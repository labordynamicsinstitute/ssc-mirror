*! pidid.ado - Path-Integrated Difference-in-Differences (PI-DiD)
*! Implements the framework of Salavi (2026),
*! "Path-Integrated Difference in Difference (PI-DiD) Framework"
*! version 1.0.1   11jul2026

program define pidid, rclass
	version 14.0

	syntax varname(numeric) [if] [in], PANELvar(varname) TIMEvar(varname) ///
		TREATvar(varname) T0(real) [T1(real -999) GRaph NOTABle ///
		XTITLE(string) YTITLE(string) TITLE(string) NAME(string)]

	marksample touse
	markout `touse' `panelvar' `timevar' `treatvar'

	quietly count if `touse'
	if r(N) == 0 {
		display as error "no observations satisfy the estimation sample"
		exit 2000
	}

	local depvar `varlist'

	*----------------------------------------------------------------
	* 0. treatvar must be coded 0 (control) / 1 (treated)
	*----------------------------------------------------------------
	tempvar tchk
	quietly generate `tchk' = `treatvar' if `touse'
	quietly summarize `tchk'
	if r(min) != 0 | r(max) != 1 {
		display as error "treatvar() must be coded 0 (control) and 1 (treated)"
		exit 198
	}

	preserve
	quietly keep if `touse'

	*----------------------------------------------------------------
	* 1. Collapse to the two group-time paths c0(t) and c1(t)
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

	*----------------------------------------------------------------
	* 2. Gap function tau(t) = c1(t) - c0(t)  and pre-trend check
	*----------------------------------------------------------------
	quietly generate double __tau__ = __c1__ - __c0__

	quietly summarize __tau__ if `timevar' == `t0'
	local tau_t0 = r(mean)

	*----------------------------------------------------------------
	* 3. Optional graph (Figure 2 style) drawn on the FULL path,
	*    before the sample is trimmed to the integration window
	*----------------------------------------------------------------
	if "`graph'" != "" {
		local gxtitle "Time"
		local gytitle "`depvar'"
		local gtitle  "PI-DiD: treated vs. counterfactual path"
		if `"`xtitle'"' != "" local gxtitle `"`xtitle'"'
		if `"`ytitle'"' != "" local gytitle `"`ytitle'"'
		if `"`title'"'  != "" local gtitle  `"`title'"'
		local gname
		if `"`name'"' != "" local gname "name(`name', replace)"

		twoway ///
			(rarea __c1__ __c0__ `timevar' if `timevar' >= `t0' & `timevar' <= `t1', ///
				color(gs12%60)) ///
			(line __c0__ `timevar', lpattern(dash) lcolor(navy)) ///
			(line __c1__ `timevar', lcolor(cranberry)) ///
			, ///
			xline(`t0' `t1', lpattern(shortdash) lcolor(gs8)) ///
			legend(order(2 "Counterfactual c0(t)" 3 "Treated c1(t)" ///
				1 "{&sigma} (cumulative effect)") pos(6) rows(1)) ///
			xtitle(`"`gxtitle'"') ytitle(`"`gytitle'"', orientation(horizontal)) title(`"`gtitle'"') ///
			`gname'
	}

	*----------------------------------------------------------------
	* 4. Trapezoidal path integral over [t0, t1]
	*    sigma = int_t0^t1 tau(t) dt
	*----------------------------------------------------------------
	quietly keep if `timevar' >= `t0' & `timevar' <= `t1'
	quietly sort `timevar'
	quietly count
	if r(N) < 2 {
		display as error "need at least two observed time points between t0() and t1() to integrate"
		restore
		exit 2000
	}

	quietly generate double __dt__    = `timevar' - `timevar'[_n-1]
	quietly generate double __trapz__ = 0.5*(__tau__ + __tau__[_n-1])*__dt__ if _n > 1

	quietly summarize __trapz__, meanonly
	local sigma = r(sum)

	quietly summarize __tau__ if `timevar' == `t0'
	local tau_a = r(mean)
	quietly summarize __tau__ if `timevar' == `t1'
	local tau_b = r(mean)

	local did_static = `tau_b' - `tau_a'
	local att_path    = `sigma' / (`t1' - `t0')

	tempfile pathdata
	quietly save `pathdata'
	restore

	*----------------------------------------------------------------
	* 5. Reporting
	*----------------------------------------------------------------
	if "`notable'" == "" {
		display as text ""
		display as text "{hline 60}"
		display as text "Path-Integrated Difference-in-Differences (PI-DiD)"
		display as text "{hline 60}"
		display as text "Outcome:            " as result "`depvar'"
		display as text "Panel id:            " as result "`panelvar'"
		display as text "Time variable:       " as result "`timevar'"
		display as text "Treatment indicator: " as result "`treatvar'"
		display as text "Window:              " as result "t0 = `t0'    t1 = `t1'"
		display as text "{hline 60}"

		preserve
		quietly use `pathdata', clear
		display as text %8s "time" _col(12) "c0(t)" _col(24) "c1(t)" _col(36) "tau(t)"
		local N = _N
		forvalues i = 1/`N' {
			local tt  = `timevar'[`i']
			local c0v = __c0__[`i']
			local c1v = __c1__[`i']
			local tv  = __tau__[`i']
			display as result %8.2f `tt' _col(12) %8.2f `c0v' _col(24) %8.2f `c1v' _col(36) %8.2f `tv'
		}
		restore
		display as text "{hline 60}"
	}

	display as text ""
	display as text "Pre-treatment gap, tau(t0)          = " as result %9.3f `tau_t0' ///
		as text "  (parallel pre-trends require ~0)"
	display as text "Cumulative causal effect, sigma     = " as result %9.3f `sigma'
	display as text "Path-integrated ATT, tau-bar        = " as result %9.3f `att_path'
	display as text "Conventional static DiD (endpoints) = " as result %9.3f `did_static'
	display as text ""
	if abs(`did_static') < 1e-6 & abs(`sigma') > 1e-6 {
		display as text "{bf:Note:} static DiD is (near) zero while the path-integrated"
		display as text "effect is not -- this is the endpoint-subtraction bias"
		display as text "documented in Salavi (2026)."
	}

	return scalar sigma      = `sigma'
	return scalar att_path   = `att_path'
	return scalar did_static = `did_static'
	return scalar tau_t0     = `tau_t0'
	return scalar t0         = `t0'
	return scalar t1         = `t1'

end
