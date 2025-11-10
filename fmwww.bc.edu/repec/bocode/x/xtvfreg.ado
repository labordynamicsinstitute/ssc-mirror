*! a Stata program for estimating variance function panel regression
* version 0.4.5, Tim Liao, University of Illinois

program define xtvfreg, rclass
    version 18.0

    // -------------------------------
    // Parse syntax
    // -------------------------------
    syntax varname(min=1 max=1) [if] [in] [pweight], ///
        GROUPVAR(varname) PANELID(varname) ///
        MEANVARS(varlist) VARVARS(varlist) ///
        [TVAR(varname) CONVERGE(real 1e-6) MAXITER(integer 100) TABLE NOLOg COMbined]
    
    // Check if output should be displayed (1 = show output, 0 = suppress)
    local show_output = c(noisily)
    
    // Handle weights
    if "`weight'" != "" {
        local wgt "[`weight' `exp']"
        // Extract variable name from exp (remove the leading "=")
        local pwgt = subinstr("`exp'", "=", "", 1)
    }
    else {
        local wgt ""
        local pwgt ""
    }

    // -------------------------------
    // Mark sample
    // -------------------------------
    marksample touse
    markout `touse' `groupvar' `panelid' `meanvars' `varvars'
    
    // -------------------------------
    // Local vars and checks
    // -------------------------------
    local yvar `varlist'
    capture confirm variable `yvar'
    if _rc { 
        di as error "Dependent variable `yvar' not found"
        exit 198
    }

    local groupvar `groupvar'
    capture confirm variable `groupvar'
    if _rc { 
        di as error "Group variable `groupvar' not found"
        exit 198
    }

    local fevar `panelid'
    capture confirm variable `fevar'
    if _rc { 
        di as error "Panel ID `fevar' not found"
        exit 198
    }

    local mean_eq_vars `meanvars'
    foreach v of local mean_eq_vars {
        capture confirm variable `v'
        if _rc { 
            di as error "Mean variable `v' not found: `v'"
            exit 198
        }
    }

    local var_eq_vars `varvars'
    foreach v of local var_eq_vars {
        capture confirm variable `v'
        if _rc { 
            di as error "Variance variable `v' not found: `v'"
            exit 198
        }
    }

    local tol = `converge'
    local maxiter = `maxiter'
    local do_table = "`table'" != ""
    local do_combined = "`combined'" != ""
    local show_log = ("`nolog'" == "" & `show_output')

    // -------------------------------
    // Setup
    // -------------------------------
    preserve
    quietly keep if `touse'
    quietly xtset `fevar'

    levelsof `groupvar', local(groups)
    local ngroups : word count `groups'
    local i = 0

    // Display header
    if `show_output' {
        di as text _n "Varying Fixed Effects Panel Regression"
        di as text "Dependent variable: " as result "`yvar'"
        di as text "Panel ID: " as result "`fevar'"
        di as text "Group variable: " as result "`groupvar'"
        di as text "Number of groups: " as result `ngroups'
        di as text "Convergence criterion: " as result `tol'
        di as text "Maximum iterations: " as result `maxiter'
        di as text "{hline 78}"
    }

    // -------------------------------
    // Loop over groups
    // -------------------------------
    foreach g of local groups {
        local ++i
        
        if `show_output' {
            di as text _n "Group `g' (`i' of `ngroups')" _n "{hline 78}"
        }
        local obscond "`groupvar'==`g'"

        // Unique suffix for this group
        local gname = subinstr("`g'", " ", "", .)
        local R2_var "R2_`gname'"
        local S2_var "S2_`gname'"

        // Drop any leftovers
        capture drop Ra_temp R_temp `R2_var' `S2_var' LOGLIK_temp LL0_temp LLN_temp DLL_temp

        // Count observations in this group
        quietly count if `obscond'
        local n_obs = r(N)
        if `show_output' {
            di as text "Observations: " as result `n_obs'
        }

        // -------------------------------
        // Initial estimation
        // -------------------------------
        if `show_log' {
            di as text _n "Initial Estimation:"
        }
        
        quietly glm `yvar' `mean_eq_vars' if `obscond' `wgt', family(gaussian) link(identity)
        capture drop Ra_temp R_temp
        quietly predict double Ra_temp if `obscond', r

        quietly xtreg Ra_temp if `obscond' `wgt', fe
        capture drop R_temp
        quietly predict double R_temp if `obscond', u

        quietly gen double `R2_var' = R_temp^2 if `obscond'

        quietly glm `R2_var' `var_eq_vars' if `obscond' `wgt', family(gamma) link(log)
        capture drop `S2_var'
        quietly predict double `S2_var' if `obscond', mu

        quietly gen double LOGLIK_temp = -0.5*(ln(`S2_var') + (`R2_var'/`S2_var')) if `obscond'
        quietly egen double LL0_temp = total(LOGLIK_temp) if `obscond'
        
        quietly summarize LL0_temp if `obscond', meanonly
        local ll_init = r(mean)
        
        if `show_log' {
            di as text "  Initial log-likelihood = " as result %10.4f `ll_init'
        }

        local iter = 0
        local diff = 1
        local converged = 0

        // -------------------------------
        // Iterative weighted GLS
        // -------------------------------
        if `show_log' {
            di as text _n "Iteration History:"
            di as text "{hline 50}"
            di as text "Iter" _col(10) "Log-likelihood" _col(30) "Change" _col(45) "Criterion"
            di as text "{hline 50}"
        }

        while (`diff' > `tol' & `iter' < `maxiter') {
            local ++iter

            // Drop temp variables before re-predicting
            capture drop Ra_temp R_temp LLN_temp DLL_temp

            // Re-estimate mean
            quietly glm `yvar' `mean_eq_vars' [aw=1/`S2_var'] if `obscond', family(gaussian) link(identity)
            capture drop Ra_temp R_temp
            quietly predict double Ra_temp if `obscond', r

            quietly xtreg Ra_temp if `obscond', fe
            capture drop R_temp
            quietly predict double R_temp if `obscond', u

            quietly replace `R2_var' = R_temp^2 if `obscond'

            // Re-estimate variance
            quietly glm `R2_var' `dev_eq_vars' if `obscond', family(gamma) link(log)
            capture drop `S2_var'
            quietly predict double `S2_var' if `obscond', mu

            // Log-likelihood and convergence
            quietly replace LOGLIK_temp = -0.5*(ln(`S2_var') + (`R2_var'/`S2_var')) if `obscond'
            quietly egen double LLN_temp = total(LOGLIK_temp) if `obscond'
            quietly gen double DLL_temp = LLN_temp - LL0_temp if `obscond'
            quietly replace LL0_temp = LLN_temp if `obscond'
            quietly summarize DLL_temp if `obscond', meanonly
            local diff = abs(r(mean))
            
            quietly summarize LLN_temp if `obscond', meanonly
            local ll_current = r(mean)

            if `show_log' {
                di as text %4.0f `iter' _col(10) as result %12.4f `ll_current' _col(30) as result %10.6f `diff' _col(45) as result %10.6f `tol'
            }
            
            if `diff' <= `tol' {
                local converged = 1
            }
        }

        if `show_log' {
            di as text "{hline 50}"
        }

        // Display convergence status
        if `show_output' {
            if `converged' {
                di as text _n "Converged in " as result `iter' as text " iterations"
            }
            else {
                di as text _n as error "Warning: " as text "Maximum iterations (`maxiter') reached without convergence"
            }
        }

        // Store final log-likelihood
        quietly summarize LL0_temp if `obscond', meanonly
        local ll_final = r(mean)

        // -------------------------------
        // Display mean equation results
        // -------------------------------
        if `show_output' {
            di as text _n "Mean Equation (Weighted GLS):"
            di as text "{hline 78}"
            if "`pwgt'" != "" {
                tempvar combined_wgt
                quietly gen double `combined_wgt' = (`pwgt') / `S2_var' if `obscond'
                glm `yvar' `mean_eq_vars' [aw=`combined_wgt'] if `obscond', family(gaussian) link(identity)
            }
            else {
                glm `yvar' `mean_eq_vars' [aw=1/`S2_var'] if `obscond', family(gaussian) link(identity)
            }
        }
        else {
            if "`pwgt'" != "" {
                tempvar combined_wgt
                quietly gen double `combined_wgt' = (`pwgt') / `S2_var' if `obscond'
                quietly glm `yvar' `mean_eq_vars' [aw=`combined_wgt'] if `obscond', family(gaussian) link(identity)
            }
            else {
                quietly glm `yvar' `mean_eq_vars' [aw=1/`S2_var'] if `obscond', family(gaussian) link(identity)
            }
        }
        estimates store mean_`gname'
        
        // -------------------------------
        // Display variance equation results
        // -------------------------------
        if `show_output' {
            di as text _n "Variance Equation (Gamma GLM):"
            di as text "{hline 78}"
            glm `R2_var' `var_eq_vars' if `obscond' `wgt', family(gamma) link(log)
        }
        else {
            quietly glm `R2_var' `var_eq_vars' if `obscond' `wgt', family(gamma) link(log)
        }
        estimates store var_`gname'
        
        // Store combined results with metadata
        if "`pwgt'" != "" {
            tempvar combined_wgt
            quietly gen double `combined_wgt' = (`pwgt') / `S2_var' if `obscond'
            quietly glm `yvar' `mean_eq_vars' [aw=`combined_wgt'] if `obscond', family(gaussian) link(identity)
        }
        else {
            quietly glm `yvar' `mean_eq_vars' [aw=1/`S2_var'] if `obscond', family(gaussian) link(identity)
        }
        estadd scalar group = `g'
        estadd scalar n_iter = `iter'
        estadd scalar vf_converged = `converged'
        estadd scalar ll_init = `ll_init'
        estadd scalar ll_final = `ll_final'
        estadd local vf_groupvar "`groupvar'"
        estadd local vf_groupval "`g'"
        estadd local vf_cmd "xtvfreg"
        quietly estimates store beta_`gname'
        
        // Return values for this group
        return scalar group`i'_iter = `iter'
        return scalar group`i'_converged = `converged'
        return scalar group`i'_ll = `ll_final'

        // Clean up temps
        capture drop Ra_temp R_temp LOGLIK_temp LL0_temp LLN_temp DLL_temp
    }

    // -------------------------------
    // Summary across groups
    // -------------------------------
    if `show_output' {
        di as text _n _n "Summary"
        di as text "{hline 78}"
        di as text "Total groups estimated: " as result `ngroups'
    }
    
    // -------------------------------
    // Optional esttab
    // -------------------------------
    if (`do_table' & `show_output') {
        capture which esttab
        if _rc == 0 {
            di as text _n _n "Combined Estimation Results:"
            di as text "{hline 78}"
            esttab beta_*, p star(* 0.10 ** 0.05 *** 0.01) ///
                wide scalars(n_iter vf_converged ll_final) ///
                mtitles
        }
        else {
            di as error "Note: esttab not installed. Install with: ssc install estout"
        }
    }
    
    // -------------------------------
    // Combined mean and variance tables
    // -------------------------------
    if (`do_combined' & `show_output') {
        capture which esttab
        if _rc == 0 {
            di as text _n _n "Mean Equation Results (All Groups):"
            di as text "{hline 78}"
            esttab mean_*, se star(* 0.10 ** 0.05 *** 0.01) ///
                b(%9.4f) se(%9.4f) ///
                mtitles
            
            di as text _n _n "Variance Equation Results (All Groups):"
            di as text "{hline 78}"
            esttab var_*, se star(* 0.10 ** 0.05 *** 0.01) ///
                b(%9.4f) se(%9.4f) ///
                mtitles
        }
        else {
            di as error "Note: esttab not installed. Install with: ssc install estout"
            di as error "      Combined tables require esttab from: ssc install estout"
        }
    }
    
    // -------------------------------
    // Return and cleanup
    // -------------------------------
    restore
    return local groups "`groups'"
    return scalar ngroups = `ngroups'
    return scalar maxiter = `maxiter'
    return scalar converge = `tol'
end