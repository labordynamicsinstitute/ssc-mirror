*======================================================================
* xtdynestimb -- guided showcase / self-test  ("see everything")
*
* Run this whole file once to see all three estimators, every variant,
* the comparison table, the coefficient graphs, the postestimation tools
* and (if installed) cross-checks against xtabond2 / xtdpdgmm.
*
*   . cd "C:\Users\HP\Documents\xtpmg\Nouveau dossier (4)\xtdynestimb"
*   . do xtdynestimb_example.do
*
* Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*======================================================================
clear all
set more off
set linesize 120

*--- 0. install the package from this folder ---------------------------
capture ado uninstall xtdynestimb
net install xtdynestimb, from("`c(pwd)'") replace
which xtdynestimb

*======================================================================
* 1. Simulate a bank-lending-style dynamic panel calibrated to
*    Chowdhury & Russell (2017), Table A1 (US bank loan growth,
*    1993-2007, n banks, T=15).  Three regimes with breaks at the
*    1998 and 2003 boundaries (periods 5 and 10) and regime mean loan
*    growth rates 0.0996 / 0.0858 / 0.0761; idiosyncratic sd = 0.163.
*    Entity-specific fixed-effect breaks are added (as the paper
*    assumes) so the difference/system estimators are biased away from
*    the double-D estimators.  True persistence (AR1) = 0.40.
*======================================================================
set seed 12345
local N 200
local T 15
local arue 0.40

set obs `N'
gen id = _n
gen double eta    = rnormal()*0.3            // bank-specific effect
gen double lam    = 0.05 + 0.15*runiform()   // factor loading -> CSD
gen double delta1 = rnormal()*0.30           // entity break at 1998 (t=5)
gen double delta2 = rnormal()*0.30           // entity break at 2003 (t=10)
expand `T'
bysort id: gen t = _n
xtset id t

* common macro factor f_t (GDP/policy shock), identical across banks
bysort t (id): gen double f = rnormal() if _n==1
bysort t (id): replace f = f[1]

* three regimes (separated enough to be detectable in the aggregate),
* breaks at the 1998 (t=5) and 2003 (t=10) boundaries, plus entity breaks
gen double mu = cond(t<=4, 0.40, cond(t<=9, 0.10, -0.10))
gen double shift = cond(t>=10, delta1+delta2, cond(t>=5, delta1, 0))

