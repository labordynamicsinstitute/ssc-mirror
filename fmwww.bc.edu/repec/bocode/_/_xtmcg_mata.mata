*! _xtmcg_mata 1.0.0  22may2026  Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Mata core for the xtmulticointgrat package.
*! Implements: per-i first-level OLS, cumulation, ADF lag selection (t-sig/AIC/BIC),
*! Pedroni between-dimension Z_rho and Z_t statistics, PANIC factor extraction
*! (PC on first differences), Bai-Ng (2004) IC for factor selection, MQ_c test
*! for the number of stochastic trends in the factors, and pooled idiosyncratic ADF.
*! Loaded on demand via:
*!     qui capture mata: __xtmcg_loaded()
*!     if _rc qui _xtmcg_mata

version 14.0
mata
mata set matastrict off

void __xtmcg_loaded() { /* sentinel */ }


// ===========================================================================
// I.  Berenguer-Rico & Carrion-i-Silvestre (2006) MOMENTS  (Tables 1, 2, 3)
// ===========================================================================
// Tables 1 & 2 give finite-sample moments of  N^{-1/2} Z_rho_NT and Z_t_NT
// for four deterministic specs x five m1 (number of I(1) regressors, 0..4) x
// two m2 (number of I(2) regressors, 1..2) x four sample sizes T (50,100,250,1000).
//
// Returns a (5 x 16) matrix laid out as
//      [row m1=0..4 ;  col block (T=50,100,250,1000) x (Theta, Psi)]
// for the chosen (det, stat, m2).

