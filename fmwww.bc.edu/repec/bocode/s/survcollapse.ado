*! survcollapse.ado
*! Collapse surveillance data over a chosen time variable and complete the series
*! v 1.0 17Jan2026  Leonelo Bautista

program define survcollapse, rclass
    version 15.1

    // timevar REQUIRED; keepvars OPTIONAL
    syntax [if] [in] , ///
    DATEVAR(name) ///
    CASEVAR(name) ///
    TIMEVAR(string) ///
    SAVING(string) ///
    [ KEEPVARS(varlist) ///
      REPLACE ]

    // ------------------------------------------------------------
    // Checks
    // ------------------------------------------------------------
    confirm variable `datevar'
    confirm variable `casevar'

    capture confirm numeric variable `datevar'
    if (_rc) {
        di as err "`datevar' must be a numeric Stata daily date."
        exit 198
    }

    capture confirm numeric variable `casevar'
    if (_rc) {
        di as err "`casevar' must be numeric."
        exit 198
    }

    if ("`saving'" == "") {
        di as err "saving() is required."
        exit 198
    }

    preserve
    marksample touse
    quietly keep if `touse'

    // missing cases -> 0
    quietly replace `casevar' = 0 if missing(`casevar')

    // ------------------------------------------------------------
    // keepvars(): confirm + must be constant (only if provided)
    // Store constants before collapse; add back after collapse.
    // ------------------------------------------------------------
    if ("`keepvars'" != "") {

        // Confirm variables exist
        local __kvl "`keepvars'"
        while ("`__kvl'" != "") {
            gettoken __kv __kvl : __kvl
            confirm variable `__kv'
        }

        // Check constancy + store value/type
        local __kvl "`keepvars'"
        while ("`__kvl'" != "") {
            gettoken __kv __kvl : __kvl

            capture confirm numeric variable `__kv'
            if (_rc == 0) {
                quietly summarize `__kv', meanonly
                if (r(min) != r(max)) {
                    di as err "keepvars() must be constant within the if/in sample when collapsing by timevar only."
                    di as err "Variable `__kv' takes multiple values in the sample."
                    exit 198
                }
                local __kv_type_`__kv' "num"
                local __kv_val_`__kv' = r(min)
            }
            else {
                quietly levelsof `__kv', local(__lev)
                local __n : word count `__lev'
                if (`__n' != 1) {
                    di as err "keepvars() must be constant within the if/in sample when collapsing by timevar only."
                    di as err "Variable `__kv' takes multiple values in the sample."
                    exit 198
                }
                local __kv_type_`__kv' "str"
                local __kv_val_`__kv' "`__lev'"
            }
        }
    }

    // ------------------------------------------------------------
    // Normalize timevar name
    // ------------------------------------------------------------
    local __t = lower(strtrim("`timevar'"))
    if ("`__t'" == "day") local __t "__day"

    if !inlist("`__t'","__day","stata_week","iso_week","cdc_week") {
        di as err "timevar() must be one of: __day stata_week iso_week cdc_week."
        exit 198
    }

    // ------------------------------------------------------------
    // DAILY: collapse by __day (existing behavior)
    // ------------------------------------------------------------
    if ("`__t'" == "__day") {

        // Build __day from datevar (overwrite if exists)
        capture confirm variable __day
        if (!_rc) drop __day
        quietly gen long __day = `datevar'
        label var __day "Day (Stata daily date from `datevar')"

        quietly collapse (sum) `casevar', by(__day)

        tempfile __collapsed __times
        quietly save `"`__collapsed'"', replace

        quietly summarize __day, meanonly
        local __tmin = r(min)
        local __tmax = r(max)

        clear
        quietly set obs `=(`__tmax' - `__tmin' + 1)'
        quietly gen long __day = `__tmin' + _n - 1
        quietly save `"`__times'"', replace

        use `"`__times'"', clear
        quietly merge 1:1 __day using `"`__collapsed'"'

        quietly gen byte created = (_merge != 3)
        label var created "1=time unit created (filled-in); 0=observed in data"
        drop _merge

        quietly replace `casevar' = 0 if missing(`casevar')

        // Add back keepvars as constants
        if ("`keepvars'" != "") {
            local __kvl "`keepvars'"
            while ("`__kvl'" != "") {
                gettoken __kv __kvl : __kvl
                if ("`__kv_type_`__kv''" == "num") gen double `__kv' = `__kv_val_`__kv''
                else                               gen strL   `__kv' = "`__kv_val_`__kv''"
            }
            order `keepvars' __day `casevar' created
        }
        else {
            order __day `casevar' created
        }

        quietly save "`saving'", `replace'
        di as txt "File saved: `saving'"
        restore
        exit
    }

    // ------------------------------------------------------------
    // WEEKLY: collapse by a continuous week-start date, then output year+week
    // ------------------------------------------------------------
    tempvar __wstart
    quietly gen long `__wstart' = .

    // Define week-start date depending on week type
    if ("`__t'" == "stata_week" | "`__t'" == "cdc_week") {
        // Sunday-based weeks: start = Sunday
        quietly replace `__wstart' = `datevar' - dow(`datevar')
    }
    else if ("`__t'" == "iso_week") {
        // Monday-based weeks: start = Monday
        quietly replace `__wstart' = `datevar' - mod(dow(`datevar') + 6, 7)
    }

    label var `__wstart' "Week start date (daily date; internal)"

    // Collapse by continuous weekly axis
    quietly collapse (sum) `casevar', by(`__wstart')

    // Complete missing weeks using step=7
    tempfile __collapsed __times
    quietly save `"`__collapsed'"', replace

    quietly summarize `__wstart', meanonly
    local __wmin = r(min)
    local __wmax = r(max)

    clear
    quietly set obs `=(floor((`__wmax' - `__wmin')/7) + 1)'
    quietly gen long `__wstart' = `__wmin' + 7*(_n - 1)
    quietly save `"`__times'"', replace

    use `"`__times'"', clear
    quietly merge 1:1 `__wstart' using `"`__collapsed'"'

    quietly gen byte created = (_merge != 3)
    label var created "1=time unit created (filled-in); 0=observed in data"
    drop _merge
    quietly replace `casevar' = 0 if missing(`casevar')
    
    // ------------------------------------------------------------
    // Generate year + week corresponding to selected week type
    // ------------------------------------------------------------
    quietly gen int year = .
    quietly gen int week = .

    if ("`__t'" == "stata_week") {
        // Stata/Sunday-based week index within calendar year
        quietly gen double __wdate = wofd(`__wstart')
        quietly replace year = year(`__wstart')
        quietly replace week = __wdate - wofd(mdy(1,1,year)) + 1
        drop __wdate
        label var year "Year (Stata/Sunday-based weeks)"
        label var week "Week (Stata/Sunday-based)"
    }
    else if ("`__t'" == "cdc_week") {
        // CDC/MMWR: Sun–Sat; week #1 is first week with >=4 days in the calendar year
        // Use Wednesday (midweek) to determine MMWR year to avoid week==0 at year boundaries
        tempvar __mid __y __jan4 __wk1
        quietly gen long `__mid'  = `__wstart' + 3          // Wednesday of this MMWR week
        quietly gen int  `__y'    = year(`__mid')
        quietly gen long `__jan4' = mdy(1,4,`__y')
        quietly gen long `__wk1'  = `__jan4' - dow(`__jan4')   // Sunday of week containing Jan 4

        quietly replace year = `__y'
        quietly replace week = 1 + floor((`__wstart' - `__wk1')/7)

        // Safety guard: MMWR week should never be 0
        quietly count if week==0
        if (r(N)) {
                di as error "survcollapse: generated MMWR week==0 (should be 1–52/53). Please report this."
                exit 459
        }

        drop `__mid' `__y' `__jan4' `__wk1'
        label var year "Year (CDC/MMWR)"
        label var week "Week (CDC/MMWR)"

    }
    else if ("`__t'" == "iso_week") {
        // ISO: Mon-based; week-year = year(Thursday); week 1 contains Jan 4
        tempvar __thu __y __jan4 __jan4_wday __thu_wk1
        quietly gen long `__thu' = `__wstart' + 3
        quietly gen int  `__y'   = year(`__thu')
        quietly gen long `__jan4' = mdy(1,4,`__y')
        // ISO weekday of Jan 4: Mon=1..Sun=7
        quietly gen byte `__jan4_wday' = mod(dow(`__jan4') + 6, 7) + 1
        quietly gen long `__thu_wk1' = `__jan4' + (4 - `__jan4_wday')
        quietly replace year = `__y'
        quietly replace week = 1 + floor((`__thu' - `__thu_wk1')/7)
        drop `__thu' `__y' `__jan4' `__jan4_wday' `__thu_wk1'
        label var year "Year (ISO 8601)"
        label var week "Week (ISO 8601)"
    }

    // Add back keepvars as constants (if provided)
    if ("`keepvars'" != "") {
        local __kvl "`keepvars'"
        while ("`__kvl'" != "") {
            gettoken __kv __kvl : __kvl
            if ("`__kv_type_`__kv''" == "num") gen double `__kv' = `__kv_val_`__kv''
            else                               gen strL   `__kv' = "`__kv_val_`__kv''"
        }
        order `keepvars' year week `casevar' created
    }
    else {
        order year week `casevar' created
    }

    // Drop internal week-start date
    drop `__wstart'

    quietly save "`saving'", `replace'
    di as txt "File saved: `saving'"

    restore
end
