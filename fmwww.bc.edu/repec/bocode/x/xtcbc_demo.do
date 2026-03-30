* xtcbc_demo.do - Complete Demonstration of the xtcbc Package
* =====================================================================
* Implements: Kaddoura (2025, Journal of Econometrics)
* "Estimating Coefficient-by-Coefficient Breaks in Panel Data Models"
* Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
* =====================================================================

clear all
set more off

di _n
di in ye "{hline 78}"
di in ye _col(5) "{bf:xtcbc PACKAGE - COMPLETE DEMONSTRATION}"
di in ye _col(5) "Coefficient-by-Coefficient Breaks in Panel Data"
di in ye _col(5) "Kaddoura (2025, Journal of Econometrics)"
di in ye "{hline 78}"
di _n


* =====================================================================
* SECTION 1: Simple Example with Known Single Break
* =====================================================================

di _n
di in ye "{hline 78}"
di in ye _col(5) "SECTION 1: Simple Example - Single Known Break"
di in ye "{hline 78}"
di _n
di in gr "  DGP: y_it = xi_i + beta_1*x1 + beta_2(t)*x2 + u_it"
di in gr "  beta_1 = 1        (constant - no break)"
di in gr "  beta_2 = 2, t<=3  (regime 1)"
di in gr "  beta_2 = 5, t>=4  (regime 2 - break at t=4)"
di in gr "  N = 100,  T = 5,  p = 2"
di _n

set seed 54321
local N = 100
local T = 5

set obs `=`N'*`T''
gen id = ceil(_n / `T')
gen time = mod(_n - 1, `T') + 1
xtset id time

* Generate fixed effects
sort id time
gen double xi = 0
forvalues i = 1/`N' {
  local xv = rnormal(0, 1)
  qui replace xi = `xv' if id == `i'
}

* Regressors correlated with FE
gen x1 = 0.2 * xi + rnormal(0, 1)
gen x2 = 0.2 * xi + rnormal(0, 1)

* DGP with structural break in x2
gen y = xi + 1 * x1 + cond(time <= 3, 2, 5) * x2 + rnormal(0, 0.5)
drop xi

* Run xtcbc with graphs
xtcbc y x1 x2, kappa(2) ngrid(50) graph

* Display stored results
di _n
di in ye "{bf:--- Stored Results ---}"
di in gr "  Break counts:"
mat list e(nbreaks), noheader
di _n
di in gr "  Optimal lambda  = " %12.8f e(opt_lambda)
di in gr "  Total breaks    = " %4.0f e(total_breaks)
di _n
di in gr "  Post-selection detail:"
mat list e(alpha_info), noheader format(%10.4f)

di _n
di in ye "  EXPECTED: x2 break at t=4; coefficient ~2.0 before, ~5.0 after"
di _n


* =====================================================================
* SECTION 2: Monte Carlo DGP from Paper (Section 4.1, Eq 4.2)
* =====================================================================

di _n
di in ye "{hline 78}"
di in ye _col(5) "SECTION 2: Monte Carlo DGP from Section 4.1"
di in ye "{hline 78}"
di _n
di in gr "  DGP: y_it = xi_i + sum_{k=1}^{6} B^0_{k,t} * x_{k,it} + u_it"
di _n
di in gr "  True B^0 matrix (p=6, T=5):"
di in gr "    beta_1: [  0,    0,   0.9,  0.2,  0.2 ] -> 2 breaks (t=3,4)"
di in gr "    beta_2: [1.25, 1.25,-1.25, 0.15, 2.25] -> 3 breaks (t=3,4,5)"
di in gr "    beta_3: [  1,    1,    1,    1,    1  ] -> 0 breaks"
di in gr "    beta_4: [  1,    1,    1,    1,    1  ] -> 0 breaks"
di in gr "    beta_5: [  1,    1,    1,    1,    1  ] -> 0 breaks"
di in gr "    beta_6: [-0.5, -0.5,  0.5,  0.5,  0.5] -> 1 break  (t=3)"
di _n
di in gr "  True breaks: [2, 3, 0, 0, 0, 1]"
di in gr "  N = 200, T = 5"
di _n

clear
set seed 20250403

local N = 200
local T = 5
local p = 6

* True coefficient matrix B^0: each row = coefficient, each col = time
matrix B0 = (   0,    0,   0.9,  0.2,  0.2  \ ///
              1.25, 1.25, -1.25, 0.15, 2.25  \ ///
              1,    1,    1,    1,    1      \ ///
              1,    1,    1,    1,    1      \ ///
              1,    1,    1,    1,    1      \ ///
             -0.5, -0.5,  0.5,  0.5,  0.5  )

