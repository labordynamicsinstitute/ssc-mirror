*! nehurdle v2.0.0
*! 23 Sept. 2024
*! Alfonso Sanchez-Penalver
*! Version history at the bottom

/*******************************************************************************
*	Program to estimate tobit, normal, lognormal, poisson and negative binomial*
*	truncated hurdle, and type II tobit models via maximum likelihood for data *
*	with lower bound at 0.													   *
********************************************************************************/

capture program drop nehurdle
program define nehurdle, byable(onecall) properties(svyb svyj svyr)
	version 11
	if replay() {
		if "`e(cmd)'" != "nehurdle"	{
			di as error "Your previous estimation command was not {bf: nehurdle}"
			exit 301
		}
		if _by() error 190
		Replay `0'
	}
	else {
		global neh_cmdline "`0'"
		
		syntax varlist(min=1 numeric fv) [if] [in] [fweight pweight iweight]	///
		[, {																	///
			TRunc		|														///
			TObit		|														///
			HEckman		|														///
			truncp		|														///
			truncnb1	|														///
			truncnb2															///
			} *																	///
		]
		
		
		if _by() local by "by `_byvars' `byrc0':"
		
		if "`tobit'" != ""														///
			`by' nehurdle_est_tobit `0'
		else if "`heckman'" != ""												///
			`by' nehurdle_est_heckman `0'
		else if "`truncp'" != ""												///
			`by' nehurdle_est_truncp `0'
		else if "`truncnb1'" != "" | "`truncnb2'" != ""							///
			`by' nehurdle_est_truncnb `0'
		else																	///
			`by' nehurdle_est_trunc `0'
	}
end

/*------------------------------------------------------------------------------

	DISPLAY PROGRAMS

------------------------------------------------------------------------------*/

// HEADER
capture program drop nehurdle_display_header
program define nehurdle_display_header
	if "`e(chi2)'" == "." 														///
		local ov_txt "{help j_robustsingular##|_new:Wald chi2(`e(df_m)')}"
	else 																		///
		local ov_txt "Wald chi2({bf:`e(df_m)'})"
	if ("`e(vce)'" != "oim" & "`e(vce)'" != "opg") | "`e(cmd_opt)'" ==			///
		"twopart" local lltext "Log Pseudolikelihood"
	else local lltext "Log Likelihood"
	
	// Displaying
	di as text "`e(title)'" _col(49) as text "Number of Obs." _col(67) "= "		///
		_col(69) as result %9.0g e(N)
	di as text _col(49) as text "Censored Obs." _col(67) "= " _col(69) as		///
		result %9.0g e(N_c)
	di as text _col(49) as text "Uncensored Obs." _col(67) "= " _col(69) as		///
		result %9.0g (e(N) - e(N_c))
	di ""
	di _col(49) as text "`ov_txt'" _col(67) "= " _col(69) as result %9.2f		///
		e(chi2)
	di _col(49) as txt "Prob > chi2" _col(67) "= " _col(69) as result %9.4f		///
		e(p)
	di as txt "`lltext'" _col(22) "= " as result %12.3f e(ll) _col(49) as txt	///
		"Pseudo R-squared" _col(67) "= " _col(69) as result %9.4f e(r2)
	di ""
end

