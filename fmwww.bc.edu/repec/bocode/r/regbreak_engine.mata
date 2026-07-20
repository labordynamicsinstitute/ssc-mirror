// regbreak_engine.mata
// Mata engine: faithful port of Perron, Yamamoto & Zhou "Testing Jointly for
// Structural Changes in the Error Variance and Coefficients of a Linear
// Regression Model" (j_breaks MATLAB) + Bai & Perron (1998) dating.
// Author: Dr Merwan Roudane (merwanroudane920@gmail.com, github.com/merwanroudane)
// Do not add attribution to anyone else.
version 14.0

mata:

// ---------------------------------------------------------------------------
// small numeric helpers
// ---------------------------------------------------------------------------

// inv() of a symmetric PD matrix; pseudo-inverse fallback (mirrors invpd.m)
real matrix rb_invpd(real matrix A)
{
    real matrix Ai
    Ai = luinv(A)
    if (hasmissing(Ai)) Ai = pinv(A)
    return(Ai)
}

// OLS b = (X'X)^-1 X'y   (mirrors olsqr.m)
real matrix rb_olsqr(real matrix y, real matrix x)
{
    return(rb_invpd(quadcross(x,x))*quadcross(x,y))
}

// index of first minimum of a column vector
real scalar rb_wmin(real colvector v)
{
    real colvector idx
    real rowvector w
    minindex(v,1,idx,w)
    return(idx[1,1])
}

// index of first maximum
real scalar rb_wmax(real colvector v)
{
    real colvector idx
    real rowvector w
    maxindex(v,1,idx,w)
    return(idx[1,1])
}

// quadratic-spectral kernel (kern.m)
real scalar rb_kern(real scalar x)
{
    real scalar del
    del = 6*pi()*x/5
    return(3*(sin(del)/del-cos(del))/(del*del))
}

// automatic AR(1) bandwidth (bandw.m)
real scalar rb_bandw(real matrix vhat)
{
    real scalar nt, d, a2n, a2d, i, b, sig, a2
    nt = rows(vhat)
    d  = cols(vhat)
    a2n = 0
    a2d = 0
    for (i=1; i<=d; i++) {
        b   = rb_olsqr(vhat[|2,i \ nt,i|], vhat[|1,i \ nt-1,i|])
        sig = cross(vhat[|2,i \ nt,i|]-b*vhat[|1,i \ nt-1,i|], vhat[|2,i \ nt,i|]-b*vhat[|1,i \ nt-1,i|])
        sig = sig/(nt-1)
        a2n = a2n + 4*b*b*sig*sig/(1-b)^8
        a2d = a2d + sig*sig/(1-b)^4
    }
    a2 = a2n/a2d
    return(1.3221*(a2*nt)^.2)
}

// long-run variance from two residual-moment matrices (jhatpr1.m)
real matrix rb_jhatpr1(real matrix vmat, real matrix vmata)
{
    real scalar nt, d, st, j
    real matrix jhat
    nt = rows(vmat)
    d  = cols(vmat)
    st = rb_bandw(vmata)
    jhat = quadcross(vmat,vmat)
    for (j=1; j<=nt-1; j++) {
        jhat = jhat + rb_kern(j/st)*quadcross(vmat[|j+1,1 \ nt,d|], vmat[|1,1 \ nt-j,d|])
    }
    for (j=1; j<=nt-1; j++) {
        jhat = jhat + rb_kern(j/st)*quadcross(vmat[|1,1 \ nt-j,d|], vmat[|j+1,1 \ nt,d|])
    }
    jhat = jhat/(nt-d)
    return(jhat)
}

