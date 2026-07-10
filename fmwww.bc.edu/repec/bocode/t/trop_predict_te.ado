*! Predict treatment effects after trop estimation

/*
    Post-estimation command: generates predicted treatment effects for
    treated observations.

    Two-step method:
        Retrieves the observation-specific estimates tau_{it} stored in e(tau),
        where tau_{it} = Y_{it} - alpha_i - beta_t - L_{it}. Each treated cell
        receives its own estimate, permitting heterogeneous effects across
        units and time periods.

    Joint method:
        Assigns the scalar ATT estimate to every treated observation, under
        the maintained assumption of a homogeneous treatment effect.

    Control observations receive missing values.
*/


program define trop_predict_te
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

    qui gen double `varlist' = .
    
    if "`method'" == "twostep" {
        // Map observation-specific tau_{it} from e(tau) back to the dataset.
        mata: _trop_predict_te_twostep("`varlist'", "`e(panelvar)'", "`e(timevar)'", "`treatvar'", "`touse'")
    }
    else {
        // Assign the homogeneous ATT to all treated cells.
        local att = e(att)
        if missing(`att') {
            di as error "e(att) is missing"
            exit 498
        }
        qui replace `varlist' = `att' if `treatvar' == 1 & `touse'
    }
    
    if "`method'" == "joint" {
        label variable `varlist' "Treatment effect (shared tau / ATT)"
    }
    else {
        label variable `varlist' "Treatment effect (cell-specific tau_it)"
    }
end


version 17
mata:
mata set matastrict on

/*
    _trop_predict_te_twostep()

    Maps the N_treated x 1 vector e(tau) to the corresponding observations
    in the current dataset. The vector is ordered by (time, unit) within the
    estimation sample; this function reconstructs that ordering to assign
    each tau_{it} to the correct row.
*/
void _trop_predict_te_twostep(
    string scalar varname,
    string scalar panelvar,
    string scalar timevar,
    string scalar treatvar,
    string scalar touse_var
)
{
    real matrix tau_vec
    real colvector panel_idx, time_idx, treat, pred, obs_order
    real scalar n, k, tau_k, i, n_tau, obs_i
    real matrix treated_info
    real scalar n_treated
    
    tau_vec = st_matrix("e(tau)")
    if (rows(tau_vec) == 0) {
        errprintf("e(tau) is empty or missing\n")
        return
    }
    n_tau = rows(tau_vec)
    
    // Build integer group indices for panel and time within e(sample).
    {
        string scalar temp_pidx, temp_tidx
        
        temp_pidx = st_tempname()
        temp_tidx = st_tempname()
        
        stata("qui egen " + temp_pidx + " = group(" + panelvar + ") if e(sample)")
        stata("qui egen " + temp_tidx + " = group(" + timevar + ") if e(sample)")
        
        panel_idx = st_data(., temp_pidx, touse_var)
        time_idx = st_data(., temp_tidx, touse_var)
        treat = st_data(., treatvar, touse_var)
        
        stata("capture drop " + temp_pidx)
        stata("capture drop " + temp_tidx)
    }
    
    n = rows(panel_idx)
    
    // Count treated observations with valid indices.
    n_treated = 0
    for (i = 1; i <= n; i++) {
        if (treat[i] == 1 && panel_idx[i] < . && time_idx[i] < .) {
            n_treated++
        }
    }
    
    if (n_treated == 0 || n_treated != n_tau) {
        if (n_treated != n_tau) {
            printf("{txt}(note: treated obs count %g != e(tau) length %g; falling back to Y-Y(0))\n",
                   n_treated, n_tau)
            _trop_predict_te_fallback(varname, touse_var)
            return
        }
        return
    }
    
    // Collect (time_idx, panel_idx, row_index) for treated cells.
    treated_info = J(n_treated, 3, .)
    k = 0
    for (i = 1; i <= n; i++) {
        if (treat[i] == 1 && panel_idx[i] < . && time_idx[i] < .) {
            k++
            treated_info[k, 1] = time_idx[i]
            treated_info[k, 2] = panel_idx[i]
            treated_info[k, 3] = i
        }
    }
    
    // Sort by (time, unit) to match the ordering convention in e(tau).
    treated_info = sort(treated_info, (1, 2))
    
    // Assign tau_{it} values to the corresponding rows.
    pred = J(n, 1, .)
    for (k = 1; k <= n_treated; k++) {
        obs_i = treated_info[k, 3]
        pred[obs_i] = tau_vec[k, 1]
    }
    
    st_store(., varname, touse_var, pred)
}


/*
    _trop_predict_te_fallback()

    Fallback when e(tau) cannot be matched to the current data. Computes
    tau_{it} = Y_{it} - Yhat_{it}(0) from the stored parameter estimates.
*/
void _trop_predict_te_fallback(
    string scalar varname,
    string scalar touse_var
)
{
    string scalar tmpname
    
    printf("{txt}(note: calculating treatment effects from parameter estimates)\n")
    
    tmpname = st_tempname()
    stata("qui trop_predict_y0 " + tmpname + " if " + touse_var)
    stata("qui replace " + varname + " = " + st_global("e(depvar)") + 
          " - " + tmpname + " if " + st_global("e(treatvar)") + " == 1 & " + touse_var)
    stata("capture drop " + tmpname)
}

end
