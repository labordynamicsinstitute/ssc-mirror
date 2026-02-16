*! _qardl_simulate v1.1.0 - Monte Carlo simulation for QARDL
*! Translates WaldTestsSims.m and qardlestimation.m
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)

program define _qardl_simulate, rclass
    version 14.0
    
    syntax, REPS(integer) NOBS(integer) P(integer) Q(integer) ///
        TAU(numlist >0 <1 sort) K(integer)
    
    local ntau : word count `tau'
    
    * DGP parameters (from Cho et al. 2015)
    local alpha = 1
    local phi_dgp = 0.25
    local rho = 0.5
    local the0 = 2
    local the1 = 3
    local gam = `the0' + `the1'
    local bes = `gam' / (1 - `phi_dgp')
    
    mata: _sim_tau = strtoreal(tokens(st_local("tau")))'
    
    * Run simulation
    mata: _qardl_mc_sim(`reps', `nobs', `p', `q', _sim_tau, `k', ///
        `alpha', `phi_dgp', `rho', `the0', `the1')
    
    * Display results
    di as txt _n "{hline 70}"
    di as res "  Monte Carlo Simulation Results"
    di as txt "{hline 70}"
    di as txt "  DGP: y_t = " as res %4.1f `alpha' as txt " + " ///
        as res %4.2f `phi_dgp' as txt "*y_{t-1} + " ///
        as res `the0' as txt "*x_t + " as res `the1' as txt "*x_{t-1} + u_t"
    di as txt "  True beta  = gamma/(1-phi) = " ///
        as res %8.4f `bes'
    di as txt "  Replications : " as res `reps'
    di as txt "  Sample size  : " as res `nobs'
    di as txt "{hline 70}"
    
    di as txt _n
    di as txt "{hline 70}"
    di as res "  Empirical Rejection Rates (Wald Tests under H0)"
    di as txt "{hline 70}"
    di as txt "  {ralign 20:Test}" _c
    di as txt "  {ralign 10:10%}" _c
    di as txt "  {ralign 10:5%}" _c
    di as txt "  {ralign 10:1%}" _c
    di as txt "  {ralign 12:Mean stat}"
    di as txt "{hline 70}"
    
    tempname sim_res
    mat `sim_res' = _sim_results
    
    if rowsof(`sim_res') >= 3 {
        local tests "Beta" "Phi" "Gamma"
        forvalues i = 1/3 {
            local tname : word `i' of `tests'
            di as txt "  W_`tname'" _c
            
            forvalues j = 1/3 {
                local val = `sim_res'[`i', `j']
                if `val' > 0.15 | `val' < 0.001 {
                    di as err "  " %8.4f `val' _c
                }
                else {
                    di as res "  " %8.4f `val' _c
                }
            }
            di as res "  " %10.3f `sim_res'[`i', 4]
        }
    }
    
    di as txt "{hline 70}"
    di as txt "  Note: Under H0, rejection rates should be close to"
    di as txt "  nominal levels (10%, 5%, 1%)."
    di as txt "{hline 70}"
    
    return matrix sim_results = `sim_res'
end

capture mata: mata drop _qardl_mc_sim()

mata:
mata set matastrict off

void _qardl_mc_sim(real scalar reps, real scalar nn, real scalar ppp,
    real scalar qqq, real colvector tau, real scalar k,
    real scalar alpha, real scalar phi_dgp, real scalar rho,
    real scalar the0, real scalar the1)
{
    real scalar iii, jj, ss, ncols
    real matrix www, yy, xx, eee1, eee, eee2, uuu
    real scalar gam, bes
    real colvector xxx1, xxx2
    real matrix data
    
    ss = rows(tau)
    gam = the0 + the1
    bes = gam / (1 - phi_dgp)
    
    // Storage: pvlrb, pvsrp, pvsrg, wtlrb, wtsrp, wtsrg
    www = J(reps, 6, 0)
    
    for (iii = 1; iii <= reps; iii++) {
        // Generate DGP
        eee1 = rnormal(nn+1, 1, 0, 1)
        eee = rho * eee1[1..nn] + (1 - rho^2) * eee1[2..nn+1]
        eee2 = rnormal(nn, 1, 0, 1)
        xxx1 = runningsum(eee)
        xxx2 = runningsum(eee2)
        xx = (xxx1, xxx2)
        uuu = rnormal(nn, 1, 0, 1)
        yy = J(nn, 1, 0)
        
        for (jj = 2; jj <= nn; jj++) {
            yy[jj] = alpha + phi_dgp*yy[jj-1] + the0*xx[jj,1] + the1*xx[jj-1,1] + 
                     the0*xx[jj,2] + the1*xx[jj-1,2] + uuu[jj]
        }
        
        data = (yy, xx)
        
        // Run QARDL on simulated data
        _qardl_core_estimate(yy, xx, ppp, qqq, tau)
        
        // Get results
        real matrix beta, beta_cov, phi, phi_cov, gamma, gamma_cov
        beta = st_matrix("_qardl_beta")
        beta_cov = st_matrix("_qardl_beta_cov")
        phi = st_matrix("_qardl_phi")
        phi_cov = st_matrix("_qardl_phi_cov")
        gamma = st_matrix("_qardl_gamma")
        gamma_cov = st_matrix("_qardl_gamma_cov")
        
        // Beta test (H0: beta = true value)
        real matrix R_b, r_b
        ncols = rows(beta)
        if (ncols >= 2*k) {
            R_b = J(2, ncols, 0)
            R_b[1, 1] = 1
            R_b[2, 2] = 1
            r_b = J(2, 1, bes)
            
            real matrix diff_b, RCR_b
            diff_b = R_b * beta - r_b
            RCR_b = R_b * beta_cov * R_b'
            RCR_b = RCR_b + 1e-12 * I(rows(RCR_b))
            www[iii, 4] = (nn-1)^2 * diff_b' * luinv(RCR_b) * diff_b
            if (www[iii, 4] < 0) www[iii, 4] = abs(www[iii, 4])
            www[iii, 1] = 1 - chi2(2, www[iii, 4])
        }
        
        // Phi test (H0: phi(tau1) = phi(tau2))
        ncols = rows(phi)
        if (ncols >= 2*ppp & ss >= 2) {
            R_b = J(1, ncols, 0)
            R_b[1, 1] = 1
            R_b[1, ppp+1] = -1
            r_b = J(1, 1, 0)
            
            diff_b = R_b * phi - r_b
            RCR_b = R_b * phi_cov * R_b'
            RCR_b = RCR_b + 1e-12 * I(rows(RCR_b))
            www[iii, 5] = (nn-1) * diff_b' * luinv(RCR_b) * diff_b
            if (www[iii, 5] < 0) www[iii, 5] = abs(www[iii, 5])
            www[iii, 2] = 1 - chi2(1, www[iii, 5])
        }
        
        // Gamma test (H0: gamma(tau1) = gamma(tau3))
        ncols = rows(gamma)
        if (ncols >= 2*k & ss >= 2) {
            R_b = J(1, ncols, 0)
            R_b[1, 1] = 1
            R_b[1, k+1] = -1
            r_b = J(1, 1, 0)
            
            diff_b = R_b * gamma - r_b
            RCR_b = R_b * gamma_cov * R_b'
            RCR_b = RCR_b + 1e-12 * I(rows(RCR_b))
            www[iii, 6] = (nn-1) * diff_b' * luinv(RCR_b) * diff_b
            if (www[iii, 6] < 0) www[iii, 6] = abs(www[iii, 6])
            www[iii, 3] = 1 - chi2(1, www[iii, 6])
        }
        
        if (mod(iii, 100) == 0) {
            displayas("txt")
            printf("  Simulation %g of %g completed\n", iii, reps)
            displayflush()
        }
    }
    
    // Compute rejection rates
    real matrix results
    results = J(3, 4, 0)
    
    // Beta: rejection at 10%, 5%, 1%
    results[1, 1] = mean(www[., 1] :< 0.10)
    results[1, 2] = mean(www[., 1] :< 0.05)
    results[1, 3] = mean(www[., 1] :< 0.01)
    results[1, 4] = mean(www[., 4])
    
    // Phi
    results[2, 1] = mean(www[., 2] :< 0.10)
    results[2, 2] = mean(www[., 2] :< 0.05)
    results[2, 3] = mean(www[., 2] :< 0.01)
    results[2, 4] = mean(www[., 5])
    
    // Gamma
    results[3, 1] = mean(www[., 3] :< 0.10)
    results[3, 2] = mean(www[., 3] :< 0.05)
    results[3, 3] = mean(www[., 3] :< 0.01)
    results[3, 4] = mean(www[., 6])
    
    st_matrix("_sim_results", results)
}

end
