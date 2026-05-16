*------------------------------------------------------------------------------
*  rals_demo.do
*  Walk-through of the full rals package using bundled Stata data.
*  Assumes the package has been installed via:
*       net install rals, from("C:/path/to/stata_rals")
*  (no need to do anything with adopath manually).
*
*  Author: Dr Merwan Roudane  <merwanroudane920@gmail.com>
*------------------------------------------------------------------------------
clear all
set more off
set scheme s2color

di as text "{hline 78}"
di as result "  rals package -- complete demo"
di as text "{hline 78}"

* --- 0. Master banner -------------------------------------------------------
rals about

* --- 1. Load data and tsset -------------------------------------------------
sysuse sp500, clear
gen t = _n
tsset t

* --- 2. Diagnostics ---------------------------------------------------------
di as result _n "  >> ralsdiag (non-normality / linearity / rho^2 preview)"
ralsdiag close, trend

* --- 3. Individual unit-root tests -----------------------------------------
di as result _n "  >> ralsadf (RALS-ADF unit root, with graph)"
ralsadf close, trend graph

di as result _n "  >> ralslm (RALS-LM unit root)"
ralslm close

di as result _n "  >> ralslmb (RALS-LM with 1 endogenous break, with graph)"
ralslmb close, model(2) breaks(1) graph

di as result _n "  >> ralsfadf (RALS-Fourier ADF, with graph)"
ralsfadf close, trend graph

di as result _n "  >> ralsfkss (RALS-Fourier KSS, with graph)"
ralsfkss close, trend graph

* --- 4. One-shot battery (every unit-root test) -----------------------------
di as result _n "  >> ralsbattery (every unit-root test in one call)"
ralsbattery close, trend graph

* --- 5. Multivariate battery (unit-root + cointegration) --------------------
di as result _n "  >> ralsbattery with cointegration"
ralsbattery close volume open, trend graph

* --- 6. Cointegration only --------------------------------------------------
di as result _n "  >> ralscoint (ECM / ADL / EG / EG2)"
ralscoint close volume open, trend

di as result _n "  >> ralsfadl (Fourier ADL cointegration)"
ralsfadl close volume open, trend graph

di as text _n "{hline 78}"
di as result "  Demo finished -- inspect each Graph window and Results window."
di as text "{hline 78}"
