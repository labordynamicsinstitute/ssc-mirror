set scheme sj
set linesize 80

capture log close
capture log using example2, text replace

* Example 2: German reunification (Abadie, Diamond, and Hainmueller 2015)

use repgermany, clear
xtset country year
xtsum gdp infrate trade industry

* Show the unit number of West Germany
label list

* Use post-lasso OLS with 5-fold cross-validation without covariates, implement placebo tests using the fake treatment units with pre-treatment MSPE 20 times smaller than or equal to that of the treated unit, and implement a placebo test with fake treatment time 1980
rcm gdp infrate trade industry, tru(17) trp(1990) me(lasso) cr(cv) fold(5) placebo(unit cut(20) period(1980))

* Figure 5
graph display pred
graph export Figure5a.eps, replace
graph display eff
graph export Figure5b.eps, replace

* Figure 6
graph display eff_pboUnit
graph export Figure6a.eps, replace
graph display ratio_pboUnit
graph export Figure6b.eps, replace
graph display pvalTwo_pboUnit
graph export Figure6c.eps, replace
graph display pvalRight_pboUnit
graph export Figure6d.eps, replace
graph display pvalLeft_pboUnit
graph export Figure6e.eps, replace

* Figure 7
graph display pred_pboTime1980
graph export Figure7a.eps, replace
graph display eff_pboTime1980
graph export Figure7b.eps, replace