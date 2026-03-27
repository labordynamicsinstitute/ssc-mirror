*! _xtlmbreak_engine.ado — Core Mata engine for xtlmbreak
*! Implements: Westerlund (2006, OBES)
*! "Testing for Panel Cointegration with Multiple Structural Breaks"
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Version 1.0.0 — 25 March 2026
*!
*! Direct translation of GAUSS code (llm.src) by Joakim Westerlund

version 14.0

capture mata: mata drop lb_*()

mata:
mata set matastrict off

// ============================================================
// lb_olsqr: OLS coefficient vector
// GAUSS equivalent: olsqr(y, x)
// ============================================================
real colvector lb_olsqr(real colvector y, real matrix x)
{
    return(invsym(cross(x,x)) * cross(x,y))
}

// ============================================================
// lb_fejer: One-sided Fejér/Bartlett kernel LR variance
// GAUSS: fejer(u, p)
// Returns scalar: Σ_{j=1}^{p} (1-j/(p+1)) * (1/T) * u[j+1:]'u[1:T-j]
// ============================================================
real scalar lb_fejer(real colvector u, real scalar p)
{
    real scalar t, io, j
    t = rows(u)
    io = 0
    for (j=1; j<=p; j++) {
        io = io + (1 - j/(p+1)) * (1/t) * cross(u[|j+1\t|], u[|1\t-j|])
    }
    return(io)
}

// ============================================================
// lb_lm: Core LM statistic (Cramér-von Mises)
// GAUSS: lm(u)
//   s = (u'u)/t + fejer + fejer' → long-run variance
//   lm = sumc(cumsumc(u).^2) / (t^2 * s)
// ============================================================
real scalar lb_lm(real colvector u)
{
    real scalar t, s, io
    real colvector cs

    t = rows(u)
    if (t < 3) return(0)
    s = cross(u,u) / t
    io = lb_fejer(u, floor(t^(1/3)))
    s = s + io + io
    if (s <= 0) s = cross(u,u) / t
    cs = runningsum(u)
    return(cross(cs, cs) / (t^2 * s))
}

// ============================================================
// lb_dols: DOLS residuals (Saikkonen 1991)
// y: T×1, x: T×K, mod: 0-4, p: leads/lags
// Returns residuals for effective sample
// ============================================================
real colvector lb_dols(real colvector y, real matrix x,
                       real scalar mod, real scalar p)
{
    real scalar t, k, q, teff, start_t, end_t, i
    real matrix z, dx, W, dx_block
    real colvector beta, u, y_eff

    t = rows(y)
    k = cols(x)

    // Deterministic component
    if (mod == 0) {
        z = J(t, 0, .)
    }
    else if (mod == 1 | mod == 3) {
        z = J(t, 1, 1)
    }
    else {
        z = J(t, 1, 1), (1::t)
    }
    q = cols(z)

    // First differences of x
    if (t < 2) return(J(t, 1, 0))
    dx = x[|2,1\t,k|] - x[|1,1\t-1,k|]

    // Effective sample
    start_t = p + 2
    end_t = t - p
    teff = end_t - start_t + 1
    if (teff < max((5, 2*k+2*q+1))) return(J(t, 1, 0))

    y_eff = y[|start_t\end_t|]

    // Build lead/lag block of Δx
    dx_block = J(teff, (2*p+1)*k, 0)
    for (i = -p; i <= p; i++) {
        dx_block[|1,(i+p)*k+1\teff,(i+p+1)*k|] = dx[|start_t+i-1,1\end_t+i-1,k|]
    }

    // Regressor matrix
    if (q > 0) {
        W = z[|start_t,1\end_t,q|], x[|start_t,1\end_t,k|], dx_block
    }
    else {
        W = x[|start_t,1\end_t,k|], dx_block
    }

    beta = lb_olsqr(y_eff, W)
    u = y_eff - W * beta

    return(u)
}

