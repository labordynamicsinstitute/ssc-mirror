mata:
mata set matastrict on

real matrix har_cos_basis(real scalar T, real scalar nu) {
    real colvector t, m
    real matrix M
    t = 1::T
    t = t :- 0.5
    m = 1::nu
    M = (m * t') * (pi()/T)
    return( sqrt(2) :* cos(M) )
}

real matrix har_fourier_basis(real scalar T, real scalar B) {
    real colvector t, m
    real matrix C, S, out
    real scalar i
    t = 1::T
    m = 1::B
    C = sqrt(2) :* cos((m * (2*pi()) * t')/T)
    S = sqrt(2) :* sin((m * (2*pi()) * t')/T)
    out = J(2*B, T, .)
    for (i=1; i<=B; i++) {
        out[2*i-1,.] = C[i,.]
        out[2*i,.]   = S[i,.]
    }
    return(out)
}

real matrix har_nw_omega(real matrix Z, real scalar S) {
    real scalar T, w, j
    real matrix Omega
    T = rows(Z)
    if (S >= T) S = T-1
    Omega = (Z' * Z)
    if (S <= 1) return(Omega)
    real matrix G
    /* LLS Bartlett form: w = 1 - j/S for j = 1..S-1 (lag S has
       weight 0). Distinct from the LLSW form w = 1 - j/(S+1) for
       j = 1..S, which puts nonzero weight 1/(S+1) on lag S and is
       intentionally NOT used here */
    for (j=1; j<=S-1; j++) {
        G = (Z[(j+1)..T,]' * Z[1..(T-j),])
        w = 1 - j/S
        Omega = Omega + w*(G + G')
    }
    return(Omega)
}

real scalar har_qs_weight(real scalar j, real scalar S) {
    real scalar v, x
    v = j/(S)
    x = 6*pi()*v/5
    if (x == 0) return(1)
    return(3*(sin(x)/x - cos(x))/(x^2))
}

real matrix har_qs_omega(real matrix Z, real scalar S) {
    real scalar T, w, j, Jmax
    real matrix Omega
    T = rows(Z)
    if (S >= T) S = T-1
    Omega = (Z' * Z)
    if (S <= 0) return(Omega)
    Jmax = T-1
    real matrix G
    for (j=1; j<=Jmax; j++) {
        w = har_qs_weight(j, S)
        G = (Z[(j+1)..T,]' * Z[1..(T-j),])
        Omega = Omega + w*(G + G')
    }
    return(Omega)
}

real colvector har_fb_tdraws(string scalar kernel, real scalar S, real scalar T, real scalar draws) {
    real colvector out, z, e
    real scalar m,omega,w,i,j
    if (S >= T) S = T-1
    real scalar Jmax
    Jmax = (kernel=="qs" ? T-1 : S-1)
    out = J(draws,1,.)
    for (i=1; i<=draws; i++) {
        z = rnormal(T,1,0,1)
        m = mean(z)
        e = z :- m
        omega = quadcross(e,e)/T
        if (Jmax>=1) {
            for (j=1; j<=Jmax; j++) {
                w = (kernel=="qs" ? har_qs_weight(j,S) : 1 - j/S)
                omega = omega + 2*w*quadcross(e[(j+1)..T,], e[1..(T-j),])/T
            }
        }
        out[i] = sqrt(T)*m/sqrt(omega)
    }
    return(out)
}

real colvector har_fb_Fdraws(string scalar kernel, real scalar S, real scalar T, real scalar draws, real scalar q) {
    real colvector out, b
    real matrix Z, E, Omega
    real scalar i
    if (S >= T) S = T-1
    out = J(draws,1,.)
    for (i=1; i<=draws; i++) {
        Z = rnormal(T,q,0,1)
        b = mean(Z)'
        E = Z :- J(T,1,1)*b'
        Omega = (kernel=="nw" ? har_nw_omega(E,S) : har_qs_omega(E,S))
        out[i] = (T^2)*(b' * invsym(Omega) * b)/q
    }
    return(out)
}

void harwald_sim(string scalar kernel, real scalar S, real scalar T, real scalar draws,
                 real scalar q, real scalar Fstat, real scalar level,
                 string scalar cvname_out, string scalar pvalname_out)
{
    real colvector d
    real scalar pos
    d = har_fb_Fdraws(kernel, S, T, draws, q)
    d = sort(d,1)
    pos = ceil(draws*level)
    st_numscalar(cvname_out, d[pos])
    st_numscalar(pvalname_out, mean(d :>= Fstat))
}

void har_build_hac(string scalar est, real scalar T, real scalar lags, real scalar dfopt,
                   real scalar draws, string scalar bnames, string scalar residvar,
                   string scalar tousevar, string scalar bname, string scalar Xmatname,
                   real scalar level_in,
                   string scalar bname_out, string scalar Vname_out,
                   string scalar pname_out, string scalar tname_out,
                   string scalar sename_out, string scalar ci_loname_out,
                   string scalar ci_hiname_out, string scalar cvname_out,
                   string scalar bwname_out, string scalar dfname_out,
                   string scalar levelname_out)
{
    real matrix X, Z
    real matrix invXX, V, Omega, basis, H, bmat
    real colvector b, u
    real colvector se, tstat, pvec, ci_lo, ci_hi
    real scalar bw, nu, level, cv, j, S, B, k, i
    bmat = st_matrix(bname)
    b = bmat'
    k = rows(b)

    X = st_matrix(Xmatname)
    st_view(u=., ., residvar, tousevar)
    Z = X :* u

    invXX = invsym(quadcross(X,X))
    if (diag0cnt(invXX) > 0) {
        errprintf("design matrix is rank-deficient\n")
        exit(error(506))
    }
    level = level_in

    if (est=="ewc" | est=="ewp") {
        if (dfopt<=0) nu = floor(0.41* (T^(2.0/3.0)))
        else nu = floor(dfopt)
        if (nu >= T) {
            errprintf("df(%g) must be less than T (%g)\n", nu, T)
            exit(error(198))
        }
        if (est=="ewp") {
            if (mod(nu,2)==1) nu = nu-1
            if (nu<2) nu=2
        }
        /* EWC floor: user df with 0 < df < 1 would land nu = 0 and
           divide by zero at Omega/nu below. Refuse cleanly. */
        if (est=="ewc" & nu < 1) {
            errprintf("df(%g) yields nu = 0 for EWC; df must be >= 1\n", dfopt)
            exit(error(198))
        }
        bw = nu
        B = (est=="ewp" ? nu/2 : nu)
        basis = (est=="ewp" ? har_fourier_basis(T,B) : har_cos_basis(T,nu))
        /* Do not normalize the basis by sqrt(1/T): keeping raw cosine /
           Fourier scores gives Omega the un-normalized convention
           Omega_stata = T * Omega_paper. The sandwich
           V = (X'X)^-1 Omega (X'X)^-1 then needs no separate T factor —
           the extra T in Omega cancels the 1/T in the paper's sandwich */
        H = basis * Z
        Omega = quadcross(H,H)/nu
        V = invXX * Omega * invXX
        se = sqrt(diagonal(V))
        tstat = b :/ se
        pvec = J(k,1,.)
        ci_lo = J(k,1,.)
        ci_hi = J(k,1,.)
        cv = invttail(nu, (1-level)/2)
        for (j=1; j<=k; j++) {
            pvec[j]   = 2*ttail(nu, abs(tstat[j]))
            ci_lo[j]  = b[j] - cv*se[j]
            ci_hi[j]  = b[j] + cv*se[j]
        }
    }
    else {
        if (lags<=0) {
            if (est=="nw") S = ceil(1.3*sqrt(T))
            else {
                real scalar nu_qs
                /* QS bandwidth: user-supplied df() takes effect when
                   lags() is absent; otherwise the default
                   nu = floor(0.41*T^(2/3)) */
                if (dfopt > 0) nu_qs = floor(dfopt)
                else nu_qs = floor(0.41*T^(2.0/3.0))
                /* QS floor: user df with 0 < df < 1 would land
                   nu_qs = 0 and ceil(T/0) is undefined. Refuse. */
                if (nu_qs < 1) {
                    errprintf("df(%g) yields nu_qs = 0 for QS; df must be >= 1\n", dfopt)
                    exit(error(198))
                }
                S = ceil(T/nu_qs)
            }
        }
        else S = lags
        if (S >= T) S = T-1
        bw = S
        nu = .
        Omega = (est=="nw" ? har_nw_omega(Z,S) : har_qs_omega(Z,S))
        V = invXX * Omega * invXX
        se = sqrt(diagonal(V))
        tstat = b :/ se
        real colvector draws_t, absd
        real scalar pos
        draws_t = har_fb_tdraws(est, S, T, draws)
        absd = abs(draws_t)
        absd = sort(absd,1)
        pos = ceil((rows(absd))*level)
        cv = absd[pos]
        pvec = J(k,1,.)
        ci_lo = J(k,1,.)
        ci_hi = J(k,1,.)
        for (j=1; j<=k; j++) {
            pvec[j] = mean(absd :>= abs(tstat[j]))
            ci_lo[j] = b[j] - cv*se[j]
            ci_hi[j] = b[j] + cv*se[j]
        }
    }

    st_matrix(bname_out, b')
    st_matrix(Vname_out, V)
    st_matrix(pname_out, pvec')
    st_matrix(tname_out, tstat')
    st_matrix(sename_out, se')
    st_matrix(ci_loname_out, ci_lo')
    st_matrix(ci_hiname_out, ci_hi')
    st_numscalar(cvname_out, cv)
    st_numscalar(bwname_out, bw)
    st_numscalar(dfname_out, nu)
    st_numscalar(levelname_out, level)
    st_local("har_est", est)
}

end
