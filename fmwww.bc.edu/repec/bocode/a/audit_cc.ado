*! version 1.0.2, 29 March 2023 
* analysis of matched case-control audits of cervical cancer screening

capture program drop audit_cc
#delimit cr
prog def audit_cc, rclass

	    version 16.1
	
		syntax [varname(numeric default=none)] [if/] [fw pw iw/] , ///
		GRoupid(varname)                           ///		
		ID(varname)		                           ///		
		CASEDDiag(varname numeric)	               ///
		SCRDate(varname numeric)                   ///
		RESult(varname numeric)	                   ///
        [                                          ///
		CASEAge(varname numeric)                   ///
		CASEDOB(varname numeric)                   ///
		CASEVars                                   ///
		AGECutpoints(numlist ascending >=0 min=2)  ///
		TLCutpoints(numlist ascending >=0)         ///
		MINage(real 25)                            ///
		MAXage(real 100)                           ///
		ANYTHReshold(real 6)                       ///
		NEGTHReshold(real 0)                       ///
		NOSRESults                                 ///
		NODetail                                   ///
		COEFFicients                               ///
		SAVing(string)                             ///
		DATA(string)                               ///
		NOHeader                                   ///                     
        ]

		
qui {

tokenize `varlist'
local case="`1'"
		
if "`case'" =="" {
	di _n as error "the variable identifying cases and controls must be specified"
	exit
}

local ddiag="`caseddiag'"
local age="`caseage'"
local dob="`casedob'"



*** saving() option

local doctype=""

tokenize `"`saving'"', parse(,)
local saving=`"`1'"'
local replace=`"`3'"'   


local saving=strtrim(`"`saving'"')
if "`saving'"=="," {
	di as error "invalid file name in saving()"
	exit
}

if "`replace'"~="" & "`replace'"~="replace" {
	di as error "option `replace' not allowed in saving()"
	exit
}

if "`saving'" != "" {		
   if strmatch("`saving'","*.*")==0 local saving "`saving'.docx" // if filename has no extension, .docx is assumed
   
   if strmatch("`saving'","*.docx")==1 {
      local doctype="word"
      cap putdocx clear
   }
  
   if strmatch("`saving'","*.smcl")==1 | strmatch("`saving'","*.log")==1 local doctype="log"
   
   if "`doctype'"=="" {
   	   di as error "invalid file name in saving() - it must end with .docx, .log, .smcl or no extension"
	   exit
   }
   
   cap confirm new file "`saving'"
   if _rc == 602 & "`replace'"=="" {
      di as error `"file "`saving'" already exists - you may want to specify the replace option in saving()"'
      exit
   }
   if _rc==602 & "`replace'"=="replace" {
	  	 capture erase "`saving'"
         if _rc!=0 {
            di as error `"file "`saving'" cannot be modified - it may be open in another application or you may not have writing permissions"'
            exit
         }
   }
   if _rc==603 {
      di as error `"file "`saving'" could not be opened: invalid file name or directory or no directory permissions to create a new file"'
      exit
   }
}


*** data() option

tokenize `"`data'"', parse(,)
local datasave=`"`1'"'
local datareplace=`"`3'"'   

local datasave=strtrim(`"`datasave'"')
if "`datasave'"=="," {
	di as error "invalid file name in data()"
	exit
}

if "`datareplace'"~="" & "`datareplace'"~="replace" {
	di as error "option `datareplace' not allowed in data()"
	exit
}

if "`datasave'" != "" {		
   if strmatch("`datasave'","*.*")==0 local datasave "`datasave'.dta" // if filename has no extension, .dta is assumed
   else {
      if substr(trim(`"`datasave'"'),-3,.)~="dta" {
	     di as error "invalid file extension in data() - it must end with .dta or no extension"
	     exit
      }
   } 
		  
   cap confirm new file "`datasave'"
   if _rc == 602 & "`datareplace'"=="" {
      di as error `"file "`data'" already exists - you may want to specify the replace option in data()"'
      exit
   }
   if _rc==603 {
      di as error `"file "`datasave'" could not be opened: invalid file name or directory or no directory permissions to create a new file"'
      exit
   }
}



*** other options

if "`dob'" =="" & "`age'"=="" {
	di _n as error "you must specify either the dob or the age option"
	exit
}

if "`dob'"!="" & "`age'"!="" {
	di _n as error "you cannot specify both the dob and age options"
}

if "`age'"~="" local agedob="`age'"
else local agedob="`dob'"

foreach var of varlist  `dob' `ddiag' `scrdate' {
   capture confirm numeric variable `var'
   if _rc {
      di as error "`var' is not numeric (you may want to use the date() function before audit_cc to convert `var' into a date variable)"
	  exit
   }
}


