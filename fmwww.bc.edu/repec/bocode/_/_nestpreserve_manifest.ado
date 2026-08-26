*! version 1.0.0 23aug2026
program define _nestpreserve_manifest
    version 16.0

    syntax , ACTION(string)
    local action = lower(strtrim("`action'"))
    if !inlist("`action'", "write", "close") {
        di as error "invalid internal manifest action"
        exit 198
    }

    local session "${NESTPRESERVE_session}"
    local manifest "${NESTPRESERVE_manifest}"
    if `"`manifest'"' == "" & "`session'" != "" {
        local manifest `"`c(tmpdir)'nestpreserve_`session'.manifest"'
    }

    if "`action'" == "close" {
        if `"`manifest'"' != "" {
            capture erase `"`manifest'"'
            if _rc & _rc != 601 {
                local erase_rc = _rc
                di as error "could not remove NESTPRESERVE session manifest"
                di as error `"`manifest'"'
                exit `erase_rc'
            }
        }
        capture macro drop NESTPRESERVE_manifest
        exit
    }

    if "`session'" == "" {
        di as error "cannot write manifest without a session identifier"
        exit 498
    }

    local candidate `"`manifest'.new"'
    capture file close np_manifest_out
    capture file open np_manifest_out using `"`candidate'"', write text replace
    if _rc {
        local open_rc = _rc
        di as error "could not create NESTPRESERVE manifest candidate"
        exit `open_rc'
    }

    local owner_pid "${NESTPRESERVE_owner_pid}"
    local owner_start "${NESTPRESERVE_owner_start}"
    local owner_host `"${NESTPRESERVE_owner_host}"'
    local manifest_version 2
    if "`owner_pid'" != "" & "`owner_start'" != "" & ///
            `"`owner_host'"' != "" {
        local manifest_version 3
    }

    file write np_manifest_out "NESTPRESERVE_MANIFEST|`manifest_version'" _n
    file write np_manifest_out `"SESSION|`session'"' _n
    if `manifest_version' == 3 {
        file write np_manifest_out ///
            `"OWNER|`owner_pid'|`owner_start'|`owner_host'"' _n
    }

    local depth = real("${NESTPRESERVE_depth}")
    if missing(`depth') local depth 0
    if `depth' > 0 {
        forvalues level = 1/`depth' {
            local file_macro "NESTPRESERVE_file_`level'"
            local frame_macro "NESTPRESERVE_frame_`level'"
            local N_macro "NESTPRESERVE_N_`level'"
            local k_macro "NESTPRESERVE_k_`level'"
            local created_macro "NESTPRESERVE_created_`level'"
            local signature_macro "NESTPRESERVE_signature_`level'"
            local vars_macro "NESTPRESERVE_vars_`level'"
            local filename : copy global `file_macro'
            local frame : copy global `frame_macro'
            local saved_N : copy global `N_macro'
            local saved_k : copy global `k_macro'
            local created : copy global `created_macro'
            local signature : copy global `signature_macro'
            local vars : copy global `vars_macro'
            local vars_encoded = subinstr(`"`vars'"', " ", ",", .)
            file write np_manifest_out ///
                `"ACTIVE|`level'|`frame'|`saved_N'|`saved_k'|`filename'|`created'|`signature'|`vars_encoded'"' _n
        }
    }

    local orphan_count = real("${NESTPRESERVE_orphan_count}")
    if missing(`orphan_count') local orphan_count 0
    if `orphan_count' > 0 {
        forvalues orphan = 1/`orphan_count' {
            local file_macro "NESTPRESERVE_orphan_file_`orphan'"
            local rc_macro "NESTPRESERVE_orphan_rc_`orphan'"
            local filename : copy global `file_macro'
            local erase_rc : copy global `rc_macro'
            file write np_manifest_out ///
                `"ORPHAN|`orphan'|`erase_rc'|`filename'"' _n
        }
    }
    file close np_manifest_out

    capture copy `"`candidate'"' `"`manifest'"', replace
    if _rc {
        local copy_rc = _rc
        capture erase `"`candidate'"'
        di as error "could not commit NESTPRESERVE session manifest"
        exit `copy_rc'
    }
    capture erase `"`candidate'"'
    global NESTPRESERVE_manifest `"`manifest'"'
end
