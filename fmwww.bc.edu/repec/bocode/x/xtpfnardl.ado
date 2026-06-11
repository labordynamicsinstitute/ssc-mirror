*! xtpfnardl — Fourier-Augmented Panel Nonlinear ARDL (Panel Fourier NARDL)
*! Version 1.0.0 — 2026-06-06
*! Author:  Dr. Merwan Roudane, Independent Researcher
*! Email:   merwanroudane920@gmail.com
*! GitHub:  https://github.com/merwanroudane
*! Copyright (c) 2026 Merwan Roudane. Distributed under the SSC Archive terms.
*!
*! Implements the Fourier-augmented panel NARDL (FPMG-NARDL):
*!   "Genuine or spurious asymmetry? Disentangling uncertainty effects on
*!    renewable energy consumption using Fourier-augmented panel NARDL" (2026)
*!   Shin, Yu & Greenwood-Nimmo (2014)  — NARDL partial-sum decomposition
*!   Pesaran, Shin & Smith (1999)       — PMG panel ARDL
*!   Chudik et al. (2016)               — CS-ARDL augmentation
*!   Enders & Lee (2012)                — Fourier flexible form
*!
*! Estimation engine: xtdcce2 (Ditzen).
*! See also:  xtpfardl  (symmetric Fourier panel ARDL),  xtfdh.

