*! 1.0.0 KNK 28 July 2025

program stackbar
version 12
syntax varlist [if] [in], ///
     Over(varname) ///
    [Title(string)] ///
	[N] ///
	[REcast(string)] ///
    [Intensity(integer 50)] ///
    [OVERopts(string asis)] ///
    [BLABELopts(string asis)] ///
    [LEGENDopts(string asis)] ///
    [GRAPHopts(string asis)] ///
	[SAving(string)]

// Set defaults
if "`title'" == "" local title "Stacked Percentage Bar"

// Set up saving option with PNG default
if "`saving'" != "" {
    if strpos("`saving'", ".") == 0 {
        local saving "`saving'.png"
    }
}

// Validate that over() variable exists
capture confirm variable `over'
if _rc {
    di as error "Variable `over' not found"
    exit 111
}

// Auto-encode string over() variable for user convenience
capture confirm string variable `over'
if !_rc {
    tempvar over_encoded
    encode `over', gen(`over_encoded')
    local over "`over_encoded'"
}

// Validate that all variables in varlist exist
foreach var of local varlist {
    capture confirm variable `var'
    if _rc {
        di as error "Variable `var' not found"
        exit 111
    }
}

// Count the number of variables to determine which approach to use
local nvars : word count `varlist'

// Validate binary variables if multiple variables
if `nvars' > 1 {
    foreach var of local varlist {
        quietly summarize `var'
        if r(min) < 0 | r(max) > 1 {
            display as error "Multiple variables should be binary (0/1): `var' has values outside 0-1 range"
            exit 198
        }
    }
}

// COMMON BRANCH: Data setup and filtering
preserve

quietly {
    marksample touse, strok
    keep if `touse' == 1
    
    // Check if any observations remain after if/in conditions
    count
    if r(N) == 0 {
        noisily di as error "No observations remain after applying if/in conditions"
        exit 2000
    }
    
    // Add N counts to over() variable labels if requested
    if "`n'" != "" {
        // Calculate N for title
        count
        local N `r(N)'
        local title "`title' (N = `N')"
        
        // Get the value label name
        local vallbl : value label `over'
        
        levelsof `over', local(over_levels)
        foreach level of local over_levels {
            count if `over' == `level'
            local n_`level' = r(N)
            
            // Get current label
            local current_label : label `vallbl' `level'
            if "`current_label'" == "" local current_label "`level'"
            
            // Modify the label
            label define `vallbl' `level' "`current_label' (n=`n_`level'')", modify
        }
        
    }
} // end common quietly block

// BRANCH-SPECIFIC DATA PROCESSING
if `nvars' == 1 {
    // Single variable - use select_one approach
    local varname `varlist'
    
    quietly {
		
		// Auto-encode string variable for user convenience  
		capture confirm string variable `varname'
		if !_rc {
		tempvar varname_encoded
		encode `varname', gen(`varname_encoded')  
		local varname "`varname_encoded'"
		}
		
        // Get levels and value labels for the legend
        levelsof `varname', local(levels)
        local legend_order ""
        local i = 1
        foreach level in `levels' {
            local vallabel : label (`varname') `level'
            if "`vallabel'" == "" local vallabel "`level'"
            local legend_order `"`legend_order' `i' "`vallabel'""'
            local ++i
        }
        
        // Prepare data for stacked bar chart
        contract `over' `varname'
        bysort `over': egen total = sum(_freq)
        gen percent = (_freq/total) * 100
        keep `over' `varname' percent
        reshape wide percent, i(`over') j(`varname')
        
        // Build the varlist for graphing
        local varlist_new ""
        foreach level in `levels' {
            local varlist_new "`varlist_new' percent`level'"
        }
    } // end quietly
}
else {
    // Multiple variables - use select_multiple approach
    
    quietly {
        // Get variable labels for the legend
        local legend_order ""
        local i = 1
        foreach var of local varlist {
            local varlabel : variable label `var'
            if "`varlabel'" == "" local varlabel "`var'"
            local legend_order `"`legend_order' `i' "`varlabel'""'
            local ++i
        }
        
        // Prepare data for stacked bar chart
        collapse (mean) `varlist', by(`over')
        
        // Convert to percentages
        foreach var of local varlist {
            replace `var' = `var' * 100
        }
        
        // Keep original varlist for graphing
        local varlist_new "`varlist'"
    } // end quietly
}

// Set dynamic default for legend rows based on actual items to display
local nitems : word count `varlist_new'
local rows = ceil(`nitems'/2)  // Up to 2 items per row

// Set graph type with smart defaults
local default_bar = cond(`nvars' > 1, "hbar", "bar")
local graph_type = cond("`recast'" != "", "graph `recast'", "graph `default_bar'")

// UNIFIED GRAPHING
`graph_type' `varlist_new', ///
    over(`over', `overopts') ///
    stack ///
    title("`title'", size(medsmall)) ///
    ytitle("Percent") ///
    blabel(bar, format(%9.1f) position(center)) ///
    blabel(bar, `blabelopts') ///
    legend(order(`legend_order') position(6) rows(`rows')) ///
    legend(`legendopts') ///
    intensity(`intensity') `graphopts'

// COMMON ENDING: Save and restore
if "`saving'" != "" {
    graph export "`saving'", replace
}

restore

end
