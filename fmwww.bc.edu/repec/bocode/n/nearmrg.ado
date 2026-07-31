*! nearmrg.ado - performs nearest match merges of nearvar within exact matches of optional varlist
*! version 3.0.1 E Booth Jul2026 (fix: using-file load/merge quoting; nearvar(m=u) parse; tie-break direction)
*! Performs nearest neighbor matching for merging datasets.

program define nearmrg
    version 11.0
    syntax [varlist(default=none)] using/ ,  ///
        Nearvar(string) [TYPE(str)] ///
        [LIMit(real -1) GENMATCH(str) LOWer UPper ROundup DISTance(str) NOKEEP * ]

    // Parse Nearvar: support nearvar(master_var[=using_var])
    local nvspec : subinstr local nearvar " " "", all
    local eqpos = strpos("`nvspec'", "=")
    if `eqpos' > 0 {
        local m_nearvar = substr("`nvspec'", 1, `eqpos' - 1)
        local u_nearvar = substr("`nvspec'", `eqpos' + 1, .)
    }
    else {
        local m_nearvar `nvspec'
        local u_nearvar `nvspec'
    }
    if "`m_nearvar'" == "" | "`u_nearvar'" == "" | strpos("`u_nearvar'", "=") > 0 {
        di as err "nearvar() must be specified as nearvar(master_var) or nearvar(master_var=using_var)"
        exit 198
    }
    confirm numeric var `m_nearvar'
    
    // Error checking for options
    if "`type'" == "" local type "m:1"
    if !inlist("`type'", "1:1", "m:1", "1:m", "m:m") {
        di as err "type() must be 1:1, m:1, 1:m, or m:m"
        exit 198
    }
    
    if ("`lower'"!="") + ("`upper'"!="") + ("`roundup'"!="") > 1 {
        di as err "Cannot specify more than one of roundup, lower, or upper"
        exit 198
    }

    if "`genmatch'" != "" confirm new var `genmatch'
    if "`distance'" != "" confirm new var `distance'

    // <= makes distance ties resolve to `last' (the lower value) by default;
    // roundup uses < so ties fall through to `next' (the higher value)
    local eq_op = cond("`roundup'" == "", "<=", "<")

    // Setup variables
    tempvar order mrg gen dist_tmp hold
    gen double `order' = _n
    
    local fullvars_m `varlist' `m_nearvar'
    local fullvars_u `varlist' `u_nearvar'
    
    if "`varlist'" != "" {
        local bycmd "by `varlist':"
    }

    preserve
        // Prepare master lookup
        keep `order' `fullvars_m'
        tempfile master_work
        save `master_work'
        
        // Load using data
        use `fullvars_u' using "`using'", clear
        confirm numeric var `u_nearvar'
        
        // Ensure uniqueness for m:1 logic if required
        sort `fullvars_u'
        cap isid `fullvars_u'
        if _rc {
            di as err "Variables `fullvars_u' are not unique in using dataset. Nearest match might be ambiguous."
            // We don't exit here to allow m:m or if the user knows what they are doing, 
            // but for the logic below we need unique values of nearvar within varlist in using.
            // Let's enforce it for the lookup phase.
            duplicates drop `fullvars_u', force
        }
        
        // Prepare using for lookup
        tempvar is_using
        gen byte `is_using' = 1
        if "`u_nearvar'" != "`m_nearvar'" {
            rename `u_nearvar' `m_nearvar' // temporary rename to match master for lookup
        }
        
        append using `master_work'
        sort `varlist' `m_nearvar' `is_using'
        
        tempvar last next
        gen double `last' = `m_nearvar' if `is_using' == 1
        gen double `next' = `last'
        
        `bycmd' replace `last' = `last'[_n-1] if mi(`last')
        
        gsort `varlist' -`m_nearvar' -`is_using'
        `bycmd' replace `next' = `next'[_n-1] if mi(`next')
        
        // Tie breaking and direction
        if "`lower'" != "" {
            gen double `gen' = `last'
        }
        else if "`upper'" != "" {
            gen double `gen' = `next'
        }
        else {
            // default nearest
            gen double `gen' = cond(abs(`m_nearvar'-`last') `eq_op' abs(`m_nearvar'-`next'), `last', `next')
            replace `gen' = `last' if mi(`next')
            replace `gen' = `next' if mi(`last')
        }
        
        // Apply limit if specified
        if `limit' != -1 {
            replace `gen' = . if abs(`m_nearvar' - `gen') > `limit'
        }
        
        // Clean up and save lookup
        keep if mi(`is_using')
        keep `order' `gen'
        save `master_work', replace
    restore

    // Merge back the matched values
    qui merge 1:1 `order' using `master_work', nogenerate
    drop `order'

    // Save distance before renaming if requested
    if "`distance'" != "" {
        gen double `distance' = abs(`m_nearvar' - `gen')
    }

    // Shuffle names to perform the actual merge with the using dataset
    rename `m_nearvar' `hold'
    rename `gen' `u_nearvar'
    
    // Perform the actual merge
    merge `type' `varlist' `u_nearvar' using "`using'", `options'
    
    // Handle results
    if "`genmatch'" != "" {
        rename `u_nearvar' `genmatch'
        label var `genmatch' "Matched value of `u_nearvar' from using"
    }
    else {
        drop `u_nearvar'
    }
    
    rename `hold' `m_nearvar'

    if "`nokeep'" != "" {
        keep if _merge == 3
    }
    
    // Final report
    count if _merge == 3
    local matched = r(N)
    count
    local total = r(N)
    di as txt "Matched: `matched' out of `total' observations."

end