tempname age2 dob2 caselab oresult agegp case1 smearage i_use date agelab min max rmiss temp


if "`casevars'"~="" {
   preserve
   foreach var in "`ddiag'" "`dob'`age'" {
      tempname temp1 temp2 temp3
	  gen `temp1'=`var' if `case'==1

	  bys `id': egen `temp2'=min(`temp1'), missing
	  bys `id': egen `temp3'=max(`temp1'), missing
	  cap assert `temp2'==`temp3'
	  if _rc~=0 {
         di as error "cases with non-constant values in `var'"
		 exit
      }
	  drop `temp2' `temp3'
	  bys `groupid': egen `temp2'=min(`temp1')
	  replace `var'=`temp2'
	  drop `temp1' `temp2'
   }
}


local vars_opts="`ddiag' `age'`dob'"

		
if "`age'" =="" {
   local age="`age2'"
   gen `age'=(`ddiag'-`dob')/365.25
}

if "`dob'" =="" {
   local dob="`dob2'"
   gen `dob'=(`ddiag'-(`age'*365.25))
}
 
foreach thr in any neg {
  if ``thr'threshold'<0 {  
    di as error "the number specified in `thr'threshold() cannot be <0"
    exit
  }
}

if "`agecutpoints'"=="" local agecutpoints "25 50 65 100"

if "`tlcutpoints'"=="" local tlcutpoints "0 0.5 3.5 5.5 9.5"

if "`coefficients'"=="" local or="or"


if `maxage'<`minage' {
   di as error "maxage cannot be smaller than minage"
   exit
}

if `minage'<0 | `maxage'<0 {
   di as error "minage and maxage cannot be <0"
   exit
}



marksample touse, novarlist

count if `case'==. & `touse'  // records with `case'==.
if r(N)>0  {
   if r(N)==1 local s=""
   else local s="s"
   noi di as txt "Note: `r(N)' record`s' not used because `case'=." 
   replace `touse'=0 if `case'==. & `touse'
}

egen `rmiss'=rowmiss(`groupid' `id')

count if `touse'==1 & `rmiss'>0
if r(N)>0 {
   if r(N)==1 local s=""
   else local s="s"
   noi di as txt "Note: `r(N)' record`s' not used because of missing values in `id' or `groupid'"
   replace `touse'=0 if `rmiss'>0 & `touse'
}

count if `touse'==1 & `rmiss'==0
if r(N) == 0 {
   di as error _n "No observations"
   exit 2000
}



cap assert `result'-floor(`result')==0 | `result'==. if `touse', fast
if _rc==9 {
   di as error "The variable `result' contains non-integer values"
   exit
}



local outvars ""
foreach var in `ddiag' `agedob' {    
  bys `groupid': egen `min'=min(`var'), missing
  bys `groupid': egen `max'=max(`var'), missing   
  cap assert `min'==`max'
  if _rc~=0 {
   if "`outvars'"=="" local outvars="`var'"
   else local outvars "`outvars' and `var'"
  }
  cap drop `min' `max'
}

if "`outvars'"~="" {
   di as error "`outvars' not constant within each matched group - you may want to specify the casevars option"
   exit
}



