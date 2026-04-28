*! version 4.4  2026-04-25
*! Author: Anne Fengyan Shi, Pew Research Center (ashi@pewresearch.org)
program define medage, rclass byable(recall)
    version 14.0
    syntax varname [if] [in], ageid(varname) [saving(string) replace by(varlist)]
    
    local pop `varlist'

    // --- BATCH MODE (Save to File) ---
    if "`saving'" != "" {
        if "`by'" == "" {
            display as error "Option by() is required when using saving()"
            exit 198
        }
        
        quietly {
            preserve
            marksample touse
            keep if `touse'
            
            // NEW STRICT CHECK: Compare total rows to expected rows
            // If every group is clean, N should equal (Number of Groups * Number of ageids)
            tempvar obs_per_group
            bysort `by' `ageid': gen byte `obs_per_group' = _n
            count if `obs_per_group' > 1
            if r(N) > 0 {
                local dups = r(N)
                restore
                display as error "Error: `dups' duplicate ageid entries found within your by() groups."
                display as error "Current level: `by'"
                display as error "You must collapse population to this level before running medage."
                exit 459
            }
            
            keep `pop' `ageid' `by'
            sort `by' `ageid', stable
            
            tempvar runningtot total half_pop is_median MedianAge
            by `by': gen double `runningtot' = sum(`pop')
            by `by': egen double `total' = total(`pop')
            gen double `half_pop' = `total' / 2

            by `by': gen byte `is_median' = (`runningtot' >= `half_pop' & `runningtot'[_n-1] < `half_pop')
            by `by': replace  `is_median' = 1 if _n == 1 & `runningtot' >= `half_pop'

            gen double `MedianAge' = ((`ageid' - 1) * 5) + ((`half_pop' - (`runningtot' - `pop')) / `pop' * 5)
            
            keep if `is_median' == 1
            keep `by' `MedianAge'
            rename `MedianAge' median_age
            
            save "`saving'", `replace'
            restore
        }
        display as text "Batch mode: Medians saved to " as result "`saving'"
    }

    // --- INTERACTIVE MODE ---
    else {
        quietly {
            preserve
            marksample touse
            keep if `touse'

            // Strict check for interactive mode
            capture isid `ageid'
            if _rc {
                restore
                display as error "Error: Multiple observations found for the same ageid."
                display as error "The data must be collapsed to one row per ageid for this selection."
                exit 459
            }

            local vlab : var label `pop'
            if `"`vlab'"' == "" local vlab "`pop'"
            local vlab = ustrregexra(`"`vlab'"', "\s*\(sum\)\s*", " ", 1)
            local vlab = trim(`"`vlab'"')

            sort `ageid', stable
            tempvar runningtot total half_pop is_median ratio_var MedianAge
            gen double `runningtot' = sum(`pop')
            sum `pop', meanonly
            local n_total = r(sum)
            local half_pop = `n_total' / 2

            gen byte `is_median' = 0
            replace `is_median' = 1 if `runningtot' >= `half_pop' & (`runningtot' - `pop' < `half_pop')

            gen double `ratio_var' = (`half_pop' - (`runningtot' - `pop')) / `pop'
            gen double `MedianAge' = ((`ageid' - 1) * 5) + (`ratio_var' * 5)
            
            summarize `MedianAge' if `is_median' == 1, meanonly
            local m_age = r(mean)
        }

        if `n_total' > 0 & `m_age' != . {
            display as text "(median age) `vlab': " as result %4.2f `m_age'
            return scalar median = `m_age'
            return scalar N      = `n_total'
        }
        restore
    }
end
