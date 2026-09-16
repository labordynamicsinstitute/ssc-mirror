*! _tvtie_mata 1.2.0 13sep2026
*! Levent Kutlu
*! Copyright (C) 2026 Levent Kutlu. GNU GPL v3; see tvtie_license.txt.
version 16.0
program define _tvtie_mata
    version 16.0
end

mata:
mata set matastrict on

struct _tvtie_data {
    real colvector yraw, y, ids, obs, df, clust
    real matrix Xraw, Uraw, Wraw, Zraw, H, Q, info
    real matrix X, U, W, Z, Ax, Az, T
    real rowvector off, sw, umean, usd, ib, iu, ie, idelta, ic
    real scalar n, ng, neff, kh, kx, ku, p, l, ir, ik, ks, kf
    real scalar s, tn, logjac, tcenter, tscale, ndrop, hetcons, absorbscons, xcons
    string rowvector xnames, unames, wnames, znames, hnames, zdropped
}

real rowvector _tvtie_seq(real scalar first, real scalar n)
{
    if (n==0) return(J(1,0,.))
    return(first..(first+n-1))
}

void _tvtie_error(string scalar message)
{
    errprintf("%s\n", message)
    _error(459)
}

real matrix _tvtie_get(real colvector obs, string scalar names)
{
    real matrix result
    real scalar j,k
    string rowvector terms,parts
    string scalar base
    if (strtrim(names)=="") return(J(rows(obs),0,.))
    if (!strpos(names,"#")) return(st_data(obs,tokens(names)))
    terms=tokens(names)
    result=J(rows(obs),cols(terms),1)
    for (j=1;j<=cols(terms);j++) {
        if (!strpos(terms[j],"#")) result[,j]=st_data(obs,terms[j])
        else {
            parts=tokens(subinstr(terms[j],"#"," "))
            for (k=1;k<=cols(parts);k++) {
                base=subinstr(parts[k],"c.","")
                result[,j]=result[,j]:*st_data(obs,base)
            }
        }
    }
    return(result)
}

