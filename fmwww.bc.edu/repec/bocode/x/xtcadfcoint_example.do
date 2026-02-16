/*
================================================================================
   xtcadfcoint — Example Do-File
   
   Banerjee & Carrion-i-Silvestre (2025, JBES)
   "Panel Data Cointegration Testing with Structural Instabilities"
   
   Translated from GAUSS PSY.gss empirical application
   
   Author: Dr Merwan Roudane <merwanroudane920@gmail.com>
   Date: 14 February 2026
================================================================================
*/

clear all
set more off
cap set matsize 11000

// ============================================================================
// PART 0: Build the PSY dataset (RHPI / RDIPC) from raw TXT files
// ============================================================================

/* 
   The data is from Banerjee & Carrion-i-Silvestre's empirical application.
   Y = log Real House Price Index (RHPI)
   X = log Real Disposable Income per capita (RDIPC)
   Panel: 51 US states, 1975-2019 (T=45, N=51)
*/

// --- Check if dataset already exists ---
capture confirm file "psy_rhpi_rdipc.dta"
if _rc != 0 {
    di as text ""
    di as text "  {bf:Building PSY dataset from raw files...}"
    di as text "  (Run xtcadfcoint_makedata.do first if this fails)"
    di as text ""
}

// Load the pre-built dataset or try to use it
capture use "psy_rhpi_rdipc.dta", clear

// If dataset doesn't exist, create a simulated dataset for demonstration
if _rc != 0 {
    di as text ""
    di as text "  {bf:PSY data file not found. Creating simulated demonstration data.}"
    di as text "  (Panel: 10 units, T=40)"
    di as text ""
    
    clear
    set obs 400
    
    // Create panel structure
    gen int unit = ceil(_n / 40)
    gen int year = 1980 + mod(_n - 1, 40)
    
    // Simulate cointegrated variables with a structural break
    set seed 12345
    gen double eps_y = rnormal(0, 1)
    gen double eps_x = rnormal(0, 1)
    gen double u_coint = rnormal(0, 0.3)
    
    // x follows a random walk
    bysort unit (year): gen double x = sum(eps_x) + unit * 2
    
    // y = beta*x + break_effect + stationary error (cointegrated)
    gen double break_dum = (year >= 2000)
    bysort unit (year): gen double y = 0.8 * x + 2 * break_dum + u_coint + unit * 1.5
    
    // Relabel
    rename unit state
    label variable y "Dependent variable (log RHPI equivalent)"
    label variable x "Independent variable (log RDIPC equivalent)"
    label variable state "Panel unit (state)"
    label variable year "Time period"
    
    xtset state year
    
    drop eps_y eps_x u_coint break_dum
    
    save "psy_demo_data.dta", replace
    di as text "  Saved: psy_demo_data.dta"
}

qui xtset
di as text ""
di as text "  Panel: `r(panelvar)', Time: `r(timevar)'"
qui xtdescribe
di as text ""


// ============================================================================
// PART 1: No Structural Breaks (Holly et al. 2010 specification)
// ============================================================================

di as text ""
di as text "  {hline 78}"
di as text "  {bf:PART 1: No Structural Breaks — Holly et al. (2010) Model}"
di as text "  {hline 78}"
di as text ""
di as text "  Model: Constant (model = 1)"
di as text "  Common factors: m = 2"
di as text "  CCE: Yes"
di as text "  Lag selection: Automatic (BIC), p_max = 5"
di as text ""

// Run the test
xtcadfcoint y x, model(1) breaks(0) nfactors(2) maxlags(5) lagselect(bic)

// Store results
local cips_nobreak = r(panel_cips)
matrix beta_nobreak = r(beta_ccep)


// ============================================================================
// PART 2: Structural Breaks (Endogenous, m = 2)
// ============================================================================

