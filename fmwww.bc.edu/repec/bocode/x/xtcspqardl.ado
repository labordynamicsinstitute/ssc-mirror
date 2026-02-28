*! xtcspqardl v1.0.0  25feb2026  Dr Merwan Roudane  merwanroudane920@gmail.com
*! Cross-Sectionally Augmented Panel Quantile ARDL (CS-PQARDL) 
*! & Quantile CCE Mean Group (QCCEMG) Estimator
*! Based on: Harding, Lamarche & Pesaran (2018), Pesaran (2006),
*!           Chudik & Pesaran (2015), Cho, Kim & Shin (2015)
*! References: xtpqardl, xtdcce2, xtcce, xtmg

capture program drop xtcspqardl
program define xtcspqardl, eclass
	version 15.1
	if replay() {
		if ("`e(cmd)'" != "xtcspqardl") error 301
		Display `0'
	}
	else Estimate `0'
end


* =====================================================================
* MAIN ESTIMATION PROGRAM
* =====================================================================
program define Estimate, eclass
	syntax varlist(min=2 ts) [if] [in], TAU(numlist >0 <1 sort) ///
		[LR(varlist ts) EC(name) ///
		 P(integer 1) Q(string) PMAX(integer 4) QMAX(integer 4) ///
		 noCONStant LEVel(integer `c(level)') ///
		 LAGSel(string) ///
		 CR_lags(integer -1) ///
		 QCCEMG QCCEPMG ///
		 PMG MG DFE ECM FULL REPLACE ///
		 SRTable HALFlife IRF(integer 0) ///
		 GRaph NOTABle SHOWIndividual SHOWCsa]
	
	* ================================================================
	* Validate inputs
	* ================================================================
	local ntau : word count `tau'
	if `ntau' < 1 {
		di as err "tau() must specify at least one quantile"
		exit 198
	}
	
	* ================================================================
	* Panel setup
	* ================================================================
	marksample touse
	qui tsset
	local ivar `r(panelvar)'
	local tvar `r(timevar)'
	
	if "`ivar'" == "" {
		di as err "data must be xtset or tsset as panel data"
		exit 459
	}
	
	* Parse variables
	tokenize `varlist'
	local depvar `1'
	mac shift
	local indepvars `*'
	local k = wordcount("`indepvars'")
	
	* Panel info
	qui levelsof `ivar' if `touse', local(ids)
	local npanels : word count `ids'
	qui count if `touse'
	local nobs = r(N)
	local avg_T = round(`nobs' / `npanels')
	
	* ================================================================
	* COMPUTE CROSS-SECTIONAL AVERAGES (CSA)
	* ================================================================
	* z̄_t = (ȳ_t, x̄₁_t, x̄₂_t, ...) — means across all units at each t
	
	* Default cr_lags: floor(T^{1/3}) per Chudik & Pesaran (2015)
	if `cr_lags' < 0 {
		local cr_lags = floor(`avg_T'^(1/3))
	}
	
	* CSA for dependent variable
	tempvar csa_y
	qui bysort `tvar': egen double `csa_y' = mean(`depvar') if `touse'
	local csa_vars "`csa_y'"
	local csa_names "csa_`depvar'"
	
	* CSA for independent variables
	local csa_x_vars ""
	local csa_x_names ""
	forvalues j = 1/`k' {
		local xvar : word `j' of `indepvars'
		* Handle ts operators: use tsrevar to get plain var
		tempvar xplain csa_x`j'
		qui gen double `xplain' = `xvar' if `touse'
		qui bysort `tvar': egen double `csa_x`j'' = mean(`xplain') if `touse'
		drop `xplain'
		local csa_x_vars "`csa_x_vars' `csa_x`j''"
		local csa_x_names "`csa_x_names' csa_x`j'"
	}
	
	local csa_all "`csa_y' `csa_x_vars'"
	local n_csa = 1 + `k'
	
	* Restore panel sort order (bysort `tvar': re-sorted by time only)
	sort `ivar' `tvar'
	
	* Generate lagged CSA
	local csa_lagged ""
	if `cr_lags' > 0 {
		foreach csav of local csa_all {
			forvalues lag = 1/`cr_lags' {
				tempvar csa_lag_`csav'_`lag'
				qui gen double `csa_lag_`csav'_`lag'' = L`lag'.`csav' if `touse'
				local csa_lagged "`csa_lagged' `csa_lag_`csav'_`lag''"
			}
		}
	}
	
	local csa_full "`csa_all' `csa_lagged'"
	local n_csa_total = `n_csa' * (1 + `cr_lags')
	
	* ================================================================
	* DISPATCH TO ESTIMATOR
	* ================================================================
	if "`qccemg'" != "" | "`qccepmg'" != "" {
		
		* Prevent both options at once
		if "`qccemg'" != "" & "`qccepmg'" != "" {
			di as err "cannot specify both qccemg and qccepmg"
			exit 198
		}
		
		* Set estimator label
		if "`qccepmg'" != "" {
			local est_type "qccepmg"
			local est_label "QCCEPMG — Quantile CCE Pooled Mean Group"
			local est_short "QCCEPMG"
		}
		else {
			local est_type "qccemg"
			local est_label "QCCEMG — Quantile CCE Mean Group"
			local est_short "QCCEMG"
		}
		
		* ============================================================
		* QCCEMG/QCCEPMG: Quantile CCE Mean/Pooled Mean Group (HLP 2018)
		* ============================================================
		di
		di in smcl in gr "{hline 78}"
		di in smcl in gr "  {bf:╔══════════════════════════════════════════════════════════════════════╗}"
		di in smcl in gr "  {bf:║}" _col(5) in ye ///
			"  XTCSPQARDL — `est_short' (`est_label')" ///
			_col(72) in gr "{bf:║}"
		di in smcl in gr "  {bf:║}" _col(5) in ye ///
			"  Harding, Lamarche & Pesaran (2018)" ///
			_col(72) in gr "{bf:║}"
		di in smcl in gr "  {bf:║}" _col(5) in ye ///
			"  Version 1.0.0" ///
			_col(72) in gr "{bf:║}"
		di in smcl in gr "  {bf:╚══════════════════════════════════════════════════════════════════════╝}"
		di in smcl in gr "{hline 78}"
		di in gr "  Estimator:        " in ye "`est_label'"
		di in gr "  Dep. variable:    " in ye "`depvar'"
		di in gr "  Regressors:       " in ye "`indepvars'"
		di in gr "  Panels (N):       " in ye "`npanels'"
		di in gr "  Avg. T:           " in ye "`avg_T'"
		di in gr "  Observations:     " in ye "`nobs'"
		di in gr "  CSA lags (pT):    " in ye "`cr_lags'"
		di in gr "  CSA variables:    " in ye "`n_csa_total' = `n_csa' × (1+`cr_lags')"
		di in gr "  Quantiles:        " _c
		foreach tauval of local tau {
			di in ye %5.2f `tauval' " " _c
		}
		di ""
		di in smcl in gr "{hline 78}"
		di
		di in smcl in gr "{hline 78}"
		
		* Call estimation engine
		if "`est_type'" == "qccepmg" {
			_xtcspqardl_qccepmg, depvar(`depvar') indepvars(`indepvars') ///
				tau(`tau') ivar(`ivar') tvar(`tvar') touse(`touse') ///
				csavars(`csa_full') ncsaorig(`n_csa') crlags(`cr_lags') ///
				`constant' `showindividual'
		}
		else {
			_xtcspqardl_qccemg, depvar(`depvar') indepvars(`indepvars') ///
				tau(`tau') ivar(`ivar') tvar(`tvar') touse(`touse') ///
				csavars(`csa_full') ncsaorig(`n_csa') crlags(`cr_lags') ///
				`constant' `showindividual'
		}
		
		local valid_panels = r(valid_panels)
		
		di
		di in gr "  ► " in ye "`valid_panels'" in gr "/" in ye "`npanels'" ///
			in gr " panels estimated successfully"
		
		if `valid_panels' == 0 {
			di as err "  ERROR: No panels could be estimated"
			exit 2000
		}
		
		* Store results
		tempname lambda_all beta_all lambda_mg beta_mg theta_mg
		tempname lambda_V beta_V theta_V halflife_mg theta_i_all
		tempname delta_mg delta_V
		
		matrix `lambda_all' = r(lambda_all)
		matrix `beta_all' = r(beta_all)
		matrix `lambda_mg' = r(lambda_mg)
		matrix `beta_mg' = r(beta_mg)
		matrix `theta_mg' = r(theta_mg)
		matrix `lambda_V' = r(lambda_V)
		matrix `beta_V' = r(beta_V)
		matrix `theta_V' = r(theta_V)
		matrix `halflife_mg' = r(halflife_mg)
		matrix `theta_i_all' = r(theta_i_all)
		matrix `delta_mg' = r(delta_mg)
		matrix `delta_V' = r(delta_V)
		
		* ============================================================
		* DISPLAY TABLES — QCCEMG
		* ============================================================
		if "`notable'" == "" {
			
			* Table 1: Short-Run (Contemporaneous) Coefficients
			di
			di in smcl in gr "{hline 78}"
			di in smcl in gr "  {bf:╔══════════════════════════════════════════════════════════════════════╗}"
			di in smcl in gr "  {bf:║   Table 1: `est_short' Short-Run Coefficients                       ║}"
			di in smcl in gr "  {bf:║   Mean Group of unit-by-unit quantile regressions                  ║}"
			di in smcl in gr "  {bf:╚══════════════════════════════════════════════════════════════════════╝}"
			di in smcl in gr "{hline 78}"
			di in gr "  {ralign 14:Variable}" _c
			di in gr " {ralign 8:Quantile}" _c
			di in gr " {ralign 12:Coef.}" _c
			di in gr " {ralign 10:Std.Err.}" _c
			di in gr " {ralign 10:z-stat}" _c
			di in gr " {ralign 10:P>|z|}" _c
			di in gr "  {ralign 4: }"
			di in smcl in gr "{hline 78}"
			
			local ti = 0
			foreach tauval of local tau {
				local ++ti
				di in smcl in ye "  ── τ = " %5.2f `tauval' " " in gr "{hline 58}"
				
				* Lambda
				local est = `lambda_mg'[1, `ti']
				local var_val = `lambda_V'[`ti', `ti']
				local se = .
				local zstat = .
				local pval = .
				if `var_val' > 0 & `var_val' != . {
					local se = sqrt(`var_val')
					if `se' > 0 {
						local zstat = `est' / `se'
						local pval = 2 * (1 - normal(abs(`zstat')))
					}
				}
				local stars ""
				if `pval' != . & `pval' < 1 {
					if `pval' < 0.01      local stars "***"
					else if `pval' < 0.05 local stars "** "
					else if `pval' < 0.10 local stars "*  "
				}
				di in gr "  {ralign 14:L.`depvar'}" _c
				di in gr " {ralign 8:" %5.2f `tauval' "}" _c
				di as res " {ralign 12:" %10.4f `est' "}" _c
				if `se' != . {
					di in gr " {ralign 10:" %8.4f `se' "}" _c
					di in gr " {ralign 10:" %8.3f `zstat' "}" _c
					if `pval' < 0.01 {
						di as err " {ralign 10:" %8.4f `pval' "}" _c
					}
					else if `pval' < 0.05 {
						di as res " {ralign 10:" %8.4f `pval' "}" _c
					}
					else {
						di in gr " {ralign 10:" %8.4f `pval' "}" _c
					}
					di in ye " `stars'"
				}
				else {
					di ""
				}
				
				* Beta coefficients
				forvalues j = 1/`k' {
					local xvar : word `j' of `indepvars'
					local bcol = (`ti' - 1) * `k' + `j'
					local est = `beta_mg'[1, `bcol']
					local var_val = `beta_V'[`bcol', `bcol']
					local se = .
					local zstat = .
					local pval = .
					if `var_val' > 0 & `var_val' != . {
						local se = sqrt(`var_val')
						if `se' > 0 {
							local zstat = `est' / `se'
							local pval = 2 * (1 - normal(abs(`zstat')))
						}
					}
					local stars ""
					if `pval' != . & `pval' < 1 {
						if `pval' < 0.01      local stars "***"
						else if `pval' < 0.05 local stars "** "
						else if `pval' < 0.10 local stars "*  "
					}
					di in gr "  {ralign 14:`xvar'}" _c
					di in gr " {ralign 8:" %5.2f `tauval' "}" _c
					di as res " {ralign 12:" %10.4f `est' "}" _c
					if `se' != . {
						di in gr " {ralign 10:" %8.4f `se' "}" _c
						di in gr " {ralign 10:" %8.3f `zstat' "}" _c
						if `pval' < 0.01 {
							di as err " {ralign 10:" %8.4f `pval' "}" _c
						}
						else if `pval' < 0.05 {
							di as res " {ralign 10:" %8.4f `pval' "}" _c
						}
						else {
							di in gr " {ralign 10:" %8.4f `pval' "}" _c
						}
						di in ye " `stars'"
					}
					else {
						di ""
					}
				}
			}
			di in smcl in gr "{hline 78}"
			di in gr "  *** p<0.01, ** p<0.05, * p<0.10"
			di in gr "  Variance: V̂_v = (1/(N-1))·Σ(ϑ̂_i − ϑ̂)(ϑ̂_i − ϑ̂)'"
			
			* Table 2: Long-Run Effects
			di
			di in smcl in gr "{hline 78}"
			di in smcl in gr "  {bf:╔══════════════════════════════════════════════════════════════════════╗}"
			di in smcl in gr "  {bf:║   Table 2: `est_short' Long-Run Effects                              ║}"
			di in smcl in gr "  {bf:║   Delta-method standard errors                                     ║}"
			di in smcl in gr "  {bf:╚══════════════════════════════════════════════════════════════════════╝}"
			di in smcl in gr "{hline 78}"
			di in gr "  {ralign 14:Variable}" _c
			di in gr " {ralign 8:Quantile}" _c
			di in gr " {ralign 12:LR Coef.}" _c
			di in gr " {ralign 10:Std.Err.}" _c
			di in gr " {ralign 10:z-stat}" _c
			di in gr " {ralign 10:P>|z|}" _c
			di in gr "  {ralign 4: }"
			di in smcl in gr "{hline 78}"
			
			local ti = 0
			foreach tauval of local tau {
				local ++ti
				di in smcl in ye "  ── τ = " %5.2f `tauval' " " in gr "{hline 58}"
				
				local lam = `lambda_mg'[1, `ti']
				local hl = `halflife_mg'[1, `ti']
				
				forvalues j = 1/`k' {
					local xvar : word `j' of `indepvars'
					local tcol = (`ti' - 1) * `k' + `j'
					local est = `theta_mg'[1, `tcol']
					
					* Delta method SE: ∂θ/∂β = 1/(1-λ), ∂θ/∂λ = β/(1-λ)²
					local bcol = (`ti' - 1) * `k' + `j'
					local b_val = `beta_mg'[1, `bcol']
					local v_beta = `beta_V'[`bcol', `bcol']
					local v_lambda = `lambda_V'[`ti', `ti']
					local denom = (1 - `lam')
					local se = .
					local zstat = .
					local pval = .
					if abs(`denom') > 1e-8 & `v_beta' > 0 & `v_lambda' > 0 {
						local g_beta = 1 / `denom'
						local g_lam = `b_val' / (`denom' * `denom')
						local var_theta = `g_beta'^2 * `v_beta' + `g_lam'^2 * `v_lambda'
						if `var_theta' > 0 {
							local se = sqrt(`var_theta')
							local zstat = `est' / `se'
							local pval = 2 * (1 - normal(abs(`zstat')))
						}
					}
					
					local stars ""
					if `pval' != . & `pval' < 1 {
						if `pval' < 0.01      local stars "***"
						else if `pval' < 0.05 local stars "** "
						else if `pval' < 0.10 local stars "*  "
					}
					
					di in gr "  {ralign 14:`xvar'}" _c
					di in gr " {ralign 8:" %5.2f `tauval' "}" _c
					di as res " {ralign 12:" %10.4f `est' "}" _c
					if `se' != . {
						di in gr " {ralign 10:" %8.4f `se' "}" _c
						di in gr " {ralign 10:" %8.3f `zstat' "}" _c
						if `pval' < 0.01 {
							di as err " {ralign 10:" %8.4f `pval' "}" _c
						}
						else if `pval' < 0.05 {
							di as res " {ralign 10:" %8.4f `pval' "}" _c
						}
						else {
							di in gr " {ralign 10:" %8.4f `pval' "}" _c
						}
						di in ye " `stars'"
					}
					else {
						di ""
					}
				}
				
				* Half-life
				if `hl' != . & `hl' > 0 {
					di in gr "  {ralign 14:Half-life}" _c
					di in gr " {ralign 8:" %5.2f `tauval' "}" _c
					di in ye " {ralign 12:" %10.2f `hl' "}" _c
					di in gr " {ralign 10: }" _c
					di in gr " {ralign 10: }" _c
					di in gr " {ralign 10: }" _c
					di in gr "  periods"
				}
			}
			di in smcl in gr "{hline 78}"
		}
		
		* CSA table (showcsa option)
		if "`showcsa'" != "" {
			local n_csa_total = colsof(`delta_mg') / `ntau'
			di
			di in smcl in gr "{hline 78}"
			di in smcl in gr "  {bf:╔══════════════════════════════════════════════════════════════════════╗}"
			di in smcl in gr "  {bf:║   CSA (Cross-Sectional Average) Coefficients                       ║}"
			di in smcl in gr "  {bf:║   Nuisance parameters — absorb unobserved common factors            ║}"
			di in smcl in gr "  {bf:╚══════════════════════════════════════════════════════════════════════╝}"
			di in smcl in gr "{hline 78}"
			di in gr "  {ralign 14:Variable}" _c
			di in gr " {ralign 8:Quantile}" _c
			di in gr " {ralign 12:Coef.}" _c
			di in gr " {ralign 10:Std.Err.}" _c
			di in gr " {ralign 10:z-stat}" _c
			di in gr " {ralign 10:P>|z|}" _c
			di in gr "  {ralign 4: }"
			di in smcl in gr "{hline 78}"
			
			local ti = 0
			foreach tauval of local tau {
				local ++ti
				di in smcl in ye "  -- tau = " %5.2f `tauval' " " in gr "{hline 58}"
				
				local ci = 0
				forvalues lag = 0/`cr_lags' {
					* CSA for y, then x1, x2, ...
					local vi = 0
					foreach vn in `depvar' `indepvars' {
						local ++vi
						local ++ci
						local ccol = (`ti' - 1) * `n_csa_total' + `ci'
						local ccols = colsof(`delta_mg')
						if `ccol' > `ccols' continue
						local est = `delta_mg'[1, `ccol']
						if `est' == . continue
						
						* Build label
						if `lag' == 0 {
							local clabel "csa(`vn')"
						}
						else {
							local clabel "L`lag'.csa(`vn')"
						}
						
						local var_val = `delta_V'[`ccol', `ccol']
						local se = .
						local zstat = .
						local pval = .
						if `var_val' > 0 & `var_val' != . {
							local se = sqrt(`var_val')
							if `se' > 0 {
								local zstat = `est' / `se'
								local pval = 2 * (1 - normal(abs(`zstat')))
							}
						}
						local stars ""
						if `pval' != . & `pval' < 1 {
							if `pval' < 0.01      local stars "***"
							else if `pval' < 0.05 local stars "** "
							else if `pval' < 0.10 local stars "*  "
						}
						di in gr "  {ralign 14:`clabel'}" _c
						di in gr " {ralign 8:" %5.2f `tauval' "}" _c
						di as res " {ralign 12:" %10.4f `est' "}" _c
						if `se' != . {
							di in gr " {ralign 10:" %8.4f `se' "}" _c
							di in gr " {ralign 10:" %8.3f `zstat' "}" _c
							if `pval' < 0.01 {
								di as err " {ralign 10:" %8.4f `pval' "}" _c
							}
							else if `pval' < 0.05 {
								di as res " {ralign 10:" %8.4f `pval' "}" _c
							}
							else {
								di in gr " {ralign 10:" %8.4f `pval' "}" _c
							}
							di in ye " `stars'"
						}
						else {
							di ""
						}
					}
				}
			}
			di in smcl in gr "{hline 78}"
			di in gr "  *** p<0.01, ** p<0.05, * p<0.10"
			di in gr "  CSA variables proxy unobserved common factors (nuisance)"
		}
		
		* Post to e()
		ereturn clear
		ereturn post, esample(`touse') obs(`nobs')
		
		ereturn matrix lambda_mg = `lambda_mg'
		ereturn matrix beta_mg = `beta_mg'
		ereturn matrix theta_mg = `theta_mg'
		ereturn matrix lambda_V = `lambda_V'
		ereturn matrix beta_V = `beta_V'
		ereturn matrix theta_V = `theta_V'
		ereturn matrix halflife_mg = `halflife_mg'
		ereturn matrix lambda_all = `lambda_all'
		ereturn matrix beta_all = `beta_all'
		ereturn matrix theta_i_all = `theta_i_all'
		ereturn matrix delta_mg = `delta_mg'
		ereturn matrix delta_V = `delta_V'
		
		ereturn scalar N = `nobs'
		ereturn scalar n_g = `npanels'
		ereturn scalar valid_panels = `valid_panels'
		ereturn scalar k = `k'
		ereturn scalar ntau = `ntau'
		ereturn scalar cr_lags = `cr_lags'
		ereturn scalar avg_T = `avg_T'
		
		ereturn local depvar "`depvar'"
		ereturn local indepvars "`indepvars'"
		ereturn local ivar "`ivar'"
		ereturn local tvar "`tvar'"
		ereturn local cmd "xtcspqardl"
		ereturn local estimator "`est_type'"
		ereturn local title "`est_label'"
	}
	else {
		* ============================================================
		* CS-PQARDL: Cross-Sectionally Augmented Panel Quantile ARDL
		* ============================================================
		
		* Validate CS-PQARDL specific inputs
		if "`lr'" == "" {
			di as err "lr() option required for CS-PQARDL — specify long-run level variables"
			di as err "  Example: lr(L.y x1 x2)"
			di as err "  For the QCCEMG estimator, use the qccemg option instead."
			exit 198
		}
		
		if ("`mg'" != "") + ("`dfe'" != "") + ("`pmg'" != "") > 1 {
			di as err "choose only one of pmg, mg, or dfe"
			exit 198
		}
		if "`mg'" == "" & "`dfe'" == "" local pmg "pmg"
		
		if `p' < 1 {
			di as err "p() must be at least 1"
			exit 198
		}
		if "`q'" == "" local q "1"
		
		* Parse lr
		tokenize `lr'
		local lr_y `1'
		mac shift
		local lr_x `*'
		local k_lr = wordcount("`lr'")
		local k_lrx = wordcount("`lr_x'")
		
		* Parse q per variable
		local nq : word count `q'
		if `nq' == 1 {
			local qlags ""
			forvalues j = 1/`k' {
				local qlags "`qlags' `q'"
			}
			local qlags = strtrim("`qlags'")
		}
		else if `nq' == `k' {
			local qlags "`q'"
		}
		else {
			di as err "q() must be a single number or k numbers"
			exit 198
		}
		
		if "`pmg'" != "" local model_label "Pooled Mean Group (PMG)"
		else if "`mg'" != "" local model_label "Mean Group (MG)"
		else if "`dfe'" != "" local model_label "Dynamic Fixed Effects (DFE)"
		
		* Build ARDL order string
		local ardl_order "`p'"
		forvalues j = 1/`k' {
			local qj : word `j' of `qlags'
			local ardl_order "`ardl_order',`qj'"
		}
		
		* Header
		di
		di in smcl in gr "{hline 78}"
		di in smcl in gr "  {bf:╔══════════════════════════════════════════════════════════════════════╗}"
		di in smcl in gr "  {bf:║}" _col(5) in ye ///
			"  XTCSPQARDL — CS Panel Quantile ARDL" ///
			_col(72) in gr "{bf:║}"
		di in smcl in gr "  {bf:║}" _col(5) in ye ///
			"  Cross-Sectionally Augmented (2nd Generation)" ///
			_col(72) in gr "{bf:║}"
		di in smcl in gr "  {bf:║}" _col(5) in ye ///
			"  Version 1.0.0" ///
			_col(72) in gr "{bf:║}"
		di in smcl in gr "  {bf:╚══════════════════════════════════════════════════════════════════════╝}"
		di in smcl in gr "{hline 78}"
		di in gr "  Model:            " in ye "`model_label'"
		di in gr "  Dep. variable:    " in ye "`depvar'"
		di in gr "  SR variables:     " in ye "`indepvars'"
		di in gr "  LR variables:     " in ye "`lr_x'"
		di in gr "  LR depvar (ECT):  " in ye "`lr_y'"
		di in gr "  CS-PQARDL(" in ye "`ardl_order'" in gr ")"
		di in gr "  Panels (N):       " in ye "`npanels'"
		di in gr "  Avg. T:           " in ye "`avg_T'"
		di in gr "  Observations:     " in ye "`nobs'"
		di in gr "  CSA lags (pT):    " in ye "`cr_lags'"
		di in gr "  CSA variables:    " in ye "`n_csa_total' = `n_csa' × (1+`cr_lags')"
		di in gr "  Quantiles:        " _c
		foreach tauval of local tau {
			di in ye %5.2f `tauval' " " _c
		}
		di ""
		di in smcl in gr "{hline 78}"
		di
		di in gr "  {bf:CCE Augmentation:} Cross-sectional averages in LR equation"
		di in gr "  CSA variables absorb unobserved common factors"
		di in smcl in gr "{hline 78}"
		
		* Call CS-PQARDL estimation engine
		if "`ecm'" != "" {
			* ECM reparameterization: CSA in ECT only
			_xtcspqardl_ecm, depvar(`depvar') indepvars(`indepvars') ///
				p(`p') qlags(`qlags') ///
				tau(`tau') ivar(`ivar') tvar(`tvar') touse(`touse') ///
				csavars(`csa_full') ///
				`constant'
			
			local valid_panels = r(valid_panels)
			local k_est = r(k)
			local k_lr_est = `k_est'
			local ncoefs_sr = r(ncoefs_sr)
			
			di
			di in gr "  ► " in ye "`valid_panels'" in gr "/" in ye "`npanels'" ///
				in gr " panels estimated successfully"
			di in gr "  ► ECM form: CSA in error correction term only"
			
			if `valid_panels' == 0 {
				di as err "  ERROR: No panels could be estimated"
				exit 2000
			}
			
			* Store matrices (remap phi → rho for unified display)
			tempname rho_all beta_all halflife_all phi_all sr_all
			tempname rho_mg beta_mg halflife_mg phi_mg sr_mg
			tempname beta_V rho_V csa_V
			tempname csa_coef_mg
			
			matrix `rho_all' = r(phi_all)
			matrix `beta_all' = r(beta_all)
			matrix `halflife_all' = r(halflife_all)
			matrix `phi_all' = r(ar_all)
			matrix `sr_all' = r(sr_all)
			matrix `rho_mg' = r(phi_mg)
			matrix `beta_mg' = r(beta_mg)
			matrix `halflife_mg' = r(halflife_mg)
			matrix `phi_mg' = r(ar_mg)
			matrix `sr_mg' = r(sr_mg)
			matrix `beta_V' = r(beta_V)
			matrix `rho_V' = r(phi_V)
			matrix `csa_coef_mg' = r(csa_coef_mg)
			matrix `csa_V' = r(csa_V)
		}
		else {
			* Standard ARDL form
			_xtcspqardl_estimate, depvar(`depvar') indepvars(`indepvars') ///
				lrvars(`lr') p(`p') qlags(`qlags') ///
				tau(`tau') ivar(`ivar') tvar(`tvar') touse(`touse') ///
				csavars(`csa_full') ///
				`constant'
			
			local valid_panels = r(valid_panels)
			local k_est = r(k)
			local k_lr_est = r(k_lr)
			local ncoefs_sr = r(ncoefs_sr)
			
			di
			di in gr "  ► " in ye "`valid_panels'" in gr "/" in ye "`npanels'" ///
				in gr " panels estimated successfully"
			
			if `valid_panels' == 0 {
				di as err "  ERROR: No panels could be estimated"
				exit 2000
			}
			
			* Store matrices
			tempname rho_all beta_all halflife_all phi_all sr_all
			tempname rho_mg beta_mg halflife_mg phi_mg sr_mg
			tempname beta_V rho_V csa_V
			tempname csa_coef_mg
			
			matrix `rho_all' = r(rho_all)
			matrix `beta_all' = r(beta_all)
			matrix `halflife_all' = r(halflife_all)
			matrix `phi_all' = r(phi_all)
			matrix `sr_all' = r(sr_all)
			matrix `rho_mg' = r(rho_mg)
			matrix `beta_mg' = r(beta_mg)
			matrix `halflife_mg' = r(halflife_mg)
			matrix `phi_mg' = r(phi_mg)
			matrix `sr_mg' = r(sr_mg)
			matrix `beta_V' = r(beta_V)
			matrix `rho_V' = r(rho_V)
			matrix `csa_coef_mg' = r(csa_coef_mg)
			matrix `csa_V' = r(csa_V)
		}
		
		* ==============================================================
		* DISPLAY TABLES — CS-PQARDL
		* ==============================================================
		if "`notable'" == "" {
			
			* Table 1: Long-Run Cointegrating Parameters
			di
			di in smcl in gr "{hline 78}"
			di in smcl in gr "  {bf:╔══════════════════════════════════════════════════════════════════════╗}"
			if "`ecm'" != "" {
				di in smcl in gr "  {bf:║   Table 1: ECM Long-Run Coefficients                                ║}"
			}
			else {
				di in smcl in gr "  {bf:║   Table 1: Long-Run Cointegrating Parameters                       ║}"
			}
			di in smcl in gr "  {bf:╚══════════════════════════════════════════════════════════════════════╝}"
			di in smcl in gr "{hline 78}"
			di in gr "  {ralign 14:Variable}" _c
			di in gr " {ralign 8:Quantile}" _c
			di in gr " {ralign 12:Coef.}" _c
			di in gr " {ralign 10:Std.Err.}" _c
			di in gr " {ralign 10:z-stat}" _c
			di in gr " {ralign 10:P>|z|}" _c
			di in gr "  {ralign 4: }"
			di in smcl in gr "{hline 78}"
			
			local ti = 0
			foreach tauval of local tau {
				local ++ti
				di in smcl in ye "  ── τ = " %5.2f `tauval' " " in gr "{hline 58}"
				
				local vnum = 0
				foreach v of local lr_x {
					local ++vnum
					local bcol = (`ti' - 1) * `k_lrx' + `vnum'
					local est = `beta_mg'[1, `bcol']
					if `est' == . {
						di in gr "  {ralign 14:`v'}" _c
						di in gr " {ralign 8:" %5.2f `tauval' "}" _c
						di in gr " {ralign 12:       n/a}"
						continue
					}
					local var_val = `beta_V'[`bcol', `bcol']
					local se = .
					local zstat = .
					local pval = .
					if `var_val' > 0 & `var_val' != . {
						local se = sqrt(`var_val')
						if `se' > 0 {
							local zstat = `est' / `se'
							local pval = 2 * (1 - normal(abs(`zstat')))
						}
					}
					local stars ""
					if `pval' != . & `pval' < 1 {
						if `pval' < 0.01      local stars "***"
						else if `pval' < 0.05 local stars "** "
						else if `pval' < 0.10 local stars "*  "
					}
					di in gr "  {ralign 14:`v'}" _c
					di in gr " {ralign 8:" %5.2f `tauval' "}" _c
					di as res " {ralign 12:" %10.4f `est' "}" _c
					if `se' != . {
						di in gr " {ralign 10:" %8.4f `se' "}" _c
						di in gr " {ralign 10:" %8.3f `zstat' "}" _c
						if `pval' < 0.01 {
							di as err " {ralign 10:" %8.4f `pval' "}" _c
						}
						else if `pval' < 0.05 {
							di as res " {ralign 10:" %8.4f `pval' "}" _c
						}
						else {
							di in gr " {ralign 10:" %8.4f `pval' "}" _c
						}
						di in ye " `stars'"
					}
					else {
						di ""
					}
				}
			}
			di in smcl in gr "{hline 78}"
			di in gr "  *** p<0.01, ** p<0.05, * p<0.10"
			di in gr "  CSA (nuisance) coefficients: use {bf:showcsa} option to display"
			
			* Table 2: ECM Speed of Adjustment
			di
			di in smcl in gr "{hline 78}"
			di in smcl in gr "  {bf:╔══════════════════════════════════════════════════════════════════════╗}"
			if "`ecm'" != "" {
				di in smcl in gr "  {bf:║   Table 2: ECM Speed of Adjustment φ(τ)                            ║}"
			}
			else {
				di in smcl in gr "  {bf:║   Table 2: ECM Speed of Adjustment ρ(τ)                            ║}"
			}
			di in smcl in gr "  {bf:╚══════════════════════════════════════════════════════════════════════╝}"
			di in smcl in gr "{hline 78}"
			di in gr "  {ralign 10:Quantile}" _c
			di in gr " {ralign 12:ρ(τ)}" _c
			di in gr " {ralign 10:Std.Err.}" _c
			di in gr " {ralign 10:z-stat}" _c
			di in gr " {ralign 10:P>|z|}" _c
			di in gr " {ralign 10:Half-Life}" _c
			di in gr " {ralign 12:Status}"
			di in smcl in gr "{hline 78}"
			
			local ti = 0
			foreach tauval of local tau {
				local ++ti
				local rho_val = `rho_mg'[1, `ti']
				local hl_val = `halflife_mg'[1, `ti']
				
				if `rho_val' == . {
					di in gr "  {ralign 10:τ=" %4.2f `tauval' "}" _c
					di in gr " {ralign 12:       n/a}"
					continue
				}
				
				local rho_var = `rho_V'[`ti', `ti']
				local se = .
				local zstat = .
				local pval = .
				if `rho_var' > 0 & `rho_var' != . {
					local se = sqrt(`rho_var')
					if `se' > 0 {
						local zstat = `rho_val' / `se'
						local pval = 2 * (1 - normal(abs(`zstat')))
					}
				}
				
				if `rho_val' < -0.5 local status "Strong"
				else if `rho_val' < -0.1 local status "Moderate"
				else if `rho_val' < 0 local status "Weak"
				else local status "No conv."
				
				di in gr "  {ralign 10:τ=" %4.2f `tauval' "}" _c
				if `rho_val' < -0.1 {
					di in ye " {ralign 12:" %10.4f `rho_val' "}" _c
				}
				else if `rho_val' < 0 {
					di in gr " {ralign 12:" %10.4f `rho_val' "}" _c
				}
				else {
					di as err " {ralign 12:" %10.4f `rho_val' "}" _c
				}
				if `se' != . {
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
				if `hl_val' != . & `hl_val' > 0 {
					di in ye " {ralign 10:" %8.2f `hl_val' "}" _c
				}
				else {
					di in gr " {ralign 10:    .}" _c
				}
				if `rho_val' < -0.1 {
					di in ye " {ralign 12:`status'}"
				}
				else if `rho_val' < 0 {
					di in gr " {ralign 12:`status'}"
				}
				else {
					di as err " {ralign 12:`status'}"
				}
			}
			di in smcl in gr "{hline 78}"
		}
		
		* CSA table (showcsa option) for CS-PQARDL
		if "`showcsa'" != "" {
			local n_csa_total = colsof(`csa_coef_mg') / `ntau'
			di
			di in smcl in gr "{hline 78}"
			di in smcl in gr "  {bf:╔══════════════════════════════════════════════════════════════════════╗}"
			di in smcl in gr "  {bf:║   CSA (Cross-Sectional Average) Coefficients                       ║}"
			di in smcl in gr "  {bf:║   Nuisance parameters — absorb unobserved common factors            ║}"
			di in smcl in gr "  {bf:╚══════════════════════════════════════════════════════════════════════╝}"
			di in smcl in gr "{hline 78}"
			di in gr "  {ralign 14:Variable}" _c
			di in gr " {ralign 8:Quantile}" _c
			di in gr " {ralign 12:Coef.}" _c
			di in gr " {ralign 10:Std.Err.}" _c
			di in gr " {ralign 10:z-stat}" _c
			di in gr " {ralign 10:P>|z|}" _c
			di in gr "  {ralign 4: }"
			di in smcl in gr "{hline 78}"
			
			* Build CSA variable names: y, x1, x2, ... for each lag
			local n_orig = 1 + `k'
			local ti = 0
			foreach tauval of local tau {
				local ++ti
				di in smcl in ye "  -- tau = " %5.2f `tauval' " " in gr "{hline 58}"
				
				local ci = 0
				forvalues lag = 0/`cr_lags' {
					local vi = 0
					foreach vn in `depvar' `indepvars' {
						local ++vi
						local ++ci
						local ccol = (`ti' - 1) * `n_csa_total' + `ci'
						local ccols = colsof(`csa_coef_mg')
						if `ccol' > `ccols' continue
						local est = `csa_coef_mg'[1, `ccol']
						if `est' == . continue
						
						if `lag' == 0 {
							local clabel "csa(`vn')"
						}
						else {
							local clabel "L`lag'.csa(`vn')"
						}
						
						local var_val = `csa_V'[`ccol', `ccol']
						local se = .
						local zstat = .
						local pval = .
						if `var_val' > 0 & `var_val' != . {
							local se = sqrt(`var_val')
							if `se' > 0 {
								local zstat = `est' / `se'
								local pval = 2 * (1 - normal(abs(`zstat')))
							}
						}
						local stars ""
						if `pval' != . & `pval' < 1 {
							if `pval' < 0.01      local stars "***"
							else if `pval' < 0.05 local stars "** "
							else if `pval' < 0.10 local stars "*  "
						}
						di in gr "  {ralign 14:`clabel'}" _c
						di in gr " {ralign 8:" %5.2f `tauval' "}" _c
						di as res " {ralign 12:" %10.4f `est' "}" _c
						if `se' != . {
							di in gr " {ralign 10:" %8.4f `se' "}" _c
							di in gr " {ralign 10:" %8.3f `zstat' "}" _c
							if `pval' < 0.01 {
								di as err " {ralign 10:" %8.4f `pval' "}" _c
							}
							else if `pval' < 0.05 {
								di as res " {ralign 10:" %8.4f `pval' "}" _c
							}
							else {
								di in gr " {ralign 10:" %8.4f `pval' "}" _c
							}
							di in ye " `stars'"
						}
						else {
							di ""
						}
					}
				}
			}
			di in smcl in gr "{hline 78}"
			di in gr "  *** p<0.01, ** p<0.05, * p<0.10"
			di in gr "  CSA variables proxy unobserved common factors (nuisance)"
		}
		
		* Post to e()
		ereturn clear
		ereturn post, esample(`touse') obs(`nobs')
		
		ereturn matrix beta_mg = `beta_mg'
		ereturn matrix rho_mg = `rho_mg'
		ereturn matrix halflife_mg = `halflife_mg'
		ereturn matrix phi_mg = `phi_mg'
		ereturn matrix sr_mg = `sr_mg'
		ereturn matrix beta_V = `beta_V'
		ereturn matrix rho_V = `rho_V'
		capture ereturn matrix sr_V = `sr_V'
		ereturn matrix beta_all = `beta_all'
		ereturn matrix rho_all = `rho_all'
		ereturn matrix halflife_all = `halflife_all'
		ereturn matrix csa_coef_mg = `csa_coef_mg'
		ereturn matrix csa_V = `csa_V'
		
		ereturn scalar N = `nobs'
		ereturn scalar n_g = `npanels'
		ereturn scalar valid_panels = `valid_panels'
		ereturn scalar p = `p'
		ereturn scalar k = `k'
		ereturn scalar k_lr = `k_lrx'
		ereturn scalar ntau = `ntau'
		ereturn scalar cr_lags = `cr_lags'
		ereturn scalar avg_T = `avg_T'
		
		ereturn local depvar "`depvar'"
		ereturn local indepvars "`indepvars'"
		ereturn local lrvars "`lr_x'"
		ereturn local lr_y "`lr_y'"
		ereturn local ivar "`ivar'"
		ereturn local tvar "`tvar'"
		ereturn local cmd "xtcspqardl"
		if "`ecm'" != "" {
			ereturn local estimator "cspqardl_ecm"
			ereturn local title "CS-PQARDL ECM Estimation"
		}
		else {
			ereturn local estimator "cspqardl"
			ereturn local title "CS-PQARDL Estimation"
		}
		ereturn local ardl_order "CS-PQARDL(`ardl_order')"
		ereturn local qlags "`qlags'"
		
		if "`pmg'" != "" ereturn local model "pmg"
		else if "`mg'" != "" ereturn local model "mg"
		else if "`dfe'" != "" ereturn local model "dfe"
	}
	
	* ================================================================
	* ADVANCED ANALYSIS (full option)
	* ================================================================
	if "`full'" != "" {
		if "`qccemg'" != "" | "`qccepmg'" != "" {
			_xtcspqardl_advanced, estimator(`est_type') tau(`tau') ///
				depvar(`depvar') indepvars(`indepvars') k(`k')
		}
		else {
			_xtcspqardl_advanced, estimator(cspqardl) tau(`tau') ///
				depvar(`depvar') indepvars(`indepvars') k(`k') ///
				lrvars(`lr') `ecm'
		}
	}
	
	* ================================================================
	* GRAPHS (graph option)
	* ================================================================
	if "`graph'" != "" {
		if "`qccemg'" != "" | "`qccepmg'" != "" {
			xtcspqardl_graph, tau(`tau') k(`k') ///
				depvar(`depvar') indepvars(`indepvars') ///
				estimator(`est_type') npanels(`npanels')
		}
		else {
			xtcspqardl_graph, tau(`tau') k(`k') ///
				depvar(`depvar') indepvars(`indepvars') ///
				estimator(cspqardl) npanels(`npanels') ///
				lrvars(`lr') `ecm'
		}
	}
	
	* ================================================================
	* FOOTER
	* ================================================================
	di
	di in smcl in gr "{hline 78}"
	di in gr "  {bf:XTCSPQARDL v1.0.0}" _c
	if "`qccemg'" != "" | "`qccepmg'" != "" {
		di in gr " — `est_label' (HLP 2018)"
	}
	else {
		di in gr " — CS Panel Quantile ARDL" _c
		di in ye "  CS-PQARDL(`ardl_order')"
	}
	di in smcl in gr "{hline 78}"
	di
end


* ----- Display (replay) -----
program define Display
	syntax [, Level(integer `c(level)')]
	di
	di in gr "  Estimator: " in ye "`e(estimator)'"
	di in gr "  (Use {bf:ereturn list} to view all stored results)"
end
