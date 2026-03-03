*! xtpcmg v1.0.0 - Panel Cointegrating Polynomial Regressions
*! Based on Wagner & Reichold (2023, Econometric Reviews) and
*! de Jong & Wagner (2022, Annals of Applied Statistics)
*! Author: Dr. Merwan Roudane
*! Date: March 2026
*! v1.0.0: Multi-regressor support with poly() option
capture program drop xtpcmg
program define xtpcmg, eclass sortpreserve
	version 14.0
	syntax varlist(min=2 numeric ts) [if] [in], ///
		Model(string)  ///
		[Q(integer 2)  ///
		 POLy(varname) ///
		 TRend(integer 1) ///
		 Kernel(string) ///
		 BW(string) ///
		 Effects(string) ///
		 CORRrob ///
		 GRaph ///
		 Level(cilevel)]
	
	if !inlist("`model'", "mg", "pmg") {
		di as error "model() must be mg (group-mean) or pmg (pooled)"
		exit 198
	}
	if !inlist(`q', 2, 3) {
		di as error "q() must be 2 or 3"
		exit 198
	}
	
	if "`kernel'" == "" local kernel "ba"
	if "`bw'" == "" local bw "And91"
	if "`effects'" == "" local effects "oneway"
	
	marksample touse
	gettoken depvar regressors : varlist
	
	* --- Parse polynomial variable and controls ---
	local nregs : word count `regressors'
	if "`poly'" == "" {
		* Default: first (or only) regressor is the polynomial variable
		gettoken reg controls : regressors
	}
	else {
		* User specified poly() — validate it is in the varlist
		local reg "`poly'"
		local found = 0
		local controls ""
		foreach v of local regressors {
			if "`v'" == "`reg'" {
				local found = 1
			}
			else {
				local controls "`controls' `v'"
			}
		}
		if `found' == 0 {
			di as error "poly(`poly') must be one of the independent variables"
			exit 198
		}
		local controls = strtrim("`controls'")
	}
	local ncontrols : word count `controls'
	local has_controls = (`ncontrols' > 0)
	
	qui xtset
	local panelvar `r(panelvar)'
	local timevar `r(timevar)'
	
	tempvar tid
	qui egen `tid' = group(`panelvar') if `touse'
	qui sum `tid' if `touse', meanonly
	local N = r(max)
	qui sum `timevar' if `touse', meanonly
	local T = r(max) - r(min) + 1
	
	sort `panelvar' `timevar'
	
	* Header
	di as text ""
	di as text "{hline 78}"
	di as text "Panel Cointegrating Polynomial Regressions" _col(60) "xtpcmg v1.0.0"
	if "`model'" == "mg" {
		local moddesc "Group-Mean FM-OLS (Wagner & Reichold, 2023)"
	}
	else {
		local moddesc "Pooled FM-OLS (de Jong & Wagner, 2022)"
	}
	di as text "`moddesc'"
	di as text "{hline 78}"
	di as text "Dep. variable : " as result "`depvar'" ///
		_col(45) as text "N (panels) = " as result "`N'"
	di as text "Poly. var     : " as result "`reg'" ///
		_col(45) as text "T (time)   = " as result "`T'"
	di as text "Poly. degree  : " as result "`q'" ///
		_col(45) as text "Kernel     = " as result "`kernel'"
	di as text "Bandwidth     : " as result "`bw'"
	if `has_controls' {
		di as text "Controls      : " as result "`controls'"
	}
	di as text "{hline 78}"
	
	* Call Mata
	if "`model'" == "mg" {
		local corrrob_flag = ("`corrrob'" != "")
		mata: _xtpcmg_mg("`depvar'", "`reg'", "`controls'", "`touse'", `N', `T', `q', `trend', "`kernel'", "`bw'", `corrrob_flag')
	}
	else {
		mata: _xtpcmg_pmg("`depvar'", "`reg'", "`controls'", "`touse'", `N', `T', `q', "`kernel'", "`bw'", "`effects'")
	}
	
	* Post results
	tempname b V
	matrix `b' = __xtpcmg_b
	matrix `V' = __xtpcmg_V
	matrix drop __xtpcmg_b __xtpcmg_V
	local cnames "`bnames'"
	matrix colnames `b' = `cnames'
	matrix colnames `V' = `cnames'
	matrix rownames `V' = `cnames'
	
	* Store individual coefficients for MG model
	if "`model'" == "mg" {
		tempname indiv_b
		capture matrix `indiv_b' = __xtpcmg_indiv
		capture matrix drop __xtpcmg_indiv
	}
	
	ereturn post `b' `V', esample(`touse')
	ereturn local cmd "xtpcmg"
	ereturn local cmdline "xtpcmg `0'"
	ereturn local title "`moddesc'"
	ereturn local depvar "`depvar'"
	ereturn local model "`model'"
	ereturn local polyvar "`reg'"
	if `has_controls' {
		ereturn local controls "`controls'"
		ereturn scalar n_controls = `ncontrols'
	}
	ereturn scalar N_g = `N'
	ereturn scalar T = `T'
	ereturn scalar q = `q'
	if "`model'" == "mg" {
		capture ereturn matrix indiv_b = `indiv_b'
	}
	
	* Display table
	ereturn display, level(`level')
	
	* =====================================================================
	* ADVANCED ANALYSIS
	* =====================================================================
	tempname bcoef Vmat
	matrix `bcoef' = e(b)
	matrix `Vmat'  = e(V)
	
	* --- Individual Coefficient Summary (MG model) ---
	if "`model'" == "mg" {
		capture confirm matrix e(indiv_b)
		if _rc == 0 {
			tempname ib
			matrix `ib' = e(indiv_b)
			di as text ""
			di as text "{hline 78}"
			di as text " Individual FM-OLS Coefficient Estimates"
			di as text "{hline 78}"
			if `q' == 2 {
				di as text %12s "Panel" _col(20) %12s "`reg'" _col(38) %12s "`reg'^2"
				di as text "{hline 50}"
				forvalues i = 1/`N' {
					di as text %12s "Panel `i'" _col(20) as result %12.4f `ib'[`i',1] _col(38) as result %12.4f `ib'[`i',2]
				}
			}
			else {
				di as text %12s "Panel" _col(20) %12s "`reg'" _col(38) %12s "`reg'^2" _col(56) %12s "`reg'^3"
				di as text "{hline 68}"
				forvalues i = 1/`N' {
					di as text %12s "Panel `i'" _col(20) as result %12.4f `ib'[`i',1] _col(38) as result %12.4f `ib'[`i',2] _col(56) as result %12.4f `ib'[`i',3]
				}
			}
			di as text "{hline 78}"
			
			* --- Enhanced Heterogeneity Analysis ---
			di as text ""
			di as text "{hline 78}"
			di as text " Coefficient Heterogeneity Analysis"
			di as text "{hline 78}"
			local totalcoefs = `q' + `ncontrols'
			
			* --- Descriptive Statistics Table ---
			di as text ""
			di as text %14s "Coeff." _col(16) %9s "Mean" _col(27) %9s "Median" ///
				_col(38) %9s "Std.Dev" _col(49) %9s "IQR" ///
				_col(59) %9s "Skewness" _col(70) %9s "Kurtosis"
			di as text "{hline 78}"
			forvalues j = 1/`totalcoefs' {
				tempname colvals
				matrix `colvals' = `ib'[1..`N', `j']
				mata: _xtpcmg_hetstat(st_matrix("`colvals'"))
				if `j' == 1 local vname "`reg'"
				else if `j' == 2 local vname "`reg'^2"
				else if `j' == 3 & `q' == 3 local vname "`reg'^3"
				else {
					local ck = `j' - `q'
					local vname : word `ck' of `controls'
				}
				di as text %14s "`vname'" _col(16) ///
					as result %9.4f scalar(__hmean) _col(27) ///
					as result %9.4f scalar(__hmed) _col(38) ///
					as result %9.4f scalar(__hsd) _col(49) ///
					as result %9.4f scalar(__hiqr) _col(59) ///
					as result %9.4f scalar(__hskew) _col(70) ///
					as result %9.4f scalar(__hkurt)
				scalar drop __hmean __hmed __hsd __hiqr __hskew __hkurt
			}
			di as text "{hline 78}"
			di as text %14s "Coeff." _col(16) %9s "Min" _col(27) %9s "P5" ///
				_col(38) %9s "P25" _col(49) %9s "P75" ///
				_col(59) %9s "P95" _col(70) %9s "Max"
			di as text "{hline 78}"
			forvalues j = 1/`totalcoefs' {
				tempname colvals
				matrix `colvals' = `ib'[1..`N', `j']
				mata: _xtpcmg_hetpctl(st_matrix("`colvals'"))
				if `j' == 1 local vname "`reg'"
				else if `j' == 2 local vname "`reg'^2"
				else if `j' == 3 & `q' == 3 local vname "`reg'^3"
				else {
					local ck = `j' - `q'
					local vname : word `ck' of `controls'
				}
				di as text %14s "`vname'" _col(16) ///
					as result %9.4f scalar(__pmin) _col(27) ///
					as result %9.4f scalar(__p5) _col(38) ///
					as result %9.4f scalar(__p25) _col(49) ///
					as result %9.4f scalar(__p75) _col(59) ///
					as result %9.4f scalar(__p95) _col(70) ///
					as result %9.4f scalar(__pmax)
				scalar drop __pmin __p5 __p25 __p75 __p95 __pmax
			}
			di as text "{hline 78}"
			
			* --- Swamy (1970) Test for Slope Homogeneity ---
			di as text ""
			di as text "{hline 78}"
			di as text " Swamy (1970) Test for Slope Homogeneity"
			di as text "{hline 78}"
			di as text " H0: All individual slope coefficients are equal"
			di as text " H1: At least one panel has a different slope"
			di as text "{hline 78}"
			
			tempname Sstat Sdf Sp
			mata: _xtpcmg_swamy(st_matrix("`ib'"), `N', `totalcoefs')
			
			di as text %30s "Swamy S-statistic" _col(35) " = " as result %12.4f scalar(`Sstat')
			di as text %30s "Degrees of freedom" _col(35) " = " as result %12.0f scalar(`Sdf')
			di as text %30s "P-value (chi-squared)" _col(35) " = " as result %12.4f scalar(`Sp')
			if scalar(`Sp') < 0.05 {
				di as text ""
				di as result "  >>> Significant heterogeneity detected (p < 0.05)."
				di as result "      Group-Mean FM-OLS is preferred over Pooled FM-OLS."
			}
			else {
				di as text ""
				di as result "  >>> No significant heterogeneity (p >= 0.05)."
				di as result "      Pooled FM-OLS may be appropriate."
			}
			di as text "{hline 78}"
			
			ereturn scalar swamy_s = scalar(`Sstat')
			ereturn scalar swamy_df = scalar(`Sdf')
			ereturn scalar swamy_p = scalar(`Sp')
			
			* --- Between-Within Variance Decomposition ---
			di as text ""
			di as text "{hline 78}"
			di as text " Between-Within Variance Decomposition"
			di as text "{hline 78}"
			di as text " Total variance   = Between-panel variance + Within-panel estimation noise"
			di as text " Between ratio    = Systematic heterogeneity / Total variation"
			di as text "{hline 78}"
			di as text ""
			di as text %14s "Coeff." _col(16) %12s "Total Var." _col(30) %12s "Between" ///
				_col(44) %12s "Within" _col(58) %12s "Ratio(B/T)" _col(72) %8s "Signal"
			di as text "{hline 78}"
			forvalues j = 1/`totalcoefs' {
				tempname colvals
				matrix `colvals' = `ib'[1..`N', `j']
				
				* Between-panel variance: var(b_i) 
				mata: st_numscalar("__bvar", variance(vec(st_matrix("`colvals'"))))
				
				* Within-panel variance: average individual VCV diagonal
				* Use group-mean VCV * N as proxy for within variance
				tempname vcv_diag
				matrix `vcv_diag' = e(V)
				local wvar = `vcv_diag'[`j', `j'] * `N'
				
				local tvar = scalar(__bvar)
				local bvar_val = max(0, `tvar' - `wvar')
				local ratio = cond(`tvar' > 0, `bvar_val' / `tvar', 0)
				
				if `j' == 1 local vname "`reg'"
				else if `j' == 2 local vname "`reg'^2"
				else if `j' == 3 & `q' == 3 local vname "`reg'^3"
				else {
					local ck = `j' - `q'
					local vname : word `ck' of `controls'
				}
				
				local signal "Low"
				if `ratio' > 0.5 local signal "Medium"
				if `ratio' > 0.8 local signal "High"
				
				di as text %14s "`vname'" _col(16) ///
					as result %12.4f `tvar' _col(30) ///
					as result %12.4f `bvar_val' _col(44) ///
					as result %12.4f `wvar' _col(58) ///
					as result %12.4f `ratio' _col(72) ///
					as result %8s "`signal'"
				scalar drop __bvar
			}
			di as text "{hline 78}"
			di as text " Note: Ratio > 0.8 = High systematic heterogeneity"
			di as text "       Ratio < 0.5 = Mostly estimation noise"
			di as text "{hline 78}"
		}
	}
	
	* --- Turning Point with Delta-Method CI ---
	if `q' == 2 {
		local b1 = `bcoef'[1,1]
		local b2 = `bcoef'[1,2]
		if `b2' != 0 {
			local tp = -`b1' / (2*`b2')
			local tp_y = `b2' * `tp'^2 + `b1' * `tp'
			local g1 = -1/(2*`b2')
			local g2 = `b1'/(2*`b2'^2)
			local v11 = `Vmat'[1,1]
			local v12 = `Vmat'[1,2]
			local v22 = `Vmat'[2,2]
			local tp_var = `g1'^2*`v11' + 2*`g1'*`g2'*`v12' + `g2'^2*`v22'
			local tp_se = sqrt(abs(`tp_var'))
			local tp_lo = `tp' - invnormal(0.975)*`tp_se'
			local tp_hi = `tp' + invnormal(0.975)*`tp_se'
			local tp_z = `tp' / `tp_se'
			local tp_p = 2 * (1 - normal(abs(`tp_z')))
			if `b2' < 0 local tp_shape "Inverted U (concave)"
			else        local tp_shape "U-shaped (convex)"
			
			di as text ""
			di as text "{hline 78}"
			di as text " Turning Point Analysis" _col(55) "Shape: `tp_shape'"
			di as text "{hline 78}"
			di as text %20s "" _col(21) %10s "Estimate" _col(33) %10s "Std. Err." _col(45) %8s "z" _col(55) %8s "P>|z|" _col(65) %14s "[95% Conf. Int.]"
			di as text "{hline 78}"
			di as text %20s "Turning point (x*)" _col(21) as result %10.4f `tp' _col(33) as result %10.4f `tp_se' _col(45) as result %8.2f `tp_z' _col(55) as result %8.3f `tp_p' _col(65) as result %8.4f `tp_lo' as text "  " as result %8.4f `tp_hi'
			di as text %20s "f(x*)" _col(21) as result %10.4f `tp_y'
			di as text "{hline 78}"
			di as text " Coefficients: b1 = " as result %8.4f `b1' as text ", b2 = " as result %8.4f `b2'
			di as text " Formula: x* = -b1/(2*b2)"
			di as text "{hline 78}"
			
			ereturn scalar tp = `tp'
			ereturn scalar tp_se = `tp_se'
			ereturn scalar tp_lo = `tp_lo'
			ereturn scalar tp_hi = `tp_hi'
			ereturn scalar tp_z = `tp_z'
			ereturn scalar tp_p = `tp_p'
			local has_tp = 1
		}
	}
	else if `q' == 3 {
		local b1 = `bcoef'[1,1]
		local b2 = `bcoef'[1,2]
		local b3 = `bcoef'[1,3]
		if `b3' != 0 & (`b2'^2 - 3*`b1'*`b3') >= 0 {
			local disc = sqrt(`b2'^2 - 3*`b1'*`b3')
			local tp1 = (-`b2' + `disc') / (3*`b3')
			local tp2 = (-`b2' - `disc') / (3*`b3')
			local tp1_y = `b1'*`tp1' + `b2'*`tp1'^2 + `b3'*`tp1'^3
			local tp2_y = `b1'*`tp2' + `b2'*`tp2'^2 + `b3'*`tp2'^3
			
			di as text ""
			di as text "{hline 78}"
			di as text " Turning Point Analysis (cubic)"
			di as text "{hline 78}"
			di as text %20s "" _col(21) %12s "x*" _col(40) %12s "f(x*)"
			di as text "{hline 54}"
			di as text %20s "Turning point 1" _col(21) as result %12.4f `tp1' _col(40) as result %12.4f `tp1_y'
			di as text %20s "Turning point 2" _col(21) as result %12.4f `tp2' _col(40) as result %12.4f `tp2_y'
			di as text "{hline 54}"
			ereturn scalar tp1 = `tp1'
			ereturn scalar tp2 = `tp2'
			local has_tp = 1
		}
	}
	if "`has_tp'" == "" local has_tp = 0
	
	* =====================================================================
	* VISUALIZATIONS
	* =====================================================================
	if "`graph'" != "" {
		qui {
			preserve
			keep if e(sample)
			
			tempname bmat
			matrix `bmat' = e(b)
			local gb1 = `bmat'[1,1]
			local gb2 = `bmat'[1,2]
			if `q' == 3 {
				local gb3 = `bmat'[1,3]
			}
			
			* --- Graph 1: Polynomial Fit with Confidence Band ---
			tempvar yhat xgrid yfitlo yfithi
			if `q' == 2 {
				gen double `yhat' = `gb1' * `reg' + `gb2' * (`reg'^2)
			}
			else {
				gen double `yhat' = `gb1' * `reg' + `gb2' * (`reg'^2) + `gb3' * (`reg'^3)
			}
			label var `yhat' "Fitted polynomial"
			
			twoway (scatter `depvar' `reg', mcolor(navy%20) msymbol(o) msize(vsmall)) ///
				   (line `yhat' `reg', sort lcolor(cranberry) lwidth(medthick)), ///
				   title("Panel Cointegrating Polynomial Fit", size(medlarge)) ///
				   subtitle("`moddesc'", size(small) color(gs6)) ///
				   legend(order(1 "Observed data" 2 "Fitted polynomial") ///
					   rows(1) position(6) size(small)) ///
				   ytitle("`depvar'", size(small)) xtitle("`reg'", size(small)) ///
				   graphregion(color(white)) plotregion(margin(small)) ///
				   name(xtpcmg_fit, replace)
			
			* --- Graph 2: Panel-by-Panel Fitted Curves ---
			tempvar panfit
			if `q' == 2 {
				gen double `panfit' = `gb1' * `reg' + `gb2' * (`reg'^2)
			}
			else {
				gen double `panfit' = `gb1' * `reg' + `gb2' * (`reg'^2) + `gb3' * (`reg'^3)
			}
			label var `panfit' "Fitted polynomial"
			
			twoway (scatter `depvar' `reg', mcolor(navy%30) msymbol(o) msize(vsmall)) ///
				   (line `panfit' `reg', sort lcolor(cranberry) lwidth(medthick)), ///
				   by(`panelvar', title("Panel-Specific Scatter + Polynomial Fit", size(medlarge)) ///
					   note("Fitted: `moddesc'", size(vsmall)) compact ///
					   legend(order(1 "`depvar'" 2 "Fitted poly.") rows(1) position(6) size(small))) ///
				   ytitle("`depvar'", size(small)) xtitle("`reg'", size(small)) ///
				   graphregion(color(white)) ///
				   name(xtpcmg_panels, replace)
			
			* --- Graph 3: Coefficient Distribution (MG model only) ---
			if "`model'" == "mg" {
				capture confirm matrix e(indiv_b)
				if _rc == 0 {
					tempname ib2
					matrix `ib2' = e(indiv_b)
					local nib = rowsof(`ib2')
					
					* Add beta columns to current data (no nested preserve)
					gen double _beta1 = .
					gen double _beta2 = .
					if `q' == 3 {
						gen double _beta3 = .
					}
					forvalues i = 1/`nib' {
						qui replace _beta1 = `ib2'[`i',1] in `i'
						qui replace _beta2 = `ib2'[`i',2] in `i'
						if `q' == 3 {
							qui replace _beta3 = `ib2'[`i',3] in `i'
						}
					}
					
					if `q' == 2 {
						twoway (kdensity _beta1, lcolor(navy) lwidth(medthick)) ///
							   (kdensity _beta2, lcolor(cranberry) lwidth(medthick) lpattern(dash)), ///
							   title("Individual FM-OLS Coefficient Distributions", size(medlarge)) ///
							   subtitle("Kernel density of panel-specific estimates", size(small) color(gs6)) ///
							   xline(`gb1', lcolor(navy) lpattern(shortdash)) ///
							   xline(`gb2', lcolor(cranberry) lpattern(shortdash)) ///
							   legend(order(1 "`reg'" 2 "`reg'^2") rows(1) position(6) size(small)) ///
							   xtitle("Coefficient value", size(small)) ytitle("Density", size(small)) ///
							   note("Dashed vertical lines = group-mean estimates", size(vsmall)) ///
							   graphregion(color(white)) ///
							   name(xtpcmg_coef, replace)
					}
					else {
						twoway (kdensity _beta1, lcolor(navy) lwidth(medthick)) ///
							   (kdensity _beta2, lcolor(cranberry) lwidth(medthick) lpattern(dash)) ///
							   (kdensity _beta3, lcolor(dkgreen) lwidth(medthick) lpattern(longdash)), ///
							   title("Individual FM-OLS Coefficient Distributions", size(medlarge)) ///
							   subtitle("Kernel density of panel-specific estimates", size(small) color(gs6)) ///
							   legend(order(1 "`reg'" 2 "`reg'^2" 3 "`reg'^3") rows(1) position(6) size(small)) ///
							   xtitle("Coefficient value", size(small)) ytitle("Density", size(small)) ///
							   graphregion(color(white)) ///
							   name(xtpcmg_coef, replace)
					}
					drop _beta1 _beta2
					capture drop _beta3
				}
			}
			
			* --- Graph 4: Residual Diagnostics ---
			tempvar resid
			if `q' == 2 {
				gen double `resid' = `depvar' - `gb1' * `reg' - `gb2' * (`reg'^2)
			}
			else {
				gen double `resid' = `depvar' - `gb1' * `reg' - `gb2' * (`reg'^2) - `gb3' * (`reg'^3)
			}
			* Subtract control contributions from residual
			if `has_controls' {
				local cstart = `q' + 1
				local ck = 1
				foreach cv of local controls {
					local cidx = `q' + `ck'
					local gc = `bmat'[1, `cidx']
					qui replace `resid' = `resid' - `gc' * `cv'
					local ck = `ck' + 1
				}
			}
			
			twoway (histogram `resid', fcolor(navy%40) lcolor(navy%60) bin(20)) ///
				   (kdensity `resid', lcolor(cranberry) lwidth(medthick)), ///
				   title("Residual Distribution", size(medlarge)) ///
				   subtitle("Histogram with kernel density overlay", size(small) color(gs6)) ///
				   xtitle("Residuals", size(small)) ytitle("Density", size(small)) ///
				   legend(order(1 "Histogram" 2 "Kernel density") rows(1) position(6) size(small)) ///
				   graphregion(color(white)) ///
				   name(xtpcmg_resid, replace)
			
			* --- Graph 5: Turning Point Graph ---
			if `has_tp' == 1 {
				qui sum `reg', detail
				local xmin = r(min)
				local xmax = r(max)
				local xrange = `xmax' - `xmin'
				
				* Generate fitted curve on a grid
				tempvar xgr ygr
				local ngrid = _N
				gen double `xgr' = `xmin' + (_n-1) * `xrange'/(`ngrid'-1) in 1/`ngrid'
				if `q' == 2 {
					gen double `ygr' = `gb1' * `xgr' + `gb2' * (`xgr'^2) in 1/`ngrid'
				}
				else {
					gen double `ygr' = `gb1' * `xgr' + `gb2' * (`xgr'^2) + `gb3' * (`xgr'^3) in 1/`ngrid'
				}
				
				if `q' == 2 {
					local tp_yval = `gb1' * `tp' + `gb2' * `tp'^2
					local tp_lo_y = `gb1' * `tp_lo' + `gb2' * `tp_lo'^2
					local tp_hi_y = `gb1' * `tp_hi' + `gb2' * `tp_hi'^2
					
					twoway (line `ygr' `xgr', sort lcolor(navy) lwidth(medthick)) ///
						   (scatter `depvar' `reg', mcolor(gs10%30) msymbol(o) msize(vsmall)) ///
						   (pci `tp_yval' `tp' `=`tp_yval' - 2' `tp', lcolor(cranberry) lwidth(thick) lpattern(solid)) ///
						   (scatteri `tp_yval' `tp', msymbol(D) mcolor(cranberry) msize(large)), ///
						   xline(`tp', lcolor(cranberry) lpattern(dash) lwidth(medthin)) ///
						   xline(`tp_lo', lcolor(cranberry%40) lpattern(shortdash) lwidth(thin)) ///
						   xline(`tp_hi', lcolor(cranberry%40) lpattern(shortdash) lwidth(thin)) ///
						   title("Turning Point Estimate", size(medlarge)) ///
						   subtitle("x* = `: di %6.3f `tp'' [`: di %6.3f `tp_lo'', `: di %6.3f `tp_hi'']", size(small) color(gs6)) ///
						   legend(order(1 "Fitted polynomial" 2 "Data" 4 "Turning point") ///
							   rows(1) position(6) size(small)) ///
						   ytitle("`depvar'", size(small)) xtitle("`reg'", size(small)) ///
						   graphregion(color(white)) ///
						   note("Dashed lines: 95% CI for turning point", size(vsmall)) ///
						   name(xtpcmg_tp, replace)
				}
				else {
					* Cubic: mark both turning points
					twoway (line `ygr' `xgr', sort lcolor(navy) lwidth(medthick)) ///
						   (scatter `depvar' `reg', mcolor(gs10%30) msymbol(o) msize(vsmall)), ///
						   xline(`tp1', lcolor(cranberry) lpattern(dash) lwidth(medthin)) ///
						   xline(`tp2', lcolor(dkgreen) lpattern(dash) lwidth(medthin)) ///
						   title("Turning Points (cubic)", size(medlarge)) ///
						   subtitle("x1* = `: di %6.3f `tp1'', x2* = `: di %6.3f `tp2''", size(small) color(gs6)) ///
						   legend(order(1 "Fitted polynomial" 2 "Data") ///
							   rows(1) position(6) size(small)) ///
						   ytitle("`depvar'", size(small)) xtitle("`reg'", size(small)) ///
						   graphregion(color(white)) ///
						   note("Dashed lines mark turning points", size(vsmall)) ///
						   name(xtpcmg_tp, replace)
				}
			}
			* --- Graph 6: Caterpillar/Forest Plot (MG model only) ---
			if "`model'" == "mg" {
				capture confirm matrix e(indiv_b)
				if _rc == 0 {
					tempname ib3
					matrix `ib3' = e(indiv_b)
					local nib3 = rowsof(`ib3')
					
					* Create caterpillar plot for each polynomial coefficient
					forvalues jc = 1/`q' {
						if `jc' == 1 local clab "`reg'"
						else if `jc' == 2 local clab "`reg'^2"
						else local clab "`reg'^3"
						
						local gmval = `bmat'[1, `jc']
						
						* Put panel coefficients into data
						gen double _cat_coef`jc' = .
						gen double _cat_rank`jc' = .
						
						* Sort coefficients via Mata helper
						mata: _xtpcmg_sort_coef(st_matrix("`ib3'"), `jc', `nib3', "_cat_coef`jc'", "_cat_rank`jc'")
						
						twoway (bar _cat_coef`jc' _cat_rank`jc' in 1/`nib3', ///
								barwidth(0.7) fcolor(navy%60) lcolor(navy%80) lwidth(vthin)) ///
							   , ///
							   yline(`gmval', lcolor(cranberry) lwidth(medthick) lpattern(dash)) ///
							   yline(0, lcolor(gs8) lwidth(thin)) ///
							   title("Sorted Panel Coefficients: `clab'", size(medium)) ///
							   subtitle("Group-Mean = `: di %6.3f `gmval''", size(small) color(cranberry)) ///
							   ytitle("Coefficient", size(small)) ///
							   xtitle("Panel (sorted)", size(small)) ///
							   xlabel(none) ///
							   note("Dashed line = group-mean estimate", size(vsmall)) ///
							   graphregion(color(white)) ///
							   name(xtpcmg_cat`jc', replace)
						
						drop _cat_coef`jc' _cat_rank`jc'
					}
					
					* Combine caterpillar plots
					if `q' == 2 {
						graph combine xtpcmg_cat1 xtpcmg_cat2, ///
							title("Coefficient Heterogeneity: Caterpillar Plot", size(medlarge)) ///
							subtitle("Individual FM-OLS estimates sorted by magnitude", size(small) color(gs6)) ///
							graphregion(color(white)) cols(2) ///
							xsize(12) ysize(5) ///
							name(xtpcmg_caterpillar, replace)
					}
					else {
						graph combine xtpcmg_cat1 xtpcmg_cat2 xtpcmg_cat3, ///
							title("Coefficient Heterogeneity: Caterpillar Plot", size(medlarge)) ///
							subtitle("Individual FM-OLS estimates sorted by magnitude", size(small) color(gs6)) ///
							graphregion(color(white)) cols(3) ///
							xsize(14) ysize(5) ///
							name(xtpcmg_caterpillar, replace)
					}
				}
			}
			
			* --- Graph 7: Box Plot of Individual Coefficients (MG model) ---
			if "`model'" == "mg" {
				capture confirm matrix e(indiv_b)
				if _rc == 0 {
					tempname ib4
					matrix `ib4' = e(indiv_b)
					local nib4 = rowsof(`ib4')
					local ncols4 = colsof(`ib4')
					
					* Stack all coefficients into long format
					gen double _box_val = .
					gen _box_coef = ""
					local obs_ct = 0
					forvalues jb = 1/`ncols4' {
						if `jb' == 1 local blab "`reg'"
						else if `jb' == 2 local blab "`reg'^2"
						else if `jb' == 3 & `q' == 3 local blab "`reg'^3"
						else {
							local ck2 = `jb' - `q'
							local blab : word `ck2' of `controls'
						}
						forvalues ib5 = 1/`nib4' {
							local obs_ct = `obs_ct' + 1
							if `obs_ct' <= _N {
								qui replace _box_val = `ib4'[`ib5', `jb'] in `obs_ct'
								qui replace _box_coef = "`blab'" in `obs_ct'
							}
						}
					}
					
					graph box _box_val in 1/`obs_ct', over(_box_coef) ///
						box(1, fcolor(navy%50) lcolor(navy)) ///
						medtype(cline) medline(lcolor(cranberry) lwidth(thick)) ///
						marker(1, msymbol(o) mcolor(cranberry%60) msize(small)) ///
						title("Coefficient Distribution: Box Plot", size(medlarge)) ///
						subtitle("Individual FM-OLS estimates across panels", size(small) color(gs6)) ///
						ytitle("Coefficient value", size(small)) ///
						yline(0, lcolor(gs10) lpattern(dash) lwidth(thin)) ///
						note("Median (red line), box = IQR, whiskers = 1.5*IQR, dots = outliers", size(vsmall)) ///
						graphregion(color(white)) ///
						name(xtpcmg_boxplot, replace)
					
					drop _box_val _box_coef
				}
			}
			
			* Combine all graphs
			local glist "xtpcmg_fit xtpcmg_panels"
			if "`model'" == "mg" {
				local glist "`glist' xtpcmg_coef xtpcmg_caterpillar xtpcmg_boxplot"
			}
			local glist "`glist' xtpcmg_resid"
			if `has_tp' == 1 {
				local glist "`glist' xtpcmg_tp"
			}
			
			graph combine `glist', ///
				title("xtpcmg Diagnostic Suite", size(medlarge)) ///
				subtitle("`moddesc'", size(small) color(gs6)) ///
				graphregion(color(white)) cols(2) ///
				xsize(14) ysize(10) iscale(0.45) ///
				name(xtpcmg_combined, replace)
			
			restore
		}
	}
end

* =========================================================================
* MATA BLOCK
* =========================================================================
version 14.0
mata:
mata set matastrict off

// -----------------------------------------------------------------------
// lr_weights  (matches lr_weights.m exactly)
// -----------------------------------------------------------------------
void _lr_weights(real scalar T, string scalar kern, real scalar band,
                 real colvector w, real scalar upper)
{
	real scalar M, j, jj, sc, ulim

	w = J(T-1, 1, 0)
	M = band
	upper = 0

	if (kern == "tr") {
		upper = min((floor(M), T-1))
		for (j=1; j<=upper; j++) w[j] = 1
	}
	else if (kern == "ba") {
		upper = min((ceil(M)-1, T-1))
		for (j=1; j<=upper; j++) w[j] = 1 - j/M
	}
	else if (kern == "pa") {
		upper = min((ceil(M)-1, T-1))
		ulim  = min((floor(M/2), T-1))
		for (j=1; j<=ulim; j++) {
			jj = j/M
			w[j] = 1 - 6*jj^2 + 6*jj^3
		}
		ulim = min((floor(M), T-1))
		for (j=floor(M/2)+1; j<=ulim; j++) {
			jj = j/M
			w[j] = 2*(1-jj)^3
		}
	}
	else if (kern == "bo") {
		upper = min((ceil(M)-1, T-1))
		for (j=1; j<=upper; j++) {
			jj = j/M
			w[j] = (1-jj)*cos(pi()*jj) + sin(pi()*jj)/pi()
		}
	}
	else if (kern == "da") {
		upper = T-1
		for (j=1; j<=T-1; j++) w[j] = sin(pi()*j/M)/(pi()*j/M)
	}
	else if (kern == "qs") {
		upper = T-1
		sc = (6*pi())/5
		for (j=1; j<=T-1; j++) {
			jj = j/M
			w[j] = 25/(12*(pi()^2)*(jj^2))*(sin(sc*jj)/(sc*jj)-cos(sc*jj))
		}
	}
	else {
		upper = min((ceil(M)-1, T-1))
		for (j=1; j<=upper; j++) w[j] = 1 - j/M
	}
}

// -----------------------------------------------------------------------
// lr_varmod  (matches lr_varmod.m exactly)
// -----------------------------------------------------------------------
void _lr_varmod(real matrix u, string scalar kern, real scalar band,
                real scalar deme,
                real matrix Omega, real matrix Delta, real matrix Sigma)
{
	real scalar TT, m, j, j_max, ii, jj2, idx
	real colvector w
	real matrix T1, T2, T_Omega, T_Delta, R, Delta1, ws_vec

	TT = rows(u)
	m  = cols(u)

	if (deme == 1) {
		u = u :- J(TT,1,1) * mean(u)
	}

	_lr_weights(TT, kern, band, w, j_max)

	Omega = J(m, m, 0)
	Delta = J(m, m, 0)
	Sigma = (1/TT) * (u' * u)

	if (kern == "qs" | kern == "da") {
		ws_vec = (0 \ w)
		R = J(TT, TT, 0)
		for (ii=1; ii<=TT; ii++) {
			for (jj2=1; jj2<=TT; jj2++) {
				idx = abs(ii-jj2) + 1
				if (idx <= rows(ws_vec)) R[ii, jj2] = ws_vec[idx]
			}
		}
		R = R'
		R[TT, .] = J(1, TT, 0)
		Delta1 = R * u
		Delta = (1/TT) * (u' * Delta1)
		Omega = Delta + Delta'
	}
	else {
		for (j=1; j<=j_max; j++) {
			T1 = u[(j+1)..TT, .]' * u[1..(TT-j), .] / TT
			T2 = u[1..(TT-j), .]' * u[(j+1)..TT, .] / TT
			T_Omega = w[j] * (T1 + T2)
			T_Delta = w[j] * T1
			Omega = Omega + T_Omega
			Delta = Delta + T_Delta
		}
		Delta = Delta'
	}

	Omega = Omega + Sigma
	Delta = Delta + Sigma
}

// -----------------------------------------------------------------------
// And_HAC91  (matches And_HAC91.m exactly)
// -----------------------------------------------------------------------
real scalar _And_HAC91(real matrix v, string scalar kern)
{
	real scalar TT, dimv, k, denom, numer2, a2, numer1, a1, bwidth
	real colvector rhovec, sigma2vec, yy, xx

	TT   = rows(v)
	dimv = cols(v)
	rhovec    = J(dimv, 1, 0)
	sigma2vec = J(dimv, 1, 0)

	for (k=1; k<=dimv; k++) {
		yy = v[2..TT, k]
		xx = v[1..(TT-1), k]
		rhovec[k] = (xx'*xx > 0 ? (xx'*yy)/(xx'*xx) : 0)
		sigma2vec[k] = (1/TT) * (yy - xx*rhovec[k])' * (yy - xx*rhovec[k])
	}

	denom = 0
	for (k=1; k<=dimv; k++) {
		denom = denom + (sigma2vec[k]^2)/((1-rhovec[k])^4)
	}
	if (denom == 0) denom = 1e-10

	numer2 = 0
	for (k=1; k<=dimv; k++) {
		numer2 = numer2 + (4*rhovec[k]^2*sigma2vec[k]^2)/((1-rhovec[k])^8)
	}
	a2 = numer2/denom

	numer1 = 0
	for (k=1; k<=dimv; k++) {
		numer1 = numer1 + (4*rhovec[k]^2*sigma2vec[k]^2)/((1-rhovec[k])^6*(1+rhovec[k])^2)
	}
	a1 = numer1/denom

	if      (kern == "tr") bwidth = 0.6611*(a2*TT)^(1/5)
	else if (kern == "ba") bwidth = 1.1447*(a1*TT)^(1/3)
	else if (kern == "pa") bwidth = 2.6614*(a2*TT)^(1/5)
	else if (kern == "th") bwidth = 1.7462*(a2*TT)^(1/5)
	else if (kern == "qs") bwidth = 1.3221*(a2*TT)^(1/5)
	else                   bwidth = 1.1447*(a1*TT)^(1/3)

	bwidth = ceil(bwidth)
	return(bwidth)
}

// -----------------------------------------------------------------------
// demean_detrend  (matches demean_detrend.m exactly)
// -----------------------------------------------------------------------
void _demean_detrend(real matrix y, real matrix x, real scalar typee,
                     real matrix ytilde, real matrix xtilde,
                     real matrix x2tilde, real matrix x3tilde)
{
	real scalar TT
	real matrix D, P

	TT = rows(x)
	if (typee == 1) D = J(TT, 1, 1)
	else            D = (J(TT,1,1), (1::TT))

	P = I(TT) - D * invsym(D'*D) * D'

	ytilde  = P * y
	xtilde  = P * x
	x2tilde = P * (x:^2)
	x3tilde = P * (x:^3)
}

// -----------------------------------------------------------------------
// simpledemean  (matches simpledemean.m exactly)
// -----------------------------------------------------------------------
void _simpledemean(real matrix y, real matrix x, string scalar way,
                   real scalar q,
                   real matrix ytilde, real matrix xtilde,
                   real matrix x2tilde, real matrix x3tilde)
{
	real scalar TT, NN, xgm, x2gm, ygm, x3gm
	real matrix x2, x3
	real rowvector xm, x2m, ym, x3m
	real colvector xrm, x2rm, yrm, x3rm

	TT = rows(x)
	NN = cols(x)
	x2 = x:^2

	if (way == "oneway") {
		xm  = mean(x)
		x2m = mean(x2)
		ym  = mean(y)
		xtilde  = x  :- J(TT,1,1)*xm
		x2tilde = x2 :- J(TT,1,1)*x2m
		ytilde  = y  :- J(TT,1,1)*ym
		if (q == 3) {
			x3 = x:^3
			x3m = mean(x3)
			x3tilde = x3 :- J(TT,1,1)*x3m
		}
		else x3tilde = J(TT, NN, 0)
	}
	else {
		xm  = mean(x)
		x2m = mean(x2)
		ym  = mean(y)
		xrm  = rowsum(x):/NN
		x2rm = rowsum(x2):/NN
		yrm  = rowsum(y):/NN
		xgm  = sum(x)/(NN*TT)
		x2gm = sum(x2)/(NN*TT)
		ygm  = sum(y)/(NN*TT)
		xtilde  = x  :- J(TT,1,1)*xm  :- xrm*J(1,NN,1) :+ xgm
		x2tilde = x2 :- J(TT,1,1)*x2m :- x2rm*J(1,NN,1) :+ x2gm
		ytilde  = y  :- J(TT,1,1)*ym  :- yrm*J(1,NN,1)  :+ ygm
		if (q == 3) {
			x3 = x:^3
			x3m  = mean(x3)
			x3rm = rowsum(x3):/NN
			x3gm = sum(x3)/(NN*TT)
			x3tilde = x3 :- J(TT,1,1)*x3m :- x3rm*J(1,NN,1) :+ x3gm
		}
		else x3tilde = J(TT, NN, 0)
	}
}

// =======================================================================
// GROUP-MEAN FM-OLS  (matches GroupMeanFMOLS.m line-by-line)
// =======================================================================
void _xtpcmg_mg(string scalar depvar, string scalar reg, string scalar ctrls,
                string scalar touse,
                real scalar N, real scalar T, real scalar q, real scalar typee,
                string scalar kern, string scalar bwopt, real scalar corrrob)
{
	real scalar i, j, TT, bandw, nc, k, p
	real scalar mu_i, Omega_uu, Omega_vv, Omega_uv, Omega_vu
	real scalar Delta_vv, Delta_vu, Delta_vu_plus, Omega_udotv, Omega_ij
	real matrix Y_view, X_view, y, x, v
	real matrix ytilde, xtilde, x2tilde, x3tilde
	real matrix betaGM, V, Xtilde_i, betaOLS_i, betaFM_i, betaFM_list
	real matrix u_hat_i, v_i, Omega_i, Delta_i, Sigma_i
	real matrix ytilde_plus_i, C_i
	real matrix u_hat_all, v_hat_all
	real matrix Omega_2N, Delta_2N, Sigma_2N
	real matrix Omega_uu_N, Omega_uv_N, Omega_vu_N, Omega_vv_N
	real matrix Mii, Mij2, Mjj, Xtilde_j
	string scalar cnames
	real matrix Z_view, z_raw, z_k, ztilde_list, D2, P2
	string rowvector ctrl_tokens

	st_view(Y_view, ., depvar, touse)
	st_view(X_view, ., reg, touse)
	y = Y_view[.,.]
	x = X_view[.,.]
	y = colshape(y, N)
	x = colshape(x, N)

	// Parse controls
	nc = 0
	ctrl_tokens = J(1, 0, "")
	if (strlen(ctrls) > 0) {
		ctrl_tokens = tokens(ctrls)
		nc = cols(ctrl_tokens)
	}
	p = q + nc

	// diff(x), drop first obs
	v = x[2..T,.] - x[1..(T-1),.]
	y = y[2..T,.]
	x = x[2..T,.]
	TT = T - 1

	// Demean/detrend polynomial
	_demean_detrend(y, x, typee, ytilde, xtilde, x2tilde, x3tilde)

	// Load and demean controls
	ztilde_list = J(0, 0, .)
	if (nc > 0) {
		if (typee == 1) D2 = J(TT, 1, 1)
		else            D2 = (J(TT,1,1), (1::TT))
		P2 = I(TT) - D2 * invsym(D2'*D2) * D2'
		ztilde_list = J(TT, N*nc, 0)
		for (k=1; k<=nc; k++) {
			st_view(Z_view, ., ctrl_tokens[k], touse)
			z_raw = Z_view[.,.]
			z_raw = colshape(z_raw, N)
			z_k = z_raw[2..T, .]
			for (i=1; i<=N; i++) {
				ztilde_list[., (k-1)*N + i] = P2 * z_k[., i]
			}
		}
	}

	betaGM      = J(p, 1, 0)
	V           = J(p, p, 0)
	u_hat_all   = J(TT, N, 0)
	v_hat_all   = J(TT, N, 0)
	betaFM_list = J(p, N, 0)

	for (i=1; i<=N; i++) {

		if (q == 2) Xtilde_i = (xtilde[.,i], x2tilde[.,i])
		else        Xtilde_i = (xtilde[.,i], x2tilde[.,i], x3tilde[.,i])
		if (nc > 0) {
			for (k=1; k<=nc; k++) {
				Xtilde_i = (Xtilde_i, ztilde_list[., (k-1)*N + i])
			}
		}

		betaOLS_i = invsym(Xtilde_i'*Xtilde_i) * (Xtilde_i'*ytilde[.,i])
		u_hat_i = ytilde[.,i] - Xtilde_i*betaOLS_i
		v_i     = v[.,i]
		mu_i    = mean(v_i)

		u_hat_all[.,i] = u_hat_i
		v_hat_all[.,i] = v_i :- mu_i

		if (bwopt == "And91") bandw = _And_HAC91((u_hat_i, v_i:-mu_i), kern)
		else {
			bandw = strtoreal(bwopt)
			if (bandw >= .) bandw = _And_HAC91((u_hat_i, v_i:-mu_i), kern)
		}

		_lr_varmod((u_hat_i, v_i:-mu_i), kern, bandw, 0, Omega_i, Delta_i, Sigma_i)

		Omega_uu      = Omega_i[1,1]
		Omega_vv      = Omega_i[2,2]
		Omega_uv      = Omega_i[1,2]
		Omega_vu      = Omega_i[2,1]
		Delta_vv      = Delta_i[2,2]
		Delta_vu      = Delta_i[2,1]
		Delta_vu_plus = Delta_vu - Delta_vv*(1/Omega_vv)*Omega_vu
		Omega_udotv   = Omega_uu - Omega_uv*(1/Omega_vv)*Omega_vu

		ytilde_plus_i = ytilde[.,i] - v_i*(1/Omega_vv)*Omega_vu

		// Bias correction: polynomial terms only, zeros for controls
		if (q == 2) C_i = Delta_vu_plus * (TT \ 2*colsum(x[.,i]))
		else        C_i = Delta_vu_plus * (TT \ 2*colsum(x[.,i]) \ 3*colsum(x[.,i]:^2))
		if (nc > 0) C_i = (C_i \ J(nc, 1, 0))

		betaFM_i = invsym(Xtilde_i'*Xtilde_i) * (Xtilde_i'*ytilde_plus_i - C_i)
		betaFM_list[., i] = betaFM_i
		betaGM   = betaGM + betaFM_i

		if (corrrob == 0) {
			V = V + Omega_udotv * invsym(Xtilde_i'*Xtilde_i)
		}
	}

	betaGM = betaGM / N

	// --- Cross-sectional robust VCV ---
	if (corrrob == 1) {
		if (bwopt == "And91") bandw = _And_HAC91((u_hat_all, v_hat_all), kern)
		_lr_varmod((u_hat_all, v_hat_all), kern, bandw, 0, Omega_2N, Delta_2N, Sigma_2N)

		Omega_uu_N = Omega_2N[1..N, 1..N]
		Omega_uv_N = Omega_2N[1..N, (N+1)..(2*N)]
		Omega_vu_N = Omega_2N[(N+1)..(2*N), 1..N]
		Omega_vv_N = Omega_2N[(N+1)..(2*N), (N+1)..(2*N)]

		for (i=1; i<=N; i++) {
			if (q == 2) Xtilde_i = (xtilde[.,i], x2tilde[.,i])
			else        Xtilde_i = (xtilde[.,i], x2tilde[.,i], x3tilde[.,i])
			if (nc > 0) {
				for (k=1; k<=nc; k++) Xtilde_i = (Xtilde_i, ztilde_list[., (k-1)*N + i])
			}
			Mii = Xtilde_i'*Xtilde_i

			for (j=1; j<=N; j++) {
				if (q == 2) Xtilde_j = (xtilde[.,j], x2tilde[.,j])
				else        Xtilde_j = (xtilde[.,j], x2tilde[.,j], x3tilde[.,j])
				if (nc > 0) {
					for (k=1; k<=nc; k++) Xtilde_j = (Xtilde_j, ztilde_list[., (k-1)*N + j])
				}
				Mij2 = Xtilde_i'*Xtilde_j
				Mjj  = Xtilde_j'*Xtilde_j

				Omega_ij = Omega_uu_N[i,j] - (Omega_uv_N[i,i]/Omega_vv_N[i,i])*Omega_vu_N[i,j] - (Omega_uv_N[j,j]/Omega_vv_N[j,j])*Omega_vu_N[j,i] + (Omega_uv_N[i,i]/Omega_vv_N[i,i])*Omega_vv_N[i,j]*(Omega_vu_N[j,j]/Omega_vv_N[j,j])

				V = V + Omega_ij * (invsym(Mii) * Mij2 * invsym(Mjj))
			}
		}
	}

	V = V / (N^2)

	if (q == 2) cnames = reg + " " + reg + "^2"
	else        cnames = reg + " " + reg + "^2 " + reg + "^3"
	if (nc > 0) {
		for (k=1; k<=nc; k++) cnames = cnames + " " + ctrl_tokens[k]
	}

	st_matrix("__xtpcmg_b", betaGM')
	st_matrix("__xtpcmg_V", V)
	st_matrix("__xtpcmg_indiv", betaFM_list')
	st_local("bnames", cnames)
}

// =======================================================================
// POOLED FM-OLS  (matches PanelEKC_indiv_eff_only.m line-by-line)
// =======================================================================
void _xtpcmg_pmg(string scalar depvar, string scalar reg, string scalar ctrls,
                 string scalar touse,
                 real scalar N, real scalar T, real scalar q,
                 string scalar kern, string scalar bwopt, string scalar effects)
{
	real scalar i, TT, bandw, Sum_Omega_udotv, Omega_udotv_i, Ouv2vv_i
	real scalar Dr_vu_plus, nc, k, p
	real matrix Y_view, X_view, y, x, vt
	real matrix ytilde, xtilde, x2tilde, x3tilde
	real matrix ytilde_vec, xtilde_vec, x2tilde_vec, x3tilde_vec, Xtilde_vec
	real matrix XX_tilde, invXX_tilde, u_hat_vec
	real colvector beta_lsdv, beta_FM, Sum_Mi, Sum_FM_cor, C_plus_star_i, Mi
	real colvector u_hat_i2, vt_i, ytildeplus_i, FM_cor_i
	real matrix GT, M_mat, Q_mat
	real matrix Sum_Lr, Sum_Dr, Sum_DMD, Sum_ODMD, Sum_ODQD, Sum_Sigma_13
	real matrix Lr_i, Dr_i, Sr_i, D_i, Xtilde_i2
	real matrix Lr_mean, Dr_mean
	real matrix V1_hat, invV1_hat, Sigma11, Sigma12, Sigma13, VCV_FM
	string scalar cnames
	real matrix Z_view, z_raw, z_k, ztilde_ctrl
	string rowvector ctrl_tokens
	real matrix VCV_full, VCV_poly, VCV_ctrl
	real matrix zt_y, zt_x, zt_x2, zt_x3
	real matrix Xc, u_fm, meat_c, bread_c

	st_view(Y_view, ., depvar, touse)
	st_view(X_view, ., reg, touse)
	y = Y_view[.,.]
	x = X_view[.,.]
	y = colshape(y, N)
	x = colshape(x, N)

	// Parse controls
	nc = 0
	ctrl_tokens = J(1, 0, "")
	if (strlen(ctrls) > 0) {
		ctrl_tokens = tokens(ctrls)
		nc = cols(ctrl_tokens)
	}
	p = q + nc

	TT = T

	// vt = [x(1,:); diff(x)]
	vt = J(TT, N, 0)
	vt[1,.] = x[1,.]
	if (TT > 1) vt[2..TT,.] = x[2..TT,.] - x[1..(TT-1),.]

	// Demean polynomial
	_simpledemean(y, x, effects, q, ytilde, xtilde, x2tilde, x3tilde)

	// Stack polynomial into NT x 1
	ytilde_vec  = vec(ytilde)
	xtilde_vec  = vec(xtilde)
	x2tilde_vec = vec(x2tilde)
	if (q == 2) Xtilde_vec = (xtilde_vec, x2tilde_vec)
	else {
		x3tilde_vec = vec(x3tilde)
		Xtilde_vec  = (xtilde_vec, x2tilde_vec, x3tilde_vec)
	}

	// Load, demean and stack controls
	if (nc > 0) {
		for (k=1; k<=nc; k++) {
			st_view(Z_view, ., ctrl_tokens[k], touse)
			z_raw = Z_view[.,.]
			z_raw = colshape(z_raw, N)
			// Demean control using same scheme as y (pass z as y argument)
			_simpledemean(z_raw, x, effects, q, zt_y, zt_x, zt_x2, zt_x3)
			Xtilde_vec = (Xtilde_vec, vec(zt_y))
		}
	}

	// OLS / LSDV
	XX_tilde    = Xtilde_vec' * Xtilde_vec
	invXX_tilde = invsym(XX_tilde)
	beta_lsdv   = invXX_tilde * (Xtilde_vec' * ytilde_vec)
	u_hat_vec   = ytilde_vec - Xtilde_vec * beta_lsdv

	// M, Q, GT matrices (polynomial terms only)
	if (q == 2) {
		GT    = diag((T^(-1), T^(-1.5)))
		M_mat = (1/6, 0 \ 0, 5/12)
		Q_mat = (1/3, 0 \ 0, 59/60)
	}
	else {
		GT    = diag((T^(-1), T^(-1.5), T^(-2)))
		M_mat = (1/6, 0, 3/8 \ 0, 5/12, 0 \ 3/8, 0, 39/20)
		Q_mat = (1/3, 0, 9/10 \ 0, 59/60, 0 \ 9/10, 0, 101/20)
	}

	Sum_Lr          = J(2,2,0)
	Sum_Dr          = J(2,2,0)
	Sum_Mi          = J(q,1,0)
	Sum_FM_cor      = J(p,1,0)
	Sum_DMD         = J(q,q,0)
	Sum_Omega_udotv = 0
	Sum_ODMD        = J(q,q,0)
	Sum_ODQD        = J(q,q,0)
	Sum_Sigma_13    = J(q,q,0)

	for (i=1; i<=N; i++) {

		u_hat_i2  = u_hat_vec[((i-1)*TT+1)..(i*TT)]
		vt_i      = vt[.,i]
		Xtilde_i2 = Xtilde_vec[((i-1)*TT+1)..(i*TT),.]

		if (bwopt == "And91")    bandw = _And_HAC91((u_hat_i2, vt_i), kern)
		else if (bwopt == "NW")  bandw = _And_HAC91((u_hat_i2, vt_i), kern)
		else {
			bandw = strtoreal(bwopt)
			if (bandw >= .) bandw = _And_HAC91((u_hat_i2, vt_i), kern)
		}

		_lr_varmod((u_hat_i2, vt_i), kern, bandw, 0, Lr_i, Dr_i, Sr_i)

		Sum_Lr = Sum_Lr + Lr_i
		Sum_Dr = Sum_Dr + Dr_i

		if (q == 2) Mi = (TT \ 2*sum(x[.,i]))
		else        Mi = (TT \ 2*sum(x[.,i]) \ 3*sum(x[.,i]:^2))
		Sum_Mi = Sum_Mi + Mi

		if (q == 2) D_i = diag((Lr_i[2,2]^(0.5), Lr_i[2,2]))
		else        D_i = diag((Lr_i[2,2]^(0.5), Lr_i[2,2], Lr_i[2,2]^(1.5)))

		Sum_DMD = Sum_DMD + D_i*M_mat*D_i

		Omega_udotv_i   = Lr_i[1,1] - (Lr_i[2,2]^(-1))*Lr_i[2,1]^2
		Sum_Omega_udotv = Sum_Omega_udotv + Omega_udotv_i

		Sum_ODMD = Sum_ODMD + Omega_udotv_i*(D_i*M_mat*D_i)

		Ouv2vv_i = (Lr_i[1,2]^2)*(Lr_i[2,2])^(-1)
		Sum_ODQD = Sum_ODQD + Ouv2vv_i*(D_i*Q_mat*D_i)

		if (q == 2) {
			Sum_Sigma_13 = Sum_Sigma_13 + (0.25*Lr_i[1,2]^2, 0 \ 0, 0)
		}
		else {
			Sum_Sigma_13 = Sum_Sigma_13 + (0.25*Lr_i[1,2]^2, 0, 0.5*Lr_i[2,2]*Lr_i[1,2]^2 \ 0, 0, 0 \ 0.5*Lr_i[2,2]*Lr_i[1,2]^2, 0, (Lr_i[2,2]^2)*(Lr_i[1,2]^2))
		}
	}

	// --- Correction terms ---
	Lr_mean = Sum_Lr/N
	Dr_mean = Sum_Dr/N

	Dr_vu_plus = Dr_mean[2,1] - Dr_mean[2,2]*(Lr_mean[2,2]^(-1))*Lr_mean[2,1]

	for (i=1; i<=N; i++) {
		if (q == 2) C_plus_star_i = Dr_vu_plus * (TT \ 2*sum(x[.,i]))
		else        C_plus_star_i = Dr_vu_plus * (TT \ 2*sum(x[.,i]) \ 3*sum(x[.,i]:^2))
		// Zero correction for controls
		if (nc > 0) C_plus_star_i = (C_plus_star_i \ J(nc, 1, 0))

		ytildeplus_i = ytilde[.,i] - Lr_mean[1,2]*(Lr_mean[2,2]^(-1))*vt[.,i]
		Xtilde_i2    = Xtilde_vec[((i-1)*TT+1)..(i*TT),.]
		FM_cor_i     = Xtilde_i2'*ytildeplus_i - C_plus_star_i
		Sum_FM_cor   = Sum_FM_cor + FM_cor_i
	}

	// --- FM-OLS estimator ---
	beta_FM = invXX_tilde * Sum_FM_cor

	// --- VCV ---
	// Polynomial VCV uses exact M/Q/GT framework
	V1_hat    = Sum_DMD/N
	invV1_hat = invsym(V1_hat)
	Sigma11   = Sum_ODMD/N
	Sigma12   = Sum_ODQD/N
	Sigma13   = Sum_Sigma_13/N

	VCV_poly = (1/N) * GT * (invV1_hat*Sigma11*invV1_hat) * GT

	if (nc > 0) {
		// For controls: use sandwich VCV from OLS residuals
		VCV_full = J(p, p, 0)
		VCV_full[1..q, 1..q] = VCV_poly
		// Control VCV: standard HC0 sandwich
		Xc = Xtilde_vec[., (q+1)..p]
		u_fm = ytilde_vec - Xtilde_vec * beta_FM
		bread_c = invsym(Xc'*Xc)
		meat_c = J(nc, nc, 0)
		for (i=1; i<=N*TT; i++) {
			meat_c = meat_c + u_fm[i]^2 * (Xc[i,.]' * Xc[i,.])
		}
		VCV_ctrl = bread_c * meat_c * bread_c
		VCV_full[(q+1)..p, (q+1)..p] = VCV_ctrl
		VCV_FM = VCV_full
	}
	else {
		VCV_FM = VCV_poly
	}

	if (q == 2) cnames = reg + " " + reg + "^2"
	else        cnames = reg + " " + reg + "^2 " + reg + "^3"
	if (nc > 0) {
		for (k=1; k<=nc; k++) cnames = cnames + " " + ctrl_tokens[k]
	}

	st_matrix("__xtpcmg_b", beta_FM')
	st_matrix("__xtpcmg_V", VCV_FM)
	st_local("bnames", cnames)
}

// =======================================================================
// HETEROGENEITY ANALYSIS HELPERS
// =======================================================================

// Descriptive statistics: mean, median, sd, iqr, skewness, kurtosis
void _xtpcmg_hetstat(real matrix vals)
{
	real colvector v, sv
	real scalar n, mn, md, sd, q1, q3, iqr, sk, ku, m2, m3, m4, p25i, p75i
	
	v = vec(vals)
	n = rows(v)
	mn = mean(v)
	sd = sqrt(variance(v))
	sv = sort(v, 1)
	
	// Median
	if (mod(n, 2) == 0) md = (sv[n/2] + sv[n/2 + 1]) / 2
	else                md = sv[(n+1)/2]
	
	// IQR
	p25i = max((1, ceil(n * 0.25)))
	p75i = min((n, ceil(n * 0.75)))
	q1 = sv[p25i]
	q3 = sv[p75i]
	iqr = q3 - q1
	
	// Skewness and Kurtosis (Fisher)
	m2 = mean((v :- mn):^2)
	m3 = mean((v :- mn):^3)
	m4 = mean((v :- mn):^4)
	if (m2 > 0) {
		sk = m3 / (m2^1.5)
		ku = m4 / (m2^2)
	}
	else {
		sk = 0
		ku = 0
	}
	
	st_numscalar("__hmean", mn)
	st_numscalar("__hmed", md)
	st_numscalar("__hsd", sd)
	st_numscalar("__hiqr", iqr)
	st_numscalar("__hskew", sk)
	st_numscalar("__hkurt", ku)
}

// Percentiles: min, p5, p25, p75, p95, max
void _xtpcmg_hetpctl(real matrix vals)
{
	real colvector v, sv
	real scalar n
	
	v = vec(vals)
	n = rows(v)
	sv = sort(v, 1)
	
	st_numscalar("__pmin", sv[1])
	st_numscalar("__p5",  sv[max((1, ceil(n * 0.05)))])
	st_numscalar("__p25", sv[max((1, ceil(n * 0.25)))])
	st_numscalar("__p75", sv[min((n, ceil(n * 0.75)))])
	st_numscalar("__p95", sv[min((n, ceil(n * 0.95)))])
	st_numscalar("__pmax", sv[n])
}

// Swamy (1970) S-test for slope homogeneity
// S = sum_i (b_i - b_bar)' * inv(V_bar) * (b_i - b_bar)
// Under H0: S ~ chi2((N-1)*K)
void _xtpcmg_swamy(real matrix indiv_b, real scalar N, real scalar K)
{
	real scalar i, S_stat, df
	real colvector b_bar, b_i, diff
	real matrix V_emp, invV
	
	// Group mean
	b_bar = mean(indiv_b)'
	
	// Empirical covariance of individual estimates
	V_emp = J(K, K, 0)
	for (i=1; i<=N; i++) {
		diff = indiv_b[i, .]' - b_bar
		V_emp = V_emp + diff * diff'
	}
	V_emp = V_emp / (N - 1)
	invV = invsym(V_emp)
	
	// S statistic
	S_stat = 0
	for (i=1; i<=N; i++) {
		diff = indiv_b[i, .]' - b_bar
		S_stat = S_stat + diff' * invV * diff
	}
	
	df = (N - 1) * K
	
	st_numscalar(st_local("Sstat"), S_stat)
	st_numscalar(st_local("Sdf"), df)
	st_numscalar(st_local("Sp"), 1 - chi2(df, S_stat))
}

// Sort individual coefficients for caterpillar plot
void _xtpcmg_sort_coef(real matrix indiv_b, real scalar col, real scalar n,
                       string scalar coef_var, string scalar rank_var)
{
	real scalar i
	real colvector cc, idx
	
	cc = indiv_b[., col]
	idx = order(cc, 1)
	for (i=1; i<=n; i++) {
		st_store(i, coef_var, cc[idx[i]])
		st_store(i, rank_var, i)
	}
}

end