capture program drop xtpfnardl
program define xtpfnardl, eclass sortpreserve
    version 17

    if replay() {
        if "`e(cmd)'" != "xtpfnardl" {
            di as err "results for {bf:xtpfnardl} not found"
            exit 301
        }
        _xtpfn_disp `0'
        exit
    }

    // =====================================================================
    // SYNTAX
    // =====================================================================
    syntax varlist(min=2 ts fv) [if] [in] , [   ///
        LIN(varlist ts fv)          /// linear (symmetric) control variables
        MODel(string)               /// pmg(default) | csardl | mg | dfe
        CRlags(integer 3)           ///
        Plags(integer 1)            ///
        Qlags(integer 1)            ///
        MAXK(integer 2)             /// max Fourier frequency (paper uses k in {1,2})
        K(real -1)                  ///
        FRACtional                  ///
        NOFourier                   ///
        NOCROSS                     ///
        TREND                       ///
        MHorizon(integer 20)        /// dynamic multiplier horizon
        Level(cilevel)              ///
        REPLACE                     /// overwrite existing _pos/_neg variables
        noGRaph                     ///
        GRAPHPrefix(string)         ///
        noDIAG                      ///
        HAUSman                     /// PMG-vs-MG long-run poolability test
        ]

    marksample touse
    gettoken depvar asymvars : varlist
    local depvar : word 1 of `varlist'
    local asymvars : list varlist - depvar

    if "`model'" == "" local model "pmg"
    local model = lower("`model'")
    if !inlist("`model'","pmg","csardl","mg","dfe") {
        di as err "model() must be {bf:pmg}, {bf:csardl}, {bf:mg} or {bf:dfe}"
        exit 198
    }
    local nasym : word count `asymvars'
    if `nasym' < 1 {
        di as err "specify at least one variable to decompose (asymmetric regressor)"
        exit 198
    }
    if `plags' < 1 local plags 1
    if `qlags' < 0 local qlags 0

    capture which xtdcce2
    if _rc {
        di as err "xtdcce2 not installed (estimation engine). {stata ssc install xtdcce2}"
        exit 199
    }
    capture xtset
    if _rc | "`r(panelvar)'" == "" {
        di as err "xtpfnardl requires panel data: {bf:xtset panelvar timevar}."
        exit 459
    }
    local panelvar "`r(panelvar)'"
    local timevar  "`r(timevar)'"

    if "`nofourier'" != "" local dofourier 0
    else                    local dofourier 1

    // time index & Fourier period
    tempvar tindex
    qui egen `tindex' = group(`timevar') if `touse'
    qui sum `tindex' if `touse', meanonly
    local Tspan = r(max)

    // =====================================================================
    // PARTIAL-SUM DECOMPOSITION  (Shin et al. 2014, eq. 19)
    //   v_pos = sum_s max(D.v,0) ;  v_neg = sum_s min(D.v,0)
    // =====================================================================
    local posvars ""
    local negvars ""
    foreach v of local asymvars {
        local pn "`v'_pos"
        local nn "`v'_neg"
        if "`replace'" != "" {
            capture drop `pn'
            capture drop `nn'
        }
        capture confirm new variable `pn' `nn'
        if _rc {
            di as err "variable `pn' or `nn' already exists; use {bf:replace} to overwrite."
            exit 110
        }
        tempvar dv dp dn
        qui gen double `dv' = D.`v' if `touse'
        qui gen double `dp' = max(`dv',0) if `touse'
        qui gen double `dn' = min(`dv',0) if `touse'
        qui replace `dp' = 0 if missing(`dp') & `touse'
        qui replace `dn' = 0 if missing(`dn') & `touse'
        qui bysort `panelvar' (`timevar'): gen double `pn' = sum(`dp') if `touse'
        qui by `panelvar': gen double `nn' = sum(`dn') if `touse'
        label variable `pn' "Positive partial sum of `v'"
        label variable `nn' "Negative partial sum of `v'"
        local posvars "`posvars' `pn'"
        local negvars "`negvars' `nn'"
    }

    // grouped decomposed-regressor list: v1+ v1- v2+ v2- ... then linear controls
    local declist ""
    local ii 0
    foreach v of local asymvars {
        local ii = `ii' + 1
        local pv : word `ii' of `posvars'
        local nv : word `ii' of `negvars'
        local declist "`declist' `pv' `nv'"
    }
    local declist "`declist' `lin'"

    // =====================================================================
    // Fourier frequency
    // =====================================================================
    local decvars "`declist'"
    if `dofourier' == 0 {
        local kstar 0
    }
    else if `k' >= 0 {
        local kstar = `k'
    }
    else {
        _xtpfn_kselect `depvar' `decvars' if `touse', plags(`plags') qlags(`qlags') ///
            tindex(`tindex') tspan(`Tspan') maxk(`maxk') `fractional' `trend'
        local kstar = r(kstar)
        capture matrix _xtpfn_kgrid = r(kgrid)
    }
    capture drop _xtpfn_sin _xtpfn_cos
    if `kstar' > 0 & `dofourier' == 1 {
        qui gen double _xtpfn_sin = sin(2*c(pi)*`kstar'*`tindex'/`Tspan') if `touse'
        qui gen double _xtpfn_cos = cos(2*c(pi)*`kstar'*`tindex'/`Tspan') if `touse'
        local fourier "_xtpfn_sin _xtpfn_cos"
    }
    else {
        local fourier ""
        local kstar 0
    }

    // =====================================================================
    // BUILD UECM REGRESSORS
    // =====================================================================
    local levterms "L.`depvar'"
    foreach v of local declist {
        local levterms "`levterms' L.`v'"
    }
    local srdep ""
    forvalues j = 1/`plags' {
        local srdep "`srdep' L`j'.D.`depvar'"
    }
    local srindep ""
    foreach v of local declist {
        forvalues j = 0/`qlags' {
            if `j' == 0 local srindep "`srindep' D.`v'"
            else        local srindep "`srindep' L`j'.D.`v'"
        }
    }
    local detlist ""
    if "`trend'" != "" local detlist "`tindex'"
    local crvars "`depvar' `declist'"

    // =====================================================================
    // ESTIMATE  (unified; differ by pooled())
    // =====================================================================
    local poolopt ""
    if "`model'" == "pmg" local poolopt "pooled(`levterms')"
    if "`model'" == "dfe" local poolopt "pooled(`levterms' `srdep' `srindep' `fourier' `detlist')"
    local crossopt "nocrosssectional"
    if "`nocross'" == "" local crossopt "crosssectional(`crvars') cr_lags(`crlags')"

    // Hausman poolability test (PMG vs MG long-run), if requested
    local h_chi2 = .
    if "`hausman'" != "" {
        _xtpfn_hausman, depvar(`depvar') lrvars(`declist') levterms(`levterms') ///
            sr(`srdep' `srindep' `fourier' `detlist') crossopt(`crossopt') touse(`touse')
        local h_chi2 = r(chi2)
        local h_df   = r(df)
        local h_p    = r(p)
    }

    capture noisily qui xtdcce2 D.`depvar' `levterms' `srdep' `srindep' ///
        `fourier' `detlist' if `touse', `poolopt' `crossopt' reportconstant
    if _rc {
        di as err "xtdcce2 estimation failed (rc=`_rc')."
        di as err "Try fewer lags, smaller cr_lags(), model(mg), or nocross."
        exit _rc
    }
    local N_g  = e(N_g)

    capture drop _xtpfn_resid
    qui predict double _xtpfn_resid if e(sample), residuals

    capture local ect_b  = _b[L.`depvar']
    if _rc local ect_b = .
    capture local ect_se = _se[L.`depvar']
    if _rc local ect_se = .

    // ---- long-run coefficients (delta method) ----
    local lrnames ""
    local first 1
    foreach v of local declist {
        if `first' local nlexp "(LR_`v': -_b[L.`v']/_b[L.`depvar'])"
        else       local nlexp "`nlexp' (LR_`v': -_b[L.`v']/_b[L.`depvar'])"
        local lrnames "`lrnames' `v'"
        local first 0
    }
    tempname lrb lrV
    capture nlcom `nlexp', level(`level')
    if _rc == 0 {
        matrix `lrb' = r(b)
        matrix `lrV' = r(V)
    }

    // ---- asymmetry Wald tests per decomposed variable ----
    tempname asym
    matrix `asym' = J(`nasym', 4, .)     // W_LR p_LR W_SR p_SR
    local r 0
    foreach v of local asymvars {
        local r = `r' + 1
        // long-run asymmetry: H0 theta+ = theta-  (== beta+ = beta-)
        capture test L.`v'_pos = L.`v'_neg
        if _rc == 0 {
            matrix `asym'[`r',1] = r(chi2)
            if missing(r(chi2)) matrix `asym'[`r',1] = r(F)
            matrix `asym'[`r',2] = r(p)
        }
        // short-run asymmetry: H0 sum(SR+) = sum(SR-)
        local lhs ""
        local rhs ""
        forvalues j = 0/`qlags' {
            local pf = cond(`j'==0,"D.",cond(`j'==1,"LD.","L`j'D."))
            if "`lhs'"=="" local lhs "`pf'`v'_pos"
            else          local lhs "`lhs' + `pf'`v'_pos"
            if "`rhs'"=="" local rhs "`pf'`v'_neg"
            else          local rhs "`rhs' + `pf'`v'_neg"
        }
        capture test `lhs' = `rhs'
        if _rc == 0 {
            matrix `asym'[`r',3] = r(chi2)
            if missing(r(chi2)) matrix `asym'[`r',3] = r(F)
            matrix `asym'[`r',4] = r(p)
        }
    }
    matrix rownames `asym' = `asymvars'

    // =====================================================================
    // STORE & DISPLAY
    // =====================================================================
    ereturn local cmd        "xtpfnardl"
    ereturn local cmdline    "xtpfnardl `0'"
    ereturn local depvar     "`depvar'"
    ereturn local asymvars   "`asymvars'"
    ereturn local linvars    "`lin'"
    ereturn local posvars    "`posvars'"
    ereturn local negvars    "`negvars'"
    ereturn local lrnames    "`lrnames'"
    ereturn local model      "`model'"
    ereturn local panelvar   "`panelvar'"
    ereturn local timevar    "`timevar'"
    ereturn scalar kstar     = `kstar'
    ereturn scalar plags     = `plags'
    ereturn scalar qlags     = `qlags'
    ereturn scalar crlags    = `crlags'
    ereturn scalar nocross   = ("`nocross'" != "")
    ereturn scalar mhorizon  = `mhorizon'
    ereturn scalar N_g       = `N_g'
    ereturn scalar ect_b     = `ect_b'
    ereturn scalar ect_se    = `ect_se'
    ereturn scalar level     = `level'
    if !missing(`h_chi2') {
        ereturn scalar hausman    = `h_chi2'
        ereturn scalar hausman_df = `h_df'
        ereturn scalar hausman_p  = `h_p'
    }
    capture ereturn matrix lr_b   = `lrb'
    capture ereturn matrix lr_V   = `lrV'
    ereturn matrix asym = `asym'
    capture ereturn matrix kgrid = _xtpfn_kgrid

    _xtpfn_disp , `graph' `diag' graphprefix(`graphprefix') level(`level')
    capture matrix drop _xtpfn_kgrid
end


// =========================================================================
//  DISPLAY
// =========================================================================
capture program drop _xtpfn_disp
program define _xtpfn_disp
    syntax [, noGRaph noDIAG GRAPHPrefix(string) Level(cilevel) ]

    local depvar   "`e(depvar)'"
    local asymvars "`e(asymvars)'"
    local linvars  "`e(linvars)'"
    local posvars  "`e(posvars)'"
    local negvars  "`e(negvars)'"
    local lrnames  "`e(lrnames)'"
    local model    "`e(model)'"
    local kstar    = e(kstar)
    local plags    = e(plags)
    local qlags    = e(qlags)
    local crlags   = e(crlags)
    local nocross  = e(nocross)
    local N_g      = e(N_g)
    local ect_b    = e(ect_b)
    local ect_se   = e(ect_se)
    if "`level'" == "" local level = e(level)

    local modlab = cond("`model'"=="pmg","Fourier Panel NARDL (Pooled Mean Group)", ///
                   cond("`model'"=="csardl","Fourier-CS-NARDL", ///
                   cond("`model'"=="mg","Fourier Panel NARDL (Mean Group)", ///
                                         "Fourier Panel NARDL (Dynamic Fixed Effects)")))

    di as txt ""
    di as txt "{hline 78}"
    di as res _col(3) "`modlab'"
    di as txt _col(3) "Asymmetric Fourier-Augmented Panel ARDL" _col(62) "xtpfnardl 1.0.0"
    di as txt "{hline 78}"
    di as txt _col(3) "Dependent variable" _col(30) ": " as res "D.`depvar'"
    di as txt _col(3) "Asymmetric regressors" _col(30) ": " as res "`asymvars'"
    if "`linvars'" != "" ///
        di as txt _col(3) "Linear controls" _col(30) ": " as res "`linvars'"
    di as txt _col(3) "Groups (N)" _col(30) ": " as res %9.0g `N_g'
    di as txt _col(3) "Short-run lags (p,q)" _col(30) ": " as res "(`plags',`qlags')"
    if `kstar' > 0 di as txt _col(3) "Fourier frequency (k*)" _col(30) ": " as res %5.2f `kstar'
    else           di as txt _col(3) "Fourier frequency (k*)" _col(30) ": " as res "none (linear)"
    if `nocross' == 1 di as txt _col(3) "Cross-section averages" _col(30) ": " as res "none (nocross)"
    else              di as txt _col(3) "Cross-section avg lags" _col(30) ": " as res %3.0f `crlags'
    di as txt "{hline 78}"

    // ---- LONG-RUN (grouped +/-) ----
    di as txt ""
    di as res _col(3) "Long-run coefficients" as txt "   (normalized on D.`depvar')"
    di as txt "  {hline 70}"
    di as txt _col(5) "Variable" _col(26) "Coef." _col(39) "Std. Err." _col(52) "z" _col(60) "P>|z|"
    di as txt "  {hline 70}"
    tempname LRB LRV
    capture matrix `LRB' = e(lr_b)
    capture matrix `LRV' = e(lr_V)
    if _rc == 0 & "`lrnames'" != "" {
        local j 0
        foreach v of local lrnames {
            local j = `j' + 1
            local b  = `LRB'[1,`j']
            local se = sqrt(`LRV'[`j',`j'])
            local z  = `b'/`se'
            local p  = 2*normal(-abs(`z'))
            // pretty: strip _pos/_neg suffix, mark with +/-
            local lab "`v'"
            if regexm("`v'","(.+)_pos$") local lab = regexs(1) + " (+)"
            if regexm("`v'","(.+)_neg$") local lab = regexs(1) + " (-)"
            _xtpfn_row "`lab'" `b' `se' `z' `p'
        }
    }
    di as txt "  {hline 70}"

    // ---- ECT ----
    di as txt ""
    di as res _col(3) "Error-correction speed of adjustment"
    di as txt "  {hline 70}"
    if !missing(`ect_b') & !missing(`ect_se') {
        local z = `ect_b'/`ect_se'
        local p = 2*normal(-abs(`z'))
        _xtpfn_row "ECT(L.`depvar')" `ect_b' `ect_se' `z' `p'
        if `ect_b' < 0 & `ect_b' > -1 {
            di as txt _col(5) "Implied half-life" _col(45) ": " ///
               as res %6.2f ln(2)/(-ln(1+`ect_b')) as txt " periods"
        }
        else di as err _col(5) "Note: adjustment outside (-1,0) — check stability."
    }
    di as txt "  {hline 70}"

    // ---- HAUSMAN poolability test ----
    if !missing(e(hausman)) {
        local hd = e(hausman_df)
        di as txt ""
        di as res _col(3) "Hausman test of long-run poolability" as txt "   (PMG vs MG)"
        di as txt "  {hline 70}"
        di as txt _col(5) "chi2(" as res `hd' as txt ") = " as res %7.3f e(hausman) ///
           as txt _col(40) "Prob > chi2 = " as res %6.3f e(hausman_p)
        if e(hausman) < 0 ///
            di as err _col(5) "=> V(MG)-V(PMG) not p.d.; prefer MG."
        else if e(hausman_p) < 0.05 ///
            di as txt _col(5) "=> reject H0: long-run heterogeneity; prefer {bf:MG}."
        else ///
            di as res _col(5) "=> do not reject H0: pooling valid; {bf:PMG} preferred."
        di as txt "  {hline 70}"
    }

    // ---- ASYMMETRY TESTS ----
    di as txt ""
    di as res _col(3) "Asymmetry Wald tests" as txt "   (H0: symmetric effect)"
    di as txt "  {hline 70}"
    di as txt _col(5) "Variable" _col(28) "LR W" _col(40) "p(LR)" ///
       _col(52) "SR W" _col(64) "p(SR)"
    di as txt "  {hline 70}"
    tempname AS
    matrix `AS' = e(asym)
    local rn : rownames `AS'
    local r 0
    foreach v of local rn {
        local r = `r' + 1
        local wlr = `AS'[`r',1]
        local plr = `AS'[`r',2]
        local wsr = `AS'[`r',3]
        local psr = `AS'[`r',4]
        local s1 = cond(`plr'<0.01,"***",cond(`plr'<0.05,"**",cond(`plr'<0.10,"*","")))
        local s2 = cond(`psr'<0.01,"***",cond(`psr'<0.05,"**",cond(`psr'<0.10,"*","")))
        di as txt _col(5) abbrev("`v'",20) ///
           _col(26) as res %8.3f `wlr' _col(38) %6.3f `plr' " `s1'" ///
           _col(50) %8.3f `wsr' _col(62) %6.3f `psr' " `s2'"
    }
    di as txt "  {hline 70}"
    di as txt _col(5) "{it:Reject H0 => genuine asymmetry. *** p<.01, ** p<.05, * p<.10}"

    // ---- SHORT-RUN (from e(b)) ----
    di as txt ""
    di as res _col(3) "Short-run dynamics" as txt "   (mean-group averages)"
    di as txt "  {hline 70}"
    di as txt _col(5) "Variable" _col(26) "Coef." _col(39) "Std. Err." _col(52) "z" _col(60) "P>|z|"
    di as txt "  {hline 70}"
    local levset "L.`depvar'"
    foreach v in `posvars' `negvars' `linvars' {
        local levset "`levset' L.`v'"
    }
    tempname bb VV
    capture matrix `bb' = e(b)
    capture matrix `VV' = e(V)
    if _rc == 0 {
        local cn : colnames `bb'
        local kk = colsof(`bb')
        forvalues i = 1/`kk' {
            local c : word `i' of `cn'
            local skip : list c in levset
            if `skip' continue
            if "`c'" == "_cons" | "`c'" == "o._cons" continue
            local lab "`c'"
            if strpos("`c'","_xtpfn_sin") local lab "sin(2{&pi}kt/T)"
            if strpos("`c'","_xtpfn_cos") local lab "cos(2{&pi}kt/T)"
            local b  = `bb'[1,`i']
            local se = sqrt(`VV'[`i',`i'])
            if `se' > 0 & !missing(`se') {
                local z = `b'/`se'
                local p = 2*normal(-abs(`z'))
                _xtpfn_row "`lab'" `b' `se' `z' `p'
            }
        }
    }
    di as txt "  {hline 70}"
    di as txt _col(5) "{it:Significance: *** p<0.01, ** p<0.05, * p<0.10}"

    // ---- DIAGNOSTICS ----
    if "`diag'" == "" {
        di as txt ""
        di as res _col(3) "Diagnostics"
        di as txt "  {hline 70}"
        if `kstar' > 0 {
            capture qui test _xtpfn_sin _xtpfn_cos
            if _rc == 0 {
                local fs "`r(chi2)'"
                if "`fs'"=="" | "`fs'"=="." local fs "`r(F)'"
                local fp "`r(p)'"
                if "`fs'"!="" & "`fs'"!="." ///
                    di as txt _col(5) "Fourier joint significance (H0: no Fourier)" ///
                       _col(52) as res %8.3f `fs' as txt " [" as res %5.3f `fp' as txt "]"
            }
        }
        capture which xtcd2
        if _rc == 0 {
            capture qui xtcd2 _xtpfn_resid
            if _rc == 0 {
                tempname cdm cdpm
                capture matrix `cdm' = r(CD)
                capture matrix `cdpm' = r(p)
                if _rc == 0 {
                    di as txt _col(5) "Pesaran CD test on residuals (H0: no CSD)" ///
                       _col(52) as res %8.3f `cdm'[1,1] as txt " [" as res %5.3f `cdpm'[1,1] as txt "]"
                }
            }
        }
        di as txt "  {hline 70}"
    }

    // ---- GRAPHS ----
    if "`graph'" == "" {
        capture _xtpfn_multiplier, depvar(`depvar') graphprefix(`graphprefix')
        if `kstar' > 0 capture _xtpfn_kplot, kstar(`kstar') graphprefix(`graphprefix')
    }

    di as txt "{hline 78}"
    di as res _col(3) "xtpfnardl 1.0.0" as txt _col(22) ///
       "{stata help xtpfnardl:help}  |  {stata help xtpfardl:xtpfardl}  |  {stata help xtfdh:xtfdh}"
    di as txt "{hline 78}"