set obs `=`N'*`T''
gen id = ceil(_n / `T')
gen time = mod(_n - 1, `T') + 1
xtset id time

* Generate fixed effects
sort id time
gen double xi = 0
forvalues i = 1/`N' {
  local xv = rnormal(0, 1)
  qui replace xi = `xv' if id == `i'
}

* Regressors: x_{k,it} = 0.2*xi_i + e_{k,it}
forvalues k = 1/`p' {
  gen x`k' = 0.2 * xi + rnormal(0, 1)
}

* Error with serial and heteroskedastic structure
gen sigma_i = runiform(0.5, 1)
gen nu = rnormal(0, sigma_i)
gen u = 0
sort id time
by id: replace u = nu if _n == 1
by id: replace u = 0.5 * u[_n-1] + nu if _n > 1

* Dependent variable
gen y = xi
forvalues k = 1/`p' {
  forvalues t = 1/`T' {
    local bkt = B0[`k', `t']
    qui replace y = y + `bkt' * x`k' if time == `t'
  }
}
replace y = y + u
drop xi sigma_i nu u

* Run xtcbc with all options
xtcbc y x1 x2 x3 x4 x5 x6, kappa(2) ngrid(50) constant(0.05) graph

* Compare detected vs. true
di _n
di in ye "{bf:--- Comparison: Detected vs. True Breaks ---}"
di _n
di in gr "  Variable" _col(20) "{c |}" _col(23) "True" _col(32) "{c |}" _col(35) "Detected"
di in gr "  {hline 15}{c +}{hline 11}{c +}{hline 15}"

local true_1 = 2
local true_2 = 3
local true_3 = 0
local true_4 = 0
local true_5 = 0
local true_6 = 1

forvalues k = 1/`p' {
  local det = e(nbreaks_`k')
  local match ""
  if `det' == `true_`k'' {
    local match " [OK]"
  }
  else {
    local match " [MISS]"
  }
  di in gr "  x`k'" _col(20) "{c |}" _col(25) in ye `true_`k'' ///
     _col(32) in gr "{c |}" _col(37) in ye `det' in gr "`match'"
}
di in gr "  {hline 15}{c BT}{hline 11}{c BT}{hline 15}"


* =====================================================================
* SECTION 3: Varying Penalty Parameters
* =====================================================================

di _n
di in ye "{hline 78}"
di in ye _col(5) "SECTION 3: Sensitivity to Penalty Constant c"
di in ye "{hline 78}"
di _n
di in gr "  Re-running the Section 2 DGP with different c values"
di in gr "  to illustrate that results are robust to c in [0.01, 0.10]"
di _n

