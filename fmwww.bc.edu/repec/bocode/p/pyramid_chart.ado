*! version 1.1 07JULY2024  Masud Rahman

// Version compatibility
version 17.0

program define pyramid_chart, rclass
    // Declare the syntax
syntax varlist(numeric) [if] [in], OVER(varname) BY(varname) DEC(integer) [*]

    // Extract variables from the varlist
    local num_var `varlist'
    local ycat_var `over'
    local xcat_var `by'

    // Extract the options and provide default values if not specified
    local decimal_place = 0
    if "`dec'" != "" {
        local decimal_place = real("`dec'")
    }

    // Capture any additional options
    local additional_options "`options'"

    // Check for the presence of variables
    if ("`num_var'" == "" | "`xcat_var'" == "" | "`ycat_var'" == "") {
        di as error "Please provide a numeric variable, and two categorical variables."
        exit 198
    }

    // Debugging: Confirm variables are set correctly
    di "Numeric Variable: `num_var'"
    di "Y-Categorical Variable: `ycat_var'"
    di "X-Categorical Variable: `xcat_var'"

    // Find the label name assigned to xcat_var
    local labelname : value label `xcat_var'
    
    // Extract the labels for the xcat_var variable
    qui label list `labelname'

    // Extract the labels for the categories (assuming categories are 1 and 2 for simplicity)
    local left_label : label `labelname' 1
    local right_label : label `labelname' 2

    // Declare tempvars
    tempvar total_population population_pct population_pct_neg population_pct_left pct_left_label pct_right_label

    // Calculate the total `num_var` for each category
    egen `total_population' = total(`num_var'), by(`xcat_var')
    
    // Calculate the `num_var` percentage for each age group within each category
    gen `population_pct' = (`num_var' / `total_population') * 100
    
    // Create a variable for negative percentage for the pyramid
    qui gen `population_pct_neg' = -`population_pct' if `xcat_var' == 1
    qui replace `population_pct_neg' = `population_pct' if `xcat_var' == 2
    
    // Identify the unique age groups and store them in a local macro
    qui levelsof `ycat_var', local(agegroups)
    
    // Generate a variable for the absolute value of male `num_var` percentage for labels
    gen `population_pct_left' = abs(`population_pct_neg')

    // Create formatted label variables for the scatter plots
    qui gen str `pct_left_label' = string(`population_pct_left', "%9.`decimal_place'f")
    qui gen str `pct_right_label' = string(`population_pct', "%9.`decimal_place'f")

    // Calculate the maximum percentage value
    qui summarize `population_pct'
    local max_pct = ceil(r(max) / 10) * 10

    if `max_pct' > 6 {
        // Generate a list of x-axis labels from 0 to max_pct in increments of 5
        local xlabels
        forvalues i = 0(5)`max_pct' {
            local xlabels `xlabels' `i'
        }

        // Generate a list of negative x-axis labels from -max_pct to -5 in increments of 5
        local neg_xlabels
        forvalues i = -`max_pct'(5)-5 {
            local neg_xlabels `neg_xlabels' `i'
        }
    } 
	else {
        // Generate a list of x-axis labels from 0 to max_pct in increments of 1
        local xlabels
        forvalues i = 0(1)`max_pct' {
            local xlabels `xlabels' `i'
        }

        // Generate a list of negative x-axis labels from -max_pct to -1 in increments of 1
        local neg_xlabels
        forvalues i = -`max_pct'(1)-1 {
            local neg_xlabels `neg_xlabels' `i'
        }
    }

    // Combine the negative and positive labels, converting negative labels to positive for display
    local xlabel_list
    foreach label in `neg_xlabels' 0 `xlabels' {
        local abs_label = abs(`label')
        local xlabel_list `xlabel_list' `label' "`abs_label'"
    }

    // Plot the `num_var` pyramid with additional options
    twoway (bar `population_pct_neg' `ycat_var' if `xcat_var' == 1, horizontal base(0) color(navy)) ///
           (bar `population_pct' `ycat_var' if `xcat_var' == 2, horizontal base(0) color(maroon)) ///
           (scatter `ycat_var' `population_pct_neg' if `xcat_var' == 1, msymbol(i) mlab(`pct_left_label') mlabcolor(gs0) mlabp(9)) ///
           (scatter `ycat_var' `population_pct' if `xcat_var' == 2, msymbol(i) mlab(`pct_right_label') mlabcolor(gs0) mlabp(3)), ///
           legend(order(1 "`left_label'" 2 "`right_label'")) ///
           ylabel(`agegroups', valuelabel angle(0)) ///
           xlabel(`xlabel_list', format(%3.0f)) ///
           `additional_options'
end