real matrix _xtmcg_mom_block(string scalar det, string scalar stat, real scalar m2)
{
    real matrix M
    M = J(5,16,.)

    // Each row holds 4 (Theta,Psi) pairs = 8 columns; cols 9..16 unused.
    // Layout: [T50 Theta, T50 Psi, T100 Theta, T100 Psi, T250 Theta, T250 Psi,
    //          T1000 Theta, T1000 Psi]

    // ---------- NON-DETERMINISTIC ----------
    if (det=="none" & stat=="rho" & m2==1) {
        M[1,1..8] = (-5.654,26.739, -5.373,25.178, -5.213,24.894, -5.093,24.789)
        M[2,1..8] = (-10.037,45.394, -9.806,43.489, -9.620,42.471, -9.456,41.596)
        M[3,1..8] = (-14.189,65.113, -13.946,59.888, -13.849,59.566, -13.624,57.703)
        M[4,1..8] = (-18.157,85.567, -17.968,76.561, -17.899,74.861, -17.684,73.107)
        M[5,1..8] = (-21.994,108.195, -21.899,93.358, -21.898,90.320, -21.706,88.715)
        return(M)
    }
    if (det=="none" & stat=="rho" & m2==2) {
        M[1,1..8] = (-10.290,49.626, -9.616,43.187, -9.185,41.569, -8.823,40.649)
        M[2,1..8] = (-14.626,71.889, -13.989,61.523, -13.603,58.983, -13.214,56.987)
        M[3,1..8] = (-18.761,94.887, -18.142,79.496, -17.796,75.546, -17.414,72.969)
        M[4,1..8] = (-22.745,120.241, -22.166,97.678, -21.847,91.441, -21.473,88.537)
        M[5,1..8] = (-26.596,147.699, -26.094,116.281, -25.887,107.664, -25.507,103.787)
        return(M)
    }
    if (det=="none" & stat=="t" & m2==1) {
        M[1,1..8] = (-1.492,0.925, -1.377,0.875, -1.302,0.870, -1.250,0.908)
        M[2,1..8] = (-2.168,0.860, -2.059,0.778, -1.984,0.727, -1.935,0.706)
        M[3,1..8] = (-2.673,0.844, -2.554,0.735, -2.479,0.676, -2.421,0.630)
        M[4,1..8] = (-3.089,0.840, -2.963,0.730, -2.879,0.650, -2.816,0.594)
        M[5,1..8] = (-3.452,0.849, -3.319,0.725, -3.227,0.638, -3.160,0.577)
        return(M)
    }
    if (det=="none" & stat=="t" & m2==2) {
        M[1,1..8] = (-2.248,0.860, -2.070,0.750, -1.942,0.720, -1.846,0.743)
        M[2,1..8] = (-2.748,0.866, -2.579,0.740, -2.462,0.675, -2.376,0.649)
        M[3,1..8] = (-3.164,0.860, -2.995,0.729, -2.875,0.656, -2.790,0.606)
        M[4,1..8] = (-3.524,0.859, -3.353,0.731, -3.227,0.645, -3.140,0.584)
        M[5,1..8] = (-3.841,0.858, -3.671,0.726, -3.547,0.640, -3.454,0.571)
        return(M)
    }

    // ---------- CONSTANT ----------
    if (det=="c" & stat=="rho" & m2==1) {
        M[1,1..8] = (-10.381,44.055, -9.819,38.759, -9.453,36.351, -9.276,35.796)
        M[2,1..8] = (-14.259,64.275, -13.707,56.068, -13.329,52.227, -13.126,51.462)
        M[3,1..8] = (-18.144,85.923, -17.582,72.963, -17.251,68.480, -17.029,67.094)
        M[4,1..8] = (-22.060,110.768, -21.496,90.987, -21.185,84.285, -20.953,82.385)
        M[5,1..8] = (-25.878,136.910, -25.359,109.777, -25.125,100.824, -24.824,97.521)
        return(M)
    }
    if (det=="c" & stat=="rho" & m2==2) {
        M[1,1..8] = (-15.617,76.183, -14.387,59.183, -13.613,53.168, -13.240,51.578)
        M[2,1..8] = (-19.499,100.986, -18.286,77.465, -17.550,69.541, -17.101,66.796)
        M[3,1..8] = (-23.363,126.880, -22.163,95.559, -21.462,86.355, -20.987,82.306)
        M[4,1..8] = (-27.251,155.956, -26.081,116.434, -25.393,102.557, -24.895,97.005)
        M[5,1..8] = (-31.048,188.191, -29.933,137.205, -29.326,119.582, -28.764,111.988)
        return(M)
    }
    if (det=="c" & stat=="t" & m2==1) {
        M[1,1..8] = (-2.363,0.804, -2.218,0.723, -2.124,0.675, -2.071,0.663)
        M[2,1..8] = (-2.780,0.816, -2.641,0.722, -2.544,0.650, -2.489,0.617)
        M[3,1..8] = (-3.155,0.825, -3.015,0.720, -2.915,0.637, -2.855,0.595)
        M[4,1..8] = (-3.498,0.829, -3.356,0.722, -3.250,0.633, -3.184,0.577)
        M[5,1..8] = (-3.806,0.833, -3.664,0.724, -3.556,0.634, -3.480,0.568)
        return(M)
    }
    if (det=="c" & stat=="t" & m2==2) {
        M[1,1..8] = (-2.955,0.821, -2.742,0.702, -2.592,0.631, -2.502,0.608)
        M[2,1..8] = (-3.298,0.824, -3.100,0.713, -2.955,0.629, -2.863,0.587)
        M[3,1..8] = (-3.615,0.825, -3.426,0.713, -3.282,0.631, -3.187,0.578)
        M[4,1..8] = (-3.908,0.823, -3.728,0.715, -3.584,0.631, -3.486,0.565)
        M[5,1..8] = (-4.175,0.824, -4.007,0.718, -3.864,0.634, -3.759,0.559)
        return(M)
    }

    // ---------- LINEAR TREND ----------
    if (det=="ct" & stat=="rho" & m2==1) {
        M[1,1..8] = (-15.978,75.296, -14.712,58.648, -14.118,53.217, -13.706,51.180)
        M[2,1..8] = (-19.677,98.989, -18.407,76.561, -17.815,69.352, -17.423,67.149)
        M[3,1..8] = (-23.383,124.728, -22.166,94.558, -21.630,86.156, -21.222,82.757)
        M[4,1..8] = (-27.090,151.184, -25.947,113.290, -25.483,101.903, -25.062,97.387)
        M[5,1..8] = (-30.873,181.851, -29.763,133.997, -29.345,118.118, -28.907,112.825)
        return(M)
    }
    if (det=="ct" & stat=="rho" & m2==2) {
        M[1,1..8] = (-21.468,120.172, -19.259,83.279, -18.155,71.121, -17.472,66.520)
        M[2,1..8] = (-25.244,148.714, -23.055,103.193, -22.003,87.481, -21.281,82.437)
        M[3,1..8] = (-29.028,180.650, -26.858,122.963, -25.881,104.295, -25.115,97.409)
        M[4,1..8] = (-32.800,214.248, -30.689,144.101, -29.756,120.904, -28.988,111.843)
        M[5,1..8] = (-36.592,250.352, -34.532,167.071, -33.635,138.068, -32.839,127.237)
        return(M)
    }
    if (det=="ct" & stat=="t" & m2==1) {
        M[1,1..8] = (-2.972,0.791, -2.759,0.674, -2.634,0.609, -2.548,0.573)
        M[2,1..8] = (-3.300,0.804, -3.099,0.694, -2.974,0.619, -2.889,0.573)
        M[3,1..8] = (-3.604,0.814, -3.416,0.701, -3.291,0.627, -3.204,0.570)
        M[4,1..8] = (-3.889,0.816, -3.711,0.708, -3.588,0.628, -3.497,0.562)
        M[5,1..8] = (-4.158,0.823, -3.989,0.715, -3.864,0.629, -3.767,0.559)
        return(M)
    }
    if (det=="ct" & stat=="t" & m2==2) {
        M[1,1..8] = (-3.471,0.827, -3.195,0.700, -3.019,0.616, -2.895,0.568)
        M[2,1..8] = (-3.754,0.821, -3.501,0.708, -3.332,0.621, -3.210,0.567)
        M[3,1..8] = (-4.019,0.813, -3.786,0.708, -3.626,0.626, -3.501,0.560)
        M[4,1..8] = (-4.269,0.809, -4.055,0.709, -3.899,0.628, -3.774,0.553)
        M[5,1..8] = (-4.507,0.811, -4.309,0.711, -4.157,0.631, -4.028,0.552)
        return(M)
    }

    // ---------- QUADRATIC TREND ----------
    if (det=="ctt" & stat=="rho" & m2==1) {
        M[1,1..8] = (-21.887,117.198, -19.737,83.195, -18.556,69.827, -17.895,65.924)
        M[2,1..8] = (-25.485,145.813, -23.395,102.971, -22.239,86.462, -21.590,81.553)
        M[3,1..8] = (-29.169,177.125, -27.123,123.170, -25.992,103.017, -25.336,96.851)
        M[4,1..8] = (-32.826,210.241, -30.888,144.739, -29.814,119.555, -29.145,112.164)
        M[5,1..8] = (-36.543,248.073, -34.677,168.437, -33.646,136.887, -32.971,126.942)
        return(M)
    }
    if (det=="ctt" & stat=="rho" & m2==2) {
        M[1,1..8] = (-27.853,182.413, -24.477,115.187, -22.642,88.917, -21.549,80.452)
        M[2,1..8] = (-31.606,217.124, -28.277,137.932, -26.448,106.112, -25.343,96.868)
        M[3,1..8] = (-35.452,256.907, -32.103,160.992, -30.062,121.549, -28.911,109.766)
        M[4,1..8] = (-39.185,296.390, -35.962,185.851, -34.141,140.566, -32.996,126.828)
        M[5,1..8] = (-42.988,341.124, -39.786,211.252, -38.004,158.116, -36.848,141.614)
        return(M)
    }
    if (det=="ctt" & stat=="t" & m2==1) {
        M[1,1..8] = (-3.511,0.776, -3.238,0.669, -3.052,0.585, -2.934,0.545)
        M[2,1..8] = (-3.774,0.785, -3.529,0.686, -3.351,0.600, -3.236,0.549)
        M[3,1..8] = (-4.029,0.788, -3.806,0.692, -3.633,0.611, -3.518,0.549)
        M[4,1..8] = (-4.271,0.797, -4.068,0.699, -3.903,0.615, -3.785,0.549)
        M[5,1..8] = (-4.501,0.804, -4.317,0.702, -4.156,0.619, -4.037,0.547)
        return(M)
    }
    if (det=="ctt" & stat=="t" & m2==2) {
        M[1,1..8] = (-3.951,0.816, -3.630,0.709, -3.396,0.604, -3.233,0.550)
        M[2,1..8] = (-4.186,0.806, -3.898,0.709, -3.678,0.613, -3.519,0.550)
        M[3,1..8] = (-4.412,0.796, -4.153,0.703, -3.942,0.618, -3.786,0.548)
        M[4,1..8] = (-4.625,0.792, -4.396,0.704, -4.195,0.620, -4.038,0.546)
        M[5,1..8] = (-4.828,0.793, -4.622,0.700, -4.434,0.622, -4.278,0.545)
        return(M)
    }

    return(M)
}


