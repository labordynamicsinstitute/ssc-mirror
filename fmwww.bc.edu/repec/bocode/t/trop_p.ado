*! Post-estimation prediction for TROP
*! Implements the predict command after trop estimation

program define trop_p
    version 17
    syntax newvarname [if] [in], ///
        [y0 y1 te residuals alpha beta mu XB ///
         ATT Counterfactual FITted RObust_check]

    // --- Option Validation ---

    // Count the number of specified prediction options; mutual exclusivity is enforced.
    local opts_count = ("`y0'"!="") + ("`y1'"!="") + ("`te'"!="") + ///
                        ("`residuals'"!="") + ("`alpha'"!="") + ///
                        ("`beta'"!="") + ("`mu'"!="") + ("`xb'"!="") + ///
                        ("`att'"!="") + ("`counterfactual'"!="") + ///
                        ("`fitted'"!="")

    if `opts_count' > 1 {
        di as error "Only one prediction type allowed"
        exit 198
    }

    // Set default prediction type to y0 if no specific option is provided.
    if `opts_count' == 0 {
        local y0 "y0"
    }

    // --- Verify Estimation Results ---

    // Ensure that trop was the last estimation command executed.
    if "`e(cmd)'" != "trop" {
        di as error "last estimates not found"
        exit 301
    }

    // --- Validate Prediction Prerequisites ---
    trop_predict_validate, `robust_check'

    // --- Data Integrity Check ---
    // Compare the checksum of the dependent variable to ensure the dataset has not
    // been modified since estimation. This prevents invalid predictions on altered data.
    if e(_depvar_checksum) != . & "`e(depvar)'" != "" {
        qui sum `e(depvar)' if e(sample), meanonly
        if reldif(r(sum), e(_depvar_checksum)) > 1e-10 {
            di as error "Data has changed since trop was run. Re-run trop before predict."
            exit 459
        }
    }

    // --- Mark Estimation Sample ---
    marksample touse, novarlist

    // --- Dispatch Prediction Subroutines ---

    if "`y0'" != "" | "`xb'" != "" | "`counterfactual'" != "" {
        // Calculate counterfactual outcome Y(0).
        // Options y0, xb, and counterfactual are all equivalent.
        trop_predict_y0 `varlist' if `touse'
    }
    else if "`y1'" != "" {
        // Calculate counterfactual outcome Y(1).
        trop_predict_y1 `varlist' if `touse'
    }
    else if "`te'" != "" | "`att'" != "" {
        // Calculate treatment effects.
        // Options te and att are equivalent.
        trop_predict_te `varlist' if `touse'
    }
    else if "`residuals'" != "" {
        // Calculate residuals: Y - Yhat where Yhat = Y(0) + tau*W.
        trop_predict_residuals `varlist' if `touse'
    }
    else if "`fitted'" != "" {
        // Calculate fitted values: Yhat = alpha_i + beta_t + L_{it} + tau_{it}*W_{it}
        // For control obs: Yhat = Y(0); for treated obs: Yhat = Y(0) + tau.
        trop_predict_fitted `varlist' if `touse'
    }
    else if "`alpha'" != "" {
        // Predict alpha coefficients.
        trop_predict_alpha `varlist' if `touse'
    }
    else if "`beta'" != "" {
        // Predict beta coefficients.
        trop_predict_beta `varlist' if `touse'
    }
    else if "`mu'" != "" {
        // Predict mu (mean) values.
        trop_predict_mu `varlist' if `touse'
    }
end
