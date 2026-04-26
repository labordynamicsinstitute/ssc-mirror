*! version 1.1  20apr2026  Kelvin Law
*! Converts ISIC codes to Fama-French industry classifications
*! Supports ISIC Revision 4 in this release
*! Uses official Census ISIC4->NAICS17 bridge + naics_to_ff/sic_to_ff stack

program isic_to_ff, rclass sortpreserve
    version 14.0

    syntax varname [if] [in], GENerate(name) ///
        [SCHeme(string) REVision(string) LABels REPlace DIAGnostics ///
         TIEgen(name) UNRESOLVEDgen(name)]

    local isicvar "`varlist'"

    _isic_check_dependencies "`labels'"

    if "`scheme'" == "" local scheme "48"
    if !inlist("`scheme'", "5", "10", "12", "17", "30", "38", "48", "49") {
        display as error "scheme() must be one of: 5, 10, 12, 17, 30, 38, 48, or 49"
        exit 198
    }

    if "`revision'" == "" local revision "4"
    if inlist("`revision'", "2", "3", "3.1") {
        display as error "revision(`revision') is planned for a future release."
        display as error "This version currently supports revision(4) only."
        exit 198
    }
    if "`revision'" != "4" {
        display as error "revision() must be 4 in this release"
        exit 198
    }

    * Block destructive name collisions before any variable operations
    if "`generate'" == "`isicvar'" {
        display as error "generate() must differ from the input ISIC variable"
        display as error "You specified: generate(`generate') on variable `isicvar'"
        exit 198
    }
    if "`tiegen'" != "" & "`tiegen'" == "`isicvar'" {
        display as error "tiegen() must differ from the input ISIC variable"
        exit 198
    }
    if "`unresolvedgen'" != "" & "`unresolvedgen'" == "`isicvar'" {
        display as error "unresolvedgen() must differ from the input ISIC variable"
        exit 198
    }
    if "`tiegen'" != "" & "`tiegen'" == "`generate'" {
        display as error "tiegen() must differ from generate()"
        exit 198
    }
    if "`unresolvedgen'" != "" & "`unresolvedgen'" == "`generate'" {
        display as error "unresolvedgen() must differ from generate()"
        exit 198
    }
    if "`tiegen'" != "" & "`unresolvedgen'" != "" & "`tiegen'" == "`unresolvedgen'" {
        display as error "tiegen() and unresolvedgen() must have different names"
        exit 198
    }
    foreach reservedname in ff_plurality tie_top top_count second_count unresolved {
        foreach optname in generate tiegen unresolvedgen {
            if "``optname''" == "`reservedname'" {
                display as error "`optname'(`reservedname') uses a reserved internal name"
                display as error "Please choose a different variable name"
                exit 198
            }
        }
    }

    * Validate bridge/lookup assets before any destructive operations
    capture findfile isic4_naics17_bridge.dta
    if _rc != 0 {
        display as error "Could not locate isic4_naics17_bridge.dta on adopath"
        exit 601
    }
    capture findfile naics_sic_lookup.dta
    if _rc != 0 {
        display as error "Could not locate naics_sic_lookup.dta on adopath"
        exit 601
    }

    capture confirm variable `generate'
    if _rc == 0 {
        if "`replace'" == "" {
            display as error "variable `generate' already exists"
            display as error "use replace option to overwrite"
            exit 110
        }
        drop `generate'
    }

    marksample touse, novarlist

    tempvar isic_num isic_clean isic_raw
    local n_parse_failed = 0
    local n_fractional = 0

    capture confirm string variable `isicvar'
    if _rc == 0 {
        quietly generate str20 `isic_clean' = trim(`isicvar') if `touse'
        quietly replace `isic_clean' = "" if `touse' & regexm(`isic_clean', "^\.[a-z]?$")
        quietly replace `isic_clean' = subinstr(`isic_clean', " ", "", .) if `touse'
        quietly replace `isic_clean' = subinstr(`isic_clean', ",", "", .) if `touse'
        quietly replace `isic_clean' = subinstr(`isic_clean', "-", "", .) if `touse'
        quietly replace `isic_clean' = subinstr(`isic_clean', ".", "", .) if `touse'
        quietly replace `isic_clean' = subinstr(`isic_clean', char(9), "", .) if `touse'

        quietly generate double `isic_raw' = real(`isic_clean') if `touse'
        quietly count if `touse' & `isic_clean' != "" & `isic_raw' >= .
        local n_parse_failed = r(N)

        quietly count if `touse' & `isic_raw' < . & floor(`isic_raw') != `isic_raw'
        local n_fractional = r(N)
        if `n_fractional' > 0 {
            display as error "isic_to_ff does not accept fractional numeric ISIC values"
            display as error "Keep formatted ISIC values as strings or pre-clean them to valid class-level integers"
            exit 198
        }

        quietly generate long `isic_num' = `isic_raw' if `touse'
        drop `isic_clean' `isic_raw'
    }
    else {
        quietly count if `touse' & `isicvar' < . & floor(`isicvar') != `isicvar'
        local n_fractional = r(N)
        if `n_fractional' > 0 {
            display as error "isic_to_ff does not accept fractional numeric ISIC values"
            display as error "Keep formatted ISIC values as strings or pre-clean them to valid class-level integers"
            exit 198
        }
        quietly generate long `isic_num' = `isicvar' if `touse'
    }

    * ISIC Rev.4 classes may include leading zeros in string form (e.g., 0111),
    * which become numeric 111 after conversion. Accept class-level values only:
    * 3-4 digits after numeric normalization (100-9999).
    quietly replace `isic_num' = . if `touse' & (`isic_num' < 100 | `isic_num' > 9999)

    tempfile bridge_map plurality_map
    _isic_to_naics_bridge "`bridge_map'" "`revision'"
    _isic_build_plurality_map "`bridge_map'" "`scheme'" "`plurality_map'"

    * Rebuild caller tempvars if a preserve/restore path cleared them.
    capture confirm variable `touse'
    if _rc != 0 {
        marksample touse, novarlist
    }
    capture confirm variable `isic_num'
    if _rc != 0 {
        capture confirm string variable `isicvar'
        if _rc == 0 {
            tempvar __recover_clean __recover_raw
            quietly generate str20 `__recover_clean' = trim(`isicvar') if `touse'
            quietly replace `__recover_clean' = "" if `touse' & regexm(`__recover_clean', "^\.[a-z]?$")
            quietly replace `__recover_clean' = subinstr(`__recover_clean', " ", "", .) if `touse'
            quietly replace `__recover_clean' = subinstr(`__recover_clean', ",", "", .) if `touse'
            quietly replace `__recover_clean' = subinstr(`__recover_clean', "-", "", .) if `touse'
            quietly replace `__recover_clean' = subinstr(`__recover_clean', char(9), "", .) if `touse'
            quietly generate double `__recover_raw' = real(`__recover_clean') if `touse'
            quietly generate long `isic_num' = `__recover_raw' if `touse'
            drop `__recover_clean' `__recover_raw'
        }
        else {
            quietly generate long `isic_num' = `isicvar' if `touse'
        }
        quietly replace `isic_num' = . if `touse' & (`isic_num' < 100 | `isic_num' > 9999)
    }

    tempvar isic_key __isic_ff __isic_tie __isic_unresolved __isic_top __isic_second
    tempfile plurality_merge
    quietly gen long `isic_key' = `isic_num' if `touse'
    quietly {
        preserve
        use "`plurality_map'", clear
        rename isic4 `isic_key'
        rename ff_plurality `__isic_ff'
        rename tie_top `__isic_tie'
        rename top_count `__isic_top'
        rename second_count `__isic_second'
        rename unresolved `__isic_unresolved'
        save "`plurality_merge'", replace
        restore
    }
    quietly merge m:1 `isic_key' using `plurality_merge', keep(master match) nogenerate

    * Valid class-level ISIC codes that are absent from the shipped bridge
    * should be treated as unresolved, not as malformed input.
    quietly replace `__isic_tie' = 0 if `touse' & `isic_num' < . & missing(`__isic_tie')
    quietly replace `__isic_top' = 0 if `touse' & `isic_num' < . & missing(`__isic_top')
    quietly replace `__isic_second' = 0 if `touse' & `isic_num' < . & missing(`__isic_second')
    quietly replace `__isic_unresolved' = 1 if `touse' & `isic_num' < . & missing(`__isic_unresolved')

    quietly generate long `generate' = . if `touse'
    quietly replace `generate' = `__isic_ff' if `touse' & `__isic_ff' < .

    if "`tiegen'" != "" {
        capture confirm variable `tiegen'
        if _rc == 0 {
            if "`replace'" == "" {
                display as error "variable `tiegen' already exists; use replace option"
                exit 110
            }
            drop `tiegen'
        }
        quietly generate byte `tiegen' = `__isic_tie' if `touse'
        label variable `tiegen' "1 if ISIC plurality tie prevented FF assignment"
    }

    if "`unresolvedgen'" != "" {
        capture confirm variable `unresolvedgen'
        if _rc == 0 {
            if "`replace'" == "" {
                display as error "variable `unresolvedgen' already exists; use replace option"
                exit 110
            }
            drop `unresolvedgen'
        }
        quietly generate byte `unresolvedgen' = `__isic_unresolved' if `touse'
        label variable `unresolvedgen' "1 if ISIC had no FF assignment (including plurality ties)"
    }

    if "`labels'" != "" {
        _isic_apply_ff_labels `generate' `scheme'
    }

    quietly count if `touse'
    local n_total = r(N)
    quietly count if `touse' & `isic_num' < .
    local n_with_isic = r(N)
    quietly count if `touse' & `generate' < .
    local n_mapped = r(N)
    quietly count if `touse' & `__isic_tie' == 1
    local n_tied = r(N)
    quietly count if `touse' & `__isic_unresolved' == 1
    local n_unresolved = r(N)

    local map_rate = 0
    if `n_with_isic' > 0 {
        local map_rate = 100 * `n_mapped' / `n_with_isic'
    }

    if `n_parse_failed' > 0 {
        display as text "  Warning: " as result `n_parse_failed' as text " observations have non-numeric ISIC values (ignored)"
    }

    display as text ""
    display as text "{hline 60}"
    display as text "Fama-French `scheme'-industry classification from ISIC Rev. `revision': " as result "`generate'"
    display as text "{hline 60}"
    display as text "Observations in sample:           " as result %10.0fc `n_total'
    display as text "Observations with ISIC code:      " as result %10.0fc `n_with_isic'
    display as text "Mapped to FF`scheme':               " as result %10.0fc `n_mapped' ///
        as text " (" as result %5.1f `map_rate' as text "%)"
    display as text "Plurality ties (missing result):  " as result %10.0fc `n_tied'
    display as text "Unresolved ISIC codes:            " as result %10.0fc `n_unresolved'
    display as text "{hline 60}"

    if "`diagnostics'" != "" {
        display as text ""
        display as text "{hline 60}"
        display as text "Diagnostics: ISIC bridge outcomes"
        display as text "{hline 60}"
        quietly count if `touse' & `__isic_top' > 0
        display as text "ISIC with at least one FF link:   " as result %10.0fc r(N)
        quietly count if `touse' & `__isic_tie' == 0 & `__isic_top' > 0
        display as text "Plurality-resolved assignments:   " as result %10.0fc r(N)
        quietly count if `touse' & `__isic_tie' == 1
        display as text "Tie-blocked assignments:          " as result %10.0fc r(N)
        quietly count if `touse' & `__isic_top' == 0
        display as text "No FF link in bridge:             " as result %10.0fc r(N)
        display as text "{hline 60}"
    }

    drop `isic_key' `__isic_ff' `__isic_tie' `__isic_unresolved' `__isic_top' `__isic_second'

    return scalar N = `n_total'
    return scalar N_isic = `n_with_isic'
    return scalar N_ff_mapped = `n_mapped'
    return scalar N_tie = `n_tied'
    return scalar N_unresolved = `n_unresolved'
    return scalar ff_map_rate = `map_rate'
    return local scheme "`scheme'"
    return local revision "`revision'"
    return local varname "`generate'"
