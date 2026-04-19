*! chse_paradox — Test the Hierarchy Persistence Paradox
*! Version 1.0.0   April 2025
*! Author: Nityahapani
*!
*! Tests whether post-collapse disruption is increasing in pre-collapse HSI:
*!   dE[cascade|collapse] / dHSI > 0
*!
*! Given a dataset with one row per country/episode, containing:
*!   - pre-collapse HSI (or FDI, which implies HSI = 1/FDI)
*!   - post-collapse disruption measure (yield volatility, default spreads, etc.)
*!
*! Runs OLS regression of disruption on HSI, tests that slope > 0,
*! and computes the theoretical cascade size under calibrated parameters.
*!
*! Syntax:
*!   chse_paradox disruption_var hsi_var [if] [in]
*!                [, fdi alpha_r(#) trust(#) phi(#) acc_floor(#)
*!                   acc_ceiling(#) generate(stub) replace]
*!
*! Options:
*!   fdi            treat hsi_var as FDI; convert via HSI = 1/FDI
*!   alpha_r(#)     direct belief drop per reframe (default 0.3)
*!   trust(#)       average cross-edge trust (default 0.65)
*!   phi(#)         average distance decay (default 0.60)
*!   acc_floor(#)   Acc_ij at HSI -> 0 (default 0.50)
*!   acc_ceiling(#) Acc_ij at HSI -> inf (default 0.92)

program define chse_paradox, rclass
    version 14.0
    
    syntax varlist(min=2 max=2 numeric) [if] [in] , ///
        [FDI ALpha_r(real 0.3) TRUST(real 0.65) PHI(real 0.60) ///
         ACC_FLOOR(real 0.50) ACC_CEILing(real 0.92) ///
         GENerate(name) replace]
    
    tokenize `varlist'
    local disrupt_var `1'
    local hsi_var     `2'
    
    marksample touse
    quietly count if `touse'
    if r(N) < 3 {
        di as error "Need at least 3 observations."
        exit 2001
    }
    
    // ----------------------------------------------------------------
    // Convert FDI to HSI if needed
    // ----------------------------------------------------------------
    local stub = cond("`generate'" != "", "`generate'", "chse")
    tempvar hsi_use acc_var rhoK_var cascade_var
    
    quietly {
        if "`fdi'" != "" {
            gen double `hsi_use' = 1 / `hsi_var' if `touse' & `hsi_var' > 0
        }
        else {
            gen double `hsi_use' = `hsi_var' if `touse'
        }
        
        // Acc_ij(HSI) = acc_floor + (acc_ceiling - acc_floor) * HSI/(1+HSI)
        gen double `acc_var' = `acc_floor' + ///
            (`acc_ceiling' - `acc_floor') * `hsi_use' / (1 + `hsi_use') ///
            if `touse'
        
        // rho_K = Acc * trust * phi
        gen double `rhoK_var' = `acc_var' * `trust' * `phi' if `touse'
        
        // E[cascade size] = alpha_R / (1 - rho_K) if rho_K < 1
        gen double `cascade_var' = cond(`rhoK_var' < 1, ///
            `alpha_r' / (1 - `rhoK_var'), .) if `touse'
    }
    
    // ----------------------------------------------------------------
    // OLS: disruption ~ HSI
    // ----------------------------------------------------------------
    quietly regress `disrupt_var' `hsi_use' if `touse'
    local slope   = _b[`hsi_use']
    local se      = _se[`hsi_use']
    local pval    = 2 * ttail(e(df_r), abs(`slope' / `se'))
    local r2      = e(r2)
    local N_reg   = e(N)
    local paradox_confirmed = (`slope' > 0 & `pval' < 0.10)
    
    // Pearson correlation
    quietly correlate `disrupt_var' `hsi_use' if `touse'
    local corr = r(rho)
    
    // ----------------------------------------------------------------
    // Summary of cascade predictions
    // ----------------------------------------------------------------
    quietly summarize `acc_var' if `touse'
    local acc_min = r(min); local acc_max = r(max)
    quietly summarize `rhoK_var' if `touse'
    local rhoK_min = r(min); local rhoK_max = r(max)
    quietly summarize `cascade_var' if `touse'
    local casc_min = r(min); local casc_max = r(max)
    
    // ----------------------------------------------------------------
    // Display
    // ----------------------------------------------------------------
    di as text _newline "CHSE Hierarchy Persistence Paradox Test"
    di as text "{hline 58}"
    di as text "  H0: slope = 0 (no paradox)"
    di as text "  H1: slope > 0 (stronger hierarchies -> larger cascades)"
    di as text "{hline 58}"
    di as text "  Regression: `disrupt_var' = a + b * HSI"
    di as text "    N          = " as result `N_reg'
    di as text "    slope (b)  = " as result %8.4f `slope'
    di as text "    std err    = " as result %8.4f `se'
    di as text "    p-value    = " as result %8.4f `pval' ///
        as text "  (one-sided: " as result %8.4f `pval'/2 as text ")"
    di as text "    R-squared  = " as result %8.4f `r2'
    di as text "    Corr(HSI, disruption) = " as result %8.4f `corr'
    di as text "{hline 58}"
    di as text "  Theoretical cascade predictions (calibrated):"
    di as text "    Acc_ij range  : [" as result %5.3f `acc_min' ///
        as text ", " as result %5.3f `acc_max' as text "]"
    di as text "    rho(K) range  : [" as result %5.3f `rhoK_min' ///
        as text ", " as result %5.3f `rhoK_max' as text "]"
    di as text "    E[cascade|collapse] range: [" ///
        as result %5.3f `casc_min' as text ", " ///
        as result %5.3f `casc_max' as text "]"
    di as text "{hline 58}"
    
    if `paradox_confirmed' {
        di as result "  PARADOX CONFIRMED: slope > 0, p < 0.10"
    }
    else if `slope' > 0 {
        di as text "  Positive slope (p = " as result %6.4f `pval' ///
            as text "), weak evidence for paradox"
    }
    else {
        di as text "  Slope <= 0 — paradox not confirmed in this sample"
    }
    
    // ----------------------------------------------------------------
    // Save generated variables if requested
    // ----------------------------------------------------------------
    if "`generate'" != "" {
        if "`replace'" != "" {
            capture drop `stub'_acc `stub'_rhoK `stub'_cascade_pred `stub'_hsi_implied
        }
        quietly {
            gen double `stub'_hsi_implied   = `hsi_use'
            gen double `stub'_acc           = `acc_var'
            gen double `stub'_rhoK          = `rhoK_var'
            gen double `stub'_cascade_pred  = `cascade_var'
            label variable `stub'_hsi_implied   "Implied HSI"
            label variable `stub'_acc           "Acc_ij(HSI)"
            label variable `stub'_rhoK          "rho(K) implied"
            label variable `stub'_cascade_pred  "E[cascade|collapse] predicted"
        }
        di as text _newline "Generated: " as result ///
            "`stub'_hsi_implied  `stub'_acc  `stub'_rhoK  `stub'_cascade_pred"
    }
    
    // ----------------------------------------------------------------
    // Return
    // ----------------------------------------------------------------
    return scalar slope             = `slope'
    return scalar se_slope          = `se'
    return scalar pval_slope        = `pval'
    return scalar r2                = `r2'
    return scalar correlation       = `corr'
    return scalar paradox_confirmed = `paradox_confirmed'
    return scalar acc_min           = `acc_min'
    return scalar acc_max           = `acc_max'
    return scalar rhoK_min          = `rhoK_min'
    return scalar rhoK_max          = `rhoK_max'
    return scalar N_obs             = `N_reg'
    
end
