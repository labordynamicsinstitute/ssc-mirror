*! _xtqsh_estimate v1.0.0  27feb2026  Dr Merwan Roudane  merwanroudane920@gmail.com
*! Core estimation engine for xtqsh — QR Slope Homogeneity Test
*! Based on: Galvao, Juhl, Montes-Rojas & Olmo (2017) JFEC
*!           "Testing Slope Homogeneity in Quantile Regression Panel Data"

capture program drop _xtqsh_estimate
program define _xtqsh_estimate, rclass
	version 15.1
	
	syntax , dep(string) indep(string) ivar(string) tvar(string) ///
		touse(string) tau(numlist >0 <1 sort) ///
		[BW(string) HAC(integer 0) MARGinal LEVel(integer 95)]
	
	* ================================================================
	* SETUP
	* ================================================================
	
	if "`bw'" == "" local bw "hallsheather"
	
	local ntau : word count `tau'
	local k : word count `indep'
	
	* Identify panels
	tempvar grp
	qui egen `grp' = group(`ivar') if `touse'
	qui summ `grp' if `touse', meanonly
	local ng = r(max)
	
	* Panel sizes
	tempvar Ti
	qui bysort `touse' `ivar': gen `Ti' = _N if `touse'
	qui summ `Ti' if `touse', meanonly
	local Tmin = r(min)
	local Tmax = r(max)
	local Tavg = r(mean)
	
	if `Tmin' <= `k' + 1 {
		di as err "panels must have T > k+1 = `= `k'+1' observations"
		exit 2001
	}
	
	di in gr "  ► Panels: n = " in ye "`ng'" ///
		in gr ",  T(min/avg/max) = " in ye "`Tmin'/`=round(`Tavg')'/`Tmax'"
	di in gr "  ► Covariates: k = " in ye "`k'"
	di in gr "  ► Quantiles: " in ye "`ntau'"
	di in gr "  ► Bandwidth: " in ye "`bw'"
	if `hac' > 0 {
		di in gr "  ► HAC lags: " in ye "`hac'" in gr " (β-mixing)"
	}
	di
	
	* ================================================================
	* DEMEAN DATA WITHIN PANELS (absorb fixed effects)
	* ================================================================
	
	* Compute panel means using egen, then subtract
	tempvar dm_dep mean_dep
	qui egen double `mean_dep' = mean(`dep') if `touse', by(`ivar')
	qui gen double `dm_dep' = `dep' - `mean_dep' if `touse'
	drop `mean_dep'
	
	local dm_indep ""
	foreach v of local indep {
		tempvar dm_`v' mean_`v'
		qui egen double `mean_`v'' = mean(`v') if `touse', by(`ivar')
		qui gen double `dm_`v'' = `v' - `mean_`v'' if `touse'
		drop `mean_`v''
		local dm_indep "`dm_indep' `dm_`v''"
	}
	
	* Sort for by-group processing
	sort `touse' `grp' `tvar'
	
	* ================================================================
	* RESULT MATRICES
	* ================================================================
	
	tempname S_vec D_vec pS_vec pD_vec beta_md_mat beta_md_se_mat
	tempname beta_all_mat beta_ols_all
	matrix `S_vec' = J(1, `ntau', .)
	matrix `D_vec' = J(1, `ntau', .)
	matrix `pS_vec' = J(1, `ntau', .)
	matrix `pD_vec' = J(1, `ntau', .)
	matrix `beta_md_mat' = J(`ntau', `k', .)
	matrix `beta_md_se_mat' = J(`ntau', `k', .)
	matrix `beta_all_mat' = J(`ng', `k' * `ntau', .)
	matrix `beta_ols_all' = J(`ng', `k', .)
	
	if "`marginal'" != "" {
		tempname S_marg D_marg pS_marg pD_marg
		matrix `S_marg' = J(`k', `ntau', .)
		matrix `D_marg' = J(`k', `ntau', .)
		matrix `pS_marg' = J(`k', `ntau', .)
		matrix `pD_marg' = J(`k', `ntau', .)
	}
	
	* ================================================================
	* OLS (MEAN) SWAMY TEST
	* ================================================================
	
	di in gr "  Computing OLS (mean) Swamy test..."
	
	* Store individual OLS V_i inverse sums
	tempname ols_sumVinv ols_sumVinvb
	matrix `ols_sumVinv' = J(`k', `k', 0)
	matrix `ols_sumVinvb' = J(`k', 1, 0)
	
	local ols_valid = 0
	
	forvalues i = 1/`ng' {
		qui count if `touse' & `grp' == `i'
		local Ti_i = r(N)
		if `Ti_i' <= `k' continue
		
		qui capture regress `dm_dep' `dm_indep' ///
			if `touse' & `grp' == `i', noconstant
		if _rc != 0 continue
		
		local ++ols_valid
		
		tempname bols_`i' Vols_`i' Vinvols_`i'
		matrix `bols_`i'' = e(b)
		matrix `Vols_`i'' = e(V)
		matrix `beta_ols_all'[`i', 1] = `bols_`i''
		
		capture matrix `Vinvols_`i'' = syminv(`Vols_`i'')
		if _rc != 0 {
			local --ols_valid
			continue
		}
		if diag0cnt(`Vinvols_`i'') > 0 {
			local --ols_valid
			continue
		}
		
		matrix `ols_sumVinv' = `ols_sumVinv' + `Vinvols_`i''
		matrix `ols_sumVinvb' = `ols_sumVinvb' + `Vinvols_`i'' * `bols_`i'''
	}
	
	* OLS MD estimator
	tempname S_ols D_ols pS_ols pD_ols beta_ols_md
	scalar `S_ols' = .
	scalar `D_ols' = .
	scalar `pS_ols' = .
	scalar `pD_ols' = .
	
	if `ols_valid' >= 2 {
		tempname ols_inv
		capture matrix `ols_inv' = syminv(`ols_sumVinv')
		if _rc == 0 & diag0cnt(`ols_inv') == 0 {
			matrix `beta_ols_md' = (`ols_inv' * `ols_sumVinvb')'
			
			scalar `S_ols' = 0
			forvalues i = 1/`ng' {
				capture confirm matrix `Vinvols_`i''
				if _rc != 0 continue
				capture confirm matrix `bols_`i''
				if _rc != 0 continue
				
				tempname diff_ols quad_ols
				matrix `diff_ols' = `bols_`i'' - `beta_ols_md'
				matrix `quad_ols' = `diff_ols' * `Vinvols_`i'' * `diff_ols''
				scalar `S_ols' = `S_ols' + `quad_ols'[1,1]
			}
			
			local df_ols = `k' * (`ols_valid' - 1)
			scalar `D_ols' = sqrt(`ols_valid') * ///
				((1/`ols_valid') * `S_ols' - `k') / sqrt(2 * `k')
			scalar `pS_ols' = chi2tail(`df_ols', `S_ols')
			scalar `pD_ols' = 2 * (1 - normal(abs(`D_ols')))
		}
	}
	
	* Clean up OLS temp matrices
	forvalues i = 1/`ng' {
		capture matrix drop `bols_`i''
		capture matrix drop `Vols_`i''
		capture matrix drop `Vinvols_`i''
	}
	
	* ================================================================
	* LOOP OVER QUANTILES
	* ================================================================
	
	local last_valid = 0
	local ti = 0
	foreach tauval of local tau {
		local ++ti
		
		di in gr "  ► Quantile τ = " in ye %5.2f `tauval' in gr " ..." _c
		
		* Accumulators for MD estimator
		tempname qsumVinv qsumVinvb
		matrix `qsumVinv' = J(`k', `k', 0)
		matrix `qsumVinvb' = J(`k', 1, 0)
		
		local valid_panels = 0
		
		forvalues i = 1/`ng' {
			* Count obs in this panel
			qui count if `touse' & `grp' == `i'
			local Ti_i = r(N)
			if `Ti_i' <= `k' + 1 continue
			
			* ========================================================
			* STEP 1: Individual QR on raw (non-demeaned) data
			*   Per Galvao (2017) eq. 2.3: QR on (y_it, X_it)
			*   with constant (absorbs alpha_i); extract slopes
			*   If qreg fails (rc=498 at extreme τ), fall back
			*   to Mata IRLS quantile regression.
			* ========================================================
			local qr_ok = 0
			local used_qreg = 0
			qui capture qreg `dep' `indep' ///
				if `touse' & `grp' == `i', quantile(`tauval') vce(iid)
			if _rc == 0 {
				local qr_ok = 1
				local used_qreg = 1
				tempname bq_full_`i' bq_`i'
				matrix `bq_full_`i'' = e(b)
				matrix `bq_`i'' = `bq_full_`i''[1, 1..`k']
				matrix drop `bq_full_`i''
			}
			else {
				* Fallback: Mata IRLS quantile regression
				* (qreg fails at extreme τ with small T due to
				*  density/sparsity estimation failure, rc=498)
				capture mata: _xtqsh_irls_qreg( ///
					"`dep'", "`indep'", ///
					"`touse'", "`grp'", `i', ///
					`tauval', `k')
				if _rc == 0 {
					tempname bq_`i'
					matrix `bq_`i'' = r(bq_slopes)
					if `bq_`i''[1,1] != . {
						local qr_ok = 1
					}
				}
			}
			
			if `qr_ok' == 0 continue
			local ++valid_panels
			
			* Store in beta_all
			local bcol_start = (`ti' - 1) * `k' + 1
			forvalues j = 1/`k' {
				local bcol = `bcol_start' + `j' - 1
				matrix `beta_all_mat'[`i', `bcol'] = `bq_`i''[1, `j']
			}
			
			* ========================================================
			* STEP 2: Variance V̂_i  (Galvao et al. 2017, eq. 2.4)
			*   When qreg succeeded (iid): use e(V) directly
			*   When IRLS fallback or HAC: use Mata sandwich
			* ========================================================
			
			tempname V_i_`i'
			
			if `used_qreg' == 1 & `hac' == 0 {
				* --- Use Stata's e(V) directly ---
				* qreg's vce(iid) gives correctly calibrated
				* Powell sandwich at the Var(β̂_i) scale.
				* Extract k×k slope subblock (drop _cons).
				tempname Vfull_`i'
				matrix `Vfull_`i'' = e(V)
				matrix `V_i_`i'' = `Vfull_`i''[1..`k', 1..`k']
				matrix drop `Vfull_`i''
			}
			else {
				* --- Mata sandwich V̂_i (for IRLS or HAC) ---
				* Compute residuals manually from coefficients
				tempvar resid_i
				qui gen double `resid_i' = `dep' if `touse' & `grp' == `i'
				forvalues j = 1/`k' {
					local xj : word `j' of `indep'
					qui replace `resid_i' = `resid_i' ///
						- `bq_`i''[1,`j'] * `xj' ///
						if `touse' & `grp' == `i'
				}
				* Subtract the τ-th quantile as constant estimate
				qui _pctile `resid_i' ///
					if `touse' & `grp' == `i', p(`= `tauval' * 100')
				qui replace `resid_i' = `resid_i' - r(r1) ///
					if `touse' & `grp' == `i'
				
				* Bandwidth for kernel density f̂(F⁻¹(τ))
				local z_tau = invnormal(`tauval')
				local phi_z = normalden(`z_tau')
				
				if "`bw'" == "bofinger" {
					local h = `Ti_i'^(-1/5) * ///
						(4.5 * `phi_z'^4 / ///
						(2 * `z_tau'^2 + 1)^2)^(1/5)
				}
				else {
					local alpha_bw = (100 - `level') / 100
					local z_a = invnormal(1 - `alpha_bw'/2)
					local h = `Ti_i'^(-1/3) * `z_a'^(2/3) * ///
						(1.5 * `phi_z'^2 / ///
						(2 * `z_tau'^2 + 1))^(1/3)
				}
				
				if `h' <= 0 | `h' == . {
					local h = 0.05
				}
				
				mata: _xtqsh_compute_Vi_safe( ///
					"`indep'", "`resid_i'", ///
					"`touse'", "`grp'", `i', ///
					`tauval', `h', `hac', `k')
				
				* Mata returns V̂_i at O(1) scale (asymptotic var
				* of √T β̂_i), so Var(β̂_i) = V̂_i / T_i
				tempname V_mata
				matrix `V_mata' = r(V_i)
				matrix `V_i_`i'' = (1/`Ti_i') * `V_mata'
				
				capture drop `resid_i'
			}
			
			* Invert V̂_i per Galvao (2017) eq. 2.5:
			* Ŝ(τ) = Σ (β̂_i − β̂_MD)' [Var(β̂_i)]⁻¹ (β̂_i − β̂_MD)
			* V_i already stores Var(β̂_i), so just invert.
			tempname Vinv_i_`i'
			capture matrix `Vinv_i_`i'' = syminv(`V_i_`i'')
			if _rc != 0 {
				local --valid_panels
				continue
			}
			if diag0cnt(`Vinv_i_`i'') > 0 {
				local --valid_panels
				continue
			}
			
			* Accumulate for MD estimator
			matrix `qsumVinv' = `qsumVinv' + `Vinv_i_`i''
			matrix `qsumVinvb' = `qsumVinvb' + `Vinv_i_`i'' * `bq_`i'''
		}
		
		* ============================================================
		* STEP 3: MD Estimator β̂_MD(τ)
		* ============================================================
		
		if `valid_panels' < 2 {
			di in ye "  [SKIP: `valid_panels' valid panels]"
			continue
		}
		
		local last_valid = `valid_panels'
		
		tempname qinv bmd_q
		capture matrix `qinv' = syminv(`qsumVinv')
		if _rc != 0 | diag0cnt(`qinv') > 0 {
			di in ye "  [SKIP: singular]"
			continue
		}
		
		matrix `bmd_q' = (`qinv' * `qsumVinvb')'
		matrix `beta_md_mat'[`ti', 1] = `bmd_q'
		
		forvalues j = 1/`k' {
			matrix `beta_md_se_mat'[`ti', `j'] = sqrt(`qinv'[`j', `j'])
		}
		
		* ============================================================
		* STEP 4: Swamy Ŝ(τ) and D̂(τ)
		* ============================================================
		
		local S_val = 0
		forvalues i = 1/`ng' {
			capture confirm matrix `Vinv_i_`i''
			if _rc != 0 continue
			capture confirm matrix `bq_`i''
			if _rc != 0 continue
			
			tempname diff_q quad_q
			matrix `diff_q' = `bq_`i'' - `bmd_q'
			matrix `quad_q' = `diff_q' * `Vinv_i_`i'' * `diff_q''
			local S_val = `S_val' + `quad_q'[1,1]
		}
		
		local df_q = `k' * (`valid_panels' - 1)
		local D_val = sqrt(`valid_panels') * ///
			((1/`valid_panels') * `S_val' - `k') / sqrt(2 * `k')
		local pS_val = chi2tail(`df_q', `S_val')
		local pD_val = 2 * (1 - normal(abs(`D_val')))
		
		matrix `S_vec'[1, `ti'] = `S_val'
		matrix `D_vec'[1, `ti'] = `D_val'
		matrix `pS_vec'[1, `ti'] = `pS_val'
		matrix `pD_vec'[1, `ti'] = `pD_val'
		
		di in ye " Ŝ=" %10.2f `S_val' in gr " D̂=" in ye %7.3f `D_val' ///
			in gr " p(Ŝ)=" in ye %6.4f `pS_val' ///
			in gr " p(D̂)=" in ye %6.4f `pD_val'
		
		* ============================================================
		* STEP 5: Marginal Tests
		* ============================================================
		
		if "`marginal'" != "" {
			forvalues j = 1/`k' {
				local S_m = 0
				local n_m = 0
				
				forvalues i = 1/`ng' {
					capture confirm matrix `bq_`i''
					if _rc != 0 continue
					capture confirm matrix `V_i_`i''
					if _rc != 0 continue
					
					local b_ij = `bq_`i''[1, `j']
					local bmd_j = `bmd_q'[1, `j']
					local d_j = `b_ij' - `bmd_j'
					* V_i stores Var(β̂_i) directly
					local v_jj = `V_i_`i''[`j', `j']
					
					if `v_jj' <= 0 | `v_jj' == . continue
					local ++n_m
					local S_m = `S_m' + (`d_j')^2 / `v_jj'
				}
				
				if `n_m' >= 2 {
					local df_m = `n_m' - 1
					local D_m = sqrt(`n_m') * ///
						((1/`n_m') * `S_m' - 1) / sqrt(2)
					
					matrix `S_marg'[`j', `ti'] = `S_m'
					matrix `D_marg'[`j', `ti'] = `D_m'
					matrix `pS_marg'[`j', `ti'] = chi2tail(`df_m', `S_m')
					matrix `pD_marg'[`j', `ti'] = ///
						2 * (1 - normal(abs(`D_m')))
				}
			}
		}
		
		* Clean up
		forvalues i = 1/`ng' {
			capture matrix drop `bq_`i''
			capture matrix drop `V_i_`i''
			capture matrix drop `Vinv_i_`i''
		}
	}
	
	* ================================================================
	* CLEAN UP
	* ================================================================
	capture drop `dm_dep'
	foreach v of local indep {
		capture drop `dm_`v''
	}
	
	* ================================================================
	* COLUMN/ROW NAMES
	* ================================================================
	
	local tau_labels ""
	foreach tauval of local tau {
		local tl = subinstr("`tauval'", ".", "_", .)
		local tau_labels "`tau_labels' tau_`tl'"
	}
	
	matrix colnames `S_vec' = `tau_labels'
	matrix colnames `D_vec' = `tau_labels'
	matrix colnames `pS_vec' = `tau_labels'
	matrix colnames `pD_vec' = `tau_labels'
	matrix colnames `beta_md_mat' = `indep'
	matrix colnames `beta_md_se_mat' = `indep'
	
	if "`marginal'" != "" {
		matrix rownames `S_marg' = `indep'
		matrix colnames `S_marg' = `tau_labels'
		matrix rownames `D_marg' = `indep'
		matrix colnames `D_marg' = `tau_labels'
		matrix rownames `pS_marg' = `indep'
		matrix colnames `pS_marg' = `tau_labels'
		matrix rownames `pD_marg' = `indep'
		matrix colnames `pD_marg' = `tau_labels'
	}
	
	* ================================================================
	* RETURN
	* ================================================================
	
	return matrix S = `S_vec'
	return matrix D = `D_vec'
	return matrix pval_S = `pS_vec'
	return matrix pval_D = `pD_vec'
	return matrix beta_md = `beta_md_mat'
	return matrix beta_md_se = `beta_md_se_mat'
	return matrix beta_all = `beta_all_mat'
	return matrix beta_ols_all = `beta_ols_all'
	
	return scalar S_ols = `S_ols'
	return scalar D_ols = `D_ols'
	return scalar pval_S_ols = `pS_ols'
	return scalar pval_D_ols = `pD_ols'
	
	return scalar n = `ng'
	return scalar k = `k'
	return scalar ntau = `ntau'
	return scalar valid_panels = `last_valid'
	
	if "`marginal'" != "" {
		return matrix S_marginal = `S_marg'
		return matrix D_marginal = `D_marg'
		return matrix pval_S_marginal = `pS_marg'
		return matrix pval_D_marginal = `pD_marg'
	}
	
