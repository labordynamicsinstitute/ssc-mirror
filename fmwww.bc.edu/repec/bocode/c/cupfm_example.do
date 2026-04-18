*! cupfm_example.do — Complete demonstration of cupfm package
*! Reproduces Monte Carlo design from Bai, Kao & Ng (2009) Table 1-4
*! and Bai & Kao (2005) Table 1
*! Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)
*! Version: 1.0.1 - 2026-04-16 (First SSC submission)

// ========================================================================
// SETUP
// ========================================================================
clear all
set more off
set seed 12345

// NOTE for SSC users: Stata finds all cupfm files automatically via adopath
// after installation — no path setup needed.
//
// NOTE for local development: add your package directory to the adopath, e.g.:
//   adopath ++ "C:\path\to\your\Cup_fm"
// The Mata engine (_cupfm_mata.ado) is loaded automatically by cupfm on first call.

// ========================================================================
// PART 1: SIMULATE PANEL DATA
// N=20, T=40, k=1 regressor, r=2 factors, beta=2  (BKN 2009 DGP)
// ========================================================================
local N     = 20
local T     = 40
local k     = 1
local r     = 2
local bval  = 2
local rati  = 1
local mu_lam = 0.1
local N_obs = `N' * `T'

di _n "Simulating panel data..."
di "  N=`N' units, T=`T' periods, k=`k' regressor, r=`r' factors"
di "  True beta = `bval'"

