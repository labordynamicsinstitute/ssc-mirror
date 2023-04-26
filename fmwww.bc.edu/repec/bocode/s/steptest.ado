*!version 1.0.0  26oct2020
/*
	syntax:
	
	steptest , [always(varlist) alpha(0.05) nowarmstart] : 
			{it:est_cmd} {it:depvar} {it:varlist}
			 [if] [in] [weight], [options]
*/
program steptest
					// parse syntax
	ParseSyntax `0'
	local always `r(always)'
	local controls `r(controls)'
	local cmd `r(cmd)'
	local model_opts `r(model_opts)'
	local depvar `r(depvar)'
	local speedup `r(speedup)'
	local alpha `r(alpha)'
	local px `r(px)'
					// compute
	Compute, always(`always')		///
		controls(`controls')		///
		cmd(`cmd')			///
		model_opts(`model_opts')	///
		depvar(`depvar')		///
		speedup(`speedup')		///
		alpha(`alpha')			///
		px(`px')
end

						//---------------------------// 
						//	Parse syntax	
						//---------------------------// 
program ParseSyntax, rclass

	_on_colon_parse `0'
	local before `s(before)'
	local after `s(after)'
					//  before colon 
	local 0 `before'
	syntax [, always(varlist numeric fv)	///
		alpha(real 0.05) 		///
		noBONferroni			///
		nowarmstart]

	fvexpand `always'
	local always `r(varlist)'

	if (`"`warmstart'"' == "nowarmstart") {
		local speedup = 0
	}
	else {
		local speedup = 1
	}

	if (`alpha' <= 0 | `alpha' > 1) {
		di as err "option {bf:alpha()} must be a "	///
			"positive number less than 1"
		exit 198
	}
					//  after colon
	local 0 `after'
	syntax anything(name=model) [if] [in] [fw iw] [, *] 

	gettoken cmd varlist: model

	local model_opts `if' `in' [`weight'`exp'] , `options' vce(robust)
	
	fvexpand `varlist'
	local allvars `r(varlist)'
	gettoken depvar allvars: allvars 

	// local in : list always in allvars

	// if (!`in') {
	// 	di as err "option {bf:always()} specifies variables not " ///
	// 		"in the model"
	// 	exit 198
	// }

	local controls : list allvars - always

	local px : list sizeof controls

	if (`"`bonferroni'"' == "nobonferroni") {
		local px = 1
	}

	ret local always `always'
	ret local controls `controls'
	ret local cmd `cmd'
	ret local model_opts `model_opts'
	ret local depvar `depvar'
	ret local speedup `speedup'
	ret local alpha	`alpha'
	ret local px `px'
end
						//---------------------------//
						//	compute
						//---------------------------//
program	Compute, rclass
	syntax, cmd(passthru)		///
		controls(string)	///
		depvar(passthru)	///
		speedup(passthru)	///
		alpha(passthru)		///
		px(passthru)		///
		[always(string)		///
		model_opts(passthru) ]
	
	local cont = 1
	local candi `controls'
	local i = 1
	local included `always'
	tempname b_from

	di
	while (`cont') {
		qui GetNext , `cmd' `depvar' candi(`candi') 	///
			included(`included') `model_opts' `from' ///
			`alpha' `px'

		local wt_next = r(wt_next)
		local var_next `r(var_next)'
		local cval = r(cval)
		local cval_lb `r(cval_lb)'
		mat `b_from' = r(eb_next)

		if (`"`var_next'"' == "") {
			local cont = 0
		}
		else {
			local included `included' `var_next'
			local candi : list candi - var_next

			DisplayLog, var_next(`var_next') 	///
				wt_next(`wt_next')		///
				cval_lb(`cval_lb')		///
				cval(`cval')

			if (`"`candi'"' == "") {
				local cont = 0
			}

			GetFrom, `cmd' `speedup' b_from(`b_from')
			local from `s(from)'
		}
		local i = `i' + 1
	}

	local included : list uniq included
	local cadi : list uniq candi

	FinalModel, `cmd' `depvar' included(`included') `model_opts'

	ret local included `included'
	ret local excluded `candi'
	ret local always `always'
	ret scalar cval = `cval'
end

						//---------------------------//
						//	 Get next
						//---------------------------//
program GetNext, rclass
	syntax	, cmd(string)		///
		depvar(string)		///
		alpha(string)		///
		px(string)		///
		[ candi(string)		///
		from(passthru)		///
		included(string) 	///
		model_opts(string)]
	
	tempname eb
	local wt_max = -1E+10
	
	foreach var of local candi {
		qui `cmd' `depvar' `included' `var' `model_opts' `from'

		test `var'
		local wt_tmp = r(chi2)
		if (`wt_tmp' == .) {
			local wt_tmp = r(F)
		}
		
		if (`"`cval'"' == "") {
			GetCval, alpha(`alpha') px(`px')
			local cval `s(cval)'
			local cval_lb `s(cval_lb)'
		}

		if (`wt_tmp' >= `cval' & `wt_tmp' >= `wt_max') {
			local wt_next = `wt_tmp'	
			local var_next `var'
			local wt_max = `wt_tmp'
			mat `eb' = e(b)
		}
	}

	if (`"`var_next'"' != "") {
		ret scalar wt_next = `wt_next'
		ret matrix eb_next = `eb'
	}

	ret local var_next `var_next'
	ret scalar cval  = `cval'
	ret local cval_lb `cval_lb'
end
						//---------------------------//
						//	 Display log
						//---------------------------//
program DisplayLog
	syntax, var_next(string) 	///
		wt_next(string)		///
		cval(string)		///
		cval_lb(string)
	
	di as txt "Wald test = " as res %9.4f `wt_next' 		///
		_column(25) as txt "`cval_lb'" as res %9.4f `cval' 	///
		_column(65) as txt "Add " as res "`var_next'"
end
						//---------------------------//
						//	 display
						//---------------------------//
program Display
	syntax , cmd(string)

	`cmd'
end

						//---------------------------//
						//	 Final model estimation
						//---------------------------//
program FinalModel
	syntax, cmd(string)		///
		depvar(string)		///
		[included(string)	///
		model_opts(string)]
	
	qui `cmd' `depvar' `included' `model_opts'

	Display, cmd(`cmd')
end
						//---------------------------//
						// get from options (warm start)
						//---------------------------//
program GetFrom, sclass
	syntax, cmd(string)	///
		speedup(string)	///
		b_from(string)
	
	if (`"`cmd'"' == "regress") {
		exit
		//NotReached
	}

	if (`speedup') {
		sret local from from(`b_from', skip)
	}
end
						//------------------------//
						// get critical value
						//------------------------//
program GetCval, sclass
	syntax, alpha(string)	///
		px(string)

	if (r(chi2) != .) {
		local cval = invchi2tail(1, `alpha'/`px')
		local cval_lb `"invchi2(1, 1-`alpha'/`px') ="' 
	}
	else if (r(F) != .) {
		local cval = invFtail(1, r(df_r), `alpha'/`px')
		local df_r = r(df_r)
		local cval_lb `"invF(1, `df_r', 1-`alpha'/`px') ="' 
	}

	if (`"`e(cmd)'"' == "regress" & r(F) == . ) {
		local cval = .
		local df_r = r(df_r)
		local cval_lb `"invF(1, `df_r', 1-`alpha'/`px') ="' 
	}
	else if (`"`e(cmd)'"' != "regress" & r(chi2) == .) {
		local cval = .
		local cval_lb `"invchi2(1, 1-`alpha'/`px') ="' 
	}

	sret local cval `cval'
	sret local cval_lb `cval_lb'
end
