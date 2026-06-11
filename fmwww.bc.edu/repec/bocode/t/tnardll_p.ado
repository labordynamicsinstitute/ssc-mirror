*! tnardll_p version 1.0.0  03jun2026
*! Postestimation predict for tnardll.
*! Reconstructs the threshold ECM design from stored thresholds and computes
*! the linear prediction of D.depvar (xb) or the residuals.

program define tnardll_p
    version 17.0

    if "`e(cmd)'" != "tnardll" {
        di as err "tnardll_p only works after tnardll"
        exit 301
    }

    syntax newvarname [if] [in] [, XB Residuals ]

    local opts "`xb' `residuals'"
    local nopt : word count `opts'
    if `nopt' > 1 {
        di as err "only one statistic may be specified"
        exit 198
    }
    if `nopt' == 0 local xb "xb"

    marksample touse, novarlist
    * restrict to estimation sample
    qui replace `touse' = 0 if !e(sample)

    local stat = cond("`residuals'"!="", "resid", "xb")

    * constant / trend flags from coefficient names
    local bn : colnames e(b)
    local consf = `: list posof "_cons" in bn' > 0
    local trf   = `: list posof "trend" in bn' > 0

    tempvar out
    qui gen double `out' = .

    mata: _tnardll_predict("`out'", "`stat'", `consf', `trf')

    gen `typlist' `varlist' = `out'
    label var `varlist' ///
        `=cond("`stat'"=="resid","\"tnardll residuals\"","\"tnardll xb (D.`e(depvar)')\"")'
end

version 17.0
mata:
mata set matastrict off

// Mata functions defined in an ado-file's trailing mata block are PRIVATE to
// that ado; they are not shared across ado files (and do not appear in the
// interactive `mata describe`).  tnardll_p therefore carries its own copies of
// the design-builder _tn_design() and its helpers, kept byte-for-byte identical
// to the definitions in tnardll.ado.  The struct layout must match too, since
// the design matrix column order must reproduce the estimator exactly.
struct tndes {
    real colvector dyv
    real matrix    X
    real colvector keep
    real scalar    S, m, p, q, irho
    real rowvector ilr_xT, ilr_w, iphi
    real matrix    ipi
}

real colvector _tn_lag(real colvector v, real scalar k)
{
    real scalar n
    n = rows(v)
    if (k <= 0) return(v)
    if (k >= n) return(J(n,1,.))
    return( J(k,1,.) \ v[|1 \ n-k|] )
}

real colvector _tn_cumsum(real colvector v)
{
    real scalar i, n
    real colvector c
    n = rows(v)
    c = J(n,1,0)
    if (n == 0) return(c)
    c[1] = (v[1]==. ? 0 : v[1])
    for (i=2; i<=n; i++) c[i] = c[i-1] + (v[i]==. ? 0 : v[i])
    return(c)
}

real matrix _tn_seg(real colvector dx, real rowvector tau)
{
    real scalar n, S, t, s
    real matrix seg
    n = rows(dx)
    S = cols(tau) + 1
    seg = J(n, S, 0)
    for (t=1; t<=n; t++) {
        if (dx[t]==.) continue
        if (S==1) {
            seg[t,1] = dx[t]
            continue
        }
        if (dx[t] <= tau[1]) {
            seg[t,1] = dx[t]
        }
        else if (dx[t] > tau[S-1]) {
            seg[t,S] = dx[t]
        }
        else {
            for (s=2; s<=S-1; s++) {
                if (dx[t] > tau[s-1] && dx[t] <= tau[s]) seg[t,s] = dx[t]
            }
        }
    }
    return(seg)
}

struct tndes scalar _tn_design(real colvector y, real colvector xT,
        real matrix W, real scalar p, real scalar q,
        real rowvector tau, real scalar consf, real scalar trf)
{
    struct tndes scalar d
    real scalar n, S, m, s, j, jj, col
    real colvector dy, dx, dw
    real matrix seg, xseg, X, M

    n = rows(y)
    S = cols(tau) + 1
    m = cols(W)
    dy = y - _tn_lag(y,1)
    dx = xT - _tn_lag(xT,1)
    seg  = _tn_seg(dx, tau)
    xseg = J(n,S,0)
    for (s=1; s<=S; s++) xseg[.,s] = _tn_cumsum(seg[.,s])

    X = J(n,0,.)
    col = 0
    X = _tn_lag(y,1)
    col = 1
    d.irho = 1
    d.ilr_xT = J(1,S,0)
    for (s=1; s<=S; s++) {
        X = X, _tn_lag(xseg[.,s],1)
        col++
        d.ilr_xT[s] = col
    }
    d.ilr_w = (m>0 ? J(1,m,0) : J(1,0,0))
    for (j=1; j<=m; j++) {
        X = X, _tn_lag(W[.,j],1)
        col++
        d.ilr_w[j] = col
    }
    d.iphi = (p>1 ? J(1,p-1,0) : J(1,0,0))
    for (j=1; j<=p-1; j++) {
        X = X, _tn_lag(dy,j)
        col++
        d.iphi[j] = col
    }
    d.ipi = J(S,q,0)
    for (s=1; s<=S; s++) {
        for (j=0; j<=q-1; j++) {
            X = X, _tn_lag(seg[.,s],j)
            col++
            d.ipi[s,j+1] = col
        }
    }
    for (jj=1; jj<=m; jj++) {
        dw = W[.,jj] - _tn_lag(W[.,jj],1)
        for (j=0; j<=q-1; j++) {
            X = X, _tn_lag(dw,j)
            col++
        }
    }
    if (trf) {
        X = X, (1::n)
        col++
    }
    if (consf) {
        X = X, J(n,1,1)
        col++
    }

    M = dy, X
    d.keep = selectindex(rowmissing(M):==0)
    d.dyv = dy[d.keep]
    d.X   = X[d.keep, .]
    d.S = S; d.m = m; d.p = p; d.q = q
    return(d)
}

void _tnardll_predict(string scalar outvar, string scalar stat,
                      real scalar consf, real scalar trf)
{
    real scalar p, q, S
    string scalar depvar, thrvar, othervars
    real colvector y, xT, b, rowsused, sel, fullout, xb
    real matrix W, thr
    real rowvector tauS
    struct tndes scalar d

    depvar    = st_global("e(depvar)")
    thrvar    = st_global("e(thrvar)")
    othervars = st_global("e(othervars)")
    p = st_numscalar("e(p)")
    q = st_numscalar("e(q)")
    S = st_numscalar("e(S)")
    b = st_matrix("e(b)")'

    // thresholds
    if (S >= 2) {
        thr = st_matrix("e(thresholds)")
        tauS = thr'
    }
    else tauS = J(1,0,.)

    // data over estimation-touse already set by ado; use e(sample) marker var
    sel = st_data(., st_local("touse"))
    rowsused = selectindex(sel)
    y  = st_data(., depvar, st_local("touse"))
    xT = st_data(., thrvar, st_local("touse"))
    if (othervars != "") W = st_data(., othervars, st_local("touse"))
    else W = J(rows(y),0,.)

    d = _tn_design(y, xT, W, p, q, tauS, consf, trf)
    xb = d.X * b
    fullout = J(st_nobs(),1,.)
    if (stat == "xb") fullout[rowsused[d.keep]] = xb
    else              fullout[rowsused[d.keep]] = d.dyv - xb
    st_store(., outvar, fullout)
}
end
