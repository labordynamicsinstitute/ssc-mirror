*==============================================================================
* tsadvroot_test.do -- full self-test of the tsadvroot package
* Exercises every subcommand and code path on simulated data with known
* properties, in both no-rejection (unit root) and rejection (stationary)
* configurations, including tables, graphs and stored results.
* Author: Merwan Roudane (merwanroudane920@gmail.com)
*
* Run time: about 2-5 minutes (dominated by the fqadf bootstrap and the
* cisur two-break search).
*==============================================================================
clear all
set more off
set seed 20260703
local errors 0

di as text _n "{hline 78}"
di as text "tsadvroot self-test started: $S_DATE $S_TIME"
di as text "{hline 78}"

*------------------------------------------------------------------------------
* DGP 1: pure random walk (H0 true everywhere), T = 200
*------------------------------------------------------------------------------
qui {
    set obs 200
    gen t = _n
    tsset t
    gen eps = rnormal()
    gen rw = eps in 1
    replace rw = L.rw + eps in 2/L
    * DGP 2: stationary AR(0.5) (H0 false)
    gen ar = eps in 1
    replace ar = 0.5*L.ar + eps in 2/L
    * DGP 3: stationary around a smooth (Fourier-type) shifting mean
    gen smooth = 2*sin(2*_pi*1*t/200) + 0.4*ar
    * DGP 4: stationary around a broken trend (breaks at t = 70 and t = 140)
    gen brk = 0.02*t + 1.5*(t>70) + 3.0*(t>140) + 0.5*ar
}

*------------------------------------------------------------------------------
* 1. qadf -- default deciles, model c, on the random walk
*------------------------------------------------------------------------------
di as text _n ">>> [1/12] tsadvroot qadf, defaults, random walk"
capture noisily tsadvroot qadf rw
if _rc {
    di as err "FAILED (rc = " _rc ")"
    local ++errors
}
else {
    assert r(lags) >= 0 & r(lags) <= 8
    matrix R = r(results)
    assert rowsof(R) == 9
    di as result "OK  (lags = " r(lags) ", N = " r(N) ")"
}

di as text _n ">>> [2/12] tsadvroot qadf, single tau, model ct, ic(aic), stationary AR"
capture noisily tsadvroot qadf ar, tau(0.5) model(ct) ic(aic) pmax(6)
if _rc {
    di as err "FAILED (rc = " _rc ")"
    local ++errors
}
else {
    assert r(tn) < .
    assert r(cv5) < .
    di as result "OK  (tn = " %6.3f r(tn) ", 5% cv = " %6.3f r(cv5) ")"
    if r(tn) < r(cv5) di as result "    rejects unit root for AR(0.5): as expected"
    else di as text "    note: no 5% rejection this draw (power is not 100%)"
}

di as text _n ">>> [3/12] tsadvroot qadf with graph, three quantiles, ic(sic)"
capture noisily tsadvroot qadf ar, tau(0.25 0.5 0.75) ic(sic) graph name(g_qadf)
if _rc {
    di as err "FAILED (rc = " _rc ")"
    local ++errors
}
else di as result "OK  (graph g_qadf created)"

di as text _n ">>> [4/12] tsadvroot qadf, pmax(0) forces no lags"
capture noisily tsadvroot qadf rw, tau(0.5) pmax(0) noprint
if _rc {
    di as err "FAILED (rc = " _rc ")"
    local ++errors
}
else {
    assert r(lags) == 0
    di as result "OK  (lags = 0)"
}

*------------------------------------------------------------------------------
* 2. fqadf -- Fourier quantile ADF
*------------------------------------------------------------------------------
di as text _n ">>> [5/12] tsadvroot fqadf, no bootstrap, smooth-break series, graph"
capture noisily tsadvroot fqadf smooth, tau(0.25 0.5 0.75) freq(1) lags(2) ///
    nobootstrap graph name(g_fqadf)
if _rc {
    di as err "FAILED (rc = " _rc ")"
    local ++errors
}
else {
    matrix R = r(results)
    assert R[2,5] < .
    di as result "OK  (median tn = " %6.3f R[2,5] ")"
}

di as text _n ">>> [6/12] tsadvroot fqadf with bootstrap (B=99, seeded)"
capture noisily tsadvroot fqadf smooth, tau(0.5) model(c) freq(1) lags(2) ///
    nboot(99) seed(12345)
if _rc {
    di as err "FAILED (rc = " _rc ")"
    local ++errors
}
else {
    assert r(pboot) >= 0 & r(pboot) <= 1
    assert r(cv5) < .
    assert r(cvsrc5) < .
    di as result "OK  (tn = " %6.3f r(tn) ", boot p = " %5.3f r(pboot) ")"
}

di as text _n ">>> [7/12] tsadvroot fqadf, model ct, random walk (should NOT reject)"
capture noisily tsadvroot fqadf rw, tau(0.5) model(ct) freq(2) lags(1) ///
    nboot(99) seed(6789)