// Linearly interpolate (Theta, Psi) for a given T from Table 1 / Table 2.
real rowvector _xtmcg_mom_lookup(string scalar det, string scalar stat,
                                  real scalar m1, real scalar m2, real scalar T)
{
    real matrix M
    real rowvector row, Tgrid, out
    real scalar mm1, mm2, T0, w, lo, hi

    mm1 = m1
    mm2 = m2
    if (mm1 < 0) mm1 = 0
    if (mm1 > 4) mm1 = 4
    if (mm2 < 1) mm2 = 1
    if (mm2 > 2) mm2 = 2

    M = _xtmcg_mom_block(det, stat, mm2)
    row = M[mm1+1, 1..8]
    Tgrid = (50, 100, 250, 1000)

    out = J(1, 2, 0)
    if (T <= Tgrid[1]) {
        out[1] = row[1]
        out[2] = row[2]
        return(out)
    }
    if (T >= Tgrid[4]) {
        out[1] = row[7]
        out[2] = row[8]
        return(out)
    }
    if (T <= Tgrid[2]) {
        lo = 1
        hi = 2
    } else if (T <= Tgrid[3]) {
        lo = 2
        hi = 3
    } else {
        lo = 3
        hi = 4
    }
    w = (T - Tgrid[lo])/(Tgrid[hi] - Tgrid[lo])
    out[1] = (1-w)*row[2*lo-1] + w*row[2*hi-1]
    out[2] = (1-w)*row[2*lo]   + w*row[2*hi]
    return(out)
}