end


// =========================================================================
//  row printer
// =========================================================================
capture program drop _xtpfn_row
program define _xtpfn_row
    args name b se z p
    local stars ""
    if `p' < 0.01      local stars "***"
    else if `p' < 0.05 local stars "**"
    else if `p' < 0.10 local stars "*"
    di as txt _col(5) abbrev("`name'",20) _col(24) as res %10.5f `b' ///
       _col(38) %9.5f `se' _col(50) %7.3f `z' _col(59) %6.3f `p' _col(67) as res "`stars'"
end


// =========================================================================
//  PMG-vs-MG Hausman poolability test (built-in hausman on long-run vector)
// =========================================================================
capture program drop _xtpfn_hausman
program define _xtpfn_hausman, rclass
    syntax , DEPvar(string) LRVARS(string) LEVTERMS(string) SR(string) ///
        CROSSopt(string) TOUSE(string)
    local first 1
    foreach x of local lrvars {
        if `first' local nlexp "(LR_`x': -_b[L.`x']/_b[L.`depvar'])"
        else       local nlexp "`nlexp' (LR_`x': -_b[L.`x']/_b[L.`depvar'])"
        local first 0
    }
    return scalar chi2 = .
    capture {
        tempname bm Vm bp Vp
        qui xtdcce2 D.`depvar' `levterms' `sr' if `touse', `crossopt' reportconstant
        qui nlcom `nlexp'
        matrix `bm' = r(b)
        matrix `Vm' = r(V)
        qui xtdcce2 D.`depvar' `levterms' `sr' if `touse', pooled(`levterms') `crossopt' reportconstant
        qui nlcom `nlexp'
        matrix `bp' = r(b)
        matrix `Vp' = r(V)
        tempname d Vd
        matrix `d'  = `bm' - `bp'
        matrix `Vd' = `Vm' - `Vp'
        mata: st_numscalar("__hH", (st_matrix(st_local("d"))*invsym(st_matrix(st_local("Vd")))*st_matrix(st_local("d"))')[1,1])
        mata: st_numscalar("__hdf", rank(st_matrix(st_local("Vd"))))
        return scalar chi2 = __hH
        return scalar df   = __hdf
        return scalar p    = cond(__hH>=0, chi2tail(__hdf,__hH), .)
    }
    capture scalar drop __hH __hdf
end


// =========================================================================
//  Fourier k* selection (pooled min SSR)
// =========================================================================
capture program drop _xtpfn_kselect
program define _xtpfn_kselect, rclass
    syntax varlist(ts) [if] , Plags(integer) Qlags(integer) ///
        TIndex(varname) TSpan(integer) MAXK(integer) [ FRACtional TREND ]
    marksample touse
    local depvar : word 1 of `varlist'
    local xs : list varlist - depvar
    local rhs "L.`depvar'"
    foreach v of local xs {
        local rhs "`rhs' L.`v'"
    }
    forvalues j = 1/`plags' {
        local rhs "`rhs' L`j'.D.`depvar'"
    }
    foreach v of local xs {
        forvalues j = 0/`qlags' {
            if `j'==0 local rhs "`rhs' D.`v'"
            else      local rhs "`rhs' L`j'.D.`v'"
        }
    }
    local det ""
    if "`trend'" != "" local det "`tindex'"
    if "`fractional'" != "" {
        local step = 0.1
        local nk = round(`maxk'/0.1)
    }
    else {
        local step = 1
        local nk = `maxk'
    }
    tempname grid
    matrix `grid' = J(`nk',2,.)
    tempvar s c
    local best = .
    local kstar = 1
    forvalues i = 1/`nk' {
        local kval = `i'*`step'
        matrix `grid'[`i',1] = `kval'
        capture drop `s' `c'
        qui gen double `s' = sin(2*c(pi)*`kval'*`tindex'/`tspan') if `touse'
        qui gen double `c' = cos(2*c(pi)*`kval'*`tindex'/`tspan') if `touse'
        capture qui regress D.`depvar' `rhs' `s' `c' `det' if `touse'
        if _rc==0 {
            matrix `grid'[`i',2] = e(rss)
            if e(rss) < `best' | missing(`best') {
                local best = e(rss)
                local kstar = `kval'
            }
        }
    }
    return scalar kstar = `kstar'
    return matrix kgrid = `grid'
end


// =========================================================================
//  Asymmetric cumulative dynamic-multiplier plot (one per asym var)
// =========================================================================
capture program drop _xtpfn_multiplier
program define _xtpfn_multiplier
    syntax , depvar(string) [ GRAPHPrefix(string) ]
    local ect = e(ect_b)
    if missing(`ect') | `ect' >= 0 | `ect' <= -2 exit
    local phi = `ect'
    if `phi' <= -1 local phi = -0.999          // keep recursion stable
    local h = e(mhorizon)
    local lvl = e(level)
    local zc = invnormal(1-(100-`lvl')/200)
    local asymvars "`e(asymvars)'"
    local lrnames  "`e(lrnames)'"
    tempname LRB LRV
    capture matrix `LRB' = e(lr_b)
    capture matrix `LRV' = e(lr_V)
    if _rc exit

    foreach v of local asymvars {
        // locate positive/negative long-run coefficients
        local jp 0
        local jn 0
        local k 0
        foreach nm of local lrnames {
            local k = `k' + 1
            if "`nm'" == "`v'_pos" local jp = `k'
            if "`nm'" == "`v'_neg" local jn = `k'
        }
        if `jp'==0 | `jn'==0 continue
        local bp = `LRB'[1,`jp']
        local bn = `LRB'[1,`jn']
        local sep = sqrt(`LRV'[`jp',`jp'])
        local sen = sqrt(`LRV'[`jn',`jn'])
        // SE of the long-run asymmetry beta+ - beta-
        local seA = sqrt(`LRV'[`jp',`jp'] + `LRV'[`jn',`jn'] - 2*`LRV'[`jp',`jn'])
        local bA  = `bp' - `bn'

        preserve
        qui {
            clear
            set obs `=`h'+1'
            gen period = _n - 1
            gen double mpos = .
            gen double mpos_lo = .
            gen double mpos_hi = .
            gen double mneg = .
            gen double mneg_lo = .
            gen double mneg_hi = .
            gen double masym = .
            gen double masym_lo = .
            gen double masym_hi = .
            gen double lrp = `bp'
            gen double lrn = `bn'
            gen double lrA = `bA'
            gen double zero = 0
        }
        // cumulative multiplier m_h = beta*(1-(1+phi)^h); CI scales by the same shape g_h
        forvalues t = 0/`h' {
            local g = 1-(1+`phi')^`t'
            local r = `=`t'+1'
            qui replace mpos    = `bp'*`g'                 in `r'
            qui replace mpos_lo = (`bp'-`zc'*`sep')*`g'    in `r'
            qui replace mpos_hi = (`bp'+`zc'*`sep')*`g'    in `r'
            qui replace mneg    = `bn'*`g'                 in `r'
            qui replace mneg_lo = (`bn'-`zc'*`sen')*`g'    in `r'
            qui replace mneg_hi = (`bn'+`zc'*`sen')*`g'    in `r'
            qui replace masym    = `bA'*`g'                in `r'
            qui replace masym_lo = (`bA'-`zc'*`seA')*`g'   in `r'
            qui replace masym_hi = (`bA'+`zc'*`seA')*`g'   in `r'
        }

        // ----- Graph 1: dynamic multipliers with CI bands -----
        capture noisily {
            twoway (rarea mpos_lo mpos_hi period, color("46 160 90%25") lwidth(none)) ///
                   (rarea mneg_lo mneg_hi period, color("220 60 50%25") lwidth(none)) ///
                   (line mpos period, lcolor("46 160 90") lwidth(medthick)) ///
                   (line mneg period, lcolor("220 60 50") lwidth(medthick)) ///
                   (line lrp period, lcolor("46 160 90") lpattern(dash) lwidth(thin)) ///
                   (line lrn period, lcolor("220 60 50") lpattern(dash) lwidth(thin)) ///
                   (line zero period, lcolor(gs10) lwidth(vthin)), ///
                title("{bf:Cumulative dynamic multipliers}", size(medlarge) color("24 54 104")) ///
                subtitle("Response to {&plusminus}1 shock in `v'  ({&plusminus}`lvl'% CI)", size(small) color(gs6)) ///
                ytitle("Cumulative effect on `depvar'", size(medsmall)) ///
                xtitle("Periods after shock", size(medsmall)) ///
                legend(order(3 "m{sup:+}(h)" 4 "m{sup:-}(h)" ///
                    5 "{&beta}{sup:+}" 6 "{&beta}{sup:-}") cols(4) size(small) ///
                    region(lcolor(gs14) fcolor(white%90)) pos(6)) ///
                ylabel(, format(%5.2f) angle(0) labsize(small) grid glcolor(gs14%50)) ///
                xlabel(, labsize(small)) ///
                graphregion(fcolor(white)) plotregion(fcolor(white) lcolor(gs14)) ///
                name(xtpfn_mult_`v', replace)
            capture graph export "`graphprefix'xtpfnardl_mult_`v'.png", replace width(1400)
        }

        // ----- Graph 2: asymmetry path  m+(h) - m-(h)  with CI band -----
        capture noisily {
            twoway (rarea masym_lo masym_hi period, color("24 54 104%20") lwidth(none)) ///
                   (line masym period, lcolor("24 54 104") lwidth(medthick)) ///
                   (line lrA period, lcolor("24 54 104") lpattern(dash) lwidth(thin)) ///
                   (line zero period, lcolor("220 50 47") lpattern(solid) lwidth(vthin)), ///
                title("{bf:Asymmetry path}", size(medlarge) color("24 54 104")) ///
                subtitle("m{sup:+}(h) {&minus} m{sup:-}(h) for `v'  ({&plusminus}`lvl'% CI)", size(small) color(gs6)) ///
                ytitle("Asymmetric cumulative effect", size(medsmall)) ///
                xtitle("Periods after shock", size(medsmall)) ///
                legend(order(2 "asymmetry m{sup:+}{&minus}m{sup:-}" ///
                    3 "{&beta}{sup:+}{&minus}{&beta}{sup:-}" 4 "zero (symmetry)") ///
                    cols(3) size(small) region(lcolor(gs14) fcolor(white%90)) pos(6)) ///
                ylabel(, format(%5.2f) angle(0) labsize(small) grid glcolor(gs14%50)) ///
                xlabel(, labsize(small)) ///
                graphregion(fcolor(white)) plotregion(fcolor(white) lcolor(gs14)) ///
                name(xtpfn_asym_`v', replace)
            capture graph export "`graphprefix'xtpfnardl_asym_`v'.png", replace width(1400)
        }
        restore
    }
end


// =========================================================================
//  Fourier frequency selection plot
// =========================================================================
capture program drop _xtpfn_kplot
program define _xtpfn_kplot
    syntax , kstar(real) [ GRAPHPrefix(string) ]
    tempname G
    capture matrix `G' = e(kgrid)
    if _rc exit
    local nk = rowsof(`G')
    if `nk' < 2 exit
    preserve
    qui {
        clear
        set obs `nk'
        gen double kval = .
        gen double ssr = .
    }
    forvalues i = 1/`nk' {
        qui replace kval = `G'[`i',1] in `i'
        qui replace ssr  = `G'[`i',2] in `i'
    }
    qui gen byte isopt = abs(kval-`kstar') < 1e-6
    capture noisily {
        twoway (connected ssr kval, lcolor("24 54 104") mcolor("24 54 104") lwidth(medthick) msymbol(circle)) ///
               (scatter ssr kval if isopt, mcolor("220 50 47") msymbol(diamond) msize(vlarge)), ///
            title("{bf:Fourier frequency selection}", size(medlarge) color("24 54 104")) ///
            subtitle("Pooled minimum-SSR criterion", size(small) color(gs6)) ///
            xtitle("Fourier frequency (k)", size(medsmall)) ytitle("Sum of squared residuals", size(medsmall)) ///
            xline(`kstar', lcolor("220 50 47") lpattern(dash) lwidth(thin)) ///
            legend(order(1 "SSR" 2 "k* = `kstar'") size(small) cols(2) ring(0) pos(1) ///
                region(fcolor(white%85) lcolor(gs12))) ///
            graphregion(fcolor(white)) plotregion(fcolor(white) lcolor(gs14)) ///
            ylabel(, labsize(small) angle(0) grid glcolor(gs14%50)) xlabel(, labsize(small)) ///
            name(xtpfn_kplot, replace)
        capture graph export "`graphprefix'xtpfnardl_kstar.png", replace width(1400)
    }
    restore
end
