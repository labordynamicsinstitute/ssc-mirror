*! rbfmvar_simulate — Monte Carlo simulation for RBFM-VAR
*! Reproduces the DGP from Section 5 of Chang (2000)
*! Version 1.0.0, February 2026
*! Author: Dr. Merwan Roudane
*! Email: merwanroudane920@gmail.com

capture program drop rbfmvar_simulate
program define rbfmvar_simulate, rclass
    version 14.0

    syntax , [                                    ///
        CASE(string)                              /// a b c
        NOBS(integer 150)                         /// sample size T
        REPS(integer 1000)                        /// Monte Carlo replications
        KERnel(string)                            /// kernel type
        SAVing(string)                            /// save dataset
        NOPRint                                   /// suppress table
        SEED(integer 12345)                       /// random seed
        ]

    *--------------------------------------------------------------------------
    * Defaults and validation
    *--------------------------------------------------------------------------
    if "`case'" == "" local case "a"
    local case = lower("`case'")
    if !inlist("`case'", "a", "b", "c") {
        di as error "case() must be {bf:a}, {bf:b}, or {bf:c}"
        exit 198
    }

    if "`kernel'" == "" local kernel "bartlett"
    local kernel = lower("`kernel'")

    if `nobs' < 30 {
        di as error "nobs() must be at least 30"
        exit 198
    }

    * DGP parameters from Chang (2000) Section 5
    if "`case'" == "a" {
        local rho1 = 1
        local rho2 = 0
        local case_label "Case A: (ρ₁,ρ₂) = (1,0) — Both I(2), no causality"
        local case_desc "Both Y₁ and Y₂ are I(2) with no cointegration"
    }
    else if "`case'" == "b" {
        local rho1 = 0.5
        local rho2 = 0
        local case_label "Case B: (ρ₁,ρ₂) = (0.5,0) — Y₁ I(1), Y₂ I(2), no causality"
        local case_desc "Y₁ is I(1), Y₂ is I(2), no Granger causality"
    }
    else {
        local rho1 = -0.3
        local rho2 = -0.15
        local case_label "Case C: (ρ₁,ρ₂) = (-0.3,-0.15) — Y₂ Granger-causes Y₁"
        local case_desc "Y₁ is I(1), Y₂ is I(2), Y₂ Granger-causes Y₁"
    }

    * Error covariance: Σ = [[1, 0.5], [0.5, 1.5]]
    local sig11 = 1
    local sig12 = 0.5
    local sig22 = 1.5

    *--------------------------------------------------------------------------
    * Display header
    *--------------------------------------------------------------------------
    if "`noprint'" == "" {
        di
        di as txt "{hline 78}"
        di as txt "{col 5}{bf:RBFM-VAR Monte Carlo Simulation}"
        di as txt "{col 5}{it:DGP from Chang (2000), Section 5, Eq. 24}"
        di as txt "{hline 78}"
        di
        di as txt "{col 5}`case_label'"
        di as txt "{col 5}`case_desc'"
        di
        di as txt "{col 5}Sample size (T):{col 30}" as res `nobs'
        di as txt "{col 5}Replications:{col 30}" as res `reps'
        di as txt "{col 5}Kernel:{col 30}" as res "`kernel'"
        di as txt "{col 5}Seed:{col 30}" as res `seed'
        di
        di as txt "{col 5}DGP: Δ²Y₁ₜ = ρ₁·ΔY₁,ₜ₋₁ + ρ₂·(Y₁,ₜ₋₁ - ΔY₂,ₜ₋₁) + ε₁ₜ"
        di as txt "{col 5}     Δ²Y₂ₜ = ε₂ₜ"
        di as txt "{col 5}     Σ = [[`sig11', `sig12'], [`sig12', `sig22']]"
        di
        di as txt "{col 5}Testing H₀: Y₂ does NOT Granger-cause Y₁"
        di
        di as txt "{hline 78}"
        di as txt "{col 5}Running simulations..."
    }

    *--------------------------------------------------------------------------
    * Load Mata engine
    *--------------------------------------------------------------------------
    capture findfile _rbfmvar_mata.ado
    if _rc {
        di as error "Required file _rbfmvar_mata.ado not found."
        exit 601
    }
    qui run `"`r(fn)'"'

    *--------------------------------------------------------------------------
    * Monte Carlo simulation via Mata
    *--------------------------------------------------------------------------
    set seed `seed'

    preserve
    clear

    * Run simulation
    mata: _rbfmvar_mc_run(`nobs', `reps', `rho1', `rho2', ///
        `sig11', `sig12', `sig22', "`kernel'")

    * Retrieve results
    local bias_ols_11   = r(bias_ols_11)
    local bias_ols_12   = r(bias_ols_12)
    local bias_ols_21   = r(bias_ols_21)
    local bias_ols_22   = r(bias_ols_22)
    local sd_ols_11     = r(sd_ols_11)
    local sd_ols_12     = r(sd_ols_12)
    local sd_ols_21     = r(sd_ols_21)
    local sd_ols_22     = r(sd_ols_22)

    local bias_rbfm_11  = r(bias_rbfm_11)
    local bias_rbfm_12  = r(bias_rbfm_12)
    local bias_rbfm_21  = r(bias_rbfm_21)
    local bias_rbfm_22  = r(bias_rbfm_22)
    local sd_rbfm_11    = r(sd_rbfm_11)
    local sd_rbfm_12    = r(sd_rbfm_12)
    local sd_rbfm_21    = r(sd_rbfm_21)
    local sd_rbfm_22    = r(sd_rbfm_22)

    local rej_ols_01    = r(rej_ols_01)
    local rej_ols_05    = r(rej_ols_05)
    local rej_ols_10    = r(rej_ols_10)

    local rej_rbfm_01   = r(rej_rbfm_01)
    local rej_rbfm_05   = r(rej_rbfm_05)
    local rej_rbfm_10   = r(rej_rbfm_10)

    restore

    *--------------------------------------------------------------------------
    * Display Table 1: Bias and Standard Deviations
    *--------------------------------------------------------------------------
    if "`noprint'" == "" {
        di
        di as txt "{hline 78}"
        di as txt "{col 5}{bf:Table 1: Bias and Standard Deviation of Π₁ Estimates}"
        di as txt "{col 5}{it:`case_label'}, T = `nobs'"
        di as txt "{hline 78}"
        di
        di as txt "{col 5}" _col(22) "OLS-VAR" _col(48) "RBFM-VAR"
        di as txt "{col 5}" _col(18) "Bias" _col(30) "S.D." _col(44) "Bias" _col(56) "S.D."
        di as txt "{col 5}{hline 60}"

        di as txt "{col 5}π₁₁" ///
           _col(15) as res %10.4f `bias_ols_11' ///
           _col(27) as res %10.4f `sd_ols_11' ///
           _col(41) as res %10.4f `bias_rbfm_11' ///
           _col(53) as res %10.4f `sd_rbfm_11'

        di as txt "{col 5}π₁₂" ///
           _col(15) as res %10.4f `bias_ols_12' ///
           _col(27) as res %10.4f `sd_ols_12' ///
           _col(41) as res %10.4f `bias_rbfm_12' ///
           _col(53) as res %10.4f `sd_rbfm_12'

        di as txt "{col 5}π₂₁" ///
           _col(15) as res %10.4f `bias_ols_21' ///
           _col(27) as res %10.4f `sd_ols_21' ///
           _col(41) as res %10.4f `bias_rbfm_21' ///
           _col(53) as res %10.4f `sd_rbfm_21'

        di as txt "{col 5}π₂₂" ///
           _col(15) as res %10.4f `bias_ols_22' ///
           _col(27) as res %10.4f `sd_ols_22' ///
           _col(41) as res %10.4f `bias_rbfm_22' ///
           _col(53) as res %10.4f `sd_rbfm_22'

        di as txt "{col 5}{hline 60}"

        *----------------------------------------------------------------------
        * Display Table 2: Size / Rejection Probabilities
        *----------------------------------------------------------------------
        di
        di as txt "{hline 78}"
        if "`case'" == "c" {
            di as txt "{col 5}{bf:Table 2: Rejection Probabilities (Power)}"
        }
        else {
            di as txt "{col 5}{bf:Table 2: Finite Sample Sizes (Rejection under H₀)}"
        }
        di as txt "{col 5}{it:`case_label'}, T = `nobs'"
        di as txt "{hline 78}"
        di
        di as txt "{col 5}" _col(25) "1%" _col(40) "5%" _col(55) "10%"
        di as txt "{col 5}{hline 60}"

        di as txt "{col 5}OLS-VAR (W_F)" ///
           _col(22) as res %10.4f `rej_ols_01' ///
           _col(37) as res %10.4f `rej_ols_05' ///
           _col(52) as res %10.4f `rej_ols_10'

        di as txt "{col 5}RBFM-VAR (W_F⁺)" ///
           _col(22) as res %10.4f `rej_rbfm_01' ///
           _col(37) as res %10.4f `rej_rbfm_05' ///
           _col(52) as res %10.4f `rej_rbfm_10'

        di as txt "{col 5}{hline 60}"
        di as txt "{col 5}Nominal size:" _col(22) "0.0100" _col(37) "0.0500" _col(52) "0.1000"
        di
        if "`case'" != "c" {
            di as txt "{col 5}Note: Closer to nominal = better size control."
            di as txt "{col 5}OLS-VAR typically shows severe size distortions."
        }
        else {
            di as txt "{col 5}Note: Higher = better power."
        }
        di as txt "{hline 78}"
    }

    *--------------------------------------------------------------------------
    * Return results
    *--------------------------------------------------------------------------
    return scalar reps       = `reps'
    return scalar nobs       = `nobs'

    return scalar bias_ols_11  = `bias_ols_11'
    return scalar bias_ols_12  = `bias_ols_12'
    return scalar bias_ols_21  = `bias_ols_21'
    return scalar bias_ols_22  = `bias_ols_22'
    return scalar sd_ols_11    = `sd_ols_11'
    return scalar sd_ols_12    = `sd_ols_12'
    return scalar sd_ols_21    = `sd_ols_21'
    return scalar sd_ols_22    = `sd_ols_22'

    return scalar bias_rbfm_11 = `bias_rbfm_11'
    return scalar bias_rbfm_12 = `bias_rbfm_12'
    return scalar bias_rbfm_21 = `bias_rbfm_21'
    return scalar bias_rbfm_22 = `bias_rbfm_22'
    return scalar sd_rbfm_11   = `sd_rbfm_11'
    return scalar sd_rbfm_12   = `sd_rbfm_12'
    return scalar sd_rbfm_21   = `sd_rbfm_21'
    return scalar sd_rbfm_22   = `sd_rbfm_22'

    return scalar rej_ols_01   = `rej_ols_01'
    return scalar rej_ols_05   = `rej_ols_05'
    return scalar rej_ols_10   = `rej_ols_10'
    return scalar rej_rbfm_01  = `rej_rbfm_01'
    return scalar rej_rbfm_05  = `rej_rbfm_05'
    return scalar rej_rbfm_10  = `rej_rbfm_10'

    return local  case         "`case'"
    return local  kernel       "`kernel'"
    return local  cmd          "rbfmvar_simulate"
