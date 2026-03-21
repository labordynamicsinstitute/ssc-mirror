*! lrmbounds_example.do
*! Example do-file for the lrmbounds package
*! Demonstrates the full workflow from Webb, Linn & Lebo (2019, 2020)
*! Author: Dr. Merwan Roudane
*! Date: 20 March 2026

clear all
set more off

* ============================================================================
*  LRMBOUNDS: Bounds Approach to Inference Using the Long Run Multiplier
*  Based on:
*    Webb, Linn & Lebo (2019) "A Bounds Approach to Inference Using the
*    Long Run Multiplier" (Political Analysis, 27(3): 281-301)
*
*    Webb, Linn & Lebo (2020) "Beyond the Unit Root Question: Uncertainty 
*    and Inference in Time Series Models" (Journal of Politics)
* ============================================================================

di _n as res "{hline 72}"
di as res "  LRMBOUNDS: Example Do-File"
di as res "  Bounds Approach to Inference Using the Long Run Multiplier"
di as res "{hline 72}" _n

* ============================================================================
*  EXAMPLE 1: Lütkepohl (2005) Quarterly Data
*  Consumption as a function of Income and Investment
*  This is a classic time series dataset frequently used in textbooks
* ============================================================================
di as res "{bf:EXAMPLE 1: Lütkepohl (2005) — Consumption, Income & Investment}"
di as txt "{hline 72}" _n

* Load built-in data
webuse lutkepohl2, clear
tsset qtr

* Quick look at the data
di as txt "Data summary:"
summarize ln_consump ln_inc ln_inv

* --- Example 1a: Basic usage (Case III: constant only, automatic lag) ---
di _n as res "{bf:1a. Basic usage — automatic BIC lag selection, Case III}"
di as txt "{hline 60}" _n
lrmbounds ln_consump ln_inc ln_inv

* --- Example 1b: With time trend (Case V) ---
di _n as res "{bf:1b. With time trend — Case V}"
di as txt "{hline 60}" _n
lrmbounds ln_consump ln_inc ln_inv, trend

* --- Example 1c: With Bewley IV estimation ---
di _n as res "{bf:1c. With Bewley (1979) IV estimation for LRM SEs}"
di as txt "{hline 60}" _n
lrmbounds ln_consump ln_inc ln_inv, bewley

* --- Example 1d: ARDL lag specification ---
di _n as res "{bf:1d. ARDL(1,0,2) — per-variable lag orders}"
di as txt "{hline 60}" _n
di as txt "  ARDL(1,0,2) = 1 lag for y, 0 lags for ln_inc, 2 lags for ln_inv"
lrmbounds ln_consump ln_inc ln_inv, ardl(1 0 2)

* --- Example 1d2: Uniform lag order ---
di _n as res "{bf:1d2. Uniform lag order (p=2 for all)}"
di as txt "{hline 60}" _n
lrmbounds ln_consump ln_inc ln_inv, lags(2)

* --- Example 1e: AIC lag selection with larger search space ---
di _n as res "{bf:1e. AIC lag selection, maxlag=8}"
di as txt "{hline 60}" _n
lrmbounds ln_consump ln_inc ln_inv, maxlag(8) lagsel(aic)

* --- Example 1f: Robust standard errors ---
di _n as res "{bf:1f. Heteroskedasticity-robust standard errors}"
di as txt "{hline 60}" _n
lrmbounds ln_consump ln_inc ln_inv, robust

* --- Example 1g: Full analysis with graphs ---
di _n as res "{bf:1g. Full analysis with visualizations}"
di as txt "{hline 60}" _n
lrmbounds ln_consump ln_inc ln_inv, bewley graph graphdir("lrmbounds_ex1")

* --- Example 1h: Access stored results ---
di _n as res "{bf:1h. Stored results}"
di as txt "{hline 60}" _n
lrmbounds ln_consump ln_inc ln_inv, bewley
return list

di as txt "  PSS F-statistic:       " as res %8.3f r(F_pss)
di as txt "  Error correction rate: " as res %8.5f r(ecr)
di as txt "  5% F-bounds:           " as res "[" %5.3f r(f_lb_5) ", " %5.3f r(f_ub_5) "]"
di as txt "  5% Webb LRM bounds:    " as res "[" %5.3f r(cv_lb_5) ", " %5.3f r(cv_ub_5) "]"
di as txt "  F-test decision:       " as res "`r(f_decision)'"
di as txt "  Equilibrium type:      " as res "`r(equil_type)'"

