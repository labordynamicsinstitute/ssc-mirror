*! maki v3.5.0  25jun2026
*! Maki (2012) Cointegration Test with Multiple Structural Breaks
*! Stata-Mata port by H. Ozan Eruygur, Professor of Economics
*! AHBV University, Department of Economics, Ankara, Turkiye (eruygur@gmail.com)
*! Line-by-line Stata-Mata port of the GAUSS coint_maki procedures (tspdlib)
*! Original GAUSS: D. Maki (email 06oct2019), modified J. Jones (Aptech)
*! Supports m=1..5 breaks, models 0-3, full GAUSS branch logic

mata:


real scalar mk_minidx(real vector v)
{
    real scalar i, mi, mv
    mi = 1
    mv = v[1]
    i = 2
    while (i <= rows(v)) {
        if (v[i] < mv) {
            mv = v[i]
            mi = i
        }
        i = i + 1
    }
    return(mi)
}

void dftau(real vector dy, real matrix x, real scalar tau, real scalar s2)
{
    real scalar n1, k, s2hat
    real vector b, e, se
    real matrix xtxi
    n1 = rows(x)
    k = cols(x)
    xtxi = invsym(cross(x, x))
    b = xtxi * cross(x, dy)
    e = dy - x * b
    s2 = cross(e, e)
    s2hat = cross(e, e) / (n1 - k)
    se = sqrt(diagonal(s2hat * xtxi))
    tau = b[1] / se[1]
}

real scalar opttlag(real vector e, real scalar maxlag)
{
    real scalar p, n, n1, k, s2hat, taut, i, j
    real vector dy, ly, b, e2, se
    real matrix x, xtxi
    p = maxlag
    while (p >= 1) {
        n = rows(e)
        dy = e[2..n] - e[1..n-1]
        i = 1
        j = 2 + p
        x = e[j-1..n-1]
        while (i <= p) {
            x = x, dy[j-1-i..n-1-i]
            i = i + 1
        }
        n1 = rows(x)
        k = cols(x)
        ly = dy[j-1..n-1]
        xtxi = invsym(cross(x, x))
        b = xtxi * cross(x, ly)
        e2 = ly - x * b
        s2hat = cross(e2, e2) / (n1 - k)
        se = sqrt(diagonal(s2hat * xtxi))
        taut = b[p+1] / se[p+1]
        if (abs(taut) > 1.654) {
            return(p)
        }
        p = p - 1
    }
    return(0)
}

real scalar bg_minp(real vector u, real matrix xadf, real scalar pmax)
{
    real scalar n, p, j, r2, lm, pv, minp, ssr, tss
    real vector b, res
    real matrix L, Z
    n = rows(u)
    minp = 1
    p = 1
    while (p <= pmax) {
        L = J(n, p, 0)
        j = 1
        while (j <= p) {
            if (n - j >= 1) {
                L[(j+1)..n, j] = u[1..(n-j)]
            }
            j = j + 1
        }
        Z = xadf, L
        b = invsym(cross(Z, Z)) * cross(Z, u)
        res = u - Z * b
        ssr = cross(res, res)
        tss = cross(u, u)
        r2 = 1 - ssr / tss
        lm = n * r2
        pv = 1 - chi2(p, lm)
        if (pv < minp) {
            minp = pv
        }
        p = p + 1
    }
    return(minp)
}

real scalar bglag(real vector e, real scalar bgmaxp, real scalar maxlag)
{
    real scalar lag, kprev, n, q, r, minp, ksel, found, minp_top, minp_sel
    real vector dy, ly, u, b
    real matrix x
    pointer(real scalar) scalar pwarn
    ksel = 0
    kprev = maxlag
    found = 0
    minp_top = 1
    minp_sel = 1
    lag = maxlag
    while (lag >= 0) {
        if (found == 0) {
            n = rows(e)
            dy = e[2..n] - e[1..n-1]
            r = 2 + lag
            x = e[r-1..n-1]
            q = 1
            while (q <= lag) {
                x = x, dy[r-1-q..n-1-q]
                q = q + 1
            }
            ly = dy[r-1..n-1]
            b = invsym(cross(x, x)) * cross(x, ly)
            u = ly - x * b
            minp = bg_minp(u, x, bgmaxp)
            if (lag == maxlag) {
                minp_top = minp
                minp_sel = minp
            }
            if (minp < 0.05) {
                ksel = kprev
                found = 1
            }
            else {
                kprev = lag
                minp_sel = minp
            }
        }
        lag = lag - 1
    }
    if (found == 0) {
        ksel = 0
    }
    pwarn = findexternal("mk_bgfound")
    if (pwarn == NULL) {
        pwarn = crexternal("mk_bgfound")
    }
    *pwarn = found
    pwarn = findexternal("mk_bgminptop")
    if (pwarn == NULL) {
        pwarn = crexternal("mk_bgminptop")
    }
    *pwarn = minp_top
    pwarn = findexternal("mk_bgminpsel")
    if (pwarn == NULL) {
        pwarn = crexternal("mk_bgminpsel")
    }
    *pwarn = minp_sel
    return(ksel)
}

void adf_block(real vector e, real scalar lagoption, real scalar tau, real scalar s2)
{
    real scalar n, lag, q, r, bgmaxp, maxlag
    real vector dy
    real matrix x
    pointer(real scalar) scalar pbg, pbest, pbtau, pml, pwarn_w, pfound, pmptop, pwin
    real scalar minp_win
    real vector dyw, lyw, uw, bw
    real matrix xw
    n = rows(e)
    pbg = findexternal("mk_bgmaxp")
    if (pbg == NULL) {
        bgmaxp = 2
    }
    else {
        bgmaxp = *pbg
    }
    pml = findexternal("mk_maxlag")
    if (pml == NULL) {
        maxlag = 12
    }
    else {
        maxlag = *pml
    }
    if (lagoption == 0) {
        lag = 0
    }
    else if (lagoption == 3) {
        lag = maxlag
    }
    else if (lagoption == 2) {
        lag = bglag(e, bgmaxp, maxlag)
    }
    else {
        lag = opttlag(e, maxlag)
    }
    dy = e[2..n] - e[1..n-1]
    q = 1
    r = 2 + lag
    x = e[r-1..n-1]
    while (q <= lag) {
        x = x, dy[r-1-q..n-1-q]
        q = q + 1
    }
    dftau(dy[r-1..n-1], x, tau, s2)
    pbtau = findexternal("mk_besttau")
    pbest = findexternal("mk_bestlag")
    if (pbtau != NULL & pbest != NULL) {
        if (tau < *pbtau) {
            *pbtau = tau
            *pbest = lag
            dyw = e[2..n] - e[1..n-1]
            r = 2 + lag
            xw = e[r-1..n-1]
            q = 1
            while (q <= lag) {
                xw = xw, dyw[r-1-q..n-1-q]
                q = q + 1
            }
            lyw = dyw[r-1..n-1]
            bw = invsym(cross(xw, xw)) * cross(xw, lyw)
            uw = lyw - xw * bw
            minp_win = bg_minp(uw, xw, bgmaxp)
            pwin = findexternal("mk_bgminp_win")
            if (pwin == NULL) {
                pwin = crexternal("mk_bgminp_win")
            }
            *pwin = minp_win
            if (lagoption == 2) {
                pwarn_w = findexternal("mk_bgwarn")
                pfound = findexternal("mk_bgfound")
                pmptop = findexternal("mk_bgminptop")
                if (pwarn_w != NULL & pfound != NULL & pmptop != NULL) {
                    if (*pfound == 0 | *pmptop < 0.05) {
                        *pwarn_w = 1
                    }
                    else {
                        *pwarn_w = 0
                    }
                }
            }
        }
    }
}

real vector mk_resid(real vector y, real matrix x)
{
    real vector b
    b = invsym(cross(x, x)) * cross(x, y)
    return(y - x * b)
}

real scalar mbreak1(real matrix datap, real scalar n, real scalar model, real scalar tb, real scalar lagoption, real scalar bp1)
{
    real scalar i, k, tau, s2, mintau1
    real vector y, u, du, e, vectau, vecbp, tr, dtr
    real matrix x, cons, dx
    y = datap[., 1]
    k = cols(datap)
    i = tb + 1
    vectau = J(n, 1, 0)
    vecbp = J(n, 1, 0)
    while (i <= n - tb) {
        u = J(n, 1, 1)
        du = (J(i, 1, 0) \ J(n - i, 1, 1))
        if (model == 0) {
            cons = u, du
            x = cons, datap[., 2..k]
        }
        else if (model == 1) {
            cons = u, du
            x = cons, (1::n), datap[., 2..k]
        }
        else if (model == 2) {
            cons = u, du
            dx = (J(i, k-1, 0) \ datap[i+1..n, 2..k])
            x = cons, datap[., 2..k], dx
        }
        else {
            tr = (1::n)
            dtr = (J(i, 1, 0) \ (i+1::n))
            cons = u, du, tr, dtr
            dx = (J(i, k-1, 0) \ datap[i+1..n, 2..k])
            x = cons, datap[., 2..k], dx
        }
        e = mk_resid(y, x)
        adf_block(e, lagoption, tau, s2)
        vectau[i] = tau
        vecbp[i] = s2
        i = i + 1
    }
    mintau1 = min(vectau[tb+1..n-tb])
    bp1 = tb + mk_minidx(vecbp[tb+1..n-tb])
    return(mintau1)
}

real scalar mbreak21(real matrix datap, real scalar n, real scalar model, real scalar tb, real scalar bp1, real scalar lagoption, real scalar bp21)
{
    real scalar i, k, tau, s2, tau1
    real vector y, u, du1, du2, e, vectau, vecbp, tr, dtr1, dtr2
    real matrix x, cons, dx1, dx2
    y = datap[., 1]
    k = cols(datap)
    u = J(n, 1, 1)
    du1 = (J(bp1, 1, 0) \ J(n - bp1, 1, 1))
    dx1 = (J(bp1, k-1, 0) \ datap[bp1+1..n, 2..k])
    dtr1 = (J(bp1, 1, 0) \ (bp1+1::n))
    i = tb + 1
    vectau = J(n, 1, 0)
    vecbp = J(n, 1, 0)
    while (i <= bp1 - tb) {
        du2 = (J(i, 1, 0) \ J(n - i, 1, 1))
        if (model == 0) {
            cons = u, du1, du2
            x = cons, datap[., 2..k]
        }
        else if (model == 1) {
            cons = u, du1, du2
            x = cons, (1::n), datap[., 2..k]
        }
        else if (model == 2) {
            cons = u, du1, du2
            dx2 = (J(i, k-1, 0) \ datap[i+1..n, 2..k])
            x = cons, datap[., 2..k], dx1, dx2
        }
        else {
            tr = (1::n)
            dtr2 = (J(i, 1, 0) \ (i+1::n))
            cons = u, du1, du2, tr, dtr1, dtr2
            dx2 = (J(i, k-1, 0) \ datap[i+1..n, 2..k])
            x = cons, datap[., 2..k], dx1, dx2
        }
        e = mk_resid(y, x)
        adf_block(e, lagoption, tau, s2)
        vectau[i] = tau
        vecbp[i] = s2
        i = i + 1
    }
    tau1 = min(vectau[tb+1..bp1-tb])
    bp21 = tb + mk_minidx(vecbp[tb+1..bp1-tb])
    return(tau1)
}

real scalar mbreak22(real matrix datap, real scalar n, real scalar model, real scalar tb, real scalar bp1, real scalar lagoption, real scalar bp22)
{
    real scalar i, k, tau, s2, tau2
    real vector y, u, du1, du2, e, vectau, vecbp, tr, dtr1, dtr2
    real matrix x, cons, dx1, dx2
    y = datap[., 1]
    k = cols(datap)
    u = J(n, 1, 1)
    du1 = (J(bp1, 1, 0) \ J(n - bp1, 1, 1))
    dx1 = (J(bp1, k-1, 0) \ datap[bp1+1..n, 2..k])
    dtr1 = (J(bp1, 1, 0) \ (bp1+1::n))
    i = bp1 + tb + 1
    vectau = J(n, 1, 0)
    vecbp = J(n, 1, 0)
    while (i <= n - tb) {
        du2 = (J(i, 1, 0) \ J(n - i, 1, 1))
        if (model == 0) {
            cons = u, du1, du2
            x = cons, datap[., 2..k]
        }
        else if (model == 1) {
            cons = u, du1, du2
            x = cons, (1::n), datap[., 2..k]
        }
        else if (model == 2) {
            cons = u, du1, du2
            dx2 = (J(i, k-1, 0) \ datap[i+1..n, 2..k])
            x = cons, datap[., 2..k], dx1, dx2
        }
        else {
            tr = (1::n)
            dtr2 = (J(i, 1, 0) \ (i+1::n))
            cons = u, du1, du2, tr, dtr1, dtr2
            dx2 = (J(i, k-1, 0) \ datap[i+1..n, 2..k])
            x = cons, datap[., 2..k], dx1, dx2
        }
        e = mk_resid(y, x)
        adf_block(e, lagoption, tau, s2)
        vectau[i] = tau
        vecbp[i] = s2
        i = i + 1
    }
    tau2 = min(vectau[bp1+tb+1..n-tb])
    bp22 = bp1 + tb + mk_minidx(vecbp[bp1+tb+1..n-tb])
    return(tau2)
}

