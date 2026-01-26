*! kmtest.ado - Tests of Linear and Logarithmic Transformations for Integrated Processes
*! Version 1.0.2  24jan2026
*! Based on Kobayashi & McAleer (1999), Econometric Reviews
*! Implementation by Dr. Merwan Roudane
*! 
*! v1.0.2: Fixed local macro syntax for panelvar (thanks to Kit Baum)
*! This command implements non-nested tests for comparing linear vs logarithmic
*! transformations of I(1) processes, as proposed by Kobayashi and McAleer.

program define kmtest, rclass
    version 14.0
    
    syntax varname(ts) [if] [in], [Lags(integer 0) NODrift Level(cilevel) ///
           BOth DETail GRaph SAVEgraph(string)]
    
    * Mark sample
    marksample touse
    
    * Get variable name
    local y `varlist'
    
    qui tsset
    local timevar `r(timevar)'
    local panelvar `r(panelvar)'
    
    if "`panelvar'" != "" {
        di as error "Panel data not supported. Please use single time series."
        exit 198
    }
    
    * Check that variable is positive (required for log transformation)
    qui sum `y' if `touse'
    if r(min) <= 0 {
        di as error "Variable `y' contains non-positive values."
        di as error "Logarithmic transformation requires strictly positive data."
        exit 411
    }
    
    * Display header
    di as text ""
    di as text "{hline 78}"
    di as text "{bf:Kobayashi-McAleer Test for Linear vs Logarithmic Transformation}"
    di as text "{hline 78}"
    di as text ""
    di as text "Variable: " as result "`y'"
    di as text "AR lags:  " as result "`lags'"
    
    if "`nodrift'" == "" {
        di as text "Drift:    " as result "Assumed present (using V1/V2 statistics)"
    }
    else {
        di as text "Drift:    " as result "Assumed absent (using U1/U2 statistics)"
    }
    di as text ""
    
    * Store original sample size
    qui count if `touse'
    local nobs = r(N)
    di as text "Observations: " as result "`nobs'"
    di as text ""
    
    * Calculate tests based on drift assumption
    if "`nodrift'" == "" {
        * Tests WITH drift (V1 and V2 - asymptotically normal)
        _kmtest_withdrift `y' if `touse', lags(`lags') `detail'
        
        local v1_stat = r(V1)
        local v1_pval = r(V1_pval)
        local v2_stat = r(V2)
        local v2_pval = r(V2_pval)
        local mu_hat = r(mu_hat)
        local eta_hat = r(eta_hat)
        local sigma_hat = r(sigma_hat)
        local omega_hat = r(omega_hat)
        
        * Get critical values for normal distribution
        local cv_10 = invnormal(0.90)
        local cv_05 = invnormal(0.95)
        local cv_01 = invnormal(0.99)
        
        * Display results
        di as text "{hline 78}"
        di as text "{bf:Test Results (With Drift - Asymptotic Normal Distribution)}"
        di as text "{hline 78}"
        di as text ""
        di as text "{col 5}{bf:Test}{col 20}{bf:Statistic}{col 35}{bf:p-value}{col 50}{bf:Decision at `level'%}"
        di as text "{hline 78}"
        
        * V1 test results
        local cv = invnormal(1 - (100-`level')/200)
        if `v1_stat' > `cv' {
            local decision1 "Reject Linear"
        }
        else {
            local decision1 "Do not reject Linear"
        }
        di as text "{col 5}V1 (H0: Linear)" ///
           as result "{col 20}" %9.4f `v1_stat' ///
           as result "{col 35}" %9.4f `v1_pval' ///
           as text "{col 50}`decision1'"
        
        * V2 test results
        if `v2_stat' > `cv' {
            local decision2 "Reject Logarithmic"
        }
        else {
            local decision2 "Do not reject Logarithmic"
        }
        di as text "{col 5}V2 (H0: Log)" ///
           as result "{col 20}" %9.4f `v2_stat' ///
           as result "{col 35}" %9.4f `v2_pval' ///
           as text "{col 50}`decision2'"
        
        di as text "{hline 78}"
        di as text ""
        
        * Critical values
        di as text "{bf:Critical Values (Upper Tail, One-sided):}"
        di as text "{col 5}10%: " as result %6.3f `cv_10' ///
           as text "{col 25}5%: " as result %6.3f `cv_05' ///
           as text "{col 45}1%: " as result %6.3f `cv_01'
        di as text ""
        
        * Estimated parameters
        if "`detail'" != "" {
            di as text "{bf:Estimated Parameters:}"
            di as text "{col 5}Linear model drift (mu):     " as result %9.4f `mu_hat'
            di as text "{col 5}Linear model std.dev (sigma):" as result %9.4f `sigma_hat'
            di as text "{col 5}Log model drift (eta):       " as result %9.4f `eta_hat'
            di as text "{col 5}Log model std.dev (omega):   " as result %9.4f `omega_hat'
            di as text ""
        }
        
        * Store results
        return scalar V1 = `v1_stat'
        return scalar V1_pval = `v1_pval'
        return scalar V2 = `v2_stat'
        return scalar V2_pval = `v2_pval'
        return scalar mu = `mu_hat'
        return scalar eta = `eta_hat'
        return scalar sigma = `sigma_hat'
        return scalar omega = `omega_hat'
        return scalar N = `nobs'
        return scalar lags = `lags'
        return local test_type "with_drift"
    }
    else {
        * Tests WITHOUT drift (U1 and U2 - nonstandard distribution)
        _kmtest_nodrift `y' if `touse', lags(`lags') `detail'
        
        local u1_stat = r(U1)
        local u2_stat = r(U2)
        local sigma_hat = r(sigma_hat)
        local omega_hat = r(omega_hat)
        
        * Critical values for nonstandard distribution (from Table 1 of paper)
        local cv_10 = 0.477
        local cv_05 = 0.664
        local cv_01 = 1.116
        
        * Calculate p-values using simulation (approximate)
        _kmtest_pval_nodrift `u1_stat'
        local u1_pval = r(pval)
        _kmtest_pval_nodrift `u2_stat'
        local u2_pval = r(pval)
        
        * Display results
        di as text "{hline 78}"
        di as text "{bf:Test Results (Without Drift - Nonstandard Distribution)}"
        di as text "{hline 78}"
        di as text ""
        di as text "{col 5}{bf:Test}{col 20}{bf:Statistic}{col 35}{bf:p-value*}{col 50}{bf:Decision at `level'%}"
        di as text "{hline 78}"
        
        * Determine critical value based on level
        if `level' >= 99 {
            local cv = `cv_01'
        }
        else if `level' >= 95 {
            local cv = `cv_05'
        }
        else {
            local cv = `cv_10'
        }
        
        * U1 test results
        if `u1_stat' > `cv' {
            local decision1 "Reject Linear"
        }
        else {
            local decision1 "Do not reject Linear"
        }
        di as text "{col 5}U1 (H0: Linear)" ///
           as result "{col 20}" %9.4f `u1_stat' ///
           as result "{col 35}" %9.4f `u1_pval' ///
           as text "{col 50}`decision1'"
        
        * U2 test results
        if `u2_stat' > `cv' {
            local decision2 "Reject Logarithmic"
        }
        else {
            local decision2 "Do not reject Logarithmic"
        }
        di as text "{col 5}U2 (H0: Log)" ///
           as result "{col 20}" %9.4f `u2_stat' ///
           as result "{col 35}" %9.4f `u2_pval' ///
           as text "{col 50}`decision2'"
        
        di as text "{hline 78}"
        di as text ""
        
        * Critical values
        di as text "{bf:Critical Values (Upper Tail, One-sided):}"
        di as text "{col 5}10%: " as result %6.3f `cv_10' ///
           as text "{col 25}5%: " as result %6.3f `cv_05' ///
           as text "{col 45}1%: " as result %6.3f `cv_01'
        di as text ""
        di as text "* p-values are approximate (based on simulation of nonstandard distribution)"
        di as text ""
        
        * Estimated parameters
        if "`detail'" != "" {
            di as text "{bf:Estimated Parameters:}"
            di as text "{col 5}Linear residual std.dev (sigma): " as result %9.4f `sigma_hat'
            di as text "{col 5}Log residual std.dev (omega):    " as result %9.4f `omega_hat'
            di as text ""
        }
        
        * Store results
        return scalar U1 = `u1_stat'
        return scalar U1_pval = `u1_pval'
        return scalar U2 = `u2_stat'
        return scalar U2_pval = `u2_pval'
        return scalar sigma = `sigma_hat'
        return scalar omega = `omega_hat'
        return scalar N = `nobs'
        return scalar lags = `lags'
        return local test_type "no_drift"
    }
    
    * Interpretation
    di as text "{hline 78}"
    di as text "{bf:Interpretation:}"
    di as text "{hline 78}"
    
    if "`nodrift'" == "" {
        if `v1_stat' <= `cv' & `v2_stat' > `cv' {
            di as text "The linear specification is preferred: y_t follows an I(1) process."
            return local conclusion "linear"
        }
        else if `v1_stat' > `cv' & `v2_stat' <= `cv' {
            di as text "The logarithmic specification is preferred: log(y_t) follows an I(1) process."
            return local conclusion "logarithmic"
        }
        else if `v1_stat' <= `cv' & `v2_stat' <= `cv' {
            di as text "Neither specification is rejected. Both may be appropriate."
            return local conclusion "both"
        }
        else {
            di as text "Both specifications are rejected. Consider alternative models."
            return local conclusion "neither"
        }
    }
    else {
        if `u1_stat' <= `cv' & `u2_stat' > `cv' {
            di as text "The linear specification is preferred: y_t follows an I(1) process."
            return local conclusion "linear"
        }
        else if `u1_stat' > `cv' & `u2_stat' <= `cv' {
            di as text "The logarithmic specification is preferred: log(y_t) follows an I(1) process."
            return local conclusion "logarithmic"
        }
        else if `u1_stat' <= `cv' & `u2_stat' <= `cv' {
            di as text "Neither specification is rejected. Both may be appropriate."
            return local conclusion "both"
        }
        else {
            di as text "Both specifications are rejected. Consider alternative models."
            return local conclusion "neither"
        }
    }
    
    di as text "{hline 78}"
    di as text ""
    
    * Generate graphs if requested
    if "`graph'" != "" | "`savegraph'" != "" {
        _kmtest_graph `y' if `touse', `savegraph'
    }
    
    return local varname "`y'"
    return local cmd "kmtest"
    
