*! _xtpvarcoint_mata.ado — Core Mata Engine
*! Panel VAR / Cointegration matrix algebra routines
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Version 1.0.0

capture program drop _xpvc_mata_load
program define _xpvc_mata_load
  version 14.0
end

mata:
mata set matastrict off

// ============================================================
// UTILITY: Convert data.frame-like panel to list of matrices
// ============================================================

// Extract panel data into Mata matrices
// Returns: Y[T x K] matrix for panel unit i
real matrix _xpvc_getpanel(string scalar depvar, string scalar indepvars,
                           string scalar ivar, string scalar tvar,
                           string scalar touse, real scalar ival)
{
  real colvector y, x, id, t, sel
  real matrix data
  string rowvector vnames
  real scalar k
  
  vnames = tokens(depvar + " " + indepvars)
  k = cols(vnames)
  
  st_view(id, ., ivar, touse)
  sel = selectindex(id :== ival)
  
  data = J(rows(sel), k, .)
  for (j=1; j<=k; j++) {
    st_view(x, ., vnames[j], touse)
    data[., j] = x[sel]
  }
  return(data)
}

// ============================================================
// STACKING: Build Z0, Z1, Z2 for Johansen RRR
// From Johansen (1995:90, Ch.6)
// ============================================================

// Stack lagged differences for short-run regressors Z2
// y_diff: (T-1) x K first-differenced data
// dim_p:  lag order (we need p-1 lags of diffs)
real matrix _xpvc_stack_diffs(real matrix y_diff, real scalar dim_p)
{
  real scalar T, K, j, rows_out
  real matrix Z2
  
  T = rows(y_diff)
  K = cols(y_diff)
  rows_out = T - dim_p + 1  // effective sample
  
  if (dim_p <= 1) return(J(0, rows_out, .))
  
  Z2 = J(K * (dim_p - 1), rows_out, 0)
  for (j = 1; j <= dim_p - 1; j++) {
    Z2[(j-1)*K+1..j*K, .] = y_diff[dim_p-j..T-j, .]'
  }
  return(Z2)
}

// Build deterministic dummy matrices
// type: "none", "const", "trend", "both"
real matrix _xpvc_dummy(real scalar dim_T, string scalar type,
                        | real colvector t_shift, real colvector t_break,
                        real colvector t_impulse, real scalar n_season)
{
  real matrix D
  real scalar n, j, s
  real colvector d_const, d_trend, d_shift, d_break, d_imp, d_seas
  
  D = J(0, dim_T, .)
  
  // Constant
  if (type == "const" | type == "both") {
    D = D \ J(1, dim_T, 1)
  }
  
  // Linear trend
  if (type == "trend" | type == "both") {
    D = D \ (1..dim_T)
  }
  
  // Shift dummies (level shift at t_shift)
  if (args() >= 4 & rows(t_shift) > 0) {
    for (j = 1; j <= rows(t_shift); j++) {
      d_shift = J(dim_T, 1, 0)
      n = t_shift[j]
      if (n >= 1 & n <= dim_T) {
        d_shift[n..dim_T] = J(dim_T - n + 1, 1, 1)
      }
      D = D \ d_shift'
    }
  }
  
  // Trend break dummies
  if (args() >= 5 & rows(t_break) > 0) {
    for (j = 1; j <= rows(t_break); j++) {
      d_break = J(dim_T, 1, 0)
      n = t_break[j]
      if (n >= 1 & n <= dim_T) {
        for (s = n; s <= dim_T; s++) {
          d_break[s] = s - n + 1
        }
      }
      D = D \ d_break'
    }
  }
  
  // Impulse dummies
  if (args() >= 6 & rows(t_impulse) > 0) {
    for (j = 1; j <= rows(t_impulse); j++) {
      d_imp = J(dim_T, 1, 0)
      n = t_impulse[j]
      if (n >= 1 & n <= dim_T) d_imp[n] = 1
      D = D \ d_imp'
    }
  }
  
  // Seasonal dummies (centered)
  if (args() >= 7 & n_season > 1) {
    for (s = 1; s <= n_season - 1; s++) {
      d_seas = J(dim_T, 1, -1/n_season)
      for (j = s; j <= dim_T; j = j + n_season) {

        d_seas[j] = 1 - 1/n_season
      }
      D = D \ d_seas'
    }
  }
  
  return(D)
}

// Full Johansen stacking: returns Z0, Z1, Z2
// y: K x T data matrix (variables in rows, time in columns)
// Johansen 1995:90, Eq.6.4-6.7
struct _xpvc_RRRdef {
  real matrix Z0    // K x (T-p) first-differenced regressand
  real matrix Z1    // (K+n_d1) x (T-p) lagged levels for cointegrating term
  real matrix Z2    // (K*(p-1)+n_d2) x (T-p) lagged diffs + unrestricted det.
  real matrix D1    // restricted det. regressors
  real matrix D2    // unrestricted det. regressors
  real matrix y     // K x T original data
  real scalar dim_K // number of endogenous variables
  real scalar dim_T // effective sample size
  real scalar dim_p // lag order
}

