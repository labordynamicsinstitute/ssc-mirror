*! xtpretest v1.0.0
*! Comprehensive Panel Data Pre-Testing Suite
*! Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)
*! Based on Hsiao (2014), Pesaran & Yamagata (2008), Blomquist & Westerlund (2015),
*!   Pesaran (2015), Swamy (1970), Okui & Yanagi (2019)
*! Date: March 2026
capture program drop xtpretest

program define xtpretest, rclass sortpreserve
    version 14.0
    syntax varlist(min=2 numeric ts) [if] [in], [  ///
        ALL                     /// run all tests (default)
        HSiao                   /// Hsiao homogeneity tests
        ROBust                  /// Robust HC version
        SUMmary                 /// xtsum-style tables
        HETerogeneity           /// coefficient heterogeneity tables
        SLOPEhomogeneity        /// xthst/xtbhst tests
        CSD                     /// cross-sectional dependence
        BREAKs                  /// structural breaks note
        GRaph                   /// diagnostic graphs
        NOTable                 /// suppress tables
        reps(integer 200)       /// bootstrap reps for xtbhst
        seed(integer -1)        /// random seed
        ]
    
    * =========================================================================
    * SETUP
    * =========================================================================
    qui xtset
    local panelvar "`r(panelvar)'"
    local timevar  "`r(timevar)'"
    
    tempvar touse
    marksample touse
    sort `panelvar' `timevar'
    
    * Parse varlist
    gettoken lhs rhs : varlist
    local K : word count `rhs'
    
    if `K' < 1 {
        di as error "At least one independent variable required."
        exit 198
    }
    
    * Count panels and time periods
    tempvar gid
    qui egen `gid' = group(`panelvar') if `touse'
    qui sum `gid' if `touse', meanonly
    local N = r(max)
    
    qui tab `timevar' if `touse'
    local T = r(r)
    local NT = _N
    qui count if `touse'
    local NTobs = r(N)
    
    * If no specific option, run ALL
    if "`hsiao'`robust'`summary'`heterogeneity'`slopehomogeneity'`csd'`breaks'" == "" {
        local all "all"
    }
    local run_hsiao     = ("`all'" != "" | "`hsiao'" != "")
    local run_robust    = ("`all'" != "" | "`robust'" != "")
    local run_summary   = ("`all'" != "" | "`summary'" != "")
    local run_hetero    = ("`all'" != "" | "`heterogeneity'" != "")
    local run_slope     = ("`all'" != "" | "`slopehomogeneity'" != "")
    local run_csd       = ("`all'" != "" | "`csd'" != "")
    local run_breaks    = ("`all'" != "" | "`breaks'" != "")
    local run_graph     = ("`graph'" != "")
    local run_table     = ("`notable'" == "")
    
    * Get panel IDs for individual regressions
    qui levelsof `panelvar' if `touse', local(panels)
    local npanels : word count `panels'
    
    * =========================================================================
    * HEADER
    * =========================================================================
    di as text ""
    di as text "{hline 78}"
    di as text " {bf:xtpretest} — Comprehensive Panel Data Pre-Testing Suite v1.0.0"
    di as text "{hline 78}"
    di as text " Dependent variable  : {res:`lhs'}"
    di as text " Independent vars    : {res:`rhs'}"
    di as text " Panel variable      : {res:`panelvar'}"
    di as text " Time variable       : {res:`timevar'}"
    di as text " N (panels)          : {res:`N'}"
    di as text " T (time periods)    : {res:`T'}"
    di as text " Observations        : {res:`NTobs'}"
    di as text "{hline 78}"
    
    * =========================================================================
    * MODULE 1: PANEL SUMMARY STATISTICS (xtsum-style)
    * =========================================================================
    if `run_summary' {
        di as text ""
        di as text "{hline 78}"
        di as text " {bf:MODULE 1: Panel Summary Statistics (xtsum-style decomposition)}"
        di as text "{hline 78}"
        
        if `run_table' {
            di as text ""
            di as text %14s "Variable" _col(16) %10s "Variation" ///
                _col(28) %10s "Mean" _col(40) %10s "Std.Dev" ///
                _col(52) %10s "Min" _col(64) %10s "Max"
            di as text "{hline 78}"
            
            foreach v of local varlist {
                * Overall stats
                qui sum `v' if `touse'
                local o_mean  = r(mean)
                local o_sd    = r(sd)
                local o_min   = r(min)
                local o_max   = r(max)
                
                * Between stats: variation of panel means
                tempvar pmean
                qui egen `pmean' = mean(`v') if `touse', by(`panelvar')
                qui sum `pmean' if `touse'
                local b_mean  = r(mean)
                local b_sd    = r(sd)
                local b_min   = r(min)
                local b_max   = r(max)
                
                * Within stats: deviations from panel mean + grand mean
                tempvar within
                qui gen `within' = `v' - `pmean' + `o_mean' if `touse'
                qui sum `within' if `touse'
                local w_mean  = r(mean)
                local w_sd    = r(sd)
                local w_min   = r(min)
                local w_max   = r(max)
                
                di as text %14s abbrev("`v'",14) _col(16) %10s "Overall" ///
                    _col(28) as result %10.4f `o_mean' ///
                    _col(40) as result %10.4f `o_sd' ///
                    _col(52) as result %10.4f `o_min' ///
                    _col(64) as result %10.4f `o_max'
                di as text _col(16) %10s "Between" ///
                    _col(28) as result %10s "" ///
                    _col(40) as result %10.4f `b_sd' ///
                    _col(52) as result %10.4f `b_min' ///
                    _col(64) as result %10.4f `b_max'
                di as text _col(16) %10s "Within" ///
                    _col(28) as result %10s "" ///
                    _col(40) as result %10.4f `w_sd' ///
                    _col(52) as result %10.4f `w_min' ///
                    _col(64) as result %10.4f `w_max'
                di as text "{hline 78}"
                
                drop `pmean' `within'
            }
        }
        
        * Pairwise Correlation Matrix with p-values
        if `run_table' {
            di as text ""
            di as text " {ul:Pairwise Correlation Matrix}"
            di as text ""
            
            * Header row
            di as text %14s "" _c
            foreach v of local varlist {
                di as text %12s abbrev("`v'",11) _c
            }
            di ""
            di as text "{hline 78}"
            
            * Correlation coefficients
            foreach v1 of local varlist {
                di as text %14s abbrev("`v1'",13) _c
                foreach v2 of local varlist {
                    qui correlate `v1' `v2' if `touse'
                    local rval = r(rho)
                    if abs(`rval') >= 0.7 {
                        di as error %12.4f `rval' _c
                    }
                    else if abs(`rval') >= 0.4 {
                        di as result %12.4f `rval' _c
                    }
                    else {
                        di as text %12.4f `rval' _c
                    }
                }
                di ""
            }
            di as text "{hline 78}"
            
            * P-values
            di as text ""
            di as text " {ul:Correlation P-values}"
            di as text ""
            di as text %14s "" _c
            foreach v of local varlist {
                di as text %12s abbrev("`v'",11) _c
            }
            di ""
            di as text "{hline 78}"
            
            foreach v1 of local varlist {
                di as text %14s abbrev("`v1'",13) _c
                foreach v2 of local varlist {
                    if "`v1'" == "`v2'" {
                        di as text %12s "." _c
                    }
                    else {
                        qui correlate `v1' `v2' if `touse'
                        local rval = r(rho)
                        local nobs = r(N)
                        * t-statistic for correlation
                        local tstat = `rval' * sqrt((`nobs' - 2) / (1 - `rval'^2))
                        local pval = 2 * ttail(`nobs' - 2, abs(`tstat'))
                        if `pval' < 0.01 {
                            di as error %12.4f `pval' _c
                        }
                        else if `pval' < 0.05 {
                            di as result %12.4f `pval' _c
                        }
                        else {
                            di as text %12.4f `pval' _c
                        }
                    }
                }
                di ""
            }
            di as text "{hline 78}"
            di as text " Note: |r| >= 0.7 highlighted in {err:red}; |r| >= 0.4 in {res:yellow}."
            di as text "       p < 0.01 in {err:red}; p < 0.05 in {res:yellow}."
            di as text "{hline 78}"
        }
        
        * Missing Data Analysis
        if `run_table' {
            di as text ""
            di as text " {ul:Missing Data Analysis}"
            di as text ""
            di as text %14s "Variable" _col(16) %12s "Total Obs" ///
                _col(30) %12s "Non-Missing" _col(44) %12s "Missing" ///
                _col(58) %10s "Missing %" _col(70) %10s "Status"
            di as text "{hline 78}"
            
            local any_missing = 0
            foreach v of local varlist {
                qui count if `touse'
                local ntotal = r(N)
                qui count if `touse' & !missing(`v')
                local nvalid = r(N)
                local nmiss = `ntotal' - `nvalid'
                local pctmiss = 100 * `nmiss' / `ntotal'
                
                if `nmiss' > 0 local any_missing = 1
                
                local mstatus "Complete"
                if `pctmiss' > 0 & `pctmiss' < 5 local mstatus "Low"
                if `pctmiss' >= 5 & `pctmiss' < 20 local mstatus "Moderate"
                if `pctmiss' >= 20 local mstatus "High"
                
                di as text %14s abbrev("`v'",13) ///
                    _col(16) as result %12.0f `ntotal' ///
                    _col(30) as result %12.0f `nvalid' _c
                
                if `nmiss' > 0 {
                    if `pctmiss' >= 20 {
                        di as error %12.0f `nmiss' ///
                            _col(58) as error %9.2f `pctmiss' "%" ///
                            _col(70) as error %10s "`mstatus'"
                    }
                    else if `pctmiss' >= 5 {
                        di as result %12.0f `nmiss' ///
                            _col(58) as result %9.2f `pctmiss' "%" ///
                            _col(70) as result %10s "`mstatus'"
                    }
                    else {
                        di as text %12.0f `nmiss' ///
                            _col(58) as text %9.2f `pctmiss' "%" ///
                            _col(70) as text %10s "`mstatus'"
                    }
                }
                else {
                    di as text %12.0f `nmiss' ///
                        _col(58) as text %9.2f `pctmiss' "%" ///
                        _col(70) as text %10s "`mstatus'"
                }
            }
            di as text "{hline 78}"
            if `any_missing' == 0 {
                di as text " No missing values detected in any variable."
            }
            else {
                di as result " Warning: Missing values detected."
                di as text "  >= 20% in {err:red}; >= 5% in {res:yellow}."
            }
            di as text "{hline 78}"
        }
        
        * Outlier Detection (IQR method)
        if `run_table' {
            di as text ""
            di as text " {ul:Outlier Detection (IQR Method)}"
            di as text ""
            di as text %14s "Variable" _col(16) %10s "N" ///
                _col(28) %10s "Q1" _col(40) %10s "Q3" ///
                _col(52) %10s "IQR" _col(64) %8s "Outliers" _col(74) %6s "%"
            di as text "{hline 78}"
            
            foreach v of local varlist {
                qui summarize `v' if `touse', detail
                local nobs_v = r(N)
                local q1 = r(p25)
                local q3 = r(p75)
                local iqr = `q3' - `q1'
                local lower = `q1' - 1.5 * `iqr'
                local upper = `q3' + 1.5 * `iqr'
                
                qui count if `touse' & !missing(`v') & (`v' < `lower' | `v' > `upper')
                local nout = r(N)
                local pctout = 100 * `nout' / `nobs_v'
                
                di as text %14s abbrev("`v'",13) ///
                    _col(16) as result %10.0f `nobs_v' ///
                    _col(28) as result %10.4f `q1' ///
                    _col(40) as result %10.4f `q3' ///
                    _col(52) as result %10.4f `iqr' _c
                
                if `nout' > 0 {
                    if `pctout' >= 10 {
                        di as error %8.0f `nout' _col(74) as error %5.1f `pctout' "%"
                    }
                    else if `pctout' >= 5 {
                        di as result %8.0f `nout' _col(74) as result %5.1f `pctout' "%"
                    }
                    else {
                        di as text %8.0f `nout' _col(74) as text %5.1f `pctout' "%"
                    }
                }
                else {
                    di as text %8.0f `nout' _col(74) as text %5.1f `pctout' "%"
                }
            }
            di as text "{hline 78}"
            di as text " Outlier = obs outside [Q1 - 1.5*IQR, Q3 + 1.5*IQR]"
            di as text " >= 10% in {err:red}; >= 5% in {res:yellow}."
            di as text "{hline 78}"
        }
        
        * Store return values for xtsum
        qui sum `lhs' if `touse'
        return scalar xtsum_overall_mean = r(mean)
        return scalar xtsum_overall_sd   = r(sd)
        
        * xtsum variation bar chart
        if `run_graph' {
            preserve
            qui drop _all
            local nvars : word count `varlist'
            qui set obs `nvars'
            qui gen str20 varname = ""
            qui gen double between_var = .
            qui gen double within_var  = .
            
            restore
            preserve
            
            local vi = 0
            tempvar pmean_g within_g bsd wsd
            foreach v of local varlist {
                local ++vi
                qui egen `pmean_g' = mean(`v') if `touse', by(`panelvar')
                qui sum `pmean_g' if `touse'
                local bsd_val = r(sd)
                qui gen `within_g' = `v' - `pmean_g' + r(mean) if `touse'
                qui sum `within_g' if `touse'
                local wsd_val = r(sd)
                drop `pmean_g' `within_g'
            }
            restore
        }
    }
    
    * =========================================================================
    * MODULE 2: HSIAO HOMOGENEITY TESTS (Standard F-tests)
    * =========================================================================
    if `run_hsiao' {
        di as text ""
        di as text "{hline 78}"
        di as text " {bf:MODULE 2: Hsiao (2014) Homogeneity Tests (ANCOVA)}"
        di as text " Reference: Hsiao, C. (2014). Analysis of Panel Data. Ch.2"
        di as text "{hline 78}"
        
        * --- Model 1: Unrestricted (individual regressions) ---
        * S1 = sum of RSS_i for each panel unit
        local S1 = 0
        local df1_total = 0
        
        foreach p of local panels {
            qui reg `lhs' `rhs' if `panelvar' == `p' & `touse'
            local S1 = `S1' + e(rss)
            local df1_total = `df1_total' + e(df_r)
        }
        * df for S1 = N(T-K-1)
        
        * --- Model 2: Common slopes, different intercepts (FE) ---
        qui areg `lhs' `rhs' if `touse', absorb(`panelvar')
        local S2 = e(rss)
        local df2 = e(df_r)
        * df for S2 = N(T-1) - K
        
        * --- Model 3: Fully pooled (OLS) ---
        qui reg `lhs' `rhs' if `touse'
        local S3 = e(rss)
        local df3 = e(df_r)
        * df for S3 = NT - (K+1)
        
        * --- F1: Overall homogeneity (slopes + intercepts) ---
        local F1_num_df = (`N' - 1) * (`K' + 1)
        local F1_den_df = `df1_total'
        if `F1_den_df' > 0 & `F1_num_df' > 0 {
            local F1 = ((`S3' - `S1') / `F1_num_df') / (`S1' / `F1_den_df')
            local F1_p = Ftail(`F1_num_df', `F1_den_df', `F1')
        }
        else {
            local F1 = .
            local F1_p = .
        }
        
        * --- F2: Slope homogeneity ---
        local F2_num_df = (`N' - 1) * `K'
        local F2_den_df = `df1_total'
        if `F2_den_df' > 0 & `F2_num_df' > 0 {
            local F2 = ((`S2' - `S1') / `F2_num_df') / (`S1' / `F2_den_df')
            local F2_p = Ftail(`F2_num_df', `F2_den_df', `F2')
        }
        else {
            local F2 = .
            local F2_p = .
        }
        
        * --- F3: Intercept homogeneity (given equal slopes) ---
        local F3_num_df = `N' - 1
        local F3_den_df = `df2'
        if `F3_den_df' > 0 & `F3_num_df' > 0 {
            local F3 = ((`S3' - `S2') / `F3_num_df') / (`S2' / `F3_den_df')
            local F3_p = Ftail(`F3_num_df', `F3_den_df', `F3')
        }
        else {
            local F3 = .
            local F3_p = .
        }
        
        if `run_table' {
            * ANCOVA Table
            di as text ""
            di as text " {ul:ANCOVA Table — Residual Sums of Squares}"
            di as text ""
            di as text %40s "Model" _col(42) %12s "RSS" _col(56) %8s "df" _col(66) %12s "Mean Sq."
            di as text "{hline 78}"
            di as text %40s "Unrestricted (individual OLS)" ///
                _col(42) as result %12.4f `S1' ///
                _col(56) as result %8.0f `df1_total' ///
                _col(66) as result %12.4f `S1'/`df1_total'
            di as text %40s "Common slopes, diff. intercepts (FE)" ///
                _col(42) as result %12.4f `S2' ///
                _col(56) as result %8.0f `df2' ///
                _col(66) as result %12.4f `S2'/`df2'
            di as text %40s "Fully pooled (OLS)" ///
                _col(42) as result %12.4f `S3' ///
                _col(56) as result %8.0f `df3' ///
                _col(66) as result %12.4f `S3'/`df3'
            di as text "{hline 78}"
            
            * Decision Table
            di as text ""
            di as text " {ul:Hypothesis Tests — F-statistics}"
            di as text ""
            di as text %45s "Hypothesis" _col(47) %10s "F-stat" _col(58) %8s "df1" _col(67) %8s "df2" _col(76) %8s "p-value"
            di as text "{hline 85}"
            
            local dec1 = cond(`F1_p' < 0.05, "Reject", "Accept")
            local dec2 = cond(`F2_p' < 0.05, "Reject", "Accept")
            local dec3 = cond(`F3_p' < 0.05, "Reject", "Accept")
            
            di as text %45s "F1: Overall homogeneity (slopes+intercepts)" ///
                _col(47) as result %10.4f `F1' ///
                _col(58) as result %8.0f `F1_num_df' ///
                _col(67) as result %8.0f `F1_den_df' ///
                _col(76) as result %8.4f `F1_p'
            di as text %45s "F2: Slope homogeneity" ///
                _col(47) as result %10.4f `F2' ///
                _col(58) as result %8.0f `F2_num_df' ///
                _col(67) as result %8.0f `F2_den_df' ///
                _col(76) as result %8.4f `F2_p'
            di as text %45s "F3: Intercept homogeneity (given equal slopes)" ///
                _col(47) as result %10.4f `F3' ///
                _col(58) as result %8.0f `F3_num_df' ///
                _col(67) as result %8.0f `F3_den_df' ///
                _col(76) as result %8.4f `F3_p'
            di as text "{hline 85}"
            
            * Decision Summary
            di as text ""
            di as text " {ul:Decision Summary}"
            di as text "{hline 78}"
            di as text " Step 1: Test overall homogeneity (F1):"
            if `F1_p' < 0.05 {
                di as result "         >>> REJECTED at 5% level (F = " %8.4f `F1' ", p = " %6.4f `F1_p' ")"
                di as text " Step 2: Test slope homogeneity (F2):"
                if `F2_p' < 0.05 {
                    di as result "         >>> REJECTED at 5% level (F = " %8.4f `F2' ", p = " %6.4f `F2_p' ")"
                    di as result "         ==> Slopes differ across panels. Use individual or MG estimator."
                }
                else {
                    di as result "         >>> ACCEPTED — slopes are homogeneous."
                    di as text " Step 3: Test intercept homogeneity (F3):"
                    if `F3_p' < 0.05 {
                        di as result "         >>> REJECTED — intercepts differ."
                        di as result "         ==> Use Fixed Effects (FE) model."
                    }
                    else {
                        di as result "         >>> ACCEPTED — intercepts are equal."
                        di as result "         ==> Pooled OLS is appropriate."
                    }
                }
            }
            else {
                di as result "         >>> ACCEPTED — overall homogeneity holds."
                di as result "         ==> Pooled OLS is appropriate. No further testing needed."
            }
            di as text "{hline 78}"
        }
        
        * Return Hsiao standard results
        return scalar F1 = `F1'
        return scalar F1_p = `F1_p'
        return scalar F1_df1 = `F1_num_df'
        return scalar F1_df2 = `F1_den_df'
        return scalar F2 = `F2'
        return scalar F2_p = `F2_p'
        return scalar F2_df1 = `F2_num_df'
        return scalar F2_df2 = `F2_den_df'
        return scalar F3 = `F3'
        return scalar F3_p = `F3_p'
        return scalar F3_df1 = `F3_num_df'
        return scalar F3_df2 = `F3_den_df'
        return scalar S1 = `S1'
        return scalar S2 = `S2'
        return scalar S3 = `S3'
    }
    
    * =========================================================================
    * MODULE 3: HSIAO ROBUST HC TESTS
    * =========================================================================
    if `run_robust' {
        di as text ""
        di as text "{hline 78}"
        di as text " {bf:MODULE 3: Hsiao Robust (HC1) Homogeneity Tests}"
        di as text " Heteroscedasticity-consistent Wald tests"
        di as text "{hline 78}"
        
        * --- Robust F1: Pooled vs Unrestricted (overall homogeneity) ---
        * Using interaction model as "full" and pooled as "reduced"
        * Build interaction terms
        local intterms ""
        foreach v of local rhs {
            local intterms "`intterms' i.`gid'#c.`v'"
        }
        
        * Full model: slopes + intercepts vary
        qui reg `lhs' `rhs' i.`gid' `intterms' if `touse', vce(robust)
        
        * Test the joint restriction that all interactions and FE dummies = 0
        * This is F1: overall homogeneity
        qui testparm i.`gid' `intterms'
        local rF1 = r(F)
        local rF1_p = r(p)
        local rF1_df1 = r(df)
        local rF1_df2 = r(df_r)
        
        * --- Robust F2: FE vs Unrestricted (slope homogeneity) ---
        * Test only interaction terms
        qui reg `lhs' `rhs' i.`gid' `intterms' if `touse', vce(robust)
        qui testparm `intterms'
        local rF2 = r(F)
        local rF2_p = r(p)
        local rF2_df1 = r(df)
        local rF2_df2 = r(df_r)
        
        * --- Robust F3: Pooled vs FE (intercept homogeneity given equal slopes) ---
        qui reg `lhs' `rhs' i.`gid' if `touse', vce(robust)
        qui testparm i.`gid'
        local rF3 = r(F)
        local rF3_p = r(p)
        local rF3_df1 = r(df)
        local rF3_df2 = r(df_r)
        
        if `run_table' {
            di as text ""
            di as text %45s "Hypothesis (Robust HC1)" _col(47) %10s "F-stat" _col(58) %8s "df1" _col(67) %8s "df2" _col(76) %8s "p-value"
            di as text "{hline 85}"
            di as text %45s "F1: Overall homogeneity (robust)" ///
                _col(47) as result %10.4f `rF1' ///
                _col(58) as result %8.0f `rF1_df1' ///
                _col(67) as result %8.0f `rF1_df2' ///
                _col(76) as result %8.4f `rF1_p'
            di as text %45s "F2: Slope homogeneity (robust)" ///
                _col(47) as result %10.4f `rF2' ///
                _col(58) as result %8.0f `rF2_df1' ///
                _col(67) as result %8.0f `rF2_df2' ///
                _col(76) as result %8.4f `rF2_p'
            di as text %45s "F3: Intercept homogeneity (robust)" ///
                _col(47) as result %10.4f `rF3' ///
                _col(58) as result %8.0f `rF3_df1' ///
                _col(67) as result %8.0f `rF3_df2' ///
                _col(76) as result %8.4f `rF3_p'
            di as text "{hline 85}"
            
            * Robust Decision Summary
            di as text ""
            di as text " {ul:Robust Decision Summary}"
            di as text "{hline 78}"
            di as text " Step 1: Test overall homogeneity (Robust F1):"
            if `rF1_p' < 0.05 {
                di as result "         >>> REJECTED (F = " %8.4f `rF1' ", p = " %6.4f `rF1_p' ")"
                di as text " Step 2: Test slope homogeneity (Robust F2):"
                if `rF2_p' < 0.05 {
                    di as result "         >>> REJECTED (F = " %8.4f `rF2' ", p = " %6.4f `rF2_p' ")"
                    di as result "         ==> Slopes differ. Use heterogeneous estimator (MG/PMG/CCE)."
                }
                else {
                    di as result "         >>> ACCEPTED — slopes homogeneous."
                    di as text " Step 3: Test intercept homogeneity (Robust F3):"
                    if `rF3_p' < 0.05 {
                        di as result "         >>> REJECTED — intercepts differ. Use FE model."
                    }
                    else {
                        di as result "         >>> ACCEPTED — Pooled OLS appropriate."
                    }
                }
            }
            else {
                di as result "         >>> ACCEPTED — homogeneity holds. Pooled OLS appropriate."
            }
            di as text "{hline 78}"
        }
        
        * Diagnostics: Breusch-Pagan & Durbin-Watson
        di as text ""
        di as text " {ul:Regression Diagnostics}"
        di as text "{hline 78}"
        
        * Breusch-Pagan for pooled model
        qui reg `lhs' `rhs' if `touse'
        qui estat hettest
        local bp_chi2 = r(chi2)
        local bp_p    = r(p)
        local bp_df   = r(df)
        
        di as text " Breusch-Pagan test (pooled model):"
        di as text "   chi2(" %3.0f `bp_df' ") = " as result %10.4f `bp_chi2' as text "   p-value = " as result %8.4f `bp_p'
        if `bp_p' < 0.05 {
            di as result "   >>> Heteroscedasticity detected. Robust standard errors recommended."
        }
        else {
            di as text "   >>> No evidence of heteroscedasticity."
        }
        di as text "{hline 78}"
        
        * Return robust results
        return scalar rF1 = `rF1'
        return scalar rF1_p = `rF1_p'
        return scalar rF2 = `rF2'
        return scalar rF2_p = `rF2_p'
        return scalar rF3 = `rF3'
        return scalar rF3_p = `rF3_p'
        return scalar bp_chi2 = `bp_chi2'
        return scalar bp_p = `bp_p'
    }
    
    * =========================================================================
    * MODULE 4: COEFFICIENT HETEROGENEITY (panelhetero-style tables)
    * =========================================================================
    if `run_hetero' {
        di as text ""
        di as text "{hline 78}"
        di as text " {bf:MODULE 4: Coefficient Heterogeneity Analysis}"
        di as text " Individual regression coefficients per panel unit"
        di as text "{hline 78}"
        
        * Run individual regressions and store coefficients
        tempname indiv_b
        matrix `indiv_b' = J(`N', `K'+1, .)
        matrix colnames `indiv_b' = _cons `rhs'
        
        local panel_names ""
        local pi = 0
        foreach p of local panels {
            local ++pi
            qui reg `lhs' `rhs' if `panelvar' == `p' & `touse'
            
            * Store constant
            matrix `indiv_b'[`pi', 1] = _b[_cons]
            
            * Store slope coefficients
            local ki = 1
            foreach v of local rhs {
                local ++ki
                matrix `indiv_b'[`pi', `ki'] = _b[`v']
            }
            local panel_names "`panel_names' `p'"
        }
        
        if `run_table' {
            * Table 1: Individual Coefficients
            di as text ""
            di as text " {ul:Table 1: Individual Panel Coefficients}"
            di as text ""
            
            * Header
            local hdr = " %12s " + `"""' + "Panel" + `"""'
            di as text %12s "Panel" _c
            di as text %12s "_cons" _c
            foreach v of local rhs {
                di as text %12s abbrev("`v'",11) _c
            }
            di as text ""
            di as text "{hline 78}"
            
            local pi = 0
            foreach p of local panels {
                local ++pi
                di as text %12s "`p'" _c
                forvalues j = 1/`=`K'+1' {
                    di as result %12.4f `indiv_b'[`pi', `j'] _c
                }
                di ""
            }
            di as text "{hline 78}"
            
            * Table 2: Heterogeneity Statistics
            di as text ""
            di as text " {ul:Table 2: Coefficient Heterogeneity Statistics}"
            di as text ""
            di as text %14s "Statistic" _col(16) %10s "_cons" _c
            foreach v of local rhs {
                di as text %12s abbrev("`v'",11) _c
            }
            di ""
            di as text "{hline 78}"
            
            * Compute stats for each coefficient
            forvalues j = 1/`=`K'+1' {
                tempname colvals
                matrix `colvals' = `indiv_b'[1..`N', `j']
                mata: _xtpretest_hetstat(st_matrix("`colvals'"), `N')
                
                if `j' == 1 local vn "_cons"
                else {
                    local jj = `j' - 1
                    local vn : word `jj' of `rhs'
                }
            }
            
            * Report Mean, Median, SD, IQR, Skewness, Kurtosis, Min, Max
            local statnames "Mean Median Std.Dev IQR Skewness Kurtosis Min Max"
            foreach sn of local statnames {
                di as text %14s "`sn'" _c
                forvalues j = 1/`=`K'+1' {
                    tempname colvals
                    matrix `colvals' = `indiv_b'[1..`N', `j']
                    mata: _xtpretest_onestat(st_matrix("`colvals'"), `N', "`sn'")
                    di as result %12.4f scalar(__hetval) _c
                }
                di ""
            }
            di as text "{hline 78}"
            
            * Table 3: Variance Decomposition
            di as text ""
            di as text " {ul:Table 3: Coefficient Variance Decomposition}"
            di as text ""
            di as text %14s "Variable" _col(16) %12s "Total Var." _col(30) %12s "Between" ///
                _col(44) %12s "Within(SE2)" _col(58) %12s "Ratio(B/T)" _col(72) %8s "Signal"
            di as text "{hline 78}"
            
            local pi = 0
            forvalues j = 2/`=`K'+1' {
                local jj = `j' - 1
                local vn : word `jj' of `rhs'
                
                * Between-panel variance of coefficients
                mata: _xtpretest_bvar(st_matrix("`indiv_b'"), `N', `j')
                local bvar = scalar(__bvar)
                
                * Within: average of squared SE of individual regressions
                local wvar = 0
                local pi2 = 0
                foreach p of local panels {
                    local ++pi2
                    qui reg `lhs' `rhs' if `panelvar' == `p' & `touse'
                    local se_v = _se[`vn']
                    local wvar = `wvar' + `se_v'^2
                }
                local wvar = `wvar' / `N'
                local tvar = `bvar' + `wvar'
                local ratio = cond(`tvar' > 0, `bvar'/`tvar', .)
                local signal = cond(`ratio' >= 0.8, "High", cond(`ratio' >= 0.5, "Moderate", "Low"))
                
                di as text %14s abbrev("`vn'",13) ///
                    _col(16) as result %12.6f `tvar' ///
                    _col(30) as result %12.6f `bvar' ///
                    _col(44) as result %12.6f `wvar' ///
                    _col(58) as result %12.4f `ratio' ///
                    _col(72) as result %8s "`signal'"
            }
            di as text "{hline 78}"
            di as text " Note: Ratio > 0.8 = High systematic heterogeneity"
            di as text "       Ratio < 0.5 = Mostly estimation noise"
            di as text "{hline 78}"
            
            * Swamy (1970) Test for Parameter Heterogeneity
            di as text ""
            di as text " {ul:Swamy (1970) Test for Parameter Heterogeneity}"
            
            * FE estimator
            qui areg `lhs' `rhs' if `touse', absorb(`panelvar')
            tempname b_fe
            matrix `b_fe' = e(b)
            local sigma2_fe = e(rss) / e(df_r)
            
            * Swamy chi2 = sum_i (b_i - b_FE)' * Var(b_i)^(-1) * (b_i - b_FE)
            local swamy_chi2 = 0
            local pi3 = 0
            foreach p of local panels {
                local ++pi3
                qui reg `lhs' `rhs' if `panelvar' == `p' & `touse'
                tempname bi Vi
                matrix `bi' = e(b)
                matrix `Vi' = e(V)
                
                * Extract slope coefficients only
                tempname bi_s bfe_s Vi_s
                matrix `bi_s' = `bi'[1, 1..`K']
                matrix `bfe_s' = `b_fe'[1, 1..`K']
                matrix `Vi_s' = `Vi'[1..`K', 1..`K']
                
                * diff = b_i - b_FE
                tempname diff
                matrix `diff' = `bi_s' - `bfe_s'
                
                * chi2_i = diff' * inv(V_i) * diff
                capture {
                    tempname Vi_inv chi2_i
                    matrix `Vi_inv' = invsym(`Vi_s')
                    matrix `chi2_i' = `diff' * `Vi_inv' * `diff''
                    local swamy_chi2 = `swamy_chi2' + `chi2_i'[1,1]
                }
            }
            
            local swamy_df = `K' * (`N' - 1)
            local swamy_p = chi2tail(`swamy_df', `swamy_chi2')
            
            di as text ""
            di as text %30s "Swamy chi-squared" _col(35) " = " as result %12.4f `swamy_chi2'
            di as text %30s "Degrees of freedom" _col(35) " = " as result %12.0f `swamy_df'
            di as text %30s "P-value" _col(35) " = " as result %12.4f `swamy_p'
            
            if `swamy_p' < 0.05 {
                di as text ""
                di as result "  >>> Significant heterogeneity detected (p < 0.05)."
                di as result "      Heterogeneous estimator (MG/PMG/CCE) recommended."
            }
            else {
                di as text ""
                di as result "  >>> No significant heterogeneity (p >= 0.05)."
                di as result "      Pooled/FE estimator is appropriate."
            }
            di as text "{hline 78}"
        }
        
        * Return heterogeneity results
        return scalar swamy_chi2 = `swamy_chi2'
        return scalar swamy_df = `swamy_df'
        return scalar swamy_p = `swamy_p'
        
        * Save a persistent copy for Module 8 graphs BEFORE return moves the matrix
        capture matrix _xtpre_ib = `indiv_b'
        return matrix indiv_b = `indiv_b'
    }
    
    * =========================================================================
    * MODULE 5: SLOPE HOMOGENEITY TESTS (xthst / xtbhst)
    * =========================================================================
    if `run_slope' {
        di as text ""
        di as text "{hline 78}"
        di as text " {bf:MODULE 5: Slope Homogeneity Tests}"
        di as text "{hline 78}"
        
        * Try xthst (Pesaran & Yamagata 2008)
        capture which xthst
        if _rc == 0 {
            di as text ""
            di as text " {ul:5.1 Pesaran & Yamagata (2008) — xthst}"
            di as text ""
            capture noisily xthst `varlist' if `touse'
            capture {
                return scalar delta_xthst = r(delta)[1,1]
                return scalar delta_adj_xthst = r(delta)[2,1]
                return scalar delta_p_xthst = r(delta_p)[1,1]
                return scalar delta_adj_p_xthst = r(delta_p)[2,1]
            }
        }
        else {
            di as text ""
            di as text " {it:xthst not installed. Install via: ssc install xthst}"
        }
        
        * Try xtbhst (Blomquist & Westerlund 2015 bootstrap)
        capture which xtbhst
        if _rc == 0 {
            di as text ""
            di as text " {ul:5.2 Blomquist & Westerlund (2015) Bootstrap — xtbhst}"
            di as text ""
            if `seed' > 0 {
                capture noisily xtbhst `varlist' if `touse', reps(`reps') seed(`seed')
            }
            else {
                capture noisily xtbhst `varlist' if `touse', reps(`reps')
            }
            capture {
                return scalar delta_xtbhst = r(delta)[1,1]
                return scalar delta_adj_xtbhst = r(delta)[2,1]
                return scalar delta_p_xtbhst = r(delta_p)[1,1]
                return scalar delta_adj_p_xtbhst = r(delta_p)[2,1]
            }
        }
        else {
            di as text ""
            di as text " {it:xtbhst not installed. Install via: ssc install xtbhst}"
        }
        
        di as text "{hline 78}"
    }
    
    * =========================================================================
    * MODULE 6: CROSS-SECTIONAL DEPENDENCE
    * =========================================================================
    if `run_csd' {
        di as text ""
        di as text "{hline 78}"
        di as text " {bf:MODULE 6: Cross-Sectional Dependence Tests}"
        
        di as text "{hline 78}"
        
        * Try xtcd2 (Pesaran 2015)
        capture which xtcd2
        if _rc == 0 {
            * --- 6.1 CSD test for all variables ---
            di as text ""
            di as text " {ul:6.1 Pesaran (2015) CD Test for Variables — xtcd2}"
            di as text ""
            capture noisily xtcd2 `varlist' if `touse'
            
            * --- 6.2 CSD test for FE residuals ---
            di as text ""
            di as text " {ul:6.2 Pesaran (2015) CD Test for FE Residuals — xtcd2}"
            di as text ""
            qui xtreg `lhs' `rhs' if `touse', fe
            capture drop _xtpre_res
            qui predict _xtpre_res if `touse', e
            capture noisily xtcd2 _xtpre_res if `touse'
            capture {
                return scalar cd = r(CD)[1,1]
                return scalar cd_p = r(p)[1,1]
                return scalar cd_rho = r(rho)[1,1]
            }
        }
        else {
            di as text ""
            di as text " {it:xtcd2 not installed. Install via: ssc install xtcd2}"
            * Still compute residuals for built-in test
            qui xtreg `lhs' `rhs' if `touse', fe
            capture drop _xtpre_res
            qui predict _xtpre_res if `touse', e
        }
        
        * Also compute simple Pesaran CD manually as backup
        di as text ""
        di as text " {ul:6.3 Pesaran (2004) CD Test — Residuals (built-in)}"
        di as text ""
        
        * Manual CD computation on residuals
        if "`_xtpre_res'" == "" {
            qui xtreg `lhs' `rhs' if `touse', fe
            capture drop _xtpre_res
            qui predict _xtpre_res if `touse', e
        }
        mata: _xtpretest_cd("_xtpre_res", "`panelvar'", "`timevar'", "`touse'")
        
        local cd_stat = scalar(__cd_stat)
        local cd_pval = 2 * (1 - normal(abs(`cd_stat')))
        local avg_rho = scalar(__avg_rho)
        
        di as text " CD test statistic  = " as result %10.4f `cd_stat'
        di as text " P-value            = " as result %10.4f `cd_pval'
        di as text " Average |rho_ij|   = " as result %10.4f `avg_rho'
        
        if `cd_pval' < 0.05 {
            di as result " >>> Cross-sectional dependence detected."
            di as result "     Consider CCE or CCEMG estimators."
        }
        else {
            di as text " >>> No significant cross-sectional dependence."
        }
        di as text "{hline 78}"
        
        return scalar cd_builtin = `cd_stat'
        return scalar cd_builtin_p = `cd_pval'
        return scalar avg_rho = `avg_rho'
        
        capture drop _xtpre_res
    }
    
    * =========================================================================
    * MODULE 7: STRUCTURAL BREAKS
    * =========================================================================
    if `run_breaks' {
        di as text ""
        di as text "{hline 78}"
        di as text " {bf:MODULE 7: Structural Breaks}"
        di as text "{hline 78}"
        
        capture which xtbreak
        if _rc == 0 {
            di as text ""
            di as text " xtbreak is available (v2.2). Running structural break test..."
            di as text ""
            capture noisily xtbreak test `lhs' `rhs' if `touse', hypothesis(1) breaks(1)
            if _rc != 0 {
                di as text ""
                di as text "  (!) xtbreak test encountered an error."
                di as text "  Try running manually:"
                di as text "   {cmd:xtbreak test `lhs' `rhs', hypothesis(1) breaks(1)}"
            }
        }
        else {
            di as text ""
            di as text " {it:xtbreak not installed. Install via: ssc install xtbreak}"
        }
        di as text "{hline 78}"
    }
    
    * =========================================================================
    * MODULE 8: DIAGNOSTIC GRAPHS
    * =========================================================================
    if `run_graph' {
        di as text ""
        di as text "{hline 78}"
        di as text " {bf:MODULE 8: Diagnostic Graphs}"
        di as text "{hline 78}"
        
        * --- Graph 1: Between vs Within Variation ---
                capture noisily {
            preserve
            tempvar gm1 pm1 wv1
            local vi = 0
            local bsd_list ""
            local wsd_list ""
            local vname_list ""
            local nvars : word count `varlist'
            
            foreach v of local varlist {
                local ++vi
                qui egen `pm1' = mean(`v') if `touse', by(`panelvar')
                qui sum `pm1' if `touse'
                local this_bsd = r(sd)
                qui gen `wv1' = `v' - `pm1' + r(mean) if `touse'
                qui sum `wv1' if `touse'
                local this_wsd = r(sd)
                drop `pm1' `wv1'
                local bsd_list "`bsd_list' `this_bsd'"
                local wsd_list "`wsd_list' `this_wsd'"
                local vname_list "`vname_list' `v'"
            }
            restore
            
            preserve
            qui drop _all
            qui set obs `nvars'
            qui gen str20 varname = ""
            qui gen double between_sd = .
            qui gen double within_sd  = .
            
            local vi = 0
            foreach v of local vname_list {
                local ++vi
                local bv : word `vi' of `bsd_list'
                local wv : word `vi' of `wsd_list'
                qui replace varname = "`v'" in `vi'
                qui replace between_sd = `bv' in `vi'
                qui replace within_sd = `wv' in `vi'
            }
            
            qui gen obsnum = _n
            graph bar between_sd within_sd, over(varname) ///
                legend(order(1 "Between (cross-panel)" 2 "Within (time)") rows(1)) ///
                title("Panel Variation Decomposition") ///
                subtitle("Standard Deviation: Between vs Within") ///
                ytitle("Standard Deviation") ///
                bar(1, color(navy%70)) bar(2, color(cranberry%70)) ///
                graphregion(color(white)) scheme(s2color) ///
                name(xtpre_variation, replace) nodraw
            restore
        }
        if _rc != 0 {
            capture restore
            di as text "  (!) Graph 1 skipped due to error."
        }
        else {
            local _created_variation = 1
        }
        
        * --- Graph 2: Distribution Histograms with Kernel Density ---

        local dist_graphs ""
        local vi = 0
        foreach v of local varlist {
            local ++vi
            if `vi' > 6 continue
            
            qui sum `v' if `touse'
            local vmean = r(mean)
            capture noisily {
                twoway (histogram `v' if `touse', density fcolor(ltblue%60) lcolor(white) bin(20)) ///
                       (kdensity `v' if `touse', lcolor(navy) lwidth(medthick)), ///
                       xline(`vmean', lcolor(cranberry) lwidth(thick) lpattern(dash)) ///
                       title("`:word `vi' of `varlist''") ///
                       xtitle("") ytitle("Density") ///
                       legend(off) ///
                       graphregion(color(white)) scheme(s2color) ///
                       name(xtpre_dist`vi', replace) nodraw
            }
            if _rc == 0 {
                local dist_graphs "`dist_graphs' xtpre_dist`vi'"
                local _created_distributions = 1
            }
        }
        
        if "`dist_graphs'" != "" {
            capture noisily graph combine `dist_graphs', ///
                title("Variable Distributions with Kernel Density") ///
                cols(3) ///
                graphregion(color(white)) ///
                name(xtpre_distributions, replace) nodraw
        }
        
        * --- Graph 3: Box Plots by Panel ---

        local box_graphs ""
        local vi = 0
        foreach v of local varlist {
            local ++vi
            if `vi' > 4 continue
            
            capture noisily {
                graph box `v' if `touse', over(`panelvar') ///
                    title("`:word `vi' of `varlist''") ///
                    ytitle("") ///
                    box(1, fcolor(ltblue%70) lcolor(navy)) ///
                    medtype(line) medline(lcolor(cranberry) lwidth(medthick)) ///
                    graphregion(color(white)) scheme(s2color) ///
                    name(xtpre_box`vi', replace) nodraw
            }
            if _rc == 0 {
                local box_graphs "`box_graphs' xtpre_box`vi'"
                local _created_boxplots = 1
            }
        }
        
        if "`box_graphs'" != "" {
            local nbg : word count `box_graphs'
            local bcols = cond(`nbg' <= 2, `nbg', 2)
            capture noisily graph combine `box_graphs', ///
                title("Cross-Panel Box Plots") ///
                subtitle("Distribution by panel unit") ///
                cols(`bcols') ///
                graphregion(color(white)) ///
                name(xtpre_boxplots, replace) nodraw
        }
        
        * --- Graph 4: Time Series by Panel ---

        local ts_graphs ""
        local vi = 0
        foreach v of local varlist {
            local ++vi
            if `vi' > 3 continue
            
            capture noisily {
                twoway (line `v' `timevar' if `touse', ///
                       connect(ascending) by(`panelvar', ///
                       title("`:word `vi' of `varlist'' by Panel") ///
                       note("") compact) ///
                       lcolor(navy) lwidth(medthin)), ///
                       ytitle("") xtitle("") ///
                       graphregion(color(white)) scheme(s2color) ///
                       name(xtpre_ts`vi', replace) nodraw
            }
            if _rc == 0 {
                local ts_graphs "`ts_graphs' xtpre_ts`vi'"
            }
        }
        
        * --- Graph 5: Scatter Plot ---

        local sc_graphs ""
        local ki = 0
        foreach v of local rhs {
            local ++ki
            if `ki' > 3 continue
            
            capture noisily {
                twoway (scatter `lhs' `v' if `touse', ///
                       mcolor(navy%40) msize(small) msymbol(circle)) ///
                       (lfit `lhs' `v' if `touse', ///
                       lcolor(cranberry) lwidth(medthick) lpattern(solid)) ///
                       (qfit `lhs' `v' if `touse', ///
                       lcolor(dkgreen) lwidth(medthick) lpattern(dash)), ///
                       title("`lhs' vs `v'") ///
                       subtitle("Linear (red) and Quadratic (green) fit") ///
                       xtitle("`v'") ytitle("`lhs'") ///
                       legend(off) ///
                       graphregion(color(white)) scheme(s2color) ///
                       name(xtpre_sc`ki', replace) nodraw
            }
            if _rc == 0 {
                local sc_graphs "`sc_graphs' xtpre_sc`ki'"
                local _created_scatter = 1
            }
        }
        
        if "`sc_graphs'" != "" {
            local nsg : word count `sc_graphs'
            local scols = cond(`nsg' <= 3, `nsg', 3)
            capture noisily graph combine `sc_graphs', ///
                title("Scatter Plots with Fitted Lines") ///
                subtitle("Pooled: Linear vs Quadratic") ///
                cols(`scols') ///
                graphregion(color(white)) ///
                name(xtpre_scatter, replace) nodraw
        }
        
        * --- Graph 6: Correlation Matrix ---

        capture {
            graph matrix `varlist' if `touse', ///
                half mcolor(navy%40) msize(vsmall) ///
                title("Pairwise Scatter Matrix") ///
                graphregion(color(white)) scheme(s2color) ///
                name(xtpre_corrmatrix, replace) nodraw
        }
        if _rc == 0 local _created_corrmatrix = 1
        


        * --- Graph 7: Residual Diagnostics ---

        capture noisily {
            qui reg `lhs' `rhs' if `touse'
            tempvar resid_pooled fitted_pooled
            qui predict `fitted_pooled' if `touse', xb
            qui predict `resid_pooled' if `touse', residuals
            
            * 7a: Residuals vs Fitted
            twoway (scatter `resid_pooled' `fitted_pooled' if `touse', ///
                   mcolor(navy%40) msize(small)) ///
                   (lowess `resid_pooled' `fitted_pooled' if `touse', ///
                   lcolor(cranberry) lwidth(medthick)), ///
                   title("Residuals vs Fitted") ///
                   subtitle("Pooled OLS") ///
                   xtitle("Fitted values") ytitle("Residuals") ///
                   yline(0, lcolor(gs10) lpattern(dash)) ///
                   legend(off) ///
                   graphregion(color(white)) scheme(s2color) ///
                   name(xtpre_rvf, replace) nodraw
            
            * 7b: Residual histogram with normal overlay
            twoway (histogram `resid_pooled' if `touse', density fcolor(ltblue%60) lcolor(white) bin(25)) ///
                   (kdensity `resid_pooled' if `touse', lcolor(navy) lwidth(medthick)), ///
                   title("Residual Distribution") ///
                   subtitle("Histogram with Kernel Density") ///
                   xtitle("Residuals") ytitle("Density") ///
                   legend(off) ///
                   graphregion(color(white)) scheme(s2color) ///
                   name(xtpre_reshist, replace) nodraw
            
            * 7c: Residuals by panel
            graph box `resid_pooled' if `touse', over(`panelvar') ///
                title("Residuals by Panel") ///
                ytitle("Residuals") ///
                box(1, fcolor(ltblue%70) lcolor(navy)) ///
                medtype(line) medline(lcolor(cranberry) lwidth(medthick)) ///
                yline(0, lcolor(gs10) lpattern(dash)) ///
                graphregion(color(white)) scheme(s2color) ///
                name(xtpre_resbox, replace) nodraw
            
            * Combine residual diagnostics
            graph combine xtpre_rvf xtpre_reshist xtpre_resbox, ///
                title("Residual Diagnostics (Pooled OLS)") ///
                cols(3) ///
                graphregion(color(white)) ///
                name(xtpre_residuals, replace) nodraw
            
            drop `resid_pooled' `fitted_pooled'
        }
        if _rc != 0 {
            di as text "  (!) Residual diagnostics graphs skipped due to error."
        }
        else {
            local _created_residuals = 1
        }
        
        * --- Graph 8: Cross-Sectional Dispersion Over Time ---

        local csd_graphs ""
        local vi = 0
        foreach v of local varlist {
            local ++vi
            if `vi' > 3 continue
            
            capture noisily {
                preserve
                collapse (sd) sd_`v' = `v' (mean) mean_`v' = `v' if `touse', by(`timevar')
                
                twoway (bar sd_`v' `timevar', fcolor(ltblue%60) lcolor(navy)) ///
                       (line mean_`v' `timevar', yaxis(2) lcolor(cranberry) lwidth(medthick)), ///
                       title("`:word `vi' of `varlist''") ///
                       ytitle("Cross-sect. SD") ytitle("Mean", axis(2)) ///
                       xtitle("") ///
                       legend(order(1 "Std.Dev" 2 "Mean") rows(1) size(small)) ///
                       graphregion(color(white)) scheme(s2color) ///
                       name(xtpre_csdsp`vi', replace) nodraw
                
                restore
            }
            if _rc == 0 {
                local csd_graphs "`csd_graphs' xtpre_csdsp`vi'"
                local _created_csdisp = 1
            }
            else {
                capture restore
            }
        }
        
        if "`csd_graphs'" != "" {
            local ncsd : word count `csd_graphs'
            local csdcols = cond(`ncsd' <= 3, `ncsd', 3)
            capture noisily graph combine `csd_graphs', ///
                title("Cross-Sectional Dispersion Over Time") ///
                subtitle("Panel SD and Mean by period") ///
                cols(`csdcols') ///
                graphregion(color(white)) ///
                name(xtpre_csdisp, replace) nodraw
        }
        
        * --- Graph 9: Coefficient Distributions ---

        local coef_graphs ""
        if `run_hetero' {
            tempname ib_graph
            capture matrix `ib_graph' = _xtpre_ib
            if _rc == 0 {
                capture noisily {
                    preserve
                    qui drop _all
                    qui set obs `N'
                    
                    local ki = 0
                    foreach v of local rhs {
                        local ++ki
                        local col = `ki' + 1
                        qui gen double coef_`ki' = .
                        forvalues i = 1/`N' {
                            qui replace coef_`ki' = `ib_graph'[`i', `col'] in `i'
                        }
                        
                        qui sum coef_`ki'
                        local mn = r(mean)
                        
                        if `mn' != . {
                            twoway (histogram coef_`ki', density fcolor(ltblue%60) lcolor(white)) ///
                                   (kdensity coef_`ki', lcolor(navy) lwidth(medthick)), ///
                                   xline(`mn', lcolor(cranberry) lwidth(thick) lpattern(dash)) ///
                               title("Distribution of `v' coefficients") ///
                               subtitle("Across `N' panel units") ///
                               xtitle("Coefficient value") ytitle("Density") ///
                               legend(off) ///
                               graphregion(color(white)) scheme(s2color) ///
                               name(xtpre_coef`ki', replace) nodraw
                        }
                        else {
                            twoway (histogram coef_`ki', density fcolor(ltblue%60) lcolor(white)) ///
                                   (kdensity coef_`ki', lcolor(navy) lwidth(medthick)), ///
                                   title("Distribution of `v' coefficients") ///
                                   subtitle("Across `N' panel units") ///
                                   xtitle("Coefficient value") ytitle("Density") ///
                                   legend(off) ///
                                   graphregion(color(white)) scheme(s2color) ///
                                   name(xtpre_coef`ki', replace) nodraw
                        }
                        
                        local coef_graphs "`coef_graphs' xtpre_coef`ki'"
                    }
                    restore
                }
                if _rc != 0 {
                    capture restore
                    di as text "  (!) Coefficient distribution graphs skipped."
                }
            }
        }
        
        * --- Graph 10: Hsiao Test Summary Bar Chart ---

        if `run_hsiao' {
            capture noisily {
                preserve
                qui drop _all
                qui set obs 3
                qui gen str40 test_name = ""
                qui gen double fstat = .
                qui gen double pval = .
                
                qui replace test_name = "F1: Overall" in 1
                qui replace fstat = `F1' in 1
                qui replace pval = `F1_p' in 1
                
                qui replace test_name = "F2: Slopes" in 2
                qui replace fstat = `F2' in 2
                qui replace pval = `F2_p' in 2
                
                qui replace test_name = "F3: Intercepts" in 3
                qui replace fstat = `F3' in 3
                qui replace pval = `F3_p' in 3
                
                qui gen sig = cond(pval < 0.05, 1, 0)
                
                graph bar fstat, over(test_name) ///
                    title("Hsiao Homogeneity F-tests") ///
                    subtitle("F-statistics") ///
                    ytitle("F-statistic") ///
                    bar(1, color(navy%70)) ///
                    yline(1, lcolor(cranberry) lpattern(dash)) ///
                    graphregion(color(white)) scheme(s2color) ///
                    name(xtpre_hsiao, replace) nodraw
                restore
            }
            if _rc != 0 {
                capture restore
                di as text "  (!) Hsiao bar chart skipped."
            }
            else {
                local _created_hsiao = 1
            }
        }
        
        * --- Graph 11: By-Panel Mean Bar Chart ---

        if `run_summary' {
            capture noisily {
                preserve
                tempvar pmean_dep
                qui egen `pmean_dep' = mean(`lhs') if `touse', by(`panelvar')
                
                graph bar `pmean_dep' if `touse', over(`panelvar') ///
                    title("Mean `lhs' by Panel") ///
                    ytitle("Mean `lhs'") ///
                    bar(1, fcolor(navy%70) lcolor(navy)) ///
                    graphregion(color(white)) scheme(s2color) ///
                    name(xtpre_panelmeans, replace) nodraw
                
                drop `pmean_dep'
                restore
            }
            if _rc != 0 {
                capture restore
                di as text "  (!) Panel means bar chart skipped."
            }
            else {
                local _created_panelmeans = 1
            }
        }
        
        * =========================================================
        * DISPLAY EACH GRAPH IN ITS OWN WINDOW
        * =========================================================
        di as text ""
        di as result " Diagnostic graphs generated:"
        
        * 1. Variation bar chart
        if "`_created_variation'" == "1" {
            capture noisily graph display xtpre_variation
            di as result "   xtpre_variation       (Between vs Within variation)"
        }
        
        * 2. Distributions combined
        if "`_created_distributions'" == "1" {
            * Re-combine with proper size for display
            capture noisily graph combine `dist_graphs', ///
                title("Variable Distributions with Kernel Density") ///
                ///
                cols(3) xsize(12) ysize(5) ///
                graphregion(color(white)) ///
                name(xtpre_distributions, replace)
            di as result "   xtpre_distributions   (Histograms + Kernel Density)"
        }
        
        * 3. Box plots combined
        if "`_created_boxplots'" == "1" {
            local nbg : word count `box_graphs'
            local bcols = cond(`nbg' <= 2, `nbg', 2)
            capture noisily graph combine `box_graphs', ///
                title("Cross-Panel Box Plots") ///
                ///
                cols(`bcols') xsize(10) ysize(8) ///
                graphregion(color(white)) ///
                name(xtpre_boxplots, replace)
            di as result "   xtpre_boxplots        (Box plots by panel unit)"
        }
        
        * 4. Scatter plots combined
        if "`_created_scatter'" == "1" {
            local nsg : word count `sc_graphs'
            local scols = cond(`nsg' <= 3, `nsg', 3)
            capture noisily graph combine `sc_graphs', ///
                title("Scatter Plots with Fitted Lines") ///
                ///
                cols(`scols') xsize(12) ysize(5) ///
                graphregion(color(white)) ///
                name(xtpre_scatter, replace)
            di as result "   xtpre_scatter         (Linear + Quadratic fit)"
        }
        
        * 5. Correlation matrix
        if "`_created_corrmatrix'" == "1" {
            capture noisily graph display xtpre_corrmatrix
            di as result "   xtpre_corrmatrix      (Pairwise scatter matrix)"
        }

        
        * 6. Residual diagnostics combined
        if "`_created_residuals'" == "1" {
            capture noisily graph combine xtpre_rvf xtpre_reshist xtpre_resbox, ///
                title("Residual Diagnostics (Pooled OLS)") ///
                ///
                cols(3) xsize(14) ysize(5) ///
                graphregion(color(white)) ///
                name(xtpre_residuals, replace)
            di as result "   xtpre_residuals       (Residuals vs Fitted, Distribution, by Panel)"
        }
        
        * 7. CSD dispersion combined
        if "`_created_csdisp'" == "1" {
            local ncsd : word count `csd_graphs'
            local csdcols = cond(`ncsd' <= 3, `ncsd', 3)
            capture noisily graph combine `csd_graphs', ///
                title("Cross-Sectional Dispersion Over Time") ///
                ///
                cols(`csdcols') xsize(12) ysize(5) ///
                graphregion(color(white)) ///
                name(xtpre_csdisp, replace)
            di as result "   xtpre_csdisp          (Panel SD and Mean by period)"
        }
        
        * 8. Coefficient distributions
        if "`coef_graphs'" != "" {
            local ncg : word count `coef_graphs'
            local cgcols = cond(`ncg' <= 2, `ncg', 2)
            capture noisily graph combine `coef_graphs', ///
                title("Individual Coefficient Distributions") ///
                ///
                cols(`cgcols') xsize(10) ysize(6) ///
                graphregion(color(white)) ///
                name(xtpre_coefdist, replace)
            di as result "   xtpre_coefdist        (Coefficient distributions across panels)"
        }
        
        * 9. Hsiao bar chart
        if "`_created_hsiao'" == "1" {
            capture noisily graph display xtpre_hsiao
            di as result "   xtpre_hsiao           (Hsiao F-test bar chart)"
        }
        
        * 10. Time series by panel
        if "`ts_graphs'" != "" {
            local nts : word count `ts_graphs'
            capture noisily graph combine `ts_graphs', ///
                title("Time Series by Panel") ///
                ///
                cols(1) xsize(10) ysize(`=5*`nts'') ///
                graphregion(color(white)) ///
                name(xtpre_timeseries, replace)
            di as result "   xtpre_timeseries      (Time series line plots)"
        }
        
        * 11. Panel means bar chart
        if "`_created_panelmeans'" == "1" {
            capture noisily graph display xtpre_panelmeans
            di as result "   xtpre_panelmeans      (Mean by panel bar chart)"
        }
        
        * 12. Radar chart — coefficient heterogeneity summary
        if `run_hetero' {
            capture noisily {
                tempname ib_radar
                capture matrix `ib_radar' = _xtpre_ib
                if _rc == 0 {
                    preserve
                    qui drop _all
                    
                    * Build summary dataset: variable × statistic
                    local nrhs : word count `rhs'
                    local nrows = `nrhs' * 4
                    qui set obs `nrows'
                    qui gen str20 variable = ""
                    qui gen str10 stat = ""
                    qui gen double value = .
                    qui gen int order = .
                    
                    local row = 0
                    local ki = 0
                    foreach v of local rhs {
                        local ++ki
                        local col = `ki' + 1
                        * Get column of coefficients
                        tempname colvec
                        matrix `colvec' = `ib_radar'[1..`N', `col']
                        mata: st_local("cmean", strofreal(mean(st_matrix("`colvec'"))[1,1]))
                        mata: st_local("csd",   strofreal(sqrt(variance(st_matrix("`colvec'"))[1,1])))
                        mata: st_local("cmin",  strofreal(min(st_matrix("`colvec'"))))
                        mata: st_local("cmax",  strofreal(max(st_matrix("`colvec'"))))
                        
                        local ++row
                        qui replace variable = "`v'" in `row'
                        qui replace stat = "Mean" in `row'
                        qui replace value = `cmean' in `row'
                        qui replace order = 1 in `row'
                        
                        local ++row
                        qui replace variable = "`v'" in `row'
                        qui replace stat = "Std.Dev" in `row'
                        qui replace value = `csd' in `row'
                        qui replace order = 2 in `row'
                        
                        local ++row
                        qui replace variable = "`v'" in `row'
                        qui replace stat = "Min" in `row'
                        qui replace value = `cmin' in `row'
                        qui replace order = 3 in `row'
                        
                        local ++row
                        qui replace variable = "`v'" in `row'
                        qui replace stat = "Max" in `row'
                        qui replace value = `cmax' in `row'
                        qui replace order = 4 in `row'
                    }
                    
                    qui encode stat, gen(stat_num)
                    
                    graph bar value, over(stat_num, label(labsize(small))) ///
                        over(variable, label(labsize(small))) ///
                        asyvars ///
                        title("Coefficient Heterogeneity Radar") ///
                        subtitle("Individual coefficient statistics across panels") ///
                        ytitle("Value") ///
                        bar(1, fcolor(navy%70)) ///
                        bar(2, fcolor(cranberry%70)) ///
                        bar(3, fcolor(dkgreen%70)) ///
                        bar(4, fcolor(dkorange%70)) ///
                        legend(rows(1) size(small)) ///
                        graphregion(color(white)) scheme(s2color) ///
                        name(xtpre_radar, replace) nodraw
                    
                    restore
                    local _created_radar = 1
                }
            }
            if _rc != 0 {
                capture restore
            }
        }
        
        * 13. Plotmeans — panel means with confidence intervals
        capture noisily {
            preserve
            tempvar pmean psd pcount pse plo phi
            qui egen `pmean' = mean(`lhs') if `touse', by(`panelvar')
            qui egen `psd'   = sd(`lhs') if `touse', by(`panelvar')
            qui egen `pcount' = count(`lhs') if `touse', by(`panelvar')
            qui gen `pse' = `psd' / sqrt(`pcount')
            qui gen `plo' = `pmean' - 1.96 * `pse'
            qui gen `phi' = `pmean' + 1.96 * `pse'
            
            * Collapse to one obs per panel
            qui collapse (mean) mean=`pmean' lo=`plo' hi=`phi', by(`panelvar')
            
            qui gen panel_n = _n
            local npg = _N
            
            twoway (bar mean panel_n, fcolor(navy%60) lcolor(navy) barwidth(0.7)) ///
                   (rcap lo hi panel_n, lcolor(cranberry) lwidth(medthick)), ///
                   xlabel(1(1)`npg', valuelabel labsize(small)) ///
                   title("Panel Means with 95% Confidence Intervals") ///
                   subtitle("`lhs' — heterogeneity in mean levels") ///
                   ytitle("Mean `lhs'") xtitle("Panel") ///
                   legend(order(1 "Mean" 2 "95% CI") rows(1) size(small)) ///
                   graphregion(color(white)) scheme(s2color) ///
                   name(xtpre_plotmeans, replace) nodraw
            
            restore
            local _created_plotmeans = 1
        }
        if _rc != 0 {
            capture restore
        }
        
        * --- Display new graphs ---
        if "`_created_radar'" == "1" {
            capture noisily graph display xtpre_radar
            di as result "   xtpre_radar           (Coefficient heterogeneity radar chart)"
        }
        if "`_created_plotmeans'" == "1" {
            capture noisily graph display xtpre_plotmeans
            di as result "   xtpre_plotmeans       (Panel means with 95% CI — bar style)"
        }
        
        * 14. Plotmeans across panels (R gplots style — connected line + CI)
        capture noisily {
            preserve
            collapse (mean) mean_y=`lhs' (sd) sd_y=`lhs' (count) n_y=`lhs' ///
                if `touse', by(`panelvar')
            qui gen se_y = sd_y / sqrt(n_y)
            qui gen lo_y = mean_y - 1.96 * se_y
            qui gen hi_y = mean_y + 1.96 * se_y
            qui gen pn = _n
            local npn = _N
            
            twoway (rcap lo_y hi_y pn, lcolor(blue) lwidth(medium)) ///
                   (connected mean_y pn, ///
                       lcolor(black) lwidth(thin) ///
                       msymbol(circle) mcolor(gs8) msize(medium)), ///
                   xlabel(1(1)`npn', valuelabel labsize(small)) ///
                   title("Heterogeneity across panels") ///
                   ytitle("`lhs'") xtitle("Panel") ///
                   legend(off) ///
                   graphregion(color(white)) scheme(s2color) ///
                   name(xtpre_plotmeans_panel, replace) nodraw
            
            restore
            local _created_pm_panel = 1
        }
        if _rc != 0 {
            capture restore
        }
        
        * 15. Plotmeans across time periods (R gplots style — connected line + CI)
        capture noisily {
            preserve
            collapse (mean) mean_y=`lhs' (sd) sd_y=`lhs' (count) n_y=`lhs' ///
                if `touse', by(`timevar')
            qui gen se_y = sd_y / sqrt(n_y)
            qui gen lo_y = mean_y - 1.96 * se_y
            qui gen hi_y = mean_y + 1.96 * se_y
            
            twoway (rcap lo_y hi_y `timevar', lcolor(blue) lwidth(medium)) ///
                   (connected mean_y `timevar', ///
                       lcolor(black) lwidth(thin) ///
                       msymbol(circle) mcolor(gs8) msize(medium)), ///
                   title("Heterogeneity across time periods") ///
                   ytitle("`lhs'") xtitle("`timevar'") ///
                   legend(off) ///
                   graphregion(color(white)) scheme(s2color) ///
                   name(xtpre_plotmeans_time, replace) nodraw
            
            restore
            local _created_pm_time = 1
        }
        if _rc != 0 {
            capture restore
        }
        
        * --- Display R-style plotmeans ---
        if "`_created_pm_panel'" == "1" {
            capture noisily graph display xtpre_plotmeans_panel
            di as result "   xtpre_plotmeans_panel (Heterogeneity across panels — line+CI)"
        }
        if "`_created_pm_time'" == "1" {
            capture noisily graph display xtpre_plotmeans_time
            di as result "   xtpre_plotmeans_time  (Heterogeneity across time — line+CI)"
        }
        
        di as text ""
        di as result " Diagnostic graphs completed."
        di as text " Use {cmd:graph display <name>} to view any graph again."
        di as text "{hline 78}"
    }
    
    * =========================================================================
    * FINAL SUMMARY
    * =========================================================================
    di as text ""
    di as text "{hline 78}"
    di as text " {bf:OVERALL PRE-TEST SUMMARY}"
    di as text "{hline 78}"
    
    if `run_hsiao' {
        local h1_dec = cond(`F1_p' < 0.05, "Heterogeneous", "Homogeneous")
        local h2_dec = cond(`F2_p' < 0.05, "Heterogeneous", "Homogeneous")
        local h3_dec = cond(`F3_p' < 0.05, "Heterogeneous", "Homogeneous")
        di as text " Hsiao F1 (overall)     : " as result "`h1_dec'" as text " (p=" as result %5.3f `F1_p' as text ")"
        di as text " Hsiao F2 (slopes)      : " as result "`h2_dec'" as text " (p=" as result %5.3f `F2_p' as text ")"
        di as text " Hsiao F3 (intercepts)  : " as result "`h3_dec'" as text " (p=" as result %5.3f `F3_p' as text ")"
    }
    if `run_robust' {
        local rh1_dec = cond(`rF1_p' < 0.05, "Heterogeneous", "Homogeneous")
        local rh2_dec = cond(`rF2_p' < 0.05, "Heterogeneous", "Homogeneous")
        di as text " Robust F1 (overall)    : " as result "`rh1_dec'" as text " (p=" as result %5.3f `rF1_p' as text ")"
        di as text " Robust F2 (slopes)     : " as result "`rh2_dec'" as text " (p=" as result %5.3f `rF2_p' as text ")"
    }
    if `run_hetero' {
        local sw_dec = cond(`swamy_p' < 0.05, "Heterogeneous", "Homogeneous")
        di as text " Swamy (1970) test      : " as result "`sw_dec'" as text " (p=" as result %5.3f `swamy_p' as text ")"
    }
    if `run_csd' {
        local cd_dec = cond(`cd_pval' < 0.05, "Dependent", "Independent")
        di as text " Cross-sect. dependence : " as result "`cd_dec'" as text " (p=" as result %5.3f `cd_pval' as text ")"
    }
    
    * Model recommendation
    di as text ""
    di as text " {ul:Recommended Estimator:}"
    
    local recommend = "Pooled OLS"
    if `run_hsiao' {
        if `F2_p' < 0.05 {
            local recommend = "Mean Group (MG) / CCEMG"
        }
        else if `F3_p' < 0.05 {
            local recommend = "Fixed Effects (FE)"
        }
    }
    * Override with robust results if they are stronger
    if `run_robust' {
        if `rF2_p' < 0.05 & "`recommend'" != "Mean Group (MG) / CCEMG" {
            local recommend = "Mean Group (MG) / CCEMG"
        }
        else if `rF3_p' < 0.05 & "`recommend'" == "Pooled OLS" {
            local recommend = "Fixed Effects (FE)"
        }
    }
    * Override with Swamy if heterogeneity detected
    if `run_hetero' {
        if `swamy_p' < 0.05 & "`recommend'" == "Pooled OLS" {
            local recommend = "Fixed Effects (FE)"
        }
    }
    if `run_csd' {
        if `cd_pval' < 0.05 {
            if "`recommend'" == "Mean Group (MG) / CCEMG" {
                local recommend = "CCEMG (with cross-sectional dependence)"
            }
            else if "`recommend'" == "Fixed Effects (FE)" {
                local recommend = "FE with Driscoll-Kraay SE"
            }
        }
    }
    di as result "  >>> `recommend'"
    di as text "{hline 78}"
    
    return local recommendation "`recommend'"
    return local depvar "`lhs'"
    return local indepvars "`rhs'"
    return scalar N = `N'
    return scalar T = `T'
    
