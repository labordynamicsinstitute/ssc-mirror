*! _xtcspqardl_advanced v1.0.0 — Advanced analysis tables
*! Cross-quantile comparison, pairwise tests, persistence profile
*! Called internally by xtcspqardl.ado via the 'full' option
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Date: February 2026

capture program drop _xtcspqardl_advanced
program define _xtcspqardl_advanced
	version 15.1
	syntax , ESTIMATOR(string) TAU(numlist >0 <1 sort) ///
		DEPVAR(string) INDEPVARS(string) ///
		K(integer) [LRVARS(string) ECM]
	
	local ntau : word count `tau'
	
	if `ntau' < 2 {
		di
		di in gr "  (Advanced analysis requires ≥2 quantiles — skipped)"
		exit
	}
	
	di
	di in smcl in gr "{hline 78}"
	di in smcl in gr "  {bf:╔══════════════════════════════════════════════════════════════════════╗}"
	di in smcl in gr "  {bf:║              ADVANCED ANALYSIS — XTCSPQARDL                        ║}"
	di in smcl in gr "  {bf:╚══════════════════════════════════════════════════════════════════════╝}"
	di in smcl in gr "{hline 78}"
	
	* ================================================================
	* TABLE A1: Cross-Quantile Coefficient Comparison
	* ================================================================
	if inlist("`estimator'", "qccemg", "qccepmg") {
		_xtcspq_adv_qccemg_table, tau(`tau') depvar(`depvar') ///
			indepvars(`indepvars') k(`k')
	}
	else {
		_xtcspq_adv_cspqardl_table, tau(`tau') depvar(`depvar') ///
			indepvars(`indepvars') k(`k') lrvars(`lrvars') `ecm'
	}
	
	* ================================================================
	* TABLE A2: Pairwise Quantile Differences
	* ================================================================
	if inlist("`estimator'", "qccemg", "qccepmg") {
		_xtcspq_adv_pairwise_qccemg, tau(`tau') ///
			indepvars(`indepvars') k(`k')
	}
	else {
		_xtcspq_adv_pairwise_cspqardl, tau(`tau') ///
			indepvars(`indepvars') k(`k') lrvars(`lrvars') `ecm'
	}
	
	* ================================================================
	* TABLE A3: Persistence Profile
	* ================================================================
	_xtcspq_adv_persistence, tau(`tau') estimator(`estimator') `ecm'
	
	* ================================================================
	* TABLES A4-A5: QCCEMG-specific paper-based analysis
	* (HLP 2018, Tables 3.3-3.6)
	* ================================================================
	if inlist("`estimator'", "qccemg", "qccepmg") {
		_xtcspq_adv_lr_effects, tau(`tau') ///
			indepvars(`indepvars') k(`k') depvar(`depvar')
		_xtcspq_adv_irf, tau(`tau') ///
			indepvars(`indepvars') k(`k')
	}
	* ================================================================
	* TABLE A6: Quantile Slope Homogeneity Test
	* Joint Wald test H₀: coef(τ₁) = coef(τ₂) = ... = coef(τ_K)
	* ================================================================
	if inlist("`estimator'", "qccemg", "qccepmg") {
		_xtcspq_adv_homogeneity_qccemg, tau(`tau') ///
			indepvars(`indepvars') k(`k') depvar(`depvar')
	}
	else {
		_xtcspq_adv_homogeneity_cspqardl, tau(`tau') ///
			indepvars(`indepvars') k(`k') lrvars(`lrvars') `ecm'
	}
	
	di in smcl in gr "{hline 78}"
	di in gr "  {bf:Advanced analysis complete.}"
	di in smcl in gr "{hline 78}"
	di
end


* ================================================================
* TABLE A1a: QCCEMG Cross-Quantile Comparison
* ================================================================
capture program drop _xtcspq_adv_qccemg_table
program define _xtcspq_adv_qccemg_table
	syntax , TAU(numlist) DEPVAR(string) INDEPVARS(string) K(integer)
	
	local ntau : word count `tau'
	
	tempname lambda_mg beta_mg lambda_V beta_V
	matrix `lambda_mg' = e(lambda_mg)
	matrix `beta_mg' = e(beta_mg)
	matrix `lambda_V' = e(lambda_V)
	matrix `beta_V' = e(beta_V)
	
	di
	di in smcl in gr "{hline 78}"
	di in smcl in gr "  {bf:Table A1: QCCEMG Cross-Quantile Coefficient Summary}"
	di in smcl in gr "{hline 78}"
	di in gr "  {ralign 12:Variable}" _c
	foreach tauval of local tau {
		di in gr " {ralign 14:τ=" %4.2f `tauval' "}" _c
	}
	if `ntau' > 1 {
		di in gr " {ralign 10:Δ(max-min)}" _c
	}
	di ""
	di in smcl in gr "{hline 78}"
	
	* --- Lambda row ---
	di in ye "  {ralign 12:L.`depvar'}" _c
	local lam_min = .
	local lam_max = .
	local ti = 0
	foreach tauval of local tau {
		local ++ti
		local est = `lambda_mg'[1, `ti']
		di as res " {ralign 14:" %10.4f `est' "}" _c
		if `est' != . {
			if `lam_min' == . | `est' < `lam_min' local lam_min = `est'
			if `lam_max' == . | `est' > `lam_max' local lam_max = `est'
		}
	}
	if `ntau' > 1 & `lam_min' != . & `lam_max' != . {
		local delta = `lam_max' - `lam_min'
		di in ye " {ralign 10:" %8.4f `delta' "}" _c
	}
	di ""
	
	* SE row
	di in gr "  {ralign 12:SE}" _c
	local ti = 0
	foreach tauval of local tau {
		local ++ti
		local var_val = `lambda_V'[`ti', `ti']
		if `var_val' > 0 & `var_val' != . {
			local se = sqrt(`var_val')
			di in gr " {ralign 14:(" %8.4f `se' ")}" _c
		}
		else {
			di in gr " {ralign 14:     .}" _c
		}
	}
	di ""
	
	* z-stat row
	di in gr "  {ralign 12:z-stat}" _c
	local ti = 0
	foreach tauval of local tau {
		local ++ti
		local est = `lambda_mg'[1, `ti']
		local var_val = `lambda_V'[`ti', `ti']
		if `var_val' > 0 & `var_val' != . & `est' != . {
			local se = sqrt(`var_val')
			local zstat = `est' / `se'
			di in gr " {ralign 14:[" %7.3f `zstat' "]}" _c
		}
		else {
			di in gr " {ralign 14:     .}" _c
		}
	}
	di ""
	
	* p-value row
	di in gr "  {ralign 12:p-value}" _c
	local ti = 0
	foreach tauval of local tau {
		local ++ti
		local est = `lambda_mg'[1, `ti']
		local var_val = `lambda_V'[`ti', `ti']
		if `var_val' > 0 & `var_val' != . & `est' != . {
			local se = sqrt(`var_val')
			local zstat = `est' / `se'
			local pval = 2 * (1 - normal(abs(`zstat')))
			local stars ""
			if `pval' < 0.01      local stars "***"
			else if `pval' < 0.05 local stars "** "
			else if `pval' < 0.10 local stars "*  "
			if `pval' < 0.01 {
				di as err " {ralign 14:" %8.4f `pval' "`stars'}" _c
			}
			else if `pval' < 0.05 {
				di as res " {ralign 14:" %8.4f `pval' "`stars'}" _c
			}
			else {
				di in gr " {ralign 14:" %8.4f `pval' "`stars'}" _c
			}
		}
		else {
			di in gr " {ralign 14:     .}" _c
		}
	}
	di ""
	di in smcl in gr "{hline 78}"
	
	* --- Beta rows ---
	forvalues j = 1/`k' {
		local xvar : word `j' of `indepvars'
		
		* Coefficient row
		di in ye "  {ralign 12:`xvar'}" _c
		local b_min = .
		local b_max = .
		local ti = 0
		foreach tauval of local tau {
			local ++ti
			local bcol = (`ti' - 1) * `k' + `j'
			local est = `beta_mg'[1, `bcol']
			di as res " {ralign 14:" %10.4f `est' "}" _c
			if `est' != . {
				if `b_min' == . | `est' < `b_min' local b_min = `est'
				if `b_max' == . | `est' > `b_max' local b_max = `est'
			}
		}
		if `ntau' > 1 & `b_min' != . & `b_max' != . {
			local delta = `b_max' - `b_min'
			di in ye " {ralign 10:" %8.4f `delta' "}" _c
		}
		di ""
		
		* SE row
		di in gr "  {ralign 12:SE}" _c
		local ti = 0
		foreach tauval of local tau {
			local ++ti
			local bcol = (`ti' - 1) * `k' + `j'
			local var_val = `beta_V'[`bcol', `bcol']
			if `var_val' > 0 & `var_val' != . {
				local se = sqrt(`var_val')
				di in gr " {ralign 14:(" %8.4f `se' ")}" _c
			}
			else {
				di in gr " {ralign 14:     .}" _c
			}
		}
		di ""
		
		* z-stat row
		di in gr "  {ralign 12:z-stat}" _c
		local ti = 0
		foreach tauval of local tau {
			local ++ti
			local bcol = (`ti' - 1) * `k' + `j'
			local est = `beta_mg'[1, `bcol']
			local var_val = `beta_V'[`bcol', `bcol']
			if `var_val' > 0 & `var_val' != . & `est' != . {
				local se = sqrt(`var_val')
				local zstat = `est' / `se'
				di in gr " {ralign 14:[" %7.3f `zstat' "]}" _c
			}
			else {
				di in gr " {ralign 14:     .}" _c
			}
		}
		di ""
		
		* p-value row
		di in gr "  {ralign 12:p-value}" _c
		local ti = 0
		foreach tauval of local tau {
			local ++ti
			local bcol = (`ti' - 1) * `k' + `j'
			local est = `beta_mg'[1, `bcol']
			local var_val = `beta_V'[`bcol', `bcol']
			if `var_val' > 0 & `var_val' != . & `est' != . {
				local se = sqrt(`var_val')
				local zstat = `est' / `se'
				local pval = 2 * (1 - normal(abs(`zstat')))
				local stars ""
				if `pval' < 0.01      local stars "***"
				else if `pval' < 0.05 local stars "** "
				else if `pval' < 0.10 local stars "*  "
				if `pval' < 0.01 {
					di as err " {ralign 14:" %8.4f `pval' "`stars'}" _c
				}
				else if `pval' < 0.05 {
					di as res " {ralign 14:" %8.4f `pval' "`stars'}" _c
				}
				else {
					di in gr " {ralign 14:" %8.4f `pval' "`stars'}" _c
				}
			}
			else {
				di in gr " {ralign 14:     .}" _c
			}
		}
		di ""
		di in smcl in gr "{hline 78}"
	}
	
	di in gr "  *** p<0.01, ** p<0.05, * p<0.10"
end


* ================================================================
* TABLE A1b: CS-PQARDL Cross-Quantile Comparison
* ================================================================
capture program drop _xtcspq_adv_cspqardl_table
program define _xtcspq_adv_cspqardl_table
	syntax , TAU(numlist) DEPVAR(string) INDEPVARS(string) ///
		K(integer) LRVARS(string) [ECM]
	
	local ntau : word count `tau'
	
	* Parse LR variables
	tokenize `lrvars'
	local lr_y `1'
	mac shift
	local lr_x `*'
	local k_lrx = wordcount("`lr_x'")
	
	tempname beta_mg rho_mg beta_V rho_V
	matrix `beta_mg' = e(beta_mg)
	matrix `rho_mg' = e(rho_mg)
	matrix `beta_V' = e(beta_V)
	matrix `rho_V' = e(rho_V)
	
	di
	di in smcl in gr "{hline 78}"
	if "`ecm'" != "" {
		di in smcl in gr "  {bf:Table A1: CS-PQARDL ECM Cross-Quantile LR Coefficients}"
	}
	else {
		di in smcl in gr "  {bf:Table A1: CS-PQARDL Cross-Quantile LR Coefficients}"
	}
	di in smcl in gr "{hline 78}"
	di in gr "  {ralign 12:Variable}" _c
	foreach tauval of local tau {
		di in gr " {ralign 14:τ=" %4.2f `tauval' "}" _c
	}
	if `ntau' > 1 {
		di in gr " {ralign 10:Δ(max-min)}" _c
	}
	di ""
	di in smcl in gr "{hline 78}"
	
	* --- LR coefficient rows ---
	local vnum = 0
	foreach v of local lr_x {
		local ++vnum
		
		* Coefficient row
		di in ye "  {ralign 12:`v'}" _c
		local b_min = .
		local b_max = .
		local ti = 0
		foreach tauval of local tau {
			local ++ti
			local bcol = (`ti' - 1) * `k_lrx' + `vnum'
			local est = `beta_mg'[1, `bcol']
			if `est' != . {
				di as res " {ralign 14:" %10.4f `est' "}" _c
				if `b_min' == . | `est' < `b_min' local b_min = `est'
				if `b_max' == . | `est' > `b_max' local b_max = `est'
			}
			else {
				di in gr " {ralign 14:       n/a}" _c
			}
		}
		if `ntau' > 1 & `b_min' != . & `b_max' != . {
			local delta = `b_max' - `b_min'
			di in ye " {ralign 10:" %8.4f `delta' "}" _c
		}
		di ""
		
		* SE row
		di in gr "  {ralign 12:SE}" _c
		local ti = 0
		foreach tauval of local tau {
			local ++ti
			local bcol = (`ti' - 1) * `k_lrx' + `vnum'
			local var_val = `beta_V'[`bcol', `bcol']
			if `var_val' > 0 & `var_val' != . {
				local se = sqrt(`var_val')
				di in gr " {ralign 14:(" %8.4f `se' ")}" _c
			}
			else {
				di in gr " {ralign 14:     .}" _c
			}
		}
		di ""
		
		* z-stat row
		di in gr "  {ralign 12:z-stat}" _c
		local ti = 0
		foreach tauval of local tau {
			local ++ti
			local bcol = (`ti' - 1) * `k_lrx' + `vnum'
			local est = `beta_mg'[1, `bcol']
			local var_val = `beta_V'[`bcol', `bcol']
			if `var_val' > 0 & `var_val' != . & `est' != . {
				local se = sqrt(`var_val')
				local zstat = `est' / `se'
				di in gr " {ralign 14:[" %7.3f `zstat' "]}" _c
			}
			else {
				di in gr " {ralign 14:     .}" _c
			}
		}
		di ""
		
		* p-value row
		di in gr "  {ralign 12:p-value}" _c
		local ti = 0
		foreach tauval of local tau {
			local ++ti
			local bcol = (`ti' - 1) * `k_lrx' + `vnum'
			local est = `beta_mg'[1, `bcol']
			local var_val = `beta_V'[`bcol', `bcol']
			if `var_val' > 0 & `var_val' != . & `est' != . {
				local se = sqrt(`var_val')
				local zstat = `est' / `se'
				local pval = 2 * (1 - normal(abs(`zstat')))
				local stars ""
				if `pval' < 0.01      local stars "***"
				else if `pval' < 0.05 local stars "** "
				else if `pval' < 0.10 local stars "*  "
				if `pval' < 0.01 {
					di as err " {ralign 14:" %8.4f `pval' "`stars'}" _c
				}
				else if `pval' < 0.05 {
					di as res " {ralign 14:" %8.4f `pval' "`stars'}" _c
				}
				else {
					di in gr " {ralign 14:" %8.4f `pval' "`stars'}" _c
				}
			}
			else {
				di in gr " {ralign 14:     .}" _c
			}
		}
		di ""
		di in smcl in gr "{hline 78}"
	}
	
	* --- Rho/Phi row ---
	if "`ecm'" != "" {
		di in ye "  {ralign 12:φ(τ)}" _c
	}
	else {
		di in ye "  {ralign 12:ρ(τ)}" _c
	}
	local ti = 0
	foreach tauval of local tau {
		local ++ti
		local rval = `rho_mg'[1, `ti']
		if `rval' != . {
			if `rval' < -0.1 {
				di in ye " {ralign 14:" %10.4f `rval' "}" _c
			}
			else {
				di as err " {ralign 14:" %10.4f `rval' "}" _c
			}
		}
		else {
			di in gr " {ralign 14:       n/a}" _c
		}
	}
	di ""
	
	* SE row for rho
	di in gr "  {ralign 12:SE}" _c
	local ti = 0
	foreach tauval of local tau {
		local ++ti
		local rvar = `rho_V'[`ti', `ti']
		if `rvar' > 0 & `rvar' != . {
			local se = sqrt(`rvar')
			di in gr " {ralign 14:(" %8.4f `se' ")}" _c
		}
		else {
			di in gr " {ralign 14:     .}" _c
		}
	}
	di ""
	
	* z-stat row for rho
	di in gr "  {ralign 12:z-stat}" _c
	local ti = 0
	foreach tauval of local tau {
		local ++ti
		local rval = `rho_mg'[1, `ti']
		local rvar = `rho_V'[`ti', `ti']
		if `rvar' > 0 & `rvar' != . & `rval' != . {
			local se = sqrt(`rvar')
			local zstat = `rval' / `se'
			di in gr " {ralign 14:[" %7.3f `zstat' "]}" _c
		}
		else {
			di in gr " {ralign 14:     .}" _c
		}
	}
	di ""
	
	* p-value row for rho
	di in gr "  {ralign 12:p-value}" _c
	local ti = 0
	foreach tauval of local tau {
		local ++ti
		local rval = `rho_mg'[1, `ti']
		local rvar = `rho_V'[`ti', `ti']
		if `rvar' > 0 & `rvar' != . & `rval' != . {
			local se = sqrt(`rvar')
			local zstat = `rval' / `se'
			local pval = 2 * (1 - normal(abs(`zstat')))
			local stars ""
			if `pval' < 0.01      local stars "***"
			else if `pval' < 0.05 local stars "** "
			else if `pval' < 0.10 local stars "*  "
			if `pval' < 0.05 {
				di as err " {ralign 14:" %8.4f `pval' "`stars'}" _c
			}
			else {
				di in gr " {ralign 14:" %8.4f `pval' "`stars'}" _c
			}
		}
		else {
			di in gr " {ralign 14:     .}" _c
		}
	}
	di ""
	di in smcl in gr "{hline 78}"
	di in gr "  *** p<0.01, ** p<0.05, * p<0.10"
end


* ================================================================
* TABLE A2a: Pairwise Quantile Differences — QCCEMG
* ================================================================
capture program drop _xtcspq_adv_pairwise_qccemg
program define _xtcspq_adv_pairwise_qccemg
	syntax , TAU(numlist) INDEPVARS(string) K(integer)
	
	local ntau : word count `tau'
	if `ntau' < 2 exit
	
	tempname beta_mg beta_V lambda_mg lambda_V
	matrix `beta_mg' = e(beta_mg)
	matrix `beta_V' = e(beta_V)
	matrix `lambda_mg' = e(lambda_mg)
	matrix `lambda_V' = e(lambda_V)
	
	di
	di in smcl in gr "{hline 78}"
	di in smcl in gr "  {bf:Table A2: Pairwise Quantile Differences — z-tests}"
	di in smcl in gr "  {bf:H₀: coefficient(τ₁) = coefficient(τ₂)}"
	di in smcl in gr "{hline 78}"
	di in gr "  {ralign 14:Variable}" _c
	di in gr " {ralign 8:τ₁}" _c
	di in gr " {ralign 8:τ₂}" _c
	di in gr " {ralign 10:β(τ₁)}" _c
	di in gr " {ralign 10:β(τ₂)}" _c
	di in gr " {ralign 10:Δβ}" _c
	di in gr " {ralign 8:z-stat}" _c
	di in gr " {ralign 10:p-value}" _c
	di ""
	di in smcl in gr "{hline 78}"
	
	* Lambda pairwise
	forvalues t1 = 1/`ntau' {
		local tau1 : word `t1' of `tau'
		forvalues t2 = `= `t1'+1'/`ntau' {
			local tau2 : word `t2' of `tau'
			local lam1 = `lambda_mg'[1, `t1']
			local lam2 = `lambda_mg'[1, `t2']
			local v1 = `lambda_V'[`t1', `t1']
			local v2 = `lambda_V'[`t2', `t2']
			
			if `lam1' != . & `lam2' != . & `v1' > 0 & `v2' > 0 {
				local diff = `lam1' - `lam2'
				local se_diff = sqrt(`v1' + `v2')
				local zstat = `diff' / `se_diff'
				local pval = 2 * (1 - normal(abs(`zstat')))
				local stars ""
				if `pval' < 0.01      local stars "***"
				else if `pval' < 0.05 local stars "** "
				else if `pval' < 0.10 local stars "*  "
				
				di in ye "  {ralign 14:λ}" _c
				di in gr " {ralign 8:" %5.2f `tau1' "}" _c
				di in gr " {ralign 8:" %5.2f `tau2' "}" _c
				di as res " {ralign 10:" %8.4f `lam1' "}" _c
				di as res " {ralign 10:" %8.4f `lam2' "}" _c
				di in ye " {ralign 10:" %8.4f `diff' "}" _c
				di in gr " {ralign 8:" %6.3f `zstat' "}" _c
				if `pval' < 0.05 {
					di as err " {ralign 10:" %8.4f `pval' "}" _c
				}
				else {
					di in gr " {ralign 10:" %8.4f `pval' "}" _c
				}
				di in ye " `stars'"
			}
		}
	}
	
	* Beta pairwise
	forvalues j = 1/`k' {
		local xvar : word `j' of `indepvars'
		forvalues t1 = 1/`ntau' {
			local tau1 : word `t1' of `tau'
			forvalues t2 = `= `t1'+1'/`ntau' {
				local tau2 : word `t2' of `tau'
				local bc1 = (`t1' - 1) * `k' + `j'
				local bc2 = (`t2' - 1) * `k' + `j'
				local b1 = `beta_mg'[1, `bc1']
				local b2 = `beta_mg'[1, `bc2']
				local v1 = `beta_V'[`bc1', `bc1']
				local v2 = `beta_V'[`bc2', `bc2']
				
				if `b1' != . & `b2' != . & `v1' > 0 & `v2' > 0 {
					local diff = `b1' - `b2'
					local se_diff = sqrt(`v1' + `v2')
					local zstat = `diff' / `se_diff'
					local pval = 2 * (1 - normal(abs(`zstat')))
					local stars ""
					if `pval' < 0.01      local stars "***"
					else if `pval' < 0.05 local stars "** "
					else if `pval' < 0.10 local stars "*  "
					
					di in ye "  {ralign 14:`xvar'}" _c
					di in gr " {ralign 8:" %5.2f `tau1' "}" _c
					di in gr " {ralign 8:" %5.2f `tau2' "}" _c
					di as res " {ralign 10:" %8.4f `b1' "}" _c
					di as res " {ralign 10:" %8.4f `b2' "}" _c
					di in ye " {ralign 10:" %8.4f `diff' "}" _c
					di in gr " {ralign 8:" %6.3f `zstat' "}" _c
					if `pval' < 0.05 {
						di as err " {ralign 10:" %8.4f `pval' "}" _c
					}
					else {
						di in gr " {ralign 10:" %8.4f `pval' "}" _c
					}
					di in ye " `stars'"
				}
			}
		}
	}
	
	di in smcl in gr "{hline 78}"
	di in gr "  *** p<0.01, ** p<0.05, * p<0.10"
end


* ================================================================
* TABLE A2b: Pairwise Quantile Differences — CS-PQARDL
* ================================================================
capture program drop _xtcspq_adv_pairwise_cspqardl
program define _xtcspq_adv_pairwise_cspqardl
	syntax , TAU(numlist) INDEPVARS(string) K(integer) ///
		LRVARS(string) [ECM]
	
	local ntau : word count `tau'
	if `ntau' < 2 exit
	
	* Parse LR variables
	tokenize `lrvars'
	mac shift
	local lr_x `*'
	local k_lrx = wordcount("`lr_x'")
	
	tempname beta_mg beta_V
	matrix `beta_mg' = e(beta_mg)
	matrix `beta_V' = e(beta_V)
	
	di
	di in smcl in gr "{hline 78}"
	di in smcl in gr "  {bf:Table A2: Pairwise LR Coefficient Differences — z-tests}"
	di in smcl in gr "  {bf:H₀: β_LR(τ₁) = β_LR(τ₂)}"
	di in smcl in gr "{hline 78}"
	di in gr "  {ralign 14:Variable}" _c
	di in gr " {ralign 8:τ₁}" _c
	di in gr " {ralign 8:τ₂}" _c
	di in gr " {ralign 10:β(τ₁)}" _c
	di in gr " {ralign 10:β(τ₂)}" _c
	di in gr " {ralign 10:Δβ}" _c
	di in gr " {ralign 8:z-stat}" _c
	di in gr " {ralign 10:p-value}" _c
	di ""
	di in smcl in gr "{hline 78}"
	
	local vnum = 0
	foreach v of local lr_x {
		local ++vnum
		forvalues t1 = 1/`ntau' {
			local tau1 : word `t1' of `tau'
			forvalues t2 = `= `t1'+1'/`ntau' {
				local tau2 : word `t2' of `tau'
				local bc1 = (`t1' - 1) * `k_lrx' + `vnum'
				local bc2 = (`t2' - 1) * `k_lrx' + `vnum'
				local b1 = `beta_mg'[1, `bc1']
				local b2 = `beta_mg'[1, `bc2']
				local v1 = `beta_V'[`bc1', `bc1']
				local v2 = `beta_V'[`bc2', `bc2']
				
				if `b1' != . & `b2' != . & `v1' > 0 & `v2' > 0 {
					local diff = `b1' - `b2'
					local se_diff = sqrt(`v1' + `v2')
					local zstat = `diff' / `se_diff'
					local pval = 2 * (1 - normal(abs(`zstat')))
					local stars ""
					if `pval' < 0.01      local stars "***"
					else if `pval' < 0.05 local stars "** "
					else if `pval' < 0.10 local stars "*  "
					
					di in ye "  {ralign 14:`v'}" _c
					di in gr " {ralign 8:" %5.2f `tau1' "}" _c
					di in gr " {ralign 8:" %5.2f `tau2' "}" _c
					di as res " {ralign 10:" %8.4f `b1' "}" _c
					di as res " {ralign 10:" %8.4f `b2' "}" _c
					di in ye " {ralign 10:" %8.4f `diff' "}" _c
					di in gr " {ralign 8:" %6.3f `zstat' "}" _c
					if `pval' < 0.05 {
						di as err " {ralign 10:" %8.4f `pval' "}" _c
					}
					else {
						di in gr " {ralign 10:" %8.4f `pval' "}" _c
					}
					di in ye " `stars'"
				}
			}
		}
	}
	
	di in smcl in gr "{hline 78}"
	di in gr "  *** p<0.01, ** p<0.05, * p<0.10"
end


* ================================================================
* TABLE A3: Persistence Profile
* ================================================================
capture program drop _xtcspq_adv_persistence
program define _xtcspq_adv_persistence
	syntax , TAU(numlist) ESTIMATOR(string) [ECM]
	
	local ntau : word count `tau'
	
	di
	di in smcl in gr "{hline 78}"
	di in smcl in gr "  {bf:Table A3: Persistence Profile Across Quantiles}"
	di in smcl in gr "{hline 78}"
	
	if inlist("`estimator'", "qccemg", "qccepmg") {
		tempname lambda_mg lambda_V halflife_mg
		matrix `lambda_mg' = e(lambda_mg)
		matrix `lambda_V' = e(lambda_V)
		matrix `halflife_mg' = e(halflife_mg)
		
		di in gr "  {ralign 10:Quantile}" _c
		di in gr " {ralign 10:λ(τ)}" _c
		di in gr " {ralign 10:SE}" _c
		di in gr " {ralign 10:z-stat}" _c
		di in gr " {ralign 10:p-value}" _c
		di in gr " {ralign 10:Half-Life}" _c
		di in gr " {ralign 12:LR Mult.}"
		di in smcl in gr "{hline 78}"
		
		local ti = 0
		foreach tauval of local tau {
			local ++ti
			local lam = `lambda_mg'[1, `ti']
			local hl = `halflife_mg'[1, `ti']
			local var_val = `lambda_V'[`ti', `ti']
			
			di in gr "  {ralign 10:τ=" %4.2f `tauval' "}" _c
			
			if `lam' != . {
				di in ye " {ralign 10:" %8.4f `lam' "}" _c
				
				if `var_val' > 0 & `var_val' != . {
					local se = sqrt(`var_val')
					local zstat = `lam' / `se'
					local pval = 2 * (1 - normal(abs(`zstat')))
					di in gr " {ralign 10:" %8.4f `se' "}" _c
					di in gr " {ralign 10:" %8.3f `zstat' "}" _c
					if `pval' < 0.05 {
						di as err " {ralign 10:" %8.4f `pval' "}" _c
					}
					else {
						di in gr " {ralign 10:" %8.4f `pval' "}" _c
					}
				}
				else {
					di in gr " {ralign 10:    .}" _c
					di in gr " {ralign 10:    .}" _c
					di in gr " {ralign 10:    .}" _c
				}
				
				if `hl' != . & `hl' > 0 {
					di in ye " {ralign 10:" %8.2f `hl' "}" _c
				}
				else {
					di in gr " {ralign 10:    .}" _c
				}
				
				* LR multiplier = 1/(1-λ)
				local denom = 1 - `lam'
				if abs(`denom') > 1e-8 {
					local lr_mult = 1 / `denom'
					di in ye " {ralign 12:" %10.4f `lr_mult' "}"
				}
				else {
					di in gr " {ralign 12:    ∞}"
				}
			}
			else {
				di in gr " {ralign 10:    .} {ralign 10:    .} {ralign 10:    .}" _c
				di in gr " {ralign 10:    .} {ralign 10:    .} {ralign 12:    .}"
			}
		}
	}
	else {
		* CS-PQARDL
		tempname rho_mg rho_V halflife_mg
		matrix `rho_mg' = e(rho_mg)
		matrix `rho_V' = e(rho_V)
		matrix `halflife_mg' = e(halflife_mg)
		
		if "`ecm'" != "" {
			local rho_label "φ(τ)"
		}
		else {
			local rho_label "ρ(τ)"
		}
		
		di in gr "  {ralign 10:Quantile}" _c
		di in gr " {ralign 10:`rho_label'}" _c
		di in gr " {ralign 10:SE}" _c
		di in gr " {ralign 10:z-stat}" _c
		di in gr " {ralign 10:p-value}" _c
		di in gr " {ralign 10:Half-Life}" _c
		di in gr " {ralign 12:Status}"
		di in smcl in gr "{hline 78}"
		
		local ti = 0
		foreach tauval of local tau {
			local ++ti
			local rval = `rho_mg'[1, `ti']
			local hl = `halflife_mg'[1, `ti']
			local rvar = `rho_V'[`ti', `ti']
			
			di in gr "  {ralign 10:τ=" %4.2f `tauval' "}" _c
			
			if `rval' != . {
				if `rval' < -0.1 {
					di in ye " {ralign 10:" %8.4f `rval' "}" _c
				}
				else if `rval' < 0 {
					di in gr " {ralign 10:" %8.4f `rval' "}" _c
				}
				else {
					di as err " {ralign 10:" %8.4f `rval' "}" _c
				}
				
				if `rvar' > 0 & `rvar' != . {
					local se = sqrt(`rvar')
					local zstat = `rval' / `se'
					local pval = 2 * (1 - normal(abs(`zstat')))
					di in gr " {ralign 10:" %8.4f `se' "}" _c
					di in gr " {ralign 10:" %8.3f `zstat' "}" _c
					if `pval' < 0.05 {
						di as err " {ralign 10:" %8.4f `pval' "}" _c
					}
					else {
						di in gr " {ralign 10:" %8.4f `pval' "}" _c
					}
				}
				else {
					di in gr " {ralign 10:    .}" _c
					di in gr " {ralign 10:    .}" _c
					di in gr " {ralign 10:    .}" _c
				}
				
				if `hl' != . & `hl' > 0 {
					di in ye " {ralign 10:" %8.2f `hl' "}" _c
				}
				else {
					di in gr " {ralign 10:    .}" _c
				}
				
				if `rval' < -0.5 local status "Strong"
				else if `rval' < -0.1 local status "Moderate"
				else if `rval' < 0 local status "Weak"
				else local status "No conv."
				
				if `rval' < -0.1 {
					di in ye " {ralign 12:`status'}"
				}
				else {
					di as err " {ralign 12:`status'}"
				}
			}
			else {
				di in gr " {ralign 10:    .} {ralign 10:    .} {ralign 10:    .}" _c
				di in gr " {ralign 10:    .} {ralign 10:    .} {ralign 12:    .}"
			}
		}
	}
	
	di in smcl in gr "{hline 78}"
end


* ================================================================
* TABLE A4: QCCEMG Long-Run Effects θ(τ) = β(τ)/(1-λ(τ))
* (HLP 2018, Tables 3.3-3.6 — key reported parameter)
* ================================================================
capture program drop _xtcspq_adv_lr_effects
program define _xtcspq_adv_lr_effects
	syntax , TAU(numlist) INDEPVARS(string) K(integer) DEPVAR(string)
	
	local ntau : word count `tau'
	
	tempname theta_mg theta_V beta_mg lambda_mg
	matrix `theta_mg' = e(theta_mg)
	matrix `theta_V' = e(theta_V)
	matrix `beta_mg' = e(beta_mg)
	matrix `lambda_mg' = e(lambda_mg)
	
	di
	di in smcl in gr "{hline 78}"
	di in smcl in gr "  {bf:Table A4: QCCEMG Long-Run Effects}"
	di in smcl in gr "{hline 78}"
	di in gr "  {ralign 12:Variable} {ralign 8:τ}" _c
	di in gr " {ralign 10:β(τ)}" _c
	di in gr " {ralign 10:λ(τ)}" _c
	di in gr " {ralign 10:θ(τ)}" _c
	di in gr " {ralign 10:SE(θ)}" _c
	di in gr " {ralign 10:z-stat}" _c
	di in gr " {ralign 10:p-value}" _c
	di ""
	di in smcl in gr "{hline 78}"
	
	forvalues j = 1/`k' {
		local xvar : word `j' of `indepvars'
		local ti = 0
		foreach tauval of local tau {
			local ++ti
			local bcol = (`ti' - 1) * `k' + `j'
			local b_est = `beta_mg'[1, `bcol']
			local lam = `lambda_mg'[1, `ti']
			local theta_est = `theta_mg'[1, `bcol']
			local var_val = `theta_V'[`bcol', `bcol']
			
			if `ti' == 1 {
				di in ye "  {ralign 12:`xvar'}" _c
			}
			else {
				di in gr "  {ralign 12:}" _c
			}
			di in gr " {ralign 8:" %5.2f `tauval' "}" _c
			
			if `b_est' != . {
				di as res " {ralign 10:" %8.4f `b_est' "}" _c
			}
			else {
				di in gr " {ralign 10:    .}" _c
			}
			if `lam' != . {
				di in gr " {ralign 10:" %8.4f `lam' "}" _c
			}
			else {
				di in gr " {ralign 10:    .}" _c
			}
			
			if `theta_est' != . {
				di in ye " {ralign 10:" %8.4f `theta_est' "}" _c
				
				if `var_val' > 0 & `var_val' != . {
					local se = sqrt(`var_val')
					local zstat = `theta_est' / `se'
					local pval = 2 * (1 - normal(abs(`zstat')))
					local stars ""
					if `pval' < 0.01      local stars "***"
					else if `pval' < 0.05 local stars "** "
					else if `pval' < 0.10 local stars "*  "
					di in gr " {ralign 10:" %8.4f `se' "}" _c
					di in gr " {ralign 10:" %8.3f `zstat' "}" _c
					if `pval' < 0.05 {
						di as err " {ralign 10:" %8.4f `pval' "}" _c
					}
					else {
						di in gr " {ralign 10:" %8.4f `pval' "}" _c
					}
					di in ye " `stars'"
				}
				else {
					di in gr " {ralign 10:    .} {ralign 10:    .} {ralign 10:    .}"
				}
			}
			else {
				di in gr " {ralign 10:    .} {ralign 10:    .} {ralign 10:    .} {ralign 10:    .}"
			}
		}
		di in smcl in gr "{hline 78}"
	}
	
	di in gr "  *** p<0.01, ** p<0.05, * p<0.10"
end


* ================================================================
* TABLE A5: Cumulative Impulse Response Function
* IRF(h, τ) = β(τ) × Σ_{l=0}^{h} λ(τ)^l = β(τ) × (1-λ^{h+1})/(1-λ)
* ================================================================
capture program drop _xtcspq_adv_irf
program define _xtcspq_adv_irf
	syntax , TAU(numlist) INDEPVARS(string) K(integer)
	
	local ntau : word count `tau'
	
	tempname beta_mg lambda_mg
	matrix `beta_mg' = e(beta_mg)
	matrix `lambda_mg' = e(lambda_mg)
	
	local max_h = 10
	
	forvalues j = 1/`k' {
		local xvar : word `j' of `indepvars'
		
		di
		di in smcl in gr "{hline 78}"
		di in smcl in gr "  {bf:Table A5: Cumulative IRF — `xvar'}"
		di in smcl in gr "{hline 78}"
		di in gr "  {ralign 10:Horizon}" _c
		foreach tauval of local tau {
			di in gr " {ralign 12:τ=" %4.2f `tauval' "}" _c
		}
		di ""
		di in smcl in gr "{hline 78}"
		
		* Impact (h=0)
		di in ye "  {ralign 10:h=0 (SR)}" _c
		local ti = 0
		foreach tauval of local tau {
			local ++ti
			local bcol = (`ti' - 1) * `k' + `j'
			local b = `beta_mg'[1, `bcol']
			if `b' != . {
				di as res " {ralign 12:" %10.4f `b' "}" _c
			}
			else {
				di in gr " {ralign 12:       .}" _c
			}
		}
		di ""
		
		* Horizons h=1 to max_h
		forvalues h = 1/`max_h' {
			local hstr = string(`h')
			if `h' < 10 local hstr " `hstr'"
			di in gr "  {ralign 10:h=`hstr'}" _c
			local ti = 0
			foreach tauval of local tau {
				local ++ti
				local bcol = (`ti' - 1) * `k' + `j'
				local b = `beta_mg'[1, `bcol']
				local lam = `lambda_mg'[1, `ti']
				
				if `b' != . & `lam' != . & abs(1 - `lam') > 1e-8 {
					local lam_pow = `lam'^(`h' + 1)
					local irf = `b' * (1 - `lam_pow') / (1 - `lam')
					di as res " {ralign 12:" %10.4f `irf' "}" _c
				}
				else {
					di in gr " {ralign 12:       .}" _c
				}
			}
			di ""
		}
		
		di in smcl in gr "  {hline 40}"
		* Long-run (h → ∞)
		di in ye "  {ralign 10:h→∞ (LR)}" _c
		local ti = 0
		foreach tauval of local tau {
			local ++ti
			local bcol = (`ti' - 1) * `k' + `j'
			local b = `beta_mg'[1, `bcol']
			local lam = `lambda_mg'[1, `ti']
			if `b' != . & `lam' != . & abs(1 - `lam') > 1e-8 {
				local theta = `b' / (1 - `lam')
				di in ye " {ralign 12:" %10.4f `theta' "}" _c
			}
			else {
				di in gr " {ralign 12:       .}" _c
			}
		}
		di ""
		di in smcl in gr "{hline 78}"
	}
	
	di in gr "  *** p<0.01, ** p<0.05, * p<0.10"
end


* ================================================================
* TABLE A6a: Quantile Homogeneity Test — QCCEMG
* Joint Wald test: H₀: coef(τ₁) = coef(τ₂) = ... = coef(τ_K)
* W = (Rβ̂)' [R V̂ R']^{-1} (Rβ̂) ~ χ²(K-1)
* ================================================================
capture program drop _xtcspq_adv_homogeneity_qccemg
program define _xtcspq_adv_homogeneity_qccemg
	syntax , TAU(numlist) INDEPVARS(string) K(integer) DEPVAR(string)
	
	local ntau : word count `tau'
	if `ntau' < 2 exit
	
	local df = `ntau' - 1
	
	tempname lambda_mg lambda_V beta_mg beta_V theta_mg theta_V
	matrix `lambda_mg' = e(lambda_mg)
	matrix `lambda_V' = e(lambda_V)
	matrix `beta_mg' = e(beta_mg)
	matrix `beta_V' = e(beta_V)
	matrix `theta_mg' = e(theta_mg)
	matrix `theta_V' = e(theta_V)
	
	di
	di in smcl in gr "{hline 78}"
	di in smcl in gr "  {bf:Table A6: Quantile Slope Homogeneity Test}"
	di in smcl in gr "{hline 78}"
	di in gr "  {ralign 14:Variable}" _c
	di in gr " {ralign 10:Wald}" _c
	di in gr " {ralign 6:df}" _c
	di in gr " {ralign 10:p-value}" _c
	di in gr " {ralign 12:Result}"
	di in smcl in gr "{hline 78}"
	
	* --- Test for λ ---
	tempname R_lam d_lam V_lam Vinv_lam
	matrix `R_lam' = J(`df', `ntau', 0)
	forvalues s = 1/`df' {
		matrix `R_lam'[`s', 1] = -1
		matrix `R_lam'[`s', `= `s' + 1'] = 1
	}
	matrix `d_lam' = `R_lam' * `lambda_mg''
	matrix `V_lam' = `R_lam' * `lambda_V' * `R_lam''
	
	capture {
		matrix `Vinv_lam' = invsym(`V_lam')
		tempname W_mat_lam
		matrix `W_mat_lam' = `d_lam'' * `Vinv_lam' * `d_lam'
		local W_lam = `W_mat_lam'[1,1]
		local p_lam = chi2tail(`df', `W_lam')
	}
	if _rc == 0 & `W_lam' != . {
		local result "Reject"
		if `p_lam' >= 0.05 local result "Fail to reject"
		local stars ""
		if `p_lam' < 0.01      local stars "***"
		else if `p_lam' < 0.05 local stars "** "
		else if `p_lam' < 0.10 local stars "*  "
		di in ye "  {ralign 14:L.`depvar'}" _c
		di as res " {ralign 10:" %8.3f `W_lam' "}" _c
		di in gr " {ralign 6:`df'}" _c
		if `p_lam' < 0.05 {
			di as err " {ralign 10:" %8.4f `p_lam' "}" _c
		}
		else {
			di in gr " {ralign 10:" %8.4f `p_lam' "}" _c
		}
		di in ye " {ralign 12:`result'}" _c
		di in ye " `stars'"
	}
	
	* --- Test for each β_j ---
	forvalues j = 1/`k' {
		local xvar : word `j' of `indepvars'
		
		tempname est_vec V_diag R_b d_b V_b Vinv_b
		matrix `est_vec' = J(`ntau', 1, .)
		matrix `V_diag' = J(`ntau', `ntau', 0)
		
		forvalues t = 1/`ntau' {
			local bcol = (`t' - 1) * `k' + `j'
			matrix `est_vec'[`t', 1] = `beta_mg'[1, `bcol']
			matrix `V_diag'[`t', `t'] = `beta_V'[`bcol', `bcol']
		}
		
		matrix `R_b' = J(`df', `ntau', 0)
		forvalues s = 1/`df' {
			matrix `R_b'[`s', 1] = -1
			matrix `R_b'[`s', `= `s' + 1'] = 1
		}
		matrix `d_b' = `R_b' * `est_vec'
		matrix `V_b' = `R_b' * `V_diag' * `R_b''
		
		capture {
			matrix `Vinv_b' = invsym(`V_b')
			tempname W_mat_b
			matrix `W_mat_b' = `d_b'' * `Vinv_b' * `d_b'
			local W_b = `W_mat_b'[1,1]
			local p_b = chi2tail(`df', `W_b')
		}
		if _rc == 0 & `W_b' != . {
			local result "Reject"
			if `p_b' >= 0.05 local result "Fail to reject"
			local stars ""
			if `p_b' < 0.01      local stars "***"
			else if `p_b' < 0.05 local stars "** "
			else if `p_b' < 0.10 local stars "*  "
			di in ye "  {ralign 14:`xvar'}" _c
			di as res " {ralign 10:" %8.3f `W_b' "}" _c
			di in gr " {ralign 6:`df'}" _c
			if `p_b' < 0.05 {
				di as err " {ralign 10:" %8.4f `p_b' "}" _c
			}
			else {
				di in gr " {ralign 10:" %8.4f `p_b' "}" _c
			}
			di in ye " {ralign 12:`result'}" _c
			di in ye " `stars'"
		}
	}
	di in smcl in gr "{hline 78}"
	
	* --- Test for each θ_j (long-run) ---
	di in gr "  {it:Long-run effects:}"
	forvalues j = 1/`k' {
		local xvar : word `j' of `indepvars'
		
		tempname est_t V_t_diag R_t d_t V_t Vinv_t
		matrix `est_t' = J(`ntau', 1, .)
		matrix `V_t_diag' = J(`ntau', `ntau', 0)
		
		forvalues t = 1/`ntau' {
			local bcol = (`t' - 1) * `k' + `j'
			matrix `est_t'[`t', 1] = `theta_mg'[1, `bcol']
			matrix `V_t_diag'[`t', `t'] = `theta_V'[`bcol', `bcol']
		}
		
		matrix `R_t' = J(`df', `ntau', 0)
		forvalues s = 1/`df' {
			matrix `R_t'[`s', 1] = -1
			matrix `R_t'[`s', `= `s' + 1'] = 1
		}
		matrix `d_t' = `R_t' * `est_t'
		matrix `V_t' = `R_t' * `V_t_diag' * `R_t''
		
		capture {
			matrix `Vinv_t' = invsym(`V_t')
			tempname W_mat_t
			matrix `W_mat_t' = `d_t'' * `Vinv_t' * `d_t'
			local W_t = `W_mat_t'[1,1]
			local p_t = chi2tail(`df', `W_t')
		}
		if _rc == 0 & `W_t' != . {
			local result "Reject"
			if `p_t' >= 0.05 local result "Fail to reject"
			local stars ""
			if `p_t' < 0.01      local stars "***"
			else if `p_t' < 0.05 local stars "** "
			else if `p_t' < 0.10 local stars "*  "
			di in ye "  {ralign 14:LR(`xvar')}" _c
			di as res " {ralign 10:" %8.3f `W_t' "}" _c
			di in gr " {ralign 6:`df'}" _c
			if `p_t' < 0.05 {
				di as err " {ralign 10:" %8.4f `p_t' "}" _c
			}
			else {
				di in gr " {ralign 10:" %8.4f `p_t' "}" _c
			}
			di in ye " {ralign 12:`result'}" _c
			di in ye " `stars'"
		}
	}
	
	di in smcl in gr "{hline 78}"
	di in gr "  *** p<0.01, ** p<0.05, * p<0.10"