drop `rmiss'
egen `rmiss'=rowmiss(`vars_opts') // `ddiag' `age' `dob'
count if `rmiss'>0 & `touse'
if r(N)>0 {
   if r(N)==1 local s=""
   else local s="s"
   local vars_opts="`ddiag' or " + word("`vars_opts'",2)
   noi di as txt "Note: `r(N)' record`s' not used because of missing values in `vars_opts'"
   replace `touse'=0 if `rmiss'>0 & `touse'
}

if "`agedob'"=="age" {
  count if `age'<=0 & `touse' // case_age<=0
  if r(N)>0  {
    if r(N)==1 local s=""
    else local s="s"
    noi di as txt "Note: `r(N)' record`s' not used because case's age <= 0"
    replace `touse'=0 if `age'<=0 & `touse'
  }
}
else { // "`agedob'"=="dob"
  count if `ddiag'<=`dob' & `touse' // case's date of diag <= case's date of birth
  if r(N)>0  {
    if r(N)==1 local s=""
    else local s="s"
    noi di as txt "Note: `r(N)' record`s' not used because case's date of diagnosis <= case's date of birth"
    replace `touse'=0 if `ddiag'<=`dob' & `touse'
  }
}


if "`casevars'"=="" preserve
keep if `touse'

if "`weight'"~="" {   
   bys `groupid': egen `min'=min(`exp')
   bys `groupid': egen `max'=max(`exp')   
   cap assert `min'==`max'
   if _rc~=0 {
      di as error "weights must be the same for all observations in a group"
	  exit 407
   }
   else {
      local ww="[`weight'=`exp']"
      if "`weight'"=="pweight" local w1="[iweight=`exp']"
      else local w1="`ww'"
	  drop `min' `max'
   }
}
else local ww=""


gen `case1'=cond(`case'==1,1,0) // case status
replace `case1'=. if `case'==.
lab define `caselab' 1 "Cases" 0 "Controls" 
lab values `case1' "`caselab'"
lab var `case1' "Case status"

recode `result' (1=1 "inadequate") (2=2 "negative") (3/max=3 "positive") (-1=-1 "adequate but not otherwise specified") (min/-2 0 .=.), gen(`oresult') // zero and values <=-2 are set to missing
label variable `oresult' "Result of screening test"
count if `result'==0 | `result'<=-2
if r(N)>1 local s="s"
else local s=""
if r(N)>0 {
noi di as text "Note: `r(N)' observation`s' with `result'= 0 or below -1 treated as missing"
}


local output_neg="yes"
count if `oresult'==-1
if r(N)>1 local s="s"
else local s=""
if r(N)>0 {
   local message_res="`r(N)' observation`s' with `result'=-1 (adequate but not otherwise specified)"   
   if "`nosresults'"=="" {
      noi di _n as error "`message_res' - you may want to specify the nosresults option"
	  exit
   }
   else {
      local output_neg="no"
	  noi di _n as text "Note: `message_res' - the analysis for the time-since-last-negative-test exposure will not be carried out"
   }	  
}

tokenize `agecutpoints'

gen `agegp'=1 if `age'>=`1' & `age'<`2'
label define `agelab' 1 "`1' to <`2' years"
macro shift
local i=2
while "`2'" !="" {
		replace `agegp'=`i' if `age'>=`1' & `age'<`2'
		label define `agelab' `i' "`1' to <`2' years", add
		macro shift
		local i=`i'+1
}
lab var `agegp' "Age group"
label val `agegp' `agelab'

sum `agegp'
if r(N)==0 {
   di as error "No observations when using agecutpoints(`agecutpoints')" // this situation arises when all obs in `agegp' are =.
   exit
}

gen `smearage'=(`scrdate' - `dob')/365.25


egen `i_use'= tag(`id') // generate a variable that identifies one line per woman

bysort `groupid': egen `date'=max(`ddiag')



