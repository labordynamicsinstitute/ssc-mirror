*! version 1.1.0  12feb2026  Dr Merwan Roudane  merwanroudane920@gmail.com
*! pnardl: Panel Nonlinear ARDL (Panel NARDL) estimation
*! Based on Shin, Yu and Greenwood-Nimmo (2014)
*! Features: Dynamic multipliers, asymmetry tables, IRF for +/- shocks, graphs
*! Requires: xtpmg (version 2.0.1+)

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
		MULTip(integer 0)               ///
		ASYTable                        ///
		IRFShock(integer 0)             ///
		PANELcoef                       ///
		GRaph                           ///
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
	di in gr "{bf:Panel NARDL Estimation}" _col(49) in ye "Version 1.1.0"
	di in gr "{it:Shin, Yu and Greenwood-Nimmo (2014)}"
	di in smcl in gr "{hline 78}"
	
	* Validate new options
	if `multip' < 0 | `multip' > 50 {
		di as err "multip() must be between 0 and 50"
		exit 198
	}
	if `irfshock' < 0 | `irfshock' > 50 {
		di as err "irfshock() must be between 0 and 50"
		exit 198
	}
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
	* 6. POST-ESTIMATION DIAGNOSTICS (new in 1.1.0)
	* =========================================================================
	
	* Asymmetry comparison table
	if "`asytable'" != "" {
		capture quie est restore PMG
		pnardl_AsymTable, ivar(`ivar') ec(`ec') ///
			posvars(`pos_vars') negvars(`neg_vars') ///
			asymvars(`asym_vars_display')
	}
	
	* Per-panel coefficients
	if "`panelcoef'" != "" {
		capture quie est restore PMG
		pnardl_PanelCoef, ivar(`ivar') ec(`ec') ///
			posvars(`pos_vars') negvars(`neg_vars') ///
			asymvars(`asym_vars_display')
	}
	
	* Dynamic multipliers
	if `multip' > 0 {
		capture quie est restore PMG
		pnardl_DynMultiplier, periods(`multip') ivar(`ivar') ec(`ec') ///
			posvars(`pos_vars') negvars(`neg_vars') ///
			asymvars(`asym_vars_display')
	}
	
	* IRF for positive/negative shocks
	if `irfshock' > 0 {
		capture quie est restore PMG
		pnardl_IRFShock, periods(`irfshock') ivar(`ivar') ec(`ec') ///
			posvars(`pos_vars') negvars(`neg_vars') ///
			asymvars(`asym_vars_display')
	}
	
	* Graph visualizations
	if "`graph'" != "" {
		di
		di in smcl in gr "{hline 78}"
		di in gr "{bf:Generating Visualizations}" _col(49) in ye "PNARDL 1.1.0"
		di in smcl in gr "{hline 78}"
		
		capture quie est restore PMG
		pnardl_PlotECT, ivar(`ivar') ec(`ec')
		pnardl_PlotAsymLR, ivar(`ivar') ec(`ec') ///
			posvars(`pos_vars') negvars(`neg_vars') ///
			asymvars(`asym_vars_display')
		
		if `multip' > 0 | `irfshock' > 0 {
			local mp = max(`multip', `irfshock')
			if `mp' == 0 local mp = 20
			pnardl_PlotMultiplier, periods(`mp') ivar(`ivar') ec(`ec') ///
				posvars(`pos_vars') negvars(`neg_vars') ///
				asymvars(`asym_vars_display')
		}
		
		di in smcl in gr "{hline 78}"
		di
	}
	
	* =========================================================================
	* 7. STORE RESULTS
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


* =========================================================================
* NEW IN 1.1.0: pnardl_AsymTable
* LR/SR asymmetry comparison table
* =========================================================================

program define pnardl_AsymTable
	syntax, IVar(string) EC(string) POSvars(string) NEGvars(string) ASYMvars(string)
	
	di
	di in smcl in gr "{hline 78}"
	di in gr "{bf:Asymmetry Comparison Table}" _col(49) in ye "PNARDL 1.1.0"
	di in smcl in gr "{hline 78}"
	di
	
	local nasym = wordcount("`asymvars'")
	
	* Long-run coefficients
	di in gr "  {bf:Long-Run Coefficients (from cointegrating vector):}"
	di
	di in smcl in gr "  {hline 74}"
	di in gr %14s "Variable" " {c |}" ///
		%12s "Beta(+)" " {c |}" ///
		%12s "Beta(-)" " {c |}" ///
		%12s "Diff" " {c |}" ///
		%10s "  Effect" " {c |}" ///
		%8s " Asym?"
	di in smcl in gr "  {hline 14}{c +}{hline 13}{c +}{hline 13}{c +}{hline 13}{c +}{hline 11}{c +}{hline 9}"
	
	forvalues i = 1/`nasym' {
		local av : word `i' of `asymvars'
		local pv : word `i' of `posvars'
		local nv : word `i' of `negvars'
		
		capture local bp = _b[`ec':`pv']
		capture local bn = _b[`ec':`nv']
		
		if !_rc {
			local diff = `bp' - `bn'
			
			local eff_str "Pos/Pos"
			if `bp' > 0 & `bn' < 0 local eff_str "Pos/Neg"
			if `bp' < 0 & `bn' > 0 local eff_str "Neg/Pos"
			if `bp' < 0 & `bn' < 0 local eff_str "Neg/Neg"
			
			* Wald test for LR asymmetry
			local asym_flag "  ---"
			capture test [`ec']`pv' = [`ec']`nv'
			if !_rc {
				if r(p) < 0.01 local asym_flag "  ***"
				else if r(p) < 0.05 local asym_flag "   **"
				else if r(p) < 0.10 local asym_flag "    *"
				else local asym_flag "   No"
			}
			
			di in gr %14s "`av'" " {c |}" ///
				in ye %12.4f `bp' " {c |}" ///
				in ye %12.4f `bn' " {c |}" ///
				in ye %12.4f `diff' " {c |}" ///
				in ye %10s "`eff_str'" " {c |}" ///
				in ye "`asym_flag'"
		}
	}
	
	di in smcl in gr "  {hline 14}{c +}{hline 13}{c +}{hline 13}{c +}{hline 13}{c +}{hline 11}{c +}{hline 9}"
	di
	
	* Short-run coefficients
	di in gr "  {bf:Short-Run Coefficients (first differences):}"
	di
	di in smcl in gr "  {hline 74}"
	di in gr %14s "Variable" " {c |}" ///
		%12s "Gamma(+)" " {c |}" ///
		%12s "Gamma(-)" " {c |}" ///
		%12s "Diff" " {c |}" ///
		%10s " |G+|>|G-|" " {c |}" ///
		%8s " Asym?"
	di in smcl in gr "  {hline 14}{c +}{hline 13}{c +}{hline 13}{c +}{hline 13}{c +}{hline 11}{c +}{hline 9}"
	
	forvalues i = 1/`nasym' {
		local av : word `i' of `asymvars'
		local pv : word `i' of `posvars'
		local nv : word `i' of `negvars'
		
		* Try various coefficient name formats
		local gp = .
		local gn = .
		foreach fmt in "[SR]D." "[SR]d." "[SR]D1." "[SR]" "D." "d." "D1." "" {
			capture local gp = _b[`fmt'`pv']
			if !_rc {
				capture local gn = _b[`fmt'`nv']
				if !_rc continue, break
			}
		}
		
		if `gp' != . & `gn' != . {
			local diff = `gp' - `gn'
			local dom "  Equal"
			if abs(`gp') > abs(`gn') local dom "    Yes"
			else if abs(`gp') < abs(`gn') local dom "     No"
			
			* Test SR asymmetry
			local sr_tested 0
			foreach fmt in "[SR]D." "[SR]d." "[SR]D1." "[SR]" "D." "d." "" {
				if `sr_tested' == 0 {
					capture test `fmt'`pv' = `fmt'`nv'
					if !_rc local sr_tested 1
				}
			}
			local asym_flag "  ---"
			if `sr_tested' == 1 {
				if r(p) < 0.01 local asym_flag "  ***"
				else if r(p) < 0.05 local asym_flag "   **"
				else if r(p) < 0.10 local asym_flag "    *"
				else local asym_flag "   No"
			}
			
			di in gr %14s "`av'" " {c |}" ///
				in ye %12.4f `gp' " {c |}" ///
				in ye %12.4f `gn' " {c |}" ///
				in ye %12.4f `diff' " {c |}" ///
				in ye "`dom'" "  {c |}" ///
				in ye "`asym_flag'"
		}
	}
	
	di in smcl in gr "  {hline 14}{c +}{hline 13}{c +}{hline 13}{c +}{hline 13}{c +}{hline 11}{c +}{hline 9}"
	di in gr "  Significance: *** 1%  ** 5%  * 10%"
	di
end


* =========================================================================
* NEW IN 1.1.0: pnardl_PanelCoef
* Per-panel ECT + asymmetric coefficients
* =========================================================================

program define pnardl_PanelCoef
	syntax, IVar(string) EC(string) POSvars(string) NEGvars(string) ASYMvars(string)
	
	di
	di in smcl in gr "{hline 78}"
	di in gr "{bf:Per-Panel Coefficients}" _col(49) in ye "PNARDL 1.1.0"
	di in smcl in gr "{hline 78}"
	di
	
	di in smcl in gr "  {hline 72}"
	di in gr %10s "Panel" " {c |}" ///
		%10s "ECT(phi)" " {c |}" ///
		%10s "Half-Life" " {c |}" ///
		%10s "Adj.Spd%" " {c |}" ///
		%10s "Converge" " {c |}" ///
		%8s "Stars"
	di in smcl in gr "  {hline 10}{c +}{hline 11}{c +}{hline 11}{c +}{hline 11}{c +}{hline 11}{c +}{hline 9}"
	
	local sum_phi = 0
	local n_conv = 0
	
	foreach i of global iis {
		local coefname "`ivar'_`i':`ec'"
		capture local phi = _b[`coefname']
		if !_rc {
			capture local se = _se[`coefname']
			
			local hl = .
			local adj = .
			local conv "No"
			local star ""
			
			if `phi' < 0 & `phi' > -2 {
				local hl = ln(2) / abs(`phi')
				local adj = abs(`phi') * 100
				local conv "Yes"
				local sum_phi = `sum_phi' + `phi'
				local n_conv = `n_conv' + 1
			}
			else {
				local conv "No"
			}
			
			if !_rc & `se' > 0 {
				local tstat = abs(`phi' / `se')
				if `tstat' > 2.576 local star "***"
				else if `tstat' > 1.960 local star " **"
				else if `tstat' > 1.645 local star "  *"
			}
			
			di in gr %10s "`i'" " {c |}" ///
				in ye %10.4f `phi' " {c |}" ///
				in ye %10.2f `hl' " {c |}" ///
				in ye %9.1f `adj' "% {c |}" ///
				in ye %10s "`conv'" " {c |}" ///
				in ye " `star'"
		}
	}
	
	di in smcl in gr "  {hline 10}{c +}{hline 11}{c +}{hline 11}{c +}{hline 11}{c +}{hline 11}{c +}{hline 9}"
	
	if `n_conv' > 0 {
		local mean_phi = `sum_phi' / `n_conv'
		local mean_hl = ln(2) / abs(`mean_phi')
		di in gr "  Convergent panels: " in ye "`n_conv'" ///
			in gr "  |  Mean phi: " in ye %7.4f `mean_phi' ///
			in gr "  |  Mean half-life: " in ye %5.2f `mean_hl'
	}
	di
end


* =========================================================================
* NEW IN 1.1.0: pnardl_DynMultiplier
* Cumulative dynamic multipliers for +/- shocks
* =========================================================================

program define pnardl_DynMultiplier
	syntax, Periods(integer) IVar(string) EC(string) ///
		POSvars(string) NEGvars(string) ASYMvars(string)
	
	di
	di in smcl in gr "{hline 78}"
	di in gr "{bf:Dynamic Multipliers (Cumulative)}" _col(49) in ye "PNARDL 1.1.0"
	di in smcl in gr "{hline 78}"
	
	* Get mean ECT coefficient
	local sum_phi = 0
	local n_valid = 0
	foreach i of global iis {
		local coefname "`ivar'_`i':`ec'"
		capture local phi = _b[`coefname']
		if !_rc & `phi' < 0 {
			local sum_phi = `sum_phi' + `phi'
			local n_valid = `n_valid' + 1
		}
	}
	if `n_valid' == 0 {
		di in re "  No convergent panels for multiplier computation."
		exit
	}
	local mean_phi = `sum_phi' / `n_valid'
	
	* Get LR coefficients for first asymmetric variable
	local pv : word 1 of `posvars'
	local nv : word 1 of `negvars'
	local av : word 1 of `asymvars'
	
	capture local beta_p = _b[`ec':`pv']
	capture local beta_n = _b[`ec':`nv']
	
	if _rc {
		di in re "  Cannot find LR coefficients for `av'."
		exit
	}
	
	di in gr "  Variable: " in ye "`av'"
	di in gr "  Mean ECT (phi): " in ye %8.4f `mean_phi'
	di in gr "  LR coef pos (beta+): " in ye %8.4f `beta_p'
	di in gr "  LR coef neg (beta-): " in ye %8.4f `beta_n'
	di
	
	di in smcl in gr "  {hline 68}"
	di in gr %8s "Period" " {c |}" ///
		%14s "m+(h)" " {c |}" ///
		%14s "m-(h)" " {c |}" ///
		%14s "m+ - m-" " {c |}" ///
		%12s "Asymmetry"
	di in smcl in gr "  {hline 8}{c +}{hline 15}{c +}{hline 15}{c +}{hline 15}{c +}{hline 13}"
	
	* Simulate cumulative multipliers
	local gap_p = 1
	local gap_n = -1
	local cum_p = 0
	local cum_n = 0
	
	forvalues h = 0/`periods' {
		if `h' == 0 {
			local m_p = 0
			local m_n = 0
		}
		else {
			* Error correction toward LR
			local adj_p = `mean_phi' * (`gap_p' - `beta_p')
			local adj_n = `mean_phi' * (`gap_n' - `beta_n')
			local gap_p = `gap_p' + `adj_p'
			local gap_n = `gap_n' + `adj_n'
			local m_p = `gap_p'
			local m_n = `gap_n'
		}
		
		local diff = `m_p' - `m_n'
		local asym_str ""
		if abs(`diff') > 0.01 {
			if `diff' > 0 local asym_str "  {res:m+ > m-}"
			else local asym_str "  {err:m+ < m-}"
		}
		else local asym_str "  ~Symmetric"
		
		di in gr %8.0f `h' " {c |}" ///
			in ye %14.4f `m_p' " {c |}" ///
			in ye %14.4f `m_n' " {c |}" ///
			in ye %14.4f `diff' " {c |}" ///
			"`asym_str'"
	}
	
	di in smcl in gr "  {hline 8}{c +}{hline 15}{c +}{hline 15}{c +}{hline 15}{c +}{hline 13}"
	
	di
	di in gr "  {bf:Long-run multipliers:}"
	di in gr "    m+(inf) = beta+ = " in ye %8.4f `beta_p'
	di in gr "    m-(inf) = beta- = " in ye %8.4f `beta_n'
	di in gr "    Asymmetry (beta+ - beta-) = " in ye %8.4f `beta_p' - `beta_n'
	di
end


* =========================================================================
* NEW IN 1.1.0: pnardl_IRFShock
* IRF for positive vs negative shocks separately
* =========================================================================

program define pnardl_IRFShock
	syntax, Periods(integer) IVar(string) EC(string) ///
		POSvars(string) NEGvars(string) ASYMvars(string)
	
	di
	di in smcl in gr "{hline 78}"
	di in gr "{bf:IRF: Positive vs Negative Shocks}" _col(49) in ye "PNARDL 1.1.0"
	di in smcl in gr "{hline 78}"
	
	* Get mean ECT
	local sum_phi = 0
	local n_valid = 0
	foreach i of global iis {
		local coefname "`ivar'_`i':`ec'"
		capture local phi = _b[`coefname']
		if !_rc & `phi' < 0 {
			local sum_phi = `sum_phi' + `phi'
			local n_valid = `n_valid' + 1
		}
	}
	if `n_valid' == 0 {
		di in re "  No convergent panels."
		exit
	}
	local mean_phi = `sum_phi' / `n_valid'
	
	local av : word 1 of `asymvars'
	local pv : word 1 of `posvars'
	local nv : word 1 of `negvars'
	capture local beta_p = _b[`ec':`pv']
	capture local beta_n = _b[`ec':`nv']
	
	di in gr "  Variable: " in ye "`av'"
	di in gr "  Mean phi: " in ye %8.4f `mean_phi'
	di
	
	di in smcl in gr "  {hline 68}"
	di in gr %7s "Period" " {c |}" ///
		%13s "Y(+shock)" " {c |}" ///
		%13s "Gap(+)" " {c |}" ///
		%13s "Y(-shock)" " {c |}" ///
		%13s "Gap(-)"
	di in smcl in gr "  {hline 7}{c +}{hline 14}{c +}{hline 14}{c +}{hline 14}{c +}{hline 14}"
	
	* Simulate + shock: unit increase -> y adjusts toward beta_p
	* Simulate - shock: unit decrease -> y adjusts toward beta_n
	local y_pos = 0
	local y_neg = 0
	
	forvalues h = 0/`periods' {
		if `h' == 0 {
			local y_pos = 0
			local y_neg = 0
			local gap_p = `beta_p'
			local gap_n = `beta_n'
		}
		else {
			local adj_p = `mean_phi' * (`y_pos' - `beta_p')
			local y_pos = `y_pos' + `adj_p'
			local gap_p = `beta_p' - `y_pos'
			
			local adj_n = `mean_phi' * (`y_neg' - `beta_n')
			local y_neg = `y_neg' + `adj_n'
			local gap_n = `beta_n' - `y_neg'
		}
		
		di in gr %7.0f `h' " {c |}" ///
			in ye %13.4f `y_pos' " {c |}" ///
			in ye %13.4f `gap_p' " {c |}" ///
			in ye %13.4f `y_neg' " {c |}" ///
			in ye %13.4f `gap_n'
	}
	
	di in smcl in gr "  {hline 7}{c +}{hline 14}{c +}{hline 14}{c +}{hline 14}{c +}{hline 14}"
	
	local hl = ln(2) / abs(`mean_phi')
	di
	di in gr "  {bf:Convergence:}"
	di in gr "    + shock -> Y converges to " in ye %8.4f `beta_p' ///
		in gr " (half-life: " in ye %4.2f `hl' in gr " periods)"
	di in gr "    - shock -> Y converges to " in ye %8.4f `beta_n' ///
		in gr " (half-life: " in ye %4.2f `hl' in gr " periods)"
	di in gr "    Asymmetric gap = " in ye %8.4f abs(`beta_p' - `beta_n')
	di
end


* =========================================================================
* NEW IN 1.1.0: pnardl_PlotECT — ECT bar chart per panel
* =========================================================================

program define pnardl_PlotECT
	syntax, IVar(string) EC(string)
	
	local n_panels = wordcount("$iis")
	
	preserve
	clear
	qui set obs `n_panels'
	qui gen panel_num = _n
	qui gen phi = .
	qui gen color_cat = .
	
	local idx = 0
	foreach i of global iis {
		local idx = `idx' + 1
		local coefname "`ivar'_`i':`ec'"
		capture local coef = _b[`coefname']
		if !_rc {
			qui replace phi = `coef' in `idx'
			if `coef' < -0.5 qui replace color_cat = 1 in `idx'
			else if `coef' < 0 qui replace color_cat = 2 in `idx'
			else qui replace color_cat = 3 in `idx'
		}
	}
	
	qui sum phi
	local mean_phi = r(mean)
	
	#delimit ;
	twoway (bar phi panel_num if color_cat == 1, 
			color("39 174 96%80") lcolor("39 174 96") barwidth(0.7))
		   (bar phi panel_num if color_cat == 2, 
		    color("243 156 18%80") lcolor("243 156 18") barwidth(0.7))
		   (bar phi panel_num if color_cat == 3, 
		    color("231 76 60%80") lcolor("231 76 60") barwidth(0.7)),
		title("{bf:ECT Speed of Adjustment by Panel}", 
			size(large) color(black))
		subtitle("Panel NARDL — PNARDL 1.1.0", size(medsmall) color(gs5))
		ytitle("ECT Coefficient ({&phi}{sub:i})", size(medium))
		xtitle("Panel", size(medium))
		ylabel(, format(%5.2f) angle(0) labsize(small) 
			grid glcolor(gs14) glpattern(dot))
		xlabel(1/`n_panels', labsize(vsmall) angle(45))
		yline(0, lcolor(gs8) lwidth(thin))
		yline(`mean_phi', lcolor("142 68 173") lwidth(medthin) lpattern(dash))
		legend(order(1 "Strong ({&phi} < -0.5)" 
					 2 "Moderate" 3 "Non-convergent") 
			position(6) ring(1) rows(1) size(vsmall)
			region(lcolor(gs14) fcolor(white%90)))
		graphregion(fcolor(white) lcolor(white))
		plotregion(fcolor(white) lcolor(gs14) margin(small))
		name(pnardl_ect, replace) ;
	#delimit cr
	
	di in gr "  {bf:Graph saved:} " in ye "pnardl_ect"
	restore
end


* =========================================================================
* NEW IN 1.1.0: pnardl_PlotAsymLR — LR beta+ vs beta- grouped bar
* =========================================================================

program define pnardl_PlotAsymLR
	syntax, IVar(string) EC(string) POSvars(string) NEGvars(string) ASYMvars(string)
	
	local nasym = wordcount("`asymvars'")
	
	preserve
	clear
	qui set obs `= `nasym' * 2'
	qui gen var_num = .
	qui gen coef = .
	qui gen shock_type = .
	qui gen var_label = ""
	
	local row = 0
	forvalues i = 1/`nasym' {
		local av : word `i' of `asymvars'
		local pv : word `i' of `posvars'
		local nv : word `i' of `negvars'
		
		capture local bp = _b[`ec':`pv']
		capture local bn = _b[`ec':`nv']
		
		if !_rc {
			local row = `row' + 1
			qui replace var_num = `i' - 0.15 in `row'
			qui replace coef = `bp' in `row'
			qui replace shock_type = 1 in `row'
			qui replace var_label = "`av'" in `row'
			
			local row = `row' + 1
			qui replace var_num = `i' + 0.15 in `row'
			qui replace coef = `bn' in `row'
			qui replace shock_type = 2 in `row'
			qui replace var_label = "`av'" in `row'
		}
	}
	
	#delimit ;
	twoway (bar coef var_num if shock_type == 1, 
			color("46 204 113%80") lcolor("39 174 96") barwidth(0.28))
		   (bar coef var_num if shock_type == 2, 
		    color("231 76 60%80") lcolor("192 57 43") barwidth(0.28)),
		title("{bf:Long-Run Asymmetric Coefficients}", 
			size(large) color(black))
		subtitle("{&beta}{sup:+} vs {&beta}{sup:-} — PNARDL 1.1.0", 
			size(medsmall) color(gs5))
		ytitle("Long-Run Coefficient", size(medium))
		xtitle("Variable", size(medium))
		ylabel(, format(%5.3f) angle(0) labsize(small) 
			grid glcolor(gs14) glpattern(dot))
		xlabel(1/`nasym', labsize(small))
		yline(0, lcolor(gs8) lwidth(thin))
		legend(order(1 "{&beta}{sup:+} (Positive)" 
					 2 "{&beta}{sup:-} (Negative)") 
			position(6) ring(1) rows(1) size(small)
			region(lcolor(gs14) fcolor(white%90)))
		graphregion(fcolor(white) lcolor(white))
		plotregion(fcolor(white) lcolor(gs14) margin(small))
		name(pnardl_asym_lr, replace) ;
	#delimit cr
	
	di in gr "  {bf:Graph saved:} " in ye "pnardl_asym_lr"
	restore
end


* =========================================================================
* NEW IN 1.1.0: pnardl_PlotMultiplier — Dynamic multiplier dual-line
* =========================================================================

program define pnardl_PlotMultiplier
	syntax, Periods(integer) IVar(string) EC(string) ///
		POSvars(string) NEGvars(string) ASYMvars(string)
	
	* Get mean ECT
	local sum_phi = 0
	local n_valid = 0
	foreach i of global iis {
		local coefname "`ivar'_`i':`ec'"
		capture local phi = _b[`coefname']
		if !_rc & `phi' < 0 {
			local sum_phi = `sum_phi' + `phi'
			local n_valid = `n_valid' + 1
		}
	}
	if `n_valid' == 0 {
		di in ye "  Cannot plot multiplier: no convergent panels."
		exit
	}
	local mean_phi = `sum_phi' / `n_valid'
	
	local pv : word 1 of `posvars'
	local nv : word 1 of `negvars'
	local av : word 1 of `asymvars'
	capture local beta_p = _b[`ec':`pv']
	capture local beta_n = _b[`ec':`nv']
	if _rc exit
	
	preserve
	clear
	qui set obs `= `periods' + 1'
	qui gen period = _n - 1
	qui gen m_pos = .
	qui gen m_neg = .
	qui gen lr_pos = `beta_p'
	qui gen lr_neg = `beta_n'
	qui gen zero = 0
	
	local gap_p = 1
	local gap_n = -1
	
	forvalues h = 0/`periods' {
		if `h' == 0 {
			qui replace m_pos = 0 in 1
			qui replace m_neg = 0 in 1
		}
		else {
			local adj_p = `mean_phi' * (`gap_p' - `beta_p')
			local adj_n = `mean_phi' * (`gap_n' - `beta_n')
			local gap_p = `gap_p' + `adj_p'
			local gap_n = `gap_n' + `adj_n'
			qui replace m_pos = `gap_p' in `= `h' + 1'
			qui replace m_neg = `gap_n' in `= `h' + 1'
		}
	}
	
	#delimit ;
	twoway (line m_pos period, lcolor("46 204 113") lwidth(medthick))
		   (line m_neg period, lcolor("231 76 60") lwidth(medthick))
		   (line lr_pos period, lcolor("46 204 113") lwidth(thin) lpattern(dash))
		   (line lr_neg period, lcolor("231 76 60") lwidth(thin) lpattern(dash))
		   (line zero period, lcolor(gs10) lwidth(vthin)),
		title("{bf:Cumulative Dynamic Multipliers}", 
			size(large) color(black))
		subtitle("Positive vs Negative Shocks to `av' — PNARDL 1.1.0", 
			size(medsmall) color(gs5))
		ytitle("Cumulative Effect on Y", size(medium))
		xtitle("Periods After Shock", size(medium))
		ylabel(, format(%5.3f) angle(0) labsize(small) 
			grid glcolor(gs14) glpattern(dot))
		xlabel(, labsize(small))
		legend(order(1 "m{sup:+}(h) Positive" 
					 2 "m{sup:-}(h) Negative"
					 3 "{&beta}{sup:+} LR target"
					 4 "{&beta}{sup:-} LR target") 
			position(1) ring(0) cols(2) size(vsmall)
			region(lcolor(gs14) fcolor(white%90)))
		note("Mean ECT = `: di %6.4f `mean_phi''"
			 "{&beta}{sup:+} = `: di %6.4f `beta_p'', {&beta}{sup:-} = `: di %6.4f `beta_n''",
			 size(vsmall) color(gs6))
		graphregion(fcolor(white) lcolor(white))
		plotregion(fcolor(white) lcolor(gs14) margin(small))
		name(pnardl_multiplier, replace) ;
	#delimit cr
	
	di in gr "  {bf:Graph saved:} " in ye "pnardl_multiplier"
	restore
end