real scalar mbreak2(real matrix datap, real scalar n, real scalar model, real scalar tb, real scalar bp1, real scalar lagoption, real scalar bp2)
{
    real scalar mintau2, tau1, tau2, bp21, bp22
    real vector tt, bb
    if (bp1 <= 0.1 * n) {
        tau2 = mbreak22(datap, n, model, tb, bp1, lagoption, bp22)
        mintau2 = tau2
        bp2 = bp22
    }
    else if (bp1 >= 0.9 * n) {
        tau1 = mbreak21(datap, n, model, tb, bp1, lagoption, bp21)
        mintau2 = tau1
        bp2 = bp21
    }
    else {
        tau1 = mbreak21(datap, n, model, tb, bp1, lagoption, bp21)
        tau2 = mbreak22(datap, n, model, tb, bp1, lagoption, bp22)
        tt = (tau1 \ tau2)
        bb = (bp21 \ bp22)
        mintau2 = min(tt)
        bp2 = bb[mk_minidx(tt)]
    }
    return(mintau2)
}

real scalar mbreak31(real matrix datap, real scalar n, real scalar model, real scalar tb, real scalar bp1, real scalar bp2, real scalar lagoption, real scalar bp31)
{
    real scalar i, k, tau, s2, tau1
    real vector y, u, du1, du2, du3, e, vectau, vecbp, tr, dtr1, dtr2, dtr3
    real matrix x, cons, dx1, dx2, dx3
    y = datap[., 1]
    k = cols(datap)
    u = J(n, 1, 1)
    du1 = (J(bp1, 1, 0) \ J(n - bp1, 1, 1))
    du2 = (J(bp2, 1, 0) \ J(n - bp2, 1, 1))
    dx1 = (J(bp1, k-1, 0) \ datap[bp1+1..n, 2..k])
    dx2 = (J(bp2, k-1, 0) \ datap[bp2+1..n, 2..k])
    dtr1 = (J(bp1, 1, 0) \ (bp1+1::n))
    dtr2 = (J(bp2, 1, 0) \ (bp2+1::n))
    i = tb + 1
    vectau = J(n, 1, 0)
    vecbp = J(n, 1, 0)
    while (i <= bp1 - tb) {
        du3 = (J(i, 1, 0) \ J(n - i, 1, 1))
        if (model == 0) {
            cons = u, du1, du2, du3
            x = cons, datap[., 2..k]
        }
        else if (model == 1) {
            cons = u, du1, du2, du3
            x = cons, (1::n), datap[., 2..k]
        }
        else if (model == 2) {
            cons = u, du1, du2, du3
            dx3 = (J(i, k-1, 0) \ datap[i+1..n, 2..k])
            x = cons, datap[., 2..k], dx1, dx2, dx3
        }
        else {
            tr = (1::n)
            dtr3 = (J(i, 1, 0) \ (i+1::n))
            cons = u, du1, du2, du3, tr, dtr1, dtr2, dtr3
            dx3 = (J(i, k-1, 0) \ datap[i+1..n, 2..k])
            x = cons, datap[., 2..k], dx1, dx2, dx3
        }
        e = mk_resid(y, x)
        adf_block(e, lagoption, tau, s2)
        vectau[i] = tau
        vecbp[i] = s2
        i = i + 1
    }
    tau1 = min(vectau[tb+1..bp1-tb])
    bp31 = tb + mk_minidx(vecbp[tb+1..bp1-tb])
    return(tau1)
}

real scalar mbreak32(real matrix datap, real scalar n, real scalar model, real scalar tb, real scalar bp1, real scalar bp2, real scalar lagoption, real scalar bp32)
{
    real scalar i, k, tau, s2, tau2
    real vector y, u, du1, du2, du3, e, vectau, vecbp, tr, dtr1, dtr2, dtr3
    real matrix x, cons, dx1, dx2, dx3
    y = datap[., 1]
    k = cols(datap)
    u = J(n, 1, 1)
    du1 = (J(bp1, 1, 0) \ J(n - bp1, 1, 1))
    du2 = (J(bp2, 1, 0) \ J(n - bp2, 1, 1))
    dx1 = (J(bp1, k-1, 0) \ datap[bp1+1..n, 2..k])
    dx2 = (J(bp2, k-1, 0) \ datap[bp2+1..n, 2..k])
    dtr1 = (J(bp1, 1, 0) \ (bp1+1::n))
    dtr2 = (J(bp2, 1, 0) \ (bp2+1::n))
    i = bp1 + tb + 1
    vectau = J(n, 1, 0)
    vecbp = J(n, 1, 0)
    while (i <= bp2 - tb) {
        du3 = (J(i, 1, 0) \ J(n - i, 1, 1))
        if (model == 0) {
            cons = u, du1, du2, du3
            x = cons, datap[., 2..k]
        }
        else if (model == 1) {
            cons = u, du1, du2, du3
            x = cons, (1::n), datap[., 2..k]
        }
        else if (model == 2) {
            cons = u, du1, du2, du3
            dx3 = (J(i, k-1, 0) \ datap[i+1..n, 2..k])
            x = cons, datap[., 2..k], dx1, dx2, dx3
        }
        else {
            tr = (1::n)
            dtr3 = (J(i, 1, 0) \ (i+1::n))
            cons = u, du1, du2, du3, tr, dtr1, dtr2, dtr3
            dx3 = (J(i, k-1, 0) \ datap[i+1..n, 2..k])
            x = cons, datap[., 2..k], dx1, dx2, dx3
        }
        e = mk_resid(y, x)
        adf_block(e, lagoption, tau, s2)
        vectau[i] = tau
        vecbp[i] = s2
        i = i + 1
    }
    tau2 = min(vectau[bp1+tb+1..bp2-tb])
    bp32 = bp1 + tb + mk_minidx(vecbp[bp1+tb+1..bp2-tb])
    return(tau2)
}

real scalar mbreak33(real matrix datap, real scalar n, real scalar model, real scalar tb, real scalar bp1, real scalar bp2, real scalar lagoption, real scalar bp33)
{
    real scalar i, k, tau, s2, tau3
    real vector y, u, du1, du2, du3, e, vectau, vecbp, tr, dtr1, dtr2, dtr3
    real matrix x, cons, dx1, dx2, dx3
    y = datap[., 1]
    k = cols(datap)
    u = J(n, 1, 1)
    du1 = (J(bp1, 1, 0) \ J(n - bp1, 1, 1))
    du2 = (J(bp2, 1, 0) \ J(n - bp2, 1, 1))
    dx1 = (J(bp1, k-1, 0) \ datap[bp1+1..n, 2..k])
    dx2 = (J(bp2, k-1, 0) \ datap[bp2+1..n, 2..k])
    dtr1 = (J(bp1, 1, 0) \ (bp1+1::n))
    dtr2 = (J(bp2, 1, 0) \ (bp2+1::n))
    i = bp2 + tb + 1
    vectau = J(n, 1, 0)
    vecbp = J(n, 1, 0)
    while (i <= n - tb) {
        du3 = (J(i, 1, 0) \ J(n - i, 1, 1))
        if (model == 0) {
            cons = u, du1, du2, du3
            x = cons, datap[., 2..k]
        }
        else if (model == 1) {
            cons = u, du1, du2, du3
            x = cons, (1::n), datap[., 2..k]
        }
        else if (model == 2) {
            cons = u, du1, du2, du3
            dx3 = (J(i, k-1, 0) \ datap[i+1..n, 2..k])
            x = cons, datap[., 2..k], dx1, dx2, dx3
        }
        else {
            tr = (1::n)
            dtr3 = (J(i, 1, 0) \ (i+1::n))
            cons = u, du1, du2, du3, tr, dtr1, dtr2, dtr3
            dx3 = (J(i, k-1, 0) \ datap[i+1..n, 2..k])
            x = cons, datap[., 2..k], dx1, dx2, dx3
        }
        e = mk_resid(y, x)
        adf_block(e, lagoption, tau, s2)
        vectau[i] = tau
        vecbp[i] = s2
        i = i + 1
    }
    tau3 = min(vectau[bp2+tb+1..n-tb])
    bp33 = bp2 + tb + mk_minidx(vecbp[bp2+tb+1..n-tb])
    return(tau3)
}

real scalar mbreak3(real matrix datap, real scalar n, real scalar model, real scalar tb, real vector bpin, real scalar lagoption, real scalar bp3)
{
    real scalar bp1, bp2, mintau3, tau1, tau2, tau3, bp31, bp32, bp33
    real vector tt, bb
    bp1 = bpin[1]
    bp2 = bpin[2]
    if (bp2 - bp1 > round(0.1*n) & bp2 <= round(0.9*n)) {
        if (bp1 <= 0.1*n) {
            tau2 = mbreak32(datap, n, model, tb, bp1, bp2, lagoption, bp32)
            tau3 = mbreak33(datap, n, model, tb, bp1, bp2, lagoption, bp33)
            tt = (tau2 \ tau3)
            bb = (bp32 \ bp33)
            mintau3 = min(tt)
            bp3 = bb[mk_minidx(tt)]
        }
        else {
            tau1 = mbreak31(datap, n, model, tb, bp1, bp2, lagoption, bp31)
            tau2 = mbreak32(datap, n, model, tb, bp1, bp2, lagoption, bp32)
            tau3 = mbreak33(datap, n, model, tb, bp1, bp2, lagoption, bp33)
            tt = (tau1 \ tau2 \ tau3)
            bb = (bp31 \ bp32 \ bp33)
            mintau3 = min(tt)
            bp3 = bb[mk_minidx(tt)]
        }
    }
    else if (bp2 - bp1 > 0.1*n & bp2 >= 0.9*n) {
        if (bp1 <= 0.1*n) {
            tau2 = mbreak32(datap, n, model, tb, bp1, bp2, lagoption, bp32)
            mintau3 = tau2
            bp3 = bp32
        }
        else {
            tau1 = mbreak31(datap, n, model, tb, bp1, bp2, lagoption, bp31)
            tau2 = mbreak32(datap, n, model, tb, bp1, bp2, lagoption, bp32)
            tt = (tau1 \ tau2)
            bb = (bp31 \ bp32)
            mintau3 = min(tt)
            bp3 = bb[mk_minidx(tt)]
        }
    }
    else if (bp2 - bp1 <= 0.1*n) {
        if (bp1 <= 0.1*n) {
            tau3 = mbreak33(datap, n, model, tb, bp1, bp2, lagoption, bp33)
            mintau3 = tau3
            bp3 = bp33
        }
        else if (bp2 >= round(0.9*n)) {
            tau1 = mbreak31(datap, n, model, tb, bp1, bp2, lagoption, bp31)
            mintau3 = tau1
            bp3 = bp31
        }
        else {
            tau1 = mbreak31(datap, n, model, tb, bp1, bp2, lagoption, bp31)
            tau3 = mbreak33(datap, n, model, tb, bp1, bp2, lagoption, bp33)
            tt = (tau1 \ tau3)
            bb = (bp31 \ bp33)
            mintau3 = min(tt)
            bp3 = bb[mk_minidx(tt)]
        }
    }
    else {
        mintau3 = 0
        bp3 = 0
    }
    return(mintau3)
}

