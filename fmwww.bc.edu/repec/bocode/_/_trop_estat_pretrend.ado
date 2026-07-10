*! _trop_estat_pretrend.ado
*! Pre-trend test for TROP event-study analysis
*!
*! Tests the null hypothesis that all pre-treatment effects are jointly zero:
*!     H0: tau(-K) = tau(-K+1) = ... = tau(-1) = 0
*!
*! Uses a simplified Wald test (diagonal covariance, assumes independent
*! pre-period effects) by default.  With option 'robust', uses the Bootstrap
*! covariance matrix for the pre-treatment period effects (if available).
*!
*! Syntax:
*!   estat pretrend [, Periods(integer) Level(real 95) ROBust]
*!
*! Returns in r():
*!   r(chi2)          - Wald chi-squared test statistic
*!   r(df)            - Degrees of freedom (number of pre-periods tested)
*!   r(p)             - p-value
*!   r(pretrend_pass) - 1 if cannot reject H0 at given level, 0 otherwise
*!   r(n_preperiods)  - Number of pre-treatment periods used

program define _trop_estat_pretrend, rclass
    version 17

    syntax [, Periods(integer 0) Level(real 95) ROBust]

    /* ──────────────────────────────────────────────────────────────────────
       1. Pre-checks
    ────────────────────────────────────────────────────────────────────── */

    // Check: must follow trop estimation
    if "`e(cmd)'" != "trop" {
        di as error "estat pretrend requires trop estimation results"
        exit 301
    }

    // Check: only twostep method supports event-study decomposition
    if "`e(method)'" != "twostep" {
        di as error "estat pretrend requires method(twostep)"
        di as error "  The joint method estimates a single scalar tau,"
        di as error "  which cannot be decomposed into pre-period effects."
        exit 459
    }

    // Check: tau_matrix must exist
    capture confirm matrix e(tau_matrix)
    if _rc {
        di as error "e(tau_matrix) not found. Re-run trop with method(twostep)."
        exit 301
    }

    // Validate level
    if `level' <= 0 | `level' >= 100 {
        di as error "level() must be between 0 and 100"
        exit 198
    }

    /* ──────────────────────────────────────────────────────────────────────
       2. Retrieve required variables and call Mata function
    ────────────────────────────────────────────────────────────────────── */

    local depvar   "`e(depvar)'"
    local panelvar "`e(panelvar)'"
    local timevar  "`e(timevar)'"
    local treatvar "`e(treatvar)'"

    // Determine number of pre-periods to test
    // If not specified (0), let the Mata function use all available pre-periods
    local n_periods = `periods'

    // Rebuild 1..N / 1..T index variables from e(panelvar)/e(timevar)
    // (the original tempvars are gone after trop_cleanup_temp_vars)
    tempvar _pt_pidx _pt_tidx _pt_touse_tmp
    qui gen byte `_pt_touse_tmp' = e(sample)
    qui egen `_pt_pidx' = group(`panelvar') if `_pt_touse_tmp'
    qui egen `_pt_tidx' = group(`timevar') if `_pt_touse_tmp'
    mata: st_global("__trop_panel_idx_var", st_local("_pt_pidx"))
    mata: st_global("__trop_time_idx_var", st_local("_pt_tidx"))
    mata: st_global("__trop_touse_var", st_local("_pt_touse_tmp"))

    // Call Mata function to compute and display the pre-trend test
    mata: _trop_run_pretrend_test(`n_periods', `level', "`robust'", ///
        "`depvar'", "`panelvar'", "`timevar'", "`treatvar'")

    /* ──────────────────────────────────────────────────────────────────────
       3. Retrieve results from Mata and store in r()
    ────────────────────────────────────────────────────────────────────── */

    if scalar(__pretrend_chi2) < . {
        return scalar chi2          = scalar(__pretrend_chi2)
        return scalar df            = scalar(__pretrend_df)
        return scalar p             = scalar(__pretrend_p)
        return scalar pretrend_pass = scalar(__pretrend_pass)
        return scalar n_preperiods  = scalar(__pretrend_nperiods)
    }
    else {
        di as error "Pre-trend test could not be computed."
        di as error "Ensure that model components (alpha, beta, factor_matrix) are available."
        exit 459
    }

    // Clean up temporary scalars
    capture scalar drop __pretrend_chi2
    capture scalar drop __pretrend_df
    capture scalar drop __pretrend_p
    capture scalar drop __pretrend_pass
    capture scalar drop __pretrend_nperiods
end
