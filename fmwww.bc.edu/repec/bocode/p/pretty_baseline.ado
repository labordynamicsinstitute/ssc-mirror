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
	[by(varlist)] ///
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
	collect clear
	marksample touse
	tempfile data
	qui save `data'
	
	capture drop pretty_replacement_by 
	capture label drop prettybylabel
	capture drop pretty_replacement_by

	if "`saving'" != "" {
	putdocx clear
	}
	
	
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

	**********************************
	** If no by variable is defined **
	**********************************
	

	if `:word count `by'' == 0 {
		local no_by = 1 
		gen pretty_replacement_by = 1
		local by pretty_replacement_by
	}
	
	else {
		local no_by = 0
	}
	
	if "`: value label `by''" == "" {
		label define prettynobylabel 0 "0" 1 "1", replace
		label value `by' prettynobylabel
	}
	
		
	****************************
	** Recoding by if not 0/1 **
	****************************
	qui levelsof(`by'), local(levelcheck)
	
	qui tab `by'
	
	local number_of_levels = r(r)
	
	forvalues i = 0/`number_of_levels' {
		
		capture drop label`i'
	
	}
	
	
	local vlname: value label `by'
	
		
	if "`vlname'" != "" {
		
	foreach level of local levelcheck{
	local m = `m' + 1
	local vl`m':label `vlname' `level'
	}
	
	}

		
	foreach level of local levelcheck {
	local begin = `begin' + 1
		
		if `begin' == 1 {
		qui recode `by' (`level' = 0)
		}
	
		else {
		local levelnumber = `levelnumber' + 1
		qui recode `by' (`level' = `levelnumber') 
		}
		
	}
	
	
	qui levelsof `by', local(levelfinal)
	************************************
	** Collecting value labels for by ** 
	************************************	
	if "`vlname'" != "" {
		
	label define prettybylabel 0 "`vl1'" 1 "`vl2'"
	label values `by' prettybylabel
	
	}

	
	*******************************************
	** Creating macros for the column headers**
	******************************************

	** Creating value lables if string variable
	    qui foreach var of local by {
        local has_label = ("`: value label `var''" != "") 
		local not_string = ("`: type `var''" != "str")
        if `has_label' != 1 & `not_string' != 1 {
			qui drop if missing(`by')
           encode `var', gen(new`var')
		   drop `var'
		   rename new`var' `var'
        }
		qui else if `has_label' != 1 & `not_string' == 1 {
		tostring `var', replace
		encode `var', gen(new`var')
			drop `var'
			rename new`var' `var'
			qui levelsof `var', local(cat_ord_levels)	
		}
		}
	
	preserve
	cap qui keep if `touse'
	qui drop if missing(`by')

	qui levelsof `by', local(levels_by_var)
	global levels_by_var `levels_by_var'
	
	if `no_by' == 0 {
	qui contract `by' `weight'	, freq(n) percent(p)
	gen label = "N = " +string(n , "%9.0fc") + " (" + string(p, "%9.1fc") + "%)"

	
	qui foreach var of local levels_by_var {
		local v = `v' + 1 
		local vlname: value label `by'
		local bylevel`v': label `vlname' `var'		
	}
	}

	else {
	qui contract `by' `weight', freq(n) percent(p)
	gen label = "N = " +string(n , "%9.0fc") + " (" + string(p, "%9.1fc") + "%)"
	
	local no_total = label
	
	}
	restore
	
	
	preserve
	cap qui keep if `touse'
	cap qui tab `by' `weight' if `by' !=.
	local total = string(`r(N)', "%9.0fc")
	restore

	local n = r(N)
	
	
	
	forvalues i = 0/`number_of_levels' {
		
		qui count if `by' == `i'
		local n`i' = r(N)
		local p`i' = (`n`i''/`n')*100
		
		gen label`i' = ///
		"N = " +string(`n`i'' , "%9.0fc") ///
		+ " (" + string(`p`i'', "%9.1fc") + "%)"
		
		local label`i' = label`i'
	

	}
	
	/*qui count if `by' == 1
	local n2 = r(N)
	local p2 = (`n2'/`n')*100
	
	gen label2 = "N = " +string(`n2', "%9.0fc") + " (" + string(`p2', "%9.1fc") + "%)"
	local label2 = label2*/
	
	***************************************************
	** Adding labels for  categorical data **
	**************************************************
	
	*****************
	** STRING DATA **
	*****************

	
	** Creating value lables if string variable  and not numeric for categorical variables
	qui foreach var of local categorical {
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
	qui foreach var of local categorical {
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
	    qui foreach var of local categorical {
		local is_numeric 
		local has_label
        local has_label = ("`: value label `var''" != "")
		qui ds `var', has(type numeric)
		local is_numeric = ("':  `r(varlist)''" != "")
        if `has_label' == 0  & `is_numeric' == 1{
		replace `var' = 999 if `var' == . 
		levelsof `var', local(levelsof`var')
		foreach l of local levelsof`var' {
		local nolabel = `nolabel' + 1
		label define prettycategorical`nolabel' `l' "`l'" 
		label values `var' prettycategorical`nolabel'
		}
		label define `:value label `var'' 999 "Missing", modify
		}
        }
	
	*****************************
	** CONTINUOUS NORMAL TABLE **
	*****************************
		qui foreach i of local position2 {
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
	
	local contnormal colname[name2 `contnormal' empty]
}
		 }
		 
		 
		 
	*****************************
	** CONTINUOUS SKEWED TABLE **
	*****************************

		qui foreach i of local position2 {
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
	
	local contskewed colname[name3 `contskewed' empty]
}
		}



	***********************
	** CATEGORICAL TABLE **
	***********************
	

	
		qui foreach i of local position2 {
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

		
	qui foreach var of local categorical {
	local q = `q' + 1
	local variablelabel :variable label `var'
	
	if "`variablelabel'" != "" {
	collect addtags varheading`q'["`:variable label `var''"], ///
	fortags(colname[`var'])

	}

	
	else {
	collect addtags varheading`q'[`var'], fortags(colname[`var'])
	}
	
	collect addtags varheading`q'["name1"], fortags(colname[name1])
	collect addtags varheading`q'["empty"], fortags(colname[empty])
	
	collect style cell varheading`q'#cell_type[row-header], ///
	font(, bold)
	
	collect style cell colname[`var']#cell_type[row-header], ///
	font(, nobold)
	
	collect style header varheading`q'#cell_type[row-header], title(hide) level(label)
	
	collect style header colname[`var'], title(hide)
	
	}
	
	qui foreach var of local categorical {
	local p = `p' + 1
		
		if `p' == 1 {
		local categoricalheading varheading`p'#colname[`var'] 
	}
	
		else {
		local categoricalheading `categoricalheading' varheading`p'#colname[`var'] 
		}
	
	}
	
	local categoricalheading colname[name1] `categoricalheading' colname[empty]
}
		}


	*********************************************
	** Creating empty rows and column headings **
	**********************************************

	qui collect get _r_b1 = " ", tags(`by'[1] colname[empty])
	
	qui foreach i of local levels_by_var{
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

		
	qui foreach i of numlist 1/ `:word count `position2''{
	
	if `"`:word `i' of `position2''"' == "contn"{
		local colname2 `colname2' `contnormal'
	}
	
	else if `"`:word `i' of `position2''"' == "conts"{
		local colname2 `colname2' `contskewed'
	}
	
	else if `"`:word `i' of `position2''"' == "categ"{
		local colname2 `colname2' `categoricalheading'
	}
	
}

	**************************
	** Formatting 0 percent ** 
	**************************
	
	foreach var of local categorical {
	qui levelsof `var', local(levels_of_`var')
	
	foreach level of local levels_of_`var' {
	
	foreach l of local levels_by_var {
	
	qui count if `var' == `level' & `by' == `l'
	local `level'`l'count = r(N)
	qui count if `by' == `l'
	local count`l' = r(N)

	if ``level'`l'count' == 0  | ``level'`l'count' == `count`l'' {
	qui collect style cell `by'[`l']#colname[`level'.`var'], nformat(%9.0fc)
	}
	
	}
	
	}
	}

	
	************************
	** Collecting Layouts **
	************************
	if `no_by' == 0 {
	
	
	
	forvalues i = 0/`number_of_levels' {

	local labelcounts = `labelcounts' + 1
	
	collect label levels `by' `i' "`vl`labelcounts'' `label`i''", modify
	
	}
	
	qui collect label levels `by' .m "Total N =  `total' (100%)" 
	
	qui collect label levels result 1 "N" 2 "%"
	
	qui collect layout (`colname2') (`by'[`levelfinal' .m]#result[1 2])
 }

	
	else {
		collect label dim pretty_replacement_by "Total", modify
		
		collect label levels `by' .m "`no_total'", modify

		qui  collect layout (`colname2') (`by'[.m]#result[1 2])
	}
	
	
	
}
	********************************
	** Formatting header or table **
	********************************
	qui collect style cell cell_type[column-header],  font(, size(11) bold)
	qui collect style cell colname[name1 name2 name3], font(, bold)
	qui collect style cell result[2], halign(right)
	
	****************************
	** Formatting Final Table **
	****************************
	qui collect style header colname[empty], level(hide)
	qui collect style header colname[name1], level(hide)
	qui collect style header colname[name2], level(hide) 
	qui collect style header colname[name3], level(hide)

	qui collect style cell ///
	colname[contnormal]#cell_type[column-header], font(, bold)
	
	qui collect style cell ///
	colname[contskewed]#cell_type[column-header], font(, bold)
	
	qui collect style row stack, nobinder indent spacer
	qui collect style header result, level(hide)
	
	 
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
	by_label_2 levels_by_var _p _q
	
	capture drop pretty_replacement_by
	capture label drop prettybylabel 
	


	end
	


	

	