real rowvector cv_coint_maki(real scalar k, real scalar m, real scalar model)
{
    real matrix cm
    cm = J(5, 3, 0)
    if (model == 0) {
        if (k == 1) cm = (-5.709,-4.602,-4.354 \ -5.416,-4.892,-4.610 \ -5.563,-5.083,-4.784 \ -5.776,-5.230,-4.982 \ -5.959,-5.426,-5.131)
        else if (k == 2) cm = (-5.541,-5.004,-4.733 \ -5.717,-5.211,-4.957 \ -5.943,-5.392,-5.125 \ -6.075,-5.550,-5.297 \ -6.296,-5.760,-5.491)
        else if (k == 3) cm = (-5.820,-5.341,-5.101 \ -5.984,-5.517,-5.272 \ -6.229,-5.704,-5.427 \ -6.406,-5.871,-5.603 \ -6.555,-6.038,-5.773)
        else cm = (-6.139,-5.650,-5.386 \ -6.303,-5.839,-5.575 \ -6.501,-5.992,-5.714 \ -6.640,-6.132,-5.892 \ -6.856,-6.306,-6.039)
    }
    else if (model == 1) {
        if (k == 1) cm = (-5.524,-5.038,-4.784 \ -5.708,-5.196,-4.938 \ -5.833,-5.373,-5.106 \ -6.059,-5.508,-5.245 \ -6.193,-5.699,-5.449)
        else if (k == 2) cm = (-5.840,-5.359,-5.117 \ -6.011,-5.518,-5.247 \ -6.169,-5.691,-5.408 \ -6.329,-5.831,-5.558 \ -6.530,-5.993,-5.722)
        else if (k == 3) cm = (-6.144,-5.645,-5.398 \ -6.271,-5.796,-5.538 \ -6.472,-5.957,-5.682 \ -6.575,-6.086,-5.820 \ -6.784,-6.250,-5.976)
        else cm = (-6.361,-5.913,-5.686 \ -6.556,-6.055,-5.805 \ -6.741,-6.214,-5.974 \ -6.845,-6.373,-6.096 \ -7.053,-6.494,-6.220)
    }
    else if (model == 2) {
        if (k == 1) cm = (-5.457,-4.895,-4.626 \ -5.863,-5.363,-5.070 \ -6.251,-5.703,-5.402 \ -6.596,-6.011,-5.723 \ -6.915,-6.357,-6.057)
        else if (k == 2) cm = (-6.020,-5.558,-5.287 \ -6.628,-6.093,-5.833 \ -7.031,-6.516,-6.210 \ -7.470,-6.872,-6.563 \ -7.839,-7.288,-6.976)
        else if (k == 3) cm = (-6.565,-6.035,-5.773 \ -7.232,-6.702,-6.411 \ -7.767,-7.155,-6.868 \ -8.236,-7.625,-7.329 \ -8.673,-8.110,-7.796)
        else cm = (-7.021,-6.520,-6.242 \ -7.756,-7.244,-6.964 \ -8.336,-7.803,-7.481 \ -8.895,-8.292,-8.004 \ -9.441,-8.869,-8.541)
    }
    else {
        if (k == 1) cm = (-6.048,-5.541,-5.281 \ -6.620,-6.100,-5.845 \ -7.082,-6.524,-6.267 \ -7.553,-7.009,-6.712 \ -8.004,-7.414,-7.110)
        else if (k == 2) cm = (-6.523,-6.055,-5.795 \ -7.153,-6.657,-6.397 \ -7.673,-7.145,-6.873 \ -8.217,-7.636,-7.341 \ -8.713,-8.129,-7.811)
        else if (k == 3) cm = (-6.964,-6.464,-6.220 \ -7.737,-7.201,-6.926 \ -8.331,-7.743,-7.449 \ -8.851,-8.269,-7.960 \ -9.428,-8.800,-8.508)
        else cm = (-7.400,-6.911,-6.649 \ -8.167,-7.638,-7.381 \ -8.865,-8.254,-7.977 \ -9.433,-8.871,-8.574 \ -10.08,-9.482,-9.151)
    }
    return(cm[m, .])
}

    real scalar mbreak41_(real matrix datap, real scalar n, real scalar model, real scalar tb, real scalar bp1, real scalar bp2, real scalar bp3, real scalar lagoption, real scalar obp)
    {
        real scalar i, k, tau, s2, otau
        real vector y, u, e, vectau, vecbp, tr
        real vector du1, du2, du3, du4, dtr1, dtr2, dtr3, dtr4
        real matrix x, cons, dx1, dx2, dx3, dx4
        y = datap[., 1]
        k = cols(datap)
        du1 = (J(bp1, 1, 0) \ J(n - bp1, 1, 1))
        du2 = (J(bp2, 1, 0) \ J(n - bp2, 1, 1))
        du3 = (J(bp3, 1, 0) \ J(n - bp3, 1, 1))
        dtr1 = (J(bp1, 1, 0) \ (bp1+1::n))
        dtr2 = (J(bp2, 1, 0) \ (bp2+1::n))
        dtr3 = (J(bp3, 1, 0) \ (bp3+1::n))
        i = tb + 1
        vectau = J(n, 1, 0)
        vecbp = J(n, 1, 0)
        while (i <= bp1 - tb) {
            u = J(n, 1, 1)
            du4 = (J(i, 1, 0) \ J(n - i, 1, 1))
            if (model == 0) {
                cons = u, du1, du2, du3, du4
                x = cons, datap[., 2..k]
            }
            else if (model == 1) {
                cons = u, du1, du2, du3, du4
                x = cons, (1::n), datap[., 2..k]
            }
            else if (model == 2) {
                cons = u, du1, du2, du3, du4
                dx1 = (J(bp1, k-1, 0) \ datap[bp1+1..n, 2..k])
                dx2 = (J(bp2, k-1, 0) \ datap[bp2+1..n, 2..k])
                dx3 = (J(bp3, k-1, 0) \ datap[bp3+1..n, 2..k])
                dx4 = (J(i, k-1, 0) \ datap[i+1..n, 2..k])
                x = cons, datap[., 2..k], dx1, dx2, dx3, dx4
            }
            else {
                tr = (1::n)
                dtr1 = (J(bp1, 1, 0) \ (bp1+1::n))
                dtr2 = (J(bp2, 1, 0) \ (bp2+1::n))
                dtr3 = (J(bp3, 1, 0) \ (bp3+1::n))
                dtr4 = (J(i, 1, 0) \ (i+1::n))
                cons = u, du1, du2, du3, du4, tr, dtr1, dtr2, dtr3, dtr4
                dx1 = (J(bp1, k-1, 0) \ datap[bp1+1..n, 2..k])
                dx2 = (J(bp2, k-1, 0) \ datap[bp2+1..n, 2..k])
                dx3 = (J(bp3, k-1, 0) \ datap[bp3+1..n, 2..k])
                dx4 = (J(i, k-1, 0) \ datap[i+1..n, 2..k])
                x = cons, datap[., 2..k], dx1, dx2, dx3, dx4
            }
            e = mk_resid(y, x)
            adf_block(e, lagoption, tau, s2)
            vectau[i] = tau
            vecbp[i] = s2
            i = i + 1
        }
        otau = min(vectau[tb+1..bp1-tb])
        obp = tb + mk_minidx(vecbp[tb+1..bp1-tb])
        return(otau)
    }

    real scalar mbreak42_(real matrix datap, real scalar n, real scalar model, real scalar tb, real scalar bp1, real scalar bp2, real scalar bp3, real scalar lagoption, real scalar obp)
    {
        real scalar i, k, tau, s2, otau
        real vector y, u, e, vectau, vecbp, tr
        real vector du1, du2, du3, du4, dtr1, dtr2, dtr3, dtr4
        real matrix x, cons, dx1, dx2, dx3, dx4
        y = datap[., 1]
        k = cols(datap)
        du1 = (J(bp1, 1, 0) \ J(n - bp1, 1, 1))
        du2 = (J(bp2, 1, 0) \ J(n - bp2, 1, 1))
        du3 = (J(bp3, 1, 0) \ J(n - bp3, 1, 1))
        dtr1 = (J(bp1, 1, 0) \ (bp1+1::n))
        dtr2 = (J(bp2, 1, 0) \ (bp2+1::n))
        dtr3 = (J(bp3, 1, 0) \ (bp3+1::n))
        i = bp1 + tb + 1
        vectau = J(n, 1, 0)
        vecbp = J(n, 1, 0)
        while (i <= bp2 - tb) {
            u = J(n, 1, 1)
            du4 = (J(i, 1, 0) \ J(n - i, 1, 1))
            if (model == 0) {
                cons = u, du1, du2, du3, du4
                x = cons, datap[., 2..k]
            }
            else if (model == 1) {
                cons = u, du1, du2, du3, du4
                x = cons, (1::n), datap[., 2..k]
            }
            else if (model == 2) {
                cons = u, du1, du2, du3, du4
                dx1 = (J(bp1, k-1, 0) \ datap[bp1+1..n, 2..k])
                dx2 = (J(bp2, k-1, 0) \ datap[bp2+1..n, 2..k])
                dx3 = (J(bp3, k-1, 0) \ datap[bp3+1..n, 2..k])
                dx4 = (J(i, k-1, 0) \ datap[i+1..n, 2..k])
                x = cons, datap[., 2..k], dx1, dx2, dx3, dx4
            }
            else {
                tr = (1::n)
                dtr1 = (J(bp1, 1, 0) \ (bp1+1::n))
                dtr2 = (J(bp2, 1, 0) \ (bp2+1::n))
                dtr3 = (J(bp3, 1, 0) \ (bp3+1::n))
                dtr4 = (J(i, 1, 0) \ (i+1::n))
                cons = u, du1, du2, du3, du4, tr, dtr1, dtr2, dtr3, dtr4
                dx1 = (J(bp1, k-1, 0) \ datap[bp1+1..n, 2..k])
                dx2 = (J(bp2, k-1, 0) \ datap[bp2+1..n, 2..k])
                dx3 = (J(bp3, k-1, 0) \ datap[bp3+1..n, 2..k])
                dx4 = (J(i, k-1, 0) \ datap[i+1..n, 2..k])
                x = cons, datap[., 2..k], dx1, dx2, dx3, dx4
            }
            e = mk_resid(y, x)
            adf_block(e, lagoption, tau, s2)
            vectau[i] = tau
            vecbp[i] = s2
            i = i + 1
        }
        otau = min(vectau[bp1+tb+1..bp2-tb])
        obp = bp1 + tb + mk_minidx(vecbp[bp1+tb+1..bp2-tb])
        return(otau)
    }

    real scalar mbreak43_(real matrix datap, real scalar n, real scalar model, real scalar tb, real scalar bp1, real scalar bp2, real scalar bp3, real scalar lagoption, real scalar obp)
    {
        real scalar i, k, tau, s2, otau
        real vector y, u, e, vectau, vecbp, tr
        real vector du1, du2, du3, du4, dtr1, dtr2, dtr3, dtr4
        real matrix x, cons, dx1, dx2, dx3, dx4
        y = datap[., 1]
        k = cols(datap)
        du1 = (J(bp1, 1, 0) \ J(n - bp1, 1, 1))
        du2 = (J(bp2, 1, 0) \ J(n - bp2, 1, 1))
        du3 = (J(bp3, 1, 0) \ J(n - bp3, 1, 1))
        dtr1 = (J(bp1, 1, 0) \ (bp1+1::n))
        dtr2 = (J(bp2, 1, 0) \ (bp2+1::n))
        dtr3 = (J(bp3, 1, 0) \ (bp3+1::n))
        i = bp2 + tb + 1
        vectau = J(n, 1, 0)
        vecbp = J(n, 1, 0)
        while (i <= bp3 - tb) {
            u = J(n, 1, 1)
            du4 = (J(i, 1, 0) \ J(n - i, 1, 1))
            if (model == 0) {
                cons = u, du1, du2, du3, du4
                x = cons, datap[., 2..k]
            }
            else if (model == 1) {
                cons = u, du1, du2, du3, du4
                x = cons, (1::n), datap[., 2..k]
            }
            else if (model == 2) {
                cons = u, du1, du2, du3, du4
                dx1 = (J(bp1, k-1, 0) \ datap[bp1+1..n, 2..k])
                dx2 = (J(bp2, k-1, 0) \ datap[bp2+1..n, 2..k])
                dx3 = (J(bp3, k-1, 0) \ datap[bp3+1..n, 2..k])
                dx4 = (J(i, k-1, 0) \ datap[i+1..n, 2..k])
                x = cons, datap[., 2..k], dx1, dx2, dx3, dx4
            }
            else {
                tr = (1::n)
                dtr1 = (J(bp1, 1, 0) \ (bp1+1::n))
                dtr2 = (J(bp2, 1, 0) \ (bp2+1::n))
                dtr3 = (J(bp3, 1, 0) \ (bp3+1::n))
                dtr4 = (J(i, 1, 0) \ (i+1::n))
                cons = u, du1, du2, du3, du4, tr, dtr1, dtr2, dtr3, dtr4
                dx1 = (J(bp1, k-1, 0) \ datap[bp1+1..n, 2..k])
                dx2 = (J(bp2, k-1, 0) \ datap[bp2+1..n, 2..k])
                dx3 = (J(bp3, k-1, 0) \ datap[bp3+1..n, 2..k])
                dx4 = (J(i, k-1, 0) \ datap[i+1..n, 2..k])
                x = cons, datap[., 2..k], dx1, dx2, dx3, dx4
            }
            e = mk_resid(y, x)
            adf_block(e, lagoption, tau, s2)
            vectau[i] = tau
            vecbp[i] = s2
            i = i + 1
        }
        otau = min(vectau[bp2+tb+1..bp3-tb])
        obp = bp2 + tb + mk_minidx(vecbp[bp2+tb+1..bp3-tb])
        return(otau)
    }

    real scalar mbreak44_(real matrix datap, real scalar n, real scalar model, real scalar tb, real scalar bp1, real scalar bp2, real scalar bp3, real scalar lagoption, real scalar obp)
    {
        real scalar i, k, tau, s2, otau
        real vector y, u, e, vectau, vecbp, tr
        real vector du1, du2, du3, du4, dtr1, dtr2, dtr3, dtr4
        real matrix x, cons, dx1, dx2, dx3, dx4
        y = datap[., 1]
        k = cols(datap)
        du1 = (J(bp1, 1, 0) \ J(n - bp1, 1, 1))
        du2 = (J(bp2, 1, 0) \ J(n - bp2, 1, 1))
        du3 = (J(bp3, 1, 0) \ J(n - bp3, 1, 1))
        dtr1 = (J(bp1, 1, 0) \ (bp1+1::n))
        dtr2 = (J(bp2, 1, 0) \ (bp2+1::n))
        dtr3 = (J(bp3, 1, 0) \ (bp3+1::n))
        i = bp3 + tb + 1
        vectau = J(n, 1, 0)
        vecbp = J(n, 1, 0)
        while (i <= n - tb) {
            u = J(n, 1, 1)
            du4 = (J(i, 1, 0) \ J(n - i, 1, 1))
            if (model == 0) {
                cons = u, du1, du2, du3, du4
                x = cons, datap[., 2..k]
            }
            else if (model == 1) {
                cons = u, du1, du2, du3, du4
                x = cons, (1::n), datap[., 2..k]
            }
            else if (model == 2) {
                cons = u, du1, du2, du3, du4
                dx1 = (J(bp1, k-1, 0) \ datap[bp1+1..n, 2..k])
                dx2 = (J(bp2, k-1, 0) \ datap[bp2+1..n, 2..k])
                dx3 = (J(bp3, k-1, 0) \ datap[bp3+1..n, 2..k])
                dx4 = (J(i, k-1, 0) \ datap[i+1..n, 2..k])
                x = cons, datap[., 2..k], dx1, dx2, dx3, dx4
            }
            else {
                tr = (1::n)
                dtr1 = (J(bp1, 1, 0) \ (bp1+1::n))
                dtr2 = (J(bp2, 1, 0) \ (bp2+1::n))
                dtr3 = (J(bp3, 1, 0) \ (bp3+1::n))
                dtr4 = (J(i, 1, 0) \ (i+1::n))
                cons = u, du1, du2, du3, du4, tr, dtr1, dtr2, dtr3, dtr4
                dx1 = (J(bp1, k-1, 0) \ datap[bp1+1..n, 2..k])
                dx2 = (J(bp2, k-1, 0) \ datap[bp2+1..n, 2..k])
                dx3 = (J(bp3, k-1, 0) \ datap[bp3+1..n, 2..k])
                dx4 = (J(i, k-1, 0) \ datap[i+1..n, 2..k])
                x = cons, datap[., 2..k], dx1, dx2, dx3, dx4
            }
            e = mk_resid(y, x)
            adf_block(e, lagoption, tau, s2)
            vectau[i] = tau
            vecbp[i] = s2
            i = i + 1
        }
        otau = min(vectau[bp3+tb+1..n-tb])
        obp = bp3 + tb + mk_minidx(vecbp[bp3+tb+1..n-tb])
        return(otau)
    }

    real scalar mbreak51_(real matrix datap, real scalar n, real scalar model, real scalar tb, real scalar bp1, real scalar bp2, real scalar bp3, real scalar bp4, real scalar lagoption, real scalar obp)
    {
        real scalar i, k, tau, s2, otau
        real vector y, u, e, vectau, vecbp, tr
        real vector du1, du2, du3, du4, du5, dtr1, dtr2, dtr3, dtr4, dtr5
        real matrix x, cons, dx1, dx2, dx3, dx4, dx5
        y = datap[., 1]
        k = cols(datap)
        du1 = (J(bp1, 1, 0) \ J(n - bp1, 1, 1))
        du2 = (J(bp2, 1, 0) \ J(n - bp2, 1, 1))
        du3 = (J(bp3, 1, 0) \ J(n - bp3, 1, 1))
        du4 = (J(bp4, 1, 0) \ J(n - bp4, 1, 1))
        dtr1 = (J(bp1, 1, 0) \ (bp1+1::n))
        dtr2 = (J(bp2, 1, 0) \ (bp2+1::n))
        dtr3 = (J(bp3, 1, 0) \ (bp3+1::n))
        dtr4 = (J(bp4, 1, 0) \ (bp4+1::n))
        i = tb + 1
        vectau = J(n, 1, 0)
        vecbp = J(n, 1, 0)
        while (i <= bp1 - tb) {
            u = J(n, 1, 1)
            du5 = (J(i, 1, 0) \ J(n - i, 1, 1))
            if (model == 0) {
                cons = u, du1, du2, du3, du4, du5
                x = cons, datap[., 2..k]
            }
            else if (model == 1) {
                cons = u, du1, du2, du3, du4, du5
                x = cons, (1::n), datap[., 2..k]
            }
            else if (model == 2) {
                cons = u, du1, du2, du3, du4, du5
                dx1 = (J(bp1, k-1, 0) \ datap[bp1+1..n, 2..k])
                dx2 = (J(bp2, k-1, 0) \ datap[bp2+1..n, 2..k])
                dx3 = (J(bp3, k-1, 0) \ datap[bp3+1..n, 2..k])
                dx4 = (J(bp4, k-1, 0) \ datap[bp4+1..n, 2..k])
                dx5 = (J(i, k-1, 0) \ datap[i+1..n, 2..k])
                x = cons, datap[., 2..k], dx1, dx2, dx3, dx4, dx5
            }
            else {
                tr = (1::n)
                dtr1 = (J(bp1, 1, 0) \ (bp1+1::n))
                dtr2 = (J(bp2, 1, 0) \ (bp2+1::n))
                dtr3 = (J(bp3, 1, 0) \ (bp3+1::n))
                dtr4 = (J(bp4, 1, 0) \ (bp4+1::n))
                dtr5 = (J(i, 1, 0) \ (i+1::n))
                cons = u, du1, du2, du3, du4, du5, tr, dtr1, dtr2, dtr3, dtr4, dtr5
                dx1 = (J(bp1, k-1, 0) \ datap[bp1+1..n, 2..k])
                dx2 = (J(bp2, k-1, 0) \ datap[bp2+1..n, 2..k])
                dx3 = (J(bp3, k-1, 0) \ datap[bp3+1..n, 2..k])
                dx4 = (J(bp4, k-1, 0) \ datap[bp4+1..n, 2..k])
                dx5 = (J(i, k-1, 0) \ datap[i+1..n, 2..k])
                x = cons, datap[., 2..k], dx1, dx2, dx3, dx4, dx5
            }
            e = mk_resid(y, x)
            adf_block(e, lagoption, tau, s2)
            vectau[i] = tau
            vecbp[i] = s2
            i = i + 1
        }
        otau = min(vectau[tb+1..bp1-tb])
        obp = tb + mk_minidx(vecbp[tb+1..bp1-tb])
        return(otau)
    }

    real scalar mbreak52_(real matrix datap, real scalar n, real scalar model, real scalar tb, real scalar bp1, real scalar bp2, real scalar bp3, real scalar bp4, real scalar lagoption, real scalar obp)
    {
        real scalar i, k, tau, s2, otau
        real vector y, u, e, vectau, vecbp, tr
        real vector du1, du2, du3, du4, du5, dtr1, dtr2, dtr3, dtr4, dtr5
        real matrix x, cons, dx1, dx2, dx3, dx4, dx5
        y = datap[., 1]
        k = cols(datap)
        du1 = (J(bp1, 1, 0) \ J(n - bp1, 1, 1))
        du2 = (J(bp2, 1, 0) \ J(n - bp2, 1, 1))
        du3 = (J(bp3, 1, 0) \ J(n - bp3, 1, 1))
        du4 = (J(bp4, 1, 0) \ J(n - bp4, 1, 1))
        dtr1 = (J(bp1, 1, 0) \ (bp1+1::n))
        dtr2 = (J(bp2, 1, 0) \ (bp2+1::n))
        dtr3 = (J(bp3, 1, 0) \ (bp3+1::n))
        dtr4 = (J(bp4, 1, 0) \ (bp4+1::n))
        i = bp1 + tb + 1
        vectau = J(n, 1, 0)
        vecbp = J(n, 1, 0)
        while (i <= bp2 - tb) {
            u = J(n, 1, 1)
            du5 = (J(i, 1, 0) \ J(n - i, 1, 1))
            if (model == 0) {
                cons = u, du1, du2, du3, du4, du5
                x = cons, datap[., 2..k]
            }
            else if (model == 1) {
                cons = u, du1, du2, du3, du4, du5
                x = cons, (1::n), datap[., 2..k]
            }
            else if (model == 2) {
                cons = u, du1, du2, du3, du4, du5
                dx1 = (J(bp1, k-1, 0) \ datap[bp1+1..n, 2..k])
                dx2 = (J(bp2, k-1, 0) \ datap[bp2+1..n, 2..k])
                dx3 = (J(bp3, k-1, 0) \ datap[bp3+1..n, 2..k])
                dx4 = (J(bp4, k-1, 0) \ datap[bp4+1..n, 2..k])
                dx5 = (J(i, k-1, 0) \ datap[i+1..n, 2..k])
                x = cons, datap[., 2..k], dx1, dx2, dx3, dx4, dx5
            }
            else {
                tr = (1::n)
                dtr1 = (J(bp1, 1, 0) \ (bp1+1::n))
                dtr2 = (J(bp2, 1, 0) \ (bp2+1::n))
                dtr3 = (J(bp3, 1, 0) \ (bp3+1::n))
                dtr4 = (J(bp4, 1, 0) \ (bp4+1::n))
                dtr5 = (J(i, 1, 0) \ (i+1::n))
                cons = u, du1, du2, du3, du4, du5, tr, dtr1, dtr2, dtr3, dtr4, dtr5
                dx1 = (J(bp1, k-1, 0) \ datap[bp1+1..n, 2..k])
                dx2 = (J(bp2, k-1, 0) \ datap[bp2+1..n, 2..k])
                dx3 = (J(bp3, k-1, 0) \ datap[bp3+1..n, 2..k])
                dx4 = (J(bp4, k-1, 0) \ datap[bp4+1..n, 2..k])
                dx5 = (J(i, k-1, 0) \ datap[i+1..n, 2..k])
                x = cons, datap[., 2..k], dx1, dx2, dx3, dx4, dx5
            }
            e = mk_resid(y, x)
            adf_block(e, lagoption, tau, s2)
            vectau[i] = tau
            vecbp[i] = s2
            i = i + 1
        }
        otau = min(vectau[bp1+tb+1..bp2-tb])
        obp = bp1 + tb + mk_minidx(vecbp[bp1+tb+1..bp2-tb])
        return(otau)
    }

    real scalar mbreak53_(real matrix datap, real scalar n, real scalar model, real scalar tb, real scalar bp1, real scalar bp2, real scalar bp3, real scalar bp4, real scalar lagoption, real scalar obp)
    {
        real scalar i, k, tau, s2, otau
        real vector y, u, e, vectau, vecbp, tr
        real vector du1, du2, du3, du4, du5, dtr1, dtr2, dtr3, dtr4, dtr5
        real matrix x, cons, dx1, dx2, dx3, dx4, dx5
        y = datap[., 1]
        k = cols(datap)
        du1 = (J(bp1, 1, 0) \ J(n - bp1, 1, 1))
        du2 = (J(bp2, 1, 0) \ J(n - bp2, 1, 1))
        du3 = (J(bp3, 1, 0) \ J(n - bp3, 1, 1))
        du4 = (J(bp4, 1, 0) \ J(n - bp4, 1, 1))
        dtr1 = (J(bp1, 1, 0) \ (bp1+1::n))
        dtr2 = (J(bp2, 1, 0) \ (bp2+1::n))
        dtr3 = (J(bp3, 1, 0) \ (bp3+1::n))
        dtr4 = (J(bp4, 1, 0) \ (bp4+1::n))
        i = bp2 + tb + 1
        vectau = J(n, 1, 0)
        vecbp = J(n, 1, 0)
        while (i <= bp3 - tb) {
            u = J(n, 1, 1)
            du5 = (J(i, 1, 0) \ J(n - i, 1, 1))
            if (model == 0) {
                cons = u, du1, du2, du3, du4, du5
                x = cons, datap[., 2..k]
            }
            else if (model == 1) {
                cons = u, du1, du2, du3, du4, du5
                x = cons, (1::n), datap[., 2..k]
            }
            else if (model == 2) {
                cons = u, du1, du2, du3, du4, du5
                dx1 = (J(bp1, k-1, 0) \ datap[bp1+1..n, 2..k])
                dx2 = (J(bp2, k-1, 0) \ datap[bp2+1..n, 2..k])
                dx3 = (J(bp3, k-1, 0) \ datap[bp3+1..n, 2..k])
                dx4 = (J(bp4, k-1, 0) \ datap[bp4+1..n, 2..k])
                dx5 = (J(i, k-1, 0) \ datap[i+1..n, 2..k])
                x = cons, datap[., 2..k], dx1, dx2, dx3, dx4, dx5
            }
            else {
                tr = (1::n)
                dtr1 = (J(bp1, 1, 0) \ (bp1+1::n))
                dtr2 = (J(bp2, 1, 0) \ (bp2+1::n))
                dtr3 = (J(bp3, 1, 0) \ (bp3+1::n))
                dtr4 = (J(bp4, 1, 0) \ (bp4+1::n))
                dtr5 = (J(i, 1, 0) \ (i+1::n))
                cons = u, du1, du2, du3, du4, du5, tr, dtr1, dtr2, dtr3, dtr4, dtr5
                dx1 = (J(bp1, k-1, 0) \ datap[bp1+1..n, 2..k])
                dx2 = (J(bp2, k-1, 0) \ datap[bp2+1..n, 2..k])
                dx3 = (J(bp3, k-1, 0) \ datap[bp3+1..n, 2..k])
                dx4 = (J(bp4, k-1, 0) \ datap[bp4+1..n, 2..k])
                dx5 = (J(i, k-1, 0) \ datap[i+1..n, 2..k])
                x = cons, datap[., 2..k], dx1, dx2, dx3, dx4, dx5
            }
            e = mk_resid(y, x)
            adf_block(e, lagoption, tau, s2)
            vectau[i] = tau
            vecbp[i] = s2
            i = i + 1
        }
        otau = min(vectau[bp2+tb+1..bp3-tb])
        obp = bp2 + tb + mk_minidx(vecbp[bp2+tb+1..bp3-tb])
        return(otau)
    }

    real scalar mbreak54_(real matrix datap, real scalar n, real scalar model, real scalar tb, real scalar bp1, real scalar bp2, real scalar bp3, real scalar bp4, real scalar lagoption, real scalar obp)
    {
        real scalar i, k, tau, s2, otau
        real vector y, u, e, vectau, vecbp, tr
        real vector du1, du2, du3, du4, du5, dtr1, dtr2, dtr3, dtr4, dtr5
        real matrix x, cons, dx1, dx2, dx3, dx4, dx5
        y = datap[., 1]
        k = cols(datap)
        du1 = (J(bp1, 1, 0) \ J(n - bp1, 1, 1))
        du2 = (J(bp2, 1, 0) \ J(n - bp2, 1, 1))
        du3 = (J(bp3, 1, 0) \ J(n - bp3, 1, 1))
        du4 = (J(bp4, 1, 0) \ J(n - bp4, 1, 1))
        dtr1 = (J(bp1, 1, 0) \ (bp1+1::n))
        dtr2 = (J(bp2, 1, 0) \ (bp2+1::n))
        dtr3 = (J(bp3, 1, 0) \ (bp3+1::n))
        dtr4 = (J(bp4, 1, 0) \ (bp4+1::n))
        i = bp3 + tb + 1
        vectau = J(n, 1, 0)
        vecbp = J(n, 1, 0)
        while (i <= bp4 - tb) {
            u = J(n, 1, 1)
            du5 = (J(i, 1, 0) \ J(n - i, 1, 1))
            if (model == 0) {
                cons = u, du1, du2, du3, du4, du5
                x = cons, datap[., 2..k]
            }
            else if (model == 1) {
                cons = u, du1, du2, du3, du4, du5
                x = cons, (1::n), datap[., 2..k]
            }
            else if (model == 2) {
                cons = u, du1, du2, du3, du4, du5
                dx1 = (J(bp1, k-1, 0) \ datap[bp1+1..n, 2..k])
                dx2 = (J(bp2, k-1, 0) \ datap[bp2+1..n, 2..k])
                dx3 = (J(bp3, k-1, 0) \ datap[bp3+1..n, 2..k])
                dx4 = (J(bp4, k-1, 0) \ datap[bp4+1..n, 2..k])
                dx5 = (J(i, k-1, 0) \ datap[i+1..n, 2..k])
                x = cons, datap[., 2..k], dx1, dx2, dx3, dx4, dx5
            }
            else {
                tr = (1::n)
                dtr1 = (J(bp1, 1, 0) \ (bp1+1::n))
                dtr2 = (J(bp2, 1, 0) \ (bp2+1::n))
                dtr3 = (J(bp3, 1, 0) \ (bp3+1::n))
                dtr4 = (J(bp4, 1, 0) \ (bp4+1::n))
                dtr5 = (J(i, 1, 0) \ (i+1::n))
                cons = u, du1, du2, du3, du4, du5, tr, dtr1, dtr2, dtr3, dtr4, dtr5
                dx1 = (J(bp1, k-1, 0) \ datap[bp1+1..n, 2..k])
                dx2 = (J(bp2, k-1, 0) \ datap[bp2+1..n, 2..k])
                dx3 = (J(bp3, k-1, 0) \ datap[bp3+1..n, 2..k])
                dx4 = (J(bp4, k-1, 0) \ datap[bp4+1..n, 2..k])
                dx5 = (J(i, k-1, 0) \ datap[i+1..n, 2..k])
                x = cons, datap[., 2..k], dx1, dx2, dx3, dx4, dx5
            }
            e = mk_resid(y, x)
            adf_block(e, lagoption, tau, s2)
            vectau[i] = tau
            vecbp[i] = s2
            i = i + 1
        }
        otau = min(vectau[bp3+tb+1..bp4-tb])
        obp = bp3 + tb + mk_minidx(vecbp[bp3+tb+1..bp4-tb])
        return(otau)
    }

    real scalar mbreak55_(real matrix datap, real scalar n, real scalar model, real scalar tb, real scalar bp1, real scalar bp2, real scalar bp3, real scalar bp4, real scalar lagoption, real scalar obp)
    {
        real scalar i, k, tau, s2, otau
        real vector y, u, e, vectau, vecbp, tr
        real vector du1, du2, du3, du4, du5, dtr1, dtr2, dtr3, dtr4, dtr5
        real matrix x, cons, dx1, dx2, dx3, dx4, dx5
        y = datap[., 1]
        k = cols(datap)
        du1 = (J(bp1, 1, 0) \ J(n - bp1, 1, 1))
        du2 = (J(bp2, 1, 0) \ J(n - bp2, 1, 1))
        du3 = (J(bp3, 1, 0) \ J(n - bp3, 1, 1))
        du4 = (J(bp4, 1, 0) \ J(n - bp4, 1, 1))
        dtr1 = (J(bp1, 1, 0) \ (bp1+1::n))
        dtr2 = (J(bp2, 1, 0) \ (bp2+1::n))
        dtr3 = (J(bp3, 1, 0) \ (bp3+1::n))
        dtr4 = (J(bp4, 1, 0) \ (bp4+1::n))
        i = bp4 + tb + 1
        vectau = J(n, 1, 0)
        vecbp = J(n, 1, 0)
        while (i <= n - tb) {
            u = J(n, 1, 1)
            du5 = (J(i, 1, 0) \ J(n - i, 1, 1))
            if (model == 0) {
                cons = u, du1, du2, du3, du4, du5
                x = cons, datap[., 2..k]
            }
            else if (model == 1) {
                cons = u, du1, du2, du3, du4, du5
                x = cons, (1::n), datap[., 2..k]
            }
            else if (model == 2) {
                cons = u, du1, du2, du3, du4, du5
                dx1 = (J(bp1, k-1, 0) \ datap[bp1+1..n, 2..k])
                dx2 = (J(bp2, k-1, 0) \ datap[bp2+1..n, 2..k])
                dx3 = (J(bp3, k-1, 0) \ datap[bp3+1..n, 2..k])
                dx4 = (J(bp4, k-1, 0) \ datap[bp4+1..n, 2..k])
                dx5 = (J(i, k-1, 0) \ datap[i+1..n, 2..k])
                x = cons, datap[., 2..k], dx1, dx2, dx3, dx4, dx5
            }
            else {
                tr = (1::n)
                dtr1 = (J(bp1, 1, 0) \ (bp1+1::n))
                dtr2 = (J(bp2, 1, 0) \ (bp2+1::n))
                dtr3 = (J(bp3, 1, 0) \ (bp3+1::n))
                dtr4 = (J(bp4, 1, 0) \ (bp4+1::n))
                dtr5 = (J(i, 1, 0) \ (i+1::n))
                cons = u, du1, du2, du3, du4, du5, tr, dtr1, dtr2, dtr3, dtr4, dtr5
                dx1 = (J(bp1, k-1, 0) \ datap[bp1+1..n, 2..k])
                dx2 = (J(bp2, k-1, 0) \ datap[bp2+1..n, 2..k])
                dx3 = (J(bp3, k-1, 0) \ datap[bp3+1..n, 2..k])
                dx4 = (J(bp4, k-1, 0) \ datap[bp4+1..n, 2..k])
                dx5 = (J(i, k-1, 0) \ datap[i+1..n, 2..k])
                x = cons, datap[., 2..k], dx1, dx2, dx3, dx4, dx5
            }
            e = mk_resid(y, x)
            adf_block(e, lagoption, tau, s2)
            vectau[i] = tau
            vecbp[i] = s2
            i = i + 1
        }
        otau = min(vectau[bp4+tb+1..n-tb])
        obp = bp4 + tb + mk_minidx(vecbp[bp4+tb+1..n-tb])
        return(otau)
    }

    real scalar mbreak4_(real matrix datap, real scalar n, real scalar model, real scalar tb, real vector bpin, real scalar lagoption, real scalar bp4)
    {
        real scalar bp1, bp2, bp3, mintau4, tau1, tau2, tau3, tau4, bp41, bp42, bp43, bp44
        real vector tt, bb
        bp1 = bpin[1]
        bp2 = bpin[2]
        bp3 = bpin[3]
        if (bp2-bp1 > round(0.1*n) & bp3-bp2 > round(0.1*n)) {
            if (bp1 <= round(0.1*n) & bp3 < round(0.9*n)) {
            tau2 = mbreak42_(datap, n, model, tb, bp1, bp2, bp3, lagoption, bp42)
            tau3 = mbreak43_(datap, n, model, tb, bp1, bp2, bp3, lagoption, bp43)
            tau4 = mbreak44_(datap, n, model, tb, bp1, bp2, bp3, lagoption, bp44)
            tt = (tau2 \ tau3 \ tau4)
            bb = (bp42 \ bp43 \ bp44)
            mintau4 = min(tt)
            bp4 = bb[mk_minidx(tt)]
            }
            else if (bp1 <= round(0.1*n) & bp3 >= round(0.9*n)) {
            tau2 = mbreak42_(datap, n, model, tb, bp1, bp2, bp3, lagoption, bp42)
            tau3 = mbreak43_(datap, n, model, tb, bp1, bp2, bp3, lagoption, bp43)
            tt = (tau2 \ tau3)
            bb = (bp42 \ bp43)
            mintau4 = min(tt)
            bp4 = bb[mk_minidx(tt)]
            }
            else if (bp1 > round(0.1*n) & bp3 >= round(0.9*n)) {
            tau1 = mbreak41_(datap, n, model, tb, bp1, bp2, bp3, lagoption, bp41)
            tau2 = mbreak42_(datap, n, model, tb, bp1, bp2, bp3, lagoption, bp42)
            tau3 = mbreak43_(datap, n, model, tb, bp1, bp2, bp3, lagoption, bp43)
            tt = (tau1 \ tau2 \ tau3)
            bb = (bp41 \ bp42 \ bp43)
            mintau4 = min(tt)
            bp4 = bb[mk_minidx(tt)]
            }
            else if (bp1 > round(0.1*n) & bp3 < round(0.9*n)) {
            tau1 = mbreak41_(datap, n, model, tb, bp1, bp2, bp3, lagoption, bp41)
            tau2 = mbreak42_(datap, n, model, tb, bp1, bp2, bp3, lagoption, bp42)
            tau3 = mbreak43_(datap, n, model, tb, bp1, bp2, bp3, lagoption, bp43)
            tau4 = mbreak44_(datap, n, model, tb, bp1, bp2, bp3, lagoption, bp44)
            tt = (tau1 \ tau2 \ tau3 \ tau4)
            bb = (bp41 \ bp42 \ bp43 \ bp44)
            mintau4 = min(tt)
            bp4 = bb[mk_minidx(tt)]
            }
        }
        else if (bp2-bp1 > round(0.1*n) & bp3-bp2 <= round(0.1*n)) {
            if (bp1 <= round(0.1*n) & bp3 < round(0.9*n)) {
            tau2 = mbreak42_(datap, n, model, tb, bp1, bp2, bp3, lagoption, bp42)
            tau4 = mbreak44_(datap, n, model, tb, bp1, bp2, bp3, lagoption, bp44)
            tt = (tau2 \ tau4)
            bb = (bp42 \ bp44)
            mintau4 = min(tt)
            bp4 = bb[mk_minidx(tt)]
            }
            else if (bp1 <= round(0.1*n) & bp3 >= round(0.9*n)) {
            tau2 = mbreak42_(datap, n, model, tb, bp1, bp2, bp3, lagoption, bp42)
            mintau4 = tau2
            bp4 = bp42
            }
            else if (bp1 > round(0.1*n) & bp3 < round(0.9*n)) {
            tau1 = mbreak41_(datap, n, model, tb, bp1, bp2, bp3, lagoption, bp41)
            tau2 = mbreak42_(datap, n, model, tb, bp1, bp2, bp3, lagoption, bp42)
            tau4 = mbreak44_(datap, n, model, tb, bp1, bp2, bp3, lagoption, bp44)
            tt = (tau1 \ tau2 \ tau4)
            bb = (bp41 \ bp42 \ bp44)
            mintau4 = min(tt)
            bp4 = bb[mk_minidx(tt)]
            }
            else if (bp1 > round(0.1*n) & bp3 >= round(0.9*n)) {
            tau1 = mbreak41_(datap, n, model, tb, bp1, bp2, bp3, lagoption, bp41)
            tau2 = mbreak42_(datap, n, model, tb, bp1, bp2, bp3, lagoption, bp42)
            tt = (tau1 \ tau2)
            bb = (bp41 \ bp42)
            mintau4 = min(tt)
            bp4 = bb[mk_minidx(tt)]
            }
        }
        else if (bp2-bp1 <= round(0.1*n) & bp3-bp2 > round(0.1*n)) {
            if (bp1 <= round(0.1*n) & bp3 < round(0.9*n)) {
            tau3 = mbreak43_(datap, n, model, tb, bp1, bp2, bp3, lagoption, bp43)
            tau4 = mbreak44_(datap, n, model, tb, bp1, bp2, bp3, lagoption, bp44)
            tt = (tau3 \ tau4)
            bb = (bp43 \ bp44)
            mintau4 = min(tt)
            bp4 = bb[mk_minidx(tt)]
            }
            else if (bp1 <= round(0.1*n) & bp3 >= round(0.9*n)) {
            tau3 = mbreak43_(datap, n, model, tb, bp1, bp2, bp3, lagoption, bp43)
            mintau4 = tau3
            bp4 = bp43
            }
            else if (bp1 > round(0.1*n) & bp3 < round(0.9*n)) {
            tau1 = mbreak41_(datap, n, model, tb, bp1, bp2, bp3, lagoption, bp41)
            tau3 = mbreak43_(datap, n, model, tb, bp1, bp2, bp3, lagoption, bp43)
            tau4 = mbreak44_(datap, n, model, tb, bp1, bp2, bp3, lagoption, bp44)
            tt = (tau1 \ tau3 \ tau4)
            bb = (bp41 \ bp43 \ bp44)
            mintau4 = min(tt)
            bp4 = bb[mk_minidx(tt)]
            }
            else if (bp1 > round(0.1*n) & bp3 >= round(0.9*n)) {
            tau1 = mbreak41_(datap, n, model, tb, bp1, bp2, bp3, lagoption, bp41)
            tau3 = mbreak43_(datap, n, model, tb, bp1, bp2, bp3, lagoption, bp43)
            tt = (tau1 \ tau3)
            bb = (bp41 \ bp43)
            mintau4 = min(tt)
            bp4 = bb[mk_minidx(tt)]
            }
        }
        else if (bp2-bp1 <= round(0.1*n) & bp3-bp2 <= round(0.1*n)) {
            if (bp1 <= round(0.1*n) & bp3 < round(0.9*n)) {
            tau4 = mbreak44_(datap, n, model, tb, bp1, bp2, bp3, lagoption, bp44)
            mintau4 = tau4
            bp4 = bp44
            }
            else if (bp1 > round(0.1*n) & bp3 < round(0.9*n)) {
            tau1 = mbreak41_(datap, n, model, tb, bp1, bp2, bp3, lagoption, bp41)
            tau4 = mbreak44_(datap, n, model, tb, bp1, bp2, bp3, lagoption, bp44)
            tt = (tau1 \ tau4)
            bb = (bp41 \ bp44)
            mintau4 = min(tt)
            bp4 = bb[mk_minidx(tt)]
            }
            else if (bp1 > round(0.1*n) & bp3 >= round(0.9*n)) {
            tau1 = mbreak41_(datap, n, model, tb, bp1, bp2, bp3, lagoption, bp41)
            mintau4 = tau1
            bp4 = bp41
            }
        }
        else {
            mintau4 = 0
            bp4 = 0
        }
        return(mintau4)
    }

    real scalar mbreak5_(real matrix datap, real scalar n, real scalar model, real scalar tb, real vector bpin, real scalar lagoption, real scalar bp5)
    {
        real scalar bp1, bp2, bp3, bp4, mintau5, tau1, tau2, tau3, tau4, tau5
        real scalar bp51, bp52, bp53, bp54, bp55
        real vector tt, bb
        bp1 = bpin[1]
        bp2 = bpin[2]
        bp3 = bpin[3]
        bp4 = bpin[4]
        if (bp2-bp1 > 0.1*n & bp3-bp2 > 0.1*n & bp4-bp3 > 0.1*n) {
            if (bp1 > 0.1*n & bp4 >= round(0.9*n)) {
            tau1 = mbreak51_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp51)
            tau2 = mbreak52_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp52)
            tau3 = mbreak53_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp53)
            tau4 = mbreak54_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp54)
            tt = (tau1 \ tau2 \ tau3 \ tau4)
            bb = (bp51 \ bp52 \ bp53 \ bp54)
            mintau5 = min(tt)
            bp5 = bb[mk_minidx(tt)]
            }
            else if (bp1 > 0.1*n & bp4 < round(0.9*n)) {
            tau1 = mbreak51_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp51)
            tau2 = mbreak52_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp52)
            tau3 = mbreak53_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp53)
            tau4 = mbreak54_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp54)
            tau5 = mbreak55_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp55)
            tt = (tau1 \ tau2 \ tau3 \ tau4 \ tau5)
            bb = (bp51 \ bp52 \ bp53 \ bp54 \ bp55)
            mintau5 = min(tt)
            bp5 = bb[mk_minidx(tt)]
            }
            else if (bp1 <= 0.1*n & bp4 >= round(0.9*n)) {
            tau2 = mbreak52_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp52)
            tau3 = mbreak53_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp53)
            tau4 = mbreak54_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp54)
            tt = (tau2 \ tau3 \ tau4)
            bb = (bp52 \ bp53 \ bp54)
            mintau5 = min(tt)
            bp5 = bb[mk_minidx(tt)]
            }
            else if (bp1 <= 0.1*n & bp4 < round(0.9*n)) {
            tau2 = mbreak52_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp52)
            tau3 = mbreak53_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp53)
            tau4 = mbreak54_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp54)
            tau5 = mbreak55_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp55)
            tt = (tau2 \ tau3 \ tau4 \ tau5)
            bb = (bp52 \ bp53 \ bp54 \ bp55)
            mintau5 = min(tt)
            bp5 = bb[mk_minidx(tt)]
            }
        }
        else if (bp2-bp1 > 0.1*n & bp3-bp2 > 0.1*n & bp4-bp3 <= 0.1*n) {
            if (bp1 > 0.1*n & bp4 >= round(0.9*n)) {
            tau1 = mbreak51_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp51)
            tau2 = mbreak52_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp52)
            tau3 = mbreak53_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp53)
            tt = (tau1 \ tau2 \ tau3)
            bb = (bp51 \ bp52 \ bp53)
            mintau5 = min(tt)
            bp5 = bb[mk_minidx(tt)]
            }
            else if (bp1 > 0.1*n & bp4 < round(0.9*n)) {
            tau1 = mbreak51_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp51)
            tau2 = mbreak52_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp52)
            tau3 = mbreak53_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp53)
            tau5 = mbreak55_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp55)
            tt = (tau1 \ tau2 \ tau3 \ tau5)
            bb = (bp51 \ bp52 \ bp53 \ bp55)
            mintau5 = min(tt)
            bp5 = bb[mk_minidx(tt)]
            }
            else if (bp1 <= 0.1*n & bp4 >= round(0.9*n)) {
            tau2 = mbreak52_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp52)
            tau3 = mbreak53_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp53)
            tt = (tau2 \ tau3)
            bb = (bp52 \ bp53)
            mintau5 = min(tt)
            bp5 = bb[mk_minidx(tt)]
            }
            else if (bp1 <= 0.1*n & bp4 < round(0.9*n)) {
            tau2 = mbreak52_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp52)
            tau3 = mbreak53_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp53)
            tau5 = mbreak55_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp55)
            tt = (tau2 \ tau3 \ tau5)
            bb = (bp52 \ bp53 \ bp55)
            mintau5 = min(tt)
            bp5 = bb[mk_minidx(tt)]
            }
        }
        else if (bp2-bp1 > 0.1*n & bp3-bp2 <= 0.1*n & bp4-bp3 > 0.1*n) {
            if (bp1 > 0.1*n & bp4 >= round(0.9*n)) {
            tau1 = mbreak51_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp51)
            tau2 = mbreak52_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp52)
            tau4 = mbreak54_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp54)
            tt = (tau1 \ tau2 \ tau4)
            bb = (bp51 \ bp52 \ bp54)
            mintau5 = min(tt)
            bp5 = bb[mk_minidx(tt)]
            }
            else if (bp1 > 0.1*n & bp4 < round(0.9*n)) {
            tau1 = mbreak51_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp51)
            tau2 = mbreak52_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp52)
            tau4 = mbreak54_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp54)
            tau5 = mbreak55_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp55)
            tt = (tau1 \ tau2 \ tau4 \ tau5)
            bb = (bp51 \ bp52 \ bp54 \ bp55)
            mintau5 = min(tt)
            bp5 = bb[mk_minidx(tt)]
            }
            else if (bp1 <= 0.1*n & bp4 >= round(0.9*n)) {
            tau2 = mbreak52_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp52)
            tau4 = mbreak54_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp54)
            tt = (tau2 \ tau4)
            bb = (bp52 \ bp54)
            mintau5 = min(tt)
            bp5 = bb[mk_minidx(tt)]
            }
            else if (bp1 <= 0.1*n & bp4 < round(0.9*n)) {
            tau2 = mbreak52_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp52)
            tau4 = mbreak54_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp54)
            tau5 = mbreak55_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp55)
            tt = (tau2 \ tau4 \ tau5)
            bb = (bp52 \ bp54 \ bp55)
            mintau5 = min(tt)
            bp5 = bb[mk_minidx(tt)]
            }
        }
        else if (bp2-bp1 > 0.1*n & bp3-bp2 <= 0.1*n & bp4-bp3 <= 0.1*n) {
            if (bp1 > 0.1*n & bp4 >= round(0.9*n)) {
            tau1 = mbreak51_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp51)
            tau2 = mbreak52_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp52)
            tt = (tau1 \ tau2)
            bb = (bp51 \ bp52)
            mintau5 = min(tt)
            bp5 = bb[mk_minidx(tt)]
            }
            else if (bp1 > 0.1*n & bp4 < round(0.9*n)) {
            tau1 = mbreak51_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp51)
            tau2 = mbreak52_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp52)
            tau5 = mbreak55_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp55)
            tt = (tau1 \ tau2 \ tau5)
            bb = (bp51 \ bp52 \ bp55)
            mintau5 = min(tt)
            bp5 = bb[mk_minidx(tt)]
            }
            else if (bp1 <= 0.1*n & bp4 >= round(0.9*n)) {
            tau2 = mbreak52_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp52)
            mintau5 = tau2
            bp5 = bp52
            }
            else if (bp1 <= 0.1*n & bp4 < round(0.9*n)) {
            tau2 = mbreak52_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp52)
            tau5 = mbreak55_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp55)
            tt = (tau2 \ tau5)
            bb = (bp52 \ bp55)
            mintau5 = min(tt)
            bp5 = bb[mk_minidx(tt)]
            }
        }
        else if (bp2-bp1 <= 0.1*n & bp3-bp2 > 0.1*n & bp4-bp3 > 0.1*n) {
            if (bp1 > 0.1*n & bp4 >= round(0.9*n)) {
            tau1 = mbreak51_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp51)
            tau3 = mbreak53_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp53)
            tau4 = mbreak54_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp54)
            tt = (tau1 \ tau3 \ tau4)
            bb = (bp51 \ bp53 \ bp54)
            mintau5 = min(tt)
            bp5 = bb[mk_minidx(tt)]
            }
            else if (bp1 > 0.1*n & bp4 < round(0.9*n)) {
            tau1 = mbreak51_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp51)
            tau3 = mbreak53_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp53)
            tau4 = mbreak54_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp54)
            tau5 = mbreak55_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp55)
            tt = (tau1 \ tau3 \ tau4 \ tau5)
            bb = (bp51 \ bp53 \ bp54 \ bp55)
            mintau5 = min(tt)
            bp5 = bb[mk_minidx(tt)]
            }
            else if (bp1 <= 0.1*n & bp4 >= round(0.9*n)) {
            tau3 = mbreak53_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp53)
            tau4 = mbreak54_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp54)
            tt = (tau3 \ tau4)
            bb = (bp53 \ bp54)
            mintau5 = min(tt)
            bp5 = bb[mk_minidx(tt)]
            }
            else if (bp1 <= 0.1*n & bp4 < round(0.9*n)) {
            tau3 = mbreak53_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp53)
            tau4 = mbreak54_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp54)
            tau5 = mbreak55_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp55)
            tt = (tau3 \ tau4 \ tau5)
            bb = (bp53 \ bp54 \ bp55)
            mintau5 = min(tt)
            bp5 = bb[mk_minidx(tt)]
            }
        }
        else if (bp2-bp1 <= 0.1*n & bp3-bp2 > 0.1*n & bp4-bp3 <= 0.1*n) {
            if (bp1 > 0.1*n & bp4 >= round(0.9*n)) {
            tau1 = mbreak51_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp51)
            tau3 = mbreak53_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp53)
            tt = (tau1 \ tau3)
            bb = (bp51 \ bp53)
            mintau5 = min(tt)
            bp5 = bb[mk_minidx(tt)]
            }
            else if (bp1 > 0.1*n & bp4 < round(0.9*n)) {
            tau1 = mbreak51_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp51)
            tau3 = mbreak53_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp53)
            tau5 = mbreak55_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp55)
            tt = (tau1 \ tau3 \ tau5)
            bb = (bp51 \ bp53 \ bp55)
            mintau5 = min(tt)
            bp5 = bb[mk_minidx(tt)]
            }
            else if (bp1 <= 0.1*n & bp4 >= round(0.9*n)) {
            tau3 = mbreak53_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp53)
            mintau5 = tau3
            bp5 = bp53
            }
            else if (bp1 <= 0.1*n & bp4 < round(0.9*n)) {
            tau3 = mbreak53_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp53)
            tau5 = mbreak55_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp55)
            tt = (tau3 \ tau5)
            bb = (bp53 \ bp55)
            mintau5 = min(tt)
            bp5 = bb[mk_minidx(tt)]
            }
        }
        else if (bp2-bp1 <= 0.1*n & bp3-bp2 <= 0.1*n & bp4-bp3 > 0.1*n) {
            if (bp1 > 0.1*n & bp4 >= round(0.9*n)) {
            tau1 = mbreak51_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp51)
            tau4 = mbreak54_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp54)
            tt = (tau1 \ tau4)
            bb = (bp51 \ bp54)
            mintau5 = min(tt)
            bp5 = bb[mk_minidx(tt)]
            }
            else if (bp1 > 0.1*n & bp4 < round(0.9*n)) {
            tau1 = mbreak51_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp51)
            tau4 = mbreak54_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp54)
            tau5 = mbreak55_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp55)
            tt = (tau1 \ tau4 \ tau5)
            bb = (bp51 \ bp54 \ bp55)
            mintau5 = min(tt)
            bp5 = bb[mk_minidx(tt)]
            }
            else if (bp1 <= 0.1*n & bp4 >= round(0.9*n)) {
            tau4 = mbreak54_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp54)
            mintau5 = tau4
            bp5 = bp54
            }
            else if (bp1 <= 0.1*n & bp4 < round(0.9*n)) {
            tau4 = mbreak54_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp54)
            tau5 = mbreak55_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp55)
            tt = (tau4 \ tau5)
            bb = (bp54 \ bp55)
            mintau5 = min(tt)
            bp5 = bb[mk_minidx(tt)]
            }
        }
        else if (bp2-bp1 <= 0.1*n & bp3-bp2 <= 0.1*n & bp4-bp3 <= 0.1*n) {
            if (bp1 > 0.1*n & bp4 >= round(0.9*n)) {
            tau1 = mbreak51_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp51)
            mintau5 = tau1
            bp5 = bp51
            }
            else if (bp1 > 0.1*n & bp4 < round(0.9*n)) {
            tau1 = mbreak51_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp51)
            tau5 = mbreak55_(datap, n, model, tb, bp1, bp2, bp3, bp4, lagoption, bp55)
            tt = (tau1 \ tau5)
            bb = (bp51 \ bp55)
            mintau5 = min(tt)
            bp5 = bb[mk_minidx(tt)]
            }
        }
        else {
            mintau5 = 0
            bp5 = 0
        }
        return(mintau5)
    }