if _rc {
    di as err "FAILED (rc = " _rc ")"
    local ++errors
}
else {
    di as result "OK  (boot p = " %5.3f r(pboot) ")"
    if r(pboot) > 0.05 di as result "    no rejection under H0: as expected"
    else di as text "    note: 5% rejection under H0 happens ~5% of draws"
}

*------------------------------------------------------------------------------
* 3. npadf -- Narayan-Popp two-break test
*------------------------------------------------------------------------------
di as text _n ">>> [8/12] tsadvroot npadf model(1), broken-trend series, graph"
capture noisily tsadvroot npadf brk, model(1) pmax(4) graph name(g_np1)
if _rc {
    di as err "FAILED (rc = " _rc ")"
    local ++errors
}
else {
    assert r(stat) < .
    assert r(tb1pos) < r(tb2pos)
    di as result "OK  (ADF = " %6.3f r(stat) ", breaks at t = " ///
        r(tb1) " and t = " r(tb2) ")"
}

di as text _n ">>> [9/12] tsadvroot npadf model(2), ic(aic), trim(0.15)"
capture noisily tsadvroot npadf brk, model(2) pmax(4) ic(aic) trim(0.15)
if _rc {
    di as err "FAILED (rc = " _rc ")"
    local ++errors
}
else di as result "OK  (ADF = " %6.3f r(stat) ")"

*------------------------------------------------------------------------------
* 4. cisur -- Carrion-i-Silvestre, Kim & Perron (2009)
*------------------------------------------------------------------------------
di as text _n ">>> [10/12] tsadvroot cisur, no-break models (const / trend)"
capture noisily tsadvroot cisur rw, model(const)
if _rc {
    di as err "FAILED (rc = " _rc ")"
    local ++errors
}
else {
    assert r(cbar) == -7
    di as result "OK  (model 0: cbar = -7, MZt = " %6.3f r(mzt) ")"
}
capture noisily tsadvroot cisur rw, model(trend) noprint
if _rc {
    di as err "FAILED (rc = " _rc ")"
    local ++errors
}
else {
    assert r(cbar) == -13.5
    di as result "OK  (model 1: cbar = -13.5)"
}

di as text _n ">>> [11/12] tsadvroot cisur model(break) breaks(1) + graph, then breaks(2)"
capture noisily tsadvroot cisur brk, model(break) breaks(1) graph name(g_cis1)
if _rc {
    di as err "FAILED (rc = " _rc ")"
    local ++errors
}
else {
    matrix CV = r(cv)
    assert rowsof(CV) == 4 & colsof(CV) == 3
    di as result "OK  (1 break at t = " el(r(breakpos),1,1) ///
        ", cbar = " %7.3f r(cbar) ")"
}
capture noisily tsadvroot cisur brk, model(break) breaks(2) penalty(bic)
if _rc {
    di as err "FAILED (rc = " _rc ")"
    local ++errors
}
else {
    matrix B = r(breakpos)
    di as result "OK  (2 breaks at t = " el(B,1,1) " and t = " el(B,2,1) ///
        "; true breaks 70 and 140)"
}

di as text _n ">>> [12/12] tsadvroot cisur, known breaks + model(slope)"
capture noisily tsadvroot cisur brk, model(break) breakdates(70 140)
if _rc {
    di as err "FAILED (rc = " _rc ")"
    local ++errors
}
else di as result "OK  (known-break MZt = " %6.3f r(mzt) ")"
capture noisily tsadvroot cisur brk, model(slope) breaks(1) noprint
if _rc {
    di as err "FAILED (rc = " _rc ")"
    local ++errors
}
else di as result "OK  (model slope runs)"

*------------------------------------------------------------------------------
* 5. Error handling: gaps, panel data, bad options
*------------------------------------------------------------------------------
di as text _n ">>> error-handling checks"
capture tsadvroot qadf rw if t != 100
if _rc == 498 di as result "OK  (gap in sample correctly rejected)"
else {
    di as err "FAILED: gap not detected (rc = " _rc ")"
    local ++errors
}
capture tsadvroot qadf rw, model(xyz)
if _rc == 198 di as result "OK  (bad model() rejected)"
else {
    di as err "FAILED: bad model() not rejected (rc = " _rc ")"
    local ++errors
}
capture tsadvroot cisur rw, model(break) breaks(4)
if _rc == 198 di as result "OK  (breaks(4) unknown correctly rejected)"
else {
    di as err "FAILED: breaks(4) not rejected (rc = " _rc ")"
    local ++errors
}
capture tsadvroot badsub rw
if _rc == 199 di as result "OK  (unknown subcommand rejected)"
else {
    di as err "FAILED: unknown subcommand not rejected (rc = " _rc ")"
    local ++errors
}

*------------------------------------------------------------------------------
* Summary
*------------------------------------------------------------------------------
di as text _n "{hline 78}"
if `errors' == 0 {
    di as result "tsadvroot self-test COMPLETED: all checks passed."
}
else {
    di as err "tsadvroot self-test finished with `errors' FAILURE(S) -- see above."
}
di as text "Graphs created: g_qadf, g_fqadf, g_np1, g_cis1 (use graph dir to list)"
di as text "{hline 78}"
