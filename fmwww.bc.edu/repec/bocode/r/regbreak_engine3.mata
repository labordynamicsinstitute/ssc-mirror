// regbreak_engine3.mata
// sup-LR test statistics pslr0..pslr4 of Perron, Yamamoto & Zhou.
// Faithful, line-by-line port of pslr0.m..pslr4.m.
// Author: Dr Merwan Roudane (merwanroudane920@gmail.com, github.com/merwanroudane)
version 14.0

mata:

// m x (m+1) first-difference contrast matrix, then kron with I(q)
real matrix rb_rmatq(real scalar m, real scalar q)
{
    real matrix rsub
    real scalar j
    rsub = J(m,m+1,0)
    for (j=1; j<=m; j++) {
        rsub[j,j] = -1
        rsub[j,j+1] = 1
    }
    return(rsub#I(q))
}

// stack squared residuals n+1 times (for variance dating)
real colvector rb_stacksq(real colvector res0, real scalar n, real scalar bigt)
{
    real colvector bigvec
    real scalar i
    bigvec = J(bigt*(n+1),1,0)
    for (i=1; i<=n+1; i++) {
        bigvec[|(i-1)*bigt+1,1 \ i*bigt,1|] = res0:^2
    }
    return(bigvec)
}

// ------- pslr0: supLR for m coef breaks | no variance breaks (pslr0.m) -------
real scalar rb_pslr0(real matrix y, real matrix z, real scalar q, real scalar m,
                     real matrix x, real scalar p, real scalar bigt, real scalar robust,
                     real scalar prewhit, real scalar h, real scalar typekc,
                     real colvector brcstar)
{
    real matrix reg0, datevec, zbar, reg1, regm, vmat0, vmat1, hac, lambda, vdel, rmat, Mtmp
    real colvector res0, brc, beta1, res1, delta1, fs, glb, bigvec
    real scalar vvar0, lr0, vvar1, lr1, suplr, i
    if (p==0) reg0 = z
    else      reg0 = (z,x)
    res0 = y - reg0*rb_invpd(quadcross(reg0,reg0))*quadcross(reg0,y)
    vvar0 = cross(res0,res0)/bigt
    lr0 = -(bigt/2)*(log(2*pi())+1+log(vvar0))
    if (p==0) rb_dating(y,z,h,m,q,bigt, glb,datevec,bigvec)
    else      rb_datingpart(y,z,x,h,m,p,q,bigt, glb,datevec,bigvec)
    brc = datevec[|1,m \ m,m|]
    zbar = rb_pzbar(z,m,brc)
    if (p==0) reg1 = zbar
    else      reg1 = (zbar,x)
    beta1 = rb_invpd(quadcross(reg1,reg1))*quadcross(reg1,y)
    res1 = y - reg1*beta1
    vvar1 = cross(res1,res1)/bigt
    lr1 = -(bigt/2)*(log(2*pi())+1+log(vvar1))
    if (robust==0) {
        suplr = 2*(lr1-lr0)
    }
    else {
        if (p==0) {
            vmat0 = reg0 :* res0
            vmat1 = reg0 :* res1
            hac = rb_correct1(vmat0,vmat1,prewhit,typekc)
            lambda = rb_plambda(brc,m,bigt)
            vdel = bigt*rb_invpd(quadcross(reg1,reg1))*(lambda#hac)*rb_invpd(quadcross(reg1,reg1))
            delta1 = beta1
        }
        else {
            regm = zbar - x*rb_invpd(quadcross(x,x))*quadcross(x,zbar)
            vmat0 = regm :* res0
            vmat1 = regm :* res1
            hac = rb_correct1(vmat0,vmat1,prewhit,typekc)
            vdel = bigt*rb_invpd(quadcross(regm,regm))*hac*rb_invpd(quadcross(regm,regm))
            delta1 = beta1[|1,1 \ (m+1)*q,1|]
        }
        rmat = rb_rmatq(m,q)
        Mtmp = rmat*delta1
        fs = Mtmp'*rb_invpd(rmat*vdel*rmat')*Mtmp
        suplr = (bigt-(m+1)*q-p)*fs[1,1]/bigt
    }
    brcstar = brc
    return(suplr/m)
}

// ------- pslr1: supLR for n variance breaks | no coef breaks (pslr1.m) -------
real scalar rb_pslr1(real matrix y, real matrix z, real scalar q, real scalar n,
                     real matrix x, real scalar p, real scalar bigt, real scalar vrobust,
                     real scalar prewhit, real scalar h, real scalar typekbv,
                     real colvector brvstar)
{
    real matrix reg, datevec, R
    real colvector res0, tao0, bigvec, brv, brvo, nbeta, res1, tao1, zeroc, onec, cbz, glob
    real scalar vvar0, lr0, lr1, phi, suplr
    if (p==0) reg = z
    else      reg = (z,x)
    res0 = y - reg*rb_invpd(quadcross(reg,reg))*quadcross(reg,y)
    vvar0 = cross(res0,res0)/bigt
    tao0 = (res0:^2 :/ vvar0) :- 1
    lr0 = -(bigt/2)*(log(2*pi())+1+log(vvar0))
    bigvec = rb_stacksq(res0,n,bigt)
    rb_dating_M2(bigvec,h,n,bigt, glob,datevec)
    brv = datevec[|1,n \ n,n|]
    zeroc = J(n,1,0)
    onec = J(n,1,1)
    rb_segmake(n,brv,0,n,zeroc,onec,q, cbz,brvo,R)
    rb_estimbr(y,z,q,x,p,bigt,n,brvo,R,n,brvo,1, nbeta,res1)
    rb_ploglik(res1,n,brvo, lr1,tao1)
    if (vrobust==0) phi = cross(tao0,tao0)/(bigt-1)
    else            phi = rb_correct1(tao0,tao1,prewhit,typekbv)
    suplr = (2/phi)*2*(lr1-lr0)
    brvstar = brvo
    return(suplr/n)
}

// ------- pslr2: supLR for n variance breaks | m coef breaks (pslr2.m) -------
real scalar rb_pslr2(real matrix y, real matrix z, real scalar q, real scalar m, real scalar n,
                     real matrix x, real scalar p, real scalar bigt, real scalar vrobust,
                     real scalar prewhit, real scalar h, real scalar typekbv,
                     real colvector brcstar, real colvector brvstar)
{
    real matrix reg0, datevec, zbar, brcdt, brvdt
    real colvector res0, brc, tao0, suplrx, cbrind, vbrind, brk, beta, brc2, brv2, res1, tao1, glb, bigvec
    real scalar vvar0, lr0, brcase, idx, K, lr1, phi, maxind
    if (p==0) {
        rb_dating(y,z,h,m,q,bigt, glb,datevec,bigvec)
        brc = datevec[|1,m \ m,m|]
        zbar = rb_pzbar(z,m,brc)
        reg0 = zbar
    }
    else {
        rb_datingpart(y,z,x,h,m,p,q,bigt, glb,datevec,bigvec)
        brc = datevec[|1,m \ m,m|]
        zbar = rb_pzbar(z,m,brc)
        reg0 = (zbar,x)
    }
    res0 = y - reg0*rb_invpd(quadcross(reg0,reg0))*quadcross(reg0,y)
    vvar0 = cross(res0,res0)/bigt
    tao0 = (res0:^2 :/ vvar0) :- 1
    lr0 = -(bigt/2)*(log(2*pi())+1+log(vvar0))
    brcase = rb_numcase(m,n)
    suplrx = J(brcase,1,0)
    brcdt = J(brcase,m,0)
    brvdt = J(brcase,n,0)
    for (idx=1; idx<=brcase; idx++) {
        rb_brcvcase(m,n,idx, K,cbrind,vbrind)
        rb_estdate(y,z,q,x,p,K,bigt,h,m,n,cbrind,vbrind, brk,beta,brc2,brv2,res1)
        rb_ploglik(res1,n,brv2, lr1,tao1)
        brcdt[idx,.] = brc2'
        brvdt[idx,.] = brv2'
        if (vrobust==0) phi = cross(tao0,tao0)/(bigt-1)
        else            phi = rb_correct1(tao0,tao1,prewhit,typekbv)
        suplrx[idx,1] = (2/phi)*2*(lr1-lr0)
    }
    maxind = rb_wmax(suplrx)
    brcstar = brcdt[maxind,.]'
    brvstar = brvdt[maxind,.]'
    return(suplrx[maxind,1]/n)
}

// ------- pslr3: supLR for m coef breaks | n variance breaks (pslr3.m) -------
real scalar rb_pslr3(real matrix y, real matrix z, real scalar q, real scalar m, real scalar n,
                     real matrix x, real scalar p, real scalar bigt, real scalar robust,
                     real scalar prewhit, real scalar h, real scalar typek,
                     real colvector brcstar, real colvector brvstar)
{
    real matrix reg0, datevec, R, brcdt, brvdt, zbar, reg1, xs, regms, vmat0, vmat1, hac, lambda, vdel, rmat, Mtmp
    real colvector res0, bigvec, brv, nbeta0, suplrx, cbrind, vbrind, brk, beta, brc2, brv2, res1, glob
    real colvector sw, ys, zbars, reg0s, reg1s, beta1s, res0s, res1s, delta1s, fs, zeroc, onec
    real scalar lr0, brcase, idx, K, lr1, suplr, maxind, i
    if (p==0) reg0 = z
    else      reg0 = (z,x)
    res0 = y - reg0*rb_invpd(quadcross(reg0,reg0))*quadcross(reg0,y)
    bigvec = rb_stacksq(res0,n,bigt)
    rb_dating_M2(bigvec,h,n,bigt, glob,datevec)
    brv = datevec[|1,n \ n,n|]
    zeroc = J(n,1,0)
    onec = J(n,1,1)
    rb_segmake(n,brv,0,n,zeroc,onec,cols(z), brc2,brv2,R)
    rb_estimbr(y,z,q,x,p,bigt,n,brv2,R,n,brv2,1, nbeta0,res0)
    lr0 = rb_ploglik_v(res0,n,brv2)
    brcase = rb_numcase(m,n)
    suplrx = J(brcase,1,0)
    brcdt = J(brcase,m,0)
    brvdt = J(brcase,n,0)
    for (idx=1; idx<=brcase; idx++) {
        rb_brcvcase(m,n,idx, K,cbrind,vbrind)
        rb_estdate(y,z,q,x,p,K,bigt,h,m,n,cbrind,vbrind, brk,beta,brc2,brv2,res1)
        brcdt[idx,.] = brc2'
        brvdt[idx,.] = brv2'
        lr1 = rb_ploglik_v(res1,n,brv2)
        suplrx[idx,1] = 2*(lr1-lr0)
    }
    maxind = rb_wmax(suplrx)
    suplr = suplrx[maxind,1]
    brcstar = brcdt[maxind,.]'
    brvstar = brvdt[maxind,.]'
    rb_brcvcase(m,n,maxind, K,cbrind,vbrind)
    rb_estdate(y,z,q,x,p,K,bigt,h,m,n,cbrind,vbrind, brk,beta,brc2,brv2,res1)
    if (robust==1) {
        zbar = rb_pzbar(z,m,brcstar)
        if (p==0) reg1 = zbar
        else      reg1 = (zbar,x)
        sw = sqrt(rb_ibigd(res1,n,brvstar))
        ys = sw:*y
        zbars = sw:*zbar
        reg0s = sw:*reg0
        reg1s = sw:*reg1
        beta1s = rb_invpd(quadcross(reg1s,reg1s))*quadcross(reg1s,ys)
        res0s = y - reg0*rb_invpd(quadcross(reg0s,reg0s))*quadcross(reg0s,ys)
        res1s = y - reg1*rb_invpd(quadcross(reg1s,reg1s))*quadcross(reg1s,ys)
        if (p==0) {
            vmat0 = reg0 :* res0s
            vmat1 = reg0 :* res1s
            hac = rb_correct1(vmat0,vmat1,prewhit,typek)
            lambda = rb_plambda(brcstar,m,bigt)
            vdel = bigt*rb_invpd(quadcross(reg1,reg1))*(lambda#hac)*rb_invpd(quadcross(reg1,reg1))
            delta1s = beta1s
        }
        else {
            xs = sw:*x
            regms = zbars - xs*rb_invpd(quadcross(xs,xs))*quadcross(xs,zbars)
            vmat0 = regms :* res0s
            vmat1 = regms :* res1s
            hac = rb_correct1(vmat0,vmat1,prewhit,typek)
            vdel = bigt*rb_invpd(quadcross(regms,regms))*hac*rb_invpd(quadcross(regms,regms))
            delta1s = beta1s[|1,1 \ (m+1)*q,1|]
        }
        rmat = rb_rmatq(m,q)
        Mtmp = rmat*delta1s
        fs = Mtmp'*rb_invpd(rmat*vdel*rmat')*Mtmp
        suplr = (bigt-(m+1)*q-p)*fs[1,1]/bigt
    }
    return(suplr/m)
}

// scalar-only ploglik (returns just the log-likelihood)
real scalar rb_ploglik_v(real colvector res, real scalar n, real colvector brv)
{
    real scalar ll
    real colvector tao
    rb_ploglik(res,n,brv, ll,tao)
    return(ll)
}

// ------- pslr4: joint supLR for m coef AND n variance breaks (pslr4.m) -------
real scalar rb_pslr4(real matrix y, real matrix z, real scalar q, real scalar m, real scalar n,
                     real matrix x, real scalar p, real scalar bigt, real scalar robust,
                     real scalar vrobust, real scalar prewhit, real scalar h,
                     real scalar typekbv, real scalar typekbc,
                     real colvector brcstar, real colvector brvstar)
{
    real matrix reg0, brcdt, brvdt, zbar, reg1, xs, regms, vmat0, vmat1, hac, lambda, vdel, rmat, Mtmp
    real colvector res0, tao0, suplrx, suplrv, cbrind, vbrind, brk, beta, brc2, brv2, res1, tao1
    real colvector resv, sw, ys, zbars, reg0s, reg1s, beta1s, res0s, res1s, delta1s, fs
    real scalar vvar0, lr0, brcase, idx, K, lr1, vvarv, lrv0, lrv1, phi, suplr, suplrvar, maxind, suplrcoef, i
    if (p==0) reg0 = z
    else      reg0 = (z,x)
    res0 = y - reg0*rb_invpd(quadcross(reg0,reg0))*quadcross(reg0,y)
    vvar0 = cross(res0,res0)/bigt
    tao0 = (res0:^2 :/ vvar0) :- 1
    lr0 = -(bigt/2)*(log(2*pi())+1+log(vvar0))
    brcase = rb_numcase(m,n)
    suplrx = J(brcase,1,0)
    suplrv = J(brcase,1,0)
    brcdt = J(brcase,m,0)
    brvdt = J(brcase,n,0)
    for (idx=1; idx<=brcase; idx++) {
        rb_brcvcase(m,n,idx, K,cbrind,vbrind)
        rb_estdate(y,z,q,x,p,K,bigt,h,m,n,cbrind,vbrind, brk,beta,brc2,brv2,res1)
        rb_ploglik(res1,n,brv2, lr1,tao1)
        zbar = rb_pzbar(z,m,brc2)
        if (p==0) reg1 = zbar
        else      reg1 = (zbar,x)
        resv = y - reg1*rb_invpd(quadcross(reg1,reg1))*quadcross(reg1,y)
        vvarv = cross(resv,resv)/bigt
        lrv0 = -(bigt/2)*(log(2*pi())+1+log(vvarv))
        lrv1 = rb_ploglik_v(resv,n,brv2)
        if (vrobust==0) phi = cross(tao0,tao0)/(bigt-1)
        else            phi = rb_correct1(tao0,tao1,prewhit,typekbv)
        suplrx[idx,1] = 2*(lr1-lr0) - ((phi-2)/phi)*2*(lrv1-lrv0)
        suplrv[idx,1] = (2/phi)*2*(lrv1-lrv0)
        brcdt[idx,.] = brc2'
        brvdt[idx,.] = brv2'
    }
    maxind = rb_wmax(suplrx)
    suplr = suplrx[maxind,1]
    suplrvar = suplrv[maxind,1]
    brcstar = brcdt[maxind,.]'
    brvstar = brvdt[maxind,.]'
    rb_brcvcase(m,n,maxind, K,cbrind,vbrind)
    rb_estdate(y,z,q,x,p,K,bigt,h,m,n,cbrind,vbrind, brk,beta,brc2,brv2,res1)
    if (robust==1) {
        zbar = rb_pzbar(z,m,brcstar)
        if (p==0) reg1 = zbar
        else      reg1 = (zbar,x)
        sw = sqrt(rb_ibigd(res1,n,brvstar))
        ys = sw:*y
        zbars = sw:*zbar
        reg0s = sw:*reg0
        reg1s = sw:*reg1
        beta1s = rb_invpd(quadcross(reg1s,reg1s))*quadcross(reg1s,ys)
        res0s = ys - reg0s*rb_invpd(quadcross(reg0s,reg0s))*quadcross(reg0s,ys)
        res1s = ys - reg1s*rb_invpd(quadcross(reg1s,reg1s))*quadcross(reg1s,ys)
        if (p==0) {
            vmat0 = reg0s :* res0s
            vmat1 = reg0s :* res1s
            hac = rb_correct1(vmat0,vmat1,prewhit,typekbc)
            lambda = rb_plambda(brcstar,m,bigt)
            vdel = bigt*rb_invpd(quadcross(reg1s,reg1s))*(lambda#hac)*rb_invpd(quadcross(reg1s,reg1s))
            delta1s = beta1s
        }
        else {
            xs = sw:*x
            regms = zbars - xs*rb_invpd(quadcross(xs,xs))*quadcross(xs,zbars)
            vmat0 = regms :* res0s
            vmat1 = regms :* res1s
            hac = rb_correct1(vmat0,vmat1,prewhit,typekbc)
            vdel = bigt*rb_invpd(quadcross(regms,regms))*hac*rb_invpd(quadcross(regms,regms))
            delta1s = beta1s[|1,1 \ (m+1)*q,1|]
        }
        rmat = rb_rmatq(m,q)
        Mtmp = rmat*delta1s
        fs = Mtmp'*rb_invpd(rmat*vdel*rmat')*Mtmp
        suplrcoef = (bigt-(m+1)*q-p)*fs[1,1]/bigt
        suplr = suplrcoef + suplrvar
    }
    return(suplr/(n+m))
}

end