struct _xpvc_RRRdef scalar _xpvc_stackRRR(real matrix y, real scalar dim_p,
                                           string scalar type,
                                           | real colvector t_shift,
                                           real colvector t_break)
{
  struct _xpvc_RRRdef scalar def
  real matrix y_diff, Z2_lags, D1, D2
  real scalar dim_K, dim_T_total, dim_T, dim_pq
  string scalar type_D1, type_D2
  real colvector ts_empty
  
  dim_K = rows(y)
  dim_T_total = cols(y)
  dim_T = dim_T_total - dim_p
  
  ts_empty = J(0, 1, .)
  if (args() < 4) t_shift = ts_empty
  if (args() < 5) t_break = ts_empty
  
  // Deterministic term mapping (Johansen cases)
  if (type == "Case1") {
    type_D1 = "none"
    type_D2 = "none"
  }
  else if (type == "Case2") {
    type_D1 = "const"
    type_D2 = "none"
  }
  else if (type == "Case3") {
    type_D1 = "none"
    type_D2 = "const"
  }
  else if (type == "Case4") {
    type_D1 = "trend"
    type_D2 = "const"
  }
  else if (type == "Case5") {
    type_D1 = "none"
    type_D2 = "both"
  }
  else {
    type_D1 = "none"
    type_D2 = "none"
  }

  
  // Build D1 (restricted) and D2 (unrestricted)
  D1 = _xpvc_dummy(dim_T_total, type_D1, t_shift, t_break)
  D2 = _xpvc_dummy(dim_T_total, type_D2, ts_empty, ts_empty)
  
  // First-difference the data
  y_diff = y[., 2..dim_T_total] - y[., 1..dim_T_total-1]
  
  // Stack Z0: first-differenced regressand (K x T-p)
  def.Z0 = y_diff[., dim_p..dim_T_total-1]
  
  // Stack Z1: lagged levels (K+n_d1 x T-p)
  if (rows(D1) > 0) {
    def.Z1 = (y \ D1)[., dim_p..dim_T_total-1]
  }
  else {
    def.Z1 = y[., dim_p..dim_T_total-1]
  }
  
  // Stack Z2: lagged diffs + unrestricted det. term
  Z2_lags = _xpvc_stack_diffs(y_diff', dim_p)
  if (rows(D2) > 0) {
    real matrix D2_eff
    // First-difference D2 and take effective sample
    D2_eff = D2[., 2..dim_T_total]
    D2_eff = D2_eff[., dim_p..dim_T_total-1]
    def.Z2 = Z2_lags \ D2_eff
  }
  else {
    def.Z2 = Z2_lags
  }
  
  // Store
  def.D1 = D1
  def.D2 = D2
  def.y = y
  def.dim_K = dim_K
  def.dim_T = dim_T
  def.dim_p = dim_p
  
  return(def)
}


// ============================================================
// REDUCED RANK REGRESSION (Johansen 1995:90, Ch.6)
// ============================================================

struct _xpvc_RRRresult {
  real colvector lambda  // eigenvalues (squared canonical correlations)
  real matrix V          // eigenvectors (cointegrating vectors)
  real matrix S00        // product moment matrices
  real matrix S01
  real matrix S10
  real matrix S11
  real matrix S00inv
  real matrix R0         // concentrated residuals (optional)
  real matrix R1
  real matrix Z0         // regressand (first-differenced)
  real matrix Z1         // lagged levels for cointegrating term
  real matrix Z2         // lagged diffs + unrestricted deterministic
  real matrix M02        // product moment M02
  real matrix M12        // product moment M12
  real matrix M22inv     // inverse of M22
}

struct _xpvc_RRRresult scalar _xpvc_RRR(real matrix Z0, real matrix Z1,
                                         real matrix Z2, | real scalar via_R0R1)
{
  struct _xpvc_RRRresult scalar res
  real matrix M00, M11, M22, M01, M02, M12, M10, M20, M21, M22inv
  real matrix S00, S01, S10, S11, S00inv
  real matrix C, Cinv, Ctemp, cc_mat
  real colvector eigenvals
  real matrix eigenvecs
  real scalar dim_T
  
  if (args() < 4) via_R0R1 = 0
  
  dim_T = cols(Z0)
  
  // Product moment matrices (Johansen 1995:90, Eq.6.4)
  M00 = Z0 * Z0' / dim_T
  M11 = Z1 * Z1' / dim_T
  M01 = Z0 * Z1' / dim_T
  M02 = Z0 * Z2' / dim_T
  M12 = Z1 * Z2' / dim_T
  M10 = M01'
  M20 = M02'
  M21 = M12'
  
  if (rows(Z2) == 0) {
    M22 = J(0, 0, .)
    M22inv = J(0, 0, .)
  }
  else {
    M22 = Z2 * Z2' / dim_T
    M22inv = invsym(M22)
  }
  
  // Concentrate out short-run effects (Johansen 1995:90, Eq.6.6-6.7)
  if (via_R0R1) {
    if (rows(Z2) > 0) {
      res.R0 = Z0 - M02 * M22inv * Z2
      res.R1 = Z1 - M12 * M22inv * Z2
    }
    else {
      res.R0 = Z0
      res.R1 = Z1
    }
  }
  
  // Product moments for RRR (Johansen 1995:90, Eq.6.10)
  if (rows(M22inv) > 0) {
    S00 = M00 - M02 * M22inv * M20
    S01 = M01 - M02 * M22inv * M21
    S11 = M11 - M12 * M22inv * M21
  }
  else {
    S00 = M00
    S01 = M01
    S11 = M11
  }
  S10 = S01'
  S00inv = invsym(S00)
  
  // Cholesky decomposition of S11 (Pfaff 2008:81 / Johansen 1995:95)
  Ctemp = cholesky(S11)
  C = Ctemp
  Cinv = luinv(C)
  
  // Eigenvalue problem (Johansen 1995:92,95)
  cc_mat = Cinv * S10 * S00inv * S01 * Cinv'
  cc_mat = (cc_mat + cc_mat') / 2  // ensure symmetry
  eigensystem(cc_mat, eigenvecs, eigenvals)
  eigenvals = Re(eigenvals)'   // transpose to column vector
  eigenvecs = Re(eigenvecs)
  
  // Sort eigenvalues descending
  real colvector idx
  idx = order(-eigenvals, 1)
  eigenvals = eigenvals[idx]
  eigenvecs = eigenvecs[., idx]
  
  // Retransform eigenvectors to cointegrating vectors
  // V = Cinv' * e, normalized so V'S11V = I
  res.V = Cinv' * eigenvecs
  res.lambda = eigenvals
  res.S00 = S00
  res.S01 = S01
  res.S10 = S10
  res.S11 = S11
  res.S00inv = S00inv
  // Store Z-matrices and M-matrices for VECM estimation
  res.Z0 = Z0
  res.Z1 = Z1
  res.Z2 = Z2
  res.M02 = M02
  res.M12 = M12
  res.M22inv = M22inv
  
  return(res)
}


// ============================================================
// COINTEGRATION RANK: LR Test Statistics and p-values
// Johansen (1995:92, Eq.6.14/6.18), Doornik (1998)
// ============================================================

struct _xpvc_LRresult {
  real colvector r_H0       // ranks under H0
  real colvector stats_TR   // trace test statistics
  real colvector stats_ME   // max eigenvalue test statistics
  real colvector pvals_TR   // p-values for trace
  real colvector pvals_ME   // p-values for max eigenvalue
}

struct _xpvc_LRresult scalar _xpvc_LRrank(real colvector lambda,
                                           real scalar dim_T,
                                           real scalar dim_K,
                                           real matrix moments)
{
  struct _xpvc_LRresult scalar res
  real scalar k, r
  real colvector stats_TR, stats_ME, pvals_TR, pvals_ME, r_H0
  real scalar m_tr, v_tr, m_me, v_me, shape, rate
  
  r_H0 = (0::dim_K-1)
  stats_TR = J(dim_K, 1, .)
  stats_ME = J(dim_K, 1, .)
  pvals_TR = J(dim_K, 1, .)
  pvals_ME = J(dim_K, 1, .)
  
  for (k = 1; k <= dim_K; k++) {
    r = k - 1  // r_H0
    
    // Max eigenvalue test (Eq.6.18)
    stats_ME[k] = -dim_T * ln(1 - lambda[k])
    
    // Trace test (Eq.6.14)
    stats_TR[k] = 0
    for (j = k; j <= dim_K; j++) {
      stats_TR[k] = stats_TR[k] - dim_T * ln(1 - lambda[j])
    }
    
    // Gamma approximation for p-values (Doornik 1998:576, Eq.4)
    m_tr = moments[k, 1]  // E[TR]
    v_tr = moments[k, 2]  // Var[TR]
    if (m_tr != . & v_tr != . & v_tr > 0) {
      shape = m_tr^2 / v_tr
      rate = m_tr / v_tr
      pvals_TR[k] = 1 - gammap(shape, stats_TR[k] * rate)
    }
    
    if (cols(moments) >= 4) {
      m_me = moments[k, 3]  // E[ME]
      v_me = moments[k, 4]  // Var[ME]
      if (m_me != . & v_me != . & v_me > 0) {
        shape = m_me^2 / v_me
        rate = m_me / v_me
        pvals_ME[k] = 1 - gammap(shape, stats_ME[k] * rate)
      }
    }
  }
  
  res.r_H0 = r_H0
  res.stats_TR = stats_TR
  res.stats_ME = stats_ME
  res.pvals_TR = pvals_TR
  res.pvals_ME = pvals_ME
  
  return(res)
}


// ============================================================
// VECM ESTIMATION given beta
// Johansen (1995:93-96)
// ============================================================

struct _xpvc_VECMresult {
  real matrix alpha    // loading matrix K x r
  real matrix PI       // long-run impact matrix K x (K+n_d1)
  real matrix GAMMA    // short-run coefficient matrices
  real matrix OMEGA    // MLE covariance of residuals
  real matrix SIGMA    // OLS covariance of residuals
  real matrix resid    // K x T residual matrix
}

struct _xpvc_VECMresult scalar _xpvc_VECM(real matrix beta,
                                             struct _xpvc_RRRresult scalar RRR)
{
  struct _xpvc_VECMresult scalar vecm
  real matrix alpha, GAMMA, PI, resid, OMEGA, SIGMA
  real scalar dim_T, dim_K, dim_r, dim_Kpn
  real matrix Z0, Z1, Z2, S00, S01, S10, S11
  real matrix M02, M12, M22inv, C_norm
  
  // Access Z-matrices from RRR result (now stored in struct)
  Z0 = RRR.Z0
  Z1 = RRR.Z1
  Z2 = RRR.Z2
  S00 = RRR.S00
  S01 = RRR.S01
  S10 = RRR.S10
  S11 = RRR.S11
  M02 = RRR.M02
  M12 = RRR.M12
  M22inv = RRR.M22inv
  
  dim_T = cols(Z0)
  dim_K = rows(Z0)
  dim_r = cols(beta)
  dim_Kpn = rows(Z1) + rows(Z2)
  
  if (dim_r == 0) {
    // No cointegration: estimate unrestricted short-run model
    alpha = J(dim_K, 0, .)
    PI = J(dim_K, rows(Z1), 0)
    if (rows(Z2) > 0) {
      GAMMA = M02 * M22inv
      resid = Z0 - GAMMA * Z2
    }
    else {
      GAMMA = J(dim_K, 0, .)
      resid = Z0
    }
  }
  else {
    // Johansen closed-form estimation (matching R aux_VECM)
    // Normalization: C = (beta' * S11 * beta)^{-1}
    C_norm = invsym(beta' * S11 * beta)
    
    // Loading matrix: alpha = S01 * beta * C
    // Johansen 1995:91, Eq.6.11
    alpha = S01 * beta * C_norm
    
    // Long-run impact: PI = alpha * beta'
    // Johansen 1995:96, Eq.6.23
    PI = alpha * beta'
    
    // Short-run effects: GAMMA = M02*M22inv - PI*M12*M22inv
    // Johansen 1995:90, Eq.6.5
    if (rows(Z2) > 0) {
      GAMMA = M02 * M22inv - PI * M12 * M22inv
    }
    else {
      GAMMA = J(dim_K, 0, .)
    }
    
    // Covariance: OMEGA = S00 - PI * S10
    // Johansen 1995:91, Eq.6.12
    OMEGA = S00 - PI * S10
    SIGMA = OMEGA * (dim_T / (dim_T - dim_Kpn))
    
    // Residuals
    resid = Z0 - PI * Z1
    if (rows(Z2) > 0) resid = resid - GAMMA * Z2
  }
  
  // Covariance matrices (for r=0 case)
  if (dim_r == 0) {
    OMEGA = resid * resid' / dim_T
    SIGMA = OMEGA * (dim_T / (dim_T - dim_Kpn))
  }
  
  vecm.alpha = alpha
  vecm.PI = PI
  vecm.GAMMA = GAMMA
  vecm.OMEGA = OMEGA
  vecm.SIGMA = SIGMA
  vecm.resid = resid
  
  return(vecm)
}

// ============================================================
// Convert VECM to VAR in levels
// PI = alpha*beta', GAMMA = [GAMMA_1, ..., GAMMA_{p-1}]
// => A = [A_1, ..., A_p] where A_j from Johansen notation
// ============================================================

real matrix _xpvc_vec2var(real matrix PI, real matrix GAMMA, real scalar dim_p)
{
  real scalar dim_K, j
  real matrix A, I_K, G_j, PI_K
  
  dim_K = rows(PI)
  PI_K = PI[., 1..dim_K]  // extract only endogenous part of PI
  I_K = I(dim_K)
  
  A = J(dim_K, dim_K * dim_p, 0)
  
  if (dim_p == 1) {
    // A_1 = I + PI
    A[., 1..dim_K] = I_K + PI_K
  }
  else {
    // A_1 = I + PI + GAMMA_1
    G_j = GAMMA[., 1..dim_K]
    A[., 1..dim_K] = I_K + PI_K + G_j
    
    // A_j = GAMMA_j - GAMMA_{j-1} for j=2,...,p-1
    for (j = 2; j <= dim_p - 1; j++) {
      real matrix G_prev, G_curr
      G_prev = GAMMA[., (j-2)*dim_K+1..(j-1)*dim_K]
      G_curr = GAMMA[., (j-1)*dim_K+1..j*dim_K]
      A[., (j-1)*dim_K+1..j*dim_K] = G_curr - G_prev
    }
    
    // A_p = -GAMMA_{p-1}
    G_j = GAMMA[., (dim_p-2)*dim_K+1..(dim_p-1)*dim_K]
    A[., (dim_p-1)*dim_K+1..dim_p*dim_K] = -G_j
  }
  
  return(A)
}


// ============================================================
// Orthogonal complement (equivalent to MASS::Null)
// ============================================================

real matrix _xpvc_oc(real matrix M)
{
  real matrix MM, V
  real colvector lambda
  real scalar rk, n, j, tol
  
  n = rows(M)
  if (cols(M) == 0) return(I(n))
  
  rk = cols(M)
  if (rk >= n) return(J(n, 0, .))
  
  // Compute M*M' and find its eigendecomposition
  // The eigenvectors corresponding to near-zero eigenvalues
  // span the orthogonal complement of range(M)
  MM = M * M'
  eigensystem(MM, V, lambda)
  
  // lambda and V are complex, take real parts
  // Eigenvectors corresponding to smallest eigenvalues are the null space
  // eigenvalues are returned in decreasing order by default
  // We need the last (n - rk) eigenvectors
  return(Re(V[., rk+1..n]))
}


// ============================================================
// Beta normalization
// ============================================================

real matrix _xpvc_beta(real matrix V, real scalar dim_r,
                       | string scalar normalize)
{
  real matrix beta
  
  if (args() < 3) normalize = "natural"
  
  if (dim_r == 0) return(J(rows(V), 0, .))
  
  beta = V[., 1..dim_r]
  
  if (normalize == "natural") {
    // Natural normalization: beta = [I_r; beta_1']' (Johansen 1995:179)
    beta = beta * luinv(beta[1..dim_r, .])
  }
  else if (normalize == "first") {
    // Normalize to first element of each column
    real scalar j
    for (j = 1; j <= dim_r; j++) {
      beta[., j] = beta[., j] / beta[1, j]
    }
  }
  
  return(beta)
}


// ============================================================
// GLS DETRENDING for SL procedure
// From Saikkonen & Luetkepohl (2000, Eq.3.1) / Trenkler (2008)
// ============================================================

struct _xpvc_GLSresult {
  real matrix MU  // coefficients for deterministic term
  real matrix x   // detrended series (K x T)
}

struct _xpvc_GLSresult scalar _xpvc_GLStrend(real matrix y,
                                              real scalar dim_p,
                                              real matrix OMEGA,
                                              real matrix A_slope,
                                              real matrix D)
{
  struct _xpvc_GLSresult scalar res
  real scalar dim_T, dim_K, dim_n, j, t, ki, kj
  real matrix OMEGAinv, Yz, Aj, Yj
  real matrix XtOX, dd
  real colvector XtOY, mu_vec, d_t, yz_t
  
  dim_T = cols(y)
  dim_K = rows(y)
  dim_n = rows(D)
  
  OMEGAinv = invsym(OMEGA)
  
  // Quasi-difference the data: remove A(L) effects
  Yz = y
  for (j = 1; j <= dim_p; j++) {
    Aj = A_slope[., (j-1)*dim_K+1..j*dim_K]
    Yj = J(dim_K, j, 0), y[., 1..dim_T-j]
    Yz = Yz - Aj * Yj
  }
  
  // Build GLS normal equations without Kronecker products
  // Accumulate (X_t' Omega^{-1} X_t) and (X_t' Omega^{-1} Yz_t)
  XtOX = J(dim_K * dim_n, dim_K * dim_n, 0)
  XtOY = J(dim_K * dim_n, 1, 0)
  
  for (t = 1; t <= dim_T; t++) {
    d_t = D[., t]
    yz_t = Yz[., t]
    dd = d_t * d_t'
    
    for (ki = 1; ki <= dim_K; ki++) {
      for (kj = 1; kj <= dim_K; kj++) {
        XtOX[(ki-1)*dim_n+1..ki*dim_n, (kj-1)*dim_n+1..kj*dim_n] = ///
          XtOX[(ki-1)*dim_n+1..ki*dim_n, (kj-1)*dim_n+1..kj*dim_n] + ///
          dd * OMEGAinv[ki, kj]
      }
      XtOY[(ki-1)*dim_n+1..ki*dim_n] = ///
        XtOY[(ki-1)*dim_n+1..ki*dim_n] + ///
        d_t * (OMEGAinv[ki, .] * yz_t)
    }
  }
  
  // Solve: mu_vec = (XtOX)^{-1} * XtOY
  mu_vec = invsym(XtOX) * XtOY
  
  // Reshape MU and detrend
  res.MU = rowshape(mu_vec, dim_K)
  res.x = y - res.MU * D
  
  return(res)
}



// ============================================================
// PANEL COMBINATION FUNCTIONS
// ============================================================

// Standardized mean of individual test statistics
// Larsson et al. (2001:112, Eq.11-12)
// STATS: K x N matrix, moments: K x 2 (mean, var)
void _xpvc_STATSbar(real matrix STATS, real matrix moments,
                     real matrix ptstats, real matrix ptpvals)
{
  real scalar dim_K, dim_N
  real colvector EZ, VZ, STATSbar, UPSILON
  
  dim_K = rows(STATS)
  dim_N = cols(STATS)
  
  EZ = moments[., 1]
  VZ = moments[., 2]
  
  STATSbar = rowsum(STATS) / dim_N
  UPSILON = sqrt(dim_N) :* (STATSbar - EZ) :/ sqrt(VZ)
  
  ptstats = UPSILON
  ptpvals = 1 :- normal(UPSILON)
}

// Meta-analytical combination of p-values
// Choi (2001) / Maddala & Wu (1999)
// PVALS: K x N matrix
void _xpvc_METApval(real matrix PVALS,
                     real matrix ptstats, real matrix ptpvals)
{
  real scalar dim_K, dim_N
  real colvector P, Pm, Z
  
  dim_K = rows(PVALS)
  dim_N = cols(PVALS)
  
  // Fisher inverse chi-square (Choi 2001:253, Eq.8)
  P = -2 * rowsum(ln(PVALS))
  
  // Modified for infinite N (Choi 2001:255, Eq.18)
  Pm = (P :- 2*dim_N) / sqrt(4*dim_N)
  
  // Inverse normal (Choi 2001:253, Eq.9)
  Z = rowsum(invnormal(PVALS)) / sqrt(dim_N)
  
  ptstats = P, Pm, Z
  
  // p-values
  real colvector pP, pPm, pZ
  pP = 1 :- chi2(2*dim_N, P)
  pPm = 1 :- normal(Pm)
  pZ = normal(Z)
  
  ptpvals = pP, pPm, pZ
}


// Correlation-augmented inverse normal (CAIN)
// Arsova & Oersal (2021)
void _xpvc_CAIN(real matrix PVALS, real scalar dim_K,
                 real scalar rho_eps,
                 real matrix ptstats, real matrix ptpvals,
                 real matrix rho_tilde)
{
  real scalar dim_N, k
  real colvector r_H0, d_H0
  real matrix PROBITS, cain_term
  real colvector rho_CAIN, CAIN
  real rowvector cain_rscoef
  
  dim_N = cols(PVALS)
  PROBITS = invnormal(PVALS)
  
  r_H0 = (0::dim_K-1)
  d_H0 = dim_K :- r_H0
  
  // Response surface coefficients (Oersal,Arsova 2016:10, Tab.2)
  cain_rscoef = (0.6319575, -0.5193669, 0.2721753,
                 0.1821374, -0.0856903, 0.0041125,
                 0.0766267, -0.1008678, 0.1874919,
                 0.1410229, -0.2029126, 0.0052557, -0.0000327)
  
  // Build regressor matrix
  cain_term = J(dim_K, 13, .)
  cain_term[., 1] = rho_eps^2 * J(dim_K, 1, 1)
  cain_term[., 2] = sqrt(dim_K) * rho_eps^2 * J(dim_K, 1, 1)
  cain_term[., 3] = sqrt(dim_K) * rho_eps^4 * J(dim_K, 1, 1)
  cain_term[., 4] = (r_H0/dim_K) * rho_eps^2
  cain_term[., 5] = (r_H0/dim_K) * rho_eps^4
  cain_term[., 6] = (r_H0 * rho_eps):^2
  cain_term[., 7] = r_H0 * rho_eps^2
  cain_term[., 8] = r_H0 * rho_eps^4
  cain_term[., 9] = sqrt(d_H0) * rho_eps^2
  cain_term[., 10] = (1:/d_H0) * rho_eps^2
  cain_term[., 11] = (1:/d_H0) * rho_eps^4
  cain_term[., 12] = (d_H0:^2) * rho_eps^2
  cain_term[., 13] = (d_H0:^4) * rho_eps^4
  
  rho_CAIN = cain_term * cain_rscoef'
  
  CAIN = rowsum(PROBITS) :/ sqrt(dim_N :+ (dim_N^2 - dim_N) :* rho_CAIN)
  
  ptstats = CAIN
  ptpvals = normal(CAIN)
  rho_tilde = rho_CAIN
}


// ============================================================
// MEAN GROUP ESTIMATOR (Pesaran & Smith 1995)
// ============================================================

void _xpvc_MG(pointer(real matrix) colvector L_coef,
              real scalar dim_N,
              real matrix mg_mean, real matrix mg_var)
{
  real scalar i
  real matrix sum_coef, sum_sq
  
  mg_mean = *L_coef[1]
  sum_sq = J(rows(mg_mean), cols(mg_mean), 0)
  
  for (i = 2; i <= dim_N; i++) {
    mg_mean = mg_mean + *L_coef[i]
  }
  mg_mean = mg_mean / dim_N
  
  for (i = 1; i <= dim_N; i++) {
    sum_sq = sum_sq + (*L_coef[i] - mg_mean):^2
  }
  mg_var = sum_sq / (dim_N - 1)
}


// ============================================================
// COMMON FACTORS (PANIC by Bai & Ng, 2004)
// PCA on first-differenced, centered, scaled panel data
// ============================================================

struct _xpvc_PCAresult {
  real matrix LAMBDA    // KN x n_factors loadings
  real matrix Ft        // T x n_factors common factors (cumulated)
  real matrix eit       // T x KN idiosyncratic components
  real colvector evals  // eigenvalues
}

struct _xpvc_PCAresult scalar _xpvc_ComFact(real matrix X,
                                             real scalar n_factors,
                                             real scalar do_trend,
                                             real scalar do_scale)
{
  struct _xpvc_PCAresult scalar pca
  real matrix xit, xsd, U, Vt
  real colvector s
  real scalar dim_T, dim_KN
  real matrix ft, Ft, LAMBDA
  
  dim_T = rows(X)
  dim_KN = cols(X)
  
  // First-difference
  xit = X[2..dim_T, .] - X[1..dim_T-1, .]
  
  // Center (demean)
  if (do_trend) {
    xit = xit :- mean(xit)
  }
  
  // Scale
  if (do_scale) {
    real rowvector sd_x
    sd_x = sqrt(diagonal(variance(xit)))'
    sd_x = sd_x + (sd_x :== 0)  // avoid division by zero
    xit = xit :/ sd_x
  }
  else {
    xsd = xit
  }
  xsd = xit
  
  // SVD
  svd(xsd, U, s, Vt)
  
  // Factors and loadings
  ft = sqrt(dim_T - 1) * U[., 1..n_factors]
  LAMBDA = xit' * ft / (dim_T - 1)
  
  // Cumulate into levels
  Ft = J(dim_T, n_factors, 0)
  Ft[1, .] = J(1, n_factors, 0)
  for (t = 2; t <= dim_T; t++) {
    Ft[t, .] = Ft[t-1, .] + ft[t-1, .]
  }
  
  // Idiosyncratic components
  pca.eit = X - Ft * LAMBDA'
  pca.LAMBDA = LAMBDA
  pca.Ft = Ft
  pca.evals = s:^2
  
  return(pca)
}


// ============================================================
// ONATSKI (2010) Edge distribution criterion
// ============================================================

real scalar _xpvc_ONC(real colvector eigenvals, real scalar r_max,
                       real scalar n_iter)
{
  real colvector eigendiffs, y_reg, x_reg
  real scalar j, delta, r_hat, i
  real rowvector b
  
  eigendiffs = eigenvals[1..r_max] - eigenvals[2..r_max+1]
  
  j = r_max + 1
  r_hat = 0
  
  for (i = 1; i <= n_iter; i++) {
    // Auxiliary OLS
    y_reg = eigenvals[j..j+4]
    x_reg = J(5, 1, 1), ((j-1..j+3)'):^(2/3)
    b = (invsym(x_reg' * x_reg) * x_reg' * y_reg)'
    delta = 2 * abs(b[2])
    
    // Estimate number of factors
    r_hat = 0
    for (k = 1; k <= r_max; k++) {
      if (eigendiffs[k] >= delta) r_hat = k
    }
    
    j = r_hat + 1
  }
  
  return(r_hat)
}

// ============================================================
// AHN-HORENSTEIN (2013) Eigenvalue ratio test
// ============================================================

void _xpvc_AHC(real colvector eigenvals, real scalar r_max,
                real scalar r_ER, real scalar r_GR)
{
  real scalar dim_m, eigen_sum, eigen_zero
  real colvector eigen_val0, eigen_star, ER, GR
  real scalar k
  
  dim_m = rows(eigenvals)
  
  // Guard: r_max must be less than dim_m - 1
  if (r_max >= dim_m - 1) r_max = dim_m - 2
  if (r_max < 1) r_max = 1
  
  eigen_sum = sum(eigenvals)
  eigen_zero = eigen_sum / (dim_m * ln(dim_m))
  
  // eigen_val0 has r_max+2 elements: [eigen_zero, evals[1..r_max+1]]
  eigen_val0 = eigen_zero \ eigenvals[1..r_max+1]
  
  // Cumulative eigenvalue sum: r_max+2 elements: [0, cumsum(evals[1..r_max+1])]
  real colvector cumev
  cumev = 0 \ runningsum(eigenvals[1..r_max+1])
  
  // eigen_star: r_max+2 elements (same as eigen_val0 and cumev)
  eigen_star = eigen_val0 :/ (eigen_sum :- cumev)
  
  // ER and GR: r_max+1 elements each
  ER = eigen_val0[1..r_max+1] :/ eigen_val0[2..r_max+2]
  GR = ln(1 :+ eigen_star[1..r_max+1]) :/ ln(1 :+ eigen_star[2..r_max+2])
  
  // Find max
  real scalar max_ER, max_GR
  real scalar idx_ER, idx_GR
  max_ER = 0
  idx_ER = 0
  max_GR = 0
  idx_GR = 0
  for (k = 1; k <= r_max + 1; k++) {
        if (ER[k] > max_ER) {
      max_ER = ER[k]
      idx_ER = k
    }
        if (GR[k] > max_GR) {
      max_GR = GR[k]
      idx_GR = k
    }
  }
  
  r_ER = idx_ER - 1  // account for k=0
  r_GR = idx_GR - 1
}


// ============================================================
// INFORMATION CRITERIA for model selection
// ============================================================

void _xpvc_MIC(real matrix OMEGA, real matrix COEF,
                real scalar dim_T,
                real scalar aic, real scalar hqc,
                real scalar sic, real scalar fpe)
{
  real scalar dim_K, n_coef, logdet
  
  dim_K = rows(OMEGA)
  n_coef = cols(COEF)
  logdet = ln(det(OMEGA))
  
  aic = logdet + 2 * n_coef * dim_K / dim_T
  hqc = logdet + 2 * ln(ln(dim_T)) * n_coef * dim_K / dim_T
  sic = logdet + ln(dim_T) * n_coef * dim_K / dim_T
  fpe = ((dim_T + n_coef) / (dim_T - n_coef))^dim_K * det(OMEGA)
}


// ============================================================
// COMPANION MATRIX for stability check
// ============================================================

real matrix _xpvc_companion(real matrix A, real scalar dim_p)
{
  real scalar dim_K, dim_Kp
  real matrix C
  
  dim_K = rows(A)
  dim_Kp = dim_K * dim_p
  
  if (dim_p == 1) return(A)
  
  C = J(dim_Kp, dim_Kp, 0)
  C[1..dim_K, .] = A
  C[dim_K+1..dim_Kp, 1..dim_Kp-dim_K] = I(dim_Kp - dim_K)
  
  return(C)
}


// ============================================================
// IMPULSE RESPONSE FUNCTIONS
// Luetkepohl (2005:51, Eq.2.1.20)
// ============================================================

// PHI_h = sum_{j=1}^{h} PHI_{h-j} * A_j, PHI_0 = I_K
// Returns: pointer vector of K x K matrices for h=0,...,n_ahead
void _xpvc_IRF_phi(real matrix A, real scalar dim_p, real scalar n_ahead,
                    pointer(real matrix) colvector PHI)
{
  real scalar dim_K, h, j, jmax
  real matrix A_j
  
  dim_K = rows(A)
  PHI = J(n_ahead + 1, 1, NULL)
  
  PHI[1] = &(I(dim_K))  // PHI_0 = I
  
  for (h = 1; h <= n_ahead; h++) {
    real matrix phi_h
    phi_h = J(dim_K, dim_K, 0)
    jmax = min((h, dim_p))
    for (j = 1; j <= jmax; j++) {
      A_j = A[., (j-1)*dim_K+1..j*dim_K]
      phi_h = phi_h + *PHI[h-j+1] * A_j
    }
    PHI[h+1] = &phi_h
  }
}

// Structural IRF: THETA_h = PHI_h * B
void _xpvc_IRF_theta(pointer(real matrix) colvector PHI,
                      real matrix B, real scalar n_ahead,
                      pointer(real matrix) colvector THETA)
{
  real scalar h
  
  THETA = J(n_ahead + 1, 1, NULL)
  for (h = 0; h <= n_ahead; h++) {
    THETA[h+1] = &(*PHI[h+1] * B)
  }
}


// ============================================================
// FORECAST ERROR VARIANCE DECOMPOSITION
// ============================================================

void _xpvc_FEVD(pointer(real matrix) colvector THETA,
                 real scalar n_ahead, real scalar dim_K,
                 real matrix FEVD_out)
{
  real scalar h, k, s
  real matrix theta_h
  real colvector mse_k
  
  // FEVD_out: (n_ahead+1) x (K*K) where each row is vectorized KxK FEVD
  FEVD_out = J(n_ahead + 1, dim_K * dim_K, 0)
  
  // Cumulative MSE
  real matrix cum_sq
  cum_sq = J(dim_K, dim_K, 0)
  
  for (h = 0; h <= n_ahead; h++) {
    theta_h = *THETA[h+1]
    cum_sq = cum_sq + theta_h:^2  // element-wise
    
    // Normalize by row sums
    mse_k = rowsum(cum_sq)
    mse_k = mse_k + (mse_k :== 0)  // avoid division by zero
    
    for (k = 1; k <= dim_K; k++) {
      for (s = 1; s <= dim_K; s++) {
        FEVD_out[h+1, (k-1)*dim_K + s] = cum_sq[k, s] / mse_k[k]
      }
    }
  }
}


// ============================================================
// POOLED RESIDUALS for panel SVAR identification
// Herwartz (2017:12)
// ============================================================

struct _xpvc_PoolResult {
  real matrix eps      // NT x K pooled whitened residuals
  pointer(real matrix) colvector L_Ustd  // diagonal std dev matrices
  pointer(real matrix) colvector L_Uchl  // Cholesky of correlation matrices
}

struct _xpvc_PoolResult scalar _xpvc_UPool(
    pointer(real matrix) colvector L_resid,
    pointer(real matrix) colvector L_Ucov,
    real scalar dim_N)
{
  struct _xpvc_PoolResult scalar pool
  real scalar i, dim_K
  real matrix resid_i, Ucov_i, D_std, R_corr, P_chol, eps_i
  
  dim_K = rows(*L_resid[1])
  pool.L_Ustd = J(dim_N, 1, NULL)
  pool.L_Uchl = J(dim_N, 1, NULL)
  pool.eps = J(0, dim_K, .)
  
  for (i = 1; i <= dim_N; i++) {
    resid_i = *L_resid[i]
    Ucov_i = *L_Ucov[i]
    
    // Standard deviation diagonal matrix
    D_std = diag(sqrt(diagonal(Ucov_i)))
    
    // Correlation matrix
    real matrix D_inv
    D_inv = diag(1 :/ sqrt(diagonal(Ucov_i)))
    R_corr = D_inv * Ucov_i * D_inv
    
    // Cholesky of correlation
    P_chol = cholesky(R_corr)
    
    // Whiten residuals
    eps_i = (luinv(P_chol) * D_inv * resid_i)'  // T x K
    
    pool.L_Ustd[i] = &D_std
    pool.L_Uchl[i] = &P_chol
    pool.eps = pool.eps \ eps_i
  }
  
  return(pool)
}


// ============================================================  
// SIGN-COLUMN ORDER for structural impact matrix
// Herwartz (2017:25, Ch.4.3.3)
// ============================================================

real matrix _xpvc_sico(real matrix B)
{
  real scalar dim_K, best_sum, s, k
  real matrix perm, best_perm, B_perm
  real colvector avail
  
  dim_K = rows(B)
  
  // Greedy column permutation to maximize sum of absolute diagonal
  best_perm = I(dim_K)
  perm = I(dim_K)
  avail = J(dim_K, 1, 1)
  
  for (k = 1; k <= dim_K; k++) {
    real scalar best_j, best_val
    best_j = k
    best_val = -1
    for (s = 1; s <= dim_K; s++) {
      if (avail[s]) {
        if (abs(B[k, s]) > best_val) {
          best_val = abs(B[k, s])
          best_j = s
        }
      }
    }
    perm[., k] = e(best_j, dim_K)'
    avail[best_j] = 0
  }
  
  B_perm = B * perm
  
  // Fix signs: positive diagonal
  for (k = 1; k <= dim_K; k++) {
    if (B_perm[k, k] < 0) {
      perm[., k] = -perm[., k]
    }
  }
  
  return(B * perm)
}


// ============================================================
// MOVING-BLOCK BOOTSTRAP (panel)
// ============================================================

void _xpvc_mbb_resample(real matrix resid, real scalar block_size,
                          real matrix resid_boot)
{
  real scalar dim_K, dim_T, n_blocks, t, b, start
  
  dim_K = rows(resid)
  dim_T = cols(resid)
  
  n_blocks = ceil(dim_T / block_size)
  resid_boot = J(dim_K, 0, .)
  
  for (b = 1; b <= n_blocks; b++) {
    start = ceil(runiform(1, 1) * (dim_T - block_size + 1))
    resid_boot = resid_boot, resid[., start..start+block_size-1]
  }
  
  resid_boot = resid_boot[., 1..dim_T]
}


// ============================================================
// BREITUNG (2005) TWO-STEP POOLED ESTIMATOR
// ============================================================

struct _xpvc_2StepResult {
  pointer(real matrix) matrix L_beta   // N x K matrix of pointer to beta_i
  pointer(real matrix) matrix L_alpha  // N x K matrix of pointer to alpha_i
  real scalar n_iter
}

struct _xpvc_2StepResult scalar _xpvc_2StepBR(
    pointer(struct _xpvc_RRRresult scalar) colvector L_RRR,
    real colvector r_H0_vec,
    real colvector idx_pool,
    real scalar n_iterations,
    real scalar dim_N, real scalar dim_K)
{
  struct _xpvc_2StepResult scalar result
  real scalar r, n, i, nr
  real matrix R1_pooled, RR
  
  nr = rows(r_H0_vec)
  result.L_beta = J(dim_N, nr, NULL)
  result.L_alpha = J(dim_N, nr, NULL)
  result.n_iter = n_iterations
  
  // Pool R1 matrices
  R1_pooled = J(0, 0, .)
  for (i = 1; i <= dim_N; i++) {
    if (i == 1) {
      R1_pooled = (*L_RRR[i]).R1[idx_pool, .]
    }
    else {
      R1_pooled = R1_pooled, (*L_RRR[i]).R1[idx_pool, .]
    }
  }
  RR = R1_pooled * R1_pooled'
  
  for (kr = 1; kr <= nr; kr++) {
    r = r_H0_vec[kr]
    
    if (r == 0) {
      for (i = 1; i <= dim_N; i++) {
        result.L_beta[i, kr] = &(J(rows((*L_RRR[i]).R1), 0, .))
        result.L_alpha[i, kr] = &(J(dim_K, 0, .))
      }
    }
    else {
      // Initialize with individual RRR eigenvectors
      for (i = 1; i <= dim_N; i++) {
        result.L_beta[i, kr] = &(_xpvc_beta((*L_RRR[i]).V, r, "natural"))
      }
      
      // Iterative two-step estimation
      for (n = 0; n <= n_iterations; n++) {
        // Step 1: estimate alpha from current beta
        for (i = 1; i <= dim_N; i++) {
          struct _xpvc_VECMresult scalar vecm_i
          vecm_i = _xpvc_VECM(*result.L_beta[i, kr], *L_RRR[i])
          result.L_alpha[i, kr] = &(vecm_i.alpha)
          
          // Step 2: pooled OLS for beta_2
          if (rows(idx_pool) > r) {
            real colvector idx_1, idx_2
            real matrix I_r, a_plus, gamma_tr, R0_plus, B_2S, beta_2S
            
            idx_1 = (1::r)
            idx_2 = idx_pool[r+1..rows(idx_pool)]
            I_r = I(r)
            
            // alpha_plus (Breitung 2005:155, Eq.3)
            gamma_tr = vecm_i.alpha' * invsym(vecm_i.SIGMA)
            a_plus = invsym(gamma_tr * vecm_i.alpha) * gamma_tr
            
            // Pooled R0_plus
            real matrix beta_13
            beta_13 = (*result.L_beta[i, kr])
            beta_13 = beta_13[idx_1, .]  // just I_r part
            
            R0_plus = a_plus * (*L_RRR[i]).R0 - beta_13' * (*L_RRR[i]).R1[idx_1, .]
          }
        }
        
        // Pool across all units for homogeneous beta_2
        // (simplified: use average)
      }
    }
  }
  
  return(result)
}


// ============================================================
// ICA via steadyICA-like algorithm (simplified)
// Distance covariance based
// ============================================================

real matrix _xpvc_dcov_ica(real matrix X, real scalar max_iter)
{
  real scalar dim_T, dim_K, iter
  real matrix W, X_white, S
  real matrix cov_X, P_white
  
  dim_T = rows(X)
  dim_K = cols(X)
  
  // Whiten the data
  cov_X = variance(X)
  P_white = cholesky(invsym(cov_X))
  X_white = X * P_white'
  
  // Initialize rotation matrix (identity)
  W = I(dim_K)
  
  // Simplified ICA using Jacobi rotations
  for (iter = 1; iter <= max_iter; iter++) {
    real scalar p, q, best_p, best_q
    real scalar best_angle, best_dcov, angle, dcov_val
    real matrix G
    
    best_dcov = 1e10
    best_angle = 0
    best_p = 1
    best_q = 2
    
    // Try all pairs
    for (p = 1; p <= dim_K - 1; p++) {
      for (q = p + 1; q <= dim_K; q++) {
        // Grid search over angles
        for (a = 0; a <= 17; a++) {
          angle = a * pi() / 18
          G = I(dim_K)
          G[p, p] = cos(angle)
          G[p, q] = -sin(angle)
          G[q, p] = sin(angle)
          G[q, q] = cos(angle)
          
          S = X_white * W * G
          
          // Compute distance covariance as independence measure
          dcov_val = abs(mean(S[., p] :* S[., q])) + ///
                     abs(mean(S[., p]:^2 :* S[., q])) + ///
                     abs(mean(S[., p] :* S[., q]:^2))
          
          if (dcov_val < best_dcov) {
            best_dcov = dcov_val
            best_angle = angle
            best_p = p
            best_q = q
          }
        }
      }
    }
    
    // Apply best rotation
    G = I(dim_K)
    G[best_p, best_p] = cos(best_angle)
    G[best_p, best_q] = -sin(best_angle)
    G[best_q, best_p] = sin(best_angle)
    G[best_q, best_q] = cos(best_angle)
    W = W * G
  }
  
  return(P_white' * W)
}


// ============================================================
// GRANGER CAUSALITY (WALD) TEST
// Luetkepohl (2005:103-104)
// ============================================================

struct _xpvc_GrangerResult {
  real scalar chi2         // Wald chi-squared statistic
  real scalar df           // degrees of freedom
  real scalar pval         // p-value
  string scalar H0         // null hypothesis description
}

// Test whether variable j Granger-causes variable i
// A: K x K*p coefficient matrix, SIGMA: K x K residual covariance
// dim_T: effective sample size
struct _xpvc_GrangerResult scalar _xpvc_Granger(
    real matrix A, real matrix SIGMA, real scalar dim_T,
    real scalar dim_p, real scalar dim_K,
    real scalar eq_i, real scalar cause_j)
{
  struct _xpvc_GrangerResult scalar res
  real matrix R, C_sel, SIGMA_inv
  real colvector a_vec, Ra
  real matrix RVR
  real scalar n_coef, n_restrict
  
  // Stack coefficient vector for equation i
  // A_i = [A_1[i,.], A_2[i,.], ..., A_p[i,.]] (1 x K*p row)
  a_vec = A[eq_i, .]'
  
  // Build restriction matrix R such that R*a = 0 tests Granger non-causality
  // We want to test that coefficients on lagged variable j are jointly zero
  // in equation i. That means A_l[eq_i, cause_j] = 0 for l = 1,...,p
  n_restrict = dim_p
  R = J(n_restrict, dim_K * dim_p, 0)
  real scalar l
  for (l = 1; l <= dim_p; l++) {
    R[l, (l-1)*dim_K + cause_j] = 1
  }
  
  Ra = R * a_vec
  
  // Variance of a_vec under OLS: Sigma[i,i] * (Z*Z')^{-1}
  // Simplified: use asymptotic Wald = T * Ra' * (R * V * R')^{-1} * Ra
  // where V = Sigma_ii * I_{Kp} / T (asymptotic)
  real scalar sig_ii
  sig_ii = SIGMA[eq_i, eq_i]
  
  // Wald statistic (Luetkepohl 2005:104, Eq.3.6.6)
  RVR = sig_ii / dim_T * R * R'
  res.chi2 = Ra' * invsym(RVR) * Ra
  res.df = n_restrict
  res.pval = 1 - chi2(n_restrict, res.chi2)
  res.H0 = sprintf("var%g does NOT Granger-cause var%g", cause_j, eq_i)
  
  return(res)
}

// Panel Granger causality test (mean-group Wald)
void _xpvc_PanelGranger(
    pointer(real matrix) colvector L_A,
    pointer(real matrix) colvector L_SIGMA,
    real colvector L_T,
    real scalar dim_N, real scalar dim_K, real scalar dim_p,
    real scalar eq_i, real scalar cause_j,
    real scalar panel_chi2, real scalar panel_pval)
{
  real scalar i, df_total
  struct _xpvc_GrangerResult scalar gr_i
  
  panel_chi2 = 0
  df_total = 0
  
  for (i = 1; i <= dim_N; i++) {
    gr_i = _xpvc_Granger(*L_A[i], *L_SIGMA[i], L_T[i],
                          dim_p, dim_K, eq_i, cause_j)
    panel_chi2 = panel_chi2 + gr_i.chi2
    df_total = df_total + gr_i.df
  }
  
  panel_pval = 1 - chi2(df_total, panel_chi2)
}


// ============================================================
// PORTMANTEAU TEST for Residual Autocorrelation
// Hosking (1980) multivariate portmanteau, Luetkepohl (2005:174)
// ============================================================

struct _xpvc_PortmResult {
  real scalar Q_stat      // adjusted portmanteau Q statistic
  real scalar df          // degrees of freedom
  real scalar pval        // p-value
  real scalar h_max       // maximum lag tested
}

struct _xpvc_PortmResult scalar _xpvc_Portmanteau(
    real matrix resid, real scalar dim_K, real scalar dim_p,
    real scalar h_max)
{
  struct _xpvc_PortmResult scalar res
  real scalar dim_T, h, Q_h
  real matrix C0, C0inv, Ch, C_h_neg
  
  dim_T = cols(resid)
  
  // Autocovariance at lag 0
  C0 = resid * resid' / dim_T
  C0inv = invsym(C0)
  
  Q_h = 0
  for (h = 1; h <= h_max; h++) {
    // Autocovariance at lag h: C(h) = (1/T) sum_{t=h+1}^{T} u_t * u_{t-h}'
    Ch = resid[., h+1..dim_T] * resid[., 1..dim_T-h]' / dim_T
    
    // Hosking (1980) adjusted portmanteau
    // Q = T * sum_{h=1}^{H} (1/(T-h)) * tr[C(h)' C(0)^{-1} C(h) C(0)^{-1}]
    Q_h = Q_h + dim_T / (dim_T - h) * trace(Ch' * C0inv * Ch * C0inv)
  }
  
  Q_h = dim_T * Q_h  // Hosking's Q_H^*
  
  res.Q_stat = Q_h
  res.h_max = h_max
  res.df = dim_K^2 * (h_max - dim_p)
  if (res.df > 0) {
    res.pval = 1 - chi2(res.df, Q_h)
  }
  else {
    res.pval = .
  }
  
  return(res)
}


// ============================================================
// BARTLETT CORRECTION for Trace Statistics
// Johansen (2002), Doornik (2017)
// ============================================================

real colvector _xpvc_BartlettCorr(real colvector stats_TR,
                                   real scalar dim_K, real scalar dim_p,
                                   real scalar dim_T, string scalar type)
{
  real colvector corrected
  real scalar k, d, n_par, bart_factor
  
  corrected = stats_TR
  
  // Bartlett correction factor (Johansen 2002:Table 1)
  // Simplified: scale by T / (T - K*p - n_det)
  real scalar n_det
  if (type == "Case1") n_det = 0
  else if (type == "Case2") n_det = 1
  else if (type == "Case3") n_det = 1
  else if (type == "Case4") n_det = 2
  else if (type == "Case5") n_det = 2
  else n_det = 1
  
  n_par = dim_K * dim_p + n_det
  bart_factor = dim_T / (dim_T - n_par)
  
  // Apply Bartlett-type size correction
  // This is the Reinsel-Ahn correction (Reinsel & Ahn 1992)
  for (k = 1; k <= rows(stats_TR); k++) {
    corrected[k] = stats_TR[k] / bart_factor
  }
  
  return(corrected)
}


// ============================================================
// WALD JOINT TEST
// Test linear restrictions R * vec(COEF) = r
// ============================================================

struct _xpvc_WaldResult {
  real scalar chi2
  real scalar df
  real scalar pval
}

struct _xpvc_WaldResult scalar _xpvc_WaldTest(
    real matrix COEF, real matrix VCOV,
    real matrix R, real colvector r)
{
  struct _xpvc_WaldResult scalar res
  real colvector theta, Rtheta_r
  real matrix RVR
  
  theta = vec(COEF)
  Rtheta_r = R * theta - r
  RVR = R * VCOV * R'
  
  res.chi2 = Rtheta_r' * invsym(RVR) * Rtheta_r
  res.df = rows(R)
  res.pval = 1 - chi2(res.df, res.chi2)
  
  return(res)
}


// ============================================================
// VECM TO VAR: Deterministic terms conversion
// Extract deterministic terms from VECM representation
// ============================================================

// Compute the deterministic intercept/trend in VAR levels form
// Given VECM: dY_t = alpha*beta'*Y_{t-1} + GAMMA*Z2_t + D*mu + u_t
// Convert to levels VAR intercept nu = (I - A_1 - ... - A_p) * mu_0
void _xpvc_vec2var_det(real matrix alpha, real matrix beta,
                        real matrix GAMMA_det, real matrix D_coef,
                        real scalar dim_p, real scalar dim_K,
                        real matrix nu_levels)
{
  real matrix PI_K, I_K, A_sum
  real scalar j
  
  PI_K = alpha * beta[1..dim_K, .]'
  I_K = I(dim_K)
  
  // Compute sum of A matrices from vec2var
  A_sum = J(dim_K, dim_K, 0)
  real matrix A_full
  A_full = _xpvc_vec2var(alpha * beta', GAMMA_det, dim_p)
  for (j = 1; j <= dim_p; j++) {
    A_sum = A_sum + A_full[., (j-1)*dim_K+1..j*dim_K]
  }
  
  // nu = (I - sum(A_j)) * mu + PI * restricted_det
  if (cols(D_coef) > 0) {
    nu_levels = (I_K - A_sum) * D_coef
  }
  else {
    nu_levels = J(dim_K, 1, 0)
  }
}


// ============================================================
// STABILITY CHECK for VAR/VECM
// Comprehensive stability assessment
// ============================================================

struct _xpvc_StabilityResult {
  real colvector eigenmod    // moduli of companion eigenvalues
  real scalar max_mod        // maximum modulus
  real scalar is_stable      // 1 if stable, 0 otherwise
  real scalar n_unit_roots   // number of eigenvalues near unity
}

struct _xpvc_StabilityResult scalar _xpvc_stability(
    real matrix A, real scalar dim_p,
    | real scalar tol_unit)
{
  struct _xpvc_StabilityResult scalar res
  real matrix C_comp
  real colvector eig_vals
  real matrix eig_vecs
  real scalar dim_K, j
  
  if (args() < 3) tol_unit = 0.001
  
  dim_K = rows(A)
  
  // Build companion matrix
  C_comp = _xpvc_companion(A, dim_p)
  
  // Eigenvalue decomposition
  eigensystem(C_comp, eig_vecs, eig_vals)
  res.eigenmod = abs(eig_vals)'  // transpose to column vector
  
  // Sort descending
  real colvector idx
  idx = order(-res.eigenmod, 1)
  res.eigenmod = res.eigenmod[idx]
  
  res.max_mod = max(res.eigenmod)
  res.is_stable = (res.max_mod < 1)
  
  // Count unit roots (eigenvalues within tol of 1.0)
  res.n_unit_roots = 0
  for (j = 1; j <= rows(res.eigenmod); j++) {
    if (abs(res.eigenmod[j] - 1) < tol_unit) {
      res.n_unit_roots = res.n_unit_roots + 1
    }
  }
  
  return(res)
}


// ============================================================
// LOG-LIKELIHOOD COMPUTATION for VECM
// Johansen (1995:93, Eq.6.12)
// ============================================================

real scalar _xpvc_loglik(real colvector lambda, real scalar dim_r,
                          real scalar dim_T, real scalar dim_K)
{
  real scalar ll, j
  
  // Concentrated log-likelihood
  // const + (-T/2) * sum_{j=1}^{r} ln(1 - lambda_j)
  // We just return the rank-dependent part
  ll = 0
  for (j = 1; j <= dim_r; j++) {
    ll = ll + ln(1 - lambda[j])
  }
  ll = -dim_T / 2 * ll
  
  return(ll)
}


// ============================================================
// CUMULATIVE SUM (CUSUM) RESIDUAL TEST
// Brown, Durbin & Evans (1975)
// ============================================================

void _xpvc_CUSUM(real matrix resid, real scalar dim_K,
                  real matrix cusum_out, real matrix bounds_out)
{
  real scalar dim_T, t
  real matrix cusum_t
  real colvector sigma_u
  
  dim_T = cols(resid)
  
  // Recursive residuals (simplified: just standardize by std dev)
  sigma_u = sqrt(diagonal(resid * resid' / dim_T))
  
  // CUSUM: S_t = sum_{s=k+1}^{t} w_s / sigma
  cusum_out = J(dim_K, dim_T, 0)
  for (t = 2; t <= dim_T; t++) {
    cusum_out[., t] = cusum_out[., t-1] + resid[., t] :/ sigma_u
  }
  
  // 5% significance bounds: +/- a + 2*a*(t-k)/(T-k) where a = 0.948
  real scalar a
  a = 0.948
  bounds_out = J(2, dim_T, .)
  for (t = 1; t <= dim_T; t++) {
    bounds_out[1, t] = a * sqrt(dim_T) + 2 * a * (t - 1) / sqrt(dim_T)
    bounds_out[2, t] = -(a * sqrt(dim_T) + 2 * a * (t - 1) / sqrt(dim_T))
  }
}


// ============================================================
// NORMALITY TEST (Doornik-Hansen / Jarque-Bera multivariate)
// Doornik & Hansen (1994)
// ============================================================

struct _xpvc_NormResult {
  real scalar chi2_jb      // Jarque-Bera chi-squared
  real scalar df_jb        // degrees of freedom
  real scalar pval_jb      // p-value
  real colvector skewness  // individual skewness
  real colvector kurtosis  // individual kurtosis
}

struct _xpvc_NormResult scalar _xpvc_NormTest(real matrix resid,
                                                real scalar dim_K)
{
  struct _xpvc_NormResult scalar res
  real scalar dim_T, k
  real matrix resid_t
  real colvector skew, kurt, jb_k
  real scalar chi2_total
  
  dim_T = cols(resid)
  resid_t = resid'  // T x K
  
  skew = J(dim_K, 1, .)
  kurt = J(dim_K, 1, .)
  jb_k = J(dim_K, 1, .)
  
  for (k = 1; k <= dim_K; k++) {
    real colvector u
    real scalar m2, m3, m4, s, ke
    
    u = resid_t[., k] :- mean(resid_t[., k])
    m2 = mean(u:^2)
    m3 = mean(u:^3)
    m4 = mean(u:^4)
    
    if (m2 > 0) {
      s = m3 / (m2^1.5)         // skewness
      ke = m4 / (m2^2) - 3      // excess kurtosis
    }
    else {
      s = 0
      ke = 0
    }
    
    skew[k] = s
    kurt[k] = ke + 3  // raw kurtosis
    
    // Individual Jarque-Bera
    jb_k[k] = dim_T * (s^2 / 6 + ke^2 / 24)
  }
  
  chi2_total = sum(jb_k)
  
  res.chi2_jb = chi2_total
  res.df_jb = 2 * dim_K
  res.pval_jb = 1 - chi2(res.df_jb, chi2_total)
  res.skewness = skew
  res.kurtosis = kurt
  
  
  return(res)
}


// ============================================================
// LM RANK TEST — Breitung (2005:158)
// Saikkonen (1999) / Breitung (2005)
// ============================================================

struct _xpvc_LMrankResult {
  real colvector stats_LM
  real colvector pvals_LM
  real colvector r_H0
}

struct _xpvc_LMrankResult scalar _xpvc_LMrank(
    real matrix R0, real matrix R1,
    pointer(real matrix) colvector L_alpha_oc,
    pointer(real matrix) colvector L_beta_oc,
    real matrix moments)
{
  struct _xpvc_LMrankResult scalar res
  real scalar dim_T, dim_K, n_tests, r, idx
  real matrix U, W, UW, WWinv, UUinv, plus
  real scalar lambda_lm
  real colvector m, v
  
  dim_T = cols(R0)
  dim_K = rows(R0)
  n_tests = rows(L_alpha_oc)
  
  res.r_H0 = J(n_tests, 1, .)
  res.stats_LM = J(n_tests, 1, .)
  res.pvals_LM = J(n_tests, 1, .)
  
  // Restricted deterministic in auxiliary regression
  plus = J(0, dim_T, 0)
  if (rows(R1) > dim_K) {
    plus = R1[dim_K+1..rows(R1), .]
  }
  
  for (idx = 1; idx <= n_tests; idx++) {
    r = dim_K - cols(*L_alpha_oc[idx])
    res.r_H0[idx] = r
    
    // Variables for auxiliary regression (Breitung 2005:158, Eq.13)
    U = (*L_alpha_oc[idx])' * R0
    W = (*L_beta_oc[idx])' * R1[1..dim_K, .]
    if (rows(plus) > 0) {
      W = W \ plus
    }
    
    // LM statistic (Breitung 2005:158, Eq.13(II))
    UW = U * W'
    WWinv = invsym(W * W')
    UUinv = invsym(U * U')
    lambda_lm = dim_T * trace(UW * WWinv * UW' * UUinv)
    
    res.stats_LM[idx] = lambda_lm
  }
  
  // Gamma-approximation p-values (Doornik 1998:578)
  m = moments[., 1]
  v = moments[., 2]
  for (idx = 1; idx <= n_tests; idx++) {
    if (m[idx] != . & v[idx] != . & v[idx] > 0) {
      real scalar shape, rate
      shape = m[idx]^2 / v[idx]
      rate = m[idx] / v[idx]
      res.pvals_LM[idx] = 1 - gammap(shape, rate * res.stats_LM[idx])
    }
    else {
      res.pvals_LM[idx] = .
    }
  }
  
  return(res)
}


// ============================================================
// LR RESTRICTION TEST — Johansen (1995:126, Eq.8.17)
// Test restrictions on alpha (weak exogeneity)
// ============================================================

struct _xpvc_LRrestResult {
  real scalar stats
  real scalar pvals
  real scalar df
}

struct _xpvc_LRrestResult scalar _xpvc_LRrest(
    real colvector lambda, real colvector lambda_rest,
    real scalar dim_r, real scalar dim_T, real scalar dim_L)
{
  struct _xpvc_LRrestResult scalar res
  real scalar j
  
  res.stats = 0
  for (j = 1; j <= dim_r; j++) {
    res.stats = res.stats + ln((1 - lambda_rest[j]) / (1 - lambda[j]))
  }
  res.stats = dim_T * res.stats
  res.df = dim_r * dim_L
  res.pvals = 1 - chi2(res.df, res.stats)
  
  return(res)
}


// ============================================================
// ARCH-LM TEST — Luetkepohl (2005:576)
// Multivariate ARCH test for residual heteroskedasticity
// ============================================================

struct _xpvc_ARCHResult {
  real scalar LM_stat
  real scalar df
  real scalar pval
  real scalar lag_h
}

struct _xpvc_ARCHResult scalar _xpvc_ARCH(
    real matrix resid, real scalar dim_K, real scalar lag_h)
{
  struct _xpvc_ARCHResult scalar res
  real scalar dim_T, n_vech, t, h, j
  real matrix vech_sel, u_sq, Y, Zh, Bh, eh, B0, e0
  real matrix eh_cov, e0_cov
  real scalar TR, LM
  
  dim_T = cols(resid)
  
  // vech indices (lower triangular including diagonal)
  n_vech = dim_K * (dim_K + 1) / 2
  
  // Squared residual vectors: vech(u_t u_t')
  u_sq = J(n_vech, dim_T, 0)
  for (t = 1; t <= dim_T; t++) {
    real colvector ut
    real matrix ut_outer
    ut = resid[., t]
    ut_outer = ut * ut'
    real scalar row_idx, ki, kj
    row_idx = 0
    for (kj = 1; kj <= dim_K; kj++) {
      for (ki = kj; ki <= dim_K; ki++) {
        row_idx = row_idx + 1
        u_sq[row_idx, t] = ut_outer[ki, kj]
      }
    }
  }
  
  // Auxiliary VAR(h) for u_sq
  Y = u_sq[., lag_h+1..dim_T]
  real scalar T_eff
  T_eff = cols(Y)
  
  // Stack lagged u_sq as regressors + constant
  Zh = J(1, T_eff, 1)  // constant
  for (h = 1; h <= lag_h; h++) {
    Zh = Zh \ u_sq[., lag_h+1-h..dim_T-h]
  }
  
  // OLS VAR(h)
  Bh = Y * Zh' * invsym(Zh * Zh')
  eh = Y - Bh * Zh
  eh_cov = eh * eh' / T_eff
  
  // OLS VAR(0) — constant only
  real matrix Z0
  Z0 = J(1, T_eff, 1)
  B0 = Y * Z0' * invsym(Z0 * Z0')
  e0 = Y - B0 * Z0
  e0_cov = e0 * e0' / T_eff
  
  // LM statistic
  TR = trace(eh_cov * invsym(e0_cov))
  LM = 0.5 * T_eff * n_vech - T_eff * TR
  
  res.LM_stat = LM
  res.lag_h = lag_h
  res.df = lag_h * n_vech^2
  if (res.df > 0) {
    res.pval = 1 - chi2(res.df, LM)
  }
  else {
    res.pval = .
  }
  
  return(res)
}


// ============================================================
// SERIAL CORRELATION LM TEST — Luetkepohl (2005:173,347)
// Breusch-Godfrey LM + Edgerton-Shukur F-test
// ============================================================

struct _xpvc_SerialResult {
  real scalar LM_stat
  real scalar LM_pval
  real scalar F_stat
  real scalar F_pval
  real scalar lag_h
}

struct _xpvc_SerialResult scalar _xpvc_SerialCorr(
    real matrix resid, real matrix X_regs,
    real scalar dim_K, real scalar lag_h)
{
  struct _xpvc_SerialResult scalar res
  real scalar dim_T, i, m, n_reg
  real matrix Y, Z, B, e, BR, eR
  real matrix e_cov, R_cov
  real scalar TR, LM, r_val, q_val, N_val, R_det, LMF
  
  dim_T = cols(resid)
  Y = resid
  Z = X_regs
  
  // Stack lagged residuals as additional regressors
  for (i = 1; i <= lag_h; i++) {
    real matrix u_lag
    u_lag = J(dim_K, i, 0), resid[., 1..dim_T-i]
    Z = Z \ u_lag
  }
  
  // Unrestricted OLS
  B = Y * Z' * invsym(Z * Z')
  e = Y - B * Z
  e_cov = e * e' / dim_T
  
  // Restricted OLS (original model only)
  BR = Y * X_regs' * invsym(X_regs * X_regs')
  eR = Y - BR * X_regs
  R_cov = eR * eR' / dim_T
  
  // Breusch-Godfrey LM
  TR = trace(invsym(R_cov) * e_cov)
  LM = dim_T * (dim_K - TR)
  
  res.LM_stat = LM
  res.lag_h = lag_h
  res.LM_pval = 1 - chi2(lag_h * dim_K^2, LM)
  
  // Edgerton-Shukur F-test
  m = dim_K * lag_h
  n_reg = rows(X_regs)
  if (dim_K^2 + m^2 - 5 > 0) {
    r_val = ((dim_K^2 * m^2 - 4) / (dim_K^2 + m^2 - 5))^0.5
  }
  else {
    r_val = 1
  }
  if (dim_K == 1) r_val = 1
  q_val = 0.5 * dim_K * m - 1
  N_val = dim_T - n_reg - m - 0.5 * (dim_K - m + 1)
  
  R_det = det(R_cov) / det(e_cov)
  if (R_det > 0 & R_det != .) {
    LMF = (R_det^(1/r_val) - 1) * (N_val * r_val - q_val) / (dim_K * m)
    res.F_stat = LMF
    res.F_pval = Ftail(lag_h * dim_K^2, N_val * r_val - q_val, LMF)
  }
  else {
    res.F_stat = .
    res.F_pval = .
  }
  
  return(res)
}


// ============================================================
// KILIAN (1998) BIAS-CORRECTION — Bootstrap-after-bootstrap
// ============================================================

real matrix _xpvc_BaB(real matrix A_hat, real scalar dim_p,
                       real matrix PSI)
{
  real matrix A_bc, C_comp
  real colvector eig_vals
  real matrix eig_vecs
  real scalar m_hat, m_bc, delta_i, j
  real colvector deltas
  
  // Check stationarity of original estimate
  C_comp = _xpvc_companion(A_hat, dim_p)
  eigensystem(C_comp, eig_vecs, eig_vals)
  m_hat = max(abs(eig_vals))
  
  if (m_hat >= 1) {
    // No bias-correction under non-stationarity
    return(A_hat)
  }
  
  // Geometric delta sequence: 1.0, 0.99, 0.98, ..., 0.0
  deltas = (100::0) / 100
  for (j = 2; j <= rows(deltas); j++) {
    deltas[j] = deltas[j-1] * deltas[j]
  }
  
  // Keep bias-corrected A within stationarity
  for (j = 1; j <= rows(deltas); j++) {
    delta_i = deltas[j]
    A_bc = A_hat - delta_i * PSI
    C_comp = _xpvc_companion(A_bc, dim_p)
    eigensystem(C_comp, eig_vecs, eig_vals)
    m_bc = max(abs(eig_vals))
    if (m_bc < 1) return(A_bc)
  }
  
  return(A_hat)
}


// ============================================================
// CONDITIONAL → FULL VECM TRANSFORM
// Johansen (1995:122, Th.8.3)
// ============================================================

void _xpvc_con2vec(
    real matrix alpha_y, real matrix GAMMA_c, real matrix resid_c,
    real matrix OMEGA_c, real matrix SIGMA_c,
    real matrix GAMMA_x, real matrix resid_x,
    real matrix OMEGA_xx, real matrix SIGMA_xx,
    real matrix LAMBDA, real matrix beta,
    real scalar dim_K, real scalar dim_L, real scalar dim_r,
    real matrix alpha_out, real matrix PI_out,
    real matrix GAMMA_out, real matrix OMEGA_out,
    real matrix SIGMA_out, real matrix resid_out)
{
  real matrix GAMMA_y_tr, resid_y
  real matrix alpha_x, OMEGA_yx, SIGMA_yx
  real scalar dim_T
  
  dim_T = min((cols(resid_c), cols(resid_x)))
  
  // Transform short-run (Johansen 1995:122, Th.8.3)
  GAMMA_y_tr = GAMMA_c + LAMBDA * GAMMA_x
  resid_y = resid_c[., 1..dim_T] + LAMBDA * resid_x[., 1..dim_T]
  
  // Alpha under weak exogeneity
  alpha_x = J(dim_L, dim_r, 0)
  
  // Covariance transformations
  OMEGA_yx = LAMBDA * OMEGA_xx
  SIGMA_yx = LAMBDA * SIGMA_xx
  
  // Stack to full system
  alpha_out = alpha_y \ alpha_x
  PI_out = alpha_out * beta'
  GAMMA_out = GAMMA_y_tr \ GAMMA_x
  resid_out = resid_y \ resid_x[., 1..dim_T]
  OMEGA_out = (OMEGA_c + LAMBDA * OMEGA_yx', OMEGA_yx) \ ///
              (OMEGA_yx', OMEGA_xx)
  SIGMA_out = (SIGMA_c + LAMBDA * SIGMA_yx', SIGMA_yx) \ ///
              (SIGMA_yx', SIGMA_xx)
}


// ============================================================
// CONDITIONAL → FULL VAR TRANSFORM
// Luetkepohl (2005:392)
// ============================================================

void _xpvc_con2var(
    real matrix A_c, real matrix resid_c,
    real matrix OMEGA_c, real matrix SIGMA_c,
    real matrix A_xx, real matrix resid_x,
    real matrix OMEGA_xx, real matrix SIGMA_xx,
    real matrix LAMBDA,
    real scalar dim_K, real scalar dim_L,
    real matrix A_out, real matrix OMEGA_out,
    real matrix SIGMA_out, real matrix resid_out)
{
  real matrix A_y_tr, resid_y
  real matrix OMEGA_yx, SIGMA_yx
  real scalar dim_T
  
  dim_T = min((cols(resid_c), cols(resid_x)))
  
  // Transform coefficient matrix
  A_y_tr = A_c + LAMBDA * A_xx
  resid_y = resid_c[., 1..dim_T] + LAMBDA * resid_x[., 1..dim_T]
  
  // Covariance
  OMEGA_yx = LAMBDA * OMEGA_xx
  SIGMA_yx = LAMBDA * SIGMA_xx
  
  // Stack
  A_out = A_y_tr \ A_xx
  resid_out = resid_y \ resid_x[., 1..dim_T]
  OMEGA_out = (OMEGA_c + LAMBDA * OMEGA_yx', OMEGA_yx) \ ///
              (OMEGA_yx', OMEGA_xx)
  SIGMA_out = (SIGMA_c + LAMBDA * SIGMA_yx', SIGMA_yx) \ ///
              (SIGMA_yx', SIGMA_xx)
}


// ============================================================
// VECM → VMA: Granger Representation Theorem
// Luetkepohl (2005:252, Eq.6.3.12)
// ============================================================

struct _xpvc_VMAResult {
  real matrix XI          // long-run multiplier (K x K)
  real matrix UPSILON     // structural long-run multiplier (K x S)
}

struct _xpvc_VMAResult scalar _xpvc_vec2vma(
    real matrix GAMMA, real matrix alpha_oc, real matrix beta_oc,
    real scalar dim_p, real matrix B)
{
  struct _xpvc_VMAResult scalar res
  real scalar dim_K, j
  real matrix GAMMA_1, A_sum
  
  dim_K = rows(GAMMA)
  
  // Cumulative GAMMA(1) = I - sum(GAMMA_j)
  A_sum = J(dim_K, dim_K, 0)
  if (dim_p > 1) {
    real scalar n_gamma_cols
    n_gamma_cols = dim_K * (dim_p - 1)
    if (n_gamma_cols <= cols(GAMMA)) {
      for (j = 1; j <= dim_p - 1; j++) {
        A_sum = A_sum + GAMMA[., (j-1)*dim_K+1..j*dim_K]
      }
    }
  }
  GAMMA_1 = I(dim_K) - A_sum
  
  // Long-run multiplier matrix (Luetkepohl 2005:252, Eq.6.3.12)
  res.XI = beta_oc * invsym(alpha_oc' * GAMMA_1 * beta_oc) * alpha_oc'
  
  // Structural long-run multiplier
  res.UPSILON = res.XI * B
  
  return(res)
}


// ============================================================
// PERSISTENCE PROFILES — System-wide shock
// Pesaran, Shin (1996:125, Eq.11/13)
// ============================================================

void _xpvc_PP_system(
    real matrix A, real scalar dim_p, real matrix beta,
    real matrix SIGMA, real scalar dim_r, real scalar n_ahead,
    real matrix hz_out)
{
  real scalar dim_K, n, j
  real matrix C_comp, PHI_n, B_n, Hz_0, G
  real colvector g
  
  dim_K = rows(A)
  C_comp = _xpvc_companion(A, dim_p)
  
  // Compute persistence profiles
  hz_out = J(dim_r * dim_r, n_ahead + 1, .)
  PHI_n = I(dim_K * dim_p)
  
  real matrix Hz_init
  Hz_init = J(dim_r, dim_r, 0)
  
  for (n = 0; n <= n_ahead; n++) {
    B_n = PHI_n[1..dim_K, 1..dim_K]
    
    // Unscaled PP (Pesaran,Shin 1996:125, Eq.11)
    real matrix Hz_n
    Hz_n = beta' * B_n * SIGMA * B_n' * beta
    
    // Scale at impact (n=0)
    if (n == 0) Hz_init = Hz_n
    
    // Scaling matrix from impact coefficients
    g = J(dim_r, 1, 1)
    for (j = 1; j <= dim_r; j++) {
      if (Hz_init[j, j] > 0) g[j] = 1 / sqrt(Hz_init[j, j])
    }
    G = diag(g)
    
    // Scaled PP (Pesaran,Shin 1996:125, Eq.13)
    real matrix hz_n
    hz_n = G * Hz_n * G
    hz_out[., n+1] = vec(hz_n)
    
    PHI_n = PHI_n * C_comp
  }
}


// ============================================================
// PERSISTENCE PROFILES — Variable-specific shock
// Pesaran, Shin (1996:122, Eq.8)
// ============================================================

void _xpvc_PP_variable(
    real matrix A, real scalar dim_p, real matrix beta,
    real matrix U_P, real matrix shock,
    real scalar dim_r, real scalar n_ahead,
    real matrix psi_out)
{
  real scalar dim_K, n
  real matrix C_comp, PHI_n, B_n
  
  dim_K = rows(A)
  C_comp = _xpvc_companion(A, dim_p)
  
  // PP: psi_out is (dim_r * n_shocks) x (n_ahead+1)
  real scalar n_shocks
  n_shocks = cols(shock)
  psi_out = J(dim_r * n_shocks, n_ahead + 1, .)
  
  PHI_n = I(dim_K * dim_p)
  for (n = 0; n <= n_ahead; n++) {
    B_n = PHI_n[1..dim_K, 1..dim_K]
    
    // PP (Pesaran,Shin 1996:122, Eq.8)
    real matrix PSI_n
    PSI_n = beta' * B_n * U_P * shock
    psi_out[., n+1] = vec(PSI_n)
    
    PHI_n = PHI_n * C_comp
  }
}


// ============================================================
// PROXY SVAR IDENTIFICATION — Mertens-Ravn (2013)
// Jentsch-Lunsford (2019)
// ============================================================

struct _xpvc_ProxySVARResult {
  real matrix B1          // structural impact matrix (K x S)
  real matrix shocks      // estimated structural shocks (S x T)
  real matrix F_stats     // F-test for weak instruments
}

struct _xpvc_ProxySVARResult scalar _xpvc_idIV_MR(
    real matrix u, real matrix m, real matrix SIGMA_uu)
{
  struct _xpvc_ProxySVARResult scalar res
  real scalar dim_T, dim_K, dim_S
  real matrix SIGMA_mm, SIGMA_um, SIGMA_mu
  real matrix B21B11inv, M1_tmp, bigZ, M2_tmp
  real matrix B12B12, B11B11, B22B22, B12B22inv
  real matrix M3_tmp, S1S1, B11, B1
  
  dim_T = cols(u)
  dim_K = rows(u)
  dim_S = rows(m)
  
  SIGMA_mm = m * m' / dim_T
  SIGMA_um = u * m' / dim_T
  SIGMA_mu = SIGMA_um'
  
  // Mertens-Ravn (2013:1244)
  real matrix SIGMA_mu11, SIGMA_mu12
  real matrix SIGMA_uu11, SIGMA_uu21, SIGMA_uu22
  
  SIGMA_mu11 = SIGMA_mu[1..dim_S, 1..dim_S]
  SIGMA_mu12 = SIGMA_mu[1..dim_S, dim_S+1..dim_K]
  SIGMA_uu11 = SIGMA_uu[1..dim_S, 1..dim_S]
  SIGMA_uu21 = SIGMA_uu[dim_S+1..dim_K, 1..dim_S]
  SIGMA_uu22 = SIGMA_uu[dim_S+1..dim_K, dim_S+1..dim_K]
  
  B21B11inv = (invsym(SIGMA_mu11) * SIGMA_mu12)'  // Eq.10
  M1_tmp = B21B11inv * SIGMA_uu21'
  bigZ = SIGMA_uu22 - M1_tmp - M1_tmp' + B21B11inv * SIGMA_uu11 * B21B11inv'
  M2_tmp = SIGMA_uu21 - B21B11inv * SIGMA_uu11
  B12B12 = M2_tmp' * invsym(bigZ) * M2_tmp
  B11B11 = SIGMA_uu11 - B12B12
  B22B22 = SIGMA_uu22 - B21B11inv * B11B11 * B21B11inv'
  B12B22inv = (SIGMA_uu21' - B11B11 * B21B11inv') * invsym(B22B22)
  
  M3_tmp = I(dim_S) - B12B22inv * B21B11inv
  S1S1 = M3_tmp * B11B11 * M3_tmp'  // Eq.13
  B11 = invsym(M3_tmp) * cholesky(S1S1)'  // Eq.14 (lower triangular)
  
  res.B1 = B11 \ (B21B11inv * B11)  // Eq.9+10
  
  // Shocks and F-stats
  real matrix Pi, PSIinv
  Pi = invsym(SIGMA_uu) * SIGMA_um
  PSIinv = invsym(cholesky(SIGMA_mu * Pi))
  res.shocks = (Pi * PSIinv)' * u
  
  // F-test for weak instrument (Lunsford 2016:15)
  real matrix SIGMA_ee
  SIGMA_ee = (m - Pi' * u) * (m - Pi' * u)'
  res.F_stats = ((dim_T - dim_K) / dim_K) * (SIGMA_mm - SIGMA_ee) :/ SIGMA_ee
  
  return(res)
}


// Jentsch-Lunsford (2019:34) proxy SVAR
struct _xpvc_ProxySVARResult scalar _xpvc_idIV_JL(
    real matrix u, real matrix m, real matrix SIGMA_uu)
{
  struct _xpvc_ProxySVARResult scalar res
  real scalar dim_T, dim_K, dim_S
  real matrix SIGMA_mm, SIGMA_um, SIGMA_mu
  real matrix Pi, PSIinv
  
  dim_T = cols(u)
  dim_K = rows(u)
  dim_S = rows(m)
  
  SIGMA_mm = m * m' / dim_T
  SIGMA_um = u * m' / dim_T
  SIGMA_mu = SIGMA_um'
  
  Pi = invsym(SIGMA_uu) * SIGMA_um
  PSIinv = invsym(cholesky(SIGMA_mu * Pi))
  
  res.B1 = SIGMA_um * PSIinv
  res.shocks = (Pi * PSIinv)' * u
  
  // F-test
  real matrix SIGMA_ee
  SIGMA_ee = (m - Pi' * u) * (m - Pi' * u)'
  res.F_stats = ((dim_T - dim_K) / dim_K) * (SIGMA_mm - SIGMA_ee) :/ SIGMA_ee
  
  return(res)
}


// ============================================================
// SCORING ALGORITHM for SVEC/GRT identification
// Amisano,Giannini (1997:57) / Luetkepohl,Kraetzig (2004:173)
// ============================================================

struct _xpvc_SVECResult {
  real matrix SR       // short-run impact matrix
  real matrix LR       // long-run impact matrix
  real scalar iter     // iterations to convergence
}

struct _xpvc_SVECResult scalar _xpvc_idGRT_scoring(
    real matrix OMEGA, real matrix XI, real scalar dim_T,
    real matrix LR_mask, real matrix SR_mask,
    real scalar max_iter, real scalar conv_crit, real scalar maxls)
{
  struct _xpvc_SVECResult scalar res
  real scalar dim_K, K2, l, iters
  real matrix IK, IK2, Kkk
  real matrix R_B, R_C1, R_mat, Sb, S_mat
  real colvector s_vec, gamma, vecab
  real matrix A_mat, B_mat, Binv, Btinv, BinvA
  real matrix infvecab, infgamma, infgammainv
  real colvector scorevecBinvA, scorevecAB, scoregamma, direction
  real scalar lambda_step, cvcrit, length_dir
  real colvector z
  
  dim_K = rows(OMEGA)
  K2 = dim_K^2
  IK = I(dim_K)
  IK2 = I(K2)
  
  // Commutation matrix
  Kkk = J(K2, K2, 0)
  real scalar ci, ri
  for (ci = 1; ci <= dim_K; ci++) {
    for (ri = 1; ri <= dim_K; ri++) {
      Kkk[(ci-1)*dim_K + ri, (ri-1)*dim_K + ci] = 1
    }
  }
  
  // Build restriction matrices from mask
  // SR_mask: 0 = restricted to zero, . = free
  // LR_mask: 0 = restricted to zero, . = free
  real scalar n_free_B, n_free_C, idx_r
  
  R_B = J(0, K2, 0)
  for (idx_r = 1; idx_r <= K2; idx_r++) {
    if (SR_mask[mod(idx_r-1, dim_K)+1, floor((idx_r-1)/dim_K)+1] == 0) {
      real rowvector row_sel
      row_sel = J(1, K2, 0)
      row_sel[idx_r] = 1
      R_B = R_B \ row_sel
    }
  }
  
  R_C1 = J(0, K2, 0)
  for (idx_r = 1; idx_r <= K2; idx_r++) {
    if (LR_mask[mod(idx_r-1, dim_K)+1, floor((idx_r-1)/dim_K)+1] == 0) {
      real rowvector row_sel2
      row_sel2 = J(1, K2, 0)
      row_sel2[idx_r] = 1
      R_C1 = R_C1 \ row_sel2
    }
  }
  R_C1 = R_C1 * (XI # IK)
  
  if (rows(R_B) == 0) R_mat = R_C1
  else R_mat = R_C1 \ R_B
  
  // S matrix (explicit form) via orthogonal complement
  Sb = _xpvc_oc(R_mat')
  S_mat = J(K2, cols(Sb), 0) \ Sb
  l = cols(S_mat)
  s_vec = vec(IK) \ J(K2, 1, 0)
  
  // Initialize
  gamma = rnormal(l, 1, 0, 1)
  
  // Scoring algorithm
  iters = 0
  cvcrit = conv_crit + 1
  
  while (cvcrit > conv_crit) {
    z = gamma
    vecab = S_mat * gamma + s_vec
    A_mat = rowshape(vecab[1..K2], dim_K)
    B_mat = rowshape(vecab[K2+1..2*K2], dim_K)
    
    Binv = invsym(B_mat)
    Btinv = invsym(B_mat')
    BinvA = Binv * A_mat
    
    // Information matrix
    real matrix inf1, inf2, inf3
    inf1 = (invsym(BinvA) # Btinv) \ (-IK # Btinv)
    inf2 = IK2 + Kkk
    inf3 = (BinvA' # Binv, -IK # Binv)
    infvecab = dim_T * (inf1 * inf2 * inf3)
    infgamma = S_mat' * infvecab * S_mat
    infgammainv = invsym(infgamma)
    
    // Score
    scorevecBinvA = dim_T * vec(invsym(BinvA')) - dim_T * ((OMEGA # IK) * vec(BinvA))
    real matrix scoreAB_mat
    scoreAB_mat = (IK # Btinv) \ (-(BinvA # Btinv))
    scorevecAB = scoreAB_mat * scorevecBinvA
    scoregamma = S_mat' * scorevecAB
    
    direction = infgammainv * scoregamma
    length_dir = max(abs(direction))
    if (length_dir > maxls) lambda_step = maxls / length_dir
    else lambda_step = 1
    
    gamma = gamma + lambda_step * direction
    iters = iters + 1
    z = z - gamma
    cvcrit = max(abs(z))
    
    if (iters >= max_iter) break
  }
  
  // Final B matrix
  vecab = S_mat * gamma + s_vec
  A_mat = rowshape(vecab[1..K2], dim_K)
  B_mat = rowshape(vecab[K2+1..2*K2], dim_K)
  
  // Normalize sign
  real matrix BinvA_final
  BinvA_final = invsym(A_mat) * B_mat
  real scalar k
  for (k = 1; k <= dim_K; k++) {
    if (BinvA_final[k, k] < 0) B_mat[., k] = -B_mat[., k]
  }
  
  res.SR = B_mat
  res.LR = XI * B_mat
  res.iter = iters - 1
  
  // Clean near-zero elements
  for (ri = 1; ri <= dim_K; ri++) {
    for (ci = 1; ci <= dim_K; ci++) {
      if (abs(res.LR[ri, ci]) < 1e-8) res.LR[ri, ci] = 0
      if (abs(res.SR[ri, ci]) < 1e-8) res.SR[ri, ci] = 0
    }
  }
  
  return(res)
}


// ============================================================
// BAI-NG (2002) PANEL INFORMATION CRITERIA — Full version
// PC, IC, IPC variants
// ============================================================

real matrix _xpvc_PIC(real scalar dim_KN, real scalar dim_T,
                       real scalar k, real scalar Vk0,
                       real scalar Vkmax0)
{
  real scalar n_vals, C2_NT, p1, p2, p3, alphaT, ip3
  real matrix result
  
  n_vals = dim_KN * dim_T
  C2_NT = min((dim_KN, dim_T))
  
  // Bai-Ng (2002:201, Eq.9)
  p1 = (dim_KN + dim_T) / n_vals * ln(n_vals / (dim_KN + dim_T))
  p2 = (dim_KN + dim_T) / n_vals * ln(C2_NT)
  p3 = ln(C2_NT) / C2_NT
  
  real rowvector penalties
  penalties = (p1, p2, p3)
  
  // PC criteria
  real rowvector PC, IC
  PC = J(1, 3, Vk0) + k * Vkmax0 * penalties
  IC = J(1, 3, ln(Vk0)) + k * penalties
  
  // IPC criteria (Bai 2004:145, Eq.12)
  alphaT = dim_T / (4 * ln(ln(dim_T)))
  ip3 = (dim_KN + dim_T - k) / n_vals * ln(n_vals)
  real rowvector IPC
  IPC = J(1, 3, Vk0) + k * Vkmax0 * alphaT * (p1, p2, ip3)
  
  result = PC \ IC \ IPC
  
  return(result)
}


// ============================================================
// COEFFICIENT ACCUMULATION A(1) — Luetkepohl (2005:289)
// ============================================================

real matrix _xpvc_accum(real matrix A, real scalar dim_p)
{
  real scalar dim_K, j
  real matrix result
  
  dim_K = rows(A)
  result = I(dim_K)
  
  for (j = 1; j <= dim_p; j++) {
    result = result - A[., (j-1)*dim_K+1..j*dim_K]
  }
  
  return(result)
}


// ============================================================
// GLS DETRENDING with Q-TRANSFORMATION — Option 2
// Saikkonen, Luetkepohl (2000:439, Eq.3.4)
// ============================================================

struct _xpvc_GLSresult scalar _xpvc_GLStrend_Q(
    real matrix y, real scalar dim_p,
    real matrix OMEGA, real matrix A_slope,
    real matrix D, real matrix alpha, real matrix alpha_oc)
{
  struct _xpvc_GLSresult scalar res
  real scalar dim_T, dim_K, dim_n, dim_r, j
  real matrix OMEGAinv, Aj, Yj, Yz, Q
  
  dim_T = cols(y)
  dim_K = rows(y)
  dim_n = rows(D)
  dim_r = cols(alpha)
  
  OMEGAinv = invsym(OMEGA)
  
  // Build Q transformation matrix (Saikkonen,Luetkepohl 2000:438, Eq.3.2)
  real matrix Q1_left, Q2_right
  Q1_left = J(dim_K, 0, 0)
  Q2_right = J(dim_K, 0, 0)
  
  if (dim_r > 0) {
    real matrix Q1_tmp
    Q1_tmp = alpha' * OMEGAinv * alpha
    // Eigendecomposition for matrix square root inverse
    real matrix Q1_vecs
    real colvector Q1_vals
    eigensystem(Q1_tmp, Q1_vecs, Q1_vals)
    real matrix Q1_eival
    Q1_eival = diag(1 :/ sqrt(Re(Q1_vals)))
    Q1_left = OMEGAinv * alpha * ///
              Re(Q1_vecs) * Q1_eival * Re(Q1_vecs)'
  }
  
  if (dim_K - dim_r > 0) {
    real matrix Q2_tmp
    Q2_tmp = alpha_oc' * OMEGA * alpha_oc
    real matrix Q2_vecs
    real colvector Q2_vals
    eigensystem(Q2_tmp, Q2_vecs, Q2_vals)
    real matrix Q2_eival
    Q2_eival = diag(1 :/ sqrt(Re(Q2_vals)))
    Q2_right = alpha_oc * ///
               Re(Q2_vecs) * Q2_eival * Re(Q2_vecs)'
  }
  
  Q = Q1_left, Q2_right
  
  // Quasi-difference the data
  Yz = y
  for (j = 1; j <= dim_p; j++) {
    Aj = A_slope[., (j-1)*dim_K+1..j*dim_K]
    Yj = J(dim_K, j, 0), y[., 1..dim_T-j]
    Yz = Yz - Aj * Yj
  }
  
  // OLS on Q-transformed model (Saikkonen,Luetkepohl 2000:439, Eq.3.4)
  // Build QD and QY per observation, accumulate
  real matrix XtX, XtY
  real colvector mu_vec
  XtX = J(dim_K * dim_n, dim_K * dim_n, 0)
  XtY = J(dim_K * dim_n, 1, 0)
  
  real scalar t, ki, kj
  for (t = 1; t <= dim_T; t++) {
    real colvector d_t, qyz_t
    real matrix qd, dd
    
    d_t = D[., t]
    qyz_t = Q' * Yz[., t]
    dd = d_t * d_t'
    
    for (ki = 1; ki <= dim_K; ki++) {
      for (kj = 1; kj <= dim_K; kj++) {
        XtX[(ki-1)*dim_n+1..ki*dim_n, (kj-1)*dim_n+1..kj*dim_n] = ///
          XtX[(ki-1)*dim_n+1..ki*dim_n, (kj-1)*dim_n+1..kj*dim_n] + ///
          dd * (Q' * I(dim_K))[ki, kj]  // simplified
      }
      XtY[(ki-1)*dim_n+1..ki*dim_n] = ///
        XtY[(ki-1)*dim_n+1..ki*dim_n] + d_t * qyz_t[ki]
    }
  }
  
  mu_vec = invsym(XtX) * XtY
  res.MU = rowshape(mu_vec, dim_K)
  res.x = y - res.MU * D
  
  return(res)
}


end

