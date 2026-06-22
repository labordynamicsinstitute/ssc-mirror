*! _xtpqcce_csqr v1.0.0  20jun2026  Dr Merwan Roudane
*! CCEMG-CSQR engine for xtpqcce  (Zhang & Su 2026, JBES)
*! Convolution-smoothed quantile CCE mean-group estimator (eq 2.8-2.10),
*! Silverman/T^{-7/24} bandwidth (eq 4.1), two-step bias correction:
*!   - smoothing-bias removal over J bandwidths (eq 3.8, Lin-Li/Cheng)
*!   - split-panel jackknife for O(1/T) bias (eq 3.10, Dhaene-Jochmans)
*! Inference: Omega-hat (eq 3.11), CI (eq 3.12).

capture program drop _xtpqcce_csqr
program define _xtpqcce_csqr, rclass
	version 15.1
	syntax , DEPVAR(string) INDEPVARS(string) TAU(numlist) ///
		IVAR(string) TVAR(string) TOUSE(string) CSA(string) ///
		[ DET(string) C0(real 0.5) BW(real -1) Jbw(integer 11) ///
		  BC noCONStant noDOTs ]

	local k    : word count `indepvars'
	local ntau : word count `tau'

	* plain copies (avoid ts complications)
	tempvar yp
	qui gen double `yp' = `depvar' if `touse'
	local xp ""
	forvalues j = 1/`k' {
		local xj : word `j' of `indepvars'
		tempvar x`j'
		qui gen double `x`j'' = `xj' if `touse'
		local xp "`xp' `x`j''"
	}
	local zp ""
	local dcount : word count `det'
	forvalues j = 1/`dcount' {
		local dj : word `j' of `det'
		tempvar d`j'
		qui gen double `d`j'' = `dj' if `touse'
		local zp "`zp' `d`j''"
	}
	* csa already plain
	local zp "`zp' `csa'"
	local cons = cond("`constant'"=="", 1, 0)

	qui levelsof `ivar' if `touse', local(ids)
	local N : word count `ids'

	local bcflag = cond("`bc'"=="", 0, 1)

	* -----------------------------------------------------------------
	* tau-major storage
	* -----------------------------------------------------------------
	tempname Ball MG BCMG SE VV
	matrix `Ball' = J(`N', `ntau'*`k', .)
	matrix `MG'   = J(1, `ntau'*`k', .)
	matrix `BCMG' = J(1, `ntau'*`k', .)
	matrix `SE'   = J(1, `ntau'*`k', .)
	matrix `VV'   = J(`ntau'*`k', `ntau'*`k', 0)

	local bw_used .
	local goodmin = `N'
	local ti 0
	foreach q of local tau {
		local ++ti
		if "`dots'" == "" di as txt "  tau = " as res %4.2f `q' as txt ": fitting CSQR " _c
		tempname oB omg obc ose oV obw ong
		mata: xtpqcce_csqr_one("`touse'","`yp'","`xp'","`zp'","`ivar'","`tvar'", ///
			`q', `c0', `bw', `jbw', `bcflag', `cons', ///
			"`oB'","`omg'","`obc'","`ose'","`oV'","`obw'","`ong'")
		local thisbw = `obw'[1,1]
		local thisgood = `ong'[1,1]
		if `ti'==1 local bw_used = `thisbw'
		if `thisgood' < `goodmin' local goodmin = `thisgood'
		if "`dots'" == "" di as txt "(N_eff=" as res `thisgood' as txt ", h=" ///
			as res %6.4f `thisbw' as txt ")"

		* place into tau-major blocks
		forvalues j = 1/`k' {
			local c = (`ti'-1)*`k' + `j'
			matrix `MG'[1,`c']   = `omg'[1,`j']
			matrix `BCMG'[1,`c'] = `obc'[1,`j']
			matrix `SE'[1,`c']   = `ose'[1,`j']
			forvalues i = 1/`N' {
				matrix `Ball'[`i',`c'] = `oB'[`i',`j']
			}
			forvalues jj = 1/`k' {
				local c2 = (`ti'-1)*`k' + `jj'
				matrix `VV'[`c',`c2'] = `oV'[`j',`jj']
			}
		}
	}

	* column names
	local cn ""
	forvalues t = 1/`ntau' {
		forvalues j = 1/`k' {
			local cn "`cn' b`j'_`t'"
		}
	}
	matrix colnames `MG'   = `cn'
	matrix colnames `BCMG' = `cn'
	matrix colnames `SE'   = `cn'
	matrix colnames `VV'   = `cn'
	matrix rownames `VV'   = `cn'

	return scalar valid_panels = `goodmin'
	return scalar bw = `bw_used'
	return matrix b_i = `Ball'
	return matrix mg  = `MG'
	return matrix V   = `VV'
	return matrix SE  = `SE'
	if `bcflag' return matrix bc_mg = `BCMG'
