// regbreak_engine5.mata
// Bai & Perron (1998) inference path: supF, seqF(l+1|l), robust covariance,
// break-date confidence intervals, coefficient estimates, and BIC/LWZ/KT model
// selection.  Faithful port of the R package mbreaks (Nguyen-Yamamoto-Perron).
// Author: Dr Merwan Roudane (merwanroudane920@gmail.com, github.com/merwanroudane)
version 14.0

mata:

// HAC a la mbreaks correct(): quadratic-spectral kernel, Andrews AR(1) bandwidth,
// optional AR(1) prewhitening.  Equivalent to rb_correct1 with typekb=0.
real matrix rb_hac(real matrix reg, real colvector res, real scalar prewhit)
{
    real matrix vmat
    vmat = reg :* res
    return(rb_correct1(vmat,vmat,prewhit,0))
}

// diagonal matrix of segment residual variances (psigmq.m / mbreaks psigmq)
real matrix rb_psigmq(real colvector res, real colvector b, real scalar q, real scalar m, real scalar nt)
{
    real matrix sigmat
    real scalar kk, bf, bl
    sigmat = J(m+1,m+1,0)
    sigmat[1,1] = cross(res[|1,1 \ b[1,1],1|], res[|1,1 \ b[1,1],1|])/b[1,1]
    for (kk=2; kk<=m; kk++) {
        bf = b[kk-1,1]
        bl = b[kk,1]
        sigmat[kk,kk] = cross(res[|bf,1 \ bl,1|], res[|bf,1 \ bl,1|])/(bl-bf)
    }
    sigmat[m+1,m+1] = cross(res[|b[m,1]+1,1 \ nt,1|], res[|b[m,1]+1,1 \ nt,1|])/(nt-b[m,1])
    return(sigmat)
}