*******************************************
* Time since last test
*******************************************

tempname postdiag2 lastsmear timelastsm tablsm lastneg timelastneg tab5neg

gen byte `postdiag2'=(`scrdate' > `date') | ((`date'- `scrdate') < ((365.25/12)*`anythreshold')) 
replace `postdiag2'=1 if `smearage'<`minage' | `smearage'>`maxage' | `oresult'==1 | `oresult'==.  // screen date outside the age range or inadequate/missing smear result

egen `lastsmear'=max(`scrdate' / !`postdiag2'), by(`id')
lab var `lastsmear' "Date of most recent adequate test (excluding `anythreshold' months)"

gen `timelastsm'=(`date'-`lastsmear')/365.25

gen `tablsm'=0 if `timelastsm'==.
lab var `tablsm' "Time since last test"

local i=1
tokenize `tlcutpoints'
while "`2'"!="" {
   replace `tablsm'=`i' if `timelastsm'>=`1' & `timelastsm'<`2'
   lab define `tablsm' `i' "`1' to <`2' yrs", add
   local i=`i'+1
   macro shift
}
replace `tablsm'=0 if  `timelastsm'>=`1'
lab define `tablsm' 0 "No adequate or >=`1'yrs", add
label values `tablsm' `tablsm'


*******************************************
* Time since last negative test 
*******************************************

replace `postdiag2'=(`scrdate'>`date') | ((`date'- `scrdate') < ((365.25/12)*`negthreshold'))  
replace `postdiag2'=1 if `smearage'<`minage' | `smearage'>`maxage' | `oresult'!=2 // screen date outside the age range or non-negative smear result

egen `lastneg'=max(`scrdate'/!`postdiag2'), by(`id')
lab var `lastneg' "Date of most recent negative test (excluding `negthreshold' months)"

gen `timelastneg'=(`date'-`lastneg')/365.25

gen `tab5neg'=0 if  `timelastneg'==.
lab var `tab5neg' "Time since last negative test"

local i=1
tokenize `tlcutpoints'
while "`2'"!="" {
	replace `tab5neg'=`i' if `timelastneg'>=`1' & `timelastneg'<`2'
	lab define `tab5neg' `i' "`1' to <`2' yrs", add
	local i=`i'+1
	macro shift
}
replace `tab5neg'=0 if  `timelastneg'>=`1'
lab define `tab5neg' 0 "No negative or >=`1'yrs", add
label values `tab5neg' `tab5neg'





********************************************
* Output
********************************************

foreach name in "Risk_of_cervical_cancer" "Time_since_last_test" ///
   "one_record_per_woman" "Case_status" "Last_screened_negative" {
	   capture drop `name'
}
 
gen Case_status= `case1'
gen one_record_per_woman = `i_use'
gen Time_since_last_test = `tablsm'
label val Time_since_last_test `tablsm'
gen Last_screened_negative = `tab5neg'
label var Last_screened_negative "Last screened negative"
label val Last_screened_negative `tab5neg'

if "`doctype'"=="word" {
   putdocx begin, font(, 11)
   putdocx paragraph, style(Title)
   putdocx text ("Results"), bold font(, 24)
   if "`noheader'"=="" {
      putdocx paragraph, style(Heading2)
      putdocx text ("audit_cc"), font(, 10, gray) linebreak
      putdocx text ("Stata `c(stata_version)'"), font(, 10, gray) linebreak
      putdocx text (trim(c(current_date))), font(, 10, gray)
   }
   putdocx paragraph, style(Heading1)
   putdocx text ("Time since last test"), bold
}