end


// ========================================================================
// Mata: Monte Carlo simulation engine
// ========================================================================

capture mata: mata drop _rbfmvar_mc_run()
capture mata: mata drop _rbfmvar_mc_dgp()
capture mata: mata drop _rbfmvar_mc_wald_ols()

version 14.0
mata:
mata set matastrict on

// ========================================================================
// DGP: Generate one replication of the bivariate process (Eq. 24)
// ========================================================================

void _rbfmvar_mc_dgp(
    real scalar T,
    real scalar rho1,
    real scalar rho2,
    real matrix Sigma,
    real matrix Y_out)
{
    real matrix eps, L_chol
    real scalar t
    real colvector y1, y2, dy1, dy2, d2y1, d2y2

    // Cholesky for correlated errors
    L_chol = cholesky(Sigma)

    // Generate i.i.d. N(0, Sigma) errors
    eps = rnormal(T + 50, 2, 0, 1) * L_chol'

    // Initialize
    y1  = J(T + 50, 1, 0)
    y2  = J(T + 50, 1, 0)
    dy1 = J(T + 50, 1, 0)
    dy2 = J(T + 50, 1, 0)

    // Generate process
    for (t = 3; t <= T + 50; t++) {
        // Δ²Y₂ₜ = ε₂ₜ  =>  ΔY₂ₜ = ΔY₂,ₜ₋₁ + ε₂ₜ
        dy2[t] = dy2[t-1] + eps[t, 2]
        y2[t]  = y2[t-1] + dy2[t]

        // Δ²Y₁ₜ = ρ₁·ΔY₁,ₜ₋₁ + ρ₂·(Y₁,ₜ₋₁ - ΔY₂,ₜ₋₁) + ε₁ₜ
        d2y1 = rho1 * dy1[t-1] + rho2 * (y1[t-1] - dy2[t-1]) + eps[t, 1]
        dy1[t] = dy1[t-1] + d2y1
        y1[t]  = y1[t-1] + dy1[t]
    }

    // Trim burn-in
    Y_out = (y1[51::(T+50)], y2[51::(T+50)])
}


