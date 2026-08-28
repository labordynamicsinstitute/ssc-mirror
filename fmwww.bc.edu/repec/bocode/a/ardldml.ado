*! ardldml 1.0.1  24aug2026
*! DML-Bounds: ARDL bounds testing for cointegration with many persistent controls
*! Implements Villena (2026), SSRN working paper 6472826
*! Dr Merwan Roudane -- merwanroudane920@gmail.com
*! https://github.com/merwanroudane

program define ardldml, eclass sortpreserve
	version 14.0

	if (replay()) {
		if ("`e(cmd)'" != "ardldml") error 301
		syntax [, Level(cilevel) noHEADer noTABle noLEGend]
		_ardldml_display, level(`level') `header' `table' `legend'
		exit
	}

	syntax varlist(min=2 max=2 numeric) [if] [in] ,			///
		Controls(varlist numeric)							///
		[													///
			LAGS(integer 4)									///
			Integrated(varlist numeric)						///
			BLOcks(integer 5)								///
			KFolds(integer 0)								///
			BUFfer(integer 0)								///
			CASE(integer 3)									///
			MZproj(string)									///
			PENalty(string)									///
			CPen(real 1.1)									///
			LTOL(real 1e-10)								///
			DLAGs											///
			ST3cons											///
			Breps(integer 999)								///
			Level(cilevel)									///
			SEED(string)									///
			BSCHeme(string)									///
			noBOOTstrap										///
			noFReeze										///
			ETAfile(string)									///
			GRAPH											///
			GRAPHBLocks										///
			NAME(string)									///
			GRAPHOPTs(string asis)							///
			noHEADer										///
			noTABle											///
			noLEGend										///
			SHOWFirst										///
		]

	// ------------------------------------------------------------------
	// parse and validate
	// ------------------------------------------------------------------
	gettoken depvar focal : varlist
	local focal : word 2 of `varlist'

	if ("`depvar'" == "`focal'") {
		di as error "the dependent variable and the focal regressor must differ"
		exit 198
	}

	// K: blocks() is the native name, kfolds() a ddml-compatible synonym
	if (`kfolds' > 0) local blocks = `kfolds'
	if (`blocks' < 2) {
		di as error "blocks() must be at least 2"
		exit 198
	}
	if (`buffer' < 0) {
		di as error "buffer() must be non-negative"
		exit 198
	}
	if (`lags' < 1) {
		di as error "lags() must be at least 1"
		exit 198
	}
	if !inlist(`case', 1, 2, 3, 4, 5) {
		di as error "case() must be 1, 2, 3, 4 or 5"
		exit 198
	}
	if (`cpen' <= 0) {
		di as error "cpen() must be positive"
		exit 198
	}
	if (`ltol' <= 0 | `ltol' >= 1) {
		di as error "ltol() must be in (0,1)"
		exit 198
	}

	// m_Z projection
	if ("`mzproj'" == "") local mzproj "adaptive"
	local mzproj = lower("`mzproj'")
	if !inlist("`mzproj'", "adaptive", "plain", "ols") {
		di as error "mzproj() must be adaptive, plain or ols"
		exit 198
	}
	local adaptive = ("`mzproj'" == "adaptive")
	local penalised = ("`mzproj'" != "ols")

	// penalty rule for the Delta-Y equation
	if ("`penalty'" == "") local penalty "plugin"
	local penalty = lower("`penalty'")
	local pennum = real("`penalty'")
	if (`pennum' >= .) {
		if !inlist("`penalty'", "plugin", "tscv", "min", "low", "mid", "medium", "1se", "high") {
			di as error "penalty() must be plugin, low, medium, high, tscv or a number"
			exit 198
		}
		local penval = .
	}
	else {
		local penval = `pennum'
		if (`penval' <= 0) {
			di as error "a numeric penalty() must be positive"
			exit 198
		}
	}

	// bootstrap scheme
	if ("`bscheme'" == "") local bscheme "system"
	local bscheme = lower("`bscheme'")
	if !inlist("`bscheme'", "system", "fixed") {
		di as error "bscheme() must be system or fixed"
		exit 198
	}

	local doboot = ("`bootstrap'" != "nobootstrap")
	if (`doboot' & `breps' < 1) {
		di as error "breps() must be positive"
		exit 198
	}
	local freeze = ("`freeze'" != "nofreeze")
	local st3c   = ("`st3cons'" != "")
	local usedl  = ("`dlags'" != "")

	// integrated controls must be a subset of controls()
	local integ ""
	foreach v of local integrated {
		local hit : list posof "`v'" in controls
		if (`hit' == 0) {
			di as error "integrated() variable {bf:`v'} is not in controls()"
			exit 198
		}
		local integ "`integ' `v'"
	}
	local integ = trim("`integ'")

	// the tested variables must not also be controls
	foreach v in `depvar' `focal' {
		local hit : list posof "`v'" in controls
		if (`hit' > 0) {
			di as error "{bf:`v'} appears both as a tested variable and in controls()"
			exit 198
		}
	}

	// ------------------------------------------------------------------
	// sample: contiguous time series required
	// ------------------------------------------------------------------
	capture qui tsset
	if (_rc) {
		di as error "data must be {help tsset:tsset} (a single time series)"
		exit 459
	}
	local tvar "`r(timevar)'"
	local pvar "`r(panelvar)'"
	if ("`pvar'" != "") {
		di as error "ardldml is a single-equation time-series command; the data are panel-tsset"
		exit 459
	}

	marksample touse
	markout `touse' `controls'

	qui count if `touse'
	local nraw = r(N)
	if (`nraw' < `lags' + 12) {
		di as error "too few observations (`nraw') for lags(`lags')"
		exit 2001
	}

	tempvar seq
	qui gen double `seq' = `tvar' if `touse'
	qui summarize `seq', meanonly
	local tmin = r(min)
	local tmax = r(max)
	qui count if `touse' & inrange(`tvar', `tmin', `tmax')
	if (r(N) != `tmax' - `tmin' + 1) {
		di as error "the estimation sample has gaps; ardldml needs a contiguous span"
		exit 198
	}

	// ------------------------------------------------------------------
	// engine
	// ------------------------------------------------------------------
	ardldml_mata

	tempname bmat Vmat draws foldm lamv
	if ("`seed'" != "") set seed `seed'

	mata: ardldml_main("`depvar'", "`focal'", "`controls'", "`integ'", "`touse'")

	if (scalar(__ardldml_ok) == 0) {
		di as error "the first stage exhausted its degrees of freedom; the statistic is not estimable"
		di as error "reduce controls(), raise blocks(), or lower buffer()"
		exit 498
	}

	// ------------------------------------------------------------------
	// post results
	// ------------------------------------------------------------------
	matrix `bmat' = __ardldml_b
	matrix `Vmat' = __ardldml_V
	local lnames "L.`depvar' L.`focal'"
	matrix colnames `bmat' = `lnames'
	matrix rownames `Vmat' = `lnames'
	matrix colnames `Vmat' = `lnames'

	ereturn post `bmat' `Vmat', depname(`depvar') obs(`=scalar(__ardldml_n)') esample(`touse')

	ereturn local cmd        "ardldml"
	ereturn local cmdline    "ardldml `0'"
	ereturn local title      "DML-Bounds test for a conditional long-run relationship"
	ereturn local depvar     "`depvar'"
	ereturn local focal      "`focal'"
	ereturn local controls   "`controls'"
	ereturn local integrated "`integ'"
	ereturn local tvar       "`tvar'"
	ereturn local mzproj     "`mzproj'"
	ereturn local penrule    "`penalty'"
	ereturn local properties "b V"
	ereturn local predict    "ardldml_p"
	ereturn local estat_cmd  "ardldml_estat"

	ereturn scalar N        = scalar(__ardldml_n)
	ereturn scalar N_raw    = `nraw'
	ereturn scalar F        = scalar(__ardldml_F)
	ereturn scalar df_rest  = 2
	ereturn scalar alpha    = scalar(__ardldml_alpha)
	ereturn scalar theta    = scalar(__ardldml_theta)
	ereturn scalar theta_se = scalar(__ardldml_theta_se)
	ereturn scalar lags     = `lags'
	ereturn scalar blocks   = `blocks'
	ereturn scalar buffer   = `buffer'
	ereturn scalar case     = `case'
	ereturn scalar cpen     = `cpen'
	ereturn scalar ltol     = `ltol'
	ereturn scalar k_ctrl   = scalar(__ardldml_dw)
	ereturn scalar k_int    = scalar(__ardldml_di)
	ereturn scalar nsel_dy  = scalar(__ardldml_nseldy)
	ereturn scalar nsel_z   = scalar(__ardldml_nselz)
	ereturn scalar lambda   = scalar(__ardldml_lam)
	ereturn scalar dlags    = `usedl'
	ereturn scalar st3cons  = `st3c'
	ereturn scalar level    = `level'

	ereturn local sel_dy "${__ardldml_seldy}"
	ereturn local sel_z  "${__ardldml_selz}"

	matrix `foldm' = __ardldml_folds
	matrix colnames `foldm' = eval_start eval_end n_eval n_train share_train
	ereturn matrix blocks_tab = `foldm'

	if (`doboot') {
		ereturn scalar B       = scalar(__ardldml_B)
		ereturn scalar crit    = scalar(__ardldml_crit)
		ereturn scalar p       = scalar(__ardldml_p)
		ereturn scalar n_fail  = scalar(__ardldml_nfail)
		ereturn scalar corr_ev = scalar(__ardldml_correv)
		ereturn scalar N_boot  = scalar(__ardldml_nboot)
		ereturn local bscheme  "`bscheme'"
		if ("`seed'" != "") ereturn local seed "`seed'"
		matrix `draws' = __ardldml_draws
		ereturn matrix draws = `draws'
	}

	capture scalar drop __ardldml_ok __ardldml_n __ardldml_F __ardldml_alpha	///
		__ardldml_theta __ardldml_theta_se __ardldml_dw __ardldml_di		///
		__ardldml_nseldy __ardldml_nselz __ardldml_lam __ardldml_B			///
		__ardldml_crit __ardldml_p __ardldml_nfail __ardldml_correv			///
		__ardldml_nboot
	capture matrix drop __ardldml_b __ardldml_V __ardldml_folds __ardldml_draws
	capture macro drop __ardldml_seldy __ardldml_selz

	// ------------------------------------------------------------------
	// display and graphs
	// ------------------------------------------------------------------
	_ardldml_display, level(`level') `header' `table' `legend' `showfirst'

	if ("`graph'" != "") {
		if ("`e(bscheme)'" == "") {
			di as text "(graph skipped: no bootstrap distribution to draw)"
		}
		else {
			_ardldml_nullgraph, name(`name') `graphopts'
		}
	}
	if ("`graphblocks'" != "") _ardldml_blockgraph, name(`name') `graphopts'
end


// ======================================================================
// display
// ======================================================================
program define _ardldml_display
	version 14.0
	syntax [, Level(cilevel) noHEADer noTABle noLEGend SHOWFirst]

	local dv "`e(depvar)'"
	local fv "`e(focal)'"
	local nb = e(blocks)
	local hb = e(buffer)

	if ("`header'" != "noheader") {
		di ""
		di as text "DML-Bounds test for a conditional long-run relationship"
		di as text "{hline 78}"
		di as text "D.`dv' - E[D.`dv'|X]" _col(30) "= orthogonalised outcome" ///
			_col(56) "Obs" _col(66) "= " as res %10.0f e(N)
		di as text "L.`dv' - E[L.`dv'|W]" _col(30) "= residualised level" ///
			_col(56) "Controls" _col(66) "= " as res %10.0f e(k_ctrl)
		di as text "L.`fv' - E[L.`fv'|W]" _col(30) "= residualised level" ///
			_col(56) "of which I(1)" _col(66) "= " as res %10.0f e(k_int)
		di as text "{hline 78}"
		di as text "H0: no level relationship after residualisation " ///
			"(pi_y = pi_x = 0)"
		di as text "short-run lags" _col(22) "= " as res %6.0f e(lags) ///
			as text _col(38) "h-block K" _col(52) "= " as res %6.0f `nb'
		di as text "deterministic case" _col(22) "= " as res %6.0f e(case) ///
			as text _col(38) "buffer h" _col(52) "= " as res %6.0f `hb'
		di as text "m_Z projection" _col(22) "= " as res %6s abbrev("`e(mzproj)'",6) ///
			as text _col(38) "penalty rule" _col(52) "= " as res %6s abbrev("`e(penrule)'",6)
	}

	if ("`table'" != "notable") {
		di ""
		di as text "{hline 13}{c TT}{hline 64}"
		di as text %12s "statistic" " {c |}" _col(20) "value" _col(34) ///
			"reference" _col(50) "p-value" _col(64) "decision"
		di as text "{hline 13}{c +}{hline 64}"

		local F = e(F)
		if (e(B) < .) {
			local cv = e(crit)
			local pv = e(p)
			local dec "fail to reject"
			if (`pv' < (100-`level')/100) local dec "reject"
			local dec "`dec'"
			di as text %12s "DML-Bounds F" " {c |}" as res _col(18) %9.4f `F' ///
				_col(32) %9.4f `cv' _col(48) %9.4f `pv' _col(60) as res %14s "`dec'"
			di as text %12s "" " {c |}" as text _col(28) ///
				"bootstrap `level'% cv"
		}
		else {
			di as text %12s "DML-Bounds F" " {c |}" as res _col(18) %9.4f `F' ///
				as text _col(32) "  no bootstrap run -- statistic has no reference"
		}
		di as text "{hline 13}{c +}{hline 64}"

		local a  = e(alpha)
		local th = e(theta)
		local se = e(theta_se)
		local z  = .
		local p  = .
		if (`se' > 0 & `se' < .) {
			local z = `th'/`se'
			local p = 2*normal(-abs(`z'))
		}
		local zc = invnormal(1 - (100-`level')/200)
		local lo = `th' - `zc'*`se'
		local hi = `th' + `zc'*`se'
		local st ""
		if (`p' < .10) local st "*"
		if (`p' < .05) local st "**"
		if (`p' < .01) local st "***"

		di as text %12s "alpha" " {c |}" as res _col(18) %9.4f `a' ///
			as text _col(32) "speed of adjustment (= -pi_y)"
		di as text %12s "theta" " {c |}" as res _col(18) %9.4f `th' ///
			as text _col(30) "se" as res _col(34) %9.4f `se' ///
			as text _col(46) "z" as res _col(50) %8.3f `z' as res "`st'"
		di as text %12s "" " {c |}" as text _col(18) "`level'% CI" ///
			as res _col(32) %9.4f `lo' as text _col(43) "," as res _col(45) %9.4f `hi'
		di as text "{hline 13}{c BT}{hline 64}"
	}

	if ("`showfirst'" != "") {
		di ""
		di as text "First stage (h-block cross-fitted, post-LASSO refit)"
		di as text "  selected in the D.`dv' projection : " as res e(nsel_dy) ///
			as text " of " as res %1.0f (e(k_ctrl) + e(lags) + 1 + e(dlags)*e(lags))
		if ("`e(sel_dy)'" != "") di as text "    " as res "`e(sel_dy)'"
		di as text "  selected in the m_Z projection    : " as res e(nsel_z) ///
			as text " of " as res %1.0f e(k_ctrl) as text " control levels"
		if ("`e(sel_z)'" != "") di as text "    " as res "`e(sel_z)'"
		di as text "  plug-in penalty (D.`dv' equation)  : " as res %9.6f e(lambda)
	}

	if ("`legend'" != "nolegend") {
		di ""
		if (e(B) < .) {
			di as text "Inference: restricted system wild bootstrap (Villena 2026, Algorithm 1)," ///
				_n "  B = " as res e(B) as text " draws, " as res "`e(bscheme)'" ///
				as text " scheme, corr(eps,v) = " as res %6.3f e(corr_ev) as text "."
			if (e(n_fail) > 0) di as text "  " as res e(n_fail) as text " draw(s) failed and were dropped."
			di as text "  Do NOT compare F with the tabulated 4.94/5.73 bounds: with an integrated"
			di as text "  control set that comparison over-rejects (paper, Section 6)."
		}
		else {
			di as text "No bootstrap critical value. The statistic has no tabulated reference:"
			di as text "  re-run without {bf:nobootstrap} before interpreting it."
		}
		di as text "  Estimand is conditional on controls(); run {bf:estat absorption} to check"
		di as text "  that the control set is not absorbing the tested relation itself."
		di as text "  * p<.10, ** p<.05, *** p<.01 (theta, delta method)."
	}
end


// ======================================================================
// graphs live in _ardldml_nullgraph.ado and _ardldml_blockgraph.ado, so
// that ardldml_estat.ado can call them too
// ======================================================================
