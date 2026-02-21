*! _garchur_mata.ado — Mata library for garchur (no-struct, safe for re-run)
*! Version 1.1.0, February 2026
*! Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)
*!
*! Reference:
*!   Narayan, P.K., Liu, R. (2015).
*!   A Unit Root Model for Trending Time-Series Energy Variables.
*!   Energy Economics. DOI: 10.1016/j.eneco.2014.11.021

*--------------------------------------------------------------------------
* Drop all functions before redefining (safe for repeated run calls)
* NOTE: structs cannot be dropped, so we use reference-parameter style
*       instead of structs — avoids "struct already defined" error on re-run
*--------------------------------------------------------------------------
capture mata: mata drop garchur_loglik()
capture mata: mata drop garchur_evalfcn()
capture mata: mata drop garchur_build_ht()
capture mata: mata drop garchur_estimate()
capture mata: mata drop garchur_breakdate()
capture mata: mata drop garchur_get_cv()
capture mata: mata drop garchur_compute()

mata:

// ------------------------------------------------------------
// GARCH(1,1) Gaussian negative log-likelihood
// Returns negative LL (we minimise, not maximise)
// h_1 initialised at unconditional variance kappa/(1-a-b)
// ------------------------------------------------------------
real scalar garchur_loglik(
    real colvector resid,
    real scalar    kappa,
    real scalar    alpha,
    real scalar    beta)
{
    real scalar T, t, ll, h_now, h_prev
    T = rows(resid)
    if (kappa <= 0 | alpha < 0 | beta < 0 | (alpha+beta) >= 1) {
        return(1e15)
    }
    h_prev = kappa / (1 - alpha - beta)
    if (h_prev <= 0) return(1e15)
    ll = 0.5 * (log(2*pi()) + log(h_prev) + resid[1]^2 / h_prev)
    for (t = 2; t <= T; t++) {
        h_now = kappa + alpha*resid[t-1]^2 + beta*h_prev
        if (h_now < 1e-10) h_now = 1e-10
        ll = ll + 0.5*(log(2*pi()) + log(h_now) + resid[t]^2/h_now)
        h_prev = h_now
    }
    return(ll)
}

// ------------------------------------------------------------
// optimize() evaluator wrapper — d0 type
//
// REPARAMETERIZATION (avoids optimize_init_constraints which
// only handles equality constraints and causes r(412)):
//   p[1] = log(kappa)          => kappa = exp(p[1]) > 0
//   p[2] = log(alpha/remain)   => via softmax below
//   p[3] = log(beta/remain)    => via softmax below
//
// Softmax decoding:
//   sa = exp(p[2]),  sb = exp(p[3]),  sc = 1 (fixed)
//   alpha = 0.9999 * sa/(sa+sb+sc)
//   beta  = 0.9999 * sb/(sa+sb+sc)
//   => alpha>=0, beta>=0, alpha+beta<=0.9999 automatically
//
// args[1] = residual column vector
// ------------------------------------------------------------
void garchur_evalfcn(
    real scalar    todo,
    real rowvector p,
    real matrix    resid_arg,
    real scalar    fv,
    real rowvector g,
    real matrix    H)
{
    real scalar kappa, alpha, beta, sa, sb, sc, denom
    kappa = exp(p[1])
    sa    = exp(p[2])
    sb    = exp(p[3])
    sc    = 1
    denom = sa + sb + sc
    alpha = 0.9999 * sa / denom
    beta  = 0.9999 * sb / denom
    fv = garchur_loglik(resid_arg, kappa, alpha, beta)
}

// ------------------------------------------------------------
// Build GARCH(1,1) conditional variance sequence h_t
// h_t returned as column vector of length T
// ------------------------------------------------------------
real colvector garchur_build_ht(
    real colvector resid,
    real scalar    kappa,
    real scalar    alpha,
    real scalar    beta)
{
    real scalar    T, t
    real colvector ht
    T     = rows(resid)
    ht    = J(T, 1, .)
    ht[1] = kappa / (1 - alpha - beta)
    if (ht[1] <= 0 | missing(ht[1])) ht[1] = variance(resid)[1,1]
    for (t = 2; t <= T; t++) {
        ht[t] = kappa + alpha*resid[t-1]^2 + beta*ht[t-1]
        if (ht[t] < 1e-10) ht[t] = 1e-10
    }
    return(ht)
}

