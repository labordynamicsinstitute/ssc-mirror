program define biastest, eclass
    version 18.0
    syntax varlist(min=2) [if] [in], m1(string) [m1ops(string)] m2(string) [m2ops(string)] [SIGMALESS]

    // --- Setup ---
    local depvar : word 1 of `varlist'
    local indepvars : list varlist - depvar
    local numvars : word count `indepvars'
    
    di as text "Dependent variable: `depvar'"
    di as text "Independent variables: `indepvars'"

    tempname b1 V1 b2 V2 tstats pvalues diffs ses s2_1 s2_2
    tempname sum_abs_b1 sum_abs_b2 b_larger V_larger b_smaller V_smaller
    tempname diff_coef V_diff V_diff_ind inv_V_diff chi2_stat

    // --- Model 1 Estimation ---
    di as text _n "Model 1 Estimation Results"
    capture noisily `m1' `depvar' `indepvars' `if' `in', `m1ops'
    if _rc != 0 {
        di as error "Error in Model 1 estimation"
        exit _rc
    }
    matrix `b1' = e(b)
    matrix `V1' = e(V)
    scalar N = e(N)
    scalar `s2_1' = e(rmse) 
    if missing(`s2_1') scalar `s2_1' = e(sigma_e)
    if missing(`s2_1') scalar `s2_1' = e(sigma)

    // --- Model 2 Estimation ---
    di as text _n "Model 2 Estimation Results"
    capture noisily `m2' `depvar' `indepvars' `if' `in', `m2ops'
    if _rc != 0 {
        di as error "Error in Model 2 estimation"
        exit _rc
    }
    matrix `b2' = e(b)
    matrix `V2' = e(V)
    scalar `s2_2' = e(rmse)
    if missing(`s2_2') scalar `s2_2' = e(sigma_e)
    if missing(`s2_2') scalar `s2_2' = e(sigma)

    // Check if sigmaless is needed but sigma values not available
    if "`sigmaless'" != "" & (missing(`s2_1') | missing(`s2_2')) {
        di as err "Warning: sigma/rmse values not found in estimation results"
        di as err "sigmaless adjustment cannot be applied"
        local sigmaless ""
    }

    // --- Determine which model has larger coefficients on average ---
    scalar `sum_abs_b1' = 0
    scalar `sum_abs_b2' = 0
    
    forval i = 1/`numvars' {
        scalar `sum_abs_b1' = `sum_abs_b1' + abs(`b1'[1, `i'])
        scalar `sum_abs_b2' = `sum_abs_b2' + abs(`b2'[1, `i'])
    }
    
    if `sum_abs_b1' > `sum_abs_b2' {
        matrix `b_larger' = `b1'
        matrix `V_larger' = `V1'
        matrix `b_smaller' = `b2'
        matrix `V_smaller' = `V2'
        local larger_model "Model 1"
        local smaller_model "Model 2"
    }
    else {
        matrix `b_larger' = `b2'
        matrix `V_larger' = `V2'
        matrix `b_smaller' = `b1'
        matrix `V_smaller' = `V1'
        local larger_model "Model 2"
        local smaller_model "Model 1"
    }
    
    // Apply sigmaless adjustment if requested and possible
    if "`sigmaless'" != "" {
        matrix `V_smaller' = ((`s2_1'/`s2_2')^2) * `V_smaller'
        matrix `V_diff_ind' = `V_larger' - `V_smaller'
    }
    else {
        matrix `V_diff_ind' = `V_larger' - `V_smaller'
    }
    
    // --- Preparation ---
    matrix `tstats' = J(1, `numvars', .)
    matrix `pvalues' = J(1, `numvars', .)
    matrix `diffs' = J(1, `numvars', .)
    matrix `ses' = J(1, `numvars', .)

    local maxvarlen = 17
    local col1 = `maxvarlen' + 1
    local col2 = `col1' + 13
    local col3 = `col2' + 13
    local col4 = `col3' + 13
    local col5 = `col4' + 13
    local col6 = `col5' + 13

    // --- Individual Bias Test ---
    di as text _n "Variable Bias Test:"
    di as text "{hline 91}"    
    di as text "H0: The parameters are equal"
    di as text "Variable" _col(`col1') "  `larger_model' " _col(`col2') "  `smaller_model' " _col(`col3') "   Diff. " _col(`col4') "   Std. Err. " _col(`col5') "   t-stat " _col(`col6') "   P>|t| "
    di as text "{hline 91}"

    forval i = 1/`numvars' {
        local fullvarname : word `i' of `indepvars'
        local varname = substr("`fullvarname'", 1, 15)
        
        scalar beta_larger = `b_larger'[1, `i']
        scalar beta_smaller = `b_smaller'[1, `i']
        
        scalar diff = beta_larger - beta_smaller
        scalar diff_se = sqrt(abs(`V_diff_ind'[`i', `i']))
        scalar tvalue = diff / diff_se
        scalar pvalue = 2 * ttail(N - `numvars', abs(tvalue))
        
        matrix `diffs'[1, `i'] = diff
        matrix `ses'[1, `i'] = diff_se
        matrix `tstats'[1, `i'] = tvalue
        matrix `pvalues'[1, `i'] = pvalue
        
        di as text _col(2) "`varname'" ///
            _col(`col1') %9.4f beta_larger ///
            _col(`col2') %9.4f beta_smaller ///
            _col(`col3') %9.4f diff ///
            _col(`col4') %9.4f diff_se ///
            _col(`col5') %9.3f tvalue ///
            _col(`col6') %9.3f pvalue
    }

    di as text "{hline 91}"

    // --- Joint Bias Test ---
    di as text _n "Joint Bias Test:"
    di as text "H0: All parameters are equal"
    di as text "{hline 36}"

    // Create submatrices excluding constant if present
    matrix `diff_coef' = `b_larger'[1, 1..`numvars'] - `b_smaller'[1, 1..`numvars']
    matrix `V_diff' = `V_larger'[1..`numvars', 1..`numvars'] - `V_smaller'[1..`numvars', 1..`numvars']

    // Make matrix symmetric (manually since makesymmetric() doesn't exist)
    forval i = 1/`numvars' {
        forval j = `i'/`numvars' {
            matrix `V_diff'[`i',`j'] = (`V_diff'[`i',`j'] + `V_diff'[`j',`i'])/2
            matrix `V_diff'[`j',`i'] = `V_diff'[`i',`j']
        }
        // Ensure positive diagonal
        matrix `V_diff'[`i',`i'] = abs(`V_diff'[`i',`i'])
    }

    // Check if matrix is positive definite
    capture matrix eigenvalues re im = `V_diff'
    if _rc != 0 {
        di as error "Warning: Could not compute eigenvalues of V_diff matrix"
        di as error "Joint test cannot be performed"
        scalar chi2_value = .
        scalar chi2_pvalue = .
    }
    else {
        local is_posdef = 1
        forval i = 1/`numvars' {
            if re[1,`i'] <= 0 {
                local is_posdef = 0
                continue, break
            }
        }
        
        if `is_posdef' {
            capture matrix `inv_V_diff' = invsym(`V_diff')
            if _rc == 0 {
                matrix `chi2_stat' = `diff_coef' * `inv_V_diff' * `diff_coef''
                scalar chi2_value = `chi2_stat'[1, 1]
                scalar df_chi2 = `numvars'
                scalar chi2_pvalue = chi2tail(df_chi2, chi2_value)
                
                di as text _col(2) "chi2(" df_chi2 ")" _col(15) "= " %9.3f chi2_value
                di as text _col(2) "Prob > chi2" _col(15) "= " %9.3f chi2_pvalue
            }
            else {
                di as error "Warning: Could not invert V_diff matrix"
                di as error "Joint test cannot be performed"
                scalar chi2_value = .
                scalar chi2_pvalue = .
            }
        }
        else {
            di as error "Warning: V_diff matrix is not positive definite"
            di as error "Joint test cannot be performed"
            di as error "Consider using the sigmaless option"
            scalar chi2_value = .
            scalar chi2_pvalue = .
        }
    }

    di as text "{hline 36}"
    
    // --- Display notes after joint test ---
    if "`sigmaless'" != "" {
        di as text _n "Note: Sigmaless adjustment applied (V_smaller scaled by (s1/s2)^2)"
    }
    di as text _n "Note: Coefficient comparison - `larger_model' has larger coefficients on average than `smaller_model'"
    di as text "      All tests will use `larger_model' - `smaller_model' "

    // --- Store results ---
    ereturn clear
    ereturn scalar N = N
    ereturn scalar chi2 = chi2_value
    ereturn scalar p = chi2_pvalue
    ereturn scalar df = `numvars'
    ereturn matrix b_m1 = `b1'
    ereturn matrix b_m2 = `b2'
    ereturn matrix V_m1 = `V1'
    ereturn matrix V_m2 = `V2'
    ereturn matrix t_stats = `tstats'
    ereturn matrix p_values = `pvalues'
    ereturn matrix diffs = `diffs'
    ereturn matrix ses = `ses'
    ereturn local depvar "`depvar'"
    ereturn local indepvars "`indepvars'"
    ereturn local larger_model "`larger_model'"
    ereturn local smaller_model "`smaller_model'"
    if "`sigmaless'" != "" {
        ereturn local sigmaless "adjusted"
        ereturn scalar s2_1 = `s2_1'
        ereturn scalar s2_2 = `s2_2'
    }
end