end

program _isic_check_dependencies
    args labels_opt

    capture which sic_to_ff
    if _rc != 0 {
        display as error "isic_to_ff requires sic_to_ff to be installed"
        display as error "Install sic_to_ff version 1.1 or later, then re-run isic_to_ff"
        exit 111
    }
    local __sic_path "`r(which)'"
    if "`__sic_path'" == "" local __sic_path "`r(fn)'"
    if "`__sic_path'" == "" {
        quietly capture findfile sic_to_ff.ado
        if _rc == 0 local __sic_path "`r(fn)'"
    }
    if "`__sic_path'" == "" {
        display as error "isic_to_ff could not locate sic_to_ff.ado on adopath"
        exit 111
    }

    local __sic_major = 0
    local __sic_minor = 0
    local __scan_done = 0
    tempname __fh
    capture file open `__fh' using "`__sic_path'", read text
    if _rc == 0 {
        forvalues __i = 1/20 {
            if `__scan_done' == 0 {
                file read `__fh' __line
                if r(eof) {
                    local __scan_done = 1
                }
                else {
                    local __pos = strpos(`"`__line'"', "*! version ")
                    if `__pos' >= 1 {
                        local __verstr = substr(`"`__line'"', `__pos' + 11, .)
                        local __dotpos = strpos("`__verstr'", ".")
                        if `__dotpos' > 0 {
                            local __sic_major = substr("`__verstr'", 1, `__dotpos' - 1)
                            local __after_dot = substr("`__verstr'", `__dotpos' + 1, .)
                            local __spacepos = strpos("`__after_dot'", " ")
                            if `__spacepos' > 0 {
                                local __sic_minor = substr("`__after_dot'", 1, `__spacepos' - 1)
                            }
                            else {
                                local __sic_minor = "`__after_dot'"
                            }
                            local __dotpos2 = strpos("`__sic_minor'", ".")
                            if `__dotpos2' > 0 {
                                local __sic_minor = substr("`__sic_minor'", 1, `__dotpos2' - 1)
                            }
                            local __scan_done = 1
                        }
                    }
                }
            }
        }
        file close `__fh'
    }

    local __version_ok = 0
    if `__sic_major' > 1 {
        local __version_ok = 1
    }
    else if `__sic_major' == 1 & `__sic_minor' >= 1 {
        local __version_ok = 1
    }
    if `__version_ok' == 0 {
        display as error "isic_to_ff requires sic_to_ff version 1.1 or later"
        exit 111
    }

    if "`labels_opt'" != "" {
        capture which naics_to_ff
        if _rc != 0 {
            display as error "isic_to_ff with labels requires naics_to_ff to be installed"
            display as error "Install naics_to_ff, then re-run isic_to_ff with labels"
            exit 111
        }
    }
