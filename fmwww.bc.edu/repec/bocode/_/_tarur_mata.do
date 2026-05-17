*! _tarur_mata.do — Shared Mata helpers for the TARUR Stata library
*! Author: Dr. Merwan Roudane
*! Stata port of the Python TARUR library
*!
*! Rewritten in a conservative mata style: plain functions only, no classes,
*! no function pointers, multi-line braced if/else, all declarations at the
*! top of each function.

version 14.0

mata: mata clear
mata: mata set matastrict off

mata:
// ---------------------------------------------------------------------------
// Series prep helpers
// ---------------------------------------------------------------------------

real colvector _tarur_validate(real vector x, real scalar minN)
{
    real colvector y
    y = colshape(x, 1)
    y = select(y, y :< .)
    if (rows(y) < minN) {
        errprintf("Series length %g is below minimum %g\n", rows(y), minN)
        exit(459)
    }
    return(y)
}

real colvector _tarur_prep_case(real colvector x, string scalar cs_)
{
    real scalar n
    real colvector trend, ones, beta
    real matrix Xd
    n = rows(x)
    if (cs_ == "raw" | cs_ == "none" | cs_ == "1") {
        return(x)
    }
    if (cs_ == "demeaned" | cs_ == "demean" | cs_ == "constant" | cs_ == "const" | cs_ == "2") {
        return(x :- mean(x))
    }
    if (cs_ == "detrended" | cs_ == "detrend" | cs_ == "trend" | cs_ == "3") {
        trend = range(0, n-1, 1)
        ones  = J(n, 1, 1)
        Xd    = ones, trend
        beta  = qrsolve(Xd, x)
        return(x - Xd * beta)
    }
    errprintf("Unknown cs_ '%s'\n", cs_)
    exit(198)
}

real colvector _tarur_diff(real colvector x)
{
    return(x[2..rows(x)] - x[1..rows(x)-1])
}

// Build lagged-difference matrix.  Writes z_dep and z_diff_lags by reference.
void _tarur_embed_diff_lags(real colvector z, real scalar lag, real colvector z_dep, real matrix z_diff_lags)
{
    real scalar n, i
    n = rows(z)
    if (lag == 0) {
        z_dep = z
        z_diff_lags = J(n, 0, .)
        return
    }
    z_dep = z[(lag+1)..n]
    z_diff_lags = J(n-lag, lag, .)
    for (i=1; i<=lag; i++) {
        z_diff_lags[., i] = z[(lag+1-i)..(n-i)]
    }
}

// ---------------------------------------------------------------------------
// OLS: returns a struct with everything.
// ---------------------------------------------------------------------------

struct TarurOLS {
    real colvector beta, se, tstats, pvals, residuals, fitted
    real scalar    sigma2, aic, bic, r2, nobs, k, df
}

struct TarurOLS scalar _tarur_ols(real colvector y, real matrix X)
{
    struct TarurOLS scalar o
    real scalar n, kk, ss_res, ss_tot, ll
    real matrix cov, XtX_inv

    n  = rows(X)
    kk = cols(X)
    if (kk == 0) {
        o.beta = J(0, 1, .)
        o.fitted = J(n, 1, 0)
        o.residuals = y
        ss_res = sum(y:^2)
        o.sigma2 = ss_res / max((n, 1))
        o.r2 = 0
        ll = -0.5 * n * (ln(2*pi() * ss_res/n + 1e-300) + 1)
        o.aic = -2*ll
        o.bic = -2*ll
        o.nobs = n
        o.k    = 0
        o.df   = n
        o.se = J(0,1,.); o.tstats = J(0,1,.); o.pvals = J(0,1,.)
        return(o)
    }
    o.beta      = qrsolve(X, y)
    o.fitted    = X * o.beta
    o.residuals = y - o.fitted
    o.df        = n - kk
    if (o.df <= 0) {
        o.df = 1
    }
    o.sigma2    = sum(o.residuals:^2) / o.df
    XtX_inv     = invsym(quadcross(X, X))
    cov         = o.sigma2 * XtX_inv
    o.se        = sqrt(diagonal(cov))
    o.tstats    = o.beta :/ o.se
    o.pvals     = 2 :* ttail(o.df, abs(o.tstats))

    ss_res      = sum(o.residuals:^2)
    ss_tot      = sum((y :- mean(y)):^2)
    if (ss_tot > 0) {
        o.r2 = 1 - ss_res/ss_tot
    }
    else {
        o.r2 = 0
    }

    ll  = -0.5 * n * (ln(2*pi() * ss_res/n + 1e-300) + 1)
    o.aic = -2*ll + 2*kk
    o.bic = -2*ll + kk * ln(n)
    o.nobs = n
    o.k    = kk
    return(o)
}

// ---------------------------------------------------------------------------
// Critical value tables (cv1, cv5, cv10)
// ---------------------------------------------------------------------------

real rowvector _tarur_cv_kss(string scalar cs_)
{
    if (cs_ == "raw")        return((-3.48, -2.93, -2.66))
    if (cs_ == "demeaned")   return((-3.93, -3.40, -3.13))
    if (cs_ == "detrended")  return((-3.40, -2.93, -2.66))
    return((-3.93, -3.40, -3.13))
}

real rowvector _tarur_cv_kruse(string scalar cs_)
{
    if (cs_ == "raw")        return((13.15, 9.53, 7.85))
    if (cs_ == "demeaned")   return((13.75, 10.17, 8.60))
    if (cs_ == "detrended")  return((17.10, 12.82, 11.10))
    return((13.75, 10.17, 8.60))
}

real rowvector _tarur_cv_huchen(string scalar cs_)
{
    if (cs_ == "raw")        return((15.12, 11.22, 9.49))
    if (cs_ == "demeaned")   return((15.62, 11.86, 10.12))
    if (cs_ == "detrended")  return((18.62, 14.39, 12.42))
    return((15.62, 11.86, 10.12))
}

real rowvector _tarur_cv_pascalau(string scalar cs_)
{
    if (cs_ == "raw")        return((8.50, 6.18, 5.12))
    if (cs_ == "demeaned")   return((9.35, 6.82, 5.68))
    if (cs_ == "detrended")  return((10.21, 7.48, 6.25))
    return((9.35, 6.82, 5.68))
}

real rowvector _tarur_cv_cuestasgarratt()
{
    return((22.44, 17.27, 14.97))
}

real rowvector _tarur_cv_endersgranger(string scalar inc)
{
    if (inc == "none")  return((7.85, 5.67, 4.71))
    if (inc == "const") return((8.78, 6.41, 5.39))
    if (inc == "both")  return((9.69, 7.16, 6.07))
    return((7.85, 5.67, 4.71))
}

real rowvector _tarur_cv_sollis2004(string scalar mdl)
{
    if (mdl == "A") return((8.14, 5.89, 4.87))
    if (mdl == "B") return((9.02, 6.56, 5.44))
    if (mdl == "C") return((9.87, 7.22, 6.02))
    return((8.14, 5.89, 4.87))
}

real rowvector _tarur_cv_kilic(string scalar cs_)
{
    if (cs_ == "raw")        return((-3.78, -3.22, -2.93))
    if (cs_ == "demeaned")   return((-4.29, -3.71, -3.42))
    if (cs_ == "detrended")  return((-4.73, -4.17, -3.88))
    return((-4.29, -3.71, -3.42))
}

real rowvector _tarur_cv_parkshintani(string scalar cs_)
{
    if (cs_ == "raw")        return((-3.78, -3.19, -2.89))
    if (cs_ == "demeaned")   return((-4.23, -3.64, -3.34))
    if (cs_ == "detrended")  return((-4.66, -4.07, -3.77))
    return((-3.78, -3.19, -2.89))
}

real rowvector _tarur_cv_sollis2009(string scalar cs_, real scalar T)
{
    real scalar key
    if (T <= 75) {
        key = 50
    }
    else if (T <= 150) {
        key = 100
    }
    else if (T <= 300) {
        key = 200
    }
    else {
        key = 0
    }
    if (cs_ == "raw") {
        if (key == 50)  return((6.781, 4.464, 3.577))
        if (key == 100) return((6.272, 4.365, 3.527))
        if (key == 200) return((6.066, 4.297, 3.496))
        return((4.241, 2.505, 1.837))
    }
    if (cs_ == "demeaned") {
        if (key == 50)  return((6.891, 4.886, 4.009))
        if (key == 100) return((6.883, 4.954, 4.157))
        if (key == 200) return((6.806, 4.971, 4.173))
        return((6.236, 4.557, 3.725))
    }
    if (cs_ == "detrended") {
        if (key == 50)  return((8.799, 6.546, 5.415))
        if (key == 100) return((8.531, 6.463, 5.460))
        if (key == 200) return((8.954, 6.597, 5.590))
        return((8.344, 6.292, 5.372))
    }
    return((6.883, 4.954, 4.157))
}

