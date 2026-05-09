*! _qvar_utils.ado — Utility functions for QVAR Stata package
*! Provides: ADF test wrapper, information criteria, quantile loss
*! These programs have NO standalone .ado files — they live only here.
*! Loaded automatically when any program in this file is called.
*! Version 1.1.0

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
