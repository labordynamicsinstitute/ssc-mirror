*! version 1.0.0  26jan2026
program define ate_pct, rclass
    version 14.0
    syntax varlist(min=1) [if] , [truew groupsize(numlist)]

    // Group indicator variables (d_i^g)
    local groupvars `varlist'
    local G: word count `groupvars'

    // check if there is e-class estimation.
    capture confirm matrix e(b)
    if (_rc) {
        di as error "ate_pct requires a preceding e-class estimation (with e(b), e(V), and e(sample))."
    exit 301
    }
    capture confirm matrix e(V)
    if (_rc) {
        di as error "Missing e(V) from the preceding estimation."
    exit 301
    }



    // Estimation sample from last e-class estimation
	tempvar touse
	marksample touse

	* restrict further to the estimation sample
	qui replace `touse' = 0 if e(sample) == 0


    // Pull coefficient vector and vcov from last estimation
    tempname beta vcov N
    matrix `beta' = e(b)
    matrix `vcov' = e(V)
    scalar `N' = e(N)

    // Prepare tau, weights, Sigma_tau, Sigma_w
    tempname tau wgt Sigma_tau Sigma_w
    matrix `tau'       = J(`G', 1, .)
    matrix `Sigma_tau' = J(`G', `G', 0)

    // Extract tau and Sigma_tau for group dummies
    forvalues g = 1/`G' {
        local dvar: word `g' of `groupvars'
        local col = colnumb(`beta', "`dvar'")

        if (`col' <= 0) {
            di as error "Group variable `dvar' not found in regression!"
            exit 198
        }
            matrix `tau'[`g', 1] = `beta'[1, `col']
            forvalues h = 1/`G' {
                local dvar2: word `h' of `groupvars'
                local col2 = colnumb(`beta', "`dvar2'")                
                    matrix `Sigma_tau'[`g', `h'] = `vcov'[`col', `col2']                
            }
        }
        // ------------------------------------------------------------
    // Group sizes and weights
    // If option groupsize() is provided: treat it as N_g (group sizes)
    // Otherwise: count N_g from group indicators within e(sample)
    // ------------------------------------------------------------
    tempname N_g N_s p_s
    matrix `N_g' = J(`G', 1, .)

    if ("`groupsize'" != "") {
        // Validate length of supplied numlist equals number of groups

        local nw : word count `groupsize'
        if (`nw' != `G') {
            di as error "Option groupsize() must contain exactly `G' numbers (one N_g per group, in the same order as the group vars)."
            exit 198
        }

        // Fill N_g from the provided list
        forvalues g = 1/`G' {
            local ng_val : word `g' of `groupsize'
            if (real("`ng_val'") <= 0) {
                di as error "All elements in groupsize() must be > 0. Found groupsize[`g'] = `ng_val'."
                exit 198
            }
            matrix `N_g'[`g', 1] = real("`ng_val'")
        }

        // N_s is the sum of supplied group sizes

        matrix define __ones = J(`G',1,1)
		matrix __sumn =__ones' * `N_g'      // 1x1
		scalar `N_s'   = __sumn[1,1]
        scalar `p_s' = `N_s'/`N'
        matrix drop __ones __sumn

    }       
    else {
    // Compute s_i = sum_g d_i^g
    tempvar s_i
    qui gen `s_i' = 0
    foreach dvar of varlist `groupvars' {
        quietly count if `dvar'!= 0 & `dvar'!= 1 & `touse'
        if (r(N) > 0) {
        di as error "Group indicators must be 0/1."
        exit 198
    }
        qui replace `s_i' = `s_i' + `dvar'
    }

 // Check if group dummies are mutually exclusive.   
    quietly count if `s_i' > 1 & `touse'
    if (r(N) > 0) {
        di as error "Group indicators must be mutually exclusive within the target sample (found observations with multiple groups)."
        exit 198
    }

        // Count group sizes within estimation sample
    forvalues g = 1/`G' {
        local dvar: word `g' of `groupvars'
        quietly count if `dvar' == 1 & `touse'

        if (r(N) == 0) {
        di as error "Group `dvar' has no observations in the target sample."
        exit 198
        }

        matrix `N_g'[`g', 1] = r(N)
    }

    quietly count if `s_i' == 1 & `touse'
    scalar `N_s' = r(N)
    scalar `p_s' = `N_s'/`N'
    }

    matrix `wgt' = `N_g' * (1/`N_s')
    // Sigma_w
    tempname diag_w ww
    matrix `diag_w' = diag(`wgt')
    matrix `ww'     = `wgt' * `wgt''

    if ("`truew'" == "") {
        if (`p_s' <= 0) {
            di as error "p_s <= 0; cannot compute Sigma_w."
            exit 2001
        }
        matrix `Sigma_w' = (1/`N') * (1/`p_s') * (`diag_w' - `ww')
    }
    else {
        matrix `Sigma_w' = J(`G', `G', 0)
    }

    // If truew is not enabled, display how weights are formed
    if ("`truew'" == "") {
        di as text "Note: weights are estimated using N_T =" %12.0f `N_s' " observations (p_T = " %9.6f `p_s' ").
    }

    // Core calculations in Mata (writes to r(b), r(V), r(delta), r(Sigma_delta))
    mata: calc_basic("`tau'","`wgt'","`Sigma_tau'","`Sigma_w'")
    // Grab Mata results
    tempname b V delta Sigma_delta
    matrix `b'           = r(b)
    matrix `V'           = r(V)
    matrix `delta'       = r(delta)
    matrix `Sigma_delta' = r(Sigma_delta)
	
    // Label results
    matname `b' taubar rho_a rho_b, explicit c(.)
    matname `V' taubar rho_a rho_b, explicit
    // -----------------------------
    // Store results in r()
    // -----------------------------
    return clear
    return local  cmd   "ate_pct"
    return scalar N     = `N'
    return scalar N_T   = `N_s'
    return scalar p_T   = `p_s'

    return matrix b           = `b'
    return matrix V           = `V'
    return matrix delta       = `delta'
    return matrix Sigma_delta = `Sigma_delta'

    // Also return underlying pieces (optional but handy)
    return matrix tau       = `tau'
    return matrix w         = `wgt'
    return matrix Sigma_tau = `Sigma_tau'
    return matrix Sigma_w   = `Sigma_w'


// -----------------------------
// Display results as a table
// -----------------------------
tempname se z pval lb ub
matrix `se' = J(1, colsof(r(b)), .)
matrix `z'  = J(1, colsof(r(b)), .)
matrix `pval' = J(1, colsof(r(b)), .)
matrix `lb' = J(1, colsof(r(b)), .)
matrix `ub' = J(1, colsof(r(b)), .)

