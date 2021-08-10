********************************************************************************
* "cub", v.25, Cerulli, 03dic2020
********************************************************************************
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
		ml model d0 cub14s (pi_beta: `varlist' = `pi') (xi_gamma: `xi') (delta:) `wgt' if `touse', `vce' `mlopts' 
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
	    ml display, level(`level') neq(2) `eform' 
		di as text "The number of categories of variable `varlist' is M = " `m'
		di "{hline 78}"
		************************************************************************
        * Estimates of 'pi' and 'xi', and 'lambda'
		************************************************************************
		if "`shelter'"!=""{
		ereturn local SHELTER=`shelter'
		di as text ""
		di as text "{hline}"
		di as text "{bf:******************************************************************************}"
		di as text "{bf:******** Estimation of the shelter parameters 'lambda' and 'delta' ***********}"
		di as text "{bf:******************************************************************************}"
		* Lambda
		tempname C
		nlcom lambda: ln(_b[delta:_cons]/(1-_b[delta:_cons]))
		mat `C'=r(b)
		ereturn matrix lambda=`C'
		* Delta
		tempname C
		nlcom delta: _b[delta:_cons]
		mat `C'=r(b)
		ereturn matrix delta=`C'
		}
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
		di as text "{bf:*************** Estimates of 'pi' and 'xi' ***********************************}"
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
qui gen double `M' = `cmb'[`y',1] if `touse'
quietly generate double `R' = ((exp(-`theta2'))^(`y'-1))/((1+exp(-`theta2'))^(`m'-1)) if `touse'
quietly generate double `S' = 1/`m' if `touse'
cap drop `prob'
gen `prob' = (`p'*(`M'*`R'-`S')+`S') if `touse'
********************************************************************************
* EXPECTED PROBABILITY WITH SHELTER
********************************************************************************
if "`shelter'"!=""{
tempvar D
qui generate double `D'=(`y'==`e(SHELTER)')  if `touse' // new for shelter
cap drop `prob'
local DELTA=_b[delta:_cons]
gen `prob' = (`DELTA'+(1-`DELTA')*(`p'*(`M'*`R'-`S')+`S'))*`D' ///
+ (1-`D')*(1-`DELTA')*(`p'*(`M'*`R'-`S')+`S')  if `touse' // new for shelter
}
********************************************************************************
* GENERATE A MATRIX "M" WITH EXPECTED AND ACTUAL PROBABILITIES BY CATEGORY
********************************************************************************
tempfile data1 
********************************************************************************
qui{  // start quietly
********************************************************************************
* GENERATE ACTUAL PROBABILITIES BY CATEGORY  
********************************************************************************
preserve
tempvar prob_real
gen `prob_real'=1 if `touse'
collapse (percent) `prob_real' if `touse' , by(`y')
replace `prob_real'=`prob_real'/100
save `data1' , replace
restore
********************************************************************************
* GENERATE EXPECTED PROBABILITIES BY CATEGORY  
********************************************************************************
preserve
collapse `prob' if `touse' , by(`y')   // takes the average over each category
merge 1:1 `y' using `data1'
********************************************************************************
* PUT EXPECTED AND ACTUAL PROBABILITIES INTO MATRIX "M"  
********************************************************************************
la var `prob' "Expected probabilities"
la var `prob_real' "Actual probabilities"
tempname M
mkmat `prob' `prob_real' , matrix(`M')
mat colnames `M' = fitted_prob actual_prob
qui levelsof `y' , local(rnames)
mat rownames `M' = `rnames'
ereturn matrix M=`M'
********************************************************************************
* DISPLAY ACTUAL VS. FITTED PROBABILITIES
********************************************************************************
noi di as text "{hline}"
noi matlist e(M) , rowt(`y') title("Actual vs. fitted probabilities")
noi di as text "{hline}"
********************************************************************************
* GRAPH ACTUAL VS. PREDICTED PROBABILITIES
********************************************************************************
if "`graph'"!=""{
********************************************************************************
set scheme s1mono
********************************************************************************
if ("`outname'"=="" & "`shelter'"==""){
tw (connected `prob' `y' , xtitle("") xlabel(1(1)`m')) ///
(connected `prob_real' `y') , note("Outcome = `y'" "Shelter = Not specified") ///
name(gr_pred , replace) 
}
if ("`outname'"=="" & "`shelter'"!=""){
tw (connected `prob' `y' , xtitle("") xlabel(1(1)`m')) ///
(connected `prob_real' `y') , note("Outcome = `y'" "Shelter = `shelter'") ///
name(gr_pred , replace) 
}
if ("`outname'"!="" & "`shelter'"==""){
tw (connected `prob' `y' , xtitle("") xlabel(1(1)`m')) ///
(connected `prob_real' `y') , note("Outcome = `outname'" "Shelter = Not specified") ///
name(gr_pred , replace) 
}
else if ("`outname'"!="" & "`shelter'"!=""){
tw (connected `prob' `y' , xtitle("") xlabel(1(1)`m')) ///
(connected `prob_real' `y') , note("Outcome = `outname'" "Shelter = `shelter'") ///
name(gr_pred , replace) 
}
if "`save_graph'"!=""{
graph save `save_graph' , replace
}
********************************************************************************
restore
********************************************************************************
} // end if on 'graph'
} // end quietly
} // end if on 'prob'
********************************************************************************
end
********************************************************************************
