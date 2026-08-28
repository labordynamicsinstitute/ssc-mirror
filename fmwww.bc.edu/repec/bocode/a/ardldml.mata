*! ardldml.mata 1.0.1  24aug2026
*! Mata engine for ardldml -- DML-Bounds (Villena 2026, SSRN 6472826)
*! Dr Merwan Roudane -- merwanroudane920@gmail.com
*! https://github.com/merwanroudane
*
*  Source for lardldml.mlib. The compiled library is what ships and what
*  ardldml.ado calls; this file is kept so the engine is readable and can be
*  rebuilt. To rebuild:  do ardldml_buildmlib.do
*
*  Every function is named against the paper in ardldml_methods.sthlp under
*  "Step-to-equation map".

version 14.0

mata:

// Presence probe. ardldml.ado calls this to check that lardldml.mlib is
// on the library search path before it tries to use the engine, so a
// mid-session install fails with an instruction instead of "function not
// found".
real scalar ardldml_version()
{
	return(1.0)
}

// ----------------------------------------------------------------------
// structures
// ----------------------------------------------------------------------
struct ardldml_opt {
	real scalar lags, blocks, buffer, dcase, cpen, ltol
	real scalar adaptive, penalised, dlags, st3cons
	real scalar penval
	string scalar penrule
}

struct ardldml_des {
	real colvector dY, dD, y0, d0
	real matrix    X, Z, Wlev, dDlag
	real colvector imask
	real scalar    n
	real colvector ylagp, dtp, dtlag, wfp
	string rowvector Xnames, Wnames
}

struct ardldml_fit {
	real colvector coef, support
	real scalar    intercept, lam, estimable
}

struct ardldml_cf {
	real colvector fitted, resid, support
	real scalar    lam, estimable
}

struct ardldml_res {
	real scalar    stat, alpha, theta, theta_se, estimable, n
	real colvector b, dysup, zsup, dYres
	real matrix    V, Zres
	real scalar    lam
}

// ----------------------------------------------------------------------
// small helpers
// ----------------------------------------------------------------------
real scalar ardldml_sd(real colvector x, real scalar ddof)
{
	real scalar n, m, s

	n = rows(x)
	if (n - ddof <= 0) return(0)
	m = mean(x)
	s = quadcross(x :- m, x :- m) / (n - ddof)
	if (s <= 0) return(0)
	return(sqrt(s))
}

real colvector ardldml_lstsq(real matrix X, real colvector y)
{
	return(qrsolve(X, y))
}

// numpy's default (linear / type-7) quantile, so bootstrap critical
// values agree with the reference implementation draw for draw
real scalar ardldml_quantile(real colvector x, real scalar q)
{
	real colvector s
	real scalar N, h, lo

	s = sort(x, 1)
	N = rows(s)
	if (N == 1) return(s[1])
	h = (N - 1) * q
	lo = floor(h)
	if (lo >= N - 1) return(s[N])
	return(s[lo+1] + (h - lo) * (s[lo+2] - s[lo+1]))
}

real scalar ardldml_plugin(real scalar n, real scalar d, real scalar sigma,
	real scalar c)
{
	real scalar dd

	dd = d
	if (dd < 2) dd = 2
	return(c * sqrt(log(dd) / n) * sigma)
}

// Coordinate-descent LASSO for  (1/2n)||y - Xw||^2 + lam*||w||_1.
//
// This is a line-by-line transcription of sklearn's
// cd_fast.enet_coordinate_descent with l2_reg = 0, which is the solver the
// reference implementation calls. The stopping rule is replicated exactly --
// cyclic sweeps until the relative coefficient change falls below `tol` AND
// the duality gap falls below tol*||y||^2 -- and not merely approximated by
// converging harder. That matters: the two-step plug-in penalty reads
// sigma-hat off this solver's residual, so a solution converged to a
// different tolerance shifts lambda and can flip a fold's selected support.
real colvector ardldml_lasso(real matrix X, real colvector y, real scalar lam,
	real scalar maxit, real scalar tol)
{
	real scalar n, p, j, it, tmp, wj, dw, dwmax, wmax, nlam, check
	real scalar dnorm, rn2, wn1, konst, an2, gap, gtol
	real colvector w, R, xn, XtA

	n = rows(X)
	p = cols(X)
	w = J(p, 1, 0)
	R = y
	xn = J(p, 1, 0)
	for (j = 1; j <= p; j++) {
		xn[j] = quadcross(X[., j], X[., j])
	}
	nlam = n * lam
	gtol = tol * quadcross(y, y)

	for (it = 1; it <= maxit; it++) {
		dwmax = 0
		wmax = 0
		for (j = 1; j <= p; j++) {
			if (xn[j] > 0) {
				wj = w[j]
				if (wj != 0) {
					R = R + X[., j] * wj
				}
				tmp = quadcross(X[., j], R)
				w[j] = 0
				if (tmp > nlam) {
					w[j] = (tmp - nlam) / xn[j]
				}
				if (tmp < -nlam) {
					w[j] = (tmp + nlam) / xn[j]
				}
				if (w[j] != 0) {
					R = R - X[., j] * w[j]
				}
				dw = abs(w[j] - wj)
				if (dw > dwmax) dwmax = dw
				if (abs(w[j]) > wmax) wmax = abs(w[j])
			}
		}
		check = 0
		if (wmax == 0) check = 1
		if (wmax > 0) {
			if (dwmax / wmax < tol) check = 1
		}
		if (it == maxit) check = 1
		if (check) {
			XtA = quadcross(X, R)
			dnorm = max(abs(XtA))
			rn2 = quadcross(R, R)
			wn1 = sum(abs(w))
			konst = 1
			gap = rn2
			if (dnorm > nlam) {
				konst = nlam / dnorm
				an2 = rn2 * konst * konst
				gap = 0.5 * (rn2 + an2)
			}
			gap = gap + nlam * wn1 - konst * quadcross(R, y)
			if (gap < gtol) break
		}
	}
	return(w)
}

