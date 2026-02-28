*! _xtcspqardl_ecm v1.0.0 — ECM reparameterization for CS-PQARDL
*! Error Correction Model: CSA enter the ECT only (not SR dynamics)
*! Called internally by xtcspqardl.ado
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Date: February 2026
*!
*! ECM form:
*!   Δy_it = φ_i(τ)[y_{i,t-1} - θ_i(τ)'x_{i,t-1} - δ_i(τ)'z̄_{t-1}]
*!         + Σ c_{ij}(τ) Δy_{i,t-j} + Σ d_{im}(τ) Δx_{k,i,t-m} + e_it(τ)
*!
*! CSA in ECT absorbs unobserved common factors; Δz̄ dropped from SR

capture program drop _xtcspqardl_ecm
program define _xtcspqardl_ecm, rclass
	version 15.1
	syntax , DEPVAR(string) INDEPVARS(string) ///
		P(integer) QLAGS(string) ///
		TAU(numlist >0 <1 sort) IVAR(string) TVAR(string) ///
		TOUSE(string) CSAVARS(string) [NOCONStant]
	
	* Parse
	local k : word count `indepvars'
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
	* CONSTRUCT ECM VARIABLES
	* ================================================================
	
	* --- Dependent variable: Δy_it ---
	tempvar dy_plain
	qui gen double `dy_plain' = D.`depvar' if `touse'
	
	* --- ECT level components ---
	* y_{i,t-1}
	tempvar ly_ecm
	qui gen double `ly_ecm' = L.`depvar' if `touse'
	
	* x_{k,i,t-1} for each indepvar — levels entering ECT
	local lx_ecm ""
	forvalues j = 1/`k' {
		local xvar : word `j' of `indepvars'
		tempvar lx_ecm`j'
		qui gen double `lx_ecm`j'' = L.`xvar' if `touse'
		local lx_ecm "`lx_ecm' `lx_ecm`j''"
	}
	
	* z̄_{t-1} — CSA level entering ECT (lag 0 + lagged CSA already include lags)
	* CSA vars passed are: z̄_t, z̄_{t-1}, ..., z̄_{t-pT}
	* For ECT, we want the lagged levels: L.z̄_t, L.z̄_{t-1}, ..., L.z̄_{t-pT}
	* But the CSA vars already contain contemporaneous and lags
	* In ECM form, CSA enter at level in the ECT
	local csa_ecm ""
	local ci = 0
	foreach csav of local csavars {
		local ++ci
		tempvar csa_ecm`ci'
		qui gen double `csa_ecm`ci'' = `csav' if `touse'
		local csa_ecm "`csa_ecm' `csa_ecm`ci''"
	}
	
	* --- Short-run dynamics (CSA excluded) ---
	
	* SR: ΔΔy_{i,t-j} for j = 1,...,p-1
	local sr_dy ""
	local ncoefs_ar = `p' - 1
	if `p' > 1 {
		forvalues lag = 1/`= `p' - 1' {
			tempvar ddy_lag`lag'
			qui gen double `ddy_lag`lag'' = L`lag'.`dy_plain' if `touse'
			local sr_dy "`sr_dy' `ddy_lag`lag''"
		}
	}
	
	* SR: x_{k,i,t-m} for m = 0,...,q_k-1 (user passes `dx` manually)
	local sr_dx ""
	local ncoefs_sr = 0
	forvalues j = 1/`k' {
		local xvar : word `j' of `indepvars'
		
		* Contemporaneous variable (user should pass differenced form e.g. dx)
		tempvar sr_`j'_0
		qui gen double `sr_`j'_0' = `xvar' if `touse'
		local sr_dx "`sr_dx' `sr_`j'_0'"
		local ++ncoefs_sr
		
		* Additional lags 
		if `q`j'' > 1 {
			forvalues m = 1/`= `q`j'' - 1' {
				tempvar sr_`j'_`m'
				qui gen double `sr_`j'_`m'' = L`m'.`xvar' if `touse'
				local sr_dx "`sr_dx' `sr_`j'_`m''"
				local ++ncoefs_sr
			}
		}
	}
	
	* ECT regressors: y_{t-1}, x_{k,t-1}, CSA
	local ect_regs "`ly_ecm' `lx_ecm' `csa_ecm'"
	local ncoefs_ect = 1 + `k' + `n_csa'
	
	* Full regressor list for qreg: ECT + AR SR + DL SR
	local fullreg "`ect_regs' `sr_dy' `sr_dx'"
	local ncoefs_total = `ncoefs_ect' + `ncoefs_ar' + `ncoefs_sr'
	
	* ================================================================
	* Storage matrices
	* ================================================================
	local beta_dim = `k' * `ntau'
	
	tempname phi_all beta_all theta_all halflife_all csa_all
	tempname ar_all sr_all
	
	* φ_i(τ) = coefficient on y_{i,t-1} in ECM — speed of adjustment
	matrix `phi_all' = J(`npanels', `ntau', .)
	
	* β_i(τ) = -coef(x_{k,t-1})/coef(y_{t-1}) — long-run coeff
	matrix `beta_all' = J(`npanels', max(`beta_dim',1), .)
	
	* θ_i(τ) = raw LR coefficients (x in ECT)
	matrix `theta_all' = J(`npanels', max(`beta_dim',1), .)
	
	* Half-life
	matrix `halflife_all' = J(`npanels', `ntau', .)
	
	* AR dynamics
	if `ncoefs_ar' > 0 {
		matrix `ar_all' = J(`npanels', `ncoefs_ar' * `ntau', .)
	}
	else {
		matrix `ar_all' = J(`npanels', `ntau', 0)
	}
	
	* SR dynamics
	if `ncoefs_sr' > 0 {
		matrix `sr_all' = J(`npanels', `ncoefs_sr' * `ntau', .)
	}
	else {
		matrix `sr_all' = J(1, 1, .)
	}
	
	* CSA nuisance
	matrix `csa_all' = J(`npanels', `n_csa' * `ntau', .)
	
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
			
			* Run quantile regression: Δy on ECT + SR (no CSA in SR)
			capture qui qreg `dy_plain' `fullreg' ///
				if `touse' & `ivar' == `i', quantile(`tq')
			
			if _rc != 0 & _rc != 498 {
				continue
			}
			if e(N) < 5 continue
			
			local any_tau_ok = 1
			
			tempname b_qr
			matrix `b_qr' = e(b)
			
			* φ_i(τ) = coefficient on y_{i,t-1} (first in ECT)
			local phi_val = `b_qr'[1, 1]
			matrix `phi_all'[`pi', `ti'] = `phi_val'
			
			* Half-life = ln(2)/|φ|
			if `phi_val' < 0 {
				matrix `halflife_all'[`pi', `ti'] = ln(2) / abs(`phi_val')
			}
			
			* θ_i(τ) = raw coefficient on x_{k,t-1} = b_qr[1, 1+j]
			* β_i(τ) = -θ_x / φ  (long-run multiplier)
			if abs(`phi_val') > 1e-10 {
				forvalues j = 1/`k' {
					local bcol = (`ti' - 1) * `k' + `j'
					local bpos = 1 + `j'
					local theta_val = `b_qr'[1, `bpos']
					matrix `theta_all'[`pi', `bcol'] = `theta_val'
					matrix `beta_all'[`pi', `bcol'] = -`theta_val' / `phi_val'
				}
			}
			
			* CSA nuisance coefficients in ECT
			forvalues j = 1/`n_csa' {
				local ccol = (`ti' - 1) * `n_csa' + `j'
				local bpos = 1 + `k' + `j'
				capture matrix `csa_all'[`pi', `ccol'] = `b_qr'[1, `bpos']
			}
			
			* AR lag coefficients
			if `ncoefs_ar' > 0 {
				forvalues j = 1/`ncoefs_ar' {
					local acol = (`ti' - 1) * `ncoefs_ar' + `j'
					local bpos = `ncoefs_ect' + `j'
					matrix `ar_all'[`pi', `acol'] = `b_qr'[1, `bpos']
				}
			}
			
			* SR impact coefficients
			if `ncoefs_sr' > 0 {
				forvalues j = 1/`ncoefs_sr' {
					local scol = (`ti' - 1) * `ncoefs_sr' + `j'
					local bpos = `ncoefs_ect' + `ncoefs_ar' + `j'
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
	tempname phi_mg beta_mg theta_mg halflife_mg ar_mg sr_mg csa_coef_mg
	matrix `phi_mg' = J(1, `ntau', .)
	matrix `beta_mg' = J(1, max(`beta_dim',1), .)
	matrix `theta_mg' = J(1, max(`beta_dim',1), .)
	matrix `halflife_mg' = J(1, `ntau', .)
	
	if `ncoefs_ar' > 0 {
		matrix `ar_mg' = J(1, `ncoefs_ar' * `ntau', .)
	}
	else {
		matrix `ar_mg' = J(1, `ntau', .)
	}
	if `ncoefs_sr' > 0 {
		matrix `sr_mg' = J(1, `ncoefs_sr' * `ntau', .)
	}
	else {
		matrix `sr_mg' = J(1, 1, .)
	}
	matrix `csa_coef_mg' = J(1, max(`n_csa' * `ntau', 1), .)
	
	* Phi & halflife averages
	forvalues t = 1/`ntau' {
		local cnt = 0
		local cnt_hl = 0
		local sum_p = 0
		local sum_hl = 0
		forvalues i = 1/`npanels' {
			if `phi_all'[`i', `t'] != . {
				local ++cnt
				local sum_p = `sum_p' + `phi_all'[`i', `t']
			}
			if `halflife_all'[`i', `t'] != . {
				local ++cnt_hl
				local sum_hl = `sum_hl' + `halflife_all'[`i', `t']
			}
		}
		if `cnt' > 0 matrix `phi_mg'[1, `t'] = `sum_p' / `cnt'
		if `cnt_hl' > 0 matrix `halflife_mg'[1, `t'] = `sum_hl' / `cnt_hl'
	}
	
	* Beta & theta averages
	local bdim = max(`beta_dim', 1)
	forvalues c = 1/`bdim' {
		local cnt = 0
		local sum_b = 0
		local cnt2 = 0
		local sum_t = 0
		forvalues i = 1/`npanels' {
			if `beta_all'[`i', `c'] != . {
				local ++cnt
				local sum_b = `sum_b' + `beta_all'[`i', `c']
			}
			if `theta_all'[`i', `c'] != . {
				local ++cnt2
				local sum_t = `sum_t' + `theta_all'[`i', `c']
			}
		}
		if `cnt' > 0 matrix `beta_mg'[1, `c'] = `sum_b' / `cnt'
		if `cnt2' > 0 matrix `theta_mg'[1, `c'] = `sum_t' / `cnt2'
	}
	
	* AR averages
	local ar_cols = colsof(`ar_mg')
	forvalues c = 1/`ar_cols' {
		local cnt = 0
		local sum_a = 0
		forvalues i = 1/`npanels' {
			if `ar_all'[`i', `c'] != . {
				local ++cnt
				local sum_a = `sum_a' + `ar_all'[`i', `c']
			}
		}
		if `cnt' > 0 matrix `ar_mg'[1, `c'] = `sum_a' / `cnt'
	}
	
	* SR averages
	if `ncoefs_sr' > 0 {
		local sr_dim = `ncoefs_sr' * `ntau'
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
	
	* CSA averages
	local csa_dim = `n_csa' * `ntau'
	if `csa_dim' > 0 {
		forvalues c = 1/`csa_dim' {
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
	}
	
	* ================================================================
	* MG variance
	* ================================================================
	tempname beta_V phi_V sr_V
	matrix `beta_V' = J(max(`beta_dim',1), max(`beta_dim',1), 0)
	matrix `phi_V' = J(`ntau', `ntau', 0)
	matrix `sr_V' = J(max(`ncoefs_sr' * `ntau', 1), max(`ncoefs_sr' * `ntau', 1), 0)
	
	* Beta variance: per-quantile block
	forvalues t = 1/`ntau' {
		local col_start = (`t' - 1) * `k' + 1
		local col_end = `t' * `k'
		
		if `k' < 1 continue
		
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
	
	* Phi variance: per-quantile diagonal
	forvalues t = 1/`ntau' {
		local nv = 0
		local ss = 0
		forvalues i = 1/`npanels' {
			if `phi_all'[`i', `t'] != . {
				local ++nv
				local dev = `phi_all'[`i', `t'] - `phi_mg'[1, `t']
				local ss = `ss' + `dev' * `dev'
			}
		}
		if `nv' > 1 {
			matrix `phi_V'[`t', `t'] = `ss' / (`nv' * (`nv' - 1))
		}
	}
	
	* SR variance: per-element diagonal (MG between-group variance)
	if `ncoefs_sr' > 0 {
		local sr_dim = `ncoefs_sr' * `ntau'
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
	local csa_vdim = max(`n_csa' * `ntau', 1)
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
	return scalar p = `p'
	return scalar ncoefs_sr = `ncoefs_sr'
	return scalar ncoefs_ar = `ncoefs_ar'
	return scalar n_csa = `n_csa'
	
	return matrix phi_all = `phi_all'
	return matrix beta_all = `beta_all'
	return matrix theta_all = `theta_all'
	return matrix halflife_all = `halflife_all'
	return matrix ar_all = `ar_all'
	return matrix sr_all = `sr_all'
	return matrix csa_all = `csa_all'
	
	return matrix phi_mg = `phi_mg'
	return matrix beta_mg = `beta_mg'
	return matrix theta_mg = `theta_mg'
	return matrix halflife_mg = `halflife_mg'
	return matrix ar_mg = `ar_mg'
	return matrix sr_mg = `sr_mg'
	return matrix csa_coef_mg = `csa_coef_mg'
	
	return matrix beta_V = `beta_V'
	return matrix phi_V = `phi_V'
	return matrix sr_V = `sr_V'
	return matrix csa_V = `csa_V'
end
