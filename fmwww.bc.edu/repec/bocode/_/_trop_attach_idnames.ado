*! _trop_attach_idnames
*!
*! Internal helper invoked by `trop` after estimation is complete.
*! Reads the sorted unique values of the user-supplied `panelvar` and
*! `timevar` on the estimation sample and installs them as matrix row
*! names on `e(alpha)` (N x 1) and `e(beta)` (T x 1).  This lets users
*! cross-reference unit / time fixed effects by their original
*! identifier instead of by the 1..N / 1..T consecutive index that the
*! plugin sees.
*!
*! The ordering is consistent with `egen ... = group(panelvar)` /
*! `egen ... = group(timevar)` used during data preparation, because
*! both `levelsof` and `egen group` emit sorted unique values.
*!
*! Matrix name rules (Stata): must start with a letter or underscore,
*! contain only letters/digits/underscore, and be at most 32 characters.
*! Any other character is replaced with `_`; leading digits are
*! prefixed with `_`; empty results become `_`.  Long names are
*! truncated to 32 characters.
*!
*! Fails silently (captured) on any mismatch so that a future change in
*! panel indexing cannot break the estimation pipeline.

program define _trop_attach_idnames, eclass
    version 17
    args panelvar timevar

    if "`e(cmd)'" != "trop" exit 0

    // --- e(alpha): rows correspond to sorted unique panelvar -----------
    capture confirm matrix e(alpha)
    if !_rc {
        qui levelsof `panelvar' if e(sample), local(_pids)
        local _pnames ""
        foreach v of local _pids {
            local _safe = ustrregexra(`"`v'"', "[^A-Za-z0-9_]", "_")
            if "`_safe'" == "" local _safe "_"
            if regexm("`_safe'", "^[0-9]") local _safe "_`_safe'"
            local _safe = substr("`_safe'", 1, 32)
            local _pnames "`_pnames' `_safe'"
        }
        tempname _A
        matrix `_A' = e(alpha)
        local _nrow = rowsof(`_A')
        local _ncount : word count `_pnames'
        if `_ncount' == `_nrow' {
            capture matrix rownames `_A' = `_pnames'
            matrix colnames `_A' = alpha
            if !_rc ereturn matrix alpha = `_A'
        }
    }

    // --- e(beta): rows correspond to sorted unique timevar -------------
    capture confirm matrix e(beta)
    if !_rc {
        qui levelsof `timevar' if e(sample), local(_tids)
        local _tnames ""
        foreach v of local _tids {
            local _safe = ustrregexra(`"`v'"', "[^A-Za-z0-9_]", "_")
            if "`_safe'" == "" local _safe "_"
            if regexm("`_safe'", "^[0-9]") local _safe "_`_safe'"
            local _safe = substr("`_safe'", 1, 32)
            local _tnames "`_tnames' `_safe'"
        }
        tempname _B
        matrix `_B' = e(beta)
        local _nrow = rowsof(`_B')
        local _ncount : word count `_tnames'
        if `_ncount' == `_nrow' {
            capture matrix rownames `_B' = `_tnames'
            matrix colnames `_B' = beta
            if !_rc ereturn matrix beta = `_B'
        }
    }
end
