*! qardl v1.2.0 - Quantile Autoregressive Distributed Lag Model
*! Based on Cho, Kim & Shin (2015), Journal of Econometrics
*! Aligned with the GAUSS QARDL 3.1.1 library
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Date: August 2026

program define qardl, eclass sortpreserve
    version 14.0

    * The shared Wald Mata routines live in _qardl_waldtest.ado so that
    * postestimation commands can use them without qardl.ado having been
    * loaded first.  Pull them in if they are not already compiled.
    capture mata which _qardl_wald_stat()
    if _rc {
        capture program drop _qardl_waldtest
        qui findfile _qardl_waldtest.ado
        qui run "`r(fn)'"
    }

    syntax varlist(min=2 numeric ts) [if] [in], TAU(numlist >0 <1 sort) ///
        [P(integer 0) Q(integer -1) QVEC(numlist integer >=0) ///
         PMAX(integer 8) QMAX(integer 8) ///
         PMIN(integer 1) QMIN(integer 0) CRITerion(string) ///
         GETSPval(real 0.1) COVariance(string) HAClags(integer 0) ///
         ECM ECMType(string) SYMmetry ///
         ROLLing(integer 0) SIMulate(numlist) ///
         WALDtest(string) GRAPH NOCONStant LEVel(cilevel) ///
         WINdow(integer 0) NOTABle]

    * Mark sample
    marksample touse

    * Preserve touse for later use (ereturn post consumes it)
    tempvar touse2
    qui gen byte `touse2' = `touse'

    * Parse variables
    gettoken depvar indepvars : varlist
    local k : word count `indepvars'

    if `k' < 1 {
        di as error "at least one independent variable required"
        exit 198
    }

    * ------------------------------------------------------------
    * Option validation
    * ------------------------------------------------------------
    if "`criterion'" == "" local criterion "bic"
    local criterion = lower("`criterion'")
    if !inlist("`criterion'", "aic", "bic", "hq", "hqc", "gets") {
        di as error "criterion() must be aic, bic, hq, hqc, or gets"
        exit 198
    }
    if `getspval' <= 0 | `getspval' >= 1 {
        di as error "getspval() must be strictly between 0 and 1"
        exit 198
    }

    * Per-regressor distributed-lag orders
    local usex = 0
    if "`qvec'" != "" {
        local nq : word count `qvec'
        if `nq' != `k' {
            di as error "qvec() must have `k' elements, one per regressor; got `nq'"
            exit 198
        }
        if `q' >= 0 {
            di as error "specify either q() or qvec(), not both"
            exit 198
        }
        * a constant qvec is just a scalar q
        local qfirst : word 1 of `qvec'
        local allsame = 1
        foreach z of local qvec {
            if `z' != `qfirst' local allsame = 0
        }
        if `allsame' {
            local q = `qfirst'
            di as txt "  Note: qvec() is constant; using the scalar path with q = `q'."
        }
        else {
            local usex = 1
        }
    }

    * Heterogeneous lag orders are a levels-form estimator only: the ECM,
    * rolling and Monte Carlo paths are all written for a scalar q.
    if `usex' {
        if "`ecm'" != "" | "`ecmtype'" != "" {
            di as error "qvec() cannot be combined with ecm; the ECM parameterisations require a scalar q()"
            exit 198
        }
        if `rolling' > 0 | `window' > 0 {
            di as error "qvec() cannot be combined with rolling()"
            exit 198
        }
        if "`simulate'" != "" {
            di as error "qvec() cannot be combined with simulate()"
            exit 198
        }
    }

    if "`covariance'" == "" local covariance "iid"
    local covariance = lower("`covariance'")
    if !inlist("`covariance'", "iid", "robust", "hac") {
        di as error "covariance() must be iid, robust, or hac"
        exit 198
    }

    if `haclags' < 0 {
        di as error "haclags() must be non-negative"
        exit 198
    }
    if `haclags' > 0 & "`covariance'" != "hac" {
        di as error "haclags() requires covariance(hac)"
        exit 198
    }

    if "`ecmtype'" == "" local ecmtype "cho"
    local ecmtype = lower("`ecmtype'")
    if !inlist("`ecmtype'", "cho", "twostep", "both") {
        di as error "ecmtype() must be cho, twostep, or both"
        exit 198
    }
    if "`ecmtype'" != "cho" & "`ecm'" == "" local ecm "ecm"

    * Count observations
    qui count if `touse'
    local nobs = r(N)

    if `nobs' < 20 {
        di as error "insufficient observations (need at least 20)"
        exit 2001
    }

    * Parse tau values
    local ntau : word count `tau'
    tempname tau_vec
    mata: st_matrix("`tau_vec'", strtoreal(tokens(st_local("tau")))')

    * ------------------------------------------------------------
    * Lag order selection
    *   p <= 0  requests automatic selection of p
    *   q <  0  requests automatic selection of q
    *   q == 0  is a valid fixed order (no distributed-lag terms)
    * ------------------------------------------------------------
    local pauto = (`p' <= 0)
    local qauto = (`q' < 0 & `usex' == 0)

    if `usex' & `pauto' {
        di as error "qvec() requires an explicit p()"
        exit 198
    }

    if `pauto' | `qauto' {
        local plo = cond(`pauto', `pmin', `p')
        local phi = cond(`pauto', `pmax', `p')
        local qlo = cond(`qauto', `qmin', `q')
        local qhi = cond(`qauto', `qmax', `q')

        local critup = upper("`criterion'")

        di as txt _n "{hline 70}"
        di as txt "  QARDL Lag Order Selection (`critup')"
        di as txt "{hline 70}"

        _qardl_icmean `varlist' if `touse', pmin(`plo') pmax(`phi') ///
            qmin(`qlo') qmax(`qhi') criterion(`criterion') getspval(`getspval')

        local p = r(p_opt)
        local q = r(q_opt)
        tempname ic_grid
        mat `ic_grid' = r(ic_grid)

        if "`criterion'" == "gets" {
            di as txt _n "  General-to-specific search, p-value threshold " ///
                as res %5.3f `getspval'
            di as txt "  Starting from p = `phi', q = `qhi'; boundary lags are"
            di as txt "  dropped until the highest retained lag is significant."
            di as res "  Retained: p = `p', q = `q'"
            di as txt "{hline 70}"
        }
        else {
            _qardl_display_icgrid `ic_grid' `plo' `phi' `qlo' `qhi' `p' `q' "`critup'"
        }
    }

    * Validate lag orders
    if `p' < 1 {
        di as error "p must be at least 1"
        exit 198
    }
    if `usex' == 0 & `q' < 0 {
        di as error "q must be non-negative"
        exit 198
    }

    if `usex' {
        local qmaxv = 0
        foreach z of local qvec {
            if `z' > `qmaxv' local qmaxv = `z'
        }
        local maxpq = max(`p', `qmaxv')
    }
    else {
        local maxpq = max(`p', `q')
    }
    if `nobs' <= `maxpq' + `k' + 5 {
        di as error "insufficient observations for specified lag orders"
        exit 2001
    }

    * ============================================================
    * Core QARDL Estimation
    * ============================================================
    * Label for the order in printed headers
    if `usex' {
        local qlab : subinstr local qvec " " ",", all
        local qlab "[`qlab']"
    }
    else {
        local qlab "`q'"
    }

    if `usex' {
        if "`covariance'" == "iid" {
            di as txt "  Note: the Cho-Kim-Shin iid covariance is not defined for"
            di as txt "  per-regressor lag orders; switching to covariance(robust)."
            local covariance "robust"
        }
        _qardl_estimatex `varlist' if `touse', p(`p') qvec(`qvec') ///
            tau(`tau') covariance(`covariance') haclags(`haclags') `noconstant'
    }
    else {
        _qardl_estimate `varlist' if `touse', p(`p') q(`q') ///
            tau(`tau') covariance(`covariance') haclags(`haclags') `noconstant'
    }

    tempname beta beta_cov phi phi_cov gamma gamma_cov alpha rho
    mat `beta' = r(beta)
    mat `beta_cov' = r(beta_cov)
    mat `phi' = r(phi)
    mat `phi_cov' = r(phi_cov)
    mat `gamma' = r(gamma)
    mat `gamma_cov' = r(gamma_cov)
    mat `alpha' = r(alpha)
    mat `rho' = r(rho)

    tempname bt_raw fh_vec
    mat `bt_raw' = r(bt_raw)
    mat `fh_vec' = r(fh_vec)

    local scale_beta = r(scale_beta)
    local scale_short = r(scale_short)
    local haclags_used = r(haclags_used)
    local nobs_eff = r(N_eff)

    * ------------------------------------------------------------
    * QARDL-ECM (Cho 2022 phi*/theta parameterisation)
    * ------------------------------------------------------------
    if "`ecm'" != "" & inlist("`ecmtype'", "cho", "both") {
        if `q' < 1 {
            di as error "ecmtype(cho) requires q >= 1"
            exit 198
        }
        _qardl_ecm `varlist' if `touse', p(`p') q(`q') ///
            tau(`tau') `noconstant'

        tempname phi_ecm phi_ecm_cov theta theta_cov
        mat `phi_ecm' = r(phi_ecm)
        mat `phi_ecm_cov' = r(phi_ecm_cov)
        mat `theta' = r(theta)
        mat `theta_cov' = r(theta_cov)
    }

    * ------------------------------------------------------------
    * QARDL-ECM (GAUSS 3.1.1 two-step parameterisation)
    * ------------------------------------------------------------
    if "`ecm'" != "" & inlist("`ecmtype'", "twostep", "both") {
        _qardl_ecm2 `varlist' if `touse', p(`p') q(`q') ///
            tau(`tau') covariance(`covariance') haclags(`haclags')

        tempname e2_beta_lr e2_alpha e2_alpha_cov e2_rho e2_rho_cov
        mat `e2_beta_lr' = r(beta_lr)
        mat `e2_alpha' = r(alpha)
        mat `e2_alpha_cov' = r(alpha_cov)
        mat `e2_rho' = r(rho)
        mat `e2_rho_cov' = r(rho_cov)
        local e2_rho_ols = r(rho_ols)
        local e2_nobs = r(N_ecm)
    }

    * ------------------------------------------------------------
    * Display
    * ------------------------------------------------------------
    if "`notable'" == "" {
        _qardl_display_results `beta' `beta_cov' `phi' `phi_cov' ///
            `gamma' `gamma_cov' `tau_vec' `p' "`qlab'" `k' `nobs' ///
            "`depvar'" "`indepvars'" `= cond("`ecm'"!="", 1, 0)' ///
            `scale_beta' `scale_short' "`covariance'" `haclags_used'

        if "`ecm'" != "" & inlist("`ecmtype'", "cho", "both") {
            _qardl_display_ecm `phi_ecm' `phi_ecm_cov' `theta' ///
                `theta_cov' `tau_vec' `p' `q' `k' `nobs' "`indepvars'"
        }

        if "`ecm'" != "" & inlist("`ecmtype'", "twostep", "both") {
            _qardl_display_ecm2 `e2_beta_lr' `e2_alpha' `e2_alpha_cov' ///
                `e2_rho' `e2_rho_cov' `tau_vec' `e2_rho_ols' `e2_nobs' ///
                "`indepvars'"
        }
    }

    * ------------------------------------------------------------
    * Wald tests
    * ------------------------------------------------------------
    _qardl_default_wald `beta' `beta_cov' `phi' `phi_cov' ///
        `gamma' `gamma_cov' `tau_vec' `p' `q' `k' `nobs' "`indepvars'" ///
        `scale_beta' `scale_short'

    if "`symmetry'" != "" {
        _qardl_symmetry_wald `beta' `beta_cov' `phi' `phi_cov' ///
            `gamma' `gamma_cov' `tau_vec' `p' `k' `scale_beta' `scale_short'
    }

    if "`ecm'" != "" & inlist("`ecmtype'", "cho", "both") {
        _qardl_default_ecm_wald `phi_ecm' `phi_ecm_cov' `theta' ///
            `theta_cov' `tau_vec' `p' `q' `k' `nobs'
    }

    * User-specified Wald restrictions
    if "`waldtest'" != "" {
        _qardl_run_waldtest "`waldtest'" `beta' `beta_cov' `phi' `phi_cov' ///
            `gamma' `gamma_cov' `tau_vec' `p' `q' `k' `scale_beta' `scale_short'
    }

    * ------------------------------------------------------------
    * Store results
    * ------------------------------------------------------------
    ereturn clear
    ereturn post, esample(`touse') obs(`nobs')
    ereturn matrix beta = `beta'
    ereturn matrix beta_cov = `beta_cov'
    ereturn matrix phi = `phi'
    ereturn matrix phi_cov = `phi_cov'
    ereturn matrix gamma = `gamma'
    ereturn matrix gamma_cov = `gamma_cov'
    ereturn matrix alpha = `alpha'
    ereturn matrix rho = `rho'
    ereturn matrix tau = `tau_vec'
    ereturn matrix bt_raw = `bt_raw'
    ereturn matrix fh = `fh_vec'
    ereturn scalar p = `p'
    ereturn scalar q = cond(`usex', ., `q')
    ereturn scalar k = `k'
    if `usex' {
        tempname qvecmat
        mata: st_matrix("`qvecmat'", strtoreal(tokens(st_local("qvec")))')
        ereturn matrix qvec = `qvecmat'
    }
    ereturn scalar ntau = `ntau'
    ereturn scalar N_eff = `nobs_eff'
    ereturn scalar scale_beta = `scale_beta'
    ereturn scalar scale_short = `scale_short'
    ereturn scalar haclags = `haclags_used'
    ereturn local covariance "`covariance'"
    ereturn local criterion "`criterion'"
    ereturn local depvar "`depvar'"
    ereturn local indepvars "`indepvars'"
    ereturn local cmd "qardl"
    ereturn local predict "qardl_p"
    ereturn local author "Dr Merwan Roudane"
    ereturn local email "merwanroudane920@gmail.com"

    if "`ecm'" == "" {
        ereturn local model "qardl"
        ereturn local title "QARDL Estimation"
    }
    else {
        ereturn local model "qardl-ecm"
        ereturn local title "QARDL-ECM Estimation"
        ereturn local ecmtype "`ecmtype'"

        if inlist("`ecmtype'", "cho", "both") {
            ereturn matrix phi_ecm = `phi_ecm'
            ereturn matrix phi_ecm_cov = `phi_ecm_cov'
            ereturn matrix theta = `theta'
            ereturn matrix theta_cov = `theta_cov'
        }
        if inlist("`ecmtype'", "twostep", "both") {
            ereturn matrix beta_lr = `e2_beta_lr'
            ereturn matrix ecm_alpha = `e2_alpha'
            ereturn matrix ecm_alpha_cov = `e2_alpha_cov'
            ereturn matrix ecm_rho = `e2_rho'
            ereturn matrix ecm_rho_cov = `e2_rho_cov'
            ereturn scalar rho_ols = `e2_rho_ols'
            ereturn scalar N_ecm = `e2_nobs'
        }
    }

    * ============================================================
    * Rolling QARDL
    * ============================================================
    if `rolling' > 0 | `window' > 0 {
        local rwin = max(`rolling', `window')
        if `rwin' == 0 {
            local rwin = max(int(`nobs' * 0.1), `maxpq' + `k' + 10)
        }

        di as txt _n "{hline 70}"
        di as txt "  Rolling QARDL Estimation (window = `rwin')"
        di as txt "{hline 70}"

        _qardl_rolling `varlist' if `touse2', p(`p') q(`q') ///
            tau(`tau') window(`rwin') covariance(`covariance') ///
            haclags(`haclags') `noconstant' ///
            `= cond("`ecm'" != "" & inlist("`ecmtype'","twostep","both"), "ecm", "")'

        * Store rolling results
        tempname rbeta rgamma rphi rbeta_se rgamma_se rphi_se
        tempname rwald_beta rwald_phi rwald_gamma
        mat `rbeta' = r(rolling_beta)
        mat `rgamma' = r(rolling_gamma)
        mat `rphi' = r(rolling_phi)
        mat `rbeta_se' = r(rolling_beta_se)
        mat `rgamma_se' = r(rolling_gamma_se)
        mat `rphi_se' = r(rolling_phi_se)
        mat `rwald_beta' = r(rolling_wald_beta)
        mat `rwald_phi' = r(rolling_wald_phi)
        mat `rwald_gamma' = r(rolling_wald_gamma)

        tempname ralpha rrho
        local rollecm = 0
        if "`ecm'" != "" & inlist("`ecmtype'", "twostep", "both") {
            mat `ralpha' = r(rolling_alpha)
            mat `rrho' = r(rolling_rho)
            local rollecm = 1
        }

        ereturn matrix rolling_beta = `rbeta'
        ereturn matrix rolling_gamma = `rgamma'
        ereturn matrix rolling_phi = `rphi'
        ereturn matrix rolling_beta_se = `rbeta_se'
        ereturn matrix rolling_gamma_se = `rgamma_se'
        ereturn matrix rolling_phi_se = `rphi_se'
        ereturn matrix rolling_wald_beta = `rwald_beta'
        ereturn matrix rolling_wald_phi = `rwald_phi'
        ereturn matrix rolling_wald_gamma = `rwald_gamma'
        if `rollecm' {
            ereturn matrix rolling_ecm_alpha = `ralpha'
            ereturn matrix rolling_ecm_rho = `rrho'
        }
        ereturn scalar rolling_window = `rwin'
    }

    * ============================================================
    * Monte Carlo Simulation
    * ============================================================
    if "`simulate'" != "" {
        local simreps : word 1 of `simulate'
        local simnn : word 2 of `simulate'
        if "`simnn'" == "" local simnn = `nobs'

        * The Monte Carlo evaluates the Cho-Kim-Shin Wald tests, whose
        * (n-1) and (n-1)^2 scalings are only defined on the iid path.
        if `q' < 1 {
            di as error "simulate() requires q >= 1 (the Cho-Kim-Shin Wald scalings are not defined for q = 0)"
            exit 198
        }

        di as txt _n "{hline 70}"
        di as txt "  Monte Carlo Simulation (reps = `simreps', n = `simnn')"
        di as txt "{hline 70}"

        _qardl_simulate, reps(`simreps') nobs(`simnn') p(`p') q(`q') ///
            tau(`tau') k(`k')

        * Store simulation results
        tempname sim_res
        mat `sim_res' = r(sim_results)
        ereturn matrix sim_results = `sim_res'
    }

    * ============================================================
    * Graphs
    * ============================================================
    if "`graph'" != "" {
        qardl_graph, tau(`tau') p(`p') q(`q') k(`k') ///
            depvar("`depvar'") indepvars("`indepvars'") ///
            `= cond("`ecm'"!="", "ecm", "")'
    }

end

* ============================================================
* Display the information-criterion grid
* ============================================================
capture program drop _qardl_display_icgrid
program define _qardl_display_icgrid
    args ic_grid plo phi qlo qhi popt qopt critup

    * Table width adapts to the number of q columns
    local gw = 6 + 12 * (`qhi' - `qlo' + 1)

    di as txt _n "  `critup' Grid: rows = p (AR lags), columns = q (DL lags)"
    di as txt "  {hline `gw'}"

    * Header row: q values
    di as txt "  {ralign 6:p \ q}" _c
    forvalues j = `qlo'/`qhi' {
        di as txt "  {ralign 10:q=`j'}" _c
    }
    di ""
    di as txt "  {hline `gw'}"

    forvalues i = `plo'/`phi' {
        local ri = `i' - `plo' + 1
        di as txt "  {ralign 6:p=`i'}" _c
        forvalues j = `qlo'/`qhi' {
            local rj = `j' - `qlo' + 1
            local bval = `ic_grid'[`ri', `rj']
            if `i' == `popt' & `j' == `qopt' {
                di as res " " %9.3f `bval' "*" _c
            }
            else if `bval' >= . {
                di as txt "  " %9s "." " " _c
            }
            else {
                di as txt "  " %9.3f `bval' " " _c
            }
        }
        di ""
    }
    di as txt "  {hline `gw'}"
    local rp = `popt' - `plo' + 1
    local rq = `qopt' - `qlo' + 1
    di as res "  Optimal: p = `popt', q = `qopt'" ///
        as txt "  (min `critup' = " %9.3f `ic_grid'[`rp', `rq'] ")"
    di as txt "  * denotes minimum `critup'"
    di as txt "{hline 70}"
