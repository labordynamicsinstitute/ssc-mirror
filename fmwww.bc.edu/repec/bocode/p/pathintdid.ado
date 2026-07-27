*! pathintdid.ado - Path-Integrated Difference-in-Differences (PI-DiD)
*! Implements the framework and estimation theory of Salavi (2026),
*! "Path-Integrated Difference-in-Differences (PI-DiD): Identification,
*! Estimation, and Inference for Cumulative Treatment Effects"
*! Formerly distributed as -pidid- (renamed at the request of the
*! Stata Journal editors, 13jul2026, to avoid colliding with a
*! possible future official StataCorp command name).
*! version 2.1.0   15jul2026
*! 2.1.0: added the companion command pathintdidrobust.ado, implementing
*!        the section 5 robustness checks and specification tests of
*!        the companion paper (dynamic placebo test for pre-treatment
*!        parallel trends, grid-density/Simpson quadrature sensitivity,
*!        and the anticipation-robust bounding estimator).
*! 2.0.1: fixed a bug in the duplicate panelvar/timevar check that made
*!        every call to pathintdid fail with an "invalid syntax" error
*!        (the "by"/"bysort" prefix cannot itself carry an if/in
*!        qualifier -- that has to go on the command after the colon).
*!        The check now runs, correctly, on the touse-restricted sample.

