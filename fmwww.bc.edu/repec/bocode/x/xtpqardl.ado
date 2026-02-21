*! xtpqardl v1.0.1  20feb2026  Dr Merwan Roudane  merwanroudane920@gmail.com
*! Panel Quantile Autoregressive Distributed Lag (PQARDL) Model
*! Combines Panel ARDL (PMG/MG/DFE) with Quantile Regression
*! Based on: Cho, Kim & Shin (2015), Bildirici (2022), Pesaran et al. (1999)

capture program drop xtpqardl
program define xtpqardl, eclass
	version 15.1
	if replay() {
		if ("`e(cmd)'" != "xtpqardl") error 301
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
		 PMG MG DFE ECM FULL REPLACE ///
		 SRTable HALFlife IRF(integer 0) ///
		 GRaph NOTABle]
	
	* ================================================================
	* Validate inputs
	* ================================================================
	if ("`mg'" != "") + ("`dfe'" != "") + ("`pmg'" != "") > 1 {
		di as err "choose only one of pmg, mg, or dfe"
		exit 198
	}
	if "`mg'" == "" & "`dfe'" == "" local pmg "pmg"
	
	local ntau : word count `tau'
	if `ntau' < 1 {
		di as err "tau() must specify at least one quantile"
		exit 198
	}
	
	* Parse p
	if `p' < 1 {
		di as err "p() must be at least 1"
		exit 198
	}
	
	* Parse q — can be a single number or per-variable list
	if "`q'" == "" local q "1"
	
	* Validate lagsel
	if "`lagsel'" != "" {
		if !inlist("`lagsel'", "aic", "bic", "both") {
			di as err "lagsel() must be one of: aic, bic, both"
			exit 198
		}
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
	
	* LR variables
	if "`lr'" == "" {
		di as err "lr() option required — specify long-run level variables"
		di as err "  Example: lr(L.y x1 x2) or lr(ly x1 x2)"
		exit 198
	}
	
	* Parse lr: first var = lagged y level, rest = x levels
	tokenize `lr'
	local lr_y `1'
	mac shift
	local lr_x `*'
	local k_lr = wordcount("`lr'")
	local k_lrx = wordcount("`lr_x'")
	
	* EC variable name
	if "`ec'" == "" local ec "ECT"
	if "`replace'" != "" capture drop `ec'
	
	* Parse q per variable
	local nq : word count `q'
	if `nq' == 1 {
		* Same q for all
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
		di as err "q() must be a single number or k numbers (one per indepvar)"
		exit 198
	}
	
	* Panel info
	qui levelsof `ivar' if `touse', local(ids)
	local npanels : word count `ids'
	qui count if `touse'
	local nobs = r(N)
	
	* ================================================================
	* BIC LAG SELECTION (if lagsel specified)
	* ================================================================
	if "`lagsel'" != "" {
		di
		di in smcl in gr "{hline 78}"
		di in gr "  {bf:PQARDL Lag Order Selection (`lagsel')}"
		di in smcl in gr "{hline 78}"
		
		* Test p = 1..pmax and q = 1..qmax using OLS at conditional mean
		* BIC = n*ln(RSS/n) + k*ln(n)
		
		local best_bic = .
		local best_p = 1
		local best_qlags ""
		forvalues j = 1/`k' {
			local best_q`j' = 1
		}
		
		* For simplicity, same q for all x: search over p and q
		di in gr "  BIC Grid: rows = p, columns = q"
		di in smcl in gr "  {hline 62}"
		
		di in gr "  {ralign 6:p \ q}" _c
		forvalues jq = 1/`qmax' {
			di in gr "  {ralign 10:q=`jq'}" _c
		}
		di ""
		di in smcl in gr "  {hline 62}"
		
		forvalues ip = 1/`pmax' {
			di in gr "  {ralign 6:p=`ip'}" _c
			
			forvalues jq = 1/`qmax' {
				* Build regressor list for this (p,q) combo using plain vars
				* Pre-generate temp vars for AR lags
				local test_ar ""
				if `ip' > 1 {
					forvalues lag = 1/`= `ip' - 1' {
						tempvar test_ar_`ip'_`jq'_`lag'
						capture qui gen double `test_ar_`ip'_`jq'_`lag'' = L`lag'.`depvar' if `touse'
						if _rc == 0 {
							local test_ar "`test_ar' `test_ar_`ip'_`jq'_`lag''"
						}
					}
				}
				* Pre-generate temp vars for SR lags
				local test_sr ""
				forvalues xj = 1/`k' {
					local xvar : word `xj' of `indepvars'
					tempvar test_x_`ip'_`jq'_`xj'_0
					capture qui gen double `test_x_`ip'_`jq'_`xj'_0' = `xvar' if `touse'
					if _rc == 0 {
						local test_sr "`test_sr' `test_x_`ip'_`jq'_`xj'_0'"
					}
					if `jq' > 1 {
						forvalues lag = 1/`= `jq' - 1' {
							tempvar test_x_`ip'_`jq'_`xj'_`lag'
							capture qui gen double `test_x_`ip'_`jq'_`xj'_`lag'' = L`lag'.`xvar' if `touse'
							if _rc == 0 {
								local test_sr "`test_sr' `test_x_`ip'_`jq'_`xj'_`lag''"
							}
						}
					}
				}
				* Pre-generate temp vars for LR variables
				local test_lr ""
				forvalues lj = 1/`k_lr' {
					local lrv : word `lj' of `lr'
					tempvar test_lr_`ip'_`jq'_`lj'
					capture qui gen double `test_lr_`ip'_`jq'_`lj'' = `lrv' if `touse'
					if _rc == 0 {
						local test_lr "`test_lr' `test_lr_`ip'_`jq'_`lj''"
					}
				}
				
				* Also need plain depvar for reg
				tempvar test_dv_`ip'_`jq'
				qui gen double `test_dv_`ip'_`jq'' = `depvar' if `touse'
				
				local test_reg "`test_lr' `test_ar' `test_sr'"
				
				* Run OLS on pooled data
				capture qui reg `test_dv_`ip'_`jq'' `test_reg' if `touse'
				if _rc == 0 & e(N) > 5 {
					local n_bic = e(N)
					local k_bic = e(df_m) + 1
					local rss = e(rss)
					local bic_val = `n_bic' * ln(`rss'/`n_bic') + `k_bic' * ln(`n_bic')
					
					if `bic_val' < `best_bic' | `best_bic' == . {
						di as res " " %9.2f `bic_val' "*" _c
						local best_bic = `bic_val'
						local best_p = `ip'
						forvalues j = 1/`k' {
							local best_q`j' = `jq'
						}
					}
					else {
						di in gr "  " %9.2f `bic_val' " " _c
					}
				}
				else {
					di in gr "  {ralign 10:    .}" _c
				}
			}
			di ""
		}
		
		di in smcl in gr "  {hline 62}"
		
		* Update p and q with optimal
		local p = `best_p'
		local qlags ""
		local qdisp ""
		forvalues j = 1/`k' {
			local qlags "`qlags' `best_q`j''"
			local qdisp "`qdisp',`best_q`j''"
		}
		local qlags = strtrim("`qlags'")
		
		di as res "  ► Optimal: PQARDL(`p'`qdisp')" ///
			in gr "  BIC = " %9.2f `best_bic'
		di in smcl in gr "{hline 78}"
	}
	
	* ================================================================
	* Build ARDL order string: PQARDL(p, q1, q2, ...)
	* ================================================================
	local ardl_order "`p'"
	forvalues j = 1/`k' {
		local qj : word `j' of `qlags'
		local ardl_order "`ardl_order',`qj'"
	}
	
	* ================================================================
	* DISPLAY HEADER
	* ================================================================
	if "`pmg'" != "" local model_label "Pooled Mean Group (PMG)"
	else if "`mg'" != "" local model_label "Mean Group (MG)"
	else if "`dfe'" != "" local model_label "Dynamic Fixed Effects (DFE)"
	
	di
	di in smcl in gr "{hline 78}"
	di in smcl in gr "  {bf:╔══════════════════════════════════════════════════════════════════════╗}"
	di in smcl in gr "  {bf:║}" _col(5) in ye ///
		"  XTPQARDL — Panel Quantile ARDL" ///
		_col(72) in gr "{bf:║}"
	di in smcl in gr "  {bf:║}" _col(5) in ye ///
		"  Version 1.0.1" ///
		_col(72) in gr "{bf:║}"
	di in smcl in gr "  {bf:╚══════════════════════════════════════════════════════════════════════╝}"
	di in smcl in gr "{hline 78}"
	di in gr "  Model:            " in ye "`model_label'"
	di in gr "  Dep. variable:    " in ye "`depvar'"
	di in gr "  SR variables:     " in ye "`indepvars'"
	di in gr "  LR variables:     " in ye "`lr_x'"
	di in gr "  LR depvar (ECT):  " in ye "`lr_y'"
	di in gr "  PQARDL(" in ye "`ardl_order'" in gr ")"
	di in gr "  Panels (N):       " in ye "`npanels'"
	di in gr "  Time periods:     " in ye "`= `nobs' / `npanels''"
	di in gr "  Observations:     " in ye "`nobs'"
	di in gr "  Quantiles:        " _c
	foreach tauval of local tau {
		di in ye %5.2f `tauval' " " _c
	}
	di ""
	
	* Show regressor list
	di in smcl in gr "{hline 78}"
	di in gr "  Regressors per panel:"
	di in gr "    ECT:    " in ye "`lr_y'" in gr " (speed of adjustment ρ)"
	di in gr "    LR:     " in ye "`lr_x'" in gr " (long-run β = -coef/ρ)"
	if `p' > 1 {
		di in gr "    AR:     " _c
		forvalues lag = 1/`= `p' - 1' {
			di in ye "L`lag'.`depvar' " _c
		}
		di ""
	}
	di in gr "    SR:     " _c
	forvalues j = 1/`k' {
		local xvar : word `j' of `indepvars'
		local qj : word `j' of `qlags'
		di in ye "`xvar'" _c
		if `qj' > 1 {
			forvalues lag = 1/`= `qj' - 1' {
				di in ye " L`lag'.`xvar'" _c
			}
		}
		if `j' < `k' di in gr ", " _c
	}
	di ""
	di in smcl in gr "{hline 78}"
	
	* ================================================================
	* ESTIMATION (PMG / MG)
	* ================================================================
	if "`dfe'" == "" {
		di
		di in gr "  {bf:Step 1:} Estimating PQARDL(`ardl_order') per panel..."
		
		_xtpqardl_estimate, depvar(`depvar') indepvars(`indepvars') ///
			lrvars(`lr') p(`p') qlags(`qlags') ///
			tau(`tau') ivar(`ivar') tvar(`tvar') touse(`touse') ///
			`constant'
		
		local valid_panels = r(valid_panels)
		local k_est = r(k)
		local k_lr_est = r(k_lr)
		local ncoefs_sr = r(ncoefs_sr)
		
		di in gr "  ► " in ye "`valid_panels'" in gr "/" in ye "`npanels'" ///
			in gr " panels estimated successfully"
		
		if `valid_panels' == 0 {
			di as err "  ERROR: No panels could be estimated"
			di as err "  Check that lr() variables exist and have sufficient variation"
			exit 2000
		}
		
		* Store matrices
		tempname rho_all beta_all halflife_all phi_all sr_all
		tempname rho_mg beta_mg halflife_mg phi_mg sr_mg
		tempname beta_V rho_V
		
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
		
		* ==============================================================
		* DISPLAY TABLES
		* ==============================================================
		if "`notable'" == "" {
			
			* =====================================================
			* TABLE 1: Long-Run Cointegrating Parameters β(τ)
			* =====================================================
			di
			di in smcl in gr "{hline 78}"
			di in smcl in gr "  {bf:╔══════════════════════════════════════════════════════════════════════╗}"
			di in smcl in gr "  {bf:║   Table 1: Long-Run Cointegrating Parameters β(τ)                  ║}"
			di in smcl in gr "  {bf:║   β_j(τ) = −coef(x_j) / ρ(τ)                                      ║}"
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
						di in gr " {ralign 12:       n/a}" _c
						di in gr " {ralign 10:       }" _c
						di in gr " {ralign 10: }" _c
						di in gr " {ralign 10: }"
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
						di in gr " {ralign 10:    .}" _c
						di in gr " {ralign 10:    .}" _c
						di in gr " {ralign 10:    .}"
					}
				}
			}
			di in smcl in gr "{hline 78}"
			di in gr "  *** p<0.01, ** p<0.05, * p<0.10"
			
			* =====================================================
			* TABLE 2: ECM Speed of Adjustment ρ(τ)
			* =====================================================
			di
			di in smcl in gr "{hline 78}"
			di in smcl in gr "  {bf:╔══════════════════════════════════════════════════════════════════════╗}"
			di in smcl in gr "  {bf:║   Table 2: ECM Speed of Adjustment ρ(τ)                            ║}"
			di in smcl in gr "  {bf:║   ρ(τ) = coef(`lr_y') — should be negative for convergence    ║}"
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
				
				* Skip quantiles where estimation failed
				if `rho_val' == . {
					di in gr "  {ralign 10:τ=" %4.2f `tauval' "}" _c
					di in gr " {ralign 12:       n/a}" _c
					di in gr " {ralign 10: }" _c
					di in gr " {ralign 10: }" _c
					di in gr " {ralign 10: }" _c
					di in gr " {ralign 10:   n/a}" _c
					di in gr " {ralign 12:   —}"
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
				
				if `rho_val' < -0.5 local status "Strong ✓"
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
					di in gr " {ralign 10:    ∞}" _c
				}
				
				if `rho_val' < -0.1 {
					di in ye " {ralign 12:`status'}"
				}
				else {
					di as err " {ralign 12:`status'}"
				}
			}
			di in smcl in gr "{hline 78}"
			di in gr "  Half-life = ln(2)/|" in ye "ρ(τ)" in gr "| — periods to close 50% of disequilibrium"
			
			* =====================================================
			* TABLE 3: Short-Run ECM Parameters
			* =====================================================
			di
			di in smcl in gr "{hline 78}"
			di in smcl in gr "  {bf:╔══════════════════════════════════════════════════════════════════════╗}"
			di in smcl in gr "  {bf:║   Table 3: Short-Run Error Correction Parameters                   ║}"
			di in smcl in gr "  {bf:║   Δy_it = ρ(τ)·ECT_{t-1} + Σφ*Δy_{t-j} + Σθ·Δx_{t-m} + ε        ║}"
			di in smcl in gr "  {bf:╚══════════════════════════════════════════════════════════════════════╝}"
			di in smcl in gr "{hline 78}"
			di in gr "  {ralign 16:Variable}" _c
			di in gr " {ralign 8:Quantile}" _c
			di in gr " {ralign 12:Coef.}" _c
			di in gr " {ralign 30:Interpretation}"
			di in smcl in gr "{hline 78}"
			
			local ti = 0
			foreach tauval of local tau {
				local ++ti
				di in smcl in ye "  ── τ = " %5.2f `tauval' " " in gr "{hline 58}"
				
				* ECT: ρ(τ) — speed of adjustment
				local rho_val = `rho_mg'[1, `ti']
				if `rho_val' == . {
					di in gr "  {ralign 16:ECT(t-1)}" _c
					di in gr " {ralign 8:" %5.2f `tauval' "}" _c
					di in gr " {ralign 12:       n/a}" _c
					di in gr " {ralign 30: (insufficient obs.)}"
					continue
				}
				if `rho_val' < -0.1 {
					di in ye "  {ralign 16:ECT(t-1)}" _c
				}
				else {
					di as err "  {ralign 16:ECT(t-1)}" _c
				}
				di in gr " {ralign 8:" %5.2f `tauval' "}" _c
				if `rho_val' < 0 {
					di in ye " {ralign 12:" %10.4f `rho_val' "}" _c
				}
				else {
					di as err " {ralign 12:" %10.4f `rho_val' "}" _c
				}
				di in gr " {ralign 30:Speed of adjustment}"
				
				* AR lags (if p > 1): D.L1.y, D.L2.y, ...
				if `p' > 1 {
					local phi_cols = colsof(`phi_mg')
					local ncoefs_ar = `p' - 1
					forvalues j = 1/`ncoefs_ar' {
						local pcol = (`ti' - 1) * `ncoefs_ar' + `j'
						if `pcol' <= `phi_cols' {
							local est = `phi_mg'[1, `pcol']
							if `est' != . {
								if `j' == 1 {
									local ar_label "D.L1.`depvar'"
								}
								else {
									local ar_label "D.L`j'.`depvar'"
								}
								di in gr "  {ralign 16:`ar_label'}" _c
								di in gr " {ralign 8:" %5.2f `tauval' "}" _c
								di as res " {ralign 12:" %10.4f `est' "}" _c
								di in gr " {ralign 30:AR(`j') dynamics}"
							}
						}
					}
				}
				
				* SR impact for each indepvar + its lags: D.x, D.L1.x, D.L2.x, ...
				if `ncoefs_sr' > 0 {
					local sr_cols = colsof(`sr_mg')
					local sr_idx = 0
					forvalues j = 1/`k' {
						local xvar : word `j' of `indepvars'
						local qj : word `j' of `qlags'
						
						forvalues lag = 0/`= `qj' - 1' {
							local ++sr_idx
							local scol = (`ti' - 1) * `ncoefs_sr' + `sr_idx'
							if `scol' <= `sr_cols' {
								local est = `sr_mg'[1, `scol']
								if `est' != . {
									if `lag' == 0 {
										if substr("`xvar'", 1, 2) == "D." {
											local label "`xvar'"
										}
										else {
											local label "D.`xvar'"
										}
										local interp "Contemp. impact"
									}
									else if `lag' == 1 {
										if substr("`xvar'", 1, 2) == "D." {
											local label "L1.`xvar'"
										}
										else {
											local label "D.L1.`xvar'"
										}
										local interp "Lagged impact(1)"
									}
									else {
										if substr("`xvar'", 1, 2) == "D." {
											local label "L`lag'.`xvar'"
										}
										else {
											local label "D.L`lag'.`xvar'"
										}
										local interp "Lagged impact(`lag')"
									}
									di in gr "  {ralign 16:`label'}" _c
									di in gr " {ralign 8:" %5.2f `tauval' "}" _c
									di as res " {ralign 12:" %10.4f `est' "}" _c
									di in gr " {ralign 30:`interp'}"
								}
							}
						}
					}
				}
			}
			di in smcl in gr "{hline 78}"
			di in gr "  ECT = `lr_y' − β(τ)'X  (error correction term)"
			di in gr "  D. = first difference, L1. = 1-period lag, L2. = 2-period lag"
			di in smcl in gr "{hline 78}"
		}
		
		* ==============================================================
		* Per-panel ECT table
		* ==============================================================
		if "`srtable'" != "" | "`full'" != "" {
			di
			di in smcl in gr "{hline 78}"
			di in smcl in gr "  {bf:╔══════════════════════════════════════════════════════════════════════╗}"
			di in smcl in gr "  {bf:║   Per-Panel ECT Speed of Adjustment ρ_i(τ)                         ║}"
			di in smcl in gr "  {bf:╚══════════════════════════════════════════════════════════════════════╝}"
			di in smcl in gr "{hline 78}"
			
			di in gr "  {ralign 10:Panel}" _c
			foreach tauval of local tau {
				di in gr " {ralign 12:τ=" %4.2f `tauval' "}" _c
			}
			di ""
			di in smcl in gr "{hline 78}"
			
			forvalues i = 1/`npanels' {
				di in gr "  {ralign 10:`i'}" _c
				forvalues t = 1/`ntau' {
					local rv = `rho_all'[`i', `t']
					if `rv' != . {
						if `rv' < -0.5 {
							di in ye " {ralign 12:" %10.4f `rv' "}" _c
						}
						else if `rv' < 0 {
							di in gr " {ralign 12:" %10.4f `rv' "}" _c
						}
						else {
							di as err " {ralign 12:" %10.4f `rv' "}" _c
						}
					}
					else {
						di in gr " {ralign 12:     n/a}" _c
					}
				}
				di ""
			}
			di in smcl in gr "{hline 78}"
			di in gr "  {bf:Yellow} = strong convergence (ρ < -0.5)"
			di in gr "  {bf:Gray}   = moderate   |   {err:Red} = non-convergent"
		}
		
		* ==============================================================
		* Half-life table
		* ==============================================================
		if "`halflife'" != "" {
			di
			di in smcl in gr "{hline 78}"
			di in smcl in gr "  {bf:╔══════════════════════════════════════════════════════════════════════╗}"
			di in smcl in gr "  {bf:║   Half-Life of Adjustment HL_i(τ) = ln(2)/|ρ_i(τ)|                 ║}"
			di in smcl in gr "  {bf:╚══════════════════════════════════════════════════════════════════════╝}"
			di in smcl in gr "{hline 78}"
			
			di in gr "  {ralign 10:Panel}" _c
			foreach tauval of local tau {
				di in gr " {ralign 12:τ=" %4.2f `tauval' "}" _c
			}
			di ""
			di in smcl in gr "{hline 78}"
			
			forvalues i = 1/`npanels' {
				di in gr "  {ralign 10:`i'}" _c
				forvalues t = 1/`ntau' {
					local hv = `halflife_all'[`i', `t']
					if `hv' != . & `hv' > 0 {
						if `hv' < 5 {
							di in ye " {ralign 12:" %10.2f `hv' "}" _c
						}
						else {
							di in gr " {ralign 12:" %10.2f `hv' "}" _c
						}
					}
					else {
						di in gr " {ralign 12:     n/a}" _c
					}
				}
				di ""
			}
			di in smcl in gr "{hline 78}"
			di in gr "  Yellow = fast adjustment (< 5 periods)"
			
			* Mean half-life by quantile
			di in ye "  {ralign 10:Mean}" _c
			forvalues t = 1/`ntau' {
				local mhl = `halflife_mg'[1, `t']
				if `mhl' > 0 & `mhl' != . {
					di in ye " {ralign 12:" %10.2f `mhl' "}" _c
				}
				else {
					di in gr " {ralign 12:     n/a}" _c
				}
			}
			di ""
			di in smcl in gr "{hline 78}"
		}
		
		* ==============================================================
		* IRF simulation by quantile
		* ==============================================================
		if `irf' > 0 {
			di
			di in smcl in gr "{hline 78}"
			di in smcl in gr "  {bf:╔══════════════════════════════════════════════════════════════════════╗}"
			di in smcl in gr "  {bf:║   Impulse Response Function by Quantile                            ║}"
			di in smcl in gr "  {bf:║   Response to a 1-unit shock via ECM mechanism                     ║}"
			di in smcl in gr "  {bf:╚══════════════════════════════════════════════════════════════════════╝}"
			di in smcl in gr "{hline 78}"
			
			di in gr "  {ralign 8:Period}" _c
			foreach tauval of local tau {
				di in gr " {ralign 12:τ=" %4.2f `tauval' "}" _c
			}
			di ""
			di in smcl in gr "{hline 78}"
			
			forvalues t = 0/`irf' {
				di in gr "  {ralign 8:`t'}" _c
				local ti = 0
				foreach tauval of local tau {
					local ++ti
					local rv = `rho_mg'[1, `ti']
					if `rv' != . & `rv' < 0 {
						local irf_val = (1 + `rv')^`t'
						if `irf_val' > 0.5 {
							di in ye " {ralign 12:" %10.4f `irf_val' "}" _c
						}
						else {
							di in gr " {ralign 12:" %10.4f `irf_val' "}" _c
						}
					}
					else {
						di as err " {ralign 12:     div.}" _c
					}
				}
				di ""
			}
			di in smcl in gr "{hline 78}"
		}
		
		* ==============================================================
		* Wald tests (if >= 2 quantiles)
		* ==============================================================
		if `ntau' >= 2 {
			_xtpqardl_waldtest `beta_mg' `beta_V' `rho_mg' `rho_V' ///
				"`tau'" `k_lrx' `nobs'
		}
		
		* ==============================================================
		* Post results to e()
		* ==============================================================
		ereturn clear
		ereturn post, esample(`touse') obs(`nobs')
		
		ereturn matrix beta_mg = `beta_mg'
		ereturn matrix rho_mg = `rho_mg'
		ereturn matrix halflife_mg = `halflife_mg'
		ereturn matrix phi_mg = `phi_mg'
		ereturn matrix sr_mg = `sr_mg'
		
		ereturn matrix beta_V = `beta_V'
		ereturn matrix rho_V = `rho_V'
		
		ereturn matrix beta_all = `beta_all'
		ereturn matrix rho_all = `rho_all'
		ereturn matrix halflife_all = `halflife_all'
		
		ereturn scalar N = `nobs'
		ereturn scalar n_g = `npanels'
		ereturn scalar valid_panels = `valid_panels'
		ereturn scalar p = `p'
		ereturn scalar k = `k'
		ereturn scalar k_lr = `k_lrx'
		ereturn scalar ntau = `ntau'
		
		ereturn local depvar "`depvar'"
		ereturn local indepvars "`indepvars'"
		ereturn local lrvars "`lr_x'"
		ereturn local lr_y "`lr_y'"
		ereturn local ivar "`ivar'"
		ereturn local tvar "`tvar'"
		ereturn local cmd "xtpqardl"
		ereturn local title "PQARDL Estimation"
		ereturn local ardl_order "PQARDL(`ardl_order')"
		ereturn local qlags "`qlags'"
		ereturn local author "Dr Merwan Roudane"
		ereturn local email "merwanroudane920@gmail.com"
		
		if "`pmg'" != "" ereturn local model "pmg"
		else if "`mg'" != "" ereturn local model "mg"
		
		* ==============================================================
		* Graphs
		* ==============================================================
		if "`graph'" != "" {
			xtpqardl_graph, tau(`tau') p(`p') q(1) k(`k_lrx') ///
				depvar("`depvar'") indepvars("`lr_x'") ///
				ecm npanels(`npanels') ivar("`ivar'")
		}
	}
	
	* ================================================================
	* DFE ESTIMATION
	* ================================================================
	else {
		di
		di in gr "  {bf:Step 1:} Pooled quantile regression with panel FE..."
		
		qui tab `ivar' if `touse', gen(__xtpqfe_)
		local ndummies = r(r)
		local fe_vars ""
		forvalues j = 2/`ndummies' {
			local fe_vars "`fe_vars' __xtpqfe_`j'"
		}
		
		local beta_dim = `k_lrx' * `ntau'
		tempname beta_dfe beta_V_dfe rho_dfe rho_V_dfe hl_dfe
		matrix `beta_dfe' = J(1, `beta_dim', .)
		matrix `beta_V_dfe' = J(`beta_dim', `beta_dim', 0)
		matrix `rho_dfe' = J(1, `ntau', .)
		matrix `rho_V_dfe' = J(`ntau', `ntau', 0)
		matrix `hl_dfe' = J(1, `ntau', .)
		
		* Build SR regressor list
		local sr_list ""
		forvalues j = 1/`k' {
			local xvar : word `j' of `indepvars'
			local qj : word `j' of `qlags'
			local sr_list "`sr_list' `xvar'"
			if `qj' > 1 {
				forvalues lag = 1/`= `qj' - 1' {
					local sr_list "`sr_list' L`lag'.`xvar'"
				}
			}
		}
		
		local ar_list ""
		if `p' > 1 {
			forvalues lag = 1/`= `p' - 1' {
				local ar_list "`ar_list' L`lag'.`depvar'"
			}
		}
		
		local dfe_reg "`lr' `ar_list' `sr_list' `fe_vars'"
		
		local ti = 0
		foreach tauval of local tau {
			local ++ti
			
			capture qui qreg `depvar' `dfe_reg' if `touse', ///
				quantile(`= `tauval' * 100')
			
			if _rc == 0 {
				tempname b_dfe_q
				matrix `b_dfe_q' = e(b)
				
				matrix `rho_dfe'[1, `ti'] = `b_dfe_q'[1, 1]
				local rv = `b_dfe_q'[1, 1]
				if `rv' < 0 {
					matrix `hl_dfe'[1, `ti'] = ln(2) / abs(`rv')
				}
				
				if abs(`rv') > 1e-10 {
					forvalues j = 2/`k_lr' {
						local bcol = (`ti' - 1) * `k_lrx' + (`j' - 1)
						matrix `beta_dfe'[1, `bcol'] = -`b_dfe_q'[1, `j'] / `rv'
					}
				}
			}
		}
		
		capture drop __xtpqfe_*
		
		if "`notable'" == "" {
			di
			di in smcl in gr "{hline 78}"
			di in gr "  {bf:DFE Long-Run β(τ)}"
			di in smcl in gr "{hline 78}"
			di in gr "  {ralign 14:Variable}" _c
			di in gr " {ralign 8:Quantile}" _c
			di in gr " {ralign 12:Coef.}"
			di in smcl in gr "{hline 78}"
			
			local ti = 0
			foreach tauval of local tau {
				local ++ti
				di in smcl in ye "  ── τ = " %5.2f `tauval' " " in gr "{hline 40}"
				local vnum = 0
				foreach v of local lr_x {
					local ++vnum
					local bcol = (`ti' - 1) * `k_lrx' + `vnum'
					local est = `beta_dfe'[1, `bcol']
					if `est' != . {
						di in gr "  {ralign 14:`v'}" _c
						di in gr " {ralign 8:" %5.2f `tauval' "}" _c
						di as res " {ralign 12:" %10.4f `est' "}"
					}
				}
			}
			di in smcl in gr "{hline 78}"
		}
		
		ereturn clear
		ereturn post, esample(`touse') obs(`nobs')
		ereturn matrix beta_mg = `beta_dfe'
		ereturn matrix rho_mg = `rho_dfe'
		ereturn matrix halflife_mg = `hl_dfe'
		ereturn scalar N = `nobs'
		ereturn scalar n_g = `npanels'
		ereturn scalar p = `p'
		ereturn scalar k = `k'
		ereturn scalar ntau = `ntau'
		ereturn local depvar "`depvar'"
		ereturn local cmd "xtpqardl"
		ereturn local model "dfe"
		ereturn local ardl_order "PQARDL(`ardl_order')"
		ereturn local author "Dr Merwan Roudane"
	}
	
	* ================================================================
	* FOOTER
	* ================================================================
	di
	di in smcl in gr "{hline 78}"
	di in gr "  {bf:XTPQARDL v1.0.1} — Panel Quantile ARDL" ///
		_col(50) in ye "PQARDL(`ardl_order')"
	di in smcl in gr "{hline 78}"
	di
end


* ----- Display (replay) -----
program define Display
	syntax [, Level(integer `c(level)')]
	di
	di in gr "  Model: " in ye "`e(model)'" in gr "   ARDL order: " in ye "`e(ardl_order)'"
	di in gr "  (Use {bf:matrix list e(beta_mg)} to view stored coefficients)"
	di in gr "  (Use {bf:matrix list e(rho_all)} to view per-panel ECT)"
end