// HAC with hybrid prewhitening option (correct1.m)
// typekb: 0 = LRV from H0 resid, 1 = from H1 resid, 2 = hybrid
real matrix rb_correct1(real matrix vmat0, real matrix vmata0, real scalar prewhit, real scalar typekb)
{
    real scalar nt, d, i
    real matrix vmat, vmata, bmat, vstar, vstara, jh, hac, b, ba
    vmat  = vmat0
    vmata = vmata0
    if (typekb==0) vmata = vmat
    if (typekb==1) vmat  = vmata
    nt = rows(vmat)
    d  = cols(vmat)
    if (prewhit==1) {
        bmat   = J(d,d,0)
        vstar  = J(nt-1,d,0)
        vstara = J(nt-1,d,0)
        for (i=1; i<=d; i++) {
            b  = rb_olsqr(vmat[|2,i \ nt,i|], vmat[|1,1 \ nt-1,d|])
            bmat[i,.] = b'
            vstar[.,i] = vmat[|2,i \ nt,i|] - vmat[|1,1 \ nt-1,d|]*b
            ba = rb_olsqr(vmata[|2,i \ nt,i|], vmata[|1,1 \ nt-1,d|])
            vstara[.,i] = vmata[|2,i \ nt,i|] - vmata[|1,1 \ nt-1,d|]*ba
        }
        jh  = rb_jhatpr1(vstar,vstara)
        hac = rb_invpd(I(d)-bmat)*jh*(rb_invpd(I(d)-bmat))'
    }
    else {
        hac = rb_jhatpr1(vmat,vmata)
    }
    return(hac)
}

// diagonal partition of z at m break dates (pzbar.m / diag_par)
real matrix rb_pzbar(real matrix zz, real scalar m, real colvector bb)
{
    real scalar nt, q1, i
    real matrix zb
    nt = rows(zz)
    q1 = cols(zz)
    zb = J(nt,(m+1)*q1,0)
    zb[|1,1 \ bb[1,1],q1|] = zz[|1,1 \ bb[1,1],q1|]
    i = 2
    while (i<=m) {
        zb[|bb[i-1,1]+1,(i-1)*q1+1 \ bb[i,1],i*q1|] = zz[|bb[i-1,1]+1,1 \ bb[i,1],q1|]
        i = i+1
    }
    zb[|bb[m,1]+1,m*q1+1 \ nt,(m+1)*q1|] = zz[|bb[m,1]+1,1 \ nt,q1|]
    return(zb)
}

// diagonal (Ti-Ti-1)/T matrix (plambda.m)
real matrix rb_plambda(real colvector b, real scalar m, real scalar bigt)
{
    real matrix lambda
    real scalar k
    lambda = J(m+1,m+1,0)
    lambda[1,1] = b[1,1]/bigt
    k = 2
    while (k<=m) {
        lambda[k,k] = (b[k,1]-b[k-1,1])/bigt
        k = k+1
    }
    lambda[m+1,m+1] = (bigt-b[m,1])/bigt
    return(lambda)
}

// segment log-likelihood given variance breaks (ploglik.m); also returns tao
void rb_ploglik(real colvector res, real scalar n, real colvector brv,
                real scalar loglik, real colvector tao)
{
    real scalar bigt, k, i, j, vvar
    real colvector seg
    bigt = rows(res)
    if (n==0) seg = (0 \ bigt)
    else      seg = (0 \ brv \ bigt)
    loglik = 0
    tao = J(bigt,1,0)
    for (k=1; k<=n+1; k++) {
        i = seg[k]+1
        j = seg[k+1]
        vvar = cross(res[|i,1 \ j,1|], res[|i,1 \ j,1|])/(j-i+1)
        tao[|i,1 \ j,1|] = (res[|i,1 \ j,1|]:^2 :/ vvar) :- 1
        loglik = loglik - (1/2)*(j-i+1)*(log(2*pi())+1+log(vvar))
    }
}

