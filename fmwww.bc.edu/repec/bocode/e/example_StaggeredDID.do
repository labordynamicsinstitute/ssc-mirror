* Example of Placebo Tests for Staggered DID
* The impact of bank deregulation on income inequality (Beck et al., 2010)

* ssc install didplacebo, all replace
* ssc install csdid, all replace 

*** Use TWFE for Estimation

use bbb.dta, clear
xtset statefip wrkyr
global cov gsp_pc_growth prop_blacks prop_dropouts prop_female_headed unemploymentrate
xtreg log_gini _intra $cov i.wrkyr, fe r
estimates store did_bbb

* In-time placebo test with fake treatment time shifted back by 1-10 periods
didplacebo did_bbb, treatvar(_intra) pbotime(1(1)10) 

* In-space placebo test
didplacebo did_bbb, treatvar(_intra) pbounit rep(500) seed(1)

* The free (unrestricted) version of mixed placebo test
didplacebo did_bbb, treatvar(_intra) pbomix(2) seed(1)

* The restricted version of mixed placebo test
didplacebo did_bbb, treatvar(_intra) pbomix(3) seed(1)

*** Use CSDID for Estimation
use bbb.dta, clear
xtset statefip wrkyr
global cov gsp_pc_growth prop_blacks prop_dropouts prop_female_headed unemploymentrate
csdid log_gini $cov, ivar(statefip) time(wrkyr) gvar(branch_reform) method(dripw) wboot rseed(1) agg(simple)
estimates store csdid_bbb
global tr_eff = _b[ATT]
dis $tr_eff

** In-Time Placebo test

* Manual implementation for just one period shifted back

gen branch_reform_1 = branch_reform - 1
csdid log_gini $cov if wrkyr < branch_reform, ivar(statefip) time(wrkyr) gvar(branch_reform_1) wboot rseed(1) agg(simple) 

* Automatic implementation for 1-10 periods shifted back

global K = 10
matrix att_b = J(1, $K, 0)
matrix att_V = J($K, $K, 0)

