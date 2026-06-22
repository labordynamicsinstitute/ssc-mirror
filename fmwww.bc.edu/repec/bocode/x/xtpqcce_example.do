*! xtpqcce_example.do  v1.0.0  20jun2026  Dr Merwan Roudane
*! Self-test + demonstration of xtpqcce on simulated panels that match the
*! data-generating processes of the two source papers.
*  Runtime note: the csqr+bc path refits many smoothed quantile regressions
*  (J bandwidths x split-panel jackknife) so it is the slowest step.

clear all
set more off
set seed 20260620

*===============================================================*
* 1) STATIC factor model  ->  CCEMG-CSQR  (Zhang & Su 2026)     *
*    y_it = a_i + b1_i*x1 + b2_i*x2 + lam_i*f_t + e_it          *
*    x_j have a common-factor structure so CCE is required.     *
*===============================================================*
local N = 40
local T = 40
set obs `=`N'*`T''
gen long id = ceil(_n/`T')
bysort id: gen int t = _n
xtset id t

* one common factor, AR(0.7)
gen double f = .
by id: replace f = rnormal() if _n==1
by id: replace f = 0.7*f[_n-1] + rnormal() if _n>1
* (use the same f path across units: rebuild a single time series)
sort t id
by t: replace f = f[1]
sort id t

* heterogeneous loadings / slopes
gen double lam_i = .
gen double g1_i  = .
gen double g2_i  = .
gen double b1_i  = .
gen double b2_i  = .
gen double a_i   = .
by id: replace lam_i = rnormal(0.5,1)   if _n==1
by id: replace g1_i  = rnormal(0.5,1)   if _n==1
by id: replace g2_i  = rnormal(0.5,1)   if _n==1
by id: replace b1_i  = rnormal(1, 0.3)  if _n==1   // true MG b1 = 1
by id: replace b2_i  = rnormal(-0.5,0.3) if _n==1  // true MG b2 = -0.5
by id: replace a_i   = rnormal()        if _n==1
foreach v in lam_i g1_i g2_i b1_i b2_i a_i {
	by id: replace `v' = `v'[1]
}

gen double x1 = 0.5 + g1_i*f + rnormal()
gen double x2 = 0.5 + g2_i*f + rnormal()
gen double y  = a_i + b1_i*x1 + b2_i*x2 + lam_i*f + rnormal()

di as txt _n "{hline 70}"
di as txt "TEST 1a: CCEMG-CSQR, no bias correction"
di as txt "{hline 70}"
xtpqcce y x1 x2, csqr quantiles(0.25 0.5 0.75)

di as txt _n "{hline 70}"
di as txt "TEST 1b: CCEMG-CSQR, two-step bias correction (bc) + graph"
di as txt "  (true MG: b1 = 1, b2 = -0.5 at every quantile)"
di as txt "{hline 70}"
xtpqcce y x1 x2, csqr quantiles(0.25 0.5 0.75) bc graph ///
	graphexport("xtpqcce_csqr_demo.png")
ereturn list
matrix list e(bc_mg)

*===============================================================*
* 2) DYNAMIC factor model  ->  QCCEMG  (Harding-Lamarche-      *
*    Pesaran 2018):                                            *
*    y_it = a_i + lam_i*y_(i,t-1) + b1_i*x1 + b2_i*x2          *
*           + gy_i*f_t + e_it                                  *
*===============================================================*
clear            // NB: clear (not clear all) so the CSQR graph stays in memory
set seed 7777
local N = 40
local T = 45
set obs `=`N'*`T''
gen long id = ceil(_n/`T')
bysort id: gen int t = _n
xtset id t

gen double f = .
by id: replace f = rnormal() if _n==1
by id: replace f = 0.7*f[_n-1] + rnormal() if _n>1
sort t id
by t: replace f = f[1]
sort id t

gen double lr_i = .   // AR coefficient, U(0.2,0.5) -> MG ~ 0.35
gen double gy_i = .
gen double g1_i = .
gen double g2_i = .
gen double b1_i = .
gen double b2_i = .
gen double a_i  = .
by id: replace lr_i = 0.2 + 0.3*runiform() if _n==1
by id: replace gy_i = rnormal(0.5,1) if _n==1
by id: replace g1_i = rnormal(0.5,1) if _n==1
by id: replace g2_i = rnormal(0.5,1) if _n==1
by id: replace b1_i = rnormal(1,0.2)  if _n==1
by id: replace b2_i = rnormal(-0.5,0.2) if _n==1
by id: replace a_i  = rnormal() if _n==1
foreach v in lr_i gy_i g1_i g2_i b1_i b2_i a_i {
	by id: replace `v' = `v'[1]
}

gen double x1 = 0.5 + g1_i*f + rnormal()
gen double x2 = 0.5 + g2_i*f + rnormal()

* build the AR(1) series recursively
gen double y = .
by id: replace y = a_i + b1_i*x1 + b2_i*x2 + gy_i*f + rnormal() if _n==1
by id: replace y = a_i + lr_i*y[_n-1] + b1_i*x1 + b2_i*x2 + gy_i*f + rnormal() ///
	if _n>1

di as txt _n "{hline 70}"
di as txt "TEST 2: QCCEMG (dynamic), short-run + speed + long-run + graph"
di as txt "  (true MG: lambda ~ 0.35, b1 = 1, b2 = -0.5; LR b1 ~ 1.54)"
di as txt "{hline 70}"
xtpqcce y x1 x2, qmg quantiles(0.25 0.5 0.75) lags(1) lrun graph ///
	graphexport("xtpqcce_qmg_demo.png")
ereturn list
matrix list e(mg)
matrix list e(lr_mg)

di as txt _n "{hline 70}"
di as txt "TEST 3: replay + a postestimation test"
di as txt "{hline 70}"
xtpqcce
* test equality of the median b1 across nothing (illustration of e(b) names)
test [q50]x1 = [q25]x1

di as txt _n "{hline 70}"
di as txt "TEST 4: show BOTH model figures together in one window"
di as txt "{hline 70}"
* both graphs are still in memory (we used 'clear', not 'clear all'),
* so they can be shown side by side in a single combined figure
graph dir
graph combine xtpqcce_csqr_y_main xtpqcce_qmg_y_main, ///
	cols(1) iscale(0.8) ///
	title("xtpqcce: CCEMG-CSQR (top) vs QCCEMG (bottom)", size(small)) ///
	graphregion(color(white)) name(xtpqcce_both, replace)
graph export "xtpqcce_both_demo.png", replace width(1600)

di as txt _n "ALL TESTS COMPLETED."
