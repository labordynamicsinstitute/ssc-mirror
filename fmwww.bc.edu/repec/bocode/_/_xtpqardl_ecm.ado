*! _xtpqardl_ecm v1.0.1 — ECM reparameterization for Panel QARDL
*! Called internally by xtpqardl.ado
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Date: February 2026

capture program drop _xtpqardl_ecm
program define _xtpqardl_ecm, rclass
	version 15.1
	syntax varlist(ts) [if] [in], P(integer) Q(integer) ///
		TAU(numlist >0 <1 sort) IVar(string) TVar(string) ///
		[NOCONStant]
	
	marksample touse
	
	gettoken depvar indepvars : varlist
	local k : word count `indepvars'
	local ntau : word count `tau'
	
	qui levels `ivar' if `touse', local(ids)
	local npanels : word count `ids'
	
	* ================================================================
	* ECM Regression: Δy_it = α_i(τ) + ρ(τ)*ECT_{it-1}
	*                + Σ φ*_j(τ)*Δy_{it-j} + Σ θ_m(τ)*Δx_{it-m} + ε_it(τ)
	*
	* where ECT_{it-1} = y_{it-1} - β(τ)'x_{it-1}
	*       ρ(τ) = speed of adjustment at quantile τ
	* ================================================================
	
	* Build ECM regressor list
	* Dependent: D.y (first difference)
	* Regressors: L.y, x_1...x_k (for ECT via coefficient),
	*             L.D.y ... L(p-1).D.y (SR dynamics),
	*             D.x_1...D.x_k, L.D.x_1...L(q-1).D.x_k
	
	local ecm_dep "D.`depvar'"
	
	* ECT components: lagged level of y and levels of x
	local ecm_lr "L.`depvar'"
	foreach x of local indepvars {
		local ecm_lr "`ecm_lr' `x'"
	}
	
	* SR dynamics: lagged differences of y
	local ecm_sr_y ""
	if `p' > 1 {
		forvalues j = 1/`= `p' - 1' {
			local ecm_sr_y "`ecm_sr_y' L`j'D.`depvar'"
		}
	}
	
	* SR dynamics: current and lagged differences of x
	local ecm_sr_x ""
	foreach x of local indepvars {
		local ecm_sr_x "`ecm_sr_x' D.`x'"
		if `q' > 1 {
			forvalues j = 1/`= `q' - 1' {
				local ecm_sr_x "`ecm_sr_x' L`j'D.`x'"
			}
		}
	}
	
	local ecm_fullreg "`ecm_lr' `ecm_sr_y' `ecm_sr_x'"
	
	* ================================================================
	* Storage
	* ================================================================
	local rho_dim = `ntau'
	local phisr_dim = max(`p' - 1, 0) * `ntau'
	local theta_dim = `k' * `q' * `ntau'
	local beta_dim = `k' * `ntau'
	
	tempname rho_all beta_ecm_all phisr_all theta_all
	tempname halflife_all
	
	matrix `rho_all' = J(`npanels', `ntau', .)
	matrix `beta_ecm_all' = J(`npanels', `beta_dim', .)
	matrix `halflife_all' = J(`npanels', `ntau', .)
	
	if `p' > 1 {
		matrix `phisr_all' = J(`npanels', `phisr_dim', .)
	}
	matrix `theta_all' = J(`npanels', `theta_dim', .)
	
	* ================================================================
	* Loop over panels × quantiles
	* ================================================================
	local pi = 0
	foreach i of local ids {
		local ++pi
		
		qui count if `touse' & `ivar' == `i'
		local ni = r(N)
		
		if `ni' < `p' + `q' + `k' + 5 {
			continue
		}
		
		local ti = 0
		foreach tauval of local tau {
			local ++ti
			
			capture qui qreg `ecm_dep' `ecm_fullreg' ///
				if `touse' & `ivar' == `i', quantile(`= `tauval' * 100') ///
				`constant'
			
			if _rc != 0 | e(N) < 5 {
				continue
			}
			
			tempname b_ecm
			matrix `b_ecm' = e(b)
			
			* ==============================================
			* Extract ECM coefficients
			* ==============================================
			* b_ecm order: L.y, x_1...x_k, [L.D.y... L(p-1).D.y], 
			*              D.x_1...D.x_k [LD.x_1...], [_cons]
			
			* ρ(τ) — coefficient on L.y (speed of adjustment)
			matrix `rho_all'[`pi', `ti'] = `b_ecm'[1, 1]
			
			* β(τ) — long-run: -coef(x_j) / coef(L.y) 
			* In ECM form: ρ*y_{t-1} + ρ*β'x_t → β_j = -coef(x_j)/ρ
			local rho_val = `b_ecm'[1, 1]
			if abs(`rho_val') > 1e-10 {
				forvalues j = 1/`k' {
					local bcol = (`ti' - 1) * `k' + `j'
					local bpos = 1 + `j'
					matrix `beta_ecm_all'[`pi', `bcol'] = -`b_ecm'[1, `bpos'] / `rho_val'
				}
			}
			
			* Half-life: ln(2) / |ρ(τ)|
			if `rho_val' < 0 {
				matrix `halflife_all'[`pi', `ti'] = ln(2) / abs(`rho_val')
			}
			else {
				matrix `halflife_all'[`pi', `ti'] = .
			}
			
			* φ*(τ) — SR lagged diff of y
			if `p' > 1 {
				local sr_start = 1 + `k' + 1
				forvalues j = 1/`= `p' - 1' {
					local pcol = (`ti' - 1) * (`p' - 1) + `j'
					local ppos = `sr_start' + `j' - 1
					capture matrix `phisr_all'[`pi', `pcol'] = `b_ecm'[1, `ppos']
					if _rc != 0 matrix `phisr_all'[`pi', `pcol'] = .
				}
			}
			
			* θ(τ) — SR diff of x
			local th_start = 1 + `k' + 1 + max(`p' - 1, 0)
			local tidx = 0
			foreach x of local indepvars {
				forvalues lag = 0/`= `q' - 1' {
					local ++tidx
					local tcol = (`ti' - 1) * `k' * `q' + `tidx'
					local tpos = `th_start' + `tidx' - 1
					capture matrix `theta_all'[`pi', `tcol'] = `b_ecm'[1, `tpos']
					if _rc != 0 matrix `theta_all'[`pi', `tcol'] = .
				}
			}
		}
	}
	
	* ================================================================
	* Compute MG averages
	* ================================================================
	tempname rho_mg beta_ecm_mg halflife_mg theta_mg
	matrix `rho_mg' = J(1, `ntau', 0)
	matrix `beta_ecm_mg' = J(1, `beta_dim', 0)
	matrix `halflife_mg' = J(1, `ntau', 0)
	matrix `theta_mg' = J(1, `theta_dim', 0)
	
	* Count valid panels per quantile
	forvalues ti = 1/`ntau' {
		local valid_rho = 0
		local valid_hl = 0
		forvalues i = 1/`npanels' {
			if `rho_all'[`i', `ti'] != . {
				local ++valid_rho
				matrix `rho_mg'[1, `ti'] = `rho_mg'[1, `ti'] + `rho_all'[`i', `ti']
			}
			if `halflife_all'[`i', `ti'] != . {
				local ++valid_hl
				matrix `halflife_mg'[1, `ti'] = `halflife_mg'[1, `ti'] + `halflife_all'[`i', `ti']
			}
		}
		if `valid_rho' > 0 {
			matrix `rho_mg'[1, `ti'] = `rho_mg'[1, `ti'] / `valid_rho'
		}
		if `valid_hl' > 0 {
			matrix `halflife_mg'[1, `ti'] = `halflife_mg'[1, `ti'] / `valid_hl'
		}
	}
	
	* Beta and theta averages
	local valid_bt = 0
	forvalues i = 1/`npanels' {
		local has_valid = 1
		forvalues j = 1/`beta_dim' {
			if `beta_ecm_all'[`i', `j'] == . local has_valid = 0
		}
		if `has_valid' {
			local ++valid_bt
			forvalues j = 1/`beta_dim' {
				matrix `beta_ecm_mg'[1, `j'] = `beta_ecm_mg'[1, `j'] + `beta_ecm_all'[`i', `j']
			}
			forvalues j = 1/`theta_dim' {
				if `theta_all'[`i', `j'] != . {
					matrix `theta_mg'[1, `j'] = `theta_mg'[1, `j'] + `theta_all'[`i', `j']
				}
			}
		}
	}
	if `valid_bt' > 0 {
		forvalues j = 1/`beta_dim' {
			matrix `beta_ecm_mg'[1, `j'] = `beta_ecm_mg'[1, `j'] / `valid_bt'
		}
		forvalues j = 1/`theta_dim' {
			matrix `theta_mg'[1, `j'] = `theta_mg'[1, `j'] / `valid_bt'
		}
	}
	
	* ================================================================
	* Compute MG variance for ECM parameters
	* ================================================================
	tempname rho_V_mg beta_ecm_V_mg
	matrix `rho_V_mg' = J(`ntau', `ntau', 0)
	matrix `beta_ecm_V_mg' = J(`beta_dim', `beta_dim', 0)
	
	forvalues i = 1/`npanels' {
		local has_valid = 1
		forvalues j = 1/`ntau' {
			if `rho_all'[`i', `j'] == . local has_valid = 0
		}
		if `has_valid' {
			tempname dev_r
			matrix `dev_r' = `rho_all'[`i', 1..`ntau'] - `rho_mg'
			matrix `rho_V_mg' = `rho_V_mg' + `dev_r'' * `dev_r'
		}
		
		local has_valid = 1
		forvalues j = 1/`beta_dim' {
			if `beta_ecm_all'[`i', `j'] == . local has_valid = 0
		}
		if `has_valid' {
			tempname dev_be
			matrix `dev_be' = `beta_ecm_all'[`i', 1..`beta_dim'] - `beta_ecm_mg'
			matrix `beta_ecm_V_mg' = `beta_ecm_V_mg' + `dev_be'' * `dev_be'
		}
	}
	
	if `valid_bt' > 1 {
		local scale = 1 / (`valid_bt' * (`valid_bt' - 1))
		matrix `rho_V_mg' = `scale' * `rho_V_mg'
		matrix `beta_ecm_V_mg' = `scale' * `beta_ecm_V_mg'
	}
	
	* ================================================================
	* Return
	* ================================================================
	return matrix rho_all = `rho_all'
	return matrix beta_ecm_all = `beta_ecm_all'
	return matrix halflife_all = `halflife_all'
	return matrix theta_all = `theta_all'
	
	return matrix rho_mg = `rho_mg'
	return matrix beta_ecm_mg = `beta_ecm_mg'
	return matrix halflife_mg = `halflife_mg'
	return matrix theta_mg = `theta_mg'
	
	return matrix rho_V = `rho_V_mg'
	return matrix beta_ecm_V = `beta_ecm_V_mg'
	
	if `p' > 1 {
		return matrix phisr_all = `phisr_all'
	}
end
