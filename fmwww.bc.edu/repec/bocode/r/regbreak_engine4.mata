// regbreak_engine4.mata
// Sequential sup-LR tests pslr9 (coef l+1|l | n var) and pslr10 (var l+1|l | m coef).
// Faithful port of pslr9.m and pslr10.m (Perron, Yamamoto & Zhou).
// Author: Dr Merwan Roudane (merwanroudane920@gmail.com, github.com/merwanroudane)
version 14.0

mata:

// pick brc0/brv0 for the (m,n) labeling that maximises the joint sequential
// combining statistic (shared prelude of pslr9 and pslr10)
void rb_seqpick(real matrix y, real matrix z, real scalar q, real scalar m, real scalar n,
                real matrix x, real scalar p, real scalar bigt, real scalar rob,
                real scalar prewhit, real scalar h, real scalar typek,
                real colvector res0, real scalar lr0,
                real colvector brc0, real colvector brv0)
{
    real matrix reg0, brctemp, brvtemp
    real colvector tao0, suplrx, cbrind, vbrind, brk, beta, brc2, brv2, res1, tao1
    real scalar vvar0, brcase, idx, K, lr1, lrv1, phi, maxind
    if (p==0) reg0 = z
    else      reg0 = (z,x)
    res0 = y - reg0*rb_invpd(quadcross(reg0,reg0))*quadcross(reg0,y)
    vvar0 = cross(res0,res0)/bigt
    tao0 = (res0:^2 :/ vvar0) :- 1
    lr0 = -(bigt/2)*(log(2*pi())+1+log(vvar0))
    brcase = rb_numcase(m,n)
    suplrx = J(brcase,1,0)
    brctemp = J(brcase,m,0)
    brvtemp = J(brcase,n,0)
    for (idx=1; idx<=brcase; idx++) {
        rb_brcvcase(m,n,idx, K,cbrind,vbrind)
        rb_estdate(y,z,q,x,p,K,bigt,h,m,n,cbrind,vbrind, brk,beta,brc2,brv2,res1)
        brctemp[idx,.] = brc2'
        brvtemp[idx,.] = brv2'
        lr1 = rb_ploglik_v(res1,n,brv2)
        rb_ploglik(res0,n,brv2, lrv1,tao1)
        if (rob==0) phi = cross(tao0,tao0)/(bigt-1)
        else        phi = rb_correct1(tao0,tao1,prewhit,typek)
        suplrx[idx,1] = 2*(lr1-lr0) - ((phi-2)/phi)*2*(lrv1-lr0)
    }
    maxind = rb_wmax(suplrx)
    brc0 = brctemp[maxind,.]'
    brv0 = brvtemp[maxind,.]'
}

// count / collect breaks strictly inside (starti,endi), shifted by -offset
real colvector rb_insidebreaks(real colvector brk0, real scalar starti, real scalar endi, real scalar offset)
{
    real colvector out
    real scalar j
    out = J(0,1,.)
    if (rows(brk0)==0) return(out)
    for (j=1; j<=rows(brk0); j++) {
        if (brk0[j,1]>starti & brk0[j,1]<endi) out = (out \ brk0[j,1]-offset)
    }
    return(out)
}

