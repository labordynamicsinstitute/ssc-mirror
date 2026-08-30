*! _xtcspqardl_advanced v1.1.0  29aug2026 -- post-estimation quantile analysis
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! github.com/merwanroudane
*!
*! Inter-quantile inference for xtcspqardl.
*!
*! IMPORTANT.  Coefficients estimated at two quantiles come from the SAME
*! cross-sectional units, so they are correlated.  The variance of a
*! contrast is
*!
*!     Var[b(t2) - b(t1)] = V[t2,t2] + V[t1,t1] - 2 V[t1,t2],
*!
*! and the joint test of quantile constancy needs the full R V R'.
*! Versions before 1.1.0 built a block-diagonal V, i.e. they set the
*! cross-quantile covariance to zero, which inflates the variance of a
*! contrast and makes both tests far too conservative.  The mean-group
*! covariance now carries those blocks and they are used here.

capture program drop _xtcspqardl_advanced
program define _xtcspqardl_advanced
	version 15.1
	syntax [, LEVel(cilevel) ]

	if "`e(cmd)'" != "xtcspqardl" {
		di as err "advanced analysis works only after xtcspqardl"
		exit 301
	}
	if "`level'" == "" local level = e(level)
	local z = invnormal(1 - (100 - `level')/200)

	local tau  "`e(tau)'"
	local ntau : word count `tau'
	if `ntau' < 2 {
		di
		di as txt "note: the inter-quantile analysis needs at least " ///
			"two quantiles; skipped."
		exit
	}

	tempname b V lr Vlr
	matrix `b'   = e(b_sr)
	matrix `V'   = e(V_sr)
	matrix `lr'  = e(b_lr)
	matrix `Vlr' = e(V_lr)

	local coefnames "`e(coefnames)'"
	local lrnames   "`e(lrnames)'"

	di
	di as txt "{hline 74}"
	di as txt "{bf:Inter-quantile analysis}"
	di as txt "{hline 74}"

	_xtcspq_iqtab, b(`b') v(`V') tau(`tau') names(`coefnames')        ///
		z(`z') level(`level')                                     ///
		title("A1. Short-run contrasts across quantiles")

	if "`lrnames'" != "" {
		_xtcspq_iqtab, b(`lr') v(`Vlr') tau(`tau')                ///
			names(`lrnames') z(`z') level(`level')            ///
			title("A2. Long-run contrasts across quantiles")
	}

	_xtcspq_qconst, b(`b') v(`V') tau(`tau') names(`coefnames')       ///
		title("A3. Test of quantile constancy, short run")

	if "`lrnames'" != "" {
		_xtcspq_qconst, b(`lr') v(`Vlr') tau(`tau')               ///
			names(`lrnames')                                  ///
			title("A4. Test of quantile constancy, long run")
	}

	_xtcspq_persist, tau(`tau')

	di as txt "{hline 74}"
end


* =====================================================================
* A1/A2  pairwise inter-quantile contrasts with the correct covariance
* =====================================================================
capture program drop _xtcspq_iqtab
program define _xtcspq_iqtab
	syntax , B(name) V(name) TAU(numlist) NAMES(string) Z(real)       ///
		TITLE(string) [ LEVel(cilevel) ]

	local nv   : word count `names'
	local ntau : word count `tau'
	local lstr = string(`level', "%2.0f")

	di
	di as txt "{bf:`title'}"
	di as txt "{hline 74}"
	di as txt %13s "Variable" %14s "Contrast" %10s "Diff." %10s "Std.Err." ///
		%8s "z" %8s "P>|z|"
	di as txt "{hline 74}"

	forvalues j = 1/`nv' {
		local nm : word `j' of `names'
		local shown = 0
		forvalues a = 1/`= `ntau' - 1' {
			forvalues c = `= `a' + 1'/`ntau' {
				local t1 : word `a' of `tau'
				local t2 : word `c' of `tau'
				local j1 = (`a' - 1) * `nv' + `j'
				local j2 = (`c' - 1) * `nv' + `j'
				mata: _xtcspq_iqr("`b'", "`v'", `j1', `j2', ///
					"r_d", "r_s")
				local d = r_d
				local s = r_s
				scalar drop r_d r_s
				local zz = .
				local pp = .
				if `s' > 0 & `s' < . {
					local zz = `d' / `s'
					local pp = 2 * normal(-abs(`zz'))
				}
				local st ""
				if `pp' < 0.01      local st "***"
				else if `pp' < 0.05 local st "** "
				else if `pp' < 0.10 local st "*  "

				if `shown' == 0 {
					di as txt %13s abbrev("`nm'", 13) _c
					local shown = 1
				}
				else di as txt %13s "" _c
				local lab = ///
					"`: di %4.2f `t2'' - `: di %4.2f `t1''"
				di as txt %14s "`lab'" _c
				di as res %10.4f `d' _c
				if `s' < . {
					di as res %10.4f `s' %8.2f `zz' %8.3f `pp' _c
					di as txt " `st'"
				}
				else di as txt %10s "." %8s "." %8s "."
			}
		}
	}
	di as txt "{hline 74}"
	di as txt "*** p<0.01, ** p<0.05, * p<0.10.  Var of a contrast ="
	di as txt "V(t2,t2) + V(t1,t1) - 2 V(t1,t2): the cross-quantile"
	di as txt "covariance is included, so the test is not conservative."
end


* =====================================================================
* A3/A4  joint test that a coefficient is constant across quantiles
* =====================================================================
capture program drop _xtcspq_qconst
program define _xtcspq_qconst
	syntax , B(name) V(name) TAU(numlist) NAMES(string) TITLE(string)

	local nv   : word count `names'
	local ntau : word count `tau'
	local df   = `ntau' - 1

	di
	di as txt "{bf:`title'}"
	di as txt "{hline 74}"
	di as txt %20s "Variable" %12s "chi2" %6s "df" %10s "p-value" ///
		%20s "Conclusion"
	di as txt "{hline 74}"

	forvalues j = 1/`nv' {
		local nm : word `j' of `names'

		* restriction matrix R: b(tau_s) - b(tau_1) = 0, s = 2..K
		tempname R d Vd Vi W
		matrix `R' = J(`df', `= `nv' * `ntau'', 0)
		forvalues s = 1/`df' {
			matrix `R'[`s', `j'] = -1
			matrix `R'[`s', `= `s' * `nv' + `j''] = 1
		}
		matrix `d'  = `R' * `b''
		matrix `Vd' = `R' * `v' * `R''
		local ok = 1
		capture matrix `Vi' = invsym(`Vd')
		if _rc != 0 local ok = 0
		if `ok' {
			matrix `W' = `d'' * `Vi' * `d'
			local w = `W'[1,1]
			local p = chi2tail(`df', `w')
		}
		else {
			local w = .
			local p = .
		}
		local concl "constant"
		if `p' < 0.05 local concl "varies with tau"

		di as txt %20s abbrev("`nm'", 20) _c
		if `w' < . {
			di as res %12.3f `w' _c
			di as txt %6.0f `df' _c
			di as res %10.3f `p' _c
			di as txt %20s "`concl'"
		}
		else di as txt %12s "." %6s "." %10s "." %20s "."
	}
	di as txt "{hline 74}"
	di as txt "H0: the coefficient is the same at every requested quantile."
	di as txt "Rejection is evidence of genuine distributional heterogeneity"
	di as txt "and justifies reporting the quantile process rather than a"
	di as txt "single conditional-mean effect."
