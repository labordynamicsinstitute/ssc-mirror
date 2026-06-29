*! 1.0.0	Ariel Linden 27Jun2026

program define betark, eclass
	version 14.0

	if replay() {
		if "`e(cmd)'" != "betark" {
			di as err "results for {bf:betark} not found"
			exit 301
		}
		Display `0'
		exit
	}

	Estimate `0'
end

program define Display
	syntax [, Level(cilevel) COEFLegend *]
	_get_diopts diopts rest, `options'

	if "`coeflegend'" != "" {
		_coef_table, `diopts' level(`level') coeflegend
		exit
	}

	di
	di as txt "Beta AR(" as res e(p_lag) as txt ") regression, joint conditional ML" ///
		_col(49) "Number of obs" _col(67) "=" ///
		_col(69) as res %10.0fc e(N)
	di as txt _col(49) "Wald chi2(" as res e(df_m) as txt ")" ///
		_col(67) "=" _col(70) as res %9.2f e(chi2)
	di as txt _col(49) "Prob > chi2" ///
		_col(67) "=" _col(70) as res %9.4f e(p)
	di

	di as txt "Link function" _col(16) ":" ///
		_skip(2) as res "g(u) = `e(linkf)'" ///
		as txt _col(49) "[{res:`e(linkt)'}]"
	di as txt "Slink function" _col(16) ":" ///
		_skip(2) as res "g(u) = `e(slinkf)'" ///
		as txt _col(49) "[{res:`e(slinkt)'}]"
	di
	di as txt "Log likelihood" _col(16) "=" as res %11.8g e(ll)
	di

	_coef_table, `diopts' level(`level')
	ml_footnote
end