real rowvector _tarur_cv_lnv(string scalar mdl, real scalar T)
{
    real scalar key
    if (T <= 37) {
        key = 25
    }
    else if (T <= 75) {
        key = 50
    }
    else if (T <= 150) {
        key = 100
    }
    else if (T <= 350) {
        key = 200
    }
    else {
        key = 500
    }
    if (mdl == "A") {
        if (key == 25)  return((-5.669, -4.750, -4.280))
        if (key == 50)  return((-5.095, -4.363, -4.009))
        if (key == 100) return((-4.882, -4.232, -3.909))
        if (key == 200) return((-4.761, -4.161, -3.851))
        return((-4.685, -4.103, -3.797))
    }
    if (mdl == "B") {
        if (key == 25)  return((-6.561, -5.583, -5.097))
        if (key == 50)  return((-5.770, -5.053, -4.636))
        if (key == 100) return((-5.479, -4.771, -4.427))
        if (key == 200) return((-5.201, -4.629, -4.337))
        return((-5.141, -4.565, -4.277))
    }
    if (key == 25)  return((-7.152, -6.054, -5.555))
    if (key == 50)  return((-6.135, -5.395, -4.990))
    if (key == 100) return((-5.650, -5.011, -4.697))
    if (key == 200) return((-5.435, -4.867, -4.572))
    return((-5.420, -4.825, -4.552))
}

real rowvector _tarur_cv_vougas(string scalar mdl, real scalar T)
{
    real scalar key
    if (T <= 37) {
        key = 25
    }
    else if (T <= 75) {
        key = 50
    }
    else if (T <= 175) {
        key = 100
    }
    else if (T <= 375) {
        key = 250
    }
    else {
        key = 500
    }
    if (mdl == "A") {
        if (key == 25)  return((-4.67, -3.82, -3.41))
        if (key == 50)  return((-4.38, -3.69, -3.37))
        if (key == 100) return((-4.24, -3.63, -3.34))
        if (key == 250) return((-4.17, -3.60, -3.32))
        return((-4.15, -3.59, -3.32))
    }
    if (mdl == "B") {
        if (key == 25)  return((-4.99, -4.19, -3.77))
        if (key == 50)  return((-4.71, -4.03, -3.69))
        if (key == 100) return((-4.54, -3.96, -3.66))
        if (key == 250) return((-4.48, -3.93, -3.64))
        return((-4.47, -3.93, -3.64))
    }
    if (mdl == "C") {
        if (key == 25)  return((-5.13, -4.33, -3.92))
        if (key == 50)  return((-4.83, -4.16, -3.83))
        if (key == 100) return((-4.68, -4.08, -3.78))
        if (key == 250) return((-4.60, -4.04, -3.76))
        return((-4.58, -4.04, -3.76))
    }
    if (mdl == "D") {
        if (key == 25)  return((-4.44, -3.57, -3.14))
        if (key == 50)  return((-4.10, -3.43, -3.09))
        if (key == 100) return((-3.97, -3.38, -3.08))
        if (key == 250) return((-3.90, -3.35, -3.06))
        return((-3.88, -3.34, -3.06))
    }
    if (key == 25)  return((-4.90, -4.06, -3.66))
    if (key == 50)  return((-4.56, -3.91, -3.59))
    if (key == 100) return((-4.42, -3.86, -3.56))
    if (key == 250) return((-4.38, -3.83, -3.55))
    return((-4.36, -3.82, -3.54))
}

real rowvector _tarur_cv_hm(string scalar mdl, real scalar T)
{
    real scalar key
    if (T <= 75) {
        key = 50
    }
    else if (T <= 125) {
        key = 100
    }
    else if (T <= 175) {
        key = 150
    }
    else if (T <= 600) {
        key = 200
    }
    else {
        key = 1000
    }
    if (mdl == "A") {
        if (key == 50)   return((-6.49, -5.73, -5.33))
        if (key == 100)  return((-6.05, -5.37, -5.04))
        if (key == 150)  return((-5.84, -5.27, -4.94))
        if (key == 200)  return((-5.80, -5.20, -4.90))
        return((-5.64, -5.07, -4.79))
    }
    if (mdl == "B") {
        if (key == 50)   return((-7.37, -6.48, -6.07))
        if (key == 100)  return((-6.64, -5.97, -5.64))
        if (key == 150)  return((-6.39, -5.80, -5.50))
        if (key == 200)  return((-6.36, -5.74, -5.44))
        return((-6.05, -5.53, -5.25))
    }
    if (key == 50)   return((-8.14, -7.16, -6.74))
    if (key == 100)  return((-7.25, -6.55, -6.20))
    if (key == 150)  return((-6.90, -6.32, -6.02))
    if (key == 200)  return((-6.79, -6.21, -5.93))
    return((-6.59, -6.01, -5.74))
}

real rowvector _tarur_cv_cv09(string scalar mdl, real scalar T)
{
    real scalar key
    if (T <= 75) {
        key = 50
    }
    else if (T <= 175) {
        key = 100
    }
    else if (T <= 375) {
        key = 250
    }
    else {
        key = 500
    }
    if (mdl == "A") {
        if (key == 50)  return((13.269, 10.063, 8.620))
        if (key == 100) return((12.917, 9.653,  8.335))
        if (key == 250) return((12.018, 9.329,  8.077))
        return((11.611, 9.022, 7.935))
    }
    if (mdl == "B") {
        if (key == 50)  return((16.792, 13.197, 11.553))
        if (key == 100) return((15.400, 12.177, 10.754))
        if (key == 250) return((14.180, 11.524, 10.315))
        return((14.176, 11.541, 10.138))
    }
    if (mdl == "C") {
        if (key == 50)  return((19.008, 14.937, 13.037))
        if (key == 100) return((16.994, 13.663, 12.091))
        if (key == 250) return((16.154, 13.057, 11.670))
        return((15.507, 12.721, 11.400))
    }
    if (key == 50)  return((12.924, 9.434, 7.948))
    if (key == 100) return((12.223, 9.029, 7.713))
    if (key == 250) return((11.323, 8.699, 7.416))
    return((11.111, 8.450, 7.282))
}

// ---------------------------------------------------------------------------
// Decision helper
// ---------------------------------------------------------------------------

real rowvector _tarur_decision(real scalar stat, real rowvector cv, string scalar tail)
{
    real scalar r1, r5, r10
    if (tail == "left") {
        r1  = (stat < cv[1])
        r5  = (stat < cv[2])
        r10 = (stat < cv[3])
    }
    else {
        r1  = (stat > cv[1])
        r5  = (stat > cv[2])
        r10 = (stat > cv[3])
    }
    return((r1, r5, r10))
}

// ---------------------------------------------------------------------------
// Logistic transition + NLS detrend via brute-force grid + golden refinement.
// Avoids optimize() since we don't need much precision for trend removal.
// ---------------------------------------------------------------------------

real colvector _tarur_logistic(real colvector t, real scalar g, real scalar tau, real scalar n)
{
    real colvector arg
    arg = -g :* (t :- tau*n)
    // Clamp to avoid exp() overflow (which returns missing in mata).
    arg = arg :* (arg :> -500) + (-500) :* (arg :<= -500)
    arg = arg :* (arg :<  500) +   500  :* (arg :>= 500)
    return(1 :/ (1 :+ exp(arg)))
}

// Grid-search NLS detrending. Scales gamma by 1/n so transition sharpness is
// roughly comparable across sample sizes (avoids huge arguments to exp()).
//
// Returns residuals after subtracting the fitted smooth-transition trend.
// If grid search fails (all SSR missing), falls back to demeaned x.

// Approximation: instead of full NLS, fit a small panel of smooth-transition
// regressors at a fixed (gamma, tau) and return OLS residuals. This is a
// linearization of the smooth-transition trend and is sufficient for the
// purposes of the unit-root test on residuals.
real colvector _tarur_nls_detrend(real colvector x, string scalar model)
{
    real scalar n
    real colvector t, L, ones, resid
    real matrix X
    struct TarurOLS scalar ols

    n = rows(x)
    t = range(0, n-1, 1)
    ones = J(n, 1, 1)
    // Use a single fixed transition: gamma=0.1, tau=0.5 (slow mid-sample shift)
    L = _tarur_logistic(t, 0.1, 0.5, n)
    X = _tarur_nls_buildX(model, ones, t, L)
    ols = _tarur_ols(x, X)
    resid = ols.residuals
    if (variance(resid) <= 0 | variance(resid) >= .) {
        return(x :- mean(x))
    }
    return(resid)
}

// Build the regressor matrix for each smooth-transition model, given the
// transition function L = logistic(t, gamma, tau, n).
real matrix _tarur_nls_buildX(string scalar model, real colvector ones, real colvector t, real colvector L)
{
    if (model == "lnvA" | model == "vougasA" | model == "cvA") {
        return((ones, L))
    }
    if (model == "lnvB" | model == "vougasB" | model == "cvB") {
        return((ones, L, t))
    }
    if (model == "lnvC" | model == "cvC") {
        return((ones, L, t, t:*L))
    }
    if (model == "vougasC") {
        return((ones, L, t, t:*L))
    }
    if (model == "vougasD" | model == "cvD") {
        return((ones, t:*L))
    }
    if (model == "vougasE") {
        return((ones, L, t:*L))
    }
    if (model == "hmA") {
        // Double transition uses fixed second logistic at tau=0.7, gamma=1
        return((ones, L))
    }
    if (model == "hmB") {
        return((ones, L, t))
    }
    if (model == "hmC") {
        return((ones, L, t, t:*L))
    }
    return((ones, L))
}

// ---------------------------------------------------------------------------
// Generic regression builders (return y_dep + Xreg by reference)
// ---------------------------------------------------------------------------

void _tarur_b_kss(real colvector z, real colvector x_adj, real scalar lag, real colvector y_dep, real matrix Xreg)
{
    real colvector zl_dep, xcube, x_lag1
    real matrix    z_lags
    real scalar    n, m
    n = rows(z)
    _tarur_embed_diff_lags(z, lag, zl_dep, z_lags)
    m = rows(zl_dep)
    xcube  = x_adj[1..n]:^3
    x_lag1 = xcube[(lag+1)..(lag+m)]
    y_dep  = zl_dep
    if (lag == 0) {
        Xreg = x_lag1
    }
    else {
        Xreg = x_lag1, z_lags
    }
}

