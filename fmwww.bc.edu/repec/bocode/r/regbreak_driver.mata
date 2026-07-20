// regbreak_driver.mata
// High-level drivers called by regbreak.ado.  Read data from Stata, run the
// Bai-Perron or Perron-Yamamoto-Zhou analysis, and post results to r()-matrices.
// Author: Dr Merwan Roudane (merwanroudane920@gmail.com, github.com/merwanroudane)
version 14.0

mata:

// look up a supF / seqF critical value (rows=q regressors, cols=breaks); . if unavailable
real scalar rb_cvlook(string scalar which, real scalar eps1, real scalar sig, real scalar q, real scalar k)
{
    real matrix cv
    if (which=="cv1") cv = rb_cv1(eps1,sig)
    else              cv = rb_cv2(eps1,sig)
    if (rows(cv)==0)  return(.)
    if (q>rows(cv) | k>cols(cv)) return(.)
    return(cv[q,k])
}

real scalar rb_cvdmaxlook(real scalar eps1, real scalar sig, real scalar q)
{
    real matrix cv
    cv = rb_cvdmax(eps1,sig)
    if (rows(cv)==0 | q>rows(cv)) return(.)
    return(cv[q,1])
}

// build the z / x matrices from Stata varlists (constant handled by caller flag)
void rb_readdata(string scalar yv, string scalar zv, string scalar xv, string scalar touse,
                 real scalar addcons, real matrix y, real matrix z, real matrix x,
                 real scalar q, real scalar p)
{
    real matrix zz
    y = st_data(., yv, touse)
    if (zv=="") zz = J(rows(y),0,.)
    else        zz = st_data(., tokens(zv), touse)
    if (addcons==1) z = (J(rows(y),1,1), zz)
    else            z = zz
    q = cols(z)
    if (xv=="") {
        x = J(rows(y),0,.)
        p = 0
    }
    else {
        x = st_data(., tokens(xv), touse)
        p = cols(x)
    }
}

// ------------------------- Bai & Perron driver -------------------------
void rb_bp(string scalar yv, string scalar zv, string scalar xv, string scalar touse,
           real scalar addcons, real scalar m, real scalar eps1, real scalar prewhit,
           real scalar robust, real scalar hetdat, real scalar hetvar, real scalar hetomega,
           real scalar hetq, real scalar fixn, real scalar icsel)
{
    real matrix y, z, x, datevec, supF, seqF, supFcv, seqFcv, udcv, CI, beta, se, date
    real colvector glb, bigvec, dcol, fitted, resid, SEc, betac
    real scalar q, p, bigt, h, i, sl, ud, mBIC, mLWZ, mKT, SSR, d, nbreak
    rb_readdata(yv,zv,xv,touse,addcons, y,z,x,q,p)
    bigt = rows(y)
    h = floor(eps1*bigt)
    if (p==0) rb_dating(y,z,h,m,q,bigt, glb,datevec,bigvec)
    else      rb_datingpart(y,z,x,h,m,p,q,bigt, glb,datevec,bigvec)
    // supF(0 vs i) and its critical values
    supF = J(m,1,0)
    supFcv = J(4,m,.)
    for (i=1; i<=m; i++) {
        supF[i,1] = rb_pftest(y,z,i,q,bigt,datevec[|1,i \ i,i|],prewhit,robust,x,p,hetdat,hetvar)
        for (sl=1; sl<=4; sl++) supFcv[sl,i] = rb_cvlook("cv1",eps1,sl,q,i)
    }
    // UDmax
    ud = colmax(supF)
    udcv = J(4,1,.)
    for (sl=1; sl<=4; sl++) udcv[sl,1] = rb_cvdmaxlook(eps1,sl,q)
    // sequential supF(l+1|l)
    seqF = J(m,1,0)
    seqFcv = J(4,m,.)
    seqF[1,1] = rb_pftest(y,z,1,q,bigt,datevec[1,1],prewhit,robust,x,p,hetdat,hetvar)
    for (i=1; i<=m-1; i++) {
        seqF[i+1,1] = rb_spflp1(bigvec,datevec[|1,i \ i,i|],i+1,y,z,h,q,prewhit,robust,x,p,hetdat,hetvar)
    }
    for (i=1; i<=m; i++) {
        for (sl=1; sl<=4; sl++) seqFcv[sl,i] = rb_cvlook("cv2",eps1,sl,q,i)
    }
    // information criteria
    rb_ic(y,z,q,bigt,m,glb,datevec, mBIC,mLWZ,mKT)
    // post test results
    st_matrix("r_supF", supF)
    st_matrix("r_supFcv", supFcv)
    st_numscalar("r_udmax", ud)
    st_matrix("r_udcv", udcv)
    st_matrix("r_seqF", seqF)
    st_matrix("r_seqFcv", seqFcv)
    st_matrix("r_ic", (mBIC \ mLWZ \ mKT))
    // choose number of breaks: fixn overrides, else the selected IC
    if (fixn>=0) nbreak = fixn
    else {
        nbreak = mKT
        if (icsel==1) nbreak = mBIC
        if (icsel==2) nbreak = mLWZ
        if (icsel==3) nbreak = mKT
    }
    st_numscalar("r_nbreak", nbreak)
    // estimate model at nbreak breaks (>=1)
    if (nbreak>=1) {
        date = datevec[|1,nbreak \ nbreak,nbreak|]
        rb_estim(nbreak,q,z,y,date,robust,prewhit,hetomega,hetq,x,p,hetdat,hetvar, betac,SEc,CI,SSR,fitted,resid)
        st_matrix("r_date", date)
        st_matrix("r_ci", CI)
        st_matrix("r_beta", betac)
        st_matrix("r_se", SEc)
        st_numscalar("r_ssr", SSR)
        st_store(., st_addvar("double","_rb_fit"), touse, fitted)
    }
    st_numscalar("r_q", q)
    st_numscalar("r_p", p)
    st_numscalar("r_bigt", bigt)
}