// adaptive post-LASSO: select on standardised (optionally reweighted)
// columns, then refit the selected support by unpenalised OLS
struct ardldml_fit scalar ardldml_apl(real matrix X, real colvector y,
	real scalar lam_in, real scalar adaptive, real scalar c,
	real colvector amask, real scalar ltol)
{
	struct ardldml_fit scalar f
	real scalar n, p, j, ybar, sigma0, sigma1, lam, nsel
	real rowvector mu, sd
	real matrix Xs, Xw
	real colvector yc, w, marg, den, cw, r0, bs, sel, idx

	n = rows(X)
	p = cols(X)
	mu = mean(X)
	sd = J(1, p, 1)
	for (j = 1; j <= p; j++) {
		sd[j] = sqrt(quadcross(X[., j] :- mu[j], X[., j] :- mu[j]) / n)
		if (sd[j] < 1e-12) sd[j] = 1
	}
	Xs = (X :- mu) :/ sd
	ybar = mean(y)
	yc = y :- ybar

	w = J(p, 1, 1)
	if (adaptive) {
		den = J(p, 1, 1)
		for (j = 1; j <= p; j++) {
			den[j] = quadcross(Xs[., j], Xs[., j])
			if (den[j] < 1e-12) den[j] = 1
		}
		marg = abs(quadcross(Xs, yc)) :/ den
		w = marg
		for (j = 1; j <= p; j++) {
			if (w[j] < 1e-8) w[j] = 1e-8
		}
		if (rows(amask) == p) {
			for (j = 1; j <= p; j++) {
				if (amask[j] == 0) w[j] = 1
			}
		}
	}
	Xw = Xs :* w'

	lam = lam_in
	if (lam >= .) {
		sigma0 = ardldml_sd(yc, 1)
		if (sigma0 == 0) sigma0 = 1
		lam = ardldml_plugin(n, p, sigma0, c)
		cw = ardldml_lasso(Xw, yc, lam, 100000, ltol)
		r0 = yc - Xw * cw
		sigma1 = ardldml_sd(r0, 1)
		if (sigma1 == 0) sigma1 = sigma0
		lam = ardldml_plugin(n, p, sigma1, c)
	}

	cw = ardldml_lasso(Xw, yc, lam, 100000, ltol)
	sel = (abs(cw) :> 1e-10)

	f.coef = J(p, 1, 0)
	f.estimable = 1
	nsel = sum(sel)
	if (nsel > 0) {
		idx = selectindex(sel)
		if (n - nsel - 1 < 1) {
			f.estimable = 0
			for (j = 1; j <= nsel; j++) {
				f.coef[idx[j]] = cw[idx[j]] * w[idx[j]] / sd[idx[j]]
			}
		}
		else {
			bs = ardldml_lstsq(Xs[., idx], yc)
			for (j = 1; j <= nsel; j++) {
				f.coef[idx[j]] = bs[j] / sd[idx[j]]
			}
		}
	}
	f.intercept = ybar - mu * f.coef
	f.support = sel
	f.lam = lam
	return(f)
}

// block edges: replicates numpy's linspace(0, n, K+1).astype(int)
real colvector ardldml_edges(real scalar n, real scalar K)
{
	real colvector e
	real scalar b

	e = J(K + 1, 1, 0)
	for (b = 0; b <= K - 1; b++) {
		e[b+1] = trunc((n / K) * b)
	}
	e[K+1] = n
	return(e)
}

