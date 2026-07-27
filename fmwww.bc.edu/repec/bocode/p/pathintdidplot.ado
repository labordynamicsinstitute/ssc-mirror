*! pathintdidplot.ado - Graph the causal impact of a Path-Integrated DiD analysis
*! Companion plotting command to pathintdid.ado
*! Draws (1) the treated vs. counterfactual paths with the cumulative
*! effect shaded, and (2) the running cumulative effect sigma(t), which
*! plateaus even after tau(t) has decayed back to zero -- the visual
*! signature of the endpoint-subtraction bias in Salavi (2026) -- with
*! a shaded 95% confidence band around the final plateau, pulled from
*! pathintdid's standard error (Theorem 2 of the companion paper).
*! Formerly distributed as -pididplot- (renamed alongside pathintdid
*! at the request of the Stata Journal editors, 13jul2026).
*! version 2.0.0   14jul2026

program define pathintdidplot
	version 14.0

	syntax varname(numeric) [if] [in], PANELvar(varname) TIMEvar(varname) ///
		TREATvar(varname) T0(real) [T1(real -999) T2(real -999) ///
		LEVEL(cilevel) NOSE ///
		XTITLE(string) TITLE(string) SUBTITLE(string) NAME(string) ///
		SAVING(string) SCHEME(string)]

	marksample touse
	markout `touse' `panelvar' `timevar' `treatvar'

	quietly count if `touse'
	if r(N) == 0 {
		display as error "no observations satisfy the estimation sample"
		exit 2000
	}

	local depvar `varlist'

	tempvar tchk
	quietly generate `tchk' = `treatvar' if `touse'
	quietly summarize `tchk'
	if r(min) != 0 | r(max) != 1 {
		display as error "treatvar() must be coded 0 (control) and 1 (treated)"
		exit 198
	}

	*----------------------------------------------------------------
	* 0. Pull sigma and its standard error from pathintdid, on exactly
	*    the same estimation sample and window, so the two commands
	*    never disagree with one another.
	*----------------------------------------------------------------
	local have_se = 0
	if "`nose'" == "" {
		local seopts
		if `t1' != -999 local seopts "`seopts' t1(`t1')"
		capture noisily quietly pathintdid `depvar' if `touse', ///
			panelvar(`panelvar') timevar(`timevar') treatvar(`treatvar') ///
			t0(`t0') `seopts' level(`level') notable
		if !_rc {
			capture local se_sigma = r(se_sigma)
			if !_rc {
				local ci_lb   = r(ci_sigma_lb)
				local ci_ub   = r(ci_sigma_ub)
				local have_se = 1
			}
		}
	}

	preserve
	quietly keep if `touse'

	*----------------------------------------------------------------
	* 1. Collapse to c0(t) and c1(t)
	*----------------------------------------------------------------
	quietly collapse (mean) `depvar', by(`treatvar' `timevar')
	quietly reshape wide `depvar', i(`timevar') j(`treatvar')

	capture confirm variable `depvar'0
	if _rc {
		display as error "no control observations (treatvar==0) found"
		restore
		exit 2000
	}
	capture confirm variable `depvar'1
	if _rc {
		display as error "no treated observations (treatvar==1) found"
		restore
		exit 2000
	}
	rename `depvar'0 __c0__
	rename `depvar'1 __c1__
	quietly sort `timevar'

	quietly summarize `timevar'
	local tmin = r(min)
	local tmax = r(max)
	if `t1' == -999 local t1 = `tmax'

	if `t0' < `tmin' | `t0' > `tmax' {
		display as error "t0(`t0') falls outside the observed time range [`tmin', `tmax']"
		restore
		exit 198
	}
	if `t1' <= `t0' {
		display as error "t1() must be strictly greater than t0()"
		restore
		exit 198
	}
	capture assert `t2' == -999
	if _rc {
		if `t2' <= `t0' | `t2' > `t1' {
			display as error "t2() must lie strictly between t0() and t1()"
			restore
			exit 198
		}
	}

	quietly generate double __tau__  = __c1__ - __c0__
	quietly count if `timevar' == `t0'
	if r(N) == 0 {
		display as error "t0(`t0') is not an observed value of `timevar'"
		restore
		exit 198
	}
	quietly summarize __tau__ if `timevar' == `t0', meanonly
	local tau_t0 = r(mean)
	quietly generate double __taud__ = __tau__ - `tau_t0'

	*----------------------------------------------------------------
	* 2. Running (partial-sum) cumulative effect: sigma(t) for t>=t0,
	*    via the trapezoidal rule on the baseline-differenced gap;
	*    undefined/blank before t0
	*----------------------------------------------------------------
	quietly generate double __cumsigma__ = .
	quietly count
	local N = _N
	tempname run
	scalar `run' = 0
	forvalues i = 1/`N' {
		local ti = `timevar'[`i']
		if `ti' == `t0' {
			scalar `run' = 0
			quietly replace __cumsigma__ = 0 in `i'
		}
		else if `ti' > `t0' {
			local im1    = `i' - 1
			local tprev  = `timevar'[`im1']
			local taucur = __taud__[`i']
			local tauprv = __taud__[`im1']
			scalar `run' = `run' + 0.5*(`taucur' + `tauprv')*(`ti' - `tprev')
			quietly replace __cumsigma__ = `run' in `i'
		}
	}

	quietly summarize __cumsigma__ if `timevar' == `t1', meanonly
	local sigma_final = r(mean)
	quietly summarize __taud__ if `timevar' == `t1', meanonly
	local did_static = r(mean)

	*----------------------------------------------------------------
	* 3. Build the two panels
	*----------------------------------------------------------------
	local gxtitle "Time"
	if `"`xtitle'"' != "" local gxtitle `"`xtitle'"'

	local gtitle "PI-DiD causal impact"
	if `"`title'"' != "" local gtitle `"`title'"'

	local xln "`t0' `t1'"
	if `t2' != -999 local xln "`t0' `t2' `t1'"

	* default to the Stata Journal-recommended "sj" scheme, which is
	* designed to remain legible when printed in grayscale
	if `"`scheme'"' == "" local scheme sj

	tempname pathgraph cumgraph

	twoway ///
		(rarea __c1__ __c0__ `timevar' if `timevar' >= `t0' & `timevar' <= `t1', ///
			color(gs12%60)) ///
		(line __c0__ `timevar', lpattern(dash) lcolor(navy) lwidth(medthick)) ///
		(line __c1__ `timevar', lcolor(cranberry) lwidth(medthick)) ///
		, ///
		xline(`xln', lpattern(shortdash) lcolor(gs8)) ///
		legend(order(2 "Counterfactual c0(t)" 3 "Treated c1(t)" ///
			1 "Area = {&sigma}") pos(6) rows(1) size(small)) ///
		xtitle(`"`gxtitle'"') ytitle("`depvar'") ///
		title("Realized vs. counterfactual path", size(medium)) ///
		scheme(`scheme') name(`pathgraph', replace)

	local cumylines "yline(0, lcolor(gs8)) yline(`sigma_final', lpattern(shortdash) lcolor(cranberry))"
	local cumnote_base = "Path-integrated ATT ({&tau}-bar) = " + strofreal(`sigma_final'/(`t1'-`t0'), "%9.2f") + ///
		"    Static endpoint DiD = " + strofreal(`did_static', "%9.2f")
	if `have_se' {
		local cumylines "`cumylines' yline(`ci_lb' `ci_ub', lpattern(shortdash) lcolor(cranberry%40))"
		local cumnote_base = "`cumnote_base'" + "    (`level'% CI for sigma shaded)"
	}
	local cumnote `"`cumnote_base'"'

	twoway ///
		(line __cumsigma__ `timevar' if `timevar' >= `t0' & `timevar' <= `t1', ///
			lcolor(cranberry) lwidth(medthick) msymbol(O) mcolor(cranberry) recast(connected)) ///
		, ///
		`cumylines' ///
		xline(`xln', lpattern(shortdash) lcolor(gs8)) ///
		xtitle(`"`gxtitle'"') ytitle("Cumulative effect {&sigma}(t)") ///
		title("Path-integrated cumulative impact", size(medium)) ///
		note(`cumnote', size(vsmall)) ///
		scheme(`scheme') name(`cumgraph', replace)

	local combopts
	if `"`subtitle'"' != "" local combopts `"`combopts' subtitle(`"`subtitle'"')"'
	local nameopt
	if `"`name'"' != "" local nameopt "name(`name', replace)"
	local saveopt
	if `"`saving'"' != "" local saveopt "saving(`saving', replace)"

	graph combine `pathgraph' `cumgraph', ///
		rows(2) title(`"`gtitle'"') `combopts' `nameopt' `saveopt' scheme(`scheme')

	restore

	display as text ""
	display as text "Graph drawn. Cumulative effect at t1 (sigma) = " as result %9.3f `sigma_final'
	if `have_se' {
		display as text "  Std. Err. = " as result %9.3f `se_sigma' ///
			as text "   `level'% CI = [" as result %9.3f `ci_lb' as text ", " as result %9.3f `ci_ub' as text "]"
	}
	display as text "Static endpoint DiD                          = " as result %9.3f `did_static'

end
