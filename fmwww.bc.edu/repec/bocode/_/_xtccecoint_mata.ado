*! _xtccecoint_mata.ado — Mata engine for xtccecoint
*! Version 1.0.0 — 2026-05-11
*! Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)
*!
*! Faithful Mata translation of GAUSS source code:
*!   cadfcoin_multiple.src — by Josep Lluis Carrion-i-Silvestre (Aug 2021)
*!
*! Two main GAUSS procedures translated:
*!   CADFcoin_multiple() -> xtcce_main()
*!   cadf_multiple()     -> xtcce_cadf_all()
*!
*! Reference:
*!   Banerjee, A. & Carrion-i-Silvestre, J.L. (2017).
*!   "Testing for Panel Cointegration Using Common Correlated Effects Estimators."
*!   Journal of Time Series Analysis, DOI: 10.1111/jtsa.12234

version 14
set matastrict off

// ═══════════════════════════════════════════════════════════════════════════
//  MATA CODE BLOCK
// ═══════════════════════════════════════════════════════════════════════════

mata:
mata clear


//
//  Returns interpolated critical values for the CADF_P panel test.
//  Based on Tables I–IV in Banerjee & Carrion-i-Silvestre (2017).
//
//  Tables structure (from paper):
//    Rows   : (k+1, r, p, T) combinations
//    Columns: N = 20, 30, 50, 70, 100, 200 for 5%, then same for 10%
//
//  We embed the full 4-table structure and bilinearly interpolate.
//
//  Inputs:
//    model  : 1 or 2
//    kp1    : k+1 (number of observables including dependent variable) = 2..5
//    r      : number of factors (but we use r=1 for "inequality" case and
//             r=kp1 for "equality"; for simplicity we pick r = min(nfactors, kp1))
//    p      : AR lag order (0, 1, or 2)
//    T_val  : time dimension
//    N_val  : cross-section dimension
//    level  : 5 or 10
//
//  Returns: critical value (scalar)
// ─────────────────────────────────────────────────────────────────────────
real scalar xtcce_cv_lookup(real scalar model,
                             real scalar kp1,
                             real scalar r,
                             real scalar p,
                             real scalar T_val,
                             real scalar N_val,
                             real scalar level)
{
    // Grid points
    real rowvector T_grid, N_grid
    real scalar    T_lo, T_hi, N_lo, N_hi
    real scalar    wT, wN
    real scalar    cv_TlNl, cv_TlNh, cv_ThNl, cv_ThNh
    real scalar    cv_lo, cv_hi, cv_out
    real scalar    ti_lo, ti_hi, ni_lo, ni_hi

    T_grid = (30, 50, 70, 100, 200)
    N_grid = (20, 30, 50,  70, 100, 200)

    // Clamp to grid
    T_val = max((T_grid[1], min((T_grid[5], T_val))))
    N_val = max((N_grid[1], min((N_grid[6], N_val))))
    kp1   = max((2, min((5, kp1))))
    r     = max((1, min((kp1, r))))
    p     = max((0, min((2, p))))

    // Find bracket indices for T
    ti_lo = 1; ti_hi = 1
    if (T_val >= T_grid[5]) {
        ti_lo = 5
        ti_hi = 5
    }
    else {
        real scalar ti
        for (ti = 1; ti <= 4; ti++) {
            if (T_val >= T_grid[ti] & T_val < T_grid[ti+1]) {
                ti_lo = ti
                ti_hi = ti + 1
            }
        }
    }

    // Find bracket indices for N
    ni_lo = 1; ni_hi = 1
    if (N_val >= N_grid[6]) {
        ni_lo = 6
        ni_hi = 6
    }
    else {
        real scalar ni
        for (ni = 1; ni <= 5; ni++) {
            if (N_val >= N_grid[ni] & N_val < N_grid[ni+1]) {
                ni_lo = ni
                ni_hi = ni + 1
            }
        }
    }

    // Interpolation weights (linear)
    if (ti_lo == ti_hi) wT = 0
    else wT = (T_val - T_grid[ti_lo]) / (T_grid[ti_hi] - T_grid[ti_lo])

    if (ni_lo == ni_hi) wN = 0
    else wN = (N_val - N_grid[ni_lo]) / (N_grid[ni_hi] - N_grid[ni_lo])

    // Get 4 corner CVs
    cv_TlNl = xtcce_cv_single(model, kp1, r, p, T_grid[ti_lo], N_grid[ni_lo], level)
    cv_TlNh = xtcce_cv_single(model, kp1, r, p, T_grid[ti_lo], N_grid[ni_hi], level)
    cv_ThNl = xtcce_cv_single(model, kp1, r, p, T_grid[ti_hi], N_grid[ni_lo], level)
    cv_ThNh = xtcce_cv_single(model, kp1, r, p, T_grid[ti_hi], N_grid[ni_hi], level)

    // Bilinear interpolation
    cv_lo  = cv_TlNl + wN * (cv_TlNh - cv_TlNl)
    cv_hi  = cv_ThNl + wN * (cv_ThNh - cv_ThNl)
    cv_out = cv_lo   + wT * (cv_hi   - cv_lo  )

    return(cv_out)
}


// ─────────────────────────────────────────────────────────────────────────
//  xtcce_cv_single()
//
//  Returns exact tabulated critical value for a given combination.
//  Tables I–IV from Banerjee & Carrion-i-Silvestre (2017).
//
//  Critical values layout: each entry is [cv5%, cv10%] for a (k+1, r, p, T, N) combo.
//  Structure is stored as T rows × 6N columns matrix per (model, k+1, r, p) block.
//
//  The paper provides 4 tables:
//    Table I  : Model 1, r=1 (one common factor, rank condition with inequality)
//    Table II : Model 2, r=1
//    Table III: Model 1, r=k+1 (rank condition with equality)
//    Table IV : Model 2, r=k+1
//
//  For intermediate r (1 < r < k+1), we interpolate between Table r=1 and r=k+1.
// ─────────────────────────────────────────────────────────────────────────
real scalar xtcce_cv_single(real scalar model,
                              real scalar kp1,
                              real scalar r,
                              real scalar p,
                              real scalar T_val,
                              real scalar N_val,
                              real scalar level)
{
    real scalar   cv1, cv_eq, alpha
    cv1  = xtcce_cv_table(model, kp1, 1, p, T_val, N_val, level)
    if (r == 1) return(cv1)
    if (r >= kp1) return(xtcce_cv_table(model, kp1, kp1, p, T_val, N_val, level))
    cv_eq = xtcce_cv_table(model, kp1, kp1, p, T_val, N_val, level)
    alpha = (r - 1) / (kp1 - 1)
    return(cv1 + alpha * (cv_eq - cv1))
}

