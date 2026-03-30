* xtcbc_test.do - Manual test file
* Run this interactively in Stata to test the xtcbc package
* =====================================================================

clear all
set more off
set seed 54321

* =====================================================================
* SETUP: Generate panel with known break structure
* beta_1 = 1        (constant, no break)
* beta_2 = 2, t<=3  then  5, t>=4  (1 break at t=4)
* N = 100, T = 5
* =====================================================================

local N = 100
local T = 5

set obs `=`N'*`T''
gen id = ceil(_n / `T')
gen time = mod(_n - 1, `T') + 1
xtset id time

* Fixed effects
sort id time
gen double xi = 0
forvalues i = 1/`N' {
  local xv = rnormal(0, 1)
  qui replace xi = `xv' if id == `i'
}

* Regressors
gen x1 = 0.2 * xi + rnormal(0, 1)
gen x2 = 0.2 * xi + rnormal(0, 1)

* DGP: break in x2 at t=4
gen y = xi + 1*x1 + cond(time <= 3, 2, 5)*x2 + rnormal(0, 0.5)
drop xi


* =====================================================================
* TEST 1: Basic estimation
* =====================================================================

di _n
di in ye "============================================"
di in ye "  TEST 1: Basic estimation (no graphs)"
di in ye "============================================"
di _n

xtcbc y x1 x2, kappa(2) ngrid(50)


* =====================================================================
* TEST 2: With all graphs
* =====================================================================

di _n
di in ye "============================================"
di in ye "  TEST 2: With graphs"
di in ye "============================================"
di _n

xtcbc y x1 x2, kappa(2) ngrid(50) graph


* =====================================================================
* TEST 3: Check stored results
* =====================================================================

di _n
di in ye "============================================"
di in ye "  TEST 3: Stored results"
di in ye "============================================"
di _n

di "e(N)            = " e(N)
di "e(T)            = " e(T)
di "e(p)            = " e(p)
di "e(kappa)        = " e(kappa)
di "e(opt_lambda)   = " %12.8f e(opt_lambda)
di "e(total_breaks) = " e(total_breaks)
di "e(nbreaks_1)    = " e(nbreaks_1)
di "e(nbreaks_2)    = " e(nbreaks_2)

di _n
di "Break counts:"
mat list e(nbreaks), noheader

di _n
di "Post-selection detail:"
mat list e(alpha_info), noheader format(%10.4f)

di _n
di "Penalized coefficient estimates (T x p):"
mat list e(beta_hat), noheader format(%10.4f)


* =====================================================================
* TEST 4: Help file
* =====================================================================

di _n
di in ye "============================================"
di in ye "  TEST 4: Help file"
di in ye "============================================"
di _n

help xtcbc


* =====================================================================
* EXPECTED RESULTS
* =====================================================================

di _n
di in ye "============================================"
di in ye "  EXPECTED:"
di in ye "  - x2 break at t=4 detected"
di in ye "  - x2 coef ~2.0 for regime 1-3"
di in ye "  - x2 coef ~5.0 for regime 4+"
di in ye "  - x1 coef ~1.0 (stable)"
di in ye "  - 3 graphs: xtcbc_coefficients.png"
di in ye "               xtcbc_ic.png"
di in ye "               xtcbc_timeline.png"
di in ye "============================================"
