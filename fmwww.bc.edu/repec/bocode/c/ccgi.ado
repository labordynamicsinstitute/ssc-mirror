*! ccgi.ado
*! China Corporate Governance Index (CCGI)
*! Version 3.6  11June2026 (Fixed export options to actually save data)
*! Authors: Wu Lianghai & Wu Hanyan

program define ccgi, rclass
    version 15.0
    syntax varlist(min=12 max=12) [if] [in] , ///
        REVerse(string) ///
        [ WINsor(string) * REPLace EXPORtDTA(string) EXPORtEXCEL(string) MISSing(string) ]

    * Check variable count
    local nvars : list sizeof varlist
    if `nvars' != 12 {
        di as error "Error: Exactly 12 governance indicators are required"
        exit 198
    }

    * Parse reverse indicators list
    local rev_vars ""
    foreach r in `reverse' {
        local rev_vars "`rev_vars' `r'"
    }

    * ========== 0. Missing value handling ==========
    * Parse missing option
    local missing_method = "none"
    if "`missing'" != "" {
        local missing_method = trim("`missing'")
        * Remove any parentheses if present
        local missing_method = subinstr("`missing_method'", "(", "", .)
        local missing_method = subinstr("`missing_method'", ")", "", .)
        
        if "`missing_method'" == "drop" {
            di as text "Missing value handling: dropping observations with any missing values..."
            tempvar any_missing
            egen `any_missing' = rowmiss(`varlist')
            quietly drop if `any_missing' > 0
            di as text "  Observations remaining: " _N
        }
        else if "`missing_method'" == "mean" {
            di as text "Missing value handling: imputing with variable means..."
            foreach var of varlist `varlist' {
                capture confirm variable `var'
                if _rc == 0 {
                    quietly summarize `var', meanonly
                    local mean_val = r(mean)
                    quietly replace `var' = `mean_val' if missing(`var')
                    di as text "  `var': imputed with mean = " `mean_val'
                }
            }
        }
        else if "`missing_method'" == "median" {
            di as text "Missing value handling: imputing with variable medians..."
            foreach var of varlist `varlist' {
                capture confirm variable `var'
                if _rc == 0 {
                    quietly summarize `var', detail
                    local median_val = r(p50)
                    quietly replace `var' = `median_val' if missing(`var')
                    di as text "  `var': imputed with median = " `median_val'
                }
            }
        }
        else if "`missing_method'" == "zero" {
            di as text "Missing value handling: imputing with zeros..."
            foreach var of varlist `varlist' {
                capture confirm variable `var'
                if _rc == 0 {
                    quietly replace `var' = 0 if missing(`var')
                    di as text "  `var': imputed with 0"
                }
            }
        }
        else {
            di as error "Error: missing() option must be drop, mean, median, or zero"
            exit 198
        }
        di as text "----------------------------------"
    }

    * Mark sample
    marksample touse
    quietly keep if `touse'
    
    * ========== 1. Winsorization (ONLY if user specifies winsor(p1 p2)) ==========
    if "`winsor'" != "" {
        local winsor_clean = trim("`winsor'")
        local winsor_clean = subinstr("`winsor_clean'", "winsor", "", .)
        local winsor_clean = trim("`winsor_clean'")
        local winsor_clean = subinstr("`winsor_clean'", "(", "", .)
        local winsor_clean = subinstr("`winsor_clean'", ")", "", .)
        local winsor_clean = trim("`winsor_clean'")
        
        if "`winsor_clean'" != "" {
            gettoken p1 p2 : winsor_clean
            if "`p2'" == "" {
                di as error "Error: winsor() requires two percentiles, e.g., winsor(1 99) or winsor(2 98)"
                di as error "  Example: ccgi ..., reverse(...) winsor(1 99)"
                exit 198
            }
            cap confirm number `p1'
            if _rc != 0 {
                di as error "Error: winsor() first argument must be a number"
                exit 198
            }
            cap confirm number `p2'
            if _rc != 0 {
                di as error "Error: winsor() second argument must be a number"
                exit 198
            }
            if `p1' >= `p2' {
                di as error "Error: winsor() first percentile must be less than second percentile"
                exit 198
            }
            di as text "Applying winsorization (`p1'% and `p2'%)..."
            foreach var of varlist `varlist' {
                quietly tab `var', missing
                local distinct = r(r)
                if `distinct' == 2 {
                    di as text "  `var': binary variable, skipping winsorization"
                    continue
                }
                quietly summarize `var', meanonly
                if r(min) == 0 & r(max) == 1 {
                    di as text "  `var': binary variable (0/1), skipping winsorization"
                    continue
                }
                quietly _pctile `var', p(`p1',`p2')
                local plow = r(r1)
                local phigh = r(r2)
                quietly gen double winsor_`var' = `var'
                quietly replace winsor_`var' = `plow' if `var' < `plow' & !missing(`var')
                quietly replace winsor_`var' = `phigh' if `var' > `phigh' & !missing(`var')
                drop `var'
                rename winsor_`var' `var'
                di as text "  `var': winsorized to [`plow', `phigh']"
            }
            di as text "Winsorization completed."
        }
        else {
            di as error "Error: winsor() requires percentiles, e.g., winsor(1 99) or winsor(2 98)"
            exit 198
        }
        di as text "----------------------------------"
    }
    else {
        di as text "No winsorization applied (use winsor(p1 p2) to enable)"
        di as text "----------------------------------"
    }

    * ========== 2. Add variable labels (original variables) ==========
    capture label variable board_size "Board Size (number of directors)"
    capture label variable indep_ratio "Proportion of Independent Directors"
    capture label variable mgt_share "Management Shareholding Ratio"
    capture label variable top1_share "Largest Shareholder Ownership"
    capture label variable top5_share "Top5 Shareholders Ownership"
    capture label variable top10_share "Top10 Shareholders Ownership"
    capture label variable meeting_freq "Board Meeting Frequency"
    capture label variable audit_committee "Audit Committee Existence (1=yes)"
    capture label variable dual_role "CEO Duality (1=CEO is Chair)"
    capture label variable salary "Executive Compensation (log)"
    capture label variable disclosure_quality "Disclosure Quality Score"
    capture label variable ipo_year "IPO Year"

    * ========== 3. Normalization (Forward/Reverse) ==========
    di as text "Min-Max normalization [0,1]:"
    
    * Drop existing normalized variables if they exist
    capture drop n_board_size n_indep_ratio n_mgt_share n_top1_share n_top5_share ///
                 n_top10_share n_meeting_freq n_audit_committee n_dual_role ///
                 n_salary n_disclosure_quality n_ipo_year
    
    * board_size
    quietly summarize board_size, meanonly
    if r(max) == r(min) {
        di as warn "  Warning: board_size has no variation, set to 0.5"
        gen double n_board_size = 0.5
    }
    else {
        gen double n_board_size = (board_size - r(min)) / (r(max) - r(min))
        di as text "  board_size [forward]"
    }
    label variable n_board_size "Normalized Board Size [0,1]"
    
    * indep_ratio
    quietly summarize indep_ratio, meanonly
    if r(max) == r(min) {
        di as warn "  Warning: indep_ratio has no variation, set to 0.5"
        gen double n_indep_ratio = 0.5
    }
    else {
        gen double n_indep_ratio = (indep_ratio - r(min)) / (r(max) - r(min))
        di as text "  indep_ratio [forward]"
    }
    label variable n_indep_ratio "Normalized Independent Directors Ratio [0,1]"
    
    * mgt_share
    quietly summarize mgt_share, meanonly
    if r(max) == r(min) {
        di as warn "  Warning: mgt_share has no variation, set to 0.5"
        gen double n_mgt_share = 0.5
    }
    else {
        gen double n_mgt_share = (mgt_share - r(min)) / (r(max) - r(min))
        di as text "  mgt_share [forward]"
    }
    label variable n_mgt_share "Normalized Management Shareholding [0,1]"
    
    * top1_share (reverse)
    quietly summarize top1_share, meanonly
    if r(max) == r(min) {
        di as warn "  Warning: top1_share has no variation, set to 0.5"
        gen double n_top1_share = 0.5
    }
    else {
        gen double n_top1_share = (r(max) - top1_share) / (r(max) - r(min))
        di as text "  top1_share [reverse]"
    }
    label variable n_top1_share "Normalized Largest Shareholder Ownership (reverse) [0,1]"
    
    * top5_share
    quietly summarize top5_share, meanonly
    if r(max) == r(min) {
        di as warn "  Warning: top5_share has no variation, set to 0.5"
        gen double n_top5_share = 0.5
    }
    else {
        gen double n_top5_share = (top5_share - r(min)) / (r(max) - r(min))
        di as text "  top5_share [forward]"
    }
    label variable n_top5_share "Normalized Top5 Shareholding [0,1]"
    
    * top10_share
    quietly summarize top10_share, meanonly
    if r(max) == r(min) {
        di as warn "  Warning: top10_share has no variation, set to 0.5"
        gen double n_top10_share = 0.5
    }
    else {
        gen double n_top10_share = (top10_share - r(min)) / (r(max) - r(min))
        di as text "  top10_share [forward]"
    }
    label variable n_top10_share "Normalized Top10 Shareholding [0,1]"
    
    * meeting_freq
    quietly summarize meeting_freq, meanonly
    if r(max) == r(min) {
        di as warn "  Warning: meeting_freq has no variation, set to 0.5"
        gen double n_meeting_freq = 0.5
    }
    else {
        gen double n_meeting_freq = (meeting_freq - r(min)) / (r(max) - r(min))
        di as text "  meeting_freq [forward]"
    }
    label variable n_meeting_freq "Normalized Meeting Frequency [0,1]"
    
    * audit_committee
    quietly summarize audit_committee, meanonly
    if r(max) == r(min) {
        di as warn "  Warning: audit_committee has no variation, set to 0.5"
        gen double n_audit_committee = 0.5
    }
    else {
        gen double n_audit_committee = (audit_committee - r(min)) / (r(max) - r(min))
        di as text "  audit_committee [forward]"
    }
    label variable n_audit_committee "Normalized Audit Committee Existence [0,1]"
    
    * dual_role (reverse)
    quietly summarize dual_role, meanonly
    if r(max) == r(min) {
        di as warn "  Warning: dual_role has no variation, set to 0.5"
        gen double n_dual_role = 0.5
    }
    else {
        gen double n_dual_role = (r(max) - dual_role) / (r(max) - r(min))
        di as text "  dual_role [reverse]"
    }
    label variable n_dual_role "Normalized CEO Duality (reverse) [0,1]"
    
    * salary
    quietly summarize salary, meanonly
    if r(max) == r(min) {
        di as warn "  Warning: salary has no variation, set to 0.5"
        gen double n_salary = 0.5
    }
    else {
        gen double n_salary = (salary - r(min)) / (r(max) - r(min))
        di as text "  salary [forward]"
    }
    label variable n_salary "Normalized Executive Compensation [0,1]"
    
    * disclosure_quality
    quietly summarize disclosure_quality, meanonly
    if r(max) == r(min) {
        di as warn "  Warning: disclosure_quality has no variation, set to 0.5"
        gen double n_disclosure_quality = 0.5
    }
    else {
        gen double n_disclosure_quality = (disclosure_quality - r(min)) / (r(max) - r(min))
        di as text "  disclosure_quality [forward]"
    }
    label variable n_disclosure_quality "Normalized Disclosure Quality [0,1]"
    
    * ipo_year
    quietly summarize ipo_year, meanonly
    if r(max) == r(min) {
        di as warn "  Warning: ipo_year has no variation, set to 0.5"
        gen double n_ipo_year = 0.5
    }
    else {
        gen double n_ipo_year = (ipo_year - r(min)) / (r(max) - r(min))
        di as text "  ipo_year [forward]"
    }
    label variable n_ipo_year "Normalized IPO Year [0,1]"
    
    di as text "----------------------------------"

    * ========== 4. Equal-weighted composite index ==========
    di as text "Creating composite index (equal-weighted)..."
    
    * Drop existing ccgi_index if it exists
    capture drop ccgi_index
    
    * Calculate mean of all 12 normalized variables
    egen double ccgi_index = rowmean(n_board_size n_indep_ratio n_mgt_share ///
        n_top1_share n_top5_share n_top10_share n_meeting_freq ///
        n_audit_committee n_dual_role n_salary n_disclosure_quality n_ipo_year)
    
    label var ccgi_index "China Corporate Governance Index (CCGI) [0,1]"
    order ccgi_index, after(ipo_year)

    * ========== 5. Descriptive statistics ==========
    di as text "CCGI Descriptive Statistics:"
    quietly summarize ccgi_index, detail
    di as text "----------------------------------"
    di as result "Mean      : " r(mean)
    di as result "Std. Dev. : " r(sd)
    di as result "Min       : " r(min)
    di as result "P25       : " r(p25)
    di as result "Median    : " r(p50)
    di as result "P75       : " r(p75)
    di as result "Max       : " r(max)

    * ========== 6. Export files (save while keeping data in memory) ==========
    * Save DTA file if requested
    if "`exportdta'" != "" {
        if "`replace'" != "" {
            quietly save "`exportdta'", replace
            di as result "✓ DTA file saved: `exportdta'"
        }
        else {
            capture confirm new file "`exportdta'"
            if _rc == 0 {
                quietly save "`exportdta'"
                di as result "✓ DTA file saved: `exportdta'"
            }
            else {
                di as error "File `exportdta' already exists. Use replace option to overwrite."
                exit 602
            }
        }
    }
    
    * Export to Excel if requested (temporary save then export)
    if "`exportexcel'" != "" {
        tempfile tempdta
        quietly save "`tempdta'"
        if "`replace'" != "" {
            quietly export excel using "`exportexcel'", firstrow(variables) replace keepcellfmt
            di as result "✓ Excel file saved: `exportexcel'"
        }
        else {
            capture confirm new file "`exportexcel'"
            if _rc == 0 {
                quietly export excel using "`exportexcel'", firstrow(variables) replace keepcellfmt
                di as result "✓ Excel file saved: `exportexcel'"
            }
            else {
                di as error "File `exportexcel' already exists. Use replace option to overwrite."
                exit 602
            }
        }
        * Restore data from temp file to keep memory intact
        quietly use "`tempdta'", clear
    }

    * ========== 7. Return results ==========
    return scalar mean_ccgi = r(mean)
    return scalar sd_ccgi   = r(sd)
    return scalar min_ccgi  = r(min)
    return scalar p25_ccgi  = r(p25)
    return scalar median_ccgi = r(p50)
    return scalar p75_ccgi  = r(p75)
    return scalar max_ccgi  = r(max)

    di as text "----------------------------------"
    di as result "✓ CCGI construction completed!"
    di as text "  Data remains in memory for further analysis"
    if "`exportdta'" != "" | "`exportexcel'" != "" {
        di as text "  Files have been exported as requested"
    }
end