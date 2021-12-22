
capture program drop vbkw_main
program define vbkw_main, sortpreserve rclass
        version 14.2
        #delimit ;
        syntax varlist(min=2 fv) [if] [in], 
		OUTcome(varlist)
        [Kerneltype(string)
        BWidth(string)
        NOCOMmon
        MPROBIT
		logitps
		SDBWidth(string)
		NOsave
		bstrap
		nreps(integer 300)
        ];
        #delimit cr
********************************************************************************

preserve
        // record sort order
        tempvar order
        g long `order' = _n
		
		/*
capture confirm var treat
if _rc == 0 {
	g treat = `1'
	local 1 = treat 
	}
	*/
	
********************************************************************************
        // clean up data: these are empty varnames which i will use later for _ATTsupport _ATTweight etc.
		tokenize `varlist'
		gettoken treat xvars : varlist
		di "`treat'"
		di "`xvars'"
		_fv_check_depvar `treat'
		*local nx : list sizeof xvars
		levelsof `treat', local(levels)
		di "`levels'"
		di r(levels)
		tab `treat'
		local n_cat = r(r)
		di "`n_cat'"
		
********************************************************************************
        if ("`outcome'"!="") {
                foreach v of varlist `outcome' {
                        cap drop _`v'
                        local moutvar `moutvar' _`v'
						
                }
        }
		di "`moutvar'"
		g vbkw_outcome = `outcome'
********************************************************************************
        // determine subset we work on
        marksample touse
        capture markout `touse' `outcome'
		//markout makes it so that obs in the vars of varlist or outcome that are missing aren't used in the program. 
		tab `touse'


********************************************************************************		
		
 // check kerneltype: default kerneltype is set to epanechnikov kernel. 
        if ("`kerneltype'"=="") local kerneltype "epan"
		di "kerneltype is: `kerneltype'"
 // if kerneltype is specified but it's not one of these options: normal, epan, biweight, uniform, tricube, then display an error message. 
        if !("`kerneltype'"=="" | "`kerneltype'"=="normal" | "`kerneltype'"=="epan" | "`kerneltype'"=="biweight" | "`kerneltype'"=="uniform" | "`kerneltype'"=="tricube") {
                di as error "Kerneltype `kerneltype' not recognized"
                exit 198
        }
		
//if kerneltype() isn't specified as an option such as if i type "vbkw treat x1 x2 x3", then the macro kerneltype will still be "epan"
//the two versions of implementation both set kerneltype to be "epan": 
//vbkw treat x1_v2 x2 x3 
//vbkw treat x1_v2 x2 x3, kerneltype()

********************************************************************************
        // estimate propensity score: confounders are required to be specified after the treatment var.
		//if mprobit is missing, the default is mlogit estimation of pscores. 

		forval i = 1/`n_cat'{
		cap drop ps`i'
		}
		
        if ("`varlist'"!="") {
                if ("`mprobit'"=="") {
				//default is mlogit
                    local mprobit "mlogit"
                }
				di "ps estimated with `mprobit'"
				tab `treat'
				local n_cat = r(r)
				di "`n_cat'"
				
                `mprobit' `treat' `xvars' if `touse', nolog
                qui replace `touse' = e(sample) // XX with factor vars some obs may be dropped because they predict failure perfectly
               
			levelsof `treat', local(levels)
			tokenize `levels'   
			
			if `n_cat' == 3 {
			qui predict double ps`1' ps`2' ps`3' if e(sample)
			}
			if `n_cat' == 4 {
			qui predict double ps`1' ps`2' ps`3' ps`4' if e(sample)
			}
			if `n_cat' == 5 {
			qui predict double ps`1' ps`2' ps`3' ps`4' ps`5' if e(sample)
			}
        }		
capture markout `touse' ps*

sum ps* 

/*
forval i = 1/`n_cat' {
	local varlab`i' : var label _ps`i'
	local temp`i' : subinstr local varlab`i' ")" "", all
	local temp`i' : subinstr local temp`i' "Pr(treat==" "", all
	
	di "`temp`i''"
	clonevar ps`temp`i'' = _ps`i'
}
*/



 *drop _ps*

********************************************************************************

// common support as default: common support using the pscores (not the logit of pscores) 
cap drop _support 
g byte _support = 1 if `touse'
tab _support
di "the number of nonmissing obs based on each of `treat'`xvars' is `r(N)'"

	levelsof `treat', local(levels)
	foreach i of local levels{
	local min `min' min`i'	
	}
	*di "`min'"
	local min: subinstr local min " " ", ", all
	di "`min'"
	
	
	levelsof `treat', local(levels)
	foreach i of local levels{
	local max `max' max`i'	
	}
	*di "`max'"
	local max: subinstr local max " " ", ", all
	di "`max'"
		levelsof `treat', local(levels)
if ("`nocommon'" == "") {
	di "Common support is applied"
	foreach i in `levels' {
		foreach j in `levels' {
			qui sum ps`i' if `treat' == `j'
			scalar min`j' = r(min)
			scalar max`j' = r(max) 
			}
		scalar maxofmin = max(`min')
		scalar minofmax = min(`max')
		di maxofmin
		di minofmax
		qui replace _support = 0 if ps`i' < maxofmin | ps`i' > minofmax
		}

*Drop units outside the common support. added a preserve statement 
*because i don't want users of this to lose data by accident. 
*preserve 
keep if _support == 1
*if nocommon is specified, _support will = 1 for all observations

}

replace `touse' = . if _support != 1 
tab _support `touse'
tab `touse' `treat' if _support == 1
di "the number of nonmissing obs based on each of `treat'`xvars', and subjects on common support is `r(N)'  "



	foreach i in `levels'{
	qui count if `treat' == `i' & _support == 1 
	scalar Nsupport_`i' = r(N)
	scalar list Nsupport_`i'
}
	
	qui count if _support == 1 
	scalar N = r(N)
	scalar list N
	
********************************************************************************


*this is our unique identifier to be used later on in order to control sort order
*appropriately so that results may be replicable and sort order of data when 
*using one method does not influence the performance of subsequent methods.  
cap drop id 
g id = _n if `touse'

count if id != . 

********************************************************************************
*logit of pscores
*default is that raw pscores are used. if logit of pscores are desired, "logitps" option must be specified by the user. 


if ("`logitps'"!="") {
	foreach i in `levels'{
	replace ps`i' = logit(ps`i') if `treat' !=. 
}
}
********************************************************************************
*bandwidth(choose a default, allow for user-specified fixed bw, 
*or user-specified bw based on sd of pscore or sd of logit of pscore. 

di "bwidth is string: `bwidth'" 
di "sdbwidth is string: `sdbwidth'"
//as is currently specified in syntax as BWidth(string), and SDBWidth(string), we see that 
//these locals both hold the value of "" if it's not specified by the user. 

*1. provide error message if both are specified:
if ("`bwidth'" != "" & "`sdbwidth'" != "") {
	di as error "User cannot specify bwidth() and sdbwidth() simultaneously."
	exit 198
}

*2. choose a default bandwidth if none are specified: sd(logit(ps)) (if logitps is specified), or logit(ps) 
if ("`bwidth'" == "" & "`sdbwidth'" == "") {
	foreach i in `levels'{
	sum ps`i' if _support == 1 
	local bandwidth`i' = .2*r(sd)
	}
}

*3. bwidth if sdbwidth isn't specified (sdbwidth will hold a value of "")
if ("`bwidth'" != "" & "`sdbwidth'" == "") {
foreach i in `levels'{
	local bandwidth`i' "`bwidth'"
}
}		
*4. sdbwidth if bwidth isn't specified (bwidth will hold a value of "")
if ("`bwidth'" == "" & "`sdbwidth'" != "") {
	local sd = real("`sdbwidth'")
	di "sd is type real = `sd'"
	foreach i in `levels'{
	sum ps`i' if _support == 1 
	local bandwidth`i' = `sd'*r(sd)
}
}
*Note: make sure bandwidth is calculated using the correct sample: 
*vbkw treat x1_v2 x2 x3, outcome(trueY) logitps nocom sdbwidth(.2) should be using 9889 obs if no common support
*vbkw treat x1_v2 x2 x3, outcome(trueY) logitps sdbwidth(.2) should be using 9479 obs if common support is applied 


foreach i in `levels'{
di "bandwidth`i' = `bandwidth`i''"
}








if `n_cat' == 3 {

********************************************************************************

*Set up the variables needed to run the VBKW matching algorithm. 
*I want the code to estimate all combination of atts and ates with each run of the program. 
*For a setting with 3 treatment groups, there will be 6 ATTs to estimate and 3 ATEs.

tempname treat_01

*1. generate the comparison vars: 
tokenize `levels'
cap drop `treat_01'
gen `treat_01' = 1 if `treat' == `1' & `touse'
replace `treat_01' = 0 if `treat' == `2' & `touse'

tab `treat_01'

capture drop _ATTsupport _ATUsupport
capture drop _ATTweight _ATUweight _ATEweight
capture drop _ATTtrueY _ATUtrueY

