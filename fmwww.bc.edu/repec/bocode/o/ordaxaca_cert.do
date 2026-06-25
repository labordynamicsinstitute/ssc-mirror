****************************************************
* ordaxaca_cert.do
* Certification tests for ordaxaca
****************************************************

clear all
set more off
set seed 98765

set obs 1000

gen group = runiform() > 0.5
gen x1 = rnormal()
gen x2 = rnormal()
gen x3 = ceil(3 * runiform())

gen latent = 0.35*x1 - 0.25*x2 + 0.30*(x3==2) + 0.55*(x3==3) ///
    + 0.30*group + rnormal()

gen y = .
replace y = 1 if latent < -0.60
replace y = 2 if latent >= -0.60 & latent < 0.60
replace y = 3 if latent >= 0.60

****************************************************
* 1. Basic ologit test
****************************************************

capture noisily ordaxaca y x1 x2 i.x3, by(group) base(0) compare(1) ///
    outcomes(1 2 3) model(ologit)

assert _rc == 0
assert "`e(cmd)'" == "ordaxaca"
assert "`e(model)'" == "ologit"
assert "`e(depvar)'" == "y"
assert "`e(by)'" == "group"
assert e(N_base) > 0
assert e(N_compare) > 0

matrix D = e(decomp)
assert rowsof(D) == 3
assert colsof(D) == 7

matrix B = e(b)
assert colsof(B) == 9

****************************************************
* 2. Replay test
****************************************************

capture noisily ordaxaca
assert _rc == 0

****************************************************
* 3. Ordered probit test
****************************************************

capture noisily ordaxaca y x1 x2 i.x3, by(group) base(0) compare(1) ///
    outcomes(1 2 3) model(oprobit)

assert _rc == 0
assert "`e(model)'" == "oprobit"

****************************************************
* 4. Single-outcome test
****************************************************

capture noisily ordaxaca y x1 x2 i.x3, by(group) base(0) compare(1) ///
    outcomes(3) model(ologit)

assert _rc == 0

matrix D1 = e(decomp)
assert rowsof(D1) == 1
assert colsof(D1) == 7

matrix B1 = e(b)
assert colsof(B1) == 3

****************************************************
* 5. Survey test
****************************************************

gen psu = ceil(_n/10)
gen strata = ceil(_n/100)
gen wt = 0.5 + runiform()

svyset psu [pweight=wt], strata(strata) singleunit(centered)

capture noisily ordaxaca y x1 x2 i.x3, by(group) base(0) compare(1) ///
    outcomes(1 2 3) model(ologit) svy

assert _rc == 0
assert "`e(svy)'" == "svy"

****************************************************
* 6. Small bootstrap test
****************************************************

capture noisily bootstrap ///
    diff_out1 = _b[diff_out1] ///
    expl_out1 = _b[expl_out1] ///
    unex_out1 = _b[unex_out1], ///
    reps(5) seed(123): ///
    ordaxaca y x1 x2 i.x3, by(group) base(0) compare(1) ///
        outcomes(1) model(ologit)

assert _rc == 0

di as result "ordaxaca certification tests passed"