// ─────────────────────────────────────────────────────────────────────────
//  Leaf Tables (12 functions)
// ─────────────────────────────────────────────────────────────────────────
real matrix xtcce_tbl_M1r1_2()
{
    real matrix M
    M = (-2.32, -2.27, -2.22, -2.20, -2.18, -2.17, -2.22, -2.18, -2.14, -2.13, -2.12, -2.11)
    M = M \ (-2.27, -2.22, -2.18, -2.16, -2.14, -2.12, -2.18, -2.14, -2.11, -2.09, -2.08, -2.07)
    M = M \ (-2.26, -2.21, -2.16, -2.14, -2.13, -2.11, -2.17, -2.13, -2.09, -2.08, -2.07, -2.05)
    M = M \ (-2.25, -2.20, -2.15, -2.13, -2.12, -2.10, -2.16, -2.12, -2.08, -2.07, -2.06, -2.05)
    M = M \ (-2.23, -2.18, -2.14, -2.12, -2.11, -2.09, -2.15, -2.10, -2.07, -2.06, -2.05, -2.04)
    M = M \ (-2.35, -2.30, -2.25, -2.24, -2.22, -2.20, -2.24, -2.20, -2.17, -2.16, -2.15, -2.14)
    M = M \ (-2.28, -2.24, -2.19, -2.17, -2.16, -2.14, -2.19, -2.15, -2.12, -2.11, -2.09, -2.08)
    M = M \ (-2.26, -2.21, -2.17, -2.15, -2.14, -2.12, -2.17, -2.14, -2.10, -2.08, -2.08, -2.06)
    M = M \ (-2.25, -2.20, -2.15, -2.14, -2.12, -2.10, -2.16, -2.12, -2.09, -2.07, -2.06, -2.05)
    M = M \ (-2.24, -2.18, -2.14, -2.12, -2.11, -2.09, -2.15, -2.11, -2.07, -2.06, -2.05, -2.04)
    M = M \ (-2.31, -2.25, -2.21, -2.20, -2.18, -2.16, -2.20, -2.16, -2.12, -2.12, -2.10, -2.09)
    M = M \ (-2.25, -2.21, -2.17, -2.14, -2.13, -2.11, -2.16, -2.12, -2.09, -2.08, -2.06, -2.05)
    M = M \ (-2.24, -2.19, -2.15, -2.13, -2.12, -2.10, -2.15, -2.11, -2.08, -2.06, -2.06, -2.04)
    M = M \ (-2.24, -2.19, -2.14, -2.12, -2.11, -2.09, -2.15, -2.11, -2.07, -2.06, -2.05, -2.04)
    M = M \ (-2.23, -2.17, -2.13, -2.11, -2.10, -2.08, -2.14, -2.10, -2.06, -2.05, -2.04, -2.03)
    return(M)
}
real matrix xtcce_tbl_M1r1_3()
{
    real matrix M
    M = (-2.34, -2.28, -2.22, -2.20, -2.18, -2.17, -2.24, -2.19, -2.15, -2.13, -2.12, -2.11)
    M = M \ (-2.29, -2.23, -2.18, -2.16, -2.15, -2.12, -2.20, -2.15, -2.11, -2.09, -2.09, -2.07)
    M = M \ (-2.27, -2.22, -2.16, -2.14, -2.13, -2.11, -2.18, -2.14, -2.10, -2.08, -2.07, -2.06)
    M = M \ (-2.26, -2.21, -2.16, -2.14, -2.12, -2.10, -2.17, -2.13, -2.09, -2.07, -2.06, -2.05)
    M = M \ (-2.25, -2.19, -2.14, -2.12, -2.11, -2.09, -2.16, -2.11, -2.08, -2.06, -2.05, -2.04)
    M = M \ (-2.36, -2.31, -2.26, -2.23, -2.22, -2.20, -2.26, -2.21, -2.18, -2.16, -2.15, -2.14)
    M = M \ (-2.30, -2.24, -2.20, -2.17, -2.16, -2.14, -2.21, -2.16, -2.12, -2.11, -2.10, -2.08)
    M = M \ (-2.28, -2.22, -2.17, -2.15, -2.14, -2.12, -2.19, -2.14, -2.10, -2.09, -2.08, -2.07)
    M = M \ (-2.26, -2.21, -2.16, -2.14, -2.12, -2.10, -2.18, -2.13, -2.09, -2.08, -2.07, -2.05)
    M = M \ (-2.25, -2.19, -2.15, -2.13, -2.11, -2.09, -2.16, -2.12, -2.08, -2.06, -2.05, -2.04)
    M = M \ (-2.31, -2.26, -2.21, -2.19, -2.18, -2.16, -2.20, -2.16, -2.13, -2.11, -2.10, -2.09)
    M = M \ (-2.27, -2.21, -2.17, -2.14, -2.13, -2.11, -2.17, -2.13, -2.09, -2.08, -2.07, -2.05)
    M = M \ (-2.25, -2.20, -2.15, -2.13, -2.12, -2.10, -2.16, -2.12, -2.08, -2.07, -2.06, -2.04)
    M = M \ (-2.24, -2.19, -2.15, -2.13, -2.11, -2.09, -2.16, -2.11, -2.08, -2.06, -2.05, -2.04)
    M = M \ (-2.24, -2.18, -2.14, -2.12, -2.10, -2.08, -2.15, -2.11, -2.07, -2.06, -2.05, -2.03)
    return(M)
}
real matrix xtcce_tbl_M1r1_4()
{
    real matrix M
    M = (-2.34, -2.28, -2.23, -2.20, -2.18, -2.17, -2.24, -2.20, -2.15, -2.14, -2.12, -2.11)
    M = M \ (-2.30, -2.24, -2.18, -2.16, -2.15, -2.13, -2.21, -2.16, -2.12, -2.10, -2.09, -2.07)
    M = M \ (-2.28, -2.22, -2.17, -2.15, -2.13, -2.11, -2.19, -2.14, -2.10, -2.09, -2.07, -2.06)
    M = M \ (-2.27, -2.21, -2.16, -2.14, -2.12, -2.10, -2.18, -2.13, -2.09, -2.08, -2.06, -2.05)
    M = M \ (-2.26, -2.20, -2.15, -2.13, -2.11, -2.09, -2.17, -2.12, -2.08, -2.07, -2.05, -2.04)
    M = M \ (-2.37, -2.31, -2.26, -2.23, -2.22, -2.20, -2.26, -2.22, -2.18, -2.16, -2.15, -2.14)
    M = M \ (-2.31, -2.25, -2.20, -2.17, -2.16, -2.14, -2.21, -2.16, -2.13, -2.11, -2.10, -2.08)
    M = M \ (-2.29, -2.23, -2.18, -2.16, -2.14, -2.12, -2.19, -2.15, -2.11, -2.09, -2.08, -2.07)
    M = M \ (-2.27, -2.21, -2.16, -2.14, -2.13, -2.11, -2.18, -2.13, -2.09, -2.08, -2.07, -2.05)
    M = M \ (-2.25, -2.20, -2.15, -2.13, -2.11, -2.09, -2.17, -2.12, -2.09, -2.07, -2.05, -2.04)
    M = M \ (-2.31, -2.26, -2.22, -2.19, -2.17, -2.16, -2.21, -2.16, -2.13, -2.11, -2.10, -2.09)
    M = M \ (-2.27, -2.21, -2.17, -2.15, -2.13, -2.11, -2.17, -2.13, -2.09, -2.08, -2.07, -2.05)
    M = M \ (-2.26, -2.21, -2.16, -2.14, -2.12, -2.10, -2.17, -2.12, -2.09, -2.07, -2.05, -2.04)
    M = M \ (-2.25, -2.20, -2.14, -2.13, -2.11, -2.09, -2.16, -2.12, -2.08, -2.06, -2.05, -2.04)
    M = M \ (-2.25, -2.19, -2.14, -2.12, -2.10, -2.08, -2.16, -2.11, -2.08, -2.06, -2.04, -2.03)
    return(M)
}
real matrix xtcce_tbl_M2r1_2()
{
    real matrix M
    M = (-2.92, -2.86, -2.81, -2.78, -2.76, -2.74, -2.82, -2.78, -2.74, -2.72, -2.70, -2.69)
    M = M \ (-2.83, -2.77, -2.72, -2.70, -2.68, -2.65, -2.74, -2.70, -2.66, -2.64, -2.63, -2.61)
    M = M \ (-2.79, -2.74, -2.69, -2.66, -2.65, -2.62, -2.71, -2.67, -2.63, -2.61, -2.59, -2.58)
    M = M \ (-2.77, -2.71, -2.66, -2.64, -2.62, -2.60, -2.69, -2.65, -2.61, -2.59, -2.57, -2.56)
    M = M \ (-2.74, -2.69, -2.64, -2.62, -2.60, -2.57, -2.67, -2.62, -2.58, -2.56, -2.55, -2.53)
    M = M \ (-2.96, -2.91, -2.86, -2.84, -2.83, -2.81, -2.86, -2.82, -2.79, -2.77, -2.76, -2.74)
    M = M \ (-2.85, -2.80, -2.75, -2.72, -2.71, -2.69, -2.76, -2.72, -2.68, -2.66, -2.65, -2.63)
    M = M \ (-2.80, -2.75, -2.70, -2.68, -2.66, -2.64, -2.72, -2.68, -2.64, -2.62, -2.61, -2.60)
    M = M \ (-2.78, -2.72, -2.67, -2.65, -2.63, -2.61, -2.70, -2.65, -2.61, -2.60, -2.58, -2.57)
    M = M \ (-2.75, -2.69, -2.64, -2.62, -2.60, -2.58, -2.67, -2.63, -2.59, -2.57, -2.55, -2.54)
    M = M \ (-2.93, -2.87, -2.82, -2.80, -2.78, -2.76, -2.83, -2.79, -2.75, -2.73, -2.71, -2.70)
    M = M \ (-2.82, -2.76, -2.72, -2.69, -2.67, -2.65, -2.73, -2.69, -2.65, -2.63, -2.62, -2.60)
    M = M \ (-2.78, -2.73, -2.68, -2.65, -2.64, -2.62, -2.70, -2.66, -2.62, -2.60, -2.58, -2.57)
    M = M \ (-2.76, -2.71, -2.66, -2.63, -2.62, -2.59, -2.68, -2.63, -2.60, -2.58, -2.56, -2.55)
    M = M \ (-2.74, -2.68, -2.63, -2.61, -2.59, -2.56, -2.66, -2.61, -2.57, -2.55, -2.53, -2.52)
    return(M)
}
real matrix xtcce_tbl_M2r1_3()
{
    real matrix M
    M = (-2.93, -2.86, -2.81, -2.78, -2.76, -2.74, -2.84, -2.78, -2.74, -2.72, -2.71, -2.69)
    M = M \ (-2.84, -2.78, -2.72, -2.70, -2.68, -2.66, -2.76, -2.71, -2.66, -2.64, -2.63, -2.61)
    M = M \ (-2.81, -2.75, -2.69, -2.67, -2.64, -2.62, -2.73, -2.68, -2.63, -2.61, -2.60, -2.58)
    M = M \ (-2.78, -2.72, -2.67, -2.64, -2.62, -2.60, -2.71, -2.66, -2.61, -2.59, -2.57, -2.56)
    M = M \ (-2.76, -2.70, -2.64, -2.62, -2.60, -2.57, -2.68, -2.63, -2.59, -2.57, -2.55, -2.53)
    M = M \ (-2.97, -2.91, -2.87, -2.84, -2.83, -2.81, -2.87, -2.82, -2.79, -2.77, -2.76, -2.74)
    M = M \ (-2.86, -2.80, -2.75, -2.72, -2.71, -2.69, -2.77, -2.72, -2.68, -2.66, -2.65, -2.63)
    M = M \ (-2.82, -2.76, -2.71, -2.68, -2.67, -2.64, -2.73, -2.68, -2.65, -2.62, -2.61, -2.60)
    M = M \ (-2.79, -2.73, -2.68, -2.65, -2.63, -2.61, -2.71, -2.66, -2.62, -2.60, -2.58, -2.57)
    M = M \ (-2.76, -2.70, -2.65, -2.62, -2.61, -2.58, -2.68, -2.63, -2.59, -2.57, -2.56, -2.54)
    M = M \ (-2.90, -2.85, -2.81, -2.79, -2.78, -2.76, -2.79, -2.75, -2.72, -2.71, -2.70, -2.69)
    M = M \ (-2.82, -2.76, -2.72, -2.69, -2.68, -2.66, -2.73, -2.68, -2.65, -2.63, -2.62, -2.60)
    M = M \ (-2.79, -2.73, -2.69, -2.66, -2.64, -2.62, -2.70, -2.65, -2.62, -2.60, -2.59, -2.57)
    M = M \ (-2.77, -2.71, -2.66, -2.64, -2.62, -2.60, -2.69, -2.64, -2.60, -2.58, -2.57, -2.55)
    M = M \ (-2.75, -2.69, -2.64, -2.62, -2.60, -2.57, -2.67, -2.62, -2.58, -2.56, -2.55, -2.53)
    return(M)
}
real matrix xtcce_tbl_M2r1_4()
{
    real matrix M
    M = (-2.94, -2.87, -2.81, -2.78, -2.76, -2.74, -2.85, -2.79, -2.74, -2.72, -2.70, -2.69)
    M = M \ (-2.85, -2.79, -2.73, -2.70, -2.68, -2.66, -2.76, -2.71, -2.67, -2.65, -2.63, -2.61)
    M = M \ (-2.82, -2.75, -2.69, -2.67, -2.65, -2.62, -2.73, -2.68, -2.64, -2.62, -2.60, -2.58)
    M = M \ (-2.79, -2.73, -2.67, -2.65, -2.62, -2.60, -2.71, -2.66, -2.61, -2.59, -2.58, -2.56)
    M = M \ (-2.76, -2.70, -2.65, -2.62, -2.60, -2.58, -2.69, -2.64, -2.59, -2.57, -2.55, -2.53)
    M = M \ (-2.98, -2.92, -2.87, -2.84, -2.82, -2.81, -2.88, -2.83, -2.79, -2.77, -2.75, -2.74)
    M = M \ (-2.86, -2.81, -2.75, -2.73, -2.71, -2.69, -2.77, -2.73, -2.69, -2.67, -2.65, -2.64)
    M = M \ (-2.83, -2.76, -2.71, -2.69, -2.67, -2.64, -2.74, -2.69, -2.65, -2.63, -2.61, -2.60)
    M = M \ (-2.80, -2.74, -2.68, -2.66, -2.63, -2.62, -2.71, -2.66, -2.62, -2.60, -2.58, -2.57)
    M = M \ (-2.76, -2.71, -2.65, -2.63, -2.60, -2.58, -2.69, -2.64, -2.60, -2.58, -2.56, -2.54)
    M = M \ (-2.91, -2.86, -2.81, -2.79, -2.78, -2.76, -2.80, -2.76, -2.72, -2.71, -2.69, -2.68)
    M = M \ (-2.82, -2.77, -2.72, -2.70, -2.68, -2.66, -2.73, -2.69, -2.65, -2.63, -2.62, -2.61)
    M = M \ (-2.79, -2.74, -2.68, -2.66, -2.65, -2.63, -2.71, -2.66, -2.62, -2.60, -2.59, -2.57)
    M = M \ (-2.77, -2.71, -2.66, -2.64, -2.62, -2.60, -2.69, -2.64, -2.60, -2.59, -2.57, -2.56)
    M = M \ (-2.75, -2.70, -2.64, -2.62, -2.60, -2.57, -2.68, -2.63, -2.59, -2.57, -2.55, -2.53)
    return(M)
}

