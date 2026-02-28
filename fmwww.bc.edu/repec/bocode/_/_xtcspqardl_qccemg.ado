*! _xtcspqardl_qccemg v1.0.0 — QCCEMG Estimation Engine
*! Quantile CCE Mean Group estimator (Harding, Lamarche & Pesaran 2018)
*! Called internally by xtcspqardl.ado
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Date: February 2026
*!
*! Model (eq 2.17):
*!   y_it = α_i(τ) + λ_i(τ)·y_{i,t-1} + x'_it·β_i(τ)
*!        + Σ_{l=0}^{pT} z̄'_{t-l}·δ_{il}(τ) + e_it(τ)
*!
*! Mean Group (eq 2.21):
*!   ϑ̂(τ) = (1/N) Σ ϑ̂_i(τ), where ϑ_i = (λ_i, β'_i)'
*!
*! Variance (Theorem 4):
*!   V̂_v = (1/(N-1)) Σ (ϑ̂_i − ϑ̂)(ϑ̂_i − ϑ̂)'

capture program drop _xtcspqardl_qccemg
program define _xtcspqardl_qccemg, rclass
	version 15.1
	syntax , DEPVAR(string) INDEPVARS(string) ///
		TAU(numlist >0 <1 sort) IVAR(string) TVAR(string) ///
		TOUSE(string) CSAVARS(string) ///
		NCSAORIG(integer) CRLAGS(integer) ///
		[NOCONStant SHOWIndividual]
	
	* Parse
	local k : word count `indepvars'
	local ntau : word count `tau'
	local n_csa : word count `csavars'
	
	* Dimension of parameter of interest: ϑ = (λ, β₁, ..., β_k)
	local dim_theta = 1 + `k'
	
	* Get panel IDs
	qui levelsof `ivar' if `touse', local(ids)
	local npanels : word count `ids'
	
	* ================================================================
	* PRE-GENERATE ALL PLAIN VARIABLES  
	* (qreg does NOT support ts operators)
	* ================================================================
	
	* Dependent variable
	tempvar dv_plain
	qui gen double `dv_plain' = `depvar' if `touse'
	
	* Lagged dependent variable: y_{i,t-1}
	tempvar lag_dv
	qui gen double `lag_dv' = L.`depvar' if `touse'
	
	* Independent variables (plain copies)
	local indep_plain ""
	forvalues j = 1/`k' {
		local xvar : word `j' of `indepvars'
		tempvar x_plain`j'
		qui gen double `x_plain`j'' = `xvar' if `touse'
		local indep_plain "`indep_plain' `x_plain`j''"
	}
	
	* CSA variables (already computed, make plain copies)
	local csa_plain ""
	local ci = 0
	foreach csav of local csavars {
		local ++ci
		tempvar csa_p`ci'
		qui gen double `csa_p`ci'' = `csav' if `touse'
		local csa_plain "`csa_plain' `csa_p`ci''"
	}
	
	* Build full regressor list:
	* X_it = (y_{i,t-1}, x'_it, z̄'_t, z̄'_{t-1}, ..., z̄'_{t-pT})
	local fullreg "`lag_dv' `indep_plain' `csa_plain'"
	local ncoefs_total = 1 + `k' + `n_csa'
	
	* ================================================================
	* STORAGE MATRICES
	* ================================================================
	* Per-unit estimates of ϑ_i(τ) = (λ_i, β'_i)'
	local theta_dim = `dim_theta' * `ntau'
	
	tempname theta_all lambda_all beta_all halflife_all
	tempname delta_all
	
	* theta_all: N × (dim_theta × ntau) — all parameters of interest
	matrix `theta_all' = J(`npanels', `theta_dim', .)
	* lambda_all: N × ntau
	matrix `lambda_all' = J(`npanels', `ntau', .)
	* beta_all: N × (k × ntau)
	matrix `beta_all' = J(`npanels', `k' * `ntau', .)
	* halflife_all: N × ntau
	matrix `halflife_all' = J(`npanels', `ntau', .)
	* delta_all: N × (n_csa × ntau) — CSA nuisance coefficients
	matrix `delta_all' = J(`npanels', `n_csa' * `ntau', .)
	
	* ================================================================
	* ESTIMATION LOOP: For each unit i and quantile τ
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
			
			* ====================================================
			* Run quantile regression (eq. 2.20):
			* min Σ_t ρ_τ(y_it - X'_it π_i)
			* ====================================================
			capture qui qreg `dv_plain' `fullreg' ///
				if `touse' & `ivar' == `i', quantile(`tq')
			
			* rc=498: VCE failed but coefficients valid
			if _rc != 0 & _rc != 498 {
				continue
			}
			if e(N) < 5 continue
			
			local any_tau_ok = 1
			
			tempname b_qr
			matrix `b_qr' = e(b)
			
			* ====================================================
			* Extract ϑ_i(τ) = (λ_i(τ), β'_i(τ))'
			* Position 1: λ_i (coef on y_{i,t-1})
			* Positions 2..1+k: β_i (coefs on x_it)
			* ====================================================
			
			* λ_i(τ)
			local lambda_val = `b_qr'[1, 1]
			matrix `lambda_all'[`pi', `ti'] = `lambda_val'
			
			* Store in theta_all
			local tcol = (`ti' - 1) * `dim_theta' + 1
			matrix `theta_all'[`pi', `tcol'] = `lambda_val'
			
			* β_i(τ)
			forvalues j = 1/`k' {
				local beta_val = `b_qr'[1, 1 + `j']
				local bcol = (`ti' - 1) * `k' + `j'
				matrix `beta_all'[`pi', `bcol'] = `beta_val'
				
				local tcol = (`ti' - 1) * `dim_theta' + 1 + `j'
				matrix `theta_all'[`pi', `tcol'] = `beta_val'
			}
			
			* Half-life: h = ln(0.5) / ln(|λ|)
			if abs(`lambda_val') > 0 & abs(`lambda_val') < 1 {
				matrix `halflife_all'[`pi', `ti'] = ///
					ln(0.5) / ln(abs(`lambda_val'))
			}
			
			* δ_i(τ) — CSA nuisance coefficients
			forvalues j = 1/`n_csa' {
				local dcol = (`ti' - 1) * `n_csa' + `j'
				local bpos = 1 + `k' + `j'
				capture matrix `delta_all'[`pi', `dcol'] = `b_qr'[1, `bpos']
			}
		}
		
		if `any_tau_ok' {
			local ++success_count
		}
		
		* Show individual results if requested
		if "`showindividual'" != "" & `any_tau_ok' {
			di in gr "  Panel `i': " _c
			local ti = 0
			foreach tauval of local tau {
				local ++ti
				local lv = `lambda_all'[`pi', `ti']
				if `lv' != . {
					di in gr "λ(τ=" %4.2f `tauval' ")=" _c
					di as res %7.4f `lv' "  " _c
				}
			}
			di ""
		}
	}
	
	* ================================================================
	* MEAN GROUP AVERAGING (eq. 2.21)
	* ϑ̂(τ) = (1/N) Σ_{i=1}^{N} ϑ̂_i(τ)
	* ================================================================
	
	tempname lambda_mg beta_mg theta_mg halflife_mg
	matrix `lambda_mg' = J(1, `ntau', .)
	matrix `beta_mg' = J(1, `k' * `ntau', .)
	matrix `theta_mg' = J(1, `k' * `ntau', .)
	matrix `halflife_mg' = J(1, `ntau', .)
	
	* Lambda MG
	forvalues t = 1/`ntau' {
		local cnt = 0
		local sum_l = 0
		local sum_hl = 0
		local cnt_hl = 0
		forvalues i = 1/`npanels' {
			if `lambda_all'[`i', `t'] != . {
				local ++cnt
				local sum_l = `sum_l' + `lambda_all'[`i', `t']
			}
			if `halflife_all'[`i', `t'] != . {
				local ++cnt_hl
				local sum_hl = `sum_hl' + `halflife_all'[`i', `t']
			}
		}
		if `cnt' > 0 matrix `lambda_mg'[1, `t'] = `sum_l' / `cnt'
		if `cnt_hl' > 0 matrix `halflife_mg'[1, `t'] = `sum_hl' / `cnt_hl'
	}
	
	* Beta MG
	local bdim = `k' * `ntau'
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
	
	* Long-run effects: θ_j(τ) = β_j(τ) / (1 - λ(τ))
	forvalues t = 1/`ntau' {
		local lam = `lambda_mg'[1, `t']
		if `lam' != . {
			local denom = 1 - `lam'
			if abs(`denom') > 1e-8 {
				forvalues j = 1/`k' {
					local bcol = (`t' - 1) * `k' + `j'
					local b_val = `beta_mg'[1, `bcol']
					if `b_val' != . {
						matrix `theta_mg'[1, `bcol'] = `b_val' / `denom'
					}
				}
			}
		}
	}
	
	* ================================================================
	* INFERENCE: Nonparametric MG Variance (Theorem 4, HLP 2018)
	* V̂_v = (1/(N-1)) Σ (ϑ̂_i − ϑ̂)(ϑ̂_i − ϑ̂)'
	* Applied separately for λ and β
	* ================================================================
	
	tempname lambda_V beta_V
	matrix `lambda_V' = J(`ntau', `ntau', 0)
	matrix `beta_V' = J(`bdim', `bdim', 0)
	
	* --- Lambda variance: per-quantile diagonal ---
	forvalues t = 1/`ntau' {
		local nv = 0
		local ss = 0
		forvalues i = 1/`npanels' {
			if `lambda_all'[`i', `t'] != . {
				local ++nv
				local dev = `lambda_all'[`i', `t'] - `lambda_mg'[1, `t']
				local ss = `ss' + `dev' * `dev'
			}
		}
		if `nv' > 1 {
			matrix `lambda_V'[`t', `t'] = `ss' / (`nv' * (`nv' - 1))
		}
	}
	
	* --- Beta variance: per-quantile block ---
	forvalues t = 1/`ntau' {
		local col_start = (`t' - 1) * `k' + 1
		local col_end = `t' * `k'
		
		* Count valid panels
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
	
	* ================================================================
	* PER-UNIT LONG-RUN EFFECTS (HLP 2018, Tables 3.3-3.6)
	* θ_i(τ) = β_i(τ) / (1 - λ_i(τ))
	* MG: θ̂(τ) = (1/N) Σ θ_i(τ)
	* Var: nonparametric MG variance
	* ================================================================
	
	tempname theta_i_all theta_V
	matrix `theta_i_all' = J(`npanels', `k' * `ntau', .)
	
	* Compute per-unit long-run effects
	forvalues i = 1/`npanels' {
		forvalues t = 1/`ntau' {
			local lam_i = `lambda_all'[`i', `t']
			if `lam_i' != . {
				local denom_i = 1 - `lam_i'
				if abs(`denom_i') > 1e-8 {
					forvalues j = 1/`k' {
						local bcol = (`t' - 1) * `k' + `j'
						local b_i = `beta_all'[`i', `bcol']
						if `b_i' != . {
							matrix `theta_i_all'[`i', `bcol'] = `b_i' / `denom_i'
						}
					}
				}
			}
		}
	}
	
	* MG average of θ_i
	forvalues c = 1/`= `k' * `ntau'' {
		local cnt = 0
		local sum_t = 0
		forvalues i = 1/`npanels' {
			if `theta_i_all'[`i', `c'] != . {
				local ++cnt
				local sum_t = `sum_t' + `theta_i_all'[`i', `c']
			}
		}
		if `cnt' > 0 matrix `theta_mg'[1, `c'] = `sum_t' / `cnt'
	}
	
	* Nonparametric MG variance of θ̂
	matrix `theta_V' = J(`bdim', `bdim', 0)
	forvalues t = 1/`ntau' {
		local col_start = (`t' - 1) * `k' + 1
		local col_end = `t' * `k'
		
		local nv = 0
		forvalues i = 1/`npanels' {
			local ok = 1
			forvalues c = `col_start'/`col_end' {
				if `theta_i_all'[`i', `c'] == . local ok = 0
			}
			if `ok' local ++nv
		}
		
		if `nv' > 1 {
			forvalues i = 1/`npanels' {
				local ok = 1
				forvalues c = `col_start'/`col_end' {
					if `theta_i_all'[`i', `c'] == . local ok = 0
				}
				if `ok' {
					forvalues r = `col_start'/`col_end' {
						forvalues c = `col_start'/`col_end' {
							local dev_r = `theta_i_all'[`i', `r'] - `theta_mg'[1, `r']
							local dev_c = `theta_i_all'[`i', `c'] - `theta_mg'[1, `c']
							matrix `theta_V'[`r', `c'] = `theta_V'[`r', `c'] + ///
								`dev_r' * `dev_c'
						}
					}
				}
			}
			local scale = 1 / (`nv' * (`nv' - 1))
			forvalues r = `col_start'/`col_end' {
				forvalues c = `col_start'/`col_end' {
					matrix `theta_V'[`r', `c'] = `scale' * `theta_V'[`r', `c']
				}
			}
		}
	}
	
	* ================================================================
	* DELTA (CSA) MG AVERAGING AND VARIANCE
	* δ̂(τ) = (1/N) Σ δ̂_i(τ)
	* V̂_δ = (1/(N(N-1))) Σ (δ̂_i − δ̂)(δ̂_i − δ̂)'
	* ================================================================
	
	local delta_dim = `n_csa' * `ntau'
	tempname delta_mg delta_V
	matrix `delta_mg' = J(1, max(`delta_dim', 1), .)
	matrix `delta_V' = J(max(`delta_dim', 1), max(`delta_dim', 1), 0)
	
	* Delta MG average
	if `delta_dim' > 0 {
		forvalues c = 1/`delta_dim' {
			local cnt = 0
			local sum_d = 0
			forvalues i = 1/`npanels' {
				if `delta_all'[`i', `c'] != . {
					local ++cnt
					local sum_d = `sum_d' + `delta_all'[`i', `c']
				}
			}
			if `cnt' > 0 matrix `delta_mg'[1, `c'] = `sum_d' / `cnt'
		}
		
		* Delta MG variance: per-element diagonal
		forvalues c = 1/`delta_dim' {
			local nv = 0
			local ss = 0
			forvalues i = 1/`npanels' {
				if `delta_all'[`i', `c'] != . {
					local ++nv
					local dev = `delta_all'[`i', `c'] - `delta_mg'[1, `c']
					local ss = `ss' + `dev' * `dev'
				}
			}
			if `nv' > 1 {
				matrix `delta_V'[`c', `c'] = `ss' / (`nv' * (`nv' - 1))
			}
		}
	}
	
	* ================================================================
	* RETURN RESULTS
	* ================================================================
	return scalar npanels = `npanels'
	return scalar valid_panels = `success_count'
	return scalar ntau = `ntau'
	return scalar k = `k'
	return scalar n_csa = `n_csa'
	return scalar cr_lags = `crlags'
	return scalar dim_theta = `dim_theta'
	
	return matrix lambda_all = `lambda_all'
	return matrix beta_all = `beta_all'
	return matrix theta_all = `theta_all'
	return matrix theta_i_all = `theta_i_all'
	return matrix halflife_all = `halflife_all'
	return matrix delta_all = `delta_all'
	
	return matrix lambda_mg = `lambda_mg'
	return matrix beta_mg = `beta_mg'
	return matrix theta_mg = `theta_mg'
	return matrix halflife_mg = `halflife_mg'
	
	return matrix lambda_V = `lambda_V'
	return matrix beta_V = `beta_V'
	return matrix theta_V = `theta_V'
	return matrix delta_mg = `delta_mg'
	return matrix delta_V = `delta_V'
end
