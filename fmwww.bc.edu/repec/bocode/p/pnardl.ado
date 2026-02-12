*! version 1.0.0  11feb2026  Dr Merwan Roudane  merwanroudane920@gmail.com
*! pnardl: Panel Nonlinear ARDL (Panel NARDL) estimation
*! Based on Shin, Yu and Greenwood-Nimmo (2014)
*! Requires: xtpmg (version 2.0.0+)

capture program drop pnardl
program define pnardl, eclass
	version 15.1
	
	syntax varlist(ts min=2) [if] [in], ///
		LR(varlist ts)                  ///
		ASYMmetric(varlist)             ///
		[                               ///
		EC(name)                        ///
		REPLACE                         ///
		MG DFE PMG                      ///
		FULL                            ///
		Level(integer `c(level)')       ///
		TECHnique(passthru)             ///
		DIFficult                       ///
		CONSTraints(numlist)            ///
		noCONStant                      ///
		CLUster(passthru)               ///
		HAUSman                         ///
		NOASYMtest                      ///
		]

	* =========================================================================
	* 0. VALIDATION
	* =========================================================================
	
	* Check that xtpmg is installed
	capture which xtpmg
	if _rc {
		di as err "pnardl requires {bf:xtpmg} (version 2.0.0+)."
		di as err "Install with: {stata ssc install xtpmg, replace}"
		exit 199
	}
	
	* Check panel structure
	qui tsset
	local ivar `r(panelvar)'
	local tvar `r(timevar)'
	if "`ivar'" == "" {
		di as err "panel variable not set; use {bf:xtset panelid timevar}"
		exit 459
	}
	
	* Parse model type (default = PMG)
	if ("`mg'"!="")+("`dfe'"!="")+("`pmg'"!="")>1 {
		di as err "choose only one of {bf:pmg}, {bf:mg}, or {bf:dfe}"
		exit 198
	}
	local modelopt ""
	local modelname "PMG"
	if "`mg'" != "" {
		local modelopt "mg"
		local modelname "MG"
	}
	else if "`dfe'" != "" {
		local modelopt "dfe"
		local modelname "DFE"
	}
	else {
		local modelopt "pmg"
		local modelname "PMG"
	}
	
	* Parse EC name
	if "`ec'" == "" local ec "ECT"
	
	* =========================================================================
	* 1. DECOMPOSE ASYMMETRIC VARIABLES
	* =========================================================================
	
	di
	di in smcl in gr "{hline 78}"
	di in gr "Panel NARDL Estimation" _col(49) in ye "Version 1.0.0"
	di in gr "{it:Shin, Yu and Greenwood-Nimmo (2014)}"
	di in smcl in gr "{hline 78}"
	di
	
	marksample touse
	
	* Store original variable names for display
	local asym_vars_display ""
	local pos_vars ""
	local neg_vars ""
	local generated_vars ""
	
	foreach v of local asymmetric {
		* Get base variable name (strip ts operators)
		local vbase = subinstr("`v'", ".", "_", .)
		local vbase = subinstr("`vbase'", "L", "l", .)
		local vbase = subinstr("`vbase'", "D", "d", .)
		
		local posname "`v'_pos"
		local negname "`v'_neg"
		
		* Clean names for Stata variable naming
		local posclean = subinstr("`posname'", ".", "_", .)
		local negclean = subinstr("`negname'", ".", "_", .)
		
		* Drop existing if replace specified
		if "`replace'" != "" {
			capture drop `posclean'
			capture drop `negclean'
			capture drop _d_`v'
			capture drop _d_`v'_pos
			capture drop _d_`v'_neg
		}
		
		* Check if decomposed variables already exist
		capture confirm variable `posclean'
		if !_rc {
			di as err "Variable `posclean' already exists. Use {bf:replace} option."
			exit 110
		}
		capture confirm variable `negclean'
		if !_rc {
			di as err "Variable `negclean' already exists. Use {bf:replace} option."
			exit 110
		}
		
		* Generate first difference
		tempvar dv dvpos dvneg
		qui gen double `dv' = d.`v' if `touse'
		
		* Decompose into positive and negative shocks
		qui gen double `dvpos' = max(`dv', 0) if `touse'
		qui gen double `dvneg' = min(`dv', 0) if `touse'
		
		* Replace missing with 0 for cumulative sum
		qui replace `dvpos' = 0 if `dvpos' == . & `touse'
		qui replace `dvneg' = 0 if `dvneg' == . & `touse'
		
		* Generate cumulative partial sums by panel
		sort `ivar' `tvar'
		qui by `ivar': gen double `posclean' = sum(`dvpos') if `touse'
		qui by `ivar': gen double `negclean' = sum(`dvneg') if `touse'
		
		* Label variables
		label variable `posclean' "Positive partial sum of `v'"
		label variable `negclean' "Negative partial sum of `v'"
		
		di in gr "  Decomposed: " in ye "`v'" in gr " -> " ///
			in ye "`posclean'" in gr " (positive), " ///
			in ye "`negclean'" in gr " (negative)"
		
		local asym_vars_display "`asym_vars_display' `v'"
		local pos_vars "`pos_vars' `posclean'"
		local neg_vars "`neg_vars' `negclean'"
		local generated_vars "`generated_vars' `posclean' `negclean'"
	}
	
	di
	
	* =========================================================================
	* 2. BUILD VARIABLE LISTS FOR XTPMG
	* =========================================================================
	
	* Parse the original varlist: depvar and SR regressors
	tokenize `varlist'
	local depvar `1'
	macro shift
	local sr_others `*'
	
	* Parse LR variables: first is lagged dep, rest are LR regressors
	tokenize `lr'
	local lr_dep `1'
	macro shift
	local lr_others `*'
	
	* Build new SR varlist: replace asymmetric vars with pos/neg in SR
	local new_sr ""
	foreach v of local sr_others {
		local is_asym 0
		local idx 0
		
		* Strip ts operators to get base variable name
		* Stata may store d.X as D.X, d.X, D1.X, etc.
		local vbase "`v'"
		local vbase : subinstr local vbase "D1." ""
		local vbase : subinstr local vbase "D." ""
		local vbase : subinstr local vbase "d1." ""
		local vbase : subinstr local vbase "d." ""
		local vbase : subinstr local vbase "L." ""
		local vbase : subinstr local vbase "l." ""
		local vbase : subinstr local vbase "L1." ""
		local vbase : subinstr local vbase "l1." ""
		
		foreach a of local asymmetric {
			local idx = `idx' + 1
			if "`vbase'" == "`a'" {
				local is_asym 1
				* Get the idx-th pos and neg var
				local pv : word `idx' of `pos_vars'
				local nv : word `idx' of `neg_vars'
				local new_sr "`new_sr' d.`pv' d.`nv'"
			}
		}
		if `is_asym' == 0 {
			local new_sr "`new_sr' `v'"
		}
	}
	
	* Build new LR varlist: replace asymmetric vars with pos/neg in LR
	local new_lr_x ""
	foreach v of local lr_others {
		local is_asym 0
		local idx 0
		foreach a of local asymmetric {
			local idx = `idx' + 1
			if "`v'" == "`a'" {
				local is_asym 1
				local pv : word `idx' of `pos_vars'
				local nv : word `idx' of `neg_vars'
				local new_lr_x "`new_lr_x' `pv' `nv'"
			}
		}
		if `is_asym' == 0 {
			local new_lr_x "`new_lr_x' `v'"
		}
	}
	
	local new_lr "`lr_dep' `new_lr_x'"
	local new_varlist "`depvar' `new_sr'"
	
	di in gr "  Dependent variable (SR): " in ye "`depvar'"
	di in gr "  Short-run regressors:    " in ye "`new_sr'"
	di in gr "  Long-run variables:      " in ye "`new_lr'"
	di in gr "  Estimator:               " in ye "`modelname'"
	di
	
	* =========================================================================
	* 3. ESTIMATE MODEL USING XTPMG
	* =========================================================================
	
	* Build xtpmg options
	local xtpmg_opts "lr(`new_lr') `modelopt' replace ec(`ec') level(`level')"
	if "`full'" != "" local xtpmg_opts "`xtpmg_opts' full"
	if "`technique'" != "" local xtpmg_opts "`xtpmg_opts' `technique'"
	if "`difficult'" != "" local xtpmg_opts "`xtpmg_opts' difficult"
	if "`constraints'" != "" local xtpmg_opts "`xtpmg_opts' constraints(`constraints')"
	if "`constant'" != "" local xtpmg_opts "`xtpmg_opts' noconstant"
	if "`cluster'" != "" local xtpmg_opts "`xtpmg_opts' `cluster'"
	
	di in smcl in gr "{hline 78}"
	di in gr "Estimating `modelname' model via {bf:xtpmg}..."
	di in smcl in gr "{hline 78}"
	di
	
	xtpmg `new_varlist' `if' `in', `xtpmg_opts'
	
	* Store main results
	local main_model "`modelname'"
	estimates store `modelname'_pnardl
	
	* =========================================================================
	* 4. HAUSMAN TEST (if requested)
	* =========================================================================
	
	if "`hausman'" != "" & "`modelopt'" != "dfe" {
		di
		di in smcl in gr "{hline 78}"
		di in gr "Hausman Test: MG vs PMG"
		di in smcl in gr "{hline 78}"
		di
		
		* Need to estimate both MG and PMG
		if "`modelopt'" == "pmg" {
			* Already have PMG, need MG
			di in gr "Estimating MG model for comparison..."
			qui capture drop `ec'
			qui xtpmg `new_varlist' `if' `in', lr(`new_lr') mg replace ec(`ec') level(`level') `constant'
			estimates store MG_hausman
			qui capture drop `ec'
			qui xtpmg `new_varlist' `if' `in', lr(`new_lr') pmg replace ec(`ec') level(`level') `constant'
			estimates store PMG_hausman
			hausman MG_hausman PMG_hausman, sigmamore
		}
		else if "`modelopt'" == "mg" {
			* Already have MG, need PMG
			di in gr "Estimating PMG model for comparison..."
			qui capture drop `ec'
			qui xtpmg `new_varlist' `if' `in', lr(`new_lr') pmg replace ec(`ec') level(`level') `constant'
			estimates store PMG_hausman
			qui capture drop `ec'
			qui xtpmg `new_varlist' `if' `in', lr(`new_lr') mg replace ec(`ec') level(`level') `constant'
			estimates store MG_hausman
			hausman MG_hausman PMG_hausman, sigmamore
		}
		
		* Restore the main model
		qui capture drop `ec'
		qui xtpmg `new_varlist' `if' `in', `xtpmg_opts'
		estimates store `modelname'_pnardl
	}
	
	* =========================================================================
	* 5. ASYMMETRY TESTS (Wald tests)
	* =========================================================================
	
	if "`noasymtest'" == "" {
		di
		di in smcl in gr "{hline 78}"
		di in gr "Tests for Asymmetry (Wald Tests)"
		di in smcl in gr "{hline 78}"
		di
		
		local idx 0
		foreach v of local asymmetric {
			local idx = `idx' + 1
			local pv : word `idx' of `pos_vars'
			local nv : word `idx' of `neg_vars'
			
			di in ye "Variable: `v'"
			di in gr "{hline 40}"
			
			* Long-run asymmetry test
			di in gr "  H0: Long-run symmetry (beta+ = beta-)"
			capture test [`ec']`pv' = [`ec']`nv'
			if !_rc {
				di in gr "    chi2(" %1.0f r(df) ") = " in ye %9.4f r(chi2)
				di in gr "    Prob > chi2 = " in ye %9.4f r(p)
				if r(p) < 0.05 {
					di in ye "    -> Long-run asymmetry DETECTED (reject H0 at 5%)"
				}
				else {
					di in gr "    -> Long-run symmetry NOT rejected at 5%"
				}
			}
			else {
				di in ye "    (Could not test — check equation labels)"
			}
			
			di
			
			* Short-run asymmetry test
			* Try multiple coefficient name formats:
			*   [SR]D.var  [SR]d.var  D.var  d.var  [SR]D1.var
			di in gr "  H0: Short-run symmetry (gamma+ = gamma-)"
			local sr_tested 0
			foreach fmt in "[SR]D." "[SR]d." "[SR]D1." "[SR]" "D." "d." "D1." "" {
				if `sr_tested' == 0 {
					capture test `fmt'`pv' = `fmt'`nv'
					if !_rc {
						local sr_tested 1
					}
				}
			}
			if `sr_tested' == 1 {
				di in gr "    chi2(" %1.0f r(df) ") = " in ye %9.4f r(chi2)
				di in gr "    Prob > chi2 = " in ye %9.4f r(p)
				if r(p) < 0.05 {
					di in ye "    -> Short-run asymmetry DETECTED (reject H0 at 5%)"
				}
				else {
					di in gr "    -> Short-run symmetry NOT rejected at 5%"
				}
			}
			else {
				di in ye "    (Could not test — SR decomposed variables not found in estimation)"
			}
			
			di
		}
	}
	
	* =========================================================================
	* 6. STORE RESULTS
	* =========================================================================
	
	ereturn local cmd "pnardl"
	ereturn local model "`modelname'"
	ereturn local asymmetric "`asym_vars_display'"
	ereturn local pos_vars "`pos_vars'"
	ereturn local neg_vars "`neg_vars'"
	ereturn local depvar "`depvar'"
	ereturn local ivar "`ivar'"
	ereturn local tvar "`tvar'"
	
	di
	di in smcl in gr "{hline 78}"
	di in gr "Note: Partial sum variables " in ye "`generated_vars'"
	di in gr "have been added to the dataset."
	di in smcl in gr "{hline 78}"
	
end