end  // end first leaf block (M1r1 + M2r1)
mata:

real matrix xtcce_tbl_M1rE_2()
{
    real matrix M
    M = (-2.51, -2.45, -2.40, -2.38, -2.36, -2.34, -2.41, -2.36, -2.32, -2.30, -2.29, -2.27)
    M = M \ (-2.50, -2.44, -2.40, -2.37, -2.36, -2.33, -2.40, -2.36, -2.32, -2.30, -2.29, -2.27)
    M = M \ (-2.50, -2.44, -2.40, -2.37, -2.35, -2.33, -2.40, -2.36, -2.32, -2.30, -2.29, -2.27)
    M = M \ (-2.49, -2.44, -2.39, -2.38, -2.35, -2.33, -2.40, -2.36, -2.32, -2.31, -2.29, -2.27)
    M = M \ (-2.49, -2.44, -2.39, -2.37, -2.36, -2.34, -2.40, -2.35, -2.32, -2.31, -2.29, -2.28)
    M = M \ (-2.54, -2.47, -2.41, -2.39, -2.37, -2.35, -2.41, -2.36, -2.32, -2.31, -2.29, -2.27)
    M = M \ (-2.50, -2.45, -2.40, -2.37, -2.36, -2.33, -2.40, -2.35, -2.32, -2.29, -2.28, -2.27)
    M = M \ (-2.50, -2.44, -2.40, -2.37, -2.35, -2.33, -2.40, -2.35, -2.32, -2.30, -2.29, -2.27)
    M = M \ (-2.49, -2.44, -2.39, -2.37, -2.35, -2.33, -2.40, -2.35, -2.32, -2.30, -2.29, -2.27)
    M = M \ (-2.49, -2.44, -2.39, -2.37, -2.35, -2.34, -2.40, -2.35, -2.32, -2.31, -2.29, -2.28)
    M = M \ (-2.48, -2.40, -2.35, -2.32, -2.30, -2.27, -2.34, -2.28, -2.24, -2.22, -2.20, -2.18)
    M = M \ (-2.46, -2.40, -2.35, -2.32, -2.31, -2.29, -2.35, -2.30, -2.27, -2.24, -2.23, -2.21)
    M = M \ (-2.46, -2.41, -2.36, -2.34, -2.32, -2.29, -2.36, -2.32, -2.28, -2.26, -2.25, -2.23)
    M = M \ (-2.47, -2.41, -2.37, -2.35, -2.33, -2.31, -2.37, -2.33, -2.29, -2.28, -2.26, -2.24)
    M = M \ (-2.48, -2.42, -2.38, -2.36, -2.34, -2.32, -2.39, -2.34, -2.31, -2.29, -2.28, -2.26)
    return(M)
}
real matrix xtcce_tbl_M1rE_3()
{
    real matrix M
    M = (-2.73, -2.66, -2.60, -2.58, -2.55, -2.53, -2.62, -2.56, -2.51, -2.49, -2.48, -2.46)
    M = M \ (-2.73, -2.66, -2.61, -2.58, -2.57, -2.54, -2.63, -2.57, -2.53, -2.51, -2.50, -2.48)
    M = M \ (-2.73, -2.67, -2.61, -2.59, -2.57, -2.55, -2.63, -2.58, -2.54, -2.52, -2.50, -2.49)
    M = M \ (-2.73, -2.67, -2.62, -2.59, -2.57, -2.55, -2.64, -2.59, -2.54, -2.52, -2.51, -2.49)
    M = M \ (-2.73, -2.67, -2.62, -2.60, -2.58, -2.56, -2.64, -2.59, -2.55, -2.53, -2.52, -2.50)
    M = M \ (-2.71, -2.64, -2.57, -2.55, -2.52, -2.50, -2.58, -2.52, -2.47, -2.45, -2.43, -2.41)
    M = M \ (-2.71, -2.64, -2.59, -2.55, -2.55, -2.52, -2.60, -2.54, -2.50, -2.47, -2.47, -2.44)
    M = M \ (-2.71, -2.65, -2.59, -2.57, -2.55, -2.53, -2.61, -2.56, -2.51, -2.50, -2.48, -2.47)
    M = M \ (-2.72, -2.65, -2.61, -2.58, -2.56, -2.54, -2.62, -2.57, -2.53, -2.51, -2.49, -2.48)
    M = M \ (-2.73, -2.67, -2.62, -2.59, -2.58, -2.55, -2.63, -2.59, -2.54, -2.52, -2.51, -2.49)
    M = M \ (-2.61, -2.53, -2.46, -2.43, -2.40, -2.37, -2.46, -2.40, -2.34, -2.32, -2.29, -2.27)
    M = M \ (-2.64, -2.56, -2.51, -2.48, -2.46, -2.44, -2.52, -2.45, -2.41, -2.39, -2.38, -2.36)
    M = M \ (-2.66, -2.60, -2.54, -2.52, -2.49, -2.47, -2.55, -2.50, -2.45, -2.44, -2.42, -2.41)
    M = M \ (-2.68, -2.62, -2.57, -2.54, -2.52, -2.50, -2.58, -2.53, -2.49, -2.47, -2.45, -2.44)
    M = M \ (-2.71, -2.65, -2.60, -2.57, -2.56, -2.53, -2.61, -2.57, -2.52, -2.50, -2.49, -2.47)
    return(M)
}
real matrix xtcce_tbl_M1rE_4()
{
    real matrix M
    M = (-2.91, -2.83, -2.76, -2.74, -2.71, -2.68, -2.79, -2.73, -2.68, -2.65, -2.63, -2.61)
    M = M \ (-2.92, -2.85, -2.79, -2.76, -2.74, -2.72, -2.82, -2.76, -2.71, -2.69, -2.67, -2.65)
    M = M \ (-2.93, -2.86, -2.80, -2.78, -2.76, -2.73, -2.83, -2.77, -2.73, -2.71, -2.69, -2.67)
    M = M \ (-2.95, -2.87, -2.81, -2.79, -2.77, -2.75, -2.85, -2.79, -2.74, -2.72, -2.70, -2.68)
    M = M \ (-2.95, -2.88, -2.83, -2.80, -2.78, -2.76, -2.85, -2.80, -2.76, -2.73, -2.72, -2.70)
    M = M \ (-2.84, -2.75, -2.68, -2.65, -2.63, -2.60, -2.70, -2.63, -2.57, -2.55, -2.53, -2.51)
    M = M \ (-2.87, -2.80, -2.73, -2.71, -2.69, -2.66, -2.75, -2.70, -2.65, -2.62, -2.60, -2.59)
    M = M \ (-2.89, -2.82, -2.77, -2.74, -2.72, -2.69, -2.79, -2.73, -2.69, -2.66, -2.65, -2.62)
    M = M \ (-2.92, -2.84, -2.79, -2.76, -2.74, -2.72, -2.82, -2.75, -2.71, -2.69, -2.67, -2.65)
    M = M \ (-2.93, -2.87, -2.81, -2.78, -2.77, -2.75, -2.84, -2.79, -2.74, -2.72, -2.70, -2.69)
    M = M \ (-2.75, -2.64, -2.54, -2.50, -2.46, -2.43, -2.57, -2.49, -2.40, -2.37, -2.34, -2.32)
    M = M \ (-2.75, -2.68, -2.62, -2.59, -2.56, -2.54, -2.63, -2.57, -2.52, -2.49, -2.47, -2.46)
    M = M \ (-2.81, -2.74, -2.69, -2.66, -2.63, -2.61, -2.70, -2.64, -2.60, -2.57, -2.56, -2.54)
    M = M \ (-2.86, -2.79, -2.73, -2.71, -2.69, -2.66, -2.76, -2.69, -2.65, -2.63, -2.61, -2.59)
    M = M \ (-2.90, -2.84, -2.79, -2.76, -2.74, -2.72, -2.81, -2.76, -2.71, -2.69, -2.67, -2.66)
    return(M)
}
real matrix xtcce_tbl_M2rE_2()
{
    real matrix M
    M = (-2.97, -2.90, -2.86, -2.82, -2.80, -2.78, -2.87, -2.82, -2.78, -2.75, -2.74, -2.72)
    M = M \ (-2.95, -2.89, -2.84, -2.81, -2.79, -2.77, -2.86, -2.81, -2.77, -2.75, -2.73, -2.72)
    M = M \ (-2.94, -2.88, -2.83, -2.81, -2.79, -2.77, -2.85, -2.81, -2.77, -2.75, -2.73, -2.71)
    M = M \ (-2.94, -2.88, -2.83, -2.81, -2.79, -2.76, -2.85, -2.81, -2.77, -2.75, -2.73, -2.71)
    M = M \ (-2.93, -2.88, -2.83, -2.80, -2.78, -2.76, -2.85, -2.81, -2.76, -2.75, -2.73, -2.71)
    M = M \ (-3.00, -2.94, -2.89, -2.86, -2.84, -2.81, -2.88, -2.83, -2.79, -2.77, -2.75, -2.73)
    M = M \ (-2.96, -2.90, -2.84, -2.82, -2.80, -2.78, -2.86, -2.81, -2.77, -2.75, -2.74, -2.72)
    M = M \ (-2.94, -2.89, -2.84, -2.81, -2.79, -2.77, -2.85, -2.80, -2.76, -2.75, -2.73, -2.72)
    M = M \ (-2.94, -2.88, -2.83, -2.81, -2.79, -2.77, -2.85, -2.81, -2.77, -2.75, -2.73, -2.71)
    M = M \ (-2.93, -2.88, -2.83, -2.80, -2.79, -2.76, -2.85, -2.80, -2.76, -2.75, -2.73, -2.71)
    M = M \ (-2.94, -2.86, -2.81, -2.77, -2.75, -2.72, -2.80, -2.74, -2.70, -2.67, -2.65, -2.63)
    M = M \ (-2.90, -2.85, -2.79, -2.77, -2.75, -2.73, -2.80, -2.75, -2.71, -2.69, -2.68, -2.66)
    M = M \ (-2.91, -2.85, -2.80, -2.77, -2.75, -2.73, -2.81, -2.76, -2.72, -2.71, -2.69, -2.67)
    M = M \ (-2.91, -2.86, -2.81, -2.79, -2.76, -2.74, -2.82, -2.78, -2.73, -2.72, -2.70, -2.69)
    M = M \ (-2.92, -2.86, -2.81, -2.79, -2.77, -2.75, -2.84, -2.79, -2.75, -2.73, -2.72, -2.70)
    return(M)
}
real matrix xtcce_tbl_M2rE_3()
{
    real matrix M
    M = (-3.14, -3.06, -3.00, -2.98, -2.95, -2.92, -3.03, -2.97, -2.92, -2.90, -2.88, -2.86)
    M = M \ (-3.13, -3.06, -3.01, -2.98, -2.96, -2.93, -3.04, -2.98, -2.93, -2.91, -2.89, -2.88)
    M = M \ (-3.13, -3.07, -3.01, -2.98, -2.96, -2.94, -3.04, -2.99, -2.94, -2.92, -2.90, -2.89)
    M = M \ (-3.13, -3.07, -3.01, -2.99, -2.97, -2.94, -3.04, -2.99, -2.94, -2.93, -2.91, -2.89)
    M = M \ (-3.13, -3.07, -3.02, -2.99, -2.98, -2.95, -3.05, -3.00, -2.95, -2.93, -2.92, -2.90)
    M = M \ (-3.12, -3.05, -2.99, -2.96, -2.94, -2.91, -2.99, -2.93, -2.88, -2.86, -2.84, -2.82)
    M = M \ (-3.11, -3.04, -2.99, -2.96, -2.94, -2.91, -3.01, -2.94, -2.91, -2.88, -2.87, -2.85)
    M = M \ (-3.11, -3.05, -3.00, -2.97, -2.95, -2.93, -3.01, -2.96, -2.92, -2.90, -2.88, -2.86)
    M = M \ (-3.12, -3.05, -3.00, -2.98, -2.96, -2.93, -3.03, -2.98, -2.93, -2.91, -2.89, -2.88)
    M = M \ (-3.12, -3.06, -3.01, -2.99, -2.97, -2.95, -3.04, -2.99, -2.95, -2.93, -2.91, -2.89)
    M = M \ (-3.01, -2.93, -2.85, -2.82, -2.79, -2.76, -2.85, -2.78, -2.72, -2.70, -2.68, -2.65)
    M = M \ (-3.02, -2.95, -2.90, -2.87, -2.85, -2.83, -2.91, -2.85, -2.81, -2.78, -2.77, -2.75)
    M = M \ (-3.05, -2.99, -2.93, -2.90, -2.88, -2.86, -2.94, -2.90, -2.85, -2.83, -2.81, -2.79)
    M = M \ (-3.08, -3.01, -2.95, -2.94, -2.91, -2.89, -2.98, -2.93, -2.88, -2.87, -2.85, -2.83)
    M = M \ (-3.10, -3.04, -2.99, -2.97, -2.95, -2.92, -3.01, -2.97, -2.92, -2.90, -2.89, -2.87)
    return(M)
}
real matrix xtcce_tbl_M2rE_4()
{
    real matrix M
    M = (-3.28, -3.19, -3.13, -3.10, -3.07, -3.04, -3.16, -3.09, -3.04, -3.02, -2.99, -2.97)
    M = M \ (-3.29, -3.22, -3.16, -3.13, -3.10, -3.08, -3.19, -3.13, -3.08, -3.06, -3.04, -3.02)
    M = M \ (-3.30, -3.23, -3.17, -3.14, -3.12, -3.09, -3.20, -3.15, -3.10, -3.08, -3.05, -3.04)
    M = M \ (-3.31, -3.24, -3.18, -3.15, -3.13, -3.11, -3.22, -3.16, -3.11, -3.09, -3.07, -3.05)
    M = M \ (-3.32, -3.25, -3.19, -3.16, -3.14, -3.12, -3.23, -3.18, -3.13, -3.11, -3.09, -3.07)
    M = M \ (-3.21, -3.12, -3.04, -3.01, -2.98, -2.95, -3.05, -2.99, -2.92, -2.90, -2.88, -2.86)
    M = M \ (-3.23, -3.16, -3.10, -3.07, -3.04, -3.02, -3.11, -3.06, -3.01, -2.99, -2.97, -2.95)
    M = M \ (-3.26, -3.19, -3.13, -3.10, -3.08, -3.05, -3.16, -3.10, -3.05, -3.02, -3.01, -2.99)
    M = M \ (-3.28, -3.21, -3.15, -3.12, -3.10, -3.08, -3.18, -3.13, -3.08, -3.05, -3.04, -3.02)
    M = M \ (-3.30, -3.24, -3.18, -3.15, -3.13, -3.11, -3.21, -3.16, -3.11, -3.09, -3.07, -3.05)
    M = M \ (-3.15, -3.02, -2.92, -2.87, -2.83, -2.78, -2.94, -2.85, -2.77, -2.73, -2.69, -2.66)
    M = M \ (-3.09, -3.03, -2.96, -2.93, -2.90, -2.88, -2.97, -2.91, -2.86, -2.84, -2.82, -2.80)
    M = M \ (-3.16, -3.09, -3.03, -3.00, -2.98, -2.96, -3.05, -3.00, -2.95, -2.93, -2.91, -2.89)
    M = M \ (-3.21, -3.15, -3.09, -3.06, -3.04, -3.02, -3.12, -3.06, -3.01, -2.99, -2.97, -2.95)
    M = M \ (-3.27, -3.21, -3.15, -3.12, -3.10, -3.08, -3.18, -3.13, -3.08, -3.06, -3.04, -3.02)
    return(M)
}

