*! _xtpqardl_waldtest v1.0.4 — Wald tests for Panel QARDL
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Date: August 2026
*!
*! Tests H0: parameter(tau_i) = parameter(tau_{i+1}) for all adjacent pairs
*!
*! v1.0.4: the covariance now carries the cross-quantile blocks (previously
*!         they were set to zero, which biased every statistic downwards);
*!         the degrees of freedom are reduced by the rank deficiency of
*!         R*V*R'; a short-run and a joint test were added.

capture program drop _xtpqardl_waldtest
program define _xtpqardl_waldtest, rclass
	version 15.1
	syntax , GMAT(string) VMAT(string) TAU(numlist >0 <1 sort) ///
		KX(integer) MDIM(integer) [NAR(integer 0) NSR(integer 0) NOTE(string)]

	local ntau : word count `tau'
	local M = `mdim'

	return scalar wald_beta  = .
	return scalar wald_rho   = .
	return scalar wald_sr    = .
	return scalar wald_joint = .

	if `ntau' < 2 {
		di as txt "  (Wald tests require at least 2 quantiles)"
		exit
	}

	* ================================================================
	* Quantiles at which every reported parameter is available
	* ================================================================
	local valid ""
	local nvalid = 0
	forvalues t = 1/`ntau' {
		local o  = (`t' - 1) * `M'
		local ok = 1
		forvalues a = 1/`M' {
			if `gmat'[1, `o' + `a'] >= . local ok = 0
		}
		if `ok' {
			local valid "`valid' `t'"
			local ++nvalid
		}
	}

	if `nvalid' < 2 {
		di as txt "  (only `nvalid' fully estimated quantile(s) — need >= 2" ///
			" for the Wald tests)"
		exit
	}

	* ================================================================
	* Header
	* ================================================================
	di
	di in smcl in gr "{hline 78}"
	di in smcl in gr "  {bf:+======================================================================+}"
	di in smcl in gr "  {bf:|}  " in ye "{bf:Wald Tests for Parameter Constancy Across Quantiles}"
	di in smcl in gr "  {bf:|}  " in gr "H0: parameter(tau_i) = parameter(tau_i+1) for all i"
	di in smcl in gr "  {bf:+======================================================================+}"
	di in smcl in gr "{hline 78}"
	di in gr "  {ralign 28:Test}" _c
	di in gr " {ralign 12:Wald stat}" _c
	di in gr " {ralign 6:df}" _c
	di in gr " {ralign 12:p-value}" _c
	di in gr " {ralign 16:Decision}"
	di in smcl in gr "{hline 78}"

	if `nvalid' < `ntau' {
		di in gr "  Note: `= `ntau' - `nvalid'' quantile(s) dropped" ///
			" (insufficient observations)"
		di in gr "  Testing across `nvalid' valid quantiles only"
		di in smcl in gr "{hline 78}"
	}

	* ================================================================
	* Blocks:  rho = position 1
	*          beta = positions 2 .. 1+kx
	*          AR   = positions 2+kx .. 1+kx+nar
	*          SR   = positions 2+kx+nar .. M
	* ================================================================
	_xtpq_wald_block "Rho (ECT speed)" `gmat' `vmat' "`valid'" `M' 1 1
	return scalar wald_rho = r(w)
	return scalar pval_rho = r(p)

	if `kx' > 0 {
		_xtpq_wald_block "Beta (long-run)" `gmat' `vmat' "`valid'" `M' ///
			2 `= 1 + `kx''
		return scalar wald_beta = r(w)
		return scalar pval_beta = r(p)
	}

	if `= `nar' + `nsr'' > 0 {
		_xtpq_wald_block "Short-run dynamics" `gmat' `vmat' "`valid'" `M' ///
			`= 2 + `kx'' `M'
		return scalar wald_sr = r(w)
		return scalar pval_sr = r(p)
	}

	_xtpq_wald_block "Joint (all parameters)" `gmat' `vmat' "`valid'" `M' 1 `M'
	return scalar wald_joint = r(w)
	return scalar pval_joint = r(p)

	di in smcl in gr "{hline 78}"
	di in gr "  Rejection => quantile heterogeneity (asymmetric dynamics)"
	if `"`note'"' != "" di in gr `"  `note'"'
	di in gr "  *** p<0.01, ** p<0.05, * p<0.10"
	di in smcl in gr "{hline 78}"
end


* =====================================================================
* One Wald block: equality of positions a..b across the valid quantiles
* =====================================================================
capture program drop _xtpq_wald_block
program define _xtpq_wald_block, rclass
	args label gmat vmat valid M a b

	local nblk   = `b' - `a' + 1
	local nvalid : word count `valid'
	local df     = (`nvalid' - 1) * `nblk'

	return scalar w = .
	return scalar p = .
	if `df' <= 0 exit

	local sub = `nvalid' * `nblk'

	tempname gs Vs R Rg RVR RVRi W
	matrix `gs' = J(1, `sub', 0)
	matrix `Vs' = J(`sub', `sub', 0)

	* --- extract the sub-vector and sub-matrix -----------------------
	local vi = 0
	foreach t of local valid {
		local ++vi
		local o = (`t' - 1) * `M'
		forvalues j = `a'/`b' {
			local dst = (`vi' - 1) * `nblk' + (`j' - `a' + 1)
			matrix `gs'[1, `dst'] = `gmat'[1, `o' + `j']
		}
	}

	local vi = 0
	foreach t1 of local valid {
		local ++vi
		local o1 = (`t1' - 1) * `M'
		local vj = 0
		foreach t2 of local valid {
			local ++vj
			local o2 = (`t2' - 1) * `M'
			forvalues r = `a'/`b' {
				forvalues c = `a'/`b' {
					local dr = (`vi' - 1) * `nblk' + (`r' - `a' + 1)
					local dc = (`vj' - 1) * `nblk' + (`c' - `a' + 1)
					matrix `Vs'[`dr', `dc'] = `vmat'[`o1' + `r', `o2' + `c']
				}
			}
		}
	}

	* --- restriction matrix: adjacent differences --------------------
	matrix `R' = J(`df', `sub', 0)
	local row = 0
	forvalues t = 1/`= `nvalid' - 1' {
		forvalues j = 1/`nblk' {
			local ++row
			matrix `R'[`row', (`t' - 1) * `nblk' + `j'] = 1
			matrix `R'[`row', `t' * `nblk' + `j']       = -1
		}
	}

	local failed = 0
	capture {
		matrix `Rg'   = `R' * `gs''
		matrix `RVR'  = `R' * `Vs' * `R''
		matrix `RVRi' = syminv(`RVR')
		matrix `W'    = `Rg'' * `RVRi' * `Rg'
	}
	if _rc local failed = 1

	if `failed' == 0 {
		local wstat  = `W'[1, 1]
		local df_adj = `df' - diag0cnt(`RVRi')
	}

	if `failed' == 0 & `wstat' < . & `wstat' >= 0 & `df_adj' > 0 {
		local pval = chi2tail(`df_adj', `wstat')

		if `pval' < 0.01      local decision "Reject***"
		else if `pval' < 0.05 local decision "Reject**"
		else if `pval' < 0.10 local decision "Reject*"
		else                  local decision "Fail to reject"

		di in gr "  {ralign 28:`label'}" _c
		di as res " {ralign 12:" %10.3f `wstat' "}" _c
		di in gr " {ralign 6:`df_adj'}" _c
		if `pval' < 0.05 {
			di as res " {ralign 12:" %10.4f `pval' "}" _c
			di as res " {ralign 16:`decision'}"
		}
		else {
			di in gr " {ralign 12:" %10.4f `pval' "}" _c
			di in gr " {ralign 16:`decision'}"
		}

		return scalar w = `wstat'
		return scalar p = `pval'
	}
	else {
		di in gr "  {ralign 28:`label'}" _c
		di in ye " {ralign 12:  (singular)}" _c
		di in gr " {ralign 6:`df'}" _c
		di in gr " {ralign 12:    .}" _c
		di in gr " {ralign 16:    —}"
	}
end
