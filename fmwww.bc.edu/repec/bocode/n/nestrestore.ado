*! version 1.0.0 23aug2026
program define nestrestore, rclass
    version 16.0

    syntax [, PRESERVE QUIET]

    if "${NESTPRESERVE_depth}" == "" {
        di as error "nothing to restore"
        exit 622
    }

    local level = real("${NESTPRESERVE_depth}")
    if missing(`level') | `level' <= 0 | `level' != floor(`level') {
        di as error "nothing to restore or stack metadata are corrupted"
        exit 622
    }

    if "${NESTPRESERVE_session}" == "" {
        di as error "nestpreserve stack metadata are corrupted: session identifier is missing"
        exit 498
    }

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
    local saved_frame : copy global `frame_macro'
    local saved_N : copy global `N_macro'
    local saved_k : copy global `k_macro'
    local source_filename : copy global `source_filename_macro'
    local source_filedate : copy global `source_filedate_macro'
    local source_changed : copy global `source_changed_macro'
    local created : copy global `created_macro'
    local signature : copy global `signature_macro'
    local vars : copy global `vars_macro'

    if `"`filename'"' == "" | `"`saved_frame'"' == "" | ///
            "`saved_N'" == "" | "`saved_k'" == "" | ///
            "`source_changed'" == "" | `"`created'"' == "" | ///
            `"`signature'"' == "" {
        di as error "nestpreserve stack metadata are corrupted at level `level'"
        exit 498
    }

    if `"`c(frame)'"' != `"`saved_frame'"' {
        di as error "current frame differs from the frame preserved at level `level'"
        di as error `"current frame: `c(frame)'"'
        di as error `"saved frame:   `saved_frame'"'
        di as error "change to the saved frame before restoring"
        exit 498
    }

    tempname exists
    mata: st_numscalar("`exists'", fileexists(st_local("filename")))
    if scalar(`exists') == 0 {
        di as error "preserved dataset was not found"
        di as error `"`filename'"'
        exit 601
    }

    /* Restore first.  Stack metadata are changed only after use succeeds. */
    quietly use `"`filename'"', clear
    global S_FN `"`source_filename'"'
    global S_FNDATE `"`source_filedate'"'
    mata: st_updata(strtoreal(st_local("source_changed")))

    if "`preserve'" == "" local newdepth = `level' - 1
    else local newdepth = `level'

    capture noisily _nestpreserve_audit, event(restore) ///
        level(`level') depth(`newdepth')
    local audit_failed = (_rc != 0)
    if `audit_failed' {
        global NESTPRESERVE_audit_failed 1
        di as error "warning: restoration succeeded, but audit recording failed"
    }

    local delete_failed 0
    if "`preserve'" == "" {
        macro drop `file_macro'
        macro drop `frame_macro'
        macro drop `N_macro'
        macro drop `k_macro'
        macro drop `source_filename_macro'
        macro drop `source_filedate_macro'
        macro drop `source_changed_macro'
        macro drop `created_macro'
        macro drop `signature_macro'
        macro drop `vars_macro'

        global NESTPRESERVE_depth `newdepth'

        if `newdepth' == 0 {
            macro drop NESTPRESERVE_depth
        }

        capture erase `"`filename'"'
        local erase_rc = _rc
        if `erase_rc' {
            local delete_failed 1
            local orphan_count = real("${NESTPRESERVE_orphan_count}")
            if missing(`orphan_count') local orphan_count 0
            local ++orphan_count
            global NESTPRESERVE_orphan_count `orphan_count'
            global NESTPRESERVE_orphan_file_`orphan_count' `"`filename'"'
            global NESTPRESERVE_orphan_rc_`orphan_count' `erase_rc'
            di as error "warning: dataset was restored, but its snapshot could not be deleted"
            di as error `"registered for later cleanup: `filename'"'
        }

    }
    local manifest_failed 0
    if "${NESTPRESERVE_depth}" == "" & "${NESTPRESERVE_orphan_count}" == "" {
        capture noisily _nestpreserve_manifest, action(close)
    }
    else {
        capture noisily _nestpreserve_manifest, action(write)
    }
    if _rc {
        local manifest_failed 1
        di as error "warning: dataset restoration succeeded, but manifest update failed"
    }
    else if "${NESTPRESERVE_depth}" == "" & ///
            "${NESTPRESERVE_orphan_count}" == "" {
        capture macro drop NESTPRESERVE_session
    }

    return scalar level = `level'
    return scalar depth = `newdepth'
    return scalar N = _N
    return scalar k = c(k)
    return scalar preserved = ("`preserve'" != "")
    return scalar delete_failed = `delete_failed'
    return scalar manifest_failed = `manifest_failed'
    return local frame `"`saved_frame'"'
    return local filename `"`filename'"'
    return local manifest "${NESTPRESERVE_manifest}"
    return local created `"`created'"'
    return local signature `"`signature'"'
    return local audit `"${NESTPRESERVE_audit}"'
    return scalar audit_failed = `audit_failed'

    if "`quiet'" == "" {
        if "`preserve'" == "" {
            di as text "dataset restored from level " as result `level' ///
                as text "; stack depth is now " as result `=`level'-1'
        }
        else {
            di as text "dataset restored from level " as result `level' ///
                as text " and preserved again at that level"
        }
    }
end
