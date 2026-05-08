*! _qvar_varqr.ado — VAR-QR Two-Stage Model
*! Carboni, Fonseca, Fornari & Urrutia (2024), ECB WP 3171
*! Stage 1: OLS VAR for conditional mean
*! Stage 2: QR on residuals for time-varying variance
*! Version 0.1.0

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
    di _n "  Stage 2: Time-Varying Variance (QR on residuals)"
    di "  {hline 40}"

    local qr_regressors ""
    foreach var of varlist `varnames' {
        forvalues j = 1/`qrlags' {
            tempvar qrx_`var'_`j'
            qui gen double `qrx_`var'_`j'' = L`j'.`var' if `touse2'
            local qr_regressors "`qr_regressors' `qrx_`var'_`j''"
        }
    }

    local eq_idx = 0
    foreach depvar of varlist `varnames' {
        local ++eq_idx

        forvalues tau_idx = 1/`ntaus' {
            local tau : word `tau_idx' of `taus'
            local tau_label = subinstr("`tau'", ".", "_", .)

            capture {
                qui qreg _varqr_resid_`depvar' `qr_regressors' ///
                    if `touse2', quantile(`tau')
                tempvar qfit_`eq_idx'_`tau_idx'
                qui predict double `qfit_`eq_idx'_`tau_idx'' ///
                    if `touse2', xb
                matrix _varqr_qr_b_`depvar'_`tau_label' = e(b)
            }
            if _rc != 0 {
                di as error "  QR failed for `depvar' tau=`tau'"
                qui gen double `qfit_`eq_idx'_`tau_idx'' = 0 if `touse2'
            }
        }

        // sigma = sum(Q*phi_inv) / sum(phi_inv^2)
        tempvar sigma_i denom_i
        qui gen double `denom_i' = 0
        qui gen double `sigma_i' = 0

        forvalues tau_idx = 1/`ntaus' {
            local tau : word `tau_idx' of `taus'
            local phi_inv = invnormal(`tau')
            qui replace `sigma_i' = `sigma_i' + ///
                `qfit_`eq_idx'_`tau_idx'' * `phi_inv' if `touse2'
            qui replace `denom_i' = `denom_i' + `phi_inv'^2 if `touse2'
        }

        qui replace `sigma_i' = `sigma_i' / `denom_i' if `touse2'
        qui replace `sigma_i' = max(`sigma_i', 1e-8) if `touse2'
        qui gen double _varqr_sigma_`depvar' = `sigma_i' if `touse2'

        qui sum _varqr_sigma_`depvar' if `touse2'
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
