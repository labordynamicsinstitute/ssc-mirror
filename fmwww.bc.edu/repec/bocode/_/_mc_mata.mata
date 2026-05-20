*! _mc_mata 1.0.2  18may2026  Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Mata core for the multicoint package -- pure .mata source file.
*!
*! Loaded on demand by every multicoint command via
*!     qui capture mata: __mc_loaded()
*!     if _rc qui _mc_mata

version 14.0
mata
mata set matastrict off

void __mc_loaded() { /* sentinel */ }


// ----------------------------------------------------------------------
//  ENGSTED-GONZALO-HALDRUP (1997) critical-value tables
// ----------------------------------------------------------------------
real matrix _mc_egh_table(string scalar trend, real scalar m2)
{
    real matrix tab
    tab = J(5, 20, 0)
    if (trend == "ct" & m2 == 1) {
        tab[1,] = (-5.21,-4.72,-4.29,-3.88,-4.66,-4.33,-4.01,-3.67,-4.55,-4.18,-3.90,-3.59,-4.41,-4.04,-3.83,-3.51,-4.33,-4.04,-3.78,-3.49)
        tab[2,] = (-5.60,-5.10,-4.71,-4.30,-5.11,-4.70,-4.42,-4.08,-4.85,-4.54,-4.26,-3.94,-4.73,-4.43,-4.19,-3.89,-4.73,-4.42,-4.15,-3.87)
        tab[3,] = (-6.09,-5.57,-5.14,-4.69,-5.47,-5.07,-4.74,-4.38,-5.21,-4.86,-4.58,-4.26,-5.07,-4.79,-4.51,-4.20,-5.00,-4.73,-4.48,-4.18)
        tab[4,] = (-6.47,-5.95,-5.53,-5.08,-5.89,-5.43,-5.13,-4.76,-5.52,-5.18,-4.91,-4.59,-5.38,-5.05,-4.78,-4.74,-5.34,-5.04,-4.78,-4.50)
        tab[5,] = (-6.95,-6.37,-5.90,-5.44,-6.35,-5.85,-5.47,-5.10,-5.86,-5.49,-5.20,-4.89,-5.66,-5.35,-5.08,-4.77,-5.63,-5.31,-5.06,-4.76)
        return(tab)
    }
    if (trend == "ct" & m2 == 2) {
        tab[1,] = (-5.81,-5.25,-4.83,-4.41,-5.14,-4.77,-4.45,-4.10,-4.93,-4.56,-4.31,-3.98,-4.81,-4.49,-4.20,-3.91,-4.75,-4.42,-4.14,-3.84)
        tab[2,] = (-6.24,-5.68,-5.21,-4.80,-5.62,-5.22,-4.89,-4.51,-5.23,-4.90,-4.62,-4.29,-5.11,-4.77,-4.50,-4.20,-5.05,-4.74,-4.48,-4.18)
        tab[3,] = (-6.70,-6.17,-5.70,-5.22,-5.98,-5.53,-5.17,-4.79,-5.59,-5.19,-4.93,-4.62,-5.35,-5.07,-4.80,-4.51,-5.34,-5.02,-4.75,-4.46)
        tab[4,] = (-7.19,-6.63,-6.08,-5.89,-6.23,-5.81,-5.48,-5.12,-5.97,-5.58,-5.25,-4.92,-5.69,-5.37,-5.07,-4.80,-5.67,-5.33,-5.06,-4.76)
        tab[5,] = (-7.61,-6.93,-6.43,-5.91,-6.64,-6.18,-5.82,-5.41,-6.09,-5.76,-5.50,-5.16,-5.95,-5.61,-5.34,-5.04,-5.92,-5.56,-5.29,-5.02)
        return(tab)
    }
    if (trend == "ctt" & m2 == 1) {
        tab[1,] = (-5.77,-5.28,-4.86,-4.43,-5.20,-4.81,-4.47,-4.12,-4.94,-4.60,-4.32,-3.98,-4.77,-4.47,-4.21,-3.92,-4.73,-4.43,-4.17,-3.88)
        tab[2,] = (-6.21,-5.69,-5.27,-4.83,-5.56,-5.16,-4.83,-4.47,-5.29,-4.93,-4.64,-4.32,-5.11,-4.79,-4.52,-4.20,-5.05,-4.75,-4.49,-4.20)
        tab[3,] = (-6.66,-6.10,-5.65,-5.20,-5.92,-5.50,-5.17,-4.82,-5.57,-5.23,-4.95,-4.63,-5.42,-5.08,-4.82,-4.52,-5.36,-5.04,-4.77,-4.48)
        tab[4,] = (-7.12,-6.51,-6.05,-5.55,-6.27,-5.85,-5.50,-5.12,-5.90,-5.54,-5.25,-4.91,-5.71,-5.38,-5.11,-4.81,-5.60,-5.30,-5.04,-4.76)
        tab[5,] = (-7.61,-6.93,-6.43,-5.91,-6.56,-6.15,-5.79,-5.41,-6.18,-5.81,-5.52,-5.19,-5.96,-5.64,-5.36,-5.05,-5.87,-5.57,-5.30,-5.26)
        return(tab)
    }
    tab[1,] = (-6.44,-5.85,-5.42,-4.96,-5.61,-5.21,-4.88,-4.52,-5.33,-4.97,-4.67,-4.34,-5.13,-4.79,-4.52,-4.23,-5.07,-4.76,-4.50,-4.21)
    tab[2,] = (-6.85,-6.30,-5.82,-5.33,-5.99,-5.58,-5.22,-4.86,-5.63,-5.27,-4.98,-4.65,-5.43,-5.09,-4.84,-4.54,-5.35,-5.05,-4.78,-4.49)
    tab[3,] = (-7.32,-6.68,-6.21,-5.69,-6.35,-5.90,-5.54,-5.16,-5.90,-5.54,-5.25,-4.92,-5.69,-5.37,-5.10,-4.80,-5.61,-5.29,-5.04,-4.76)
    tab[4,] = (-7.68,-7.06,-6.55,-6.03,-6.63,-6.23,-5.86,-5.46,-6.19,-5.85,-5.55,-5.22,-5.96,-5.64,-5.37,-5.07,-5.85,-5.55,-5.30,-5.02)
    tab[5,] = (-8.18,-7.47,-6.93,-6.38,-7.00,-6.55,-6.16,-5.76,-6.47,-6.10,-5.80,-5.47,-6.21,-5.87,-5.60,-5.31,-6.12,-5.80,-5.54,-5.26)
    return(tab)
}