// covariance matrix of the delta estimates (mbreaks pvdel)
real matrix rb_pvdel(real matrix y, real matrix z, real scalar i, real scalar q, real scalar bigT,
                     real colvector b, real scalar prewhit, real scalar robust, real matrix x,
                     real scalar p, real scalar withb, real scalar hetdat, real scalar hetvar)
{
    real matrix zbar, reg, vdel, sig, lambda, wbar, ww, gg, hac, PX, ztz
    real colvector delv, res
    real scalar sigsc, j, ie, ncol
    real matrix incr
    zbar = rb_pzbar(z,i,b)
    if (p==0) {
        delv = rb_olsqr(y,zbar)
        res = y - zbar*delv
        reg = zbar
    }
    else {
        delv = rb_olsqr(y,(zbar,x))
        res = y - (zbar,x)*delv
        if (withb==0) {
            PX = x*rb_invpd(quadcross(x,x))*x'
            reg = zbar - PX*zbar
        }
        else reg = (x,zbar)
    }
    vdel = J((i+1)*q + p*withb,(i+1)*q + p*withb,0)
    if (robust==0) {
        if (p==0) {
            if (hetdat==1 & hetvar==0) {
                sigsc = cross(res,res)/bigT
                vdel = sigsc*rb_invpd(quadcross(reg,reg))
            }
            if (hetdat==1 & hetvar==1) {
                sig = rb_psigmq(res,b,q,i,bigT)
                vdel = (sig#I(q))*rb_invpd(quadcross(reg,reg))
            }
            if (hetdat==0 & hetvar==0) {
                lambda = rb_plambda(b,i,bigT)
                sigsc = cross(res,res)/bigT
                vdel = sigsc*rb_invpd(lambda#quadcross(z,z))
            }
            if (hetdat==0 & hetvar==1) {
                lambda = rb_plambda(b,i,bigT)
                sig = rb_psigmq(res,b,q,i,bigT)
                vdel = (sig#I(q))*rb_invpd(lambda#quadcross(z,z))
            }
        }
        else {
            if (hetdat==1 & hetvar==0) {
                sigsc = cross(res,res)/bigT
                vdel = sigsc*rb_invpd(quadcross(reg,reg))
            }
            if (hetdat==1 & hetvar==1) {
                wbar = rb_pzbar(reg,i,b)
                ww = quadcross(wbar,wbar)
                sig = rb_psigmq(res,b,q,i,bigT)
                ncol = (i+1)*q + p*withb
                gg = J(ncol,ncol,0)
                ie = 1
                while (ie<=i+1) {
                    incr = sig[ie,ie]*ww[|(ie-1)*ncol+1,(ie-1)*ncol+1 \ ie*ncol,ie*ncol|]
                    gg = gg + incr
                    ie = ie+1
                }
                vdel = rb_invpd(quadcross(reg,reg))*gg*rb_invpd(quadcross(reg,reg))
            }
        }
    }
    else {
        if (p==0) {
            if (hetvar==1) {
                hac = J(q*(i+1),q*(i+1),0)
                hac[|1,1 \ q,q|] = b[1,1]*rb_hac(z[|1,1 \ b[1,1],cols(z)|], res[|1,1 \ b[1,1],1|], prewhit)
                if (rows(b)>1) {
                    for (j=2; j<=i; j++) {
                        hac[|(j-1)*q+1,(j-1)*q+1 \ j*q,j*q|] = (b[j,1]-b[j-1,1])*rb_hac(z[|b[j-1,1]+1,1 \ b[j,1],cols(z)|], res[|b[j-1,1]+1,1 \ b[j,1],1|], prewhit)
                    }
                }
                hac[|i*q+1,i*q+1 \ (i+1)*q,(i+1)*q|] = (bigT-b[i,1])*rb_hac(z[|b[i,1]+1,1 \ bigT,cols(z)|], res[|b[i,1]+1,1 \ bigT,1|], prewhit)
                vdel = rb_invpd(quadcross(reg,reg))*hac*rb_invpd(quadcross(reg,reg))
            }
            else {
                hac = rb_hac(z,res,prewhit)
                lambda = rb_plambda(b,i,bigT)
                vdel = bigT*rb_invpd(quadcross(reg,reg))*(lambda#hac)*rb_invpd(quadcross(reg,reg))
            }
        }
        else {
            hac = rb_hac(reg,res,prewhit)
            vdel = bigT*rb_invpd(quadcross(reg,reg))*hac*rb_invpd(quadcross(reg,reg))
        }
    }
    return(vdel)
}

// supF test of 0 vs i breaks at given dates (mbreaks pftest)
real scalar rb_pftest(real matrix y, real matrix z, real scalar i, real scalar q, real scalar bigT,
                      real colvector date, real scalar prewhit, real scalar robust, real matrix x,
                      real scalar p, real scalar hetdat, real scalar hetvar)
{
    real matrix rmat, zbar, vdel, Mtmp
    real colvector delta, dbdel, fs
    real scalar ftest
    rmat = rb_rmatq(i,q)
    zbar = rb_pzbar(z,i,date)
    if (p==0) delta = rb_olsqr(y,zbar)
    else {
        dbdel = rb_olsqr(y,(zbar,x))
        delta = dbdel[|1,1 \ (i+1)*q,1|]
    }
    vdel = rb_pvdel(y,z,i,q,bigT,date,prewhit,robust,x,p,0,hetdat,hetvar)
    Mtmp = rmat*delta
    fs = Mtmp'*rb_invpd(rmat*vdel*rmat')*Mtmp
    ftest = (bigT-(i+1)*q-p)*fs[1,1]/(bigT*i)
    return(ftest)
}

// x^t for a square matrix (mpower)
real matrix rb_mpower(real matrix A, real scalar t)
{
    real matrix B
    real scalar i
    B = A
    if (t==1) return(B)
    for (i=2; i<=t; i++) B = B*A
    return(B)
}

// density used for break-date CI critical values (funcg)
real scalar rb_funcg(real scalar x, real scalar bet, real scalar alph, real scalar b, real scalar deld, real scalar gam)
{
    real scalar g, xb, aa
    if (x<=0) {
        xb = bet*sqrt(abs(x))
        if (abs(xb)<=30) {
            g = -sqrt(-x/(2*pi()))*exp(x/8) - (bet/alph)*exp(-alph*x)*normal(-bet*sqrt(abs(x))) + ((2*bet*bet/alph)-2-x/2)*normal(-sqrt(abs(x))/2)
        }
        else {
            aa = log(bet/alph)-alph*x-xb^2/2-log(sqrt(2*pi()))-log(xb)
            g = -sqrt(-x/(2*pi()))*exp(x/8) - exp(aa)*normal(-sqrt(abs(x))/2) + ((2*bet*bet/alph)-2-x/2)*normal(-sqrt(abs(x))/2)
        }
    }
    else {
        xb = deld*sqrt(x)
        if (abs(xb)<=30) {
            g = 1 + (b/sqrt(2*pi()))*sqrt(x)*exp(-b*b*x/8) + (b*deld/gam)*exp(gam*x)*normal(-deld*sqrt(x)) + (2-b*b*x/2-2*deld*deld/gam)*normal(-b*sqrt(x)/2)
        }
        else {
            aa = log((b*deld/gam))+gam*x-xb^2/2-log(sqrt(2*pi()))-log(xb)
            g = 1 + (b/sqrt(2*pi()))*sqrt(x)*exp(-b*b*x/8) + exp(aa) + (2-b*b*x/2-2*deld*deld/gam)*normal(-b*sqrt(x)/2)
        }
    }
    return(g)
}

// critical values of the break-date limiting distribution (cvg)
real colvector rb_cvg(real scalar eta, real scalar phi1s, real scalar phi2s)
{
    real colvector cvec, sig
    real scalar a, gam, b, deld, alph, bet, isig, upb, lwb, crit, cct, xx, pval
    cvec = J(4,1,0)
    a = phi1s/phi2s
    gam = ((phi2s/phi1s)+1)*eta/2
    b = sqrt(phi1s*eta/phi2s)
    deld = sqrt(phi2s*eta/phi1s)+b/2
    alph = a*(1+a)/2
    bet = (1+2*a)/2
    sig = (0.025 \ 0.05 \ 0.95 \ 0.975)
    for (isig=1; isig<=4; isig++) {
        upb = 2000
        lwb = -2000
        crit = 999999
        cct = 1
        while (abs(crit)>=0.000001) {
            cct = cct+1
            if (cct>100) {
                crit = 0
            }
            else {
                xx = lwb + (upb-lwb)/2
                pval = rb_funcg(xx,bet,alph,b,deld,gam)
                crit = pval - sig[isig,1]
                if (crit<=0) lwb = xx
                else         upb = xx
            }
        }
        cvec[isig,1] = xx
    }
    return(cvec)
}

// confidence intervals for the break dates (mbreaks interval); rows=breaks,
// cols = lower95, upper95, lower90, upper90
real matrix rb_interval(real matrix y, real matrix z, real matrix zbar, real colvector b,
                        real scalar q, real scalar m, real scalar robust, real scalar prewhit,
                        real scalar hetomega, real scalar hetq, real matrix x, real scalar p)
{
    real matrix bound, qmat, qmat1, omega, omega1, PX
    real colvector cvf, bf, delta, res, dbdel, delv
    real scalar nt, ii, jj, phi1s, phi2s, eta, a, aa1, aa2
    nt = rows(z)
    bound = J(m,4,0)
    bf = J(m+2,1,0)
    if (p==0) {
        delta = rb_olsqr(y,zbar)
        res = y - zbar*delta
    }
    else {
        dbdel = rb_olsqr(y,(zbar,x))
        res = y - (zbar,x)*dbdel
        delta = dbdel[|1,1 \ (m+1)*q,1|]
    }
    bf[1,1] = 0
    bf[|2,1 \ m+1,1|] = b[|1,1 \ m,1|]
    bf[m+2,1] = nt
    for (ii=1; ii<=m; ii++) {
        delv = delta[|ii*q+1,1 \ (ii+1)*q,1|] - delta[|(ii-1)*q+1,1 \ ii*q,1|]
        if (robust==0) {
            if (hetq==1) {
                qmat = quadcross(z[|bf[ii,1]+1,1 \ bf[ii+1,1],cols(z)|], z[|bf[ii,1]+1,1 \ bf[ii+1,1],cols(z)|])/(bf[ii+1,1]-bf[ii,1])
                qmat1 = quadcross(z[|bf[ii+1,1]+1,1 \ bf[ii+2,1],cols(z)|], z[|bf[ii+1,1]+1,1 \ bf[ii+2,1],cols(z)|])/(bf[ii+2,1]-bf[ii+1,1])
            }
            else {
                qmat = quadcross(z,z)/nt
                qmat1 = qmat
            }
            if (hetomega==1) {
                phi1s = cross(res[|bf[ii,1]+1,1 \ bf[ii+1,1],1|], res[|bf[ii,1]+1,1 \ bf[ii+1,1],1|])/(bf[ii+1,1]-bf[ii,1])
                phi2s = cross(res[|bf[ii+1,1]+1,1 \ bf[ii+2,1],1|], res[|bf[ii+1,1]+1,1 \ bf[ii+2,1],1|])/(bf[ii+2,1]-bf[ii+1,1])
            }
            else {
                phi1s = cross(res,res)/nt
                phi2s = phi1s
            }
            aa1 = (delv'*qmat1*delv)
            aa2 = (delv'*qmat*delv)
            eta = aa1[1,1]/aa2[1,1]
            cvf = rb_cvg(eta,phi1s,phi2s)
            a = aa2[1,1]/phi1s
        }
        else {
            if (hetq==1) {
                qmat = quadcross(z[|bf[ii,1]+1,1 \ bf[ii+1,1],cols(z)|], z[|bf[ii,1]+1,1 \ bf[ii+1,1],cols(z)|])/(bf[ii+1,1]-bf[ii,1])
                qmat1 = quadcross(z[|bf[ii+1,1]+1,1 \ bf[ii+2,1],cols(z)|], z[|bf[ii+1,1]+1,1 \ bf[ii+2,1],cols(z)|])/(bf[ii+2,1]-bf[ii+1,1])
            }
            else {
                qmat = quadcross(z,z)/nt
                qmat1 = qmat
            }
            if (hetomega==1) {
                omega = rb_hac(z[|bf[ii,1]+1,1 \ bf[ii+1,1],cols(z)|], res[|bf[ii,1]+1,1 \ bf[ii+1,1],1|], prewhit)
                omega1 = rb_hac(z[|bf[ii+1,1]+1,1 \ bf[ii+2,1],cols(z)|], res[|bf[ii+1,1]+1,1 \ bf[ii+2,1],1|], prewhit)
            }
            else {
                omega = rb_hac(z,res,prewhit)
                omega1 = omega
            }
            aa1 = (delv'*omega*delv)
            aa2 = (delv'*qmat*delv)
            phi1s = aa1[1,1]/aa2[1,1]
            aa1 = (delv'*omega1*delv)
            phi2s = aa1[1,1]/aa2[1,1]
            aa1 = (delv'*qmat1*delv)
            eta = aa1[1,1]/aa2[1,1]
            cvf = rb_cvg(eta,phi1s,phi2s)
            aa1 = (delv'*omega*delv)
            a = (aa2[1,1]*aa2[1,1])/aa1[1,1]
        }
        bound[ii,1] = b[ii,1] - cvf[4,1]/a
        bound[ii,2] = b[ii,1] - cvf[1,1]/a
        bound[ii,3] = b[ii,1] - cvf[3,1]/a
        bound[ii,4] = b[ii,1] - cvf[2,1]/a
        // mbreaks rounds ALL rows at the end of EACH break iteration, so an
        // earlier break's upper bounds accumulate one +1 per remaining break.
        // Replicated verbatim for exact compatibility with the R package.
        for (jj=1; jj<=m; jj++) {
            bound[jj,1] = round(bound[jj,1])
            bound[jj,2] = round(bound[jj,2])+1
            bound[jj,3] = round(bound[jj,3])
            bound[jj,4] = round(bound[jj,4])+1
        }
    }
    return(bound)
}

// full coefficient estimation given break dates (mbreaks estim):
// returns beta, SE, CI (m x 4), SSR via output args
void rb_estim(real scalar m, real scalar q, real matrix z, real matrix y, real colvector b,
              real scalar robust, real scalar prewhit, real scalar hetomega, real scalar hetq,
              real matrix x, real scalar p, real scalar hetdat, real scalar hetvar,
              real colvector beta, real colvector SE, real matrix CI, real scalar SSR,
              real colvector fitted, real colvector resid)
{
    real matrix zbar, reg, vdel
    real scalar bigT, d, ii
    bigT = rows(z)
    d = (m+1)*q + p
    zbar = rb_pzbar(z,m,b)
    if (p==0) reg = zbar
    else      reg = (x,zbar)
    beta = rb_olsqr(y,reg)
    vdel = rb_pvdel(y,z,m,q,bigT,b,prewhit,robust,x,p,1,hetdat,hetvar)
    SE = J(d,1,0)
    for (ii=1; ii<=d; ii++) SE[ii,1] = sqrt(vdel[ii,ii])
    CI = rb_interval(y,z,zbar,b,q,m,robust,prewhit,hetomega,hetq,x,p)
    fitted = reg*beta
    resid = y - fitted
    SSR = cross(resid,resid)
}

// supF(l+1|l) additional-break statistic within global segments (mbreaks spflp1)
real scalar rb_spflp1(real colvector bigvec, real colvector dt, real scalar nseg, real matrix y,
                      real matrix z, real scalar h, real scalar q, real scalar prewhit,
                      real scalar robust, real matrix x, real scalar p, real scalar hetdat, real scalar hetvar)
{
    real matrix datevec, glb, bigv2
    real colvector ssrv, ftestv, dv, ds, ytest, ztest, xtest, sub
    real scalar bigT, i_n, is, len, ssrmin, dx, maxf, ssr1
    real scalar starti, endi
    bigT = rows(z)
    ssrv = J(nseg,1,0)
    ftestv = J(nseg,1,0)
    dv = J(nseg+1,1,0)
    if (nseg>=2) dv[|2,1 \ nseg,1|] = dt
    dv[nseg+1,1] = bigT
    ds = J(nseg,1,0)
    i_n = 0
    for (is=1; is<=nseg; is++) {
        len = dv[is+1,1]-dv[is,1]
        if (len>=2*h) {
            starti = dv[is,1]+1
            endi = dv[is+1,1]
            ytest = y[|starti,1 \ endi,1|]
            ztest = z[|starti,1 \ endi,cols(z)|]
            if (p==0) {
                rb_parti(dv[is,1]+1,dv[is,1]+h,dv[is+1,1]-h,dv[is+1,1],bigvec,bigT, ssrmin,dx)
                ds[is,1] = dx
                ftestv[is,1] = rb_pftest(ytest,ztest,1,q,len,J(1,1,dx-dv[is,1]),prewhit,robust,J(len,0,.),0,hetdat,hetvar)
            }
            else {
                xtest = x[|starti,1 \ endi,cols(x)|]
                rb_onebp(y,z,x,h,dv[is,1]+1,dv[is+1,1], ssr1,dx)
                ds[is,1] = dx
                ftestv[is,1] = rb_pftest(ytest,ztest,1,q,len,J(1,1,dx-dv[is,1]),prewhit,robust,xtest,p,hetdat,hetvar)
            }
        }
        else {
            i_n = i_n+1
            ftestv[is,1] = 0.0
        }
    }
    maxf = colmax(ftestv)
    return(maxf)
}

// optimal one-break partition for a partial-change segment (mbreaks onebp)
void rb_onebp(real matrix y, real matrix z, real matrix x, real scalar h, real scalar start,
              real scalar last, real scalar ssrind, real scalar bd)
{
    real matrix zb, xreg
    real colvector yreg, bb, resid
    real scalar i, ssrn, bdat
    ssrind = 999999999999999
    bdat = h
    i = h
    while (i<=last-start+1-h) {
        zb = rb_pzbar(z[|start,1 \ last,cols(z)|],1,J(1,1,i))
        yreg = y[|start,1 \ last,1|]
        xreg = (x[|start,1 \ last,cols(x)|],zb)
        bb = rb_olsqr(yreg,xreg)
        resid = yreg - xreg*bb
        ssrn = cross(resid,resid)
        if (ssrn<ssrind) {
            ssrind = ssrn
            bdat = i
        }
        i = i+1
    }
    bd = bdat + start - 1
}

// information criteria BIC/LWZ/KT -> selected number of breaks (mbreaks doorder)
void rb_ic(real matrix y, real matrix z, real scalar q, real scalar bigT, real scalar m,
           real colvector glb, real matrix datevec,
           real scalar mBIC, real scalar mLWZ, real scalar mKT)
{
    real colvector glob, bic, lwz, kt, bd, segy, segz, segres
    real scalar ssr0, delta0, c0, ii, ll, dt
    real matrix zz, seg
    zz = z
    ssr0 = cross(y - z*rb_olsqr(y,z), y - z*rb_olsqr(y,z))
    delta0 = 0.1
    c0 = 0.299
    glob = J(m+1,1,0)
    glob[1,1] = ssr0
    glob[|2,1 \ m+1,1|] = glb
    bic = J(m+1,1,0)
    lwz = J(m+1,1,0)
    kt = J(m+1,1,0)
    for (ii=1; ii<=m+1; ii++) {
        bic[ii,1] = log(glob[ii,1]/bigT) + log(bigT)*(ii-1)*(q+1)/bigT
        lwz[ii,1] = log(glob[ii,1]/(bigT-ii*q-ii+1)) + ((ii-1)*(q+1)*c0*(log(bigT))^(2+delta0))/bigT
        if (ii==1) bd = (0 \ bigT)
        else       bd = (0 \ datevec[|1,ii-1 \ ii-1,ii-1|] \ bigT)
        for (ll=1; ll<=ii; ll++) {
            segy = y[|bd[ll,1]+1,1 \ bd[ll+1,1],1|]
            segz = z[|bd[ll,1]+1,1 \ bd[ll+1,1],cols(z)|]
            segres = segy - segz*rb_olsqr(segy,segz)
            dt = bd[ll+1,1]-bd[ll,1]
            kt[ii,1] = kt[ii,1] + (dt*log(cross(segres,segres)/dt) + q*log(dt))
        }
        kt[ii,1] = kt[ii,1] + 2*ii*log(bigT)
    }
    mBIC = rb_wmin(bic) - 1
    mLWZ = rb_wmin(lwz) - 1
    mKT  = rb_wmin(kt) - 1
}

end
