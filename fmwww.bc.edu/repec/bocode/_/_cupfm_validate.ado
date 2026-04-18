*! _cupfm_validate.ado - Input validation for cupfm
*! Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)
*! Version: 1.0.1 - 2026-04-16 (First SSC submission)

capture program drop _cupfm_validate
program define _cupfm_validate, rclass
    version 14
    // STATA 17 BATCH FIX: integer() and real() options cause r(197).
    // All numeric options declared as string() and converted manually.
    syntax varlist(min=2 numeric ts) [if] [in], ///
        [NFactors(string) BANDwidth(string) MAXiter(string) TOLerance(string)]

    // Convert string -> numeric & apply defaults
    if "`nfactors'"  == "" local nfactors  0
    else                    local nfactors  = real("`nfactors'")
    if "`bandwidth'" == "" local bandwidth 5
    else                    local bandwidth = real("`bandwidth'")
    if "`maxiter'"   == "" local maxiter   20
    else                    local maxiter   = real("`maxiter'")
    if "`tolerance'" == "" local tolerance 0.0001
    else                    local tolerance = real("`tolerance'")

    // Convert to integer where needed
    local nfactors  = int(`nfactors')
    local bandwidth = int(`bandwidth')
    local maxiter   = int(`maxiter')

    marksample touse

    // --- Check xtset ─────────────────────────────────────────────────────────
    quietly xtset
    local panelvar "`r(panelvar)'"
    local timevar  "`r(timevar)'"
    if "`panelvar'" == "" | "`timevar'" == "" {
        di as error "Data must be xtset before using cupfm."
        exit 459
    }

    // --- Panel dimensions ────────────────────────────────────────────────────
    quietly xtsum `timevar' if `touse'
    local N_g = r(n)   // number of cross-section units

    // Get T: count obs in touse for one unit using bysort
    tempvar cnt_t
    quietly bysort `panelvar' (`timevar'): gen `cnt_t' = _N if `touse'
    quietly summarize `cnt_t' if `touse'
    local T_min = r(min)
    local T_max = r(max)
    drop `cnt_t'

    if `N_g' < 2 {
        di as error "cupfm requires at least 2 cross-section units (N >= 2)."
        exit 2001
    }
    if `T_min' < 5 {
        di as error "cupfm requires at least 5 time periods per unit (T >= 5)."
        exit 2001
    }
    if `T_min' != `T_max' {
        di as error "cupfm requires a balanced panel (T must be equal for all units)."
        di as error "  Min T = `T_min', Max T = `T_max'."
        exit 2001
    }
    local T_obs = `T_min'

    // --- Check variables ──────────────────────────────────────────────────────
    local depvar    : word 1 of `varlist'
    local indepvars : list varlist - depvar

    foreach v of local varlist {
        quietly count if missing(`v') & `touse'
        if r(N) > 0 {
            di as error "Variable `v' has `r(N)' missing values. Drop them or restrict sample."
            exit 416
        }
    }

    // --- Validate NFactors ────────────────────────────────────────────────────
    local rmax = min(`N_g', `T_obs') / 2
    if `nfactors' < 0 {
        di as error "nfactors() must be non-negative (0 = auto-select using Bai-Ng 2002 IC)."
        exit 198
    }
    if `nfactors' > `rmax' {
        di as error "nfactors(`nfactors') exceeds maximum allowed = min(N,T)/2 = `rmax'."
        exit 198
    }

    // --- Validate bandwidth ───────────────────────────────────────────────────
    if `bandwidth' < 1 {
        di as error "bandwidth() must be at least 1."
        exit 198
    }
    if `bandwidth' > `T_obs' - 2 {
        di as error "bandwidth() too large for T=`T_obs'. Reduce to <= `=`T_obs'-2'."
        exit 198
    }

    // --- Validate maxiter ─────────────────────────────────────────────────────
    if `maxiter' < 1 | `maxiter' > 500 {
        di as error "maxiter() must be between 1 and 500."
        exit 198
    }

    // --- Return ───────────────────────────────────────────────────────────────
    return scalar N_g      = `N_g'
    return scalar T        = `T_obs'
    return scalar N_obs    = `N_g' * `T_obs'
    return scalar rmax     = `rmax'
    return local panelvar  = "`panelvar'"
    return local timevar   = "`timevar'"
    return local depvar    = "`depvar'"
    return local indepvars = "`indepvars'"
    return local balanced  = "Balanced"
end