* ============================================================================
*  EXAMPLE 2: Bivariate Case (Single Regressor)
*  Simpler model to demonstrate k=1 case
* ============================================================================
di _n(3) as res "{bf:EXAMPLE 2: Bivariate Case — Consumption on Income Only}"
di as txt "{hline 72}" _n

webuse lutkepohl2, clear
tsset qtr

lrmbounds ln_consump ln_inc, bewley trend graph graphdir("lrmbounds_ex2")

* ============================================================================
*  EXAMPLE 3: Understanding the Output
*  Step-by-step guide to reading lrmbounds results
* ============================================================================
di _n(3) as res "{bf:EXAMPLE 3: Step-by-Step Interpretation Guide}"
di as txt "{hline 72}" _n

webuse lutkepohl2, clear
tsset qtr

lrmbounds ln_consump ln_inc ln_inv

di _n as txt "  HOW TO READ THE OUTPUT:"
di as txt "  ========================"
di as txt ""
di as txt "  1. Table 1 shows the full ECM coefficients."
di as txt "     - L.ln_consump = error correction rate (psi_yy)"
di as txt "     - L.ln_inc, L.ln_inv = level effects (psi_yx)"
di as txt "     - D.ln_inc, D.ln_inv = short-run effects"
di as txt ""
di as txt "  2. Table 2 tests for the EXISTENCE of a level relationship."
di as txt "     - Panel A: F-test on all lagged levels jointly"
di as txt "     - Panel B: t-test on the error correction rate alone"
di as txt "     - If F > Upper Bound: relationship exists"
di as txt ""
di as txt "  3. Table 3 classifies the equilibrium type."
di as txt "     - 'Nondegenerate' = valid relationship (both psi_yy and psi_yx ≠ 0)"
di as txt "     - 'Degenerate' = spurious or trivial relationship"
di as txt ""
di as txt "  4. Table 4 tests INDIVIDUAL long-run effects (Webb innovation)."
di as txt "     - For each x: does x have a long-run effect on y?"
di as txt "     - Uses Webb bounds that are valid under I(0) OR I(1)"
di as txt "     - 'Signif.' = confident in LRR regardless of integration order"
di as txt "     - 'Incon.' = depends on unknown integration order"
di as txt ""
di as txt "  5. Table 5 checks model specification."
di as txt "     - No serial correlation, homoskedasticity, normality, no misspec."

* ============================================================================
*  EXAMPLE 4: Comparing Standard vs. Bounds Inference
*  Demonstrates why bounds matter (Webb et al. 2020 motivation)
* ============================================================================
di _n(3) as res "{bf:EXAMPLE 4: Why Bounds Matter — Standard vs. Bounds Inference}"
di as txt "{hline 72}" _n

webuse lutkepohl2, clear
tsset qtr

qui lrmbounds ln_consump ln_inc ln_inv
local n = r(N)
local k = r(k)

di as txt "  With T=`n' observations and k=`k' regressors:"
di as txt ""

forvalues j = 1/`k' {
    local xv = r(xvar_`j')
    local lrm = r(lrm_`j')
    local t = abs(r(lrm_t_`j'))
    local p = 2 * ttail(`n' - 10, `t')
    local d = r(lrm_dcode_`j')
    
    di as txt "  `xv':"
    di as txt "    LRM = `: display %8.4f `lrm''"
    di as txt "    |t| = `: display %6.3f `t''"
    di as txt "    Standard inference (normal c.v. = 1.96):  " _continue
    if `t' > 1.96 di as res "Significant"
    else di as txt "Not significant"
    di as txt "    Webb bounds inference:                    " _continue
    if "`d'" == "reject" di as res "Significant (above upper bound)"
    else if "`d'" == "fail" di as txt "Not significant (below lower bound)"
    else di as res "INCONCLUSIVE (between bounds)"
    di ""
}

di as txt "  => Standard inference may OVER-REJECT when variables are I(1)."
di as txt "     Webb bounds honestly reflect this uncertainty."

di _n as res "{hline 72}"
di as res "  End of examples. For help, type: {stata help lrmbounds}"
di as res "{hline 72}"
