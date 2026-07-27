*! xtpanicsb 1.0.0  23jul2026
*! PANIC panel unit-root test with sharp structural breaks (Bai & Carrion-i-Silvestre 2009)
*! MSB test on the idiosyncratic component, breaks by Bai-Perron (1998) dynamic programming
*! Author: Dr Merwan Roudane  (merwanroudane920@gmail.com)
*! https://github.com/merwanroudane
program xtpanicsb, rclass
    version 14.0
    syntax varname [if] [in] , [ Model(string) Breaks(integer 2) ///
        Kmax(integer 2) Pbar(integer 3) Trim(real 0.15) Factors(integer -1) ]

    if ("`model'"=="") local model "trend"
    local model = strlower("`model'")
    if !inlist("`model'","constant","trend") {
        di as error "model() must be constant (level breaks) or trend (level & trend breaks)"
        exit 198
    }
    local mnum = cond("`model'"=="constant",3,4)
    if `breaks'<1 | `breaks'>5 {
        di as error "breaks() must be between 1 and 5"
        exit 198
    }

    _xt, treq
    local id "`r(ivar)'"
    local tv "`r(tvar)'"
    marksample touse
    markout `touse' `varlist'
    qui xtset
    if "`r(balanced)'"!="strongly balanced" {
        di as error "xtpanicsb requires a strongly balanced panel"
        exit 451
    }
    tempvar tag
    qui by `id': gen byte `tag' = _n==1 if `touse'
    qui count if `tag'
    local N = r(N)
    qui count if `touse'
    local T = r(N)/`N'
    if `T'*`N' != r(N) {
        di as error "panel is not balanced over the estimation sample"
        exit 451
    }
    qui su `tv' if `touse', meanonly
    local tmin = r(min)

    tempname OUT STAT
    mata: _xps_run("`varlist'","`touse'", `N', `T', `mnum', `breaks', ///
        `kmax', `pbar', `trim', `factors', `tmin', "`OUT'", "`STAT'")

    local mlab = cond(`mnum'==3,"level breaks","level & trend breaks")
    di ""
    di as txt "PANIC panel unit-root test with sharp breaks (Bai-Carrion 2009)" ///
        _col(66) "N = " as res %4.0f `N'
    di as txt "H0: unit root (all panels)" _col(66) "T = " as res %4.0f `T'
    di as txt "Deterministics: `mlab', " as res %1.0f `breaks' as txt " break(s)" ///
        _col(50) "Common factors = " as res %2.0f `STAT'[1,3]
    di as txt "{hline 68}"
    di as txt "  id" _col(11) "MSB" _col(24) "p-value" _col(38) "break1" _col(50) "break2" _col(60) "lag"
    di as txt "{hline 68}"
    forvalues i = 1/`N' {
        di as res %4.0f `OUT'[`i',1] _col(7) %9.4f `OUT'[`i',2] ///
            _col(22) %8.3f `OUT'[`i',3] _col(36) %6.0f `OUT'[`i',4] ///
            _col(48) %6.0f `OUT'[`i',5] _col(59) %4.0f `OUT'[`i',6]
    }
    di as txt "{hline 68}"
    di as txt "Simplified panel tests:"
    di as txt "  Pval-chi (Fisher, " as res %3.0f 2*`N' as txt " df)" ///
        _col(40) as res %9.3f `STAT'[1,1] as txt "   p = " as res %6.3f `STAT'[1,4]
    di as txt "  Pval-normal (standardized)" _col(40) as res %9.3f `STAT'[1,2] ///
        as txt "   p = " as res %6.3f `STAT'[1,5]
    di as txt "{hline 68}"
    di as txt "Reject H0 (=> stationary) for a small MSB / large Pval-chi, Pval-normal."

    return scalar Pchi   = `STAT'[1,1]
    return scalar Pnorm  = `STAT'[1,2]
    return scalar Pchi_p = `STAT'[1,4]
    return scalar Pnorm_p = `STAT'[1,5]
    return scalar nf     = `STAT'[1,3]
    return matrix units = `OUT'
    return local model  "`model'"
    return local cmd    "xtpanicsb"
    return scalar N = `N'
    return scalar T = `T'
end

version 14.0
mata:

// ---------- Bai-Perron (1998) dynamic-programming break estimation --------
// recursive SSR for all segments starting at `start` (RLS updates)
real colvector _xps_ssr(real scalar start, real colvector y, real matrix z,
    real scalar h, real scalar last)
{
    real colvector vecssr, delta1, delta2, invzc, res
    real matrix inv1
    real scalar r, v, f
    vecssr = J(last, 1, 0)
    inv1 = luinv(cross(z[start..start+h-1,.], z[start..start+h-1,.]))
    delta1 = inv1 * cross(z[start..start+h-1,.], y[start..start+h-1])
    res = y[start..start+h-1] - z[start..start+h-1,.]*delta1
    vecssr[start+h-1] = cross(res,res)
    r = start + h
    while (r <= last) {
        v = y[r] - (z[r,.]*delta1)[1,1]
        invzc = inv1 * z[r,.]'
        f = 1 + (z[r,.]*invzc)[1,1]
        delta2 = delta1 + (invzc*v)/f
        inv1 = inv1 - (invzc*invzc')/f
        delta1 = delta2
        vecssr[r] = vecssr[r-1] + v*v/f
        r = r + 1
    }
    return(vecssr)
}
// optimal single break in [b1,b2]; returns (ssrmin, breakdate)
real rowvector _xps_parti(real scalar start, real scalar b1, real scalar b2,
    real scalar last, real colvector bigvec, real scalar bigt)
{
    real colvector dvec
    real scalar ini, j, jj, k, mn, mi, i
    dvec = J(bigt,1,.)
    ini = (start-1)*bigt - (start-2)*(start-1)/2 + 1
    j = b1
    while (j <= b2) {
        jj = j - start
        k = j*bigt - (j-1)*j/2 + last - j
        dvec[j] = bigvec[ini+jj] + bigvec[k]
        j = j + 1
    }
    mn = dvec[b1]; mi = b1
    i = b1 + 1
    while (i <= b2) {
        if (dvec[i] < mn) {
            mn = dvec[i]; mi = i
        }
        i = i + 1
    }
    return((mn, mi))
}
// full DP; returns datevec (m x m), column c = break dates when c breaks
real matrix _xps_dating(real colvector y, real matrix z, real scalar h,
    real scalar m, real scalar q, real scalar bigt)
{
    real matrix datevec, optdat, optssr
    real colvector dvec, bigvec, vecssr
    real scalar i, lo, hi, j1, ib, jlast, jb, xx, mn, mi, kk
    real rowvector pr
    datevec = J(m,m,0)
    optdat = J(bigt,m,0)
    optssr = J(bigt,m,0)
    dvec = J(bigt,1,.)
    bigvec = J(bigt*(bigt+1)/2,1,0)
    i = 1
    while (i <= bigt-h+1) {
        vecssr = _xps_ssr(i, y, z, h, bigt)
        lo = (i-1)*bigt + i - (i-1)*i/2
        hi = i*bigt - (i-1)*i/2
        bigvec[lo..hi] = vecssr[i..bigt]
        i = i + 1
    }
    if (m == 1) {
        pr = _xps_parti(1, h, bigt-h, bigt, bigvec, bigt)
        datevec[1,1] = pr[2]
        return(datevec)
    }
    j1 = 2*h
    while (j1 <= bigt) {
        pr = _xps_parti(1, h, j1-h, j1, bigvec, bigt)
        optssr[j1,1] = pr[1]
        optdat[j1,1] = pr[2]
        j1 = j1 + 1
    }
    datevec[1,1] = optdat[bigt,1]
    ib = 2
    while (ib <= m) {
        if (ib == m) {
            jlast = bigt
            jb = ib*h
            while (jb <= jlast-h) {
                dvec[jb] = optssr[jb,ib-1] + bigvec[(jb+1)*bigt - jb*(jb+1)/2]
                jb = jb + 1
            }
            mn = dvec[ib*h]; mi = ib*h
            kk = ib*h + 1
            while (kk <= jlast-h) {
                if (dvec[kk] < mn) {
                    mn = dvec[kk]; mi = kk
                }
                kk = kk + 1
            }
            optssr[jlast,ib] = mn
            optdat[jlast,ib] = mi
        }
        else {
            jlast = (ib+1)*h
            while (jlast <= bigt) {
                jb = ib*h
                while (jb <= jlast-h) {
                    dvec[jb] = optssr[jb,ib-1] + bigvec[jb*bigt - jb*(jb-1)/2 + jlast - jb]
                    jb = jb + 1
                }
                mn = dvec[ib*h]; mi = ib*h
                kk = ib*h + 1
                while (kk <= jlast-h) {
                    if (dvec[kk] < mn) {
                        mn = dvec[kk]; mi = kk
                    }
                    kk = kk + 1
                }
                optssr[jlast,ib] = mn
                optdat[jlast,ib] = mi
                jlast = jlast + 1
            }
        }
        datevec[ib,ib] = optdat[bigt,ib]
        i = 1
        while (i <= ib-1) {
            xx = ib - i
            datevec[xx,ib] = optdat[datevec[xx+1,ib], xx]
            i = i + 1
        }
        ib = ib + 1
    }
    return(datevec)
}

// ---------- OLS helper (GAUSS y/x = QR least squares) --------------------
real colvector _xps_lsq(real colvector y, real matrix X)
{
    return(qrsolve(X, y))
}
real matrix _xps_cumsum(real matrix X)
{
    real matrix C
    real scalar j
    C = X
    j = 1
    while (j <= cols(X)) {
        C[.,j] = runningsum(X[.,j])
        j = j + 1
    }
    return(C)
}
// break dummies (step + impulse) for a unit; d = raw break date (d leading zeros),
// matching the GAUSS construction zeros(d)|ones(Tm1-d) and zeros(d)|1|zeros(Tm1-d-1)
real matrix _xps_dummies(real scalar Tm1, real colvector tb)
{
    real matrix xreg
    real scalar j, d
    xreg = J(Tm1,1,1)
    j = 1
    while (j <= rows(tb)) {
        d = tb[j]
        xreg = xreg, (J(d,1,0)\J(Tm1-d,1,1)), (J(d,1,0)\1\J(Tm1-d-1,1,0))
        j = j + 1
    }
    return(xreg)
}

// ---------- Bai_Perron98: per-series break estimation on Dx (z=const) -----
// returns Dx (detrended diffs) and fills m_estimated_breaks (N x breaks+1)
void _xps_baiperron(real matrix x, real scalar breaks, real scalar h, real scalar trim,
    real matrix Dx, real matrix mtb)
{
    real scalar t, n, i, hh, nb
    real colvector zcol, tb
    real matrix z, dv, xreg
    t = rows(x)
    n = cols(x)
    Dx = x[2..t,.] - x[1..t-1,.]
    z = J(t-1,1,1)
    hh = trunc(trim*t)
    mtb = J(n, breaks+1, 0)
    for (i=1; i<=n; i++) {
        dv = _xps_dating(Dx[.,i], z, hh, breaks, 1, t-1)
        tb = dv[1..breaks, breaks]                 // break dates for `breaks` breaks
        mtb[i,1] = i
        mtb[i,2..breaks+1] = (tb :+ 1)'            // +1 for differenced data
        xreg = _xps_dummies(t-1, tb)
        Dx[.,i] = Dx[.,i] - xreg*_xps_lsq(Dx[.,i], xreg)
    }
}

// ---------- iter_comfac: factors given breaks ----------------------------
// returns idiosyncratic e = cumsum(De) (T-1 x N), fhat cumsum, csi; sets k_temp
void _xps_itercomfac(real matrix x, real matrix mtb, real scalar kmax, real scalar forcenf,
    real matrix e_out, real matrix fhat_out, real matrix csi_out, real scalar k_temp)
{
    real scalar bigt, N, ii, iii, ssr1, ssr2, i, converged
    real colvector CT, sigma, IC1, tb
    real matrix Dx, Dx_iter, xreg, u, s, v, csi, fhat, De
    bigt = rows(x)
    N = cols(x)
    Dx = x[2..bigt,.] - x[1..bigt-1,.]
    Dx_iter = Dx
    ssr1 = (vec(Dx_iter)'vec(Dx_iter))/(bigt*N)
    converged = 0
    k_temp = 0
    De = Dx_iter
    csi = J(N,1,0)
    fhat = J(bigt-1,1,0)
    while (converged==0) {
        for (ii=1; ii<=N; ii++) {
            tb = _xps_mtbrow(mtb, ii)
            xreg = _xps_dummies(bigt-1, tb)
            Dx_iter[.,ii] = (x[2..bigt,ii]-x[1..bigt-1,ii]) - xreg*_xps_lsq(Dx_iter[.,ii], xreg)
        }
        svd(cross(Dx_iter,Dx_iter), u, s, v)
        if (forcenf >= 0) {
            k_temp = forcenf
        }
        else {
            CT = J(kmax,1,0); sigma = J(kmax,1,0); IC1 = J(kmax+1,1,0)
            for (i=1; i<=kmax; i++) {
                CT[i] = ln(N*bigt/(N+bigt))*i*(N+bigt)/(N*bigt)
                csi = sqrt(N)*u[.,1..i]
                fhat = Dx_iter*csi/N
                De = Dx_iter - fhat*csi'
                sigma[i] = mean(colsum(De:*De/bigt)')
                IC1[i+1] = ln(sigma[i]) + CT[i]
            }
            IC1[1] = ln(mean(colsum(Dx_iter:*Dx_iter/bigt)'))
            k_temp = _xps_argmin(IC1) - 1
        }
        if (k_temp == 0) {
            De = Dx_iter
            ssr2 = (vec(De)'vec(De))/(bigt*N)
            if (abs(ssr1-ssr2) > 0.001) {
                ssr1 = ssr2
                Dx_iter = x[2..bigt,.]-x[1..bigt-1,.]
            }
            else converged = 1
        }
        else {
            csi = sqrt(N)*u[.,1..k_temp]
            fhat = Dx_iter*csi/N
            De = Dx_iter - fhat*csi'
            ssr2 = (vec(De)'vec(De))/(bigt*N)
            if (abs(ssr1-ssr2) > 0.001) {
                ssr1 = ssr2
                Dx_iter = (x[2..bigt,.]-x[1..bigt-1,.]) - fhat*csi'
            }
            else converged = 1
        }
    }
    // final extra-projection of De on the break dummies
    for (ii=1; ii<=N; ii++) {
        tb = _xps_mtbrow(mtb, ii)
        xreg = _xps_dummies(bigt-1, tb)
        De[.,ii] = De[.,ii] - xreg*_xps_lsq(De[.,ii], xreg)
    }
    e_out = _xps_cumsum(De)
    if (k_temp == 0) {
        fhat_out = J(bigt-1,1,0)
        csi_out = J(N,1,0)
    }
    else {
        fhat_out = _xps_cumsum(fhat)
        csi_out = csi
    }
}
real colvector _xps_mtbrow(real matrix mtb, real scalar i)
{
    // extract positive break positions (in diff scale) for unit i, minus the +1 offset
    real colvector row, tb
    real scalar j
    row = mtb[i,.]'
    tb = J(0,1,0)
    j = 2
    while (j <= rows(row)) {
        if (row[j] > 0) tb = tb \ (row[j]-1)     // undo the +1 that Bai_Perron98 added
        j = j + 1
    }
    return(tb)
}
real scalar _xps_argmin(real colvector v)
{
    real scalar i, im, mn
    mn = v[1]; im = 1; i = 2
    while (i <= rows(v)) {
        if (v[i] < mn) {
            mn = v[i]; im = i
        }
        i = i + 1
    }
    return(im)
}

// ---------- iter_comfac_est_bks: outer break<->factor iteration ----------
void _xps_estbks(real matrix x, real scalar breaks, real scalar h, real scalar trim,
    real scalar kmax, real scalar forcenf,
    real matrix e_out, real matrix mtb_out, real scalar k_temp)
{
    real scalar bigt, N, count, ssr1, ssr2
    real matrix x_iter, Dx_iter, mtb, e, fhat, csi, De
    bigt = rows(x)
    N = cols(x)
    x_iter = x
    Dx_iter = x[2..bigt,.]-x[1..bigt-1,.]
    ssr1 = (vec(Dx_iter)'vec(Dx_iter))/(bigt*N)
    count = 0
    while (count < 10) {
        count = count + 1
        _xps_baiperron(x_iter, breaks, h, trim, Dx_iter, mtb)
        _xps_itercomfac(x, mtb, kmax, forcenf, e, fhat, csi, k_temp)
        De = e[2..rows(e),.] - e[1..rows(e)-1,.]
        ssr2 = (vec(De)'vec(De))/(bigt*N)
        if (rows(fhat) > 1) {
            if (abs(ssr1-ssr2) > 0.001) {
                ssr1 = ssr2
                x_iter = x - (J(1,cols(fhat),0)\fhat)*csi'
            }
            else count = 100
        }
        else {
            if (abs(ssr1-ssr2) > 0.001) {
                ssr1 = ssr2
                x_iter = x
            }
            else count = 100
        }
    }
    if (rows(fhat) > 1) x_iter = x - (J(1,cols(fhat),0)\fhat)*csi'
    else x_iter = x
    _xps_baiperron(x_iter, breaks, h, trim, Dx_iter, mtb)
    e_out = e
    mtb_out = mtb
}

// ---------- long-run variance (prewhitened) ------------------------------
real scalar _xps_lrvar(real colvector y, real scalar p, real scalar oT)
{
    real scalar t, s2, s2w, ii
    real colvector dep, difer, beta, err
    real matrix z, x
    t = rows(y)
    z = y[(p+2)..t], y[(p+1)..(t-1)]
    if (p > 0) {
        difer = y[(p+1)..(t-1)] - y[p..(t-2)]
        ii = 2
        while (ii <= p) {
            difer = difer, (y[(p+2-ii)..(t-ii)] - y[(p+1-ii)..(t-ii-1)])
            ii = ii + 1
        }
        z = z, difer
        x = z[.,2..cols(z)]
    }
    else x = z[.,2]
    dep = z[.,1] - z[.,2]
    beta = qrsolve(x, dep)
    err = dep - x*beta
    s2 = (err'err)/(oT - cols(x))
    if (p > 0) s2w = s2/(1 - sum(beta[2..rows(beta)]))^2
    else s2w = (y[2..t]-y[1..t-1])'(y[2..t]-y[1..t-1])/oT
    return(s2w)
}

// ---------- logistic p-value coefficients (model=4, k>0) -----------------
real colvector _xps_param(real scalar m)
{
    if (m==1) return((22.20065\4.289649\-32.50563\155.6752\-145.4165\478.8142\0\-561.1564\3010.034\-2926.62\-8402.306\617.0136\4396.556\-31185.25\34616.91))
    if (m==2) return((17.97336\4.689319\-53.14943\218.9461\-185.5172\653.26\0\-905.9285\4584.611\-4332.302\-3025.287\241.4993\0\-5763.431\8547.036))
    if (m==3) return((16.60412\5.013528\-83.4425\316.5897\-252.8456\786.3703\0\-1339.661\6335.15\-5784.559\-20125.9\618.2094\18041.08\-105286.4\106750.4))
    if (m==4) return((0\5.405235\-98.86701\323.0012\-228.4775\1309.162\0\-2449.211\11251.42\-10115.76\-19033.41\419.0541\20272.5\-111718.1\110064.4))
    return((17.24524\5.304317\-168.3526\582.9689\-436.8904\866.4131\0\-1749.514\7792.967\-6914.606\-7440.335\310.2156\0\-17569.33\24695.21))
}
real scalar _xps_pval(real scalar q, real scalar cvT, real scalar m)
{
    real colvector param
    real rowvector xr
    real scalar lin
    param = _xps_param(m)
    xr = (1, q, q^(-1/2), q^(-1/3), q^(-1/4),
          1/cvT, q/cvT, q^(-1/2)/cvT, q^(-1/3)/cvT, q^(-1/4)/cvT,
          1/cvT^2, q/cvT^2, q^(-1/2)/cvT^2, q^(-1/3)/cvT^2, q^(-1/4)/cvT^2)
    lin = (xr*param)[1,1]
    return(exp(lin)/(1+exp(lin)))
}

// ---------- driver -------------------------------------------------------
void _xps_run(string scalar vname, string scalar touse, real scalar N,
    real scalar T, real scalar model, real scalar breaks, real scalar kmax,
    real scalar pbar, real scalar trim, real scalar forcenf, real scalar tmin,
    string scalar outname, string scalar statname)
{
    real matrix Y, e, mtb, out
    real colvector v, tb, msb, msbsim, pv, ei, tmp, tmpe, seg
    real scalar h, k_temp, i, j, s2w, oT, Tm1, Pchi, Pnorm, cvT, q, nreg
    v = st_data(., vname, touse)
    Y = colshape(v, T)'
    h = trunc(trim*T)
    _xps_estbks(Y, breaks, h, trim, kmax, forcenf, e, mtb, k_temp)
    oT = T
    Tm1 = rows(e)          // T-1
    msb = J(N,1,0)
    msbsim = J(N,1,0)
    pv = J(N,1,0)
    for (i=1; i<=N; i++) {
        ei = e[.,i]
        s2w = _xps_lrvar(ei, pbar, oT)
        msb[i] = (oT^(-2))*(ei[1..Tm1]'ei[1..Tm1])/s2w
        // simplified (regime-partitioned) MSB
        tb = _xps_mtbrowplus(mtb, i)     // break positions (diff scale, +1 as stored)
        tmp = 0 \ tb \ (T-1)
        tmpe = J(rows(tmp)-1,1,0)
        for (j=1; j<=rows(tmp)-1; j++) {
            seg = ei[(tmp[j]+1)..tmp[j+1]]
            tmpe[j] = (rows(seg)^(-2))*(seg'seg)
        }
        msbsim[i] = sum(tmpe)/s2w
        // deterministic logistic p-value on the simplified statistic
        cvT = T/breaks
        pv[i] = _xps_pval(msbsim[i], cvT, breaks)
    }
    Pchi = -2*sum(ln(pv))
    Pnorm = (Pchi - 2*N)/sqrt(4*N)
    out = (1::N), msb, pv, (tmin :+ mtb[.,2] :- 1), (tmin :+ mtb[.,3] :- 1), J(N,1,pbar)
    st_matrix(outname, out)
    st_matrixcolstripe(outname, (J(6,1,""), ("id","MSB","pval","break1","break2","lag")'))
    st_matrix(statname, (Pchi, Pnorm, k_temp, chi2tail(2*N,Pchi), 1-normal(Pnorm)))
}
// break positions for unit i as stored in mtb (already +1 offset, diff scale)
real colvector _xps_mtbrowplus(real matrix mtb, real scalar i)
{
    real colvector row, tb
    real scalar j
    row = mtb[i,.]'
    tb = J(0,1,0)
    j = 2
    while (j <= rows(row)) {
        if (row[j] > 0) tb = tb \ row[j]
        j = j + 1
    }
    return(tb)
}

end