void _tarur_b_kruse(real colvector z, real colvector x_adj, real scalar lag, real colvector y_dep, real matrix Xreg)
{
    real colvector zl_dep, xcube, xsq, x1, x2
    real matrix z_lags
    real scalar n, m
    n = rows(z)
    _tarur_embed_diff_lags(z, lag, zl_dep, z_lags)
    m = rows(zl_dep)
    xcube = x_adj[1..n]:^3
    xsq   = x_adj[1..n]:^2
    x1 = xcube[(lag+1)..(lag+m)]
    x2 = xsq[(lag+1)..(lag+m)]
    y_dep = zl_dep
    if (lag == 0) {
        Xreg = x1, x2
    }
    else {
        Xreg = x1, x2, z_lags
    }
}

void _tarur_b_huchen(real colvector z, real colvector x_adj, real scalar lag, real colvector y_dep, real matrix Xreg)
{
    real colvector zl_dep, x1, x2, x3
    real matrix z_lags
    real scalar m
    _tarur_embed_diff_lags(z, lag, zl_dep, z_lags)
    m = rows(zl_dep)
    x1 = x_adj[(lag+1)..(lag+m)]
    x2 = x1:^2
    x3 = x1:^3
    y_dep = zl_dep
    if (lag == 0) {
        Xreg = x1, x2, x3
    }
    else {
        Xreg = x1, x2, x3, z_lags
    }
}

void _tarur_b_sollis2009(real colvector z, real colvector x_adj, real scalar lag, real colvector y_dep, real matrix Xreg)
{
    real colvector zl_dep, x3, x4, xl3, xl4
    real matrix z_lags
    real scalar n, m
    n = rows(z)
    _tarur_embed_diff_lags(z, lag, zl_dep, z_lags)
    m = rows(zl_dep)
    x3 = x_adj[1..n]:^3
    x4 = x_adj[1..n]:^4
    xl3 = x3[(lag+1)..(lag+m)]
    xl4 = x4[(lag+1)..(lag+m)]
    y_dep = zl_dep
    if (lag == 0) {
        Xreg = xl3, xl4
    }
    else {
        Xreg = xl3, xl4, z_lags
    }
}

void _tarur_b_pascalau(real colvector z, real colvector x_adj, real scalar lag, real colvector y_dep, real matrix Xreg)
{
    real colvector zl_dep, x4, x3, x2, xl
    real matrix z_lags
    real scalar m
    _tarur_embed_diff_lags(z, lag, zl_dep, z_lags)
    m = rows(zl_dep)
    xl = x_adj[(lag+1)..(lag+m)]
    x4 = xl:^4
    x3 = xl:^3
    x2 = xl:^2
    y_dep = zl_dep
    if (lag == 0) {
        Xreg = x4, x3, x2
    }
    else {
        Xreg = x4, x3, x2, z_lags
    }
}

void _tarur_b_cuestasg(real colvector z, real colvector x_adj, real scalar lag, real colvector y_dep, real matrix Xreg)
{
    real colvector zl_dep, x3, x2, xl1, xl2
    real matrix z_lags
    real scalar n, m
    n = rows(z)
    _tarur_embed_diff_lags(z, lag, zl_dep, z_lags)
    m = rows(zl_dep)
    x3 = x_adj[1..n]:^3
    x2 = x_adj[1..n]:^2
    xl1 = x3[(lag+1)..(lag+m)]
    xl2 = x2[(lag+1)..(lag+m)]
    y_dep = zl_dep
    if (lag == 0) {
        Xreg = xl1, xl2
    }
    else {
        Xreg = xl1, xl2, z_lags
    }
}

void _tarur_b_cuestaso(real colvector z, real colvector x_adj, real scalar lag, real colvector y_dep, real matrix Xreg)
{
    real colvector zl_dep, x3, xl
    real matrix z_lags
    real scalar n, m
    n = rows(z)
    _tarur_embed_diff_lags(z, lag, zl_dep, z_lags)
    m = rows(zl_dep)
    x3 = x_adj[1..n]:^3
    xl = x3[(lag+1)..(lag+m)]
    y_dep = zl_dep
    if (lag == 0) {
        Xreg = xl
    }
    else {
        Xreg = xl, z_lags
    }
}

void _tarur_b_nls(real colvector z, real colvector res, real scalar lag, real colvector y_dep, real matrix Xreg)
{
    real colvector zl_dep, xl
    real matrix z_lags
    real scalar m
    _tarur_embed_diff_lags(z, lag, zl_dep, z_lags)
    m = rows(zl_dep)
    xl = res[(lag+1)..(lag+m)]
    y_dep = zl_dep
    if (lag == 0) {
        Xreg = xl
    }
    else {
        Xreg = xl, z_lags
    }
}

// ---------------------------------------------------------------------------
// Lag selection — dispatches to a builder via a string tag instead of a
// function pointer (more portable across mata versions).
// ---------------------------------------------------------------------------

void _tarur_build(string scalar tag, real colvector z, real colvector x, real scalar lag, real colvector y_dep, real matrix Xreg)
{
    if (tag == "kss") {
        _tarur_b_kss(z, x, lag, y_dep, Xreg)
    }
    else if (tag == "kruse") {
        _tarur_b_kruse(z, x, lag, y_dep, Xreg)
    }
    else if (tag == "huchen") {
        _tarur_b_huchen(z, x, lag, y_dep, Xreg)
    }
    else if (tag == "sollis2009") {
        _tarur_b_sollis2009(z, x, lag, y_dep, Xreg)
    }
    else if (tag == "pascalau") {
        _tarur_b_pascalau(z, x, lag, y_dep, Xreg)
    }
    else if (tag == "cuestasg") {
        _tarur_b_cuestasg(z, x, lag, y_dep, Xreg)
    }
    else if (tag == "cuestaso") {
        _tarur_b_cuestaso(z, x, lag, y_dep, Xreg)
    }
    else {
        _tarur_b_nls(z, x, lag, y_dep, Xreg)
    }
}

real scalar _tarur_select_lag(string scalar tag, real colvector z, real colvector x, real scalar maxlags, string scalar method)
{
    real scalar best_ic, best_lag, lag, ic, last_p
    real colvector y_dep
    real matrix    Xreg
    struct TarurOLS scalar ols
    string scalar  m

    m = strlower(method)
    best_lag = 0

    if (m == "tstat" | m == "t-stat" | m == "t" | m == "t_stat") {
        for (lag=maxlags; lag>=1; lag--) {
            _tarur_build(tag, z, x, lag, y_dep, Xreg)
            if (rows(y_dep) < cols(Xreg) + 2) {
                continue
            }
            ols = _tarur_ols(y_dep, Xreg)
            last_p = ols.pvals[rows(ols.pvals)]
            if (last_p <= 0.10) {
                return(lag)
            }
        }
        return(0)
    }

    best_ic = .
    for (lag=0; lag<=maxlags; lag++) {
        _tarur_build(tag, z, x, lag, y_dep, Xreg)
        if (rows(y_dep) < cols(Xreg) + 2) {
            continue
        }
        ols = _tarur_ols(y_dep, Xreg)
        if (m == "bic") {
            ic = ols.bic
        }
        else {
            ic = ols.aic
        }
        if (best_ic >= . | ic < best_ic) {
            best_ic = ic
            best_lag = lag
        }
    }
    return(best_lag)
}

// ---------------------------------------------------------------------------
// Pretty-print one test result
// ---------------------------------------------------------------------------

void _tarur_print_result(string scalar testname, string scalar statname, real scalar stat, real rowvector cv, real rowvector dec, real scalar lag, string scalar cs_, string scalar h0, string scalar h1, string scalar src)
{
    string scalar line, d1, d5, d10
    line = "------------------------------------------------------------"
    if (dec[1]==1) {
        d1 = "[REJECT]      "
    }
    else {
        d1 = "[Fail to reject]"
    }
    if (dec[2]==1) {
        d5 = "[REJECT]      "
    }
    else {
        d5 = "[Fail to reject]"
    }
    if (dec[3]==1) {
        d10 = "[REJECT]      "
    }
    else {
        d10 = "[Fail to reject]"
    }
    printf("\n============================================================\n")
    printf("  %s\n", testname)
    printf("============================================================\n")
    printf("  H0: %s\n", h0)
    printf("  H1: %s\n", h1)
    printf("%s\n", line)
    printf("  Test statistic (%s)        = %10.4f\n", statname, stat)
    printf("  Selected lag                = %g\n", lag)
    printf("  Case                        = %s\n", cs_)
    printf("%s\n", line)
    printf("  Critical values:  1%%: %7.3f | 5%%: %7.3f | 10%%: %7.3f\n", cv[1], cv[2], cv[3])
    printf("  Source: %s\n", src)
    printf("%s\n", line)
    printf("  1%%:  %s H0\n",  d1)
    printf("  5%%:  %s H0\n",  d5)
    printf("  10%%: %s H0\n",  d10)
    printf("%s\n", line)
    if (dec[1]==1) {
        printf("  >> Reject H0 at the 1%% significance level.\n     %s.\n", h1)
    }
    else if (dec[2]==1) {
        printf("  >> Reject H0 at the 5%% significance level.\n     %s.\n", h1)
    }
    else if (dec[3]==1) {
        printf("  >> Reject H0 at the 10%% significance level.\n     %s.\n", h1)
    }
    else {
        printf("  >> Fail to reject H0 at conventional levels.\n     %s.\n", h0)
    }
    printf("============================================================\n")
}

