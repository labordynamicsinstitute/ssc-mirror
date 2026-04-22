*! chse_fdi v1.0.1  18apr2025  Nityahapani
*! Fiscal Dominance Index: FDI = V_T*lambda_R / (K_CB*rho_ratio)

program define chse_fdi, rclass
    version 14.0
    syntax , VT(string) KCB(string) ///
             [LAMbda(real 1.0) RHOratio(real 1.0) GENerate(name) replace]

    if `rhoratio' <= 0 {
        di as error "rhoratio() must be positive"
        exit 198
    }
    if `lambda' <= 0 {
        di as error "lambda() must be positive"
        exit 198
    }

    // --- parse vt ---
    capture confirm number `vt'
    local vt_is_scalar = (_rc == 0)
    if `vt_is_scalar' local vt_val = `vt'
    else confirm variable `vt'

    // --- parse kcb ---
    capture confirm number `kcb'
    local kcb_is_scalar = (_rc == 0)
    if `kcb_is_scalar' local kcb_val = `kcb'
    else confirm variable `kcb'

    // ----------------------------------------------------------------
    // SCALAR PATH: pure arithmetic, no dataset access
    // ----------------------------------------------------------------
    if `vt_is_scalar' & `kcb_is_scalar' {
        local fdi_val = (`vt_val' * `lambda') / (`kcb_val' * `rhoratio')
        local hsi_val = 1 / `fdi_val'

        if      `fdi_val' <  0.5 local regime "monetary"
        else if `fdi_val' <= 1   local regime "contested"
        else                     local regime "fiscal"

        return scalar FDI       = `fdi_val'
        return scalar HSI       = `hsi_val'
        return scalar lambda_R  = `lambda'
        return scalar rho_ratio = `rhoratio'
        return local  regime      "`regime'"

        di as text _newline "Fiscal Dominance Index"
        di as text "  V_T         = " as result `vt_val'
        di as text "  K_CB        = " as result `kcb_val'
        di as text "  lambda_R    = " as result `lambda'
        di as text "  rho_ratio   = " as result `rhoratio'
        di as text "  FDI         = " as result %8.4f `fdi_val'
        di as text "  Implied HSI = " as result %8.4f `hsi_val'
        di as text "  Regime      : " as result "`regime'"
        exit 0
    }

    // ----------------------------------------------------------------
    // VARIABLE PATH
    // ----------------------------------------------------------------
    local stub = cond("`generate'" != "", "`generate'", "chse")
    local fdivar "`stub'_fdi"
    local regvar "`stub'_fdi_regime"
    local hsivar "`stub'_hsi"

    if "`replace'" == "" {
        foreach v in `fdivar' `regvar' `hsivar' {
            capture confirm new variable `v'
            if _rc {
                di as error "Variable `v' already exists. Use replace."
                exit 110
            }
        }
    }
    else {
        foreach v in `fdivar' `regvar' `hsivar' {
            capture drop `v'
        }
    }

    quietly {
        tempvar vt_tmp kcb_tmp

        if `vt_is_scalar'  gen double `vt_tmp'  = `vt_val'
        else                gen double `vt_tmp'  = `vt'

        if `kcb_is_scalar' gen double `kcb_tmp' = `kcb_val'
        else                gen double `kcb_tmp' = `kcb'

        gen double `fdivar' = (`vt_tmp' * `lambda') / (`kcb_tmp' * `rhoratio') ///
            if !missing(`vt_tmp') & !missing(`kcb_tmp') & `kcb_tmp' > 0
        label variable `fdivar' "Fiscal Dominance Index (CHSE)"

        gen double `hsivar' = 1/`fdivar' if `fdivar' > 0 & !missing(`fdivar')
        label variable `hsivar' "Implied HSI (1/FDI)"

        gen str12 `regvar' = ""
        replace `regvar' = "monetary"  if `fdivar' <  0.5
        replace `regvar' = "contested" if `fdivar' >= 0.5 & `fdivar' <= 1
        replace `regvar' = "fiscal"    if `fdivar' >  1
        label variable `regvar' "FDI regime"
    }

    di as text _newline ///
        "Generated: " as result "`fdivar'" ///
        as text "  " as result "`regvar'" ///
        as text "  " as result "`hsivar'"
end
