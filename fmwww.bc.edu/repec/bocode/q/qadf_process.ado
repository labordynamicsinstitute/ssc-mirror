*! qadf_process - Quantile ADF Unit Root Test: Multi-Quantile Process
*! Version 1.0.0, February 2026
*! Author: Dr. Merwan Roudane
*! Email: merwanroudane920@gmail.com
*!
*! Reference:
*!   Koenker, R., Xiao, Z., 2004.
*!   Unit Root Quantile Autoregression Inference.
*!   Journal of the American Statistical Association 99, 775-787.
*!
*! Computes QADF at multiple quantiles and global test statistics:
*!   QKS_alpha = sup|U_n(tau)|  (eq 13)
*!   QKS_t     = sup|t_n(tau)|  (eq 13)
*!   QCM_alpha = int U_n(tau)^2 dtau  (eq 14)
*!   QCM_t     = int t_n(tau)^2 dtau  (eq 14)

program define qadf_process, rclass sortpreserve
    version 14.0

    syntax varname(ts) [if] [in], [           ///
        Quantiles(numlist >0 <1)              /// Quantiles to evaluate
        Model(string)                         /// Model: c or ct
        MAXLags(integer 8)                    /// Maximum ADF lags
        IC(string)                            /// Info criterion: aic, bic, tstat
        Level(cilevel)                        /// Confidence level
        BOOTstrap                             /// Use bootstrap for QKS/QCM CVs
        REPS(integer 399)                     /// Bootstrap replications
        SEED(integer -1)                      /// Random seed
        ]

    *--------------------------------------------------------------------------
    * Defaults
    *--------------------------------------------------------------------------
    if "`quantiles'" == "" {
        local quantiles "0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9"
    }
    if "`model'" == "" local model "c"
    if "`ic'" == "" local ic "aic"

    * Count quantiles
    local nq : word count `quantiles'

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

    local model = lower("`model'")
    if !inlist("`model'", "c", "ct") {
        di as error "model() must be {bf:c} (constant) or {bf:ct} (constant + trend)"
        exit 198
    }
    local ic = lower("`ic'")
    if !inlist("`ic'", "aic", "bic", "tstat") {
        di as error "ic() must be {bf:aic}, {bf:bic}, or {bf:tstat}"
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
    * Run QADF at each quantile
    *--------------------------------------------------------------------------
    tempname tau_mat rho_mat tstat_mat ustat_mat d2_mat cv1_mat cv5_mat cv10_mat hl_mat

    mat `tau_mat'   = J(`nq', 1, .)
    mat `rho_mat'   = J(`nq', 1, .)
    mat `tstat_mat' = J(`nq', 1, .)
    mat `ustat_mat' = J(`nq', 1, .)
    mat `d2_mat'    = J(`nq', 1, .)
    mat `cv1_mat'   = J(`nq', 1, .)
    mat `cv5_mat'   = J(`nq', 1, .)
    mat `cv10_mat'  = J(`nq', 1, .)
    mat `hl_mat'    = J(`nq', 1, .)

    local i = 1
    local opt_lags = .
    foreach tau of numlist `quantiles' {

        qui qadf `varlist' if `touse', tau(`tau') model(`model') ///
            maxlags(`maxlags') ic(`ic') noprint

        mat `tau_mat'[`i', 1]   = `tau'
        mat `rho_mat'[`i', 1]   = r(rho_tau)
        mat `tstat_mat'[`i', 1] = r(qadf)
        mat `ustat_mat'[`i', 1] = r(Unstat)
        mat `d2_mat'[`i', 1]    = r(delta2)
        mat `cv1_mat'[`i', 1]   = r(cv1)
        mat `cv5_mat'[`i', 1]   = r(cv5)
        mat `cv10_mat'[`i', 1]  = r(cv10)
        mat `hl_mat'[`i', 1]    = r(half_life)

        if `i' == 1 {
            local opt_lags = r(lags)
            local nobs = r(N)
            local rho_ols = r(rho_ols)
        }

        local i = `i' + 1
    }

    *--------------------------------------------------------------------------
    * Compute QKS and QCM statistics (equations 13-14)
    *--------------------------------------------------------------------------
    * QKS_alpha = max|U_n(tau)|
    * QKS_t     = max|t_n(tau)|
    * QCM_alpha = sum U_n(tau)^2 * dtau  (trapezoidal)
    * QCM_t     = sum t_n(tau)^2 * dtau  (trapezoidal)

    local qks_alpha = 0
    local qks_t = 0
    local qcm_alpha = 0
    local qcm_t = 0

    forvalues i = 1/`nq' {
        * QKS: supremum
        local abs_u = abs(`=`ustat_mat'[`i', 1]')
        local abs_t = abs(`=`tstat_mat'[`i', 1]')

        if `abs_u' > `qks_alpha' local qks_alpha = `abs_u'
        if `abs_t' > `qks_t' local qks_t = `abs_t'

        * QCM: numerical integration (trapezoidal)
        if `i' < `nq' {
            local dtau = `=`tau_mat'[`=`i'+1', 1]' - `=`tau_mat'[`i', 1]'
        }
        else {
            if `nq' >= 2 {
                local dtau = `=`tau_mat'[`i', 1]' - `=`tau_mat'[`=`i'-1', 1]'
            }
            else {
                local dtau = 1
            }
        }

        local u_sq = (`=`ustat_mat'[`i', 1]')^2
        local t_sq = (`=`tstat_mat'[`i', 1]')^2

        local qcm_alpha = `qcm_alpha' + `u_sq' * `dtau'
        local qcm_t = `qcm_t' + `t_sq' * `dtau'
    }

    *--------------------------------------------------------------------------
    * Bootstrap QKS/QCM critical values (if requested)
    *--------------------------------------------------------------------------
    if "`bootstrap'" != "" {
        di as txt _n "{col 5}Computing bootstrap critical values (`reps' replications)..."

        tempvar y_temp
        qui gen double `y_temp' = `varlist' if `touse'

        local seed_val = `seed'
        if `seed_val' == -1 local seed_val = .

        mata: qadf_bootstrap_process("`y_temp'", "`quantiles'", ///
            "`model'", `maxlags', "`ic'", `reps', `seed_val', "`touse'")

        local boot_nv = r(boot_nvalid)

        if `boot_nv' >= 10 {
            local boot_qks_a_5  = r(boot_qks_a_5)
            local boot_qks_a_10 = r(boot_qks_a_10)
            local boot_qks_t_5  = r(boot_qks_t_5)
            local boot_qks_t_10 = r(boot_qks_t_10)
            local boot_qcm_a_5  = r(boot_qcm_a_5)
            local boot_qcm_a_10 = r(boot_qcm_a_10)
            local boot_qcm_t_5  = r(boot_qcm_t_5)
            local boot_qcm_t_10 = r(boot_qcm_t_10)
        }
        else {
            di as error "Warning: Insufficient valid bootstrap replications (`boot_nv')"
            local bootstrap ""
        }
    }

    *--------------------------------------------------------------------------
    * Display beautiful results
    *--------------------------------------------------------------------------
    di
    di as txt "{hline 96}"
    di as txt "{col 5}{bf:Quantile ADF Unit Root Test — Multi-Quantile Process}"
    di as txt "{col 5}{it:Koenker, R., Xiao, Z. (2004). JASA, 99, 775-787.}"
    di as txt "{hline 96}"
    di
    di as txt "{col 5}Variable:{col 25}" as res "`varlist'" ///
       as txt "{col 45}Number of obs{col 62}=" as res %10.0f `nobs'
    di as txt "{col 5}Model:{col 25}" as res "`model_label'" ///
       as txt "{col 45}Optimal lags{col 62}=" as res %10.0f `opt_lags'
    di as txt "{col 5}Quantiles:{col 25}" as res "`nq'" ///
       as txt "{col 45}IC:{col 62}" as res %10s "`ic'"
    di as txt "{col 5}rho_1 [OLS]:{col 25}" as res %9.6f `rho_ols'
    di
    di as txt "{hline 96}"
    di as txt "{col 3}{bf:tau}" ///
       "{col 11}{bf:rho_1(tau)}" ///
       "{col 24}{bf:t_n(tau)}" ///
       "{col 36}{bf:U_n(tau)}" ///
       "{col 48}{bf:delta-sq}" ///
       "{col 59}{bf:CV(1%)}" ///
       "{col 70}{bf:CV(5%)}" ///
       "{col 81}{bf:CV(10%)}" ///
       "{col 93}{bf:Sig}"
    di as txt "{hline 96}"

    forvalues i = 1/`nq' {
        local tau_i  = `=`tau_mat'[`i', 1]'
        local rho_i  = `=`rho_mat'[`i', 1]'
        local t_i    = `=`tstat_mat'[`i', 1]'
        local u_i    = `=`ustat_mat'[`i', 1]'
        local d2_i   = `=`d2_mat'[`i', 1]'
        local cv1_i  = `=`cv1_mat'[`i', 1]'
        local cv5_i  = `=`cv5_mat'[`i', 1]'
        local cv10_i = `=`cv10_mat'[`i', 1]'

        * Significance stars
        local stars ""
        if `t_i' < `cv1_i' {
            local stars "***"
        }
        else if `t_i' < `cv5_i' {
            local stars " **"
        }
        else if `t_i' < `cv10_i' {
            local stars "  *"
        }

        di as txt %6.2f `tau_i' ///
           as res %12.6f `rho_i' ///
           as res %11.4f `t_i' ///
           as res %11.4f `u_i' ///
           as res %10.4f `d2_i' ///
           as res %10.4f `cv1_i' ///
           as res %10.4f `cv5_i' ///
           as res %10.4f `cv10_i' ///
           as txt "  `stars'"
    }

    di as txt "{hline 96}"

    * Global statistics
    di
    di as txt "{hline 96}"
    di as txt "{col 5}{bf:Global Test Statistics (Equations 13-14)}"
    di as txt "{hline 96}"
    di
    di as txt "{col 5}{bf:Kolmogorov-Smirnov type:}"
    di as txt "{col 10}QKS_alpha = sup|U_n(tau)|{col 45}=" as res %12.4f `qks_alpha'
    di as txt "{col 10}QKS_t     = sup|t_n(tau)|{col 45}=" as res %12.4f `qks_t'
    di
    di as txt "{col 5}{bf:Cramer-von Mises type:}"
    di as txt "{col 10}QCM_alpha = int U_n(tau)^2 dtau{col 45}=" as res %12.4f `qcm_alpha'
    di as txt "{col 10}QCM_t     = int t_n(tau)^2 dtau{col 45}=" as res %12.4f `qcm_t'

    if "`bootstrap'" != "" {
        di
        di as txt "{hline 96}"
        di as txt "{col 5}{bf:Bootstrap Critical Values (`reps' replications)}"
        di as txt "{hline 96}"
        di
        di as txt "{col 25}" _col(40) "5%" _col(55) "10%"
        di as txt "{col 5}QKS_alpha" ///
           _col(37) as res %10.4f `boot_qks_a_5' ///
           _col(52) as res %10.4f `boot_qks_a_10'
        di as txt "{col 5}QKS_t" ///
           _col(37) as res %10.4f `boot_qks_t_5' ///
           _col(52) as res %10.4f `boot_qks_t_10'
        di as txt "{col 5}QCM_alpha" ///
           _col(37) as res %10.4f `boot_qcm_a_5' ///
           _col(52) as res %10.4f `boot_qcm_a_10'
        di as txt "{col 5}QCM_t" ///
           _col(37) as res %10.4f `boot_qcm_t_5' ///
           _col(52) as res %10.4f `boot_qcm_t_10'

        * Decision for QKS_t
        di
        if `qks_t' > `boot_qks_t_5' {
            di as res "{col 5}QKS_t rejects H0 at 5%: Evidence against unit root"
        }
        else if `qks_t' > `boot_qks_t_10' {
            di as txt "{col 5}QKS_t rejects H0 at 10%: Weak evidence against unit root"
        }
        else {
            di as txt "{col 5}QKS_t: Cannot reject H0 (unit root)"
        }
    }

    di
    di as txt "{hline 96}"
    di as txt "{col 5}Note: *** p<0.01, ** p<0.05, * p<0.10 (left-tail t_n test)"
    di as txt "{col 5}H0: Unit root (alpha_1=1) for all tau in T=[tau_0, 1-tau_0]"
    di as txt "{hline 96}"

    *--------------------------------------------------------------------------
    * Store results for qadf_graph
    *--------------------------------------------------------------------------
    * Matrices for graphing
    tempname results_mat
    mat `results_mat' = J(`nq', 9, .)
    forvalues i = 1/`nq' {
        mat `results_mat'[`i', 1] = `tau_mat'[`i', 1]
        mat `results_mat'[`i', 2] = `rho_mat'[`i', 1]
        mat `results_mat'[`i', 3] = `tstat_mat'[`i', 1]
        mat `results_mat'[`i', 4] = `ustat_mat'[`i', 1]
        mat `results_mat'[`i', 5] = `d2_mat'[`i', 1]
        mat `results_mat'[`i', 6] = `cv1_mat'[`i', 1]
        mat `results_mat'[`i', 7] = `cv5_mat'[`i', 1]
        mat `results_mat'[`i', 8] = `cv10_mat'[`i', 1]
        mat `results_mat'[`i', 9] = `hl_mat'[`i', 1]
    }
    mat colnames `results_mat' = tau rho tstat Ustat delta2 cv1 cv5 cv10 halflife
    matrix qadf_results = `results_mat'

    *--------------------------------------------------------------------------
    * Return results
    *--------------------------------------------------------------------------
    return scalar N        = `nobs'
    return scalar nq       = `nq'
    return scalar lags     = `opt_lags'
    return scalar rho_ols  = `rho_ols'

    return scalar QKS_alpha = `qks_alpha'
    return scalar QKS_t     = `qks_t'
    return scalar QCM_alpha = `qcm_alpha'
    return scalar QCM_t     = `qcm_t'

    if "`bootstrap'" != "" {
        return scalar boot_qks_a_5  = `boot_qks_a_5'
        return scalar boot_qks_t_5  = `boot_qks_t_5'
        return scalar boot_qcm_a_5  = `boot_qcm_a_5'
        return scalar boot_qcm_t_5  = `boot_qcm_t_5'
        return scalar boot_qks_a_10 = `boot_qks_a_10'
        return scalar boot_qks_t_10 = `boot_qks_t_10'
        return scalar boot_qcm_a_10 = `boot_qcm_a_10'
        return scalar boot_qcm_t_10 = `boot_qcm_t_10'
        return scalar boot_nvalid   = `boot_nv'
    }

    return matrix results = `results_mat'

    return local varname    "`varlist'"
    return local model      "`model'"
    return local ic         "`ic'"
    return local quantiles  "`quantiles'"
    return local cmd        "qadf_process"
end