// ------------------------------------------------------------
// Core trend-GARCH estimation (paper equations 1-2)
// Uses reference parameters instead of struct (struct would
// cause "already defined" error on repeated .ado execution)
//
// Inputs:  y (T×1), TB (k×1 break row-indices), model ("ct"/"c")
// Outputs: all scalars/vectors passed by reference (modified in-place)
//
// Design matrix:
//   "ct": [1  t  y_{t-1}  DU_1 ... DU_k]   rho_pos = 3
//   "c":  [1  y_{t-1}  DU_1 ... DU_k]       rho_pos = 2
// ------------------------------------------------------------
void garchur_estimate(
    real colvector y,
    real colvector TB,
    string scalar  model,
    real scalar    rho_ref,
    real scalar    tstat_ref,
    real scalar    alpha_ref,
    real scalar    beta_ref,
    real scalar    kappa_ref,
    real scalar    halflife_ref,
    real scalar    loglik_ref,
    real scalar    nobs_ref,
    real colvector ht_ref,
    real colvector resid_ref)
{
    real scalar T, k, j, t, tbreak
    real scalar var0, kappa0, alpha0, beta0, kappa, alpha, beta, ab
    real scalar rho_pos, sigma2w, se_rho, nk
    real matrix Xmat, XtXinv, XwXw, Vb, Xw
    real colvector ones, trend, ylag, Yvec, Du
    real colvector bols, resid0, wt, Yw, bwls, resid_wls, wresid, ht
    transmorphic S
    real rowvector bopt

    T = rows(y)
    k = rows(TB)

    // ---- Build design matrix (obs 2..T to allow y_{t-1}) ----
    ones  = J(T-1, 1, 1)
    trend = (2::T)
    ylag  = y[1..T-1]
    Yvec  = y[2..T]

    if (model == "ct") {
        Xmat    = (ones, trend, ylag)
        rho_pos = 3
    }
    else {
        Xmat    = (ones, ylag)
        rho_pos = 2
    }

    // Add break dummies DU_{jt}=1 if t>=TB_j  (paper eq.1)
    // Row i of Xmat corresponds to time t=i+1, so DU[i]=1 iff (i+1)>=TB_j
    for (j = 1; j <= k; j++) {
        Du     = J(T-1, 1, 0)
        tbreak = TB[j]
        for (t = 1; t <= T-1; t++) {
            if ((t+1) >= tbreak) Du[t] = 1
        }
        Xmat = (Xmat, Du)
    }

    // ---- Step 1: OLS for initial residuals ----
    XtXinv = invsym(cross(Xmat, Xmat))
    bols   = XtXinv * cross(Xmat, Yvec)
    resid0 = Yvec - Xmat*bols
    var0   = cross(resid0, resid0) / (rows(resid0) - cols(Xmat))
    if (var0 <= 0) var0 = 1e-4

    // ---- Step 2: GARCH(1,1) MLE via direct grid search (paper eq.2) ----
    //
    // We avoid Stata's optimize() entirely — it is unreliable for GARCH:
    //   optimize_init_constraints => r(412) (equality only, not inequality)
    //   BFGS numerical derivatives => r(430) (flat region on GARCH surfaces)
    //   Nelder-Mead               => r(3499) (not available in Stata 14)
    //
    // Instead: nested grid search over (kappa, alpha, beta).
    //   - Standardize residuals by RMS so kappa is always O(0.01-1.0)
    //   - 11 x 13 x 14 = 2002 evaluations; each O(T); total << 0.1 sec
    //   - No optimizer, no convergence criteria, no error codes possible
    //
    real scalar sd_scale, var_s
    real colvector resid_s
    sd_scale = sqrt(cross(resid0, resid0) / rows(resid0))
    if (sd_scale <= 0 | sd_scale == .) sd_scale = 1
    resid_s = resid0 / sd_scale          // standardized: RMS = 1
    var_s   = cross(resid_s, resid_s) / rows(resid_s)   // ~ 1.0

    // Alpha grid (11 points): fine at low end (typical GARCH), coarser at high
    real rowvector ag
    ag = (0.01, 0.03, 0.05, 0.08, 0.10, 0.15, 0.20, 0.30, 0.50, 0.70, 0.90)

    // Beta grid (13 points): dense near 0.7-0.95 where GARCH beta lives
    real rowvector bg
    bg = (0.01, 0.05, 0.10, 0.30, 0.50, 0.60, 0.70, 0.75, 0.80, 0.85, 0.90, 0.93, 0.97)

    // Kappa grid (14 points): log-spaced from var_s*1e-3 to var_s*10
    real rowvector kg
    real scalar ki
    kg = J(1, 14, .)
    for (ki = 1; ki <= 14; ki++) {
        kg[ki] = var_s * (10 ^ (-3 + (3.5/13)*(ki-1)))
    }

    real scalar ia, ib, ik, alp, bet, kap, ll_now, ll_best
    real scalar alpha_g, beta_g, kappa_g
    ll_best = 1e15
    alpha_g = 0.10 ;  beta_g = 0.85 ;  kappa_g = var_s * 0.05

    for (ia = 1; ia <= cols(ag); ia++) {
        alp = ag[ia]
        for (ib = 1; ib <= cols(bg); ib++) {
            bet = bg[ib]
            if (alp + bet >= 0.9999) continue        // GARCH stationarity
            for (ik = 1; ik <= cols(kg); ik++) {
                kap    = kg[ik]
                ll_now = garchur_loglik(resid_s, kap, alp, bet)
                if (ll_now < ll_best) {
                    ll_best = ll_now
                    alpha_g = alp ;  beta_g = bet ;  kappa_g = kap
                }
            }
        }
    }

    // Scale kappa back from standardized-residual units to original units
    kappa = kappa_g * sd_scale * sd_scale
    alpha = alpha_g
    beta  = beta_g
    ab    = alpha + beta

    // Sanity guard
    if (missing(kappa) | kappa <= 0 | ab >= 1) {
        kappa = var0 * 0.05
        if (kappa <= 0) kappa = 1e-6
        alpha = 0.05 ;  beta = 0.90 ;  ab = 0.95
    }

    // ---- Step 3: Build h_t (paper eq.2) ----
    ht = garchur_build_ht(resid0, kappa, alpha, beta)

    // ---- Step 4: WLS re-estimation (FGLS with weights 1/sqrt(h_t)) ----
    wt   = 1 :/ sqrt(ht)
    Yw   = Yvec :* wt
    Xw   = Xmat :* wt
    XwXw = cross(Xw, Xw)
    bwls = invsym(XwXw) * cross(Xw, Yw)
    resid_wls = Yvec - Xmat*bwls

    // ---- Step 5: SE of rho using weighted sigma^2 ----
    wresid   = Yw - Xw*bwls
    nk       = rows(Yvec) - cols(Xmat)
    if (nk <= 0) nk = 1
    sigma2w  = cross(wresid, wresid) / nk
    Vb       = sigma2w * invsym(XwXw)
    se_rho   = sqrt(Vb[rho_pos, rho_pos])
    if (se_rho <= 0 | missing(se_rho)) se_rho = 1e-6

    // ---- Populate output reference variables ----
    rho_ref      = bwls[rho_pos]
    tstat_ref    = (bwls[rho_pos] - 1) / se_rho
    alpha_ref    = alpha
    beta_ref     = beta
    kappa_ref    = kappa
    loglik_ref   = -garchur_loglik(resid0, kappa, alpha, beta)
    nobs_ref     = rows(Yvec)
    ht_ref       = ht
    resid_ref    = resid_wls

    if (ab > 0 & ab < 1) {
        halflife_ref = log(0.5) / log(ab)
    }
    else {
        halflife_ref = .
    }
}

