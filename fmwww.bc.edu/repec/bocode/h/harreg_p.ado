program define harreg_p, properties(default_xb)
    version 15.0
    if "`e(cmd)'" != "harreg" {
        di as err "harreg_p may only be used after harreg"
        exit 301
    }
    syntax newvarname [if] [in] [, XB Residuals ]
    if "`xb'" != "" & "`residuals'" != "" {
        di as err "only one of xb and residuals may be specified"
        exit 198
    }
    local outvar `varlist'

    tempvar touse
    marksample touse, novarlist

    if "`residuals'" != "" {
        tempvar __har_xb
        quietly _predict double `__har_xb' if `touse', xb
        quietly generate double `outvar' = `e(depvar)' - `__har_xb' if `touse'
        label var `outvar' "Residuals"
        exit
    }

    if "`xb'" == "" {
        di as txt "(option xb assumed; fitted values)"
    }
    _predict double `outvar' if `touse', xb
    label var `outvar' "Linear prediction"
end