if "`doctype'"=="log" {
   cap log close `temp'
   log using "`saving'", `replace' name(`temp')
   if "`noheader'"=="" noi di as text _n " audit_cc" _n " Stata `c(stata_version)'" _n " " trim(c(current_date))
}

noisily {
    
*** output for time since last test

di as text _n "{c TLC}{hline 34}{c TRC}" _n ///
   "{c |} {col 35} {c |}" _n ///
   "{c |}{bf: Results by time since last test}  {c |}" _n ///
   "{c |} {col 35} {c |}" _n ///
   "{c BLC}{hline 34}{c BRC}"

tempname rtable H R

qui count if one_record_per_woman==1 & `agegp'~=.
qui return scalar N=r(N)  

qui levelsof `agegp', local(age_levels)


foreach i of local age_levels {
		
   if "`doctype'"=="word" {
      putdocx paragraph
      putdocx text (". "), bold font(, 30)
      putdocx text ("Age group: `: label `agelab' `i''"), bold //linebreak
   }
   
   di _n as text "{it:{hi:*** Age group: `: label `agelab' `i''}}" 
   local cmdline="clogit Case_status i.Time_since_last_test `ww' if one_record_per_woman==1 & `agegp'==`i', group(`groupid') `or'"
  
   if "`if'"~="" local cmdline2=subinstr("`cmdline'"," if "," if `if' & ",1)
   else local cmdline2="`cmdline'"
   
   local cmdline2=subinstr("`cmdline2'","`agegp'==`i'", `"agegroup=="`: label `agelab' `i''""',1)
   di _n as result `"`cmdline2'"'
   
   
   qui tab Case_status if one_record_per_woman & `agegp'==`i'
   if r(r)==0 {
   	 di as text "No observations" _n
     if "`doctype'"=="word" putdocx text ("No observations"), font(, 11)
   }
   
   if r(r)==1 {
     di as text "Model cannot be estimated because outcome does not vary in any group defined by `groupid'" _n
     if "`doctype'"=="word" putdocx text ("Model cannot be estimated because outcome does not vary in any group defined by `groupid'"), font(, 11)
   }
   
   
   if r(r)==2 {
       
     `cmdline'
	 
	  if "`doctype'"=="word" pdocx1 "Time since last test" tab`i'_est_lt `weight'
	  
	  if "`nodetail'"=="" {	  	
		 if "`weight'"=="fweight" {
		 	local wh=" (weighted using [`weight'=`exp'])"
			local wgt="`w1'"
		 }
		 else {
		 	local wh=""
			local wgt=""
		 }	
		 
		 di _n(2) as text "{bf: Observations retained in the estimation`wh'}"
		 tab `tablsm' `case1' `wgt'  if  e(sample)==1, matcell(`H') matrow(`R')
 	     di _n
			
         if "`doctype'"=="word" {
	        putdocx paragraph, indent(left, 0.5cm)
			putdocx text (" "), linebreak 
		    putdocx text ("Observations retained in the estimation`wh'"), bold font(, 11)
	        pdocx2 tab_lt_`i' Time_since_last_test `H' `R'
         }
      }
	  else di _n(2)
   }
}



*** output for time since last negative test

if "`output_neg'"=="yes" {

if "`doctype'"=="word" {
   putdocx paragraph, style(Heading1) spacing(before, 1.5cm) 
   putdocx text ("Time since last NEGATIVE test"), bold
}

di as text _n "{c TLC}{hline 42}{c TRC}" _n ///
   "{c |} {col 43} {c |}" _n ///
   "{c |}{bf: Results by time since last NEGATIVE test} {c |}" _n ///
   "{c |} {col 43} {c |}" _n ///
   "{c BLC}{hline 42}{c BRC}"


foreach i of local age_levels {

   if "`doctype'"=="word" {
      putdocx paragraph
      putdocx text (". "), bold font(, 30)
      putdocx text ("Age group: `: label `agelab' `i''"), bold
   }
   
   di _n as text "{it:{hi:*** Age group: `: label `agelab' `i''}}"
   local cmdline="clogit Case_status i.Last_screened_negative `ww' if one_record_per_woman==1 & `agegp'==`i', group(`groupid') `or'"

   if "`if'"~="" local cmdline2=subinstr("`cmdline'"," if "," if `if' & ",1)
   else local cmdline2="`cmdline'"
   
   local cmdline2=subinstr("`cmdline2'","`agegp'==`i'", `"agegroup=="`: label `agelab' `i''""',1)
   di _n as result `"`cmdline2'"'
   
   qui tab Case_status if one_record_per_woman & `agegp'==`i'
   
   if r(r)==0 {
   	 di as text "No observations" _n
     if "`doctype'"=="word" putdocx text ("No observations"), font(, 11)
   }
   
   if r(r)==1 {
     di as text "Model cannot be estimated because outcome does not vary in any group defined by `groupid'" _n
     if "`doctype'"=="word" putdocx text ("Model cannot be estimated because outcome does not vary in any group defined by `groupid'"), font(, 11)
   }
   
   if r(r)==2 {
       
      `cmdline'
	  
	  if "`doctype'"=="word" pdocx1 "Last screened negative" tab`i'_est_nt `weight'
	  
	  if "`nodetail'"=="" {
	      if "`weight'"=="fweight" {
		 	local wh=" (weighted using [`weight'=`exp'])"
			local wgt="`w1'"
		 }
		 else {
		 	local wh=""
			local wgt=""
		 }	
		 
		 di _n(2) as text "{bf: Observations retained in the estimation`wh'}"		
	        
         tab Last_screened_negative `case1' `wgt'  if  e(sample)==1, matcell(`H') matrow(`R')
		 di _n
   
         if "`doctype'"=="word" {
		 	putdocx paragraph
			putdocx text (" "), linebreak
		    putdocx text ("Observations retained in the estimation`wh'"), bold font(, 11)			
			pdocx2 tab_nres_`i' Last_screened_negative `H' `R'
	     }
      }
	  else di _n(2)
   }
}
}

if "`datasave'"~="" {
   cap drop agegroup  
   qui ren `agegp' agegroup
   qui keep if one_record_per_woman==1 & agegroup~=.
   if "`weight'"~="" {
	  cap drop weights
	  gen weights=`exp'
	  label var weights "weights"
	  local weight "weights"
   }
   qui keep `groupid' `id' Case_status agegroup Time_since_last_test Last_screened_negative `weight'
   order `groupid' `id' Case_status agegroup Time_since_last_test Last_screened_negative `weight'
   foreach v in Time_since_last_test Last_screened_negative agegroup {
      label var `v' "`=subinstr(lower("`v'"),"_"," ",.)'"
      local lab=substr(lower("`v'"),1,5)
      local labval: value label `v'
      label copy `labval' `lab', replace
      label val `v' `lab'
   }
   label var `groupid' "matched group id"
   label var `id' "woman id"
   label var Case_status "case status"
   label var agegroup "age group"
   if "`output_neg'"=="no" drop Last_screened_negative
   save "`datasave'", `datareplace'
}

 
if "`doctype'"=="word" putdocx save "`saving'", `replace'
if "`doctype'"=="log" qui log close `temp'
}


restore

}

ereturn clear
return local tlc_cutpoints "`tlcutpoints'"
return local age_cutpoints "`agecutpoints'"
return local cmdline `"audit_cc `0'"'
return local cmd "audit_cc"


end

***********************


cap program drop pdocx1
program def pdocx1
args what tab weight

tempname rtable
mat `rtable'= r(table)'
if c(showbaselevels)=="on" mat `rtable'=`rtable'[1...,1..6]
else mat `rtable'=`rtable'[2...,1..6]
		 
qui putdocx table `tab' = etable, width(100%) cellmargin(left, 10pt) cellmargin(right, 10pt) ///
   layout(autofitc) indent(1cm) border(top,)
		 
if "`weight'"=="pweight" {
   putdocx table `tab'(1,.), drop
   putdocx table `tab'(1,3)=("Robust SE")
}
		 
putdocx table `tab'(1,.), bold
putdocx table `tab'(.,1), italic halign(left)
putdocx table `tab'(2,1)=("`what'"), bold 
putdocx table `tab'(.,2/7), nformat(%9.3f) halign(center)
putdocx table `tab'(1,1) = ("")
putdocx table `tab'(.,4), drop
putdocx table `tab'(1,4)=("p-value"), bold halign(center)
putdocx table `tab'(1,5)=("95% conf. interval"), bold halign(center)
putdocx table `tab'(2,5), colspan(2)
		 

forval m=1/`=rowsof(`rtable')' {
   if `rtable'[`m',"pvalue"]<0.001 local pv="<0.001"
   else local pv: display %9.3f `rtable'[`m',"pvalue"]
   putdocx table `tab'(`=`m'+2',5), colspan(2)
			
   local beta=strofreal(`rtable'[`m',"b"],"%9.3f")
   putdocx table `tab'(`=`m'+2',2)=("`beta'"), halign(right)
			
   if `rtable'[`m',"se"]~=. { // SE
      local se=strofreal(`rtable'[`m',"se"],"%9.3f")
	  putdocx table `tab'(`=`m'+2',3)=("`se'"), halign(right)
   }
   else putdocx table `tab'(`=`m'+2',3)=("")
			
   if `rtable'[`m',"pvalue"]~=. { // p-value
      putdocx table `tab'(`=`m'+2',4)=("`pv'"), halign(right)
   }
   else putdocx table `tab'(`=`m'+2',4)=("")   
			   
   if `rtable'[`m',"ll"]~=. & `rtable'[`m',"ul"]~=. { // 95% CI
	  local c1=strofreal(`rtable'[`m',"ll"],"%9.3f")
	  local c2=strofreal(`rtable'[`m',"ul"],"%9.3f")              
	  putdocx table `tab'(`=`m'+2',5)=("(`c1', `c2')"), halign(right)
   }
   else putdocx table `tab'(`=`m'+2',5)=("")
}
	  
end


***********************

cap program drop pdocx2
program def pdocx2
args tabname var1 M Z

local r=rowsof(`M')
putdocx table `tabname' = matrix(`M'), rownames colnames layout(autofitc) ///
   indent(1cm) cellmargin(left,15pt) border(insideV, nil) border(insideH, nil) ///
   border(start, nil) border(end, nil)
