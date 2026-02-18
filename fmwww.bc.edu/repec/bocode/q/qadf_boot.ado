*! qadf_boot - Quantile ADF Unit Root Test: Bootstrap Inference
*! Version 1.0.0, February 2026
*! Author: Dr. Merwan Roudane
*! Email: merwanroudane920@gmail.com
*!
*! Reference:
*!   Koenker, R., Xiao, Z., 2004. Section 3.2
*!   Unit Root Quantile Autoregression Inference.
*!   Journal of the American Statistical Association 99, 775-787.
*!
*! Bootstrap procedure (Section 3.2 of paper):
*!   Step 1: Fit AR(q) to w_t = dy_t by OLS
*!   Step 2: Draw iid {u*_t} from centered residuals
*!   Step 3: Generate y*_t under null (unit root): y*_t = y*_{t-1} + w*_t
*!   Step 4: Estimate QAR regression on bootstrap sample

program define qadf_boot, rclass sortpreserve
    version 14.0

    syntax varname(ts) [if] [in], [           ///
        TAU(real 0.5)                         /// Quantile
        Model(string)                         /// Model: c or ct
        MAXLags(integer 8)                    /// Maximum ADF lags
        IC(string)                            /// Info criterion
        REPS(integer 399)                     /// Bootstrap replications
        SEED(integer -1)                      /// Random seed
        Level(cilevel)                        /// Confidence level
        ]

    *--------------------------------------------------------------------------
    * Load Mata library
    *--------------------------------------------------------------------------
    capture findfile _qadf_mata.ado
    if _rc {
        di as error "Required file _qadf_mata.ado not found."
        exit 601
    }
    qui run `"`r(fn)'"'

    *--------------------------------------------------------------------------
    * Validate inputs
    *--------------------------------------------------------------------------
    marksample touse
    _ts timevar panelvar if `touse', sort onepanel
    markout `touse' `timevar'

    if `tau' <= 0 | `tau' >= 1 {
        di as error "tau() must be strictly between 0 and 1"
        exit 198
    }

    if "`model'" == "" local model "c"
    local model = lower("`model'")
    if !inlist("`model'", "c", "ct") {
        di as error "model() must be {bf:c} or {bf:ct}"
        exit 198
    }

    if "`ic'" == "" local ic "aic"
    local ic = lower("`ic'")
    if !inlist("`ic'", "aic", "bic", "tstat") {
        di as error "ic() must be {bf:aic}, {bf:bic}, or {bf:tstat}"
        exit 198
    }

    if `reps' < 50 {
        di as error "reps() should be at least 50"
        exit 198
    }

    qui count if `touse'
    local N = r(N)

    if "`model'" == "c" {
        local model_label "Constant"
    }
    else {
        local model_label "Constant + Trend"
    }

    *--------------------------------------------------------------------------
    * First, run the original QADF test
    *--------------------------------------------------------------------------
    qui qadf `varlist' if `touse', tau(`tau') model(`model') ///
        maxlags(`maxlags') ic(`ic') noprint

    local qadf_stat   = r(qadf)
    local coef_stat   = r(Unstat)
    local rho_tau     = r(rho_tau)
    local rho_ols     = r(rho_ols)
    local alpha_tau   = r(alpha_tau)
    local delta2      = r(delta2)
    local half_life   = r(half_life)
    local opt_lags    = r(lags)
    local nobs        = r(N)
    local cv1_hansen  = r(cv1)
    local cv5_hansen  = r(cv5)
    local cv10_hansen = r(cv10)

    *--------------------------------------------------------------------------
    * Run bootstrap
    *--------------------------------------------------------------------------
    di as txt _n "{col 5}Running bootstrap (`reps' replications)..."
    di as txt "{col 5}Bootstrap DGP: AR(`opt_lags') sieve under H0 (unit root)"

    tempvar y_temp
    qui gen double `y_temp' = `varlist' if `touse'

    local seed_val = `seed'
    if `seed_val' == -1 local seed_val = .

    mata: qadf_bootstrap("`y_temp'", `tau', "`model'", `maxlags', ///
        "`ic'", `reps', `seed_val', "`touse'", `qadf_stat')

    local boot_nv = r(boot_nvalid)

    if `boot_nv' < 10 {
        di as error "Insufficient valid bootstrap replications (`boot_nv' out of `reps')"
        exit 198
    }

    local boot_pvalue   = r(boot_pvalue)
    local boot_cv1_t    = r(boot_cv1_t)
    local boot_cv5_t    = r(boot_cv5_t)
    local boot_cv10_t   = r(boot_cv10_t)
    local boot_cv1_u    = r(boot_cv1_u)
    local boot_cv5_u    = r(boot_cv5_u)
    local boot_cv10_u   = r(boot_cv10_u)

    * Significance
    local stars ""
    local decision "Cannot reject H0: Evidence consistent with unit root"
    if `boot_pvalue' <= 0.01 {
        local stars "***"
        local decision "Reject H0 at 1%: Strong evidence of stationarity"
    }
    else if `boot_pvalue' <= 0.05 {
        local stars "**"
        local decision "Reject H0 at 5%: Evidence of stationarity"
    }
    else if `boot_pvalue' <= 0.10 {
        local stars "*"
        local decision "Reject H0 at 10%: Weak evidence of stationarity"
    }

    *--------------------------------------------------------------------------
    * Display results
    *--------------------------------------------------------------------------
    di
    di as txt "{hline 78}"
    di as txt "{col 5}{bf:Quantile ADF Unit Root Test — Bootstrap Inference}"
    di as txt "{col 5}{it:Koenker, R., Xiao, Z. (2004). JASA, 99, 775-787.}"
    di as txt "{hline 78}"
    di
    di as txt "{col 5}Variable:{col 25}" as res "`varlist'" ///
       as txt "{col 45}Number of obs{col 62}=" as res %10.0f `nobs'
    di as txt "{col 5}Model:{col 25}" as res "`model_label'" ///
       as txt "{col 45}Optimal lags{col 62}=" as res %10.0f `opt_lags'
    di as txt "{col 5}Quantile (tau):{col 25}" as res %7.3f `tau' ///
       as txt "{col 45}Bootstrap reps{col 62}=" as res %10.0f `reps'
    di as txt "{col 5}rho_1(tau):{col 25}" as res %9.6f `rho_tau' ///
       as txt "{col 45}Valid replications{col 62}=" as res %10.0f `boot_nv'
    di
    di as txt "{hline 78}"
    di as txt "{col 5}{bf:Test Statistic:}  t_n(tau) =" as res %9.4f `qadf_stat' ///
       as txt "  `stars'"
    di as txt "{col 5}{bf:Bootstrap p-value:}" as res %12.4f `boot_pvalue'
    di as txt "{hline 78}"
    di
    di as txt "{col 5}{bf:Critical Values Comparison}"
    di as txt "{hline 78}"
    di as txt _col(28) "1%" _col(43) "5%" _col(58) "10%"
    di as txt "{col 5}Hansen (1995):" ///
       _col(25) as res %10.4f `cv1_hansen' ///
       _col(40) as res %10.4f `cv5_hansen' ///
       _col(55) as res %10.4f `cv10_hansen'
    di as txt "{col 5}Bootstrap:" ///
       _col(25) as res %10.4f `boot_cv1_t' ///
       _col(40) as res %10.4f `boot_cv5_t' ///
       _col(55) as res %10.4f `boot_cv10_t'
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
    di as txt "{col 5}Bootstrap DGP: AR sieve under H0 (Section 3.2 of paper)"
    di as txt "{hline 78}"

    *--------------------------------------------------------------------------
    * Return results
    *--------------------------------------------------------------------------
    return scalar N         = `nobs'
    return scalar tau       = `tau'
    return scalar lags      = `opt_lags'

    return scalar qadf      = `qadf_stat'
    return scalar Unstat    = `coef_stat'
    return scalar rho_tau   = `rho_tau'
    return scalar delta2    = `delta2'

    return scalar boot_pvalue  = `boot_pvalue'
    return scalar boot_cv1_t   = `boot_cv1_t'
    return scalar boot_cv5_t   = `boot_cv5_t'
    return scalar boot_cv10_t  = `boot_cv10_t'
    return scalar boot_cv1_u   = `boot_cv1_u'
    return scalar boot_cv5_u   = `boot_cv5_u'
    return scalar boot_cv10_u  = `boot_cv10_u'
    return scalar boot_nvalid  = `boot_nv'
    return scalar boot_nreps   = `reps'

    return scalar cv1_hansen   = `cv1_hansen'
    return scalar cv5_hansen   = `cv5_hansen'
    return scalar cv10_hansen  = `cv10_hansen'

    return local varname    "`varlist'"
    return local model      "`model'"
    return local ic         "`ic'"
    return local cmd        "qadf_boot"
end