end

* ============================================================
* Display standard QARDL results
* ============================================================
capture program drop _qardl_display_results
program define _qardl_display_results
    args beta beta_cov phi phi_cov gamma gamma_cov ///
         tau_vec p q k nobs depvar indepvars is_ecm ///
         scale_beta scale_short covariance haclags

    local ntau = rowsof(`tau_vec')

    * Header
    di as txt _n
    di as txt "{hline 70}"
    if `is_ecm' {
        di as res "  QARDL-ECM Estimation Results"
    }
    else {
        di as res "  QARDL Estimation Results"
    }
    di as txt "{hline 70}"
    di as txt "  Cho, Kim & Shin (2015), Journal of Econometrics"
    di as txt "{hline 70}"
    di as txt "  Dep. variable  : " as res "`depvar'"
    di as txt "  Indep. vars    : " as res "`indepvars'"
    di as txt "  Observations   : " as res `nobs'
    di as txt "  QARDL(" as res `p' as txt "," as res `q' as txt ")"
    if "`covariance'" == "iid" {
        di as txt "  Covariance     : " as res "iid (Cho-Kim-Shin)"
    }
    else if "`covariance'" == "robust" {
        di as txt "  Covariance     : " as res "heteroskedasticity-robust QR sandwich"
    }
    else {
        di as txt "  Covariance     : " as res "Newey-West HAC QR sandwich (lags = `haclags')"
    }
    di as txt "  Quantiles      : " _c
    forvalues i = 1/`ntau' {
        di as res %5.2f `tau_vec'[`i',1] " " _c
    }
    di ""
    di as txt "{hline 70}"

    * Long-run parameter: beta
    di as txt _n
    di as txt "{hline 70}"
    di as res "  Long-Run Parameters: {it:beta}(tau)"
    di as txt "  beta_j(tau) = gamma_j(tau) / (1 - sum(phi_i(tau)))"
    di as txt "{hline 70}"
    _qardl_coef_table `beta' `beta_cov' `tau_vec' `k' `scale_beta' ///
        "`indepvars'" "Variable"

    * Short-run AR parameter: phi
    di as txt _n
    di as txt "{hline 70}"
    di as res "  Short-Run AR Parameters: {it:phi}(tau)"
    di as txt "{hline 70}"
    local phinames ""
    forvalues j = 1/`p' {
        local phinames "`phinames' L`j'.`depvar'"
    }
    _qardl_coef_table `phi' `phi_cov' `tau_vec' `p' `scale_short' ///
        "`phinames'" "Lag"

    * Short-run impact parameter: gamma
    di as txt _n
    di as txt "{hline 70}"
    di as res "  Short-Run Impact Parameters: {it:gamma}(tau)"
    di as txt "{hline 70}"
    _qardl_coef_table `gamma' `gamma_cov' `tau_vec' `k' `scale_short' ///
        "`indepvars'" "Variable"
