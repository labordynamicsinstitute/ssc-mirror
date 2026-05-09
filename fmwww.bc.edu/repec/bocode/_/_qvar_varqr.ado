*! _qvar_varqr.ado — VAR-QR Two-Stage Model
*! Carboni, Fonseca, Fornari & Urrutia (2024), ECB WP 3171
*! Stage 1: OLS VAR for conditional mean
*! Stage 2: QR on residuals for time-varying variance
*! Version 1.1.0

program define _qvar_varqr, eclass
    version 16.0
    syntax varlist(min=2 ts), VARlags(integer) ///
        [QRlags(integer 1) TAUs(numlist >0 <1)]

    if "`taus'" == "" {
        local taus "0.10 0.90"
    }

    local varnames "`varlist'"
    local nvars : word count `varnames'
    local ntaus : word count `taus'

    qui tsset
    tempvar touse
    mark `touse'
    markout `touse' `varnames'

    // ─── Stage 1: OLS VAR ───
    di _n "{hline 78}"
    di _col(20) "VAR-QR Model Results"
    di _col(8) "Carboni et al. (2024, ECB WP 3171)"
    di "{hline 78}"
    di "  Variables    : `varnames'"
    di "  VAR lags     : `varlags'"
    di "  QR lags      : `qrlags'"
    di "  QR quantiles : `taus'"
    di "{hline 78}"
    di _n "  Stage 1: VAR Estimation (OLS)"
    di "  {hline 40}"

    qui var `varnames' if `touse', lags(1/`varlags')
    local var_aic = e(aic)

    foreach depvar of varlist `varnames' {
        qui predict double _varqr_resid_`depvar' if `touse', ///
            equation(`depvar') residuals
        di "    Eq. `depvar': AIC = " %8.2f `var_aic'
    }

    tempvar touse2
    mark `touse2'
    foreach vname of varlist `varnames' {
        markout `touse2' _varqr_resid_`vname'
    }
    qui count if `touse2'
    local T = r(N)
    di "  Observations : `T'"

    // ─── Stage 2: QR on Residuals ───
    // Use lagged |residuals| as regressors to capture volatility clustering
    di _n "  Stage 2: Time-Varying Variance (QR on residuals)"
    di "  {hline 40}"

    local eq_idx = 0
    foreach depvar of varlist `varnames' {
        local ++eq_idx

        // Build regressors: lagged absolute residuals for all equations
        local qr_regressors ""
        foreach rvar of varlist `varnames' {
            forvalues j = 1/`qrlags' {
                tempvar absres_`rvar'_`j'
                qui gen double `absres_`rvar'_`j'' = ///
                    abs(L`j'._varqr_resid_`rvar') if `touse2'
                local qr_regressors "`qr_regressors' `absres_`rvar'_`j''"
            }
        }

        // Mark valid obs after generating lags
        tempvar touse3
        mark `touse3'
        markout `touse3' `qr_regressors' _varqr_resid_`depvar'

        forvalues tau_idx = 1/`ntaus' {
            local tau : word `tau_idx' of `taus'
            local tau_label = subinstr("`tau'", ".", "_", .)

            capture {
                qui qreg _varqr_resid_`depvar' `qr_regressors' ///
                    if `touse3', quantile(`tau')
                tempvar qfit_`eq_idx'_`tau_idx'
                qui predict double `qfit_`eq_idx'_`tau_idx'' ///
                    if `touse3', xb
                matrix _varqr_qr_b_`depvar'_`tau_label' = e(b)
            }
            if _rc != 0 {
                di as error "  QR failed for `depvar' tau=`tau'"
                qui gen double `qfit_`eq_idx'_`tau_idx'' = 0 if `touse3'
            }
        }

        // Estimate sigma from interquantile range:
        // sigma_t = (Q_upper(t) - Q_lower(t)) / (Phi^{-1}(tau_up) - Phi^{-1}(tau_lo))
        // Use first and last tau as lower/upper
        local tau_lo : word 1 of `taus'
        local tau_hi : word `ntaus' of `taus'
        local phi_lo = invnormal(`tau_lo')
        local phi_hi = invnormal(`tau_hi')
        local phi_spread = `phi_hi' - `phi_lo'

        tempvar sigma_i
        qui gen double `sigma_i' = ///
            (`qfit_`eq_idx'_`ntaus'' - `qfit_`eq_idx'_1') / `phi_spread' ///
            if `touse3'
        qui replace `sigma_i' = max(`sigma_i', 1e-8) if `touse3'
        qui gen double _varqr_sigma_`depvar' = `sigma_i' if `touse3'

        qui sum _varqr_sigma_`depvar' if `touse3'
        di as result "    sigma(`depvar'): mean=" %8.4f r(mean) ///
                     ", std=" %8.4f r(sd)
    }

    // ─── Store results ───
    di _n "{hline 78}"
    ereturn clear
    ereturn local cmd       "qvar varqr"
    ereturn local varnames  "`varnames'"
    ereturn local taus      "`taus'"
    ereturn scalar n_vars   = `nvars'
    ereturn scalar var_lags = `varlags'
    ereturn scalar qr_lags  = `qrlags'
    ereturn scalar n_obs    = `T'
    ereturn scalar var_aic  = `var_aic'

    di "  Results stored. Variables: _varqr_resid_*, _varqr_sigma_*"
    di "{hline 78}"
end
