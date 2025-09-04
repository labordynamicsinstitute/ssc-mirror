*! fencode v1.1 - Frequency-based encoding for Stata
*! Encodes a variable with numeric codes ordered by frequency
*! Default (descending): Most frequent category = 1, second most frequent = 2, etc.
*! With ascending option: Least frequent category = 1, second least frequent = 2, etc.

program define fencode
    version 14
    syntax varname, [GENerate(name)] [ASCending]
    
    // Set default name if generate not specified
    if "`generate'" == "" {
        local generate "`varlist'_fencode"
    }
    
    quietly {
        // Handle both string and numeric (encoded) variables
        tempvar working_var
        capture confirm string variable `varlist'
        if _rc {
            // Numeric: require a value label, then decode
            local vl : value label `varlist'
            if "`vl'" == "" {
                noisily di as err "`varlist' is numeric without a value label. Please attach a label or pass a string variable."
                exit 459
            }
            decode `varlist', gen(`working_var')
        }
        else {
            // String: make a working copy
            gen `working_var' = `varlist'
        }
        
        // Normalize whitespace so trailing or double spaces do not split categories
        replace `working_var' = stritrim(strtrim(`working_var'))
        
        tempfile map
        tempvar mapvar  // used only in the mapping merge
        
        // Build a compact mapping of distinct categories -> rank and prefixed string
        preserve
            keep `working_var'
            drop if missing(`working_var')        // exclude missings from frequency ranking
            contract `working_var', freq(freq)
			
			        // Modified sort based on option
        if "`ascending'" != "" {
            gsort freq `working_var'      // Ascending: least frequent = 1 with ties broken alphabetically by `working_var'
        }
        else {
            gsort -freq `working_var'     // Descending (default): most frequent = 1
        }
            gen long rank = _n
            gen `mapvar' = string(rank, "%03.0f") + "_" + `working_var'
            keep `working_var' `mapvar'
            save `map'
        restore
        
        // Merge the mapping back without changing row order
        merge m:1 `working_var' using `map', nogen keep(master match) keepusing(`mapvar')
        
        // Encode using the prefixed string
        encode `mapvar', gen(`generate')
        
        // Strip the "001_" prefix from value labels
        local vl : value label `generate'
        levelsof `generate', local(codes)
        foreach c of local codes {
            local cur   : label `vl' `c'
			local clean = substr("`cur'", 5, length("`cur'")-4)
            label define `vl' `c' "`clean'", modify
        }
        
        // Copy the original variable label if present
        local varlabel : variable label `varlist'
        if "`varlabel'" != "" label var `generate' "`varlabel'"
        
        drop `mapvar' `working_var'
        
        // Get category count for reporting
        tab `generate'
        local ncat = r(r)
    }
	
	    
    // Report results
    display as text "Encoded variable " as result "`generate'" as text " created with " as result "`ncat'" as text " categories"
	
	local order = cond("`ascending'" != "", "ascending", "descending")
	display as text "Categories ordered by frequency (`order'), ties (if any) broken alphabetically"
end
