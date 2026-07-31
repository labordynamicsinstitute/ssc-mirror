*! 1.0.0	Ariel Linden 21Jul2026	// panel extension of betark; PCSE (default) and DK panel-corrected VCEs

program define xtbetark, eclass
	version 14.0

	if replay() {
		if "`e(cmd)'" != "xtbetark" {
			di as err "results for {bf:xtbetark} not found"
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

	local N_g   = e(N_g)
	local g_min = e(g_min)
	local g_avg = e(g_avg)
	local g_max = e(g_max)

	di
	di as txt "Beta AR(" as res e(p_lag) as txt ") regression, panel data, joint conditional ML" ///
		_col(66) "Number of obs" _col(80) "=" ///
		_col(82) as res %8.0fc e(N)
	di as txt "Group variable: " _col(19) as res "`e(panelvar)'" ///
		_col(66) as txt "Number of groups" _col(80) "= " as res %8.0f `N_g'
	di as txt "Time variable:  " _col(19) as res "`e(timevar)'" ///
		_col(66) as txt "Obs per group:"
	di as txt _col(70) "min" _col(80) "= " as res %8.0f `g_min'
	di as txt _col(70) "avg" _col(80) "= " as res %8.1f `g_avg'
	di as txt _col(70) "max" _col(80) "= " as res %8.0f `g_max'
	di as txt "VCE:            " _col(19) as res "`e(vcetype)'"
	di

	di as txt "Wald chi2(" as res e(df_m) as txt ")" ///
		_col(49) "=" _col(52) as res %9.2f e(chi2)
	di as txt "Prob > chi2" ///
		_col(49) "=" _col(52) as res %9.4f e(p)
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
		  Level(cilevel)							///
		  COEFLegend								///
		  ITERate(integer 1500)						///
		  TOLerance(real 1e-6)						///
		  NOLOg										///
		  from(string)								///
		  VCE(string)								///
		  NMK								///
		]

	local cmdline `"xtbetark `0'"'

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

	// panel variable is required for xtbetark (unlike betark, where it is optional)
	_xt, trequired
	local panelvar "`r(ivar)'"
	local timevar  "`r(tvar)'"

	// vce()
	local vce_l = lower("`vce'")
	if "`vce_l'" == "" local vce_l "pcse"
	if !inlist("`vce_l'", "pcse", "dk", "oim") {
		di as err "vce() must be pcse, dk, or oim"
		exit 198
	}
	local nmk_flag = ("`nmk'" != "")

	marksample touse
	markout `touse' `timevar' `panelvar'
	qui count if `touse'
	if r(N) <= 1 {
		di as err "insufficient observations"
		exit 2001
	}

	gettoken depvar indepvars : varlist

	qui summarize `depvar' if `touse'
	if r(min) <= 0 | r(max) >= 1 {
		di as err "`depvar' must be greater than zero and less than one"
		exit 459
	}

	// link/slink are hardcoded (no additional options yet implemented)
	local link   "logit"
	local linkf  "log(u/(1-u))"
	local linkt  "Logit"
	local slink  "log"
	local slinkf "log(u)"
	local slinkt "Log"

	quietly tsreport if `touse'
	local ngaps = r(N_gaps)
	if `ngaps' > 0 {
		di ""
		di as txt "Number of gaps in sample = " as res `ngaps' ///
			as txt "   (gap count includes panel changes)"
		di as txt "note: computations for rho restarted at each gap."
	}

	// panel summary stats
	tempvar grpct
	quietly {
		by `panelvar', sort: gen `c(obs_t)' `grpct' = _N if `touse'
		summarize `grpct' if `touse', meanonly
	}
	local g_min = r(min)
	local g_max = r(max)
	local g_avg = r(mean)
	quietly {
		tempvar panfirst
		by `panelvar': gen byte `panfirst' = (_n==1) if `touse'
		summarize `panfirst' if `touse', meanonly
	}
	local N_g = r(sum)

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

	local k1 : word count `meannames'
	local k2 : word count `scalenames'
	local k3 : word count `arnames'

	local k1_est : word count `indepvars_est'
	if !`nocons_mean' local k1_est = `k1_est' + 1
	local k2_est : word count `scale_est'
	local k2_est = `k2_est' + 1

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

	// DK bandwidth
	local dklag = `lag'

	di ""
	mata: xtbetark_main("`depvar'", "`indepvars_est'", "`scale_est'",	///
	                   `lag', "`touse'", "`timevar'", "`panelvar'",	///
	                   `nocons_mean', `k1_est', `k2_est', `k3',		///
	                   `tolerance', `iterate', "`b_init'", `ngaps',	///
	                   ("`nolog'" == ""), "`vce_l'", `dklag', `nmk_flag')

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

	ereturn local cmd       "xtbetark"
	ereturn local predict    "xtbetark_p"
	ereturn local cmdline    `"`cmdline'"'
	ereturn local title      "Beta AR(`lag') regression, panel data, joint conditional ML"
	ereturn local link       "`link'"
	ereturn local linkf      "`linkf'"
	ereturn local linkt      "`linkt'"
	ereturn local slink      "`slink'"
	ereturn local slinkf     "`slinkf'"
	ereturn local slinkt     "`slinkt'"
	ereturn local timevar    "`timevar'"
	ereturn local panelvar   "`panelvar'"
	ereturn local ivar       "`panelvar'"
	ereturn local tvar       "`timevar'"
	ereturn local noconstant "`constant'"
	if "`vce_l'" == "pcse" {
		ereturn local vce     "pcse"
		ereturn local vcetype "Panel-corrected"
	}
	else if "`vce_l'" == "dk" {
		ereturn local vce     "dk"
		ereturn local vcetype "Driscoll-Kraay"
	}
	else {
		ereturn local vce     "oim"
		ereturn local vcetype "OIM"
	}

	ereturn scalar ll         = `ll_post'
	ereturn scalar N          = `nobs_post'
	ereturn scalar p_lag      = `lag'
	ereturn scalar iterations = `niter_post'
	ereturn scalar converged  = `conv_post'
	ereturn scalar ngaps      = `ngaps'
	ereturn scalar tolerance  = `tolerance'
	ereturn scalar N_g        = `N_g'
	ereturn scalar g_min      = `g_min'
	ereturn scalar g_avg      = `g_avg'
	ereturn scalar g_max      = `g_max'
	if "`vce_l'" == "dk"   ereturn scalar dklag      = `dklag'
	if "`vce_l'" == "pcse" ereturn scalar nmk = `nmk_flag'

	if `nocons_mean' {
		ereturn scalar df_m = `k1_est'
	}
	else {
		ereturn scalar df_m = `k1_est' - 1
	}

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


