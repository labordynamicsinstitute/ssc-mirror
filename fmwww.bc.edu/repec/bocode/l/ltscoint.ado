*! ltscoint 1.0.0  17sep2026
*! Least Trimmed Squares estimation of a cointegrated ADL with outliers
*! Berenguer-Rico & Nielsen (2026), Oxford Bulletin of Economics and Statistics 88, 690-711
*! Author: Merwan Roudane  (merwanroudane920@gmail.com)  https://github.com/merwanroudane
*
* Step -> equation map (full version in help ltscoint methods)
*   _ltsc_build        regressor vector x_t of eq. (2.2) / (2.3)
*   _ltsc_fastlts      LTS estimator (2.4)-(2.5), FAST-LTS C-steps (Rousseeuw & Van Driessen 2006)
*   _ltsc_exact        exhaustive enumeration of all h-subsets (2.5) for small T
*   _ltsc_profile      T_h = h k3^2/6 + h k4^2/24 profile (BJN 2023 eq. 6.2, Table 7 of the paper)
*   regress + dummies  oracle inference, Theorem 3: OLS on the selected good observations
*   long-run block     kappa = -psi/alpha, delta method (Section 6.1 / supplement)
*   LR test            no cointegration, alpha = 0 (Section 6.3; Harbo et al. 1998; Doornik 1998, 2003)
*   ECM t test         t_alpha with Ericsson & MacKinnon (2002) response surfaces
*   SLTS               standard-LTS variance, Berenguer-Rico & Nielsen (2026 ET) eq. (2.4)