end

* =========================================================================
* MATA HELPER FUNCTIONS
* =========================================================================
mata:

// Compute single heterogeneity statistic
void _xtpretest_onestat(real matrix vals, real scalar n, string scalar sname) {
    real colvector v
    v = vec(vals)
    v = select(v, v :!= .)
    
    real scalar result
    
    if (sname == "Mean") {
        result = mean(v)
    }
    else if (sname == "Median") {
        real colvector sv
        sv = sort(v, 1)
        real scalar mid
        mid = floor(rows(sv)/2) + 1
        if (mod(rows(sv), 2) == 0) {
            result = (sv[mid-1] + sv[mid]) / 2
        }
        else {
            result = sv[mid]
        }
    }
    else if (sname == "Std.Dev") {
        result = sqrt(variance(v))
    }
    else if (sname == "IQR") {
        real colvector sv2
        sv2 = sort(v, 1)
        real scalar q1idx, q3idx
        q1idx = max((1, floor(rows(sv2)*0.25)))
        q3idx = min((rows(sv2), ceil(rows(sv2)*0.75)))
        result = sv2[q3idx] - sv2[q1idx]
    }
    else if (sname == "Skewness") {
        real scalar m, s
        m = mean(v)
        s = sqrt(variance(v))
        if (s > 0) {
            result = mean(((v :- m) :/ s) :^3)
        }
        else result = 0
    }
    else if (sname == "Kurtosis") {
        real scalar m2, s2
        m2 = mean(v)
        s2 = sqrt(variance(v))
        if (s2 > 0) {
            result = mean(((v :- m2) :/ s2) :^4)
        }
        else result = 0
    }
    else if (sname == "Min") {
        result = min(v)
    }
    else if (sname == "Max") {
        result = max(v)
    }
    else {
        result = .
    }
    
    st_numscalar("__hetval", result)
}

