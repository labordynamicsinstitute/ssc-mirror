*! 1.0.0 KNK 31 July 2025

program define sumbar
  version 12.0
  syntax varlist [if] [in], ///
	[By(varname)] ///
	[Title(string)] ///
	[Percent] ///
	[n] ///
	[TOtal] ///
	[KEEPmiss] ///
	[REcast(string)] ///
	[SOrt] ///
	[SAving(string)] ///
	[Intensity(integer 50)] ///
	[OVERopts(string asis)] ///
	[BLABELopts(string asis)] ///
	[LEGENDopts(string asis)] ///
	[GRAPHopts(string asis)] 
 
  qui {
  
  ************************************************************
  /*
  SECTION 0: RESOLVE VARLIST AND VALIDATE INPUTS
  
  Lock in the exact variable list order and validate inputs
  before any data operations
  */
  ************************************************************
  
  // Validate all variables exist before other checks
	foreach var of local varlist {
    capture confirm variable `var'
    if _rc {
        di as error "Variable `var' not found"
        exit 111
    }
}
  
  unab varlist : `varlist'    // Fully resolve and lock in the varlist
  local nvars : word count `varlist'
  
  * Check that varlist contains only numeric variables
  ds `varlist', has(type string)
  local string_vars `r(varlist)'
  if "`string_vars'" != "" {
      di as error "String variables not allowed in varlist: `string_vars'"
      di as error "sumbar calculates sums and so, only numeric variables are valid"
      exit 198
  }
  
  ************************************************************
  /*
  SECTION 1: PRESERVE DATA AND APPLY CONDITIONS
  
  Use preserve/restore for clean data handling and check for
  empty results after applying if/in conditions
  */
  ************************************************************
  
  * Preserve original data - will automatically restore on any exit
  preserve
     
  * Sample indicator for mapping the [IF] [IN] conditions
  if "`keepmiss'" != "" {
    marksample touse, strok novarlist
}
else {
    marksample touse, strok
}
  
  * For category breakdown, exclude observations with missing by() variable (for accurate N calculations)
  if "`by'" != "" & "`keepmiss'" == "" {
  replace `touse' = 0 if missing(`by')
  }
  
  keep if `touse' == 1
  
  * Check if any observations remain after if/in conditions
  count
  if r(N) == 0 {
      di as error "No observations remain after applying if/in conditions"
      exit 2000
  }
  
  
  if "`by'" != "" {
    // Save reference to original by variable
    local original_by "`by'"
    
    capture confirm string variable `by'
    if !_rc {
        // String variable - encode it
        tempvar by_encoded
        encode `by', gen(`by_encoded')
        local by "`by_encoded'"
    }
    else {
        // Numeric variable - must have value labels
        local vallbl : value label `by'
        if "`vallbl'" == "" {
            di as error "Numeric by() variable must have value labels attached"
            di as error "Either use a string variable or attach value labels to `original_by'"
            exit 198
        }
        
        // Has labels - use decode/encode to preserve them
        tempvar by_sequential  
		tempvar temp_decoded
		decode `by', gen(`temp_decoded')
        encode `temp_decoded', gen(`by_sequential')
        local by "`by_sequential'"
    }
    
    	if "`keepmiss'" != "" {
    // Check if original by variable had missing values that were kept
    count if missing(`original_by') 
    if r(N) > 0 {
        // Get the highest category number
        qui levelsof `by', local(levels)
        local max_level : word count `levels'
        local missing_code = `max_level' + 1
        
        // Assign missing values to new category
        replace `by' = `missing_code' if missing(`original_by')
        
        // Add label for missing category
        local vallbl : value label `by'
        if "`vallbl'" != "" {
            label define `vallbl' `missing_code' "Missing", add
        }
    }
}
}
     
  * Set graph command based on recast option
  local graphcmd = cond("`recast'" != "", "graph `recast'", "graph bar")
  
  * Set default title if not specified
  if "`title'" == "" {
      local title = cond("`percent'" != "", "Percentage Distribution", "Totals")
  }
  
  * Set sort option for graph command
  if "`sort'" != "" {
      local sort "sort(1) descending"
  }
  
  * Set up saving option with PNG default
  if "`saving'" != "" {
      * Check if filename has an extension
      if strpos("`saving'", ".") == 0 {
          local saving "`saving'.png"
      }
  }
  
  ************************************************************
  /*
  SECTION 2: COMMON CALCULATIONS
  
  Calculate totals, counts, and labels that are needed regardless
  of whether by() is specified. The touse filtering from Section 1 
  ensures we're working with the correct observations for each case.
  */
  ************************************************************
  
  * Set up common formatting with user-controlled decimals
  local ytitle = cond("`percent'" != "", "Percentage", "Total")
  local graph_decimal = cond("`percent'" != "", "%11.1f", "%11.0fc")
  local yaxis_format =  cond("`percent'" != "", "", "ylabel(, format(%15.0fc))")
  
  * Count observations per variable 
  local varying_n = 0
  if "`n'" != "" {
      forval i = 1/`nvars' {
          local thisvar : word `i' of `varlist'
          count if !missing(`thisvar')
          local n_`i' = r(N)
          
          * Check if N varies (compare to first variable)
          if `i' > 1 & `n_`i'' != `n_1' {
              local varying_n = 1
          }
      }
  }
  
  * Calculate overall total 
  local grand_total = 0
  forval i = 1/`nvars' {
      local thisvar : word `i' of `varlist'
      sum `thisvar'
      local grand_total = `grand_total' + r(sum)
  }
  
  * Build all variable labels with fallback and n annotations
  forval i = 1/`nvars' {
      local thisvar : word `i' of `varlist'
      local varlabel`i' : variable label `thisvar'
      if "`varlabel`i''" == "" {
          local varlabel`i' "`thisvar'"  // Use variable name as fallback
      }
      
      * Add n to individual labels if n varies across variables
      if "`n'" != "" & `varying_n' == 1 {
          local varlabel`i' "`varlabel`i'' (n = `n_`i'')"
      }
  }
  
  * Build subtitle combining N and grand total info
  local subtitle ""
  local sub_parts ""
  
  * Only add N to subtitle if it's constant across variables
  if "`n'" != "" & `varying_n' == 0 {
      local sub_parts "N = `n_1'"
  }
  
  if "`total'" != "" {
      local gt_formatted : di %15.0fc `grand_total'
      local gt_formatted = trim("`gt_formatted'")
      if "`sub_parts'" != "" {
          local sub_parts "`sub_parts', Overall total = `gt_formatted'"
      }
      else {
          local sub_parts "Overall total = `gt_formatted'"
      }
  }
  
  if "`sub_parts'" != "" {
      local subtitle `"subtitle("`sub_parts'", size(small))"'
  }
  
    local common_opts `"title("`title'", size(medsmall)) `subtitle' ytitle("`ytitle'") `yaxis_format' blabel(bar, format(`graph_decimal')) blabel(bar, `blabelopts') legend(pos(6) row(1)) legend(`legendopts') intensity(`intensity') `graphopts'"'  
   
  ************************************************************
  /*
  SECTION 3: HANDLE CATEGORY BREAKDOWN (when by() is specified)
  */
  ************************************************************
  
  if "`by'" != "" {
      
      ************************************************************
      /*
      Step 3A: Store category labels before data manipulation
      
      Extract category labels before we clear the dataset
      because once we reshape/clear, we lose access to original labels
      */
      ************************************************************
      
      levelsof `by', local(byvals_numeric)  	// Get numeric category codes (1,2,3...)
      
      * Store category labels (e.g., "Urban", "Rural" for codes 1, 2)
      local category_labels ""
      foreach val of local byvals_numeric {
          local catlab : label (`by') `val'  // Get string label for numeric code
          local category_labels "`category_labels' `val' "`catlab'""
      }
      
      * Store variable labels for x-axis using labels built in Section 2
      local order_labels ""
      forval i = 1/`nvars' {
          local order_labels "`order_labels' `i' "`varlabel`i''""
      }
      
      ************************************************************
      /*
      Step 3B: Calculate sums for each variable x category combination
      
      For each variable (G1, G2, etc.) and each category (Urban, Rural),
      calculate the sum and store it in a local macro
      Format: sum_1_1 = G1 Urban, sum_1_2 = G1 Rural, etc.
      Using positional indexing and the grand_total from Section 2
      */
      ************************************************************
      
      forval i = 1/`nvars' {
          local thisvar : word `i' of `varlist'
          foreach val of local byvals_numeric {
              sum `thisvar' if `by' == `val'
              local sum_`i'_`val' = r(sum)
              
              * Convert to percentage if requested
              if "`percent'" != "" {
                  local sum_`i'_`val' = (`sum_`i'_`val'' / `grand_total') * 100
              }
          }
      }
      
      ************************************************************
      /*
      Step 3C: Create new dataset structure for graphing
      
      Clear current data and create a structure that graph bar can use:
      - One row per variable (G1, G2, G3, etc.)
      - One column per category (total_cat1, total_cat2, etc.)
      */
      ************************************************************
      
      clear                              
      set obs `nvars'                    // One row per variable
      gen order = _n                     // Order variable (1, 2, 3, ...)
      
      * Create one column for each category
      foreach val of local byvals_numeric {
          gen total_cat`val' = .
      }
      
      * Fill in the calculated values using positional indexing
      forval i = 1/`nvars' {
          foreach val of local byvals_numeric {
              replace total_cat`val' = `sum_`i'_`val'' in `i'
          }
      }
      
      ************************************************************
      /*
      Step 3D: Reshape for graphing and create chart
      
      Reshape from wide to long format:
      Before: total_cat1, total_cat2, total_cat3
      After: total_cat (values), category (1,2,3)
      This is the format that graph bar needs for colored bars
      */
      ************************************************************
      
      reshape long total_cat, i(order) j(category)
      
      * Create the graph with proper labeling and legend positioning
      `graphcmd' total_cat, ///
          over(category, relabel(`category_labels')) ///
          over(order, `sort' relabel(`order_labels') `overopts') ///
          asyvars `common_opts'
      
      * Save graph if requested
      if "`saving'" != "" {
          graph export "`saving'", replace
      }
  }
  
  ************************************************************
  /*
  SECTION 4: HANDLE SIMPLE CASE (no by() variable specified)
  */
  ************************************************************
  
  if "`by'" == "" {
      
      ************************************************************
      /*
      Step 4A: Calculate sums and build label string
      
      For the simple case, we sum each variable and create
      the relabel string using the labels built in Section 2
      */
      ************************************************************
      
      local label_string ""
      
      * Calculate sums and build label string using pre-built labels and grand_total
      forval i = 1/`nvars' {
          local thisvar : word `i' of `varlist'
          sum `thisvar'                              
          local val`i' = r(sum)
          
          * Convert to percentage if requested
          if "`percent'" != "" {
              local val`i' = (`val`i'' / `grand_total') * 100
          }
          
          * Build the relabel string using pre-built labels from Section 2
          local label_string "`label_string' `i' "`varlabel`i''""
      }
      
      ************************************************************
      /*
      Step 4B: Create simple dataset and graph
      */
      ************************************************************
      
      clear
      set obs `nvars'          // One row per variable
      gen total = .            // Column for the sums
      gen order = _n           // Order variable (1, 2, 3, ...)
      
      * Fill in the calculated sums using positional indexing
      forval i = 1/`nvars' {
          replace total = `val`i'' in `i'   
      }
      
      `graphcmd' total, over(order, `sort' relabel(`label_string') `overopts') `common_opts'
      
      * Save graph if requested
      if "`saving'" != "" {
          graph export "`saving'", replace
      }
  }
  
  ************************************************************
  /*
  SECTION 5: AUTOMATIC DATA RESTORATION
  
  The preserve command at the beginning automatically restores
  the original dataset when the program ends (successfully or with error)
  */
  ************************************************************
  
  restore
  
  }
    
end
