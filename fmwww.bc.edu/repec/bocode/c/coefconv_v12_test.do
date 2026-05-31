*! coefconv v1.2.0 — verification do-file
*! Run after placing coefconv.ado / coefconv_plot.ado on the adopath
*! (e.g. in PERSONAL or the current directory). Each block is annotated
*! with what to check.

clear all
set more off

*-----------------------------------------------------------------------
* 1. Cross-section, plain run  (should print v1.2.0 banner + all 8 families)
*-----------------------------------------------------------------------
sysuse auto, clear
regress price mpg weight foreign
coefconv

*-----------------------------------------------------------------------
* 2. Dominance / Shapley table
*    CHECK: a second table appears (Pratt vs General Dominance);
*           the Dominance % column is all >= 0 and sums to 100%;
*           the "raw" column sums to the reported OLS R2.
*-----------------------------------------------------------------------
regress price mpg weight foreign
coefconv, dominance

*-----------------------------------------------------------------------
* 3. Dominance + reference-relative plots
*    CHECK: graphs ccv_ref_mpg, ccv_ref_weight open; dominance table prints.
*    (foreign is a 0/1 var still confirmable as a variable, so it enters
*     the correlation matrix; that is expected.)
*-----------------------------------------------------------------------
regress price mpg weight foreign
coefconv, plot dominance
graph dir

*-----------------------------------------------------------------------
* 4. Companion summary graphs
*    CHECK: ccv_std (forest), ccv_pratt (importance), ccv_eff_<v> all open.
*-----------------------------------------------------------------------
regress price mpg weight foreign
coefconv_plot

*-----------------------------------------------------------------------
* 5. Squared term — negative Pratt %, dominance as non-negative check
*    CHECK: Pratt table flags a negative component for one mpg term;
*           dominance column for both mpg terms is >= 0.
*-----------------------------------------------------------------------
regress price c.mpg##c.mpg weight foreign
coefconv, dominance

*-----------------------------------------------------------------------
* 6. Stored results, no display
*    CHECK: r(dom_r2), r(dom_pct_mpg), r(pratt_pct_mpg) all return values.
*-----------------------------------------------------------------------
regress price mpg weight foreign
coefconv, dominance notable
display "OLS R2 (dominance denom): " r(dom_r2)
display "Pratt % weight:           " r(pratt_pct_weight)
display "Dominance % weight:       " r(dom_pct_weight)
display "Pratt % mpg:              " r(pratt_pct_mpg)
display "Dominance % mpg:          " r(dom_pct_mpg)

*-----------------------------------------------------------------------
* 7. Save wide dataset incl dominance columns
*    CHECK: file saves; dom_raw / dom_pct columns are present and populated.
*-----------------------------------------------------------------------
regress price mpg weight foreign
coefconv, dominance saving("coefconv_v12_out", replace) notable
preserve
    use "coefconv_v12_out", clear
    list varname pratt_pct dom_raw dom_pct, noobs
restore

*-----------------------------------------------------------------------
* 8. maxdom guard  (artificially low cap -> dominance should be skipped)
*    CHECK: message "Dominance skipped: ... exceed maxdom(1)".
*-----------------------------------------------------------------------
regress price mpg weight foreign
coefconv, dominance maxdom(1)

*-----------------------------------------------------------------------
* 9. Panel — Family 8 temporal metrics fully populated + dominance
*    CHECK: ref_period / ref_attrib non-missing; dominance table prints.
*-----------------------------------------------------------------------
webuse grunfeld, clear
xtset company year
xtreg invest mvalue kstock, fe
coefconv, plot dominance

*-----------------------------------------------------------------------
* 10. gybench on a cross-section (period denominator only)
*-----------------------------------------------------------------------
sysuse auto, clear
regress price mpg weight
coefconv, plot gybench(0.02)

display _n "coefconv v1.2.0 test script completed."
