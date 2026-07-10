*! Prediction of potential outcome Y(1)

/*
    trop_predict_y1

    Generates predicted potential outcome Y(1) for all observations.

    Joint:    Y_hat(1) = Y_hat(0) + ATT
    Twostep:  Y_hat(1) = Y_hat(0) + tau_it   (treated)
              Y_hat(1) = Y_hat(0) + ATT       (control)
*/


program define trop_predict_y1
    version 17
    syntax newvarname [if] [in]
    
    marksample touse, novarlist
    
    
    qui gen double `varlist' = .
    
    local att = e(att)
    if `att' == . {
        di as error "e(att) is missing"
        exit 498
    }
    
    // Obtain Y_hat(0) as baseline
    tempvar y0_temp
    qui trop_predict_y0 `y0_temp' if `touse'
    
    local method "`e(method)'"
    if "`method'" == "" {
        local method "twostep"
    }
    
    if "`method'" == "twostep" {
        capture confirm matrix e(tau)
        if !_rc {
            local treatvar "`e(treatvar)'"
            
            // Default: Y(1) = Y(0) + ATT
            qui replace `varlist' = `y0_temp' + `att' if `touse'
            
            // Override treated obs with observation-specific tau_it
            if "`treatvar'" != "" {
                local n_tau = rowsof(e(tau))
                
                tempvar tau_individual orig_order time_grp panel_grp treat_rank
                qui gen long `orig_order' = _n
                qui egen `time_grp' = group(`e(timevar)') if e(sample)
                qui egen `panel_grp' = group(`e(panelvar)') if e(sample)
                
                // Sort by time then unit to match estimation ordering
                sort `time_grp' `panel_grp'
                
                // Rank treated observations within e(sample)
                qui gen long `treat_rank' = sum(`treatvar' == 1 & e(sample)) if `treatvar' == 1 & e(sample)
                
                // Map e(tau) elements to corresponding treated observations
                qui gen double `tau_individual' = 0
                forvalues k = 1/`n_tau' {
                    qui replace `tau_individual' = el(e(tau), `k', 1) if `treat_rank' == `k'
                }
                
                sort `orig_order'
                
                // Y(1) = Y(0) + tau_it for treated
                qui replace `varlist' = `y0_temp' + `tau_individual' if `treatvar' == 1 & `touse'
            }
            label variable `varlist' "Potential outcome Y(1) [tau_it for treated]"
        }
        else {
            // e(tau) unavailable; use scalar ATT
            qui replace `varlist' = `y0_temp' + `att' if `touse'
            label variable `varlist' "Potential outcome Y(1)"
        }
    }
    else {
        // Joint: scalar ATT for all observations
        qui replace `varlist' = `y0_temp' + `att' if `touse'
        label variable `varlist' "Potential outcome Y(1)"
    }
end
