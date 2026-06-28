/*===========================================================================
 * example_malesky.do - Basic DID with Repeated Cross-Sectional Data
 *
 * Replication of Malesky et al. (2014) analysis using diddesign
 *
 * Data Description:
 *   Repeated cross-sectional data from Vietnam communes (2006, 2008, 2010).
 *   Treatment: Abolition of elected councils (implemented in 2009).
 *   Study examines the effect on local public services.
 *
 * Variables:
 *   - id_district: District identifier (string, needs encoding)
 *   - year: Year (2006, 2008, 2010)
 *   - treatment: Treated commune indicator (0/1)
 *   - pro4: Education and Cultural Program indicator [outcome]
 *   - tapwater: Tap water availability indicator [outcome]
 *   - agrext: Agricultural extension center indicator [outcome]
 *   - lnarea, lnpopden, city, reg8: Control variables
 *
 * Key Notes:
 *   - This is REPEATED CROSS-SECTIONAL data, NOT panel data
 *   - Use post() instead of id() for RCS data
 *   - post() identifies repeated cross-section data; explicit rcs is optional
 *   - Cluster standard errors at district level
 *
 * Reference:
 *   Malesky, Nguyen, and Tran (2014). "The Impact of Recentralization on
 *   Public Services: A Difference-in-Differences Analysis of the Abolition
 *   of Elected Councils in Vietnam." American Political Science Review.
 *===========================================================================*/

version 16
clear all
set more off
capture log close

local outdir "output"
capture mkdir "`outdir'"
log using "`outdir'/example_malesky.log", replace

/*---------------------------------------------------------------------------
 * Section 1: Data Loading and Exploration
 *---------------------------------------------------------------------------*/

di as txt _n _dup(70) "="
di as txt "SECTION 1: DATA LOADING AND EXPLORATION"
di as txt _dup(70) "=" _n

capture noisily sysuse malesky2014, clear
if _rc != 0 {
    display as error "Error: malesky2014.dta is not installed"
    display as error "Please run: net install diddesign, from(...)"
    exit _rc
}

// Basic data description
di as txt "Data Description:"
describe

// Summary statistics for key variables
di as txt _n "Summary Statistics for Key Variables:"
summarize pro4 tapwater agrext treatment year

// Check data structure - this is RCS data, not panel
di as txt _n "Data Structure (Repeated Cross-Section):"
di as txt "Note: Each year contains different observations, not a panel"
tabulate year treatment

// Check post-treatment indicator (treatment happened in 2009)
// Note: post_treat already exists in the dataset
di as txt _n "Post-Treatment Indicator:"
di as txt "Using existing post_treat variable (1 if year == 2010)"
tabulate year post_treat

// Encode district identifier for clustering
di as txt _n "Encoding District Identifier for Clustering..."
encode id_district, gen(id_cluster_num)
label variable id_cluster_num "Numeric district identifier"

// Create region fixed effects dummies
di as txt _n "Creating Region Fixed Effects Dummies..."
quietly tabulate reg8, gen(reg8_)

// Check covariate availability
di as txt _n "Covariate Summary:"
summarize lnarea lnpopden city reg8

/*---------------------------------------------------------------------------
 * Section 2: Parallel Trends Assessment
 *---------------------------------------------------------------------------*/

di as txt _n _dup(70) "="
di as txt "SECTION 2: PARALLEL TRENDS ASSESSMENT"
di as txt _dup(70) "=" _n

// Set random seed for reproducibility
set seed 1234

// Placebo test: lag=1 (comparing 2006-2008 pre-treatment trends)

// =====================================================
// Test 1: pro4 (Education and Cultural Program)
// =====================================================
di as txt _n "=== Testing pro4 (Education and Cultural Program) ==="
di as txt "Running parallel trends test (nboot=200 for speed)..."

diddesign_check pro4, ///
    treatment(treatment) time(year) ///
    post(post_treat) ///
    lag(1) ///
    cluster(id_cluster_num) ///
    nboot(200)

