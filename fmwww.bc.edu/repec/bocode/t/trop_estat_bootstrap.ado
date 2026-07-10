*! trop_estat_bootstrap
*! Purpose: Display Bootstrap distribution statistics, confidence intervals, and normality tests

/*==============================================================================
  estat bootstrap - Bootstrap Distribution Analysis
  
  Syntax:
    estat bootstrap [, graph]
  
  Options:
    graph - Plot histogram of Bootstrap distribution
  
  Output:
    - Number of Bootstrap samples and valid samples
    - ATT distribution statistics: mean, std.dev, median, IQR
    - Percentiles: 2.5%, 5%, 25%, 50%, 75%, 95%, 97.5%
    - Normality test (Jarque-Bera)
    - Comparison of Bootstrap mean with point estimate
    - Comparison of Bootstrap standard deviation with SE
  
  references:
    - Bootstrap distribution analysis requirements
    - Bootstrap distribution analysis requirements
==============================================================================*/


program define trop_estat_bootstrap
    version 17
    syntax [, graph]
    
    // ========== Step 1: Check e() results ==========
    if "`e(cmd)'" != "trop" {
        di as error "last estimates not found"
        exit 301
    }
    
    // ========== Step 2: Check if Bootstrap was used ==========
    // First check bootstrap_reps
    capture confirm scalar e(bootstrap_reps)
    if _rc {
        di as error "Bootstrap not used in estimation"
        di as error "Rerun {bf:trop} with bootstrap() option"
        exit 301
    }
    
    local boot_reps = e(bootstrap_reps)
    if `boot_reps' == 0 | `boot_reps' == . {
        di as error "Bootstrap not used in estimation"
        di as error "Rerun {bf:trop} with bootstrap() option"
        exit 301
    }
    
    // ========== Step 3: Obtain Bootstrap distribution ==========
    // Prioritize new e(bootstrap_estimates), compatible with old e(att_boot)
    tempname boot_est
    local matrix_found = 0
    
    // Check if e(bootstrap_estimates) exists and is valid
    // When matrix doesn't exist, Stata creates 1x1 with missing value
    capture matrix `boot_est' = e(bootstrap_estimates)
    local cap_rc = _rc
    if `cap_rc' == 0 {
        local nrows = rowsof(`boot_est')
        local ncols = colsof(`boot_est')
        // Valid bootstrap matrix should have B rows and 1 column, B > 1
        // A 1x1 matrix with missing value indicates non-existent matrix
        if `nrows' > 1 | (`nrows' == 1 & `ncols' == 1 & `boot_est'[1,1] != .) {
            local matrix_found = 1
        }
    }
    
    if `matrix_found' == 0 {
        // Try old matrix name
        capture matrix `boot_est' = e(att_boot)
        local cap_rc = _rc
        if `cap_rc' == 0 {
            local nrows = rowsof(`boot_est')
            local ncols = colsof(`boot_est')
            if `nrows' > 1 | (`nrows' == 1 & `ncols' == 1 & `boot_est'[1,1] != .) {
                local matrix_found = 1
            }
        }
    }
    
    if `matrix_found' == 0 {
        di as error "Bootstrap estimates not found in e()"
        di as error "Expected e(bootstrap_estimates) or e(att_boot) matrix"
        exit 301
    }
    
    local B = rowsof(`boot_est')
    
    // ========== Step 4: Display Bootstrap analysis ==========
    mata: _trop_estat_bootstrap_display(st_matrix("`boot_est'"), ///
          st_numscalar("e(att)"), st_numscalar("e(se)"), ///
          st_numscalar("e(bootstrap_reps)"))
    
    // ========== Step 5: Graph output ==========
    if "`graph'" != "" {
        _trop_estat_bootstrap_graph `boot_est'
    }
end

/*==============================================================================
  Graph function: Bootstrap distribution histogram*/


program define _trop_estat_bootstrap_graph
    args boot_est
    
    local B = rowsof(`boot_est')
    
    // Create temporary dataset for plotting
    preserve
    clear
    quietly set obs `B'
    quietly gen double att_b = .
    
    forvalues i = 1/`B' {
        qui replace att_b = `boot_est'[`i', 1] in `i'
    }
    
    // Drop missing values (failed bootstrap iterations)
    // The bootstrap_estimates matrix may contain missing values for failed iterations.
    qui drop if att_b == .
    qui count
    if r(N) < 2 {
        di as error "Insufficient valid bootstrap estimates for graph"
        restore
        exit
    }
    
    // Get point estimate and CI
    local tau = e(att)
    local ci_lower = e(ci_lower)
    local ci_upper = e(ci_upper)
    local boot_reps = e(bootstrap_reps)
    
    // Dynamically calculate confidence level from e(alpha_level), no longer hardcoded to 95%
    local alpha_level = e(alpha_level)
    if `alpha_level' == . | `alpha_level' <= 0 | `alpha_level' >= 1 {
        local alpha_level = 0.05
    }
    local ci_level : di %3.0f 100*(1 - `alpha_level')
    local ci_level = strtrim("`ci_level'")
    
    // Draw histogram
    histogram att_b, ///
        normal ///
        xline(`tau', lcolor(red) lwidth(thick)) ///
        xline(`ci_lower' `ci_upper', lcolor(red) lpattern(dash)) ///
        title("Bootstrap Distribution of ATT") ///
        subtitle("`boot_reps' replications") ///
        xtitle("ATT estimate") ///
        ytitle("Density") ///
        legend(order(1 "Bootstrap dist." 2 "Normal approx." ///
                     3 "Point estimate" 4 "`ci_level'% CI")) ///
        scheme(s2color)
    
    restore
end

/*==============================================================================
  Mata function: Display Bootstrap distribution analysis
*/

version 17
mata:

// Linear interpolation percentile (consistent with the Rust core's
// interpolate_percentile()).  Uses the (n-1)*p convention: the fractional
// index idx = (n-1)*p is linearly interpolated between adjacent order
// statistics.
real scalar _trop_interpolate_percentile(real colvector sorted_vec, real scalar p)
{
    real scalar n, idx_f, idx_low, idx_high, frac
    
    n = rows(sorted_vec)
    if (n == 0) return(.)
    if (n == 1) return(sorted_vec[1])
    
    idx_f = (n - 1) * p    // 0-based fractional index
    idx_low = floor(idx_f)
    idx_high = ceil(idx_f)
    
    // Clamp to valid range [0, n-1]
    if (idx_low < 0) idx_low = 0
    if (idx_high > n - 1) idx_high = n - 1
    
    if (idx_low == idx_high) {
        return(sorted_vec[idx_low + 1])    // +1 for Mata 1-based indexing
    }
    
    frac = idx_f - idx_low
    return(sorted_vec[idx_low + 1] * (1 - frac) + sorted_vec[idx_high + 1] * frac)
}

void _trop_estat_bootstrap_display(real colvector boot_est, 
                                    real scalar att_point,
                                    real scalar se_point,
                                    real scalar boot_reps)
{
    struct bootstrap_stats scalar bstats
    real scalar B, B_total, median_val, iqr_val
    real scalar q25, q75, q025, q05, q95, q975
    real scalar jb_stat, jb_p
    real scalar fail_pct
    real colvector sorted_boot, boot_valid
    
    // Filter out missing values from bootstrap estimates.
    // The bootstrap_estimates matrix is pre-allocated as J(n_bootstrap, 1, .)
    // and C bridge only writes n_valid rows. Remaining rows stay as missing,
    // which causes mean()/variance() to propagate missing → all stats become NaN.
    // Distribution statistics must be computed on valid estimates only;
    // including missing placeholders would propagate NaN.
    B_total = rows(boot_est)
    boot_valid = select(boot_est, boot_est :< .)
    B = rows(boot_valid)
    
    if (B < 2) {
        printf("\n")
        printf("{err}Insufficient valid bootstrap estimates for analysis\n")
        printf("{err}Valid samples: %g / %g\n", B, boot_reps)
        printf("{err}At least 2 valid estimates are required\n")
        return
    }
    
    // ========== Calculate distribution statistics ==========
    // Use compute_bootstrap_stats() to replace inline repeated calculations
    // This function is defined in trop_estat_helpers.mata, calculating mean/sd/skewness/kurtosis
    // and handles missing filtering and sd=0 guard
    bstats = compute_bootstrap_stats(boot_valid)
    
    // Sort for percentile calculation
    sorted_boot = sort(boot_valid, 1)
    
    // Calculate percentiles — use (n-1)*p linear interpolation,
    // consistent with the Rust core's interpolate_percentile().
    q025 = _trop_interpolate_percentile(sorted_boot, 0.025)
    q05 = _trop_interpolate_percentile(sorted_boot, 0.05)
    q25 = _trop_interpolate_percentile(sorted_boot, 0.25)
    median_val = _trop_interpolate_percentile(sorted_boot, 0.50)
    q75 = _trop_interpolate_percentile(sorted_boot, 0.75)
    q95 = _trop_interpolate_percentile(sorted_boot, 0.95)
    q975 = _trop_interpolate_percentile(sorted_boot, 0.975)
    
    iqr_val = q75 - q25
    
    // ========== Display title ==========
    printf("\n")
    printf("{txt}Bootstrap Distribution Analysis\n")
    printf("{txt}{hline 78}\n")
    
    // ========== Display sample information ==========
    printf("{txt}Bootstrap samples:  B = {res}%g\n", B)
    printf("{txt}Requested samples:  {res}%g\n", boot_reps)
    printf("{txt}Valid samples:      {res}%g{txt} / {res}%g{txt} ({res}%5.1f%%{txt})\n", B, boot_reps, 100*B/boot_reps)
    /* Surface the failure rate symmetrically with `estat loocv`:
       > 5% prints an advisory note reminding users that SEs may be
       less reliable.  The exact threshold is set in
       `_trop_display_bootstrap_warnings` (`mata/trop_ereturn_store.mata`). */
    if (B < boot_reps) {
        fail_pct = 100 * (boot_reps - B) / boot_reps
        printf("{txt}Bootstrap fail rate: {res}%5.1f%%\n", fail_pct)
        if (fail_pct > 5.0) {
            printf("{txt}  note: > 5%% of replicates failed; SEs may be less reliable.\n")
        }
    }
    printf("\n")
    
    // ========== Display ATT distribution statistics ==========
    printf("{txt}ATT distribution:\n")
    printf("{txt}  Mean       = {res}%10.4f{txt}   (point estimate: {res}%10.4f{txt})\n", 
           bstats.mean_val, att_point)
    printf("{txt}  Std.Dev.   = {res}%10.4f{txt}   (bootstrap SE:   {res}%10.4f{txt})\n", 
           bstats.sd, se_point)
    printf("{txt}  Median     = {res}%10.4f\n", median_val)
    printf("{txt}  IQR        = {res}%10.4f{txt}   (Q75 - Q25)\n", iqr_val)
    printf("\n")
    
    // ========== Display percentiles ==========
    printf("{txt}Percentiles:\n")
    printf("{txt}   2.5%%      = {res}%10.4f\n", q025)
    printf("{txt}   5.0%%      = {res}%10.4f\n", q05)
    printf("{txt}  25.0%%      = {res}%10.4f\n", q25)
    printf("{txt}  50.0%%      = {res}%10.4f\n", median_val)
    printf("{txt}  75.0%%      = {res}%10.4f\n", q75)
    printf("{txt}  95.0%%      = {res}%10.4f\n", q95)
    printf("{txt}  97.5%%      = {res}%10.4f\n", q975)
    printf("\n")
    
    // ========== Display normality test ==========
    if (bstats.sd > 0) {
        // Jarque-Bera statistic: JB = (B/6) * (Skew^2 + (1/4)(Kurt-3)^2)
        jb_stat = (B / 6.0) * (bstats.skewness^2 + 0.25 * (bstats.kurtosis - 3)^2)
        jb_p = chi2tail(2, jb_stat)
        
        printf("{txt}Normality test (Jarque-Bera):\n")
        printf("{txt}  Statistic  = {res}%10.4f\n", jb_stat)
        printf("{txt}  p-value    = {res}%10.4f", jb_p)
        
        if (jb_p > 0.05) {
            printf("{txt}    (fail to reject normality)\n")
        }
        else {
            printf("{txt}    (reject normality)\n")
        }
    }
    else {
        printf("{txt}Normality test (Jarque-Bera):\n")
        printf("{txt}  {res}(skipped: all bootstrap estimates identical, sd=0)\n")
    }
    
    printf("{txt}{hline 78}\n")
}

end
