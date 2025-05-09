program define biastest, eclass
    version 18.0
    syntax varlist(min=2) [if] [in], m1(string) [m1ops(string)] m2(string) [m2ops(string)]

    // --- Setup ---
    local depvar : word 1 of `varlist'
    local indepvars : list varlist - depvar
    local numvars : word count `indepvars'
    
    // Calculate degrees of freedom based on number of independent variables
    scalar df = `numvars'

    di as text "Dependent variable: `depvar'"
    di as text "Independent variables: `indepvars'"
    di as text "Degrees of freedom: " df

    tempname b1 V1 b2 V2 tstats pvalues

    // --- Model 1 Estimation ---
    di as text _n "Model 1 Estimation Results"
    `m1' `depvar' `indepvars' `if' `in', `m1ops'
    matrix `b1' = e(b)
    matrix `V1' = e(V)

    // --- Model 2 Estimation ---
    di as text _n "Model 2 Estimation Results"
    `m2' `depvar' `indepvars' `if' `in', `m2ops'
    matrix `b2' = e(b)
    matrix `V2' = e(V)

    // --- Determine which model has larger coefficients on average ---
    tempname sum_abs_b1 sum_abs_b2
    scalar `sum_abs_b1' = 0
    scalar `sum_abs_b2' = 0
    
    forval i = 1/`numvars' {
        scalar `sum_abs_b1' = `sum_abs_b1' + abs(`b1'[1, `i'])
        scalar `sum_abs_b2' = `sum_abs_b2' + abs(`b2'[1, `i'])
    }
    
    tempname b_larger V_larger b_smaller V_smaller
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
    
    di as text _n "Note: Coefficient comparison - `larger_model' has larger coefficients on average than `smaller_model'"
    di as text "      All tests will use `larger_model' - `smaller_model' "

    // --- Preparation ---
    matrix `tstats' = J(1, `numvars', .)
    matrix `pvalues' = J(1, `numvars', .)

    local maxvarlen = 17
    local col1 = `maxvarlen' + 1
    local col2 = `col1' + 13
    local col3 = `col2' + 13
    local col4 = `col3' + 13
    local col5 = `col4' + 13

    tempname V_diff_ind
    matrix `V_diff_ind' = `V_larger' - `V_smaller'

    // --- Individual Bias Test ---
    di as text _n "Variable Bias Test:"
    di as text "{hline 78}"    
    di as text "H0: The parameters are equal"
    di as text "Variable" _col(`col1') "  `larger_model' " _col(`col2') "  `smaller_model' " _col(`col3') "   Diff. " _col(`col4') "   t-stat " _col(`col5') "   P>|t| "
    di as text "{hline 78}"

    forval i = 1/`numvars' {
        local fullvarname : word `i' of `indepvars'
        local varname = substr("`fullvarname'", 1, 15)
        
        scalar beta_larger = `b_larger'[1, `i']
        scalar beta_smaller = `b_smaller'[1, `i']
        
        scalar diff = beta_larger - beta_smaller
        scalar diff_se = sqrt(abs(`V_diff_ind'[`i', `i']))
        scalar tvalue = diff / diff_se
        
        scalar pvalue = 2 * ttail(df, abs(tvalue))
        
        matrix `tstats'[1, `i'] = tvalue
        matrix `pvalues'[1, `i'] = pvalue
        
        di as text _col(2) "`varname'" ///
            _col(`col1') %9.4f beta_larger ///
            _col(`col2') %9.4f beta_smaller ///
            _col(`col3') %9.4f diff ///
            _col(`col4') %9.4f tvalue ///
            _col(`col5') %9.4f pvalue
    }

    di as text "{hline 78}"

    // --- Joint Bias Test ---
    di as text _n "Jointly Bias Test:"
    di as text "H0: All parameters are equal"
    di as text "{hline 36}"

    matrix b_larger_no_const = `b_larger'[1, 1..`numvars']
    matrix b_smaller_no_const = `b_smaller'[1, 1..`numvars']
    matrix V_larger_no_const = `V_larger'[1..`numvars', 1..`numvars']
    matrix V_smaller_no_const = `V_smaller'[1..`numvars', 1..`numvars']

    matrix diff_coef = b_larger_no_const - b_smaller_no_const
    matrix V_diff = V_larger_no_const - V_smaller_no_const

    // --- Ensure positive definiteness ---
    forval i = 1/`numvars' {
        matrix V_diff[`i',`i'] = abs(V_diff[`i',`i'])
    }

    capture matrix eigenvalues re im = V_diff
    if _rc != 0 {
        di as error "Variance-covariance matrix is not positive definite. Test cannot be computed."
        exit 506
    }

    local is_posdef = 1
    forval i = 1/`numvars' {
        if re[1,`i'] <= 0 {
            local is_posdef = 0
            continue, break
        }
    }

    if `is_posdef' == 0 {
        forval i = 1/`numvars' {
            forval j = 1/`numvars' {
                matrix V_diff[`i',`j'] = abs(V_diff[`i',`j'])
            }
        }
    }

    matrix chi2_stat = diff_coef * inv(V_diff) * diff_coef'
    scalar chi2_value = chi2_stat[1, 1]
    scalar df_chi2 = `numvars'
    scalar chi2_pvalue = chi2tail(df_chi2, chi2_value)

    di as text _col(2) "chi2(" df_chi2 ")" _col(15) "= " %9.4f chi2_value
    di as text _col(2) "Prob > chi2" _col(15) "= " %9.4f chi2_pvalue
    di as text "{hline 36}"

    // --- Store results ---
    ereturn clear
    ereturn scalar chi2 = chi2_value
    ereturn scalar p = chi2_pvalue
    ereturn scalar df = df_chi2
    ereturn matrix b_m1 = `b1'
    ereturn matrix b_m2 = `b2'
    ereturn matrix V_m1 = `V1'
    ereturn matrix V_m2 = `V2'
    ereturn matrix t_stats = `tstats'
    ereturn matrix p_values = `pvalues'
    ereturn local larger_model "`larger_model'"
    ereturn local smaller_model "`smaller_model'"
end