putdocx table `tabname'(1,1) = ("")
putdocx table `tabname'(1,2) = ("Controls"), bold
putdocx table `tabname'(1,3) = ("Cases"), bold
putdocx table `tabname'(.,3), addcols(1, after)
putdocx table `tabname'(1,4) = ("Total"), bold

putdocx table `tabname'(`=`r'+1',.), addrows(2, after)
putdocx table `tabname'(`=`r'+2',1) = ("")
putdocx table `tabname'(`=`r'+3',1) = ("Total"), bold

local cum_freq1=0
local cum_freq2=0
forval j=1/`r' {
   local rlbl: label (`var1') `=`Z'[`j',1]'
   local i1=`j'+1
   putdocx table `tabname'(`i1',1) = (`"`rlbl'"'), italic
   putdocx table `tabname'(`i1',4) = (`=`M'[`j',1]+`M'[`j',2]')
   local cum_freq1=`cum_freq1'+`M'[`j',1]
   local cum_freq2=`cum_freq2'+`M'[`j',2]
}
putdocx table `tabname'(`=`r'+3',2) = ("`cum_freq1'")
putdocx table `tabname'(`=`r'+3',3) = ("`cum_freq2'")
putdocx table `tabname'(`=`r'+3',4) = ("`=`cum_freq1'+`cum_freq2''")

putdocx table `tabname'(.,2/4), halign(right) nformat(%16.0gc)

putdocx table `tabname'(1,.), addrows(1, after)
local vlab=subinstr("`var1'","_"," ",.)
putdocx table `tabname'(2,1) = (`"`vlab'"'), bold
putdocx table `tabname'(1,2/4), border(bottom)

end

