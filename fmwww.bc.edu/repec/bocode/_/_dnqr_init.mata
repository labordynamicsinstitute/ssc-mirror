*! _dnqr_init.mata  version 1.0.0  27may2026
*! Mata function library for the dnqr package.  Loaded once per Stata
*! session by the _dnqr_mata loader; do not call directly.
*!
*! Author : Dr Merwan Roudane  <merwanroudane920@gmail.com>

version 13.0

mata:
mata set matastrict off

// ---------------------------------------------------------------------
real matrix dnqr_rowstd(real matrix W)
{
        real colvector rs
        real matrix    Wo
        Wo = W
        rs = rowsum(Wo)
        rs = rs + (rs:==0)
        return(Wo :/ rs)
}

// ---------------------------------------------------------------------
real matrix dnqr_panel_to_NT(real colvector v, real colvector id,
                              real colvector t, real scalar N, real scalar T)
{
        real matrix M
        real scalar i
        M = J(N, T, .)
        for (i=1; i<=rows(v); i++) M[id[i], t[i]] = v[i]
        return(M)
}

// ---------------------------------------------------------------------
real matrix dnqr_make_F(real matrix Fmat, real scalar N, real scalar plag)
{
        real scalar T, m, k, j
        real matrix Fdesign, Fblock
        T = rows(Fmat)
        m = cols(Fmat)
        if (plag<0) plag = 0
        if (T-plag <= 0) _error(3300, "common-factor lag exceeds T")
        Fblock = J(T-plag, 0, .)
        for (k=0; k<=plag; k++) {
                Fblock = Fblock, Fmat[(plag+1-k)..(T-k), .]
        }
        Fdesign = J(N*(T-plag), cols(Fblock), .)
        for (j=1; j<=T-plag; j++) {
                Fdesign[((j-1)*N+1)::(j*N), .] = J(N,1,1) * Fblock[j, .]
        }
        return(Fdesign)
}

// ---------------------------------------------------------------------
real matrix dnqr_make_Z(real matrix Zmat, real scalar Teff)
{
        real matrix Zdesign
        real scalar j, N
        N = rows(Zmat)
        Zdesign = J(N*Teff, cols(Zmat), .)
        for (j=1; j<=Teff; j++) {
                Zdesign[((j-1)*N+1)::(j*N), .] = Zmat
        }
        return(Zdesign)
}

// ---------------------------------------------------------------------
real scalar dnqr_powell_band(real scalar tau, real scalar n,
                              string scalar btype, real scalar scale)
{
        real scalar hf
        if (btype == "HS") {
                hf = n^(-1/3) * (invnormal(0.975))^(2/3) *
                     (1.5 * (normalden(invnormal(tau)))^2 /
                       (2 * (invnormal(tau))^2 + 1))^(1/3)
        }
        else {
                hf = n^(-1/5) *
                     (4.5 * (normalden(invnormal(tau)))^4 /
                       ((2*(invnormal(tau))^2 + 1)^2))^(1/5)
        }
        hf = scale * hf
        if (tau+hf>=1 | tau-hf<=0) hf = min((abs(tau-0.0001),abs(1-tau-0.0001)))
        return(hf)
}

// ---------------------------------------------------------------------
real rowvector dnqr_qreg_via_st(real colvector y, real matrix X,
                                 real scalar tau)
{
        real rowvector b
        real scalar k, j, rc, dummy
        string rowvector xn
        stata("preserve")
        stata("quietly drop _all")
        dummy = st_addobs(rows(y))
        dummy = st_addvar("double", "__dnqr_y")
        st_store(., "__dnqr_y", y)
        k = cols(X)
        xn = J(1, k, "")
        for (j=1; j<=k; j++) {
                xn[j] = sprintf("__dnqr_x%g", j)
                dummy = st_addvar("double", xn[j])
                st_store(., xn[j], X[., j])
        }
        rc = _stata("_dnqr_silent_qreg __dnqr_y " + invtokens(xn) +
                    ", quantile(" + strofreal(tau) + ")")
        if (rc != 0 | st_numscalar("c(rc)") != 0) {
                stata("restore")
                _error(3498, "qreg failed inside IVQR grid")
        }
        b = st_matrix("e(b)")
        stata("restore")
        return(b)
}

