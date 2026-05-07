// ═══════════════════════════════════════════════════════════════════════════════
// example_realdata.do — xtpanelcoint with Jordà-Schularick-Taylor (JST) Data
// Author: Dr. Merwan Roudane
// Version: 1.1.0
// ═══════════════════════════════════════════════════════════════════════════════
// Replicates Table 4 of Chudik, Pesaran & Smith (2023) "Revisiting the Great
// Ratios Hypothesis" using the JST macrohistory database (17 countries, 1870-2016).
//
// Usage:
//   . do example_realdata.do
//
// Requirements:
//   . ssc install xtpanelcoint      (or adopath + "path/to/xtpanelcoint")
//   . xtpanelcoint_sample.dta must be in the working directory or ADOPATH
// ═══════════════════════════════════════════════════════════════════════════════

clear all
program drop _all
set more off

// ═══════════════════════════════════════════════════════════════════════════════
// STEP 1: Load bundled sample data
// ═══════════════════════════════════════════════════════════════════════════════

di as txt _n "{hline 78}"
di as txt "{bf:STEP 1: Load JST Macrohistory Database}"
di as txt "{hline 78}"

// Option A: Use the bundled sample dataset (shipped with xtpanelcoint)
use xtpanelcoint_sample, clear

// Option B: If you have the original JST Excel file, uncomment below:
// import excel "JSTdatasetR4.xlsx", sheet("Data") firstrow clear
// ... (see make_ssc_data.do for full preprocessing)

describe, short
xtset country_id year
xtdes

// ═══════════════════════════════════════════════════════════════════════════════
// STEP 2: Select largest balanced panel for each pair
//         (following the paper's sample selection procedure)
// ═══════════════════════════════════════════════════════════════════════════════

di as txt _n "{hline 78}"
di as txt "{bf:STEP 2: Great Ratio 1 — Consumption / GDP}"
di as txt "  Test H0: log(C/Y) = const  ⟺  θ_{CON-GDP} = 1"
di as txt "{hline 78}"

// ─── Keep balanced panel for consumption-GDP ─────────────────────────────────
preserve
keep if ln_con != . & ln_gdp != .

// Check balance
bysort country_id: gen _T = _N
sum _T
local T_min = r(min)
local T_max = r(max)
di as txt "  Min T = `T_min', Max T = `T_max'"

// Keep only countries with T = T_max (largest balanced panel)
keep if _T == `T_max'
drop _T

// Re-verify balance
xtset country_id year
xtdes

// ─── SPMG estimation ────────────────────────────────────────────────────────
di _n as txt "{bf:  SPMG:}"
xtpanelcoint spmg ln_con ln_gdp, lags(2)
estimates store con_spmg

// ─── SPMG with bootstrap ────────────────────────────────────────────────────
di _n as txt "{bf:  SPMG (bootstrap):}"
xtpanelcoint spmg ln_con ln_gdp, lags(2) bootstrap(500) seed(1234)
estimates store con_spmg_boot

// ─── Breitung ────────────────────────────────────────────────────────────────
di _n as txt "{bf:  Breitung:}"
xtpanelcoint breitung ln_con ln_gdp, lags(2)
estimates store con_breit

// ─── PDOLS ───────────────────────────────────────────────────────────────────
di _n as txt "{bf:  PDOLS(4):}"
xtpanelcoint pdols ln_con ln_gdp, leadslags(4)
estimates store con_pdols4

di _n as txt "{bf:  PDOLS(8):}"
xtpanelcoint pdols ln_con ln_gdp, leadslags(8)
estimates store con_pdols8

// ─── MGMW ────────────────────────────────────────────────────────────────────
di _n as txt "{bf:  MGMW (q=5):}"
xtpanelcoint mgmw ln_con ln_gdp, subperiods(5)
estimates store con_mgmw

// ─── Comparison table ────────────────────────────────────────────────────────
di _n as txt "  {bf:Summary — Consumption / GDP}"
di as txt "  {hline 65}"
di as txt "  {ralign 22:Estimator}{ralign 12:theta}{ralign 12:SE}" ///
          "{ralign 12:95% CI_lo}{ralign 12:95% CI_hi}"
di as txt "  {hline 65}"

foreach est in con_spmg con_breit con_pdols4 con_pdols8 con_mgmw {
    cap estimates restore `est'
    if !_rc {
        di as txt "  " as res %-22s "`e(estimator)'" ///
           as res %12.4f e(theta) ///
           as res %12.4f e(se) ///
           as res %12.4f e(ci95_lo) ///
           as res %12.4f e(ci95_hi)
    }
}
di as txt "  {hline 65}"

