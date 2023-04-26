*!version 1.0.0  3aug2020
program stepbic
					// parse syntax
	ParseSyntax `0'
	local always `r(always)'
	local controls `r(controls)'
	local cmd `r(cmd)'
	local model_opts `r(model_opts)'
	local depvar `r(depvar)'
	local speedup `r(speedup)'
					// compute
	Compute, always(`always')		///
		controls(`controls')		///
		cmd(`cmd')			///
		model_opts(`model_opts')	///
		depvar(`depvar')		///
		speedup(`speedup')
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
	syntax [, always(varlist numeric fv) nowarmstart]

	fvexpand `always'
	local always `r(varlist)'

	if (`"`warmstart'"' == "nowarmstart") {
		local speedup = 0
	}
	else {
		local speedup = 1
	}
					//  after colon
	local 0 `after'
	syntax anything(name=model) [if] [in] [fw iw] [, *] 

	gettoken cmd varlist: model

	local model_opts `if' `in' [`weight'`exp'] , `options'
	
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

	ret local always `always'
	ret local controls `controls'
	ret local cmd `cmd'
	ret local model_opts `model_opts'
	ret local depvar `depvar'
	ret local speedup `speedup'
end
						//---------------------------//
						//	compute
						//---------------------------//
program	Compute, rclass
	syntax, cmd(passthru)		///
		controls(string)	///
		depvar(passthru)	///
		speedup(passthru)	///
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
			included(`included') `model_opts' `from'
		local bic_next = r(bic_next)
		local var_next `r(var_next)'
		mat `b_from' = r(eb_next)

		if (`i' == 1) {
			local bic_best = `bic_next'
		}

		if (`bic_next' > `bic_best') {
			local cont = 0
		}
		else {
			local included `included' `var_next'
			local candi : list candi - var_next
			local bic_best = `bic_next'

			DisplayLog, var_next(`var_next') bic_best(`bic_best')

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

	ret local included `included'
	ret local excluded `candi'
	ret local always `always'
	ret scalar bic_best = `bic_best'

	FinalModel, `cmd' `depvar' included(`included') `model_opts'
end

						//---------------------------//
						//	 Get next
						//---------------------------//
program GetNext, rclass
	syntax	, cmd(string)		///
		depvar(string)		///
		[ candi(string)		///
		from(passthru)		///
		included(string) 	///
		model_opts(string)]
	
	local bic_min = .
	tempname eb
	
	foreach var of local candi {
		qui `cmd' `depvar' `included' `var' `model_opts' `from'

		GetBic
		local bic_tmp = `s(bic)'

		if (`bic_tmp' < `bic_min') {
			local bic_next = `bic_tmp'
			local bic_min = `bic_tmp'
			local var_next `var'
			mat `eb' = e(b)
		}
	}

	ret scalar bic_next = `bic_next'
	ret local var_next `var_next'
	ret matrix eb_next = `eb'
end
						//---------------------------//
						//	 Display log
						//---------------------------//
program DisplayLog
	syntax, var_next(string) 	///
		bic_best(string)	
	
	di as txt "BIC = " as res %9.4f `bic_best' 	///
		_column(20) as txt "Add " as res "`var_next'"
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
						//	get bic
						//---------------------------//
program GetBic, sclass
	if (`"`e(cmd)'"' == "regress") {
		local sse = e(rss)
		local df = colsof(e(b))

		qui count if e(sample)
		local n = r(N)

		local ll = -(`n'/2)*(ln(2*_pi/`n') + 1  + ln(`sse'))
		local bic = -2*`ll' + `df'*ln(`n')
	}
	else {
		estat ic
		local bic = r(S)[1, 6]
	}
	sret local bic = `bic'
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
