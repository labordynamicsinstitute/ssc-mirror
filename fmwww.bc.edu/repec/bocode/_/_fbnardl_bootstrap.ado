*! _fbnardl_bootstrap — Bootstrap Cointegration Tests for FBNARDL
*! Based on Bertelli, Vacca & Zoia (2022) — Economic Modelling
*! Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)

capture program drop _fbnardl_bootstrap
program define _fbnardl_bootstrap, rclass
    version 17

    // Syntax: _fbnardl_bootstrap D.depvar regvars, options
    syntax varlist [if] [in], ///
        depvar(string)        /// original depvar name
        decnames(string)      /// decomposed variable names (clean)
        ecmcoef(string)       /// ECM coefficient name (L.depvar)
        levelsvars(string)    /// all lagged level variable names (for Fov test)
        indepvars(string)     /// lagged independent variable names (for Find test)
        reps(integer)         /// number of bootstrap replications
        nobs(integer)         /// number of observations used
        [controls(string)]    /// control variable names (optional)

    // Parse the regression specification
    gettoken lhs regressors : varlist

    // =========================================================================
    // STEP 1: Fit unrestricted model, compute test statistics
    // =========================================================================
    qui regress `lhs' `regressors'

    // Store original test statistics
    // Fov: joint test on all lagged levels
    qui test `levelsvars'
    local Fov_orig = r(F)

    // t-test on lagged dependent
    local t_orig = _b[`ecmcoef'] / _se[`ecmcoef']

    // Find: test on lagged independents only
    qui test `indepvars'
    local Find_orig = r(F)

    // Store residuals and fitted values
    tempvar resid_unrestr
    qui predict double `resid_unrestr', residuals

    // Store coefficients for data generation
    tempname b_unrestr
    mat `b_unrestr' = e(b)
    local nobs_model = e(N)
    local nparams = e(df_m) + 1

    // =========================================================================
    // STEP 2-3: Re-estimate under each null, compute restricted residuals
    // =========================================================================

    // --- Fov null: drop all lagged levels ---
    local regressors_fov ""
    foreach v of local regressors {
        local is_level = 0
        foreach lv of local levelsvars {
            if "`v'" == "`lv'" local is_level = 1
        }
        if `is_level' == 0 {
            local regressors_fov "`regressors_fov' `v'"
        }
    }
    qui regress `lhs' `regressors_fov'
    tempvar resid_fov
    qui predict double `resid_fov', residuals

    // --- t null: drop only L.depvar ---
    local regressors_t ""
    foreach v of local regressors {
        if "`v'" != "`ecmcoef'" {
            local regressors_t "`regressors_t' `v'"
        }
    }
    qui regress `lhs' `regressors_t'
    tempvar resid_t
    qui predict double `resid_t', residuals

    // --- Find null: drop lagged independents ---
    local regressors_find ""
    foreach v of local regressors {
        local is_indep = 0
        foreach iv of local indepvars {
            if "`v'" == "`iv'" local is_indep = 1
        }
        if `is_indep' == 0 {
            local regressors_find "`regressors_find' `v'"
        }
    }
    qui regress `lhs' `regressors_find'
    tempvar resid_find
    qui predict double `resid_find', residuals

    // =========================================================================
    // STEP 4-6: Bootstrap via Mata
    // =========================================================================
    // Transfer data to Mata for speed
    // We use residual resampling with recentering

    // Prepare Mata matrices
    tempname bs_Fov bs_t bs_Find
    mata: _fbnardl_do_bootstrap("`resid_fov'", "`resid_t'", "`resid_find'", ///
        "`lhs'", "`regressors'", "`regressors_fov'", "`regressors_t'", "`regressors_find'", ///
        "`levelsvars'", "`ecmcoef'", "`indepvars'", ///
        `reps', "`bs_Fov'", "`bs_t'", "`bs_Find'")

    // =========================================================================
    // Compute critical values and p-values from bootstrap distributions
    // =========================================================================
    // Fov critical values (upper tail — reject if Fov > cv)
    mata: st_local("Fov_cv01", strofreal(_fbnardl_quantile("`bs_Fov'", 0.99)))
    mata: st_local("Fov_cv05", strofreal(_fbnardl_quantile("`bs_Fov'", 0.95)))
    mata: st_local("Fov_cv10", strofreal(_fbnardl_quantile("`bs_Fov'", 0.90)))

    // t critical values (lower tail — reject if t < cv, so use negative quantiles)
    mata: st_local("t_cv01", strofreal(_fbnardl_quantile("`bs_t'", 0.01)))
    mata: st_local("t_cv05", strofreal(_fbnardl_quantile("`bs_t'", 0.05)))
    mata: st_local("t_cv10", strofreal(_fbnardl_quantile("`bs_t'", 0.10)))

    // Find critical values (upper tail)
    mata: st_local("Find_cv01", strofreal(_fbnardl_quantile("`bs_Find'", 0.99)))
    mata: st_local("Find_cv05", strofreal(_fbnardl_quantile("`bs_Find'", 0.95)))
    mata: st_local("Find_cv10", strofreal(_fbnardl_quantile("`bs_Find'", 0.90)))

    // p-values
    mata: st_local("Fov_pval", strofreal(_fbnardl_pvalue_upper("`bs_Fov'", `Fov_orig')))
    mata: st_local("t_pval", strofreal(_fbnardl_pvalue_lower("`bs_t'", `t_orig')))
    mata: st_local("Find_pval", strofreal(_fbnardl_pvalue_upper("`bs_Find'", `Find_orig')))

    // Return results
    return scalar Fov_cv01 = `Fov_cv01'
    return scalar Fov_cv05 = `Fov_cv05'
    return scalar Fov_cv10 = `Fov_cv10'
    return scalar t_cv01 = `t_cv01'
    return scalar t_cv05 = `t_cv05'
    return scalar t_cv10 = `t_cv10'
    return scalar Find_cv01 = `Find_cv01'
    return scalar Find_cv05 = `Find_cv05'
    return scalar Find_cv10 = `Find_cv10'
    return scalar Fov_pval = `Fov_pval'
    return scalar t_pval = `t_pval'
    return scalar Find_pval = `Find_pval'
end


// =============================================================================
// MATA FUNCTIONS FOR BOOTSTRAP
// =============================================================================
mata:
mata set matastrict off

// Bootstrap main routine
void _fbnardl_do_bootstrap(
    string scalar resid_fov_name,
    string scalar resid_t_name,
    string scalar resid_find_name,
    string scalar lhs_name,
    string scalar regressors_name,
    string scalar regressors_fov_name,
    string scalar regressors_t_name,
    string scalar regressors_find_name,
    string scalar levelsvars_name,
    string scalar ecmcoef_name,
    string scalar indepvars_name,
    real scalar B,
    string scalar bs_Fov_matname,
    string scalar bs_t_matname,
    string scalar bs_Find_matname)
{
    // All variable declarations at function scope (Mata requirement)
    real colvector resid_fov, resid_t, resid_find
    real colvector y, y_orig
    real colvector bs_Fov_dist, bs_t_dist, bs_Find_dist
    real colvector idx_fov, idx_t, idx_find
    real colvector bs_resid_fov, bs_resid_t, bs_resid_find
    real colvector y_star, y_full
    real scalar n, b, rc, orig_n
    real scalar pct, last_pct
    real scalar b_ecm, se_ecm, coef_idx
    real scalar valid_fov, valid_t, valid_find

    // Get residuals
    resid_fov  = st_data(., resid_fov_name)
    resid_t    = st_data(., resid_t_name)
    resid_find = st_data(., resid_find_name)

    // Get original y values (full column including missings)
    y_orig = st_data(., lhs_name)
    orig_n = rows(y_orig)

    // Use common non-missing mask: obs must be non-missing in y AND all residuals
    // This ensures all vectors have identical length after selection
    real colvector valid_mask
    valid_mask = (y_orig :!= .) :& (resid_fov :!= .) :& (resid_t :!= .) :& (resid_find :!= .)
    
    resid_fov  = select(resid_fov, valid_mask)
    resid_t    = select(resid_t, valid_mask)
    resid_find = select(resid_find, valid_mask)
    y          = select(y_orig, valid_mask)

    n = rows(resid_fov)

    // Recenter residuals (Step 5a of Bertelli et al.)
    resid_fov  = resid_fov  :- mean(resid_fov)
    resid_t    = resid_t    :- mean(resid_t)
    resid_find = resid_find :- mean(resid_find)

    // Fitted values under each null (fitted = observed - residual)
    // Note: residuals may be shorter than y due to lags, so use tail of y
    
    // Initialize bootstrap distributions
    bs_Fov_dist  = J(B, 1, .)
    bs_t_dist    = J(B, 1, .)
    bs_Find_dist = J(B, 1, .)

    // Progress indicator
    printf("  [")
    last_pct = 0

    for (b = 1; b <= B; b++) {
        // Progress bar
        pct = floor(b / B * 50)
        if (pct > last_pct) {
            printf("=")
            displayflush()
            last_pct = pct
        }

        // Resample residuals with replacement
        idx_fov  = ceil(uniform(n, 1) :* n)
        idx_t    = ceil(uniform(n, 1) :* n)
        idx_find = ceil(uniform(n, 1) :* n)

        bs_resid_fov  = resid_fov[idx_fov]
        bs_resid_t    = resid_t[idx_t]
        bs_resid_find = resid_find[idx_find]

        // Recenter bootstrap residuals
        bs_resid_fov  = bs_resid_fov  :- mean(bs_resid_fov)
        bs_resid_t    = bs_resid_t    :- mean(bs_resid_t)
        bs_resid_find = bs_resid_find :- mean(bs_resid_find)

        // --- Fov bootstrap statistic ---
        // y* = fitted_fov + bootstrap_resid_fov
        y_star = (y :- resid_fov) :+ bs_resid_fov

        // Build full column vector with missings in the right places
        y_full = y_orig
        y_full[| orig_n - n + 1, 1 \ orig_n, 1 |] = y_star
        st_store(., lhs_name, y_full)

        rc = _stata("capture qui regress " + lhs_name + " " + regressors_name, 1)
        if (rc == 0) {
            rc = _stata("capture qui test " + levelsvars_name, 1)
            if (rc == 0) {
                bs_Fov_dist[b] = st_numscalar("r(F)")
            }
        }

        // --- t bootstrap statistic ---
        y_star = (y :- resid_t) :+ bs_resid_t
        y_full = y_orig
        y_full[| orig_n - n + 1, 1 \ orig_n, 1 |] = y_star
        st_store(., lhs_name, y_full)

        rc = _stata("capture qui regress " + lhs_name + " " + regressors_name, 1)
        if (rc == 0) {
            coef_idx = _fbnardl_find_coef_idx(ecmcoef_name)
            b_ecm = st_matrix("e(b)")[1, coef_idx]
            se_ecm = sqrt(diagonal(st_matrix("e(V)"))[coef_idx])
            if (se_ecm > 0) {
                bs_t_dist[b] = b_ecm / se_ecm
            }
        }

        // --- Find bootstrap statistic ---
        y_star = (y :- resid_find) :+ bs_resid_find
        y_full = y_orig
        y_full[| orig_n - n + 1, 1 \ orig_n, 1 |] = y_star
        st_store(., lhs_name, y_full)

        rc = _stata("capture qui regress " + lhs_name + " " + regressors_name, 1)
        if (rc == 0) {
            rc = _stata("capture qui test " + indepvars_name, 1)
            if (rc == 0) {
                bs_Find_dist[b] = st_numscalar("r(F)")
            }
        }

        // Restore original y
        st_store(., lhs_name, y_orig)
    }

    printf("]\n")

    // Remove missing bootstrap statistics
    bs_Fov_dist  = select(bs_Fov_dist,  bs_Fov_dist  :!= .)
    bs_t_dist    = select(bs_t_dist,    bs_t_dist    :!= .)
    bs_Find_dist = select(bs_Find_dist, bs_Find_dist :!= .)

    // Store as Stata matrices
    st_matrix(bs_Fov_matname,  bs_Fov_dist)
    st_matrix(bs_t_matname,    bs_t_dist)
    st_matrix(bs_Find_matname, bs_Find_dist)

    valid_fov = rows(bs_Fov_dist)
    valid_t = rows(bs_t_dist)
    valid_find = rows(bs_Find_dist)
    printf("  Valid bootstrap replications: Fov=%g, t=%g, Find=%g\n",
        valid_fov, valid_t, valid_find)
}


// Find coefficient index by name
real scalar _fbnardl_find_coef_idx(string scalar coefname)
{
    string rowvector names
    real scalar i

    names = st_matrixcolstripe("e(b)")[., 2]'
    for (i = 1; i <= cols(names); i++) {
        if (names[i] == coefname) return(i)
    }
    // If not found, try column 1 (equation name : coefname)
    names = st_matrixcolstripe("e(b)")[., 1]' + ":" + st_matrixcolstripe("e(b)")[., 2]'
    for (i = 1; i <= cols(names); i++) {
        if (names[i] == coefname) return(i)
    }
    return(1) // fallback
}


// Quantile function for bootstrap distribution
real scalar _fbnardl_quantile(string scalar matname, real scalar prob)
{
    real colvector v
    real scalar n, idx

    v = st_matrix(matname)
    if (cols(v) > rows(v)) v = v'  // ensure column vector
    v = sort(v, 1)
    n = rows(v)
    idx = ceil(n * prob)
    if (idx < 1) idx = 1
    if (idx > n) idx = n
    return(v[idx])
}


// P-value (upper tail) for F-tests
real scalar _fbnardl_pvalue_upper(string scalar matname, real scalar stat)
{
    real colvector v
    real scalar n

    v = st_matrix(matname)
    if (cols(v) > rows(v)) v = v'
    n = rows(v)
    return(sum(v :>= stat) / n)
}


// P-value (lower tail) for t-test
real scalar _fbnardl_pvalue_lower(string scalar matname, real scalar stat)
{
    real colvector v
    real scalar n

    v = st_matrix(matname)
    if (cols(v) > rows(v)) v = v'
    n = rows(v)
    return(sum(v :<= stat) / n)
}

end