end


* ================================================================
* MATA: Compute V̂_i — safe version using selectindex
*
* Since qreg always includes a constant, the sandwich variance
* must be computed on X̃ = [X, ι] to be consistent, then the
* k×k subblock for slope parameters is extracted.
* ================================================================

version 15.1
mata:

// ================================================================
// IRLS Quantile Regression — fallback when qreg fails (rc=498)
// Uses the Hunter-Lange MM algorithm (IRLS with check function).
// Only returns coefficients (no VCE — we compute our own sandwich).
// ================================================================
void _xtqsh_irls_qreg(
	string scalar depvar,
	string scalar xvars,
	string scalar tousevar,
	string scalar grpvar,
	real scalar panel_id,
	real scalar tau,
	real scalar k)
{
	real scalar T_i, iter, maxiter, eps, converged
	real matrix X, X_raw, y_raw
	real colvector y, resid, w, b_new, b_old, sel
	real colvector touse_vec, grp_vec
	
	// Read panel data
	st_view(touse_vec = ., ., tousevar)
	st_view(grp_vec = ., ., grpvar)
	sel = selectindex((touse_vec :!= 0) :& (grp_vec :== panel_id))
	
	if (length(sel) == 0) {
		st_matrix("r(bq_slopes)", J(1, k, .))
		return
	}
	
	st_view(y_raw = ., ., depvar)
	st_view(X_raw = ., ., tokens(xvars))
	
	y = y_raw[sel]
	X = (X_raw[sel, .], J(length(sel), 1, 1))  // [X, constant]
	T_i = rows(y)
	
	if (T_i <= k + 1) {
		st_matrix("r(bq_slopes)", J(1, k, .))
		return
	}
	
	// Initialize with OLS
	b_old = invsym(cross(X, X)) * cross(X, y)
	if (hasmissing(b_old)) {
		st_matrix("r(bq_slopes)", J(1, k, .))
		return
	}
	
	// IRLS iterations
	maxiter = 200
	eps = 1e-8
	converged = 0
	
	for (iter = 1; iter <= maxiter; iter++) {
		resid = y - X * b_old
		
		// Asymmetric weights: w_t = tau/|resid| if resid > 0
		//                     w_t = (1-tau)/|resid| if resid <= 0
		// Floor |resid| to avoid division by zero
		w = J(T_i, 1, 0)
		for (j = 1; j <= T_i; j++) {
			if (abs(resid[j]) < eps) {
				w[j] = 1 / eps
			}
			else if (resid[j] > 0) {
				w[j] = tau / abs(resid[j])
			}
			else {
				w[j] = (1 - tau) / abs(resid[j])
			}
		}
		
		// Weighted least squares step
		b_new = invsym(cross(X, w, X)) * cross(X, w, y)
		if (hasmissing(b_new)) break
		
		// Check convergence
		if (mreldif(b_new, b_old) < eps) {
			converged = 1
			break
		}
		
		b_old = b_new
	}
	
	if (converged == 0 & !hasmissing(b_new)) {
		// Use last iterate even if not fully converged
		converged = 1
	}
	
	if (converged & !hasmissing(b_new)) {
		// Return only slope coefficients (first k elements)
		st_matrix("r(bq_slopes)", b_new[1..k]')
	}
	else {
		st_matrix("r(bq_slopes)", J(1, k, .))
	}
}

void _xtqsh_compute_Vi_safe(
	string scalar xvars,
	string scalar residvar,
	string scalar tousevar,
	string scalar grpvar,
	real scalar panel_id,
	real scalar tau,
	real scalar bw,
	real scalar hac_lags,
	real scalar k)
{
	real scalar T_i, j, t, kp1
	real matrix X, X_raw, X_full, C_i, Xi_i, V_full, V_i
	real colvector resid, resid_full, kernel_wt, sel
	real colvector touse_vec, grp_vec
	
	// Read full vectors
	st_view(touse_vec = ., ., tousevar)
	st_view(grp_vec = ., ., grpvar)
	
	// Select rows for this panel
	sel = selectindex((touse_vec :!= 0) :& (grp_vec :== panel_id))
	
	if (length(sel) == 0) {
		st_matrix("r(V_i)", J(k, k, .))
		return
	}
	
	// Get X and residuals for this panel
	st_view(X_full = ., ., tokens(xvars))
	st_view(resid_full = ., ., residvar)
	
	X_raw = X_full[sel, .]
	resid = resid_full[sel]
	
	T_i = rows(X_raw)
	
	if (T_i <= k) {
		st_matrix("r(V_i)", J(k, k, .))
		return
	}
	
	// Build X̃ = [X, ι] to match qreg which includes a constant
	X = (X_raw, J(T_i, 1, 1))
	kp1 = k + 1
	
	// ============================================================
	// Ĉ_i = (1/T) Σ K_h(û_it) X̃_it X̃'_it
	// Gaussian kernel: K_h(u) = (1/h)φ(u/h)
	// ============================================================
	
	kernel_wt = normalden(resid :/ bw) :/ bw
	
	// Adaptive bandwidth floor: if kernel weights collapse
	// (common at extreme τ with small T), widen to Silverman
	// rule based on residual dispersion
	if (max(kernel_wt) < 1e-6) {
		real scalar sd_r, bw_adapt
		sd_r = sqrt(variance(resid))
		if (sd_r > 0 & sd_r < .) {
			bw_adapt = 0.9 * sd_r * T_i^(-1/5)
			if (bw_adapt > bw) {
				bw = bw_adapt
				kernel_wt = normalden(resid :/ bw) :/ bw
			}
		}
	}
	
	C_i = cross(X, kernel_wt, X) / T_i
	
	// ============================================================
	// Ξ̂_i
	// ============================================================
	
	if (hac_lags == 0) {
		// i.i.d.: Ξ̂_i = τ(1−τ) · (1/T) X̃'X̃
		Xi_i = (tau * (1 - tau) / T_i) * cross(X, X)
	}
	else {
		// HAC with Bartlett kernel
		real colvector psi
		real scalar bartlett_wt
		real matrix Gamma_j
		
		psi = J(T_i, 1, tau) - (resid :<= 0)
		
		// j = 0
		Xi_i = (tau * (1 - tau) / T_i) * cross(X, X)
		
		// j = 1..m
		for (j = 1; j <= min((hac_lags, T_i - 1)); j++) {
			bartlett_wt = 1 - j / (hac_lags + 1)
			
			Gamma_j = J(kp1, kp1, 0)
			for (t = 1; t <= T_i - j; t++) {
				Gamma_j = Gamma_j + psi[t] * psi[t + j] * 
					X[t, .]' * X[t + j, .]
			}
			Gamma_j = Gamma_j / T_i
			
			Xi_i = Xi_i + bartlett_wt * (Gamma_j + Gamma_j')
		}
	}
	
	// ============================================================
	// V̂_full = Ĉ_i⁻¹ Ξ̂_i Ĉ_i⁻¹  (full (k+1)×(k+1))
	// Then extract the k×k slope subblock [1..k, 1..k]
	// ============================================================
	
	real matrix C_inv
	C_inv = invsym(C_i)
	
	if (hasmissing(C_inv)) {
		st_matrix("r(V_i)", J(k, k, .))
		return
	}
	
	V_full = C_inv * Xi_i * C_inv
	
	// Extract only slope-parameter block (rows/cols 1..k)
	V_i = V_full[1..k, 1..k]
	
	st_matrix("r(V_i)", V_i)
}
end

exit