// ------- pslr9: SeqLR9 coef m+1|m given n variance breaks (pslr9.m) -------
real scalar rb_pslr9(real matrix y, real matrix z, real scalar q, real scalar m, real scalar n,
                     real matrix x, real scalar p, real scalar bigt, real scalar robust,
                     real scalar prewhit, real scalar h, real scalar typek, real scalar newd)
{
    real matrix reg1, datevec, segreg, segregs, segreg0, segreg1, segreg0s, segreg1s
    real matrix segzbar, segzbars, segregms, vmat0, vmat1, hac, lambda, vdel, rmat, Mtmp, zbar
    real colvector res0, brc0, brv0, res1, dv, ds, lrtest, vseg, sw, ys, zs, xs
    real colvector segy, segz, segys, segzs, segx, segxs, brvi, segres0, segres1, segres0s, segres1s
    real colvector beta1s, delta1s, fs, sub, ni_col, bigvecd, glb
    real scalar lr0, nseg, k, i, j, is, lengthi, starti, endi, ni, seglr0, seglr1, brci, suplr, news, dtmp
    rb_seqpick(y,z,q,m,n,x,p,bigt,robust,prewhit,h,typek, res0,lr0,brc0,brv0)
    if (rows(brc0)==0) zbar = z
    else               zbar = rb_pzbar(z,rows(brc0),brc0)
    if (p==0) reg1 = zbar
    else      reg1 = (zbar,x)
    res1 = y - reg1*rb_invpd(quadcross(reg1,reg1))*quadcross(reg1,y)
    nseg = m+1
    lrtest = J(nseg,1,0)
    dv = J(nseg+1,1,0)
    if (nseg>=2) dv[|2,1 \ nseg,1|] = brc0
    dv[nseg+1,1] = bigt
    ds = J(nseg,1,0)
    // variance-standardise the data using brv0 segment variances
    sw = sqrt(rb_ibigd(res1,n,brv0))
    ys = sw:*y
    zs = sw:*z
    if (p>=1) xs = sw:*x
    for (is=1; is<=nseg; is++) {
        lengthi = dv[is+1,1]-dv[is,1]
        if (lengthi>=2*h) {
            starti = dv[is,1]+1
            endi = dv[is+1,1]
            segy = y[|starti,1 \ endi,1|]
            segz = z[|starti,1 \ endi,cols(z)|]
            segys = ys[|starti,1 \ endi,1|]
            segzs = zs[|starti,1 \ endi,cols(z)|]
            if (p==0) {
                segx = J(lengthi,0,.)
                segxs = J(lengthi,0,.)
                segreg = segz
                segregs = segzs
            }
            else {
                segx = x[|starti,1 \ endi,cols(x)|]
                segxs = xs[|starti,1 \ endi,cols(x)|]
                segreg = (segz,segx)
                segregs = (segzs,segxs)
            }
            brvi = rb_insidebreaks(brv0,starti,endi,dv[is,1])
            ni = rows(brvi)
            segres0 = segy - segreg*rb_invpd(quadcross(segregs,segregs))*quadcross(segregs,segys)
            seglr0 = rb_ploglik_v(segres0,ni,brvi)
            if (p==0) rb_dating(segys,segzs,h,1,q,lengthi, sub,datevec,bigvecd)
            else      rb_datingpart(segys,segzs,segxs,h,1,p,q,lengthi, sub,datevec,bigvecd)
            brci = datevec[1,1]
            rb_estimbr(segy,segz,q,segx,p,lengthi,1,J(1,1,brci),J(1,1,0),ni,brvi,0, beta1s,segres1)
            if (robust==0) {
                seglr1 = rb_ploglik_v(segres1,ni,brvi)
                lrtest[is,1] = 2*(seglr1-seglr0)
                ds[is,1] = dv[is,1]+brci
            }
            else {
                segzbar = rb_pzbar(segz,1,J(1,1,brci))
                segzbars = rb_pzbar(segzs,1,J(1,1,brci))
                if (p==0) {
                    segreg1 = segzbar
                    segreg0 = segz
                    segreg1s = segzbars
                    segreg0s = segzs
                }
                else {
                    segreg1 = (segzbar,segx)
                    segreg0 = (segz,segx)
                    segreg1s = (segzbars,segxs)
                    segreg0s = (segzs,segxs)
                }
                beta1s = rb_invpd(quadcross(segreg1s,segreg1s))*quadcross(segreg1s,segys)
                segres0s = segy - segreg0*rb_invpd(quadcross(segreg0s,segreg0s))*quadcross(segreg0s,segys)
                segres1s = segy - segreg1*rb_invpd(quadcross(segreg1s,segreg1s))*quadcross(segreg1s,segys)
                if (p==0) {
                    vmat0 = segreg0 :* segres0s
                    vmat1 = segreg0 :* segres1s
                    hac = rb_correct1(vmat0,vmat1,prewhit,typek)
                    lambda = rb_plambda(J(1,1,brci),1,lengthi)
                    vdel = lengthi*rb_invpd(quadcross(segreg1,segreg1))*(lambda#hac)*rb_invpd(quadcross(segreg1,segreg1))
                    delta1s = beta1s
                }
                else {
                    segregms = segzbars - segxs*rb_invpd(quadcross(segxs,segxs))*quadcross(segxs,segzbars)
                    vmat0 = segregms :* segres0s
                    vmat1 = segregms :* segres1s
                    hac = rb_correct1(vmat0,vmat1,prewhit,typek)
                    vdel = lengthi*rb_invpd(quadcross(segregms,segregms))*hac*rb_invpd(quadcross(segregms,segregms))
                    delta1s = beta1s[|1,1 \ q*2,1|]
                }
                rmat = rb_rmatq(1,q)
                Mtmp = rmat*delta1s
                fs = Mtmp'*rb_invpd(rmat*vdel*rmat')*Mtmp
                lrtest[is,1] = (lengthi-2*q-p)*fs[1,1]/lengthi
            }
        }
        else {
            lrtest[is,1] = 0.0
        }
    }
    suplr = colmax(lrtest)
    news = rb_wmax(lrtest)
    newd = ds[news,1]
    return(suplr)
}

