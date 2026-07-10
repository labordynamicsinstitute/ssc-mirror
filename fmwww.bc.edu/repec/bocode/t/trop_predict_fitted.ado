*! Fitted value prediction for trop
/*
    trop_predict_fitted

    Generates fitted values Yhat for each observation:

        Yhat_{it} = alpha_i + beta_t + L_{it} + tau_{it} * W_{it}

    For control observations (W=0):
        Yhat = alpha_i + beta_t + L_{it}   (equivalent to Y(0))

    For treated observations (W=1):
        Yhat = alpha_i + beta_t + L_{it} + tau_{it}   (equivalent to Y(1))

    Two-step method:
        Uses observation-specific tau_{it} from e(tau) for treated cells.

    Joint method:
        Uses scalar ATT from e(att) for all treated cells.
        Includes global intercept mu in the prediction.

    Required stored estimates:
        e(alpha)          unit fixed effects (N x 1)
        e(beta)           time fixed effects (T x 1)
        e(factor_matrix)  low-rank interaction (T x N, column-major)
        e(mu)             intercept (joint method)
        e(tau)            observation-level treatment effects
        e(att)            scalar ATT (joint method fallback)
*/


program define trop_predict_fitted
    version 17
    syntax newvarname [if] [in]

    marksample touse, novarlist

    // Retrieve estimation results.
    local treatvar "`e(treatvar)'"
    if "`treatvar'" == "" {
        di as error "e(treatvar) is missing"
        exit 498
    }

    local depvar "`e(depvar)'"
    if "`depvar'" == "" {
        di as error "e(depvar) is missing"
        exit 498
    }

    local method "`e(method)'"
    if "`method'" == "" {
        local method "twostep"
    }

    // Step 1: Compute counterfactual Y(0) as the base.
    tempvar y0_temp
    qui trop_predict_y0 `y0_temp' if `touse'

    // Step 2: For treated observations, add tau to get fitted value.
    qui gen double `varlist' = `y0_temp' if `touse'

    if "`method'" == "twostep" {
        // Use observation-specific tau from e(tau) if available.
        capture confirm matrix e(tau)
        if !_rc {
            tempvar te_temp
            qui trop_predict_te `te_temp' if `touse'
            qui replace `varlist' = `y0_temp' + `te_temp' ///
                if `treatvar' == 1 & `te_temp' < . & `touse'
        }
        else {
            // Fall back to scalar ATT.
            local att = e(att)
            if !missing(`att') {
                qui replace `varlist' = `y0_temp' + `att' ///
                    if `treatvar' == 1 & `touse'
            }
        }
    }
    else {
        // Joint method: scalar ATT applies to all treated observations.
        local att = e(att)
        if !missing(`att') {
            qui replace `varlist' = `y0_temp' + `att' ///
                if `treatvar' == 1 & `touse'
        }
    }

    label variable `varlist' "Fitted values (Y(0) + tau*W)"
end
