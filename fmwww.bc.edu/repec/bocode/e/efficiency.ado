*! efficiency version 2.0.0 2025-10-03
*! Authors: Wu Lianghai, Wu Hanyan, Chen Liwen, Liu Changyun
*! Richardson (2006) investment efficiency measurement with single Excel file import

program define efficiency
    version 18.0
    syntax, FILEpath(string) [SHEETnum(integer 10) SAVEpath(string) REPLACE]
    
    preserve
    
    * 1. Import and merge Excel sheets
    tempfile master_data
    local first_run 1
    
    forvalues i = 1/`sheetnum' {
        capture {
            import excel "`filepath'", sheet("Sheet`i'") firstrow clear
                
            * Convert string variables to numeric if needed
            capture destring stkcd, replace
            capture destring year, replace
            
            * Extract year from date if date variable exists
            capture {
                gen year = real(substr(date,1,4)) if substr("`c(current_date)'",1,3) != ""
                drop date
            }
            
            * Ensure consistent structure
            order stkcd year
            sort stkcd year
            duplicates drop stkcd year, force
            
            if `first_run' {
                save `master_data', replace
                local first_run 0
            }
            else {
                merge 1:1 stkcd year using `master_data', nogen
                save `master_data', replace
            }
        }
        if _rc != 0 {
            di as error "Error importing Sheet`i' from `filepath'"
            exit _rc
        }
    }
    
    * 2. Generate lagged variables
    xtset stkcd year
    foreach var of varlist invest size lev cash age ret tobinq state salegrowth {
        capture confirm variable `var'
        if !_rc {
            bysort stkcd: gen L1_`var' = L.`var'
        }
    }
    
    * 3. Generate year and industry dummies
    tab year, gen(YearDum)
    
    * Create industry code from stock code (assuming Chinese stock codes)
    gen indcd = ""
    capture replace indcd = substr(code,1,2) if substr(code,1,1) == "C"
    capture replace indcd = substr(code,1,1) if indcd == "" & code != ""
    
    encode indcd, gen(industry)
    tab industry, gen(IndDum)
    
    * 4. Richardson (2006) model estimation
    xtreg invest L1.invest L1_size L1_lev L1_cash L1_age ///
        L1_ret L1_tobinq L1_salegrowth state YearDum* IndDum*, ///
        fe vce(cluster stkcd)
    
    * 5. Predict normal investment level
    predict Invest_Predicted, xb
    
    * 6. Calculate investment inefficiency
    gen Abs_InEff = abs(invest - Invest_Predicted)
    gen Over_Invest = (invest - Invest_Predicted) * (invest > Invest_Predicted)
    gen Under_Invest = (Invest_Predicted - invest) * (invest < Invest_Predicted)
    
    * 7. Label variables
    label var Invest_Predicted "Predicted normal investment level"
    label var Abs_InEff "Absolute investment inefficiency (Richardson, 2006)"
    label var Over_Invest "Over-investment (positive deviation)"
    label var Under_Invest "Under-investment (positive deviation)"
    
    * 8. Display summary statistics
    di as text _n "Summary Statistics for Investment Efficiency Measures:"
    di as text "{hline 60}"
    sum invest Invest_Predicted Abs_InEff Over_Invest Under_Invest
    
    * 9. Save results if requested
    if "`savepath'" != "" {
        save "`savepath'", `replace'
        di as text _n "Results saved to: `savepath'"
    }
    
    restore
end