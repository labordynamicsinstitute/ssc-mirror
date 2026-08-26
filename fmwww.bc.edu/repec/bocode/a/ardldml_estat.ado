*! ardldml_estat 1.0.0  24aug2026
*! postestimation for ardldml -- DML-Bounds
*! Dr Merwan Roudane -- merwanroudane920@gmail.com
*! https://github.com/merwanroudane

program define ardldml_estat, rclass
	version 14.0

	if ("`e(cmd)'" != "ardldml") {
		di as error "last estimates not found; {bf:ardldml} must be run first"
		exit 301
	}

	gettoken sub 0 : 0, parse(" ,")
	local sub = lower("`sub'")

	if ("`sub'" == "") {
		di as error "estat subcommand required"
		di as error "  {bf:absorption} {bf:penalty} {bf:classical} {bf:blocks} {bf:null}"
		exit 198
	}

	if (substr("absorption", 1, max(6, length("`sub'"))) == "`sub'") {
		_ardldml_absorb `0'
	}
	else if (substr("penalty", 1, max(3, length("`sub'"))) == "`sub'") {
		_ardldml_penalty `0'
	}
	else if (substr("classical", 1, max(5, length("`sub'"))) == "`sub'") {
		_ardldml_classical `0'
	}
	else if (substr("blocks", 1, max(3, length("`sub'"))) == "`sub'") {
		_ardldml_blocks `0'
	}
	else if (substr("null", 1, max(4, length("`sub'"))) == "`sub'") {
		_ardldml_null `0'
	}
	else {
		di as error "unknown estat subcommand {bf:`sub'}"
		di as error "  choose from {bf:absorption} {bf:penalty} {bf:classical} {bf:blocks} {bf:null}"
		exit 198
	}
	return add
end


// ======================================================================
// pull the fitted specification back out of e()
// ======================================================================
program define _ardldml_spec, rclass
	version 14.0
	return local depvar   "`e(depvar)'"
	return local focal    "`e(focal)'"
	return local controls "`e(controls)'"
	return local integ    "`e(integrated)'"
	return local mzproj   "`e(mzproj)'"
	return local penrule  "`e(penrule)'"
	return local bscheme  "`e(bscheme)'"
	local core "lags(`e(lags)') blocks(`e(blocks)') buffer(`e(buffer)')"
	local core "`core' case(`e(case)') cpen(`e(cpen)') ltol(`e(ltol)')"
	if (e(dlags) == 1)   local core "`core' dlags"
	if (e(st3cons) == 1) local core "`core' st3cons"
	return local core "`core'"
	return scalar level = e(level)
	return scalar B     = e(B)
end


