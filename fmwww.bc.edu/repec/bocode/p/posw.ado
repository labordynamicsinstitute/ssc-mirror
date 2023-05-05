*!version 1.0.0  13apr2021
/*
	syntax:
		posw depvar dvars [if] [in], 		///
			controls(varlist)		///
			model(linear|logit|poisson) 	///
			[method(bic|test)		///
			alpha(string)]
*/
program posw
	
	if (replay()) {
		Display `0'
	}
	else {
		Estimate `0'
	}
end
						//------------------------//
						//	Display
						//------------------------//
program Display
	syntax [, *]
	
	_get_diopts diopts extra, `options'

	if (`"`extra'"' != "") {
		di as err "extra options not allowed"
		exit 198
	}

	Head
	_coef_table, `diopts'

	di as txt "{p 0 6 2}Note: Chi-squared test is a Wald test of "	///
		"the coefficients of the variables of interest jointly " ///
		"equal to zero.{p_end}"
end
						//---------------------------//
						//	Estimate	
						//---------------------------//
program Estimate, eclass

					//  parse syntax
	tempvar touse_esample
	ParseSyntax `touse_esample' : `0'
	local diopts `r(diopts)'
	local model `r(model)'
	local yvar `r(yvar)'
	local dvars `r(dvars)'
	local xvars `r(xvars)'
	local method `r(method)'
	local alpha  `r(alpha)'
					// preserve START
	preserve
	qui keep if `touse_esample'
					// compute
	Compute, model(`model')	///
		yvar(`yvar')	///
		dvars(`dvars')	///
		xvars(`xvars')	///
		alpha(`alpha')	///
		method(`method')
					// preserve END
	restore
					// display
	Display, `diopts'

	ereturn repost, esample(`touse_esample')

end
						//---------------------------//
						//	Parse syntax
						//---------------------------//
program ParseSyntax, rclass

	_on_colon_parse `0'
	local touse_esample `s(before)'
	local 0 `s(after)'

	syntax varlist(numeric fv)		///
		[if] [in]			///
		, model(string)			///
		controls(varlist numeric fv)	///
		[method(string)			///
		alpha(real 0.05)		///
		*]
	
					//  diopts
	_get_diopts diopts extra, `options'

	if (`"`extra'"' != "") {
		di as err "extra options not allowed"
		exit 198
	}

					//  touse
	marksample touse
					//  yvar and dvars	
	gettoken yvar dvars : varlist

	fvexpand `dvars'
	local dvars `r(varlist)'

	_fv_check_depvar `yvar'
					//  xvars
	fvexpand `controls'
	local xvars `r(varlist)'

					// markout
	markout `touse' `yvar' `dvars' `xvars'

					// check nobs
	qui count if `touse'
	local nobs = r(N)
	if (`nobs' <=2){
		di as err "insufficient observations"
		exit 2001
	}

					//  model
	if (`"`model'"' != "linear" &		///
		`"`model'"' != "logit" &	///
		`"`model'"' != "poisson") {
		di as err "option {bf:model()} must be one of {bf:linear}, " ///
			"{bf:logit}, or {bf:poisson}"
		exit 198
	}
					// method
	if (`"`method'"' == "") {
		local method bic
	}
	else if (`"`method'"' == "test" | `"`method'"' == "bic") {
		local method `method'
	}
	else {
		di as err "option {bf:method()} allows only one " ///
			"of {bf:test} or {bf:bic}"
		exit 198
	}

	gen byte `touse_esample' = `touse' 

	ret local diopts `diopts'
	ret local yvar `yvar'
	ret local xvars `xvars'
	ret local dvars `dvars'
	ret local model `model'
	ret local method `method'
	ret local alpha `alpha'
end
						//---------------------------//
						//	compute
						//---------------------------//
program Compute
	syntax , model(string)		///
		[*]
	
	if (`"`model'"' == "linear") {
		ComputeLinear , `options'
	}
	else if (`"`model'"' == "logit"	///
		| `"`model'"' == "poisson") {
		ComputeGLM `0'
	}
end
						//------------------------//
						//	 compute GLM
						//------------------------//
program ComputeGLM, eclass
	syntax , model(string)	///
		yvar(string)	///
		dvars(string)	///
		xvars(string)	///
		method(string)	///
		[alpha(passthru)]
	
	GetEstcmd `model'
	local estcmd `s(estcmd)'

	GetSwcmd, method(`method') `alpha'
	local swcmd `s(swcmd)'

	/* ----------------------------------------------------------- */
					// Step 1: post-selection y on d and x
	di
	di_log, var(`yvar') method(`method')

					// swcmd y on d and x 
	qui `swcmd' : `estcmd' `yvar' `dvars' `xvars'	
	local controls_sel `r(included)'
	local allvars_sel : list dvars | controls_sel
	local controls_sel_k : list controls_sel - dvars
	local depvar_k `yvar'

					// post-selection y on d and selected x 
	qui `estcmd' `yvar' `allvars_sel'

					// get Xb in main sample 
	tempvar xb
	qui predict double `xb', xb

	qui replace `xb' = `xb' 
	foreach var of local dvars {
		qui replace `xb' = `xb' - _b[`"`var'"']*`var' 
	}

					// get weight 
	tempvar wvar
	qui predict double `wvar' 
	if (`"`model'"' == "logit") {
		qui replace `wvar' = `wvar'*(1-`wvar') 
	}

	/* ----------------------------------------------------------- */
					// Step 2: post-selection d on x

					// swcmd on x 
	foreach var of local dvars {
		tempvar dvar_tmp
		qui gen double `dvar_tmp' = `var'

		di_log, var(`var') method(`method')
		qui `swcmd': regress `dvar_tmp' `xvars' [iw=`wvar']
		local controls_sel_k `controls_sel_k' || `r(included)'
		local depvar_k  `depvar_k' || `var'
		
		local controls_sel `controls_sel' `r(included)'

		tempvar zvar
		predict double `zvar', res
		local inst `inst' `zvar'
	}

	local controls_sel : list controls_sel - dvars
	local controls_sel : list uniq controls_sel

	/* ----------------------------------------------------------- */
					// Step 3: instrumental GMM
	qui InstGLM, yvar(`yvar') dvars(`dvars') 	 ///
			xbvar(`xb') inst(`inst') model(`model') 

	/* ----------------------------------------------------------- */
					// Step 4: Post Result
	PostResult , controls_sel_k(`controls_sel_k')	///
		depvar_k(`depvar_k')			///
		model(`model')				///
		controls_sel(`controls_sel')		///
		yvar(`yvar')				///
		xvars(`xvars')				///
		dvars(`dvars')				///
		method(`method')
end
						//------------------------//
						//	get est cmd
						//------------------------//
program GetEstcmd, sclass
	args model

	if (`"`model'"' == "linear") {
		local estcmd regress
	}
	else if (`"`model'"' == "logit" | `"`model'"' == "poisson") {
		local estcmd `model'
	}

	sret local estcmd `estcmd'
end

						//------------------------//
						//	instrumental GMM
						//------------------------//
program InstGLM
	syntax, yvar(string)	///
		dvars(string) 	///
		xbvar(string) 	///
		inst(string) 	///
		model(string) 

	if (`"`model'"' == "logit") {
		local fcn_m poswbic_gmm_logit
		local est_cmd logit
	}
	else if ( `"`model'"' == "poisson") {
		local fcn_m poswbic_gmm_pois
		local est_cmd poisson
	}
						//  starting values
	`est_cmd' `yvar' `dvars', offset(`xbvar') noconstant
	tempname b_from
	mat `b_from' = e(b)
						//  one step gmm
	gmm `fcn_m', nequations(1) parameters({`yvar':`dvars'})	///
		instruments(`inst', noconstant)				///
		haslfderivatives onestep				///
		from(`b_from') winitial(identity) vce(robust)		///
		yvar(`yvar') xbvar(`xbvar') 				

	if (!e(converged)) {
		di as err "{p 4 4 2}gmm step failed to converge{p_end}"
		exit 498
	}
end

						//------------------------//
						//	 Head
						//------------------------//
program Head
						// title
	local title as txt "`e(title)'"

	local col = 38
						//  nobs
	local nobs _col(`col') as txt "Number of obs" _col(67) "="	///
		_col(69) as res %10.0fc e(N)
						//  number of controls
	local k_controls _col(`col') as txt "Number of controls"	///
		_col(67) "=" _col(69) as res %10.0fc e(k_controls)

						//  number of unique controls
	local k_controls_sel _col(`col') as txt 	///
		"Number of selected controls" ///
		_col(67) "=" _col(69) as res %10.0fc e(k_controls_sel)
	
	local model as txt "Model: " as res "`e(model)'"

						// wald
	local wald _col(`col') as txt "Wald chi2({res:`e(df)'})"	///
		 _col(67) "="  _col(69) as res %10.2f e(chi2)

						// prob
	local prob _col(`col') as txt "Prob > chi2" _col(67) "="	///
		_col(69) as res %10.4f e(p)	

	di
	di `title' `nobs'
	di `k_controls'
	di `k_controls_sel'
	di `wald'
	di `model' `prob'
	di
end
						//------------------------//
						//	 Post result
						//------------------------//
program PostResult, eclass
	syntax , controls_sel_k(string)	///
		depvar_k(string)	///
		model(string)		///
		xvars(string)		///
		yvar(string)		///
		dvars(string)		///
		method(string)		///
		[controls_sel(string)]	
		
	tempname b V
	mat `b' = e(b)
	mat `V' = e(V)
	local N = e(N)

	mat colnames `b' = `dvars'
	mat colnames `V' = `dvars'
	mat rownames `V' = `dvars'

	tempvar touse
	gen byte `touse' = e(sample)

	eret post `b' `V', buildfvinfo esample(`touse')

	_parse expand xsel_list tmp : controls_sel_k
	_parse expand ylist tmp : depvar_k

	forvalues i = 1/`xsel_list_n' {
		eret hidden local controls_sel_`i' `xsel_list_`i''
		eret hidden local depvar_`i' `ylist_`i''
		eret hidden scalar 	///
			k_controls_sel_`i' = `:list sizeof xsel_list_`i''
	}

	eret local vce robust
	eret local vcetype Robust
	eret local title "Partialing-out stepwise `method'"
	eret local model "`model'"
	eret local controls `xvars'
	eret local controls_sel `controls_sel'
	eret local depvar `yvar'
	eret local varsofinterest `dvars'

	eret scalar N = `N'
	eret scalar k_controls  = `: list sizeof xvars'
	eret scalar k_controls_sel = `: list sizeof controls_sel'
	eret scalar k_varsofinterest = `: list sizeof dvars'

	ComputeChi2

	eret local cmd posw
end

program GetSwcmd, sclass
	syntax, method(string)		///
		[alpha(string)]
	
	local swcmd step`method'
	if (`"`method'"' == "test" & `"`alpha'"' != "") {
		local swcmd `swcmd', alpha(`alpha')
	}

	sret local swcmd `swcmd'
end

						//------------------------//
						//  ComputeLinear
						//------------------------//
program ComputeLinear, eclass
	syntax , yvar(string)	///
		dvars(string)	///
		xvars(string)	///
		method(string)	///
		[alpha(passthru)]
	
	GetSwcmd, method(`method') `alpha'
	local swcmd `s(swcmd)'

	/* ----------------------------------------------------------- */
					// Step 1: partial-out x from y

					// select xvars for y	
	di
	di_log, var(`yvar') method(`method')
	qui `swcmd' : regress `yvar' `xvars'

					// housekeeping
	local controls_sel `r(included)'
	local controls_sel_k `r(included)'
	local depvar_k `yvar'
					// get residuals
	tempvar rho
	qui predict double `rho', residuals

	/* ----------------------------------------------------------- */
					// Step 2: partial out x from dvars

	foreach var of local dvars {
		tempvar dvar_tmp
		qui gen double `dvar_tmp' = `var'

					// select controls
		di_log, var(`var') method(`method')
		qui `swcmd': regress `dvar_tmp' `xvars'

					// housekeeping
		local controls_sel `controls_sel' `r(included)'
		local controls_sel_k `controls_sel_k' || `r(included)'
		local depvar_k `depvar_k' || `var'

					// get residuals (instruments)
		tempvar inst_tmp
		qui predict double `inst_tmp', residuals 
		local inst `inst' `inst_tmp'
	}
	local controls_sel : list uniq controls_sel

	/* ----------------------------------------------------------- */
					// Step 3: OLS of rho on instruments
	qui regress `rho' `inst', vce(robust) noconstant


	/* ----------------------------------------------------------- */
					// Step 4: Post result
	PostResult , controls_sel_k(`controls_sel_k')	///
		depvar_k(`depvar_k')			///
		model(linear)				///
		controls_sel(`controls_sel')		///
		yvar(`yvar')				///
		xvars(`xvars')				///
		dvars(`dvars')				///
		method(`method')
end
						//------------------------//
						//  di_log
						//------------------------//
program di_log
	syntax , var(string)	///
		method(string)	///
	
	di as txt "select controls for {bf:`var'} using stepwise {bf:`method'}"
end

						//------------------------//
						//  compute Chi2
						//------------------------//
program ComputeChi2, eclass
	local vars : colvarlist e(b)
	qui test `vars'

	local chi2 = r(chi2)
	local p  = r(p)
	local df = r(df)
	
	eret scalar chi2 = `chi2'
	eret scalar p = `p'
	eret scalar df = `df'
	eret local chi2type "Wald"

	mata : st_numscalar("e(rank)", rank(st_matrix("e(V)")))
end