program define pathintdid, rclass
	version 14.0

	syntax varname(numeric) [if] [in], PANELvar(varname) TIMEvar(varname) ///
		TREATvar(varname) T0(real) [T1(real -999) LEVEL(cilevel) ///
		GRaph NOTABle NOSE ///
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

	*----------------------------------------------------------------
	* 0b. panelvar/timevar must not contain duplicate unit-period pairs
	*     (the "by"/"bysort" prefix itself cannot take an if/in
	*     qualifier -- that must go on the command after the colon --
	*     so we first drop to the estimation sample, then bysort-count
	*     within it)
	*----------------------------------------------------------------
	preserve
	quietly keep if `touse'

	tempvar dupflag
	quietly bysort `panelvar' `timevar': generate `dupflag' = _N > 1
	quietly summarize `dupflag', meanonly
	if r(max) == 1 {
		display as error "panelvar()/timevar() do not uniquely identify observations (duplicates found)"
		restore
		exit 198
	}

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
	* keep a copy of the raw (individual-level) data: needed later to
	* build the unit-level baseline-demeaned trajectories used for
	* standard errors. The point-estimate branch below collapses the
	* in-memory copy to group-by-time means as before.
	*----------------------------------------------------------------
	tempfile rawpanel
	quietly save `rawpanel'

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

	*----------------------------------------------------------------
	* 2. Gap function tau(t) = c1(t) - c0(t), and its baseline-
	*    differenced counterpart tauhat(t) = tau(t) - tau(t0), which
	*    is the building-block estimator of the companion paper's
	*    Theorem 1 (it coincides with tau(t) whenever parallel
	*    pre-trends hold exactly, i.e. tau(t0) = 0).
	*----------------------------------------------------------------
	quietly generate double __tau__ = __c1__ - __c0__

	quietly summarize __tau__ if `timevar' == `t0'
	local tau_t0 = r(mean)

	quietly generate double __taud__ = __tau__ - `tau_t0'

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
			xtitle(`"`gxtitle'"') ytitle(`"`gytitle'"') title(`"`gtitle'"') ///
			`gname'
	}

	*----------------------------------------------------------------
	* 4. Trapezoidal path integral over [t0, t1]
	*    sigma = int_t0^t1 tauhat(t) dt
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
	quietly generate double __trapz__ = 0.5*(__taud__ + __taud__[_n-1])*__dt__ if _n > 1

	quietly summarize __trapz__, meanonly
	local sigma = r(sum)

	quietly summarize __taud__ if `timevar' == `t1'
	local did_static = r(mean)
	local att_path    = `sigma' / (`t1' - `t0')

	* grid times used for integration, sorted, t0 first
	local K = 0
	local gridlist ""
	local nobs = _N
	forvalues i = 1/`nobs' {
		local gt = `timevar'[`i']
		local gridlist "`gridlist' `gt'"
		if `gt' != `t0' local ++K
	}

	tempfile pathdata
	quietly save `pathdata'
	restore

	*----------------------------------------------------------------
	* 5. Standard errors, t-statistics, and confidence intervals
	*    (Theorems 1-2 of the companion paper): built from the
	*    individual-level baseline-demeaned trajectories
	*    Delta Y_i,k = Y_i,tk - Y_i,t0, k = 1,...,K, using a
	*    cluster(panelvar)-style, group-specific covariance matrix.
	*----------------------------------------------------------------
	local have_se = 0
	if "`nose'" == "" {
		preserve
		quietly use `rawpanel', clear

		* map each observed grid time to a sequential integer rank
		* 0,1,...,K (0 = t0), which sidesteps any fragile variable-
		* naming issues that reshape would otherwise inherit from
		* the raw (possibly non-integer) values of timevar.
		tempvar grank
		quietly generate int `grank' = .
		local kk = 0
		foreach gt of local gridlist {
			quietly replace `grank' = `kk' if `timevar' == `gt'
			local ++kk
		}
		quietly keep if `grank' != .
		quietly keep `panelvar' `treatvar' `depvar' `grank'

		capture noisily quietly reshape wide `depvar', i(`panelvar') j(`grank')
		if _rc {
			display as text "{bf:Note:} could not build the unit-level trajectory matrix " ///
				"needed for standard errors (unbalanced panel across the integration " ///
				"grid?); reporting point estimates only."
			restore
		}
		else {
			capture confirm variable `depvar'0
			if _rc {
				display as text "{bf:Note:} no unit has an observation exactly at t0() " ///
					"after reshaping; standard errors not reported."
				restore
			}
			else {
				forvalues k = 1/`K' {
					capture confirm variable `depvar'`k'
					if _rc {
						display as text "{bf:Note:} unbalanced panel across the integration grid; " ///
							"standard errors not reported."
						local K 0
						continue, break
					}
					quietly generate double __d`k'__ = `depvar'`k' - `depvar'0
				}

				capture confirm variable __d1__
				if !_rc & `K' > 0 {
					quietly count if `treatvar' == 1 & __d1__ != .
					local N1c = r(N)
					quietly count if `treatvar' == 0 & __d1__ != .
					local N0c = r(N)

					if `N1c' < 2 | `N0c' < 2 {
						display as text "{bf:Note:} standard errors require at least 2 treated and " ///
							"2 control units with complete records at every grid date in " ///
							"[t0,t1]; found N1=`N1c' N0=`N0c'. Reporting point estimates only."
					}
					else {
						quietly correlate __d1__-__d`K'__ if `treatvar' == 1, covariance
						tempname Sigma1
						matrix `Sigma1' = r(C)
						quietly correlate __d1__-__d`K'__ if `treatvar' == 0, covariance
						tempname Sigma0
						matrix `Sigma0' = r(C)

						local Ntot = `N1c' + `N0c'
						local pihat = `N1c' / `Ntot'

						tempname Omega
						matrix `Omega' = `Sigma1' * (1/`pihat') + `Sigma0' * (1/(1-`pihat'))

						* trapezoidal weight vector w (1 x K), general
						* (possibly unequally spaced) grid
						local prev `t0'
						local j = 0
						local dtlist ""
						foreach gt of local gridlist {
							if `gt' != `t0' {
								local ++j
								local dt`j' = `gt' - `prev'
								local prev `gt'
							}
						}
						tempname wmat
						matrix `wmat' = J(1, `K', 0)
						forvalues j = 1/`K' {
							local left  = 0.5*`dt`j''
							local right = 0
							local jp1 = `j' + 1
							if `jp1' <= `K' local right = 0.5*`dt`jp1''
							matrix `wmat'[1,`j'] = `left' + `right'
						}

						tempname Vsig
						matrix `Vsig' = `wmat' * `Omega' * `wmat''
						local var_sigma = `Vsig'[1,1] / `Ntot'
						local se_sigma  = sqrt(`var_sigma')
						local se_att    = `se_sigma' / (`t1' - `t0')
						local se_did    = sqrt(`Omega'[`K',`K'] / `Ntot')

						local df_se   = `Ntot' - 2
						local crit    = invttail(`df_se', (100-`level')/200)

						local t_sigma = `sigma' / `se_sigma'
						local t_did   = `did_static' / `se_did'
						local p_sigma = 2*ttail(`df_se', abs(`t_sigma'))
						local p_did   = 2*ttail(`df_se', abs(`t_did'))

						local ci_sigma_lb = `sigma' - `crit'*`se_sigma'
						local ci_sigma_ub = `sigma' + `crit'*`se_sigma'
						local ci_att_lb   = `att_path' - `crit'*`se_att'
						local ci_att_ub   = `att_path' + `crit'*`se_att'
						local ci_did_lb   = `did_static' - `crit'*`se_did'
						local ci_did_ub   = `did_static' + `crit'*`se_did'

						local have_se = 1
					}
				}
			}
			restore
		}
	}

	*----------------------------------------------------------------
	* 6. Reporting
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
			local tv  = __taud__[`i']
			display as result %8.2f `tt' _col(12) %8.2f `c0v' _col(24) %8.2f `c1v' _col(36) %8.2f `tv'
		}
		restore
		display as text "{hline 60}"
	}

	display as text ""
	display as text "Pre-treatment gap, tau(t0)          = " as result %9.3f `tau_t0' ///
		as text "  (parallel pre-trends require ~0)"
	display as text ""

	if `have_se' {
		display as text "{hline 78}"
		display as text %-22s "" _col(24) "Coef." _col(36) "Std. Err." _col(48) "t" ///
			_col(56) "P>|t|" _col(66) "[`level'% Conf. Interval]"
		display as text "{hline 78}"
		display as text %-22s "Cumulative (sigma)" as result ///
			_col(23) %9.3f `sigma' _col(35) %9.3f `se_sigma' _col(47) %6.2f `t_sigma' ///
			_col(55) %6.3f `p_sigma' _col(64) %9.3f `ci_sigma_lb' "  " %9.3f `ci_sigma_ub'
		display as text %-22s "Path-ATT (tau-bar)" as result ///
			_col(23) %9.3f `att_path' _col(35) %9.3f `se_att' _col(47) %6.2f `t_sigma' ///
			_col(55) %6.3f `p_sigma' _col(64) %9.3f `ci_att_lb' "  " %9.3f `ci_att_ub'
		display as text %-22s "Static DiD (endpoints)" as result ///
			_col(23) %9.3f `did_static' _col(35) %9.3f `se_did' _col(47) %6.2f `t_did' ///
			_col(55) %6.3f `p_did' _col(64) %9.3f `ci_did_lb' "  " %9.3f `ci_did_ub'
		display as text "{hline 78}"
		display as text "SE/t/CI: cluster(`panelvar')-style, based on N1=`N1c' treated and " ///
			"N0=`N0c' control units with complete records; df = `df_se'."
	}
	else {
		display as text "Cumulative causal effect, sigma     = " as result %9.3f `sigma'
		display as text "Path-integrated ATT, tau-bar        = " as result %9.3f `att_path'
		display as text "Conventional static DiD (endpoints) = " as result %9.3f `did_static'
		if "`nose'" != "" {
			display as text ""
			display as text "(standard errors suppressed: nose specified)"
		}
	}
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
	return scalar level      = `level'

	if `have_se' {
		return scalar se_sigma   = `se_sigma'
		return scalar t_sigma    = `t_sigma'
		return scalar p_sigma    = `p_sigma'
		return scalar ci_sigma_lb = `ci_sigma_lb'
		return scalar ci_sigma_ub = `ci_sigma_ub'

		return scalar se_att     = `se_att'
		return scalar t_att      = `t_sigma'
		return scalar p_att      = `p_sigma'
		return scalar ci_att_lb  = `ci_att_lb'
		return scalar ci_att_ub  = `ci_att_ub'

		return scalar se_did     = `se_did'
		return scalar t_did      = `t_did'
		return scalar p_did      = `p_did'
		return scalar ci_did_lb  = `ci_did_lb'
		return scalar ci_did_ub  = `ci_did_ub'

		return scalar N1         = `N1c'
		return scalar N0         = `N0c'
		return scalar df         = `df_se'
	}

end
