
cap program drop sumdocx

program define sumdocx

    version 15
	
	syntax varlist [if] [, By(varname) Title(string) Save(string) THreshold(real 0.05) Decimals(real 2) Font(string) SIze(real 8) Color(string)] 
	
    qui {	
		
		if "`color'" == "" {
		local color "1F497D"
		}
		
		* Retain only numeric variables from the varlist
	
		ds `varlist', has(type string)
		local string_vars `r(varlist)'
		
		ds `varlist', has(type numeric)
		local num_vars `r(varlist)'
		
		* Remove the by variable from the list of variables to disaggregate the by variable by!
	
		if "`by'" != "" {	
	
		local num_vars_clean
		
		foreach var of local num_vars {
		if "`var'" != "`by'" {
        local num_vars_clean `num_vars_clean' `var'
		}
		}
		
		local num_vars `num_vars_clean'
		
		}
		
		if "`num_vars'" == "" {
		display as error "Error: You must specify at least one numeric variable."
		exit 198
}	

		if `threshold' <= 0 | `threshold' >= 1 {
			display as error "Error: Threshold must be between 0 and 1 (exclusive)."
			exit 198
		}
		
		if "`save'" != "" {
        putdocx clear
        putdocx begin
	    }
		
		   * Optional title
		   
        if "`title'" != "" {
            putdocx paragraph, style(Heading3)
            putdocx text ("`title'")
        }	
		
		if "`by'" == "" {		
	
        * We need a row count for the number of lines we will need in the table (with an additional line for the header row)
        local varcount : word count `num_vars'
        local rowcount = `varcount' + 1  

        * Populating the first row of the table
        putdocx table descriptors = (`rowcount', 9), layout(autofitcontents) border(start, nil) border(insideV, nil) border(insideH, nil) border(end, nil)
				
		putdocx table descriptors(1,.), border(bottom, double) 
		
        putdocx table descriptors(1, 1) = ("Variable")
        putdocx table descriptors(1, 2) = ("N")
        putdocx table descriptors(1, 3) = ("Mean")
        putdocx table descriptors(1, 4) = ("Median")
        putdocx table descriptors(1, 5) = ("Min")
        putdocx table descriptors(1, 6) = ("Max")
        putdocx table descriptors(1, 7) = ("% Min")
        putdocx table descriptors(1, 8) = ("% Max")
		putdocx table descriptors(1, 9) = ("Missing")

        local row = 1
	
        * Each line is for a particular variable
        foreach var of local num_vars {
            
            * Move to next line
            local ++row

            * Get the variable label, and if the label is empty, fall back to the variable name
            local varlabel : variable label `var'
            if "`varlabel'" == "" {
                local varlabel "`var'"
            }
			
			local varlabel_clean = subinstr(`"`varlabel'"', `"""', "", .)
			local varlabel `"`varlabel_clean'"'

            * Summarize statistics with the if condition (if provided)
            summarize `var' `if', detail
            
            local N = r(N)
            local mean = r(mean)
            local median = r(p50)
            local min = r(min)
            local max = r(max)
            local cond_min = "if `var' == `min'"
            local cond_max = "if `var' == `max'"

            * Adjust conditions for 'if' condition
            if "`if'" != "" {
                local cond_min = "`if' & `var' == `min'"
                local cond_max = "`if' & `var' == `max'"
            }

            * Count for min and max with the correct condition
            count `cond_min'
            local min_perc = (100 * r(N)) / `N'

            count `cond_max'
            local max_perc = (100 * r(N)) / `N'
			
			    * Now calculate missing values
			count `if'
			local total_obs = r(N)
			local missing = `total_obs' - `N'

            * Populate the table 
            putdocx table descriptors(`row', 1) = ("`varlabel'")
            putdocx table descriptors(`row', 2) = (`N')
            putdocx table descriptors(`row', 3) = (`mean'), nformat(%9.`decimals'f)
            putdocx table descriptors(`row', 4) = (`median'), nformat(%9.`decimals'f)
            putdocx table descriptors(`row', 5) = (`min'), nformat(%9.`decimals'f)
            putdocx table descriptors(`row', 6) = (`max'), nformat(%9.`decimals'f)
            putdocx table descriptors(`row', 7) = (`min_perc'), nformat(%9.`decimals'f)
            putdocx table descriptors(`row', 8) = (`max_perc'), nformat(%9.`decimals'f)
			putdocx table descriptors(`row', 9) = (`missing') 
        }
		
			putdocx table descriptors(.,.), font("`font'", `size')
			putdocx table descriptors(1,.), font(,, "`color'")
			putdocx table descriptors(1,.), bold


		}
		
		if "`by'" != "" {
			
	capture confirm numeric variable `by'
    if _rc != 0 {
        display as error "Error: The 'by' variable must be numeric."
        exit 198
    }
	
	levelsof `by', local(levels)
    local num_levels : word count `levels'
    if `num_levels' != 2 {
        display as error "Error: The 'by' variable must have exactly two unique values."
        exit 198
    }
	
	local value1 : word 1 of `levels'
	local value2 : word 2 of `levels'

    * We need a row count for the number of lines we will need in the table (with an additional line for the header row)
    local varcount : word count `num_vars'
    local rowcount = `varcount' + 1
	
	* Initialize the table with appropriate columns (now 8 columns)
	putdocx table descriptors = (`rowcount', 8), layout(autofitcontents) ///
		border(start, nil) border(insideV, nil) border(insideH, nil) border(end, nil)

	* Retrieve value labels for the 'by' variable
	local vlabel : value label `by'

	* Initialize labels for values 1 and 2
	local label1 "`value1'"
	local label2 "`value2'"

	* If the 'by' variable has value labels, get them
	if "`vlabel'" != "" {
		local label1 : label (`by') `value1'
		local label2 : label (`by') `value2'
	}

	* Populate the first row of the table with headers

	putdocx table descriptors(1,.), border(bottom, double) 
	
	putdocx table descriptors(1, 1) = ("Variable")
	putdocx table descriptors(1, 2) = ("N (`label1')")
	putdocx table descriptors(1, 3) = ("N (`label2')")
	putdocx table descriptors(1, 4) = ("Mean (`label1')")
	putdocx table descriptors(1, 5) = ("Mean (`label2')")
	putdocx table descriptors(1, 6) = ("Mean Diff")
	putdocx table descriptors(1, 7) = ("p-value")
	putdocx table descriptors(1, 8) = ("Significant?")
	
	local row = 1

    * Loop over each variable in the variable list
    foreach var of local num_vars {

        * Move to the next row in the table
        local ++row

        * Get the variable label, and if the label is empty, fall back to the variable name
        local varlabel : variable label `var'
        if "`varlabel'" == "" {
            local varlabel "`var'"
        }
		
		local varlabel_clean = subinstr(`"`varlabel'"', `"""', "", .)
		local varlabel `"`varlabel_clean'"'

        * Construct 'if' conditions for each group
        local if1 = "if `by' == `value1'"
        local if2 = "if `by' == `value2'"
        local ttest_if = ""

        if "`if'" != "" {
            local if1 = "`if' & `by' == `value1'"
            local if2 = "`if' & `by' == `value2'"
            local ttest_if = "`if'"
        }

        * Summarize statistics for group 1
        summarize `var' `if1', meanonly
        local N1 = r(N)
        local mean1 = r(mean)

        * Summarize statistics for group 2
        summarize `var' `if2', meanonly
        local N2 = r(N)
        local mean2 = r(mean)

        * Compute mean difference (mean2 - mean1)
        local meandiff = `mean2' - `mean1'

        * Perform t-test
        capture ttest `var' `ttest_if', by(`by') unequal
		
		if _rc != 0 {
            local pvalue = .
            local significance = "Error"
        }
		
				
		if _rc == 0 {
			local pvalue = r(p)
			
			
		if `pvalue' < `threshold' {
			local significance = "Yes"
		} 
		else {
			local significance = "No"
		}		
						
		}
		
        * Populate the table with computed statistics
        putdocx table descriptors(`row', 1) = ("`varlabel'")
        putdocx table descriptors(`row', 2) = (`N1')
        putdocx table descriptors(`row', 3) = (`N2')
        putdocx table descriptors(`row', 4) = (`mean1'), nformat(%9.`decimals'f)
        putdocx table descriptors(`row', 5) = (`mean2'), nformat(%9.`decimals'f)
        putdocx table descriptors(`row', 6) = (`meandiff'), nformat(%9.`decimals'f)
        putdocx table descriptors(`row', 7) = (`pvalue'), nformat(%9.2f)
        putdocx table descriptors(`row', 8) = ("`significance'")
		}
		
		putdocx table descriptors(.,.), font("`font'", `size')
		putdocx table descriptors(1,.), font(,, "`color'")
		putdocx table descriptors(1,.), bold
	}
	
	if "`save'" != "" {		
	noisily putdocx save "`save'.docx", replace		
	}
			
	if "`string_vars'" != "" {
	noisily display ""	
    noisily display "Ignored string variables include: `string_vars'"
}
	
	}
		
end

