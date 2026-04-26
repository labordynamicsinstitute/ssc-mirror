*! version 1.1  20apr2026  Kelvin Law
*! Converts NACE Rev. 2 codes to Fama-French industry classifications
*! Uses official NACE2->ISIC4 bridge + isic_to_ff pipeline

program nace_to_ff, rclass sortpreserve
    version 14.0

    syntax varname [if] [in], GENerate(name) ///
        [SCHeme(string) LABels REPlace DIAGnostics ///
         TIEgen(name) UNRESOLVEDgen(name)]

    local nacevar "`varlist'"

    capture which isic_to_ff
    if _rc != 0 {
        display as error "nace_to_ff requires isic_to_ff to be installed"
        display as error "Install it first, then re-run nace_to_ff"
        exit 111
    }
    capture which sic_to_ff
    if _rc != 0 {
        display as error "nace_to_ff requires sic_to_ff version 1.1 or later"
        display as error "Install sic_to_ff, then re-run nace_to_ff"
        exit 111
    }
    * Explicit version guard: parse sic_to_ff version header
    local __sic_path "`r(which)'"
    if "`__sic_path'" == "" local __sic_path "`r(fn)'"
    if "`__sic_path'" == "" {
        quietly capture findfile sic_to_ff.ado
        if _rc == 0 local __sic_path "`r(fn)'"
    }
    if "`__sic_path'" != "" {
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
            display as error "nace_to_ff requires sic_to_ff version 1.1 or later"
            display as error "Found version `__sic_major'.`__sic_minor'; please update sic_to_ff"
            exit 111
        }
    }
    if "`labels'" != "" {
        capture which naics_to_ff
        if _rc != 0 {
            display as error "nace_to_ff with labels requires naics_to_ff to be installed"
            display as error "Install naics_to_ff, then re-run nace_to_ff with labels"
            exit 111
        }
    }

    if "`scheme'" == "" local scheme "48"
    if !inlist("`scheme'", "5", "10", "12", "17", "30", "38", "48", "49") {
        display as error "scheme() must be one of: 5, 10, 12, 17, 30, 38, 48, or 49"
        exit 198
    }

    if "`generate'" == "`nacevar'" {
        display as error "generate() must differ from the input NACE variable"
        display as error "You specified: generate(`generate') on variable `nacevar'"
        exit 198
    }
    if "`tiegen'" != "" & "`tiegen'" == "`nacevar'" {
        display as error "tiegen() must differ from the input NACE variable"
        exit 198
    }
    if "`unresolvedgen'" != "" & "`unresolvedgen'" == "`nacevar'" {
        display as error "unresolvedgen() must differ from the input NACE variable"
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

    marksample touse, novarlist

    tempvar nace_num nace_clean nace_raw nace_key isic4_bridge no_bridge
    tempvar __nace_tie_internal __nace_unres_internal
    local n_parse_failed = 0
    local n_fractional = 0

    capture confirm string variable `nacevar'
    if _rc == 0 {
        quietly generate str20 `nace_clean' = trim(`nacevar') if `touse'
        quietly replace `nace_clean' = "" if `touse' & regexm(`nace_clean', "^\.[a-z]?$")
        quietly replace `nace_clean' = subinstr(`nace_clean', " ", "", .) if `touse'
        quietly replace `nace_clean' = subinstr(`nace_clean', ",", "", .) if `touse'
        quietly replace `nace_clean' = subinstr(`nace_clean', "-", "", .) if `touse'
        quietly replace `nace_clean' = subinstr(`nace_clean', ".", "", .) if `touse'
        quietly replace `nace_clean' = subinstr(`nace_clean', char(9), "", .) if `touse'

        quietly generate double `nace_raw' = real(`nace_clean') if `touse'
        quietly count if `touse' & `nace_clean' != "" & `nace_raw' >= .
        local n_parse_failed = r(N)

        quietly count if `touse' & `nace_raw' < . & floor(`nace_raw') != `nace_raw'
        local n_fractional = r(N)
        if `n_fractional' > 0 {
            display as error "nace_to_ff does not accept fractional numeric NACE values"
            display as error "Keep formatted NACE values as strings or pre-clean them to valid class-level integers"
            exit 198
        }

        quietly generate long `nace_num' = `nace_raw' if `touse'
        drop `nace_clean' `nace_raw'
    }
    else {
        quietly count if `touse' & `nacevar' < . & floor(`nacevar') != `nacevar'
        local n_fractional = r(N)
        if `n_fractional' > 0 {
            display as error "nace_to_ff does not accept fractional numeric NACE values"
            display as error "Keep formatted NACE values as strings or pre-clean them to valid class-level integers"
            exit 198
        }
        quietly generate long `nace_num' = `nacevar' if `touse'
    }

    * NACE Rev.2 classes may include leading zeros or dots in string form
    * (e.g., 01.11), which normalize to numeric class-level codes 100-9999.
    quietly replace `nace_num' = . if `touse' & (`nace_num' < 100 | `nace_num' > 9999)

    quietly count if `touse'
    local n_total = r(N)
    quietly count if `touse' & `nace_num' < .
    local n_with_nace = r(N)

    tempfile bridge_map bridge_merge
    _nace2_to_isic_bridge "`bridge_map'"

    quietly gen long `nace_key' = `nace_num' if `touse'
    quietly {
        preserve
        use "`bridge_map'", clear
        rename nace2 `nace_key'
        rename isic4 `isic4_bridge'
        save "`bridge_merge'", replace
        restore
    }
    quietly merge m:1 `nace_key' using "`bridge_merge'", keep(master match) nogenerate

    quietly generate byte `no_bridge' = `touse' & `nace_num' < . & missing(`isic4_bridge')
    quietly count if `no_bridge'
    local n_no_bridge = r(N)
    quietly count if `touse' & `isic4_bridge' < .
    local n_with_isic = r(N)

    local __tiegen_use "`tiegen'"
    local __unresolved_use "`unresolvedgen'"
    if "`__tiegen_use'" == "" local __tiegen_use "`__nace_tie_internal'"
    if "`__unresolved_use'" == "" local __unresolved_use "`__nace_unres_internal'"

    local __label_opt ""
    local __replace_opt ""
    local __diag_opt ""
    if "`labels'" != "" local __label_opt "labels"
    if "`replace'" != "" local __replace_opt "replace"
    if "`diagnostics'" != "" local __diag_opt "diagnostics"

    quietly isic_to_ff `isic4_bridge' if `touse', generate(`generate') ///
        scheme(`scheme') revision(4) `__label_opt' `__replace_opt' `__diag_opt' ///
        tiegen(`__tiegen_use') unresolvedgen(`__unresolved_use')

    if `n_no_bridge' > 0 {
        quietly replace `__tiegen_use' = 0 if `no_bridge'
        quietly replace `__unresolved_use' = 1 if `no_bridge'
    }

    quietly count if `touse' & `generate' < .
    local n_mapped = r(N)
    quietly count if `touse' & `__tiegen_use' == 1
    local n_tied = r(N)
    quietly count if `touse' & `__unresolved_use' == 1
    local n_unresolved = r(N)

    local map_rate = 0
    if `n_with_nace' > 0 {
        local map_rate = 100 * `n_mapped' / `n_with_nace'
    }

    if `n_parse_failed' > 0 {
        display as text "  Warning: " as result `n_parse_failed' as text " observations have non-numeric NACE values (ignored)"
    }

    display as text ""
    display as text "{hline 60}"
    display as text "Fama-French `scheme'-industry classification from NACE Rev. 2: " as result "`generate'"
    display as text "{hline 60}"
    display as text "Observations in sample:           " as result %10.0fc `n_total'
    display as text "Observations with NACE code:      " as result %10.0fc `n_with_nace'
    display as text "Mapped to FF`scheme':               " as result %10.0fc `n_mapped' ///
        as text " (" as result %5.1f `map_rate' as text "%)"
    display as text "Plurality ties (missing result):  " as result %10.0fc `n_tied'
    display as text "Unresolved NACE codes:            " as result %10.0fc `n_unresolved'
    display as text "{hline 60}"

    if "`diagnostics'" != "" {
        quietly count if `touse' & `__unresolved_use' == 1 & `__tiegen_use' == 0 & `no_bridge' == 0
        local n_downstream_unresolved = r(N)

        display as text ""
        display as text "{hline 60}"
        display as text "Diagnostics: NACE bridge outcomes"
        display as text "{hline 60}"
        display as text "NACE with ISIC bridge link:       " as result %10.0fc `n_with_isic'
        display as text "NACE without ISIC bridge link:    " as result %10.0fc `n_no_bridge'
        display as text "Tie-blocked assignments:          " as result %10.0fc `n_tied'
        display as text "No FF link after ISIC step:       " as result %10.0fc `n_downstream_unresolved'
        display as text "{hline 60}"
    }

    return scalar N = `n_total'
    return scalar N_nace = `n_with_nace'
    return scalar N_ff_mapped = `n_mapped'
    return scalar N_tie = `n_tied'
    return scalar N_unresolved = `n_unresolved'
    return scalar ff_map_rate = `map_rate'
    return local scheme "`scheme'"
    return local revision "4"
    return local nace_revision "2"
    return local varname "`generate'"
end

program _nace2_to_isic_bridge
    args out_bridge

    capture findfile nace2_isic4_bridge.dta
    if _rc != 0 {
        display as error "Could not locate nace2_isic4_bridge.dta on adopath"
        exit 601
    }

    preserve
    capture noisily {
        use "`r(fn)'", clear
        foreach v in nace2 isic4 {
            capture confirm variable `v'
            if _rc != 0 {
                display as error "NACE bridge file missing required column: `v'"
                exit 610
            }
        }
        quietly {
            keep if nace2 >= 100 & nace2 <= 9999
            keep if isic4 >= 100 & isic4 <= 9999
            keep nace2 isic4
            duplicates drop
            bysort nace2: gen __nace_count = _N
            count if __nace_count > 1
        }
        if r(N) > 0 {
            display as error "NACE bridge file has non-unique nace2 keys"
            exit 610
        }
        quietly {
            drop __nace_count
            sort nace2
            save "`out_bridge'", replace
        }
    }
    local __bridge_rc = _rc
    restore
    if `__bridge_rc' != 0 {
        exit `__bridge_rc'
    }
end