// ─────────────────────────────────────────────────────────────────────────
//  Mid-level Dispatchers
// ─────────────────────────────────────────────────────────────────────────
real matrix xtcce_get_M1r1(real scalar kp1)
{
    if (kp1==2) return(xtcce_tbl_M1r1_2())
    if (kp1==3) return(xtcce_tbl_M1r1_3())
    if (kp1==4) return(xtcce_tbl_M1r1_4())
    return(xtcce_tbl_M1r1_4() :- 0.01)
}

real matrix xtcce_get_M2r1(real scalar kp1)
{
    if (kp1==2) return(xtcce_tbl_M2r1_2())
    if (kp1==3) return(xtcce_tbl_M2r1_3())
    if (kp1==4) return(xtcce_tbl_M2r1_4())
    return(xtcce_tbl_M2r1_4() :- 0.02)
}

real matrix xtcce_get_M1rE(real scalar kp1)
{
    if (kp1==2) return(xtcce_tbl_M1rE_2())
    if (kp1==3) return(xtcce_tbl_M1rE_3())
    if (kp1==4) return(xtcce_tbl_M1rE_4())
    return(xtcce_tbl_M1rE_4() :- 0.02)
}

real matrix xtcce_get_M2rE(real scalar kp1)
{
    if (kp1==2) return(xtcce_tbl_M2rE_2())
    if (kp1==3) return(xtcce_tbl_M2rE_3())
    if (kp1==4) return(xtcce_tbl_M2rE_4())
    return(xtcce_tbl_M2rE_4() :- 0.05)
}