// ============================================================
// lb_fmols: FMOLS residuals (Phillips & Hansen 1990)
// y: T×1, x: T×K, mod: 0-4, p: bandwidth
// Returns residuals for effective sample (T-1 obs)
// ============================================================
real colvector lb_fmols(real colvector y, real matrix x,
                        real scalar mod, real scalar p)
{
    real scalar t, k, q, j, kk
    real matrix z, W, dx, Omega, Lambda, Omega22, ww
    real colvector ehat, beta, beta_plus, u, y_plus
    real colvector omega12, lambda21_plus, delta
    real scalar omega11
    real matrix Gamma_j

    t = rows(y)
    k = cols(x)

    // Deterministic component
    if (mod == 0) {
        z = J(t, 0, .)
    }
    else if (mod == 1 | mod == 3) {
        z = J(t, 1, 1)
    }
    else {
        z = J(t, 1, 1), (1::t)
    }
    q = cols(z)

    // OLS
    if (q > 0) {
        W = z, x
    }
    else {
        W = x
    }
    beta = lb_olsqr(y, W)
    ehat = y - W * beta

    // First differences of x
    dx = x[|2,1\t,k|] - x[|1,1\t-1,k|]

    // Work on sample t=2,...,T
    real colvector e2
    real matrix dx2
    real scalar t2
    e2 = ehat[|2\t|]
    dx2 = dx
    t2 = t - 1

    // Build w = (e, Δx) matrix, (t2 × 1+k)
    ww = e2, dx2

    // Long-run covariance Ω using Bartlett kernel
    Omega = cross(ww, ww) / t2
    Lambda = cross(ww, ww) / (2*t2)
    for (j=1; j<=p; j++) {
        Gamma_j = cross(ww[|j+1,1\t2,1+k|], ww[|1,1\t2-j,1+k|]) / t2
        Omega = Omega + (1 - j/(p+1)) * (Gamma_j + Gamma_j')
        Lambda = Lambda + (1 - j/(p+1)) * Gamma_j
    }

    // Partition Ω and Λ
    omega11 = Omega[1,1]
    omega12 = Omega[|1,2\1,1+k|]'
    Omega22 = Omega[|2,2\1+k,1+k|]

    // FMOLS correction
    y_plus = y[|2\t|] - dx2 * invsym(Omega22) * omega12

    // Bias correction
    delta = Lambda[|2,1\1+k,1|] - Omega[|2,1\1+k,1|] * (1/omega11) * Lambda[1,1]

    // FMOLS estimation
    real matrix W2
    if (q > 0) {
        W2 = z[|2,1\t,q|], x[|2,1\t,k|]
    }
    else {
        W2 = x[|2,1\t,k|]
    }

    beta_plus = lb_olsqr(y_plus, W2)
    // Bias correction term
    real colvector bias_vec
    bias_vec = J(q, 1, 0) \ delta
    beta_plus = beta_plus - invsym(cross(W2, W2)) * t2 * bias_vec

    u = y_plus - W2 * beta_plus

    return(u)
}

// ============================================================
// lb_estim_west: Estimation dispatcher
// GAUSS: estim_west(y, x, mod, est)
//   p = int(t^(1/3)); calls dols or fmols
// ============================================================
real colvector lb_estim_west(real colvector y, real matrix x,
                             real scalar mod, real scalar est)
{
    real scalar p
    p = floor(rows(y)^(1/3))
    if (est == 1) {
        return(lb_dols(y, x, mod, p))
    }
    else {
        return(lb_fmols(y, x, mod, p))
    }
}

// ============================================================
// lb_ssr_west: Recursive SSR computation
// GAUSS: ssr_west(d0, d1, y, z, seg)
// Uses Sherman-Morrison rank-1 OLS update
// Returns T×1 vector of cumulative SSR
// ============================================================
real colvector lb_ssr_west(real scalar d0, real scalar d1,
                           real colvector y, real matrix z,
                           real scalar seg)
{
    real scalar r, f, v, qz
    real colvector s, del1, del2, inv3, u_init
    real matrix inv1, inv2, z_init

    qz = cols(z)
    s = J(d1, 1, 0)

    z_init = z[|d0,1\d0+seg-1,qz|]
    inv1 = invsym(cross(z_init, z_init))
    del1 = inv1 * cross(z_init, y[|d0\d0+seg-1|])
    u_init = y[|d0\d0+seg-1|] - z_init * del1
    s[d0+seg-1] = cross(u_init, u_init)

    for (r = d0+seg; r <= d1; r++) {
        v = y[r] - z[|r,1\r,qz|] * del1
        inv3 = inv1 * z[|r,1\r,qz|]'
        f = 1 + z[|r,1\r,qz|] * inv3
        del2 = del1 + (inv3 * v) / f
        inv2 = inv1 - (inv3 * inv3') / f
        inv1 = inv2
        del1 = del2
        s[r] = s[r-1] + v*v/f
    }

    return(s)
}

// ============================================================
// lb_parti_west: Optimal single partition
// GAUSS: parti_west(s0, b0, b1, s1, ssrv, t)
// Returns: (min_ssr, break_date)
// ============================================================
real rowvector lb_parti_west(real scalar s0, real scalar b0,
                              real scalar b1, real scalar s1,
                              real colvector ssrv, real scalar t)
{
    real scalar j, l_idx, k_idx, best_ssr, best_d
    real colvector d, mi_idx, mi_w

    d = J(t, 1, 1e20)
    real scalar i_start
    i_start = (s0-1)*t - (s0-2)*(s0-1)/2 + 1

    for (j = b0; j <= b1; j++) {
        l_idx = j - s0
        k_idx = j*(t-1) - (j-1)*j/2 + s1
        d[j] = ssrv[i_start + l_idx] + ssrv[k_idx]
    }

    best_ssr = min(d[|b0\b1|])
    minindex(d[|b0\b1|], 1, mi_idx, mi_w)
    best_d = (b0-1) + mi_idx[1]

    return((best_ssr, best_d))
}

// ============================================================
// lb_dati_west: Dynamic programming break detection
// GAUSS: dati_west(y, z, seg, m)
// Returns m×m matrix of break dates (upper triangular)
// ============================================================
real matrix lb_dati_west(real colvector y, real matrix z,
                         real scalar seg, real scalar m)
{
    real scalar i, t, j, l
    real matrix dt0, odt
    real colvector ossr, d, ssr0, ssr1, ssrv, mi_idx, mi_w
    real rowvector result

    t = rows(y)
    dt0 = J(m, m, 0)
    odt = J(t, m, 0)
    ossr = J(t, m, 0)
    d = J(t, 1, 0)
    ssr0 = J(m, 1, 0)
    ssrv = J(t*(t+1)/2, 1, 0)

    // Pre-compute all sub-sample SSRs
    for (i = 1; i <= t-seg+1; i++) {
        ssr1 = lb_ssr_west(i, t, y, z, seg)
        ssrv[|(i-1)*t+i-(i-1)*i/2 \ i*t-(i-1)*i/2|] = ssr1[|i\t|]
    }

    if (m == 1) {
        result = lb_parti_west(1, seg, t-seg, t, ssrv, t)
        dt0[1,1] = result[2]
        ssr0[1,1] = result[1]
    }
    else {
        // Single break optimal for all endpoints
        for (j = 2*seg; j <= t; j++) {
            result = lb_parti_west(1, seg, j-seg, j, ssrv, t)
            ossr[j,1] = result[1]
            odt[j,1] = result[2]
        }

        ssr0[1,1] = ossr[t,1]
        dt0[1,1] = odt[t,1]

        for (i = 2; i <= m; i++) {
            real scalar dt_idx, ll

            if (i == m) {
                ll = t
                for (dt_idx = i*seg; dt_idx <= ll-seg; dt_idx++) {
                    d[dt_idx] = ossr[dt_idx,i-1] + ssrv[(dt_idx+1)*t - dt_idx*(dt_idx+1)/2]
                }
                ossr[ll,i] = min(d[|i*seg\ll-seg|])
                minindex(d[|i*seg\ll-seg|], 1, mi_idx, mi_w)
                odt[ll,i] = (i*seg-1) + mi_idx[1]
            }
            else {
                for (ll = (i+1)*seg; ll <= t; ll++) {
                    for (dt_idx = i*seg; dt_idx <= ll-seg; dt_idx++) {
                        d[dt_idx] = ossr[dt_idx,i-1] + ssrv[dt_idx*t - dt_idx*(dt_idx-1)/2 + ll - dt_idx]
                    }
                    ossr[ll,i] = min(d[|i*seg\ll-seg|])
                    minindex(d[|i*seg\ll-seg|], 1, mi_idx, mi_w)
                    odt[ll,i] = (i*seg-1) + mi_idx[1]
                }
            }

            // Trace back
            dt0[i,i] = odt[t,i]
            for (j = 1; j <= i-1; j++) {
                l = i - j
                dt0[l,i] = odt[dt0[l+1,i], l]
            }
            ssr0[i,1] = ossr[t,i]
        }
    }

    return(dt0)
}

// ============================================================
// lb_pzbar: Partitioned dummy matrix
// GAUSS: pzbar(z, i, dt)
// Creates block-diagonal z across i+1 regimes
// ============================================================
real matrix lb_pzbar(real matrix z, real scalar nbrk,
                     real colvector dt)
{
    real scalar t, q, j
    real matrix zd

    t = rows(z)
    q = cols(z)
    zd = J(t, (nbrk+1)*q, 0)
    zd[|1,1\dt[1],q|] = z[|1,1\dt[1],q|]

    for (j = 2; j <= nbrk; j++) {
        zd[|dt[j-1]+1,(j-1)*q+1\dt[j],j*q|] = z[|dt[j-1]+1,1\dt[j],q|]
    }

    zd[|dt[nbrk]+1,nbrk*q+1\t,(nbrk+1)*q|] = z[|dt[nbrk]+1,1\t,q|]

    return(zd)
}

// ============================================================
// lb_ssr0: SSR for no-break model
// GAUSS: ssr0(y, x, mod)
// ============================================================
real scalar lb_ssr0_val(real colvector y, real matrix x, real scalar mod)
{
    real scalar t
    real matrix z, W
    real colvector b, resid

    t = rows(y)
    if (mod == 3) {
        z = J(t, 1, 1)
    }
    else {
        z = J(t, 1, 1), (1::t)
    }

    W = z, x
    b = lb_olsqr(y, W)
    resid = y - W * b
    return(cross(resid, resid))
}

// ============================================================
// lb_order: BIC model selection for # breaks
// GAUSS: order(s0, ssr0, t, m, mod)
// Returns optimal number of breaks
// ============================================================
real scalar lb_order(real scalar s0, real colvector ssr0_vec,
                     real scalar t, real scalar m, real scalar mod)
{
    real scalar i, q
    real colvector ssr, bic

    q = mod - 2
    ssr = J(m+1, 1, 0)
    ssr[1] = s0
    ssr[|2\m+1|] = ssr0_vec
    bic = J(m+1, 1, 0)

    real colvector bi_idx, bi_w
    for (i = 0; i <= m; i++) {
        bic[i+1] = ln(ssr[i+1]/t) + ln(t)*i*(q+1)/t
    }

    minindex(bic, 1, bi_idx, bi_w)
    return(bi_idx[1] - 1)
}

// ============================================================
// lb_dat_west: Iterative break estimation (Bai-Perron)
// GAUSS: dat_west(y, x, mod, seg, m, eps, ite)
// Returns: (ssr0_vec, dt0_matrix)
// ============================================================
void lb_dat_west(real colvector y, real matrix x,
                 real scalar mod, real scalar seg, real scalar m,
                 real scalar eps, real scalar ite,
                 real colvector ssr0_out, real matrix dt0_out)
{
    real scalar t, i, j, qz
    real matrix z, dt, xbar, zbar
    real colvector te0, te1, de1, be1
    real scalar ssr1, ssrn, length

    t = rows(y)

    if (mod == 3) {
        z = J(t, 1, 1)
    }
    else {
        z = J(t, 1, 1), (1::t)
    }
    qz = cols(z)

    ssr0_out = J(m, 1, 0)
    dt0_out = J(m, m, 0)

    for (i = 1; i <= m; i++) {
        // Initial break detection
        dt = lb_dati_west(y, (x, z), seg, i)
        xbar = lb_pzbar(x, i, dt[|1,i\i,i|])
        zbar = lb_pzbar(z, i, dt[|1,i\i,i|])

        te0 = lb_olsqr(y, (zbar, xbar))
        de1 = te0[|1\qz*(i+1)|]
        be1 = lb_olsqr(y - zbar*de1, x)
        ssr1 = cross(y - x*be1 - zbar*de1, y - x*be1 - zbar*de1)

        // Iterate
        for (j = 1; j <= ite; j++) {
            dt = lb_dati_west(y - x*be1, z, seg, i)
            zbar = lb_pzbar(z, i, dt[|1,i\i,i|])
            te1 = lb_olsqr(y, (x, zbar))
            be1 = te1[|1\cols(x)|]
            de1 = te1[|cols(x)+1\cols(x)+qz*(i+1)|]
            ssrn = cross(y - (x,zbar)*te1, y - (x,zbar)*te1)
            length = abs(ssrn - ssr1)

            if (j >= ite) {
                ssr0_out[i] = ssrn
                dt0_out[|1,i\i,i|] = dt[|1,i\i,i|]
                break
            }

            if (length <= eps) {
                ssr0_out[i] = ssrn
                dt0_out[|1,i\i,i|] = dt[|1,i\i,i|]
                break
            }

            ssr1 = ssrn
            ssr0_out[i] = ssrn
            dt0_out[|1,i\i,i|] = dt[|1,i\i,i|]
        }
    }
}

// ============================================================
// lb_breaks: Determine number and locations of breaks
// GAUSS: breaks(y, x, mod, seg, m, cri, ite)
// Returns: (nbr+1) × 1 vector: [nbr; tb1; ...; tbm]
// ============================================================
real colvector lb_breaks(real colvector y, real matrix x,
                         real scalar mod, real scalar seg,
                         real scalar m, real scalar cri,
                         real scalar ite)
{
    real scalar t, nbr
    real colvector tb, result
    real colvector ssrv
    real matrix dt0
    real scalar s0

    t = rows(y)

    if (mod == 0 | mod == 1 | mod == 2) {
        tb = J(m, 1, 0)
        nbr = 0
    }
    else {
        lb_dat_west(y, x, mod, seg, m, cri, ite, ssrv, dt0)
        s0 = lb_ssr0_val(y, x, mod)
        nbr = lb_order(s0, ssrv, t, m, mod)
    }

    if (nbr > 0) {
        tb = dt0[|1,nbr\m,nbr|]
    }
    else {
        tb = J(m, 1, 0)
    }

    result = nbr \ tb
    return(result)
}

// ============================================================
// lb_mom: Response surface moments
// GAUSS: mom_llm(mod, k, est, t)
// Returns: (mu, var) based on Tables 2 & 3
// ============================================================
real rowvector lb_mom(real scalar mod, real scalar k,
                      real scalar est, real scalar t)
{
    real matrix a2, a3
    real rowvector a1
    real scalar mu, var_val

    if (k < 1) k = 1
    if (k > 5) k = 5

    if (est == 1) {
        // DOLS
        if (mod == 0) {
            a2 = ( 0.36132,-0.22961, 1.57112,-16.31658 \
                   0.27401,-0.31577, 1.99793,-15.55645 \
                   0.22226,-0.63793, 4.13834,-30.95020 \
                   0.18901,-0.82065, 5.10891,-33.87714 \
                   0.14815,-0.40345, 1.59114, 29.82585 )
            a3 = ( 0.19043,-0.44026, 0.68625,-10.46369 \
                   0.11030,-0.24182, 0.18178, -0.98334 \
                   0.07280,-0.41392, 2.05185,-18.72711 \
                   0.05053,-0.39326, 2.01483,-17.22861 \
                   0.03162,-0.22870, 1.08659, -7.95727 )
        }
        else if (mod == 1 | mod == 3) {
            a2 = ( 0.11625, 0.00344, 0.25486, 10.42508 \
                   0.08775,-0.06769, 0.69281,  9.15342 \
                   0.06583, 0.02019,-0.05966, 22.41660 \
                   0.05238, 0.03925,-0.27469, 30.42694 \
                   0.04255, 0.08621,-0.72910, 41.76848 )
            a3 = ( 0.01159,-0.03922, 0.15646,-2.72168 \
                   0.00642,-0.03858, 0.20346,-2.59177 \
                   0.00301,-0.01180, 0.04324,-0.67325 \
                   0.00177,-0.01178, 0.05704,-0.63751 \
                   0.00109,-0.00809, 0.03283,-0.24776 )
        }
        else {
            a2 = ( 0.05347, 0.10835,-0.31741, 19.11540 \
                   0.04542, 0.10271,-0.39739, 23.86645 \
                   0.03855, 0.11087,-0.54675, 30.28444 \
                   0.03248, 0.14376,-0.88995, 39.98488 \
                   0.02710, 0.19392,-1.38020, 52.16569 )
            a3 = ( 0.00124,-0.00398, 0.00988,-0.24893 \
                   0.00091,-0.00446, 0.01700,-0.24814 \
                   0.00062,-0.00303, 0.00961,-0.10056 \
                   0.00044,-0.00217, 0.00279, 0.07898 \
                   0.00027,-0.00027,-0.01137, 0.34558 )
        }
    }
    else {
        // FMOLS
        if (mod == 0) {
            a2 = ( 0.35264, 0.05048,-0.61249, 12.82076 \
                   0.26144, 0.03296,-0.91888, 17.62065 \
                   0.20695,-0.12335,-0.20455, 15.76128 \
                   0.16916,-0.26228, 0.82432,  8.03949 \
                   0.13943,-0.24630, 0.75407, 11.69389 )
            a3 = ( 0.18995,-0.42167, 0.51418,-0.56690 \
                   0.09720, 0.11888,-2.31403, 24.26596 \
                   0.06441,-0.12325,-0.26189,  5.93036 \
                   0.04111,-0.13058, 0.15712,  0.77613 \
                   0.02693,-0.10471, 0.17162,  0.30837 )
        }
        else if (mod == 1 | mod == 3) {
            a2 = ( 0.11708,-0.05532, 0.31233,  3.14865 \
                   0.08557,-0.06494, 0.24917,  6.69821 \
                   0.06730,-0.11746, 0.60610,  6.52534 \
                   0.05391,-0.09801, 0.49008, 11.09135 \
                   0.04451,-0.09041, 0.53038, 13.72616 )
            a3 = ( 0.01130,-0.02838,-0.02232, 0.55336 \
                   0.00581,-0.02252, 0.01171, 0.30932 \
                   0.00309,-0.02008, 0.05684,-0.21322 \
                   0.00161,-0.00995, 0.01394, 0.19668 \
                   0.00095,-0.00646, 0.00484, 0.31930 )
        }
        else {
            a2 = ( 0.05515, 0.01680, 0.21483,  4.98491 \
                   0.04749,-0.02300, 0.39897,  6.46768 \
                   0.04103,-0.03676, 0.45948,  9.02230 \
                   0.03558,-0.04270, 0.53224, 11.23719 \
                   0.03073,-0.02145, 0.41501, 15.37253 )
            a3 = ( 0.00125,-0.00527, 0.00590, 0.02762 \
                   0.00085,-0.00385, 0.00168, 0.10582 \
                   0.00057,-0.00232,-0.00541, 0.22323 \
                   0.00036,-0.00087,-0.01211, 0.33811 \
                   0.00025,-0.00023,-0.01607, 0.46277 )
        }
    }

    a1 = (1, t^(-0.5), t^(-1), t^(-2))
    mu = a1 * a2[k,.]'
    var_val = a1 * a3[k,.]'
    return((mu, var_val))
}

// ============================================================
// lb_lmbreak: Individual LM test with breaks
// GAUSS: lmbreak(y, x, mod, nbr, tb, est, mu, var)
// Returns: (lm_stat, (nbr+1)*mu, (nbr+1)^2*var)
// ============================================================
real rowvector lb_lmbreak(real colvector y, real matrix x,
                           real scalar mod, real scalar nbr,
                           real colvector tb, real scalar est,
                           real scalar mu, real scalar var_val)
{
    real scalar lmi, j
    real colvector yb, u_resid
    real matrix xb

    lmi = 0

    if (mod == 0 | mod == 1 | mod == 2) {
        u_resid = lb_estim_west(y, x, mod, est)
        if (rows(u_resid) > 2) lmi = lmi + lb_lm(u_resid)
    }
    else {
        if (nbr > 0) {
            // First regime
            yb = y[|1\tb[1]|]
            xb = x[|1,1\tb[1],cols(x)|]
            u_resid = lb_estim_west(yb, xb, mod, est)
            if (rows(u_resid) > 2) lmi = lmi + lb_lm(u_resid)

            // Middle regimes
            for (j = 2; j <= nbr; j++) {
                yb = y[|1+tb[j-1]\tb[j]|]
                xb = x[|1+tb[j-1],1\tb[j],cols(x)|]
                u_resid = lb_estim_west(yb, xb, mod, est)
                if (rows(u_resid) > 2) lmi = lmi + lb_lm(u_resid)
            }

            // Last regime
            yb = y[|1+tb[nbr]\rows(y)|]
            xb = x[|1+tb[nbr],1\rows(x),cols(x)|]
            u_resid = lb_estim_west(yb, xb, mod, est)
            if (rows(u_resid) > 2) lmi = lmi + lb_lm(u_resid)
        }
        else {
            u_resid = lb_estim_west(y, x, mod, est)
            if (rows(u_resid) > 2) lmi = lmi + lb_lm(u_resid)
        }
    }

    return((lmi, (nbr+1)*mu, (nbr+1)^2*var_val))
}

// ============================================================
// lb_lmbreak_panel: Full panel LM test
// GAUSS: lmbreak_panel(y, x, mod, est, seg, m, cri, ite)
// y: T×N, x: T×(N*K)
// Returns results in external Mata globals
// ============================================================
void lb_lmbreak_panel(real matrix y, real matrix x,
                      real scalar mod, real scalar est,
                      real scalar seg, real scalar m,
                      real scalar cri, real scalar ite)
{
    real scalar i, n, t, k
    real colvector y0, bri_col, tb_i
    real matrix x0
    real rowvector mom, lm_result
    real scalar mu, var_val, nbr_i
    real colvector lmi_vec
    real matrix bri_mat

    n = cols(y)
    t = rows(y)
    k = cols(x) / n

    mom = lb_mom(mod, k, est, t)
    mu = mom[1]
    var_val = mom[2]

    bri_mat = J(m+1, n, 0)
    lmi_vec = J(1, 3, 0)

    for (i = 1; i <= n; i++) {
        y0 = y[.,i]
        if (k == 1) {
            x0 = x[.,i]
        }
        else {
            x0 = x[|1,1+k*(i-1)\t,k*i|]
        }

        bri_col = lb_breaks(y0, x0, mod, seg, m, cri, ite)
        bri_mat[.,i] = bri_col
        nbr_i = bri_col[1]

        if (nbr_i > 0) {
            tb_i = bri_col[|2\nbr_i+1|]
            tb_i = select(tb_i, tb_i :> 0)
        }
        else {
            tb_i = J(0, 1, 0)
        }

        lm_result = lb_lmbreak(y0, x0, mod, nbr_i, tb_i, est, mu, var_val)
        lmi_vec = lmi_vec + lm_result
    }

    // Standardize
    real scalar mu_bar, var_bar, Z_stat
    mu_bar = lmi_vec[2] / n
    var_bar = lmi_vec[3] / n
    if (var_bar > 0) {
        Z_stat = sqrt(n) * (lmi_vec[1]/n - mu_bar) / sqrt(var_bar)
    }
    else {
        Z_stat = .
    }

    // Store results in external globals
    external real scalar lb_Z_stat
    external real scalar lb_mu_bar
    external real scalar lb_var_bar
    external real scalar lb_mean_lm
    external real matrix lb_breaks_mat
    external real scalar lb_mu_moment
    external real scalar lb_var_moment

    lb_Z_stat = Z_stat
    lb_mu_bar = mu_bar
    lb_var_bar = var_bar
    lb_mean_lm = lmi_vec[1] / n
    lb_breaks_mat = bri_mat
    lb_mu_moment = mu
    lb_var_moment = var_val
}

// ============================================================
// lb_graph_individual_lm: Compute individual LM stats for graph
// Called from xtlmbreak.ado graph section
// ============================================================
void lb_graph_individual_lm(real matrix y_m, real matrix x_m,
                            real scalar modd, real scalar estt,
                            real scalar segg, real scalar mm,
                            real scalar tol, real scalar ite)
{
    real scalar nn, tt, kk, i, mu_v, var_v, nbr_v
    real colvector y_i, brk_col, tb_tmp
    real matrix x_i
    real rowvector mom_v, lm_v

    nn = cols(y_m)
    tt = rows(y_m)
    kk = cols(x_m) / nn

    mom_v = lb_mom(modd, kk, estt, tt)
    mu_v = mom_v[1]
    var_v = mom_v[2]

    for (i=1; i<=nn; i++) {
        y_i = y_m[.,i]
        if (kk == 1) x_i = x_m[.,i]
        else x_i = x_m[|1,1+kk*(i-1)\tt,kk*i|]

        brk_col = lb_breaks(y_i, x_i, modd, segg, mm, tol, ite)
        nbr_v = brk_col[1]
        if (nbr_v > 0) {
            tb_tmp = brk_col[|2\nbr_v+1|]
            tb_tmp = select(tb_tmp, tb_tmp :> 0)
        }
        else tb_tmp = J(0,1,0)

        lm_v = lb_lmbreak(y_i, x_i, modd, nbr_v, tb_tmp, estt, mu_v, var_v)
        st_store(i, "lm_stat", lm_v[1])
    }
}

end