mata:

real matrix function xtbetark_getsegs(real colvector panid, real colvector tvec)
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


// likelihood function
void function xtbetark_lf(transmorphic M, real rowvector b, real colvector lnf)
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


// Driscoll-Kraay-style sandwich
real matrix function xtbetark_dk_vcv(real matrix    scores,
                                      real colvector panid,
                                      real colvector tvec,
                                      real matrix    Hinv,
                                      real scalar    dklag)
{
	real matrix    h, Omega, Oj, scores_s
	real colvector tvec_s, tuniq, cnt, t_start
	real scalar    T, t, j, q, r1, r2, w
	real matrix    ord

	q   = cols(scores)
	ord = order((tvec, panid), (1,2))
	tvec_s   = tvec[ord]
	scores_s = scores[ord, .]

	tuniq = uniqrows(tvec_s)
	T     = rows(tuniq)

	h = J(T, q, 0)
	r1 = 1
	for (t=1; t<=T; t++) {
		r2 = r1
		while (r2 < rows(tvec_s)) {
			if (tvec_s[r2+1] != tvec_s[r1]) break
			r2 = r2 + 1
		}
		h[t, .] = colsum(scores_s[|r1,1 \ r2,q|])
		r1 = r2 + 1
	}

	Omega = h' * h
	for (j=1; j<=dklag; j++) {
		if (j >= T) break
		w  = 1 - j/(dklag+1)
		Oj = h[|j+1,1 \ T,q|]' * h[|1,1 \ T-j,q|]
		Omega = Omega + w * (Oj + Oj')
	}

	return(Hinv * Omega * Hinv)
}


// Beck-Katz PCSE
real matrix function xtbetark_pcse_vcv(real matrix    scores,
                                        real matrix    Xall,
                                        real colvector keq,
                                        real colvector panid,
                                        real matrix    Hinv,
                                        real scalar    nmk_correct,
                                        real scalar    nobs,
                                        real scalar    q)
{
	real matrix    MEAT, Sigma_eep, block, V_out
	real colvector panels, eq_start, eq_end, si, sj, Xe_i, Xep_j
	real scalar    neq, e, ep, M, i, j, T_ij, n_i, n_j, off

	neq    = cols(scores)
	panels = uniqrows(panid)
	M      = rows(panels)

	eq_start = J(neq, 1, .)
	eq_end   = J(neq, 1, .)
	off = 0
	for (e=1; e<=neq; e++) {
		eq_start[e] = off + 1
		eq_end[e]   = off + keq[e]
		off = off + keq[e]
	}

	MEAT = J(q, q, 0)

	for (e=1; e<=neq; e++) {
		for (ep=e; ep<=neq; ep++) {

			// Sigma_{e,e'}[i,j] = (1/T_ij) * sum_t scores_e,it * scores_e',jt
			Sigma_eep = J(M, M, 0)
			for (i=1; i<=M; i++) {
				si = scores[selectindex(panid :== panels[i]), e]
				for (j=1; j<=M; j++) {
					sj   = scores[selectindex(panid :== panels[j]), ep]
					T_ij = min((rows(si), rows(sj)))
					Sigma_eep[i,j] = (si[|1 \ T_ij|]' * sj[|1 \ T_ij|])[1,1] / T_ij
				}
			}

			block = J(keq[e], keq[ep], 0)
			for (i=1; i<=M; i++) {
				n_i  = sum(panid :== panels[i])
				Xe_i = Xall[selectindex(panid :== panels[i]), eq_start[e]..eq_end[e]]
				for (j=1; j<=M; j++) {
					n_j   = sum(panid :== panels[j])
					T_ij  = min((n_i, n_j))
					Xep_j = Xall[selectindex(panid :== panels[j]), eq_start[ep]..eq_end[ep]]
					block = block + Sigma_eep[i,j] *
					        (Xe_i[|1,1 \ T_ij,keq[e]|]' * Xep_j[|1,1 \ T_ij,keq[ep]|])
				}
			}

			MEAT[|eq_start[e],eq_start[ep] \ eq_end[e],eq_end[ep]|] = block
			if (e != ep) {
				MEAT[|eq_start[ep],eq_start[e] \ eq_end[ep],eq_end[e]|] = block'
			}
		}
	}

	V_out = Hinv * MEAT * Hinv
	if (nmk_correct) V_out = nobs * V_out / (nobs - q)
	return(V_out)
}


void function xtbetark_main(string scalar yvar,
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
                           real   scalar showlog,
                           string scalar vcetype,
                           real   scalar dklag,
                           real   scalar nmk_correct)
{
	real matrix      data, allsegs, scores, Hinv, V_out, X_mean, X_scale, G, Xall
	real colvector   y, panid, tvec, seg_start, seg_end, keq
	real rowvector   b0
	real scalar      nobs, converged, ll, nexcl, jj, has_x, has_z, nx, nz, col, q, neq
	string matrix    allvars

	transmorphic     M

	has_x = (xvars != "")
	has_z = (zvars != "")
	nx    = has_x ? cols(tokens(xvars)) : 0
	nz    = has_z ? cols(tokens(zvars)) : 0

	// column layout
	allvars = (tousename, panelvar, timevar, yvar)
	if (has_x) allvars = (allvars, tokens(xvars))
	if (has_z) allvars = (allvars, tokens(zvars))

	data = st_data(., allvars)
	data = data[selectindex(data[.,1] :== 1), .]

	data  = data[order(data[|1,1 \ rows(data),3|], (2,3)), .]
	panid = data[., 2]
	tvec  = data[., 3]
	y     = data[., 4]

	col = 4
	if (has_x) {
		X_mean = data[|1,col+1 \ rows(data), col+nx|]
		col = col + nx
	}
	else {
		X_mean = J(rows(data), 0, .)
	}
	if (has_z) {
		X_scale = data[|1,col+1 \ rows(data), col+nz|]
		col = col + nz
	}
	else {
		X_scale = J(rows(data), 0, .)
	}
	// column order
	if (!nocons_mean) X_mean = (X_mean, J(rows(data), 1, 1))
	X_scale = (X_scale, J(rows(data), 1, 1))   // scale eq always has a constant

	nobs    = rows(y)
	allsegs = xtbetark_getsegs(panid, tvec)
	seg_start = allsegs[.,1]
	seg_end   = allsegs[.,2]

	b0 = st_matrix(b_init_name)

	M = moptimize_init()
	moptimize_init_evaluator(M, &xtbetark_lf())
	moptimize_init_evaluatortype(M, "lf")
	moptimize_init_depvar(M, 1, yvar)
	moptimize_init_touse(M, tousename)

	// OIM vce
	moptimize_init_vcetype(M, "oim")

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

	if (vcetype == "dk" | vcetype == "pcse") {
		Hinv = moptimize_result_V(M)   // OIM-based bread, H^-1, q x q (q = total coefficients)

		scores = moptimize_result_scores(M)   // nobs x (2+p), pre-chain-rule

		q   = k1 + k2 + p
		neq = 2 + p

		// keq: number of coefficient columns belonging to each equation
		keq = (k1 \ k2 \ J(p, 1, 1))

		// Xall: equation design blocks concatenated in that same order
		Xall = (X_mean, X_scale)
		for (jj=1; jj<=p; jj++) {
			Xall = (Xall, J(rows(data), 1, 1))
		}

		if (vcetype == "dk") {
			G = (X_mean :* scores[.,1], X_scale :* scores[.,2])
			for (jj=1; jj<=p; jj++) {
				G = (G, scores[., 2+jj])
			}
			V_out = xtbetark_dk_vcv(G, panid, tvec, Hinv, dklag)
		}
		else {
			V_out = xtbetark_pcse_vcv(scores, Xall, keq, panid, Hinv, nmk_correct, nobs, q)
		}

		st_matrix("r(V)", V_out)
	}
	else {
		st_matrix("r(V)", moptimize_result_V(M))
	}

	st_matrix("r(b)", moptimize_result_coefs(M))
	st_numscalar("r(ll)", ll)
	st_numscalar("r(nobs)", nobs - nexcl)
	st_numscalar("r(niter)", moptimize_result_iterations(M))
	st_numscalar("r(converged)", converged)
}

end
