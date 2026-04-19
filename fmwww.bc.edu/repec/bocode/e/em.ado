*! em v1.0 18Apr2026
*! Modified Jones Model for Earnings Management Measurement
*! Authors: Wu Lianghai, Wu Hanyan, Liu Rui, Yang Lu
*! Email: agd2010@yeah.net

program define em
    version 18.0
    syntax [using/] [, Datafolder(string) Outputfolder(string) Replace]
    
    * Set default paths if not specified
    if "`using'" != "" {
        local rawdatafile "`using'"
    }
    else if "`datafolder'" != "" {
        local rawdatafile "`datafolder'/rawdata.xlsx"
    }
    else {
        local rawdatafile "rawdata.xlsx"
    }
    
    if "`outputfolder'" == "" {
        local outputfolder "`c(pwd)'"
    }
    
    * Check if data file exists
    capture confirm file `"`rawdatafile'"'
    if _rc != 0 {
        di as error "Data file does not exist: `rawdatafile'"
        exit 601
    }
    
    * Check if output folder exists, create if needed
    capture mkdir `"`outputfolder'"'
    
    * Set working directory to output folder (optional, but ensures logs/saves there)
    cd `"`outputfolder'"'
    
    * Close any open log and handle replacement
    capture log close
    capture confirm file "earnings_management_analysis.log"
    if _rc == 0 & "`replace'" != "" {
        rm "earnings_management_analysis.log"
    }
    
    * Create log file
    if "`replace'" != "" {
        log using "earnings_management_analysis.log", replace
    }
    else {
        capture log using "earnings_management_analysis.log", append
        if _rc != 0 {
            log using "earnings_management_analysis.log", replace
        }
    }
    
    di "=== Earnings Management Analysis using Modified Jones Model ==="
    di "Start time: $S_TIME, $S_DATE"
    di "Data file: `rawdatafile'"
    di "Output folder: `outputfolder'"
    
    * --------------------------------------------------------------
    * Load and process first dataset (Sheet1: industry, assets, income, revenue)
    * --------------------------------------------------------------
    di "Loading industry codes, total assets, net income, and revenue data..."
    import excel `"`rawdatafile'"', sheet("Sheet1") firstrow clear
    destring stkcd, replace
    gen year = real(substr(date,1,4))
    sort stkcd year
    xtset stkcd year
    order stkcd year
    drop date
    tempfile d1
    save `d1'
    
    * --------------------------------------------------------------
    * Load and process second dataset (Sheet2: cash flow from operations)
    * --------------------------------------------------------------
    di "Loading cash flow from operations data..."
    import excel `"`rawdatafile'"', sheet("Sheet2") firstrow clear
    destring stkcd, replace
    gen year = real(substr(date,1,4))
    sort stkcd year
    xtset stkcd year
    order stkcd year
    capture drop code   // drop any 'code' variable to avoid conflict with Sheet1
    drop date
    tempfile d2
    save `d2'
    
    * --------------------------------------------------------------
    * Load and process third dataset (Sheet3: receivables and fixed assets)
    * --------------------------------------------------------------
    di "Loading receivables and fixed assets data..."
    import excel `"`rawdatafile'"', sheet("Sheet3") firstrow clear
    destring stkcd, replace
    gen year = real(substr(date,1,4))
    sort stkcd year
    xtset stkcd year
    order stkcd year
    capture drop code
    drop date
    tempfile d3
    save `d3'
    
    * --------------------------------------------------------------
    * Load and process fourth dataset (Sheet4: fixed assets PPE)
    * --------------------------------------------------------------
    di "Loading fixed assets data..."
    import excel `"`rawdatafile'"', sheet("Sheet4") firstrow clear
    drop if type == "B"   // keep consolidated statements (A), drop parent company statements (B)
    destring stkcd, replace
    gen year = real(substr(date,1,4))
    sort stkcd year
    duplicates drop stkcd year, force
    xtset stkcd year
    order stkcd year
    drop date type
    tempfile fixed_assets
    save `fixed_assets'
    
    * --------------------------------------------------------------
    * Merge all datasets
    * --------------------------------------------------------------
    di "Merging datasets..."
    use `d1', clear
    merge 1:1 stkcd year using `d2', keep(match) nogenerate
    merge 1:1 stkcd year using `d3', keep(match) nogenerate
    merge 1:1 stkcd year using `fixed_assets', keep(match) nogenerate
    
    * --------------------------------------------------------------
    * Generate required variables
    * --------------------------------------------------------------
    * Lagged total assets
    by stkcd: gen lag_at = at[_n-1] if year == year[_n-1]+1
    
    * Total accruals
    gen ta = ni - cfo
    
    * Standardized variables
    gen ta_at = ta / lag_at
    gen inv_at = 1 / lag_at
    
    * Revenue change
    by stkcd: gen delta_rev = revenue - revenue[_n-1] if year == year[_n-1]+1
    gen delta_rev_at = delta_rev / lag_at
    
    * Receivables change
    by stkcd: gen delta_rec = rec - rec[_n-1] if year == year[_n-1]+1
    
    * Fixed assets ratio
    gen ppe_at = ppe / lag_at
    
    * Drop missing values
    drop if missing(ta_at, inv_at, delta_rev_at, ppe_at)
    
    * Industry code (first digit for non-C, first two digits for C)
    gen ind = cond(substr(code,1,1)=="C", substr(code,1,2), substr(code,1,1))
    encode ind, gen(indcd)
    
    * Year-industry grouping
    egen year_ind = group(year indcd), label
    
    * --------------------------------------------------------------
    * Estimate Modified Jones Model by year-industry groups
    * --------------------------------------------------------------
    di "Estimating Modified Jones Model coefficients by year-industry groups..."
    statsby _b _se e(r2) e(rmse) e(df_m) e(F) e(N), by(year_ind) saving(temp_coef, replace): ///
        reg ta_at inv_at delta_rev_at ppe_at, nocons
    
    * Merge coefficients back
    merge m:1 year_ind using temp_coef, nogenerate
    rename (_b_inv_at _b_delta_rev_at _b_ppe_at) (alpha0 alpha1 alpha2)
    
    * Calculate non-discretionary accruals (NDA)
    gen delta_rev_adj_at = (delta_rev - delta_rec) / lag_at
    gen nda_at = alpha0*inv_at + alpha1*delta_rev_adj_at + alpha2*ppe_at
    
    * Calculate discretionary accruals (DA)
    gen da_at = ta_at - nda_at
    
    * --------------------------------------------------------------
    * Label and save final dataset
    * --------------------------------------------------------------
    label data "Modified Jones Model (Dechow et al., 1995)"
    notes: Calculated using em.ado v1.0 on $S_DATE
    notes: Authors: Wu Lianghai (AHUT), Wu Hanyan (NUAA), Liu Rui (AHUT), Yang Lu (Rugao Finance Bureau)
    
    save `"`outputfolder'/em_results.dta"', replace
    
    * --------------------------------------------------------------
    * Export to Excel and show file path (no automatic opening)
    * --------------------------------------------------------------
    export excel using `"`outputfolder'/em_results.xlsx"', firstrow(variables) keepcellfmt replace

    * Display the full path with backslashes for Windows
    local excelfile_win `"`outputfolder'\em_results.xlsx"'
    di as text "Excel results file saved at:"
    di as text "    `excelfile_win'"
    di as text "Please open it manually (e.g., double-click in File Explorer)."
    
    * --------------------------------------------------------------
    * Generate descriptive statistics tables (optional)
    * --------------------------------------------------------------
    di "Generating descriptive statistics tables..."
    local vars ta_at inv_at delta_rev_at ppe_at delta_rec nda_at da_at
    foreach v in `vars' {
        drop if `v' >= .
    }
    
    estpost summarize `vars'
    esttab using `"`outputfolder'/descriptive_stats_variables.rtf"', ///
        cells("count mean sd min max") ///
        title("Descriptive Statistics: Model Variables") ///
        replace label
    
    estpost summarize ta_at nda_at da_at
    esttab using `"`outputfolder'/descriptive_stats_em.rtf"', ///
        cells("count mean sd min max") ///
        title("Descriptive Statistics: Earnings Management Measures") ///
        replace label
    
    * Example regression results for first year-industry group
    preserve
    keep if year_ind == 1
    reg ta_at inv_at delta_rev_at ppe_at, nocons
    esttab using `"`outputfolder'/jones_model_regression.rtf"', ///
        b(%9.4f) se(%9.4f) ///
        star(* 0.1 ** 0.05 *** 0.01) ///
        title("Modified Jones Model Regression Results (Year-Industry Group 1)") ///
        scalars("N Observations" "r2 R-squared" "F F-statistic") ///
        replace label
    restore
    
    di "Analysis completed successfully!"
    di "Results saved to: `outputfolder'/em_results.dta"
    di "Excel file: `outputfolder'/em_results.xlsx"
    di "Log file: `outputfolder'/earnings_management_analysis.log"
    di "End time: $S_TIME, $S_DATE"
    
    log close
end