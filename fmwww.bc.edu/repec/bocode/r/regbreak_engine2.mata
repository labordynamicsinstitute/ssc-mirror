// regbreak_engine2.mata
// Joint coefficient+variance estimation: segmake, estimbr (FGLS), estdate
// (Qu-Perron 2007 sec 5.1 dating), jdateestim. Faithful port of j_breaks.
// Author: Dr Merwan Roudane (merwanroudane920@gmail.com, github.com/merwanroudane)
version 14.0

mata:

// per-observation inverse-variance weights from segment variances (variance breaks brv)
real colvector rb_ibigd(real colvector res, real scalar n, real colvector brv)
{
    real scalar bigt, k, i, j, vvar
    real colvector seg, d
    bigt = rows(res)
    if (n==0) seg = (0 \ bigt)
    else      seg = (0 \ brv \ bigt)
    d = J(bigt,1,0)
    for (k=1; k<=n+1; k++) {
        i = seg[k]+1
        j = seg[k+1]
        vvar = cross(res[|i,1 \ j,1|], res[|i,1 \ j,1|])/(j-i+1)
        d[|i,1 \ j,1|] = J(j-i+1,1,1/vvar)
    }
    return(d)
}

// split K break dates into coefficient breaks brc, variance breaks brv, and
// restriction matrix R (segmake.m)
void rb_segmake(real scalar K, real colvector brk, real scalar m, real scalar n,
                real colvector cbrind, real colvector vbrind, real scalar q,
                real colvector brc, real colvector brv, real matrix R)
{
    real scalar ri, i
    brc = J(0,1,.)
    brv = J(0,1,.)
    R = J(q*(K+1),q*(m+1),0)
    R[|1,1 \ q,q|] = I(q)
    ri = 0
    for (i=1; i<=K; i++) {
        if (cbrind[i,1]==1) {
            brc = (brc \ brk[i,1])
            ri = ri+1
        }
        R[|q*i+1,q*ri+1 \ q*(i+1),q*(ri+1)|] = I(q)
        if (vbrind[i,1]==1) brv = (brv \ brk[i,1])
    }
}

// FGLS estimation of coefficients & residuals given coef & variance break dates (estimbr.m)
void rb_estimbr(real matrix y0, real matrix z0, real scalar q, real matrix x, real scalar p,
                real scalar bigt, real scalar K, real colvector brk, real matrix R,
                real scalar n, real colvector brv, real scalar rest,
                real colvector nbeta, real colvector res)
{
    real matrix y, z, zbar, PX
    real colvector beta0, res0, d, beta, bstar
    real scalar itr
    y = y0
    z = z0
    if (p>=1) {
        PX = x*rb_invpd(quadcross(x,x))*x'
        y = y - PX*y
        z = z - PX*z
    }
    if (K==0) zbar = z
    else      zbar = rb_pzbar(z,K,brk)
    if (rest==1) zbar = zbar*R
    beta0 = rb_invpd(quadcross(zbar,zbar))*quadcross(zbar,y)
    res0 = y-zbar*beta0
    d = rb_ibigd(res0,n,brv)
    beta = rb_invpd(cross(zbar,d,zbar))*cross(zbar,d,y)
    bstar = beta :+ 10
    itr = 1
    while (max(abs(bstar-beta))>=1e-6 & itr<=100) {
        bstar = beta
        res = y-zbar*beta
        d = rb_ibigd(res,n,brv)
        beta = rb_invpd(cross(zbar,d,zbar))*cross(zbar,d,y)
        itr = itr+1
    }
    if (rest==1) nbeta = R*beta
    else         nbeta = beta
    res = y-zbar*beta
}

// jointly estimate coefficient & variance break dates for one labeling (estdate.m)
void rb_estdate(real matrix y0, real matrix z0, real scalar q, real matrix x, real scalar p,
                real scalar K, real scalar bigt, real scalar h, real scalar m, real scalar n,
                real colvector cbrind, real colvector vbrind,
                real colvector brk, real colvector beta, real colvector brc,
                real colvector brv, real colvector res)
{
    real matrix datevec, R, y, z, PX
    real colvector glob, bigvec, dv2
    real scalar diffc, maxiter
    // step 1: joint MLE dating -> K break dates
    rb_dating_MLE(y0,z0,q,x,p,h,K,bigt, glob, datevec, bigvec)
    brk = datevec[|1,K \ K,K|]
    // step 2: split & FGLS
    rb_segmake(K,brk,m,n,cbrind,vbrind,q, brc,brv,R)
    rb_estimbr(y0,z0,q,x,p,bigt,K,brk,R,n,brv,1, beta,res)
    y = y0
    z = z0
    if (p>=1) {
        PX = x*rb_invpd(quadcross(x,x))*x'
        y = y - PX*y
        z = z - PX*z
    }
    // steps 3-5: iterate variance-dating vs FGLS to convergence
    diffc = 0
    maxiter = 10
    while (diffc!=-1 & diffc<maxiter) {
        bigvec = rb_residuals(y,z,beta,q,K)
        rb_dating_M2(bigvec,h,K,bigt, glob, datevec)
        dv2 = datevec[|1,K \ K,K|]
        if (dv2==brk) {
            diffc = -1
        }
        else {
            brk = dv2
            rb_segmake(K,brk,m,n,cbrind,vbrind,q, brc,brv,R)
            rb_estimbr(y0,z0,q,x,p,bigt,K,brk,R,n,brv,1, beta,res)
            diffc = diffc+1
        }
    }
}

// estimate coefficient & variance break dates given (m,n) by maximizing the
// joint log-likelihood over all labelings (jdateestim.m)
void rb_jdateestim(real matrix y, real matrix z, real scalar q, real scalar m, real scalar n,
                   real matrix x, real scalar p, real scalar bigt, real scalar h,
                   real colvector Tc, real colvector Tv)
{
    real scalar brcase, idx, K, idxstar, lr1
    real colvector suplrx, cbrind, vbrind, brk, beta, brc, brv, res, tao
    if (m==0 & n==0) {
        Tc = J(0,1,.)
        Tv = J(0,1,.)
        return
    }
    brcase = rb_numcase(m,n)
    suplrx = J(brcase,1,0)
    for (idx=1; idx<=brcase; idx++) {
        rb_brcvcase(m,n,idx, K,cbrind,vbrind)
        rb_estdate(y,z,q,x,p,K,bigt,h,m,n,cbrind,vbrind, brk,beta,brc,brv,res)
        rb_ploglik(res,n,brv, lr1,tao)
        suplrx[idx,1] = lr1
    }
    idxstar = rb_wmax(suplrx)
    rb_brcvcase(m,n,idxstar, K,cbrind,vbrind)
    rb_estdate(y,z,q,x,p,K,bigt,h,m,n,cbrind,vbrind, brk,beta,brc,brv,res)
    Tc = brc
    Tv = brv
}

end
