*! 1.2.0 Ariel Linden 23Apr2026	// fixed display with multiple panels
*! 1.1.0 Ariel Linden 25Mar2026	// added nolog option
*! 1.0.0 Ariel Linden 09Mar2026

program define praisk, eclass
	version 14

	if replay() {
		if "`e(cmd)'" != "praisk" {
			di as err "last estimates not found"
			exit(301)
		}
		syntax [, Level(cilevel) COEFLegend]
		praisk_display, level(`level') `coeflegend'
		exit
	}

	local cmdline `"praisk `0'"'

	syntax varlist(min=1 numeric ts fv) [if] [in]	///
		, LAG(integer)								///
		[  Level(cilevel)							///
		   NOCONStant								///
		   Robust									///
		   TOLerance(real 1e-6)						///
		   ITERate(integer 250)						///
		   vce(string)								///
		   COEFLegend								///
		   NOLog									///
		]

	if `lag' < 1 {
		di as err "lag() must be >= 1"
		exit(198)
	}
	if `tolerance' <= 0 {
		di as err "tolerance() must be a positive number"
		exit(198)
	}
	if `iterate' < 1 {
		di as err "iterate() must be a positive integer"
		exit(198)
	}

	if "`robust'" != "" & "`vce'" != "" {
		di as err "cannot specify both robust and vce()"
		exit(198)
	}
	if "`robust'" != "" local vce "robust"

	local vce_type   ""
	local clustervar ""
	if "`vce'" != "" {
		tokenize `vce'
		local vce_type = lower("`1'")
		if "`vce_type'" == "cluster" {
			if "`2'" == "" {
				di as err "vce(cluster) requires a variable name"
				exit(198)
			}
			local clustervar "`2'"
			confirm variable `clustervar'
		}
		else if "`vce_type'" != "robust" {
			di as err "vce() must be robust or cluster varname"
			exit(198)
		}
	}

	marksample touse

	quietly tsset
	local timevar  "`r(timevar)'"
	local panelvar "`r(panelvar)'"

	tokenize `varlist'
	local yvar `1'
	macro shift
	local xvars_orig `*'

	// intercept-only model: skip regress-based collinearity resolution
	if "`xvars_orig'" == "" {
		if "`noconstant'" != "" {
			di as err "no regressors and noconstant specified: empty model"
			exit(198)
		}
		local cnames_all ""
		local cnames     ""
		local xvars_keep ""
		local omitted    ""
	}
	else {
		// run regress quietly and resolve all collinearity, fv base, etc.
		quietly regress `yvar' `xvars_orig' if `touse', `noconstant'

		// read column names from regress e(b) -- these are the ground truth
		local allcnames : colfullnames e(b)

		foreach cn of local allcnames {
			// skip _cons -- we add it ourselves
			if "`cn'" == "_cons" continue
			// skip base fv levels (prefixed with "b." or contain "#b.")
			if strpos("`cn'", "b.") > 0 continue

			// omitted collinear terms (prefixed with "o.")
			if substr("`cn'", 1, 2) == "o." {
				local bare = substr("`cn'", 3, .)
				di as txt "note: `bare' omitted because of collinearity."
				local omitted `"`omitted' `cn'"'
				local cnames_all `"`cnames_all' `cn'"'
				continue
			}

			// grab the non-omitted non-base terms
			fvrevar `cn' if `touse'
			local tmpv `r(varlist)'
			local xvars_keep `"`xvars_keep' `tmpv'"'
			local cnames     `"`cnames' `cn'"'
			local cnames_all `"`cnames_all' `cn'"'
		}
	}

	local nocons = ("`noconstant'" != "")

	mata: praisk_main("`yvar'", "`xvars_keep'",        ///
	                  `lag', "`touse'",                 ///
	                  "`timevar'", "`panelvar'",         ///
	                  `nocons', `tolerance', `iterate',  ///
	                  "`vce_type'", "`clustervar'")

	matrix b_post     = r(b)
	matrix V_post     = r(V)
	matrix rho_post   = r(rho)
	matrix serho_post = r(serho)
	matrix iter_hist  = r(iter_hist)
	local  ll_post        = r(ll)
	local  nobs_post      = r(nobs)
	local  k_post         = r(k)
	local  iter_post      = r(iter)
	local  ss_res         = r(ss_res)
	local  ss_tot         = r(ss_tot)
	local  ngaps          = r(ngaps)
	local  nonstationary  = r(nonstationary)
	if "`vce_type'" == "cluster" local nclust = r(nclust)

	// display gaps message before iteration log — matches prais behaviour
	if `ngaps' > 0 {
		di as txt _newline "Number of gaps in sample = " as res `ngaps' ///
			as txt "   (gap count includes panel changes)"
		di as txt "note: computations for rho restarted at each gap."
	}

	// display iteration history prais-like
	if "`nolog'" == "" {
		di ""
		local niter = rowsof(iter_hist)
		forvalues i = 1/`niter' {
			local itnum = iter_hist[`i', 1]
			local itval = iter_hist[`i', 2]
			if `lag' == 1 {
				di as txt "Iteration `itnum':  rho = " as res %7.4f `itval'		
			}
			else {
				di as txt "Iteration `itnum':  max|eigenvalue| = " as res %7.4f `itval'				
			}
		}
	}

	if `nonstationary' {
		di as txt "warning: lag(`lag') estimates are non-stationary" ///
			" (max|eigenvalue| >= 1)"
	}

	// apply display names like -prais-
	local cnames_full `"`cnames_all'"'
	if "`noconstant'" == "" local cnames_full `"`cnames_full' _cons"'

	// expand b_post and V_post to include zero rows/cols for omitted terms
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

	ereturn post b_post V_post, depname(`yvar') obs(`nobs_post') esample(`touse')

	// rank = number of non-zero diagonal elements in the posted V, including omitted-variable zero rows!
	local k_full_post = colsof(e(V))
	local rank_post = 0
	forvalues j = 1/`k_full_post' {
		if el(e(V),`j',`j') != 0 local rank_post = `rank_post' + 1
	}

	if "`noconstant'" == "" local dfm_post = `rank_post' - 1
	else                    local dfm_post = `rank_post'
	local dfr_post = `nobs_post' - `rank_post'
	local ss_mod   = `ss_tot' - `ss_res'
	local r2       = `ss_mod' / `ss_tot'
	local r2_adj   = 1 - (1-`r2') * (`nobs_post'-1) / `dfr_post'
	local rmse     = sqrt(`ss_res' / `dfr_post')

	if "`vce_type'" == "" | "`vce_type'" == "ols" {
		local f_stat = (`ss_mod' / `dfm_post') / (`ss_res' / `dfr_post')
		ereturn scalar F = `f_stat'
	}

	ereturn scalar ll         = `ll_post'
	ereturn scalar N          = `nobs_post'
	ereturn scalar rank       = `rank_post'
	ereturn scalar df_m       = `dfm_post'
	ereturn scalar df_r       = `dfr_post'
	ereturn scalar r2         = `r2'
	ereturn scalar r2_a       = `r2_adj'
	ereturn scalar rmse       = `rmse'
	ereturn scalar mss        = `ss_mod'
	ereturn scalar rss        = `ss_res'
	ereturn scalar level      = `level'
	ereturn scalar iterations = `iter_post'
	ereturn scalar tolerance  = `tolerance'
	ereturn scalar ngaps      = `ngaps'
	if "`vce_type'" == "cluster" ereturn scalar N_clust = `nclust'

	ereturn scalar p_lag      = `lag'
	ereturn matrix rho        = rho_post
	ereturn matrix serho      = serho_post
	ereturn local  cmd        "praisk"
	ereturn local  cmdline    `"`cmdline'"'
	ereturn local  predict    "praisk_p"
	ereturn local  title      "Prais-Winsten AR(`lag') Regression"
	ereturn local  noconstant "`noconstant'"
	ereturn local  panelvar   "`panelvar'"
	ereturn local  timevar    "`timevar'"

	if "`vce_type'" == "robust" {
		ereturn local vce     "robust"
		ereturn local vcetype "Semirobust"
	}
	else if "`vce_type'" == "cluster" {
		ereturn local vce      "cluster"
		ereturn local vcetype  "Semirobust"
		ereturn local clustvar "`clustervar'"
	}
	else {
		ereturn local vce     "ols"
		ereturn local vcetype ""
	}

	// autocorrelations of residuals at lags 1..p
	tempvar smpl xbhat ols_r ue_r
	quietly generate byte `smpl' = e(sample)
	quietly _predict double `xbhat' if `smpl', xb
	quietly generate double `ols_r' = `yvar' - `xbhat' if `smpl'
	quietly praisk_p `ue_r' if `smpl', ue

	forvalues k = 1/`lag' {
		quietly correlate `ols_r' L`k'.`ols_r' if `smpl'
		ereturn scalar ac_ols`k' = r(rho)
		quietly correlate `ue_r'  L`k'.`ue_r'  if `smpl'
		ereturn scalar ac_ue`k'  = r(rho)
	}

	praisk_display, level(`level') `coeflegend'
end


// display program
program define praisk_display
	syntax [, Level(cilevel) COEFLegend]

	local nobs     = e(N)
	local dfm      = e(df_m)
	local dfr      = e(df_r)
	local r2       = e(r2)
	local r2_adj   = e(r2_a)
	local rmse     = e(rmse)
	local ss_mod   = e(mss)
	local ss_res   = e(rss)
	local ss_tot   = `ss_mod' + `ss_res'
	local ms_mod   = `ss_mod' / `dfm'
	local ms_res   = `ss_res' / `dfr'
	local vce_type = e(vce)
	local clusvar  = e(clustvar)
	local nclust   = e(N_clust)
	local p_lag    = colsof(e(rho))
	local ngaps    = e(ngaps)
	local nocons   = ("`e(noconstant)'" != "")

	local crit = invnormal(1 - (1-`level'/100)/2)

	di ""
	di as txt "Prais{c 150}Winsten AR(`p_lag') regression with iterated estimates"
	di ""

	if "`vce_type'" == "ols" {
		local f_stat = e(F)
		local p_f    = Ftail(`dfm', `dfr', `f_stat')
		di as txt %12s "Source"  " {c |}" ///
			_col(22) "SS" _col(35) "df" _col(44) "MS" ///
			_col(52) "Number of obs"   _col(67) "= " as res %10.0f `nobs'
		di as txt "{hline 13}{c +}{hline 34}" ///
			_col(52) "F(`dfm',`dfr')"  _col(67) "= " as res %10.2f `f_stat'
		di as txt %12s "Model" " {c |}"  ///
			_col(17) as res %10.0g `ss_mod'  ///
			_col(27) %10.0fc `dfm'           ///
			_col(39) %10.0g `ms_mod'         ///
			_col(52) as txt "Prob > F"   _col(67) "= " as res %10.4f `p_f'
		di as txt %12s "Residual" " {c |}" ///
			_col(17) as res %10.0g `ss_res'  ///
			_col(27) %10.0fc `dfr'           ///
			_col(39) %10.0g `ms_res'         ///
			_col(52) as txt "R-squared"   _col(67) "= " as res %10.4f `r2'
		di as txt "{hline 13}{c +}{hline 34}" ///
			_col(52) "Adj R-squared"      _col(67) "= " as res %10.4f `r2_adj'
		di as txt %12s "Total" " {c |}"          ///
			_col(17) as res %10.0g `ss_tot'      ///
			_col(27) %10.0fc (`nobs'-1)          ///
			_col(39) %10.0g (`ss_tot'/(`nobs'-1)) ///
			_col(52) as txt "Root MSE"    _col(67) "= " as res %10.4f `rmse'
		di ""
		ereturn display, level(`level') plus `coeflegend'
	}
	else {
		tempname bmat Vmat
		matrix `bmat' = e(b)
		matrix `Vmat' = e(V)
		mata: praisk_wald_f("`bmat'", "`Vmat'", `dfm', `nocons', "r(wald_F)")
		local f_stat = r(wald_F)
		local p_f    = Ftail(`dfm', `dfr', `f_stat')
		di as txt "Linear regression" ///
			_col(49) "Number of obs"    _col(67) "= " as res %10.0f `nobs'
		di as txt _col(49) "F(`dfm',`dfr')"    _col(67) "= " as res %10.2f `f_stat'
		di as txt _col(49) "Prob > F"          _col(67) "= " as res %10.4f `p_f'
		di as txt _col(49) "R-squared"         _col(67) "= " as res %10.4f `r2'
		di as txt _col(49) "Root MSE"          _col(67) "= " as res %10.4f `rmse'
		di ""
		ereturn display, level(`level') plus `coeflegend'
	}

	// lag parameters: always shown regardless of coeflegend
	local i = 1
	while `i' <= `p_lag' {
		local rho_est = el(e(rho),1,`i')
		local rho_se  = el(e(serho),1,`i')
		local rho_lo  = `rho_est' - `crit'*`rho_se'
		local rho_hi  = `rho_est' + `crit'*`rho_se'
		if `p_lag' == 1 local rholabel "rho"
		else            local rholabel "rho`i'"
		if "`coeflegend'" == "" {
			di as txt %12s "`rholabel'" " {c |}" ///
				_col(17) as res %9.0g `rho_est'  ///
				_col(28) %9.0g `rho_se'          ///
				_col(58) %9.0g `rho_lo'          ///
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

	// autocorrelations of residuals: shown unless coeflegend active
	if "`coeflegend'" == "" {
		local col0 = 20          // label column width
		local colw = 10          // column width per lag

		di as txt "Autocorrelations of residuals:"
		di ""

		// header row
		di as txt _col(`col0') _continue
		forvalues k = 1/`p_lag' {
			local colpos = `col0' + (`k'-1)*`colw'
			di as txt _col(`colpos') %9s "lag `k'" _continue
		}
		di ""

		// untransformed row
		di as txt "  Untransformed:" _continue
		forvalues k = 1/`p_lag' {
			local colpos = `col0' + (`k'-1)*`colw'
			di as txt _col(`colpos') as res %9.4f e(ac_ols`k') _continue
		}
		di ""

		// transformed row
		di as txt "  Transformed:  " _continue
		forvalues k = 1/`p_lag' {
			local colpos = `col0' + (`k'-1)*`colw'
			di as txt _col(`colpos') as res %9.4f e(ac_ue`k') _continue
		}
		di ""
	}

	di ""
