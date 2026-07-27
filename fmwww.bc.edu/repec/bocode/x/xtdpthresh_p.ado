*! version 0.9.23  13jul2026  (companion predict program; recomputed cache checksum, guarded serial/token identity and data-integrity checks)
*!
*! predict program for xtdpthresh: residuals, xb, regime, arresiduals.
*!
*! Architecture: xtdpthresh_run persists two row sets in Mata memory,
*! keyed by run serial plus the exact token/recomputed-checksum guard (asarrays
*! holding the 20 most recent runs, so -estimates store/restore- works within
*! a session) and, within a run,
*! by (panelvar, timevar):
*!   (1) the ESTIMATION-equation series — y and e-hat on the rows the estimator
*!       actually used (FOD rows under method(fod); FD rows under fd);
*!   (2) the FD AR-test series — the exact rows the AR(1)/AR(2) tests consume.
*! This program merges the requested series back by key via xdpt2_p_fill()
*! (defined in xtdpthresh.ado), guarded by e(p_serial), an exact per-fit token,
*! and e(p_cache_sig) against stale or serial-colliding Mata
*! state. Both series are identical BY CONSTRUCTION to their estimation-time
*! values, for every method and any panel pattern — no transformation, trim,
*! t-2 membership, or zero-instrument (B4) filter is re-derived here.
*!
*! Syntax:
*!   predict [type] newvar [if] [in] [, Residuals XB REGime ARResiduals]
*!   (v0.7.13: -r- abbreviates residuals; regime needs -reg-)
*!
*!     residuals    residual of the ESTIMATED equation (must be requested):
*!                    method(fd)     — FD residual dy - dW(g)theta
*!                    method(fod)    — forward-orthogonal-deviation residual
*!                    method(system) — FD-restack residual (level-equation
*!                                     residuals are not yet exposed; equals
*!                                     -arresiduals- for this method)
*!     arresiduals  the FD residual series the AR(1)/AR(2) tests consume
*!                  (xtabond2 convention; always FD-form). For method(fd) this
*!                  equals -residuals-; for method(fod) it is the FD restack,
*!                  which differs from the FOD estimation residual (different
*!                  variance and a mechanical first-order autocorrelation —
*!                  use this, not -residuals-, to reproduce the reported AR
*!                  statistics under fod).
*!     xb           fit of whichever equation -residuals- corresponds to
*!                  (residuals + xb = transformed y, row by row)
*!     regime       1{q_it > g} on raw rows (within if/in, q non-missing);
*!                  not restricted to e(sample)
*!
*! Notes:
*!   - Requires xtdpthresh estimation results and intact Mata state.
*!     -estimates store/restore- IS supported for the 20 most recent runs of
*!     the current session (v0.9.18+ guarded runtimes). After -mata: mata clear-,
*!     -discard-, a Stata restart, eviction (>20 newer runs), or any change
*!     to the source data (signature check, rc 459), re-run xtdpthresh
*!     first -- a clear error is issued in every case.
*!   - Rows outside the estimation row set (trimmed rows, rows failing the t-2
*!     instrument-history requirement, zero-instrument rows) are missing.

