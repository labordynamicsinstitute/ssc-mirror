*! xtgets: Panel General-to-Specific Indicator Saturation
*! Version 1.0.0  14mar2026  Dr Merwan Roudane  merwanroudane920@gmail.com
*! Implements panel GETS indicator saturation for structural break detection
*! Based on Pretis & Schwarz (2022/2026) "Discovering What Mattered"
*! R package: getspanel (Schwarz & Pretis, 2026, CRAN)
*!   - isatpanel() wraps gets::isat() with panel indicator matrices
*!   - Uses gets::sim(), gets::iim(), gets::tim() for indicator generation
*!   - Block-diagonal Matrix::bdiag() for per-unit indicators
*! Original time-series gets.ado by Damian C. Clarke (2013)
*!   - tsort() Mata function for t-statistic elimination
*!   - Multiple search paths (numsearch)
*!   - Misspecification tests (DH, BP, Chow) at each step

capture program drop xtgets
program define xtgets, eclass
	version 15.1
	
	#delimit ;
	syntax varlist(min=2 ts fv) [if] [in] [pweight fweight aweight iweight]
	[,
	EFfect(string)
	IIS
	JIIS
	JSIS
	FESIS
	CSIS
	CFESIS
	TIS
	fesis_id(string)
	fesis_time(string)
	cfesis_id(string)
	cfesis_var(string)
	cfesis_time(string)
	csis_var(string)
	csis_time(string)
	tis_id(string)
	tis_time(string)
	t_pval(real 0.001)
	tlimit(real 0)
	NUMSearch(integer 1)
	vce(string)
	Verbose
	NODIAGnostic
	NOPARTition
	ar(integer 0)
	CLuster(string)
	PLOT
	]
	;
	#delimit cr
	
	* =========================================================================
	* 0. VALIDATION & SETUP  (follows gets.ado structure sections 0-1)
	* =========================================================================
	
	* Check panel structure (requires xtset like gets.ado with xt option)
	qui xtset
	local ivar `r(panelvar)'
	local tvar `r(timevar)'
	if "`ivar'" == "" {
		di as err "panel variable not set; use {bf:xtset panelid timevar}"
		exit 459
	}
	
	* Default effect = twoways (matching R isatpanel default)
	if "`effect'" == "" local effect "twoways"
	if !inlist("`effect'", "twoways", "individual", "time", "none") {
		di as err "effect() must be one of: twoways, individual, time, none"
		exit 198
	}
	
	* t-limit: if not specified, derive from t.pval (matching R default t.pval=0.001)
	if `tlimit' == 0 {
		local tlimit = invnormal(1 - `t_pval'/2)
	}
	
	* Must specify at least one indicator saturation method (as in R isatpanel)
	local any_isat = ("`iis'"!="") + ("`jiis'"!="") + ("`jsis'"!="") + ///
		("`fesis'"!="") + ("`csis'"!="") + ("`cfesis'"!="") + ("`tis'"!="")
	if `any_isat' == 0 {
		di as err "must specify at least one indicator saturation method:"
		di as err "  {bf:iis}, {bf:jiis}, {bf:jsis}, {bf:fesis}, {bf:csis}, {bf:cfesis}, or {bf:tis}"
		exit 198
	}
	
	* Collinearity checks (from R isatpanel lines 142, 347)
	if "`jiis'" != "" & inlist("`effect'", "twoways", "time") {
		di as err "Cannot use {bf:jiis} with time fixed effects (collinear)."
		di as err "Set jiis off or use effect(individual) or effect(none)."
		exit 198
	}
	if "`jsis'" != "" & inlist("`effect'", "twoways", "time") {
		di "{txt}Note: JSIS normally not retained with time FE (collinear)."
	}
	
	* Parse varlist (as in gets.ado lines 81-86)
	marksample touse
	fvexpand `varlist'
	local varlist `r(varlist)'
	tokenize `varlist'
	local depvar `1'
	macro shift
	local xvars `*'
	local numxvars : list sizeof local(xvars)
	
	* Default csis_var and cfesis_var = all regressors (R lines 199-200)
	if "`csis'" != "" & "`csis_var'" == "" local csis_var `xvars'
	if "`cfesis'" != "" & "`cfesis_var'" == "" local cfesis_var `xvars'
	
	* Sample
	qui count if `touse'
	local nobs = r(N)
	
	* Out-of-sample partition (from gets.ado lines 100-114)
	tempvar outofsample
	if "`nopartition'" == "" {
		local Nx `numxvars'
		if `Nx' > round(`nobs'/10) & "`nopartition'" == "" {
			di "{txt}  # of regressors > 10% of sample size. Skipping out-of-sample tests."
			local nopartition yes
		}
	}
	local tenpercent = `nobs' - round(`nobs'/10)
	if "`nopartition'" == "" {
		qui gen `outofsample' = (_n > `tenpercent') if `touse'
	}
	else {
		qui gen `outofsample' = 0 if `touse'
	}
	
	global Fbase
	
	* =========================================================================
	* HEADER DISPLAY
	* =========================================================================
	
	di
	di in smcl in gr "{hline 78}"
	di in gr "{bf:xtgets: Panel GETS Indicator Saturation}" _col(55) "v1.0.0 14mar2026"
	di in gr "{it:Pretis & Schwarz (2022/2026) + Clarke (2013)}"
	di in smcl in gr "{hline 78}"
	di
	di in gr "  Dependent variable:  " in ye "`depvar'"
	di in gr "  Regressors:          " in ye "`xvars'"
	di in gr "  Panel variable:      " in ye "`ivar'"
	di in gr "  Time variable:       " in ye "`tvar'"
	di in gr "  Fixed effects:       " in ye "`effect'"
	di in gr "  t.pval (R):          " in ye %7.4f `t_pval'
	di in gr "  t-limit:             " in ye %6.3f `tlimit'
	di in gr "  Search paths:        " in ye "`numsearch'"
	di
	
	* List active methods (matching R output)
	di in gr "  Active indicator saturation methods:"
	if "`iis'"   != "" di in ye "    - IIS    (Impulse Indicator Saturation)"
	if "`jiis'"  != "" di in ye "    - JIIS   (Joint Impulse Indicators)"
	if "`jsis'"  != "" di in ye "    - JSIS   (Joint Step Indicators)"
	if "`fesis'" != "" di in ye "    - FESIS  (Fixed-Effect Step Indicators)"
	if "`csis'"  != "" di in ye "    - CSIS   (Coefficient Step Indicators)"
	if "`cfesis'"!= "" di in ye "    - CFESIS (Coefficient-FE Step Indicators)"
	if "`tis'"   != "" di in ye "    - TIS    (Trend Indicators)"
	di
	
	* =========================================================================
	* 1. PRESERVE AND PREPARE DATA
	* =========================================================================
	
	preserve
	
	if "`if'`in'" != "" {
		qui keep if `touse'
	}
	
	sort `ivar' `tvar'
	
	qui tab `ivar'
	local N_units = r(r)
	qui tab `tvar'
	local T_periods = r(r)
	
	di in gr "  Panel dimensions:    " in ye "N = `N_units', T = `T_periods'"
	di in gr "  Observations:        " in ye "`nobs'"
	
	* Encode string panel var if needed
	capture confirm numeric variable `ivar'
	if _rc {
		tempvar ivar_num
		encode `ivar', gen(`ivar_num')
		local ivar_orig `ivar'
		local ivar `ivar_num'
	}
	
	* =========================================================================
	* 2. GENERATE FIXED EFFECTS (as in R isatpanel lines 588-610)
	*    Uses dummy_cols in R; we use tab, gen()
	* =========================================================================
	
	di
	di in smcl in gr "{hline 78}"
	di in gr "{bf:Step 1: Generating Fixed Effects}"
	di in smcl in gr "{hline 78}"
	
	local fe_vars ""
	
	if inlist("`effect'", "individual", "twoways") {
		qui tab `ivar', gen(_xtgets_id_)
		qui ds _xtgets_id_*
		local id_dummies `r(varlist)'
		* Drop first dummy (R: remove_first_dummy=FALSE but twoways drops dummies[-1])
		if "`effect'" == "twoways" {
			local first_id : word 1 of `id_dummies'
			drop `first_id'
			qui ds _xtgets_id_*
			local id_dummies `r(varlist)'
		}
		local fe_vars `fe_vars' `id_dummies'
		di in gr "  Generated " in ye `: word count `id_dummies'' in gr " individual FE dummies"
	}
	
	if inlist("`effect'", "time", "twoways") {
		qui tab `tvar', gen(_xtgets_t_)
		qui ds _xtgets_t_*
		local t_dummies `r(varlist)'
		if "`effect'" == "twoways" {
			local first_t : word 1 of `t_dummies'
			drop `first_t'
			qui ds _xtgets_t_*
			local t_dummies `r(varlist)'
		}
		local fe_vars `fe_vars' `t_dummies'
		di in gr "  Generated " in ye `: word count `t_dummies'' in gr " time FE dummies"
	}
	
	* =========================================================================
	* 3. LOAD MATA FUNCTIONS & GENERATE INDICATOR MATRICES
	*    (Replicates R isatpanel lines 330-574: BreakList construction)
	* =========================================================================
	
	di
	di in smcl in gr "{hline 78}"
	di in gr "{bf:Step 2: Generating Indicator Matrices (BreakList)}"
	di in smcl in gr "{hline 78}"
	di
	
	qui findfile xtgets_mata.ado
	qui run "`r(fn)'"
	
	local indicator_vars ""
	local n_indicators = 0
	
	* --- IIS (R lines: block-diagonal iim) ---
	if "`iis'" != "" {
		mata: xtgets_gen_iis("`ivar'", "`tvar'", "_iis_", "`touse'")
		cap qui ds _iis_*
		if !_rc {
			local iis_vars `r(varlist)'
			local indicator_vars `indicator_vars' `iis_vars'
			local n_iis : word count `iis_vars'
			local n_indicators = `n_indicators' + `n_iis'
		}
	}
	
	* --- JIIS (R lines 351-365) ---
	if "`jiis'" != "" {
		mata: xtgets_gen_jiis("`ivar'", "`tvar'", "_jiis_", "`touse'")
		cap qui ds _jiis_*
		if !_rc {
			local jiis_vars `r(varlist)'
			local indicator_vars `indicator_vars' `jiis_vars'
			local n_jiis : word count `jiis_vars'
			local n_indicators = `n_indicators' + `n_jiis'
		}
	}
	
	* --- JSIS (R lines 332-348) ---
	if "`jsis'" != "" {
		mata: xtgets_gen_jsis("`ivar'", "`tvar'", "_jsis_", "`touse'")
		cap qui ds _jsis_*
		if !_rc {
			local jsis_vars `r(varlist)'
			local indicator_vars `indicator_vars' `jsis_vars'
			local n_jsis : word count `jsis_vars'
			local n_indicators = `n_indicators' + `n_jsis'
		}
	}
	
	* --- FESIS (R lines 368-421: block-diagonal sim) ---
	if "`fesis'" != "" {
		mata: xtgets_gen_fesis("`ivar'", "`tvar'", "_fesis_", "`touse'")
		cap qui ds _fesis_*
		if !_rc {
			local fesis_vars `r(varlist)'
			local indicator_vars `indicator_vars' `fesis_vars'
			local n_fesis : word count `fesis_vars'
			local n_indicators = `n_indicators' + `n_fesis'
		}
	}
	
	* --- CSIS (R lines 424-452) ---
	if "`csis'" != "" {
		di in gr "  CSIS variables: `csis_var'"
		mata: xtgets_gen_csis("`ivar'", "`tvar'", "`csis_var'", "_csis_", "`touse'")
		cap qui ds _csis_*
		if !_rc {
			local csis_vars `r(varlist)'
			local indicator_vars `indicator_vars' `csis_vars'
			local n_csis : word count `csis_vars'
			local n_indicators = `n_indicators' + `n_csis'
		}
	}
	
	* --- CFESIS (R lines 455-512) ---
	if "`cfesis'" != "" {
		di in gr "  CFESIS variables: `cfesis_var'"
		mata: xtgets_gen_cfesis("`ivar'", "`tvar'", "`cfesis_var'", "_cfesis_", "`touse'")
		cap qui ds _cfesis_*
		if !_rc {
			local cfesis_vars `r(varlist)'
			local indicator_vars `indicator_vars' `cfesis_vars'
			local n_cfesis : word count `cfesis_vars'
			local n_indicators = `n_indicators' + `n_cfesis'
		}
	}
	
	* --- TIS (R lines 515-567) ---
	if "`tis'" != "" {
		mata: xtgets_gen_tis("`ivar'", "`tvar'", "_tis_", "`touse'")
		cap qui ds _tis_*
		if !_rc {
			local tis_vars `r(varlist)'
			local indicator_vars `indicator_vars' `tis_vars'
			local n_tis : word count `tis_vars'
			local n_indicators = `n_indicators' + `n_tis'
		}
	}
	
	di
	di in gr "  Total candidate indicators (BreakList): " in ye "`n_indicators'"
	di
	
	* =========================================================================
	* 4. TWO-STAGE GETS SELECTION
	*    Stage 1: Structural indicators (FESIS/CSIS/CFESIS/TIS/JSIS) first
	*    Stage 2: Outlier indicators (IIS/JIIS) conditional on retained step
	*    This prevents IIS from absorbing structural breaks that FESIS
	*    should capture as parsimonious step-shifts.
	*    Selection uses direct name scanning (fixes tsort position-mapping bug)
	* =========================================================================
	
	di in smcl in gr "{hline 78}"
	di in gr "{bf:Step 3: Two-Stage GETS Selection}"
	di in smcl in gr "{hline 78}"
	di
	di in gr "  Selection threshold: |t| >= " in ye %6.3f `tlimit'
	di in gr "  (equiv. t.pval = " in ye %7.5f `t_pval' in gr ")"
	di in gr "  Search paths: `numsearch'"
	di
	
	local k_base : word count `xvars' `fe_vars'
	local max_block = max(1, floor(`nobs' * 0.5) - `k_base' - 2)
	
	if "`verbose'" != "" {
		di in gr "  Base regressors (x + FE): `k_base'"
		di in gr "  Max indicators per block: `max_block'"
		di
	}
	
	* -------------------------------------------------------------------------
	* STAGE 1: Select structural indicators (more parsimonious)
	* Process FESIS, JSIS, CSIS, CFESIS, TIS first
	* -------------------------------------------------------------------------
	
	local struct_vars ""
	* Collect structural indicator variables
	cap qui ds _fesis_*
	if !_rc local struct_vars `struct_vars' `r(varlist)'
	cap qui ds _jsis_*
	if !_rc local struct_vars `struct_vars' `r(varlist)'
	cap qui ds _csis_*
	if !_rc local struct_vars `struct_vars' `r(varlist)'
	cap qui ds _cfesis_*
	if !_rc local struct_vars `struct_vars' `r(varlist)'
	cap qui ds _tis_*
	if !_rc local struct_vars `struct_vars' `r(varlist)'
	
	local n_struct : word count `struct_vars'
	
	* Collect outlier indicator variables
	local outlier_vars ""
	cap qui ds _iis_*
	if !_rc local outlier_vars `outlier_vars' `r(varlist)'
	cap qui ds _jiis_*
	if !_rc local outlier_vars `outlier_vars' `r(varlist)'
	
	local n_outlier : word count `outlier_vars'
	
	local retained_struct ""
	local retained_outlier ""
	local n_ret_struct = 0
	local n_ret_outlier = 0
	
	* --- Stage 1a: Individual screen structural indicators ---
	* Test each indicator ONE-AT-A-TIME against base model
	* (Fixes multicollinearity: 24 overlapping FESIS per unit in one block
	*  makes individual steps insignificant. Individual testing avoids this.)
	if `n_struct' > 0 {
		di in gr "  {bf:Stage 1: Structural break indicators}"
		di in gr "  Candidates: `n_struct' (FESIS/JSIS/CSIS/CFESIS/TIS)"
		di in gr "  Screening method: individual t-test against base model"
		
		local n_screened = 0
		foreach ind of local struct_vars {
			local ++n_screened
			
			local all_rhs `xvars' `fe_vars' `ind'
			cap qui reg `depvar' `all_rhs' if `outofsample'==0 [`weight' `exp'], `=cond("`vce'"!="","vce(`vce')","")'
			
			if _rc != 0 continue
			
			cap local tstat = abs(_b[`ind'] / _se[`ind'])
			if _rc == 0 & `tstat' != . {
				if `tstat' >= `tlimit' {
					local retained_struct `retained_struct' `ind'
					if "`verbose'" != "" {
						di in gr "    " in ye "`ind'" in gr " |t|=" in ye %6.2f `tstat' in gr " -> retained"
					}
				}
			}
		}
		
		local n_ret_struct : word count `retained_struct'
		di in gr "    Screened `n_screened' indicators, " in ye "`n_ret_struct'" in gr " passed |t|>=`tlimit'"
		
		* --- Stage 1b: Joint refinement ---
		* All individually-significant indicators in one regression,
		* then iteratively remove least significant until all pass
		if `n_ret_struct' > 1 {
			di in gr "    Joint refinement of `n_ret_struct' candidates..."
			
			local changed = 1
			local iter = 0
			local max_iter = 500
			
			while `changed' & `iter' < `max_iter' {
				local ++iter
				local changed = 0
				
				local n_cur : word count `retained_struct'
				if `n_cur' == 0 continue, break
				
				local all_rhs `xvars' `fe_vars' `retained_struct'
				cap qui reg `depvar' `all_rhs' if `outofsample'==0 [`weight' `exp'], `=cond("`vce'"!="","vce(`vce')","")'
				if _rc != 0 continue, break
				
				* Find least significant indicator by name scanning
				local min_t = .
				local min_var ""
				foreach ind of local retained_struct {
					cap local tstat = abs(_b[`ind'] / _se[`ind'])
					if _rc == 0 & `tstat' != . {
						if `tstat' < `min_t' {
							local min_t = `tstat'
							local min_var `ind'
						}
					}
				}
				
				if `min_t' < `tlimit' & "`min_var'" != "" {
					local retained_struct : list retained_struct - min_var
					local changed = 1
					if "`verbose'" != "" {
						di in gr "      Iter `iter': drop " in ye "`min_var'" ///
							in gr " (|t|=" in ye %5.2f `min_t' in gr ")"
					}
				}
			}
			
			local n_ret_struct : word count `retained_struct'
			di in gr "    After joint refinement: " in ye "`n_ret_struct'" in gr " structural retained"
		}
	}
	
	* -------------------------------------------------------------------------
	* STAGE 2: Select outlier indicators (IIS/JIIS)
	* Conditional on retained structural indicators in the base model
	* Also uses individual screening to avoid IIS multicollinearity
	* -------------------------------------------------------------------------
	
	if `n_outlier' > 0 {
		di
		di in gr "  {bf:Stage 2: Outlier indicators (conditional on Stage 1)}"
		di in gr "  Candidates: `n_outlier' (IIS/JIIS)"
		di in gr "  Base model includes `n_ret_struct' structural indicators"
		
		* Base model = xvars + FE + retained structural indicators
		local base_stage2 `xvars' `fe_vars' `retained_struct'
		
		* Individual screen each outlier indicator
		local n_screened = 0
		foreach ind of local outlier_vars {
			local ++n_screened
			
			local all_rhs `base_stage2' `ind'
			cap qui reg `depvar' `all_rhs' if `outofsample'==0 [`weight' `exp'], `=cond("`vce'"!="","vce(`vce')","")'
			
			if _rc != 0 continue
			
			cap local tstat = abs(_b[`ind'] / _se[`ind'])
			if _rc == 0 & `tstat' != . {
				if `tstat' >= `tlimit' {
					local retained_outlier `retained_outlier' `ind'
				}
			}
		}
		
		local n_ret_outlier : word count `retained_outlier'
		di in gr "    Screened `n_screened' indicators, " in ye "`n_ret_outlier'" in gr " passed"
		
		* --- Stage 2b: Joint refinement ---
		if `n_ret_outlier' > 1 {
			di in gr "    Joint refinement of `n_ret_outlier' candidates..."
			
			local changed = 1
			local iter = 0
			local max_iter = 500
			
			while `changed' & `iter' < `max_iter' {
				local ++iter
				local changed = 0
				
				local n_cur : word count `retained_outlier'
				if `n_cur' == 0 continue, break
				
				local all_rhs `base_stage2' `retained_outlier'
				cap qui reg `depvar' `all_rhs' if `outofsample'==0 [`weight' `exp'], `=cond("`vce'"!="","vce(`vce')","")'
				if _rc != 0 continue, break
				
				local min_t = .
				local min_var ""
				foreach ind of local retained_outlier {
					cap local tstat = abs(_b[`ind'] / _se[`ind'])
					if _rc == 0 & `tstat' != . {
						if `tstat' < `min_t' {
							local min_t = `tstat'
							local min_var `ind'
						}
					}
				}
				
				if `min_t' < `tlimit' & "`min_var'" != "" {
					local retained_outlier : list retained_outlier - min_var
					local changed = 1
					if "`verbose'" != "" {
						di in gr "      Iter `iter': drop " in ye "`min_var'" ///
							in gr " (|t|=" in ye %5.2f `min_t' in gr ")"
					}
				}
			}
			
			local n_ret_outlier : word count `retained_outlier'
			di in gr "    After joint refinement: " in ye "`n_ret_outlier'" in gr " outlier retained"
		}
	}
	
	* -------------------------------------------------------------------------
	* Combine Stage 1 + Stage 2 retained indicators
	* -------------------------------------------------------------------------
	
	local retained_indicators `retained_struct' `retained_outlier'
	local n_retained : word count `retained_indicators'
	
	di
	di in gr "  {bf:Total retained: " in ye "`n_retained'" in gr " indicators}"
	if `n_ret_struct' > 0 di in gr "    Structural (FESIS/CSIS/CFESIS/TIS/JSIS): `n_ret_struct'"
	if `n_ret_outlier' > 0 di in gr "    Outlier (IIS/JIIS): `n_ret_outlier'"
	
	* =========================================================================
	* 5. FINAL MODEL ESTIMATION (gets.ado section 5)
	* =========================================================================
	
	di
	di in smcl in gr "{hline 78}"
	di in gr "{bf:Step 4: Final Model Estimation}"
	di in smcl in gr "{hline 78}"
	di
	
	* -------------------------------------------------------------------------
	* Rename variables to R-style labels for clean output
	* _xtgets_id_K  -> idK       (R: idBelgium, etc.)
	* _xtgets_t_K   -> timeYEAR  (R: time1971)
	* _fesis_I_Y    -> fesisI.Y  (R: fesisFrance.1988)
	* _iis_I_Y      -> iisI.Y    (R: iis)
	* _csis_V_Y     -> csisV.Y   (R: csis)
	* _tis_I_Y      -> tisI.Y    (R: tis)
	* _jsis_Y       -> jsisY     (R: jsis)
	* _jiis_Y       -> jiisY     (R: jiis)
	* _cfesis_V_I_Y -> cfesisV.I.Y
	* -------------------------------------------------------------------------
	
	* Rename individual FE dummies
	cap qui ds _xtgets_id_*
	if !_rc {
		foreach v of varlist _xtgets_id_* {
			local k = substr("`v'", 12, .)
			* Map K-th dummy to actual unit value
			* tab, gen() numbers dummies by level position: _xtgets_id_K -> Kth level
			qui levelsof `ivar', local(uvals)
			local uval : word `k' of `uvals'
			cap rename `v' id`uval'
		}
		* Update fe_vars list
		local new_fe ""
		foreach v of local fe_vars {
			if substr("`v'", 1, 11) == "_xtgets_id_" {
				local k = substr("`v'", 12, .)
				qui levelsof `ivar', local(uvals)
				local uval : word `k' of `uvals'
				local new_fe `new_fe' id`uval'
			}
			else {
				local new_fe `new_fe' `v'
			}
		}
		local fe_vars `new_fe'
	}
	
	* Rename time FE dummies
	cap qui ds _xtgets_t_*
	if !_rc {
		foreach v of varlist _xtgets_t_* {
			local k = substr("`v'", 11, .)
			* Map K-th dummy to actual time value
			* tab, gen() numbers dummies by level position: _xtgets_t_K -> Kth level
			qui levelsof `tvar', local(tvals)
			local tval : word `k' of `tvals'
			cap rename `v' time`tval'
		}
		local new_fe ""
		foreach v of local fe_vars {
			if substr("`v'", 1, 10) == "_xtgets_t_" {
				local k = substr("`v'", 11, .)
				qui levelsof `tvar', local(tvals)
				local tval : word `k' of `tvals'
				local new_fe `new_fe' time`tval'
			}
			else {
				local new_fe `new_fe' `v'
			}
		}
		local fe_vars `new_fe'
	}
	
	* Rename retained indicators to R-style
	local new_retained ""
	foreach v of local retained_indicators {
		local newname "`v'"
		
		* _fesis_I_Y -> fesisI.Y
		if substr("`v'", 1, 7) == "_fesis_" {
			local rest = substr("`v'", 8, .)
			local pos = strpos("`rest'", "_")
			local uid = substr("`rest'", 1, `pos'-1)
			local yr  = substr("`rest'", `pos'+1, .)
			local newname "fesis`uid'.`yr'"
		}
		* _iis_I_Y -> iisI.Y
		else if substr("`v'", 1, 5) == "_iis_" {
			local rest = substr("`v'", 6, .)
			local pos = strpos("`rest'", "_")
			local uid = substr("`rest'", 1, `pos'-1)
			local yr  = substr("`rest'", `pos'+1, .)
			local newname "iis`uid'.`yr'"
		}
		* _csis_V_Y -> csisV.Y
		else if substr("`v'", 1, 6) == "_csis_" {
			local rest = substr("`v'", 7, .)
			local lpos = 0
			forvalues pp = 1/50 {
				if substr("`rest'", `pp', 1) == "_" local lpos = `pp'
			}
			local cvar = substr("`rest'", 1, `lpos'-1)
			local yr   = substr("`rest'", `lpos'+1, .)
			local newname "csis.`cvar'.`yr'"
		}
		* _tis_I_Y -> tisI.Y
		else if substr("`v'", 1, 5) == "_tis_" {
			local rest = substr("`v'", 6, .)
			local pos = strpos("`rest'", "_")
			local uid = substr("`rest'", 1, `pos'-1)
			local yr  = substr("`rest'", `pos'+1, .)
			local newname "tis`uid'.`yr'"
		}
		* _jsis_Y -> jsisY
		else if substr("`v'", 1, 6) == "_jsis_" {
			local yr = substr("`v'", 7, .)
			local newname "jsis.`yr'"
		}
		* _jiis_Y -> jiisY 
		else if substr("`v'", 1, 6) == "_jiis_" {
			local yr = substr("`v'", 7, .)
			local newname "jiis.`yr'"
		}
		* _cfesis_V_I_Y -> cfesisV.I.Y
		else if substr("`v'", 1, 8) == "_cfesis_" {
			local rest = substr("`v'", 9, .)
			local newname "cfesis.`rest'"
		}
		
		* Rename the variable
		if "`newname'" != "`v'" {
			* Stata var names can't have dots — use underscores
			* But we want dots in display. Use variable LABELS instead.
			cap label variable `v' "`newname'"
		}
		local new_retained `new_retained' `v'
	}
	local retained_indicators `new_retained'
	
	local final_rhs `xvars' `fe_vars' `retained_indicators'
	
	if "`vce'" != "" {
		reg `depvar' `final_rhs' [`weight' `exp'], vce(`vce')
	}
	else {
		reg `depvar' `final_rhs' [`weight' `exp']
	}
	
	* =========================================================================
	* 6. DISPLAY RETAINED INDICATORS (matching R output style)
	*    R output shows: fesisUnit.Year  coef  std.error  t-stat  p-value  ***
	* =========================================================================
	
	di
	di in smcl in gr "{hline 78}"
	di in gr "{bf:Detected Structural Breaks (Retained Indicators)}"
	di in smcl in gr "{hline 78}"
	di
	
	if `n_retained' == 0 {
		di in gr "  No indicators retained. No structural breaks detected."
	}
	else {
		* Display header matching R output style
		di in gr "  SPECIFIC mean equation:"
		di in smcl in gr "  {hline 72}"
		di in gr %25s "Indicator" " {c |}" ///
			%12s "Coef" ///
			%12s "Std.Err" ///
			%10s "t-stat" ///
			%12s "p-value" ///
			%5s ""
		di in smcl in gr "  {hline 25}{c +}{hline 47}"
		
		local n_fesis_ret = 0
		local n_iis_ret = 0
		local n_csis_ret = 0
		local n_cfesis_ret = 0
		local n_tis_ret = 0
		local n_jsis_ret = 0
		local n_jiis_ret = 0
		
		foreach ind of local retained_indicators {
			cap local coef = _b[`ind']
			cap local se_val = _se[`ind']
			if _rc != 0 continue
			local tstat = `coef' / `se_val'
			local pval = 2 * (1 - normal(abs(`tstat')))
			
			* Significance stars (R style)
			local stars ""
			if `pval' < 0.001 local stars "***"
			else if `pval' < 0.01 local stars " **"
			else if `pval' < 0.05 local stars "  *"
			else if `pval' < 0.10 local stars "  ."
			
			* Count by type
			if substr("`ind'", 1, 7) == "_fesis_" local ++n_fesis_ret
			else if substr("`ind'", 1, 5) == "_iis_" local ++n_iis_ret
			else if substr("`ind'", 1, 6) == "_csis_" local ++n_csis_ret
			else if substr("`ind'", 1, 8) == "_cfesis_" local ++n_cfesis_ret
			else if substr("`ind'", 1, 5) == "_tis_" local ++n_tis_ret
			else if substr("`ind'", 1, 6) == "_jsis_" local ++n_jsis_ret
			else if substr("`ind'", 1, 6) == "_jiis_" local ++n_jiis_ret
			
			* R-style display name from variable label
			local disp_name : variable label `ind'
			if "`disp_name'" == "" local disp_name "`ind'"
			
			di in ye %25s "`disp_name'" " {c |}" ///
				in ye %12.4f `coef' ///
				in ye %12.4f `se_val' ///
				in ye %10.4f `tstat' ///
				in ye %12.6f `pval' ///
				in ye " `stars'"
		}
		
		di in smcl in gr "  {hline 25}{c +}{hline 47}"
		di in gr "  Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1"
		di
		
		* Summary
		di in gr "  Retained indicators:"
		if `n_fesis_ret' > 0  di in ye "    FESIS:  `n_fesis_ret'"
		if `n_iis_ret' > 0    di in ye "    IIS:    `n_iis_ret'"
		if `n_csis_ret' > 0   di in ye "    CSIS:   `n_csis_ret'"
		if `n_cfesis_ret' > 0 di in ye "    CFESIS: `n_cfesis_ret'"
		if `n_tis_ret' > 0    di in ye "    TIS:    `n_tis_ret'"
		if `n_jsis_ret' > 0   di in ye "    JSIS:   `n_jsis_ret'"
		if `n_jiis_ret' > 0   di in ye "    JIIS:   `n_jiis_ret'"
		
		* Interpretation notes for beginners
		di
		di in smcl in gr "  {hline 72}"
		di in gr "  {bf:Interpretation Notes (Pretis & Schwarz, 2022):}"
		di in smcl in gr "  {hline 72}"
		if `n_fesis_ret' > 0 {
			di in gr "  {bf:FESIS} (Fixed-Effect Step Indicator Saturation):"
			di in gr "    Detects permanent level shifts in a unit's intercept."
			di in gr "    A retained fesisI.Y with coef {it:tau} means unit I"
			di in gr "    experienced a permanent shift of {it:tau} starting at year Y."
			di in gr "    Positive = increase, Negative = decrease in `depvar'."
			di in gr "    Analogous to a staggered diff-in-diff treatment effect."
			di
		}
		if `n_iis_ret' > 0 {
			di in gr "  {bf:IIS} (Impulse Indicator Saturation):"
			di in gr "    Detects one-time outliers for a specific unit-time."
			di in gr "    A retained iisI.Y means unit I had an unusual value"
			di in gr "    at year Y (e.g. crisis, measurement error, shock)."
			di in gr "    The coefficient is the outlier magnitude."
			di
		}
		if `n_csis_ret' > 0 {
			di in gr "  {bf:CSIS} (Coefficient Step Indicator Saturation):"
			di in gr "    Detects structural change in slope coefficients."
			di in gr "    A retained csis.X.Y means the effect of variable X"
			di in gr "    on `depvar' changed at year Y for ALL units."
			di in gr "    The coefficient is the change in the slope of X."
			di
		}
		if `n_cfesis_ret' > 0 {
			di in gr "  {bf:CFESIS} (Coefficient-FE Step Indicator Saturation):"
			di in gr "    Detects unit-specific structural change in slopes."
			di in gr "    Like CSIS, but the slope change is unit-specific."
			di
		}
		if `n_tis_ret' > 0 {
			di in gr "  {bf:TIS} (Trend Indicator Saturation):"
			di in gr "    Detects broken linear trends for units from a date."
			di in gr "    A retained tisI.Y means unit I has a linear trend"
			di in gr "    change starting at year Y."
			di
		}
		if `n_jsis_ret' > 0 {
			di in gr "  {bf:JSIS} (Joint Step Indicator Saturation):"
			di in gr "    Detects common structural breaks affecting ALL units."
			di in gr "    A retained jsis.Y means all units experienced a"
			di in gr "    common level shift at year Y."
			di
		}
		if `n_jiis_ret' > 0 {
			di in gr "  {bf:JIIS} (Joint Impulse Indicator Saturation):"
			di in gr "    Detects common outliers affecting all units at once."
			di in gr "    Equivalent to time fixed effect selection."
			di
		}
	}
	
	* =========================================================================
	* 7. DIAGNOSTICS AND FIT (matching R output)
	* =========================================================================
	
	if "`nodiagnostic'" == "" {
		di
		di in smcl in gr "{hline 78}"
		di in gr "{bf:Diagnostics and Fit}"
		di in smcl in gr "{hline 78}"
		di
		
		local r2 = e(r2)
		local r2_a = e(r2_a)
		local rmse = e(rmse)
		local ll = e(ll)
		
		di in gr "  SE of regression:    " in ye %12.5f `rmse'
		di in gr "  R-squared:           " in ye %12.6f `r2'
		di in gr "  Log-lik.(n=`nobs'):" _col(29) in ye %12.5f `ll'
		
		* False discovery rate (from paper eq. 36-43)
		local gamma_c = 2 * (1 - normal(`tlimit'))
		local expected_false = `gamma_c' * `n_indicators'
		local p_unit_false = 1 - (1 - `gamma_c')^(`T_periods' - 1)
		
		di
		di in gr "  {bf:False Discovery Rate (Pretis & Schwarz, 2026):}"
		di in gr "    gamma_c (eq.36):                " in ye %9.6f `gamma_c'
		di in gr "    Total candidate indicators:     " in ye "`n_indicators'"
		di in gr "    E[spurious retained] (eq.37):   " in ye %5.1f `expected_false'
		di in gr "    P(unit falsely treated) (eq.45):" in ye %7.4f `p_unit_false'
		di in gr "    Retained indicators:            " in ye "`n_retained'"
	}
	
	* =========================================================================
	* 8. STORE RESULTS (eclass)
	* =========================================================================
	
	ereturn local cmd "xtgets"
	ereturn local effect "`effect'"
	ereturn local depvar "`depvar'"
	ereturn local xvars "`xvars'"
	ereturn local ivar "`ivar'"
	ereturn local tvar "`tvar'"
	ereturn local retained "`retained_indicators'"
	ereturn scalar n_indicators = `n_indicators'
	ereturn scalar n_retained = `n_retained'
	ereturn scalar tlimit = `tlimit'
	ereturn scalar t_pval = `t_pval'
	ereturn scalar gamma_c = `gamma_c'
	ereturn scalar N_units = `N_units'
	ereturn scalar T_periods = `T_periods'
	
	if "`iis'"   != "" ereturn local iis "yes"
	if "`jiis'"  != "" ereturn local jiis "yes"
	if "`jsis'"  != "" ereturn local jsis "yes"
	if "`fesis'" != "" ereturn local fesis "yes"
	if "`csis'"  != "" ereturn local csis "yes"
	if "`cfesis'"!= "" ereturn local cfesis "yes"
	if "`tis'"   != "" ereturn local tis "yes"
	
	di
	di in smcl in gr "{hline 78}"
	di in gr "Note: {bf:ereturn list} for stored results."
	di in gr "      {bf:e(retained)} lists retained indicator variable names."
	di in smcl in gr "{hline 78}"
	di
	
	restore
	
end
