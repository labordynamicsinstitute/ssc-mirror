********************************************************************************
* makicoint_example.do  (v2.0.0)
* Example usage of the makicoint package
* Maki (2012) Cointegration Test with Multiple Structural Breaks
*
* Author: Merwan Roudane  (merwanroudane920@gmail.com)
* GitHub: github.com/merwanroudane
********************************************************************************

clear all
set more off

********************************************************************************
* EXAMPLE 1: Basic Usage with Lutkepohl Dataset
********************************************************************************

di _newline(2) as txt "{hline 70}"
di as txt "EXAMPLE 1: Basic Test with Lutkepohl Data"
di as txt "{hline 70}"

* Load example data
webuse lutkepohl, clear

* Set time series
tsset qtr

* Display data structure
describe
summarize

* Basic test with 2 maximum breaks using regime shift model (default)
makicoint consumption investment income, maxbreaks(2)

* Store results
return list

********************************************************************************
* EXAMPLE 2: Different Model Specifications
********************************************************************************

di _newline(2) as txt "{hline 70}"
di as txt "EXAMPLE 2: Different Model Specifications"
di as txt "{hline 70}"

* Model 0: Level shift only
di _newline as txt "--- Model 0: Level Shift ---"
makicoint consumption investment, maxbreaks(2) model(0)

* Model 1: Level shift with trend
di _newline as txt "--- Model 1: Level Shift with Trend ---"
makicoint consumption investment, maxbreaks(2) model(1)

* Model 2: Regime shift (default)
di _newline as txt "--- Model 2: Regime Shift ---"
makicoint consumption investment, maxbreaks(2) model(2)

* Model 3: Regime shift with trend
di _newline as txt "--- Model 3: Regime Shift with Trend ---"
makicoint consumption investment, maxbreaks(2) model(3)

********************************************************************************
* EXAMPLE 3: Different Maximum Breaks
********************************************************************************

di _newline(2) as txt "{hline 70}"
di as txt "EXAMPLE 3: Different Maximum Breaks"
di as txt "{hline 70}"

* 1 break
di _newline as txt "--- 1 Maximum Break ---"
makicoint consumption investment, maxbreaks(1)

* 2 breaks
di _newline as txt "--- 2 Maximum Breaks ---"
makicoint consumption investment, maxbreaks(2)

* 3 breaks
di _newline as txt "--- 3 Maximum Breaks ---"
makicoint consumption investment, maxbreaks(3)

********************************************************************************
* EXAMPLE 4: Lag Selection Methods
********************************************************************************

di _newline(2) as txt "{hline 70}"
di as txt "EXAMPLE 4: Different Lag Selection Methods"
di as txt "{hline 70}"

* t-sig method (default)
di _newline as txt "--- t-sig Method ---"
makicoint consumption investment, maxbreaks(2) lagmethod(tsig) maxlags(8)

* AIC method
di _newline as txt "--- AIC Method ---"
makicoint consumption investment, maxbreaks(2) lagmethod(aic) maxlags(8)

* BIC method
di _newline as txt "--- BIC Method ---"
makicoint consumption investment, maxbreaks(2) lagmethod(bic) maxlags(8)

* Fixed lags
di _newline as txt "--- Fixed Lags ---"
makicoint consumption investment, maxbreaks(2) lagmethod(fixed) maxlags(4)

********************************************************************************
* EXAMPLE 5: Custom Trimming Parameter
********************************************************************************

di _newline(2) as txt "{hline 70}"
di as txt "EXAMPLE 5: Different Trimming Parameters"
di as txt "{hline 70}"

* Default trimming (10%)
di _newline as txt "--- 10% Trimming (Default) ---"
makicoint consumption investment, maxbreaks(2) trimming(0.10)

* 15% trimming
di _newline as txt "--- 15% Trimming ---"
makicoint consumption investment, maxbreaks(2) trimming(0.15)

********************************************************************************
* EXAMPLE 6: Using Stored Results
********************************************************************************