void _mc_egh_cv(string scalar trend, real scalar m1, real scalar m2, real scalar T, string scalar cv01, string scalar cv025, string scalar cv05, string scalar cv10)
{
    real matrix tab
    real scalar irow, T0, w, Tlo, Thi, v01, v025, v05, v10, mm1, mm2
    real rowvector Tvec, qrow

    mm2 = m2
    mm1 = m1
    if (mm2 < 1) mm2 = 1
    if (mm2 > 2) mm2 = 2
    if (mm1 < 0) mm1 = 0
    if (mm1 > 4) mm1 = 4

    tab  = _mc_egh_table(trend, mm2)
    irow = mm1 + 1
    Tvec = (25, 50, 100, 250, 500)
    qrow = tab[irow,]

    if      (T <= 25)  T0 = 1
    else if (T <= 50)  T0 = 2
    else if (T <= 100) T0 = 3
    else if (T <= 250) T0 = 4
    else               T0 = 5

    if (T0 == 1) {
        v01  = qrow[1]
        v025 = qrow[2]
        v05  = qrow[3]
        v10  = qrow[4]
    }
    else {
        Tlo = Tvec[T0-1]
        Thi = Tvec[T0]
        w = (T - Tlo)/(Thi - Tlo)
        if (w < 0) w = 0
        if (w > 1) w = 1
        v01  = (1-w)*qrow[(T0-2)*4 + 1] + w*qrow[(T0-1)*4 + 1]
        v025 = (1-w)*qrow[(T0-2)*4 + 2] + w*qrow[(T0-1)*4 + 2]
        v05  = (1-w)*qrow[(T0-2)*4 + 3] + w*qrow[(T0-1)*4 + 3]
        v10  = (1-w)*qrow[(T0-2)*4 + 4] + w*qrow[(T0-1)*4 + 4]
    }
    st_numscalar(cv01,  v01)
    st_numscalar(cv025, v025)
    st_numscalar(cv05,  v05)
    st_numscalar(cv10,  v10)
}


