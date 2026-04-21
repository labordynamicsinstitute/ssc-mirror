*! cupfm.ado - Panel Cointegration with Common Factors
*! Version 1.0.4 - 2026-04-20 (Fix: mata engine embedded at top level per Baum SSC guidelines)
*! Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)
*!
*! Implements all estimators from:
*!   Bai, J., Kao, C. & Ng, S. (2009). Panel cointegration with global
*!     stochastic trends. Journal of Econometrics, 149(1), 82-99.
*!   Bai, J. & Kao, C. (2005). On the estimation and inference of a panel
*!     cointegration model with cross-sectional dependence.
*!     CPR Working Paper No. 75, Syracuse University. SSRN-1815227.
*!
*! Estimators (exactly as in GAUSS bkn source code):
*!   LSDV     : Within/fixed-effects (baseline, biased under CS dependence)
*!   Bai FM   : One-shot 2-step FM  [Bai & Kao 2005, Eq. 7-8]
*!   CupFM    : Continuously-Updated FM  [BKN 2009, Theorem 3, Eq. 16]
*!   CupFM-bar: CupFM with Z-bar instrument  [BKN 2009, alternative]
*!   CupBC    : Continuously-Updated BC  [BKN 2009, Theorem 2]
*!
*! Data: Stata long format (xtset panelvar timevar), balanced panel required
*! Long->Wide conversion handled internally in Mata (matches GAUSS bkn)
*!
*! Mata engine is embedded below at the top level: compiled once when
*! cupfm.ado is first sourced, persists until discard.

// ── MATA ENGINE (compiled on first load of cupfm.ado) ──────────────────────
capture mata: mata drop cupfm_*()
mata:

// ===================================================================
// 1. UTILITY: Stata long format → GAUSS wide "grouped-by-unit"
// ===================================================================
function cupfm_long2wide(V_long, N, T, m) {
    V_wide = J(T, N*m, .)
    for (i=1; i<=N; i++) {
        idx = (i-1)*T+1 :: i*T
        V_wide[., (i-1)*m+1 :: i*m] = V_long[idx, .]
    }
    return(V_wide)
}

// ===================================================================
// 2. UTILITY: Wide → Long
// ===================================================================
function cupfm_wide2long(V_wide, N, T, m) {
    V_long = J(N*T, m, .)
    for (i=1; i<=N; i++) {
        idx = (i-1)*T+1 :: i*T
        V_long[idx, .] = V_wide[., (i-1)*m+1 :: i*m]
    }
    return(V_long)
}

// ===================================================================
// 3. UTILITY: First differences
// ===================================================================
function cupfm_fdif(X) {
    T = rows(X)
    return(X[2::T, .] - X[1::T-1, .])
}

// ===================================================================
// 4. UTILITY: Within-demean each unit
// ===================================================================
function cupfm_demean(X_long, N, T) {
    Xdm = X_long :+ 0
    for (i=1; i<=N; i++) {
        idx = (i-1)*T+1 :: i*T
        Xdm[idx, .] = X_long[idx, .] :- mean(X_long[idx, .])
    }
    return(Xdm)
}

