*! twostep_nardl_p version 3.0.0  09mar2026
*! Predict after twostep_nardl

program define twostep_nardl_p
    version 14

    if "`e(cmd)'" != "twostep_nardl" error 301

    syntax newvarname [if] [in] , [ XB RESiduals ECTerm ]

    local nopt = ("`xb'" != "") + ("`residuals'" != "") + ("`ecterm'" != "")
    if `nopt' > 1 {
        di as error "Only one of xb, residuals, or ecterm may be specified."
        exit 198
    }
    if `nopt' == 0 local xb "xb"

    marksample touse, novarlist
    qui replace `touse' = 0 if !e(sample)

    if "`xb'" != "" | "`residuals'" != "" {
        // Build fitted values manually from Step 2 coefficients
        // Step 2: D.y = rho*L.ect + phi*LD.y + pi+*D.xpos + pi-*D.xneg + ... + _cons

        local ectvar "`e(ect_var)'"
        if "`ectvar'" == "" local ectvar "_ect_nardl"
        capture confirm variable `ectvar'
        if _rc {
            di as error "Estimation variables not found. Re-run twostep_nardl first."
            exit 111
        }

        tempname bsr
        matrix `bsr' = e(b_sr)
        local ncols = colsof(`bsr')

        tempvar yhat_sr
        qui gen double `yhat_sr' = 0 if `touse'

        local col = 0

        // 1. ECT: rho * L.ect
        local ++col
        qui replace `yhat_sr' = `yhat_sr' + `bsr'[1,`col'] * L.`ectvar' if `touse'

        // 2. Lagged D.y terms
        local p_lag = e(p_lag)
        local depvar "`e(depvar)'"
        forvalues j = 1/`p_lag' {
            local ++col
            qui replace `yhat_sr' = `yhat_sr' + `bsr'[1,`col'] * L`j'D.`depvar' if `touse'
        }

        // 3. Short-run dx+ and dx- using stored permanent variables
        local pos_vars "`e(pos_vars)'"
        local neg_vars "`e(neg_vars)'"
        local asymvars "`e(asymvars)'"
        local k = e(k)
        local q_lag = e(q_lag)
        local q_use = max(`q_lag', 1)

        // Process each asymmetric variable
        forvalues vi = 1/`k' {
            local pv : word `vi' of `pos_vars'
            local nv : word `vi' of `neg_vars'

            // Positive shock coefficients
            forvalues j = 0/`=`q_use'-1' {
                local ++col
                if `j' == 0 {
                    qui replace `yhat_sr' = `yhat_sr' + `bsr'[1,`col'] * D.`pv' if `touse'
                }
                else {
                    qui replace `yhat_sr' = `yhat_sr' + `bsr'[1,`col'] * L`j'D.`pv' if `touse'
                }
            }
            // Negative shock coefficients
            forvalues j = 0/`=`q_use'-1' {
                local ++col
                if `j' == 0 {
                    qui replace `yhat_sr' = `yhat_sr' + `bsr'[1,`col'] * D.`nv' if `touse'
                }
                else {
                    qui replace `yhat_sr' = `yhat_sr' + `bsr'[1,`col'] * L`j'D.`nv' if `touse'
                }
            }
        }

        // 4. Exogenous variables
        local exogvars "`e(exogvars)'"
        if "`exogvars'" != "" {
            foreach v of local exogvars {
                local ++col
                qui replace `yhat_sr' = `yhat_sr' + `bsr'[1,`col'] * `v' if `touse'
            }
        }

        // 5. Trend
        local trendvar "`e(trendvar)'"
        if "`trendvar'" != "" {
            local ++col
            qui replace `yhat_sr' = `yhat_sr' + `bsr'[1,`col'] * `trendvar' if `touse'
        }

        // 6. Constant (last column)
        if `col' < `ncols' {
            local ++col
            qui replace `yhat_sr' = `yhat_sr' + `bsr'[1,`col'] if `touse'
        }

        if "`residuals'" != "" {
            gen `typlist' `varlist' = D.`depvar' - `yhat_sr' if `touse'
            label variable `varlist' "Residuals"
        }
        else {
            gen `typlist' `varlist' = `yhat_sr' if `touse'
            label variable `varlist' "Fitted values"
        }
    }
    else if "`ecterm'" != "" {
        local ectvar "`e(ect_var)'"
        if "`ectvar'" == "" {
            di as error "ECT variable name not stored. Re-run twostep_nardl first."
            exit 111
        }
        capture confirm variable `ectvar'
        if _rc {
            di as error "ECT variable `ectvar' not found. Re-run twostep_nardl first."
            exit 111
        }
        gen `typlist' `varlist' = `ectvar' if `touse'
        label variable `varlist' "Error correction term"
    }
end
