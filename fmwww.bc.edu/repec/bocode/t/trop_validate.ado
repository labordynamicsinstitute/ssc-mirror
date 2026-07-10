/*
    trop_validate --- Pre-estimation data validation for the TROP estimator.

    Validates panel data requirements for the triply robust panel estimator:

    1. Panel structure: unique (i,t) pairs, strictly increasing time within
       each unit, integer time index generation.
    2. Balance diagnostics: panel dimensions (N, T), missingness rate with
       tiered diagnostics, detection of entirely missing rows or columns,
       creation of __trop_valid indicator.
    3. Treatment pattern: binary W in {0,1}, absorbing-state verification,
       classification (single treated, simultaneous, staggered, switching),
       generation of __trop_ever_treated and __trop_T_start.
    4. Outlier detection: Tukey's rule with conservative threshold (k=10).
    5. Covariate balance: optional standardized-difference diagnostics.
    6. Feasibility checks: hard constraints on identification and LOOCV.
    7. Summary report and handoff to estimation routines.
*/


program define trop_validate, eclass
    version 17.0
    syntax varlist(min=2 max=2 numeric) [if] [in], ///
        PANelvar(varname) ///
        TIMevar(varname numeric) ///
        [NOUNiqueness] ///      // skip uniqueness check
        [NOMONotonicity] ///    // skip monotonicity check
        [NOTIMeindex] ///       // skip time-index generation
        [COVariates(varlist)] ///  // covariates for balance diagnostics
        [MCP] ///               // enable extended consistency checks
        [STATEmcp] ///          // alias for mcp
        [METHod(string)]        // estimation method (joint enforces absorbing state)
    
    // Clean up variables that may persist from a previous call
    _trop_cleanup_vars
    
    // Parse variable list: outcome and treatment
    tokenize `varlist'
    local depvar `1'
    local treatvar `2'
    
    // Mark estimation sample
    marksample touse, novarlist
    
    // Display validation header
    di as text _newline "{bf:TROP Data Validation: Panel Structure}"
    di as text "{hline 70}"
    di as text "Requirements:"
    di as text "  - Unique (i,t) pairs for N x T matrix representation"
    di as text "  - Strictly increasing time within each unit"
    di as text "{hline 70}" _newline
    
    // Preserve original observation order
    tempvar orig_order
    gen long `orig_order' = _n
    
    // Step 1: Sort data and declare panel structure
    di as text "Step 1: Sorting and panel setup..." _continue
    sort `panelvar' `timevar'
    
    // Attempt tsset to register the panel structure
    capture tsset `panelvar' `timevar', noquery
    local tsset_rc = _rc
    if `tsset_rc' != 0 {
        di as text _n "  NOTE: tsset failed; proceeding with manual checks"
    }
    di as result " done"
    
    // Step 2: Verify uniqueness of (i,t) pairs
    if "`nouniqueness'" == "" {
        di as text "Step 2: (i,t) uniqueness check..." _continue
        
        // If tsset succeeded, Stata already verified uniqueness
        local already_tsset = (`tsset_rc' == 0)
        
        if `already_tsset' {
            // Panel structure already validated by tsset
            di as result " passed (panel structure verified)"
        }
        else {
            // tsset unavailable; run explicit duplicate check
            qui duplicates report `panelvar' `timevar' if `touse'
            local n_unique = r(unique_value)
            local n_total  = r(N)
            
            // Duplicates detected — report and abort
            if `n_unique' < `n_total' {
            di as error " FAILED"
            di ""
            
            // Tag duplicate observations
            qui duplicates tag `panelvar' `timevar' if `touse', gen(__trop_dup_count)
            
            // Count duplicate observations
            qui count if __trop_dup_count > 0 & `touse'
            local n_dup_obs = r(N)
            qui tab __trop_dup_count if __trop_dup_count > 0 & `touse', matcell(dup_freq)
            
            di as error "{bf:ERROR: Duplicate (i,t) pairs detected}"
            di as error "The N x T matrix representation requires each (i,t) to be unique."
            di as error "Found `n_dup_obs' observations with duplicate (i,t)."
            di as error "(unique pairs: `n_unique' < total observations: `n_total')"
            
            di as text _newline "{bf:Consequences:}"
            di as text "  1. Fixed-effect estimates biased by double counting"
            di as text "  2. LOOCV cannot uniquely identify the held-out observation"
            di as text "  3. Unit-distance sums distorted"
            
            di as text _newline "{bf:First 10 duplicate (i,t) pairs:}"
            list `panelvar' `timevar' `depvar' `treatvar' __trop_dup_count ///
                if __trop_dup_count > 0 & `touse' in 1/10, ///
                table separator(0) abbrev(12)
            
            di as text _newline "{bf:Suggested remedies:}"
            di as text "  1. Drop duplicate rows:"
            di as text "     {stata duplicates drop `panelvar' `timevar', force}"
            di as text ""
            di as text "  2. Collapse to unique (i,t):"
            di as text "     {stata collapse (mean) `depvar' `treatvar', by(`panelvar' `timevar')}"
            di as text ""
            di as text "  3. Verify data source for merge or append errors"
            
            drop __trop_dup_count
                error 459
            }
            
            di as result " passed (unique N x T structure)"
        }
    }
    else {
        di as text "Step 2/3: (i,t) uniqueness check..." ///
            as result " skipped"
    }
    
    // Step 3: Verify strict monotonicity of the time variable
    if "`nomonotonicity'" == "" {
        di as text "Step 3: Time monotonicity check..." _continue
        
        // Compute within-unit time differences
        tempvar time_diff
        qui by `panelvar': gen double `time_diff' = `timevar' - `timevar'[_n-1] if `touse'
        
        // Detect non-monotonic observations (diff <= 0 means not strictly increasing)
        qui count if `time_diff' <= 0 & !missing(`time_diff') & `touse'
        local n_nonmono = r(N)
        
        // Non-monotonic time detected — report and abort
        if `n_nonmono' > 0 {
            di as error " FAILED"
            di ""
            
            // Flag offending units
            tempvar has_nonmono
            qui by `panelvar': egen byte `has_nonmono' = max(`time_diff' <= 0 & !missing(`time_diff') & `touse')
            
            di as error "{bf:ERROR: `n_nonmono' non-monotonic time observations detected}"
            di as error "The time distance dist^time(s,t) = |t - s| requires a strict total order."
            
            di as text _newline "{bf:Consequences:}"
            di as text "  1. Time distance |t-s| loses interpretability"
            di as text "  2. Exponential time weights break down"
            di as text "  3. LOOCV time-neighbourhood selection is invalid"
            
            // List up to 10 offending units
            di as text _newline "{bf:First 10 non-monotonic units:}"
            qui levelsof `panelvar' if `has_nonmono' == 1 & `touse', local(bad_units)
            local count = 0
            foreach uid of local bad_units {
                if `count' >= 10 {
                    continue, break
                }
                di as text _newline "  Unit {bf:`uid'}:"
                qui levelsof `timevar' if `panelvar' == `uid' & `touse', local(times) clean
                di as text "    Time sequence: `times'"
                local count = `count' + 1
            }
            
            di as text _newline "{bf:Suggested remedies:}"
            di as text "  1. Sort the data:"
            di as text "     {stata sort `panelvar' `timevar'}"
            di as text ""
            di as text "  2. Inspect the time variable for data-entry errors:"
            di as text "     {stata list `panelvar' `timevar' if `has_nonmono'==1}"
            di as text ""
            di as text "  3. Verify consistent time encoding across units"
            di as text ""
            di as text "  4. Re-run the uniqueness check to rule out duplicates"
            
            error 498
        }
        
        di as result " passed (time is strictly increasing)"
        
        // Persist time differences for the balance check
        qui gen double __trop_time_diff = `time_diff' if `touse'
        label variable __trop_time_diff "Time difference between consecutive periods"
    }
    else {
        di as text "Step 3/3: Time monotonicity check..." ///
            as result " skipped"
    }
    
    // Generate integer time index (1, 2, 3, ...)
    if "`notimeindex'" == "" {
        di as text _newline "Additional step: Generating time index..." _continue
        
        // Map timevar to consecutive integers
        qui egen int __trop_tindex = group(`timevar') if `touse'
        label variable __trop_tindex "Integer time index"
        
        // Store time range
        qui summarize `timevar' if `touse', meanonly
        local time_min = r(min)
        local time_max = r(max)
        local time_range = `time_max' - `time_min'
        
        // Verify __trop_tindex is strictly increasing within each unit
        tempvar tindex_diff
        qui by `panelvar': gen double `tindex_diff' = __trop_tindex - __trop_tindex[_n-1] if `touse'
        qui count if `tindex_diff' <= 0 & !missing(`tindex_diff') & `touse'
        if r(N) > 0 {
            di as error " FAILED"
            di as error "ERROR: __trop_tindex is not strictly increasing (internal error)"
            error 498
        }
        
        // Return time-range information
        ereturn scalar time_min = `time_min'
        ereturn scalar time_max = `time_max'
        ereturn scalar time_range = `time_range'
        
        di as result " done (time_min=`time_min', time_max=`time_max')"
    }
    else {
        di as text _newline "Additional step: Generating time index..." ///
            as result " skipped"
    }
    
    // Restore original observation order
    sort `orig_order'
    
    // Panel structure validation summary
    di as text _newline "{hline 70}"
    di as result "{bf:Panel structure validation passed}"
    di as text "  - (i,t) uniqueness: N x T matrix representation valid"
    di as text "  - Time monotonicity: time-distance computation valid"
    di as text "  - Time index: __trop_tindex generated"
    di as text "{hline 70}" _newline
    
    // ========================================================================
    // Balance diagnostics and missingness analysis
    // ========================================================================
    trop_balance_check `depvar' `treatvar' if `touse', ///
        panelvar(`panelvar') timevar(`timevar')
        
    // Retrieve balance-check results for subsequent use
    local N = e(N)
    local T = e(T)
    local N_obs = e(N_obs)
    local miss_rate = e(miss_rate)
    local balanced = e(balanced)
    
    // ========================================================================
    // Step 7: Verify binary treatment variable
    // ========================================================================
    di as text _newline "Step 7: Treatment binary check..." _continue
    
    // Count distinct treatment values (excluding missing)
    qui levelsof `treatvar' if `touse', local(unique_vals) clean
    local n_unique = r(r)
    
    // Check whether values are exactly {0, 1}
    local has_zero = 0
    local has_one = 0
    foreach val of local unique_vals {
        if `val' == 0 local has_zero = 1
        if `val' == 1 local has_one = 1
    }
    local is_binary = (`n_unique' == 2) & `has_zero' & `has_one'
    
    // Non-binary treatment detected — report and abort
    if !`is_binary' {
        di as error " FAILED"
        di ""
        
        di as error "{bf:ERROR: Non-binary treatment variable detected}"
        di as error "The TROP estimator requires a binary treatment, W in {0,1}."
        
        di as error _newline "Found {bf:`n_unique'} distinct values: {bf:`unique_vals'}"
        
        // Tabulate observation counts by treatment value
        di as text _newline "{bf:Distribution of treatment values:}"
        qui tab `treatvar' if `touse', matrow(vals) matcell(counts)
        forvalues i = 1/`r(r)' {
            local val = vals[`i',1]
            local cnt = counts[`i',1]
            di as text "  W = `val': `cnt' obs"
        }
        
        di as text _newline "{bf:Consequences:}"
        di as text "  1. Potential-outcomes framework undefined for non-binary W"
        di as text "  2. ATT requires binary treatment"
        di as text "  3. Triply-robust property assumes binary treatment"
        
        di as text _newline "{bf:Suggested remedies:}"
        di as text "  1. Check for data-entry errors:"
        di as text "     {stata tab `treatvar'}"
        di as text ""
        di as text "  2. Dichotomise the treatment (choose a threshold):"
        di as text "     {stata generate W_binary = (`treatvar' >= threshold)}"
        di as text ""
        di as text "  3. For continuous-dose treatments, TROP does not apply."
        di as text "     Consider dose-response methods instead."
        di as text ""
        di as text "  4. For multi-valued W, define separate binary contrasts:"
        di as text "     e.g., W_low = (W==1), W_high = (W==2)"
        di as text "     and run TROP separately for each contrast."
        
        ereturn scalar data_validated = 0
        error 450
    }
    
    di as result " passed (W in {0,1})"
    
    // ========================================================================
    // Step 8: Treatment pattern identification
    // ========================================================================
    di as text _newline "Step 8: Treatment pattern identification..." _continue
    
    // Sub-step 1: Compute ever-treated indicator
    qui bysort `panelvar': egen byte __trop_ever_treated = max(`treatvar') if `touse'
    label variable __trop_ever_treated "Ever-treated indicator"
    
    // Count distinct treated units
    tempvar unit_id_treated
    qui egen `unit_id_treated' = tag(`panelvar') if __trop_ever_treated == 1 & `touse'
    qui count if `unit_id_treated' == 1
    local N_treated_units = r(N)
    
    // Sub-step 2: Compute first treatment time for each unit
    tempvar first_treat_time
    qui bysort `panelvar': egen `first_treat_time' = min(`timevar') if `treatvar' == 1 & `touse'
    qui bysort `panelvar': egen double __trop_T_start = min(`first_treat_time') if `touse'
    label variable __trop_T_start "First treatment period"
    
    // Sub-step 3: Count treatment switches
    sort `panelvar' `timevar'
    qui by `panelvar': gen byte __trop_W_diff = (`treatvar' != `treatvar'[_n-1]) if _n > 1 & `touse'
    qui bysort `panelvar': egen int __trop_n_switches = total(__trop_W_diff) if `touse'
    
    // Sub-step 3b: Verify absorbing state — treatment must be non-decreasing
    // Once treated, a unit remains treated (no treatment reversal).
    // NOTE: This constraint is only required by method(joint), whose single
    // scalar-tau WLS assumes an absorbing (non-decreasing) treatment path.
    // The twostep method (and the Rust core) support arbitrary 0/1 treatment
    // matrices, including switching treatment, so it is not enforced there.
    tempvar _W_decrease _has_decrease
    qui by `panelvar': gen byte `_W_decrease' = (`treatvar'[_n-1] == 1 & `treatvar' == 0) ///
        if _n > 1 & `touse'
    qui bysort `panelvar': egen byte `_has_decrease' = max(`_W_decrease') if `touse'
    qui sum `_has_decrease' if `touse', meanonly
    if r(max) == 1 & "`method'" == "joint" {
        // List offending units
        di as result " done"
        di ""
        di as error "{bf:ERROR: Treatment indicator violates absorbing-state assumption}"
        di as error "Once W_it = 1, subsequent periods must remain treated."
        di as error "Treatment must be monotonically non-decreasing."
        
        // List up to 10 offending units
        tempvar _unit_tag_viol
        qui egen `_unit_tag_viol' = tag(`panelvar') if `_has_decrease' == 1 & `touse'
        qui levelsof `panelvar' if `_unit_tag_viol' == 1 & `touse', local(viol_units)
        local n_viol : word count `viol_units'
        di as error "Found `n_viol' offending units"
        
        di as text _newline "{bf:Treatment sequences of offending units (first 10):}"
        local viol_count = 0
        foreach uid of local viol_units {
            if `viol_count' >= 10 {
                di as text "  ... (`n_viol' offending units total)"
                continue, break
            }
            qui levelsof `treatvar' if `panelvar' == `uid' & `touse', local(d_seq) clean
            di as text "  Unit `uid': D = `d_seq'"
            local viol_count = `viol_count' + 1
        }
        
        di as text _newline "{bf:Suggested remedies:}"
        di as text "  Convert treatment to absorbing state:"
        di as text "  D[t, i] = 1 for all t >= first treatment period"
        di as text "  e.g.: bysort `panelvar' (`timevar'): replace `treatvar' = 1 if `treatvar'[_n-1] == 1"
        
        drop `_W_decrease' `_has_decrease'
        error 459
    }
    drop `_W_decrease' `_has_decrease'
    
    // Sub-step 4: Count distinct adoption cohorts
    tempvar adoption_time
    qui egen `adoption_time' = group(__trop_T_start) if !missing(__trop_T_start) & `touse'
    qui levelsof `adoption_time' if `touse', local(adoption_cohorts)
    local n_adoption_times : word count `adoption_cohorts'
    if `n_adoption_times' == 0 {
        local n_adoption_times = 0  // handle case with no treated units
    }
    
    // Sub-step 5: Count periods containing treated observations
    qui bysort `timevar': egen byte __trop_any_treated_t = max(`treatvar') if `touse'
    
    // Count distinct treated periods
    tempvar time_id_treated
    qui egen `time_id_treated' = tag(`timevar') if __trop_any_treated_t == 1 & `touse'
    qui count if `time_id_treated' == 1
    local T_treat_periods = r(N)
    
    // Sub-step 6: Classify pattern (priority: switching > staggered > simultaneous > single)
    qui sum __trop_n_switches if `touse', meanonly
    local max_switches = r(max)
    if missing(`max_switches') local max_switches = 0
    
    if `max_switches' >= 2 {
        local pattern = "switching_treatment"
        local has_switching = 1
        
        di as result " done"
        di ""
        di as text "{bf:WARNING: Switching treatment detected}"
        di as text "max_switches = {bf:`max_switches'} >= 2"
        di as text "The estimator assumes no dynamic treatment effects."
        
        di as text _newline "{bf:Implications:}"
        di as text "  - Switching treatment lies outside the estimator's theoretical scope"
        di as text "  - TROP estimates contemporaneous effects, not cumulative ones"
        di as text "  - Standard replication exercises exclude such data"
        di as text "  - Consider event-study or dynamic panel methods if needed"
    }
    else if `n_adoption_times' > 1 {
        local pattern = "staggered_adoption"
        local has_switching = 0
        
        di as result " done"
        di ""
        di as text "{bf:Identified as staggered adoption:}"
        di as text "  N_treated_units = {bf:`N_treated_units'}"
        di as text "  Adoption cohorts  = {bf:`n_adoption_times'}"
        di as text "  Adoption time distribution:"
        qui levelsof __trop_T_start if !missing(__trop_T_start) & `touse', local(adoption_times) clean
        foreach t of local adoption_times {
            tempvar unit_at_t
            qui egen `unit_at_t' = tag(`panelvar') if __trop_T_start == `t' & `touse'
            qui count if `unit_at_t' == 1
            local n_units_at_t = r(N)
            di as text "    Period `t': `n_units_at_t' units begin treatment"
        }
    }
    else if `N_treated_units' > 1 {
        local pattern = "multiple_treated_simultaneous"
        local has_switching = 0
        
        di as result " done"
        di ""
        di as text "{bf:Identified as multiple treated, simultaneous adoption:}"
        di as text "  N_treated_units = {bf:`N_treated_units'}"
        qui levelsof __trop_T_start if !missing(__trop_T_start) & `touse', local(start_time) clean
        di as text "  Adoption time = {bf:`start_time'} (all treated units start simultaneously)"
    }
    else {
        local pattern = "single_treated_unit"
        local has_switching = 0
        
        di as result " done"
        di ""
        di as text "{bf:Identified as single treated unit:}"
        di as text "  N_treated_units = {bf:1}"
        qui levelsof `panelvar' if __trop_ever_treated == 1 & `touse', local(treated_unit) clean
        di as text "  Treated unit: {bf:`treated_unit'}"
    }
    
    // Sub-step 7a: Compute n_pre_periods and n_post_periods
    qui sum __trop_T_start if `touse', meanonly
    local global_first_treat = r(min)
    local n_pre_periods = 0
    local n_post_periods = `T_treat_periods'
    if !missing(`global_first_treat') {
        // n_pre_periods: number of periods before first treatment
        tempvar _time_tag_pre
        qui egen `_time_tag_pre' = tag(`timevar') if `timevar' < `global_first_treat' & `touse'
        qui count if `_time_tag_pre' == 1
        local n_pre_periods = r(N)
        // n_post_periods: number of periods with any D=1 from first treatment onward
        // (= T_treat_periods, computed in sub-step 5)
    }
    
    // Sub-step 7b: Store results in ereturn
    ereturn local treatment_pattern "`pattern'"
    ereturn scalar N_treated_units = `N_treated_units'
    ereturn scalar T_treat_periods = `T_treat_periods'
    ereturn scalar has_switching = `has_switching'
    ereturn scalar max_switches = `max_switches'
    // Store pre/post period counts in ereturn
    ereturn scalar n_pre_periods = `n_pre_periods'
    ereturn scalar n_post_periods = `n_post_periods'
    
    // Display verification summary
    di as text _newline "{hline 70}"
    di as result "{bf:Treatment pattern verification passed}"
    di as text "  - Binary treatment: W in {0,1} confirmed"
    di as text "  - Pattern: {bf:`pattern'}"
    di as text "  - N_treated_units: {bf:`N_treated_units'}"
    di as text "  - T_treat_periods: {bf:`T_treat_periods'}"
    if `has_switching' {
        di as text "  - Switching detected: {bf:Yes} (max_switches=`max_switches')"
    }
    else {
        di as text "  - Switching detected: No"
    }
    di as text "{hline 70}" _newline
    
    // ========================================================================
    // Step 9: Outlier detection (Tukey's rule, k=10 conservative threshold)
    // ========================================================================
    di as text _newline "{bf:Step 9: Outlier detection (Tukey's rule, k=10)...}"
    di as text "{hline 70}"
    di as text "Theoretical basis:"
    di as text "  • Fixed-effect estimation is sensitive to extreme values."
    di as text "  • SVD decomposition amplifies ill-conditioned data."
    di as text "  • Unit-distance computation depends on outcome magnitudes."
    di as text "{hline 70}" _newline
    
    // Step 1: Compute quartiles (excluding missing values)
    qui _pctile `depvar' if !missing(`depvar') & `touse', p(25 75)
    local Q1 = r(r1)
    local Q3 = r(r2)
    local IQR = `Q3' - `Q1'
    
    // Step 2: Define outlier bounds (k=10 conservative threshold)
    local k = 10
    local lower = `Q1' - `k' * `IQR'
    local upper = `Q3' + `k' * `IQR'
    
    // Step 3: Flag potential outliers
    qui gen byte __trop_outlier_flag = (`depvar' < `lower' | `depvar' > `upper') ///
        if !missing(`depvar') & `touse'
    qui replace __trop_outlier_flag = 0 if missing(`depvar') | !`touse'
    label variable __trop_outlier_flag "Outlier indicator"
    
    // Step 4: Count outliers and calculate rate
    qui count if __trop_outlier_flag == 1 & `touse'
    local n_outliers = r(N)
    qui count if !missing(`depvar') & `touse'
    local N_valid_depvar = r(N)
    local outlier_rate = cond(`N_valid_depvar' > 0, `n_outliers' / `N_valid_depvar', 0)
    
    // Step 5: Report outlier statistics
    di as text "Quartile diagnostics:"
    di as text "  Q1 (25th percentile) = " %12.4f `Q1'
    di as text "  Q3 (75th percentile) = " %12.4f `Q3'
    di as text "  IQR (Interquartile Range) = " %12.4f `IQR'
    di as text ""
    di as text "Outlier bounds (Tukey's rule with k=10):"
    di as text "  Lower bound = Q1 - 10*IQR = " %12.4f `lower'
    di as text "  Upper bound = Q3 + 10*IQR = " %12.4f `upper'
    di as text ""
    
    if `n_outliers' > 0 {
        di as text "Result: found {bf:`n_outliers'} potential outliers"
        di as text "        Rate: " %5.3f `outlier_rate'*100 "% (based on `N_valid_depvar' valid obs)"
        
        // List up to 10 outliers (sorted by absolute deviation from median)
        tempvar abs_deviation
        qui gen double `abs_deviation' = abs(`depvar' - ((`Q1' + `Q3')/2)) ///
            if __trop_outlier_flag == 1 & `touse'
        
        di as text _newline "Top 10 outliers (sorted by deviation from median):"
        preserve
        qui keep if __trop_outlier_flag == 1 & `touse'
        qui count
        local n_to_show = min(r(N), 10)
        if `n_to_show' > 0 {
            qui gsort -`abs_deviation'
            list `panelvar' `timevar' `depvar' in 1/`n_to_show', ///
                noobs table separator(0) abbrev(12)
        }
        restore
        
        di as text _newline "WARNING: Outliers are flagged but NOT removed."
        di as text "Variable __trop_outlier_flag created (0=normal, 1=outlier)"
        di as text ""
        di as text "{bf:Suggested actions:}"
        di as text "  1. Winsorization (recommended):"
        di as text "     replace `depvar' = `upper' if `depvar' > `upper'"
        di as text "     replace `depvar' = `lower' if `depvar' < `lower'"
        di as text "     Reason: Limits extreme values while preserving data structure."
        di as text ""
        di as text "  2. Drop outliers:"
        di as text "     drop if __trop_outlier_flag == 1"
        di as text "     Reason: If outliers are due to data entry errors."
        di as text "     WARNING: Dropping observations reduces sample size."
        di as text ""
        di as text "  3. Create a dummy variable for outliers:"
        di as text "     gen outlier_dummy = __trop_outlier_flag"
        di as text ""
        di as text "  4. Check data source:"
        di as text "     list `panelvar' `timevar' `depvar' if __trop_outlier_flag == 1"
        di as text "     Verify if these are real economic shocks or errors."
    }
    else {
        di as result "Result: {bf:No extreme outliers detected}"
        di as text "All observations satisfy bounds [" %12.4f `lower' ", " %12.4f `upper' "]"
    }
    
    // ========================================================================
    // Covariate balance diagnostics
    // ========================================================================
    
    // Check if covariates are provided
    local has_covariates = ("`covariates'" != "")
    
    if `has_covariates' == 0 {
        // No covariates: skip
        di as text _newline "Covariate balance check: skipped (no covariates provided)"
        di as text "  Baseline model uses factor model only." _newline
    }
    else {
        // ========== Execute covariate balance diagnostics ==========
        di as text _newline "{hline 60}"
        di as text "{bf:Covariate balance diagnostics}"
        di as text "{hline 60}"
        di as text "Theoretical basis: Covariate bias decomposition"
        di as text "Covariates: `covariates'"
        
        // Step 1: Define pre-treatment period
        // Reuse __trop_T_start if available
        capture confirm variable __trop_first_treat_time
        if _rc != 0 {
            // If not available, compute manually
            qui bysort `panelvar': egen __trop_first_treat_time = min(`timevar') if `treatvar' == 1 & `touse'
        }
        
        qui sum __trop_first_treat_time if `touse'
        local t0 = r(min)  // Global first treatment period
        
        // Boundary case: no treated observations
        if missing(`t0') {
            di as text _newline "  NOTE: No treated observations (all W=0), using all-period covariates"
            local t0 = .
        }
        else {
            di as text "Pre-treatment period definition: t < `t0' (first treatment period)"
        }
        
        // Mark pre-treatment period
        qui gen byte __trop_is_pretreat = (`timevar' < `t0') if !missing(`t0') & `touse'
        if missing(`t0') {
            qui replace __trop_is_pretreat = 1 if `touse'  // All periods
        }
        
        // Edge case: no pre-treatment observations
        qui count if __trop_is_pretreat == 1 & `touse'
        if r(N) == 0 {
            di as text _newline "{bf:WARNING}: Pre-treatment period is empty (t_0 = `t0' is the first period)"
            di as text "  Covariate balance cannot be calculated."
            di as text "  Skipping covariate balance diagnostics." _newline
            drop __trop_is_pretreat
        }
        else {
            // ========== Step 2: Compute Standardized Difference for each covariate ==========
            local n_covariates = 0
            local n_good = 0
            local n_acceptable = 0
            local n_moderate_imbalance = 0
            local n_severe_imbalance = 0
            
            foreach x of local covariates {
                local n_covariates = `n_covariates' + 1
                
                di as text _newline "Covariate: {bf:`x'}"
                
                // === Compute stats for treated units (pre-treatment, ever-treated) ===
                qui sum `x' if __trop_is_pretreat == 1 & __trop_ever_treated == 1 & __trop_valid == 1 & `touse'
                
                // Edge case: no treated observations
                if r(N) == 0 {
                    di as text "  {bf:WARNING}: No valid treated observations in pre-treatment period, skipping"
                    continue
                }
                
                local mean_t = r(mean)
                local sd_t   = r(sd)
                local N_t    = r(N)
                
                // === Compute stats for control units (pre-treatment, never-treated) ===
                qui sum `x' if __trop_is_pretreat == 1 & __trop_ever_treated == 0 & __trop_valid == 1 & `touse'
                
                // Edge case: no control observations
                if r(N) == 0 {
                    di as text "  {bf:WARNING}: No valid control observations in pre-treatment period, skipping"
                    continue
                }
                
                local mean_c = r(mean)
                local sd_c   = r(sd)
                local N_c    = r(N)
                
                // === Compute standardized difference ===
                local diff = `mean_t' - `mean_c'
                local sd_pool = sqrt((`sd_t'^2 + `sd_c'^2) / 2)
                
                // Zero variance check
                if `sd_pool' < 1e-10 {
                    di as text "  {bf:WARNING}: Covariate has near-zero variance, StdDiff undefined"
                    di as text "  sd_pooled = " %9.3e `sd_pool' " < 1e-10"
                    continue
                }
                
                local std_diff = `diff' / `sd_pool'
                
                // === Format output ===
                di as text "  - Treated (N=`N_t'): Mean=" %9.3f `mean_t' ", SD=" %8.3f `sd_t'
                di as text "  - Control (N=`N_c'): Mean=" %9.3f `mean_c' ", SD=" %8.3f `sd_c'
                di as text "  - Raw diff: " %9.3f `diff'
                di as text "  - Std diff: " %6.3f `std_diff'
                
                // === Severity warnings ===
                if abs(`std_diff') > 0.5 {
                    di as text "      {bf:WARNING: Severe imbalance} (|StdDiff| = " %6.3f abs(`std_diff') " > 0.5)"
                    di as text "      Covariate bias term may dominate total bias."
                    di as text "      Strongly recommended:"
                    di as text "        (1) Include `x' in covariates()"
                    di as text "        (2) Use PSM pre-matching"
                    di as text "        (3) Report sensitivity analysis"
                    local n_severe_imbalance = `n_severe_imbalance' + 1
                }
                else if abs(`std_diff') > 0.25 {
                    di as text "      {bf:WARNING: Imbalance} (|StdDiff| = " %6.3f abs(`std_diff') " > 0.25)"
                    di as text "      Recommended:"
                    di as text "        (1) Include `x' in covariates()"
                    di as text "        (2) Report sensitivity analysis"
                    local n_moderate_imbalance = `n_moderate_imbalance' + 1
                }
                else if abs(`std_diff') > 0.1 {
                    di as text "      Mild imbalance (|StdDiff| = " %6.3f abs(`std_diff') " <= 0.25, acceptable)"
                    local n_acceptable = `n_acceptable' + 1
                }
                else {
                    di as text "      Balanced (|StdDiff| = " %6.3f abs(`std_diff') " <= 0.1)"
                    local n_good = `n_good' + 1
                }
            }
            
            // ========== Step 3: Summary Report ==========
            di as text _newline "{hline 60}"
            di as text "{bf:Covariate balance summary}"
            di as text "{hline 60}"
            di as text "Total covariates: `n_covariates'"
            di as text "Balanced (|StdDiff|<=0.1): `n_good'"
            di as text "Acceptable (0.1<|StdDiff|<=0.25): `n_acceptable'"
            di as text "Imbalanced (0.25<|StdDiff|<=0.5): `n_moderate_imbalance'"
            di as text "Severely Imbalanced (|StdDiff|>0.5): `n_severe_imbalance'"
            
            // Overall assessment
            if `n_severe_imbalance' > 0 {
                di as text _newline "{bf:WARNING: Severe overall imbalance}"
                di as text "Covariate bias may dominate total estimation bias."
                di as text "Strongly recommended:"
                di as text "  1. Use covariate extension: trop Y W `covariates', covariates(`covariates') ..."
                di as text "  2. Pre-matching strategies (PSM/trajectory balancing)"
                di as text "  3. Sensitivity analysis"
            }
            else if `n_moderate_imbalance' > 0 {
                di as text _newline "Overall assessment: Moderate imbalance"
                di as text "Recommended: Include imbalanced variables in covariates()"
                di as text "             or perform sensitivity analysis"
            }
            else {
                di as text _newline "Overall assessment: Good covariate balance"
                di as text "Standard TROP (no covariates) or covariate-adjusted TROP both viable"
            }
            di as text "{hline 60}" _newline
            
            // ========== Cleanup temporary variables ==========
            drop __trop_is_pretreat
            
            // __trop_first_treat_time may be reused by subsequent steps, keep it
        }
    }
    
    // ========================================================================
    // Feasibility and identification checks
    // ========================================================================
    
    /*
    Feasibility checks ensure the TROP estimator and LOOCV are theoretically
    feasible on the current dataset. Returns hard errors for unidentified or
    extremely sparse situations.

    7 hard constraints:
    - Check 0.1: Var(Y) > 0 (outcome non-degenerate)
    - Check 0.2: N_treated_units >= 1 (treated units exist)
    - Check 1:   N_control >= 1 (control observations exist)
    - Check 2:   N_control_units >= 2 (sufficient control units)
    - Check 3:   min_pre_treated >= 2 (pre-treatment period length)
    - Check 4:   for all treated i, control periods >= 1
    - Check 5:   min_valid_pairs >= 2 (common control periods)
    */
    
    di as text _newline _newline
    di as text "{hline 60}"
    di as text "{bf:TROP Algorithm Feasibility Check}"
    di as text "{hline 60}"
    di as text "Theoretical basis: Triply robust assumptions"
    di as text "Dimensions: 7 hard constraints (2 degeneracy checks + 5 feasibility checks)"
    di as text "{hline 60}" _newline
    
    // === Check 0.1: Var(Y) > 0 ===
    di as text "Check 0.1: Outcome variable variance..." _continue
    qui sum `depvar' if __trop_valid == 1 & `touse'
    local var_Y = r(Var)
    
    if `var_Y' <= 0 | missing(`var_Y') {
        di as error " FAILED"
        di ""
        di as error "{bf:ERROR}: Outcome variance is zero or missing (Var(Y)=" %9.3e `var_Y' ")"
        di as error "Causal inference premise: If Y has no variation, treatment effect tau is undefined."
        di as error "Meaning: All Y observations are constant or missing."
        di as text _newline "Suggested remedies:"
        di as text "  1. Check data entry: Confirm if Y is constant due to read errors."
        di as text "     sum `depvar'"
        di as text "  2. Check variable selection: Ensure correct outcome variable."
        di as text "     describe `depvar'"
        di as text "  3. Check missing values: If Var is missing, valid obs might be 0."
        di as text "     tab __trop_valid"
        di as text "  4. If Y has no variation, TROP is not applicable."
        
        ereturn scalar data_validated = 0
        error 459
    }
    di as result " passed (Var(Y)=" %9.3f `var_Y' ")"
    
    // === Check 0.2: N_treated_units >= 1 ===
    di as text "Check 0.2: Existence of ever-treated units..." _continue
    // Reuse __trop_ever_treated
    capture confirm variable __trop_ever_treated
    if _rc != 0 {
        qui bysort `panelvar': egen byte __trop_ever_treated_check = max(`treatvar') if `touse'
        local ever_var "__trop_ever_treated_check"
    }
    else {
        local ever_var "__trop_ever_treated"
    }
    
    // Count ever-treated units
    tempvar unit_tag_treat
    qui egen `unit_tag_treat' = tag(`panelvar') if `ever_var' == 1 & `touse'
    qui count if `unit_tag_treat' == 1
    local N_treated_units = r(N)
    
    if `N_treated_units' < 1 {
        di as error " FAILED"
        di ""
        di as error "{bf:ERROR}: No ever-treated units (N_treated_units=0)"
        di as error "ATT is undefined when no units receive treatment."
        di as text _newline "Suggested remedies:"
        di as text "  1. Check treatment variable W: Confirm if all W=0."
        di as text "     tab `treatvar'"
        di as text "  2. Check variable selection: Ensure correct treatment variable."
        di as text "     describe `treatvar'"
        di as text "  3. If no treatment exists, TROP is not applicable."
        
        ereturn scalar data_validated = 0
        error 459
    }
    di as result " passed (N_treated_units=" %3.0f `N_treated_units' ")"
    
    // === Check 1: N_control >= 1 ===
    di as text "Check 1: Existence of global control observations..." _continue
    qui gen byte __trop_is_control_26 = (`treatvar' == 0 & __trop_valid == 1) if `touse'
    qui count if __trop_is_control_26 == 1
    local N_control = r(N)
    
    if `N_control' < 1 {
        di as error " FAILED"
        di ""
        di as error "{bf:ERROR}: No control observations (N_control=0)"
        di as error "The weighted least squares objective sums over control cells only."
        di as error "Without control observations, fixed effects are unidentified."
        di as text _newline "Suggested remedies:"
        di as text "  1. Check treatment variable: Confirm if all W=1."
        di as text "     list `panelvar' `timevar' `treatvar' in 1/20"
        di as text "  2. Check missing values: Confirm if all __trop_valid=0."
        di as text "     tab __trop_valid"
        di as text "  3. Redefine treatment: Relax treatment criteria if too strict."
        di as text "  4. If truly no controls, TROP is not applicable."
        
        capture drop __trop_is_control_26
        ereturn scalar data_validated = 0
        error 459
    }
    di as result " passed (N_control=" %6.0f `N_control' ")"
    
    // === Check 2: N_control_units >= 2 ===
    di as text "Check 2: Control unit size..." _continue
    qui bysort `panelvar': egen byte __trop_max_treat_26 = max(`treatvar') if `touse'
    qui gen byte __trop_never_treated_26 = (__trop_max_treat_26 == 0) if !missing(__trop_max_treat_26)
    tempvar unit_tag_never
    qui egen `unit_tag_never' = tag(`panelvar') if __trop_never_treated_26 == 1 & `touse'
    qui count if `unit_tag_never' == 1
    local N_control_units = r(N)
    qui drop __trop_max_treat_26
    
    if `N_control_units' < 2 {
        di as error " FAILED"
        di ""
        di as error "{bf:ERROR}: Insufficient control units (N_control_units=`N_control_units', required >= 2)"
        di as error "Unit distance computation requires comparison against multiple controls."
        di as error "With only `N_control_units' never-treated units, unit weights degenerate."
        di as text _newline "Suggested remedies:"
        di as text "  1. Reduce treated units: Retain more units as controls."
        di as text "  2. Expand panel: Include more control regions/firms."
        di as text "  3. Redefine ever-treated: Reclassify rarely treated units as controls."
        di as text "  4. If only 1 control exists, TROP is not applicable."
        di as text "     Consider single-control case studies."
        
        capture drop __trop_is_control_26 __trop_never_treated_26
        ereturn scalar data_validated = 0
        error 459
    }
    di as result " passed (N_control_units=" %3.0f `N_control_units' ")"
    
    // === Check 3: min_pre_treated >= 2 ===
    di as text "Check 3: Pre-treatment period length..." _continue
    
    // Reuse __trop_T_start if available
    capture confirm variable __trop_T_start
    if _rc != 0 {
        tempvar first_treat_time
        qui bysort `panelvar': egen `first_treat_time' = min(`timevar') if `treatvar' == 1 & `touse'
        qui bysort `panelvar': egen double __trop_T_start_26 = min(`first_treat_time') if `touse'
        local T_start_var "__trop_T_start_26"
    }
    else {
        local T_start_var "__trop_T_start"
    }
    
    // Calculate valid pre-treatment periods for each ever-treated unit
    qui gen byte __trop_is_pre_26 = (`timevar' < `T_start_var') & __trop_valid == 1 if !missing(`T_start_var') & `touse'
    qui bysort `panelvar': egen int __trop_n_pre_valid_26 = total(__trop_is_pre_26) if `touse'
    
    qui sum __trop_n_pre_valid_26 if `ever_var' == 1 & `touse'
    local min_pre_treated = r(min)
    if missing(`min_pre_treated') local min_pre_treated = 0
    
    if `min_pre_treated' < 2 {
        di as error " FAILED"
        di ""
        di as error "{bf:ERROR}: Insufficient pre-treatment periods (min_pre_treated=`min_pre_treated', required >= 2)"
        di as error "Each treated unit requires >= 2 pre-treatment periods because:"
        di as error "  (1) LOOCV holds out one period, requiring at least one remaining."
        di as error "  (2) Unit distance is based on RMSE over common control periods."
        di as error "  (3) Separating alpha_i and beta_t requires at least 2 periods."
        
        // List offending units
        qui levelsof `panelvar' if `ever_var'==1 & __trop_n_pre_valid_26 < 2 & `touse', local(bad_units) clean
        di as text _newline "Offending units:"
        di as text "  Units with <2 pre-periods: `bad_units'"
        qui sum __trop_n_pre_valid_26 if `ever_var'==1 & __trop_n_pre_valid_26 < 2 & `touse'
        di as text "  Minimum pre-periods for these units: " %1.0f r(min)
        
        di as text _newline "Suggested remedies:"
        di as text "  1. Check treatment start time: Confirm T_i^{start}."
        di as text "     list `panelvar' `timevar' `treatvar' if inlist(`panelvar', `bad_units')"
        di as text "  2. Delay treatment start: Ensure >= 2 pre-periods if justifiable."
        di as text "  3. Drop unit: If truly insufficient history."
        di as text "     drop if inlist(`panelvar', `bad_units')"
        di as text "  4. If all treated units have only 1 pre-treatment period, TROP LOOCV cannot run reliably."
        di as text "     Consider using fixedlambda() or increasing pre-treatment data."
        
        capture drop __trop_is_control_26 __trop_never_treated_26 __trop_is_pre_26 __trop_n_pre_valid_26
        capture drop __trop_T_start_26
        ereturn scalar data_validated = 0
        error 459
    }
    di as result " passed (min_pre_treated=" %3.0f `min_pre_treated' ")"
    
    // === Check 4: For all i in Treated, N_{i,control} >= 1 ===
    di as text "Check 4: Control periods for ever-treated units..." _continue
    
    qui gen byte __trop_is_control_obs_26 = (`treatvar' == 0) & __trop_valid == 1 if `touse'
    qui bysort `panelvar': egen int __trop_n_control_i_26 = total(__trop_is_control_obs_26) if `ever_var' == 1 & `touse'
    
    qui sum __trop_n_control_i_26 if `ever_var' == 1 & `touse'
    local min_control_per_unit = r(min)
    if missing(`min_control_per_unit') local min_control_per_unit = 0
    
    if `min_control_per_unit' < 1 {
        di as error " FAILED"
        di ""
        qui levelsof `panelvar' if `ever_var' == 1 & __trop_n_control_i_26 == 0 & `touse', local(bad_units) clean
        di as error "{bf:ERROR}: Ever-treated units found with treatment in all periods"
        di as error "Offending units: `bad_units'"
        di as error "LOOCV requires control periods (W_it=0) for each treated unit."
        di as error "These units have no control periods for constructing pseudo-treatment points."
        
        di as text _newline "Suggested remedies:"
        di as text "  1. Check treatment coverage: Confirm if unit is truly treated in all periods."
        di as text "     list `panelvar' `timevar' `treatvar' if `panelvar' inlist(`bad_units')"
        di as text "  2. Shorten treatment period: Treat only later periods if justifiable."
        di as text "  3. Drop unit: If unit is truly treated throughout."
        di as text "     drop if `panelvar' inlist(`bad_units')"
        di as text "     Note: Re-check N_control_units >= 2 after dropping."
        di as text "  4. Redesign: If most units are always treated, TROP may not apply."
        
        capture drop __trop_is_control_26 __trop_never_treated_26 __trop_is_pre_26 __trop_n_pre_valid_26
        capture drop __trop_is_control_obs_26 __trop_n_control_i_26 __trop_T_start_26
        ereturn scalar data_validated = 0
        error 459
    }
    di as result " passed (All ever-treated units have control periods)"
    
    // === Check 5: min_valid_pairs >= 2 ===
    di as text "Check 5: Common control periods (Mata vectorized)..." _continue
    
    // Prepare data: Create panel ID and time ID (using non-tempvar variables)
    qui egen int __trop_panel_id_26 = group(`panelvar') if `touse'
    qui egen int __trop_time_id_26 = group(`timevar') if `touse'
    
    qui sum __trop_panel_id_26 if `touse'
    local N_panel = r(max)
    qui sum __trop_time_id_26 if `touse'
    local T_panel = r(max)
    
    // Mata vectorized computation of min_valid_pairs.
    // Unit distance denominator: sum_u 1{u!=t}(1-W_iu)(1-W_ju).
    // Each ever-treated unit needs >= 2 common control periods with at least
    // one other unit (one held out by LOOCV, leaving >= 1 for distance).
    //
    // Algorithm: O(N^2 * T) via matrix multiplication.
    //   C[i,t] = 1{W_{it}=0 & Y_{it} non-missing}  (N x T control mask)
    //   overlap = C * C'                              (N x N common control periods)
    //   min_valid_pairs = min_{i in ever-treated} max_{j!=i} overlap[i,j]
    
    // Call pre-compiled Mata function
    // (inline Mata blocks cause issues in batch mode)
    mata: st_local("min_valid_pairs", strofreal(_trop_chk_common_ctrl_periods("__trop_panel_id_26", "__trop_time_id_26", "`treatvar'", "`depvar'", "`touse'", strtoreal(st_local("N_panel")), strtoreal(st_local("T_panel")))))
    
    if `min_valid_pairs' < 2 {
        di as error " FAILED"
        di ""
        di as error "{bf:ERROR}: Some ever-treated units have < 2 common control periods with all others"
        di as error "       min_valid_pairs = `min_valid_pairs'"
        di as error "Unit distance formula:"
        di as error "  dist_{-t}^{unit}(j,i) = sqrt[ sum_u I_u(Y_iu-Y_ju)^2 / sum_u I_u ]"
        di as error "  where I_u = 1{u!=t}(1-W_iu)(1-W_ju), requires sum_u I_u >= 1"
        di as error "With LOOCV holding out one period, >= 2 common control periods are needed."
        di as error "Current min_valid_pairs=`min_valid_pairs', distance denominator may be 0."
        
        di as text _newline "Suggested remedies:"
        di as text "  1. Check treatment pattern: Confirm if W matrix is too sparse."
        di as text "  2. Expand pre-treatment: Add T_pr to increase common control periods."
        di as text "  3. Reduce treated units: Drop isolated treated units."
        di as text "  4. Impute missing values: If __trop_valid is too sparse."
        di as text "     Warning: Imputation requires modeling assumptions."
        di as text "  5. If irreparable, TROP may not suit data."
        di as text "     Consider SC (unit weights only) or DID (uniform weights)."
        
        capture drop __trop_is_control_26 __trop_never_treated_26 __trop_is_pre_26 __trop_n_pre_valid_26
        capture drop __trop_is_control_obs_26 __trop_n_control_i_26 __trop_T_start_26
        ereturn scalar data_validated = 0
        error 459
    }
    di as result " passed (min_valid_pairs=" %3.0f `min_valid_pairs' " >= 2)"
    
    // ========== All Checks Passed ==========
    di as text _newline "{hline 60}"
    di as result "{bf:✓ All TROP feasibility checks passed}"
    di as text "{hline 60}"
    di as text "Validation Results:"
    di as text "  - Var(Y) = " %9.3f `var_Y' " > 0 passed"
    di as text "  - N_treated_units = " %3.0f `N_treated_units' " >= 1 passed"
    di as text "  - N_control = " %6.0f `N_control' " >= 1 passed"
    di as text "  - N_control_units = " %3.0f `N_control_units' " >= 2 passed"
    di as text "  - min_pre_treated = " %3.0f `min_pre_treated' " >= 1 passed"
    di as text "  - Ever-treated unit control periods checked passed"
    di as text "  - min_valid_pairs = " %3.0f `min_valid_pairs' " >= 2 passed"
    di as text "{hline 60}" _newline
    
    // ========== Store Diagnostics in e() ==========
    // Store critical validation metrics
    qui count if `treatvar' == 1 & __trop_valid == 1 & `touse'
    local N_treat = r(N)
    ereturn scalar N_treat = `N_treat'
    ereturn scalar N_control = `N_control'
    ereturn scalar N_control_units = `N_control_units'
    ereturn scalar min_pre_treated = `min_pre_treated'
    ereturn scalar min_valid_pairs = `min_valid_pairs'
    
    // ========== Final data_validated decision ==========
    // Set to 1 only if all strict constraints pass AND missing rate <= 0.3
    if `miss_rate' <= 0.3 {
        ereturn scalar data_validated = 1
    }
    else {
        ereturn scalar data_validated = 0
    }
    
    // ========== Cleanup ==========
    capture drop __trop_is_control_26 __trop_never_treated_26 __trop_T_start_26
    capture drop __trop_is_pre_26 __trop_n_pre_valid_26 __trop_is_control_obs_26 __trop_n_control_i_26
    capture drop __trop_ever_treated_check __trop_panel_id_26 __trop_time_id_26
    
    // ========================================================================
    // Data Quality Comprehensive Report
    // ========================================================================
    di as text _newline _newline
    di as text "{hline 70}"
    di as text "{bf:                    Data Quality Diagnostic Report}"
    di as text "{hline 70}"
    
    // Panel Dimensions
    di as text ""
    di as text "{bf:1. Panel Dimensions}"
    di as text "  Units (N)             = " %8.0f `N'
    di as text "  Periods (T)           = " %8.0f `T'
    di as text "  Actual obs (N_obs)    = " %8.0f `N_obs'
    di as text "  Theoretical obs (NxT) = " %8.0f `N'*`T'
    
    // Balance Diagnostics
    di as text ""
    di as text "{bf:2. Balance Diagnostics}"
    di as text "  Overall missing rate  = " %6.2f `miss_rate'*100 "%"
    if `balanced' == 1 {
        di as text "  Panel type            = {bf:Balanced}"
    }
    else if `miss_rate' <= 0.1 {
        di as text "  Panel type            = Mildly unbalanced"
        di as text "                          (Minimal impact on algorithm)"
    }
    else if `miss_rate' <= 0.3 {
        di as text "  Panel type            = Moderately unbalanced"
        di as text "                          (Monitor estimation precision)"
    }
    else {
        di as text "  Panel type            = {bf:Severely unbalanced}"
        di as text "                          {bf:WARNING: > 30% threshold}"
    }
    
    // Treatment Patterns
    di as text ""
    di as text "{bf:3. Treatment Patterns}"
    local pattern_display = ""
    if "`e(treatment_pattern)'" == "single_treated_unit" {
        local pattern_display = "Single Treated Unit"
    }
    else if "`e(treatment_pattern)'" == "multiple_treated_simultaneous" {
        local pattern_display = "Multiple, Simultaneous Adoption"
    }
    else if "`e(treatment_pattern)'" == "staggered_adoption" {
        local pattern_display = "Staggered Adoption"
    }
    else if "`e(treatment_pattern)'" == "switching_treatment" {
        local pattern_display = "Switching Treatment (WARNING)"
    }
    di as text "  Identified pattern    = {bf:`pattern_display'}"
    di as text "  Ever-treated units    = " %8.0f e(N_treated_units)
    di as text "  Treatment periods     = " %8.0f e(T_treat_periods)
    if e(has_switching) == 1 {
        di as text "  Treatment switching   = {bf:Yes} (max_switches=" %3.0f e(max_switches) ")"
        di as text "                          {bf:WARNING: Violates 'no dynamic effects' assumption}"
    }
    else {
        di as text "  Treatment switching   = No"
    }
    
    // Outlier Diagnostics
    di as text ""
    di as text "{bf:4. Outlier Diagnostics}"
    di as text "  Method                = Tukey's rule (k=10 conservative)"
    di as text "  IQR                   = " %12.4f `IQR'
    di as text "  Outlier bounds        = [" %10.2f `lower' ", " %10.2f `upper' "]"
    di as text "  Outliers detected     = " %8.0f `n_outliers'
    di as text "  Outlier percentage    = " %6.3f `outlier_rate'*100 "%"
    if `n_outliers' > 0 {
        di as text "                          {bf:WARNING: Check or handle outliers}"
    }
    
    // Summary
    di as text ""
    di as text "{hline 70}"
    if `miss_rate' <= 0.3 & `n_outliers' / `N_obs' < 0.05 {
        di as result "{bf:PASS: Data passed all strict constraints}"
        di as text "  Safe to proceed to estimation."
    }
    else {
        di as text "WARNING {bf:Data quality attention needed:}"
        if `miss_rate' > 0.3 {
            di as text "  - Missing rate > 30% threshold, consider data cleaning."
        }
        if `n_outliers' / `N_obs' >= 0.05 {
            di as text "  - Outliers > 5%, recommend inspection."
        }
        di as text "  TROP can run, but estimation quality may be affected."
    }
    di as text "{hline 70}" _newline
    
    // ========================================================================
    // Data Validation Integrity Report
    // ========================================================================
    
    // ========== Prerequisites Check ==========
    if e(data_validated) != 1 {
        di as text _newline "NOTE: Data validation failed (e(data_validated)=`=e(data_validated)'), skipping summary report."
        di as text "      Summary report requires all strict constraints to pass."
        exit 0
    }
    
    // ========== Function 1: Data quality report ==========
    di as text _newline _newline
    di as text "{hline 80}"
    di as text "{bf:TROP Data Validation Integrity Report}"
    di as text "{hline 80}"
    
    // Part 1: Panel Dimensions
    di as text _newline "{bf:[1. Panel Dimensions]}"
    di as text "  Units (N)             = " %8.0f e(N)
    di as text "  Periods (T)           = " %8.0f e(T)
    di as text "  Theoretical obs (NxT) = " %8.0f e(N)*e(T)
    di as text "  Actual obs (N_obs)    = " %8.0f e(N_obs)
    local miss_pct = e(miss_rate) * 100
    if e(miss_rate) < 0.1 {
        di as text "  Missing rate          = " %6.2f `miss_pct' "% (Good)"
    }
    else if e(miss_rate) < 0.3 {
        di as text "  Missing rate          = " %6.2f `miss_pct' "% (Moderately unbalanced)"
    }
    else {
        di as text "  Missing rate          = " %6.2f `miss_pct' "% (Severely unbalanced)"
    }
    if e(balanced) == 1 {
        di as text "  Balanced              = Yes"
    }
    else {
        di as text "  Balanced              = No"
    }
    
    // Part 2: Treatment Patterns
    di as text _newline "{bf:[2. Treatment Patterns]}"
    di as text "  Pattern               = {bf:`e(treatment_pattern)'}"
    di as text "  Ever-treated units    = " %8.0f e(N_treated_units)
    di as text "  Treatment periods     = " %8.0f e(T_treat_periods)
    if e(N_control_units) >= 10 {
        di as text "  Control units         = " %8.0f e(N_control_units) " (Sufficient)"
    }
    else if e(N_control_units) >= 2 {
        di as text "  Control units         = " %8.0f e(N_control_units) " (Low)"
    }
    else {
        di as text "  Control units         = " %8.0f e(N_control_units) " (Insufficient)"
    }
    
    capture confirm existence e(has_switching)
    if _rc == 0 {
        if e(has_switching) == 1 {
            di as text "  Switching detected    = {bf:Yes} (max_switches=" %3.0f e(max_switches) ", WARNING: Violates 'no dynamic effects' assumption)"
        }
        else {
            di as text "  Switching detected    = No"
        }
    }
    
    di as text _newline "{bf:[3. TROP Algorithm Feasibility]}"
    if e(N_control_units) >= 100 {
        di as text "  Control units         = " %8.0f e(N_control_units) " (Sufficient)"
    }
    else if e(N_control_units) >= 2 {
        di as text "  Control units         = " %8.0f e(N_control_units) " (Low)"
    }
    else {
        di as text "  Control units         = " %8.0f e(N_control_units) " (Insufficient)"
    }
    
    if e(min_pre_treated) >= 10 {
        di as text "  Min pre-treat period  = " %8.0f e(min_pre_treated) " (Sufficient)"
    }
    else if e(min_pre_treated) >= 5 {
        di as text "  Min pre-treat period  = " %8.0f e(min_pre_treated) " (Moderate)"
    }
    else {
        di as text "  Min pre-treat period  = " %8.0f e(min_pre_treated) " (Short)"
    }
    
    if e(min_valid_pairs) >= 10 {
        di as text "  Min paired units      = " %8.0f e(min_valid_pairs) " (Sufficient)"
    }
    else if e(min_valid_pairs) >= 5 {
        di as text "  Min paired units      = " %8.0f e(min_valid_pairs) " (Moderate)"
    }
    else {
        di as text "  Min paired units      = " %8.0f e(min_valid_pairs) " (Low)"
    }
    
    // Part 4: Outlier Diagnostics
    qui count if __trop_outlier_flag == 1 & `touse'
    local n_outliers_27 = r(N)
    di as text _newline "{bf:[4. Outliers]}"
    di as text "  Method                = Tukey 10xIQR rule"
    if `n_outliers_27' > 0 {
        local outlier_pct_27 = `n_outliers_27' / e(N_obs) * 100
        if `outlier_pct_27' < 1 {
            di as text "  Count                 = " %8.0f `n_outliers_27' " (" %6.2f `outlier_pct_27' "%) (Normal)"
        }
        else if `outlier_pct_27' < 5 {
            di as text "  Count                 = " %8.0f `n_outliers_27' " (" %6.2f `outlier_pct_27' "%) (Moderate)"
        }
        else {
            di as text "  Count                 = " %8.0f `n_outliers_27' " (" %6.2f `outlier_pct_27' "%) (High)"
        }
        di as text "  Recommendation        = Outliers marked (__trop_outlier_flag=1). User to decide on removal/winsorizing."
    }
    else {
        di as text "  Count                 = 0 (None detected)"
    }
    
    // ========== Temporary variable cleanup ==========
    // Drop internal variables that are no longer needed
    local drop_vars "__trop_n_valid_i __trop_n_valid_t __trop_dup_count __trop_time_diff _has_nonmono"
    local drop_vars "`drop_vars' _is_control _never_treated _is_pre _n_pre__trop_valid"
    local drop_vars "`drop_vars' _is_control_obs _n_control_i __trop_any_treated_t _first_treat_idx __trop_W_diff __trop_is_pretreat"
    
    foreach v of local drop_vars {
        capture drop `v'
    }
    
    // ========== ereturn field verification ==========
    di as text _newline "{bf:[5. ereturn Checks]}"
    
    // Verify required fields (6 fields)
    local required_fields "data_validated N T N_obs treatment_pattern miss_rate"
    local n_required = 0
    local n_required_total: word count `required_fields'
    local missing_required ""
    
    foreach field of local required_fields {
        capture confirm existence e(`field')
        if _rc == 0 {
            local n_required = `n_required' + 1
        }
        else {
            local missing_required "`missing_required' e(`field')"
        }
    }
    
    // Verify diagnostic fields (7 fields)
    local diagnostic_fields "N_control N_control_units min_pre_treated min_valid_pairs balanced"
    local n_diagnostic = 0
    local n_diagnostic_total: word count `diagnostic_fields'
    
    foreach field of local diagnostic_fields {
        capture confirm existence e(`field')
        if _rc == 0 {
            local n_diagnostic = `n_diagnostic' + 1
        }
    }
    
    if `n_required' == `n_required_total' {
        di as text "  Required fields (6)   = " %1.0f `n_required' "/" %1.0f `n_required_total' " (All present)"
    }
    else {
        di as text "  Required fields (6)   = " %1.0f `n_required' "/" %1.0f `n_required_total' " (Missing: `missing_required')"
    }
    
    if `n_diagnostic' >= 5 {
        di as text "  Diagnostic fields (7) = " %1.0f `n_diagnostic' "/" %1.0f `n_diagnostic_total' " (Core fields present)"
    }
    else {
        di as text "  Diagnostic fields (7) = " %1.0f `n_diagnostic' "/" %1.0f `n_diagnostic_total' " (Partial missing)"
    }
    
    // If required fields missing, report error
    if `n_required' < `n_required_total' {
        di as error _newline "ERROR: Incomplete e() fields. Validation not fully executed."
        di as error "Missing fields: `missing_required'"
        di as error "Check implementation of validation steps."
        ereturn scalar validation_complete = 0
        error 459
    }
    
    // ========== Function 5: StataMCP verification (optional) ==========
    // Runs when StataMCP is enabled
    if "`statemcp'" != "" | "`mcp'" != "" {
        di as text _newline "{bf:[StataMCP Verification]}"
        di as text "  Check 1: e() field relationships"
        
        // Check 1.1: N_obs <= N * T
        if e(N_obs) > e(N) * e(T) {
            di as text "    - N_obs > N*T (Data anomaly)"
        }
        else {
            di as text "    - N_obs <= N*T (OK)"
        }
        
        // Check 1.2: miss_rate consistency
        local miss_calc = 1 - e(N_obs)/(e(N)*e(T))
        if abs(e(miss_rate) - `miss_calc') < 1e-10 {
            di as text "    - miss_rate definition consistent"
        }
        else {
            di as text "    - miss_rate inconsistent (e=" %9.6f e(miss_rate) ", calc=" %9.6f `miss_calc' ")"
        }
        
        di as text "  Check 2: Temporary variable quality"
        
        // Check 2.1: __trop_valid completeness
        qui count if missing(__trop_valid) & `touse'
        if r(N) == 0 {
            di as text "    - __trop_valid has no missing values"
        }
        else {
            di as text "    - __trop_valid has " %6.0f r(N) " missing values"
        }
        
        // Check 2.2: __trop_tindex range
        qui sum __trop_tindex if `touse', meanonly
        if r(min) >= 1 & r(max) <= e(T) {
            di as text "    - __trop_tindex range valid [1, " %3.0f e(T) "]"
        }
        else {
            di as text "    - __trop_tindex range invalid [" %6.1f r(min) ", " %6.1f r(max) "]"
        }
        
        // Check 2.3: __trop_ever_treated consistency
        capture confirm variable __trop_ever_treated
        if _rc == 0 {
            qui count if __trop_ever_treated == 1 & `touse'
            tempvar unit_tag_27
            qui egen `unit_tag_27' = tag(`panelvar') if __trop_ever_treated == 1 & `touse'
            qui count if `unit_tag_27' == 1
            local n__trop_ever_treated_units = r(N)
            if `n__trop_ever_treated_units' == e(N_treated_units) {
                di as text "    - __trop_ever_treated matches e(N_treated_units)"
            }
            else {
                di as text "    - __trop_ever_treated count(" %3.0f `n__trop_ever_treated_units' ") != e(N_treated_units)(" %3.0f e(N_treated_units) ")"
            }
        }
    }
    
    // ========== Validation status summary ==========
    di as text _newline "{bf:[6. Validation Status]}"
    
    if e(data_validated) == 1 & `n_required' == `n_required_total' {
        di as text "  Validation            = {bf:Passed}"
        di as text "  Next Step             = {bf:Ready for Estimation}"
        di as text "  Temp Variables        = {bf:Cleaned}"
        di as text "  ereturn Fields        = {bf:Complete}"
        
        // Set completion flag
        ereturn scalar validation_complete = 1
        
        di as text _newline "{bf:PASS: Data validation completed successfully.}"
        di as text "Ready for fixed effects estimation."
    }
    else {
        di as text "  Validation            = {bf:Failed}"
        di as text "  Next Step             = {bf:Cannot Proceed}"
        di as text "  Recommendation        = Review diagnostics above and re-run validation."
        
        ereturn scalar validation_complete = 0
    }
    
    di as text "{hline 80}"
    di as text "Detailed diagnostics saved in e(). Type {bf:ereturn list} to view."
    di as text "{hline 80}" _newline
    
    // Note: e(data_validated) is set by feasibility checks (strict constraints + missing rate <= 30%)
    // This module is the final gate for data validation status.
    
