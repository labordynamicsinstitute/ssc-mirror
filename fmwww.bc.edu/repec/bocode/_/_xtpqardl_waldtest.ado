*! _xtpqardl_waldtest v1.0.1 — Wald tests for Panel QARDL
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Date: February 2026
*!
*! Tests H0: parameter(tau_i) = parameter(tau_{i+1}) for all adjacent pairs
*! Now handles missing quantiles by testing only valid ones

capture program drop _xtpqardl_waldtest
program define _xtpqardl_waldtest, rclass
	version 15.1
	
	* Use simple positional args to avoid option parsing issues
	args betamat betavmat rhomat rhovmat taulist kval nobsval
	
	local ntau : word count `taulist'
	
	if `ntau' < 2 {
		di as txt "  (Wald tests require at least 2 quantiles)"
		return scalar wald_beta = .
		return scalar wald_rho = .
		exit
	}
	
	* ================================================================
	* Identify valid (non-missing) quantiles
	* ================================================================
	local valid_taus ""
	local nvalid = 0
	forvalues t = 1/`ntau' {
		local b_ok = 1
		forvalues j = 1/`kval' {
			local bcol = (`t' - 1) * `kval' + `j'
			if `betamat'[1, `bcol'] == . local b_ok = 0
		}
		if `b_ok' {
			local valid_taus "`valid_taus' `t'"
			local ++nvalid
		}
	}
	
	if `nvalid' < 2 {
		di as txt "  (Only `nvalid' valid quantile(s) — need ≥ 2 for Wald test)"
		return scalar wald_beta = .
		return scalar wald_rho = .
		exit
	}
	
	* ================================================================
	* Display header
	* ================================================================
	di
	di in smcl in gr "{hline 78}"
	di in smcl in gr "  {bf:╔══════════════════════════════════════════════════════════════════════╗}"
	di in smcl in gr "  {bf:║   Wald Tests for Parameter Constancy Across Quantiles               ║}"
	di in smcl in gr "  {bf:║   H0: parameter(τ_i) = parameter(τ_{i+1}) for all i                ║}"
	di in smcl in gr "  {bf:╚══════════════════════════════════════════════════════════════════════╝}"
	di in smcl in gr "{hline 78}"
	di in gr "  {ralign 28:Test}" _c
	di in gr " {ralign 12:Wald stat}" _c
	di in gr " {ralign 6:df}" _c
	di in gr " {ralign 12:p-value}" _c
	di in gr " {ralign 16:Decision}"
	di in smcl in gr "{hline 78}"
	
	if `nvalid' < `ntau' {
		di in gr "  Note: `= `ntau' - `nvalid'' quantile(s) dropped (insufficient obs.)"
		di in gr "  Testing across `nvalid' valid quantiles only"
		di in smcl in gr "{hline 78}"
	}
	
	* ================================================================
	* Test 1: Beta constancy across VALID quantiles only
	* Extract sub-vectors for valid quantiles
	* ================================================================
	local sub_dim = `kval' * `nvalid'
	local df_beta = (`nvalid' - 1) * `kval'
	
	if `df_beta' > 0 {
		* Extract sub-vector of betas at valid quantiles
		tempname bsub Vsub
		matrix `bsub' = J(1, `sub_dim', 0)
		matrix `Vsub' = J(`sub_dim', `sub_dim', 0)
		
		local vi = 0
		foreach t of local valid_taus {
			local ++vi
			forvalues j = 1/`kval' {
				local src = (`t' - 1) * `kval' + `j'
				local dst = (`vi' - 1) * `kval' + `j'
				matrix `bsub'[1, `dst'] = `betamat'[1, `src']
			}
		}
		
		* Extract corresponding sub-block of variance matrix
		local vi = 0
		foreach t1 of local valid_taus {
			local ++vi
			local vj = 0
			foreach t2 of local valid_taus {
				local ++vj
				forvalues r = 1/`kval' {
					forvalues c = 1/`kval' {
						local sr = (`t1' - 1) * `kval' + `r'
						local sc = (`t2' - 1) * `kval' + `c'
						local dr = (`vi' - 1) * `kval' + `r'
						local dc = (`vj' - 1) * `kval' + `c'
						matrix `Vsub'[`dr', `dc'] = `betavmat'[`sr', `sc']
					}
				}
			}
		}
		
		* Build restriction matrix for valid quantiles only
		tempname R_beta Rb RVR RVR_inv W_beta
		matrix `R_beta' = J(`df_beta', `sub_dim', 0)
		
		local row = 0
		forvalues t = 1/`= `nvalid' - 1' {
			forvalues j = 1/`kval' {
				local ++row
				local col1 = (`t' - 1) * `kval' + `j'
				local col2 = `t' * `kval' + `j'
				matrix `R_beta'[`row', `col1'] = 1
				matrix `R_beta'[`row', `col2'] = -1
			}
		}
		
		* W = (R*b)' * inv(R*V*R') * (R*b)
		capture {
			matrix `Rb' = `R_beta' * `bsub''
			matrix `RVR' = `R_beta' * `Vsub' * `R_beta''
			matrix `RVR_inv' = syminv(`RVR')
			matrix `W_beta' = `Rb'' * `RVR_inv' * `Rb'
			local w_beta = `W_beta'[1,1]
		}
		
		if _rc == 0 & `w_beta' != . & `w_beta' > 0 {
			local pv_beta = chi2tail(`df_beta', abs(`w_beta'))
			_xtpqardl_wald_row "Beta (long-run)" `w_beta' `df_beta' `pv_beta'
			return scalar wald_beta = `w_beta'
			return scalar pval_beta = `pv_beta'
		}
		else {
			di in gr "  {ralign 28:Beta (long-run)}" _c
			di in ye " {ralign 12:  (singular)}" _c
			di in gr " {ralign 6:`df_beta'}" _c
			di in gr " {ralign 12:    .}" _c
			di in gr " {ralign 16:    —}"
			return scalar wald_beta = .
		}
	}
	
	* ================================================================
	* Test 2: Rho (ECT speed) constancy across VALID quantiles only
	* ================================================================
	* Identify valid rho quantiles
	local valid_rho ""
	local nvalid_r = 0
	forvalues t = 1/`ntau' {
		if `rhomat'[1, `t'] != . {
			local valid_rho "`valid_rho' `t'"
			local ++nvalid_r
		}
	}
	
	local df_rho = `nvalid_r' - 1
	
	if `df_rho' > 0 {
		* Extract sub-vector
		tempname rsub rVsub
		matrix `rsub' = J(1, `nvalid_r', 0)
		matrix `rVsub' = J(`nvalid_r', `nvalid_r', 0)
		
		local vi = 0
		foreach t of local valid_rho {
			local ++vi
			matrix `rsub'[1, `vi'] = `rhomat'[1, `t']
		}
		
		local vi = 0
		foreach t1 of local valid_rho {
			local ++vi
			local vj = 0
			foreach t2 of local valid_rho {
				local ++vj
				matrix `rVsub'[`vi', `vj'] = `rhovmat'[`t1', `t2']
			}
		}
		
		tempname R_rho Rrho RVR_rho RVR_rho_inv W_rho
		matrix `R_rho' = J(`df_rho', `nvalid_r', 0)
		
		forvalues t = 1/`df_rho' {
			matrix `R_rho'[`t', `t'] = 1
			matrix `R_rho'[`t', `t' + 1] = -1
		}
		
		capture {
			matrix `Rrho' = `R_rho' * `rsub''
			matrix `RVR_rho' = `R_rho' * `rVsub' * `R_rho''
			matrix `RVR_rho_inv' = syminv(`RVR_rho')
			matrix `W_rho' = `Rrho'' * `RVR_rho_inv' * `Rrho'
			local w_rho = `W_rho'[1,1]
		}
		
		if _rc == 0 & `w_rho' != . & `w_rho' > 0 {
			local pv_rho = chi2tail(`df_rho', abs(`w_rho'))
			_xtpqardl_wald_row "Rho (ECT speed)" `w_rho' `df_rho' `pv_rho'
			return scalar wald_rho = `w_rho'
			return scalar pval_rho = `pv_rho'
		}
		else {
			di in gr "  {ralign 28:Rho (ECT speed)}" _c
			di in ye " {ralign 12:  (singular)}" _c
			di in gr " {ralign 6:`df_rho'}" _c
			di in gr " {ralign 12:    .}" _c
			di in gr " {ralign 16:    —}"
			return scalar wald_rho = .
		}
	}
	else {
		di as txt "  (Rho: only `nvalid_r' valid quantile — need ≥ 2)"
		return scalar wald_rho = .
	}
	
	di in smcl in gr "{hline 78}"
	di in gr "  Rejection => quantile heterogeneity (asymmetric dynamics)"
	di in gr "  *** p<0.01, ** p<0.05, * p<0.10"
	di in smcl in gr "{hline 78}"
end

* ================================================================
* Helper: display one Wald test row
* ================================================================
capture program drop _xtpqardl_wald_row
program define _xtpqardl_wald_row
	args testname wstat df pval
	
	if `pval' < 0.01      local decision "Reject***"
	else if `pval' < 0.05 local decision "Reject**"
	else if `pval' < 0.10 local decision "Reject*"
	else                  local decision "Fail to reject"
	
	di in gr "  {ralign 28:`testname'}" _c
	di as res " {ralign 12:" %10.3f `wstat' "}" _c
	di in gr " {ralign 6:`df'}" _c
	if `pval' < 0.05 {
		di as err " {ralign 12:" %10.4f `pval' "}" _c
		di as err " {ralign 16:`decision'}"
	}
	else {
		di in gr " {ralign 12:" %10.4f `pval' "}" _c
		di in gr " {ralign 16:`decision'}"
	}
end
