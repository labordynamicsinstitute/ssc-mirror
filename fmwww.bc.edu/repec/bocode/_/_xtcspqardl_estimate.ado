*! _xtcspqardl_estimate v1.0.0 — Per-panel quantile regression engine
*! CS-PQARDL: Panel Quantile ARDL with CCE augmentation
*! Called internally by xtcspqardl.ado
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Date: February 2026
*! CSA variables are added to the LR equation only

capture program drop _xtcspqardl_estimate
program define _xtcspqardl_estimate, rclass
	version 15.1
	syntax , DEPVAR(string) INDEPVARS(string) LRVARS(string) ///
		P(integer) QLAGS(string) ///
		TAU(numlist >0 <1 sort) IVAR(string) TVAR(string) ///
		TOUSE(string) CSAVARS(string) [NOCONStant]
	
	* Parse
	local k : word count `indepvars'
	local k_lr : word count `lrvars'
	local ntau : word count `tau'
	local n_csa : word count `csavars'
	
	* Parse q lags per variable
	local nqlags : word count `qlags'
	if `nqlags' == 1 {
		forvalues j = 1/`k' {
			local q`j' = `qlags'
		}
	}
	else if `nqlags' == `k' {
		forvalues j = 1/`k' {
			local q`j' : word `j' of `qlags'
		}
	}
	else {
		di as err "qlags() must have 1 or k elements"
		exit 198
	}
	
	* Get panel IDs
	qui levelsof `ivar' if `touse', local(ids)
	local npanels : word count `ids'
	
	* ================================================================
	* PRE-GENERATE ALL VARIABLES
	* ================================================================
	
	* --- Depvar ---
	tempvar dv_plain
	qui gen double `dv_plain' = `depvar' if `touse'
	local depvar_q "`dv_plain'"
	
	* --- LR variables ---
	local lr_varlist ""
	forvalues j = 1/`k_lr' {
		local lrv : word `j' of `lrvars'
		tempvar lr_plain`j'
		qui gen double `lr_plain`j'' = `lrv' if `touse'
		local lr_varlist "`lr_varlist' `lr_plain`j''"
	}
	
	* --- Contemporaneous indepvars ---
	local indep_plain ""
	forvalues j = 1/`k' {
		local xvar : word `j' of `indepvars'
		tempvar x_plain`j'
		qui gen double `x_plain`j'' = `xvar' if `touse'
		local indep_plain "`indep_plain' `x_plain`j''"
	}
	
	* --- AR lags of depvar (p-1 additional lags) ---
	local ar_varlist ""
	if `p' > 1 {
		forvalues lag = 1/`= `p' - 1' {
			tempvar ar_lag`lag'
			qui gen double `ar_lag`lag'' = L`lag'.`dv_plain' if `touse'
			local ar_varlist "`ar_varlist' `ar_lag`lag''"
		}
	}
	local ncoefs_ar = `p' - 1
	
	* --- SR impact: contemporaneous + lags of each indepvar ---
	local sr_varlist ""
	local ncoefs_sr = 0
	forvalues j = 1/`k' {
		local xvar_p : word `j' of `indep_plain'
		local sr_varlist "`sr_varlist' `xvar_p'"
		local ++ncoefs_sr
		if `q`j'' > 1 {
			forvalues lag = 1/`= `q`j'' - 1' {
				tempvar sr_`j'_lag`lag'
				qui gen double `sr_`j'_lag`lag'' = L`lag'.`xvar_p' if `touse'
				local sr_varlist "`sr_varlist' `sr_`j'_lag`lag''"
				local ++ncoefs_sr
			}
		}
	}
	
	* --- CSA variables (already generated, just create plain copies) ---
	local csa_plain ""
	local ci = 0
	foreach csav of local csavars {
		local ++ci
		tempvar csa_p`ci'
		qui gen double `csa_p`ci'' = `csav' if `touse'
		local csa_plain "`csa_plain' `csa_p`ci''"
	}
	
	* Build full regressor list: LR + AR + SR + CSA (CSA in LR equation)
	local fullreg "`lr_varlist' `ar_varlist' `sr_varlist' `csa_plain'"
	local ncoefs_lr = `k_lr'
	local ncoefs_total = `ncoefs_lr' + `ncoefs_ar' + `ncoefs_sr' + `n_csa'
	
	* ================================================================
	* Storage matrices
	* ================================================================
	local k_x = `k_lr' - 1
	local beta_dim = `k_x' * `ntau'
	local phi_dim = max(`ncoefs_ar', 1) * `ntau'
	local sr_dim = `ncoefs_sr' * `ntau'
	local csa_dim = `n_csa' * `ntau'
	
	tempname rho_all beta_all phi_all sr_all halflife_all csa_all
	
	matrix `rho_all' = J(`npanels', `ntau', .)
	matrix `beta_all' = J(`npanels', max(`beta_dim',1), .)
	matrix `halflife_all' = J(`npanels', `ntau', .)
	
	if `ncoefs_ar' > 0 {
		matrix `phi_all' = J(`npanels', `ncoefs_ar' * `ntau', .)
	}
	else {
		matrix `phi_all' = J(`npanels', `ntau', 0)
	}
	
	if `ncoefs_sr' > 0 {
		matrix `sr_all' = J(`npanels', `sr_dim', .)
	}
	else {
		matrix `sr_all' = J(1, 1, .)
	}
	
	matrix `csa_all' = J(`npanels', `csa_dim', .)
	
	* ================================================================
	* Loop over panels
	* ================================================================
	local pi = 0
	local success_count = 0
	
	foreach i of local ids {
		local ++pi
		
		qui count if `touse' & `ivar' == `i'
		local ni = r(N)
		
		if `ni' < `ncoefs_total' + 5 {
			continue
		}
		
		local any_tau_ok = 0
		local ti = 0
		
		foreach tauval of local tau {
			local ++ti
			local tq = round(`tauval' * 100)
			
			* Run quantile regression
			capture qui qreg `depvar_q' `fullreg' ///
				if `touse' & `ivar' == `i', quantile(`tq')
			
			if _rc != 0 & _rc != 498 {
				continue
			}
			if e(N) < 5 continue
			
			local any_tau_ok = 1
			
			tempname b_qr
			matrix `b_qr' = e(b)
			
			* ρ(τ) = coefficient on first LR var (lagged y level)
			matrix `rho_all'[`pi', `ti'] = `b_qr'[1, 1]
			
			* Half-life
			local rho_val = `b_qr'[1, 1]
			if `rho_val' < 0 {
				matrix `halflife_all'[`pi', `ti'] = ln(2) / abs(`rho_val')
			}
			
			* β(τ) = -coef(x_level) / coef(y_level)
			if abs(`rho_val') > 1e-10 {
				forvalues j = 2/`k_lr' {
					local bcol = (`ti' - 1) * `k_x' + (`j' - 1)
					matrix `beta_all'[`pi', `bcol'] = ///
						-`b_qr'[1, `j'] / `rho_val'
				}
			}
			
			* φ (AR lags)
			if `ncoefs_ar' > 0 {
				forvalues j = 1/`ncoefs_ar' {
					local pcol = (`ti' - 1) * `ncoefs_ar' + `j'
					local bpos = `k_lr' + `j'
					matrix `phi_all'[`pi', `pcol'] = `b_qr'[1, `bpos']
				}
			}
			
			* SR impact coefficients
			if `ncoefs_sr' > 0 {
				forvalues j = 1/`ncoefs_sr' {
					local scol = (`ti' - 1) * `ncoefs_sr' + `j'
					local bpos = `k_lr' + `ncoefs_ar' + `j'
					matrix `sr_all'[`pi', `scol'] = `b_qr'[1, `bpos']
				}
			}
			
			* CSA coefficients (nuisance)
			forvalues j = 1/`n_csa' {
				local ccol = (`ti' - 1) * `n_csa' + `j'
				local bpos = `k_lr' + `ncoefs_ar' + `ncoefs_sr' + `j'
				capture matrix `csa_all'[`pi', `ccol'] = `b_qr'[1, `bpos']
			}
		}
		
		if `any_tau_ok' {
			local ++success_count
		}
	}
	
	* ================================================================
	* Compute Mean Group averages
	* ================================================================
	tempname rho_mg beta_mg halflife_mg phi_mg sr_mg csa_coef_mg
	matrix `rho_mg' = J(1, `ntau', .)
	matrix `beta_mg' = J(1, max(`beta_dim',1), .)
	matrix `halflife_mg' = J(1, `ntau', .)
	
	if `ncoefs_ar' > 0 {
		matrix `phi_mg' = J(1, `ncoefs_ar' * `ntau', .)
	}
	else {
		matrix `phi_mg' = J(1, `ntau', .)
	}
	if `ncoefs_sr' > 0 {
		matrix `sr_mg' = J(1, `sr_dim', .)
	}
	else {
		matrix `sr_mg' = J(1, 1, .)
	}
	matrix `csa_coef_mg' = J(1, max(`csa_dim',1), .)
	
	* Rho & halflife averages
	forvalues t = 1/`ntau' {
		local cnt = 0
		local cnt_hl = 0
		local sum_r = 0
		local sum_hl = 0
		forvalues i = 1/`npanels' {
			if `rho_all'[`i', `t'] != . {
				local ++cnt
				local sum_r = `sum_r' + `rho_all'[`i', `t']
			}
			if `halflife_all'[`i', `t'] != . {
				local ++cnt_hl
				local sum_hl = `sum_hl' + `halflife_all'[`i', `t']
			}
		}
		if `cnt' > 0 matrix `rho_mg'[1, `t'] = `sum_r' / `cnt'
		if `cnt_hl' > 0 matrix `halflife_mg'[1, `t'] = `sum_hl' / `cnt_hl'
	}
	
	* Beta average
	local bdim = max(`beta_dim', 1)
	forvalues c = 1/`bdim' {
		local cnt = 0
		local sum_b = 0
		forvalues i = 1/`npanels' {
			if `beta_all'[`i', `c'] != . {
				local ++cnt
				local sum_b = `sum_b' + `beta_all'[`i', `c']
			}
		}
		if `cnt' > 0 matrix `beta_mg'[1, `c'] = `sum_b' / `cnt'
	}
	
	* Phi average
	local phi_cols = colsof(`phi_mg')
	forvalues c = 1/`phi_cols' {
		local cnt = 0
		local sum_p = 0
		forvalues i = 1/`npanels' {
			if `phi_all'[`i', `c'] != . {
				local ++cnt
				local sum_p = `sum_p' + `phi_all'[`i', `c']
			}
		}
		if `cnt' > 0 matrix `phi_mg'[1, `c'] = `sum_p' / `cnt'
	}
	
	* SR average
	if `ncoefs_sr' > 0 {
		forvalues c = 1/`sr_dim' {
			local cnt = 0
			local sum_s = 0
			forvalues i = 1/`npanels' {
				if `sr_all'[`i', `c'] != . {
					local ++cnt
					local sum_s = `sum_s' + `sr_all'[`i', `c']
				}
			}
			if `cnt' > 0 matrix `sr_mg'[1, `c'] = `sum_s' / `cnt'
		}
	}
	
	* CSA average
	local cdim = max(`csa_dim', 1)
	forvalues c = 1/`cdim' {
		local cnt = 0
		local sum_c = 0
		forvalues i = 1/`npanels' {
			if `csa_all'[`i', `c'] != . {
				local ++cnt
				local sum_c = `sum_c' + `csa_all'[`i', `c']
			}
		}
		if `cnt' > 0 matrix `csa_coef_mg'[1, `c'] = `sum_c' / `cnt'
	}
	
	* ================================================================
	* MG variance: V = (1/(N(N-1))) Σ(b_i - b̄)(b_i - b̄)'
	* ================================================================
	tempname beta_V rho_V sr_V
	matrix `beta_V' = J(max(`beta_dim',1), max(`beta_dim',1), 0)
	matrix `rho_V' = J(`ntau', `ntau', 0)
	matrix `sr_V' = J(max(`sr_dim',1), max(`sr_dim',1), 0)
	
	* Beta variance: per-quantile block
	forvalues t = 1/`ntau' {
		local col_start = (`t' - 1) * `k_x' + 1
		local col_end = `t' * `k_x'
		
		if `k_x' < 1 continue
		
		local nv = 0
		forvalues i = 1/`npanels' {
			local ok = 1
			forvalues c = `col_start'/`col_end' {
				if `beta_all'[`i', `c'] == . local ok = 0
			}
			if `ok' local ++nv
		}
		
		if `nv' > 1 {
			forvalues i = 1/`npanels' {
				local ok = 1
				forvalues c = `col_start'/`col_end' {
					if `beta_all'[`i', `c'] == . local ok = 0
				}
				if `ok' {
					forvalues r = `col_start'/`col_end' {
						forvalues c = `col_start'/`col_end' {
							local dev_r = `beta_all'[`i', `r'] - `beta_mg'[1, `r']
							local dev_c = `beta_all'[`i', `c'] - `beta_mg'[1, `c']
							matrix `beta_V'[`r', `c'] = `beta_V'[`r', `c'] + ///
								`dev_r' * `dev_c'
						}
					}
				}
			}
			local scale = 1 / (`nv' * (`nv' - 1))
			forvalues r = `col_start'/`col_end' {
				forvalues c = `col_start'/`col_end' {
					matrix `beta_V'[`r', `c'] = `scale' * `beta_V'[`r', `c']
				}
			}
		}
	}
	
	* Rho variance: per-quantile diagonal
	forvalues t = 1/`ntau' {
		local nv = 0
		local ss = 0
		forvalues i = 1/`npanels' {
			if `rho_all'[`i', `t'] != . {
				local ++nv
				local dev = `rho_all'[`i', `t'] - `rho_mg'[1, `t']
				local ss = `ss' + `dev' * `dev'
			}
		}
		if `nv' > 1 {
			matrix `rho_V'[`t', `t'] = `ss' / (`nv' * (`nv' - 1))
		}
	}
	
	* SR variance: per-element diagonal (MG between-group variance)
	if `ncoefs_sr' > 0 {
		forvalues c = 1/`sr_dim' {
			local nv = 0
			local ss = 0
			forvalues i = 1/`npanels' {
				if `sr_all'[`i', `c'] != . {
					local ++nv
					local dev = `sr_all'[`i', `c'] - `sr_mg'[1, `c']
					local ss = `ss' + `dev' * `dev'
				}
			}
			if `nv' > 1 {
				matrix `sr_V'[`c', `c'] = `ss' / (`nv' * (`nv' - 1))
			}
		}
	}
	
	* CSA variance: per-element diagonal (MG between-group variance)
	tempname csa_V
	local csa_vdim = max(`csa_dim', 1)
	matrix `csa_V' = J(`csa_vdim', `csa_vdim', 0)
	
	forvalues c = 1/`csa_vdim' {
		local nv = 0
		local ss = 0
		forvalues i = 1/`npanels' {
			if `csa_all'[`i', `c'] != . {
				local ++nv
				local dev = `csa_all'[`i', `c'] - `csa_coef_mg'[1, `c']
				local ss = `ss' + `dev' * `dev'
			}
		}
		if `nv' > 1 {
			matrix `csa_V'[`c', `c'] = `ss' / (`nv' * (`nv' - 1))
		}
	}
	
	* ================================================================
	* Return results
	* ================================================================
	return scalar npanels = `npanels'
	return scalar valid_panels = `success_count'
	return scalar ntau = `ntau'
	return scalar k = `k'
	return scalar k_lr = `k_lr'
	return scalar p = `p'
	return scalar ncoefs_sr = `ncoefs_sr'
	
	return matrix rho_all = `rho_all'
	return matrix beta_all = `beta_all'
	return matrix halflife_all = `halflife_all'
	return matrix phi_all = `phi_all'
	return matrix sr_all = `sr_all'
	return matrix csa_all = `csa_all'
	
	return matrix rho_mg = `rho_mg'
	return matrix beta_mg = `beta_mg'
	return matrix halflife_mg = `halflife_mg'
	return matrix phi_mg = `phi_mg'
	return matrix sr_mg = `sr_mg'
	return matrix csa_coef_mg = `csa_coef_mg'
	
	return matrix beta_V = `beta_V'
	return matrix rho_V = `rho_V'
	return matrix sr_V = `sr_V'
	return matrix csa_V = `csa_V'
end
