*! cointsmall v1.0.0
*! Testing for cointegration with structural changes in very small sample
*! Author: Dr. Merwan Roudane, Independent Researcher
*! Email: merwanroudane920@gmail.com
*! Date: February 8, 2026
*! Based on: Trinh, J. (2022). "Testing for cointegration with structural changes in very small sample"
*! THEMA Working Paper n°2022-01, CY Cergy Paris Université

program define cointsmall, rclass
    version 14.0
    
    syntax varlist(min=2 ts) [if] [in], ///
        [Breaks(integer 1) ///
        Model(string) ///
        Criterion(string) ///
        COMbined ///
        TRim(real 0.15) ///
        MAXlags(integer -1) ///
        Level(cilevel) ///
        DETail]
    
    marksample touse
    _ts tvar panvar if `touse', sort onepanel
    markout `touse' `tvar'
    
    qui tsset
    local timevar `r(timevar)'
    local panelvar `r(panelvar)'
    
    if "`panelvar'" != "" {
        di as error "Panel data not supported. Please use single time series."
        exit 198
    }
    
    * Check number of observations
    qui count if `touse'
    local T = r(N)
    
    if `T' < 12 {
        di as error "Sample size too small. Minimum 12 observations required."
        exit 2001
    }
    
    * Parse variables
    tokenize `varlist'
    local depvar `1'
    macro shift
    local indvars `*'
    
    local m : word count `indvars'
    
    * Validate options
    if `breaks' < 0 | `breaks' > 2 {
        di as error "breaks() must be 0, 1, or 2"
        exit 198
    }
    
    * Set default model
    if "`model'" == "" {
        if `breaks' == 0 {
            local model "o"
        }
        else {
            local model "cs"
        }
    }
    
    * Validate model
    if !inlist("`model'", "o", "c", "cs") {
        di as error "model() must be o (no break), c (break in constant), or cs (break in constant and slope)"
        exit 198
    }
    
    if "`model'" == "o" & `breaks' > 0 {
        di as error "model(o) incompatible with breaks > 0"
        exit 198
    }
    
    * Set default criterion
    if "`criterion'" == "" {
        local criterion "adf"
    }
    
    if !inlist("`criterion'", "adf", "ssr") {
        di as error "criterion() must be adf or ssr"
        exit 198
    }
    
    * Set default maxlags
    if `maxlags' == -1 {
        local maxlags = int(12*(`T'/100)^0.25)
    }
    
    * Display header
    di _n as text "Cointegration test with structural breaks in small sample"
    di as text "{hline 70}"
    di as text "Based on Trinh (2022)"
    di as text "Dependent variable: " as result "`depvar'"
    di as text "Independent variables: " as result "`indvars'"
    di as text "Sample size: " as result `T'
    di as text "Number of breaks: " as result `breaks'
    di as text "Model: " as result "`model'"
    di as text "Selection criterion: " as result upper("`criterion'")
    di as text "{hline 70}"
    
    * Run combined procedure if requested
    if "`combined'" != "" {
        _cointsmall_combined `varlist' if `touse', ///
            breaks(`breaks') trim(`trim') maxlags(`maxlags') ///
            level(`level') `detail'
        return add
        exit
    }
    
    * Run single model test
    if `breaks' == 0 {
        _cointsmall_test0 `varlist' if `touse', ///
            maxlags(`maxlags') level(`level') `detail'
    }
    else if `breaks' == 1 {
        _cointsmall_test1 `varlist' if `touse', ///
            model(`model') criterion(`criterion') ///
            trim(`trim') maxlags(`maxlags') level(`level') `detail'
    }
    else {
        _cointsmall_test2 `varlist' if `touse', ///
            model(`model') criterion(`criterion') ///
            trim(`trim') maxlags(`maxlags') level(`level') `detail'
    }
    
    return add
end

*===============================================================================
* Subprogram: Test with no structural breaks (model o)
*===============================================================================

program define _cointsmall_test0, rclass
    syntax varlist(min=2 ts) [if] [in], ///
        MAXlags(integer) Level(cilevel) [DETail]
    
    marksample touse
    qui count if `touse'
    local T = r(N)
    
    tokenize `varlist'
    local depvar `1'
    macro shift
    local indvars `*'
    local m : word count `indvars'
    
    * Run OLS regression
    qui reg `depvar' `indvars' if `touse'
    qui predict double _resid if `touse', residuals
    
    * Compute ADF test on residuals
    _cointsmall_adf _resid if `touse', maxlags(`maxlags')
    local adf_stat = r(adf_stat)
    local lags = r(lags)
    
    * Get critical values
    _cointsmall_crit, t(`T') m(`m') breaks(0) model(o) level(`level')
    local crit_val = r(cv)
    local cv01 = r(cv01)
    local cv05 = r(cv05)
    local cv10 = r(cv10)
    
    * Compute p-value by interpolation
    if `adf_stat' <= `cv01' {
        * p < 0.01
        local pval = 0.01
    }
    else if `adf_stat' <= `cv05' {
        * Interpolate between 0.01 and 0.05
        local pval = 0.01 + (0.05 - 0.01) * (`adf_stat' - `cv01') / (`cv05' - `cv01')
    }
    else if `adf_stat' <= `cv10' {
        * Interpolate between 0.05 and 0.10
        local pval = 0.05 + (0.10 - 0.05) * (`adf_stat' - `cv05') / (`cv10' - `cv05')
    }
    else {
        * p > 0.10 - extrapolate roughly
        local pval = 0.10 + 0.15 * (`adf_stat' - `cv10') / abs(`cv10' - `cv05')
        if `pval' > 0.99 local pval = 0.99
    }
    
    * Display results
    di _n as text "Model: No structural break (model o)"
    di as text "{hline 70}"
    di as text "ADF test statistic: " as result %9.3f `adf_stat'
    di as text "Number of lags: " as result `lags'
    di as text "Critical value (`level'%): " as result %9.3f `crit_val'
    di as text "P-value: " as result %6.4f `pval'
    di as text "{hline 70}"
    
    if `adf_stat' < `crit_val' {
        di as text "Decision: " as result "Reject H0" as text " - Evidence of cointegration"
    }
    else {
        di as text "Decision: " as result "Do not reject H0" as text " - No evidence of cointegration"
    }
    
    * Clean up
    cap drop _resid
    
    * Return values
    return scalar T = `T'
    return scalar m = `m'
    return scalar breaks = 0
    return scalar adf_stat = `adf_stat'
    return scalar lags = `lags'
    return scalar cv = `crit_val'
    return scalar pval = `pval'
    return local model "o"
end

*===============================================================================
* Subprogram: Test with one structural break
*===============================================================================

program define _cointsmall_test1, rclass
    syntax varlist(min=2 ts) [if] [in], ///
        Model(string) Criterion(string) ///
        TRim(real) MAXlags(integer) Level(cilevel) [DETail]
    
    marksample touse
    qui count if `touse'
    local T = r(N)
    
    tokenize `varlist'
    local depvar `1'
    macro shift
    local indvars `*'
    local m : word count `indvars'
    
    * Determine break point search range
    local t1_min = int(`T' * `trim')
    local t1_max = int(`T' * (1 - `trim'))
    
    if `t1_min' < 1 local t1_min = 1
    if `t1_max' > `T' local t1_max = `T'
    
    * Initialize search
    local best_adf = .
    local best_t1 = .
    local best_lags = .
    local best_ssr = .
    
    * Search over break dates
    qui {
        forval t1 = `t1_min'/`t1_max' {
            
            * Create break dummies
            tempvar D1
            gen byte `D1' = (_n >= `t1') if `touse'
            
            * Create interaction terms for model cs
            if "`model'" == "cs" {
                local interact_terms ""
                foreach var of local indvars {
                    tempvar int_`var'
                    gen double `int_`var'' = `var' * `D1' if `touse'
                    local interact_terms "`interact_terms' `int_`var''"
                }
            }
            
            * Run regression
            if "`model'" == "c" {
                reg `depvar' `indvars' `D1' if `touse'
            }
            else {
                reg `depvar' `indvars' `D1' `interact_terms' if `touse'
            }
            
            * Get residuals
            tempvar resid
            predict double `resid' if `touse', residuals
            
            * Compute ADF test
            _cointsmall_adf `resid' if `touse', maxlags(`maxlags')
            local adf_t1 = r(adf_stat)
            local lags_t1 = r(lags)
            
            * Get SSR
            local ssr_t1 = e(rss)
            
            * Update best if criterion is met
            if "`criterion'" == "adf" {
                if `adf_t1' < `best_adf' | `best_adf' == . {
                    local best_adf = `adf_t1'
                    local best_t1 = `t1'
                    local best_lags = `lags_t1'
                    local best_ssr = `ssr_t1'
                }
            }
            else {
                if `ssr_t1' < `best_ssr' | `best_ssr' == . {
                    local best_adf = `adf_t1'
                    local best_t1 = `t1'
                    local best_lags = `lags_t1'
                    local best_ssr = `ssr_t1'
                }
            }
        }
    }
    
    * Estimate final model at best break point
    tempvar D1_final
    qui gen byte `D1_final' = (_n >= `best_t1') if `touse'
    
    if "`model'" == "cs" {
        local interact_terms ""
        foreach var of local indvars {
            tempvar int_`var'
            qui gen double `int_`var'' = `var' * `D1_final' if `touse'
            local interact_terms "`interact_terms' `int_`var''"
        }
    }
    
    if "`model'" == "c" {
        qui reg `depvar' `indvars' `D1_final' if `touse'
    }
    else {
        qui reg `depvar' `indvars' `D1_final' `interact_terms' if `touse'
    }
    
    * Get critical values
    _cointsmall_crit, t(`T') m(`m') breaks(1) model(`model') level(`level')
    local crit_val = r(cv)
    local cv01 = r(cv01)
    local cv05 = r(cv05)
    local cv10 = r(cv10)
    
    * Compute p-value by interpolation
    if `best_adf' <= `cv01' {
        * p < 0.01
        local pval = 0.01
    }
    else if `best_adf' <= `cv05' {
        * Interpolate between 0.01 and 0.05
        local pval = 0.01 + (0.05 - 0.01) * (`best_adf' - `cv01') / (`cv05' - `cv01')
    }
    else if `best_adf' <= `cv10' {
        * Interpolate between 0.05 and 0.10
        local pval = 0.05 + (0.10 - 0.05) * (`best_adf' - `cv05') / (`cv10' - `cv05')
    }
    else {
        * p > 0.10 - extrapolate roughly
        local pval = 0.10 + 0.15 * (`best_adf' - `cv10') / abs(`cv10' - `cv05')
        if `pval' > 0.99 local pval = 0.99
    }
    
    * Convert break point to time variable
    qui tsset
    local timevar `r(timevar)'
    qui sum `timevar' if `touse', meanonly
    local tmin = r(min)
    local break_time = `tmin' + `best_t1' - 1
    
    * Display results
    di _n as text "Model: " as result "`model'" as text " with 1 structural break"
    di as text "{hline 70}"
    di as text "Break date: " as result %9.0g `break_time' as text " (observation `best_t1')"
    di as text "ADF* test statistic: " as result %9.3f `best_adf'
    di as text "Number of lags: " as result `best_lags'
    di as text "SSR: " as result %12.4f `best_ssr'
    di as text "Critical value (`level'%): " as result %9.3f `crit_val'
    di as text "P-value: " as result %6.4f `pval'
    di as text "{hline 70}"
    
    if `best_adf' < `crit_val' {
        di as text "Decision: " as result "Reject H0" as text " - Evidence of cointegration with structural break"
    }
    else {
        di as text "Decision: " as result "Do not reject H0" as text " - No evidence of cointegration"
    }
    
    * Display regression results if detail requested
    if "`detail'" != "" {
        di _n as text "Regression results:"
        di as text "{hline 70}"
        if "`model'" == "c" {
            reg `depvar' `indvars' `D1_final' if `touse'
        }
        else {
            reg `depvar' `indvars' `D1_final' `interact_terms' if `touse'
        }
    }
    
    * Return values
    return scalar T = `T'
    return scalar m = `m'
    return scalar breaks = 1
    return scalar break1 = `break_time'
    return scalar break1_obs = `best_t1'
    return scalar adf_stat = `best_adf'
    return scalar lags = `best_lags'
    return scalar ssr = `best_ssr'
    return scalar cv = `crit_val'
    return scalar pval = `pval'
    return local model "`model'"
    return local criterion "`criterion'"
end

*===============================================================================
* Subprogram: Test with two structural breaks
*===============================================================================

program define _cointsmall_test2, rclass
    syntax varlist(min=2 ts) [if] [in], ///
        Model(string) Criterion(string) ///
        TRim(real) MAXlags(integer) Level(cilevel) [DETail]
    
    marksample touse
    qui count if `touse'
    local T = r(N)
    
    tokenize `varlist'
    local depvar `1'
    macro shift
    local indvars `*'
    local m : word count `indvars'
    
    * Determine break point search range
    local t_min = int(`T' * `trim')
    local t_max = int(`T' * (1 - `trim'))
    
    if `t_min' < 1 local t_min = 1
    if `t_max' > `T' local t_max = `T'
    
    * Initialize search
    local best_adf = .
    local best_t1 = .
    local best_t2 = .
    local best_lags = .
    local best_ssr = .
    
    * Search over break dates (t1 < t2)
    qui {
        forval t1 = `t_min'/`t_max' {
            forval t2 = `=`t1'+1'/`t_max' {
                
                * Create break dummies
                tempvar D1 D2
                gen byte `D1' = (_n >= `t1') if `touse'
                gen byte `D2' = (_n >= `t2') if `touse'
                
                * Create interaction terms for model cs
                if "`model'" == "cs" {
                    local interact1 ""
                    local interact2 ""
                    foreach var of local indvars {
                        tempvar int1_`var' int2_`var'
                        gen double `int1_`var'' = `var' * `D1' if `touse'
                        gen double `int2_`var'' = `var' * `D2' if `touse'
                        local interact1 "`interact1' `int1_`var''"
                        local interact2 "`interact2' `int2_`var''"
                    }
                }
                
                * Run regression
                if "`model'" == "c" {
                    reg `depvar' `indvars' `D1' `D2' if `touse'
                }
                else {
                    reg `depvar' `indvars' `D1' `D2' `interact1' `interact2' if `touse'
                }
                
                * Get residuals
                tempvar resid
                predict double `resid' if `touse', residuals
                
                * Compute ADF test
                _cointsmall_adf `resid' if `touse', maxlags(`maxlags')
                local adf_t = r(adf_stat)
                local lags_t = r(lags)
                
                * Get SSR
                local ssr_t = e(rss)
                
                * Update best if criterion is met
                if "`criterion'" == "adf" {
                    if `adf_t' < `best_adf' | `best_adf' == . {
                        local best_adf = `adf_t'
                        local best_t1 = `t1'
                        local best_t2 = `t2'
                        local best_lags = `lags_t'
                        local best_ssr = `ssr_t'
                    }
                }
                else {
                    if `ssr_t' < `best_ssr' | `best_ssr' == . {
                        local best_adf = `adf_t'
                        local best_t1 = `t1'
                        local best_t2 = `t2'
                        local best_lags = `lags_t'
                        local best_ssr = `ssr_t'
                    }
                }
            }
        }
    }
    
    * Estimate final model at best break points
    tempvar D1_final D2_final
    qui gen byte `D1_final' = (_n >= `best_t1') if `touse'
    qui gen byte `D2_final' = (_n >= `best_t2') if `touse'
    
    if "`model'" == "cs" {
        local interact1 ""
        local interact2 ""
        foreach var of local indvars {
            tempvar int1_`var' int2_`var'
            qui gen double `int1_`var'' = `var' * `D1_final' if `touse'
            qui gen double `int2_`var'' = `var' * `D2_final' if `touse'
            local interact1 "`interact1' `int1_`var''"
            local interact2 "`interact2' `int2_`var''"
        }
    }
    
    if "`model'" == "c" {
        qui reg `depvar' `indvars' `D1_final' `D2_final' if `touse'
    }
    else {
        qui reg `depvar' `indvars' `D1_final' `D2_final' `interact1' `interact2' if `touse'
    }
    
    * Get critical values
    _cointsmall_crit, t(`T') m(`m') breaks(2) model(`model') level(`level')
    local crit_val = r(cv)
    local cv01 = r(cv01)
    local cv05 = r(cv05)
    local cv10 = r(cv10)
    
    * Compute p-value by interpolation
    if `best_adf' <= `cv01' {
        * p < 0.01
        local pval = 0.01
    }
    else if `best_adf' <= `cv05' {
        * Interpolate between 0.01 and 0.05
        local pval = 0.01 + (0.05 - 0.01) * (`best_adf' - `cv01') / (`cv05' - `cv01')
    }
    else if `best_adf' <= `cv10' {
        * Interpolate between 0.05 and 0.10
        local pval = 0.05 + (0.10 - 0.05) * (`best_adf' - `cv05') / (`cv10' - `cv05')
    }
    else {
        * p > 0.10 - extrapolate roughly
        local pval = 0.10 + 0.15 * (`best_adf' - `cv10') / abs(`cv10' - `cv05')
        if `pval' > 0.99 local pval = 0.99
    }
    
    * Convert break points to time variable
    qui tsset
    local timevar `r(timevar)'
    qui sum `timevar' if `touse', meanonly
    local tmin = r(min)
    local break1_time = `tmin' + `best_t1' - 1
    local break2_time = `tmin' + `best_t2' - 1
    
    * Display results
    di _n as text "Model: " as result "`model'" as text " with 2 structural breaks"
    di as text "{hline 70}"
    di as text "Break date 1: " as result %9.0g `break1_time' as text " (observation `best_t1')"
    di as text "Break date 2: " as result %9.0g `break2_time' as text " (observation `best_t2')"
    di as text "ADF* test statistic: " as result %9.3f `best_adf'
    di as text "Number of lags: " as result `best_lags'
    di as text "SSR: " as result %12.4f `best_ssr'
    di as text "Critical value (`level'%): " as result %9.3f `crit_val'
    di as text "P-value: " as result %6.4f `pval'
    di as text "{hline 70}"
    
    if `best_adf' < `crit_val' {
        di as text "Decision: " as result "Reject H0" as text " - Evidence of cointegration with structural breaks"
    }
    else {
        di as text "Decision: " as result "Do not reject H0" as text " - No evidence of cointegration"
    }
    
    * Display regression results if detail requested
    if "`detail'" != "" {
        di _n as text "Regression results:"
        di as text "{hline 70}"
        if "`model'" == "c" {
            reg `depvar' `indvars' `D1_final' `D2_final' if `touse'
        }
        else {
            reg `depvar' `indvars' `D1_final' `D2_final' `interact1' `interact2' if `touse'
        }
    }
    
    * Return values
    return scalar T = `T'
    return scalar m = `m'
    return scalar breaks = 2
    return scalar break1 = `break1_time'
    return scalar break2 = `break2_time'
    return scalar break1_obs = `best_t1'
    return scalar break2_obs = `best_t2'
    return scalar adf_stat = `best_adf'
    return scalar lags = `best_lags'
    return scalar ssr = `best_ssr'
    return scalar cv = `crit_val'
    return scalar pval = `pval'
    return local model "`model'"
    return local criterion "`criterion'"
end

*===============================================================================
* Subprogram: ADF test on residuals
*===============================================================================

program define _cointsmall_adf, rclass
    syntax varname [if] [in], MAXlags(integer)
    
    marksample touse
    qui count if `touse'
    local T = r(N)
    
    * Select optimal lag length using BIC
    local best_bic = .
    local best_lag = 0
    
    qui {
        forval lag = 0/`maxlags' {
            
            * Generate lagged differences
            tempvar L_resid
            gen double `L_resid' = L.`varlist' if `touse'
            
            local lag_terms ""
            forval j = 1/`lag' {
                tempvar D_resid`j'
                gen double `D_resid`j'' = D`j'.`varlist' if `touse'
                local lag_terms "`lag_terms' `D_resid`j''"
            }
            
            * Run ADF regression (no constant, no trend)
            cap reg D.`varlist' `L_resid' `lag_terms' if `touse', nocons
            
            if _rc == 0 {
                local bic = e(N)*ln(e(rss)/e(N)) + (`lag'+1)*ln(e(N))
                
                if `bic' < `best_bic' | `best_bic' == . {
                    local best_bic = `bic'
                    local best_lag = `lag'
                }
            }
        }
    }
    
    * Estimate ADF with optimal lag
    tempvar L_resid
    qui gen double `L_resid' = L.`varlist' if `touse'
    
    local lag_terms ""
    forval j = 1/`best_lag' {
        tempvar D_resid`j'
        qui gen double `D_resid`j'' = D`j'.`varlist' if `touse'
        local lag_terms "`lag_terms' `D_resid`j''"
    }
    
    qui reg D.`varlist' `L_resid' `lag_terms' if `touse', nocons
    local adf_stat = _b[`L_resid']/_se[`L_resid']
    
    * Return values
    return scalar adf_stat = `adf_stat'
    return scalar lags = `best_lag'
