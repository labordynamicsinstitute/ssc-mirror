*! crash.ado version 1.2 13sep2025
*! Authors: Wu Lianghai; Wu Hanyan; Ding Ming
*! Contact: agd2010@yeah.net, 2325476320@qq.com, dingming0417@163.com
program define crash
    version 18.0
    set more off
    
    syntax [using/] [, SAVEpath(string) SHEETnames(string) MARKETvars(string) ///
        MINweeks(integer 30) clear]
    
    // Set default save path if not specified
    if "`savepath'" == "" {
        local savepath "`c(pwd)'"
    }
    
    // Set default sheet names if not specified
    if "`sheetnames'" == "" {
        local sheetnames "Sheet1 Sheet2 Sheet3 Sheet4 Sheet5"
    }
    
    // Set default market variables if not specified
    if "`marketvars'" == "" {
        local marketvars "market Wrettmv"
    }
    
    // Clear memory if requested
    if "`clear'" != "" {
        clear all
    }
    
    // Create directory if it doesn't exist
    cap mkdir "`savepath'"
    cd "`savepath'"
    
    // Merge individual stock return sheets
    tempfile master market_data
    local sheets : word count `sheetnames'
    local ind_sheets = `sheets' - 1  // Number of individual stock sheets

    // Process individual stock sheets
    if `ind_sheets' > 0 {
        // Import and save the first individual stock sheet
        local sheet : word 1 of `sheetnames'
        import excel "`using'", sheet("`sheet'") firstrow clear
        save `master', replace
        
        // Append additional sheets if there are more than one
        if `ind_sheets' > 1 {
            forvalues i = 2/`ind_sheets' {
                local sheet : word `i' of `sheetnames'
                import excel "`using'", sheet("`sheet'") firstrow clear
                append using `master'
                save `master', replace
            }
        }
        
        sort Stkcd date
        save `master', replace
    }
    else {
        di as error "No individual stock sheets found. Please check your sheetnames option."
        exit 198
    }
    
    // Import market return data
    local market_sheet : word `sheets' of `sheetnames'
    import excel "`using'", sheet("`market_sheet'") firstrow clear
    keep if market == 1 | market == 4
    save `market_data', replace
    
    // Merge individual and market returns
    use `master', clear
    merge m:m date using `market_data', force
    drop _merge
    save crash_dataset, replace
    
    // Data preparation
    use crash_dataset, clear
    
    // Remove duplicate observations by stock and date
    duplicates tag Stkcd date, gen(dup)
    drop if dup > 0
    drop dup
    
    destring date, gen(Date) ignore("-")
    destring Stkcd, gen(stkcd)
    order stkcd Date
    sort stkcd Date
    xtset stkcd Date
    
    // Generate lag and lead variables
    gen lag2_Wrettmv = L2.Wrettmv
    gen lag1_Wrettmv = L1.Wrettmv
    gen fwd1_Wrettmv = F1.Wrettmv
    gen fwd2_Wrettmv = F2.Wrettmv
    
    drop if Wkret == .
    gen year = real(substr(date, 1, 4))
    bysort stkcd year: egen n = count(year)
    drop if n < `minweeks'  // Drop samples with fewer than specified weeks
    
    // Calculate weekly holding returns
    egen g = group(stkcd year)
    sum g
    local max_g = r(max)
    gen e = .  // Store regression residuals
    
    forvalues g = 1/`max_g' {
        qui reg Wkret lag2_Wrettmv lag1_Wrettmv Wrettmv ///
            fwd1_Wrettmv fwd2_Wrettmv if g == `g'
        predict rs if e(sample), residual
        replace e = rs if e(sample)
        drop rs
    }
    
    gen w = ln(1 + e)
    save crashrisk, replace
    
    // Calculate negative coefficient of skewness (NCSKEW)
    use crashrisk, clear
    bys stkcd year: egen sum_w3 = sum(w^3)
    bys stkcd year: egen sum_w2 = sum(w^2)
    gen NCSKEW = -[n*(n-1)^(3/2)*sum_w3]/[(n-1)*(n-2)*(sum_w2)^(3/2)]
    
    // Calculate up-down volatility ratio (DUVOL)
    bysort stkcd year: egen w_mean = mean(w)
    gen w_delt = w - w_mean
    gen up = (w_delt > 0) if !missing(w)
    gen down = (w_delt < 0) if !missing(w)
    
    bysort stkcd year: egen n_up = sum(up)
    bysort stkcd year: egen n_down = sum(down)
    
    gen w_down = w if down == 1
    gen w_up = w if up == 1
    
    bysort stkcd year: egen sum_w_down2 = sum(w_down^2)
    bysort stkcd year: egen sum_w_up2 = sum(w_up^2)
    
    gen DUVOL = ln([(n_up-1)*sum_w_down2]/[(n_down-1)*sum_w_up2])
    
    // Save crash risk data
    duplicates drop stkcd year, force
    keep stkcd year NCSKEW DUVOL
    save stock_crash_risk, replace
    
    // Export to Excel
    export excel stock_crash_risk.xlsx, sheet("crash_risk") ///
        firstrow(variables) replace
    
    // Display summary statistics
    sum NCSKEW DUVOL
    tab year
end