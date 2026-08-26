*! version 1.0.0 23aug2026
program define nestrecover, rclass
    version 16.0

    syntax [using/] [, LIST INSPECT ADOPT CONFIRM(string)]

    local modes = ("`list'" != "") + ("`inspect'" != "") + ("`adopt'" != "")
    local automatic = (`modes' == 0 & `"`using'"' == "")
    if `modes' == 0 & !`automatic' local list "list"
    if `modes' > 1 {
        di as error "specify only one of list, inspect, or adopt"
        exit 198
    }

    if `automatic' {
        if "${NESTPRESERVE_depth}" != "" | "${NESTPRESERVE_session}" != "" {
            di as error "an active NESTPRESERVE session already exists"
            exit 498
        }
        local tmpdir `"`c(tmpdir)'"'
        mata: np_f = dir(st_local("tmpdir"), "files", ///
            "nestpreserve_*.manifest"); ///
            st_local("np_manifests", rows(np_f) == 0 ? "" : ///
            invtokens(vec(np_f)'))
        local dead_count 0
        local live_count 0
        local refused_count 0
        foreach filename of local np_manifests {
            local candidate `"`tmpdir'`filename'"'
            capture quietly nestrecover using `"`candidate'"', inspect
            if _rc {
                local ++refused_count
                continue
            }
            local version = r(manifest_version)
            local candidate_files = r(files_ok)
            local candidate_audit = r(audit_ok)
            local candidate_session `"`r(session)'"'
            local candidate_pid `"`r(owner_pid)'"'
            local candidate_start `"`r(owner_start)'"'
            local candidate_host `"`r(owner_host)'"'
            local candidate_depth = r(depth)
            local candidate_top_file `"`r(file_`candidate_depth')'"'
            local candidate_top_signature `"`r(signature_`candidate_depth')'"'
            if `version' != 3 | !`candidate_files' | !`candidate_audit' {
                local ++refused_count
                continue
            }
            quietly _nestpreserve_process, action(check) pid(`candidate_pid') ///
                start(`candidate_start') host(`candidate_host')
            local status `"`r(status)'"'
            if `"`status'"' == "alive" local ++live_count
            else if `"`status'"' == "dead" {
                local ++dead_count
                local selected_manifest `"`candidate'"'
                local selected_session `"`candidate_session'"'
                local selected_top_file `"`candidate_top_file'"'
                local selected_top_signature `"`candidate_top_signature'"'
            }
            else local ++refused_count
        }

        if `dead_count' != 1 {
            di as error "automatic recovery refused"
            if `dead_count' == 0 {
                di as error "no uniquely safe crashed manifest was found"
            }
            else di as error "multiple safely recoverable manifests were found"
            return scalar recovered = 0
            return scalar candidates_dead = `dead_count'
            return scalar candidates_live = `live_count'
            return scalar candidates_refused = `refused_count'
            exit 498
        }

        /* Open and verify the actual snapshot in an isolated frame before
           adoption globals or the user's current data can change. */
        local original_frame `"`c(frame)'"'
        tempname validation_frame
        capture frame create `validation_frame'
        if _rc {
            di as error "automatic recovery could not create a validation frame"
            exit _rc
        }
        frame change `validation_frame'
        capture quietly use `"`selected_top_file'"', clear
        local validation_rc = _rc
        local actual_signature ""
        if !`validation_rc' {
            capture quietly datasignature
            local validation_rc = _rc
            if !`validation_rc' local actual_signature `"`r(datasignature)'"'
        }
        frame change `original_frame'
        frame drop `validation_frame'
        if `validation_rc' | ///
                `"`actual_signature'"' != `"`selected_top_signature'"' {
            di as error "automatic recovery refused: snapshot validation failed"
            exit 498
        }

        global NESTPRESERVE_internal_auto_adopt 1
        capture quietly nestrecover using `"`selected_manifest'"', ///
            adopt confirm(`selected_session')
        local adopt_rc = _rc
        if !`adopt_rc' local recovered_depth = r(depth)
        capture macro drop NESTPRESERVE_internal_auto_adopt
        if `adopt_rc' exit `adopt_rc'
        if "${NESTPRESERVE_internal_adopt_only}" == "1" {
            return scalar recovered = 1
            return scalar depth = `recovered_depth'
            return scalar candidates_dead = `dead_count'
            return scalar candidates_live = `live_count'
            return scalar candidates_refused = `refused_count'
            return local session `"`selected_session'"'
            return local manifest `"`selected_manifest'"'
            exit
        }
        capture quietly nestrestore, preserve
        if _rc {
            local restore_rc = _rc
            di as error "automatic recovery could not load the latest checkpoint"
            exit `restore_rc'
        }
        return scalar recovered = 1
        return scalar depth = `recovered_depth'
        return scalar candidates_dead = `dead_count'
        return scalar candidates_live = `live_count'
        return scalar candidates_refused = `refused_count'
        return local session `"`selected_session'"'
        return local manifest `"`selected_manifest'"'
        di as result "latest crashed checkpoint recovered"
        exit
    }

    if "`list'" != "" {
        if `"`using'"' != "" {
            di as error "using is not allowed with list"
            exit 198
        }
        local tmpdir `"`c(tmpdir)'"'
        mata: np_f = dir(st_local("tmpdir"), "files", ///
            "nestpreserve_*.manifest"); ///
            st_local("np_manifests", rows(np_f) == 0 ? "" : ///
            invtokens(vec(np_f)'))
        local count 0
        foreach filename of local np_manifests {
            local ++count
            di as text `"`tmpdir'`filename'"'
            return local manifest_`count' `"`tmpdir'`filename'"'
        }
        return scalar count = `count'
        exit
    }

    if `"`using'"' == "" {
        di as error "a manifest filename is required"
        exit 198
    }
    confirm file `"`using'"'

    file open np_recover_in using `"`using'"', read text
    file read np_recover_in line
    local manifest_version 0
    if `"`line'"' == "NESTPRESERVE_MANIFEST|1" local manifest_version 1
    else if `"`line'"' == "NESTPRESERVE_MANIFEST|2" local manifest_version 2
    else if `"`line'"' == "NESTPRESERVE_MANIFEST|3" local manifest_version 3
    if r(eof) | `manifest_version' == 0 {
        file close np_recover_in
        di as error "not a supported NESTPRESERVE manifest"
        exit 498
    }

    file read np_recover_in line
    if r(eof) | substr(`"`line'"', 1, 8) != "SESSION|" {
        file close np_recover_in
        di as error "manifest session record is missing or malformed"
        exit 498
    }
    local session = substr(`"`line'"', 9, .)
    if !regexm("`session'", "^[0-9]+_[0-9]+$") {
        file close np_recover_in
        di as error "manifest session identifier is invalid"
        exit 498
    }

    local norm_using = lower(subinstr(`"`using'"', "\", "/", .))
    local expected_manifest `"`c(tmpdir)'nestpreserve_`session'.manifest"'
    local norm_expected = lower(subinstr(`"`expected_manifest'"', "\", "/", .))
    if `"`norm_using'"' != `"`norm_expected'"' {
        file close np_recover_in
        di as error "manifest path does not match its declared session"
        exit 498
    }

    local depth 0
    local orphan_count 0
    local files_ok 1
    file read np_recover_in line
    local owner_pid ""
    local owner_start ""
    local owner_host ""
    if `manifest_version' == 3 {
        tokenize `"`line'"', parse("|")
        if "`1'" != "OWNER" | missing(real("`3'")) | ///
                missing(real("`5'")) | `"`7'"' == "" {
            file close np_recover_in
            di as error "manifest owner record is missing or malformed"
            exit 498
        }
        local owner_pid "`3'"
        local owner_start "`5'"
        local owner_host `"`7'"'
        file read np_recover_in line
    }
    while !r(eof) {
        if `"`line'"' != "" {
            tokenize `"`line'"', parse("|")
            if "`1'" == "ACTIVE" {
                local level = real("`3'")
                local saved_N = real("`7'")
                local saved_k = real("`9'")
                local filename `"`11'"'
                if missing(`level') | `level' != `depth' + 1 | ///
                        missing(`saved_N') | missing(`saved_k') | `"`5'"' == "" {
                    file close np_recover_in
                    di as error "manifest contains malformed or noncontiguous active levels"
                    exit 498
                }
                local expected_file `"`c(tmpdir)'nestpreserve_`session'_`level'.dta"'
                local norm_file = lower(subinstr(`"`filename'"', "\", "/", .))
                local norm_expected_file = lower(subinstr(`"`expected_file'"', "\", "/", .))
                if `"`norm_file'"' != `"`norm_expected_file'"' {
                    file close np_recover_in
                    di as error "manifest snapshot path failed ownership validation"
                    exit 498
                }
                local ++depth
                local active_frame_`level' `"`5'"'
                local active_N_`level' `saved_N'
                local active_k_`level' `saved_k'
                local active_file_`level' `"`filename'"'
                if `manifest_version' >= 2 {
                    local created `"`13'"'
                    local signature `"`15'"'
                    local vars_encoded `"`17'"'
                    local vars = subinstr(`"`vars_encoded'"', ",", " ", .)
                    if missing(real("`created'")) | `"`signature'"' == "" {
                        file close np_recover_in
                        di as error "manifest contains malformed checkpoint audit metadata"
                        exit 498
                    }
                    local active_created_`level' `"`created'"'
                    local active_signature_`level' `"`signature'"'
                    local active_vars_`level' `"`vars'"'
                }
                else {
                    local active_created_`level' "0"
                    local active_signature_`level' "legacy-unavailable"
                    local active_vars_`level' ""
                }
                capture confirm file `"`filename'"'
                local active_ok_`level' = (_rc == 0)
                if !`active_ok_`level'' local files_ok 0
            }
            else if "`1'" == "ORPHAN" {
                local index = real("`3'")
                local erase_rc = real("`5'")
                local filename `"`7'"'
                if missing(`index') | `index' != `orphan_count' + 1 | ///
                        missing(`erase_rc') {
                    file close np_recover_in
                    di as error "manifest contains malformed orphan records"
                    exit 498
                }
                local expected_prefix `"`c(tmpdir)'nestpreserve_`session'_"'
                local norm_file = lower(subinstr(`"`filename'"', "\", "/", .))
                local norm_prefix = lower(subinstr(`"`expected_prefix'"', "\", "/", .))
                if substr(`"`norm_file'"', 1, length(`"`norm_prefix'"')) != ///
                        `"`norm_prefix'"' | substr(`"`norm_file'"', -4, 4) != ".dta" {
                    file close np_recover_in
                    di as error "manifest orphan path failed ownership validation"
                    exit 498
                }
                local ++orphan_count
                local orphan_file_`orphan_count' `"`filename'"'
                local orphan_rc_`orphan_count' `erase_rc'
            }
            else {
                file close np_recover_in
                di as error "manifest contains an unknown record type"
                exit 498
            }
        }
        file read np_recover_in line
    }
    file close np_recover_in

    if `depth' == 0 & `orphan_count' == 0 {
        di as error "manifest contains no recoverable records"
        exit 498
    }

    local audit_ok 0
    local recovered_audit `"`c(tmpdir)'nestpreserve_`session'.audit"'
    capture confirm file `"`recovered_audit'"'
    if !_rc {
        capture file close np_recover_audit
        capture file open np_recover_audit using `"`recovered_audit'"', read text
        if !_rc {
            file read np_recover_audit audit_line
            local audit_header_ok = (`"`audit_line'"' == "NESTPRESERVE_AUDIT|1")
            file read np_recover_audit audit_line
            local audit_session_ok = (`"`audit_line'"' == "SESSION|`session'")
            local last_state_depth .
            file read np_recover_audit audit_line
            while !r(eof) {
                if substr(`"`audit_line'"', 1, 9) == "PRESERVE|" | ///
                        substr(`"`audit_line'"', 1, 8) == "RESTORE|" {
                    tokenize `"`audit_line'"', parse("|")
                    local last_state_depth = real("`7'")
                }
                file read np_recover_audit audit_line
            }
            file close np_recover_audit
            local audit_ok = (`audit_header_ok' & `audit_session_ok' & ///
                !missing(`last_state_depth') & `last_state_depth' == `depth')
        }
    }

    if "`adopt'" != "" {
        if "${NESTPRESERVE_depth}" != "" | "${NESTPRESERVE_session}" != "" {
            di as error "an active NESTPRESERVE session already exists"
            exit 498
        }
        if "`confirm'" != "`session'" {
            di as error "adoption requires confirm(`session')"
            di as error "confirm only after verifying that the originating Stata session ended"
            exit 198
        }
        global NESTPRESERVE_session "`session'"
        global NESTPRESERVE_manifest `"`using'"'
        if `manifest_version' == 3 {
            global NESTPRESERVE_owner_pid "`owner_pid'"
            global NESTPRESERVE_owner_start "`owner_start'"
            global NESTPRESERVE_owner_host `"`owner_host'"'
        }
        capture confirm file `"`recovered_audit'"'
        if !_rc {
            global NESTPRESERVE_audit `"`recovered_audit'"'
            global NESTPRESERVE_last_audit `"`recovered_audit'"'
        }
        if `depth' > 0 {
            forvalues level = 1/`depth' {
                global NESTPRESERVE_file_`level' `"`active_file_`level''"'
                global NESTPRESERVE_frame_`level' `"`active_frame_`level''"'
                global NESTPRESERVE_N_`level' "`active_N_`level''"
                global NESTPRESERVE_k_`level' "`active_k_`level''"
                global NESTPRESERVE_source_filename_`level' ""
                global NESTPRESERVE_source_filedate_`level' ""
                global NESTPRESERVE_source_changed_`level' 0
                global NESTPRESERVE_created_`level' `"`active_created_`level''"'
                global NESTPRESERVE_signature_`level' `"`active_signature_`level''"'
                global NESTPRESERVE_vars_`level' `"`active_vars_`level''"'
            }
            global NESTPRESERVE_depth `depth'
        }
        if `orphan_count' > 0 {
            forvalues orphan = 1/`orphan_count' {
                global NESTPRESERVE_orphan_file_`orphan' `"`orphan_file_`orphan''"'
                global NESTPRESERVE_orphan_rc_`orphan' "`orphan_rc_`orphan''"
            }
            global NESTPRESERVE_orphan_count `orphan_count'
        }
        return scalar adopted = 1
        if "${NESTPRESERVE_internal_auto_adopt}" != "1" {
            di as error "warning: foreign manifest adopted by explicit session confirmation"
        }
    }
    else return scalar adopted = 0

    return scalar depth = `depth'
    return scalar orphan_count = `orphan_count'
    return scalar files_ok = `files_ok'
    return local session "`session'"
    return local manifest `"`using'"'
    return scalar manifest_version = `manifest_version'
    return scalar audit_ok = `audit_ok'
    return local owner_pid "`owner_pid'"
    return local owner_start "`owner_start'"
    return local owner_host `"`owner_host'"'
    if `depth' > 0 {
        forvalues level = 1/`depth' {
            return local file_`level' `"`active_file_`level''"'
            return local signature_`level' `"`active_signature_`level''"'
        }
    }
end
