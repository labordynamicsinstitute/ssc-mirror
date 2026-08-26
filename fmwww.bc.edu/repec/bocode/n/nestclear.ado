*! version 1.0.0 23aug2026
program define nestclear, rclass
    version 16.0

    syntax [, FORCE QUIET]

    /* With no adopted session, one-word cleanup may adopt exactly one v3
       candidate only after process-death and integrity checks. */
    if "${NESTPRESERVE_depth}" == "" & "${NESTPRESERVE_session}" == "" {
        quietly nestrecover, list
        local discovered = r(count)
        if `discovered' > 0 {
            global NESTPRESERVE_internal_adopt_only 1
            capture quietly nestrecover
            local recover_rc = _rc
            capture macro drop NESTPRESERVE_internal_adopt_only
            if `recover_rc' {
                di as error "automatic cleanup refused: no uniquely safe crashed session"
                exit `recover_rc'
            }
        }
    }

    local depth 0
    local depth_valid 1
    if "${NESTPRESERVE_depth}" != "" {
        local depth = real("${NESTPRESERVE_depth}")
        if missing(`depth') | `depth' < 0 | `depth' != floor(`depth') {
            local depth_valid 0
        }
    }

    if !`depth_valid' & "`force'" == "" {
        di as error "nestpreserve stack metadata are corrupted"
        di as error "specify force to remove recoverable package metadata"
        exit 498
    }

    local cleared 0
    local deleted 0
    local missing_files 0
    local failed 0
    local manifest_failures 0

    /* Work from the top down.  If a deletion fails without force, every
       remaining active level still forms a valid contiguous stack. */
    if `depth_valid' & `depth' > 0 {
        forvalues level = `depth'(-1)1 {
            local file_macro "NESTPRESERVE_file_`level'"
            local frame_macro "NESTPRESERVE_frame_`level'"
            local N_macro "NESTPRESERVE_N_`level'"
            local k_macro "NESTPRESERVE_k_`level'"
            local source_filename_macro "NESTPRESERVE_source_filename_`level'"
            local source_filedate_macro "NESTPRESERVE_source_filedate_`level'"
            local source_changed_macro "NESTPRESERVE_source_changed_`level'"
            local created_macro "NESTPRESERVE_created_`level'"
            local signature_macro "NESTPRESERVE_signature_`level'"
            local vars_macro "NESTPRESERVE_vars_`level'"
            local filename : copy global `file_macro'
            local frame : copy global `frame_macro'
            local saved_N : copy global `N_macro'
            local saved_k : copy global `k_macro'

            if `"`filename'"' == "" | `"`frame'"' == "" | ///
                    "`saved_N'" == "" | "`saved_k'" == "" {
                if "`force'" == "" {
                    di as error "nestpreserve stack metadata are corrupted at level `level'"
                    exit 498
                }
            }

            local file_ok 0
            if `"`filename'"' != "" {
                tempname exists
                mata: st_numscalar("`exists'", fileexists(st_local("filename")))
                local file_ok = scalar(`exists')
            }

            local can_pop 1
            if `file_ok' {
                capture erase `"`filename'"'
                local erase_rc = _rc
                if `erase_rc' {
                    local ++failed
                    local can_pop = ("`force'" != "")
                    if !`can_pop' {
                        di as error "could not erase preserved file at level `level'"
                        di as error `"`filename'"'
                        exit `erase_rc'
                    }
                }
                else local ++deleted
            }
            else local ++missing_files

            if `can_pop' {
                capture macro drop `file_macro'
                capture macro drop `frame_macro'
                capture macro drop `N_macro'
                capture macro drop `k_macro'
                capture macro drop `source_filename_macro'
                capture macro drop `source_filedate_macro'
                capture macro drop `source_changed_macro'
                capture macro drop `created_macro'
                capture macro drop `signature_macro'
                capture macro drop `vars_macro'
                local ++cleared
                local newdepth = `level' - 1
                if `newdepth' > 0 global NESTPRESERVE_depth `newdepth'
                else capture macro drop NESTPRESERVE_depth
                if "${NESTPRESERVE_depth}" == "" & ///
                        "${NESTPRESERVE_orphan_count}" == "" {
                    capture noisily _nestpreserve_manifest, action(close)
                }
                else capture noisily _nestpreserve_manifest, action(write)
                if _rc {
                    local ++manifest_failures
                    di as error "warning: cleanup state changed, but manifest update failed"
                }
            }
        }
    }

    /* Force also removes package globals that cannot be enumerated through a
       valid depth.  Cross-session file discovery belongs to Stage 3. */
    if "`force'" != "" & !`depth_valid' {
        capture macro drop NESTPRESERVE_depth
    }

    local orphan_count = real("${NESTPRESERVE_orphan_count}")
    if missing(`orphan_count') local orphan_count 0
    if `orphan_count' > 0 {
        forvalues orphan = `orphan_count'(-1)1 {
            local orphan_file_macro "NESTPRESERVE_orphan_file_`orphan'"
            local orphan_rc_macro "NESTPRESERVE_orphan_rc_`orphan'"
            local filename : copy global `orphan_file_macro'
            local file_ok 0
            local orphan_can_drop 1
            if `"`filename'"' != "" {
                tempname exists
                mata: st_numscalar("`exists'", fileexists(st_local("filename")))
                local file_ok = scalar(`exists')
            }
            if `file_ok' {
                capture erase `"`filename'"'
                if _rc {
                    local ++failed
                    local orphan_can_drop = ("`force'" != "")
                    if "`force'" == "" {
                        local erase_rc = _rc
                        di as error "could not erase registered orphan snapshot"
                        di as error `"`filename'"'
                        exit `erase_rc'
                    }
                }
                else local ++deleted
            }
            else local ++missing_files

            if `orphan_can_drop' {
                capture macro drop `orphan_file_macro'
                capture macro drop `orphan_rc_macro'
                local remaining_orphans = `orphan' - 1
                if `remaining_orphans' > 0 {
                    global NESTPRESERVE_orphan_count `remaining_orphans'
                }
                else capture macro drop NESTPRESERVE_orphan_count
                if "${NESTPRESERVE_depth}" == "" & ///
                        "${NESTPRESERVE_orphan_count}" == "" {
                    capture noisily _nestpreserve_manifest, action(close)
                }
                else capture noisily _nestpreserve_manifest, action(write)
                if _rc {
                    local ++manifest_failures
                    di as error "warning: orphan state changed, but manifest update failed"
                }
            }
        }
    }

    if `depth_valid' & "${NESTPRESERVE_depth}" == "" & ///
            "${NESTPRESERVE_orphan_count}" == "" {
        capture noisily _nestpreserve_manifest, action(close)
        if _rc local ++manifest_failures
        capture macro drop NESTPRESERVE_session
        capture macro drop NESTPRESERVE_owner_pid
        capture macro drop NESTPRESERVE_owner_start
        capture macro drop NESTPRESERVE_owner_host
    }

    local audit_deleted 0
    if "${NESTPRESERVE_depth}" == "" & ///
            "${NESTPRESERVE_orphan_count}" == "" {
        local audit `"${NESTPRESERVE_audit}"'
        if `"`audit'"' == "" local audit `"${NESTPRESERVE_last_audit}"'
        if `"`audit'"' != "" {
            capture erase `"`audit'"'
            if !_rc | _rc == 601 local audit_deleted 1
        }
        capture macro drop NESTPRESERVE_audit
        capture macro drop NESTPRESERVE_last_audit
        capture macro drop NESTPRESERVE_audit_failed
    }

    return scalar cleared = `cleared'
    return scalar files_deleted = `deleted'
    return scalar files_missing = `missing_files'
    return scalar delete_failures = `failed'
    return scalar manifest_failures = `manifest_failures'
    return scalar audit_deleted = `audit_deleted'

    if "`quiet'" == "" {
        di as text "cleared " as result `cleared' as text " preservation level(s)"
        di as text "snapshot files deleted: " as result `deleted'
        di as text "snapshot files missing: " as result `missing_files'
        if `failed' > 0 {
            di as error "`failed' file(s) could not be deleted"
        }
    }
end
