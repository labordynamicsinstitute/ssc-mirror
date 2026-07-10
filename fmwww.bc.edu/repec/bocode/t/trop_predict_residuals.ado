*! Postestimation residual prediction for trop

/*
    trop_predict_residuals

    Generates residuals from a fitted trop model:

        e_{it} = Y_{it} - Y_{it}(0) - tau_{it} * W_{it}

    where Y_{it}(0) is the estimated counterfactual outcome and tau_{it} is
    the estimated treatment effect.

    Under the twostep estimator, tau_{it} is observation-specific and stored
    in e(tau).  Under the joint estimator, tau_{it} reduces to the scalar
    ATT in e(att).  For control observations (W_{it}=0) the residual
    simplifies to e_{it} = Y_{it} - Y_{it}(0).

    The tau vector in e(tau) is ordered time-major: sorted by (time, panel)
    to match the enumeration produced by the nuclear-norm solver.
*/


program define trop_predict_residuals
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

    local att = e(att)
    if `att' == . {
        di as error "e(att) is missing"
        exit 498
    }

    // Obtain the counterfactual Y(0).
    qui gen double `varlist' = .

    tempvar y0_temp
    qui trop_predict_y0 `y0_temp' if `touse'

    // Compute residuals.
    local method "`e(method)'"
    if "`method'" == "" {
        local method "twostep"
    }

    if "`method'" == "twostep" {
        // Twostep estimator: use observation-specific tau_{it} if available.
        capture confirm matrix e(tau)
        if !_rc {
            // Map each element of e(tau) to its treated observation.
            // The tau vector is time-major ordered: within each period,
            // entries run across panel units.
            local n_tau = rowsof(e(tau))

            tempvar tau_individual orig_order time_grp panel_grp treat_rank
            qui gen long `orig_order' = _n
            qui egen `time_grp' = group(`e(timevar)') if e(sample)
            qui egen `panel_grp' = group(`e(panelvar)') if e(sample)

            // Sort time-major to align with the tau vector ordering.
            sort `time_grp' `panel_grp'

            // Cumulative rank among treated observations in the sample.
            qui gen long `treat_rank' = sum(`treatvar' == 1 & e(sample)) ///
                if `treatvar' == 1 & e(sample)

            // Distribute tau elements to the corresponding observations.
            qui gen double `tau_individual' = 0
            forvalues k = 1/`n_tau' {
                qui replace `tau_individual' = el(e(tau), `k', 1) ///
                    if `treat_rank' == `k'
            }

            sort `orig_order'

            // e_{it} = Y_{it} - Y(0)_{it} - tau_{it}
            // Control observations have tau_{it} = 0 by construction.
            qui replace `varlist' = `depvar' - `y0_temp' - `tau_individual' ///
                if `touse'
            label variable `varlist' "Residuals (Y - Y(0) - tau_it*D)"
        }
        else {
            // e(tau) not available; fall back to scalar ATT.
            qui replace `varlist' = `depvar' - `y0_temp' - `att' * `treatvar' ///
                if `touse'
            label variable `varlist' "Residuals (Y - Y(0) - ATT*D)"
        }
    }
    else {
        // Joint estimator: scalar ATT applies to all treated observations.
        qui replace `varlist' = `depvar' - `y0_temp' - `att' * `treatvar' ///
            if `touse'
        label variable `varlist' "Residuals (Y - Y(0) - ATT*D)"
    }
end
