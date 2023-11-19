/*
Changelog

v.1.0.0 -- 1 September 2023
(1) Original release.

v.2.0.0 -- 11 November 2023
(1) Option -endogenous()- is now used to specify the names of the endogenous variables if any of them are not the same as the auxiliary dependent variables and are instead functions of the auxiliary dependent variables.
(2) Original -endogenous- option renamed -auxiliary-; use this to specify the auxiliary dependent variables.
(3) Replay functionality: previous estimation output is replayed after inputting "ivcloglog".
(4) Modified output for improved clarity.
(5) Bug fixes and minor tweaks.

v.2.0.1 -- 17 November 2023
(1) Bug fix for when multiple endogenous variables are supplied with -endogenous()-
*/

*! Version 2.0.1 -- William Liu (刘威廉) -- 17 November 2023
*! ivcloglog -- Complementary log-log model with endogenous covariates (either continuous or functions of observed continuous covariates), instrumented via the control function approach (i.e., 2SRI)
*!
*! Syntax:
*! ivcloglog binary_outcome_var [controls] [if] [in], VHATname(string) AUXiliary(auxdep_vars = instruments[, NOCONstant]) [ENDOgenous(transformed_endo_vars) NOCONstant order(integer) vce(vcetype) NOGENerate DIFFicult_vce SHOWstages]

program ivcloglog, eclass byable(onecall)
	version 11											// FVvars and -_rmcoll- option -touse()- not introduced until v11.0
	
	qui ds												// Get original varlist
	local orig_varlist `r(varlist)'
	
	if _by() {
		local BY `"by `_byvars'`_byrc0':"'
	}
	
	`BY' _vce_parserun ivcloglog, noeqlist jkopts(eclass): `0'
	
	if "`s(exit)'" != "" {
		ereturn local cmdline `"ivcloglog `0'"'
		exit
	}
	
	if replay() {										// For replaying the results
		if `"`e(cmd)'"' != "ivcloglog" { 
			error 301
		}
		else if _by() { 
			error 190 
		}
		else {
			ivcloglog_out `0'
			exit
		}
	}
	
	cap noi {											// To allow us to drop the cfvars
		`BY' Estimate `0'
	}
	local est_rc = _rc
	ereturn local cmdline `"ivcloglog `0'"'
	
	drop_cfvars `0' orig_varlist(`orig_varlist')		// Drop powers of vhat if requested with -nogenerate- (if they exist)
	
	if `est_rc' {										// To restore the original behavior -- with -capture noisily-, the error message is displayed but not the return code
		exit `est_rc'									// Note: -exit- with a return code only displays the error code; -error- with a return code also displays the corresponding generic error message
	}
end