end

* ============================================================
* Generic coefficient table
*   se = sqrt( diag(cov) / scale )
* ============================================================
capture program drop _qardl_coef_table
program define _qardl_coef_table
    args param cov tau_vec dim scale rownames label

    local ntau = rowsof(`tau_vec')
    local nrows = rowsof(`param')

    di as txt "  {ralign 12:`label'}" _c
    di as txt "  {ralign 8:Quantile}" _c
    di as txt "  {ralign 12:Estimate}" _c
    di as txt "  {ralign 10:Std.Err.}" _c
    di as txt "  {ralign 10:z-stat}" _c
    di as txt "  {ralign 10:p-value}" _c
    di as txt "  {ralign 5:Sig.}"
    di as txt "{hline 70}"

    local idx = 1
    * vec() stacks columns: outer loop = quantile, inner = parameter
    forvalues t = 1/`ntau' {
        local tauval = `tau_vec'[`t', 1]
        di as txt "  {hline 4} tau = " %5.2f `tauval' " {hline 48}"
        foreach v of local rownames {
            if `idx' <= `nrows' {
                local est = `param'[`idx', 1]
                local var_val = `cov'[`idx', `idx'] / `scale'
                if `var_val' > 0 {
                    local se = sqrt(`var_val')
                }
                else {
                    local se = .
                }
                if `se' != . & `se' > 0 {
                    local zstat = `est' / `se'
                    local pval = 2 * normal(-abs(`zstat'))
                }
                else {
                    local zstat = .
                    local pval = .
                }

                if `pval' >= .            local star ""
                else if `pval' < 0.01     local star "***"
                else if `pval' < 0.05     local star "**"
                else if `pval' < 0.10     local star "*"
                else                      local star ""

                di as txt "  {ralign 12:`v'}" _c
                di as txt "  {ralign 8:" %5.2f `tauval' "}" _c
                di as res "  {ralign 12:" %10.4f `est' "}" _c
                if `se' != . {
                    di as txt "  {ralign 10:" %8.4f `se' "}" _c
                    di as txt "  {ralign 10:" %8.3f `zstat' "}" _c
                    if `pval' < 0.01 {
                        di as res "  {ralign 10:" %8.4f `pval' "}" _c
                    }
                    else if `pval' < 0.05 {
                        di as res "  {ralign 10:" %8.4f `pval' "}" _c
                    }
                    else {
                        di as txt "  {ralign 10:" %8.4f `pval' "}" _c
                    }
                    di as txt "  {ralign 5:`star'}"
                }
                else {
                    di as txt "  {ralign 10:    .}" _c
                    di as txt "  {ralign 10:    .}" _c
                    di as txt "  {ralign 10:    .}" _c
                    di as txt "  {ralign 5:}"
                }
                local ++idx
            }
        }
    }
    di as txt "{hline 70}"
    di as txt "  *** p<0.01, ** p<0.05, * p<0.10"
