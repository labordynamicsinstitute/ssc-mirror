******** ztree2stata --- Read data file created by z-Tree. 
******** Kan Takeuchi at the University of Michigan. (Now, Hitotsubashi U. in Japan.)
******** E-mail: <ktakeuch@umich.edu> or <kan@econ.hit-u.ac.jp>
******** Mar 01, 2005. 
******** Feb 01, 2008.  Update "trim too long names" part.
******** Apr 18, 2014.  "Bug fixed on April.18, 2014". 
******** Dec 05, 2022.  Use "subjects" instead of "session" to get NumTreatment. 
******** Dec 11, 2022.  Destring automatically. string option is no longer needed.

program ztree2stata
version 8

local versiondate "Dec 11, 2022"

** Define the command first. 
syntax name(name=keepthistable) using/ [, TReatment(numlist >0 integer) STRing(namelist) EXCept(namelist) SAve CLEAR REPLACE]

tokenize `string'
local counter 1
while "``counter''"~=""{ 
	local StrVar`counter' ``counter''
	local ++counter
}
local NumStrVar = `counter'-1

tokenize `except'
local counter 1
while "``counter''"~=""{ 
	local Exception`counter' ``counter''
	local ++counter
}
local NumException = `counter'-1

** Read the data.
quietly{
	insheet using `using', `clear'

*** Bug fixed on April.18, 2014. Thanks to Lawrence.
*** When the data file contains chat data, the second column (v2) is string.
***  Thus, to obtain the number of treatments, we need to 
*** change the type from string into real.  Use "table"  data. 
gen temptreatmentnum = v2 if v3 =="`keepthistable'"
destring temptreatmentnum, replace 
sum temptreatmentnum
local NumTreatment = _result(6)
local CurrentTreatment = `NumTreatment' 
drop temptreatmentnum

** Check if the treatment in the option surely includes 
** actual treatment in the data.  If not, return error. 
if "`treatment'"~=""{
	local NG 0
	foreach temp of numlist `treatment'{
		if `temp' > `NumTreatment'{
			local NG 1
		}
	}
	if `NG'{
		noisily{
			di " The treament option unmatches with the data. "
			di " Note that the data includes only `NumTreatment' treatment(s)."
		}
		error 
		exit
	}
}


tempfile tempdata

** Begin from the last treatment. 
local NotFirstTreatment 0
while `CurrentTreatment' > 0 {
* But the CurrentTreatment should be included in `treatment'.
	local UseThisTreatment 0

	if "`treatment'"==""{
		local UseThisTreatment 1 
	}
	else{
		foreach temp of numlist `treatment'{
			if `CurrentTreatment' == `temp'{
				local UseThisTreatment 1
			}
		}
	}
	
    if `UseThisTreatment'{
	if `NotFirstTreatment'{
		import delimited `using', delimiters(tab) stripquotes(no) clear
		compress
	}
	rename v1 session
	rename v2 treatment
	rename v3 tables

	* delete irrelevant observations. 
	keep if tables== "`keepthistable'"
	*** Bug fixed on April.18, 2014. Thanks to Lawrence.
	destring treatment, replace
	*** Bug fixed. 
	keep if treatment == `CurrentTreatment'

	des 
	local NumVariable = _result(2)

	* Then, drop duplicated labels. 
	local temp = trim(v4[1])
	drop if v4=="`temp'"&_n~=1
	
	* Rename all of the rest variables. 
	* i is counting up from v4 to v`NumVariable'. 
	tempvar tempvarname
	local i = 4
	di v7[1]
	while `i' <= `NumVariable'{
		rename v`i' `tempvarname'`i'
		local ++i
	}

	local i = 4
	while `i' <= `NumVariable'{
		* We need to check if obs of v`i' are not all missing values.
		local emptydata = missing(`tempvarname'`i'[1])
		if `emptydata' {
			local j = ""
		} 
		else{
			local j = trim(`tempvarname'`i'[1])
			* Delete double quotations, if any.
			local j = subinstr(`"`j'"',`"""',"",.)
		}
		* j is the variable name of `tempvarname'`i'.
		
		
		* Let's check whether this variable is one of exceptions or not. 
		local IsException = 0
		* This counter is conuting up Exceptions below.
		local counter = 1  
		while `counter' <= `NumException'{
			if index( "`j'" , "`Exception`counter''" ) > 0{ 
				local IsException = `counter'
			}
			local ++counter
		}

		* If `tempvarname'`i' variable does not include Exception's, then `IsException' == 0. 
		if `IsException'==0{
			* delete " [ " and " ] "
			local j = subinstr("`j'","[","",.)
			local j = subinstr("`j'","]","",.)
			* delete "!", ":", ";", "=", " ". 
			local j = subinstr("`j'","!","",.)
			local j = subinstr("`j'",":","",.)
			local j = subinstr("`j'","=","",.)
			local j = subinstr("`j'",";","",.)
			local j = subinstr("`j'"," ","",.)
			
			*trim too long names. 
			if length("`j'")>30{
				local j=substr(" `j' ", 1 , 15)+substr(" `j' " , length("`j'")-14 ,length("`j'"))
			}
			* For this part I owe Mr. Joshua B. Miller.  Thanks, Joshua. 
    
			* Finally define the variable name. 
			local NewName = "`j'"
		} 
	
		* If `tempvarname'`i' variable includes Exception's, then `IsException' > 0. 
		if `IsException' > 0{
			local NewName = "`Exception`IsException''"+"`i'"
		}
	
		* Finally rename the variable name. 
		if length("`NewName'") == 0 {
			drop `tempvarname'`i'
		}
		if length("`NewName'") > 0 {
			rename `tempvarname'`i' `NewName'
		}
		
	
		* Then, the counter is increasing. 
		local ++i
	} // End of while `i' < `NumVariable'{
	
	drop if _n==1
	
	if `NotFirstTreatment'{
		append using `tempdata'
	}
	save `tempdata', replace 

	local NotFirstTreatment 1
	} // The end of if `UseThisTreatment'{
	
	local --CurrentTreatment
}

**** Destring all variables, with the replace option. 
ds
local vars `r(varlist)'
foreach x of varlist `vars' {
    * Check if it is not one of the string variables. 
	local IsStringOption 0
	local counter 1
	while `counter' <= `NumStrVar'{
	    if "`x'" == "`StrVar`counter''"{
			local IsStringOption 1
		}
		local ++counter
	}
	if `IsStringOption' == 0{
		destring `x', replace
	}
}

compress
}  // The end of quietly{ 

display ""
display "ztree2stata version `versiondate'"

set more off
des
set more on

if "`save'"~=""{
	local newfilename = subinstr("`using'",".xls",".dta",1)
	local newfilename = subinstr("`newfilename'",".dta","-`keepthistable'.dta",1)
	save "`newfilename'", `replace'
}
end