// ======================================================================
// estat absorption -- the trend-absorption diagnostic (Definition 2)
// ======================================================================
program define _ardldml_absorb, rclass
	version 14.0
	syntax [, DROP(varlist numeric) Breps(integer -1) SEED(string) ///
		Level(cilevel) MZALT(string) noTABle ]

	qui _ardldml_spec
	local dv    "`r(depvar)'"
	local fv    "`r(focal)'"
	local ctrl  "`r(controls)'"
	local integ "`r(integ)'"
	local core  "`r(core)'"
	local bsch  "`r(bscheme)'"
	if (`breps' < 0) local breps = r(B)
	if (`breps' < 1 | `breps' >= .) local breps = 999
	if ("`bsch'" != "") local bsch "bscheme(`bsch')"

	// The Delta_m arm. Definition 2 words it as "the unpenalized m_Z
	// projection", but Section 4.1 motivates the contrast as adaptive
	// versus *vanilla l1* -- "vanilla l1 over-selects integrated
	// regressors and thereby induces spurious trend absorption, whereas
	// adaptive penalization curbs it" -- and the reference implementation
	// takes the second reading. plain is therefore the default; mzalt(ols)
	// gives Definition 2's literal wording.
	if ("`mzalt'" == "") local mzalt "plain"
	local mzalt = lower("`mzalt'")
	if !inlist("`mzalt'", "plain", "ols") {
		di as error "mzalt() must be plain or ols"
		exit 198
	}

	if ("`drop'" == "") {
		di as error "drop() is required: name the controls most likely to be"
		di as error "cointegrated with the tested relation itself"
		exit 198
	}
	foreach v of local drop {
		local hit : list posof "`v'" in ctrl
		if (`hit' == 0) {
			di as error "drop() variable {bf:`v'} is not among the controls"
			exit 198
		}
	}

	local ctrl_r : list ctrl - drop
	local integ_r : list integ - drop
	local nfull : list sizeof ctrl
	local nred  : list sizeof ctrl_r

	tempname _h
	capture _estimates hold `_h', restore nullok

	tempname R
	matrix `R' = J(4, 8, .)

	local row = 0
	foreach arm in "full adaptive" "full `mzalt'" "reduced adaptive" "reduced `mzalt'" {
		local ++row
		local wset : word 1 of `arm'
		local proj : word 2 of `arm'
		local cc "`ctrl'"
		local ii "`integ'"
		local nn = `nfull'
		if ("`wset'" == "reduced") {
			local cc "`ctrl_r'"
			local ii "`integ_r'"
			local nn = `nred'
		}
		local sd ""
		if ("`seed'" != "") local sd "seed(`=`seed' + 10000*(`row'-1)')"

		capture noisily qui ardldml `dv' `fv', controls(`cc') ///
			integrated(`ii') `core' mzproj(`proj') breps(`breps') ///
			level(`level') `sd' `bsch'
		if (_rc) {
			di as error "the `wset'/`proj' fit failed (rc = `_rc')"
			exit _rc
		}
		matrix `R'[`row', 1] = `nn'
		matrix `R'[`row', 2] = e(nsel_z)
		matrix `R'[`row', 3] = e(F)
		matrix `R'[`row', 4] = e(crit)
		matrix `R'[`row', 5] = e(p)
		matrix `R'[`row', 6] = e(alpha)
		matrix `R'[`row', 7] = e(theta)
		matrix `R'[`row', 8] = e(theta_se)
	}

	local a = (100 - `level')/100
	local dm = `R'[2,5] - `R'[1,5]
	local dW = `R'[1,5] - `R'[3,5]

	local tmin = .
	local tmax = .
	forvalues i = 1/4 {
		local t = `R'[`i',7]
		if (`t' < .) {
			if (`t' < `tmin' | `tmin' >= .) local tmin = `t'
			if (`t' > `tmax' | `tmax' >= .) local tmax = `t'
		}
	}
	local tspread = `tmax' - `tmin'

	if ("`table'" != "notable") {
		di ""
		di as text "Trend-absorption diagnostic (Villena 2026, Definition 2)"
		di as text "dropped from the reduced set: " as res "`drop'"
		di as text "{hline 86}"
		di as text %-9s "controls" %-10s "m_Z proj" %5s "k_W" %6s "selZ" ///
			%9s "F" %10s "boot cv" %9s "boot p" %17s "verdict"
		di as text "{hline 86}"
		local rn 1
		foreach arm in "full adaptive" "full `mzalt'" "reduced adaptive" "reduced `mzalt'" {
			local wset : word 1 of `arm'
			local proj : word 2 of `arm'
			local pv = `R'[`rn',5]
			local vd "fail to reject"
			if (`pv' < `a') local vd "reject"
			di as text %-9s "`wset'" %-10s "`proj'" ///
				as res %5.0f `R'[`rn',1] %6.0f `R'[`rn',2] ///
				%9.4f `R'[`rn',3] %10.4f `R'[`rn',4] %9.4f `pv' ///
				%17s "`vd'"
			local ++rn
		}
		di as text "{hline 86}"
		di as text %-19s "long run" %9s "alpha" %10s "theta" %10s "se(theta)"
		di as text "{hline 86}"
		local rn 1
		foreach arm in "full adaptive" "full `mzalt'" "reduced adaptive" "reduced `mzalt'" {
			local wset : word 1 of `arm'
			local proj : word 2 of `arm'
			di as text %-9s "`wset'" %-10s "`proj'" ///
				as res %9.4f `R'[`rn',6] %10.4f `R'[`rn',7] %10.4f `R'[`rn',8]
			local ++rn
		}
		di as text "{hline 86}"
		di as text "Delta_m = p_`mzalt' - p_adaptive  = " as res %8.4f `dm'
		di as text "Delta_W = p_full  - p_reduced   = " as res %8.4f `dW'
		di as text "theta spread across the four fits = " as res %8.4f `tspread'
		di as text "{hline 86}"

		// Remark 9, read conservatively
		local pfull = `R'[1,5]
		local pred  = `R'[3,5]
		local sefull = `R'[1,8]
		local sered  = `R'[3,8]
		local rr = (`pred' < `a')
		local rf = (`pfull' < `a')
		di ""
		if (`rr' & !`rf' & `dW' > 0) {
			di as text "Possible over-absorption. The reduced set rejects (p = " ///
				as res %5.3f `pred' as text ") where the full set"
			di as text "does not (p = " as res %5.3f `pfull' as text "); Delta_W = " ///
				as res %+6.3f `dW' as text "."
			if (`sered' < `sefull') {
				di as text "The long-run coefficient is also more sharply estimated under the reduced"
				di as text "set (se " as res %5.3f `sered' as text " vs " as res %5.3f `sefull' ///
					as text "), which strengthens the reading. The reduced-set"
				di as text "verdict is the more credible one."
			}
			else {
				di as text "The long-run coefficient is not more sharply estimated under the reduced"
				di as text "set, so ordinary specification sensitivity cannot be ruled out."
			}
		}
		else if (`rr' == `rf') {
			di as text "Concordant verdicts across control sets (full p = " as res %5.3f `pfull' ///
				as text ", reduced p = " as res %5.3f `pred' as text ")."
			di as text "The conclusion does not appear to be an artefact of over-absorption."
		}
		else {
			di as text "Discordant, but not in the over-absorption direction (full p = " ///
				as res %5.3f `pfull' as text ", reduced"
			di as text "p = " as res %5.3f `pred' as text "). Treat both verdicts as fragile."
		}
		di ""
		di as text "This is a hypothesis-generating device, not a formal test: it has no size"
		di as text "and no power. It tells you where to look."
	}

	matrix colnames `R' = k_controls n_selected_Z F boot_cv boot_p alpha theta se_theta
	matrix rownames `R' = full_adaptive full_`mzalt' reduced_adaptive reduced_`mzalt'

	return matrix table = `R'
	return scalar delta_m = `dm'
	return scalar delta_W = `dW'
	return scalar theta_spread = `tspread'
	return local dropped "`drop'"
	return local mzalt "`mzalt'"
end


// ======================================================================
// estat penalty -- the Section 7.5 robustness grid
// ======================================================================
program define _ardldml_penalty, rclass
	version 14.0
	syntax [, RULES(string) PROJections(string) LAGSgrid(numlist integer >0) ///
		Breps(integer 0) SEED(string) ]

	qui _ardldml_spec
	local dv    "`r(depvar)'"
	local fv    "`r(focal)'"
	local ctrl  "`r(controls)'"
	local integ "`r(integ)'"
	local core  "`r(core)'"

	if ("`rules'" == "") local rules "low medium high"
	if ("`projections'" == "") local projections "adaptive plain ols"
	if ("`lagsgrid'" == "") local lagsgrid = e(lags)

	// strip lags() out of core: the sweep sets it
	local core2 ""
	foreach tok of local core {
		if (substr("`tok'", 1, 5) != "lags(") local core2 "`core2' `tok'"
	}

	local sd ""
	if ("`seed'" != "") local sd "seed(`seed')"
	local bo "nobootstrap"
	if (`breps' > 0) local bo "breps(`breps') `sd'"

	tempname _h
	capture _estimates hold `_h', restore nullok

	tempname R
	local nr = 0
	foreach L of numlist `lagsgrid' {
		foreach pj of local projections {
			foreach pn of local rules {
				local ++nr
				if ("`pj'" == "ols") continue, break
			}
			if ("`pj'" == "ols") local ++nr
		}
	}
	matrix `R' = J(`nr', 7, .)

	di ""
	di as text "Penalty and projection sweep (Villena 2026, Section 7.5)"
	di as text "{hline 80}"
	di as text %5s "lags" %10s "m_Z proj" %9s "penalty" %6s "selZ" %10s "F" ///
		%10s "alpha" %10s "theta" %10s "se"
	di as text "{hline 80}"

	local row = 0
	foreach L of numlist `lagsgrid' {
		foreach pj of local projections {
			local rl "`rules'"
			if ("`pj'" == "ols") local rl "-"
			foreach pn of local rl {
				local ++row
				local popt "penalty(`pn')"
				if ("`pn'" == "-") local popt ""
				capture qui ardldml `dv' `fv', controls(`ctrl') ///
					integrated(`integ') lags(`L') `core2' ///
					mzproj(`pj') `popt' `bo'
				if (_rc) {
					di as text %5.0f `L' %10s "`pj'" %9s "`pn'" ///
						as error "   not estimable (rc = `_rc')"
					continue
				}
				matrix `R'[`row', 1] = `L'
				matrix `R'[`row', 2] = e(nsel_z)
				matrix `R'[`row', 3] = e(F)
				matrix `R'[`row', 4] = e(alpha)
				matrix `R'[`row', 5] = e(theta)
				matrix `R'[`row', 6] = e(theta_se)
				matrix `R'[`row', 7] = e(p)
				di as text %5.0f `L' %10s "`pj'" %9s "`pn'" ///
					as res %6.0f e(nsel_z) %10.4f e(F) %10.4f e(alpha) ///
					%10.4f e(theta) %10.4f e(theta_se)
			}
		}
	}
	di as text "{hline 80}"

	// sign stability of the long-run coefficient across the grid
	local tmin = .
	local tmax = .
	forvalues i = 1/`row' {
		local t = `R'[`i',5]
		if (`t' < .) {
			if (`t' < `tmin' | `tmin' >= .) local tmin = `t'
			if (`t' > `tmax' | `tmax' >= .) local tmax = `t'
		}
	}
	local flip = (`tmin' < 0 & `tmax' > 0)
	di as text "n selected Z is the empirical counterpart of the effective integrated"
	di as text "count: 0 means nothing was absorbed, a large value means heavy absorption."
	if (`flip') {
		di ""
		di as error "WARNING: theta changes sign across this grid (" ///
			%6.3f `tmin' " to " %6.3f `tmax' ")."
		di as error "The conditioning set, not the data, may be driving the answer."
	}

	matrix colnames `R' = lags n_selected_Z F alpha theta se_theta boot_p
	return matrix table = `R'
	return scalar theta_min = `tmin'
	return scalar theta_max = `tmax'
	return scalar sign_flip = `flip'
end


// ======================================================================
// estat classical -- the Pesaran-Shin-Smith benchmark
// ======================================================================
program define _ardldml_classical, rclass
	version 14.0
	syntax [, ORDer(integer 1) NSIM(integer 20000) SEED(string) ///
		Levels(numlist >0 <1) ]

	qui _ardldml_spec
	local dv "`r(depvar)'"
	local fv "`r(focal)'"
	local lags = e(lags)
	local case = e(case)

	if ("`levels'" == "") local levels "0.10 0.05 0.01"

	tempvar touse
	qui gen byte `touse' = e(sample)

	tempname pre
	mata: ardldml_classical("`dv'", "`fv'", "`touse'", `lags', `order', ///
		`case', "__ardldml_c_")

	if (scalar(__ardldml_c_ok) == 0) {
		di as error "the classical conditional ECM has no residual degrees of freedom"
		exit 498
	}

	local cF  = scalar(__ardldml_c_F)
	local ct  = scalar(__ardldml_c_t)
	local cN  = scalar(__ardldml_c_N)
	local ck  = scalar(__ardldml_c_k)
	local cnr = scalar(__ardldml_c_nrest)
	local ca  = scalar(__ardldml_c_alpha)
	local cw  = scalar(__ardldml_c_wald)
	local cwp = scalar(__ardldml_c_waldp)
	tempname th sth
	matrix `th'  = __ardldml_c_theta
	matrix `sth' = __ardldml_c_setheta

	// the bracket, simulated at THIS sample size rather than read from a
	// table calibrated at T = 1000
	local nlev : word count `levels'
	tempname LV BD
	matrix `LV' = J(`nlev', 1, .)
	local i = 0
	foreach l of local levels {
		local ++i
		matrix `LV'[`i', 1] = `l'
	}
	if ("`seed'" != "") set seed `seed'
	mata: ardldml_pss("__ardldml_bd", `ck', `case', `cN', `nsim', ///
		st_matrix("`LV'"))
	matrix `BD' = __ardldml_bd

	di ""
	di as text "Classical bounds test (Pesaran, Shin and Smith 2001)"
	di as text "{hline 76}"
	di as text "H0: no level relationship" _col(38) "Obs" _col(54) "= " as res %8.0f `cN'
	di as text "case " as res `case' as text ", " as res `lags' as text " short-run lag(s)" ///
		_col(38) "k (forcing)" _col(54) "= " as res %8.0f `ck'
	di as text "level terms tested: " as res `cnr' _col(38) "restrictions" _col(54) "= " ///
		as res %8.0f `cnr'
	di as text "{hline 76}"
	di as text %10s "statistic" %12s "value" _col(30) "simulated bracket at T = " as res `cN'
	di as text %10s "" %12s "" %9s "level" %12s "I(0) lower" %12s "I(1) upper" %17s "verdict"
	di as text "{hline 76}"
	forvalues i = 1/`nlev' {
		local lv = `BD'[`i',1]
		local lo = `BD'[`i',2]
		local hi = `BD'[`i',3]
		local vd "fail to reject"
		if (`cF' > `lo') local vd "inconclusive"
		if (`cF' > `hi') local vd "reject"
		local lab ""
		if (`i' == 1) local lab "F"
		local fv2 = .
		if (`i' == 1) local fv2 = `cF'
		if (`i' == 1) {
			di as text %10s "`lab'" as res %12.4f `cF' ///
				as res %9.3f `lv' %12.3f `lo' %12.3f `hi' %17s "`vd'"
		}
		else {
			di as text %10s "" %12s "" ///
				as res %9.3f `lv' %12.3f `lo' %12.3f `hi' %17s "`vd'"
		}
	}
	di as text "{hline 76}"
	di as text %10s "t" as res %12.4f `ct' as text ///
		"   on the speed of adjustment (step 2)"
	di as text %10s "Wald" as res %12.4f `cw' as text ///
		"   theta = 0, chi2(" as res `ck' as text ") p = " as res %6.4f `cwp' ///
		as text " (step 3)"
	di as text %10s "alpha" as res %12.4f `ca' as text "   speed of adjustment"
	di as text %10s "theta" as res %12.4f `th'[1,1] as text "   se " ///
		as res %8.4f `sth'[1,1] as text "  long-run coefficient"
	di as text "{hline 76}"
	di as text "Bracket simulated from the Pesaran-Shin-Smith Table CI design at this"
	di as text "sample size, " as res `nsim' as text " replications -- not read from a T = 1000 table."
	di ""
	di as text "Rejecting the joint F alone is not evidence of a level relationship: two"
	di as text "degenerate cases survive it, which is why the t and Wald steps are shown."
	di as text "Compare with the DML-Bounds result: this benchmark conditions on nothing."

	matrix colnames `BD' = level I0_lower I1_upper
	return matrix bounds = `BD'
	return matrix theta = `th'
	return scalar F = `cF'
	return scalar t = `ct'
	return scalar wald = `cw'
	return scalar wald_p = `cwp'
	return scalar alpha = `ca'
	return scalar N = `cN'
	return scalar k = `ck'

	capture scalar drop __ardldml_c_ok __ardldml_c_F __ardldml_c_t __ardldml_c_N ///
		__ardldml_c_k __ardldml_c_nrest __ardldml_c_alpha __ardldml_c_wald ///
		__ardldml_c_waldp
	capture matrix drop __ardldml_c_theta __ardldml_c_setheta __ardldml_bd
end


// ======================================================================
// estat blocks -- the h-block cross-fitting structure
// ======================================================================
program define _ardldml_blocks, rclass
	version 14.0
	syntax [, GRAPH NAME(string) * ]

	tempname F
	matrix `F' = e(blocks_tab)
	local K = rowsof(`F')

	di ""
	di as text "h-block cross-fitting structure (Villena 2026, Section 4.1)"
	di as text "K = " as res `=e(blocks)' as text " blocks, buffer h = " ///
		as res `=e(buffer)' as text ", n = " as res `=e(N)'
	di as text "{hline 66}"
	di as text %7s "block" %13s "eval start" %11s "eval end" %9s "n eval" ///
		%11s "n train" %15s "train share"
	di as text "{hline 66}"
	forvalues i = 1/`K' {
		di as res %7.0f `i' %13.0f `F'[`i',1] %11.0f `F'[`i',2] ///
			%9.0f `F'[`i',3] %11.0f `F'[`i',4] %15.3f `F'[`i',5]
	}
	di as text "{hline 66}"
	local tot = 0
	forvalues i = 1/`K' {
		local tot = `tot' + `F'[`i',5]
	}
	di as text "mean training share = " as res %5.3f `=`tot'/`K'' as text ///
		"   (1 - 1/K = " as res %5.3f `=1-1/`K'' as text " with no buffer)"
	di as text "Each evaluation block is predicted from a model fitted on the other"
	di as text "blocks minus an h-observation buffer either side, which is what"
	di as text "decouples the first-stage error from the evaluation innovations."

	// build the graph BEFORE returning the matrix (returning moves it)
	if ("`graph'" != "") _ardldml_blockgraph, name(`name') `options'

	return matrix table = `F'
end


// ======================================================================
// estat null -- the bootstrap null distribution
// ======================================================================
program define _ardldml_null, rclass
	version 14.0
	syntax [, NAME(string) noGRaph * ]

	if (e(B) >= .) {
		di as error "no bootstrap distribution stored; re-run {bf:ardldml} without {bf:nobootstrap}"
		exit 301
	}

	tempname D
	matrix `D' = e(draws)
	local B = rowsof(`D')

	tempname q
	di ""
	di as text "Bootstrap null distribution (restricted system wild bootstrap)"
	di as text "B = " as res `B' as text " usable draws, " as res "`e(bscheme)'" ///
		as text " scheme"
	di as text "{hline 56}"
	preserve
	quietly {
		clear
		svmat double `D', name(fstar)
		summarize fstar1, detail
		local p50 = r(p50)
		local p90 = r(p90)
		local p95 = r(p95)
		local p99 = r(p99)
		local mn  = r(mean)
		local sd  = r(sd)
	}
	restore
	di as text %-28s "observed F" as res %10.4f e(F)
	di as text %-28s "bootstrap mean" as res %10.4f `mn'
	di as text %-28s "bootstrap sd" as res %10.4f `sd'
	di as text %-28s "median" as res %10.4f `p50'
	di as text %-28s "90th percentile" as res %10.4f `p90'
	di as text %-28s "95th percentile" as res %10.4f `p95'
	di as text %-28s "99th percentile" as res %10.4f `p99'
	di as text %-28s "critical value (`=e(level)'%)" as res %10.4f e(crit)
	di as text %-28s "bootstrap p-value" as res %10.4f e(p)
	di as text "{hline 56}"
	di as text "For reference only, the classical tabulated bounds for k = 1, case 3"
	di as text "are 4.94 (I(0)) and 5.73 (I(1)). Do not test against them here: with"
	di as text "an integrated control set that comparison over-rejects badly."

	if ("`graph'" != "nograph") _ardldml_nullgraph, name(`name') `options'

	return scalar p50 = `p50'
	return scalar p95 = `p95'
	return scalar crit = e(crit)
	return scalar p = e(p)
end