// ----------------------------------------------------------------------
//  GRANGER-LEE rough p-value (MacKinnon Engle-Granger c.v. surrogate)
// ----------------------------------------------------------------------
void _mc_gl_pval(real scalar t, string scalar trend, real scalar k, real scalar T, string scalar pvname, string scalar cv05name)
{
    real matrix asymp05
    real scalar trow, kc, cv5, z, pv
    asymp05 = J(4, 7, 0)
    asymp05[1,] = (-1.95, -3.34, -3.74, -4.10, -4.42, -4.71, -4.98)
    asymp05[2,] = (-2.86, -3.34, -3.74, -4.10, -4.42, -4.71, -4.98)
    asymp05[3,] = (-3.41, -3.78, -4.12, -4.43, -4.72, -4.99, -5.25)
    asymp05[4,] = (-3.96, -4.32, -4.62, -4.89, -5.14, -5.38, -5.61)
    if      (trend == "none") trow = 1
    else if (trend == "c")    trow = 2
    else if (trend == "ct")   trow = 3
    else                       trow = 4
    kc = k + 1
    if (kc > 7) kc = 7
    if (kc < 1) kc = 1
    cv5 = asymp05[trow, kc]
    z = (t - cv5) / 0.8
    pv = normal(z)
    if (pv < 0) pv = 0
    if (pv > 1) pv = 1
    st_numscalar(pvname,   pv)
    st_numscalar(cv05name, cv5)
}