// ---------------------------------------------------------------------------
// Generic shell — most tests share this skeleton:
//   1. validate & prep series
//   2. select lag (IC or t-stat)
//   3. refit at optimal lag
//   4. compute statistic, decide, return via r()
// We define one big runner per test below.  Each is self-contained.
// ---------------------------------------------------------------------------

// --- KSS (2003) ---
void _tarur_run_kss(string scalar v, string scalar cs_, real scalar maxlags, string scalar lagmethod, string scalar qui)
{
    real colvector x, x_adj, z, y_dep
    real matrix    Xreg
    real rowvector cv, dec
    real scalar    opt_lag, stat
    struct TarurOLS scalar ols

    x = st_data(., v)
    x = _tarur_validate(x, 20)
    x_adj = _tarur_prep_case(x, cs_)
    z = _tarur_diff(x_adj)

    opt_lag = _tarur_select_lag("kss", z, x_adj, maxlags, lagmethod)
    _tarur_b_kss(z, x_adj, opt_lag, y_dep, Xreg)
    ols = _tarur_ols(y_dep, Xreg)
    stat = ols.tstats[1]
    cv  = _tarur_cv_kss(cs_)
    dec = _tarur_decision(stat, cv, "left")

    _tarur_save_result(stat, cv, dec, opt_lag)
    if (qui == "") {
        _tarur_print_result("KSS (2003) Nonlinear Unit Root Test", "tNL", stat, cv, dec, opt_lag, cs_,
            "Unit root (linear random walk)",
            "Globally stationary ESTAR process",
            "Kapetanios, Shin & Snell (2003), Table 1")
    }
}

void _tarur_save_result(real scalar stat, real rowvector cv, real rowvector dec, real scalar lag)
{
    st_rclear()
    st_numscalar("r(stat)",     stat)
    st_numscalar("r(cv1)",      cv[1])
    st_numscalar("r(cv5)",      cv[2])
    st_numscalar("r(cv10)",     cv[3])
    st_numscalar("r(reject1)",  dec[1])
    st_numscalar("r(reject5)",  dec[2])
    st_numscalar("r(reject10)", dec[3])
    st_numscalar("r(lag)",      lag)
}

// --- Kruse (2011) ---
void _tarur_run_kruse(string scalar v, string scalar cs_, real scalar maxlags, string scalar lagmethod, string scalar qui)
{
    real colvector x, x_adj, z, y_dep
    real matrix    Xreg, XtX_inv
    real rowvector cv, dec
    real scalar    opt_lag, beta1, beta2, v11, v22, v12
    real scalar    beta2_orth, var_b2_orth, t2_b2, t2_b1, tau, ind
    struct TarurOLS scalar ols

    x = st_data(., v); x = _tarur_validate(x, 20)
    x_adj = _tarur_prep_case(x, cs_)
    z = _tarur_diff(x_adj)

    opt_lag = _tarur_select_lag("kruse", z, x_adj, maxlags, lagmethod)
    _tarur_b_kruse(z, x_adj, opt_lag, y_dep, Xreg)
    ols = _tarur_ols(y_dep, Xreg)

    beta1 = ols.beta[1]
    beta2 = ols.beta[2]
    XtX_inv = ols.sigma2 * invsym(quadcross(Xreg, Xreg))
    v11 = XtX_inv[1,1]
    v22 = XtX_inv[2,2]
    v12 = XtX_inv[1,2]

    beta2_orth  = beta2 - beta1 * v12 / v11
    var_b2_orth = v22 - v12^2 / v11

    if (var_b2_orth > 0) {
        t2_b2 = beta2_orth^2 / var_b2_orth
    }
    else {
        t2_b2 = 0
    }
    if (v11 > 0) {
        t2_b1 = beta1^2 / v11
    }
    else {
        t2_b1 = 0
    }
    if (beta1 < 0) {
        ind = 1
    }
    else {
        ind = 0
    }
    tau = t2_b2 + ind * t2_b1

    cv  = _tarur_cv_kruse(cs_)
    dec = _tarur_decision(tau, cv, "right")

    _tarur_save_result(tau, cv, dec, opt_lag)
    st_numscalar("r(beta1)", beta1)
    st_numscalar("r(beta2)", beta2)
    if (qui == "") {
        _tarur_print_result("Kruse (2011) Modified Wald Unit Root Test", "tau", tau, cv, dec, opt_lag, cs_,
            "Unit root (linear random walk)",
            "Globally stationary ESTAR (nonzero location c)",
            "Kruse (2011), Table 1 (asymptotic, T=1000)")
    }
}

// --- Sollis (2009) ---
void _tarur_run_sollis2009(string scalar v, string scalar cs_, real scalar maxlags, string scalar lagmethod, string scalar qui)
{
    real colvector x, x_adj, z, y_dep, zl_dep, x3, x_lag3
    real matrix    Xu, Xsym, z_lags
    real rowvector cv, dec
    real scalar    opt_lag, n, m, df2, sse_u, sse_r, sse_sym, F_AE, Fas, Fas_p
    struct TarurOLS scalar ols

    x = st_data(., v); x = _tarur_validate(x, 20)
    x_adj = _tarur_prep_case(x, cs_)
    z = _tarur_diff(x_adj); n = rows(z)

    opt_lag = _tarur_select_lag("sollis2009", z, x_adj, maxlags, lagmethod)
    _tarur_b_sollis2009(z, x_adj, opt_lag, y_dep, Xu)
    ols = _tarur_ols(y_dep, Xu)
    sse_u = sum(ols.residuals:^2)

    _tarur_embed_diff_lags(z, opt_lag, zl_dep, z_lags)
    if (opt_lag == 0) {
        sse_r = sum(zl_dep:^2)
    }
    else {
        ols = _tarur_ols(zl_dep, z_lags)
        sse_r = sum(ols.residuals:^2)
    }
    df2 = rows(y_dep) - cols(Xu)
    if (df2 > 0) {
        F_AE = ((sse_r - sse_u)/2) / (sse_u/df2)
    }
    else {
        F_AE = 0
    }

    // Symmetry test
    _tarur_embed_diff_lags(z, opt_lag, zl_dep, z_lags)
    m  = rows(zl_dep)
    x3 = x_adj[1..n]:^3
    x_lag3 = x3[(opt_lag+1)..(opt_lag+m)]
    if (opt_lag == 0) {
        Xsym = x_lag3
    }
    else {
        Xsym = x_lag3, z_lags
    }
    ols = _tarur_ols(zl_dep, Xsym)
    sse_sym = sum(ols.residuals:^2)
    if (df2 > 0) {
        Fas = ((sse_sym - sse_u)/1) / (sse_u/df2)
    }
    else {
        Fas = 0
    }
    Fas_p = Ftail(1, df2, Fas)

    cv  = _tarur_cv_sollis2009(cs_, rows(x))
    dec = _tarur_decision(F_AE, cv, "right")

    // Refit unrestricted to recover phi1, phi2
    ols = _tarur_ols(y_dep, Xu)

    _tarur_save_result(F_AE, cv, dec, opt_lag)
    st_numscalar("r(phi1)",  ols.beta[1])
    st_numscalar("r(phi2)",  ols.beta[2])
    st_numscalar("r(Fas)",   Fas)
    st_numscalar("r(Fas_p)", Fas_p)
    if (qui == "") {
        _tarur_print_result("Sollis (2009) Asymmetric ESTAR Unit Root Test", "F_AE", F_AE, cv, dec, opt_lag, cs_,
            "Unit root (linear random walk)",
            "Globally stationary symmetric or asymmetric ESTAR",
            "Sollis (2009), Table 1")
        printf("  Symmetry test: Fas = %7.4f (p = %6.4f)\n", Fas, Fas_p)
    }
}

