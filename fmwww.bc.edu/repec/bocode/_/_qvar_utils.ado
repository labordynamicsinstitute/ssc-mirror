*! _qvar_utils.ado — Utility functions for QVAR Stata package
*! Provides: lag matrix construction, ADF test wrappers,
*!           information criteria, quantile loss
*! Translated from Python qvar/utils.py
*! Version 0.1.0

// ─────────────────────────────────────────────────────────────────────────────
// build_lag_matrix: Create lagged variables for VAR/QVAR estimation
//   Generates L1..Lp lags for each variable in varlist.
//   Stores created variable names in r(lagvars) and r(nvars).
// ─────────────────────────────────────────────────────────────────────────────
program define _qvar_build_lags, rclass
    version 16.0
    syntax varlist(ts), Lags(integer) [TIMEvar(varname) PANELvar(varname)]

    local nvars : word count `varlist'
    local lagvars ""

    // Set time-series operators if panel/time specified
    if "`timevar'" != "" & "`panelvar'" != "" {
        tsset `panelvar' `timevar'
    }
    else if "`timevar'" != "" {
        tsset `timevar'
    }

    foreach var of varlist `varlist' {
        forvalues lag = 1/`lags' {
            local lagname = "`var'_L`lag'"
            capture drop `lagname'
            qui gen double `lagname' = L`lag'.`var'
            local lagvars "`lagvars' `lagname'"
        }
    }

    return local lagvars "`lagvars'"
    return scalar nvars = `nvars'
    return scalar nlags = `lags'
    return scalar nlagvars = `nvars' * `lags'
end

// ─────────────────────────────────────────────────────────────────────────────
// _qvar_adf_test: Run ADF test for stationarity on a variable
//   Wrapper around Stata's dfuller with AIC lag selection
// ─────────────────────────────────────────────────────────────────────────────
program define _qvar_adf_test, rclass
    version 16.0
    syntax varname [if] [in], [MAXLags(integer 0)]

    marksample touse

    // Default maxlags: int(12*(T/100)^0.25)
    if `maxlags' == 0 {
        qui count if `touse'
        local T = r(N)
        local maxlags = floor(12 * (`T'/100)^0.25)
    }

    // Run ADF test
    qui dfuller `varlist' if `touse', lags(`maxlags')

    return scalar adf_stat  = r(Zt)
    return scalar adf_pval  = r(p)
    return scalar adf_lags  = `maxlags'
    return scalar adf_nobs  = r(N)
    return scalar stationary = (r(p) < 0.05)
end

// ─────────────────────────────────────────────────────────────────────────────
// _qvar_stationarity_check: Run ADF on all variables, display summary table
// ─────────────────────────────────────────────────────────────────────────────
program define _qvar_stationarity_check
    version 16.0
    syntax varlist [if] [in], [SIGnificance(real 0.05)]

    marksample touse

    di as text ""
    di as text "{hline 78}"
    di as text "  Stationarity Tests (Augmented Dickey-Fuller)"
    di as text "{hline 78}"
    di as text %20s "Variable" %14s "ADF Stat" %12s "p-value" %8s "Lags" %14s "Stationary"
    di as text "{hline 78}"

    foreach var of varlist `varlist' {
        _qvar_adf_test `var' if `touse'
        local stat   = r(adf_stat)
        local pval   = r(adf_pval)
        local nlags  = r(adf_lags)
        local stnry  = cond(r(stationary), "Yes", "No")

        di as result %20s "`var'" ///
                     %14.4f `stat' ///
                     %12.4f `pval' ///
                     %8.0f  `nlags' ///
                     %14s   "`stnry'"
    }

    di as text "{hline 78}"
    di as text "  Significance level: `significance'"
    di as text "{hline 78}"
end

// ─────────────────────────────────────────────────────────────────────────────
// _qvar_info_criteria: Compute AIC, BIC, HQ from residual matrix
//   Input: matrix of residuals (T x n), number of parameters
//   Returns: r(AIC), r(BIC), r(HQ)
// ─────────────────────────────────────────────────────────────────────────────
program define _qvar_info_criteria, rclass
    version 16.0
    args resid_matname nparams T_obs

    tempname Sigma logdet

    // Sigma = (1/T) * resid' * resid
    matrix `Sigma' = (1/`T_obs') * (`resid_matname'' * `resid_matname')
    scalar `logdet' = ln(det(`Sigma'))

    local n = colsof(`Sigma')

    return scalar AIC = `logdet' + 2 * `nparams' * `n' / `T_obs'
    return scalar BIC = `logdet' + ln(`T_obs') * `nparams' * `n' / `T_obs'
    return scalar HQ  = `logdet' + 2 * ln(ln(`T_obs')) * `nparams' * `n' / `T_obs'
end

// ─────────────────────────────────────────────────────────────────────────────
// _qvar_quantile_loss: Compute check function ρ_τ(u) = u*(τ - I{u<0})
//   Creates variable __qloss in the dataset (overwrites if exists)
// ─────────────────────────────────────────────────────────────────────────────
program define _qvar_quantile_loss, rclass
    version 16.0
    syntax varname, TAU(real)

    tempvar indicator qloss
    qui gen double `indicator' = (`varlist' < 0)
    qui gen double `qloss' = `varlist' * (`tau' - `indicator')
    qui sum `qloss', meanonly
    return scalar qloss_mean = r(mean)
end

// ─────────────────────────────────────────────────────────────────────────────
// _qvar_significance_stars: Return significance stars from p-value
// ─────────────────────────────────────────────────────────────────────────────
program define _qvar_significance_stars, rclass
    version 16.0
    args pvalue

    if `pvalue' < 0.01 {
        return local stars "***"
    }
    else if `pvalue' < 0.05 {
        return local stars "**"
    }
    else if `pvalue' < 0.10 {
        return local stars "*"
    }
    else {
        return local stars ""
    }
end
