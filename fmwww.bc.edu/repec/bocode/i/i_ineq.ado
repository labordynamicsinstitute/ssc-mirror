*! version 2.0.0  11nov2025
*! Individual decomposition of inequality measures
*! Tim F. Liao, University of Illinois Urbana-Champaign
*! Ported from R package iIneq

program define i_ineq, rclass
    version 14.0
    
    syntax varname(numeric) [if] [in] [pweight], ///
        Group(varname numeric) ///
        [Measure(string) GENerate(string) REPlace]
    
    // Mark sample
    marksample touse
    markout `touse' `group'
    
    // Handle non-positive values based on measure
    if "`measure'" == "gini" {
        // Gini can handle all values including zeros and negatives
        // No additional filtering needed
    }
    else if "`measure'" == "theill" {
        // Theil L requires positive values only
        quietly count if `varlist' <= 0 & `touse'
        if r(N) > 0 {
            local n_nonpositive = r(N)
            display as text "Note: `n_nonpositive' observation(s) with non-positive values excluded from Theil L computation"
            quietly replace `touse' = 0 if `varlist' <= 0
        }
    }
    else if "`measure'" == "theilt" {
        // Theil T can include zeros but not negative values
        // Using information theory principle: 0*log(0) = 0
        quietly count if `varlist' < 0 & `touse'
        if r(N) > 0 {
            local n_negative = r(N)
            display as text "Note: `n_negative' observation(s) with negative values excluded from Theil T computation"
            quietly replace `touse' = 0 if `varlist' < 0
        }
    }
    
    // Default measure is Gini
    if "`measure'" == "" {
        local measure "gini"
    }
    
    // Validate measure
    if !inlist("`measure'", "gini", "theill", "theilt") {
        display as error "measure() must be one of: gini, theill, theilt"
        exit 198
    }
    
    // Check number of groups
    quietly levelsof `group' if `touse', local(groups)
    local ng = r(r)
    if `ng' <= 1 {
        display as error "data must have 2 or more groups"
        exit 198
    }
    
    // Handle weights
    if "`weight'" != "" {
        local wgt "[`weight' `exp']"
        tempvar w
        quietly gen double `w' `exp' if `touse'
        local wgtvar "`w'"
    }
    else {
        tempvar w
        quietly gen double `w' = 1 if `touse'
        local wgtvar "`w'"
    }
    
    // Set up variable names
    if "`generate'" == "" {
        if "`measure'" == "gini" {
            local gen_i "g_i"
            local gen_b "g_ikb"
            local gen_w "g_ikw"
        }
        else if "`measure'" == "theill" {
            local gen_i "tl_i"
            local gen_b "tl_ib"
            local gen_w "tl_iw"
        }
        else if "`measure'" == "theilt" {
            local gen_i "tt_i"
            local gen_b "tt_ib"
            local gen_w "tt_iw"
        }
    }
    else {
        local gen_i "`generate'_i"
        local gen_b "`generate'_b"
        local gen_w "`generate'_w"
    }
    
    // Check if variables exist
    if "`replace'" == "" {
        confirm new variable `gen_i' `gen_b' `gen_w'
    }
    else {
        capture drop `gen_i' `gen_b' `gen_w'
    }
    
    // Display header
    display as text _n "Individual Decomposition of Inequality"
    display as text "Measure: " as result "`measure'"
    display as text "Variable: " as result "`varlist'"
    display as text "Group variable: " as result "`group'"
    display as text "Number of groups: " as result `ng'
    quietly count if `touse'
    display as text "Number of observations: " as result r(N)
    display as text "{hline 78}"
    
    // Call appropriate function
    if "`measure'" == "gini" {
        i_ineq_gini `varlist' if `touse', group(`group') ///
            wgtvar(`wgtvar') gen_i(`gen_i') gen_b(`gen_b') gen_w(`gen_w')
    }
    else if "`measure'" == "theill" {
        i_ineq_theill `varlist' if `touse', group(`group') ///
            wgtvar(`wgtvar') gen_i(`gen_i') gen_b(`gen_b') gen_w(`gen_w')
    }
    else if "`measure'" == "theilt" {
        i_ineq_theilt `varlist' if `touse', group(`group') ///
            wgtvar(`wgtvar') gen_i(`gen_i') gen_b(`gen_b') gen_w(`gen_w')
    }
    
    // Display summary statistics
    display as text _n "Summary Statistics:"
    display as text "{hline 78}"
    quietly summarize `gen_i' if `touse', detail
    display as text "Overall index: " as result %9.6f r(sum)
    
    quietly summarize `gen_b' if `touse', detail
    local between = r(sum)
    display as text "Between-group component: " as result %9.6f `between'
    
    quietly summarize `gen_w' if `touse', detail
    local within = r(sum)
    display as text "Within-group component: " as result %9.6f `within'
    
    local ratio = `between' / (`between' + `within')
    display as text "Between-group proportion: " as result %9.6f `ratio'
    
    // Return results
    return scalar N = r(N)
    return scalar groups = `ng'
    return scalar overall = r(sum)
    return scalar between = `between'
    return scalar within = `within'
    return scalar ratio = `ratio'
    return local measure "`measure'"
    return local varlist "`varlist'"
    return local group "`group'"
end


// Subroutine for Gini decomposition
program define i_ineq_gini
    syntax varname [if], group(varname) wgtvar(varname) ///
        gen_i(string) gen_b(string) gen_w(string)
    
    marksample touse
    
    quietly {
        // Calculate basic statistics
        summarize `wgtvar' if `touse', meanonly
        local N1 = r(sum)
        local n = r(N)
        
        count if `varlist' > 0 & `touse'
        local N0 = r(N)
        
        tempvar temp_wx
        gen double `temp_wx' = `wgtvar' * `varlist' if `touse'
        summarize `temp_wx' if `touse', meanonly
        local sx = r(sum)
        local c = 2 * `N1' * `sx'
        
        // Initialize output variables
        gen double `gen_i' = . if `touse'
        gen double `gen_b' = . if `touse'
        gen double `gen_w' = . if `touse'
        
        // Main computation loop
        noisily display as text "Computing Gini decomposition..."
        local last_pct = 0
        
        forvalues i = 1/`n' {
            // Progress indicator
            local pct = floor(`i' / `n' * 100)
            if `pct' > `last_pct' & mod(`pct', 10) == 0 {
                noisily display as text "  Progress: `pct'%"
                local last_pct = `pct'
            }
            
            local xi = `varlist'[`i']
            local gi = `group'[`i']
            local wi = `wgtvar'[`i']
            
            if `xi' != . & `gi' != . & `wi' != . {
                // Between-group component
                summarize `varlist' if `group' != `gi' & `touse', meanonly
                if r(N) > 0 {
                    tempvar temp_diff_b
                    gen double `temp_diff_b' = `wi' * `wgtvar' * abs(`xi' - `varlist') ///
                        if `group' != `gi' & `touse'
                    summarize `temp_diff_b' if `touse', meanonly
                    local gikb = r(sum) / `c'
                    drop `temp_diff_b'
                }
                else {
                    local gikb = 0
                }
                
                // Within-group component
                summarize `varlist' if `group' == `gi' & `touse', meanonly
                if r(N) > 0 {
                    tempvar temp_diff_w
                    gen double `temp_diff_w' = `wi' * `wgtvar' * abs(`xi' - `varlist') ///
                        if `group' == `gi' & `touse'
                    summarize `temp_diff_w' if `touse', meanonly
                    local gikw = r(sum) / `c'
                    drop `temp_diff_w'
                }
                else {
                    local gikw = 0
                }
                
                replace `gen_i' = `gikb' + `gikw' in `i'
                replace `gen_b' = `gikb' in `i'
                replace `gen_w' = `gikw' in `i'
            }
        }
        
        drop `temp_wx'
    }
    
    // Label variables
    label variable `gen_i' "Individual Gini component"
    label variable `gen_b' "Between-group Gini component"
    label variable `gen_w' "Within-group Gini component"
end


// Subroutine for Theil L decomposition
program define i_ineq_theill
    syntax varname [if], group(varname) wgtvar(varname) ///
        gen_i(string) gen_b(string) gen_w(string)
    
    marksample touse
    
    quietly {
        // Calculate basic statistics
        summarize `wgtvar' if `touse', meanonly
        local N1 = r(sum)
        
        count if `varlist' > 0 & `touse'
        local N0_count = r(N)
        summarize `wgtvar' if `varlist' > 0 & `touse', meanonly
        local N0 = r(sum)
        
        tempvar temp_wx
        gen double `temp_wx' = `wgtvar' * `varlist' if `touse'
        summarize `temp_wx' if `touse', meanonly
        local sx = r(sum)
        
        // Initialize output variables
        gen double `gen_i' = . if `touse'
        gen double `gen_b' = . if `touse'
        gen double `gen_w' = . if `touse'
        
        // Get group-specific sums
        levelsof `group' if `touse', local(groups)
        local ng : word count `groups'
        
        noisily display as text "Computing Theil L decomposition..."
        
        // Loop through groups
        foreach j of local groups {
            // Calculate group statistics
            summarize `wgtvar' if `group' == `j' & `touse', meanonly
            local nk = r(sum)
            local nk0 = `nk' / `N0'
            
            tempvar temp_wx_g
            gen double `temp_wx_g' = `wgtvar' * `varlist' if `group' == `j' & `touse'
            summarize `temp_wx_g' if `touse', meanonly
            local xk = r(sum)
            local yk = `xk' / `sx'
            drop `temp_wx_g'
            
            // Individual components for group j
            tempvar temp_ni0 temp_tli temp_tlib temp_tliw
            gen double `temp_ni0' = `wgtvar' / `nk' if `group' == `j' & `touse'
            
            // Tl.i component
            gen double `temp_tli' = (`wgtvar' / `N0') * ///
                log((`wgtvar' / `N0') / ((`wgtvar' * `varlist') / `sx')) ///
                if `group' == `j' & `varlist' > 0 & `touse'
            replace `gen_i' = `temp_tli' if `group' == `j' & `varlist' > 0 & `touse'
            
            // Tl.ib component
            gen double `temp_tlib' = `temp_ni0' * `nk0' * log(`nk0' / `yk') ///
                if `group' == `j' & `varlist' > 0 & `touse'
            replace `gen_b' = `temp_tlib' if `group' == `j' & `varlist' > 0 & `touse'
            
            // Tl.iw component
            gen double `temp_tliw' = `temp_ni0' * `nk0' * ///
                log(`temp_ni0' / ((`wgtvar' * `varlist') / `xk')) ///
                if `group' == `j' & `varlist' > 0 & `touse'
            replace `gen_w' = `temp_tliw' if `group' == `j' & `varlist' > 0 & `touse'
            
            drop `temp_ni0' `temp_tli' `temp_tlib' `temp_tliw'
        }
        
        drop `temp_wx'
    }
    
    // Label variables
    label variable `gen_i' "Individual Theil L component"
    label variable `gen_b' "Between-group Theil L component"
    label variable `gen_w' "Within-group Theil L component"
