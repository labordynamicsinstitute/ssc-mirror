*! fqardl v1.1.0 — Fourier Quantile ARDL
*! Implements: (1) FQARDL, (2) FBQARDL (bootstrap), (3) Quantile Cointegration
*! References: Cho, Kim & Shin (2015); Zaghdoudi (2025); Furno (2021)
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Date: February 2026

capture program drop fqardl
capture program drop _fqardl_display_full
capture program drop _fqardl_display_ecm
capture program drop _fqardl_display_bootstrap
capture program drop _fqardl_pval_display
capture program drop _fqardl_select_kstar
capture program drop _fqardl_waldtest
capture program drop _fqardl_estimate
capture program drop _fqardl_ecm
capture program drop _fqardl_bootstrap
capture program drop _fqardl_qcoint
capture mata: mata drop _fqardl_qreg()
capture mata: mata drop _fqardl_qreg_irls()
capture mata: mata drop _fqardl_core_estimate()
capture mata: mata drop _fqardl_build_constancy_R()
capture mata: mata drop _fqardl_wald_stat()
program define fqardl, eclass sortpreserve
    version 14.0

    // =========================================================================
    // 1. SYNTAX PARSING
    // =========================================================================
    syntax varlist(min=2 numeric ts) [if] [in], ///
        TAU(numlist >0 <1 sort) ///
        [Type(string) ///
         P(integer 0) Q(integer 0) PMAX(integer 4) QMAX(integer 4) ///
         MAXLAG(integer 4) MAXK(real 3) ///
         IC(string) CASE(integer 3) ///
         ECM REPS(integer 999) ///
         GRAPH NOTABle LEVel(cilevel) ///
         NOFourier NOCONStant ///
         LEADS(integer 1) LAGS(integer 1) BREAK(varlist) ///
         WALDtest]

    marksample touse
    tempvar touse2
    qui gen byte `touse2' = `touse'

    gettoken depvar indepvars : varlist
    local k : word count `indepvars'

    if `k' < 1 {
        di as error "at least one independent variable required"
        exit 198
    }

    // Validate type
    if "`type'" == "" local type "fqardl"
    local type = lower("`type'")
    if !inlist("`type'", "fqardl", "fbqardl", "qcoint") {
        di as err "type() must be {bf:fqardl}, {bf:fbqardl}, or {bf:qcoint}"
        exit 198
    }

    // Validate IC — BIC is the default (like ardl)
    if "`ic'" == "" local ic "bic"
    local ic = lower("`ic'")
    if !inlist("`ic'", "aic", "bic") {
        di as err "ic() must be {bf:aic} or {bf:bic}"
        exit 198
    }

    // Validate maxlag / case
    if `maxlag' < 1 | `maxlag' > 12 {
        di as err "maxlag() must be between 1 and 12"
        exit 198
    }
    if !inlist(`case', 2, 3, 4, 5) {
        di as err "case() must be 2, 3, 4, or 5"
        exit 198
    }

    // Time series
    qui tsset
    local timevar "`r(timevar)'"
    local panelvar "`r(panelvar)'"
    if "`panelvar'" != "" {
        di as err "fqardl is designed for time-series data only"
        exit 198
    }

    // Parse tau
    local ntau : word count `tau'
    tempname tau_vec
    mata: st_matrix("`tau_vec'", strtoreal(tokens(st_local("tau")))')

    // Count obs
    qui count if `touse'
    local nobs = r(N)

    if `nobs' < 20 {
        di as err "insufficient observations (need at least 20)"
        exit 2001
    }

    // =========================================================================
    // MAIN HEADER (ardl-style)
    // =========================================================================
    di as txt ""
    di as txt "{hline 78}"
    if "`type'" == "fqardl" {
        di as res _col(5) "Fourier Quantile ARDL (FQARDL)"
        di as txt _col(5) "Quantile Regression with Fourier Flexible Form"
    }
    else if "`type'" == "fbqardl" {
        di as res _col(5) "Fourier Bootstrap Quantile ARDL (FBQARDL)"
        di as txt _col(5) "With Unconditional & Conditional Bootstrap Cointegration Tests"
    }
    else {
        di as res _col(5) "Quantile Cointegration Test"
        di as txt _col(5) "Residual-based Cointegration at Quantiles"
    }
    di as txt "{hline 78}"
    di as txt _col(3) "Dep. variable   : " as res "`depvar'"
    di as txt _col(3) "Indep. vars     : " as res "`indepvars'"
    di as txt _col(3) "Observations    : " as res "`nobs'"
    di as txt _col(3) "Quantiles       : " _c
    forvalues i = 1/`ntau' {
        local tv : word `i' of `tau'
        di as res %5.2f `tv' " " _c
    }
    di ""
    if "`nofourier'" == "" {
        di as txt _col(3) "Max Fourier k   : " as res "`maxk'"
    }
    else {
        di as txt _col(3) "Fourier terms   : " as res "excluded"
    }
    di as txt _col(3) "Lag selection    : " as res upper("`ic'")
    if "`type'" == "fbqardl" {
        di as txt _col(3) "Bootstrap reps  : " as res "`reps'"
    }
    di as txt "{hline 78}"
    di as txt ""

    // =========================================================================
    // ROUTE: Quantile Cointegration
    // =========================================================================
    if "`type'" == "qcoint" {
        local kstar_val = 0
        if "`nofourier'" == "" {
            _fqardl_select_kstar `varlist' if `touse', ///
                maxk(`maxk') maxlag(`maxlag') tau(`tau') ///
                timevar(`timevar') `nofourier'
            local kstar_val = r(kstar)
        }

        _fqardl_qcoint `varlist' if `touse', ///
            tau(`tau') kstar(`kstar_val') ///
            leads(`leads') lags(`lags') `= cond("`break'"!="", "break(`break')", "")'

        ereturn clear
        ereturn post, esample(`touse') obs(`nobs')
        ereturn matrix qcoint_results = _fqardl_qcoint_results
        ereturn scalar kstar = `kstar_val'
        ereturn local cmd "fqardl"
        ereturn local model "qcoint"
        ereturn local title "Quantile Cointegration Test"
        ereturn local depvar "`depvar'"
        ereturn local indepvars "`indepvars'"

        if "`graph'" != "" {
            fqardl_graph, tau(`tau') p(1) q(1) k(`k') ///
                depvar("`depvar'") indepvars("`indepvars'") ///
                kstar(`kstar_val') noqprocess
        }
        exit
    }

    // =========================================================================
    // PRESERVE & PREPARE DATA
    // =========================================================================
    preserve
    qui keep if `touse'
    qui count
    local T = r(N)

    tempvar ttrend
    qui gen `ttrend' = _n

    // =========================================================================
    // STEP 1: FOURIER FREQUENCY SELECTION (k* by min SSR)
    // =========================================================================
    local best_kstar = 0

    if "`nofourier'" == "" {
        di as txt _col(3) "{bf:Step 1}: Selecting Fourier frequency k* by minimum SSR"
        di as txt _col(3) "{hline 72}"

        local nkgrid = round(`maxk' / 0.1)
        tempname kgrid ssr_matrix best_ssr_k
        mat `kgrid' = J(1, `nkgrid', .)
        forvalues i = 1/`nkgrid' {
            mat `kgrid'[1, `i'] = `i' * 0.1
        }
        scalar `best_ssr_k' = .
        mat `ssr_matrix' = J(`nkgrid', 2, .)

        forvalues kidx = 1/`nkgrid' {
            local kval = `kgrid'[1, `kidx']
            mat `ssr_matrix'[`kidx', 1] = `kval'

            capture drop _fqardl_sin _fqardl_cos
            if `kval' > 0 {
                qui gen double _fqardl_sin = sin(2*c(pi)*`kval'*`ttrend'/`T')
                qui gen double _fqardl_cos = cos(2*c(pi)*`kval'*`ttrend'/`T')
            }

            // Maximal regression for SSR (OLS used ONLY for k* selection, not estimation)
            local regvars_max "L.`depvar'"
            foreach xvar of local indepvars {
                local regvars_max "`regvars_max' L.`xvar'"
            }
            forvalues j = 1/`maxlag' {
                local regvars_max "`regvars_max' LD`j'.`depvar'"
            }
            foreach xvar of local indepvars {
                local regvars_max "`regvars_max' D.`xvar'"
                forvalues j = 1/`maxlag' {
                    local regvars_max "`regvars_max' LD`j'.`xvar'"
                }
            }
            if `kval' > 0 {
                local regvars_max "`regvars_max' _fqardl_sin _fqardl_cos"
            }

            capture qui regress D.`depvar' `regvars_max'
            if _rc == 0 {
                local this_ssr = e(rss)
            }
            else {
                local this_ssr = .
            }
            mat `ssr_matrix'[`kidx', 2] = `this_ssr'

            if `this_ssr' < scalar(`best_ssr_k') | missing(scalar(`best_ssr_k')) {
                scalar `best_ssr_k' = `this_ssr'
                local best_kstar = `kval'
            }
        }

        di as txt _col(5) "Optimal k* = " as res "`best_kstar'" ///
           as txt "   (min SSR = " as res %12.4f scalar(`best_ssr_k') as txt ")"
        di as txt ""
    }

    // Fix Fourier at optimal k*
    capture drop _fqardl_sin _fqardl_cos
    if `best_kstar' > 0 {
        qui gen double _fqardl_sin = sin(2*c(pi)*`best_kstar'*`ttrend'/`T')
        qui gen double _fqardl_cos = cos(2*c(pi)*`best_kstar'*`ttrend'/`T')
    }

    // =========================================================================
    // STEP 2: LAG ORDER SELECTION (p,q) by BIC/AIC
    // Uses OLS-based IC for lag selection only (standard practice)
    // Actual estimation uses quantile regression
    // =========================================================================
    local p = `p'
    local q = `q'

    if `p' == 0 & `q' == 0 {
        di as txt _col(3) "{bf:Step 2}: Selecting lag orders (p,q) by " upper("`ic'")
        di as txt _col(3) "{hline 72}"

        tempname best_ic_val bic_grid
        scalar `best_ic_val' = .
        local best_p = 1
        local best_q = 1
        local total_specs = 0

        mat `bic_grid' = J(`pmax', `qmax', .)

        forvalues pp = 1/`pmax' {
            forvalues qq = 1/`qmax' {
                local total_specs = `total_specs' + 1

                // Build regressor list using ardl-style notation
                // EC form: D.y = L.y + L.x1 + ... + L(1/p)D.y + L(0/q)D.x
                local regvars "L.`depvar'"
                foreach xvar of local indepvars {
                    local regvars "`regvars' L.`xvar'"
                }
                forvalues j = 1/`pp' {
                    local regvars "`regvars' L`j'D.`depvar'"
                }
                foreach xvar of local indepvars {
                    local regvars "`regvars' D.`xvar'"
                    forvalues j = 1/`qq' {
                        local regvars "`regvars' L`j'D.`xvar'"
                    }
                }
                if `best_kstar' > 0 {
                    local regvars "`regvars' _fqardl_sin _fqardl_cos"
                }

                capture qui regress D.`depvar' `regvars'
                if _rc == 0 {
                    local nobs_tmp = e(N)
                    local k_tmp = e(df_m) + 1
                    local ll_tmp = e(ll)

                    if "`ic'" == "aic" {
                        local ic_tmp = -2*`ll_tmp' + 2*`k_tmp'
                    }
                    else {
                        local ic_tmp = -2*`ll_tmp' + `k_tmp'*ln(`nobs_tmp')
                    }

                    mat `bic_grid'[`pp', `qq'] = `ic_tmp'

                    if `ic_tmp' < scalar(`best_ic_val') | missing(scalar(`best_ic_val')) {
                        scalar `best_ic_val' = `ic_tmp'
                        local best_p = `pp'
                        local best_q = `qq'
                    }
                }
            }
        }

        local p = `best_p'
        local q = `best_q'

        // Display BIC/AIC grid (ardl-style)
        di as txt ""
        di as txt _col(5) upper("`ic'") " Grid:  rows = p (AR lags),  columns = q (DL lags)"
        di as txt "  {hline 68}"
        di as txt _col(5) "{ralign 6:p \\ q}" _c
        forvalues j = 1/`qmax' {
            di as txt "  {ralign 10:q=`j'}" _c
        }
        di ""
        di as txt "  {hline 68}"
        forvalues i = 1/`pmax' {
            di as txt _col(5) "{ralign 6:p=`i'}" _c
            forvalues j = 1/`qmax' {
                local bval = `bic_grid'[`i', `j']
                if `i' == `p' & `j' == `q' {
                    di as res " " %9.3f `bval' "*" _c
                }
                else {
                    di as txt "  " %9.3f `bval' " " _c
                }
            }
            di ""
        }
        di as txt "  {hline 68}"
        di as res _col(5) "Optimal: FQARDL(" as res "`p'" as res "," ///
           as res "`q'" as res ")" ///
           as txt "  * denotes min " upper("`ic'") " = " ///
           %9.3f `bic_grid'[`p', `q']
        di as txt _col(5) "(" as res "`total_specs'" as txt " models evaluated)"
        di as txt ""
    }
    else {
        if `p' == 0 local p = 1
        if `q' == 0 local q = 1
    }

    // =========================================================================
    // STEP 3: QUANTILE REGRESSION ESTIMATION
    // Uses IRLS-based quantile regression in Mata (NOT OLS)
    // =========================================================================
    di as txt _col(3) "{bf:Step 3}: Estimating FQARDL(`p',`q') with k* = `best_kstar'"
    di as txt _col(3) "         Quantile regression via IRLS (Mata)"
    di as txt _col(3) "{hline 72}"
    di as txt ""

    // Store lag/kstar info (ardl-style)
    tempname optimlags maxlags_mat
    mat `optimlags' = J(1, 1 + `k', 0)
    mat `optimlags'[1, 1] = `p'
    local colnames "`depvar'"
    local vi = 1
    foreach xvar of local indepvars {
        local ++vi
        mat `optimlags'[1, `vi'] = `q'
        local colnames "`colnames' `xvar'"
    }
    mat colnames `optimlags' = `colnames'

    if "`ecm'" == "" {
        // === STANDARD FQARDL ===
        _fqardl_estimate `varlist' if `touse2', p(`p') q(`q') ///
            tau(`tau') kstar(`best_kstar') `noconstant'

        tempname beta beta_cov phi phi_cov gamma gamma_cov bt_raw bt_se fh_vec
        mat `beta' = r(beta)
        mat `beta_cov' = r(beta_cov)
        mat `phi' = r(phi)
        mat `phi_cov' = r(phi_cov)
        mat `gamma' = r(gamma)
        mat `gamma_cov' = r(gamma_cov)
        mat `bt_raw' = r(bt_raw)
        mat `bt_se' = r(bt_se)
        mat `fh_vec' = r(fh_vec)

        // Display using ardl-style sections
        if "`notable'" == "" {
            _fqardl_display_full `beta' `beta_cov' `phi' `phi_cov' ///
                `gamma' `gamma_cov' `tau_vec' `p' `q' `k' `nobs' ///
                "`depvar'" "`indepvars'" 0 `best_kstar' `bt_raw' `bt_se'
        }

        // Wald tests
        _fqardl_waldtest, bmat(`beta') bvcov(`beta_cov') ///
            pmat(`phi') pvcov(`phi_cov') gmat(`gamma') gvcov(`gamma_cov') ///
            tvec(`tau_vec') pp(`p') qq(`q') kk(`k') nnobs(`nobs') ///
            indepvars("`indepvars'")

        // Compute rho(tau) = sum of phi coefficients for each quantile
        tempname rho_vec
        mat `rho_vec' = J(1, `ntau', 0)
        forvalues t = 1/`ntau' {
            local rho_sum = 0
            forvalues j = 1/`p' {
                local phi_idx = (`t' - 1) * `p' + `j'
                if `phi_idx' <= rowsof(`phi') {
                    local rho_sum = `rho_sum' + `phi'[`phi_idx', 1]
                }
            }
            mat `rho_vec'[1, `t'] = `rho_sum' - 1
        }

        // ereturn
        ereturn clear
        ereturn post, esample(`touse') obs(`nobs')
        ereturn matrix beta = `beta'
        ereturn matrix beta_cov = `beta_cov'
        ereturn matrix phi = `phi'
        ereturn matrix phi_cov = `phi_cov'
        ereturn matrix gamma = `gamma'
        ereturn matrix gamma_cov = `gamma_cov'
        ereturn matrix tau = `tau_vec'
        ereturn matrix bt_raw = `bt_raw'
        ereturn matrix fh = `fh_vec'
        ereturn matrix lags = `optimlags'
        ereturn matrix rho_vec = `rho_vec'
        capture ereturn matrix ssr_matrix = `ssr_matrix'
        ereturn scalar p = `p'
        ereturn scalar q = `q'
        ereturn scalar k = `k'
        ereturn scalar kstar = `best_kstar'
        ereturn scalar ntau = `ntau'
        ereturn local depvar "`depvar'"
        ereturn local indepvars "`indepvars'"
        ereturn local model "fqardl"
        ereturn local cmd "fqardl"
        ereturn local title "FQARDL(`p',`q') regression, k* = `best_kstar'"
    }
    else {
        // === FQARDL-ECM ===
        _fqardl_ecm `varlist' if `touse2', p(`p') q(`q') ///
            tau(`tau') kstar(`best_kstar') `noconstant'

        tempname beta beta_cov phi phi_cov gamma gamma_cov
        tempname phi_ecm phi_ecm_cov theta theta_cov bt_raw bt_se fh_vec

        mat `beta' = r(beta)
        mat `beta_cov' = r(beta_cov)
        mat `phi' = r(phi)
        mat `phi_cov' = r(phi_cov)
        mat `gamma' = r(gamma)
        mat `gamma_cov' = r(gamma_cov)
        mat `phi_ecm' = r(phi_ecm)
        mat `phi_ecm_cov' = r(phi_ecm_cov)
        mat `theta' = r(theta)
        mat `theta_cov' = r(theta_cov)
        mat `bt_raw' = r(bt_raw)
        mat `bt_se' = r(bt_se)
        mat `fh_vec' = r(fh_vec)

        // Display (ardl-style: ADJ + LR + SR sections)
        if "`notable'" == "" {
            _fqardl_display_full `beta' `beta_cov' `phi' `phi_cov' ///
                `gamma' `gamma_cov' `tau_vec' `p' `q' `k' `nobs' ///
                "`depvar'" "`indepvars'" 1 `best_kstar' `bt_raw' `bt_se'

            _fqardl_display_ecm `phi_ecm' `phi_ecm_cov' `theta' ///
                `theta_cov' `tau_vec' `p' `q' `k' `nobs' "`indepvars'" "`depvar'"
        }

        // Wald tests
        _fqardl_waldtest, bmat(`beta') bvcov(`beta_cov') ///
            pmat(`phi') pvcov(`phi_cov') gmat(`gamma') gvcov(`gamma_cov') ///
            tvec(`tau_vec') pp(`p') qq(`q') kk(`k') nnobs(`nobs') ///
            indepvars("`indepvars'")

        // ereturn
        // Compute rho(tau) for ECM
        tempname rho_vec
        mat `rho_vec' = J(1, `ntau', 0)
        forvalues t = 1/`ntau' {
            local rho_sum = 0
            forvalues j = 1/`p' {
                local phi_idx = (`t' - 1) * `p' + `j'
                if `phi_idx' <= rowsof(`phi') {
                    local rho_sum = `rho_sum' + `phi'[`phi_idx', 1]
                }
            }
            mat `rho_vec'[1, `t'] = `rho_sum' - 1
        }

        ereturn clear
        ereturn post, esample(`touse') obs(`nobs')
        ereturn matrix beta = `beta'
        ereturn matrix beta_cov = `beta_cov'
        ereturn matrix phi = `phi'
        ereturn matrix phi_cov = `phi_cov'
        ereturn matrix gamma = `gamma'
        ereturn matrix gamma_cov = `gamma_cov'
        ereturn matrix phi_ecm = `phi_ecm'
        ereturn matrix phi_ecm_cov = `phi_ecm_cov'
        ereturn matrix theta = `theta'
        ereturn matrix theta_cov = `theta_cov'
        ereturn matrix tau = `tau_vec'
        ereturn matrix bt_raw = `bt_raw'
        ereturn matrix fh = `fh_vec'
        ereturn matrix lags = `optimlags'
        ereturn matrix rho_vec = `rho_vec'
        capture ereturn matrix ssr_matrix = `ssr_matrix'
        ereturn scalar p = `p'
        ereturn scalar q = `q'
        ereturn scalar k = `k'
        ereturn scalar kstar = `best_kstar'
        ereturn scalar ntau = `ntau'
        ereturn local depvar "`depvar'"
        ereturn local indepvars "`indepvars'"
        ereturn local model "fqardl-ecm"
        ereturn local cmd "fqardl"
        ereturn local title "FQARDL(`p',`q') regression, EC representation, k* = `best_kstar'"
    }

    // =========================================================================
    // BOOTSTRAP COINTEGRATION (fbqardl type)
    // =========================================================================
    if "`type'" == "fbqardl" {
        local regvars ""
        local levelvars ""
        local indeplev ""
        local ecmvar "L.`depvar'"

        local regvars "L.`depvar'"
        local levelvars "L.`depvar'"
        foreach xvar of local indepvars {
            local regvars "`regvars' L.`xvar'"
            local levelvars "`levelvars' L.`xvar'"
            local indeplev "`indeplev' L.`xvar'"
        }
        forvalues j = 1/`p' {
            local regvars "`regvars' L`j'D.`depvar'"
        }
        foreach xvar of local indepvars {
            local regvars "`regvars' D.`xvar'"
            forvalues j = 1/`q' {
                local regvars "`regvars' L`j'D.`xvar'"
            }
        }
        if `best_kstar' > 0 {
            local regvars "`regvars' _fqardl_sin _fqardl_cos"
        }

        // Save matrices before bootstrap clears ereturn
        mat _fqardl_b_orig = e(beta)
        mat _fqardl_bc_orig = e(beta_cov)
        mat _fqardl_g_orig = e(gamma)
        mat _fqardl_gc_orig = e(gamma_cov)
        mat _fqardl_r_orig = e(rho_vec)
        capture mat _fqardl_ssr_orig = e(ssr_matrix)
        capture mat _fqardl_phi_orig = e(phi)
        capture mat _fqardl_phic_orig = e(phi_cov)
        capture mat _fqardl_tau_orig = e(tau)
        capture mat _fqardl_btr_orig = e(bt_raw)
        capture mat _fqardl_fh_orig = e(fh)
        capture mat _fqardl_lags_orig = e(lags)

        // --- Method 1: Unconditional Bootstrap ---
        _fqardl_bootstrap D.`depvar' `regvars' if `touse2', ///
            depvar("`depvar'") indepvars("`indepvars'") ///
            levelvars("`levelvars'") indeplev("`indeplev'") ///
            ecmvar("`ecmvar'") bootstrap_type("fbqardl_mcnown") ///
            reps(`reps') nobs(`nobs') best_p(`p') ///
            best_kstar(`best_kstar') tau_median(0.5) ///
            timevar("`timevar'")

        _fqardl_display_bootstrap, ///
            depvar("`depvar'") indeplev("`indeplev'") ///
            levelvars("`levelvars'")

        ereturn scalar boot_Fov_pval = r(Fov_pval)
        ereturn scalar boot_t_pval = r(t_pval)
        ereturn scalar boot_Find_pval = r(Find_pval)
        ereturn scalar boot_reps = `reps'

        // --- Method 2: Conditional Bootstrap ---
        _fqardl_bootstrap D.`depvar' `regvars' if `touse2', ///
            depvar("`depvar'") indepvars("`indepvars'") ///
            levelvars("`levelvars'") indeplev("`indeplev'") ///
            ecmvar("`ecmvar'") bootstrap_type("fbqardl_bertelli") ///
            reps(`reps') nobs(`nobs') best_p(`p') ///
            best_kstar(`best_kstar') tau_median(0.5) ///
            timevar("`timevar'")

        _fqardl_display_bootstrap, ///
            depvar("`depvar'") indeplev("`indeplev'") ///
            levelvars("`levelvars'")

        ereturn scalar boot2_Fov_pval = r(Fov_pval)
        ereturn scalar boot2_t_pval = r(t_pval)
        ereturn scalar boot2_Find_pval = r(Find_pval)

        // Restore saved matrices to ereturn
        ereturn matrix beta = _fqardl_b_orig
        ereturn matrix beta_cov = _fqardl_bc_orig
        ereturn matrix gamma = _fqardl_g_orig
        ereturn matrix gamma_cov = _fqardl_gc_orig
        ereturn matrix rho_vec = _fqardl_r_orig
        capture ereturn matrix ssr_matrix = _fqardl_ssr_orig
        capture ereturn matrix phi = _fqardl_phi_orig
        capture ereturn matrix phi_cov = _fqardl_phic_orig
        capture ereturn matrix tau = _fqardl_tau_orig
        capture ereturn matrix bt_raw = _fqardl_btr_orig
        capture ereturn matrix fh = _fqardl_fh_orig
        capture ereturn matrix lags = _fqardl_lags_orig
        ereturn scalar p = `p'
        ereturn scalar q = `q'
        ereturn scalar k = `k'
        ereturn scalar kstar = `best_kstar'
        ereturn scalar ntau = `ntau'
        ereturn local depvar "`depvar'"
        ereturn local indepvars "`indepvars'"
        ereturn local cmd "fqardl"

        // =================================================================
        // BOOTSTRAP IRF CONFIDENCE INTERVALS (when graph requested)
        // =================================================================
        if "`graph'" != "" {
            di as txt _n
            di as txt "  Computing bootstrap IRF confidence intervals (`reps' replications)..."

            * Pure Stata bootstrap IRF computation
            local nhorizons = 5

            mat _fqardl_b_orig = e(beta)
            mat _fqardl_g_orig = e(gamma)
            mat _fqardl_r_orig = e(rho_vec)
            mat _fqardl_bc_orig = e(beta_cov)
            mat _fqardl_gc_orig = e(gamma_cov)

            local nrows_b = rowsof(_fqardl_b_orig)
            local nrows_g = rowsof(_fqardl_g_orig)

            mat _fqardl_irf_lo = J(`k' * `ntau', `nhorizons', .)
            mat _fqardl_irf_hi = J(`k' * `ntau', `nhorizons', .)
            mat _fqardl_irf_med = J(`k' * `ntau', `nhorizons', .)

            local vnum = 0
            foreach v of local indepvars {
                local ++vnum
                forvalues ti = 1/`ntau' {
                    local bidx = (`ti' - 1) * `k' + `vnum'
                    local rv_orig = _fqardl_r_orig[1, `ti']
                    local bv_orig = 0
                    local gv_orig = 0
                    if `bidx' <= `nrows_b' {
                        local bv_orig = _fqardl_b_orig[`bidx', 1]
                    }
                    if `bidx' <= `nrows_g' {
                        local gv_orig = _fqardl_g_orig[`bidx', 1]
                    }

                    local bse_val = 0
                    if `bidx' <= rowsof(_fqardl_bc_orig) & `bidx' <= colsof(_fqardl_bc_orig) {
                        if _fqardl_bc_orig[`bidx', `bidx'] > 0 {
                            local bse_val = sqrt(_fqardl_bc_orig[`bidx', `bidx']) / sqrt(`nobs' - 1)
                        }
                    }
                    local gse_val = 0
                    if `bidx' <= rowsof(_fqardl_gc_orig) & `bidx' <= colsof(_fqardl_gc_orig) {
                        if _fqardl_gc_orig[`bidx', `bidx'] > 0 {
                            local gse_val = sqrt(_fqardl_gc_orig[`bidx', `bidx']) / sqrt(`nobs' - 1)
                        }
                    }
                    local rse_val = abs(`rv_orig') * 0.1

                    local hh = 0
                    foreach hval in 0 1 5 10 20 {
                        local ++hh

                        * Generate bootstrap IRFs into matrix
                        mat _fqardl_bvec = J(`reps', 1, .)
                        forvalues bb = 1/`reps' {
                            local bv_b = `bv_orig' + cond(`bse_val'>0, `bse_val' * rnormal(), 0)
                            local gv_b = `gv_orig' + cond(`gse_val'>0, `gse_val' * rnormal(), 0)
                            local rv_b = `rv_orig' + cond(`rse_val'>0, `rse_val' * rnormal(), 0)

                            if `rv_b' < 0 {
                                local decay_b = (1 + `rv_b')^`hval'
                                local irf_b = `bv_b' + (`gv_b' - `bv_b') * `decay_b'
                                mat _fqardl_bvec[`bb', 1] = `irf_b'
                            }
                        }

                        * Sort via single mata call and extract percentiles
                        mata: st_matrix("_fqardl_bvec", sort(select(st_matrix("_fqardl_bvec"), st_matrix("_fqardl_bvec") :< .), 1))
                        local nvalid = rowsof(_fqardl_bvec)
                        if `nvalid' > 10 {
                            local lo_pos = max(ceil(0.025 * `nvalid'), 1)
                            local hi_pos = min(floor(0.975 * `nvalid'), `nvalid')
                            local med_pos = max(ceil(0.5 * `nvalid'), 1)
                            local rowidx = (`vnum' - 1) * `ntau' + `ti'
                            mat _fqardl_irf_lo[`rowidx', `hh'] = _fqardl_bvec[`lo_pos', 1]
                            mat _fqardl_irf_hi[`rowidx', `hh'] = _fqardl_bvec[`hi_pos', 1]
                            mat _fqardl_irf_med[`rowidx', `hh'] = _fqardl_bvec[`med_pos', 1]
                        }
                    }
                }
            }

            capture mat drop _fqardl_b_orig _fqardl_g_orig _fqardl_r_orig
            capture mat drop _fqardl_bc_orig _fqardl_gc_orig _fqardl_bvec

            ereturn matrix irf_lo = _fqardl_irf_lo
            ereturn matrix irf_hi = _fqardl_irf_hi
            ereturn matrix irf_med = _fqardl_irf_med

            di as txt "  Bootstrap IRF complete."

            // Display Bootstrap IRF Table
            di as txt _n
            di as txt "{hline 78}"
            di as txt "  {bf:Bootstrap IRF: Dynamic Multiplier with 95% CI}"
            di as txt "  {it:Percentile method, `reps' replications}"
            di as txt "{hline 78}"

            local vnum = 0
            foreach v of local indepvars {
                local ++vnum
                di as txt _n
                di as txt "  Shock: {bf:`v'} → {bf:`depvar'}"
                di as txt "  {hline 74}"
                di as txt _col(3) "{ralign 8:Quantile}" ///
                    _col(14) "{ralign 12:h=0}" ///
                    _col(28) "{ralign 12:h=1}" ///
                    _col(42) "{ralign 12:h=5}" ///
                    _col(56) "{ralign 12:h=10}" ///
                    _col(68) "{ralign 10:h=20}"
                di as txt "  {hline 74}"

                forvalues t = 1/`ntau' {
                    local tauval : word `t' of `tau'
                    local rowidx = (`vnum' - 1) * `ntau' + `t'

                    * Point estimate
                    local bidx = (`t' - 1) * `k' + `vnum'
                    local rv = e(rho_vec)[1, `t']
                    local bv = 0
                    local gv = 0
                    capture local bv = e(beta)[`bidx', 1]
                    capture local gv = e(gamma)[`bidx', 1]

                    di as txt _col(3) "{ralign 8:τ=" %4.2f `tauval' "}"

                    * Point estimate row
                    di as txt _col(5) "  Est" _c
                    foreach hcol in 1 2 3 4 5 {
                        local hval = cond(`hcol'==1,0,cond(`hcol'==2,1,cond(`hcol'==3,5,cond(`hcol'==4,10,20))))
                        if `rv' < 0 & `rv' != . {
                            local decay = (1 + `rv')^`hval'
                            local irf = `bv' + (`gv' - `bv') * `decay'
                            di as res _col(`= 14 + (`hcol'-1)*14') "{ralign 12:" %8.4f `irf' "}" _c
                        }
                        else {
                            di as txt _col(`= 14 + (`hcol'-1)*14') "{ralign 12:—}" _c
                        }
                    }
                    di ""

                    * CI row
                    di as txt _col(5) "  95%CI" _c
                    foreach hcol in 1 2 3 4 5 {
                        local lo_val = e(irf_lo)[`rowidx', `hcol']
                        local hi_val = e(irf_hi)[`rowidx', `hcol']
                        if `lo_val' != . & `hi_val' != . {
                            di as txt _col(`= 14 + (`hcol'-1)*14') "[" %5.3f `lo_val' "," %5.3f `hi_val' "]" _c
                        }
                        else {
                            di as txt _col(`= 14 + (`hcol'-1)*14') "{ralign 12:—}" _c
                        }
                    }
                    di ""
                }
                di as txt "  {hline 74}"
            }
        }
    }

    // =========================================================================
    // GRAPHS
    // =========================================================================
    if "`graph'" != "" {
        fqardl_graph, tau(`tau') p(`p') q(`q') k(`k') ///
            depvar("`depvar'") indepvars("`indepvars'") ///
            kstar(`best_kstar') ///
            `= cond("`ecm'"!="", "ecm", "")'

        // =================================================================
        // SUMMARY TABLES (accompany graphs)
        // =================================================================

        // --- Table 1: Speed of Adjustment & Persistence ---
        di as txt _n
        di as txt "{hline 78}"
        di as txt "  {bf:Table: Speed of Adjustment, Persistence & Half-Life}"
        di as txt "{hline 78}"
        di as txt _n
        di as txt "  {hline 74}"
        di as txt _col(3) "{ralign 10:Quantile}" ///
            _col(18) "{ralign 12:ρ(τ)}" ///
            _col(32) "{ralign 12:1+ρ(τ)}" ///
            _col(47) "{ralign 12:Half-Life}" ///
            _col(62) "{ralign 12:Convergent}"
        di as txt "  {hline 74}"

        forvalues t = 1/`ntau' {
            local tauval : word `t' of `tau'
            local rv = e(rho_vec)[1, `t']
            local persist = 1 + `rv'
            local converge = "No"
            local hl_str = "∞"

            if `rv' < 0 {
                local converge = "Yes"
                local hl = ln(2) / abs(`rv')
                if `hl' < 100 {
                    local hl_str : di %8.2f `hl'
                }
            }

            di as txt _col(3) "{ralign 10:τ=" %4.2f `tauval' "}" _c
            di as res _col(18) "{ralign 12:" %10.6f `rv' "}" _c
            di as res _col(32) "{ralign 12:" %10.6f `persist' "}" _c
            di as txt _col(47) "{ralign 12:`hl_str'}" _c
            if "`converge'" == "Yes" {
                di as res _col(62) "{ralign 12:Yes}"
            }
            else {
                di as err _col(62) "{ralign 12:No}"
            }
        }
        di as txt "  {hline 74}"
        di as txt _col(3) "{it:Half-Life = ln(2)/|ρ(τ)|  (periods to 50% adjustment)}"

        // --- Table 2: Long-Run vs Short-Run Comparison ---
        di as txt _n
        di as txt "{hline 78}"
        di as txt "  {bf:Table: Long-Run β(τ) vs Short-Run γ(τ) Comparison}"
        di as txt "{hline 78}"

        local vnum = 0
        foreach v of local indepvars {
            local ++vnum
            di as txt _n
            di as txt "  Variable: {bf:`v'}"
            di as txt "  {hline 74}"
            di as txt _col(3) "{ralign 10:Quantile}" ///
                _col(18) "{ralign 12:β(τ) [LR]}" ///
                _col(32) "{ralign 12:γ(τ) [SR]}" ///
                _col(47) "{ralign 12:LR/SR ratio}" ///
                _col(62) "{ralign 12:Adjustment}"
            di as txt "  {hline 74}"

            forvalues t = 1/`ntau' {
                local tauval : word `t' of `tau'
                local bidx = (`t' - 1) * `k' + `vnum'
                local bv = 0
                local gv = 0
                capture local bv = e(beta)[`bidx', 1]
                capture local gv = e(gamma)[`bidx', 1]

                local ratio_str = "—"
                local adj_str = "—"
                if abs(`gv') > 0.0001 {
                    local ratio = `bv' / `gv'
                    local ratio_str : di %8.3f `ratio'
                    if `ratio' > 1 {
                        local adj_str = "Amplify"
                    }
                    else if `ratio' > 0 {
                        local adj_str = "Dampen"
                    }
                    else {
                        local adj_str = "Reverse"
                    }
                }

                di as txt _col(3) "{ralign 10:τ=" %4.2f `tauval' "}" _c
                di as res _col(18) "{ralign 12:" %10.6f `bv' "}" _c
                di as res _col(32) "{ralign 12:" %10.6f `gv' "}" _c
                di as txt _col(47) "{ralign 12:`ratio_str'}" _c
                di as txt _col(62) "{ralign 12:`adj_str'}"
            }
            di as txt "  {hline 74}"
        }
        di as txt _col(3) "{it:LR/SR > 1: long-run amplification;  LR/SR < 1: long-run dampening}"

        // --- Table 3: Dynamic Multiplier (IRF) at Key Horizons ---
        di as txt _n
        di as txt "{hline 78}"
        di as txt "  {bf:Table: Dynamic Multiplier at Key Horizons}"
        di as txt "  {it:IRF(h,τ) = β(τ) + (γ(τ) - β(τ))·(1+ρ(τ))^h}"
        di as txt "{hline 78}"

        local vnum = 0
        foreach v of local indepvars {
            local ++vnum
            di as txt _n
            di as txt "  Shock to: {bf:`v'} → Response of {bf:`depvar'}"
            di as txt "  {hline 74}"
            di as txt _col(3) "{ralign 10:Quantile}" ///
                _col(15) "{ralign 10:h=0}" ///
                _col(27) "{ralign 10:h=1}" ///
                _col(39) "{ralign 10:h=5}" ///
                _col(51) "{ralign 10:h=10}" ///
                _col(63) "{ralign 10:h=20 (LR)}"
            di as txt "  {hline 74}"

            forvalues t = 1/`ntau' {
                local tauval : word `t' of `tau'
                local bidx = (`t' - 1) * `k' + `vnum'
                local rv = e(rho_vec)[1, `t']
                local bv = 0
                local gv = 0
                capture local bv = e(beta)[`bidx', 1]
                capture local gv = e(gamma)[`bidx', 1]

                di as txt _col(3) "{ralign 10:τ=" %4.2f `tauval' "}" _c

                if `rv' < 0 & `rv' != . {
                    foreach hh in 0 1 5 10 20 {
                        local decay = (1 + `rv')^`hh'
                        local irf = `bv' + (`gv' - `bv') * `decay'
                        di as res _col(`= 15 + 12 * (cond(`hh'==0,0,cond(`hh'==1,1,cond(`hh'==5,2,cond(`hh'==10,3,4)))))') ///
                            "{ralign 10:" %8.4f `irf' "}" _c
                    }
                    di ""
                }
                else {
                    di as txt "    (non-convergent)"
                }
            }
            di as txt "  {hline 74}"
        }
        di as txt _col(3) "{it:h=0: contemporaneous impact;  h→∞: long-run equilibrium}"
    }

    restore

    // Footer
    di as txt ""
    di as txt "{hline 78}"
    di as txt _col(3) "{it:Estimation: Quantile Regression via IRLS}"
    if "`nofourier'" == "" {
        di as txt _col(3) "{it:Fourier flexible form with k* = `best_kstar'}"
    }
    if "`type'" == "fbqardl" {
        di as txt _col(3) "{it:Bootstrap cointegration test (`reps' replications)}"
    }
    di as txt "{hline 78}"
end


* ============================================================
* DISPLAY: ardl-style with ADJ / LR / SR sections
* ============================================================
capture program drop _fqardl_display_full
program define _fqardl_display_full
    args beta beta_cov phi phi_cov gamma gamma_cov ///
         tau_vec p q k nobs depvar indepvars is_ecm kstar bt_raw bt_se

    local ntau = rowsof(`tau_vec')

    // =========================================================================
    // Model Summary Table (like ardl Table 1)
    // =========================================================================
    di as txt "{hline 78}"
    if `is_ecm' {
        di as res _col(3) "FQARDL(`p',`q') regression, EC representation"
    }
    else {
        di as res _col(3) "FQARDL(`p',`q') regression"
    }
    di as txt "{hline 78}"
    di as txt _col(3) "Quantile regression (IRLS)" ///
       _col(45) "Number of obs  = " as res %8.0f `nobs'
    di as txt _col(3) "Dep. var: D.`depvar'" ///
       _col(45) "Fourier k*     = " as res %8.1f `kstar'
    di as txt _col(3) "No. of quantiles: " as res `ntau' ///
       as txt _col(45) "No. of x-vars  = " as res %8.0f `k'
    di as txt "{hline 78}"

    // =========================================================================
    // Loop over quantiles, display ADJ / LR / SR blocks for each tau
    // =========================================================================
    forvalues t = 1/`ntau' {
        local tauval = `tau_vec'[`t', 1]

        di as txt ""
        di as txt "{hline 78}"
        di as res _col(3) "Quantile: tau = " %5.2f `tauval'
        di as txt "{hline 78}"
        di as txt _col(3) "{ralign 18:Variable}" ///
           _col(25) "{ralign 12:Coef.}" ///
           _col(39) "{ralign 10:Std.Err.}" ///
           _col(51) "{ralign 8:t-stat}" ///
           _col(61) "{ralign 8:p-value}" ///
           _col(72) ""
        di as txt "  {hline 74}"

        // -----------------------------------------------------------
        // ADJ — Speed of Adjustment (sum of phi - 1)
        // rho(tau) = sum(phi_i(tau)) - 1
        // -----------------------------------------------------------
        di as txt "  {bf:ADJ}"

        local sum_phi = 0
        forvalues j = 1/`p' {
            local phi_idx = (`t' - 1) * `p' + `j'
            local phi_rows = rowsof(`phi')
            if `phi_idx' <= `phi_rows' {
                local sum_phi = `sum_phi' + `phi'[`phi_idx', 1]
            }
        }
        local rho = `sum_phi' - 1

        // Display rho = speed of adjustment (SE via raw QR)
        // rho comes from sum of phi coefficients in raw bt
        // phi positions in bt: rows 2+(q+1)*k to 1+(q+1)*k+p
        local phi_start = 2 + (`q'+1)*`k'
        local phi_end = 1 + (`q'+1)*`k' + `p'
        local rho_se = 0
        forvalues j = `phi_start'/`phi_end' {
            local bt_se_rows = rowsof(`bt_se')
            if `j' <= `bt_se_rows' {
                local rho_se = `rho_se' + (`bt_se'[`j', `t'])^2
            }
        }
        local rho_se = sqrt(`rho_se')
        if `rho_se' > 0 {
            local rho_t = `rho' / `rho_se'
            local rho_pv = 2*(1 - normal(abs(`rho_t')))
        }
        else {
            local rho_t = .
            local rho_pv = .
        }

        di as txt _col(3) "{ralign 18:L.`depvar'}" _c
        di as res _col(25) "{ralign 12:" %10.6f `rho' "}" _c
        if `rho_se' > 0 {
            di as txt _col(39) "{ralign 10:" %8.6f `rho_se' "}" _c
            di as txt _col(51) "{ralign 8:" %7.3f `rho_t' "}" _c
            _fqardl_pval_display `rho_pv'
        }
        else {
            di as txt _col(39) "{ralign 10:    —}" _c
            di as txt _col(51) "{ralign 8:    —}" _c
            di as txt _col(61) "{ralign 8:    —}"
        }

        di as txt "  {hline 74}"

        // -----------------------------------------------------------
        // LR — Long-Run Coefficients: beta(tau)
        // beta_j(tau) = gamma_j(tau) / (1 - sum(phi_i(tau)))
        // -----------------------------------------------------------
        di as txt "  {bf:LR}"

        local vnum = 0
        foreach v of local indepvars {
            local ++vnum
            local beta_idx = (`t' - 1) * `k' + `vnum'
            local beta_rows = rowsof(`beta')
            if `beta_idx' <= `beta_rows' {
                local est = `beta'[`beta_idx', 1]
                local var_val = `beta_cov'[`beta_idx', `beta_idx']
                if `var_val' > 0 {
                    local se = sqrt(`var_val') / sqrt(`nobs' - 1)
                }
                else local se = .

                if `se' != . & `se' > 0 {
                    local tstat = `est' / `se'
                    local pval = 2*(1 - normal(abs(`tstat')))
                }
                else {
                    local tstat = .
                    local pval = .
                }

                di as txt _col(3) "{ralign 18:`v'}" _c
                di as res _col(25) "{ralign 12:" %10.6f `est' "}" _c
                if `se' != . {
                    di as txt _col(39) "{ralign 10:" %8.6f `se' "}" _c
                    di as txt _col(51) "{ralign 8:" %7.3f `tstat' "}" _c
                    _fqardl_pval_display `pval'
                }
                else {
                    di as txt _col(39) "     ." _col(51) "     ." _col(61) "     ."
                }
            }
        }
        di as txt "  {hline 74}"

        // -----------------------------------------------------------
        // SR — Short-Run Coefficients
        // phi_i(tau): AR lags of D.y  (notation: L1D.depvar, L2D.depvar, ...)
        // gamma_j(tau): impact of x   (notation: D.xvar)
        // -----------------------------------------------------------
        di as txt "  {bf:SR}"

        // phi: lagged differences of depvar
        forvalues j = 1/`p' {
            local phi_idx = (`t' - 1) * `p' + `j'
            local phi_rows = rowsof(`phi')
            if `phi_idx' <= `phi_rows' {
                local est = `phi'[`phi_idx', 1]
                local var_val = `phi_cov'[`phi_idx', `phi_idx']
                if `var_val' > 0 {
                    local se = sqrt(`var_val') / sqrt(`nobs' - 1)
                }
                else {
                    // Fallback to raw QR SE
                    local bt_row = 2 + (`q'+1)*`k' + `j' - 1
                    local bt_se_rows = rowsof(`bt_se')
                    if `bt_row' <= `bt_se_rows' & `t' <= colsof(`bt_se') {
                        local se = `bt_se'[`bt_row', `t']
                    }
                    else local se = .
                }

                if `se' != . & `se' > 0 {
                    local tstat = `est' / `se'
                    local pval = 2*(1 - normal(abs(`tstat')))
                }
                else {
                    local tstat = .
                    local pval = .
                }

                di as txt _col(3) "{ralign 18:L`j'D.`depvar'}" _c
                di as res _col(25) "{ralign 12:" %10.6f `est' "}" _c
                if `se' != . {
                    di as txt _col(39) "{ralign 10:" %8.6f `se' "}" _c
                    di as txt _col(51) "{ralign 8:" %7.3f `tstat' "}" _c
                    _fqardl_pval_display `pval'
                }
                else {
                    di as txt _col(39) "     ." _col(51) "     ." _col(61) "     ."
                }
            }
        }

        // gamma: short-run impact of indepvars (D.xvar notation)
        local vnum = 0
        foreach v of local indepvars {
            local ++vnum
            local gamma_idx = (`t' - 1) * `k' + `vnum'
            local gamma_rows = rowsof(`gamma')
            if `gamma_idx' <= `gamma_rows' {
                local est = `gamma'[`gamma_idx', 1]
                local var_val = `gamma_cov'[`gamma_idx', `gamma_idx']
                if `var_val' > 0 {
                    local se = sqrt(`var_val') / sqrt(`nobs' - 1)
                }
                else {
                    // Fallback to raw QR SE
                    // gamma position in bt: row 2 + (vnum-1) + q*k
                    local bt_row = 2 + (`vnum' - 1) + `q'*`k'
                    local bt_se_rows = rowsof(`bt_se')
                    if `bt_row' <= `bt_se_rows' & `t' <= colsof(`bt_se') {
                        local se = `bt_se'[`bt_row', `t']
                    }
                    else local se = .
                }

                if `se' != . & `se' > 0 {
                    local tstat = `est' / `se'
                    local pval = 2*(1 - normal(abs(`tstat')))
                }
                else {
                    local tstat = .
                    local pval = .
                }

                di as txt _col(3) "{ralign 18:D.`v'}" _c
                di as res _col(25) "{ralign 12:" %10.6f `est' "}" _c
                if `se' != . {
                    di as txt _col(39) "{ralign 10:" %8.6f `se' "}" _c
                    di as txt _col(51) "{ralign 8:" %7.3f `tstat' "}" _c
                    _fqardl_pval_display `pval'
                }
                else {
                    di as txt _col(39) "     ." _col(51) "     ." _col(61) "     ."
                }
            }
        }

        // Fourier terms with SEs (from raw coefficients and raw SEs)
        if `kstar' > 0 {
            local bt_rows = rowsof(`bt_raw')
            local bt_cols = colsof(`bt_raw')
            if `t' <= `bt_cols' {
                // sin at bt_rows - 1, cos at bt_rows
                local sin_est = `bt_raw'[`bt_rows' - 1, `t']
                local cos_est = `bt_raw'[`bt_rows', `t']
                local sin_se = `bt_se'[`bt_rows' - 1, `t']
                local cos_se = `bt_se'[`bt_rows', `t']

                // sin
                local sin_t = `sin_est' / `sin_se'
                local sin_pv = 2*(1 - normal(abs(`sin_t')))
                di as txt _col(3) "{ralign 18:sin(2pi*k*/T)}" _c
                di as res _col(25) "{ralign 12:" %10.6f `sin_est' "}" _c
                di as txt _col(39) "{ralign 10:" %8.6f `sin_se' "}" _c
                di as txt _col(51) "{ralign 8:" %7.3f `sin_t' "}" _c
                _fqardl_pval_display `sin_pv'

                // cos
                local cos_t = `cos_est' / `cos_se'
                local cos_pv = 2*(1 - normal(abs(`cos_t')))
                di as txt _col(3) "{ralign 18:cos(2pi*k*/T)}" _c
                di as res _col(25) "{ralign 12:" %10.6f `cos_est' "}" _c
                di as txt _col(39) "{ralign 10:" %8.6f `cos_se' "}" _c
                di as txt _col(51) "{ralign 8:" %7.3f `cos_t' "}" _c
                _fqardl_pval_display `cos_pv'
            }
        }

        di as txt "  {hline 74}"
    }

    di as txt _col(3) "{it:*** p<0.01  ** p<0.05  * p<0.10}"
    di as txt _col(3) "{it:Long-run: beta = gamma / (1 - sum(phi))}"
    di as txt ""
end

* ============================================================
* Display ECM-specific results (ardl-style)
* ============================================================
capture program drop _fqardl_display_ecm
program define _fqardl_display_ecm
    args phi_ecm phi_ecm_cov theta theta_cov tau_vec p q k nobs indepvars depvar

    local ntau = rowsof(`tau_vec')
    local pp1 = `p' - 1
    if `pp1' < 1 local pp1 = 1

    di as txt ""
    di as txt "{hline 78}"
    di as res _col(3) "ECM Reparameterization"
    di as txt "{hline 78}"

    forvalues t = 1/`ntau' {
        local tauval = `tau_vec'[`t', 1]

        di as txt ""
        di as txt _col(3) "{hline 4} tau = " %5.2f `tauval' " {hline 59}"
        di as txt _col(3) "{ralign 18:Variable}" ///
           _col(25) "{ralign 12:Coef.}" ///
           _col(39) "{ralign 10:Std.Err.}" ///
           _col(51) "{ralign 8:t-stat}" ///
           _col(61) "{ralign 8:p-value}"
        di as txt "  {hline 74}"

        // phi* (cumulative AR in ECM)
        di as txt "  {bf:ECM-AR}"
        local phi_rows = rowsof(`phi_ecm')
        forvalues j = 1/`pp1' {
            local idx = (`t' - 1) * `pp1' + `j'
            if `idx' <= `phi_rows' {
                local est = `phi_ecm'[`idx', 1]
                local var_val = `phi_ecm_cov'[`idx', `idx']
                if `var_val' > 0 {
                    local se = sqrt(`var_val') / sqrt(`nobs' - 1)
                }
                else local se = .
                if `se' != . & `se' > 0 {
                    local tstat = `est' / `se'
                    local pval = 2*(1 - normal(abs(`tstat')))
                }
                else {
                    local tstat = .
                    local pval = .
                }
                di as txt _col(3) "{ralign 18:phi*_`j'(tau)}" _c
                di as res _col(25) "{ralign 12:" %10.6f `est' "}" _c
                if `se' != . {
                    di as txt _col(39) "{ralign 10:" %8.6f `se' "}" _c
                    di as txt _col(51) "{ralign 8:" %7.3f `tstat' "}" _c
                    _fqardl_pval_display `pval'
                }
                else {
                    di as txt "     .     .     ."
                }
            }
        }

        // theta (short-run impact in ECM: coefficients on D.x)
        di as txt "  {bf:ECM-SR}"
        local theta_rows = rowsof(`theta')
        local qk = `q' * `k'
        forvalues lag = 0/`= `q' - 1' {
            foreach v of local indepvars {
                local idx_t = (`t' - 1) * `qk' + `lag' * `k'
                local vnum = 0
                foreach v2 of local indepvars {
                    local ++vnum
                    if "`v'" == "`v2'" {
                        local idx_t = `idx_t' + `vnum'
                    }
                }
                if `idx_t' <= `theta_rows' {
                    local est = `theta'[`idx_t', 1]
                    local var_val = `theta_cov'[`idx_t', `idx_t']
                    if `var_val' > 0 {
                        local se = sqrt(`var_val') / sqrt(`nobs' - 1)
                    }
                    else local se = .
                    if `se' != . & `se' > 0 {
                        local tstat = `est' / `se'
                        local pval = 2*(1 - normal(abs(`tstat')))
                    }
                    else {
                        local tstat = .
                        local pval = .
                    }
                    if `lag' == 0 {
                        local vlab "D.`v'"
                    }
                    else {
                        local vlab "L`lag'D.`v'"
                    }
                    di as txt _col(3) "{ralign 18:`vlab'}" _c
                    di as res _col(25) "{ralign 12:" %10.6f `est' "}" _c
                    if `se' != . {
                        di as txt _col(39) "{ralign 10:" %8.6f `se' "}" _c
                        di as txt _col(51) "{ralign 8:" %7.3f `tstat' "}" _c
                        _fqardl_pval_display `pval'
                    }
                    else {
                        di as txt "     .     .     ."
                    }
                }
            }
        }
        di as txt "  {hline 74}"
    }
    di as txt _col(3) "{it:*** p<0.01  ** p<0.05  * p<0.10}"
end

* ============================================================
* Display bootstrap results
* ============================================================
capture program drop _fqardl_display_bootstrap
program define _fqardl_display_bootstrap
    syntax, DEPVAR(string) INDEPLEV(string) LEVELVARS(string)

    di as txt ""
    di as txt "{hline 78}"
    di as res _col(3) "Bootstrap Cointegration Test Results"
    di as txt "{hline 78}"
    di as txt ""
    di as txt "  {hline 74}"
    di as txt _col(5) "{ralign 18:Test}" ///
       _col(36) "{ralign 8:1% CV}" ///
       _col(46) "{ralign 8:5% CV}" ///
       _col(56) "{ralign 8:10% CV}" ///
       _col(66) "{ralign 10:p-value}"
    di as txt "  {hline 74}"

    local Fov_pval = r(Fov_pval)
    local Fov_cv01 = r(Fov_cv01)
    local Fov_cv05 = r(Fov_cv05)
    local Fov_cv10 = r(Fov_cv10)

    di as txt _col(5) "{ralign 18:F_overall}" _c
    di as res _col(36) "{ralign 8:" %7.3f `Fov_cv01' "}" _c
    di as res _col(46) "{ralign 8:" %7.3f `Fov_cv05' "}" _c
    di as res _col(56) "{ralign 8:" %7.3f `Fov_cv10' "}" _c
    if `Fov_pval' < 0.05 {
        di as err _col(66) "{ralign 10:" %8.4f `Fov_pval' "}"
    }
    else {
        di as txt _col(66) "{ralign 10:" %8.4f `Fov_pval' "}"
    }

    local t_pval = r(t_pval)
    local t_cv01 = r(t_cv01)
    local t_cv05 = r(t_cv05)
    local t_cv10 = r(t_cv10)

    di as txt _col(5) "{ralign 18:t_dependent}" _c
    di as res _col(36) "{ralign 8:" %7.3f `t_cv01' "}" _c
    di as res _col(46) "{ralign 8:" %7.3f `t_cv05' "}" _c
    di as res _col(56) "{ralign 8:" %7.3f `t_cv10' "}" _c
    if `t_pval' < 0.05 {
        di as err _col(66) "{ralign 10:" %8.4f `t_pval' "}"
    }
    else {
        di as txt _col(66) "{ralign 10:" %8.4f `t_pval' "}"
    }

    local Find_pval = r(Find_pval)
    local Find_cv01 = r(Find_cv01)
    local Find_cv05 = r(Find_cv05)
    local Find_cv10 = r(Find_cv10)

    di as txt _col(5) "{ralign 18:F_independent}" _c
    di as res _col(36) "{ralign 8:" %7.3f `Find_cv01' "}" _c
    di as res _col(46) "{ralign 8:" %7.3f `Find_cv05' "}" _c
    di as res _col(56) "{ralign 8:" %7.3f `Find_cv10' "}" _c
    if `Find_pval' < 0.05 {
        di as err _col(66) "{ralign 10:" %8.4f `Find_pval' "}"
    }
    else {
        di as txt _col(66) "{ralign 10:" %8.4f `Find_pval' "}"
    }

    di as txt "  {hline 74}"

    local all_reject = (`Fov_pval' < 0.05) & (`t_pval' < 0.05) & (`Find_pval' < 0.05)
    di as txt ""
    if `all_reject' {
        di as res _col(5) "Conclusion: Evidence of COINTEGRATION"
        di as txt _col(5) "(All three tests reject at 5%)"
    }
    else {
        di as txt _col(5) "Conclusion: Inconclusive / No cointegration"
        di as txt _col(5) "(Not all tests reject at 5%)"
    }
    di as txt ""
end

* ============================================================
* P-value display helper with stars
* ============================================================
capture program drop _fqardl_pval_display
program define _fqardl_pval_display
    args pval
    if `pval' < 0.01 {
        di as err _col(61) "{ralign 8:" %6.4f `pval' "}" " ***"
    }
    else if `pval' < 0.05 {
        di as res _col(61) "{ralign 8:" %6.4f `pval' "}" "  **"
    }
    else if `pval' < 0.10 {
        di as txt _col(61) "{ralign 8:" %6.4f `pval' "}" "   *"
    }
    else {
        di as txt _col(61) "{ralign 8:" %6.4f `pval' "}"
    }
end

* ============================================================
* Fourier k* selection helper (for qcoint)
* ============================================================
capture program drop _fqardl_select_kstar
program define _fqardl_select_kstar, rclass
    syntax varlist [if] [in], MAXK(real) MAXLAG(integer) ///
        TAU(numlist) TIMEVAR(string) [NOFourier]

    marksample touse
    gettoken depvar indepvars : varlist

    qui count if `touse'
    local T = r(N)

    tempvar ttrend
    qui gen `ttrend' = _n if `touse'

    local nkgrid = round(`maxk' / 0.1)
    tempname best_ssr_k
    scalar `best_ssr_k' = .
    local best_kstar = 0

    forvalues kidx = 1/`nkgrid' {
        local kval = `kidx' * 0.1

        capture drop _fqardl_sin _fqardl_cos
        if `kval' > 0 {
            qui gen double _fqardl_sin = sin(2*c(pi)*`kval'*`ttrend'/`T') if `touse'
            qui gen double _fqardl_cos = cos(2*c(pi)*`kval'*`ttrend'/`T') if `touse'
        }

        local regvars "L.`depvar'"
        foreach xvar of local indepvars {
            local regvars "`regvars' L.`xvar'"
        }
        forvalues j = 1/`maxlag' {
            local regvars "`regvars' L`j'D.`depvar'"
        }
        foreach xvar of local indepvars {
            local regvars "`regvars' D.`xvar'"
            forvalues j = 1/`maxlag' {
                local regvars "`regvars' L`j'D.`xvar'"
            }
        }
        if `kval' > 0 {
            local regvars "`regvars' _fqardl_sin _fqardl_cos"
        }

        capture qui regress D.`depvar' `regvars' if `touse'
        if _rc == 0 {
            local this_ssr = e(rss)
        }
        else {
            local this_ssr = .
        }

        if `this_ssr' < scalar(`best_ssr_k') | missing(scalar(`best_ssr_k')) {
            scalar `best_ssr_k' = `this_ssr'
            local best_kstar = `kval'
        }
    }

    capture drop _fqardl_sin _fqardl_cos
    return scalar kstar = `best_kstar'
    return scalar ssr = scalar(`best_ssr_k')
end