// REPLAY
capture program drop Replay
program define Replay
	syntax [, Level(cilevel) noHEader COEFLegend]
	
	di ""
	if "`header'" != "noheader"													///
		nehurdle_display_header
	ml display, level(`level') noheader `coeflegend'
	if "`e(lrstat)'" != "" {
		// Display the results of the LR test. This only happens with an NB model
		di as txt "LR test of alpha=0: {help j_chibar##j_new:chibar(01)} = "	///
			as result %10.2f e(lrstat) _col(55) as txt "Prob >= chibar2 = "		///
			as result %6.4f e(lrpval)
	}
end

/*------------------------------------------------------------------------------

	PARSING

------------------------------------------------------------------------------*/
capture program drop parse_select_opts
program define parse_select_opts, sclass
	syntax [varlist(numeric fv default=none)]									///
	[	,																		///
		noCONstant																///
		HET(varlist numeric fv)													///
		OFFset(passthru)														///
		EXPosure(passthru)														///
	]
	
	sreturn local vars `varlist'
	sreturn local constant `constant'
	sreturn local het `het'
	sreturn local off `offset'
	sreturn local exp `exposure'
end

capture program drop parse_het_opts
program define parse_het_opts, sclass
	syntax varlist(numeric fv)													///
	[,																			///
		noCONstant																///
	]
	
	sreturn local vars `varlist'
	sreturn local constant `constant'
end

/*------------------------------------------------------------------------------

	ESTIMATORS

------------------------------------------------------------------------------*/

// TRUNCATED HURDLE
capture program drop nehurdle_est_trunc
program define nehurdle_est_trunc, eclass byable(recall) sortpreserve
	syntax varlist(numeric fv) [if] [in] [fweight pweight iweight]				///
	[,																			///
		TRunc																	///
		SELect(string)															///
		HET(string)																///
		noHEader																///
		EXPONential																///
		COEFLegend																///
		noLOg																	///
		noCONStant																///
		vce(passthru)															///
		Level(passthru)															///
		OFFset(passthru)														///
		EXPosure(passthru)														///
		NRTOLerance(real 1e-12) *												///
	]
	
	// Temporary variables and names
	tempvar y1 dy res res2
	tempname b b1 coeff varcov
	
	// Marking the sample
	marksample touse
	quiet count if `touse'
	if `r(N)' == 0 error 2000

	// Checking syntax of ml options
	mlopts mlopts, nrtolerance(`nrtolerance') `options'
	local cns `s(constraints)'
	
	gettoken y x : varlist
	quiet gen double `y1' = `y'
	_fv_check_depvar `y1'
	
	quiet gen double `dy' = `y1' > 0
	
	// The user may have passed the explanatory variables for the selection
	// equation
	if "`select'" != "" {
		parse_select_opts `select'
		if "`s(vars)'" != "" 													{
			local selvars `s(vars)'
			local z `s(vars)'
		}
		else																	///
			local z `x'
		local selcons `s(constant)'
		local selhet `s(het)'
		local seloff `s(off)'
		local selexp `s(exp)'
	}
	else local z `x'
	
	if "`het'" != "" {
		parse_het_opts `het'
		local hetvars `s(vars)'
		local hetcons `s(constant)'
	}
	
	if "`weight'" != "" local wgt "[`weight' `exp']"
	
	// markout missing values
	markout `touse' `selvars' `selhet' `hetvars'
	_vce_parse `touse', opt(Robust oim opg) argopt(CLuster): `wgt', `vce'
	
	if "`exponential'" != "" {
		// transform the dependent variable to logs and trick max likelihood
		quiet replace `y1' = ln(`y1')
		local valname "ln`y'"
		// Set other string values
		local title "Lognormal Hurdle"
		global neh_method "exponential"
	}
	else {
		local valname "`y'"
		local title "Normal Truncated Hurdle"
		global neh_method "linear"
	}
	
	// Initial values
	// Estimates for selection equation
	quiet probit `dy' `z' if `touse' `wgt', `selcons'
	mat `b1' = e(b)
	mat coleq `b1' = selection
	mat `b' = `b1'
	// Estimates for selection heteroskedasticity
	if "`selhet'" != "" {
		quiet predict double `res', pr
		quiet replace `res' = ln((`dy' - `res')^2)
		quiet regress `res' `selhet' if `touse' `wgt', noconstant
		mat `b1' = e(b)
		mat coleq `b1' = sellnsigma
		mat `b' = `b', `b1'
	}
	// Estimates for value equation
	quiet reg `y1' `x' if `dy' & `touse' `wgt', `constant'
	mat `b1' = e(b)
	mat coleq `b1' = `valname'
	mat `b' = `b', `b1'
	// Estimates for value heteroskedasticity
	if "`het'" != "" {
		quiet predict double `res2', res
		quiet replace `res2' = ln(`res2'^2)
		quiet regress `res2' `hetvars' if `touse' `wgt', `hetcons'
		mat `b1' = e(b)
		mat coleq `b1' = lnsigma
	}
	else {
		mat `b1' = (ln(e(rmse)))
		mat colnames `b1' = lnsigma:_cons
	}
	mat `b' = `b' , `b1'
	
	if "`het'" != "" local anci = 0
	else {
		// To display the actual value for sigma
		local diparm diparm(lnsigma, exp label("sigma"))
		local anci = 1
	}
	
	// If there is a selection heteroskedasticity equation we need a different
	// likelihood valuator
	if "`selhet'" == "" {
		ml model lf2 nehurdle_trunc												///
			(selection: `dy'=`z', `selcons' `seloff' `selexp')					///
			(`valname':	 `y1'=`x', `constant' `offset' `exposure')				///
			(lnsigma: `het')													///
			if `touse' `wgt', `log' `mlopts' `vce' init(`b') missing `diparm'	///
			waldtest(-3) nopreserve maximize
	}
	else {
		ml model lf2 nehurdle_trunc_het											///
			(selection: `dy'=`z', `selcons' `seloff' `selexp')					///
			(`valname':	 `y1'=`x', `constant' `offset' `exposure')				///
			(sellnsigma: `selhet', noconstant)									///
			(lnsigma: `het')													///
			if `touse' `wgt', `log' `mlopts' `vce' init(`b') missing `diparm'	///
			waldtest(-4) nopreserve maximize
	}
	
	// Censored observations
	quiet sum `dy' if !`dy' & `touse', mean
	local numcen = r(N)
	
	// Tests of joint signficance
	if "`e(chi2)'" == "." {
		// Selection
		ereturn scalar sel_chi2 = .
		ereturn scalar sel_p = .
		ereturn scalar sel_df = .
		// Value
		ereturn scalar val_chi2 = .
		ereturn scalar val_p = .
		ereturn scalar val_df = .
		// Selection Heteroskedasticity
		if "`selhet'" != "" {
			ereturn scalar selhet_chi2 = .
			ereturn scalar selhet_p = .
			ereturn scalar selhet_df = .
		}
		// Heteroskedasticity
		if "`het'" != "" {
			ereturn scalar het_chi2 = .
			ereturn scalar het_p = .
			ereturn scalar het_df = .
		}
	}
	else {
		// Selection
		if "`z'" != "" {
			quiet testparm `z', eq(#1)
			ereturn scalar sel_chi2 = r(chi2)
			ereturn scalar sel_p = r(p)
			ereturn scalar sel_df = r(df)
		}
		// Value
		if "`x'" != "" {
			quiet testparm `x', eq(#2)
			ereturn scalar val_chi2 = r(chi2)
			ereturn scalar val_p = r(p)
			ereturn scalar val_df = r(df)
		}
		// Selection Heteroskedasticity
		if "`selhet'" != "" {
			quiet testparm `selhet', eq(#3)
			ereturn scalar selhet_chi2 = r(chi2)
			ereturn scalar selhet_p = r(p)
			ereturn scalar selhet_df = r(df)
			// Hetersokedasticity
			if "`het'" != "" {
				quiet testparm `hetvars', eq(#4)
				ereturn scalar het_chi2 = r(chi2)
				ereturn scalar het_p = r(p)
				ereturn scalar het_df = r(df)
			}
		}
		else if "`het'" != "" {
			quiet testparm `hetvars', eq(#3)
			ereturn scalar het_chi2 = r(chi2)
			ereturn scalar het_p = r(p)
			ereturn scalar het_df = r(df)
		}
	}

	ereturn local neh_cmdline = "nehurdle $neh_cmdline"
	if "`exponential'" != "" 													///
		ereturn local est_model = "exponential"
	else ereturn local est_model = "linear"
	macro drop neh_cmdline neh_method
	if "`het'" == ""  ereturn scalar sigma = exp(_b[lnsigma:_cons])
	ereturn local het "`het'"
	ereturn local selhet "`selhet'"
	ereturn local title "`title'"
	ereturn local cmd_opt "trunc"
	// ereturn local marginsok = "XB default"
	ereturn local depvar = "`y'"
	ereturn scalar N_c = `numcen'
	ereturn scalar k_aux = `anci'
	ereturn local predict "nehurdle_p"
	ereturn local cmd = "nehurdle"
	// Predicting censored mean and calculating pseudo r-squared
	tempvar yhat zg selsig sig
	quiet {
		_predict double `zg' `if' `in', equation(#1)
		_predict double `yhat' `if' `in', equation(#2)
		if "`selhet'" != "" {
			_predict double `selsig' `if' `in', equation(#3)
			replace `selsig' = exp(`selsig') `if' `in'
			_predict double `sig' `if' `in', equation(#4)
		}
		else {
			generate double `selsig' = 1 `if' `in'
			_predict double `sig' `if' `in', equation(#3)
		}
		replace `sig' = exp(`sig')
		if "`exponential'" == ""												///
			replace `yhat' = `yhat' + `sig' * normalden(`yhat' / `sig') 		///
			/ normal(`yhat' / `sig') `if' `in'
		else replace `yhat' = exp(`yhat' + `sig'^2 / 2) `if' `in'
		replace `yhat' = normal(`zg' / `selsig') * `yhat' `if' `in'
	}
	capture correl `y' `yhat'
	ereturn scalar r2 = r(rho)^2
	// Display
	Replay, `level' `header' `coeflegend'
end

// TOBIT
program define nehurdle_est_tobit, eclass byable(recall) sortpreserve
	syntax varlist(numeric fv) [if] [in] [fweight pweight iweight],				///
		TObit																	///
		[																		///
			HET(string)															///
			noHEader															///
			EXPONential															///
			noLOg																///
			noCONStant															///
			COEFLegend															///
			vce(passthru)														///
			Level(passthru)														///
			OFFset(passthru)													///
			EXPosure(passthru)													///
			NRTOLerance(real 1e-12) *											///
		]
	
	tempvar y1 res2
	tempname b b1 coeff varcov
	marksample touse
	quiet count if `touse'
	if `r(N)' == 0 error 2000

	// Checking syntax of ml options
	mlopts mlopts, nrtolerance(`nrtolerance') `options'
	local cns `s(constraints)'
	
	// parse the varlist
	gettoken y x : varlist
	quiet gen double `y1' = `y'
	_fv_check_depvar `y1'
	
	if "`het'" != "" {
		parse_het_opts `het'
		local hetvars `s(vars)'
		local hetcons `s(constant)'
	}
	
	if "`weight'" != "" local wgt "[`weight' `exp']"
	
	// markout missing values
	markout `touse' `selection' `hetvars'
	_vce_parse `touse', opt(Robust oim opg) argopt(CLuster): `wgt', `vce'
	
	if "`exponential'" != "" {
		quiet replace `y1' = ln(`y1')
		quiet sum `y1', mean
		local gamma = r(min) - 1e-7
		quiet regress `y1' `x' if `touse' `wgt', `constant'
		global neh_method "exponential"												// This is set to use with the ml evaluator
		local etitle "Lognormal "
		local ytit "ln`y'"
	}
	else {
		quiet regress `y1' `x' if `y' > 0 & `touse' `wgt', `constant'
		global neh_method "linear"													// This is set to use with the ml evaluator
		local etitle "Normal "
		local ytit "`y'"
	}
	local numuncen = e(N)
	mat `b' = e(b)
	mat coleq `b' = `ytit'
	
	// Get estimates for heteroskedasticity
	if "`het'" != "" {
		quiet predict `res2', res
		quiet replace `res2' = ln(`res2'^2)
		quiet regress `res2' `hetvars' if `touse' `wgt', `hetcons'
		mat `b1' = e(b)
		mat coleq `b1' = lnsigma
	}
	else {
		mat `b1' = (ln(e(rmse)))
		mat colnames `b1' = lnsigma:_cons
	}
	mat `b' = `b', `b1'
	
	// To display the actual value for sigma
	if "`het'" != "" local anci = 0
	else {
		// To display the actual value for sigma
		local diparm diparm(lnsigma, exp label("sigma"))
		local anci = 1
	}
	
	// Estimation
	ml model lf2 nehurdle_tobit													///
		(`ytit': `y1'=`x', `constant' `offset' `exposure') (lnsigma: `het')		///
		if `touse' `wgt', `log' `mlopts' `vce' init(`b') missing `diparm'		///
		waldtest(-2) nopreserve maximize
	
	// Tests of joint signficance
	if "`e(chi2)'" == "." & "`het'" != "" {
		ereturn scalar val_chi2 = .
		ereturn scalar val_p = .
		ereturn scalar val_df = .
		
		ereturn scalar het_chi2 = .
		ereturn scalar het_p = .
		ereturn scalar het_df = .
	}
	else if "`het'" != "" {
		// Value
		quiet testparm `x', eq(#1)
		ereturn scalar val_chi2 = r(chi2)
		ereturn scalar val_p = r(p)
		ereturn scalar val_df = r(df)
	
		quiet testparm `hetvars', eq(#2)
		ereturn scalar het_chi2 = r(chi2)
		ereturn scalar het_p = r(p)
		ereturn scalar het_df = r(df)
	}
	local numcen = e(N) - `numuncen'
	
	ereturn local neh_cmdline = "nehurdle $neh_cmdline"
	macro drop neh_cmdline neh_method
	if "`het'" == ""  ereturn scalar sigma = exp(_b[lnsigma:_cons])
	ereturn local het "`het'"
	if "`exponential'" != ""													///
		ereturn local est_model = "exponential"
	else ereturn local est_model = "linear"
	// ereturn local marginsok = "XB default"
	ereturn local title "`etitle'Tobit"
	ereturn local cmd_opt "tobit"
	ereturn local depvar = "`y'"
	ereturn scalar N_c = `numcen'
	ereturn scalar k_aux = `anci'
	if "`gamma'" != "" ereturn scalar gamma = `gamma'
	// Predicting censored mean to get the pseudo R-squared
	tempvar yhat sig
	quiet {
		_predict double `yhat' `if' `in', equation(#1)
		_predict double `sig' `if' `in', equation(#2)
		replace `sig' = exp(`sig') `if' `in'
		if "`exponential'" == "" {
			replace `yhat' = normal(`yhat'/`sig') *`yhat' + `sig' *				///
				normalden(`yhat' / `sig') `if' `in'
		}
		else {
			replace `yhat' = exp(`yhat' + (`sig'^2)/2) * normal((`sig'^2 +		///
				`yhat' - `gamma')/`sig') `if' `in'
		}
	}
	capture correl `y' `yhat'
	ereturn scalar r2 = r(rho)^2
	ereturn local predict "nehurdle_p"
	ereturn local cmd = "nehurdle"
	
	// Display
	Replay, `level' `header' `coeflegend'
end

// HECKMAN
capture program drop nehurdle_est_heckman
program define nehurdle_est_heckman, eclass byable(recall) sortpreserve
	syntax varlist(min=1 numeric fv) [if] [in] [fweight pweight iweight] ,		///
		HEckman																	///
		[																		///
			SELect(string)														///
			HET(string)															///
			noHEader															///
			EXPONential															///
			COEFLegend															///
			noLOg																///
			noCONStant															///
			vce(passthru)														///
			Level(passthru)														///
			OFFset(passthru)													///
			EXPosure(passthru)													///
			NRTOLerance(real 1e-12) *											///
		]
	// Temporary variables and names
	tempvar y1 dy res1 res1sq res2 res2sq
	tempname b b1 b2 coeff varcov ll0 chi2_c p_c
	
	gettoken y x : varlist
	quiet gen double `y1' = `y'
	_fv_check_depvar `y1'
	
	quiet gen double `dy' = `y1' > 0
	
	if "`select'" != "" {
		parse_select_opts `select'
		if "`s(vars)'" != "" {
			local selvars `s(vars)'
			local z `s(vars)'
		}
		else local z `x'
		local selcons `s(constant)'
		local selhet `s(het)'
		local seloff `s(off)'
		local selexp `s(exp)'
	}
	else local z `x'
	
	if "`het'" != "" {
		parse_het_opts `het'
		local hetvars `s(vars)'
		local hetcons `s(constant)'
	}
	// Marking the sample
	marksample touse
	quiet count if `touse'
	if `r(N)' == 0 error 2000

	// Checking syntax of ml options
	mlopts mlopts, nrtolerance(`nrtolerance') `options'
	local cns `s(constraints)'
	
	if "`weight'" != "" local wgt "[`weight' `exp']"
	
	// markout missing values
	markout `touse' `selvars' `selhet' `hetvars'
	_vce_parse `touse', opt(Robust oim opg) argopt(CLuster): `wgt', `vce'
	
	if "`exponential'" != "" {
		// transform the dependent variable to logs and trick max likelihood
		quiet replace `y1' = ln(`y1')	
		local valname "ln`y'"
		local title "Lognormal Type II Tobit"
		global neh_method "exponential"
	}
	else {
		local title "Normal Type II Tobit"
		local valname "`y'"
		global neh_method "linear"
	}
	
	// Initial values
	// Estimates for selection equation
	quiet probit `dy' `z' if `touse' `wgt', `selcons'
	mat `b1' = e(b)
	mat coleq `b1' = selection
	mat `b' = `b1'
	quiet predict double `res1', pr
	quiet replace `res1' = `dy' - `res1'
	// Estimates for selection heteroskedasticity
	if "`selhet'" != "" {
		quiet gen double `res1sq' = ln(`res1'^2)
		quiet regress `res1sq' `selhet' if `touse' `wgt', noconstant
		mat `b1' = e(b)
		mat coleq `b1' = sellnsigma
		mat `b' = `b', `b1'
	}
	// Estimates for value equation
	quiet reg `y1' `x' if `dy' & `touse' `wgt', `constant'
	mat `b1' = e(b)
	mat coleq `b1' = `valname'
	mat `b' = `b', `b1'
	quiet predict double `res2', res
	// Get estimates for heteroskedasticity of value equation
	if "`het'" != "" {
		quiet gen double `res2sq' = ln(`res2'^2)
		quiet regress `res2sq' `hetvars' if `dy' & `touse' `wgt', `hetcons'
		mat `b1' = e(b)
		mat coleq `b1' = lnsigma
	}
	else {
		mat `b1' = (ln(e(rmse)))
		mat colnames `b1' = lnsigma:_cons
	}
	mat `b' = `b' , `b1'
	
	// Use the correlation of the probit and regression residuals for the
	// initial value of correlation
	quiet corr `res1' `res2'
	if r(rho) < 0 local st = -0.5
	else local st = 0.5
	mat `b1' = atanh(`st')
	mat colnames `b1' = athrho:_cons
	mat `b' = `b' , `b1'
	
	// To display the actual values of the ancilliary parameters
	local dip2 diparm(athrho, tanh label("rho"))
	if "`het'" != "" local anci = 1
	else {
		local dip1 diparm(lnsigma, exp label("sigma"))
		local dip3 diparm(athrho lnsigma,										///
			func(exp(@2)*(exp(@1)-exp(-@1))/(exp(@1)+exp(-@1)))					///
			der(exp(@2)*(1-((exp(@1)-exp(-@1))/(exp(@1)+exp(-@1)))^2)			///
			exp(@2)*(exp(@1)-exp(-@1))/(exp(@1)+exp(-@1))) label("lambda"))
		local anci = 2
	}
	
	// If there is a selection heteroskedasticity equation we need a different
	// likelihood valuator
	if "`selhet'" == ""															///
		ml model lf2 nehurdle_heckman											///
			(selection: `dy'=`z', `selcons' `seloff' `selexp')					///
			(`valname':	 `y1'=`x', `constant' `offset' `exposure')				///
			(lnsigma: `het') (athrho:)											///
			if `touse' `wgt', `log' `mlopts' `vce' init(`b') missing `dip1'		///
			`dip2' `dip3' waldtest(-4) nopreserve maximize
	else																		///
		ml model lf2 nehurdle_heckman_het										///
			(selection: `dy'=`z', `selcons' `seloff' `selexp')					///
			(`valname':	 `y1'=`x', `constant' `offset' `exposure')				///
			(sellnsigma: `selhet', noconstant)									///
			(lnsigma: `het') (athrho:)											///
			if `touse' `wgt', `log' `mlopts' `vce' init(`b') missing `dip1'		///
			`dip2' `dip3' waldtest(-5) nopreserve maximize
	
	quiet sum `dy' if !`dy' & `touse'
	local numcen = r(N)
	
	// Tests of joint signficance
	if "`e(chi2)'" == "." {
		// Selection
		ereturn scalar sel_chi2 = .
		ereturn scalar sel_p = .
		ereturn scalar sel_df = .
		// Value
		ereturn scalar val_chi2 = .
		ereturn scalar val_p = .
		ereturn scalar val_df = .
		// Selection Heteroskedasticity
		if "`selhet'" != "" {
			ereturn scalar selhet_chi2 = .
			ereturn scalar selhet_p = .
			ereturn scalar selhet_df = .
		}
		// Heteroskedasticity
		if "`het'" != "" {
			ereturn scalar het_chi2 = .
			ereturn scalar het_p = .
			ereturn scalar het_df = .
		}
	}
	else {
		// Selection
		if "`z'" != "" {
			quiet testparm `z', eq(#1)
			ereturn scalar sel_chi2 = r(chi2)
			ereturn scalar sel_p = r(p)
			ereturn scalar sel_df = r(df)
		}
		// Value
		if "`x'" != "" {
			quiet testparm `x', eq(#2)
			ereturn scalar val_chi2 = r(chi2)
			ereturn scalar val_p = r(p)
			ereturn scalar val_df = r(df)
		}
		// Selection Heteroskedasticity
		if "`selhet'" != "" {
			quiet testparm `selhet', eq(#3)
			ereturn scalar selhet_chi2 = r(chi2)
			ereturn scalar selhet_p = r(p)
			ereturn scalar selhet_df = r(df)
			// Hetersokedasticity
			if "`het'" != "" {
				quiet testparm `hetvars', eq(#4)
				ereturn scalar het_chi2 = r(chi2)
				ereturn scalar het_p = r(p)
				ereturn scalar het_df = r(df)
			}
		}
		else if "`het'" != "" {
			quiet testparm `hetvars', eq(#3)
			ereturn scalar het_chi2 = r(chi2)
			ereturn scalar het_p = r(p)
			ereturn scalar het_df = r(df)
		}
	}
	
	ereturn local neh_cmdline "nehurdle $neh_cmdline"
	macro drop neh_cmdline neh_method
	if "`het'" == ""  ereturn scalar sigma = exp(_b[lnsigma:_cons])
	if "`exponential'" != "" ///
		ereturn local est_model "exponential"
	else ereturn local est_model "linear"
	ereturn local title "`title'"
	ereturn local cmd_opt "heckman"
	// ereturn local marginsok "XB default"
	ereturn local depvar "`y'"
	ereturn local het "`het'"
	ereturn local selhet "`selhet'"
	ereturn scalar rho = tanh(_b[athrho:_cons])
	if "`het'" == "" {
		ereturn scalar sigma = exp(_b[lnsigma:_cons])
		ereturn scalar lambda = exp(_b[lnsigma:_cons]) * tanh(_b[athrho:_cons])
	}
	ereturn scalar N_c = `numcen'
	ereturn scalar k_aux = `anci'
	// Predicting the censored mean and calculating the pseudo R-squared
	tempvar yhat zg selsig sig rho
	quiet {
		_predict double `zg' `if' `in', equation(#1)
		_predict double `yhat' `if' `in', equation(#2)
		if "`selhet'" != "" {
			_predict double `selsig' `if' `in', equation(#3)
			replace `selsig' = exp(`selsig') `if' `in'
			_predict double `sig' `if' `in', equation(#4)
			_predict double `rho' `if' `in', equation(#5)
		}
		else {
			generate double `selsig' = 1 `if' `in'
			_predict double `sig' `if' `in', equation(#3)
			_predict double `rho' `if' `in', equation(#4)
		}
		replace `sig' = exp(`sig') `if' `in'
		replace `rho' = tanh(`rho') `if' `in'
		if "`exponential'" == ""												///
			replace `yhat' = `yhat' + `sig' * `rho' * normalden(`zg' / `selsig') ///
				/ normal(`zg' / `selsig') `if' `in'
		else																	///
			replace `yhat' = exp(`yhat' + `sig'^2 / 2) * normal(`zg' / `selsig'	///
				+ `rho' * `sig') / normal(`zg' / `selsig') `if' `in'
		replace `yhat' = normal(`zg' / `selsig') * `yhat' `if' `in'
	}
	capture quiet correl `y' `yhat'
	ereturn scalar r2 = r(rho)^2
	ereturn local predict "nehurdle_p"
	ereturn local cmd "nehurdle"
	// Display
	di as txt ""
	Replay, `level' `header' `coeflegend'
end

// POISSON TRUNCATED HURDLE
capture program drop nehurdle_est_truncp
program define nehurdle_est_truncp, eclass byable(recall) sortpreserve
	syntax varlist(numeric fv) [if] [in] [fweight pweight iweight]				///
	[,																			///
		truncp																	///
		SELect(string)															///
		noHEader																///
		COEFLegend																///
		noLOg																	///
		noCONStant																///
		vce(passthru)															///
		Level(passthru)															///
		OFFset(passthru)														///
		EXPosure(passthru)														///
		NRTOLerance(real 1e-12) *												///
	]
	
	// Temporary variables and names
	tempvar y1 dy res res2
	tempname b b1 coeff varcov
	
	// Marking the sample
	marksample touse
	quiet count if `touse'
	if `r(N)' == 0 error 2000

	// Checking syntax of ml options
	mlopts mlopts, nrtolerance(`nrtolerance') `options'
	local cns `s(constraints)'
	
	gettoken y x : varlist
	quiet gen double `y1' = `y'
	_fv_check_depvar `y1'
	
	quiet gen double `dy' = `y1' > 0
	
	// The user may have passed the explanatory variables for the selection
	// equation
	if "`select'" != "" {
		parse_select_opts `select'
		if "`s(vars)'" != "" 													{
			local selvars `s(vars)'
			local z `s(vars)'
		}
		else																	///
			local z `x'
		local selcons `s(constant)'
		local selhet `s(het)'
		local seloff `s(off)'
		local selexp `s(exp)'
	}
	else local z `x'
	
	// Weights
	if "`weight'" != "" local wgt "[`weight' `exp']"
	
	// markout missing values
	markout `touse' `selvars' `selhet'
	// Parse the vce options
	_vce_parse `touse', opt(Robust oim opg) argopt(CLuster): `wgt', `vce'
	
	// Values for display
	local valname "`y'"
	local title "Poisson Truncated Hurdle"
	
	// Initial values
	// Estimates for selection equation
	quiet probit `dy' `z' if `touse' `wgt', `selcons'
	mat `b1' = e(b)
	mat coleq `b1' = selection
	mat `b' = `b1'
	// Estimates for selection heteroskedasticity
	if "`selhet'" != "" {
		quiet predict double `res', pr
		quiet replace `res' = abs(`dy' - `res')
		quiet regress `res' `selhet' if `touse' `wgt', noconstant
		mat `b1' = e(b)
		mat coleq `b1' = sellnsigma
		mat `b' = `b', `b1'
	}
	// Estimates for value equation
	tempvar lny
	quiet gen double `lny' = ln(`y1')
	quiet reg `lny' `x' if `dy' & `touse' `wgt', `constant'
	mat `b1' = e(b)
	mat coleq `b1' = `valname'
	mat `b' = `b', `b1'
	
	// If there is a selection heteroskedasticity equation we need a different
	// likelihood valuator
	if "`selhet'" == "" {
		ml model lf2 nehurdle_truncp											///
			(selection: `dy'=`z', `selcons' `seloff' `selexp')					///
			(`valname':	 `y1'=`x', `constant' `offset' `exposure')				///
			if `touse' `wgt', `log' `mlopts' `vce' init(`b') missing `diparm'	///
			waldtest(-2) nopreserve maximize
	}
	else {
		ml model lf2 nehurdle_truncp_het										///
			(selection: `dy'=`z', `selcons' `seloff' `selexp')					///
			(`valname':	 `y1'=`x', `constant' `offset' `exposure')				///
			(sellnsigma: `selhet', noconstant)									///
			if `touse' `wgt', `log' `mlopts' `vce' init(`b') missing `diparm'	///
			waldtest(-3) nopreserve maximize
	}
	
	// Censored observations
	quiet sum `dy' if !`dy' & `touse', mean
	local numcen = r(N)
	
	// Tests of joint signficance
	if "`e(chi2)'" == "." {
		// Selection
		ereturn scalar sel_chi2 = .
		ereturn scalar sel_p = .
		ereturn scalar sel_df = .
		// Value
		ereturn scalar val_chi2 = .
		ereturn scalar val_p = .
		ereturn scalar val_df = .
		// Selection Heteroskedasticity
		if "`selhet'" != "" {
			ereturn scalar selhet_chi2 = .
			ereturn scalar selhet_p = .
			ereturn scalar selhet_df = .
		}
	}
	else {
		// Selection
		if "`z'" != "" {
			quiet testparm `z', eq(#1)
			ereturn scalar sel_chi2 = r(chi2)
			ereturn scalar sel_p = r(p)
			ereturn scalar sel_df = r(df)
		}
		// Value
		if "`x'" != "" {
			quiet testparm `x', eq(#2)
			ereturn scalar val_chi2 = r(chi2)
			ereturn scalar val_p = r(p)
			ereturn scalar val_df = r(df)
		}
		// Selection Heteroskedasticity
		if "`selhet'" != "" {
			quiet testparm `selhet', eq(#3)
			ereturn scalar selhet_chi2 = r(chi2)
			ereturn scalar selhet_p = r(p)
			ereturn scalar selhet_df = r(df)
		}
	}

	ereturn local neh_cmdline = "nehurdle $neh_cmdline"
	macro drop neh_cmdline
	ereturn local selhet "`selhet'"
	ereturn local title "`title'"
	ereturn local cmd_opt "truncp"
	// ereturn local marginsok = "XB default"
	ereturn local depvar = "`y'"
	ereturn scalar N_c = `numcen'
	// ereturn scalar k_aux = `anci'
	ereturn local predict "nehurdle_p"
	ereturn local cmd = "nehurdle"
	
	// Predicting censored mean and calculating pseudo r-squared
	tempvar yhat lam psel selsig
	quiet {
		_predict `vtyp' `lam' `if' `in', equation(#2)
		replace `lam' = exp(`lam')
		_predict `vtyp' `psel' `if' `in', equation(#1)
		if "`selhet'" != "" {
			_predict `vtyp' `selsig' `if' `in', equation(#3)
			replace `selsig' = exp(`selsig') `if' `in'
		}
		else generate `vtyp' `selsig' = 1 `if' `in'
		replace `psel' = normal(`psel' / `selsig') `if' `in'
		generate `vtyp' `yhat' = `psel' * `lam' / (1 - exp(- `lam'))
	}
	capture correl `y' `yhat'
	ereturn scalar r2 = r(rho)^2
	// Display
	Replay, `level' `header' `coeflegend'
end

// NEGATIVE BINOMIAL TRUNCATED HURDLE
capture program drop nehurdle_est_truncnb
program define nehurdle_est_truncnb, eclass byable(recall) sortpreserve
	syntax varlist(numeric fv) [if] [in] [fweight pweight iweight]				///
	[,																			///
		{truncnb1 | truncnb2}													///
		SELect(string)															///
		HET(string)																///
		noHEader																///
		COEFLegend																///
		noLRTest																///
		noLOg																	///
		noCONStant																///
		vce(passthru)															///
		Level(passthru)															///
		OFFset(passthru)														///
		EXPosure(passthru)														///
		NRTOLerance(real 1e-12) *												///
	]
	
	// Temporary variables and names
	tempvar y1 dy res res2
	tempname b b1 coeff varcov
	
	// Marking the sample
	marksample touse
	quiet count if `touse'
	if `r(N)' == 0 error 2000

	// Checking syntax of ml options
	mlopts mlopts, nrtolerance(`nrtolerance') `options'
	local cns `s(constraints)'
	
	gettoken y x : varlist
	quiet gen double `y1' = `y'
	_fv_check_depvar `y1'
	
	quiet gen double `dy' = `y1' > 0
	
	// The user may have passed the explanatory variables for the selection
	// equation
	if "`select'" != "" {
		parse_select_opts `select'
		if "`s(vars)'" != "" 													{
			local selvars `s(vars)'
			local z `s(vars)'
		}
		else																	///
			local z `x'
		local selcons `s(constant)'
		local selhet `s(het)'
		local seloff `s(off)'
		local selexp `s(exp)'
	}
	else local z `x'
	
	if "`het'" != "" {
		parse_het_opts `het'
		local hetvars `s(vars)'
		local hetcons `s(constant)'
	}
	
	if "`weight'" != "" local wgt "[`weight' `exp']"
	
	// markout missing values
	markout `touse' `selvars' `selhet' `hetvars'
	_vce_parse `touse', opt(Robust oim opg) argopt(CLuster): `wgt', `vce'
	
	local valname "`y'"
	
	// Check with specification we want, and set the local macros accordingly
	if "`truncnb1'" != "" {
		local title "NB1"
		local spec "truncnb1"
	}
	else {
		local title "NB2"
		local spec "truncnb2"
	}
	local title "`title' Truncated Hurdle"
	
	// Initial values
	// Estimates for selection equation
	quiet probit `dy' `z' if `touse' `wgt', `selcons'
	mat `b1' = e(b)
	mat coleq `b1' = selection
	mat `b' = `b1'
	// Estimates for selection heteroskedasticity
	if "`selhet'" != "" {
		quiet predict double `res', pr
		quiet replace `res' = abs(`dy' - `res')
		quiet regress `res' `selhet' if `touse' `wgt', noconstant
		mat `b1' = e(b)
		mat coleq `b1' = sellnsigma
		mat `b' = `b', `b1'
	}
	tempvar lny
	quiet gen double `lny' = ln(`y1')
	quiet reg `lny' `x' if `dy' & `touse' `wgt', `constant'
	mat `b1' = e(b)
	mat coleq `b1' = `valname'
	mat `b' = `b', `b1'
	
	// Calculate these now in case the user wants the LR test
	if "`het'" != "" {
		quiet predict double `res2', res
		quiet replace `res2' = abs(`res2')
	}
	else {
		tempname lnsig
		scalar `lnsig' = ln(e(rmse))
	}
	
	// If lrtest is empty, estimate truncated poisson hurdle, get log-likelihood
	// and set the initial values.
	if "`lrtest'" == "" & "`het'" == "" & inlist("`vce'", "", "vce(oim)", "vce(opg)") {
		tempname ll0
		di as txt "Fitting Poisson truncated hurdle"
		if "`selhet'" == "" {
			ml model lf2 nehurdle_truncp										///
			(selection: `dy'=`z', `selcons' `seloff' `selexp')					///
			(`valname':	 `y1'=`x', `constant' `offset' `exposure')				///
			if `touse' `wgt', `log' `mlopts' `vce' init(`b') missing `diparm'	///
			waldtest(-2) nopreserve maximize
		}
		else {
			ml model lf2 nehurdle_truncp_het									///
			(selection: `dy'=`z', `selcons' `seloff' `selexp')					///
			(`valname':	 `y1'=`x', `constant' `offset' `exposure')				///
			(sellnsigma: `selhet', noconstant)									///
			if `touse' `wgt', `log' `mlopts' `vce' init(`b') missing `diparm'	///
			waldtest(-3) nopreserve maximize
		}
		// Get the log-likelihood for lr test and set b to e(b)
		scalar `ll0' = e(ll)
		mat `b' = e(b)
	}
	
	
	// Estimates for dispersion heterogeneity
	if "`het'" != "" {
		quiet regress `res2' `hetvars' if `touse' `wgt', `hetcons'
		mat `b1' = e(b)
		mat coleq `b1' = lnalpha
	}
	else {
		mat `b1' = (ln(e(rmse)))
		mat colnames `b1' = lnalpha:_cons
	}
	mat `b' = `b' , `b1'
	
	if "`het'" != "" local anci = 0
	else {
		// To display the actual value for alpha
		local diparm diparm(lnalpha, exp label("alpha"))
		local anci = 1
	}
	
	// if lrtest is empty, indicate we are now estimating the right model
	if "`lrtest'" == "" & "`het'" == "" & inlist("`vce'", "", "vce(oim)", "vce(opg)") {
		di ""
		di as txt "Fitting `title'"
	}
	// If there is a selection heteroskedasticity equation we need a different
	// likelihood valuator
	if "`selhet'" == "" {
		ml model lf2 nehurdle_`spec'											///
			(selection: `dy'=`z', `selcons' `seloff' `selexp')					///
			(`valname':	 `y1'=`x', `constant' `offset' `exposure')				///
			(lnalpha: `het')													///
			if `touse' `wgt', `log' `mlopts' `vce' init(`b') missing `diparm'	///
			waldtest(-3) nopreserve maximize
	}
	else {
		ml model lf2 nehurdle_`spec'_het										///
			(selection: `dy'=`z', `selcons' `seloff' `selexp')					///
			(`valname':	 `y1'=`x', `constant' `offset' `exposure')				///
			(sellnsigma: `selhet', noconstant)									///
			(lnalpha: `het')													///
			if `touse' `wgt', `log' `mlopts' `vce' init(`b') missing `diparm'	///
			waldtest(-4) nopreserve maximize
	}
	
	// Censored observations
	quiet sum `dy' if !`dy' & `touse', mean
	local numcen = r(N)
	
	// Tests of joint signficance
	if "`e(chi2)'" == "." {
		// Selection
		ereturn scalar sel_chi2 = .
		ereturn scalar sel_p = .
		ereturn scalar sel_df = .
		// Value
		ereturn scalar val_chi2 = .
		ereturn scalar val_p = .
		ereturn scalar val_df = .
		// Selection Heteroskedasticity
		if "`selhet'" != "" {
			ereturn scalar selhet_chi2 = .
			ereturn scalar selhet_p = .
			ereturn scalar selhet_df = .
		}
		// Heteroskedasticity
		if "`het'" != "" {
			ereturn scalar het_chi2 = .
			ereturn scalar het_p = .
			ereturn scalar het_df = .
		}
	}
	else {
		// Selection
		if "`z'" != "" {
			quiet testparm `z', eq(#1)
			ereturn scalar sel_chi2 = r(chi2)
			ereturn scalar sel_p = r(p)
			ereturn scalar sel_df = r(df)
		}
		// Value
		if "`x'" != "" {
			quiet testparm `x', eq(#2)
			ereturn scalar val_chi2 = r(chi2)
			ereturn scalar val_p = r(p)
			ereturn scalar val_df = r(df)
		}
		// Selection Heteroskedasticity
		if "`selhet'" != "" {
			quiet testparm `selhet', eq(#3)
			ereturn scalar selhet_chi2 = r(chi2)
			ereturn scalar selhet_p = r(p)
			ereturn scalar selhet_df = r(df)
			// Hetersokedasticity
			if "`het'" != "" {
				quiet testparm `hetvars', eq(#4)
				ereturn scalar het_chi2 = r(chi2)
				ereturn scalar het_p = r(p)
				ereturn scalar het_df = r(df)
			}
		}
		else if "`het'" != "" {
			quiet testparm `hetvars', eq(#3)
			ereturn scalar het_chi2 = r(chi2)
			ereturn scalar het_p = r(p)
			ereturn scalar het_df = r(df)
		}
	}
	
	ereturn local neh_cmdline = "nehurdle $neh_cmdline"
	macro drop neh_cmdline
	ereturn local het "`het'"
	ereturn local selhet "`selhet'"
	ereturn local title "`title'"
	ereturn local cmd_opt "`spec'"
	// ereturn local marginsok = "XB default"
	ereturn local depvar = "`y'"
	ereturn scalar N_c = `numcen'
	ereturn scalar k_aux = `anci'
	ereturn local predict "nehurdle_p"
	ereturn local cmd = "nehurdle"
	
	// Doing lrtest
	if "`lrtest'" == "" & "`het'" == "" & inlist("`vce'", "", "vce(oim)", "vce(opg)") {
		tempname lrstat lrpval
		scalar `lrstat' = 2 * (e(ll) - `ll0')
		if `lrstat' < 0 {
			ereturn scalar lrstat = .
			ereturn scalar lrpval = .
		}
		else {
			ereturn scalar lrstat = `lrstat'
			ereturn scalar lrpval = chi2tail(1, `lrstat') / 2
		}
	}
	
	// Predicting censored mean and calculating pseudo r-squared
	tempvar yhat zg selsig alpha
	quiet {
		_predict double `zg' if `touse', equation(#1)
		_predict double `yhat' if `touse', equation(#2)
		replace `yhat' = exp(`yhat') if `touse'
		if "`selhet'" != "" {
			_predict double `selsig' if `touse', equation(#3)
			replace `selsig' = exp(`selsig') if `touse'
			_predict double `alpha' if `touse', equation(#4)
		}
		else {
			generate double `selsig' = 1 if `touse'
			_predict double `alpha' if `touse', equation(#3)
		}
		replace `alpha' = exp(`alpha') if `touse'
		if "`truncnb2'" != "" {
			replace `yhat' = normal(`zg' / `selsig') * `yhat' / (1 - (1 +	///
				`alpha' * `yhat')^(- 1 / `alpha')) if `touse'
		}
		else {
			replace `yhat' = normal(`zg' / `selsig') * `yhat' / (1 - (1 +		///
				`alpha')^(- `yhat' / `alpha')) if `touse'
		}
	}
	capture correl `y' `yhat' if `touse'
	ereturn scalar r2 = r(rho)^2
	
	// Display
	Replay, `level' `header' `coeflegend'
end


// Version 1.0.0 uses lf evaluators for all models and specifications
// Version 1.1.0 uses lf2 evaluators for all models and specifications and
//		no longer performs the LR test for the correlation in the Heckman
// Version 1.1.1 sets the default nrtolerance to 1e-12