end

program _isic_to_naics_bridge
    args out_bridge revision

    if "`revision'" == "4" {
        _isic4_to_naics_bridge "`out_bridge'"
        exit
    }
    if inlist("`revision'", "2", "3", "3.1") {
        display as error "revision(`revision') is planned for a future release."
        display as error "This version currently supports revision(4) only."
        exit 198
    }
    display as error "Unsupported ISIC revision: `revision'"
    exit 198
end

program _isic4_to_naics_bridge
    args out_bridge

    capture findfile isic4_naics17_bridge.dta
    if _rc != 0 {
        display as error "Could not locate isic4_naics17_bridge.dta on adopath"
        exit 601
    }

    preserve
    capture noisily {
        use "`r(fn)'", clear
        foreach v in isic4 naics17 {
            capture confirm variable `v'
            if _rc != 0 {
                display as error "ISIC bridge file missing required column: `v'"
                exit 610
            }
        }
        * Keep class-level Rev.4 numeric keys only; allow values like 111 (i.e., 0111)
        * and exclude known group-level artifacts such as 12 and 14.
        quietly keep if isic4 >= 100 & isic4 <= 9999
        quietly keep if naics17 >= 100000 & naics17 <= 999999
        quietly rename naics17 naics
        quietly keep isic4 naics
        quietly save "`out_bridge'", replace
    }
    local __bridge_rc = _rc
    restore
    if `__bridge_rc' != 0 {
        exit `__bridge_rc'
    }
