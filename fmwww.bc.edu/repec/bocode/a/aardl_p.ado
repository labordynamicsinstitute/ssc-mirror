*! aardl_p - predict after aardl
*! Version 2.0.0 - 2026-08-28
*! Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)
*!
*! e(b) after aardl holds the EC representation (adjustment coefficient,
*! LONG-RUN coefficients, short-run coefficients), so a plain linear
*! combination of e(b) with the data is meaningless.  All predictions are
*! therefore built from e(b_ecm), the coefficient vector of the underlying
*! conditional ECM regression, whose column names carry the time-series
*! operators of the fitted model.
*!
*! Statistics
*!   xb         fitted values of D.depvar          (the default)
*!   residuals  D.depvar minus xb
*!   ect        the error-correction term
*!              depvar - sum_i beta_i * x_i  (- restricted intercept in Case 2)
*!   level      fitted level of depvar, L.depvar + xb

capture program drop aardl_p
program define aardl_p
    version 17

    syntax newvarname [if] [in], [ XB RESiduals ECT LEVel SCores ]

    if "`e(cmd)'" != "aardl" {
        di as err "aardl_p works only after {bf:aardl}"
        exit 301
    }
    if "`scores'" != "" {
        di as err "score predictions are not available after aardl"
        exit 198
    }

    local nopt : word count `xb' `residuals' `ect' `level'
    if `nopt' > 1 {
        di as err "only one statistic may be requested"
        exit 198
    }
    if `nopt' == 0 {
        local xb "xb"
        di as txt "(option {bf:xb} assumed; fitted D.`e(depvar)')"
    }

    marksample touse, novarlist
    local vtyp "`typlist'"
    if "`vtyp'" == "" local vtyp double

    tempname becm
    mat `becm' = e(b_ecm)

    // ---------------------------------------------------------------- xb
    if "`xb'" != "" | "`residuals'" != "" | "`level'" != "" {
        tempvar xbv
        qui matrix score double `xbv' = `becm' if `touse'

        if "`xb'" != "" {
            gen `vtyp' `varlist' = `xbv' if `touse'
            label var `varlist' "Fitted D.`e(depvar)'"
            exit
        }
        if "`residuals'" != "" {
            gen `vtyp' `varlist' = D.`e(depvar)' - `xbv' if `touse'
            label var `varlist' "Residuals, aardl"
            exit
        }
        if "`level'" != "" {
            gen `vtyp' `varlist' = L.`e(depvar)' + `xbv' if `touse'
            label var `varlist' "Fitted level of `e(depvar)'"
            exit
        }
    }

    // --------------------------------------------------------------- ect
    if "`ect'" != "" {
        tempname bb
        mat `bb' = e(b)
        local cnames : colnames `bb'
        local ceq    : coleq    `bb'
        local nc = colsof(`bb')

        tempvar e0
        qui gen double `e0' = `e(depvar)' if `touse'
        forvalues j = 1/`nc' {
            local eqj : word `j' of `ceq'
            if "`eqj'" != "LR" continue
            local vj : word `j' of `cnames'
            local cj = `bb'[1,`j']
            if "`vj'" == "_cons" {
                qui replace `e0' = `e0' - `cj' if `touse'
            }
            else {
                capture qui replace `e0' = `e0' - `cj'*`vj' if `touse'
            }
        }
        gen `vtyp' `varlist' = `e0' if `touse'
        label var `varlist' "Error-correction term, aardl"
        exit
    }
end
