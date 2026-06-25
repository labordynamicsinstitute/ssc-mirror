****************************************************
* ordaxaca_examples.do
* Example file for ordaxaca
****************************************************

clear all
set more off
set seed 12345

****************************************************
* 1. Simulate ordered outcome data
****************************************************

set obs 2000

gen group = runiform() > 0.45
label define group_lbl 0 "Base group" 1 "Comparison group"
label values group group_lbl

gen x1 = rnormal()
gen x2 = rnormal()
gen x3 = ceil(3 * runiform())

label define x3_lbl 1 "Low" 2 "Medium" 3 "High"
label values x3 x3_lbl

gen latent = 0.30*x1 - 0.20*x2 + 0.25*(x3==2) + 0.50*(x3==3) ///
    + 0.40*group + rnormal()

gen y = .
replace y = 1 if latent < -0.75
replace y = 2 if latent >= -0.75 & latent < 0.50
replace y = 3 if latent >= 0.50

label define y_lbl 1 "Low outcome" 2 "Middle outcome" 3 "High outcome"
label values y y_lbl

tab y group

****************************************************
* 2. Basic ordered logit decomposition
****************************************************

ordaxaca y x1 x2 i.x3, by(group) base(0) compare(1) ///
    outcomes(1 2 3) model(ologit)

ereturn list
matrix list e(decomp)
matrix list e(b)

****************************************************
* 3. Ordered probit decomposition
****************************************************

ordaxaca y x1 x2 i.x3, by(group) base(0) compare(1) ///
    outcomes(1 2 3) model(oprobit)

****************************************************
* 4. Bootstrap example
****************************************************

bootstrap ///
    diff_out1 = _b[diff_out1] ///
    expl_out1 = _b[expl_out1] ///
    unex_out1 = _b[unex_out1] ///
    diff_out2 = _b[diff_out2] ///
    expl_out2 = _b[expl_out2] ///
    unex_out2 = _b[unex_out2] ///
    diff_out3 = _b[diff_out3] ///
    expl_out3 = _b[expl_out3] ///
    unex_out3 = _b[unex_out3], ///
    reps(50) seed(123): ///
    ordaxaca y x1 x2 i.x3, by(group) base(0) compare(1) ///
        outcomes(1 2 3) model(ologit)

****************************************************
* 5. Survey-style example using simulated weights
****************************************************

gen psu = ceil(_n/10)
gen strata = ceil(_n/100)
gen wt = 0.5 + runiform()

svyset psu [pweight=wt], strata(strata) singleunit(centered)

ordaxaca y x1 x2 i.x3, by(group) base(0) compare(1) ///
    outcomes(1 2 3) model(ologit) svy