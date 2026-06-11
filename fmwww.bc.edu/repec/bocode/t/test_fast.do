*! test_fast.do  --  fast (no-ML) end-to-end test of xtcsnardl v1.0.0
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*!
*! Skips PMG / MG (which use ML and can take minutes on asymmetric data).
*! Covers DFE + all four xtdcce2 engines + all 10 tables + all 5 plots.
*! Runs in under one minute on a typical laptop.

clear all
set more off
set seed 2026

* ---- discoverability ------------------------------------------------------
foreach c in xtcsnardl xtcsnardl_graph xtpmg xtdcce2 {
    capture which `c'
    if _rc {
        di as error "MISSING: `c'  -- install with: ssc install `c', replace"
        exit 199
    }
}

* ---- DGP ------------------------------------------------------------------
set obs 8
gen id = _n
expand 80
bysort id: gen t = 1939 + _n
xtset id t

gen double f = .
by id: replace f = rnormal() if _n == 1
by id: replace f = 0.5*f[_n-1] + 0.3*rnormal() if _n > 1

gen double lam_x = runiform(0.30, 0.70)
gen double x = lam_x*f + rnormal()
gen double c = 0.3*f + 0.5*rnormal()

gen double dxp = max(d.x, 0)
gen double dxn = min(d.x, 0)
replace dxp = 0 if dxp == .
replace dxn = 0 if dxn == .
by id: gen double truepos = sum(dxp)
by id: gen double trueneg = sum(dxn)

gen double lam_y = runiform(0.2, 0.5)
gen double y = 0
forvalues s = 2/80 {
    qui replace y = L.y + (-0.35)*(L.y - 0.60*truepos - (-0.90)*trueneg ///
                                   - 0.40*c) + lam_y*f + 0.3*rnormal() ///
                   if t - 1939 == `s'
}
drop if t < 1950
xtset id t

* ---- 1. DFE ---------------------------------------------------------------
di _n as result "{hline 60}"
di as result "  ENGINE 1/5:  DFE (xtpmg, OLS-like)"
di as result "{hline 60}"
xtcsnardl D.y L.y D.x D.c, lr(L.y x c) asymmetric(x) dfe cr_lags(1) ///
    multip(10) irfshock(10) asytable replace
di _n as result "  >>> DFE: PASS  (recovered beta+ ~ " %5.3f _b[ECT:x_pos] ///
    " | beta- ~ " %5.3f _b[ECT:x_neg] " | phi ~ " %5.3f _b[SR:ECT] ")"

* ---- 2. CS-ARDL (xtdcce2) -------------------------------------------------
di _n as result "{hline 60}"
di as result "  ENGINE 2/5:  Nonlinear CS-ARDL (xtdcce2)"
di as result "{hline 60}"
xtcsnardl D.y L.y D.x D.c, lr(L.y x c) asymmetric(x) engine(csardl) ///
    cr_lags(1) multip(8) irfshock(8) replace
di _n as result "  >>> CS-ARDL: PASS  (lr_x+ ~ " %5.3f _b[lr_x_pos] ///
    " | lr_x- ~ " %5.3f _b[lr_x_neg] " | phi ~ " %5.3f _b[lr_y] ")"

* ---- 3. CS-DL (xtdcce2) ---------------------------------------------------
di _n as result "{hline 60}"
di as result "  ENGINE 3/5:  Nonlinear CS-DL (xtdcce2)"
di as result "{hline 60}"
xtcsnardl D.y L.y D.x D.c, lr(L.y x c) asymmetric(x) engine(csdl) ///
    cr_lags(1) replace
di _n as result "  >>> CS-DL: PASS"

* ---- 4. DCCE (xtdcce2) ----------------------------------------------------
di _n as result "{hline 60}"
di as result "  ENGINE 4/5:  Nonlinear DCCE (xtdcce2)"
di as result "{hline 60}"
xtcsnardl D.y L.y D.x D.c, lr(L.y x c) asymmetric(x) engine(dcce) ///
    cr_lags(1) replace
di _n as result "  >>> DCCE: PASS"

* ---- 5. CCE (xtdcce2) -----------------------------------------------------
di _n as result "{hline 60}"
di as result "  ENGINE 5/5:  Nonlinear CCE (xtdcce2)"
di as result "{hline 60}"
xtcsnardl D.y L.y D.x D.c, lr(L.y x c) asymmetric(x) engine(cce) ///
    cr_lags(1) replace
di _n as result "  >>> CCE: PASS"

* ---- GRAPHS ---------------------------------------------------------------
di _n as result "{hline 60}"
di as result "  GRAPH TEST"
di as result "{hline 60}"
xtcsnardl D.y L.y D.x D.c, lr(L.y x c) asymmetric(x) dfe cr_lags(0) ///
    multip(15) irfshock(15) graph replace
foreach g in csn_lr_asym csn_multip_1 csn_irf_1 csn_csa csn_ect {
    capture graph export "fast_`g'.png", name(`g') replace width(900)
    if _rc == 0 di as text "  saved fast_`g'.png"
}

* ---- SUMMARY --------------------------------------------------------------
di _n as result "{hline 60}"
di as result "  FAST TEST COMPLETE"
di as text  "  xtcsnardl v1.0.0  --  Dr Merwan Roudane"
di as text  "                        merwanroudane920@gmail.com"
di as text  "  5 engines tested:  dfe / csardl / csdl / dcce / cce"
di as result "{hline 60}"
