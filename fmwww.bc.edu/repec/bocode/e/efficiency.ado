*! efficiency version 3.2.0 2026-03-24
*! Authors: Wu Lianghai, Wu Hanyan, Chen Liwen, Liu Changyun
*! Richardson (2006) investment efficiency with robust multi-sheet merge

program define efficiency
    version 18.0
    syntax, FILEpath(string) [SHEETnum(integer 10) SAVEpath(string) REPLACE]

    preserve

    * 1. Prepare master dataset (empty)
    tempfile master_data
    save `master_data', emptyok
    local first = 1

    * 2. Loop over sheets
    forvalues i = 1/`sheetnum' {
        di as text "Processing Sheet`i' ..."
        capture {
            import excel "`filepath'", sheet("Sheet`i'") firstrow clear
        }
        if _rc {
            di as error "  -> Cannot import Sheet`i' (skipped)"
            continue
        }

        * Ensure stkcd exists
        capture confirm variable stkcd
        if _rc {
            di as error "  -> Sheet`i' missing stkcd (skipped)"
            continue
        }

        * Get year variable
        capture confirm variable year
        if _rc {
            * No numeric year, try date
            capture confirm variable date
            if !_rc {
                * Convert date to Stata date if necessary
                capture confirm numeric variable date
                if _rc {
                    * date is string, convert to numeric date
                    capture gen double date_n = date(date, "YMD")
                    if _rc {
                        di as error "  -> Cannot parse date in Sheet`i' (skipped)"
                        continue
                    }
                    drop date
                    rename date_n date
                }
                * Generate year
                gen year = year(date)
                drop date
            }
            else {
                di as error "  -> Sheet`i' missing both year and date (skipped)"
                continue
            }
        }

        * Ensure year is numeric
        capture confirm numeric variable year
        if _rc {
            capture destring year, replace
            if _rc {
                di as error "  -> Year variable in Sheet`i' cannot be numeric (skipped)"
                continue
            }
        }

        * Convert stkcd to string for consistent merging
        capture confirm string variable stkcd
        if _rc {
            tostring stkcd, replace force
        }

        * Keep only necessary variables? We'll keep all except maybe drop date
        order stkcd year
        sort stkcd year
        duplicates drop stkcd year, force

        * Merge into master
        tempfile sheet`i'
        save `sheet`i'', replace

        use `master_data', clear
        if `first' {
            use `sheet`i'', clear
            save `master_data', replace
            local first = 0
        }
        else {
            merge 1:1 stkcd year using `sheet`i'', nogen
            save `master_data', replace
        }
    }

    * 3. Load final merged data
    use `master_data', clear

    * 4. Check required variables for Richardson model
    local required invest size lev cash age ret tobinq state salegrowth
    foreach var of local required {
        capture confirm variable `var'
        if _rc {
            di as error "Variable `var' not found in merged data"
            exit 111
        }
    }

    * 5. Ensure numeric types for required variables
    foreach var in invest size lev cash age ret tobinq salegrowth {
        capture confirm numeric variable `var'
        if _rc {
            capture destring `var', replace force
            if _rc {
                di as error "Cannot convert `var' to numeric; missing values will be generated"
            }
        }
    }

    * 5a. Special handling for state (allow Chinese text)
    capture confirm numeric variable state
    if _rc {
        * Try to convert common text to 0/1
        capture {
            destring state, replace force
        }
        if _rc {
            * If destring fails, assume it's textual: "国有" = 1, else 0
            gen byte state_num = 0
            replace state_num = 1 if inlist(state, "国有", "1", "yes", "Yes", "Y")
            drop state
            rename state_num state
        }
    }

    * 5b. Ensure year is numeric
    capture confirm numeric variable year
    if _rc {
        capture destring year, replace force
        if _rc {
            di as error "Year variable could not be converted to numeric; model may fail"
        }
    }

    * 6. Set panel and generate lagged variables
    * Create numeric firm id for clustering
    encode stkcd, gen(firm_id)
    xtset firm_id year

    foreach var of local required {
        bysort firm_id: gen L1_`var' = L.`var'
    }

    * 7. Generate year dummies
    tab year, gen(YearDum)

    * 8. Generate industry dummies
    * Try to use code or indcd variable
    capture confirm variable code
    if _rc {
        capture confirm variable indcd
        if _rc {
            di as error "No industry variable (code or indcd) found"
            exit 111
        }
        else {
            local indvar indcd
        }
    }
    else {
        local indvar code
    }

    * Create industry code based on Chinese stock codes (if not already encoded)
    capture confirm string variable `indvar'
    if _rc {
        tostring `indvar', replace force
    }
    gen indcd2 = ""
    capture replace indcd2 = substr(`indvar',1,2) if substr(`indvar',1,1)=="C"
    capture replace indcd2 = substr(`indvar',1,1) if indcd2=="" & `indvar'!=""
    encode indcd2, gen(industry)
    tab industry, gen(IndDum)

    * 9. Estimate Richardson model
    xtreg invest L1.invest L1_size L1_lev L1_cash L1_age L1_ret L1_tobinq state L1_salegrowth YearDum* IndDum*, ///
        fe vce(cluster firm_id)

    * 10. Predict normal investment and inefficiency
    predict Invest_Predicted, xb
    gen Abs_InEff = abs(invest - Invest_Predicted)
    gen Over_Invest = (invest - Invest_Predicted) * (invest > Invest_Predicted)
    gen Under_Invest = (Invest_Predicted - invest) * (invest < Invest_Predicted)

    label var Invest_Predicted "Predicted normal investment level"
    label var Abs_InEff      "Absolute investment inefficiency (Richardson, 2006)"
    label var Over_Invest    "Over-investment (positive deviation)"
    label var Under_Invest   "Under-investment (positive deviation)"

    * 11. Summary statistics
    di as text _n "Summary Statistics for Investment Efficiency Measures:"
    di as text "{hline 60}"
    sum invest Invest_Predicted Abs_InEff Over_Invest Under_Invest

    * 12. Save results if requested
    if "`savepath'" != "" {
    save "`savepath'", `replace'
    export excel "inefficiency.xlsx", sheet("inefficiency") first(var) replace keepcellfmt

    di as text "Results saved to: " _continue
    di as result "{browse inefficiency.xlsx:inefficiency.xlsx}"
}

    restore
end