*==============================================================================
* aardl — worked examples
* Augmented ARDL cointegration analysis
* Version 2.0.0 — 28 August 2026
* Dr Merwan Roudane  (merwanroudane920@gmail.com)
*==============================================================================
* Run this file after installing the package.  Each block is self-contained.
*==============================================================================

clear all
set more off

*------------------------------------------------------------------------------
* 0.  Data
*     Any tsset time-series dataset with a contiguous sample will do.  The
*     Lutkepohl macro data that ships with Stata is used here.
*------------------------------------------------------------------------------
webuse lutkepohl2, clear
tsset qtr

*------------------------------------------------------------------------------
* 1.  Baseline augmented ARDL, asymptotic bounds
*
*     Three tests are reported.  Cointegration requires all three to reject:
*       F_overall  joint significance of every lagged level
*       t_DV       the lagged level of the dependent variable
*       F_ind      the lagged levels of the independent variables
*
*     F and t bounds come from ardlbounds (Kripfganz & Schneider 2020).
*     F_ind bounds come from Tables 1-3 of Sam, McNown & Goh (2019), which are
*     built into the package.  The ordinary regression p-value for F_ind is
*     invalid under I(1) regressors and is deliberately not shown.
*------------------------------------------------------------------------------
aardl ln_inv ln_inc ln_consump, maxlag(4) ic(aic)

* what came out
display "cointegration status : " e(coint_status)
display "speed of adjustment  : " e(ecm_coef)
display "half-life            : " e(halflife)
display "CUSUM / CUSUMSQ      : " e(cusum) " / " e(cusumsq)
matrix list e(bounds)

*------------------------------------------------------------------------------
* 2.  Deterministic cases
*
*     case() changes the ESTIMATED equation, not just the critical-value table.
*       1  no intercept, no trend
*       2  restricted intercept   (the intercept joins the F_overall null and
*                                  appears among the long-run coefficients)
*       3  unrestricted intercept (default)
*       4  restricted trend       (the trend joins the F_overall null and
*                                  appears among the long-run coefficients)
*       5  unrestricted trend
*------------------------------------------------------------------------------
aardl ln_inv ln_inc ln_consump, case(5) maxlag(4) ///
      nodiag nostability nodynmult noadvanced nograph
aardl ln_inv ln_inc ln_consump, case(2) maxlag(4) ///
      nodiag nostability nodynmult noadvanced nograph

*------------------------------------------------------------------------------
* 3.  Robust and HAC inference
*
*     vce() feeds the coefficient table, the three bounds statistics, the
*     asymmetry Wald tests, the multiplier confidence bands AND the bootstrap.
*     Reach for vce(hac) when panel B or C of the diagnostics flags serial
*     correlation or ARCH.
*------------------------------------------------------------------------------
aardl ln_inv ln_inc ln_consump, vce(robust) maxlag(4) ///
      nostability nodynmult noadvanced nograph
aardl ln_inv ln_inc ln_consump, vce(hac) maxlag(4) ///
      nostability nodynmult noadvanced nograph
display "Newey-West bandwidth used: " e(hlag)

* a bandwidth of your own
aardl ln_inv ln_inc ln_consump, vce(hac) lags(6) maxlag(4) ///
      nodiag nostability nodynmult noadvanced nograph

*------------------------------------------------------------------------------
* 4.  Bootstrap critical values
*
*     Both methods impose the null and generate the pseudo-data recursively.
*       bootstrap(bvz)     Bertelli, Vacca & Zoia (2022): a separate restricted
*                          equation per null hypothesis (their eqs. 16-18)
*       bootstrap(mcnown)  McNown, Sam & Goh (2018): one restricted equation,
*                          all lagged levels zero, serving all three tests
*
*     xdgp() controls the marginal process for x:
*       rw    (default) impose the unit root, x*(t) = x*(t-1) + Dx*(t) with
*                       Dx* a stationary VAR in differences
*       vecm            estimate the marginal VECM including the x levels,
*                       as printed in the two papers
*
*     See "Size properties" in the help file before choosing.
*------------------------------------------------------------------------------
aardl ln_inv ln_inc ln_consump, type(baardl) reps(999) maxlag(4) ///
      nodiag nostability nodynmult noadvanced nograph

aardl ln_inv ln_inc ln_consump, type(baardl) bootstrap(mcnown) reps(999) ///
      maxlag(4) nodiag nostability nodynmult noadvanced nograph

display "bootstrap p-values: F_ov " e(Fov_bp) "  t_DV " e(tDV_bp) "  F_ind " e(Find_bp)

