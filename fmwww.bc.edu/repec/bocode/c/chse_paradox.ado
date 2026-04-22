*! chse_paradox v1.0.2  18apr2025  Nityahapani
*! Test the Hierarchy Persistence Paradox
*!
*! Options (no underscores -- Stata syntax requirement):
*!   fdi           treat hsi_var as FDI; convert via HSI = 1/FDI
*!   alphar(#)     direct belief drop per reframe (default 0.3)
*!   trust(#)      average cross-edge trust (default 0.65)
*!   phi(#)        average distance decay (default 0.60)
*!   accfloor(#)   Acc_ij at HSI->0 (default 0.50)
*!   accceiling(#) Acc_ij at HSI->inf (default 0.92)
*!   generate(stub) generate predicted variables
*!   replace       replace existing variables

program define chse_paradox, rclass
    version 14.0
    syntax varlist(min=2 max=2 numeric) [if] [in] , ///
        [FDI ALPHAr(real 0.3) TRUST(real 0.65) PHI(real 0.60) ///
         ACCfloor(real 0.50) ACCceiling(real 0.92) ///
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

    tempvar hsi_use acc_var rhoK_var cascade_var

    quietly {
        if "`fdi'" != "" {
            gen double `hsi_use' = 1/`hsi_var' if `touse' & `hsi_var' > 0
        }
        else {
            gen double `hsi_use' = `hsi_var' if `touse'
        }

        gen double `acc_var' = `accfloor' + ///
            (`accceiling' - `accfloor') * `hsi_use'/(1+`hsi_use') if `touse'

        gen double `rhoK_var' = `acc_var' * `trust' * `phi' if `touse'

        gen double `cascade_var' = cond(`rhoK_var' < 1, ///
            `alphar'/(1-`rhoK_var'), .) if `touse'
    }

    quietly regress `disrupt_var' `hsi_use' if `touse'
    local slope  = _b[`hsi_use']
    local se     = _se[`hsi_use']
    local pval   = 2*ttail(e(df_r), abs(`slope'/`se'))
    local r2     = e(r2)
    local N_reg  = e(N)
    local paradox_confirmed = (`slope' > 0 & `pval' < 0.10)

    quietly correlate `disrupt_var' `hsi_use' if `touse'
    local corr = r(rho)

    quietly summarize `acc_var'     if `touse'
    local acc_min = r(min);  local acc_max = r(max)
    quietly summarize `rhoK_var'    if `touse'
    local rhoK_min = r(min); local rhoK_max = r(max)
    quietly summarize `cascade_var' if `touse'
    local casc_min = r(min); local casc_max = r(max)

    di as text _newline "CHSE Hierarchy Persistence Paradox Test"
    di as text "{hline 58}"
    di as text "  Regression: `disrupt_var' = a + b*HSI   (N=`N_reg')"
    di as text "  slope  = " as result %8.4f `slope' ///
        as text "   se = " as result %8.4f `se' ///
        as text "   p = " as result %8.4f `pval'
    di as text "  R2     = " as result %8.4f `r2' ///
        as text "   corr = " as result %8.4f `corr'
    di as text "{hline 58}"
    di as text "  Acc_ij range    : [" as result %5.3f `acc_min' ///
        as text ", " as result %5.3f `acc_max' as text "]"
    di as text "  rho(K) range    : [" as result %5.3f `rhoK_min' ///
        as text ", " as result %5.3f `rhoK_max' as text "]"
    di as text "  E[cascade] range: [" as result %5.3f `casc_min' ///
        as text ", " as result %5.3f `casc_max' as text "]"
    di as text "{hline 58}"
    if `paradox_confirmed' {
        di as result "  PARADOX CONFIRMED (slope > 0, p < 0.10)"
    }
    else {
        di as text "  slope > 0 but p = " as result %6.4f `pval' ///
            as text " (weak evidence)"
    }

    if "`generate'" != "" {
        if "`replace'" != "" {
            capture drop `generate'_hsi `generate'_acc ///
                         `generate'_rhoK `generate'_cascade
        }
        quietly {
            gen double `generate'_hsi     = `hsi_use'
            gen double `generate'_acc     = `acc_var'
            gen double `generate'_rhoK    = `rhoK_var'
            gen double `generate'_cascade = `cascade_var'
        }
        di as text _newline "Generated: " as result ///
            "`generate'_hsi  `generate'_acc  `generate'_rhoK  `generate'_cascade"
    }

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
