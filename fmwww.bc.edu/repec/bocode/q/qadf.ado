*! qadf - Quantile ADF Unit Root Test
*! Version 1.0.0, February 2026
*! Author: Dr. Merwan Roudane
*! Email: merwanroudane920@gmail.com
*!
*! Reference:
*!   Koenker, R., Xiao, Z., 2004.
*!   Unit Root Quantile Autoregression Inference.
*!   Journal of the American Statistical Association 99, 775-787.
*!   DOI: 10.1198/016214504000001114
*!
*! Critical Values:
*!   Hansen, B. (1995). Rethinking the Univariate Approach to Unit Root Tests.
*!   Econometric Theory, 11, 1148-1171.

program define qadf, rclass sortpreserve
    version 14.0

    syntax varname(ts) [if] [in], [           ///
        TAU(real 0.5)                         /// Quantile (0 < tau < 1)
        Model(string)                         /// Model: c (constant) or ct (constant+trend)
        MAXLags(integer 8)                    /// Maximum ADF lags
        IC(string)                            /// Info criterion: aic, bic, tstat
        Level(cilevel)                        /// Confidence level
        NOPRint                               /// Suppress output
        ]

    *--------------------------------------------------------------------------
    * Load Mata library
    *--------------------------------------------------------------------------
    capture findfile _qadf_mata.ado
    if _rc {
        di as error "Required file _qadf_mata.ado not found."
        di as error "Ensure the QADF package is properly installed."
        exit 601
    }
    qui run `"`r(fn)'"'

    *--------------------------------------------------------------------------
    * Input validation
    *--------------------------------------------------------------------------
    marksample touse
    _ts timevar panelvar if `touse', sort onepanel
    markout `touse' `timevar'

    * Validate tau
    if `tau' <= 0 | `tau' >= 1 {
        di as error "tau() must be strictly between 0 and 1"
        exit 198
    }

    * Validate model
    if "`model'" == "" {
        local model "c"
    }
    else {
        local model = lower("`model'")
        if !inlist("`model'", "c", "ct") {
            di as error "model() must be {bf:c} (constant) or {bf:ct} (constant + trend)"
            exit 198
        }
    }

    * Validate IC
    if "`ic'" == "" {
        local ic "aic"
    }
    else {
        local ic = lower("`ic'")
        if !inlist("`ic'", "aic", "bic", "tstat") {
            di as error "ic() must be {bf:aic}, {bf:bic}, or {bf:tstat}"
            exit 198
        }
    }

    * Validate maxlags
    if `maxlags' < 0 {
        di as error "maxlags() must be non-negative"
        exit 198
    }

    * Check sample size
    qui count if `touse'
    local N = r(N)
    if `N' < 20 {
        di as error "insufficient observations (need at least 20, have `N')"
        exit 2001
    }

    *--------------------------------------------------------------------------
    * Compute QADF test via Mata
    *--------------------------------------------------------------------------
    tempvar y_temp
    qui gen double `y_temp' = `varlist' if `touse'

    mata: qadf_compute("`y_temp'", `tau', "`model'", `maxlags', "`ic'", "`touse'")

    * Retrieve results from Mata
    local qadf_stat = r(qadf_stat)
    local coef_stat = r(coef_stat)
    local rho_tau   = r(rho_tau)
    local rho_ols   = r(rho_ols)
    local alpha_tau = r(alpha_tau)
    local delta2    = r(delta2)
    local half_life = r(half_life)
    local opt_lags  = r(lags)
    local nobs      = r(nobs)
    local cv1       = r(cv1)
    local cv5       = r(cv5)
    local cv10      = r(cv10)

    *--------------------------------------------------------------------------
    * Significance determination
    *--------------------------------------------------------------------------
    local stars ""
    local decision "Cannot reject H0: Evidence consistent with unit root"
    if `qadf_stat' < `cv1' {
        local stars "***"
        local decision "Reject H0 at 1%: Strong evidence of stationarity"
    }
    else if `qadf_stat' < `cv5' {
        local stars "**"
        local decision "Reject H0 at 5%: Evidence of stationarity"
    }
    else if `qadf_stat' < `cv10' {
        local stars "*"
        local decision "Reject H0 at 10%: Weak evidence of stationarity"
    }

    * Half-life display
    if `half_life' == . {
        local hl_display "{c -}{c -}{c -}"
    }
    else {
        local hl_display : di %9.2f `half_life'
    }

    * Model label
    if "`model'" == "c" {
        local model_label "Constant"
    }
    else {
        local model_label "Constant + Trend"
    }

    *--------------------------------------------------------------------------
    * Display beautiful results table
    *--------------------------------------------------------------------------
    if "`noprint'" == "" {

        di
        di as txt "{hline 78}"
        di as txt "{col 5}{bf:Quantile ADF Unit Root Test}"
        di as txt "{col 5}{it:Koenker, R., Xiao, Z. (2004). JASA, 99, 775-787.}"
        di as txt "{hline 78}"
        di
        di as txt "{col 5}Variable:{col 25}" as res "`varlist'" ///
           as txt "{col 45}Number of obs{col 62}=" as res %10.0f `nobs'
        di as txt "{col 5}Model:{col 25}" as res "`model_label'" ///
           as txt "{col 45}Optimal lags{col 62}=" as res %10.0f `opt_lags'
        di as txt "{col 5}Quantile (tau):{col 25}" as res %7.3f `tau' ///
           as txt "{col 45}IC:{col 62}" as res %10s "`ic'"
        di
        di as txt "{hline 78}"
        di as txt "{col 25}{bf:Coefficient Estimates}"
        di as txt "{hline 78}"
        di
        di as txt "{col 5}rho_1(tau) [QR]:{col 35}" as res %12.6f `rho_tau'
        di as txt "{col 5}rho_1     [OLS]:{col 35}" as res %12.6f `rho_ols'
        di as txt "{col 5}alpha_0(tau):{col 35}" as res %12.6f `alpha_tau'
        di as txt "{col 5}delta-sq:{col 35}" as res %12.6f `delta2'
        di as txt "{col 5}Half-life:{col 35}" as res "`hl_display'"
        di
        di as txt "{hline 78}"
        di as txt "{col 25}{bf:Test Statistics}"
        di as txt "{hline 78}"
        di
        di as txt "{col 5}{bf:t_n(tau):{col 35}}" as res %12.4f `qadf_stat' ///
           as txt "  `stars'"
        di as txt "{col 5}U_n(tau) = n(rho-1):{col 35}" as res %12.4f `coef_stat'
        di
        di as txt "{hline 78}"
        di as txt "{col 25}{bf:Critical Values (Hansen, 1995)}"
        di as txt "{hline 78}"
        di
        di as txt "{col 5}" _col(20) "1%" _col(35) "5%" _col(50) "10%"
        di as txt "{col 5}" _col(17) as res %10.4f `cv1' ///
           _col(32) as res %10.4f `cv5' ///
           _col(47) as res %10.4f `cv10'
        di
        di as txt "{hline 78}"
        di as txt "{col 5}{bf:Decision:}"
        if "`stars'" != "" {
            di as res "{col 5}`decision'"
        }
        else {
            di as txt "{col 5}`decision'"
        }
        di as txt "{hline 78}"
        di as txt "{col 5}Note: *** p<0.01, ** p<0.05, * p<0.10"
        di as txt "{col 5}H0: Unit root (rho_1 = 1)  vs  H1: Stationarity (rho_1 < 1)"
        di as txt "{hline 78}"
    }

    *--------------------------------------------------------------------------
    * Return results
    *--------------------------------------------------------------------------
    return scalar N        = `nobs'
    return scalar tau      = `tau'
    return scalar lags     = `opt_lags'

    return scalar qadf     = `qadf_stat'
    return scalar Unstat   = `coef_stat'

    return scalar rho_tau  = `rho_tau'
    return scalar rho_ols  = `rho_ols'
    return scalar alpha_tau = `alpha_tau'
    return scalar delta2   = `delta2'
    return scalar half_life = `half_life'

    return scalar cv1      = `cv1'
    return scalar cv5      = `cv5'
    return scalar cv10     = `cv10'

    return local varname   "`varlist'"
    return local model     "`model'"
    return local ic        "`ic'"
    return local cmd       "qadf"
end
