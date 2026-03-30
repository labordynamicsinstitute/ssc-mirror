* xtcbc_example.do - Monte Carlo DGP from Kaddoura (2025, Section 4.1)
* =====================================================================
* DGP: Eq 4.2 from the paper
* p=6, T=5, N=200
* True breaks = [2, 3, 0, 0, 0, 1]
* =====================================================================

clear all
set more off
set seed 20250403

local N = 200
local T = 5
local p = 6

* True coefficient matrix B^0 (p x T)
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

* Fixed effects
sort id time
gen double xi = 0
forvalues i = 1/`N' {
  local xv = rnormal(0, 1)
  qui replace xi = `xv' if id == `i'
}

* Regressors
forvalues k = 1/`p' {
  gen x`k' = 0.2 * xi + rnormal(0, 1)
}

* Heteroskedastic AR(1) errors
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

* =====================================================================
* Estimation
* =====================================================================

adopath + "`c(pwd)'"
xtcbc y x1 x2 x3 x4 x5 x6, kappa(2) ngrid(50) constant(0.05) graph

* =====================================================================
* Comparison with true DGP
* =====================================================================

di _n
di in ye "{bf:Comparison: Detected vs. True Breaks}"
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
    local match " {bf:[OK]}"
  }
  else {
    local match " [MISS]"
  }
  di in gr "  x`k'" _col(20) "{c |}" _col(25) in ye `true_`k'' ///
     _col(32) in gr "{c |}" _col(37) in ye `det' in gr "`match'"
}
di in gr "  {hline 15}{c BT}{hline 11}{c BT}{hline 15}"