end


version 14.0
mata:

real rowvector function praisk_ljungbox(real matrix  resid,
                                         real matrix  allsegs,
                                         real scalar  m)
{
	real scalar    g, nsegs, r1, r2, ns, k, i
	real scalar    c0, ck, Q, c0_sum, n_tot, emean, ei, eim
	real colvector eg, ec, ck_vec, n_vec

	resid  = colshape(resid, 1)
	nsegs  = rows(allsegs)
	ck_vec = J(m, 1, 0)
	n_vec  = J(m, 1, 0)
	c0_sum = 0
	n_tot  = 0

	for (g=1; g<=nsegs; g++) {
		r1 = allsegs[g,1]
		r2 = allsegs[g,2]
		if (r2 > rows(resid)) r2 = rows(resid)
		if (r1 > r2) continue
		eg = resid[|r1 \ r2|]
		eg = colshape(select(eg, !missing(eg)), 1)
		ns = rows(eg)
		if (ns < m + 1) continue

		emean = mean(eg)[1,1]
		ec    = eg :- emean

		c0_sum = c0_sum + colsum(ec:^2)[1,1]
		n_tot  = n_tot + ns

		for (k=1; k<=m; k++) {
			ck = 0
			for (i=k+1; i<=ns; i++) {
				ei  = ec[i,1]
				eim = ec[i-k,1]
				ck  = ck + ei * eim
			}
			ck_vec[k] = ck_vec[k] + ck
			n_vec[k]  = n_vec[k]  + ns
		}
	}

	if (n_tot < 2 | c0_sum == 0) return((., .))

	c0 = c0_sum / n_tot
	Q  = 0
	for (k=1; k<=m; k++) {
		if (n_vec[k] == 0) continue
		ck = ck_vec[k] / n_tot
		Q  = Q + (ck / c0)^2 / (n_vec[k] - k)
	}
	Q = n_tot * (n_tot + 2) * Q

	return((Q, m))
}
real matrix function praisk_toeplitz(real colvector c)
{
	real scalar n, i, j
	real matrix T

	n = rows(c)
	T = J(n, n, 0)
	for (i=1; i<=n; i++) {
		for (j=1; j<=i; j++) {
			T[i,j] = c[i-j+1]
		}
	}
	return(T)
}