* recursive AR(1): loan growth y = a*L.y + mu + (eta+shift) + lam*f + e
* start at the stationary level to avoid an initial-condition transient
sort id t
gen double y = .
by id: replace y = (mu+eta+shift)/(1-`arue') + lam*f + rnormal()*0.163 if t == 1
by id: replace y = `arue'*y[_n-1] + mu + (eta+shift) + lam*f + rnormal()*0.163 if t > 1

* a strictly exogenous macro regressor x (e.g. the interest rate change)
gen double x = 0.4*f + rnormal()*0.5
xtset id t
summarize y x

*======================================================================
* 2. DOUBLE-D GMM  (Chowdhury & Russell 2017)  -- break-robust
*======================================================================
di _n(2) as txt "{hline 70}"
di as txt ">>> 2a-i. BREAK / REGIME DETECTION (Bai-Perron, like the paper's Table A1)"
di as txt "{hline 70}"
xtdynestimb breaks y, minlength(3)
matrix list r(regimes)

di _n(2) as txt ">>> 2a-ii. EMPIRICAL COMPARISON TABLE (Chowdhury-Russell 2017, Table 7 style)"
di as txt "          regimes on top, then estimators in columns with long-run coefs"
di as txt "{hline 70}"
xtdynestimb table y x, lags(1) gmmlags(2 4) breaks minlength(3) longrun ///
    title("US bank lending channel: estimator comparison (calibrated)")
matrix list r(coef)

di _n(2) as txt ">>> 2b. Same comparison, persistence coefficient only + plot"
di as txt "{hline 70}"
xtdynestimb dd y, lags(1) compare graph graphname(g_compare)
matrix list r(compare)

di _n(2) as txt ">>> 2c. The full (recommended) break-robust estimator + plot"
xtdynestimb dd y, lags(1) variant(full) graph graphname(g_dd_full)

di _n(2) as txt ">>> 2d. With the exogenous regressor x and capped instruments"
xtdynestimb dd y x, lags(1) variant(full) gmmlags(2 5)

di _n(2) as txt ">>> 2e. Long-run effect of x via nlcom"
nlcom (lr_x: _b[x]/(1 - _b[L1.y]))

*======================================================================
* 3. CSD-ROBUST GMM  (Sarafidis 2009)  -- handles the common factor
*======================================================================
di _n(2) as txt "{hline 70}"
di as txt ">>> 3a. CSD-robust system GMM (time-demeaned)"
di as txt "{hline 70}"
xtdynestimb csdgmm y x, variant(system) graph graphname(g_csd)

di _n(2) as txt ">>> 3b. Regressor-only (partial) instruments"
xtdynestimb csdgmm y x, variant(system) partial

di _n(2) as txt ">>> 3c. Turn the CSD correction OFF (to see its effect)"
xtdynestimb csdgmm y x, variant(system) nodemean

*======================================================================
* 4. ARELLANO-BOND LASSO  (Chernozhukov et al. 2024)  -- long-T bias
*======================================================================
di _n(2) as txt "{hline 70}"
di as txt ">>> 4a. Plain AB-LASSO"
di as txt "{hline 70}"
xtdynestimb ablasso y, lags(1)

di _n(2) as txt ">>> 4b. AB-LASSO-SS: 5-fold cross-fitting over 5 splits + plot"
xtdynestimb ablasso y, lags(1) crossfit kfold(5) nsplits(5) seed(123) ///
    graph graphname(g_ablasso)

di _n(2) as txt ">>> 4c. TABLE 5.1 LAYOUT (Chernozhukov et al. 2024): AB-LASSO-SS(K=2),"
di as txt "        AB-LASSO-SS(K=5), AB, DAB-SS; AR(4); short-run + long-run per regressor."
di as txt "        AB-LASSO needs LONG T, so we use a fresh T=30 panel here (like the"
di as txt "        paper's COVID application, T=27).  True AR(1)=0.5; b_D=0.40, b_C=-0.25."
di as txt "{hline 90}"
preserve
clear
set seed 20240
local N2 300
local T2 30
set obs `N2'
gen id = _n
gen double eta = rnormal()*0.3
expand `T2'
bysort id: gen t = _n
xtset id t
* two strictly exogenous covariates (a treatment D and a control C)
gen double D = rnormal()
gen double C = rnormal()
sort id t
gen double Y = .
by id: replace Y = eta/(1-0.5) + 0.40*D - 0.25*C + rnormal() if t==1
by id: replace Y = 0.5*Y[_n-1] + 0.40*D - 0.25*C + eta + rnormal() if t>1
xtset id t

xtdynestimb table Y D C, lags(4) gmmlags(2 6) srlr nsplits(3) ///
    estimators(ablasso2 ablasso5 ab dabss) ///
    title("Short-run & long-run effects (T=30 panel, AB-LASSO regime)")

di _n(2) as txt ">>> 4d. Debiased Arellano-Bond (DAB-SS) on its own"
xtdynestimb dabss Y D C, lags(4)
restore

*======================================================================
* 5. Postestimation: predict + companion specification tests (xtdyntest)
*======================================================================
di _n(2) as txt "{hline 70}"
di as txt ">>> 5. Residuals + cross-sectional-dependence tests"
di as txt "{hline 70}"
xtdynestimb csdgmm y x, variant(system)
predict double ehat, residuals
capture which xtdyntest
if _rc == 0 {
    xtdyntest csd, residuals(ehat)
}
else {
    di as txt "(install xtdyntest to run the residual CSD battery here)"
}

*======================================================================
* 6. OPTIONAL cross-checks against xtabond2 / xtdpdgmm
*    The difference variant should track the Arellano-Bond estimator.
*======================================================================
di _n(2) as txt "{hline 70}"
di as txt ">>> 6. Cross-checks (only if xtabond2 / xtdpdgmm are installed)"
di as txt "{hline 70}"
xtdynestimb dd y, lags(1) variant(difference) twostep

capture which xtabond2
if _rc == 0 {
    di _n as txt ">>> xtabond2 two-step difference GMM (for comparison):"
    capture noisily xtabond2 y L.y, gmm(L.y, lag(2 .)) noleveleq twostep robust nodiffsargan
}
capture which xtdpdgmm
if _rc == 0 {
    di _n as txt ">>> xtdpdgmm two-step difference GMM (for comparison):"
    capture noisily xtdpdgmm y L.y, gmm(y, lag(2 .)) model(diff) twostep vce(robust)
    di _n as txt ">>> xtdpdgmm AR(1)/AR(2) tests -- should match xtdynestimb's exact AB test:"
    capture noisily estat serial, ar(1/2)
}

di _n(2) as txt "{hline 70}"
di as txt "Done. Graphs created: g_compare, g_dd_full, g_csd, g_ablasso."
di as txt "Type  help xtdynestimb  for the full documentation."
di as txt "{hline 70}"