forvalues i = 1(1)$K{
	cap drop branch_reform_new
	qui gen branch_reform_new = branch_reform - `i'
	qui csdid log_gini $cov if wrkyr < branch_reform, ivar(statefip) time(wrkyr) gvar(branch_reform_new) wboot rseed(1) agg(simple)
	matrix att_b[1, `i'] = e(b)[., "ATT"]
	matrix att_V[`i', `i'] = e(V)["ATT", "ATT"]
}
mata: st_local("names", invtokens("L":+strofreal(1..$K):+".ATT"))
matrix colnames att_b = `names'
matrix colnames att_V = `names'
matrix rownames att_V = `names'
ereturn post att_b att_V
ereturn display

coefplot,vertical msymbol(smcircle_hollow) yline(0, lp(dash)) xtitle("number of periods shifted back as fake treatment time") ytitle("placebo effect") title("In-time Placebo Test") legend(order(2 "Placebo Effect" 1 "95% Confidence Interval")) ciopts(recast(rcap)) addplot(line @b @at) coeflabels(L.ATT=1 L2.ATT=2 L3.ATT=3  L4.ATT=4 L5.ATT=5 L6.ATT=6 L7.ATT=7 L8.ATT=8 L9.ATT=9 L10.ATT=10)
** In-Space Placebo test

cap drop branch_reform_new
capture program drop InSpacePlaceboTest
prog def InSpacePlaceboTest, rclass
	preserve
	xtshuffle branch_reform, gen(branch_reform_new)
	qui csdid log_gini $cov, ivar(statefip) time(wrkyr) gvar(branch_reform_new) agg(simple)
	return scalar pbo_eff = _b[ATT]
end

simulate pbo_eff = r(pbo_eff), seed(1) reps(500): InSpacePlaceboTest
save bbb_InSpacePbo.dta, replace
use bbb_InSpacePbo.dta, clear
graph twoway (kdensity pbo_eff) (histogram pbo_eff, fcolor(gs8%50) lcolor(white) lalign(center) below), xline(0, lp(dash)) xline($tr_eff) xtitle("distribution of placebo effect") ytitle("density") title("In-space Placebo Test") legend(order(1 "Kernel density estimate" 2 "Histogram") rows(1)) name(pbounit, replace)

* Compute two-sided p-value
gen extreme_abs = (abs(pbo_eff)>=abs($tr_eff))
sum extreme_abs

* Compute left-sided p-value
gen extreme_left = (pbo_eff<=$tr_eff)
sum extreme_left

* Compute right-sided p-value
gen extreme_right = (pbo_eff>=$tr_eff)
sum extreme_right

** Mixed Placebo test: Method 2 (free version)

use bbb.dta, clear
xtset statefip wrkyr
global cov gsp_pc_growth prop_blacks prop_dropouts prop_female_headed unemploymentrate
csdid log_gini $cov, ivar(statefip) time(wrkyr) gvar(branch_reform) method(dripw) wboot rseed(1) agg(simple)
global tr_eff = _b[ATT]

capture program drop MixedPlaceboTest2
prog def MixedPlaceboTest2, rclass
	preserve
	xtrantreat _intra, method(2) gen(_intra_new)
	tofirsttreat _intra_new, gen(branch_reform_new)
	qui csdid log_gini $cov, ivar(statefip) time(wrkyr) gvar(branch_reform_new) agg(simple)
	return scalar pbo_eff = _b[ATT]
end

simulate pbo_eff = r(pbo_eff), seed(1) reps(500): MixedPlaceboTest2
save bbb_MixedPbo2.dta, replace
graph twoway (kdensity pbo_eff) (histogram pbo_eff, fcolor(gs8%50) lcolor(white) lalign(center) below), xline(0, lp(dash)) xline($tr_eff) xtitle("distribution of placebo effect") ytitle("density") title("Unrestricted Mixed Placebo Test") legend(order(1 "Kernel density estimate" 2 "Histogram") rows(1)) name(pbomix, replace)

* Compute two-sided p-value
gen extreme_abs = (abs(pbo_eff)>=abs($tr_eff))
sum extreme_abs

* Compute left-sided p-value
gen extreme_left = (pbo_eff<=$tr_eff)
sum extreme_left

* Compute right-sided p-value
gen extreme_right = (pbo_eff>=$tr_eff)
sum extreme_right

** Mixed Placebo test: Method 3 (restricted version)

use bbb.dta, clear
xtset statefip wrkyr
global cov gsp_pc_growth prop_blacks prop_dropouts prop_female_headed unemploymentrate
csdid log_gini $cov, ivar(statefip) time(wrkyr) gvar(branch_reform) method(dripw) wboot rseed(1) agg(simple)
global tr_eff = _b[ATT]

capture program drop MixedPlaceboTest3
prog def MixedPlaceboTest3, rclass
	preserve
	xtrantreat _intra, method(3) gen(_intra_new)
	tofirsttreat _intra_new, gen(branch_reform_new)
	qui csdid log_gini $cov, ivar(statefip) time(wrkyr) gvar(branch_reform_new) agg(simple)
	return scalar pbo_eff = _b[ATT]
end

simulate pbo_eff = r(pbo_eff), seed(1) reps(500): MixedPlaceboTest3
save bbb_MixedPbo3.dta, replace
graph twoway (kdensity pbo_eff) (histogram pbo_eff, fcolor(gs8%50) lcolor(white) lalign(center) below), xline(0, lp(dash)) xline($tr_eff) xtitle("distribution of placebo effect") ytitle("density") title("Restricted Mixed Placebo Test") legend(order(1 "Kernel density estimate" 2 "Histogram") rows(1)) name(pbomix, replace)

* Compute two-sided p-value
gen extreme_abs = (abs(pbo_eff)>=abs($tr_eff))
sum extreme_abs

* Compute left-sided p-value
gen extreme_left = (pbo_eff<=$tr_eff)
sum extreme_left

* Compute right-sided p-value
gen extreme_right = (pbo_eff>=$tr_eff)
sum extreme_right