end

* ============================================================
* Display ECM-specific results (Cho phi*/theta parameterisation)
* ============================================================
capture program drop _qardl_display_ecm
program define _qardl_display_ecm
    args phi_ecm phi_ecm_cov theta theta_cov tau_vec p q k nobs indepvars

    local ntau = rowsof(`tau_vec')

    * ECM phi parameters
    di as txt _n
    di as txt "{hline 70}"
    di as res "  ECM Short-Run Parameters: {it:phi*}(tau)"
    di as txt "  (Cumulative AR coefficients in ECM parameterization)"
    di as txt "{hline 70}"

    local pp1 = `p' - 1
    if `pp1' < 1 local pp1 = 1
    local phinames ""
    forvalues j = 1/`pp1' {
        local phinames "`phinames' phi*_`j'"
    }
    _qardl_coef_table `phi_ecm' `phi_ecm_cov' `tau_vec' `pp1' ///
        `= `nobs' - 1' "`phinames'" "Lag"

    * Theta parameters
    di as txt _n
    di as txt "{hline 70}"
    di as res "  ECM Short-Run Parameters: {it:theta}(tau)"
    di as txt "  (Impact coefficients of dx in ECM form)"
    di as txt "{hline 70}"

    * theta stacks the lagged-difference block variable-major, lag-minor:
    * [x1 lag0 ... x1 lag(q-1), x2 lag0 ...], matching how eei is built in
    * qardlecm.m.  The labels must follow that order.
    local thnames ""
    foreach v of local indepvars {
        forvalues lag = 0/`= `q' - 1' {
            if `q' > 1 {
                local thnames "`thnames' L`lag'.d.`v'"
            }
            else {
                local thnames "`thnames' d.`v'"
            }
        }
    }
    _qardl_coef_table `theta' `theta_cov' `tau_vec' `= `q' * `k'' ///
        `= `nobs' - 2' "`thnames'" "Variable"
