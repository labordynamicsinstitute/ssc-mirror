*! nehurdle_p v2.0.0
*! 19 September 2024
*! Alfonso Sanchez-Penalver

/*******************************************************************************
*	Program that collects -predict- options after nehurdle					   *
*******************************************************************************/

// DISTRIBUTION
capture program drop nehurdle_p
program define nehurdle_p
	version 11
	if "`e(cmd)'" != "nehurdle"	{
		di as error "Your previous estimation command was not {bf: nehurdle}"
		exit 301
	}
	
	if "`e(cmd_opt)'" == "trunc"												///
		nehurdle_trunc_p `0'
	else if "`e(cmd_opt)'" == "tobit"											///
		nehurdle_tobit_p `0'
	else if "`e(cmd_opt)'" == "heckman"											///
		nehurdle_heckman_p `0'
	else if "`e(cmd_opt)'" == "truncp"											///
		nehurdle_truncp_p `0'
	else if "`e(cmd_opt)'" == "truncnb1"										///
		nehurdle_truncnb1_p `0'
	else if "`e(cmd_opt)'" == "truncnb2"										///
		nehurdle_truncnb2_p `0'
	else {
		di as error "No valid predict command"
		exit 198
	}
end

// PARSING COMMANDS
capture program drop nehurdle_parse_probopts
program define nehurdle_parse_probopts, sclass
	version 11
	syntax anything(name=opt) [if] [in]
	
	// The program receives one argument, opt, and it checks whether values
	// are integers or missing, whether the argument is a macro or a variable.
	// If it fails both, it returns 1, and if it is either it returns 0.
	
	capture confirm var `opt'
	if _rc {
		// If model is of a continuous variable we can accept any numeric value
		// but if the model is of count data we can only accept integers
		local nopt "number `opt'"
		if inlist("`e(cmd_opt)'", "truncp", "truncnb2")							///
			local nopt "integer `nopt'"
		capture confirm `nopt'
		if _rc {
			if "`opt'" != "."													///
				sreturn local nh_res = 1
			else sreturn local nh_res = 0
		}
		else sreturn local nh_res = 0
	}
	else {
		// Check the variable is actually numeric
		capture confirm numeric variable `opt'
		if _rc sreturn local nh_res = 1
		else if inlist("`e(cmd_opt)'", "truncp", "truncnb2") {
			// have to check that the values are either integers or missing.
			tempvar check
			quiet gen double `check' = mod(`opt',1) `if' `in'
			quiet replace `check' = (`check' != 0 & !missing(`check')) `if' `in'
			quiet summarize `check' `if' `in', mean
			if r(sum) > 0 sreturn local nh_res = 1
			else sreturn local nh_res = 0
		}
		else sreturn local nh_res = 0
	}
end