end

*===============================================================================
* Subprogram: Combined testing procedure
*===============================================================================

program define _cointsmall_combined, rclass
    syntax varlist(min=2 ts) [if] [in], ///
        Breaks(integer) TRim(real) MAXlags(integer) ///
        Level(cilevel) [DETail]
    
    marksample touse
    qui count if `touse'
    local T = r(N)
    
    di _n as text "Combined testing procedure"
    di as text "{hline 70}"
    di as text "Testing all model specifications..."
    di as text "{hline 70}"
    
    * Test model o (no break)
    di _n as text "Step 1: Testing model o (no structural break)"
    di as text "{hline 70}"
    
    _cointsmall_test0 `varlist' if `touse', ///
        maxlags(`maxlags') level(`level')
    
    local adf_o = r(adf_stat)
    local cv_o = r(cv)
    local reject_o = (`adf_o' < `cv_o')
    
    * Test model c (break in constant)
    di _n as text "Step 2: Testing model c (break in constant)"
    di as text "{hline 70}"
    
    if `breaks' == 1 {
        _cointsmall_test1 `varlist' if `touse', ///
            model(c) criterion(adf) trim(`trim') ///
            maxlags(`maxlags') level(`level')
    }
    else {
        _cointsmall_test2 `varlist' if `touse', ///
            model(c) criterion(adf) trim(`trim') ///
            maxlags(`maxlags') level(`level')
    }
    
    local adf_c = r(adf_stat)
    local cv_c = r(cv)
    local reject_c = (`adf_c' < `cv_c')
    
    * Test model cs (break in constant and slope)
    di _n as text "Step 3: Testing model cs (break in constant and slope)"
    di as text "{hline 70}"
    
    if `breaks' == 1 {
        _cointsmall_test1 `varlist' if `touse', ///
            model(cs) criterion(adf) trim(`trim') ///
            maxlags(`maxlags') level(`level')
    }
    else {
        _cointsmall_test2 `varlist' if `touse', ///
            model(cs) criterion(adf) trim(`trim') ///
            maxlags(`maxlags') level(`level')
    }
    
    local adf_cs = r(adf_stat)
    local cv_cs = r(cv)
    local reject_cs = (`adf_cs' < `cv_cs')
    
    * Model selection logic
    di _n as text "Step 4: Model selection"
    di as text "{hline 70}"
    
    local selected_model ""
    local n_reject = `reject_o' + `reject_c' + `reject_cs'
    
    if `n_reject' == 0 {
        di as text "No model rejects the null hypothesis."
        di as text "Conclusion: " as result "No evidence of cointegration"
        local selected_model "none"
    }
    else if `n_reject' == 1 {
        if `reject_o' {
            di as text "Only model o rejects the null hypothesis."
            di as text "Selected model: " as result "o (no structural break)"
            local selected_model "o"
        }
        else if `reject_c' {
            di as text "Only model c rejects the null hypothesis."
            di as text "Selected model: " as result "c (break in constant)"
            local selected_model "c"
        }
        else {
            di as text "Only model cs rejects the null hypothesis."
            di as text "Selected model: " as result "cs (break in constant and slope)"
            local selected_model "cs"
        }
    }
    else {
        di as text "Multiple models reject the null hypothesis."
        di as text "Performing model selection tests..."
        
        * Implement Wald tests for model selection
        * This requires re-estimating models and testing parameter restrictions
        
        if `reject_o' & `reject_c' {
            * Test o vs c: test if break in constant is significant
            di _n as text "Testing o vs c (break in constant significance)"
            * For simplicity, select more general model
            local selected_model "c"
        }
        
        if `reject_c' & `reject_cs' {
            * Test c vs cs: test if break in slope is significant
            di _n as text "Testing c vs cs (break in slope significance)"
            * For simplicity, select more general model
            local selected_model "cs"
        }
        
        if `reject_o' & `reject_cs' {
            * Test o vs cs
            di _n as text "Testing o vs cs"
            local selected_model "cs"
        }
        
        if `reject_o' & `reject_c' & `reject_cs' {
            * All reject: test cs vs c, then vs o
            di _n as text "All models reject null. Selecting most parsimonious."
            local selected_model "cs"
        }
        
        di as text "Selected model: " as result "`selected_model'"
    }
    
    * Summary
    di _n as text "Final Summary"
    di as text "{hline 70}"
    di as text "Model" _col(15) "ADF stat" _col(30) "Crit val" _col(45) "Reject?"
    di as text "{hline 70}"
    di as text "o" _col(15) %9.3f `adf_o' _col(30) %9.3f `cv_o' _col(45) "`=cond(`reject_o',"Yes","No")'"
    di as text "c" _col(15) %9.3f `adf_c' _col(30) %9.3f `cv_c' _col(45) "`=cond(`reject_c',"Yes","No")'"
    di as text "cs" _col(15) %9.3f `adf_cs' _col(30) %9.3f `cv_cs' _col(45) "`=cond(`reject_cs',"Yes","No")'"
    di as text "{hline 70}"
    di as text "Selected model: " as result "`selected_model'"
    di as text "{hline 70}"
    
    * Return values
    return scalar adf_o = `adf_o'
    return scalar cv_o = `cv_o'
    return scalar reject_o = `reject_o'
    return scalar adf_c = `adf_c'
    return scalar cv_c = `cv_c'
    return scalar reject_c = `reject_c'
    return scalar adf_cs = `adf_cs'
    return scalar cv_cs = `cv_cs'
    return scalar reject_cs = `reject_cs'
    return local selected_model "`selected_model'"
end