gen byte _ATTsupport = .
replace _ATTsupport = (`treat_01' <= 1)
gen double _ATTtrueY = 0 if _ATTsupport // ATT matched outcome 
 
gen byte _ATUsupport = .
replace _ATUsupport = (`treat_01' <=1)
gen double _ATUtrueY = 0 if _ATUsupport // ATU matched outcome 

gen double _ATUweight = 1 - `treat_01' if _ATUsupport == 1 
gen double _ATTweight = `treat_01' if _ATTsupport == 1

********************************************************************************
di "VBKW ATT `1' v `2' | T = `2' estimation:"

cap drop n_used
g double n_used = 0 if `treat_01' !=. 


*for now, the outcome used in estimating the counterfactual outcome is based on just the first outcome listed in outcome(varlist)
gettoken outcome1 otheroutcomes : outcome

di "The outcome we use to estimate the counterfactual is: `outcome1'"

sort `treat_01' id 
local vars ps`2' _ATUsupport _ATUtrueY _ATUweight `outcome1' n_used
local method vbkw 
count if `treat' == `2' 
local nref = r(N)
count if `treat' == `1' 
local ncomp = r(N)
*NOTE: I've made changes to the way we specify the arguments: specification of the bandwidths and ps vars are now to stay the same regardless of which treatment effect is being estimated.
mata: match("`vars'", "`kerneltype'", `nref', `ncomp', `bandwidth`1'', `bandwidth`2'', `bandwidth`3'', "ps`1'", "ps`2'", "ps`3'")
replace _ATUsupport = 0 if _ATUweight == 0 | _ATUweight == . 



/*
if "`nmatched'" == "yes" {
*for reference subjects, n_used gives us the number of comparison subjects used to calculate
*the counterfactual outcomes for each reference subject. 
sum n_used if _ATUsupport == 1 & treat == 2, detail
return scalar vbkw_ATT122_compused_mu = r(mean)
return scalar vbkw_ATT122_compused_p50 = r(p50)
return scalar vbkw_ATT122_compused_min = r(min)
return scalar vbkw_ATT122_compused_max = r(max)
*for comparison subjects, n_used gives the number of reference subjects each comparison subject
*has been matched to. 
sum n_used if _ATUsupport == 1 & treat == 1, detail
return scalar vbkw_ATT122_refmatched_mu = r(mean)
return scalar vbkw_ATT122_refmatched_p50 = r(p50)
return scalar vbkw_ATT122_refmatched_min = r(min)
return scalar vbkw_ATT122_refmatched_max = r(max)
}
*/
*of the treat = 2 reference subjects on overall common support, how many of them were able to find matches? 
count if _ATUsupport == 1 & `treat' == `2'
scalar on = r(N)
count if `treat' == `2'
scalar total = r(N)

*scalar vbkw_122_matched_pct = (on/total)*100 

*ATT 1 v 2 | T = 2: 
sum _ATUtrueY if `treat' == `2' & _ATUsupport == 1 
scalar m1u = r(mean)
local N2 = r(N)
sum `outcome1' if `treat' == `2' & _ATUsupport == 1 
scalar m2u = r(mean)
scalar vbkw_ATU = m1u - m2u 

scalar vbkw_ATT`1'`2'_`2' = vbkw_ATU


rename n_used n_used_ATT`1'`2'`2'
********************************************************************************

di "VBKW ATT `1' v `2' | T = `1' estimation:"

cap drop n_used
g double n_used = 0 if `treat_01' !=. 

gsort -`treat_01' id 
local vars ps`1' _ATTsupport _ATTtrueY _ATTweight `outcome1' n_used
local method vbkw 
count if `treat' == `1' 
local nref = r(N)
count if `treat' == `2' 
local ncomp = r(N)
mata: match("`vars'", "`kerneltype'", `nref', `ncomp', `bandwidth`1'', `bandwidth`2'', `bandwidth`3'', "ps`1'", "ps`2'", "ps`3'")
replace _ATTsupport = 0 if _ATTweight == 0 | _ATTweight == . 
/*
if "`nmatched'" == "yes" {
*for reference subjects, n_used gives us the number of comparison subjects used to calculate
*the counterfactual outcomes for each reference subject. 
sum n_used if _ATTsupport == 1 & treat == 1, detail
return scalar vbkw_ATT121_compused_mu = r(mean)
return scalar vbkw_ATT121_compused_p50 = r(p50)
return scalar vbkw_ATT121_compused_min = r(min)
return scalar vbkw_ATT121_compused_max = r(max)
*for comparison subjects, n_used gives the number of reference subjects each comparison subject
*has been matched to. 
sum n_used if _ATTsupport == 1 & treat == 2, detail
return scalar vbkw_ATT121_refmatched_mu = r(mean)
return scalar vbkw_ATT121_refmatched_p50 = r(p50)
return scalar vbkw_ATT121_refmatched_min = r(min)
return scalar vbkw_ATT121_refmatched_max = r(max)
}
*/
*of the treat = 1 reference subjects on overall common support, how many of them were able to find matches? 
count if _ATTsupport == 1 & `treat' == `1'
scalar on = r(N)
count if `treat' == `1'
scalar total = r(N)

*scalar vbkw_121_matched_pct = (on/total)*100 
*ATT 1 v 2 | T = 1: 
sum `outcome1' if `treat' == `1' & _ATTsupport == 1 
scalar m1t = r(mean)
local N1 = r(N)
sum _ATTtrueY if `treat' == `1' & _ATTsupport == 1 
scalar m2t = r(mean)
scalar vbkw_ATT = m1t - m2t

scalar vbkw_ATT`1'`2'_`1' = vbkw_ATT 
scalar vbkw_ATE`1'`2' = (vbkw_ATT*`N1'/(`N1'+`N2')) +  (vbkw_ATU*`N2'/(`N1'+`N2'))
gen double _ATEweight = _ATTweight + _ATUweight if `treat_01' <= 1


rename n_used n_used_ATT`1'`2'`1'
compress


cap drop  ATTsupport`1'`2'_`1'
cap drop  ATTweight`1'`2'_`1'
cap drop  ATUsupport`1'`2'_`2'
cap drop  ATUweight`1'`2'_`2'
cap drop  ATEweight`1'`2'

cap drop  ATTsupport`1'`3'_`1'
cap drop  ATTweight`1'`3'_`1'
cap drop  ATUsupport`1'`3'_`3'
cap drop  ATUweight`1'`3'_`3'
cap drop  ATEweight`1'`3'

cap drop  ATTsupport`2'`3'_`2'
cap drop  ATTweight`2'`3'_`2'
cap drop  ATUsupport`2'`3'_`3'
cap drop  ATUweight`2'`3'_`3'
cap drop  ATEweight`2'`3'


clonevar  ATTsupport`1'`2'_`1' = _ATTsupport
clonevar  ATTweight`1'`2'_`1' = _ATTweight
clonevar  ATUsupport`1'`2'_`2' = _ATUsupport
clonevar  ATUweight`1'`2'_`2' = _ATUweight
clonevar  ATEweight`1'`2' = _ATEweight



********************************************************************************
*Estimate the treatment effects for 1 vs. 3: 
********************************************************************************

tempname treat_01

*1. generate the comparison vars: 
tokenize `levels'
cap drop `treat_01'
gen `treat_01' = 1 if `treat' == `1' & `touse'
replace `treat_01' = 0 if `treat' == `3' & `touse'

tab `treat_01'

capture drop _ATTsupport _ATUsupport
capture drop _ATTweight _ATUweight _ATEweight
capture drop _ATTtrueY _ATUtrueY

gen byte _ATTsupport = .
replace _ATTsupport = (`treat_01' <= 1)
gen double _ATTtrueY = 0 if _ATTsupport // ATT matched outcome 
 
gen byte _ATUsupport = .
replace _ATUsupport = (`treat_01' <=1)
gen double _ATUtrueY = 0 if _ATUsupport // ATU matched outcome 

gen double _ATUweight = 1 - `treat_01' if _ATUsupport == 1 
gen double _ATTweight = `treat_01' if _ATTsupport == 1

********************************************************************************
di "VBKW ATT `1' v `3' | T = `3' estimation:"

cap drop n_used
g double n_used = 0 if `treat_01' !=. 


*for now, the outcome used in estimating the counterfactual outcome is based on just the first outcome listed in outcome(varlist)
gettoken outcome1 otheroutcomes : outcome

di "The outcome we use to estimate the counterfactual is: `outcome1'"

sort `treat_01' id 
local vars ps`3' _ATUsupport _ATUtrueY _ATUweight `outcome1' n_used
local method vbkw 
count if `treat' == `3' 
local nref = r(N)
count if `treat' == `1' 
local ncomp = r(N)
*NOTE: I've made changes to the way we specify the arguments: specification of the bandwidths and ps vars are now to stay the same regardless of which treatment effect is being estimated.
mata: match("`vars'", "`kerneltype'", `nref', `ncomp', `bandwidth`1'', `bandwidth`2'', `bandwidth`3'', "ps`1'", "ps`2'", "ps`3'")
replace _ATUsupport = 0 if _ATUweight == 0 | _ATUweight == . 

*of the treat = 3 reference subjects on overall common support, how many of them were able to find matches? 
count if _ATUsupport == 1 & `treat' == `3'
scalar on = r(N)
count if `treat' == `3'
scalar total = r(N)

*scalar vbkw_133_matched_pct = (on/total)*100 

*ATT 1 v 3 | T = 3: 
sum _ATUtrueY if `treat' == `3' & _ATUsupport == 1 
scalar m1u = r(mean)
local N2 = r(N)
sum `outcome1' if `treat' == `3' & _ATUsupport == 1 
scalar m2u = r(mean)
scalar vbkw_ATU = m1u - m2u 

scalar vbkw_ATT`1'`3'_`3' = vbkw_ATU

rename n_used n_used_ATT`1'`3'`3'
********************************************************************************

di "VBKW ATT `1' v `3' | T = `1' estimation:"

cap drop n_used
g double n_used = 0 if `treat_01' !=. 

gsort -`treat_01' id 
local vars ps`1' _ATTsupport _ATTtrueY _ATTweight `outcome1' n_used
local method vbkw 
count if `treat' == `1' 
local nref = r(N)
count if `treat' == `3' 
local ncomp = r(N)
mata: match("`vars'", "`kerneltype'", `nref', `ncomp', `bandwidth`1'', `bandwidth`2'', `bandwidth`3'', "ps`1'", "ps`2'", "ps`3'")
replace _ATTsupport = 0 if _ATTweight == 0 | _ATTweight == . 

*of the treat = 1 reference subjects on overall common support, how many of them were able to find matches? 
count if _ATTsupport == 1 & `treat' == `1'
scalar on = r(N)
count if `treat' == `1'
scalar total = r(N)

*scalar vbkw_131_matched_pct = (on/total)*100 
*ATT 1 v 3 | T = 1: 
sum `outcome1' if `treat' == `1' & _ATTsupport == 1 
scalar m1t = r(mean)
local N1 = r(N)
sum _ATTtrueY if `treat' == `1' & _ATTsupport == 1 
scalar m2t = r(mean)
scalar vbkw_ATT = m1t - m2t

scalar vbkw_ATT`1'`3'_`1' = vbkw_ATT 
scalar vbkw_ATE`1'`3' = (vbkw_ATT*`N1'/(`N1'+`N2')) +  (vbkw_ATU*`N2'/(`N1'+`N2'))
gen double _ATEweight = _ATTweight + _ATUweight if `treat_01' <= 1

rename n_used n_used_ATT`1'`3'`1'
compress

clonevar  ATTsupport`1'`3'_`1' = _ATTsupport
clonevar  ATTweight`1'`3'_`1' = _ATTweight
clonevar  ATUsupport`1'`3'_`3' = _ATUsupport
clonevar  ATUweight`1'`3'_`3' = _ATUweight
clonevar  ATEweight`1'`3' = _ATEweight



********************************************************************************
*Estimate the treatment effects for 2 vs. 3: 
********************************************************************************

tempname treat_01

*1. generate the comparison vars: 
tokenize `levels'
cap drop `treat_01'
gen `treat_01' = 1 if `treat' == `2' & `touse'
replace `treat_01' = 0 if `treat' == `3' & `touse'

tab `treat_01'

capture drop _ATTsupport _ATUsupport
capture drop _ATTweight _ATUweight _ATEweight
capture drop _ATTtrueY _ATUtrueY

gen byte _ATTsupport = .
replace _ATTsupport = (`treat_01' <= 1)
gen double _ATTtrueY = 0 if _ATTsupport // ATT matched outcome 
 
gen byte _ATUsupport = .
replace _ATUsupport = (`treat_01' <=1)
gen double _ATUtrueY = 0 if _ATUsupport // ATU matched outcome 

gen double _ATUweight = 1 - `treat_01' if _ATUsupport == 1 
gen double _ATTweight = `treat_01' if _ATTsupport == 1

********************************************************************************
di "VBKW ATT `2' v `3' | T = `3' estimation:"

cap drop n_used
g double n_used = 0 if `treat_01' !=. 


*for now, the outcome used in estimating the counterfactual outcome is based on just the first outcome listed in outcome(varlist)
gettoken outcome1 otheroutcomes : outcome

di "The outcome we use to estimate the counterfactual is: `outcome1'"

sort `treat_01' id 
local vars ps`3' _ATUsupport _ATUtrueY _ATUweight `outcome1' n_used
local method vbkw 
count if `treat' == `3' 
local nref = r(N)
count if `treat' == `2' 
local ncomp = r(N)
*NOTE: I've made changes to the way we specify the arguments: specification of the bandwidths and ps vars are now to stay the same regardless of which treatment effect is being estimated.
mata: match("`vars'", "`kerneltype'", `nref', `ncomp', `bandwidth`1'', `bandwidth`2'', `bandwidth`3'', "ps`1'", "ps`2'", "ps`3'")
replace _ATUsupport = 0 if _ATUweight == 0 | _ATUweight == . 

*of the treat = 3 reference subjects on overall common support, how many of them were able to find matches? 
count if _ATUsupport == 1 & `treat' == `3'
scalar on = r(N)
count if `treat' == `3'
scalar total = r(N)

*scalar vbkw_233_matched_pct = (on/total)*100 

*ATT 2 v 3 | T = 3: 
sum _ATUtrueY if `treat' == `3' & _ATUsupport == 1 
scalar m1u = r(mean)
local N2 = r(N)
sum `outcome1' if `treat' == `3' & _ATUsupport == 1 
scalar m2u = r(mean)
scalar vbkw_ATU = m1u - m2u 

scalar vbkw_ATT`2'`3'_`3' = vbkw_ATU

rename n_used n_used_ATT`2'`3'`3'
********************************************************************************

di "VBKW ATT `2' v `3' | T = `2' estimation:"

cap drop n_used
g double n_used = 0 if `treat_01' !=. 

gsort -`treat_01' id 
local vars ps`2' _ATTsupport _ATTtrueY _ATTweight `outcome1' n_used
local method vbkw 
count if `treat' == `2' 
local nref = r(N)
count if `treat' == `3' 
local ncomp = r(N)
mata: match("`vars'", "`kerneltype'", `nref', `ncomp', `bandwidth`1'', `bandwidth`2'', `bandwidth`3'', "ps`1'", "ps`2'", "ps`3'")
replace _ATTsupport = 0 if _ATTweight == 0 | _ATTweight == . 

*of the treat = 2 reference subjects on overall common support, how many of them were able to find matches? 
count if _ATTsupport == 1 & `treat' == `2'
scalar on = r(N)
count if `treat' == `2'
scalar total = r(N)

*scalar vbkw_232_matched_pct = (on/total)*100 
*ATT 2 v 3 | T = 2: 
sum `outcome1' if `treat' == `2' & _ATTsupport == 1 
scalar m1t = r(mean)
local N1 = r(N)
sum _ATTtrueY if `treat' == `2' & _ATTsupport == 1 
scalar m2t = r(mean)
scalar vbkw_ATT = m1t - m2t

scalar vbkw_ATT`2'`3'_`2' = vbkw_ATT 
scalar vbkw_ATE`2'`3' = (vbkw_ATT*`N1'/(`N1'+`N2')) +  (vbkw_ATU*`N2'/(`N1'+`N2'))
gen double _ATEweight = _ATTweight + _ATUweight if `treat_01' <= 1

rename n_used n_used_ATT`2'`3'`2'
compress

clonevar  ATTsupport`2'`3'_`2' = _ATTsupport
clonevar  ATTweight`2'`3'_`2' = _ATTweight
clonevar  ATUsupport`2'`3'_`3' = _ATUsupport
clonevar  ATUweight`2'`3'_`3' = _ATUweight
clonevar  ATEweight`2'`3' = _ATEweight


********************************************************************************

scalar list vbkw_ATT`1'`3'_`3' vbkw_ATT`1'`3'_`1' vbkw_ATE`1'`3'
scalar list vbkw_ATT`1'`2'_`2' vbkw_ATT`1'`2'_`1' vbkw_ATE`1'`2'
scalar list vbkw_ATT`2'`3'_`3' vbkw_ATT`2'`3'_`2' vbkw_ATE`2'`3'



cap drop  vbkw_ATT`1'`2'_`1'
cap drop  vbkw_ATT`1'`2'_`2'
cap drop  vbkw_ATE`1'`2'

cap drop  vbkw_ATT`1'`3'_`1'
cap drop  vbkw_ATT`1'`3'_`3'
cap drop  vbkw_ATE`1'`3'

cap drop  vbkw_ATT`2'`3'_`2'
cap drop  vbkw_ATT`2'`3'_`3'
cap drop  vbkw_ATE`2'`3'


g vbkw_ATT`1'`3'_`3' = vbkw_ATT`1'`3'_`3'
g vbkw_ATT`1'`3'_`1' = vbkw_ATT`1'`3'_`1'
g vbkw_ATE`1'`3' = vbkw_ATE`1'`3'

g vbkw_ATT`1'`2'_`2' = vbkw_ATT`1'`2'_`2'
g vbkw_ATT`1'`2'_`1' = vbkw_ATT`1'`2'_`1'
g vbkw_ATE`1'`2' = vbkw_ATE`1'`2'

g vbkw_ATT`2'`3'_`3' = vbkw_ATT`2'`3'_`3'
g vbkw_ATT`2'`3'_`2' = vbkw_ATT`2'`3'_`2'
g vbkw_ATE`2'`3' = vbkw_ATE`2'`3'


return scalar vbkw_ATT`1'`2'_`2'b = vbkw_ATT`1'`2'_`2'
return scalar vbkw_ATT`1'`2'_`1'b = vbkw_ATT`1'`2'_`1'
return scalar vbkw_ATE`1'`2'b = vbkw_ATE`1'`2'

return scalar vbkw_ATT`1'`3'_`3'b = vbkw_ATT`1'`3'_`3'
return scalar vbkw_ATT`1'`3'_`1'b = vbkw_ATT`1'`3'_`1'
return scalar vbkw_ATE`1'`3'b = vbkw_ATE`1'`3'

return scalar vbkw_ATT`2'`3'_`3'b = vbkw_ATT`2'`3'_`3'
return scalar vbkw_ATT`2'`3'_`2'b = vbkw_ATT`2'`3'_`2'
return scalar vbkw_ATE`2'`3'b = vbkw_ATE`2'`3'

********************************************************************************

}

if `n_cat' == 4 {
********************************************************************************


tempname treat_01

*1. generate the comparison vars: 
tokenize `levels'
cap drop `treat_01'
gen `treat_01' = 1 if `treat' == `1' & `touse'
replace `treat_01' = 0 if `treat' == `2' & `touse'

tab `treat_01'

capture drop _ATTsupport _ATUsupport
capture drop _ATTweight _ATUweight _ATEweight
capture drop _ATTtrueY _ATUtrueY

gen byte _ATTsupport = .
replace _ATTsupport = (`treat_01' <= 1)
gen double _ATTtrueY = 0 if _ATTsupport // ATT matched outcome 
 
gen byte _ATUsupport = .
replace _ATUsupport = (`treat_01' <=1)
gen double _ATUtrueY = 0 if _ATUsupport // ATU matched outcome 

gen double _ATUweight = 1 - `treat_01' if _ATUsupport == 1 
gen double _ATTweight = `treat_01' if _ATTsupport == 1

********************************************************************************
di "VBKW ATT `1' v `2' | T = `2' estimation:"

cap drop n_used
g double n_used = 0 if `treat_01' !=. 


*for now, the outcome used in estimating the counterfactual outcome is based on just the first outcome listed in outcome(varlist)
gettoken outcome1 otheroutcomes : outcome

di "The outcome we use to estimate the counterfactual is: `outcome1'"

sort `treat_01' id 
local vars ps`2' _ATUsupport _ATUtrueY _ATUweight `outcome1' n_used
local method vbkw 
count if `treat' == `2' 
local nref = r(N)
count if `treat' == `1' 
local ncomp = r(N)
*NOTE: I've made changes to the way we specify the arguments: specification of the bandwidths and ps vars are now to stay the same regardless of which treatment effect is being estimated.
mata: match4("`vars'", "`kerneltype'", `nref', `ncomp', `bandwidth`1'', `bandwidth`2'', `bandwidth`3'', `bandwidth`4'', "ps`1'", "ps`2'", "ps`3'", "ps`4'")
replace _ATUsupport = 0 if _ATUweight == 0 | _ATUweight == . 



/*
if "`nmatched'" == "yes" {
*for reference subjects, n_used gives us the number of comparison subjects used to calculate
*the counterfactual outcomes for each reference subject. 
sum n_used if _ATUsupport == 1 & treat == 2, detail
return scalar vbkw_ATT122_compused_mu = r(mean)
return scalar vbkw_ATT122_compused_p50 = r(p50)
return scalar vbkw_ATT122_compused_min = r(min)
return scalar vbkw_ATT122_compused_max = r(max)
*for comparison subjects, n_used gives the number of reference subjects each comparison subject
*has been matched to. 
sum n_used if _ATUsupport == 1 & treat == 1, detail
return scalar vbkw_ATT122_refmatched_mu = r(mean)
return scalar vbkw_ATT122_refmatched_p50 = r(p50)
return scalar vbkw_ATT122_refmatched_min = r(min)
return scalar vbkw_ATT122_refmatched_max = r(max)
}
*/
*of the treat = 2 reference subjects on overall common support, how many of them were able to find matches? 
count if _ATUsupport == 1 & `treat' == `2'
scalar on = r(N)
count if `treat' == `2'
scalar total = r(N)

*scalar vbkw_122_matched_pct = (on/total)*100 

*ATT 1 v 2 | T = 2: 
sum _ATUtrueY if `treat' == `2' & _ATUsupport == 1 
scalar m1u = r(mean)
local N2 = r(N)
sum `outcome1' if `treat' == `2' & _ATUsupport == 1 
scalar m2u = r(mean)
scalar vbkw_ATU = m1u - m2u 

scalar vbkw_ATT`1'`2'_`2' = vbkw_ATU


rename n_used n_used_ATT`1'`2'`2'
********************************************************************************

di "VBKW ATT `1' v `2' | T = `1' estimation:"

cap drop n_used
g double n_used = 0 if `treat_01' !=. 

gsort -`treat_01' id 
local vars ps`1' _ATTsupport _ATTtrueY _ATTweight `outcome1' n_used
local method vbkw 
count if `treat' == `1' 
local nref = r(N)
count if `treat' == `2' 
local ncomp = r(N)
mata: match4("`vars'", "`kerneltype'", `nref', `ncomp', `bandwidth`1'', `bandwidth`2'', `bandwidth`3'', `bandwidth`4'', "ps`1'", "ps`2'", "ps`3'", "ps`4'")
replace _ATTsupport = 0 if _ATTweight == 0 | _ATTweight == . 
/*
if "`nmatched'" == "yes" {
*for reference subjects, n_used gives us the number of comparison subjects used to calculate
*the counterfactual outcomes for each reference subject. 
sum n_used if _ATTsupport == 1 & treat == 1, detail
return scalar vbkw_ATT121_compused_mu = r(mean)
return scalar vbkw_ATT121_compused_p50 = r(p50)
return scalar vbkw_ATT121_compused_min = r(min)
return scalar vbkw_ATT121_compused_max = r(max)
*for comparison subjects, n_used gives the number of reference subjects each comparison subject
*has been matched to. 
sum n_used if _ATTsupport == 1 & treat == 2, detail
return scalar vbkw_ATT121_refmatched_mu = r(mean)
return scalar vbkw_ATT121_refmatched_p50 = r(p50)
return scalar vbkw_ATT121_refmatched_min = r(min)
return scalar vbkw_ATT121_refmatched_max = r(max)
}
*/
*of the treat = 1 reference subjects on overall common support, how many of them were able to find matches? 
count if _ATTsupport == 1 & `treat' == `1'
scalar on = r(N)
count if `treat' == `1'
scalar total = r(N)

*scalar vbkw_121_matched_pct = (on/total)*100 
*ATT 1 v 2 | T = 1: 
sum `outcome1' if `treat' == `1' & _ATTsupport == 1 
scalar m1t = r(mean)
local N1 = r(N)
sum _ATTtrueY if `treat' == `1' & _ATTsupport == 1 
scalar m2t = r(mean)
scalar vbkw_ATT = m1t - m2t

scalar vbkw_ATT`1'`2'_`1' = vbkw_ATT 
scalar vbkw_ATE`1'`2' = (vbkw_ATT*`N1'/(`N1'+`N2')) +  (vbkw_ATU*`N2'/(`N1'+`N2'))
gen double _ATEweight = _ATTweight + _ATUweight if `treat_01' <= 1


rename n_used n_used_ATT`1'`2'`1'
compress


cap drop  ATTsupport`1'`2'_`1'
cap drop  ATTweight`1'`2'_`1'
cap drop  ATUsupport`1'`2'_`2'
cap drop  ATUweight`1'`2'_`2'
cap drop  ATEweight`1'`2'

cap drop  ATTsupport`1'`3'_`1'
cap drop  ATTweight`1'`3'_`1'
cap drop  ATUsupport`1'`3'_`3'
cap drop  ATUweight`1'`3'_`3'
cap drop  ATEweight`1'`3'

cap drop  ATTsupport`1'`4'_`1'
cap drop  ATTweight`1'`4'_`1'
cap drop  ATUsupport`1'`4'_`4'
cap drop  ATUweight`1'`4'_`4'
cap drop  ATEweight`1'`4'

cap drop  ATTsupport`2'`3'_`2'
cap drop  ATTweight`2'`3'_`2'
cap drop  ATUsupport`2'`3'_`3'
cap drop  ATUweight`2'`3'_`3'
cap drop  ATEweight`2'`3'

cap drop  ATTsupport`2'`4'_`2'
cap drop  ATTweight`2'`4'_`2'
cap drop  ATUsupport`2'`4'_`4'
cap drop  ATUweight`2'`4'_`4'
cap drop  ATEweight`2'`4'

cap drop  ATTsupport`3'`4'_`3'
cap drop  ATTweight`3'`4'_`3'
cap drop  ATUsupport`3'`4'_`4'
cap drop  ATUweight`3'`4'_`4'
cap drop  ATEweight`3'`4'


clonevar  ATTsupport`1'`2'_`1' = _ATTsupport
clonevar  ATTweight`1'`2'_`1' = _ATTweight
clonevar  ATUsupport`1'`2'_`2' = _ATUsupport
clonevar  ATUweight`1'`2'_`2' = _ATUweight
clonevar  ATEweight`1'`2' = _ATEweight



********************************************************************************
*Estimate the treatment effects for 1 vs. 3: 
********************************************************************************

tempname treat_01

*1. generate the comparison vars: 
tokenize `levels'
cap drop `treat_01'
gen `treat_01' = 1 if `treat' == `1' & `touse'
replace `treat_01' = 0 if `treat' == `3' & `touse'

tab `treat_01'

capture drop _ATTsupport _ATUsupport
capture drop _ATTweight _ATUweight _ATEweight
capture drop _ATTtrueY _ATUtrueY

gen byte _ATTsupport = .
replace _ATTsupport = (`treat_01' <= 1)
gen double _ATTtrueY = 0 if _ATTsupport // ATT matched outcome 
 
gen byte _ATUsupport = .
replace _ATUsupport = (`treat_01' <=1)
gen double _ATUtrueY = 0 if _ATUsupport // ATU matched outcome 

gen double _ATUweight = 1 - `treat_01' if _ATUsupport == 1 
gen double _ATTweight = `treat_01' if _ATTsupport == 1

********************************************************************************
di "VBKW ATT `1' v `3' | T = `3' estimation:"

cap drop n_used
g double n_used = 0 if `treat_01' !=. 


*for now, the outcome used in estimating the counterfactual outcome is based on just the first outcome listed in outcome(varlist)
gettoken outcome1 otheroutcomes : outcome

di "The outcome we use to estimate the counterfactual is: `outcome1'"

sort `treat_01' id 
local vars ps`3' _ATUsupport _ATUtrueY _ATUweight `outcome1' n_used
local method vbkw 
count if `treat' == `3' 
local nref = r(N)
count if `treat' == `1' 
local ncomp = r(N)
*NOTE: I've made changes to the way we specify the arguments: specification of the bandwidths and ps vars are now to stay the same regardless of which treatment effect is being estimated.
mata: match4("`vars'", "`kerneltype'", `nref', `ncomp', `bandwidth`1'', `bandwidth`2'', `bandwidth`3'', `bandwidth`4'', "ps`1'", "ps`2'", "ps`3'", "ps`4'")
replace _ATUsupport = 0 if _ATUweight == 0 | _ATUweight == . 

*of the treat = 3 reference subjects on overall common support, how many of them were able to find matches? 
count if _ATUsupport == 1 & `treat' == `3'
scalar on = r(N)
count if `treat' == `3'
scalar total = r(N)

*scalar vbkw_133_matched_pct = (on/total)*100 

*ATT 1 v 3 | T = 3: 
sum _ATUtrueY if `treat' == `3' & _ATUsupport == 1 
scalar m1u = r(mean)
local N2 = r(N)
sum `outcome1' if `treat' == `3' & _ATUsupport == 1 
scalar m2u = r(mean)
scalar vbkw_ATU = m1u - m2u 

scalar vbkw_ATT`1'`3'_`3' = vbkw_ATU

rename n_used n_used_ATT`1'`3'`3'
********************************************************************************

di "VBKW ATT `1' v `3' | T = `1' estimation:"

cap drop n_used
g double n_used = 0 if `treat_01' !=. 

gsort -`treat_01' id 
local vars ps`1' _ATTsupport _ATTtrueY _ATTweight `outcome1' n_used
local method vbkw 
count if `treat' == `1' 
local nref = r(N)
count if `treat' == `3' 
local ncomp = r(N)
mata: match4("`vars'", "`kerneltype'", `nref', `ncomp', `bandwidth`1'', `bandwidth`2'', `bandwidth`3'', `bandwidth`4'', "ps`1'", "ps`2'", "ps`3'", "ps`4'")
replace _ATTsupport = 0 if _ATTweight == 0 | _ATTweight == . 

*of the treat = 1 reference subjects on overall common support, how many of them were able to find matches? 
count if _ATTsupport == 1 & `treat' == `1'
scalar on = r(N)
count if `treat' == `1'
scalar total = r(N)

*scalar vbkw_131_matched_pct = (on/total)*100 
*ATT 1 v 3 | T = 1: 
sum `outcome1' if `treat' == `1' & _ATTsupport == 1 
scalar m1t = r(mean)
local N1 = r(N)
sum _ATTtrueY if `treat' == `1' & _ATTsupport == 1 
scalar m2t = r(mean)
scalar vbkw_ATT = m1t - m2t

scalar vbkw_ATT`1'`3'_`1' = vbkw_ATT 
scalar vbkw_ATE`1'`3' = (vbkw_ATT*`N1'/(`N1'+`N2')) +  (vbkw_ATU*`N2'/(`N1'+`N2'))
gen double _ATEweight = _ATTweight + _ATUweight if `treat_01' <= 1

rename n_used n_used_ATT`1'`3'`1'
compress

clonevar  ATTsupport`1'`3'_`1' = _ATTsupport
clonevar  ATTweight`1'`3'_`1' = _ATTweight
clonevar  ATUsupport`1'`3'_`3' = _ATUsupport
clonevar  ATUweight`1'`3'_`3' = _ATUweight
clonevar  ATEweight`1'`3' = _ATEweight

********************************************************************************
*Estimate the treatment effects for 1 vs. 4: 
********************************************************************************

tempname treat_01

*1. generate the comparison vars: 
tokenize `levels'
cap drop `treat_01'
gen `treat_01' = 1 if `treat' == `1' & `touse'
replace `treat_01' = 0 if `treat' == `4' & `touse'

tab `treat_01'

capture drop _ATTsupport _ATUsupport
capture drop _ATTweight _ATUweight _ATEweight
capture drop _ATTtrueY _ATUtrueY

gen byte _ATTsupport = .
replace _ATTsupport = (`treat_01' <= 1)
gen double _ATTtrueY = 0 if _ATTsupport // ATT matched outcome 
 
gen byte _ATUsupport = .
replace _ATUsupport = (`treat_01' <=1)
gen double _ATUtrueY = 0 if _ATUsupport // ATU matched outcome 

gen double _ATUweight = 1 - `treat_01' if _ATUsupport == 1 
gen double _ATTweight = `treat_01' if _ATTsupport == 1

********************************************************************************
di "VBKW ATT `1' v `4' | T = `4' estimation:"

cap drop n_used
g double n_used = 0 if `treat_01' !=. 


*for now, the outcome used in estimating the counterfactual outcome is based on just the first outcome listed in outcome(varlist)
gettoken outcome1 otheroutcomes : outcome

di "The outcome we use to estimate the counterfactual is: `outcome1'"

sort `treat_01' id 
local vars ps`4' _ATUsupport _ATUtrueY _ATUweight `outcome1' n_used
local method vbkw 
count if `treat' == `4' 
local nref = r(N)
count if `treat' == `1' 
local ncomp = r(N)
*NOTE: I've made changes to the way we specify the arguments: specification of the bandwidths and ps vars are now to stay the same regardless of which treatment effect is being estimated.
mata: match4("`vars'", "`kerneltype'", `nref', `ncomp', `bandwidth`1'', `bandwidth`2'', `bandwidth`3'', `bandwidth`4'', "ps`1'", "ps`2'", "ps`3'", "ps`4'")
replace _ATUsupport = 0 if _ATUweight == 0 | _ATUweight == . 

*of the treat = 4 reference subjects on overall common support, how many of them were able to find matches? 
count if _ATUsupport == 1 & `treat' == `4'
scalar on = r(N)
count if `treat' == `4'
scalar total = r(N)

*scalar vbkw_144_matched_pct = (on/total)*100 

*ATT 1 v 4 | T = 4: 
sum _ATUtrueY if `treat' == `4' & _ATUsupport == 1 
scalar m1u = r(mean)
local N2 = r(N)
sum `outcome1' if `treat' == `4' & _ATUsupport == 1 
scalar m2u = r(mean)
scalar vbkw_ATU = m1u - m2u 

scalar vbkw_ATT`1'`4'_`4' = vbkw_ATU

rename n_used n_used_ATT`1'`4'`4'
********************************************************************************

di "VBKW ATT `1' v `4' | T = `1' estimation:"

cap drop n_used
g double n_used = 0 if `treat_01' !=. 

gsort -`treat_01' id 
local vars ps`1' _ATTsupport _ATTtrueY _ATTweight `outcome1' n_used
local method vbkw 
count if `treat' == `1' 
local nref = r(N)
count if `treat' == `4' 
local ncomp = r(N)
mata: match4("`vars'", "`kerneltype'", `nref', `ncomp', `bandwidth`1'', `bandwidth`2'', `bandwidth`3'', `bandwidth`4'', "ps`1'", "ps`2'", "ps`3'", "ps`4'")
replace _ATTsupport = 0 if _ATTweight == 0 | _ATTweight == . 

*of the treat = 1 reference subjects on overall common support, how many of them were able to find matches? 
count if _ATTsupport == 1 & `treat' == `1'
scalar on = r(N)
count if `treat' == `1'
scalar total = r(N)

*scalar vbkw_141_matched_pct = (on/total)*100 
*ATT 1 v 4 | T = 1: 
sum `outcome1' if `treat' == `1' & _ATTsupport == 1 
scalar m1t = r(mean)
local N1 = r(N)
sum _ATTtrueY if `treat' == `1' & _ATTsupport == 1 
scalar m2t = r(mean)
scalar vbkw_ATT = m1t - m2t

scalar vbkw_ATT`1'`4'_`1' = vbkw_ATT 
scalar vbkw_ATE`1'`4' = (vbkw_ATT*`N1'/(`N1'+`N2')) +  (vbkw_ATU*`N2'/(`N1'+`N2'))
gen double _ATEweight = _ATTweight + _ATUweight if `treat_01' <= 1

rename n_used n_used_ATT`1'`4'`1'
compress

clonevar  ATTsupport`1'`4'_`1' = _ATTsupport
clonevar  ATTweight`1'`4'_`1' = _ATTweight
clonevar  ATUsupport`1'`4'_`4' = _ATUsupport
clonevar  ATUweight`1'`4'_`4' = _ATUweight
clonevar  ATEweight`1'`4' = _ATEweight


********************************************************************************
*Estimate the treatment effects for 2 vs. 3: 
********************************************************************************

tempname treat_01

*1. generate the comparison vars: 
tokenize `levels'
cap drop `treat_01'
gen `treat_01' = 1 if `treat' == `2' & `touse'
replace `treat_01' = 0 if `treat' == `3' & `touse'

tab `treat_01'

capture drop _ATTsupport _ATUsupport
capture drop _ATTweight _ATUweight _ATEweight
capture drop _ATTtrueY _ATUtrueY

gen byte _ATTsupport = .
replace _ATTsupport = (`treat_01' <= 1)
gen double _ATTtrueY = 0 if _ATTsupport // ATT matched outcome 
 
gen byte _ATUsupport = .
replace _ATUsupport = (`treat_01' <=1)
gen double _ATUtrueY = 0 if _ATUsupport // ATU matched outcome 

gen double _ATUweight = 1 - `treat_01' if _ATUsupport == 1 
gen double _ATTweight = `treat_01' if _ATTsupport == 1

********************************************************************************
di "VBKW ATT `2' v `3' | T = `3' estimation:"

cap drop n_used
g double n_used = 0 if `treat_01' !=. 


*for now, the outcome used in estimating the counterfactual outcome is based on just the first outcome listed in outcome(varlist)
gettoken outcome1 otheroutcomes : outcome

di "The outcome we use to estimate the counterfactual is: `outcome1'"

sort `treat_01' id 
local vars ps`3' _ATUsupport _ATUtrueY _ATUweight `outcome1' n_used
local method vbkw 
count if `treat' == `3' 
local nref = r(N)
count if `treat' == `2' 
local ncomp = r(N)
*NOTE: I've made changes to the way we specify the arguments: specification of the bandwidths and ps vars are now to stay the same regardless of which treatment effect is being estimated.
mata: match4("`vars'", "`kerneltype'", `nref', `ncomp', `bandwidth`1'', `bandwidth`2'', `bandwidth`3'', `bandwidth`4'', "ps`1'", "ps`2'", "ps`3'", "ps`4'")
replace _ATUsupport = 0 if _ATUweight == 0 | _ATUweight == . 

*of the treat = 3 reference subjects on overall common support, how many of them were able to find matches? 
count if _ATUsupport == 1 & `treat' == `3'
scalar on = r(N)
count if `treat' == `3'
scalar total = r(N)

*scalar vbkw_233_matched_pct = (on/total)*100 

*ATT 2 v 3 | T = 3: 
sum _ATUtrueY if `treat' == `3' & _ATUsupport == 1 
scalar m1u = r(mean)
local N2 = r(N)
sum `outcome1' if `treat' == `3' & _ATUsupport == 1 
scalar m2u = r(mean)
scalar vbkw_ATU = m1u - m2u 

scalar vbkw_ATT`2'`3'_`3' = vbkw_ATU

rename n_used n_used_ATT`2'`3'`3'
********************************************************************************

di "VBKW ATT `2' v `3' | T = `2' estimation:"

cap drop n_used
g double n_used = 0 if `treat_01' !=. 

gsort -`treat_01' id 
local vars ps`2' _ATTsupport _ATTtrueY _ATTweight `outcome1' n_used
local method vbkw 
count if `treat' == `2' 
local nref = r(N)
count if `treat' == `3' 
local ncomp = r(N)
mata: match4("`vars'", "`kerneltype'", `nref', `ncomp', `bandwidth`1'', `bandwidth`2'', `bandwidth`3'', `bandwidth`4'', "ps`1'", "ps`2'", "ps`3'", "ps`4'")
replace _ATTsupport = 0 if _ATTweight == 0 | _ATTweight == . 

*of the treat = 2 reference subjects on overall common support, how many of them were able to find matches? 
count if _ATTsupport == 1 & `treat' == `2'
scalar on = r(N)
count if `treat' == `2'
scalar total = r(N)

*scalar vbkw_232_matched_pct = (on/total)*100 
*ATT 2 v 3 | T = 2: 
sum `outcome1' if `treat' == `2' & _ATTsupport == 1 
scalar m1t = r(mean)
local N1 = r(N)
sum _ATTtrueY if `treat' == `2' & _ATTsupport == 1 
scalar m2t = r(mean)
scalar vbkw_ATT = m1t - m2t

scalar vbkw_ATT`2'`3'_`2' = vbkw_ATT 
scalar vbkw_ATE`2'`3' = (vbkw_ATT*`N1'/(`N1'+`N2')) +  (vbkw_ATU*`N2'/(`N1'+`N2'))
gen double _ATEweight = _ATTweight + _ATUweight if `treat_01' <= 1

rename n_used n_used_ATT`2'`3'`2'
compress

clonevar  ATTsupport`2'`3'_`2' = _ATTsupport
clonevar  ATTweight`2'`3'_`2' = _ATTweight
clonevar  ATUsupport`2'`3'_`3' = _ATUsupport
clonevar  ATUweight`2'`3'_`3' = _ATUweight
clonevar  ATEweight`2'`3' = _ATEweight

********************************************************************************
*Estimate the treatment effects for 2 vs. 4: 
********************************************************************************

tempname treat_01

*1. generate the comparison vars: 
tokenize `levels'
cap drop `treat_01'
gen `treat_01' = 1 if `treat' == `2' & `touse'
replace `treat_01' = 0 if `treat' == `4' & `touse'

tab `treat_01'

capture drop _ATTsupport _ATUsupport
capture drop _ATTweight _ATUweight _ATEweight
capture drop _ATTtrueY _ATUtrueY

gen byte _ATTsupport = .
replace _ATTsupport = (`treat_01' <= 1)
gen double _ATTtrueY = 0 if _ATTsupport // ATT matched outcome 
 
gen byte _ATUsupport = .
replace _ATUsupport = (`treat_01' <=1)
gen double _ATUtrueY = 0 if _ATUsupport // ATU matched outcome 

gen double _ATUweight = 1 - `treat_01' if _ATUsupport == 1 
gen double _ATTweight = `treat_01' if _ATTsupport == 1

********************************************************************************
di "VBKW ATT `2' v `4' | T = `4' estimation:"

cap drop n_used
g double n_used = 0 if `treat_01' !=. 


*for now, the outcome used in estimating the counterfactual outcome is based on just the first outcome listed in outcome(varlist)
gettoken outcome1 otheroutcomes : outcome

di "The outcome we use to estimate the counterfactual is: `outcome1'"

sort `treat_01' id 
local vars ps`4' _ATUsupport _ATUtrueY _ATUweight `outcome1' n_used
local method vbkw 
count if `treat' == `4' 
local nref = r(N)
count if `treat' == `2' 
local ncomp = r(N)
*NOTE: I've made changes to the way we specify the arguments: specification of the bandwidths and ps vars are now to stay the same regardless of which treatment effect is being estimated.
mata: match4("`vars'", "`kerneltype'", `nref', `ncomp', `bandwidth`1'', `bandwidth`2'', `bandwidth`3'', `bandwidth`4'',"ps`1'", "ps`2'", "ps`3'", "ps`4'")
replace _ATUsupport = 0 if _ATUweight == 0 | _ATUweight == . 

*of the treat = 4 reference subjects on overall common support, how many of them were able to find matches? 
count if _ATUsupport == 1 & `treat' == `4'
scalar on = r(N)
count if `treat' == `4'
scalar total = r(N)

*scalar vbkw_244_matched_pct = (on/total)*100 

*ATT 2 v 4 | T = 4: 
sum _ATUtrueY if `treat' == `4' & _ATUsupport == 1 
scalar m1u = r(mean)
local N2 = r(N)
sum `outcome1' if `treat' == `4' & _ATUsupport == 1 
scalar m2u = r(mean)
scalar vbkw_ATU = m1u - m2u 

scalar vbkw_ATT`2'`4'_`4' = vbkw_ATU

rename n_used n_used_ATT`2'`4'`4'
********************************************************************************

di "VBKW ATT `2' v `4' | T = `2' estimation:"

cap drop n_used
g double n_used = 0 if `treat_01' !=. 

gsort -`treat_01' id 
local vars ps`2' _ATTsupport _ATTtrueY _ATTweight `outcome1' n_used
local method vbkw 
count if `treat' == `2' 
local nref = r(N)
count if `treat' == `4' 
local ncomp = r(N)
mata: match4("`vars'", "`kerneltype'", `nref', `ncomp', `bandwidth`1'', `bandwidth`2'', `bandwidth`3'', `bandwidth`4'', "ps`1'", "ps`2'", "ps`3'", "ps`4'")
replace _ATTsupport = 0 if _ATTweight == 0 | _ATTweight == . 

*of the treat = 2 reference subjects on overall common support, how many of them were able to find matches? 
count if _ATTsupport == 1 & `treat' == `2'
scalar on = r(N)
count if `treat' == `2'
scalar total = r(N)

*scalar vbkw_242_matched_pct = (on/total)*100 
*ATT 2 v 4 | T = 2: 
sum `outcome1' if `treat' == `2' & _ATTsupport == 1 
scalar m1t = r(mean)
local N1 = r(N)
sum _ATTtrueY if `treat' == `2' & _ATTsupport == 1 
scalar m2t = r(mean)
scalar vbkw_ATT = m1t - m2t

scalar vbkw_ATT`2'`4'_`2' = vbkw_ATT 
scalar vbkw_ATE`2'`4' = (vbkw_ATT*`N1'/(`N1'+`N2')) +  (vbkw_ATU*`N2'/(`N1'+`N2'))
gen double _ATEweight = _ATTweight + _ATUweight if `treat_01' <= 1

rename n_used n_used_ATT`2'`4'`2'
compress

clonevar  ATTsupport`2'`4'_`2' = _ATTsupport
clonevar  ATTweight`2'`4'_`2' = _ATTweight
clonevar  ATUsupport`2'`4'_`4' = _ATUsupport
clonevar  ATUweight`2'`4'_`4' = _ATUweight
clonevar  ATEweight`2'`4' = _ATEweight
********************************************************************************
*Estimate the treatment effects for 3 vs. 4: 
********************************************************************************

tempname treat_01

*1. generate the comparison vars: 
tokenize `levels'
cap drop `treat_01'
gen `treat_01' = 1 if `treat' == `3' & `touse'
replace `treat_01' = 0 if `treat' == `4' & `touse'

tab `treat_01'

capture drop _ATTsupport _ATUsupport
capture drop _ATTweight _ATUweight _ATEweight
capture drop _ATTtrueY _ATUtrueY

gen byte _ATTsupport = .
replace _ATTsupport = (`treat_01' <= 1)
gen double _ATTtrueY = 0 if _ATTsupport // ATT matched outcome 
 
gen byte _ATUsupport = .
replace _ATUsupport = (`treat_01' <=1)
gen double _ATUtrueY = 0 if _ATUsupport // ATU matched outcome 

gen double _ATUweight = 1 - `treat_01' if _ATUsupport == 1 
gen double _ATTweight = `treat_01' if _ATTsupport == 1

********************************************************************************
di "VBKW ATT `3' v `4' | T = `4' estimation:"

cap drop n_used
g double n_used = 0 if `treat_01' !=. 


*for now, the outcome used in estimating the counterfactual outcome is based on just the first outcome listed in outcome(varlist)
gettoken outcome1 otheroutcomes : outcome

di "The outcome we use to estimate the counterfactual is: `outcome1'"

sort `treat_01' id 
local vars ps`4' _ATUsupport _ATUtrueY _ATUweight `outcome1' n_used
local method vbkw 
count if `treat' == `4' 
local nref = r(N)
count if `treat' == `3' 
local ncomp = r(N)
*NOTE: I've made changes to the way we specify the arguments: specification of the bandwidths and ps vars are now to stay the same regardless of which treatment effect is being estimated.
mata: match4("`vars'", "`kerneltype'", `nref', `ncomp', `bandwidth`1'', `bandwidth`2'', `bandwidth`3'', `bandwidth`4'',"ps`1'", "ps`2'", "ps`3'", "ps`4'")
replace _ATUsupport = 0 if _ATUweight == 0 | _ATUweight == . 

*of the treat = 4 reference subjects on overall common support, how many of them were able to find matches? 
count if _ATUsupport == 1 & `treat' == `4'
scalar on = r(N)
count if `treat' == `4'
scalar total = r(N)

*scalar vbkw_344_matched_pct = (on/total)*100 

*ATT 3 v 4 | T = 4: 
sum _ATUtrueY if `treat' == `4' & _ATUsupport == 1 
scalar m1u = r(mean)
local N2 = r(N)
sum `outcome1' if `treat' == `4' & _ATUsupport == 1 
scalar m2u = r(mean)
scalar vbkw_ATU = m1u - m2u 

scalar vbkw_ATT`3'`4'_`4' = vbkw_ATU

rename n_used n_used_ATT`3'`4'`4'
********************************************************************************

di "VBKW ATT `3' v `4' | T = `3' estimation:"

cap drop n_used
g double n_used = 0 if `treat_01' !=. 

gsort -`treat_01' id 
local vars ps`3' _ATTsupport _ATTtrueY _ATTweight `outcome1' n_used
local method vbkw 
count if `treat' == `3' 
local nref = r(N)
count if `treat' == `4' 
local ncomp = r(N)
mata: match4("`vars'", "`kerneltype'", `nref', `ncomp', `bandwidth`1'', `bandwidth`2'', `bandwidth`3'', `bandwidth`4'', "ps`1'", "ps`2'", "ps`3'", "ps`4'")
replace _ATTsupport = 0 if _ATTweight == 0 | _ATTweight == . 

*of the treat = 3 reference subjects on overall common support, how many of them were able to find matches? 
count if _ATTsupport == 1 & `treat' == `3'
scalar on = r(N)
count if `treat' == `3'
scalar total = r(N)

*scalar vbkw_343_matched_pct = (on/total)*100 
*ATT 3 v 4 | T = 3: 
sum `outcome1' if `treat' == `3' & _ATTsupport == 1 
scalar m1t = r(mean)
local N1 = r(N)
sum _ATTtrueY if `treat' == `3' & _ATTsupport == 1 
scalar m2t = r(mean)
scalar vbkw_ATT = m1t - m2t

scalar vbkw_ATT`3'`4'_`3' = vbkw_ATT 
scalar vbkw_ATE`3'`4' = (vbkw_ATT*`N1'/(`N1'+`N2')) +  (vbkw_ATU*`N2'/(`N1'+`N2'))
gen double _ATEweight = _ATTweight + _ATUweight if `treat_01' <= 1

rename n_used n_used_ATT`3'`4'`3'
compress

clonevar  ATTsupport`3'`4'_`3' = _ATTsupport
clonevar  ATTweight`3'`4'_`3' = _ATTweight
clonevar  ATUsupport`3'`4'_`4' = _ATUsupport
clonevar  ATUweight`3'`4'_`4' = _ATUweight
clonevar  ATEweight`3'`4' = _ATEweight

********************************************************************************

scalar list vbkw_ATT`1'`3'_`3' vbkw_ATT`1'`3'_`1' vbkw_ATE`1'`3'
scalar list vbkw_ATT`1'`2'_`2' vbkw_ATT`1'`2'_`1' vbkw_ATE`1'`2'
scalar list vbkw_ATT`1'`4'_`4' vbkw_ATT`1'`4'_`1' vbkw_ATE`1'`4'

scalar list vbkw_ATT`2'`3'_`3' vbkw_ATT`2'`3'_`2' vbkw_ATE`2'`3'
scalar list vbkw_ATT`2'`4'_`4' vbkw_ATT`2'`4'_`2' vbkw_ATE`2'`4'

scalar list vbkw_ATT`3'`4'_`4' vbkw_ATT`3'`4'_`3' vbkw_ATE`3'`4'


cap drop  vbkw_ATT`1'`2'_`1'
cap drop  vbkw_ATT`1'`2'_`2'
cap drop  vbkw_ATE`1'`2'

cap drop  vbkw_ATT`1'`3'_`1'
cap drop  vbkw_ATT`1'`3'_`3'
cap drop  vbkw_ATE`1'`3'

cap drop  vbkw_ATT`1'`4'_`1'
cap drop  vbkw_ATT`1'`4'_`4'
cap drop  vbkw_ATE`1'`4'

cap drop  vbkw_ATT`2'`3'_`2'
cap drop  vbkw_ATT`2'`3'_`3'
cap drop  vbkw_ATE`2'`3'

cap drop  vbkw_ATT`2'`4'_`2'
cap drop  vbkw_ATT`2'`4'_`4'
cap drop  vbkw_ATE`2'`4'

cap drop  vbkw_ATT`3'`4'_`3'
cap drop  vbkw_ATT`3'`4'_`4'
cap drop  vbkw_ATE`3'`4'

g vbkw_ATT`1'`3'_`3' = vbkw_ATT`1'`3'_`3'
g vbkw_ATT`1'`3'_`1' = vbkw_ATT`1'`3'_`1'
g vbkw_ATE`1'`3' = vbkw_ATE`1'`3'

g vbkw_ATT`1'`2'_`2' = vbkw_ATT`1'`2'_`2'
g vbkw_ATT`1'`2'_`1' = vbkw_ATT`1'`2'_`1'
g vbkw_ATE`1'`2' = vbkw_ATE`1'`2'

g vbkw_ATT`1'`4'_`4' = vbkw_ATT`1'`4'_`4'
g vbkw_ATT`1'`4'_`1' = vbkw_ATT`1'`4'_`1'
g vbkw_ATE`1'`4' = vbkw_ATE`1'`4'

g vbkw_ATT`2'`3'_`3' = vbkw_ATT`2'`3'_`3'
g vbkw_ATT`2'`3'_`2' = vbkw_ATT`2'`3'_`2'
g vbkw_ATE`2'`3' = vbkw_ATE`2'`3'

g vbkw_ATT`2'`4'_`4' = vbkw_ATT`2'`4'_`4'
g vbkw_ATT`2'`4'_`2' = vbkw_ATT`2'`4'_`2'
g vbkw_ATE`2'`4' = vbkw_ATE`2'`4'

g vbkw_ATT`3'`4'_`4' = vbkw_ATT`3'`4'_`4'
g vbkw_ATT`3'`4'_`3' = vbkw_ATT`3'`4'_`3'
g vbkw_ATE`3'`4' = vbkw_ATE`3'`4'



return scalar vbkw_ATT`1'`2'_`2'b = vbkw_ATT`1'`2'_`2'
return scalar vbkw_ATT`1'`2'_`1'b = vbkw_ATT`1'`2'_`1'
return scalar vbkw_ATE`1'`2'b = vbkw_ATE`1'`2'

return scalar vbkw_ATT`1'`3'_`3'b = vbkw_ATT`1'`3'_`3'
return scalar vbkw_ATT`1'`3'_`1'b = vbkw_ATT`1'`3'_`1'
return scalar vbkw_ATE`1'`3'b = vbkw_ATE`1'`3'

return scalar vbkw_ATT`2'`3'_`3'b = vbkw_ATT`2'`3'_`3'
return scalar vbkw_ATT`2'`3'_`2'b = vbkw_ATT`2'`3'_`2'
return scalar vbkw_ATE`2'`3'b = vbkw_ATE`2'`3'

return scalar vbkw_ATT`2'`4'_`4'b = vbkw_ATT`2'`4'_`4'
return scalar vbkw_ATT`2'`4'_`2'b = vbkw_ATT`2'`4'_`2'
return scalar vbkw_ATE`2'`4'b = vbkw_ATE`2'`4'

return scalar vbkw_ATT`3'`4'_`4'b = vbkw_ATT`3'`4'_`4'
return scalar vbkw_ATT`3'`4'_`3'b = vbkw_ATT`3'`4'_`3'
return scalar vbkw_ATE`3'`4'b = vbkw_ATE`3'`4'




}


if `n_cat' == 5 {

********************************************************************************

*Set up the variables needed to run the VBKW matching algorithm. 
*I want the code to estimate all combination of atts and ates with each run of the program. 
*For a setting with 3 treatment groups, there will be 6 ATTs to estimate and 3 ATEs.

tempname treat_01

*1. generate the comparison vars: 
tokenize `levels'
cap drop `treat_01'
gen `treat_01' = 1 if `treat' == `1' & `touse'
replace `treat_01' = 0 if `treat' == `2' & `touse'

tab `treat_01'

capture drop _ATTsupport _ATUsupport
capture drop _ATTweight _ATUweight _ATEweight
capture drop _ATTtrueY _ATUtrueY

gen byte _ATTsupport = .
replace _ATTsupport = (`treat_01' <= 1)
gen double _ATTtrueY = 0 if _ATTsupport // ATT matched outcome 
 
gen byte _ATUsupport = .
replace _ATUsupport = (`treat_01' <=1)
gen double _ATUtrueY = 0 if _ATUsupport // ATU matched outcome 

gen double _ATUweight = 1 - `treat_01' if _ATUsupport == 1 
gen double _ATTweight = `treat_01' if _ATTsupport == 1

********************************************************************************
di "VBKW ATT `1' v `2' | T = `2' estimation:"

cap drop n_used
g double n_used = 0 if `treat_01' !=. 


*for now, the outcome used in estimating the counterfactual outcome is based on just the first outcome listed in outcome(varlist)
gettoken outcome1 otheroutcomes : outcome

di "The outcome we use to estimate the counterfactual is: `outcome1'"

sort `treat_01' id 
local vars ps`2' _ATUsupport _ATUtrueY _ATUweight `outcome1' n_used
local method vbkw 
count if `treat' == `2' 
local nref = r(N)
count if `treat' == `1' 
local ncomp = r(N)
*NOTE: I've made changes to the way we specify the arguments: specification of the bandwidths and ps vars are now to stay the same regardless of which treatment effect is being estimated.
mata: match5("`vars'", "`kerneltype'", `nref', `ncomp', `bandwidth`1'', `bandwidth`2'', `bandwidth`3'', `bandwidth`4'', `bandwidth`5'', "ps`1'", "ps`2'", "ps`3'", "ps`4'", "ps`5'")
replace _ATUsupport = 0 if _ATUweight == 0 | _ATUweight == . 



/*
if "`nmatched'" == "yes" {
*for reference subjects, n_used gives us the number of comparison subjects used to calculate
*the counterfactual outcomes for each reference subject. 
sum n_used if _ATUsupport == 1 & treat == 2, detail
return scalar vbkw_ATT122_compused_mu = r(mean)
return scalar vbkw_ATT122_compused_p50 = r(p50)
return scalar vbkw_ATT122_compused_min = r(min)
return scalar vbkw_ATT122_compused_max = r(max)
*for comparison subjects, n_used gives the number of reference subjects each comparison subject
*has been matched to. 
sum n_used if _ATUsupport == 1 & treat == 1, detail
return scalar vbkw_ATT122_refmatched_mu = r(mean)
return scalar vbkw_ATT122_refmatched_p50 = r(p50)
return scalar vbkw_ATT122_refmatched_min = r(min)
return scalar vbkw_ATT122_refmatched_max = r(max)
}
*/
*of the treat = 2 reference subjects on overall common support, how many of them were able to find matches? 
count if _ATUsupport == 1 & `treat' == `2'
scalar on = r(N)
count if `treat' == `2'
scalar total = r(N)

*scalar vbkw_122_matched_pct = (on/total)*100 

*ATT 1 v 2 | T = 2: 
sum _ATUtrueY if `treat' == `2' & _ATUsupport == 1 
scalar m1u = r(mean)
local N2 = r(N)
sum `outcome1' if `treat' == `2' & _ATUsupport == 1 
scalar m2u = r(mean)
scalar vbkw_ATU = m1u - m2u 

scalar vbkw_ATT`1'`2'_`2' = vbkw_ATU


rename n_used n_used_ATT`1'`2'`2'
********************************************************************************

di "VBKW ATT `1' v `2' | T = `1' estimation:"

cap drop n_used
g double n_used = 0 if `treat_01' !=. 

gsort -`treat_01' id 
local vars ps`1' _ATTsupport _ATTtrueY _ATTweight `outcome1' n_used
local method vbkw 
count if `treat' == `1' 
local nref = r(N)
count if `treat' == `2' 
local ncomp = r(N)
mata: match5("`vars'", "`kerneltype'", `nref', `ncomp', `bandwidth`1'', `bandwidth`2'', `bandwidth`3'', `bandwidth`4'', `bandwidth`5'', "ps`1'", "ps`2'", "ps`3'", "ps`4'", "ps`5'")
replace _ATTsupport = 0 if _ATTweight == 0 | _ATTweight == . 
/*
if "`nmatched'" == "yes" {
*for reference subjects, n_used gives us the number of comparison subjects used to calculate
*the counterfactual outcomes for each reference subject. 
sum n_used if _ATTsupport == 1 & treat == 1, detail
return scalar vbkw_ATT121_compused_mu = r(mean)
return scalar vbkw_ATT121_compused_p50 = r(p50)
return scalar vbkw_ATT121_compused_min = r(min)
return scalar vbkw_ATT121_compused_max = r(max)
*for comparison subjects, n_used gives the number of reference subjects each comparison subject
*has been matched to. 
sum n_used if _ATTsupport == 1 & treat == 2, detail
return scalar vbkw_ATT121_refmatched_mu = r(mean)
return scalar vbkw_ATT121_refmatched_p50 = r(p50)
return scalar vbkw_ATT121_refmatched_min = r(min)
return scalar vbkw_ATT121_refmatched_max = r(max)
}
*/
*of the treat = 1 reference subjects on overall common support, how many of them were able to find matches? 
count if _ATTsupport == 1 & `treat' == `1'
scalar on = r(N)
count if `treat' == `1'
scalar total = r(N)

*scalar vbkw_121_matched_pct = (on/total)*100 
*ATT 1 v 2 | T = 1: 
sum `outcome1' if `treat' == `1' & _ATTsupport == 1 
scalar m1t = r(mean)
local N1 = r(N)
sum _ATTtrueY if `treat' == `1' & _ATTsupport == 1 
scalar m2t = r(mean)
scalar vbkw_ATT = m1t - m2t

scalar vbkw_ATT`1'`2'_`1' = vbkw_ATT 
scalar vbkw_ATE`1'`2' = (vbkw_ATT*`N1'/(`N1'+`N2')) +  (vbkw_ATU*`N2'/(`N1'+`N2'))
gen double _ATEweight = _ATTweight + _ATUweight if `treat_01' <= 1


rename n_used n_used_ATT`1'`2'`1'
compress


cap drop  ATTsupport`1'`2'_`1'
cap drop  ATTweight`1'`2'_`1'
cap drop  ATUsupport`1'`2'_`2'
cap drop  ATUweight`1'`2'_`2'
cap drop  ATEweight`1'`2'

cap drop  ATTsupport`1'`3'_`1'
cap drop  ATTweight`1'`3'_`1'
cap drop  ATUsupport`1'`3'_`3'
cap drop  ATUweight`1'`3'_`3'
cap drop  ATEweight`1'`3'

cap drop  ATTsupport`1'`4'_`1'
cap drop  ATTweight`1'`4'_`1'
cap drop  ATUsupport`1'`4'_`4'
cap drop  ATUweight`1'`4'_`4'
cap drop  ATEweight`1'`4'

cap drop  ATTsupport`1'`5'_`1'
cap drop  ATTweight`1'`5'_`1'
cap drop  ATUsupport`1'`5'_`5'
cap drop  ATUweight`1'`5'_`5'
cap drop  ATEweight`1'`5'

cap drop  ATTsupport`2'`3'_`2'
cap drop  ATTweight`2'`3'_`2'
cap drop  ATUsupport`2'`3'_`3'
cap drop  ATUweight`2'`3'_`3'
cap drop  ATEweight`2'`3'

cap drop  ATTsupport`2'`4'_`2'
cap drop  ATTweight`2'`4'_`2'
cap drop  ATUsupport`2'`4'_`4'
cap drop  ATUweight`2'`4'_`4'
cap drop  ATEweight`2'`4'

cap drop  ATTsupport`2'`5'_`2'
cap drop  ATTweight`2'`5'_`2'
cap drop  ATUsupport`2'`5'_`5'
cap drop  ATUweight`2'`5'_`5'
cap drop  ATEweight`2'`5'

cap drop  ATTsupport`3'`4'_`3'
cap drop  ATTweight`3'`4'_`3'
cap drop  ATUsupport`3'`4'_`4'
cap drop  ATUweight`3'`4'_`4'
cap drop  ATEweight`3'`4'

cap drop  ATTsupport`3'`5'_`3'
cap drop  ATTweight`3'`5'_`3'
cap drop  ATUsupport`3'`5'_`5'
cap drop  ATUweight`3'`5'_`5'
cap drop  ATEweight`3'`5'

cap drop  ATTsupport`4'`5'_`4'
cap drop  ATTweight`4'`5'_`4'
cap drop  ATUsupport`4'`5'_`5'
cap drop  ATUweight`4'`5'_`5'
cap drop  ATEweight`4'`5'

clonevar  ATTsupport`1'`2'_`1' = _ATTsupport
clonevar  ATTweight`1'`2'_`1' = _ATTweight
clonevar  ATUsupport`1'`2'_`2' = _ATUsupport
clonevar  ATUweight`1'`2'_`2' = _ATUweight
clonevar  ATEweight`1'`2' = _ATEweight



********************************************************************************
*Estimate the treatment effects for 1 vs. 3: 
********************************************************************************

tempname treat_01

*1. generate the comparison vars: 
tokenize `levels'
cap drop `treat_01'
gen `treat_01' = 1 if `treat' == `1' & `touse'
replace `treat_01' = 0 if `treat' == `3' & `touse'

tab `treat_01'

capture drop _ATTsupport _ATUsupport
capture drop _ATTweight _ATUweight _ATEweight
capture drop _ATTtrueY _ATUtrueY

gen byte _ATTsupport = .
replace _ATTsupport = (`treat_01' <= 1)
gen double _ATTtrueY = 0 if _ATTsupport // ATT matched outcome 
 
gen byte _ATUsupport = .
replace _ATUsupport = (`treat_01' <=1)
gen double _ATUtrueY = 0 if _ATUsupport // ATU matched outcome 

gen double _ATUweight = 1 - `treat_01' if _ATUsupport == 1 
gen double _ATTweight = `treat_01' if _ATTsupport == 1

********************************************************************************
di "VBKW ATT `1' v `3' | T = `3' estimation:"

cap drop n_used
g double n_used = 0 if `treat_01' !=. 


*for now, the outcome used in estimating the counterfactual outcome is based on just the first outcome listed in outcome(varlist)
gettoken outcome1 otheroutcomes : outcome

di "The outcome we use to estimate the counterfactual is: `outcome1'"

sort `treat_01' id 
local vars ps`3' _ATUsupport _ATUtrueY _ATUweight `outcome1' n_used
local method vbkw 
count if `treat' == `3' 
local nref = r(N)
count if `treat' == `1' 
local ncomp = r(N)
*NOTE: I've made changes to the way we specify the arguments: specification of the bandwidths and ps vars are now to stay the same regardless of which treatment effect is being estimated.
mata: match5("`vars'", "`kerneltype'", `nref', `ncomp', `bandwidth`1'', `bandwidth`2'', `bandwidth`3'', `bandwidth`4'', `bandwidth`5'', "ps`1'", "ps`2'", "ps`3'", "ps`4'", "ps`5'")
replace _ATUsupport = 0 if _ATUweight == 0 | _ATUweight == . 

*of the treat = 3 reference subjects on overall common support, how many of them were able to find matches? 
count if _ATUsupport == 1 & `treat' == `3'
scalar on = r(N)
count if `treat' == `3'
scalar total = r(N)

*scalar vbkw_133_matched_pct = (on/total)*100 

*ATT 1 v 3 | T = 3: 
sum _ATUtrueY if `treat' == `3' & _ATUsupport == 1 
scalar m1u = r(mean)
local N2 = r(N)
sum `outcome1' if `treat' == `3' & _ATUsupport == 1 
scalar m2u = r(mean)
scalar vbkw_ATU = m1u - m2u 

scalar vbkw_ATT`1'`3'_`3' = vbkw_ATU

rename n_used n_used_ATT`1'`3'`3'
********************************************************************************

di "VBKW ATT `1' v `3' | T = `1' estimation:"

cap drop n_used
g double n_used = 0 if `treat_01' !=. 

gsort -`treat_01' id 
local vars ps`1' _ATTsupport _ATTtrueY _ATTweight `outcome1' n_used
local method vbkw 
count if `treat' == `1' 
local nref = r(N)
count if `treat' == `3' 
local ncomp = r(N)
mata: match5("`vars'", "`kerneltype'", `nref', `ncomp', `bandwidth`1'', `bandwidth`2'', `bandwidth`3'', `bandwidth`4'', `bandwidth`5'', "ps`1'", "ps`2'", "ps`3'", "ps`4'", "ps`5'")
replace _ATTsupport = 0 if _ATTweight == 0 | _ATTweight == . 

*of the treat = 1 reference subjects on overall common support, how many of them were able to find matches? 
count if _ATTsupport == 1 & `treat' == `1'
scalar on = r(N)
count if `treat' == `1'
scalar total = r(N)

*scalar vbkw_131_matched_pct = (on/total)*100 
*ATT 1 v 3 | T = 1: 
sum `outcome1' if `treat' == `1' & _ATTsupport == 1 
scalar m1t = r(mean)
local N1 = r(N)
sum _ATTtrueY if `treat' == `1' & _ATTsupport == 1 
scalar m2t = r(mean)
scalar vbkw_ATT = m1t - m2t

scalar vbkw_ATT`1'`3'_`1' = vbkw_ATT 
scalar vbkw_ATE`1'`3' = (vbkw_ATT*`N1'/(`N1'+`N2')) +  (vbkw_ATU*`N2'/(`N1'+`N2'))
gen double _ATEweight = _ATTweight + _ATUweight if `treat_01' <= 1

rename n_used n_used_ATT`1'`3'`1'
compress

clonevar  ATTsupport`1'`3'_`1' = _ATTsupport
clonevar  ATTweight`1'`3'_`1' = _ATTweight
clonevar  ATUsupport`1'`3'_`3' = _ATUsupport
clonevar  ATUweight`1'`3'_`3' = _ATUweight
clonevar  ATEweight`1'`3' = _ATEweight



********************************************************************************
*Estimate the treatment effects for 1 vs. 4: 
********************************************************************************

tempname treat_01

*1. generate the comparison vars: 
tokenize `levels'
cap drop `treat_01'
gen `treat_01' = 1 if `treat' == `1' & `touse'
replace `treat_01' = 0 if `treat' == `4' & `touse'

tab `treat_01'

capture drop _ATTsupport _ATUsupport
capture drop _ATTweight _ATUweight _ATEweight
capture drop _ATTtrueY _ATUtrueY

gen byte _ATTsupport = .
replace _ATTsupport = (`treat_01' <= 1)
gen double _ATTtrueY = 0 if _ATTsupport // ATT matched outcome 
 
gen byte _ATUsupport = .
replace _ATUsupport = (`treat_01' <=1)
gen double _ATUtrueY = 0 if _ATUsupport // ATU matched outcome 

gen double _ATUweight = 1 - `treat_01' if _ATUsupport == 1 
gen double _ATTweight = `treat_01' if _ATTsupport == 1

********************************************************************************
di "VBKW ATT `1' v `4' | T = `4' estimation:"

cap drop n_used
g double n_used = 0 if `treat_01' !=. 


*for now, the outcome used in estimating the counterfactual outcome is based on just the first outcome listed in outcome(varlist)
gettoken outcome1 otheroutcomes : outcome

di "The outcome we use to estimate the counterfactual is: `outcome1'"

sort `treat_01' id 
local vars ps`4' _ATUsupport _ATUtrueY _ATUweight `outcome1' n_used
local method vbkw 
count if `treat' == `4' 
local nref = r(N)
count if `treat' == `1' 
local ncomp = r(N)
*NOTE: I've made changes to the way we specify the arguments: specification of the bandwidths and ps vars are now to stay the same regardless of which treatment effect is being estimated.
mata: match5("`vars'", "`kerneltype'", `nref', `ncomp', `bandwidth`1'', `bandwidth`2'', `bandwidth`3'', `bandwidth`4'', `bandwidth`5'', "ps`1'", "ps`2'", "ps`3'", "ps`4'", "ps`5'")
replace _ATUsupport = 0 if _ATUweight == 0 | _ATUweight == . 

*of the treat = 4 reference subjects on overall common support, how many of them were able to find matches? 
count if _ATUsupport == 1 & `treat' == `4'
scalar on = r(N)
count if `treat' == `4'
scalar total = r(N)

*scalar vbkw_144_matched_pct = (on/total)*100 

*ATT 1 v 4 | T = 4: 
sum _ATUtrueY if `treat' == `4' & _ATUsupport == 1 
scalar m1u = r(mean)
local N2 = r(N)
sum `outcome1' if `treat' == `4' & _ATUsupport == 1 
scalar m2u = r(mean)
scalar vbkw_ATU = m1u - m2u 

scalar vbkw_ATT`1'`4'_`4' = vbkw_ATU

rename n_used n_used_ATT`1'`4'`4'
********************************************************************************

di "VBKW ATT `1' v `4' | T = `1' estimation:"

cap drop n_used
g double n_used = 0 if `treat_01' !=. 

gsort -`treat_01' id 
local vars ps`1' _ATTsupport _ATTtrueY _ATTweight `outcome1' n_used
local method vbkw 
count if `treat' == `1' 
local nref = r(N)
count if `treat' == `4' 
local ncomp = r(N)
mata: match5("`vars'", "`kerneltype'", `nref', `ncomp', `bandwidth`1'', `bandwidth`2'', `bandwidth`3'', `bandwidth`4'', `bandwidth`5'', "ps`1'", "ps`2'", "ps`3'", "ps`4'", "ps`5'")
replace _ATTsupport = 0 if _ATTweight == 0 | _ATTweight == . 

*of the treat = 1 reference subjects on overall common support, how many of them were able to find matches? 
count if _ATTsupport == 1 & `treat' == `1'
scalar on = r(N)
count if `treat' == `1'
scalar total = r(N)

*scalar vbkw_141_matched_pct = (on/total)*100 
*ATT 1 v 4 | T = 1: 
sum `outcome1' if `treat' == `1' & _ATTsupport == 1 
scalar m1t = r(mean)
local N1 = r(N)
sum _ATTtrueY if `treat' == `1' & _ATTsupport == 1 
scalar m2t = r(mean)
scalar vbkw_ATT = m1t - m2t

scalar vbkw_ATT`1'`4'_`1' = vbkw_ATT 
scalar vbkw_ATE`1'`4' = (vbkw_ATT*`N1'/(`N1'+`N2')) +  (vbkw_ATU*`N2'/(`N1'+`N2'))
gen double _ATEweight = _ATTweight + _ATUweight if `treat_01' <= 1

rename n_used n_used_ATT`1'`4'`1'
compress

clonevar  ATTsupport`1'`4'_`1' = _ATTsupport
clonevar  ATTweight`1'`4'_`1' = _ATTweight
clonevar  ATUsupport`1'`4'_`4' = _ATUsupport
clonevar  ATUweight`1'`4'_`4' = _ATUweight
clonevar  ATEweight`1'`4' = _ATEweight

********************************************************************************
*Estimate the treatment effects for 1 vs. 5: 
********************************************************************************

tempname treat_01

*1. generate the comparison vars: 
tokenize `levels'
cap drop `treat_01'
gen `treat_01' = 1 if `treat' == `1' & `touse'
replace `treat_01' = 0 if `treat' == `5' & `touse'

tab `treat_01'

capture drop _ATTsupport _ATUsupport
capture drop _ATTweight _ATUweight _ATEweight
capture drop _ATTtrueY _ATUtrueY

gen byte _ATTsupport = .
replace _ATTsupport = (`treat_01' <= 1)
gen double _ATTtrueY = 0 if _ATTsupport // ATT matched outcome 
 
gen byte _ATUsupport = .
replace _ATUsupport = (`treat_01' <=1)
gen double _ATUtrueY = 0 if _ATUsupport // ATU matched outcome 

gen double _ATUweight = 1 - `treat_01' if _ATUsupport == 1 
gen double _ATTweight = `treat_01' if _ATTsupport == 1

********************************************************************************
di "VBKW ATT `1' v `5' | T = `5' estimation:"

cap drop n_used
g double n_used = 0 if `treat_01' !=. 


*for now, the outcome used in estimating the counterfactual outcome is based on just the first outcome listed in outcome(varlist)
gettoken outcome1 otheroutcomes : outcome

di "The outcome we use to estimate the counterfactual is: `outcome1'"

sort `treat_01' id 
local vars ps`5' _ATUsupport _ATUtrueY _ATUweight `outcome1' n_used
local method vbkw 
count if `treat' == `5' 
local nref = r(N)
count if `treat' == `1' 
local ncomp = r(N)
*NOTE: I've made changes to the way we specify the arguments: specification of the bandwidths and ps vars are now to stay the same regardless of which treatment effect is being estimated.
mata: match5("`vars'", "`kerneltype'", `nref', `ncomp', `bandwidth`1'', `bandwidth`2'', `bandwidth`3'', `bandwidth`4'', `bandwidth`5'', "ps`1'", "ps`2'", "ps`3'", "ps`4'", "ps`5'")
replace _ATUsupport = 0 if _ATUweight == 0 | _ATUweight == . 

*of the treat = 5 reference subjects on overall common support, how many of them were able to find matches? 
count if _ATUsupport == 1 & `treat' == `5'
scalar on = r(N)
count if `treat' == `5'
scalar total = r(N)

*scalar vbkw_155_matched_pct = (on/total)*100 

*ATT 1 v 5 | T = 5: 
sum _ATUtrueY if `treat' == `5' & _ATUsupport == 1 
scalar m1u = r(mean)
local N2 = r(N)
sum `outcome1' if `treat' == `5' & _ATUsupport == 1 
scalar m2u = r(mean)
scalar vbkw_ATU = m1u - m2u 

scalar vbkw_ATT`1'`5'_`5' = vbkw_ATU

rename n_used n_used_ATT`1'`5'`5'
********************************************************************************

di "VBKW ATT `1' v `5' | T = `1' estimation:"

cap drop n_used
g double n_used = 0 if `treat_01' !=. 

gsort -`treat_01' id 
local vars ps`1' _ATTsupport _ATTtrueY _ATTweight `outcome1' n_used
local method vbkw 
count if `treat' == `1' 
local nref = r(N)
count if `treat' == `5' 
local ncomp = r(N)
mata: match5("`vars'", "`kerneltype'", `nref', `ncomp', `bandwidth`1'', `bandwidth`2'', `bandwidth`3'', `bandwidth`4'', `bandwidth`5'', "ps`1'", "ps`2'", "ps`3'", "ps`4'", "ps`5'")
replace _ATTsupport = 0 if _ATTweight == 0 | _ATTweight == . 

*of the treat = 1 reference subjects on overall common support, how many of them were able to find matches? 
count if _ATTsupport == 1 & `treat' == `1'
scalar on = r(N)
count if `treat' == `1'
scalar total = r(N)

*scalar vbkw_151_matched_pct = (on/total)*100 
*ATT 1 v 5 | T = 1: 
sum `outcome1' if `treat' == `1' & _ATTsupport == 1 
scalar m1t = r(mean)
local N1 = r(N)
sum _ATTtrueY if `treat' == `1' & _ATTsupport == 1 
scalar m2t = r(mean)
scalar vbkw_ATT = m1t - m2t

scalar vbkw_ATT`1'`5'_`1' = vbkw_ATT 
scalar vbkw_ATE`1'`5' = (vbkw_ATT*`N1'/(`N1'+`N2')) +  (vbkw_ATU*`N2'/(`N1'+`N2'))
gen double _ATEweight = _ATTweight + _ATUweight if `treat_01' <= 1

rename n_used n_used_ATT`1'`5'`1'
compress

clonevar  ATTsupport`1'`5'_`1' = _ATTsupport
clonevar  ATTweight`1'`5'_`1' = _ATTweight
clonevar  ATUsupport`1'`5'_`5' = _ATUsupport
clonevar  ATUweight`1'`5'_`5' = _ATUweight
clonevar  ATEweight`1'`5' = _ATEweight

********************************************************************************
*Estimate the treatment effects for 2 vs. 3: 
********************************************************************************

tempname treat_01

*1. generate the comparison vars: 
tokenize `levels'
cap drop `treat_01'
gen `treat_01' = 1 if `treat' == `2' & `touse'
replace `treat_01' = 0 if `treat' == `3' & `touse'

tab `treat_01'

capture drop _ATTsupport _ATUsupport
capture drop _ATTweight _ATUweight _ATEweight
capture drop _ATTtrueY _ATUtrueY

gen byte _ATTsupport = .
replace _ATTsupport = (`treat_01' <= 1)
gen double _ATTtrueY = 0 if _ATTsupport // ATT matched outcome 
 
gen byte _ATUsupport = .
replace _ATUsupport = (`treat_01' <=1)
gen double _ATUtrueY = 0 if _ATUsupport // ATU matched outcome 

gen double _ATUweight = 1 - `treat_01' if _ATUsupport == 1 
gen double _ATTweight = `treat_01' if _ATTsupport == 1

********************************************************************************
di "VBKW ATT `2' v `3' | T = `3' estimation:"

cap drop n_used
g double n_used = 0 if `treat_01' !=. 


*for now, the outcome used in estimating the counterfactual outcome is based on just the first outcome listed in outcome(varlist)
gettoken outcome1 otheroutcomes : outcome

di "The outcome we use to estimate the counterfactual is: `outcome1'"

sort `treat_01' id 
local vars ps`3' _ATUsupport _ATUtrueY _ATUweight `outcome1' n_used
local method vbkw 
count if `treat' == `3' 
local nref = r(N)
count if `treat' == `2' 
local ncomp = r(N)
*NOTE: I've made changes to the way we specify the arguments: specification of the bandwidths and ps vars are now to stay the same regardless of which treatment effect is being estimated.
mata: match5("`vars'", "`kerneltype'", `nref', `ncomp', `bandwidth`1'', `bandwidth`2'', `bandwidth`3'', `bandwidth`4'', `bandwidth`5'', "ps`1'", "ps`2'", "ps`3'", "ps`4'", "ps`5'")
replace _ATUsupport = 0 if _ATUweight == 0 | _ATUweight == . 

*of the treat = 3 reference subjects on overall common support, how many of them were able to find matches? 
count if _ATUsupport == 1 & `treat' == `3'
scalar on = r(N)
count if `treat' == `3'
scalar total = r(N)

*scalar vbkw_233_matched_pct = (on/total)*100 

*ATT 2 v 3 | T = 3: 
sum _ATUtrueY if `treat' == `3' & _ATUsupport == 1 
scalar m1u = r(mean)
local N2 = r(N)
sum `outcome1' if `treat' == `3' & _ATUsupport == 1 
scalar m2u = r(mean)
scalar vbkw_ATU = m1u - m2u 

scalar vbkw_ATT`2'`3'_`3' = vbkw_ATU

rename n_used n_used_ATT`2'`3'`3'
********************************************************************************

di "VBKW ATT `2' v `3' | T = `2' estimation:"

cap drop n_used
g double n_used = 0 if `treat_01' !=. 

gsort -`treat_01' id 
local vars ps`2' _ATTsupport _ATTtrueY _ATTweight `outcome1' n_used
local method vbkw 
count if `treat' == `2' 
local nref = r(N)
count if `treat' == `3' 
local ncomp = r(N)
mata: match5("`vars'", "`kerneltype'", `nref', `ncomp', `bandwidth`1'', `bandwidth`2'', `bandwidth`3'', `bandwidth`4'', `bandwidth`5'', "ps`1'", "ps`2'", "ps`3'", "ps`4'", "ps`5'")
replace _ATTsupport = 0 if _ATTweight == 0 | _ATTweight == . 

*of the treat = 2 reference subjects on overall common support, how many of them were able to find matches? 
count if _ATTsupport == 1 & `treat' == `2'
scalar on = r(N)
count if `treat' == `2'
scalar total = r(N)

*scalar vbkw_232_matched_pct = (on/total)*100 
*ATT 2 v 3 | T = 2: 
sum `outcome1' if `treat' == `2' & _ATTsupport == 1 
scalar m1t = r(mean)
local N1 = r(N)
sum _ATTtrueY if `treat' == `2' & _ATTsupport == 1 
scalar m2t = r(mean)
scalar vbkw_ATT = m1t - m2t

scalar vbkw_ATT`2'`3'_`2' = vbkw_ATT 
scalar vbkw_ATE`2'`3' = (vbkw_ATT*`N1'/(`N1'+`N2')) +  (vbkw_ATU*`N2'/(`N1'+`N2'))
gen double _ATEweight = _ATTweight + _ATUweight if `treat_01' <= 1

rename n_used n_used_ATT`2'`3'`2'
compress

clonevar  ATTsupport`2'`3'_`2' = _ATTsupport
clonevar  ATTweight`2'`3'_`2' = _ATTweight
clonevar  ATUsupport`2'`3'_`3' = _ATUsupport
clonevar  ATUweight`2'`3'_`3' = _ATUweight
clonevar  ATEweight`2'`3' = _ATEweight

********************************************************************************
*Estimate the treatment effects for 2 vs. 4: 
********************************************************************************

tempname treat_01

*1. generate the comparison vars: 
tokenize `levels'
cap drop `treat_01'
gen `treat_01' = 1 if `treat' == `2' & `touse'
replace `treat_01' = 0 if `treat' == `4' & `touse'

tab `treat_01'

capture drop _ATTsupport _ATUsupport
capture drop _ATTweight _ATUweight _ATEweight
capture drop _ATTtrueY _ATUtrueY

gen byte _ATTsupport = .
replace _ATTsupport = (`treat_01' <= 1)
gen double _ATTtrueY = 0 if _ATTsupport // ATT matched outcome 
 
gen byte _ATUsupport = .
replace _ATUsupport = (`treat_01' <=1)
gen double _ATUtrueY = 0 if _ATUsupport // ATU matched outcome 

gen double _ATUweight = 1 - `treat_01' if _ATUsupport == 1 
gen double _ATTweight = `treat_01' if _ATTsupport == 1

********************************************************************************
di "VBKW ATT `2' v `4' | T = `4' estimation:"

cap drop n_used
g double n_used = 0 if `treat_01' !=. 


*for now, the outcome used in estimating the counterfactual outcome is based on just the first outcome listed in outcome(varlist)
gettoken outcome1 otheroutcomes : outcome

di "The outcome we use to estimate the counterfactual is: `outcome1'"

sort `treat_01' id 
local vars ps`4' _ATUsupport _ATUtrueY _ATUweight `outcome1' n_used
local method vbkw 
count if `treat' == `4' 
local nref = r(N)
count if `treat' == `2' 
local ncomp = r(N)
*NOTE: I've made changes to the way we specify the arguments: specification of the bandwidths and ps vars are now to stay the same regardless of which treatment effect is being estimated.
mata: match5("`vars'", "`kerneltype'", `nref', `ncomp', `bandwidth`1'', `bandwidth`2'', `bandwidth`3'', `bandwidth`4'', `bandwidth`5'',"ps`1'", "ps`2'", "ps`3'", "ps`4'", "ps`5'")
replace _ATUsupport = 0 if _ATUweight == 0 | _ATUweight == . 

*of the treat = 4 reference subjects on overall common support, how many of them were able to find matches? 
count if _ATUsupport == 1 & `treat' == `4'
scalar on = r(N)
count if `treat' == `4'
scalar total = r(N)

*scalar vbkw_244_matched_pct = (on/total)*100 

*ATT 2 v 4 | T = 4: 
sum _ATUtrueY if `treat' == `4' & _ATUsupport == 1 
scalar m1u = r(mean)
local N2 = r(N)
sum `outcome1' if `treat' == `4' & _ATUsupport == 1 
scalar m2u = r(mean)
scalar vbkw_ATU = m1u - m2u 

scalar vbkw_ATT`2'`4'_`4' = vbkw_ATU

rename n_used n_used_ATT`2'`4'`4'
********************************************************************************

di "VBKW ATT `2' v `4' | T = `2' estimation:"

cap drop n_used
g double n_used = 0 if `treat_01' !=. 

gsort -`treat_01' id 
local vars ps`2' _ATTsupport _ATTtrueY _ATTweight `outcome1' n_used
local method vbkw 
count if `treat' == `2' 
local nref = r(N)
count if `treat' == `4' 
local ncomp = r(N)
mata: match5("`vars'", "`kerneltype'", `nref', `ncomp', `bandwidth`1'', `bandwidth`2'', `bandwidth`3'', `bandwidth`4'', `bandwidth`5'', "ps`1'", "ps`2'", "ps`3'", "ps`4'", "ps`5'")
replace _ATTsupport = 0 if _ATTweight == 0 | _ATTweight == . 

*of the treat = 2 reference subjects on overall common support, how many of them were able to find matches? 
count if _ATTsupport == 1 & `treat' == `2'
scalar on = r(N)
count if `treat' == `2'
scalar total = r(N)

*scalar vbkw_242_matched_pct = (on/total)*100 
*ATT 2 v 4 | T = 2: 
sum `outcome1' if `treat' == `2' & _ATTsupport == 1 
scalar m1t = r(mean)
local N1 = r(N)
sum _ATTtrueY if `treat' == `2' & _ATTsupport == 1 
scalar m2t = r(mean)
scalar vbkw_ATT = m1t - m2t

scalar vbkw_ATT`2'`4'_`2' = vbkw_ATT 
scalar vbkw_ATE`2'`4' = (vbkw_ATT*`N1'/(`N1'+`N2')) +  (vbkw_ATU*`N2'/(`N1'+`N2'))
gen double _ATEweight = _ATTweight + _ATUweight if `treat_01' <= 1

rename n_used n_used_ATT`2'`4'`2'
compress

clonevar  ATTsupport`2'`4'_`2' = _ATTsupport
clonevar  ATTweight`2'`4'_`2' = _ATTweight
clonevar  ATUsupport`2'`4'_`4' = _ATUsupport
clonevar  ATUweight`2'`4'_`4' = _ATUweight
clonevar  ATEweight`2'`4' = _ATEweight


********************************************************************************
*Estimate the treatment effects for 2 vs. 5: 
********************************************************************************

tempname treat_01

*1. generate the comparison vars: 
tokenize `levels'
cap drop `treat_01'
gen `treat_01' = 1 if `treat' == `2' & `touse'
replace `treat_01' = 0 if `treat' == `5' & `touse'

tab `treat_01'

capture drop _ATTsupport _ATUsupport
capture drop _ATTweight _ATUweight _ATEweight
capture drop _ATTtrueY _ATUtrueY

gen byte _ATTsupport = .
replace _ATTsupport = (`treat_01' <= 1)
gen double _ATTtrueY = 0 if _ATTsupport // ATT matched outcome 
 
gen byte _ATUsupport = .
replace _ATUsupport = (`treat_01' <=1)
gen double _ATUtrueY = 0 if _ATUsupport // ATU matched outcome 

gen double _ATUweight = 1 - `treat_01' if _ATUsupport == 1 
gen double _ATTweight = `treat_01' if _ATTsupport == 1

********************************************************************************
di "VBKW ATT `2' v `5' | T = `5' estimation:"

cap drop n_used
g double n_used = 0 if `treat_01' !=. 


*for now, the outcome used in estimating the counterfactual outcome is based on just the first outcome listed in outcome(varlist)
gettoken outcome1 otheroutcomes : outcome

di "The outcome we use to estimate the counterfactual is: `outcome1'"

sort `treat_01' id 
local vars ps`5' _ATUsupport _ATUtrueY _ATUweight `outcome1' n_used
local method vbkw 
count if `treat' == `5' 
local nref = r(N)
count if `treat' == `2' 
local ncomp = r(N)
*NOTE: I've made changes to the way we specify the arguments: specification of the bandwidths and ps vars are now to stay the same regardless of which treatment effect is being estimated.
mata: match5("`vars'", "`kerneltype'", `nref', `ncomp', `bandwidth`1'', `bandwidth`2'', `bandwidth`3'', `bandwidth`4'', `bandwidth`5'',"ps`1'", "ps`2'", "ps`3'", "ps`4'", "ps`5'")
replace _ATUsupport = 0 if _ATUweight == 0 | _ATUweight == . 

*of the treat = 5 reference subjects on overall common support, how many of them were able to find matches? 
count if _ATUsupport == 1 & `treat' == `5'
scalar on = r(N)
count if `treat' == `5'
scalar total = r(N)

*scalar vbkw_255_matched_pct = (on/total)*100 

*ATT 2 v 5 | T = 5: 
sum _ATUtrueY if `treat' == `5' & _ATUsupport == 1 
scalar m1u = r(mean)
local N2 = r(N)
sum `outcome1' if `treat' == `5' & _ATUsupport == 1 
scalar m2u = r(mean)
scalar vbkw_ATU = m1u - m2u 

scalar vbkw_ATT`2'`5'_`5' = vbkw_ATU

rename n_used n_used_ATT`2'`5'`5'
********************************************************************************

di "VBKW ATT `2' v `5' | T = `2' estimation:"

cap drop n_used
g double n_used = 0 if `treat_01' !=. 

gsort -`treat_01' id 
local vars ps`2' _ATTsupport _ATTtrueY _ATTweight `outcome1' n_used
local method vbkw 
count if `treat' == `2' 
local nref = r(N)
count if `treat' == `5' 
local ncomp = r(N)
mata: match5("`vars'", "`kerneltype'", `nref', `ncomp', `bandwidth`1'', `bandwidth`2'', `bandwidth`3'', `bandwidth`4'', `bandwidth`5'', "ps`1'", "ps`2'", "ps`3'", "ps`4'", "ps`5'")
replace _ATTsupport = 0 if _ATTweight == 0 | _ATTweight == . 

*of the treat = 2 reference subjects on overall common support, how many of them were able to find matches? 
count if _ATTsupport == 1 & `treat' == `2'
scalar on = r(N)
count if `treat' == `2'
scalar total = r(N)

*scalar vbkw_252_matched_pct = (on/total)*100 
*ATT 2 v 5 | T = 2: 
sum `outcome1' if `treat' == `2' & _ATTsupport == 1 
scalar m1t = r(mean)
local N1 = r(N)
sum _ATTtrueY if `treat' == `2' & _ATTsupport == 1 
scalar m2t = r(mean)
scalar vbkw_ATT = m1t - m2t

scalar vbkw_ATT`2'`5'_`2' = vbkw_ATT 
scalar vbkw_ATE`2'`5' = (vbkw_ATT*`N1'/(`N1'+`N2')) +  (vbkw_ATU*`N2'/(`N1'+`N2'))
gen double _ATEweight = _ATTweight + _ATUweight if `treat_01' <= 1

rename n_used n_used_ATT`2'`5'`2'
compress

clonevar  ATTsupport`2'`5'_`2' = _ATTsupport
clonevar  ATTweight`2'`5'_`2' = _ATTweight
clonevar  ATUsupport`2'`5'_`5' = _ATUsupport
clonevar  ATUweight`2'`5'_`5' = _ATUweight
clonevar  ATEweight`2'`5' = _ATEweight

********************************************************************************
*Estimate the treatment effects for 3 vs. 4: 
********************************************************************************

tempname treat_01

*1. generate the comparison vars: 
tokenize `levels'
cap drop `treat_01'
gen `treat_01' = 1 if `treat' == `3' & `touse'
replace `treat_01' = 0 if `treat' == `4' & `touse'

tab `treat_01'

capture drop _ATTsupport _ATUsupport
capture drop _ATTweight _ATUweight _ATEweight
capture drop _ATTtrueY _ATUtrueY

gen byte _ATTsupport = .
replace _ATTsupport = (`treat_01' <= 1)
gen double _ATTtrueY = 0 if _ATTsupport // ATT matched outcome 
 
gen byte _ATUsupport = .
replace _ATUsupport = (`treat_01' <=1)
gen double _ATUtrueY = 0 if _ATUsupport // ATU matched outcome 

gen double _ATUweight = 1 - `treat_01' if _ATUsupport == 1 
gen double _ATTweight = `treat_01' if _ATTsupport == 1

********************************************************************************
di "VBKW ATT `3' v `4' | T = `4' estimation:"

cap drop n_used
g double n_used = 0 if `treat_01' !=. 


*for now, the outcome used in estimating the counterfactual outcome is based on just the first outcome listed in outcome(varlist)
gettoken outcome1 otheroutcomes : outcome

di "The outcome we use to estimate the counterfactual is: `outcome1'"

sort `treat_01' id 
local vars ps`4' _ATUsupport _ATUtrueY _ATUweight `outcome1' n_used
local method vbkw 
count if `treat' == `4' 
local nref = r(N)
count if `treat' == `3' 
local ncomp = r(N)
*NOTE: I've made changes to the way we specify the arguments: specification of the bandwidths and ps vars are now to stay the same regardless of which treatment effect is being estimated.
mata: match5("`vars'", "`kerneltype'", `nref', `ncomp', `bandwidth`1'', `bandwidth`2'', `bandwidth`3'', `bandwidth`4'', `bandwidth`5'',"ps`1'", "ps`2'", "ps`3'", "ps`4'", "ps`5'")
replace _ATUsupport = 0 if _ATUweight == 0 | _ATUweight == . 

*of the treat = 4 reference subjects on overall common support, how many of them were able to find matches? 
count if _ATUsupport == 1 & `treat' == `4'
scalar on = r(N)
count if `treat' == `4'
scalar total = r(N)

*scalar vbkw_344_matched_pct = (on/total)*100 

*ATT 3 v 4 | T = 4: 
sum _ATUtrueY if `treat' == `4' & _ATUsupport == 1 
scalar m1u = r(mean)
local N2 = r(N)
sum `outcome1' if `treat' == `4' & _ATUsupport == 1 
scalar m2u = r(mean)
scalar vbkw_ATU = m1u - m2u 

scalar vbkw_ATT`3'`4'_`4' = vbkw_ATU

rename n_used n_used_ATT`3'`4'`4'
********************************************************************************

di "VBKW ATT `3' v `4' | T = `3' estimation:"

cap drop n_used
g double n_used = 0 if `treat_01' !=. 

gsort -`treat_01' id 
local vars ps`3' _ATTsupport _ATTtrueY _ATTweight `outcome1' n_used
local method vbkw 
count if `treat' == `3' 
local nref = r(N)
count if `treat' == `4' 
local ncomp = r(N)
mata: match5("`vars'", "`kerneltype'", `nref', `ncomp', `bandwidth`1'', `bandwidth`2'', `bandwidth`3'', `bandwidth`4'', `bandwidth`5'', "ps`1'", "ps`2'", "ps`3'", "ps`4'", "ps`5'")
replace _ATTsupport = 0 if _ATTweight == 0 | _ATTweight == . 

*of the treat = 3 reference subjects on overall common support, how many of them were able to find matches? 
count if _ATTsupport == 1 & `treat' == `3'
scalar on = r(N)
count if `treat' == `3'
scalar total = r(N)

*scalar vbkw_343_matched_pct = (on/total)*100 
*ATT 3 v 4 | T = 3: 
sum `outcome1' if `treat' == `3' & _ATTsupport == 1 
scalar m1t = r(mean)
local N1 = r(N)
sum _ATTtrueY if `treat' == `3' & _ATTsupport == 1 
scalar m2t = r(mean)
scalar vbkw_ATT = m1t - m2t

scalar vbkw_ATT`3'`4'_`3' = vbkw_ATT 
scalar vbkw_ATE`3'`4' = (vbkw_ATT*`N1'/(`N1'+`N2')) +  (vbkw_ATU*`N2'/(`N1'+`N2'))
gen double _ATEweight = _ATTweight + _ATUweight if `treat_01' <= 1

rename n_used n_used_ATT`3'`4'`3'
compress

clonevar  ATTsupport`3'`4'_`3' = _ATTsupport
clonevar  ATTweight`3'`4'_`3' = _ATTweight
clonevar  ATUsupport`3'`4'_`4' = _ATUsupport
clonevar  ATUweight`3'`4'_`4' = _ATUweight
clonevar  ATEweight`3'`4' = _ATEweight

********************************************************************************
*Estimate the treatment effects for 3 vs. 5: 
********************************************************************************

tempname treat_01

*1. generate the comparison vars: 
tokenize `levels'
cap drop `treat_01'
gen `treat_01' = 1 if `treat' == `3' & `touse'
replace `treat_01' = 0 if `treat' == `5' & `touse'

tab `treat_01'

capture drop _ATTsupport _ATUsupport
capture drop _ATTweight _ATUweight _ATEweight
capture drop _ATTtrueY _ATUtrueY

gen byte _ATTsupport = .
replace _ATTsupport = (`treat_01' <= 1)
gen double _ATTtrueY = 0 if _ATTsupport // ATT matched outcome 
 
gen byte _ATUsupport = .
replace _ATUsupport = (`treat_01' <=1)
gen double _ATUtrueY = 0 if _ATUsupport // ATU matched outcome 

gen double _ATUweight = 1 - `treat_01' if _ATUsupport == 1 
gen double _ATTweight = `treat_01' if _ATTsupport == 1

********************************************************************************
di "VBKW ATT `3' v `5' | T = `5' estimation:"

cap drop n_used
g double n_used = 0 if `treat_01' !=. 


*for now, the outcome used in estimating the counterfactual outcome is based on just the first outcome listed in outcome(varlist)
gettoken outcome1 otheroutcomes : outcome

di "The outcome we use to estimate the counterfactual is: `outcome1'"

sort `treat_01' id 
local vars ps`5' _ATUsupport _ATUtrueY _ATUweight `outcome1' n_used
local method vbkw 
count if `treat' == `5' 
local nref = r(N)
count if `treat' == `3' 
local ncomp = r(N)
*NOTE: I've made changes to the way we specify the arguments: specification of the bandwidths and ps vars are now to stay the same regardless of which treatment effect is being estimated.
mata: match5("`vars'", "`kerneltype'", `nref', `ncomp', `bandwidth`1'', `bandwidth`2'', `bandwidth`3'', `bandwidth`4'', `bandwidth`5'',"ps`1'", "ps`2'", "ps`3'", "ps`4'", "ps`5'")
replace _ATUsupport = 0 if _ATUweight == 0 | _ATUweight == . 

*of the treat = 5 reference subjects on overall common support, how many of them were able to find matches? 
count if _ATUsupport == 1 & `treat' == `5'
scalar on = r(N)
count if `treat' == `5'
scalar total = r(N)

*scalar vbkw_355_matched_pct = (on/total)*100 

*ATT 3 v 5 | T = 5: 
sum _ATUtrueY if `treat' == `5' & _ATUsupport == 1 
scalar m1u = r(mean)
local N2 = r(N)
sum `outcome1' if `treat' == `5' & _ATUsupport == 1 
scalar m2u = r(mean)
scalar vbkw_ATU = m1u - m2u 

scalar vbkw_ATT`3'`5'_`5' = vbkw_ATU

rename n_used n_used_ATT`3'`5'`5'
********************************************************************************

di "VBKW ATT `3' v `5' | T = `3' estimation:"

cap drop n_used
g double n_used = 0 if `treat_01' !=. 

gsort -`treat_01' id 
local vars ps`3' _ATTsupport _ATTtrueY _ATTweight `outcome1' n_used
local method vbkw 
count if `treat' == `3' 
local nref = r(N)
count if `treat' == `5' 
local ncomp = r(N)
mata: match5("`vars'", "`kerneltype'", `nref', `ncomp', `bandwidth`1'', `bandwidth`2'', `bandwidth`3'', `bandwidth`4'', `bandwidth`5'', "ps`1'", "ps`2'", "ps`3'", "ps`4'", "ps`5'")
replace _ATTsupport = 0 if _ATTweight == 0 | _ATTweight == . 

*of the treat = 3 reference subjects on overall common support, how many of them were able to find matches? 
count if _ATTsupport == 1 & `treat' == `3'
scalar on = r(N)
count if `treat' == `3'
scalar total = r(N)

*scalar vbkw_353_matched_pct = (on/total)*100 
*ATT 3 v 5 | T = 3: 
sum `outcome1' if `treat' == `3' & _ATTsupport == 1 
scalar m1t = r(mean)
local N1 = r(N)
sum _ATTtrueY if `treat' == `3' & _ATTsupport == 1 
scalar m2t = r(mean)
scalar vbkw_ATT = m1t - m2t

scalar vbkw_ATT`3'`5'_`3' = vbkw_ATT 
scalar vbkw_ATE`3'`5' = (vbkw_ATT*`N1'/(`N1'+`N2')) +  (vbkw_ATU*`N2'/(`N1'+`N2'))
gen double _ATEweight = _ATTweight + _ATUweight if `treat_01' <= 1

rename n_used n_used_ATT`3'`5'`3'
compress

clonevar  ATTsupport`3'`5'_`3' = _ATTsupport
clonevar  ATTweight`3'`5'_`3' = _ATTweight
clonevar  ATUsupport`3'`5'_`5' = _ATUsupport
clonevar  ATUweight`3'`5'_`5' = _ATUweight
clonevar  ATEweight`3'`5' = _ATEweight


********************************************************************************
*Estimate the treatment effects for 4 vs. 5: 
********************************************************************************

tempname treat_01

*1. generate the comparison vars: 
tokenize `levels'
cap drop `treat_01'
gen `treat_01' = 1 if `treat' == `4' & `touse'
replace `treat_01' = 0 if `treat' == `5' & `touse'

tab `treat_01'

capture drop _ATTsupport _ATUsupport
capture drop _ATTweight _ATUweight _ATEweight
capture drop _ATTtrueY _ATUtrueY

gen byte _ATTsupport = .
replace _ATTsupport = (`treat_01' <= 1)
gen double _ATTtrueY = 0 if _ATTsupport // ATT matched outcome 
 
gen byte _ATUsupport = .
replace _ATUsupport = (`treat_01' <=1)
gen double _ATUtrueY = 0 if _ATUsupport // ATU matched outcome 

gen double _ATUweight = 1 - `treat_01' if _ATUsupport == 1 
gen double _ATTweight = `treat_01' if _ATTsupport == 1

********************************************************************************
di "VBKW ATT `4' v `5' | T = `5' estimation:"

cap drop n_used
g double n_used = 0 if `treat_01' !=. 


*for now, the outcome used in estimating the counterfactual outcome is based on just the first outcome listed in outcome(varlist)
gettoken outcome1 otheroutcomes : outcome

di "The outcome we use to estimate the counterfactual is: `outcome1'"

sort `treat_01' id 
local vars ps`5' _ATUsupport _ATUtrueY _ATUweight `outcome1' n_used
local method vbkw 
count if `treat' == `5' 
local nref = r(N)
count if `treat' == `4' 
local ncomp = r(N)
*NOTE: I've made changes to the way we specify the arguments: specification of the bandwidths and ps vars are now to stay the same regardless of which treatment effect is being estimated.
mata: match5("`vars'", "`kerneltype'", `nref', `ncomp', `bandwidth`1'', `bandwidth`2'', `bandwidth`3'', `bandwidth`4'', `bandwidth`5'',"ps`1'", "ps`2'", "ps`3'", "ps`4'", "ps`5'")
replace _ATUsupport = 0 if _ATUweight == 0 | _ATUweight == . 

*of the treat = 5 reference subjects on overall common support, how many of them were able to find matches? 
count if _ATUsupport == 1 & `treat' == `5'
scalar on = r(N)
count if `treat' == `5'
scalar total = r(N)

*scalar vbkw_455_matched_pct = (on/total)*100 

*ATT 4 v 5 | T = 5: 
sum _ATUtrueY if `treat' == `5' & _ATUsupport == 1 
scalar m1u = r(mean)
local N2 = r(N)
sum `outcome1' if `treat' == `5' & _ATUsupport == 1 
scalar m2u = r(mean)
scalar vbkw_ATU = m1u - m2u 

scalar vbkw_ATT`4'`5'_`5' = vbkw_ATU

rename n_used n_used_ATT`4'`5'`5'
********************************************************************************

di "VBKW ATT `4' v `5' | T = `4' estimation:"

cap drop n_used
g double n_used = 0 if `treat_01' !=. 

gsort -`treat_01' id 
local vars ps`4' _ATTsupport _ATTtrueY _ATTweight `outcome1' n_used
local method vbkw 
count if `treat' == `4' 
local nref = r(N)
count if `treat' == `5' 
local ncomp = r(N)
mata: match5("`vars'", "`kerneltype'", `nref', `ncomp', `bandwidth`1'', `bandwidth`2'', `bandwidth`3'', `bandwidth`4'', `bandwidth`5'', "ps`1'", "ps`2'", "ps`3'", "ps`4'", "ps`5'")
replace _ATTsupport = 0 if _ATTweight == 0 | _ATTweight == . 

*of the treat = 4 reference subjects on overall common support, how many of them were able to find matches? 
count if _ATTsupport == 1 & `treat' == `4'
scalar on = r(N)
count if `treat' == `4'
scalar total = r(N)

*scalar vbkw_454_matched_pct = (on/total)*100 
*ATT 4 v 5 | T = 4: 
sum `outcome1' if `treat' == `4' & _ATTsupport == 1 
scalar m1t = r(mean)
local N1 = r(N)
sum _ATTtrueY if `treat' == `4' & _ATTsupport == 1 
scalar m2t = r(mean)
scalar vbkw_ATT = m1t - m2t

scalar vbkw_ATT`4'`5'_`4' = vbkw_ATT 
scalar vbkw_ATE`4'`5' = (vbkw_ATT*`N1'/(`N1'+`N2')) +  (vbkw_ATU*`N2'/(`N1'+`N2'))
gen double _ATEweight = _ATTweight + _ATUweight if `treat_01' <= 1

rename n_used n_used_ATT`4'`5'`4'
compress

clonevar  ATTsupport`4'`5'_`4' = _ATTsupport
clonevar  ATTweight`4'`5'_`4' = _ATTweight
clonevar  ATUsupport`4'`5'_`5' = _ATUsupport
clonevar  ATUweight`4'`5'_`5' = _ATUweight
clonevar  ATEweight`4'`5' = _ATEweight



********************************************************************************

scalar list vbkw_ATT`1'`3'_`3' vbkw_ATT`1'`3'_`1' vbkw_ATE`1'`3'
scalar list vbkw_ATT`1'`2'_`2' vbkw_ATT`1'`2'_`1' vbkw_ATE`1'`2'
scalar list vbkw_ATT`1'`4'_`4' vbkw_ATT`1'`4'_`1' vbkw_ATE`1'`4'
scalar list vbkw_ATT`1'`5'_`5' vbkw_ATT`1'`5'_`1' vbkw_ATE`1'`5'


scalar list vbkw_ATT`2'`3'_`3' vbkw_ATT`2'`3'_`2' vbkw_ATE`2'`3'
scalar list vbkw_ATT`2'`4'_`4' vbkw_ATT`2'`4'_`2' vbkw_ATE`2'`4'
scalar list vbkw_ATT`2'`5'_`5' vbkw_ATT`2'`5'_`2' vbkw_ATE`2'`5'

scalar list vbkw_ATT`3'`4'_`4' vbkw_ATT`3'`4'_`3' vbkw_ATE`3'`4'
scalar list vbkw_ATT`3'`5'_`5' vbkw_ATT`3'`5'_`3' vbkw_ATE`3'`5'

scalar list vbkw_ATT`4'`5'_`5' vbkw_ATT`4'`5'_`4' vbkw_ATE`4'`5'


********************************************************************************





cap drop  vbkw_ATT`1'`2'_`1'
cap drop  vbkw_ATT`1'`2'_`2'
cap drop  vbkw_ATE`1'`2'

cap drop  vbkw_ATT`1'`3'_`1'
cap drop  vbkw_ATT`1'`3'_`3'
cap drop  vbkw_ATE`1'`3'

cap drop  vbkw_ATT`1'`4'_`1'
cap drop  vbkw_ATT`1'`4'_`4'
cap drop  vbkw_ATE`1'`4'

cap drop  vbkw_ATT`1'`5'_`1'
cap drop  vbkw_ATT`1'`5'_`5'
cap drop  vbkw_ATE`1'`5'

cap drop  vbkw_ATT`2'`3'_`2'
cap drop  vbkw_ATT`2'`3'_`3'
cap drop  vbkw_ATE`2'`3'

cap drop  vbkw_ATT`2'`4'_`2'
cap drop  vbkw_ATT`2'`4'_`4'
cap drop  vbkw_ATE`2'`4'

cap drop  vbkw_ATT`2'`5'_`2'
cap drop  vbkw_ATT`2'`5'_`5'
cap drop  vbkw_ATE`2'`5'

cap drop  vbkw_ATT`3'`4'_`3'
cap drop  vbkw_ATT`3'`4'_`4'
cap drop  vbkw_ATE`3'`4'

cap drop  vbkw_ATT`3'`5'_`3'
cap drop  vbkw_ATT`3'`5'_`5'
cap drop  vbkw_ATE`3'`5'

cap drop  vbkw_ATT`4'`5'_`4'
cap drop  vbkw_ATT`4'`5'_`5'
cap drop  vbkw_ATE`4'`5'


g vbkw_ATT`1'`3'_`3' = vbkw_ATT`1'`3'_`3'
g vbkw_ATT`1'`3'_`1' = vbkw_ATT`1'`3'_`1'
g vbkw_ATE`1'`3' = vbkw_ATE`1'`3'

g vbkw_ATT`1'`2'_`2' = vbkw_ATT`1'`2'_`2'
g vbkw_ATT`1'`2'_`1' = vbkw_ATT`1'`2'_`1'
g vbkw_ATE`1'`2' = vbkw_ATE`1'`2'

g vbkw_ATT`1'`4'_`4' = vbkw_ATT`1'`4'_`4'
g vbkw_ATT`1'`4'_`1' = vbkw_ATT`1'`4'_`1'
g vbkw_ATE`1'`4' = vbkw_ATE`1'`4'

g vbkw_ATT`1'`5'_`5' = vbkw_ATT`1'`5'_`5'
g vbkw_ATT`1'`5'_`1' = vbkw_ATT`1'`5'_`1'
g vbkw_ATE`1'`5' = vbkw_ATE`1'`5'




g vbkw_ATT`2'`3'_`3' = vbkw_ATT`2'`3'_`3'
g vbkw_ATT`2'`3'_`2' = vbkw_ATT`2'`3'_`2'
g vbkw_ATE`2'`3' = vbkw_ATE`2'`3'

g vbkw_ATT`2'`4'_`4' = vbkw_ATT`2'`4'_`4'
g vbkw_ATT`2'`4'_`2' = vbkw_ATT`2'`4'_`2'
g vbkw_ATE`2'`4' = vbkw_ATE`2'`4'

g vbkw_ATT`2'`5'_`5' = vbkw_ATT`2'`5'_`5'
g vbkw_ATT`2'`5'_`2' = vbkw_ATT`2'`5'_`2'
g vbkw_ATE`2'`5' = vbkw_ATE`2'`5'



g vbkw_ATT`3'`4'_`4' = vbkw_ATT`3'`4'_`4'
g vbkw_ATT`3'`4'_`3' = vbkw_ATT`3'`4'_`3'
g vbkw_ATE`3'`4' = vbkw_ATE`3'`4'

g vbkw_ATT`3'`5'_`5' = vbkw_ATT`3'`5'_`5'
g vbkw_ATT`3'`5'_`3' = vbkw_ATT`3'`5'_`3'
g vbkw_ATE`3'`5' = vbkw_ATE`3'`5'


g vbkw_ATT`4'`5'_`5' = vbkw_ATT`4'`5'_`5'
g vbkw_ATT`4'`5'_`4' = vbkw_ATT`4'`5'_`4'
g vbkw_ATE`4'`5' = vbkw_ATE`4'`5'




}



/*

if ("`balance'" != "") {
**THIS HAS TO BE MODIFIED: automate the differentiation between continuous vars and discrete vars:
*********************************************************
	
*Placeholders for producing this graph only for 1 vs. 2:
				tempvar treated mweight support
				g `treated'= 1 if `treat' == `1' 
				replace `treated' = 0 if `treat' == `2'
				g `mweight' = ATTweight`1'`2'_`1'
				g `support' = ATTsupport`1'`2'_`1'
*********************************************************
				
				
		
        tempvar sumbias sumbias0 _bias0 _biasm xvar meanbiasbef medbiasbef meanbiasaft medbiasaft _vratio_bef _vratio_aft
        tempname Flowu Fhighu Flowm Fhighm

        qui count if `treated'==1 & `touse'
        scalar `Flowu'  = invF(r(N)-1, r(N)-1, 0.025)
        scalar `Fhighu' = invF(r(N)-1, r(N)-1, 0.975)

        qui count if `treated'==1 & `support'==1 & `touse'
        scalar `Flowm'  = invF(r(N)-1, r(N)-1, 0.025)
        scalar `Fhighm' = invF(r(N)-1, r(N)-1, 0.975)

        qui g `_bias0' = .
        qui g `_biasm' = .
        qui g str12 `xvar' = ""
        qui g `sumbias' = .
        qui g `sumbias0' = .

        qui g `_vratio_bef' = .
        qui g `_vratio_aft' = .

        fvexpand `xvars'      
        local hasfactorvars = ("`=r(fvops)'" == "true")
        local vnames `r(varlist)'
        local vlength 22
        foreach v of local vnames {
                local vlength = max(`vlength', length("`v'"))
        }
        
        /* construct header */
        local c = `vlength' + 4
        local s = `vlength' - 22
		

        `quietly' di
        `quietly' di as text "{hline `c'}{c TT}{hline 34}{c TT}{hline 15}{c TT}{hline 10}"
        `quietly' di as text "              " _s(`s') "  Unmatched {c |}       Mean               %reduct {c |}     t-test    {c |}  V`add'(T)/"
        `quietly' di as text "Variable      " _s(`s') "    Matched {c |} Treated Control    %bias  |bias| {c |}    t    p>|t| {c |}  V`add'(C)" 
        `quietly' di as text "{hline `c'}{c +}{hline 34}{c +}{hline 15}{c +}{hline 10}"
        
        
        /* calculate stats for varlist */
        tempname m1u m0u v1u v0u m1m m0m bias biasm absreduc tbef taft pbef paft 
        tempname v1m v0m v_ratiobef v_ratioaft v_e_1
        tempvar resid0 resid1
        local cnt_concbef = 0  /* counting vars with ratio of concern - rubin */
        local cnt_concaft = 0   
        local cnt_badbef  = 0  /* counting vars with bad ratio - rubin */
        local cnt_badaft  = 0
        local cont_cnt = 0     /* counting continuous vars */
        local cont_varbef = 0  /* counting continuous vars w/ excessive var ratio*/
        local cont_varaft = 0  
        local i 0
        fvrevar `xvars'
        foreach v in `r(varlist)' {
                local ++i 
                local xlab : word `i' of `vnames'
                if (regexm("`xlab'", ".*b[\\.].*") == 1) continue

                if (`hasfactorvars'==0 & "`label'" != "") {
                        local xlab : var label `v'
                        if ("`xlab'" == "") local xlab `v'
                }
				
				
                qui sum `v' if `treated'==1 & `touse'
                scalar `m1u' = r(mean)
                scalar `v1u' = r(Var)

                qui sum `v' if `treated'==0 & `touse'
                scalar `m0u' = r(mean)
                scalar `v0u' = r(Var)

                qui sum `v' [iw=`mweight'] if `treated'==1 & `support'==1 & `touse'
                scalar `m1m' = r(mean)
                scalar `v1m' = r(Var)

                qui sum `v' [iw=`mweight'] if `treated'==0 & `support'==1 & `touse'
                scalar `m0m' = r(mean)
                scalar `v0m' = r(Var)

                
                scalar `v_ratiobef' = .
                scalar `v_ratioaft' = .
                local starbef ""
                local staraft ""
                
                if ("`rubin'"=="" & "`scatter'"=="") {
                        capture assert `v'==0 | `v'==1 | `v'==., fast
                        if (_rc) {
                                local cont_cnt = `cont_cnt' +1
                                /* get Var ratio*/
                                scalar `v_ratiobef' = `v1u'/`v0u' 
                                if `v_ratiobef'>`Fhighu'  | `v_ratiobef'<`Flowu' {
                                        local cont_varbef = `cont_varbef' +1
                                        local starbef "*"
                                }
                                scalar `v_ratioaft' = `v1m'/`v0m' 
                                if `v_ratioaft'>`Fhighm'  | `v_ratioaft'<`Flowm' {
                                        local cont_varaft = `cont_varaft' +1
                                        local staraft "*"
                                }
                        }
                }
                


                qui replace `xvar' = "`v'" in `i'
                
                /* standardised % bias before matching */
                scalar `bias' = 100*(`m1u' - `m0u')/sqrt((`v1u' + `v0u')/2)
                qui replace `_bias0' = `bias' in `i'
                qui replace `sumbias0' = abs(`bias') in `i'
                /* standardised % bias after matching */
                scalar `biasm' = 100*(`m1m' - `m0m')/sqrt((`v1u' + `v0u')/2)
                qui replace `_biasm' = `biasm' in `i'
                qui replace `sumbias' = abs(`biasm') in `i'
                /* % reduction in absolute bias */
                scalar `absreduc' = -100*(abs(`biasm') - abs(`bias'))/abs(`bias')

                /* t-tests before matching */
                qui regress `v' `treated' if `touse' 
                scalar `tbef' = _b[`treated']/_se[`treated']
                scalar `pbef' = 2*ttail(e(df_r),abs(`tbef'))
                /* t-tests after matching */
                qui regress `v' `treated' [iw=`mweight'] if `support'==1 & `touse'
                scalar `taft' = _b[`treated']/_se[`treated']
                scalar `paft' = 2*ttail(e(df_r),abs(`taft'))

                `quietly' di as text  %-`vlength's abbrev("`xlab'",`vlength') _col(`=`c'-2') "U  {c |}" as result %7.0g `m1u' "  " %7.0g `m0u' "  " %7.1f `bias'   _s(8)           as text " {c |}"  as res %7.2f `tbef'  _s(2) as res      %05.3f `pbef' " {c |}"  as res %6.2f `v_ratiobef' "`starbef'"
                `quietly' di as text                                          _col(`=`c'-2') "M  {c |}" as result %7.0g `m1m' "  " %7.0g `m0m' "  " %7.1f `biasm' %8.1f `absreduc' as text " {c |}"  as res %7.2f `taft'  _s(2) as res  %05.3f `paft' " {c |}"  as res %6.2f `v_ratioaft' "`staraft'"
                `quietly' di as text                                          _col(`=`c'-2') "   {c |}" as text _s(31) "   {c |}" as text _s(12) "   {c |}" 
        }
        `quietly' di as text "{hline `c'}{c BT}{hline 34}{c BT}{hline 15}{c BT}{hline 10}"


        graph dot `_bias0' `_biasm', over(`xvar', sort(1) descending `nolabelx') legend(pos(5) ring(0) col(1) lab(1 "Unmatched") lab(2 "Matched")) yline(0, lcolor(gs10)) marker(1, mcolor(black)  msymbol(O)) marker(2, mcolor(black)  msymbol(X))  ytitle("Standardized % bias across covariates") `options'

}
*/

***********************************************************************************

/*
graph dot `_bias0' `_biasm', ///
over(`xvar', sort(1) descending `nolabelx') ///
legend(pos(5) ring(0) col(1) lab(1 "Unmatched") lab(2 "Matched")) ///
yline(0, lcolor(gs10)) marker(1, mcolor(black)  msymbol(O)) ///
marker(2, mcolor(black)  msymbol(X))  ytitle("Standardized % bias across covariates") `options'
    
*/



********************************************************************************
*write help file
*perhaps code up a dialog box*
di "These are the locals and variables and the values that they hold that were generated in the code so far:" 
macro list 

di "These are the names of all the locals that were generated in the code so far:"
mata : st_local("all_locals", invtokens(st_dir("local", "macro", "*")'))
display "`all_locals'"

di "`moutvar'"

sum `outcome' if `touse'
tab `treat' if `touse'

*Delete all the tempvars that were created: 
drop __0000*

*save a copy of the data where common support was applied.
save vbkwdta_commonsupportonly, replace  


restore

if `n_cat' == 3 {
if ("`bstrap'" != "") {
save vbkwtemp_jesslum, replace 

preserve 

simulate vbkw_ATE`1'`2'b = r(vbkw_ATE`1'`2'b) ///
vbkw_ATE`1'`3'b = r(vbkw_ATE`1'`3'b) ///
vbkw_ATE`2'`3'b = r(vbkw_ATE`2'`3'b) ///
vbkw_ATT`1'`2'_`1'b = r(vbkw_ATT`1'`2'_`1'b) ///
vbkw_ATT`1'`2'_`2'b = r(vbkw_ATT`1'`2'_`2'b) ///
vbkw_ATT`1'`3'_`1'b = r(vbkw_ATT`1'`3'_`1'b) ///
vbkw_ATT`1'`3'_`3'b = r(vbkw_ATT`1'`3'_`3'b) ///
vbkw_ATT`2'`3'_`2'b = r(vbkw_ATT`2'`3'_`2'b) ///
vbkw_ATT`2'`3'_`3'b = r(vbkw_ATT`2'`3'_`3'b) ///
, reps(3) seed(123456): vbkwbstrap `treat' `xvars', outcome(`outcome')

sum vbkw_ATE`1'`2'b
scalar vbkw_ATE`1'`2'bstrap_se = r(sd)
sum vbkw_ATE`1'`3'b
scalar vbkw_ATE`1'`3'bstrap_se = r(sd)
sum vbkw_ATE`2'`3'b
scalar vbkw_ATE`2'`3'bstrap_se = r(sd)

sum vbkw_ATT`1'`2'_`1'b 
scalar vbkw_ATT`1'`2'_`1'bstrap_se = r(sd)
sum vbkw_ATT`1'`2'_`2'b 
scalar vbkw_ATT`1'`2'_`2'bstrap_se = r(sd)
sum vbkw_ATT`1'`3'_`1'b 
scalar vbkw_ATT`1'`3'_`1'bstrap_se = r(sd)
sum vbkw_ATT`1'`3'_`3'b 
scalar vbkw_ATT`1'`3'_`3'bstrap_se = r(sd)
sum vbkw_ATT`2'`3'_`2'b 
scalar vbkw_ATT`2'`3'_`2'bstrap_se = r(sd)
sum vbkw_ATT`2'`3'_`3'b 
scalar vbkw_ATT`2'`3'_`3'bstrap_se = r(sd)

erase vbkwtemp_jesslum.dta
restore
}
}


if `n_cat' == 4 {
if ("`bstrap'" != "") {
save vbkwtemp_jesslum, replace 

preserve 
simulate vbkw_ATE`1'`2'b = r(vbkw_ATE`1'`2'b) ///
vbkw_ATE`1'`3'b = r(vbkw_ATE`1'`3'b) ///
vbkw_ATE`1'`4'b = r(vbkw_ATE`1'`4'b) ///
vbkw_ATE`2'`3'b = r(vbkw_ATE`2'`3'b) ///
vbkw_ATE`2'`4'b = r(vbkw_ATE`2'`4'b) ///
vbkw_ATE`3'`4'b = r(vbkw_ATE`3'`4'b) ///
vbkw_ATT`1'`2'_`1'b = r(vbkw_ATT`1'`2'_`1'b) ///
vbkw_ATT`1'`2'_`2'b = r(vbkw_ATT`1'`2'_`2'b) ///
vbkw_ATT`1'`3'_`1'b = r(vbkw_ATT`1'`3'_`1'b) ///
vbkw_ATT`1'`3'_`3'b = r(vbkw_ATT`1'`3'_`3'b) ///
vbkw_ATT`1'`4'_`1'b = r(vbkw_ATT`1'`4'_`1'b) ///
vbkw_ATT`1'`4'_`4'b = r(vbkw_ATT`1'`4'_`4'b) ///
vbkw_ATT`2'`3'_`2'b = r(vbkw_ATT`2'`3'_`2'b) ///
vbkw_ATT`2'`3'_`3'b = r(vbkw_ATT`2'`3'_`3'b) ///
vbkw_ATT`2'`4'_`2'b = r(vbkw_ATT`2'`4'_`2'b) ///
vbkw_ATT`2'`4'_`4'b = r(vbkw_ATT`2'`4'_`4'b) ///
vbkw_ATT`3'`4'_`3'b = r(vbkw_ATT`3'`4'_`3'b) ///
vbkw_ATT`3'`4'_`4'b = r(vbkw_ATT`3'`4'_`4'b) ///
, reps(3) seed(123456): vbkwbstrap `treat' `xvars', outcome(`outcome')

sum vbkw_ATE`1'`2'b
scalar vbkw_ATE`1'`2'bstrap_se = r(sd)
sum vbkw_ATE`1'`3'b
scalar vbkw_ATE`1'`3'bstrap_se = r(sd)
sum vbkw_ATE`1'`4'b
scalar vbkw_ATE`1'`4'bstrap_se = r(sd)
sum vbkw_ATE`2'`3'b
scalar vbkw_ATE`2'`3'bstrap_se = r(sd)
sum vbkw_ATE`2'`4'b
scalar vbkw_ATE`2'`4'bstrap_se = r(sd)
sum vbkw_ATE`3'`4'b
scalar vbkw_ATE`3'`4'bstrap_se = r(sd)

sum vbkw_ATT`1'`2'_`1'b 
scalar vbkw_ATT`1'`2'_`1'bstrap_se = r(sd)
sum vbkw_ATT`1'`2'_`2'b 
scalar vbkw_ATT`1'`2'_`2'bstrap_se = r(sd)
sum vbkw_ATT`1'`3'_`1'b 
scalar vbkw_ATT`1'`3'_`1'bstrap_se = r(sd)
sum vbkw_ATT`1'`3'_`3'b 
scalar vbkw_ATT`1'`3'_`3'bstrap_se = r(sd)
sum vbkw_ATT`1'`4'_`1'b 
scalar vbkw_ATT`1'`4'_`1'bstrap_se = r(sd)
sum vbkw_ATT`1'`4'_`4'b 
scalar vbkw_ATT`1'`4'_`4'bstrap_se = r(sd)
sum vbkw_ATT`2'`3'_`2'b 
scalar vbkw_ATT`2'`3'_`2'bstrap_se = r(sd)
sum vbkw_ATT`2'`3'_`3'b 
scalar vbkw_ATT`2'`3'_`3'bstrap_se = r(sd)
sum vbkw_ATT`2'`4'_`2'b 
scalar vbkw_ATT`2'`4'_`2'bstrap_se = r(sd)
sum vbkw_ATT`2'`4'_`4'b 
scalar vbkw_ATT`2'`4'_`4'bstrap_se = r(sd)
sum vbkw_ATT`3'`4'_`3'b 
scalar vbkw_ATT`3'`4'_`3'bstrap_se = r(sd)
sum vbkw_ATT`3'`4'_`4'b 
scalar vbkw_ATT`3'`4'_`4'bstrap_se = r(sd)

erase vbkwtemp_jesslum.dta
restore
}
}


if `n_cat' == 5 {
if ("`bstrap'" != "") {
local nreps = `nreps'
save vbkwtemp_jesslum, replace 

preserve 
simulate vbkw_ATE`1'`2'b = r(vbkw_ATE`1'`2'b) ///
vbkw_ATE`1'`3'b = r(vbkw_ATE`1'`3'b) ///
vbkw_ATE`1'`4'b = r(vbkw_ATE`1'`4'b) ///
vbkw_ATE`1'`5'b = r(vbkw_ATE`1'`5'b) ///
vbkw_ATE`2'`3'b = r(vbkw_ATE`2'`3'b) ///
vbkw_ATE`2'`4'b = r(vbkw_ATE`2'`4'b) ///
vbkw_ATE`2'`5'b = r(vbkw_ATE`2'`5'b) ///
vbkw_ATE`3'`4'b = r(vbkw_ATE`3'`4'b) ///
vbkw_ATE`3'`5'b = r(vbkw_ATE`3'`5'b) ///
vbkw_ATE`4'`5'b = r(vbkw_ATE`4'`5'b) ///
vbkw_ATT`1'`2'_`1'b = r(vbkw_ATT`1'`2'_`1'b) ///
vbkw_ATT`1'`2'_`2'b = r(vbkw_ATT`1'`2'_`2'b) ///
vbkw_ATT`1'`3'_`1'b = r(vbkw_ATT`1'`3'_`1'b) ///
vbkw_ATT`1'`3'_`3'b = r(vbkw_ATT`1'`3'_`3'b) ///
vbkw_ATT`1'`4'_`1'b = r(vbkw_ATT`1'`4'_`1'b) ///
vbkw_ATT`1'`4'_`4'b = r(vbkw_ATT`1'`4'_`4'b) ///
vbkw_ATT`1'`5'_`1'b = r(vbkw_ATT`1'`5'_`1'b) ///
vbkw_ATT`1'`5'_`5'b = r(vbkw_ATT`1'`5'_`5'b) ///
vbkw_ATT`2'`3'_`2'b = r(vbkw_ATT`2'`3'_`2'b) ///
vbkw_ATT`2'`3'_`3'b = r(vbkw_ATT`2'`3'_`3'b) ///
vbkw_ATT`2'`4'_`2'b = r(vbkw_ATT`2'`4'_`2'b) ///
vbkw_ATT`2'`4'_`4'b = r(vbkw_ATT`2'`4'_`4'b) ///
vbkw_ATT`2'`5'_`2'b = r(vbkw_ATT`2'`5'_`2'b) ///
vbkw_ATT`2'`5'_`5'b = r(vbkw_ATT`2'`5'_`5'b) ///
vbkw_ATT`3'`4'_`3'b = r(vbkw_ATT`3'`4'_`3'b) ///
vbkw_ATT`3'`4'_`4'b = r(vbkw_ATT`3'`4'_`4'b) ///
vbkw_ATT`3'`5'_`3'b = r(vbkw_ATT`3'`5'_`3'b) ///
vbkw_ATT`3'`5'_`5'b = r(vbkw_ATT`3'`5'_`5'b) ///
vbkw_ATT`4'`5'_`4'b = r(vbkw_ATT`4'`5'_`4'b) ///
vbkw_ATT`4'`5'_`5'b = r(vbkw_ATT`4'`5'_`5'b) ///
, reps(`nreps') seed(123456): vbkwbstrap `treat' `xvars', outcome(`outcome')

sum vbkw_ATE`1'`2'b
scalar vbkw_ATE`1'`2'bstrap_se = r(sd)
sum vbkw_ATE`1'`3'b
scalar vbkw_ATE`1'`3'bstrap_se = r(sd)
sum vbkw_ATE`1'`4'b
scalar vbkw_ATE`1'`4'bstrap_se = r(sd)
sum vbkw_ATE`1'`5'b
scalar vbkw_ATE`1'`5'bstrap_se = r(sd)
sum vbkw_ATE`2'`3'b
scalar vbkw_ATE`2'`3'bstrap_se = r(sd)
sum vbkw_ATE`2'`4'b
scalar vbkw_ATE`2'`4'bstrap_se = r(sd)
sum vbkw_ATE`2'`5'b
scalar vbkw_ATE`2'`5'bstrap_se = r(sd)
sum vbkw_ATE`3'`4'b
scalar vbkw_ATE`3'`4'bstrap_se = r(sd)
sum vbkw_ATE`3'`5'b
scalar vbkw_ATE`3'`5'bstrap_se = r(sd)
sum vbkw_ATE`4'`5'b
scalar vbkw_ATE`4'`5'bstrap_se = r(sd)

sum vbkw_ATT`1'`2'_`1'b 
scalar vbkw_ATT`1'`2'_`1'bstrap_se = r(sd)
sum vbkw_ATT`1'`2'_`2'b 
scalar vbkw_ATT`1'`2'_`2'bstrap_se = r(sd)
sum vbkw_ATT`1'`3'_`1'b 
scalar vbkw_ATT`1'`3'_`1'bstrap_se = r(sd)
sum vbkw_ATT`1'`3'_`3'b 
scalar vbkw_ATT`1'`3'_`3'bstrap_se = r(sd)
sum vbkw_ATT`1'`4'_`1'b 
scalar vbkw_ATT`1'`4'_`1'bstrap_se = r(sd)
sum vbkw_ATT`1'`4'_`4'b 
scalar vbkw_ATT`1'`4'_`4'bstrap_se = r(sd)
sum vbkw_ATT`1'`5'_`1'b 
scalar vbkw_ATT`1'`5'_`1'bstrap_se = r(sd)
sum vbkw_ATT`1'`5'_`5'b 
scalar vbkw_ATT`1'`5'_`5'bstrap_se = r(sd)
sum vbkw_ATT`2'`3'_`2'b 
scalar vbkw_ATT`2'`3'_`2'bstrap_se = r(sd)
sum vbkw_ATT`2'`3'_`3'b 
scalar vbkw_ATT`2'`3'_`3'bstrap_se = r(sd)
sum vbkw_ATT`2'`4'_`2'b 
scalar vbkw_ATT`2'`4'_`2'bstrap_se = r(sd)
sum vbkw_ATT`2'`4'_`4'b 
scalar vbkw_ATT`2'`4'_`4'bstrap_se = r(sd)
sum vbkw_ATT`2'`5'_`2'b 
scalar vbkw_ATT`2'`5'_`2'bstrap_se = r(sd)
sum vbkw_ATT`2'`5'_`5'b 
scalar vbkw_ATT`2'`5'_`5'bstrap_se = r(sd)
sum vbkw_ATT`3'`4'_`3'b 
scalar vbkw_ATT`3'`4'_`3'bstrap_se = r(sd)
sum vbkw_ATT`3'`4'_`4'b 
scalar vbkw_ATT`3'`4'_`4'bstrap_se = r(sd)
sum vbkw_ATT`3'`5'_`3'b 
scalar vbkw_ATT`3'`5'_`3'bstrap_se = r(sd)
sum vbkw_ATT`3'`5'_`5'b 
scalar vbkw_ATT`3'`5'_`5'bstrap_se = r(sd)
sum vbkw_ATT`4'`5'_`4'b 
scalar vbkw_ATT`4'`5'_`4'bstrap_se = r(sd)
sum vbkw_ATT`4'`5'_`5'b 
scalar vbkw_ATT`4'`5'_`5'bstrap_se = r(sd)



erase vbkwtemp_jesslum.dta
restore
}
}


********************************************************************************
if ("`nosave'" != "") {
erase vbkwdta_commonsupportonly.dta
}
end 







mata: mata clear
set matastrict on 
mata: 
void match(string viewvars, string kerneltype, real scalar N_ref, real scalar N_comp, real scalar bandwidth1, real scalar bandwidth2, real scalar bandwidth3, string ps1, string ps2, string ps3)
{
		real scalar Nobs, pscore_ref, pscore_ref2, pscore_ref3, i, bwidth, bwidth2, bwidth3
		real colvector pscore_tref, pscore_tref2, pscore_tref3, pscore_tcomp, pscore_tcomp2, pscore_tcomp3, dif, dif2, dif3, weight, _y
		real matrix X
		
		
		Nobs = pscore_ref = pscore_ref2 = pscore_ref3 = i = bwidth = bwidth2 = bwidth3 = .
		pscore_tref = pscore_tref2 = pscore_tref3 = pscore_tcomp = pscore_tcomp2 = pscore_tcomp3 = dif = dif2 = dif3 = weight = _y = .
		
		if (tokens(viewvars)[1] == ps1) {
		st_view(X = ., ., tokens(viewvars + " " + ps2 + " " +  ps3), 0)
		tokens(viewvars + " " + ps2 + " " +  ps3)
		bwidth = bandwidth1
		bwidth2 = bandwidth2
		bwidth3 = bandwidth3
		
		}
		else if (tokens(viewvars)[1] == ps2) {
		st_view(X = ., ., tokens(viewvars + " " + ps1 + " " +  ps3), 0)
		tokens(viewvars + " " + ps1 + " " +  ps3)
		bwidth = bandwidth2
		bwidth2 = bandwidth1
		bwidth3 = bandwidth3
		}
		else if (tokens(viewvars)[1] == ps3) {
		st_view(X = ., ., tokens(viewvars + " " +  ps1 + " " + ps2), 0)
		tokens(viewvars + " " +  ps1 + " " + ps2)
		bwidth = bandwidth3
		bwidth2 = bandwidth1
		bwidth3 = bandwidth2
		}
		
		
		
		Nobs = rows(X)
		
		tokens(viewvars)[1]
		mean(X)
		Nobs = rows(X)
		Nobs
		N_ref
		N_comp
		
		
		
		
		pscore_tref = X[(1..N_ref), 1]
		pscore_tcomp = X[((N_ref + 1)..Nobs), 1]
		

		pscore_tref2 = X[(1..N_ref), 7]
		pscore_tref3 = X[(1..N_ref), 8]
		pscore_tcomp2 = X[((N_ref + 1)..Nobs), 7]
		pscore_tcomp3 = X[((N_ref + 1)..Nobs), 8]
		
		
		
		for (i = 1; i <= N_ref; i = i + 1) {
				pscore_ref = pscore_tref[i, 1]
				dif = abs(pscore_tcomp :- pscore_ref)

				pscore_ref2 = pscore_tref2[i, 1]
				pscore_ref3 = pscore_tref3[i, 1]
				dif2 = abs(pscore_tcomp2 :- pscore_ref2) 
				dif3 = abs(pscore_tcomp3 :- pscore_ref3) 
				
				weight = J(N_comp, 1, .)
				if (kerneltype == "epan") {
				weight = (3/4) :* (1 :- (dif :/ bwidth) :^2)
				}

				dif = dif :<= bwidth
				dif2 = dif2 :<= bwidth2
				dif3 = dif3 :<= bwidth3
				dif = dif :* dif2 :* dif3
				
				weight = weight :* dif
				X[((N_ref + 1)..Nobs), 6] = X[((N_ref + 1)..Nobs), 6] :+ dif
				X[i, 6] = colsum(dif)				
							
				
		if (mean(weight) == 0) X[i, 2] = 0
		if (mean(weight) == 0) X[i, 4] = 0
		if (mean(weight) != 0) weight = weight / sum(weight)
		X[((N_ref + 1)..Nobs), 4] = X[((N_ref + 1)..Nobs), 4] :+ weight
		_y = X[((N_ref + 1)..Nobs), 5] :* weight
		_editvalue(_y, 0, .)
		if (mean(weight) == 0) X[i, 3] = .
		if (mean(weight) != 0) X[i, 3] = sum(_y)
		}
		
}

void match4(string viewvars, string kerneltype, real scalar N_ref, real scalar N_comp, real scalar bandwidth1, real scalar bandwidth2, real scalar bandwidth3, real scalar bandwidth4, string ps1, string ps2, string ps3, string ps4)
{
		real scalar Nobs, pscore_ref, pscore_ref2, pscore_ref3, pscore_ref4, i, bwidth, bwidth2, bwidth3, bwidth4
		real colvector pscore_tref, pscore_tref2, pscore_tref3, pscore_tref4, pscore_tcomp, pscore_tcomp2, pscore_tcomp3, pscore_tcomp4, dif, dif2, dif3, dif4, weight, _y
		real matrix X
		
		
		Nobs = pscore_ref = pscore_ref2 = pscore_ref3 = pscore_ref4 = i = bwidth = bwidth2 = bwidth3 = bwidth4 = .
		pscore_tref = pscore_tref2 = pscore_tref3 = pscore_tref4 = pscore_tcomp = pscore_tcomp2 = pscore_tcomp3 = pscore_tcomp4 = dif = dif2 = dif3 = dif4 = weight = _y = .

		if (tokens(viewvars)[1] == ps1) {
		st_view(X = ., ., tokens(viewvars + " " + ps2 + " " +  ps3 + " " +  ps4), 0)
		tokens(viewvars + " " + ps2 + " " +  ps3 + " " +  ps4)
		bwidth = bandwidth1
		bwidth2 = bandwidth2
		bwidth3 = bandwidth3
		bwidth4 = bandwidth4
		
		}
		else if (tokens(viewvars)[1] == ps2) {
		st_view(X = ., ., tokens(viewvars + " " + ps1 + " " +  ps3 + " " + ps4), 0)
		tokens(viewvars + " " + ps1 + " " +  ps3 + " " +  ps4)
		bwidth = bandwidth2
		bwidth2 = bandwidth1
		bwidth3 = bandwidth3
		bwidth4 = bandwidth4
		
		}
		else if (tokens(viewvars)[1] == ps3) {
		st_view(X = ., ., tokens(viewvars + " " +  ps1 + " " + ps2 + " " + ps4), 0)
		tokens(viewvars + " " +  ps1 + " " + ps2 + " " + ps4)
		bwidth = bandwidth3
		bwidth2 = bandwidth1
		bwidth3 = bandwidth2
		bwidth4 = bandwidth4
		
		}
		else if (tokens(viewvars)[1] == ps4) {
		st_view(X = ., ., tokens(viewvars + " " +  ps1 + " " + ps2 + " " + ps3), 0)
		tokens(viewvars + " " +  ps1 + " " + ps2 + " " + ps3)
		bwidth = bandwidth4
		bwidth2 = bandwidth1
		bwidth3 = bandwidth2
		bwidth4 = bandwidth3
		}
		
		
		Nobs = rows(X)
		
		tokens(viewvars)[1]
		mean(X)
		Nobs = rows(X)
		Nobs
		N_ref
		N_comp
		
		
		
		
		pscore_tref = X[(1..N_ref), 1]
		pscore_tcomp = X[((N_ref + 1)..Nobs), 1]
		

		pscore_tref2 = X[(1..N_ref), 7]
		pscore_tref3 = X[(1..N_ref), 8]
		pscore_tref4 = X[(1..N_ref), 9]
		
		pscore_tcomp2 = X[((N_ref + 1)..Nobs), 7]
		pscore_tcomp3 = X[((N_ref + 1)..Nobs), 8]
		pscore_tcomp4 = X[((N_ref + 1)..Nobs), 9]

		
		
		for (i = 1; i <= N_ref; i = i + 1) {
				pscore_ref = pscore_tref[i, 1]
				dif = abs(pscore_tcomp :- pscore_ref)

				pscore_ref2 = pscore_tref2[i, 1]
				pscore_ref3 = pscore_tref3[i, 1]
				pscore_ref4 = pscore_tref4[i, 1]
				
				dif2 = abs(pscore_tcomp2 :- pscore_ref2) 
				dif3 = abs(pscore_tcomp3 :- pscore_ref3) 
				dif4 = abs(pscore_tcomp4 :- pscore_ref4) 
				
				
				weight = J(N_comp, 1, .)
				if (kerneltype == "epan") {
				weight = (3/4) :* (1 :- (dif :/ bwidth) :^2)
				}

				dif = dif :<= bwidth
				dif2 = dif2 :<= bwidth2
				dif3 = dif3 :<= bwidth3
				dif4 = dif4 :<= bwidth4
				dif = dif :* dif2 :* dif3 :* dif4
				
				weight = weight :* dif
				X[((N_ref + 1)..Nobs), 6] = X[((N_ref + 1)..Nobs), 6] :+ dif
				X[i, 6] = colsum(dif)				
								
				
		if (mean(weight) == 0) X[i, 2] = 0
		if (mean(weight) == 0) X[i, 4] = 0
		if (mean(weight) != 0) weight = weight / sum(weight)
		X[((N_ref + 1)..Nobs), 4] = X[((N_ref + 1)..Nobs), 4] :+ weight
		_y = X[((N_ref + 1)..Nobs), 5] :* weight
		_editvalue(_y, 0, .)
		if (mean(weight) == 0) X[i, 3] = .
		if (mean(weight) != 0) X[i, 3] = sum(_y)
		}
		
}



void match5(string viewvars, string kerneltype, real scalar N_ref, real scalar N_comp, real scalar bandwidth1, real scalar bandwidth2, real scalar bandwidth3, real scalar bandwidth4, real scalar bandwidth5, string ps1, string ps2, string ps3, string ps4, string ps5)
{
		real scalar Nobs, pscore_ref, pscore_ref2, pscore_ref3, pscore_ref4, pscore_ref5,  i, bwidth, bwidth2, bwidth3, bwidth4, bwidth5
		real colvector pscore_tref, pscore_tref2, pscore_tref3, pscore_tref4, pscore_tref5, pscore_tcomp, pscore_tcomp2, pscore_tcomp3, pscore_tcomp4, pscore_tcomp5, dif, dif2, dif3, dif4, dif5, weight, _y
		real matrix X
		
		
		Nobs = pscore_ref = pscore_ref2 = pscore_ref3 = pscore_ref4 = pscore_ref5 = i = bwidth = bwidth2 = bwidth3 = bwidth4 = bwidth5 = .
		pscore_tref = pscore_tref2 = pscore_tref3 = pscore_tref4 = pscore_tref5 = pscore_tcomp = pscore_tcomp2 = pscore_tcomp3 = pscore_tcomp4 = pscore_tcomp5 = dif = dif2 = dif3 = dif4 = dif5 = weight = _y = .

		if (tokens(viewvars)[1] == ps1) {
		st_view(X = ., ., tokens(viewvars + " " + ps2 + " " +  ps3 + " " +  ps4 + " " +  ps5), 0)
		tokens(viewvars + " " + ps2 + " " +  ps3 + " " +  ps4 + " " +  ps5)
		bwidth = bandwidth1
		bwidth2 = bandwidth2
		bwidth3 = bandwidth3
		bwidth4 = bandwidth4
		bwidth5 = bandwidth5 
		
		}
		else if (tokens(viewvars)[1] == ps2) {
		st_view(X = ., ., tokens(viewvars + " " + ps1 + " " +  ps3 + " " + ps4 + " " + ps5), 0)
		tokens(viewvars + " " + ps1 + " " +  ps3 + " " +  ps4 + " " + ps5)
		bwidth = bandwidth2
		bwidth2 = bandwidth1
		bwidth3 = bandwidth3
		bwidth4 = bandwidth4
		bwidth5 = bandwidth5
		
		}
		else if (tokens(viewvars)[1] == ps3) {
		st_view(X = ., ., tokens(viewvars + " " +  ps1 + " " + ps2 + " " + ps4 + " " + ps5), 0)
		tokens(viewvars + " " +  ps1 + " " + ps2 + " " + ps4 + " " + ps5)
		bwidth = bandwidth3
		bwidth2 = bandwidth1
		bwidth3 = bandwidth2
		bwidth4 = bandwidth4
		bwidth5 = bandwidth5 
		
		}
		else if (tokens(viewvars)[1] == ps4) {
		st_view(X = ., ., tokens(viewvars + " " +  ps1 + " " + ps2 + " " + ps3 + " " + ps5), 0)
		tokens(viewvars + " " +  ps1 + " " + ps2 + " " + ps3 + " " + ps5)
		bwidth = bandwidth4
		bwidth2 = bandwidth1
		bwidth3 = bandwidth2
		bwidth4 = bandwidth3
		bwidth5 = bandwidth5
		
		}
		else if (tokens(viewvars)[1] == ps5) {
		st_view(X = ., ., tokens(viewvars + " " +  ps1 + " " + ps2 + " " + ps3 + " " + ps4), 0)
		tokens(viewvars + " " +  ps1 + " " + ps2 + " " + ps3 + " " + ps4)
		bwidth = bandwidth5
		bwidth2 = bandwidth1
		bwidth3 = bandwidth2
		bwidth4 = bandwidth3
		bwidth5 = bandwidth4
		}
		
		Nobs = rows(X)
		
		tokens(viewvars)[1]
		mean(X)
		Nobs = rows(X)
		Nobs
		N_ref
		N_comp
		
		
		
		
		pscore_tref = X[(1..N_ref), 1]
		pscore_tcomp = X[((N_ref + 1)..Nobs), 1]

		pscore_tref2 = X[(1..N_ref), 7]
		pscore_tref3 = X[(1..N_ref), 8]
		pscore_tref4 = X[(1..N_ref), 9]
		pscore_tref5 = X[(1..N_ref), 10]
		
		pscore_tcomp2 = X[((N_ref + 1)..Nobs), 7]
		pscore_tcomp3 = X[((N_ref + 1)..Nobs), 8]
		pscore_tcomp4 = X[((N_ref + 1)..Nobs), 9]
		pscore_tcomp5 = X[((N_ref + 1)..Nobs), 10]

		
		
		for (i = 1; i <= N_ref; i = i + 1) {
				pscore_ref = pscore_tref[i, 1]
				dif = abs(pscore_tcomp :- pscore_ref)

				pscore_ref2 = pscore_tref2[i, 1]
				pscore_ref3 = pscore_tref3[i, 1]
				pscore_ref4 = pscore_tref4[i, 1]
				pscore_ref5 = pscore_tref5[i, 1]
				
				dif2 = abs(pscore_tcomp2 :- pscore_ref2) 
				dif3 = abs(pscore_tcomp3 :- pscore_ref3) 
				dif4 = abs(pscore_tcomp4 :- pscore_ref4) 
				dif5 = abs(pscore_tcomp5 :- pscore_ref5) 

				weight = J(N_comp, 1, .)
				
				if (kerneltype == "epan") {			
				weight = (3/4) :* (1 :- (dif :/ bwidth) :^2)
				}
				
        else if ("`kernel'"=="normal") {
                weight = normalden(dif/bwidth)
        }
        else if ("`kernel'"=="biweight") {
                weight = (1 - (dif/bwidth)^2)^2
        }
        else if ("`kernel'"=="uniform") {
                weight = 1
        }
        else if ("`kernel'"=="tricube") {
                weight = (1-abs(dif/bwidth)^3)^3
        }
				
				
				dif = dif :<= bwidth
				dif2 = dif2 :<= bwidth2
				dif3 = dif3 :<= bwidth3
				dif4 = dif4 :<= bwidth4
				dif5 = dif5 :<= bwidth5
				dif = dif :* dif2 :* dif3 :* dif4 :* dif5
				
				weight = weight :* dif
				X[((N_ref + 1)..Nobs), 6] = X[((N_ref + 1)..Nobs), 6] :+ dif
				X[i, 6] = colsum(dif)				
	
				
		if (mean(weight) == 0) X[i, 2] = 0
		if (mean(weight) == 0) X[i, 4] = 0
		if (mean(weight) != 0) weight = weight / sum(weight)
		X[((N_ref + 1)..Nobs), 4] = X[((N_ref + 1)..Nobs), 4] :+ weight
		_y = X[((N_ref + 1)..Nobs), 5] :* weight
		_editvalue(_y, 0, .)
		if (mean(weight) == 0) X[i, 3] = .
		if (mean(weight) != 0) X[i, 3] = sum(_y)
		}
		
}
end


