***********************************************
******************* odk2doc *******************
*** Stata program to convert xlsform to doc ***
***********************************************
*************** By Anna Reuter ****************

*! Version 2.1, June 4th 2025 


program odk2doc

	version 15.0
	
	syntax using/, to(string) [keep(string)] [DROPType(string)] [DROPVar(string)] [max(integer 30)] [fill] [DELete(string)] [clean] [mark(string)] [doc(string asis)] [fmt(string asis)] [tfmt(string asis)] [qfmt(string asis)] [afmt(string asis)] [replace]
	
	if !inlist("`mark'","","multiple","single","both") {
		di in red `"Option "mark" must contain either "multiple", "single", or "both""'
		exit
	}
	if `max'<0 {
		di in red `"Option "max" must be positive"'
		exit
	}

	
preserve
	
quietly {
	
	tempfile temp_choices temp_vars
		
		

***	Get choices sheet ***
	
import excel "`using'", sh("choices") first all clear
 
	// Harmonize list name (different versions possible)
	cap rename 	list 		list_name
	cap rename 	listname 	list_name
	keep 		list_name name label*
	
	// Ignore blank rows
	drop 		if list_name==""
	
	// Apply max. number of choices
	tempvar Nobs nobs toomany
	gen 	`nobs' = _n
	bysort list_name: gen `Nobs' = _N
	gen 	`toomany' = `Nobs'>`max'
	count if `toomany'==1
	if `r(N)'>0 {
		noi di _n "The following choices are omitted as the number of answer options exceed `max':"
		noi tab list_name if `toomany'==1
	}
	drop if `Nobs'>`max'
	sort list_name `nobs'
	drop `Nobs' 
	
	rename label* answer*
	compress

save "`temp_choices'"


*** Get survey sheet ***

import excel "`using'", sh("survey") first all clear

	// Error check: Do all variables specified in "keep" exist?
	foreach k in `keep' {
		ds, has(varl "`k'*")
		if wordcount("`r(varlist)'")==0 {
			noisily di in red `"Column labeled "`k'" not found"'
			exit(0)
		}
	}
	
	// Keep labeled questions only
	drop if name==""
	ds label*
	local w: word 1 of `r(varlist)'
	drop if `w'==""
	
	// Split question type and list name
	tempvar qtype other wcount
	gen 	`qtype' 	= word(type,1)
	gen 	list_name 	= word(type,2)
	gen 	`other' 	= ""
	gen 	`wcount' 	= wordcount(type)
	su 		`wcount', meanonly
	if `r(max)'>2 {
		replace `other' = word(type,3)
	}
	replace `qtype' 	= list_name 	if inlist(`qtype',"begin","end")
	foreach d of local droptype {
		drop 	if inlist(`qtype',"`d'")
		if r(N_drop)>0 	noi di as text 	`"Dropped questions of type "`d'""'
	}
	
	// Drop unwanted elements
	local count = 0
	foreach var in `dropvar' {
		drop if strmatch(name,"`var'")
		if r(N_drop)>0 	local count = `count'+1
	}
	if "`dropvar'"!="" & `count'==0 noi di as text `"No variable specified in option "drovar" could be dropped"'

	// Collect all columns which should be kept.
	foreach k in `keep' {
		ds, has(varl "`k'*")
		local klist `klist' `r(varlist)'
	}
	
	// Number questions
	tempvar question_no
	gen `question_no' = _n
	
	// Display warranted input below questions
	if "`fill'"!="" {
		tempvar dup1 dup2 dup3 dup4
		expand 2 	if type=="range", 							gen(`dup1')
		expand 2 	if (type=="integer" | type=="decimal"), 	gen(`dup2')
		expand 2 	if regexm(`other',"other"), 				gen(`dup3')
		expand 2 	if inlist(type,"text","image","geopoint"), 	gen(`dup4')
		sort `question_no' `dup1' `dup2' `dup3' `dup4'
		foreach v of varlist label* {
			cap replace `v' = parameter 	if type=="range" & `dup1' == 1
				replace `v' = "[Number]" 	if type=="range" & `dup1' == 1 & missing(`v')	
			cap replace `v' = constraint 	if (type=="integer" | type=="decimal") & `dup2' == 1
				replace `v' = "[Number]" 	if (type=="integer" | type=="decimal") & `dup2' == 1 & missing(`v')	
				replace `v' = "Other, specify" if `other'!="" & `dup3' == 1
				replace `v' = "[" + strproper(type) + "]" if `dup4' == 1
		}
		foreach k in `klist' {
			replace `k' = "" 	if `dup1'==1 | `dup2'==1 | `dup3'==1 | `dup4'==1
		}
		replace name 	= "" 	if `dup1'==1 | `dup2'==1 | `dup4'==1
		replace `qtype' = "" 	if `dup3'==1
	}
	
	// Mark single/multiple select
	if inlist("`mark'","multiple","both") {
		foreach w of varlist label* {
			replace `w' = `w' + " [Multiple select]" if `qtype'=="select_multiple"
		}		
	}
	if inlist("`mark'","single","both") {
		foreach w of varlist label* {
			replace `w' = `w' + " [Single select]" if `qtype'=="select_one"
		}		
	}

	// Order & keep only relevant columns
	order 	`question_no' type list_name name label* `klist'
	keep 	`question_no' type list_name name label* `klist' `dup1' `dup2' `dup3' `dup4'
	
	tempvar is_question code
	gen `code' = name
	drop name
	gen `is_question' = 1
	
	compress

