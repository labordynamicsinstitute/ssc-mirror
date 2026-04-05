// ============================================================================
//  coefconv_examples.do
//  Worked examples for coefconv and coefconv_plot v1.0.0
//
//  Requirements: coefconv.ado and coefconv_plot.ado must be installed.
//  Run:  ssc install coefconv   OR place .ado files in your personal adopath.
// ============================================================================

clear all
set more off
version 14.0

// ============================================================================
// EXAMPLE 1 — Basic use (Stata's built-in auto dataset)
// ============================================================================
// Regress car price on fuel economy, weight, and origin.
// Then run coefconv to see all 26 effect types for each predictor.

sysuse auto, clear

regress price mpg weight foreign

coefconv

// Key results to notice:
//   Family 1  : weight has the largest standardized slope (beta*)
//   Family 2  : elasticity of weight at means
//   Family 5  : Pratt decomposition shows weight dominates R-squared
//   Family 7  : IQR effect for weight expressed in dollars

// ============================================================================
// EXAMPLE 2 — Changing the growth rate for Family 7
// ============================================================================
// Default growth rate is 1% of the mean of X (grate = 0.01).
// Use grate(0.05) to benchmark a 5% expansion instead.

sysuse auto, clear
regress price mpg weight foreign

coefconv, grate(0.05)

// ============================================================================
// EXAMPLE 3 — Adding extra quantiles for Family 6
// ============================================================================
// Default quantiles for the median-to-quantile displacement effects are
// 10, 25, 50, 75, 90. Add extreme tails with quantiles(5 95).

sysuse auto, clear
regress price mpg weight foreign

coefconv, quantiles(5 95)

// ============================================================================
// EXAMPLE 4 — Custom delta-X scenarios
// ============================================================================
// Supply specific ΔX values via delta(). Each value generates a separate
// "Custom ΔX" row in the Family 7 block for every predictor.

sysuse auto, clear
regress price mpg weight foreign

// Scenario: what happens if mpg increases by 5, or weight by 500 lb?
coefconv, delta(5 500)

// ============================================================================
// EXAMPLE 5 — Save wide results dataset
// ============================================================================
// Use saving() to export one row per predictor with all 26 effect columns.
// This is useful for tables, further analysis, or export to Excel.

sysuse auto, clear
regress price mpg weight foreign

coefconv, saving(coefconv_auto_results, replace)

// Inspect the saved dataset
use coefconv_auto_results, clear
list varname beta beta_fstd elasticity ysemi_elas pratt_pct, ///
     noobs sep(0) ab(20)

// ============================================================================
// EXAMPLE 6 — Programmatic access via r() scalars
// ============================================================================
// Run coefconv silently (notable) then read any scalar directly.

sysuse auto, clear
regress price mpg weight foreign

coefconv, notable

// Read individual effects
display "--- Key scalars for mpg ---"
display "Raw slope:           " %9.4f r(b_mpg)
display "Standardized slope:  " %9.4f r(bstd_mpg)
display "Elasticity at means: " %9.4f r(elas_mpg)
display "Y-semi-elasticity:   " %9.4f r(ysemi_mpg)
display "Pratt % of R-sq:     " %9.4f r(pratt_pct_mpg) "%"

display ""
display "--- Key scalars for weight ---"
display "Raw slope:           " %9.4f r(b_weight)
display "Standardized slope:  " %9.4f r(bstd_weight)
display "Pratt % of R-sq:     " %9.4f r(pratt_pct_weight) "%"

display ""
display "Model R-squared:     " %9.4f r(r2)
display "Pratt total (= R2):  " %9.4f r(pratt_tot)

// ============================================================================
// EXAMPLE 7 — Combine all options
// ============================================================================

sysuse auto, clear
regress price mpg weight foreign

coefconv, ///
    grate(0.02)              ///  2% growth benchmark
    quantiles(1 5 95 99)     ///  add extreme tails
    delta(100 500 1000)      ///  three custom delta-X scenarios
    saving(coefconv_full, replace) ///
    format(%10.4f)

// ============================================================================
// EXAMPLE 8 — After ivregress (instrumental variables)
// ============================================================================

sysuse auto, clear
ivregress 2sls price (mpg = gear_ratio) weight foreign

coefconv, grate(0.03)
// Note: SE-based CI for beta* (forest plot) reflects 2SLS standard errors.

// ============================================================================
// EXAMPLE 9 — After areg (absorbed fixed effects)
// ============================================================================

sysuse nlsw88, clear
areg wage age hours tenure, absorb(industry)

coefconv
coefconv_plot, noeffects       // summary graphs only for this model

// ============================================================================
// EXAMPLE 10 — VISUALIZATION: all three graphs
// ============================================================================

sysuse auto, clear
regress price mpg weight foreign

// Produces three named graphs simultaneously:
//   ccv_std         forest plot of standardized slopes
//   ccv_pratt       Pratt R-squared decomposition bar chart
//   ccv_eff_mpg     discrete effects ladder for mpg
//   ccv_eff_weight  discrete effects ladder for weight
//   ccv_eff_foreign discrete effects ladder for foreign

coefconv_plot

// ============================================================================
// EXAMPLE 11 — VISUALIZATION: selective graphs and options
// ============================================================================

sysuse auto, clear
regress price mpg weight foreign

// Forest plot only, 90% CI
coefconv_plot, nopratt noeffects level(90)

// Pratt chart + effects, with 5% growth rate
coefconv_plot, nostd grate(0.05)

// Save all graph files for a paper
coefconv_plot, saving(auto_paper_graphs, replace)

// Bring a specific graph to the front
graph display ccv_std
graph display ccv_eff_weight

// ============================================================================
// EXAMPLE 12 — Loop: collect elasticities across multiple models
// ============================================================================

sysuse auto, clear

// Fit three nested models and collect elasticities into a matrix
local models `" "mpg" "mpg weight" "mpg weight foreign" "'
local ncols : word count `models'

matrix ELAS = J(3, 3, .)
matrix rownames ELAS = mpg weight foreign
matrix colnames ELAS = Model1 Model2 Model3

local col = 0
foreach mvars of local models {
    local col = `col' + 1
    regress price `mvars'
    coefconv, notable

    local row = 0
    foreach v in mpg weight foreign {
        local row = `row' + 1
        capture {
            matrix ELAS[`row', `col'] = r(elas_`v')
        }
    }
}

matrix list ELAS, format(%8.4f)

// ============================================================================
// END OF EXAMPLES
// ============================================================================