end


* =====================================================================
* MATA: convolution-smoothed quantile CCEMG with two-step bias correction
* =====================================================================
version 15.1
mata:
mata set matastrict off

// ---- empirical quantile of a column vector (type-7-ish, simple)
real scalar xtpqcce_q(real colvector x, real scalar p)
{
    real colvector s
    real scalar n, idx
    n = rows(x)
    if (n < 1) return(.)
    s = sort(x, 1)
    idx = ceil(p*n)
    if (idx < 1) idx = 1
    if (idx > n) idx = n
    return(s[idx])
}

// ---- one-unit convolution-smoothed QR fit (Gaussian kernel)
real colvector xtpqcce_fit(real colvector y, real matrix W,
                           real scalar tau, real scalar h)
{
    real colvector b, u, s, kk, d
    real matrix H, XX, Reg
    real scalar it, p, rdg, sdn, mx
    p = cols(W)
    // invsym is robust to the (near-)collinear CSA block: it drops
    // redundant columns instead of returning exploding coefficients.
    XX = quadcross(W, W)
    b = invsym(XX) * quadcross(W, y)
    // small ridge (scaled to the data) keeps the smoothed-QR Hessian
    // well conditioned when few residuals fall inside the kernel window
    rdg = 1e-6 * trace(XX) / p
    Reg = rdg * I(p)
    it = 0
    d = J(p, 1, 1)
    do {
        u  = y - W*b
        s  = tau :- normal(-u/h)
        kk = normalden(u/h) :/ h
        H  = cross(W :* kk, W) + Reg
        d  = invsym(H) * quadcross(W, s)
        // step damping to prevent runaway divergence
        sdn = sqrt(sum(d:^2))
        if (sdn > 5) d = d :* (5/sdn)
        b  = b + d
        it = it + 1
        mx = max(abs(d))
    } while (mx > 1e-7 & it < 100)
    return(b)
}

// ---- mean-group beta at fixed bandwidth h over a row mask
// returns mgbeta (k x 1); writes per-unit beta into B (Nu x k) and the
// per-unit validity flag into vflag (Nu x 1)
real colvector xtpqcce_mg(real colvector y, real matrix W,
                          real colvector ps, real colvector pe,
                          real colvector mask, real scalar tau,
                          real scalar h, real scalar k,
                          real matrix B, real colvector vflag)
{
    real scalar nu, i, r0, r1, need, m, cnt, j
    real colvector gidx, sub, sumb, bi, yi
    real matrix Wi
    nu = rows(ps)
    m  = cols(W)
    need = m + 3
    B = J(nu, k, .)
    vflag = J(nu, 1, 0)
    sumb = J(k, 1, 0)
    cnt = 0
    for (i=1; i<=nu; i++) {
        r0 = ps[i]
        r1 = pe[i]
        sub = mask[|r0 \ r1|]
        gidx = selectindex(sub) :+ (r0 - 1)
        if (rows(gidx) < need) continue
        yi = y[gidx]
        Wi = W[gidx, .]
        bi = xtpqcce_fit(yi, Wi, tau, h)
        if (hasmissing(bi)) continue
        for (j=1; j<=k; j++) {
            B[i, j] = bi[j]
        }
        sumb = sumb + bi[|1 \ k|]
        vflag[i] = 1
        cnt = cnt + 1
    }
    if (cnt < 1) return(J(k, 1, .))
    return(sumb :/ cnt)
}

