	* Produces a table of baseline characteristics for publications, describing baseline characteristics
	* Rafael Gafoor, rafael.gafoor@protonmail.com
	*
	*! -pretty_baseline- version 1.4 Georgia McRedmond 02-10-2024
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
		[IQRRANGE] ///
		[TITLE(string)] ///
		[SAVing(string)] ///
		[POSition(string)] ///
		[REPLACE]
		
		

	**************
	** SET - UP **
	**************
		
		************************************************
		** Setting up environment and clearing macros **
		************************************************
		collect clear
		marksample touse
		tempfile data
		qui save `data'
		

		if "`saving'" != "" {
		putdocx clear
		}
		
		
		qui if "`by'" != "" {
		drop if `by' == . 	
		}
		
		**********************
		** Frequency Weight **
		**********************
		local weight "[`weight'`exp']"
		if "`weight'" == "[]"{
			local weight
		}

		
		********************
		** Decimal Format **
		********************
		 if `:word count `fcont'' == 0{
			local fcont "%9.2fc"
		 }
		 
		 if `:word count `fcateg'' == 0{
			local fcateg "%9.2fc"
		 }
		
		

	**********************
	** ONLY BY VARIABLE ** 
	**********************
		
		if `:word count `contnormal'' == 0 & `:word count `contskewed'' == 0 & `:word count `categorical'' == 0 {	
		
		qui table, stat(fvfrequency `by') stat(fvpercent `by')
		collect recode result `"fvfrequency"' = `"one"' `"fvpercent"' = `"two"'
		qui collect layout () (`by'#result[one two])
		collect label levels result one "N" two "(%)", modify
		collect style cell result[two], nformat(`fcateg') sformat("(%s%%)")
		}
		

		

	*****************************
	** BY AND VARIABLES TABLES **
	*****************************	
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
		if `:word count `by'' != 0 {
		qui ds `by', has(type string)
		
		if "`r(varlist)'" != "" {
		
		local string_by = r(varlist)
		
		foreach var of local string_by {
			
		local new = `new' + 1	
		
		encode `var', gen(new`new')
		drop `var'
		rename new`new' `var'
		
		}
		
		}
		
		}
		
		if `:word count `by'' == 0 {
			local no_by = 1 
			capture gen pretty_replacement_by = 1
			local by pretty_replacement_by
		}
		
		else {
			local no_by = 0
		}
	
			
		****************************
		** Recoding by if not 0/1 **
		****************************

		qui levelsof(`by'), local(levelcheck)
		
		qui tab `by'
		
		local number_of_levels = r(r)
		
		qui forvalues i = 0/`number_of_levels' {
			
			capture drop label`i'
		
		}
		
		
		local vlname: value label `by'
		
			
		if "`vlname'" != "" {
			
		qui foreach level of local levelcheck{
		
		local m = `m' + 1
		
		local vl`m':label `vlname' `level'
		
		}
		
		}

		qui foreach level of local levelcheck {
		
		local begin = `begin' + 1
		
			if "`: value label `by''" == "" | "`nolabel'" != "" {
				
				capture label define prettynobylabel `level' "`level'", add 
				
				label value `by' prettynobylabel
			
			}	
			
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
			
			label define prettybylabel 0 "`vl1'" 1 "`vl2'", replace
		
			label values `by' prettybylabel
		
		}

		
		*******************************************
		** Encoding string categorical variables **
		*******************************************
		qui ds `categorical', has(type string)
		
		if "`r(varlist)'" != "" {
				
		
		local string_categ = r(varlist)
		
		foreach var of local string_categ {
			
		replace `var' = subinstr(`var', "`=char(10)'"," ", .)
		
		replace `var' = subinstr(`var', "`=char(13)'"," ", .)
			
		local newc = `newc' + 1	
		
		encode `var', gen(newc`newc')
		drop `var'
		rename newc`newc' `var'
		
		}
		
		}
		
		
		***********************
		** Labelling Missing **
		***********************
		
		qui foreach var of local categorical {
		
		if "`: value label `var''" != "" {
		
		local prettylabel :value label `var'
		
		replace `var' = 999 if `var' == . 
		
		label define `prettylabel' 999 "Missing", modify
		
		label values `var' `prettylabel'
		
		}
		
		else {
			
		replace `var' = 999 if `var' == . 
		
		label define prettylabel 999 "Missing", replace
		
		label values `var' prettylabel
			
		}
		
		}

		*******************************
		** Formatting Column Headers **
		*******************************
		
		preserve
		cap qui keep if `touse'
		qui drop if missing(`by')

		qui levelsof `by', local(levels_by_var)
		
		
		if `no_by' == 0 {
		qui contract `by' `weight'	, freq(n) percent(p)
		gen label = "N = " +string(n , "%9.0fc") + " (" + string(p, "%9.1fc") + "%)"

		
		qui foreach level of local levels_by_var {
			local v = `v' + 1 
			local vlname: value label `by'
			local bylevel`v': label `vlname' `level'		
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
		
		
		preserve
		cap qui keep if `touse'
		forvalues i = 0/`number_of_levels' {
			
			qui count if `by' == `i'
			local n`i' = r(N)
			local p`i' = (`n`i''/`n')*100
			
			gen pstring`i' = ///
			"(" + string(`p`i'', "%9.1fc") + "%)"
			
			local pstring`i' = pstring`i'
			
			gen label`i' = ///
			"N = " +string(`n`i'' , "%9.0fc") ///
			+ "(" + string(`p`i'', "%9.1fc") + "%)"
			
			local label`i' = label`i'
		

		}
		
		restore 
		
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
							   
		qui collect recode result `"mean"' = `"one"' ///
									`"sd"' = `"two"' 
		
		qui collect style cell result#colname[`contnormal'], nformat(`fcont')
		qui collect style cell result[two]#colname[`contnormal'], sformat("(%s)") nformat(`fcont')
		
		restore
		
		local contnormal colname[name2 `contnormal']
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
							   statistic(p25 `contskewed') ///
							   statistic(p75 `contskewed') ///
							   missing append

		if "`:word count `iqrrange''" == "0" {
		qui collect recode result `"median"' = `"one"' ///
							  `"iqr"' = `"two"' 
							  
		qui collect style cell result[two]#colname[`contskewed'], sformat("(%s)") nformat(`fcont')
		
		}
		
		else {
		collect recode result `"median"' = `"one"' ///
								`"p25"' = `"two"' ///
								`"p75"' = `"three"'
								
		qui collect style cell result[two]#colname[`contskewed'], sformat("(%s") nformat(`fcont')
		qui collect style cell result[four]#colname[`contskewed'], sformat("%s)") nformat(`fcont')
								
		
		}
		
		qui collect style cell result#colname[`contskewed'], nformat(`fcont')
	
		
		restore
		   
		local contskewed colname[name3 `contskewed']
		
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
							   
		qui collect recode result `"fvfrequency"' = `"one"' ///
							  `"fvpercent"' = `"two"' 
						  
		
		qui collect style cell result[one]#colname[`categorical'], nformat(%9.0fc)
		qui collect style cell result[two]#colname[`categorical'], nformat(`fcateg')
		qui collect style cell result[two]#colname[`categorical'], sformat("(%s)")
		
		
		restore
		

		** Bold Category Headings 	
		qui foreach var of local categorical {
		local q = `q' + 1
		local variablelabel :variable label `var'
		
		qui levelsof `var', local(`var'f)
		
		foreach l of local `var'f {
		
		local `var'fl ``var'fl' `l'.`var'
		
		di "``var'fl'"

		}
		
		
		if "`variablelabel'" != "" {
		collect addtags varheading`q'["`:variable label `var''"], ///
		fortags(colname[``var'fl'])

		}

		
		else {
		collect addtags varheading`q'[`var'], fortags(colname[``var'fl'])
		}
		
		collect addtags varheading`q'["name1"], fortags(colname[name1])
		collect addtags varheading`q'["empty"], fortags(colname[empty])
		
		collect style cell varheading`q'#cell_type[row-header], ///
		font(, bold)
		
		collect style cell colname[``var'fl']#cell_type[row-header], ///
		font(, nobold)
		
		collect style header varheading`q'#cell_type[row-header], title(hide) level(label)
		
		collect style header colname[``var'fl'], title(hide)
		
		qui collect style cell result[one]#colname[``var'fl'], nformat(%9.0fc)
		qui collect style cell result[two]#colname[``var'fl'], nformat(`fcateg')
		qui collect style cell result[two]#colname[``var'fl'], sformat("(%s)")
		
		}
		
		
		
			** Hide New Dimension Headings 
			qui foreach var of local categorical {
			local p = `p' + 1
				
				if `p' == 1 {
				local categoricalheading varheading`p'#colname[``var'fl'] 
			}
			
				else {
				local categoricalheading `categoricalheading' varheading`p'#colname[``var'fl'] 
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
		qui collect get _r_b8 = "N = `n`i''", tags(`by'[`i'] colname[name4])
		qui collect get _r_b9 = "`pstring`i''", tags(`by'[`i'] colname[name4])
		}
		
		qui collect get _r_b2 = "n", tags(`by'[.m] colname[name1]) 
		qui collect get _r_b3 = "(%)", tags(`by'[.m] colname[name1])
		qui collect get _r_b4 = "Mean", tags(`by'[.m] colname[name2]) 
		qui collect get _r_b5 = "(sd)", tags(`by'[.m] colname[name2])
		qui collect get _r_b6 = "Median", tags(`by'[.m] colname[name3]) 
		qui collect get _r_b7 = "(IQR)", tags(`by'[.m] colname[name3])
		qui collect get _r_b8 = "N = `total'", tags(`by'[.m] colname[name4])
		qui collect get _r_b9 = "(100%)", tags(`by'[.m] colname[name4])
		
		qui collect recode result `"_r_b2"' = `"one"' ///
								  `"_r_b3"' = `"two"' ///
								  `"_r_b4"' = `"one"' ///
								  `"_r_b5"' = `"two"' ///
								  `"_r_b6"' = `"one"' ///
								  `"_r_b7"' = `"two"' ///
								  `"_r_b1"' = `"one"' ///
								  `"_r_b8"' = `"one"' ///
								  `"_r_b9"' = `"two"' 
								  				 
		
	**********************
	** FINAL FORMATTING **	
	**********************	
		
		**************************
		** Formatting 0 percent ** 
		**************************
		
		foreach var of local categorical {
		local format0 = `format0' + 1	
		
		qui levelsof `var', local(levels_of_`format0')
		
		foreach level of local levels_of_`format0' {
		
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

		*collect style row stack, spacer nobinder
		
		
		***************************
		** Assembing Final Table **
		***************************

			
		qui foreach i of numlist 1/ `:word count `position2''{
		
		if `"`:word `i' of `position2''"' == "contn"{
			local colname2 `colname2' `contnormal' colname[empty]
		}
		
		else if `"`:word `i' of `position2''"' == "conts"{
			local colname2 `colname2' `contskewed' colname[empty]
		}
		
		else if `"`:word `i' of `position2''"' == "categ"{
			local colname2 `colname2' `categoricalheading' 
		}
		
		}

		
		
		************************
		** Collecting Layouts **
		************************
		qui if `no_by' == 0 {
		
		
		qui forvalues i = 0/`number_of_levels' {

		local labelcounts = `labelcounts' + 1
		
		collect label levels `by' `i' "`vl`labelcounts''", modify
		
		}
		
		qui collect label levels `by' .m "Total", modify
		
		qui collect label levels result one "N" two "%"
		
		if `:word count `iqrrange'' == 0 {
		
		qui collect layout (colname[name4] colname[empty] `colname2') (`by'[`levelfinal' .m]#result[one two])
	
	}
		
		qui else {
		collect composite define four = two three, delimiter("to")
		
		collect layout (colname[name4] colname[empty] `colname2') (`by'[`levelfinal' .m]#result[one four])
		
		}
		
		}

		
		qui else {
			collect label dim pretty_replacement_by "Total", modify
			
			collect label levels `by' .m "Total", modify
			collect style header `by', level(hide)
			
			if `:word count `iqrrange'' == 0 {

			qui  collect layout (colname[name4] colname[empty]`colname2') (`by'[.m]#result[one two])
			
			}
			
			qui else {
			collect composite define four = two three, delimiter("to")
			
			qui collect layout (colname[name4] colname[empty]`colname2') (`by'[.m]#result[one four])
			
			}
		
		}
		
		}
		
		
		****************************
		** Formatting Final Table **
		****************************
		
		qui collect style cell cell_type[column-header],  font(, size(11) bold)
		
		qui collect style cell cell_type[row-header], font(, bold)
		
		
		if `:word count `iqrrange'' == 0 {
		qui collect style cell result[two], halign(left)
		}
		
		else {
		qui collect style cell result[four], halign(left)	
		}
		
		qui collect style cell result[one], halign(right)
		
		
		qui collect style header colname[empty], level(hide) 
		qui collect style header colname[name1], level(hide) 
		qui collect style header colname[name2], level(hide) 
		qui collect style header colname[name3], level(hide) 
		qui collect style header colname[name4], level(hide)
		
		qui collect style header result, level(hide)
		
		qui collect style cell cell_type[column-header], halign(center)
		
		qui collect style header cell_type[row-header], level(label)

		qui collect style cell ///
		colname[contnormal]#cell_type[column-header], font(, bold)
		
		qui collect style cell colname[name1] colname[name2] colname[name3], font(, bold)
		
		qui collect style cell /// 
		cell_type[column-header]#result[one two] , font(, bold)
		
		
		*qui collect style row stack, nobinder indent spacer
		
		 
		******************
		** Adding title	**
		******************
		
		if `"`title'"' != "" {
			collect title "`title'"
		}
		
		
		***************************
		** Setting export format **
		***************************
		
		collect style putdocx,  cellmargin(bottom, 0.05) cellmargin(top, 0.05)
		
		
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
		capture label drop prettybylabel 
		


		end
		


		

		
