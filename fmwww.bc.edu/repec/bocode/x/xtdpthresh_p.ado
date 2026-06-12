*! version 0.7.5  11jun2026  (companion predict program, shipped with xtdpthresh 0.7.5)
*!
*! predict program for xtdpthresh: residuals, xb, regime, arresiduals.
*!
*! Architecture: xtdpthresh_run persists two row sets in Mata globals that
*! survive -restore-, both keyed by (panelvar, timevar):
*!   (1) the ESTIMATION-equation series — y and e-hat on the rows the estimator
*!       actually used (FOD rows under method(fod); FD rows under fd);
*!   (2) the FD AR-test series — the exact rows the AR(1)/AR(2) tests consume.
*! This program merges the requested series back by key via xdpt2_p_fill()
*! (defined in xtdpthresh.ado), guarded by e(p_serial) against stale Mata
*! state. Both series are identical BY CONSTRUCTION to their estimation-time
*! values, for every method and any panel pattern — no transformation, trim,
*! t-2 membership, or zero-instrument (B4) filter is re-derived here.
*!
*! Syntax:
*!   predict [type] newvar [if] [in] [, RESiduals XB Regime ARResiduals]
*!
*!     residuals    (default) residual of the ESTIMATED equation:
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
*!   - Requires xtdpthresh as the active estimation results AND its Mata state
*!     intact. After -mata: mata clear-, -discard-, a Stata restart, or
*!     -estimates restore- of an older run, re-run xtdpthresh first (a clear
*!     error is issued in those cases).
*!   - Rows outside the estimation row set (trimmed rows, rows failing the t-2
*!     instrument-history requirement, zero-instrument rows) are missing.

program xtdpthresh_p
    version 15.0

    if "`e(cmd)'" != "xtdpthresh" {
        di as err "predict must follow xtdpthresh"
        exit 301
    }

    syntax newvarname [if] [in] [, RESiduals XB Regime ARResiduals]

    // Resolve statistic (default residuals); reject combinations
    local n_opts = ("`residuals'" != "") + ("`xb'" != "") ///
                 + ("`regime'" != "") + ("`arresiduals'" != "")
    if `n_opts' > 1 {
        di as err "only one of residuals, xb, regime, arresiduals may be specified"
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

    qui gen `typlist' `varlist' = . if `touse'
    mata: xdpt2_p_fill("`panelvar'", "`timevar'", "`varlist'", ///
                        "`touse'", `source', `which', `=e(p_serial)')

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
// from xtdpthresh_p.ado. The externals xdpt_p_resid / xdpt_p_est /
// xdpt_p_serial_m ARE persistent across calls (Mata externals survive), so
// they refer to the values xtdpthresh_run populated.
// ============================================================================
mata:
mata set matastrict off

void xdpt2_p_fill(string scalar pvar, string scalar tvar,
                   string scalar outvar, string scalar touse,
                   real scalar source, real scalar which,
                   real scalar serial_expect)
{
    external real matrix xdpt_p_resid, xdpt_p_est, xdpt_p_serial_m
    real matrix D, S
    real scalar r, v
    transmorphic A

    S = (source == 2 ? xdpt_p_est : xdpt_p_resid)

    if (rows(xdpt_p_serial_m) == 0 | rows(S) == 0) {
        errprintf("xtdpthresh predict: stored estimation rows not found in Mata memory\n")
        errprintf("  (cleared by -mata: mata clear-, -discard-, or restarting Stata).\n")
        errprintf("  Re-run xtdpthresh, then predict.\n")
        exit(498)
    }
    if (serial_expect >= . | xdpt_p_serial_m[1, 1] != serial_expect) {
        errprintf("xtdpthresh predict: stored rows belong to a different xtdpthresh run\n")
        errprintf("  than the current e() results (e.g. -estimates restore- of an older\n")
        errprintf("  model). Re-run xtdpthresh, then predict.\n")
        exit(498)
    }

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