end

* ============================================================
* Display GAUSS-style two-step ECM results
* ============================================================
capture program drop _qardl_display_ecm2
program define _qardl_display_ecm2
    args beta_lr alpha alpha_cov rho rho_cov tau_vec rho_ols nobs_ecm indepvars

    local ntau = rowsof(`tau_vec')

    di as txt _n
    di as txt "{hline 70}"
    di as res "  Two-Step QARDL-ECM (GAUSS 3.1.1 parameterization)"
    di as txt "  d.y = alpha(tau) + rho(tau)*ECT(-1) + short-run terms"
    di as txt "  ECT(-1) = y(-1) - x(-1)'beta_LR   [beta_LR from step-1 OLS]"
    di as txt "{hline 70}"
    di as txt "  ECM observations : " as res `nobs_ecm'
    di as txt "  OLS rho          : " as res %10.4f `rho_ols'
    di as txt "{hline 70}"

    * Step-1 long-run vector
    di as txt _n "  {bf:Step-1 long-run coefficients (OLS)}"
    di as txt "  {hline 40}"
    di as txt "  {ralign 16:Variable}" _c
    di as txt "  {ralign 14:beta_LR}"
    di as txt "  {hline 40}"
    local vnum = 0
    foreach v of local indepvars {
        local ++vnum
        di as txt "  {ralign 16:`v'}" _c
        di as res "  {ralign 14:" %12.4f `beta_lr'[`vnum', 1] "}"
    }
    di as txt "  {hline 40}"

    * alpha(tau)
    di as txt _n
    di as res "  ECM Intercept: {it:alpha}(tau)"
    di as txt "{hline 70}"
    _qardl_coef_table `alpha' `alpha_cov' `tau_vec' 1 1 "alpha" "Parameter"

    * rho(tau)
    di as txt _n
    di as res "  Speed of Adjustment: {it:rho}(tau)"
    di as txt "  (rho < 0 and significant implies convergence to equilibrium)"
    di as txt "{hline 70}"
    _qardl_coef_table `rho' `rho_cov' `tau_vec' 1 1 "rho" "Parameter"

    * Convergence signal
    di as txt _n "  {ralign 10:Quantile}" _c
    di as txt "  {ralign 14:rho(tau)}" _c
    di as txt "  {ralign 12:Half-life}" _c
    di as txt "  {ralign 12:Signal}"
    di as txt "  {hline 52}"
    forvalues t = 1/`ntau' {
        local tv = `tau_vec'[`t', 1]
        local rv = `rho'[`t', 1]
        if `rv' < 0 & `rv' > -2 {
            local hl = ln(0.5) / ln(1 + `rv')
            local sig "Conv."
        }
        else {
            local hl = .
            local sig "Diverg."
        }
        di as txt "  {ralign 10:" %5.2f `tv' "}" _c
        di as res "  {ralign 14:" %12.4f `rv' "}" _c
        if `hl' < . {
            di as txt "  {ralign 12:" %10.2f `hl' "}" _c
            di as res "  {ralign 12:`sig'}"
        }
        else {
            di as txt "  {ralign 12:      .}" _c
            di as res "  {ralign 12:`sig'}"
        }
    }
    di as txt "  {hline 52}"
    di as txt "{hline 70}"