real matrix function praisk_vp_inv(real colvector rho, real scalar p)
{
	real matrix  vpinv, rho1
	real scalar  i, j, k1, k2, s1, s2

	vpinv = J(p, p, 0)
	rho1  = (-1 \ rho)

	for (j=1; j<=p; j++) {
		for (i=1; i<=j; i++) {
			s2 = 0
			for (k2 = p+1-j; k2 <= p+i-j; k2++) {
				s2 = s2 + rho[k2] * rho[k2+j-i]
			}
			s1 = 0
			for (k1=1; k1<=i; k1++) {
				s1 = s1 + rho1[k1] * rho1[k1+j-i]
			}
			vpinv[i,j] = s1 - s2
			vpinv[j,i] = vpinv[i,j]
		}
	}
	return(vpinv)
}


// compute Wald F statistic from named e(b) and e(V) matrices
void function praisk_wald_f(string scalar bname,
                             string scalar Vname,
                             real   scalar dfm,
                             real   scalar nocons,
                             string scalar rscalar)
{
	real matrix b, V
	real scalar k, F

	b = st_matrix(bname)
	V = st_matrix(Vname)
	k = cols(b)

	if (!nocons) {
		b = b[|1,1 \ 1,k-1|]
		V = V[|1,1 \ k-1,k-1|]
	}

	F = (b * invsym(V) * b')[1,1] / dfm
	st_numscalar(rscalar, F)
}


// compute maximum modulus of companion matrix eigenvalues
real scalar function praisk_ar_maxroot(real colvector rho, real scalar p)
{
	real matrix companion, eigvals

	if (p == 1) return(abs(rho[1,1]))

	companion = J(p, p, 0)
	companion[1, .] = rho'
	companion[|2,1 \ p,p-1|] = I(p-1)

	eigvals = eigenvalues(companion)
	return(max(sqrt(Re(eigvals):^2 + Im(eigvals):^2)))
}


// compute AR innovation residuals pooled across segments
real colvector function praisk_ar_resid(real colvector u,
                                         real matrix    allsegs,
                                         real colvector rho,
                                         real scalar    p)
{
	real scalar    g, nsegs, r1, r2, ns, i, lag
	real scalar    val
	real colvector ug, er, out

	nsegs = rows(allsegs)
	out   = J(0, 1, 0)

	for (g=1; g<=nsegs; g++) {
		r1 = allsegs[g,1]
		r2 = allsegs[g,2]
		ns = r2 - r1 + 1
		if (ns <= p) continue

		ug = u[|r1 \ r2|]
		er = J(ns - p, 1, 0)

		for (i=1; i<=ns-p; i++) {
			val = ug[i+p]
			for (lag=1; lag<=p; lag++) {
				val = val - rho[lag] * ug[i+p-lag]
			}
			er[i] = val
		}
		out = (out \ er)
	}
	return(out)
}


// estimate rho by Yule-Walker (pooled cross-products across segments)
real colvector function praisk_pooled_yw(real colvector   u,
                                          real matrix      allsegs,
                                          real scalar      p,
                                          real matrix      A_out)
{
	real scalar    g, nsegs, r1, r2, ns, i, j, lo, hi
	real colvector rho, ug, b
	real matrix    A

	nsegs = rows(allsegs)
	A     = J(p, p, 0)
	b     = J(p, 1, 0)

	for (g=1; g<=nsegs; g++) {
		r1 = allsegs[g,1]
		r2 = allsegs[g,2]
		ns = r2 - r1 + 1
		if (ns <= p) continue

		ug = u[|r1 \ r2|]

		for (j=1; j<=p; j++) {
			if (ns > j) {
				b[j] = b[j] + (ug[|j+1 \ ns|]' * ug[|1 \ ns-j|])[1,1]
			}
		}

		for (i=1; i<=p; i++) {
			for (j=1; j<=i; j++) {
				lo = max((i,j)) + 1
				hi = ns
				if (hi >= lo) {
					A[i,j] = A[i,j] + (ug[|lo-i \ hi-i|]' * ug[|lo-j \ hi-j|])[1,1]
				}
				A[j,i] = A[i,j]
			}
		}
	}

	if (A[1,1] == 0) {
		errprintf("ERROR: No segment has enough observations to estimate AR(%g)\n", p)
		exit(198)
	}

	rho   = lusolve(A, b)
	A_out = A
	return(rho)
}


void function praisk_transform_segment(real colvector ys,  real matrix  Xs,
                                        real colvector rho, real scalar  p,
                                        real colvector yrs, real matrix  xrs)
{
	real matrix    vpinv, p0, pm
	real scalar    n
	real colvector col1

	n     = rows(ys)
	vpinv = praisk_vp_inv(rho, p)
	p0    = cholesky(vpinv)
	p0    = p0[p::1, p::1]

	col1  = (1 \ -rho \ J(n-p-1, 1, 0))
	pm    = praisk_toeplitz(col1)
	pm[|1,1 \ p,p|] = p0

	yrs = pm * ys
	xrs = pm * Xs
}


real matrix function praisk_build_segments(real colvector panid,
                                            real colvector tvec,
                                            pointer(real scalar) scalar ngaps_ptr)
{
	real scalar n, i, seg_start, is_new_seg
	real matrix segs

	n          = rows(panid)
	seg_start  = 1
	segs       = J(0, 2, .)

	for (i=2; i<=n; i++) {
		is_new_seg = 0
		if (panid[i] != panid[i-1]) {
			is_new_seg = 1
		}
		else if (tvec[i] - tvec[i-1] != 1) {
			is_new_seg = 1
		}
		if (is_new_seg) {
			segs      = (segs \ (seg_start, i-1))
			seg_start = i
		}
	}
	segs = (segs \ (seg_start, n))
	*ngaps_ptr = rows(segs) - 1
	return(segs)
}


void function praisk_transform_panel(real colvector y,       real matrix  X,
                                      real colvector rho,     real scalar  p,
                                      real matrix    allsegs,
                                      real colvector yr,      real matrix  xr)
{
	real scalar    g, nsegs, r1, r2, ns
	real colvector yrs
	real matrix    xrs

	nsegs = rows(allsegs)
	for (g=1; g<=nsegs; g++) {
		r1  = allsegs[g,1]
		r2  = allsegs[g,2]
		ns  = r2 - r1 + 1
		yrs = J(ns, 1, .)
		xrs = J(ns, cols(X), .)
		praisk_transform_segment(y[|r1 \ r2|],
		                          X[|r1,1 \ r2,cols(X)|],
		                          rho, p, yrs, xrs)
		yr[|r1 \ r2|]            = yrs
		xr[|r1,1 \ r2,cols(X)|] = xrs
	}
}


void function praisk_main(string scalar yvar,
                           string scalar xvars_expanded,
                           real   scalar p,
                           string scalar touse,
                           string scalar timevar,
                           string scalar panelvar,
                           real   scalar nocons,
                           real   scalar tol,
                           real   scalar maxiter,
                           string scalar vcetype,
                           string scalar clustervar)
{
	real matrix      X, yr, xr, invxx, cov, cov_v, A_yw, data, vpinv
	real matrix      meat, scores, allsegs
	real colvector   y, u, rho, oldrho, b, es, serho, clid, ar_res
	real colvector   panid, tvec
	real scalar      nobs, k, iter, uu, s2, hc_scale, has_x
	real scalar      ll, ldet, i, g, nclust, ngaps, disp_val, s2_ar, n_ar
	real scalar      ss_res, ss_tot, yrbar
	pointer(real scalar) scalar ngaps_ptr
	string matrix    rhonames
	string rowvector allvars

	has_x = (xvars_expanded != "")

	if (panelvar != "") {
		if (clustervar != "") {
			if (has_x) allvars = (touse, panelvar, timevar, yvar, tokens(xvars_expanded), clustervar)
			else       allvars = (touse, panelvar, timevar, yvar, clustervar)
		}
		else {
			if (has_x) allvars = (touse, panelvar, timevar, yvar, tokens(xvars_expanded))
			else       allvars = (touse, panelvar, timevar, yvar)
		}
	}
	else {
		if (clustervar != "") {
			if (has_x) allvars = (touse, timevar, yvar, tokens(xvars_expanded), clustervar)
			else       allvars = (touse, timevar, yvar, clustervar)
		}
		else {
			if (has_x) allvars = (touse, timevar, yvar, tokens(xvars_expanded))
			else       allvars = (touse, timevar, yvar)
		}
	}

	data = st_data(., allvars)
	data = data[selectindex(data[.,1] :== 1), .]

	if (panelvar != "") {
		data  = data[order(data[|1,1 \ rows(data),3|], (2,3)), .]
		panid = data[., 2]
		tvec  = data[., 3]
		y     = data[., 4]
		if (clustervar != "") {
			if (has_x) X = data[|1,5 \ rows(data), cols(data)-1|]
			else       X = J(rows(data), 0, .)
			clid = data[., cols(data)]
		}
		else {
			if (has_x) X = data[|1,5 \ rows(data), cols(data)|]
			else       X = J(rows(data), 0, .)
			clid = J(0, 1, .)
		}
	}
	else {
		data  = data[order(data[.,2], 1), .]
		panid = J(rows(data), 1, 1)
		tvec  = data[., 2]
		y     = data[., 3]
		if (clustervar != "") {
			if (has_x) X = data[|1,4 \ rows(data), cols(data)-1|]
			else       X = J(rows(data), 0, .)
			clid = data[., cols(data)]
		}
		else {
			if (has_x) X = data[|1,4 \ rows(data), cols(data)|]
			else       X = J(rows(data), 0, .)
			clid = J(0, 1, .)
		}
	}

	if (nocons == 0) X = (X, J(rows(X), 1, 1))

	nobs = rows(y)
	k    = cols(X)

	ngaps_ptr = &ngaps
	ngaps     = 0
	allsegs   = praisk_build_segments(panid, tvec, ngaps_ptr)
	ngaps     = *ngaps_ptr

	A_yw   = J(p, p, 0)
	u      = y - X * (invsym(X'*X) * (X'*y))
	rho    = praisk_pooled_yw(u, allsegs, p, A_yw)
	oldrho = rho :+ 1

	yr = J(nobs, 1, .)
	xr = J(nobs, k, .)

	// accumulate iteration history
	iter_hist = (0, 0)

	iter = 0
	while (max(abs(rho - oldrho)) > tol) {
		iter = iter + 1
		if (iter > maxiter) {
			errprintf("Maximum number of iterations exceeded!\n")
			exit(430)
		}
		oldrho = rho
		praisk_transform_panel(y, X, rho, p, allsegs, yr, xr)
		invxx = invsym(xr'*xr)
		b     = invxx * (xr'*yr)
		u     = y - X*b
		rho   = praisk_pooled_yw(u, allsegs, p, A_yw)
		if (p == 1) {
			disp_val = rho[1,1]
		}
		else {
			disp_val = praisk_ar_maxroot(rho, p)
		}
		iter_hist = iter_hist \ (iter, disp_val)
	}

	es  = yr - xr*b
	uu  = (es'*es)[1,1]
	s2  = uu / nobs
	cov = (uu/(nobs-k)) * invxx

	if (vcetype == "robust") {
		hc_scale = nobs / (nobs - k)
		meat     = xr' * diag(es:^2) * xr
		cov_v    = hc_scale * invxx * meat * invxx
	}
	else if (vcetype == "cluster") {
		nclust   = rows(uniqrows(clid))
		hc_scale = (nclust/(nclust-1)) * ((nobs-1)/(nobs-k))
		meat     = J(k, k, 0)
		for (g=1; g<=nclust; g++) {
			scores = xr[selectindex(clid :== uniqrows(clid)[g]), .] ///
			       :* es[selectindex(clid :== uniqrows(clid)[g])]
			meat   = meat + (colsum(scores))' * colsum(scores)
		}
		cov_v = hc_scale * invxx * meat * invxx
	}
	else {
		cov_v = cov
	}

	// correct SE for rho_hat
	ar_res = praisk_ar_resid(u, allsegs, rho, p)
	n_ar   = rows(ar_res)
	s2_ar  = (ar_res' * ar_res)[1,1] / n_ar
	serho  = sqrt(diagonal(s2_ar * invsym(A_yw)))

	vpinv = praisk_vp_inv(rho, p)
	ldet  = ln(det(vpinv))
	ll    = - nobs/2 * ln(2*pi())  ///
	        - nobs/2 * ln(s2)      ///
	        + 0.5   * ldet         ///
	        - uu / (2*s2)

	ss_res = uu
	if (nocons == 0) {
		yrbar  = mean(yr)
		ss_tot = ((yr :- yrbar)'*(yr :- yrbar))[1,1]
	}
	else {
		ss_tot = (yr'*yr)[1,1]
	}

	st_matrix("r(b)",     b')
	st_matrix("r(V)",     cov_v)
	st_matrix("r(rho)",   rho')
	st_matrix("r(serho)", serho')
	st_matrix("r(iter_hist)", iter_hist)
	st_numscalar("r(ll)",            ll)
	st_numscalar("r(nobs)",          nobs)
	st_numscalar("r(k)",             k)
	st_numscalar("r(p_lag)",          p)
	st_numscalar("r(iter)",          iter)
	st_numscalar("r(ss_res)",        ss_res)
	st_numscalar("r(ss_tot)",        ss_tot)
	st_numscalar("r(ngaps)",         ngaps)
	st_numscalar("r(nonstationary)", (praisk_ar_maxroot(rho, p) >= 1))
	if (vcetype == "cluster") st_numscalar("r(nclust)", nclust)

	rhonames = J(p, 1, "")
	for (i=1; i<=p; i++) rhonames[i,1] = "rho" + strofreal(i)
	st_matrixcolstripe("r(rho)",   (J(p,1,""), rhonames))
	st_matrixcolstripe("r(serho)", (J(p,1,""), rhonames))
}

end