end


// Subroutine for Theil T decomposition
program define i_ineq_theilt
    syntax varname [if], group(varname) wgtvar(varname) ///
        gen_i(string) gen_b(string) gen_w(string)
    
    marksample touse
    
    quietly {
        // Calculate basic statistics
        summarize `wgtvar' if `touse', meanonly
        local N1 = r(sum)
        
        tempvar temp_wx
        gen double `temp_wx' = `wgtvar' * `varlist' if `touse'
        summarize `temp_wx' if `touse', meanonly
        local sx = r(sum)
        
        // Initialize output variables
        gen double `gen_i' = 0 if `touse'  // Initialize to 0 for 0*log(0) = 0
        gen double `gen_b' = 0 if `touse'
        gen double `gen_w' = 0 if `touse'
        
        // Get group-specific sums
        levelsof `group' if `touse', local(groups)
        
        noisily display as text "Computing Theil T decomposition..."
        
        // Loop through groups
        foreach j of local groups {
            // Calculate group statistics
            summarize `wgtvar' if `group' == `j' & `touse', meanonly
            local nk = r(sum)
            local nk1 = `nk' / `N1'
            
            tempvar temp_wx_g
            gen double `temp_wx_g' = `wgtvar' * `varlist' if `group' == `j' & `touse'
            summarize `temp_wx_g' if `touse', meanonly
            local xk = r(sum)
            local yk = `xk' / `sx'
            drop `temp_wx_g'
            
            // Individual components for group j
            tempvar temp_yi temp_tti temp_ttib temp_ttiw
            gen double `temp_yi' = (`wgtvar' * `varlist') / `xk' if `group' == `j' & `touse'
            
            // Tt.i component - only compute for positive values (0*log(0) = 0 by information theory)
            gen double `temp_tti' = ((`wgtvar' * `varlist') / `sx') * ///
                log(((`wgtvar' * `varlist') / `sx') / (`wgtvar' / `N1')) ///
                if `group' == `j' & `varlist' > 0 & `touse'
            replace `gen_i' = `temp_tti' if `group' == `j' & `varlist' > 0 & `touse'
            
            // Tt.ib component - only compute for positive values
            gen double `temp_ttib' = `temp_yi' * `yk' * log(`yk' / `nk1') ///
                if `group' == `j' & `varlist' > 0 & `touse'
            replace `gen_b' = `temp_ttib' if `group' == `j' & `varlist' > 0 & `touse'
            
            // Tt.iw component - only compute for positive values
            gen double `temp_ttiw' = `temp_yi' * `yk' * ///
                log(((`wgtvar' * `varlist') / `xk') / (`wgtvar' / `nk')) ///
                if `group' == `j' & `varlist' > 0 & `touse'
            replace `gen_w' = `temp_ttiw' if `group' == `j' & `varlist' > 0 & `touse'
            
            drop `temp_yi' `temp_tti' `temp_ttib' `temp_ttiw'
        }
        
        drop `temp_wx'
    }
    
    // Label variables
    label variable `gen_i' "Individual Theil T component"
    label variable `gen_b' "Between-group Theil T component"
    label variable `gen_w' "Within-group Theil T component"
    
    // Add note about zero values
    note `gen_i': Zero values included using 0*log(0)=0 principle (Liao 2016)
end