// out-of-fold projection under the h-block partition
struct ardldml_cf scalar ardldml_crossfit(real matrix X, real colvector y,
	real scalar K, real scalar h, real scalar lam, real scalar adaptive,
	real scalar c, real scalar penalised, real colvector amask,
	real scalar ltol)
{
	struct ardldml_cf scalar out
	struct ardldml_fit scalar f
	real colvector e, keep, tr, ev, coef, b
	real scalar n, p, blk, lo, hi, xlo, xhi, cons, i
	real matrix Xtr

	n = rows(X)
	p = cols(X)
	e = ardldml_edges(n, K)
	out.fitted = J(n, 1, .)
	out.support = J(p, 1, 0)
	out.estimable = 1
	out.lam = .

	for (blk = 1; blk <= K; blk++) {
		lo = e[blk] + 1
		hi = e[blk+1]
		if (hi >= lo) {
			ev = (lo::hi)
			keep = J(n, 1, 1)
			xlo = lo - h
			if (xlo < 1) xlo = 1
			xhi = hi + h
			if (xhi > n) xhi = n
			for (i = xlo; i <= xhi; i++) {
				keep[i] = 0
			}
			if (sum(keep) == 0) {
				_error(3498, "buffer() is too wide: a block has an empty training set")
			}
			tr = selectindex(keep)
			if (penalised) {
				f = ardldml_apl(X[tr, .], y[tr], lam, adaptive, c, amask, ltol)
				coef = f.coef
				cons = f.intercept
				out.support = out.support :| f.support
				out.lam = f.lam
				if (f.estimable == 0) out.estimable = 0
			}
			else {
				Xtr = J(rows(tr), 1, 1), X[tr, .]
				b = ardldml_lstsq(Xtr, y[tr])
				cons = b[1]
				coef = b[|2 \ p+1|]
				out.support = J(p, 1, 1)
				if (rows(tr) - p - 1 <= 0) out.estimable = 0
			}
			out.fitted[ev] = X[ev, .] * coef :+ cons
		}
	}
	out.resid = y - out.fitted
	return(out)
}