end

*------------------------------------------------------------------------------
* Subroutine: Tests WITH drift (V1 and V2)
*------------------------------------------------------------------------------
program define _kmtest_withdrift, rclass
    version 14.0
    syntax varname(ts) [if] [in], [Lags(integer 0) DETail]
    
    marksample touse
    local y `varlist'
    local p = `lags'
    
    * Get sample size
    qui count if `touse'
    local n = r(N)
    
    * Create first difference
    tempvar dy logy dlogy
    qui gen double `dy' = D.`y' if `touse'
    qui gen double `logy' = ln(`y') if `touse'
    qui gen double `dlogy' = D.`logy' if `touse'
    
    *--------------------------------------------------------------------------
    * V1 Test: H0: Linear model (y_t - y_{t-1} = e_t + mu)
    *--------------------------------------------------------------------------
    
    * Estimate AR(p) model for first differences with constant
    if `p' > 0 {
        * Build lag list for regression
        local laglist ""
        forvalues i = 1/`p' {
            local laglist "`laglist' L`i'.`dy'"
        }
        qui reg `dy' `laglist' if `touse'
    }
    else {
        qui reg `dy' if `touse'
    }
    
    * Get residuals and estimate of mu
    tempvar z z2 y_lag1
    qui predict double `z' if `touse', resid
    qui gen double `z2' = `z'^2 if `touse'
    
    * Calculate sample variance of residuals
    qui sum `z2' if `touse'
    local s2 = r(mean)
    local s = sqrt(`s2')
    
    * Calculate estimated drift
    qui sum `dy' if `touse'
    local m = r(mean)
    if `p' > 0 {
        * Adjust for AR parameters
        local a1_sum = 0
        matrix b = e(b)
        local ncols = colsof(b)
        forvalues i = 1/`p' {
            local a1_sum = `a1_sum' + b[1,`i']
        }
        local m = `m' / (1 - `a1_sum')
    }
    
    * Create lagged level
    qui gen double `y_lag1' = L.`y' if `touse'
    
    * Calculate V1 statistic
    * V1 = n^{-3/2} * sum(y_{t-1} * (z_t^2 - s^2)) / sqrt(s^4 * m^2 / 6)
    
    tempvar v1_term
    qui gen double `v1_term' = `y_lag1' * (`z2' - `s2') if `touse'
    qui sum `v1_term' if `touse'
    local sum_v1 = r(sum)
    
    local V1_num = `n'^(-1.5) * `sum_v1'
    local V1_den = sqrt(`s'^4 * `m'^2 / 6)
    
    if `V1_den' > 0 {
        local V1 = `V1_num' / `V1_den'
    }
    else {
        local V1 = .
    }
    
    * P-value (upper tail, normal)
    local V1_pval = 1 - normal(`V1')
    
    *--------------------------------------------------------------------------
    * V2 Test: H0: Logarithmic model (log y_t - log y_{t-1} = u_t + eta)
    *--------------------------------------------------------------------------
    
    * Estimate AR(p) model for log first differences with constant
    if `p' > 0 {
        local laglist ""
        forvalues i = 1/`p' {
            local laglist "`laglist' L`i'.`dlogy'"
        }
        qui reg `dlogy' `laglist' if `touse'
    }
    else {
        qui reg `dlogy' if `touse'
    }
    
    * Get residuals and estimate of eta
    tempvar v v2 logy_lag1
    qui predict double `v' if `touse', resid
    qui gen double `v2' = `v'^2 if `touse'
    
    * Calculate sample variance of residuals
    qui sum `v2' if `touse'
    local w2 = r(mean)
    local w = sqrt(`w2')
    
    * Calculate estimated drift
    qui sum `dlogy' if `touse'
    local h = r(mean)
    if `p' > 0 {
        local b1_sum = 0
        matrix b = e(b)
        local ncols = colsof(b)
        forvalues i = 1/`p' {
            local b1_sum = `b1_sum' + b[1,`i']
        }
        local h = `h' / (1 - `b1_sum')
    }
    
    * Create lagged log level
    qui gen double `logy_lag1' = L.`logy' if `touse'
    
    * Calculate V2 statistic
    * V2 = n^{-3/2} * sum((-log y_{t-1}) * (v_t^2 - w^2)) / sqrt(w^4 * h^2 / 6)
    
    tempvar v2_term
    qui gen double `v2_term' = (-`logy_lag1') * (`v2' - `w2') if `touse'
    qui sum `v2_term' if `touse'
    local sum_v2 = r(sum)
    
    local V2_num = `n'^(-1.5) * `sum_v2'
    local V2_den = sqrt(`w'^4 * `h'^2 / 6)
    
    if `V2_den' > 0 {
        local V2 = `V2_num' / `V2_den'
    }
    else {
        local V2 = .
    }
    
    * P-value (upper tail, normal)
    local V2_pval = 1 - normal(`V2')
    
    * Return results
    return scalar V1 = `V1'
    return scalar V1_pval = `V1_pval'
    return scalar V2 = `V2'
    return scalar V2_pval = `V2_pval'
    return scalar mu_hat = `m'
    return scalar eta_hat = `h'
    return scalar sigma_hat = `s'
    return scalar omega_hat = `w'
    
end

*------------------------------------------------------------------------------
* Subroutine: Tests WITHOUT drift (U1 and U2)
*------------------------------------------------------------------------------
program define _kmtest_nodrift, rclass
    version 14.0
    syntax varname(ts) [if] [in], [Lags(integer 0) DETail]
    
    marksample touse
    local y `varlist'
    local p = `lags'
    
    * Get sample size
    qui count if `touse'
    local n = r(N)
    
    * Create first difference
    tempvar dy logy dlogy
    qui gen double `dy' = D.`y' if `touse'
    qui gen double `logy' = ln(`y') if `touse'
    qui gen double `dlogy' = D.`logy' if `touse'
    
    *--------------------------------------------------------------------------
    * U1 Test: H0: Linear model without drift
    *--------------------------------------------------------------------------
    
    * Estimate AR(p) model for first differences WITHOUT constant
    if `p' > 0 {
        local laglist ""
        forvalues i = 1/`p' {
            local laglist "`laglist' L`i'.`dy'"
        }
        qui reg `dy' `laglist' if `touse', noconstant
        
        * Calculate a(1) = 1 - a_1 - ... - a_p
        local a1_sum = 0
        matrix b = e(b)
        forvalues i = 1/`p' {
            local a1_sum = `a1_sum' + b[1,`i']
        }
        local a1 = 1 - `a1_sum'
    }
    else {
        qui reg `dy' if `touse', noconstant
        local a1 = 1
    }
    
    * Get residuals
    tempvar z z2 y_lag1 y0
    qui predict double `z' if `touse', resid
    qui gen double `z2' = `z'^2 if `touse'
    
    * Calculate sample variance of residuals
    qui sum `z2' if `touse'
    local s2 = r(mean)
    local s = sqrt(`s2')
    
    * Get initial value y_0
    qui sum `y' if `touse'
    local y0_val = r(min)  // Approximate initial value
    
    * Create lagged level minus initial value
    qui gen double `y_lag1' = L.`y' - `y0_val' if `touse'
    
    * Calculate U1 statistic
    * U1 = n^{-1} * sum(y_{t-1} * (z_t^2 - s^2)) / (sqrt(2) * a(1)^{-1} * s^3)
    
    tempvar u1_term
    qui gen double `u1_term' = `y_lag1' * (`z2' - `s2') if `touse'
    qui sum `u1_term' if `touse'
    local sum_u1 = r(sum)
    
    local U1_num = `n'^(-1) * `sum_u1'
    local U1_den = sqrt(2) * (1/`a1') * `s'^3
    
    if `U1_den' != 0 {
        local U1 = `U1_num' / `U1_den'
    }
    else {
        local U1 = .
    }
    
    *--------------------------------------------------------------------------
    * U2 Test: H0: Logarithmic model without drift
    *--------------------------------------------------------------------------
    
    * Estimate AR(p) model for log first differences WITHOUT constant
    if `p' > 0 {
        local laglist ""
        forvalues i = 1/`p' {
            local laglist "`laglist' L`i'.`dlogy'"
        }
        qui reg `dlogy' `laglist' if `touse', noconstant
        
        * Calculate b(1) = 1 - b_1 - ... - b_p
        local b1_sum = 0
        matrix b = e(b)
        forvalues i = 1/`p' {
            local b1_sum = `b1_sum' + b[1,`i']
        }
        local b1 = 1 - `b1_sum'
    }
    else {
        qui reg `dlogy' if `touse', noconstant
        local b1 = 1
    }
    
    * Get residuals
    tempvar v v2 logy_lag1 logy0
    qui predict double `v' if `touse', resid
    qui gen double `v2' = `v'^2 if `touse'
    
    * Calculate sample variance of residuals
    qui sum `v2' if `touse'
    local w2 = r(mean)
    local w = sqrt(`w2')
    
    * Get initial value log(y_0)
    qui sum `logy' if `touse'
    local logy0_val = r(min)  // Approximate initial value
    
    * Create lagged log level minus initial value
    qui gen double `logy_lag1' = L.`logy' - `logy0_val' if `touse'
    
    * Calculate U2 statistic
    * U2 = n^{-1} * sum((-log y_{t-1}) * (v_t^2 - w^2)) / (sqrt(2) * b(1)^{-1} * w^3)
    
    tempvar u2_term
    qui gen double `u2_term' = (-`logy_lag1') * (`v2' - `w2') if `touse'
    qui sum `u2_term' if `touse'
    local sum_u2 = r(sum)
    
    local U2_num = `n'^(-1) * `sum_u2'
    local U2_den = sqrt(2) * (1/`b1') * `w'^3
    
    if `U2_den' != 0 {
        local U2 = `U2_num' / `U2_den'
    }
    else {
        local U2 = .
    }
    
    * Return results
    return scalar U1 = `U1'
    return scalar U2 = `U2'
    return scalar sigma_hat = `s'
    return scalar omega_hat = `w'
    
end

*------------------------------------------------------------------------------
* Subroutine: Approximate p-value for nonstandard distribution
*------------------------------------------------------------------------------
program define _kmtest_pval_nodrift, rclass
    version 14.0
    args stat
    
    * Critical values from Table 1 of Kobayashi & McAleer (1999)
    * 10%: 0.477, 5%: 0.664, 1%: 1.116
    
    * Use linear interpolation for approximate p-values
    if `stat' < 0.477 {
        * p-value > 0.10
        local pval = 0.10 + (0.477 - `stat') * 0.5
        if `pval' > 0.99 local pval = 0.99
    }
    else if `stat' < 0.664 {
        * 0.05 < p-value < 0.10
        local pval = 0.05 + (0.664 - `stat') / (0.664 - 0.477) * 0.05
    }
    else if `stat' < 1.116 {
        * 0.01 < p-value < 0.05
        local pval = 0.01 + (1.116 - `stat') / (1.116 - 0.664) * 0.04
    }
    else {
        * p-value < 0.01
        local pval = 0.01 * exp(-(`stat' - 1.116))
        if `pval' < 0.001 local pval = 0.001
    }
    
    return scalar pval = `pval'
end

*------------------------------------------------------------------------------
* Subroutine: Generate diagnostic graphs
*------------------------------------------------------------------------------
program define _kmtest_graph
    version 14.0
    syntax varname(ts) [if] [in], [SAVEgraph(string)]
    
    marksample touse
    local y `varlist'
    
    preserve
    qui keep if `touse'
    
    * Create log variable
    tempvar logy
    qui gen double `logy' = ln(`y')
    
    * Create combined graph
    graph combine ///
        (tsline `y', title("Level: `y'") ytitle("`y'") xtitle("Time")) ///
        (tsline `logy', title("Log: ln(`y')") ytitle("ln(`y')") xtitle("Time")), ///
        cols(1) title("Comparison of Linear and Logarithmic Transformations") ///
        note("Source: Kobayashi-McAleer Test")
    
    if "`savegraph'" != "" {
        graph export "`savegraph'", replace
    }
    
    restore
end