// ------------------------------------------------------------
// Sequential break-date search (paper equations 3 and 4)
//
// eq.(3): TB1 = argmax_{t in [trim*T,(1-trim)*T]} |t(gamma_1)|
// eq.(4): TB2 = argmax_{t in [trim*T,(1-trim)*T]} |t(gamma_2|TB1)|
//
// Uses OLS t-statistics (not GARCH) for the search loop — fast
// and consistent with Narayan & Popp (2010); break dates enter
// the GARCH estimation but the search itself uses OLS.
// ------------------------------------------------------------
real colvector garchur_breakdate(
    real colvector y,
    real scalar    nbreaks,
    string scalar  model,
    real scalar    trim)
{
    real scalar T, T1, T2, t, ii, tval, nk, s2, se_du
    real scalar best1, best2, best3, tmax1, tmax2, tmax3, tb1, tb2, tbreak
    real matrix Xmat, XtXinv
    real colvector found, ones, trend, ylag, Yvec, DU, DU1, DU2, DU3, b, resid

    T  = rows(y)
    T1 = round(trim * T)
    if (T1 < 5) T1 = 5
    T2 = T - T1
    if (T2 <= T1) T2 = T - 3

    found = J(nbreaks, 1, .)

    ones  = J(T-1, 1, 1)
    trend = (2::T)
    ylag  = y[1..T-1]
    Yvec  = y[2..T]

    // ------ First break (eq. 3) ------
    tmax1 = -1
    best1 = T1
    for (t = T1; t <= T2; t++) {
        DU = J(T-1, 1, 0)
        for (ii = 1; ii <= T-1; ii++) {
            if ((ii+1) >= t) DU[ii] = 1
        }
        if (model == "ct") Xmat = (ones, trend, ylag, DU)
        else               Xmat = (ones, ylag, DU)
        XtXinv = invsym(cross(Xmat, Xmat))
        b      = XtXinv * cross(Xmat, Yvec)
        resid  = Yvec - Xmat*b
        nk     = rows(resid) - cols(Xmat)
        if (nk <= 0) continue
        s2     = cross(resid, resid) / nk
        if (s2 <= 0) s2 = 1e-10
        se_du  = sqrt(s2 * XtXinv[cols(Xmat), cols(Xmat)])
        if (se_du <= 0 | missing(se_du)) continue
        tval   = abs(b[cols(Xmat)] / se_du)
        if (tval > tmax1) {
            tmax1 = tval
            best1 = t
        }
    }
    found[1] = best1

    // ------ Second break (eq. 4, conditional on TB1) ------
    if (nbreaks >= 2) {
        tb1   = found[1]
        tmax2 = -1
        best2 = T1
        DU1   = J(T-1, 1, 0)
        for (ii = 1; ii <= T-1; ii++) {
            if ((ii+1) >= tb1) DU1[ii] = 1
        }
        for (t = T1; t <= T2; t++) {
            if (t == tb1) continue
            DU2 = J(T-1, 1, 0)
            for (ii = 1; ii <= T-1; ii++) {
                if ((ii+1) >= t) DU2[ii] = 1
            }
            if (model == "ct") Xmat = (ones, trend, ylag, DU1, DU2)
            else               Xmat = (ones, ylag, DU1, DU2)
            XtXinv = invsym(cross(Xmat, Xmat))
            b      = XtXinv * cross(Xmat, Yvec)
            resid  = Yvec - Xmat*b
            nk     = rows(resid) - cols(Xmat)
            if (nk <= 0) continue
            s2     = cross(resid, resid) / nk
            if (s2 <= 0) s2 = 1e-10
            se_du  = sqrt(s2 * XtXinv[cols(Xmat), cols(Xmat)])
            if (se_du <= 0 | missing(se_du)) continue
            tval   = abs(b[cols(Xmat)] / se_du)
            if (tval > tmax2) {
                tmax2 = tval
                best2 = t
            }
        }
        found[2] = best2
    }

    // ------ Third break (conditional on TB1 and TB2) ------
    if (nbreaks >= 3) {
        tb1   = found[1]
        tb2   = found[2]
        tmax3 = -1
        best3 = T1
        DU1   = J(T-1, 1, 0)
        DU2   = J(T-1, 1, 0)
        for (ii = 1; ii <= T-1; ii++) {
            if ((ii+1) >= tb1) DU1[ii] = 1
            if ((ii+1) >= tb2) DU2[ii] = 1
        }
        for (t = T1; t <= T2; t++) {
            if (t==tb1 | t==tb2) continue
            DU3 = J(T-1, 1, 0)
            for (ii = 1; ii <= T-1; ii++) {
                if ((ii+1) >= t) DU3[ii] = 1
            }
            if (model == "ct") Xmat = (ones, trend, ylag, DU1, DU2, DU3)
            else               Xmat = (ones, ylag, DU1, DU2, DU3)
            XtXinv = invsym(cross(Xmat, Xmat))
            b      = XtXinv * cross(Xmat, Yvec)
            resid  = Yvec - Xmat*b
            nk     = rows(resid) - cols(Xmat)
            if (nk <= 0) continue
            s2     = cross(resid, resid) / nk
            if (s2 <= 0) s2 = 1e-10
            se_du  = sqrt(s2 * XtXinv[cols(Xmat), cols(Xmat)])
            if (se_du <= 0 | missing(se_du)) continue
            tval   = abs(b[cols(Xmat)] / se_du)
            if (tval > tmax3) {
                tmax3 = tval
                best3 = t
            }
        }
        found[3] = best3
    }

    return(sort(found, 1))
}

