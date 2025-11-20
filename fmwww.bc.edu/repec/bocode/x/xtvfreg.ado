*! a Stata program for estimating variance function panel regression
* xtvfreg version 0.4.8
* Tim Liao, University of Illinois
* Variance decomposition + combined tables working

program define xtvfreg, eclass
    version 18.0

    // -------------------------------
    // Parse syntax
    // -------------------------------
    syntax varlist(min=1 max=1) [if] [in] [pweight], ///
        GROUPVAR(varname) PANELID(varname) ///
        MEANVARS(varlist) VARVARS(varlist) ///
        [TVAR(varname) CONVERGE(real 1e-6) MAXITER(integer 100) TABLE NOLOg COMbined]
    
    // Check if output should be displayed
    local show_output = c(noisily)
    
    // Handle weights
    if "`weight'" != "" {
        local wgt "[`weight' `exp']"
        local pwgt = subinstr("`exp'", "=", "", 1)
    }
    else {
        local wgt ""
        local pwgt ""
    }

    // -------------------------------
    // Mark sample - but DON'T use preserve/restore
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
    quietly xtset `fevar'

    levelsof `groupvar' if `touse', local(groups)
    local ngroups : word count `groups'
    local i = 0
    
    // Build list of clean group names
    local mean_est_list ""
    local var_est_list ""
    local beta_est_list ""

    // Display header
    if `show_output' {
        di as text _n "Varying Fixed Effects Panel Regression (Version 0.4.7)"
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
        local obscond "`groupvar'==`g' & `touse'"

        // Unique suffix for this group
        local gname = subinstr("`g'", " ", "", .)
        local gname = subinstr("`gname'", ".", "_", .)
        local gname = subinstr("`gname'", "-", "_", .)
        local R2_var "R2_`gname'"
        local S2_var "S2_`gname'"
        
        // Add to estimation lists
        local mean_est_list "`mean_est_list' mean_`gname'"
        local var_est_list "`var_est_list' var_`gname'"
        local beta_est_list "`beta_est_list' beta_`gname'"

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
            quietly glm `R2_var' `var_eq_vars' if `obscond', family(gamma) link(log)
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

        // Store final log-likelihood
        quietly summarize LL0_temp if `obscond', meanonly
        local ll_final = r(mean)

        // Display convergence status
        if `show_output' {
            if `converged' {
                di as text _n "Converged in " as result `iter' as text " iterations"
            }
            else {
                di as text _n as error "Warning: " as text "Maximum iterations (`maxiter') reached without convergence"
            }
        }

        // -------------------------------
        // Final estimation and storage
        // -------------------------------
        
        // Variance equation
        if `show_output' {
            di as text _n "Variance Equation (Gamma GLM):"
            di as text "{hline 78}"
            glm `R2_var' `var_eq_vars' if `obscond' `wgt', family(gamma) link(log)
        }
        else {
            quietly glm `R2_var' `var_eq_vars' if `obscond' `wgt', family(gamma) link(log)
        }
        estimates store var_`gname'
        
        // Mean equation
        if `show_output' {
            di as text _n "Mean Equation (Weighted GLS):"
            di as text "{hline 78}"
        }
        
        if "`pwgt'" != "" {
            tempvar combined_wgt
            quietly gen double `combined_wgt' = (`pwgt') / `S2_var' if `obscond'
            if `show_output' {
                glm `yvar' `mean_eq_vars' [aw=`combined_wgt'] if `obscond', family(gaussian) link(identity)
            }
            else {
                quietly glm `yvar' `mean_eq_vars' [aw=`combined_wgt'] if `obscond', family(gaussian) link(identity)
            }
        }
        else {
            if `show_output' {
                glm `yvar' `mean_eq_vars' [aw=1/`S2_var'] if `obscond', family(gaussian) link(identity)
            }
            else {
                quietly glm `yvar' `mean_eq_vars' [aw=1/`S2_var'] if `obscond', family(gaussian) link(identity)
            }
        }
        
        // Add metadata to mean equation estimates
        quietly estadd scalar group = `g'
        quietly estadd scalar n_iter = `iter'
        quietly estadd scalar vf_converged = `converged'
        quietly estadd scalar ll_init = `ll_init'
        quietly estadd scalar ll_final = `ll_final'
        quietly estadd local vf_groupvar "`groupvar'"
        quietly estadd local vf_groupval "`g'"
        quietly estadd local vf_cmd "xtvfreg"
        
        estimates store mean_`gname'
        
        // Store again as beta for combined tables with variance decomposition
        estimates store beta_`gname'
        
        // -------------------------------
        // Calculate and display variance decomposition
        // -------------------------------
        
        // Total variance of outcome
        quietly summarize `yvar' if `obscond', detail
        local var_total = r(Var)
        
        // Variance of fitted values from mean model
        capture drop fitted_temp
        quietly predict double fitted_temp if `obscond'
        quietly summarize fitted_temp if `obscond', detail
        local var_fitted = r(Var)
        capture drop fitted_temp
        
        // Mean of estimated variance function
        quietly summarize `S2_var' if `obscond', meanonly
        local var_heterosced = r(mean)
        
        // Proportions
        local prop_mean = `var_fitted' / `var_total'
        local prop_var = `var_heterosced' / `var_total'
        local prop_unexplained = 1 - `prop_mean' - `prop_var'
        
        // Display variance decomposition
        if `show_output' {
            di as text _n "Variance Decomposition:"
            di as text "{hline 78}"
            di as text "Total variance of " as result "`yvar'" as text ": " as result %9.6f `var_total'
            di as text "  Variance explained by mean model: " as result %9.6f `var_fitted' as text " (" as result %5.1f =`prop_mean'*100 as text "%)"
            di as text "  Variance explained by variance model: " as result %9.6f `var_heterosced' as text " (" as result %5.1f =`prop_var'*100 as text "%)"
            di as text "  Unexplained variance: " as result %9.6f =`var_total'-`var_fitted'-`var_heterosced' as text " (" as result %5.1f =`prop_unexplained'*100 as text "%)"
        }
        
        // Add variance decomposition to stored estimates
        estimates restore beta_`gname'
        estadd scalar var_total = `var_total'
        estadd scalar var_fitted = `var_fitted'
        estadd scalar var_heterosced = `var_heterosced'
        estadd scalar prop_mean = `prop_mean'
        estadd scalar prop_var = `prop_var'
        estimates store beta_`gname'
        
        // Return values for this group
        ereturn scalar group`i'_iter = `iter'
        ereturn scalar group`i'_converged = `converged'
        ereturn scalar group`i'_ll = `ll_final'
        ereturn scalar group`i'_var_total = `var_total'
        ereturn scalar group`i'_prop_mean = `prop_mean'
        ereturn scalar group`i'_prop_var = `prop_var'

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
            esttab `beta_est_list', p star(* 0.10 ** 0.05 *** 0.01) ///
                wide scalars(n_iter vf_converged ll_final var_total prop_mean prop_var) ///
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
            esttab `mean_est_list', se star(* 0.10 ** 0.05 *** 0.01) ///
                b(%9.4f) se(%9.4f) ///
                mtitles
            
            di as text _n _n "Variance Equation Results (All Groups):"
            di as text "{hline 78}"
            esttab `var_est_list', se star(* 0.10 ** 0.05 *** 0.01) ///
                b(%9.4f) se(%9.4f) ///
                mtitles
        }
        else {
            di as error "Note: esttab not installed. Install with: ssc install estout"
        }
    }
    
    ereturn local groups "`groups'"
    ereturn scalar ngroups = `ngroups'
    ereturn scalar maxiter = `maxiter'
    ereturn scalar converge = `tol'
	// Clean up temporary variables
   capture drop R2_* S2_*
end