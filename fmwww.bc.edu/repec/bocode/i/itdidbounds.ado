*! itdidbounds 1.0.0 15sep2026
*! Copyright (c) 2026 Christina Laternser
*! Licensed under the MIT License.
program define itdidbounds, rclass
    version 17.0

    syntax varname(numeric) [if] [in], ///
        ID(varname) ///
        TIME(varname numeric) ///
        TREATED(varname numeric) ///
        LOWER(varname numeric) ///
        UPPER(varname numeric) ///
        NEVER(varname numeric) ///
        EVENT(numlist integer) ///
        [UNITWEIGHT(varname numeric) ///
         SAVING(string) ///
         DETAIL(string) ///
         REPLACE]

    marksample touse, novarlist

    local y `varlist'

    * unitweight() is deliberately named to avoid Stata's built-in
    * weight grammar. syntax confirms that it names a numeric variable.

    foreach e of numlist `event' {
        if `e' < 0 {
            di as error "event() must contain nonnegative integers."
            exit 198
        }
    }

    preserve
    quietly keep if `touse'

    if _N == 0 {
        restore
        di as error "No observations remain in the requested sample."
        exit 2000
    }

    capture isid `id' `time'
    if _rc {
        restore
        di as error "id() and time() must uniquely identify observations."
        exit 459
    }

    capture assert `time' == floor(`time') if !missing(`time')
    if _rc {
        restore
        di as error "time() must be integer-valued."
        exit 459
    }

    capture assert !missing(`treated', `never')
    if _rc {
        restore
        di as error "treated() and never() must be nonmissing."
        exit 459
    }

    capture assert inlist(`treated', 0, 1) if !missing(`treated')
    if _rc {
        restore
        di as error "treated() must be coded 0/1."
        exit 459
    }

    capture assert inlist(`never', 0, 1) if !missing(`never')
    if _rc {
        restore
        di as error "never() must be coded 0/1."
        exit 459
    }

    capture assert !(`treated' == 1 & `never' == 1)
    if _rc {
        restore
        di as error "A unit cannot be both treated and never-treated."
        exit 459
    }

    tempvar iid idlabel
    quietly egen long `iid' = group(`id')

    capture confirm string variable `id'
    if !_rc {
        quietly gen str80 `idlabel' = substr(`id', 1, 80)
    }
    else {
        quietly tostring `id', gen(`idlabel') usedisplayformat force
        quietly replace `idlabel' = substr(`idlabel', 1, 80)
    }

    tempvar trmin trmax nvmin nvmax lmin lmax umin umax wmin wmax
    quietly bysort `iid': egen double `trmin' = min(`treated')
    quietly bysort `iid': egen double `trmax' = max(`treated')
    quietly bysort `iid': egen double `nvmin' = min(`never')
    quietly bysort `iid': egen double `nvmax' = max(`never')
    quietly bysort `iid': egen double `lmin'  = min(`lower')
    quietly bysort `iid': egen double `lmax'  = max(`lower')
    quietly bysort `iid': egen double `umin'  = min(`upper')
    quietly bysort `iid': egen double `umax'  = max(`upper')

    capture assert `trmin' == `trmax'
    if _rc {
        restore
        di as error "treated() must be constant within id()."
        exit 459
    }

    capture assert `nvmin' == `nvmax'
    if _rc {
        restore
        di as error "never() must be constant within id()."
        exit 459
    }

    capture assert `lmin' == `lmax' if `trmax' == 1
    if _rc {
        restore
        di as error "lower() must be constant within treated id()."
        exit 459
    }

    capture assert `umin' == `umax' if `trmax' == 1
    if _rc {
        restore
        di as error "upper() must be constant within treated id()."
        exit 459
    }

    capture assert !missing(`lmin', `umin') if `trmax' == 1
    if _rc {
        restore
        di as error "Treated units require nonmissing lower() and upper()."
        exit 459
    }

    capture assert `lmin' == floor(`lmin') & `umin' == floor(`umin') ///
        if `trmax' == 1
    if _rc {
        restore
        di as error "lower() and upper() must be integer-valued."
        exit 459
    }

    capture assert `lmin' <= `umin' if `trmax' == 1
    if _rc {
        restore
        di as error "lower() cannot exceed upper()."
        exit 459
    }

    tempvar aw
    if "`unitweight'" == "" {
        quietly gen double `aw' = 1
    }
    else {
        quietly bysort `iid': egen double `wmin' = min(`unitweight')
        quietly bysort `iid': egen double `wmax' = max(`unitweight')

        capture assert `wmin' == `wmax' if `trmax' == 1
        if _rc {
            restore
            di as error "unitweight() must be constant within treated id()."
            exit 459
        }

        capture assert `wmin' > 0 & !missing(`wmin') if `trmax' == 1
        if _rc {
            restore
            di as error "unitweight() must be positive and nonmissing for treated units."
            exit 459
        }

        quietly gen double `aw' = `unitweight'
    }

    tempfile panel meta candidates states aggregates
    quietly save `panel'

    * The command is already inside one preserve/restore scope.
    * Build metadata by switching datasets rather than nesting preserve.
    quietly sort `iid' `time'
    quietly by `iid': keep if _n == 1
    quietly keep `iid' `idlabel' `trmax' `nvmax' `lmin' `umin' `aw'
    quietly rename (`trmax' `nvmax' `lmin' `umin') ///
           (__treated __never __lower __upper)
    quietly rename `aw' __weight
    quietly isid `iid'
    quietly save `meta'

    quietly use `meta', clear
    quietly count if __treated == 1
    local ntreated = r(N)

    if `ntreated' == 0 {
        restore
        di as error "No treated units were identified."
        exit 2001
    }

    quietly levelsof `iid' if __treated == 1, local(treated_ids)

    * Numeric scalars preserve full double precision. Do not route
    * noninteger outcomes or contrasts through local macros. In postfile's
    * newvarlist syntax, parentheses are required to apply one storage type
    * to several variables; without them, only the next variable gets that type.
    tempname ph sW syb syt sdy sdc sq
    quietly postfile `ph' ///
        long unit_id ///
        str80 unit_label ///
        int(lower upper candidate_date event_time baseline_year target_year) ///
        double(analysis_weight treated_change control_change contrast) ///
        int n_controls ///
        byte(supported candidate_is_earliest candidate_is_latest) ///
        using `candidates', replace

    foreach ii of local treated_ids {
        quietly use `meta', clear
        quietly summarize __lower if `iid' == `ii', meanonly
        local L = r(mean)
        quietly summarize __upper if `iid' == `ii', meanonly
        local U = r(mean)
        quietly summarize __weight if `iid' == `ii', meanonly
        scalar `sW' = r(mean)
        quietly levelsof `idlabel' if `iid' == `ii', local(ILAB) clean

        forvalues g = `L'/`U' {
            foreach e of numlist `event' {
                local b = `g' - 1
                local t = `g' + `e'

                quietly use `panel', clear
                quietly summarize `y' if `iid' == `ii' & `time' == `b', meanonly
                scalar `syb' = r(mean)
                local yb_ok = (r(N) == 1 & !missing(`syb'))

                quietly summarize `y' if `iid' == `ii' & `time' == `t', meanonly
                scalar `syt' = r(mean)
                local yt_ok = (r(N) == 1 & !missing(`syt'))

                local supported = 0
                local nctrl = 0
                scalar `sdc' = .
                scalar `sq' = .
                scalar `sdy' = .

                if `yb_ok' & `yt_ok' {
                    scalar `sdy' = `syt' - `syb'

                    quietly keep if inlist(`time', `b', `t')
                    tempvar ybase ytarget base target nobs
                    quietly gen double `ybase'   = `y' if `time' == `b'
                    quietly gen double `ytarget' = `y' if `time' == `t'

                    quietly bysort `iid': egen double `base' = max(`ybase')
                    quietly bysort `iid': egen double `target' = max(`ytarget')
                    quietly bysort `iid': egen int `nobs' = total(!missing(`y'))

                    quietly sort `iid' `time'
                    quietly by `iid': keep if _n == 1
                    quietly merge 1:1 `iid' using `meta', keep(match) nogen

                    quietly gen byte __eligible_control = ///
                        (__never == 1 | ///
                        (__treated == 1 & __lower > `t')) ///
                        & `iid' != `ii'

                    quietly gen double __control_change = `target' - `base' ///
                        if __eligible_control == 1 ///
                        & `nobs' == 2 ///
                        & !missing(`base', `target')

                    quietly summarize __control_change, meanonly
                    local nctrl = r(N)

                    if `nctrl' > 0 {
                        scalar `sdc' = r(mean)
                        scalar `sq' = `sdy' - `sdc'
                        local supported = 1
                    }
                }

                post `ph' ///
                    (`ii') (`"`ILAB'"') ///
                    (`L') (`U') (`g') (`e') (`b') (`t') ///
                    (`sW') (`sdy') (`sdc') (`sq') ///
                    (`nctrl') (`supported') ///
                    (`g' == `L') (`g' == `U')
            }
        }
    }

    quietly postclose `ph'

    quietly use `candidates', clear
    quietly isid unit_id candidate_date event_time
    assert supported == !missing(contrast)

    if `"`detail'"' != "" {
        if "`replace'" != "" quietly save `"`detail'"', replace
        else quietly save `"`detail'"'

        capture confirm file `"`detail'"'
        if _rc {
            restore
            di as error "detail() file was not created:"
            di as error `"`detail'"'
            exit 603
        }
    }

    * Sort on a unique within-cell key before any by-group calculations.
    * This prevents Stata's randomized tie ordering from selecting a different
    * candidate row across clean sessions.
    quietly sort unit_id event_time candidate_date
    quietly by unit_id event_time: egen int candidates_expected = ///
        max(upper - lower + 1)
    quietly by unit_id event_time: egen int candidates_supported = ///
        total(supported)

    quietly gen byte full_candidate_support = ///
        candidates_supported == candidates_expected

    quietly by unit_id event_time: egen double state_lower = min(contrast)
    quietly by unit_id event_time: egen double state_upper = max(contrast)
    quietly by unit_id event_time: egen double earliest_contrast = ///
        max(cond(candidate_is_earliest == 1, contrast, .))
    quietly by unit_id event_time: egen double latest_contrast = ///
        max(cond(candidate_is_latest == 1, contrast, .))
    quietly by unit_id event_time: egen int controls_min = ///
        min(cond(supported == 1, n_controls, .))
    quietly by unit_id event_time: egen int controls_max = ///
        max(cond(supported == 1, n_controls, .))

    quietly by unit_id event_time: keep if _n == 1
    quietly keep if full_candidate_support == 1

    if _N == 0 {
        restore
        di as error "No event-time cells have full candidate-date support."
        exit 2001
    }

    quietly gen double state_width = state_upper - state_lower
    assert state_lower <= state_upper
    quietly save `states'

    * Fix the summation order explicitly so repeated runs are bitwise stable.
    quietly sort event_time unit_id
    quietly by event_time: egen double total_weight = total(analysis_weight)
    quietly gen double normalized_weight = analysis_weight / total_weight

    quietly gen double lower_component = normalized_weight * state_lower
    quietly gen double upper_component = normalized_weight * state_upper
    quietly gen double earliest_component = normalized_weight * earliest_contrast
    quietly gen double latest_component = normalized_weight * latest_contrast

    quietly by event_time: egen double envelope_lower = total(lower_component)
    quietly by event_time: egen double envelope_upper = total(upper_component)
    quietly by event_time: egen double all_earliest = total(earliest_component)
    quietly by event_time: egen double all_latest = total(latest_component)
    quietly by event_time: egen int treated_units = count(unit_id)
    quietly by event_time: egen int aggregate_controls_min = min(controls_min)
    quietly by event_time: egen int aggregate_controls_max = max(controls_max)

    quietly by event_time: keep if _n == 1
    quietly gen double envelope_width = envelope_upper - envelope_lower
    quietly gen byte envelope_contains_zero = ///
        envelope_lower <= 0 & envelope_upper >= 0

    quietly keep event_time treated_units envelope_lower envelope_upper ///
        envelope_width envelope_contains_zero all_earliest all_latest ///
        aggregate_controls_min aggregate_controls_max
    quietly order event_time treated_units envelope_lower envelope_upper ///
        envelope_width envelope_contains_zero all_earliest all_latest ///
        aggregate_controls_min aggregate_controls_max

    quietly sort event_time
    quietly isid event_time
    quietly save `aggregates'

    if `"`saving'"' != "" {
        if "`replace'" != "" quietly save `"`saving'"', replace
        else quietly save `"`saving'"'

        capture confirm file `"`saving'"'
        if _rc {
            restore
            di as error "saving() file was not created:"
            di as error `"`saving'"'
            exit 603
        }
    }

    tempname E
    quietly mkmat event_time treated_units envelope_lower envelope_upper ///
        envelope_width all_earliest all_latest ///
        aggregate_controls_min aggregate_controls_max, matrix(`E')
    matrix colnames `E' = ///
        event treated_units lower upper width all_earliest all_latest ///
        controls_min controls_max

    * Store dimensions before posting the temporary matrix to r().
    * return matrix may rename/consume a tempname, so rowsof() must be
    * evaluated first.
    local n_supported_events = rowsof(`E')

    di as text ""
    di as result "Timing-uncertainty contrast envelopes"
    di as text "These are numerical envelopes over feasible adoption dates."
    di as text "They are not automatically causal treatment-effect bounds."
    list event_time treated_units envelope_lower envelope_upper ///
        envelope_width all_earliest all_latest, ///
        noobs abbreviate(20)

    restore

    * Set returned results only after restore and all display commands.
    * Nothing r-class is called after these lines.
    return scalar N_treated = `ntreated'
    return scalar N_supported_events = `n_supported_events'
    return local command "itdidbounds"
    return local interpretation ///
        "timing-uncertainty contrast envelope; not automatically causal"
    return matrix envelope = `E'
end