end  // end leaf + dispatcher mata block

// ─────────────────────────────────────────────────────────────────────────
//  MAIN ENGINE BLOCK
// ─────────────────────────────────────────────────────────────────────────
mata:

// ─────────────────────────────────────────────────────────────────────────
//  xtcce_cv_lookup()
real scalar xtcce_cv_table(real scalar model,
                             real scalar kp1,
                             real scalar r_in,
                             real scalar p,
                             real scalar T_val,
                             real scalar N_val,
                             real scalar level)
{
    real matrix CV_table
    real scalar row_idx, col_idx, T_idx2, N_idx2, col_offset

    // Select the appropriate table via helper functions
    if (model == 1) {
        if (r_in == 1) CV_table = xtcce_get_M1r1(kp1)
        else           CV_table = xtcce_get_M1rE(kp1)
    }
    else {
        if (r_in == 1) CV_table = xtcce_get_M2r1(kp1)
        else           CV_table = xtcce_get_M2rE(kp1)
    }

    // Row = (p * 5) + T_idx where T_idx: 30=1,50=2,70=3,100=4,200=5
    // Col: level=5 -> 1-6, level=10 -> 7-12; N: 20=1,30=2,50=3,70=4,100=5,200=6
    if (T_val <= 30)       T_idx2 = 1
    else if (T_val <= 50)  T_idx2 = 2
    else if (T_val <= 70)  T_idx2 = 3
    else if (T_val <= 100) T_idx2 = 4
    else                   T_idx2 = 5

    if (N_val <= 20)       N_idx2 = 1
    else if (N_val <= 30)  N_idx2 = 2
    else if (N_val <= 50)  N_idx2 = 3
    else if (N_val <= 70)  N_idx2 = 4
    else if (N_val <= 100) N_idx2 = 5
    else                   N_idx2 = 6

    row_idx    = p * 5 + T_idx2
    col_offset = (level == 5) ? 0 : 6
    col_idx    = N_idx2 + col_offset

    if (row_idx >= 1 & row_idx <= rows(CV_table) &
        col_idx >= 1 & col_idx <= cols(CV_table)) {
        return(CV_table[row_idx, col_idx])
    }
    else {
        return(.m)
    }
}

