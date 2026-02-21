*! _xtpqardl_estimate v1.0.1 — Per-panel quantile regression engine
*! Called internally by xtpqardl.ado
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Date: February 2026
*!
*! Fixed: pre-generates lagged variables to avoid qreg+tsop failures

capture program drop _xtpqardl_estimate
program define _xtpqardl_estimate, rclass
	version 15.1
	syntax , DEPVAR(string) INDEPVARS(string) LRVARS(string) ///
		P(integer) QLAGS(string) ///
		TAU(numlist >0 <1 sort) IVAR(string) TVAR(string) ///
		TOUSE(string) [NOCONStant]
	
	* Parse
	local k : word count `indepvars'
	local k_lr : word count `lrvars'
	local ntau : word count `tau'
	
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
	* PRE-GENERATE ALL VARIABLES (qreg does NOT support ts operators)
	* ================================================================
	* Convert any D./L./S. operator variables into plain temp vars.
	* This is essential because qreg rejects time-series operators.
	
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
		* Contemporaneous (already generated)
		local sr_varlist "`sr_varlist' `xvar_p'"
		local ++ncoefs_sr
		* Lags
		if `q`j'' > 1 {
			forvalues lag = 1/`= `q`j'' - 1' {
				tempvar sr_`j'_lag`lag'
				qui gen double `sr_`j'_lag`lag'' = L`lag'.`xvar_p' if `touse'
				local sr_varlist "`sr_varlist' `sr_`j'_lag`lag''"
				local ++ncoefs_sr
			}
		}
	}
	
	* Build full regressor list (all plain temp vars, no ts operators)
	local fullreg "`lr_varlist' `ar_varlist' `sr_varlist'"
	local ncoefs_lr = `k_lr'
	local ncoefs_total = `ncoefs_lr' + `ncoefs_ar' + `ncoefs_sr'
	
	* ================================================================
	* Storage matrices
	* ================================================================
	local beta_dim = (`k_lr' - 1) * `ntau'
	local phi_dim = max(`ncoefs_ar', 1) * `ntau'
	local sr_dim = `ncoefs_sr' * `ntau'
	
	tempname rho_all beta_all phi_all sr_all halflife_all
	
	matrix `rho_all' = J(`npanels', `ntau', .)
	matrix `beta_all' = J(`npanels', `beta_dim', .)
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
	
	* ================================================================
	* Loop over panels
	* ================================================================
	local pi = 0
	local success_count = 0
	local first_error = 1
	
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
			
			* Run quantile regression (no ts operators needed now)
			capture qui qreg `depvar_q' `fullreg' ///
				if `touse' & `ivar' == `i', quantile(`tq')
			
			* rc=498 means VCE failed but coefficients are valid
			* Only skip on other errors (101 = ts operators, 2000 = no obs, etc.)
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
					local bcol = (`ti' - 1) * (`k_lr' - 1) + (`j' - 1)
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
		}
		
		if `any_tau_ok' {
			local ++success_count
		}
	}
	
	* ================================================================
	* Compute Mean Group averages
	* ================================================================
	tempname rho_mg beta_mg halflife_mg phi_mg sr_mg
	matrix `rho_mg' = J(1, `ntau', .)
	matrix `beta_mg' = J(1, `beta_dim', .)
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
	
	* Average across panels (skip missing)
	forvalues t = 1/`ntau' {
		local cnt_rho = 0
		local cnt_hl = 0
		local sum_rho = 0
		local sum_hl = 0
		forvalues i = 1/`npanels' {
			if `rho_all'[`i', `t'] != . {
				local ++cnt_rho
				local sum_rho = `sum_rho' + `rho_all'[`i', `t']
			}
			if `halflife_all'[`i', `t'] != . {
				local ++cnt_hl
				local sum_hl = `sum_hl' + `halflife_all'[`i', `t']
			}
		}
		if `cnt_rho' > 0 matrix `rho_mg'[1, `t'] = `sum_rho' / `cnt_rho'
		if `cnt_hl' > 0 matrix `halflife_mg'[1, `t'] = `sum_hl' / `cnt_hl'
	}
	
	* Beta average
	forvalues c = 1/`beta_dim' {
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
	
	* ================================================================
	* MG variance: PER-QUANTILE block-diagonal computation
	* Each quantile's SE uses only panels valid at THAT quantile
	* V_t = (1/N_t(N_t-1)) Σ(b_it - b_bar_t)(b_it - b_bar_t)'
	* ================================================================
	local k_x = `k_lr' - 1
	tempname beta_V rho_V
	matrix `beta_V' = J(`beta_dim', `beta_dim', 0)
	matrix `rho_V' = J(`ntau', `ntau', 0)
	
	* --- Beta variance: per-quantile block ---
	forvalues t = 1/`ntau' {
		local col_start = (`t' - 1) * `k_x' + 1
		local col_end = `t' * `k_x'
		
		* Count valid panels at this quantile
		local nv = 0
		forvalues i = 1/`npanels' {
			local ok = 1
			forvalues c = `col_start'/`col_end' {
				if `beta_all'[`i', `c'] == . local ok = 0
			}
			if `ok' local ++nv
		}
		
		if `nv' > 1 {
			* Compute block (k_x × k_x) for this quantile
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
	
	* --- Rho variance: per-quantile diagonal ---
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
	
	* ================================================================
	* Clean up temp variables
	* ================================================================
	capture drop __xtpq_*
	
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
	
	return matrix rho_mg = `rho_mg'
	return matrix beta_mg = `beta_mg'
	return matrix halflife_mg = `halflife_mg'
	return matrix phi_mg = `phi_mg'
	return matrix sr_mg = `sr_mg'
	
	return matrix beta_V = `beta_V'
	return matrix rho_V = `rho_V'
end
