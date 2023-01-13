set scheme sj
set linesize 80

capture log close
capture log using example1, text replace

* Example 1: political and economic integration between Hong Kong and mainland China (Hsiao, Ching, and Wan 2012)

******************************************************************************
* Estimating the impact of political integration of Hong Kong with mainland China in 1997q3 (Hsiao et al., 2012)

use growth, clear
xtset region time

* Show the unit number of Hong Kong and treatment period
label list
display tq(1997q3)

display tq(2003q4)

* Replicate results in Hsiao et al.(2012) with specified control units and designated post-treatment periods
rcm gdp, trunit(9) trperiod(150) ctrlunit(4 10 12 13 14 19 20 22 23 25) postperiod(150/175)

* Figure 1
graph display pred
graph export Figure1a.eps, replace
graph display eff
graph export Figure1b.eps, replace

******************************************************************************
* Estimating the impact of economic integration between Hong Kong and mainland China in 2004q1 (Hsiao et al., 2012)

* Show treatment period
display tq(2002q1)

* Replicate results in Hsiao et al.(2012) with all control units, and create a Stata frame "growth_wide" storing generated variables in wide form including counterfactual predictions, treatment effects, and results from placebo tests if implemented
rcm gdp, trunit(9) trperiod(176) nofigure frame(growth_wide)

* Change to the generated Stata frame "growth_wide"
frame change growth_wide
describe

* Change back to the default Stata frame
frame change default

* Implement placebo tests using fake treatment units with pre-treatment MSPE 5 times smaller than or equal to that of the treated unit, and fake treatment time 2002q1
display tq(2002q1)
rcm gdp, trunit(9) trperiod(176) method(lasso) criterion(cv) placebo(unit cut(5) period(168))

* Figure 2
graph display pred
graph export Figure2a.eps, replace
graph display eff
graph export Figure2b.eps, replace

* Figure 3
graph display eff_pboUnit
graph export Figure3a.eps, replace
graph display ratio_pboUnit
graph export Figure3b.eps, replace
graph display pvalTwo_pboUnit
graph export Figure3c.eps, replace
graph display pvalRight_pboUnit
graph export Figure3d.eps, replace
graph display pvalLeft_pboUnit
graph export Figure3e.eps, replace

* Figure 4
graph display pred_pboTime168
graph export Figure4a.eps, replace
graph display eff_pboTime168
graph export Figure4b.eps, replace
******************************************************************************

capture log close