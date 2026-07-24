*! icss_example.do  --  self-test / known-truth validation for -icss-
*! flexur library : Dr Merwan Roudane
*!
*! Run AFTER loading the command:
*!     do icss.ado
*!     do icss_example.do
*! (use -clear-, NOT -clear all-, so the just-loaded program survives)

clear
set more off
set seed 12345

*==========================================================================
* CASE A -- iid N(0,1), NO change in variance.
*   Truth: 0 breaks.  All three tests should (mostly) detect none;
*   kappa2 is the most reliable.
*==========================================================================
di _n(2) as txt "{hline 74}"
di as txt "CASE A : iid N(0,1), T=500  -- TRUTH = 0 variance breaks"
di as txt "{hline 74}"
quietly set obs 500
gen t = _n
tsset t
gen double y = rnormal()

icss y, test(all)
di as txt ">> Expected: 0 breaks for all three tests (kappa2 cleanest)."

*==========================================================================
* CASE B -- single variance break at t=250 (sd 1 -> sd 2).
*   Truth: 1 break near t=250.
*==========================================================================
di _n(2) as txt "{hline 74}"
di as txt "CASE B : sd=1 for t<=250, sd=2 for t>250  -- TRUTH = 1 break @ 250"
di as txt "{hline 74}"
clear
quietly set obs 500
gen t = _n
tsset t
gen double y = rnormal() * cond(t<=250, 1, 2)

icss y, test(k2) graph gname(icss_caseB)
di as txt ">> Expected: 1 break near position 250 (kappa2)."
return list

*==========================================================================
* CASE C -- GARCH(1,1)-type leptokurtic + persistent variance, NO true break.
*   Truth: 0 structural breaks. The paper's point:
*   IT (and kappa1) OVER-detect spurious breaks; kappa2 stays clean.
*==========================================================================
di _n(2) as txt "{hline 74}"
di as txt "CASE C : GARCH(1,1), T=500, NO true break"
di as txt "         -- IT/kappa1 over-reject; kappa2 should find ~0 breaks"
di as txt "{hline 74}"
clear
quietly set obs 500
gen t = _n
tsset t
* GARCH(1,1):  h_t = 0.05 + 0.10 e^2_{t-1} + 0.85 h_{t-1}
gen double e = .
gen double h = .
quietly replace h = 0.05/(1-0.10-0.85) in 1
tempvar z
gen double `z' = rnormal()
quietly replace e = sqrt(h)*`z' in 1
forvalues i = 2/500 {
    quietly replace h = 0.05 + 0.10*e[`i'-1]^2 + 0.85*h[`i'-1] in `i'
    quietly replace e = sqrt(h[`i'])*rnormal() in `i'
}
rename e y

di as txt "--- ICSS(IT): expect several SPURIOUS breaks ---"
icss y, test(it)
di as txt "--- ICSS(kappa2): expect ~0 breaks (robust) ---"
icss y, test(k2)

di _n as txt "{hline 74}"
di as txt "Validation summary:"
di as txt " A) no-break data      -> ~0 breaks (all tests)."
di as txt " B) one true break     -> 1 break near 250 (kappa2)."
di as txt " C) GARCH, no break    -> IT over-detects, kappa2 stays near 0."
di as txt "{hline 74}"