program define Estimate, eclass byable(recall)
	syntax varlist(numeric fv ts) [if] [in]								///
								  [fweight iweight pweight aweight],	///
								  [										///
								  VHATname(string)						///
								  noCONstant							///
								  order(integer 1)						///
								  vce(string)							///
								  NOGENerate							///
								  DIFFicult_vce							///
								  SHOWstages							///
								  *										///
								  ]
	
	_get_diopts diopts options, `options'		// Note: the second argument must be provided anyway when there are non-display options
	
	if ("`weight'" != "") {
		local wgt [`weight'`exp']
	}
	
	if ("`vhatname'" == "") {
		local vhatname "vhat"
	}
	else if (strpos("`vhatname'", " ")) {
		di as err "option {bf:vhatname()} should only contain one word"
		exit 198
	}
	
	gettoken depvar exogvars : varlist
	_fv_check_depvar `depvar', k(1)				// Stops depvar being a factor variable
	local exogvars : list uniq exogvars			// Check for duplicates
	
	local nocon2 `constant'						// For better readability
	
	* Parse -auxiliary(...)- option
	parse_remaining_opt, exogvars(`exogvars') `options'
	local options `s(options)'
	local num_endo = `s(num_endo)'
	local num_aux = `s(num_aux)'
	
	local allinst `s(allinst)'
	local endovars `s(endovars)'
	local auxdepvars `s(auxdepvars)'
	local nocon1 `s(nocons1)'
	
	marksample touse
	_vce_parse `touse', optlist(Robust) argoptlist(CLuster) : , vce(`vce')			// Apart from parsing the -vce()- option, this will also check variables inside of it for missing values
	local clustervar "`r(cluster)'"
	markout `touse' `endovars' `allinst'
	
	* Check for "perfect predictors" of the outcome and collinearity amongst the regressors; also expand factor variables
	// Checking the exogvars once rather than twice would be more efficient. (Recall that they appear as instruments!)
	// Must check the second stage first since the number of observations can decrease if "perfect predictors" are present
	tempname omit1 omit2
	
	di as text "Checking second stage for perfect predictors of the outcome and regressor collinearity..."
	iden_check_and_fvexpand_2, lhs(`depvar') exog(`exogvars') endo(`endovars') touse(`touse') wgt(`wgt') `difficult_vce' `nocon2'
	if ("`exogvars'" != "") {
		local exogvars `r(exog)'
		matrix `omit2' = r(exog_omit)
		matrix `omit2' = `omit2', J(1, `=`num_aux'*`order' + `num_endo'', 1)		// Add elements for the endovars and residual powers
	}
	else {
		matrix `omit2' = J(1, `=`num_aux'*`order' + `num_endo'', 1)
	}
	
	di as text "Checking first stage for regressor collinearity..."
	iden_check_and_fvexpand_1, allinst(`allinst') touse(`touse') wgt(`wgt') `difficult_vce' `nocon1'
	local allinst `r(allinst)'
	matrix `omit1' = r(allinst_omit)
	
	* Initial values
	** First stage
	tempname F1 F2 F1_forone_eq F
	forval i = 1/`num_aux' {
		forval p = 1/`order' {
			local resid`i'_`p' `vhatname'`i'_`p'		// For better readability
			qui gen double `resid`i'_`p'' = .			// Previously, for some reason, initializing the higher powers with missing values didn't work when not using -from(...)-
			local resid`i'_powers = "`resid`i'_powers' `resid`i'_`p''"
		}
		
		local endovar`i' : word `i' of `auxdepvars'
		init_values_1 `endovar`i'' `allinst' if `touse' `wgt', `nocon1' predictvars(`resid`i'_powers') order(`order') `showstages'		// Store powers of vhat for auxdep variable `i' in local macro `resid`i'_powers'
		matrix `F1_forone_eq' = r(param_est)
		matrix `F1' = nullmat(`F1'), `F1_forone_eq'		// -nullmat()- relaxes the restriction that `A' must exist
		local yparam1 "`r(yparam)'"
		local yparam1_combined "`yparam1_combined' `yparam1'"
		
		local resid_combo "`resid_combo' `resid`i'_1'"							// vhats from all endo. variables
		forval p = 1/`order' {
			local resid_powers_combo "`resid_powers_combo' `resid`i'_`p''"		// Powers of the vhats from all endo. variables
		}
		
		local inst_opt1 "`inst_opt1' instruments(`endovar`i'':`allinst', `nocon1')"
	}
	
	** Second stage
	local 2ndstage_vars "`exogvars' `endovars' `resid_powers_combo'"
	init_values_2 `depvar' `2ndstage_vars' if `touse' `wgt', `nocon2' `showstages'
	local yparam2 "`r(yparam)'"
	local ll = `r(ll)'
	local ll_0 = `r(ll_0)'
	local rc = `r(rc)'
	local ic = `r(ic)'
	local converged = `r(converged)'
	
	matrix `F2' = r(param_est)
	matrix `F' = `F1', `F2'
	
	local inst_opt2 "instruments(`depvar': `2ndstage_vars', `nocon2')"
	
	* Calculate VCE
	// The undocumented option -iter(0)- prevents numerical iterations -- we only want the sandwich formula.
	// -haslfderivatives- differs from -hasderivatives- in that you don't need to specify each parameter, only the parameter groupings.
	// These are what I call the parameters that form linear combinations.
	// They are specified using the curly braces in the -parameter()- option or through residual equation names.
	tempname b V N k N_clust
	
	* -difficult_vce-
	if ("`difficult_vce'" != "") {
		if ("`clustervar'" == "") {
			di as err "only vcetype {bf:cluster} is allowed with option {bf:difficult_vce}"
			exit 198
		}
		
		forval eq = 1/`num_aux' {
			forval q = 1/`=`order'-1' {
				local resid_powerm1s_combo "`vhatname'`eq'_`q' `resid_powerm1s_combo'"
			}
		}
		
		mata: calc_vce("`depvar'", "`2ndstage_vars'", "`allinst'",		///
					"`resid_powerm1s_combo'",							///
					"`resid_combo'", `order',							///
					"`F'", "`touse'", "`clustervar'",					///
					"`nocon1'", "`nocon2'", "`V'",						///
					"`omit1'", "`omit2'")
		
		qui gmm gmm_ivcloglog if `touse', equations(`auxdepvars' `depvar')					///
											parameters("`yparam1_combined' `yparam2'")		///
											y1(`depvar') y2(`auxdepvars') 					///		// Wooldridge-style notation for this line; the 1 and 2 on other lines represent stages
											vhatname(`vhatname') order(`order')				///
											`inst_opt1' `inst_opt2'							///
											winitial(identity)								///
											hasderivatives fakederivatives					///
											onestep iter(0) from(`F')						///
											vce(`vce')										///
											valueid("EE criterion") `diopts'
		
		matrix `b' = e(b)
		matrix colnames `V' = `yparam1_combined' `yparam2'
		matrix rownames `V' = `yparam1_combined' `yparam2'
		
		ereturn repost b = `b' V = `V'
	}
	
	* Directly use GMM if no -difficult_vce- option
	else {
		qui gmm gmm_ivcloglog if `touse', equations(`auxdepvars' `depvar')					///
											parameters("`yparam1_combined' `yparam2'")		///
											y1(`depvar') y2(`auxdepvars') 					///		// Wooldridge-style notation for this line; the 1 and 2 on other lines represent stages
											vhatname(`vhatname') order(`order')				///
											`inst_opt1' `inst_opt2'							///
											winitial(identity)								///
											haslfderivatives onestep iter(0) from(`F')		///
											vce(`vce')										///
											valueid("EE criterion") `diopts'
	}
	
	* -ereturn- stuff and display results
	// Note: in versions < 14 of Stata, -gmm- can count the number of parameters incorrectly,
	// failing to exclude omission-flagged variables.
	matrix `b' = e(b)
	matrix `V' = e(V)
	scalar `N' = e(N)
	scalar `k' = e(n_moments)					// Equals number of parameters but is not incorrectly counted in versions 14 of Stata
	scalar `N_clust' = e(N_clust)
	local clustvar `e(clustvar)'
	local e_vce "`e(vce)'"						// Named this way as a reminder that this is different from `vce'
	local vcetype "`e(vcetype)'"
	
	ereturn post `b' `V' /*`wgt'*/, depname(`depvar') o(`=`N'') esample(`touse') buildfvinfo
	
	// Macros (apart from those from -ereturn post-)	
	ereturn hidden local vcetype "`vcetype'"
	ereturn local clustvar `clustvar'
	ereturn local vce "`e_vce'"
	
	if ("`nocon1'" == "") {
		ereturn local inst `allinst' _con
	}
	else {
		ereturn local inst `allinst'
	}
	ereturn local auxdep `auxdepvars'
	ereturn local endog `endovars'
	if ("`nocon2'" == "") {
		ereturn local exog `exogvars' _con
	}
	else {
		ereturn local exog `exogvars'
	}
	ereturn local depvar `depvar'
	ereturn local cmd "ivcloglog"
	
	// Scalars
	ereturn scalar k = `k'
	ereturn scalar endog_ct = `num_endo'
	ereturn scalar auxdep_ct = `num_aux'
	ereturn scalar N_clust = `N_clust'
	
	foreach var in `exogvars' `endovars' {
		local temp "`temp' [`depvar']`var'"
	}
	qui test `temp'								// Wald test for second stage, excluding constant (if it exists) and control function
	ereturn scalar chi2 = r(chi2)
	ereturn scalar df_m = r(df)
	ereturn scalar p = chiprob(r(df), r(chi2))
	
	ereturn scalar ll = `ll'
	ereturn scalar ll_0 = `ll_0'
	_post_vce_rank
	
	ereturn scalar ic = `ic'					// From -cloglog-
	ereturn scalar rc = `rc'					// From -cloglog-
	ereturn scalar converged = `converged'		// From -cloglog-
	
	ivcloglog_out, `diopts'
end



program parse_remaining_opt, sclass		// Parses -auxiliary()- and also checks for remaining options (should be none)
	syntax [, exogvars(varlist fv ts) AUXiliary(string) ENDOgenous(varlist fv ts) *]
	
	* Check for remaining options (should be none)
	if ("`options'"!="") {
		di as err "option(s) {bf:`options'} not allowed"
		exit 198
	}
	
	* Parse contents of -auxiliary()-
	gettoken auxiliary temp : auxiliary, parse(",")			// Delimiter is stored in `temp' (which is not str.) and is then deleted
	local options = substr("`temp'", 2, .)
	parse_subopt_noconstant, `options'
	local nocons1 `r(constant)'								// Don't directly store `options' in `nocons1' since the former can be abbreviated
	
	gettoken auxdepvars temp : auxiliary, parse("=")
	local auxdepvars : list uniq auxdepvars					// Check for duplicates
	local extinst = substr("`temp'", 2, .)
	local extinst : list uniq extinst						// Check for duplicates
	local extinst : list extinst - exogvars					// Check for exogvars being explicitly added as instruments
	
	* Count and parse auxiliary dependent variables
	local num_aux : list sizeof auxdepvars
	forval i = 1/`num_aux' {
		local temp : word `i' of `auxdepvars'				// Format is auxiliary(auxdepvar_1 ... auxdepvar_k = ...)
		_fv_check_depvar `temp', k(1)						// Stops the dependent variables in the auxiliary equations being factor variables
	}
	
	local num_extinst : list sizeof extinst
	if (`num_aux' > `num_extinst') {
		di as err "equation not identified; must have at least as many instruments not in the regression as there are instrumented variables"
		exit 481
	}
	
	if ("`endogenous'" == "") {
		local endogenous "`auxdepvars'"
		local num_endo = `num_aux'							// If option -endogenous()- not supplied, assume that the auxdepvars are the endovars
	}
	else {
		local endogenous : list uniq endogenous				// Check for duplicates
		local num_endo : word count `endogenous'			// Should not have quotes otherwise will return 1
	}
	
	sreturn local allinst "`exogvars' `extinst'"
	sreturn local endovars "`endogenous'"
	sreturn local auxdepvars "`auxdepvars'"
	sreturn local nocons1 "`nocons1'"
	
	sreturn local num_endo `num_endo'
	sreturn local num_aux `num_aux'
	sreturn local options `options'
end

program define parse_subopt_noconstant, rclass
	syntax [anything], [noCONstant * ]
	if ("`options'"!="") {
		di as err "suboption(s) {bf:`options'} not allowed in option {bf:auxiliary()}"
		exit 198
	}
	
	return local constant "`constant'"
end



program define iden_check_and_fvexpand_1, rclass
	syntax, allinst(varlist fv ts) touse(name) [wgt(name) DIFFicult_vce noCONstant]
	
	* Auxiliary model
	cap noi _rmcoll `allinst' if `touse', expand `constant' noskipline		// Note: all instruments are shared between the auxiliary models
	if _rc {
		error _rc
	}
	
	local vlist "`r(varlist)'"
	
	* Recording the position of variables flagged for omission
	// Constants are never flagged for omission. Since we focus on the variables that are flagged here, we don't need to worry about constants.
	tempname temp allinst_omit
	
	// "`allinst'" can obviously never be an empty string, so we do not need to worry about the problem explained below
	matrix `temp' = J(1, wordcount("`vlist'"), 1)
	matrix colnames `temp' = `vlist'
	_ms_omit_info `temp'
	matrix `allinst_omit' = `temp' - r(omit)
	
	return local allinst "`vlist'"
	return matrix allinst_omit = `allinst_omit'
end

program define iden_check_and_fvexpand_2, rclass
	syntax, [lhs(varname ts) exog(varlist fv ts) endo(varlist ts) touse(name) wgt(name) DIFFicult_vce noCONstant]
	
	* Primary model
	cap noi _rmcoll `lhs' `endo' `exog' if `touse', touse(`touse') logit expand `constant' noskipline
	if _rc {						// Using c(rc), which means `=_rc', also works
		error _rc
	}
	
	// Note: putting the exogenous variables at the end instead prioritizes them for omission.
	// -logit- is an undocumented option of -_rmcoll-. Like ivprobit.ado, I use it here too.
	// I use -_rmcoll, logit- instead of -_rmdcoll- and -_rmcoll- separately because -_rmdcoll- does not allow the option -touse()-.

	* Extract the exogenous controls post-flagging
	local vlist "`r(varlist)'"			// `r(varlist)' is technically not a macro but is usually (not always) treated as such by Stata. Verbose here for safety just in case.
	gettoken lhs vlist : vlist
	extract_varlist, small(`endo') big(`vlist')
	local endo `r(small)'
	local vlist `r(big)'
	local exog : copy local vlist

	* Disallow dropping endogenous variables
	checkifdropped, vars(`endo')
	
	* Recording the position of variables flagged for omission
	// Constants are never flagged for omission. Since we focus on the variables that are flagged here, we don't need to worry about constants.
	tempname temp exog_omit
	
	// Annoyingly, void matrices are allowed in Mata but not Stata, so I need to work around this.
	if ("`exog'" != "") {
		matrix `temp' = J(1, wordcount("`exog'"), 1)		// Annoyingly, -_ms_omit_info- only works with matrices
		matrix colnames `temp' = `exog'
		_ms_omit_info `temp'
		matrix `exog_omit' = `temp' - r(omit)				// r(omit) from -_ms_omit_info- uses 1 to represent omission; we want it the other way round for Mata
	}
	
	return local exog "`exog'"
	if ("`exog'" != "") {
		return matrix exog_omit = `exog_omit'
	}
end

program define extract_varlist, rclass
	syntax, small(string) big(string)
	
	local n : list sizeof small
	local small							// Clear this local macro since it is not empty
	forval i = 1/`n' {
		gettoken v big : big
		local small `small' `v'
	}
	
	return local small `small'
	return local big `big'
end

program define checkifdropped		// Adapted from ivprobit.ado
	syntax, vars(string)

	while "`vars'" != "" {
		gettoken var vars : vars
		_ms_parse_parts `var'			// Parses the matrix stripe `var' and returns the token parts in r()

		if r(omit) {					// From _ms_parse_parts
			di as err "tried to drop an endogenous variable, which is not allowed"
			exit 498
		}
	}
end



program define init_values_1, rclass		// First stage
	syntax [anything][if][in]							///
					 [fweight iweight pweight aweight], ///
					 [									///
					 noCONstant 						///
					 predictvars(string)				///
					 order(integer 1)					///
					 SHOWstages							///
					 ]
		
		marksample touse 	
		if ("`weight'" != "") {
			local wgt [`weight'`exp']
		}
		
		tempname param_est
		if ("`showstages'" == "") {
			local qui quietly
		}
		`qui' regress `anything' if `touse' `wgt', `constant'
		
		matrix `param_est' = e(b)		// e(b) from -regress- DOES NOT have the format "depvar: ...", so we must change the format
		reformat_params					// (Renaming the columns is unnecessary because -from()- extracts positionally and ignores names.)
		local yparam "`r(yparam)'"
		
		tempvar prediction
		qui predict double `prediction' if `touse', resid
		forval p = 1/`order' {
			local predictvar_`p' : word `p' of `predictvars'
			qui replace `predictvar_`p'' = `prediction'^`p'
		}
		
		return matrix param_est = `param_est'
		return local yparam "`yparam'"
end

program define init_values_2, rclass		// Second stage
	syntax [anything][if][in]							///
					 [fweight iweight pweight aweight], ///
					 [									///
					 noCONstant 						///
					 SHOWstages							///
					 ]
					 
		marksample touse
		if ("`weight'" != "") {
			local wgt [`weight'`exp']
		}
		
		tempname param_est
		if ("`showstages'" == "") {
			local qui quietly
		}
		`qui' cloglog `anything' if `touse' `wgt', `constant'
		
		matrix `param_est' = e(b)		// e(b) from -cloglog- DOES have the format "depvar: ..."
		local yparam: colfullnames e(b)

		return matrix param_est = `param_est'
		return local yparam "`yparam'"
		return local ll = e(ll)
		return local ll_0 = e(ll_0)
		return local ic = e(ic)
		return local rc = e(rc)
		return local converged = e(converged)
end 

program define reformat_params, rclass
	syntax [anything], [subtract(string)]
	
	local paramy: colfullnames e(b)
	local yvar "`e(depvar)'"
	
	foreach var in `paramy' {
		local yparam "`yparam' `yvar':`var'"
	}

	return local yparam "`yparam'"
end



mata:
//% Subroutine to get VCE
void calc_vce(string scalar y, string scalar x, string scalar z,							///
				string scalar resid_powerm1s_combo,											///
				string scalar resid_combo, real scalar order,								///
				string scalar point_est, string scalar touse, string scalar clustervar,		///
				string scalar nocon1, string scalar nocon2, string scalar vcename,			///
				string scalar omit1, string scalar omit2)
{	//% Type declarations (what types these objects *initially* are)
	real matrix temp_mat, X, Z, R1, info, g1_c, g2_c, g_c, Omega, vhat_powerm1s_combo_rump, vhat_powerm1s_eq, H_OLS, G_11, G_21_eq, G_21, G_22, V
	real rowvector X_omit, Z_omit,  multiZ_omit, ZX_omit, temp_b, b, rho_rump, rho_eq
	real colvector y1, Xb, expXb, r1, r2, cvar, d, d_tilde_eq
	real scalar n, num_endo, k_multiZ, k_multiZ_orig, nc, k_X, k_ZX, eq, orderm1
	
	//% Set up matrices (representing the data)
	// Note: st_data ignores factor variables with any omitted levels.
	// It treats all levels as omitted, even ones with the omission operator "o", setting all their columns to zero!
	st_view(y1=., ., y, touse)					// Used "y" rather than "y1" as argument to avoid conflict
	
	st_view(temp_mat=., ., x, touse)			// Need "temp" because identical arguments not allowed
	X_omit = st_matrix(omit2)
	st_select(X, temp_mat, X_omit)
	
	st_view(temp_mat=., ., z, touse)
	Z_omit = st_matrix(omit1)
	st_select(Z, temp_mat, Z_omit)
	
	st_view(R1=., ., resid_combo, touse)		// Matrix of auxiliary model residuals
	
	n = rows(X)									// All variables should have the same number of observations, conditioning on `touse'
	
	// Add vector of ones to X and Z if constant requested.
	// cross()/quadcross() can automatically do this for you, but this way is more readable.
	if (nocon1 == "") {
		Z = Z, J(n, 1, 1)
		Z_omit = (Z_omit, 1)
	}
	
	if (nocon2 == "") {
		X = X, J(n, 1, 1)
		X_omit = (X_omit, 1)
	}
	
	
	
	//% Set up vectors (representing parameter estimates)
	// Need to transpose because the estimates are inputted as `F', a row vector
	num_endo = cols(R1)
	k_multiZ = cols(Z) * num_endo					// Defined in a SUR style; each instrument is counted once per eq. This makes intuitive sense if you consider having different instruments for each eq.
	k_multiZ_orig = cols(Z_omit) * num_endo
	temp_b = st_matrix(point_est)[|k_multiZ_orig+1 \ .|]
	st_select(b, temp_b, X_omit)
	b = b'
	// Reminder: range subscripts are faster than list subscripts for subsetting a contiguous matrix (larger than 1x1)
	// Reminder: "..." is not allowed for Mata matrix/vector subsetting
	
	
	
	//% Omega (meat in the sandwich formula)
	// We need to average the moment functions within each cluster to get the monent functions
	st_view(cvar=., ., clustervar, touse)
	info = panelsetup(cvar, 1)											// Note: the other data must be in the same order as clustervar (which is true by default)
	nc = rows(info)
	k_X = cols(X)
	k_ZX = k_multiZ + k_X
	
	// Primary model, Part 1
	Xb = X*b
	expXb = exp(Xb)
	r2 = mm_cond(y1, exp(Xb - expXb) :/ (-expm1(-expXb)), -expXb)		// Not true residuals but pseudo-residuals

	// Make by-cluster superobservations and then we can get the "robust SE"-style Gram matrix
	g1_c = J(nc, 0, 0)
	for (eq=1; eq<=num_endo; eq++) {
		r1 = R1[., eq]								// Residuals corresponding to auxiliary equation #eq
		g1_c = (g1_c, panelsum(Z, r1, info))		// "c" here means summed within cluster (with R1 as the weights)
	}
	g2_c = panelsum(X, r2, info)
	g_c = (g1_c, g2_c)
	Omega = quadcross(g_c, g_c)
	
	
	
	//% G_inv (bread in the sandwich formula); G = (G_11, G_12 \ G_21, G_22)
	//% G_11
	H_OLS = -quadcross(Z, Z)		// Minus sign in this Hessian comes from maximizing the negative of the OLS objective function
	G_11 = I(num_endo) # H_OLS		// Used Kronecker product operator; could probably be optimized by using a loop with blockdiag() instead
	
	//% G_12 is just a zero matrix
		
	//% G_21
	d = mm_cond(y1,														///
				r2 :* (expm1(Xb) + exp(-expXb)) :/ expm1(-expXb),		///
				-expXb)
	// d is a vector of values "C_i", defined in the gmm moment evaluator function.
	// I changed the notation here to avoid confusion since "c" was already used above.
	
	if (order > 1) {
		st_view(vhat_powerm1s_combo_rump, ., resid_powerm1s_combo, touse)					// This contain the rest when we partition off a subvector from the front (like -gettoken-)
	}
	
	orderm1 = order - 1
	
	// rho_rump is defined similarly to the above. (Also, order*num_endo is the size of rho)
	if (nocon2 == "") {
		rho_rump = b[|k_X-order*num_endo \ k_X-1|]
	}
	else {
		rho_rump = b[|k_X-order*num_endo+1 \ .|]
	}
	
	G_21 = J(k_X, 0, .)																		// Initialize as zero-column matrix so it can be used in the loop
	for (eq=1; eq<=num_endo; eq++) {
		if (order > 1) {
			vhat_powerm1s_eq = vhat_powerm1s_combo_rump[|1, 1 \ ., orderm1|]
			if (eq < num_endo) {
				vhat_powerm1s_combo_rump = vhat_powerm1s_combo_rump[|1, order \ ., .|]		// Only take the rest if that actually exists
			}
			vhat_powerm1s_eq = J(n, 1, 1), vhat_powerm1s_eq									// v^(p-1), p = 1, ...
		}
		else {
			vhat_powerm1s_eq = J(n, 1, 1)
		}
		
		rho_eq = rho_rump[|1 \ order|]
		if (eq < num_endo) {
			rho_rump = rho_rump[|order+1 \ .|]												// Only take the rest if that actually exists
		}
		d_tilde_eq = -d :* (vhat_powerm1s_eq * rho_eq)
		G_21_eq = quadcross(X, d_tilde_eq, Z)
		G_21 = (G_21, G_21_eq)
	}
	
	//% G_22
	G_22 = quadcross(X, d, X)
	
	
	
	//% V
	// I use -lusolve()- rather than actually inverting G because this is more efficient.
	// In addition, I use 0 tolerance because we already checked for collinearity with -_rmcoll-.
	// Changing the tolerance is important because the data matrix might pass the -_rmcoll- collinearity check but
	// fail the built-in collinearity check in -lusolve()-.
	V = lusolve_special(G_11, G_21, G_22, lusolve_special(G_11, G_21, G_22, Omega, 0)', 0)		// Would be more efficient to reuse the L and U instead of doing the same LU decomposition twice
	
	// This V is currently actually only the VCE for the non-omission-flagged variables
	multiZ_omit = J(1, 0, .)
	for (eq=1; eq<=num_endo; eq++) {
		multiZ_omit = (multiZ_omit, Z_omit)
	}
	ZX_omit = (multiZ_omit, X_omit)
	V = insert_col_cons(V, ZX_omit, 0)
	V = insert_col_cons(V', ZX_omit, 0)
	V = makesymmetric(V)
	st_matrix(vcename, V)
}

//% Subroutine similar to -lusolve()- that exploits the block lower triangular nature of G
real matrix lusolve_special(real matrix A1, real matrix A3, real matrix A4,		///
							real matrix B, real scalar tolerance)
{
	//% Type declarations
	real matrix B1, B2, B3, B4, X1, X2, X3, X4, X
	real scalar m1, n1
	
	//% Main code
	m1 = rows(A1)
	n1 = cols(A3)
	
	B1 = B[|1, 1 \ m1, n1|]
	B2 = B[|1, n1+1 \ m1, .|]
	B3 = B[|m1+1, 1 \ ., n1|]
	B4 = B[|m1+1, n1+1 \ ., .|]
	
	X1 = lusolve(A1, B1, tolerance)
	X2 = lusolve(A1, B2, tolerance)
	X3 = lusolve(A4, B3-A3*X1, tolerance)
	X4 = lusolve(A4, B4-A3*X2, tolerance)
	X = (X1, X2 \ X3, X4)
	return(X)
}

//% Subroutine that inserts columns of a constant in a matrix corresponding to the 0s in a specified vector
real matrix insert_col_cons(real matrix M, real matrix v, real scalar cons)
{
	//% Type declarations
	real matrix R, temp
	real scalar end_num_cols, num_rows, i
	
	//% Main code
	end_num_cols = cols(v)
	num_rows = rows(M)
	
	R = J(num_rows, end_num_cols, cons)						// Easier to start with matrix of constants with final dimensions than to "expand" the original matrix 
	temp = M, J(num_rows, 1, 0)								// Hacky buffer to prevent the loop from breaking at the last column of M
	
	for (i=1; i<=end_num_cols; i++) {
		if (v[i] == 1) {
			R[., i] = temp[., 1]
			temp = temp[|1, 2 \ ., .|]
		}
	}
	
	return(R)
}
end



program ivcloglog_out		// Modified version of -GMMout- from gmm.ado
	syntax [, level(cilevel) COEFLegend selegend *]
	
	_get_diopts diopts, `coeflegend' `selegend' `options'
	
	local EXPRESSION = 1
	local PROGRAM = 2
	local robust
	local hac
	local bs
	if bsubstr("`e(vcetype)'", 1, 6) == "Robust" | "`e(clustvar)'" != "" {
			local robust "yes"
	}
	
	if bsubstr(`"`e(vcetype)'"', 1, 9) == "Bootstrap" |		///
			bsubstr(`"`e(vcetype)'"', 1, 9) == "Jackknife" {
			local bs "yes"
	}
	
	local anyrobust 0
	
	display ""
	display "{bf:Two-step cloglog model with endogenous covariates}"
	display ""
	
	tempname left right
	.`left' = {}
	.`right' = {}
	local C1 "_col(1)"
	local C2 "_col(21)"
	local C3 "_col(43)"
	local C4 "_col(64)"
	
	.`left'.Arrpush `C1' as text "2nd-stage Wald chi2" `C2' "=" as res %14.2f e(chi2)
	.`left'.Arrpush `C1' as text "2nd-stage Wald DF" `C2' "=" as res %14.0fc e(df_m)
	.`left'.Arrpush `C1' as text "Prob > chi2" `C2' "=" as res %14.4f e(p)
	
	.`right'.Arrpush `C3' as text "Number of parameters" `C4' "=" as res %14.0fc e(k)
	.`right'.Arrpush `C3' as text "Number of obs" `C4' "=" as res %14.0fc e(N)
	.`right'.Arrpush `C3' as text "Log-likelihood" `C4' "=" as res %14.2f e(ll)
	
	local nl = `.`left'.arrnels'
	local nr = `.`right'.arrnels'
	local k = max(`nl', `nr')
	forvalues i = 1/`k' {
			di as text `.`left'[`i']' as text `.`right'[`i']'
	}
	
	di
	
	_coef_table, level(`level') `diopts'		// Stealthily uses e(vcetype), e(N_clust), and e(clustvar)
	di in smcl "{p 0 4 4}{txt}Instruments: {res}`e(inst)'{p_end}"
	ml_footnote
end

program define drop_cfvars
	syntax anything, orig_varlist(varlist) [NOGENerate *]
	
	if "`nogenerate'" != "" {
		keep `orig_varlist'
		// Yes, -nogenerate- is a misnomer because we do actually generate the powers of vhat. But, to be fair, that's also true for Stata tempvars.
		// We do this because it's easier than renaming the columns of ("column-restriping") the matrix holding the coefficient estimates,
		// which is necessary to make the powers of vhat be called "`vhatname'`i'_`p'".
	}
end