end

* ============================================================
* Default Wald tests across quantiles (constancy)
* Mirrors wtestconst() from GAUSS QARDL 3.1.1
* ============================================================
capture program drop _qardl_default_wald
program define _qardl_default_wald
    args beta beta_cov phi phi_cov gamma gamma_cov ///
         tau_vec p q k nobs indepvars scale_beta scale_short

    local ntau = rowsof(`tau_vec')

    if `ntau' < 2 {
        exit
    }

    di as txt _n
    di as txt "{hline 70}"
    di as res "  Wald Tests for Parameter Constancy Across Quantiles"
    di as txt "  H0: parameter(tau_i) = parameter(tau_{i+1})"
    di as txt "{hline 70}"
    di as txt "  {ralign 20:Test}" _c
    di as txt "  {ralign 12:Wald stat}" _c
    di as txt "  {ralign 8:df}" _c
    di as txt "  {ralign 12:p-value}" _c
    di as txt "  {ralign 14:Decision}"
    di as txt "{hline 70}"

    _qardl_one_wald `beta' `beta_cov' `k' `ntau' `scale_beta' "Beta constancy"
    _qardl_one_wald `phi' `phi_cov' `p' `ntau' `scale_short' "Phi constancy"
    _qardl_one_wald `gamma' `gamma_cov' `k' `ntau' `scale_short' "Gamma constancy"

    di as txt "{hline 70}"
    di as txt "  *** p<0.01, ** p<0.05, * p<0.10"

    * ============================================================
    * ECM Speed-of-Adjustment Table (rho)
    * ============================================================
    di as txt _n
    di as txt "{hline 70}"
    di as res "  ECM Speed of Adjustment: {it:rho}(tau) = SUM {it:phi}_i(tau) - 1"
    di as txt "  (rho < 0 implies convergence to long-run equilibrium)"
    di as txt "{hline 70}"
    di as txt "  {ralign 8:Quantile}" _c
    di as txt "  {ralign 12:rho(tau)}" _c
    di as txt "  {ralign 10:Std.Err.}" _c
    di as txt "  {ralign 10:z-stat}" _c
    di as txt "  {ralign 10:p-value}" _c
    di as txt "  {ralign 8:Signal}"
    di as txt "{hline 70}"

    local phi_rows = rowsof(`phi')
    local phi_cov_dim = rowsof(`phi_cov')

    forvalues t = 1/`ntau' {
        local tauval = `tau_vec'[`t', 1]

        local sum_phi = 0
        forvalues i = 1/`p' {
            local phi_idx = (`t' - 1) * `p' + `i'
            if `phi_idx' <= `phi_rows' {
                local sum_phi = `sum_phi' + `phi'[`phi_idx', 1]
            }
        }
        local rho_val = `sum_phi' - 1

        * Var(rho) = sum_i sum_j Cov(phi_i, phi_j), on the SE scale
        local var_rho = 0
        forvalues i = 1/`p' {
            forvalues j = 1/`p' {
                local pi = (`t' - 1) * `p' + `i'
                local pj = (`t' - 1) * `p' + `j'
                if `pi' <= `phi_cov_dim' & `pj' <= `phi_cov_dim' {
                    local var_rho = `var_rho' + `phi_cov'[`pi', `pj']
                }
            }
        }
        local var_rho = `var_rho' / `scale_short'

        if `var_rho' > 0 {
            local se_rho = sqrt(`var_rho')
        }
        else {
            local se_rho = .
        }

        if `se_rho' != . & `se_rho' > 0 {
            local zstat = `rho_val' / `se_rho'
            local pval = 2 * normal(-abs(`zstat'))
        }
        else {
            local zstat = .
            local pval = .
        }

        if `rho_val' < 0 {
            local signal "Conv."
        }
        else {
            local signal "Diverg."
        }

        di as txt "  {ralign 8:" %5.2f `tauval' "}" _c
        di as res "  {ralign 12:" %10.4f `rho_val' "}" _c
        if `se_rho' != . {
            di as txt "  {ralign 10:" %8.4f `se_rho' "}" _c
            di as txt "  {ralign 10:" %8.3f `zstat' "}" _c
            if `pval' < 0.01 {
                di as res "  {ralign 10:" %8.4f `pval' "}" _c
            }
            else if `pval' < 0.05 {
                di as res "  {ralign 10:" %8.4f `pval' "}" _c
            }
            else {
                di as txt "  {ralign 10:" %8.4f `pval' "}" _c
            }
        }
        else {
            di as txt "  {ralign 10:    .}" _c
            di as txt "  {ralign 10:    .}" _c
            di as txt "  {ralign 10:    .}" _c
        }
        if `rho_val' < 0 {
            di as res "  {ralign 8:`signal'}"
        }
        else {
            di as res "  {ralign 8:`signal'}"
        }
    }
    di as txt "{hline 70}"

    * ============================================================
    * Pairwise Equality Tests (Variable-Specific)
    * ============================================================
    if `ntau' >= 2 {
        di as txt _n
        di as txt "{hline 70}"
        di as res "  Pairwise Equality Tests Across Quantiles (by variable)"
        di as txt "  H0: param_v(tau_i) = param_v(tau_j)"
        di as txt "{hline 70}"

        di as txt _n "  {bf:Long-Run Parameters (beta)}"
        _qardl_pairwise `beta' `beta_cov' `tau_vec' `k' `scale_beta' "`indepvars'"

        di as txt _n "  {bf:Short-Run Impact Parameters (gamma)}"
        _qardl_pairwise `gamma' `gamma_cov' `tau_vec' `k' `scale_short' "`indepvars'"

        di as txt "  *** p<0.01, ** p<0.05, * p<0.10"
    }
    di as txt "{hline 70}"
end

