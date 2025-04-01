* biastest.ado
program define biastest
    version 18.0
    syntax varlist(min=2) [if] [in], m1(string) [m1ops(string)] m2(string) [m2ops(string)]   
	
    // Separate dependent and independent variables
    local depvar : word 1 of `varlist'
    local indepvars : list varlist - depvar

    // Display dependent and independent variables to the user
    di as text "Dependent variable: `depvar'" 
    di as text "Independent variables: `indepvars'"
    di as text "Model 1 Estimation Results"

    // Run the first regression model (M1) and store results
    `m1' `depvar' `indepvars' `if' `in', `m1ops'
    matrix b_m1 = e(b)  // Coefficients from the first model
    matrix V_m1 = e(V)  // Variance-covariance matrix from the first model
    scalar df_m1 = e(df_r)  // Degrees of freedom from the first model

    // Display results for the second model
    di as text "Model 2 Estimation Results"
    
    // Run the second regression model (M2) and store results
    `m2' `depvar' `indepvars' `if' `in', `m2ops'
    matrix b_m2 = e(b)  // Coefficients from the second model
    matrix V_m2 = e(V)  // Variance-covariance matrix from the second model

    // Get the number of independent variables
    local numvars : word count `indepvars'

    // Determine the maximum length of variable names for formatting
    local maxvarlen = 0
    foreach var of local indepvars {
        local varlen = length("`var'")
        if `varlen' > `maxvarlen' {
            local maxvarlen = `varlen'
        }
    }

    // Define column widths based on the maximum variable name length
    local col1_width = `maxvarlen' + 2  // Column for variable names
    local col2_width = 10  // Column for Model1 coefficients
    local col3_width = 10  // Column for Model2 coefficients
    local col4_width = 10  // Column for differences
    local col5_width = 10  // Column for t-statistics
    local col6_width = 10  // Column for p-values

    // Calculate the total width of the table
    local total_width = `col1_width' + `col2_width' + `col3_width' + `col4_width' + `col5_width' + `col6_width' + 10

    // Display the header for the individual bias test
    di as text "Variable Bias Test:"
	di as text "H0: The parameters are equal"
    di as text _dup(`total_width') "-"
    di as text _col(2) "Variables" _col(`=`col1_width'+4') "|" ///
        _col(`=`col1_width'+4') " Model 1 " _col(`=`col1_width'+`col2_width'+4') "|" ///
        _col(`=`col1_width'+`col2_width'+6') " Model 2 " _col(`=`col1_width'+`col2_width'+`col3_width'+6') "|" ///
        _col(`=`col1_width'+`col2_width'+`col3_width'+8') "Diff." _col(`=`col1_width'+`col2_width'+`col3_width'+`col4_width'+8') "|" ///
        _col(`=`col1_width'+`col2_width'+`col3_width'+`col4_width'+10') "t-stat" _col(`=`col1_width'+`col2_width'+`col3_width'+`col4_width'+`col5_width'+10') "|" ///
        _col(`=`col1_width'+`col2_width'+`col3_width'+`col4_width'+`col5_width'+12') "P>|t|"
    di as text _dup(`total_width') "-"

    // Loop through each independent variable
    forval i = 1/`numvars' {
        // Get the variable name
        local varname : word `i' of `indepvars'

        // Extract coefficients and standard errors from both models
        scalar beta_m1 = b_m1[1, `i']
        scalar beta_m2 = b_m2[1, `i']
        scalar stderr_m1 = sqrt(V_m1[`i', `i'])
        scalar stderr_m2 = sqrt(V_m2[`i', `i'])
        
        // Calculate the difference, t-statistic, and p-value
        scalar diff = beta_m1 - beta_m2
        scalar pooled_se = sqrt(stderr_m1^2 + stderr_m2^2)
        scalar tvalue = diff / pooled_se
        scalar pvalue = 2 * ttail(df_m1, abs(tvalue))
		
        // Display the results in a formatted table
        di as text _col(2) "`varname'" _col(`=`col1_width'+4') "|" ///
            _col(`=`col1_width'+4') %9.4f beta_m1 _col(`=`col1_width'+`col2_width'+4') "|" ///
            _col(`=`col1_width'+`col2_width'+6') %9.4f beta_m2 _col(`=`col1_width'+`col2_width'+`col3_width'+6') "|" ///
            _col(`=`col1_width'+`col2_width'+`col3_width'+8') %9.4f diff _col(`=`col1_width'+`col2_width'+`col3_width'+`col4_width'+8') "|" ///
            _col(`=`col1_width'+`col2_width'+`col3_width'+`col4_width'+10') %9.4f tvalue _col(`=`col1_width'+`col2_width'+`col3_width'+`col4_width'+`col5_width'+10') "|" ///
            _col(`=`col1_width'+`col2_width'+`col3_width'+`col4_width'+`col5_width'+12') %9.4f pvalue
    }
    
    di as text _dup(`total_width') "-"

    // Perform a joint chi-squared test for all coefficients (excluding the constant term)
    di as text "Jointly Bias Test:"
	di as text "H0: All parameters are equal"
    
    // Exclude the constant term from the coefficient vectors and variance-covariance matrices
    matrix b_m1_no_const = b_m1[1, 1..`numvars']  // Exclude the last column (constant term)
    matrix b_m2_no_const = b_m2[1, 1..`numvars']  // Exclude the last column (constant term)
    matrix V_m1_no_const = V_m1[1..`numvars', 1..`numvars']  // Exclude the last row and column (constant term)
    matrix V_m2_no_const = V_m2[1..`numvars', 1..`numvars']  // Exclude the last row and column (constant term)
    
    // Calculate the difference in coefficients (excluding the constant term)
    matrix diff_coef = b_m1_no_const - b_m2_no_const
    
    // Calculate the variance-covariance matrix of the difference (excluding the constant term)
    matrix V_diff = V_m1_no_const - V_m2_no_const 
    
    // Check if the variance-covariance matrix is invertible
    if det(V_diff) <= 0 {
        di as error "Variance-covariance matrix of the difference is not positive definite. Chi-squared test cannot be computed."
        exit
    }
    
    // Compute the chi-squared statistic
    matrix chi2_stat = diff_coef * inv(V_diff) * diff_coef'
    scalar chi2_value = abs(chi2_stat[1, 1])
    
    // Degrees of freedom for the chi-squared test
    scalar df_chi2 = `numvars'
    
    // Calculate the p-value for the chi-squared test
    scalar chi2_pvalue = chi2tail(df_chi2, chi2_value)
    
    // Display the chi-squared test results
    display as text "chi2" "(" df_chi2 ") ="%9.4f chi2_value
    display as text "Prob > chi2 ="%9.4f chi2_pvalue
    display as text _dup(`total_width') "-"
end