program xtdpthresh_p
    version 15.0

    if "`e(cmd)'" != "xtdpthresh" {
        di as err "predict must follow xtdpthresh"
        exit 301
    }

    // v0.7.13: -Residuals- abbreviates to "r" (the universal Stata idiom
    // -predict e, r-) and -REGime- requires "reg". Previously -Regime-
    // captured the single letter "r", so -predict e, r- silently returned
    // the 0/1 regime dummy instead of residuals.
    syntax newvarname [if] [in] [, Residuals XB REGime ARResiduals]

    // Resolve the explicitly requested statistic; reject combinations
    local n_opts = ("`residuals'" != "") + ("`xb'" != "") ///
                 + ("`regime'" != "") + ("`arresiduals'" != "")
    if `n_opts' > 1 {
        di as err "only one of residuals, xb, regime, arresiduals may be specified"
        exit 198
    }
    // v0.9.6 R22 (#6): no silent default. Official dynamic-panel commands
    // default to xb; this predictor's statistics are CACHED estimation-row
    // series (not current-data linear predictions), so a silent default in
    // either direction misleads -- require the caller to say what they want.
    if `n_opts' == 0 {
        di as err "specify one of: xb, residuals, arresiduals, regime"
        di as err "(cached estimation-row statistics; see help xtdpthresh)"
        exit 198
    }
    local stat "residuals"
    if "`xb'" != ""          local stat "xb"
    if "`regime'" != ""      local stat "regime"
    if "`arresiduals'" != "" local stat "arresiduals"

    local panelvar "`e(panelvar)'"
    local timevar  "`e(timevar)'"
    local qvar     "`e(q_var)'"
    local method   "`e(method)'"

    marksample touse, novarlist

    // ---------- regime indicator: raw rows, no e(sample) restriction ----------
    if "`stat'" == "regime" {
        tempname gam
        scalar `gam' = e(gamma)
        qui gen `typlist' `varlist' = (`qvar' > `gam') ///
            if `touse' & !missing(`qvar')
        label var `varlist' "1{`qvar' > gamma_hat} (xtdpthresh)"
        exit
    }

    // ---------- residuals / xb / arresiduals: merge from persisted rows ------
    // e(p_serial) exists only for runs that stored the row sets (>= v0.7.3).
    if missing(e(p_serial)) {
        di as err "these e() results were produced by an xtdpthresh version (or run)"
        di as err "that did not store prediction rows; re-run xtdpthresh (>= v0.7.4)"
        exit 301
    }
    if missing(e(p_cache_sig)) {
        di as err "these e() results do not contain the model-specific predict cache guard"
        di as err "required by xtdpthresh 0.9.18 or newer; re-run xtdpthresh, then predict"
        exit 301
    }
    if `"`e(p_cache_token)'"' == "" {
        di as err "these e() results do not contain the exact predict cache token"
        di as err "required by xtdpthresh 0.9.18 or newer; re-run xtdpthresh, then predict"
        exit 301
    }

    // v0.9.6 R22 (#5): cached series are estimation-time values -- refuse
    // when the source columns changed since estimation (or a different
    // dataset with coincident panel-time keys is in memory).
    if `"`e(p_dsig)'"' != "" {
        cap qui _datasignature `e(p_dsig_vars)'
        if _rc {
            di as err "data have changed since estimation (source variables missing or"
            di as err "renamed); cached residuals/fitted values are no longer valid."
            exit 459
        }
        if `"`r(datasignature)'"' != `"`e(p_dsig)'"' {
            di as err "data have changed since estimation; cached residuals and fitted"
            di as err "values are no longer valid. Re-run xtdpthresh on the current data."
            exit 459
        }
    }

    // source: 1 = FD AR-test series, 2 = estimation-equation series.
    //   arresiduals -> always the FD AR-test series (source 1)
    //   residuals/xb -> estimation-equation series (source 2) EXCEPT for
    //     fd (the two series are identical; use 1) and system (level rows make
    //     the estimation series non-mergeable by key; route to the FD series).
    // which: 1 = residual, 2 = xb (fit = dy - e-hat, row by row).
    if "`stat'" == "arresiduals" {
        local source = 1
        local which  = 1
    }
    else {
        local which = cond("`stat'" == "xb", 2, 1)
        local source = cond("`method'" == "fod", 2, 1)
    }

    // Fill a temporary target and rename only after the cache lookup succeeds.
    // A failed lookup must not leave an all-missing user variable behind.
    tempvar _cacheout
    tempname _pserial _psig
    local _ptoken `"`e(p_cache_token)'"'
    scalar `_pserial' = e(p_serial)
    scalar `_psig' = e(p_cache_sig)
    qui gen `typlist' `_cacheout' = . if `touse'
    capture noisily mata: xdpt2_p_fill("`panelvar'", "`timevar'", "`_cacheout'", ///
        "`touse'", `source', `which', st_numscalar("`_pserial'"), ///
        st_numscalar("`_psig'"), st_local("_ptoken"))
    local _rc = _rc
    if `_rc' {
        capture drop `_cacheout'
        exit `_rc'
    }
    rename `_cacheout' `varlist'

    // ---------- labels ----------
    if "`stat'" == "arresiduals" {
        label var `varlist' "FD AR-test residual (xtdpthresh, `method')"
    }
    else if "`stat'" == "xb" {
        if "`method'" == "fod" ///
            label var `varlist' "FOD fit (estimation eq, xtdpthresh)"
        else if "`method'" == "system" ///
            label var `varlist' "FD-restack fit (xtdpthresh system)"
        else ///
            label var `varlist' "FD fit dW*theta_hat (xtdpthresh)"
    }
    else {
        if "`method'" == "fod" ///
            label var `varlist' "FOD residual (estimation eq, xtdpthresh)"
        else if "`method'" == "system" ///
            label var `varlist' "FD-restack residual (xtdpthresh system)"
        else ///
            label var `varlist' "FD residual (estimation eq, xtdpthresh)"
    }
end


