*! _xtpqardl_mlib v1.0.4 — Mata computational core for xtpqardl
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Date: August 2026
*!
*! Calling this (no-op) program forces Stata to load this file, which
*! compiles every Mata routine the package needs.  All other xtpqardl
*! components start with  "capture _xtpqardl_mlib".
*!
*! Contents
*!   _xtpq_qrfit     quantile regression by MM (Hunter & Lange 2000)
*!   _xtpq_iidvce    Koenker sparsity-based i.i.d. covariance
*!   _xtpq_vcemat    Powell sandwich: robust / HAC (Newey-West) / cluster
*!   _xtpq_deltamat  delta-method map  (rho, gamma) -> (rho, beta)
*!   _xtpq_run       full per-panel loop, stage 1
*!   _xtpq_run2      full per-panel loop, stage 2 (PMG, pooled long run)
*!   _xtpq_pool_lr   minimum-distance / equal-weight long-run pooling
*!   _xtpq_mg        mean-group averages and covariance matrices

capture program drop _xtpqardl_mlib
program define _xtpqardl_mlib
	version 15.1
end


capture mata: mata drop _xtpq_kw()
capture mata: mata drop _xtpq_iqr()
capture mata: mata drop _xtpq_hsprob()
capture mata: mata drop _xtpq_hsbw()
capture mata: mata drop _xtpq_qrfit()
capture mata: mata drop _xtpq_iidvce()
capture mata: mata drop _xtpq_vcemat()
capture mata: mata drop _xtpq_vce()
capture mata: mata drop _xtpq_deltamat()
capture mata: mata drop _xtpq_delta()
capture mata: mata drop _xtpq_store_init()
capture mata: mata drop _xtpq_store_put()
capture mata: mata drop _xtpq_run()
capture mata: mata drop _xtpq_run2()
capture mata: mata drop _xtpq_pool_lr()
capture mata: mata drop _xtpq_mg()
capture mata: mata drop _xtpq_graft_pool()
capture mata: mata drop _xtpq_legacy()
capture mata: mata drop _xtpq_legacy_panels()
capture mata: mata drop _xtpq_halflife()

version 15.1
mata:
mata set matastrict off

/* =================================================================
   Kernels and bandwidths
   ================================================================= */

real scalar _xtpq_kw(real scalar l, real scalar L, string scalar kern)
{
	real scalar x, d

	if (l == 0) return(1)
	if (L <= 0) return(0)

	if (kern == "bartlett") {
		x = l / (L + 1)
		return(x >= 1 ? 0 : 1 - x)
	}
	if (kern == "parzen") {
		x = l / (L + 1)
		if (x > 1) return(0)
		if (x <= 0.5) return(1 - 6 * x^2 + 6 * x^3)
		return(2 * (1 - x)^3)
	}
	/* quadratic spectral */
	x = l / L
	d = 6 * pi() * x / 5
	return(25 / (12 * pi()^2 * x^2) * (sin(d) / d - cos(d)))
}

real scalar _xtpq_iqr(real colvector u)
{
	real colvector s
	real scalar n

	n = rows(u)
	if (n < 4) return(.)
	s = sort(u, 1)
	return(s[ceil(0.75 * n)] - s[max((1, ceil(0.25 * n)))])
}

/* Hall-Sheather bandwidth on the probability scale */
real scalar _xtpq_hsprob(real scalar n, real scalar tau)
{
	real scalar zt, hs

	if (n < 6) return(.)
	zt = invnormal(tau)
	hs = n^(-1/3) * invnormal(0.975)^(2/3) *
	     (1.5 * normalden(zt)^2 / (2 * zt^2 + 1))^(1/3)
	if (hs >= . | hs <= 0) return(.)
	if (tau - hs <= 0 | tau + hs >= 1) return(.)
	return(hs)
}

/* the same bandwidth expressed in residual units */
real scalar _xtpq_hsbw(real colvector u, real scalar tau)
{
	real colvector s
	real scalar n, hs, lo, hi, cn

	n  = rows(u)
	hs = _xtpq_hsprob(n, tau)
	if (hs >= .) return(.)

	s  = sort(u, 1)
	lo = max((1, ceil((tau - hs) * n)))
	hi = min((n, ceil((tau + hs) * n)))
	if (hi <= lo) return(.)

	cn = s[hi] - s[lo]
	return(cn > 0 ? cn : .)
}


/* =================================================================
   Quantile regression by the MM algorithm of Hunter & Lange (2000)

   min_b sum_i rho_tau(y_i - x_i'b),  rho_tau(r) = |r|/2 + (tau-1/2) r

   |r| is majorised by  r^2/(eps+|r~|) + eps + |r~|  (all over 2), so
   each MM step is the weighted least squares problem

       b+ = (X'WX)^-1 ( X'W y + (2 tau - 1) X'1 ),  w_i = 1/(eps+|r~_i|)

   eps is driven down geometrically, which makes the limit the exact
   quantile regression fit.
   Returns 0 on success, non-zero otherwise; b is filled by reference.
   ================================================================= */
