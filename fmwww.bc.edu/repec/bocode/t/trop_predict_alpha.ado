*! trop_predict_alpha -- generate unit fixed effects from estimation results

/*
    trop_predict_alpha

    Generates predicted unit fixed effects (alpha_i) from e(alpha).
    Each unit receives a single time-invariant intercept.  Within the
    joint estimator the first unit is normalised to zero for
    identification.

    Syntax
        predict <newvar> [if] [in], alpha
*/


program define trop_predict_alpha
    version 17
    syntax newvarname [if] [in]
    
    marksample touse, novarlist
    
    
    // Confirm that e(alpha) was stored by the estimation command
    capture matrix list e(alpha)
    if _rc {
        di as error "e(alpha) matrix not found"
        exit 498
    }
    
    // Initialise the target variable
    qui gen double `varlist' = .
    
    // Construct a sequential panel index, restricted to the estimation sample
    // so that group numbering matches the row order of e(alpha)
    tempvar panel_idx
    qui egen `panel_idx' = group(`e(panelvar)') if e(sample)
    
    // Map e(alpha) entries to individual observations via the panel index
    mata: _trop_predict_alpha_extract("`varlist'", "`panel_idx'", "`touse'")
    
    label variable `varlist' "Unit fixed effect (alpha)"
end

// ---------------------------------------------------------------------------
// Mata helper
// ---------------------------------------------------------------------------
version 17
mata:
mata set matastrict on

/*
    _trop_predict_alpha_extract()

    Reads the N_units x 1 vector e(alpha) and assigns alpha[i] to every
    observation belonging to unit i.

    Arguments
        varname    -- name of the Stata variable to store results
        panel_var  -- name of the sequential panel-index variable
        touse_var  -- name of the sample-marker variable
*/
void _trop_predict_alpha_extract(
    string scalar varname,
    string scalar panel_var,
    string scalar touse_var
)
{
    real colvector alpha
    real colvector panel_idx
    real colvector alpha_vec
    real scalar n, i, i_idx
    
    alpha     = st_matrix("e(alpha)")
    panel_idx = st_data(., panel_var, touse_var)
    
    n         = rows(panel_idx)
    alpha_vec = J(n, 1, .)
    
    for (i = 1; i <= n; i++) {
        i_idx = panel_idx[i]
        if (i_idx >= 1 & i_idx <= rows(alpha)) {
            alpha_vec[i] = alpha[i_idx]
        }
    }
    
    st_store(., varname, touse_var, alpha_vec)
}

end