// ============================================================================
// Mata helper for predict — duplicated from xtdpthresh.ado because functions
// in an ado's inline mata: block are private to that ado on Stata 17 (the
// version targeted by SSC), so xtdpthresh.ado's xdpt2_p_fill is not callable
// from xtdpthresh_p.ado. Mata EXTERNALS persist across calls: v0.9.18+
// runtimes populate serial-keyed row, token, and checksum stores; v0.9.19
// additionally recomputes that checksum from the actual rows. Older
// cached results without the exact token are rejected and must be re-run.
// ============================================================================
version 15.0
mata:
mata set matastrict off

void xdpt2_p_fill(string scalar pvar, string scalar tvar,
                   string scalar outvar, string scalar touse,
                   real scalar source, real scalar which,
                   real scalar serial_expect, real scalar sig_expect,
                   string scalar token_expect)
{
    // Serial-keyed lookup plus an exact per-fit token and a deterministic
    // checksum of the cache matrices. A bare serial is unsafe because its
    // counter restarts after mata clear and can collide with restored e().
    external transmorphic xdpt_p_store_r, xdpt_p_store_e, xdpt_p_store_sig
    external transmorphic xdpt_p_store_token
    real matrix D, S, S_r, S_e
    real scalar r, v, sig_have, sig_actual
    string scalar token_have
    transmorphic A

    if (serial_expect >= . | sig_expect >= . | token_expect == "") {
        errprintf("xtdpthresh predict: cache identity is missing; re-run xtdpthresh.\n")
        exit(498)
    }
    if (eltype(xdpt_p_store_r) == "real" | eltype(xdpt_p_store_e) == "real" |
        eltype(xdpt_p_store_sig) == "real" |
        eltype(xdpt_p_store_token) == "real") {
        errprintf("xtdpthresh predict: stored estimation rows not found in Mata memory\n")
        errprintf("  (cleared by -mata: mata clear-, -discard-, or restarting Stata).\n")
        errprintf("  Re-run xtdpthresh, then predict.\n")
        exit(498)
    }
    if (!asarray_contains(xdpt_p_store_token, serial_expect)) {
        errprintf("xtdpthresh predict: this run's exact cache token was evicted or cleared\n")
        errprintf("  Re-run xtdpthresh, then predict.\n")
        exit(498)
    }
    token_have = asarray(xdpt_p_store_token, serial_expect)
    if (token_have != token_expect) {
        errprintf("xtdpthresh predict: cached rows belong to a different model/run\n")
        errprintf("  (the Mata serial was reused after state was cleared).\n")
        errprintf("  Re-run xtdpthresh, then predict.\n")
        exit(498)
    }
    if (!asarray_contains(xdpt_p_store_sig, serial_expect)) {
        errprintf("xtdpthresh predict: this run's cache was evicted or cleared\n")
        errprintf("  Re-run xtdpthresh, then predict.\n")
        exit(498)
    }
    sig_have = asarray(xdpt_p_store_sig, serial_expect)
    if (sig_have != sig_expect) {
        errprintf("xtdpthresh predict: cached rows belong to a different model/run\n")
        errprintf("  (the Mata serial was reused after state was cleared).\n")
        errprintf("  Re-run xtdpthresh, then predict.\n")
        exit(498)
    }
    // v0.9.19: recompute the combined checksum from the two ACTUAL cache
    // matrices. Comparing only the parallel stored checksum with e() does
    // not detect a row matrix that another Mata routine overwrote.
    if (!asarray_contains(xdpt_p_store_r, serial_expect) |
        !asarray_contains(xdpt_p_store_e, serial_expect)) {
        errprintf("xtdpthresh predict: this run's stored rows were evicted or cleared\n")
        exit(498)
    }
    S_r = asarray(xdpt_p_store_r, serial_expect)
    S_e = asarray(xdpt_p_store_e, serial_expect)
    sig_actual = hash1(S_r, 2147483647) * 4194304 +
                 mod(hash1(S_e), 4194304)
    if (sig_actual != sig_have) {
        errprintf("xtdpthresh predict: cached estimation rows failed their checksum\n")
        errprintf("  (Mata cache contents were changed or corrupted).\n")
        errprintf("  Re-run xtdpthresh, then predict.\n")
        exit(498)
    }
    S = (source == 2 ? S_e : S_r)

    A = asarray_create("real", 2)
    asarray_notfound(A, .)
    for (r = 1; r <= rows(S); r++) {
        asarray(A, (S[r, 1], S[r, 2]),
                (which == 2 ? S[r, 3] - S[r, 4] : S[r, 4]))
    }
    st_view(D = ., ., (pvar, tvar, outvar), touse)
    for (r = 1; r <= rows(D); r++) {
        v = asarray(A, (D[r, 1], D[r, 2]))
        if (v < .) D[r, 3] = v
    }
}

end
