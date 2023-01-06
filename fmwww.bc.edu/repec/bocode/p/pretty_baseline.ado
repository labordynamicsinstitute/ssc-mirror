*********************************************************************************
*********************************************************************************
	cap program drop pretty_baseline
	program define pretty_baseline
	version 17.0
	syntax  , title(string) name(string) by(string) [CONTinuous(string) CATEGorical(string)]
	putdocx clear
	collect clear
	preserve
	
	if `: word count `title'' == 0 {
		local title "Table"
	}
		
	if `: word count `name'' == 0 {
		local name "Table"
		
	}
	
	
** Getting macros for the column headers
	qui levelsof `by', local(levels_by_var)
	global levels_by_var `levels_by_var'
	foreach i of numlist 1/ `:word count `levels_by_var''{
		local by_var_label_`:word 	`i' of $levels_by_var' "`:label `:value label `by'' `:word `i' of $levels_by_var''"
	}
	
	
	qui contract `by', freq(n) percent(p)
	gen label = "N = " +string(n , "%9.0fc") + " (" + string(p, "%9.1fc") + "%)"
	
	foreach i of numlist 1/`:word count `levels_by_var''{
	local by_label_`i' = label[`i']
	local new_by_label_`:word `i' of `levels_by_var''  `by_label_`i''
	local new_by_var_label_`:word 	`i' of $levels_by_var' `by_var_label_`i''
	}

	restore
	
	qui count if `by' !=.
	local total = string(`r(N)', "%9.0fc")
	

**********************************************************
** TABLE WITH BOTH CATEGORICAL AND CONTINUOUS VARIABLES **
**********************************************************	
	if `:word count `categorical'' != 0 & `:word count `continuous'' != 0 {
	display in red "CATEGORICAL AND CONTINUOUS VARIABLES"
	
	preserve
	
	
	
** Adding labels for missing values
	foreach i of global cat_row{
		qui replace `i' = 999 if `i' == .
	** Labelling variables with no value label
		qui ds, not(vallabel)
		local list `r(varlist)'
		foreach item of global cat_row{
			if strpos("`list'", "`item'") {
			label define label_`i' 999 "Missing"
			label values `i' label_`i'	
			}
			else {
				label define `:value label `i'' 999 "Missing", modify
			}
		}
		}
	
	
	
