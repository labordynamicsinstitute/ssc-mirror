/*******************************************************************************
    Example: Using the MHT Package
    Based on Viviano, Wuthrich, and Niehaus (2026)
    "A Model of Multiple Hypothesis Testing" -- arXiv:2104.13367v10

    This do-file demonstrates all five commands, ordered from most common
    workflow to most specialized:

        1. mht_est            - Postestimation: test J coefficients after a
                                regression (the typical workflow)
        2. mht_test           - Test a collection of p-values directly
        3. mht_table          - Reference table of optimal critical values
        4. mht_critical       - Compute a single optimal critical value
        5. mht_cost_estimate  - Estimate cost function parameters from
                                project-level cost data (simulated here)

    HOW TO RUN:
        After `ssc install mhtopt`, simply run this file:
            do mht_example.do
        From the source repository (uninstalled), run from the repo root:
            cd "path/to/mhtopt"
            do "stata/examples/mht_example.do"
*******************************************************************************/

clear all
set more off

* If running from the source repository (uninstalled), add the package folder to
* the ado-path. After `ssc install mhtopt` the commands are already on the path,
* so this block is a harmless no-op.
capture confirm file "`c(pwd)'/stata/mht_critical.ado"
if !_rc {
    adopath + "`c(pwd)'/stata"
}
else {
    capture confirm file "`c(pwd)'/../stata/mht_critical.ado"
    if !_rc adopath + "`c(pwd)'/../stata"
}


/*******************************************************************************
    PART 1: Postestimation -- The Typical Workflow (mht_est)

    The most common use case: you run a regression with multiple treatment
    arms (or multiple coefficients of interest), and you want to know which
    survive a properly calibrated MHT correction.

    mht_est reads directly from e(b) and e(V), so it works after any Stata
    estimation command (regress, logit, ivregress, areg, xtreg, etc.).
*******************************************************************************/

display _newline(2) as result "{hline 65}"
display as result "  PART 1: Postestimation -- The Typical Workflow (mht_est)"
display as result "{hline 65}"

// Load Stata's built-in auto dataset
sysuse auto, clear

// Run a regression with multiple regressors you want to test jointly
quietly regress price mpg weight foreign, robust

// Test all three coefficients with optimal MHT correction (Linear model)
display _newline as text "Testing mpg, weight, foreign jointly (Linear cost model, one-sided):"
mht_est, vars(mpg weight foreign) alphabar(0.05)

// Same regression, different cost model
display _newline as text "Same regression, Cobb-Douglas cost model:"
mht_est, vars(mpg weight foreign) alphabar(0.05) model(cobbdouglas)

// Access stored scalars for programmatic use
display _newline as text "Stored scalars (from the last call):"
display as text "  alpha_opt  = " as result %7.5f r(alpha_opt)
display as text "  alpha_bonf = " as result %7.5f r(alpha_bonf)
display as text "  n_reject (optimal) = " as result r(n_reject_opt)


/*******************************************************************************
    PART 2: Testing a Collection of P-values (mht_test)

    When you already have a list of p-values -- e.g., from separate
    regressions, a meta-analysis, or a paper you are reviewing -- you can
    pass them directly to mht_test without running any estimation command.

    The input is a Stata variable containing one-sided p-values (one per
    hypothesis). mht_test generates rejection indicators for all five
    procedures: Optimal, Bonferroni, Holm, BH, and unadjusted.
*******************************************************************************/

display _newline(2) as result "{hline 65}"
display as result "  PART 2: Testing a Collection of P-values (mht_test)"
display as result "{hline 65}"

// --- Example 2a: Basic usage with p-values ---
// Create a small dataset of 6 hypothetical one-sided p-values
quietly {
    clear
    set obs 6
    gen hypothesis = _n
    gen pval = .
    replace pval = 0.003 in 1
    replace pval = 0.015 in 2
    replace pval = 0.030 in 3
    replace pval = 0.048 in 4
    replace pval = 0.120 in 5
    replace pval = 0.500 in 6
    label variable hypothesis "Hypothesis number"
    label variable pval "One-sided p-value"
}