// ========================================================================
// OLS Wald statistic for Granger non-causality (for comparison)
// ========================================================================

void _rbfmvar_mc_wald_ols(
    real matrix F_ols,
    real matrix Sigma_e,
    real matrix X,
    real scalar T,
    real scalar n,
    real scalar ncols_z,
    real scalar wald_stat)
{
    real matrix R, XpXinv, V_mat, V_inv
    real colvector r_vec, vecF, Rf_r
    real scalar np_total, j

    np_total = cols(X)
    R = J(2, n * np_total, 0)
    r_vec = J(2, 1, 0)

    // Restriction: F[1, ncols_z + 2] = 0  (Π₁: effect of y2 on y1 equation)
    // vec(F') position for F[eq,reg] = (eq-1)*np_total + reg
    j = ncols_z + 2
    R[1, (1-1)*np_total + j] = 1

    // Restriction: F[1, ncols_z + n + 2] = 0  (Π₂: effect of y2 on y1 equation)
    j = ncols_z + n + 2
    R[2, (1-1)*np_total + j] = 1

    vecF = vec(F_ols')
    Rf_r = R * vecF - r_vec

    XpXinv = invsym(cross(X, X))
    V_mat = R * (Sigma_e # XpXinv) * R'
    V_inv = invsym(V_mat)

    wald_stat = Rf_r' * V_inv * Rf_r
}


// ========================================================================
// Main MC runner
// ========================================================================

void _rbfmvar_mc_run(
    real scalar T_obs,
    real scalar n_reps,
    real scalar rho1,
    real scalar rho2,
    real scalar sig11,
    real scalar sig12,
    real scalar sig22,
    string scalar kernel)
{
    real matrix Sigma, Y_sim, Y, Z, W, X
    real matrix F_ols, F_plus, E_hat, V_hat
    real matrix Omega_ev, Omega_vv, Delta_vdw, dW
    real matrix Gamma_plus, A_plus, Sigma_e
    real scalar bw, r, T_eff, n, ncols_z
    real scalar wald_ols, wald_rbfm

    // True Π₁ and Π₂ values from DGP (Eq. 24):
    //   Δ²y₁ₜ = ρ₁·Δy₁,ₜ₋₁ + ρ₂·(y₁,ₜ₋₁ - Δy₂,ₜ₋₁) + ε₁ₜ
    //         = ρ₁·Δy₁,ₜ₋₁ + (-ρ₂)·Δy₂,ₜ₋₁ + ρ₂·y₁,ₜ₋₁ + ε₁ₜ
    // So in ECM form y_t = Π₁·Δy_{t-1} + Π₂·y_{t-1} + ε_t:
    //   Π₁ = [[ρ₁, -ρ₂], [0, 0]]  and  Π₂ = [[ρ₂, 0], [0, 0]]
    real matrix Pi1_true
    Pi1_true = (rho1, -rho2 \ 0, 0)

    Sigma = (sig11, sig12 \ sig12, sig22)
    n = 2

    // Storage for estimates
    real matrix Pi1_ols_store, Pi1_rbfm_store
    real colvector wald_ols_store, wald_rbfm_store
    Pi1_ols_store  = J(n_reps, 4, 0)
    Pi1_rbfm_store = J(n_reps, 4, 0)
    wald_ols_store  = J(n_reps, 1, 0)
    wald_rbfm_store = J(n_reps, 1, 0)

    real scalar p_lags, valid_reps
    p_lags = 1
    valid_reps = 0

    for (r = 1; r <= n_reps; r++) {
        // Generate DGP
        _rbfmvar_mc_dgp(T_obs, rho1, rho2, Sigma, Y_sim)

        // ECM reparameterize
        _rbfm_ecm_reparameterize(Y_sim, p_lags, Y, Z, W)
        T_eff = rows(Y)
        X = (Z, W)
        ncols_z = cols(Z)

        // OLS estimation
        _rbfm_ols_var(Y, X, Z, W, F_ols, E_hat)

        // Construct v_hat
        _rbfm_construct_vhat(Y_sim, p_lags, F_ols, X, V_hat)

        // Bandwidth
        bw = _rbfm_andrews_bandwidth(V_hat, kernel)

        // LRV
        _rbfm_kernel_lrv(E_hat, V_hat, kernel, bw, Omega_ev, Omega_vv)

        // One-sided LRV
        dW = W[2::T_eff, .] - W[1::(T_eff-1), .]
        dW = (J(1, cols(W), 0) \ dW)
        _rbfm_kernel_olrv(V_hat, dW, kernel, bw, Delta_vdw)

        // RBFM correction
        _rbfm_correct(Y, Z, W, X, E_hat, V_hat, Omega_ev, Omega_vv, Delta_vdw, T_eff, F_plus, Gamma_plus, A_plus)

        // Residual covariance
        Sigma_e = (E_hat' * E_hat) / T_eff

        // Extract Π₁ estimates (cols ncols_z+1 to ncols_z+n)
        real matrix Pi1_ols_r, Pi1_rbfm_r
        Pi1_ols_r  = F_ols[., (ncols_z+1)::(ncols_z+n)]
        Pi1_rbfm_r = F_plus[., (ncols_z+1)::(ncols_z+n)]

        // Store: vec(Π₁) = (π₁₁, π₂₁, π₁₂, π₂₂)
        Pi1_ols_store[r, .]  = (Pi1_ols_r[1,1], Pi1_ols_r[1,2], Pi1_ols_r[2,1], Pi1_ols_r[2,2])
        Pi1_rbfm_store[r, .] = (Pi1_rbfm_r[1,1], Pi1_rbfm_r[1,2], Pi1_rbfm_r[2,1], Pi1_rbfm_r[2,2])

        // Wald tests
        _rbfmvar_mc_wald_ols(F_ols, Sigma_e, X, T_eff, n, ncols_z, wald_ols)
        wald_ols_store[r] = wald_ols

        // RBFM Wald — reuse the same R matrix structure
        real scalar wald_tmp, wald_p_tmp, wald_df_tmp
        real matrix R_gc
        real colvector r_gc
        real scalar j_col, np_total

        np_total = cols(X)
        R_gc = J(2, n * np_total, 0)
        r_gc = J(2, 1, 0)

        j_col = ncols_z + 2
        R_gc[1, (1-1)*np_total + j_col] = 1
        j_col = ncols_z + n + 2
        R_gc[2, (1-1)*np_total + j_col] = 1

        _rbfm_wald_test(R_gc, r_gc, F_plus, Sigma_e, X, T_eff, wald_tmp, wald_p_tmp, wald_df_tmp)
        wald_rbfm_store[r] = wald_tmp

        valid_reps = valid_reps + 1
    }

    // Compute bias and s.d.
    real rowvector true_vals, mean_ols, mean_rbfm, sd_ols, sd_rbfm, bias_ols, bias_rbfm
    true_vals = (Pi1_true[1,1], Pi1_true[1,2], Pi1_true[2,1], Pi1_true[2,2])

    mean_ols  = mean(Pi1_ols_store)
    mean_rbfm = mean(Pi1_rbfm_store)

    bias_ols  = mean_ols - true_vals
    bias_rbfm = mean_rbfm - true_vals

    sd_ols  = J(1, 4, 0)
    sd_rbfm = J(1, 4, 0)
    for (r = 1; r <= 4; r++) {
        sd_ols[r]  = sqrt(variance(Pi1_ols_store[., r]))
        sd_rbfm[r] = sqrt(variance(Pi1_rbfm_store[., r]))
    }

    // Rejection rates (χ²_2 critical values)
    real scalar cv01, cv05, cv10
    cv01 = invchi2(2, 0.99)  // 9.210
    cv05 = invchi2(2, 0.95)  // 5.991
    cv10 = invchi2(2, 0.90)  // 4.605

    real scalar rej_ols_01, rej_ols_05, rej_ols_10
    real scalar rej_rbfm_01, rej_rbfm_05, rej_rbfm_10

    rej_ols_01  = mean(wald_ols_store :> cv01)
    rej_ols_05  = mean(wald_ols_store :> cv05)
    rej_ols_10  = mean(wald_ols_store :> cv10)

    rej_rbfm_01 = mean(wald_rbfm_store :> cv01)
    rej_rbfm_05 = mean(wald_rbfm_store :> cv05)
    rej_rbfm_10 = mean(wald_rbfm_store :> cv10)

    // Post to Stata
    st_numscalar("r(bias_ols_11)", bias_ols[1])
    st_numscalar("r(bias_ols_12)", bias_ols[2])
    st_numscalar("r(bias_ols_21)", bias_ols[3])
    st_numscalar("r(bias_ols_22)", bias_ols[4])
    st_numscalar("r(sd_ols_11)", sd_ols[1])
    st_numscalar("r(sd_ols_12)", sd_ols[2])
    st_numscalar("r(sd_ols_21)", sd_ols[3])
    st_numscalar("r(sd_ols_22)", sd_ols[4])

    st_numscalar("r(bias_rbfm_11)", bias_rbfm[1])
    st_numscalar("r(bias_rbfm_12)", bias_rbfm[2])
    st_numscalar("r(bias_rbfm_21)", bias_rbfm[3])
    st_numscalar("r(bias_rbfm_22)", bias_rbfm[4])
    st_numscalar("r(sd_rbfm_11)", sd_rbfm[1])
    st_numscalar("r(sd_rbfm_12)", sd_rbfm[2])
    st_numscalar("r(sd_rbfm_21)", sd_rbfm[3])
    st_numscalar("r(sd_rbfm_22)", sd_rbfm[4])

    st_numscalar("r(rej_ols_01)", rej_ols_01)
    st_numscalar("r(rej_ols_05)", rej_ols_05)
    st_numscalar("r(rej_ols_10)", rej_ols_10)
    st_numscalar("r(rej_rbfm_01)", rej_rbfm_01)
    st_numscalar("r(rej_rbfm_05)", rej_rbfm_05)
    st_numscalar("r(rej_rbfm_10)", rej_rbfm_10)
}


end