// ------------------------------------------------------------
// Critical value lookup + interpolation from Table III
// (Narayan & Liu, 2015, 50,000 MC replications)
//
// Table III GARCH groups:
//   G1: (alpha=0.05, beta=0.95)  ab=1.00  low ARCH ratio
//   G2: (alpha=0.45, beta=0.50)  ab=0.95  mid ARCH ratio
//   G3: (alpha=0.90, beta=0.05)  ab=0.95  high ARCH ratio
//
// Interpolation: inverse-distance weighting in 2D (ab, alpha/ab)
// then linear interpolation on T axis
// 1%/10% adjusted from Table VI gap patterns
// ------------------------------------------------------------
real scalar garchur_get_cv(
    real scalar T_in,
    real scalar alpha,
    real scalar beta,
    real scalar pct)
{
    real scalar T, ab, ar, d1, d2, d3, dsum, g1, g2, g3, wT, cv5, cv1, cv10
    real scalar v1_150, v1_250, v1_500
    real scalar v2_150, v2_250, v2_500
    real scalar v3_150, v3_250, v3_500
    real scalar cv5_g1, cv5_g2, cv5_g3

    T  = T_in
    if (T < 150) T = 150
    if (T > 500) T = 500
    ab = alpha + beta
    if (ab <= 0)  ab = 0.95
    if (ab >= 1)  ab = 0.9999
    ar = alpha / ab      // ARCH ratio: distinguishes G2 vs G3

    // 5% CVs from Table III (averaged across 6 break-position combos)
    v1_150 = -3.995;  v1_250 = -3.920;  v1_500 = -3.836  // G1
    v2_150 = -3.942;  v2_250 = -3.840;  v2_500 = -3.754  // G2
    v3_150 = -3.903;  v3_250 = -3.811;  v3_500 = -3.705  // G3

    // Interpolate on T within each group
    if (T <= 250) {
        wT     = (T - 150) / 100
        cv5_g1 = (1-wT)*v1_150 + wT*v1_250
        cv5_g2 = (1-wT)*v2_150 + wT*v2_250
        cv5_g3 = (1-wT)*v3_150 + wT*v3_250
    }
    else {
        wT     = (T - 250) / 250
        cv5_g1 = (1-wT)*v1_250 + wT*v1_500
        cv5_g2 = (1-wT)*v2_250 + wT*v2_500
        cv5_g3 = (1-wT)*v3_250 + wT*v3_500
    }

    // Inverse-distance weighting in 2D: (ab, ar) vs anchors
    // G1 anchor: (ab=1.00, ar=0.05)
    // G2 anchor: (ab=0.95, ar=0.47)
    // G3 anchor: (ab=0.95, ar=0.95)
    d1 = abs(ab-1.00) + abs(ar-0.05); if (d1 < 1e-6) d1 = 1e-6
    d2 = abs(ab-0.95) + abs(ar-0.47); if (d2 < 1e-6) d2 = 1e-6
    d3 = abs(ab-0.95) + abs(ar-0.95); if (d3 < 1e-6) d3 = 1e-6
    g1   = 1/d1;  g2 = 1/d2;  g3 = 1/d3
    dsum = g1 + g2 + g3
    g1   = g1/dsum;  g2 = g2/dsum;  g3 = g3/dsum

    cv5  = g1*cv5_g1 + g2*cv5_g2 + g3*cv5_g3
    cv1  = cv5 - 0.50
    cv10 = cv5 + 0.35

    if (pct == 1)  return(cv1)
    if (pct == 10) return(cv10)
    return(cv5)
}