display _newline as text "Input: 6 one-sided p-values"
list hypothesis pval, noobs

// Apply MHT adjustment with Linear model (FDA default)
mht_test pval, alphabar(0.05)

display _newline as text "Side-by-side rejection decisions:"
list hypothesis pval mht_reject_opt mht_reject_bonf mht_reject_holm ///
     mht_reject_bh mht_reject_unadj, noobs

// --- Example 2b: Using z-statistics instead of p-values ---
quietly gen zstat = invnormal(1 - pval)
quietly label variable zstat "Z-statistic"

mht_test zstat, alphabar(0.05) zstat generate(z) replace

display _newline as text "Same results from z-statistics:"
list hypothesis zstat z_reject_opt z_reject_bonf z_reject_unadj, noobs

// --- Example 2c: Cobb-Douglas model with custom parameters ---
quietly drop mht_* z_*
mht_test pval, alphabar(0.05) model(cobbdouglas) beta(0.22) iota(0.136) replace
display _newline as text "Cobb-Douglas with custom parameters (beta=0.22, iota=0.136):"
list hypothesis pval mht_reject_opt mht_reject_bonf mht_reject_unadj, noobs


/*******************************************************************************
    PART 3: Reference Table of Critical Values (mht_table)

    mht_table displays a grid of optimal test sizes for different numbers
    of hypotheses (rows) and sample size ratios (columns). Useful for
    quick lookup and for reproducing Table 1 of the paper.
*******************************************************************************/

display _newline(2) as result "{hline 65}"
display as result "  PART 3: Reference Table (mht_table)"
display as result "{hline 65}"

// Linear model (reproduces Table 1 of the paper)
mht_table, alphabar(0.05) jrange(1 2 3 5 9) nmratios(0.5 1.0 2.0)

// Cobb-Douglas model
mht_table, alphabar(0.05) model(cobbdouglas) jrange(1 2 3 5 9) nmratios(0.5 1.0 2.0)


/*******************************************************************************
    PART 4: Computing a Single Optimal Critical Value (mht_critical)

    The building block behind mht_est and mht_test. Given the number of
    hypotheses and a cost model, it returns the optimal per-test alpha.
    Useful when you need the threshold itself rather than rejection decisions.
*******************************************************************************/

display _newline(2) as result "{hline 65}"
display as result "  PART 4: Computing Optimal Critical Values (mht_critical)"
display as result "{hline 65}"

// --- Example 4a: Linear calibration with default parameters ---
// 5 hypotheses, benchmark alpha = 0.05
mht_critical, jhypotheses(5) alphabar(0.05)

// Store results
local alpha_lin5 = r(alpha_opt)

// --- Example 4b: Cobb-Douglas calibration (J-PAL parameters) ---
mht_critical, jhypotheses(5) alphabar(0.05) model(cobbdouglas) beta(0.13) iota(0.075)
local alpha_cd5 = r(alpha_opt)

// --- Example 4c: Reproduce Table 1 from the paper (manual loop) ---
display _newline as text "Reproducing Table 1 (linear calibration, n_bar/m_bar = 1):"
display as text "{hline 50}"
display as text "  |J|    alpha_bar=0.025   0.05    0.10    0.15"
display as text "{hline 50}"