// LOG/NORMAL HURDLES
capture program drop nehurdle_trunc_p
program define nehurdle_trunc_p, eclass
	version 11
	syntax anything(id="newvarname") [if] [in]									///
	[, {																		///
		YCen			|														///
		RESCen			|														///
		VCen			|														///
		SIGCen			|														///
		PRCen(string)	|														///
		YTrun			|														///
		RESTrun			|														///
		VTrun			|														///
		SIGTrun			|														///
		PRTrun(string)	|														///
		YStar			|														///
		RESStar			|														///
		VStar			|														///
		SIGStar			|														///
		PRStar(string)	|														///
		XBVal			|														///
		RESVal			|														///
		PSel			|														///
		RESSEL			|														///
		SCores			|														///
		XB				|														///
		XBSel			|														///
		XBSIG			|														///
		SIGma			|														///
		SELSIGma		|														///
		XBSELSig																///
	} * ]
	
	if "`scores'" != "" {
		local bvar "`e(depvar)'"
		tempvar dy y1
		quiet generate byte `dy' = `bvar' > 0
		if "`e(est_model)'" == "exponential" 									///
			quiet generate double `y1' = ln(`bvar')
		else quiet generate double `y1' = `bvar'
		ereturn local depvar "`dy' `y1'"
		
		marksample touse
		marksample touse2
		local xvars : colna e(b)
		local cons _cons _cons _cons _cons
		local xvars : list xvars - cons
		markout `touse2' `xvars'
		quiet replace `touse' = 0 if `dy' & !`touse2'
		ml score `anything' if `touse', `scores' missing `options'
		ereturn local depvar "`bvar'"
		exit
	}
	
	
	local myopts "YCen RESCen VCen SIGCen PRCen(string) YTrun RESTrun VTrun"
	local myopts "`myopts' SIGTrun PRTrun(string) YStar RESStar VStar SIGStar"
	local myopts "`myopts' PRStar(string) XBVal RESVal PSel RESSEL XB XBSel"
	local myopts "`myopts' XBSIG SIGma SELSIGma XBSELSig"
	_pred_se "`myopts'" `0'
	if `s(done)' exit
	local vtyp  `s(typ)'
	local varn `s(varn)'
	local 0 `"`s(rest)'"'
	
	// Mark sample
	marksample touse
	
	// Have to capture xb to notify it is not valid.
	if "`xb'" != "" {
		di as error "option {bf:xb} not valid"
		di as error "Try one of the following:"
		di as error _col(6) "1. {bf:xbval} for fitted values of the value equation."
		di as error _col(6) "2. {bf:xbsel} for fitted values of the selection equation."
		if "`e(selhet)'" != "" {
			di as error _col(6) "3. {bf:xbselsig} for fitted values of the selection ln sigma."
			di as error _col(6) "4. {bf:xbsig} for fitted values of the value ln sigma."
		}
		else																	///
			di as error _col(6) "3. {bf:xbsig} for fitted values of the value ln sigma."
		exit 198
	}
	
	// ycen is the default and is done last
	if "`rescen'" != "" {
		tempvar zg selsig mu sig
		_predict double `zg' if `touse', equation(#1)
		_predict double `mu' if `touse', equation(#2)
		if "`e(selhet)'" != "" {
			_predict double `selsig' if `touse', equation(#3)
			quiet replace `selsig' = exp(`selsig') if `touse'
			_predict double `sig' if `touse', equation(#4)
		}
		else {
			quiet generate double `selsig' = 1 if `touse'
			_predict double `sig' if `touse', equation(#3)
		}
		quiet replace `sig' = exp(`sig') if `touse'
		if "`e(est_model)'" == "linear"											///
			quiet replace `mu' = `mu' + `sig' * normalden(`mu' /				///
				`sig') / normal(`mu' / `sig') if `touse'
		else quiet replace `mu' = exp(`mu' + `sig'^2 / 2) if `touse'
		quiet replace `mu' = `e(depvar)' -  normal(`zg' / `selsig') *		///
			`mu' if `touse'
		quiet generate `vtyp' `varn' = `mu' if `touse'
		label var `varn' "Observed variable residuals: `e(depvar)' - E(`e(depvar)'|x,z)"
		exit
	}
	
	if "`vcen'" != "" {
		tempvar sig selsig phiz mu
		if "`e(selhet)'" != ""{
			local eqnum = 4
			_predict double `selsig' if `touse', equation(#3)
			quiet replace `selsig' = exp(`selsig') if `touse'
		}
		else {
			local eqnum = 3
			quiet generate double `selsig' = 1 if `touse'
		}
		_predict double `phiz' if `touse', equation(#1)
		quiet replace `phiz' = normal(`phiz' / `selsig') if `touse'
		
		_predict double `mu' if `touse', equation(#2)
		_predict double `sig' if `touse', equation(#`eqnum')
		quiet replace `sig' = exp(`sig') if `touse'
		if "`e(est_model)'" == "exponential" {
			quiet replace `mu' = `phiz' * exp(2 * `mu' + `sig'^2) *			///
				(exp(`sig'^2) - `phiz') if `touse'
		}
		else {
			tempvar lam
			quiet generate double `lam' = normalden(`mu' / `sig') /			///
				normal(`mu' / `sig') if `touse'
			quiet replace `mu' = `phiz' * `sig'^2 * (1 + (`mu' / `sig' +	///
				`lam') * (`mu' / `sig'  - (`mu' / `sig' + `lam') * `phiz')) ///
				if `touse'
		}
		quiet generate `vtyp' `varn' = `mu' if `touse'
		label var `varn' "Observed variable variance: V(`e(depvar)'|x,z)"
		exit
	}
	
	if "`sigcen'" != "" {
		tempvar sig selsig phiz mu
		if "`e(selhet)'" != ""{
			local eqnum = 4
			_predict double `selsig' if `touse', equation(#3)
			quiet replace `selsig' = exp(`selsig') if `touse'
		}
		else {
			local eqnum = 3
			quiet generate double `selsig' = 1 if `touse'
		}
		_predict double `phiz' if `touse', equation(#1)
		quiet replace `phiz' = normal(`phiz' / `selsig') if `touse'
		
		_predict double `mu' if `touse', equation(#2)
		_predict double `sig' if `touse', equation(#`eqnum')
		quiet replace `sig' = exp(`sig') if `touse'
		if "`e(est_model)'" == "exponential" {
			quiet replace `mu' = `phiz' * exp(2 * `mu' + `sig'^2) *			///
				(exp(`sig'^2) - `phiz') if `touse'
		}
		else {
			tempvar lam
			quiet generate double `lam' = normalden(`mu' / `sig') /			///
				normal(`mu' / `sig') if `touse'
			quiet replace `mu' = `phiz' * `sig'^2 * (1 + (`mu' / `sig' +	///
				`lam') * (`mu' / `sig'  - (`mu' / `sig' + `lam') * `phiz')) ///
				if `touse'
		}
		quiet replace `mu' = sqrt(`mu') if `touse'
		quiet generate `vtyp' `varn' = `mu' if `touse'
		label var `varn' "Observed variable std. dev.: sd(`e(depvar)'|x,z)"
		exit
	}
	
	if "`prcen'" != "" {
		local cpos = strpos("`prcen'", ",")
		if `cpos' == 0 {
			if "`prcen'" != "0" {
				di as error "only two values/variables separated by comma (,) or 0 are suitable arguments"
				exit 198
			}
			else {
				tempvar zg selsig
				_predict double `zg' if `touse', equation(#1)
				if "`e(selhet)'" != "" {
					_predict double `selsig' if `touse', equation(#3)
					quiet replace `selsig' = exp(`selsig') if `touse'
				}
				else quiet generate double `selsig' = 1 if `touse'
				quiet replace `zg' = normal(- `zg' / `selsig') if `touse'
				quiet generate `vtyp' `varn' = `zg' if `touse'
				label var `varn' "Prob. observed variable: P(`e(depvar)'=`prcen'|z)"
				exit
			}
		}
		
		local left = substr("`prcen'",1,`cpos' - 1)
		local right = substr("`prcen'", `cpos' + 1, .)
		
		// Now check that right doesn't have another comma.
		local cpos = strpos("`right'" , ",")
		if `cpos' > 0 {
			di as error "Too many arguments"
			exit 198
		}
		
		// Check both are not missing
		if "`left'" == "." & "`right'" == "." {
			di as error "Both arguments cannot be ."
			exit 198
		}
		
		nehurdle_parse_probopts `left' if `touse'
		if `s(nh_res)' > 0 {
			di as error "The first argument needs to be numeric or ."
			exit 198
		}
		nehurdle_parse_probopts `right' if `touse'
		if `s(nh_res)' > 0 {
			di as error "The second argument needs to be numeric or ."
			exit 198
		}
		
		tempvar phiz selsig sig phix mu
		_predict double `phiz' if `touse', equation(#1)
		_predict double `mu' if `touse', equation(#2)
		if "`e(selhet)'" != "" {
			local eqn = 4
			_predict double `selsig' if `touse', equation(#3)
			quiet replace `selsig' = exp(`selsig') if `touse'
		}
		else {
			local eqn = 3
			quiet generate double `selsig' = 1 if `touse'
		}
		quiet replace `phiz' = normal(`phiz' / `selsig') if `touse'
		_predict double `sig' if `touse', equation(#`eqn')
		quiet replace `sig' = exp(`sig') if `touse'
		quiet generate double `phix' = normal(`mu' / `sig') if `touse'
		
		
		if "`left'" == "." {
			// Probability less than
			tempvar check
			quiet generate `vtyp' `check' = (`right' <= 0) if `touse'
			quiet summarize `check' if `touse', mean
			if r(sum) > 0 {
				di as error "The second argument has to be positive"
				exit 198
			}
			
			// Chek missing values
			quiet replace `check' = missing(`right') if `touse'
			quiet summarize `check' if `touse', mean
			if r(sum) > 0 {
				di as error "The second argument cannot have missing values"
				exit 198
			}
			drop `check'
			
			// different formulas for lognormal and normal
			if "`e(est_model)'" == "exponential" {
				quiet replace `mu' = 1 - `phiz' *								///
					normal((`mu' - ln(`right')) / `sig') if `touse'
			}
			else {
				// normal
				quiet replace `mu' = 1 + `phiz' / `phix' *					///
					(normal((`right' - `mu') / `sig') - 1) if `touse'
			}
			quiet generate `vtyp' `varn' = `mu' if `touse'
			label var `varn' "Prob. observed variable: P(`e(depvar)'<`right'|x,z)"
			exit
		}
		
		
		if "`right'" == "." {
			// Probability greater than.
			// If left is 0, then it's pz independent of linear or exponential
			if "`left'" == "0" {
				quiet generate `vtyp' `varn' = `phiz' if `touse'
				label var `varn' "Prob. observed variable: P(`e(depvar)'>`left'|x,z)"
				exit
			}
			
			tempvar check
			quiet generate `check' = (`left' < 0) if `touse'
			quiet summarize `check' if `touse', mean
			if r(sum) > 0 {
				di as error "The first argument cannot be negative"
				exit 198
			}
			quiet replace `check' = missing(`left') if `touse'
			quiet summarize `check' if `touse', mean
			if r(sum) > 0 {
				di as error "The first argument cannot have missing values"
				exit 198
			}
			drop `check'
			
			if "`e(est_model)'" == "exponential" {
				// Have to check for zeroes on left.
				capture confirm var `left'
				if !_rc {
					// We have a variable, so we are going to generate a temp one
					// and replace zeroes with 1e-20, and then take the log.
					tempvar lnleft
					quiet generate double `lnleft' = `left' if `touse'
					quiet replace `lnleft' = 1e-20 if `touse' & `lnleft' == 0
					quiet replace `lnleft' = ln(`lnleft') if `touse'
				}
				else local lnleft = ln(`left')
				
				quiet replace `mu' = `phiz' *									///
					normal((`mu' - `lnleft') / `sig') if `touse'
			}
			else {
				quiet replace `mu' = `phiz' / `phix' *						///
					normal((`mu' - `left') / `sig') if `touse'
			}
			quiet generate `vtyp' `varn' = `mu' if `touse'
			label var `varn' "Prob. observed variable: P(`e(depvar)'>`left'|x,z)"
			exit
		}
		
		
		// Alright, probability of a range.
		// Check right
		tempvar check
		quiet generate byte `check' = (`left' < 0) if `touse'
		quiet summarize `check' if `touse', mean
		if r(sum) > 0 {
			di as error "The first argument cannot be negative"
			exit 198
		}
		quiet replace `check' = (`right'<=`left') if `touse'
		quiet summarize `check' if `touse', mean
		if r(sum) > 0 {
			di as error "The second argument has to be greater than the first"
			exit 198
		}
		quiet replace `check' = missing(`left', `right') if `touse'
		quiet summarize `check' if `touse', mean
		if r(sum) > 0 {
			di as error "Neither argument can have missing values"
			exit 198
		}
		drop `check'
		
		if "`e(est_model)'" == "exponential" {
			// Check for zeroes in left.
			capture confirm var `left'
			if !_rc {
				tempvar lnleft
				quiet generate double `lnleft' = `left' if `touse'
				quiet replace `lnleft' = 1e-20 if `touse' & `lnleft' == 0
				quiet replace `lnleft' = ln(`lnleft') if `touse'
			}
			else if "`left'" == "0" local lnleft = ln(1e-20)
			else local lnleft = ln(`left')
			
			quiet replace `mu' = `phiz' *										///
				(normal((ln(`right') - `mu') / `sig') -						///
					normal((`lnleft' - `mu') / `sig')) if `touse'
		}
		else {
			quiet replace `mu' = `phiz' / `phix' *							///
				(normal((`right' - `mu') / `sig') -							///
					normal((`left' - `mu') / `sig')) if `touse'
		}
		quiet generate `vtyp' `varn' = `mu' if `touse'
		label var `varn' "Prob. observed variable: P(`left'<`e(depvar)'<`right'|x,z)"
		exit
	}
		
	if "`ytrun'" != "" {
		if "`e(est_model)'" == "exponential" {
			di as error "{bf:ytrun} is not a valid option in the lognormal hurdle model, because there is no truncation. Try:"
			di as error _col(6) "1. {bf:ystar} for the latent variable's mean, or"
			di as error _col(6) "2. {bf:ycen} for the observed variable's mean."
			exit 198
		}
		tempvar sig mu
		_predict double `mu' if `touse', equation(#2)
		if "`e(selhet)'" != "" local eqnum = 4
		else local eqnum = 3
		_predict double `sig' if `touse', equation(#`eqnum')
		quiet replace `sig' = exp(`sig') if `touse'
		quiet replace `mu' = `mu' + `sig' * normalden(`mu' / `sig') /		///
			normal(`mu' / `sig') if `touse'
		quiet generate `vtyp' `varn' = `mu' if `touse'
		label var `varn' "Truncated variable mean: E(`e(depvar)'*|x,`e(depvar)'*>0)"
		exit
	}
	
	if "`restrun'" != "" {
		if "`e(est_model)'" == "exponential" {
			di as error "{bf:restrun} is not a valid option in the lognormal hurdle model, because there is no truncation. Try:"
			di as error _col(6) "1. {bf:resstar} for the latent variable's residuals, or"
			di as error _col(6) "2. {bf:rescen} for the observed variable's residuals."
			exit 198
		}
		tempvar sig mu
		_predict double `mu' if `touse', equation(#2)
		if "`e(selhet)'" != "" local eqnum = 4
		else local eqnum = 3
		_predict double `sig' if `touse', equation(#`eqnum')
		quiet replace `sig' = exp(`sig') if `touse'
		quiet replace `mu' = `mu' + `sig' * normalden(`mu' / `sig') /		///
			normal(`mu' / `sig') if `touse'
		quiet replace `mu' = `e(depvar)' - `mu' if `touse'
		quiet generate `vtyp' `varn' = `mu' if `touse'
		label var `varn' "Truncated variable residuals: `e(depvar)' - E(`e(depvar)'*|x,`e(depvar)'*>0)"
		exit
	}
	
	if "`vtrun'" != "" {
		if "`e(est_model)'" == "exponential" {
			di as error "{bf:vtrun} is not a valid option in the lognormal hurdle model, because there is no truncation. Try:"
			di as error _col(6) "1. {bf:vstar} for the latent variable's variance, or"
			di as error _col(6) "2. {bf:vcen} for the observed variable's variance."
			exit 198
		}
		tempvar sig lam mu
		if "`e(selhet)'" != "" local eqnum = 4
		else local eqnum = 3
		_predict double `sig' if `touse', equation(#`eqnum')
		quiet replace `sig' = exp(`sig') if `touse'
		_predict double `mu' if `touse', equation(#2)
		// lambdax
		quiet generate double `lam' = normalden(`mu' / `sig') / normal(`mu' /	///
			`sig') if `touse'
		quiet replace `mu' = `sig'^2 * (1 - `lam' * (`mu' / `sig' + `lam'))		///
			if `touse'
		quiet generate `vtype' `varn' = `mu' if `touse'
		label var `varn' "Truncated variable variance: V(`e(depvar)'*|x,`e(depvar)'*>0)"
		exit
	}
	
	if "`sigtrun'" != "" {
		if "`e(est_model)'" == "exponential" {
			di as error "{bf:sigtrun} is not a valid option in the lognormal hurdle model, because there is no truncation. Try:"
			di as error _col(6) "1. {bf:sigstar} for the latent variable's std. dev., or"
			di as error _col(6) "2. {bf:sigcen} for the observed variable's std. dev."
			exit 198
		}
		tempvar sig lam mu
		if "`e(selhet)'" != "" local eqnum = 4
		else local eqnum = 3
		_predict double `sig' if `touse', equation(#`eqnum')
		quiet replace `sig' = exp(`sig') if `touse'
		_predict double `mu' if `touse', equation(#2)
		// lambdax
		quiet generate double `lam' = normalden(`mu' / `sig') / normal(`mu' /	///
			`sig') if `touse'
		quiet replace `mu' = `sig'^2 * (1 - `lam' * (`mu' / `sig' + `lam'))		///
			if `touse'
		quiet replace `mu' = sqrt(`mu') if `touse'
		quiet generate `vtype' `varn' = `mu' if `touse'
		label var `varn' "Truncated variable std. dev.: sd(`e(depvar)'*|x,`e(depvar)'*>0)"
		exit
	}
	
	if "`prtrun'" != "" {
		if "`e(est_model)'" == "exponential" {
			di as error "{bf:prtrun} is not a valid option in the lognormal hurdle model, because there is no truncation. Try:"
			di as error _col(6) "1. {bf:prstar} for the latent variable's probabilities, or"
			di as error _col(6) "2. {bf:sigcen} for the observed variable's probabilities."
			exit 198
		}
		
		// Only accept ranges, like in prstar
		local cpos = strpos("`prtrun'", ",")
		if `cpos' == 0 {
			di as error "Need two arguments (value or variables) separated by a comma"
			exit 198
		}
		
		local left = substr("`prtrun'",1,`cpos' - 1)
		local right = substr("`prtrun'", `cpos' + 1, .)
		
		// Now check that right doesn't have another comma.
		local cpos = strpos("`right'" , ",")
		if `cpos' > 0 {
			di as error "Too many arguments"
			exit 198
		}
		
		// Check if they are values, or variables or missing
		nehurdle_parse_probopts `left' if `touse'
		if `s(nh_res)' == 1 {
			display as error "The first argument needs to be numeric or ."
			exit 198
		}
		
		nehurdle_parse_probopts `right' if `touse'
		if `s(nh_res)' == 1 {
			display as error "The second argument needs to be numeric or ."
			exit 198
		}
		
		if "`left'" == "." & "`right'" == "." {
			di as error "Both arguments cannot be ."
			exit 198
		}
		
		
		// Ok let's get the variables we need for all estimations. Only normal
		// model, and it's the truncated variable, so we only need variables
		// from the value equation.
		tempvar mu sig phix
		_predict double `mu' if `touse', equation(#2)
		if "`e(selhet)'" != "" local eqn = 4
		else local eqn = 3
		_predict double `sig' if `touse', equation(#`eqn')
		quiet replace `sig' = exp(`sig') if `touse'
		quiet generate `phix' = normal(`mu' / `sig') if `touse'
		
		
		if "`left'" == "." {
			// Right cannot be negative, because we are truncated at zero
			tempvar check
			quiet generate byte `check' = (`right' <= 0) if `touse'
			quiet summarize `check' if `touse', mean
			if r(sum) > 0 {
				di as error "The second argument can only have positive values"
				exit 198
			}
			
			// And we cannot have missing values in a variable
			quiet replace `check' = missing(`right') if `touse'
			quiet summarize `check' if `touse', mean
			if r(sum) > 0 {
				di as error "The second argument cannot have missing values"
				exit 198
			}
			drop `check'
			
			// Probability less than
			quiet replace `mu' = (normal((`right' - `mu') / `sig') -			///
				normal(- `mu' / `sig'))/ `phix' if `touse'
			quiet generate `vtyp' `varn' = `mu' if `touse'
			label var `varn' "Prob. truncated variable: P(`e(depvar)'*<`right'|x,`e(depvar)'*>0)"
			exit
		}
		
		if "`right'" == "." {
			// Again, left has to be positive
			tempvar check
			quiet generate byte `check' = (`left' <= 0) if `touse'
			quiet summarize `check' if `touse', mean
			if r(sum) > 0 {
				di as error "The first argument can only have positive values"
				exit 198
			}
			
			// And we cannot have missing values in a variable
			quiet replace `check' = missing(`left') if `touse'
			quiet summarize `check' if `touse', mean
			if r(sum) > 0 {
				di as error "The first argument cannot have missing values"
				exit 198
			}
			drop `check'
			
			// Probability greater than
			quiet replace `mu' = normal((`mu' - `left') / `sig') / `phix'		///
				if `touse'
			quiet generate `vtyp' `varn' = `mu' if `touse'
			label var `varn' "Prob. truncated variable: P(`e(depvar)'*>`left'|x,`e(depvar)'*>0)"
			exit
		}
		
		tempvar check
		// Left positive
		quiet generate byte `check' = (`left' <= 0) if `touse'
		quiet summarize `check' if `touse', mean
		if r(sum) > 0 {
			di as error "The first argument can only have positive values"
			exit 198
		}
		
		// Right greater than left
		quiet replace `check' = (`right'<=`left') if `touse'
		quiet summarize `check' if `touse', mean
		if r(sum) > 0 {
			di as error "The second argument has to be greater than the first"
			exit 198
		}
		drop `check'
		
		quiet replace `mu' = (normal((`right' - `mu') / `sig') -				///
			normal((`left' - `mu') / `sig')) / `phix' if `touse'
		quiet generate `vtyp' `varn' = `mu' if `touse'
		label var `varn' "Prob. truncated variable: P(`left'<`e(depvar)'*<`right'|x,`e(depvar)'*>0)"
		exit
	}

	if "`ystar'" != "" {
		// If the model is normal, this will be the same as xbval, but if the
		// model is lognormal it won't.
		tempvar mu
		_predict double `mu' if `touse', equation(#2)
		if "`e(est_model)'" == "exponential"{
			if "`e(selhet)'" != ""												///
				local eqn = 4
			else local eqn = 3
			tempvar sig
			_predict double `sig' if `touse', equation(#`eqn')
			quiet replace `mu' = exp(`mu' + exp(2 * `sig') / 2) if `touse'
		}
		quiet generate `vtyp' `varn' = `mu' if `touse'
		label var `varn' "Latent variable mean: E(`e(depvar)'*|x)"
		exit
	}
	
	if "`resstar'" != "" {
		// Same thing. The same as resval if normal and different if lognormal.
		tempvar mu
		_predict double `mu' if `touse', equation(#2)
		if "`e(est_model)'" == "exponential"{
			if "`e(selhet)'" != ""												///
				local eqn = 4
			else local eqn = 3
			tempvar sig
			_predict double `sig' if `touse', equation(#`eqn')
			quiet replace `mu' = exp(`mu' + exp(2 * `sig') / 2) if `touse'
		}
		quiet replace `mu' = `e(depvar)' - `mu' if `touse'
		quiet generate `vtyp' `varn' = `mu' if `touse'
		label var `varn' "Latent variable residuals: `e(depvar)'* - E(`e(depvar)'*|x)"
		exit
	}
	
	if "`vstar'" != "" {
		// The normal model only involves sig_ui, but the loglinear model involves
		// both sig_ui and xb.
		if "`e(selhet)'" != "" local eqn = 4
		else local eqn = 3
		tempvar sig mu
		_predict double `sig' if `touse', equation(#`eqn')
		quiet replace `sig' = exp(`sig') if `touse'
		if "`e(est_model)'" == "exponential" {
			_predict double `mu' if `touse', equation(#2)
			quiet replace `mu' = exp(2 * `mu' + `sig'^2) * (exp(`sig'^2) - 1)	///
				if `touse'
		}
		else																	///
			quiet generate double `mu' = `sig'^2 if `touse'
		quiet generate `vtyp' `varn' = `mu' if `touse'
		label var `varn' "Latent variable variance: V(`e(depvar)'*|x)"
		exit
	}
	
	if "`sigstar'" != "" {
		// same as above. If model is normal this returns the same as sigma.
		if "`e(selhet)'" != "" local eqn = 4
		else local eqn = 3
		tempvar sig
		_predict double `sig' if `touse', equation(#`eqn')
		quiet replace `sig' = exp(`sig') if `touse'
		if "`e(est_model)'" == "exponential" {
			tempvar mu
			_predict double `mu' if `touse', equation(#2)
			quiet replace `mu' = exp(2 * `mu' + `sig'^2) * (exp(`sig'^2) - 1)	///
				if `touse'
			quiet replace `mu' = sqrt(`mu') if `touse'
			quiet generate `vtyp' `varn' = `mu' if `touse'
		}
		else																	///
			quiet generate `vtyp' `varn' = `sig' if `touse'
		label var `varn' "Latent variable std.dev.: sd(`e(depvar)'*|x)"
		exit
	}
	
	if "`prstar'" != "" {
		// This is ystar. So besides all the checking the trick here is that if
		// the model is lognormal we have to take the natural log of the values.
		// In either case, this follows a normal distribution. Also this is
		// a continuous variable, so we only do the case of two values.
		
		local cpos = strpos("`prstar'", ",")
		if `cpos' == 0 {
			di as error "Need two arguments (value or variables) separated by a comma"
			exit 198
		}
		
		local left = substr("`prstar'",1,`cpos' - 1)
		local right = substr("`prstar'", `cpos' + 1, .)
		
		// Now check that right doesn't have another comma.
		local cpos = strpos("`right'" , ",")
		if `cpos' > 0 {
			di as error "Too many arguments"
			exit 198
		}
		
		// Check if they are values, or variables or missing
		nehurdle_parse_probopts `left' if `touse'
		if `s(nh_res)' == 1 {
			display as error "The first argument needs to be numeric or ."
			exit 198
		}
		
		nehurdle_parse_probopts `right' if `touse'
		if `s(nh_res)' == 1 {
			display as error "The second argument needs to be numeric or ."
			exit 198
		}
		
		// Check both aren't .
		if "`left'" == "." & "`right'" == "." {
			display as error "Both arguments cannot be ."
			exit 198
		}
		
		// For all predictions I am going to need the fitted values of the value
		// equation (not exponentiated) and the standard deviation.
		tempvar mu sig
		_predict double `mu' if `touse', equation(#2)
		if "`e(sehlhet)'" != ""	local eqn = 4
		else local eqn = 3
		_predict double `sig' if `touse', equation(#`eqn')
		quiet replace `sig' = exp(`sig') if `touse'
		
		// Now we check the different cases.
		if "`left'" == "." {
			// Probability less than right.
			
			tempvar check
			quiet generate byte `check' = missing(`right') if `touse'
			quiet summarize `check' if `touse', mean
			if r(sum) > 0 {
				di as error "Second argument cannot have missing values"
				exit 198
			}
			if "`e(est_model)'" == "exponential" {
				quiet replace `check' = (`right' <= 0) if `touse'
				quiet summarize `check' if `touse', mean
				if r(sum) > 0 {
					di as error "Second argument needs to be positive"
					exit 198
				}
				drop `check'
				quiet replace `mu' = normal((ln(`right') - `mu') / `sig')		///
					if `touse'
			}
			else {
				quiet replace `mu' = normal((`right' - `mu') / `sig') if `touse'
			}
			quiet generate `vtyp' `varn' = `mu' if `touse'
			label var `varn' "Prob. latent variable: P(`e(depvar)'*<`right'|x)"
			exit
		}
		
		if "`right'" == "." {			
			// Probability more than left.
			tempvar check
			quiet generate byte `check' = missing(`left') if `touse'
			quiet summarize `check' if `touse', mean
			if r(sum) > 0 {
				di as error "First argument cannot have missing values"
				exit 198
			}
			if "`e(est_model)'" == "exponential" {
				quiet replace `check' = (`left' < 0) if `touse'
				quiet summarize `check' if `touse', mean
				if r(sum) > 0 {
					di as error "First argument cannot be negative"
					exit 198
				}
				
				capture confirm var `left'
				if !_rc {
					// variable
					tempvar lnleft
					quiet generate double `lnleft' = `left' if `touse'
					quiet replace `lnleft' = 1e-20 if `touse' & `lnleft' == 0
					quiet replace `lnleft' = ln(`lnleft') if `touse'
				}
				else  if "`left'" == "0" local lnleft = ln(1e-20)	
				else local lnleft = ln(`left')
			}
			else local lnleft = `left'
			
			drop `check'
			
			// It is 1 - normal(z), but it is more precise to do normal(-z). In
			// this case taking the negative of what's inside normal() is the
			// same as reversing the order in the numerator.
			quiet replace `mu' = normal((`mu' - `lnleft') / `sig') if `touse'
			quiet generate `vtyp' `varn' = `mu' if `touse'
			label var `varn' "Prob. latent variable: P(`e(depvar)'*>`left'|x)"
			exit
		}
		
		// Probability of an interval.
		// Check that right is greater than left.
		tempvar check
		quiet generate byte `check' = (`right' <= `left') if `touse'
		quiet summarize `check' if `touse', mean
		if r(sum) > 0 {
			di as error "The second argument must be greater than the first argument"
			exit 198
		}
		
		quiet replace `check' = missing(`left',`right') if `touse'
		quiet summarize `check' if `touse', mean
		if r(sum) > 0 {
			di as error "Neither argument can have missing values"
			exit 198
		}
		
		// If model is lognormal we have to transform both left and right
		if "`e(est_model)'" == "exponential" {
			quiet replace `check' = (`left' < 0) if `touse'
			quiet summarize `check' if `touse', mean
			if r(sum) > 0 {
				di as error "The first argument cannot be negative"
				exit 198
			}
			drop `check'
			
			// Left.
			capture confirm var `left'
			if !_rc {
				tempvar lnleft
				quiet generate double `lnleft' = `left' if `touse'
				quiet replace `lnleft' = 1e-20 if `touse' & `lnleft' == 0
				quiet replace `lnleft' = ln(`lnleft') if `touse'
			}
			else {
				if "`left'" == "0" local lnleft = ln(1e-20)
				else local lnleft = ln(`left')
			}
			
			
			// Right
			capture confirm var `right'
			if !_rc {
				tempvar lnright
				quiet generate double `lnright' = `right' if `touse'
				quiet replace `lnright' = ln(`lnright') if `touse'
			}
			else																///
				local lnright = ln(`right')
		}
		else {
			local lnleft = `left'
			local lnright = `right'
		}
		
		quiet replace `mu' = normal((`lnright' - `mu') / `sig') -				///
			normal((`lnleft' - `mu') / `sig') if `touse'
		quiet generate `vtyp' `varn' = `mu' if `touse'
		label var `varn' "Prob. latent variable: P(`left'<`e(depvar)'*<`right'|x)"
		exit
	}
		
	if "`xbval'" != "" {
		_predict `vtyp' `varn' if `touse', equation(#2)
		if "`e(est_model)'" == "linear"											///
			label var `varn' "Predicted uncensored mean E(`e(depvar)'*|x)"
		else																	///
			label var `varn' "Predicted uncensored mean E(ln(`e(depvar)')*|x)"
		exit
	}
	
	if "`resval'" != "" {
		tempvar mu
		_predict double `mu' if `touse', equation(#2)
		if "`e(est_model)'" == "linear"	{
			quiet replace `mu' = `e(depvar)' - `mu' if `touse'
			local vlab "Residual of uncensored mean E(`e(depvar)'*|x)"
		}
		else {
			quiet replace `mu' = ln(`e(depvar)') - `mu' if `touse'
			local vlab "Residual of uncensored mean E(ln(`e(depvar)')*|x)"
		}
		quiet generate `vtyp' `varn' = `mu' if `touse'
		label var `varn' "`vlab'"
		exit
	}
	
	if "`psel'" != "" {
		tempvar phiz selsig
		_predict double `phiz' if `touse', equation(#1)
		if "`e(selhet)'" != "" {
			_predict double `selsig' if `touse', equation(#3)
			quiet replace `selsig' = exp(`selsig') if `touse'
		}
		else quiet generate double `selsig' = 1 if `touse'
		quiet replace `phiz' = normal(`phiz' / `selsig') if `touse'
		quiet generate `vtyp' `varn' = `phiz' if `touse'
		label var `varn' "Prob. selection: P(`e(depvar)'> 0|z)"
		exit
	}
	
	if "`ressel'" != "" {
		tempvar selsig dy phiz
		quiet generate double `dy' = `e(depvar)' > 0 if `touse'
		_predict double `phiz' if `touse', equation(#1)
		if "`e(selhet)'" == "" {
			_predict double `selsig' if `touse', equation(#3)
			quiet replace `selsig' = exp(`selsig') if `touse'
		}
		else quiet generate double `selsig' = 1 if `touse'
		quiet replace `phiz' = `dy' - normal(`phiz' / `selsig') if `touse'
		quiet generate `vtyp' `varn' = `phiz' if `touse'
		label var `varn' "Participation prob. residuals: I(`e(depvar)'>0) -  P(`e(depvar)'>0|z)"
		exit
	}
	
	if "`xbsel'" != "" {
		_predict `vtyp' `varn' if `touse', equation(#1)
		label var `varn' "Selection equation fitted values (xb)"
		exit
	}
	
	if "`xbsig'" != "" {
		if "`e(selhet)'" != "" local eqn = 4
		else local eqn = 3
		_predict `vtyp' `varn' if `touse', equation(#`eqn')
		label var `varn' "Value equation fitted values (xb)"
		exit
	}
	
	if "`sigma'" != "" {
		tempvar sig
		if "`e(selhet)'" != "" local eqnum = 4
		else local eqnum = 3
		_predict double `sig' if `touse', equation(#`eqnum')
		quiet replace `sig' = exp(`sig') if `touse'
		quiet generate `vtyp' `varn' = `sig' if `touse'
		label var `varn' "Std. dev. of estimated value equation: exp(lnsigma)"
		exit
	}
	
	if "`selsigma'" != "" {
		if "`e(selhet)'" == "" {
			di as error "{bf: selsigma} not valid"
			exit 198
		}
		tempvar selsig
		_predict double `selsig' if `touse', equation(#3)
		quiet replace `selsig' = exp(`selsig') if `touse'
		quiet generate `vtyp' `varn' = `selsig' if `touse'
		label var `varn' "Std. dev. of the selection equation: exp(sellnsigma)"
		exit
	}
	
	if "`xbselsig'" != "" {
		if "`e(selhet)'" == ""{
			di as error "{bf:xbselsig} not valid"
			exit 198
		}
		_predict `vtyp' `varn' if `touse', equation(#3)
		label var `varn' "Fitted values for the natural log of standard deviation of selection"
		exit
	}
	
	
	// The default is ycen
	if "`ycen'" == "" noi di as txt "(option ycen assumed)"
	tempvar zg selsig sig mu
	_predict double `zg' if `touse', equation(#1)
	_predict double `mu' if `touse', equation(#2)
	if "`e(selhet)'" != "" {
		_predict double `selsig' if `touse', equation(#3)
		quiet replace `selsig' = exp(`selsig') if `touse'
		_predict double `sig' if `touse', equation(#4)
	}
	else {
		quiet generate double `selsig' = 1 if `touse'
		_predict double `sig' if `touse', equation(#3)
	}
	quiet replace `sig' = exp(`sig') if `touse'
	if "`e(est_model)'" == "linear"												///
		quiet replace `mu' = `mu' + `sig' * normalden(`mu' / `sig') /			///
			normal(`mu' / `sig') if `touse'
	else quiet replace `mu' = exp(`mu' + `sig'^2 / 2) if `touse'
	quiet replace `mu' = normal(`zg' / `selsig') * `mu' if `touse'
	quiet generate `vtyp' `varn' = `mu' if `touse'
	label var `varn' "Observed variable mean: E(`e(depvar)'|x,z)"
end


// TOBIT
// In Tobit the selection and value processes are the same. So there is only
// one heteroskedasticity (value).
capture program drop nehurdle_tobit_p
program define nehurdle_tobit_p, eclass
	syntax anything(id="newvarname") [if] [in]									///
	[, {																		///
		YCen			|														///
		RESCen			|														///
		VCen			|														///
		SIGCen			|														///
		PRCen(string)	|														///
		YTrun			|														///
		RESTrun			|														///
		VTrun			|														///
		SIGTrun			|														///
		PRTrun(string)	|														///
		YStar			|														///
		RESStar			|														///
		VStar			|														///
		SIGStar			|														///
		PRStar(string)	|														///
		XB				|														///
		XBVal			|														///
		RESVal			|														///
		PSel			|														///
		RESSEL			|														///
		SCores			|														///
		XBSIG			|														///
		SIGma																	///
	} * ]
		
	if "`scores'" != "" {
		local bvar "`e(depvar)'"
		tempvar y1
		if "`e(est_model)'" == "exponential" 									///
			quiet generate double `y1' = ln(`bvar')
		else quiet generate double `y1' = `bvar'
		ereturn local depvar "`y1'"
		
		marksample touse
		marksample touse2
		local xvars : colna e(b)
		local cons _cons _cons _cons _cons
		local xvars : list xvars - cons
		markout `touse2' `xvars'
		quiet replace `touse' = 0 if `bvar' > 0 & !`touse2'
		ml score `anything' if `touse', `scores' missing `options'
		ereturn local depvar "`bvar'"
		exit
	}
	
	local myopts "YCen RESCen VCen SIGCen PRCen(string) YTrun RESTrun VTrun"	
	local myopts "`myopts' SIGTrun PRTrun(string) YStar RESStar VStar SIGStar"	
	local myopts "`myopts' PRStar(string) XB XBVal RESVal PSel RESSEL XBSIG SIGma"
	_pred_se "`myopts'" `0'
	if `s(done)' exit
	local vtyp  `s(typ)'
	local varn `s(varn)'
	local 0 `"`s(rest)'"'
	
	// Mark sample
	marksample touse
	
	if "`xb'" != "" {
		di as error "option {bf:xb} not valid"
		di as error "Try one of the following:"
		di as error _col(6) "1. {bf:xbval} for fitted values of the value equation."
		di as error _col(6) "2. {bf:xbsig} for fitted values of ln sigma."
		exit 198
	}
	
	// ycen is the default so it will be done last.
	if "`rescen'" != "" {
		tempvar mu sig
		_predict double `mu' if `touse', equation(#1)
		_predict double `sig' if `touse', equation(#2)
		quiet replace `sig' = exp(`sig') if `touse'
		if "`e(est_model)'" == "linear"	{
			quiet replace `mu' = normal(`mu'/`sig') *`mu' + `sig' *				///
				normalden(`mu' / `sig') if `touse'
		}
		else {
			quiet replace `mu' = exp(`mu' + `sig'^2/2) * normal((`sig'^2 +		///
				`mu' - `e(gamma)')/`sig') if `touse'
		}
		quiet replace `mu' = `e(depvar)' - `mu' if `touse'
		quiet generate `vtyp' `varn' = `mu' if `touse'
		label var `varn' "Observed variable residuals: `e(depvar)' - E(`e(depvar)'|x)"
		exit
	}
	
	if "`vcen'" != "" {
		tempvar mu sig phi
		_predict double `mu' if `touse', equation(#1)
		_predict double `sig' if `touse', equation(#2)
		quiet replace `sig' = exp(`sig') if `touse'
		quiet generate double `phi' = normal(`mu' / `sig') if `touse'
		if "`e(est_model)'" == "linear" {
			tempvar lam nphi
			quiet generate double `nphi' = normal(- `mu' / `sig') if `touse'
			quiet generate double `lam' = normalden(`mu' / `sig') / `phi' if	///
				`touse'
			quiet replace `mu' = `sig'^2 * (1 + (`mu' / `sig' + `lam') *		///
				(`mu' / `sig' * `nlam' - normalden(`mu' / `sig'))) if `touse'
		}
		else {
			quiet replace `mu' = exp(2 * `mu' + `sig'^2) * (exp(`sig'^2) *		///
				normal((`mu' - `e(gamma)') / `sig' + 2 * `sig') +				///
				(normal((`mu' - `e(gamma)') / `sig' + `sig'))^2) if `touse'
		}
		quiet generate `vtyp' `varn' = `mu' if `touse'
		label var `varn' "Observed variable variance: V(`e(depvar)'|x)"
		exit
	}
	
	if "`sigcen'" != "" {
		tempvar mu sig phi
		_predict double `mu' if `touse', equation(#1)
		_predict double `sig' if `touse', equation(#2)
		quiet replace `sig' = exp(`sig') if `touse'
		quiet generate double `phi' = normal(`mu' / `sig') if `touse'
		if "`e(est_model)'" == "linear" {
			tempvar lam nphi
			quiet generate double `nphi' = normal(- `mu' / `sig') if `touse'
			quiet generate double `lam' = normalden(`mu' / `sig') / `phi' if	///
				`touse'
			quiet replace `mu' = `sig'^2 * (1 + (`mu' / `sig' + `lam') *		///
				(`mu' / `sig' * `nlam' - normalden(`mu' / `sig'))) if `touse'
		}
		else {
			quiet replace `mu' = exp(2 * `mu' + `sig'^2) * (exp(`sig'^2) *		///
				normal((`mu' - `e(gamma)') / `sig' + 2 * `sig') +				///
				(normal((`mu' - `e(gamma)') / `sig' + `sig'))^2) if `touse'
		}
		quiet replace `mu' = sqrt(`mu') if `touse'
		quiet generate `vtyp' `varn' = `mu' if `touse'
		label var `varn' "Observed variable std. dev.: sd(`e(depvar)'|x)"
		exit
	}
	
	if "`prcen'" != "" {
		// So this is the normal probability for any positive value. In addition
		// we have that we can have the probability that y = 0, which is the
		// same as y* < 0. So all we have to check is that if it's an individual
		// value, that it is zero, and that we cannot have negative values.
		
		local cpos = strpos("`prcen'", ",")
		if `cpos' == 0 {
			if "`prcen'" != "0" {
				di as error "only two values/variables separated by comma (,) or 0 are suitable arguments"
				exit 198
			}
			else {
				// probability of 0
				tempvar mu sig
				_predict double `mu' if `touse', equation(#1)
				_predict double `sig' if `touse', equation(#2)
				quiet replace `sig' = exp(`sig') if `touse'
				if "`e(est_model)'" == "linear"									///
					quiet replace `mu' = normal(- `mu' / `sig') if `touse'
				else {
					quiet replace `mu' = normal(`e(gamma)' - `mu' / `sig') if	///
						`touse'
				}
				quiet generate `vtyp' `varn' = `mu' if `touse'
				label var `varn' "Prob. observed variable: P(`e(depvar)'=0|x)"
				exit
			}
		}
		
		local left = substr("`prcen'",1,`cpos' - 1)
		local right = substr("`prcen'", `cpos' + 1, .)
		
		// Now check that right doesn't have another comma.
		local cpos = strpos("`right'" , ",")
		if `cpos' > 0 {
			di as error "Too many arguments"
			exit 198
		}
		
		// Check both are not missing
		if "`left'" == "." & "`right'" == "." {
			di as error "Both arguments cannot be ."
			exit 198
		}
		
		nehurdle_parse_probopts `left' if `touse'
		if `s(nh_res)' > 0 {
			di as error "The first argument needs to be numeric or ."
			exit 198
		}
		
		nehurdle_parse_probopts `right' if `touse'
		if `s(nh_res)' > 0 {
			di as error "The second argument needs to be numeric or ."
			exit 198
		}
		
		tempvar mu sig
		_predict double `mu' if `touse', equation(#1)
		_predict double `sig' if `touse', equation(#2)
		quiet replace `sig' = exp(`sig') if `touse'
		
		if "`left'" == "." {
			// prob less than
			// check that right is greater than zero and not missing
			tempvar check
			quiet generate byte `check' = (`right'<= 0) if `touse'
			quiet summarize `check' if `touse', mean
			if r(sum) > 0 {
				di as error "The second argument has to be positive"
				exit 198
			}
			quiet replace `check' = missing(`right') if `touse'
			quiet summarize `check' if `touse', mean
			if r(sum) > 0 {
				di as error "The second argument cannot have missing values"
				exit 198
			}
			drop `check'
			
			if "`e(est_model)'" == "exponential" {
				quiet replace `mu' = normal((ln(`right') - `mu') / `sig') if	///
					`touse'
			}
			else {
				quiet replace `mu' = normal((`right' - `mu') / `sig') if `touse'
			}
			quiet generate `vtyp' `varn' = `mu' if `touse'
			label var `varn' "Prob. observed value: P(`e(depvar)'<`right'|x)"
			exit
		}
		
		if "`right'" == "." {
			// Probability greater than.
			// Check that left is not negative or missing
			tempvar check
			quiet generate byte `check' = (`left' < 0) if `touse'
			quiet summarize `check' if `touse', mean
			if r(sum) > 0 {
				di as error "The first argument cannot be negative"
				exit 198
			}
			quiet replace `check' = missing(`left') if `touse'
			quiet summarize `check' if `touse', mean
			if r(sum) > 0 {
				di as error "The first argument cannot have missing values"
				exit 198
			}
			drop `check'
			
			// Now do the same checking as before to transform left if lognormal.
			capture confirm var `left'
			if !_rc {
				tempvar lnleft
				quiet generate double `lnleft' = `left' if `touse'
				if "`e(est_model)'" == "exponential" {
					quiet replace `lnleft' = exp(`e(gamma)') if `touse' &		///
						`lnleft' == 0
					quiet replace `lnleft' = ln(`lnleft') if `touse'
				}
			}
			else {
				if "`e(est_model)'" == "exponential" {
					if "`left'" == "0" local lnleft = `e(gamma)'
					else local lnleft = ln(`left')
				}
				else local lnleft = `left'
			}
			
			quiet replace `mu' = normal((`mu' - `lnleft') / `sig') if `touse'
			quiet generate `vtyp' `varn' = `mu' if `touse'
			label var `varn' "Prob. observed variable: P(`e(depvar)'>`left'|x)"
			exit
		}
		
		// Probability that it falls inside a range.
		// check left is not negative or missing
		tempvar check
		quiet generate byte `check' = (`left' < 0 ) if `touse'
		quiet summarize `check' if `touse', mean
		if r(sum) > 0 {
			di as error "The first argument cannot be negative"
			exit 198
		}
		
		quiet replace `check' = missing(`left' , `right') if `touse'
		quiet summarize `check' if `touse', mean
		if r(sum) > 0 {
			di as error "Neither argument can have missing values"
			exit 198
		}
		
		// Check right is greater than left
		quiet replace `check' = (`right'<=`left') if `touse'
		quiet summarize `check' if `touse', mean
		if r(sum) > 0 {
			di as error "The second argument has to be greater than the first"
			exit 198
		}
		
		// Now do the transformation for the left if exponential
		if "`e(est_model)'" == "exponential" {
			capture confirm var `left'
			if !_rc {
				tempvar lnleft
				quiet generate double `lnleft' = `left' if `touse'
				quiet replace `lnleft' = exp(`e(gamma)') if `touse' &			///
					`lnleft' == 0
				quiet replace `lnleft' = ln(`lnleft') if `touse'
			}
			else {
				if "`left'" == "0" local lnleft = `e(gamma)'
				else local lnleft = ln(`left')
			}
			quiet replace `mu' = normal((ln(`right') - `mu') / `sig') - 		///
				normal((`lnleft' - `mu') / `sig') if `touse'
		}
		else {
			quiet replace `mu' = normal((`right' - `mu') / `sig') -				///
				normal((`left' - `mu') / `sig') if `touse'
		}
		quiet generate `vtyp' `varn' = `mu' if `touse'
		label var `varn' "Prob. observed variable: P(`left'<`e(depvar)'<`right'|x)"
		exit
	}
	
	if "`ytrun'" != "" {
		tempvar mu sig
		_predict double `mu' if `touse', equation(#1)
		_predict double `sig' if `touse', equation(#2)
		quiet replace `sig' = exp(`sig') if `touse'
		if "`e(est_model)'" == "linear" {
			quiet replace `mu' = `mu' + `sig' * normalden(`mu' / `sig') /		///
				normal(`mu' / `sig') if `touse'
		}
		else {
			quiet replace `mu' = exp(`mu' + `sig'^2/2) * normal((`sig'^2 + `mu'	///
				- e(gamma))/`sig') / normal((`mu' - e(gamma))/`sig') if `touse'
		}
		quiet generate `vtyp' `varn' = `mu' if `touse'
		label var `varn' "Truncated variable mean: E(`e(depvar)'|x,`e(depvar)'>0)"
		exit
	}
	
	if "`restrun'" != "" {
		tempvar mu sig
		_predict double `mu' if `touse', equation(#1)
		_predict double `sig' if `touse', equation(#2)
		quiet replace `sig' = exp(`sig') if `touse'
		if "`e(est_model)'" == "linear" {
			quiet replace `mu' = `mu' + `sig' * normalden(`mu' / `sig') /		///
				normal(`mu' / `sig') if `touse'
		}
		else {
			quiet replace `mu' = exp(`mu' + `sig'^2/2) * normal((`sig'^2 + `mu'	///
				- e(gamma))/`sig') / normal((`mu' - e(gamma))/`sig') if `touse'
		}
		quiet replace `mu' = `e(depvar)' - `mu' if `touse'
		quiet generate `vtyp' `varn' = `mu' if `touse'
		label var `varn' "Truncated variable residuals: `e(depvar)' - E(`e(depvar)'*|x,`e(depvar)'*> 0)"
		exit
	}
	
	if "`vtrun'" != "" {
		tempvar mu sig phi
		_predict double `mu' if `touse', equation(#1)
		_predict double `sig' if `touse', equation(#2)
		quiet replace `sig' = exp(`sig') if `touse'
		quiet generate double `phi' = normal(`mu' / `sig')
		if "`e(est_model)'" == "linear" {
			tempvar lam
			quiet generate double `lam' = normalden(`mu' / `sig') / `phi' if	///
				`touse'
			quiet replace `mu' = `sig'^2 * (1 - `lam' * (`mu' / `sig' + `lam'))	///
				if `touse'
		}
		else {
			quiet replace `phi' = normal((`mu' - `e(gamma)') / `sig')
			quiet replace `mu' = exp(2 * `mu' + `sig'^2) * (exp(`sig')^2 *		///
				normal((`mu' - `e(gamma)') / `sig' + 2 * `sig') / `phi' -		///
				(normal((`mu' - `e(gamma)') / `sig' + `sig') / `phi')^2) if		///
				`touse'
		}
		quiet generate `vtyp' `varn' = `mu' if `touse'
		label var `varn' "Truncated variable variance: V(`e(depvar)'*|x,`e(depvar)'*>0)"
		exit
	}
	
	if "`sigtrun'" != "" {
		tempvar mu sig phi
		_predict double `mu' if `touse', equation(#1)
		_predict double `sig' if `touse', equation(#2)
		quiet replace `sig' = exp(`sig') if `touse'
		quiet generate double `phi' = normal(`mu' / `sig')
		if "`e(est_model)'" == "linear" {
			tempvar lam
			quiet generate double `lam' = normalden(`mu' / `sig') / `phi' if	///
				`touse'
			quiet replace `mu' = `sig'^2 * (1 - `lam' * (`mu' / `sig' + `lam'))	///
				if `touse'
		}
		else {
			quiet replace `phi' = normal((`mu' - `e(gamma)') / `sig')
			quiet replace `mu' = exp(2 * `mu' + `sig'^2) * (exp(`sig')^2 *		///
				normal((`mu' - `e(gamma)') / `sig' + 2 * `sig') / `phi' -		///
				(normal((`mu' - `e(gamma)') / `sig' + `sig') / `phi')^2) if		///
				`touse'
		}
		quiet replace `mu' = sqrt(`mu') if `touse'
		quiet generate `vtyp' `varn' = `mu' if `touse'
		label var `varn' "Truncated variable std. dev.: sd(`e(depvar)'*|x,`e(depvar)'*>0)"
		exit
	}
	
	if "`prtrun'" != "" {
		local cpos = strpos("`prtrun'", ",")
		if `cpos' == 0 {
			di as error "only two values/variables separated by comma (,) are suitable arguments"
			exit 198
		}
		
		local left = substr("`prtrun'",1,`cpos' - 1)
		local right = substr("`prtrun'", `cpos' + 1, .)
		
		// Now check that right doesn't have another comma.
		local cpos = strpos("`right'" , ",")
		if `cpos' > 0 {
			di as error "Too many arguments"
			exit 198
		}
		
		// Check both are not missing
		if "`left'" == "." & "`right'" == "." {
			di as error "Both arguments cannot be ."
			exit 198
		}
		
		nehurdle_parse_probopts `left' if `touse'
		if `s(nh_res)' > 0 {
			di as error "The first argument needs to be numeric or ."
			exit 198
		}
		nehurdle_parse_probopts `right' if `touse'
		if `s(nh_res)' > 0 {
			di as error "The second argument needs to be numeric or ."
			exit 198
		}
		
		tempvar mu sig phi
		_predict double `mu' if `touse', equation(#1)
		_predict double `sig' if `touse', equation(#2)
		quiet replace `sig' = exp(`sig') if `touse'
		
		if "`e(est_model)'" == "exponential" {
			quiet generate double `phi' = normal((`mu' - `e(gamma)') / `sig')	///
				if `touse'
		}
		else 																	///
			quiet generate double `phi' = normal(`mu' / `sig') if `touse'
		
		if "`left'" == "." {
			// check right is greater than zero and not missing
			tempvar check
			quiet generate byte `check' = (`right' <= 0) if `touse'
			quiet summarize `check' if `touse', mean
			if r(sum) > 0 {
				di as error "The second argument has to be positive"
				exit 198
			}
			quiet replace `check' = missing(`right') if `touse'
			quiet summarize `check' if `touse', mean
			if r(sum) > 0 {
				di as error "The second argument cannot have missing values"
				exit 198
			}
			drop `check'
			
			if "`e(est_model)'" == "exponential" {
				quiet replace `mu' = 											///
					(normal((ln(`right') - `mu') / `sig') - 					///
					normal((`e(gamma)' - `mu') / `sig')) / `phi' if `touse'
			}
			else {
				quiet replace `mu' = (normal((`right' - `mu') / `sig') -		///
					normal(- `mu' / `sig')) / `phi' if `touse'
			}
			quiet generate `vtyp' `varn' = `mu' if `touse'
			label var `varn' "Prob. truncated variable: P(`e(depvar)'*<`right'|x,`e(depvar)'*>0)"
			exit
		}
		
		if "`right'" == "." {
			// Check left is positive and not missing
			tempvar check
			quiet generate byte `check' = (`left' <= 0) if `touse'
			quiet summarize `check' if `touse', mean
			if r(sum) > 0 {
				di as error "The first argument must be positive"
				exit 198
			}
			
			quiet replace `check' = missing(`left') if `touse'
			quiet summarize `check' if `touse', mean
			if r(sum) > 0 {
				di as error "The first argument cannot have missing values"
				exit 198
			}
			drop `check'
			
			if "`e(est_model)'" == "exponential" {
				quiet replace `mu' = normal((`mu' - ln(`left')) / `sig') / `phi' ///
					if `touse'
			}
			else {
				quiet replace `mu' = normal((`mu' - `left') / `sig') / `phi'	///
					if `touse'
			}
			quiet generate `vtyp' `varn' = `mu' if `touse'
			label var `varn' "Prob. truncated variable: P(`e(depvar)'*>`left'|x,`e(depvar)'*>0)"
			exit
		}
		
		// Probability of a range. Check left is positive, right is greater than
		// left and neither is missing.
		tempvar check
		quiet generate byte `check' = (`left'<=0) if `touse'
		quiet summarize `check' if `touse', mean
		if r(sum) > 0 {
			di as error "First argument must be positive"
			exit 198
		}
		
		quiet replace `check' = (`right'<=`left') if `touse'
		quiet summarize `check' if `touse', mean
		if r(sum) > 0 {
			di as error "Second argument must be greater than first"
			exit 198
		}
		
		quiet replace `check' = missing(`left',`right') if `touse'
		quiet summarize `check' if `touse', mean
		if r(sum) > 0 {
			di as error "Neither argument can have missing values"
			exit 198
		}
		drop `check'
		
		if "`e(est_model)'" == "exponential" {
			quiet replace `mu' = (normal((ln(`right') - `mu') / `sig') -		///
				normal((ln(`left') - `mu') / `sig')) / `phi' if `touse'
		}
		else {
			quiet replace `mu' = (normal((`right' - `mu') / `sig') -			///
				normal((`left' - `mu') / `sig')) / `phi' if `touse'
		}
		quiet generate `vtyp' `varn' = `mu' if `touse'
		label var `varn' "Prob. truncated variable: P(`left'<`e(depvar)'*<`right'|x,`e(depvar)'*>0)"
		exit
	}
	
	if "`ystar'" != "" {
		tempvar mu
		_predict double `mu' if `touse', equation(#1)
		if "`e(est_model)'" == "exponential" {
			tempvar sig
			_predict double `sig' if `touse', equation(#2)
			quiet replace `mu' = exp(`mu' + exp(2* `sig') / 2) if `touse'
		}
		quiet generate `vtyp' `varn' = `mu' if `touse'
		label var `varn' "Latent variable mean: E(`e(depvar)'*|x)"
		exit
	}
	
	if "`vstar'" != "" {
		tempvar sig
		_predict double `sig' if `touse', equation(#2)
		quiet replace `sig' = exp(`sig') if `touse'
		if "`e(est_model)'" == "exponential" {
			tempvar mu
			_predict double `mu' if `touse', equation(#1)
			quiet replace `sig' = exp(2 * `mu' + `sig'^2) * (exp(`sig'^2) - 1)	///
				if `touse'
		}
		else quiet replace `sig' = `sig'^2 if `touse'
		quiet generate `vtyp' `varn' = `sig' if `touse'
		label var `varn' "Latent variable variance: V(`e(depvar)'*|x)"
		exit
	}
	
	if "`sigstar'" != "" {
		tempvar sig
		_predict double `sig' if `touse', equation(#2)
		quiet replace `sig' = exp(`sig') if `touse'
		if "`e(est_model)'" == "exponential" {
			tempvar mu
			_predict double `mu' if `touse', equation(#1)
			quiet replace `sig' = exp(2 * `mu' + `sig'^2) * (exp(`sig'^2) - 1)	///
				if `touse'
			quiet replace `sig' = sqrt(`sig') if `touse'
		}
		quiet generate `vtyp' `varn' = `sig' if `touse'
		label var `varn' "Latent variable std. dev.: sd(`e(depvar)'*|x)"
		exit
	}
	
	if "`resstar'" != "" {
		tempvar mu
		_predict double `mu' if `touse', equation(#1)
		if "`e(est_model)'" == "exponential" {
			tempvar sig
			_predict double `sig' if `touse', equation(#2)
			quiet replace `mu' = exp(`mu' + exp(2* `sig') / 2) if `touse'
		}
		quiet replace `mu' = `e(depvar)' - `mu' if `touse'
		quiet generate `vtyp' `varn' = `mu' if `touse'
		label var `varn' "Latent variable residuals: `e(depvar)' - E(`e(depvar)'*|x)"
		exit
	}
	
	if "`prstar'" != "" {
		local cpos = strpos("`prstar'", ",")
		if `cpos' == 0 {
			di as error "only two values/variables separated by comma (,) are suitable arguments"
			exit 198
		}
		
		local left = substr("`prstar'",1,`cpos' - 1)
		local right = substr("`prstar'", `cpos' + 1, .)
		
		// Now check that right doesn't have another comma.
		local cpos = strpos("`right'" , ",")
		if `cpos' > 0 {
			di as error "Too many arguments"
			exit 198
		}
		
		// Check both are not missing
		if "`left'" == "." & "`right'" == "." {
			di as error "Both arguments cannot be ."
			exit 198
		}
		
		nehurdle_parse_probopts `left' if `touse'
		if `s(nh_res)' > 0 {
			di as error "The first argument needs to be numeric or ."
			exit 198
		}
		
		nehurdle_parse_probopts `right' if `touse'
		if `s(nh_res)' > 0 {
			di as error "The second argument needs to be numeric or ."
			exit 198
		}
		
		// Predicitions needed for all estimations.
		tempvar mu sig
		_predict double `mu' if `touse', equation(#1)
		_predict double `sig' if `touse', equation(#2)
		quiet replace `sig' = exp(`sig') if `touse'
		
		if "`left'" == "." {
			// Probability less than right. Check right is not missing.
			tempvar check
			quiet generate byte `check' = missing(`right') if `touse'
			quiet summarize `check' if `touse', mean
			if r(sum) > 0 {
				di as error "The second argument cannot hve missing values"
				exit 198
			}
			
			if "`e(est_model)'" == "exponential" {
				// Here we have to check that right is not negative
				quiet replace `check' = (`right'< 0) if `touse'
				quiet summarize `check' if `touse', mean
				if r(sum) > 0 {
					di as error "The second argument cannot be negative"
					exit 198
				}
				
				capture confirm var `right'
				if !_rc {
					tempvar right
					quiet generate double `lnright' = `right' if `touse'
					quiet replace `lnright' = 1e-20 if `touse' & `lnright' == 0
				}
				else if "`right'" == "0" local lnright = 1e-20
				else local lnright = `right'
				
				quiet replace `mu' = normal((ln(`lnright') - `mu') / `sig') if	///
					`touse'
			}
			else {
				quiet replace `mu' = normal((`right' - `mu') / `sig') if `touse'
			}
			drop `check'
			quiet generate `vtyp' `varn' = `mu' if `touse'
			label var `varn' "Prob. latent variable: P(`e(depvar)'*<`right'|x)"
			exit
		}
		
		if "`right'" == "." {
			// Probability greater than.
			// Check left is not msising
			tempvar check
			quiet generate byte `check' = missing(`left') if `touse'
			quiet summarize `check' if `touse', mean
			if r(sum) > 0 {
				di as error "The first argument cannot have missing values"
				exit 198
			}
			
			if "`e(est_model)'" == "exponential" {
				// Have to check left is not negative and capture zeroes.
				// Only needed for a variable becaue if it had been a single
				// value we would have set left to .
				quiet replace `check' = (`left' < 0) if `touse'
				quiet summarize `check' if `touse', mean
				if r(sum) > 0 {
					di as error "The first argument cannot be negative"
					exit 198
				}
				
				capture confirm var `left'
				if !_rc {
					tempvar lnleft
					quiet generate lnleft = `left' if `touse'
					quiet replace `lnleft' = 1e-20 if `touse' & `lnleft' == 0
				}
				else if "`left'" == "0" local lnleft = 1e-20
				else local lnleft = `left'
				
				quiet replace `mu' = normal((`mu' - ln(`lnleft')) / `sig') if	///
					`touse'
			}
			else {
				quiet replace `mu' = normal((`mu' - `left') / `sig') if `touse'
			}
			drop `check'
			quiet generate `vtyp' `varn' = `mu' if `touse'
			label var `varn' "Prob. latent variable: P(`e(depvar)'*>`left'|x)"
			exit
		}
		
		// Ok probability of an interval. Need to check that neither variable
		// has missing values, that right is greater than left. Also if exponential
		// have to check that left is not negative and capture zeroes.
		tempvar check
		quiet generate byte `check' = missing(`left',`right') if `touse'
		quiet summarize `check' if `touse', mean
		if r(sum) > 0 {
			di as error "Neither argument can have missing values"
			exit 198
		}
		quiet replace `check' = (`right'<=`left') if `touse'
		quiet summarize `check' if `touse', mean
		if r(sum) > 0 {
			di as error "The second argument has to be greater than the first"
			exit 198
		}
		drop `check'
		
		if "`e(est_model)'" == "exponential" {
			tempvar check
			quiet generate byte `check' = (`left' < 0) if `touse'
			quiet summarize `check' if `touse', mean
			if r(sum) > 0 {
				di as error "The first argument cannot be negative"
				exit 198
			}
			drop `check'
			
			capture confirm var `left'
			if !_rc {
				tempvar lnleft
				quiet generate double `lnleft' = `left' if `touse'
				quiet replace `lnleft' = 1e-20 if `touse' & `lnleft' == 0
			}
			else if "`left'" == "0" local lnleft = 1e-20
			else local lnleft = `left'
			
			quiet replace `mu' = normal((ln(`right') - `mu') / `sig') -			///
				normal((ln(`lnleft') - `mu') / `sig') if `touse'
		}
		else {
			quiet replace `mu' = normal((`right' - `mu') / `sig') -				///
				normal((`left' - `mu') / `sig') if `touse'
		}
		quiet generate `vtyp' `varn' = `mu' if `touse'
		label var `varn' "Prob. latent variable: P(`left'<`e(depvar)'*<`right'|x)"
		exit
	}
	
	if "`xbval'" != "" {
		_predict `vtyp' `varn' if `touse', equation(#1)
		label var `varn' "Fitted values of value equation: xb"
		exit
	}
	
	if "`resval'" != "" {
		tempvar mu
		_predict double `mu' if `touse', equation(#1)
		if "`e(est_model)'" == "linear"	{
			quiet replace `mu' = `e(depvar)' - `mu' if `touse'
			local labv "Value equation residuals: `e(depvar)' - xb"
		}
		else {
			quiet replace `mu' = ln(`e(depvar)') - `mu' if `touse'
			local labv "Value equation residuals: ln(`e(depvar)') - xb"
		}
		quiet generate `vtyp' `varn' = `mu' if `touse'
		label var `varn' "`labv'"
		exit
	}
	
	if "`psel'" != "" {
		tempvar mu sig
		_predict double `mu' if `touse', equation(#1)
		_predict double `sig' if `touse', equation(#2)
		quiet replace `sig' = exp(`sig') if `touse'
		if "`e(est_model)'" == "linear"											///
			quiet replace `mu' = normal(`mu' / `sig') if `touse'
		else																	///
			quiet replace `mu' = normal((`mu' - `e(gamma)') / `sig') if `touse'
		quiet generate `vtyp' `varn' = `mu' if `touse'
		label var `varn' "Prob. selection: Pr(`e(depvar)'>0|x)"
		exit
	}
	
	if "`ressel'" != "" {
		tempvar sig dy mu
		quiet generate double `dy' = `e(depvar)' > 0 if `touse'
		_predict double `mu' if `touse', equation(#1)
		_predict double `sig' if `touse', equation(#2)
		quiet replace `sig' = exp(`sig') if `touse'
		quiet replace `mu' = `dy' - normal(`mu' / `sig') if `touse'
		quiet generate `vtyp' `varn' = `mu' if `touse'
		label var `varn' "Residual of selection: I(`e(depvar)'>0) - Pr(`e(depvar)'>0|x)"
		exit
	}
	
	if "`xbsig'" != "" {
		_predict `vtyp' `varn' if `touse', equation(#2)
		label var `varn' "Value equation ln of std. dev.: lnsigma"
		exit
	}
	
	if "`sigma'" != "" {
		tempvar sig
		_predict double `sig' if `touse', equation(#2)
		quiet replace `sig' = exp(`sig') if `touse'
		quiet generate `vtyp' `varn' = `sig' if `touse'
		label var `varn' "Value equaion std. dev.: exp(lnsigma)"
		exit
	}
	
	// ycen is the default
	if "`ycen'" == "" noi di as txt "(option ycen assumed)"
	tempvar mu sig
	_predict double `mu' if `touse', equation(#1)
	_predict double `sig' if `touse', equation(#2)
	quiet replace `sig' = exp(`sig') if `touse'
	if "`e(est_model)'" == "linear" {
		quiet replace `mu' = normal(`mu'/`sig') * `mu' + `sig' * normalden(`mu'	///
			/ `sig') if `touse'
	}
	else {
		quiet replace `mu' = exp(`mu' + `sig'^2/2) * normal((`sig'^2 + `mu' -	///
			`e(gamma)') / `sig') if `touse'
	}
	quiet generate `vtyp' `varn' = `mu' if `touse'
	label var `varn' "Observed variable mean: E(`e(depvar)'|x)"
end


// HECKMAN
capture program drop nehurdle_heckman_p
program define nehurdle_heckman_p, eclass
	syntax anything(id="newvarname") [if] [in]									///
	[, {																		///
		YCen			|														///
		RESCen			|														///
		VCen			|														///
		SIGCen			|														///
		PRCen(string)	|														///
		YTrun			|														///
		RESTrun			|														///
		VTrun			|														///
		SIGTrun			|														///
		PRTrun(string)	|														///
		YStar			|														///
		RESStar			|														///
		VStar			|														///
		SIGStar			|														///
		PRStar(string)	|														///
		XBVal			|														///
		RESVal			|														///
		PSel			|														///
		RESSEL			|														///
		SCores			|														///
		XB				|														///
		XBSel			|														///
		XBSIG			|														///
		SIGma			|														///
		SELSIGma		|														///
		XBSELSig		|														///
		LAMbda																	///
	} * ]
	
	if "`scores'" != "" {
		local bvar "`e(depvar)'"
		tempvar dy y1
		quiet generate byte `dy' = `bvar' > 0
		if "`e(est_model)'" == "exponential" 									///
			quiet generate double `y1' = ln(`bvar')
		else quiet generate double `y1' = `bvar'
		ereturn local depvar "`dy' `y1'"
		
		marksample touse
		marksample touse2
		local xvars : colna e(b)
		local cons _cons _cons _cons _cons
		local xvars : list xvars - cons
		markout `touse2' `xvars'
		quiet replace `touse' = 0 if `dy' & !`touse2'
		ml score `anything' if `touse', `scores' missing `options'
		ereturn local depvar "`bvar'"
		exit
	}
		
	local myopts "YCen RESCen VCen SIGCen PRCen(string) YTrun RESTrun VTrun"
	local myopts "`myopts' SIGTrun PRTrun(string) YStar RESStar VStar SIGStar"
	local myopts "`myopts' PRStar(string) XBVal RESVal PSel RESSEL XB XBSel"
	local myopts "`myopts' XBSIG SIGma SELSIGma XBSELSig LAMbda"
	
	_pred_se "`myopts'" `0'
	if `s(done)' exit
	local vtyp  `s(typ)'
	local varn `s(varn)'
	local 0 `"`s(rest)'"'
	
	// Marking sample
	marksample touse
	
	// Have to capture xb to notify it is not valid.
	if "`xb'" != "" {
		di as error "option {bf:xb} not valid"
		di as error "Try one of the following:"
		di as error _col(6) "1. {bf:xbval} for fitted values of the value equation."
		di as error _col(6) "2. {bf:xbsel} for fitted values of the selection equation."
		if "`e(selhet)'" != "" {
			di as error _col(6) "3. {bf:xbselsig} for fitted values of the selection ln sigma."
			di as error _col(6) "4. {bf:xbsig} for fitted values of the value ln sigma."
		}
		else																	///
			di as error _col(6) "3. {bf:xbsig} for fitted values of the value ln sigma."
		exit 198
	}
	
	// ycen is the default and is done last
	if "`rescen'" != "" {
		tempvar mu zg selsig sig rho
		_predict double `zg' if `touse', equation(#1)
		_predict double `mu' if `touse', equation(#2)
		if "`e(selhet)'" != "" {
			_predict double `selsig' if `touse', equation(#3)
			quiet replace `selsig' = exp(`selsig') if `touse'
			_predict double `sig' if `touse', equation(#4)
			_predict double `rho' if `touse', equation(#5)
		}
		else {
			quiet generate double `selsig' = 1 if `touse'
			_predict double `sig' if `touse', equation(#3)
			_predict double `rho' if `touse', equation(#4)
		}
		quiet replace `sig' = exp(`sig') if `touse'
		quiet replace `rho' = tanh(`rho') if `touse'
		if "`e(est_model)'" == "linear"											///
			quiet replace `mu' = `mu' + `sig' * `rho' * normalden(`zg' /		///
				`selsig') / normal(`zg' / `selsig') if `touse'
		else																	///
			quiet replace `mu' = exp(`mu' + `sig'^2 / 2) * normal(`zg' /		///
				`selsig' + `rho' * `sig') / normal(`zg' / `selsig') if `touse'
		quiet replace `mu' = `e(depvar)' - normal(`zg' / `selsig') *		///
			`mu' if `touse'
		quiet generate `vtyp' `varn' = `mu' if `touse'
		label var `varn' "Observed variable residuals: `e(depvar)' - E(`e(depvar)'|x,z)"
		exit
	}
	
	if "`vcen'" != "" {
		tempvar mu zg selsig sig rho
		_predict double `zg' if `touse', equation(#1)
		_predict double `mu' if `touse', equation(#2)
		if "`e(selhet)'" != "" {
			_predict double `selsig' if `touse', equation(#3)
			quiet replace `selsig' = exp(`selsig') if `touse'
			_predict double `sig' if `touse', equation(#4)
			_predict double `rho' if `touse', equation(#5)
		}
		else {
			quiet generate double `selsig' = 1 if `touse'
			_predict double `sig' if `touse', equation(#3)
			_predict double `rho' if `touse', equation(#4)
		}
		quiet replace `sig' = exp(`sig') if `touse'
		quiet replace `rho' = tanh(`rho') if `touse'
		
		quiet replace `zg' = `zg' / `selsig' if `touse'
		
		if "`e(est_model)'" == "exponential" {
			quiet replace `mu' = exp(2 * `mu' + `sig'^2) * ( exp(`sig'^2) *		///
				normal(`zg' + 2 * `rho' * `sig') - normal(`zg' + `rho' *		///
				`sig')^2) if `touse'
		}
		else	{
			quiet replace `mu' = `mu' / `sig' if `touse'
			
			quiet replace `mu' = normal(`zg') * `sig'^2 * (1 + `mu'^2 *			///
				normal(-`zg') + normalden(`zg') / normal(`zg') * `rho' *		///
				(2 * `mu' * normal(-`zg') - `rho' * (`zg' + normalden(`zg'))))	///
				if `touse'
		}
		quiet generate `vtyp' `varn' = `mu' if `touse'
		label var `varn' "Observed variable variance: V(`e(depvar)'|x,z)"
		exit
	}
	
	if "`sigcen'" != "" {
		tempvar mu zg selsig sig rho
		_predict double `zg' if `touse', equation(#1)
		_predict double `mu' if `touse', equation(#2)
		if "`e(selhet)'" != "" {
			_predict double `selsig' if `touse', equation(#3)
			quiet replace `selsig' = exp(`selsig') if `touse'
			_predict double `sig' if `touse', equation(#4)
			_predict double `rho' if `touse', equation(#5)
		}
		else {
			quiet generate double `selsig' = 1 if `touse'
			_predict double `sig' if `touse', equation(#3)
			_predict double `rho' if `touse', equation(#4)
		}
		quiet replace `sig' = exp(`sig') if `touse'
		quiet replace `rho' = tanh(`rho') if `touse'
		
		quiet replace `zg' = `zg' / `selsig' if `touse'
		
		if "`e(est_model)'" == "exponential" {
			quiet replace `mu' = exp(2 * `mu' + `sig'^2) * ( exp(`sig'^2) *		///
				normal(`zg' + 2 * `rho' * `sig') - normal(`zg' + `rho' *		///
				`sig')^2) if `touse'
		}
		else	{
			quiet replace `mu' = `mu' / `sig' if `touse'
			
			quiet replace `mu' = normal(`zg') * `sig'^2 * (1 + `mu'^2 *			///
				normal(-`zg') + normalden(`zg') / normal(`zg') * `rho' *		///
				(2 * `mu' * normal(-`zg') - `rho' * (`zg' + normalden(`zg'))))	///
				if `touse'
		}
		quiet replace `mu' = sqrt(`mu') if `touse'
		quiet generate `vtyp' `varn' = `mu' if `touse'
		label var `varn' "Observed variable std. dev.: sd(`e(depvar)'|x,z)"
		exit
	}
	
	if "`prcen'" != "" {
		local cpos = strpos("`prcen'", ",")
		if `cpos' == 0 {
			if "`prcen'" != "0" {
				di as error "only two values/variables separated by comma (,) or 0 are suitable arguments"
				exit 198
			}
			else {
				// probability of 0
				tempvar zg selsig
				_predict double `zg' if `touse', equation(#1)
				if "`e(selhet)'" != "" {
					_predict double `selsig' if `touse', equation(#3)
					quiet replace `selsig' = exp(`selsig') if `touse'
				}
				else quiet generate double `selsig' = 1 if `touse'
				quiet replace `zg' = normal(- `zg' / `selsig') if `touse'
				quiet generate `vtyp' `varn' = `zg' if `touse'
				label var `varn' "Prob. observed variable: P(`e(depvar)'=`prcen'|z)"
				exit
			}
		}
		
		local left = substr("`prcen'",1,`cpos' - 1)
		local right = substr("`prcen'", `cpos' + 1, .)
		
		// Now check that right doesn't have another comma.
		local cpos = strpos("`right'" , ",")
		if `cpos' > 0 {
			di as error "Too many arguments"
			exit 198
		}
		
		// Check both are not missing
		if "`left'" == "." & "`right'" == "." {
			di as error "Both arguments cannot be ."
			exit 198
		}
		
		nehurdle_parse_probopts `left' if `touse'
		if `s(nh_res)' > 0 {
			di as error "The first argument needs to be numeric or ."
			exit 198
		}
		nehurdle_parse_probopts `right' if `touse'
		if `s(nh_res)' > 0 {
			di as error "The second argument needs to be numeric or ."
			exit 198
		}
		
		// Censored variable, need all predictions.
		tempvar mu zg selsig sig rho
		_predict double `zg' if `touse', equation(#1)
		_predict double `mu' if `touse', equation(#2)
		if "`e(selhet)'" != "" {
			_predict double `selsig' if `touse', equation(#3)
			quiet replace `selsig' = exp(`selsig') if `touse'
			_predict double `sig' if `touse', equation(#4)
			_predict double `rho' if `touse', equation(#5)
		}
		else {
			quiet generate double `selsig' = 1 if `touse'
			_predict double `sig' if `touse', equation(#3)
			_predict double `rho' if `touse', equation(#4)
		}
		quiet replace `sig' = exp(`sig') if `touse'
		quiet replace `rho' = tanh(`rho') if `touse'
		
		// We don't need zg by itself. Always standardized so I change it here
		quiet replace `zg' = `zg' / `selsig' if `touse'
		
		if "`left'" == "." {
			// Less than.
			// We need right to be positive, and not missing.
			tempvar check
			quiet generate byte `check' = (`right'<=0) if `touse'
			quiet summarize `check' if `touse', mean
			if r(sum) > 0 {
				di as error "The second argument must be positive"
				exit 198
			}
			quiet replace `check' = missing(`right') if `touse'
			quiet summarize `check' if `touse', mean
			if r(sum) > 0 {
				di as error "The second argument cannot have missing values"
				exit 198
			}
			drop `check'
			
			// Now if exponential, need to transform and different formula
			if "`e(est_model)'" == "exponential" {
				capture confirm var `right'
				if !_rc {
					tempvar lnright
					quiet generate double `lnright' = ln(`right') if `touse'
				}
				else local lnright = ln(`right')
				
				quiet replace `mu' = normal(-`zg') + 							///
					binormal((`lnright' - `mu') / `sig', `zg', `rho')			///
					if `touse'
			}
			else {
				quiet replace `mu' = normal(-`zg') + 							///
					binormal((`right' - `mu') / `sig', `zg', `rho') -			///
					binormal(- `mu' / `sig', `zg', `rho') if `touse'
			}
			quiet generate `vtyp' `varn' = `mu' if `touse'
			label var `varn' "Prob. observed variable: P(`e(depvar)'<`right'|x,z)"
			exit
		}
		
		if "`right'" == "." {
			// Greater than
			// Left cannot be negative or missing. Will need to transform to logs
			// and catch zeroes if lognormal.
			tempvar check
			quiet generate byte `check' = (`left'<0) if `touse'
			quiet summarize `check' if `touse', mean
			if r(sum) > 0 {
				di as error "The first argument cannot be negative"
				exit 198
			}
			quiet replace `check' = missing(`left') if `touse'
			quiet summarize `check' if `touse', mean
			if r(sum) > 0 {
				di as error "The first argument cannot have missing values"
				exit 198
			}
			drop `check'
			
			if "`e(est_model)'" == "exponential" {
				capture confirm var `left'
				if !_rc {
					tempvar lnleft
					quiet generate double `lnleft' = `left' if `touse'
					quiet replace `lnleft' = 1e-20 if `touse' & `lnleft' == 0
					quiet replace `lnleft' = ln(`left') if `touse'
				}
				else if "`left'" == "0" local lnleft = ln(1e-20)
				else local lnleft = ln(`left')
				
				quiet replace `mu' = normal(`zg') -							///
					binormal((`lnleft' - `mu') / `sig', `zg', `rho') if `touse'
			}
			else {
				quiet replace `mu' = normal(`zg') - binormal((`left' - `mu')	///
					/ `sig', `zg', `rho') + binormal(- `mu' / `sig', `zg',		///
					`rho') if `touse'
			}
			quiet generate `vtyp' `varn' = `mu' if `touse'
			label var `varn' "Prob. observed variable: P(`e(depvar)'>`left'|x,z)"
			exit
		}
		
		// Probability of range. Left cannot be negative, right must be greater
		// than left, neither can be missing, and transform both to logs and capture
		// zeroes in left for lognormal
		
		tempvar check
		quiet generate byte `check' = (`left'<0) if `touse'
		quiet summarize `check' if `touse', mean
		if r(sum) > 0 {
			di as error "The first argument cannot be negative"
			exit 198
		}
		quiet replace `check' = (`right'<=`left') if `touse'
		quiet summarize `check' if `touse', mean
		if r(sum) > 0 {
			di as error "The second argument must be greater than the first"
			exit 198
		}
		quiet replace `check' = missing(`left',`right') if `touse'
		quiet summarize `check' if `touse', mean
		if r(sum) > 0 {
			di as error "Neither argument can have missing values"
			exit 198
		}
		drop `check'
		
		if "`e(est_model)'" == "exponential" {
			capture confirm var `left'
			if !_rc {
				tempvar lnleft
				quiet generate double `lnleft' = `left' if `touse'
				quiet replace `lnleft' = 1e-20 if `touse' & `lnleft' == 0
				quiet replace `lnleft' = ln(`lnleft') if `touse'
			}
			else if "`left'" == "0" local lnleft = ln(1e-20)
			else local lnleft = ln(`left')
			
			capture confirm var `right'
			if !_rc {
				tempvar lnright
				quiet generate double `lnright' = ln(`right') if `touse'
			}
			else local lnright = ln(`right')
		}
		else {
			local lnleft = `left'
			local lnright = `right'
		}
		
		quiet replace `mu' = binormal((`lnright' - `mu') / `sig', `zg', `rho')	///
			- binormal((`lnleft' - `mu') / `sig', `zg', `rho') if `touse'
		quiet generate `vtyp' `varn' = `mu' if `touse'
		label var `varn' "Prob. observed variable: P(`left'<`e(depvar)'<`right'|x,z)"
		exit
	}
	
	if "`ytrun'" != "" {
		tempvar mu zg selsig sig rho
		_predict double `zg' if `touse', equation(#1)
		_predict double `mu' if `touse', equation(#2)
		if "`e(selhet)'" != "" {
			_predict double `selsig' if `touse', equation(#3)
			quiet replace `selsig' = exp(`selsig') if `touse'
			_predict double `sig' if `touse', equation(#4)
			_predict double `rho' if `touse', equation(#5)
		}
		else {
			quiet generate double `selsig' = 1 if `touse'
			_predict double `sig' if `touse', equation(#3)
			_predict double `rho' if `touse', equation(#4)
		}
		quiet replace `sig' = exp(`sig') if `touse'
		quiet replace `rho' = tanh(`rho') if `touse'
		if "`e(est_model)'" == "linear"											///
			quiet replace `mu' = `mu' + `sig' * `rho' *	 normalden(`zg' /		///
				`selsig') / normal(`zg' / `selsig') if `touse'
		else																	///
			quiet replace `mu' = exp(`mu' + `sig'^2 / 2) * normal(`zg' /		///
				`selsig' + `rho' * `sig') / normal(`zg' / `selsig') if `touse'
		quiet generate `vtyp' `varn' = `mu' if `touse'
		label var `varn' "Truncated variable mean: E(`e(depvar)'*|x,z,`e(depvar)'*>0)"
		exit
	}
	
	if "`restrun'" != "" {
		tempvar mu zg selsig sig rho
		_predict double `zg' if `touse', equation(#1)
		_predict double `mu' if `touse', equation(#2)
		if "`e(selhet)'" != "" {
			_predict double `selsig' if `touse', equation(#3)
			quiet replace `selsig' = exp(`selsig') if `touse'
			_predict double `sig' if `touse', equation(#4)
			_predict double `rho' if `touse', equation(#5)
		}
		else {
			quiet generate double `selsig' = 1 if `touse'
			_predict double `sig' if `touse', equation(#3)
			_predict double `rho' if `touse', equation(#4)
		}
		quiet replace `sig' = exp(`sig') if `touse'
		quiet replace `rho' = tanh(`rho') if `touse'
		if "`e(est_model)'" == "linear"											///
			quiet replace `mu' = `mu' + `sig' * `rho' *	 normalden(`zg' /		///
				`selsig') / normal(`zg' / `selsig') if `touse'
		else																	///
			quiet replace `mu' = exp(`mu' + `sig'^2 / 2) * normal(`zg' /		///
				`selsig' + `rho' * `sig') / normal(`zg' / `selsig') if `touse'
		quiet replace `mu' = `e(depvar)' - `mu' if `touse'
		quiet generate `vtyp' `varn' = `mu' if `touse'
		label var `varn' "Truncated variable resisdual: `e(depvar)' - E(`e(depvar)'*|x,z,`e(depvar)'>0)"
		exit
	}
	
	if "`vtrun'" != "" {
		tempvar mu zg selsig sig rho
		_predict double `zg' if `touse', equation(#1)
		_predict double `mu' if `touse', equation(#2)
		if "`e(selhet)'" != "" {
			_predict double `selsig' if `touse', equation(#3)
			quiet replace `selsig' = exp(`selsig') if `touse'
			_predict double `sig' if `touse', equation(#4)
			_predict double `rho' if `touse', equation(#5)
		}
		else {
			quiet generate double `selsig' = 1 if `touse'
			_predict double `sig' if `touse', equation(#3)
			_predict double `rho' if `touse', equation(#4)
		}
		quiet replace `sig' = exp(`sig') if `touse'
		quiet replace `rho' = tanh(`rho') if `touse'
		
		quiet replace `zg' = `zg' / `selsig' if `touse'
		
		if "`e(est_model)'" == "linear" {
			quiet replace `mu' = `sig'^2 * (1 - `rho'^2 *						///
				normalden(`zg') / normal(`zg') * (`zg' +						///
				normalden(`zg') / normal(`zg'))) if `touse'
		}
		else {
			quiet replace `mu' = exp(2 * `mu' + `sig'^2) * ( exp(`sig'^2) *		///
				normal(`zg' + 2 * `rho' * `sig') * normal(`zg') - normal(`zg' + ///
				`rho' * `sig')^2) / (normal(`zg')^2) if `touse'
		}
		quiet generate `vtyp' `varn' = `mu' if `touse'
		label var `varn' "Truncated variable variance: V(`e(depvar)'*|x,z,`e(depvar)'*>0)"
		exit
	}
	
	if "`sigtrun'" != "" {
		tempvar mu zg selsig sig rho
		_predict double `zg' if `touse', equation(#1)
		_predict double `mu' if `touse', equation(#2)
		if "`e(selhet)'" != "" {
			_predict double `selsig' if `touse', equation(#3)
			quiet replace `selsig' = exp(`selsig') if `touse'
			_predict double `sig' if `touse', equation(#4)
			_predict double `rho' if `touse', equation(#5)
		}
		else {
			quiet generate double `selsig' = 1 if `touse'
			_predict double `sig' if `touse', equation(#3)
			_predict double `rho' if `touse', equation(#4)
		}
		quiet replace `sig' = exp(`sig') if `touse'
		quiet replace `rho' = tanh(`rho') if `touse'
		
		quiet replace `zg' = `zg' / `selsig' if `touse'
		
		if "`e(est_model)'" == "linear" {
			quiet replace `mu' = `sig'^2 * (1 - `rho'^2 *						///
				normalden(`zg') / normal(`zg') * (`zg' +						///
				normalden(`zg') / normal(`zg'))) if `touse'
		}
		else {
			quiet replace `mu' = exp(2 * `mu' + `sig'^2) * ( exp(`sig'^2) *		///
				normal(`zg' + 2 * `rho' * `sig') * normal(`zg') - normal(`zg' + ///
				`rho' * `sig')^2) / (normal(`zg')^2) if `touse'
		}
		quiet replace `mu' = sqrt(`mu') if `touse'
		quiet generate `vtyp' `varn' = `mu' if `touse'
		label var `varn' "Truncated variable std. dev.: sd(`e(depvar)'*|x,z,`e(depvar)'*>0)"
		exit
	}
	
	if "`prtrun'" != "" {
		// Truncated variable.
		// Only accept ranges, like in prstar
		local cpos = strpos("`prtrun'", ",")
		if `cpos' == 0 {
			di as error "Need two arguments (value or variables) separated by a comma"
			exit 198
		}
		
		local left = substr("`prtrun'",1,`cpos' - 1)
		local right = substr("`prtrun'", `cpos' + 1, .)
		
		// Now check that right doesn't have another comma.
		local cpos = strpos("`right'" , ",")
		if `cpos' > 0 {
			di as error "Too many arguments"
			exit 198
		}
		
		// Check if they are values, or variables or missing
		nehurdle_parse_probopts `left' if `touse'
		if `s(nh_res)' == 1 {
			display as error "The first argument needs to be numeric or ."
			exit 198
		}
		
		nehurdle_parse_probopts `right' if `touse'
		if `s(nh_res)' == 1 {
			display as error "The second argument needs to be numeric or ."
			exit 198
		}
		
		if "`left'" == "." & "`right'" == "." {
			di as error "Both arguments cannot be ."
			exit 198
		}
		
		// So in the Type II Tobit, the truncation is done by the variable
		// that determines participation. So even in the lognormal model
		// there is truncation. Since it involves both processes, we need to
		// predict all equations.
		tempvar mu zg selsig sig rho
		_predict double `zg' if `touse', equation(#1)
		_predict double `mu' if `touse', equation(#2)
		if "`e(selhet)'" != "" {
			_predict double `selsig' if `touse', equation(#3)
			quiet replace `selsig' = exp(`selsig') if `touse'
			_predict double `sig' if `touse', equation(#4)
			_predict double `rho' if `touse', equation(#5)
		}
		else {
			quiet generate double `selsig' = 1 if `touse'
			_predict double `sig' if `touse', equation(#3)
			_predict double `rho' if `touse', equation(#4)
		}
		quiet replace `sig' = exp(`sig') if `touse'
		quiet replace `rho' = tanh(`rho') if `touse'
		
		// We don't need zg by itself. Always standardized so I change it here
		quiet replace `zg' = `zg' / `selsig' if `touse'
		
		if "`left'" == "." {
			// Less than
			// Now, this is the truncated variable. So the right has to be
			// greater than zero, even in the normal model, because in theory
			// once the participation variable is positive, the value variable
			// ought to be, and we are truncating to when the participation
			// variable is positive. 
			tempvar check
			quiet generate byte `check' = (`right'<=0) if `touse'
			quiet summarize `check' if `touse', mean
			if r(sum) > 0 {
				di as error "The second argument must be positive"
				exit 198
			}
			quiet replace `check' = missing(`right') if `touse'
			quiet summarize `check' if `touse', mean
			if r(sum) > 0 {
				di as error "The second argument cannot have missing values"
				exit 198
			}
			drop `check'
			
			if "`e(est_model)'" == "exponential" {
				capture confirm var `right'
				if !_rc {
					tempvar lnright
					quiet generate double `lnright' = ln(`right') if `touse'
				}
				else local lnright = ln(`right')
				
				quiet replace `mu' = binormal((`lnright' - `mu') / `sig', `zg',	///
					`rho') / normal(`zg') if `touse'
			}
			else {
				quiet replace `mu' = (binormal((`right' - `mu') / `sig', `zg',	///
					`rho') - binormal(- `mu' / `sig', `zg', `rho')) /			///
					normal(`zg') if `touse'
			}
			quiet generate `vtyp' `varn' = `mu' if `touse'
			label var `varn' "Prob. truncated variable: P(`e(depvar)'*<`right'|x,z,d=1)"
			exit
		}
		
		if "`right'" == "." {
			// Greater than
			// Truncated, so left has to be greater than zero.
			tempvar check
			quiet generate byte `check' = (`left'<=0) if `touse'
			quiet summarize `check' if `touse', mean
			if r(sum) > 0 {
				di as error "The first argument must be positive"
				exit 198
			}
			quiet replace `check' = missing(`left') if `touse'
			quiet summarize `check' if `touse', mean
			if r(sum) > 0 {
				di as error "The second argument cannot have missing values"
				exit 198
			}
			drop `check'
			
			if "`e(est_model)'" == "exponential" {
				capture confirm var `left'
				if !_rc{
					tempvar lnleft
					quiet generate double `lnleft' = ln(`left') if `touse'
				}
				else local lnleft = ln(`left')
				
				quiet replace `mu' = (normal(`zg') -  binormal((`lnleft' -		///
					`mu') / `sig', `zg', `rho')) / normal(`zg') if `touse'
			}
			else {
				quiet replace `mu' = (normal(`zg') - binormal((`left' - `mu')	///
					/ `sig', `zg', `rho') + binormal(- `mu' / `sig', `zg',		///
					`rho')) / normal(`zg') if `touse'
			}
			quiet generate `vtyp' `varn' = `mu' if `touse'
			label var `varn' "Prob. truncated variable: P(`e(depvar)'*>`left'|x,z,d=1)"
			exit
		}
		
		// range
		// both have to be positive, but only need to check on left, because
		// right has to be larger than left.
		tempvar check
		quiet generate byte `check' = (`left'<=0) if `touse'
		quiet summarize `check' if `touse', mean
		if r(sum) > 0 {
			di as error "The first argument must be positive"
			exit 198
		}
		quiet replace `check' = (`right'<=`left') if `touse'
		quiet summarize `check' if `touse', mean
		if r(sum) > 0 {
			di as error "The second argument must be greater than the first"
			exit 198
		}
		quiet replace `check' = missing(`left',`right') if `touse'
		quiet summarize `check' if `touse', mean
		if r(sum) > 0 {
			di as error "Neither argument can have missing values"
			exit 198
		}
		drop `check'
		
		// This is the one that has the same formula for both models, just
		// have to transform to logs in the exponential.
		if "`e(est_model)'" == "exponential" {
			capture confirm var `left'
			if !_rc {
				tempvar lnleft
				quiet generate double `lnleft' = ln(`left') if `touse'
			}
			else local lnleft = ln(`left')
			
			capture confirm var `right'
			if !_rc {
				tempvar lnright
				quiet generate double `lnright' = ln(`right') if `touse'
			}
			else local lnright = ln(`right')
		}
		else {
			local lnright = `right'
			local lnleft = `left'
		}
		
		quiet replace `mu' = (binormal((`lnright' - `mu') / `sig', `zg', `rho')	///
			- binormal((`lnleft' - `mu') / `sig', `zg', `rho')) / normal(`zg')	///
			if `touse'
		quiet generate `vtyp' `varn' = `mu' if `touse'
		label var `varn' "Prob. truncated variable: P(`left'<`e(depvar)'*<`right'|x,z,d=1)"
		exit
	}
	
	if "`ystar'" != "" {
		tempvar mu
		_predict double `mu' if `touse', equation(#2)
		
		if "`e(est_model)'" == "exponential" {
			tempvar sig
			
			if "`e(selhet)'" != "" 												///
				_predict double `sig' if `touse', equation(#4)
			else																///
				_predict double `sig' if `touse', equation(#3)
				
			quiet replace `sig' = exp(`sig') if `touse'
			quiet replace `mu' = exp(`mu' + `sig'^2 / 2) if `touse'
		}
		quiet generate `vtyp' `varn' = `mu' if `touse'
		label var `varn' "Latent variable mean: E(`e(depvar)'*|x)"
		exit
	}
	
	if "`resstar'" != "" {
		tempvar mu
		_predict double `mu' if `touse', equation(#2)
		
		if "`e(est_model)'" == "exponential" {
			tempvar sig
			
			if "`e(selhet)'" != "" 												///
				_predict double `sig' if `touse', equation(#4)
			else																///
				_predict double `sig' if `touse', equation(#3)
				
			quiet replace `sig' = exp(`sig') if `touse'
			quiet replace `mu' = exp(`mu' + `sig'^2 / 2) if `touse'
		}
		quiet replace `mu' = `e(depvar)' - `mu' if `touse'
		quiet generate `vtyp' `varn' = `mu' if `touse'
		label var `varn' "Latent variable residual: `e(depvar)' - E(`e(depvar)'*|x)"
		exit
	}
	
	if "`vstar'" != "" {
		tempvar sig
		if "`e(selhet)'" != ""													///
			_predict double `sig' if `touse', equation(#4)
		else																	///
			_predict double `sig' if `touse', equation(#3)
		quiet replace `sig' = exp(`sig') if `touse'
		
		if "`e(est_model)'" == "exponential" {
			tempvar mu
			_predict double `mu' if `touse', equation(#2)
			
			quiet replace `sig' = exp(2 * `mu' + `sig'^2) * (exp(`sig'^2) - 1)	///
				if `touse'
		}
		else																	///
			quiet replace `sig' = `sig'^2 if `touse'
		quiet generate `vtyp' `varn' = `sig' if `touse'
		label var `varn' "Latent variable variance: V(`e(depvar)'*|x)"
		exit
	}
	
	if "`sigstar'" != "" {
		tempvar sig
		if "`e(selhet)'" != ""													///
			_predict double `sig' if `touse', equation(#4)
		else																	///
			_predict double `sig' if `touse', equation(#3)
		quiet replace `sig' = exp(`sig') if `touse'
		
		if "`e(est_model)'" == "exponential" {
			tempvar mu
			_predict double `mu' if `touse', equation(#2)
			
			quiet replace `sig' = sqrt(exp(2 * `mu' + `sig'^2) * (exp(`sig'^2)	///
				- 1)) if `touse'
		}
		quiet generate `vtyp' `varn' = `sig' if `touse'
		label var `varn' "Variance of latent variable: V(`e(depvar)'*|x)"
		exit
	}
	
	if "`prstar'" != "" {
		// This is ystar. So a simple normal distribution. The only complication
		// are zeroes if lognormal. Since it's not the observed variable, we
		// only accept ranges, so two arguments.
		
		local cpos = strpos("`prstar'", ",")
		if `cpos' == 0 {
			di as error "Need two arguments (values or variables) separated by a comma"
			exit 198
		}
		
		local left = substr("`prstar'",1,`cpos' - 1)
		local right = substr("`prstar'", `cpos' + 1, .)
		
		// Now check that right doesn't have another comma.
		local cpos = strpos("`right'" , ",")
		if `cpos' > 0 {
			di as error "Too many arguments"
			exit 198
		}
		
		// Check if they are values, or variables or missing
		nehurdle_parse_probopts `left' if `touse'
		if `s(nh_res)' == 1 {
			display as error "The first argument needs to be numeric or ."
			exit 198
		}
		
		nehurdle_parse_probopts `right' if `touse'
		if `s(nh_res)' == 1 {
			display as error "The second argument needs to be numeric or ."
			exit 198
		}
		
		// Check both aren't .
		if "`left'" == "." & "`right'" == "." {
			display as error "Both arguments cannot be ."
			exit 198
		}
		
		// Here we do the predictions from the equations. We only need the value
		// equation, and the std. dev. of the value.
		tempvar sig mu
		_predict double `mu' if `touse', equation(#2)
		if "`e(selhet)'" != "" 													///
			_predict double `sig' if `touse', equation(#4)
		else																	///
			_predict double `sig' if `touse', equation(#3)
		quiet replace `sig' = exp(`sig') if `touse'
		
		// Alright here we go.
		if "`left'" == "." {
			// Less than
			if "`e(est_model)'" == "exponential" {
				tempvar check
				quiet generate byte `check' = (`right'<=0) if `touse'
				quiet summarize `check' if `touse', mean
				if r(sum) > 0 {
					di as error "The second argument needs to be positive"
					exit 198
				}
				drop `check'
				
				capture confirm var `right'
				if !_rc {
					tempvar lnright
					quiet generate double `lnright' = ln(`right') if `touse'
				}
				else local lnright = ln(`right')
			}
			else local lnright = `right'
			
			
			quiet replace `mu' = normal((`lnright' - `mu') / `sig') if `touse'
			quiet generate `vtyp' `varn' = `mu' if `touse'
			label var `varn' "Prob. latent variable: E(`e(depvar)'*<`right'|x)"
			exit
		}
		
		if "`right'" == "." {
			// Greater than.
			if "`e(est_model)'" == "exponential" {
				tempvar check
				quiet generate byte `check' = (`left'<0) if `touse'
				quiet summarize `check' if `touse', mean
				if r(sum) > 0 {
					di as error "First argument cannot be negative"
					exit 198
				}
				drop `check'
				
				capture confirm var `left'
				if !_rc {
					tempvar lnleft
					quiet generate double `lnleft' = `left' if `touse'
					quiet replace `lnleft' = 1e-20 if `touse' & `lnleft' == 0
					quiet replace `lnleft' = ln(`left') if `touse'
				}
				else {
					if "`left'" == "0" local lnleft = ln(1e-20)
					else local lnleft = ln(`left')
				}
			}
			else local lnleft = `left'
			quiet replace `mu' = normal((`mu' - `lnleft') / `sig') if `touse'
			quiet generate `vtyp' `varn' = `mu' if `touse'
			label var `varn' "Prob. latent variable: P(`e(depvar)'*>`left'|x)"
			exit
		}
		
		// Probability of a range.
		tempvar check
		quiet generate byte `check' = (`right'<=`left') if `touse'
		quiet summarize `check' if `touse', mean
		if r(sum) > 0 {
			di as error "The second argument must be greater than the first"
			exit 198
		}
		quiet replace `check' = missing(`left',`right') if `touse'
		quiet summarize `check' if `touse', mean
		if r(sum) > 0 {
			di as error "Neither argument can have missing values"
			exit 198
		}
		if "`e(est_model)'" == "exponential" {
			quiet replace `check' = (`left'<0) if `touse'
			quiet summarize `check' if `touse', mean
			if r(sum) > 0 {
				di as error "The first argument cannot be negative"
				exit 198
			}
			
			capture confirm var `left'
			if !_rc {
				tempvar lnleft
				quiet generate double `lnleft' = `left' if `touse'
				quiet replace `lnleft' = 1e-20 if `touse' & `lnleft' == 0
				quiet replace `lnleft' = ln(`lnleft') if `touse'
			}
			else {
				if "`left'" == "0" local lnleft = ln(1e-20)
				else local lnleft = ln(`left')
			}
			
			capture confirm var `right'
			if !_rc {
				tempvar lnright
				quiet generate double `lnright' = ln(`right') if `touse'
			}
			else local lnright = ln(`right')
		}
		else {
			local lnleft = `left'
			local lnright = `right'
		}
		
		drop `check'
		
		quiet replace `mu' = normal((`lnright' - `mu') / `sig') -				///
			normal((`lnleft' - `mu') / `sig') if `touse'
		quiet generate `vtyp' `varn' = `mu' if `touse'
		label var `varn' "Prob. latent variable: P(`left'<`e(depvar)'*<`right'|x)"
		exit
	}
	
	if "`xbval'" != "" {
		_predict `vtyp' `varn' if `touse', equation(#2)
		if "`e(est_model)'" == "linear"											///
			label var `varn' "Linear prediction of uncensored mean E(`e(depvar)'*|x)"
		else																	///
			label var `varn' "Linear prediction of uncensored mean E(ln(`e(depvar)')*|x)"
		exit
	}
	
	if "`resval'" != "" {
		tempvar xb
		_predict double `xb' if `touse', equation(#2)
		if "`e(est_model)'" == "linear"	{
			quiet replace `xb' = `e(depvar)' - `xb' if `touse'
			quiet generate `vtyp' `varn' = `xb' if `touse'
			label var `varn' "Residual of uncensored mean E(`e(depvar)'*|x)"
		}
		else {
			quiet replace `xb' = ln(`e(depvar)') - `xb' if `touse'
			quiet generate `vtyp' `varn' = `xb' if `touse'
			label var `varn' "Residual of uncensored mean E(ln(`e(depvar)')*|x)"
		}
		exit
	}
	
	if "`psel'" != "" {
		tempvar zg sig
		_predict double `zg' if `touse', equation(#1)
		if "`e(selhet)'" != "" {
			_predict double `sig' if `touse', equation(#3)
			quiet replace `sig' = exp(`sig') if `touse'
		}
		else quiet generate double `sig' = 1 if `touse'
		quiet replace `zg' = normal(`zg' / `sig') if `touse'
		quiet generate `vtyp' `varn' = `zg' if `touse'
		label var `varn' "Prob. selection: Pr(`e(depvar)'> 0|z)"
		exit
	}
	
	if "`ressel'" != "" {
		tempvar zg sig dy
		quiet generate byte `dy' = `e(depvar)' > 0 if `touse'
		_predict double `zg' if `touse', equation(#1)
		if "`e(selhet)'" != "" {
			_predict double `sig' if `touse', equation(#3)
			quiet replace `sig' = exp(`sig') if `touse'
		}
		else quiet generate double `sig' = 1 if `touse'
		quiet replace `zg' = `dy' - normal(`zg' / `sig') if `touse'
		quiet generate `vtyp' `varn' = `zg' if `touse'
		label var `varn' "Residual of prob. participation: I(`e(depvar)'>0) - Pr(`e(depvar)'>0|z)"
		exit
	}
	
	if "`xbsel'" != "" {
		_predict `vtyp' `varn' if `touse', equation(#1)
		label var `varn' "Linear prediction of selection"
		exit
	}
	
	if "`xbsig'" != "" {
		if "`e(selhet)'" != "" local eqn = 4
		else local eqn = 3
		_predict `vtyp' `varn' if `touse', equation(#`eqn')
		label var `varn' "Linear prediction of ln(SE)"
		exit
	}
	
	if "`sigma'" != "" {
		tempvar sig
		if "`e(selhet)'" != "" local eqn = 4
		else local eqn = 3
		_predict double `sig' if `touse', equation(#`eqn')
		quiet replace `sig' = exp(`sig') if `touse'
		quiet generate `vtyp' `varn' = `sig' if `touse'
		label var `varn' "Std. dev. of the value equation: exp(lnsigma)"
		exit
	}
	
	if "`selsigma'" != "" {
		if "`e(selhet)'" == "" {
			di as error "{bf:selsigma} not valid"
			exit 198
		}
		tempvar sig
		_predict double `sig' if `touse', equation(#3)
		quiet replace `sig' = exp(`sig') if `touse'
		quiet generate `vtyp' `varn' = `sig' if `touse'
		label var `varn' "Std. dev. of the selection equation: exp(sellnsigma)"
		exit
	}
	
	if "`xbselsig'" != "" {
		if "`e(selhet)'" == ""{
			di as error "{bf:selsigxb} not valid"
			exit 198
		}
		_predict `vtyp' `varn' if `touse', equation(#3)
		label var `varn' "Linear prediction of selection ln(SE)"
		exit
	}
	
	if "`lambda'" != "" {
		tempvar sig rho
		if "`e(selhet)'" != "" {
			tempvar ss
			_predict double `ss' if `touse', equation(#3)
			_predict double `sig' if `touse', equation(#4)
			_predict double `rho' if `touse', equation(#5)
			quiet replace `sig' = exp(`ss') * exp(`sig') * tanh(`rho') if `touse'
		}
		else {
			_predict double `sig' if `touse', equation(#3)
			_predict double `rho' if `touse', equation(#4)
			quiet replace `sig' = exp(`sig') * tanh(`rho') if `touse'
		}
		quiet generate `vtyp' `varn' = `sig' if `touse'
		label var `varn' "Prediction of coefficient on inverse mills ratio"
		exit
	}
	
	// ycen is the default
	if "`ycen'" == "" noi di as txt "(option ycen assumed)"
	tempvar mu zg selsig sig rho
	_predict double `zg' if `touse', equation(#1)
	_predict double `mu' if `touse', equation(#2)
	if "`e(selhet)'" != "" {
		_predict double `selsig' if `touse', equation(#3)
		quiet replace `selsig' = exp(`selsig') if `touse'
		_predict double `sig' if `touse', equation(#4)
		_predict double `rho' if `touse', equation(#5)
	}
	else {
		quiet generate double `selsig' = 1 if `touse'
		_predict double `sig' if `touse', equation(#3)
		_predict double `rho' if `touse', equation(#4)
	}
	quiet replace `sig' = exp(`sig') if `touse'
	quiet replace `rho' = tanh(`rho') if `touse'
	if "`e(est_model)'" == "linear" {
		quiet replace `mu' = `mu' + `sig' * `rho' * normalden(`zg' / `selsig')	///
			/ normal(`zg' / `selsig') if `touse'
	}
	else {
		quiet replace `mu' = exp(`mu' + `sig'^2 / 2) * normal(`zg' / `selsig' + ///
			`rho' * `sig') / normal(`zg' / `selsig') if `touse'
	}
	quiet replace `mu' = normal(`zg' / `selsig') * `mu' if `touse'
	quiet generate `vtyp' `varn' = `mu' if `touse'
	label var `varn' "Observed variable mean: E(`e(depvar)'|x,z)"
end


capture program drop nehurdle_truncp_p
program define nehurdle_truncp_p, eclass
	syntax anything(id="newvarname") [if] [in]									///
	[, {																		///
		YCen			|														///
		RESCen			|														///
		VCen			|														///
		SIGCen			|														///
		PRCen(string)	|														///
		YTrun			|														///
		RESTrun			|														///
		VTrun			|														///
		SIGTrun			|														///
		PRTrun(string)	|														///
		YStar			|														///
		RESStar			|														///
		VStar			|														///
		SIGStar			|														///
		PRStar(string)	|														///
		XB				|														///
		XBVal			|														///
		XBSel			|														///
		XBSELSig		|														///
		SELSIGma		|														///
		PSel			|														///
		RESSEL			|														///
		SCores																	///
	} * ]
	
	if "`scores'" != "" {
		local bvar "`e(depvar)'"
		tempvar dy y1
		quiet generate byte `dy' = `bvar' > 0
		quiet generate double `y1' = `bvar'
		ereturn local depvar "`dy' `y1'"
		
		marksample touse
		marksample touse2
		local xvars : colna e(b)
		local cons _cons _cons _cons
		local xvars : list xvars - cons
		
		markout `touse2' `xvars'
		quiet replace `touse' = 0 if `dy' & !`touse2'
		ml score `anything' if `touse', `scores' missing `options'
		ereturn local depvar "`bvar'"
		exit
	}
	
	local myopts "YCen RESCen VCen SIGCen PRCen(string) YTrun RESTrun VTrun"
	local myopts "`myopts' SIGTrun PRTrun(string) YStar RESStar VStar SIGStar"
	local myopts "`myopts' PRStar(string) XB XBVal PSel RESSEL XBSel SELSIGma"
	local myopts "`myopts' XBSELSig"
	_pred_se "`myopts'" `0'
	if `s(done)' exit
	local vtyp  `s(typ)'
	local varn `s(varn)'
	local 0 `"`s(rest)'"'
	
	marksample touse
	
	// Have to capture xb to notify it is not vaid.
	if "`xb'" != "" {
		di as error "option {bf:xb} not valid"
		di as error "Try one of the following:"
		di as error _col(6) "1. {bf:xbval} for fitted values of the value equation."
		di as error _col(6) "2. {bf:xbsel} for fitted values of the selection equation."
		if "`e(selhet)'" != "" 													///
			di as error _col(6) "3. {bf:xbselsig} for fitted values of the selection ln sigma."
		exit 198
	}
	
	// Censored (observed) variable.
	// ycen is the default so I do that at the end.
	if "`rescen'" != "" {
		// First we predict ycen.
		tempvar lam psel selsig
		_predict double `lam' if `touse', equation(#2)
		quiet replace `lam' = exp(`lam') if `touse'
		_predict double `psel' if `touse', equation(#1)
		if "`e(selhet)'" != "" {
			_predict double `selsig' if `touse', equation(#3)
			quiet replace `selsig' = exp(`selsig') if `touse'
		}
		else quiet generate double `selsig' = 1 if `touse'
		quiet replace `psel' = normal(`psel' / `selsig') if `touse'
		quiet replace `lam' = `psel' * `lam' / (1 - exp(- `lam')) if `touse'
		// And now modify it to make it the residuals
		quiet replace `lam' = `e(depvar)' - `lam' if `touse'
		quiet generate `vtyp' `varn' = `lam' if `touse'
		label var `varn' "Observed variable residuals: `e(depvar)' - E(`e(depvar)'|x,z)"
		exit
	}
	
	if "`vcen'" != "" {
		tempvar lam psel selsig
		// Poisson mean
		_predict double `lam' if `touse', equation(#2)
		quiet replace `lam' = exp(`lam') if `touse'
		// Prob yes.
		_predict double `psel' if `touse', equation(#1)
		if "`e(selhet)'" != "" {
			_predict double `selsig' if `touse', equation(#3)
			quiet replace `selsig' = exp(`selsig') if `touse'
		}
		else quiet generate double `selsig' = 1 if `touse'
		quiet replace `psel' = normal(`psel' / `selsig') if `touse'
		
		// Alright, now we form the variance.
		quiet replace `lam' = `psel' * (`lam' + `lam'^2) / (1 - exp(- `lam')) - ///
			(`psel' * `lam' / (1 - exp(- `lam')))^2 if `touse'
		quiet generate `vtyp' `varn' = `lam' if `touse'
		label var `varn' "Observed variable variance: V(`e(depvar)'|x,z)"
		exit
	}
	
	if "`sigcen'" != "" {
		tempvar lam psel selsig
		// Poisson mean
		_predict double `lam' if `touse', equation(#2)
		quiet replace `lam' = exp(`lam') if `touse'
		// Prob yes.
		_predict double `psel' if `touse', equation(#1)
		if "`e(selhet)'" != "" {
			_predict double `selsig' if `touse', equation(#3)
			quiet replace `selsig' = exp(`selsig') if `touse'
		}
		else quiet generate double `selsig' = 1 if `touse'
		quiet replace `psel' = normal(`psel' / `selsig') if `touse'
		
		// Alright, now we form the variance.
		quiet replace `lam' = `psel' * (`lam' + `lam'^2) / (1 - exp(- `lam')) - ///
			(`psel' * `lam' / (1 - exp(- `lam')))^2 if `touse'
		quiet replace `lam' = sqrt(`lam') if `touse'
		quiet generate `vtyp' `varn' = `lam' if `touse'
		label var `varn' "Observed variable std. dev.: sd(`e(depvar)'|x,z)"
		exit
	}
	
	// Probability of the censored variable
	if "`prcen'" != "" {
		// First thing we check whether the position of a comma in the string
		local cpos = strpos("`prcen'", ",")
		if `cpos' > 0 {
			// Probability of the censored variable falling between two values.
			local left = substr("`prcen'",1,`cpos' - 1)
			local right = substr("`prcen'", `cpos' + 1, .)
			
			// If the user passed too many arguments there will be commas in
			// the right, not in the left bc strpos returns the position of the
			// first occurrance.
			local cpos = strpos("`right'", ",")
			if `cpos' > 0 {
				di as error "Too many arguments"
				exit 198
			}
			
			// Alright, now we have to check that the arguments are either
			// numbers or variables. Left.
			nehurdle_parse_probopts `left' if `touse'
			if `s(nh_res)' == 1 {
				di as error "The second argument must be a variable, or an integer, or ."
				exit 198
			}
			
			// Now right.
			nehurdle_parse_probopts `right' if `touse'
			if `s(nh_res)' == 1 {
				di as error "The second argument must be a variable, or an integer, or ."
				exit 198
			}
			
			// if "`left'" == "0" local left = .									// Discrete variable it is the same less than something and 0 to something
			
			if "`left'" == "." & "`right'" == "." {
				di as error "Both arguments cannot be ., or you have pased 0,."
				exit 198
			}
			
			// calculations for all probabilities. Censored variable so both
			// processes.
			tempvar phiz selsig lam
			_predict double `phiz' if `touse', equation(#1)
			if "`e(selhet)'" != "" {
				_predict double `selsig' if `touse', equation(#3)
				quiet replace `selsig' = exp(`selsig') if `touse'
				local eqn = 4
			}
			else {
				quiet generate double `selsig' = 1 if `touse'
				local eqn = 3
			}
			quiet replace `phiz' = normal(`phiz' / `selsig') if `touse'
			_predict double `lam' if `touse', equation(#2)
			quiet replace `lam' = exp(`lam') if `touse'
			
			if "`left'" == "." {
				// Prob. less than. Have to check that right is nonnegative and not missing.
				tempvar check
				quiet generate byte `check' = (`right' < 0) if `touse'
				quiet summarize `check' if `touse', mean
				if r(sum) > 0 {
					di as error "The second argument cannot be negative"
					exit 198
				}
				quiet replace `check' = missing(`right') if `touse'
				quiet summarize `check' if `touse', mean
				if r(sum) > 0 {
					di as error "The second argument cannot have missing values"
					exit 198
				}
				
				quiet replace `lam' = 1 + `phiz' * ((poisson(`lam',`right') -	///
					exp(- `lam')) / (1 - exp(- `lam')) - 1) if `touse'
				quiet generate `vtyp' `varn' = `lam' if `touse'
				label var `varn' "Prob. observed variable: P(`e(depvar)'<=`right'|x,z)"
				exit
			}
			
			if "`right'" == "." {
				// Probability greater than left.
				// Check left is positive and not missing
				tempvar check
				quiet generate byte `check' = (`left' < 0) if `touse'
				quiet summarize `check' if `touse', mean
				if r(sum) > 0 {
					di as error "The first argument cannot be negative"
					exit 198
				}
				quiet replace `check' = missing(`left') if `touse'
				quiet summarize `check' if `touse', mean
				if r(sum) > 0 {
					di as error "The first argument cannot have missing values"
					exit 198
				}
				drop `check'
				
				quiet replace `lam' = `phiz' * (1 - (poisson(`lam', `left' - 1)	///
					- exp(- `lam')) / (1 - exp(- `lam'))) if `touse'
				// Have to catch when left = 0
				quiet replace `lam' = 1 if `touse' & `left' == 0
				quiet generate `vtyp' `varn' = `lam' if `touse'
				label var `varn' "Prob. observed variable: P(`e(depvar)'>=`left'|x,z)"
				exit
			}
			// Probability of in between. Have to do different calculations
			// if left = 0.
			
			// have to check left is non-negative, right is greater than left and
			// neither is missing.
			tempvar check
			quiet generate byte `check' = (`left' < 0) if `touse'
			quiet summarize `check' if `touse', mean
			if r(sum) > 0 {
				di as error "The first argument cannot have negative values"
				exit 198
			}
			quiet replace `check' = (`right'<=`left') if `touse'
			quiet summarize `check' if `touse', mean
			if r(sum) > 0 {
				di as error "The second argument has to be always greater than the first"
				exit 198
			}
			quiet replace `check' = missing(`left',`right') if `touse'
			quiet summarize `check' if `touse', mean
			if r(sum) > 0 {
				di as error "Neither argument can have missing values"
				exit 198
			}
			
			tempvar PR
			quiet generate double `PR' = `phiz' / (1 - exp(- `lam')) *			///
				(poisson(`lam', `right') - poisson(`lam', `left' - 1)) if		///
				`touse' & `left' > 0
			quiet replace `PR' = 1 + `phiz' * ((poisson(`lam', `right') -		///
				exp(- `lam')) / (1 - exp(- `lam')) - 1) if `touse' & `left' == 0
			quiet generate `vtyp' `varn' = `PR' if `touse'
			label var `varn' "Prob. observed variable: P(`left'<=`e(depvar)'<=`right'|x,z)"
			exit
		}
		
		// Probability of the censored variable equaling one value.
		
		// Check prcen is variable or number
		nehurdle_parse_probopts `prcen' if `touse'
		if `s(nh_res)' == 1 {
			di as error "The argument must be a variable, or an integer"
			exit 198
		}
		else if "`prcen'" == "." {
			di as error "The argument cannot be ."
			exit 198
		}
		
		// Finally check if the values are less than zero or missing.
		tempvar check
		quiet generate `check' = (`prcen' < 0) if `touse'
		quiet summarize `check' if `touse', mean
		if r(sum) > 0 {
			di as error "The argument cannot have negative values"
			exit 198
		}
		quiet replace `check' = missing(`prcen') if `touse'
		quiet summarize `check' if `touse', mean
		if r(sum) > 0 {
			di as error "The argument cannot have missing values"
			exit 198
		}
		drop `check'
		
		tempvar psel selsig lam
		_predict double `lam' if `touse', equation(#2)
		quiet replace `lam' = exp(`lam') if `touse'
		_predict double `psel' if `touse', equation(#1)
		if "`e(selhet)'" != "" {
			_predict double `selsig' if `touse', equation(#3)
			quiet replace `selsig' = exp(`selsig') if `touse'
		}
		else quiet generate double `selsig' = 1 if `touse'
		quiet replace `psel' = normal(`psel' / `selsig') if `touse'
		
		tempvar PR
		quiet generate double `PR' = 1 - `psel' if `touse' & `prcen' == 0
		quiet replace `PR' = `psel' / (1 - exp(- `lam')) * exp(- `lam') *		///
			`lam'^`prcen' / round(exp(lnfactorial(`prcen')),1) if `touse'		///
			& `prcen' > 0
		quiet generate `vtyp' `varn' = `PR' if `touse'
		label var `varn' "Prob. observed value: P(`e(depvar)'=`prcen'|x,z)"
		exit
	}
	
	// Truncated variable. Zero truncated poisson.
	if "`ytrun'" != "" {
		// Zero truncated poisson mean.
		tempvar lam		// variable for the latent mean.
		_predict double `lam' if `touse', equation(#2)
		quiet replace `lam' = exp(`lam') if `touse'
		quiet replace `lam' = `lam' / (1 - exp(-`lam')) if `touse'
		quiet generate `vtyp' `varn' = `lam' if `touse'
		label var `varn' "Trunctated variable mean: E(`e(depvar)'*|x,`e(depvar)'*>0)"
		exit
	}
	
	if "`restrun'" != "" {
		tempvar lam		// variable for the latent mean.
		_predict double `lam' if `touse', equation(#2)
		quiet replace `lam' = exp(`lam') if `touse'
		quiet replace `lam' = `lam' / (1 - exp(-`lam')) if `touse'
		quiet replace `lam' = `e(depvar)' - `lam' if `touse'
		quiet generate `vtyp' `varn' = `lam' if `touse'
		label var `varn' "Truncated variable residuals: `e(depvar)' - E(`e(depvar)'*|x,`e(depvar)'*>0)"
		exit
	}
	
	if "`vtrun'" != "" {
		tempvar lam		// variable for the latent mean.
		_predict double `lam' if `touse', equation(#2)
		quiet replace `lam' = exp(`lam') if `touse'
		// Variance.
		quiet replace `lam' = (`lam' + `lam'^2) / (1 - exp(- `lam')) -  (`lam'	///
			/ (1 - exp(- `lam')))^2 if `touse'
		quiet generate `vtyp' `varn' = `lam' if `touse'
		label var `varn' "Truncated variable variance: V(`e(depvar)'*|x,`e(depvar)'*>0)"
		exit
	}
	
	if "`sigtrun'" != "" {
		tempvar lam		// variable for the latent mean.
		_predict double `lam' if `touse', equation(#2)
		quiet replace `lam' = exp(`lam') if `touse'
		// Variance.
		quiet replace `lam' = (`lam' + `lam'^2) / (1 - exp(- `lam')) -  (`lam'	///
			/ (1 - exp(- `lam')))^2 if `touse'
		quiet replace `lam' = sqrt(`lam') if `touse'
		quiet generate `vtyp' `varn' = `lam' if `touse'
		label var `varn' "Truncated variable std. dev.: sd(`e(depvar)'*|x,`e(depvar)'*>0)"
		exit
	}
	
	if "`prtrun'" ! = "" {
		// Check for th position of a comma
		local cpos = strpos("`prtrun'", ",")
		if `cpos' > 0 {
			// Two arguments, theoretically, so cumulative probs.
			// Probability of the censored variable falling between two values.
			local left = substr("`prtrun'",1,`cpos' - 1)
			local right = substr("`prtrun'", `cpos' + 1, .)
			
			// If the user passed too many arguments there will be commas in
			// the right, not in the left bc strpos returns the position of the
			// first occurrance.
			local cpos = strpos("`right'", ",")
			if `cpos' > 0 {
				di as error "Too many arguments"
				exit 198
			}
			
			// Alright, now we have to check that the arguments are either
			// numbers or variables. Left.
			nehurdle_parse_probopts `left' if `touse'
			if `s(nh_res)' == 1 {
				di as error "The first argument must be a variable, or an integer, or ."
				exit 198
			}
			
			// Now right.
			nehurdle_parse_probopts `right' if `touse'
			if `s(nh_res)' == 1 {
				di as error "The second argument must be a variable, or an integer, or ."
				exit 198
			}
			
			if "`left'" == "." & "`right'" == "." {
				di as error "Both arguments cannot be ."
				exit
			}
			
			// ok for all predictions all I need is xb
			tempvar lam
			_predict double `lam' if `touse', equation(#2)
			quiet replace `lam' = exp(`lam') if `touse'							// Now holds the mean
			
			if "`left'" == "." {
				// Probability less or equal to right.
				// check right is greater than zero
				tempvar check
				quiet generate byte `check' = (`right' < 1) if `touse'
				quiet summarize `check' if `touse', mean
				if r(sum) > 0 {
					di as error "The second argument has to be positive"
					exit 198
				}
				drop `check'
				quiet replace `lam' = (poisson(`lam', `right') -				///
					poisson(`lam', 0)) / (1 - exp(- `lam')) if `touse'
				quiet generate `vtyp' `varn' = `lam' if `touse'
				label var `varn' "Prob. truncated variable: P(`e(depvar)'*<=`right'|x,`e(depvar)'*>0)"
				exit
			}
			
			if "`right'" == "." {
				// Probability greater or equal than
				// check left is greater than zero
				tempvar check
				quiet generate byte `check' = (`left' < 1) if `touse'
				quiet summarize `check' if `touse', mean
				if r(sum) > 0 {
					di as error "The first argument has to be positive"
					exit 198
				}
				drop `check'
				
				quiet replace `lam' = 1 - (poisson(`lam', `left' - 1) -			///
					exp(- `lam')) / (1 - exp(- `lam')) if `touse'
				quiet generate `vtyp' `varn' = `lam' if `touse'
				label var `varn' "Prob. truncated variable: P(`e(depvar)'*>=`left'|x,`e(depvar)'*>0)"
				exit
			}
			
			// if we're here we have to do the probability that y falls in a range.
			// Need to check that right is greater than left, and that left is
			// greater than 0.
			tempvar check
			quiet generate byte `check' = (`right'<=`left') if `touse'
			quiet summarize `check' if `touse', mean
			if r(sum) > 0 {
				di as error "The second argument must be greater than the first"
				exit 198
			}
			
			// Finally we have to check that the left is not less than 1 (truncated at 0)
			qui replace `check' = (`left' < 1) if `touse'
			qui summarize `check' if `touse', mean
			if r(sum) > 0 {
				di as error "The first argument cannot be less than 1"
				exit 198
			}
			drop `check'
			
			quiet replace `lam' = (poisson(`lam',`right') - poisson(`lam',		///
				`left' - 1)) / (1 - exp(- `lam')) if `touse'
			quiet generate `vtyp' `varn' = `lam' if `touse'
			label var `varn' "Prob. truncated variable: P(`left'<=`e(depvar)'*<=`right'|x, `e(depvar)'*>0)"
			exit
		}
		
		// single argument in prtrun
		
		// Check prtrun is variable or number
		nehurdle_parse_probopts `prtrun' if `touse'
		if `s(nh_res)' == 1 {
			di as error "The argument must be a variable, or an integer"
			exit 198
		}
		else if "`prtrun'" == "." {
			di as error "The argument cannot be ."
			exit 198
		}
		
		// Finally check if it has nonpositive values and/or missing.
		tempvar check
		quiet generate `check' = (`prtrun' < 1) if `touse'
		quiet summarize `check' if `touse', mean
		if r(sum) > 0 {
			di as error "The argument cannot be less than 1"
			exit 198
		}
		quiet replace `check' = missing(`prtrun') if `touse'
		quiet summarize `check' if `touse', mean
		if r(sum) > 0 {
			di as error "The argument cannot have missing values"
			exit 198
		}
		drop `check'
		
		tempvar lam
		_predict double `lam' if `touse', equation(#2)
		quiet replace `lam' = exp(`lam') if `touse'
		quiet replace `lam' = exp(- `lam') * `lam'^`prtrun' / ((1 -				///
			exp(- `lam')) * round(exp(lnfactorial(`prtrun')),1)) if `touse'
		quiet generate `vtyp' `varn' = `lam' if `touse'
		label var `varn' "Prob. truncated variable: P(`e(depvar)'*=`prtrun'|x,`e(depvar)'*>0)"
		exit
	}
	
	// Latent variable (Poisson).
	if "`ystar'" != "" {
		tempvar lam
		_predict double `lam' if `touse', equation(#2)
		quiet replace `lam' = exp(`lam') if `touse'
		quiet generate `vtyp' `varn' = `lam' if `touse'
		label var `varn' "Latent variable mean: E(`e(depvar)'*|x)"
		exit
	}
	
	if "`resstar'" != "" {
		tempvar lam
		_predict double `lam' if `touse', equation(#2)
		quiet replace `lam' = exp(`lam') if `touse'
		quiet replace `lam' = `e(depvar)' - exp(`lam') if `touse'
		quiet generate `vtyp' `varn' = `lam' if `touse'
		label var `varn' "Latent variable residuals: `e(depvar)' - E(`e(depvar)'*|x)"
		exit
	}
	
	if "`vstar'" != "" {
		// The variance of the poisson variable equals its mean. So
		tempvar var
		_predict double `var' if `touse', equation(#2)
		quiet replace `var' = exp(`var') if `touse'
		quiet generate `vtyp' `varn' = `var' if `touse'
		label var `varn' "Latent variable variance: V(`e(depvar)'*|x)"
		exit
	}
	
	if "`sigstar'" != "" {
		tempvar var
		_predict double `var' if `touse', equation(#2)
		quiet replace `var' = sqrt(exp(`var')) if `touse'
		quiet generate `vtyp' `varn' = `var' if `touse'
		label var `varn' "Latent variable std. dev.: sd(`e(depvar)'*|x)"
		exit
	}
	
	if "`prstar'" != "" {
		
		// Check for the position of a comma
		local cpos = strpos("`prstar'", ",")
		if `cpos' > 0 {
			// Two arguments, theoretically, so cumulative probs.
			// Probability of the censored variable falling between two values.
			local left = substr("`prstar'",1,`cpos' - 1)
			local right = substr("`prstar'", `cpos' + 1, .)
			
			// If the user passed too many arguments there will be commas in
			// the right, not in the left bc strpos returns the position of the
			// first occurrance.
			local cpos = strpos("`right'", ",")
			if `cpos' > 0 {
				di as error "Too many arguments"
				exit 198
			}
			
			// Alright, now we have to check that the arguments are either
			// numbers or variables. Left.
			nehurdle_parse_probopts `left' if `touse'
			if `s(nh_res)' == 1 {
				di as error "The first argument must be a variable, or an integer, or ."
				exit 198
			}
			
			// Now right.
			nehurdle_parse_probopts `right' if `touse'
			if `s(nh_res)' == 1 {
				di as error "The second argument must be a variable, or an integer, or ."
				exit 198
			}
			
			if "`left'" == "." & "`right'" == "." {
				di as error "Both arguments cannot be . or you've passed (0,.)"
				exit 198
			}
			
			// OK all we need is mux
			tempvar lam
			_predict double `lam' if `touse', equation(#2)
			quiet replace `lam' = exp(`lam') if `touse'
			
			if "`left'" == "." {
				// Probability less or equal to.
				// Check right is positive.
				tempvar check
				quiet generate byte `check' = (`right' < 0) if `touse'
				quiet summarize `check' if `touse', mean
				if r(sum) > 0 {
					di as error "Second argument cannot be negative"
					exit 198
				}
				quiet replace `check' = missing(`right') if `touse'
				quiet summarize `check' if `touse', mean
				if r(sum) > 0 {
					di as error "Second argument cannot have missing values"
					exit 198
				}
				drop `check'
				
				quiet replace `lam' = poisson(`lam', `right') if `touse'
				quiet generate `vtyp' `varn' = `lam' if `touse'
				label var `varn' "Prob. latent variable: P(`e(depvar)'*<=`right'|x)"
				exit
			}
			
			// Greater or equal than
			if "`right'" == "." {
				// check left is positive and not missing
				tempvar check
				quiet generate byte `check' = (`left' < 0) if `touse'
				quiet summarize `check' if `touse', mean
				if r(sum) > 0 {
					di as error "The first argument cannot be negative"
					exit 198
				}
				quiet replace `check' = missing(`left') if `touse'
				quiet summarize `check' if `touse', mean
				if r(sum) > 0 {
					di as error "The first argument cannot have missing values"
					exit 198
				}
				drop `check'
				
				quiet replace `lam' = 1 - poisson(`lam', `left' - 1) if `touse'
				// Catch if left = 0
				quiet replace `lam' = 1 if `touse' & `left' == 0
				quiet generate `vtyp' `varn' = `lam' if `touse'
				label var `varn' "Prob. latent variable: P(`e(depvar)'*>=`left'|x)"
				exit
			}
			
			// Ok so here probability of an interval.
			
			// check left is not negative, right is greater than left and neither
			// have missing values
			tempvar check
			
			quiet generate byte `check' = (`left' < 0) if `touse'
			quiet summarize `check' if `touse', mean
			if r(sum) > 0 {
				di as error "First argument cannot be negative"
				exit 198
			}
			
			quiet replace `check' = (`right'<=`left') if `touse'
			quiet summarize `check' if `touse', mean
			if r(sum) > 0 {
				di as error "Second argument has to be greater than the first"
				exit 198
			}
			
			quiet replace `check' = missing(`left',`right') if `touse'
			quiet summarize `check' if `touse', mean
			if r(sum) > 0 {
				di as error "Neither argument can have missing values"
				exit 198
			}
			drop `check'
			
			tempvar PR
			// If left = 0, this is the same as <= right. Otherwise interval.
			quiet generate double `PR' = poisson(`lam', `right') -				///
				poisson(`lam', `left' - 1) if `touse' & `left' > 0
			quiet replace `PR' = poisson(`lam', `right') if `touse' & `left' == 0
			quiet generate `vtyp' `varn' = `PR' if `touse'
			label var `varn' "Prob. latent variable: P(`left'<=`e(depvar)'*<=`right'|x)"
			exit
		}
		
		// Single value
		// Check prstar is variable or number
		nehurdle_parse_probopts `prstar' if `touse'
		if `s(nh_res)' == 1 {
			di as error "The argument must be a variable, or an integer"
			exit 198
		}
		else if "`prstar'" == "." {
			di as error "The argument cannot be ."
			exit 198
		}
		
		// Check if the values are less than 0 or missing
		tempvar check
		quiet generate `check' = (`prstar' < 0) if `touse'
		quiet summarize `check' if `touse', mean
		if r(sum) > 0 {
			di as error "The argument cannot be less than 1"
			exit 198
		}
		quiet replace `check' = missing(`prstar') if `touse'
		quiet summarize `check' if `touse', mean
		if r(sum) > 0 {
			di as error "The argument cannot have missing values"
			exit 198
		}
		drop `check'
		
		tempvar lam
		_predict double `lam' if `touse', equation(#2)
		quiet replace `lam' = exp(`lam') if `touse'
		quiet replace `lam' = exp( -`lam') * `lam'^`prstar' /					///
			round(exp(lnfactorial(`prstar')), 1) if `touse'
		quiet generate `vtyp' `varn' = `lam' if `touse'
		label var `varn' "Prob. latent variable: P(`e(depvar)'*=`prstar'|x)"
		exit
	}
	
	if "`xbval'" != "" {
		_predict `vtyp' `varn' if `touse', equation(#2)
		label var `varn' "`e(depvar)' equation fitted values (xb)"
		exit
	}
	
	if "`xbsel'" != "" {
		_predict `vtyp' `varn' if `touse', equation(#1)
		label var `varn' "Selection equation fitted values (xb)"
		exit
	}
	
	if "`xbselsig'" != "" {
		if "`e(selhet)'" == "" {
			di as error "{bf:xbselsig} not valid"
			exit 198
		}
		_predict `vtyp' `varn' if `touse', equation(#3)
		label var `varn' "Selection ln std. dev. fitted values (xb)"
		exit
	}
	
	if "`selsigma'" != "" {
		if "`e(selhet)'" == "" {
			di as error "{bf: selsigma} not valid"
			exit 198
		}
		tempvar sig
		_predict double `sig' if `touse', equation(#3)
		quiet replace `sig' = exp(`sig') if `touse'
		quiet generate `vtyp' `varn' = `sig' if `touse'
		label var `varn' "Std. dev. selection equation: exp(sellnsigma)"
		exit
	}
	
	if "`psel'" != "" {
		tempvar phiz selsig
		_predict double `phiz' if `touse', equation(#1)
		if "`e(selhet)'" != "" {
			_predict double `selsig' if `touse', equation(#3)
			quiet replace `selsig' = exp(`selsig') if `touse'
		}
		else quiet generate double `selsig' = 1 if `touse'
		quiet replace `phiz' = normal(`phiz' / `selsig') if `touse'
		quiet generate `vtyp' `varn' = `phiz' if `touse'
		label var `varn' "Prob. selection: Pr(`e(depvar)' > 0|z)"
		exit
	}
	
	if "`ressel'" != "" {
		tempvar phiz selsig dy
		quiet generate double `dy' = `e(depvar)' > 0 if `touse'
		_predict double `phiz' if `touse', equation(#1)
		if "`e(selhet)'" != "" {
			_predict double `selsig' if `touse', equation(#3)
			quiet replace `selsig' = exp(`selsig') if `touse'
		}
		else quiet generate double `selsig' = 1 if `touse'
		quiet replace `phiz' = `dy' - normal(`phiz' / `selsig') if `touse'
		quiet generate `vtyp' `varn' = `phiz' if `touse'
		label var `varn' "Prob. participation residuals: I(`e(depvar)'>0) -  Pr(`e(depvar)'>0|z)"
		exit
	}
	
	// Ycen is de default, so if we're here that is what we predict.
	if "`ycen'" == "" noi di as txt "(option ycen assumed)"
	tempvar lam psel selsig
	_predict double `lam' if `touse', equation(#2)
	quiet replace `lam' = exp(`lam') if `touse'
	_predict double `psel' if `touse', equation(#1)
	if "`e(selhet)'" != "" {
		_predict double `selsig' if `touse', equation(#3)
		quiet replace `selsig' = exp(`selsig') if `touse'
	}
	else quiet generate double `selsig' = 1 if `touse'
	quiet replace `psel' = normal(`psel' / `selsig') if `touse'
	quiet replace `lam' = `psel' * `lam' / (1 - exp(- `lam')) if `touse'
	quiet generate `vtyp' `varn' = `lam' if `touse'
	label var `varn' "Observed variable mean: E(`e(depvar)'|x,z)"
end


// NEGATIVE BINOMIAL 1
capture program drop nehurdle_truncnb1_p
program define nehurdle_truncnb1_p, eclass
	syntax anything(id="newvarname") [if] [in]									///
	[, {																		///
		YCen			|														///
		RESCen			|														///
		VCen			|														///
		SIGCen			|														///
		PRCen(string)	|														///
		YTrun			|														///
		RESTrun			|														///
		VTrun			|														///
		SIGTrun			|														///
		PRTrun(string)	|														///
		YStar			|														///
		RESStar			|														///
		VStar			|														///
		SIGStar			|														///
		PRStar(string)	|														///
		XB				|														///
		XBVal			|														///
		XBSel			|														///
		XBSELSig		|														///
		XBAlpha			|														///
		SELSIGma		|														///
		ALPha			|														///
		PSel			|														///
		RESSEL			|														///
		SCores																	///
	} * ]
	
	if "`scores'" != "" {
		local bvar "`e(depvar)'"
		tempvar dy y1
		quiet generate byte `dy' = `bvar' > 0
		quiet generate double `y1' = `bvar'
		ereturn local depvar "`dy' `y1'"
		
		marksample touse
		marksample touse2
		local xvars : colna e(b)
		local cons _cons _cons _cons
		local xvars : list xvars - cons
		
		markout `touse2' `xvars'
		quiet replace `touse' = 0 if `dy' & !`touse2'
		ml score `anything' if `touse', `scores' missing `options'
		ereturn local depvar "`bvar'"
		exit
	}
	
	local myopts "YCen RESCen VCen SIGCen PRCen(string) YTrun RESTrun VTrun"
	local myopts "`myopts' SIGTrun PRTrun(string) YStar RESStar VStar SIGStar"
	local myopts "`myopts' PRStar(string) XB XBVal PSel RESSEL XBSel SELSIGma"
	local myopts "`myopts' XBSELSig XBAlpha ALPha"
	_pred_se "`myopts'" `0'
	if `s(done)' exit
	local vtyp  `s(typ)'
	local varn `s(varn)'
	local 0 `"`s(rest)'"'
	
	// marking sample
	marksample touse
	
	
	// Have to capture xb to notify it is not valid.
	if "`xb'" != "" {
		di as error "option {bf:xb} not valid"
		di as error "Try one of the following:"
		di as error _col(6) "1. {bf:xbval} for fitted values of the value equation."
		di as error _col(6) "2. {bf:xbsel} for fitted values of the selection equation."
		if "`e(selhet)'" != "" {
			di as error _col(6) "3. {bf:xbselsig} for fitted values of the selection ln sigma."
			di as error _col(6) "4. {bf:xbalpha} for fitted values of the ln of dispersion"
		}
		else																	///
			di as error _col(6) "3. {bf:xbalpha} for fitted values of the ln of dispersion"
		exit 198
	}
	
	// Censored (observed) variable.
	// ycen is the default so I do that at the end.
	if "`rescen'" != "" {
		tempvar mu zg selsig alpha
		_predict double `zg' if `touse', equation(#1)
		_predict double `mu' if `touse', equation(#2)
		quiet replace `mu' = exp(`mu') if `touse'
		if "`e(selhet)'" != "" {
			_predict double `selsig' if `touse', equation(#3)
			quiet replace `selsig' = exp(`selsig') if `touse'
			_predict double `alpha' if `touse', equation(#4)
		}
		else {
			quiet generate double `selsig' = 1 if `touse'
			_predict double `alpha' if `touse', equation(#3)
		}
		quiet replace `alpha' = -20 if `touse' & `alpha' < -20
		quiet replace `alpha' = exp(`alpha') if `touse'
		
		
		quiet replace `mu' = normal(`zg' / `selsig') * `mu' / (1 - (1 +			///
			`alpha')^(- `mu' / `alpha')) if `touse'
		quiet replace `mu' = `e(depvar)' - `mu' if `touse'
		quiet generate `vtyp' `varn' = `mu' if `touse'
		label var `varn' "Observed variable residuals: `e(depvar)' - E(`e(depvar)'|x,z)"
		exit
	}
	
	if "`vcen'" != "" {
		tempvar phiz selsig alpha mu var
		_predict double `phiz' if `touse', equation(#1)
		_predict double `mu' if `touse', equation(#2)
		quiet replace `mu' = exp(`mu') if `touse'
		if "`e(selhet)'" != "" {
			_predict double `selsig' if `touse', equation(#3)
			quiet replace `selsig' = exp(`selsig') if `touse'
			_predict double `alpha' if `touse', equation(#4)
		}
		else {
			quiet generate double `selsig' = 1 if `touse'
			_predict double `alpha' if `touse', equation(#3)
		}
		quiet replace `alpha' = -20 if `touse' & `alpha' < -20
		quiet replace `alpha' = exp(`alpha') if `touse'
		quiet replace `phiz' = normal(`phiz' / `selsig') if `touse'
		
		// Alright, now we form the variance.
		quiet generate double `var' = `phiz' * `mu' * (1 + `alpha' + `mu') /	///
			(1 - (1 + `alpha')^(- `mu' / `alpha')) - (`phiz' * `mu' / (1 - (1 +	///
			`alpha')^(- `mu' / `alpha')))^2 if `touse'
		quiet generate `vtyp' `varn' = `var' if `touse'
		label var `varn' "Observed variable variance: V(`e(depvar)'|x,z)"
		exit
	}
	
	if "`sigcen'" != "" {
		tempvar phiz selsig alpha mu var
		_predict double `phiz' if `touse', equation(#1)
		_predict double `mu' if `touse', equation(#2)
		quiet replace `mu' = exp(`mu') if `touse'
		if "`e(selhet)'" != "" {
			_predict double `selsig' if `touse', equation(#3)
			quiet replace `selsig' = exp(`selsig') if `touse'
			_predict double `alpha' if `touse', equation(#4)
		}
		else {
			quiet generate double `selsig' = 1 if `touse'
			_predict double `alpha' if `touse', equation(#3)
		}
		quiet replace `alpha' = -20 if `touse' & `alpha' < -20
		quiet replace `alpha' = exp(`alpha') if `touse'
		quiet replace `phiz' = normal(`phiz' / `selsig') if `touse'
		
		// Alright, now we form the variance.
		quiet generate double `var' = `phiz' * `mu' * (1 + `alpha' + `mu') /	///
			(1 - (1 + `alpha')^(- `mu' / `alpha')) - (`phiz' * `mu' / (1 - (1 +	///
			`alpha')^(- `mu' / `alpha')))^2 if `touse'
		quiet replace `var' = sqrt(`var') if `touse'
		quiet generate `vtyp' `varn' = `var' if `touse'
		label var `varn' "Observed variable std. dev.: sd(`e(depvar)'|x,z)"
		exit
	}
	
	// Probability of the censored variable
	if "`prcen'" != "" {
		// First thing we check whether the position of a comma in the string
		local cpos = strpos("`prcen'", ",")
		if `cpos' > 0 {
			// Probability of the censored variable falling between two values.
			local left = substr("`prcen'",1,`cpos' - 1)
			local right = substr("`prcen'", `cpos' + 1, .)
			
			// If the user passed too many arguments there will be commas in
			// the right, not in the left bc strpos returns the position of the
			// first occurrance.
			local cpos = strpos("`right'", ",")
			if `cpos' > 0 {
				di as error "Too many arguments"
				exit 198
			}
			
			// Alright, now we have to check that the arguments are either
			// numbers or variables. Left.
			nehurdle_parse_probopts `left' if `touse'
			if `s(nh_res)' == 1 {
				di as error "The second argument must be a variable, or an integer, or ."
				exit 198
			}
			
			// Now right.
			nehurdle_parse_probopts `right' if `touse'
			if `s(nh_res)' == 1 {
				di as error "The second argument must be a variable, or an integer, or ."
				exit 198
			}
			
			if "`left'" == "." & "`right'" == "." {
				di as error "Both arguments cannot be ., or you have pased 0,."
				exit 198
			}
			
			tempvar phiz selsig alpha mu p pg0 PR
			// Model calculations
			_predict double `phiz' if `touse', equation(#1)
			_predict double `mu' if `touse', equation(#2)
			quiet replace `mu' = exp(`mu') if `touse'
			if "`e(selhet)'" != "" {
				_predict double `selsig' if `touse', equation(#3)
				quiet replace `selsig' = exp(`selsig') if `touse'
				_predict double `alpha' if `touse', equation(#4)
			}
			else {
				quiet generate double `selsig' = 1 if `touse'
				_predict double `alpha' if `touse', equation(#3)
			}
			quiet replace `alpha' = -20 if `touse' & `alpha' < -20
			quiet replace `alpha' = exp(`alpha') if `touse'
			quiet replace `phiz' = normal(`phiz' / `selsig') if `touse'
			
			// p to use with nbinomial functions
			quiet generate double `p' = 1 / (1 + `alpha') if `touse'
			// truncating probability
			quiet generate double `pg0' = nbinomialtail(`mu' / `alpha', 1, `p') if	///
				`touse'
			
			if "`left'" == "." {
				// Prob. less than. Have to check that right is not negative and not missing.
				tempvar check
				quiet generate byte `check' = (`right' < 0) if `touse'
				quiet summarize `check' if `touse', mean
				if r(sum) > 0 {
					di as error "The second argument cannot be negative"
					exit 198
				}
				quiet replace `check' = missing(`right') if `touse'
				quiet summarize `check' if `touse', mean
				if r(sum) > 0 {
					di as error "The second argument cannot have missing values"
					exit 198
				}
				
				quiet generate double `PR' = 1 + `phiz' * (nbinomial(`mu' /		///
					`alpha', `right', `p') - 1) / `pg0' if `touse'
				quiet generate `vtyp' `varn' = `PR' if `touse'
				label var `varn' "Prob. observed variable: P(`e(depvar)'<=`right'|x,z)"
				exit
			}
			
			if "`right'" == "." {
				// Probability greater or equal to left.
				
				// Check left is nonnegative and not missing.  If it were 0 we would
				// have that the probability is 1, so we have to replace those.
				tempvar check
				quiet generate byte `check' = (`left' < 0) if `touse'
				quiet summarize `check' if `touse', mean
				if r(sum) > 0 {
					di as error "The first argument cannot be negative"
					exit 198
				}
				quiet replace `check' = missing(`left') if `touse'
				quiet summarize `check' if `touse', mean
				if r(sum) > 0 {
					di as error "The first argument cannot have missing values"
					exit 198
				}
				drop `check'
				
				quiet generate double `PR' = `phiz' * nbinomialtail(`mu' /			///
					`alpha', `left', `p') / `pg0' if `touse'
				quiet replace `PR' = 1 if `touse' & `left' == 0
				quiet generate `vtyp' `varn' = `PR' if `touse'
				label var `varn' "Prob. observed variable: P(`e(depvar)'>=`left'|x,z)"
				exit
			}
			// Probability of in between.
			
			// have to check left is non-negative, right is greater than left and
			// neither is missing.
			tempvar check
			quiet generate byte `check' = (`left' < 0) if `touse'
			quiet summarize `check' if `touse', mean
			if r(sum) > 0 {
				di as error "The first argument cannot have negative values"
				exit 198
			}
			quiet replace `check' = (`right'<=`left') if `touse'
			quiet summarize `check' if `touse', mean
			if r(sum) > 0 {
				di as error "The second argument has to be always greater than the first"
				exit 198
			}
			quiet replace `check' = missing(`left',`right') if `touse'
			quiet summarize `check' if `touse', mean
			if r(sum) > 0 {
				di as error "Neither argument can have missing values"
				exit 198
			}
			
			// If left = 0 , this is the same as y <= right.
			quiet generate double `PR' = 1 + `phiz' * (nbinomial(`mu' /			///
				`alpha', `right', `p') - 1) / `pg0' if `touse' & `left' == 0
			// If left > 0 we apply the formula for the interval
			quiet replace `PR' = `phiz' * (nbinomial(`mu' / `alpha', `right',	///
				`p') - nbinomial(`mu' / `alpha', `left' - 1, `p')) / `pg0'		///
				if `touse' & `left' > 0
			quiet generate `vtyp' `varn' = `PR' if `touse'
			label var `varn' "Prob. observed variable: P(`left'<=`e(depvar)'<=`right'|x,z)"
			exit
		}
		
		// Probability of the censored variable equaling one value.
		
		// Check prcen is variable or number
		nehurdle_parse_probopts `prcen' if `touse'
		if `s(nh_res)' == 1 {
			di as error "The argument must be a variable, or an integer"
			exit 198
		}
		else if "`prcen'" == "." {
			di as error "The argument cannot be ."
			exit 198
		}
		
		// Finally check if the values are less than zero or missing.
		tempvar check
		quiet generate `check' = (`prcen' < 0) if `touse'
		quiet summarize `check' if `touse', mean
		if r(sum) > 0 {
			di as error "The argument cannot have negative values"
			exit 198
		}
		quiet replace `check' = missing(`prcen') if `touse'
		quiet summarize `check' if `touse', mean
		if r(sum) > 0 {
			di as error "The argument cannot have missing values"
			exit 198
		}
		drop `check'
		
		// Let's get what we need
		tempvar phiz nphiz selsig alpha mu p pg0 PR
		// Model calculations
		_predict double `phiz' if `touse', equation(#1)
		_predict double `mu' if `touse', equation(#2)
		quiet replace `mu' = exp(`mu') if `touse'
		if "`e(selhet)'" != "" {
			_predict double `selsig' if `touse', equation(#3)
			quiet replace `selsig' = exp(`selsig') if `touse'
			_predict double `alpha' if `touse', equation(#4)
		}
		else {
			quiet generate double `selsig' = 1 if `touse'
			_predict double `alpha' if `touse', equation(#3)
		}
		quiet replace `alpha' = -20 if `touse' & `alpha' < -20
		quiet replace `alpha' = exp(`alpha') if `touse'
		quiet generate double `nphiz' = normal(- `phiz' / `selsig') if `touse'
		quiet replace `phiz' = normal(`phiz' / `selsig') if `touse'
		
		// p to use with nbinomial functions
		quiet generate double `p' = 1 / (1 + `alpha') if `touse'
		// truncating probability
		quiet generate double `pg0' = nbinomialtail(`mu' / `alpha', 1, `p') if	///
			`touse'
		
		// Ok if prcen = 0 we want 1 - phiz (nphiz), but if not, we want
		// phiz times the truncated probability.
		quiet generate double `PR' = `nphiz' if `touse' & `prcen' == 0
		quiet replace `PR' = `phiz' * nbinomialp(`mu' / `alpha', `prcen', `p') /	///
			`pg0' if `touse' & `prcen' > 0
		quiet generate `vtyp' `varn' = `PR' if `touse'
		label var `varn' "Prob. observed value: P(`e(depvar)'=`prcen'|x,z)"
		exit
	}
	
	if "`ytrun'" != "" {
		tempvar alpha mu
		_predict double `mu' if `touse', equation(#2)
		quiet replace `mu' = exp(`mu') if `touse'
		if "`e(selhet)'" != "" local eqn = 4
		else local eqn = 3
		_predict double `alpha' if `touse', equation(#`eqn')
		quiet replace `alpha' = -20 if `touse' & `alpha' < -20
		quiet replace `alpha' = exp(`alpha') if `touse'
		
		quiet replace `mu' = `mu' / (1 - (1 + `alpha')^(- `mu' / `alpha'))		///
			if `touse'
		quiet generate `vtyp' `varn' = `mu' if `touse'
		label var `varn' "Trunctated variable mean: E(`e(depvar)'*|x,`e(depvar)'*>0)"
		exit
	}
	
	if "`restrun'" != "" {
		tempvar alpha mu
		_predict double `mu' if `touse', equation(#2)
		quiet replace `mu' = exp(`mu') if `touse'
		if "`e(selhet)'" != "" local eqn = 4
		else local eqn = 3
		_predict double `alpha' if `touse', equation(#`eqn')
		quiet replace `alpha' = -20 if `touse' & `alpha' < -20
		quiet replace `alpha' = exp(`alpha') if `touse'
		
		quiet replace `mu' = `mu' / (1 - (1 + `alpha')^(- `mu' / `alpha'))		///
			if `touse'
		quiet replace `mu' = `e(depvar)' - `mu' if `touse'
		quiet generate `vtyp' `varn' = `mu' if `touse'
		label var `varn' "Truncated variable resisduals: `e(depvar)'*|`e(depvar)'*>0"
		exit
	}
	
	if "`vtrun'" != "" {
		tempvar alpha mu var
		_predict double `mu' if `touse', equation(#2)
		quiet replace `mu' = exp(`mu') if `touse'
		if "`e(selhet)'" != "" local eqn = 4
		else local eqn = 3
		_predict double `alpha' if `touse', equation(#`eqn')
		quiet replace `alpha' = -20 if `touse' & `alpha' < -20
		quiet replace `alpha' = exp(`alpha') if `touse'
		
		quiet generate double `var' = `mu' * (1 + `alpha' + `mu') / (1 - (1 +	///
			`alpha')^(- `mu' / `alpha')) - (`mu' / (1 - (1 + `alpha')^(- `mu' /	///
			`alpha')))^2 if `touse'
		quiet generate `vtyp' `varn' = `var' if `touse'
		label var `varn' "Truncated variable variance: V(`e(depvar)'*|x,`e(depvar)'*>0)"
		exit
	}
	
	if "`sigtrun'" != "" {
		tempvar alpha mu var
		_predict double `mu' if `touse', equation(#2)
		quiet replace `mu' = exp(`mu') if `touse'
		if "`e(selhet)'" != "" local eqn = 4
		else local eqn = 3
		_predict double `alpha' if `touse', equation(#`eqn')
		quiet replace `alpha' = -20 if `touse' & `alpha' < -20
		quiet replace `alpha' = exp(`alpha') if `touse'
		
		quiet generate double `var' = `mu' * (1 + `alpha' + `mu') / (1 - (1 +	///
			`alpha')^(- `mu' / `alpha')) - (`mu' / (1 - (1 + `alpha')^(- `mu' /	///
			`alpha')))^2 if `touse'
		quiet replace `var' = sqrt(`var') if `touse'
		quiet generate `vtyp' `varn' = `var' if `touse'
		label var `varn' "Truncated variable std. dev.: sd(`e(depvar)'*|x,`e(depvar)'*>0)"
		exit
	}
	
	if "`prtrun'" ! = "" {
		// Check for th position of a comma
		local cpos = strpos("`prtrun'", ",")
		if `cpos' > 0 {
			// Two arguments, theoretically, so cumulative probs.
			// Probability of the censored variable falling between two values.
			local left = substr("`prtrun'",1,`cpos' - 1)
			local right = substr("`prtrun'", `cpos' + 1, .)
			
			// If the user passed too many arguments there will be commas in
			// the right, not in the left bc strpos returns the position of the
			// first occurrance.
			local cpos = strpos("`right'", ",")
			if `cpos' > 0 {
				di as error "Too many arguments"
				exit 198
			}
			
			// Alright, now we have to check that the arguments are either
			// numbers or variables. Left.
			nehurdle_parse_probopts `left' if `touse'
			if `s(nh_res)' == 1 {
				di as error "The first argument must be a variable, or an integer, or ."
				exit 198
			}
			
			// Now right.
			nehurdle_parse_probopts `right' if `touse'
			if `s(nh_res)' == 1 {
				di as error "The second argument must be a variable, or an integer, or ."
				exit 198
			}
			
			// Need mu and alpha
			tempvar mu alpha p pg0 PR
			_predict double `mu' if `touse', equation(#2)
			quiet replace `mu' = exp(`mu') if `touse'
			if "`e(selhet)'" != "" local eqn = 4
			else local eqn = 3
			_predict double `alpha' if `touse', equation(#`eqn')
			quiet replace `alpha' = -20 if `touse' & `alpha' < -20
			quiet replace `alpha' = exp(`alpha') if `touse'
			
			// var to use with nbinomial(), nbinomialtail() and nbinomialp()
			quiet generate double `p' = 1 / (1 + `alpha') if `touse'
			quiet generate double `pg0' = nbinomialtail(`mu' / `alpha', 1, `p')	///
				if `touse'
			
			if "`left'" == "." & "`right'" == "." {
				di as error "Both arguments cannot be ."
				exit
			}
			
			if "`left'" == "." {
				// Probability less or equal to right.
				// check right is greater than zero
				tempvar check
				quiet generate byte `check' = (`right' < 1) if `touse'
				quiet summarize `check' if `touse', mean
				if r(sum) > 0 {
					di as error "The second argument has to be positive"
					exit 198
				}
				drop `check'
				
				quiet generate double `PR' = (nbinomial(`mu' / `alpha',			///
					`right', `p') - nbinomialp(`mu' / `alpha', 0, `p')) / `pg0'	///
					if `touse'
				quiet generate `vtyp' `varn' = `PR' if `touse'
				label var `varn' "Prob. truncated variable: P(`e(depvar)'*<=`right'|x,`e(depvar)'*>0)"
				exit
			}
			
			if "`right'" == "." {
				// Probability greater or equal than
				// check left is greater than zero
				tempvar check
				quiet generate byte `check' = (`left' < 1) if `touse'
				quiet summarize `check' if `touse', mean
				if r(sum) > 0 {
					di as error "The first argument has to be positive"
					exit 198
				}
				drop `check'
				
				quiet generate double `PR' = nbinomialtail(`mu' / `alpha',		///
					`left', `p') / `pg0' if `touse'
				quiet generate `vtyp' `varn' = `PR' if `touse'
				label var `varn' "Prob. truncated variable: P(`e(depvar)'*>=`left'|x,`e(depvar)'*>0)"
				exit
			}
			
			// if we're here we have to do the probability that y falls in a range.
			// Need to check that right is greater than left, and that left is
			// greater than 0.
			tempvar check
			quiet generate byte `check' = (`right'<=`left') if `touse'
			quiet summarize `check' if `touse', mean
			if r(sum) > 0 {
				di as error "The second argument must be greater than the first"
				exit 198
			}
			quiet replace `check' = (`left' < 1) if `touse'
			quiet summarize `check' if `touse', mean
			if r(sum) > 0 {
				di as error "The first argument cannot be less than 1"
				exit 198
			}
			// Also need to check that neither is missing.
			quiet replace `check' = missing(`left', `right') if `touse'
			quiet summarize `check' if `touse', mean
			if r(sum) > 0 {
				di as error "Neither argument can be missing"
				exit 198
			}
			drop `check'
			
			// Since the minimum left value is 1 we don't have to worry about
			// zeroes in this case.
			quiet generate double `PR' = (nbinomial(`mu' / `alpha', `right',	///
				`p') - nbinomial(`mu' / `alpha', `left' - 1, `p')) / `pg0'		///
				if `touse'
			quiet generate `vtyp' `varn' = `PR' if `touse'
			label var `varn' "Prob. truncated variable: P(`left'<=`e(depvar)'*<=`right'|x, `e(depvar)'*>0)"
			exit
		}
		
		// single argument in prtrun
		
		// Check prtrun is variable or number
		nehurdle_parse_probopts `prtrun' if `touse'
		if `s(nh_res)' == 1 {
			di as error "The argument must be a variable with integers, or an integer value"
			exit 198
		}
		else if "`prtrun'" == "." {
			di as error "The argument cannot be ."
			exit 198
		}
		
		// Finally check if it has nonpositive values and/or missing.
		tempvar check
		quiet generate byte `check' = (`prtrun' < 1) if `touse'
		quiet summarize `check' if `touse', mean
		if r(sum) > 0 {
			di as error "The argument cannot be less than 1"
			exit 198
		}
		quiet replace `check' = missing(`prtrun') if `touse'
		quiet summarize `check' if `touse', mean
		if r(sum) > 0 {
			di as error "The argument cannot have missing values"
			exit 198
		}
		drop `check'
		
		// Need mu and alpha
		tempvar mu alpha p PR pg0
		_predict double `mu' if `touse', equation(#2)
		quiet replace `mu' = exp(`mu') if `touse'
		if "`e(selhet)'" != "" local eqn = 4
		else local eqn = 3
		_predict double `alpha' if `touse', equation(#`eqn')
		quiet replace `alpha' = -20 if `touse' & `alpha' < -20
		quiet replace `alpha' = exp(`alpha') if `touse'
		
		// var to use with nbinomial(), nbinomialtail() and nbinomialp()
		quiet generate double `p' = 1 / (1 + `alpha') if `touse'
		quiet generate double `pg0' = nbinomialtail(`mu' / `alpha', 1, `p')		///
			if `touse'
		
		quiet generate double `PR' = nbinomialp(`mu' / `alpha', `prtrun', `p')	///
			/ `pg0' if `touse'
		quiet generate `vtyp' `varn' = `PR' if `touse'
		label var `varn' "Prob. truncated variable: P(`e(depvar)'*=`prtrun'|x,`e(depvar)'*>0)"
		exit
	}
	
	if "`ystar'" != "" {
		tempvar mu
		_predict double `mu' if `touse', equation(#2)
		quiet replace `mu' = exp(`mu') if `touse'
		quiet generate `vtyp' `varn' = `mu' if `touse'
		label var `varn' "Latent variable mean: E(`e(depvar)'*|x)"
		exit
	}
	
	if "`resstar'" != "" {
		tempvar mu
		_predict double `mu' if `touse', equation(#2)
		quiet replace `mu' = exp(`mu') if `touse'
		quiet generate `vtyp' `varn' = `e(depvar)' - `mu' if `touse'
		label var `varn' "Latent variable residuals: `e(depvar)' - E(`e(depvar)'*|x)"
		exit
	}
	
	if "`vstar'" != "" {
		tempvar alpha mu var
		_predict double `mu' if `touse', equation(#2)
		quiet replace `mu' = exp(`mu') if `touse'
		if "`e(selhet)'" != "" local eqn = 4
		else local eqn = 3
		_predict double `alpha' if `touse', equation(#`eqn')
		quiet replace `alpha' = -20 if `touse' & `alpha' < -20
		quiet replace `alpha' = exp(`alpha') if `touse'
		quiet generate double `var' = `mu' * (1 + `alpha') if `touse'
		quiet generate `vtyp' `varn' = `var' if `touse'
		label var `varn' "Latent variable variance: V(`e(depvar)'*|x)"
		exit
	}
	
	if "`sigstar'" != "" {
		tempvar alpha mu var
		_predict double `mu' if `touse', equation(#2)
		quiet replace `mu' = exp(`mu') if `touse'
		if "`e(selhet)'" != "" local eqn = 4
		else local eqn = 3
		_predict double `alpha' if `touse', equation(#`eqn')
		quiet replace `alpha' = -20 if `touse' & `alpha' < -20
		quiet replace `alpha' = exp(`alpha') if `touse'
		quiet generate double `var' = sqrt(`mu' * (1 + `alpha')) if `touse'
		quiet generate `vtyp' `varn' = `var' if `touse'
		label var `varn' "Latent variable std. dev.: sd(`e(depvar)'*|x)"
		exit
	}
	
	if "`prstar'" != "" {
		// Check for th position of a comma
		local cpos = strpos("`prstar'", ",")
		if `cpos' > 0 {
			// Two arguments, theoretically, so cumulative probs.
			// Probability of the censored variable falling between two values.
			local left = substr("`prstar'",1,`cpos' - 1)
			local right = substr("`prstar'", `cpos' + 1, .)
			
			// If the user passed too many arguments there will be commas in
			// the right, not in the left bc strpos returns the position of the
			// first occurrance.
			local cpos = strpos("`right'", ",")
			if `cpos' > 0 {
				di as error "Too many arguments"
				exit 198
			}
			
			// Alright, now we have to check that the arguments are either
			// numbers or variables. Left.
			nehurdle_parse_probopts `left' if `touse'
			if `s(nh_res)' == 1 {
				di as error "The first argument must be a variable with integers, or an integer, or ."
				exit 198
			}
			// else if "`left'" == "0" local left = .
			
			// Now right.
			nehurdle_parse_probopts `right' if `touse'
			if `s(nh_res)' == 1 {
				di as error "The second argument must be a variable with integers, or an integer, or ."
				exit 198
			}
			
			if "`left'" == "." & "`right'" == "." {
				di as error "Either both arguments are . or you passed (0,.)"
				exit 198
			}
			
			// Alright, here we go. We need mu and alpha.
			tempvar mu alpha p PR
			_predict double `mu' if `touse', equation(#2)
			quiet replace `mu' = exp(`mu') if `touse'
			if "`e(selhet)'" != "" local eqn = 4
			else local eqn = 3
			_predict double `alpha' if `touse', equation(#`eqn')
			quiet replace `alpha' = -20 if `touse' & `alpha' < -20
			quiet replace `alpha' = exp(`alpha') if `touse'
			
			// probability of success for the nbinomial() functions.
			quiet generate double `p' = 1 / (1 + `alpha') if `touse'
			
			if "`left'" == "." {
				// Probability less or equal to.
				// Check right is nonnegative.
				tempvar check
				quiet generate byte `check' = (`right' < 0) if `touse'
				quiet summarize `check' if `touse', mean
				if r(sum) > 0 {
					di as error "Second argument cannot be negative"
					exit 198
				}
				quiet replace `check' = missing(`right') if `touse'
				quiet summarize `check' if `touse', mean
				if r(sum) > 0 {
					di as error "Second argument cannot have missing values"
					exit 198
				}
				drop `check'
				
				quiet generate double `PR' = nbinomial(`mu' / `alpha', `right',	///
					`p') if `touse'
				quiet generate `vtyp' `varn' = `PR' if `touse'
				label var `varn' "Prob. latent variable: P(`e(depvar)'*<=`right'|x)"
				exit
			}
			
			// Greater or equal than
			if "`right'" == "." {
				// check left is positive and not missing
				tempvar check
				quiet generate byte `check' = (`left' < 0) if `touse'
				quiet summarize `check' if `touse', mean
				if r(sum) > 0 {
					di as error "The first argument cannot be negative"
					exit 198
				}
				quiet replace `check' = missing(`left') if `touse'
				quiet summarize `check' if `touse', mean
				if r(sum) > 0 {
					di as error "The first argument cannot have missing values"
					exit 198
				}
				drop `check'
				
				quiet generate double `PR' = nbinomialtail(`mu' / `alpha',		///
					`left', `p') if `touse'
				quiet generate `vtyp' `varn' = `PR' if `touse'
				label var `varn' "Prob. latent variable: P(`e(depvar)'*>=`left'|x)"
				exit
			}
			
			// Ok so here probability of an interval.
			
			// check left is not negative, right is greater than left and neither
			// have missing values
			tempvar check
			
			quiet generate byte `check' = (`left' < 0) if `touse'
			quiet summarize `check' if `touse', mean
			if r(sum) > 0 {
				di as error "First argument cannot be negative"
				exit 198
			}
			
			quiet replace `check' = (`right'<=`left') if `touse'
			quiet summarize `check' if `touse', mean
			if r(sum) > 0 {
				di as error "Second argument has to be greater than the first"
				exit 198
			}
			
			quiet replace `check' = missing(`left',`right') if `touse'
			quiet summarize `check' if `touse', mean
			if r(sum) > 0 {
				di as error "Neither argument can have missing values"
				exit 198
			}
			
			// If left > 0 , we do the difference in cumulative probabilities.
			// If left == 0 it is less than right. So I generate the variable
			// with the negbinomial() for the right value, and then will
			// change it for the cases where left > 0.
			quiet generate double `PR' = nbinomial(`mu' / `alpha', `right',		///
				`p') if `touse'
			quiet replace `PR' = `PR' - nbinomial(`mu' / `alpha', `left' - 1,	///
				`p') if `touse' & `left' > 0
			quiet generate `vtyp' `varn' = `PR' if `touse'
			label var `varn' "Prob. latent variable: P(`left'<=`e(depvar)'*<=`right'|x)"
			exit
		}
		
		// Single value
		// Check prstar is variable or number
		nehurdle_parse_probopts `prstar' if `touse'
		if `s(nh_res)' == 1 {
			di as error "The argument must be a variable with integers, or an integer value"
			exit 198
		}
		else if "`prstar'" == "." {
			di as error "The argument cannot be ."
			exit 198
		}
		
		// Check if the values are less than 0 or missing
		tempvar check
		quiet generate `check' = (`prstar' < 0) if `touse'
		quiet summarize `check' if `touse', mean
		if r(sum) > 0 {
			di as error "The argument cannot be less than 1"
			exit 198
		}
		quiet replace `check' = missing(`prstar') if `touse'
		quiet summarize `check' if `touse', mean
		if r(sum) > 0 {
			di as error "The argument cannot have missing values"
			exit 198
		}
		drop `check'
		
		// Alright, here we go. We need mu and alpha.
		tempvar mu alpha p PR
		_predict double `mu' if `touse', equation(#2)
		quiet replace `mu' = exp(`mu') if `touse'
		if "`e(selhet)'" != "" local eqn = 4
		else local eqn = 3
		_predict double `alpha' if `touse', equation(#`eqn')
		quiet replace `alpha' = -20 if `touse' & `alpha' < -20
		quiet replace `alpha' = exp(`alpha') if `touse'
		
		// Probability of success
		quiet generate double `p' = 1 / (1 + `alpha') if `touse'
		
		quiet generate double `PR' = nbinomialp(`mu' / `alpha', `prstar', `p')	///
			if `touse'
		quiet generate `vtyp' `varn' = `PR' if `touse'
		label var `varn' "Prob. latent variable: P(`e(depvar)'*=`prstar'|x)"
		exit
	}
	
	if "`xbval'" != "" {
		_predict `vtyp' `varn' if `touse', equation(#2)
		label var `varn' "`e(depvar)' equation fitted values (xb)"
		exit
	}
	
	if "`xbsel'" != "" {
		_predict `vtyp' `varn' if `touse', equation(#1)
		label var `varn' "Selection equation fitted values (xb)"
		exit
	}
	
	if "`xbselsig'" != "" {
		if "`e(selhet)'" == "" {
			di as error "{bf:xbselsig} not valid"
			exit 198
		}
		_predict `vtyp' `varn' if `touse', equation(#3)
		label var `varn' "Selection ln std. dev. fitted values (xb)"
		exit
	}
	
	if "`selsigma'" != "" {
		if "`e(selhet)'" == "" {
			di as error "{bf: selsigma} not valid"
			exit 198
		}
		tempvar sig
		_predict double `sig' if `touse', equation(#3)
		quiet replace `sig' = exp(`sig') if `touse'
		quiet generate `vtyp' `varn' = `sig' if `touse'
		label var `varn' "Std. dev. selection equation: exp(sellnsigma)"
		exit
	}
	
	if "`xbalpha'" != "" {
		if "`e(selhet)'" != "" local eqn = 4
		else local eqn = 3
		_predict `vtyp' `varn' if `touse', equation(#`eqn')
		label var `varn' "Dispersion fitted values: ln(alpha)"
		exit
	}
	
	if "`alpha'" != "" {
		if "`e(selhet)'" != "" local eqn = 4
		else local eqn = 3
		tempvar alpha
		_predict double `alpha' if `touse', equation(#`eqn')
		quiet replace `alpha' = -20 if `touse' & `alpha' < -20
		quiet replace `alpha' = exp(`alpha') if `touse'
		quiet generate `vtyp' `varn' = `alpha' if `touse'
		label var `varn' "Predicted dispersion parameter: alpha"
		exit
	}
	
	if "`psel'" != "" {
		tempvar phiz selsig
		_predict double `phiz' if `touse', equation(#1)
		if "`e(selhet)'" != "" {
			_predict double `selsig' if `touse', equation(#3)
			quiet replace `selsig' = exp(`selsig') if `touse'
		}
		else quiet generate double `selsig' = 1 if `touse'
		quiet replace `phiz' = normal(`phiz' / `selsig') if `touse'
		quiet generate `vtyp' `varn' = `phiz' if `touse'
		label var `varn' "Prob. selection: Pr(`e(depvar)' > 0|z)"
		exit
	}
	
	if "`ressel'" != "" {
		tempvar phiz selsig dy
		quiet generate double `dy' = `e(depvar)' > 0 if `touse'
		_predict double `phiz' if `touse', equation(#1)
		if "`e(selhet)'" != "" {
			_predict double `selsig' if `touse', equation(#3)
			quiet replace `selsig' = exp(`selsig') if `touse'
		}
		else quiet generate double `selsig' = 1 if `touse'
		quiet replace `phiz' = `dy' - normal(`phiz' / `selsig') if `touse'
		quiet generate `vtyp' `varn' = `phiz' if `touse'
		label var `varn' "Prob. participation residuals: I(`e(depvar)' > 0) -  Pr(`e(depvar)' > 0|z)"
		exit
	}
	
	// Ycen is de default, so if we're here that is what we predict.
	if "`ycen'" == "" noi di as txt "(option ycen assumed)"
	tempvar mu phiz selsig alpha
	_predict double `phiz' if `touse', equation(#1)
	_predict double `mu' if `touse', equation(#2)
	quiet replace `mu' = exp(`mu') if `touse'
	if "`e(selhet)'" != "" {
		_predict double `selsig' if `touse', equation(#3)
		quiet replace `selsig' = exp(`selsig') if `touse'
		_predict double `alpha' if `touse', equation(#4)
	}
	else {
		quiet generate double `selsig' = 1 if `touse'
		_predict double `alpha' if `touse', equation(#3)
	}
	quiet replace `alpha' = -20 if `touse' & `alpha' < -20
	quiet replace `alpha' = exp(`alpha') if `touse'
	quiet replace `mu' = normal(`phiz' / `selsig') * `mu' / (1 - (1 +			///
		`alpha')^(- `mu' / `alpha')) if `touse'
	quiet generate `vtyp' `varn' = `mu' if `touse'
	label var `varn' "Observed variable mean: E(`e(depvar)'|x,z)"
end


// NEGATIVE BINOMIAL II
capture program drop nehurdle_truncnb2_p
program define nehurdle_truncnb2_p, eclass
	syntax anything(id="newvarname") [if] [in]									///
	[, {																		///
		YCen			|														///
		RESCen			|														///
		VCen			|														///
		SIGCen			|														///
		PRCen(string)	|														///
		YTrun			|														///
		RESTrun			|														///
		VTrun			|														///
		SIGTrun			|														///
		PRTrun(string)	|														///
		YStar			|														///
		RESStar			|														///
		VStar			|														///
		SIGStar			|														///
		PRStar(string)	|														///
		XB				|														///
		XBVal			|														///
		XBSel			|														///
		XBSELSig		|														///
		XBAlpha			|														///
		SELSIGma		|														///
		ALPha			|														///
		PSel			|														///
		RESSEL			|														///
		SCores																	///
	} * ]
	
	if "`scores'" != "" {
		local bvar "`e(depvar)'"
		tempvar dy y1
		quiet generate byte `dy' = `bvar' > 0
		quiet generate double `y1' = `bvar'
		ereturn local depvar "`dy' `y1'"
		
		marksample touse
		marksample touse2
		local xvars : colna e(b)
		local cons _cons _cons _cons
		local xvars : list xvars - cons
		
		markout `touse2' `xvars'
		quiet replace `touse' = 0 if `dy' & !`touse2'
		ml score `anything' if `touse', `scores' missing `options'
		ereturn local depvar "`bvar'"
		exit
	}
	
	local myopts "YCen RESCen VCen SIGCen PRCen(string) YTrun RESTrun VTrun"
	local myopts "`myopts' SIGTrun PRTrun(string) YStar RESStar VStar SIGStar"
	local myopts "`myopts' PRStar(string) XB XBVal PSel RESSEL XBSel SELSIGma"
	local myopts "`myopts' XBSELSig XBAlpha ALPha"
	_pred_se "`myopts'" `0'
	if `s(done)' exit
	local vtyp  `s(typ)'
	local varn `s(varn)'
	local 0 `"`s(rest)'"'
	
	// marking sample
	marksample touse
	
	
	// Have to capture xb to notify it is not vaid.
	if "`xb'" != "" {
		di as error "option {bf:xb} not valid"
		di as error "Try one of the following:"
		di as error _col(6) "1. {bf:xbval} for fitted values of the value equation."
		di as error _col(6) "2. {bf:xbsel} for fitted values of the selection equation."
		if "`e(selhet)'" != "" {
			di as error _col(6) "3. {bf:xbselsig} for fitted values of the selection ln sigma."
			di as error _col(6) "4. {bf:xbalpha} for fitted values of the ln of dispersion"
		}
		else																	///
			di as error _col(6) "3. {bf:xbalpha} for fitted values of the ln of dispersion"
		exit 198
	}
	
	// Censored (observed) variable.
	// ycen is the default so I do that at the end.
	if "`rescen'" != "" {
		tempvar mu zg selsig alpha
		_predict double `zg' if `touse', equation(#1)
		_predict double `mu' if `touse', equation(#2)
		quiet replace `mu' = exp(`mu') if `touse'
		if "`e(selhet)'" != "" {
			_predict double `selsig' if `touse', equation(#3)
			quiet replace `selsig' = exp(`selsig') if `touse'
			_predict double `alpha' if `touse', equation(#4)
		}
		else {
			quiet generate double `selsig' = 1 if `touse'
			_predict double `alpha' if `touse', equation(#3)
		}
		quiet replace `alpha' = -20 if `touse' & `alpha' < -20
		quiet replace `alpha' = exp(`alpha') if `touse'
		quiet replace `mu' = normal(`zg' / `selsig') * `mu' / (1 -	///
			(1 / (1 + `alpha' * `mu'))^(1 / `alpha')) if `touse'
		quiet replace `mu' = `e(depvar)' - `mu' if `touse'
		quiet generate `vtyp' `varn' = `mu' if `touse'
		label var `varn' "Observed variable residuals: `e(depvar)' - E(`e(depvar)'|x,z)"
		exit
	}
	
	if "`vcen'" != "" {
		tempvar phiz selsig alpha mu var
		_predict double `phiz' if `touse', equation(#1)
		_predict double `mu' if `touse', equation(#2)
		quiet replace `mu' = exp(`mu') if `touse'
		if "`e(selhet)'" != "" {
			_predict double `selsig' if `touse', equation(#3)
			quiet replace `selsig' = exp(`selsig') if `touse'
			_predict double `alpha' if `touse', equation(#4)
		}
		else {
			quiet generate double `selsig' = 1 if `touse'
			_predict double `alpha' if `touse', equation(#3)
		}
		quiet replace `alpha' = -20 if `touse' & `alpha' < -20
		quiet replace `alpha' = exp(`alpha') if `touse'
		quiet replace `phiz' = normal(`phiz' / `selsig') if `touse'
		
		// Alright, now we form the variance.
		quiet generate double `var' = `phiz' * `mu' * (1 + `alpha' * `mu' +	///
			`mu') / (1 - (1 / (1 + `alpha' * `mu'))^(1 / `alpha')) -			///
			`phiz'^2 * `mu'^2 / ((1 - (1 / (1 + `alpha' *						///
			`mu'))^(1 / `alpha'))^2) if `touse'
		quiet generate `vtyp' `varn' = `var' if `touse'
		label var `varn' "Observed variable variance: V(`e(depvar)'|x,z)"
		exit
	}
	
	if "`sigcen'" != "" {
		tempvar phiz selsig alpha mu var
		_predict double `phiz' if `touse', equation(#1)
		_predict double `mu' if `touse', equation(#2)
		quiet replace `mu' = exp(`mu') if `touse'
		if "`e(selhet)'" != "" {
			_predict double `selsig' if `touse', equation(#3)
			quiet replace `selsig' = exp(`selsig') if `touse'
			_predict double `alpha' if `touse', equation(#4)
		}
		else {
			quiet generate double `selsig' = 1 if `touse'
			_predict double `alpha' if `touse', equation(#3)
		}
		quiet replace `alpha' = -20 if `touse' & `alpha' < -20
		quiet replace `alpha' = exp(`alpha') if `touse'
		quiet replace `phiz' = normal(`phiz' / `selsig') if `touse'
		
		// Alright, now we form the variance.
		quiet generate double `var' = `phiz' * `mu' * (1 + `alpha' * `mu' +	///
			`mu') / (1 - (1 / (1 + `alpha' * `mu'))^(1 / `alpha')) -			///
			`phiz'^2 * `mu'^2 / ((1 - (1 / (1 + `alpha' *						///
			`mu'))^(1 / `alpha'))^2) if `touse'
		quiet replace `var' = sqrt(`var') if `touse'
		quiet generate `vtyp' `varn' = `var' if `touse'
		label var `varn' "Observed variable std. dev.: sd(`e(depvar)'|x,z)"
		exit
	}
	
	// Probability of the censored variable
	if "`prcen'" != "" {
		// First thing we check whether the position of a comma in the string
		local cpos = strpos("`prcen'", ",")
		if `cpos' > 0 {
			// Probability of the censored variable falling between two values.
			local left = substr("`prcen'",1,`cpos' - 1)
			local right = substr("`prcen'", `cpos' + 1, .)
			
			// If the user passed too many arguments there will be commas in
			// the right, not in the left bc strpos returns the position of the
			// first occurrance.
			local cpos = strpos("`right'", ",")
			if `cpos' > 0 {
				di as error "Too many arguments"
				exit 198
			}
			
			// Alright, now we have to check that the arguments are either
			// numbers or variables. Left.
			nehurdle_parse_probopts `left' if `touse'
			if `s(nh_res)' == 1 {
				di as error "The second argument must be a variable, or an integer, or ."
				exit 198
			}
			
			// Now right.
			nehurdle_parse_probopts `right' if `touse'
			if `s(nh_res)' == 1 {
				di as error "The second argument must be a variable, or an integer, or ."
				exit 198
			}
			
			if "`left'" == "." & "`right'" == "." {
				di as error "Both arguments cannot be ., or you have pased 0,."
				exit 198
			}
			
			tempvar phiz selsig alpha mu p pg0 PR
			// Model calculations
			_predict double `phiz' if `touse', equation(#1)
			_predict double `mu' if `touse', equation(#2)
			quiet replace `mu' = exp(`mu') if `touse'
			if "`e(selhet)'" != "" {
				_predict double `selsig' if `touse', equation(#3)
				quiet replace `selsig' = exp(`selsig') if `touse'
				_predict double `alpha' if `touse', equation(#4)
			}
			else {
				quiet generate double `selsig' = 1 if `touse'
				_predict double `alpha' if `touse', equation(#3)
			}
			quiet replace `alpha' = -20 if `touse' & `alpha' < -20
			quiet replace `alpha' = exp(`alpha') if `touse'
			quiet replace `phiz' = normal(`phiz' / `selsig') if `touse'
			
			// p to use with nbinomial functions
			quiet generate double `p' = 1 / (1 + `alpha' * `mu') if `touse'
			// truncating probability
			quiet generate double `pg0' = nbinomialtail(1 / `alpha', 1, `p') if	///
				`touse'
			
			if "`left'" == "." {
				// Prob. less than. Have to check that right is not negative and not missing.
				tempvar check
				quiet generate byte `check' = (`right' < 0) if `touse'
				quiet summarize `check' if `touse', mean
				if r(sum) > 0 {
					di as error "The second argument cannot be negative"
					exit 198
				}
				quiet replace `check' = missing(`right') if `touse'
				quiet summarize `check' if `touse', mean
				if r(sum) > 0 {
					di as error "The second argument cannot have missing values"
					exit 198
				}
				
				quiet generate double `PR' = 1 + `phiz' * (nbinomial(1 /		///
					`alpha', `right', `p') - 1) / `pg0' if `touse'
				quiet generate `vtyp' `varn' = `PR' if `touse'
				label var `varn' "Prob. observed variable: P(`e(depvar)'<=`right'|x,z)"
				exit
			}
			
			if "`right'" == "." {
				// Probability greater or equal to left.
				
				// Check left is nonnegative and not missing.  If it were 0 we would
				// have that the probability is 1, so we have to replace those.
				tempvar check
				quiet generate byte `check' = (`left' < 0) if `touse'
				quiet summarize `check' if `touse', mean
				if r(sum) > 0 {
					di as error "The first argument cannot be negative"
					exit 198
				}
				quiet replace `check' = missing(`left') if `touse'
				quiet summarize `check' if `touse', mean
				if r(sum) > 0 {
					di as error "The first argument cannot have missing values"
					exit 198
				}
				drop `check'
				
				quiet generate double `PR' = `phiz' * nbinomialtail(1 /			///
					`alpha', `left', `p') / `pg0' if `touse'
				quiet replace `PR' = 1 if `touse' & `left' == 0
				quiet generate `vtyp' `varn' = `PR' if `touse'
				label var `varn' "Prob. observed variable: P(`e(depvar)'>=`left'|x,z)"
				exit
			}
			// Probability of in between.
			
			// have to check left is non-negative, right is greater than left and
			// neither is missing.
			tempvar check
			quiet generate byte `check' = (`left' < 0) if `touse'
			quiet summarize `check' if `touse', mean
			if r(sum) > 0 {
				di as error "The first argument cannot have negative values"
				exit 198
			}
			quiet replace `check' = (`right'<=`left') if `touse'
			quiet summarize `check' if `touse', mean
			if r(sum) > 0 {
				di as error "The second argument has to be always greater than the first"
				exit 198
			}
			quiet replace `check' = missing(`left',`right') if `touse'
			quiet summarize `check' if `touse', mean
			if r(sum) > 0 {
				di as error "Neither argument can have missing values"
				exit 198
			}
			
			// If left = 0 , this is the same as y <= right.
			quiet generate double `PR' = 1 + `phiz' * (nbinomial(1 / `alpha',	///
				`right', `p') - 1) / `pg0' if `touse' & `left' == 0
			// If left > 0 we apply the formula for the interval
			quiet replace `PR' = `phiz' * (nbinomial(1 / `alpha', `right', `p')	///
				- nbinomial(1 / `alpha', `left' - 1, `p')) / `pg0' if `touse'	///
				& `left' > 0
			quiet generate `vtyp' `varn' = `PR' if `touse'
			label var `varn' "Prob. observed variable: P(`left'<=`e(depvar)'<=`right'|x,z)"
			exit
		}
		
		// Probability of the censored variable equaling one value.
		
		// Check prcen is variable or number
		nehurdle_parse_probopts `prcen' if `touse'
		if `s(nh_res)' == 1 {
			di as error "The argument must be a variable, or an integer"
			exit 198
		}
		else if "`prcen'" == "." {
			di as error "The argument cannot be ."
			exit 198
		}
		
		// Finally check if the values are less than zero or missing.
		tempvar check
		quiet generate `check' = (`prcen' < 0) if `touse'
		quiet summarize `check' if `touse', mean
		if r(sum) > 0 {
			di as error "The argument cannot have negative values"
			exit 198
		}
		quiet replace `check' = missing(`prcen') if `touse'
		quiet summarize `check' if `touse', mean
		if r(sum) > 0 {
			di as error "The argument cannot have missing values"
			exit 198
		}
		drop `check'
		
		// Let's get what we need
		tempvar phiz nphiz selsig alpha mu p pg0 PR
		// Model calculations
		_predict double `phiz' if `touse', equation(#1)
		_predict double `mu' if `touse', equation(#2)
		quiet replace `mu' = exp(`mu') if `touse'
		if "`e(selhet)'" != "" {
			_predict double `selsig' if `touse', equation(#3)
			quiet replace `selsig' = exp(`selsig') if `touse'
			_predict double `alpha' if `touse', equation(#4)
		}
		else {
			quiet generate double `selsig' = 1 if `touse'
			_predict double `alpha' if `touse', equation(#3)
		}
		quiet replace `alpha' = -20 if `touse' & `alpha' < -20
		quiet replace `alpha' = exp(`alpha') if `touse'
		quiet generate double `nphiz' = normal(- `phiz' / `selsig') if `touse'
		quiet replace `phiz' = normal(`phiz' / `selsig') if `touse'
		
		// p to use with nbinomial functions
		quiet generate double `p' = 1 / (1 + `alpha' * `mu') if `touse'
		// truncating probability
		quiet generate double `pg0' = nbinomialtail(1 / `alpha', 1, `p') if	///
			`touse'
		
		// Ok if prcen = 0 we want 1 - phiz (nphiz), but if not, we want
		// phiz times the truncated probability.
		quiet generate double `PR' = `nphiz' if `touse' & `prcen' == 0
		quiet replace `PR' = `phiz' * nbinomialp(1 / `alpha', `prcen', `p') /	///
			`pg0' if `touse' & `prcen' > 0
		quiet generate `vtyp' `varn' = `PR' if `touse'
		label var `varn' "Prob. observed value: P(`e(depvar)'=`prcen'|x,z)"
		exit
	}
	
	if "`ytrun'" != "" {
		tempvar alpha mu
		_predict double `mu' if `touse', equation(#2)
		quiet replace `mu' = exp(`mu') if `touse'
		if "`e(selhet)'" != "" local eqn = 4
		else local eqn = 3
		_predict double `alpha' if `touse', equation(#`eqn')
		quiet replace `alpha' = -20 if `touse' & `alpha' < -20
		quiet replace `alpha' = exp(`alpha') if `touse'
		
		quiet replace `mu' = `mu' / (1 - (1 / (1 + `alpha' *				///
			`mu'))^(1 / `alpha')) if `touse'
		quiet generate `vtyp' `varn' = `mu' if `touse'
		label var `varn' "Trunctated variable mean: E(`e(depvar)'*|x,`e(depvar)'*>0)"
		exit
	}
	
	if "`restrun'" != "" {
		tempvar alpha mu
		_predict double `mu' if `touse', equation(#2)
		quiet replace `mu' = exp(`mu') if `touse'
		if "`e(selhet)'" != "" local eqn = 4
		else local eqn = 3
		_predict double `alpha' if `touse', equation(#`eqn')
		quiet replace `alpha' = -20 if `touse' & `alpha' < -20
		quiet replace `alpha' = exp(`alpha') if `touse'
		
		quiet replace `mu' = `mu' / (1 - (1 / (1 + `alpha' *				///
			`mu'))^(1 / `alpha')) if `touse'
		quiet replace `mu' = `e(depvar)' - `mu' if `touse'
		quiet generate `vtyp' `varn' = `mu' if `touse'
		label var `varn' "Truncated variable resisduals: `e(depvar)'*|`e(depvar)'*>0"
		exit
	}
	
	if "`vtrun'" != "" {
		tempvar alpha mu var
		_predict double `mu' if `touse', equation(#2)
		quiet replace `mu' = exp(`mu') if `touse'
		if "`e(selhet)'" != "" local eqn = 4
		else local eqn = 3
		_predict double `alpha' if `touse', equation(#`eqn')
		quiet replace `alpha' = -20 if `touse' & `alpha' < -20
		quiet replace `alpha' = exp(`alpha') if `touse'
		
		quiet generate double `var' = `mu' * (`alpha' * `mu' + `mu' + 1) /		///
			(1 - (1 / (1 + `alpha' *	`mu'))^(1 / `alpha')) - `mu'^2 / (((1 -	///
			(1 / (1 + `alpha' * `mu'))^(1 / `alpha')))^2) if `touse'
		quiet generate `vtyp' `varn' = `var' if `touse'
		label var `varn' "Truncated variable variance: V(`e(depvar)'*|x,`e(depvar)'*>0)"
		exit
	}
	
	if "`sigtrun'" != "" {
		tempvar alpha mu var
		_predict double `mu' if `touse', equation(#2)
		quiet replace `mu' = exp(`mu') if `touse'
		if "`e(selhet)'" != "" local eqn = 4
		else local eqn = 3
		_predict double `alpha' if `touse', equation(#`eqn')
		quiet replace `alpha' = -20 if `touse' & `alpha' < -20
		quiet replace `alpha' = exp(`alpha') if `touse'
		
		quiet generate double `var' = `mu' * (`alpha' * `mu' + `mu' + 1) /		///
			(1 - (1 / (1 + `alpha' *	`mu'))^(1 / `alpha')) - `mu'^2 / (((1 -	///
			(1 / (1 + `alpha' * `mu'))^(1 / `alpha')))^2) if `touse'
		quiet replace `var' = sqrt(`var') if `touse'
		quiet generate `vtyp' `varn' = `var' if `touse'
		label var `varn' "Truncated variable std. dev.: sd(`e(depvar)'*|x,`e(depvar)'*>0)"
		exit
	}
	
	if "`prtrun'" ! = "" {
		// Check for th position of a comma
		local cpos = strpos("`prtrun'", ",")
		if `cpos' > 0 {
			// Two arguments, theoretically, so cumulative probs.
			// Probability of the censored variable falling between two values.
			local left = substr("`prtrun'",1,`cpos' - 1)
			local right = substr("`prtrun'", `cpos' + 1, .)
			
			// If the user passed too many arguments there will be commas in
			// the right, not in the left bc strpos returns the position of the
			// first occurrance.
			local cpos = strpos("`right'", ",")
			if `cpos' > 0 {
				di as error "Too many arguments"
				exit 198
			}
			
			// Alright, now we have to check that the arguments are either
			// numbers or variables. Left.
			nehurdle_parse_probopts `left' if `touse'
			if `s(nh_res)' == 1 {
				di as error "The first argument must be a variable, or an integer, or ."
				exit 198
			}
			
			// Now right.
			nehurdle_parse_probopts `right' if `touse'
			if `s(nh_res)' == 1 {
				di as error "The second argument must be a variable, or an integer, or ."
				exit 198
			}
			
			// Need mu and alpha
			tempvar mu alpha p pg0 PR
			_predict double `mu' if `touse', equation(#2)
			quiet replace `mu' = exp(`mu') if `touse'
			if "`e(selhet)'" != "" local eqn = 4
			else local eqn = 3
			_predict double `alpha' if `touse', equation(#`eqn')
			quiet replace `alpha' = -20 if `touse' & `alpha' < -20
			quiet replace `alpha' = exp(`alpha') if `touse'
			
			// var to use with nbinomial(), nbinomialtail() and nbinomialp()
			quiet generate double `p' = 1 / (1 + `alpha' * `mu') if `touse'
			quiet generate double `pg0' = nbinomialtail(1 / `alpha', 1, `p') if	///
				`touse'
			
			if "`left'" == "." & "`right'" == "." {
				di as error "Both arguments cannot be ."
				exit
			}
			
			if "`left'" == "." {
				// Probability less or equal to right.
				// check right is greater than zero
				tempvar check
				quiet generate byte `check' = (`right' < 1) if `touse'
				quiet summarize `check' if `touse', mean
				if r(sum) > 0 {
					di as error "The second argument has to be positive"
					exit 198
				}
				drop `check'
				
				quiet generate double `PR' = (nbinomial(1 / `alpha', `right',	///
					`p') - nbinomialp(1 / `alpha', 0, `p')) / `pg0' if `touse'
				quiet generate `vtyp' `varn' = `PR' if `touse'
				label var `varn' "Prob. truncated variable: P(`e(depvar)'*<=`right'|x,`e(depvar)'*>0)"
				exit
			}
			
			if "`right'" == "." {
				// Probability greater or equal than
				// check left is greater than zero
				tempvar check
				quiet generate byte `check' = (`left' < 1) if `touse'
				quiet summarize `check' if `touse', mean
				if r(sum) > 0 {
					di as error "The first argument has to be positive"
					exit 198
				}
				drop `check'
				
				quiet generate double `PR' = nbinomialtail(1 / `alpha', `left',	///
					`p') / `pg0' if `touse'
				quiet generate `vtyp' `varn' = `PR' if `touse'
				label var `varn' "Prob. truncated variable: P(`e(depvar)'*>=`left'|x,`e(depvar)'*>0)"
				exit
			}
			
			// if we're here we have to do the probability that y falls in a range.
			// Need to check that right is greater than left, and that left is
			// greater than 0.
			tempvar check
			quiet generate byte `check' = (`right'<=`left') if `touse'
			quiet summarize `check' if `touse', mean
			if r(sum) > 0 {
				di as error "The second argument must be greater than the first"
				exit 198
			}
			quiet replace `check' = (`left' < 1) if `touse'
			quiet summarize `check' if `touse', mean
			if r(sum) > 0 {
				di as error "The first argument cannot be less than 1"
				exit 198
			}
			// Also need to check that neither is missing.
			quiet replace `check' = missing(`left', `right') if `touse'
			quiet summarize `check' if `touse', mean
			if r(sum) > 0 {
				di as error "Neither argument can be missing"
				exit 198
			}
			drop `check'
			
			// Since the minimum left value is 1 we don't have to worry about
			// zeroes in this case.
			quiet generate double `PR' = (nbinomial(1 / `alpha', `right', `p')	///
				- nbinomial(1 / `alpha', `left' - 1, `p')) / `pg0' if `touse'
			quiet generate `vtyp' `varn' = `PR' if `touse'
			label var `varn' "Prob. truncated variable: P(`left'<=`e(depvar)'*<=`right'|x, `e(depvar)'*>0)"
			exit
		}
		
		// single argument in prtrun
		
		// Check prtrun is variable or number
		nehurdle_parse_probopts `prtrun' if `touse'
		if `s(nh_res)' == 1 {
			di as error "The argument must be a variable with integers, or an integer value"
			exit 198
		}
		else if "`prtrun'" == "." {
			di as error "The argument cannot be ."
			exit 198
		}
		
		// Finally check if it has nonpositive values and/or missing.
		tempvar check
		quiet generate byte `check' = (`prtrun' < 1) if `touse'
		quiet summarize `check' if `touse', mean
		if r(sum) > 0 {
			di as error "The argument cannot be less than 1"
			exit 198
		}
		quiet replace `check' = missing(`prtrun') if `touse'
		quiet summarize `check' if `touse', mean
		if r(sum) > 0 {
			di as error "The argument cannot have missing values"
			exit 198
		}
		drop `check'
		
		// Need mu and alpha
		tempvar mu alpha p PR pg0
		_predict double `mu' if `touse', equation(#2)
		quiet replace `mu' = exp(`mu') if `touse'
		if "`e(selhet)'" != "" local eqn = 4
		else local eqn = 3
		_predict double `alpha' if `touse', equation(#`eqn')
		quiet replace `alpha' = -20 if `touse' & `alpha' < -20
		quiet replace `alpha' = exp(`alpha') if `touse'
		
		// var to use with nbinomial(), nbinomialtail() and nbinomialp()
		quiet generate double `p' = 1 / (1 + `alpha' * `mu') if `touse'
		quiet generate double `pg0' = nbinomialtail(1 / `alpha', 1, `p') if `touse'
		
		quiet generate double `PR' = nbinomialp(1 / `alpha', `prtrun', `p') /	///
			`pg0' if `touse'
		quiet generate `vtyp' `varn' = `PR' if `touse'
		label var `varn' "Prob. truncated variable: P(`e(depvar)'*=`prtrun'|x,`e(depvar)'*>0)"
		exit
	}
	
	if "`ystar'" != "" {
		tempvar mu
		_predict double `mu' if `touse', equation(#2)
		quiet replace `mu' = exp(`mu') if `touse'
		quiet generate `vtyp' `varn' = `mu' if `touse'
		label var `varn' "Latent variable mean: E(`e(depvar)'*|x)"
		exit
	}
	
	if "`resstar'" != "" {
		tempvar mu
		_predict double `mu' if `touse', equation(#2)
		quiet replace `mu' = exp(`mu') if `touse'
		quiet generate `vtyp' `varn' = `e(depvar)' - `mu' if `touse'
		label var `varn' "Latent variable residuals: `e(depvar)' - E(`e(depvar)'*|x)"
		exit
	}
	
	if "`vstar'" != "" {
		tempvar alpha mu var
		_predict double `mu' if `touse', equation(#2)
		quiet replace `mu' = exp(`mu') if `touse'
		if "`e(selhet)'" != "" local eqn = 4
		else local eqn = 3
		_predict double `alpha' if `touse', equation(#`eqn')
		quiet replace `alpha' = -20 if `touse' & `alpha' < -20
		quiet replace `alpha' = exp(`alpha') if `touse'
		quiet generate double `var' = `mu' * (1 + `alpha' * `mu') if `touse'
		quiet generate `vtyp' `varn' = `var' if `touse'
		label var `varn' "Latent variable variance: V(`e(depvar)'*|x)"
		exit
	}
	
	if "`sigstar'" != "" {
		tempvar alpha mu var
		_predict double `mu' if `touse', equation(#2)
		quiet replace `mu' = exp(`mu') if `touse'
		if "`e(selhet)'" != "" local eqn = 4
		else local eqn = 3
		_predict double `alpha' if `touse', equation(#`eqn')
		quiet replace `alpha' = -20 if `touse' & `alpha' < -20
		quiet replace `alpha' = exp(`alpha') if `touse'
		quiet generate double `var' = sqrt(`mu' * (1 + `alpha' * `mu'))			///
			if `touse'
		quiet generate `vtyp' `varn' = `var' if `touse'
		label var `varn' "Latent variable std. dev.: sd(`e(depvar)'*|x)"
		exit
	}
	
	if "`prstar'" != "" {
		// Check for th position of a comma
		local cpos = strpos("`prstar'", ",")
		if `cpos' > 0 {
			// Two arguments, theoretically, so cumulative probs.
			// Probability of the censored variable falling between two values.
			local left = substr("`prstar'",1,`cpos' - 1)
			local right = substr("`prstar'", `cpos' + 1, .)
			
			// If the user passed too many arguments there will be commas in
			// the right, not in the left bc strpos returns the position of the
			// first occurrance.
			local cpos = strpos("`right'", ",")
			if `cpos' > 0 {
				di as error "Too many arguments"
				exit 198
			}
			
			// Alright, now we have to check that the arguments are either
			// numbers or variables. Left.
			nehurdle_parse_probopts `left' if `touse'
			if `s(nh_res)' == 1 {
				di as error "The first argument must be a variable with integers, or an integer, or ."
				exit 198
			}
			// else if "`left'" == "0" local left = .
			
			// Now right.
			nehurdle_parse_probopts `right' if `touse'
			if `s(nh_res)' == 1 {
				di as error "The second argument must be a variable with integers, or an integer, or ."
				exit 198
			}
			
			if "`left'" == "." & "`right'" == "." {
				di as error "Either both arguments are . or you passed (0,.)"
				exit 198
			}
			
			// Alright, here we go. We need mu and alpha.
			tempvar mu alpha p PR
			_predict double `mu' if `touse', equation(#2)
			quiet replace `mu' = exp(`mu') if `touse'
			if "`e(selhet)'" != "" local eqn = 4
			else local eqn = 3
			_predict double `alpha' if `touse', equation(#`eqn')
			quiet replace `alpha' = -20 if `touse' & `alpha' < -20
			quiet replace `alpha' = exp(`alpha') if `touse'
			
			// probability of success for the nbinomial() functions.
			quiet generate double `p' = (1 / (1 + `alpha' * `mu')) if `touse'
			
			if "`left'" == "." {
				// Probability less or equal to.
				// Check right is nonnegative.
				tempvar check
				quiet generate byte `check' = (`right' < 0) if `touse'
				quiet summarize `check' if `touse', mean
				if r(sum) > 0 {
					di as error "Second argument cannot be negative"
					exit 198
				}
				quiet replace `check' = missing(`right') if `touse'
				quiet summarize `check' if `touse', mean
				if r(sum) > 0 {
					di as error "Second argument cannot have missing values"
					exit 198
				}
				drop `check'
				
				quiet generate double `PR' = nbinomial(1 / `alpha', `right',	///
					`p') if `touse'
				quiet generate `vtyp' `varn' = `PR' if `touse'
				label var `varn' "Prob. latent variable: P(`e(depvar)'*<=`right'|x)"
				exit
			}
			
			// Greater or equal than
			if "`right'" == "." {
				// check left is positive and not missing
				tempvar check
				quiet generate byte `check' = (`left' < 0) if `touse'
				quiet summarize `check' if `touse', mean
				if r(sum) > 0 {
					di as error "The first argument cannot be negative"
					exit 198
				}
				quiet replace `check' = missing(`left') if `touse'
				quiet summarize `check' if `touse', mean
				if r(sum) > 0 {
					di as error "The first argument cannot have missing values"
					exit 198
				}
				drop `check'
				
				quiet generate double `PR' = nbinomialtail(1 / `alpha', `left',	///
					`p') if `touse'
				quiet generate `vtyp' `varn' = `PR' if `touse'
				label var `varn' "Prob. latent variable: P(`e(depvar)'*>=`left'|x)"
				exit
			}
			
			// Ok so here probability of an interval.
			
			// check left is not negative, right is greater than left and neither
			// have missing values
			tempvar check
			
			quiet generate byte `check' = (`left' < 0) if `touse'
			quiet summarize `check' if `touse', mean
			if r(sum) > 0 {
				di as error "First argument cannot be negative"
				exit 198
			}
			
			quiet replace `check' = (`right'<=`left') if `touse'
			quiet summarize `check' if `touse', mean
			if r(sum) > 0 {
				di as error "Second argument has to be greater than the first"
				exit 198
			}
			
			quiet replace `check' = missing(`left',`right') if `touse'
			quiet summarize `check' if `touse', mean
			if r(sum) > 0 {
				di as error "Neither argument can have missing values"
				exit 198
			}
			
			// If left > 0 , we do the difference in cumulative probabilities.
			// If left == 0 it is less than right. So I generate the variable
			// with the negbinomial() for the right value, and then will
			// change it for the cases where left > 0.
			quiet generate double `PR' = nbinomial(1 / `alpha', `right', `p')	///
				if `touse'
			quiet replace `PR' = `PR' - nbinomial(1 / `alpha', `left' - 1, `p')	///
				if `touse' & `left' > 0
			quiet generate `vtyp' `varn' = `PR' if `touse'
			label var `varn' "Prob. latent variable: P(`left'<=`e(depvar)'*<=`right'|x)"
			exit
		}
		
		// Single value
		// Check prstar is variable or number
		nehurdle_parse_probopts `prstar' if `touse'
		if `s(nh_res)' == 1 {
			di as error "The argument must be a variable with integers, or an integer value"
			exit 198
		}
		else if "`prstar'" == "." {
			di as error "The argument cannot be ."
			exit 198
		}
		
		// Check if the values are less than 0 or missing
		tempvar check
		quiet generate `check' = (`prstar' < 0) if `touse'
		quiet summarize `check' if `touse', mean
		if r(sum) > 0 {
			di as error "The argument cannot be less than 1"
			exit 198
		}
		quiet replace `check' = missing(`prstar') if `touse'
		quiet summarize `check' if `touse', mean
		if r(sum) > 0 {
			di as error "The argument cannot have missing values"
			exit 198
		}
		drop `check'
		
		// Alright, here we go. We need mu and alpha.
		tempvar mu alpha p PR
		_predict double `mu' if `touse', equation(#2)
		quiet replace `mu' = exp(`mu') if `touse'
		if "`e(selhet)'" != "" local eqn = 4
		else local eqn = 3
		_predict double `alpha' if `touse', equation(#`eqn')
		quiet replace `alpha' = -20 if `touse' & `alpha' < -20
		quiet replace `alpha' = exp(`alpha') if `touse'
		
		// Probability of success
		quiet generate double `p' = 1 / (1 + `alpha' * `mu') if `touse'
		
		quiet generate double `PR' = nbinomialp(1 / `alpha', `prstar', `p')		///
			if `touse'
		quiet generate `vtyp' `varn' = `PR' if `touse'
		label var `varn' "Prob. latent variable: P(`e(depvar)'*=`prstar'|x)"
		exit
	}
	
	if "`xbval'" != "" {
		_predict `vtyp' `varn' if `touse', equation(#2)
		label var `varn' "`e(depvar)' equation fitted values (xb)"
		exit
	}
	
	if "`xbsel'" != "" {
		_predict `vtyp' `varn' if `touse', equation(#1)
		label var `varn' "Selection equation fitted values (xb)"
		exit
	}
	
	if "`xbselsig'" != "" {
		if "`e(selhet)'" == "" {
			di as error "{bf:xbselsig} not valid"
			exit 198
		}
		_predict `vtyp' `varn' if `touse', equation(#3)
		label var `varn' "Selection ln std. dev. fitted values (xb)"
		exit
	}
	
	if "`selsigma'" != "" {
		if "`e(selhet)'" == "" {
			di as error "{bf: selsigma} not valid"
			exit 198
		}
		tempvar sig
		_predict double `sig' if `touse', equation(#3)
		quiet replace `sig' = exp(`sig') if `touse'
		quiet generate `vtyp' `varn' = `sig' if `touse'
		label var `varn' "Std. dev. selection equation: exp(sellnsigma)"
		exit
	}
	
	if "`xbalpha'" != "" {
		if "`e(selhet)'" != "" local eqn = 4
		else local eqn = 3
		_predict `vtyp' `varn' if `touse', equation(#`eqn')
		label var `varn' "Dispersion fitted values: ln(alpha)"
		exit
	}
	
	if "`alpha'" != "" {
		if "`e(selhet)'" != "" local eqn = 4
		else local eqn = 3
		tempvar alpha
		_predict double `alpha' if `touse', equation(#`eqn')
		quiet replace `alpha' = -20 if `touse' & `alpha' < -20
		quiet replace `alpha' = exp(`alpha') if `touse'
		quiet generate `vtyp' `varn' = `alpha' if `touse'
		label var `varn' "Predicted dispersion parameter: alpha"
		exit
	}
	
	if "`psel'" != "" {
		tempvar phiz selsig
		_predict double `phiz' if `touse', equation(#1)
		if "`e(selhet)'" != "" {
			_predict double `selsig' if `touse', equation(#3)
			quiet replace `selsig' = exp(`selsig') if `touse'
		}
		else quiet generate double `selsig' = 1 if `touse'
		quiet replace `phiz' = normal(`phiz' / `selsig') if `touse'
		quiet generate `vtyp' `varn' = `phiz' if `touse'
		label var `varn' "Prob. selection: Pr(`e(depvar)' > 0|z)"
		exit
	}
	
	if "`ressel'" != "" {
		tempvar phiz selsig dy
		quiet generate double `dy' = `e(depvar)' > 0 if `touse'
		_predict double `phiz' if `touse', equation(#1)
		if "`e(selhet)'" != "" {
			_predict double `selsig' if `touse', equation(#3)
			quiet replace `selsig' = exp(`selsig') if `touse'
		}
		else quiet generate double `selsig' = 1 if `touse'
		quiet replace `phiz' = `dy' - normal(`phiz' / `selsig') if `touse'
		quiet generate `vtyp' `varn' = `phiz' if `touse'
		label var `varn' "Prob. participation residuals: I(`e(depvar)' > 0) -  Pr(`e(depvar)' > 0|z)"
		exit
	}
	
	// Ycen is de default, so if we're here that is what we predict.
	if "`ycen'" == "" noi di as txt "(option ycen assumed)"
	tempvar mu phiz selsig alpha
	_predict double `phiz' if `touse', equation(#1)
	_predict double `mu' if `touse', equation(#2)
	quiet replace `mu' = exp(`mu') if `touse'
	if "`e(selhet)'" != "" {
		_predict double `selsig' if `touse', equation(#3)
		quiet replace `selsig' = exp(`selsig') if `touse'
		_predict double `alpha' if `touse', equation(#4)
	}
	else {
		quiet generate double `selsig' = 1 if `touse'
		_predict double `alpha' if `touse', equation(#3)
	}
	quiet replace `alpha' = -20 if `touse' & `alpha' < -20
	quiet replace `alpha' = exp(`alpha') if `touse'
	quiet replace `mu' = normal(`phiz' / `selsig') * `mu' / (1 - (1 / (1 +	///
		`alpha' * `mu'))^(1 / `alpha')) if `touse'
	quiet generate `vtyp' `varn' = `mu' if `touse'
	label var `varn' "Observed variable mean: E(`e(depvar)'|x,z)"
end