program define Estimate, eclass
	syntax varlist(numeric fv ts) [if] [in]		///
		, LAG(integer)								///
		[ SCale(varlist numeric fv ts)				///
		  noCONstant								///
		  LInk(string)								///
		  SLInk(string)								///
		  Level(cilevel)							///
		  COEFLegend								///
		  ITERate(integer 1500)						///
		  TOLerance(real 1e-6)						///
		  NOLOg										///
		  from(string)								///
		]

	local cmdline `"betark `0'"'

	if `lag' < 1 {
		di as err "lag() must be >= 1"
		exit 198
	}
	if `tolerance' <= 0 {
		di as err "tolerance() must be positive"
		exit 198
	}
	if `iterate' < 1 {
		di as err "iterate() must be a positive integer"
		exit 198
	}

	marksample touse
	qui count if `touse'
	if r(N) <= 1 {
		di as err "insufficient observations"
		exit 2001
	}

	gettoken depvar indepvars : varlist

	// depvar must be strictly in (0,1), same check as betareg
	qui summarize `depvar' if `touse'
	if r(min) <= 0 | r(max) >= 1 {
		di as err "`depvar' must be greater than zero and less than one"
		exit 459
	}

	// link / slink: identical menu and defaults to betareg
	ParseLink, `link'
	local link  `s(link)'
	local linkf `s(linkf)'
	local linkt `s(linkt)'
	ParseSlink, `slink'
	local slink  `s(slink)'
	local slinkf `s(slinkf)'
	local slinkt `s(slinkt)'

	// for v0.1.0, only logit/log are actually wired up in the Mata
	// likelihood; other links are parsed (for forward compatibility
	// with betareg's option menu) but not yet implemented
	if "`link'" != "logit" {
		di as err "link(`link') is not yet implemented in betark; only link(logit) is currently supported"
		exit 198
	}
	if "`slink'" != "log" {
		di as err "slink(`slink') is not yet implemented in betark; only slink(log) is currently supported"
		exit 198
	}

	// time variable required: AR(k) needs an explicit ordering
	_ts timevar panvar, panel
	if "`timevar'" == "" {
		di as err "betark requires the data to be tsset"
		exit 459
	}
	local tsdelta = r(tdelta)

	quietly tsreport if `touse'
	local ngaps = r(N_gaps)
	if `ngaps' > 0 {
		di ""
		di as txt "Number of gaps in sample = " as res `ngaps' ///
			as txt "   (gap count includes panel changes)"
		di as txt "note: computations for rho restarted at each gap."
	}

	local nocons_mean = ("`constant'" == "noconstant")
	if "`indepvars'" == "" {
		if `nocons_mean' {
			di as err "no regressors and noconstant specified: empty mean model"
			exit 198
		}
		local indepvars_full ""
		local indepvars_est  ""
	}
	else {
		_rmcoll `indepvars' if `touse', expand `constant'
		local indepvars_full `r(varlist)'
		local indepvars_est ""
		foreach v of local indepvars_full {
			if substr("`v'", 1, 2) != "o." local indepvars_est `indepvars_est' `v'
		}
	}

	// collinearity removal, scale equation (same logic)
	local nocons_scale = 0
	if "`scale'" != "" {
		_rmcoll `scale' if `touse', expand
		local scale_full `r(varlist)'
		local scale_est ""
		foreach v of local scale_full {
			if substr("`v'", 1, 2) != "o." local scale_est `scale_est' `v'
		}
	}
	else {
		local scale_full ""
		local scale_est  ""
	}

	markout `touse' `depvar' `indepvars_est' `scale_est'

	local meannames `indepvars_full'
	if !`nocons_mean' local meannames `meannames' _cons
	local scalenames `scale_full' _cons
	local arnames ""
	forvalues j = 1/`lag' {
		local arnames `arnames' rho`j'
	}

	local k1 : word count `meannames'		// FULL count (display)
	local k2 : word count `scalenames'		// FULL count (display)
	local k3 : word count `arnames'

	local k1_est : word count `indepvars_est'
	if !`nocons_mean' local k1_est = `k1_est' + 1
	local k2_est : word count `scale_est'
	local k2_est = `k2_est' + 1		// scale always has _cons in v0.1.0

	// starting values: static betareg fit (rho = 0), on the reduced
	tempname b0
	if "`scale_est'" != "" local scaleopt "scale(`scale_est')"
	else                   local scaleopt ""
	capture quietly betareg `depvar' `indepvars_est' if `touse', `constant' `scaleopt'
	if _rc {
		di as err "could not obtain starting values from a static betareg fit; try from()"
		exit 430
	}
	tempname bmean bscale
	matrix `bmean'  = e(b)[1, 1..`k1_est']
	matrix `bscale' = e(b)[1, `k1_est'+1..`k1_est'+`k2_est']

	tempname b_init
	matrix `b_init' = `bmean', `bscale', J(1, `k3', 0.1/`lag')

	if `"`from'"' != "" {
		matrix `b_init' = `from'
	}

	di ""
	mata: betark_main("`depvar'", "`indepvars_est'", "`scale_est'",	///
	                   `lag', "`touse'", "`timevar'", "`panvar'",		///
	                   `nocons_mean', `k1_est', `k2_est', `k3',		///
	                   `tolerance', `iterate', "`b_init'", `ngaps',		///
	                   ("`nolog'" == ""))

	matrix b_post = r(b)
	matrix V_post = r(V)
	local ll_post    = r(ll)
	local nobs_post  = r(nobs)
	local niter_post = r(niter)
	local conv_post  = r(converged)

	if `conv_post' == 0 {
		di as txt "{p}Warning: optimizer did not report convergence within iterate(`iterate'). " ///
		          "Results may be unreliable; consider increasing iterate() or supplying from().{p_end}"
	}

	local allnames_full `meannames' `scalenames' `arnames'
	local k_full : word count `allnames_full'

	tempname b_full V_full
	matrix `b_full' = J(1, `k_full', 0)
	matrix `V_full' = J(`k_full', `k_full', 0)

	local col_f = 0
	local col_r = 0
	foreach v of local allnames_full {
		local col_f = `col_f' + 1
		if substr("`v'", 1, 2) != "o." {
			local col_r = `col_r' + 1
			matrix `b_full'[1, `col_f'] = b_post[1, `col_r']
			local col_f2 = 0
			local col_r2 = 0
			foreach v2 of local allnames_full {
				local col_f2 = `col_f2' + 1
				if substr("`v2'", 1, 2) != "o." {
					local col_r2 = `col_r2' + 1
					matrix `V_full'[`col_f', `col_f2'] = V_post[`col_r', `col_r2']
				}
			}
		}
	}
	matrix b_post = `b_full'
	matrix V_post = `V_full'

	local colnames ""
	foreach v of local meannames {
		local colnames `"`colnames' `depvar':`v'"'
	}
	foreach v of local scalenames {
		local colnames `"`colnames' scale:`v'"'
	}
	foreach v of local arnames {
		local colnames `"`colnames' ar:`v'"'
	}

	matrix colnames b_post = `colnames'
	matrix colnames V_post = `colnames'
	matrix rownames V_post = `colnames'

	ereturn post b_post V_post, depname(`depvar') obs(`nobs_post') esample(`touse')

	ereturn local cmd       "betark"
	ereturn local predict    "betark_p"
	ereturn local cmdline    `"`cmdline'"'
	ereturn local title      "Beta AR(`lag') regression, joint conditional ML"
	ereturn local link       "`link'"
	ereturn local linkf      "`linkf'"
	ereturn local linkt      "`linkt'"
	ereturn local slink      "`slink'"
	ereturn local slinkf     "`slinkf'"
	ereturn local slinkt     "`slinkt'"
	ereturn local timevar    "`timevar'"
	ereturn local panelvar   "`panvar'"
	ereturn local noconstant "`constant'"

	ereturn scalar ll         = `ll_post'
	ereturn scalar N          = `nobs_post'
	ereturn scalar p_lag      = `lag'
	ereturn scalar iterations = `niter_post'
	ereturn scalar converged  = `conv_post'
	ereturn scalar ngaps      = `ngaps'
	ereturn scalar tolerance  = `tolerance'

	if `nocons_mean' {
		ereturn scalar df_m = `k1_est'			// no constant: all mean-eq terms tested
	}
	else {
		ereturn scalar df_m = `k1_est' - 1		// constant present: excluded from the Wald test below
	}

	// Wald test on the mean equation's non-constant coefficients
	if "`indepvars_est'" != "" {
		qui test `indepvars_est'
		ereturn scalar chi2 = r(chi2)
		ereturn scalar p    = chi2tail(e(df_m), e(chi2))
	}
	else {
		ereturn scalar chi2 = 0
		ereturn scalar p    = 1
	}

	Display, level(`level') `coeflegend'
end


// link/slink parsers -- identical menu/defaults to betareg, kept as-is
program define ParseLink, sclass
	syntax [, logit PRObit CLOGlog LOGLog *]
	if `"`options'"' != "" {
		di as err "unrecognized link() function: `options'"
		exit 199
	}
	capture qui opts_exclusive "`logit' `probit' `cloglog' `loglog'"
	if _rc {
		di as err "only one of logit, probit, cloglog, or loglog is allowed"
		exit 198
	}
	local link `logit' `probit' `cloglog' `loglog'
	if "`link'" == "" local link "logit"
	sreturn local link "`link'"
	if "`link'" == "logit" {
		sreturn local linkf "log(u/(1-u))"
		sreturn local linkt "Logit"
	}
	else if "`link'" == "probit" {
		sreturn local linkf "invnormal(u)"
		sreturn local linkt "Probit"
	}
	else if "`link'" == "cloglog" {
		sreturn local linkf "log(-log(1-u))"
		sreturn local linkt "Comp. log-log"
	}
	else if "`link'" == "loglog" {
		sreturn local linkf "-log(-log(u))"
		sreturn local linkt "Log-log"
	}
end

program define ParseSlink, sclass
	syntax [, log root IDENtity *]
	if `"`options'"' != "" {
		di as err "unrecognized slink() function: `options'"
		exit 199
	}
	capture qui opts_exclusive "`identity' `root' `log'"
	if _rc {
		di as err "only one of log, root, or identity is allowed"
		exit 198
	}
	local slink `log' `root' `identity'
	if "`slink'" == "" local slink "log"
	sreturn local slink "`slink'"
	if "`slink'" == "log" {
		sreturn local slinkf "log(u)"
		sreturn local slinkt "Log"
	}
	else if "`slink'" == "root" {
		sreturn local slinkf "sqrt(u)"
		sreturn local slinkt "Square root"
	}
	else if "`slink'" == "identity" {
		sreturn local slinkf "u"
		sreturn local slinkt "Identity"
	}
end


// build time/panel segments (gaps restart the AR recursion)
mata:

real matrix function betark_getsegs(real colvector panid, real colvector tvec)
{
	real matrix    segs
	real scalar    n, i, start
	n = rows(panid)
	segs = J(0, 2, .)
	start = 1
	for (i=2; i<=n; i++) {
		if (panid[i] != panid[i-1] | tvec[i] != tvec[i-1] + 1) {
			segs = (segs \ (start, i-1))
			start = i
		}
	}
	segs = (segs \ (start, n))
	return(segs)
}


// joint conditional log-likelihood for the beta-AR(k) model
void function betark_lf(transmorphic M, real rowvector b, real colvector lnf)
{
	real colvector y, eta, lnphi, seg_start, seg_end
	real colvector eta_seg, y_seg, lnphi_seg
	real rowvector rho
	real scalar    p, nsegs, gg, r1, r2, ns, t_loc, kk
	real scalar    eta_t, xi_t, mu_t, phi_t

	y         = moptimize_util_userinfo(M, 1)
	seg_start = moptimize_util_userinfo(M, 2)
	seg_end   = moptimize_util_userinfo(M, 3)
	p         = moptimize_util_userinfo(M, 4)

	eta   = moptimize_util_xb(M, b, 1)
	lnphi = moptimize_util_xb(M, b, 2)

	rho = J(1, p, .)
	for (kk=1; kk<=p; kk++) {
		rho[kk] = moptimize_util_xb(M, b, 2+kk)[1]
	}

	lnf   = J(rows(eta), 1, 0)
	nsegs = rows(seg_start)

	for (gg=1; gg<=nsegs; gg++) {
		r1 = seg_start[gg]
		r2 = seg_end[gg]
		ns = r2 - r1 + 1
		if (ns <= p) continue

		y_seg     = y[|r1 \ r2|]
		eta_seg   = eta[|r1 \ r2|]
		lnphi_seg = lnphi[|r1 \ r2|]

		for (t_loc=p+1; t_loc<=ns; t_loc++) {

			eta_t = eta_seg[t_loc]
			xi_t  = 0
			for (kk=1; kk<=p; kk++) {
				xi_t = xi_t + rho[kk] * (logit(y_seg[t_loc-kk]) - eta_seg[t_loc-kk])
			}

			mu_t  = invlogit(eta_t + xi_t)
			mu_t  = min((max((mu_t, 1e-10)), 1-1e-10))
			phi_t = exp(lnphi_seg[t_loc])
			phi_t = max((phi_t, 1e-6))

			lnf[r1+t_loc-1] = lngamma(phi_t) - lngamma(mu_t*phi_t) - lngamma((1-mu_t)*phi_t) +
			                  (mu_t*phi_t - 1)*ln(y_seg[t_loc]) + ((1-mu_t)*phi_t - 1)*ln(1-y_seg[t_loc])
		}
	}
}


void function betark_main(string scalar yvar,
                           string scalar xvars,
                           string scalar zvars,
                           real   scalar p,
                           string scalar tousename,
                           string scalar timevar,
                           string scalar panelvar,
                           real   scalar nocons_mean,
                           real   scalar k1,
                           real   scalar k2,
                           real   scalar k3,
                           real   scalar tol,
                           real   scalar maxiter,
                           string scalar b_init_name,
                           real   scalar ngaps_in,
                           real   scalar showlog)
{
	real matrix      data, allsegs
	real colvector   y, panid, tvec, seg_start, seg_end
	real rowvector   b0
	real scalar      nobs, converged, ll, nexcl, jj
	string matrix    allvars
	transmorphic     M

	// load just enough to build segments and panel/time ordering
	if (panelvar != "") allvars = (tousename, panelvar, timevar, yvar)
	else                allvars = (tousename, timevar, yvar)

	data = st_data(., allvars)
	data = data[selectindex(data[.,1] :== 1), .]

	if (panelvar != "") {
		data  = data[order(data[|1,1 \ rows(data),3|], (2,3)), .]
		panid = data[., 2]
		tvec  = data[., 3]
		y     = data[., 4]
	}
	else {
		data  = data[order(data[.,2], 1), .]
		panid = J(rows(data), 1, 1)
		tvec  = data[., 2]
		y     = data[., 3]
	}

	nobs    = rows(y)
	allsegs = betark_getsegs(panid, tvec)
	seg_start = allsegs[.,1]
	seg_end   = allsegs[.,2]

	b0 = st_matrix(b_init_name)

	M = moptimize_init()
	moptimize_init_evaluator(M, &betark_lf())
	moptimize_init_evaluatortype(M, "lf")
	moptimize_init_depvar(M, 1, yvar)
	moptimize_init_touse(M, tousename)

	moptimize_init_eq_n(M, 2 + p)

	moptimize_init_eq_indepvars(M, 1, xvars)
	if (nocons_mean) moptimize_init_eq_cons(M, 1, "off")
	moptimize_init_eq_name(M, 1, yvar)

	moptimize_init_eq_indepvars(M, 2, zvars)
	moptimize_init_eq_name(M, 2, "scale")

	for (jj=1; jj<=p; jj++) {
		moptimize_init_eq_indepvars(M, 2+jj, "")
		moptimize_init_eq_name(M, 2+jj, "ar")
	}

	moptimize_init_userinfo(M, 1, y)
	moptimize_init_userinfo(M, 2, seg_start)
	moptimize_init_userinfo(M, 3, seg_end)
	moptimize_init_userinfo(M, 4, p)

	moptimize_init_conv_maxiter(M, maxiter)
	moptimize_init_conv_ptol(M, tol)
	moptimize_init_conv_vtol(M, tol)
	moptimize_init_conv_ignorenrtol(M, "on")
	moptimize_init_technique(M, "nr 5 bhhh 20 nr")
	moptimize_init_singularHmethod(M, "hybrid")
	if (showlog) moptimize_init_trace_value(M, "on")
	else         moptimize_init_trace_value(M, "off")

	if (cols(b0) > 0) {
		moptimize_init_eq_coefs(M, 1, b0[1, 1..k1])
		moptimize_init_eq_coefs(M, 2, b0[1, k1+1..k1+k2])
		for (jj=1; jj<=p; jj++) {
			moptimize_init_eq_coefs(M, 2+jj, b0[1, k1+k2+jj])
		}
	}

	converged = 1
	moptimize(M)
	if (moptimize_result_converged(M) == 0) converged = 0

	ll = moptimize_result_value(M)

	nexcl = 0
	for (jj=1; jj<=rows(seg_start); jj++) {
		if (seg_end[jj]-seg_start[jj]+1 > p) nexcl = nexcl + p
	}

	st_matrix("r(b)", moptimize_result_coefs(M))
	st_matrix("r(V)", moptimize_result_V(M))
	st_numscalar("r(ll)", ll)
	st_numscalar("r(nobs)", nobs - nexcl)
	st_numscalar("r(niter)", moptimize_result_iterations(M))
	st_numscalar("r(converged)", converged)
}

end
