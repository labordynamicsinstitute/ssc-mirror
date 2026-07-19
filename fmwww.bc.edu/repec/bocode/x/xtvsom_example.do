*! xtvsom_example.do  1.0.0  18jul2026
*! Self-test / demonstration for xtvsom.
*! Simulates an FE panel with KNOWN true slopes and INJECTED outliers, then
*! exercises every code path (postestimation FE, standalone FE, pooled OLS,
*! simultaneous 2SLS).  Paste the log back for refereeing.
*! Run:  do xtvsom.ado    then    do xtvsom_example.do
*! Author: Dr Merwan Roudane

clear
set seed 20260718
version 14.0

* ---- balanced panel: N=40 units, T=8 -> 320 obs -----------------------
local N  = 40
local T  = 8
set obs `=`N'*`T''
gen int id = ceil(_n/`T')
bysort id: gen int t = _n
xtset id t

* unit fixed effects
by id: gen double alpha = rnormal()*2 if _n==1
by id: replace alpha = alpha[1]
* regressors (x1 correlated with alpha to make FE bite)
gen double x1 = 0.5*alpha + rnormal()
gen double x2 = rnormal()
gen double x3 = rnormal()

* TRUE slopes
scalar b1 = 1.0
scalar b2 = -0.5
scalar b3 = 0.75
gen double e  = rnormal()
gen double y  = alpha + b1*x1 + b2*x2 + b3*x3 + e

* ---- inject 5 gross outliers (large positive shocks) ------------------
gen byte trueout = 0
foreach o in 17 58 129 200 265 {
    replace y = y + 8 in `o'
    replace trueout = 1 in `o'
}

di as txt _n "TRUE slopes:  b1=1.0  b2=-0.5  b3=0.75    (5 injected outliers)"

* ======================================================================
* 1. Postestimation after xtreg, fe   (+ figures)
* ======================================================================
di as txt _n(2) "{hline 70}" _n "1) xtvsom postestimation after xtreg, fe" _n "{hline 70}"
xtreg y x1 x2 x3, fe
xtvsom, alpha(0.05) reps(1000) seed(777) graph
matrix list r(b_vsom)

* cross-check the injected outliers were flagged
matrix OL = r(outliers)
di as txt "injected obs = 17 58 129 200 265 ; detected obs are in r(outliers) col 1"

* verify e() was restored
di as txt _n "e(cmd) after xtvsom (should be xtreg): " as res "`e(cmd)'"

* ======================================================================
* 2. Standalone FE (should match the postestimation slopes)
* ======================================================================
di as txt _n(2) "{hline 70}" _n "2) xtvsom standalone, fe" _n "{hline 70}"
xtvsom y x1 x2 x3, fe seed(777)

* ======================================================================
* 3. Pooled OLS design
* ======================================================================
di as txt _n(2) "{hline 70}" _n "3) xtvsom pooled OLS" _n "{hline 70}"
regress y x1 x2 x3
xtvsom, ols seed(777)

* ======================================================================
* 4. Simultaneous / 2SLS design
* ======================================================================
di as txt _n(2) "{hline 70}" _n "4) xtvsom after ivregress 2sls (simultaneous)" _n "{hline 70}"
* build an endogenous regressor w with instruments z1 z2
* (small unit-effect share so pooled 2SLS residual variance stays modest)
gen double z1 = rnormal()
gen double z2 = rnormal()
gen double w  = 0.6*z1 - 0.4*z2 + 0.5*x2 + rnormal()
gen double y2 = 0.15*alpha + 1.2*w + 0.3*x1 + rnormal()
replace y2 = y2 + 12 in 58
replace y2 = y2 + 12 in 200
di as txt "TRUE structural: w=1.2  x1=0.3  (outliers at 58, 200)"
ivregress 2sls y2 (w = z1 z2) x1
xtvsom, iv seed(777)

di as txt _n(2) "{hline 70}" _n "REFEREE CHECKLIST" _n "{hline 70}"
di as txt "[ ] compiles clean (no 'error loading xtvsom.ado')"
di as txt "[ ] slopes recover ~ b1=1.0 b2=-0.5 b3=0.75 under VSOM"
di as txt "[ ] most injected obs (17 58 129 200 265) appear in r(outliers)"
di as txt "[ ] SSR VSOM < SSR null"
di as txt "[ ] e(cmd)=xtreg restored after run 1"
di as txt "[ ] four-panel figure drawn in run 1"