*------------------------------------------------------------------------------
* 5.  Fourier terms: integer vs fractional frequencies
*
*     Yilanci, Bozoklu & Gorus (2020) search k over [0.1, ..., 5] by minimum
*     SSR.  Christopoulos & Leon-Ledesma (2011) and Omay (2015) show that
*     INTEGER k implies a TEMPORARY break and FRACTIONAL k a PERMANENT one.
*     aardl reports the best k on each grid and on the two combined, so the
*     implied break type is explicit; kmode() decides which one is used.
*------------------------------------------------------------------------------
* let the data pick
aardl ln_inv ln_inc ln_consump, type(faardl) maxk(5) kstep(0.1) ///
      nodiag nostability nodynmult noadvanced nograph
display "k* = " e(kstar) "   (" e(ktype) ", " e(breaktype) " break)"

* force a temporary-break reading
aardl ln_inv ln_inc ln_consump, type(faardl) kmode(integer) ///
      nodiag nostability nodynmult noadvanced nograph

* force a permanent-break reading
aardl ln_inv ln_inc ln_consump, type(faardl) kmode(fractional) ///
      nodiag nostability nodynmult noadvanced nograph

* Fourier plus bootstrap
aardl ln_inv ln_inc ln_consump, type(fbaardl) reps(999) maxlag(3) ///
      nodiag nostability nodynmult noadvanced nograph

*------------------------------------------------------------------------------
* 6.  Asymmetric (NARDL) models
*
*     decompose() splits a variable into its positive and negative partial
*     sums.  The multipliers are simulated from the full estimated ECM, and
*     the asymmetry M+(h) - M-(h) gets its own confidence band.
*------------------------------------------------------------------------------
aardl ln_inv ln_inc ln_consump, type(nardl) decompose(ln_inc) maxlag(3) ///
      horizon(36) bands(1000)

* the partial sums are kept, so you can inspect them
summarize ln_inc_pos ln_inc_neg

* bootstrap NARDL
aardl ln_inv ln_inc ln_consump, type(banardl) decompose(ln_inc) ///
      reps(999) maxlag(3) nodiag nostability noadvanced nograph

* Fourier bootstrap NARDL, everything switched on
aardl ln_inv ln_inc ln_consump, type(fbanardl) decompose(ln_inc) ///
      maxlag(3) reps(999) horizon(36)

*------------------------------------------------------------------------------
* 7.  Lag search
*
*     Every candidate is estimated on the SAME sample, the one implied by
*     maxlag(), so the information criteria are comparable.  search(full) tries
*     every combination; search(sequential) is the cheap alternative and is
*     picked automatically when the exhaustive grid exceeds 6000 models.
*------------------------------------------------------------------------------
aardl ln_inv ln_inc ln_consump, maxlag(4) search(full) ///
      nodiag nostability nodynmult noadvanced nograph
display "models estimated: " e(nmodels) "   strategy: " e(search)

aardl ln_inv ln_inc ln_consump, maxlag(4) search(sequential) ///
      nodiag nostability nodynmult noadvanced nograph
display "models estimated: " e(nmodels) "   strategy: " e(search)

*------------------------------------------------------------------------------
* 8.  Postestimation
*------------------------------------------------------------------------------
aardl ln_inv ln_inc ln_consump, maxlag(4) nograph

* e(sample) is correct, so the usual tools work
count if e(sample)

predict double dyhat                    // fitted D.depvar
predict double resid, residuals
predict double ecterm, ect              // the error-correction term
predict double lvl,   level             // fitted level of depvar
summarize dyhat resid ecterm lvl

* joint test on the long-run block
test [LR]

* a single long-run coefficient
lincom [LR]ln_inc

* re-run the advanced analysis over a longer horizon
aardl_advanced, horizon(48)

* the underlying regression is left stored, so estat still works by hand
estimates restore _aardl_ols
estat bgodfrey, lags(1 2 3 4)
estat archlm, lags(1)

*------------------------------------------------------------------------------
* 9.  Graphs
*
*     graphprefix() names every graph, which makes several models easy to keep
*     apart.  Graph names produced: <p>kstar <p>fit <p>resid <p>hist <p>qq
*     <p>ac <p>pac <p>ect <p>cusum <p>cusumsq <p>dm_# <p>asym_#
*     <p>persistence <p>bounds <p>bootFov <p>boottDV <p>bootFind <p>dash
*------------------------------------------------------------------------------
aardl ln_inv ln_inc ln_consump, type(fbanardl) decompose(ln_inc) ///
      maxlag(3) reps(499) graphprefix(m1_)

graph display m1_dash
graph display m1_cusum
graph display m1_cusumsq
graph display m1_asym_1
graph display m1_bootFov

* export the ones you want
* graph export "cusum.png",   name(m1_cusum)   replace width(2000)
* graph export "asym.png",    name(m1_asym_1)  replace width(2000)

*------------------------------------------------------------------------------
* 10. A fast exploratory run
*------------------------------------------------------------------------------
aardl ln_inv ln_inc ln_consump, maxlag(2) ///
      nodiag nostability nodynmult noadvanced nograph

*==============================================================================
* end of examples
*==============================================================================
