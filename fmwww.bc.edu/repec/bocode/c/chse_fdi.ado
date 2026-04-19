*! chse_fdi — Compute Fiscal Dominance Index (FDI)
*! Version 1.0.0   April 2025
*! Author: Nityahapani
*!
*! FDI = V_T * lambda_R / (K_CB * rho_ratio)
*!
*! where:
*!   V_T         political capital / government pressure index
*!   K_CB        central bank independence score (Dincer-Eichengreen scale)
*!   lambda_R    reframing efficiency (default 1.0)
*!   rho_ratio   rho_kappa / rho_nu replenishment ratio (default 1.0)
*!
*! Regime classification:
*!   FDI < 0.5         monetary dominance
*!   0.5 <= FDI <= 1   contested
*!   FDI > 1           fiscal dominance
*!
*! Syntax:
*!   chse_fdi, vt(varname|#) kcb(varname|#)
*!             [lambda(#) rhoratio(#) generate(stub) replace]

program define chse_fdi, rclass
    version 14.0
    
    syntax , VT(string) KCB(string) ///
             [LAMbda(real 1.0) RHOratio(real 1.0) ///
              GENerate(name) replace]
    
    // ----------------------------------------------------------------
    // Validate rho_ratio > 0
    // ----------------------------------------------------------------
    if `rhoratio' <= 0 {
        di as error "rhoratio() must be positive"
        exit 198
    }
    if `lambda' <= 0 {
        di as error "lambda() must be positive"
        exit 198
    }
    
    // ----------------------------------------------------------------
    // Parse vt() and kcb()
    // ----------------------------------------------------------------
    capture confirm number `vt'
    local vt_is_scalar = (_rc == 0)
    if `vt_is_scalar' local vt_val = `vt'
    else confirm variable `vt'
    
    capture confirm number `kcb'
    local kcb_is_scalar = (_rc == 0)
    if `kcb_is_scalar' local kcb_val = `kcb'
    else confirm variable `kcb'
    
    // ----------------------------------------------------------------
    // Output variable stub
    // ----------------------------------------------------------------
    local stub = cond("`generate'" != "", "`generate'", "chse")
    local fdivar  "`stub'_fdi"
    local regvar  "`stub'_fdi_regime"
    local hsivar  "`stub'_hsi"
    
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
    
    // ----------------------------------------------------------------
    // Compute FDI
    // ----------------------------------------------------------------
    quietly {
        tempvar vt_tmp kcb_tmp
        
        if `vt_is_scalar'  gen double `vt_tmp'  = `vt_val'
        else               gen double `vt_tmp'  = `vt'
        
        if `kcb_is_scalar' gen double `kcb_tmp' = `kcb_val'
        else               gen double `kcb_tmp' = `kcb'
        
        // FDI = V_T * lambda_R / (K_CB * rho_ratio)
        gen double `fdivar' = (`vt_tmp' * `lambda') / ///
            (`kcb_tmp' * `rhoratio') ///
            if !missing(`vt_tmp') & !missing(`kcb_tmp') & `kcb_tmp' > 0
        label variable `fdivar' "Fiscal Dominance Index (CHSE)"
        
        // Implied HSI = 1 / FDI
        gen double `hsivar' = 1 / `fdivar' if `fdivar' > 0 & !missing(`fdivar')
        label variable `hsivar' "Implied Hierarchy Stability Index (1/FDI)"
        
        // Regime
        gen str12 `regvar' = ""
        replace `regvar' = "monetary"  if `fdivar' <  0.5
        replace `regvar' = "contested" if `fdivar' >= 0.5 & `fdivar' <= 1
        replace `regvar' = "fiscal"    if `fdivar' >  1
        replace `regvar' = "."         if missing(`fdivar')
        label variable `regvar' "FDI regime (monetary/contested/fiscal)"
    }
    
    // ----------------------------------------------------------------
    // Return scalars for single-obs calls
    // ----------------------------------------------------------------
    if `vt_is_scalar' & `kcb_is_scalar' {
        local fdi_val = (`vt_val' * `lambda') / (`kcb_val' * `rhoratio')
        local hsi_val = 1 / `fdi_val'
        
        if `fdi_val' <  0.5 local regime "monetary"
        else if `fdi_val' <= 1 local regime "contested"
        else local regime "fiscal"
        
        return scalar FDI      = `fdi_val'
        return scalar HSI      = `hsi_val'
        return scalar lambda_R = `lambda'
        return scalar rho_ratio = `rhoratio'
        return local  regime    "`regime'"
        
        di as text _newline "Fiscal Dominance Index"
        di as text "  V_T        = " as result `vt_val'
        di as text "  K_CB       = " as result `kcb_val'
        di as text "  lambda_R   = " as result `lambda'
        di as text "  rho_ratio  = " as result `rhoratio'
        di as text "  FDI        = " as result %8.4f `fdi_val'
        di as text "  Implied HSI= " as result %8.4f `hsi_val'
        di as text "  Regime     : " as result "`regime'"
    }
    
    di as text _newline ///
        "Generated: " as result "`fdivar'" as text "  " ///
        as result "`regvar'" as text "  " as result "`hsivar'"
    
end
