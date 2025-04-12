program define biastest, eclass
    version 18.0
    syntax varlist(min=2) [if] [in], m1(string) [m1ops(string)] m2(string) [m2ops(string)]

    local depvar : word 1 of `varlist'
    local indepvars : list varlist - depvar
    local numvars : word count `indepvars'

    di as text "Dependent variable: `depvar'"
    di as text "Independent variables: `indepvars'"
    
    tempname b1 V1 df1 b2 V2 tstats pvalues
    
    // Run Model 1
    di as text _n "Model 1 Estimation Results"
    `m1' `depvar' `indepvars' `if' `in', `m1ops'
    matrix `b1' = e(b)
    matrix `V1' = e(V)
    scalar `df1' = e(df_r)

    // Run Model 2
    di as text _n "Model 2 Estimation Results"
    `m2' `depvar' `indepvars' `if' `in', `m2ops'
    matrix `b2' = e(b)
    matrix `V2' = e(V)

    matrix `tstats' = J(1, `numvars', .)
    matrix `pvalues' = J(1, `numvars', .)
    
    // Calculate maximum variable name length for formatting
    local maxvarlen = 17 // Set max length to 10 characters
    local col1 = `maxvarlen' + 1
    local col2 = `col1' + 13
    local col3 = `col2' + 13
    local col4 = `col3' + 13
    local col5 = `col4' + 13
    
    // Individual Bias Test Table
    di as text _n "Variable Bias Test:"
    di as text "{hline 78}"    
    di as text "H0: The parameters are equal"
    di as text "Variable" _col(`col1') "  Model 1 " _col(`col2') "  Model 2 " _col(`col3') "   Diff. " _col(`col4') "   t-stat " _col(`col5') "   P>|t| "
    di as text "{hline 78}"

    // Create V_diff matrix for individual tests
    tempname V_diff_ind
    matrix `V_diff_ind' = `V1' - `V2'
    
    forval i = 1/`numvars' {
        local fullvarname : word `i' of `indepvars'
        local varname = substr("`fullvarname'", 1, 15) // Truncate variable name to 10 characters
        
        scalar beta_m1 = `b1'[1, `i']
        scalar beta_m2 = `b2'[1, `i']
        
        scalar diff = beta_m1 - beta_m2
        scalar diff_se = sqrt(`V_diff_ind'[`i', `i'])
        scalar tvalue = diff / diff_se
        scalar pvalue = 2 * ttail(`df1', abs(tvalue))

        matrix `tstats'[1, `i'] = tvalue
        matrix `pvalues'[1, `i'] = pvalue
        
        di as text _col(2) "`varname'" ///
            _col(`col1') %9.4f beta_m1 ///
            _col(`col2') %9.4f beta_m2 ///
            _col(`col3') %9.4f diff ///
            _col(`col4') %9.4f tvalue ///
            _col(`col5') %9.4f pvalue
    }

    di as text "{hline 78}"

    // Joint Bias Test
    di as text _n "Jointly Bias Test:"
    di as text "H0: All parameters are equal"
    di as text "{hline 36}"
    
    matrix b_m1_no_const = `b1'[1, 1..`numvars']
    matrix b_m2_no_const = `b2'[1, 1..`numvars']
    matrix V_m1_no_const = `V1'[1..`numvars', 1..`numvars']
    matrix V_m2_no_const = `V2'[1..`numvars', 1..`numvars']
    
    matrix diff_coef = b_m1_no_const - b_m2_no_const
    matrix V_diff = V_m1_no_const - V_m2_no_const
    
    if det(V_diff) <= 0 {
        di as error "Variance-covariance matrix is not positive definite. Test cannot be computed."
        exit 506
    }
    
    matrix chi2_stat = diff_coef * inv(V_diff) * diff_coef'
    scalar chi2_value = chi2_stat[1, 1]
    scalar df_chi2 = `numvars'
    scalar chi2_pvalue = chi2tail(df_chi2, chi2_value)
    
    di as text _col(2) "chi2(" df_chi2 ")" _col(15) "= " %9.4f chi2_value
    di as text _col(2) "Prob > chi2" _col(15) "= " %9.4f chi2_pvalue
    di as text "{hline 36}"
    
    // Store results
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
end
