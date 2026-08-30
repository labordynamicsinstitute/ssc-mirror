*! _xtcspqardl_mata.mata v1.1.0  29aug2026
*! Mata source for the xtcspqardl aggregation engine.
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! github.com/merwanroudane
*!
*! This file is compiled by _xtcspqardl_mata.ado, which locates it with
*! findfile and executes it with run.  It must NOT be renamed: Stata's
*! ado loader does not execute a trailing mata block inside an .ado, so
*! the definitions have to live in a file that is run explicitly.

version 15.1

mata:

// -----------------------------------------------------------------
// Initialise the unit-level stores.
// -----------------------------------------------------------------
void _xtcspq_init(real scalar N, real scalar ntau, real scalar pfull,
                  real scalar pv)
{
	external real matrix XTCSPQ_TH, XTCSPQ_OM, XTCSPQ_OK
	external real matrix XTCSPQ_ADEV, XTCSPQ_RDEV, XTCSPQ_NI
	XTCSPQ_TH   = J(N, ntau*pfull, .)
	XTCSPQ_OM   = J(N, ntau*pv*pv, .)
	XTCSPQ_OK   = J(N, ntau, 0)
	XTCSPQ_ADEV = J(N, ntau, .)
	XTCSPQ_RDEV = J(N, ntau, .)
	XTCSPQ_NI   = J(N, ntau, .)
}

// -----------------------------------------------------------------
// Store one unit x quantile result.
// -----------------------------------------------------------------
void _xtcspq_put(real scalar i, real scalar t, real scalar pfull,
                 real scalar pv,
                 string scalar bname, string scalar vname,
                 real scalar adev, real scalar rdev, real scalar ni)
{
	external real matrix XTCSPQ_TH, XTCSPQ_OM, XTCSPQ_OK
	external real matrix XTCSPQ_ADEV, XTCSPQ_RDEV, XTCSPQ_NI
	real matrix b, V
	real scalar c0, j, r, c

	b = st_matrix(bname)
	c0 = (t-1)*pfull
	for (j=1; j<=pfull; j++) {
		XTCSPQ_TH[i, c0+j] = b[1,j]
	}

	V = st_matrix(vname)
	if (rows(V)==pv) {
		if (cols(V)==pv) {
			c0 = (t-1)*pv*pv
			for (r=1; r<=pv; r++) {
				for (c=1; c<=pv; c++) {
					XTCSPQ_OM[i, c0+(r-1)*pv+c] = V[r,c]
				}
			}
		}
	}

	XTCSPQ_OK[i,t]   = 1
	XTCSPQ_ADEV[i,t] = adev
	XTCSPQ_RDEV[i,t] = rdev
	XTCSPQ_NI[i,t]   = ni
}

// -----------------------------------------------------------------
// Mean-group aggregation over units usable at EVERY quantile
// (listwise), so the covariance is one coherent joint covariance
// across coefficients and quantiles.
//   mhat = (1/n) sum_i th_i
//   V    = (1/(n(n-1))) sum_i (th_i-mhat)(th_i-mhat)'   [HLP 2018 s2.3]
// -----------------------------------------------------------------
void _xtcspq_mg(real scalar ntau, real scalar pfull, real scalar pv,
                string scalar mname, string scalar vname,
                string scalar nname, string scalar uname)
{
	external real matrix XTCSPQ_TH, XTCSPQ_OM, XTCSPQ_OK
	external real matrix XTCSPQ_ADEV, XTCSPQ_RDEV, XTCSPQ_NI
	real matrix B, D, V
	real rowvector m
	real colvector keep
	real scalar N, i, n, t, c0, good

	// A unit enters the mean group when it was estimable at EVERY
	// requested quantile and none of its parameters of interest is
	// missing at any of them.  Listwise on that common set keeps the
	// returned covariance a single coherent joint covariance across
	// coefficients AND quantiles.
	N = rows(XTCSPQ_OK)
	keep = J(N,1,0)
	for (i=1; i<=N; i++) {
		if (min(XTCSPQ_OK[i,.])!=1) continue
		good = 1
		for (t=1; t<=ntau; t++) {
			c0 = (t-1)*pfull
			if (missing(XTCSPQ_TH[i, (c0+1)..(c0+pv)])>0) good = 0
		}
		if (good==1) keep[i] = 1
	}
	n = colsum(keep)
	st_numscalar(nname, n)
	st_matrix(uname, keep)
	if (n < 1) {
		st_matrix(mname, J(1, cols(XTCSPQ_TH), .))
		st_matrix(vname, J(cols(XTCSPQ_TH), cols(XTCSPQ_TH), .))
		return
	}
	B = select(XTCSPQ_TH, keep)
	m = colsum(B) :/ n
	st_matrix(mname, m)
	if (n > 1) {
		D = B :- m
		V = quadcross(D, D) :/ (n*(n-1))
	}
	else {
		V = J(cols(B), cols(B), .)
	}
	st_matrix(vname, V)
}

