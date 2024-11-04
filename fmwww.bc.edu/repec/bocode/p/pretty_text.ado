
************
** SET-UP **
************

	capture program drop pretty_text
	version 18.5
	program define pretty_text
    syntax [if], ///
	STRING_variables(varlist) ///
	[by(varlist)] ///
	[SAVing(string)]

	marksample touse
	tempfile data
	qui save `data'
	qui use `data', clear
	qui keep if `touse'
	
****************************
** REMOVE NON-STRING VARS **
****************************

	** Error if string variable not string
	qui ds `string_variables', not(type string)
	
	if "`r(varlist)'" != "" {
		
		display as error "string_variable is not in string format."
		exit 198	
			
	}
	
	** Convert grouping variable to string if neccessary
	qui ds `by', not(type string)
	
	qui if "`r(varlist)'" != "" {
		
		local numeric `r(varlist)'
		
		foreach v of local numeric {
			
			rename `v' `v'_num

			decode `v'_num, gen(`v')

			drop `v'_num
			
		}
			
	}
	 

 **********************************
 ** ORDER AND SORT BY GROUP VARS ** 
 **********************************
 
   qui if "`by'" != "" {
        
		foreach var of local by {
           
			local i = `i' + 1
            local j = `i' - 1
			
            levelsof `var', local(sort`i')
			
            if `i' == 1 {
                local sorted_group_var `var'
            }
            
			** Order grouping vars by number of levels ** 
			else if ///
			`:word count `sort`i''' < `: word count `sort`j''' {
                
				local sorted_group_var `var' `sorted_group_var'
            
			}
			
            else {
                
				local sorted_group_var `sorted_group_var' `var'
            
			}
        
		}
	
        sort `sorted_group_var'
		
    }

***********************************
** CALCULATE DIMENSIONS OF TABLE **
***********************************
	
	** Number of Columns ** 
    local ncols = wordcount("`sorted_group_var' `string_variables'")

    ** Number of Rows ** 
    local nrows = `=_N' + 1

    ** Create word document if saving ** 
	qui if "`saving'" != "" {
	putdocx clear
    putdocx begin
	}
	
	** Put table in **
    putdocx table tbl1 = (`nrows', `ncols'), border(insideH, nil) cellmargin(top, 0.1) cellmargin(bottom, 0.1) 

	
********************
** INPUTTING DATA ** 
********************

	** Header row **
    local col = 1
	
    qui if "`by'" != "" {
        foreach var of varlist `sorted_group_var' {
			
			if "`: var l `var''" == "" {
			
				label var `var' "`var'"

			}
			
            putdocx table tbl1(1, `col') = ("`: var l `var''")
			
			putdocx table tbl1(1, `col'), bold border(all, single)
			
            local col = `col' + 1
        }
    }

    foreach var of varlist `string_variables' {
		
		if "`: var l `var''" == "" {
			
				label var `var' "`var'"

		}
		
        putdocx table tbl1(1, `col') = ("`: var l `var''")
		
		putdocx table tbl1(1, `col'), bold border(all, single)
		
        local col = `col' + 1
		
    }


    
	** Inputting Grouping Columns ** 
	qui forvalues k = 1/`:word count `sorted_group_var'' {
    forvalues l = 2/`nrows' {
		
		local m = `l' - 1
		
		local group`k'_level`l' = `:word `k' of `sorted_group_var''[`m']
		
		if `k' == 1 {
		if "`group`k'_level`l''" != "`group`k'_level`m''" {
			
		putdocx table tbl1(`l', `k') = ("- `group`k'_level`l''"), bold
		putdocx table tbl1(`l', .), border(top, single) 
		
		}
		}
		
		else {
			local n = `k' - 1
			
			if "`group`n'_level`l''" != "`group`n'_level`m''" {
				
				putdocx table tbl1(`l', `k') = ("- `group`k'_level`l''"), bold
				putdocx table tbl1(`l', .), border(top, single) 
			}
		
			else if "`group`k'_level`l''" != "`group`k'_level`m''" {
			
				putdocx table tbl1(`l', `k') = ( "- `group`k'_level`l''"), bold 
				putdocx table tbl1(`l', .), border(top, single) 
		
			}		
				
			}
			
			
		}
    }   
        
        ** Inputting other string columns ** 
        local string_col = wordcount("`sorted_group_var'") + 1
		
       qui foreach var of varlist `string_variables' {
			forvalues o = 2/`nrows' {
				local p = `o' - 1
				local value = `var'[`p']
				putdocx table tbl1(`o', `string_col') = ("`value'")
        }
		local string_col = `string_col' + 1
    }

 
****************
** FORMATTING **
****************
 
	** Removing horizontal lines ** 
	
	
	** Adjusting height of cells ** 
 
 
 
*****************
** CLEANING UP ** 
*****************

	** Saving if specified ** 
	if "`saving'" != "" {
    putdocx save `saving'.docx, replace
	}
	
	** Replacing Dataset
	qui use `data', clear
	
end