// ---------------------------------------------------------------------
real rowvector dnqr_ivqr_grid(real colvector y, real colvector D,
                               real matrix X, real matrix Mz,
                               real colvector grid, real scalar tau)
{
        real scalar i, L, gmin, alpha
        real rowvector b
        real colvector gnorms
        L = cols(Mz)
        gnorms = J(rows(grid), 1, .)
        for (i=1; i<=rows(grid); i++) {
                alpha = grid[i]
                b = dnqr_qreg_via_st(y :- alpha:*D, (Mz, X), tau)
                gnorms[i] = sqrt(sum(b[1..L]:^2))
        }
        gmin = min(gnorms)
        for (i=1; i<=rows(grid); i++) {
                if (gnorms[i]==gmin) return((grid[i], gmin))
        }
        return((grid[1], gnorms[1]))
}

// ---------------------------------------------------------------------
real matrix dnqr_powell_vcov(real colvector y, real colvector D,
                              real matrix X, real matrix Mz,
                              real colvector resid, real scalar tau,
                              string scalar btype, real scalar scale)
{
        real scalar n, hf, den, qhi, qlo
        real matrix XD, XZ, J1, S, V
        n = rows(y)
        XD = (J(n,1,1), D, X)
        XZ = (J(n,1,1), Mz, X)
        hf = dnqr_powell_band(tau, n, btype, scale)
        qhi = dnqr_quantile(resid, tau+hf)
        qlo = dnqr_quantile(resid, tau-hf)
        if (qhi - qlo <= 0) den = 1e-6
        else                den = 2*hf / (qhi - qlo)
        J1 = (XD' * XZ) * den
        S  = cross(XZ, XZ)
        V  = invsym(J1 * invsym(S) * J1') * tau * (1-tau)
        return(V)
}

// ---------------------------------------------------------------------
real scalar dnqr_quantile(real colvector x, real scalar p)
{
        real colvector xs
        real scalar n, idx
        xs = sort(x, 1)
        n  = rows(xs)
        idx = p * (n + 1)
        idx = max((1, min((n, idx))))
        return(xs[round(idx)])
}

// ---------------------------------------------------------------------
real scalar dnqr_goodfit(real colvector r_full, real colvector r_null,
                          real scalar tau)
{
        real scalar V1, V0
        V1 = sum(r_full :* (tau :- (r_full :< 0)))
        V0 = sum(r_null :* (tau :- (r_null :< 0)))
        if (V0==0) return(.)
        return(1 - V1/V0)
}

// ---------------------------------------------------------------------
real matrix dnqr_impulse(real matrix G, real colvector v0, real scalar H)
{
        real matrix IRF
        real scalar h
        IRF = J(rows(G), H+1, .)
        IRF[., 1] = v0
        for (h=2; h<=H+1; h++) IRF[., h] = G * IRF[., h-1]
        return(IRF)
}

// =====================================================================
// Mata routines specific to the nqar / dnqr engines (recoding, design)
// =====================================================================

real matrix _nqar_recode(real colvector v, real colvector u)
{
        real scalar i, n
        real matrix idx
        real colvector r
        n = rows(v)
        r = J(n, 1, .)
        for (i=1; i<=n; i++) {
                idx = selectindex(u:==v[i])
                r[i] = idx[1]
        }
        return(r)
}

real matrix _nqar_panel_to_NT(real colvector v, real colvector id2,
                               real colvector t2, real scalar N,
                               real scalar T)
{
        real matrix M
        real scalar i
        M = J(N, T, .)
        for (i=1; i<=rows(v); i++) M[id2[i], t2[i]] = v[i]
        return(M)
}

real matrix _nqar_collapse_Z(real matrix Zlong, real colvector id2,
                              real scalar N)
{
        real matrix Z
        real scalar i
        Z = J(N, cols(Zlong), .)
        for (i=1; i<=rows(Zlong); i++) {
                if (Z[id2[i], 1] == .) Z[id2[i], .] = Zlong[i, .]
        }
        return(Z)
}

real matrix _nqar_collapse_F(real matrix Flong, real colvector t2,
                              real scalar T)
{
        real matrix F
        real scalar i
        F = J(T, cols(Flong), .)
        for (i=1; i<=rows(Flong); i++) {
                if (F[t2[i], 1] == .) F[t2[i], .] = Flong[i, .]
        }
        return(F)
}

real matrix _nqar_build_F(real matrix Fsub, real scalar N, real scalar plag)
{
        real scalar Teff, m, k, j
        real matrix block, design
        Teff = rows(Fsub) - plag
        m    = cols(Fsub)
        block = J(Teff, 0, .)
        for (k=0; k<=plag; k++) {
                block = block, Fsub[(plag+1-k)..(Teff+plag-k), .]
        }
        design = J(N*Teff, cols(block), .)
        for (j=1; j<=Teff; j++) {
                design[((j-1)*N+1)::(j*N), .] = J(N,1,1) * block[j, .]
        }
        return(design)
}

real matrix _nqar_expand_Z(real matrix Zmat, real scalar Teff)
{
        real matrix design
        real scalar j, N
        N = rows(Zmat)
        if (cols(Zmat)==0) return(J(N*Teff, 0, .))
        design = J(N*Teff, cols(Zmat), .)
        for (j=1; j<=Teff; j++) {
                design[((j-1)*N+1)::(j*N), .] = Zmat
        }
        return(design)
}

// Powell SE for the no-IV case
real matrix _nqar_powell_vcov(real colvector y, real matrix X,
                               real colvector r, real scalar tau,
                               string scalar btype, real scalar bs)
{
        real scalar n, hf, den, qhi, qlo
        real matrix Xc, V, A
        n  = rows(y)
        Xc = (J(n,1,1), X)
        hf = dnqr_powell_band(tau, n, btype, bs)
        qhi = dnqr_quantile(r, tau+hf)
        qlo = dnqr_quantile(r, tau-hf)
        if (qhi - qlo <= 0) den = 1e-6
        else                den = 2*hf / (qhi - qlo)
        A   = cross(Xc, Xc) :* den
        V   = invsym(A * invsym(cross(Xc, Xc)) * A) :* (tau*(1-tau))
        return(V)
}

// =====================================================================
// _nqar_engine : main NQAR estimator
// =====================================================================
void _nqar_engine(string scalar depv, string scalar zlist,
                  string scalar flist, string scalar Wname,
                  string scalar pvar, string scalar tvar,
                  string scalar touse, real scalar plag,
                  string scalar qstr, string scalar btype,
                  real scalar bscale, real scalar rowstd, real scalar lev,
                  string scalar Bname, string scalar SEname,
                  string scalar Tname, string scalar Pname,
                  string scalar Loname, string scalar Hiname,
                  string scalar Qname, string scalar Dname,
                  string scalar Bfirst, string scalar Vfirst)
{
        real matrix W, Ymat, Zmat, Fmat, X, Zd, Fd
        real matrix Ymatl, WYmatl, Zlong, Flong, Fsub
        real matrix B, SE, Tv, Pv, Lo, Hi
        real matrix V
        real colvector yv, idv, tv, id2, t2, ylag, wylag, taus
        real colvector uid, ut, bvec, resid
        real rowvector b
        real scalar N, T, Teff, q, nq, k, j, tstart, nb, netd, zlev, kreg
        string rowvector rnames, zn, fn
        string matrix rs, cs

        W = st_matrix(Wname)
        N = rows(W)
        if (cols(W) != N) _error(3200, "W must be square N x N")
        if (rowstd)       W = dnqr_rowstd(W)

        idv = st_data(., pvar, touse)
        tv  = st_data(., tvar, touse)
        yv  = st_data(., depv, touse)

        uid = uniqrows(idv)
        ut  = uniqrows(tv)
        if (rows(uid) != N) {
                printf("{err}rows(W) = %g but panel restricts to %g units\n",
                       N, rows(uid))
                _error(3200, "network dimension mismatch")
        }
        T   = rows(ut)
        id2 = _nqar_recode(idv, uid)
        t2  = _nqar_recode(tv,  ut)
        Ymat = _nqar_panel_to_NT(yv, id2, t2, N, T)

        if (zlist != "") {
                Zlong = st_data(., zlist, touse)
                Zmat  = _nqar_collapse_Z(Zlong, id2, N)
        }
        else Zmat = J(N, 0, .)

        if (flist != "") {
                Flong = st_data(., flist, touse)
                Fmat  = _nqar_collapse_F(Flong, t2, T)
        }
        else Fmat = J(T, 0, .)

        tstart = max((2, plag+2))
        Teff   = T - tstart + 1
        if (Teff < 2) _error(3300, "not enough time periods after lags")

        Ymatl  = Ymat[., (tstart-1)..(T-1)]
        WYmatl = W * Ymatl
        yv     = vec(Ymat[., tstart..T])
        ylag   = vec(Ymatl)
        wylag  = vec(WYmatl)

        Zd = _nqar_expand_Z(Zmat, Teff)
        if (cols(Fmat) > 0) {
                Fsub = Fmat[(tstart-plag)..T, .]
                Fd   = _nqar_build_F(Fsub, N, plag)
        }
        else Fd = J(rows(yv), 0, .)

        X    = wylag, ylag, Zd, Fd
        kreg = cols(X)

        rnames = ("_cons", "WY_L1", "Y_L1")
        if (cols(Zmat) > 0) rnames = rnames, tokens(zlist)
        if (cols(Fmat) > 0) {
                fn = tokens(flist)
                for (k=0; k<=plag; k++) {
                        for (j=1; j<=cols(Fmat); j++) {
                                if (k==0) rnames = rnames, fn[j]
                                else      rnames = rnames, sprintf("%s_L%g", fn[j], k)
                        }
                }
        }
        nb = cols(rnames)

        taus = strtoreal(tokens(qstr))'
        nq   = rows(taus)
        B  = J(nb, nq, .); SE = J(nb, nq, .)
        Tv = J(nb, nq, .); Pv = J(nb, nq, .)
        Lo = J(nb, nq, .); Hi = J(nb, nq, .)
        zlev = invnormal(1 - (1-lev/100)/2)

        real matrix V_first, b_first
        V_first = J(nb, nb, .)
        b_first = J(1, nb, .)
        for (q=1; q<=nq; q++) {
                b = dnqr_qreg_via_st(yv, X, taus[q])
                bvec = (b[kreg+1] \ b[1..kreg]')
                resid = yv :- (J(rows(yv),1,1), X) * bvec
                V = _nqar_powell_vcov(yv, X, resid, taus[q], btype, bscale)
                B[., q]  = bvec
                SE[., q] = sqrt(diagonal(V))
                Tv[., q] = B[., q] :/ SE[., q]
                Pv[., q] = 2 :* (1 :- normal(abs(Tv[., q])))
                Lo[., q] = B[., q] :- zlev :* SE[., q]
                Hi[., q] = B[., q] :+ zlev :* SE[., q]
                if (q==1) {
                        // store first-quantile b and V for ereturn-post
                        b_first = bvec'
                        V_first = V
                }
        }

        netd = sum(W:>0) / (N*N - N)
        st_numscalar(Dname, netd)

        rs = J(nb, 1, ""), rnames'
        cs = J(nq, 1, ""), strofreal(taus, "%6.3f")
        st_matrix(Bname,  B);  st_matrixrowstripe(Bname,  rs); st_matrixcolstripe(Bname,  cs)
        st_matrix(SEname, SE); st_matrixrowstripe(SEname, rs); st_matrixcolstripe(SEname, cs)
        st_matrix(Tname,  Tv); st_matrixrowstripe(Tname,  rs); st_matrixcolstripe(Tname,  cs)
        st_matrix(Pname,  Pv); st_matrixrowstripe(Pname,  rs); st_matrixcolstripe(Pname,  cs)
        st_matrix(Loname, Lo); st_matrixrowstripe(Loname, rs); st_matrixcolstripe(Loname, cs)
        st_matrix(Hiname, Hi); st_matrixrowstripe(Hiname, rs); st_matrixcolstripe(Hiname, cs)
        st_matrix(Qname,  taus'); st_matrixcolstripe(Qname, cs)

        // posting matrices: e(b) is 1 x k row vector with var-name cols;
        //                   e(V) is k x k symmetric.  We drop _cons from rnames
        //                   and append it at the end (Stata convention).
        string rowvector rn2
        real matrix Vp, bp, perm
        real scalar i
        // _cons is rnames[1]; reorder to (vars..., _cons)
        rn2 = J(1, nb, "")
        for (i=2; i<=nb; i++) rn2[i-1] = rnames[i]
        rn2[nb] = "_cons"
        // permutation: position i in new layout came from position i+1 in old layout
        // for i<nb, and from position 1 for i==nb.
        perm = J(1, nb, .)
        for (i=1; i<nb; i++) perm[i] = i+1
        perm[nb] = 1
        bp = J(1, nb, .)
        Vp = J(nb, nb, .)
        for (i=1; i<=nb; i++) bp[i] = b_first[perm[i]]
        for (i=1; i<=nb; i++) {
                real scalar j2
                for (j2=1; j2<=nb; j2++) {
                        Vp[i, j2] = V_first[perm[i], perm[j2]]
                }
        }
        st_matrix(Bfirst, bp)
        st_matrixcolstripe(Bfirst, (J(nb,1,""), rn2'))
        st_matrix(Vfirst, Vp)
        st_matrixrowstripe(Vfirst, (J(nb,1,""), rn2'))
        st_matrixcolstripe(Vfirst, (J(nb,1,""), rn2'))
}

// =====================================================================
// _dnqr_engine : main DNQR / IVQR estimator
// =====================================================================
void _dnqr_engine(string scalar depv, string scalar zlist,
                  string scalar flist, string scalar Wname,
                  string scalar pvar, string scalar tvar,
                  string scalar touse, real scalar plag,
                  string scalar qstr, string scalar btype,
                  real scalar bscale, real scalar rowstd, real scalar lev,
                  string scalar ivtype, real scalar gpts, real scalar gscale,
                  string scalar GRname,
                  string scalar Bname, string scalar SEname,
                  string scalar Tname, string scalar Pname,
                  string scalar Loname, string scalar Hiname,
                  string scalar Qname, string scalar Aname,
                  string scalar Gname, string scalar Dname,
                  string scalar Bfirst, string scalar Vfirst)
{
        real matrix W, Ymat, Zmat, Fmat, X, Mz
        real matrix Ymatl, WYmatl, WYmat, W2Ymatl, W3Ymatl
        real matrix Zd, Fd, Fsub, gridmat, Xpilot, V, B, SE, Tv, Pv, Lo, Hi
        real colvector yv, idv, tv, id2, t2, ylag, wylag, wycur, taus
        real colvector uid, ut, user_grid, grid, bcoef, resid, pres
        real rowvector b, pilot, alphas, gnorms, bfin, found
        real scalar N, T, Teff, q, nq, k, j, tstart, nb, netd, zlev, kreg
        real scalar gam_init, gam_se, alpha
        string rowvector rnames, fn
        string matrix rs, cs

        W = st_matrix(Wname)
        N = rows(W)
        if (cols(W) != N) _error(3200, "W must be square N x N")
        if (rowstd)       W = dnqr_rowstd(W)

        idv = st_data(., pvar, touse)
        tv  = st_data(., tvar, touse)
        yv  = st_data(., depv, touse)

        uid = uniqrows(idv)
        ut  = uniqrows(tv)
        if (rows(uid) != N) {
                printf("{err}rows(W) = %g but panel restricts to %g units\n",
                       N, rows(uid))
                _error(3200, "network dimension mismatch")
        }
        T  = rows(ut)
        id2 = _nqar_recode(idv, uid)
        t2  = _nqar_recode(tv,  ut)
        Ymat = _nqar_panel_to_NT(yv, id2, t2, N, T)

        Zmat = (zlist != "") ?
               _nqar_collapse_Z(st_data(., zlist, touse), id2, N) :
               J(N, 0, .)
        Fmat = (flist != "") ?
               _nqar_collapse_F(st_data(., flist, touse), t2, T) :
               J(T, 0, .)

        tstart = max((2, plag+2))
        Teff   = T - tstart + 1
        if (Teff < 2) _error(3300, "not enough time periods after lags")

        Ymatl  = Ymat[., (tstart-1)..(T-1)]
        WYmatl = W * Ymatl
        WYmat  = W * Ymat[., tstart..T]

        yv    = vec(Ymat[., tstart..T])
        ylag  = vec(Ymatl)
        wylag = vec(WYmatl)
        wycur = vec(WYmat)

        if (ivtype == "wy2") {
                W2Ymatl = W * WYmatl
                Mz = vec(W2Ymatl)
        }
        else if (ivtype == "wy3") {
                W3Ymatl = W * W * WYmatl
                Mz = vec(W3Ymatl)
        }
        else {
                W2Ymatl = W * WYmatl
                W3Ymatl = W * W2Ymatl
                Mz = vec(W2Ymatl), vec(W3Ymatl)
        }

        Zd = _nqar_expand_Z(Zmat, Teff)
        if (cols(Fmat) > 0) {
                Fsub = Fmat[(tstart-plag)..T, .]
                Fd   = _nqar_build_F(Fsub, N, plag)
        }
        else Fd = J(rows(yv), 0, .)

        X    = wylag, ylag, Zd, Fd
        kreg = cols(X)

        rnames = ("_cons", "WY", "WY_L1", "Y_L1")
        if (cols(Zmat) > 0) rnames = rnames, tokens(zlist)
        if (cols(Fmat) > 0) {
                fn = tokens(flist)
                for (k=0; k<=plag; k++) {
                        for (j=1; j<=cols(Fmat); j++) {
                                if (k==0) rnames = rnames, fn[j]
                                else      rnames = rnames, sprintf("%s_L%g", fn[j], k)
                        }
                }
        }
        nb = cols(rnames)

        taus = strtoreal(tokens(qstr))'
        nq   = rows(taus)

        user_grid = J(0, 1, .)
        gridmat = st_matrix(GRname)
        if (!(gridmat[1,1] == . & cols(gridmat)==1)) user_grid = vec(gridmat)

        B  = J(nb, nq, .); SE = J(nb, nq, .)
        Tv = J(nb, nq, .); Pv = J(nb, nq, .)
        Lo = J(nb, nq, .); Hi = J(nb, nq, .)
        alphas = J(1, nq, .)
        gnorms = J(1, nq, .)
        zlev   = invnormal(1 - (1-lev/100)/2)

        real matrix V_first
        real rowvector b_first
        V_first = J(nb, nb, .)
        b_first = J(1, nb, .)
        for (q=1; q<=nq; q++) {
                if (rows(user_grid) > 0) grid = user_grid
                else {
                        Xpilot = wycur, X
                        pilot  = dnqr_qreg_via_st(yv, Xpilot, taus[q])
                        gam_init = pilot[1]
                        pres = yv :- (J(rows(yv),1,1), Xpilot) *
                               (pilot[cols(Xpilot)+1] \ pilot[1..cols(Xpilot)]')
                        gam_se = max((0.01, sqrt(variance(pres))/sqrt(rows(yv))))
                        grid = gam_init :+ (range(-gpts, gpts, 1) :*
                                            (gscale*gam_se/gpts))
                }

                found = dnqr_ivqr_grid(yv, wycur, X, Mz, grid, taus[q])
                alpha = found[1]

                bfin = dnqr_qreg_via_st(yv :- alpha:*wycur, X, taus[q])
                bcoef = J(nb, 1, .)
                bcoef[1] = bfin[kreg+1]
                bcoef[2] = alpha
                bcoef[3..nb] = bfin[1..kreg]'

                resid = yv :- alpha:*wycur :-
                        (J(rows(yv),1,1), X) *
                        (bcoef[1] \ bcoef[3..nb])
                V = dnqr_powell_vcov(yv, wycur, X, Mz, resid, taus[q],
                                     btype, bscale)

                B[., q]  = bcoef
                SE[., q] = sqrt(diagonal(V))
                Tv[., q] = B[., q] :/ SE[., q]
                Pv[., q] = 2 :* (1 :- normal(abs(Tv[., q])))
                Lo[., q] = B[., q] :- zlev :* SE[., q]
                Hi[., q] = B[., q] :+ zlev :* SE[., q]
                alphas[q] = alpha
                gnorms[q] = found[2]
                if (q==1) {
                        b_first = bcoef'
                        V_first = V
                }
        }

        netd = sum(W:>0) / (N*N - N)
        st_numscalar(Dname, netd)

        rs = J(nb, 1, ""), rnames'
        cs = J(nq, 1, ""), strofreal(taus, "%6.3f")
        st_matrix(Bname,  B);  st_matrixrowstripe(Bname,  rs); st_matrixcolstripe(Bname,  cs)
        st_matrix(SEname, SE); st_matrixrowstripe(SEname, rs); st_matrixcolstripe(SEname, cs)
        st_matrix(Tname,  Tv); st_matrixrowstripe(Tname,  rs); st_matrixcolstripe(Tname,  cs)
        st_matrix(Pname,  Pv); st_matrixrowstripe(Pname,  rs); st_matrixcolstripe(Pname,  cs)
        st_matrix(Loname, Lo); st_matrixrowstripe(Loname, rs); st_matrixcolstripe(Loname, cs)
        st_matrix(Hiname, Hi); st_matrixrowstripe(Hiname, rs); st_matrixcolstripe(Hiname, cs)
        st_matrix(Qname,  taus'); st_matrixcolstripe(Qname, cs)
        st_matrix(Aname,  alphas); st_matrixcolstripe(Aname, cs)
        st_matrix(Gname,  gnorms); st_matrixcolstripe(Gname, cs)

        // post-able e(b)/e(V) -- reorder rnames so _cons is last
        string rowvector rn2
        real matrix Vp, perm
        real rowvector bp
        real scalar i, j2
        rn2 = J(1, nb, "")
        for (i=2; i<=nb; i++) rn2[i-1] = rnames[i]
        rn2[nb] = "_cons"
        perm = J(1, nb, .)
        for (i=1; i<nb; i++) perm[i] = i+1
        perm[nb] = 1
        bp = J(1, nb, .)
        Vp = J(nb, nb, .)
        for (i=1; i<=nb; i++) bp[i] = b_first[perm[i]]
        for (i=1; i<=nb; i++) for (j2=1; j2<=nb; j2++)
                Vp[i, j2] = V_first[perm[i], perm[j2]]
        st_matrix(Bfirst, bp)
        st_matrixcolstripe(Bfirst, (J(nb,1,""), rn2'))
        st_matrix(Vfirst, Vp)
        st_matrixrowstripe(Vfirst, (J(nb,1,""), rn2'))
        st_matrixcolstripe(Vfirst, (J(nb,1,""), rn2'))
}

// =====================================================================
// Impulse helper
// =====================================================================
void _dnqr_irf(string scalar Wname, real scalar g1, real scalar g2,
               real scalar g3, real scalar H, real scalar shocknode,
               real scalar shocksize, real scalar rowstd,
               string scalar IRFname, string scalar NORMname)
{
        real matrix W, I_n, S, G, IRF, nm
        real colvector v0
        real scalar N, h
        W = st_matrix(Wname)
        N = rows(W)
        if (rowstd) W = dnqr_rowstd(W)
        I_n = I(N)
        if (abs(g1) > 1e-12) {
                S = luinv(I_n :- g1:*W)
                G = S * (g2:*W :+ g3:*I_n)
        }
        else G = g2:*W :+ g3:*I_n
        v0 = J(N, 1, 0)
        if (shocknode < 1 | shocknode > N) shocknode = 1
        v0[shocknode] = shocksize
        IRF = dnqr_impulse(G, v0, H)
        nm = J(2, H+1, .)
        for (h=1; h<=H+1; h++) {
                nm[1, h] = sqrt(sum(IRF[., h]:^2))
                nm[2, h] = max(abs(IRF[., h]))
        }
        st_matrix(IRFname,  IRF)
        st_matrix(NORMname, nm)
}

// =====================================================================
// Simulator helpers
// =====================================================================

real matrix _dnqr_W_dyad(real scalar N, real scalar delta)
{
        real matrix A
        real scalar i, npairs, a, b, j
        A = J(N, N, 0)
        npairs = round(N*delta)
        for (i=1; i<=npairs; i++) {
                a = ceil(runiform(1,1)*N)
                b = ceil(runiform(1,1)*N)
                if (a==b) b = mod(b, N) + 1
                A[a, b] = 1
                A[b, a] = 1
        }
        for (i=1; i<=N; i++) {
                if (sum(A[i, .])==0) {
                        j = ceil(runiform(1,1)*N)
                        if (j==i) j = mod(j, N) + 1
                        A[i, j] = 1
                }
        }
        return(A)
}

real matrix _dnqr_W_powerlaw(real scalar N, real scalar alpha)
{
        real matrix A
        real scalar i, nf, k
        real colvector pool, pick
        A = J(N, N, 0)
        for (i=1; i<=N; i++) {
                nf = ceil(runiform(1,1)^(-1/alpha))
                nf = min((nf, N-1))
                pool = (1::N)
                pool = select(pool, pool:!=i)
                _jumble(pool)
                pick = pool[1::min((nf, rows(pool)))]
                for (k=1; k<=rows(pick); k++) A[i, pick[k]] = 1
        }
        for (i=1; i<=N; i++) {
                if (sum(A[i, .])==0) {
                        k = mod(i, N) + 1
                        A[i, k] = 1
                }
        }
        return(A)
}

real matrix _dnqr_W_block(real scalar N, real scalar K)
{
        real matrix A
        real scalar i, j, blk, bi, bj, pr
        A = J(N, N, 0)
        blk = floor(N/K)
        if (blk < 1) blk = 1
        for (i=1; i<=N; i++) {
                bi = floor((i-1)/blk) + 1
                for (j=1; j<=N; j++) {
                        if (i==j) continue
                        bj = floor((j-1)/blk) + 1
                        pr = (bi==bj) ? 0.4 : 0.05
                        if (runiform(1,1) < pr) A[i, j] = 1
                }
        }
        for (i=1; i<=N; i++) {
                if (sum(A[i, .])==0) {
                        j = mod(i, N) + 1
                        A[i, j] = 1
                }
        }
        return(A)
}

real matrix _dnqr_W_asym(real scalar N, real scalar h)
{
        real matrix A
        real scalar i, j, hh
        A = J(N, N, 0)
        hh = round(h)
        for (i=1; i<=N; i++) {
                for (j=i+1; j<=min((N, i+hh)); j++) A[i, j] = 1
        }
        for (i=1; i<=N; i++) {
                for (j=1; j<i; j++) if (A[j, i]==1) A[i, j] = 1
        }
        for (i=1; i<=N; i++) {
                if (sum(A[i, .])==0) {
                        j = mod(i, N) + 1
                        A[i, j] = 1
                }
        }
        return(A)
}

void _dnqr_simulate(string scalar wtype, real scalar N, real scalar wpar,
                    real scalar burnin, real scalar T, string scalar edist,
                    real scalar edf,
                    real scalar g1, real scalar g2, real scalar g3,
                    real scalar nz, real scalar nf, real scalar seed,
                    string scalar Wname, string scalar Yname,
                    string scalar Zname, string scalar Fname)
{
        real matrix A, W, Ymat, Zmat, Fmat, rhs, err
        real scalar i, t, Tt
        rseed(seed)
        if      (wtype=="dyad")  A = _dnqr_W_dyad(N, wpar)
        else if (wtype=="block") A = _dnqr_W_block(N, wpar)
        else if (wtype=="asym")  A = _dnqr_W_asym(N, wpar)
        else                     A = _dnqr_W_powerlaw(N, wpar)
        W = dnqr_rowstd(A)

        Zmat = (nz > 0) ? rnormal(N, nz, 0, 1) : J(N, 0, .)
        Fmat = (nf > 0) ? rnormal(T + burnin, nf, 0, 1) : J(T + burnin, 0, .)

        Tt = T + burnin
        Ymat = J(N, Tt, 0)
        for (t=2; t<=Tt; t++) {
                if (edist=="normal")   err = rnormal(N, 1, 0, 1)
                else if (edist=="t")   err = invnormal(uniform(N,1))   // approx; t is not built-in
                else                   err = rchi2(N, 1, edf) :- edf
                rhs = g2:*(W*Ymat[., t-1]) :+ g3:*Ymat[., t-1] :+ err
                if (nz > 0) rhs = rhs + Zmat * J(nz, 1, 0.3)
                if (nf > 0) rhs = rhs + J(N, 1, 1) :* (sum(Fmat[t, .]) * 0.2)
                if (abs(g1) > 1e-12) Ymat[., t] = luinv(I(N) :- g1:*W) * rhs
                else                 Ymat[., t] = rhs
        }
        Ymat = Ymat[., (burnin+1)..Tt]
        if (nf > 0) Fmat = Fmat[(burnin+1)..Tt, .]

        st_matrix(Wname, W)
        st_matrix(Yname, Ymat)
        if (nz > 0) st_matrix(Zname, Zmat)
        else        st_matrix(Zname, J(0, 0, .))
        if (nf > 0) st_matrix(Fname, Fmat)
        else        st_matrix(Fname, J(0, 0, .))
}

void _dnqr_sim_writeY(string scalar vn, real matrix Y)
{
        real scalar N, T, i, t, row
        real colvector v
        N = rows(Y)
        T = cols(Y)
        v = J(N*T, 1, .)
        row = 1
        for (t=1; t<=T; t++) {
                for (i=1; i<=N; i++) {
                        v[row] = Y[i, t]
                        row = row + 1
                }
        }
        st_store(., vn, v)
}

void _dnqr_sim_writeZ(real matrix Z)
{
        real scalar N, q, NT, k, i, t, row
        real colvector v
        if (rows(Z)==0 | cols(Z)==0) return
        N  = rows(Z)
        q  = cols(Z)
        NT = st_nobs()
        for (k=1; k<=q; k++) {
                v = J(NT, 1, .)
                row = 1
                for (t=1; t<=NT/N; t++) {
                        for (i=1; i<=N; i++) {
                                v[row] = Z[i, k]
                                row = row + 1
                        }
                }
                st_store(., sprintf("Z%g", k), v)
        }
}

void _dnqr_sim_writeF(real matrix F)
{
        real scalar T, m, N, NT, k, i, t, row
        real colvector v
        if (rows(F)==0 | cols(F)==0) return
        T  = rows(F)
        m  = cols(F)
        NT = st_nobs()
        N  = NT / T
        for (k=1; k<=m; k++) {
                v = J(NT, 1, .)
                row = 1
                for (t=1; t<=T; t++) {
                        for (i=1; i<=N; i++) {
                                v[row] = F[t, k]
                                row = row + 1
                        }
                }
                st_store(., sprintf("F%g", k), v)
        }
}

end
