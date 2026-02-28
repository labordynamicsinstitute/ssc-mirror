*! xtqsh v1.0.0  27feb2026  Dr Merwan Roudane  merwanroudane920@gmail.com
*! Quantile Regression Slope Homogeneity Test for Panel Data
*! Based on: Galvao, Juhl, Montes-Rojas & Olmo (2017)
*!   "Testing Slope Homogeneity in Quantile Regression Panel Data
*!    with an Application to the Cross-Section of Stock Returns"
*!   Journal of Financial Econometrics, 2017, 1–33

capture program drop xtqsh
program define xtqsh, eclass sortpreserve
	version 15.1
	
	if replay() {
		if "`e(cmd)'" != "xtqsh" error 301
		Display `0'
	}
	else Estimate `0'
end


* =====================================================================
* MAIN ESTIMATION PROGRAM
* =====================================================================

capture program drop Estimate
program define Estimate, eclass sortpreserve

	* ================================================================
	* SYNTAX
	* ================================================================
	
	syntax varlist(min=2 ts fv) [if] [in], TAU(numlist >0 <1 sort) ///
		[BW(string) HAC(integer 0) MARGinal ///
		 LEVel(integer `c(level)') ///
		 GRaph NOTAble]
	
	* Parse variables
	tokenize `varlist'
	local depvar "`1'"
	mac shift
	local indepvars "`*'"
	local k : word count `indepvars'
	local ntau : word count `tau'
	
	if `k' < 1 {
		di as err "at least one independent variable required"
		exit 198
	}
	
	if `ntau' < 1 {
		di as err "at least one quantile required in tau()"
		exit 198
	}
	
	* Default bandwidth
	if "`bw'" == "" local bw "hallsheather"
	if !inlist("`bw'", "bofinger", "hallsheather") {
		di as err "bw() must be {bf:bofinger} or {bf:hallsheather}"
		exit 198
	}
	
	* ================================================================
	* PANEL SETUP
	* ================================================================
	
	_xt
	local ivar "`r(ivar)'"
	local tvar "`r(tvar)'"
	
	marksample touse
	markout `touse' `ivar' `tvar'
	
	qui count if `touse'
	local nobs = r(N)
	if `nobs' == 0 error 2000
	
	* Count panels
	tempvar grp
	qui egen `grp' = group(`ivar') if `touse'
	qui summ `grp' if `touse', meanonly
	local npanels = r(max)
	
	* ================================================================
	* HEADER
	* ================================================================
	
	di
	di in smcl in gr "{hline 78}"
	di in smcl in gr "  {bf:Quantile Regression Slope Homogeneity Test}"
	di in smcl in gr "{hline 78}"
	di in gr "  H₀: β₁(τ) = β₂(τ) = ··· = βₙ(τ)" ///
		in gr "       (slope homogeneity)"
	di in gr "  H₁: βᵢ(τ) ≠ βⱼ(τ) for some i ≠ j" ///
		in gr "   (heterogeneity)"
	di in smcl in gr "{hline 78}"
	di in gr "  Dep. variable  : " in ye "`depvar'"
	di in gr "  Covariates     : " in ye "`indepvars'"
	di in gr "  Observations   : " in ye "`nobs'"
	di in smcl in gr "{hline 78}"
	di
	
	* ================================================================
	* CALL ESTIMATION ENGINE
	* ================================================================
	
	local marg_opt ""
	if "`marginal'" != "" local marg_opt "marginal"
	
	_xtqsh_estimate, dep(`depvar') indep(`indepvars') ///
		ivar(`ivar') tvar(`tvar') touse(`touse') ///
		tau(`tau') bw(`bw') hac(`hac') level(`level') ///
		`marg_opt'
	
	local valid_panels = r(valid_panels)
	local ng = r(n)
	local kk = r(k)
	
	* Retrieve results
	tempname S_mat D_mat pS_mat pD_mat beta_md beta_md_se beta_all
	tempname beta_ols_all
	matrix `S_mat' = r(S)
	matrix `D_mat' = r(D)
	matrix `pS_mat' = r(pval_S)
	matrix `pD_mat' = r(pval_D)
	matrix `beta_md' = r(beta_md)
	matrix `beta_md_se' = r(beta_md_se)
	matrix `beta_all' = r(beta_all)
	matrix `beta_ols_all' = r(beta_ols_all)
	
	local S_ols = r(S_ols)
	local D_ols = r(D_ols)
	local pS_ols = r(pval_S_ols)
	local pD_ols = r(pval_D_ols)
	
	if "`marginal'" != "" {
		tempname S_marg D_marg pS_marg pD_marg
		matrix `S_marg' = r(S_marginal)
		matrix `D_marg' = r(D_marginal)
		matrix `pS_marg' = r(pval_S_marginal)
		matrix `pD_marg' = r(pval_D_marginal)
	}
	
	* ================================================================
	* DISPLAY RESULTS
	* ================================================================
	
	if "`notable'" == "" {
		di
		di in smcl in gr "{hline 78}"
		di in smcl in gr ///
			"  {bf:JOINT SLOPE HOMOGENEITY TEST}" ///
			in gr "  (H₀: all slopes equal across panels)"
		di in smcl in gr "{hline 78}"
		di in gr ///
			"  {ralign 8:Quantile}" ///
			"  {ralign 14:Ŝ statistic}" ///
			"  {ralign 10:p(Ŝ)}" ///
			"  {ralign 14:D̂ statistic}" ///
			"  {ralign 10:p(D̂)}" ///
			"  {ralign 6:}"
		di in smcl in gr "{hline 78}"
		
		* OLS/Mean row
		di in ye "  {ralign 8:  Mean  }" _c
		di in ye "  {ralign 14:" %12.2f `S_ols' "}" _c
		_xtqsh_disp_pval `pS_ols'
		di in ye "  {ralign 14:" %12.3f `D_ols' "}" _c
		_xtqsh_disp_pval `pD_ols'
		_xtqsh_disp_stars `pD_ols'
		
		di in smcl in gr "  {hline 76}"
		
		* QR rows
		local ti = 0
		foreach tauval of local tau {
			local ++ti
			
			local S_val = `S_mat'[1, `ti']
			local D_val = `D_mat'[1, `ti']
			local pS_val = `pS_mat'[1, `ti']
			local pD_val = `pD_mat'[1, `ti']
			
			di in ye "  {ralign 8:τ = " %4.2f `tauval' "}" _c
			
			if `S_val' == . {
				di in gr "  {ralign 14:  ---}" ///
					"  {ralign 10:  ---}" ///
					"  {ralign 14:  ---}" ///
					"  {ralign 10:  ---}"
				continue
			}
			
			di in ye "  {ralign 14:" %12.2f `S_val' "}" _c
			_xtqsh_disp_pval `pS_val'
			di in ye "  {ralign 14:" %12.3f `D_val' "}" _c
			_xtqsh_disp_pval `pD_val'
			_xtqsh_disp_stars `pD_val'
		}
		
		di in smcl in gr "{hline 78}"
		di in gr "  *** p<0.01, ** p<0.05, * p<0.10"
		di in gr "  Ŝ ~ χ²(" in ye "`=`kk'*(`valid_panels'-1)'" in gr ///
			") under H₀ (T→∞, n fixed)"
		di in gr "  D̂ ~ N(0,1) under H₀ (T,n→∞)"
		di in gr "  Bandwidth: " in ye "`bw'" ///
			in gr "  |  Panels: n = " in ye "`ng'" ///
			in gr "  |  k = " in ye "`kk'"
		
		* ============================================================
		* MARGINAL TESTS TABLE
		* ============================================================
		
		if "`marginal'" != "" {
			di
			di in smcl in gr "{hline 78}"
			di in smcl in gr ///
				"  {bf:MARGINAL SLOPE HOMOGENEITY TESTS}" ///
				in gr "  (per-variable, H₀: β_j same ∀ i)"
			di in smcl in gr "{hline 78}"
			
			forvalues j = 1/`kk' {
				local xvar : word `j' of `indepvars'
				di
				di in ye "  ── Variable: " in ye "{bf:`xvar'}" ///
					in gr " {hline 50}"
				di in gr ///
					"  {ralign 8:Quantile}" ///
					"  {ralign 14:Ŝ statistic}" ///
					"  {ralign 10:p(Ŝ)}" ///
					"  {ralign 14:D̂ statistic}" ///
					"  {ralign 10:p(D̂)}" ///
					"  {ralign 6:}"
				di in smcl in gr "  {hline 74}"
				
				local ti = 0
				foreach tauval of local tau {
					local ++ti
					
					local S_val = `S_marg'[`j', `ti']
					local D_val = `D_marg'[`j', `ti']
					local pS_val = `pS_marg'[`j', `ti']
					local pD_val = `pD_marg'[`j', `ti']
					
					di in ye "  {ralign 8:τ = " %4.2f `tauval' "}" _c
					
					if `S_val' == . {
						di in gr "  {ralign 14:  ---}" ///
							"  {ralign 10:  ---}" ///
							"  {ralign 14:  ---}" ///
							"  {ralign 10:  ---}"
						continue
					}
					
					di in ye "  {ralign 14:" %12.2f `S_val' "}" _c
					_xtqsh_disp_pval `pS_val'
					di in ye "  {ralign 14:" %12.3f `D_val' "}" _c
					_xtqsh_disp_pval `pD_val'
					_xtqsh_disp_stars `pD_val'
				}
			}
			
			di in smcl in gr "{hline 78}"
			di in gr "  *** p<0.01, ** p<0.05, * p<0.10"
			di in gr "  Marginal test: k=1, Ŝ ~ χ²(n−1), D̂ ~ N(0,1)"
		}
		
		* ============================================================
		* MD-QR COEFFICIENT TABLE
		* ============================================================
		
		di
		di in smcl in gr "{hline 78}"
		di in smcl in gr ///
			"  {bf:MINIMUM DISTANCE QR ESTIMATES}" ///
			in gr "  β̂_MD(τ) = (ΣV̂ᵢ⁻¹)⁻¹ΣV̂ᵢ⁻¹β̂ᵢ"
		di in smcl in gr "{hline 78}"
		di in gr ///
			"  {ralign 8:Quantile}" _c
		forvalues j = 1/`kk' {
			local xvar : word `j' of `indepvars'
			local xvar = abbrev("`xvar'", 12)
			di in gr "  {ralign 12:`xvar'}" _c
		}
		di
		di in smcl in gr "{hline 78}"
		
		local ti = 0
		foreach tauval of local tau {
			local ++ti
			
			di in ye "  {ralign 8:τ = " %4.2f `tauval' "}" _c
			forvalues j = 1/`kk' {
				local est = `beta_md'[`ti', `j']
				if `est' == . {
					di in gr "  {ralign 12:---}" _c
				}
				else {
					di in ye "  {ralign 12:" %10.4f `est' "}" _c
				}
			}
			di
			
			* SE row
			di in gr "  {ralign 8:        }" _c
			forvalues j = 1/`kk' {
				local se = `beta_md_se'[`ti', `j']
				if `se' == . {
					di in gr "  {ralign 12:     }" _c
				}
				else {
					di in gr "  {ralign 12:(" %8.4f `se' ")}" _c
				}
			}
			di
		}
		
		di in smcl in gr "{hline 78}"
		di in gr "  Standard errors in parentheses"
	}
	
	* ================================================================
	* ERETURN
	* ================================================================
	
	tempname b_post V_post
	* Post the MD estimates for the median (or first quantile) as b/V
	local mid_tau = ceil(`ntau'/2)
	matrix `b_post' = `beta_md'[`mid_tau', 1...]
	matrix colnames `b_post' = `indepvars'
	matrix `V_post' = I(`kk')
	matrix colnames `V_post' = `indepvars'
	matrix rownames `V_post' = `indepvars'
	
	ereturn post `b_post' `V_post', obs(`nobs') esample(`touse')
	
	ereturn matrix S = `S_mat'
	ereturn matrix D = `D_mat'
	ereturn matrix pval_S = `pS_mat'
	ereturn matrix pval_D = `pD_mat'
	ereturn matrix beta_md = `beta_md'
	ereturn matrix beta_md_se = `beta_md_se'
	ereturn matrix beta_all = `beta_all'
	ereturn matrix beta_ols = `beta_ols_all'
	
	ereturn scalar S_ols = `S_ols'
	ereturn scalar D_ols = `D_ols'
	ereturn scalar pval_S_ols = `pS_ols'
	ereturn scalar pval_D_ols = `pD_ols'
	ereturn scalar N_g = `ng'
	ereturn scalar k = `kk'
	ereturn scalar ntau = `ntau'
	ereturn scalar valid_panels = `valid_panels'
	
	ereturn local tau "`tau'"
	ereturn local depvar "`depvar'"
	ereturn local indepvars "`indepvars'"
	ereturn local ivar "`ivar'"
	ereturn local tvar "`tvar'"
	ereturn local bw "`bw'"
	ereturn local cmdline "xtqsh `0'"
	ereturn local cmd "xtqsh"
	ereturn local title "QR Slope Homogeneity Test (Galvao et al. 2017)"
	
	if "`marginal'" != "" {
		ereturn matrix S_marginal = `S_marg'
		ereturn matrix D_marginal = `D_marg'
		ereturn matrix pval_S_marginal = `pS_marg'
		ereturn matrix pval_D_marginal = `pD_marg'
	}
	
	* ================================================================
	* GRAPHS
	* ================================================================
	
	if "`graph'" != "" {
		xtqsh_graph, tau(`tau') k(`kk') ///
			depvar(`depvar') indepvars(`indepvars') ///
			npanels(`ng') `marginal'
	}
	
	
end


* =====================================================================
* DISPLAY HELPERS
* =====================================================================

capture program drop _xtqsh_disp_pval
program define _xtqsh_disp_pval
	args pval
	if `pval' == . {
		di in gr "  {ralign 10:  ---}" _c
	}
	else if `pval' < 0.01 {
		di as err "  {ralign 10:" %8.4f `pval' "}" _c
	}
	else if `pval' < 0.05 {
		di as res "  {ralign 10:" %8.4f `pval' "}" _c
	}
	else {
		di in gr "  {ralign 10:" %8.4f `pval' "}" _c
	}
end

capture program drop _xtqsh_disp_stars
program define _xtqsh_disp_stars
	args pval
	if `pval' == . {
		di ""
	}
	else if `pval' < 0.01 {
		di in ye " ***"
	}
	else if `pval' < 0.05 {
		di in ye " **"
	}
	else if `pval' < 0.10 {
		di in ye " *"
	}
	else {
		di ""
	}
end


* =====================================================================
* REPLAY DISPLAY
* =====================================================================

capture program drop Display
program define Display
	syntax [, LEVel(integer `c(level)')]
	
	di
	di in smcl in gr "{hline 78}"
	di in smcl in gr "  {bf:Quantile Regression Slope Homogeneity Test}"
	di in smcl in gr "{hline 78}"
	
	* Re-display the test results from stored matrices
	local ntau = e(ntau)
	local kk = e(k)
	local ng = e(N_g)
	local tau "`e(tau)'"
	local indepvars "`e(indepvars)'"
	
	tempname S_mat D_mat pS_mat pD_mat
	matrix `S_mat' = e(S)
	matrix `D_mat' = e(D)
	matrix `pS_mat' = e(pval_S)
	matrix `pD_mat' = e(pval_D)
	
	di in gr ///
		"  {ralign 8:Quantile}" ///
		"  {ralign 14:Ŝ statistic}" ///
		"  {ralign 10:p(Ŝ)}" ///
		"  {ralign 14:D̂ statistic}" ///
		"  {ralign 10:p(D̂)}" ///
		"  {ralign 6:}"
	di in smcl in gr "{hline 78}"
	
	* Mean
	di in ye "  {ralign 8:  Mean  }" _c
	di in ye "  {ralign 14:" %12.2f e(S_ols) "}" _c
	_xtqsh_disp_pval `=e(pval_S_ols)'
	di in ye "  {ralign 14:" %12.3f e(D_ols) "}" _c
	_xtqsh_disp_pval `=e(pval_D_ols)'
	_xtqsh_disp_stars `=e(pval_D_ols)'
	
	di in smcl in gr "  {hline 76}"
	
	local ti = 0
	foreach tauval of local tau {
		local ++ti
		
		local S_val = `S_mat'[1, `ti']
		local D_val = `D_mat'[1, `ti']
		local pS_val = `pS_mat'[1, `ti']
		local pD_val = `pD_mat'[1, `ti']
		
		di in ye "  {ralign 8:τ = " %4.2f `tauval' "}" _c
		
		if `S_val' == . {
			di in gr "  {ralign 14:  ---}" ///
				"  {ralign 10:  ---}" ///
				"  {ralign 14:  ---}" ///
				"  {ralign 10:  ---}"
			continue
		}
		
		di in ye "  {ralign 14:" %12.2f `S_val' "}" _c
		_xtqsh_disp_pval `pS_val'
		di in ye "  {ralign 14:" %12.3f `D_val' "}" _c
		_xtqsh_disp_pval `pD_val'
		_xtqsh_disp_stars `pD_val'
	}
	
	di in smcl in gr "{hline 78}"
	di in gr "  *** p<0.01, ** p<0.05, * p<0.10"
	di in gr "  Panels: n = " in ye "`ng'" ///
		in gr "  |  k = " in ye "`kk'" ///
		in gr "  |  Bandwidth: " in ye "`e(bw)'"
	
end


exit
