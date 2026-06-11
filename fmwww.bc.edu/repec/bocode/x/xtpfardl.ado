*! xtpfardl — Fourier-Augmented Panel ARDL / CS-ARDL Estimator
*! Version 1.0.0 — 2026-06-06
*! Author:  Dr. Merwan Roudane, Independent Researcher
*! Email:   merwanroudane920@gmail.com
*! GitHub:  https://github.com/merwanroudane
*! Copyright (c) 2026 Merwan Roudane. Distributed under the SSC Archive terms.
*!
*! Implements the Fourier-augmented panel ARDL family:
*!   Ersin (2026)               — Fourier-CS-ARDL  <doi:10.3390/su18062728>
*!   Sardarli & Suleymanli (2026) — Fourier Panel ARDL (PMG) <doi:10.62433/josdi.v3i2.68>
*!   Chudik, Mohaddes, Pesaran & Raissi (2016) — CS-ARDL base
*!   Pesaran, Shin & Smith (1999) — PMG / panel ARDL base
*!   Enders & Lee (2012); Yilanci, Bozoklu & Gorus (2020) — Fourier flexible form
*!
*! Estimation engine: xtdcce2 (Ditzen) — must be installed.
*!
*! See also:  xtfdh  (Fourier Dumitrescu-Hurlin causality)