program define ltscoint, rclass
    version 14.0
    gettoken sub rest : 0, parse(" ,")
    local sub1 = lower(`"`sub'"')
    if ("`sub1'"=="hsearch" | "`sub1'"=="h") {
        _ltsc_hsearch `rest'
        return add
        exit
    }
    if ("`sub1'"=="graph") {
        _ltsc_graph `rest'
        exit
    }
    if ("`sub1'"=="dataplot") {
        _ltsc_dataplot `rest'
        exit
    }
    if ("`sub1'"=="version") {
        di as text "ltscoint 1.0.0  17sep2026"
        exit
    }
    _ltsc_est `0'
end

* ============================================================================
*  MAIN ESTIMATOR
* ============================================================================
program define _ltsc_est, eclass
    version 14.0
    syntax varlist(min=2 numeric ts) [if] [in] [, H(integer -1) NOUT(integer -1)       ///
        LAGS(integer 2) TREND HMIN(integer -1) HMAX(integer -1) HSel(string)          ///
        NSAMP(integer 500) CSTEPS(integer 2) NKEEP(integer 10) SEED(integer -1)        ///
        EXACT SLTS SIGma(string) LEVel(cilevel) KAPPA0(numlist) WEtest FORCE           ///
        GENerate(name) GRaph NAME(string) noTESTS noOLS noHEADer ]

    * ---- time-series setup -------------------------------------------------
    capture tsset
    if (_rc) {
        di as err "the data must be {bf:tsset} (time series) before using {bf:ltscoint}"
        exit 459
    }
    local tvar "`r(timevar)'"
    if ("`r(panelvar)'"!="") {
        di as err "ltscoint is a time-series command; a panel is tsset. Use a single series."
        exit 459
    }
    if ("`sigma'"=="") local sigma "df"
    if (!inlist("`sigma'","df","h","n")) {
        di as err "sigma() must be one of df, h, n"
        exit 198
    }
    if (`lags'<1) {
        di as err "lags() must be >= 1"
        exit 198
    }
    if ("`hsel'"=="") local hsel "cumulant"
    if (!inlist("`hsel'","cumulant","ic")) {
        di as err "hsel() must be cumulant or ic"
        exit 198
    }
    if (`h'>0 & `nout'>=0) {
        di as err "specify only one of h() and nout()"
        exit 198
    }
    if ("`generate'"!="") {
        capture confirm new variable `generate'
        if (_rc) {
            di as err "generate(): variable `generate' already exists"
            exit 110
        }
    }

    * ---- build regressors ----------------------------------------------------
    gettoken depvar zvars : varlist
    marksample touse
    tempvar dy tt
    local nz : word count `zvars'
    local nx = 2*`nz' + 1 + (`lags'-1)*(1+`nz')
    local xv ""
    forvalues i = 1/`nx' {
        tempvar x`i'
        local xv "`xv' `x`i''"
    }
    _ltsc_build `depvar' `zvars', lags(`lags') `trend' touse(`touse') dy(`dy') tt(`tt') xv(`xv')
    local xvars   "`r(xvars)'"      // tempvar list, paper order (2.2)
    local xnames  "`r(xnames)'"     // display names
    local xlev    "`r(xlev)'"       // tempvars of L.y, L.z1..
    local ndz     = r(ndz)
    local nlev    = r(nlev)
    local nshort  = r(nshort)
    local K       = r(K)
    local nz : word count `zvars'
    markout `touse' `dy' `xvars'
    qui count if `touse'
    local n = r(N)
    if (`n' <= `K'+2) {
        di as err "too few usable observations (`n') for `K' regressors"
        exit 2001
    }

    * ---- h / nout logic -----------------------------------------------------
    local searched 0
    local hmin0 = floor(2*`n'/3) + 1
    if (`hmin'<0) local hmin = `hmin0'
    if (`hmax'<0) local hmax = `n'
    if (`nout'>=0) local h = `n' - `nout'
    if (`h'<0) {
        local searched 1
    }
    else {
        if (`h' > `n') {
            di as err "h() cannot exceed the number of usable observations (`n')"
            exit 198
        }
        if (`h' <= `K') {
            di as err "h() must exceed the number of regressors (`K')"
            exit 198
        }
        if (`h' <= 2*`n'/3 & "`force'"=="") {
            di as err "h = `h' <= 2T/3 = " %5.1f 2*`n'/3 ": boundedness of LTS fails in the cointegrated ADL"
            di as err "(Berenguer-Rico & Nielsen 2026, eq. 4.8, Remark B.1). Use {bf:force} to override."
            exit 498
        }
    }
    if (`hmin' <= `K') local hmin = `K' + 1
    if (`hmax' > `n')  local hmax = `n'
    if (`hmin' > `hmax') {
        di as err "hmin() > hmax()"
        exit 198
    }

    * ---- LTS in Mata ----------------------------------------------------------
    tempvar good
    qui gen byte `good' = 0
    tempname PROF GOODM
    if (`searched') {
        mata: _ltsc_profile("`dy'", "`xvars'", "`touse'", `hmin', `hmax', `nsamp', `csteps', ///
                            `nkeep', `seed', "`exact'"!="", `nz', "`PROF'", "`GOODM'")
        * choose h: minimiser of T_h (cumulant) or IC_h
        local col = cond("`hsel'"=="cumulant", 3, 4)
        mata: st_local("hopt", strofreal(_ltsc_argmin(st_matrix("`PROF'"), `col')))
        local h = `hopt'
        local ih = `h' - `hmin' + 1
        mata: st_store(., "`good'", "`touse'", st_matrix("`GOODM'")[., `ih'])
        mata: st_numscalar("r(rss)", st_matrix("`PROF'")[`ih', 5])
        local rss = r(rss)
    }
    else {
        mata: _ltsc_run("`dy'", "`xvars'", "`touse'", `h', `nsamp', `csteps', `nkeep', `seed', ///
                        "`exact'"!="", "`good'")
        local rss = r(rss)
        local nsing = r(nsing)
    }
    local nout = `n' - `h'
    if (`nout' > sqrt(`n')) {
        di as txt "note: T - h = `nout' > sqrt(T) = " %5.2f sqrt(`n') ///
            ": beyond the o(sqrt(T)/log T) regime of Theorem 3 (eq. 4.12); simulations in the paper show inference may deteriorate"
    }

    * ---- outlier dummies and oracle OLS (Theorem 3) --------------------------
    local dumlist ""
    local outyears ""
    tempname OUTL
    if (`nout'>0) {
        qui levelsof `tvar' if `touse' & `good'==0, local(outyears)
        matrix `OUTL' = J(1, `nout', .)
        local j 0
        foreach yr of local outyears {
            local ++j
            tempvar d`j'
            qui gen byte `d`j'' = (`tvar'==`yr') if `touse'
            local dumlist "`dumlist' `d`j''"
            matrix `OUTL'[1, `j'] = `yr'
        }
        matrix colnames `OUTL' = `outyears'
        matrix rownames `OUTL' = `tvar'
    }
    * unrestricted LTS-augmented regression = OLS on the good observations
    qui regress `dy' `xvars' `dumlist' if `touse'
    tempname bL VL bfull Vfull
    matrix `bfull' = e(b)
    matrix `Vfull' = e(V)
    local ncf = colsof(`bfull')
    if (`nout'>0) {
        matrix `bL' = `bfull'[1, 1..`K'-1], `bfull'[1, `ncf']
        matrix `VL' = (`Vfull'[1..`K'-1, 1..`K'-1], `Vfull'[1..`K'-1, `ncf'] \ `Vfull'[`ncf', 1..`K'-1], `Vfull'[`ncf', `ncf'])
    }
    else {
        matrix `bL' = `bfull'
        matrix `VL' = `Vfull'
    }
    local rss_u = e(rss)
    local ll_L  = e(ll)
    local s2_df = `rss_u' / (`h' - `K')
    if ("`sigma'"=="df") local s2 = `s2_df'
    if ("`sigma'"=="h")  local s2 = `rss_u' / `h'
    if ("`sigma'"=="n")  local s2 = `rss_u' / (`n' - `K')
    matrix `VL' = `VL' * (`s2' / `s2_df')
    local sigma_L = sqrt(`s2')
    * SLTS variance (Berenguer-Rico & Nielsen 2026 ET, eq. 2.4)
    local lambda = `h' / `n'
    local cq = invnormal((1 + `lambda')/2)
    local varsig2 = (`lambda' - 2*`cq'*normalden(`cq')) / `lambda'
    tempname VS
    matrix `VS' = `VL' / (`varsig2'^2)
    * residuals: eL from the dummy regression (0 at outliers); eA = LTS residual for every observation
    tempvar eL eA xbL
    qui predict double `eL' if `touse', resid
    tempname bLs
    matrix `bLs' = `bL'
    matrix colnames `bLs' = `xvars' _cons
    qui matrix score double `xbL' = `bLs' if `touse'
    qui gen double `eA' = `dy' - `xbL' if `touse'

    * ---- full-sample OLS for comparison ---------------------------------------
    tempname bO VO
    tempvar eO
    qui regress `dy' `xvars' if `touse'
    matrix `bO' = e(b)
    matrix `VO' = e(V)
    local ll_O = e(ll)
    local sigma_O = sqrt(e(rss)/(`n' - `K'))
    local rss_O = e(rss)
    qui predict double `eO' if `touse', resid

    * ---- long-run block: kappa_j = -psi_j / alpha ------------------------------
    * positions: x = (dz_1..dz_nz, L.y, L.z_1..L.z_nz, short-run..., [trend], _cons)
    local pa = `nz' + 1
    tempname KAP KAPO
    matrix `KAP'  = J(`nz'+1, 4, .)
    matrix `KAPO' = J(`nz'+1, 4, .)
    local rn ""
    foreach zz of local zvars {
        local rn "`rn' `zz'"
    }
    local rn "`rn' _nu"
    matrix rownames `KAP'  = `rn'
    matrix rownames `KAPO' = `rn'
    matrix colnames `KAP'  = kappa se z p
    matrix colnames `KAPO' = kappa se z p
    _ltsc_longrun `bL' `VL' `KAP' `nz' `K' "`trend'"
    _ltsc_longrun `bO' `VO' `KAPO' `nz' `K' "`trend'"
    local alpha_L = `bL'[1, `pa']
    local alpha_O = `bO'[1, `pa']
    local se_alpha_L = sqrt(`VL'[`pa', `pa'])
    local se_alpha_O = sqrt(`VO'[`pa', `pa'])

    * ---- tests for no cointegration ------------------------------------------
    local dotests = ("`tests'"=="")
    if (`dotests') {
        * restricted model: drop the levels and the restricted deterministic term
        local xrest ""
        local iw 0
        foreach v of local xvars {
            local ++iw
            local keep 1
            if (`iw' > `nz' & `iw' <= 2*`nz'+1) local keep 0      // L.y, L.z
            if ("`trend'"!="" & `iw'==`K') local keep 0               // trend (case H_l)
            if (`keep') local xrest "`xrest' `v'"
        }
        if ("`trend'"=="") {
            qui regress `dy' `xrest' `dumlist' if `touse', noconstant     // case H_c: constant is restricted
        }
        else {
            qui regress `dy' `xrest' `dumlist' if `touse'
        }
        local rss_r = e(rss)
        local LR_L = `n' * ln(`rss_r' / `rss_u')
        qui regress `dy' `xrest' if `touse' `=cond("`trend'"=="", ", noconstant", "")'
        local LR_O = `n' * ln(e(rss) / `rss_O')
        * Doornik (2003) gamma approximation, partial system, p1-r = 1, p2 = nz
        tempname CVLR
        matrix `CVLR' = J(1, 6, .)
        local case = cond("`trend'"=="", "c", "l")
        mata: _ltsc_lrcv(`nz', "`case'", `LR_L', `LR_O', "`CVLR'")
        local LR_p_L = r(p_L)
        local LR_p_O = r(p_O)
        local lrmean = r(mean)
        local lrvar  = r(var)
        * ECM t statistic, Ericsson & MacKinnon (2002) response surfaces
        local t_alpha_L = `alpha_L' / `se_alpha_L'
        local t_alpha_O = `alpha_O' / `se_alpha_O'
        tempname CVT CVTO
        matrix `CVT'  = J(1, 3, .)
        matrix `CVTO' = J(1, 3, .)
        local kk = `nz' + 1
        mata: _ltsc_ecmcv(`kk', "`case'", `h' - `K', "`CVT'")
        mata: _ltsc_ecmcv(`kk', "`case'", `n' - `K', "`CVTO'")
    }

    * ---- mis-specification tests (on the good observations) ---------------------
    tempname MISL MISO
    matrix `MISL' = J(5, 4, .)
    matrix `MISO' = J(5, 4, .)
    matrix rownames `MISL' = F_ar12 F_arch1 chi2_norm F_hetero T_h
    matrix rownames `MISO' = F_ar12 F_arch1 chi2_norm F_hetero T_h
    matrix colnames `MISL' = stat df1 df2 p
    matrix colnames `MISO' = stat df1 df2 p
    _ltsc_misspec `dy' "`xvars'" "`dumlist'" `eL' `good' `touse' `MISL' `nout'
    tempvar allone
    qui gen byte `allone' = 1
    _ltsc_misspec `dy' "`xvars'" "" `eO' `allone' `touse' `MISO' 0

    * ---- weak exogeneity regressions ---------------------------------------------
    tempname WE
    if ("`wetest'"!="") {
        matrix `WE' = J(`nz', 4, .)
        matrix colnames `WE' = coef se t p
        matrix rownames `WE' = `zvars'
        _ltsc_wetest `depvar' "`zvars'" "`xvars'" "`dumlist'" `touse' `nz' `K' `KAP' `WE' `lags' "`trend'" "`kappa0'"
    }

    * ---- sample range -------------------------------------------------------------
    qui sum `tvar' if `touse', meanonly
    local t0 = r(min)
    local t1 = r(max)
    local tfmt : format `tvar'

    * ---- DISPLAY --------------------------------------------------------------------
    if ("`header'"=="") {
        _ltsc_header "`depvar'" "`zvars'" `lags' "`trend'" `n' `h' `nout' `t0' `t1' "`tfmt'" `searched' "`hsel'" `hmin' `hmax' "`exact'" `nsamp'
    }
    _ltsc_coeftab `bO' `VO' `bL' `VL' `VS' "`xnames'" `nz' `K' `nshort' "`trend'" `level' "`slts'" "`ols'" `n' `h' "`depvar'"
    di as txt "{hline 78}"
    if ("`ols'"=="") {
        di as txt "  sigma          " as res %10.5f `sigma_O' as txt "      " as res %10.5f `sigma_L'
        di as txt "  log-likelihood " as res %10.3f `ll_O'    as txt "      " as res %10.3f `ll_L'
        di as txt "  T (h)          " as res %10.0f `n'       as txt "      " as res %10.0f `n' as txt " (h = " as res `h' as txt ")"
    }
    else {
        di as txt "  sigma          " as res %10.5f `sigma_L'
        di as txt "  log-likelihood " as res %10.3f `ll_L'
        di as txt "  T (h)          " as res %10.0f `n' as txt " (h = " as res `h' as txt ")"
    }
    di as txt "{hline 78}"
    _ltsc_mistab `MISO' `MISL' "`ols'"
    _ltsc_lrtab `KAPO' `KAP' `nz' "`ols'" `level' "`kappa0'" "`trend'" "`zvars'"
    if (`dotests') {
        _ltsc_cointtab `LR_O' `LR_L' `LR_p_O' `LR_p_L' `CVLR' `t_alpha_O' `t_alpha_L' `CVTO' `CVT' `nz' "`case'" "`ols'"
    }
    if ("`wetest'"!="") {
        _ltsc_wetab `WE' "`zvars'" "`kappa0'"
    }
    if (`nout'>0) {
        di as txt "Outliers identified by LTS (T - h = `nout'): " _c
        local j 0
        foreach yr of local outyears {
            local ++j
            local yrs : di `tfmt' `yr'
            local yrs = trim("`yrs'")
            if (`j'>1) di as txt ", " _c
            di as res "`yrs'" _c
        }
        di
    }
    else {
        di as txt "No outliers: h = T, LTS = full-sample OLS."
    }
    if (`searched') {
        local hs = cond("`hsel'"=="cumulant", "cumulant normality statistic T_h", "information criterion IC_h")
        di as txt "h selected by minimising the `hs' over h = `hmin',...,`hmax'; see {bf:ltscoint hsearch}."
    }
    di as txt "{hline 78}"

    * ---- graph ----------------------------------------------------------------------
    if ("`graph'"!="") {
        if ("`name'"=="") local name "ltscoint"
        _ltsc_dash `dy' `eA' `eO' `good' `touse' `tvar' "`depvar'" `sigma_L' `sigma_O' "`name'"
    }

    * ---- ereturn -----------------------------------------------------------------------
    if ("`generate'"!="") {
        qui gen byte `generate' = `good' if `touse'
        label var `generate' "1 = good observation selected by LTS, 0 = outlier"
    }
    tempname b V
    matrix `b' = `bL'
    matrix `V' = `VL'
    if ("`slts'"!="") matrix `V' = `VS'
    matrix colnames `b' = `xnames'
    matrix colnames `V' = `xnames'
    matrix rownames `V' = `xnames'
    ereturn post `b' `V', esample(`touse') depname(`depvar') obs(`n')
    ereturn scalar N       = `n'
    ereturn scalar h       = `h'
    ereturn scalar nout    = `nout'
    ereturn scalar lambda  = `lambda'
    ereturn scalar K       = `K'
    ereturn scalar lags    = `lags'
    ereturn scalar rss     = `rss_u'
    ereturn scalar sigma   = `sigma_L'
    ereturn scalar sigma2  = `s2'
    ereturn scalar ll      = `ll_L'
    ereturn scalar sigma_ols = `sigma_O'
    ereturn scalar ll_ols    = `ll_O'
    ereturn scalar rss_ols   = `rss_O'
    ereturn scalar alpha     = `alpha_L'
    ereturn scalar se_alpha  = `se_alpha_L'
    ereturn scalar varsigma2 = `varsig2'
    ereturn scalar tmin      = `t0'
    ereturn scalar tmax      = `t1'
    ereturn scalar searched  = `searched'
    ereturn scalar hmin      = `hmin'
    ereturn scalar hmax      = `hmax'
    ereturn scalar T_h       = `MISL'[5,1]
    if (`dotests') {
        ereturn scalar LR      = `LR_L'
        ereturn scalar LR_p    = `LR_p_L'
        ereturn scalar LR_ols  = `LR_O'
        ereturn scalar LR_p_ols = `LR_p_O'
        ereturn scalar t_alpha = `t_alpha_L'
        ereturn scalar t_alpha_ols = `t_alpha_O'
        matrix colnames `CVLR' = q50 q80 q90 q95 q975 q99
        ereturn matrix LR_cv = `CVLR'
        matrix colnames `CVT' = cv1 cv5 cv10
        ereturn matrix t_alpha_cv = `CVT'
    }
    ereturn matrix kappa     = `KAP'
    ereturn matrix kappa_ols = `KAPO'
    ereturn matrix misspec     = `MISL'
    ereturn matrix misspec_ols = `MISO'
    matrix colnames `bO' = `xnames'
    matrix colnames `VO' = `xnames'
    matrix rownames `VO' = `xnames'
    ereturn matrix b_ols = `bO'
    ereturn matrix V_ols = `VO'
    matrix colnames `VS' = `xnames'
    matrix rownames `VS' = `xnames'
    ereturn matrix V_slts = `VS'
    if (`nout'>0) ereturn matrix outliers = `OUTL'
    if (`searched') {
        matrix colnames `PROF' = h nout T_h IC_h rss sigma alpha
        ereturn matrix hprofile = `PROF'
    }
    if ("`wetest'"!="") ereturn matrix wetest = `WE'
    ereturn local outyears "`outyears'"
    ereturn local depvar   "`depvar'"
    ereturn local zvars    "`zvars'"
    ereturn local xnames   "`xnames'"
    ereturn local timevar  "`tvar'"
    ereturn local trend    "`trend'"
    ereturn local sigma_opt "`sigma'"
    local vcetxt = cond("`slts'"=="", "oracle OLS on selected observations (Theorem 3)", "SLTS: oracle / varsigma^4")
    ereturn local vce      "`vcetxt'"
    ereturn local hsel     "`hsel'"
    local algtxt = cond("`exact'"=="", "FAST-LTS", "exact enumeration")
    ereturn local algorithm "`algtxt'"
    ereturn local title    "Least Trimmed Squares cointegrated ADL"
    ereturn local cmdline  "ltscoint `0'"
    ereturn local cmd      "ltscoint"
end

* ============================================================================
*  REGRESSOR BUILDER  — eq. (2.2) / (2.3)
*  x_t = (Dz_t', y_{t-1}, z_{t-1}', Dx_{t-1}', ..., Dx_{t-k+1}', [t], 1)'
* ============================================================================
program define _ltsc_build, rclass
    * tempvars are created by the CALLER (names in xv()) so they survive this program's exit
    syntax varlist(min=1 ts), lags(integer) touse(name) dy(name) tt(name) xv(string) [TREND]
    gettoken depvar zvars : varlist
    qui gen double `dy' = D.`depvar' if `touse'
    local xvars ""
    local xnames ""
    local ndz 0
    local ix 0
    foreach z of local zvars {
        local ++ix
        local v : word `ix' of `xv'
        qui gen double `v' = D.`z' if `touse'
        local xvars "`xvars' `v'"
        local xnames "`xnames' D.`z'"
        local ++ndz
    }
    local ++ix
    local v : word `ix' of `xv'
    qui gen double `v' = L.`depvar' if `touse'
    local xvars "`xvars' `v'"
    local xnames "`xnames' L.`depvar'"
    local xlev "`v'"
    local nlev 1
    foreach z of local zvars {
        local ++ix
        local v : word `ix' of `xv'
        qui gen double `v' = L.`z' if `touse'
        local xvars "`xvars' `v'"
        local xnames "`xnames' L.`z'"
        local xlev "`xlev' `v'"
        local ++nlev
    }
    local nshort 0
    forvalues j = 1/`=`lags'-1' {
        local ++ix
        local v : word `ix' of `xv'
        qui gen double `v' = L`j'D.`depvar' if `touse'
        local xvars "`xvars' `v'"
        local xnames "`xnames' L`j'D.`depvar'"
        local ++nshort
        foreach z of local zvars {
            local ++ix
            local v : word `ix' of `xv'
            qui gen double `v' = L`j'D.`z' if `touse'
            local xvars "`xvars' `v'"
            local xnames "`xnames' L`j'D.`z'"
            local ++nshort
        }
    }
    if ("`trend'"!="") {
        capture tsset
        local tv "`r(timevar)'"
        qui sum `tv' if `touse', meanonly
        qui gen double `tt' = `tv' - r(min) + 1 if `touse'
        local xvars "`xvars' `tt'"
        local xnames "`xnames' trend"
    }
    local K : word count `xvars'
    local K = `K' + 1
    local xnames "`xnames' _cons"
    return local xvars  "`xvars'"
    return local xnames "`xnames'"
    return local xlev   "`xlev'"
    return scalar ndz    = `ndz'
    return scalar nlev   = `nlev'
    return scalar nshort = `nshort'
    return scalar K      = `K'
end

* ============================================================================
*  LONG-RUN BLOCK: kappa_j = -psi_j/alpha ; nu = -mu/alpha (delta method)
* ============================================================================
program define _ltsc_longrun
    args b V KAP nz K trend
    local pa = `nz' + 1
    local alpha = `b'[1, `pa']
    tempname D
    forvalues j = 1/`nz' {
        local pp = `pa' + `j'
        local psi = `b'[1, `pp']
        local kap = -`psi' / `alpha'
        matrix `D' = J(1, `K', 0)
        matrix `D'[1, `pa'] = `psi' / ((`alpha')^2)
        matrix `D'[1, `pp'] = -1 / `alpha'
        tempname vv
        matrix `vv' = `D' * `V' * `D''
        local se = sqrt(`vv'[1,1])
        matrix `KAP'[`j', 1] = `kap'
        matrix `KAP'[`j', 2] = `se'
        matrix `KAP'[`j', 3] = `kap' / `se'
        matrix `KAP'[`j', 4] = 2*normal(-abs(`kap' / `se'))
    }
    * nu: constant case  nu_c = -mu/alpha (mu = _cons);  trend case  nu_l = -coef(t)/alpha
    local pm = cond("`trend'"=="", `K', `K'-1)
    local mu = `b'[1, `pm']
    local nu = -`mu' / `alpha'
    matrix `D' = J(1, `K', 0)
    matrix `D'[1, `pa'] = `mu' / ((`alpha')^2)
    matrix `D'[1, `pm'] = -1 / `alpha'
    tempname vv
    matrix `vv' = `D' * `V' * `D''
    local se = sqrt(`vv'[1,1])
    matrix `KAP'[`nz'+1, 1] = `nu'
    matrix `KAP'[`nz'+1, 2] = `se'
    matrix `KAP'[`nz'+1, 3] = `nu' / `se'
    matrix `KAP'[`nz'+1, 4] = 2*normal(-abs(`nu' / `se'))
end

* ============================================================================
*  MIS-SPECIFICATION TESTS on the retained observations (PcGive-style F forms)
* ============================================================================
program define _ltsc_misspec
    args dy xvars dumlist e good touse M nout
    tempname hold
    capture _estimates hold `hold', restore nullok
    local K : word count `xvars'
    local K = `K' + 1
    qui count if `touse'
    local n = r(N)
    * --- F_ar(1-2): Godfrey (1978) LM in F form, lagged residuals set to 0 where missing
    tempvar e1 e2
    qui gen double `e1' = L.`e' if `touse'
    qui gen double `e2' = L2.`e' if `touse'
    qui replace `e1' = 0 if `touse' & `e1'>=.
    qui replace `e2' = 0 if `touse' & `e2'>=.
    qui regress `e' `xvars' `dumlist' `e1' `e2' if `touse'
    qui test `e1' `e2'
    matrix `M'[1,1] = r(F)
    matrix `M'[1,2] = r(df)
    matrix `M'[1,3] = r(df_r)
    matrix `M'[1,4] = r(p)
    * --- F_arch(1): Engle (1982), regression of e^2 on lagged e^2 (good obs only)
    tempvar e2sq le2
    qui gen double `e2sq' = `e'^2 if `touse' & `good'
    qui gen double `le2'  = L.`e2sq'
    qui regress `e2sq' `le2' if `touse' & `good'
    matrix `M'[2,1] = e(F)
    matrix `M'[2,2] = e(df_m)
    matrix `M'[2,3] = e(df_r)
    matrix `M'[2,4] = Ftail(e(df_m), e(df_r), e(F))
    * --- chi2_normal(2): Doornik & Hansen (2008) on the retained residuals
    capture mvtest normality `e' if `touse' & `good', stats(dhansen)
    if (!_rc) {
        matrix `M'[3,1] = r(chi2_dh)
        matrix `M'[3,2] = 2
        matrix `M'[3,4] = r(p_dh)
    }
    * --- F_hetero: White (1980) without cross-products (regressors and their squares)
    local sq ""
    foreach v of local xvars {
        tempvar s
        qui gen double `s' = `v'^2 if `touse'
        local sq "`sq' `s'"
    }
    qui regress `e2sq' `xvars' `sq' `dumlist' if `touse' & `good'
    qui test `xvars' `sq'
    matrix `M'[4,1] = r(F)
    matrix `M'[4,2] = r(df)
    matrix `M'[4,3] = r(df_r)
    matrix `M'[4,4] = r(p)
    * --- T_h: cumulant statistic of Berenguer-Rico, Johansen & Nielsen (2023, eq. 6.2)
    qui sum `e' if `touse' & `good', detail
    local hh = r(N)
    local k3 = r(skewness)
    local k4 = r(kurtosis) - 3
    matrix `M'[5,1] = `hh' * ((`k3')^2/6 + (`k4')^2/24)
    matrix `M'[5,2] = 2
    matrix `M'[5,4] = chi2tail(2, `M'[5,1])
end

* ============================================================================
*  WEAK EXOGENEITY: D.z_j on (y - kappa'z)_{t-1}, deterministic terms, lagged D's, dummies
* ============================================================================
program define _ltsc_wetest
    args depvar zvars xvars dumlist touse nz K KAP WE lags trend kappa0
    tempname hold
    capture _estimates hold `hold', restore nullok
    tempvar ec
    qui gen double `ec' = L.`depvar' if `touse'
    local j 0
    foreach z of local zvars {
        local ++j
        local kj = `KAP'[`j', 1]
        if ("`kappa0'"!="") {
            local kj : word `j' of `kappa0'
        }
        qui replace `ec' = `ec' - `kj' * L.`z' if `touse'
    }
    * short-run part of xvars: positions 2*nz+2 .. (K-1 [-1 if trend])
    local short ""
    local iw 0
    foreach v of local xvars {
        local ++iw
        if (`iw' > 2*`nz'+1) local short "`short' `v'"
    }
    local j 0
    foreach z of local zvars {
        local ++j
        tempvar dz
        qui gen double `dz' = D.`z' if `touse'
        qui regress `dz' `ec' `short' `dumlist' if `touse'
        matrix `WE'[`j',1] = _b[`ec']
        matrix `WE'[`j',2] = _se[`ec']
        matrix `WE'[`j',3] = _b[`ec'] / _se[`ec']
        matrix `WE'[`j',4] = 2*ttail(e(df_r), abs(_b[`ec'] / _se[`ec']))
    }
end

* ============================================================================
*  H-SEARCH SUBCOMMAND: profile of T_h / IC_h over h (Table 7 of the paper)
* ============================================================================
program define _ltsc_hsearch, rclass
    version 14.0
    syntax varlist(min=2 numeric ts) [if] [in] [, LAGS(integer 2) TREND HMIN(integer -1) HMAX(integer -1) ///
        NSAMP(integer 500) CSTEPS(integer 2) NKEEP(integer 10) SEED(integer -1) EXACT GRaph NAME(string) ///
        noOUTliers ]
    capture tsset
    if (_rc) {
        di as err "the data must be {bf:tsset}"
        exit 459
    }
    local tvar "`r(timevar)'"
    gettoken depvar zvars : varlist
    marksample touse
    tempvar dy tt
    local nz : word count `zvars'
    local nx = 2*`nz' + 1 + (`lags'-1)*(1+`nz')
    local xv ""
    forvalues i = 1/`nx' {
        tempvar x`i'
        local xv "`xv' `x`i''"
    }
    _ltsc_build `depvar' `zvars', lags(`lags') `trend' touse(`touse') dy(`dy') tt(`tt') xv(`xv')
    local xvars  "`r(xvars)'"
    local xnames "`r(xnames)'"
    local K = r(K)
    markout `touse' `dy' `xvars'
    qui count if `touse'
    local n = r(N)
    if (`hmin'<0) local hmin = floor(2*`n'/3) + 1
    if (`hmin'<=`K') local hmin = `K'+1
    if (`hmax'<0 | `hmax'>`n') local hmax = `n'
    tempname PROF GOODM
    mata: _ltsc_profile("`dy'", "`xvars'", "`touse'", `hmin', `hmax', `nsamp', `csteps', ///
                        `nkeep', `seed', "`exact'"!="", `nz', "`PROF'", "`GOODM'")
    local nh = `hmax' - `hmin' + 1
    mata: st_local("hT",  strofreal(_ltsc_argmin(st_matrix("`PROF'"), 3)))
    mata: st_local("hIC", strofreal(_ltsc_argmin(st_matrix("`PROF'"), 4)))
    local tfmt : format `tvar'
    * kappa for first z at each h from the stored coefficients
    local pa = `nz' + 1
    di as txt ""
    di as txt "Determining h: LTS profile of the cumulant normality statistic T_h and IC_h"
    di as txt "Berenguer-Rico, Johansen & Nielsen (2023, eqs 6.1-6.2); B-R & Nielsen (2026, Table 7)"
    di as txt "Dependent variable: D.`depvar'   ADL(`lags')`=cond("`trend'"!=""," with trend","")'   T = `n'   h = `hmin',...,`hmax'"
    di as txt "{hline 78}"
    di as txt %6s "h" %7s "T-h" %11s "T_h" %10s "IC_h" %10s "sigma" %10s "alpha" %10s "kappa_1" "   outliers"
    di as txt "{hline 78}"
    forvalues i = 1/`nh' {
        local hh  = `PROF'[`i',1]
        local nn  = `PROF'[`i',2]
        local Th  = `PROF'[`i',3]
        local IC  = `PROF'[`i',4]
        local sg  = `PROF'[`i',6]
        local al  = `PROF'[`i',7]
        local ps  = `PROF'[`i',8]
        local kp  = -`ps' / `al'
        local mark ""
        if (`hh'==`hT')  local mark "`mark'T"
        if (`hh'==`hIC') local mark "`mark'I"
        di as res %6.0f `hh' %7.0f `nn' %11.3f `Th' %10.3f `IC' %10.5f `sg' %10.3f `al' %10.3f `kp' as txt "  " _c
        if ("`outliers'"=="" & `nn'>0 & `nn'<=6) {
            mata: st_local("ol", _ltsc_outlist(st_matrix("`GOODM'")[., `i'], "`tvar'", "`touse'", "`tfmt'"))
            di as txt "`ol'" _c
        }
        else if (`nn'>6) di as txt "(`nn' obs)" _c
        di as txt " `mark'"
    }
    di as txt "{hline 78}"
    di as txt "T = argmin T_h at h = " as res `hT' as txt " (T-h = " as res `n'-`hT' as txt ")" ///
        as txt ";  I = argmin IC_h at h = " as res `hIC' as txt " (T-h = " as res `n'-`hIC' as txt ")"
    di as txt "T_h = h k3^2/6 + h k4^2/24 on the h retained residuals;"
    di as txt "IC_h = log(sigma_h^2) + 2 log log(T) (T-h)/T."
    di as txt "Search restricted to h > 2T/3 (boundedness, eq. 4.8) unless hmin() is set."
    if ("`graph'"!="") {
        if ("`name'"=="") local name "ltscoint_h"
        _ltsc_hplot `PROF' `n' `hT' `hIC' "`name'" `nz'
    }
    matrix colnames `PROF' = h nout T_h IC_h rss sigma alpha psi1
    return matrix hprofile = `PROF'
    return scalar h_T  = `hT'
    return scalar h_IC = `hIC'
    return scalar N    = `n'
    return scalar hmin = `hmin'
    return scalar hmax = `hmax'
end

* ============================================================================
*  DISPLAY HELPERS
* ============================================================================
program define _ltsc_header
    args depvar zvars lags trend n h nout t0 t1 tfmt searched hsel hmin hmax exact nsamp
    local s0 : di `tfmt' `t0'
    local s1 : di `tfmt' `t1'
    local s0 = trim("`s0'")
    local s1 = trim("`s1'")
    di as txt ""
    di as txt "Least Trimmed Squares estimation of a cointegrated ADL" _col(58) "Sample: " as res "`s0' - `s1'"
    di as txt "Berenguer-Rico & Nielsen (2026, OBES 88, 690-711)"     _col(58) "T=" as res `n' as txt "  h=" as res `h' as txt "  T-h=" as res `nout'
    di as txt "EC form (2.1)/(2.3): D.`depvar' on " _c
    local nz : word count `zvars'
    local j 0
    foreach z of local zvars {
        local ++j
        if (`j'>1) di as txt ", " _c
        di as res "`z'" _c
    }
    di as txt ";  ADL(`lags')" _c
    if ("`trend'"!="") di as txt ", constant + restricted trend" _c
    else di as txt ", restricted constant" _c
    di
    local alg = cond("`exact'"=="", "FAST-LTS (nsamp = `nsamp')", "exact enumeration")
    di as txt "LTS algorithm: `alg';  breakdown bound h > 2T/3 = " as res %5.1f 2*`n'/3
end

program define _ltsc_coeftab
    args bO VO bL VL VS xnames nz K nshort trend level slts ols n h depvar
    local showols = ("`ols'"=="")
    di as txt "{hline 78}"
    if (`showols') {
        di as txt _col(19) "|" _col(24) "Full-sample OLS" _col(48) "|" _col(56) "LTS, h = `h'"
        di as txt %-18s "  D.`depvar'" "|" %9s "Coef." %9s "Std.Err." %7s "t" "  |" %9s "Coef." %9s "Std.Err." %7s "t"
    }
    else {
        di as txt %-18s "  D.`depvar'" "|" %10s "Coef." %10s "Std.Err." %7s "t" "     [" `level' "% Conf. Interval]"
    }
    di as txt "{hline 78}"
    local tcrit = invttail(`h'-`K', (100-`level')/200)
    local i 0
    local lastgrp ""
    foreach nm of local xnames {
        local ++i
        if (`i' <= `nz') local grp "Short run (contemporaneous)"
        else if (`i' <= 2*`nz'+1) local grp "Levels (equilibrium correction)"
        else if (`i' <= 2*`nz'+1+`nshort') local grp "Short run (lagged differences)"
        else local grp "Deterministic terms"
        if ("`grp'"!="`lastgrp'") {
            di as txt "  {it:`grp'}"
            local lastgrp "`grp'"
        }
        local bo = `bO'[1,`i']
        local so = sqrt(`VO'[`i',`i'])
        local bl = `bL'[1,`i']
        local sl = sqrt(`VL'[`i',`i'])
        if ("`slts'"!="") local sl = sqrt(`VS'[`i',`i'])
        local to = `bo'/`so'
        local tl = `bl'/`sl'
        local pl = 2*ttail(`h'-`K', abs(`tl'))
        local po = 2*ttail(`n'-`K', abs(`to'))
        local stl = cond(`pl'<.01,"***",cond(`pl'<.05,"** ",cond(`pl'<.10,"*  ","   ")))
        local sto = cond(`po'<.01,"***",cond(`po'<.05,"** ",cond(`po'<.10,"*  ","   ")))
        if (`showols') {
            di as txt %-18s "  `nm'" "|" as res %9.4f `bo' %9.4f `so' %7.2f `to' as txt "`sto'|" ///
               as res %9.4f `bl' %9.4f `sl' %7.2f `tl' as txt "`stl'"
        }
        else {
            di as txt %-18s "  `nm'" "|" as res %10.4f `bl' %10.4f `sl' %7.2f `tl' as txt "`stl'" ///
               as res %11.4f `bl'-`tcrit'*`sl' %11.4f `bl'+`tcrit'*`sl'
        }
    }
    di as txt "{hline 78}"
    local vtxt = cond("`slts'"=="", "Std. errors: oracle OLS on the h retained observations (Theorem 3).", ///
                      "Std. errors: SLTS = oracle variance / varsigma^4 (Berenguer-Rico & Nielsen 2026 ET).")
    di as txt "`vtxt'"
    di as txt "Stars: * p<0.10 ** p<0.05 *** p<0.01 (t distribution, h - K df)."