// ------- pslr10: SeqLR10 variance n+1|n given m coefficient breaks (pslr10.m) -------
real scalar rb_pslr10(real matrix y, real matrix z, real scalar q, real scalar m, real scalar n,
                      real matrix x, real scalar p, real scalar bigt, real scalar vrobust,
                      real scalar prewhit, real scalar h, real scalar typek, real scalar newd)
{
    real matrix datevec, segzbar, segreg0
    real colvector res0, brc0, brv0, dv, ds, lrtest, segy, segz, segx, brci, segbeta0, segres0, segtao0
    real colvector bigveci, segres1, segtao1, sub
    real scalar lr0, nseg, is, lengthi, starti, endi, mi, segvvar0, seglr0, brvi, seglr1, segphi, suplr, news
    rb_seqpick(y,z,q,m,n,x,p,bigt,vrobust,prewhit,h,typek, res0,lr0,brc0,brv0)
    nseg = n+1
    lrtest = J(nseg,1,0)
    dv = J(nseg+1,1,0)
    if (nseg>=2) dv[|2,1 \ nseg,1|] = brv0
    dv[nseg+1,1] = bigt
    ds = J(nseg,1,0)
    for (is=1; is<=nseg; is++) {
        lengthi = dv[is+1,1]-dv[is,1]
        if (lengthi>=2*h) {
            starti = dv[is,1]+1
            endi = dv[is+1,1]
            segy = y[|starti,1 \ endi,1|]
            segz = z[|starti,1 \ endi,cols(z)|]
            if (p==0) segx = J(lengthi,0,.)
            else      segx = x[|starti,1 \ endi,cols(x)|]
            brci = rb_insidebreaks(brc0,starti,endi,dv[is,1])
            mi = rows(brci)
            if (mi==0) segzbar = segz
            else       segzbar = rb_pzbar(segz,mi,brci)
            if (p==0) segreg0 = segzbar
            else      segreg0 = (segzbar,segx)
            segbeta0 = rb_invpd(quadcross(segreg0,segreg0))*quadcross(segreg0,segy)
            segres0 = segy - segreg0*segbeta0
            segvvar0 = cross(segres0,segres0)/lengthi
            seglr0 = -(lengthi/2)*(log(2*pi())+1+log(segvvar0))
            segtao0 = (segres0:^2 :/ segvvar0) :- 1
            bigveci = rb_stacksq(segres0,1,lengthi)
            rb_dating_M2(bigveci,h,1,lengthi, sub,datevec)
            brvi = datevec[1,1]
            rb_estimbr(segy,segz,q,segx,p,lengthi,mi,brci,J(1,1,0),1,J(1,1,brvi),0, segbeta0,segres1)
            rb_ploglik(segres1,1,J(1,1,brvi), seglr1,segtao1)
            if (vrobust==0) segphi = cross(segtao0,segtao0)/(lengthi-1)
            else            segphi = rb_correct1(segtao0,segtao1,prewhit,typek)
            lrtest[is,1] = (2/segphi)*2*(seglr1-seglr0)
            ds[is,1] = dv[is,1]+brvi
        }
        else {
            lrtest[is,1] = 0.0
        }
    }
    suplr = colmax(lrtest)
    news = rb_wmax(lrtest)
    newd = ds[news,1]
    return(suplr)
}

end