// Store results
matrix pro4_placebo = e(placebo)
local pro4_est = pro4_placebo[1,4]
local pro4_se = pro4_placebo[1,5]
local pro4_eqci_lb = pro4_placebo[1,6]
local pro4_eqci_ub = pro4_placebo[1,7]
local pro4_eqci_radius = max(abs(`pro4_eqci_lb'), abs(`pro4_eqci_ub'))

di as txt _n "pro4 Parallel Trends Test:"
di as txt "  Estimate(raw):   " %9.4f `pro4_est'
di as txt "  Std. Error(raw): " %9.4f `pro4_se'
di as txt "  EqCI95:          [" %9.4f `pro4_eqci_lb' ", " %9.4f `pro4_eqci_ub' "]"

// =====================================================
// Test 2: tapwater (Tap Water)
// =====================================================
di as txt _n "=== Testing tapwater (Tap Water) ==="
di as txt "Running parallel trends test..."

diddesign_check tapwater, ///
    treatment(treatment) time(year) ///
    post(post_treat) ///
    lag(1) ///
    cluster(id_cluster_num) ///
    nboot(200)

matrix tapwater_placebo = e(placebo)
local tapwater_est = tapwater_placebo[1,4]
local tapwater_se = tapwater_placebo[1,5]
local tapwater_eqci_lb = tapwater_placebo[1,6]
local tapwater_eqci_ub = tapwater_placebo[1,7]
local tapwater_eqci_radius = max(abs(`tapwater_eqci_lb'), abs(`tapwater_eqci_ub'))

di as txt _n "tapwater Parallel Trends Test:"
di as txt "  Estimate(raw):   " %9.4f `tapwater_est'
di as txt "  Std. Error(raw): " %9.4f `tapwater_se'
di as txt "  EqCI95:          [" %9.4f `tapwater_eqci_lb' ", " %9.4f `tapwater_eqci_ub' "]"

// =====================================================
// Test 3: agrext (Agricultural Center)
// =====================================================
di as txt _n "=== Testing agrext (Agricultural Center) ==="
di as txt "Running parallel trends test..."

diddesign_check agrext, ///
    treatment(treatment) time(year) ///
    post(post_treat) ///
    lag(1) ///
    cluster(id_cluster_num) ///
    nboot(200)

matrix agrext_placebo = e(placebo)
local agrext_est = agrext_placebo[1,4]
local agrext_se = agrext_placebo[1,5]
local agrext_eqci_lb = agrext_placebo[1,6]
local agrext_eqci_ub = agrext_placebo[1,7]
local agrext_eqci_radius = max(abs(`agrext_eqci_lb'), abs(`agrext_eqci_ub'))

di as txt _n "agrext Parallel Trends Test:"
di as txt "  Estimate(raw):   " %9.4f `agrext_est'
di as txt "  Std. Error(raw): " %9.4f `agrext_se'
di as txt "  EqCI95:          [" %9.4f `agrext_eqci_lb' ", " %9.4f `agrext_eqci_ub' "]"

// Summary Table
di as txt _n _dup(70) "-"
di as txt "PARALLEL TRENDS ASSESSMENT SUMMARY (raw Estimate/SE + EqCI95)"
di as txt _dup(70) "-"
di as txt "Variable     Estimate(raw) Std.Error(raw) EqCI95(rad) Conclusion"
di as txt _dup(70) "-"
di as txt "pro4        " %9.4f `pro4_est' "   " %9.4f `pro4_se' "   " %10.4f `pro4_eqci_radius' "   Inspect with plot"
di as txt "tapwater    " %9.4f `tapwater_est' "   " %9.4f `tapwater_se' "   " %10.4f `tapwater_eqci_radius' "   Inspect with plot"
di as txt "agrext      " %9.4f `agrext_est' "   " %9.4f `agrext_se' "   " %10.4f `agrext_eqci_radius' "   Inspect with plot"
di as txt _dup(70) "-"

/*---------------------------------------------------------------------------
 * Section 3: Basic DID Estimation (Without Covariates)
 *---------------------------------------------------------------------------*/

di as txt _n _dup(70) "="
di as txt "SECTION 3: BASIC DID ESTIMATION (NO COVARIATES)"
di as txt _dup(70) "=" _n

set seed 1234

// =====================================================
// Estimate 1: pro4
// =====================================================
di as txt "=== Estimating effect on pro4 (Education Program) ==="

diddesign pro4, ///
    treatment(treatment) time(year) ///
    post(post_treat) ///
    cluster(id_cluster_num) ///
    nboot(200)

// Store results - e(estimates) columns: [lead, estimate, std_error, ci_lo, ci_hi, weight]
// Row order: Double-DID (1), DID (2), sDID (3)
local pro4_ddid = e(estimates)[1,2]
local pro4_did = e(estimates)[2,2]
local pro4_sdid = e(estimates)[3,2]
local pro4_w_did = e(weights)[1,1]
local pro4_w_sdid = e(weights)[1,2]

di as txt _n "pro4 Estimation Results:"
di as txt "  Double-DID:  " %9.4f `pro4_ddid'
di as txt "  DID:         " %9.4f `pro4_did'
di as txt "  sDID:        " %9.4f `pro4_sdid'
di as txt "  Weights:     w_DID=" %5.3f `pro4_w_did' ", w_sDID=" %5.3f `pro4_w_sdid'

// =====================================================
// Estimate 2: tapwater
// =====================================================
di as txt _n "=== Estimating effect on tapwater (Tap Water) ==="

diddesign tapwater, ///
    treatment(treatment) time(year) ///
    post(post_treat) ///
    cluster(id_cluster_num) ///
    nboot(200)

local tapwater_ddid = e(estimates)[1,2]
local tapwater_did = e(estimates)[2,2]
local tapwater_sdid = e(estimates)[3,2]
local tapwater_w_did = e(weights)[1,1]
local tapwater_w_sdid = e(weights)[1,2]

di as txt _n "tapwater Estimation Results:"
di as txt "  Double-DID:  " %9.4f `tapwater_ddid'
di as txt "  DID:         " %9.4f `tapwater_did'
di as txt "  sDID:        " %9.4f `tapwater_sdid'
di as txt "  Weights:     w_DID=" %5.3f `tapwater_w_did' ", w_sDID=" %5.3f `tapwater_w_sdid'

// =====================================================
// Estimate 3: agrext
// =====================================================
di as txt _n "=== Estimating effect on agrext (Agricultural Center) ==="

diddesign agrext, ///
    treatment(treatment) time(year) ///
    post(post_treat) ///
    cluster(id_cluster_num) ///
    nboot(200)

local agrext_ddid = e(estimates)[1,2]
local agrext_did = e(estimates)[2,2]
local agrext_sdid = e(estimates)[3,2]
local agrext_w_did = e(weights)[1,1]
local agrext_w_sdid = e(weights)[1,2]

di as txt _n "agrext Estimation Results:"
di as txt "  Double-DID:  " %9.4f `agrext_ddid'
di as txt "  DID:         " %9.4f `agrext_did'
di as txt "  sDID:        " %9.4f `agrext_sdid'
di as txt "  Weights:     w_DID=" %5.3f `agrext_w_did' ", w_sDID=" %5.3f `agrext_w_sdid'

/*---------------------------------------------------------------------------
 * Section 4: Estimation with Covariates (Paper Replication)
 *---------------------------------------------------------------------------*/

di as txt _n _dup(70) "="
di as txt "SECTION 4: ESTIMATION WITH COVARIATES (PAPER REPLICATION)"
di as txt _dup(70) "=" _n

di as txt "Covariates: lnarea, lnpopden, city, reg8 (regional FE)"
di as txt "Clustering: id_district level"
di as txt "Bootstrap: 200 iterations (use 2000 for publication)"
di as txt _n _dup(50) "-"

set seed 1234

// =====================================================
// pro4 with covariates
// =====================================================
di as txt _n "=== pro4 with covariates ==="

diddesign pro4, ///
    treatment(treatment) time(year) ///
    post(post_treat) ///
    covariates("lnarea lnpopden city reg8_2 reg8_3 reg8_4 reg8_5 reg8_6 reg8_7") ///
    cluster(id_cluster_num) ///
    nboot(200)

local pro4_cov_ddid = e(estimates)[1,2]
local pro4_cov_se = e(estimates)[1,3]
local pro4_cov_ci_lo = e(estimates)[1,4]
local pro4_cov_ci_hi = e(estimates)[1,5]

di as txt "pro4 Results (with covariates):"
di as txt "  Double-DID:      " %9.4f `pro4_cov_ddid'
di as txt "  Std. Error:      " %9.4f `pro4_cov_se'
di as txt "  95% CI:          [" %7.4f `pro4_cov_ci_lo' ", " %7.4f `pro4_cov_ci_hi' "]"

// =====================================================
// tapwater with covariates
// =====================================================
di as txt _n "=== tapwater with covariates ==="

diddesign tapwater, ///
    treatment(treatment) time(year) ///
    post(post_treat) ///
    covariates("lnarea lnpopden city reg8_2 reg8_3 reg8_4 reg8_5 reg8_6 reg8_7") ///
    cluster(id_cluster_num) ///
    nboot(200)

local tapwater_cov_ddid = e(estimates)[1,2]
local tapwater_cov_did = e(estimates)[2,2]
local tapwater_cov_sdid = e(estimates)[3,2]
local tapwater_cov_se = e(estimates)[1,3]

di as txt "tapwater Results (with covariates):"
di as txt "  Double-DID:      " %9.4f `tapwater_cov_ddid'
di as txt "  DID:             " %9.4f `tapwater_cov_did'
di as txt "  sDID:            " %9.4f `tapwater_cov_sdid'
di as txt "  Note: tapwater has notable pre-trend; Double-DID applies the weaker-assumption correction"

// =====================================================
// agrext with covariates
// =====================================================
di as txt _n "=== agrext with covariates ==="

diddesign agrext, ///
    treatment(treatment) time(year) ///
    post(post_treat) ///
    covariates("lnarea lnpopden city reg8_2 reg8_3 reg8_4 reg8_5 reg8_6 reg8_7") ///
    cluster(id_cluster_num) ///
    nboot(200)

local agrext_cov_ddid = e(estimates)[1,2]
local agrext_cov_did = e(estimates)[2,2]
local agrext_cov_sdid = e(estimates)[3,2]

di as txt "agrext Results (with covariates):"
di as txt "  Double-DID:      " %9.4f `agrext_cov_ddid'
di as txt "  DID:             " %9.4f `agrext_cov_did'
di as txt "  sDID:            " %9.4f `agrext_cov_sdid'
di as txt "  Note: Neither EPT nor PTT holds; estimates may be biased"

/*---------------------------------------------------------------------------
 * Section 5: Visualization
 *---------------------------------------------------------------------------*/

di as txt _n _dup(70) "="
di as txt "SECTION 5: VISUALIZATION"
di as txt _dup(70) "=" _n

// Generate plots for each outcome

// pro4 - Trends plot
di as txt "Generating plots for pro4..."
set seed 1234
diddesign_check pro4, ///
    treatment(treatment) time(year) ///
    post(post_treat) lag(1) cluster(id_cluster_num) nboot(200)

diddesign_plot, type(trends) saving("`outdir'/malesky_pro4_trends.png") replace

// tapwater - Trends plot
di as txt "Generating plots for tapwater..."
set seed 1234
diddesign_check tapwater, ///
    treatment(treatment) time(year) ///
    post(post_treat) lag(1) cluster(id_cluster_num) nboot(200)

diddesign_plot, type(trends) saving("`outdir'/malesky_tapwater_trends.png") replace

// agrext - Trends plot
di as txt "Generating plots for agrext..."
set seed 1234
diddesign_check agrext, ///
    treatment(treatment) time(year) ///
    post(post_treat) lag(1) cluster(id_cluster_num) nboot(200)

diddesign_plot, type(trends) saving("`outdir'/malesky_agrext_trends.png") replace

di as txt _n "Plots saved: output/malesky_*_trends.png"

/*---------------------------------------------------------------------------
 * Section 6: Results Summary
 *---------------------------------------------------------------------------*/

di as txt _n _dup(70) "="
di as txt "SECTION 6: RESULTS SUMMARY"
di as txt _dup(70) "=" _n

di as txt "Parallel Trends Assessment (lag=1, raw scale):"
di as txt _dup(64) "-"
di as txt "Variable    Est(raw)   SE(raw)   EqCI95 LB   EqCI95 UB"
di as txt _dup(64) "-"
di as txt "pro4     " %9.4f `pro4_est' "  " %9.4f `pro4_se' "  " %9.4f `pro4_eqci_lb' "  " %9.4f `pro4_eqci_ub'
di as txt "tapwater " %9.4f `tapwater_est' "  " %9.4f `tapwater_se' "  " %9.4f `tapwater_eqci_lb' "  " %9.4f `tapwater_eqci_ub'
di as txt "agrext   " %9.4f `agrext_est' "  " %9.4f `agrext_se' "  " %9.4f `agrext_eqci_lb' "  " %9.4f `agrext_eqci_ub'
di as txt _dup(64) "-"

di as txt _n "Treatment Effects (lead=0, with covariates -- Double-DID):"
di as txt _dup(40) "-"
di as txt "pro4     " %9.4f `pro4_cov_ddid'
di as txt "tapwater " %9.4f `tapwater_cov_ddid'
di as txt "agrext   " %9.4f `agrext_cov_ddid'
di as txt _dup(40) "-"
di as txt _n "Paper reference (Table 2, Figure 4):"
di as txt "  pro4:     Double-DID = 0.082; EPT is plausible"
di as txt "  tapwater: Double-DID = -0.119; EPT is questionable (positive pre-trend)"
di as txt "  agrext:   pre-trends are inconsistent; causal estimate is not credible"

/*---------------------------------------------------------------------------
 * Section 7: Exporting Results
 *---------------------------------------------------------------------------*/

di as txt _n _dup(70) "="
di as txt "SECTION 7: EXPORTING RESULTS"
di as txt _dup(70) "=" _n

// Create summary matrix
matrix results_summary = J(3, 6, .)
matrix rownames results_summary = "pro4" "tapwater" "agrext"
matrix colnames results_summary = "PT_est" "PT_EqCI95" "DID" "sDID" "DoubleDID" "Preferred"

// Fill in results (using stored locals)
matrix results_summary[1,1] = `pro4_est'
matrix results_summary[1,2] = `pro4_eqci_radius'
matrix results_summary[1,3] = `pro4_did'
matrix results_summary[1,4] = `pro4_sdid'
matrix results_summary[1,5] = `pro4_ddid'
matrix results_summary[1,6] = `pro4_ddid'  // Preferred: DoubleDID

matrix results_summary[2,1] = `tapwater_est'
matrix results_summary[2,2] = `tapwater_eqci_radius'
matrix results_summary[2,3] = `tapwater_did'
matrix results_summary[2,4] = `tapwater_sdid'
matrix results_summary[2,5] = `tapwater_ddid'
matrix results_summary[2,6] = `tapwater_ddid'  // Preferred: Double-DID under weaker PTT-based logic

matrix results_summary[3,1] = `agrext_est'
matrix results_summary[3,2] = `agrext_eqci_radius'
matrix results_summary[3,3] = `agrext_did'
matrix results_summary[3,4] = `agrext_sdid'
matrix results_summary[3,5] = `agrext_ddid'
matrix results_summary[3,6] = .  // No credible estimate

di as txt "Results Summary Matrix:"
matrix list results_summary, format(%9.4f)

// LaTeX table output
di as txt _n "LaTeX-Ready Table (example output format):"
di as txt ""
di as txt "\begin{table}[htbp]"
di as txt "\centering"
di as txt "\caption{Parallel Trends Assessment and Treatment Effects}"
di as txt "\label{tab:malesky_results}"
di as txt "\begin{tabular}{lccccc}"
di as txt "\hline\hline"
di as txt "Outcome & PT Est. & EqCI95 radius & DID & sDID & Double-DID \\"
di as txt "\hline"
di as txt "Education Program & " %6.3f `pro4_est' " & " %5.3f `pro4_eqci_radius' " & " %6.3f `pro4_did' " & " %6.3f `pro4_sdid' " & " %6.3f `pro4_ddid' " \\"
di as txt "Tap Water & " %6.3f `tapwater_est' " & " %5.3f `tapwater_eqci_radius' " & " %6.3f `tapwater_did' " & " %6.3f `tapwater_sdid' " & " %6.3f `tapwater_ddid' " \\"
di as txt "Agricultural Center & " %6.3f `agrext_est' " & " %5.3f `agrext_eqci_radius' " & " %6.3f `agrext_did' " & " %6.3f `agrext_sdid' " & " %6.3f `agrext_ddid' " \\"
di as txt "\hline\hline"
di as txt "\multicolumn{6}{l}{\footnotesize Notes: Bootstrap standard errors clustered at district level.} \\"
di as txt "\end{tabular}"
di as txt "\end{table}"

// Export to CSV
preserve
clear
set obs 3
gen outcome = ""
gen pt_estimate = .
gen pt_eqci95_radius = .
gen did = .
gen sdid = .
gen double_did = .
gen preferred = ""

replace outcome = "pro4" in 1
replace pt_estimate = `pro4_est' in 1
replace pt_eqci95_radius = `pro4_eqci_radius' in 1
replace did = `pro4_did' in 1
replace sdid = `pro4_sdid' in 1
replace double_did = `pro4_ddid' in 1
replace preferred = "Double-DID" in 1

replace outcome = "tapwater" in 2
replace pt_estimate = `tapwater_est' in 2
replace pt_eqci95_radius = `tapwater_eqci_radius' in 2
replace did = `tapwater_did' in 2
replace sdid = `tapwater_sdid' in 2
replace double_did = `tapwater_ddid' in 2
replace preferred = "Double-DID" in 2

replace outcome = "agrext" in 3
replace pt_estimate = `agrext_est' in 3
replace pt_eqci95_radius = `agrext_eqci_radius' in 3
replace did = `agrext_did' in 3
replace sdid = `agrext_sdid' in 3
replace double_did = `agrext_ddid' in 3
replace preferred = "None" in 3

export delimited using "`outdir'/malesky_results.csv", replace
di as txt _n "Results exported to output/malesky_results.csv"
restore

/*---------------------------------------------------------------------------
 * Section 8: Comparison with Paper Values
 *---------------------------------------------------------------------------*/

di as txt _n _dup(70) "="
di as txt "SECTION 8: COMPARISON WITH PAPER VALUES"
di as txt _dup(70) "=" _n

di as txt "Expected values from Paper (Table 2 and Figure 4):"
di as txt ""
di as txt "Parallel Trends Test (lag=1):"
di as txt "  pro4:     Estimate=-0.007, SE=0.096"
di as txt "  tapwater: Estimate=0.166, SE=0.083"
di as txt "  agrext:   Estimate=0.198, SE=0.082"
di as txt ""
di as txt "Treatment Effects (lead=0):"
di as txt "  pro4:     DID=0.084, sDID=0.087, Double-DID=0.082"
di as txt "  tapwater: DID=-0.078, sDID=-0.119, Double-DID=-0.043"
di as txt "  agrext:   No credible estimator of the ATT without stronger assumptions"
di as txt ""
di as txt "Note: The paper values are reference targets from the article."
di as txt "      This walkthrough prints the public diddesign_check contract:"
di as txt "      raw placebo estimate/SE plus standardized EqCI95."

/*---------------------------------------------------------------------------
 * End of Example
 *---------------------------------------------------------------------------*/

di as txt _n _dup(70) "="
di as txt _n "MALESKY EXAMPLE COMPLETED SUCCESSFULLY"
di as txt _dup(70) "=" _n

log close
