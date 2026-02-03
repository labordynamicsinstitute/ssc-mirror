*! boundedur v1.0.0 Dr. Merwan Roudane 02Feb2026
*! Unit root tests for bounded time series (Cavaliere & Xu, 2014)
*! Email: merwanroudane920@gmail.com
*! Reference: Cavaliere, G., Xu, F. (2014). Testing for unit roots in bounded time series.
*!            Journal of Econometrics 178, 259-272.

program define boundedur, rclass
    version 14.0
    
    syntax varname(ts) [if] [in], ///
        lbound(real) ///
        [ubound(real 999999)] ///
        [test(string)] ///
        [lags(integer -1)] ///
        [maxlag(integer -1)] ///
        [nsim(integer 499)] ///
        [nstep(integer -1)] ///
        [recolor] ///
        [krclag(integer -1)] ///
        [level(cilevel)] ///
        [detrend(string)] ///
        [nosimulation] ///
        [seed(integer -1)] ///
        [savesim(string)]
    
    * Display header
    di _n as text "{title:Bounded Unit Root Tests}"
    di as text "{hline 78}"
    di as text "Reference: Cavaliere & Xu (2014), Journal of Econometrics 178, 259-272"
    di as text "{hline 78}"
    
    * Mark sample
    marksample touse
    _ts tvar panvar if `touse', sort onepanel
    markout `touse' `tvar'
    
    * CRITICAL: Correct syntax for tsset (from lessons learned)
    * NO EQUALS SIGN for string r() results!
    qui tsset
    local timevar `r(timevar)'
    local panelvar `r(panelvar)'
    
    * Check for panel data
    if "`panelvar'" != "" {
        di as error "Panel data not supported. Please use single time series."
        exit 198
    }
    
    if "`timevar'" == "" {
        di as error "Time variable not set. Use {cmd:tsset} first."
        exit 111
    }
    
    * Count observations
    qui count if `touse'
    local N = r(N)
    
    if `N' < 10 {
        di as error "Insufficient observations (minimum 10 required)"
        exit 2001
    }
    
    * Validate bounds
    if `lbound' >= `ubound' & `ubound' != 999999 {
        di as error "Lower bound must be less than upper bound"
        exit 198
    }
    
    * Check if variable respects bounds
    qui summarize `varlist' if `touse'
    local vmin = r(min)
    local vmax = r(max)
    
    if `vmin' < `lbound' {
        di as error "Variable minimum (`vmin') is below lower bound (`lbound')"
        exit 198
    }
    
    if `ubound' != 999999 & `vmax' > `ubound' {
        di as error "Variable maximum (`vmax') is above upper bound (`ubound')"
        exit 198
    }
    
    * Default test type
    if "`test'" == "" local test "all"
    
    * Validate test option
    local test = lower("`test'")
    local validtests "adf adfalpha adft mzalpha mzt msb all"
    local testok = 0
    foreach vt of local validtests {
        if "`test'" == "`vt'" {
            local testok = 1
        }
    }
    if !`testok' {
        di as error "Invalid test type. Valid options: adf, adfalpha, adft, mzalpha, mzt, msb, all"
        exit 198
    }
    
    * Default detrend
    if "`detrend'" == "" local detrend "constant"
    local detrend = lower("`detrend'")
    
    * Validate detrend
    if !inlist("`detrend'", "constant", "none") {
        di as error "Invalid detrend option. Use 'constant' or 'none'"
        exit 198
    }
    
    * Set seed if specified
    if `seed' > 0 {
        set seed `seed'
    }
    
    * Set maxlag default (Ng & Perron 2001: k <= 12*(T/100)^0.25)
    if `maxlag' == -1 {
        local maxlag = floor(12 * (`N'/100)^0.25)
    }
    
    * Set nstep default
    if `nstep' == -1 {
        if "`nosimulation'" != "" {
            local nstep = 0
        }
        else {
            local nstep = `N'  // Paper recommends n=T for finite samples
        }
    }
    
    * Display test configuration
    di _n as text "{bf:Test Configuration:}"
    di as text "  Variable: " as result "`varlist'"
    di as text "  Time variable: " as result "`timevar'"
    di as text "  Observations: " as result `N'
    if `ubound' != 999999 {
        di as text "  Bounds: [" as result `lbound' as text ", " as result `ubound' as text "]"
    }
    else {
        di as text "  Lower bound: " as result `lbound' as text " (one-sided)"
    }
    di as text "  Detrending: " as result "`detrend'"
    
    * Lag selection using MAIC criterion (Ng & Perron 2001)
    if `lags' == -1 {
        tempname lagsel
        _boundedur_lagselect `varlist' if `touse', ///
            maxlag(`maxlag') ///
            detrend(`detrend')
        local lags = r(maic_lag)
        di as text "  Lags (MAIC): " as result `lags'
    }
    else {
        di as text "  Lags (user): " as result `lags'
    }
    
    * Set krclag for recoloring
    if `krclag' == -1 {
        local krclag = `lags'
    }
    
    * Estimate long-run variance using spectral AR estimator (Equation 3.8)
    tempname sigma2_lr alpha1_hat
    _boundedur_lrvar `varlist' if `touse', ///
        lags(`lags') ///
        detrend(`detrend')
    scalar `sigma2_lr' = r(sigma2_lr)
    scalar `alpha1_hat' = r(alpha1_hat)
    
    * Estimate bound parameters c and c_bar (Equation 4.10)
    tempname c_lower c_upper
    
    * Use X0 as initial value (under null hypothesis)
    qui sum `varlist' if `touse'
    local X0 = r(mean) 
    
    * Compute standardized bound parameters
    scalar `c_lower' = (`lbound' - `X0') / (sqrt(`sigma2_lr') * sqrt(`N'))
    
    if `ubound' != 999999 {
        scalar `c_upper' = (`ubound' - `X0') / (sqrt(`sigma2_lr') * sqrt(`N'))
    }
    else {
        scalar `c_upper' = .  // Infinity for one-sided bound
    }
    
    di as text "  Estimated c_lower: " as result %7.4f `c_lower'
    if `ubound' != 999999 {
        di as text "  Estimated c_upper: " as result %7.4f `c_upper'
    }
    di as text "  Long-run variance: " as result %9.6f `sigma2_lr'
    di as text "  alpha(1) estimate: " as result %9.6f `alpha1_hat'
    
    * Storage for results
    tempname test_stat pval
    
    * Initialize result matrix
    matrix define boundedur_results = J(6, 3, .)
    matrix colnames boundedur_results = Statistic p_value CV_5pct
    matrix rownames boundedur_results = ADF_alpha ADF_t MZ_alpha MZ_t MSB_test Standard
    
    local row = 1
    
    * Run ADF_alpha test
    if inlist("`test'", "adf", "adfalpha", "all") {
        if "`nosimulation'" == "" {
            _boundedur_adf `varlist' if `touse', ///
                lags(`lags') ///
                clower(`=`c_lower'') ///
                cupper(`=`c_upper'') ///
                nsim(`nsim') ///
                nstep(`nstep') ///
                detrend(`detrend') ///
                stat(alpha) ///
                krclag(`krclag') ///
                `recolor'
            
            scalar `test_stat' = r(adf_alpha)
            scalar `pval' = r(pval)
            
            matrix boundedur_results[1,1] = `test_stat'
            matrix boundedur_results[1,2] = `pval'
            
            return scalar adf_alpha = `test_stat'
            return scalar pval_adf_alpha = `pval'
        }
        else {
            _boundedur_adf `varlist' if `touse', ///
                lags(`lags') ///
                detrend(`detrend') ///
                stat(alpha) ///
                nosimulation
            
            scalar `test_stat' = r(adf_alpha)
            matrix boundedur_results[1,1] = `test_stat'
            return scalar adf_alpha = `test_stat'
        }
    }
    
    * Run ADF_t test
    if inlist("`test'", "adf", "adft", "all") {
        if "`nosimulation'" == "" {
            _boundedur_adf `varlist' if `touse', ///
                lags(`lags') ///
                clower(`=`c_lower'') ///
                cupper(`=`c_upper'') ///
                nsim(`nsim') ///
                nstep(`nstep') ///
                detrend(`detrend') ///
                stat(t) ///
                krclag(`krclag') ///
                `recolor'
            
            scalar `test_stat' = r(adf_t)
            scalar `pval' = r(pval)
            
            matrix boundedur_results[2,1] = `test_stat'
            matrix boundedur_results[2,2] = `pval'
            
            return scalar adf_t = `test_stat'
            return scalar pval_adf_t = `pval'
        }
        else {
            _boundedur_adf `varlist' if `touse', ///
                lags(`lags') ///
                detrend(`detrend') ///
                stat(t) ///
                nosimulation
            
            scalar `test_stat' = r(adf_t)
            matrix boundedur_results[2,1] = `test_stat'
            return scalar adf_t = `test_stat'
        }
    }
    
    * Run MZ_alpha test
    if inlist("`test'", "mzalpha", "all") {
        if "`nosimulation'" == "" {
            _boundedur_m `varlist' if `touse', ///
                lags(`lags') ///
                clower(`=`c_lower'') ///
                cupper(`=`c_upper'') ///
                nsim(`nsim') ///
                nstep(`nstep') ///
                detrend(`detrend') ///
                test(mzalpha) ///
                sigma2(`=`sigma2_lr'')
            
            scalar `test_stat' = r(mz_alpha)
            scalar `pval' = r(pval)
            
            matrix boundedur_results[3,1] = `test_stat'
            matrix boundedur_results[3,2] = `pval'
            
            return scalar mz_alpha = `test_stat'
            return scalar pval_mz_alpha = `pval'
        }
        else {
            _boundedur_m `varlist' if `touse', ///
                lags(`lags') ///
                detrend(`detrend') ///
                test(mzalpha) ///
                sigma2(`=`sigma2_lr'') ///
                nosimulation
            
            scalar `test_stat' = r(mz_alpha)
            matrix boundedur_results[3,1] = `test_stat'
            return scalar mz_alpha = `test_stat'
        }
    }
    
    * Run MZ_t test
    if inlist("`test'", "mzt", "all") {
        if "`nosimulation'" == "" {
            _boundedur_m `varlist' if `touse', ///
                lags(`lags') ///
                clower(`=`c_lower'') ///
                cupper(`=`c_upper'') ///
                nsim(`nsim') ///
                nstep(`nstep') ///
                detrend(`detrend') ///
                test(mzt) ///
                sigma2(`=`sigma2_lr'')
            
            scalar `test_stat' = r(mz_t)
            scalar `pval' = r(pval)
            
            matrix boundedur_results[4,1] = `test_stat'
            matrix boundedur_results[4,2] = `pval'
            
            return scalar mz_t = `test_stat'
            return scalar pval_mz_t = `pval'
        }
        else {
            _boundedur_m `varlist' if `touse', ///
                lags(`lags') ///
                detrend(`detrend') ///
                test(mzt) ///
                sigma2(`=`sigma2_lr'') ///
                nosimulation
            
            scalar `test_stat' = r(mz_t)
            matrix boundedur_results[4,1] = `test_stat'
            return scalar mz_t = `test_stat'
        }
    }
    
    * Run MSB test
    if inlist("`test'", "msb", "all") {
        if "`nosimulation'" == "" {
            _boundedur_m `varlist' if `touse', ///
                lags(`lags') ///
                clower(`=`c_lower'') ///
                cupper(`=`c_upper'') ///
                nsim(`nsim') ///
                nstep(`nstep') ///
                detrend(`detrend') ///
                test(msb) ///
                sigma2(`=`sigma2_lr'')
            
            scalar `test_stat' = r(msb)
            scalar `pval' = r(pval)
            
            matrix boundedur_results[5,1] = `test_stat'
            matrix boundedur_results[5,2] = `pval'
            
            return scalar msb = `test_stat'
            return scalar pval_msb = `pval'
        }
        else {
            _boundedur_m `varlist' if `touse', ///
                lags(`lags') ///
                detrend(`detrend') ///
                test(msb) ///
                sigma2(`=`sigma2_lr'') ///
                nosimulation
            
            scalar `test_stat' = r(msb)
            matrix boundedur_results[5,1] = `test_stat'
            return scalar msb = `test_stat'
        }
    }
    
    * Display results
    di _n as text "{bf:Test Results:}"
    di as text "{hline 78}"
    
    if "`nosimulation'" == "" {
        di as text _col(20) "Statistic" _col(35) "p-value" _col(50) "Decision (5%)"
        di as text "{hline 78}"
        
        if !missing(boundedur_results[1,1]) {
            local dec1 = cond(boundedur_results[1,2] < 0.05, "Reject H0", "Fail to reject")
            di as text "ADF_alpha" _col(20) as result %10.4f boundedur_results[1,1] ///
                _col(35) %8.4f boundedur_results[1,2] _col(50) "`dec1'"
        }
        
        if !missing(boundedur_results[2,1]) {
            local dec2 = cond(boundedur_results[2,2] < 0.05, "Reject H0", "Fail to reject")
            di as text "ADF_t" _col(20) as result %10.4f boundedur_results[2,1] ///
                _col(35) %8.4f boundedur_results[2,2] _col(50) "`dec2'"
        }
        
        if !missing(boundedur_results[3,1]) {
            local dec3 = cond(boundedur_results[3,2] < 0.05, "Reject H0", "Fail to reject")
            di as text "MZ_alpha" _col(20) as result %10.4f boundedur_results[3,1] ///
                _col(35) %8.4f boundedur_results[3,2] _col(50) "`dec3'"
        }
        
        if !missing(boundedur_results[4,1]) {
            local dec4 = cond(boundedur_results[4,2] < 0.05, "Reject H0", "Fail to reject")
            di as text "MZ_t" _col(20) as result %10.4f boundedur_results[4,1] ///
                _col(35) %8.4f boundedur_results[4,2] _col(50) "`dec4'"
        }
        
        if !missing(boundedur_results[5,1]) {
            local dec5 = cond(boundedur_results[5,2] < 0.05, "Reject H0", "Fail to reject")
            di as text "MSB" _col(20) as result %10.4f boundedur_results[5,1] ///
                _col(35) %8.4f boundedur_results[5,2] _col(50) "`dec5'"
        }
    }
    else {
        di as text _col(20) "Statistic"
        di as text "{hline 78}"
        
        if !missing(boundedur_results[1,1]) {
            di as text "ADF_alpha" _col(20) as result %10.4f boundedur_results[1,1]
        }
        
        if !missing(boundedur_results[2,1]) {
            di as text "ADF_t" _col(20) as result %10.4f boundedur_results[2,1]
        }
        
        if !missing(boundedur_results[3,1]) {
            di as text "MZ_alpha" _col(20) as result %10.4f boundedur_results[3,1]
        }
        
        if !missing(boundedur_results[4,1]) {
            di as text "MZ_t" _col(20) as result %10.4f boundedur_results[4,1]
        }
        
        if !missing(boundedur_results[5,1]) {
            di as text "MSB" _col(20) as result %10.4f boundedur_results[5,1]
        }
    }
    
    di as text "{hline 78}"
    di as text "H0: Unit root with bounds at [`lbound', " ///
        cond(`ubound'==999999, "inf", string(`ubound')) "]"
    
    if "`nosimulation'" == "" {
        di as text "p-values computed using " `nsim' " Monte Carlo replications"
        di as text "Discretization steps: " `nstep'
        if "`recolor'" != "" {
            di as text "Re-coloring device applied (krc=" `krclag' ")"
        }
    }
    
    * Return results
    return scalar N = `N'
    return scalar lags = `lags'
    return scalar c_lower = `c_lower'
    return scalar c_upper = `c_upper'
    return scalar sigma2_lr = `sigma2_lr'
    return scalar lbound = `lbound'
    return scalar ubound = `ubound'
    return local timevar "`timevar'"
    return local depvar "`varlist'"
    return local detrend "`detrend'"
    return matrix results = boundedur_results
    
end

*==============================================================================
* Subroutine: MAIC lag selection (Ng & Perron 2001)
*==============================================================================
program define _boundedur_lagselect, rclass
    syntax varlist(max=1 ts) [if] [in], maxlag(integer) [detrend(string)]
    
    marksample touse
    
    if "`detrend'" == "" local detrend "constant"
    
    tempname maic bestlag
    scalar `maic' = .
    scalar `bestlag' = 0
    
    forvalues k = 0/`maxlag' {
        * Run ADF regression with k lags
        if "`detrend'" == "constant" {
            qui reg D.`varlist' L.`varlist' LD(1/`k').D.`varlist' if `touse'
        }
        else {
            qui reg D.`varlist' L.`varlist' LD(1/`k').D.`varlist' if `touse', nocons
        }
        
        local N_k = e(N)
        local sigma2_k = e(rss) / `N_k'
        local tau_k = 2 * (`k' + 1) / `N_k'
        
        local maic_k = ln(`sigma2_k') + `tau_k'
        
        if `maic_k' < `maic' | `k' == 0 {
            scalar `maic' = `maic_k'
            scalar `bestlag' = `k'
        }
    }
    
    return scalar maic_lag = `bestlag'
    return scalar maic = `maic'
end

*==============================================================================
* Subroutine: Long-run variance estimation (spectral AR, Equation 3.8)
*==============================================================================
program define _boundedur_lrvar, rclass
    syntax varlist(max=1 ts) [if] [in], lags(integer) [detrend(string)]
    
    marksample touse
    
    if "`detrend'" == "" local detrend "constant"
    
    * Run ADF regression to get residual variance and alpha(1)
    if `lags' > 0 {
        if "`detrend'" == "constant" {
            qui reg D.`varlist' L.`varlist' LD(1/`lags').D.`varlist' if `touse'
        }
        else {
            qui reg D.`varlist' L.`varlist' LD(1/`lags').D.`varlist' if `touse', nocons
        }
        
        * Get coefficients on lagged differences
        tempname alpha1
        scalar `alpha1' = 1
        forvalues i = 1/`lags' {
            scalar `alpha1' = `alpha1' - _b[LD`i'.D.`varlist']
        }
    }
    else {
        if "`detrend'" == "constant" {
            qui reg D.`varlist' L.`varlist' if `touse'
        }
        else {
            qui reg D.`varlist' L.`varlist' if `touse', nocons
        }
        
        tempname alpha1
        scalar `alpha1' = 1
    }
    
    * Residual variance
    local sigma2 = e(rss) / e(N)
    
    * Long-run variance estimate: sigma^2 / alpha(1)^2
    local sigma2_lr = `sigma2' / (`alpha1'^2)
    
    return scalar sigma2_lr = `sigma2_lr'
    return scalar alpha1_hat = `alpha1'
    return scalar sigma2 = `sigma2'
end
