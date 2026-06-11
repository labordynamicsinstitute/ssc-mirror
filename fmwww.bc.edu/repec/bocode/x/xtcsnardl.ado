*! xtcsnardl v1.0.0  28may2026  Dr Merwan Roudane  merwanroudane920@gmail.com
*! Cross-Sectionally Augmented Panel Nonlinear ARDL (CS-NARDL)
*! ---------------------------------------------------------------------------
*! Methodological foundations:
*!   Shin, Yu & Greenwood-Nimmo (2014)   -- NARDL asymmetric decomposition
*!   Pesaran (2006, Econometrica)         -- CCE / CCE-MG
*!   Chudik & Pesaran (2015, JoE)         -- CS-DL, p_T = floor(T^{1/3}) lags
*!   Kapetanios, Mitchell & Shin (2014)   -- Nonlinear panel CSD
*!   Hacioglu-Hoke & Kapetanios (2020 JAE / BoE WP 683)
*!                                       -- CCE for nonlinear conditional mean
*!   Mehta & Derbeneva (2024 Int.J.Therm.)-- CS-NARDL EURO-4 application
*!   Wang, Huang, Ghafoor et al. (2022)   -- CS-NARDL BRICS REC application
*! Requires: xtpmg (>= 2.0.1), pnardl (>= 1.1.0)
*! ---------------------------------------------------------------------------