// ----------------------------------------------------------------------
//  TAOLS estimator -- basis-transform OLS
// ----------------------------------------------------------------------
void _mc_taols_compute(string scalar yvar, string scalar Xcums, string scalar Xflows, string scalar Dxs, string scalar trend, real scalar K, string scalar touse, string scalar bname, string scalar Vname, string scalar rssname, string scalar r2name, string scalar Nname, string scalar resvar)
{
    real matrix Y, Xc, Xf, Dx
    real matrix V_Y, V_Xc, V_Xf, V_Dx, V_l, V_tr
    real matrix Phi, Xdesign, XX, bvec, resid, Vmat
    real matrix bout, Vout, bxc, bxf, bdet
    real colvector uhat, touseflag, full
    real rowvector keep
    real scalar T, i, t, nXc, nXf, nDx, nd, sigma2, RSS, TSS, R2, ybar, c, ti, ki

    Y  = st_data(., yvar,           touse)
    Xc = st_data(., tokens(Xcums),  touse)
    Xf = st_data(., tokens(Xflows), touse)
    Dx = st_data(., tokens(Dxs),    touse)
    T  = rows(Y)

    Phi = J(T, K, 0)
    for (i=1; i<=K; i++) {
        for (t=1; t<=T; t++) {
            Phi[t,i] = sqrt(2)*sin( (i - 0.5)*pi()*(t/T) )
        }
    }

    V_Y  = (Phi' * Y)  / sqrt(T)
    V_Xc = (Phi' * Xc) / sqrt(T)
    V_Xf = (Phi' * Xf) / sqrt(T)
    V_Dx = (Phi' * Dx) / sqrt(T)
    V_l  = colsum(Phi)' / sqrt(T)

    V_tr = J(K, 0, 0)
    if (trend == "ct" | trend == "ctt") V_tr = (V_tr, (Phi'*(1::T))/sqrt(T)/T)
    if (trend == "ctt")                  V_tr = (V_tr, (Phi'*((1::T):^2))/sqrt(T)/T^2)

    nXc = cols(V_Xc)
    nXf = cols(V_Xf)
    nDx = cols(V_Dx)
    Xdesign = V_Xc, V_Xf, V_Dx
    if (trend != "none")                       Xdesign = Xdesign, V_l
    if (trend == "ct" | trend == "ctt")        Xdesign = Xdesign, V_tr[,1]
    if (trend == "ctt")                        Xdesign = Xdesign, V_tr[,2]

    XX = quadcross(Xdesign, Xdesign)
    bvec = qrsolve(XX, quadcross(Xdesign, V_Y))
    resid = V_Y - Xdesign * bvec
    sigma2 = (resid' * resid) / (K - cols(Xdesign))
    if (sigma2 <= 0 | sigma2 == .) sigma2 = (resid' * resid)/K
    Vmat = sigma2 * invsym(XX)

    nd = 0
    if (trend != "none")                       nd = nd + 1
    if (trend == "ct" | trend == "ctt")        nd = nd + 1
    if (trend == "ctt")                        nd = nd + 1

    keep = 1..(nXc + nXf)
    if (nd > 0) keep = (keep, (nXc+nXf+nDx+1)..(nXc+nXf+nDx+nd))

    bout = bvec[keep,]'
    Vout = Vmat[keep,keep]

    bxc = bvec[1..nXc,]
    bxf = bvec[(nXc+1)..(nXc+nXf),]
    uhat = Y - Xc*bxc - Xf*bxf

    if (nd > 0) {
        bdet = bvec[(nXc+nXf+nDx+1)..(nXc+nXf+nDx+nd),]
        c = 1
        if (trend != "none") {
            uhat = uhat :- bdet[c,1]
            c = c + 1
        }
        if (trend == "ct" | trend == "ctt") {
            uhat = uhat - bdet[c,1] * (1::T) / T
            c = c + 1
        }
        if (trend == "ctt") {
            uhat = uhat - bdet[c,1] * ((1::T):^2) / T^2
        }
    }

    RSS = uhat' * uhat
    ybar = mean(Y)
    TSS = (Y :- ybar)' * (Y :- ybar)
    R2 = 1 - RSS/TSS

    st_matrix(bname, bout)
    st_matrix(Vname, Vout)
    st_numscalar(rssname, RSS)
    st_numscalar(r2name,  R2)
    st_numscalar(Nname,   T)

    if (resvar != "") {
        touseflag = st_data(., touse)
        full = J(st_nobs(), 1, .)
        ki = 1
        for (ti=1; ti<=st_nobs(); ti++) {
            if (touseflag[ti] == 1) {
                full[ti] = uhat[ki]
                ki = ki + 1
            }
        }
        (void) st_addvar("double", resvar)
        st_store(., resvar, full)
    }
}


// ----------------------------------------------------------------------
//  TAOLS adaptive F-test (Sun et al 2026)
// ----------------------------------------------------------------------
real colvector __mc_diff_demean(real colvector x)
{
    real colvector dx
    real scalar n
    n = rows(x)
    if (n < 2) return(J(1,1,0))
    dx = x[2..n] - x[1..(n-1)]
    return(dx :- mean(dx))
}


void _mc_taols_test_compute(string scalar Ycumvar, string scalar yflowvar, string scalar Xcums, string scalar Xflows, string scalar Dxs, string scalar trend, real scalar K, real scalar nx, string scalar touse, string scalar Fm_n, string scalar Fmp_n, string scalar Fc_n, string scalar Fcp_n, string scalar Fa_n, string scalar Fap_n, string scalar w_n)
{
    real matrix Y, yf, Xc, Xf, Dx
    real matrix Phi, Vyc, Vy, Vxc, Vxf, Vdx, Vl, Vtr
    real matrix Xm, b_m, e_m, XXm, sigma_m, V_m
    real matrix Xc2, b_c, e_c, XXc, sigma_c, V_c
    real matrix gam_m, S_m, Wm, gam_c, S_c, Wc
    real scalar T, i, t, dfm, dfc, Omega_zz, Sigma_zz, ratio
    real scalar kappa, weight, Wa, dfden_m, dfden_c, p_m, p_c, p_a

    Y  = st_data(., Ycumvar,        touse)
    yf = st_data(., yflowvar,       touse)
    Xc = st_data(., tokens(Xcums),  touse)
    Xf = st_data(., tokens(Xflows), touse)
    Dx = st_data(., tokens(Dxs),    touse)
    T  = rows(Y)

    Phi = J(T, K, 0)
    for (i=1; i<=K; i++) {
        for (t=1; t<=T; t++) {
            Phi[t,i] = sqrt(2)*sin( (i - 0.5)*pi()*(t/T) )
        }
    }

    Vyc = (Phi'*Y)  / sqrt(T)
    Vy  = (Phi'*yf) / sqrt(T)
    Vxc = (Phi'*Xc) / sqrt(T)
    Vxf = (Phi'*Xf) / sqrt(T)
    Vdx = (Phi'*Dx) / sqrt(T)
    Vl  = colsum(Phi)'/sqrt(T)

    Vtr = J(K, 0, 0)
    if (trend == "ct" | trend == "ctt") Vtr = (Vtr, (Phi'*(1::T))/sqrt(T)/T)
    if (trend == "ctt")                  Vtr = (Vtr, (Phi'*((1::T):^2))/sqrt(T)/T^2)

    Xm = Vxc, Vxf, Vdx
    if (trend != "none")                       Xm = Xm, Vl
    if (trend == "ct" | trend == "ctt")        Xm = Xm, Vtr[,1]
    if (trend == "ctt")                        Xm = Xm, Vtr[,2]
    XXm = quadcross(Xm, Xm)
    b_m = qrsolve(XXm, quadcross(Xm, Vyc))
    e_m = Vyc - Xm*b_m
    dfm = K - cols(Xm)
    if (dfm <= 0) dfm = 1
    sigma_m = (e_m'*e_m)/dfm
    V_m     = sigma_m * invsym(XXm)

    Xc2 = Vxf, Vdx
    if (trend != "none")                       Xc2 = Xc2, Vl
    if (trend == "ct" | trend == "ctt")        Xc2 = Xc2, Vtr[,1]
    if (trend == "ctt")                        Xc2 = Xc2, Vtr[,2]
    XXc = quadcross(Xc2, Xc2)
    b_c = qrsolve(XXc, quadcross(Xc2, Vy))
    e_c = Vy - Xc2*b_c
    dfc = K - cols(Xc2)
    if (dfc <= 0) dfc = 1
    sigma_c = (e_c'*e_c)/dfc
    V_c     = sigma_c * invsym(XXc)

    gam_m = b_m[(nx+1)..(2*nx),1]
    S_m   = V_m[(nx+1)..(2*nx),(nx+1)..(2*nx)]
    Wm    = (gam_m'*invsym(S_m)*gam_m)/nx

    gam_c = b_c[(nx+1)..(2*nx),1]
    S_c   = V_c[(nx+1)..(2*nx),(nx+1)..(2*nx)]
    Wc    = (gam_c'*invsym(S_c)*gam_c)/nx

    Omega_zz = sum(e_m:^2)/dfm
    Sigma_zz = sum(__mc_diff_demean(yf):^2)/T
    if (Sigma_zz <= 0) Sigma_zz = 1
    ratio = Omega_zz/Sigma_zz

    kappa = 0.5
    weight = exp(-(T^kappa) * ratio)
    if (weight < 0) weight = 0
    if (weight > 1) weight = 1
    Wa = weight*Wm + (1-weight)*Wc

    dfden_m = K - 3*nx - 1
    dfden_c = K - 2*nx
    if (dfden_m < 1) dfden_m = 1
    if (dfden_c < 1) dfden_c = 1
    p_m = 1 - F(nx, dfden_m, Wm)
    p_c = 1 - F(nx, dfden_c, Wc)
    p_a = 1 - F(nx, dfden_m, Wa)
    if (p_m == .) p_m = 1
    if (p_c == .) p_c = 1
    if (p_a == .) p_a = 1

    st_numscalar(Fm_n,  Wm)
    st_numscalar(Fmp_n, p_m)
    st_numscalar(Fc_n,  Wc)
    st_numscalar(Fcp_n, p_c)
    st_numscalar(Fa_n,  Wa)
    st_numscalar(Fap_n, p_a)
    st_numscalar(w_n,   weight)
}

end