// ---- bandwidth (eq 4.1) using a two-pass residual scale on a mask
real scalar xtpqcce_bw(real colvector y, real matrix W,
                       real colvector ps, real colvector pe,
                       real colvector mask, real scalar tau,
                       real scalar c0, real scalar k)
{
    real scalar nu, i, r0, r1, m, need, Tbar, cnt, ntot
    real scalar s_ols, hA, scale_u, iqr, sdv, h0
    real colvector gidx, sub, res, allres, bi, ui, yi, bdummy, vflag
    real matrix Wi, B
    nu = rows(ps)
    m  = cols(W)
    need = m + 3
    // pooled OLS-within residual scale + Tbar
    allres = J(0, 1, .)
    Tbar = 0
    cnt = 0
    ntot = 0
    for (i=1; i<=nu; i++) {
        r0 = ps[i]
        r1 = pe[i]
        sub = mask[|r0 \ r1|]
        gidx = selectindex(sub) :+ (r0 - 1)
        if (rows(gidx) < need) continue
        yi = y[gidx]
        Wi = W[gidx, .]
        bi = invsym(quadcross(Wi, Wi)) * quadcross(Wi, yi)
        if (hasmissing(bi)) continue
        res = yi - Wi*bi
        allres = allres \ res
        Tbar = Tbar + rows(gidx)
        cnt = cnt + 1
    }
    if (cnt < 1) return(.)
    Tbar = Tbar / cnt
    sdv = sqrt(variance(allres))
    if (sdv <= 0 | sdv == .) sdv = 1
    hA = c0 * sdv * Tbar^(-7/24)
    if (hA <= 0 | hA == .) hA = 0.1
    // pass A: CSQR residuals at hA
    B = J(nu, k, .)
    vflag = J(nu, 1, 0)
    bdummy = xtpqcce_mg(y, W, ps, pe, mask, tau, hA, k, B, vflag)
    allres = J(0, 1, .)
    for (i=1; i<=nu; i++) {
        if (vflag[i] == 0) continue
        r0 = ps[i]
        r1 = pe[i]
        sub = mask[|r0 \ r1|]
        gidx = selectindex(sub) :+ (r0 - 1)
        yi = y[gidx]
        Wi = W[gidx, .]
        bi = xtpqcce_fit(yi, Wi, tau, hA)
        ui = yi - Wi*bi
        allres = allres \ ui
    }
    if (rows(allres) < 4) return(hA)
    sdv = sqrt(variance(allres))
    iqr = (xtpqcce_q(allres, 0.75) - xtpqcce_q(allres, 0.25)) / 1.34898
    scale_u = sdv
    if (iqr > 0 & iqr < scale_u) scale_u = iqr
    if (scale_u <= 0 | scale_u == .) scale_u = sdv
    h0 = c0 * scale_u * Tbar^(-7/24)
    if (h0 <= 0 | h0 == .) h0 = hA
    return(h0)
}

// ---- smoothing-bias-corrected MG beta over a mask (eq 3.8)
real colvector xtpqcce_sb(real colvector y, real matrix W,
                          real colvector ps, real colvector pe,
                          real colvector mask, real scalar tau,
                          real scalar c0, real scalar J, real scalar k,
                          real scalar h0in)
{
    real scalar h0, j, ssum2, ssum4, denom
    real colvector cc, gg, bsum, mgj, bdummy2, vfl
    real matrix Bd
    h0 = h0in
    if (h0 <= 0 | h0 == .) h0 = xtpqcce_bw(y, W, ps, pe, mask, tau, c0, k)
    cc = J(J, 1, 0)
    for (j=1; j<=J; j++) {
        cc[j] = 0.5 + 0.1*(j - 1)
    }
    ssum2 = sum(cc:^2)
    ssum4 = sum(cc:^4)
    denom = J*ssum4 - ssum2^2
    gg = (J(J,1,ssum4) - ssum2*(cc:^2)) :/ denom
    bsum = J(k, 1, 0)
    for (j=1; j<=J; j++) {
        Bd = J(rows(ps), k, .)
        vfl = J(rows(ps), 1, 0)
        mgj = xtpqcce_mg(y, W, ps, pe, mask, tau, cc[j]*h0, k, Bd, vfl)
        bsum = bsum + gg[j]*mgj
    }
    return(bsum)
}