forvalues j = 1/9 {
    foreach ab in 0.025 0.05 0.10 0.15 {
        quietly mht_critical, jhypotheses(`j') alphabar(`ab')
        local tag = subinstr("`ab'", ".", "p", .)
        local a_`j'_`tag' = r(alpha_opt)
    }
    display as text "  " %2.0f `j' _col(12) ///
        as result %8.4f `a_`j'_0p025' ///
        _col(24) %8.4f `a_`j'_0p05' ///
        _col(34) %8.4f `a_`j'_0p10' ///
        _col(44) %8.4f `a_`j'_0p15'
}
display as text "{hline 50}"

// --- Example 4d: Varying sample size ratios ---
display _newline as text "Varying sample size (|J|=5, alpha_bar=0.025):"
foreach nm in 0.5 1.0 1.5 2.0 {
    quietly mht_critical, jhypotheses(5) alphabar(0.025) nmratio(`nm')
    display as text "  n/m = `nm': alpha_opt = " as result %8.5f r(alpha_opt)
}


/*******************************************************************************
    PART 5: Estimating Cost Function Parameters (mht_cost_estimate)

    When you have project-level data on research costs, number of treatment
    arms, and sample sizes, mht_cost_estimate recovers the cost function
    parameters (beta and iota for Cobb-Douglas, or cf_share for Linear).
    These can then be passed to mht_test or mht_est for study-specific
    calibration instead of relying on the default parameters.

    Below we simulate a dataset of 500 research projects with known cost
    structure, estimate the parameters, and show how to feed them back
    into the testing commands.
*******************************************************************************/

display _newline(2) as result "{hline 65}"
display as result "  PART 5: Estimating Cost Parameters (mht_cost_estimate)"
display as result "  Using simulated project-level cost data"
display as result "{hline 65}"

// --- Example 5a: Simulate project-level cost data ---
// True DGP: Cobb-Douglas with beta=0.2, iota=0.15
quietly {
    clear
    set seed 12345
    set obs 500

    gen arms = ceil(runiform() * 5)                   // 1-5 treatment arms
    gen sample_size = ceil(500 + runiform() * 4500)   // 500-5000 subjects
    gen project_type = ceil(runiform() * 3)            // 3 project types

    gen cost = exp(10 + 0.2*ln(arms) + 0.15*ln(sample_size) ///
               + 0.3*(project_type == 2) + 0.5*(project_type == 3) ///
               + rnormal(0, 0.4))

    label variable cost "Total project cost"
    label variable arms "Number of treatment arms"
    label variable sample_size "Total sample size"
    label variable project_type "Project type (1-3)"
}

// Estimate Cobb-Douglas cost function (no controls)
display _newline as text "--- Cobb-Douglas estimation (no controls) ---"
display as text "    True parameters: beta=0.20, iota=0.15"
mht_cost_estimate cost arms sample_size, alphabar(0.05) table robust

// With controls for project type
quietly {
    gen byte ptype2 = (project_type == 2)
    gen byte ptype3 = (project_type == 3)
}
display _newline as text "--- Cobb-Douglas estimation (with project-type controls) ---"
mht_cost_estimate cost arms sample_size, alphabar(0.05) ///
    controls(ptype2 ptype3) robust table

// --- Example 5b: Linear model estimation ---
display _newline as text "--- Linear model estimation ---"
mht_cost_estimate cost arms sample_size, alphabar(0.05) model(linear_share) robust table

// --- Example 5c: Feed estimated parameters back into mht_test ---
// First, get estimated beta and iota from the data
quietly mht_cost_estimate cost arms sample_size, alphabar(0.05) robust
local est_beta = e(beta)
local est_iota = e(iota)

display _newline as text "--- Using estimated parameters in mht_test ---"
display as text "    Estimated beta = " %5.3f `est_beta' ", iota = " %5.3f `est_iota'

// Create a small set of p-values to test with the estimated cost structure
quietly {
    clear
    set obs 4
    gen pval = .
    replace pval = 0.01 in 1
    replace pval = 0.03 in 2
    replace pval = 0.06 in 3
    replace pval = 0.15 in 4
}

mht_test pval, alphabar(0.05) model(cobbdouglas) ///
    beta(`est_beta') iota(`est_iota')

display _newline as text "Test results using study-specific cost parameters:"
list pval mht_reject_opt mht_reject_bonf mht_reject_unadj, noobs


display _newline(2) as result "{hline 65}"
display as result "  All examples completed successfully!"
display as result "{hline 65}"
