*! version 1.2.0 2025-10-02
*! Bhattacharya et al.(2003) Information Opacity Measure
*! Authors: Wu Lianghai, Liu Rui, Jin Xuening
*! Anhui University of Technology (AHUT), Ma'anshan, China
*! E-mail: agd2010@yeah.net

program define opacity
    version 18.0
    syntax [, SAVEpath(string) LOGpath(string) REPLACE]
    
    * Check if asreg package is installed
    capture which asreg
    if _rc != 0 {
        display as error "The asreg package is required but not installed."
        display as error "Please install it using the following command:"
        display as error "ssc install asreg, replace"
        display as error "Then run the opacity command again."
        exit 111
    }
    
    * Check if opacity.xlsx file exists
    capture confirm file "opacity.xlsx"
    if _rc != 0 {
        display as error "File 'opacity.xlsx' not found in current directory."
        display as error "Please make sure the opacity.xlsx file is placed in the current working directory."
        display as error "The file should contain the following sheets:"
        display as error "  - Sheet1: Market return data"
        display as error "  - Sheet2: Firm characteristics data" 
        display as error "  - Sheet3: Accounting data"
        display as error "  - Sheet4: Industry classification data"
        exit 601
    }
    
    * Set default paths if not specified
    if "`savepath'" == "" {
        local savepath "."
    }
    if "`logpath'" == "" {
        local logpath "."
    }
    
    * Start log file
    capture log close
    log using "`logpath'/opacity.log", replace
    
    display "==============================================="
    display "Bhattacharya et al.(2003) Information Opacity Calculation"
    display "Authors: Wu Lianghai, Liu Rui, Jin Xuening"
    display "Anhui University of Technology (AHUT)"
    display "Start time: $S_TIME, $S_DATE"
    display "==============================================="
    
    * Data preparation and merging
    display "Step 1: Data preparation and merging..."
    
    * Import market return data (Sheet1)
    import excel "opacity.xlsx", sheet("Sheet1") firstrow clear
    destring year, replace
    order year mkt
    sort year mkt
    save "`savepath'/d1.dta", replace
    
    * Import firm characteristics data (Sheet2)
    import excel "opacity.xlsx", sheet("Sheet2") firstrow clear
    destring stkcd year, replace
    order year mkt
    sort year mkt
    save "`savepath'/d2.dta", replace
    
    * Merge with market returns
    use "`savepath'/d2.dta", clear
    merge m:1 year mkt using "`savepath'/d1.dta", keepusing(mkt_ret) nogen
    order stkcd year
    sort stkcd year
    save "`savepath'/d3.dta", replace
    
    * Import accounting data (Sheet3)
    import excel "opacity.xlsx", sheet("Sheet3") firstrow clear
    destring stkcd, replace
    gen year = real(substr(date,1,4))
    drop date
    order stkcd year
    sort stkcd year
    merge 1:1 stkcd year using "`savepath'/d3.dta", force keep(match) nogen
    replace cfo = cfo / at
    drop at
    keep if mkt == 1 | mkt == 4
    save "`savepath'/opacity_temp.dta", replace
    
    * Import industry classification data (Sheet4)
    import excel "opacity.xlsx", sheet("Sheet4") firstrow clear
    destring stkcd, replace
    gen year = real(substr(date,1,4))
    gen indcd = cond(substr(code,1,1)=="C", substr(code,1,2), substr(code,1,1))
    encode indcd, gen(industry)
    drop date code
    order stkcd year
    sort stkcd year
    merge 1:1 stkcd year using "`savepath'/opacity_temp.dta", force keep(match) nogen
    
    * Calculate opacity measures
    display "Step 2: Calculating opacity measures..."
    
    * Calculate absolute values by firm-year
    bysort stkcd year: egen abs_ni = mean(abs(roa))
    bysort stkcd year: egen abs_cfo = mean(abs(cfo))
    
    * Calculate volatility measures
    * (1) Earnings volatility (Earnings Synchronicity)
    bysort stkcd: egen sd_ni = sd(roa)
    gen earnsync = sd_ni / abs_ni
    
    * (2) Cash flow volatility (Cash Flow Synchronicity)
    bysort stkcd: egen sd_cfo = sd(cfo)
    gen cfsync = sd_cfo / abs_cfo
    
    * (3) Stock price synchronicity (Price Synchronicity)
    by stkcd: asreg ret mkt_ret, window(year -5 0)
    gen pricesync = 1 - _R2  // 1 - R² from market model
    
    * Calculate comprehensive opacity index
    gen opacity = (earnsync + cfsync + pricesync)/3
    
    * Label variables
    label var earnsync "Earnings volatility"
    label var cfsync "Cash flow volatility"
    label var pricesync "Stock price synchronicity"
    label var opacity "Information opacity index"
    
    * Clean missing values
    global var opacity earnsync cfsync pricesync
    foreach v in $var {
        drop if `v' >= .
    }
    
    * Generate output tables
    display "Step 3: Generating output tables..."
    
    * Descriptive statistics
    estpost summarize $var
    esttab using "`logpath'/descriptive_statistics.rtf", replace ///
        cells("mean(fmt(4)) sd(fmt(4)) min(fmt(4)) max(fmt(4))") ///
        title("Descriptive Statistics of Information Opacity Measures") ///
        label nogap compress
    
    * Yearly statistics
    preserve
    collapse (mean) mean_var=opacity (sd) sd_var=opacity, by(year)
    estpost tabstat mean_var sd_var, statistics(mean) by(year)
    esttab using "`logpath'/yearly_statistics.rtf", replace ///
        cells("mean_var sd_var") collabels("Mean" "SD") ///
        title("Yearly Descriptive Statistics") label
    restore
    
    * Industry statistics
    preserve
    collapse (mean) mean_var = opacity (sd) sd_var = opacity, by(industry)
    estpost tabstat mean_var sd_var, statistics(mean) by(industry)
    esttab using "`logpath'/industry_statistics.rtf", replace ///
        cells("mean_var(fmt(4)) sd_var(fmt(4))") collabels("Mean" "SD") ///
        title("Industry Comparison of Information Opacity") label 
    restore
    
    * Save final dataset
    if "`replace'" != "" {
        capture erase "`savepath'/opacity_final.dta"
    }
    label data "Bhattacharya et al.(2003) Information Opacity, Wu LiangHai et al., 2025-10-02"
    save "`savepath'/opacity_final.dta", replace
    
    * Clean up temporary files
    capture erase "`savepath'/d1.dta"
    capture erase "`savepath'/d2.dta"
    capture erase "`savepath'/d3.dta"
    capture erase "`savepath'/opacity_temp.dta"
    
    display "==============================================="
    display "Opacity calculation completed successfully!"
    display "Output files:"
    display "- opacity_final.dta (final dataset)"
    display "- descriptive_statistics.rtf"
    display "- yearly_statistics.rtf" 
    display "- industry_statistics.rtf"
    display "- opacity.log (log file)"
    display "End time: $S_TIME, $S_DATE"
    display "==============================================="
    
    log close
    
end