// Compute between-panel variance
void _xtpretest_bvar(real matrix ib, real scalar n, real scalar col) {
    real colvector v
    v = ib[., col]
    v = select(v, v :!= .)
    st_numscalar("__bvar", variance(v))
}

// Compute heterogeneity stats (legacy helper)
void _xtpretest_hetstat(real matrix vals, real scalar n) {
    real colvector v
    v = vec(vals)
    v = select(v, v :!= .)
    // just placeholder — actual computation via _xtpretest_onestat
}

// Cross-sectional dependence test (Pesaran 2004)
void _xtpretest_cd(string scalar residvar, string scalar idvar, 
                    string scalar tvar, string scalar tousevar) {
    
    real matrix resid, ids, times
    resid = st_data(., residvar, tousevar)
    ids   = st_data(., idvar, tousevar)
    times = st_data(., tvar, tousevar)
    
    // Get unique panels
    real colvector uid
    uid = uniqrows(ids)
    real scalar Np
    Np = rows(uid)
    
    // Get unique times
    real colvector ut
    ut = uniqrows(times)
    real scalar Tp
    Tp = rows(ut)
    
    // Build residual matrix: T x N
    real matrix R
    R = J(Tp, Np, .)
    
    real scalar i, j, t_idx
    for (i=1; i<=rows(resid); i++) {
        real scalar pi, ti
        for (pi=1; pi<=Np; pi++) {
            if (ids[i] == uid[pi]) break
        }
        for (ti=1; ti<=Tp; ti++) {
            if (times[i] == ut[ti]) break
        }
        if (pi <= Np & ti <= Tp) {
            R[ti, pi] = resid[i]
        }
    }
    
    // Compute pairwise correlations
    real scalar cd_sum, rho_sum, npairs
    cd_sum = 0
    rho_sum = 0
    npairs = 0
    
    for (i=1; i<=Np-1; i++) {
        for (j=i+1; j<=Np; j++) {
            real colvector ri, rj
            ri = R[., i]
            rj = R[., j]
            
            // Handle missing
            real colvector valid
            valid = (ri :!= .) :& (rj :!= .)
            real scalar Tij
            Tij = sum(valid)
            
            if (Tij > 2) {
                real colvector ri2, rj2
                ri2 = select(ri, valid)
                rj2 = select(rj, valid)
                
                real scalar rho_ij
                rho_ij = correlation(ri2, rj2)[1,1]
                
                cd_sum = cd_sum + sqrt(Tij) * rho_ij
                rho_sum = rho_sum + abs(rho_ij)
                npairs++
            }
        }
    }
    
    real scalar cd_stat, avg_rho
    cd_stat = sqrt(2 / (Np * (Np-1))) * cd_sum
    avg_rho = rho_sum / max((npairs, 1))
    
    st_numscalar("__cd_stat", cd_stat)
    st_numscalar("__avg_rho", avg_rho)
}

end