// ─── Comparison plot ─────────────────────────────────────────────────────────
cap noisily xtpanelcoint plot, type(compare) ///
    title("{bf:Consumption-GDP Long-Run Coefficient}") ///
    subtitle("JST Data, 17 Countries, 1870-2016")

restore

// ═══════════════════════════════════════════════════════════════════════════════
// STEP 3: Great Ratio 2 — Short Rate / Long Rate
// ═══════════════════════════════════════════════════════════════════════════════

di as txt _n "{hline 78}"
di as txt "{bf:STEP 3: Great Ratio 2 — Short Rate / Long Rate}"
di as txt "  Test H0: long - short spread stationary  ⟺  θ = 1"
di as txt "{hline 78}"

preserve
keep if short_r != . & long_r != .
bysort country_id: gen _T = _N
sum _T
keep if _T == r(max)
drop _T
xtset country_id year

di _n as txt "{bf:  SPMG:}"
xtpanelcoint spmg short_r long_r, lags(2) bootstrap(500) seed(42)
estimates store ir_spmg

di _n as txt "{bf:  Breitung:}"
xtpanelcoint breitung short_r long_r, lags(2)
estimates store ir_breit

di _n as txt "{bf:  PDOLS(4):}"
xtpanelcoint pdols short_r long_r, leadslags(4)
estimates store ir_pdols4

di _n as txt "{bf:  MGMW (q=5):}"
xtpanelcoint mgmw short_r long_r, subperiods(5)
estimates store ir_mgmw

// Summary
di _n as txt "  {bf:Summary — Short Rate / Long Rate}"
di as txt "  {hline 65}"
di as txt "  {ralign 22:Estimator}{ralign 12:theta}{ralign 12:SE}" ///
          "{ralign 12:95% CI_lo}{ralign 12:95% CI_hi}"
di as txt "  {hline 65}"

foreach est in ir_spmg ir_breit ir_pdols4 ir_mgmw {
    cap estimates restore `est'
    if !_rc {
        di as txt "  " as res %-22s "`e(estimator)'" ///
           as res %12.4f e(theta) ///
           as res %12.4f e(se) ///
           as res %12.4f e(ci95_lo) ///
           as res %12.4f e(ci95_hi)
    }
}
di as txt "  {hline 65}"

cap noisily xtpanelcoint plot, type(compare) ///
    title("{bf:Short-Long Interest Rate Spread}") ///
    subtitle("JST Data, Stationary Term Structure Test")

restore

// ═══════════════════════════════════════════════════════════════════════════════
// STEP 4: PME — Multiple Long-Run Relations (Consumption, GDP, Investment)
// ═══════════════════════════════════════════════════════════════════════════════

di as txt _n "{hline 78}"
di as txt "{bf:STEP 4: PME — Consumption, GDP, Investment}"
di as txt "  Estimate number of cointegrating relations among 3 variables"
di as txt "{hline 78}"

preserve
keep if ln_con != . & ln_gdp != . & ln_inv != .
bysort country_id: gen _T = _N
sum _T
keep if _T == r(max)
drop _T
xtset country_id year

xtpanelcoint pme ln_con ln_gdp ln_inv, subsamples(3) delta(0.25)
estimates store pme3

cap noisily xtpanelcoint plot, type(eigenvalue) ///
    title("{bf:PME Eigenvalue Analysis}") ///
    subtitle("Consumption, GDP, Investment — JST Data")

restore

// ═══════════════════════════════════════════════════════════════════════════════
// STEP 5: Full Summary
// ═══════════════════════════════════════════════════════════════════════════════

di as txt _n "{hline 78}"
di as txt "{bf:SUMMARY: Great Ratios Replication with xtpanelcoint}"
di as txt "{hline 78}"

di _n as txt "  Paper: Chudik, Pesaran & Smith (2023), Table 4"
di as txt "  Data:  JST Macrohistory Database, 17 countries, 1870-2016"
di as txt "  True value under H0: theta = 1.0"
di
di as txt "  {bf:Key findings:}"
di as txt "    • SPMG is the most robust estimator (handles two-way causality,"
di as txt "      non-cointegrating episodes, and cross-sectional dependence)"
di as txt "    • Bootstrap CIs should be preferred for inference"
di as txt "    • PDOLS tends to over-reject due to SE underestimation"
di as txt "    • PME correctly identifies the number of cointegrating relations"

di _n as res "{bf:Real-data example completed successfully!}"