end

// ----------------------------------------------------------------------------
// Internal routine: balance diagnostics and missingness analysis.
// ----------------------------------------------------------------------------

/*
    trop_balance_check --- Panel balance and missingness diagnostics.

    Checks:
    - Panel dimensions (N units, T periods).
    - Overall missingness rate with tiered diagnostics (note/warning/error).
    - Full-row missingness: units with no valid observations.
    - Full-column missingness: periods with no valid observations.

    Hard threshold: missingness > 30% triggers an error because fixed-effect
    variance inflates, SVD condition numbers degrade, and LOOCV validation
    variance increases.

    Outputs stored in e():
      e(N), e(T), e(N_obs), e(miss_rate), e(balanced).
    Creates persistent variable __trop_valid (byte).
*/


program define trop_balance_check, eclass
    version 17.0
    syntax varlist(min=2 max=2 numeric) [if] [in], ///
        PANelvar(varname) ///
        TIMevar(varname numeric) ///
        [NOBALance]  // skip balance check
    
    // Cleanup potential leftover __trop_valid variable
    capture drop __trop_valid
    
    // Parse variable list
    tokenize `varlist'
    local depvar `1'
    local treatvar `2'
    
    // Mark sample
    marksample touse, novarlist
    
    // Display start info
    di as text _newline "{bf:Data Validation Module - Balance Diagnostics}"
    di as text "{hline 70}"
    di as text "Theoretical Basis:"
    di as text "  - Identification: FE identification requires non-missing observations."
    di as text "  - Constraint: 30% missing rate hard threshold."
    di as text "{hline 70}" _newline
    
    if "`nobalance'" != "" {
        di as text "Balance diagnostics skipped." _newline
        exit
    }
    
    // ========================================================================
    // Step 1: Compute Panel Dimensions
    // ========================================================================
    di as text "Step 1: Computing panel dimensions..." _continue
    
    // Calculate number of units N
    qui tab `panelvar' if `touse'
    local N = r(r)
    
    // Calculate number of periods T
    qui tab `timevar' if `touse'
    local T = r(r)
    
    // Theoretical observations
    local N_theory = `N' * `T'
    
    di as result " Done"
    di as text "  Theoretical panel size: N={bf:`N'} x T={bf:`T'} = {bf:`N_theory'} obs"
    
    // ========================================================================
    // Step 2: Calculate Missingness Rate
    // ========================================================================
    di as text "Step 2: Calculating missing rate..." _continue
    
    // Create missing marker variable
    qui gen byte __trop_valid = !missing(`depvar', `treatvar') if `touse'
    label variable __trop_valid "Non-missing indicator (Y and W both observed)"
    
    // Count actual non-missing observations
    qui count if __trop_valid == 1 & `touse'
    local N_obs = r(N)
    
    // Calculate overall missing rate
    local miss_overall = 1 - `N_obs' / `N_theory'
    
    di as result " Done"
    di as text "  Actual observations: {bf:`N_obs'}"
    di as text "  Overall missing rate: " %4.2f `miss_overall'*100 "%"
    
    // ========================================================================
    // Step 3: Graded Warning System (3-Tier)
    // ========================================================================
    di as text "Step 3: Diagnostic classification..." _continue
    
    if `miss_overall' > 0.3 {
        // HARD ERROR: Severely Unbalanced (>30%)
        di as error " Failed!"
        di ""
        
        di as error "{bf:ERROR: Severely Unbalanced}"
        di as error "Missing rate: " %4.1f `miss_overall'*100 "% > 30% (Hard Threshold)"
        di as error "Theoretical obs: `N_theory' (N=`N', T=`T')"
        di as error "Actual obs: `N_obs'"
        
        di as text _newline "{bf:Theoretical Basis} (Variance Inflation & Instability):"
        di as text "  (A) FE Variance Inflation +43%"
        di as text "      Var(alpha_i) falls as sum(w_is) decreases."
        di as text "      Variance ratio: Var_30%/Var_0% approx 1.43"
        di as text ""
        di as text "  (B) SVD Condition Number x2 (Numerical Instability)"
        di as text "      kappa(Y_missing) increases, leading to unstable rank selection."
        di as text ""
        di as text "  (C) CV Loss Variance +43%"
        di as text "      Reduced effective neighborhood for LOOCV."
        
        // Compute helper variable for repair suggestions
        capture drop __trop_n_valid_i
        qui bysort `panelvar': egen __trop_n_valid_i = total(__trop_valid) if `touse'
        local cutoff_i = int(0.7 * `T')
        
        di as text _newline "{bf:Repair Suggestions} (Prioritized):"
        di as text "  1. {bf:[Recommended]} Drop high-missingness units:"
        di as text "     {stata drop if __trop_n_valid_i < `cutoff_i'}"
        di as text "     where __trop_n_valid_i is valid obs per unit."
        di as text "     Expected: Keep high-quality units with >= 70% obs."
        di as text ""
        di as text "  2. Drop high-missingness periods:"
        qui bysort `timevar': egen __trop_n_valid_t = total(__trop_valid) if `touse'
        local cutoff_t = int(0.7 * `N')
        di as text "     {stata drop if __trop_n_valid_t < `cutoff_t'}"
        di as text "     Expected: Keep high-quality periods with >= 70% obs."
        qui drop __trop_n_valid_t
        di as text ""
        di as text "  3. Impute missing values (User responsibility):"
        di as text "     e.g., Mean imputation, forward fill."
        di as text "     {bf:WARNING:} May violate factor model assumptions."
        di as text ""
        di as text "  4. Re-evaluate data source suitability."
        
        // Set failure flags
        ereturn scalar data_validated = 0
        ereturn scalar miss_rate = `miss_overall'
        ereturn scalar N = `N'
        ereturn scalar T = `T'
        ereturn scalar N_obs = `N_obs'
        ereturn scalar balanced = 0
        
        error 459  // Severely unbalanced panel
    }
    else if `miss_overall' > 0.1 {
        // WARNING: Moderately Unbalanced (10%-30%)
        di as result " Moderately Unbalanced"
        di ""
        di as text "{bf:WARNING: Moderately Unbalanced}"
        di as text "Missing rate: " %4.1f `miss_overall'*100 "% (10%-30% range)"
        di as text "Theoretical obs: `N_theory', Actual obs: `N_obs'"
        di as text "{bf:Suggestion:} Check missingness patterns to ensure FE estimation is not compromised."
        di as text "        Weights calculation will automatically exclude missing observations." _newline
    }
    else if `miss_overall' > 0 {
        // NOTE: Mildly Unbalanced (0%-10%)
        di as result " Mildly Unbalanced"
        di as text "NOTE: Mildly Unbalanced (Missing rate=" %4.2f `miss_overall'*100 "%)" _newline
    }
    else {
        // Fully Balanced
        di as result " Fully Balanced"
        di as text "NOTE: Fully balanced panel (miss_rate=0)" _newline
    }
    
    // ========================================================================
    // Step 4: Check Full Row Missing (Unit Dimension Hard Constraint)
    // ========================================================================
    di as text "Step 4: Checking for full row missingness (Unit dimension)..." _continue
    
    tempvar n_valid_i
    qui bysort `panelvar': egen `n_valid_i' = total(__trop_valid) if `touse'
    
    // Check if any unit is missing in all periods
    qui count if `n_valid_i' == 0 & `touse'
    local n_allmiss_units = r(N)
    
    if `n_allmiss_units' > 0 {
        di as error " Failed!"
        di ""
        
        // Get violating unit IDs (deduplicate)
        tempvar unit_marked
        qui gen byte `unit_marked' = (`n_valid_i' == 0 & `touse')
        qui bysort `panelvar': egen byte _allmiss_unit = max(`unit_marked')
        
        di as error "{bf:ERROR: Units missing in all periods detected}"
        di as error "Count: {bf:`n_allmiss_units'} units"
        di as error "Unit fixed effect alpha_i requires at least one observed period."
        di as error "If unit i is missing in all periods, alpha_i is undefined."
        
        di as text _newline "{bf:Violating Units} (First 10):"
        list `panelvar' if _allmiss_unit == 1 in 1/10, ///
            noobs table separator(0) abbrev(12)
        
        di as text _newline "{bf:Repair Suggestion}:"
        di as text "  1. Drop these units:"
        di as text "     {stata drop if _allmiss_unit == 1}"
        di as text "     Reason: These units contribute nothing to estimation."
        
        // Set failure flag
        ereturn scalar data_validated = 0
        drop _allmiss_unit
        error 459
    }
    
    di as result " Passed (No full row missingness)"
    
    // ========================================================================
    // Step 5: Check Full Column Missing (Time Dimension Hard Constraint)
    // ========================================================================
    di as text "Step 5: Checking for full column missingness (Time dimension)..." _continue
    
    tempvar n_valid_t
    qui bysort `timevar': egen `n_valid_t' = total(__trop_valid) if `touse'
    
    // Check if any period is missing in all units
    qui count if `n_valid_t' == 0 & `touse'
    local n_allmiss_periods = r(N)
    
    if `n_allmiss_periods' > 0 {
        di as error " Failed!"
        di ""
        
        // Get violating period IDs (deduplicate)
        tempvar period_marked
        qui gen byte `period_marked' = (`n_valid_t' == 0 & `touse')
        qui bysort `timevar': egen byte _allmiss_period = max(`period_marked')
        
        di as error "{bf:ERROR: Periods missing in all units detected}"
        di as error "Count: {bf:`n_allmiss_periods'} periods"
        di as error "Time fixed effect beta_t requires at least one observed unit."
        di as error "If period t is missing in all units, beta_t is undefined."
        
        di as text _newline "{bf:Violating Periods} (First 10):"
        list `timevar' if _allmiss_period == 1 in 1/10, ///
            noobs table separator(0) abbrev(12)
        
        di as text _newline "{bf:Repair Suggestion}:"
        di as text "  1. Drop these periods:"
        di as text "     {stata drop if _allmiss_period == 1}"
        di as text "     Reason: These periods contribute nothing to estimation."
        
        // Set failure flag
        ereturn scalar data_validated = 0
        drop _allmiss_period
        error 459
    }
    
    di as result " Passed (No full column missingness)"
    
    // ========================================================================
    // Step 6: Store Diagnostic Metrics in e()
    // ========================================================================
    di as text "Step 6: Storing diagnostic metrics..." _continue
    
    ereturn scalar N = `N'
    ereturn scalar T = `T'
    ereturn scalar N_obs = `N_obs'
    ereturn scalar miss_rate = `miss_overall'
    ereturn scalar balanced = (`miss_overall' < 1e-10)
    
    // Note: data_validated is NOT set to 1 here. Validation requires subsequent checks.
    
    di as result " Done"
    di as text "  Stored: e(N), e(T), e(N_obs), e(miss_rate), e(balanced)"
    
    // ========================================================================
    // Step 7: Cleanup (__trop_valid retained for subsequent use)
    // ========================================================================
    // Clean internal variables
    capture drop __trop_n_valid_i
    capture drop __trop_n_valid_t
    // __trop_valid is retained for use by subsequent validation and estimation steps.
    
    // Display summary
    di as text _newline "{hline 70}"
    di as result "{bf:✓ Balance Diagnostics Passed}"
    di as text "  - Missing rate: " %4.2f `miss_overall'*100 "%"
    if e(balanced) == 1 {
        di as text "  - Balance: {bf:Fully Balanced}"
    }
    else if `miss_overall' <= 0.1 {
        di as text "  - Balance: Mildly Unbalanced (Minimal impact)"
    }
    else {
        di as text "  - Balance: Moderately Unbalanced (Monitor precision)"
    }
    di as text "  - Full row missing check: Passed (Every unit has at least 1 obs)"
    di as text "  - Full col missing check: Passed (Every period has at least 1 obs)"
    di as text "  - __trop_valid variable: Created (For use in subsequent validation)"
    di as text "{hline 70}" _newline
    
end

// _trop_chk_common_ctrl_periods() is defined in trop_validation.mata,
// pre-compiled via load_mata_once.do / compile_all.do.
// Inline Mata definitions at ado-file tail may fail during adopath auto-loading.