// ---------------------------------------------------------------------------
// recursive SSR of a segment (ssr.m)  -> column vector length last
// ---------------------------------------------------------------------------
real colvector rb_ssr(real scalar start, real matrix y, real matrix z, real scalar h, real scalar last)
{
    real colvector out, delta1, delta2, invz
    real matrix z0, y0, inv1, inv2, zr, tmp
    real scalar r, v, f
    out = J(last,1,0)
    z0 = z[|start,1 \ start+h-1,cols(z)|]
    y0 = y[|start,1 \ start+h-1,cols(y)|]
    inv1 = rb_invpd(quadcross(z0,z0))
    delta1 = rb_olsqr(y0,z0)
    out[start+h-1,1] = cross(y0-z0*delta1, y0-z0*delta1)
    r = start+h
    while (r<=last) {
        zr = z[|r,1 \ r,cols(z)|]
        tmp = zr*delta1
        v = y[r,1] - tmp[1,1]
        invz = inv1*zr'
        tmp = zr*invz
        f = 1 + tmp[1,1]
        delta2 = delta1 + (invz*v)/f
        inv2 = inv1 - (invz*invz')/f
        inv1 = inv2
        delta1 = delta2
        out[r,1] = out[r-1,1] + v*v/f
        r = r+1
    }
    return(out)
}

// one-break partition on the triangular SSR store (parti.m)
void rb_parti(real scalar start, real scalar b1, real scalar b2, real scalar last,
              real colvector bigvec, real scalar bigt, real scalar ssrmin, real scalar dx)
{
    real colvector dvec, sub
    real scalar ini, j, jj, k
    dvec = J(bigt,1,0)
    ini = (start-1)*bigt - (start-2)*(start-1)/2 + 1
    for (j=b1; j<=b2; j++) {
        jj = j-start
        k = j*bigt - (j-1)*j/2 + last - j
        dvec[j,1] = bigvec[ini+jj,1] + bigvec[k,1]
    }
    sub = dvec[|b1,1 \ b2,1|]
    ssrmin = colmin(sub)
    dx = (b1-1) + rb_wmin(sub)
}

// SSR-minimising dynamic program (dating.m)
void rb_dating(real matrix y, real matrix z, real scalar h, real scalar m, real scalar q, real scalar bigt,
               real colvector glb, real matrix datevec, real colvector bigvec)
{
    real matrix optdat, optssr
    real colvector dvec, vecssr, sub
    real scalar i, j1, ib, jlast, jb, ssrmin, dx, xx
    datevec = J(m,m,0)
    optdat = J(bigt,m,0)
    optssr = J(bigt,m,0)
    dvec = J(bigt,1,0)
    glb = J(m,1,0)
    bigvec = J(bigt*(bigt+1)/2,1,0)
    for (i=1; i<=bigt-h+1; i++) {
        vecssr = rb_ssr(i,y,z,h,bigt)
        bigvec[|(i-1)*bigt+i-(i-1)*i/2,1 \ i*bigt-(i-1)*i/2,1|] = vecssr[|i,1 \ bigt,1|]
    }
    if (m==1) {
        rb_parti(1,h,bigt-h,bigt,bigvec,bigt,ssrmin,dx)
        datevec[1,1] = dx
        glb[1,1] = ssrmin
    }
    else {
        for (j1=2*h; j1<=bigt; j1++) {
            rb_parti(1,h,j1-h,j1,bigvec,bigt,ssrmin,dx)
            optssr[j1,1] = ssrmin
            optdat[j1,1] = dx
        }
        glb[1,1] = optssr[bigt,1]
        datevec[1,1] = optdat[bigt,1]
        for (ib=2; ib<=m; ib++) {
            if (ib==m) {
                jlast = bigt
                for (jb=ib*h; jb<=jlast-h; jb++) {
                    dvec[jb,1] = optssr[jb,ib-1] + bigvec[(jb+1)*bigt-jb*(jb+1)/2,1]
                }
                sub = dvec[|ib*h,1 \ jlast-h,1|]
                optssr[jlast,ib] = colmin(sub)
                optdat[jlast,ib] = (ib*h-1) + rb_wmin(sub)
            }
            else {
                for (jlast=(ib+1)*h; jlast<=bigt; jlast++) {
                    for (jb=ib*h; jb<=jlast-h; jb++) {
                        dvec[jb,1] = optssr[jb,ib-1] + bigvec[jb*bigt-jb*(jb-1)/2+jlast-jb,1]
                    }
                    sub = dvec[|ib*h,1 \ jlast-h,1|]
                    optssr[jlast,ib] = colmin(sub)
                    optdat[jlast,ib] = (ib*h-1) + rb_wmin(sub)
                }
            }
            datevec[ib,ib] = optdat[bigt,ib]
            for (i=1; i<=ib-1; i++) {
                xx = ib-i
                datevec[xx,ib] = optdat[datevec[xx+1,ib],xx]
            }
            glb[ib,1] = optssr[bigt,ib]
        }
    }
}

// partial-change SSR dating (datingpart.m)
void rb_datingpart(real matrix y, real matrix z, real matrix x, real scalar h, real scalar m,
                   real scalar p, real scalar q, real scalar bigt,
                   real colvector glb, real matrix datevec, real colvector bigvec)
{
    real scalar mi, qq, i, len, ssrn, ssr1
    real matrix zz, datenl, xbar, zbar, teta, gtmp
    real colvector delta1, beta1
    glb = J(m,1,0)
    datevec = J(m,m,0)
    for (mi=1; mi<=m; mi++) {
        qq = p+q
        zz = (x,z)
        rb_dating(y,zz,h,mi,qq,bigt,glb,datenl,bigvec)
        xbar = rb_pzbar(x,mi,datenl[|1,mi \ mi,mi|])
        zbar = rb_pzbar(z,mi,datenl[|1,mi \ mi,mi|])
        teta = rb_olsqr(y,(zbar,xbar))
        delta1 = teta[|1,1 \ q*(mi+1),1|]
        beta1 = rb_olsqr(y-zbar*delta1, x)
        ssr1 = cross(y-x*beta1-zbar*delta1, y-x*beta1-zbar*delta1)
        len = 99999999.0
        while (len>0.0001) {
            rb_dating(y-x*beta1,z,h,mi,q,bigt,glb,datenl,bigvec)
            zbar = rb_pzbar(z,mi,datenl[|1,mi \ mi,mi|])
            teta = rb_olsqr(y,(x,zbar))
            beta1 = teta[|1,1 \ p,1|]
            delta1 = teta[|p+1,1 \ p+q*(mi+1),1|]
            ssrn = cross(y-(x,zbar)*teta, y-(x,zbar)*teta)
            len = abs(ssrn-ssr1)
            ssr1 = ssrn
            glb[mi,1] = ssrn
            datevec[|1,mi \ mi,mi|] = datenl[|1,mi \ mi,mi|]
        }
    }
}

// one-break log-likelihood partition for variance dating (parti2.m)
void rb_parti2(real scalar start, real scalar b1, real scalar b2, real scalar last,
               real colvector bigvec, real scalar bigt, real scalar lrmax, real scalar dx)
{
    real colvector dvec, sub
    real scalar j, llr1, llr2
    dvec = J(bigt,1,0)
    for (j=b1; j<=b2; j++) {
        llr1 = -0.5*(j-start+1)*((log(2*pi())+1)+log(sum(bigvec[|start,1 \ j,1|])/(j-start+1)))
        llr2 = -0.5*(last-j)*((log(2*pi())+1)+log(sum(bigvec[|1*bigt+j+1,1 \ 1*bigt+last,1|])/(last-j)))
        dvec[j,1] = llr1+llr2
    }
    sub = dvec[|b1,1 \ b2,1|]
    lrmax = colmax(sub)
    dx = (b1-1) + rb_wmax(sub)
}

// variance-break dating: maximise segment Gaussian log-lik of squared resids (dating_M2.m)
void rb_dating_M2(real colvector bigvec, real scalar h, real scalar m, real scalar bigt,
                  real colvector glob, real matrix datevec)
{
    real matrix optdat, optlr
    real colvector dvec, sub
    real scalar j1, ib, jlast, jb, lrmax, dx, i, xx
    datevec = J(m,m,0)
    optdat = J(bigt,m,0)
    optlr = J(bigt,m,0)
    dvec = J(bigt,1,0)
    glob = J(m,1,0)
    if (m==1) {
        rb_parti2(1,h,bigt-h,bigt,bigvec,bigt,lrmax,dx)
        datevec[1,1] = dx
        glob[1,1] = lrmax
    }
    else {
        for (j1=2*h; j1<=bigt; j1++) {
            rb_parti2(1,h,j1-h,j1,bigvec[|1,1 \ 2*bigt,1|],bigt,lrmax,dx)
            optlr[j1,1] = lrmax
            optdat[j1,1] = dx
        }
        glob[1,1] = optlr[bigt,1]
        datevec[1,1] = optdat[bigt,1]
        for (ib=2; ib<=m; ib++) {
            if (ib==m) {
                jlast = bigt
                for (jb=ib*h; jb<=jlast-h; jb++) {
                    dvec[jb,1] = optlr[jb,ib-1] - 0.5*(bigt-jb+1)*((log(2*pi())+1)+log(sum(bigvec[|m*bigt+jb+1,1 \ bigt*(m+1),1|])/(bigt-jb)))
                }
                sub = dvec[|ib*h,1 \ jlast-h,1|]
                optlr[jlast,ib] = colmax(sub)
                optdat[jlast,ib] = (ib*h-1) + rb_wmax(sub)
            }
            else {
                for (jlast=(ib+1)*h; jlast<=bigt; jlast++) {
                    for (jb=ib*h; jb<=jlast-h; jb++) {
                        dvec[jb,1] = optlr[jb,ib-1] - 0.5*(jlast-jb+1)*((log(2*pi())+1)+log(sum(bigvec[|ib*bigt+jb+1,1 \ ib*bigt+jlast,1|])/(jlast-jb)))
                    }
                    sub = dvec[|ib*h,1 \ jlast-h,1|]
                    optlr[jlast,ib] = colmax(sub)
                    optdat[jlast,ib] = (ib*h-1) + rb_wmax(sub)
                }
            }
            datevec[ib,ib] = optdat[bigt,ib]
            for (i=1; i<=ib-1; i++) {
                xx = ib-i
                datevec[xx,ib] = optdat[datevec[xx+1,ib],xx]
            }
            glob[ib,1] = optlr[bigt,ib]
        }
    }
}

// recursive FGLS segment log-likelihood used in joint MLE dating (mlef.m)
real colvector rb_mlef(real scalar start, real matrix y0, real matrix z0, real scalar q,
                       real matrix x, real scalar p, real scalar h, real scalar last)
{
    real colvector loglik
    real matrix y, z, segz, segy, b, res, ihstar, bstar, ystar, zstar, tempz, tempy, gstar, icstar, zj, yj
    real scalar i, j, vvar, vstar, itr
    loglik = J(last,1,0)
    y = y0
    z = z0
    if (p>0) {
        y = y - x*rb_invpd(quadcross(x,x))*quadcross(x,y)
        z = z - x*rb_invpd(quadcross(x,x))*quadcross(x,z)
    }
    i = start
    j = start+h-1
    segz = z[|i,1 \ j,cols(z)|]
    segy = y[|i,1 \ j,cols(y)|]
    b = rb_invpd(quadcross(segz,segz))*quadcross(segz,segy)
    res = segy-segz*b
    vvar = cross(res,res)/h
    vstar = vvar+1
    itr = 1
    while (abs(vvar-vstar)>1e-6 & itr<1000) {
        vstar = vvar
        b = rb_invpd(quadcross(segz,segz)/vstar)*quadcross(segz,segy)/vstar
        res = segy-segz*b
        vvar = cross(res,res)/h
        itr = itr+1
    }
    ihstar = rb_invpd(quadcross(segz,segz)/vvar)
    bstar = b
    ystar = segy
    zstar = segz
    vstar = vvar
    while (j<=last) {
        zj = z[|j,1 \ j,cols(z)|]
        yj = y[|j,1 \ j,cols(y)|]
        gstar = ihstar*zj'
        icstar = rb_invpd(vstar + (zj*ihstar*zj'))
        b = bstar + gstar*icstar*(yj-zj*bstar)
        tempz = (zstar \ zj)
        tempy = (ystar \ yj)
        res = tempy-tempz*b
        vvar = cross(res,res)/(j-i+1)
        itr = 1
        vstar = vvar+10
        while (abs(vvar-vstar)>1e-6 & itr<1000) {
            vstar = vvar
            icstar = rb_invpd(vstar + (zj*ihstar*zj'))
            b = bstar + gstar*icstar*(yj-zj*bstar)
            res = tempy-tempz*b
            vvar = cross(res,res)/(j-i+1)
            itr = itr+1
        }
        loglik[j,1] = ((j-i+1)/2)*(log(2*pi())+1) + (j-i+1)/2*log(vvar)
        bstar = b
        zstar = tempz
        ystar = tempy
        vstar = vvar
        ihstar = ihstar - gstar*icstar*gstar'
        j = j+1
    }
    return(loglik)
}

// joint MLE dating dynamic program (dating_MLE.m)
void rb_dating_MLE(real matrix y, real matrix z, real scalar q, real matrix x, real scalar p,
                   real scalar h, real scalar m, real scalar bigt,
                   real colvector glob, real matrix datevec, real colvector bigvec)
{
    real matrix optdat, optmle
    real colvector dvec, loglik, sub
    real scalar i, j1, ib, jlast, jb, mlemax, dx, xx
    datevec = J(m,m,0)
    optdat = J(bigt,m,0)
    optmle = J(bigt,m,0)
    dvec = J(bigt,1,0)
    glob = J(m,1,0)
    bigvec = J(bigt*(bigt+1)/2,1,0)
    for (i=1; i<=bigt-h+1; i++) {
        loglik = rb_mlef(i,y,z,q,x,p,h,bigt)
        bigvec[|(i-1)*bigt+i-(i-1)*i/2,1 \ i*bigt-(i-1)*i/2,1|] = loglik[|i,1 \ bigt,1|]
    }
    if (m==1) {
        rb_parti(1,h,bigt-h,bigt,bigvec,bigt,mlemax,dx)
        datevec[1,1] = dx
        glob[1,1] = mlemax
    }
    else {
        for (j1=2*h; j1<=bigt; j1++) {
            rb_parti(1,h,j1-h,j1,bigvec,bigt,mlemax,dx)
            optmle[j1,1] = mlemax
            optdat[j1,1] = dx
        }
        glob[1,1] = optmle[bigt,1]
        datevec[1,1] = optdat[bigt,1]
        for (ib=2; ib<=m; ib++) {
            if (ib==m) {
                jlast = bigt
                for (jb=ib*h; jb<=jlast-h; jb++) {
                    dvec[jb,1] = optmle[jb,ib-1] + bigvec[(jb+1)*bigt-jb*(jb+1)/2,1]
                }
                sub = dvec[|ib*h,1 \ jlast-h,1|]
                optmle[jlast,ib] = colmin(sub)
                optdat[jlast,ib] = (ib*h-1) + rb_wmin(sub)
            }
            else {
                for (jlast=(ib+1)*h; jlast<=bigt; jlast++) {
                    for (jb=ib*h; jb<=jlast-h; jb++) {
                        dvec[jb,1] = optmle[jb,ib-1] + bigvec[jb*bigt-jb*(jb-1)/2+jlast-jb,1]
                    }
                    sub = dvec[|ib*h,1 \ jlast-h,1|]
                    optmle[jlast,ib] = colmin(sub)
                    optdat[jlast,ib] = (ib*h-1) + rb_wmin(sub)
                }
            }
            datevec[ib,ib] = optdat[bigt,ib]
            for (i=1; i<=ib-1; i++) {
                xx = ib-i
                datevec[xx,ib] = optdat[datevec[xx+1,ib],xx]
            }
            glob[ib,1] = optmle[bigt,ib]
        }
    }
    glob = -glob
}

// squared residuals per coefficient regime (residuals.m)
real colvector rb_residuals(real matrix y, real matrix z, real colvector b, real scalar q, real scalar m)
{
    real scalar bigt, i
    real colvector bigvec
    bigt = rows(y)
    bigvec = J(bigt*(m+1),1,0)
    for (i=1; i<=m+1; i++) {
        bigvec[|(i-1)*bigt+1,1 \ i*bigt,1|] = (y-z*b[|(i-1)*q+1,1 \ i*q,1|]):^2
    }
    return(bigvec)
}

// number of labelings of m coefficient + n variance breaks (numcase.m)
real scalar rb_numcase(real scalar m, real scalar n)
{
    real scalar num
    num = .
    if (m==0) num = n
    if (n==0) num = m
    if (m==1 & n==1) num = 3
    if (m==1 & n==2) num = 5
    if (m==1 & n==3) num = 7
    if (m==1 & n==4) num = 9
    if (m==2 & n==1) num = 5
    if (m==2 & n==2) num = 13
    if (m==2 & n==3) num = 25
    if (m==3 & n==1) num = 7
    if (m==3 & n==2) num = 25
    if (m==3 & n==3) num = 62
    if (m==4 & n==1) num = 9
    return(num)
}

end