capture program drop xtcsnardl
program define xtcsnardl, eclass
	version 15.1

	if replay() {
		if ("`e(cmd)'" != "xtcsnardl") error 301
		_xtcsnardl_replay `0'
		exit
	}

	syntax varlist(ts min=2) [if] [in],                                   ///
		LR(varlist ts)                                                     ///
		ASYMmetric(varlist)                                                ///
		[                                                                  ///
		EC(name)                                                           ///
		REPLACE                                                            ///
		MG DFE PMG                                                         ///
		ENGine(string)                                                     ///
		POOLed(varlist ts)                                                 ///
		RECursive                                                          ///
		JACKknife                                                          ///
		LR_options(string)                                                 ///
		FULL                                                               ///
		Level(integer `c(level)')                                          ///
		TECHnique(passthru)                                                ///
		DIFficult                                                          ///
		CONSTraints(numlist)                                               ///
		noCONStant                                                         ///
		CLUster(passthru)                                                  ///
		CR_lags(integer -1)                                                ///
		CSAvars(varlist)                                                   ///
		NOCSA                                                              ///
		HAUSman                                                            ///
		NOASYMtest                                                         ///
		ASYTable                                                           ///
		PANELcoef                                                          ///
		MULTip(integer 0)                                                  ///
		IRFShock(integer 0)                                                ///
		SHOWCsa                                                            ///
		KEEPCsa                                                            ///
		NOCDtest                                                           ///
		GRaph                                                              ///
		NOTABle                                                            ///
		]

	* =========================================================================
	* 0. VALIDATION & DEPENDENCIES
	* =========================================================================

	capture which xtpmg
	if _rc {
		di as err "{bf:xtcsnardl} requires {bf:xtpmg} (v2.0.1+)."
		di as err "Install with: {stata ssc install xtpmg, replace}"
		exit 199
	}

	qui tsset
	local ivar `r(panelvar)'
	local tvar `r(timevar)'
	if "`ivar'" == "" {
		di as err "panel variable not set; use {bf:xtset panelid timevar}"
		exit 459
	}

	if ("`mg'" != "") + ("`dfe'" != "") + ("`pmg'" != "") > 1 {
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

	* ---------- ENGINE DISPATCH ----------
	* engine() routes to xtdcce2 (Ditzen) for the dynamic CCE / CS-ARDL /
	* CS-DL / static CCE estimators of Pesaran (2006) and Chudik-Pesaran (2015).
	* engine() omitted (or pmg/mg/dfe) uses the classical xtpmg ECM path.
	if "`engine'" == "" local engine "`modelopt'"
	local engine = strlower("`engine'")
	if !inlist("`engine'", "pmg", "mg", "dfe", "csardl", "csdl", "dcce", "cce") {
		di as err "engine() must be one of: pmg, mg, dfe, csardl, csdl, dcce, cce"
		exit 198
	}
	local use_dcce = inlist("`engine'", "csardl", "csdl", "dcce", "cce")

	if `use_dcce' {
		capture which xtdcce2
		if _rc {
			di as err "engine(`engine') requires {bf:xtdcce2} (Ditzen)."
			di as err "Install with: {stata ssc install xtdcce2, replace}"
			exit 199
		}
	}

	if "`ec'" == "" local ec "ECT"

	if `multip'   < 0 | `multip'   > 60 {
		di as err "multip() must be between 0 and 60" ; exit 198
	}
	if `irfshock' < 0 | `irfshock' > 60 {
		di as err "irfshock() must be between 0 and 60" ; exit 198
	}

	marksample touse
	qui count if `touse'
	local nobs = r(N)
	qui levelsof `ivar' if `touse', local(ids)
	local npanels : word count `ids'
	local avg_T = round(`nobs' / `npanels')

	* Chudik-Pesaran default lag rule p_T = floor(T^{1/3})
	if `cr_lags' < 0 {
		local cr_lags = floor(`avg_T'^(1/3))
	}

	* =========================================================================
	* 1. HEADER
	* =========================================================================

	di
	di in smcl in gr "{hline 78}"
	di in smcl in gr "  {bf:CS-NARDL}" _col(45) in ye "xtcsnardl v1.0.0"
	di in smcl in gr "  Cross-Sectionally Augmented Panel Nonlinear ARDL"
	di in smcl in gr "  Shin-Yu-Greenwood-Nimmo (2014) {c |} Chudik-Pesaran (2015)"
	di in smcl in gr "  Kapetanios-Mitchell-Shin (2014) {c |} Hacioglu-Hoke & Kapetanios (2020)"
	di in smcl in gr "{hline 78}"

	* =========================================================================
	* 2. ASYMMETRIC DECOMPOSITION  (positive / negative partial sums)
	*    Per Shin, Yu & Greenwood-Nimmo (2014):
	*      x+_it = sum_{s<=t} max(Dx_is, 0)
	*      x-_it = sum_{s<=t} min(Dx_is, 0)
	* =========================================================================

	local asym_vars_display ""
	local pos_vars ""
	local neg_vars ""
	local generated_vars ""

	foreach v of local asymmetric {
		local posname "`v'_pos"
		local negname "`v'_neg"

		if "`replace'" != "" {
			capture drop `posname'
			capture drop `negname'
		}

		capture confirm variable `posname'
		if !_rc {
			di as err "variable {bf:`posname'} already exists; use {bf:replace}."
			exit 110
		}
		capture confirm variable `negname'
		if !_rc {
			di as err "variable {bf:`negname'} already exists; use {bf:replace}."
			exit 110
		}

		tempvar dv dvpos dvneg
		qui gen double `dv'    = d.`v' if `touse'
		qui gen double `dvpos' = max(`dv', 0) if `touse'
		qui gen double `dvneg' = min(`dv', 0) if `touse'
		qui replace `dvpos' = 0 if `dvpos' == . & `touse'
		qui replace `dvneg' = 0 if `dvneg' == . & `touse'

		sort `ivar' `tvar'
		qui by `ivar': gen double `posname' = sum(`dvpos') if `touse'
		qui by `ivar': gen double `negname' = sum(`dvneg') if `touse'

		label variable `posname' "Positive partial sum of `v' (Shin-Yu-Greenwood-Nimmo)"
		label variable `negname' "Negative partial sum of `v' (Shin-Yu-Greenwood-Nimmo)"

		di in gr "  {bf:NARDL decomposition:} " in ye "`v'" in gr ///
			" -> " in ye "`posname'" in gr "(+), " in ye "`negname'" in gr "(-)"

		local asym_vars_display "`asym_vars_display' `v'"
		local pos_vars          "`pos_vars' `posname'"
		local neg_vars          "`neg_vars' `negname'"
		local generated_vars    "`generated_vars' `posname' `negname'"
	}

	* =========================================================================
	* 3. BUILD AUGMENTED SR / LR VARIABLE LISTS
	* =========================================================================

	tokenize `varlist'
	local depvar `1'
	macro shift
	local sr_others `*'

	tokenize `lr'
	local lr_dep `1'
	macro shift
	local lr_others `*'

	* SR: substitute asymmetric variables with d.x_pos d.x_neg
	local new_sr ""
	foreach v of local sr_others {
		local vbase "`v'"
		foreach op in "D1." "D." "d1." "d." "L1." "L." "l1." "l." {
			local vbase : subinstr local vbase "`op'" ""
		}
		local is_asym 0
		local idx 0
		foreach a of local asymmetric {
			local idx = `idx' + 1
			if "`vbase'" == "`a'" {
				local is_asym 1
				local pv : word `idx' of `pos_vars'
				local nv : word `idx' of `neg_vars'
				local new_sr "`new_sr' d.`pv' d.`nv'"
			}
		}
		if !`is_asym' local new_sr "`new_sr' `v'"
	}

	* LR: substitute asymmetric vars with x_pos x_neg in cointegrating vector
	local new_lr_x ""
	local lr_x_substantive ""
	foreach v of local lr_others {
		local is_asym 0
		local idx 0
		foreach a of local asymmetric {
			local idx = `idx' + 1
			if "`v'" == "`a'" {
				local is_asym 1
				local pv : word `idx' of `pos_vars'
				local nv : word `idx' of `neg_vars'
				local new_lr_x       "`new_lr_x' `pv' `nv'"
				local lr_x_substantive "`lr_x_substantive' `pv' `nv'"
			}
		}
		if !`is_asym' {
			local new_lr_x       "`new_lr_x' `v'"
			local lr_x_substantive "`lr_x_substantive' `v'"
		}
	}

	* =========================================================================
	* 4. CROSS-SECTIONAL AUGMENTATION  (CCE / Chudik-Pesaran / HHK)
	*    z̄_t = (1/N) sum_i z_it for z in {y, x+ , x-, controls}
	*    Add z̄_t, L1.z̄_t, ..., L_{pT}.z̄_t to the LR equation
	*    Per Kapetanios, Mitchell & Shin (2014) -- introduce the nonlinear panel
	*    CSD framework -- and Hacioglu-Hoke & Kapetanios (2020 JAE) -- prove that
	*    consistency in nonlinear conditional mean models requires CSA of the
	*    nonlinear-transformed regressors (here: positive/negative partial sums).
	* =========================================================================

	local csa_full ""
	local csa_orig_names ""
	local n_csa_orig 0

	* For xtdcce2 engines, skip manual CSA construction; xtdcce2 builds CSA
	* internally via crosssectional() option.  Only do CSA when using xtpmg.
	if "`nocsa'" == "" & !`use_dcce' {
		* Derive underlying level of dep var from lr_dep (e.g. L.y -> y).
		* That is the correct CSA proxy for the cointegrating vector.
		local y_level "`lr_dep'"
		foreach op in "L1." "L." "l1." "l." "D1." "D." "d1." "d." {
			local y_level : subinstr local y_level "`op'" ""
		}

		* Default CSA list: y level + every substantive LR regressor (pos/neg pairs)
		if "`csavars'" == "" {
			local csa_target_vars "`y_level' `lr_x_substantive'"
		}
		else {
			local csa_target_vars "`csavars'"
		}

		* Pre-evaluate ts operators before bysort tvar (xtcspqardl pattern)
		local csa_clean ""
		foreach v of local csa_target_vars {
			tempvar tcsa_`++n_csa_orig'
			qui gen double `tcsa_`n_csa_orig'' = `v' if `touse'
			local csa_clean "`csa_clean' `tcsa_`n_csa_orig''"
			* Sanitise display name (strip ts operators, replace . with _)
			local clean_name "`v'"
			foreach op in "L1." "L." "l1." "l." "D1." "D." "d1." "d." {
				local clean_name : subinstr local clean_name "`op'" ""
			}
			local clean_name : subinstr local clean_name "." "_", all
			local csa_orig_names "`csa_orig_names' `clean_name'"
		}

		* Cross-sectional means at each t
		local idx 0
		local csa_zero_lag ""
		foreach src of local csa_clean {
			local ++idx
			local origname : word `idx' of `csa_orig_names'
			local csaname  "csa_`origname'"
			if "`replace'" != "" capture drop `csaname'
			capture confirm new variable `csaname'
			if _rc {
				di as err "CSA variable {bf:`csaname'} already exists; use {bf:replace}."
				exit 110
			}
			qui bysort `tvar': egen double `csaname' = mean(`src') if `touse'
			label variable `csaname' "Cross-sectional average of `origname'"
			local csa_zero_lag "`csa_zero_lag' `csaname'"
			local generated_vars "`generated_vars' `csaname'"
		}

		* Restore panel sort and tsset
		qui tsset

		* CSA lags
		local csa_lagged ""
		if `cr_lags' > 0 {
			forvalues k = 1/`cr_lags' {
				foreach csav of local csa_zero_lag {
					local csa_lagged "`csa_lagged' L`k'.`csav'"
				}
			}
		}

		local csa_full "`csa_zero_lag' `csa_lagged'"
	}

	* Final augmented LR equation:
	*   y_lag  +  substantive LR vars  +  CSA(z)  +  CSA lags
	local new_lr "`lr_dep' `new_lr_x' `csa_full'"
	local new_varlist "`depvar' `new_sr'"

	* =========================================================================
	* 5. SUMMARY OF MODEL SPECIFICATION
	* =========================================================================

	* Derive y level (used by xtdcce2 forms)
	local y_level "`lr_dep'"
	foreach op in "L1." "L." "l1." "l." "D1." "D." "d1." "d." {
		local y_level : subinstr local y_level "`op'" ""
	}

	di
	di in smcl in gr "{hline 78}"
	di in gr "  {bf:Model specification}"
	di in smcl in gr "{hline 78}"
	di in gr "    Dependent variable       : " in ye "`depvar'"
	di in gr "    Engine / backend         : " _c
	if `use_dcce' {
		if "`engine'" == "csardl"     di in ye "Nonlinear CS-ARDL  (xtdcce2 backend)"
		else if "`engine'" == "csdl"  di in ye "Nonlinear CS-DL    (xtdcce2 backend)"
		else if "`engine'" == "dcce"  di in ye "Nonlinear DCCE     (xtdcce2 backend)"
		else if "`engine'" == "cce"   di in ye "Nonlinear CCE      (xtdcce2 backend)"
	}
	else          di in ye "Nonlinear Panel ARDL -- `modelname' (xtpmg backend)"
	if !`use_dcce' {
		di in gr "    Heterogeneity scheme     : " _c
		if "`modelopt'" == "pmg" di in ye "PMG (pooled long-run, heterogeneous short-run)"
		else if "`modelopt'" == "mg"  di in ye "MG (heterogeneous long & short run, averaged)"
		else                          di in ye "DFE (homogeneous, dynamic fixed effects)"
	}
	else if "`pooled'" != ""           di in gr "    Pooled long-run vars     : " in ye "`pooled'"
	di in gr "    Asymmetric variables     : " in ye "`asym_vars_display'"
	di in gr "    Short-run regressors     : " in ye "`new_sr'"
	di in gr "    Long-run substantive vars: " in ye "`lr_x_substantive'"
	di in gr "    CCE augmentation         : " _c
	if "`nocsa'" != "" di in ye "OFF (reduces to Panel NARDL)"
	else if `use_dcce' {
		di in ye "ON (handled internally by xtdcce2)"
		di in gr "      CSA lags (p_T)         : " in ye "`cr_lags'" in gr ///
			"  (Chudik-Pesaran rule: floor(T^{1/3}) = floor(`avg_T'^{1/3}) = " ///
			in ye `=floor(`avg_T'^(1/3))' in gr ")"
	}
	else {
		di in ye "ON"
		di in gr "      CSA target variables   : " in ye "`csa_orig_names'"
		di in gr "      CSA lags (p_T)         : " in ye "`cr_lags'" in gr ///
			"  (Chudik-Pesaran rule: floor(T^{1/3}) = floor(`avg_T'^{1/3}) = " ///
			in ye `=floor(`avg_T'^(1/3))' in gr ")"
		local n_csa_total = `n_csa_orig' * (1 + `cr_lags')
		di in gr "      Total CSA proxies      : " in ye "`n_csa_total'" in gr ///
			"  = " in ye "`n_csa_orig'" in gr " x (1+" in ye "`cr_lags'" in gr ")"
	}
	di in gr "    Panels (N)               : " in ye "`npanels'"
	di in gr "    Average T_i              : " in ye "`avg_T'"
	di in gr "    Observations             : " in ye "`nobs'"
	di in gr "    Confidence level         : " in ye "`level'%"
	di in smcl in gr "{hline 78}"

	* =========================================================================
	* 6. ESTIMATE  (dispatch by engine)
	* =========================================================================

	if !`use_dcce' {
		* ---------------- xtpmg backend (default) -------------------
		local xtpmg_opts "lr(`new_lr') `modelopt' replace ec(`ec') level(`level')"
		if "`full'"        != "" local xtpmg_opts "`xtpmg_opts' full"
		if "`technique'"   != "" local xtpmg_opts "`xtpmg_opts' `technique'"
		if "`difficult'"   != "" local xtpmg_opts "`xtpmg_opts' difficult"
		if "`constraints'" != "" local xtpmg_opts "`xtpmg_opts' constraints(`constraints')"
		if "`constant'"    != "" local xtpmg_opts "`xtpmg_opts' noconstant"
		if "`cluster'"     != "" local xtpmg_opts "`xtpmg_opts' `cluster'"

		di
		di in smcl in gr "  Estimating {bf:Nonlinear Panel ARDL (`modelname')} via xtpmg..."
		di

		qui capture drop `ec'
		xtpmg `new_varlist' `if' `in', `xtpmg_opts'
	}
	else {
		* ---------------- xtdcce2 backend ---------------------------
		* Build the xtdcce2 call.  The decomposed pos/neg vars enter the LR /
		* regressor list; xtdcce2 takes their CSA via crosssectional(_all).
		* Default pooled() = all LR substantive vars + lagged y (PMG-style).

		if "`pooled'" == "" {
			if "`engine'" == "csardl"     local pooled_use "`lr_dep' `new_lr_x'"
			else if "`engine'" == "csdl"  local pooled_use "`new_lr_x'"
			else if "`engine'" == "dcce"  local pooled_use ""        // MG default
			else if "`engine'" == "cce"   local pooled_use ""        // MG default
		}
		else local pooled_use "`pooled'"

		local dcce_opts "crosssectional(_all) cr_lags(`cr_lags')"
		if "`pooled_use'" != "" local dcce_opts "`dcce_opts' pooled(`pooled_use')"
		if "`recursive'"  != "" local dcce_opts "`dcce_opts' recursive"
		if "`jackknife'"  != "" local dcce_opts "`dcce_opts' jackknife"
		if "`constant'"   != "" local dcce_opts "`dcce_opts' noconstant"
		if "`lr_options'" != "" local dcce_opts "`dcce_opts' lr_options(`lr_options')"

		* Build the regressor list according to engine form
		if "`engine'" == "csardl" {
			* CS-ARDL: regressors at level, LR via ARDL recovery
			local dcce_rhs "`new_sr'"
			local dcce_lr  "`lr_dep' `new_lr_x'"
			if `"`lr_options'"' == "" local dcce_opts "`dcce_opts' lr_options(ardl)"
			local dcce_call "xtdcce2 `depvar' `dcce_rhs' `if' `in', lr(`dcce_lr') `dcce_opts'"
		}
		else if "`engine'" == "csdl" {
			* CS-DL: direct LR estimation, no ARDL recovery
			local dcce_rhs ""
			local dcce_lr  "`new_lr_x'"
			if `"`lr_options'"' == "" local dcce_opts "`dcce_opts' lr_options(nodivide)"
			local dcce_call "xtdcce2 `y_level' `dcce_rhs' `if' `in', lr(`dcce_lr') `dcce_opts'"
		}
		else if "`engine'" == "dcce" {
			* Dynamic CCE: regressors at level with lag of dep
			local dcce_rhs "`lr_dep' `new_lr_x'"
			local dcce_call "xtdcce2 `y_level' `dcce_rhs' `if' `in', `dcce_opts'"
		}
		else if "`engine'" == "cce" {
			* Static CCE: no dynamics, only contemporaneous regressors
			local dcce_rhs "`new_lr_x'"
			local dcce_call "xtdcce2 `y_level' `dcce_rhs' `if' `in', `dcce_opts'"
		}

		di
		if "`engine'" == "csardl"     di in smcl in gr "  Estimating {bf:Nonlinear CS-ARDL} via xtdcce2..."
		else if "`engine'" == "csdl"  di in smcl in gr "  Estimating {bf:Nonlinear CS-DL} via xtdcce2..."
		else if "`engine'" == "dcce"  di in smcl in gr "  Estimating {bf:Nonlinear DCCE} via xtdcce2..."
		else if "`engine'" == "cce"   di in smcl in gr "  Estimating {bf:Nonlinear CCE} via xtdcce2..."
		di in smcl in gr "  Call: " in ye "`dcce_call'"
		di

		`dcce_call'
	}

	estimates store CSNARDL_main

	* =========================================================================
	* 7. PUBLICATION TABLES (long-run, ECT, short-run, asymmetry)
	* =========================================================================

	if "`notable'" == "" & !`use_dcce' {
		_xtcsnardl_tab_lr,   ec(`ec') asymvars(`asym_vars_display') ///
			posvars(`pos_vars') negvars(`neg_vars') ///
			lrothers(`lr_others') level(`level')
		_xtcsnardl_tab_ect,  ec(`ec') ivar(`ivar') model(`modelopt') level(`level')
		_xtcsnardl_tab_sr,   ec(`ec') asymvars(`asym_vars_display') ///
			posvars(`pos_vars') negvars(`neg_vars') srvars(`new_sr') level(`level')
	}
	* xtdcce2 prints its own publication-quality tables -- no need to duplicate

	* =========================================================================
	* 8. ASYMMETRY WALD TESTS (long-run and short-run)
	* =========================================================================

	if "`noasymtest'" == "" {
		* dispatch by engine: equation prefix differs (ec: vs lr_)
		if `use_dcce' {
			_xtcsnardl_asymtest_dcce, asymvars(`asym_vars_display') ///
				posvars(`pos_vars') negvars(`neg_vars') engine(`engine')
		}
		else {
			_xtcsnardl_asymtest, ec(`ec') asymvars(`asym_vars_display') ///
				posvars(`pos_vars') negvars(`neg_vars')
		}
	}

	* =========================================================================
	* 9. OPTIONAL DIAGNOSTICS
	* =========================================================================

	if "`hausman'" != "" & "`modelopt'" != "dfe" {
		_xtcsnardl_hausman, varlist(`new_varlist') lr(`new_lr') ec(`ec') ///
			model(`modelopt') level(`level') `constant'
		* restore main model
		qui capture drop `ec'
		qui xtpmg `new_varlist' `if' `in', `xtpmg_opts'
		estimates store CSNARDL_main
	}

	if "`asytable'" != "" {
		_xtcsnardl_asym_compare, ec(`ec') asymvars(`asym_vars_display') ///
			posvars(`pos_vars') negvars(`neg_vars') srvars(`new_sr')
	}

	if "`panelcoef'" != "" {
		_xtcsnardl_panelcoef, ec(`ec') ivar(`ivar')
	}

	if "`showcsa'" != "" & "`nocsa'" == "" {
		_xtcsnardl_tab_csa, ec(`ec') ///
			csavars(`csa_zero_lag') csanames(`csa_orig_names') ///
			crlags(`cr_lags') level(`level')
	}

	if `multip' > 0 {
		if `use_dcce' {
			_xtcsnardl_multiplier_dcce, periods(`multip') ///
				posvars(`pos_vars') negvars(`neg_vars') ///
				asymvars(`asym_vars_display') level(`level')
		}
		else {
			_xtcsnardl_multiplier, periods(`multip') ec(`ec') ivar(`ivar') ///
				posvars(`pos_vars') negvars(`neg_vars') ///
				asymvars(`asym_vars_display') level(`level')
		}
	}

	if `irfshock' > 0 {
		if `use_dcce' {
			_xtcsnardl_irfshock_dcce, periods(`irfshock') ///
				posvars(`pos_vars') negvars(`neg_vars') ///
				asymvars(`asym_vars_display')
		}
		else {
			_xtcsnardl_irfshock, periods(`irfshock') ec(`ec') ivar(`ivar') ///
				posvars(`pos_vars') negvars(`neg_vars') ///
				asymvars(`asym_vars_display')
		}
	}

	* ---------- CSD diagnostics (Pesaran CD on residuals) ----------
	if "`nocdtest'" == "" {
		_xtcsnardl_cdtest, ivar(`ivar') tvar(`tvar') touse(`touse') ///
			depvar(`depvar') sr_vars(`new_sr') lr_vars(`new_lr') ec(`ec')
	}

	* =========================================================================
	* 10. PUBLICATION-QUALITY GRAPHS
	* =========================================================================

	if "`graph'" != "" {
		capture which xtcsnardl_graph
		if _rc {
			di as err "xtcsnardl_graph.ado not found in adopath."
		}
		else {
			local mp = max(`multip', `irfshock', 20)
			xtcsnardl_graph, ec(`ec') ivar(`ivar') ///
				asymvars(`asym_vars_display') ///
				posvars(`pos_vars') negvars(`neg_vars') ///
				periods(`mp') depvar(`depvar')
		}
	}

	* =========================================================================
	* 11. STORE RESULTS  &  CLEAN UP CSA VARS
	* =========================================================================

	ereturn local cmd          "xtcsnardl"
	ereturn local model        "`modelname'"
	ereturn local estimator    "cs_nardl_`modelopt'"
	ereturn local depvar       "`depvar'"
	ereturn local asymmetric   "`asym_vars_display'"
	ereturn local pos_vars     "`pos_vars'"
	ereturn local neg_vars     "`neg_vars'"
	ereturn local lr_x         "`lr_x_substantive'"
	ereturn local csa_vars     "`csa_orig_names'"
	ereturn local sr_vars      "`new_sr'"
	ereturn local ivar         "`ivar'"
	ereturn local tvar         "`tvar'"
	ereturn local ec_name      "`ec'"
	ereturn scalar cr_lags     = `cr_lags'
	ereturn scalar n_csa_orig  = `n_csa_orig'
	ereturn scalar npanels     = `npanels'
	ereturn scalar avg_T       = `avg_T'
	ereturn scalar level       = `level'

	* Drop transient CSA vars unless user asked to keep them
	if "`nocsa'" == "" & "`keepcsa'" == "" {
		foreach csav of local csa_zero_lag {
			capture drop `csav'
		}
	}

	di
	di in smcl in gr "{hline 78}"
	di in gr "  Generated partial-sum variables retained: " in ye "`pos_vars' `neg_vars'"
	if "`nocsa'" == "" & "`keepcsa'" != "" {
		di in gr "  Generated CSA variables retained        : " in ye "`csa_zero_lag'"
	}
	di in smcl in gr "  {bf:xtcsnardl v1.0.0} -- CS-NARDL estimation complete"
	di in smcl in gr "{hline 78}"
	di
end


* =============================================================================
* HELPER: Replay (when user types xtcsnardl with no args)
* =============================================================================
program define _xtcsnardl_replay
	syntax [, Level(integer `c(level)')]
	di in gr "  CS-NARDL estimator      : " in ye "`e(estimator)'"
	di in gr "  Dep. var                : " in ye "`e(depvar)'"
	di in gr "  Asymmetric variables    : " in ye "`e(asymmetric)'"
	di in gr "  CSA target variables    : " in ye "`e(csa_vars)'"
	di in gr "  CSA lags (p_T)          : " in ye "`e(cr_lags)'"
	di in gr "  See {help xtcsnardl_postestimation:postestimation help} for predict/test"
end


* =============================================================================
* TABLE 1: LONG-RUN COINTEGRATING PARAMETERS (with asymmetric pairs)
* =============================================================================
program define _xtcsnardl_tab_lr, rclass
	syntax, EC(string) ASYMvars(string) POSvars(string) NEGvars(string) ///
		LROthers(string) [Level(integer 95)]

	local zcrit = invnormal(1 - (100 - `level')/200)

	di
	di in smcl in gr "{hline 78}"
	di in gr "  {bf:Table 1.}  Long-run cointegrating parameters  ({it:CS-NARDL})"
	di in smcl in gr "{hline 78}"
	di in gr "  {ralign 16:Variable}  {ralign 11:Coef.}  {ralign 9:Std.Err.}  " _c
	di in gr "{ralign 8:z}  {ralign 8:P>|z|}  {ralign 21:[`level'% Conf. Interval]}  Sig"
	di in smcl in gr "{hline 78}"

	* (a) Asymmetric pos/neg pairs ----------------------------------------
	local nasym : word count `asymvars'
	forvalues i = 1/`nasym' {
		local av : word `i' of `asymvars'
		local pv : word `i' of `posvars'
		local nv : word `i' of `negvars'

		* positive partial sum
		_xtcsnardl_lr_row, ec(`ec') var(`pv') label("`av' (+)") zcrit(`zcrit') level(`level')

		* negative partial sum
		_xtcsnardl_lr_row, ec(`ec') var(`nv') label("`av' (-)") zcrit(`zcrit') level(`level')

		di in smcl in gr "  {hline 76}"
	}

	* (b) Other (symmetric) LR regressors  -------------------------------
	foreach v of local lrothers {
		local is_asym 0
		foreach a of local asymvars {
			if "`v'" == "`a'" local is_asym 1
		}
		if !`is_asym' {
			_xtcsnardl_lr_row, ec(`ec') var(`v') label("`v'") zcrit(`zcrit') level(`level')
		}
	}

	di in smcl in gr "{hline 78}"
	di in gr "  Sig: *** p<.01   ** p<.05   * p<.10        (Asymptotic z-test)"
	di in gr "  CSA (nuisance) proxies absorb unobserved common factors --" ///
		" show with {bf:showcsa}"
end

program define _xtcsnardl_lr_row
	syntax, EC(string) VAR(string) LABEL(string) ZCRIT(real) [Level(integer 95)]
	capture local b  = _b[`ec':`var']
	if _rc {
		di in gr "  {ralign 16:`label'}  {ralign 11:" in ye ".}  " ///
			in gr "(not estimated)"
		exit
	}
	capture local se = _se[`ec':`var']
	if _rc | `se' == 0 | `se' == . {
		di in gr "  {ralign 16:`label'}  {ralign 11:" in ye %9.4f `b' "}  " ///
			in gr "(std.err. unavailable)"
		exit
	}
	local z   = `b' / `se'
	local p   = 2 * (1 - normal(abs(`z')))
	local lo  = `b' - `zcrit' * `se'
	local hi  = `b' + `zcrit' * `se'
	local star ""
	if `p' < 0.01      local star "***"
	else if `p' < 0.05 local star "** "
	else if `p' < 0.10 local star "*  "

	di in gr "  {ralign 16:`label'}  " _c
	di as res "{ralign 11:" %9.4f `b' "}  " _c
	di in gr "{ralign 9:" %7.4f `se' "}  " _c
	di in gr "{ralign 8:" %6.3f `z' "}  " _c
	if `p' < 0.05 di as res "{ralign 8:" %6.4f `p' "}  " _c
	else          di in gr  "{ralign 8:" %6.4f `p' "}  " _c
	di in gr "{ralign 9:" %8.4f `lo' "} {ralign 9:" %8.4f `hi' "}  " _c
	di in ye "`star'"
end


* =============================================================================
* TABLE 2: ERROR CORRECTION COEFFICIENT (phi)
* =============================================================================
program define _xtcsnardl_tab_ect, rclass
	syntax, EC(string) IVar(string) MODEL(string) [Level(integer 95)]
	local zcrit = invnormal(1 - (100 - `level')/200)

	di
	di in smcl in gr "{hline 78}"
	di in gr "  {bf:Table 2.}  Error-correction speed of adjustment ({&phi})"
	di in smcl in gr "{hline 78}"

	if "`model'" == "pmg" | "`model'" == "dfe" {
		* pooled phi: try SR equation (xtpmg default for ECM), then bare name
		local phitested 0
		foreach fmt in "SR:" "ec:" "ECT:" "" {
			if !`phitested' {
				capture local b  = _b[`fmt'`ec']
				if !_rc {
					capture local se = _se[`fmt'`ec']
					if !_rc {
						local phitested 1
						local fmt_used "`fmt'"
					}
				}
			}
		}
		if `phitested' {
			local z  = `b' / `se'
			local p  = 2 * (1 - normal(abs(`z')))
			local lo = `b' - `zcrit' * `se'
			local hi = `b' + `zcrit' * `se'
			local hl = .
			if `b' < 0 & `b' > -2 local hl = ln(2) / abs(`b')
			local adj = abs(`b') * 100

			local class "Strong"
			if `b' >= -0.5  & `b' < -0.1 local class "Moderate"
			else if `b' >= -0.1 & `b' < 0 local class "Weak"
			else if `b' >= 0 local class "Non-convergent"

			di in gr "  {ralign 18:Pooled `ec'}  " _c
			if `b' < 0 di as res "{ralign 10:" %8.4f `b' "}  " _c
			else       di as err "{ralign 10:" %8.4f `b' "}  " _c
			di in gr "{ralign 8:" %7.4f `se' "}  " _c
			di in gr "{ralign 7:" %6.3f `z' "}  " _c
			di in gr "{ralign 7:" %6.4f `p' "}"
			di in gr "      Half-life          : " in ye %7.2f `hl' in gr "  periods"
			di in gr "      Adjustment speed   : " in ye %6.2f `adj' in gr "%  per period"
			di in gr "      Convergence class  : " in ye "`class'"
		}
		else {
			di in gr "  Could not locate pooled `ec' coefficient in xtpmg output."
		}
	}
	else {
		* MG: report mean phi across panels
		local sum_b = 0
		local n_conv = 0
		foreach i of global iis {
			local b = .
			capture local b = _b[`ivar'_`i':`ec']
			if _rc continue
			if `b' == . continue
			if `b' < 0 & `b' > -2 {
				local sum_b = `sum_b' + `b'
				local n_conv = `n_conv' + 1
			}
		}
		if `n_conv' > 0 {
			local mean_b = `sum_b' / `n_conv'
			local hl = ln(2) / abs(`mean_b')
			di in gr "  Mean-group `ec' (over convergent panels):"
			di in gr "      mean({&phi})        : " in ye %7.4f `mean_b'
			di in gr "      mean half-life     : " in ye %6.2f `hl' in gr "  periods"
			di in gr "      convergent panels  : " in ye "`n_conv'"
		}
	}
	di in smcl in gr "{hline 78}"
end


* =============================================================================
* TABLE 3: SHORT-RUN ASYMMETRIC COEFFICIENTS
*    xtpmg stores SR coefs under "SR:" equation.  For each SR varlist token,
*    we try the variable as the user wrote it (e.g. "L.y", "D.x_pos") and a
*    case-folded copy.  Asymmetric pairs are relabelled as "D.<var> (+/-)".
* =============================================================================
program define _xtcsnardl_tab_sr
	syntax, EC(string) ASYMvars(string) POSvars(string) NEGvars(string) ///
		SRvars(string) [Level(integer 95)]

	di
	di in smcl in gr "{hline 78}"
	di in gr "  {bf:Table 3.}  Short-run dynamics  ({&Delta} regressors)"
	di in smcl in gr "{hline 78}"
	di in gr "  {ralign 18:Variable}  {ralign 11:Coef.}  {ralign 9:Std.Err.}  " _c
	di in gr "{ralign 8:z}  {ralign 8:P>|z|}  Sig"
	di in smcl in gr "{hline 78}"

	local nasym : word count `asymvars'
	foreach sv of local srvars {

		* --- build display label ---
		* strip operators only for matching against asym pair list
		local stripped "`sv'"
		foreach op in "D1." "D." "d1." "d." "L1." "L." "l1." "l." {
			local stripped : subinstr local stripped "`op'" ""
		}
		local lbl "`sv'"
		forvalues i = 1/`nasym' {
			local pv : word `i' of `posvars'
			local nv : word `i' of `negvars'
			local av : word `i' of `asymvars'
			if "`stripped'" == "`pv'" local lbl "D.`av' (+)"
			if "`stripped'" == "`nv'" local lbl "D.`av' (-)"
		}

		* --- find coefficient: try variant capitalisations of the operator ---
		local b  = .
		local se = .
		local cand1 "`sv'"
		local cand2 = subinstr("`sv'", "d.", "D.", .)
		local cand3 = subinstr("`sv'", "D.", "d.", .)
		local cand4 = subinstr("`sv'", "l.", "L.", .)
		local cand5 = subinstr("`sv'", "L.", "l.", .)

		foreach c in "`cand1'" "`cand2'" "`cand3'" "`cand4'" "`cand5'" {
			capture local bt = _b[SR:`c']
			if !_rc {
				capture local set = _se[SR:`c']
				if !_rc {
					local b  = `bt'
					local se = `set'
					continue, break
				}
			}
		}
		if `b' == . | `se' == . | `se' == 0 continue

		local z = `b'/`se'
		local p = 2*(1 - normal(abs(`z')))
		local star ""
		if `p' < 0.01      local star "***"
		else if `p' < 0.05 local star "** "
		else if `p' < 0.10 local star "*  "

		di in gr "  {ralign 18:`lbl'}  " _c
		di as res "{ralign 11:" %9.4f `b' "}  " _c
		di in gr  "{ralign 9:" %7.4f `se' "}  " _c
		di in gr  "{ralign 8:" %6.3f `z' "}  " _c
		if `p' < 0.05 di as res "{ralign 8:" %6.4f `p' "}  " _c
		else          di in gr  "{ralign 8:" %6.4f `p' "}  " _c
		di in ye "`star'"
	}
	di in smcl in gr "{hline 78}"
end


* =============================================================================
* TABLE 4: CSA (nuisance) coefficients
* =============================================================================
program define _xtcsnardl_tab_csa
	syntax, EC(string) CSAvars(string) CSAnames(string) CRLags(integer) ///
		[Level(integer 95)]
	local zcrit = invnormal(1 - (100 - `level')/200)

	di
	di in smcl in gr "{hline 78}"
	di in gr "  {bf:Table 4.}  Cross-sectional average (CSA) loadings -- nuisance"
	di in gr "             Per Kapetanios-Mitchell-Shin (2014) and Hacioglu-Hoke &"
	di in gr "             Kapetanios (2020), CSA of nonlinear terms (x+, x-)"
	di in gr "             restores consistency and absorbs unobserved common factors."
	di in smcl in gr "{hline 78}"
	di in gr "  {ralign 22:CSA proxy}  {ralign 11:Coef.}  {ralign 9:Std.Err.}  " _c
	di in gr "{ralign 8:z}  {ralign 8:P>|z|}  Sig"
	di in smcl in gr "{hline 78}"

	local idx 0
	foreach v of local csavars {
		local ++idx
		local origname : word `idx' of `csanames'
		* lag 0
		_xtcsnardl_csa_row, ec(`ec') var(`v') label("csa(`origname')") zcrit(`zcrit')

		* lags 1..p_T
		forvalues k = 1/`crlags' {
			_xtcsnardl_csa_row, ec(`ec') var(L`k'.`v') ///
				label("L`k'.csa(`origname')") zcrit(`zcrit')
		}
	}
	di in smcl in gr "{hline 78}"
	di in gr "  Sig: *** p<.01   ** p<.05   * p<.10"
end

program define _xtcsnardl_csa_row
	syntax, EC(string) VAR(string) LABEL(string) ZCRIT(real)
	capture local b  = _b[`ec':`var']
	if _rc exit
	capture local se = _se[`ec':`var']
	if _rc | `se' == 0 | `se' == . exit
	local z = `b'/`se'
	local p = 2*(1 - normal(abs(`z')))
	local star ""
	if `p' < 0.01      local star "***"
	else if `p' < 0.05 local star "** "
	else if `p' < 0.10 local star "*  "
	di in gr "  {ralign 22:`label'}  " _c
	di as res "{ralign 11:" %9.4f `b' "}  " _c
	di in gr  "{ralign 9:" %7.4f `se' "}  " _c
	di in gr  "{ralign 8:" %6.3f `z' "}  " _c
	if `p' < 0.05 di as res "{ralign 8:" %6.4f `p' "}  " _c
	else          di in gr  "{ralign 8:" %6.4f `p' "}  " _c
	di in ye "`star'"
end


* =============================================================================
* ASYMMETRY WALD TESTS  (Long-run and Short-run)
* =============================================================================
program define _xtcsnardl_asymtest, rclass
	syntax, EC(string) ASYMvars(string) POSvars(string) NEGvars(string)

	di
	di in smcl in gr "{hline 78}"
	di in gr "  {bf:Table 5.}  Tests for asymmetry  (Wald, H0: {&beta}{sup:+}={&beta}{sup:-})"
	di in smcl in gr "{hline 78}"
	di in gr "  {ralign 18:Variable}  " _c
	di in gr "{ralign 8:chi2(1)}  {ralign 8:p-val}   Conclusion (5%)"
	di in smcl in gr "{hline 78}"

	local nasym : word count `asymvars'
	forvalues i = 1/`nasym' {
		local av : word `i' of `asymvars'
		local pv : word `i' of `posvars'
		local nv : word `i' of `negvars'

		* --- Long-run asymmetry ---
		capture test [`ec']`pv' = [`ec']`nv'
		if !_rc {
			local lr_chi = r(chi2)
			local lr_p   = r(p)
			local concl_lr "Symmetric (do not reject)"
			if `lr_p' < 0.05 local concl_lr "{bf:Asymmetric (reject)}"

			di in gr "  {ralign 18:`av' [LR]}  " _c
			di in ye "{ralign 8:" %7.3f `lr_chi' "}  " _c
			if `lr_p' < 0.05 di as res "{ralign 8:" %6.4f `lr_p' "}" _c
			else             di in gr  "{ralign 8:" %6.4f `lr_p' "}" _c
			di "   `concl_lr'"
		}

		* --- Short-run asymmetry (try variants of the operator case) ---
		local sr_tested 0
		foreach prefix in "SR:D." "SR:d." "[SR]D." "[SR]d." "D." "d." {
			if !`sr_tested' {
				capture test `prefix'`pv' = `prefix'`nv'
				if !_rc local sr_tested 1
			}
		}
		if `sr_tested' {
			local sr_chi = r(chi2)
			local sr_p   = r(p)
			local concl_sr "Symmetric (do not reject)"
			if `sr_p' < 0.05 local concl_sr "{bf:Asymmetric (reject)}"
			di in gr "  {ralign 18:`av' [SR]}  " _c
			di in ye "{ralign 8:" %7.3f `sr_chi' "}  " _c
			if `sr_p' < 0.05 di as res "{ralign 8:" %6.4f `sr_p' "}" _c
			else             di in gr  "{ralign 8:" %6.4f `sr_p' "}" _c
			di "   `concl_sr'"
		}
	}
	di in smcl in gr "{hline 78}"
end


* =============================================================================
* HAUSMAN TEST (MG vs PMG)
* =============================================================================
program define _xtcsnardl_hausman
	syntax, varlist(string) lr(string) ec(string) model(string) ///
		[Level(integer 95) noCONStant]

	di
	di in smcl in gr "{hline 78}"
	di in gr "  {bf:Hausman test:}  MG vs PMG"
	di in gr "  H0: long-run pooling restriction is valid (PMG efficient)"
	di in smcl in gr "{hline 78}"

	qui capture drop `ec'
	qui xtpmg `varlist', lr(`lr') mg  replace ec(`ec') level(`level') `constant'
	estimates store CSNARDL_mg
	qui capture drop `ec'
	qui xtpmg `varlist', lr(`lr') pmg replace ec(`ec') level(`level') `constant'
	estimates store CSNARDL_pmg

	capture hausman CSNARDL_mg CSNARDL_pmg, sigmamore
	if _rc {
		di in ye "  Hausman test could not be computed (matrix singular)."
	}
end


* =============================================================================
* ASYMMETRY COMPARISON TABLE
* =============================================================================
program define _xtcsnardl_asym_compare
	syntax, EC(string) ASYMvars(string) POSvars(string) NEGvars(string) ///
		SRvars(string)

	di
	di in smcl in gr "{hline 78}"
	di in gr "  {bf:Table 6.}  Asymmetry summary: long-run vs short-run"
	di in smcl in gr "{hline 78}"
	di in gr "  {ralign 14:Variable}" " {c |}" " {ralign 10:beta+}" " {c |}" ///
		" {ralign 10:beta-}" " {c |}" " {ralign 10:LR diff}" " {c |}" ///
		" {ralign 9:gamma+}" " {c |}" " {ralign 9:gamma-}" " {c |}" " {ralign 9:SR diff}"
	di in smcl in gr "  {hline 76}"

	local nasym : word count `asymvars'
	forvalues i = 1/`nasym' {
		local av : word `i' of `asymvars'
		local pv : word `i' of `posvars'
		local nv : word `i' of `negvars'

		capture local bp = _b[`ec':`pv']
		capture local bn = _b[`ec':`nv']
		if !_rc {
			local diff_lr = `bp' - `bn'
		}
		else {
			local bp = .
			local bn = .
			local diff_lr = .
		}

		local gp = .
		local gn = .
		foreach prefix in "SR:D." "SR:d." "D." "d." {
			capture local gp_t = _b[`prefix'`pv']
			if !_rc {
				capture local gn_t = _b[`prefix'`nv']
				if !_rc {
					local gp = `gp_t'
					local gn = `gn_t'
					continue, break
				}
			}
		}
		local diff_sr = .
		if `gp' != . & `gn' != . local diff_sr = `gp' - `gn'

		di in gr "  {ralign 14:`av'}" " {c |}" ///
			in ye " {ralign 10:" %8.4f `bp' "}" " {c |}" ///
			in ye " {ralign 10:" %8.4f `bn' "}" " {c |}" ///
			in ye " {ralign 10:" %8.4f `diff_lr' "}" " {c |}" ///
			in ye " {ralign 9:" %7.4f `gp' "}" " {c |}" ///
			in ye " {ralign 9:" %7.4f `gn' "}" " {c |}" ///
			in ye " {ralign 9:" %7.4f `diff_sr' "}"
	}
	di in smcl in gr "{hline 78}"
end


* =============================================================================
* PER-PANEL ECT COEFFICIENTS
* =============================================================================
program define _xtcsnardl_panelcoef
	syntax, EC(string) IVar(string)

	di
	di in smcl in gr "{hline 78}"
	di in gr "  {bf:Table 7.}  Per-panel error-correction coefficient {&phi}{sub:i}"
	di in smcl in gr "{hline 78}"
	di in gr "  {ralign 10:Panel}" " {c |}" " {ralign 12:phi_i}" " {c |}" ///
		" {ralign 10:Std.Err.}" " {c |}" " {ralign 8:z}" " {c |}" ///
		" {ralign 11:half-life}" " {c |}" " {ralign 12:speed (%)}" " {c |}" " conv?"
	di in smcl in gr "  {hline 76}"

	local sum_b = 0
	local n_conv = 0
	foreach i of global iis {
		capture local b  = _b[`ivar'_`i':`ec']
		if _rc continue
		capture local se = _se[`ivar'_`i':`ec']
		local z = .
		if `se' > 0 & `se' != . local z = `b'/`se'
		local hl = .
		local adj = .
		local conv "No"
		if `b' < 0 & `b' > -2 {
			local hl = ln(2)/abs(`b')
			local adj = abs(`b')*100
			local conv "Yes"
			local sum_b = `sum_b' + `b'
			local n_conv = `n_conv' + 1
		}
		di in gr "  {ralign 10:`i'}" " {c |}" ///
			in ye " {ralign 12:" %10.4f `b' "}" " {c |}" ///
			in ye " {ralign 10:" %8.4f `se' "}" " {c |}" ///
			in ye " {ralign 8:" %6.3f `z' "}" " {c |}" ///
			in ye " {ralign 11:" %8.2f `hl' "}" " {c |}" ///
			in ye " {ralign 12:" %9.2f `adj' "}" " {c |}" ///
			in ye " `conv'"
	}
	di in smcl in gr "  {hline 76}"
	if `n_conv' > 0 {
		local mean_b = `sum_b'/`n_conv'
		local mean_hl = ln(2)/abs(`mean_b')
		di in gr "  Convergent panels: " in ye "`n_conv'" ///
			in gr "  |  mean {&phi}: " in ye %7.4f `mean_b' ///
			in gr "  |  mean half-life: " in ye %5.2f `mean_hl'
	}
	di in smcl in gr "{hline 78}"
end


* =============================================================================
* DYNAMIC MULTIPLIERS  (cumulative asymmetric)
* =============================================================================
program define _xtcsnardl_multiplier
	syntax, Periods(integer) EC(string) IVar(string) ///
		POSvars(string) NEGvars(string) ASYMvars(string) [Level(integer 95)]

	di
	di in smcl in gr "{hline 78}"
	di in gr "  {bf:Table 8.}  Cumulative dynamic multipliers  m+(h), m-(h)"
	di in smcl in gr "{hline 78}"

	* Mean ECT (try MG-style per-panel first, fall back to pooled)
	local sum_b = 0
	local n_conv = 0
	foreach i of global iis {
		local b = .
		capture local b = _b[`ivar'_`i':`ec']
		if _rc continue
		if `b' == . continue
		if `b' < 0 & `b' > -2 {
			local sum_b = `sum_b' + `b'
			local n_conv = `n_conv' + 1
		}
	}
	local mean_phi = .
	if `n_conv' == 0 {
		* try pooled in SR equation (PMG/DFE storage)
		capture local mean_phi = _b[SR:`ec']
		if _rc local mean_phi = .
		if `mean_phi' == . {
			capture local mean_phi = _b[`ec']
			if _rc local mean_phi = .
		}
		if `mean_phi' == . {
			di in ye "  No convergent ECT -- multipliers cannot be computed."
			exit
		}
	}
	else {
		local mean_phi = `sum_b'/`n_conv'
	}

	local nasym : word count `asymvars'
	forvalues i = 1/`nasym' {
		local av : word `i' of `asymvars'
		local pv : word `i' of `posvars'
		local nv : word `i' of `negvars'

		capture local bp = _b[`ec':`pv']
		capture local bn = _b[`ec':`nv']
		if _rc continue

		di
		di in gr "  Variable: " in ye "`av'" in gr "   mean {&phi}=" in ye %7.4f `mean_phi' ///
			in gr "   {&beta}+=" in ye %7.4f `bp' in gr "   {&beta}-=" in ye %7.4f `bn'
		di in gr "  {ralign 6:h}  {ralign 12:m+(h)}  {ralign 12:m-(h)}  " _c
		di in gr "{ralign 14:m+ - m-}  Asymmetry"
		di in smcl in gr "  {hline 70}"

		local gap_p = 1
		local gap_n = -1
		forvalues h = 0/`periods' {
			if `h' == 0 {
				local mp = 0
				local mn = 0
			}
			else {
				local gap_p = `gap_p' + `mean_phi'*(`gap_p' - `bp')
				local gap_n = `gap_n' + `mean_phi'*(`gap_n' - `bn')
				local mp = `gap_p'
				local mn = `gap_n'
			}
			local diff = `mp' - `mn'
			local sym ""
			if abs(`diff') < 0.005 local sym "approx symmetric"
			else if `diff' > 0     local sym "m+ > m-"
			else                   local sym "m+ < m-"

			di in gr "  {ralign 6:" %4.0f `h' "}  " _c
			di in ye "{ralign 12:" %9.4f `mp' "}  " _c
			di in ye "{ralign 12:" %9.4f `mn' "}  " _c
			di in ye "{ralign 14:" %10.4f `diff' "}" _c
			di in gr "   `sym'"
		}
		di in gr "  Long-run targets:  m+({&infin})=" in ye %7.4f `bp' ///
			in gr "   m-({&infin})=" in ye %7.4f `bn' ///
			in gr "   asym=" in ye %7.4f `bp'-`bn'
	}
	di in smcl in gr "{hline 78}"
end


* =============================================================================
* IRF: POSITIVE vs NEGATIVE SHOCKS
* =============================================================================
program define _xtcsnardl_irfshock
	syntax, Periods(integer) EC(string) IVar(string) ///
		POSvars(string) NEGvars(string) ASYMvars(string)

	di
	di in smcl in gr "{hline 78}"
	di in gr "  {bf:Table 9.}  Asymmetric impulse responses to + / - shocks"
	di in smcl in gr "{hline 78}"

	local sum_b = 0
	local n_conv = 0
	foreach i of global iis {
		local b = .
		capture local b = _b[`ivar'_`i':`ec']
		if _rc continue
		if `b' == . continue
		if `b' < 0 & `b' > -2 {
			local sum_b = `sum_b' + `b'
			local n_conv = `n_conv' + 1
		}
	}
	local mean_phi = .
	if `n_conv' == 0 {
		capture local mean_phi = _b[SR:`ec']
		if _rc local mean_phi = .
		if `mean_phi' == . {
			capture local mean_phi = _b[`ec']
			if _rc local mean_phi = .
		}
		if `mean_phi' == . {
			di in ye "  No convergent ECT -- IRF cannot be computed."
			exit
		}
	}
	else {
		local mean_phi = `sum_b'/`n_conv'
	}

	local nasym : word count `asymvars'
	forvalues i = 1/`nasym' {
		local av : word `i' of `asymvars'
		local pv : word `i' of `posvars'
		local nv : word `i' of `negvars'
		capture local bp = _b[`ec':`pv']
		capture local bn = _b[`ec':`nv']
		if _rc continue

		di
		di in gr "  Variable: " in ye "`av'"
		di in gr "  {ralign 6:h}  {ralign 12:y(+shock)}  {ralign 12:gap(+)}  " _c
		di in gr "{ralign 12:y(-shock)}  {ralign 12:gap(-)}"
		di in smcl in gr "  {hline 70}"

		local yp = 0
		local yn = 0
		forvalues h = 0/`periods' {
			if `h' == 0 {
				local yp = 0
				local yn = 0
				local gp = `bp'
				local gn = `bn'
			}
			else {
				local yp = `yp' + `mean_phi'*(`yp' - `bp')
				local yn = `yn' + `mean_phi'*(`yn' - `bn')
				local gp = `bp' - `yp'
				local gn = `bn' - `yn'
			}
			di in gr "  {ralign 6:" %4.0f `h' "}  " _c
			di in ye "{ralign 12:" %9.4f `yp' "}  " _c
			di in ye "{ralign 12:" %9.4f `gp' "}  " _c
			di in ye "{ralign 12:" %9.4f `yn' "}  " _c
			di in ye "{ralign 12:" %9.4f `gn' "}"
		}
		local hl = ln(2)/abs(`mean_phi')
		di in gr "  Convergence:  +shock {c -}> " in ye %7.4f `bp' ///
			in gr "   -shock {c -}> " in ye %7.4f `bn' ///
			in gr "   half-life=" in ye %5.2f `hl' in gr " periods"
	}
	di in smcl in gr "{hline 78}"
end


* =============================================================================
* CROSS-SECTIONAL DEPENDENCE DIAGNOSTICS
*    Pesaran (2004, 2015) CD test on the residuals of the augmented model.
*    Tests whether CSA augmentation has fully absorbed unobserved common
*    factors.  Under H0 (no residual CSD) the standard ARDL inference is
*    valid; under H1 the user should increase cr_lags() or include extra
*    CSA proxies via csavars().
* =============================================================================
program define _xtcsnardl_cdtest, rclass
	syntax, IVar(string) TVar(string) TOUSE(string) DEPvar(string) ///
		SR_vars(string) LR_vars(string) EC(string)

	di
	di in smcl in gr "{hline 78}"
	di in gr "  {bf:Table 10.}  Cross-sectional dependence diagnostics  (residuals)"
	di in smcl in gr "{hline 78}"

	* Reconstruct residual u_it = Dy - fitted from xtpmg (e(b))
	tempvar uhat
	capture xtpmg_p `uhat', residuals
	if _rc {
		capture predict `uhat' if `touse', residuals
	}
	if _rc {
		* Fallback manual residual using e(b)
		capture confirm matrix e(b)
		if _rc {
			di in ye "  CD test skipped (residuals unavailable)."
			exit
		}
		* Try xtpmg's predict helper
		capture predict double `uhat' if `touse', xb
		if !_rc {
			tempvar dy
			qui gen double `dy' = d.`depvar' if `touse'
			qui replace `uhat' = `dy' - `uhat'
		}
		else {
			di in ye "  CD test skipped (cannot reconstruct residuals)."
			exit
		}
	}

	* Pesaran CD = sqrt(2T/(N(N-1))) * sum_{i<j} rho_ij      (Pesaran 2004)
	* Average absolute correlation |rho_bar|                  (Pesaran 2015)
	tempname CDstat CDpval rhobar absrho TBAR NBAR
	mata: _xtcsnardl_cd("`uhat'", "`ivar'", "`tvar'", "`touse'")

	di in gr "  H0: residual cross-sectional independence"
	di in gr "  {ralign 28:Statistic}  {ralign 12:Value}  {ralign 12:p-value}"
	di in smcl in gr "{hline 78}"
	di in gr "  {ralign 28:Pesaran (2004) CD}  " _c
	di in ye "{ralign 12:" %9.4f r(CD) "}  " _c
	if r(CD_p) < 0.05 di as res "{ralign 12:" %9.4f r(CD_p) "}" _c
	else              di in gr  "{ralign 12:" %9.4f r(CD_p) "}" _c
	di ""
	di in gr "  {ralign 28:avg pairwise rho (rho-bar)}  " _c
	di in ye "{ralign 12:" %9.4f r(rhobar) "}"
	di in gr "  {ralign 28:avg |rho| (Pesaran 2015)}  " _c
	di in ye "{ralign 12:" %9.4f r(absrho) "}"
	di in gr "  {ralign 28:T-bar (mean obs/panel)}  " _c
	di in ye "{ralign 12:" %9.0f r(Tbar) "}"
	di in gr "  {ralign 28:N (cross-sections used)}  " _c
	di in ye "{ralign 12:" %9.0f r(Nbar) "}"
	di in smcl in gr "{hline 78}"
	if r(CD_p) < 0.05 {
		di in ye "  WARNING: residual CSD detected.  Consider increasing " ///
			"{bf:cr_lags()} or adding"
		di in ye "  extra CSA proxies via {bf:csavars()}."
	}
	else {
		di in gr "  CSA augmentation appears sufficient (residuals look weakly dependent)."
	}

	return scalar CD       = r(CD)
	return scalar CD_p     = r(CD_p)
	return scalar rhobar   = r(rhobar)
	return scalar absrhobar= r(absrho)
end

* Mata routine: Pesaran CD on residual matrix (declarations at top, ANSI Mata)
mata:
mata clear
void _xtcsnardl_cd(string scalar resvar, string scalar ivar,
                   string scalar tvar,   string scalar touse)
{
	real matrix    U, R
	real colvector ids, ts, sel, u_panel, t_panel, mask, ui, uj
	real scalar    i, j, k, N, T, Tij, trow, cd, rhobar, absrhobar
	real scalar    sumcd, count, sdi, sdj, rho

	st_view(U=., ., (resvar, ivar, tvar), touse)
	if (rows(U) == 0) {
		st_rclear()
		st_numscalar("r(CD)",     .)
		st_numscalar("r(CD_p)",   .)
		st_numscalar("r(rhobar)", .)
		st_numscalar("r(absrho)", .)
		st_numscalar("r(Tbar)",   0)
		st_numscalar("r(Nbar)",   0)
		return
	}

	ids = uniqrows(U[., 2])
	ts  = uniqrows(U[., 3])
	N   = rows(ids)
	T   = rows(ts)

	if (N < 2) {
		st_rclear()
		st_numscalar("r(CD)",     .)
		st_numscalar("r(CD_p)",   .)
		st_numscalar("r(rhobar)", .)
		st_numscalar("r(absrho)", .)
		st_numscalar("r(Tbar)",   T)
		st_numscalar("r(Nbar)",   N)
		return
	}

	R = J(T, N, .)
	for (i = 1; i <= N; i++) {
		sel = select((1::rows(U)), U[., 2] :== ids[i])
		if (rows(sel) == 0) continue
		u_panel = U[sel, 1]
		t_panel = U[sel, 3]
		for (k = 1; k <= rows(t_panel); k++) {
			trow = selectindex(ts :== t_panel[k])[1]
			R[trow, i] = u_panel[k]
		}
	}

	sumcd     = 0
	rhobar    = 0
	absrhobar = 0
	count     = 0
	for (i = 1; i <= N - 1; i++) {
		for (j = i + 1; j <= N; j++) {
			mask = (R[., i] :!= .) :& (R[., j] :!= .)
			Tij  = sum(mask)
			if (Tij < 3) continue
			ui = select(R[., i], mask)
			uj = select(R[., j], mask)
			ui = ui :- mean(ui)
			uj = uj :- mean(uj)
			sdi = sqrt(sum(ui :* ui) / (Tij - 1))
			sdj = sqrt(sum(uj :* uj) / (Tij - 1))
			if (sdi == 0 | sdj == 0) continue
			rho = sum(ui :* uj) / ((Tij - 1) * sdi * sdj)
			sumcd     = sumcd + sqrt(Tij) * rho
			rhobar    = rhobar + rho
			absrhobar = absrhobar + abs(rho)
			count     = count + 1
		}
	}

	if (count == 0) {
		st_rclear()
		st_numscalar("r(CD)",     .)
		st_numscalar("r(CD_p)",   .)
		st_numscalar("r(rhobar)", .)
		st_numscalar("r(absrho)", .)
		st_numscalar("r(Tbar)",   T)
		st_numscalar("r(Nbar)",   N)
		return
	}

	cd        = sqrt(2 / (N * (N - 1))) * sumcd
	rhobar    = rhobar / count
	absrhobar = absrhobar / count

	st_rclear()
	st_numscalar("r(CD)",     cd)
	st_numscalar("r(CD_p)",   2 * (1 - normal(abs(cd))))
	st_numscalar("r(rhobar)", rhobar)
	st_numscalar("r(absrho)", absrhobar)
	st_numscalar("r(Tbar)",   T)
	st_numscalar("r(Nbar)",   N)
}
end


* =============================================================================
* xtdcce2-specific helpers
* =============================================================================
* xtdcce2 stores long-run coefficients in e(b) under the names "lr_<var>"
* (e.g. lr_x_pos, lr_x_neg, lr_y).  The lr_y entry is the speed-of-adjustment
* coefficient -(1-alpha).  Short-run/ARDL coefs are at bare names (e.g. x_pos,
* x_neg, L.y) WITHOUT an equation prefix.

* ASYMMETRY WALD TESTS (dcce/csardl/csdl)
program define _xtcsnardl_asymtest_dcce, rclass
	syntax, ASYMvars(string) POSvars(string) NEGvars(string) ENGine(string)

	di
	di in smcl in gr "{hline 78}"
	di in gr "  {bf:Table 5.}  Tests for asymmetry  (Wald, H0: {&beta}{sup:+}={&beta}{sup:-})"
	di in smcl in gr "  Engine: " in ye "`engine'" in gr " (xtdcce2 backend)"
	di in smcl in gr "{hline 78}"
	di in gr "  {ralign 18:Variable}  " _c
	di in gr "{ralign 8:chi2(1)}  {ralign 8:p-val}   Conclusion (5%)"
	di in smcl in gr "{hline 78}"

	local nasym : word count `asymvars'
	forvalues i = 1/`nasym' {
		local av : word `i' of `asymvars'
		local pv : word `i' of `posvars'
		local nv : word `i' of `negvars'

		* csardl: LR coefs are stored as lr_<var>; ARDL-form coefs at bare name
		* csdl  : x_<pos/neg> ARE the LR coefs directly (Chudik-Pesaran direct)
		* dcce  : x_<pos/neg> are ARDL coefs; LR test = (b_pos - b_neg)/(1-alpha) test
		* cce   : x_<pos/neg> are static coefs; symmetric test on them

		if "`engine'" == "csardl" {
			capture test lr_`pv' = lr_`nv'
			local rc1 = _rc
			if `rc1' == 0 {
				local s1 = cond(r(chi2)<. , r(chi2), cond(r(F)<. , r(F)*r(df), .))
				local p1 = r(p)
				_xtcsnardl_print_asymrow, lbl(`av' [LR]) chi2(`s1') p(`p1')
			}
			capture test `pv' = `nv'
			local rc1 = _rc
			if `rc1' == 0 {
				local s1 = cond(r(chi2)<. , r(chi2), cond(r(F)<. , r(F)*r(df), .))
				local p1 = r(p)
				_xtcsnardl_print_asymrow, lbl(`av' [SR]) chi2(`s1') p(`p1')
			}
		}
		else if "`engine'" == "csdl" {
			capture test `pv' = `nv'
			local rc1 = _rc
			if `rc1' == 0 {
				local s1 = cond(r(chi2)<. , r(chi2), cond(r(F)<. , r(F)*r(df), .))
				local p1 = r(p)
				_xtcsnardl_print_asymrow, lbl(`av' [LR]) chi2(`s1') p(`p1')
			}
		}
		else if "`engine'" == "dcce" {
			capture test `pv' = `nv'
			local rc1 = _rc
			if `rc1' == 0 {
				local s1 = cond(r(chi2)<. , r(chi2), cond(r(F)<. , r(F)*r(df), .))
				local p1 = r(p)
				_xtcsnardl_print_asymrow, lbl(`av' [ARDL]) chi2(`s1') p(`p1')
			}
		}
		else if "`engine'" == "cce" {
			capture test `pv' = `nv'
			local rc1 = _rc
			if `rc1' == 0 {
				local s1 = cond(r(chi2)<. , r(chi2), cond(r(F)<. , r(F)*r(df), .))
				local p1 = r(p)
				_xtcsnardl_print_asymrow, lbl(`av' [static]) chi2(`s1') p(`p1')
			}
		}
	}
	di in smcl in gr "{hline 78}"
	di in gr "  All engines decompose x into x+ / x- (Shin-Yu-Greenwood-Nimmo)"
	di in gr "  before estimation, so every test is on the {ul:nonlinear} extension:"
	di in gr "    csardl : LR via lr_x+ vs lr_x-; SR via ARDL-form x+ vs x-"
	di in gr "    csdl   : LR coefs ARE x+ and x- directly (Chudik-Pesaran)"
	di in gr "    dcce   : ARDL-form x+ vs x- (recover LR via beta/(1-alpha))"
	di in gr "    cce    : static contemporaneous x+ vs x-"
end

program define _xtcsnardl_print_asymrow
	syntax, LBL(string) CHI2(real) P(real)
	di in gr "  {ralign 18:`lbl'}  " _c
	di in ye "{ralign 8:" %7.3f `chi2' "}  " _c
	if `p' < 0.05 di as res "{ralign 8:" %6.4f `p' "}" _c
	else          di in gr  "{ralign 8:" %6.4f `p' "}" _c
	if `p' < 0.05 di "   {bf:Asymmetric (reject)}"
	else          di "   Symmetric (do not reject)"
end



* DYNAMIC MULTIPLIERS (dcce/csardl/csdl)
program define _xtcsnardl_multiplier_dcce
	syntax, Periods(integer) POSvars(string) NEGvars(string) ASYMvars(string) ///
		[Level(integer 95)]

	di
	di in smcl in gr "{hline 78}"
	di in gr "  {bf:Table 8.}  Cumulative dynamic multipliers  m+(h), m-(h)"
	di in smcl in gr "  (xtdcce2 / CS-ARDL recovery)"
	di in smcl in gr "{hline 78}"

	* Speed of adjustment is lr_y = -(1 - alpha) under lr_options(ardl)
	local mean_phi = .
	capture local mean_phi = _b[lr_y]
	if _rc local mean_phi = .
	if `mean_phi' == . {
		* csdl form has no lr_y; degrade to single jump multiplier
		di in ye "  No lr_y in xtdcce2 output -- multipliers cannot be computed."
		di in ye "  (CS-DL gives long-run effects directly; use Table 1)"
		exit
	}

	local nasym : word count `asymvars'
	forvalues i = 1/`nasym' {
		local av : word `i' of `asymvars'
		local pv : word `i' of `posvars'
		local nv : word `i' of `negvars'

		local bp = .
		local bn = .
		capture local bp = _b[lr_`pv']
		capture local bn = _b[lr_`nv']
		if `bp' == . | `bn' == . continue

		di
		di in gr "  Variable: " in ye "`av'" in gr "   {&phi}=" in ye %7.4f `mean_phi' ///
			in gr "   {&beta}+=" in ye %7.4f `bp' in gr "   {&beta}-=" in ye %7.4f `bn'
		di in gr "  {ralign 6:h}  {ralign 12:m+(h)}  {ralign 12:m-(h)}  " _c
		di in gr "{ralign 14:m+ - m-}  Asymmetry"
		di in smcl in gr "  {hline 70}"

		local gap_p = 1
		local gap_n = -1
		forvalues h = 0/`periods' {
			if `h' == 0 {
				local mp = 0
				local mn = 0
			}
			else {
				local gap_p = `gap_p' + `mean_phi'*(`gap_p' - `bp')
				local gap_n = `gap_n' + `mean_phi'*(`gap_n' - `bn')
				local mp = `gap_p'
				local mn = `gap_n'
			}
			local diff = `mp' - `mn'
			local sym ""
			if abs(`diff') < 0.005 local sym "approx symmetric"
			else if `diff' > 0     local sym "m+ > m-"
			else                   local sym "m+ < m-"
			di in gr "  {ralign 6:" %4.0f `h' "}  " _c
			di in ye "{ralign 12:" %9.4f `mp' "}  " _c
			di in ye "{ralign 12:" %9.4f `mn' "}  " _c
			di in ye "{ralign 14:" %10.4f `diff' "}" _c
			di in gr "   `sym'"
		}
		di in gr "  Long-run targets:  m+({&infin})=" in ye %7.4f `bp' ///
			in gr "   m-({&infin})=" in ye %7.4f `bn' ///
			in gr "   asym=" in ye %7.4f `bp'-`bn'
	}
	di in smcl in gr "{hline 78}"
end


* IRF (dcce/csardl/csdl)
program define _xtcsnardl_irfshock_dcce
	syntax, Periods(integer) POSvars(string) NEGvars(string) ASYMvars(string)

	di
	di in smcl in gr "{hline 78}"
	di in gr "  {bf:Table 9.}  Asymmetric impulse responses to + / - shocks"
	di in smcl in gr "  (xtdcce2 / CS-ARDL recovery)"
	di in smcl in gr "{hline 78}"

	local mean_phi = .
	capture local mean_phi = _b[lr_y]
	if _rc local mean_phi = .
	if `mean_phi' == . {
		di in ye "  No lr_y in xtdcce2 output -- IRF cannot be computed."
		exit
	}

	local nasym : word count `asymvars'
	forvalues i = 1/`nasym' {
		local av : word `i' of `asymvars'
		local pv : word `i' of `posvars'
		local nv : word `i' of `negvars'

		local bp = .
		local bn = .
		capture local bp = _b[lr_`pv']
		capture local bn = _b[lr_`nv']
		if `bp' == . | `bn' == . continue

		di
		di in gr "  Variable: " in ye "`av'"
		di in gr "  {ralign 6:h}  {ralign 12:y(+shock)}  {ralign 12:gap(+)}  " _c
		di in gr "{ralign 12:y(-shock)}  {ralign 12:gap(-)}"
		di in smcl in gr "  {hline 70}"

		local yp = 0
		local yn = 0
		forvalues h = 0/`periods' {
			if `h' == 0 {
				local yp = 0
				local yn = 0
				local gp = `bp'
				local gn = `bn'
			}
			else {
				local yp = `yp' + `mean_phi'*(`yp' - `bp')
				local yn = `yn' + `mean_phi'*(`yn' - `bn')
				local gp = `bp' - `yp'
				local gn = `bn' - `yn'
			}
			di in gr "  {ralign 6:" %4.0f `h' "}  " _c
			di in ye "{ralign 12:" %9.4f `yp' "}  " _c
			di in ye "{ralign 12:" %9.4f `gp' "}  " _c
			di in ye "{ralign 12:" %9.4f `yn' "}  " _c
			di in ye "{ralign 12:" %9.4f `gn' "}"
		}
		local hl = ln(2)/abs(`mean_phi')
		di in gr "  Convergence:  +shock {c -}> " in ye %7.4f `bp' ///
			in gr "   -shock {c -}> " in ye %7.4f `bn' ///
			in gr "   half-life=" in ye %5.2f `hl' in gr " periods"
	}
	di in smcl in gr "{hline 78}"
end
