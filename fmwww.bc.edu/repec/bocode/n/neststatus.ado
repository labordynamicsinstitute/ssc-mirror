*! version 1.0.0 23aug2026
program define neststatus, rclass
    version 16.0

    syntax [, DETAIL]

    local depth 0
    if "${NESTPRESERVE_depth}" != "" {
        local depth = real("${NESTPRESERVE_depth}")
        if missing(`depth') | `depth' < 0 | `depth' != floor(`depth') {
            di as error "nestpreserve stack metadata are corrupted"
            exit 498
        }
    }
    if `depth' > 0 & "${NESTPRESERVE_session}" == "" {
        di as error "nestpreserve stack metadata are corrupted: session identifier is missing"
        exit 498
    }

    local all_exist 1
    if `depth' == 0 di as text "no active nestpreserve checkpoints"
    else di as text "active checkpoints: " as result `depth'

    local previous_N .
    local previous_vars ""
    local previous_signature ""

    if `depth' > 0 {
        forvalues level = 1/`depth' {
            foreach item in file frame N k created signature vars {
                local `item'_macro "NESTPRESERVE_`item'_`level'"
                local `item' : copy global ``item'_macro'
            }
            if `"`file'"' == "" | `"`frame'"' == "" | ///
                    "`N'" == "" | "`k'" == "" | ///
                    `"`created'"' == "" | `"`signature'"' == "" {
                di as error "nestpreserve stack metadata are corrupted at level `level'"
                exit 498
            }

            tempname exists
            mata: st_numscalar("`exists'", fileexists(st_local("file")))
            local file_ok = scalar(`exists')
            if !`file_ok' local all_exist 0

            local created_display : display %tcDDmonCCYY_HH:MM:SS real("`created'")
            di as text "level " as result `level' as text ": " ///
                as result `N' as text " observations, " as result `k' ///
                as text " variables; saved " as result "`created_display'"

            if `level' > 1 {
                local added : list vars - previous_vars
                local removed : list previous_vars - vars
                local n_added : word count `added'
                local n_removed : word count `removed'
                local N_change = real("`N'") - `previous_N'
                local state_changed = (`"`signature'"' != `"`previous_signature'"' | ///
                    `N_change' != 0)
                di as text "  since level `=`level'-1': observations " ///
                    as result %10.0g `N_change' as text ", variables +" ///
                    as result `n_added' as text "/-" as result `n_removed' ///
                    as text ", data changed " ///
                    as result cond(`state_changed', "yes", "no")
                if `"`added'"' != "" di as text "    added:   " as result `"`added'"'
                if `"`removed'"' != "" di as text "    removed: " as result `"`removed'"'
                return scalar N_change_`level' = `N_change'
                return scalar vars_added_`level' = `n_added'
                return scalar vars_removed_`level' = `n_removed'
                return scalar changed_`level' = `state_changed'
                return local added_`level' `"`added'"'
                return local removed_`level' `"`removed'"'
            }

            if !`file_ok' di as error "  warning: checkpoint file is missing"
            if "`detail'" != "" {
                di as text "  frame: " as result `"`frame'"'
                di as text "  signature: " as result `"`signature'"'
                di as text "  file: " as result `"`file'"'
            }

            return local file_`level' `"`file'"'
            return local frame_`level' `"`frame'"'
            return local created_`level' `"`created'"'
            return local signature_`level' `"`signature'"'
            return local vars_`level' `"`vars'"'
            return scalar N_`level' = real("`N'")
            return scalar k_`level' = real("`k'")
            return scalar file_ok_`level' = `file_ok'

            local previous_N = real("`N'")
            local previous_vars `"`vars'"'
            local previous_signature `"`signature'"'
        }

        if `"`c(frame)'"' == `"`frame'"' {
            local current_vars ""
            if c(k) > 0 {
                unab current_vars : _all
                quietly datasignature
                local current_signature `"`r(datasignature)'"'
            }
            else local current_signature "0:0(empty)"
            local current_added : list current_vars - previous_vars
            local current_removed : list previous_vars - current_vars
            local current_n_added : word count `current_added'
            local current_n_removed : word count `current_removed'
            local current_N_change = _N - `previous_N'
            local current_changed = (`"`current_signature'"' != `"`previous_signature'"' | ///
                `current_N_change' != 0)
            di as text "current data since level `depth': observations " ///
                as result %10.0g `current_N_change' as text ", variables +" ///
                as result `current_n_added' as text "/-" as result `current_n_removed' ///
                as text ", data changed " ///
                as result cond(`current_changed', "yes", "no")
            if `"`current_added'"' != "" di as text "  added:   " as result `"`current_added'"'
            if `"`current_removed'"' != "" di as text "  removed: " as result `"`current_removed'"'
            return scalar current_N_change = `current_N_change'
            return scalar current_vars_added = `current_n_added'
            return scalar current_vars_removed = `current_n_removed'
            return scalar current_changed = `current_changed'
            return local current_added `"`current_added'"'
            return local current_removed `"`current_removed'"'
            return scalar current_comparable = 1
        }
        else {
            di as text "current data comparison skipped: current frame is " ///
                as result `"`c(frame)'"' as text ", checkpoint frame is " ///
                as result `"`frame'"'
            return scalar current_comparable = 0
        }
    }

    local audit `"${NESTPRESERVE_audit}"'
    if `"`audit'"' == "" local audit `"${NESTPRESERVE_last_audit}"'
    local audit_events 0
    local transactions 0
    local last_command_rc .
    local last_rollback_rc .
    if `"`audit'"' != "" {
        capture confirm file `"`audit'"'
        if !_rc {
            capture file close np_status_audit
            file open np_status_audit using `"`audit'"', read text
            file read np_status_audit audit_line
            while !r(eof) {
                if substr(`"`audit_line'"', 1, 9) == "PRESERVE|" | ///
                        substr(`"`audit_line'"', 1, 8) == "RESTORE|" | ///
                        substr(`"`audit_line'"', 1, 12) == "TRANSACTION|" {
                    local ++audit_events
                }
                if substr(`"`audit_line'"', 1, 12) == "TRANSACTION|" {
                    local ++transactions
                    tokenize `"`audit_line'"', parse("|")
                    local last_command_rc = real("`5'")
                    local last_rollback_rc = real("`7'")
                }
                file read np_status_audit audit_line
            }
            file close np_status_audit
        }
    }
    if `transactions' > 0 {
        di as text "recorded transactions: " as result `transactions' ///
            as text "; latest command rc " as result `last_command_rc' ///
            as text ", rollback rc " as result `last_rollback_rc'
    }

    local orphan_count = real("${NESTPRESERVE_orphan_count}")
    if missing(`orphan_count') local orphan_count 0
    if `orphan_count' > 0 {
        di as error "registered orphan snapshots awaiting cleanup: `orphan_count'"
    }

    return scalar depth = `depth'
    return scalar valid = 1
    return scalar files_ok = `all_exist'
    return scalar orphan_count = `orphan_count'
    return scalar audit_events = `audit_events'
    return scalar transactions = `transactions'
    return scalar last_command_rc = `last_command_rc'
    return scalar last_rollback_rc = `last_rollback_rc'
    return local audit `"`audit'"'
    return local session "${NESTPRESERVE_session}"
end