// -----------------------------------------------------------------
// Inverse-variance (pooled / CCEP) aggregation, per quantile block.
//   W_i   = Omega_i^{-1}
//   th_P  = (sum W_i)^{-1} (sum W_i th_i)             [Pesaran 2006]
//   V_hom = (sum W_i)^{-1}
//   V_rob = (1/n) Psi^{-1} R Psi^{-1},  Psi=(1/n) sum W_i,
//           R = (1/(n-1)) sum W_i (th_i-th_MG)(th_i-th_MG)' W_i
//                                            [Pesaran 2006, eq. 67]
// -----------------------------------------------------------------
void _xtcspq_pool(real scalar ntau, real scalar pfull, real scalar pv,
                  string scalar mname, string scalar vname,
                  string scalar vhname, string scalar nname)
{
	external real matrix XTCSPQ_TH, XTCSPQ_OM, XTCSPQ_OK
	external real matrix XTCSPQ_ADEV, XTCSPQ_RDEV, XTCSPQ_NI
	real matrix Om, Wi, SW, SWi, TH, WW, Psi, R, Vh, Vall, Vhall
	real colvector SWb, bp
	real rowvector mall, mg, thi, dv
	real scalar N, t, i, c0, r, c, n, ok

	N     = rows(XTCSPQ_OK)
	mall  = J(1, ntau*pv, .)
	Vall  = J(ntau*pv, ntau*pv, 0)
	Vhall = J(ntau*pv, ntau*pv, 0)
	n = 0

	for (t=1; t<=ntau; t++) {
		SW  = J(pv, pv, 0)
		SWb = J(pv, 1, 0)
		TH  = J(0, pv, .)
		WW  = J(0, pv*pv, .)
		for (i=1; i<=N; i++) {
			if (XTCSPQ_OK[i,t]!=1) continue
			c0 = (t-1)*pfull
			thi = XTCSPQ_TH[i, (c0+1)..(c0+pv)]
			if (missing(thi)>0) continue
			c0 = (t-1)*pv*pv
			Om = J(pv, pv, .)
			for (r=1; r<=pv; r++) {
				for (c=1; c<=pv; c++) {
					Om[r,c] = XTCSPQ_OM[i, c0+(r-1)*pv+c]
				}
			}
			if (missing(Om)>0) continue
			Wi = invsym(Om)
			ok = 0
			if (missing(Wi)==0) {
				if (min(diagonal(Wi))>0) ok = 1
			}
			if (ok==0) continue
			SW  = SW  + Wi
			SWb = SWb + Wi*thi'
			TH  = TH \ thi
			WW  = WW  \ rowshape(Wi, 1)
		}
		if (rows(TH) < 2) continue
		SWi = invsym(SW)
		if (missing(SWi)>0) continue
		n  = rows(TH)
		mg = colsum(TH) :/ n
		bp = SWi*SWb
		c0 = (t-1)*pv
		mall[1, (c0+1)..(c0+pv)] = bp'

		Psi = SW :/ n
		R = J(pv, pv, 0)
		for (i=1; i<=n; i++) {
			Wi = rowshape(WW[i,.], pv)
			dv = TH[i,.] :- mg
			R  = R + Wi*(dv'dv)*Wi
		}
		R  = R :/ (n-1)
		Vh = invsym(Psi)*R*invsym(Psi) :/ n
		for (r=1; r<=pv; r++) {
			for (c=1; c<=pv; c++) {
				Vall[c0+r,  c0+c] = Vh[r,c]
				Vhall[c0+r, c0+c] = SWi[r,c]
			}
		}
	}
	st_matrix(mname, mall)
	st_matrix(vname, Vall)
	st_matrix(vhname, Vhall)
	st_numscalar(nname, n)
}

// -----------------------------------------------------------------
// Long-run effects by the delta method, INCLUDING the covariance
// between numerator and denominator.
//   theta_j(tau) = beta_j(tau)/(1 - sgn*lambda(tau))     [HLP 2018]
//   d/d beta_j = 1/(1-sgn*lambda)
//   d/d lambda = sgn*beta_j/(1-sgn*lambda)^2
// Blocks are ordered per quantile with lambda at position `lampos'.
// sgn = 1 for an AR level form (theta = beta/(1-lambda));
// sgn = -1 for an ECM form      (theta = -beta/phi = beta/(1+... )).
// -----------------------------------------------------------------
void _xtcspq_lrdelta(real scalar ntau, real scalar k, real scalar lampos,
                     real scalar sgn,
                     string scalar bname, string scalar vname,
                     string scalar tname, string scalar tvname,
                     string scalar gname)
{
	real matrix b, V, G, TV
	real rowvector T
	real scalar pblk, t, j, c0, d0, lam, den, bj, ib

	b = st_matrix(bname)
	V = st_matrix(vname)
	pblk = 1 + k
	G = J(ntau*k, ntau*pblk, 0)
	T = J(1, ntau*k, .)

	for (t=1; t<=ntau; t++) {
		c0 = (t-1)*pblk
		d0 = (t-1)*k
		lam = b[1, c0+lampos]
		if (lam>=.) continue
		den = 1 - sgn*lam
		if (abs(den) < 1e-6) continue
		for (j=1; j<=k; j++) {
			ib = c0 + j
			if (j >= lampos) ib = c0 + j + 1
			bj = b[1, ib]
			if (bj>=.) continue
			T[1, d0+j] = bj/den
			G[d0+j, ib]        = 1/den
			G[d0+j, c0+lampos] = sgn*bj/(den*den)
		}
	}
	TV = G*V*G'
	st_matrix(tname, T)
	st_matrix(tvname, TV)
	st_matrix(gname, G)
}

// -----------------------------------------------------------------
// Wald test of H0: b[idx] = 0.
// -----------------------------------------------------------------
void _xtcspq_wald(string scalar bname, string scalar vname,
                  string scalar iname, string scalar wname,
                  string scalar dfname, string scalar pname)
{
	real matrix b, V, Vs, Vi
	real rowvector idx, bs
	real scalar df, W

	b = st_matrix(bname)
	V = st_matrix(vname)
	idx = st_matrix(iname)
	bs = b[1, idx]
	Vs = V[idx, idx]
	st_numscalar(wname, .)
	st_numscalar(dfname, .)
	st_numscalar(pname, .)
	if (missing(bs)>0) return
	if (missing(Vs)>0) return
	Vi = invsym(Vs)
	df = rank(Vi)
	if (df < 1) return
	W  = (bs*Vi*bs')
	st_numscalar(wname, W)
	st_numscalar(dfname, df)
	st_numscalar(pname, chi2tail(df, W))
}

// -----------------------------------------------------------------
// Inter-quantile contrast b[j2]-b[j1] with the CORRECT variance
//   Var = V[j1,j1] + V[j2,j2] - 2 V[j1,j2]
// -----------------------------------------------------------------
void _xtcspq_iqr(string scalar bname, string scalar vname,
                 real scalar j1, real scalar j2,
                 string scalar dname, string scalar sname)
{
	real matrix b, V
	real scalar d, v

	b = st_matrix(bname)
	V = st_matrix(vname)
	d = b[1,j2] - b[1,j1]
	v = V[j1,j1] + V[j2,j2] - 2*V[j1,j2]
	st_numscalar(dname, d)
	st_numscalar(sname, .)
	if (v > 0) st_numscalar(sname, sqrt(v))
}

// -----------------------------------------------------------------
// Pesaran (2004, 2015) CD test on a residual variable.
//   CD = sqrt(2/(N(N-1))) sum_{i<j} sqrt(T_ij) rho_ij  ~ N(0,1)
// -----------------------------------------------------------------
void _xtcspq_cd(string scalar rvar, string scalar ivar,
                string scalar tvar, string scalar tousev,
                string scalar cdname, string scalar pname,
                string scalar nname, string scalar tname)
{
	real colvector r, id, tt, uid, ut, ok, ri, rj, ii, jj
	real matrix R, M
	real scalar N, T, i, j, s, cd, np, tij, rij, sw
	real scalar mi, mj, si, sj

	r  = st_data(., rvar,  tousev)
	id = st_data(., ivar,  tousev)
	tt = st_data(., tvar,  tousev)

	uid = uniqrows(id)
	ut  = uniqrows(tt)
	N = rows(uid)
	T = rows(ut)
	st_numscalar(nname, N)
	st_numscalar(tname, T)
	st_numscalar(cdname, .)
	st_numscalar(pname, .)
	if (N < 2) return
	if (T < 3) return

	R = J(T, N, .)
	M = J(T, N, 0)
	for (s=1; s<=rows(r); s++) {
		if (r[s]>=.) continue
		ii = selectindex(uid:==id[s])
		jj = selectindex(ut :==tt[s])
		if (rows(ii)<1) continue
		if (rows(jj)<1) continue
		R[jj[1], ii[1]] = r[s]
		M[jj[1], ii[1]] = 1
	}

	cd = 0
	np = 0
	for (i=1; i<=N-1; i++) {
		for (j=i+1; j<=N; j++) {
			ok = M[.,i]:*M[.,j]
			tij = colsum(ok)
			if (tij < 3) continue
			ri = select(R[.,i], ok)
			rj = select(R[.,j], ok)
			mi = mean(ri)
			mj = mean(rj)
			si = sqrt(quadcross(ri:-mi, ri:-mi))
			sj = sqrt(quadcross(rj:-mj, rj:-mj))
			if (si<=0) continue
			if (sj<=0) continue
			rij = quadcross(ri:-mi, rj:-mj)/(si*sj)
			cd  = cd + sqrt(tij)*rij
			np  = np + 1
		}
	}
	if (np < 1) return
	sw = sqrt(2/(N*(N-1)))*cd
	st_numscalar(cdname, sw)
	st_numscalar(pname, 2*normal(-abs(sw)))
}

// -----------------------------------------------------------------
// Galvao, Juhl, Montes-Rojas & Olmo (2017) slope-homogeneity tests for
// QUANTILE regression panels, applied to the unit-level estimates at
// quantile t.  Their equations (p.5):
//
//   Shat(tau) = sum_i (b_i - b_MD)' (V_i/T)^-1 (b_i - b_MD)
//             -> chi2 with (n-1)k df   as T -> inf, n fixed
//   Dhat(tau) = sqrt(n) [ Shat/n - k ] / sqrt(2k)
//             -> N(0,1)                as (T,n) -> inf
//
// b_MD is the minimum-distance (inverse-variance weighted) estimator,
// and (V_i/T)^-1 is the inverse of the variance of b_i.
//
// NOTE.  This is the quantile-regression Swamy statistic, NOT the
// Pesaran-Yamagata (2008) mean-regression test: PY's bias adjustment
// sqrt(2k(T-k-1)/(T+1)) is derived from the finite-T moments of the
// least-squares Swamy statistic and does not carry over to the quantile
// case, so it is deliberately not applied here.  The dedicated
// standalone implementation, with the Powell kernel variance and a HAC
// option, is Roudane's xtqsh (SSC).
// -----------------------------------------------------------------
void _xtcspq_gjmo(real scalar t, real scalar pfull, real scalar pv,
                  string scalar sname, string scalar dfname,
                  string scalar psname,
                  string scalar dname, string scalar pdname,
                  string scalar nname)
{
	external real matrix XTCSPQ_TH, XTCSPQ_OM, XTCSPQ_OK
	external real matrix XTCSPQ_ADEV, XTCSPQ_RDEV, XTCSPQ_NI
	real matrix Om, Wi, SW, SWi, TH, WW
	real colvector SWb
	real rowvector thi, wmg, dv
	real scalar N, i, c0, r, c, n, S, p, D, ok, df

	N  = rows(XTCSPQ_OK)
	SW = J(pv, pv, 0)
	SWb= J(pv, 1, 0)
	TH = J(0, pv, .)
	WW = J(0, pv*pv, .)
	st_numscalar(sname,.)
	st_numscalar(dfname,.)
	st_numscalar(psname,.)
	st_numscalar(dname,.)
	st_numscalar(pdname,.)
	for (i=1; i<=N; i++) {
		if (XTCSPQ_OK[i,t]!=1) continue
		c0 = (t-1)*pfull
		thi = XTCSPQ_TH[i, (c0+1)..(c0+pv)]
		if (missing(thi)>0) continue
		c0 = (t-1)*pv*pv
		Om = J(pv, pv, .)
		for (r=1; r<=pv; r++) {
			for (c=1; c<=pv; c++) {
				Om[r,c] = XTCSPQ_OM[i, c0+(r-1)*pv+c]
			}
		}
		if (missing(Om)>0) continue
		Wi = invsym(Om)
		ok = 0
		if (missing(Wi)==0) {
			if (min(diagonal(Wi))>0) ok = 1
		}
		if (ok==0) continue
		SW  = SW + Wi
		SWb = SWb + Wi*thi'
		TH  = TH \ thi
		WW  = WW \ rowshape(Wi, 1)
	}
	n = rows(TH)
	st_numscalar(nname, n)
	if (n < 2) return
	SWi = invsym(SW)
	if (missing(SWi)>0) return

	// b_MD, the minimum-distance estimator
	wmg = (SWi*SWb)'

	S = 0
	for (i=1; i<=n; i++) {
		Wi = rowshape(WW[i,.], pv)
		dv = TH[i,.] :- wmg
		S  = S + (dv*Wi*dv')
	}
	p  = pv
	df = (n-1)*p

	// Swamy form: chi2 with (n-1)k df, T large and n fixed
	st_numscalar(sname, S)
	st_numscalar(dfname, df)
	if (df > 0) st_numscalar(psname, chi2tail(df, S))

	// standardized form: N(0,1) as (T,n) -> inf.  One-sided: the
	// alternative is over-dispersion of the b_i, so only large positive
	// values are evidence against homogeneity.
	D = sqrt(n)*( S/n - p )/sqrt(2*p)
	st_numscalar(dname, D)
	st_numscalar(pdname, 1 - normal(D))
}

// -----------------------------------------------------------------
// Koenker & Machado (1999) pseudo-R1, pooled over usable units:
//   R1(tau) = 1 - sum_i Vhat_i(tau) / sum_i Vtilde_i(tau)
// -----------------------------------------------------------------
void _xtcspq_r1(real scalar t, string scalar rname)
{
	external real matrix XTCSPQ_TH, XTCSPQ_OM, XTCSPQ_OK
	external real matrix XTCSPQ_ADEV, XTCSPQ_RDEV, XTCSPQ_NI
	real scalar N, i, a, b
	a = 0
	b = 0
	N = rows(XTCSPQ_OK)
	for (i=1; i<=N; i++) {
		if (XTCSPQ_OK[i,t]!=1) continue
		if (XTCSPQ_ADEV[i,t]>=.) continue
		if (XTCSPQ_RDEV[i,t]>=.) continue
		a = a + XTCSPQ_ADEV[i,t]
		b = b + XTCSPQ_RDEV[i,t]
	}
	st_numscalar(rname, .)
	if (b > 0) st_numscalar(rname, 1 - a/b)
}

// -----------------------------------------------------------------
// Export the unit-level estimate matrix (for plots and unit tables).
// -----------------------------------------------------------------
void _xtcspq_getall(string scalar nm)
{
	external real matrix XTCSPQ_TH, XTCSPQ_OM, XTCSPQ_OK
	external real matrix XTCSPQ_ADEV, XTCSPQ_RDEV, XTCSPQ_NI
	st_matrix(nm, XTCSPQ_TH)
}

void _xtcspq_getok(string scalar nm)
{
	external real matrix XTCSPQ_TH, XTCSPQ_OM, XTCSPQ_OK
	external real matrix XTCSPQ_ADEV, XTCSPQ_RDEV, XTCSPQ_NI
	st_matrix(nm, XTCSPQ_OK)
}

void _xtcspq_drop()
{
	external real matrix XTCSPQ_TH, XTCSPQ_OM, XTCSPQ_OK
	external real matrix XTCSPQ_ADEV, XTCSPQ_RDEV, XTCSPQ_NI
	if (findexternal("XTCSPQ_TH")  !=NULL) rmexternal("XTCSPQ_TH")
	if (findexternal("XTCSPQ_OM")  !=NULL) rmexternal("XTCSPQ_OM")
	if (findexternal("XTCSPQ_OK")  !=NULL) rmexternal("XTCSPQ_OK")
	if (findexternal("XTCSPQ_ADEV")!=NULL) rmexternal("XTCSPQ_ADEV")
	if (findexternal("XTCSPQ_RDEV")!=NULL) rmexternal("XTCSPQ_RDEV")
	if (findexternal("XTCSPQ_NI")  !=NULL) rmexternal("XTCSPQ_NI")
}

end

mata:

// Probe used by _xtcspqardl_mata.ado to decide whether this library is
// already compiled AND complete in the current session.  It is defined
// last, so its mere existence proves the file compiled to the end; it
// also checks every other entry point, so that a session in which one
// function was dropped by hand is detected and recompiled rather than
// failing later with "function not found".
real scalar _xtcspq_ver()
{
	string vector nm
	real scalar i

	nm = ("_xtcspq_init()", "_xtcspq_put()", "_xtcspq_mg()",
	      "_xtcspq_pool()", "_xtcspq_lrdelta()", "_xtcspq_wald()",
	      "_xtcspq_iqr()", "_xtcspq_cd()", "_xtcspq_gjmo()",
	      "_xtcspq_r1()", "_xtcspq_getall()", "_xtcspq_getok()",
	      "_xtcspq_drop()")
	for (i=1; i<=length(nm); i++) {
		if (findexternal(nm[i])==NULL) return(0)
	}
	return(110)
}

end