// Table 3: idiosyncratic ADF moments (constant vs. trend specs)
//   "c"  -> ADF_e_c   "t" -> ADF_e_tau
real rowvector _xtmcg_mom_idio(string scalar spec, real scalar T)
{
    real matrix M
    real rowvector row, Tgrid, out
    real scalar lo, hi, w

    M = (-0.401, 1.167, -0.410, 1.054, -0.420, 0.996, -0.421, 0.970 \
         -1.563, 0.415, -1.554, 0.378, -1.540, 0.357, -1.529, 0.339)
    if (spec == "c") row = M[1, .]
    else             row = M[2, .]
    Tgrid = (50, 100, 250, 1000)
    out = J(1,2,0)
    if (T <= Tgrid[1]) {
        out = (row[1], row[2])
        return(out)
    }
    if (T >= Tgrid[4]) {
        out = (row[7], row[8])
        return(out)
    }
    if (T <= Tgrid[2]) {
        lo = 1
        hi = 2
    } else if (T <= Tgrid[3]) {
        lo = 2
        hi = 3
    } else {
        lo = 3
        hi = 4
    }
    w = (T - Tgrid[lo])/(Tgrid[hi] - Tgrid[lo])
    out[1] = (1-w)*row[2*lo-1] + w*row[2*hi-1]
    out[2] = (1-w)*row[2*lo]   + w*row[2*hi]
    return(out)
}


// ===========================================================================
// II.  Helper utilities
// ===========================================================================

// OLS coefficients (no intercept added internally)
real colvector _xtmcg_ols(real matrix Y, real matrix X)
{
    return(qrsolve(quadcross(X,X), quadcross(X,Y)))
}

// Detrend a column vector x by regressing on (constant) or (constant, trend)
real colvector _xtmcg_detrend(real colvector x, string scalar det)
{
    real scalar T
    real matrix W
    real colvector b, r
    T = rows(x)
    if (det == "none") return(x)
    if (det == "c") W = J(T,1,1)
    else if (det == "ct") W = (J(T,1,1), (1::T))
    else                  W = (J(T,1,1), (1::T), (1::T):^2)
    b = qrsolve(quadcross(W,W), quadcross(W,x))
    r = x - W*b
    return(r)
}

// Build deterministic regressor matrix for given length T
real matrix _xtmcg_det(real scalar T, string scalar det)
{
    if (det == "none") return(J(T,0,0))
    if (det == "c")    return(J(T,1,1))
    if (det == "ct")   return((J(T,1,1), (1::T)))
    return((J(T,1,1), (1::T), (1::T):^2))
}

// Cumulative sum of a column
real colvector _xtmcg_cumsum(real colvector x)
{
    real colvector y
    real scalar i, n
    n = rows(x)
    y = J(n,1,0)
    y[1] = x[1]
    for (i=2; i<=n; i++) y[i] = y[i-1] + x[i]
    return(y)
}


