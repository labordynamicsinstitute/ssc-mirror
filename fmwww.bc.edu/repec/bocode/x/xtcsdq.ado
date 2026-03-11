*! xtcsdq v1.3.0  07mar2026  Dr Merwan Roudane  merwanroudane920@gmail.com
*! Tests of No Cross-Sectional Error Dependence in Panel Quantile Regressions
*! Based on: Demetrescu, Hosseinkouchack & Rodrigues (2023)
*! Ruhr Economic Papers #1041
*! References: xtpqardl, xtcspqardl, mmqreg, xtqreg, qregpd
*!
*! Three modes of operation:
*!   Mode 1: xtcsdq depvar indepvars, quantiles(...)           — internal QR
*!   Mode 2: xtcsdq, residuals(resid_vars) quantiles(...)      — external residuals
*!   Mode 3: xtcsdq, post quantiles(...)                       — post-estimation
*!           Reads e() from: xtpqardl, xtcspqardl, mmqreg,
*!           xtqreg, qregpd, qreg, ivqreg, or any panel QR command

program define xtcsdq, rclass
    version 14.0
    
    // ──────────────────────────────────────────────────────────────────────
    //  Parse syntax
    // ──────────────────────────────────────────────────────────────────────
    syntax [anything(equalok)] [if] [in], ///
        Quantiles(numlist min=1 >0 <1 sort) ///
        [Individual Bandwidth(real 0) NOCorrection ///
         Residuals(string) POST]
    
    // ──────────────────────────────────────────────────────────────────────
    //  Determine mode
    // ──────────────────────────────────────────────────────────────────────
    local use_external_resid = 0
    local use_post = 0
    local varlist "`anything'"
    
    // Check for conflicting options
    local nmodes = ("`residuals'" != "") + ("`post'" != "") + ("`varlist'" != "")
    if `nmodes' > 1 {
        di as error "specify only one of: varlist, residuals(), or post"
        di as error "  Mode 1: xtcsdq depvar indepvars, quantiles(...)"
        di as error "  Mode 2: xtcsdq, residuals(resid_vars) quantiles(...)"
        di as error "  Mode 3: xtcsdq, post quantiles(...)"
        exit 198
    }
    
    if `nmodes' == 0 {
        di as error "must specify one of: varlist, residuals(), or post"
        di as error "  Mode 1: xtcsdq depvar indepvars, quantiles(...)"
        di as error "  Mode 2: xtcsdq, residuals(resid_vars) quantiles(...)"
        di as error "  Mode 3: xtcsdq, post quantiles(...) — after a panel QR command"
        exit 198
    }
    
    if "`residuals'" != "" {
        // ── Mode 2: External residuals ──
        local use_external_resid = 1
        
        foreach v of local residuals {
            confirm numeric variable `v'
        }
        
        local n_resid_vars = 0
        foreach v of local residuals {
            local n_resid_vars = `n_resid_vars' + 1
        }
        
        local K = 0
        foreach tau of local quantiles {
            local K = `K' + 1
        }
        
        if `n_resid_vars' != `K' {
            di as error "number of residual variables (`n_resid_vars') must equal " ///
                "number of quantiles (`K')"
            exit 198
        }
    }
    else if "`post'" != "" {
        // ── Mode 3: Post-estimation ──
        local use_post = 1
        
        * Detect the previous estimation command
        local prev_cmd "`e(cmd)'"
        if "`prev_cmd'" == "" {
            di as error "no estimation results found; run a panel QR command first"
            exit 301
        }
        
        * Read estimation info from e()
        local post_depvar "`e(depvar)'"
        if "`post_depvar'" == "" {
            di as error "previous command did not store e(depvar)"
            exit 198
        }
        
        * Try to read panel variables
        local post_ivar "`e(ivar)'"
        local post_tvar "`e(tvar)'"
        
        di as txt ""
        di as txt "  Post-estimation mode: detected {bf:`prev_cmd'}"
        di as txt "  Dependent variable: `post_depvar'"
    }
    else {
        // ── Mode 1: Internal QR estimation ──
        unab varlist : `varlist'
        
        local nvar : word count `varlist'
        if `nvar' < 2 {
            di as error "varlist must contain at least a dependent variable and one regressor"
            exit 198
        }
        
        gettoken depvar indepvars : varlist
    }
    
    // ──────────────────────────────────────────────────────────────────────
    //  Panel structure
    // ──────────────────────────────────────────────────────────────────────
    qui xtset
    local ivar "`r(panelvar)'"
    local tvar "`r(timevar)'"
    if "`ivar'" == "" | "`tvar'" == "" {
        di as error "panel variable and time variable must be set; use {cmd:xtset}"
        exit 459
    }
    
    // Mark the estimation sample
    marksample touse, novarlist
    if `use_external_resid' {
        markout `touse' `residuals'
    }
    else if `use_post' {
        * Use the e(sample) if available
        capture confirm variable __e_sample__
        if _rc == 0 {
            markout `touse' __e_sample__
        }
    }
    else {
        markout `touse' `varlist'
    }
    
    preserve
    qui keep if `touse'
    
    // ──────────────────────────────────────────────────────────────────────
    //  Compute N, T and check balance
    // ──────────────────────────────────────────────────────────────────────
    tempvar group Ti
    qui egen `group' = group(`ivar')
    qui su `group', meanonly
    local N = r(max)
    
    if `N' < 2 {
        di as error "at least 2 cross-sectional units required"
        exit 198
    }
    
    qui by `ivar': gen long `Ti' = _N if _n == _N
    qui su `Ti', meanonly
    local Tmin = r(min)
    local Tmax = r(max)
    
    if `Tmin' != `Tmax' {
        di as error "panel must be balanced; found T ranging from `Tmin' to `Tmax'"
        exit 198
    }
    local T = `Tmin'
    
    if `T' < 3 {
        di as error "at least 3 time periods required"
        exit 198
    }
    
    sort `ivar' `tvar'
    
    // ──────────────────────────────────────────────────────────────────────
    //  Determine quantile count
    // ──────────────────────────────────────────────────────────────────────
    local K = 0
    foreach tau of local quantiles {
        local K = `K' + 1
    }
    
    // Set default bandwidth: 0.35*(N*T)^(-0.2)
    local bw_default = 0.35 * (`N' * `T')^(-0.2)
    if `bandwidth' <= 0 {
        local bw_used = `bw_default'
    }
    else {
        local bw_used = `bandwidth'
    }
    
    // ──────────────────────────────────────────────────────────────────────
    //  Post-estimation: generate residuals from previous QR model
    // ──────────────────────────────────────────────────────────────────────
    if `use_post' {
        local use_external_resid = 1
        local residuals ""
        
        * ──────────────────────────────────────────────
        * Detect model type and build regressor list ONCE (before loop)
        * (per-panel qreg inside the loop would overwrite e())
        * ──────────────────────────────────────────────
        if "`prev_cmd'" == "xtpqardl" | "`prev_cmd'" == "xtcspqardl" {
            local post_indep "`e(indepvars)'"
            local post_lr ""
            capture local post_lr "`e(lrvars)'"
            local post_lr_y ""
            capture local post_lr_y "`e(lr_y)'"
            
            local post_regressors "`post_indep'"
            if "`post_lr_y'" != "" {
                local post_regressors "`post_regressors' `post_lr_y'"
            }
            if "`post_lr'" != "" {
                local post_regressors "`post_regressors' `post_lr'"
            }
        }
        else {
            local post_indep ""
            capture local post_indep "`e(indepvars)'"
            if "`post_indep'" == "" {
                capture {
                    tempname post_b
                    matrix `post_b' = e(b)
                    local post_indep : colnames `post_b'
                    local post_indep : subinstr local post_indep "_cons" "", all
                    local post_indep = strtrim("`post_indep'")
                }
            }
            local post_regressors "`post_indep'"
        }
        
        if "`post_regressors'" == "" {
            di as error "  Cannot determine regressors from e() results"
            di as error "  Use residuals() option instead to provide residuals manually"
            exit 198
        }
        
        local k_idx = 0
        foreach tau of local quantiles {
            local k_idx = `k_idx' + 1
            
            di as txt "  Generating residuals at tau = `tau' via per-panel QR..."
            
            * Generate residual variable for this quantile
            qui gen double __xtcsdq_resid_`k_idx' = .
            
            * Run per-panel QR to generate residuals
            local _post_nfail = 0
            qui levelsof `group', local(units)
            foreach g of local units {
                capture qui qreg `post_depvar' `post_regressors' ///
                    if `group' == `g', quantile(`tau') vce(robust)
                if _rc == 0 {
                    qui predict double __xtcsdq_tmp if `group' == `g', residuals
                    qui replace __xtcsdq_resid_`k_idx' = __xtcsdq_tmp if `group' == `g'
                    capture qui drop __xtcsdq_tmp
                }
                else {
                    * If full model fails, try simpler specification
                    capture qui qreg `post_depvar' `post_indep' ///
                        if `group' == `g', quantile(`tau') vce(robust)
                    if _rc == 0 {
                        qui predict double __xtcsdq_tmp if `group' == `g', residuals
                        qui replace __xtcsdq_resid_`k_idx' = __xtcsdq_tmp if `group' == `g'
                        capture qui drop __xtcsdq_tmp
                    }
                    else {
                        local _post_nfail = `_post_nfail' + 1
                    }
                }
            }
            if `_post_nfail' > 0 {
                di as error "  Warning: QR failed for `_post_nfail' of `N' units at tau=`tau' (T=`T' too small)"
                if `_post_nfail' == `N' {
                    di as error "  All units failed. Use pooled mode: xtcsdq depvar indepvars, quantiles(...)"
                }
            }
            
            local residuals "`residuals' __xtcsdq_resid_`k_idx'"
        }
        local residuals = strtrim("`residuals'")
    }
    
    // ──────────────────────────────────────────────────────────────────────
    //  Estimation type label
    // ──────────────────────────────────────────────────────────────────────
    if `use_post' {
        local est_type "Post-estimation (`prev_cmd')"
    }
    else if `use_external_resid' {
        local est_type "External residuals"
    }
    else if "`individual'" != "" {
        local est_type "Individual-unit"
    }
    else {
        local est_type "Pooled fixed-effects"
    }
    
    // ──────────────────────────────────────────────────────────────────────
    //  Display header
    // ──────────────────────────────────────────────────────────────────────
    di ""
    di as txt "{hline 70}"
    di as txt "  {bf:XTCSDQ} — CSD Test in Panel Quantile Regressions"
    di as txt "{hline 70}"
    di as txt "  Estimation:  " as res "`est_type' QR"
    di as txt "  N (units):   " as res `N'
    di as txt "  T (periods): " as res `T'
    di as txt "  Quantiles:   " as res "`quantiles'"
    di as txt "  KDE bandw.:  " as res %9.6f `bw_used'
    di as txt "{hline 70}"
    
    // ──────────────────────────────────────────────────────────────────────
    //  Create result matrices
    // ──────────────────────────────────────────────────────────────────────
    tempname mat_T mat_Ttilde mat_pval mat_pval_c mat_fhat
    mat `mat_T'      = J(`K', 1, .)
    mat `mat_Ttilde'  = J(`K', 1, .)
    mat `mat_pval'   = J(`K', 1, .)
    mat `mat_pval_c' = J(`K', 1, .)
    mat `mat_fhat'   = J(`K', 1, .)
    
    local sum_Ttilde = 0
    local sum_T      = 0
    local k_idx = 0
    
    // Build list of external residual variables
    if `use_external_resid' {
        local resid_list ""
        foreach v of local residuals {
            local resid_list "`resid_list' `v'"
        }
    }
    
    // ──────────────────────────────────────────────────────────────────────
    //  Loop over quantiles
    // ──────────────────────────────────────────────────────────────────────
    foreach tau of local quantiles {
        local k_idx = `k_idx' + 1
        
        di as txt ""
        di as txt "  Computing test at quantile tau = " as res `tau' as txt " ..."
        
        // ─── Step 1: Get residuals ───
        tempvar resid_`k_idx'
        
        if `use_external_resid' {
            local ext_resid_var : word `k_idx' of `resid_list'
            qui gen double `resid_`k_idx'' = `ext_resid_var'
        }
        else if "`individual'" != "" {
            qui gen double `resid_`k_idx'' = .
            local _ind_nfail = 0
            qui levelsof `group', local(units)
            foreach g of local units {
                capture qui qreg `depvar' `indepvars' ///
                    if `group' == `g', quantile(`tau') vce(robust)
                if _rc != 0 {
                    local _ind_nfail = `_ind_nfail' + 1
                    continue
                }
                qui predict double __tmpres if `group' == `g', residuals
                qui replace `resid_`k_idx'' = __tmpres if `group' == `g'
                qui drop __tmpres
            }
            if `_ind_nfail' > 0 {
                di as error "  Warning: QR failed for `_ind_nfail' of `N' units at tau=`tau' (T=`T' too small)"
                if `_ind_nfail' == `N' {
                    di as error "  All units failed. Use pooled mode instead (remove 'individual' option)"
                }
            }
        }
        else {
            qui tab `group', gen(__fe_d)
            qui ds __fe_d*
            local fe_vars "`r(varlist)'"
            gettoken first_fe rest_fe : fe_vars
            qui qreg `depvar' `indepvars' `rest_fe', quantile(`tau') vce(robust)
            qui predict double `resid_`k_idx'', residuals
            qui drop __fe_d*
        }
        
        // ─── Step 2: Demean residuals unit-by-unit ───
        tempvar resid_mean_`k_idx' resid_dm_`k_idx'
        qui bysort `group': egen double `resid_mean_`k_idx'' = mean(`resid_`k_idx'')
        qui gen double `resid_dm_`k_idx'' = `resid_`k_idx'' - `resid_mean_`k_idx''
        
        // ─── Step 3: Unit-specific sigma ───
        tempvar resid_dm_sq_`k_idx' sigma_i_`k_idx'
        qui gen double `resid_dm_sq_`k_idx'' = `resid_dm_`k_idx''^2
        qui bysort `group': egen double `sigma_i_`k_idx'' = mean(`resid_dm_sq_`k_idx'')
        qui replace `sigma_i_`k_idx'' = sqrt(`sigma_i_`k_idx'')
        
        // ─── Step 4: Standardize RAW residuals for KDE ───
        tempvar std_resid_`k_idx'
        qui gen double `std_resid_`k_idx'' = `resid_`k_idx'' / `sigma_i_`k_idx''
        
        // ─── Step 5: KDE of f(q_tau) at zero ───
        tempvar kde_contrib_`k_idx'
        local h = `bw_used'
        qui gen double `kde_contrib_`k_idx'' = ///
            (1 / sqrt(2 * _pi)) * exp(-0.5 * (`std_resid_`k_idx'' / `h')^2)
        qui su `kde_contrib_`k_idx'', meanonly
        local fhat_val = r(sum) / ((`N' * `T') * `h')
        mat `mat_fhat'[`k_idx', 1] = `fhat_val'
        
        // ─── Step 6: Compute test via Mata ───
        mata: _xtcsdq_compute_test("`resid_dm_`k_idx''", "`group'", `N', `T', ///
            `tau', `fhat_val', "`individual'")
        
        local T_tau     = r(T_tau)
        local Ttilde_tau = r(Ttilde_tau)
        local pval      = 1 - normal(`T_tau')
        local pval_c    = 1 - normal(`Ttilde_tau')
        
        mat `mat_T'[`k_idx', 1]      = `T_tau'
        mat `mat_Ttilde'[`k_idx', 1]  = `Ttilde_tau'
        mat `mat_pval'[`k_idx', 1]   = `pval'
        mat `mat_pval_c'[`k_idx', 1] = `pval_c'
        
        local sum_T      = `sum_T'      + `T_tau'
        local sum_Ttilde = `sum_Ttilde' + `Ttilde_tau'
    }
    
    // ──────────────────────────────────────────────────────────────────────
    //  Portmanteau M_K (Eq. 7)
    // ──────────────────────────────────────────────────────────────────────
    local M_K      = `sum_T'      / `K'
    local Mtilde_K = `sum_Ttilde' / `K'
    local pval_M   = 1 - normal(`M_K')
    local pval_Mc  = 1 - normal(`Mtilde_K')
    
    // ──────────────────────────────────────────────────────────────────────
    //  Display results table
    // ──────────────────────────────────────────────────────────────────────
    di ""
    di as txt "{hline 70}"
    di as txt "  H0: No cross-sectional error dependence in panel QR"
    di as txt "  H1: Cross-sectional error dependence present"
    di as txt "  Distribution under H0: Standard Normal (reject for large values)"
    di as txt "{hline 70}"
    
    if "`individual'" != "" & !`use_external_resid' {
        if "`nocorrection'" == "" {
            di as txt %12s "tau" %14s "T(i)_tau" %14s "T~(i)_tau" ///
                %14s "p(T)" %14s "p(T~)"
        }
        else {
            di as txt %12s "tau" %14s "T(i)_tau" %14s "p-value"
        }
    }
    else {
        if "`nocorrection'" == "" {
            di as txt %12s "tau" %14s "T_tau" %14s "T~_tau" ///
                %14s "p(T)" %14s "p(T~)"
        }
        else {
            di as txt %12s "tau" %14s "T_tau" %14s "p-value"
        }
    }
    di as txt "{hline 70}"
    
    local k_idx = 0
    foreach tau of local quantiles {
        local k_idx = `k_idx' + 1
        local tv    = `mat_T'[`k_idx', 1]
        local ttv   = `mat_Ttilde'[`k_idx', 1]
        local pv    = `mat_pval'[`k_idx', 1]
        local pcv   = `mat_pval_c'[`k_idx', 1]
        
        * Significance stars based on corrected p-value (or uncorrected if nocorrection)
        local stars ""
        if "`nocorrection'" == "" {
            if `pcv' < 0.01      local stars "***"
            else if `pcv' < 0.05 local stars "** "
            else if `pcv' < 0.10 local stars "*  "
        }
        else {
            if `pv' < 0.01      local stars "***"
            else if `pv' < 0.05 local stars "** "
            else if `pv' < 0.10 local stars "*  "
        }
        
        if "`nocorrection'" == "" {
            di as res %12.3f `tau' %14.3f `tv' %14.3f `ttv' ///
                %14.4f `pv' %14.4f `pcv' "  `stars'"
        }
        else {
            di as res %12.3f `tau' %14.3f `tv' %14.4f `pv' "  `stars'"
        }
    }
    
    if `K' > 1 {
        di as txt "{hline 70}"
        
        local stars_m ""
        if "`nocorrection'" == "" {
            if `pval_Mc' < 0.01      local stars_m "***"
            else if `pval_Mc' < 0.05 local stars_m "** "
            else if `pval_Mc' < 0.10 local stars_m "*  "
        }
        else {
            if `pval_M' < 0.01      local stars_m "***"
            else if `pval_M' < 0.05 local stars_m "** "
            else if `pval_M' < 0.10 local stars_m "*  "
        }
        
        if "`nocorrection'" == "" {
            di as txt %12s "M_K" as res %14.3f `M_K' %14.3f `Mtilde_K' ///
                %14.4f `pval_M' %14.4f `pval_Mc' "  `stars_m'"
        }
        else {
            di as txt %12s "M_K" as res %14.3f `M_K' %14.4f `pval_M' "  `stars_m'"
        }
    }
    
    di as txt "{hline 70}"
    di as txt "  *** p<0.01, ** p<0.05, * p<0.10"
    di as txt "  H0: No CSD in errors  |  Reject for large positive values"
    di as txt "{hline 70}"
    
    // ──────────────────────────────────────────────────────────────────────
    //  Return stored results
    // ──────────────────────────────────────────────────────────────────────
    local rownames ""
    foreach tau of local quantiles {
        local rownames "`rownames' tau_`tau'"
    }
    
    mat colnames `mat_T'      = "T_tau"
    mat colnames `mat_Ttilde'  = "Ttilde_tau"
    mat colnames `mat_pval'   = "pval_T"
    mat colnames `mat_pval_c' = "pval_Ttilde"
    mat colnames `mat_fhat'   = "fhat"
    
    mat rownames `mat_T'      = `rownames'
    mat rownames `mat_Ttilde'  = `rownames'
    mat rownames `mat_pval'   = `rownames'
    mat rownames `mat_pval_c' = `rownames'
    mat rownames `mat_fhat'   = `rownames'
    
    return matrix T_tau      = `mat_T'
    return matrix Ttilde_tau = `mat_Ttilde'
    return matrix pval_T     = `mat_pval'
    return matrix pval_Ttilde = `mat_pval_c'
    return matrix fhat       = `mat_fhat'
    
    return scalar N = `N'
    return scalar T = `T'
    return scalar K = `K'
    return scalar bandwidth = `bw_used'
    
    if `K' > 1 {
        return scalar M_K      = `M_K'
        return scalar Mtilde_K = `Mtilde_K'
        return scalar pval_M   = `pval_M'
        return scalar pval_Mc  = `pval_Mc'
    }
    
    // Clean up post-estimation temp variables
    if `use_post' {
        capture drop __xtcsdq_resid_*
        capture drop __xtcsdq_tmp
    }
    
    restore
end

// ══════════════════════════════════════════════════════════════════════════
//  Mata function: efficient pairwise correlation computation
//  Computes T_tau (Eq. 3) and T~_tau (Eq. 5)
// ══════════════════════════════════════════════════════════════════════════
mata:
void _xtcsdq_compute_test(string scalar resid_var, string scalar group_var,
                           real scalar N, real scalar T,
                           real scalar tau, real scalar fhat,
                           string scalar individual)
{
    real colvector resid, grp
    real matrix    U
    real scalar    i, j, rho2_sum, T_tau, Ttilde_tau
    real scalar    pair_count, correction1, correction2
    real colvector u_i, u_j
    real scalar    ss_i, ss_j, cov_ij, rho_sq
    
    resid = st_data(., resid_var)
    grp   = st_data(., group_var)
    
    U = J(T, N, .)
    for (i = 1; i <= N; i++) {
        idx = selectindex(grp :== i)
        if (rows(idx) != T) {
            errprintf("Unit %g has %g observations, expected %g\n", i, rows(idx), T)
            exit(error(198))
        }
        U[., i] = resid[idx]
    }
    
    rho2_sum = 0
    pair_count = N * (N - 1) / 2
    
    for (i = 1; i <= N - 1; i++) {
        u_i  = U[., i]
        ss_i = quadcross(u_i, u_i)
        
        for (j = i + 1; j <= N; j++) {
            u_j    = U[., j]
            ss_j   = quadcross(u_j, u_j)
            cov_ij = quadcross(u_i, u_j)
            rho_sq = (cov_ij^2) / (ss_i * ss_j)
            rho2_sum = rho2_sum + (T * rho_sq - 1)
        }
    }
    
    // T_tau (Eq. 3)
    T_tau = rho2_sum / sqrt(N * (N - 1))
    
    // T~_tau (Eq. 5)
    correction1 = sqrt(N * (N - 1) / (2 * T))
    correction2 = (tau * (1 - tau)) / (fhat^2) * sqrt(N * (N - 1) / T)
    Ttilde_tau  = T_tau - correction1 - correction2
    
    st_numscalar("r(T_tau)", T_tau)
    st_numscalar("r(Ttilde_tau)", Ttilde_tau)
}
end

exit