** Creating table 		
	qui table (var) (`by') (), statistic(fvfrequency `categorical') ///
                           statistic(fvpercent `categorical') ///
						   statistic(mean `continuous') ///
						   statistic(sd `continuous') ///
						   missing name(Table_1) 
						   
						   
	qui collect recode result `"mean"' = `"1"' ///
						  `"sd"' = `"2"' ///
						  `"fvfrequency"' = `"1"' ///
						  `"fvpercent"' = `"2"'
					  
	qui collect layout (var) (`by'#result[1 2])
	
** Creating empty rows and column headings

	collect get _r_b1 = " ", tags(`by'[1] colname[empty])
	
	foreach i of global levels_by_var{
	collect get _r_b2 = "n", tags(`by'[`i'] colname[name1]) 
	collect get _r_b3 = "(%)", tags(`by'[`i'] colname[name1])
	collect get _r_b4 = "Mean", tags(`by'[`i'] colname[name2]) 
	collect get _r_b5 = "(sd)", tags(`by'[`i'] colname[name2])
	}
	
	
	
	collect get _r_b2 = "n", tags(`by'[.m] colname[name1])
	collect get _r_b3 = "(%)", tags(`by'[.m] colname[name1])
	collect get _r_b4 = "Mean", tags(`by'[.m] colname[name2])
	collect get _r_b5 = "(sd)", tags(`by'[.m] colname[name2])
	
	qui collect recode result `"_r_b2"' = `"1"' ///
							  `"_r_b3"' = `"2"' ///
							  `"_r_b4"' = `"1"' ///
							  `"_r_b5"' = `"2"'	///
							  `"_r_b1"' = `"1"'

	qui collect layout (colname[ name1 `categorical' empty name2 `continuous']) (`by'#result[1 2])

	collect style header colname[empty], level(hide)
	collect style header colname[name1], level(hide)
	collect style header colname[name2], level(hide) 


	collect style row stack, nobinder indent
	collect style header result, level(hide)



	foreach k of  global levels_by_var{
		collect label levels  `by' `k' "`by_var_label_`k'' `new_by_label_`k''"
	}
	
	collect label levels `by' .m "Total N = `total' (100%)", modify 
	collect style cell cell_type[column-header] /*#`by'[.m]#`by'[0]#`by'[1]*/,  font(, size(9) bold)
	collect style cell colname[name1 name2], font(, bold)
	collect style cell result[2], halign(left)
	

	collect style cell result[2]#colname[`categorical'], nformat(%9.1fc) sformat("(%s%%)")
	
	
	collect style cell result#colname[`continuous'], nformat(%9.2fc)
	collect style cell result[2]#colname[`continuous'], sformat("(%s)")
	
	collect style putdocx, layout(autofitcontents)
	restore
}

*********************************************************************
** TABLE WITH ONLY CATEGORICAL VALUES **
**********************************************************************
else if `: word count `categorical'' !=0 & `:word count `continuous'' == 0 {
	display in red "CATEGORICAL ONLY VARIABLES"
	preserve
	
	
	
** Adding labels for missing values
	foreach i of global cat_row{
		qui replace `i' = 999 if `i' == .
		
	** Labelling variables with no value label
		qui ds, not(vallabel)
		local list `r(varlist)'
		foreach item of global cat_row{
			if strpos("`list'", "`item'") {
			label define label_`i' 999 "Missing"
			label values `i' label_`i'	
			}
			else {
				label define `:value label `i'' 999 "Missing", modify
			}
		}
		}
	
	
	
** Creating table 		
	qui table (var) (`by') (), statistic(fvfrequency `categorical') ///
                           statistic(fvpercent `categorical') ///
						   missing name(Table_1) 
						   
						   
	qui collect recode result `"fvfrequency"' = `"1"' ///
						  `"fvpercent"' = `"2"'
					  
	qui collect layout (var) (`by'#result[1 2])
	
** Creating empty rows and column headings
	
	foreach i of global levels_by_var{
	collect get _r_b2 = "n", tags(`by'[`i'] colname[name1]) 
	collect get _r_b3 = "(%)", tags(`by'[`i'] colname[name1])
	}
	
	
	
	collect get _r_b2 = "n", tags(`by'[.m] colname[name1])
	collect get _r_b3 = "(%)", tags(`by'[.m] colname[name1])
	
	
	qui collect recode result `"_r_b2"' = `"1"' ///
							  `"_r_b3"' = `"2"' ///
							 /* `"_r_b1"' = `"1"' */

	qui collect layout (colname[name1 `categorical']) (`by'#result[1 2])

	collect style header colname[empty], level(hide)
	collect style header colname[name1], level(hide)
	collect style header colname[name2], level(hide) 



	collect style row stack, nobinder indent
	collect style header result, level(hide)



	foreach k of  global levels_by_var{
		collect label levels  `by' `k' "`by_var_label_`k'' `new_by_label_`k''", modify
	}
	
	collect label levels `by' .m "Total N = `total' (100%)", modify
	collect style cell cell_type[column-header]/*#`by'[.m]#`by'[0]#`by'[1]*/,  font(, size(9) bold)
	collect style cell colname[name1 name2], font(, bold)
	collect style cell result[2], halign(left)
	

	collect style cell result[2]#colname[`categorical'], nformat(%9.1fc) sformat("(%s%%)")
	
	collect style putdocx, layout(autofitcontents)
	
	
	restore
}



**********************************************************
** TABLE WITH ONLY CONTINUOUS VARIABLES **
**********************************************************	
	else {
	display in red "CONTINUOUS ONLY VARIABLES"

	preserve
	
	
	
** Adding labels for missing values
	foreach i of global cat_row{
		qui replace `i' = 999 if `i' == .
	** Labelling variables with no value label
		qui ds, not(vallabel)
		local list `r(varlist)'
		foreach item of global cat_row{
			if strpos("`list'", "`item'") {
			label define label_`i' 999 "Missing"
			label values `i' label_`i'	
			}
			else {
				label define `:value label `i'' 999 "Missing", modify
			}
		}
		}
	
	
	
** Creating table 		
	qui table (var) (`by') (), statistic(mean `continuous') ///
						   statistic(sd `continuous') ///
						   missing name(Table_1) 
						   
						   
	qui collect recode result `"mean"' = `"1"' ///
						  `"sd"' = `"2"' 
					  
	qui collect layout (var) (`by'#result[1 2])
	
** Creating empty rows and column headings

	collect get _r_b1 = " ", tags(`by'[1] colname[empty])
	
	foreach i of global levels_by_var{
	collect get _r_b4 = "Mean", tags(`by'[`i'] colname[name2]) 
	collect get _r_b5 = "sd", tags(`by'[`i'] colname[name2])
	}
	
	
	collect get _r_b4 = "Mean", tags(`by'[.m] colname[name2])
	collect get _r_b5 = "sd", tags(`by'[.m] colname[name2])
	
	qui collect recode result `"_r_b4"' = `"1"' ///
							  `"_r_b5"' = `"2"'	///
							  `"_r_b1"' = `"1"'

	qui collect layout (colname[name2 `continuous']) (`by'#result[1 2])

	collect style header colname[empty], level(hide)
	collect style header colname[name1], level(hide)
	collect style header colname[name2], level(hide) 


	collect style row stack, nobinder indent
	collect style header result, level(hide)



	foreach k of  global levels_by_var{
		collect label levels  `by' `k' "`by_var_label_`k'' `new_by_label_`k''", modify
	}
	
	collect label levels `by' .m "Total N = `total' (100%)", modify
	collect style cell cell_type[column-header] /*#`by'[.m]#`by'[0]#`by'[1]*/,  font(, size(9) bold)
	collect style cell colname[name1 name2], font(, bold)
	collect style cell result[2], halign(left)
	

	collect style cell result[2]#colname[`categorical'], nformat(%9.1fc) sformat("(%s)")
	
	
	collect style cell result#colname[`continuous'], nformat(%9.2fc)
	collect style cell result[2]#colname[`continuous'], sformat("(%s)")
	
	collect style putdocx, layout(autofitcontents)
	
	
	restore
	
}


	collect title `name'
	collect preview
	collect	 export "`title'", as(docx) replace
	macro drop location name_table con_row cat_row by_var data by_label_1 ///
	by_label_2 levels_by_var 
	end
	
	
