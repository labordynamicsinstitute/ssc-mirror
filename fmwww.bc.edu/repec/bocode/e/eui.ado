*! eui v1.7 - Environmental Uncertainty Index Calculator
*! Authors: 
*!   Wu Lianghai, School of Business, Anhui University of Technology
*!   Wu Hanyan, School of Economics and Management, Nanjing University of Aeronautics and Astronautics  
*!   Chen Liwen, School of Business, Anhui University of Technology
*! Date: 30 Nov 2025

program define eui
    version 16.0
    syntax [using/], WINDow(integer) [MISsing(string) SAVing(string) REPLACE]
    
    * Display program start information
    di as text "Environmental Uncertainty Index (EUI) Calculator"
    di as text "Version 1.7 - 30 Nov 2025"
    di as text "Authors: Wu Lianghai, Wu Hanyan, Chen Liwen"
    di ""

    * Check window parameter
    if `window' < 3 | `window' > 5 {
        di as error "Window must be between 3 and 5 years"
        exit 198
    }
    
    * Set default missing value treatment method
    if "`missing'" == "" {
        local missing "drop"
    }
    
    * Import data
    if "`using'" != "" {
        import excel "`using'", firstrow clear
        di as text "Data imported from: `using'"
    }
    else {
        import excel "sales.xlsx", firstrow clear
        di as text "Data imported from: sales.xlsx"
    }
    
    * Data cleaning
    di as text "Step 1: Data cleaning..."
    
    * Check if required variables exist
    cap confirm variable stkcd date code revenue
    if _rc != 0 {
        di as error "Required variables (stkcd, date, code, revenue) not found"
        exit 111
    }
    
    * Ensure code is string type
    capture confirm string variable code
    if _rc != 0 {
        tostring code, replace
        di as text "Note: code variable converted to string type"
    }
    
    * Create numeric year variable from date variable
    di as text "Creating year variable from date..."
    capture confirm string variable date
    if _rc == 0 {
        * date is string type, extract year
        gen year = real(substr(date, 1, 4))
    }
    else {
        * date is numeric type, convert directly to year
        gen year = year(date)
    }
    
    * Check if year variable was successfully created
    count if missing(year)
    if r(N) > 0 {
        di as error "Failed to create year variable from date"
        exit 498
    }
    
    * Display year range in data
    sum year
    di as text "Data covers years from " r(min) " to " r(max)
    
    * Remove duplicate observations
    duplicates report stkcd year
    local dup_obs = r(unique_value)
    if `dup_obs' != _N {
        duplicates drop stkcd year, force
        di as text "Duplicates removed: " _N - `dup_obs' " observations"
    }
    
    * Handle missing values in code variable
    di as text "Handling missing industry codes..."
    
    * Sort by company and year to facilitate filling
    sort stkcd year
    
    * Identify missing industry codes
    gen missing_code = missing(code) | code == "" | code == "NA" | code == "N/A"
    
    count if missing_code == 1
    local miss_code = r(N)
    
    if `miss_code' > 0 {
        di as text "Found `miss_code' observations with missing industry codes"
        
        * Method 1: Use company's most recent non-missing code (forward fill)
        by stkcd: gen temp_code = code if !missing_code
        by stkcd: replace temp_code = temp_code[_n-1] if missing(temp_code) & _n > 1
        
        * Method 2: Use company's earliest non-missing code for remaining missing (backward fill)
        gsort stkcd -year
        by stkcd: replace temp_code = temp_code[_n-1] if missing(temp_code) & _n > 1
        
        * Method 3: Use company's mode for any remaining missing
        gsort stkcd year
        by stkcd: egen temp_code2 = mode(code) if !missing_code
        by stkcd: replace temp_code = temp_code2 if missing(temp_code)
        
        * Fill missing codes
        replace code = temp_code if missing_code
        
        * Count how many were successfully filled
        count if missing_code == 1 & !missing(code) & code != "" & code != "NA" & code != "N/A"
        local filled = r(N)
        
        * Remove temporary variables
        drop temp_code temp_code2 missing_code
        
        di as text "Successfully filled `filled' missing industry codes"
        
        * Count remaining missing codes after filling
        count if missing(code) | code == "" | code == "NA" | code == "N/A"
        local still_missing = r(N)
        
        if `still_missing' > 0 {
            di as text "Still have `still_missing' observations with missing industry codes after filling"
            di as text "These observations will be removed"
        }
    }
    
    * Handle missing values in revenue - FIXED VERSION
    count if missing(revenue)
    local miss_rev = r(N)
    
    if "`missing'" == "drop" & `miss_rev' > 0 {
        drop if missing(revenue)
        di as text "Missing revenue observations dropped: `miss_rev'"
    }
    else if "`missing'" == "ipolate" & `miss_rev' > 0 {
        di as text "Interpolating missing revenue values..."
        
        * Create numeric ID for each company since stkcd is string
        egen company_id = group(stkcd)
        
        * Set panel data structure
        tsset company_id year
        
        * Interpolate missing revenue values by company
        ipolate revenue year, gen(revenue_ip) by(company_id)
        
        * Replace missing revenue with interpolated values
        replace revenue = revenue_ip if missing(revenue)
        
        * Clean up temporary variables
        drop revenue_ip company_id
        
        di as text "Missing revenue values interpolated: `miss_rev'"
    }
    
    * Generate industry variable - based on string code variable
    di as text "Step 2: Generating industry variable..."
    
    * Clean spaces in code variable
    replace code = trim(code)
    
    * Remove any remaining observations with missing or invalid industry codes
    count if missing(code) | code == "" | code == "NA" | code == "N/A"
    if r(N) > 0 {
        di as text "Removing observations with missing or invalid industry codes: " r(N)
        drop if missing(code) | code == "" | code == "NA" | code == "N/A"
    }
    
    * Generate industry codes according to rules: if first character is "C" then take first 2 characters, otherwise take first character
    gen industry = ""
    replace industry = substr(code, 1, 2) if substr(code, 1, 1) == "C"
    replace industry = substr(code, 1, 1) if substr(code, 1, 1) != "C" & industry == ""
    
    * Handle missing values in industry variable using the same logic as code variable
    di as text "Handling missing industry classification..."
    
    count if missing(industry)
    local miss_industry = r(N)
    
    if `miss_industry' > 0 {
        di as text "Found `miss_industry' observations with missing industry classification"
        
        * Sort by company and year to facilitate filling
        sort stkcd year
        
        * Method 1: Use company's most recent non-missing industry (forward fill)
        by stkcd: gen temp_industry = industry if !missing(industry)
        by stkcd: replace temp_industry = temp_industry[_n-1] if missing(temp_industry) & _n > 1
        
        * Method 2: Use company's earliest non-missing industry for remaining missing (backward fill)
        gsort stkcd -year
        by stkcd: replace temp_industry = temp_industry[_n-1] if missing(temp_industry) & _n > 1
        
        * Method 3: Use company's mode for any remaining missing
        gsort stkcd year
        by stkcd: egen temp_industry2 = mode(industry) if !missing(industry)
        by stkcd: replace temp_industry = temp_industry2 if missing(temp_industry)
        
        * Fill missing industry
        replace industry = temp_industry if missing(industry)
        
        * Count how many were successfully filled
        count if missing(industry)
        local filled_industry = `miss_industry' - r(N)
        
        * Remove temporary variables
        drop temp_industry temp_industry2
        
        di as text "Successfully filled `filled_industry' missing industry classifications"
        
        * Count remaining missing industry after filling
        count if missing(industry)
        local still_missing_industry = r(N)
        
        if `still_missing_industry' > 0 {
            di as text "Still have `still_missing_industry' observations with missing industry classification after filling"
            di as text "These observations will be removed"
        }
    }
    
    * Remove unclassified industries
    count if industry == ""
    if r(N) > 0 {
        drop if industry == ""
        di as text "Unclassified industries removed: " r(N) " observations"
    }
    
    * Display industry classification results
    tab industry
    di as text "Industry classification completed"
    
    * Save the clean processed data with industry codes
    tempfile clean_data
    save "`clean_data'"
    
    * Calculate total sales by industry and year
    di as text "Step 3: Calculating total sales by industry and year..."
    
    preserve
        collapse (sum) total_revenue = revenue, by(industry year)
        
        * Sort by industry and year
        sort industry year
        
        * Display year range after collapse
        sum year
        di as text "After collapse: data covers years from " r(min) " to " r(max)
        
        * Calculate sales growth rate
        by industry: gen growth_rate = (total_revenue - total_revenue[_n-1]) / total_revenue[_n-1] if _n > 1
        
        * Calculate Environmental Uncertainty Index (EUI) - rolling standard deviation
        by industry: gen eui = .
        by industry: gen obs_num = _n
        
        levelsof industry, local(industries)
        foreach ind of local industries {
            di "Processing industry: `ind'"
            count if industry == "`ind'"
            local T = r(N)
            
            * Calculate EUI for all possible windows
            forvalues t = `window'/`T' {
                local start = `t' - `window' + 1
                local end = `t'
                qui: sum growth_rate if industry == "`ind'" & obs_num >= `start' & obs_num <= `end'
                replace eui = r(sd) if industry == "`ind'" & obs_num == `t'
            }
        }
        
        * Keep only industry, year, and eui for merging
        keep industry year eui
        drop if missing(eui)
        
        * Save EUI results
        tempfile eui_data
        save "`eui_data'"
    restore
    
    * Merge EUI data back to clean dataset
    di as text "Step 4: Merging EUI data..."
    use "`clean_data'", clear
    merge m:1 industry year using "`eui_data'", nogen
    
    * Display final year range with EUI values
    di as text "Years with EUI values:"
    tab year if !missing(eui)
    
    * Check for any remaining missing industry values
    count if missing(industry)
    if r(N) > 0 {
        di as text "Note: " r(N) " observations still have missing industry values"
    }
    
    * Descriptive statistics
    di as text "Step 5: Descriptive statistics..."
    di as text _n "Environmental Uncertainty Index (EUI) Descriptive Statistics"
    di as text "================================================================="
    sum eui, detail
    
    * EUI statistics by industry group
    di as text _n "EUI Statistics by Industry"
    di as text "================================================================="
    tabstat eui if !missing(eui), by(industry) stat(mean sd min max n)
    
    * Visualization
    di as text "Step 6: Generating visualizations..."
    
    * EUI distribution histogram
    histogram eui, frequency ///
        title("Distribution of Environmental Uncertainty Index") ///
        xtitle("EUI") ytitle("Frequency") ///
        name(eui_hist, replace)
    
    * EUI box plot by industry  
    graph box eui if !missing(eui), over(industry) ///
        title("EUI by Industry") ///
        ytitle("Environmental Uncertainty Index") ///
        name(eui_box, replace)
    
    * EUI trend over time by industry
    preserve
        collapse (mean) mean_eui = eui if !missing(eui), by(industry year)
        twoway line mean_eui year, by(industry) ///
            title("EUI Trend by Industry") ///
            xtitle("Year") ytitle("Mean EUI") ///
            name(eui_trend, replace)
    restore
    
    * Industry-year EUI heatmap
    preserve
        collapse (mean) mean_eui = eui if !missing(eui), by(industry year)
        
        * Create heatmap data table
        di as text _n "EUI Heatmap Data by Industry and Year"
        di as text "================================================================="
        list industry year mean_eui, noobs sepby(industry)
    restore
    
    * Save results
    if "`saving'" != "" {
        if "`replace'" != "" {
            save "`saving'", replace
        }
        else {
            save "`saving'"
        }
        di as text "Results saved to: `saving'"
    }
    
    * Display summary information
    di as text _n "EUI Calculation Completed Successfully!"
    di as text "================================================================="
    di as text "Total observations with EUI values: " _N
    quietly: tab industry if !missing(eui)
    di as text "Number of industries with EUI values: " r(r)
    quietly: tab year if !missing(eui)
    di as text "Number of years with EUI values: " r(r)
    di as text "Time window for standard deviation: `window' years"
    di as text "Missing value treatment: `missing'"
    di as text "Note: EUI values start from " `window' " years after the first year due to rolling window requirement"
    
end