foreach cval in 0.01 0.05 0.10 {
  di in ye "  --- constant(`cval') ---"
  qui xtcbc y x1 x2 x3 x4 x5 x6, kappa(2) ngrid(50) constant(`cval')

  mat nb = e(nbreaks)
  di in gr "  Breaks: x1=" nb[1,1] " x2=" nb[1,2] ///
     " x3=" nb[1,3] " x4=" nb[1,4] ///
     " x5=" nb[1,5] " x6=" nb[1,6] ///
     "  (lambda=" %8.6f e(opt_lambda) ")"
}
di _n


* =====================================================================
* SECTION 4: Using Cross-Section Demeaning
* =====================================================================

di _n
di in ye "{hline 78}"
di in ye _col(5) "SECTION 4: Cross-Section Demeaning Option"
di in ye "{hline 78}"
di _n
di in gr "  Useful when model has interactive/common factor effects"
di in gr "  csdemean removes cross-sectional means at each time period"
di _n

qui xtcbc y x1 x2 x3 x4 x5 x6, kappa(2) ngrid(50) csdemean
mat nb = e(nbreaks)
di in gr "  With csdemean:    Breaks: x1=" nb[1,1] " x2=" nb[1,2] ///
   " x3=" nb[1,3] " x4=" nb[1,4] ///
   " x5=" nb[1,5] " x6=" nb[1,6]

qui xtcbc y x1 x2 x3 x4 x5 x6, kappa(2) ngrid(50)
mat nb = e(nbreaks)
di in gr "  Without csdemean: Breaks: x1=" nb[1,1] " x2=" nb[1,2] ///
   " x3=" nb[1,3] " x4=" nb[1,4] ///
   " x5=" nb[1,5] " x6=" nb[1,6]
di _n


* =====================================================================
* SECTION 5: DGP with No Breaks (Size Check)
* =====================================================================

di _n
di in ye "{hline 78}"
di in ye _col(5) "SECTION 5: No-Break DGP (Size Check)"
di in ye "{hline 78}"
di _n
di in gr "  DGP: y_it = xi_i + 1*x1 + 2*x2 + 3*x3 + u_it (no breaks)"
di in gr "  The estimator should detect 0 breaks for all coefficients."
di _n

clear
set seed 99999

local N = 150
local T = 5

set obs `=`N'*`T''
gen id = ceil(_n / `T')
gen time = mod(_n - 1, `T') + 1
xtset id time

sort id time
gen double xi = 0
forvalues i = 1/`N' {
  local xv = rnormal(0, 1)
  qui replace xi = `xv' if id == `i'
}

gen x1 = 0.2 * xi + rnormal(0, 1)
gen x2 = 0.2 * xi + rnormal(0, 1)
gen x3 = 0.2 * xi + rnormal(0, 1)
gen y = xi + 1 * x1 + 2 * x2 + 3 * x3 + rnormal(0, 0.5)
drop xi

xtcbc y x1 x2 x3, kappa(2) ngrid(50) graph

di _n
di in ye "  EXPECTED: 0 breaks for all coefficients"
mat list e(nbreaks), noheader
di _n


* =====================================================================
* SECTION 6: DGP with Multiple Breaks in Multiple Coefficients
* =====================================================================

di _n
di in ye "{hline 78}"
di in ye _col(5) "SECTION 6: Multiple Breaks in Multiple Coefficients"
di in ye "{hline 78}"
di _n
di in gr "  DGP: N=200, T=8, p=3"
di in gr "  beta_1: 1 for t<=3,  3 for t=4-6,  -1 for t>=7  (2 breaks: t=4,7)"
di in gr "  beta_2: 2 for t<=5,  -2 for t>=6                 (1 break:  t=6)"
di in gr "  beta_3: 0.5 always                                (0 breaks)"
di _n

clear
set seed 77777

local N = 200
local T = 8

set obs `=`N'*`T''
gen id = ceil(_n / `T')
gen time = mod(_n - 1, `T') + 1
xtset id time

sort id time
gen double xi = 0
forvalues i = 1/`N' {
  local xv = rnormal(0, 1)
  qui replace xi = `xv' if id == `i'
}

gen x1 = 0.2 * xi + rnormal(0, 1)
gen x2 = 0.2 * xi + rnormal(0, 1)
gen x3 = 0.2 * xi + rnormal(0, 1)

* True coefficients with multiple breaks
gen beta1 = cond(time <= 3, 1, cond(time <= 6, 3, -1))
gen beta2 = cond(time <= 5, 2, -2)
gen beta3 = 0.5

gen y = xi + beta1*x1 + beta2*x2 + beta3*x3 + rnormal(0, 0.5)
drop xi beta1 beta2 beta3

xtcbc y x1 x2 x3, kappa(2) ngrid(80) graph

di _n
di in ye "  EXPECTED: x1 -> 2 breaks (t=4,7); x2 -> 1 break (t=6); x3 -> 0 breaks"
mat list e(nbreaks), noheader
di _n
di in ye "{bf:--- Full Post-Selection Results ---}"
mat list e(alpha_info), noheader format(%10.4f)
di _n


* =====================================================================
* SECTION 7: Summary of Stored Results
* =====================================================================

di _n
di in ye "{hline 78}"
di in ye _col(5) "SECTION 7: Complete Stored Results (from Section 6)"
di in ye "{hline 78}"
di _n

di in gr "  e(N)            = " e(N)
di in gr "  e(T)            = " e(T)
di in gr "  e(p)            = " e(p)
di in gr "  e(kappa)        = " e(kappa)
di in gr "  e(ngrid)        = " e(ngrid)
di in gr "  e(c_const)      = " e(c_const)
di in gr "  e(opt_lambda)   = " %12.8f e(opt_lambda)
di in gr "  e(total_breaks) = " e(total_breaks)
di in gr "  e(nbreaks_1)    = " e(nbreaks_1)
di in gr "  e(nbreaks_2)    = " e(nbreaks_2)
di in gr "  e(nbreaks_3)    = " e(nbreaks_3)
di _n
di in gr "  Break counts vector:"
mat list e(nbreaks), noheader
di _n
di in gr "  Break dates matrix:"
mat list e(break_dates), noheader
di _n
di in gr "  Penalized coefficient estimates (T x p):"
mat list e(beta_hat), noheader format(%10.4f)
di _n
di in gr "  IC values (first 10):"
mat IC = e(ic_values)
forvalues q = 1/10 {
  di in gr "    lambda grid[`q'] -> IC = " %12.6f IC[`q',1]
}

di _n
di in ye "{hline 78}"
di in ye _col(5) "DEMO COMPLETE"
di in ye _col(5) "Graph files saved: xtcbc_coefficients.png"
di in ye _col(5) "                   xtcbc_ic.png"
di in ye _col(5) "                   xtcbc_timeline.png"
di in ye "{hline 78}"
di _n

log close
