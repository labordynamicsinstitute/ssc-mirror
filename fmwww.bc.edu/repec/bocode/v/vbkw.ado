capture program drop vbkw
program define vbkw, rclass

		quietly{
vbkw_main `0'
di "`0'"


*. display ustrword("`0'", -5) + " " + ustrword("`0'", -4) + ustrword("`0'", -3) + ustrword("`0'", -2) + ustrword("`0'", -1)
/*
		tokenize "`0'"
		gettoken treat xvars : varlist
		di "`treat'"
		di "`xvars'"
*/

local 0 = subinstr("`0'",(ustrword("`0'", -5) + " " + ustrword("`0'", -4) + ustrword("`0'", -3) + ustrword("`0'", -2) + ustrword("`0'", -1)),"",.)
local xvars = subinstr("`0'","`1'","",.)
di wordcount("`0'")
*10
di word("`0'",1)
*TREAT
local treat = word("`0'",1)

preserve 
use vbkwdta_commonsupportonly, clear 
*tab treat

tab `1'
local n_cat = r(r)
di `n_cat'
}
if `n_cat' == 3 {
	quietly levelsof `1', local(levels)
	tokenize `levels'
	capture confirm scalar vbkw_ATE`1'`2'bstrap_se
	scalar errormsg = _rc
	if _rc != 111 {
	/*
	scalar list vbkw_ATE`1'`2'bstrap_se
	scalar list vbkw_ATE`1'`3'bstrap_se
	scalar list vbkw_ATE`2'`3'bstrap_se
	scalar list vbkw_ATT`1'`2'_`1'bstrap_se
scalar list vbkw_ATT`1'`2'_`2'bstrap_se
scalar list vbkw_ATT`1'`3'_`1'bstrap_se
scalar list vbkw_ATT`1'`3'_`3'bstrap_se
scalar list vbkw_ATT`2'`3'_`2'bstrap_se
scalar list vbkw_ATT`2'`3'_`3'bstrap_se

	*/
	
	}
}

if `n_cat' == 4 {
	quietly levelsof `1', local(levels)
	tokenize `levels'
	capture confirm scalar vbkw_ATE`1'`2'bstrap_se
	scalar errormsg = _rc
	if _rc != 111 {
	/*
	scalar list vbkw_ATE`1'`2'bstrap_se
	scalar list vbkw_ATE`1'`3'bstrap_se
	scalar list vbkw_ATE`1'`4'bstrap_se
	scalar list vbkw_ATE`2'`3'bstrap_se
	scalar list vbkw_ATE`2'`4'bstrap_se
	scalar list vbkw_ATE`3'`4'bstrap_se
scalar list vbkw_ATT`1'`2'_`1'bstrap_se
scalar list vbkw_ATT`1'`2'_`2'bstrap_se
scalar list vbkw_ATT`1'`3'_`1'bstrap_se
scalar list vbkw_ATT`1'`3'_`3'bstrap_se
scalar list vbkw_ATT`1'`4'_`1'bstrap_se
scalar list vbkw_ATT`1'`4'_`4'bstrap_se
scalar list vbkw_ATT`2'`3'_`2'bstrap_se
scalar list vbkw_ATT`2'`3'_`3'bstrap_se
scalar list vbkw_ATT`2'`4'_`2'bstrap_se
scalar list vbkw_ATT`2'`4'_`4'bstrap_se
scalar list vbkw_ATT`3'`4'_`3'bstrap_se
scalar list vbkw_ATT`3'`4'_`4'bstrap_se
	
	*/
	
	}
}


if `n_cat' == 5 {
	quietly levelsof `1', local(levels)
	tokenize `levels'
	capture confirm scalar vbkw_ATE`1'`2'bstrap_se
	scalar errormsg = _rc
	if _rc != 111 {
	/*
	scalar list vbkw_ATE`1'`3'bstrap_se
	scalar list vbkw_ATE`1'`4'bstrap_se
	scalar list vbkw_ATE`1'`5'bstrap_se
	scalar list vbkw_ATE`2'`3'bstrap_se
	scalar list vbkw_ATE`2'`4'bstrap_se
	scalar list vbkw_ATE`2'`5'bstrap_se
	scalar list vbkw_ATE`3'`4'bstrap_se
	scalar list vbkw_ATE`3'`5'bstrap_se
	scalar list vbkw_ATE`4'`5'bstrap_se
scalar list vbkw_ATT`1'`2'_`1'bstrap_se
scalar list vbkw_ATT`1'`2'_`2'bstrap_se
scalar list vbkw_ATT`1'`3'_`1'bstrap_se
scalar list vbkw_ATT`1'`3'_`3'bstrap_se
scalar list vbkw_ATT`1'`4'_`1'bstrap_se
scalar list vbkw_ATT`1'`4'_`4'bstrap_se
scalar list vbkw_ATT`1'`5'_`1'bstrap_se
scalar list vbkw_ATT`1'`5'_`5'bstrap_se
scalar list vbkw_ATT`2'`3'_`2'bstrap_se
scalar list vbkw_ATT`2'`3'_`3'bstrap_se
scalar list vbkw_ATT`2'`4'_`2'bstrap_se
scalar list vbkw_ATT`2'`4'_`4'bstrap_se
scalar list vbkw_ATT`2'`5'_`2'bstrap_se
scalar list vbkw_ATT`2'`5'_`5'bstrap_se
scalar list vbkw_ATT`3'`4'_`3'bstrap_se
scalar list vbkw_ATT`3'`4'_`4'bstrap_se
scalar list vbkw_ATT`3'`5'_`3'bstrap_se
scalar list vbkw_ATT`3'`5'_`5'bstrap_se
scalar list vbkw_ATT`4'`5'_`4'bstrap_se
scalar list vbkw_ATT`4'`5'_`5'bstrap_se

	*/
	
	}