di as text ""
di as text "  {hline 78}"
di as text "  {bf:PART 2: Structural Breaks — Endogenous Estimation (m = 2)}"
di as text "  {hline 78}"
di as text ""
di as text "  Model: Constant with level shifts (model = 3)"
di as text "  Breaks: m = 2 (endogenous)"
di as text "  Break effects: slope + loadings"
di as text "  Common factors: m = 2"
di as text "  CCE: Yes"
di as text "  Lag selection: Automatic (BIC), p_max = 4"
di as text ""

xtcadfcoint y x, model(3) breaks(2) brkslope brkloadings nfactors(2) ///
    maxlags(4) lagselect(bic) trimming(0.20)

// Store results
local cips_break = r(panel_cips)
local cips_break_alt = r(panel_cips_alt)
matrix beta_break = r(beta_ccep)
matrix Tb_hat = r(Tb_hat)
matrix Tb_tilde = r(Tb_tilde)


// ============================================================================
// PART 3: One Structural Break
// ============================================================================

di as text ""
di as text "  {hline 78}"
di as text "  {bf:PART 3: Structural Breaks — Endogenous Estimation (m = 1)}"
di as text "  {hline 78}"
di as text ""

xtcadfcoint y x, model(3) breaks(1) brkslope brkloadings nfactors(2) ///
    maxlags(5) lagselect(bic) trimming(0.15)


// ============================================================================
// PART 4: Summary Comparison Table
// ============================================================================

di as text ""
di as text ""
di as text "  {hline 78}"
di as text "  {bf:╔══════════════════════════════════════════════════════════════════════════╗}"
di as text "  {bf:║     SUMMARY: Banerjee & Carrion-i-Silvestre (2025) Panel CADF Results   ║}"
di as text "  {bf:╚══════════════════════════════════════════════════════════════════════════╝}"
di as text "  {hline 78}"
di as text ""
di as text "  ┌─────────────────────────────────┬───────────────┬───────────────────────┐"
di as text "  │ Specification                   │ CIPS (λ_hat)  │ CIPS (λ_tilde)        │"
di as text "  ├─────────────────────────────────┼───────────────┼───────────────────────┤"
di as text "  │ No breaks (Model 1, Holly)      │" _col(40) %10.4f `cips_nobreak' _col(55) "│" _col(60) "    —" _col(76) "│"
di as text "  │ 1 break (Model 3, brk all)      │" _col(40) %10.4f r(panel_cips) _col(55) "│" _col(60) " " _col(76) "│"
di as text "  │ 2 breaks (Model 3, brk all)     │" _col(40) %10.4f `cips_break' _col(55) "│" _col(60) %10.4f `cips_break_alt' _col(76) "│"
di as text "  └─────────────────────────────────┴───────────────┴───────────────────────┘"
di as text ""
di as text "  {it:Note: Reject H0 (no cointegration) for sufficiently negative CIPS values.}"
di as text "  {it:Critical values: see Tables B.13-B.24 in Banerjee & Carrion-i-Silvestre (2025, JBES)}"
di as text ""
di as text "  {hline 78}"
di as text "  Author: Dr Merwan Roudane  <merwanroudane920@gmail.com>"
di as text "  Package: xtcadfcoint v1.0.0 — Banerjee & Carrion-i-Silvestre (2025)"
di as text "  {hline 78}"
di as text ""

// ============================================================================
// PART 5: No CCE (Robustness)
// ============================================================================

di as text ""
di as text "  {hline 78}"
di as text "  {bf:PART 5 (Robustness): Without CCE — Cross-section Independence}"
di as text "  {hline 78}"

xtcadfcoint y x, model(1) breaks(0) nocce maxlags(5) lagselect(bic)


// ============================================================================
// Done
// ============================================================================
di as text ""
di as text "  {bf:╔══════════════════════════════════════════════════════════════╗}"
di as text "  {bf:║  All tests completed successfully.                          ║}"
di as text "  {bf:║  Package: xtcadfcoint v1.0.0                                ║}"
di as text "  {bf:║  Author: Dr Merwan Roudane <merwanroudane920@gmail.com>      ║}"
di as text "  {bf:╚══════════════════════════════════════════════════════════════╝}"
