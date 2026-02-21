/* ============================================================================
   garchur_example.do — Example usage of the garchur Stata package
   
   Reference:
     Narayan, P.K. & Liu, R. (2015).
     A Unit Root Model for Trending Time-Series Energy Variables.
     Energy Economics. DOI: 10.1016/j.eneco.2014.11.021
   
   Implemented by: Dr. Merwan Roudane (merwanroudane920@gmail.com)
   Version: 1.0.0 | February 2026
   ============================================================================ */

clear all
set more off

/* --------------------------------------------------------------------------
   STEP 0: Add garchur to the ado-path
   -------------------------------------------------------------------------- */
local pkg_dir `"C:\Users\HP\Documents\xtpmg\garch unit root\garchur"'
adopath + `"`pkg_dir'"'

/* --------------------------------------------------------------------------
   STEP 1: Load example data — S&P 500 closing prices (built-in)
   -------------------------------------------------------------------------- */
sysuse sp500, clear
tsset date

di as txt _n "{hline 78}"
di as txt "{col 3}{bf:garchur — Example: S&P 500 Closing Price}"
di as txt "{col 3}Reference: Narayan & Liu (2015, Energy Economics)"
di as txt "{hline 78}"

/* --------------------------------------------------------------------------
   STEP 2: Pre-test with ADF (baseline comparison)
   -------------------------------------------------------------------------- */
di as txt _n "{col 3}{bf:ADF baseline test (for comparison):}"
qui dfuller close, trend lags(1)
di as txt "{col 3}ADF t-stat: " as res %8.4f r(t) ///
   as txt "  (5% CV: -3.42)"

/* --------------------------------------------------------------------------
   STEP 3: ARCH LM test for heteroskedasticity
   -------------------------------------------------------------------------- */
di as txt _n "{col 3}{bf:ARCH LM test for heteroskedasticity:}"
qui reg D.close L.D.close if !missing(close)
estat archlm, lags(1 2 4 8)

/* --------------------------------------------------------------------------
   STEP 4: Main test — model with constant + trend, 2 breaks (paper default)
   -------------------------------------------------------------------------- */
di as txt _n "{bf:Main test: Constant + Trend, 2 Breaks}"
garchur close, breaks(2) model(ct)

/* Store results */
local stat_ct2   = r(stat)
local cv5_ct2    = r(cv5)
local alpha_ct2  = r(alpha)
local beta_ct2   = r(beta)
local hl_ct2     = r(halflife)
local TB1_ct2    = r(TB1)
local TB2_ct2    = r(TB2)

/* --------------------------------------------------------------------------
   STEP 5: Robustness — constant only model
   -------------------------------------------------------------------------- */
di as txt _n "{bf:Robustness: Constant only, 2 Breaks}"
garchur close, breaks(2) model(c) noprint
local stat_c2 = r(stat)
local cv5_c2  = r(cv5)

/* --------------------------------------------------------------------------
   STEP 6: Summary comparison table (replicates paper Table VII style)
   -------------------------------------------------------------------------- */
di as txt _n
di as txt "{hline 78}"
di as txt "{col 5}{bf:Summary: garchur Test Results (Comparison Table)}"
di as txt "{col 5}{it:Variable: S&P 500 closing price}"
di as txt "{hline 78}"
di as txt "{col 5}Model{col 30}t-statistic{col 48}5% CV{col 62}Decision"
di as txt "{hline 78}"
di as txt "{col 5}CT + 2 breaks{col 30}" ///
   as res %10.4f `stat_ct2' as txt "  /  " as res %8.4f `cv5_ct2' ///
   as txt "{col 62}" as res cond(`stat_ct2'<`cv5_ct2', "Stationary*", "Unit root")
di as txt "{col 5}C  + 2 breaks{col 30}" ///
   as res %10.4f `stat_c2' as txt "  /  " as res %8.4f `cv5_c2' ///
   as txt "{col 62}" as res cond(`stat_c2'<`cv5_c2', "Stationary*", "Unit root")
di as txt "{hline 78}"
di as txt "{col 5}GARCH params (CT model): alpha=" as res %6.4f `alpha_ct2' ///
   as txt ", beta=" as res %6.4f `beta_ct2' ///
   as txt ", half-life=" as res %6.2f `hl_ct2' as txt " periods"
di as txt "{hline 78}"


/* --------------------------------------------------------------------------
   STEP 7: Visualisation (3-panel publication-quality graph)
   -------------------------------------------------------------------------- */
di as txt _n "{col 5}{bf:Generating 3-panel diagnostic graph...}"

/* Re-run with graph option */
garchur close, breaks(2) model(ct) noprint graph ///
    savegraph("`pkg_dir'\garchur_sp500_graph.png")

di as txt _n "{col 5}{bf:Graph saved to:} `pkg_dir'\garchur_sp500_graph.png"

/* --------------------------------------------------------------------------
   STEP 8: Simulated trending data (reproduce paper flavour)
   -------------------------------------------------------------------------- */
di as txt _n "{hline 78}"
di as txt "{col 5}{bf:Simulated energy-type data (trending + GARCH + breaks)}"
di as txt "{hline 78}"

clear
set obs 300
set seed 12345
gen t = _n
tsset t

* Simulate: trend + two structural breaks + GARCH errors
gen trend_comp = 0.1 * t
gen break_du1  = (t >= 100)
gen break_du2  = (t >= 200)

* GARCH(1,1) errors with a=0.10, b=0.85
gen eps = rnormal()
gen h   = .
gen e   = .
replace h = 0.5 in 1
replace e = eps * sqrt(h) in 1
forvalues i = 2/300 {
    qui replace h = 0.50 + 0.10*e[`i'-1]^2 + 0.85*h[`i'-1]  in `i'
    qui replace e = eps * sqrt(h) in `i'
}

* Generate price series: stationary around trend with breaks
gen y = 10 + trend_comp + 3*break_du1 + (-2)*break_du2 + e
label var y "Simulated energy price (stationary, GARCH, 2 breaks)"

di as txt "{col 5}Testing simulated stationary series (should reject H0):"
garchur y, breaks(2) model(ct) graph

/* --------------------------------------------------------------------------
   STEP 9: Clean up temporary variables
   -------------------------------------------------------------------------- */
capture drop _garchur_ht _garchur_sr

di as txt _n "{hline 78}"
di as txt "{col 5}{bf:garchur example completed successfully.}"
di as txt "{col 5}Cite: Narayan & Liu (2015). Energy Economics."
di as txt "{col 5}Package: Dr. Merwan Roudane (merwanroudane920@gmail.com)"
di as txt "{hline 78}"