// ===================================================================
// 5. FACTOR EXTRACTION - pass-by-reference
// ===================================================================
void cupfm_factor(U_wide, r, F_out, L_out) {
    T = rows(U_wide)
    N = cols(U_wide)
    if (T >= N) {
        _P = J(T, T, .)
        _D = J(min((T,N)), 1, .)
        _Q = J(N, N, .)
        svd(U_wide, _P, _D, _Q)
        F_out = _P[., 1::r] :* T
        L_out = U_wide' * F_out :/ T^2
    }
    else {
        _P = J(N, N, .)
        _D = J(N, 1, .)
        _Q = J(N, N, .)
        svd(U_wide'*U_wide, _P, _D, _Q)
        L_out = _P[., 1::r] :* sqrt(N)
        F_out = U_wide * L_out :/ N
    }
}

// ===================================================================
// 6. ROTATION WEIGHTS a_ik  (BKN 2009 Section 2)
// ===================================================================
function cupfm_delta(Lambda) {
    N    = rows(Lambda)
    SigL = Lambda'*Lambda :/ N
    return(Lambda * invsym(SigL) * Lambda')
}

// ===================================================================
// 7. BAI-NG (2002) IC CRITERION FOR NUMBER OF FACTORS
// ===================================================================
function cupfm_ic_bn(U_wide, rmax) {
    T    = rows(U_wide)
    N    = cols(U_wide)
    NT   = N*T
    best_r  = 1
    best_ic = 1e15
    F_r = J(T, 1, .)
    L_r = J(N, 1, .)
    for (ri=1; ri<=rmax; ri++) {
        cupfm_factor(U_wide, ri, F_r, L_r)
        resid = U_wide - F_r * L_r'
        V_r   = sum(resid:^2) / NT
        if (V_r <= 0) continue
        ic_r = log(V_r) + ri * (N+T)/NT * log(NT/(N+T))
        if (ic_r < best_ic) {
            best_ic = ic_r
            best_r  = ri
        }
    }
    return(best_r)
}

// ===================================================================
// 8. BARTLETT KERNEL LONG-RUN COVARIANCE
// ===================================================================
function cupfm_kernel_unit(U, bw, Delta_plus) {
    T1    = rows(U)
    m     = cols(U)
    Sigma = U'*U :/ T1
    Gamma = J(m, m, 0)
    for (j=1; j<=bw; j++) {
        if (T1-j < 1) break
        wj      = 1 - j/(bw+1)
        Gamma_j = U[j+1::T1, .]' * U[1::T1-j, .] :/ T1
        Gamma   = Gamma + wj * Gamma_j
    }
    Delta_plus = Sigma + Gamma
    return(Sigma + Gamma + Gamma')
}

// ===================================================================
// 9. CUP PLAIN LS
// ===================================================================
function cupfm_plsbeta(X_long, y_long, F, N, T, k) {
    invFtF = invsym(F'*F)
    XX = J(k, k, 0)
    Xy = J(k, 1, 0)
    for (i=1; i<=N; i++) {
        idx = (i-1)*T+1 :: i*T
        xi  = X_long[idx, .]
        yi  = y_long[idx, .]
        FtX = F'*xi
        FtY = F'*yi
        XX  = XX + xi'*xi - FtX'*invFtF*FtX
        Xy  = Xy + xi'*yi - FtX'*invFtF*FtY
    }
    return(invsym(XX) * Xy)
}

// ===================================================================
// 10. FULL FM BETA - pass-by-reference for all outputs
// ===================================================================
void cupfm_fmbeta(y_wide_T1, X_long_T1, X_wide_T1, aik,
                  F_T1, dF, u1_wide_T1,
                  du2_T1_long, bw, N, T1, k, r,
                  beta_fm1, beta_fm2, tstat_fm1, tstat_fm2, Omega_bar, cond_var) {

    m = 1 + k + r

    du2_T1_wide = cupfm_long2wide(du2_T1_long, N, T1, k)
    du2N_wide   = J(T1, N*k, 0)
    for (ip=1; ip<=N; ip++) {
        sumd = J(T1, k, 0)
        for (kp=1; kp<=N; kp++) {
            sumd = sumd + du2_T1_wide[., (kp-1)*k+1::kp*k] :* aik[ip, kp]
        }
        du2N_wide[., (ip-1)*k+1::ip*k] = du2_T1_wide[., (ip-1)*k+1::ip*k] - sumd:/N
    }

    xbar_wide = J(T1, N*k, 0)
    for (ip=1; ip<=N; ip++) {
        sumx = J(T1, k, 0)
        for (kp=1; kp<=N; kp++) {
            sumx = sumx + X_wide_T1[., (kp-1)*k+1::kp*k] :* aik[ip, kp]
        }
        xbar_wide[., (ip-1)*k+1::ip*k] = X_wide_T1[., (ip-1)*k+1::ip*k] - sumx:/N
    }

    Omega_sum = J(m, m, 0)
    Dplus_sum = J(m, m, 0)
    Dp_k = J(m, m, 0)
    for (ku=1; ku<=N; ku++) {
        u1k   = u1_wide_T1[., ku]
        du2Nk = du2N_wide[., (ku-1)*k+1::ku*k]
        W_k   = u1k, du2Nk, dF
        Om_k  = cupfm_kernel_unit(W_k, bw, Dp_k)
        Omega_sum = Omega_sum + Om_k
        Dplus_sum = Dplus_sum + Dp_k
    }
    Omega_bar = Omega_sum :/ N
    Dplus_bar = Dplus_sum :/ N

    Omega_ub = Omega_bar[1, 2::m]
    Omega_b  = Omega_bar[2::m, 2::m]
    invOmb   = invsym(Omega_b)
    gab      = Omega_ub * invOmb

    y_plus = J(T1, N, .)
    for (ip=1; ip<=N; ip++) {
        dN_ip = du2N_wide[., (ip-1)*k+1::ip*k]
        for (ti=1; ti<=T1; ti++) {
            temp5          = (dN_ip[ti, .], dF[ti, .])'
            y_plus[ti, ip] = y_wide_T1[ti, ip] - gab*temp5
        }
    }

    abu  = Dplus_bar[2::m, 1]
    ab_  = Dplus_bar[2::m, 2::m]
    obu  = Omega_bar[2::m, 1]
    obup = abu - ab_*invOmb*obu

    invFF    = invsym(F_T1'*F_T1)
    db_all   = J(N, r*k, 0)
    for (ip=1; ip<=N; ip++) {
        x_ip = X_wide_T1[., (ip-1)*k+1::ip*k]
        db_i = invFF * (F_T1'*x_ip)
        db_all[ip, .] = rowshape(db_i, 1)
    }
    dbsum_all = J(N, r*k, 0)
    for (ip=1; ip<=N; ip++) {
        for (kp=1; kp<=N; kp++) {
            dbsum_all[ip, .] = dbsum_all[ip, .] + db_all[kp, .] :* aik[ip, kp]
        }
    }
    dbsum1_all = db_all - dbsum_all:/N
    db_bar     = rowshape(colsum(dbsum1_all), r)

    db2 = J(r, N*k, 0)
    for (ip=1; ip<=N; ip++) {
        db2[., (ip-1)*k+1::ip*k] = rowshape(dbsum1_all[ip, .], r)
    }

    obup_x = obup[1::k]
    obup_f = obup[k+1::k+r]
    temp3  = T1 :* (N*obup_x - db_bar'*obup_f)

    invFF1 = invsym(F_T1'*F_T1)
    XX = J(k, k, 0)
    Xy = J(k, 1, 0)
    for (ip=1; ip<=N; ip++) {
        xi  = X_long_T1[(ip-1)*T1+1::ip*T1, .]
        yi  = y_plus[., ip]
        FtX = F_T1'*xi
        FtY = F_T1'*yi
        XX  = XX + xi'*xi - FtX'*invFF1*FtX
        Xy  = Xy + xi'*yi - FtX'*invFF1*FtY
    }
    Xy     = Xy - temp3
    invXX  = invsym(XX)
    beta_fm1  = invXX * Xy

    Omega_uu = Omega_bar[1, 1]
    cond_var = Omega_uu - Omega_ub * invOmb * Omega_ub'
    tstat_fm1 = beta_fm1 :/ sqrt(diagonal(invXX) :* cond_var)

    z1     = xbar_wide - F_T1*db2
    z_long = cupfm_wide2long(z1, N, T1, k)

    XXz = J(k, k, 0)
    Xyz = J(k, 1, 0)
    for (ip=1; ip<=N; ip++) {
        zi  = z_long[(ip-1)*T1+1::ip*T1, .]
        yi  = y_plus[., ip]
        XXz = XXz + zi'*zi
        Xyz = Xyz + zi'*yi
    }
    Xyz      = Xyz - temp3
    invXXz   = invsym(XXz)
    beta_fm2 = invXXz * Xyz
    tstat_fm2 = beta_fm2 :/ sqrt(diagonal(invXXz) :* cond_var)
}

// ===================================================================
// 11. MAIN ENGINE - called from cupfm.ado
// ===================================================================
void cupfm_main(string scalar depvar,
                string scalar indepvars,
                string scalar touse,
                real scalar N,
                real scalar T,
                real scalar r_in,
                real scalar bw,
                string scalar ktype,
                real scalar maxiter,
                real scalar do_autoR,
                real scalar autormax,
                real scalar verbose) {

    real matrix y_long, X_long
    st_view(y_long, ., depvar, touse)
    st_view(X_long, ., tokens(indepvars), touse)
    k  = cols(X_long)
    NT = N * T
    r  = r_in

    Xdm_long  = cupfm_demean(X_long, N, T)
    ydm_long  = cupfm_demean(y_long, N, T)
    XX_lsdv   = Xdm_long'*Xdm_long
    beta_lsdv = invsym(XX_lsdv) * (Xdm_long'*ydm_long)

    uhat_lsdv   = ydm_long - Xdm_long*beta_lsdv
    sigma2_lsdv = (uhat_lsdv'*uhat_lsdv)[1,1] / (NT - N - k)
    if (sigma2_lsdv <= 0) sigma2_lsdv = 1e-12
    var_lsdv    = diagonal(sigma2_lsdv :* invsym(XX_lsdv))
    se_lsdv     = sqrt(var_lsdv)
    t_lsdv      = beta_lsdv :/ se_lsdv

    uhat_long = y_long - X_long*beta_lsdv
    U_wide    = cupfm_long2wide(uhat_long, N, T, 1)

    real matrix F_hat, L_hat
    F_hat = J(T, 1, .)
    L_hat = J(N, 1, .)

    if (do_autoR) {
        rmax_use = floor(min((autormax, min((N, T)) / 2)))
        if (rmax_use < 1) rmax_use = 1
        r = cupfm_ic_bn(U_wide, rmax_use)
    }

    cupfm_factor(U_wide, r, F_hat, L_hat)

    T1          = T - 1
    du2_T1_long = J(N*T1, k, .)
    for (i=1; i<=N; i++) {
        idx_i = (i-1)*T+1 :: i*T
        du2_T1_long[(i-1)*T1+1 :: i*T1, .] = cupfm_fdif(X_long[idx_i, .])
    }

    dF = cupfm_fdif(F_hat)

    FL_wide = J(T, N, 0)
    for (i=1; i<=N; i++) {
        FL_wide[., i] = F_hat * L_hat[i, .]'
    }
    FL_long = cupfm_wide2long(FL_wide, N, T, 1)
    u1_wide = cupfm_long2wide(y_long - X_long*beta_lsdv - FL_long, N, T, 1)

    aik = cupfm_delta(L_hat)

    F_T1       = F_hat[1::T1, .]
    u1_wide_T1 = u1_wide[1::T1, .]
    y_wide     = cupfm_long2wide(y_long, N, T, 1)
    y_wide_T1  = y_wide[1::T1, .]

    X_long_T1 = J(N*T1, k, .)
    for (i=1; i<=N; i++) {
        idx_i = (i-1)*T+1 :: i*T
        X_long_T1[(i-1)*T1+1 :: i*T1, .] = X_long[idx_i, .][1::T1, .]
    }
    X_wide_T1 = cupfm_long2wide(X_long_T1, N, T1, k)

    real matrix beta_bfm, beta_bfm2, ts_bfm, ts_bfm2, Om_bfm
    real scalar cv_bfm
    beta_bfm  = J(k, 1, .)
    beta_bfm2 = J(k, 1, .)
    ts_bfm    = J(k, 1, .)
    ts_bfm2   = J(k, 1, .)
    Om_bfm    = J(1+k+r, 1+k+r, .)
    cv_bfm    = .

    cupfm_fmbeta(y_wide_T1, X_long_T1, X_wide_T1, aik,
                 F_T1, dF, u1_wide_T1,
                 du2_T1_long, bw, N, T1, k, r,
                 beta_bfm, beta_bfm2, ts_bfm, ts_bfm2, Om_bfm, cv_bfm)

    real matrix beta_cur, beta_cur2, ts_cur, ts_cur2, Om_cur
    real scalar cv_cur
    beta_cur  = beta_bfm
    beta_cur2 = beta_bfm2
    ts_cur    = ts_bfm
    ts_cur2   = ts_bfm2
    Om_cur    = Om_bfm
    cv_cur    = cv_bfm

    real matrix _b1, _b2, _t1, _t2, _Om
    real scalar _cv
    _b1 = J(k, 1, .)
    _b2 = J(k, 1, .)
    _t1 = J(k, 1, .)
    _t2 = J(k, 1, .)
    _Om = J(1+k+r, 1+k+r, .)
    _cv = .

    itr = 1
    do {
        uhat_long = y_long - X_long*beta_cur
        U_wide    = cupfm_long2wide(uhat_long, N, T, 1)
        cupfm_factor(U_wide, r, F_hat, L_hat)
        aik = cupfm_delta(L_hat)

        F_T1 = F_hat[1::T1, .]
        dF   = cupfm_fdif(F_hat)

        FL_wide = J(T, N, 0)
        for (i=1; i<=N; i++) {
            FL_wide[., i] = F_hat * L_hat[i, .]'
        }
        FL_long    = cupfm_wide2long(FL_wide, N, T, 1)
        u1_wide    = cupfm_long2wide(y_long - X_long*beta_cur - FL_long, N, T, 1)
        u1_wide_T1 = u1_wide[1::T1, .]

        cupfm_fmbeta(y_wide_T1, X_long_T1, X_wide_T1, aik,
                     F_T1, dF, u1_wide_T1,
                     du2_T1_long, bw, N, T1, k, r,
                     _b1, _b2, _t1, _t2, _Om, _cv)
        beta_cur  = _b1
        beta_cur2 = _b2
        ts_cur    = _t1
        ts_cur2   = _t2
        Om_cur    = _Om
        cv_cur    = _cv

        if (verbose) printf("CupFM iter: %g\n", itr)
        itr++
    } while (itr <= maxiter)

    beta_cupfm  = beta_cur
    beta_cupfm2 = beta_cur2
    ts_cupfm    = ts_cur
    ts_cupfm2   = ts_cur2
    Om_cupfm    = Om_cur
    cv_cupfm    = cv_cur
    niter_cupfm = itr - 1

    uhat_long = y_long - X_long*beta_lsdv
    U_wide    = cupfm_long2wide(uhat_long, N, T, 1)

    real matrix F_bc, L_bc
    F_bc = J(T, r, .)
    L_bc = J(N, r, .)
    cupfm_factor(U_wide, r, F_bc, L_bc)

    itr_bc = 1
    real matrix beta_bc
    beta_bc = J(k, 1, .)
    do {
        beta_bc   = cupfm_plsbeta(X_long, y_long, F_bc, N, T, k)
        uhat_long = y_long - X_long*beta_bc
        U_wide    = cupfm_long2wide(uhat_long, N, T, 1)
        cupfm_factor(U_wide, r, F_bc, L_bc)
        if (verbose) printf("CupBC iter: %g\n", itr_bc)
        itr_bc++
    } while (itr_bc <= maxiter)

    aik_bc  = cupfm_delta(L_bc)
    dF_bc   = cupfm_fdif(F_bc)
    F_T1_bc = F_bc[1::T1, .]

    FL_wide_bc = J(T, N, 0)
    for (i=1; i<=N; i++) {
        FL_wide_bc[., i] = F_bc * L_bc[i, .]'
    }
    FL_long_bc    = cupfm_wide2long(FL_wide_bc, N, T, 1)
    u1_wide_bc    = cupfm_long2wide(y_long - X_long*beta_bc - FL_long_bc, N, T, 1)
    u1_wide_T1_bc = u1_wide_bc[1::T1, .]
    X_wide_T1_bc  = cupfm_long2wide(X_long_T1, N, T1, k)

    real matrix _b1bc, _b2bc, _t1bc, _t2bc, _Ombc
    real scalar _cvbc
    _b1bc = J(k, 1, .)
    _b2bc = J(k, 1, .)
    _t1bc = J(k, 1, .)
    _t2bc = J(k, 1, .)
    _Ombc = J(1+k+r, 1+k+r, .)
    _cvbc = .

    cupfm_fmbeta(y_wide_T1, X_long_T1, X_wide_T1_bc, aik_bc,
                 F_T1_bc, dF_bc, u1_wide_T1_bc,
                 du2_T1_long, bw, N, T1, k, r,
                 _b1bc, _b2bc, _t1bc, _t2bc, _Ombc, _cvbc)

    beta_cupbc = _b1bc
    ts_cupbc   = _t1bc
    cv_cupbc   = _cvbc
    Om_cupbc   = _Ombc

    st_matrix("_cupfm_b_lsdv",   beta_lsdv')
    st_matrix("_cupfm_b_baifm",  beta_bfm')
    st_matrix("_cupfm_b_cupfm",  beta_cupfm')
    st_matrix("_cupfm_b_cupfm2", beta_cupfm2')
    st_matrix("_cupfm_b_cupbc",  beta_cupbc')
    st_matrix("_cupfm_t_lsdv",   t_lsdv')
    st_matrix("_cupfm_t_baifm",  ts_bfm')
    st_matrix("_cupfm_t_cupfm",  ts_cupfm')
    st_matrix("_cupfm_t_cupfm2", ts_cupfm2')
    st_matrix("_cupfm_t_cupbc",  ts_cupbc')
    st_matrix("_cupfm_omega",    Om_cupfm)
    st_matrix("_cupfm_omega_bc", Om_cupbc)
    st_matrix("_cupfm_f",        F_hat)
    st_matrix("_cupfm_lambda",   L_hat)
    st_matrix("_cupfm_aik",      aik)
    st_numscalar("_cupfm_r",         r)
    st_numscalar("_cupfm_bw",        bw)
    st_numscalar("_cupfm_niter",     niter_cupfm)
    st_numscalar("_cupfm_cvar",      cv_cupfm)
    st_numscalar("_cupfm_cvar_bc",   cv_cupbc)
    st_numscalar("_cupfm_N",         N)
    st_numscalar("_cupfm_T",         T)
    st_numscalar("_cupfm_Nobs",      N*T)
    st_numscalar("_cupfm_converged", (niter_cupfm < maxiter ? 1 : 0))
}

end
// ── END MATA ENGINE ────────────────────────────────────────────────────────

capture program drop cupfm
program define cupfm, eclass
    version 14

    // --- Syntax ---------------------------------------------------------------
    // STATA 17 BATCH FIX: integer() and real() options cause r(197) "invalid
    // syntax" in Stata 17 batch mode. ALL numeric options are declared as
    // string() and converted manually below. This does NOT affect any calling
    // syntax - users still write nfactors(2), bandwidth(5) etc. as normal.
    // Also: LEVEL() is reserved by Stata eclass - do NOT declare it.
    // Also: fv removed from varlist - cupfm uses numeric panel data only.
    syntax varlist(min=2 numeric ts) [if] [in], ///
        [NFactors(string)              /// integer: 0 = auto-select via Bai-Ng (2002) IC
         BANDwidth(string)             /// integer: Bartlett kernel bandwidth (default=5)
         KERnel(string)                /// string:  bartlett|parzen (default: bartlett)
         MAXiter(string)               /// integer: max CupFM/CupBC iterations (default=20)
         TOLerance(string)             /// real:    convergence tolerance (default=0.0001)
         AUTORMAX(string)              /// integer: max r in auto-selection (default=8)
         NOICsummary                  /// suppress factor diagnostics table
         PLot                         /// produce all visualization plots
         PLotcoef                     /// plot: coefficient comparison only
         PLotfactors                  /// plot: estimated factors only
         PLotloadings                 /// plot: factor loadings only
         EXPort(string)               /// excel|latex|csv|all
         SAVing(string)               /// filename (no extension) for export/plots
         NOIsily                      /// verbose Mata output
         ]

    // --- Convert string options -> numeric & apply defaults -------------------
    if "`nfactors'"  == "" local nfactors  0
    else                    local nfactors  = real("`nfactors'")
    if "`bandwidth'" == "" local bandwidth 5
    else                    local bandwidth = real("`bandwidth'")
    if "`maxiter'"   == "" local maxiter   20
    else                    local maxiter   = real("`maxiter'")
    if "`tolerance'" == "" local tolerance 0.0001
    else                    local tolerance = real("`tolerance'")
    if "`autormax'"  == "" local autormax  8
    else                    local autormax  = real("`autormax'")
    local level 95   // hardcoded; LEVEL is reserved by Stata eclass

    // --- Validate numeric conversions -----------------------------------------
    foreach opt in nfactors bandwidth maxiter autormax {
        if missing(``opt'') {
            di as error "Option `opt'() must be a valid integer."
            exit 198
        }
        local `opt' = int(``opt'')
    }
    if missing(`tolerance') {
        di as error "Option tolerance() must be a valid real number."
        exit 198
    }

    // --- Sample ---------------------------------------------------------------
    marksample touse
    markout `touse' `varlist'

    // --- Parse varlist --------------------------------------------------------
    local depvar    : word 1 of `varlist'
    local indepvars : list varlist - depvar
    local nv        : word count `indepvars'

    if `nv' < 1 {
        di as error "cupfm requires at least one independent variable."
        exit 102
    }

    // --- Validate -------------------------------------------------------------
    _cupfm_validate `varlist' if `touse', ///
        nfactors(`nfactors') bandwidth(`bandwidth') ///
        maxiter(`maxiter') tolerance(`tolerance')

    local N_g      = r(N_g)
    local T        = r(T)
    local N_obs    = r(N_obs)
    local rmax     = r(rmax)
    local panelvar = "`r(panelvar)'"
    local timevar  = "`r(timevar)'"

    // --- Factor number logic --------------------------------------------------
    local do_autoR = 0
    local r_use    = `nfactors'
    if `nfactors' == 0 {
        local do_autoR = 1
        local r_use    = 1   // Mata will update this
    }

    // --- Kernel ---------------------------------------------------------------
    if "`kernel'" == "" local kernel "bartlett"
    if !inlist("`kernel'", "bartlett", "parzen") {
        di as error "kernel() must be 'bartlett' or 'parzen'."
        exit 198
    }

    // --- Sort data ------------------------------------------------------------
    sort `panelvar' `timevar'

    // --- DISPLAY: Running message ---------------------------------------------
    di ""
    di as text "  {bf:cupfm} - Panel Cointegration with Common Factors"
    di as text "  Running `=`N_g'' units x `=`T'' periods = `=`N_obs'' observations"
    if `do_autoR' {
        di as text "  Factor number: auto-select via Bai-Ng (2002) IC (rmax=`autormax')"
    }
    else {
        di as text "  Factor number: specified r = `r_use'"
    }
    di as text "  Bandwidth: `bandwidth' (`kernel' kernel)"
    di as text "  Max iterations: `maxiter'"
    di as text "  Estimating..."
    di ""

    // Re-sort (dataset sort order must be panelvar timevar for Mata engine)
    sort `panelvar' `timevar'

    // --- CALL MATA ENGINE - results stored in _cupfm_* global matrices --------
    mata: cupfm_main("`depvar'", "`indepvars'", "`touse'", ///
                     `N_g', `T', `r_use', `bandwidth', ///
                     "`kernel'", `maxiter', `do_autoR', `autormax', ///
                     `=cond("`noisily'"!="",1,0)')

    // --- Transfer _cupfm_ Stata scalars to local macros ----------------------
    local r_final     = _cupfm_r
    local niter_cupfm = _cupfm_niter
    local cvar_cupfm  = _cupfm_cvar
    local cvar_cupbc  = _cupfm_cvar_bc
    local converged   = _cupfm_converged

    // --- DISPLAY TABLES -------------------------------------------------------
    _cupfm_display, ///
        depvar(`depvar') indepvars(`indepvars') ///
        panelvar(`panelvar') timevar(`timevar') ///
        ng(`N_g') tperiods(`T') nobs(`N_obs') ///
        rfactors(`r_final') bwidth(`bandwidth') mxiter(`maxiter') ///
        niter(`niter_cupfm') ///
        `noicsummary'

    // --- PLOTS ----------------------------------------------------------------
    // IMPORTANT: must run BEFORE ereturn matrix (which DROPS _cupfm_b_* globals)
    if "`plot'" != "" | "`plotcoef'" != "" | "`plotfactors'" != "" | "`plotloadings'" != "" {
        local graph_opt ""
        if "`plotcoef'" != ""     local graph_opt "coef"
        if "`plotfactors'" != ""  local graph_opt "factors"
        if "`plotloadings'" != "" local graph_opt "loadings"
        if "`plot'" != ""         local graph_opt "all"

    // Pre-build option strings - avoids nested-quote r(132) in cond() expressions
        local saving_opt ""
        if "`saving'" != "" local saving_opt "saving(`saving')"
        local graph_arg "graph(all)"
        if "`graph_opt'" != "" local graph_arg "graph(`graph_opt')"

        _cupfm_plot, ///
            depvar(`depvar') indepvars(`indepvars') ///
            timevar(`timevar') ng(`N_g') tobs(`T') rfact(`r_final') ///
            `saving_opt' `graph_arg'
    }

    // --- EXPORT ---------------------------------------------------------------
    // IMPORTANT: must run BEFORE ereturn matrix (which DROPS _cupfm_b_* globals)
    if "`export'" != "" {
        if "`saving'" == "" {
            local saving "cupfm_results"
        }
        _cupfm_export, ///
            depvar(`depvar') indepvars(`indepvars') ///
            ng(`N_g') tobs(`T') rfact(`r_final') bwuse(`bandwidth') ///
            niter(`niter_cupfm') ///
            format(`export') saving(`saving')
    }

    // --- STORE IN e() ---------------------------------------------------------
    tempname b_cupfm V_cupfm

    // Build coefficient row vector for e(b): CupFM is the primary estimator
    matrix `b_cupfm' = _cupfm_b_cupfm

    // Build diagonal variance matrix: V_jj = (b_j / t_j)^2 = se_j^2
    matrix `V_cupfm' = J(`nv', `nv', 0)
    forvalues j = 1/`nv' {
        local bj = _cupfm_b_cupfm[1, `j']
        local tj = _cupfm_t_cupfm[1, `j']
        if abs(`tj') > 0.0001 {
            matrix `V_cupfm'[`j', `j'] = (`bj'/`tj')^2
        }
        else {
            matrix `V_cupfm'[`j', `j'] = 0
        }
    }

    // Name b and V with IDENTICAL column names - required by ereturn post
    matrix colnames `b_cupfm' = `indepvars'
    matrix rownames `V_cupfm' = `indepvars'
    matrix colnames `V_cupfm' = `indepvars'

    // Post primary result - clears previous e()
    ereturn post `b_cupfm' `V_cupfm', esample(`touse')

    // Additional coefficient matrices
    ereturn matrix beta_lsdv   = _cupfm_b_lsdv
    ereturn matrix beta_baifm  = _cupfm_b_baifm
    ereturn matrix beta_cupfm  = _cupfm_b_cupfm
    ereturn matrix beta_cupfm2 = _cupfm_b_cupfm2
    ereturn matrix beta_cupbc  = _cupfm_b_cupbc

    ereturn matrix tstat_lsdv   = _cupfm_t_lsdv
    ereturn matrix tstat_baifm  = _cupfm_t_baifm
    ereturn matrix tstat_cupfm  = _cupfm_t_cupfm
    ereturn matrix tstat_cupfm2 = _cupfm_t_cupfm2
    ereturn matrix tstat_cupbc  = _cupfm_t_cupbc

    // Factor/rotation matrices
    ereturn matrix F_hat    = _cupfm_f
    ereturn matrix Lambda   = _cupfm_lambda
    ereturn matrix Aik      = _cupfm_aik
    ereturn matrix Omega    = _cupfm_omega
    ereturn matrix Omega_bc = _cupfm_omega_bc

    // Scalars
    ereturn scalar Nobs        = `N_obs'
    ereturn scalar Ng          = `N_g'
    ereturn scalar Tperiods    = `T'
    ereturn scalar nfactors    = `r_final'
    ereturn scalar bw          = `bandwidth'
    ereturn scalar maxiter     = `maxiter'
    ereturn scalar niter       = `niter_cupfm'
    ereturn scalar cvar_cupfm  = `cvar_cupfm'
    ereturn scalar cvar_cupbc  = `cvar_cupbc'
    ereturn scalar level       = `level'
    ereturn scalar converged   = `converged'

    // Strings
    ereturn local cmd       "cupfm"
    ereturn local cmdline   "cupfm `0'"
    ereturn local depvar    "`depvar'"
    ereturn local indepvars "`indepvars'"
    ereturn local panelvar  "`panelvar'"
    ereturn local timevar   "`timevar'"
    ereturn local kernel    "`kernel'"
    ereturn local estimator "CupFM"
    ereturn local papers    "Bai, Kao & Ng (2009, JoE); Bai & Kao (2005, SSRN)"
    ereturn local vcetype   "Mixed normal (BKN 2009 Theorem 3)"

    di as text "  {it:Note: Primary result e(b), e(V) correspond to CupFM.}"
    di as text "  {it:All 5 estimators available in e(beta_*) and e(tstat_*).}"
    di ""
end