end


* ================================================================
* TABLE A6b: Quantile Homogeneity Test — CS-PQARDL
* ================================================================
capture program drop _xtcspq_adv_homogeneity_cspqardl
program define _xtcspq_adv_homogeneity_cspqardl
	syntax , TAU(numlist) INDEPVARS(string) K(integer) ///
		LRVARS(string) [ECM]
	
	local ntau : word count `tau'
	if `ntau' < 2 exit
	
	local df = `ntau' - 1
	
	* Parse LR variables
	tokenize `lrvars'
	mac shift
	local lr_x `*'
	local k_lrx = wordcount("`lr_x'")
	
	tempname beta_mg beta_V rho_mg rho_V
	matrix `beta_mg' = e(beta_mg)
	matrix `beta_V' = e(beta_V)
	matrix `rho_mg' = e(rho_mg)
	matrix `rho_V' = e(rho_V)
	
	if "`ecm'" != "" {
		local rho_label "phi"
	}
	else {
		local rho_label "rho"
	}
	
	di
	di in smcl in gr "{hline 78}"
	di in smcl in gr "  {bf:Table A6: Quantile Slope Homogeneity Test}"
	di in smcl in gr "{hline 78}"
	di in gr "  {ralign 14:Variable}" _c
	di in gr " {ralign 10:Wald}" _c
	di in gr " {ralign 6:df}" _c
	di in gr " {ralign 10:p-value}" _c
	di in gr " {ralign 12:Result}"
	di in smcl in gr "{hline 78}"
	
	* --- Test for each LR β_j ---
	local vnum = 0
	foreach v of local lr_x {
		local ++vnum
		
		tempname est_v V_v_diag R_v d_v V_v Vinv_v
		matrix `est_v' = J(`ntau', 1, .)
		matrix `V_v_diag' = J(`ntau', `ntau', 0)
		
		forvalues t = 1/`ntau' {
			local bcol = (`t' - 1) * `k_lrx' + `vnum'
			matrix `est_v'[`t', 1] = `beta_mg'[1, `bcol']
			matrix `V_v_diag'[`t', `t'] = `beta_V'[`bcol', `bcol']
		}
		
		matrix `R_v' = J(`df', `ntau', 0)
		forvalues s = 1/`df' {
			matrix `R_v'[`s', 1] = -1
			matrix `R_v'[`s', `= `s' + 1'] = 1
		}
		matrix `d_v' = `R_v' * `est_v'
		matrix `V_v' = `R_v' * `V_v_diag' * `R_v''
		
		capture {
			matrix `Vinv_v' = invsym(`V_v')
			tempname W_mat_v
			matrix `W_mat_v' = `d_v'' * `Vinv_v' * `d_v'
			local W_v = `W_mat_v'[1,1]
			local p_v = chi2tail(`df', `W_v')
		}
		if _rc == 0 & `W_v' != . {
			local result "Reject"
			if `p_v' >= 0.05 local result "Fail to reject"
			local stars ""
			if `p_v' < 0.01      local stars "***"
			else if `p_v' < 0.05 local stars "** "
			else if `p_v' < 0.10 local stars "*  "
			di in ye "  {ralign 14:`v'}" _c
			di as res " {ralign 10:" %8.3f `W_v' "}" _c
			di in gr " {ralign 6:`df'}" _c
			if `p_v' < 0.05 {
				di as err " {ralign 10:" %8.4f `p_v' "}" _c
			}
			else {
				di in gr " {ralign 10:" %8.4f `p_v' "}" _c
			}
			di in ye " {ralign 12:`result'}" _c
			di in ye " `stars'"
		}
	}
	
	* --- Test for ρ/φ ---
	tempname R_rho d_rho V_rho Vinv_rho
	matrix `R_rho' = J(`df', `ntau', 0)
	forvalues s = 1/`df' {
		matrix `R_rho'[`s', 1] = -1
		matrix `R_rho'[`s', `= `s' + 1'] = 1
	}
	matrix `d_rho' = `R_rho' * `rho_mg''
	matrix `V_rho' = `R_rho' * `rho_V' * `R_rho''
	
	capture {
		matrix `Vinv_rho' = invsym(`V_rho')
		tempname W_mat_rho
		matrix `W_mat_rho' = `d_rho'' * `Vinv_rho' * `d_rho'
		local W_rho = `W_mat_rho'[1,1]
		local p_rho = chi2tail(`df', `W_rho')
	}
	if _rc == 0 & `W_rho' != . {
		local result "Reject"
		if `p_rho' >= 0.05 local result "Fail to reject"
		local stars ""
		if `p_rho' < 0.01      local stars "***"
		else if `p_rho' < 0.05 local stars "** "
		else if `p_rho' < 0.10 local stars "*  "
		di in ye "  {ralign 14:`rho_label'}" _c
		di as res " {ralign 10:" %8.3f `W_rho' "}" _c
		di in gr " {ralign 6:`df'}" _c
		if `p_rho' < 0.05 {
			di as err " {ralign 10:" %8.4f `p_rho' "}" _c
		}
		else {
			di in gr " {ralign 10:" %8.4f `p_rho' "}" _c
		}
		di in ye " {ralign 12:`result'}" _c
		di in ye " `stars'"
	}
	
	di in smcl in gr "{hline 78}"
	di in gr "  *** p<0.01, ** p<0.05, * p<0.10"
end