capture program drop xtpfardl
program define xtpfardl, eclass sortpreserve
    version 17

    if replay() {
        if "`e(cmd)'" != "xtpfardl" {
            di as err "results for {bf:xtpfardl} not found"
            exit 301
        }
        _xtpf_disp `0'
        exit
    }

    // =====================================================================
    // 1. SYNTAX
    // =====================================================================
    syntax varlist(min=2 ts fv) [if] [in] , [   ///
        MODel(string)               /// csardl | mg | pmg | dfe
        CRlags(integer 3)           /// lags of cross-section averages
        Plags(integer 1)            /// short-run lags of D.depvar
        Qlags(integer 1)            /// short-run lags of D.indepvars
        LAGSearch(integer 0)        /// >0: BIC search of p,q up to this max
        MAXK(integer 3)             /// max Fourier frequency for k* search
        K(real -1)                  /// fix Fourier frequency (overrides search)
        FRACtional                  /// search k in 0.1 steps (else integer)
        NOFourier                   /// exclude Fourier terms (plain panel ARDL)
        NOCROSS                     /// no cross-sectional augmentation
        TREND                       /// include linear trend
        Level(cilevel)              ///
        noGRaph                     /// suppress all graphs
        GRAPHPrefix(string)         /// filename prefix for exported graphs
        noDIAG                      /// suppress diagnostics block
        noCInfo                     /// suppress country-coefficient block
        HAUSman                     /// PMG-vs-MG long-run poolability Hausman test
        ]

    marksample touse
    gettoken depvar indepvars : varlist
    local nindep : word count `indepvars'

    // ----- option validation -----
    if "`model'" == "" local model "csardl"
    local model = lower("`model'")
    if !inlist("`model'", "csardl", "mg", "pmg", "dfe") {
        di as err "model() must be {bf:csardl}, {bf:mg}, {bf:pmg} or {bf:dfe}"
        exit 198
    }
    if `nindep' < 1 {
        di as err "at least one independent variable is required"
        exit 198
    }
    if `plags' < 1  local plags 1
    if `qlags' < 0  local qlags 0
    if `crlags' < 0 local crlags 0

    // ----- engine present? -----
    capture which xtdcce2
    if _rc {
        di as err "xtdcce2 not installed (estimation engine)."
        di as err `"install: {stata "ssc install xtdcce2"}"'
        exit 199
    }

    // ----- panel structure -----
    capture xtset
    if _rc {
        di as err "data are not {bf:xtset}. Use {bf:xtset panelvar timevar} first."
        exit 459
    }
    local panelvar "`r(panelvar)'"
    local timevar  "`r(timevar)'"
    if "`panelvar'" == "" {
        di as err "xtpfardl requires panel data (xtset panelvar timevar). For a single time series use {bf:fbardl}."
        exit 459
    }

    // Fourier on/off bookkeeping
    if "`nofourier'" != "" {
        local dofourier 0
    }
    else {
        local dofourier 1
    }

    // =====================================================================
    // 2. BUILD TIME INDEX & FOURIER PERIOD T
    // =====================================================================
    tempvar tindex
    qui egen `tindex' = group(`timevar') if `touse'
    qui sum `tindex' if `touse', meanonly
    local Tspan = r(max)            // number of distinct time periods

    // =====================================================================
    // 3. OPTIONAL (p,q) BIC SEARCH (pooled, fast)  -- and k* SEARCH
    // =====================================================================
    // Fourier frequency grid
    if `dofourier' == 0 {
        local kstar = 0
    }
    else if `k' >= 0 {
        local kstar = `k'
    }
    else {
        local kstar = .            // to be chosen
    }

    // Lag search (pooled BIC) ----------------------------------------------
    if `lagsearch' > 0 {
        _xtpf_lagsearch `depvar' `indepvars' if `touse', ///
            maxp(`lagsearch') maxq(`lagsearch') tindex(`tindex') ///
            tspan(`Tspan') kstar(`=cond(missing(`kstar'),1,`kstar')')
        local plags = r(bestp)
        local qlags = r(bestq)
    }

    // Fourier k* search (pooled min-SSR, Yilanci et al. 2020) ---------------
    if `dofourier' == 1 & missing(`kstar') {
        _xtpf_kselect `depvar' `indepvars' if `touse', ///
            plags(`plags') qlags(`qlags') tindex(`tindex') tspan(`Tspan') ///
            maxk(`maxk') `fractional' `trend'
        local kstar   = r(kstar)
        matrix _xtpf_kgrid = r(kgrid)
    }

    // =====================================================================
    // 4. GENERATE FOURIER TERMS AT k*
    // =====================================================================
    capture drop _xtpf_sin _xtpf_cos
    if `kstar' > 0 & `dofourier' == 1 {
        qui gen double _xtpf_sin = sin(2*c(pi)*`kstar'*`tindex'/`Tspan') if `touse'
        qui gen double _xtpf_cos = cos(2*c(pi)*`kstar'*`tindex'/`Tspan') if `touse'
        local fourier "_xtpf_sin _xtpf_cos"
    }
    else {
        local fourier ""
        local kstar 0
    }

    // =====================================================================
    // 5. BUILD UECM REGRESSOR LISTS
    //    D.y = phi*L.y + sum theta_m*L.x_m
    //          + sum psi_j L^j.D.y + sum delta_mj L^j.D.x_m + Fourier (+trend)
    // =====================================================================
    local levterms "L.`depvar'"          // first = ECT speed term (phi)
    local xlev ""
    foreach x of local indepvars {
        local levterms "`levterms' L.`x'"
        local xlev "`xlev' L.`x'"
    }

    local srdep ""
    forvalues j = 1/`plags' {
        local srdep "`srdep' L`j'.D.`depvar'"
    }
    local srindep ""
    foreach x of local indepvars {
        forvalues j = 0/`qlags' {
            if `j' == 0  local srindep "`srindep' D.`x'"
            else         local srindep "`srindep' L`j'.D.`x'"
        }
    }

    local detlist ""
    if "`trend'" != "" local detlist "`tindex'"

    // cross-section average variables (levels of all model variables)
    local crvars "`depvar' `indepvars'"

    local crossopt "nocrosssectional"
    if "`nocross'" == "" local crossopt "crosssectional(`crvars') cr_lags(`crlags')"

    // =====================================================================
    // 6a. HAUSMAN poolability test (PMG vs MG long-run), if requested
    // =====================================================================
    local h_chi2 = .
    if "`hausman'" != "" {
        _xtpf_hausman, depvar(`depvar') lrvars(`indepvars') levterms(`levterms') ///
            sr(`srdep' `srindep' `fourier' `detlist') crossopt(`crossopt') touse(`touse')
        local h_chi2 = r(chi2)
        local h_df   = r(df)
        local h_p    = r(p)
    }

    // =====================================================================
    // 6. ESTIMATE
    // =====================================================================
    // Unified one-step UECM estimated via xtdcce2.  The four models differ
    // only in what is pooled (homogeneous) vs mean-group (heterogeneous):
    //   csardl : all heterogeneous + cross-section averages (Chudik et al.)
    //   mg     : all heterogeneous (CCE-MG)
    //   pmg    : long-run level terms pooled, dynamics heterogeneous (PMG)
    //   dfe    : everything pooled (dynamic fixed effects / CCEP)
    local poolopt ""
    if "`model'" == "pmg"  local poolopt "pooled(`levterms')"
    if "`model'" == "dfe"  local poolopt "pooled(`levterms' `srdep' `srindep' `fourier' `detlist')"

    capture noisily qui xtdcce2 D.`depvar' `levterms' `srdep' `srindep' ///
        `fourier' `detlist' if `touse', `poolopt' `crossopt' reportconstant
    if _rc {
        di as err "xtdcce2 estimation failed (rc=`_rc')."
        di as err "Try: fewer lags (plags/qlags), smaller cr_lags(), model(mg), or nocross."
        exit _rc
    }
    local N_g  = e(N_g)
    local Tavg = e(T)

    // residuals (common-factor-partialled)
    capture drop _xtpf_resid
    qui predict double _xtpf_resid if e(sample), residuals

    // ECT speed of adjustment = coefficient on L.depvar
    capture local ect_b  = _b[L.`depvar']
    if _rc local ect_b = .
    capture local ect_se = _se[L.`depvar']
    if _rc local ect_se = .

    // Long-run coefficients via delta method:  LR_x = -theta_x / phi
    // (nlcom WITHOUT post leaves xtdcce2 e() intact, returns r(b)/r(V))
    tempname lrb lrV
    local lrnames ""
    local first 1
    foreach x of local indepvars {
        if `first' local nlexp "(LR_`x': -_b[L.`x']/_b[L.`depvar'])"
        else       local nlexp "`nlexp' (LR_`x': -_b[L.`x']/_b[L.`depvar'])"
        local lrnames "`lrnames' `x'"
        local first 0
    }
    capture nlcom `nlexp', level(`level')
    if _rc == 0 {
        matrix `lrb' = r(b)
        matrix `lrV' = r(V)
    }

    // =====================================================================
    // 7. DISPLAY
    // =====================================================================
    // stash everything needed for replay into e()
    tempname kgridmat
    capture matrix `kgridmat' = _xtpf_kgrid

    ereturn local cmd        "xtpfardl"
    ereturn local cmdline    "xtpfardl `0'"
    ereturn local depvar     "`depvar'"
    ereturn local indepvars  "`indepvars'"
    ereturn local model      "`model'"
    ereturn local panelvar   "`panelvar'"
    ereturn local timevar    "`timevar'"
    ereturn local lrnames    "`lrnames'"
    ereturn scalar kstar     = `kstar'
    ereturn scalar plags     = `plags'
    ereturn scalar qlags     = `qlags'
    ereturn scalar crlags    = `crlags'
    ereturn scalar nocross   = ("`nocross'" != "")
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
    capture ereturn matrix kgrid  = `kgridmat'

    _xtpf_disp , `graph' `diag' `cinfo' graphprefix(`graphprefix') level(`level')

    capture matrix drop _xtpf_kgrid
end


// =========================================================================
//  DISPLAY ENGINE
// =========================================================================
capture program drop _xtpf_disp
program define _xtpf_disp
    syntax [, noGRaph noDIAG noCInfo GRAPHPrefix(string) Level(cilevel) ]

    local depvar    "`e(depvar)'"
    local indepvars "`e(indepvars)'"
    local model     "`e(model)'"
    local kstar     = e(kstar)
    local plags     = e(plags)
    local qlags     = e(qlags)
    local crlags    = e(crlags)
    local nocross   = e(nocross)
    local N_g       = e(N_g)
    local ect_b     = e(ect_b)
    local ect_se    = e(ect_se)
    local lrnames   "`e(lrnames)'"
    if "`level'" == "" local level = e(level)

    local modlab = cond("`model'"=="csardl","Fourier-CS-ARDL", ///
                   cond("`model'"=="mg","Fourier Panel ARDL (Mean Group)", ///
                   cond("`model'"=="pmg","Fourier Panel ARDL (Pooled Mean Group)", ///
                                          "Fourier Panel ARDL (Dynamic Fixed Effects)")))

    // ---- header ----
    di as txt ""
    di as txt "{hline 78}"
    di as res _col(3) "`modlab'"
    di as txt _col(3) "Fourier-Augmented Panel ARDL Estimator" _col(62) "xtpfardl 1.0.0"
    di as txt "{hline 78}"
    di as txt _col(3) "Dependent variable" _col(30) ": " as res "D.`depvar'"
    di as txt _col(3) "Long-run variables" _col(30) ": " as res "`indepvars'"
    di as txt _col(3) "Groups (N)" _col(30) ": " as res %9.0g `N_g'
    di as txt _col(3) "ARDL short-run lags (p,q)" _col(30) ": " as res "(`plags',`qlags')"
    if `kstar' > 0 {
        di as txt _col(3) "Fourier frequency (k*)" _col(30) ": " as res %6.2f `kstar'
    }
    else {
        di as txt _col(3) "Fourier frequency (k*)" _col(30) ": " as res "none (linear)"
    }
    if `nocross' == 1 {
        di as txt _col(3) "Cross-section averages" _col(30) ": " as res "none (nocross)"
    }
    else {
        di as txt _col(3) "Cross-section avg lags" _col(30) ": " as res %3.0f `crlags'
    }
    di as txt "{hline 78}"

    // ---- LONG-RUN TABLE ----
    di as txt ""
    di as res _col(3) "Long-run coefficients" as txt "   (normalized on D.`depvar')"
    di as txt "  {hline 70}"
    di as txt _col(5) "Variable" _col(26) "Coef." _col(39) "Std. Err." ///
       _col(52) "z" _col(60) "P>|z|" _col(70) " "
    di as txt "  {hline 70}"
    tempname LRB LRV
    capture matrix `LRB' = e(lr_b)
    capture matrix `LRV' = e(lr_V)
    if _rc == 0 & "`lrnames'" != "" {
        local j 0
        foreach x of local lrnames {
            local j = `j' + 1
            local b  = `LRB'[1,`j']
            local se = sqrt(`LRV'[`j',`j'])
            local z  = `b'/`se'
            local p  = 2*normal(-abs(`z'))
            _xtpf_row "`x'" `b' `se' `z' `p'
        }
    }
    else {
        di as txt _col(5) "(long-run vector unavailable)"
    }
    di as txt "  {hline 70}"

    // ---- ERROR-CORRECTION / ADJUSTMENT ----
    di as txt ""
    di as res _col(3) "Error-correction speed of adjustment"
    di as txt "  {hline 70}"
    di as txt _col(5) "Variable" _col(26) "Coef." _col(39) "Std. Err." ///
       _col(52) "z" _col(60) "P>|z|"
    di as txt "  {hline 70}"
    if !missing(`ect_b') & !missing(`ect_se') {
        local z = `ect_b'/`ect_se'
        local p = 2*normal(-abs(`z'))
        _xtpf_row "ECT(L.`depvar')" `ect_b' `ect_se' `z' `p'
        local hl = -1/`ect_b'
    }
    di as txt "  {hline 70}"
    if !missing(`ect_b') {
        if `ect_b' < 0 & `ect_b' > -1 {
            local conv = ln(2)/(-ln(1+`ect_b'))
            di as txt _col(5) "Implied half-life of a shock" _col(45) ": " ///
               as res %6.2f `conv' as txt " periods"
        }
        else {
            di as err _col(5) "Note: adjustment coefficient outside (-1,0) — check stability."
        }
    }

    // ---- HAUSMAN poolability test ----
    if !missing(e(hausman)) {
        local hc = e(hausman)
        local hd = e(hausman_df)
        local hp = e(hausman_p)
        di as txt ""
        di as res _col(3) "Hausman test of long-run poolability" as txt "   (PMG vs MG)"
        di as txt "  {hline 70}"
        di as txt _col(5) "H0: long-run homogeneity (PMG efficient and consistent)"
        di as txt _col(5) "chi2(" as res `hd' as txt ") = " as res %7.3f `hc' ///
           as txt _col(40) "Prob > chi2 = " as res %6.3f `hp'
        if `hc' < 0 ///
            di as err _col(5) "=> negative statistic: V(MG)-V(PMG) not p.d.; prefer MG."
        else if `hp' < 0.05 ///
            di as txt _col(5) "=> reject H0 at 5%: long-run heterogeneity; prefer {bf:MG}."
        else ///
            di as res _col(5) "=> do not reject H0: pooling valid; {bf:PMG} preferred."
        di as txt "  {hline 70}"
    }

    // ---- SHORT-RUN TABLE (read names directly from e(b)) ----
    di as txt ""
    di as res _col(3) "Short-run dynamics" as txt "   (mean-group averages)"
    di as txt "  {hline 70}"
    di as txt _col(5) "Variable" _col(26) "Coef." _col(39) "Std. Err." ///
       _col(52) "z" _col(60) "P>|z|"
    di as txt "  {hline 70}"
    // Level (long-run / ECT) terms to exclude from the short-run block
    local levset "L.`depvar'"
    foreach x of local indepvars {
        local levset "`levset' L.`x'"
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
            if `skip'             continue
            if "`c'" == "_cons"   continue
            if "`c'" == "o._cons" continue
            // pretty labels for the Fourier deterministics
            local lab "`c'"
            if strpos("`c'","_xtpf_sin") local lab "sin(2{&pi}kt/T)"
            if strpos("`c'","_xtpf_cos") local lab "cos(2{&pi}kt/T)"
            local b  = `bb'[1,`i']
            local se = sqrt(`VV'[`i',`i'])
            if `se' > 0 & !missing(`se') {
                local z = `b'/`se'
                local p = 2*normal(-abs(`z'))
                _xtpf_row "`lab'" `b' `se' `z' `p'
            }
        }
    }
    di as txt "  {hline 70}"
    di as txt _col(5) "{it:Significance: *** p<0.01, ** p<0.05, * p<0.10}"

    // ---- DIAGNOSTICS ----
    if "`diag'" == "" {
        _xtpf_diag, depvar(`depvar') kstar(`kstar')
    }

    // ---- LONG-RUN COEFFICIENT PLOT ----
    if "`cinfo'" == "" & "`graph'" == "" {
        capture _xtpf_forest, depvar(`depvar') indepvars(`indepvars') ///
            graphprefix(`graphprefix')
    }

    // ---- k* SELECTION PLOT ----
    if "`graph'" == "" & `kstar' > 0 {
        capture _xtpf_kplot, kstar(`kstar') graphprefix(`graphprefix')
    }

    di as txt "{hline 78}"
    di as res _col(3) "xtpfardl 1.0.0" as txt _col(20) ///
       "{stata help xtpfardl:help}  |  {stata help xtfdh:xtfdh}"
    di as txt "{hline 78}"
end


// =========================================================================
//  ROW PRINTER with significance stars
// =========================================================================
capture program drop _xtpf_row
program define _xtpf_row
    args name b se z p
    local stars ""
    if `p' < 0.01      local stars "***"
    else if `p' < 0.05 local stars "**"
    else if `p' < 0.10 local stars "*"
    di as txt _col(5) abbrev("`name'",20) ///
       _col(24) as res %10.5f `b' ///
       _col(38) %9.5f `se' ///
       _col(50) %7.3f `z' ///
       _col(59) %6.3f `p' ///
       _col(67) as res "`stars'"
end


// =========================================================================
//  HELPER: PMG-vs-MG Hausman poolability test on the long-run vector
//          (built-in hausman on nlcom-posted long-run estimates)
// =========================================================================
capture program drop _xtpf_hausman
program define _xtpf_hausman, rclass
    syntax , DEPvar(string) LRVARS(string) LEVTERMS(string) SR(string) ///
        CROSSopt(string) TOUSE(string)
    // long-run delta-method expression (same for both models)
    local first 1
    foreach x of local lrvars {
        if `first' local nlexp "(LR_`x': -_b[L.`x']/_b[L.`depvar'])"
        else       local nlexp "`nlexp' (LR_`x': -_b[L.`x']/_b[L.`depvar'])"
        local first 0
    }
    return scalar chi2 = .
    capture {
        tempname bm Vm bp Vp
        // MG: heterogeneous long run (consistent under H0 and H1)
        qui xtdcce2 D.`depvar' `levterms' `sr' if `touse', `crossopt' reportconstant
        qui nlcom `nlexp'
        matrix `bm' = r(b)
        matrix `Vm' = r(V)
        // PMG: pooled long run (efficient under H0)
        qui xtdcce2 D.`depvar' `levterms' `sr' if `touse', pooled(`levterms') `crossopt' reportconstant
        qui nlcom `nlexp'
        matrix `bp' = r(b)
        matrix `Vp' = r(V)
        // Hausman = d (Vm-Vp)^{-1} d' ,  d = bm-bp ,  df = rank(Vm-Vp)
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
//  HELPER: build UECM regressor list (shared)
// =========================================================================
capture program drop _xtpf_uecm
program define _xtpf_uecm, rclass
    args depvar plags qlags
    // NB: indepvars passed via global to keep args simple
    local indepvars "$XTPF_INDEP"
    local rhs "L.`depvar'"
    foreach x of local indepvars {
        local rhs "`rhs' L.`x'"
    }
    forvalues j = 1/`plags' {
        local rhs "`rhs' L`j'.D.`depvar'"
    }
    foreach x of local indepvars {
        forvalues j = 0/`qlags' {
            if `j' == 0 local rhs "`rhs' D.`x'"
            else        local rhs "`rhs' L`j'.D.`x'"
        }
    }
    return local rhs "`rhs'"
end


// =========================================================================
//  HELPER: Fourier frequency k* selection by pooled minimum SSR
//          (Yilanci, Bozoklu & Gorus 2020; Enders & Lee 2012)
// =========================================================================
capture program drop _xtpf_kselect
program define _xtpf_kselect, rclass
    syntax varlist(ts) [if] , Plags(integer) Qlags(integer) ///
        TIndex(varname) TSpan(integer) MAXK(integer) [ FRACtional TREND ]
    marksample touse
    gettoken depvar indepvars : varlist
    global XTPF_INDEP "`indepvars'"
    _xtpf_uecm `depvar' `plags' `qlags'
    local rhs "`r(rhs)'"
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
    matrix `grid' = J(`nk', 2, .)
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
        if _rc == 0 {
            matrix `grid'[`i',2] = e(rss)
            if e(rss) < `best' | missing(`best') {
                local best = e(rss)
                local kstar = `kval'
            }
        }
    }
    macro drop XTPF_INDEP
    return scalar kstar = `kstar'
    return matrix kgrid = `grid'
end


// =========================================================================
//  HELPER: pooled BIC search of short-run lag orders (p,q)
// =========================================================================
capture program drop _xtpf_lagsearch
program define _xtpf_lagsearch, rclass
    syntax varlist(ts) [if] , MAXP(integer) MAXQ(integer) ///
        TIndex(varname) TSpan(integer) KStar(real)
    marksample touse
    gettoken depvar indepvars : varlist
    global XTPF_INDEP "`indepvars'"

    tempvar s c
    if `kstar' > 0 {
        qui gen double `s' = sin(2*c(pi)*`kstar'*`tindex'/`tspan') if `touse'
        qui gen double `c' = cos(2*c(pi)*`kstar'*`tindex'/`tspan') if `touse'
        local four "`s' `c'"
    }
    local bestbic = .
    local bestp 1
    local bestq 1
    forvalues p = 1/`maxp' {
        forvalues q = 0/`maxq' {
            _xtpf_uecm `depvar' `p' `q'
            capture qui regress D.`depvar' `r(rhs)' `four' if `touse'
            if _rc == 0 {
                local bic = -2*e(ll) + (e(df_m)+1)*ln(e(N))
                if `bic' < `bestbic' | missing(`bestbic') {
                    local bestbic = `bic'
                    local bestp = `p'
                    local bestq = `q'
                }
            }
        }
    }
    macro drop XTPF_INDEP
    return scalar bestp = `bestp'
    return scalar bestq = `bestq'
    return scalar bic   = `bestbic'
end


// =========================================================================
//  HELPER: diagnostics block
// =========================================================================
capture program drop _xtpf_diag
program define _xtpf_diag
    syntax , depvar(string) kstar(real)
    di as txt ""
    di as res _col(3) "Diagnostics"
    di as txt "  {hline 70}"

    // Fourier joint nonlinearity test
    if `kstar' > 0 {
        capture qui test _xtpf_sin _xtpf_cos
        if _rc == 0 {
            local fstat "`r(chi2)'"
            if "`fstat'"=="" | "`fstat'"=="." local fstat "`r(F)'"
            local fp "`r(p)'"
            if "`fp'"=="" local fp "."
            if "`fstat'"!="" & "`fstat'"!="." {
                di as txt _col(5) "Fourier joint significance (H0: no Fourier)" ///
                   _col(52) as res %8.3f `fstat' as txt " [" as res %5.3f `fp' as txt "]"
            }
            else {
                di as txt _col(5) "Fourier joint significance (H0: no Fourier)" ///
                   _col(52) as txt "p = " as res %5.3f `fp'
            }
        }
    }

    // Cross-sectional dependence of residuals (xtcd2 returns CD & p as matrices)
    capture which xtcd2
    if _rc == 0 {
        capture qui xtcd2 _xtpf_resid
        if _rc == 0 {
            tempname cdm cdpm
            capture matrix `cdm'  = r(CD)
            capture matrix `cdpm' = r(p)
            if _rc == 0 {
                local cd  = `cdm'[1,1]
                local cdp = `cdpm'[1,1]
                di as txt _col(5) "Pesaran CD test on residuals (H0: no CSD)" ///
                   _col(52) as res %8.3f `cd' as txt " [" as res %5.3f `cdp' as txt "]"
            }
        }
    }
    else {
        di as txt _col(5) "(install {bf:xtcd2} for residual CSD test)"
    }
    di as txt "  {hline 70}"
end


// =========================================================================
//  HELPER: long-run coefficient plot (point estimate + CI)
// =========================================================================
capture program drop _xtpf_forest
program define _xtpf_forest
    syntax , depvar(string) indepvars(string) [ GRAPHPrefix(string) ]
    tempname B V
    capture matrix `B' = e(lr_b)
    capture matrix `V' = e(lr_V)
    if _rc != 0 exit
    local lrnames "`e(lrnames)'"
    local nb : word count `lrnames'
    if `nb' == 0 exit
    local lvl = e(level)
    local zcrit = invnormal(1-(100-`lvl')/200)

    preserve
    qui {
        clear
        set obs `nb'
        gen double est = .
        gen double lo  = .
        gen double hi  = .
        gen double ord = _n
    }
    local ylab ""
    forvalues j = 1/`nb' {
        local v : word `j' of `lrnames'
        local b  = `B'[1,`j']
        local se = sqrt(`V'[`j',`j'])
        qui replace est = `b' in `j'
        qui replace lo  = `b' - `zcrit'*`se' in `j'
        qui replace hi  = `b' + `zcrit'*`se' in `j'
        local ylab `"`ylab' `j' "`v'""'
    }
    capture noisily {
        twoway (rcap lo hi ord, horizontal lcolor("24 54 104") lwidth(medthick)) ///
               (scatter ord est, mcolor("220 50 47") msymbol(diamond) msize(large)), ///
            yscale(reverse) ///
            ylabel(`ylab', noticks labsize(medsmall)) ///
            ytitle("") ///
            xline(0, lcolor(gs8) lpattern(dash) lwidth(thin)) ///
            xtitle("Long-run coefficient on D.`depvar'", size(medsmall)) ///
            title("{bf:Long-run effects}", size(medlarge) color("24 54 104")) ///
            subtitle("Fourier-augmented panel ARDL  ({&plusminus} `lvl'% CI)", ///
                size(small) color(gs6)) ///
            graphregion(fcolor(white)) plotregion(fcolor(white) lcolor(gs14)) ///
            legend(off) name(xtpf_lrplot, replace)
        capture graph export "`graphprefix'xtpfardl_lr.png", replace width(1400)
    }
    restore
end


// =========================================================================
//  HELPER: Fourier frequency selection plot (SSR vs k)
// =========================================================================
capture program drop _xtpf_kplot
program define _xtpf_kplot
    syntax , kstar(real) [ GRAPHPrefix(string) ]
    tempname G
    capture matrix `G' = e(kgrid)
    if _rc != 0 exit
    local nk = rowsof(`G')
    if `nk' < 2 exit
    preserve
    qui {
        clear
        set obs `nk'
        gen double kval = .
        gen double ssr  = .
    }
    forvalues i = 1/`nk' {
        qui replace kval = `G'[`i',1] in `i'
        qui replace ssr  = `G'[`i',2] in `i'
    }
    qui gen byte isopt = abs(kval-`kstar') < 1e-6
    capture noisily {
        twoway (connected ssr kval, lcolor("24 54 104") mcolor("24 54 104") ///
                   lwidth(medthick) msymbol(circle)) ///
               (scatter ssr kval if isopt, mcolor("220 50 47") ///
                   msymbol(diamond) msize(vlarge)), ///
            title("{bf:Fourier frequency selection}", size(medlarge) color("24 54 104")) ///
            subtitle("Pooled minimum-SSR criterion", size(small) color(gs6)) ///
            xtitle("Fourier frequency (k)", size(medsmall)) ///
            ytitle("Sum of squared residuals", size(medsmall)) ///
            xline(`kstar', lcolor("220 50 47") lpattern(dash) lwidth(thin)) ///
            legend(order(1 "SSR" 2 "k* = `kstar'") size(small) cols(2) ///
                ring(0) pos(1) region(fcolor(white%85) lcolor(gs12))) ///
            graphregion(fcolor(white)) plotregion(fcolor(white) lcolor(gs14)) ///
            ylabel(, labsize(small) angle(0) grid glcolor(gs14%50)) ///
            xlabel(, labsize(small)) ///
            name(xtpf_kplot, replace)
        capture graph export "`graphprefix'xtpfardl_kstar.png", replace width(1400)
    }
    restore
end