di _newline(2) as txt "{hline 70}"
di as txt "EXAMPLE 6: Using Stored Results"
di as txt "{hline 70}"

* Run test
makicoint consumption investment income, maxbreaks(3)

* Display stored results
di _newline as txt "Stored Results:"
di as txt "{hline 40}"
di as txt "Test statistic: " as res %9.4f r(test_stat)
di as txt "Critical values:"
di as txt "  1%:  " as res %9.3f r(cv1)
di as txt "  5%:  " as res %9.3f r(cv5)
di as txt "  10%: " as res %9.3f r(cv10)
di as txt "{hline 40}"
di as txt "Number of observations: " as res r(nobs)
di as txt "Maximum breaks allowed: " as res r(maxbreaks)
di as txt "Model: " as res "`r(model_name)'"
di as txt "Lags used: " as res r(lags)
di as txt "{hline 40}"
di as txt "Break points:"
di as txt "  Break 1 - Observation: " as res r(bp1) as txt " (fraction: " as res %6.4f r(bpfrac1) as txt ")"
di as txt "  Break 2 - Observation: " as res r(bp2) as txt " (fraction: " as res %6.4f r(bpfrac2) as txt ")"
di as txt "  Break 3 - Observation: " as res r(bp3) as txt " (fraction: " as res %6.4f r(bpfrac3) as txt ")"
di as txt "{hline 40}"

* Interpretation
if r(reject) == 1 {
    di as res "Conclusion: Reject null of no cointegration."
}
else {
    di as res "Conclusion: Fail to reject null of no cointegration."
}

********************************************************************************
* EXAMPLE 7: The break dashboard (graph)
********************************************************************************

di _newline(2) as txt "{hline 70}"
di as txt "EXAMPLE 7: Two-panel break dashboard"
di as txt "{hline 70}"

makicoint consumption investment income, maxbreaks(2) model(2) graph name(mkc_dash)
* export it:
* graph export mkc_dash.png, replace width(1600)

********************************************************************************
* EXAMPLE 8: Default GAUSS engine vs the Maki (2012) paper engine
********************************************************************************

di _newline(2) as txt "{hline 70}"
di as txt "EXAMPLE 8: Default engine vs the -paper- option"
di as txt "{hline 70}"

* Default reproduces the original GAUSS/tspdlib results exactly
makicoint consumption investment, maxbreaks(3) model(2)

* -paper- switches to the Maki (2012) paper method (may differ for 2+ breaks)
makicoint consumption investment, maxbreaks(3) model(2) paper

********************************************************************************
* EXAMPLE 9: More than five breaks with simulated critical values
*            (extension in this version: Maki Table 1 stops at 5 breaks)
********************************************************************************

di _newline(2) as txt "{hline 70}"
di as txt "EXAMPLE 9: Beyond Maki Table 1 (m>5) -- simulated CVs"
di as txt "{hline 70}"

* CVs for >5 breaks are not in Maki (2012); makicoint simulates them by the
* paper's own design. Use a few thousand reps for serious work; this small run
* is just illustrative. r(cvsource) reports table / simulated / none.
makicoint consumption investment, maxbreaks(6) model(2) simcv(200) simt(300) simseed(101)
di as txt "Critical-value source: " as res "`r(cvsource)'"

* A larger, more realistic run (slower) -- 7 breaks, 2000 reps:
* makicoint consumption investment, maxbreaks(7) model(2) simcv(2000) simt(500)

********************************************************************************
* EXAMPLE 10: Long-run regression at the estimated breaks
********************************************************************************

di _newline(2) as txt "{hline 70}"
di as txt "EXAMPLE 10: Cointegrating regression at the breaks"
di as txt "{hline 70}"

makicoint consumption investment income, maxbreaks(2) model(2) reg

********************************************************************************
* End of Examples
********************************************************************************

di _newline(2) as txt "{hline 70}"
di as txt "End of Examples"
di as txt "{hline 70}"