/* Equilibrated thin Householder QR; no full N by N orthogonal matrix. */
void _tvtie_qr(real matrix A, real matrix Q, real matrix R, string scalar label)
{
    real matrix hh, rr
    real rowvector scale, tau, sg
    real colvector sv
    real scalar k
    k=cols(A)
    if (k==0) {
        Q=J(rows(A),0,.)
        R=J(0,0,.)
        return
    }
    if (rows(A)<k) _tvtie_error(label+": more columns than rows")
    scale=sqrt(colsum(A:^2))
    if (min(scale)<=1e-150 | hasmissing(scale)) {
        _tvtie_error(label+": a column is absorbed or has zero variation")
    }
    hh=A:/scale
    sv=svdsv(hh)
    if (min(sv)<=1e-10*max(sv)) {
        _tvtie_error(label+": rank deficient; remove redundant or absorbed variables")
    }
    tau=.
    rr=.
    _hqrd(hh,tau,rr)
    Q=hqrdq1(hh,tau)
    sg=2:*(diagonal(rr)':>=0):-1
    Q=Q:*sg
    R=(rr:*sg'):*scale
}

real matrix _tvtie_project(struct _tvtie_data scalar D, real matrix A)
{
    real matrix result, qi
    real colvector ii
    real scalar i
    result=A
    if (D.kh & cols(A)) {
        for (i=1;i<=D.ng;i++) {
            ii=D.info[i,1]::D.info[i,2]
            qi=D.Q[ii,.]
            result[ii,.]=A[ii,.]-qi*(qi'*A[ii,.])
        }
    }
    return(result)
}

struct _tvtie_data scalar _tvtie_setup()
{
    struct _tvtie_data scalar D
    real colvector order0, keep, ii, counts, useobs, projectedone
    real matrix times
    real matrix q, r, xp, zp, wp, u0, within, tu
    real rowvector keepz, scalez, scalezp
    real scalar i, j, k, a, c, trend, nohet
    string scalar clname
    D.obs=selectindex(st_data(.,st_local("touse")))
    if (rows(D.obs)==0) _tvtie_error("No complete observations")
    D.ids=st_data(D.obs,st_local("id"))
    times=_tvtie_get(D.obs,st_local("time"))
    if (cols(times)) order0=order((D.ids,times,D.obs),(1,2,3))
    else order0=order((D.ids,D.obs),(1,2))
    D.obs=D.obs[order0]
    D.ids=D.ids[order0]
    if (cols(times)) times=times[order0]
    D.info=panelsetup(D.ids,1)
    D.ng=rows(D.info)
    trend=strtoreal(st_local("trend"))
    nohet=(st_local("nohet")!="")
    D.hetcons=(!nohet & st_local("nohetconstant")=="")
    D.kh=0
    if (!nohet) {
        D.kh=D.hetcons+trend
        if (st_local("heterogeneity")!="") {
            D.kh=D.hetcons+cols(tokens(st_local("heterogeneity")))
        }
    }
    counts=D.info[,2]-D.info[,1]:+1
    keep=J(rows(D.obs),1,1)
    D.ndrop=0
    for (i=1;i<=D.ng;i++) {
        ii=D.info[i,1]::D.info[i,2]
        if (counts[i]<=D.kh) {
            if (st_local("dropshort")=="") {
                _tvtie_error(sprintf("Panel %g has %g observations but needs more than %g. Use dropshort to exclude it.",D.ids[ii[1]],counts[i],D.kh))
            }
            keep[ii]=J(rows(ii),1,0)
            D.ndrop=D.ndrop+1
        }
        if (cols(times) & counts[i]>1) {
            for (j=2;j<=rows(ii);j++) {
                if (times[ii[j]]==times[ii[j-1]]) {
                    _tvtie_error(sprintf("Repeated time values in panel %g",D.ids[ii[1]]))
                }
            }
        }
    }
    if (D.ndrop) {
        useobs=selectindex(keep:==0)
        st_store(D.obs[useobs],st_local("touse"),J(rows(useobs),1,0))
        D.obs=select(D.obs,keep)
        D.ids=select(D.ids,keep)
        if (cols(times)) times=select(times,keep)
        D.info=panelsetup(D.ids,1)
        D.ng=rows(D.info)
    }
    D.n=rows(D.obs)
    if (D.ng<2) _tvtie_error("At least two usable panels are required")
    D.df=D.info[,2]-D.info[,1]:+1:-D.kh
    D.neff=sum(D.df)
    D.yraw=st_data(D.obs,st_local("depvar"))
    D.Xraw=_tvtie_get(D.obs,st_local("indepvars"))
    D.xnames=tokens(st_local("indepvars"))
    u0=_tvtie_get(D.obs,st_local("uhet"))
    D.Uraw=(u0,J(D.n,1,1))
    D.unames=(tokens(st_local("uhet")),"_cons")
    D.Wraw=_tvtie_get(D.obs,st_local("endogenous"))
    D.wnames=tokens(st_local("endogenous"))
    D.Zraw=_tvtie_get(D.obs,st_local("zvars"))
    D.znames=tokens(st_local("zvars"))
    D.p=cols(D.Wraw)
    D.tcenter=0
    D.tscale=1
    D.hnames=J(1,0,"")
    D.H=J(D.n,0,.)
    if (!nohet) {
        if (D.hetcons) {
            D.H=J(D.n,1,1)
            D.hnames="_cons"
        }
        if (st_local("heterogeneity")!="") {
            D.H=(D.H,_tvtie_get(D.obs,st_local("heterogeneity")))
            D.hnames=(D.hnames,tokens(st_local("heterogeneity")))
        }
        else if (trend>0) {
            if (!cols(times)) _tvtie_error("A time variable is required for trend()")
            /* Without an intercept, centering changes the restricted model. */
            if (D.hetcons) D.tcenter=mean(times)
            D.tscale=max(abs(times:-D.tcenter))
            if (D.tscale==0) _tvtie_error("The time variable is constant")
            times=(times:-D.tcenter):/D.tscale
            for (j=1;j<=trend;j++) {
                D.H=(D.H,times:^j)
                D.hnames=(D.hnames,"trend"+strofreal(j))
            }
        }
    }
    D.Q=J(D.n,D.kh,0)
    q=r=.
    for (i=1;i<=D.ng;i++) {
        ii=D.info[i,1]::D.info[i,2]
        _tvtie_qr(D.H[ii,.],q,r,sprintf("Heterogeneity basis, panel %g",D.ids[ii[1]]))
        if (D.kh) D.Q[ii,.]=q
    }
    projectedone=_tvtie_project(D,J(D.n,1,1))
    D.absorbscons=(sqrt(cross(projectedone,projectedone))<=1e-11*sqrt(D.n))
    D.xcons=(!D.absorbscons & st_local("noconstant")=="")
    if (D.xcons) {
        D.Xraw=(D.Xraw,J(D.n,1,1))
        D.xnames=(D.xnames,"_cons")
    }
    if (!D.absorbscons & D.p) {
        D.Zraw=(D.Zraw,J(D.n,1,1))
        D.znames=(D.znames,"_cons")
    }
    D.y=_tvtie_project(D,D.yraw)
    xp=_tvtie_project(D,D.Xraw)
    wp=_tvtie_project(D,D.Wraw)
    zp=_tvtie_project(D,D.Zraw)
    D.kx=cols(xp)
    if (D.kx) {
        for (j=1;j<=D.kx;j++) {
            if (sqrt(cross(xp[,j],xp[,j]))<=1e-11*max((sqrt(cross(D.Xraw[,j],D.Xraw[,j])),1e-150))) {
                _tvtie_error("Frontier regressor "+D.xnames[j]+" is absorbed or nearly absorbed by heterogeneity")
            }
        }
    }
    D.ku=cols(D.Uraw)
    _tvtie_qr(xp,q,r,"Frontier regressors")
    D.X=q*sqrt(D.neff)
    D.Ax=J(0,0,.)
    if (D.kx) D.Ax=solveupper(r,I(D.kx)*sqrt(D.neff))
    D.zdropped=J(1,0,"")
    D.Z=J(D.n,0,.)
    D.W=J(D.n,0,.)
    D.Az=J(0,0,.)
    D.sw=J(1,0,.)
    D.logjac=0
    if (D.p) {
        scalez=sqrt(colsum(D.Zraw:^2))
        scalezp=sqrt(colsum(zp:^2))
        keepz=selectindex(scalezp:>1e-12:*(1:+scalez))
        for (j=1;j<=cols(D.znames);j++) {
            if (!any(keepz:==j)) D.zdropped=(D.zdropped,D.znames[j])
        }
        if (!cols(keepz)) _tvtie_error("All instruments are absorbed by heterogeneity")
        D.Zraw=D.Zraw[,keepz]
        D.znames=D.znames[keepz]
        zp=zp[,keepz]
        D.l=cols(zp)
        if (D.l<D.p) _tvtie_error("Too few instruments survive the projection")
        _tvtie_qr(zp,q,r,"Reduced-form instruments")
        D.Z=q*sqrt(D.neff)
        D.Az=solveupper(r,I(D.l)*sqrt(D.neff))
        D.sw=sqrt(colsum(wp:^2)/D.neff)
        if (min(D.sw)<=1e-12) _tvtie_error("An endogenous variable is absorbed by heterogeneity")
        D.W=wp:/D.sw
        D.logjac=sum(ln(D.sw))
        k=0
        for (j=1;j<=cols(D.znames);j++) {
            if (any(tokens(st_local("instruments")):==D.znames[j])) k=k+1
        }
        if (k<D.p) _tvtie_error("Too few excluded instruments survive the projection for the declared endogenous variables")
    }
    else D.l=0
    D.umean=J(1,0,.)
    D.usd=J(1,0,.)
    if (cols(u0)) {
        D.umean=mean(u0)
        D.usd=sqrt(colsum((u0:-D.umean):^2)/D.n)
        if (min(D.usd)<=1e-12) _tvtie_error("uhet() contains a constant; its scale normalization is already estimated")
    }
    D.U=J(D.n,1,1)
    if (cols(u0)) D.U=((u0:-D.umean):/D.usd,J(D.n,1,1))
    _tvtie_qr(D.U,q,r,"uhet() and its scale constant")
    if (D.absorbscons) {
        within=u0
        for (i=1;i<=D.ng;i++) {
            ii=D.info[i,1]::D.info[i,2]
            if (cols(u0)) within[ii,.]=u0[ii,.]:-mean(u0[ii,.])
        }
        if (!cols(u0)) {
            _tvtie_error("Inefficiency is unidentified with constant scaling and individual effects; specify time-varying uhet()")
        }
        if (sqrt(sum(within:^2))<=1e-10*(1+sqrt(sum(u0:^2)))) {
            _tvtie_error("Inefficiency is unidentified: uhet() has no within-panel variation")
        }
    }
    D.s=1
    if (st_local("cost")!="") D.s=-1
    D.tn=(st_local("distribution")=="tnormal")
    j=1
    D.ib=_tvtie_seq(j,D.kx);j=j+D.kx
    D.iu=_tvtie_seq(j,D.ku);j=j+D.ku
    D.ir=j;j=j+1
    D.ik=0
    if (D.tn) {
        D.ik=j
        j=j+1
    }
    D.ie=_tvtie_seq(j,D.p);j=j+D.p
    D.idelta=_tvtie_seq(j,D.l*D.p);j=j+D.l*D.p
    D.ks=j-1
    D.ic=_tvtie_seq(j,D.p*(D.p+1)/2)
    D.kf=D.ks+cols(D.ic)
    if (D.neff<=D.kf) _tvtie_error("Too few transformed observations for this parameterization")
    D.T=I(D.kf)
    D.off=J(1,D.kf,0)
    if (D.kx) D.T[D.ib,D.ib]=D.Ax
    tu=I(D.ku)
    if (D.ku>1) {
        k=D.ku-1
        tu[1..k,1..k]=diag(1:/D.usd)
        tu[D.ku,1..k]=-D.umean:/D.usd
    }
    D.T[D.iu,D.iu]=tu
    if (D.p) {
        D.T[D.ie,D.ie]=diag(1:/D.sw)
        D.T[D.idelta,D.idelta]=diag(D.sw)#D.Az
        k=1
        for (i=1;i<=D.p;i++) {
            for (j=1;j<=i;j++) {
                a=D.ic[k]
                if (i==j) D.off[a]=ln(D.sw[i])
                else D.T[a,a]=D.sw[i]
                k=k+1
            }
        }
    }
    D.clust=D.ids[D.info[,1]]
    clname=st_local("clustvar")
    if (clname!="") {
        keep=st_data(D.obs,clname)
        for (i=1;i<=D.ng;i++) {
            ii=D.info[i,1]::D.info[i,2]
            if (min(keep[ii])!=max(keep[ii])) _tvtie_error("Each panel must be contained in a single variance cluster")
            D.clust[i]=keep[ii[1]]
        }
    }
    return(D)
}

/* Mean, variance and inverse Mills ratio of N(z,1) left-truncated at zero. */
real rowvector _tvtie_tail(real scalar z)
{
    real scalar c, dc, den, j, t, r, m, v
    if (z < -8) {
        t=-z
        c=dc=0
        for (j=80;j>=1;j--) {
            den=t+c
            dc=-j*(1+dc)/(den^2)
            c=j/den
        }
        return((c,-dc,t+c))
    }
    r=exp(-0.5*z*z-0.5*ln(2*pi())-lnnormal(z))
    m=z+r
    v=1-r*m
    if (v<0 & v> -1e-12) v=0
    return((m,v,r))
}

real scalar _tvtie_logS(real scalar z)
{
    real rowvector tm
    if (z< -8) {
        tm=_tvtie_tail(z)
        return(-0.5*ln(2*pi())-ln(tm[3]))
    }
    return(0.5*z*z+lnnormal(z))
}

real rowvector _tvtie_pack(real matrix C)
{
    real rowvector result
    real scalar i,j,k,p
    p=rows(C)
    result=J(1,p*(p+1)/2,.)
    k=1
    for (i=1;i<=p;i++) {
        for (j=1;j<=i;j++) {
            if (i==j) result[k]=ln(C[i,j])
            else result[k]=C[i,j]
            k=k+1
        }
    }
    return(result)
}

real matrix _tvtie_unpack(real rowvector packed, real scalar p)
{
    real matrix C
    real scalar i,j,k
    C=J(p,p,0)
    k=1
    for (i=1;i<=p;i++) {
        for (j=1;j<=i;j++) {
            if (i==j) C[i,j]=exp(packed[k])
            else C[i,j]=packed[k]
            k=k+1
        }
    }
    return(C)
}

real rowvector _tvtie_profile_full(struct _tvtie_data scalar D, real rowvector b)
{
    real matrix F,C,delta
    if (cols(b)!=D.ks | hasmissing(b)) return(J(1,D.kf,.))
    if (!D.p) return(b)
    delta=rowshape(b[D.idelta],D.p)'
    F=D.W-D.Z*delta
    C=cholesky(cross(F,F)/D.neff)
    if (hasmissing(C)) return(J(1,D.kf,.))
    if (min(diagonal(C))<1e-10) return(J(1,D.kf,.))
    return((b,_tvtie_pack(C)))
}

/* Exact full likelihood and panel scores. Covariance parameters are not
   profiled here, so the same scores give the full-information sandwich. */
void _tvtie_full(struct _tvtie_data scalar D, real rowvector b,
                real colvector value, real matrix G)
{
    real colvector loga,a,g,e,ii,ei,gi,rr,ge,ggs
    real matrix delta,F,C,Ci,Oi,Fw,fiw,fi,gd,gc
    real rowvector eta,prior,tm
    real scalar r2,kap,i,j,k,q,gg,eg,A,sd,m,z,ew,vw,ew2,base,qf,ld
    value=J(D.ng,1,.)
    G=J(D.ng,D.kf,0)
    if (hasmissing(b)) return
    loga=0.5*D.U*b[D.iu]'
    if (max(abs(loga))>300 | abs(b[D.ir])>500) return
    a=exp(loga)
    g=_tvtie_project(D,a)
    r2=exp(b[D.ir])
    kap=0
    if (D.tn) kap=b[D.ik]
    prior=_tvtie_tail(kap)
    e=D.y
    if (D.kx) e=e-D.X*b[D.ib]'
    F=J(D.n,0,.)
    eta=J(1,0,.)
    Ci=Oi=Fw=J(0,0,.)
    ld=0
    if (D.p) {
        delta=rowshape(b[D.idelta],D.p)'
        F=D.W-D.Z*delta
        eta=b[D.ie]
        e=e-F*eta'
        C=_tvtie_unpack(b[D.ic],D.p)
        if (hasmissing(C) | min(diagonal(C))<=1e-150) return
        Ci=solvelower(C,I(D.p))
        Oi=Ci'*Ci
        Fw=F*Ci'
        ld=sum(ln(diagonal(C)))
    }
    for (i=1;i<=D.ng;i++) {
        ii=D.info[i,1]::D.info[i,2]
        q=D.df[i]
        ei=e[ii]
        gi=g[ii]
        gg=cross(gi,gi)
        eg=cross(ei,gi)
        A=1+gg/r2
        sd=1/sqrt(A)
        m=(kap-D.s*eg/r2)/A
        z=m/sd
        tm=_tvtie_tail(z)
        ew=sd*tm[1]
        vw=sd*sd*tm[2]
        ew2=ew*ew+vw
        base=-0.5*q*(ln(2*pi())+b[D.ir])-0.5*ln(A)
        if (kap< -8) {
            value[i]=base-0.5*cross(ei,ei)/r2+_tvtie_logS(z)-_tvtie_logS(kap)
        }
        else {
            rr=ei+D.s*gi*m
            qf=cross(rr,rr)/r2+(m-kap)^2
            value[i]=base-0.5*qf+lnnormal(z)-lnnormal(kap)
        }
        if (D.p) {
            fiw=Fw[ii,.]
            value[i]=value[i]-0.5*q*D.p*ln(2*pi())-q*(ld+D.logjac)-0.5*sum(fiw:^2)
        }
        rr=ei+D.s*gi*ew
        ge=-rr/r2
        ggs=-(D.s*ei*ew+gi*ew2)/r2
        if (D.kx) G[i,D.ib]=(-D.X[ii,.]'*ge)'
        G[i,D.iu]=(0.5*D.U[ii,.]'*(a[ii]:*ggs))'
        G[i,D.ir]=0.5*((cross(rr,rr)+gg*vw)/r2-q)
        if (D.tn) G[i,D.ik]=ew-prior[1]
        if (D.p) {
            fi=F[ii,.]
            G[i,D.ie]=(-fi'*ge)'
            gd=D.Z[ii,.]'*(fi*Oi+ge*eta)
            G[i,D.idelta]=vec(gd)'
            gc=Ci'*(cross(fiw,fiw)-q*I(D.p))
            k=1
            for (j=1;j<=D.p;j++) {
                for (q=1;q<=j;q++) {
                    if (j==q) G[i,D.ic[k]]=gc[j,q]*C[j,j]
                    else G[i,D.ic[k]]=gc[j,q]
                    k=k+1
                }
            }
        }
    }
    if (hasmissing(value) | hasmissing(G)) value=J(D.ng,1,.)
}

/* Envelope score for the exactly concentrated reduced-form covariance. */
void _tvtie_eval(real scalar todo, real rowvector b,
                 struct _tvtie_data scalar D, real scalar value,
                 real rowvector gradient, real matrix Hessian)
{
    real rowvector full
    real colvector vv
    real matrix G
    full=_tvtie_profile_full(D,b)
    _tvtie_full(D,full,vv,G)
    if (hasmissing(vv)) {
        value=.
        return
    }
    value=sum(vv)/D.neff
    if (todo>=1) gradient=colsum(G[,1..D.ks])/D.neff
}

real rowvector _tvtie_initial(struct _tvtie_data scalar D,
                             real scalar start, real scalar seed)
{
    real rowvector b,direction
    real matrix delta,F,xf
    real colvector fit0,residual,g0
    real scalar var,gvar,j,kap
    b=J(1,D.ks,0)
    F=J(D.n,0,.)
    if (D.p) {
        delta=cross(D.Z,D.W)/D.neff
        b[D.idelta]=vec(delta)'
        F=D.W-D.Z*delta
    }
    xf=(D.X,F)
    residual=D.y
    if (cols(xf)) {
        fit0=qrsolve(xf,D.y)
        if (hasmissing(fit0)) fit0=J(cols(xf),1,0)
        if (D.kx) b[D.ib]=fit0[1..D.kx]'
        if (D.p) b[D.ie]=fit0[(D.kx+1)..(D.kx+D.p)]'
        residual=D.y-xf*fit0
    }
    var=max((cross(residual,residual)/D.neff,1e-8))
    if (D.ku>1) {
        direction=J(1,D.ku-1,0)
        for (j=1;j<D.ku;j++) {
            direction[j]=sin((start+1)*(j+0.37)*1.61803398875+mod(seed,997)*0.013)
        }
        direction=direction/max((sqrt(sum(direction:^2)),1e-8))
        b[D.iu[1..(D.ku-1)]]=direction*(0.8+0.4*mod(start,4))
    }
    if (D.tn) {
        direction=(0,1.5,-1.5,0.5)
        kap=direction[mod(start,4)+1]
        b[D.ik]=kap
    }
    g0=_tvtie_project(D,exp(0.5*D.U*b[D.iu]'))
    gvar=max((cross(g0,g0)/D.neff,1e-8))
    b[D.iu[D.ku]]=ln(0.4*var/gvar)
    b[D.ir]=ln(0.6*var)
    return(b)
}

real matrix _tvtie_information(struct _tvtie_data scalar D, real rowvector b)
{
    real matrix H,Gp,Gm
    real colvector vp,vm
    real rowvector bp,bm
    real scalar j,step
    H=J(D.kf,D.kf,.)
    for (j=1;j<=D.kf;j++) {
        step=(epsilon(1)^(1/3))*(1+abs(b[j]))
        bp=bm=b
        bp[j]=bp[j]+step
        bm[j]=bm[j]-step
        _tvtie_full(D,bp,vp,Gp)
        _tvtie_full(D,bm,vm,Gm)
        if (hasmissing(vp) | hasmissing(vm)) return(J(D.kf,D.kf,.))
        H[,j]=-(colsum(Gp)-colsum(Gm))'/(2*step)
    }
    return((H+H')/2)
}

string matrix _tvtie_stripe(struct _tvtie_data scalar D)
{
    string matrix stripe
    real scalar i,j,k
    stripe=J(D.kf,2,"")
    if (D.kx) {
        stripe[D.ib,1]=J(D.kx,1,"frontier")
        stripe[D.ib,2]=D.xnames'
    }
    stripe[D.iu,1]=J(D.ku,1,"usigma")
    stripe[D.iu,2]=D.unames'
    stripe[D.ir,.]=("lnsig2r","_cons")
    if (D.tn) stripe[D.ik,.]=("kappa","_cons")
    if (D.p) {
        stripe[D.ie,1]=J(D.p,1,"eta")
        stripe[D.ie,2]=D.wnames'
        for (j=1;j<=D.p;j++) {
            for (i=1;i<=D.l;i++) {
                k=D.idelta[(j-1)*D.l+i]
                stripe[k,.]=("rf"+strofreal(j),D.znames[i])
            }
        }
        k=1
        for (i=1;i<=D.p;i++) {
            for (j=1;j<=i;j++) {
                if (i==j) stripe[D.ic[k],.]=("chol","lnL"+strofreal(i)+"_"+strofreal(j))
                else stripe[D.ic[k],.]=("chol","L"+strofreal(i)+"_"+strofreal(j))
                k=k+1
            }
        }
    }
    return(stripe)
}

real matrix _tvtie_firststage(struct _tvtie_data scalar D)
{
    real matrix result,Z0,delta,F,restricted,q,r
    real rowvector j0
    real scalar i,j,nex,df2,ssef,sser,diff
    result=J(D.p,5,.)
    if (!D.p) return(result)
    j0=J(1,0,.)
    nex=0
    for (j=1;j<=D.l;j++) {
        if (any(tokens(st_local("instruments")):==D.znames[j])) nex=nex+1
        else j0=(j0,j)
    }
    delta=cross(D.Z,D.W)/D.neff
    F=D.W-D.Z*delta
    restricted=D.W
    if (cols(j0)) {
        Z0=_tvtie_project(D,D.Zraw[,j0])
        q=r=.
        _tvtie_qr(Z0,q,r,"Included instruments")
        restricted=D.W-q*(q'*D.W)
    }
    df2=D.neff-D.l
    for (i=1;i<=D.p;i++) {
        ssef=cross(F[,i],F[,i])
        sser=cross(restricted[,i],restricted[,i])
        diff=max((sser-ssef,0))
        if (sser>0 & ssef>0 & df2>0 & nex>0) {
            result[i,1]=(diff/nex)/(ssef/df2)
            result[i,2]=Ftail(nex,df2,result[i,1])
            result[i,3]=diff/sser
        }
        result[i,4]=nex
        result[i,5]=df2
    }
    return(result)
}

void _tvtie_fit(string scalar bname, string scalar vname, string scalar oimname,
                string scalar runname, string scalar diagname,
                string scalar fsname, string scalar omname, string scalar delname)
{
    struct _tvtie_data scalar D
    transmorphic S
    real rowvector initial,b,best,full,raw,gradient,eig,bbackup
    real colvector vv,di,ii,cc,go,gh,aa
    real matrix G,H,V,VR,meat,clusterG,ci,runs,diagnostics,delta,omega,C
    real scalar start,nstarts,seed,iterations,tol,rc,val,bestval,scoremax,accept,ncl,khits,ratio,j,sr2,su2,mu,sv2,vbackup,sbackup
    real scalar rc_bfgs,rc_nr,niter_nr,used_bfgs
    string scalar trace,from,vcetype
    string matrix stripe
    D=_tvtie_setup()
    nstarts=strtoreal(st_local("starts"))
    seed=strtoreal(st_local("seed"))
    iterations=strtoreal(st_local("iterate"))
    tol=strtoreal(st_local("tolerance"))
    trace="value"
    if (st_local("nolog")!="") trace="none"
    from=st_local("from")
    bestval=.
    best=J(1,D.ks,.)
    runs=J(nstarts,6,.)
    for (start=0;start<nstarts;start++) {
        initial=_tvtie_initial(D,start,seed)
        if (start==0 & from!="") {
            raw=st_matrix(from)
            if (rows(raw)!=1 | cols(raw)!=D.kf | hasmissing(raw)) {
                _tvtie_error("from() must be a finite row vector in the documented full e(b) order")
            }
            initial=lusolve(D.T,(raw-D.off)')'
            initial=initial[1..D.ks]
        }
        if (trace!="none") printf("\nStarting value %g of %g\n",start+1,nstarts)
        S=optimize_init()
        optimize_init_evaluator(S,&_tvtie_eval())
        optimize_init_evaluatortype(S,"d1")
        optimize_init_argument(S,1,D)
        optimize_init_which(S,"max")
        optimize_init_technique(S,"bfgs")
        optimize_init_params(S,initial)
        optimize_init_conv_maxiter(S,iterations)
        optimize_init_conv_ptol(S,tol)
        optimize_init_conv_vtol(S,tol*0.1)
        optimize_init_conv_nrtol(S,tol)
        optimize_init_tracelevel(S,trace)
        optimize_init_conv_warning(S,"off")
        rc=_optimize(S)
        rc_bfgs=optimize_result_returncode(S)
        b=optimize_result_params(S)
        if (cols(b)!=D.ks | hasmissing(b)) b=initial
        bbackup=b
        full=_tvtie_profile_full(D,bbackup)
        _tvtie_full(D,full,vv,G)
        vbackup=sbackup=.
        if (!hasmissing(vv)) {
            vbackup=sum(vv)
            sbackup=max(abs(colsum(G)))/D.neff
        }
        /* Keep the valid quasi-Newton endpoint if refinement fails. */
        optimize_init_params(S,b)
        optimize_init_technique(S,"nr")
        optimize_init_singularHmethod(S,"hybrid")
        optimize_init_conv_maxiter(S,min((iterations,100)))
        rc=_optimize(S)
        rc_nr=optimize_result_returncode(S)
        niter_nr=optimize_result_iterations(S)
        b=optimize_result_params(S)
        full=_tvtie_profile_full(D,b)
        _tvtie_full(D,full,vv,G)
        val=scoremax=.
        if (!hasmissing(vv)) {
            val=sum(vv)
            scoremax=max(abs(colsum(G)))/D.neff
        }
        used_bfgs=0
        if (vbackup<.) {
            if (val==. | val<vbackup-1e-8 |
                (sbackup<=max((20*tol,2e-6)) & scoremax>max((20*tol,2e-6)))) {
                b=bbackup
                used_bfgs=1
                val=vbackup
                scoremax=sbackup
            }
        }
        accept=(val<. & scoremax<=max((20*tol,2e-6)))
        rc=rc_nr
        if (used_bfgs) rc=rc_bfgs
        runs[start+1,.]=(start+1,val,scoremax,accept,niter_nr,rc)
        if (accept) {
            if (bestval==. | val>bestval) {
                bestval=val
                best=b
            }
        }
    }
    st_matrix(runname,runs)
    if (hasmissing(best)) _tvtie_error("No sufficiently stationary solution; increase starts()/iterate() or reconsider identification")
    full=_tvtie_profile_full(D,best)
    _tvtie_full(D,full,vv,G)
    H=_tvtie_information(D,full)
    if (hasmissing(H) | min(diagonal(H))<=0) _tvtie_error("Observed information is not positive definite; standard errors are not reported")
    di=sqrt(diagonal(H))
    eig=symeigenvalues(H:/(di*di'))
    if (hasmissing(eig) | min(eig)<=1e-9) _tvtie_error("Observed information is singular or nearly singular; no reliable covariance matrix")
    V=cholinv(H)
    if (hasmissing(V)) _tvtie_error("The observed information could not be inverted reliably")
    vcetype=st_local("vcetype")
    ncl=D.ng
    if (vcetype=="oim") VR=V
    else {
        go=order(D.clust,1)
        cc=D.clust[go]
        ci=panelsetup(cc,1)
        ncl=rows(ci)
        if (ncl<=D.kf) _tvtie_error("Too few independent clusters for a full-rank sandwich covariance")
        clusterG=J(ncl,D.kf,0)
        for (j=1;j<=ncl;j++) {
            ii=ci[j,1]::ci[j,2]
            clusterG[j,.]=colsum(G[go[ii],.])
        }
        meat=cross(clusterG,clusterG)
        VR=V*meat*V
    }
    raw=full*D.T'+D.off
    stripe=_tvtie_stripe(D)
    st_matrix(bname,raw)
    st_matrixcolstripe(bname,stripe)
    VR=D.T*VR*D.T'
    VR=(VR+VR')/2
    st_matrix(vname,VR)
    st_matrixrowstripe(vname,stripe)
    st_matrixcolstripe(vname,stripe)
    V=D.T*V*D.T'
    V=(V+V')/2
    st_matrix(oimname,V)
    st_matrixrowstripe(oimname,stripe)
    st_matrixcolstripe(oimname,stripe)
    aa=exp(0.5*D.U*full[D.iu]')
    gh=_tvtie_project(D,aa)
    ratio=cross(gh,gh)/cross(aa,aa)
    khits=sum(runs[,4])
    sr2=exp(raw[D.ir])
    su2=exp(raw[D.iu[D.ku]])
    mu=0
    if (D.tn) mu=raw[D.ik]*sqrt(su2)
    sv2=sr2
    if (D.p) {
        C=_tvtie_unpack(raw[D.ic],D.p)
        omega=C*C'
        sv2=sr2+raw[D.ie]*omega*raw[D.ie]'
    }
    diagnostics=(D.n,D.ng,D.neff,D.kh,D.kf,D.ks,sum(vv),max(abs(colsum(G)))/D.neff,max(eig)/min(eig),ratio,khits,D.ndrop,ncl,D.tcenter,D.tscale,sr2,su2,mu,sv2)
    st_matrix(diagname,diagnostics)
    if (D.p) st_matrix(fsname,_tvtie_firststage(D))
    st_local("zvars_used",invtokens(select(D.znames,D.znames:!="_cons")))
    st_local("zvars_dropped",invtokens(D.zdropped))
    if (D.p) {
        delta=rowshape(raw[D.idelta],D.p)'
        C=_tvtie_unpack(raw[D.ic],D.p)
        omega=C*C'
        st_matrix(delname,delta)
        st_matrix(omname,omega)
    }
    st_local("_tvtie_hetcons",strofreal(D.hetcons))
    st_local("_tvtie_absorbscons",strofreal(D.absorbscons))
    st_local("_tvtie_xcons",strofreal(D.xcons))
    st_local("_tvtie_wnames",invtokens(D.wnames))
    st_local("_tvtie_znames",invtokens(D.znames))
    st_local("_tvtie_signature",_tvtie_signature(D))
}

/* Canonical row order keeps the sample check invariant to sorting. */
string scalar _tvtie_signature(struct _tvtie_data scalar D)
{
    real matrix A
    A=(D.ids,_tvtie_get(D.obs,st_local("time")),D.yraw,D.Xraw,D.Uraw,D.Wraw,D.Zraw,D.H)
    A=A[order(A,1..cols(A)),.]
    return(strofreal(hash1(A,.,1),"%21.0f")+":"+strofreal(hash1(A',.,1),"%21.0f"))
}

real scalar _tvtie_log1m(real scalar p)
{
    if (p<=0 | p>=1) return(.)
    if (p<0.0001) return(-p*(1+p*(0.5+p*(1/3+p*(0.25+p/5)))))
    return(ln(1-p))
}

real scalar _tvtie_invlogphi(real scalar lp)
{
    real scalar z,j,step,t
    real rowvector tm
    if (lp>=0 | lp==.) return(.)
    if (lp>ln(0.5)) {
        if (lp> -0.0001) t=-lp*(1+lp*(0.5+lp*(1/6+lp/24)))
        else t=1-exp(lp)
        return(-invnormal(t))
    }
    if (lp> -700) return(invnormal(exp(lp)))
    z=-sqrt(-2*lp)
    for (j=1;j<=30;j++) {
        tm=_tvtie_tail(z)
        step=(lnnormal(z)-lp)/tm[3]
        z=z-step
        if (abs(step)<1e-12*(1+abs(z))) break
    }
    return(z)
}

real matrix _tvtie_predictions(struct _tvtie_data scalar D, real rowvector raw,
                               real matrix alpha, real scalar probability, real scalar tequantile)
{
    real rowvector b,tm
    real colvector a,g,e,xb,cf,ii,ew,vw,mp,sp,u,te,meante,fe,fitted,uq
    real matrix delta,q,r,result
    real scalar r2,kap,i,j,A,sd,m,z,logte,su,quant,logtail,difference
    b=lusolve(D.T,(raw-D.off)')'
    a=exp(0.5*D.U*b[D.iu]')
    g=_tvtie_project(D,a)
    r2=exp(b[D.ir])
    kap=0
    if (D.tn) kap=b[D.ik]
    xb=J(D.n,1,0)
    e=D.y
    if (D.kx) {
        xb=D.Xraw*raw[D.ib]'
        e=e-D.X*b[D.ib]'
    }
    cf=J(D.n,1,0)
    if (D.p) {
        delta=rowshape(b[D.idelta],D.p)'
        cf=(D.W-D.Z*delta)*b[D.ie]'
        e=e-cf
    }
    ew=vw=mp=sp=J(D.n,1,.)
    for (i=1;i<=D.ng;i++) {
        ii=D.info[i,1]::D.info[i,2]
        A=1+cross(g[ii],g[ii])/r2
        sd=1/sqrt(A)
        m=(kap-D.s*cross(e[ii],g[ii])/r2)/A
        tm=_tvtie_tail(m/sd)
        ew[ii]=J(rows(ii),1,sd*tm[1])
        vw[ii]=J(rows(ii),1,sd*sd*tm[2])
        mp[ii]=J(rows(ii),1,m)
        sp[ii]=J(rows(ii),1,sd)
    }
    u=a:*ew
    te=exp(-u)
    meante=uq=J(D.n,1,.)
    for (j=1;j<=D.n;j++) {
        z=mp[j]/sp[j]
        logte=_tvtie_logS(z-a[j]*sp[j])-_tvtie_logS(z)
        if (logte>1e-8) _tvtie_error("Posterior efficiency is numerically invalid")
        meante[j]=exp(min((logte,0)))
        if (probability>0 & probability<1) {
            logtail=_tvtie_log1m(probability)
            if (tequantile) logtail=ln(probability)
            quant=_tvtie_invlogphi(logtail+lnnormal(z))
            difference=z-quant
            if (difference< -1e-8*(1+abs(z)) | difference==.) _tvtie_error("Conditional quantile is numerically invalid")
            uq[j]=a[j]*sp[j]*max((difference,0))
        }
    }
    alpha=J(D.ng,D.kh,.)
    fe=J(D.n,1,0)
    if (D.kh) {
        q=r=.
        for (i=1;i<=D.ng;i++) {
            ii=D.info[i,1]::D.info[i,2]
            _tvtie_qr(D.H[ii,.],q,r,"Heterogeneity recovery")
            alpha[i,.]=solveupper(r,q'*(D.yraw[ii]-xb[ii]+D.s*u[ii]))'
            fe[ii]=D.H[ii,.]*alpha[i,.]'
        }
    }
    fitted=xb+fe+cf-D.s*u
    su=exp(raw[D.iu[D.ku]]/2)
    result=(xb,u,te,meante,fe,cf,fitted,D.yraw-fitted,a/su,su*ew,su*sqrt(vw),uq)
    return(result)
}

void _tvtie_predict(string scalar target, string scalar targetuse,
                    string scalar statistic, real scalar probability)
{
    struct _tvtie_data scalar D
    real matrix result,alpha
    real colvector take,index
    real scalar column
    D=_tvtie_setup()
    if (D.n!=st_numscalar("e(N)") | D.ng!=st_numscalar("e(N_g)")) {
        _tvtie_error("The estimation sample is no longer available unchanged")
    }
    if (_tvtie_signature(D)!=st_global("e(data_signature)")) {
        _tvtie_error("The estimation variables have changed; restore the original data before prediction")
    }
    result=_tvtie_predictions(D,st_matrix("e(b)"),alpha,probability,statistic=="tequantile")
    column=1
    if (statistic=="inefficiency") column=2
    if (statistic=="efficiency") column=3
    if (statistic=="meante") column=4
    if (statistic=="fe") column=5
    if (statistic=="cf") column=6
    if (statistic=="fitted") column=7
    if (statistic=="residuals") column=8
    if (statistic=="uscale") column=9
    if (statistic=="u0") column=10
    if (statistic=="u0sd") column=11
    if (statistic=="uquantile" | statistic=="tequantile") column=12
    if (statistic=="tequantile") result[,12]=exp(-result[,12])
    take=st_data(D.obs,targetuse)
    index=selectindex(take)
    if (rows(index)) st_store(D.obs[index],target,result[index,column])
}

void _tvtie_heterogeneity(string scalar resultname, string scalar idname)
{
    struct _tvtie_data scalar D
    real matrix result,alpha
    D=_tvtie_setup()
    if (!D.kh) _tvtie_error("No individual effects were fitted")
    if (_tvtie_signature(D)!=st_global("e(data_signature)")) _tvtie_error("The estimation variables have changed")
    result=_tvtie_predictions(D,st_matrix("e(b)"),alpha,0.5,0)
    st_matrix(resultname,alpha)
    st_matrix(idname,D.ids[D.info[,1]])
    st_matrixcolstripe(resultname,(J(D.kh,1,""),D.hnames'))
}

/* Residual-regression F diagnostic, fitted under the stated null model. */
void _tvtie_hettest(string scalar target)
{
    real colvector obs,id,v,tm,ii,err
    real matrix info,H,Q,R
    real scalar n,ng,i,j,k,degree,rss0,rss1,q,df,stat,center,scale,tv
    obs=selectindex(st_data(.,st_local("touse")))
    id=st_data(obs,st_local("id"))
    obs=obs[order(id,1)]
    id=st_data(obs,st_local("id"))
    v=st_data(obs,st_local("response"))
    n=rows(obs)
    info=panelsetup(id,1)
    ng=rows(info)
    H=J(n,1,1)
    degree=strtoreal(st_local("trend"))
    tv=(st_local("timevarying")!="")
    if (st_local("heterogeneity")!="") H=(H,st_data(obs,tokens(st_local("heterogeneity"))))
    else if (degree>0) {
        tm=st_data(obs,st_local("time"))
        center=mean(tm)
        scale=max(abs(tm:-center))
        if (scale<=0 | hasmissing(tm)) _tvtie_error("The heterogeneity test needs a nonmissing, varying time variable")
        tm=(tm:-center)/scale
        for (j=1;j<=degree;j++) H=(H,tm:^j)
    }
    if (hasmissing(H) | hasmissing(v)) _tvtie_error("The diagnostic must use the complete estimation sample")
    k=cols(H)
    df=n-ng*k
    q=ng*k-1
    if (tv) q=ng*(k-1)
    if (df<=0 | q<=0) _tvtie_error("Insufficient residual degrees of freedom for this heterogeneity test")
    rss0=cross(v:-mean(v),v:-mean(v))
    if (tv) rss0=0
    rss1=0
    Q=R=.
    for (i=1;i<=ng;i++) {
        ii=info[i,1]::info[i,2]
        if (rows(ii)<=k) _tvtie_error("Each panel needs more observations than the alternative heterogeneity rank")
        _tvtie_qr(H[ii,.],Q,R,"Heterogeneity test basis")
        err=v[ii]-Q*(Q'*v[ii])
        rss1=rss1+cross(err,err)
        if (tv) rss0=rss0+cross(v[ii]:-mean(v[ii]),v[ii]:-mean(v[ii]))
    }
    if (rss1<=0 | rss0<rss1-1e-8*(1+rss0)) _tvtie_error("Degenerate residual regression")
    stat=(max((rss0-rss1,0))/q)/(rss1/df)
    st_matrix(target,(stat,q,df,Ftail(q,df,stat),n,ng,rss0,rss1))
}

/* Loading check for the QR and truncated-normal routines. */
void _tvtie_smoke()
{
    real matrix A,Q,R
    real rowvector tm
    A=(1,0\1,1\1,2\1,3)
    Q=R=.
    _tvtie_qr(A,Q,R,"QR loading check")
    assert(rows(Q)==4 & cols(Q)==2)
    assert(max(abs(A-Q*R))<1e-11)
    assert(max(abs(Q'*Q-I(2)))<1e-11)
    tm=_tvtie_tail(0)
    assert(abs(tm[1]-sqrt(2/pi()))<1e-12)
}

real rowvector _tvtie_boot_null(struct _tvtie_data scalar D, real rowvector original, real rowvector exogenous)
{
    real rowvector raw,b,full
    raw=original
    raw[1..cols(exogenous)]=exogenous
    raw[D.ie]=J(1,D.p,0)
    b=lusolve(D.T,(raw-D.off)')'
    b[D.idelta]=vec(D.Z'*D.W/D.neff)'
    full=_tvtie_profile_full(D,b[1..D.ks])
    return(full*D.T'+D.off)
}

void _tvtie_boot_draw(struct _tvtie_data scalar D, real rowvector raw)
{
    real matrix F,W,C,delta,X,U
    real colvector y,latent,ii,cf
    real scalar i,kap,draw
    string rowvector names
    cf=J(D.n,1,0)
    if (D.p) {
        C=_tvtie_unpack(raw[D.ic],D.p)
        F=rnormal(D.n,D.p,0,1)*C'
        F=_tvtie_project(D,F)
        delta=rowshape(raw[D.idelta],D.p)'
        W=_tvtie_project(D,D.Zraw*delta)+D.Wraw-_tvtie_project(D,D.Wraw)+F
        names=tokens(st_local("endogenous"))
        st_store(D.obs,names,W)
        cf=F*raw[D.ie]'
    }
    X=_tvtie_get(D.obs,st_local("indepvars"))
    if (D.xcons) X=(X,J(D.n,1,1))
    U=(_tvtie_get(D.obs,st_local("uhet")),J(D.n,1,1))
    kap=0
    if (D.tn) kap=raw[D.ik]
    latent=J(D.n,1,.)
    for (i=1;i<=D.ng;i++) {
        ii=D.info[i,1]::D.info[i,2]
        draw=kap-_tvtie_invlogphi(ln(1-runiform(1,1))+lnnormal(kap))
        latent[ii]=J(rows(ii),1,draw)
    }
    y=cf-D.s*exp(0.5*U*raw[D.iu]'):*latent+rnormal(D.n,1,0,sqrt(exp(raw[D.ir])))
    if (D.kx) y=y+X*raw[D.ib]'
    if (D.kh) y=y+D.yraw-D.y
    st_store(D.obs,st_local("depvar"),y)
}

/* Defined last: presence of this marker means every preceding function loaded. */
real scalar _tvtie_version()
{
    return(10200)
}

end
