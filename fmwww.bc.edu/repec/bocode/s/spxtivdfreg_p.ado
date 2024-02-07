*! version 1.4.2  06feb2024
*! Sebastian Kripfganz, www.kripfganz.de
*! Vasilis Sarafidis, sites.google.com/view/vsarafidis

*==================================================*
***** predictions and residuals after spxtivdfreg *****

program define spxtivdfreg_p, sort
	version 13.0
	if "`e(cmd)'" != "spxtivdfreg" {
		error 301
	}
	if "`e(vcetype)'" == "Delta-method" {
		_predict `0'
		exit
	}
	syntax [anything] [if] [in] [, *]
	loc 0				`"`anything' `if' `in' ,"'
	loc option			`"`options'"'
	loc options			"RForm DIRECT INDIRECT NAive XB Residuals"
	_pred_se "`options'" `0'
	if `s(done)' {
		exit
	}
	loc vtype			"`s(typ)'"
	loc varn			"`s(varn)'"
	loc 0				`"`s(rest)' `option'"'
	syntax [if] [in] [, `options']
	marksample touse

	loc prediction		"`rform' `direct' `indirect' `naive' `xb' `residuals'"
	if `: word count `prediction'' > 1 {
		exit 198
	}
	loc prediction		: list retok prediction
	if "`prediction'" != "indirect" & "`prediction'" != "residuals" {
		tempname b b0 b1
		mat `b'				= e(b)
		cap mat `b1'		= `b'[1, "W:"]
		if _rc == 303 {									// linear prediction
			_predict `vtype' `varn' if `touse', xb
			exit
		}
		mata: st_numscalar("r(ismatrix)", findexternal("`e(spmat)'") != J(1, 1, NULL))
		if !r(ismatrix) {
			error 301
		}
		loc K				= colsof(`b')
		loc Ksp				= colsof(`b1')
		if `Ksp' < `K' {
			mat `b0'			= `b'[1, ":"]
		}
		loc depvar			"`e(depvar)'"
		loc spvars			: coln `b1'
		if "`prediction'" == "naive" | "`prediction'" == "xb" {		// naive prediction
			tempvar aux
			if "`prediction'" == "xb" & e(splag) {
				loc spvars			: list spvars - depvar
				if "`spvars'" != "" {
					mat `b1'			= `b1'[1, 2..`Ksp']
				}
				else {
					mat sco double `aux' = `b0' if `touse'
					gen `vtype' `varn' = `aux' if `touse'
					lab var `varn' "Linear prediction"
					exit
				}
			}
			foreach var in `spvars' {
				fvrevar `var'
				loc var				"`r(varlist)'"
				tempvar sp`var'
				qui gen double `sp`var'' = `var'
				loc spvarlist		"`spvarlist' `sp`var''"
			}
			sort `_dta[_TStvar]' `_dta[_TSpanel]'
			mata: spxtivdfreg_spgen("`spvarlist'", "`_dta[_TStvar]'", "", `e(spmat)')
			sort `_dta[_TSpanel]' `_dta[_TStvar]'
			mat coln `b1'		= `spvarlist'
			mat coleq `b1'		= ""
			if `Ksp' < `K' {
				mat `b'				= (`b0', `b1')
			}
			else {
				mat `b'				= `b1'
			}
			mat sco double `aux' = `b' if `touse'
			gen `vtype' `varn' = `aux' if `touse'
			if "`prediction'" == "naive" {
				lab var `varn' "Naive-form prediction"
			}
			else {
				lab var `varn' "Linear prediction"
			}
			exit
		}
		if "`prediction'" == "" {						// reduced-form prediction (default)
			di as txt "(option rform assumed)"
		}
		if !e(splag) {
			if "`prediction'" == "direct" {
				if `Ksp' < `K' {
					_predict `vtype' `varn' if `touse', xb eq(#1)
				}
				else {
					gen `vtype' `varn' = 0 if `touse'
					lab var `varn' "Prediction of direct mean"
				}
			}
			else {
				predict `vtype' `varn' if `touse', naive
				lab var `varn' "Reduced-form prediction"
			}
			exit
		}
		loc spvars			: list spvars - depvar
		if `Ksp' < `K' {
			loc indepvars		: coln `b0'
			foreach var in `indepvars' {
				if "`var'" == "_cons" {
					loc var				"`touse'"
				}
				else {
					fvrevar `var'
					loc var				"`r(varlist)'"
				}
				tempvar `var'
				qui gen double ``var'' = `var'
				loc indepvarlist	"`indepvarlist' ``var''"
			}
		}
		else if "`spvars'" == "" {
			gen `vtype' `varn' = 0 if `touse'
			if "`prediction'" == "direct" {
				lab var `varn' "Prediction of direct mean"
			}
			else {
				lab var `varn' "Reduced-form prediction"
			}
			exit
		}
		if "`spvars'" != "" {
			foreach var in `spvars' {
				fvrevar `var'
				loc var				"`r(varlist)'"
				tempvar sp`var'
				qui gen double `sp`var'' = `var'
				loc spvarlist		"`spvarlist' `sp`var''"
			}
		}
		tempname lambda
		mat `lambda'		= `b1'[1, 1]
		sort `_dta[_TStvar]' `_dta[_TSpanel]'
		if "`spvarlist'" != "" {
			mata: spxtivdfreg_spgen("`spvarlist'", "`_dta[_TStvar]'", "", `e(spmat)', "`lambda'", `= 2 + 2 * ("`prediction'" == "direct")')
		}
		if "`indepvarlist'" != "" {
			mata: spxtivdfreg_spgen("`indepvarlist'", "`_dta[_TStvar]'", "", `e(spmat)', "`lambda'", `= 1 + 2 * ("`prediction'" == "direct")')
		}
		sort `_dta[_TSpanel]' `_dta[_TStvar]'
		mat coleq `b1'		= ""
		if "`spvars'" != "" {
			if `Ksp' < `K' {
				mat `b'				= (`b0', `b1'[1, 2..`Ksp'])
			}
			else {
				mat `b'				= `b1'[1, 2..`Ksp']
			}
		}
		else {
			mat `b'				= `b0'
		}
		mat coln `b'		= `varlist' `spvarlist'
		tempvar aux
		mat sco double `aux' = `b' if `touse'
		gen `vtype' `varn' = `aux' if `touse'
		if "`prediction'" == "direct" {
			lab var `varn' "Prediction of direct mean"
		}
		else {
			lab var `varn' "Reduced-form prediction"
		}
		exit
	}
	else if "`prediction'" == "indirect" {				// prediction of indirect mean
		tempvar aux1 aux2
		qui predict double `aux1' if `touse', rform
		qui predict double `aux2' if `touse', direct
		gen `vtype' `varn' = `aux1' - `aux2' if `touse'
		lab var `varn' "Prediction of indirect means"
		exit
	}
	else if "`prediction'" == "residuals" {				// combined residual
		tempvar aux
		qui predict double `aux' if `touse', naive
		gen `vtype' `varn' = `e(depvar)' - `aux' if `touse'
		lab var `varn' "Residuals"
		exit
	}
	error 198
end
