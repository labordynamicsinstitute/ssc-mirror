* Version 1:0 25-03-2021 

cap prog drop winratio
prog winratio , rclass 
syntax varlist(min=2 max=2) [if] , outcomes(string) [ strata(varname) strata_method(string)  PFormat(string)  WRFormat(string) ]

version 12.0
preserve 

tokenize `varlist'
local idvar `1'
local trtvar `2'

if "`if'"~="" {
	keep `if' 
	}
	
if "`wrformat'"=="" {
	local wrformat %03.2f
	}
if "`pformat'"=="" {
	local pformat %05.4f
	}

* -----------------------------------------------
* Checks
* -----------------------------------------------
* Check elements in `outcomes' is a multiple of 3
local comp_n=wordcount("`outcomes'")/3 
if `comp_n'!=round(`comp_n') {
	di in r "Wrong number of elements in outcomes option"
	exit
	}

if "`strata'"!="" & "`strata_method'"=="" {
	local strata_method="unweighted"
	}
	
if "`strata'"!="" & !inlist("`strata_method'", "IV", "MH", "unweighted") {
	di in r "Invalid option for strata_method"
	exit
	}
	
qui sum `trtvar'
if r(min)!=0 | r(max)!=1 {
	di in r "Treatment group variable should be 0/1"
	exit	
	}
qui duplicates report `idvar' 
if r(unique_value)!=r(N) {
    di in r "Duplicate or missing values in ID variable"
	exit
	}
qui count if missing(`idvar')
if r(N)>0 {
	di in r "Missing values in ID variable"
	exit
	}
* local outlist="`outcomes'"   // needed? 
* What other checks needed?


* ------------------------------------------------
* Separate components into c outcomes, types, time/direction vars  
* ------------------------------------------------
forvalues c=1/`comp_n' {

gettoken x outcomes:outcomes
local outvar `outvar' `x'
gettoken y outcomes:outcomes
	if inlist("`y'", "c", "tf", "ts", "r")!=1 {
		di in r "Type should be one of c, tf, ts, r" 
		exit 
		}
local type `type' `y'
gettoken z outcomes:outcomes
local tdvar `tdvar' `z'
if "`z'"!="<" & "`z'"!=">" {
	local tdvarlist `tdvarlist' `z'
	}
}

