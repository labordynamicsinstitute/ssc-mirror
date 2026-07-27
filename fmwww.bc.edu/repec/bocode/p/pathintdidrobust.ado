*! pathintdidrobust.ado - Robustness checks and specification tests for
*! Path-Integrated Difference-in-Differences (PI-DiD)
*! Companion command to pathintdid.ado / pathintdidplot.ado, implementing
*! the three diagnostics of section 5 ("Robustness checks and
*! specification tests") of Salavi (2026):
*!   (A) dynamic placebo test for pre-treatment parallel trends
*!       (joint Wald test on tau_pre, and the pre-treatment cumulative
*!       envelope (PCE) test on sigma_pre);
*!   (B) sensitivity of sigma-hat to grid density (half-grid comparison)
*!       and to the quadrature rule (trapezoidal vs. Simpson's 1/3 rule);
*!   (C) the anticipation-robust bounding estimator sigma-hat(delta) and
*!       its sensitivity curve over a grid of anticipation horizons.
*!
*! All three diagnostics that require pre-treatment survey waves (A and
*! C) degrade gracefully -- with an explicit note, not silently -- when
*! no observation is recorded before t0().
*!
*! version 1.0.0   15jul2026

*==================================================================
* Helper: sigma-hat and its cluster(panelvar)-style standard error
* on an arbitrary [wlo, whi] window with an arbitrary reference date
* tbase() in [wlo, whi]. Used for the post-treatment window in
* pathintdid.ado itself (tbase = wlo), for the pre-treatment placebo
* window (tbase = whi = t0), and for each anticipation-shifted window
* in section (C) below (tbase = wlo = t0 - delta).
*==================================================================
program define _pidid_seg, rclass
	version 14.0
	syntax varname(numeric) [if] [in], PANELvar(varname) TIMEvar(varname) ///
		TREATvar(varname) TBase(real) WLO(real) WHI(real) [LEVEL(real 95)]

	marksample touse
	markout `touse' `panelvar' `timevar' `treatvar'
	local depvar `varlist'

	return scalar have = 0

	preserve
	quietly keep if `touse' & `timevar' >= `wlo' & `timevar' <= `whi'
	quietly count if `timevar' == `tbase'
	if r(N) == 0 {
		restore
		exit
	}
	quietly count
	if r(N) == 0 {
		restore
		exit
	}

	*--- point estimate: collapse to the two group-time paths --------
	tempfile rawseg
	quietly save `rawseg'

	quietly collapse (mean) `depvar', by(`treatvar' `timevar')
	quietly reshape wide `depvar', i(`timevar') j(`treatvar')
	capture confirm variable `depvar'0
	if _rc {
		restore
		exit
	}
	capture confirm variable `depvar'1
	if _rc {
		restore
		exit
	}
	rename `depvar'0 __c0__
	rename `depvar'1 __c1__
	quietly sort `timevar'
	quietly generate double __tau__ = __c1__ - __c0__
	quietly summarize __tau__ if `timevar' == `tbase', meanonly
	local tb = r(mean)
	quietly generate double __taud__ = __tau__ - `tb'

	quietly count
	local ngrid = r(N)
	if `ngrid' < 2 {
		restore
		exit
	}

	quietly generate double __dt__    = `timevar' - `timevar'[_n-1]
	quietly generate double __trapz__ = 0.5*(__taud__ + __taud__[_n-1])*__dt__ if _n > 1
	quietly summarize __trapz__, meanonly
	local sigma = r(sum)

	local gridlist ""
	forvalues i = 1/`ngrid' {
		local gt = `timevar'[`i']
		local gridlist "`gridlist' `gt'"
	}
	local K = `ngrid' - 1

	return scalar sigma = `sigma'
	return scalar K     = `K'
	return scalar N     = `ngrid'
	return local  gridlist "`gridlist'"

	*--- standard error via the individual-level covariance matrix ---
	quietly use `rawseg', clear

	tempvar crank
	quietly generate int `crank' = .
	local kk = 0
	local bcrank = -1
	foreach gt of local gridlist {
		if `gt' == `tbase' local bcrank `kk'
		quietly replace `crank' = `kk' if `timevar' == `gt'
		local ++kk
	}
	quietly keep `panelvar' `treatvar' `depvar' `crank'
	quietly keep if `crank' != .

	capture noisily quietly reshape wide `depvar', i(`panelvar') j(`crank')
	if _rc {
		restore
		exit
	}
	capture confirm variable `depvar'`bcrank'
	if _rc {
		restore
		exit
	}

	local dlist ""
	local maxc = `ngrid' - 1
	forvalues k = 0/`maxc' {
		if `k' == `bcrank' continue
		capture confirm variable `depvar'`k'
		if _rc {
			restore
			exit
		}
		quietly generate double __seg_d`k'__ = `depvar'`k' - `depvar'`bcrank'
		local dlist "`dlist' __seg_d`k'__"
	}

	if `K' == 0 {
		restore
		exit
	}

	quietly count if `treatvar' == 1 & `depvar'`bcrank' != .
	local N1c = r(N)
	quietly count if `treatvar' == 0 & `depvar'`bcrank' != .
	local N0c = r(N)
	if `N1c' < 2 | `N0c' < 2 {
		restore
		exit
	}

	quietly correlate `dlist' if `treatvar' == 1, covariance
	tempname Sigma1
	matrix `Sigma1' = r(C)
	quietly correlate `dlist' if `treatvar' == 0, covariance
	tempname Sigma0
	matrix `Sigma0' = r(C)

	local Ntot  = `N1c' + `N0c'
	local pihat = `N1c' / `Ntot'

	tempname Omega
	matrix `Omega' = `Sigma1' * (1/`pihat') + `Sigma0' * (1/(1-`pihat'))

	* chronological gaps between consecutive grid points
	local ndt = `ngrid' - 1
	local prevt : word 1 of `gridlist'
	forvalues j = 1/`ndt' {
		local jp1 = `j' + 1
		local gt : word `jp1' of `gridlist'
		local dt`j' = `gt' - `prevt'
		local prevt `gt'
	}

	* trapezoid weight for each non-baseline grid point (0-based crank),
	* in the same ascending-crank order as the columns of `dlist'
	tempname wmat
	matrix `wmat' = J(1, `K', 0)
	local col = 0
	forvalues k = 0/`ndt' {
		if `k' == `bcrank' continue
		local ++col
		local wgt = 0
		if `k' >= 1        local wgt = `wgt' + 0.5*`dt`k''
		local kp1 = `k' + 1
		if `kp1' <= `ndt'  local wgt = `wgt' + 0.5*`dt`kp1''
		matrix `wmat'[1,`col'] = `wgt'
	}

	tempname Vsig
	matrix `Vsig' = `wmat' * `Omega' * `wmat''
	local var_sigma = `Vsig'[1,1] / `Ntot'
	local se_sigma  = sqrt(`var_sigma')
	local df_se     = `Ntot' - 2
	local crit      = invttail(`df_se', (100-`level')/200)

	return scalar se_sigma = `se_sigma'
	return scalar df       = `df_se'
	return scalar N1       = `N1c'
	return scalar N0       = `N0c'
	return scalar ci_lb    = `sigma' - `crit'*`se_sigma'
	return scalar ci_ub    = `sigma' + `crit'*`se_sigma'
	return scalar have     = 1
	return matrix Omega    = `Omega'
	return matrix w        = `wmat'

	restore
end

*==================================================================
* Main command
*==================================================================
program define pathintdidrobust, rclass
	version 14.0

	syntax varname(numeric) [if] [in], PANELvar(varname) TIMEvar(varname) ///
		TREATvar(varname) T0(real) [T1(real -999) LEVEL(cilevel) ///
		MAXANTicip(integer 0) NOTABle]

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

	tempfile rawpanel
	quietly save `rawpanel'

	display as text ""
	display as text "{hline 66}"
	display as text "PI-DiD robustness checks and specification tests"
	display as text "(Salavi 2026, section 5)"
	display as text "{hline 66}"
	display as text "Outcome:            " as result "`depvar'"
	display as text "Window:              " as result "t0 = `t0'    t1 = `t1'"

	*----------------------------------------------------------------
	* Full observed grid, all times in [tmin, t1], used both to find
	* pre-treatment waves (for A and C) and the post-treatment grid
	* (for B).
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
	quietly generate double __tau__  = __c1__ - __c0__
	quietly summarize __tau__ if `timevar' == `t0', meanonly
	local tau_t0 = r(mean)
	quietly generate double __taud__ = __tau__ - `tau_t0'

	local pretimes ""
	local P = 0
	quietly count
	local ngrid = _N
	forvalues i = 1/`ngrid' {
		local gt = `timevar'[`i']
		if `gt' < `t0' {
			local pretimes "`pretimes' `gt'"
			local ++P
		}
	}

	tempfile fullgrid
	quietly save `fullgrid'

	*==================================================================
	* (A) Dynamic placebo test for pre-treatment parallel trends
	*==================================================================
	display as text ""
	display as text "{hline 66}"
	display as text "(A) Dynamic placebo test for pre-treatment parallel trends"
	display as text "{hline 66}"

	local have_pretest = 0
	if `P' == 0 {
		display as text "{bf:Note:} no observations recorded before t0(`t0'); the pre-treatment"
		display as text "placebo test requires at least one pre-treatment wave and is skipped."
	}
	else {
		quietly use `fullgrid', clear
		local sigma_pre = 0
		local wlo_pre : word 1 of `pretimes'

		tempname tauvec
		matrix `tauvec' = J(`P', 1, 0)
		local jj = 0
		foreach gt of local pretimes {
			local ++jj
			quietly summarize __taud__ if `timevar' == `gt', meanonly
			matrix `tauvec'[`jj',1] = r(mean)
		}

		quietly use `fullgrid', clear
		quietly keep if `timevar' >= `wlo_pre' & `timevar' <= `t0'
		quietly sort `timevar'
		quietly generate double __dt__    = `timevar' - `timevar'[_n-1]
		quietly generate double __trapz__ = 0.5*(__taud__ + __taud__[_n-1])*__dt__ if _n > 1
		quietly summarize __trapz__, meanonly
		local sigma_pre = r(sum)

		quietly use `rawpanel', clear
		_pidid_seg `depvar' if `touse', panelvar(`panelvar') timevar(`timevar') ///
			treatvar(`treatvar') tbase(`t0') wlo(`wlo_pre') whi(`t0') level(`level')

		if r(have) == 0 {
			display as text "{bf:Note:} could not compute standard errors for the pre-treatment"
			display as text "window (unbalanced panel or too few units); reporting the point"
			display as text "estimate of sigma_pre only."
			display as text ""
			display as text "sigma_pre (pre-treatment cumulative gap) = " as result %9.3f `sigma_pre'
		}
		else {
			local se_sigma_pre = r(se_sigma)
			local Ntot_pre     = r(N1) + r(N0)
			local df_pre       = r(df)
			tempname Omega_pre
			matrix `Omega_pre' = r(Omega)

			local Z_pre = `sigma_pre' / `se_sigma_pre'
			local p_Z   = 2*(1 - normal(abs(`Z_pre')))

			tempname IOmega_pre
			matrix `IOmega_pre' = invsym(`Omega_pre')
			tempname Wq
			matrix `Wq' = `tauvec'' * `IOmega_pre' * `tauvec''
			local W_pre = `Ntot_pre' * `Wq'[1,1]
			local p_Wald = chi2tail(`P', `W_pre')

			display as text "Pre-treatment window:  [" as result "`wlo_pre'" as text ", " ///
				as result "`t0'" as text "]   (" as result `P' as text " pre-treatment wave(s))"
			display as text ""
			display as text "Pre-treatment cumulative envelope (PCE) test:"
			display as text "  sigma_pre = " as result %9.3f `sigma_pre' ///
				as text "   se = " as result %9.3f `se_sigma_pre' ///
				as text "   Z = " as result %6.2f `Z_pre' ///
				as text "   p = " as result %6.3f `p_Z'
			display as text ""
			display as text "Joint Wald test of H0: tau_pre = 0  (all pre-treatment gaps zero):"
			display as text "  W = " as result %9.3f `W_pre' ///
				as text "   df = " as result `P' ///
				as text "   p = " as result %6.3f `p_Wald'
			display as text ""
			if `p_Z' < 0.05 | `p_Wald' < 0.05 {
				display as text "{bf:Warning:} the null of parallel pre-trends is rejected at the 5% level;"
				display as text "results based on assumption 3 (path-level parallel trends) should be"
				display as text "interpreted with caution."
			}
			else {
				display as text "Fails to reject parallel pre-trends at the 5% level."
			}

			return scalar sigma_pre = `sigma_pre'
			return scalar se_sigma_pre = `se_sigma_pre'
			return scalar Z_pre     = `Z_pre'
			return scalar p_Z_pre   = `p_Z'
			return scalar W_pre     = `W_pre'
			return scalar df_pre    = `P'
			return scalar p_Wald_pre = `p_Wald'
			local have_pretest = 1
		}
	}
	return scalar P_pre = `P'

	*==================================================================
	* (B) Sensitivity to grid density and to the quadrature scheme
	*==================================================================
	display as text ""
	display as text "{hline 66}"
	display as text "(B) Sensitivity to grid density and quadrature scheme"
	display as text "{hline 66}"

	quietly use `fullgrid', clear
	quietly keep if `timevar' >= `t0' & `timevar' <= `t1'
	quietly sort `timevar'
	quietly count
	local ngp = r(N)
	local K = `ngp' - 1

	local equal = 1
	local h0 = .
	forvalues i = 2/`ngp' {
		local im1 = `i' - 1
		local dti = `timevar'[`i'] - `timevar'[`im1']
		if `h0' == . local h0 = `dti'
		if abs(`dti' - `h0') > 1e-8 local equal = 0
	}

	if `K' < 2 | mod(`K',2) != 0 | !`equal' {
		display as text "{bf:Note:} the grid-sensitivity diagnostic requires an even number of"
		display as text "equally spaced post-treatment intervals between t0() and t1(); the"
		display as text "current window has K = `K' interval(s) (equal spacing = `equal'). Skipped."
	}
	else {
		local h = `h0'
		quietly generate double __trapz__ = 0.5*(__taud__ + __taud__[_n-1])*(`timevar'-`timevar'[_n-1]) if _n > 1
		quietly summarize __trapz__, meanonly
		local sigma_full = r(sum)

		* half grid: keep every other post-treatment point (indices
		* 0,2,4,...,K), forming K/2 intervals of width 2h
		tempvar keephalf
		quietly generate byte `keephalf' = 0
		local i = 1
		local keepnext = 1
		forvalues i = 1/`ngp' {
			if `keepnext' == 1 {
				quietly replace `keephalf' = 1 in `i'
				local keepnext = 0
			}
			else local keepnext = 1
		}
		preserve
		quietly keep if `keephalf'
		quietly sort `timevar'
		quietly generate double __trapzh__ = 0.5*(__taud__ + __taud__[_n-1])*(`timevar'-`timevar'[_n-1]) if _n > 1
		quietly summarize __trapzh__, meanonly
		local sigma_half = r(sum)
		restore

		* Simpson's 1/3 rule (requires even K, equal spacing)
		local sum_odd  = 0
		local sum_even = 0
		forvalues i = 1/`ngp' {
			local kk = `i' - 1
			local tv = __taud__[`i']
			if `kk' > 0 & `kk' < `K' {
				if mod(`kk',2) == 1 local sum_odd  = `sum_odd'  + `tv'
				else                local sum_even = `sum_even' + `tv'
			}
		}
		local tau0v = __taud__[1]
		local tauKv = __taud__[`ngp']
		local sigma_simpson = (`h'/3)*(`tau0v' + 4*`sum_odd' + 2*`sum_even' + `tauKv')

		local reldiff = .
		if abs(`sigma_full') > 1e-8 local reldiff = (`sigma_full'-`sigma_half')/`sigma_full'

		display as text "Full grid   (K = " as result `K' as text ", h = " as result %5.3f `h' as text "):"
		display as text "  sigma_K       = " as result %9.3f `sigma_full'
		display as text "Half grid   (K/2 = " as result `=`K'/2' as text " intervals, 2h = " as result %5.3f `=2*`h'' as text "):"
		display as text "  sigma_{K/2}   = " as result %9.3f `sigma_half'
		display as text "Simpson's 1/3 rule on the full grid:"
		display as text "  sigma_Simpson = " as result %9.3f `sigma_simpson'
		display as text ""
		if `reldiff' != . {
			display as text "Relative change, full vs. half grid: " as result %6.3f `reldiff' ///
				as text "  (" as result %5.1f `=100*`reldiff'' as text "%)"
		}
		if abs(`sigma_full' - `sigma_simpson') > 0.05*max(abs(`sigma_full'),1) {
			display as text "{bf:Note:} sigma_K and sigma_Simpson differ by more than 5%, suggesting"
			display as text "tau(t) may have curvature not well captured by assumption 4 (path"
			display as text "smoothness); consider a finer survey grid."
		}
		else {
			display as text "sigma_K and sigma_Simpson agree closely: no evidence against the"
			display as text "path-smoothness assumption from the quadrature comparison."
		}

		return scalar sigma_K       = `sigma_full'
		return scalar sigma_Khalf   = `sigma_half'
		return scalar sigma_Simpson = `sigma_simpson'
		return scalar K_grid        = `K'
	}

	*==================================================================
	* (C) Anticipation-robust bounding estimator and sensitivity curve
	*==================================================================
	display as text ""
	display as text "{hline 66}"
	display as text "(C) Anticipation-robust bounding estimator"
	display as text "{hline 66}"

	if `maxanticip' <= 0 {
		display as text "{bf:Note:} maxanticip() not specified (or 0); anticipation-robustness"
		display as text "sensitivity curve skipped. Specify maxanticip(#) to shift the reference"
		display as text "baseline back by up to # pre-treatment grid points."
	}
	else if `P' == 0 {
		display as text "{bf:Note:} no observations recorded before t0(`t0'); the anticipation-"
		display as text "robust bounding estimator requires at least one pre-treatment wave"
		display as text "and is skipped."
	}
	else {
		local mmax = min(`maxanticip', `P')
		display as text "Shifting the reference baseline back by delta = 0, 1, ..., `mmax'"
		display as text "pre-treatment grid point(s); integration window becomes"
		display as text "[t0 - delta, t1] for each delta."
		display as text ""
		display as text %-8s "delta" _col(12) "baseline" _col(24) "sigma(delta)" ///
			_col(40) "se" _col(50) "[`level'% CI]"

		tempname AntTable
		matrix `AntTable' = J(`mmax'+1, 4, .)

		local allpos = 1
		local allneg = 1
		local minsig = .
		local maxsig = .

		forvalues m = 0/`mmax' {
			if `m' == 0 local tb_m = `t0'
			else {
				local idx = `P' - `m' + 1
				local tb_m : word `idx' of `pretimes'
			}

			quietly use `rawpanel', clear
			_pidid_seg `depvar' if `touse', panelvar(`panelvar') timevar(`timevar') ///
				treatvar(`treatvar') tbase(`tb_m') wlo(`tb_m') whi(`t1') level(`level')

			if r(have) == 0 {
				display as text %-8.0f `m' _col(12) as result %8.2f `tb_m' as text _col(24) "  (not identified)"
			}
			else {
				local sig_m = r(sigma)
				local se_m  = r(se_sigma)
				local lb_m  = r(ci_lb)
				local ub_m  = r(ci_ub)

				matrix `AntTable'[`m'+1,1] = `sig_m'
				matrix `AntTable'[`m'+1,2] = `se_m'
				matrix `AntTable'[`m'+1,3] = `lb_m'
				matrix `AntTable'[`m'+1,4] = `ub_m'

				if `minsig' == . | `sig_m' < `minsig' local minsig = `sig_m'
				if `maxsig' == . | `sig_m' > `maxsig' local maxsig = `sig_m'
				if `lb_m' <= 0 local allpos = 0
				if `ub_m' >= 0 local allneg = 0

				display as text %-8.0f `m' _col(12) as result %8.2f `tb_m' ///
					as text _col(24) as result %9.3f `sig_m' ///
					as text _col(40) as result %7.3f `se_m' ///
					as text _col(50) as result "[" %8.3f `lb_m' ", " %8.3f `ub_m' "]"
			}
		}

		display as text ""
		if `allpos' {
			display as text "Robustness criterion satisfied: the lower CI bound of sigma(delta)"
			display as text "remains strictly positive across all delta considered. The positive"
			display as text "cumulative-effect finding is robust to plausible anticipation."
		}
		else if `allneg' {
			display as text "Robustness criterion satisfied (negative direction): the upper CI"
			display as text "bound of sigma(delta) remains strictly negative across all delta"
			display as text "considered."
		}
		else {
			display as text "Robustness criterion not satisfied: the sign of sigma(delta) is not"
			display as text "stable across anticipation horizons. Conservative, model-free bounds"
			display as text "for the true cumulative effect:"
			display as text "  [" as result %9.3f `minsig' as text ", " as result %9.3f `maxsig' as text "]"
		}

		return matrix anticipation_table = `AntTable'
		return scalar anticip_min = `minsig'
		return scalar anticip_max = `maxsig'
		return scalar anticip_mmax = `mmax'
	}

	display as text ""
	display as text "{hline 66}"

	restore
end