real scalar maki_test(real matrix datap, real scalar m, real scalar model, real scalar tb, real scalar lagoption, real vector breakpoints)
{
    real scalar n, mintau1, mintau2, mintau3, mintau4, mintau5
    real scalar bp1, bp2, bp3, bp4, bp5, d0
    real vector mintau, bp, bp123, bp1234, d1
    n = rows(datap)
    if (m == 1) {
        mintau1 = mbreak1(datap, n, model, tb, lagoption, bp1)
        d0 = mintau1
        d1 = bp1
    }
    else if (m == 2) {
        mintau1 = mbreak1(datap, n, model, tb, lagoption, bp1)
        mintau2 = mbreak2(datap, n, model, tb, bp1, lagoption, bp2)
        mintau = (mintau1 \ mintau2)
        d0 = min(mintau)
        d1 = sort((bp1 \ bp2), 1)
    }
    else if (m == 3) {
        mintau1 = mbreak1(datap, n, model, tb, lagoption, bp1)
        mintau2 = mbreak2(datap, n, model, tb, bp1, lagoption, bp2)
        bp = sort((bp1 \ bp2), 1)
        mintau3 = mbreak3(datap, n, model, tb, bp, lagoption, bp3)
        mintau = (mintau1 \ mintau2 \ mintau3)
        d0 = min(mintau)
        d1 = sort((bp1 \ bp2 \ bp3), 1)
    }
    else if (m == 4) {
        mintau1 = mbreak1(datap, n, model, tb, lagoption, bp1)
        mintau2 = mbreak2(datap, n, model, tb, bp1, lagoption, bp2)
        bp = sort((bp1 \ bp2), 1)
        mintau3 = mbreak3(datap, n, model, tb, bp, lagoption, bp3)
        bp123 = sort((bp1 \ bp2 \ bp3), 1)
        mintau4 = mbreak4_(datap, n, model, tb, bp123, lagoption, bp4)
        mintau = (mintau1 \ mintau2 \ mintau3 \ mintau4)
        d0 = min(mintau)
        d1 = sort((bp1 \ bp2 \ bp3 \ bp4), 1)
    }
    else {
        mintau1 = mbreak1(datap, n, model, tb, lagoption, bp1)
        mintau2 = mbreak2(datap, n, model, tb, bp1, lagoption, bp2)
        bp = sort((bp1 \ bp2), 1)
        mintau3 = mbreak3(datap, n, model, tb, bp, lagoption, bp3)
        bp123 = sort((bp1 \ bp2 \ bp3), 1)
        mintau4 = mbreak4_(datap, n, model, tb, bp123, lagoption, bp4)
        bp1234 = sort((bp1 \ bp2 \ bp3 \ bp4), 1)
        mintau5 = mbreak5_(datap, n, model, tb, bp1234, lagoption, bp5)
        mintau = (mintau1 \ mintau2 \ mintau3 \ mintau4 \ mintau5)
        d0 = min(mintau)
        d1 = sort((bp1 \ bp2 \ bp3 \ bp4 \ bp5), 1)
    }
    breakpoints[1..m] = d1
    return(d0)
}


