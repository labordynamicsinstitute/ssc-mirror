*-------------------------------------------------------------------------------
* urvol_example.do
* Worked examples for -urvol-: unit-root tests robust to time-varying volatility.
*   wbdf  : wild-bootstrap (A)DF/PP       (Cavaliere & Taylor 2008, 2009)
*   beare : kernel-rescaled PP            (Beare 2017)
*   bzu   : adaptive wild-bootstrap LR    (Boswijk & Zu 2018)
*
* Author: Merwan Roudane (merwanroudane920@gmail.com)
*-------------------------------------------------------------------------------
clear all
set more off
set seed 20260709

*===============================================================================
* PART A.  REAL DATA  (runs when you have an internet connection)
*===============================================================================
* A1. A macro price series (classic unit-root example): quarterly log WPI.
capture webuse wpi1, clear
if _rc==0 {
    tsset t
    di as txt _n "{hline 78}"
    di as txt "A1. Quarterly log WPI (trend model) - the three tests at a glance"
    di as txt "{hline 78}"
    urvol all ln_wpi, trend reps(999)

    * detailed single tests, with the diagnostic graphs
    urvol wbdf  ln_wpi, trend reps(999) graph gname(wpi_wbdf)
    urvol beare ln_wpi, trend reps(999) graph gname(wpi_beare)
    urvol bzu   ln_wpi, trend reps(999) graph gname(wpi_bzu)
}

* A2. A financial series with pronounced volatility clustering: daily S&P 500.
capture webuse sp500, clear
if _rc==0 {
    gen t = _n
    tsset t
    gen double lclose = ln(close)
    di as txt _n "{hline 78}"
    di as txt "A2. Daily log S&P 500 (constant model) - volatility is clearly unstable"
    di as txt "{hline 78}"
    urvol all lclose, reps(999)
    urvol bzu lclose, graph gname(sp500_vol)     // inspect the estimated sigma(t)
}

*===============================================================================
* PART B.  SHIPPED / REPRODUCIBLE DATA  (always runs, no internet needed)
*     A unit-root series with a genuine late positive variance shift - exactly the
*     Cavaliere (2004) DGP that distorts classical DF/PP tests.
*===============================================================================
clear
set obs 300
gen t = _n
tsset t
gen double e = rnormal()
replace e = e*4 if t > 0.7*300                 // sigma: 1 -> 4 late in the sample
gen double y = 0
replace y = y[_n-1] + e if _n > 1              // random walk => H0 (unit root) TRUE
label var y "I(1) series with a late variance break"

di as txt _n "{hline 78}"
di as txt "B1. H0 TRUE (random walk + variance break): all tests should NOT reject"
di as txt "{hline 78}"
urvol all y, reps(999)

* the wild bootstrap null distribution and the estimated volatility path
urvol wbdf y, reps(999) graph gname(sim_boot)
urvol beare y, reps(999) graph gname(sim_beare)
urvol bzu   y, reps(999) graph gname(sim_bzu)

* combine the diagnostics into one journal-style dashboard
capture graph combine sim_boot sim_beare sim_bzu, ///
    cols(1) title("urvol diagnostics: I(1) series with a variance break") ///
    graphregion(color(white)) name(urvol_dashboard, replace)

* B2. A STATIONARY series with the same variance break: tests SHOULD reject
clear
set obs 300
gen t = _n
tsset t
gen double e = rnormal()
replace e = e*4 if t > 0.7*300
gen double y = 0
replace y = 0.5*y[_n-1] + e if _n > 1          // AR(0.5) => H1 (stationary) TRUE
label var y "Stationary AR(0.5) with a variance break"

di as txt _n "{hline 78}"
di as txt "B2. H1 TRUE (stationary AR(0.5) + variance break): tests SHOULD reject"
di as txt "{hline 78}"
urvol all y, reps(999)

di as result _n "urvol_example.do finished."
