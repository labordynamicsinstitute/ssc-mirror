*! chse_regime v1.0.1  18apr2025  Nityahapani
*! Classify CHSE regime from HSI and PI
*! Z = HSI^-1*(1+2*PI)  ->  stable / oscillatory / cascade / turbulent

program define chse_regime, rclass
    version 14.0
    syntax , HSI(string) PI(string) [GENerate(name) replace]

    // --- parse hsi ---
    capture confirm number `hsi'
    local hsi_is_scalar = (_rc == 0)
    if `hsi_is_scalar' {
        local hsi_val = `hsi'
    }
    else {
        confirm variable `hsi'
    }

    // --- parse pi ---
    capture confirm number `pi'
    local pi_is_scalar = (_rc == 0)
    if `pi_is_scalar' {
        local pi_val = `pi'
    }
    else {
        confirm variable `pi'
    }

    // ----------------------------------------------------------------
    // SCALAR PATH: pure arithmetic, no dataset access
    // ----------------------------------------------------------------
    if `hsi_is_scalar' & `pi_is_scalar' {
        local z_val = (1 / `hsi_val') * (1 + 2 * `pi_val')

        if      `z_val' <  1   local regime "stable"
        else if `z_val' <  2   local regime "oscillatory"
        else if `z_val' <  3.5 local regime "cascade"
        else                   local regime "turbulent"

        return scalar Z   = `z_val'
        return scalar HSI = `hsi_val'
        return scalar PI  = `pi_val'
        return local regime "`regime'"

        di as text _newline ///
            "HSI = " as result `hsi_val' ///
            as text "   PI = " as result `pi_val' ///
            as text "   Z = " as result %6.4f `z_val' ///
            as text "   Regime: " as result "`regime'"
        exit 0
    }

    // ----------------------------------------------------------------
    // VARIABLE PATH
    // ----------------------------------------------------------------
    local stub = cond("`generate'" != "", "`generate'", "chse")
    local zvar   "`stub'_Z"
    local rvar   "`stub'_regime"
    local numvar "`stub'_regime_n"

    if "`replace'" == "" {
        foreach v in `zvar' `rvar' `numvar' {
            capture confirm new variable `v'
            if _rc {
                di as error "Variable `v' already exists. Use replace."
                exit 110
            }
        }
    }
    else {
        foreach v in `zvar' `rvar' `numvar' {
            capture drop `v'
        }
    }

    quietly {
        tempvar hsi_tmp pi_tmp

        if `hsi_is_scalar' gen double `hsi_tmp' = `hsi_val'
        else                gen double `hsi_tmp' = `hsi'

        if `pi_is_scalar'  gen double `pi_tmp' = `pi_val'
        else                gen double `pi_tmp' = `pi'

        gen double `zvar' = (1/`hsi_tmp') * (1 + 2*`pi_tmp') ///
            if !missing(`hsi_tmp') & !missing(`pi_tmp') & `hsi_tmp' > 0
        label variable `zvar' "CHSE Instability Index Z = HSI^-1*(1+2*PI)"

        gen byte `numvar' = .
        replace `numvar' = 1 if `zvar' <  1
        replace `numvar' = 2 if `zvar' >= 1   & `zvar' < 2
        replace `numvar' = 3 if `zvar' >= 2   & `zvar' < 3.5
        replace `numvar' = 4 if `zvar' >= 3.5
        label define _chse_regime_lbl 1 "Stable" 2 "Oscillatory" ///
            3 "Cascade" 4 "Turbulent", replace
        label values `numvar' _chse_regime_lbl
        label variable `numvar' "CHSE regime (numeric)"

        gen str12 `rvar' = ""
        replace `rvar' = "stable"      if `numvar' == 1
        replace `rvar' = "oscillatory" if `numvar' == 2
        replace `rvar' = "cascade"     if `numvar' == 3
        replace `rvar' = "turbulent"   if `numvar' == 4
        label variable `rvar' "CHSE regime"
    }

    di as text _newline ///
        "Generated: " as result "`zvar'" ///
        as text "  " as result "`rvar'" ///
        as text "  " as result "`numvar'"
end
