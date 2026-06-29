*! 1.0.0	Ariel Linden 27Jun2026

program define betark_p
	version 14.0
	if `"`e(cmd)'"' != "betark" {
		error 301
	}
	syntax newvarname [if] [in]	///
		[, CMean				///
		   CVARiance			///
		   xb					///
		   XBSCAle				///
		]

	marksample touse, novarlist

	local case : word count `cmean' `cvariance' `xb' `xbscale'
	if `case' > 1 {
		di as err "only one {it:statistic} may be specified"
		exit 498
	}
	if `case' == 0 {
		local cmean cmean
		di as txt "(option {bf:cmean} assumed)"
	}

	if `"`xb'"' != "" {
		_predict `typlist' `varlist' if `touse', xb equation(`e(depvar)')
		label var `varlist' "Linear prediction in `e(depvar)' equation (no AR adjustment)"
	}
	else if `"`xbscale'"' != "" {
		_predict `typlist' `varlist' if `touse', xb equation(scale)
		label var `varlist' "Linear prediction in scale equation"
	}
	else if `"`cmean'"' != "" {
		PredictCmean `typlist' `varlist', touse(`touse')
		label var `varlist' "Conditional (AR-adjusted, one-step-ahead) mean of `e(depvar)'"
	}
	else if `"`cvariance'"' != "" {
		PredictCvar `typlist' `varlist', touse(`touse')
		label var `varlist' "Conditional (AR-adjusted) variance of `e(depvar)'"
	}
end


// AR-adjusted in-sample one-step-ahead mean.
program define PredictCmean
	syntax newvarname [, touse(string)]
	local vtyp : copy local typlist
	local varn : copy local varlist
	local dv `"`e(depvar)'"'
	local p = e(p_lag)

	tempvar xb mu0 xi xicomplete
	quietly _predict double `xb' if `touse', xb equation(`dv')
	quietly gen double `mu0' = invlogit(`xb') if `touse'

	quietly gen double `xi' = 0 if `touse'
	quietly gen byte `xicomplete' = 1 if `touse'

	forvalues k = 1/`p' {
		tempvar lagy lagxb term
		quietly gen double `lagy'  = L`k'.`dv' if `touse'
		quietly gen double `lagxb' = L`k'.`xb' if `touse'
		quietly gen double `term'  = _b[ar:rho`k'] * (logit(`lagy') - `lagxb') if `touse'
		quietly replace `xi' = `xi' + `term' if `touse' & !missing(`term')
		quietly replace `xicomplete' = 0 if `touse' & missing(`term')
	}

	quietly gen `vtyp' `varn' = invlogit(`xb' + `xi') if `touse' & `xicomplete'
	quietly replace `varn' = `mu0' if `touse' & !`xicomplete'
end


program define PredictCvar
	syntax newvarname [, touse(string)]
	tempvar mu_p phi_p
	PredictCmean `typlist' `mu_p', touse(`touse')

	tempvar zb
	quietly _predict double `zb' if `touse', xb equation(scale)
	quietly gen double `phi_p' = exp(`zb') if `touse'

	quietly gen `typlist' `varlist' = `mu_p'*(1-`mu_p')/(1+`phi_p') if `touse'
end