// ------------------------- Joint PYZ driver -------------------------
// Posts supLR4 (M x N), UDmax4, supLR/supLR3 (M x (N+1)), supLR1/supLR2 (N x (M+1)),
// and the sequentially-selected # of coefficient and variance breaks + dates.
void rb_joint(string scalar yv, string scalar zv, string scalar xv, string scalar touse,
              real scalar addcons, real scalar M, real scalar N, real scalar eps1,
              real scalar robust, real scalar vrobust, real scalar prewhit,
              real scalar typekbv, real scalar typekbc, real scalar signif)
{
    real matrix y, z, x, slr4, slr3, slr2, cv4
    real colvector slr0, slr1, brc, brv, cvcol, Tc, Tv
    real scalar q, p, bigt, h, mm, nn, sl, ud4, mh, nh, sc
    real colvector slr9v, slr10v
    rb_readdata(yv,zv,xv,touse,addcons, y,z,x,q,p)
    bigt = rows(y)
    h = floor(eps1*bigt)
    brc = brv = J(0,1,.)
    // supLR4 joint, M x N
    slr4 = J(M,N,.)
    for (mm=1; mm<=M; mm++) {
        for (nn=1; nn<=N; nn++) {
            slr4[mm,nn] = rb_pslr4(y,z,q,mm,nn,x,p,bigt,robust,vrobust,prewhit,h,typekbv,typekbc, brc,brv)
        }
    }
    ud4 = colmax(vec(slr4))
    st_matrix("r_slr4", slr4)
    st_numscalar("r_ud4", ud4)
    // supLR4 critical values (q, signif) as an M x N matrix at chosen signif
    cv4 = rb_cv4(eps1,signif,q)
    st_matrix("r_cv4", cv4)
    // supLR (coef | 0 var) and supLR3 (coef | n var), stacked M x (N+1)
    slr3 = J(M,N+1,.)
    for (mm=1; mm<=M; mm++) {
        slr3[mm,1] = rb_pslr0(y,z,q,mm,x,p,bigt,robust,prewhit,h,typekbc, brc)
        for (nn=1; nn<=N; nn++) {
            slr3[mm,nn+1] = rb_pslr3(y,z,q,mm,nn,x,p,bigt,robust,prewhit,h,typekbc, brc,brv)
        }
    }
    st_matrix("r_slr3", slr3)
    // supLR1 (var | 0 coef) and supLR2 (var | m coef), stacked N x (M+1)
    slr2 = J(N,M+1,.)
    for (nn=1; nn<=N; nn++) {
        slr2[nn,1] = rb_pslr1(y,z,q,nn,x,p,bigt,vrobust,prewhit,h,typekbv, brv)
        for (mm=1; mm<=M; mm++) {
            slr2[nn,mm+1] = rb_pslr2(y,z,q,mm,nn,x,p,bigt,vrobust,prewhit,h,typekbv, brc,brv)
        }
    }
    st_matrix("r_slr2", slr2)
    // supLR / supLR3 critical values from cv1 at chosen signif: rows q, col=coef breaks
    cvcol = J(M,1,.)
    for (mm=1; mm<=M; mm++) cvcol[mm,1] = rb_cvlook("cv1",eps1,signif,q,mm)
    st_matrix("r_cv1coef", cvcol)
    cvcol = J(N,1,.)
    for (nn=1; nn<=N; nn++) cvcol[nn,1] = rb_cvlook("cv1",eps1,signif,1,nn)
    st_matrix("r_cv1var", cvcol)
    // sequential selection of # coefficient breaks given 0 var breaks (SeqLR9)
    slr9v = J(M+1,1,.)
    slr9v[1,1] = slr3[1,1]
    mh = 0
    for (mm=1; mm<=M; mm++) {
        sc = rb_pslr9(y,z,q,mm,0,x,p,bigt,vrobust,prewhit,h,typekbc, sc)
        slr9v[mm+1,1] = sc
    }
    for (mm=0; mm<=M; mm++) {
        if (slr9v[mm+1,1] <= rb_cvlook("cv2",eps1,signif,q,mm+1) | mm==M) {
            mh = mm
            break
        }
    }
    st_matrix("r_slr9", slr9v)
    st_numscalar("r_mh", mh)
    // sequential selection of # variance breaks given 0 coef breaks (SeqLR10)
    slr10v = J(N+1,1,.)
    slr10v[1,1] = slr2[1,1]
    nh = 0
    for (nn=1; nn<=N; nn++) {
        sc = rb_pslr10(y,z,q,0,nn,x,p,bigt,vrobust,prewhit,h,typekbv, sc)
        slr10v[nn+1,1] = sc
    }
    for (nn=0; nn<=N; nn++) {
        if (slr10v[nn+1,1] <= rb_cvlook("cv2",eps1,signif,1,nn+1) | nn==N) {
            nh = nn
            break
        }
    }
    st_matrix("r_slr10", slr10v)
    st_numscalar("r_nh", nh)
    // estimate the joint break dates at (mh,nh)
    rb_jdateestim(y,z,q,mh,nh,x,p,bigt,h, Tc,Tv)
    if (rows(Tc)>0) st_matrix("r_Tc", Tc)
    else            st_matrix("r_Tc", J(0,1,.))
    if (rows(Tv)>0) st_matrix("r_Tv", Tv)
    else            st_matrix("r_Tv", J(0,1,.))
    st_numscalar("r_q", q)
    st_numscalar("r_p", p)
    st_numscalar("r_bigt", bigt)
}

end