// ------------------------------------------------------------
// Main entry point called from garchur.ado:
//   mata: garchur_compute("varname", "touse", "model", nbreaks, trim)
//
// Stores all results in r() scalars for retrieval by Stata
// Creates auxiliary variables _garchur_ht and _garchur_sr
// ------------------------------------------------------------
void garchur_compute(
    string scalar varname,
    string scalar touse,
    string scalar model,
    real scalar   nbreaks,
    real scalar   trim)
{
    real colvector y, TB, ht, resid
    real scalar T, j, cv1, cv5, cv10
    real scalar rho, tstat, alpha, beta, kappa, halflife, loglik, nobs

    // Pull in-sample data
    st_view(y=., ., varname, touse)
    y = y :+ 0       // force deep copy (view -> matrix)
    T = rows(y)

    // Step 1: Find break dates (paper eq. 3-4)
    TB = garchur_breakdate(y, nbreaks, model, trim)

    // Step 2: Estimate model (paper eq. 1-2)
    // Results returned via reference parameters
    garchur_estimate(y, TB, model,
        rho, tstat, alpha, beta, kappa, halflife, loglik, nobs, ht, resid)

    // Step 3: Critical values from Table III
    cv1  = garchur_get_cv(T, alpha, beta, 1)
    cv5  = garchur_get_cv(T, alpha, beta, 5)
    cv10 = garchur_get_cv(T, alpha, beta, 10)

    // Step 4 (run FIRST): Create _garchur_ht and _garchur_sr
    // These stata() calls may internally clear r() scalars, so we
    // run them BEFORE setting r() to ensure our values survive.
    stata("capture drop _garchur_ht")
    stata("capture drop _garchur_sr")
    stata("quietly generate double _garchur_ht = .")
    stata("quietly generate double _garchur_sr = .")

    real scalar ht_col, sr_col, total_obs, n, count, touse_col, ht_val
    ht_col    = st_varindex("_garchur_ht")
    sr_col    = st_varindex("_garchur_sr")
    touse_col = st_varindex(touse)
    total_obs = st_nobs()
    count     = 0

    for (n = 1; n <= total_obs; n++) {
        if (st_data(n, touse_col) == 1) {
            count++
            if (count >= 2 & count <= rows(ht)+1) {
                ht_val = ht[count-1]
                st_store(n, ht_col, ht_val)
                if (ht_val > 0) {
                    st_store(n, sr_col, resid[count-1] / sqrt(ht_val))
                }
            }
        }
    }

    // Step 5 (run LAST): Push results to Stata r()
    // Must be last so stata() calls above do not clear these values.
    st_numscalar("r(stat)",     tstat)
    st_numscalar("r(rho)",      rho)
    st_numscalar("r(alpha)",    alpha)
    st_numscalar("r(beta)",     beta)
    st_numscalar("r(kappa)",    kappa)
    st_numscalar("r(halflife)", halflife)
    st_numscalar("r(loglik)",   loglik)
    st_numscalar("r(nobs)",     nobs)
    st_numscalar("r(cv1)",      cv1)
    st_numscalar("r(cv5)",      cv5)
    st_numscalar("r(cv10)",     cv10)
    st_numscalar("r(nbreaks)",  nbreaks)
    st_numscalar("r(ab)",       alpha + beta)

    for (j = 1; j <= nbreaks; j++) {
        st_numscalar("r(TB" + strofreal(j) + ")", TB[j])
    }
}

end