*sum vbkw* 
*sum vbkw_outcome 


}
*ATEs:
eststo clear 
estimates clear 

	capture confirm scalar vbkw_ATE`1'`2'bstrap_se
	scalar errormsg = _rc
	if _rc != 111 {
	
if `n_cat' == 3 {
quietly eststo: reg vbkw_outcome ib`2'.`treat' if inlist(`treat', `1', `2') & (ATTsupport`1'`2'_`1' == 1 | ATUsupport`1'`2'_`2' == 1) [pw= ATEweight`1'`2']
quietly estadd scalar Bootstrapped_SE = vbkw_ATE`1'`2'bstrap_se
quietly eststo: reg vbkw_outcome ib`3'.`treat' if inlist(`treat', `1', `3') & (ATTsupport`1'`3'_`1' == 1 | ATUsupport`1'`3'_`3' == 1) [pw= ATEweight`1'`3']
quietly estadd scalar Bootstrapped_SE = vbkw_ATE`1'`3'bstrap_se
quietly eststo: reg vbkw_outcome ib`3'.`treat' if inlist(`treat', `2', `3') & (ATTsupport`2'`3'_`2' == 1 | ATUsupport`2'`3'_`3' == 1) [pw= ATEweight`2'`3']
quietly estadd scalar Bootstrapped_SE = vbkw_ATE`2'`3'bstrap_se

esttab, label title("Average Treatment Effects") nonumbers mtitles("`1' vs. `2'" "`1' vs. `3'" "`2' vs. `3'") se stats(Bootstrapped_SE N, labels("Bootstrapped SE" "Observations"))

quietly eststo clear 
quietly estimates clear 

quietly eststo: reg vbkw_outcome ib`2'.`treat' if inlist(`treat' , `1', `2') & (ATTsupport`1'`2'_`1' == 1) [pw= ATTweight`1'`2'_`1']
quietly estadd scalar Bootstrapped_SE = vbkw_ATT`1'`2'_`1'bstrap_se
quietly eststo: reg vbkw_outcome ib`2'.`treat' if inlist(`treat' , `1', `2') & (ATUsupport`1'`2'_`2' == 1) [pw= ATUweight`1'`2'_`2']
quietly estadd scalar Bootstrapped_SE = vbkw_ATT`1'`2'_`2'bstrap_se
quietly eststo: reg vbkw_outcome ib`3'.`treat' if inlist(`treat' , `1', `3') & (ATTsupport`1'`3'_`1' == 1) [pw= ATTweight`1'`3'_`1']
quietly estadd scalar Bootstrapped_SE = vbkw_ATT`1'`3'_`1'bstrap_se
quietly eststo: reg vbkw_outcome ib`3'.`treat' if inlist(`treat' , `1', `3') & (ATUsupport`1'`3'_`3' == 1) [pw= ATUweight`1'`3'_`3']
quietly estadd scalar Bootstrapped_SE = vbkw_ATT`1'`3'_`3'bstrap_se
quietly eststo: reg vbkw_outcome ib`3'.`treat' if inlist(`treat' , `2', `3') & (ATTsupport`2'`3'_`2' == 1) [pw= ATTweight`2'`3'_`2']
quietly estadd scalar Bootstrapped_SE = vbkw_ATT`2'`3'_`2'bstrap_se
quietly eststo: reg vbkw_outcome ib`3'.`treat' if inlist(`treat' , `2', `3') & (ATUsupport`2'`3'_`3' == 1) [pw= ATUweight`2'`3'_`3']
quietly estadd scalar Bootstrapped_SE = vbkw_ATT`2'`3'_`3'bstrap_se
esttab, label title("Average Treatment Effects on the Treated") nonumbers modelwidth(20) ///
mtitles("`1' vs. `2' | T = `1'" "`1' vs. `2' | T = `2'" "`1' vs. `3' | T = `1'" "`1' vs. `3' | T = `3'" "`2' vs. `3' | T = `2'" "`2' vs. `3' | T = `3'" ) se ///
stats(Bootstrapped_SE N, labels("Bootstrapped SE" "Observations"))
}


if `n_cat' == 4 {
quietly eststo: reg vbkw_outcome ib`2'.`treat' if inlist(`treat', `1', `2') & (ATTsupport`1'`2'_`1' == 1 | ATUsupport`1'`2'_`2' == 1) [pw= ATEweight`1'`2']
quietly estadd scalar Bootstrapped_SE = vbkw_ATE`1'`2'bstrap_se
quietly eststo: reg vbkw_outcome ib`3'.`treat' if inlist(`treat', `1', `3') & (ATTsupport`1'`3'_`1' == 1 | ATUsupport`1'`3'_`3' == 1) [pw= ATEweight`1'`3']
quietly estadd scalar Bootstrapped_SE = vbkw_ATE`1'`3'bstrap_se
quietly eststo: reg vbkw_outcome ib`4'.`treat' if inlist(`treat', `1', `4') & (ATTsupport`1'`4'_`1' == 1 | ATUsupport`1'`4'_`4' == 1) [pw= ATEweight`1'`4']
quietly estadd scalar Bootstrapped_SE = vbkw_ATE`1'`4'bstrap_se
quietly eststo: reg vbkw_outcome ib`3'.`treat' if inlist(`treat', `2', `3') & (ATTsupport`2'`3'_`2' == 1 | ATUsupport`2'`3'_`3' == 1) [pw= ATEweight`2'`3']
quietly estadd scalar Bootstrapped_SE = vbkw_ATE`2'`3'bstrap_se
quietly eststo: reg vbkw_outcome ib`4'.`treat' if inlist(`treat', `2', `4') & (ATTsupport`2'`4'_`2' == 1 | ATUsupport`2'`4'_`4' == 1) [pw= ATEweight`2'`4']
quietly estadd scalar Bootstrapped_SE = vbkw_ATE`2'`4'bstrap_se
quietly eststo: reg vbkw_outcome ib`4'.`treat' if inlist(`treat', `3', `4') & (ATTsupport`3'`4'_`3' == 1 | ATUsupport`3'`4'_`4' == 1) [pw= ATEweight`3'`4']
quietly estadd scalar Bootstrapped_SE = vbkw_ATE`3'`4'bstrap_se
esttab, label title("Average Treatment Effects") nonumbers mtitles("`1' vs. `2'" "`1' vs. `3'" "`1' vs. `4'" "`2' vs. `3'" "`2' vs. `4'" "`3' vs. `4'") se ///
stats(Bootstrapped_SE N, labels("Bootstrapped SE" "Observations"))


quietly eststo clear 
quietly estimates clear 

quietly eststo: reg vbkw_outcome ib`2'.`treat' if inlist(`treat' , `1', `2') & (ATTsupport`1'`2'_`1' == 1) [pw= ATTweight`1'`2'_`1']
quietly estadd scalar Bootstrapped_SE = vbkw_ATT`1'`2'_`1'bstrap_se
quietly eststo: reg vbkw_outcome ib`2'.`treat' if inlist(`treat' , `1', `2') & (ATUsupport`1'`2'_`2' == 1) [pw= ATUweight`1'`2'_`2']
quietly estadd scalar Bootstrapped_SE = vbkw_ATT`1'`2'_`2'bstrap_se
quietly eststo: reg vbkw_outcome ib`3'.`treat' if inlist(`treat' , `1', `3') & (ATTsupport`1'`3'_`1' == 1) [pw= ATTweight`1'`3'_`1']
quietly estadd scalar Bootstrapped_SE = vbkw_ATT`1'`3'_`1'bstrap_se
quietly eststo: reg vbkw_outcome ib`3'.`treat' if inlist(`treat' , `1', `3') & (ATUsupport`1'`3'_`3' == 1) [pw= ATUweight`1'`3'_`3']
quietly estadd scalar Bootstrapped_SE = vbkw_ATT`1'`3'_`3'bstrap_se
quietly eststo: reg vbkw_outcome ib`4'.`treat' if inlist(`treat' , `1', `4') & (ATTsupport`1'`4'_`1' == 1) [pw= ATTweight`1'`4'_`1']
quietly estadd scalar Bootstrapped_SE = vbkw_ATT`1'`4'_`1'bstrap_se
quietly eststo: reg vbkw_outcome ib`4'.`treat' if inlist(`treat' , `1', `4') & (ATUsupport`1'`4'_`4' == 1) [pw= ATUweight`1'`4'_`4']
quietly estadd scalar Bootstrapped_SE = vbkw_ATT`1'`4'_`4'bstrap_se
quietly eststo: reg vbkw_outcome ib`3'.`treat' if inlist(`treat' , `2', `3') & (ATTsupport`2'`3'_`2' == 1) [pw= ATTweight`2'`3'_`2']
quietly estadd scalar Bootstrapped_SE = vbkw_ATT`2'`3'_`2'bstrap_se
quietly eststo: reg vbkw_outcome ib`3'.`treat' if inlist(`treat' , `2', `3') & (ATUsupport`2'`3'_`3' == 1) [pw= ATUweight`2'`3'_`3']
quietly estadd scalar Bootstrapped_SE = vbkw_ATT`2'`3'_`3'bstrap_se
quietly eststo: reg vbkw_outcome ib`4'.`treat' if inlist(`treat' , `2', `4') & (ATTsupport`2'`4'_`2' == 1) [pw= ATTweight`2'`4'_`2']
quietly estadd scalar Bootstrapped_SE = vbkw_ATT`2'`4'_`2'bstrap_se
quietly eststo: reg vbkw_outcome ib`4'.`treat' if inlist(`treat' , `2', `4') & (ATUsupport`2'`4'_`4' == 1) [pw= ATUweight`2'`4'_`4']
quietly estadd scalar Bootstrapped_SE = vbkw_ATT`2'`4'_`4'bstrap_se
esttab, label title("Average Treatment Effects on the Treated") nonumbers modelwidth(20) ///
mtitles("`1' vs. `2' | T = `1'" "`1' vs. `2' | T = `2'" "`1' vs. `3' | T = `1'" "`1' vs. `3' | T = `3'" "`1' vs. `4' | T = `1'" "`1' vs. `4' | T = `4'" "`2' vs. `3' | T = `2'" "`2' vs. `3' | T = `3'" "`2' vs. `4' | T = `2'" "`2' vs. `4' | T = `4'") se ///
stats(Bootstrapped_SE N, labels("Bootstrapped SE" "Observations"))
}

if `n_cat' == 5 {
quietly eststo: reg vbkw_outcome ib`2'.`treat' if inlist(`treat', `1', `2') & (ATTsupport`1'`2'_`1' == 1 | ATUsupport`1'`2'_`2' == 1) [pw= ATEweight`1'`2']
quietly estadd scalar Bootstrapped_SE = vbkw_ATE`1'`2'bstrap_se
quietly eststo: reg vbkw_outcome ib`3'.`treat' if inlist(`treat', `1', `3') & (ATTsupport`1'`3'_`1' == 1 | ATUsupport`1'`3'_`3' == 1) [pw= ATEweight`1'`3']
quietly estadd scalar Bootstrapped_SE = vbkw_ATE`1'`3'bstrap_se
quietly eststo: reg vbkw_outcome ib`4'.`treat' if inlist(`treat', `1', `4') & (ATTsupport`1'`4'_`1' == 1 | ATUsupport`1'`4'_`4' == 1) [pw= ATEweight`1'`4']
quietly estadd scalar Bootstrapped_SE = vbkw_ATE`1'`4'bstrap_se
quietly eststo: reg vbkw_outcome ib`5'.`treat' if inlist(`treat', `1', `5') & (ATTsupport`1'`5'_`1' == 1 | ATUsupport`1'`5'_`5' == 1) [pw= ATEweight`1'`5']
quietly estadd scalar Bootstrapped_SE = vbkw_ATE`1'`4'bstrap_se
quietly eststo: reg vbkw_outcome ib`3'.`treat' if inlist(`treat', `2', `3') & (ATTsupport`2'`3'_`2' == 1 | ATUsupport`2'`3'_`3' == 1) [pw= ATEweight`2'`3']
quietly estadd scalar Bootstrapped_SE = vbkw_ATE`2'`3'bstrap_se
quietly eststo: reg vbkw_outcome ib`4'.`treat' if inlist(`treat', `2', `4') & (ATTsupport`2'`4'_`2' == 1 | ATUsupport`2'`4'_`4' == 1) [pw= ATEweight`2'`4']
quietly estadd scalar Bootstrapped_SE = vbkw_ATE`2'`3'bstrap_se
quietly eststo: reg vbkw_outcome ib`5'.`treat' if inlist(`treat', `2', `5') & (ATTsupport`2'`5'_`2' == 1 | ATUsupport`2'`5'_`5' == 1) [pw= ATEweight`2'`5']
quietly estadd scalar Bootstrapped_SE = vbkw_ATE`2'`3'bstrap_se
quietly eststo: reg vbkw_outcome ib`4'.`treat' if inlist(`treat', `3', `4') & (ATTsupport`3'`4'_`3' == 1 | ATUsupport`3'`4'_`4' == 1) [pw= ATEweight`3'`4']
quietly estadd scalar Bootstrapped_SE = vbkw_ATE`3'`4'bstrap_se
quietly eststo: reg vbkw_outcome ib`5'.`treat' if inlist(`treat', `3', `5') & (ATTsupport`3'`5'_`3' == 1 | ATUsupport`3'`5'_`5' == 1) [pw= ATEweight`3'`5']
quietly estadd scalar Bootstrapped_SE = vbkw_ATE`3'`5'bstrap_se
quietly eststo: reg vbkw_outcome ib`5'.`treat' if inlist(`treat', `4', `5') & (ATTsupport`4'`5'_`4' == 1 | ATUsupport`4'`5'_`5' == 1) [pw= ATEweight`4'`5']
quietly estadd scalar Bootstrapped_SE = vbkw_ATE`4'`5'bstrap_se
esttab, label title("Average Treatment Effects") mtitles("`1' vs. `2'" "`1' vs. `3'" "`1' vs. `4'" "`1' vs. `5'" "`2' vs. `3'" "`2' vs. `4'" "`2' vs. `5'" "`3' vs. `4'" "`3' vs. `5'" "`4' vs. `5'") se ///
stats(Bootstrapped_SE N, labels("Bootstrapped SE" "Observations"))

quietly eststo clear 
quietly estimates clear 

quietly eststo: reg vbkw_outcome ib`2'.`treat' if inlist(`treat' , `1', `2') & (ATTsupport`1'`2'_`1' == 1) [pw= ATTweight`1'`2'_`1']
quietly estadd scalar Bootstrapped_SE = vbkw_ATT`1'`2'_`1'bstrap_se
quietly eststo: reg vbkw_outcome ib`2'.`treat' if inlist(`treat' , `1', `2') & (ATUsupport`1'`2'_`2' == 1) [pw= ATUweight`1'`2'_`2']
quietly estadd scalar Bootstrapped_SE = vbkw_ATT`1'`2'_`2'bstrap_se
quietly eststo: reg vbkw_outcome ib`3'.`treat' if inlist(`treat' , `1', `3') & (ATTsupport`1'`3'_`1' == 1) [pw= ATTweight`1'`3'_`1']
quietly estadd scalar Bootstrapped_SE = vbkw_ATT`1'`3'_`1'bstrap_se
quietly eststo: reg vbkw_outcome ib`3'.`treat' if inlist(`treat' , `1', `3') & (ATUsupport`1'`3'_`3' == 1) [pw= ATUweight`1'`3'_`3']
quietly estadd scalar Bootstrapped_SE = vbkw_ATT`1'`3'_`3'bstrap_se
quietly eststo: reg vbkw_outcome ib`4'.`treat' if inlist(`treat' , `1', `4') & (ATTsupport`1'`4'_`1' == 1) [pw= ATTweight`1'`4'_`1']
quietly estadd scalar Bootstrapped_SE = vbkw_ATT`1'`4'_`1'bstrap_se
quietly eststo: reg vbkw_outcome ib`4'.`treat' if inlist(`treat' , `1', `4') & (ATUsupport`1'`4'_`4' == 1) [pw= ATUweight`1'`4'_`4']
quietly estadd scalar Bootstrapped_SE = vbkw_ATT`1'`4'_`4'bstrap_se
quietly eststo: reg vbkw_outcome ib`5'.`treat' if inlist(`treat' , `1', `5') & (ATTsupport`1'`5'_`1' == 1) [pw= ATTweight`1'`5'_`1']
quietly estadd scalar Bootstrapped_SE = vbkw_ATT`1'`5'_`1'bstrap_se
quietly eststo: reg vbkw_outcome ib`5'.`treat' if inlist(`treat' , `1', `5') & (ATUsupport`1'`5'_`5' == 1) [pw= ATUweight`1'`5'_`5']
quietly estadd scalar Bootstrapped_SE = vbkw_ATT`1'`5'_`5'bstrap_se
quietly eststo: reg vbkw_outcome ib`3'.`treat' if inlist(`treat' , `2', `3') & (ATTsupport`2'`3'_`2' == 1) [pw= ATTweight`2'`3'_`2']
quietly estadd scalar Bootstrapped_SE = vbkw_ATT`2'`3'_`2'bstrap_se
quietly eststo: reg vbkw_outcome ib`3'.`treat' if inlist(`treat' , `2', `3') & (ATUsupport`2'`3'_`3' == 1) [pw= ATUweight`2'`3'_`3']
quietly estadd scalar Bootstrapped_SE = vbkw_ATT`2'`3'_`3'bstrap_se
quietly eststo: reg vbkw_outcome ib`4'.`treat' if inlist(`treat' , `2', `4') & (ATTsupport`2'`4'_`2' == 1) [pw= ATTweight`2'`4'_`2']
quietly estadd scalar Bootstrapped_SE = vbkw_ATT`2'`4'_`2'bstrap_se
quietly eststo: reg vbkw_outcome ib`4'.`treat' if inlist(`treat' , `2', `4') & (ATUsupport`2'`4'_`4' == 1) [pw= ATUweight`2'`4'_`4']
quietly estadd scalar Bootstrapped_SE = vbkw_ATT`2'`4'_`4'bstrap_se
quietly eststo: reg vbkw_outcome ib`5'.`treat' if inlist(`treat' , `2', `5') & (ATTsupport`2'`5'_`2' == 1) [pw= ATTweight`2'`5'_`2']
quietly estadd scalar Bootstrapped_SE = vbkw_ATT`2'`5'_`2'bstrap_se
quietly eststo: reg vbkw_outcome ib`5'.`treat' if inlist(`treat' , `2', `5') & (ATUsupport`2'`5'_`5' == 1) [pw= ATUweight`2'`5'_`5']
quietly estadd scalar Bootstrapped_SE = vbkw_ATT`2'`5'_`5'bstrap_se
quietly eststo: reg vbkw_outcome ib`4'.`treat' if inlist(`treat' , `3', `4') & (ATTsupport`3'`4'_`3' == 1) [pw= ATTweight`3'`4'_`3']
quietly estadd scalar Bootstrapped_SE = vbkw_ATT`3'`4'_`3'bstrap_se
quietly eststo: reg vbkw_outcome ib`4'.`treat' if inlist(`treat' , `3', `4') & (ATUsupport`3'`4'_`4' == 1) [pw= ATUweight`3'`4'_`4']
quietly estadd scalar Bootstrapped_SE = vbkw_ATT`3'`4'_`4'bstrap_se
quietly eststo: reg vbkw_outcome ib`5'.`treat' if inlist(`treat' , `3', `5') & (ATTsupport`3'`5'_`3' == 1) [pw= ATTweight`3'`5'_`3']
quietly estadd scalar Bootstrapped_SE = vbkw_ATT`3'`5'_`3'bstrap_se
quietly eststo: reg vbkw_outcome ib`5'.`treat' if inlist(`treat' , `3', `5') & (ATUsupport`3'`5'_`5' == 1) [pw= ATUweight`3'`5'_`5']
quietly estadd scalar Bootstrapped_SE = vbkw_ATT`3'`5'_`5'bstrap_se
quietly eststo: reg vbkw_outcome ib`5'.`treat' if inlist(`treat' , `4', `5') & (ATTsupport`4'`5'_`4' == 1) [pw= ATTweight`4'`5'_`4']
quietly estadd scalar Bootstrapped_SE = vbkw_ATT`4'`5'_`4'bstrap_se
quietly eststo: reg vbkw_outcome ib`5'.`treat' if inlist(`treat' , `4', `5') & (ATUsupport`4'`5'_`5' == 1) [pw= ATUweight`4'`5'_`5']
quietly estadd scalar Bootstrapped_SE = vbkw_ATT`4'`5'_`5'bstrap_se


esttab, label title("Average Treatment Effects on the Treated") nonumbers modelwidth(20) ///
mtitles("`1' vs. `2' | T = `1'" "`1' vs. `2' | T = `2'" "`1' vs. `3' | T = `1'" "`1' vs. `3' | T = `3'" "`1' vs. `4' | T = `1'" "`1' vs. `4' | T = `4'" "`1' vs. `5' | T = `1'" "`1' vs. `5' | T = `5'" "`2' vs. `3' | T = `2'" "`2' vs. `3' | T = `3'" "`2' vs. `4' | T = `2'" "`2' vs. `4' | T = `4'" "`2' vs. `5' | T = `2'" "`2' vs. `5' | T = `5'" "`3' vs. `4' | T = `3'" "`3' vs. `4' | T = `4'" "`3' vs. `5' | T = `3'" "`3' vs. `5' | T = `5'" "`4' vs. `5' | T = `4'" "`4' vs. `5' | T = `5'") se ///
stats(Bootstrapped_SE N, labels("Bootstrapped SE" "Observations"))

}
}

