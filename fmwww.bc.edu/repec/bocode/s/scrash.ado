*! scrash.ado version 1.0 21sep2025
*! Authors: Wu Lianghai; Wu Hanyan; Ding Ming
*! Contact: agd2010@yeah.net, 2325476320@qq.com, dingming0417@163.com
program define scrash
    version 18.0
    set more off
    
    syntax [using/] [, SAVEpath(string) SHEETnames(string) MARKETvars(string) ///
        MINdays(integer 30) clear]
    
    // Set default save path if not specified
    if `"`savepath'"' == "" {
        local savepath `"`c(pwd)'"'
    }
    
    // Set default sheet names if not specified
    if `"`sheetnames'"' == "" {
        local sheetnames "Sheet1 Sheet2"
    }
    
    // Set default market variables if not specified
    if `"`marketvars'"' == "" {
        local marketvars "market mret"
    }
    
    // Clear memory if requested
    if "`clear'" != "" {
        clear all
    }
    
    // Create directory if it doesn't exist
    cap mkdir `"`savepath'"'
    cd `"`savepath'"'
    
    // Process individual stock returns
    tempfile master market_data
    local sheets : word count `sheetnames'
    local ind_sheets = `sheets' - 1

    if `ind_sheets' > 0 {
        local sheet : word 1 of `sheetnames'
        import excel `"`using'"', sheet("`sheet'") firstrow clear
        gen yq = qofd(date)
        format yq %tq
        save `master', replace
        
        if `ind_sheets' > 1 {
            forvalues i = 2/`ind_sheets' {
                local sheet : word `i' of `sheetnames'
                import excel `"`using'"', sheet("`sheet'") firstrow clear
                gen yq = qofd(date)
                format yq %tq
                append using `master'
                save `master', replace
            }
        }
        sort stkcd date
        save `master', replace
    }
    else {
        di as error "No individual stock sheets found"
        exit 198
    }
    
    // Process market returns
    local market_sheet : word `sheets' of `sheetnames'
    import excel `"`using'"', sheet("`market_sheet'") firstrow clear
    tokenize `marketvars'
    keep if `1' == 1
    gen date = date(date2, "YMD")
    format date %td
    save `market_data', replace
    
    // Merge datasets
    use `master', clear
    merge 1:1 date using `market_data', force
    drop _merge
    save quarterly_crash_dataset, replace
    
    // Prepare data
    use quarterly_crash_dataset, clear
    order stkcd date
    sort stkcd date
    xtset stkcd date
    
    // Generate lag and lead variables
    gen lag2_mret = L2.mret
    gen lag1_mret = L1.mret
    gen fd1_mret = F1.mret
    gen fd2_mret = F2.mret
    
    drop if dret == .
    bysort stkcd yq: egen n = count(yq)
    drop if n < `mindays'
    
    // Calculate residuals
    egen g = group(stkcd yq)
    sum g
    local max_g = r(max)
    gen e = .
    
    forvalues g = 1/`max_g' {
        qui reg dret lag2_mret lag1_mret mret ///
            fd1_mret fd2_mret if g == `g'
        predict rs if e(sample), residual
        replace e = rs if e(sample)
        drop rs
    }
    
    gen d = ln(1 + e)
    save scrashrisk, replace
    
    // Calculate NCSKEW
    use scrashrisk, clear
    bys stkcd yq: egen sum_d3 = sum(d^3)
    bys stkcd yq: egen sum_d2 = sum(d^2)
    gen NCSKEW = -[n*(n-1)^(3/2)*sum_d3]/[(n-1)*(n-2)*(sum_d2)^(3/2)]
    
    // Calculate DUVOL
    bysort stkcd yq: egen d_mean = mean(d)
    gen d_delt = d - d_mean
    gen up = (d_delt > 0) if !missing(d)
    gen down = (d_delt < 0) if !missing(d)
    
    bysort stkcd yq: egen n_up = sum(up)
    bysort stkcd yq: egen n_down = sum(down)
    
    gen d_down = d if down == 1
    gen d_up = d if up == 1
    
    bysort stkcd yq: egen sum_d_down2 = sum(d_down^2)
    bysort stkcd yq: egen sum_d_up2 = sum(d_up^2)
    
    gen DUVOL = ln([(n_up-1)*sum_d_down2]/[(n_down-1)*sum_d_up2])
    
    // Save final results
    duplicates drop stkcd yq, force
    keep stkcd yq NCSKEW DUVOL
    save quarterly_crash_risk, replace
    
    export excel quarterly_crash_risk.xlsx, ///
        sheet("scrash_risk") firstrow(variables) replace
    
    sum NCSKEW DUVOL
    tab yq
end