// rolling-origin time-series cross-validation for the Delta-Y penalty (eq 11)
real scalar ardldml_tscv(real matrix X, real colvector y, string scalar rule,
	real scalar c, real scalar ltol)
{
	struct ardldml_fit scalar f
	real scalar n, p, mint, ng, gi, t, j, nor, base, se, lmin, l1se, pred, m0
	real colvector grid, mse, s2
	real matrix sq

	n = rows(X)
	p = cols(X)
	mint = trunc(n / 3)
	if (mint < 20) mint = 20
	base = ardldml_plugin(n, p, ardldml_sd(y, 1), c)
	if (mint >= n - 1) return(base)

	ng = 20
	grid = J(ng, 1, 0)
	for (gi = 1; gi <= ng; gi++) {
		grid[gi] = (base / 10) * exp((gi - 1) / (ng - 1) * log(100))
	}
	nor = n - mint
	sq = J(ng, nor, 0)
	for (gi = 1; gi <= ng; gi++) {
		j = 0
		for (t = mint + 1; t <= n; t++) {
			j = j + 1
			f = ardldml_apl(X[|1, 1 \ t-1, p|], y[|1 \ t-1|], grid[gi], 0, c,
				J(0, 1, 0), ltol)
			pred = X[t, .] * f.coef + f.intercept
			sq[gi, j] = (y[t] - pred) ^ 2
		}
	}
	mse = J(ng, 1, 0)
	for (gi = 1; gi <= ng; gi++) {
		mse[gi] = mean(sq[gi, .]')
	}
	m0 = min(mse)
	s2 = selectindex(mse :== m0)
	gi = s2[1]
	lmin = grid[gi]
	se = 0
	if (nor > 1) se = ardldml_sd(sq[gi, .]', 1) / sqrt(nor)
	l1se = lmin
	for (j = 1; j <= ng; j++) {
		if (mse[j] <= m0 + se) l1se = grid[j]
	}
	if (rule == "1se") return(l1se)
	if (rule == "mid") return(sqrt(lmin * l1se))
	return(lmin)
}

// ----------------------------------------------------------------------
// balanced design (Section 3.5 / 4.1)
// ----------------------------------------------------------------------
struct ardldml_des scalar ardldml_design(real colvector y, real colvector d,
	real matrix W, real colvector imask, real colvector iord,
	real scalar lags, real scalar dlags, string rowvector wnames,
	string scalar ynm, string scalar dnm)
{
	struct ardldml_des scalar D
	real scalar N, n, t0, p, dW, j, i, nc, pos
	real colvector idx, dYa, dDa, sidx
	real matrix dWa, X

	N = rows(y)
	p = lags
	dW = cols(W)
	t0 = p + 2
	n = N - t0 + 1
	idx = (t0::N)

	dYa = J(N, 1, .)
	dDa = J(N, 1, .)
	dYa[|2 \ N|] = y[|2 \ N|] - y[|1 \ N-1|]
	dDa[|2 \ N|] = d[|2 \ N|] - d[|1 \ N-1|]
	dWa = J(N, dW, .)
	if (dW > 0) {
		dWa[|2, 1 \ N, dW|] = W[|2, 1 \ N, dW|] - W[|1, 1 \ N-1, dW|]
	}

	// stationary control positions, in controls() order
	sidx = J(0, 1, 0)
	for (j = 1; j <= dW; j++) {
		if (imask[j] == 0) sidx = sidx \ j
	}
	if (rows(sidx) + rows(iord) != dW) {
		_error(3498, "integrated() classification does not partition controls()")
	}

	nc = rows(sidx) + rows(iord) + p + 1
	if (dlags) nc = nc + p
	X = J(n, nc, .)
	D.Xnames = J(1, nc, "")
	pos = 0
	for (j = 1; j <= rows(sidx); j++) {
		pos = pos + 1
		X[., pos] = W[idx, sidx[j]]
		D.Xnames[pos] = wnames[sidx[j]]
	}
	for (j = 1; j <= rows(iord); j++) {
		pos = pos + 1
		X[., pos] = dWa[idx, iord[j]]
		D.Xnames[pos] = "D." + wnames[iord[j]]
	}
	D.wfp = J(0, 1, 0)
	if (pos > 0) D.wfp = (1::pos)
	D.ylagp = J(p, 1, 0)
	for (i = 1; i <= p; i++) {
		pos = pos + 1
		X[., pos] = dYa[idx :- i]
		D.Xnames[pos] = "D." + ynm + ".L" + strofreal(i)
		D.ylagp[i] = pos
	}
	nc = p + 1
	if (dlags == 0) nc = 1
	D.dtp = J(nc, 1, 0)
	D.dtlag = J(nc, 1, 0)
	j = 0
	if (dlags) {
		for (i = 1; i <= p; i++) {
			pos = pos + 1
			X[., pos] = dDa[idx :- i]
			D.Xnames[pos] = "D." + dnm + ".L" + strofreal(i)
			j = j + 1
			D.dtp[j] = pos
			D.dtlag[j] = i
		}
	}
	pos = pos + 1
	X[., pos] = dDa[idx]
	D.Xnames[pos] = "D." + dnm
	j = j + 1
	D.dtp[j] = pos
	D.dtlag[j] = 0

	D.dDlag = J(n, p, .)
	for (i = 1; i <= p; i++) {
		D.dDlag[., i] = dDa[idx :- i]
	}

	D.dY = dYa[idx]
	D.dD = dDa[idx]
	D.X = X
	D.Z = (y[idx :- 1], d[idx :- 1])
	D.Wlev = W[idx, .]
	D.imask = imask
	D.n = n
	D.Wnames = wnames
	D.y0 = y[t0 - 1]
	D.d0 = d[t0 - 1]
	return(D)
}

// ----------------------------------------------------------------------
// the statistic (eq 10 + the F form of the Wald test)
// ----------------------------------------------------------------------
struct ardldml_res scalar ardldml_compute(struct ardldml_des scalar D,
	struct ardldml_opt scalar O, real colvector frozen)
{
	struct ardldml_res scalar R
	struct ardldml_cf scalar fdy, fz
	real scalar n, j, s2, dof, piy, pix, nfz, vt
	real matrix Xs, Xu, Zres, Vb, XX
	real colvector dy, amask, b, resid, g, fidx, sup

	n = D.n
	dy = D.dY
	Xs = D.X
	fidx = J(0, 1, 0)
	nfz = 0
	if (rows(frozen) == cols(D.X)) {
		nfz = sum(frozen)
	}
	if (nfz > 0) {
		fidx = selectindex(frozen)
		Xu = Xs[., fidx]
	}
	else {
		Xu = Xs
	}

	// Delta-Y penalty
	R.lam = .
	if (O.penval < .) {
		R.lam = O.penval
	}
	if (O.penval >= . & O.penalised & O.penrule != "plugin") {
		R.lam = ardldml_tscv(Xu, dy, O.penrule, O.cpen, O.ltol)
	}

	// stationary projection: plain LASSO
	fdy = ardldml_crossfit(Xu, dy, O.blocks, O.buffer, R.lam, 0, O.cpen,
		O.penalised, J(0, 1, 0), O.ltol)
	if (R.lam >= .) R.lam = fdy.lam

	// map the support back to the full design width when it was frozen,
	// or the frozen mask on the next bootstrap path is misaligned
	sup = fdy.support
	if (nfz > 0) {
		sup = J(cols(D.X), 1, 0)
		for (j = 1; j <= rows(fidx); j++) {
			if (fdy.support[j] == 1) sup[fidx[j]] = 1
		}
	}

	// level projections: adaptive weights on the integrated block only
	amask = D.imask
	if (O.adaptive == 0) amask = J(0, 1, 0)
	Zres = J(n, 2, .)
	R.zsup = J(cols(D.Wlev), 1, 0)
	R.estimable = fdy.estimable
	for (j = 1; j <= 2; j++) {
		fz = ardldml_crossfit(D.Wlev, D.Z[., j], O.blocks, O.buffer, .,
			O.adaptive, O.cpen, O.penalised, amask, O.ltol)
		Zres[., j] = fz.resid
		R.zsup = R.zsup :| fz.support
		if (fz.estimable == 0) R.estimable = 0
	}

	// eq (10): unpenalised, no-intercept regression on the orthogonalised terms
	Xs = Zres
	if (O.st3cons) Xs = J(n, 1, 1), Zres
	b = ardldml_lstsq(Xs, fdy.resid)
	resid = fdy.resid - Xs * b
	dof = n - cols(Xs)
	R.stat = .
	R.alpha = .
	R.theta = .
	R.theta_se = .
	R.n = n
	R.dYres = fdy.resid
	R.Zres = Zres
	R.dysup = sup
	if (dof <= 0) {
		R.estimable = 0
		return(R)
	}

	s2 = quadcross(resid, resid) / dof
	XX = quadcross(Xs, Xs)
	Vb = s2 * invsym(XX)
	if (O.st3cons) {
		Vb = Vb[|2, 2 \ 3, 3|]
		b = b[|2 \ 3|]
	}
	R.b = b
	R.V = Vb
	R.stat = (b' * invsym(Vb) * b) / 2
	piy = b[1]
	pix = b[2]
	R.alpha = -piy
	if (abs(R.alpha) < 1e-12) return(R)
	R.theta = pix / R.alpha
	g = (pix / (piy * piy) \ -1 / piy)
	vt = g' * Vb * g
	if (vt < 0) vt = 0
	R.theta_se = sqrt(vt)
	return(R)
}

// ----------------------------------------------------------------------
// Algorithm 1: restricted system wild bootstrap
// ----------------------------------------------------------------------
real colvector ardldml_boot(real colvector y, real colvector d, real matrix W,
	real colvector imask, real colvector iord, struct ardldml_opt scalar O,
	string rowvector wnames, string scalar ynm, string scalar dnm,
	real scalar B, real scalar system, real colvector frozen,
	real colvector dysup, string scalar etafile, string scalar corrout,
	string scalar nbout)
{
	struct ardldml_des scalar D, Db
	struct ardldml_res scalar Rb
	real scalar n, p, i, j, t, b, lag, val, nw
	real colvector dy, dD, eps, vhat, bc, bm, eta, dDs, dYs, ys, ds
	real colvector wsel, out, wcon, wmcon, epss, vs
	real matrix Xr, Xm, ETA, cc
	real scalar cconst, mconst

	D = ardldml_design(y, d, W, imask, iord, O.lags, O.dlags, wnames, ynm, dnm)
	n = D.n
	p = O.lags
	dy = D.dY
	dD = D.dD

	// ---- restricted conditional model under H0 -----------------------
	// same deterministics and short-run structure, no lagged levels and
	// no control levels
	Xr = J(n, 0, .)
	if (O.dcase != 1) Xr = J(n, 1, 1)
	Xr = Xr, D.X[., D.ylagp], D.X[., D.dtp], D.X[., D.wfp]
	bc = ardldml_lstsq(Xr, dy)
	eps = dy - Xr * bc

	j = 0
	cconst = 0
	if (O.dcase != 1) {
		j = 1
		cconst = bc[1]
	}
	// coefficients, in the order they were stacked
	nw = rows(D.wfp)
	wcon = J(n, 1, 0)
	if (nw > 0) {
		wcon = D.X[., D.wfp] * bc[|j + p + rows(D.dtp) + 1 \ j + p + rows(D.dtp) + nw|]
	}

	// ---- marginal model for Delta-D ---------------------------------
	// intercept, own lags, and the first-stage-selected differenced controls
	wsel = J(0, 1, 0)
	if (rows(dysup) == cols(D.X)) {
		for (i = 1; i <= nw; i++) {
			if (dysup[D.wfp[i]] == 1) wsel = wsel \ D.wfp[i]
		}
	}
	if (rows(wsel) == 0) wsel = D.wfp
	Xm = J(n, 1, 1), D.dDlag
	if (rows(wsel) > 0) Xm = Xm, D.X[., wsel]
	bm = ardldml_lstsq(Xm, dD)
	vhat = dD - Xm * bm
	mconst = bm[1]
	wmcon = J(n, 1, 0)
	if (rows(wsel) > 0) {
		wmcon = D.X[., wsel] * bm[|p + 2 \ p + 1 + rows(wsel)|]
	}

	cc = correlation((eps, vhat))
	st_numscalar(corrout, cc[1, 2])

	// ---- externally supplied Rademacher weights (verification) ------
	ETA = J(0, 0, .)
	if (etafile != "") {
		ETA = ardldml_readmat(etafile)
		if (cols(ETA) != n) {
			_error(3498, "etafile() must have " + strofreal(n) + " columns")
		}
	}

	out = J(B, 1, .)
	for (b = 1; b <= B; b++) {
		if (rows(ETA) > 0) {
			eta = ETA[mod(b - 1, rows(ETA)) + 1, .]'
		}
		else {
			eta = 2 :* (runiform(n, 1) :< 0.5) :- 1
		}
		epss = eps :* eta

		dDs = J(n, 1, 0)
		if (system) {
			vs = vhat :* eta
			for (t = 1; t <= n; t++) {
				val = mconst + wmcon[t] + vs[t]
				for (i = 1; i <= p; i++) {
					if (t - i >= 1) {
						val = val + bm[i+1] * dDs[t-i]
					}
					else {
						val = val + bm[i+1] * D.dDlag[t, i]
					}
				}
				dDs[t] = val
			}
		}
		else {
			dDs = dD
		}

		dYs = J(n, 1, 0)
		for (t = 1; t <= n; t++) {
			val = cconst + wcon[t] + epss[t]
			for (i = 1; i <= p; i++) {
				if (t - i >= 1) {
					val = val + bc[j+i] * dYs[t-i]
				}
				else {
					val = val + bc[j+i] * D.X[t, D.ylagp[i]]
				}
			}
			for (i = 1; i <= rows(D.dtp); i++) {
				lag = D.dtlag[i]
				if (t - lag >= 1) {
					val = val + bc[j+p+i] * dDs[t-lag]
				}
				else {
					val = val + bc[j+p+i] * D.X[t, D.dtp[i]]
				}
			}
			dYs[t] = val
		}

		ys = D.y0 :+ runningsum(dYs)
		ds = D.d0 :+ runningsum(dDs)

		Db = ardldml_design(ys, ds, D.Wlev, imask, iord, O.lags, O.dlags,
			wnames, ynm, dnm)
		Rb = ardldml_compute(Db, O, frozen)
		out[b] = Rb.stat
		if (b == 1) st_numscalar(nbout, Rb.n)
	}
	return(out)
}

// read a whitespace/comma separated numeric matrix from a text file
real matrix ardldml_readmat(string scalar fn)
{
	real scalar fh
	real matrix M
	real rowvector r
	string scalar line

	M = J(0, 0, .)
	fh = fopen(fn, "r")
	line = fget(fh)
	while (line != J(0, 0, "")) {
		line = subinstr(line, ",", " ")
		r = strtoreal(tokens(line))
		if (cols(r) > 0) {
			if (rows(M) == 0) {
				M = r
			}
			else {
				if (cols(r) == cols(M)) M = M \ r
			}
		}
		line = fget(fh)
	}
	fclose(fh)
	return(M)
}

// ----------------------------------------------------------------------
// driver
// ----------------------------------------------------------------------
void ardldml_main(string scalar ynm, string scalar dnm, string scalar wnm,
	string scalar inm, string scalar touse)
{
	struct ardldml_opt scalar O
	struct ardldml_des scalar D
	struct ardldml_res scalar R
	real scalar j, i, dW, K, h, B, doboot, system, level, nf
	real colvector y, d, imask, iord, frozen, draws, good, e
	real matrix W, F
	string rowvector wnames, inames
	string scalar sels, selz, etafile

	y = st_data(., ynm, touse)
	d = st_data(., dnm, touse)
	W = st_data(., wnm, touse)
	wnames = tokens(wnm)
	inames = tokens(inm)
	dW = cols(W)

	imask = J(dW, 1, 0)
	iord = J(0, 1, 0)
	for (i = 1; i <= cols(inames); i++) {
		for (j = 1; j <= dW; j++) {
			if (wnames[j] == inames[i]) {
				imask[j] = 1
				iord = iord \ j
			}
		}
	}

	O.lags      = strtoreal(st_local("lags"))
	O.blocks    = strtoreal(st_local("blocks"))
	O.buffer    = strtoreal(st_local("buffer"))
	O.dcase      = strtoreal(st_local("case"))
	O.cpen      = strtoreal(st_local("cpen"))
	O.ltol      = strtoreal(st_local("ltol"))
	O.adaptive  = strtoreal(st_local("adaptive"))
	O.penalised = strtoreal(st_local("penalised"))
	O.dlags     = strtoreal(st_local("usedl"))
	O.st3cons   = strtoreal(st_local("st3c"))
	O.penval    = strtoreal(st_local("penval"))
	O.penrule   = st_local("penalty")
	if (O.penrule == "low")    O.penrule = "min"
	if (O.penrule == "tscv")   O.penrule = "min"
	if (O.penrule == "medium") O.penrule = "mid"
	if (O.penrule == "high")   O.penrule = "1se"

	D = ardldml_design(y, d, W, imask, iord, O.lags, O.dlags, wnames, ynm, dnm)
	if (D.n < 12) {
		_error(2001, "too few observations after building the balanced design")
	}
	R = ardldml_compute(D, O, J(0, 1, 0))

	st_numscalar("__ardldml_ok", R.estimable)
	st_numscalar("__ardldml_n", R.n)
	st_numscalar("__ardldml_F", R.stat)
	st_numscalar("__ardldml_alpha", R.alpha)
	st_numscalar("__ardldml_theta", R.theta)
	st_numscalar("__ardldml_theta_se", R.theta_se)
	st_numscalar("__ardldml_dw", dW)
	st_numscalar("__ardldml_di", sum(imask))
	st_numscalar("__ardldml_nseldy", sum(R.dysup))
	st_numscalar("__ardldml_nselz", sum(R.zsup))
	st_numscalar("__ardldml_lam", R.lam)
	if (R.estimable == 0) return

	st_matrix("__ardldml_b", R.b')
	st_matrix("__ardldml_V", R.V)

	sels = ""
	for (j = 1; j <= rows(R.dysup); j++) {
		if (R.dysup[j] == 1) sels = sels + " " + D.Xnames[j]
	}
	selz = ""
	for (j = 1; j <= rows(R.zsup); j++) {
		if (R.zsup[j] == 1) selz = selz + " " + wnames[j]
	}
	st_global("__ardldml_seldy", strtrim(sels))
	st_global("__ardldml_selz", strtrim(selz))

	// fold table
	K = O.blocks
	h = O.buffer
	e = ardldml_edges(D.n, K)
	F = J(K, 5, 0)
	for (j = 1; j <= K; j++) {
		F[j, 1] = e[j] + 1
		F[j, 2] = e[j+1]
		F[j, 3] = e[j+1] - e[j]
		i = e[j] + 1 - h
		if (i < 1) i = 1
		nf = e[j+1] + h
		if (nf > D.n) nf = D.n
		F[j, 4] = D.n - (nf - i + 1)
		F[j, 5] = F[j, 4] / D.n
	}
	st_matrix("__ardldml_folds", F)

	doboot = (st_local("doboot") == "1")
	if (doboot == 0) return

	B = strtoreal(st_local("breps"))
	system = (st_local("bscheme") == "system")
	level = strtoreal(st_local("level"))
	etafile = st_local("etafile")

	frozen = J(0, 1, 0)
	if (st_local("freeze") == "1") {
		if (sum(R.dysup) > 0) frozen = R.dysup
	}

	draws = ardldml_boot(y, d, W, imask, iord, O, wnames, ynm, dnm, B, system,
		frozen, R.dysup, etafile, "__ardldml_correv", "__ardldml_nboot")

	good = select(draws, draws :< .)
	if (rows(good) == 0) {
		_error(3498, "every bootstrap draw failed; check the specification")
	}
	st_numscalar("__ardldml_B", B)
	st_numscalar("__ardldml_nfail", B - rows(good))
	st_numscalar("__ardldml_crit", ardldml_quantile(good, level / 100))
	st_numscalar("__ardldml_p", mean(good :>= R.stat))
	st_matrix("__ardldml_draws", good)
}

// ----------------------------------------------------------------------
// Classical benchmark: the Pesaran-Shin-Smith conditional ECM and the
// bounds bracket, regenerated from the Table CI data-generating process
// rather than transcribed from a table. Reproduced from the reference
// implementation's ardldml.critvals.
// ----------------------------------------------------------------------
real scalar ardldml_wald(real colvector dy, real matrix z, real matrix w)
{
	real matrix X, XX, V
	real colvector b, r
	real scalar nrest, dof, s2, q

	X = z
	if (cols(w) > 0) X = z, w
	nrest = cols(z)
	dof = rows(X) - cols(X)
	if (dof <= 0) return(.)
	b = ardldml_lstsq(X, dy)
	r = dy - X * b
	s2 = quadcross(r, r) / dof
	XX = invsym(quadcross(X, X))
	V = s2 * XX[|1, 1 \ nrest, nrest|]
	q = b[|1 \ nrest|]' * invsym(V) * b[|1 \ nrest|]
	return(q / nrest)
}

// one side of the bracket: regressors purely I(1) or purely I(0)
real colvector ardldml_pss_side(real scalar k, real scalar dcase,
	real scalar T, real scalar nsim, real scalar integ)
{
	real colvector out, y, dy, one, trend
	real matrix e, x, z, w
	real scalar i, j

	out = J(nsim, 1, .)
	one = J(T, 1, 1)
	trend = (1::T)
	for (i = 1; i <= nsim; i++) {
		e = rnormal(T + 1, k + 1, 0, 1)
		y = runningsum(e[., 1])
		x = J(T + 1, 0, .)
		if (k > 0) {
			x = e[|1, 2 \ T+1, k+1|]
			if (integ) {
				// runningsum() takes a vector, so cumulate column by column
				for (j = 1; j <= k; j++) {
					x[., j] = runningsum(x[., j])
				}
			}
		}
		z = y[|1 \ T|]
		if (k > 0) z = z, x[|1, 1 \ T, k|]
		w = J(T, 0, .)
		if (dcase == 2) z = z, one
		if (dcase == 3) w = one
		if (dcase == 4) {
			z = z, trend
			w = one
		}
		if (dcase == 5) w = one, trend
		dy = y[|2 \ T+1|] - y[|1 \ T|]
		out[i] = ardldml_wald(dy, z, w)
	}
	return(select(out, out :< .))
}

void ardldml_pss(string scalar outmat, real scalar k, real scalar dcase,
	real scalar T, real scalar nsim, real colvector levels)
{
	real colvector lo, hi
	real matrix R
	real scalar i

	lo = ardldml_pss_side(k, dcase, T, nsim, 0)
	hi = ardldml_pss_side(k, dcase, T, nsim, 1)
	R = J(rows(levels), 3, .)
	for (i = 1; i <= rows(levels); i++) {
		R[i, 1] = levels[i]
		R[i, 2] = ardldml_quantile(lo, 1 - levels[i])
		R[i, 3] = ardldml_quantile(hi, 1 - levels[i])
	}
	st_matrix(outmat, R)
}

// The classical conditional error-correction model of Pesaran, Shin and
// Smith (2001): all three steps -- the joint F on the lagged levels, the
// t test on the speed of adjustment, and the Wald test on the long-run
// coefficients.
void ardldml_classical(string scalar ynm, string scalar xnm,
	string scalar touse, real scalar lags, real scalar order,
	real scalar dcase, string scalar pre)
{
	real colvector y, dy, b, r, pix, theta, cf
	real matrix X, XM, V, J1, Vt, Vth, x, dx
	real scalar N, n, k, i, j, t0, dof, s2, piy, sey, alpha, tw
	real colvector idx

	y = st_data(., ynm, touse)
	x = st_data(., xnm, touse)
	N = rows(y)
	k = cols(x)
	t0 = max((lags, order)) + 1
	if (t0 < 2) t0 = 2
	n = N - t0 + 1
	idx = (t0::N)

	dy = J(N, 1, .)
	dy[|2 \ N|] = y[|2 \ N|] - y[|1 \ N-1|]
	dx = J(N, k, .)
	dx[|2, 1 \ N, k|] = x[|2, 1 \ N, k|] - x[|1, 1 \ N-1, k|]

	// tested level terms first, so the Wald block is the leading submatrix
	X = y[idx :- 1]
	for (j = 1; j <= k; j++) {
		X = X, x[idx :- 1, j]
	}
	if (dcase == 2) X = X, J(n, 1, 1)
	if (dcase == 4) X = X, idx
	// untested deterministics and short-run dynamics
	if (dcase == 3 | dcase == 4 | dcase == 5) X = X, J(n, 1, 1)
	if (dcase == 5) X = X, idx
	for (i = 1; i <= lags - 1; i++) {
		X = X, dy[idx :- i]
	}
	for (j = 1; j <= k; j++) {
		for (i = 0; i <= order - 1; i++) {
			X = X, dx[idx :- i, j]
		}
	}

	dof = n - cols(X)
	if (dof <= 0) {
		st_numscalar(pre + "ok", 0)
		return
	}
	b = ardldml_lstsq(X, dy[idx])
	r = dy[idx] - X * b
	s2 = quadcross(r, r) / dof
	V = s2 * invsym(quadcross(X, X))

	// number of restrictions: k+1 level terms, +1 in cases 2 and 4
	j = k + 1
	if (dcase == 2 | dcase == 4) j = k + 2
	Vt = V[|1, 1 \ j, j|]
	cf = b[|1 \ j|]
	st_numscalar(pre + "F", (cf' * invsym(Vt) * cf) / j)
	st_numscalar(pre + "nrest", j)

	piy = b[1]
	sey = sqrt(V[1, 1])
	st_numscalar(pre + "t", piy / sey)
	alpha = -piy
	st_numscalar(pre + "alpha", alpha)

	// step 3: theta = pi_x / alpha, delta method
	pix = b[|2 \ k+1|]
	theta = pix :/ alpha
	J1 = J(k, cols(X), 0)
	for (i = 1; i <= k; i++) {
		J1[i, i+1] = 1 / alpha
		J1[i, 1] = pix[i] / (alpha * alpha)
	}
	Vth = J1 * V * J1'
	tw = theta' * invsym(Vth) * theta
	st_numscalar(pre + "wald", tw)
	st_numscalar(pre + "waldp", chi2tail(k, tw))
	st_numscalar(pre + "N", n)
	st_numscalar(pre + "k", k)
	st_numscalar(pre + "ok", 1)
	st_matrix(pre + "theta", theta')
	st_matrix(pre + "setheta", sqrt(diagonal(Vth))')
}

// ----------------------------------------------------------------------
// predict: rebuild the first stage from e() and hand back the
// orthogonalised series. Nothing is cached at estimation time, so this
// recomputes -- cheap, and it guarantees predict cannot drift from the
// fit it claims to describe.
// ----------------------------------------------------------------------
void ardldml_predict(string scalar v1, string scalar v2, string scalar v3,
	string scalar touse)
{
	struct ardldml_opt scalar O
	struct ardldml_des scalar D
	struct ardldml_res scalar R
	real colvector y, d, imask, iord
	real matrix W, out
	real scalar i, j, dW, n, N
	string rowvector wnames, inames
	string scalar ynm, dnm

	ynm = st_global("e(depvar)")
	dnm = st_global("e(focal)")
	wnames = tokens(st_global("e(controls)"))
	inames = tokens(st_global("e(integrated)"))

	y = st_data(., ynm, touse)
	d = st_data(., dnm, touse)
	W = st_data(., st_global("e(controls)"), touse)
	dW = cols(W)

	imask = J(dW, 1, 0)
	iord = J(0, 1, 0)
	for (i = 1; i <= cols(inames); i++) {
		for (j = 1; j <= dW; j++) {
			if (wnames[j] == inames[i]) {
				imask[j] = 1
				iord = iord \ j
			}
		}
	}

	O.lags      = st_numscalar("e(lags)")
	O.blocks    = st_numscalar("e(blocks)")
	O.buffer    = st_numscalar("e(buffer)")
	O.dcase     = st_numscalar("e(case)")
	O.cpen      = st_numscalar("e(cpen)")
	O.ltol      = st_numscalar("e(ltol)")
	O.dlags     = st_numscalar("e(dlags)")
	O.st3cons   = st_numscalar("e(st3cons)")
	O.adaptive  = (st_global("e(mzproj)") == "adaptive")
	O.penalised = (st_global("e(mzproj)") != "ols")
	O.penval    = .
	O.penrule   = st_global("e(penrule)")
	if (O.penrule == "low")    O.penrule = "min"
	if (O.penrule == "tscv")   O.penrule = "min"
	if (O.penrule == "medium") O.penrule = "mid"
	if (O.penrule == "high")   O.penrule = "1se"

	D = ardldml_design(y, d, W, imask, iord, O.lags, O.dlags, wnames, ynm, dnm)
	R = ardldml_compute(D, O, J(0, 1, 0))

	N = rows(y)
	n = D.n
	out = J(N, 3, .)
	out[|N-n+1, 1 \ N, 1|] = R.dYres
	out[|N-n+1, 2 \ N, 3|] = R.Zres
	st_store(., (v1, v2, v3), touse, out)
}

end
