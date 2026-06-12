*! 1.0.0 Ariel Linden 10Jun2026

program define poissark, eclass
	version 14

	if replay() {
		if "`e(cmd)'" != "poissark" {
			di as err "last estimates not found"
			exit 301
		}
		syntax [, Level(cilevel) COEFLegend IRR]
		poissark_display, level(`level') `coeflegend' `irr'
		exit
	}

	local cmdline `"poissark `0'"'

	syntax varlist(min=1 numeric ts fv) [if] [in]	///
		, LAG(integer)								///
		[ OFFset(varname numeric)					///
		  EXPosure(varname numeric)					///
		  NOCONStant								///
		  TOLerance(real 1e-6)						///
		  ITERate(integer 250)						///
		  Level(cilevel)							///
		  COEFLegend								///
		  NOLog										///
		  IRR										///
		]

	// error checking
	if `lag' < 1 {
		di as err "lag() must be >= 1"
		exit 198
	}
	if `tolerance' <= 0 {
		di as err "tolerance() must be a positive number"
		exit 198
	}
	if `iterate' < 1 {
		di as err "iterate() must be a positive integer"
		exit 198
	}
	if "`offset'" != "" & "`exposure'" != "" {
		di as err "cannot specify both offset() and exposure()"
		exit 198
	}

	// store original names
	local exposure_orig "`exposure'"
	local offset_orig   "`offset'"

	marksample touse

	// create log(exposure) as tempvar
	if "`exposure_orig'" != "" {
		tempvar offset
		quietly generate double `offset' = log(`exposure_orig') if `touse'
		markout `touse' `offset'
	}
	if "`offset_orig'" != "" & "`exposure_orig'" == "" {
		markout `touse' `offset_orig'
	}

	// use _ts to get timevar/panelvar exactly as official Stata TS commands do
	_ts timevar panvar, panel
	local tsdelta = r(tdelta)

	// use tsreport to count gaps correctly
	quietly tsreport if `touse'
	local ngaps_pre = r(N_gaps)
	if `ngaps_pre' > 0 {
		di ""
		di as txt "Number of gaps in sample = " as res `ngaps_pre' ///
			as txt "   (gap count includes panel changes)"
		di as txt "note: computations for rho restarted at each gap."
	}

	tokenize `varlist'
	local yvar `1'
	macro shift
	local xvars_orig `*'

	// collinearity resolution via regress
	if "`xvars_orig'" == "" {
		if "`noconstant'" != "" {
			di as err "no regressors and noconstant specified: empty model"
			exit 198
		}
		local cnames_all ""
		local cnames     ""
		local xvars_keep ""
		local omitted    ""
	}
	else {
		quietly regress `yvar' `xvars_orig' if `touse', `noconstant'

		local allcnames : colfullnames e(b)

		foreach cn of local allcnames {
			if "`cn'" == "_cons" continue
			if strpos("`cn'", "b.") > 0 continue
			if substr("`cn'", 1, 2) == "o." {
				local bare = substr("`cn'", 3, .)
				di as txt "note: `bare' omitted because of collinearity."
				local omitted    `"`omitted' `cn'"'
				local cnames_all `"`cnames_all' `cn'"'
				continue
			}
			fvrevar `cn' if `touse'
			local tmpv `r(varlist)'
			local xvars_keep `"`xvars_keep' `tmpv'"'
			local cnames     `"`cnames' `cn'"'
			local cnames_all `"`cnames_all' `cn'"'
		}
	}

	local nocons = ("`noconstant'" != "")

	// pass the appropriate offset varname to Mata
	local offsetpass ""
	if "`exposure_orig'" != "" local offsetpass "`offset'"
	else if "`offset_orig'" != "" local offsetpass "`offset_orig'"

	// call Mata
	mata: poissark_main("`yvar'", "`xvars_keep'",        ///
	                    `lag', "`touse'",                 ///
	                    "`timevar'", "`panvar'",           ///
	                    `nocons', `tolerance', `iterate',  ///
	                    "`offsetpass'", `ngaps_pre')

	// collect Mata results — capture ALL r() before any Stata calls
	matrix b_post     = r(b)
	matrix V_post     = r(V)
	matrix rho_post   = r(rho)
	matrix serho_post = r(serho)
	matrix iter_hist  = r(iter_hist)
	local  ll_post    = r(ll)
	local  nobs_post  = r(nobs)
	local  iter_post  = r(iter)
	local  ngaps      = `ngaps_pre'
	local  niter      = r(niter)

	// iteration log
	if "`nolog'" == "" {
		di ""
		forvalues i = 1/`niter' {
			local itnum = iter_hist[`i', 1]
			di as txt "Iteration `itnum':  " _continue
			forvalues j = 1/`lag' {
				local rhoval = iter_hist[`i', 1+`j']
				if `lag' == 1 local rholbl "rho"
				else          local rholbl "rho`j'"
				if `j' < `lag' {
					di as txt "`rholbl' = " as res %7.4f `rhoval' ///
						as txt ",  " _continue
				}
				else {
					di as txt "`rholbl' = " as res %7.4f `rhoval'
				}
			}
		}
	}

	// expand b/V for omitted terms
	local cnames_full `"`cnames_all'"'
	if "`noconstant'" == "" local cnames_full `"`cnames_full' _cons"'

	if `"`omitted'"' != "" {
		local k_full : word count `cnames_full'
		matrix b_full = J(1, `k_full', 0)
		matrix V_full = J(`k_full', `k_full', 0)
		local col_f = 0
		local col_a = 0
		foreach cn of local cnames_full {
			local col_f = `col_f' + 1
			if substr("`cn'", 1, 2) != "o." {
				local col_a = `col_a' + 1
				matrix b_full[1, `col_f'] = b_post[1, `col_a']
				local col_f2 = 0
				local col_a2 = 0
				foreach cn2 of local cnames_full {
					local col_f2 = `col_f2' + 1
					if substr("`cn2'", 1, 2) != "o." {
						local col_a2 = `col_a2' + 1
						matrix V_full[`col_f', `col_f2'] = V_post[`col_a', `col_a2']
					}
				}
			}
		}
		matrix b_post = b_full
		matrix V_post = V_full
	}

	matrix colnames b_post = `cnames_full'
	matrix colnames V_post = `cnames_full'
	matrix rownames V_post = `cnames_full'

	// post — z statistics throughout
	ereturn post b_post V_post, depname(`yvar') obs(`nobs_post') esample(`touse')

	ereturn local cmd     "poissark"
	ereturn local predict "poissark_p"

	// rank and df
	local k_full_post = colsof(e(V))
	local rank_post   = 0
	forvalues j = 1/`k_full_post' {
		if el(e(V),`j',`j') != 0 local rank_post = `rank_post' + 1
	}
	if "`noconstant'" == "" local dfm_post = `rank_post' - 1
	else                    local dfm_post = `rank_post'
	local dfr_post = `nobs_post' - `rank_post'

	// Wald chi2
	tempname bmat Vmat
	matrix `bmat' = e(b)
	matrix `Vmat' = e(V)
	mata: poissark_wald_chi2("`bmat'", "`Vmat'", `nocons', "r(wald_chi2)")
	local chi2_stat = r(wald_chi2)
	local p_chi2    = chi2tail(`dfm_post', `chi2_stat')

	// deviance and Pearson GOF
	tempvar smpl xbhat mu_hat dev_t pear_t

	quietly generate byte   `smpl'  = e(sample)
	quietly _predict double `xbhat' if `smpl', xb

	if "`exposure_orig'" != "" {
		quietly replace `xbhat' = `xbhat' + log(`exposure_orig') if `smpl'
	}
	else if "`offset_orig'" != "" {
		quietly replace `xbhat' = `xbhat' + `offset_orig' if `smpl'
	}

	quietly generate double `mu_hat' = exp(`xbhat') if `smpl'

	quietly generate double `dev_t'  = ///
		2*(`yvar'*ln(cond(`yvar'>0, `yvar'/`mu_hat', 1)) - ///
		   (`yvar' - `mu_hat')) if `smpl'
	quietly generate double `pear_t' = ///
		(`yvar'-`mu_hat')^2/`mu_hat' if `smpl'
	quietly summarize `dev_t'  if `smpl', meanonly
	local deviance  = r(sum)
	quietly summarize `pear_t' if `smpl', meanonly
	local pearson_g = r(sum)

	// post scalars and macros
	ereturn scalar ll         = `ll_post'
	ereturn scalar chi2       = `chi2_stat'
	ereturn scalar p          = `p_chi2'
	ereturn scalar deviance   = `deviance'
	ereturn scalar pearson    = `pearson_g'
	ereturn scalar df_m       = `dfm_post'
	ereturn scalar N          = `nobs_post'
	ereturn scalar rank       = `rank_post'
	ereturn scalar iterations = `iter_post'
	ereturn scalar tolerance  = `tolerance'
	ereturn scalar ngaps      = `ngaps'
	ereturn scalar p_lag      = `lag'

	ereturn matrix rho        = rho_post
	ereturn matrix serho      = serho_post

	ereturn local  cmdline    `"`cmdline'"'
	ereturn local  title      "Poisson AR(`lag') regression"
	ereturn local  vcetype    "INAR-corrected"
	ereturn local  vce        "inar"
	ereturn local  noconstant "`noconstant'"
	ereturn local  panelvar   "`panelvar'"
	ereturn local  timevar    "`timevar'"
	ereturn local  offset_var  "`offset_orig'"
	ereturn local  exposure    "`exposure_orig'"

	if "`exposure_orig'" != "" {
		ereturn local offset_lbl  "ln(`exposure_orig')"
		ereturn local offset_type "exposure"
		ereturn local offset      "ln(`exposure_orig')"
	}
	else if "`offset_orig'" != "" {
		ereturn local offset_lbl  "`offset_orig'"
		ereturn local offset_type "offset"
		ereturn local offset      "`offset_orig'"
	}

	if "`irr'" != "" ereturn local eform_lbl "IRR"

	poissark_display, level(`level') `coeflegend' `irr'
end


// display program
program define poissark_display
	syntax [, Level(cilevel) COEFLegend IRR]

	local nobs  = e(N)
	local dfm   = e(df_m)
	local chi2  = e(chi2)
	local p_chi2 = e(p)
	local ll    = e(ll)
	local p_lag = e(p_lag)
	local crit  = invnormal(1 - (1-`level'/100)/2)

	// irr label
	local irr_lbl ""
	if "`irr'" != "" {
		if `dfm' == 0 local irr_lbl "Inc. rate"
		else          local irr_lbl "IRR"
	}
	// also honor stored eform_lbl from ereturn (set at estimation)
	local eform_stored "`e(eform_lbl)'"
	if "`irr_lbl'" == "" & "`eform_stored'" != "" local irr_lbl "`eform_stored'"

	di ""
	di as txt "Poisson AR(`p_lag') regression, INAR-corrected standard errors"
	di ""
	di as txt _col(49) "Number of obs"    _col(67) "= " as res %10.0f `nobs'
	di as txt _col(49) "Wald chi2(`dfm')" _col(67) "= " as res %10.2f `chi2'
	di as txt _col(49) "Prob > chi2"      _col(67) "= " as res %10.4f `p_chi2'
	di as txt _col(49) "Log likelihood"   _col(67) "= " as res %10.4f `ll'
	di ""

	// coefficient table
	if "`irr_lbl'" != "" {
		ereturn display, level(`level') plus `coeflegend' eform("`irr_lbl'")
	}
	else {
		ereturn display, level(`level') plus `coeflegend'
	}

	// rho rows
	local i = 1
	while `i' <= `p_lag' {
		local rho_est = el(e(rho),  1, `i')
		local rho_se  = el(e(serho),1, `i')
		local rho_lo  = `rho_est' - `crit'*`rho_se'
		local rho_hi  = `rho_est' + `crit'*`rho_se'
		if `p_lag' == 1 local rholabel "rho"
		else            local rholabel "rho`i'"
		if "`coeflegend'" == "" {
			di as txt %12s "`rholabel'" " {c |}" ///
				_col(17) as res %9.0g `rho_est' ///
				_col(28) %9.0g `rho_se'         ///
				_col(58) %9.0g `rho_lo'         ///
				_col(70) %9.0g `rho_hi'
		}
		else {
			di as txt %12s "`rholabel'" " {c |}" ///
				_col(17) as res %9.0g `rho_est'
		}
		local i = `i' + 1
	}

	di as txt "{hline 13}{c BT}{hline 64}"
	di ""
end


// Mata functions
version 14.0
mata:

// Wald chi2 (excludes constant)
void function poissark_wald_chi2(string scalar bname,
                                  string scalar Vname,
                                  real   scalar nocons,
                                  string scalar rscalar)
{
	real matrix b, V
	real scalar k, chi2

	b = st_matrix(bname)
	V = st_matrix(Vname)
	k = cols(b)

	if (!nocons) {
		if (k <= 1) {
			st_numscalar(rscalar, 0)
			return
		}
		b = b[|1,1 \ 1,k-1|]
		V = V[|1,1 \ k-1,k-1|]
	}

	if (cols(b) == 0) {
		st_numscalar(rscalar, 0)
		return
	}

	chi2 = (b * invsym(V) * b')[1,1]
	st_numscalar(rscalar, chi2)
}


// build segment boundaries from panel ID and time variable.
real matrix function poissark_getsegs(real colvector panid,
                                       real colvector tvec)
{
	real scalar    n, i, seg_start, is_new_seg, delta
	real scalar    nd, di, best_count, cnt
	real matrix    segs
	real colvector diffs, udiffs

	n         = rows(panid)
	seg_start = 1
	segs      = J(0, 2, .)

	// compute modal time step as expected delta

	diffs = J(0, 1, .)
	for (i=2; i<=n; i++) {
		if (panid[i] == panid[i-1]) {
			diffs = (diffs \ (tvec[i] - tvec[i-1]))
		}
	}
	if (rows(diffs) == 0) {
		delta = 1
	}
	else {
		udiffs     = uniqrows(diffs)
		nd         = rows(udiffs)
		best_count = 0
		delta      = 1
		for (di=1; di<=nd; di++) {
			if (udiffs[di] <= 0) continue
			cnt = sum(diffs :== udiffs[di])
			if (cnt > best_count) {
				best_count = cnt
				delta      = udiffs[di]
			}
		}
		if (delta <= 0) delta = 1
	}

	for (i=2; i<=n; i++) {
		is_new_seg = 0
		if (panid[i] != panid[i-1]) is_new_seg = 1
		else if (abs(tvec[i] - tvec[i-1] - delta) > delta*0.5) is_new_seg = 1
		if (is_new_seg) {
			segs      = (segs \ (seg_start, i-1))
			seg_start = i
		}
	}
	segs = (segs \ (seg_start, n))
	return(segs)
}


// project rho onto feasible region:
//   rho_j >= 0 for all j,  sum(rho) < 1
// ----------------------------------------------------------------

real colvector function poissark_project(real colvector alpha)
{
	real scalar s

	// non-negativity constraint
	alpha = rowmax((alpha, J(rows(alpha),1,0)))

	// sum < 1 constraint: rescale if violated
	s = sum(alpha)
	if (s >= 1) alpha = alpha * (0.99 / s)

	return(alpha)
}


// coordinate descent CLS optimizer
real colvector function poissark_cls_minimize(real colvector y,
                                               real colvector mu,
                                               real matrix    allsegs,
                                               real scalar    p,
                                               real scalar    tol)
{
	real colvector alpha, alpha_prev
	real scalar    g, nsegs, r1, r2, ns, j, kk, t_loc
	real scalar    num, denom, alpha_j_new
	real scalar    yt, mut, ytj, Ct_j, zjt, sumalpha
	real colvector y_seg, mu_seg
	real scalar    inner_iter, max_inner

	// initial values: 0.3/p per spec
	alpha     = J(p, 1, 0.3/p)
	max_inner = 500
	nsegs     = rows(allsegs)

	for (inner_iter=1; inner_iter<=max_inner; inner_iter++) {
		alpha_prev = alpha

		for (j=1; j<=p; j++) {
			num   = 0
			denom = 0

			for (g=1; g<=nsegs; g++) {
				r1 = allsegs[g,1]
				r2 = allsegs[g,2]
				ns = r2 - r1 + 1
				if (ns <= p) continue

				y_seg  = y[|r1 \ r2|]
				mu_seg = mu[|r1 \ r2|]

				for (t_loc=p+1; t_loc<=ns; t_loc++) {
					yt  = y_seg[t_loc]
					mut = mu_seg[t_loc]
					if (mut <= 0) continue

					ytj = y_seg[t_loc - j]

					// sumalpha without the j-th term
					sumalpha = 0
					for (kk=1; kk<=p; kk++) {
						if (kk != j) sumalpha = sumalpha + alpha[kk]
					}

					// C^{-j}_t = mu_t*(1 - sumalpha_excl_j) + sum_{k!=j} alpha_k * y_{t-k}
					// Note: the (1 - sum_all + alpha_j) form from spec simplifies to this
					Ct_j = mut * (1 - sumalpha)
					for (kk=1; kk<=p; kk++) {
						if (kk != j) Ct_j = Ct_j + alpha[kk] * y_seg[t_loc - kk]
					}

					zjt   = (ytj - mut) / mut
					num   = num   + zjt * (yt - Ct_j) / mut
					denom = denom + zjt * zjt
				}
			}

			if (denom == 0 | denom == .) alpha_j_new = 0
			else                          alpha_j_new = num / denom

			// non-negativity per iteration
			alpha[j] = (alpha_j_new > 0 ? alpha_j_new : 0)
		}

		// project onto feasible region after full coordinate sweep
		alpha = poissark_project(alpha)

		if (max(abs(alpha - alpha_prev)) < tol) break
	}

	return(alpha)
}


// CLS sandwich standard errors for rho
real colvector function poissark_cls_se(real colvector y,
                                         real colvector mu,
                                         real colvector alpha,
                                         real matrix    allsegs,
                                         real scalar    p)
{
	real matrix    Z, ZtZ, meat, cov_alpha
	real colvector e_vec, y_seg, mu_seg
	real scalar    g, nsegs, r1, r2, ns, t_loc, j, kk
	real scalar    yt, mut, e_t, sumalpha
	real rowvector z_row

	nsegs  = rows(allsegs)
	Z      = J(0, p, .)
	e_vec  = J(0, 1, .)
	sumalpha = sum(alpha)

	for (g=1; g<=nsegs; g++) {
		r1 = allsegs[g,1]
		r2 = allsegs[g,2]
		ns = r2 - r1 + 1
		if (ns <= p) continue

		y_seg  = y[|r1 \ r2|]
		mu_seg = mu[|r1 \ r2|]

		for (t_loc=p+1; t_loc<=ns; t_loc++) {
			yt  = y_seg[t_loc]
			mut = mu_seg[t_loc]
			if (mut <= 0) continue

			// normalized CLS residual
			e_t = yt
			for (kk=1; kk<=p; kk++) {
				e_t = e_t - alpha[kk] * y_seg[t_loc - kk]
			}
			e_t = e_t - mut * (1 - sumalpha)
			e_t = e_t / mut

			// z row: z_{jt} = (y_{t-j} - mu_t) / mu_t for j=1..p
			z_row = J(1, p, .)
			for (j=1; j<=p; j++) {
				z_row[1,j] = (y_seg[t_loc - j] - mut) / mut
			}

			Z     = (Z     \ z_row)
			e_vec = (e_vec \ e_t)
		}
	}

	if (rows(Z) == 0) return(J(p, 1, .))

	ZtZ = Z'*Z
	if (det(ZtZ) == 0) return(J(p, 1, .))

	meat      = Z' * diag(e_vec:^2) * Z
	cov_alpha = invsym(ZtZ) * meat * invsym(ZtZ)

	return(sqrt(diagonal(cov_alpha)))
}


// INAR-corrected sandwich VCE for beta
real matrix function poissark_inar_vcov(real colvector y,
                                         real colvector mu,
                                         real matrix    X,
                                         real colvector alpha,
                                         real matrix    allsegs,
                                         real scalar    p)
{
	real matrix    A, B, scores, cross, sc_seg, Ainv, V
	real scalar    g, nsegs, r1, r2, ns, lag, t_loc, ncols
	real colvector s_t, s_tk

	nsegs = rows(allsegs)
	ncols = cols(X)

	// A = X' diag(mu) X
	A = X' * diag(mu) * X

	// score matrix: row t = (y_t - mu_t) * X[t,.]
	scores = diag(y - mu) * X

	// B: start with HC0 outer product sum
	B = scores' * scores

	// add INAR cross-lag corrections
	for (lag=1; lag<=p; lag++) {
		cross = J(ncols, ncols, 0)

		for (g=1; g<=nsegs; g++) {
			r1 = allsegs[g,1]
			r2 = allsegs[g,2]
			ns = r2 - r1 + 1
			if (ns <= lag) continue

			sc_seg = scores[|r1,1 \ r2,ncols|]

			for (t_loc=lag+1; t_loc<=ns; t_loc++) {
				s_t  = sc_seg[t_loc,  .]'
				s_tk = sc_seg[t_loc-lag,.]'
				cross = cross + s_t*s_tk' + s_tk*s_t'
			}
		}

		B = B + alpha[lag] * cross
	}

	Ainv = invsym(A)
	V    = Ainv * B * Ainv

	return(V)
}


// Poisson log likelihood
real scalar function poissark_ll(real colvector y, real colvector mu)
{
	// guard against log(0): mu should already be clamped
	real colvector ll_vec
	ll_vec = y :* ln(rowmax((mu, J(rows(mu),1,1e-300)))) - mu - lnfactorial(y)
	return(sum(ll_vec))
}


// main estimation function
void function poissark_main(string scalar yvar,
                             string scalar xvars_expanded,
                             real   scalar p,
                             string scalar tousename,
                             string scalar timevar,
                             string scalar panelvar,
                             real   scalar nocons,
                             real   scalar tol,
                             real   scalar maxiter,
                             string scalar offsetvar,
                             real   scalar ngaps_in)
{
	real matrix      X, allsegs, data, iter_hist, b_tmp, b_row, V_inar
	real colvector   y, off, mu, eta, alpha, alpha_old, b, serho
	real colvector   panid, tvec
	real scalar      nobs, ncols, iter, ngaps, ll, has_x, has_off, i
	string matrix    allvars
	string colvector rhonames, cnames_raw
	string scalar    stata_cmd, nocons_opt

	has_x   = (xvars_expanded != "")
	has_off = (offsetvar != "")

	// load data from Stata
	if (panelvar != "") {
		if (has_x & has_off) allvars = (tousename, panelvar, timevar, yvar, tokens(xvars_expanded), offsetvar)
		else if (has_x)      allvars = (tousename, panelvar, timevar, yvar, tokens(xvars_expanded))
		else if (has_off)    allvars = (tousename, panelvar, timevar, yvar, offsetvar)
		else                 allvars = (tousename, panelvar, timevar, yvar)
	}
	else {
		if (has_x & has_off) allvars = (tousename, timevar, yvar, tokens(xvars_expanded), offsetvar)
		else if (has_x)      allvars = (tousename, timevar, yvar, tokens(xvars_expanded))
		else if (has_off)    allvars = (tousename, timevar, yvar, offsetvar)
		else                 allvars = (tousename, timevar, yvar)
	}

	data = st_data(., allvars)
	data = data[selectindex(data[.,1] :== 1), .]

	if (panelvar != "") {
		data  = data[order(data[|1,1 \ rows(data),3|], (2,3)), .]
		panid = data[., 2]
		tvec  = data[., 3]
		y     = data[., 4]
		// layout: touse(1) panelvar(2) timevar(3) yvar(4) [xvars...] [offset]
		if (has_x & has_off) {
			X   = data[|1,5 \ rows(data), cols(data)-1|]
			off = data[., cols(data)]
		}
		else if (has_x) {
			X   = data[|1,5 \ rows(data), cols(data)|]
			off = J(rows(data), 1, 0)
		}
		else if (has_off) {
			X   = J(rows(data), 0, .)
			off = data[., cols(data)]
		}
		else {
			X   = J(rows(data), 0, .)
			off = J(rows(data), 1, 0)
		}
	}
	else {
		data  = data[order(data[.,2], 1), .]
		panid = J(rows(data), 1, 1)
		tvec  = data[., 2]
		y     = data[., 3]
		// layout: touse(1) timevar(2) yvar(3) [xvars...] [offset]
		if (has_x & has_off) {
			X   = data[|1,4 \ rows(data), cols(data)-1|]
			off = data[., cols(data)]
		}
		else if (has_x) {
			X   = data[|1,4 \ rows(data), cols(data)|]
			off = J(rows(data), 1, 0)
		}
		else if (has_off) {
			X   = J(rows(data), 0, .)
			off = data[., cols(data)]
		}
		else {
			X   = J(rows(data), 0, .)
			off = J(rows(data), 1, 0)
		}
	}

	if (nocons == 0) X = (X, J(rows(X), 1, 1))

	nobs  = rows(y)
	ncols = cols(X)

	// segments — ngaps already counted by tsreport in Stata
	ngaps   = ngaps_in
	allsegs = poissark_getsegs(panid, tvec)

	// build the Stata poisson call string
	nocons_opt = (nocons ? " noconstant" : "")

	if (has_off) {
		if (nocons) {
			stata_cmd = "quietly poisson " + yvar + " " + xvars_expanded +
			            " if " + tousename + "==1" +
			            " , offset(" + offsetvar + ") noconstant"
		}
		else {
			stata_cmd = "quietly poisson " + yvar + " " + xvars_expanded +
			            " if " + tousename + "==1" +
			            " , offset(" + offsetvar + ")"
		}
	}
	else {
		if (nocons) {
			stata_cmd = "quietly poisson " + yvar + " " + xvars_expanded +
			            " if " + tousename + "==1" +
			            " , noconstant"
		}
		else {
			// Per spec: NO trailing comma when there are no options
			stata_cmd = "quietly poisson " + yvar + " " + xvars_expanded +
			            " if " + tousename + "==1"
		}
	}

	// Step 1: initial Poisson MLE (rho = 0)
	stata(stata_cmd)

	// capture e(b) immediately after initial Poisson call
	b_tmp = st_matrix("e(b)")
	b     = b_tmp'

	// initial mu
	eta = X*b + off
	mu  = exp(eta)
	mu  = rowmax((mu, J(nobs, 1, 1e-10)))

	// initial alpha
	alpha = J(p, 1, 0.3/p)

	// iterative two-step loop
	iter      = 0
	iter_hist = (0, alpha')     // iteration 0: all p rho values

	while (1) {
		iter      = iter + 1
		alpha_old = alpha

		// CLS step: update alpha given current mu
		alpha = poissark_cls_minimize(y, mu, allsegs, p, tol)

		// log all p rho values
		iter_hist = (iter_hist \ (iter, alpha'))

		// Poisson step: refit Poisson to update beta and mu
		stata(stata_cmd)
		b_tmp = st_matrix("e(b)")
		b     = b_tmp'

		eta = X*b + off
		mu  = exp(eta)
		mu  = rowmax((mu, J(nobs, 1, 1e-10)))

		// convergence
		if (max(abs(alpha - alpha_old)) < tol) break
		if (iter >= maxiter) break
	}

	// final quantities
	ll = poissark_ll(y, mu)

	// INAR-corrected VCE for beta
	V_inar = poissark_inar_vcov(y, mu, X, alpha, allsegs, p)

	// CLS standard errors for alpha
	serho = poissark_cls_se(y, mu, alpha, allsegs, p)

	// b as 1 x k row vector for r(b)
	b_row = b'

	// Return all results in r()
	st_matrix("r(b)",         b_row)
	st_matrix("r(V)",         V_inar)
	st_matrix("r(rho)",       alpha')
	st_matrix("r(serho)",     serho')
	st_matrix("r(iter_hist)", iter_hist)
	st_numscalar("r(ll)",    ll)
	st_numscalar("r(nobs)",  nobs)
	st_numscalar("r(iter)",  iter)
	st_numscalar("r(ngaps)", ngaps)
	st_numscalar("r(niter)", rows(iter_hist))

	rhonames = J(p, 1, "")
	for (i=1; i<=p; i++) rhonames[i,1] = "rho" + strofreal(i)
	st_matrixcolstripe("r(rho)",   (J(p,1,""), rhonames))
	st_matrixcolstripe("r(serho)", (J(p,1,""), rhonames))
}

end