// ===========================================================================
// III.  ADF regression with lag selection (t-sig, AIC, BIC, fixed)
// ===========================================================================
// Returns (1 x 4) rowvector: (rho, t_rho, sum_phi, p_used)
real rowvector _xtmcg_adf(real colvector y, real scalar pmax, string scalar lagsel,
                          string scalar det)
{
    real scalar T, p, j, k, dfres, sigma2, rho, t_rho, sum_phi, best_p, best_ic
    real scalar tlast, ic, RSS
    real colvector dy, lev, b, e
    real matrix X, Z, det_mat
    real rowvector out

    T = rows(y)
    dy = y[2..T] :- y[1..(T-1)]    // length T-1
    lev = y[1..(T-1)]              // y_{t-1}

    if (lagsel == "fixed") {
        best_p = pmax
    } else if (lagsel == "tsig") {
        // Ng & Perron (1995) sequential t-rule: start at pmax, drop one
        // lag at a time while |t| on highest lag < 1.96.
        best_p = pmax
        for (p=pmax; p>=1; p--) {
            X = lev[(p+1)..(T-1)]
            for (j=1; j<=p; j++) {
                X = (X, dy[(p+1-j)..(T-1-j)])
            }
            det_mat = _xtmcg_det(rows(X), det)
            if (cols(det_mat) > 0) X = (X, det_mat)
            Z = dy[(p+1)..(T-1)]
            b = qrsolve(quadcross(X,X), quadcross(X,Z))
            e = Z - X*b
            dfres = rows(X) - cols(X)
            if (dfres <= 0) continue
            sigma2 = (e'e)/dfres
            if (sigma2 <= 0) continue
            tlast = b[p+1] / sqrt(sigma2 * invsym(quadcross(X,X))[p+1,p+1])
            if (abs(tlast) >= 1.96) {
                best_p = p
                break
            }
            if (p == 1) best_p = 0
        }
    } else {
        // AIC / BIC / HQIC: try p=0..pmax, pick min IC
        best_p = 0
        best_ic = .
        for (p=0; p<=pmax; p++) {
            X = lev[(pmax+1)..(T-1)]
            for (j=1; j<=p; j++) {
                X = (X, dy[(pmax+1-j)..(T-1-j)])
            }
            det_mat = _xtmcg_det(rows(X), det)
            if (cols(det_mat) > 0) X = (X, det_mat)
            Z = dy[(pmax+1)..(T-1)]
            b = qrsolve(quadcross(X,X), quadcross(X,Z))
            e = Z - X*b
            k = cols(X)
            if (rows(X) <= k) continue
            RSS = e'e
            if (RSS <= 0) continue
            sigma2 = RSS/rows(X)
            if (lagsel == "aic") {
                ic = ln(sigma2) + 2*k/rows(X)
            } else if (lagsel == "bic") {
                ic = ln(sigma2) + ln(rows(X))*k/rows(X)
            } else if (lagsel == "hqic") {
                ic = ln(sigma2) + 2*k*ln(ln(rows(X)))/rows(X)
            } else {
                ic = .
            }
            if (ic < best_ic | best_ic == .) {
                best_ic = ic
                best_p = p
            }
        }
    }

    // Final ADF regression with best_p lags
    p = best_p
    if (p > T-3) p = T-3
    if (p < 0) p = 0
    X = lev[(p+1)..(T-1)]
    for (j=1; j<=p; j++) {
        X = (X, dy[(p+1-j)..(T-1-j)])
    }
    det_mat = _xtmcg_det(rows(X), det)
    if (cols(det_mat) > 0) X = (X, det_mat)
    Z = dy[(p+1)..(T-1)]
    b = qrsolve(quadcross(X,X), quadcross(X,Z))
    e = Z - X*b
    dfres = rows(X) - cols(X)
    sigma2 = (e'e)/dfres
    rho = b[1]
    t_rho = rho / sqrt(sigma2 * invsym(quadcross(X,X))[1,1])
    sum_phi = 0
    if (p > 0) {
        for (j=1; j<=p; j++) sum_phi = sum_phi + b[1+j]
    }
    out = (rho, t_rho, sum_phi, p)
    return(out)
}


// ===========================================================================
// IV.  Per-i first-level cointegration: u = y - det α - X β,  S = Σu
// ===========================================================================
// y, X: (T x 1) and (T x k) matrices for one individual
// det:  "none","c","ct","ctt"
// Returns S_t (T x 1) cumulated residual.
real colvector _xtmcg_firstlevel(real colvector y, real matrix X, string scalar det)
{
    real matrix W, R
    real colvector b, u
    real scalar T, dx, dd
    T = rows(y)
    dx = cols(X)
    R = _xtmcg_det(T, det)
    dd = cols(R)
    W = (R, X)
    if (cols(W) == 0) {
        u = y
    } else {
        b = qrsolve(quadcross(W,W), quadcross(W,y))
        u = y - W*b
    }
    return(_xtmcg_cumsum(u))
}


// ===========================================================================
// V.  PANIC factor extraction on first differences of u-hat
// ===========================================================================
// U: T x N matrix of stage-2 residuals (one column per individual)
// det: deterministic spec for the second-stage regression
// rmax: maximum number of factors
// icname: "ic1","ic2","ic3","bic3"  -> Bai-Ng (2002) panel IC for factor number
//
// Returns Fhat, Lambdahat, ehat (idiosyncratic, recovered by cumsum), r_selected.
// Output via st_matrix for use back in Stata.

void _xtmcg_panic(string scalar Uname, string scalar det, real scalar rmax,
                   string scalar icname,
                   string scalar Fname, string scalar Lname, string scalar Ename,
                   string scalar rsel_name)
{
    real matrix U, dU, F, Lam, e, Fhat, Lhat, ehat, ehat_lev
    real matrix V, evecs
    real colvector evals
    real scalar T, N, Tm, k, r, r_star, ic_min, ic_val, sigma2, NT, c, i
    real rowvector sums

    U = st_matrix(Uname)
    T = rows(U)
    N = cols(U)
    if (rmax > min((T,N))-1) rmax = min((T,N))-1
    if (rmax < 1) rmax = 1

    // First-difference each column
    dU = U[2..T,.] - U[1..(T-1),.]
    Tm = rows(dU)

    // Demean columns (PANIC routine works on demeaned ΔU)
    for (i=1; i<=N; i++) dU[.,i] = dU[.,i] :- mean(dU[.,i])

    // PCA: eigen-decomposition of (1/(T*N)) ΔU * ΔU'
    // Use SVD of dU for numerical stability
    // dU = U * S * V', columns of U are principal components of rows
    V = dU * dU'        // Tm x Tm
    V = V / (Tm * N)
    symeigensystem(V, evecs, evals)   // returns DESCENDING (largest first)
    // Build factor estimates Fhat (Tm x k) and loadings Lhat (N x k) for each k
    // Select k via panel IC of Bai-Ng (2002).
    NT = Tm*N
    c  = min((Tm,N))

    r_star = 1
    ic_min = .
    for (k=1; k<=rmax; k++) {
        F = sqrt(Tm) * evecs[., 1..k]               // Tm x k
        Lam = (F' * dU)' / Tm                        // N x k
        e = dU - F * Lam'                            // Tm x N
        sigma2 = sum(e:^2) / NT
        if (icname == "ic1") ic_val = ln(sigma2) + k*((Tm+N)/NT)*ln(NT/(Tm+N))
        else if (icname == "ic2") ic_val = ln(sigma2) + k*((Tm+N)/NT)*ln(c)
        else if (icname == "ic3") ic_val = ln(sigma2) + k*(ln(c)/c)
        else if (icname == "bic3") ic_val = sigma2 + k*sigma2*((Tm+N-k)*ln(NT))/NT
        else ic_val = .
        if (ic_val < ic_min | ic_min == .) {
            ic_min = ic_val
            r_star = k
        }
    }

    // Final extraction at r_star
    r = r_star
    Fhat = sqrt(Tm) * evecs[., 1..r]
    Lhat = (Fhat' * dU)' / Tm
    ehat = dU - Fhat * Lhat'

    // Recover LEVELS of idiosyncratic + factor: cumulate by column
    ehat_lev = J(T, N, 0)
    for (i=1; i<=N; i++) ehat_lev[2..T, i] = _xtmcg_cumsum(ehat[., i])

    // Cumulate factors too
    real matrix Fhat_lev
    Fhat_lev = J(T, r, 0)
    for (i=1; i<=r; i++) Fhat_lev[2..T, i] = _xtmcg_cumsum(Fhat[., i])

    st_matrix(Fname, Fhat_lev)
    st_matrix(Lname, Lhat)
    st_matrix(Ename, ehat_lev)
    st_numscalar(rsel_name, r_star)
}


// ===========================================================================
// VI.  Pedroni between-dimension panel statistics for multicointegration
//      (cross-section independent case, Theorem 1).
// ===========================================================================
// Ymat: T x N panel of dep var (one column per i), Xmat: T x (N*m1) flow regressors,
// Xcum: T x (N*m2) cumulated I(2) regressors. m1, m2 fixed across i.
// det:  "none","c","ct","ctt"
// pmax, lagsel: ADF lag controls.
//
// Returns per-i ADF table and pooled stats via st_matrix / st_numscalar.

void _xtmcg_pedroni_indep(string scalar Yname, string scalar Xname, string scalar Xcumname,
                           real scalar m1, real scalar m2, string scalar det,
                           real scalar pmax, string scalar lagsel,
                           string scalar adfname, string scalar poolname)
{
    real matrix Y, X, Xc, R, W, ADFtab
    real colvector y_i, u_i, b
    real matrix X_i, Xc_i, Yfull
    real scalar T, N, i, p_used, rho_i, t_i, sumphi_i
    real scalar Z_rho_raw, Z_t_raw, Nused
    real rowvector adfres, pool
    real matrix Worig

    Y  = st_matrix(Yname)
    X  = st_matrix(Xname)
    Xc = st_matrix(Xcumname)
    T  = rows(Y)
    N  = cols(Y)

    ADFtab = J(N, 4, .)
    Z_rho_raw = 0
    Z_t_raw   = 0
    Nused     = 0

    for (i=1; i<=N; i++) {
        y_i = Y[.,i]
        if (m1 == 0) X_i = J(T,0,0)
        else         X_i = X[., (1+(i-1)*m1)..(i*m1)]
        if (m2 == 0) Xc_i = J(T,0,0)
        else         Xc_i = Xc[., (1+(i-1)*m2)..(i*m2)]

        // Build full regressor matrix: det, Xc_i (I(2)), X_i (I(1))
        R = _xtmcg_det(T, det)
        W = (R, Xc_i, X_i)
        if (cols(W) == 0) {
            u_i = y_i
        } else {
            b   = qrsolve(quadcross(W,W), quadcross(W,y_i))
            u_i = y_i - W*b
        }

        // ADF on u_i with NO deterministics (already partialled out)
        adfres = _xtmcg_adf(u_i, pmax, lagsel, "none")
        rho_i    = adfres[1]
        t_i      = adfres[2]
        sumphi_i = adfres[3]
        p_used   = adfres[4]
        ADFtab[i, 1] = rho_i
        ADFtab[i, 2] = t_i
        ADFtab[i, 3] = sumphi_i
        ADFtab[i, 4] = p_used

        if (rho_i != . & t_i != . & (1 - sumphi_i) != 0) {
            Z_rho_raw = Z_rho_raw + (T * rho_i)/(1 - sumphi_i)
            Z_t_raw   = Z_t_raw + t_i
            Nused = Nused + 1
        }
    }

    // Pool: N^{-1/2} Z = (1/sqrt(N)) * Z_raw
    real scalar Z_rho_pool, Z_t_pool, Theta1, Psi1, Theta2, Psi2, std_rho, std_t
    real rowvector mom_r, mom_t

    Z_rho_pool = Z_rho_raw / sqrt(Nused)
    Z_t_pool   = Z_t_raw   / sqrt(Nused)

    mom_r = _xtmcg_mom_lookup(det, "rho", m1, m2, T)
    mom_t = _xtmcg_mom_lookup(det, "t",   m1, m2, T)
    Theta1 = mom_r[1]; Psi1 = mom_r[2]
    Theta2 = mom_t[1]; Psi2 = mom_t[2]

    // Standardized statistics ~ N(0,1) under H0
    std_rho = (Z_rho_pool - Theta1*sqrt(Nused)) / sqrt(Psi1)
    std_t   = (Z_t_pool   - Theta2*sqrt(Nused)) / sqrt(Psi2)

    pool = (Z_rho_pool, Z_t_pool, std_rho, std_t, Theta1, Psi1, Theta2, Psi2, Nused, T)

    st_matrix(adfname, ADFtab)
    st_matrix(poolname, pool)
}


// ===========================================================================
// VII.  Common-factor branch: PANIC + pooled idiosyncratic ADF + MQ_c on F
// ===========================================================================
// For each i:  1) y_i on (det, x_i) -> ϑ̂_i, then S_i = cumsum(ϑ̂_i)
//              2) y_i on (det, S_i)  -> u_i  (Granger-Lee two-step, eq 11)
// Then assemble U (T x N), pass to PANIC factor extraction.
// Apply pooled ADF to idiosyncratic (LEVELS) using Table 3 moments.
// For factors: ADF on each (if r=1) or MQ_c test (if r>1).

void _xtmcg_twostep_resid(string scalar Yname, string scalar Xname, real scalar m1,
                           string scalar det,
                           string scalar Sname, string scalar Uname)
{
    real matrix Y, X, S, U
    real colvector y_i, S_i, b, u_i
    real matrix R, X_i, W
    real scalar T, N, i, dx

    Y = st_matrix(Yname)
    X = st_matrix(Xname)
    T = rows(Y)
    N = cols(Y)

    S = J(T, N, 0)
    U = J(T, N, 0)

    for (i=1; i<=N; i++) {
        y_i = Y[.,i]
        if (m1 == 0) X_i = J(T,0,0)
        else         X_i = X[., (1+(i-1)*m1)..(i*m1)]
        // Stage 1: y on (det, x) -> ϑ̂, S_t = cumsum
        S_i = _xtmcg_firstlevel(y_i, X_i, det)
        S[., i] = S_i
        // Stage 2: y on (det, S) -> u_t
        R = _xtmcg_det(T, det)
        W = (R, S_i)
        if (cols(W) == 0) {
            u_i = y_i
        } else {
            b   = qrsolve(quadcross(W,W), quadcross(W,y_i))
            u_i = y_i - W*b
        }
        U[., i] = u_i
    }

    st_matrix(Sname, S)
    st_matrix(Uname, U)
}


// Pooled idiosyncratic ADF: read ehat (T x N), run ADF on each col, pool.
void _xtmcg_pool_idio_adf(string scalar Ename, string scalar det,
                           real scalar pmax, string scalar lagsel,
                           string scalar adfname, string scalar poolname)
{
    real matrix E, ADFtab
    real colvector e_i
    real scalar T, N, i, Nused, sum_t, Theta_e, Psi_e, T_eff
    real rowvector adfres, pool, mom
    string scalar spec

    E = st_matrix(Ename)
    T = rows(E)
    N = cols(E)
    ADFtab = J(N, 4, .)
    sum_t = 0
    Nused = 0
    for (i=1; i<=N; i++) {
        e_i = E[.,i]
        adfres = _xtmcg_adf(e_i, pmax, lagsel, det)
        ADFtab[i,] = adfres
        if (adfres[2] != .) {
            sum_t = sum_t + adfres[2]
            Nused = Nused + 1
        }
    }
    T_eff = T
    spec = (det == "c" ? "c" : "t")
    mom = _xtmcg_mom_idio(spec, T_eff)
    Theta_e = mom[1]
    Psi_e   = mom[2]

    real scalar Zbar, Zstd
    Zbar = sum_t / sqrt(Nused)
    Zstd = (sum_t/Nused - Theta_e) * sqrt(Nused/Psi_e)

    pool = (Zbar, Zstd, Theta_e, Psi_e, Nused, T_eff)
    st_matrix(adfname, ADFtab)
    st_matrix(poolname, pool)
}


// MQ_c parametric (Bai-Ng 2004) - determine the number of stochastic trends
// among r estimated factors. We implement a simplified version: for each
// candidate number of common stochastic trends q (0..r), run an ADF on
// successively orthogonalised factors and apply the joint procedure.
//
// Returned: vector of t-statistics for each cumulative factor (1..r) after
// detrending; the user then reads the column showing how many > 5% c.v.

void _xtmcg_mq_test(string scalar Fname, string scalar det, real scalar pmax,
                     string scalar lagsel, string scalar outname)
{
    real matrix F, OUT
    real colvector f_j
    real scalar T, r, j
    real rowvector adfres

    F = st_matrix(Fname)
    T = rows(F)
    r = cols(F)
    OUT = J(r, 4, .)
    for (j=1; j<=r; j++) {
        f_j = F[., j]
        adfres = _xtmcg_adf(f_j, pmax, lagsel, det)
        OUT[j,] = adfres
    }
    st_matrix(outname, OUT)
}


// ===========================================================================
// VIII.  Build T x N matrices from a (long) Stata panel
// ===========================================================================
void _xtmcg_build_matrices(string scalar yvar, string scalar xvars,
                           string scalar ivar, string scalar tvar,
                           string scalar touse,
                           string scalar Yname, string scalar Xname,
                           string scalar Xcumname)
{
    real matrix data, Y, X, Xc
    real colvector ids, vx_col
    real scalar N, T, i, j, m1
    string rowvector xs
    real matrix sub

    xs = tokens(xvars)
    m1 = length(xs)

    data = st_data(., (ivar, tvar, yvar, xs), touse)
    ids  = uniqrows(data[.,1])
    N    = length(ids)
    T    = sum(data[.,1] :== ids[1])

    Y  = J(T, N, .)
    X  = J(T, N*m1, .)
    Xc = J(T, N*m1, .)

    for (i=1; i<=N; i++) {
        sub = select(data, data[.,1] :== ids[i])
        sub = sort(sub, 2)
        Y[., i] = sub[., 3]
        for (j=1; j<=m1; j++) {
            vx_col = sub[., 3+j]
            X[., (i-1)*m1 + j]  = vx_col
            Xc[., (i-1)*m1 + j] = _xtmcg_cumsum(vx_col)
        }
    }
    st_matrix(Yname,    Y)
    st_matrix(Xname,    X)
    st_matrix(Xcumname, Xc)
}


// ===========================================================================
// IX.  Persist factor / residual matrices back into the Stata dataset
// ===========================================================================
void _xtmcg_persist(string scalar Sname, string scalar Uname,
                    string scalar Ename, string scalar Fname,
                    string scalar ivar, string scalar tvar, string scalar touse)
{
    real matrix S, U, E, F
    real scalar T, N, r, i, k, t, nobs
    real colvector ids, idfull, tfull, tousefull
    real colvector slot_S, slot_U, slot_E
    real matrix slot_F
    real colvector mask, tvals_i, idx_full
    real matrix sortmat

    S = st_matrix(Sname)
    U = st_matrix(Uname)
    E = st_matrix(Ename)
    F = st_matrix(Fname)
    T = rows(S)
    N = cols(S)
    r = cols(F)

    nobs      = st_nobs()
    idfull    = st_data(., ivar)
    tfull     = st_data(., tvar)
    tousefull = st_data(., touse)
    ids       = uniqrows(select(idfull, tousefull))

    slot_S = J(nobs, 1, .)
    slot_U = J(nobs, 1, .)
    slot_E = J(nobs, 1, .)
    slot_F = J(nobs, r, .)

    for (i=1; i<=N; i++) {
        mask     = (idfull :== ids[i]) :& (tousefull :== 1)
        idx_full = select(range(1, nobs, 1), mask)
        tvals_i  = select(tfull, mask)
        sortmat  = sort((tvals_i, idx_full), 1)
        for (t=1; t<=rows(sortmat); t++) {
            slot_S[sortmat[t,2], 1] = S[t, i]
            slot_U[sortmat[t,2], 1] = U[t, i]
            slot_E[sortmat[t,2], 1] = E[t, i]
            for (k=1; k<=r; k++) slot_F[sortmat[t,2], k] = F[t, k]
        }
    }

    (void) st_addvar("double", "_xtmcg_S_i")
    (void) st_addvar("double", "_xtmcg_u_i")
    (void) st_addvar("double", "_xtmcg_e_i")
    st_store(., "_xtmcg_S_i", slot_S)
    st_store(., "_xtmcg_u_i", slot_U)
    st_store(., "_xtmcg_e_i", slot_E)
    for (k=1; k<=r; k++) {
        (void) st_addvar("double", "_xtmcg_F" + strofreal(k))
        st_store(., "_xtmcg_F" + strofreal(k), slot_F[., k])
    }
}

end