* ============================================================
* One constancy Wald test row
* ============================================================
capture program drop _qardl_one_wald
program define _qardl_one_wald
    args param cov dim ntau scale label

    if rowsof(`param') < `dim' * `ntau' exit
    if rowsof(`cov') < `dim' * `ntau' exit

    tempname R r W
    mata: _qardl_build_constancy_R(`dim', `ntau', "`R'", "`r'")

    capture mata: _qardl_wald_stat("`param'", "`cov'", "`R'", "`r'", `scale', "`W'")
    if _rc exit

    local wstat = `W'[1,1]
    local df = `W'[2,1]
    if `df' < 1 exit
    if `wstat' >= . exit
    local wpv = chi2tail(`df', `wstat')

    if `wpv' < 0.01      local decision "Reject***"
    else if `wpv' < 0.05 local decision "Reject**"
    else if `wpv' < 0.10 local decision "Reject*"
    else                 local decision "Fail to reject"

    di as txt "  {ralign 20:`label'}" _c
    di as res "  {ralign 12:" %10.3f `wstat' "}" _c
    di as txt "  {ralign 8:`df'}" _c
    if `wpv' < 0.05 {
        di as res "  {ralign 12:" %10.4f `wpv' "}" _c
        di as res "  {ralign 14:`decision'}"
    }
    else {
        di as txt "  {ralign 12:" %10.4f `wpv' "}" _c
        di as txt "  {ralign 14:`decision'}"
    }
end

* ============================================================
* Pairwise across-quantile equality tests for one parameter block
* ============================================================
capture program drop _qardl_pairwise
program define _qardl_pairwise
    args param cov tau_vec dim scale varnames

    local ntau = rowsof(`tau_vec')
    local pdim = rowsof(`param')
    local cdim = rowsof(`cov')

    di as txt "  {hline 66}"
    di as txt "  {ralign 12:Variable}" _c
    di as txt "  {ralign 8:tau_i}" _c
    di as txt "  {ralign 8:tau_j}" _c
    di as txt "  {ralign 10:Wald}" _c
    di as txt "  {ralign 6:df}" _c
    di as txt "  {ralign 10:p-value}" _c
    di as txt "  {ralign 10:Decision}"
    di as txt "  {hline 66}"

    local vnum = 0
    foreach v of local varnames {
        local ++vnum
        forvalues i = 1/`ntau' {
            local ti = `tau_vec'[`i', 1]
            local ip1 = `i' + 1
            forvalues j = `ip1'/`ntau' {
                local tj = `tau_vec'[`j', 1]

                local idx_i = (`i' - 1) * `dim' + `vnum'
                local idx_j = (`j' - 1) * `dim' + `vnum'

                if `idx_i' <= `pdim' & `idx_j' <= `pdim' ///
                 & `idx_i' <= `cdim' & `idx_j' <= `cdim' {
                    local diff = `param'[`idx_i', 1] - `param'[`idx_j', 1]

                    local v_ii = `cov'[`idx_i', `idx_i']
                    local v_jj = `cov'[`idx_j', `idx_j']
                    local v_ij = `cov'[`idx_i', `idx_j']
                    local var_diff = `v_ii' + `v_jj' - 2 * `v_ij'

                    if `var_diff' > 1e-15 {
                        local wstat = `scale' * (`diff')^2 / `var_diff'
                        local wpv = chi2tail(1, `wstat')

                        if `wpv' < 0.01      local decision "Reject***"
                        else if `wpv' < 0.05 local decision "Reject**"
                        else if `wpv' < 0.10 local decision "Reject*"
                        else                 local decision "Accept"

                        di as txt "  {ralign 12:`v'}" _c
                        di as txt "  {ralign 8:" %5.2f `ti' "}" _c
                        di as txt "  {ralign 8:" %5.2f `tj' "}" _c
                        di as res "  {ralign 10:" %8.3f `wstat' "}" _c
                        di as txt "  {ralign 6:1}" _c
                        if `wpv' < 0.05 {
                            di as res "  {ralign 10:" %8.4f `wpv' "}" _c
                            di as res "  {ralign 10:`decision'}"
                        }
                        else {
                            di as txt "  {ralign 10:" %8.4f `wpv' "}" _c
                            di as txt "  {ralign 10:`decision'}"
                        }
                    }
                }
            }
        }
        di as txt "  {hline 66}"
    }
end

* ============================================================
* Quantile symmetry Wald tests
* Mirrors wtestsym() from GAUSS QARDL 3.1.1
* H0: parameter(tau) = parameter(1-tau)
* ============================================================
capture program drop _qardl_symmetry_wald
program define _qardl_symmetry_wald
    args beta beta_cov phi phi_cov gamma gamma_cov ///
         tau_vec p k scale_beta scale_short

    local ntau = rowsof(`tau_vec')

    tempname npairs
    mata: st_numscalar("`npairs'", _qardl_count_sym_pairs("`tau_vec'"))

    di as txt _n
    di as txt "{hline 70}"
    di as res "  Wald Tests for Quantile Symmetry"
    di as txt "  H0: parameter(tau) = parameter(1-tau)"
    di as txt "{hline 70}"

    if `npairs' == 0 {
        di as txt "  No symmetric quantile pairs (tau_i + tau_j = 1) in tau()."
        di as txt "  Supply e.g. tau(0.1 0.25 0.5 0.75 0.9) to enable this test."
        di as txt "{hline 70}"
        exit
    }

    di as txt "  Symmetric pairs found : " as res `npairs'
    di as txt "{hline 70}"
    di as txt "  {ralign 20:Test}" _c
    di as txt "  {ralign 12:Wald stat}" _c
    di as txt "  {ralign 8:df}" _c
    di as txt "  {ralign 12:p-value}" _c
    di as txt "  {ralign 14:Decision}"
    di as txt "{hline 70}"

    _qardl_one_sym `beta' `beta_cov' `k' `tau_vec' `scale_beta' "Beta symmetry"
    _qardl_one_sym `phi' `phi_cov' `p' `tau_vec' `scale_short' "Phi symmetry"
    _qardl_one_sym `gamma' `gamma_cov' `k' `tau_vec' `scale_short' "Gamma symmetry"

    di as txt "{hline 70}"
    di as txt "  *** p<0.01, ** p<0.05, * p<0.10"
end

capture program drop _qardl_one_sym
program define _qardl_one_sym
    args param cov dim tau_vec scale label

    tempname R r W
    mata: _qardl_build_symmetry_R(`dim', "`tau_vec'", "`R'", "`r'")

    capture mata: _qardl_wald_stat("`param'", "`cov'", "`R'", "`r'", `scale', "`W'")
    if _rc exit

    local wstat = `W'[1,1]
    local df = `W'[2,1]
    if `df' < 1 exit
    if `wstat' >= . exit
    local wpv = chi2tail(`df', `wstat')

    if `wpv' < 0.01      local decision "Reject***"
    else if `wpv' < 0.05 local decision "Reject**"
    else if `wpv' < 0.10 local decision "Reject*"
    else                 local decision "Fail to reject"

    di as txt "  {ralign 20:`label'}" _c
    di as res "  {ralign 12:" %10.3f `wstat' "}" _c
    di as txt "  {ralign 8:`df'}" _c
    if `wpv' < 0.05 {
        di as res "  {ralign 12:" %10.4f `wpv' "}" _c
        di as res "  {ralign 14:`decision'}"
    }
    else {
        di as txt "  {ralign 12:" %10.4f `wpv' "}" _c
        di as txt "  {ralign 14:`decision'}"
    }
end

* ============================================================
* Default ECM Wald tests (Cho phi*/theta parameterisation)
* ============================================================
capture program drop _qardl_default_ecm_wald
program define _qardl_default_ecm_wald
    args phi_ecm phi_ecm_cov theta theta_cov tau_vec p q k nobs

    local ntau = rowsof(`tau_vec')
    if `ntau' < 2 exit

    local pp1 = `p' - 1
    if `pp1' < 1 exit

    di as txt _n
    di as txt "{hline 70}"
    di as res "  ECM Wald Tests for Parameter Constancy Across Quantiles"
    di as txt "{hline 70}"
    di as txt "  {ralign 20:Test}" _c
    di as txt "  {ralign 12:Wald stat}" _c
    di as txt "  {ralign 8:df}" _c
    di as txt "  {ralign 12:p-value}" _c
    di as txt "  {ralign 14:Decision}"
    di as txt "{hline 70}"

    _qardl_one_wald `phi_ecm' `phi_ecm_cov' `pp1' `ntau' ///
        `= `nobs' - 1' "Phi-ECM constancy"

    local theta_dim = `q' * `k'
    if `theta_dim' > 0 {
        _qardl_one_wald `theta' `theta_cov' `theta_dim' `ntau' ///
            `= `nobs' - 2' "Theta constancy"
    }

    di as txt "{hline 70}"
    di as txt "  *** p<0.01, ** p<0.05, * p<0.10"
end

* ============================================================
* User-specified Wald tests
*   waldtest(beta)                        constancy on beta
*   waldtest(beta phi gamma)              several parameter blocks
*   waldtest(beta, r(Rmat) rr(rvec))      custom restriction matrices
* ============================================================
capture program drop _qardl_run_waldtest
program define _qardl_run_waldtest
    args spec beta beta_cov phi phi_cov gamma gamma_cov ///
         tau_vec p q k scale_beta scale_short

    local ntau = rowsof(`tau_vec')

    * Split "blocks , options"
    gettoken blocks opts : spec, parse(",")
    if substr("`opts'", 1, 1) == "," {
        local opts = substr("`opts'", 2, .)
    }

    local Rmat ""
    local rvec ""
    if trim("`opts'") != "" {
        local 0 ", `opts'"
        syntax , [R(string) RR(string)]
        local Rmat "`r'"
        local rvec "`rr'"
    }

    if trim("`blocks'") == "" local blocks "beta phi gamma"

    di as txt _n
    di as txt "{hline 70}"
    di as res "  User-Specified Wald Tests"
    di as txt "{hline 70}"
    di as txt "  {ralign 20:Test}" _c
    di as txt "  {ralign 12:Wald stat}" _c
    di as txt "  {ralign 8:df}" _c
    di as txt "  {ralign 12:p-value}" _c
    di as txt "  {ralign 14:Decision}"
    di as txt "{hline 70}"

    foreach b of local blocks {
        local b = lower("`b'")
        if "`b'" == "beta" {
            local param "`beta'"
            local cov "`beta_cov'"
            local dim = `k'
            local sc = `scale_beta'
        }
        else if "`b'" == "phi" {
            local param "`phi'"
            local cov "`phi_cov'"
            local dim = `p'
            local sc = `scale_short'
        }
        else if "`b'" == "gamma" {
            local param "`gamma'"
            local cov "`gamma_cov'"
            local dim = `k'
            local sc = `scale_short'
        }
        else {
            di as error "waldtest(): unknown parameter block '`b''"
            di as error "valid blocks are beta, phi, gamma"
            exit 198
        }

        tempname R rr W
        if "`Rmat'" != "" {
            capture confirm matrix `Rmat'
            if _rc {
                di as error "waldtest(): matrix `Rmat' not found"
                exit 198
            }
            mat `R' = `Rmat'
            if "`rvec'" != "" {
                capture confirm matrix `rvec'
                if _rc {
                    di as error "waldtest(): matrix `rvec' not found"
                    exit 198
                }
                mat `rr' = `rvec'
            }
            else {
                mat `rr' = J(rowsof(`R'), 1, 0)
            }
        }
        else {
            mata: _qardl_build_constancy_R(`dim', `ntau', "`R'", "`rr'")
        }

        capture noisily mata: _qardl_wald_stat("`param'", "`cov'", "`R'", ///
            "`rr'", `sc', "`W'")
        if _rc continue

        local wstat = `W'[1,1]
        local df = `W'[2,1]
        if `df' < 1 continue
        if `wstat' >= . continue
        local wpv = chi2tail(`df', `wstat')

        if `wpv' < 0.01      local decision "Reject***"
        else if `wpv' < 0.05 local decision "Reject**"
        else if `wpv' < 0.10 local decision "Reject*"
        else                 local decision "Fail to reject"

        di as txt "  {ralign 20:W(`b')}" _c
        di as res "  {ralign 12:" %10.3f `wstat' "}" _c
        di as txt "  {ralign 8:`df'}" _c
        if `wpv' < 0.05 {
            di as res "  {ralign 12:" %10.4f `wpv' "}" _c
            di as res "  {ralign 14:`decision'}"
        }
        else {
            di as txt "  {ralign 12:" %10.4f `wpv' "}" _c
            di as txt "  {ralign 14:`decision'}"
        }
    }

    di as txt "{hline 70}"
    di as txt "  *** p<0.01, ** p<0.05, * p<0.10"
end