end

program _isic_naics_lookup_path, rclass
    capture findfile naics_sic_lookup.dta
    if _rc == 0 {
        return local path "`r(fn)'"
        exit
    }
    display as error "Could not locate NAICS lookup data file on adopath."
    display as error "Expected: naics_sic_lookup.dta"
    exit 601
end

program _isic_build_plurality_map
    args bridge_file scheme out_map

    tempfile naics_ff top_ff all_isic

    preserve
    capture noisily {
        _isic_naics_lookup_path
        use "`r(path)'", clear

        * Auxiliary SIC placeholders cannot be fed into sic_to_ff directly
        quietly replace sic = . if sic > 9999 | sic < 0
        tempvar ffcode
        quietly sic_to_ff sic, generate(`ffcode') scheme(`scheme') replace
        keep naics `ffcode'
        rename `ffcode' ff_code
        quietly save `naics_ff', replace
    }
    local __naics_ff_rc = _rc
    restore
    if `__naics_ff_rc' != 0 {
        exit `__naics_ff_rc'
    }

    preserve
    capture noisily {
        quietly {
            use "`bridge_file'", clear
            keep isic4
            duplicates drop
            save `all_isic', replace
        }
    }
    local __all_isic_rc = _rc
    restore
    if `__all_isic_rc' != 0 {
        exit `__all_isic_rc'
    }

    preserve
    capture noisily {
        quietly {
            use "`bridge_file'", clear
            merge m:1 naics using `naics_ff', keep(master match) nogenerate

            keep if ff_code < .
            if _N > 0 {
                contract isic4 ff_code, freq(link_count)
                gsort isic4 -link_count ff_code
                by isic4: gen rank = _n
                by isic4: gen top_count = link_count[1]
                by isic4: gen second_count = link_count[2]
                keep if rank == 1
                gen byte tie_top = (second_count == top_count & second_count < .)
                gen long ff_plurality = ff_code
                replace ff_plurality = . if tie_top == 1
                keep isic4 ff_plurality tie_top top_count second_count
                tempfile top_map
                save `top_map', replace

                use `all_isic', clear
                merge 1:1 isic4 using `top_map', keep(master match) nogenerate
            }
            else {
                use `all_isic', clear
                gen long ff_plurality = .
                gen byte tie_top = 0
                gen long top_count = 0
                gen long second_count = 0
            }

            replace tie_top = 0 if missing(tie_top)
            replace top_count = 0 if missing(top_count)
            replace second_count = 0 if missing(second_count)
            gen byte unresolved = missing(ff_plurality)
            save "`out_map'", replace
        }
    }
    local __plurality_rc = _rc
    restore
    if `__plurality_rc' != 0 {
        exit `__plurality_rc'
    }
end

program _isic_apply_ff_labels
    args outvar scheme

    preserve
    capture noisily {
        clear
        set obs 1
        gen long __n2f_label_naics = 111110
        quietly naics_to_ff __n2f_label_naics, generate(__n2f_label_ff) scheme(`scheme') labels replace
        local __lblname : value label __n2f_label_ff
    }
    local __lbl_rc = _rc
    restore
    if `__lbl_rc' != 0 {
        exit `__lbl_rc'
    }
    if "`__lblname'" != "" {
        label values `outvar' `__lblname'
    }
end