real scalar _xtpq_qrfit(real colvector y, real matrix X, real scalar tau,
                        real rowvector b)
{
	real colvector r, w, bb, bnew, one, bprev
	real matrix    A, Ai
	real scalar    n, k, it, cyc, ep, s, dev, tol

	n = rows(X)
	k = cols(X)
	if (n <= k) return(1)

	A  = quadcross(X, X)
	Ai = invsym(A)
	if (diag0cnt(Ai) > 0) return(2)

	bb  = Ai * quadcross(X, y)          /* OLS start */
	one = colsum(X)'                    /* X'1 */

	r = y - X * bb
	s = mean(abs(r))
	if (s <= 0 | s >= .) s = 1

	ep  = s
	tol = 1e-11

	for (cyc = 1; cyc <= 16; cyc++) {
		ep = ep / 10
		if (ep < 1e-14) ep = 1e-14
		bprev = bb

		for (it = 1; it <= 100; it++) {
			r  = y - X * bb
			w  = 1 :/ (ep :+ abs(r))
			A  = quadcross(X, w, X)
			Ai = invsym(A)
			if (diag0cnt(Ai) > 0) return(3)

			bnew = Ai * (quadcross(X, w, y) + (2 * tau - 1) * one)
			dev  = max(abs(bnew - bb))
			bb   = bnew
			if (dev < tol * (1 + max(abs(bb)))) break
		}
		if (max(abs(bb - bprev)) < tol * (1 + max(abs(bb)))) break
	}

	if (missing(bb)) return(4)
	b = bb'
	return(0)
}


/* =================================================================
   Koenker (2005) i.i.d. covariance:  V = tau(1-tau) s(tau)^2 (X'X)^-1
   ================================================================= */
real matrix _xtpq_iidvce(real colvector y, real matrix X,
                         real rowvector b, real scalar tau)
{
	real colvector u, su
	real matrix    Ai
	real scalar    n, k, h, lo, hi, sp

	n = rows(X)
	k = cols(X)
	u = y - X * b'

	h = _xtpq_hsprob(n, tau)
	if (h >= .) return(J(k, k, .))

	su = sort(u, 1)
	lo = max((1, ceil((tau - h) * n)))
	hi = min((n, ceil((tau + h) * n)))
	if (hi <= lo) return(J(k, k, .))

	sp = (su[hi] - su[lo]) / (2 * h)
	if (sp <= 0 | sp >= .) return(J(k, k, .))

	Ai = invsym(quadcross(X, X))
	if (diag0cnt(Ai) > 0) return(J(k, k, .))

	return(tau * (1 - tau) * sp^2 * Ai)
}


/* =================================================================
   Powell sandwich:  V = (1/n) H^-1 J H^-1

     H = (1/n) sum_t K_h(u_t) x_t x_t'      (uniform kernel, HS width)
     J = (1/n) sum_t sum_s w(|t-s|) psi_t psi_s x_t x_s'
     psi_t = tau - 1{u_t < 0}

   vcetype "robust"  -> w(.) = 1{t = s}
           "hac"     -> Bartlett / Parzen / quadratic-spectral weights,
                        lag distance measured on the time variable
           "cluster" -> full within-group sum (arbitrary correlation)

   tt and cl may be J(0,1,.) when there is no time or group structure.
   ================================================================= */
