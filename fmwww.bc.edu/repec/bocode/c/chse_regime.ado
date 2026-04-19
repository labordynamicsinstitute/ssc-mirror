*! chse_regime — Classify CHSE regime from HSI and PI
*! Version 1.0.0   April 2025
*! Author: Nityahapani
*!
*! Computes the Instability Index Z = HSI^-1 * (1 + 2*PI) and
*! classifies each observation into one of four regimes:
*!   stable       Z < 1
*!   oscillatory  1 <= Z < 2
*!   cascade      2 <= Z < 3.5
*!   turbulent    Z >= 3.5
*!
*! Syntax:
*!   chse_regime, hsi(varname|#) pi(varname|#) [generate(stub) replace]

program define chse_regime, rclass
    version 14.0
    
    syntax , HSI(string) PI(string) [GENerate(name) replace]
    
    // ----------------------------------------------------------------
    // Parse hsi() — may be a varname or a scalar
    // ----------------------------------------------------------------
    capture confirm number `hsi'
    if _rc == 0 {
        // scalar supplied
        local hsi_scalar = `hsi'
        local hsi_is_scalar 1
    }
    else {
        confirm variable `hsi'
        local hsi_var `hsi'
        local hsi_is_scalar 0
    }
    
    // Parse pi() — may be a varname or a scalar
    capture confirm number `pi'
    if _rc == 0 {
        local pi_scalar = `pi'
        local pi_is_scalar 1
    }
    else {
        confirm variable `pi'
        local pi_var `pi'
        local pi_is_scalar 0
    }
    
    // ----------------------------------------------------------------
    // Output variable names
    // ----------------------------------------------------------------
    if "`generate'" == "" {
        local stub "chse"
    }
    else {
        local stub "`generate'"
    }
    
    local zvar   "`stub'_Z"
    local rvar   "`stub'_regime"
    local numvar "`stub'_regime_n"
    
    if "`replace'" == "" {
        foreach v of local zvar rvar numvar {
            capture confirm new variable ``v''
            if _rc {
                di as error "Variable ``v'' already exists. Use replace option."
                exit 110
            }
        }
    }
    else {
        foreach v in `zvar' `rvar' `numvar' {
            capture drop `v'
        }
    }
    
    // ----------------------------------------------------------------
    // Compute Z and classify
    // ----------------------------------------------------------------
    quietly {
        // Build temporary HSI and PI variables
        tempvar hsi_tmp pi_tmp
        
        if `hsi_is_scalar' {
            gen double `hsi_tmp' = `hsi_scalar'
        }
        else {
            gen double `hsi_tmp' = `hsi_var'
        }
        
        if `pi_is_scalar' {
            gen double `pi_tmp' = `pi_scalar'
        }
        else {
            gen double `pi_tmp' = `pi_var'
        }
        
        // Instability index Z
        gen double `zvar' = (1 / `hsi_tmp') * (1 + 2 * `pi_tmp') ///
            if !missing(`hsi_tmp') & !missing(`pi_tmp') & `hsi_tmp' > 0
        label variable `zvar' "CHSE Instability Index Z = HSI^-1*(1+2*PI)"
        
        // Regime numeric code
        gen byte `numvar' = .
        replace `numvar' = 1 if `zvar' <  1
        replace `numvar' = 2 if `zvar' >= 1  & `zvar' < 2
        replace `numvar' = 3 if `zvar' >= 2  & `zvar' < 3.5
        replace `numvar' = 4 if `zvar' >= 3.5
        label define _chse_regime_lbl ///
            1 "Stable" 2 "Oscillatory" 3 "Cascade" 4 "Turbulent"
        label values `numvar' _chse_regime_lbl
        label variable `numvar' "CHSE regime (numeric)"
        
        // Regime string
        gen str12 `rvar' = ""
        replace `rvar' = "stable"      if `numvar' == 1
        replace `rvar' = "oscillatory" if `numvar' == 2
        replace `rvar' = "cascade"     if `numvar' == 3
        replace `rvar' = "turbulent"   if `numvar' == 4
        label variable `rvar' "CHSE regime"
    }
    
    // ----------------------------------------------------------------
    // Return scalars for single-observation use
    // ----------------------------------------------------------------
    if `hsi_is_scalar' & `pi_is_scalar' {
        local z_val = (1 / `hsi_scalar') * (1 + 2 * `pi_scalar')
        return scalar Z       = `z_val'
        return scalar HSI     = `hsi_scalar'
        return scalar PI      = `pi_scalar'
        
        if `z_val' <  1   return local regime "stable"
        if `z_val' >= 1   & `z_val' < 2   return local regime "oscillatory"
        if `z_val' >= 2   & `z_val' < 3.5 return local regime "cascade"
        if `z_val' >= 3.5 return local regime "turbulent"
        
        di as text _newline "HSI = " as result `hsi_scalar' ///
            as text "   PI = " as result `pi_scalar' ///
            as text "   Z = " as result %6.4f `z_val' ///
            as text "   Regime: " as result "`r(regime)'"
    }
    
    di as text _newline ///
        "Generated: " as result "`zvar'" as text " (Instability Index)"
    di as text ///
        "          " as result "`rvar'" as text " (regime string)"
    di as text ///
        "          " as result "`numvar'" as text " (regime numeric, labelled)"
    
end