void maki_main(string scalar depvar, string scalar indepvars, real scalar m, real scalar model, real scalar trimm, real scalar lagoption, real scalar bgmaxp, real scalar maxlag, real scalar nobs)
{
    real matrix datap, X
    real vector y, breakpoints, timevals
    real scalar tb, d0, i, kreg
    real rowvector cv
    string rowvector xvars
    pointer(real scalar) scalar pbg, pbest, pbtau, pml, pwarn
    pbg = findexternal("mk_bgmaxp")
    if (pbg == NULL) {
        pbg = crexternal("mk_bgmaxp")
    }
    *pbg = bgmaxp
    pml = findexternal("mk_maxlag")
    if (pml == NULL) {
        pml = crexternal("mk_maxlag")
    }
    *pml = maxlag
    pwarn = findexternal("mk_bgwarn")
    if (pwarn == NULL) {
        pwarn = crexternal("mk_bgwarn")
    }
    *pwarn = 0
    pwarn = findexternal("mk_bgfound")
    if (pwarn == NULL) {
        pwarn = crexternal("mk_bgfound")
    }
    *pwarn = 0
    pwarn = findexternal("mk_bgminptop")
    if (pwarn == NULL) {
        pwarn = crexternal("mk_bgminptop")
    }
    *pwarn = 1
    pwarn = findexternal("mk_bgminp_win")
    if (pwarn == NULL) {
        pwarn = crexternal("mk_bgminp_win")
    }
    *pwarn = 1
    pbtau = findexternal("mk_besttau")
    if (pbtau == NULL) {
        pbtau = crexternal("mk_besttau")
    }
    *pbtau = 1e+300
    pbest = findexternal("mk_bestlag")
    if (pbest == NULL) {
        pbest = crexternal("mk_bestlag")
    }
    *pbest = 0
    y = st_data(., depvar)
    xvars = tokens(indepvars)
    X = st_data(., xvars)
    datap = y, X
    kreg = cols(X)
    tb = round(trimm * nobs)
    breakpoints = J(5, 1, 0)
    d0 = maki_test(datap, m, model, tb, lagoption, breakpoints)
    st_numscalar("r(sel_lag)", *pbest)
    pwarn = findexternal("mk_bgwarn")
    if (pwarn != NULL) {
        st_numscalar("r(bg_warn)", *pwarn)
    }
    pwarn = findexternal("mk_bgminp_win")
    if (pwarn != NULL) {
        st_numscalar("r(bg_minp)", *pwarn)
    }
    timevals = st_data(., "_timevals")
    cv = cv_coint_maki(kreg, m, model)
    st_numscalar("r(test_stat)", d0)
    st_numscalar("r(num_breaks)", m)
    i = 1
    while (i <= 5) {
        if (i <= m & breakpoints[i] > 0) {
            st_numscalar("r(bp" + strofreal(i) + ")", breakpoints[i])
            st_numscalar("r(bpdate" + strofreal(i) + ")", timevals[breakpoints[i]])
            st_numscalar("r(bpfrac" + strofreal(i) + ")", breakpoints[i] / nobs)
        }
        else {
            st_numscalar("r(bp" + strofreal(i) + ")", 0)
            st_numscalar("r(bpdate" + strofreal(i) + ")", 0)
            st_numscalar("r(bpfrac" + strofreal(i) + ")", 0)
        }
        i = i + 1
    }
    st_numscalar("r(cv1)", cv[1])
    st_numscalar("r(cv5)", cv[2])
    st_numscalar("r(cv10)", cv[3])
}