real matrix _xtpq_vcemat(real colvector y, real matrix X, real rowvector b,
                         real scalar tau, string scalar vcetype,
                         real scalar bwin, string scalar kern,
                         real colvector ttin, real colvector clin)
{
	real colvector u, psi, hd, tt, cl, sg
	real matrix    H, Jm, Hi, V, Xs, gg, ord
	real scalar    n, k, h, sd, iq, L, i, j, d, wl, ng, gstart, cf

	n = rows(X)
	k = cols(X)
	if (n <= k) return(J(k, k, .))

	u   = y - X * b'
	psi = tau :- (u :< 0)

	/* ---- density-weighted Hessian ---- */
	h = _xtpq_hsbw(u, tau)
	if (h <= 0 | h >= .) {
		sd = sqrt(variance(u))
		iq = _xtpq_iqr(u)
		h  = (iq < . & iq > 0) ? min((sd, iq / 1.349)) : sd
		h  = 1.06 * h * n^(-0.2)
		if (h <= 0 | h >= .) return(J(k, k, .))
		hd = normalden(u :/ h) :/ h
	}
	else hd = (abs(u) :< h) :/ h

	H  = quadcross(X, hd, X) / n
	Hi = invsym(H)
	if (diag0cnt(Hi) > 0) return(J(k, k, .))

	/* ---- meat ---- */
	cl = (rows(clin) == n) ? clin : J(n, 1, 1)
	tt = (rows(ttin) == n) ? ttin : (1::n)

	ord = order((cl, tt), (1, 2))
	Xs  = X[ord, .]
	psi = psi[ord]
	cl  = cl[ord]
	tt  = tt[ord]

	if (vcetype == "cluster") {
		Jm = J(k, k, 0)
		ng = 0
		gstart = 1
		for (i = 1; i <= n; i++) {
			if (i == n) {
				sg = quadcolsum(Xs[|gstart, 1 \ i, k|] :*
				                psi[|gstart, 1 \ i, 1|])'
				Jm = Jm + sg * sg'
				ng++
			}
			else if (cl[i + 1] != cl[i]) {
				sg = quadcolsum(Xs[|gstart, 1 \ i, k|] :*
				                psi[|gstart, 1 \ i, 1|])'
				Jm = Jm + sg * sg'
				ng++
				gstart = i + 1
			}
		}
		cf = (ng > 1) ? (ng / (ng - 1)) * ((n - 1) / (n - k)) : 1
	}
	else if (vcetype == "hac") {
		L = bwin
		if (L < 0) L = floor(4 * (n / 100)^(2 / 9))
		if (L < 0) L = 0
		Jm = quadcross(Xs, psi:^2, Xs)
		for (i = 2; i <= n; i++) {
			for (j = i - 1; j >= 1; j--) {
				if (cl[j] != cl[i]) break
				d = tt[i] - tt[j]
				if (d > L & kern != "qs") break
				if (d > 4 * L) break
				if (d < 1) continue
				wl = _xtpq_kw(d, L, kern)
				if (wl == 0) continue
				gg = (psi[i] * psi[j] * wl) * (Xs[i, .]' * Xs[j, .])
				Jm = Jm + gg + gg'
			}
		}
		cf = n / (n - k)
	}
	else {	/* robust */
		Jm = quadcross(Xs, psi:^2, Xs)
		cf = n / (n - k)
	}

	Jm = Jm / n
	V  = cf * Hi * Jm * Hi / n
	_makesymmetric(V)
	return(V)
}

/* Stata-facing wrapper (used by the DFE branch) */
void _xtpq_vce(string scalar yv, string scalar xv, string scalar tousev,
               real scalar tau, string scalar bname, string scalar vout,
               string scalar vcetype, real scalar bwin, string scalar kern,
               string scalar tvarv, string scalar clustv, real scalar cons)
{
	real colvector y, tt, cl
	real matrix    X
	real rowvector b
	real scalar    n

	y = st_data(., yv, tousev)
	X = st_data(., tokens(xv), tousev)
	n = rows(X)
	if (cons) X = X, J(n, 1, 1)

	b = st_matrix(bname)
	if (cols(b) != cols(X)) {
		st_matrix(vout, J(cols(X), cols(X), .))
		return
	}

	tt = (tvarv  != "") ? st_data(., tvarv,  tousev) : J(0, 1, .)
	cl = (clustv != "") ? st_data(., clustv, tousev) : J(0, 1, .)

	st_matrix(vout, _xtpq_vcemat(y, X, b, tau, vcetype, bwin, kern, tt, cl))
}


/* =================================================================
   Delta method:  b = (rho, gamma_1..gamma_kx, rest.., cons)
               -> g = (rho, beta_1..beta_kx, rest..),  beta_j = -gamma_j/rho
   ================================================================= */
void _xtpq_deltamat(real rowvector b, real matrix V, real scalar kx,
                    real scalar nrest, real rowvector g, real matrix Vg)
{
	real matrix G
	real scalar M, K, j, rho

	K = cols(b)
	M = 1 + kx + nrest

	if (K < M) {
		g  = J(1, M, .)
		Vg = J(M, M, .)
		return
	}

	rho = b[1]
	g   = J(1, M, .)
	G   = J(M, K, 0)

	g[1]    = rho
	G[1, 1] = 1

	for (j = 1; j <= kx; j++) {
		if (abs(rho) > 1e-10) {
			g[1 + j]        = -b[1 + j] / rho
			G[1 + j, 1]     =  b[1 + j] / rho^2
			G[1 + j, 1 + j] = -1 / rho
		}
	}
	for (j = 1; j <= nrest; j++) {
		g[1 + kx + j]             = b[1 + kx + j]
		G[1 + kx + j, 1 + kx + j] = 1
	}

	if (rows(V) == K & cols(V) == K) {
		if (V[1, 1] < .) {
			Vg = G * V * G'
			_makesymmetric(Vg)
			return
		}
	}
	Vg = J(M, M, .)
}

/* Stata-facing wrapper (used by the DFE branch) */
void _xtpq_delta(string scalar bname, string scalar vname, real scalar kx,
                 real scalar nrest, string scalar gout, string scalar vgout)
{
	real rowvector b, g
	real matrix    V, Vg

	b = st_matrix(bname)
	V = st_matrix(vname)
	_xtpq_deltamat(b, V, kx, nrest, g, Vg)
	st_matrix(gout,  g)
	st_matrix(vgout, Vg)
}


/* =================================================================
   Per-panel storage
     XTPQ_GA  : npanels x (ntau*M)     derived coefficients
     XTPQ_GV  : npanels x (ntau*M*M)   per-quantile MxM covariance blocks
     XTPQ_GOK : npanels x ntau         1 if that panel/quantile was fitted
   ================================================================= */
void _xtpq_store_init(real scalar np, real scalar nt, real scalar M)
{
	external real matrix XTPQ_GA, XTPQ_GV, XTPQ_GOK
	external real scalar XTPQ_NP, XTPQ_NT, XTPQ_M

	XTPQ_NP = np ; XTPQ_NT = nt ; XTPQ_M = M

	XTPQ_GA  = J(np, nt * M, .)
	XTPQ_GV  = J(np, nt * M * M, .)
	XTPQ_GOK = J(np, nt, 0)
}

void _xtpq_store_put(real scalar pi, real scalar ti,
                     real rowvector g, real matrix V)
{
	external real matrix XTPQ_GA, XTPQ_GV, XTPQ_GOK
	external real scalar XTPQ_M
	real scalar M, o, ov

	M  = XTPQ_M
	o  = (ti - 1) * M
	ov = (ti - 1) * M * M

	XTPQ_GA[pi, (o + 1)..(o + M)] = g
	if (rows(V) == M & cols(V) == M) {
		XTPQ_GV[pi, (ov + 1)..(ov + M * M)] = rowshape(V, 1)
	}
	XTPQ_GOK[pi, ti] = 1
}


/* =================================================================
   Stage 1 — the complete per-panel quantile ARDL loop, in Mata.

   Regressor order in X:  lr_y, lr_x(1..kx), AR lags, short-run terms,
   plus a constant appended last when cons = 1.
   ================================================================= */
void _xtpq_run(string scalar yv, string scalar xv, string scalar iv,
               string scalar tv, string scalar tousev, string scalar tauname,
               real scalar kx, real scalar nrest, real scalar cons,
               string scalar vcetype, real scalar bwin, string scalar kern,
               string scalar snp, string scalar sskip, string scalar sfail,
               string scalar sok)
{
	external real matrix XTPQ_Y, XTPQ_X, XTPQ_ID, XTPQ_TT
	external real colvector XTPQ_PS, XTPQ_PE, XTPQ_PID
	external real scalar XTPQ_KX, XTPQ_NREST, XTPQ_CONS
	external real rowvector XTPQ_TAU
	external string scalar XTPQ_VCE, XTPQ_KERN
	external real scalar XTPQ_BW

	real colvector y, yi, ttv, tti, ps, pe
	real matrix    X, Xi, V, Vg, ord
	real rowvector b, g, taus
	real scalar    n, K, np, nt, i, t, ni, rc, nok, nskip, nfail, M, sandw
	real scalar    anyok

	y   = st_data(., yv, tousev)
	X   = st_data(., tokens(xv), tousev)
	ttv = st_data(., tv, tousev)
	n   = rows(X)
	if (cons) X = X, J(n, 1, 1)
	K = cols(X)

	/* sort by panel then time */
	ord = order((st_data(., iv, tousev), ttv), (1, 2))
	y   = y[ord]
	X   = X[ord, .]
	ttv = ttv[ord]
	XTPQ_ID = st_data(., iv, tousev)[ord]

	/* panel boundaries */
	ps = J(0, 1, .) ; pe = J(0, 1, .)
	if (n > 0) {
		ps = 1
		for (i = 2; i <= n; i++) {
			if (XTPQ_ID[i] != XTPQ_ID[i - 1]) {
				pe = pe \ (i - 1)
				ps = ps \ i
			}
		}
		pe = pe \ n
	}
	np = rows(ps)
	XTPQ_PID = XTPQ_ID[ps]

	taus = st_matrix(tauname)
	nt   = cols(taus)
	M    = 1 + kx + nrest

	/* cache for stage 2 */
	XTPQ_Y = y ; XTPQ_X = X ; XTPQ_TT = ttv
	XTPQ_PS = ps ; XTPQ_PE = pe
	XTPQ_TAU = taus ; XTPQ_KX = kx ; XTPQ_NREST = nrest ; XTPQ_CONS = cons
	XTPQ_VCE = vcetype ; XTPQ_KERN = kern ; XTPQ_BW = bwin

	_xtpq_store_init(np, nt, M)

	sandw = (vcetype == "robust" | vcetype == "hac" | vcetype == "cluster")

	nok = 0 ; nskip = 0 ; nfail = 0

	for (i = 1; i <= np; i++) {
		ni = pe[i] - ps[i] + 1
		if (ni < K + 1) {
			nskip++
			continue
		}
		yi  = y[|ps[i] \ pe[i]|]
		Xi  = X[|ps[i], 1 \ pe[i], K|]
		tti = ttv[|ps[i] \ pe[i]|]

		anyok = 0
		for (t = 1; t <= nt; t++) {
			rc = _xtpq_qrfit(yi, Xi, taus[t], b = .)
			if (rc != 0) {
				nfail++
				continue
			}
			anyok = 1

			if (sandw) {
				V = _xtpq_vcemat(yi, Xi, b, taus[t], vcetype, bwin,
				                 kern, tti, J(0, 1, .))
				if (missing(V)) V = _xtpq_iidvce(yi, Xi, b, taus[t])
			}
			else V = _xtpq_iidvce(yi, Xi, b, taus[t])

			_xtpq_deltamat(b, V, kx, nrest, g = ., Vg = .)
			_xtpq_store_put(i, t, g, Vg)
		}
		if (anyok) nok++
	}

	st_numscalar(snp,   np)
	st_numscalar(sskip, nskip)
	st_numscalar(sfail, nfail)
	st_numscalar(sok,   nok)
}


/* =================================================================
   Stage 2 (PMG) — refit every panel with the pooled long run imposed
       D.y = rho_i(tau) * ECT(tau) + AR + short run + const
       ECT(tau) = lr_y - beta_pooled(tau)' lr_x
   ================================================================= */
void _xtpq_run2(string scalar bpname)
{
	external real matrix XTPQ_Y, XTPQ_X, XTPQ_TT
	external real colvector XTPQ_PS, XTPQ_PE
	external real scalar XTPQ_KX, XTPQ_NREST, XTPQ_CONS
	external real rowvector XTPQ_TAU
	external string scalar XTPQ_VCE, XTPQ_KERN
	external real scalar XTPQ_BW
	external real matrix XTPQ_GA, XTPQ_GV, XTPQ_GOK

	real matrix    GA1, GV1, OK1, X2, Xi, V, Vg, Vfull
	real colvector ect, yi, tti
	real rowvector bp, b, g, gfull, taus
	real scalar    kx, nrest, cons, np, nt, M, K2, i, t, j, ni, rc, sandw
	real scalar    a, c

	kx = XTPQ_KX ; nrest = XTPQ_NREST ; cons = XTPQ_CONS
	taus = XTPQ_TAU ; nt = cols(taus)
	np = rows(XTPQ_PS)
	M  = 1 + kx + nrest
	K2 = 1 + nrest + (cons ? 1 : 0)

	bp = st_matrix(bpname)

	sandw = (XTPQ_VCE == "robust" | XTPQ_VCE == "hac" | XTPQ_VCE == "cluster")

	GA1 = J(np, nt * M, .)
	GV1 = J(np, nt * M * M, .)
	OK1 = J(np, nt, 0)

	for (t = 1; t <= nt; t++) {
		if (missing(bp[1, ((t - 1) * kx + 1)..(t * kx)])) continue

		/* ECT for this quantile, whole sample at once */
		ect = XTPQ_X[., 1] -
		      XTPQ_X[., 2..(1 + kx)] * bp[1, ((t - 1) * kx + 1)..(t * kx)]'

		X2 = ect
		if (nrest > 0) X2 = X2, XTPQ_X[., (2 + kx)..(1 + kx + nrest)]
		if (cons) X2 = X2, J(rows(X2), 1, 1)

		for (i = 1; i <= np; i++) {
			/* keep the stage-1 estimation sample: the restricted fit must
			   not silently add the very short panels that could not
			   support the unrestricted long run */
			if (XTPQ_GOK[i, t] == 0) continue
			ni = XTPQ_PE[i] - XTPQ_PS[i] + 1
			if (ni < K2 + 1) continue

			yi  = XTPQ_Y[|XTPQ_PS[i] \ XTPQ_PE[i]|]
			Xi  = X2[|XTPQ_PS[i], 1 \ XTPQ_PE[i], K2|]
			tti = XTPQ_TT[|XTPQ_PS[i] \ XTPQ_PE[i]|]

			rc = _xtpq_qrfit(yi, Xi, taus[t], b = .)
			if (rc != 0) continue

			if (sandw) {
				V = _xtpq_vcemat(yi, Xi, b, taus[t], XTPQ_VCE, XTPQ_BW,
				                 XTPQ_KERN, tti, J(0, 1, .))
				if (missing(V)) V = _xtpq_iidvce(yi, Xi, b, taus[t])
			}
			else V = _xtpq_iidvce(yi, Xi, b, taus[t])

			/* expand (rho, rest) into the M-vector, leaving beta empty */
			g = J(1, M, .)
			g[1] = b[1]
			for (j = 1; j <= nrest; j++) g[1 + kx + j] = b[1 + j]

			Vfull = J(M, M, .)
			if (rows(V) >= 1 + nrest) {
				if (V[1, 1] < .) {
					Vfull = J(M, M, 0)
					Vfull[1, 1] = V[1, 1]
					for (j = 1; j <= nrest; j++) {
						Vfull[1, 1 + kx + j] = V[1, 1 + j]
						Vfull[1 + kx + j, 1] = V[1 + j, 1]
						for (c = 1; c <= nrest; c++) {
							Vfull[1 + kx + j, 1 + kx + c] = V[1 + j, 1 + c]
						}
					}
				}
			}

			a = (t - 1) * M
			GA1[i, (a + 1)..(a + M)] = g
			a = (t - 1) * M * M
			GV1[i, (a + 1)..(a + M * M)] = rowshape(Vfull, 1)
			OK1[i, t] = 1
		}
	}

	XTPQ_GA = GA1 ; XTPQ_GV = GV1 ; XTPQ_GOK = OK1
}


/* =================================================================
   Long-run pooling
     (a) minimum distance:  beta_P = (sum W_i)^-1 sum W_i beta_i
     (b) fallback when the per-panel variances are unusable (very short
         T): equal weights with the across-panel variance of the mean.
   ================================================================= */
void _xtpq_pool_lr(real scalar kx, string scalar bout, string scalar vout,
                   string scalar nout, string scalar mout)
{
	external real matrix XTPQ_GA, XTPQ_GV, XTPQ_GOK
	external real scalar XTPQ_NP, XTPQ_NT, XTPQ_M

	real matrix    Vi, Wi, SW, SWb, Vp, Bout, Vall, B, D, G, Z
	real colvector rv
	real rowvector bi, bbar
	real scalar    np, nt, M, t, i, o, ov, npool, minpool, allmd, nb, ri, rbar

	np = XTPQ_NP ; nt = XTPQ_NT ; M = XTPQ_M
	Bout = J(1, kx * nt, .)
	Vall = J(kx * nt, kx * nt, 0)
	minpool = .
	allmd   = 1

	for (t = 1; t <= nt; t++) {
		o  = (t - 1) * M
		ov = (t - 1) * M * M
		SW  = J(kx, kx, 0)
		SWb = J(kx, 1, 0)
		npool = 0

		for (i = 1; i <= np; i++) {
			if (XTPQ_GOK[i, t] == 0) continue
			bi = XTPQ_GA[i, (o + 2)..(o + 1 + kx)]
			if (missing(bi)) continue
			Vi = rowshape(XTPQ_GV[i, (ov + 1)..(ov + M * M)], M)
			if (missing(Vi)) continue
			Vi = Vi[|2, 2 \ 1 + kx, 1 + kx|]
			if (missing(Vi)) continue
			if (min(diagonal(Vi)) <= 0) continue
			Wi = invsym(Vi)
			if (diag0cnt(Wi) > 0) continue
			SW  = SW  + Wi
			SWb = SWb + Wi * bi'
			npool++
		}

		if (npool >= 2) {
			Vp = invsym(SW)
			if (diag0cnt(Vp) == 0) {
				Bout[1, ((t - 1) * kx + 1)..(t * kx)] = (Vp * SWb)'
				Vall[|(t - 1) * kx + 1, (t - 1) * kx + 1 \ t * kx, t * kx|] = Vp
				minpool = min((minpool, npool))
				continue
			}
		}

		// ---- (b) fallback: ratio-of-means pooling ------------------
		// beta_i = -gamma_i/rho_i explodes whenever rho_i is close to
		// zero, so the simple average of the beta_i is dominated by a
		// handful of panels.  Pool the structural pieces instead,
		//     beta_P = sum_i gamma_i / sum_i (-rho_i),
		// recovering gamma_i = -beta_i * rho_i from what is stored, and
		// take the variance from the linearisation
		//     z_i = gamma_i - beta_P * (-rho_i),
		//     V   = (1/rhobar^2) * sum z_i z_i' / (nb (nb-1)).
		allmd = 0
		B  = J(0, kx, .)
		rv = J(0, 1, .)
		for (i = 1; i <= np; i++) {
			if (XTPQ_GOK[i, t] == 0) continue
			bi = XTPQ_GA[i, (o + 2)..(o + 1 + kx)]
			if (missing(bi)) continue
			ri = XTPQ_GA[i, o + 1]
			if (ri >= . | ri >= 0) continue
			B  = B \ bi
			rv = rv \ (-ri)
		}
		nb = rows(B)
		if (nb >= 2) {
			G     = B :* rv                       /* gamma_i = beta_i * (-rho_i) */
			rbar  = mean(rv)
			bbar  = mean(G) :/ rbar
			Z     = G :- (rv * bbar)
			Bout[1, ((t - 1) * kx + 1)..(t * kx)] = bbar
			Vall[|(t - 1) * kx + 1, (t - 1) * kx + 1 \ t * kx, t * kx|] =
				quadcross(Z, Z) / (nb * (nb - 1) * rbar^2)
			minpool = min((minpool, nb))
		}
		else minpool = 0
	}

	st_matrix(bout, Bout)
	st_matrix(vout, Vall)
	st_numscalar(nout, minpool == . ? 0 : minpool)
	st_numscalar(mout, allmd)
}


/* =================================================================
   Mean-group averages
     Vnp  : Pesaran-Smith non-parametric across-panel covariance,
            complete cases, so the cross-quantile blocks are filled
     Veff : (1/N^2) sum_i V_i, block diagonal in tau
   ================================================================= */
void _xtpq_mg(real scalar kx, real scalar nrest,
              string scalar gout, string scalar vnpout,
              string scalar veffout, string scalar nout)
{
	external real matrix XTPQ_GA, XTPQ_GV, XTPQ_GOK
	external real scalar XTPQ_NP, XTPQ_NT, XTPQ_M

	real matrix    Vnp, Veff, Vi, D, Gc
	real rowvector gbar, cnt, s, act
	real colvector cc
	real scalar    np, nt, M, GD, i, t, c, nc, o, ov, nv, dev

	np = XTPQ_NP ; nt = XTPQ_NT ; M = XTPQ_M
	GD = nt * M

	gbar = J(1, GD, 0)
	cnt  = J(1, GD, 0)
	for (i = 1; i <= np; i++) {
		for (c = 1; c <= GD; c++) {
			if (XTPQ_GA[i, c] < .) {
				gbar[c] = gbar[c] + XTPQ_GA[i, c]
				cnt[c]  = cnt[c] + 1
			}
		}
	}
	for (c = 1; c <= GD; c++) gbar[c] = (cnt[c] > 0 ? gbar[c] / cnt[c] : .)

	act = J(1, 0, .)
	for (c = 1; c <= GD; c++) {
		if (cnt[c] > 0) act = act, c
	}

	cc = J(0, 1, .)
	if (cols(act) > 0) {
		for (i = 1; i <= np; i++) {
			if (!missing(XTPQ_GA[i, act])) cc = cc \ i
		}
	}
	nc = rows(cc)

	Vnp = J(GD, GD, 0)
	if (nc > 1) {
		// the mean-group estimator and its covariance must come from the
		// same set of panels, otherwise the reported coefficients and the
		// Wald statistics are computed on different samples
		Gc = XTPQ_GA[cc, act]
		s  = mean(Gc)
		D  = Gc :- s
		Vnp[act, act] = quadcross(D, D) / (nc * (nc - 1))
		gbar[act] = s
	}
	else {
		for (c = 1; c <= GD; c++) {
			nv = 0 ; dev = 0
			for (i = 1; i <= np; i++) {
				if (XTPQ_GA[i, c] < . & gbar[c] < .) {
					nv++
					dev = dev + (XTPQ_GA[i, c] - gbar[c])^2
				}
			}
			if (nv > 1) Vnp[c, c] = dev / (nv * (nv - 1))
		}
	}

	Veff = J(GD, GD, 0)
	for (t = 1; t <= nt; t++) {
		o  = (t - 1) * M
		ov = (t - 1) * M * M
		D  = J(M, M, 0)
		nv = 0
		for (i = 1; i <= np; i++) {
			if (XTPQ_GOK[i, t] == 0) continue
			Vi = rowshape(XTPQ_GV[i, (ov + 1)..(ov + M * M)], M)
			if (missing(Vi)) continue
			D = D + Vi
			nv++
		}
		if (nv > 0) Veff[|o + 1, o + 1 \ o + M, o + M|] = D / (nv^2)
	}

	if (sum(diagonal(Veff)) == 0) Veff = Vnp

	_makesymmetric(Vnp)
	_makesymmetric(Veff)

	st_matrix(gout,    gbar)
	st_matrix(vnpout,  Vnp)
	st_matrix(veffout, Veff)
	st_numscalar(nout, nc)
}


void _xtpq_graft_pool(real scalar kx, real scalar nrest,
                      string scalar gname, string scalar vnpname,
                      string scalar veffname,
                      string scalar bpname, string scalar vpname)
{
	external real scalar XTPQ_NT, XTPQ_M
	real rowvector g, bp
	real matrix    Vnp, Veff, Vp
	real scalar    nt, M, t, j, l, o, a, b, r, c, GD

	nt = XTPQ_NT ; M = XTPQ_M
	g    = st_matrix(gname)
	Vnp  = st_matrix(vnpname)
	Veff = st_matrix(veffname)
	bp   = st_matrix(bpname)
	Vp   = st_matrix(vpname)
	GD   = cols(Vnp)

	for (t = 1; t <= nt; t++) {
		o = (t - 1) * M
		for (j = 1; j <= kx; j++) {
			g[o + 1 + j] = bp[1, (t - 1) * kx + j]
			for (c = 1; c <= GD; c++) {
				Vnp[o + 1 + j, c]  = 0 ; Vnp[c, o + 1 + j]  = 0
				Veff[o + 1 + j, c] = 0 ; Veff[c, o + 1 + j] = 0
			}
		}
	}
	for (t = 1; t <= nt; t++) {
		o = (t - 1) * M
		for (j = 1; j <= kx; j++) {
			for (l = 1; l <= kx; l++) {
				r = o + 1 + j ; c = o + 1 + l
				a = (t - 1) * kx + j ; b = (t - 1) * kx + l
				Vnp[r, c]  = Vp[a, b]
				Veff[r, c] = Vp[a, b]
			}
		}
	}

	_makesymmetric(Vnp)
	_makesymmetric(Veff)
	st_matrix(gname,    g)
	st_matrix(vnpname,  Vnp)
	st_matrix(veffname, Veff)
}


void _xtpq_legacy(real scalar kx, real scalar nar, real scalar nsr,
                  string scalar gname, string scalar vname,
                  string scalar rhoout, string scalar betaout,
                  string scalar phiout, string scalar srout,
                  string scalar rhovout, string scalar betavout)
{
	external real scalar XTPQ_NT, XTPQ_M
	real rowvector g, rho, be, ph, sr
	real matrix    V, rV, bV
	real scalar    nt, M, t, j, o, b, t2, o2

	nt = XTPQ_NT ; M = XTPQ_M
	g = st_matrix(gname)
	V = st_matrix(vname)

	rho = J(1, nt, .)
	be  = J(1, max((kx * nt, 1)), .)
	ph  = J(1, max((nar * nt, nt)), .)
	sr  = J(1, max((nsr * nt, 1)), .)
	rV  = J(nt, nt, 0)
	bV  = J(max((kx * nt, 1)), max((kx * nt, 1)), 0)

	for (t = 1; t <= nt; t++) {
		o = (t - 1) * M
		rho[t] = g[o + 1]
		for (j = 1; j <= kx;  j++) be[(t - 1) * kx + j]  = g[o + 1 + j]
		for (j = 1; j <= nar; j++) ph[(t - 1) * nar + j] = g[o + 1 + kx + j]
		for (j = 1; j <= nsr; j++) sr[(t - 1) * nsr + j] = g[o + 1 + kx + nar + j]

		for (t2 = 1; t2 <= nt; t2++) {
			o2 = (t2 - 1) * M
			rV[t, t2] = V[o + 1, o2 + 1]
			for (j = 1; j <= kx; j++) {
				for (b = 1; b <= kx; b++) {
					bV[(t - 1) * kx + j, (t2 - 1) * kx + b] =
						V[o + 1 + j, o2 + 1 + b]
				}
			}
		}
	}

	st_matrix(rhoout,   rho)
	st_matrix(betaout,  be)
	st_matrix(phiout,   ph)
	st_matrix(srout,    sr)
	st_matrix(rhovout,  rV)
	st_matrix(betavout, bV)
}

void _xtpq_legacy_panels(real scalar kx, real scalar nar, real scalar nsr,
                         string scalar rhoout, string scalar betaout,
                         string scalar phiout, string scalar srout,
                         string scalar idout)
{
	external real matrix XTPQ_GA
	external real colvector XTPQ_PID
	external real scalar XTPQ_NP, XTPQ_NT, XTPQ_M
	real matrix rho, be, ph, sr
	real scalar np, nt, M, i, t, j, o

	np = XTPQ_NP ; nt = XTPQ_NT ; M = XTPQ_M

	rho = J(np, nt, .)
	be  = J(np, max((kx * nt, 1)), .)
	ph  = J(np, max((nar * nt, nt)), .)
	sr  = J(np, max((nsr * nt, 1)), .)

	for (i = 1; i <= np; i++) {
		for (t = 1; t <= nt; t++) {
			o = (t - 1) * M
			rho[i, t] = XTPQ_GA[i, o + 1]
			for (j = 1; j <= kx;  j++) be[i, (t - 1) * kx + j]  = XTPQ_GA[i, o + 1 + j]
			for (j = 1; j <= nar; j++) ph[i, (t - 1) * nar + j] = XTPQ_GA[i, o + 1 + kx + j]
			for (j = 1; j <= nsr; j++) sr[i, (t - 1) * nsr + j] = XTPQ_GA[i, o + 1 + kx + nar + j]
		}
	}

	st_matrix(rhoout,  rho)
	st_matrix(betaout, be)
	st_matrix(phiout,  ph)
	st_matrix(srout,   sr)
	st_matrix(idout,   XTPQ_PID)
}

/* Exact half-life: HL = ln(0.5)/ln(1+rho), defined for -2 < rho < 0 */
void _xtpq_halflife(string scalar rhoname, string scalar hlout,
                    real scalar dopanels,
                    string scalar rhoallname, string scalar hlallout)
{
	real rowvector rho, hl
	real matrix    R, H
	real scalar    n, i, j, r

	rho = st_matrix(rhoname)
	n   = cols(rho)
	hl  = J(1, n, .)
	for (j = 1; j <= n; j++) {
		r = rho[j]
		if (r < . & r < 0 & r > -2) hl[j] = ln(0.5) / ln(1 + r)
	}
	st_matrix(hlout, hl)

	if (dopanels) {
		R = st_matrix(rhoallname)
		H = J(rows(R), cols(R), .)
		for (i = 1; i <= rows(R); i++) {
			for (j = 1; j <= cols(R); j++) {
				r = R[i, j]
				if (r < . & r < 0 & r > -2) H[i, j] = ln(0.5) / ln(1 + r)
			}
		}
		st_matrix(hlallout, H)
	}
}
end