else {
if `n_cat' == 3 {
quietly eststo: reg vbkw_outcome ib`2'.`treat' if inlist(`treat', `1', `2') & (ATTsupport`1'`2'_`1' == 1 | ATUsupport`1'`2'_`2' == 1) [pw= ATEweight`1'`2']
quietly eststo: reg vbkw_outcome ib`3'.`treat' if inlist(`treat', `1', `3') & (ATTsupport`1'`3'_`1' == 1 | ATUsupport`1'`3'_`3' == 1) [pw= ATEweight`1'`3']
quietly eststo: reg vbkw_outcome ib`3'.`treat' if inlist(`treat', `2', `3') & (ATTsupport`2'`3'_`2' == 1 | ATUsupport`2'`3'_`3' == 1) [pw= ATEweight`2'`3']
esttab, label title("Average Treatment Effects") nonumbers mtitles("`1' vs. `2'" "`1' vs. `3'" "`2' vs. `3'") se

quietly eststo clear 
quietly estimates clear 

quietly eststo: reg vbkw_outcome ib`2'.`treat' if inlist(`treat' , `1', `2') & (ATTsupport`1'`2'_`1' == 1) [pw= ATTweight`1'`2'_`1']
quietly eststo: reg vbkw_outcome ib`2'.`treat' if inlist(`treat' , `1', `2') & (ATUsupport`1'`2'_`2' == 1) [pw= ATUweight`1'`2'_`2']
quietly eststo: reg vbkw_outcome ib`3'.`treat' if inlist(`treat' , `1', `3') & (ATTsupport`1'`3'_`1' == 1) [pw= ATTweight`1'`3'_`1']
quietly eststo: reg vbkw_outcome ib`3'.`treat' if inlist(`treat' , `1', `3') & (ATUsupport`1'`3'_`3' == 1) [pw= ATUweight`1'`3'_`3']
quietly eststo: reg vbkw_outcome ib`3'.`treat' if inlist(`treat' , `2', `3') & (ATTsupport`2'`3'_`2' == 1) [pw= ATTweight`2'`3'_`2']
quietly eststo: reg vbkw_outcome ib`3'.`treat' if inlist(`treat' , `2', `3') & (ATUsupport`2'`3'_`3' == 1) [pw= ATUweight`2'`3'_`3']
esttab, label title("Average Treatment Effects on the Treated") nonumbers modelwidth(20) ///
mtitles("`1' vs. `2' | T = `1'" "`1' vs. `2' | T = `2'" "`1' vs. `3' | T = `1'" "`1' vs. `3' | T = `3'" "`2' vs. `3' | T = `2'" "`2' vs. `3' | T = `3'" ) se
}


if `n_cat' == 4 {
quietly eststo: reg vbkw_outcome ib`2'.`treat' if inlist(`treat', `1', `2') & (ATTsupport`1'`2'_`1' == 1 | ATUsupport`1'`2'_`2' == 1) [pw= ATEweight`1'`2']
quietly eststo: reg vbkw_outcome ib`3'.`treat' if inlist(`treat', `1', `3') & (ATTsupport`1'`3'_`1' == 1 | ATUsupport`1'`3'_`3' == 1) [pw= ATEweight`1'`3']
quietly eststo: reg vbkw_outcome ib`4'.`treat' if inlist(`treat', `1', `4') & (ATTsupport`1'`4'_`1' == 1 | ATUsupport`1'`4'_`4' == 1) [pw= ATEweight`1'`4']
quietly eststo: reg vbkw_outcome ib`3'.`treat' if inlist(`treat', `2', `3') & (ATTsupport`2'`3'_`2' == 1 | ATUsupport`2'`3'_`3' == 1) [pw= ATEweight`2'`3']
quietly eststo: reg vbkw_outcome ib`4'.`treat' if inlist(`treat', `2', `4') & (ATTsupport`2'`4'_`2' == 1 | ATUsupport`2'`4'_`4' == 1) [pw= ATEweight`2'`4']
quietly eststo: reg vbkw_outcome ib`4'.`treat' if inlist(`treat', `3', `4') & (ATTsupport`3'`4'_`3' == 1 | ATUsupport`3'`4'_`4' == 1) [pw= ATEweight`3'`4']
esttab, label title("Average Treatment Effects") nonumbers mtitles("`1' vs. `2'" "`1' vs. `3'" "`1' vs. `4'" "`2' vs. `3'" "`2' vs. `4'" "`3' vs. `4'") se 


quietly eststo clear 
quietly estimates clear 

quietly eststo: reg vbkw_outcome ib`2'.`treat' if inlist(`treat' , `1', `2') & (ATTsupport`1'`2'_`1' == 1) [pw= ATTweight`1'`2'_`1']
quietly eststo: reg vbkw_outcome ib`2'.`treat' if inlist(`treat' , `1', `2') & (ATUsupport`1'`2'_`2' == 1) [pw= ATUweight`1'`2'_`2']
quietly eststo: reg vbkw_outcome ib`3'.`treat' if inlist(`treat' , `1', `3') & (ATTsupport`1'`3'_`1' == 1) [pw= ATTweight`1'`3'_`1']
quietly eststo: reg vbkw_outcome ib`3'.`treat' if inlist(`treat' , `1', `3') & (ATUsupport`1'`3'_`3' == 1) [pw= ATUweight`1'`3'_`3']
quietly eststo: reg vbkw_outcome ib`4'.`treat' if inlist(`treat' , `1', `4') & (ATTsupport`1'`4'_`1' == 1) [pw= ATTweight`1'`4'_`1']
quietly eststo: reg vbkw_outcome ib`4'.`treat' if inlist(`treat' , `1', `4') & (ATUsupport`1'`4'_`4' == 1) [pw= ATUweight`1'`4'_`4']
quietly eststo: reg vbkw_outcome ib`3'.`treat' if inlist(`treat' , `2', `3') & (ATTsupport`2'`3'_`2' == 1) [pw= ATTweight`2'`3'_`2']
quietly eststo: reg vbkw_outcome ib`3'.`treat' if inlist(`treat' , `2', `3') & (ATUsupport`2'`3'_`3' == 1) [pw= ATUweight`2'`3'_`3']
quietly eststo: reg vbkw_outcome ib`4'.`treat' if inlist(`treat' , `2', `4') & (ATTsupport`2'`4'_`2' == 1) [pw= ATTweight`2'`4'_`2']
quietly eststo: reg vbkw_outcome ib`4'.`treat' if inlist(`treat' , `2', `4') & (ATUsupport`2'`4'_`4' == 1) [pw= ATUweight`2'`4'_`4']
esttab, label title("Average Treatment Effects on the Treated") nonumbers modelwidth(20) ///
mtitles("`1' vs. `2' | T = `1'" "`1' vs. `2' | T = `2'" "`1' vs. `3' | T = `1'" "`1' vs. `3' | T = `3'" "`1' vs. `4' | T = `1'" "`1' vs. `4' | T = `4'" "`2' vs. `3' | T = `2'" "`2' vs. `3' | T = `3'" "`2' vs. `4' | T = `2'" "`2' vs. `4' | T = `4'") se
}

if `n_cat' == 5 {
quietly eststo: reg vbkw_outcome ib`2'.`treat' if inlist(`treat', `1', `2') & (ATTsupport`1'`2'_`1' == 1 | ATUsupport`1'`2'_`2' == 1) [pw= ATEweight`1'`2']
quietly eststo: reg vbkw_outcome ib`3'.`treat' if inlist(`treat', `1', `3') & (ATTsupport`1'`3'_`1' == 1 | ATUsupport`1'`3'_`3' == 1) [pw= ATEweight`1'`3']
quietly eststo: reg vbkw_outcome ib`4'.`treat' if inlist(`treat', `1', `4') & (ATTsupport`1'`4'_`1' == 1 | ATUsupport`1'`4'_`4' == 1) [pw= ATEweight`1'`4']
quietly eststo: reg vbkw_outcome ib`5'.`treat' if inlist(`treat', `1', `5') & (ATTsupport`1'`5'_`1' == 1 | ATUsupport`1'`5'_`5' == 1) [pw= ATEweight`1'`5']
quietly eststo: reg vbkw_outcome ib`3'.`treat' if inlist(`treat', `2', `3') & (ATTsupport`2'`3'_`2' == 1 | ATUsupport`2'`3'_`3' == 1) [pw= ATEweight`2'`3']
quietly eststo: reg vbkw_outcome ib`4'.`treat' if inlist(`treat', `2', `4') & (ATTsupport`2'`4'_`2' == 1 | ATUsupport`2'`4'_`4' == 1) [pw= ATEweight`2'`4']
quietly eststo: reg vbkw_outcome ib`5'.`treat' if inlist(`treat', `2', `5') & (ATTsupport`2'`5'_`2' == 1 | ATUsupport`2'`5'_`5' == 1) [pw= ATEweight`2'`5']
quietly eststo: reg vbkw_outcome ib`4'.`treat' if inlist(`treat', `3', `4') & (ATTsupport`3'`4'_`3' == 1 | ATUsupport`3'`4'_`4' == 1) [pw= ATEweight`3'`4']
quietly eststo: reg vbkw_outcome ib`5'.`treat' if inlist(`treat', `3', `5') & (ATTsupport`3'`5'_`3' == 1 | ATUsupport`3'`5'_`5' == 1) [pw= ATEweight`3'`5']
quietly eststo: reg vbkw_outcome ib`5'.`treat' if inlist(`treat', `4', `5') & (ATTsupport`4'`5'_`4' == 1 | ATUsupport`4'`5'_`5' == 1) [pw= ATEweight`4'`5']
esttab, label title("Average Treatment Effects") mtitles("`1' vs. `2'" "`1' vs. `3'" "`1' vs. `4'" "`1' vs. `5'" "`2' vs. `3'" "`2' vs. `4'" "`2' vs. `5'" "`3' vs. `4'" "`3' vs. `5'" "`4' vs. `5'") se

quietly eststo clear 
quietly estimates clear 

quietly eststo: reg vbkw_outcome ib`2'.`treat' if inlist(`treat' , `1', `2') & (ATTsupport`1'`2'_`1' == 1) [pw= ATTweight`1'`2'_`1']
quietly eststo: reg vbkw_outcome ib`2'.`treat' if inlist(`treat' , `1', `2') & (ATUsupport`1'`2'_`2' == 1) [pw= ATUweight`1'`2'_`2']
quietly eststo: reg vbkw_outcome ib`3'.`treat' if inlist(`treat' , `1', `3') & (ATTsupport`1'`3'_`1' == 1) [pw= ATTweight`1'`3'_`1']
quietly eststo: reg vbkw_outcome ib`3'.`treat' if inlist(`treat' , `1', `3') & (ATUsupport`1'`3'_`3' == 1) [pw= ATUweight`1'`3'_`3']
quietly eststo: reg vbkw_outcome ib`4'.`treat' if inlist(`treat' , `1', `4') & (ATTsupport`1'`4'_`1' == 1) [pw= ATTweight`1'`4'_`1']
quietly eststo: reg vbkw_outcome ib`4'.`treat' if inlist(`treat' , `1', `4') & (ATUsupport`1'`4'_`4' == 1) [pw= ATUweight`1'`4'_`4']
quietly eststo: reg vbkw_outcome ib`5'.`treat' if inlist(`treat' , `1', `5') & (ATTsupport`1'`5'_`1' == 1) [pw= ATTweight`1'`5'_`1']
quietly eststo: reg vbkw_outcome ib`5'.`treat' if inlist(`treat' , `1', `5') & (ATUsupport`1'`5'_`5' == 1) [pw= ATUweight`1'`5'_`5']
quietly eststo: reg vbkw_outcome ib`3'.`treat' if inlist(`treat' , `2', `3') & (ATTsupport`2'`3'_`2' == 1) [pw= ATTweight`2'`3'_`2']
quietly eststo: reg vbkw_outcome ib`3'.`treat' if inlist(`treat' , `2', `3') & (ATUsupport`2'`3'_`3' == 1) [pw= ATUweight`2'`3'_`3']
quietly eststo: reg vbkw_outcome ib`4'.`treat' if inlist(`treat' , `2', `4') & (ATTsupport`2'`4'_`2' == 1) [pw= ATTweight`2'`4'_`2']
quietly eststo: reg vbkw_outcome ib`4'.`treat' if inlist(`treat' , `2', `4') & (ATUsupport`2'`4'_`4' == 1) [pw= ATUweight`2'`4'_`4']
quietly eststo: reg vbkw_outcome ib`5'.`treat' if inlist(`treat' , `2', `5') & (ATTsupport`2'`5'_`2' == 1) [pw= ATTweight`2'`5'_`2']
quietly eststo: reg vbkw_outcome ib`5'.`treat' if inlist(`treat' , `2', `5') & (ATUsupport`2'`5'_`5' == 1) [pw= ATUweight`2'`5'_`5']
quietly eststo: reg vbkw_outcome ib`4'.`treat' if inlist(`treat' , `3', `4') & (ATTsupport`3'`4'_`3' == 1) [pw= ATTweight`3'`4'_`3']
quietly eststo: reg vbkw_outcome ib`4'.`treat' if inlist(`treat' , `3', `4') & (ATUsupport`3'`4'_`4' == 1) [pw= ATUweight`3'`4'_`4']
quietly eststo: reg vbkw_outcome ib`5'.`treat' if inlist(`treat' , `3', `5') & (ATTsupport`3'`5'_`3' == 1) [pw= ATTweight`3'`5'_`3']
quietly eststo: reg vbkw_outcome ib`5'.`treat' if inlist(`treat' , `3', `5') & (ATUsupport`3'`5'_`5' == 1) [pw= ATUweight`3'`5'_`5']
quietly eststo: reg vbkw_outcome ib`5'.`treat' if inlist(`treat' , `4', `5') & (ATTsupport`4'`5'_`4' == 1) [pw= ATTweight`4'`5'_`4']
quietly eststo: reg vbkw_outcome ib`5'.`treat' if inlist(`treat' , `4', `5') & (ATUsupport`4'`5'_`5' == 1) [pw= ATUweight`4'`5'_`5']


esttab, label title("Average Treatment Effects on the Treated") nonumbers modelwidth(20) ///
mtitles("`1' vs. `2' | T = `1'" "`1' vs. `2' | T = `2'" "`1' vs. `3' | T = `1'" "`1' vs. `3' | T = `3'" "`1' vs. `4' | T = `1'" "`1' vs. `4' | T = `4'" "`1' vs. `5' | T = `1'" "`1' vs. `5' | T = `5'" "`2' vs. `3' | T = `2'" "`2' vs. `3' | T = `3'" "`2' vs. `4' | T = `2'" "`2' vs. `4' | T = `4'" "`2' vs. `5' | T = `2'" "`2' vs. `5' | T = `5'" "`3' vs. `4' | T = `3'" "`3' vs. `4' | T = `4'" "`3' vs. `5' | T = `3'" "`3' vs. `5' | T = `5'" "`4' vs. `5' | T = `4'" "`4' vs. `5' | T = `5'") se

}

}



/*
quietly{
*Placeholders for producing this graph only for 1 vs. 2:
				tempvar treated mweight support
				g `treated'= 1 if `treat' == `1' 
				replace `treated' = 0 if `treat' == `2'
				g `mweight' = ATTweight`1'`2'_`1'
				g `support' = ATTsupport`1'`2'_`1'
*********************************************************
			
				
		
        tempvar sumbias sumbias0 _bias0 _biasm xvar meanbiasbef medbiasbef meanbiasaft medbiasaft _vratio_bef _vratio_aft
        tempname Flowu Fhighu Flowm Fhighm

        qui count if `treated'==1 
		
        scalar `Flowu'  = invF(r(N)-1, r(N)-1, 0.025)
        scalar `Fhighu' = invF(r(N)-1, r(N)-1, 0.975)

        qui count if `treated'==1 & `support'==1
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
		
}
        `quietly' di
		`quietly' di as text "{hline `c'}{hline 34}{hline 15}{hline 13}"
		`quietly' di as text "Covariate Balance across treatment groups `1' and `2'"
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
	 			
				
                qui sum `v' if `treated'==1
                scalar `m1u' = r(mean)
                scalar `v1u' = r(Var)

                qui sum `v' if `treated'==0
                scalar `m0u' = r(mean)
                scalar `v0u' = r(Var)

                qui sum `v' [iw=`mweight'] if `treated'==1 & `support'==1
                scalar `m1m' = r(mean)
                scalar `v1m' = r(Var)

                qui sum `v' [iw=`mweight'] if `treated'==0 & `support'==1
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
                qui regress `v' `treated'
                scalar `tbef' = _b[`treated']/_se[`treated']
                scalar `pbef' = 2*ttail(e(df_r),abs(`tbef'))
                /* t-tests after matching */
                qui regress `v' `treated' [iw=`mweight'] if `support'==1
                scalar `taft' = _b[`treated']/_se[`treated']
                scalar `paft' = 2*ttail(e(df_r),abs(`taft'))

                `quietly' di as text  %-`vlength's abbrev("`xlab'",`vlength') _col(`=`c'-2') "U  {c |}" as result %7.0g `m1u' "  " %7.0g `m0u' "  " %7.1f `bias'   _s(8)           as text " {c |}"  as res %7.2f `tbef'  _s(2) as res      %05.3f `pbef' " {c |}"  as res %6.2f `v_ratiobef' "`starbef'"
                `quietly' di as text                                          _col(`=`c'-2') "M  {c |}" as result %7.0g `m1m' "  " %7.0g `m0m' "  " %7.1f `biasm' %8.1f `absreduc' as text " {c |}"  as res %7.2f `taft'  _s(2) as res  %05.3f `paft' " {c |}"  as res %6.2f `v_ratioaft' "`staraft'"
                `quietly' di as text                                          _col(`=`c'-2') "   {c |}" as text _s(31) "   {c |}" as text _s(12) "   {c |}" 
        }

		
        `quietly' di as text "{hline `c'}{c BT}{hline 34}{c BT}{hline 15}{c BT}{hline 10}"

        graph dot `_bias0' `_biasm', title("Covariate balance, ATT `1' vs. `2' | T = `1'") over(`xvar', sort(1) descending `nolabelx') legend(pos(5) ring(0) col(1) lab(1 "Unmatched") lab(2 "Matched")) yline(0, lcolor(gs10)) marker(1, mcolor(black)  msymbol(O)) marker(2, mcolor(black)  msymbol(X))  ytitle("Standardized % bias across covariates") `options'

*/

********************************************************************************
*Use the above to create the output tables (robust SEs and complex SEs as well and the balance graphs)
*Reminder: code the different kernel functions (viewsource psmatch2.ado)
*Reminder: code up capturing bootstrapped SEs of the ATTs (so far, I just coded for the ATEs)
********************************************************************************

restore
end 