end

program define _ltsc_mistab
    args MO ML ols
    local showols = ("`ols'"=="")
    di as txt "Mis-specification tests on the retained observations"
    if (`showols') di as txt %-18s " " "|" %10s "stat" %10s "df" %8s "p-val" "  |" %10s "stat" %10s "df" %8s "p-val"
    else di as txt %-18s " " "|" %10s "stat" %10s "df" %8s "p-val"
    local names1 `""F_ar(1-2)" "F_arch(1)" "chi2_normal(2)" "F_hetero" "T_h (cumulant)""'
    local i 0
    foreach nm of local names1 {
        local ++i
        local sL = `ML'[`i',1]
        local d1 = `ML'[`i',2]
        local d2 = `ML'[`i',3]
        local pL = `ML'[`i',4]
        local sO = `MO'[`i',1]
        local pO = `MO'[`i',4]
        local d1O = `MO'[`i',2]
        local d2O = `MO'[`i',3]
        local dfL = cond(`d2'<., "(" + string(`d1') + "," + string(`d2') + ")", "(" + string(`d1') + ")")
        local dfO = cond(`d2O'<., "(" + string(`d1O') + "," + string(`d2O') + ")", "(" + string(`d1O') + ")")
        if (`showols') {
            di as txt %-18s "  `nm'" "|" as res %10.3f `sO' as txt %10s "`dfO'" as res %8.3f `pO' as txt "  |" ///
               as res %10.3f `sL' as txt %10s "`dfL'" as res %8.3f `pL'
        }
        else {
            di as txt %-18s "  `nm'" "|" as res %10.3f `sL' as txt %10s "`dfL'" as res %8.3f `pL'
        }
    }
    di as txt "{hline 78}"
end

program define _ltsc_lrtab
    args KO KL nz ols level kappa0 trend zvars
    local showols = ("`ols'"=="")
    local zc = invnormal(1 - (100-`level')/200)
    di as txt "Long-run relation y_t-1 - kappa'z_t-1 - nu`=cond("`trend'"!="","*t","")' (delta method, N(0,1))"
    if (`showols') {
        di as txt %-18s " " "|" %9s "kappa" %9s "Std.Err." %6s "z" "  |" %9s "kappa" %9s "Std.Err." %6s "z" %8s "p-val"
    }
    else {
        di as txt %-18s " " "|" %10s "kappa" %10s "Std.Err." %7s "z" %10s "p-value" "   [" `level' "% Conf. Int.]"
    }
    forvalues j = 1/`=`nz'+1' {
        if (`j'<=`nz') {
            local nm : word `j' of `zvars'
            local nm "kappa[`nm']"
        }
        else local nm = cond("`trend'"=="", "nu (level)", "nu (trend)")
        local kl = `KL'[`j',1]
        local sl = `KL'[`j',2]
        local zl = `KL'[`j',3]
        local pl = `KL'[`j',4]
        local ko = `KO'[`j',1]
        local so = `KO'[`j',2]
        local zo = `KO'[`j',3]
        if (`showols') {
            di as txt %-18s "  `nm'" "|" as res %9.4f `ko' %9.4f `so' %6.2f `zo' as txt "  |" ///
               as res %9.4f `kl' %9.4f `sl' %6.2f `zl' %8.3f `pl'
        }
        else {
            di as txt %-18s "  `nm'" "|" as res %10.4f `kl' %10.4f `sl' %7.2f `zl' %10.3f `pl' ///
               %11.4f `kl'-`zc'*`sl' %11.4f `kl'+`zc'*`sl'
        }
    }
    if ("`kappa0'"!="") {
        local j 0
        foreach k0 of local kappa0 {
            local ++j
            if (`j'>`nz') continue
            local nm : word `j' of `zvars'
            local tt = (`KL'[`j',1] - `k0') / `KL'[`j',2]
            di as txt "  H0: kappa[`nm'] = " as res `k0' as txt ":  z = " as res %7.3f `tt' ///
               as txt "   p = " as res %6.3f 2*normal(-abs(`tt')) as txt "   (LTS; needs weak exogeneity)"
        }
    }
    di as txt "{hline 78}"
end

program define _ltsc_cointtab
    args LRO LRL pO pL CV tO tL CVTO CVT nz case ols
    local showols = ("`ols'"=="")
    local ctxt = cond("`case'"=="c", "H_c: restricted constant", "H_l: restricted linear trend")
    di as txt "Tests for no cointegration, H0: alpha = 0"
    di as txt "  (`ctxt'; p2 = `nz' weakly exogenous regressor(s))"
    di as txt %-18s "  LR statistic" "|" _c
    if (`showols') di as res %10.3f `LRO' as txt "   p = " as res %6.3f `pO' as txt "     |" _c
    di as res %10.3f `LRL' as txt "   p = " as res %6.3f `pL'
    di as txt %-18s "   crit. values" "|" as txt "  80%: " as res %6.2f `CV'[1,2] as txt "  90%: " as res %6.2f `CV'[1,3] ///
        as txt "  95%: " as res %6.2f `CV'[1,4] as txt "  99%: " as res %6.2f `CV'[1,6]
    di as txt %-18s "  ECM t (t_alpha)" "|" _c
    if (`showols') di as res %10.3f `tO' as txt "                |" _c
    di as res %10.3f `tL'
    if (`showols') {
        di as txt %-18s "   cv OLS (T-K)" "|" as txt " 10%: " as res %6.2f `CVTO'[1,3] as txt "  5%: " as res %6.2f `CVTO'[1,2] ///
           as txt "  1%: " as res %6.2f `CVTO'[1,1]
    }
    di as txt %-18s "   cv LTS (h-K)" "|" as txt " 10%: " as res %6.2f `CVT'[1,3] as txt "  5%: " as res %6.2f `CVT'[1,2] as txt "  1%: " as res %6.2f `CVT'[1,1]
    di as txt "LR: Harbo, Johansen, Nielsen & Rahbek (1998) partial-system test; p-value from"
    di as txt "    Doornik's (1998, 2003) Gamma approximation. ECM t: Ericsson & MacKinnon (2002)"
    di as txt "    response-surface critical values. Reject H0 if LR > cv or t < cv."
    di as txt "{hline 78}"
end

program define _ltsc_wetab
    args WE zvars kappa0
    local nz : word count `zvars'
    local ktxt = cond("`kappa0'"=="", "kappa-hat (LTS)", "kappa0()")
    di as txt "Weak exogeneity: D.z_j on (y - kappa'z)_t-1 [`ktxt'], lagged D's, dummies"
    di as txt %-18s "  equation" "|" %10s "coef" %10s "Std.Err." %7s "t" %10s "p-value"
    forvalues j = 1/`nz' {
        local nm : word `j' of `zvars'
        di as txt %-18s "  D.`nm'" "|" as res %10.4f `WE'[`j',1] %10.4f `WE'[`j',2] %7.2f `WE'[`j',3] %10.3f `WE'[`j',4]
    }
    di as txt "A significant coefficient rejects weak exogeneity of that regressor (Johansen"
    di as txt "1992); the single-equation inference above then requires a systems method."
    di as txt "{hline 78}"
end

* ============================================================================
*  GRAPHS
* ============================================================================
program define _ltsc_dash
    args dy eL eO good touse tvar depvar sigL sigO name
    tempvar fit sr sro
    qui gen double `fit' = `dy' - `eL' if `touse'
    qui gen double `sr'  = `eL' / `sigL' if `touse'
    qui gen double `sro' = `eO' / `sigO' if `touse'
    qui count if `touse' & `good'
    local hh = r(N)
    local cutv = sqrt(2*ln(`hh'))
    local cutf : di %4.2f `cutv'
    * (a) actual and fitted (fitted = x_t' beta_LTS for every t)
    twoway (line `dy' `tvar' if `touse', lcolor(navy) lwidth(medthick))                    ///
           (line `fit' `tvar' if `touse', lcolor(cranberry) lpattern(dash))                ///
           (scatter `dy' `tvar' if `touse' & !`good', mcolor(red) msymbol(Oh) msize(medlarge)), ///
           title("(a) D.`depvar': actual and LTS fit", size(medsmall)) ytitle("") xtitle("") ///
           legend(order(1 "actual" 2 "LTS fit" 3 "outlier") rows(1) size(small) position(6)) ///
           graphregion(color(white)) plotregion(margin(small)) name(`name'_a, replace) nodraw
    * (b) scaled residuals index plot with the outlier bound sqrt(2 log h)
    twoway (dropline `sr' `tvar' if `touse' & `good', lcolor(navy) mcolor(navy) msize(small))  ///
           (dropline `sr' `tvar' if `touse' & !`good', lcolor(red) mcolor(red) msymbol(O) msize(medium)),   ///
           yline(`cutv' -`cutv', lcolor(gs8) lpattern(shortdash)) yline(0, lcolor(gs12))         ///
           title("(b) Scaled LTS residuals; bound {&plusminus}(2 log h){superscript:1/2} = {&plusminus}`cutf'", size(medsmall)) ///
           ytitle("") xtitle("") legend(order(1 "retained" 2 "outlier") rows(1) size(small) position(6)) ///
           graphregion(color(white)) name(`name'_b, replace) nodraw
    * (c) residual correlogram on the retained observations
    tempvar eg
    qui gen double `eg' = `eL' if `touse' & `good'
    local nlag = min(12, floor(`hh'/4))
    tempname AC
    matrix `AC' = J(`nlag', 4, .)
    forvalues L = 1/`nlag' {
        qui corr `eg' L`L'.`eg' if `touse'
        matrix `AC'[`L',1] = `L'
        matrix `AC'[`L',2] = r(rho)
        matrix `AC'[`L',3] = 1.96/sqrt(`hh')
        matrix `AC'[`L',4] = -1.96/sqrt(`hh')
    }
    preserve
    qui clear
    qui svmat double `AC', name(ac)
    twoway (bar ac2 ac1, barwidth(0.5) color(navy)) (line ac3 ac1, lcolor(gs8) lpattern(shortdash)) ///
           (line ac4 ac1, lcolor(gs8) lpattern(shortdash)), ///
           title("(c) Residual correlogram (retained obs), 95% band", size(medsmall)) ytitle("") xtitle("lag") ///
           xlabel(1(1)`nlag') yline(0, lcolor(gs12)) legend(off) graphregion(color(white)) name(`name'_c, replace) nodraw
    restore
    * (d) QQ plot of scaled retained residuals against N(0,1)
    preserve
    tempvar q nq rk
    qui gen double `q' = `sr' if `touse' & `good'
    qui sort `q'
    qui gen double `rk' = _n if `q'<.
    qui gen double `nq' = invnormal((`rk'-0.5)/`hh') if `q'<.
    twoway (scatter `q' `nq' if `q'<., mcolor(navy) msize(small))                          ///
           (function y = x, range(`nq') lcolor(cranberry)),                                 ///
           title("(d) QQ plot of scaled residuals (retained obs)", size(medsmall))           ///
           ytitle("residual quantiles") xtitle("normal quantiles") legend(off)              ///
           graphregion(color(white)) name(`name'_d, replace) nodraw
    restore
    graph combine `name'_a `name'_b `name'_c `name'_d, cols(2) graphregion(color(white)) ///
        title("LTS cointegrated ADL: mis-specification graphics", size(medium)) name(`name', replace)
end

program define _ltsc_hplot
    args PROF n hT hIC name nz
    preserve
    qui clear
    qui svmat double `PROF', name(p)
    qui gen double kappa = -p8/p7
    twoway (connected p3 p1, lcolor(navy) mcolor(navy) msize(small))                                    ///
           (scatter p3 p1 if p1==`hT', mcolor(red) msymbol(D) msize(medlarge)),                          ///
           yscale(log)                                                                                       ///
           ylabel(0.01 0.1 1 10 100 1000, angle(0) format(%9.0g))                                            ///
           title("(a) Cumulant statistic T{subscript:h} (log scale); diamond = argmin", size(medsmall))    ///
           ytitle("") xtitle("h (number of good observations)") legend(off) graphregion(color(white))     ///
           name(`name'_a, replace) nodraw
    twoway (connected p4 p1, lcolor(navy) mcolor(navy) msize(small))                                    ///
           (scatter p4 p1 if p1==`hIC', mcolor(red) msymbol(D) msize(medlarge)),                         ///
           title("(b) Information criterion IC{subscript:h}; diamond = argmin", size(medsmall))           ///
           ytitle("") xtitle("h") legend(off) graphregion(color(white)) name(`name'_b, replace) nodraw
    twoway (connected p7 p1, lcolor(navy) mcolor(navy) msize(small)),                                    ///
           title("(c) Adjustment coefficient alpha-hat(h)", size(medsmall)) ytitle("") xtitle("h")         ///
           yline(0, lcolor(gs12)) legend(off) graphregion(color(white)) name(`name'_c, replace) nodraw
    twoway (connected kappa p1, lcolor(navy) mcolor(navy) msize(small)),                                 ///
           title("(d) Cointegrating coefficient kappa-hat{subscript:1}(h)", size(medsmall)) ytitle("") xtitle("h") ///
           legend(off) graphregion(color(white)) name(`name'_d, replace) nodraw
    graph combine `name'_a `name'_b `name'_c `name'_d, cols(2) graphregion(color(white)) ///
        title("Determining h: LTS profiles over the number of good observations", size(medium)) name(`name', replace)
    restore
end

program define _ltsc_graph
    version 14.0
    syntax [, NAME(string)]
    if ("`e(cmd)'"!="ltscoint") {
        di as err "ltscoint graph requires a previous ltscoint estimation"
        exit 301
    }
    if ("`name'"=="") local name "ltscoint"
    local depvar "`e(depvar)'"
    local zvars  "`e(zvars)'"
    local lags   = e(lags)
    local trend  "`e(trend)'"
    local tvar   "`e(timevar)'"
    tempvar touse good dy tt eL eO
    qui gen byte `touse' = e(sample)
    qui gen byte `good' = 1 if `touse'
    if (e(nout)>0) {
        foreach yr in `e(outyears)' {
            qui replace `good' = 0 if `touse' & `tvar'==`yr'
        }
    }
    local nz : word count `zvars'
    local nx = 2*`nz' + 1 + (`lags'-1)*(1+`nz')
    local xv ""
    forvalues i = 1/`nx' {
        tempvar x`i'
        local xv "`xv' `x`i''"
    }
    _ltsc_build `depvar' `zvars', lags(`lags') `trend' touse(`touse') dy(`dy') tt(`tt') xv(`xv')
    local xvars "`r(xvars)'"
    tempname hold b bo
    matrix `b'  = e(b)
    matrix `bo' = e(b_ols)
    qui gen double `eL' = `dy' if `touse'
    qui gen double `eO' = `dy' if `touse'
    local i 0
    foreach v of local xvars {
        local ++i
        qui replace `eL' = `eL' - `b'[1,`i']*`v'  if `touse'
        qui replace `eO' = `eO' - `bo'[1,`i']*`v' if `touse'
    }
    local K = e(K)
    qui replace `eL' = `eL' - `b'[1,`K']  if `touse'
    qui replace `eO' = `eO' - `bo'[1,`K'] if `touse'
    _ltsc_dash `dy' `eL' `eO' `good' `touse' `tvar' "`depvar'" `=e(sigma)' `=e(sigma_ols)' "`name'"
end

program define _ltsc_dataplot
    version 14.0
    syntax varlist(min=2 numeric ts) [if] [in] [, NAME(string) KAPPA(numlist)]
    capture tsset
    if (_rc) {
        di as err "the data must be {bf:tsset}"
        exit 459
    }
    local tvar "`r(timevar)'"
    marksample touse
    gettoken depvar zvars : varlist
    if ("`name'"=="") local name "ltscoint_data"
    local nz : word count `zvars'
    * EC term: use kappa() if given, else e(kappa) from a previous ltscoint, else unit coefficients
    tempvar ec
    qui gen double `ec' = `depvar' if `touse'
    local src "unit coefficients"
    local j 0
    foreach z of local zvars {
        local ++j
        local kj 1
        if ("`kappa'"!="") {
            local kj : word `j' of `kappa'
            local src "kappa()"
        }
        else if ("`e(cmd)'"=="ltscoint") {
            tempname KP
            matrix `KP' = e(kappa)
            local kj = `KP'[`j',1]
            local src "LTS kappa-hat"
        }
        qui replace `ec' = `ec' - `kj'*`z' if `touse'
    }
    local lv ""
    local dv ""
    local lg ""
    local lgd ""
    local j 0
    local cols navy cranberry dkgreen orange purple gs6
    foreach v in `depvar' `zvars' {
        local ++j
        local cc : word `j' of `cols'
        local lv "`lv' (line `v' `tvar' if `touse', lcolor(`cc'))"
        local dv "`dv' (line D.`v' `tvar' if `touse', lcolor(`cc'))"
        local lg `"`lg' `j' "`v'""'
        local lgd `"`lgd' `j' "D.`v'""'
    }
    twoway `lv', title("(a) Levels", size(medsmall)) ytitle("") xtitle("") legend(order(`lg') rows(1) size(small) position(6)) ///
        graphregion(color(white)) name(`name'_a, replace) nodraw
    twoway `dv', title("(b) First differences", size(medsmall)) ytitle("") xtitle("") legend(order(`lgd') rows(1) size(small) position(6)) ///
        yline(0, lcolor(gs12)) graphregion(color(white)) name(`name'_b, replace) nodraw
    twoway (line `ec' `tvar' if `touse', lcolor(navy)), title("(c) Candidate cointegrating relation (`src')", size(medsmall)) ///
        ytitle("") xtitle("") legend(off) graphregion(color(white)) name(`name'_c, replace) nodraw
    graph combine `name'_a `name'_b `name'_c, cols(1) graphregion(color(white)) ysize(7) xsize(5) name(`name', replace)
end

* ============================================================================
*  MATA
* ============================================================================
version 14.0
mata:

// ---------- OLS on a subset; returns coefficient column, rc==1 if singular ----------
real colvector _ltsc_ols(real colvector y, real matrix X, real colvector sel, real scalar rc)
{
    real matrix Xs, XX, XXi
    real colvector ys, b
    Xs = select(X, sel)
    ys = select(y, sel)
    XX = cross(Xs, Xs)
    XXi = invsym(XX)
    rc = 0
    if (any(diagonal(XXi) :== 0)) {
        rc = 1
        b = J(cols(X), 1, 0)
        return(b)
    }
    b = XXi * cross(Xs, ys)
    return(b)
}

// ---------- indicator of the h smallest squared residuals ----------
real colvector _ltsc_hsub(real colvector r2, real scalar h)
{
    real colvector o, g
    o = order(r2, 1)
    g = J(rows(r2), 1, 0)
    g[o[1..h]] = J(h, 1, 1)
    return(g)
}

// ---------- C-steps from a starting subset until convergence ----------
real scalar _ltsc_csteps(real colvector y, real matrix X, real colvector g, real scalar h,
                         real scalar maxit, real colvector b)
{
    real scalar it, rc, rss
    real colvector r2, gnew, bb
    it = 0
    rss = .
    bb = b
    while (it < maxit) {
        it = it + 1
        bb = _ltsc_ols(y, X, g, rc)
        if (rc) {
            return(.)
        }
        r2 = (y - X*bb):^2
        gnew = _ltsc_hsub(r2, h)
        rss = sum(select(r2, gnew))
        if (all(gnew :== g)) {
            g = gnew
            b = bb
            return(rss)
        }
        g = gnew
    }
    b = bb
    return(rss)
}

// ---------- FAST-LTS (Rousseeuw & Van Driessen 2006) ----------
void _ltsc_fastlts(real colvector y, real matrix X, real scalar h, real scalar nsamp,
                   real scalar csteps, real scalar nkeep, real scalar seed,
                   real colvector gbest, real colvector bbest, real scalar rssbest, real scalar nsing)
{
    real scalar n, k, s, rc, rss, i, j, worst, iw
    real colvector perm, sel, b, r2, g
    real matrix G, B
    real rowvector R
    n = rows(y)
    k = cols(X)
    if (seed >= 0) rseed(seed)
    nsing = 0
    // candidate store
    G = J(n, nkeep, 0)
    B = J(k, nkeep, 0)
    R = J(1, nkeep, .)
    // full-sample start is always included (h = n gives OLS; otherwise a sensible start)
    g = J(n, 1, 1)
    b = _ltsc_ols(y, X, g, rc)
    r2 = (y - X*b):^2
    g = _ltsc_hsub(r2, h)
    b = J(k, 1, 0)
    rss = _ltsc_csteps(y, X, g, h, csteps, b)
    R[1] = rss
    G[., 1] = g
    B[., 1] = b
    for (s = 1; s <= nsamp; s = s + 1) {
        perm = jumble((1::n))
        sel = J(n, 1, 0)
        sel[perm[1..k]] = J(k, 1, 1)
        b = _ltsc_ols(y, X, sel, rc)
        if (rc) {
            // singular elemental set: add observations until non-singular (RvD 2006)
            iw = k
            while (rc & iw < n) {
                iw = iw + 1
                sel[perm[iw]] = 1
                b = _ltsc_ols(y, X, sel, rc)
            }
            if (rc) {
                nsing = nsing + 1
                continue
            }
        }
        r2 = (y - X*b):^2
        g = _ltsc_hsub(r2, h)
        rss = _ltsc_csteps(y, X, g, h, csteps, b)
        if (rss >= .) {
            nsing = nsing + 1
            continue
        }
        // keep the nkeep best (distinct) candidates
        worst = 1
        for (j = 2; j <= nkeep; j = j + 1) {
            if (R[j] >= . ) {
                worst = j
                break
            }
            if (R[j] > R[worst]) worst = j
        }
        if (R[worst] >= . | rss < R[worst]) {
            R[worst] = rss
            G[., worst] = g
            B[., worst] = b
        }
    }
    // iterate the kept candidates to convergence
    rssbest = .
    for (j = 1; j <= nkeep; j = j + 1) {
        if (R[j] >= .) continue
        g = G[., j]
        b = B[., j]
        rss = _ltsc_csteps(y, X, g, h, 200, b)
        if (rss < .) {
            if (rssbest >= . | rss < rssbest) {
                rssbest = rss
                gbest = g
                bbest = b
            }
        }
    }
}

// ---------- exact enumeration of all h-subsets (small T only) ----------
void _ltsc_exact(real colvector y, real matrix X, real scalar h,
                 real colvector gbest, real colvector bbest, real scalar rssbest)
{
    real scalar n, k, m, i, j, rc, rss, ncomb, done
    real colvector c, g, b, r2
    n = rows(y)
    k = cols(X)
    m = n - h                    // enumerate the outlier sets (smaller when h > n/2)
    ncomb = comb(n, m)
    if (ncomb > 3000000) {
        _error(3000, "exact enumeration: " + strofreal(ncomb) + " subsets is too many; use FAST-LTS")
    }
    rssbest = .
    if (m == 0) {
        g = J(n, 1, 1)
        b = _ltsc_ols(y, X, g, rc)
        r2 = (y - X*b):^2
        rssbest = sum(r2)
        gbest = g
        bbest = b
        return
    }
    c = (1::m)
    done = 0
    while (!done) {
        g = J(n, 1, 1)
        g[c] = J(m, 1, 0)
        b = _ltsc_ols(y, X, g, rc)
        if (!rc) {
            r2 = (y - X*b):^2
            rss = sum(select(r2, g))
            if (rssbest >= . | rss < rssbest) {
                rssbest = rss
                gbest = g
                bbest = b
            }
        }
        // next combination in lexicographic order
        i = m
        while (i >= 1) {
            if (c[i] < n - m + i) break
            i = i - 1
        }
        if (i < 1) {
            done = 1
        }
        else {
            c[i] = c[i] + 1
            for (j = i + 1; j <= m; j = j + 1) {
                c[j] = c[j-1] + 1
            }
        }
    }
}

// ---------- driver for a single h ----------
void _ltsc_run(string scalar yv, string scalar xv, string scalar tv, real scalar h,
               real scalar nsamp, real scalar csteps, real scalar nkeep, real scalar seed,
               real scalar exact, string scalar goodv)
{
    real colvector y, g, b
    real matrix X
    real scalar rss, nsing
    y = st_data(., yv, tv)
    X = st_data(., tokens(xv), tv)
    X = X, J(rows(X), 1, 1)
    nsing = 0
    if (exact) {
        _ltsc_exact(y, X, h, g, b, rss)
    }
    else {
        _ltsc_fastlts(y, X, h, nsamp, csteps, nkeep, seed, g, b, rss, nsing)
    }
    st_store(., goodv, tv, g)
    st_numscalar("r(rss)", rss)
    st_numscalar("r(nsing)", nsing)
}

// ---------- profile over h: T_h, IC_h, sigma_h, alpha_h, psi_1 ----------
void _ltsc_profile(string scalar yv, string scalar xv, string scalar tv, real scalar hmin,
                   real scalar hmax, real scalar nsamp, real scalar csteps, real scalar nkeep,
                   real scalar seed, real scalar exact, real scalar nz, string scalar profm, string scalar goodm)
{
    real colvector y, g, b, e, eg
    real matrix X, P, G
    real scalar n, k, h, i, rss, nsing, m2, m3, m4, k3, k4, Th, ICh, nh
    y = st_data(., yv, tv)
    X = st_data(., tokens(xv), tv)
    X = X, J(rows(X), 1, 1)
    n = rows(y)
    k = cols(X)
    nh = hmax - hmin + 1
    P = J(nh, 8, .)
    G = J(n, nh, 0)
    for (i = 1; i <= nh; i = i + 1) {
        h = hmin + i - 1
        if (exact) {
            _ltsc_exact(y, X, h, g, b, rss)
        }
        else {
            _ltsc_fastlts(y, X, h, nsamp, csteps, nkeep, seed, g, b, rss, nsing)
        }
        e = y - X*b
        eg = select(e, g)
        m2 = mean(eg:^2)
        m3 = mean(eg:^3)
        m4 = mean(eg:^4)
        k3 = m3 / (m2^1.5)
        k4 = m4 / (m2^2) - 3
        Th = h * (k3*k3/6 + k4*k4/24)
        ICh = ln(rss/h) + 2*ln(ln(n)) * (n - h)/n
        P[i, 1] = h
        P[i, 2] = n - h
        P[i, 3] = Th
        P[i, 4] = ICh
        P[i, 5] = rss
        P[i, 6] = sqrt(rss/(h - k))
        // X is in paper order: dz(1..nz), L.y, L.z(1..nz), ... so alpha = b[nz+1], psi_1 = b[nz+2]
        P[i, 7] = b[nz + 1]
        P[i, 8] = b[nz + 2]
        G[., i] = g
    }
    st_matrix(profm, P)
    st_matrix(goodm, G)
}

real scalar _ltsc_argmin(real matrix P, real scalar col)
{
    real scalar i, best, ib
    best = .
    ib = 1
    for (i = 1; i <= rows(P); i = i + 1) {
        if (P[i, col] < .) {
            if (best >= . | P[i, col] < best) {
                best = P[i, col]
                ib = i
            }
        }
    }
    return(P[ib, 1])
}

string scalar _ltsc_outlist(real colvector g, string scalar tv, string scalar touse, string scalar fmt)
{
    real colvector t
    string scalar s
    real scalar i
    t = st_data(., tv, touse)
    s = ""
    for (i = 1; i <= rows(t); i = i + 1) {
        if (g[i] == 0) {
            if (s != "") s = s + " "
            s = s + strtrim(sprintf(fmt, t[i]))
        }
    }
    return(s)
}

// ---------- Doornik (2003) gamma tables: partial system, p1-r = 1, p2 = 1..6 ----------
// columns: q50 q80 q90 q95 q97.5 q99 mean var     (Tables 12 = H_c, 13 = H_l)
void _ltsc_lrcv(real scalar p2, string scalar cs, real scalar LRL, real scalar LRO, string scalar cvm)
{
    real matrix Tc, Tl, T
    real scalar a, bsc, m, v, pL, pO
    Tc = ( 5.45,  8.50, 10.46, 12.28, 14.01, 16.21,  6.04, 10.89 \
           7.40, 10.96, 13.20, 15.25, 17.19, 19.63,  8.01, 14.98 \
           9.39, 13.38, 15.84, 18.08, 20.18, 22.81, 10.01, 18.99 \
          11.38, 15.75, 18.42, 20.83, 23.08, 25.88, 12.01, 23.01 \
          13.37, 18.10, 20.95, 23.52, 25.89, 28.85, 14.01, 27.05 \
          15.37, 20.42, 23.44, 26.15, 28.65, 31.74, 16.01, 31.10 )
    Tl = ( 7.69, 11.18, 13.35, 15.33, 17.19, 19.53,  8.27, 14.40 \
           9.62, 13.55, 15.96, 18.16, 20.20, 22.76, 10.22, 18.47 \
          11.56, 15.89, 18.52, 20.89, 23.10, 25.84, 12.17, 22.55 \
          13.53, 18.22, 21.05, 23.59, 25.94, 28.86, 14.15, 26.74 \
          15.50, 20.54, 23.55, 26.24, 28.73, 31.81, 16.13, 30.98 \
          17.48, 22.84, 26.03, 28.86, 31.48, 34.71, 18.12, 35.26 )
    if (cs == "c") T = Tc
    else T = Tl
    if (p2 < 1 | p2 > 6) {
        st_matrix(cvm, J(1, 6, .))
        st_numscalar("r(p_L)", .)
        st_numscalar("r(p_O)", .)
        st_numscalar("r(mean)", .)
        st_numscalar("r(var)", .)
        return
    }
    st_matrix(cvm, T[p2, 1..6])
    m = T[p2, 7]
    v = T[p2, 8]
    a = m*m / v
    bsc = v / m
    pL = 1 - gammap(a, LRL / bsc)
    pO = 1 - gammap(a, LRO / bsc)
    st_numscalar("r(p_L)", pL)
    st_numscalar("r(p_O)", pO)
    st_numscalar("r(mean)", m)
    st_numscalar("r(var)", v)
}

// ---------- Ericsson & MacKinnon (2002) response surfaces, Tables 3 (constant) and 4 (constant+trend) ----------
// rows k = 1..12; for each k three rows (1%, 5%, 10%): theta_inf theta1 theta2 theta3
void _ltsc_ecmcv(real scalar k, string scalar cs, real scalar Ta, string scalar cvm)
{
    real matrix Tc, Tl, T
    real rowvector cv
    real scalar r, i
    Tc = (-3.4307, -6.52,  -4.7,  -10 \ -2.8617, -2.81,  -3.2,   37 \ -2.5668, -1.56,   2.1,  -29 \
          -3.7948, -7.87,  -3.6,  -28 \ -3.2145, -3.21,  -2.0,   17 \ -2.9083, -1.55,   1.9,  -25 \
          -4.0947, -8.59,  -2.0,  -65 \ -3.5057, -3.27,   1.1,  -34 \ -3.1924, -1.23,   2.1,  -39 \
          -4.3555, -8.90,  -6.7,  -31 \ -3.7592, -2.92,  -3.7,    5 \ -3.4412, -0.53,  -4.5,    4 \
          -4.5859, -9.14,  -2.5,  -78 \ -3.9856, -2.50,  -1.7,  -35 \ -3.6635,  0.21,  -6.0,   -8 \
          -4.7970, -9.04,  -5.6,  -66 \ -4.1922, -1.73,  -7.8,   -9 \ -3.8670,  1.26, -12.7,   14 \
          -4.9912, -8.85,  -5.1,  -72 \ -4.3831, -0.90, -12.2,    1 \ -4.0556,  2.39, -18.8,   27 \
          -5.1723, -8.58,  -2.0, -113 \ -4.5608,  0.02, -15.4,   -2 \ -4.2310,  3.59, -25.6,   44 \
          -5.3437, -7.86,  -7.8, -101 \ -4.7287,  1.25, -26.0,   42 \ -4.3975,  5.11, -39.2,  104 \
          -5.5048, -7.19,  -9.8, -102 \ -4.8876,  2.46, -31.7,   43 \ -4.5543,  6.53, -47.2,  116 \
          -5.6588, -6.39, -13.7, -105 \ -5.0394,  3.88, -45.7,  117 \ -4.7055,  8.31, -66.5,  222 \
          -5.8068, -5.13, -29.2,  -15 \ -5.1836,  5.33, -55.9,  134 \ -4.8480,  9.94, -78.0,  240 )
    Tl = (-3.9593, -8.99,  -4.9,   39 \ -3.4108, -4.38,   4.5,  -21 \ -3.1272, -2.57,   3.5,   -7 \
          -4.2488,-10.04,  -4.1,   -1 \ -3.6873, -4.56,   2.2,    1 \ -3.3927, -2.41,   3.4,  -14 \
          -4.4981,-10.69,   0.6,  -58 \ -3.9263, -4.47,   5.2,  -38 \ -3.6249, -1.86,   1.1,  -10 \
          -4.7214,-10.94,   1.6,  -77 \ -4.1421, -3.99,   2.8,  -35 \ -3.8342, -1.16,   0.4,  -23 \
          -4.9255,-10.86,   1.2,  -94 \ -4.3392, -3.37,   1.6,  -47 \ -4.0271, -0.17,  -4.4,  -14 \
          -5.1137,-10.72,   1.4,  -96 \ -4.5227, -2.52,  -2.8,  -32 \ -4.2067,  0.94,  -9.9,    0 \
          -5.2923,-10.11,  -4.0,  -75 \ -4.6952, -1.43, -10.6,   -5 \ -4.3751,  2.18, -16.9,   18 \
          -5.4565, -9.77,  -1.5, -106 \ -4.8569, -0.43, -14.4,   -3 \ -4.5344,  3.52, -24.9,   40 \
          -5.6149, -9.11,  -2.0, -126 \ -5.0108,  0.78, -21.2,   12 \ -4.6864,  5.08, -37.2,   88 \
          -5.7657, -8.28,  -5.3, -121 \ -5.1582,  2.12, -28.6,   26 \ -4.8311,  6.62, -46.2,  103 \
          -5.9099, -7.41,  -6.2, -160 \ -5.2992,  3.57, -40.0,   69 \ -4.9707,  8.41, -64.7,  199 \
          -6.0478, -6.17, -20.6,  -74 \ -5.4346,  5.22, -54.5,  121 \ -5.1046, 10.20, -78.3,  231 )
    if (cs == "c") T = Tc
    else T = Tl
    cv = J(1, 3, .)
    if (k >= 1 & k <= 12 & Ta > 0) {
        for (i = 1; i <= 3; i = i + 1) {
            r = 3*(k - 1) + i
            cv[i] = T[r, 1] + T[r, 2]/Ta + T[r, 3]/(Ta*Ta) + T[r, 4]/(Ta*Ta*Ta)
        }
    }
    st_matrix(cvm, cv)
}
end
