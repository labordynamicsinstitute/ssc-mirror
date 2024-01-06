* Produces a table of baseline characteristics for publications, describing baseline characteristics
* Rafael Gafoor, rafael.gafoor@protonmail.com
*
*! -pretty_baseline- version 1.1 Rafael Gafoor 2023-12-07
*
* version history
* 2023-12-10 	v1.1 	Added optional formatting options
* 2023-07-10 	v1.0  	Initial Version


	capture program drop pretty_baseline
	program define pretty_baseline
	version 17.0
	syntax [if] [in] [fweight], ///
	by(varlist) ///
	[CONTNormal(varlist)] ///
	[CONTSkewed(varlist)] ///
	[CATEGorical(varlist)] ///
	[FCONT(string)] ///
	[FCATEG(string)] ///
	[TITLE(string)] ///
	[SAVing(string)] ///
	[POSition(string)] ///
	[REPLACE]
	
	

	
	************************************************
	** Setting up environment and clearing macros **
	************************************************
	putdocx clear
	collect clear
	marksample touse
	tempfile data
	qui save `data'
	
	
	********************************************
	** Generating macro for frequency weight **
	********************************************
	local weight "[`weight'`exp']"
	if "`weight'" == "[]"{
		local weight
	}



	
	********************************
	** Setting formats for output **
	********************************
	 if `:word count `fcont'' == 0{
	 	local fcont "%9.2fc"
	 }
	 
	 if `:word count `fcateg'' == 0{
	 	local fcateg "%9.2fc"
	 }
	

	
	*********************************************************************
	** Creating empty table if no variables defined except by variable **
	**********************************************************************

	if `:word count `contnormal'' == 0 & `:word count `contskewed'' == 0 & `:word count `categorical'' == 0 {
	
	
	
	qui table, stat(fvfrequency `by') stat(fvpercent `by')

	collect recode result `"fvfrequency"' = `"1"' `"fvpercent"' = `"2"'
	qui collect layout () (`by'#result[1 2])
	collect label levels result 1 "N" 2 "(%)", modify
	collect style cell result[2], nformat (`fcateg') sformat("(%s%%)")
	}
else{
	

	******************************************
	** Setting ordering of results in table **
	*******************************************
	
		if `:word count `contnormal'' != 0 & `: word count `position'' == 0 {
			local position2  "contn"
			}
		
		if `:word count `contskewed'' != 0 & `:word count `position'' == 0 {
			
			local position2 `position2' "conts"
		}
		
		
		if `:word count `categorical'' !=0 & `:word count `position'' ==0 {
			local position2 `position2' "categ"
		}
		
		if `:word count `position'' != 0 {
			local position2 
			local position2 `position'
		}


	
	
	*******************************************
	** Creating macros for the column headers**
	******************************************

	
	** Creating value lables if string variable
	    foreach var of local by {
        local has_label = ("`: value label `var''" != "")
        if `has_label' != 1 {
			qui drop if missing(`by')
           encode `var', gen(new`var')
		   drop `var'
		   rename new`var' `var'
        }
		}
		
	preserve
	
	cap qui keep if `touse'
	qui drop if missing(`by')
	


	qui levelsof `by', local(levels_by_var)
	global levels_by_var `levels_by_var'
	foreach i of numlist 1/ `:word count `levels_by_var''{
		local by_var_label_`:word 	`i' of $levels_by_var' "`:label `:value label `by'' `:word `i' of $levels_by_var''"
	}
	
	
	qui contract `by' `weight'	, freq(n) percent(p)
	gen label = "N = " +string(n , "%9.0fc") + " (" + string(p, "%9.1fc") + "%)"
	
	foreach i of numlist 1/`:word count `levels_by_var''{
	local by_label_`i' = label[`i']
	local new_by_label_`:word `i' of `levels_by_var''  `by_label_`i''
	local new_by_var_label_`:word 	`i' of $levels_by_var' `by_var_label_`i''
	}

	restore
	
	preserve
	cap qui keep if `touse'
	cap qui tab `by' `weight' if `by' !=.
	local total = string(`r(N)', "%9.0fc")
	restore
	
	***************************************************
	** Adding labels for  categorical data **
	**************************************************
	
	*****************
	** STRING DATA **
	*****************

	
	** Creating value lables if string variable  and not numeric for categorical variables
	    foreach var of local categorical {
			local has_label
			local is_string
        local has_label = ("`: value label `var''" != "")
	 ds `var', has(type string)
		local is_string `: word count `r(varlist)''
        if `has_label' == 0  & `is_string' >0{
           encode `var', gen(new`var')
		 drop `var'
		  rename new`var' `var'
		  replace `var' = 999 if `var' == .
		  label define `:value label `var'' 999 "Missing", modify
        }
		}
		
		
	** creating value labels if nominal variable with levels and a value label
	foreach var of local categorical {
		local is_numeric 
		local has_label
        local has_label = ("`: value label `var''" != "")
		qui ds `var', has(type numeric)
		local is_numeric = ("':  `r(varlist)''" != "")
        if `has_label' == 1  & `is_numeric' == 1{
            qui replace `var' = 999 if `var' == .
	 label define `:value label `var'' 999 "Missing", modify
		}
        }
		

		
	** Creating value lables if numeric  variable  and has no label
	    foreach var of local categorical {
		local is_numeric 
		local has_label
        local has_label = ("`: value label `var''" != "")
		qui ds `var', has(type numeric)
		local is_numeric = ("':  `r(varlist)''" != "")
        if `has_label' == 0  & `is_numeric' == 1{
		tostring `var', replace
		  replace `var' = "999" if `var' == "."
         encode `var', gen(new`var')
		 drop `var'
		  rename new`var' `var'
		  qui levelsof `var', local(cat_ord_levels)
		  local max `: word count `cat_ord_levels''
		  label define `:value label `var'' `max' "Missing", modify
		}
        }
	
	*****************************
	** CONTINUOUS NORMAL TABLE **
	*****************************
		foreach i of local position2 {
		 if "`i'" == "contn"  {

	preserve
	qui keep if `touse'
	
	** Creating table 		
	qui table (var) (`by') () `weight' , statistic(mean `contnormal') ///
						   statistic(sd `contnormal') ///
						   missing append
						   
	qui collect recode result `"mean"' = `"1"' ///
						  `"sd"' = `"2"' 
					  
	qui collect layout (var) (`by'#result[1 2])
	qui collect style cell result#colname[`contnormal'], nformat(`fcont')
	qui collect style cell result[2]#colname[`contnormal'], sformat("(%s)")
	
	restore
	
	local contnormal name2 `contnormal' empty
}
		 }
		 
		 
		 
	*****************************
	** CONTINUOUS SKEWED TABLE **
	*****************************

		foreach i of local position2 {
		 if "`i'" == "conts"  {
	
	preserve
	qui keep if `touse'
	
** Creating table 		
	qui table (var) (`by') () `weight', statistic(median `contskewed') ///
						   statistic(iqr `contskewed') ///
						   missing append
						   
	qui collect recode result `"median"' = `"1"' ///
						  `"iqr"' = `"2"' 
					  
	qui collect layout (var) (`by'#result[1 2])
	qui collect style cell result#colname[`contskewed'], nformat(`fcont')
	qui collect style cell result[2]#colname[`contskewed'], sformat("(%s)")
	
	restore
	
	local contskewed name3 `contskewed' empty
}
		}



	***********************
	** CATEGORICAL TABLE **
	***********************
	

	
		foreach i of local position2 {
		 if "`i'" == "categ"  {
	
	preserve
	cap qui keep if `touse'
	
** Creating table 		
	qui table (var) (`by') () `weight', statistic(fvfrequency `categorical') ///
						   statistic(fvpercent `categorical') ///
						   missing append
						   
	qui collect recode result `"fvfrequency"' = `"1"' ///
						  `"fvpercent"' = `"2"' 
					  
	qui collect layout (var) (`by'#result[1 2])
	qui collect style cell result[1]#colname[`categorical'], nformat(%9.0fc)
	qui collect style cell result[2]#colname[`categorical'], nformat(`fcateg')
	qui collect style cell result[2]#colname[`categorical'], sformat("(%s)")
	
	
	restore
	
	local categorical name1 `categorical' empty
}
		}


	*********************************************
	** Creating empty rows and column headings **
	**********************************************

	qui collect get _r_b1 = " ", tags(`by'[1] colname[empty])
	
	foreach i of global levels_by_var{
	qui collect get _r_b2 = "n", tags(`by'[`i'] colname[name1]) 
	qui collect get _r_b3 = "(%)", tags(`by'[`i'] colname[name1])
	qui collect get _r_b4 = "Mean", tags(`by'[`i'] colname[name2]) 
	qui collect get _r_b5 = "(sd)", tags(`by'[`i'] colname[name2])
	qui collect get _r_b6 = "Median", tags(`by'[`i'] colname[name3]) 
	qui collect get _r_b7 = "(IQR)", tags(`by'[`i'] colname[name3])
	}
	
	
	qui collect get _r_b2 = "n", tags(`by'[.m] colname[name1]) 
	qui collect get _r_b3 = "(%)", tags(`by'[.m] colname[name1])
	qui collect get _r_b4 = "Mean", tags(`by'[.m] colname[name2]) 
	qui collect get _r_b5 = "(sd)", tags(`by'[.m] colname[name2])
	qui collect get _r_b6 = "Median", tags(`by'[.m] colname[name3]) 
	qui collect get _r_b7 = "(IQR)", tags(`by'[.m] colname[name3])
	
	
	
	
	qui collect recode result `"_r_b2"' = `"1"' ///
							  `"_r_b3"' = `"2"' ///
							  `"_r_b4"' = `"1"' ///
							  `"_r_b5"' = `"2"'	///
							  `"_r_b6"' = `"1"' ///
							  `"_r_b7"' = `"2"'	///
							  `"_r_b1"' = `"1"' 

	***************************
	** Assembing Final Table **
	***************************

		
	foreach i of numlist 1/ `:word count `position2''{
	
	if `"`:word `i' of `position2''"' == "contn"{
		local colname2 `colname2' `contnormal'
	}
	
	else if `"`:word `i' of `position2''"' == "conts"{
		local colname2 `colname2' `contskewed'
	}
	
	else if `"`:word `i' of `position2''"' == "categ"{
		local colname2 `colname2' `categorical'
	}
	
}

	qui  collect layout (colname[`colname2']) (`by'#result[1 2])

	********************************
	** Formatting header or table **
	********************************
	
		foreach k of  global levels_by_var{
		qui collect label levels  `by' `k' "`by_var_label_`k'' `new_by_label_`k''", modify
	}
	
	qui collect label levels `by' .m "Total N =  `total' (100%)", modify
	qui collect style cell cell_type[column-header],  font(, size(11) bold)
	qui collect style cell colname[name1 name2 name3], font(, bold)
	qui collect style cell result[2], halign(left)
	
	****************************
	** Formatting Final Table **
	****************************
	qui collect style header colname[empty], level(hide)
	qui collect style header colname[name1], level(hide)
	qui collect style header colname[name2], level(hide) 
	qui collect style header colname[name3], level(hide)


	qui collect style row stack, nobinder indent
	qui collect style header result, level(hide)
 }
	******************
	** Adding title	**
	******************
	if `"`title'"' != "" {
		collect title "`title'"
	}
	
	***************************
	** Setting export format **
	***************************
	collect style putdocx, layout(autofitcontents)
	
	************************
	** Exporting document **
	************************
	
	
	if `"`saving'"' != "" {
		collect export "`saving'", as(docx) `replace'
	}
	
	*********************************
	** Displaying table on console **
	*********************************
	collect preview
	
	*********************************
	** Replacing original dataset **
	********************************
	
	qui use `data', clear
	
	******************
	** Cleaning up 	**
	******************
	macro drop location name_table con_row cat_row by_var data by_label_1 ///
	by_label_2 levels_by_var 
	


	end
	

	