forvalues c=1/`comp_n' {
	local out`c':word `c' of `outvar'
	local type`c':word `c' of `type'
	local tdvar`c':word `c' of `tdvar'
	}

* -----------------------------------------------
* Loop through program once if unstratified
* or M times if stratified
* -----------------------------------------------
local TotalWeight=0

if "`strata'"~="" {
	qui levelsof `strata' , local(M)
	local nstrata=r(r)
	}

else {
	local M=1
	}

foreach m of numlist `M' {

	if "`strata'"!="" {
	local stratlab:label (`strata') `m' 
	qui keep if `strata'==`m'
	}

* ------------------------------------------
* Number overall, per group and comparisons 
* for output later
* ------------------------------------------
qui count
	local NP=r(N)
qui tab `idvar' if `trtvar'==0
	local NP0=r(r)
qui tab `idvar' if `trtvar'==1
	local NP1=r(r)
	local Ncomps=`NP0'*`NP1'

* -----------------------------------
* Cross dataset (full cross)
* -----------------------------------
tempfile file_j
rename * *_j
qui save `file_j'	 
rename *_j *_i
cross using `file_j'

* ------------------------------------------------
* Loop through i outcomes in sequence-creating 
* a comp`i' variable for each 
* ------------------------------------------------
forvalues i=1/`comp_n' {
	decide_winner, out(`out`i'') type(`type`i'') tdvar(`tdvar`i'') i(`i') 
	}	
* --------------------------------------------
* Create single variable u_ij containing WLT 
* across hierarchy of components
* -------------------------------------------- 
qui gen u_ij=comp1

* Wins/Losses at level 1
qui count if u_ij==1 & (`trtvar'_i==1 & `trtvar'_j==0)
	local w1=r(N)
qui count if u_ij==-1 & (`trtvar'_i==1 & `trtvar'_j==0)
	local l1=r(N)

local wcum=`w1'
local lcum=`l1'

* Replace untied values with wins/losses at subsequent levels
forvalues i=2/`comp_n' {
	qui replace u_ij=comp`i' if u_ij==0

* Count wins/losses at levels 2,3,...
	qui count if u_ij==1 & (`trtvar'_i==1 & `trtvar'_j==0)
	local w`i'=r(N)-`wcum'
	qui count if u_ij==-1 & (`trtvar'_i==1 & `trtvar'_j==0)
	local l`i'=r(N)-`lcum'
	local wcum=`wcum'+`w`i''
	local lcum=`lcum'+`l`i''
	}

* Final ties (includes possibilty of u_ij being missing if
* missing values in outcomes)
qui count if inlist(u_ij, 0 , .) & (`trtvar'_i==0 & `trtvar'_j==1)
	local ties`m'=r(N)

* ---------------------------------------
* For Win Ratio compare wins/losses 
* only for Trt_1 v Trt_2 comparisons
* ---------------------------------------
qui count if u_ij==1 & (`trtvar'_i==1 & `trtvar'_j==0)
	local W`m'=r(N)
qui count if u_ij==-1 & (`trtvar'_i==1 & `trtvar'_j==0)
	local L`m'=r(N)
	local wr`m'=`W`m''/`L`m''

* ------------------------------------------------
* P-value/asymptotic CI
* ------------------------------------------------
* Step 1: calculate u_i for each person 
* 		 i.e. sum of u_ij for j=1 to N 
* ------------------------------------------------
qui bysort `idvar'_i:egen u_i=sum(u_ij)
qui bysort `idvar'_i:keep if _n==1  
* ------------------------------------------------
* Step 2: calculate T = sum(u_i x d_i) where d_i 
*         is 1 if patient in active group 
*		  T is single value (not variable) 
* ------------------------------------------------
egen T=sum(u_i*(`trtvar'_i==1))
* ------------------------------------------------
* Step 3: Variance = (N1xN2)/(Nx(1-N))xSum(u_i^2)
* ------------------------------------------------
qui gen u_isq=u_i^2 if `trtvar'_i==1
qui egen U_isq=sum(u_i^2)
qui sum U_isq
	local sumUisq=r(max)
qui count if `trtvar'_i==0
	local N1=r(N)
qui count if `trtvar'_i==1
	local N2=r(N)
	local N=`N1'+`N2'
	local V`m'=(`N1'*`N2')/(`N'*(`N'-1))*`sumUisq'

* -----------------------------------------------
* Step 4: calculate Z = T/sqrt(V)  -> p-value
* ------------------------------------------------
qui sum T 
	local T`m'=r(max)
local z=`T`m''/sqrt(`V`m'')
local p=2*(1-normal(abs(`z')))
local pstr=string(`p',"`pformat'") 

* -----------------------------------------
* Step 5: Approximate 95% CI 
* -----------------------------------------
* See supplement to EHJ win ratio paper

local logwr`m'=log(`wr`m'')
local s`m'=`logwr`m''/`z'
* di "Null standard error estimate: `s`m''" // do we need this? could add to return list
local ll=string(exp(`logwr`m''-1.96*`s`m''),"`wrformat'")
local ul=string(exp(`logwr`m''+1.96*`s`m''),"`wrformat'")
local ci "(`ll', `ul')"

local wrrep`m'=string(`wr`m'', "`wrformat'")

* -------------------------------------
* Output
* -------------------------------------
if `m'==1 {
di in smcl in gr "{hline 60}
}

if "`strata'"!="" {
disp in gr "Strata: `stratlab'"
di in smcl in gr "{hline 60}
}

di "Total number of patients: " _col(35) `NP'
di "Number in control group: " _col(35) `NP0'
di "Number in active group: " _col(35) `NP1'
di "Number of comparisons: " _col(35) `Ncomps' 

di in smcl in gr "{hline 60}
di _col(20) "Wins"  _col(30) "Losses" _col(40) "Ties"
di in smcl in gr "{hline 60}

forvalues j=1/`comp_n' {
di "Outcome `j'" _col(20) `w`j''  _col(30) `l`j''
}

di in smcl in gr "{hline 60}
di "Total" _col(20) `W`m''  _col(30) `L`m'' _col(40) `ties`m''
di in smcl in gr "{hline 60}

di "Win Ratio: `wrrep`m'', 95% CI`ci' P=`pstr'"
di in smcl in gr "{hline 60}

*-----------------------------------------
*Defining strata weights
*-----------------------------------------
if "`strata_method'"=="unweighted"  {
	* di "Calculating unweighted weights"
	local weight`m'=1	
	local TotalWeight=`TotalWeight'+`weight`m''	
	}
if "`strata_method'"=="MH" {
	* di "Calculating MH weights"
	local weight`m'=1/`N'
	local TotalWeight=`TotalWeight'+`weight`m''	
	}
if "`strata_method'"=="IV" {
	* di "Calculating IV weights"
	local weight`m'=1/`V`m''
	local TotalWeight=`TotalWeight'+`weight`m''	
	}

restore , preserve  
}  // end of strata loop 



*-------------------------------------
* Stratified WR
* -------------------------------------
if "`strata'"!="" {
	local wsum=0
	local lsum=0
	local Tsum=0
	local Vsum=0
	local vstrat=0
	
foreach m of local M {
* Weighted sum of winners
	local wsum=`wsum'+`weight`m''*`W`m''	
* Weighted sum of losers 
	local lsum=`lsum'+`weight`m''*`L`m''	
	
* Alternative methodology as per ATTRACT/PARTNER trials
* Calculate sum of test statistic and sum of variance of test statistic and use this
if "`strata_method'"=="unweighted" {
	local Tsum=`Tsum'+`T`m''
	local Vsum=`Vsum'+`V`m''
	}
	
	local ScaledWeight`m'=`weight`m''/`TotalWeight'          
	local var_contrib=`ScaledWeight`m''^2 * `s`m''^2
	local vstrat=`vstrat'+`var_contrib'  
	}	

*For unweighted win ratio the p-value is calculated by taking the sum of test statistics
*and comparing to the sum of variances. 
*This approach has been used in ATTR-ACT (N Engl J Med 2018; 379:1007-1016) and PARTNER trials 
if "`strata_method'"=="unweighted" {
	local wrstrat=`wsum'/`lsum'
	local z=`Tsum'/sqrt(`Vsum')
	local p=2*(1-normal(abs(`z')))
	local pstr=string(`p',"`pformat'") 
	local se_logwr=log(`wrstrat')/`z'
	local lci=string(exp(log(`wrstrat')-1.96*`se_logwr'),"`wrformat'")
	local uci=string(exp(log(`wrstrat')+1.96*`se_logwr'),"`wrformat'")
	}	

*For MH or IV weighting the p-value is calculated from the weighted null standard error 
if "`strata_method'"!="unweighted" {
	local wrstrat=`wsum'/`lsum'
	local se_logwr=sqrt(`vstrat')
	local z=log(`wrstrat')/`se_logwr'
	local p=2*(1-normal(abs(`z')))
	local pstr=string(`p',"`pformat'") 
	local lci=string(exp(log(`wrstrat')-1.96*`se_logwr'),"`wrformat'")
	local uci=string(exp(log(`wrstrat')+1.96*`se_logwr'),"`wrformat'")
	}



local wrstrat1=string(`wrstrat' , "`wrformat'")

disp "Stratified Win Ratio: `wrstrat1' 95% CI (`lci', `uci') P=`pstr'"
di in smcl in gr "{hline 60}	
	
}

* ---------------------------------------
* Returned values 
* ---------------------------------------
if "`strata'"!="" {
foreach i of numlist `M'  {
	return scalar wr`i' = `wr`i''
	return scalar se`i' = `s`i''
	}
	}
	
if "`strata'"!="" {
	return scalar wr = `wrstrat'
	return scalar se_logwr = `se_logwr'
	}

if "`strata'"=="" {
	return scalar wr = `wr1'
	return scalar se_logwr = `s1'
	}
	
return scalar p = `p'

* ---------------------------------------

end 






