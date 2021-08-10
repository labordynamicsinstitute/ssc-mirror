program def fndmtch2
*! NJC 1.5.0 14 November 2000 
* NJC 1.4.0 29 February 2000 
	version 6.0 
	syntax varlist(min=2 max=2) [if] [in] /* 
	*/ , [ Generate(string) List by(varlist) MISS Count ] 
	
	local g `generate'
	if "`g'" == "" & "`list'" == "" { 
		di in r "must specify either generate( ) or list option" 
		exit 198 
	}
	else if "`g'" != "" { 
		confirm new variable `g' 
	} 
	else tempvar g 
	
	tokenize `varlist' 
	args var1 var2
	
	capture confirm string variable `var1' 
	local var1num = _rc != 0
	capture confirm string variable `var2' 
	local var2num = _rc != 0 
	if `var1num' != `var2num' { 
		local var1is = cond(`var1num',"numeric","string") 
		local var2is = cond(`var2num',"numeric","string") 
		di in r "`var1' is `var1is', `var2' is `var2is'" 
		exit 198 
	}	

	tempvar touse group BY 
	mark `touse' `if' `in'
	if "`miss'" == "" { 
		qui replace `touse' = 0 if missing(`var1') 
	}	
	qui gen byte `g' = cond(`touse',0,.) 

	if "`by'" == "" { 
		gen byte `BY' = 1 
	}	
	else { 
		sort `by' 
		qui by `by' : gen byte `BY' = _n == 1 
		qui replace `BY' = sum(`BY') 
	}	
	
	sort `touse' `var2' `BY' 
	qui by `touse' `var2' `BY' : gen byte `group' = _n == 1 & `touse' 
	qui replace `group' = sum(`group') 
	local ngrp = `group'[_N] 

	qui count if !`touse' 
	local j = r(N) + 1
	local i = 1 
	
	if "`count'" != "" { 
		qui while `i' <= `ngrp' {
			count /* 
		*/ if `var1' == `var2'[`j'] & `touse' & `BY' == `BY'[`j']  
			replace `g' = r(N) /* 
		*/ if `var1' == `var2'[`j'] & `touse' & `BY' == `BY'[`j'] 
			count if `group' == `i' 
			local j = `j' + r(N) 
			local i = `i' + 1 
		} 	
	} 
	else { 
		qui while `i' <= `ngrp' {
			replace `g' = 1 /* 
		*/ if `var1' == `var2'[`j'] & `touse' & `BY' == `BY'[`j'] 
			count if `group' == `i' 
			local j = `j' + r(N) 
			local i = `i' + 1 
		} 	
	}

	if "`list'" != "" {
		qui count if `g' > 0 & `g' < . 
		if r(N) > 0 { list `varlist' if `g' > 0 & `g' < . } 
	} 	
end 		