end


* =====================================================================
* A5  persistence and half-life profile
* =====================================================================
capture program drop _xtcspq_persist
program define _xtcspq_persist
	syntax , TAU(numlist)

	tempname hl hlse b V
	capture matrix `hl'   = e(halflife)
	if _rc != 0 exit
	capture matrix `hlse' = e(halflife_se)
	matrix `b' = e(b_sr)
	matrix `V' = e(V_sr)
	local ntau : word count `tau'
	local nv : word count `e(coefnames)'

	di
	di as txt "{bf:A5. Persistence profile}"
	di as txt "{hline 74}"
	di as txt %10s "Quantile" %14s "Persistence" %12s "Std.Err."         ///
		%12s "Half-life" %12s "Std.Err."
	di as txt "{hline 74}"
	local ti = 0
	foreach tv of local tau {
		local ++ti
		local c = (`ti' - 1) * `nv' + 1
		local pv = `b'[1, `c']
		local ps = .
		if `V'[`c', `c'] > 0 & `V'[`c', `c'] < . ///
			local ps = sqrt(`V'[`c', `c'])
		local h  = `hl'[1, `ti']
		local hs = .
		capture local hs = `hlse'[1, `ti']
		di as txt %10s "`: di %4.2f `tv''" _c
		di as res %14.4f `pv' _c
		if `ps' < . di as res %12.4f `ps' _c
		else        di as txt %12s "." _c
		if `h' < .  di as res %12.3f `h' _c
		else        di as txt %12s "." _c
		if `hs' < . di as res %12.4f `hs'
		else        di as txt %12s "."
	}
	di as txt "{hline 74}"
	di as txt "Half-life h solves lambda^h = 1/2, i.e. h = ln(0.5)/ln(lambda),"
	di as txt "the exact discrete-time value.  Its standard error is the"
	di as txt "delta-method one, |dh/dlambda| * SE(lambda)."
end
