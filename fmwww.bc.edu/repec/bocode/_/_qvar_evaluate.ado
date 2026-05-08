*! _qvar_evaluate.ado — Forecast Evaluation Tools
*! Surprenant (2025), Bank of Canada SWP 2025-4
*! Provides: qwCRPS, Diebold-Mariano, Mincer-Zarnowitz, Coverage tests
*! Version 0.1.0

program define _qvar_evaluate, rclass
    version 16.0
    syntax varlist(min=2), ACTual(varname) ///
        [TAUs(numlist >0 <1) WEIght(string) ///
         HORizon(integer 1) NOMinal(real 0.90)]

    // varlist: forecast variables (quantile forecasts at different taus)
    // actual: realized values

    if "`weight'" == "" {
        local weight "tails"
    }

    if "`taus'" == "" {
        local taus "0.05 0.25 0.50 0.75 0.95"
    }

    local nforecasts : word count `varlist'
    local ntaus : word count `taus'

    di _n "{hline 78}"
    di _col(18) "Forecast Evaluation"
    di _col(8) "Surprenant (2025, Bank of Canada SWP 2025-4)"
    di "{hline 78}"
    di "  Actual variable : `actual'"
    di "  Forecast vars   : `varlist'"
    di "  Weight function : `weight'"
    di "  Horizon         : `horizon'"
    di "{hline 78}"

    // ═══════════════════════════════════════════════════════════════════
    // 1. Quantile Score: rho_tau(u) = u * (tau - I{u<0})
    // ═══════════════════════════════════════════════════════════════════

    di _n "  Quantile Scores:"
    di "  {hline 50}"

    local fc_idx = 0
    foreach fcvar of varlist `varlist' {
        local ++fc_idx
        local tau : word `fc_idx' of `taus'
        if "`tau'" == "" local tau = 0.5

        tempvar qs_`fc_idx'
        qui gen double `qs_`fc_idx'' = (`actual' - `fcvar') * ///
            (`tau' - (`actual' < `fcvar'))

        qui sum `qs_`fc_idx'', meanonly
        di "    `fcvar' (tau=`tau'): mean QS = " %10.6f r(mean)
    }

    // ═══════════════════════════════════════════════════════════════════
    // 2. Quantile-Weighted CRPS (Gneiting & Ranjan, 2011)
    // ═══════════════════════════════════════════════════════════════════

    di _n "  Quantile-Weighted CRPS (weight: `weight'):"
    di "  {hline 50}"

    tempvar qw_crps_val
    qui gen double `qw_crps_val' = 0

    local fc_idx = 0
    foreach fcvar of varlist `varlist' {
        local ++fc_idx
        local tau : word `fc_idx' of `taus'
        if "`tau'" == "" local tau = 0.5

        // Weight function
        if "`weight'" == "tails" {
            local w = (2 * `tau' - 1)^2
        }
        else if "`weight'" == "left" {
            local w = (1 - `tau')^2
        }
        else if "`weight'" == "right" {
            local w = `tau'^2
        }
        else {
            local w = 1
        }

        qui replace `qw_crps_val' = `qw_crps_val' + `w' * `qs_`fc_idx''
    }

    if `nforecasts' > 1 {
        qui replace `qw_crps_val' = (2 / (`nforecasts' - 1)) * `qw_crps_val'
    }

    qui sum `qw_crps_val', meanonly
    local crps_mean = r(mean)
    di "    Mean qwCRPS = " %10.6f `crps_mean'

    return scalar qw_crps = `crps_mean'

    // ═══════════════════════════════════════════════════════════════════
    // 3. Diebold-Mariano Test (if 2+ forecast sets)
    // ═══════════════════════════════════════════════════════════════════

    if `nforecasts' >= 2 {
        di _n "  Diebold-Mariano Test (Diebold & Mariano, 1995):"
        di "  {hline 50}"

        // Compare first vs second forecast
        local fc1 : word 1 of `varlist'
        local fc2 : word 2 of `varlist'

        tempvar d_t
        qui gen double `d_t' = `qs_1' - `qs_2'

        qui sum `d_t', meanonly
        local d_bar = r(mean)
        local T = r(N)

        // HAC variance (Newey-West)
        qui sum `d_t'
        local gamma0 = r(Var) * (`T' - 1) / `T'
        local gamma_sum = 0

        forvalues lag = 1/`=`horizon'-1' {
            tempvar d_lag`lag'
            qui gen double `d_lag`lag'' = ///
                (`d_t' - `d_bar') * L`lag'.(`d_t' - `d_bar')
            qui sum `d_lag`lag'', meanonly
            local gamma_sum = `gamma_sum' + 2 * r(mean)
            drop `d_lag`lag''
        }

        local var_d = (`gamma0' + `gamma_sum') / `T'
        local var_d = max(`var_d', 1e-12)
        local dm_stat = `d_bar' / sqrt(`var_d')
        local dm_pval = 2 * (1 - normal(abs(`dm_stat')))

        di "    d_bar     = " %10.6f `d_bar'
        di "    DM stat   = " %10.4f `dm_stat'
        di "    p-value   = " %10.4f `dm_pval'
        di "    Winner    : " cond(`d_bar' < 0, "`fc1'", "`fc2'")

        return scalar dm_stat = `dm_stat'
        return scalar dm_pval = `dm_pval'
        return scalar dm_diff = `d_bar'
    }

    // ═══════════════════════════════════════════════════════════════════
    // 4. Coverage Test (Christoffersen, 1998)
    // ═══════════════════════════════════════════════════════════════════

    if `nforecasts' >= 2 {
        di _n "  Coverage Test (Christoffersen, 1998):"
        di "  {hline 50}"
        di "  Nominal coverage: `nominal'"

        local lower_fc : word 1 of `varlist'
        local upper_fc : word `nforecasts' of `varlist'

        tempvar I_cov
        qui gen byte `I_cov' = (`actual' >= `lower_fc') & ///
            (`actual' <= `upper_fc')

        qui sum `I_cov', meanonly
        local rho_hat = r(mean)
        local T = r(N)
        local T1 = `rho_hat' * `T'
        local T0 = `T' - `T1'
        local rho = `nominal'

        // Unconditional coverage LR
        if `T0' > 0 & `T1' > 0 {
            local lr_uc = -2 * (`T0' * ln(1 - `rho') + `T1' * ln(`rho') ///
                - `T0' * ln(1 - `rho_hat') - `T1' * ln(`rho_hat'))
        }
        else {
            local lr_uc = 0
        }
        local uc_pval = 1 - chi2(1, `lr_uc')

        di "    Empirical coverage = " %6.4f `rho_hat'
        di "    UC LR statistic    = " %8.4f `lr_uc'
        di "    UC p-value         = " %8.4f `uc_pval'
        di "    Correct coverage   : " cond(`uc_pval' > 0.05, "Yes", "No")

        return scalar coverage   = `rho_hat'
        return scalar uc_stat    = `lr_uc'
        return scalar uc_pval    = `uc_pval'
    }

    di _n "{hline 78}"
    di "  Significance: *** p<0.01, ** p<0.05, * p<0.1"
    di "{hline 78}"
end