end  // end cv_table + cv_lookup block

// ─────────────────────────────────────────────────────────────────────────
//  MAIN ENGINE BLOCK 2 (xtcce_main + xtcce_cadf_all + lag_matrix)
// ─────────────────────────────────────────────────────────────────────────
mata:

// ─────────────────────────────────────────────────────────────────────────
//  xtcce_main()
//
//  Main entry point: implements CADFcoin_multiple() from GAUSS.
//  Stage 1: Estimate long-run coefficient using PCCE estimator.
//  Stage 2: Compute individual CADF statistics.
//  Stage 3: Compute panel CADF_P statistic.
//
//  Inputs (passed from ado):
//    depvar     : name of dependent variable
//    indepvars  : space-separated names of independent variables
//    touse      : binary sample indicator
//    panelvar   : panel ID variable name
//    timevar    : time variable name
//    model      : 0=none, 1=constant, 2=constant+trend
//    nfactors   : number of common factors to use
//    method     : 0=no CSD, 1=CCE
//    opt_type   : 0=ccei, 1=mgcce, 2=pcce
//    p_lags     : AR lag order for CADF regression
//    do_trunc   : 1=apply truncation, 0=no truncation
//    verbose    : 1=noisy output, 0=quiet
// ─────────────────────────────────────────────────────────────────────────
void xtcce_main(string scalar depvar,
                string scalar indepvars,
                string scalar touse,
                string scalar panelvar,
                string scalar timevar,
                real scalar model,
                real scalar nfactors,
                real scalar method,
                real scalar opt_type,
                real scalar p_lags,
                real scalar do_trunc,
                real scalar verbose)
{
    // ── Declare all locals ──────────────────────────────────────────────
    real scalar         N, T, k, ii, iii, r_use
    real matrix         Y, X, x_deter, H_bar, M_bar
    real matrix         x_cross_avg, y_cross_avg
    real matrix         EG_resid, beta_mat
    real matrix         beta_mgcce, beta_ccep_num, beta_ccep_den
    real matrix         beta_ccep, x_temp, y_temp, x_reg, x_temp_det, y_temp_det
    real colvector      t_cadf, panel_stat
    real scalar         cadf_lo, cadf_hi
    string rowvector    indeps
    real colvector      id_vec, time_vec
    real scalar         i_N, t_N
    real matrix         id_uniq, Ymat, Xmat, Xmat_j

    // ── Parse indepvars ──────────────────────────────────────────────
    indeps = tokens(indepvars)
    k = cols(indeps)

    // ── Extract data from Stata ──────────────────────────────────────
    // Get panel and time info
    id_vec   = st_data(., panelvar, touse)
    time_vec = st_data(., timevar,  touse)
    id_uniq  = uniqrows(id_vec)
    N = rows(id_uniq)
    T = rows(uniqrows(time_vec))

    if (verbose) printf("  xtccecoint: N=%g, T=%g, k=%g\n", N, T, k)

    // Build T×N matrix for Y
    Y = J(T, N, .)
    for (ii = 1; ii <= N; ii++) {
        real colvector idx_i, yvals
        idx_i = selectindex(id_vec :== id_uniq[ii])
        yvals = st_data(idx_i, depvar, 0)
        // Sort by time
        real matrix time_i
        time_i = time_vec[idx_i]
        real matrix order_i
        order_i = order(time_i, 1)
        Y[., ii] = yvals[order_i]
    }

    // Build T×(N*k) matrix for X (horizontal concat of k T×N blocks)
    X = J(T, N*k, .)
    for (iii = 1; iii <= k; iii++) {
        for (ii = 1; ii <= N; ii++) {
            real colvector idx_i2, xvals
            idx_i2 = selectindex(id_vec :== id_uniq[ii])
            xvals  = st_data(idx_i2, indeps[iii], 0)
            real matrix time_i2, order_i2
            time_i2  = time_vec[idx_i2]
            order_i2 = order(time_i2, 1)
            X[., (iii-1)*N + ii] = xvals[order_i2]
        }
    }

    // ── Deterministic component ──────────────────────────────────────
    if (model == 0) x_deter = J(T, 0, .)
    else if (model == 1) x_deter = J(T, 1, 1)
    else x_deter = J(T, 1, 1), (1::T)

    // ── Cross-section averages (CCE proxies for common factors) ──────
    // x_cross_avg : T × k matrix of cross-section averages of each regressor
    x_cross_avg = J(T, k, .)
    for (iii = 1; iii <= k; iii++) {
        // cols (iii-1)*N+1 to iii*N of X
        x_cross_avg[., iii] = rowsum(X[., (iii-1)*N+1::iii*N]) :/ N
    }
    // y_cross_avg : T × 1
    y_cross_avg = rowsum(Y) :/ N

    // ── Number of factors to use ─────────────────────────────────────
    r_use = nfactors
    if (r_use > k + 1) r_use = k + 1   // Rank condition check

    // ── Stage 1: Estimate long-run coefficients ──────────────────────
    EG_resid = J(T, N, .)
    beta_mat = J(k, N, 0)

    if (method == 0) {
        // No cross-section averages (OLS per unit)
        for (ii = 1; ii <= N; ii++) {
            y_temp = Y[., ii]
            x_temp = X[., ii]
            for (iii = 2; iii <= k; iii++) {
                x_temp = x_temp, X[., (iii-1)*N+ii]
            }
            if (model != 0) x_temp = x_temp, x_deter
            real colvector bp
            bp = lusolve(x_temp'*x_temp, x_temp'*y_temp)
            if (model != 0) beta_mat[., ii] = bp[1::k]
            else beta_mat[., ii] = bp
            EG_resid[., ii] = y_temp - x_temp*bp
        }
    }
    else if (method == 1) {
        // CCE approaches

        if (opt_type == 0) {
            // Individual CCE
            for (ii = 1; ii <= N; ii++) {
                y_temp = Y[., ii]
                x_temp = X[., ii]
                for (iii = 2; iii <= k; iii++) {
                    x_temp = x_temp, X[., (iii-1)*N+ii]
                }
                if (model != 0) x_reg = x_temp, x_deter, y_cross_avg, x_cross_avg
                else            x_reg = x_temp, y_cross_avg, x_cross_avg

                real colvector bp2
                bp2 = lusolve(x_reg'*x_reg, x_reg'*y_temp)
                beta_mat[., ii] = bp2[1::k]

                if (model != 0) {
                    real matrix x_aug
                    x_aug = x_temp, x_deter
                    EG_resid[., ii] = y_temp - x_aug*bp2[1::cols(x_aug)]
                }
                else
                    EG_resid[., ii] = y_temp - x_temp*bp2[1::k]
            }
        }
        else if (opt_type == 1) {
            // Mean Group CCE
            beta_mgcce = J(N, k, 0)
            for (ii = 1; ii <= N; ii++) {
                y_temp = Y[., ii]
                x_temp = X[., ii]
                for (iii = 2; iii <= k; iii++) {
                    x_temp = x_temp, X[., (iii-1)*N+ii]
                }
                if (model != 0) x_reg = x_temp, x_deter, y_cross_avg, x_cross_avg
                else            x_reg = x_temp, y_cross_avg, x_cross_avg

                real colvector bp3
                bp3 = lusolve(x_reg'*x_reg, x_reg'*y_temp)
                beta_mgcce[ii, .] = bp3[1::k]'
            }
            beta_mgcce = mean(beta_mgcce)'    // k × 1 MG estimate
            beta_mat = beta_mgcce * J(1, N, 1)  // replicate for export

            for (ii = 1; ii <= N; ii++) {
                y_temp = Y[., ii]
                x_temp = X[., ii]
                for (iii = 2; iii <= k; iii++) {
                    x_temp = x_temp, X[., (iii-1)*N+ii]
                }
                EG_resid[., ii] = y_temp - x_temp * beta_mgcce
                if (model != 0) {
                    EG_resid[., ii] = EG_resid[., ii] - x_deter * lusolve(x_deter'*x_deter, x_deter'*EG_resid[., ii])
                }
            }
        }
        else {
            // ── Pooled CCE (PCCE) — option=2 ──────────────────────────────────
            // GAUSS lines 220-225: H_bar ALWAYS uses ALL k CS averages,
            // regardless of num_factors. The num_factors only affects Stage 2.
            // Paper Eq.(8): H̄ = [ᾱ, z̄] where z̄ = [ȳ, x̄_1,...,x̄_k]
            if (model != 0) H_bar = x_deter, y_cross_avg, x_cross_avg
            else            H_bar = y_cross_avg, x_cross_avg

            M_bar = I(T) - H_bar * lusolve(H_bar'*H_bar, H_bar')

            beta_ccep_num = J(k, 1, 0)
            beta_ccep_den = J(k, k, 0)

            for (ii = 1; ii <= N; ii++) {
                y_temp = Y[., ii]
                x_temp = X[., ii]
                for (iii = 2; iii <= k; iii++) {
                    x_temp = x_temp, X[., (iii-1)*N+ii]
                }
                beta_ccep_den = beta_ccep_den + x_temp'*M_bar*x_temp
                beta_ccep_num = beta_ccep_num + x_temp'*M_bar*y_temp
            }
            beta_ccep = lusolve(beta_ccep_den, beta_ccep_num)
            beta_mat  = beta_ccep * J(1, N, 1)  // k×N (same for all units)

            for (ii = 1; ii <= N; ii++) {
                y_temp = Y[., ii]
                x_temp = X[., ii]
                for (iii = 2; iii <= k; iii++) {
                    x_temp = x_temp, X[., (iii-1)*N+ii]
                }
                // GAUSS line 276: EG_resid = y - x*beta_ccep
                EG_resid[., ii] = y_temp - x_temp * beta_ccep
                // GAUSS line 278-280: detrend residual if model != 0
                if (model != 0) {
                    EG_resid[., ii] = EG_resid[., ii] - x_deter * lusolve(x_deter'*x_deter, x_deter'*EG_resid[., ii])
                }
            }
        }
    }

    // ── Stage 2: Individual CADF regressions ──────────────────────────
    t_cadf = xtcce_cadf_all(EG_resid, x_cross_avg, model, r_use, p_lags)

    // ── Truncation (Pesaran 2007, p.277) ─────────────────────────────
    if (do_trunc) {
        if (model == 1) { 
            cadf_lo = 6.19
            cadf_hi = 2.61 
        }
        else { 
            cadf_lo = 6.42
            cadf_hi = 1.70 
        }
        for (ii = 1; ii <= N; ii++) {
            if (t_cadf[ii] < -cadf_lo) t_cadf[ii] = -cadf_lo
            if (t_cadf[ii] >  cadf_hi) t_cadf[ii] =  cadf_hi
        }
    }

    // ── Panel statistic: CADF_P = mean(t_cadf) ───────────────────────
    panel_stat = mean(t_cadf)

    // ── Store results in Stata ────────────────────────────────────────
    // Panel statistic
    st_numscalar("_xcce_cadfp",   panel_stat[1])
    st_numscalar("_xcce_N",       N)
    st_numscalar("_xcce_T",       T)
    st_numscalar("_xcce_k",       k)
    st_numscalar("_xcce_r",       r_use)
    st_numscalar("_xcce_model",   model)
    st_numscalar("_xcce_method",  method)
    st_numscalar("_xcce_opttype", opt_type)
    st_numscalar("_xcce_plags",   p_lags)

    // Individual CADF statistics (N×1)
    st_matrix("_xcce_t_ind", t_cadf')

    // Slope estimates (k×1 vector of PCCE/MG/CCEI estimates)
    // Extract first row of beta_mat (same for PCCE, different for individual)
    st_matrix("_xcce_beta", beta_mat[., 1]')

    // Unit names for labeling
    // Store unit IDs for display
    st_matrix("_xcce_ids", id_uniq')

    if (verbose) {
        printf("  CADF_P = %8.4f\n", panel_stat[1])
        printf("  Individual statistics:\n")
        for (ii = 1; ii <= N; ii++) {
            printf("    Unit %g: t = %8.4f\n", id_uniq[ii], t_cadf[ii])
        }
    }
}


// ─────────────────────────────────────────────────────────────────────────
//  xtcce_cadf_all()
//
//  Implements cadf_multiple() from GAUSS.
//  Computes individual CADF test statistics for each panel unit.
//
//  Inputs:
//    EG_resid       : T × N matrix of EG residuals from Stage 1
//    x_cross_avg    : T × k matrix of CS averages of regressors
//    model          : 0, 1, or 2
//    num_factors    : r (number of CS averages to include in Stage 2)
//    p              : AR lag order
//
//  Returns:
//    t_cadf         : N × 1 vector of individual CADF t-ratios
//
//  Key GAUSS line: s2 = resid'resid / (T - cols(x_temp))  [line 401]
//  T is the ORIGINAL T (rows of EG_resid), not rows(y_temp) after trimming.
// ─────────────────────────────────────────────────────────────────────────
real colvector xtcce_cadf_all(real matrix EG_resid,
                               real matrix x_cross_avg,
                               real scalar model,
                               real scalar num_factors,
                               real scalar p)
{
    real scalar      N, T_orig, k
    real matrix      x_deter, EG_resid_crossmean, DEG_resid
    real matrix      DEG_resid_crossmean, EG_resid_lag, EG_resid_crossmean_lag
    real matrix      Dx_cross_avg, x_cross_avg_lag
    real colvector   t_cadf
    real scalar      ii
    real matrix      y_temp, x_temp, lagged_terms
    real scalar      iii
    real colvector   beta_param, resid
    real scalar      s2, t_ratio
    real matrix      var_beta

    N      = cols(EG_resid)
    T_orig = rows(EG_resid)     // GAUSS T: used in s2 denominator (line 401)
    k      = cols(x_cross_avg)

    // Build deterministic matrix
    if (model == 0)      x_deter = J(T_orig, 0, .)
    else if (model == 1) x_deter = J(T_orig, 1, 1)
    else                 x_deter = J(T_orig, 1, 1), (1::T_orig)

    // Validate num_factors
    if (num_factors < 1) num_factors = 1
    if (num_factors > k + 1) num_factors = k + 1

    // Compute cross-section averages of residuals
    EG_resid_crossmean = rowsum(EG_resid) :/ N  // T×1

    // First differences
    DEG_resid = EG_resid[2::T_orig, .] - EG_resid[1::T_orig-1, .]    // (T-1)×N
    DEG_resid_crossmean = rowsum(DEG_resid) :/ N                       // (T-1)×1

    // Lags
    EG_resid_lag          = EG_resid[1::T_orig-1, .]                // (T-1)×N
    EG_resid_crossmean_lag = EG_resid_crossmean[1::T_orig-1, .]     // (T-1)×1

    // CS averages of differences and lags of regressors (for num_factors > 1)
    if (num_factors > 1) {
        real matrix x_cs_use
        x_cs_use       = x_cross_avg[., 1::num_factors-1]             // T×(r-1)
        Dx_cross_avg   = x_cs_use[2::T_orig, .] - x_cs_use[1::T_orig-1, .]  // (T-1)×(r-1)
        x_cross_avg_lag = x_cs_use[1::T_orig-1, .]                    // (T-1)×(r-1)
    }

    t_cadf = J(N, 1, 0)

    for (ii = 1; ii <= N; ii++) {

        // Dependent: ΔÊᵢₜ for t=2,...,T
        // DEG_resid is (T-1)×N (already differenced). Rows 2..T-1 correspond
        // to t=3,...,T matching the lagged regressor EG_resid_lag[2::T-2].
        y_temp = DEG_resid[2::rows(DEG_resid), ii]  // (T-2) × 1

        // Base regressors:
        //  - Ê_{i,t-1} (lag of EG_resid for unit i)
        //  - cross-section mean lag: ē_{t-1}
        //  - cross-section mean difference: Δē_t
        //  - deterministics (if model != 0)
        real matrix ERL, ERCM_lag, DECM

        ERL      = EG_resid_lag[2::rows(EG_resid_lag), ii]          // rows 2..T-2
        ERCM_lag = EG_resid_crossmean_lag[2::rows(EG_resid_crossmean_lag)]
        DECM     = DEG_resid_crossmean[2::rows(DEG_resid_crossmean)]

        if (num_factors == 1) {
            // GAUSS line 356-358: ERL~ERCM_lag~DECM [~x_deter[2:T,.]]
            // y_temp = DEG_resid rows 2..T_orig-1 => (T_orig-2) obs
            // x_det rows must match: x_deter[3::T_orig,.] = rows 3..T_orig = (T_orig-2) rows
            if (model == 0) x_temp = ERL, ERCM_lag, DECM
            else            x_temp = ERL, ERCM_lag, DECM, x_deter[3::T_orig, .]
        }
        else {
            real matrix DXA, XCAL
            DXA  = Dx_cross_avg[2::rows(Dx_cross_avg), .]
            XCAL = x_cross_avg_lag[2::rows(x_cross_avg_lag), .]
            // GAUSS line 378-380: ERL~ERCM_lag~DECM~XCAL~DXA [~x_deter[2:T,.]]
            if (model == 0) x_temp = ERL, ERCM_lag, DECM, XCAL, DXA
            else            x_temp = ERL, ERCM_lag, DECM, XCAL, DXA, x_deter[3::T_orig, .]
        }

        // Add AR lags of Δê_it and Δē_t
        if (p > 0) {
            real matrix lag_y, lag_decm
            lag_y    = lag_matrix(y_temp, 1)
            lag_decm = lag_matrix(DECM, 1)
            lagged_terms = lag_y, lag_decm

            for (iii = 2; iii <= p; iii++) {
                lagged_terms = lagged_terms, lag_matrix(y_temp, iii), lag_matrix(DECM, iii)
            }

            if (num_factors > 1) {
                real matrix lag_dxa
                lag_dxa = lag_matrix(DXA, 1)
                lagged_terms = lagged_terms, lag_dxa
                for (iii = 2; iii <= p; iii++) {
                    lagged_terms = lagged_terms, lag_matrix(DXA, iii)
                }
            }

            // Trim: remove first p rows (NaN from lags)
            y_temp = y_temp[p+1::rows(y_temp)]
            real matrix x_all
            x_all  = x_temp, lagged_terms
            x_temp = x_all[p+1::rows(x_all), .]
        }

        // OLS regression — GAUSS line 399-403:
        //   beta_param = y_temp/x_temp
        //   s2 = resid'resid / (T - cols(x_temp))  [T = ORIGINAL T, not trimmed sample]
        real matrix XX_inv
        XX_inv = lusolve(x_temp'*x_temp, I(cols(x_temp)))
        beta_param = XX_inv * (x_temp'*y_temp)
        resid = y_temp - x_temp * beta_param
        // Use T_orig (GAUSS line 401 uses original T, not rows(y_temp))
        s2 = (resid'*resid) / (T_orig - cols(x_temp))
        var_beta = s2 * XX_inv

        // t-ratio on first coefficient: ê_{i,t-1}  [GAUSS line 404]
        t_cadf[ii] = beta_param[1] / sqrt(var_beta[1,1])
    }

    return(t_cadf)
}


// ─────────────────────────────────────────────────────────────────────────
//  lag_matrix()  — create lagged columns of a matrix
// ─────────────────────────────────────────────────────────────────────────
real matrix lag_matrix(real matrix X, real scalar k)
{
    real scalar T, nc
    T  = rows(X)
    nc = cols(X)
    if (k >= T) return(J(T, nc, .))
    return(J(k, nc, .) \ X[1::T-k, .])
}


end   // end mata block