scalar level = c(level)
scalar zalpha = invnormal(1 - (100 - level)/200)
forvalues i = 1/`=colsof(r(b))' {
    matrix `se'[1,`i'] = sqrt(r(V)[`i',`i'])
    matrix `z'[1,`i'] = r(b)[1,`i'] / `se'[1,`i']
    matrix `pval'[1,`i'] = 2 * (1 - normal(abs(`z'[1,`i'])))
    matrix `lb'[1,`i'] = r(b)[1,`i'] - zalpha * `se'[1,`i']
    matrix `ub'[1,`i'] = r(b)[1,`i'] + zalpha * `se'[1,`i']
}

// Display table
di as text _newline "ATE in Percentage Points"
di as text "-----------------------------------------------------------------------------------------"
di as text %12s "Parameter" %12s "Estimate" %14s "Std. Err." %8s "z" %14s "P>|z|" ///
   %6s "[" %3.0f level "% conf." %8s "interval]"
di as text "-----------------------------------------------------------------------------------------"

local names  "taubar rho_a rho_b"
forvalues i = 1/`=colsof(r(b))' {
    local name : word `i' of `names'
    di as result %12s "`name'" ///
       %12.4f r(b)[1,`i'] ///
       %12.4f `se'[1,`i'] ///
	   %12.4f `z'[1,`i'] ///
       %12.4f `pval'[1,`i'] ///
       %12.4f `lb'[1,`i'] ///
       %12.4f `ub'[1,`i']
}
di as text "-----------------------------------------------------------------------------------------"
end


mata:
void calc_basic(string scalar tau_name, string scalar w_name,
                string scalar Sigma_tau_name, string scalar Sigma_w_name)
{
    real matrix tau, w, Sigma_tau, Sigma_w, Sigma_eta
    real scalar taubar, Var_taubar, rho_a, Var_rho_a, rho_b, Var_b
    real matrix expeta0, b, V, se
    real scalar G

    tau       = st_matrix(tau_name)
    w         = st_matrix(w_name)
    Sigma_w   = st_matrix(Sigma_w_name)
    Sigma_tau = st_matrix(Sigma_tau_name)
    G = rows(tau)

    expeta0      = w :* exp(tau)
    Sigma_eta = diag(1:/w) * Sigma_w * diag(1:/w) + Sigma_tau

    taubar      = (w'*tau)[1,1]
    Var_taubar  = (w'*Sigma_tau*w)[1,1] + (tau'*Sigma_w*tau)[1,1]

    rho_a       = exp(taubar) - 1
    Var_rho_a   = (exp(taubar))^2 * Var_taubar

    rho_b       = sum(w :* exp(tau)) - 1
    Var_b       = expeta0' * Sigma_eta * expeta0

    b  = (taubar, rho_a, rho_b)
    se = (sqrt(Var_taubar), sqrt(Var_rho_a), sqrt(Var_b))
    V  = diag(se:^2)

    st_rclear()
    st_matrix("r(b)", b)
    st_matrix("r(V)", V)
    st_matrix("r(delta)", (tau \ w))
    st_matrix("r(Sigma_delta)", blockdiag(Sigma_tau, Sigma_w))
}
end