// ---- driver for a single tau
void xtpqcce_csqr_one(string scalar touse, string scalar yv,
    string scalar xvars, string scalar zvars,
    string scalar idv, string scalar tvv,
    real scalar tau, real scalar c0, real scalar bwman,
    real scalar J, real scalar bc, real scalar cons,
    string scalar oB, string scalar omg, string scalar obc,
    string scalar ose, string scalar oV, string scalar obw,
    string scalar ong)
{
    real colvector y, idc, tc, ps, pe, uid, maskall, mask1, mask2
    real colvector mgb, bcb, vflag, bsb, bsb1, bsb2, seb, ut
    real matrix X, Z, W, B, Om
    real scalar n, k, nu, i, h0, cut, good, c
    real rowvector mgr, bcr, ser

    y = st_data(., yv, touse)
    X = st_data(., tokens(xvars), touse)
    Z = st_data(., tokens(zvars), touse)
    idc = st_data(., idv, touse)
    tc  = st_data(., tvv, touse)
    n = rows(y)
    k = cols(X)
    W = X, Z
    if (cons == 1) W = W, J(n, 1, 1)

    // panel boundaries (data is xtset-sorted by id then t)
    uid = uniqrows(idc)
    nu = rows(uid)
    ps = J(nu, 1, 0)
    pe = J(nu, 1, 0)
    real colvector tmpix
    for (i=1; i<=nu; i++) {
        tmpix = selectindex(idc :== uid[i])
        ps[i] = tmpix[1]
    }
    for (i=1; i<=nu-1; i++) {
        pe[i] = ps[i+1] - 1
    }
    pe[nu] = n

    maskall = J(n, 1, 1)

    // bandwidth on full sample
    if (bwman > 0) {
        h0 = bwman
    } else {
        h0 = xtpqcce_bw(y, W, ps, pe, maskall, tau, c0, k)
    }

    // full-sample MG and per-unit beta at h0
    B = J(nu, k, .)
    vflag = J(nu, 1, 0)
    mgb = xtpqcce_mg(y, W, ps, pe, maskall, tau, h0, k, B, vflag)
    good = sum(vflag)

    // bias correction
    if (bc == 1) {
        bsb = xtpqcce_sb(y, W, ps, pe, maskall, tau, c0, J, k, h0)
        if (hasmissing(bsb)) bsb = mgb
        // split-panel jackknife: halves of the time index (eq 3.10)
        ut = uniqrows(tc)
        cut = xtpqcce_q(ut, 0.5)
        mask1 = (tc :<= cut)
        mask2 = (tc :>  cut)
        bsb1 = xtpqcce_sb(y, W, ps, pe, mask1, tau, c0, J, k, .)
        bsb2 = xtpqcce_sb(y, W, ps, pe, mask2, tau, c0, J, k, .)
        if (hasmissing(bsb1) | hasmissing(bsb2)) {
            bcb = bsb
        } else {
            bcb = 2*bsb :- 0.5*(bsb1 + bsb2)
        }
    } else {
        bcb = mgb
    }

    // Omega-hat (eq 3.11): (1/N) sum (beta_i - bcb)(beta_i - bcb)'
    Om = J(k, k, 0)
    real scalar nv
    real colvector dvi
    nv = 0
    for (i=1; i<=nu; i++) {
        if (vflag[i] == 0) continue
        dvi = (B[i, .]') - bcb
        Om = Om + dvi*dvi'
        nv = nv + 1
    }
    if (nv >= 1) Om = Om :/ nv
    seb = J(k, 1, .)
    if (nv >= 1) {
        for (c=1; c<=k; c++) {
            seb[c] = sqrt(Om[c, c] / nv)
        }
    }

    // outputs
    mgr = mgb'
    bcr = bcb'
    ser = seb'
    st_matrix(oB, B)
    st_matrix(omg, mgr)
    st_matrix(obc, bcr)
    st_matrix(ose, ser)
    st_matrix(oV, Om :/ nv)
    st_matrix(obw, h0)
    st_matrix(ong, good)
}
end