save "`temp_vars'"


	// If requested input type should be displayed below open-ended questions, "Other, specify" is dropped
	if "`fill'"!="" {
		drop if `dup3'==1
	}
	
	// Only keep question number, name, listname and input marker to merge answer lists, other information will be appended
	keep `question_no' `code' list_name `dup1' `dup2' `dup4'



*** Combine with answer options ***

	// First combine such that we only have the answers to each question
joinby list_name using "`temp_choices'"
	sort `question_no' `dup1' `dup2' `dup4' `nobs'
	if "`fill'"!="" {
		gen `dup3' = 0
	}
	drop list_name

	// Append question labels
append using "`temp_vars'"

	// Match questions with answer options	
	ds answer*
	local a `r(varlist)'
	local N: list sizeof a
	tokenize `a'
	
	ds label*
	local q `r(varlist)'
	
	foreach w of local q {
		forv n = 1/`N' {
			if regexr("``n''","answer","label")=="`w'" {
				replace `w' = ``n'' if `w'=="" & ``n''!=""
			}
		}
	}
	
	// Delete substrings from questions and answers
	if `"`delete'"'!="" {	
		foreach w of varlist label* {
			foreach c of local delete {
				replace `w' = ustrregexrf(`w',`"`c'"',"")
			}
			replace `w' = ustrtrim(stritrim(`w'))
		}
	}

	// Clean Markdown and xlsForm code
	if "`clean'"!="" {
		if "`fill'"!="" {
			foreach w of varlist label* {
				replace `w' = ustrregexra(`w',"<.[^>]+>"," ") 		if `dup1'!=1 & `dup2'!=1
				replace `w' = ustrregexra(`w',"[\*_#]","") 			if `dup1'!=1 & `dup2'!=1
				replace `w' = usubinstr(`w',"${","_",.)		 		if `dup1'!=1 & `dup2'!=1			
				replace `w' = ustrregexra(`w',"_.[^\}]+\}","___",.)	if `dup1'!=1 & `dup2'!=1			
				replace `w' = ustrtrim(stritrim(`w'))			
			}
		}
		if "`fill'"=="" {
			foreach w of varlist label* {
				replace `w' = ustrregexra(`w',"<.[^>]+>"," ")
				replace `w' = ustrregexra(`w',"[\*_#]","")
				replace `w' = usubinstr(`w',"${","_",.)	
				replace `w' = ustrregexra(`w',"_.[^\}]+\}","___",.)
				replace `w' = ustrtrim(stritrim(`w'))			
			}
		}
	}
	
	replace `code' = name if name!=""
	if "`fill'"!="" {
		replace `code' = `code' + "_other" if `dup3'==1
	}
	sort `question_no' `dup1' `dup2' `dup3' `dup4' `is_question' `nobs'
	
	// Only give question number to question, not answers
	tempvar running question
	by `question_no': 	gen 	`running' 		= _n
						replace `question_no' 	= . 	if `running'>1
						gen 	`question' 		= strofreal(`question_no')
						replace `question' 		= "" 	if `question'=="."
	drop 	`question_no'
	
	keep 	`question' label* `code' `klist'
	order 	`question' label* `code' `klist'

	// Clean "relevant" and "constraint" column
	foreach v in relevant constraint {
		cap confirm var `v'
		if !_rc {
			replace `v' = usubinstr(`v',"${","",.)
			replace `v' = usubinstr(`v',"},'","=",.) 					if ustrregexm(`v',"selected(")
			replace `v' = usubinstr(`v',"}, '","=",.) 					if ustrregexm(`v',"selected(")
			replace `v' = usubinstr(`v',"')","",.) 						if ustrregexm(`v',"selected(")
			replace `v' = usubinstr(`v',"count-selected(","count(",.)	if ustrregexm(`v',"count-selected(")
			replace `v' = usubinstr(`v',"selected(","",.) 				if ustrregexm(`v',"selected(")
			replace `v' = usubinstr(`v',"}","",.)
		}
	}
	
	// Create column headers
	la var `question' Question
	la var `code' Code
	ds, not(varl *::*) 
	local lab_list1 `r(varlist)'
	foreach l of local lab_list1 {
		local lab: var lab `l' 
		local lab = ustrtitle(ustrtrim(ustrregexrf("`lab'","_"," ")))
		la var `l' "`lab'"
	}
	ds, has(varl *::*)
	local lab_list2 `r(varlist)'
	foreach l of local lab_list2 {
		local lab: var lab `l' 
		local lab = ustrregexrf("`lab'","::"," ")
		local type: word 1 of `lab'
		local type = ustrtitle(ustrtrim(ustrregexrf("`type'","_"," ",.)))		
		local lab: word 2 of `lab'
		if "`type'"=="Label" la var `l' "`lab'"
		if "`type'"!="Label" la var `l' "`type' `lab'"
	}

}


	cap putdocx clear

putdocx begin, `doc'

	putdocx table Q = data(*), varnames `fmt'
	
	// Put column headers in first row
	local n = 1
	foreach var of varlist * {
		local lab: var l `var'
		putdocx table Q(1,`n') = ("`lab'")
		local n = `n'+1
	}
	
	// Format column headers
	if `"`tfmt'"'!="" {
		putdocx table Q(1,.), `tfmt'
	}
	
	// Format questions & answers
	if `"`qfmt'"'!="" {
		forv n = 1/`=_N' {
			if `question'[`n']!="" {
				putdocx table Q(`=`n'+1',.), `qfmt'
			}	
		}
	}
	
	// Format answers
	if `"`afmt'"'!="" {
		forv n = 1/`=_N' {
			if `question'[`n']=="" {
				putdocx table Q(`=`n'+1',.), `afmt'
			}	
		}
	}

putdocx save `"`to'"', replace
	
restore
	
end