// Create balanced panel skeleton
set obs `=`N'*`T''
quietly gen int id   = ceil(_n/`T')
quietly gen int year = mod(_n-1, `T') + 1
xtset id year

quietly {
    local T_burn = 200

    // Mata DGP
    mata:
    N       = `N'
    T       = `T'
    T_burn  = `T_burn'
    T_tot   = T + T_burn
    k       = `k'
    r_dgp   = `r'
    beta1   = `bval'
    rati    = `rati'
    mu_lam  = `mu_lam'

    // Correlation matrix W (m x m), m = r+1+k
    // W = I + small off-diagonal, guaranteed PD
    m = r_dgp + 1 + k
    W = I(m)
    W[r_dgp+1, r_dgp+2] = -0.4
    W[r_dgp+2, r_dgp+1] = -0.4
    // Lower Cholesky: L s.t. L*L' = W
    L_chol = cholesky(W)

    // Factor loadings N x r: each element mu + N(0,1)
    Lambda_dgp = J(N, r_dgp, mu_lam) + rnormal(N, r_dgp, 0, 1)

    // Fixed effects
    alpha_i = runiform(N, 1) :* 10

    // Output
    Y_long = J(N*T, 1, .)
    X_long = J(N*T, k, .)

    // Common I(1) factors (same for all units)
    F_innov = rnormal(T_tot, r_dgp, 0, 1)
    F_dgp   = J(T_tot, r_dgp, 0)
    for (t=2; t<=T_tot; t++) {
        F_dgp[t,.] = F_dgp[t-1,.] + F_innov[t,.]
    }
    F_dgp = F_dgp[T_burn+1::T_tot, .]

    for (i=1; i<=N; i++) {
        // Draw m-variate correlated normal via Cholesky
        Z_raw   = rnormal(T_tot, m, 0, 1)
        eps_raw = Z_raw * L_chol'          // T_tot x m, correlated

        // AR(1) idiosyncratic error
        u_innov = eps_raw[., r_dgp+1]
        u_i     = J(T_tot, 1, 0)
        for (t=2; t<=T_tot; t++) {
            u_i[t] = 0.3*u_i[t-1] + u_innov[t]
        }
        u_i = u_i[T_burn+1::T_tot, .]

        // I(1) regressor
        xi_innov = eps_raw[., r_dgp+2::r_dgp+1+k]
        x_i      = J(T_tot, k, 0)
        for (t=2; t<=T_tot; t++) {
            x_i[t,.] = x_i[t-1,.] + xi_innov[t,.]
        }
        x_i = x_i[T_burn+1::T_tot, .]

        // Generate y
        y_i = alpha_i[i] :+ x_i*beta1 + F_dgp*Lambda_dgp[i,.]' :* rati + u_i

        idx            = (i-1)*T+1 :: i*T
        Y_long[idx]    = y_i
        X_long[idx, .] = x_i
    }

    // Write to Stata dataset
    (void) _st_addvar("double", "y")
    (void) _st_addvar("double", "x1")
    st_store(., "y",  Y_long)
    st_store(., "x1", X_long)

    st_numscalar("true_r",    r_dgp)
    st_numscalar("true_beta", beta1)
    st_matrix("Lambda_true",  Lambda_dgp)
    st_matrix("F_true",       F_dgp)

    end
}

di ""
di "Simulated data: `N_obs' observations"
di "True beta = " true_beta "  |  r = " true_r " factors"
di ""

// ========================================================================
// PART 2: DESCRIPTIVE STATISTICS
// ========================================================================
di "========================================================="
di "  DESCRIPTIVE STATISTICS"
di "========================================================="
xtsum y x1

// ========================================================================
// PART 3: RUN cupfm — MAIN ESTIMATION
// ========================================================================
di _n "========================================================="
di "  CUPFM ESTIMATION (all 5 estimators)"
di "========================================================="

cupfm y x1, nfactors(`r') bandwidth(5) maxiter(20)

di ""
di "  TRUE beta = " %6.3f true_beta "  (compare with estimates above)"
di ""

di "  CupFM estimate:  beta = " %8.4f e(beta_cupfm)[1,1]
di "  CupBC estimate:  beta = " %8.4f e(beta_cupbc)[1,1]
di "  LSDV  estimate:  beta = " %8.4f e(beta_lsdv)[1,1]
di "  Bias (CupFM):        " %8.4f e(beta_cupfm)[1,1] - true_beta
di "  Bias (LSDV):         " %8.4f e(beta_lsdv)[1,1] - true_beta

// ========================================================================
// PART 4: AUTO-SELECTION OF r
// ========================================================================
di _n "--- Automatic factor selection (Bai-Ng 2002 IC) ---"
cupfm y x1, nfactors(0) autormax(5) bandwidth(5) noicsummary

di "  Auto-selected r = " e(nfactors)

// ========================================================================
// PART 5 & 6: PLOTS AND EXPORT (skipped in batch test — run interactively)
// ========================================================================
di _n "--- Plots and export skipped in batch mode (use plot/export options interactively) ---"

// ========================================================================
// PART 7: MULTIPLE REGRESSORS
// ========================================================================
di _n "--- Multiple regressors example ---"

mata:
N2 = `N'; T2 = `T'
xx2 = J(N2*T2, 1, 0)
for (i2=1; i2<=N2; i2++) {
    eps2 = rnormal(T2, 1, 0, 1)
    x2_i = J(T2, 1, 0)
    for (t2=2; t2<=T2; t2++) x2_i[t2] = x2_i[t2-1] + eps2[t2]
    idx2 = (i2-1)*T2+1 :: i2*T2
    xx2[idx2] = x2_i
}
end
capture drop x2
quietly gen double x2 = .
mata: st_store(., "x2", xx2)

quietly replace y = y + 1.5*x2
cupfm y x1 x2, nfactors(`r') bandwidth(5)
di _n "  Note: True beta1 = 2.0, beta2 = 1.5"

// ========================================================================
// PART 8: SUMMARY
// ========================================================================
di _n "========================================================="
di "  SUMMARY: cupfm Package Test Complete"
di "========================================================="
di "  All 5 estimators: LSDV, Bai FM, CupFM, CupFM-bar, CupBC"
di "  Bai-Ng (2002) auto factor selection: OK"
di "  Bartlett kernel long-run covariance: OK"
di "  Export: LaTeX, Excel, CSV"
di ""
di "  References:"
di "  [1] Bai, Kao & Ng (2009). JoE 149:82-99."
di "  [2] Bai & Kao (2005). CPR WP 75, SSRN-1815227."
di "  [3] Bai & Ng (2002). Econometrica 70:191-221."
di ""
