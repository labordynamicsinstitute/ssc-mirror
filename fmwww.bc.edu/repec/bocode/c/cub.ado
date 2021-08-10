********************************************************************************
*! "cub", v.28, Cerulli, 22may2021
********************************************************************************
*
********************************************************************************
* READ-ME
********************************************************************************
* This DO-file codes the following Stata commands:
********************************************************************************
* "cub"         // estimates the cub model
********************************************************************************
* "pr_pred_cub"   // estimates model predicted probability 
********************************************************************************
* "scattercub"  // produces the scatterplot of "Uncertainty" and "Feeling" for cub00
********************************************************************************
* "gr_prob_cub"  // produces the graph comparing the actual and the expected (or model) probabilities for cub00
********************************************************************************
*
********************************************************************************
* "get_hidden_prob": PROGRAM GENERATING PREDICTED PROBABILITIES BY CATEGORY   
********************************************************************************
* INPUTS:
* -> m = # of categories
* -> y = original target variable
* -> theta1 = variable of index parameters 1
* -> theta2 = variable of index parameters 2
********************************************************************************
program get_hidden_prob , eclass
********************************************************************************
args y m theta1 theta2 theta3
********************************************************************************
quietly{ // start quietly
local c = exp(lnfactorial(`m'-1))
local LEV_Y2 ""
forvalues i=1/`m'{
	local LEV_Y2 `LEV_Y2' `i'
}
tempname cmb2
mat `cmb2' = J(`m',1,.)
forvalues  i=1/`m'{
foreach j of local LEV_Y2 {
if `j'==`i'{	
  scalar d = (exp(lnfactorial(`j'-1))*exp(lnfactorial(`m'-`j')))
  mat `cmb2'[`i',1] = `c'/d
}
}
}
qui sum `theta1'
local T1=r(mean)
qui sum `theta2'
local T2=r(mean)
qui sum `theta3'
local T3=r(mean)
********************************************************************************
* WITHOUT SHELTER
********************************************************************************
if "`theta3'"==""{
preserve
clear
set obs `m'
gen _y=_n
tempvar p M R S
gen `p' = 1/(1+exp(-`T1')) 
gen `M' = `cmb2'[_y,1] 
gen `R' = ((exp(-`T2'))^(_y-1))/((1+exp(-`T2'))^(`m'-1)) 
gen `S' = 1/`m' 
tempvar prob_fitted
gen `prob_fitted' = (`p'*(`M'*`R'-`S')+`S')
keep _y `prob_fitted' 
tempfile NEW_PROB
save `NEW_PROB' , replace
restore
}
********************************************************************************
* WITH SHELTER
********************************************************************************
if "`theta3'"!=""{	
preserve
clear
set obs `m'
gen _y=_n
tempvar p M R S D delta
gen `p' = 1/(1+exp(-`T1')) 
gen `M' = `cmb2'[_y,1] 
gen `R' = ((exp(-`T2'))^(_y-1))/((1+exp(-`T2'))^(`m'-1)) 
gen `S' = 1/`m' 
quietly gen double `D'=(_y==`e(SHELTER)')  // new for shelter
quietly gen double `delta'= 1/(1+exp(-`T3'))  // new for shelter
tempvar prob_fitted
gen `prob_fitted' = (`delta'*`D' + (1-`delta')*(`p'*(`M'*`R'-`S')+`S')) // new for shelter
keep _y `prob_fitted' 
tempfile NEW_PROB
save `NEW_PROB' , replace
restore
}
********************************************************************************
* ACTUAL PROBABILITIES
********************************************************************************
tempvar prob_real
gen `prob_real'=1 
collapse (percent) `prob_real' , by(`y')
replace `prob_real'=`prob_real'/100
tempfile data1
save `data1' , replace
********************************************************************************
preserve
clear 
set obs `m'
tempfile dzero
gen _y =_n
save `dzero' , replace
use `data1' , clear
rename `y' _y
merge 1:1 _y using `dzero'
sort _y 
replace `prob_real'=0 if `prob_real'==.
drop _merge
tempfile data2
save `data2' , replace
merge 1:1 _y using `NEW_PROB' 
drop _merge
********************************************************************************
la var `prob_fitted' "Expected probabilities"
la var `prob_real' "Actual probabilities"
tempname M
mkmat `prob_fitted' `prob_real' , matrix(`M')
mat colnames `M' = fitted_prob actual_prob
qui levelsof _y , local(rnames)
mat rownames `M' = `rnames'
ereturn matrix M=`M'
} // end quietly
********************************************************************************
* DISPLAY ACTUAL VS. FITTED PROBABILITIES
********************************************************************************
noi di as text "{hline}"
noi matlist e(M) , rowt(`y') title("Actual vs. fitted probabilities")
noi di as text "{hline}"
restore
********************************************************************************
end
*
********************************************************************************
*! "cub14", v.28, Cerulli, 28may2021
********************************************************************************
*
********************************************************************************
* Code "cub14" and "cub14s" --> Likelihood Maximization via Stata "ml" (type "d0")
********************************************************************************
*
********************************************************************************
* CUB14 --> CUB14 (no-shelter)
********************************************************************************
cap program drop cub14
program cub14 , eclass
version 14.1
args todo b lnf
tempvar theta1 theta2
mleval `theta1' = `b', eq(1)
mleval `theta2' = `b', eq(2)
local y "$ML_y1" // this is just for readability
local m=e(M)
tempvar p M R S D
* Calculate p
quietly generate double `p' = 1/(1+exp(-`theta1'))
* Calculate M
local c = exp(lnfactorial(`m'-1))
tempname cmb
mat `cmb' = J(`m',1,.)
levelsof `y' , local(LEV_Y) 
*di in red "m = " `m'
*di in red "`LEV_Y'"
********************************************************************************
forvalues  i=1/`m'{
foreach j of local LEV_Y {
if `j'==`i'{	
  scalar d = (exp(lnfactorial(`j'-1))*exp(lnfactorial(`m'-`j')))
  mat `cmb'[`i',1] = `c'/d
}
}
}
********************************************************************************
qui gen double `M' = `cmb'[`y',1]
********************************************************************************
* Calculate R 
quietly generate double `R' = ((exp(-`theta2'))^(`y'-1))/((1+exp(-`theta2'))^(`m'-1))
* Calculate S
quietly generate double `S' = 1/`m'
mlsum `lnf' = ln(`p'*(`M'*`R'-`S')+`S')  
ereturn scalar M=`m'
end
********************************************************************************
*
********************************************************************************
*! "cub14s", v.28, Cerulli, 28may2021 (cub with shelter)
********************************************************************************
program cub14s , eclass
version 14.1
args todo b lnf
tempvar theta1 theta2 theta3
mleval `theta1' = `b', eq(1)
mleval `theta2' = `b', eq(2)
mleval `theta3' = `b', eq(3) // new for shelter
local y "$ML_y1" // this is just for readability
local m=e(M)
tempvar p M R S D delta
* Calculate p
quietly generate double `p' = 1/(1+exp(-`theta1'))
* Calculate M
local c = exp(lnfactorial(`m'-1))
tempname cmb
mat `cmb' = J(`m',1,.)
levelsof `y' , local(LEV_Y) 
********************************************************************************
forvalues  i=1/`m'{
foreach j of local LEV_Y {
if `j'==`i'{	
  scalar d = (exp(lnfactorial(`j'-1))*exp(lnfactorial(`m'-`j')))
  mat `cmb'[`i',1] = `c'/d
}
}
}
********************************************************************************
qui gen double `M' = `cmb'[`y',1]
********************************************************************************
* Calculate R 
quietly generate double `R' = ((exp(-`theta2'))^(`y'-1))/((1+exp(-`theta2'))^(`m'-1))
* Calculate S
quietly generate double `S' = 1/`m'
* Calculate D
quietly generate double `D'=(`y'==`e(SHELTER)')  // new for shelter
* Calculate delta
quietly generate double `delta'= 1/(1+exp(-`theta3'))  // new for shelter
mlsum `lnf' = ln(`delta'*`D' + (1-`delta')*(`p'*(`M'*`R'-`S')+`S'))  // new for shelter
ereturn scalar M=`m'
end
********************************************************************************
* END
********************************************************************************
*
********************************************************************************
* Main ADO-file --> "cub", v.28, Cerulli, 28may2021
********************************************************************************
capture program drop cub 
program cub , eclass sortpreserve
	version 14.1
	if replay()  {
		if ("`e(cmd)'" != "cub") {
		error 301
		}
		syntax [, Level(cilevel) ]
	    ml display, level(`level') eform
 	}
	else {
	qui{
        syntax varlist(max=1) [if] [in] [fweight pweight]  [, graph outname(string) save_graph(string) prob(name) m(numlist max=1) vce(passthru) Level(cilevel) Eform pi(varlist numeric fv ts) xi(varlist numeric fv ts) shelter(numlist max=1) * ]  
		// * adds other options    without returning an error
		mlopts mlopts , `options'  // Since the optins included in * are available in the macro `options', this line tells Stata to add into mplots also the options in *
		************************************************************************
		* WARNING 1
		************************************************************************
		if ("`prob'"=="") & ("`graph'"!=""){
		di as text ""
		di in red "{bf:*********************************************************************}"
		di in red "{bf:WARNING: Option 'graph' available only if option 'prob' is specified }"
		di in red "{bf:*********************************************************************}"
		exit
		} 
		************************************************************************
		* WARNING 2
		************************************************************************
		if "`save_graph'"!="" & "`graph'"==""{
		di as text ""
		di in red "{bf:************************************************************************}"
		di in red "{bf:WARNING: Option 'save_graph' can be used only if option 'graph' is used }"
		di in red "{bf:************************************************************************}"
		exit
		} 
		************************************************************************
		* MAIN PROGRAM
        ************************************************************************	    
		if "`weight'"!=""{
		local wgt "[`weight'`exp']"
		}
        ************************************************************************		
		marksample touse
		************************************************************************
		* Model with sheleter (cub14s) or without shelter (cub14)
		************************************************************************
		if "`shelter'"!=""{
		ereturn local SHELTER=`shelter'
		ml model d0 cub14s (pi_beta: `varlist' = `pi') (xi_gamma: `xi') (lambda:) `wgt' if `touse', `vce' `mlopts' 
		}
		else if "`shelter'"==""{
		ml model d0 cub14 (pi_beta: `varlist' = `pi') (xi_gamma: `xi') `wgt' if `touse', `vce' `mlopts'
		}
		************************************************************************
		if "`m'"!=""{
		ereturn scalar M=`m'
		}
		else if "`m'"==""{
		tempvar max_y
		egen `max_y'=max(`varlist')
		qui sum `max_y'
		local m=r(mean)
		ereturn scalar M=`m'
		}
		************************************************************************
		ml maximize
	    ereturn local cmdline `"`0'"'
		ereturn local cmd "cub"
		************************************************************************
		}
	    }
	    ml display, level(`level') neq(3) `eform' 
		di as text "The number of categories of variable `varlist' is M = " `m'
		di "{hline 78}"
		************************************************************************
        * Estimates of 'pi' and 'xi', and 'delta'
		************************************************************************
		
		************************************************************************
		if ("`pi'" == "") & ("`xi'" == ""){
		************************************************************************
		if "`m'"!=""{
		ereturn scalar M=`m'
		}
		else if "`m'"==""{
		tempvar y2
		qui tostring `varlist' , gen(`y2')
		qui levelsof `y2',  local(mylevs)
		qui local m : word count `mylevs'
		ereturn scalar M=`m'
		}
		************************************************************************
		di as text ""
		di as text "{hline}"
		di as text "{bf:******************************************************************************}"
		di as text "{bf:*************** Estimates of 'pi', and 'xi' **********************************}"
		di as text "{bf:******************************************************************************}"
		tempname A B C
		nlcom (pi: 1/(1+exp(-_b[pi_beta:_cons])))
		mat `A'=r(b)
		ereturn matrix pi=`A'
		nlcom (xi: 1/(1+exp(-_b[xi_gamma:_cons])))
		mat `B'=r(b)
		ereturn matrix xi=`B'
				di as text "{bf:******************************************************************************}"
		************************************************************************
		}
		if "`shelter'"!=""{
		ereturn local SHELTER=`shelter'
		di as text ""
		di as text "{hline}"
		di as text "{bf:******************************************************************************}"
		di as text "{bf:******** Estimation of the shelter parameters 'delta'  **********************}"
		di as text "{bf:******************************************************************************}"
		* Delta
		tempname C
		nlcom delta: 1/(1+exp(-_b[lambda:_cons]))
		mat `C'=r(b)
		ereturn matrix delta=`C'
				}
********************************************************************************
* ESTIMATE THE EXPECTED PROBABILITIES
********************************************************************************
if "`prob'"!=""{
********************************************************************************
tempvar theta1 
predict `theta1' , equation(pi_beta)   
tempvar theta2 
predict `theta2' , equation(xi_gamma)
********************************************************************************
* EXPECTED PROBABILITY WITHOUT SHELTER
********************************************************************************
tempvar p M R S
quietly generate double `p' = 1/(1+exp(-`theta1')) if `touse'
local c = exp(lnfactorial(`m'-1))
local y `varlist'
qui levelsof `y' , local(LEV_Y) 
********************************************************************************
tempname cmb
mat `cmb' = J(`m',1,.)
forvalues  i=1/`m'{
foreach j of local LEV_Y {
if `j'==`i'{	
  scalar d = (exp(lnfactorial(`j'-1))*exp(lnfactorial(`m'-`j')))
  mat `cmb'[`i',1] = `c'/d
}
}
}
********************************************************************************
* EXPECTED PROBABILITY WITHOUT SHELTER
********************************************************************************
if "`shelter'"==""{
qui gen double `M' = `cmb'[`y',1] if `touse'
quietly generate double `R' = ((exp(-`theta2'))^(`y'-1))/((1+exp(-`theta2'))^(`m'-1)) if `touse'
quietly generate double `S' = 1/`m' if `touse'
cap drop `prob'
gen `prob' = (`p'*(`M'*`R'-`S')+`S') if `touse'
********************************************************************************
* GENERATE A MATRIX "M" WITH EXPECTED AND ACTUAL PROBABILITIES BY CATEGORY
********************************************************************************
preserve
tempvar theta1 
predict `theta1' , equation(pi_beta)   
tempvar theta2 
predict `theta2' , equation(xi_gamma) 
get_hidden_prob `y' `m' `theta1' `theta2'
restore
}
********************************************************************************
* EXPECTED PROBABILITY WITH SHELTER
********************************************************************************
if "`shelter'"!=""{
qui gen double `M' = `cmb'[`y',1] if `touse'
quietly generate double `R' = ((exp(-`theta2'))^(`y'-1))/((1+exp(-`theta2'))^(`m'-1)) if `touse'
quietly generate double `S' = 1/`m' if `touse'
cap drop `prob'	
tempvar D
qui generate double `D'=(`y'==`e(SHELTER)')  if `touse' // new for shelter
local DELTA=1/(1+exp(-_b[lambda:_cons]))
cap drop `prob'
gen `prob' = (`DELTA'+(1-`DELTA')*(`p'*(`M'*`R'-`S')+`S'))*`D' ///
+ (1-`D')*(1-`DELTA')*(`p'*(`M'*`R'-`S')+`S')  if `touse' // new for shelter
********************************************************************************
* GENERATE A MATRIX "M" WITH EXPECTED AND ACTUAL PROBABILITIES BY CATEGORY
********************************************************************************
preserve
tempvar theta1 
predict `theta1' , equation(pi_beta)   
tempvar theta2 
predict `theta2' , equation(xi_gamma) 
tempvar theta3 
predict `theta3' , equation(lambda) 
get_hidden_prob `y' `m' `theta1' `theta2' `theta3'
restore
}
********************************************************************************
} // end if on 'prob'
********************************************************************************
* GRAPH ACTUAL VS. PREDICTED PROBABILITIES
********************************************************************************
if "`graph'"!=""{
preserve
qui{ // start quietly
clear
mat A=e(M)
svmat A , names(col)
la var fitted_prob "Fitted probabilities"
la var actual_prob "Actual probabilities"
gen _y=_n
local y1 "_y"
local prob "fitted_prob"
local prob_real "actual_prob"
} // end quietly
********************************************************************************
set scheme s1mono
********************************************************************************
if ("`outname'"=="" & "`shelter'"==""){
tw (connected `prob' `y1' , xtitle("") xlabel(1(1)`m')) ///
(connected `prob_real' `y1') , note("Outcome = `y'" "Shelter = Not specified") ///
name(gr_pred , replace) 
}
if ("`outname'"=="" & "`shelter'"!=""){
tw (connected `prob' `y1' , xtitle("") xlabel(1(1)`m')) ///
(connected `prob_real' `y1') , note("Outcome = `y'" "Shelter = `shelter'") ///
name(gr_pred , replace) 
}
if ("`outname'"!="" & "`shelter'"==""){
tw (connected `prob' `y1' , xtitle("") xlabel(1(1)`m')) ///
(connected `prob_real' `y1') , note("Outcome = `outname'" "Shelter = Not specified") ///
name(gr_pred , replace) 
}
else if ("`outname'"!="" & "`shelter'"!=""){
tw (connected `prob' `y1' , xtitle("") xlabel(1(1)`m')) ///
(connected `prob_real' `y1') , note("Outcome = `outname'" "Shelter = `shelter'") ///
name(gr_pred , replace) 
}
if "`save_graph'"!=""{
graph save `save_graph' , replace
}
********************************************************************************
restore
********************************************************************************
} // end if on 'graph'
********************************************************************************
end
********************************************************************************
