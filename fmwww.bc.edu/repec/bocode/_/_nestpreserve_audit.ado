*! version 1.0.0 23aug2026
program define _nestpreserve_audit
    version 16.0

    syntax , EVENT(string) [LEVEL(integer 0) DEPTH(integer 0) ///
        COMMAND(string asis) COMMANDRC(integer 0) ROLLBACKRC(integer 0)]

    local event = lower(strtrim("`event'"))
    if !inlist("`event'", "preserve", "restore", "transaction") {
        di as error "invalid internal audit event"
        exit 198
    }

    local session "${NESTPRESERVE_session}"
    if "`session'" == "" {
        di as error "cannot write audit event without a session identifier"
        exit 498
    }

    local audit `"${NESTPRESERVE_audit}"'
    if `"`audit'"' == "" {
        local audit `"`c(tmpdir)'nestpreserve_`session'.audit"'
    }

    capture confirm file `"`audit'"'
    local newfile = (_rc != 0)
    capture file close np_audit_out
    capture file open np_audit_out using `"`audit'"', ///
        write text append
    if _rc {
        local open_rc = _rc
        di as error "could not write NESTPRESERVE audit trail"
        exit `open_rc'
    }

    if `newfile' {
        file write np_audit_out "NESTPRESERVE_AUDIT|1" _n
        file write np_audit_out `"SESSION|`session'"' _n
    }

    local timestamp_value = clock("`c(current_date)' `c(current_time)'", "DMYhms")
    local timestamp = strtrim(string(`timestamp_value', "%21.0f"))
    if inlist("`event'", "preserve", "restore") {
        local frame_macro "NESTPRESERVE_frame_`level'"
        local N_macro "NESTPRESERVE_N_`level'"
        local k_macro "NESTPRESERVE_k_`level'"
        local created_macro "NESTPRESERVE_created_`level'"
        local signature_macro "NESTPRESERVE_signature_`level'"
        local vars_macro "NESTPRESERVE_vars_`level'"
        local frame : copy global `frame_macro'
        local saved_N : copy global `N_macro'
        local saved_k : copy global `k_macro'
        local created : copy global `created_macro'
        local signature : copy global `signature_macro'
        local vars : copy global `vars_macro'
        local vars_encoded = subinstr(`"`vars'"', " ", ",", .)
        local event_upper = upper("`event'")
        file write np_audit_out ///
            `"`event_upper'|`timestamp'|`level'|`depth'|`frame'|`saved_N'|`saved_k'|`created'|`signature'|`vars_encoded'"' _n
    }
    else {
        local cleancommand = subinstr(`"`command'"', "|", "/", .)
        local cleancommand = subinstr(`"`cleancommand'"', char(9), " ", .)
        local cleancommand = subinstr(`"`cleancommand'"', char(10), " ", .)
        local cleancommand = subinstr(`"`cleancommand'"', char(13), " ", .)
        file write np_audit_out ///
            `"TRANSACTION|`timestamp'|`commandrc'|`rollbackrc'|`cleancommand'"' _n
    }
    file close np_audit_out

    global NESTPRESERVE_audit `"`audit'"'
    global NESTPRESERVE_last_audit `"`audit'"'
end