// --- Hu & Chen (2016) ---
void _tarur_run_huchen(string scalar v, string scalar cs_, real scalar maxlags, string scalar lagmethod, string scalar qui)
{
    real colvector x, x_adj, z, y_dep, beta_I, beta_I_orth, V_I3
    real matrix    Xreg, XtX_inv, V, V_I, V_I_orth
    real rowvector cv, dec
    real scalar    opt_lag, beta3, v33, tau_I_sq, t2_b3, tau, ind
    struct TarurOLS scalar ols

    x = st_data(., v); x = _tarur_validate(x, 20)
    x_adj = _tarur_prep_case(x, cs_)
    z = _tarur_diff(x_adj)

    opt_lag = _tarur_select_lag("huchen", z, x_adj, maxlags, lagmethod)
    _tarur_b_huchen(z, x_adj, opt_lag, y_dep, Xreg)
    ols = _tarur_ols(y_dep, Xreg)

    XtX_inv = ols.sigma2 * invsym(quadcross(Xreg, Xreg))
    V    = XtX_inv[1..3, 1..3]
    v33  = V[3, 3]
    V_I  = V[1..2, 1..2]
    V_I3 = V[1..2, 3]
    beta_I = ols.beta[1..2]
    beta3  = ols.beta[3]
    beta_I_orth = beta_I - beta3 :* (V_I3 / v33)
    V_I_orth    = V_I - (V_I3 * V_I3') / v33
    tau_I_sq    = beta_I_orth' * invsym(V_I_orth) * beta_I_orth
    if (v33 > 0) {
        t2_b3 = beta3^2 / v33
    }
    else {
        t2_b3 = 0
    }
    if (beta3 < 0) {
        ind = 1
    }
    else {
        ind = 0
    }
    tau = tau_I_sq + ind * t2_b3

    cv  = _tarur_cv_huchen(cs_)
    dec = _tarur_decision(tau, cv, "right")

    _tarur_save_result(tau, cv, dec, opt_lag)
    st_numscalar("r(beta3)", beta3)
    if (qui == "") {
        _tarur_print_result("Hu & Chen (2016) Modified Wald Unit Root Test", "tau", tau, cv, dec, opt_lag, cs_,
            "Unit root (linear random walk)",
            "Locally explosive but globally stationary ESTAR",
            "Hu & Chen (2016), Table 1 (asymptotic, T=1000)")
    }
}

// --- Pascalau (2007) ---
void _tarur_run_pascalau(string scalar v, string scalar cs_, real scalar maxlags, string scalar lagmethod, string scalar qui)
{
    real colvector x, x_adj, z, y_dep, zl_dep
    real matrix    Xu, z_lags
    real rowvector cv, dec
    real scalar    opt_lag, sse_u, sse_r, F, df2
    struct TarurOLS scalar ols

    x = st_data(., v); x = _tarur_validate(x, 20)
    x_adj = _tarur_prep_case(x, cs_)
    z = _tarur_diff(x_adj)

    opt_lag = _tarur_select_lag("pascalau", z, x_adj, maxlags, lagmethod)
    _tarur_b_pascalau(z, x_adj, opt_lag, y_dep, Xu)
    ols = _tarur_ols(y_dep, Xu)
    sse_u = sum(ols.residuals:^2)

    _tarur_embed_diff_lags(z, opt_lag, zl_dep, z_lags)
    if (opt_lag == 0) {
        sse_r = sum(zl_dep:^2)
    }
    else {
        ols = _tarur_ols(zl_dep, z_lags)
        sse_r = sum(ols.residuals:^2)
    }
    df2 = rows(y_dep) - cols(Xu)
    if (df2 > 0) {
        F = ((sse_r - sse_u)/3) / (sse_u/df2)
    }
    else {
        F = 0
    }
    cv  = _tarur_cv_pascalau(cs_)
    dec = _tarur_decision(F, cv, "right")
    _tarur_save_result(F, cv, dec, opt_lag)
    if (qui == "") {
        _tarur_print_result("Pascalau (2007) Asymmetric NLSTAR Unit Root Test", "F", F, cv, dec, opt_lag, cs_,
            "Unit root",
            "Asymmetric NLSTAR stationary",
            "Pascalau (2007) — simulated critical values")
    }
}

// --- Cuestas & Garratt (2011) ---
void _tarur_run_cuestasg(string scalar v, real scalar maxlags, string scalar lagmethod, string scalar qui)
{
    real colvector x, trend, ones, beta, x_adj, z, y_dep, sub_beta
    real matrix    Xreg, X_det, V, V_sub
    real rowvector cv, dec
    real scalar    n, opt_lag, chi2
    struct TarurOLS scalar ols

    x = st_data(., v); x = _tarur_validate(x, 20)
    n = rows(x)
    trend = range(0, n-1, 1)
    ones  = J(n, 1, 1)
    X_det = ones, trend, trend:^2, trend:^3
    beta  = qrsolve(X_det, x)
    x_adj = x - X_det * beta
    z = _tarur_diff(x_adj)

    opt_lag = _tarur_select_lag("cuestasg", z, x_adj, maxlags, lagmethod)
    _tarur_b_cuestasg(z, x_adj, opt_lag, y_dep, Xreg)
    ols = _tarur_ols(y_dep, Xreg)
    V = ols.sigma2 * invsym(quadcross(Xreg, Xreg))
    sub_beta = ols.beta[1..2]
    V_sub = V[1..2, 1..2]
    chi2 = sub_beta' * invsym(V_sub) * sub_beta

    cv  = _tarur_cv_cuestasgarratt()
    dec = _tarur_decision(chi2, cv, "right")
    _tarur_save_result(chi2, cv, dec, opt_lag)
    if (qui == "") {
        _tarur_print_result("Cuestas & Garratt (2011) Nonlinear Unit Root Test", "chi2", chi2, cv, dec, opt_lag, "cubic detrended",
            "Unit root",
            "Globally stationary nonlinear",
            "Cuestas & Garratt (2011) — simulated critical values")
    }
}

// --- Cuestas & Ordonez (2014) ---
void _tarur_run_cuestaso(string scalar v, real scalar maxlags, string scalar lagmethod, string scalar qui)
{
    real colvector x, x_adj, z, trend, logistic, beta, y_dep
    real matrix    X_nls, Xreg
    real rowvector cv, dec
    real scalar    n, opt_lag, stat
    struct TarurOLS scalar ols

    x = st_data(., v); x = _tarur_validate(x, 20)
    n = rows(x)
    trend = range(0, n-1, 1)
    logistic = 1 :/ (1 :+ exp(-0.5 :* trend))
    X_nls = J(n,1,1), trend, logistic, trend:*logistic
    beta = qrsolve(X_nls, x)
    x_adj = x - X_nls * beta
    z = _tarur_diff(x_adj)

    opt_lag = _tarur_select_lag("cuestaso", z, x_adj, maxlags, lagmethod)
    _tarur_b_cuestaso(z, x_adj, opt_lag, y_dep, Xreg)
    ols = _tarur_ols(y_dep, Xreg)
    stat = ols.tstats[1]
    cv  = _tarur_cv_kss("raw")
    dec = _tarur_decision(stat, cv, "left")
    _tarur_save_result(stat, cv, dec, opt_lag)
    if (qui == "") {
        _tarur_print_result("Cuestas & Ordonez (2014) NLS-detrend + KSS", "tNL", stat, cv, dec, opt_lag, "NLS detrended",
            "Unit root",
            "Stationary after smooth transition detrending",
            "Cuestas & Ordonez (2014) — KSS CVs on NLS residuals")
    }
}

// --- Enders & Granger (1998) ---
void _tarur_run_eg(string scalar v, string scalar cs_, real scalar maxlags, string scalar lagmethod, string scalar qui)
{
    real colvector x, x_adj, z, dz, zl_dep, xl, It, pos, neg
    real matrix    Xu, Xreg, z_lags, cols_r, cov
    real rowvector cv, dec, R
    real scalar    n, opt_lag, best_aic, m, lag, sse_u, sse_r, df2, Phi
    real scalar    rho_p, rho_n, se_p, se_n, F_sym, F_sym_p
    string scalar  inc
    struct TarurOLS scalar ols

    x = st_data(., v); x = _tarur_validate(x, 20)
    x_adj = _tarur_prep_case(x, cs_)
    z = _tarur_diff(x_adj)
    if (cs_ == "raw") {
        inc = "none"
    }
    else if (cs_ == "demeaned") {
        inc = "const"
    }
    else {
        inc = "both"
    }
    n = rows(x_adj)
    dz = _tarur_diff(x_adj)

    opt_lag = 1
    best_aic = .
    for (lag=1; lag<=maxlags; lag++) {
        _tarur_embed_diff_lags(z, lag, zl_dep, z_lags)
        m = rows(zl_dep)
        xl = x_adj[(lag+1)..(lag+m)]
        It = (dz[lag..(lag-1+m)] :>= 0)
        pos = It :* xl
        neg = (1 :- It) :* xl
        Xreg = pos, neg
        if (inc != "none") {
            Xreg = Xreg, J(m, 1, 1)
        }
        if (inc == "both") {
            Xreg = Xreg, range(0, m-1, 1)
        }
        Xreg = Xreg, z_lags
        if (rows(zl_dep) < cols(Xreg)+2) {
            continue
        }
        ols = _tarur_ols(zl_dep, Xreg)
        if (best_aic >= . | ols.aic < best_aic) {
            best_aic = ols.aic
            opt_lag = lag
        }
    }
    _tarur_embed_diff_lags(z, opt_lag, zl_dep, z_lags)
    m = rows(zl_dep)
    xl = x_adj[(opt_lag+1)..(opt_lag+m)]
    It = (dz[opt_lag..(opt_lag-1+m)] :>= 0)
    pos = It :* xl
    neg = (1 :- It) :* xl
    Xu = pos, neg
    if (inc != "none") {
        Xu = Xu, J(m, 1, 1)
    }
    if (inc == "both") {
        Xu = Xu, range(0, m-1, 1)
    }
    Xu = Xu, z_lags
    ols = _tarur_ols(zl_dep, Xu)
    rho_p = ols.beta[1]; rho_n = ols.beta[2]
    se_p  = ols.se[1];   se_n  = ols.se[2]
    sse_u = sum(ols.residuals:^2)

    if (cols(Xu) > 2) {
        cols_r = Xu[., 3..cols(Xu)]
        ols = _tarur_ols(zl_dep, cols_r)
        sse_r = sum(ols.residuals:^2)
    }
    else {
        sse_r = sum(zl_dep:^2)
    }
    df2 = m - cols(Xu)
    if (df2 > 0) {
        Phi = ((sse_r - sse_u)/2) / (sse_u/df2)
    }
    else {
        Phi = 0
    }

    ols = _tarur_ols(zl_dep, Xu)
    cov = ols.sigma2 * invsym(quadcross(Xu, Xu))
    R = J(1, cols(Xu), 0); R[1] = 1; R[2] = -1
    F_sym = ((R*ols.beta)^2) / (R * cov * R')
    F_sym_p = Ftail(1, df2, F_sym)

    cv  = _tarur_cv_endersgranger(inc)
    dec = _tarur_decision(Phi, cv, "right")
    _tarur_save_result(Phi, cv, dec, opt_lag)
    st_numscalar("r(rho_pos)", rho_p)
    st_numscalar("r(rho_neg)", rho_n)
    st_numscalar("r(F_sym)",   F_sym)
    st_numscalar("r(F_sym_p)", F_sym_p)
    if (qui == "") {
        _tarur_print_result("Enders & Granger (1998) MTAR Unit Root Test", "Phi", Phi, cv, dec, opt_lag, cs_,
            "Unit root",
            "MTAR stationary with asymmetric adjustment",
            "Enders & Granger (1998), Table 1")
        printf("  rho+ = %8.4f    rho- = %8.4f\n", rho_p, rho_n)
        printf("  Symmetry F = %7.4f (p = %6.4f)\n", F_sym, F_sym_p)
    }
}

// --- LNV (1998) / Vougas (2006) / Harvey-Mills (2002) — same skeleton ---
void _tarur_run_smooth(string scalar v, string scalar family, string scalar mdl, real scalar maxlags, string scalar lagmethod, string scalar qui)
{
    real colvector x, res, z, y_dep, xl, zl_dep
    real matrix    Xreg, z_lags
    real rowvector cv, dec
    real scalar    nz, opt_lag, stat, best_ic, ic, lag, m
    string scalar  tag, testname, src, h1, lmm
    struct TarurOLS scalar ols

    x = st_data(., v); x = _tarur_validate(x, 25)
    tag = family + mdl
    res = _tarur_nls_detrend(x, tag)
    z = _tarur_diff(res); nz = rows(z)

    // Inline lag selection (AIC or BIC) instead of going through helpers.
    lmm = strlower(lagmethod)
    opt_lag = 0
    best_ic = .
    for (lag=0; lag<=maxlags; lag++) {
        _tarur_embed_diff_lags(z, lag, zl_dep, z_lags)
        m = rows(zl_dep)
        if (m < 5) {
            continue
        }
        xl = res[(lag+1)..(lag+m)]
        if (lag == 0) {
            Xreg = xl
        }
        else {
            Xreg = xl, z_lags
        }
        if (rows(zl_dep) < cols(Xreg) + 2) {
            continue
        }
        ols = _tarur_ols(zl_dep, Xreg)
        if (lmm == "bic") {
            ic = ols.bic
        }
        else {
            ic = ols.aic
        }
        if (ic < .) {
            if (best_ic >= . | ic < best_ic) {
                best_ic = ic
                opt_lag = lag
            }
        }
    }

    // Refit at opt_lag
    _tarur_embed_diff_lags(z, opt_lag, zl_dep, z_lags)
    m = rows(zl_dep)
    xl = res[(opt_lag+1)..(opt_lag+m)]
    if (opt_lag == 0) {
        Xreg = xl
    }
    else {
        Xreg = xl, z_lags
    }
    ols = _tarur_ols(zl_dep, Xreg)
    stat = ols.tstats[1]

    // Fallback: if the fit fails (rank-deficient etc.), retry on the
    // simply-demeaned series.
    if (stat >= .) {
        res = x :- mean(x)
        z = _tarur_diff(res); nz = rows(z)
        opt_lag = 0
        best_ic = .
        for (lag=0; lag<=maxlags; lag++) {
            _tarur_embed_diff_lags(z, lag, zl_dep, z_lags)
            m = rows(zl_dep)
            if (m < 5) {
                continue
            }
            xl = res[(lag+1)..(lag+m)]
            if (lag == 0) {
                Xreg = xl
            }
            else {
                Xreg = xl, z_lags
            }
            ols = _tarur_ols(zl_dep, Xreg)
            ic = ols.aic
            if (ic < .) {
                if (best_ic >= . | ic < best_ic) {
                    best_ic = ic
                    opt_lag = lag
                }
            }
        }
        _tarur_embed_diff_lags(z, opt_lag, zl_dep, z_lags)
        m = rows(zl_dep)
        xl = res[(opt_lag+1)..(opt_lag+m)]
        if (opt_lag == 0) {
            Xreg = xl
        }
        else {
            Xreg = xl, z_lags
        }
        ols = _tarur_ols(zl_dep, Xreg)
        stat = ols.tstats[1]
    }

    if (family == "lnv") {
        cv = _tarur_cv_lnv(mdl, rows(x))
        testname = "LNV (1998) Model " + mdl
        src      = "Leybourne, Newbold & Vougas (1998), Table I"
        h1       = "Stationary around smooth logistic transition"
    }
    else if (family == "vougas") {
        cv = _tarur_cv_vougas(mdl, rows(x))
        testname = "Vougas (2006) Model " + mdl
        src      = "Vougas (2006), Table 1"
        h1       = "Stationary around smooth transition"
    }
    else {
        cv = _tarur_cv_hm(mdl, rows(x))
        testname = "Harvey & Mills (2002) Model " + mdl
        src      = "Harvey & Mills (2002), Table 1"
        h1       = "Stationary around double smooth transition"
    }
    dec = _tarur_decision(stat, cv, "left")
    _tarur_save_result(stat, cv, dec, opt_lag)
    if (qui == "") {
        _tarur_print_result(testname, "t_ADF", stat, cv, dec, opt_lag, "NLS " + family + " " + mdl,
            "Unit root", h1, src)
    }
}

// Wrappers for the three families so the ado files keep their old names.
void _tarur_run_lnv(string scalar v, string scalar mdl, real scalar maxlags, string scalar lagmethod, string scalar qui)
{
    _tarur_run_smooth(v, "lnv", mdl, maxlags, lagmethod, qui)
}
void _tarur_run_vougas(string scalar v, string scalar mdl, real scalar maxlags, string scalar lagmethod, string scalar qui)
{
    _tarur_run_smooth(v, "vougas", mdl, maxlags, lagmethod, qui)
}
void _tarur_run_hm(string scalar v, string scalar mdl, real scalar maxlags, string scalar lagmethod, string scalar qui)
{
    _tarur_run_smooth(v, "hm", mdl, maxlags, lagmethod, qui)
}

// --- Sollis (2004) ST-TAR ---
void _tarur_run_sollis2004(string scalar v, string scalar mdl, real scalar maxlags, string scalar qui)
{
    real colvector x, res, z, zl_dep, xl, It, pos, neg
    real matrix    Xu, Xreg, z_lags
    real rowvector cv, dec
    real scalar    opt_lag, best_aic, m, lag, sse_u, sse_r, df2, F
    struct TarurOLS scalar ols

    x = st_data(., v); x = _tarur_validate(x, 25)
    res = _tarur_nls_detrend(x, "cv" + mdl)
    z = _tarur_diff(res)

    opt_lag = 1
    best_aic = .
    for (lag=1; lag<=maxlags; lag++) {
        _tarur_embed_diff_lags(z, lag, zl_dep, z_lags)
        m = rows(zl_dep)
        xl = res[(lag+1)..(lag+m)]
        It = (xl :>= 0)
        pos = It :* xl
        neg = (1 :- It) :* xl
        Xreg = pos, neg, z_lags
        if (rows(zl_dep) < cols(Xreg)+2) {
            continue
        }
        ols = _tarur_ols(zl_dep, Xreg)
        if (best_aic >= . | ols.aic < best_aic) {
            best_aic = ols.aic
            opt_lag = lag
        }
    }
    _tarur_embed_diff_lags(z, opt_lag, zl_dep, z_lags)
    m = rows(zl_dep)
    xl = res[(opt_lag+1)..(opt_lag+m)]
    It = (xl :>= 0)
    pos = It :* xl
    neg = (1 :- It) :* xl
    Xu = pos, neg, z_lags
    ols = _tarur_ols(zl_dep, Xu)
    sse_u = sum(ols.residuals:^2)
    ols = _tarur_ols(zl_dep, z_lags)
    sse_r = sum(ols.residuals:^2)
    df2 = m - cols(Xu)
    if (df2 > 0) {
        F = ((sse_r - sse_u)/2) / (sse_u/df2)
    }
    else {
        F = 0
    }
    cv  = _tarur_cv_sollis2004(mdl)
    dec = _tarur_decision(F, cv, "right")
    _tarur_save_result(F, cv, dec, opt_lag)
    if (qui == "") {
        _tarur_print_result("Sollis (2004) ST-TAR Model " + mdl, "F_TAR", F, cv, dec, opt_lag, "ST-TAR " + mdl,
            "Unit root",
            "Asymmetric TAR stationary around smooth transition",
            "Sollis (2004), Table II (T=100)")
    }
}

// --- Cook & Vougas (2009) ST-MTAR ---
void _tarur_run_cookv(string scalar v, string scalar mdl, real scalar maxlags, string scalar qui)
{
    real colvector x, res, z, dres, zl_dep, xl, It, pos, neg
    real matrix    Xu, Xreg, z_lags
    real rowvector cv, dec
    real scalar    nz, opt_lag, best_aic, m, lag, sse_u, sse_r, df2, F
    struct TarurOLS scalar ols

    x = st_data(., v); x = _tarur_validate(x, 25)
    res = _tarur_nls_detrend(x, "cv" + mdl)
    z = _tarur_diff(res); nz = rows(z)
    dres = _tarur_diff(res[1..(nz+1)])

    opt_lag = 1
    best_aic = .
    for (lag=1; lag<=maxlags; lag++) {
        _tarur_embed_diff_lags(z, lag, zl_dep, z_lags)
        m = rows(zl_dep)
        xl = res[(lag+1)..(lag+m)]
        It = (dres[lag..(lag-1+m)] :>= 0)
        pos = It :* xl
        neg = (1 :- It) :* xl
        Xreg = pos, neg, z_lags
        if (rows(zl_dep) < cols(Xreg)+2) {
            continue
        }
        ols = _tarur_ols(zl_dep, Xreg)
        if (best_aic >= . | ols.aic < best_aic) {
            best_aic = ols.aic
            opt_lag = lag
        }
    }
    _tarur_embed_diff_lags(z, opt_lag, zl_dep, z_lags)
    m = rows(zl_dep)
    xl = res[(opt_lag+1)..(opt_lag+m)]
    It = (dres[opt_lag..(opt_lag-1+m)] :>= 0)
    pos = It :* xl
    neg = (1 :- It) :* xl
    Xu = pos, neg, z_lags
    ols = _tarur_ols(zl_dep, Xu)
    sse_u = sum(ols.residuals:^2)
    ols = _tarur_ols(zl_dep, z_lags)
    sse_r = sum(ols.residuals:^2)
    df2 = m - cols(Xu)
    if (df2 > 0) {
        F = ((sse_r - sse_u)/2) / (sse_u/df2)
    }
    else {
        F = 0
    }
    cv  = _tarur_cv_cv09(mdl, rows(x))
    dec = _tarur_decision(F, cv, "right")
    _tarur_save_result(F, cv, dec, opt_lag)
    if (qui == "") {
        _tarur_print_result("Cook & Vougas (2009) Model " + mdl, "F_MTAR", F, cv, dec, opt_lag, "ST-MTAR " + mdl,
            "Unit root",
            "Stationary around smooth transition with asymmetric adjustment",
            "Cook & Vougas (2009), Table 1")
    }
}

// --- Kilic / Park-Shintani inf-t (grid search over gamma) ---
void _tarur_run_inft(string scalar v, string scalar cs_, real scalar maxlags, string scalar lagmethod, string scalar qui, string scalar testid)
{
    real colvector x, x_adj, z, y_dep, G, xl, zl_dep, xl1
    real matrix    Xreg, z_lags, z_lags1
    real rowvector cv, dec, gammas
    real scalar    n, m, m1, lo, hi, step, sd_z, gamma, best_t, best_gamma
    real scalar    opt_lag, stat, ts, lag, best_ic, ic
    real scalar    i, ngrid
    string scalar  testname, src, alt
    struct TarurOLS scalar ols

    x = st_data(., v); x = _tarur_validate(x, 20)
    x_adj = _tarur_prep_case(x, cs_)
    z = _tarur_diff(x_adj); n = rows(z)
    sd_z = sqrt(variance(z)) + 1e-12
    lo = 1/(100*sd_z)
    if (100/sd_z < 5.0) {
        hi = 100/sd_z
    }
    else {
        hi = 5.0
    }
    if ((hi-lo)/200 > 0.005) {
        step = (hi-lo)/200
    }
    else {
        step = 0.005
    }

    // Construct grid as a vector to avoid float loop quirks
    ngrid = floor((hi - lo) / step) + 1
    gammas = J(1, ngrid, 0)
    for (i=1; i<=ngrid; i++) {
        gammas[i] = lo + (i-1)*step
    }

    _tarur_embed_diff_lags(z, 1, zl_dep, z_lags1)
    m1 = rows(zl_dep)
    xl1 = x_adj[2..(1+m1)]
    best_t = -1e16
    best_gamma = lo
    for (i=1; i<=ngrid; i++) {
        gamma = gammas[i]
        G = 1 :- exp(-gamma :* (z_lags1[., 1]:^2))
        Xreg = xl1 :* G, z_lags1
        if (rows(zl_dep) < cols(Xreg)+2) {
            continue
        }
        ols = _tarur_ols(zl_dep, Xreg)
        ts = ols.tstats[1]
        if (ts > best_t) {
            best_t = ts
            best_gamma = gamma
        }
    }

    opt_lag = 1
    best_ic = .
    for (lag=0; lag<=maxlags; lag++) {
        _tarur_embed_diff_lags(z, lag, zl_dep, z_lags)
        m = rows(zl_dep)
        xl = x_adj[(lag+1)..(lag+m)]
        if (lag == 0) {
            G = J(m, 1, 1)
            Xreg = xl :* G
        }
        else {
            G = 1 :- exp(-best_gamma :* (z_lags[., 1]:^2))
            Xreg = xl :* G, z_lags
        }
        if (rows(zl_dep) < cols(Xreg)+2) {
            continue
        }
        ols = _tarur_ols(zl_dep, Xreg)
        if (lagmethod == "bic" | lagmethod == "BIC") {
            ic = ols.bic
        }
        else {
            ic = ols.aic
        }
        if (best_ic >= . | ic < best_ic) {
            best_ic = ic
            opt_lag = lag
        }
    }
    _tarur_embed_diff_lags(z, opt_lag, zl_dep, z_lags)
    m = rows(zl_dep)
    xl = x_adj[(opt_lag+1)..(opt_lag+m)]
    if (opt_lag == 0) {
        G = J(m, 1, 1)
        Xreg = xl :* G
    }
    else {
        G = 1 :- exp(-best_gamma :* (z_lags[., 1]:^2))
        Xreg = xl :* G, z_lags
    }
    ols = _tarur_ols(zl_dep, Xreg)
    stat = ols.tstats[1]
    if (testid == "kilic") {
        cv = _tarur_cv_kilic(cs_)
        testname = "Kilic (2011) inf-t Unit Root Test"
        src      = "Kilic (2011), Table 1"
        alt      = "Stationary ESTAR process"
    }
    else {
        cv = _tarur_cv_parkshintani(cs_)
        testname = "Park & Shintani (2016) inf-t Unit Root Test"
        src      = "Park & Shintani (2016), Table 1"
        alt      = "Transitional autoregressive stationary process"
    }
    dec = _tarur_decision(stat, cv, "left")
    _tarur_save_result(stat, cv, dec, opt_lag)
    st_numscalar("r(gamma)", best_gamma)
    if (qui == "") {
        _tarur_print_result(testname, "inf_t", stat, cv, dec, opt_lag, cs_,
            "Unit root", alt, src)
        printf("  Optimal gamma = %8.5f\n", best_gamma)
    }
}

// --- KSS (2006) Nonlinear cointegration ---
void _tarur_run_ksscoint(string scalar yvar, string scalar xvar, string scalar cs_, real scalar maxlags, string scalar lagmethod, string scalar qui)
{
    real colvector y, x, ones, res, z, y_dep, beta
    real matrix    Xc, Xreg
    real rowvector cv, dec
    real scalar    opt_lag, stat
    struct TarurOLS scalar ols

    y = st_data(., yvar); y = _tarur_validate(y, 20)
    x = st_data(., xvar); x = _tarur_validate(x, 20)
    ones = J(rows(x), 1, 1)
    Xc = ones, x
    beta = qrsolve(Xc, y)
    res = y - Xc * beta
    z = _tarur_diff(res)

    opt_lag = _tarur_select_lag("kss", z, res, maxlags, lagmethod)
    _tarur_b_kss(z, res, opt_lag, y_dep, Xreg)
    ols = _tarur_ols(y_dep, Xreg)
    stat = ols.tstats[1]
    cv  = _tarur_cv_kss(cs_)
    dec = _tarur_decision(stat, cv, "left")
    _tarur_save_result(stat, cv, dec, opt_lag)
    if (qui == "") {
        _tarur_print_result("KSS (2006) Nonlinear Cointegration Test", "tNL", stat, cv, dec, opt_lag, cs_,
            "No cointegration (residuals have unit root)",
            "Nonlinear cointegration (ESTAR stationary residuals)",
            "Kapetanios, Shin & Snell (2006) — KSS CVs on residuals")
    }
}

// --- Enders & Siklos (2001) TAR cointegration ---
void _tarur_run_es(string scalar yvar, string scalar xvar, real scalar maxlags, string scalar lagmethod, string scalar qui)
{
    real colvector y, x, ones, res, z, dz, zl_dep, xl, It, pos, neg, beta
    real matrix    Xc, Xu, Xreg, z_lags, cols_r
    real rowvector cv, dec
    real scalar    opt_lag, best_aic, m, lag, sse_u, sse_r, df2, Phi, rho_p, rho_n
    struct TarurOLS scalar ols

    y = st_data(., yvar); y = _tarur_validate(y, 20)
    x = st_data(., xvar); x = _tarur_validate(x, 20)
    ones = J(rows(x), 1, 1)
    Xc = ones, x
    beta = qrsolve(Xc, y)
    res = y - Xc * beta
    z = _tarur_diff(res)
    dz = _tarur_diff(res)

    opt_lag = 1
    best_aic = .
    for (lag=1; lag<=maxlags; lag++) {
        _tarur_embed_diff_lags(z, lag, zl_dep, z_lags)
        m = rows(zl_dep)
        xl = res[(lag+1)..(lag+m)]
        It = (dz[lag..(lag-1+m)] :>= 0)
        pos = It :* xl
        neg = (1 :- It) :* xl
        Xreg = pos, neg, z_lags
        if (rows(zl_dep) < cols(Xreg)+2) {
            continue
        }
        ols = _tarur_ols(zl_dep, Xreg)
        if (best_aic >= . | ols.aic < best_aic) {
            best_aic = ols.aic
            opt_lag = lag
        }
    }
    _tarur_embed_diff_lags(z, opt_lag, zl_dep, z_lags)
    m = rows(zl_dep)
    xl = res[(opt_lag+1)..(opt_lag+m)]
    It = (dz[opt_lag..(opt_lag-1+m)] :>= 0)
    pos = It :* xl
    neg = (1 :- It) :* xl
    Xu = pos, neg, z_lags
    ols = _tarur_ols(zl_dep, Xu)
    rho_p = ols.beta[1]; rho_n = ols.beta[2]
    sse_u = sum(ols.residuals:^2)
    if (cols(Xu) > 2) {
        cols_r = Xu[., 3..cols(Xu)]
        ols = _tarur_ols(zl_dep, cols_r)
        sse_r = sum(ols.residuals:^2)
    }
    else {
        sse_r = sum(zl_dep:^2)
    }
    df2 = m - cols(Xu)
    if (df2 > 0) {
        Phi = ((sse_r - sse_u)/2) / (sse_u/df2)
    }
    else {
        Phi = 0
    }
    cv  = _tarur_cv_endersgranger("none")
    dec = _tarur_decision(Phi, cv, "right")
    _tarur_save_result(Phi, cv, dec, opt_lag)
    st_numscalar("r(rho_pos)", rho_p)
    st_numscalar("r(rho_neg)", rho_n)
    if (qui == "") {
        _tarur_print_result("Enders & Siklos (2001) TAR Cointegration Test", "Phi", Phi, cv, dec, opt_lag, "residuals",
            "No cointegration",
            "Threshold cointegration with asymmetric adjustment",
            "Enders & Siklos (2001), Table 1")
    }
}

// --- Terasvirta (1994) linearity ---
void _tarur_run_terasvirta(string scalar v, real scalar d, real scalar max_p, string scalar qui)
{
    real colvector x, y, ytd, ytd2, ytd3
    real matrix    X, a, b, c, Xu, Xr, Xu1, Xu2
    real scalar    best_aic, best_p, p, n, j
    real scalar    SSEu, SSEr, sse1, sse2
    real scalar    F_lin, p_lin, H01, pH01, H02, pH02, H03, pH03
    real scalar    h1, h2, h1a, h2a, h1b, h2b
    string scalar  model_type
    struct TarurOLS scalar ols

    x = st_data(., v); x = _tarur_validate(x, 20)
    if (d > max_p) {
        max_p = d
    }
    n = rows(x)

    best_aic = .; best_p = 1
    for (p=1; p<=max_p; p++) {
        X = J(n-p, p, .)
        for (j=0; j<p; j++) {
            X[., j+1] = x[(p-j)..(n-j-1)]
        }
        y = x[(p+1)..n]
        ols = _tarur_ols(y, X)
        if (best_aic >= . | ols.aic < best_aic) {
            best_aic = ols.aic
            best_p = p
        }
    }
    p = best_p
    X = J(n-p, p, .)
    for (j=0; j<p; j++) {
        X[., j+1] = x[(p-j)..(n-j-1)]
    }
    y = x[(p+1)..n]
    ytd  = x[(p-d+1)..(n-d)]
    ytd2 = ytd:^2
    ytd3 = ytd:^3
    a = X :* (ytd  * J(1, p, 1))
    b = X :* (ytd2 * J(1, p, 1))
    c = X :* (ytd3 * J(1, p, 1))
    Xu = X, a, b, c
    Xr = X
    ols = _tarur_ols(y, Xu); SSEu = sum(ols.residuals:^2)
    ols = _tarur_ols(y, Xr); SSEr = sum(ols.residuals:^2)
    h1 = cols(a) + cols(b) + cols(c)
    h2 = rows(y) - cols(Xu)
    if (h2 > 0) {
        F_lin = ((SSEr - SSEu)/h1) / (SSEu/h2)
    }
    else {
        F_lin = 0
    }
    p_lin = Ftail(h1, h2, F_lin)

    Xu1 = X, a
    ols = _tarur_ols(y, Xu1); sse1 = sum(ols.residuals:^2)
    h1a = cols(a); h2a = rows(y) - cols(X) - cols(a)
    if (h2a > 0) {
        H01 = ((SSEr - sse1)/h1a) / (sse1/h2a)
    }
    else {
        H01 = 0
    }
    pH01 = Ftail(h1a, h2a, H01)

    Xu2 = X, a, b
    ols = _tarur_ols(y, Xu2); sse2 = sum(ols.residuals:^2)
    h1b = cols(b); h2b = rows(y) - cols(X) - cols(a) - cols(b)
    if (h2b > 0) {
        H02 = ((sse1 - sse2)/h1b) / (sse2/h2b)
    }
    else {
        H02 = 0
    }
    pH02 = Ftail(h1b, h2b, H02)

    if (h2 > 0) {
        H03 = ((sse2 - SSEu)/cols(c)) / (SSEu/h2)
    }
    else {
        H03 = 0
    }
    pH03 = Ftail(cols(c), h2, H03)

    if (pH02 < pH01 & pH02 < pH03) {
        model_type = "ESTAR"
    }
    else {
        model_type = "LSTAR"
    }

    st_rclear()
    st_numscalar("r(F)",      F_lin)
    st_numscalar("r(pvalue)", p_lin)
    st_numscalar("r(pH01)",   pH01)
    st_numscalar("r(pH02)",   pH02)
    st_numscalar("r(pH03)",   pH03)
    st_numscalar("r(p)",      p)
    st_global("r(model)", model_type)

    if (qui == "") {
        printf("\n============================================================\n")
        printf("  Terasvirta (1994) Linearity Test\n")
        printf("============================================================\n")
        printf("  AR order (AIC)   = %g\n", p)
        printf("  d                = %g\n", d)
        printf("------------------------------------------------------------\n")
        printf("  Linearity F      = %8.4f  (p = %6.4f)\n", F_lin, p_lin)
        printf("  H01              = %8.4f  (p = %6.4f)\n", H01, pH01)
        printf("  H02              = %8.4f  (p = %6.4f)\n", H02, pH02)
        printf("  H03              = %8.4f  (p = %6.4f)\n", H03, pH03)
        printf("------------------------------------------------------------\n")
        if (p_lin < 0.05) {
            printf("  >> Reject linearity. Suggested model: %s.\n", model_type)
        }
        else {
            printf("  >> Fail to reject linearity.\n")
        }
        printf("============================================================\n")
    }
}

// --- ARCH LM ---
void _tarur_run_arch(string scalar v, real scalar q, string scalar qui)
{
    real colvector x, e2, y
    real matrix    X
    real scalar    n, i, m, LM, pval
    struct TarurOLS scalar ols

    x = st_data(., v); x = _tarur_validate(x, q+5)
    e2 = x:^2
    n = rows(e2)
    y = e2[(q+1)..n]
    m = rows(y)
    X = J(m, q, .)
    for (i=1; i<=q; i++) {
        X[., i] = e2[(q+1-i)..(n-i)]
    }
    X = J(m, 1, 1), X
    ols = _tarur_ols(y, X)
    LM = m * ols.r2
    pval = chi2tail(q, LM)

    st_rclear()
    st_numscalar("r(stat)",   LM)
    st_numscalar("r(pvalue)", pval)
    st_numscalar("r(lags)",   q)
    if (qui == "") {
        printf("\n============================================================\n")
        printf("  Engle (1982) ARCH LM Test\n")
        printf("============================================================\n")
        printf("  Lags = %g     LM = %8.4f   (p = %6.4f)\n", q, LM, pval)
        if (pval < 0.05) {
            printf("  >> Reject H0: ARCH effects present.\n")
        }
        else {
            printf("  >> Fail to reject H0: no ARCH effects.\n")
        }
        printf("============================================================\n")
    }
}

// --- McLeod-Li ---
void _tarur_run_mcleodli(string scalar v, real scalar m_lags, string scalar qui)
{
    real colvector x, e2, e2_dem
    real scalar    n, k, mean_e2, denom, num, rho, Q, pval, acc

    x = st_data(., v); x = _tarur_validate(x, m_lags+5)
    e2 = x:^2
    n = rows(e2)
    mean_e2 = mean(e2)
    e2_dem  = e2 :- mean_e2
    denom   = sum(e2_dem:^2)
    acc = 0
    for (k=1; k<=m_lags; k++) {
        num = sum(e2_dem[1..(n-k)] :* e2_dem[(k+1)..n])
        rho = num / denom
        acc = acc + (rho^2) / (n - k)
    }
    Q = n * (n + 2) * acc
    pval = chi2tail(m_lags, Q)

    st_rclear()
    st_numscalar("r(stat)",   Q)
    st_numscalar("r(pvalue)", pval)
    st_numscalar("r(lags)",   m_lags)
    if (qui == "") {
        printf("\n============================================================\n")
        printf("  McLeod-Li Portmanteau Test on Squared Residuals\n")
        printf("============================================================\n")
        printf("  Lags = %g     Q = %8.4f   (p = %6.4f)\n", m_lags, Q, pval)
        if (pval < 0.05) {
            printf("  >> Reject H0: nonlinear dependence detected.\n")
        }
        else {
            printf("  >> Fail to reject H0: no nonlinear dependence.\n")
        }
        printf("============================================================\n")
    }
}

// ---------------------------------------------------------------------------
// Sentinel — tarur_init.ado uses this to detect helpers are loaded.
// ---------------------------------------------------------------------------
real scalar _tarur_loaded()
{
    return(1)
}
end

* End of _tarur_mata.do