end

program define maki, rclass
    version 14.0

    capture mata: st_local("_mkok", strofreal(findexternal("maki_main()") != NULL))
    if "`_mkok'" != "1" {
        qui findfile maki.ado
        qui run "`r(fn)'"
    }

    syntax varlist(min=2 ts) [if] [in], nbreaks(integer) [ Model(integer 2) TRIMming(real 0.10) LAGoption(integer 1) MAXLag(integer 12) REG REGNEWey ]

    marksample touse
    qui tsset
    local timevar `r(timevar)'
    local panelvar `r(panelvar)'

    if "`panelvar'" != "" {
        di as error "Panel data not supported."
        exit 198
    }
    if "`timevar'" == "" {
        di as error "Time variable not set. Use tsset first."
        exit 198
    }

    gettoken depvar indepvars : varlist
    local numindep : word count `indepvars'

    if `nbreaks' < 1 | `nbreaks' > 5 {
        di as error "Maximum number of breaks must be between 1 and 5."
        exit 198
    }
    if `model' < 0 | `model' > 3 {
        di as error "Model must be 0, 1, 2, or 3."
        exit 198
    }
    if `numindep' < 1 | `numindep' > 4 {
        di as error "Number of regressors must be between 1 and 4."
        exit 198
    }
    if `trimming' <= 0 | `trimming' >= 0.5 {
        di as error "Trimming must be between 0 and 0.5."
        exit 198
    }
    if !inlist(`lagoption', 0, 1, 2, 3) {
        di as error "lagoption must be 0, 1, 2, or 3."
        exit 198
    }
    if `maxlag' < 1 {
        di as error "maxlag must be a positive integer."
        exit 198
    }

    local bgmaxp = 2
    if `lagoption' == 2 {
        qui tsset
        local tsfmt `r(tsfmt)'
        local tdelta `r(tdelta)'
        if strpos("`tsfmt'", "q") {
            local bgmaxp = 8
        }
        else if strpos("`tsfmt'", "m") {
            local bgmaxp = 24
        }
        else if strpos("`tsfmt'", "w") {
            local bgmaxp = 52
        }
        else if strpos("`tsfmt'", "d") {
            local bgmaxp = 100
        }
        else {
            local bgmaxp = 2
        }
    }

    preserve
    qui keep if `touse'
    qui count
    local nobs = r(N)

    foreach v of local varlist {
        qui count if missing(`v')
        if r(N) > 0 {
            di as error "Missing values found in `v'."
            exit 198
        }
    }

    capture drop _timevals
    qui gen double _timevals = `timevar'

    mata: maki_main("`depvar'", "`indepvars'", `nbreaks', `model', `trimming', `lagoption', `bgmaxp', `maxlag', `nobs')

    local num_breaks = r(num_breaks)
    forvalues i = 1/`nbreaks' {
        local bp`i' = r(bp`i')
        local bpdate`i' = r(bpdate`i')
        local bpfrac`i' = r(bpfrac`i')
    }
    local test_stat = r(test_stat)
    local sel_lag = r(sel_lag)
    local bg_warn = r(bg_warn)
    local bg_minp = r(bg_minp)
    local cv1 = r(cv1)
    local cv5 = r(cv5)
    local cv10 = r(cv10)

    restore

    local mname0 "Level Shift"
    local mname1 "Level Shift with Trend"
    local mname2 "Regime Shift"
    local mname3 "Regime Shift with Trend"

    di ""
    di as txt "{hline 70}"
    di as txt _col(5) "{bf:Maki (2012) Cointegration Test with Multiple Breaks}"
    di as txt "{hline 70}"
    di as txt "Model: " as res "`mname`model''"
    di as txt "Observations: " as res `nobs' as txt "   Number of breaks: " as res `nbreaks' as txt "   Trimming: " as res %4.2f `trimming'
    if `lagoption' == 0 {
        di as txt "Lag: " as res "fixed (0)"
        di as txt "Selected lag (at test statistic): " as res `sel_lag'
        di as txt "BG min p-value (checked for AR1-AR`bgmaxp' type autocorrelations): " as res %6.4f `bg_minp'
    }
    else if `lagoption' == 3 {
        di as txt "Lag: " as res "fixed (`maxlag')"
        di as txt "Selected lag (at test statistic): " as res `sel_lag'
        di as txt "BG min p-value (checked for AR1-AR`bgmaxp' type autocorrelations): " as res %6.4f `bg_minp'
    }
    else if `lagoption' == 2 {
        di as txt "Lag: " as res "BG-selected (general-to-specific from max `maxlag')"
        di as txt "Selected lag (at test statistic): " as res `sel_lag'
        di as txt "BG min p-value (checked for AR1-AR`bgmaxp' type autocorrelations): " as res %6.4f `bg_minp'
    }
    else {
        di as txt "Lag: " as res "t-sig (max `maxlag')"
        di as txt "Selected lag (at test statistic): " as res `sel_lag'
        di as txt "BG min p-value (checked for AR1-AR`bgmaxp' type autocorrelations): " as res %6.4f `bg_minp'
    }
    di as txt "Dependent: " as res "`depvar'" as txt "   Regressors: " as res "`indepvars'"
    di as txt "{hline 70}"
    di as txt "H0: No cointegration   H1: Cointegration with up to `nbreaks' break(s)"
    di as txt "{hline 70}"
    di as txt "Test statistic" _col(20) as res %10.4f `test_stat'
    di as txt "Critical values:" _col(20) "1%" _col(30) "5%" _col(40) "10%"
    di as txt _col(18) as res %8.3f `cv1' _col(28) %8.3f `cv5' _col(38) %8.3f `cv10'
    di as txt "{hline 70}"
    di as txt "Estimated break points:"
    di as txt _col(5) "Break" _col(15) "Obs" _col(25) "Date" _col(38) "Fraction"
    forvalues i = 1/`nbreaks' {
        if `bp`i'' > 0 {
            di as txt _col(7) as res `i' _col(15) `bp`i'' _col(25) `bpdate`i'' _col(38) %6.4f `bpfrac`i''
        }
    }
    di as txt "{hline 70}"
    if `test_stat' < `cv1' {
        di as res "Reject H0 at 1%: cointegration with break(s)."
        local reject = 1
    }
    else if `test_stat' < `cv5' {
        di as res "Reject H0 at 5%: cointegration with break(s)."
        local reject = 1
    }
    else if `test_stat' < `cv10' {
        di as res "Reject H0 at 10%: cointegration with break(s)."
        local reject = 1
    }
    else {
        di as res "Fail to reject H0: no cointegration."
        local reject = 0
    }
    di as txt "{hline 70}"
    di ""

    if `lagoption' == 2 & "`bg_warn'" == "1" {
        di as res "Warning: Autocorrelation could not be eliminated up to the maximum lag of `maxlag'."
        di as res "         Results should be interpreted with caution. Consider increasing maxlag()."
        di ""
    }

    if "`reg'" != "" | "`regnewey'" != "" {
        qui tsset `timevar'
        sort `timevar'

        local nbrk = 0
        forvalues i = 1/`nbreaks' {
            if `bp`i'' > 0 local nbrk = `nbrk' + 1
        }

        capture drop mk_tr
        qui gen double mk_tr = _n
        label variable mk_tr "Maki linear trend (estimation order)"

        local du ""
        forvalues i = 1/`nbreaks' {
            if `bp`i'' > 0 {
                capture drop mk_du`i'
                qui gen byte mk_du`i' = (`timevar' > `bpdate`i'') if `touse'
                label variable mk_du`i' "Maki regime dummy `i' (=1 after break `i')"
                local du "`du' mk_du`i'"
            }
        }

        local regvars ""
        if `model' == 0 {
            local regvars "`indepvars' `du'"
        }
        else if `model' == 1 {
            local regvars "mk_tr `indepvars' `du'"
        }
        else if `model' == 2 {
            local regvars "`indepvars'"
            forvalues i = 1/`nbreaks' {
                if `bp`i'' > 0 {
                    foreach v of local indepvars {
                        capture drop mk_du`i'_`v'
                        qui gen double mk_du`i'_`v' = mk_du`i' * `v' if `touse'
                        label variable mk_du`i'_`v' "mk_du`i' x `v'"
                        local regvars "`regvars' mk_du`i'_`v'"
                    }
                }
            }
            local regvars "`regvars' `du'"
        }
        else if `model' == 3 {
            local regvars "mk_tr `indepvars'"
            forvalues i = 1/`nbreaks' {
                if `bp`i'' > 0 {
                    capture drop mk_dtr`i'
                    qui gen double mk_dtr`i' = mk_du`i' * mk_tr if `touse'
                    label variable mk_dtr`i' "mk_du`i' x trend"
                    local regvars "`regvars' mk_dtr`i'"
                    foreach v of local indepvars {
                        capture drop mk_du`i'_`v'
                        qui gen double mk_du`i'_`v' = mk_du`i' * `v' if `touse'
                        label variable mk_du`i'_`v' "mk_du`i' x `v'"
                        local regvars "`regvars' mk_du`i'_`v'"
                    }
                }
            }
            local regvars "`regvars' `du'"
        }
        local regvars : list clean regvars
    }

    if "`reg'" != "" {
        di as text "Cointegrating regression at the estimated breaks (Stata regress, OLS):"
        regress `depvar' `regvars' if `touse'
        di _n as text "To reproduce this regression directly in Stata:"
        di as text "    regress `depvar' `regvars'"
        di ""
    }
    else if "`regnewey'" != "" {
        local nwlag = floor(4 * (`nobs'/100)^(2/9))
        di as text "Cointegrating regression at the estimated breaks (Newey-West HAC, lag = `nwlag'):"
        newey `depvar' `regvars' if `touse', lag(`nwlag')
        di _n as text "Newey-West lag selected automatically as floor(4*(T/100)^(2/9)) = `nwlag'."
        di as text "To reproduce this regression directly in Stata:"
        di as text "    newey `depvar' `regvars', lag(`nwlag')"
        di ""
    }

    return scalar test_stat = `test_stat'
    return scalar cv1 = `cv1'
    return scalar cv5 = `cv5'
    return scalar cv10 = `cv10'
    return scalar nobs = `nobs'
    return scalar nbreaks = `nbreaks'
    return scalar model = `model'
    return scalar reject = `reject'
    forvalues i = 1/`nbreaks' {
        return scalar bp`i' = `bp`i''
        return scalar bpdate`i' = `bpdate`i''
        return scalar bpfrac`i' = `bpfrac`i''
    }
    return local depvar "`depvar'"
    return local indepvars "`indepvars'"
end
