*! version 1.00.00  24jan2026  Prof. Imadeddin A. Almosabbeh
capture program drop tnardl

program define tnardl
version 14.0
    syntax varlist(min=2), TARGET(varname) [MAXlags(integer 2) CRITerion(string) NOGraph TRIM(real 15)]
    
    // 1. Parsing input variables
    gettoken dep_var control_vars : varlist
    local target_var "`target'"
    
    if "`criterion'" == "" local criterion "aic"
    
    display as result "{hline 80}"
    display as result "  STARTING ADVANCED THRESHOLD NARDL (TNARDL) PROCEDURE"
    display as result "{hline 80}"
    display as txt "Dependent Var:   `dep_var'"
    display as txt "Threshold Var:   `target_var'"
    display as txt "Control Vars:   `control_vars'"
    display as txt "Max Lags:        `maxlags'"
    display as result "{hline 80}"

 // ---------------------------------------------------------
    // 2. Full Grid Search with Custom Trimming
    // ---------------------------------------------------------
    quietly {
        tempvar d_target
        gen `d_target' = d.`target_var'
        
        // Calculate bounds based on trim option
        local lower_p = `trim'
        local upper_p = 100 - `trim'
        
        _pctile `d_target', p(`lower_p' `upper_p')
        local min_search = r(r1)
        local max_search = r(r2)

        // Extract all unique values within specified bounds
        levelsof `d_target' if `d_target' >= `min_search' & `d_target' <= `max_search', local(candidates)
        
        scalar min_rss = 1e+30
        scalar b1 = .
        scalar b2 = .

        foreach s1 of local candidates {
            foreach s2 of local candidates {
                if `s2' > `s1' {
                    tempvar p_t m_t n_t cp cm cn
                    gen `p_t' = `d_target' * (`d_target' > `s2')
                    gen `cp' = sum(`p_t')
                    gen `m_t' = `d_target' * (`d_target' >= `s1' & `d_target' <= `s2')
                    gen `cm' = sum(`m_t')
                    gen `n_t' = `d_target' * (`d_target' < `s1')
                    gen `cn' = sum(`n_t')

                    reg d.`dep_var' L.`dep_var' L.`cp' L.`cm' L.`cn' L.(`control_vars')
                    if e(rss) < min_rss {
                        scalar min_rss = e(rss)
                        scalar b1 = `s1'
                        scalar b2 = `s2'
                    }
                    drop `p_t' `m_t' `n_t' `cp' `cm' `cn'
                }
            }
        }
    }
   
	display as text "Optimal Thresholds Identified: " 
	display as result "{hline 80}"
	display as result "      s1 = " %6.4f b1 
	display as result "      s2 = " %6.4f b2
    display as result "{hline 80}"
    // ---------------------------------------------------------
    // 3. Generate variables and Final Estimation
    // ---------------------------------------------------------
    capture drop `target_var'_POS `target_var'_MED `target_var'_NEG
    quietly {
        gen `target_var'_POS = sum(`d_target' * (`d_target' > b2))
        gen `target_var'_MED = sum(`d_target' * (`d_target' >= b1 & `d_target' <= b2))
        gen `target_var'_NEG = sum(`d_target' * (`d_target' < b1))
    }

    ardl `dep_var' `target_var'_POS `target_var'_MED `target_var'_NEG `control_vars', ///
         maxlags(`maxlags') `criterion' ec1 regstore(final_tnardl)
		 estat ectest

// ---------------------------------------------------------
    // 3.5. Calculate Long-Run Multipliers
    // ---------------------------------------------------------
    display _n as text "Table: Estimated Long-Run Multipliers (Total Effects)"
    display as result "{hline 80}"
    display as text " Variable" _col(22) "Coefficient" _col(38) "Std. Error" _col(54) "t-stat" _col(68) "P-value"
    display as result "{hline 80}"

    local lr_vars "`target_var'_POS `target_var'_MED `target_var'_NEG `control_vars'"
    
    // Restore model to ensure degrees of freedom availability
    quietly estimates restore final_tnardl
    local model_df = e(df_r) // <--- Save degrees of freedom here before they are lost
    local b_names : colfullnames e(b)

    foreach v of local lr_vars {
        if strpos("`b_names'", "L.`v'") & strpos("`b_names'", "L.`dep_var'") {
            
            // Restore model before each calculation
            quietly estimates restore final_tnardl
            
            capture quietly nlcom (LR_`v': -_b[L.`v'] / _b[L.`dep_var']), post
            
            if !_rc {
                local b  = _b[LR_`v']
                local se = _se[LR_`v']
                local t  = `b' / `se'
                
                // Use stored model_df instead of e(df_r)
                local p  = 2 * ttail(`model_df', abs(`t')) 
                
                local p_disp : display %6.4f `p'
                if "`p_disp'" == "." local p_disp " (N/A) "

                display as text " `v'" ///
                        as result _col(22) %9.4f `b' ///
                        as result _col(38) %9.4f `se' ///
                        as result _col(54) %8.2f `t' ///
                        as result _col(68) "`p_disp'"
            }
            else {
                display as text " `v'" _col(22) as error "Computation failed (Singular)"
            }
        }
        else {
             // Silently ignore dropped variables or print a note
             // display as text " `v'" _col(22) as txt " (Dropped)"
        }
    }
    display as result "{hline 80}"
    // Restore original model at the end to ensure code continuity
    quietly estimates restore final_tnardl
	
	
	
  // ---------------------------------------------------------
    // 4. Symmetry Tests
    // ---------------------------------------------------------
    
    matrix SYMTESS = J(3, 6, .)
     
    // --- 1. POS vs NEG ---
    quietly test L.`target_var'_POS = L.`target_var'_NEG
    matrix SYMTESS[1,1] = r(F), r(p)
    quietly test d.`target_var'_POS = d.`target_var'_NEG
    matrix SYMTESS[1,3] = r(F), r(p)
    quietly test (L.`target_var'_POS = L.`target_var'_NEG) (d.`target_var'_POS = d.`target_var'_NEG)
    matrix SYMTESS[1,5] = r(F), r(p)

    // --- 2. POS vs MED ---
    quietly test L.`target_var'_POS = L.`target_var'_MED
    matrix SYMTESS[2,1] = r(F), r(p)
    quietly test d.`target_var'_POS = d.`target_var'_MED
    matrix SYMTESS[2,3] = r(F), r(p)
    quietly test (L.`target_var'_POS = L.`target_var'_MED) (d.`target_var'_POS = d.`target_var'_MED)
    matrix SYMTESS[2,5] = r(F), r(p)

    // --- 3. MED vs NEG ---
    quietly test L.`target_var'_MED = L.`target_var'_NEG
    matrix SYMTESS[3,1] = r(F), r(p)
    quietly test d.`target_var'_MED = d.`target_var'_NEG
    matrix SYMTESS[3,3] = r(F), r(p)
    quietly test (L.`target_var'_MED = L.`target_var'_NEG) (d.`target_var'_MED = d.`target_var'_NEG)
    matrix SYMTESS[3,5] = r(F), r(p)

    // --- Print formatted table ---
    display _n as text "Table: Comprehensive Wald Tests for Long-Run, Short-Run, and Joint Asymmetry"
	display _n(2) as text "{hline 75}"
    display as text " Comparison" _col(20) "Long Run" _col(40) "Short Run" _col(60) "Joint"
    display as text "{hline 75}"

    local rows "POS vs NEG" "POS vs MED" "MED vs NEG"
    forvalues i = 1/3 {
        local lbl : word `i' of "POS_vs_NEG" "POS_vs_MED" "MED_vs_NEG"
        local lbl = subinstr("`lbl'", "_", " ", .)
        
        // Row for F-values
        display as text " `lbl'" ///
                as result _col(20) %8.3f SYMTESS[`i',1] ///
                as result _col(40) %8.3f SYMTESS[`i',3] ///
                as result _col(60) %8.3f SYMTESS[`i',5]
        
        // Row for P-values (in parentheses)
        display as text _col(20) "(" %5.4f SYMTESS[`i',2] ")" ///
                as text _col(40) "(" %5.4f SYMTESS[`i',4] ")" ///
                as text _col(60) "(" %5.4f SYMTESS[`i',6] ")"
        display ""
    }
    display as text "{hline 75}"
	display as text "Note: Numbers in parentheses represent P-values."
    display as text "      Null Hypothesis (H0): Symmetry holds (Equality of coefficients)."
    display as text "      Reject H0 if P-value < 0.05."

	// ---------------------------------------------------------
    // 5. Diagnostic Matrix and Table
    // ---------------------------------------------------------
    estimates restore final_tnardl
    matrix DIAG = J(4, 2, .)

    // 1. Serial Correlation (LM)
    quietly estat bgodfrey, lags(1)
    matrix DIAG[1,1] = r(chi2), r(p)

    // 2. Heteroskedasticity (BP)
    quietly estat hettest
    matrix DIAG[2,1] = r(chi2), r(p)

    // 3. Functional Form (RESET)
    quietly estat ovtest
    matrix DIAG[3,1] = r(F), r(p)

    // 4. Normality (JB)
    capture drop res_tmp
    quietly predict res_tmp if e(sample), residuals
    quietly summarize res_tmp, detail
    scalar jb_v = (r(N)/6) * (r(skewness)^2 + (1/4)*(r(kurtosis)-3)^2)
    scalar jb_p = chi2tail(2, jb_v)
    matrix DIAG[4,1] = jb_v, jb_p

    // Print diagnostics table
    display _n as text "Table: Diagnostic Tests for Model Robustness"
    display as result "{hline 75}"
    display as text " Test Name" _col(32) "Stat. Type" _col(48) "Value" _col(62) "P-value"
    display as text "{hline 75}"

    display as text " Serial Correlation (LM)" _col(32) "Chi-sq" _col(45) %8.3f DIAG[1,1] _col(60) "(" %5.4f DIAG[1,2] ")"
    display as text " Heteroskedasticity (BP)" _col(32) "Chi-sq" _col(45) %8.3f DIAG[2,1] _col(60) "(" %5.4f DIAG[2,2] ")"
    display as text " Functional Form (RESET)"  _col(32) "F-stat" _col(45) %8.3f DIAG[3,1] _col(60) "(" %5.4f DIAG[3,2] ")"
    display as text " Normality (Jarque-Bera)"  _col(32) "Chi-sq" _col(45) %8.3f DIAG[4,1] _col(60) "(" %5.4f DIAG[4,2] ")"

    display as result "{hline 75}"
    display as text " Note: H0 for all tests indicates No Violation (Model is Robust)."
    display as text "       Accept H0 if P-value > 0.05."
	
    
	
	
	// ---------------------------------------------------------
    // 6. Stability Plots
    // ---------------------------------------------------------
    
	if "`nograph'" == "" {
        display as result "Generating stability plots..."
	
	display _n as result "Generating Stability Plots..."
    
    // CUSUM
    estat sbcusum, name(CUSUM_`dep_var', replace) title("CUSUM: `dep_var'")
    
    // CUSUMQ (Robust Method)
    quietly {
        tempvar es res res_sq c_res_sq t_ax ub lb
        gen `es' = e(sample)
        predict `res' if `es'==1, residuals
        gen `res_sq' = `res'^2
        gen `c_res_sq' = sum(`res_sq') if `es'==1
        summarize `res_sq' if `es'==1, meanonly
        replace `c_res_sq' = `c_res_sq' / r(sum) if `es'==1
        gen `t_ax' = _n if `es'==1
        summarize `t_ax' if `es'==1, meanonly
        local N = r(N)
        gen `ub' = (1.358 / sqrt(`N')) + ((_n - r(min)) / (r(max) - r(min))) if `es'==1
        gen `lb' = -(1.358 / sqrt(`N')) + ((_n - r(min)) / (r(max) - r(min))) if `es'==1
    }
    
    twoway (line `c_res_sq' `t_ax' if `es'==1, lcolor(blue)) ///
           (line `ub' `t_ax' if `es'==1, lpattern(dash) lcolor(red)) ///
           (line `lb' `t_ax' if `es'==1, lpattern(dash) lcolor(red)), ///
           title("CUSUMQ: `dep_var'") name(CUSUMQ_`dep_var', replace) legend(off)

    display as result "{hline 80}"
    display as result "  TNARDL PROCEDURE COMPLETED SUCCESSFULLY"
    display as result "{hline 80}"
	
	}
    else {
        display as text "Note: Stability plots skipped as per 'nograph' option."
    }
	
// ---------------------------------------------------------
    // 7. Dynamic Multiplier Graphs (Manual Simulation)
    // ---------------------------------------------------------
    display _n as result "Computing Dynamic Multipliers (Horizon: 20 periods)..."
    
    quietly {
        local horizon 20
        estimates restore final_tnardl
        
        // Extract Error Correction Term (Lagged Dependent Var Coeff)
        scalar rho = _b[L.`dep_var']
        
        // Extract Raw Long-Run Coefficients
        foreach s in POS MED NEG {
            scalar b_`s' = _b[L.`target_var'_`s']
            
            tempvar m_`s'
            gen `m_`s'' = .
            
            // Calculate dynamic cumulative multipliers
            // Path depends on recursive multiplier relationship
            replace `m_`s'' = -b_`s' / rho in 1
            forvalues h = 2/`horizon' {
                // Mathematical simplification for dynamic path (Point Estimates)
                replace `m_`s'' = (1 + rho) * `m_`s''[_n-1] - (rho * (-b_`s' / rho)) in `h'
            }
        }
        
        // Prepare time variable for plotting
        tempvar h_axis
        gen `h_axis' = _n - 1 in 1/`horizon'
    }

    // Plot Dynamic Multipliers
    twoway (line `m_POS' `h_axis' in 1/`horizon', lcolor(blue) lwidth(medthick)) ///
           (line `m_MED' `h_axis' in 1/`horizon', lcolor(green) lwidth(medthick)) ///
           (line `m_NEG' `h_axis' in 1/`horizon', lcolor(red) lwidth(medthick)), ///
        title("{bf:Dynamic Multipliers Path}") ///
        subtitle("Response of `dep_var' to shocks in `target_var'") ///
        xtitle("Periods after shock") ytitle("Cumulative Effect") ///
        legend(order(1 "Positive Shock" 2 "Medium Shock" 3 "Negative Shock") pos(6) rows(1)) ///
        name(Multipliers_`dep_var', replace)

    display as result "Success: Dynamic Multiplier Graph generated."

end