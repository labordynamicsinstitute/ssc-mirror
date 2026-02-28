*! version 1.0.0  27feb2026
*! Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)
*! xtfifevd: Fixed Effects Filtered & Vector Decomposition Estimation
*! Implements FEVD (Plumper & Troeger 2007) and FEF/FEF-IV (Pesaran & Zhou 2016)
*! Correct variance estimators following Pesaran & Zhou (2016, Econometric Reviews)

capture program drop xtfifevd
program define xtfifevd, eclass sortpreserve
	version 15.1
	if replay() {
		if ("`e(cmd)'" != "xtfifevd") error 301
		Display `0'
	}
	else Estimate `0'
end

// =============================================================================
// MAIN ESTIMATION ROUTINE
// =============================================================================

capture program drop Estimate
program define Estimate, eclass sortpreserve
	syntax varlist(ts min=2) [if] [in], 		///
		Zinvariants(varlist)					///
		[										///
		FEF									///
		IV(varlist)							///
		NOIntercept2							///
		Robust								///
		COMPare								///
		BWratio								///
		Level(integer `c(level)')				///
		REPlace								///
		]
	
	// =========================================================================
	// 1. SETUP AND VALIDATION
	// =========================================================================
	
	marksample touse
	
	// Check panel structure
	qui tsset
	local ivar `r(panelvar)'
	local tvar `r(timevar)'
	if "`ivar'" == "" {
		di as err "panel variable not set; use {bf:xtset panelid timevar}"
		exit 459
	}
	
	// Parse depvar and xvars
	gettoken depvar xvars : varlist
	
	if "`xvars'" == "" {
		di as err "at least one time-varying regressor is required"
		exit 102
	}
	
	// Validate z-invariant variables exist
	foreach z of local zinvariants {
		capture confirm variable `z'
		if _rc {
			di as err "variable `z' in zinvariants() not found"
			exit 111
		}
	}
	
	// Mark additional variables
	markout `touse' `depvar' `xvars' `zinvariants'
	if "`iv'" != "" {
		markout `touse' `iv'
	}
	
	// Determine method
	local method "FEVD"
	if "`fef'" != "" {
		local method "FEF"
	}
	if "`iv'" != "" {
		local method "FEF-IV"
		local fef "fef"
	}
	
	// Count variables
	local k_x : word count `xvars'
	local k_z : word count `zinvariants'
	if "`iv'" != "" {
		local k_iv : word count `iv'
		if `k_iv' < `k_z' {
			di as err "number of instruments (`k_iv') must be >= number of" ///
				" endogenous z-variables (`k_z')"
			exit 198
		}
	}
	
	// Count panels and observations
	qui tab `ivar' if `touse'
	local N_g = r(r)
	qui count if `touse'
	local N_obs = r(N)
	
	// Check balanced panel and get T
	tempvar Ti
	sort `ivar' `tvar'
	qui by `ivar': gen `Ti' = _N if `touse'
	qui summ `Ti' if `touse', meanonly
	local T_min = r(min)
	local T_max = r(max)
	local T_bar = r(mean)
	
	if `T_min' != `T_max' {
		di as txt "(note: unbalanced panel detected, T ranges from" ///
			" `T_min' to `T_max')"
		local T = round(`T_bar')
	}
	else {
		local T = `T_min'
	}
	
	// =========================================================================
	// 2. ESTIMATION (output is shown by Display routine)
	// =========================================================================
	
	// =========================================================================
	// 3. BETWEEN/WITHIN VARIANCE RATIO
	// =========================================================================
	
	if "`bwratio'" != "" {
		di
		di in gr "{bf:Between/Within Variance Ratios for Time-Invariant Variables}"
		di in smcl in gr "{hline 60}"
		di in gr _col(3) "Variable" _col(20) "Between SD"  ///
			_col(35) "Within SD" _col(49) "B/W Ratio"
		di in smcl in gr "{hline 60}"
		
		foreach z of local zinvariants {
			tempvar zmean zdev
			qui by `ivar': egen `zmean' = mean(`z') if `touse'
			qui summ `zmean' if `touse', detail
			local sd_between = r(sd)
			
			qui gen `zdev' = `z' - `zmean' if `touse'
			qui summ `zdev' if `touse', detail
			local sd_within = r(sd)
			
			if `sd_within' > 0 {
				local ratio = `sd_between' / `sd_within'
				di in gr _col(3) abbrev("`z'",14) ///
					_col(20) in ye %9.4f `sd_between' ///
					_col(35) in ye %9.4f `sd_within' ///
					_col(49) in ye %9.2f `ratio'
			}
			else {
				di in gr _col(3) abbrev("`z'",14) ///
					_col(20) in ye %9.4f `sd_between' ///
					_col(35) in ye %9.4f `sd_within' ///
					_col(49) in ye "       Inf"
			}
			drop `zmean' `zdev'
		}
		di in smcl in gr "{hline 60}"
		di in gr "  Note: B/W > 1.7 suggests FEVD/FEF may improve on FE"
		di in gr "        (threshold depends on corr(z,u); see Plumper & Troeger 2007)"
		di
	}
	
	// =========================================================================
	// 4. STAGE 1: FIXED EFFECTS ESTIMATION  (Pesaran-Zhou Eq. 3)
	//    Compute beta_hat_FE and residuals u_hat_it = y_it - beta_hat' x_it
	//    Then u_bar_i = T^{-1} sum_t u_hat_it  (the time-averaged FE residual)
	// =========================================================================
	

	
	// Run FE regression: y_it = alpha_i + x_it' beta + e_it
	qui xtreg `depvar' `xvars' if `touse', fe
	
	// Store FE results
	local N_fe = e(N)
	local N_g_fe = e(N_g)
	
	tempname beta_fe V_fe sigma2_e sigma2_u
	matrix `beta_fe' = e(b)
	matrix `V_fe' = e(V)
	scalar `sigma2_e' = e(sigma_e)^2
	scalar `sigma2_u' = e(sigma_u)^2
	
	// Check if _cons is in the FE coefficient vector
	local cols_fe = colsof(`beta_fe')
	local names_fe : colnames `beta_fe'
	local has_cons 0
	foreach n of local names_fe {
		if "`n'" == "_cons" local has_cons 1
	}
	
	// Get combined FE residual: u_hat_it = alpha_hat_i + e_hat_it  (Eq. 3)
	// predict, ue gives u_i + e_it = y_it - x_it'beta_hat - _cons
	tempvar uhat_it
	qui predict `uhat_it' if `touse', ue
	
	// Compute u_bar_i = T^{-1} sum_t u_hat_it  (panel time-averages)
	// This equals: y_bar_i - x_bar_i' beta_hat - _cons
	// In the cross-section regression (step 2), the intercept absorbs _cons
	tempvar ubar_i
	qui egen `ubar_i' = mean(`uhat_it') if `touse', by(`ivar')
	
	// Get FE residuals (pure idiosyncratic) for later use
	tempvar e_it
	qui predict `e_it' if `touse', e
	

	
	// =========================================================================
	// 5A. FEF ESTIMATION (2-STEP)  — Pesaran & Zhou (2016) Eq. 4-5
	//
	//  Step 2: Regress u_bar_i on z_i WITH intercept:
	//    gamma_hat_FEF = [sum (z_i-zbar)(z_i-zbar)']^{-1} sum (z_i-zbar)(ubar_i-ubar)
	//    alpha_hat_FEF = ubar - gamma_hat'_FEF * zbar
	//
	//  Variance: Eq. 17 (Pesaran-Zhou nonparametric estimator)
	//    V_hat(gamma) = N^{-1} Q_zz^{-1} [V_zz + Q_zxbar * N*Vhat(beta) * Q_xbarz] Q_zz^{-1}
	//    where V_zz = (1/N) sum (chat_i)^2 (z_i-zbar)(z_i-zbar)'   (Eq. 19)
	//    and chat_i = ybar_i - ybar - (xbar_i-xbar)'beta_hat        (Eq. 20)
	//              - (z_i-zbar)'gamma_hat_FEF
	//    Note: chat_i = OLS residuals from reg ubar_i on z with intercept (proven in audit)
	// =========================================================================
	
	if "`fef'" != "" & "`iv'" == "" {

		
		// Get one observation per panel for cross-section regression
		tempvar tag
		qui egen `tag' = tag(`ivar') if `touse'
		
		// OLS of u_bar_i on z_i with intercept → gamma_hat_FEF (Eq. 4)
		qui reg `ubar_i' `zinvariants' if `tag' == 1 & `touse'
		
		tempname gamma_fef alpha_fef
		matrix `gamma_fef' = e(b)
		scalar `alpha_fef' = `gamma_fef'[1, colsof(`gamma_fef')]
		
		// Extract z-coefficients only (exclude _cons)
		tempname gamma_z
		matrix `gamma_z' = `gamma_fef'[1, 1..`k_z']
		
		// Get chat_i residuals for V_zz (Eq. 19-20)
		// These are the OLS residuals = ubar_i - a_hat - z_i' gamma_hat
		// = (ybar_i - ybar) - (xbar_i - xbar)' beta_hat - (z_i - zbar)' gamma_hat
		tempvar chat_i
		qui predict `chat_i' if `tag' == 1 & `touse', residuals
		
		// === PESARAN-ZHOU VARIANCE (Eq. 17) ===

		
		tempname Qzz Vzz Qzxbar Vbeta V_gamma_pz
		
		// Compute Q_zz (Eq. 8), V_zz (Eq. 19), Q_zxbar (Eq. 9) via Mata
		mata: _xtfifevd_fef_variance( ///
			"`touse'", "`tag'", "`ivar'", ///
			"`zinvariants'", "`xvars'", "`chat_i'", ///
			"`Qzz'", "`Vzz'", "`Qzxbar'")
		
		// Get V_hat(beta_FE) — HC sandwich estimator (Eq. 18)
		// xtreg, fe vce(robust) gives panel-robust standard errors
		qui xtreg `depvar' `xvars' if `touse', fe vce(robust)
		matrix `Vbeta' = e(V)
		if `has_cons' {
			matrix `Vbeta' = `Vbeta'[1..`k_x', 1..`k_x']
		}
		
		// V_gamma = (1/N) * Qzz^{-1} * [Vzz + Qzxbar * N*Vbeta * Qzxbar'] * Qzz^{-1}
		// Note: N*Vbeta ≈ Omega_beta (asymptotic variance of sqrt(N)*(beta_hat - beta))
		tempname Qzz_inv mid
		matrix `Qzz_inv' = syminv(`Qzz')
		matrix `mid' = `Vzz' + `Qzxbar' * (`N_g' * `Vbeta') * `Qzxbar''
		matrix `V_gamma_pz' = (1/`N_g') * `Qzz_inv' * `mid' * `Qzz_inv'
		
		// ---- Build combined coefficient vector and variance matrix ----
		tempname b_combined V_combined beta_nc
		
		// Remove _cons from beta_fe if present
		if `has_cons' {
			matrix `beta_nc' = `beta_fe'[1, 1..`k_x']
		}
		else {
			matrix `beta_nc' = `beta_fe'
		}
		
		// b = [beta_fe, gamma_fef, alpha_fef]
		tempname alpha_sc
		matrix `alpha_sc' = J(1, 1, `alpha_fef')
		matrix `b_combined' = `beta_nc', `gamma_z', `alpha_sc'
		
		// V = block diagonal: [V_beta, V_gamma_pz, V_alpha]
		local k_total = `k_x' + `k_z' + 1
		matrix `V_combined' = J(`k_total', `k_total', 0)
		
		// Fill beta block (standard FE variance)
		qui xtreg `depvar' `xvars' if `touse', fe
		tempname Vbeta_std
		matrix `Vbeta_std' = e(V)
		if `has_cons' {
			matrix `Vbeta_std' = `Vbeta_std'[1..`k_x', 1..`k_x']
		}
		forvalues i = 1/`k_x' {
			forvalues j = 1/`k_x' {
				matrix `V_combined'[`i', `j'] = `Vbeta_std'[`i', `j']
			}
		}
		
		// Fill gamma block (Pesaran-Zhou corrected)
		forvalues i = 1/`k_z' {
			forvalues j = 1/`k_z' {
				local ri = `k_x' + `i'
				local rj = `k_x' + `j'
				matrix `V_combined'[`ri', `rj'] = `V_gamma_pz'[`i', `j']
			}
		}
		
		// Fill alpha variance (from stage 2 OLS)
		local idx_a = `k_total'
		qui reg `ubar_i' `zinvariants' if `tag' == 1 & `touse'
		local se_alpha = _se[_cons]
		matrix `V_combined'[`idx_a', `idx_a'] = `se_alpha'^2
		
		// Set equation names
		local allnames ""
		foreach x of local xvars {
			local allnames "`allnames' FE:`x'"
		}
		foreach z of local zinvariants {
			local allnames "`allnames' FEF:`z'"
		}
		local allnames "`allnames' FEF:_cons"
		
		matrix colnames `b_combined' = `allnames'
		matrix rownames `V_combined' = `allnames'
		matrix colnames `V_combined' = `allnames'
		
		// Post results
		eret post `b_combined' `V_combined', esample(`touse')
		
		eret local cmd "xtfifevd"
		eret local method "FEF"
		eret local depvar "`depvar'"
		eret local xvars "`xvars'"
		eret local zinvariants "`zinvariants'"
		eret local ivar "`ivar'"
		eret local tvar "`tvar'"
		if "`robust'" != "" {
			eret local vce "robust"
			eret local vcetype "Robust"
		}
		else {
			eret local vce "pesaran-zhou"
			eret local vcetype "PZ Robust"
		}
		eret scalar N = `N_obs'
		eret scalar N_g = `N_g'
		eret scalar T = `T'
		eret scalar T_bar = `T_bar'
		eret scalar k_x = `k_x'
		eret scalar k_z = `k_z'
		eret scalar sigma2_e = `sigma2_e'
		eret scalar sigma2_u = `sigma2_u'
		eret matrix beta_fe = `beta_nc'
		eret matrix gamma_fef = `gamma_z'
		eret matrix V_gamma_pz = `V_gamma_pz'
		
		Display, level(`level')
		drop `tag'
	}
	
	// =========================================================================
	// 5B. FEF-IV ESTIMATION — Pesaran & Zhou (2016) Eq. 48, 51
	//
	//  gamma_hat_FEF-IV = (Q_zr Q_rr^{-1} Q'_zr)^{-1} Q_zr Q_rr^{-1} Q_r_ubar
	//  = standard 2SLS of ubar_i on z_i using instruments r_i
	//
	//  Variance (Eq. 51):
	//    V_hat = N^{-1} H_zr [V_rr + Q_rxbar * N*Vhat(beta) * Q_xbarr] H'_zr
	//    H_zr = (Q_zr Q_rr^{-1} Q'_zr)^{-1} Q_zr Q_rr^{-1}
	//    V_rr = (1/N) sum (r_i-rbar)(r_i-rbar)' (upsilon_hat_i)^2
	//    upsilon_hat_i = ubar_i - a_hat - z_i' gamma_hat_IV
	// =========================================================================
	
	else if "`iv'" != "" {

		
		tempvar tag
		qui egen `tag' = tag(`ivar') if `touse'
		
		// 2SLS of ubar_i on z_i using instruments r_i (Eq. 48)
		qui ivregress 2sls `ubar_i' (`zinvariants' = `iv') if `tag' == 1 & `touse'
		
		tempname gamma_iv alpha_iv
		matrix `gamma_iv' = e(b)
		scalar `alpha_iv' = `gamma_iv'[1, colsof(`gamma_iv')]
		
		tempname gamma_z_iv
		matrix `gamma_z_iv' = `gamma_iv'[1, 1..`k_z']
		
		// Get IV residuals: upsilon_hat_i = ubar_i - a_hat - z_i' gamma_hat_IV
		tempvar upsilon_i
		qui predict `upsilon_i' if `tag' == 1 & `touse', residuals
		
		// === PESARAN-ZHOU FEF-IV VARIANCE (Eq. 51) ===

		
		tempname Qzr Qrr Qrxbar Vrr Vbeta Hzr V_gamma_iv_pz
		
		// Compute Q_zr, Q_rr, Q_rxbar, V_rr via Mata
		mata: _xtfifevd_fefiv_variance( ///
			"`touse'", "`tag'", "`ivar'", ///
			"`zinvariants'", "`iv'", "`xvars'", "`upsilon_i'", ///
			"`Qzr'", "`Qrr'", "`Qrxbar'", "`Vrr'")
		
		// HC sandwich V_hat(beta_FE) (Eq. 18)
		qui xtreg `depvar' `xvars' if `touse', fe vce(robust)
		matrix `Vbeta' = e(V)
		if `has_cons' {
			matrix `Vbeta' = `Vbeta'[1..`k_x', 1..`k_x']
		}
		
		// H_zr = (Q_zr * Q_rr^{-1} * Q_zr')^{-1} * Q_zr * Q_rr^{-1}
		tempname Qrr_inv mid_iv
		matrix `Qrr_inv' = syminv(`Qrr')
		matrix `Hzr' = syminv(`Qzr' * `Qrr_inv' * `Qzr'') * `Qzr' * `Qrr_inv'
		
		// V = (1/N) * H_zr * [V_rr + Q_rxbar * N*V(beta) * Q_rxbar'] * H_zr'
		matrix `mid_iv' = `Vrr' + `Qrxbar' * (`N_g' * `Vbeta') * `Qrxbar''
		matrix `V_gamma_iv_pz' = (1/`N_g') * `Hzr' * `mid_iv' * `Hzr''
		
		// ---- Build combined results ----
		tempname b_combined V_combined beta_nc
		if `has_cons' {
			matrix `beta_nc' = `beta_fe'[1, 1..`k_x']
		}
		else {
			matrix `beta_nc' = `beta_fe'
		}
		
		tempname alpha_sc
		matrix `alpha_sc' = J(1, 1, `alpha_iv')
		matrix `b_combined' = `beta_nc', `gamma_z_iv', `alpha_sc'
		
		local k_total = `k_x' + `k_z' + 1
		matrix `V_combined' = J(`k_total', `k_total', 0)
		
		// Fill beta block
		qui xtreg `depvar' `xvars' if `touse', fe
		tempname Vbeta_std
		matrix `Vbeta_std' = e(V)
		if `has_cons' {
			matrix `Vbeta_std' = `Vbeta_std'[1..`k_x', 1..`k_x']
		}
		forvalues i = 1/`k_x' {
			forvalues j = 1/`k_x' {
				matrix `V_combined'[`i', `j'] = `Vbeta_std'[`i', `j']
			}
		}
		
		// Fill gamma block (Pesaran-Zhou FEF-IV)
		forvalues i = 1/`k_z' {
			forvalues j = 1/`k_z' {
				local ri = `k_x' + `i'
				local rj = `k_x' + `j'
				matrix `V_combined'[`ri', `rj'] = `V_gamma_iv_pz'[`i', `j']
			}
		}
		
		// Alpha variance
		local idx_a = `k_total'
		qui ivregress 2sls `ubar_i' (`zinvariants' = `iv') if `tag' == 1 & `touse'
		local se_alpha = _se[_cons]
		matrix `V_combined'[`idx_a', `idx_a'] = `se_alpha'^2
		
		// Names
		local allnames ""
		foreach x of local xvars {
			local allnames "`allnames' FE:`x'"
		}
		foreach z of local zinvariants {
			local allnames "`allnames' FEF_IV:`z'"
		}
		local allnames "`allnames' FEF_IV:_cons"
		
		matrix colnames `b_combined' = `allnames'
		matrix rownames `V_combined' = `allnames'
		matrix colnames `V_combined' = `allnames'
		
		eret post `b_combined' `V_combined', esample(`touse')
		
		eret local cmd "xtfifevd"
		eret local method "FEF-IV"
		eret local depvar "`depvar'"
		eret local xvars "`xvars'"
		eret local zinvariants "`zinvariants'"
		eret local instruments "`iv'"
		eret local ivar "`ivar'"
		eret local tvar "`tvar'"
		if "`robust'" != "" {
			eret local vce "robust"
			eret local vcetype "Robust"
		}
		else {
			eret local vce "pesaran-zhou"
			eret local vcetype "PZ Robust"
		}
		eret scalar N = `N_obs'
		eret scalar N_g = `N_g'
		eret scalar T = `T'
		eret scalar T_bar = `T_bar'
		eret scalar k_x = `k_x'
		eret scalar k_z = `k_z'
		eret scalar k_iv = `k_iv'
		eret scalar sigma2_e = `sigma2_e'
		eret scalar sigma2_u = `sigma2_u'
		eret matrix beta_fe = `beta_nc'
		eret matrix gamma_fefiv = `gamma_z_iv'
		eret matrix V_gamma_pz = `V_gamma_iv_pz'
		
		Display, level(`level')
		drop `tag'
	}
	
	// =========================================================================
	// 5C. FEVD 3-STAGE ESTIMATION  — Pesaran & Zhou Section 3.4
	//
	//  Stage 1: FE on y_it = alpha_i + x_it' beta + e_it  →  beta_hat, u_hat_it
	//  Stage 2: OLS of ubar_i on z_i [with intercept]  →  gamma_hat, h_hat_i  (Eq. 21-22)
	//  Stage 3: Pooled OLS: y_it = a + x_it'beta + z_i'gamma + delta*h_i + eps (Eq. 25)
	//           Result: gamma_tilde = gamma_hat (Prop. 3), delta_tilde = 1, beta_tilde = beta_hat
	//
	//  Variance: Use Pesaran-Zhou Eq. 17 (NOT stage-3 pooled OLS SEs which are inconsistent)
	// =========================================================================
	
	else {
		// --- STAGE 2: Decompose unit effects ---

		
		tempvar tag
		qui egen `tag' = tag(`ivar') if `touse'
		
		if "`nointercept2'" != "" {
			// Without intercept (original PT Eq. 5 — NOT recommended)
			di in ye "  {bf:WARNING}: Running without intercept in stage 2."
			di in ye "  This may produce biased/inconsistent estimates."
			di in ye "  See Pesaran & Zhou (2016) Proposition 4."
			qui reg `ubar_i' `zinvariants' if `tag' == 1 & `touse', noconstant
		}
		else {
			// With intercept (correct — equivalent to FEF, Proposition 3)
			qui reg `ubar_i' `zinvariants' if `tag' == 1 & `touse'
		}
		
		tempname gamma_s2 
		matrix `gamma_s2' = e(b)
		
		// h_hat_i = unexplained part of unit effects (Eq. 21)
		tempvar h_i
		qui predict `h_i' if `tag' == 1 & `touse', residuals
		
		// Expand h_i to all observations within each panel
		tempvar h_full
		qui egen `h_full' = mean(`h_i') if `touse', by(`ivar')
		
		// --- STAGE 3: Pooled OLS  (Eq. 25) ---

		
		qui reg `depvar' `xvars' `zinvariants' `h_full' if `touse'
		
		tempname b_fevd V_fevd_raw
		matrix `b_fevd' = e(b)
		matrix `V_fevd_raw' = e(V)
		
		// Verify delta = 1 (Proposition 3: delta_tilde should be exactly 1)
		local delta = _b[`h_full']
		if abs(`delta' - 1) > 0.001 {
			di in ye "  Note: delta = " %9.6f `delta' " (expected 1.0)"
		}
		
		// Extract gamma from stage 3 (FEVD point estimates)
		tempname gamma_fevd
		matrix `gamma_fevd' = J(1, `k_z', 0)
		forvalues i = 1/`k_z' {
			local zv : word `i' of `zinvariants'
			matrix `gamma_fevd'[1, `i'] = _b[`zv']
		}
		
		local alpha_val = _b[_cons]
		
		// === CORRECT VARIANCE: Pesaran-Zhou (Eq. 17) ===
		// The FEVD stage-3 pooled OLS SEs are INCONSISTENT (Section 3.4, Remark 4)
		// Even when point estimates are identical, the SEs are wrong.
		

		
		// chat_i residuals for V_zz (Eq. 19-20)
		tempvar chat_i
		qui reg `ubar_i' `zinvariants' if `tag' == 1 & `touse'
		qui predict `chat_i' if `tag' == 1 & `touse', residuals
		
		tempname Qzz Vzz Qzxbar Vbeta V_gamma_pz
		
		// Compute Q_zz (Eq. 8), V_zz (Eq. 19), Q_zxbar (Eq. 9) via Mata
		mata: _xtfifevd_fef_variance( ///
			"`touse'", "`tag'", "`ivar'", ///
			"`zinvariants'", "`xvars'", "`chat_i'", ///
			"`Qzz'", "`Vzz'", "`Qzxbar'")
		
		// HC sandwich V_hat(beta_FE) (Eq. 18)
		qui xtreg `depvar' `xvars' if `touse', fe vce(robust)
		matrix `Vbeta' = e(V)
		if `has_cons' {
			matrix `Vbeta' = `Vbeta'[1..`k_x', 1..`k_x']
		}
		
		// V_gamma_pz = (1/N) * Qzz^{-1} * [Vzz + Qzxbar * N*Vbeta * Qzxbar'] * Qzz^{-1}
		tempname Qzz_inv mid
		matrix `Qzz_inv' = syminv(`Qzz')
		matrix `mid' = `Vzz' + `Qzxbar' * (`N_g' * `Vbeta') * `Qzxbar''
		matrix `V_gamma_pz' = (1/`N_g') * `Qzz_inv' * `mid' * `Qzz_inv'
		
		// Build combined b and V
		tempname b_combined V_combined beta_nc
		if `has_cons' {
			matrix `beta_nc' = `beta_fe'[1, 1..`k_x']
		}
		else {
			matrix `beta_nc' = `beta_fe'
		}
		
		tempname alpha_sc
		matrix `alpha_sc' = J(1, 1, `alpha_val')
		matrix `b_combined' = `beta_nc', `gamma_fevd', `alpha_sc'
		
		local k_total = `k_x' + `k_z' + 1
		matrix `V_combined' = J(`k_total', `k_total', 0)
		
		// Fill beta block (standard FE)
		qui xtreg `depvar' `xvars' if `touse', fe
		tempname Vbeta_std
		matrix `Vbeta_std' = e(V)
		if `has_cons' {
			matrix `Vbeta_std' = `Vbeta_std'[1..`k_x', 1..`k_x']
		}
		forvalues i = 1/`k_x' {
			forvalues j = 1/`k_x' {
				matrix `V_combined'[`i', `j'] = `Vbeta_std'[`i', `j']
			}
		}
		
		// Fill gamma block (Pesaran-Zhou corrected, Eq. 17)
		forvalues i = 1/`k_z' {
			forvalues j = 1/`k_z' {
				local ri = `k_x' + `i'
				local rj = `k_x' + `j'
				matrix `V_combined'[`ri', `rj'] = `V_gamma_pz'[`i', `j']
			}
		}
		
		// Alpha variance
		local idx_a = `k_total'
		qui reg `ubar_i' `zinvariants' if `tag' == 1 & `touse'
		local se_alpha = _se[_cons]
		matrix `V_combined'[`idx_a', `idx_a'] = `se_alpha'^2
		
		// Store UNCORRECTED FEVD SEs for comparison
		tempname V_fevd_gamma
		matrix `V_fevd_gamma' = J(`k_z', `k_z', 0)
		forvalues i = 1/`k_z' {
			forvalues j = 1/`k_z' {
				local ri_raw = `k_x' + `i'
				local rj_raw = `k_x' + `j'
				matrix `V_fevd_gamma'[`i', `j'] = `V_fevd_raw'[`ri_raw', `rj_raw']
			}
		}
		
		// Names
		local allnames ""
		foreach x of local xvars {
			local allnames "`allnames' FE:`x'"
		}
		foreach z of local zinvariants {
			local allnames "`allnames' FEVD:`z'"
		}
		local allnames "`allnames' FEVD:_cons"
		
		matrix colnames `b_combined' = `allnames'
		matrix rownames `V_combined' = `allnames'
		matrix colnames `V_combined' = `allnames'
		
		eret post `b_combined' `V_combined', esample(`touse')
		
		eret local cmd "xtfifevd"
		eret local method "FEVD"
		eret local depvar "`depvar'"
		eret local xvars "`xvars'"
		eret local zinvariants "`zinvariants'"
		eret local ivar "`ivar'"
		eret local tvar "`tvar'"
		if "`robust'" != "" {
			eret local vce "robust"
			eret local vcetype "Robust"
		}
		else {
			eret local vce "pesaran-zhou"
			eret local vcetype "PZ Robust"
		}
		eret scalar N = `N_obs'
		eret scalar N_g = `N_g'
		eret scalar T = `T'
		eret scalar T_bar = `T_bar'
		eret scalar k_x = `k_x'
		eret scalar k_z = `k_z'
		eret scalar delta = `delta'
		eret scalar sigma2_e = `sigma2_e'
		eret scalar sigma2_u = `sigma2_u'
		eret matrix beta_fe = `beta_nc'
		eret matrix gamma_fevd = `gamma_fevd'
		eret matrix V_gamma_pz = `V_gamma_pz'
		eret matrix V_gamma_fevd_raw = `V_fevd_gamma'
		
		Display, level(`level')
		
		// --- COMPARE MODE ---
		if "`compare'" != "" {
			di
			di in smcl in gr "{hline 78}"
			di in gr "{bf:TABLE A: Pesaran-Zhou Corrected SEs (Consistent)}"
			di in smcl in gr "{hline 78}"
			di in gr _col(3) "Variable" ///
				_col(16) "Coef." ///
				_col(28) "PZ SE" ///
				_col(40) "z" ///
				_col(48) "P>|z|" ///
				_col(58) "[95% Conf. Interval]"
			di in smcl in gr "{hline 78}"
			
			forvalues i = 1/`k_z' {
				local zv : word `i' of `zinvariants'
				local coef = e(gamma_fevd)[1, `i']
				local se_pz = sqrt(e(V_gamma_pz)[`i', `i'])
				local z_pz = `coef' / `se_pz'
				local p_pz = 2 * (1 - normal(abs(`z_pz')))
				local ci_lo = `coef' - 1.96 * `se_pz'
				local ci_hi = `coef' + 1.96 * `se_pz'
				
				di in gr _col(3) abbrev("`zv'", 11) ///
					_col(14) in ye %10.6f `coef' ///
					_col(26) in ye %9.6f `se_pz' ///
					_col(38) in ye %7.2f `z_pz' ///
					_col(47) in ye %6.3f `p_pz' ///
					_col(56) in ye %10.6f `ci_lo' ///
					_col(68) in ye %10.6f `ci_hi'
			}
			di in smcl in gr "{hline 78}"
			
			di
			di in smcl in gr "{hline 78}"
			di in gr "{bf:TABLE B: FEVD Raw SEs (Inconsistent — Stage-3 Pooled OLS)}"
			di in smcl in gr "{hline 78}"
			di in gr _col(3) "Variable" ///
				_col(16) "Coef." ///
				_col(28) "Raw SE" ///
				_col(40) "z" ///
				_col(48) "P>|z|" ///
				_col(58) "[95% Conf. Interval]"
			di in smcl in gr "{hline 78}"
			
			forvalues i = 1/`k_z' {
				local zv : word `i' of `zinvariants'
				local coef = e(gamma_fevd)[1, `i']
				local se_raw = sqrt(e(V_gamma_fevd_raw)[`i', `i'])
				local z_raw = `coef' / `se_raw'
				local p_raw = 2 * (1 - normal(abs(`z_raw')))
				local ci_lo = `coef' - 1.96 * `se_raw'
				local ci_hi = `coef' + 1.96 * `se_raw'
				
				di in gr _col(3) abbrev("`zv'", 11) ///
					_col(14) in ye %10.6f `coef' ///
					_col(26) in ye %9.6f `se_raw' ///
					_col(38) in ye %7.2f `z_raw' ///
					_col(47) in ye %6.3f `p_raw' ///
					_col(56) in ye %10.6f `ci_lo' ///
					_col(68) in ye %10.6f `ci_hi'
			}
			di in smcl in gr "{hline 78}"
			di in ye "  {bf:WARNING}: These SEs are inconsistent (Pesaran & Zhou 2016, Remark 4)."
			di in ye "  They ignore the generated regressor (h_i) estimation uncertainty."
			
			di
			di in smcl in gr "{hline 78}"
			di in gr "{bf:TABLE C: SE Ratio Summary — Size Distortion Diagnostic}"
			di in smcl in gr "{hline 78}"
			di in gr _col(3) "Variable" ///
				_col(18) "PZ SE" ///
				_col(31) "Raw SE" ///
				_col(43) "Ratio" ///
				_col(55) "Distortion"
			di in smcl in gr "{hline 78}"
			
			forvalues i = 1/`k_z' {
				local zv : word `i' of `zinvariants'
				local se_pz = sqrt(e(V_gamma_pz)[`i', `i'])
				local se_raw = sqrt(e(V_gamma_fevd_raw)[`i', `i'])
				local ratio = `se_pz' / `se_raw'
				
				local severity "Moderate"
				if `ratio' > 3 local severity "SEVERE"
				if `ratio' > 5 local severity "EXTREME"
				if `ratio' < 1.5 local severity "Mild"
				
				di in gr _col(3) abbrev("`zv'", 13) ///
					_col(16) in ye %9.6f `se_pz' ///
					_col(29) in ye %9.6f `se_raw' ///
					_col(42) in ye %7.2f `ratio' "x" ///
					_col(55) in ye "`severity'"
			}
			di in smcl in gr "{hline 78}"
			di in gr "  Ratio = PZ SE / Raw SE. Values > 1 confirm SEs are understated."
			di in gr "  SEVERE (>3x): rejection rates may exceed 90% at nominal 5%."
			di
		}
		
		drop `tag' `h_full'
	}
	
end

// =============================================================================
// DISPLAY ROUTINE
// =============================================================================

capture program drop Display
program define Display
	syntax [, Level(integer `c(level)')]
	
	di
	di in smcl in gr "{hline 78}"
	di in gr "{bf:`e(method)' Estimation Results}" ///
		_col(56) in ye "xtfifevd 1.0.0"
	di in smcl in gr "{hline 78}"
	di in gr "Dep. variable:  " in ye "`e(depvar)'" ///
		in gr _col(42) "Observations:  " in ye e(N)
	di in gr "Method:         " in ye "`e(method)'" ///
		in gr _col(42) "Groups:        " in ye e(N_g)
	di in gr "Variance:       " in ye "Pesaran-Zhou (2016)" ///
		in gr _col(42) "T (avg):       " in ye %5.1f e(T_bar)
	di in smcl in gr "{hline 78}"
	
	ereturn display, level(`level')
	
	di in smcl in gr "{hline 78}"
	di in gr "Time-varying (FE):      " in ye "`e(xvars)'"
	di in gr "Time-invariant:         " in ye "`e(zinvariants)'"
	if "`e(method)'" == "FEF-IV" {
		di in gr "Instruments:            " in ye "`e(instruments)'"
	}
	if "`e(method)'" == "FEVD" {
		di in gr "Stage-3 delta:          " in ye %6.4f e(delta)
	}
	di in smcl in gr "{hline 78}"
	

end

// =============================================================================
// MATA FUNCTIONS FOR VARIANCE COMPUTATION
// =============================================================================

mata:
mata clear
mata set matastrict off

// -------------------------------------------------------------------
// FEF variance estimator (Pesaran-Zhou Eq. 17)
//   Computes: Q_zz (Eq. 8), V_zz (Eq. 19), Q_zxbar (Eq. 9)
//   Input: chat_i = OLS residuals from reg ubar_i on z  (= Eq. 20)
// -------------------------------------------------------------------
void _xtfifevd_fef_variance(
	string scalar touse_name,
	string scalar tag_name,
	string scalar ivar_name,
	string scalar zvars_name,
	string scalar xvars_name,
	string scalar chat_name,
	string scalar Qzz_mat,
	string scalar Vzz_mat,
	string scalar Qzxbar_mat)
{
	real matrix Z, Xbar
	real colvector chat, tag
	real scalar N, k_z, k_x, i
	real matrix Qzz, Vzz, Qzxbar
	real rowvector zbar, xbar_bar
	
	// Get data — panel-level (one obs per panel)
	tag = st_data(., tag_name, touse_name)
	Z = st_data(., tokens(zvars_name), touse_name)
	chat = st_data(., chat_name, touse_name)
	
	k_z = cols(Z)
	
	// Select only tagged rows (one per panel)
	real colvector sel
	sel = selectindex(tag :== 1)
	
	Z = Z[sel, .]
	chat = chat[sel, .]
	
	// Compute Xbar (panel means of x-vars) from full data
	string rowvector xnames
	xnames = tokens(xvars_name)
	k_x = cols(xnames)
	
	real matrix fullX, fullID
	fullX = st_data(., tokens(xvars_name), touse_name)
	fullID = st_data(., ivar_name, touse_name)
	
	// Get unique panel IDs and compute panel means
	real colvector uniq_id
	uniq_id = uniqrows(fullID)
	N = rows(uniq_id)
	
	Xbar = J(N, k_x, 0)
	for (i = 1; i <= N; i++) {
		real colvector idx
		idx = selectindex(fullID :== uniq_id[i])
		Xbar[i, .] = mean(fullX[idx, .])
	}
	
	// Compute means
	zbar = mean(Z)
	xbar_bar = mean(Xbar)
	
	// Center
	real matrix Zc, Xbarc
	Zc = Z :- zbar
	Xbarc = Xbar :- xbar_bar
	
	// Q_zz = (1/N) * Z_c' * Z_c   (Eq. 8)
	Qzz = (1/N) * cross(Zc, Zc)
	
	// V_zz = (1/N) * sum chat_i^2 * (z_i - zbar)(z_i - zbar)'  (Eq. 19)
	real matrix Vzz_tmp
	Vzz_tmp = J(k_z, k_z, 0)
	for (i = 1; i <= N; i++) {
		Vzz_tmp = Vzz_tmp + chat[i]^2 * (Zc[i, .]' * Zc[i, .])
	}
	Vzz = (1/N) * Vzz_tmp
	
	// Q_zxbar = (1/N) * Z_c' * Xbar_c   (Eq. 9)
	Qzxbar = (1/N) * cross(Zc, Xbarc)
	
	// Store results back to Stata matrices
	st_matrix(Qzz_mat, Qzz)
	st_matrix(Vzz_mat, Vzz)
	st_matrix(Qzxbar_mat, Qzxbar)
}

// -------------------------------------------------------------------
// FEF-IV variance estimator (Pesaran-Zhou Eq. 51)
//   Computes: Q_zr, Q_rr, Q_rxbar, V_rr
//   Input: upsilon_i = IV residuals from 2SLS
// -------------------------------------------------------------------
void _xtfifevd_fefiv_variance(
	string scalar touse_name,
	string scalar tag_name,
	string scalar ivar_name,
	string scalar zvars_name,
	string scalar ivvars_name,
	string scalar xvars_name,
	string scalar upsilon_name,
	string scalar Qzr_mat,
	string scalar Qrr_mat,
	string scalar Qrxbar_mat,
	string scalar Vrr_mat)
{
	real matrix Z, R, Xbar
	real colvector upsilon, tag
	real scalar N, k_z, k_iv, k_x, i
	
	tag = st_data(., tag_name, touse_name)
	Z = st_data(., tokens(zvars_name), touse_name)
	R = st_data(., tokens(ivvars_name), touse_name)
	upsilon = st_data(., upsilon_name, touse_name)
	
	k_z = cols(Z)
	k_iv = cols(R)
	
	// Select tagged rows
	real colvector sel
	sel = selectindex(tag :== 1)
	Z = Z[sel, .]
	R = R[sel, .]
	upsilon = upsilon[sel, .]
	
	// Compute Xbar from full data
	string rowvector xnames
	xnames = tokens(xvars_name)
	k_x = cols(xnames)
	
	real matrix fullX, fullID
	fullX = st_data(., tokens(xvars_name), touse_name)
	fullID = st_data(., ivar_name, touse_name)
	
	real colvector uniq_id
	uniq_id = uniqrows(fullID)
	N = rows(uniq_id)
	
	Xbar = J(N, k_x, 0)
	for (i = 1; i <= N; i++) {
		real colvector idx
		idx = selectindex(fullID :== uniq_id[i])
		Xbar[i, .] = mean(fullX[idx, .])
	}
	
	// Center
	real rowvector zbar, rbar, xbar_bar
	zbar = mean(Z)
	rbar = mean(R)
	xbar_bar = mean(Xbar)
	
	real matrix Zc, Rc, Xbarc
	Zc = Z :- zbar
	Rc = R :- rbar
	Xbarc = Xbar :- xbar_bar
	
	// Q_zr = (1/N) * Z_c' * R_c
	real matrix Qzr, Qrr, Qrxbar, Vrr_tmp
	Qzr = (1/N) * cross(Zc, Rc)
	
	// Q_rr = (1/N) * R_c' * R_c
	Qrr = (1/N) * cross(Rc, Rc)
	
	// Q_rxbar = (1/N) * R_c' * Xbar_c
	Qrxbar = (1/N) * cross(Rc, Xbarc)
	
	// V_rr = (1/N) * sum upsilon_i^2 * (r_i - rbar)(r_i - rbar)'
	Vrr_tmp = J(k_iv, k_iv, 0)
	for (i = 1; i <= N; i++) {
		Vrr_tmp = Vrr_tmp + upsilon[i]^2 * (Rc[i, .]' * Rc[i, .])
	}
	real matrix Vrr
	Vrr = (1/N) * Vrr_tmp
	
	st_matrix(Qzr_mat, Qzr)
	st_matrix(Qrr_mat, Qrr)
	st_matrix(Qrxbar_mat, Qrxbar)
	st_matrix(Vrr_mat, Vrr)
}

end
