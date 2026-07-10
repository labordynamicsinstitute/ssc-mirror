/*
    Generate estimated time fixed effects (beta) for the estimation sample.
    
    This program retrieves the estimated time fixed effects vector e(beta)
    and maps the values to observations based on the time variable used
    during estimation.
    
    The time fixed effects are identified under the normalization beta_1 = 0.
    
    Syntax:
        predict <newvar> [if] [in], beta
*/


program define trop_predict_beta
    version 17
    syntax newvarname [if] [in]
    
    marksample touse, novarlist
    
    
    // Verify existence of time fixed effects matrix.
    capture matrix list e(beta)
    if _rc {
        di as error "e(beta) matrix not found"
        exit 498
    }
    
    // Initialize the output variable.
    qui gen double `varlist' = .
    
    // Generate time index variable.
    // Restricts the index generation to the estimation sample to ensure
    // consistency with the rows of the e(beta) vector.
    tempvar time_idx
    qui egen `time_idx' = group(`e(timevar)') if e(sample)
    
    // Map time indices to estimated time fixed effects.
    mata: _trop_predict_beta_extract("`varlist'", "`time_idx'", "`touse'")
    
    label variable `varlist' "Time fixed effect (beta)"
end

// -----------------------------------------------------------------------------
// Mata Helper Function
// -----------------------------------------------------------------------------
version 17
mata:
mata set matastrict on

void _trop_predict_beta_extract(
    string scalar varname,
    string scalar time_var,
    string scalar touse_var
)
{
    /*
    Maps time indices to the corresponding elements of the estimated
    time fixed effects vector.
    
    Arguments:
        varname:   Name of the Stata variable to populate.
        time_var:  Name of the variable containing time indices (1..T).
        touse_var: Name of the variable indicating the sample inclusion.
    */

    real colvector beta
    real colvector time_idx
    real colvector beta_vec
    real scalar n, i, t_idx
    
    // Import the estimated time fixed effects vector.
    beta = st_matrix("e(beta)")
    
    // Import time indices for the specified sample.
    time_idx = st_data(., time_var, touse_var)
    
    n = rows(time_idx)
    beta_vec = J(n, 1, .)
    
    // Assign the corresponding beta value for each observation.
    for (i = 1; i <= n; i++) {
        t_idx = time_idx[i]
        if (t_idx >= 1 & t_idx <= rows(beta)) {
            beta_vec[i] = beta[t_idx]
        }
    }
    
    // Store the results in the Stata variable.
    st_store(., varname, touse_var, beta_vec)
}

end
