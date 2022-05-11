*! version 1.2.1  09apr2022
*! Sebastian Kripfganz, www.kripfganz.de

*==================================================*
***** predictions and residuals after xtdpdbc *****

program define xtdpdbc_p, sort
	version 12.1
	syntax [anything] [if] [in] [, SCores *]

	if "`scores'" == "" {
		loc scores			"predict"
	}
	xtdpdbc_p_`scores' `0'
end

program define xtdpdbc_p_predict
	version 12.1
	syntax [anything] [if] [in] [, XB *]
	loc 0				`"`anything' `if' `in' , `options'"'
	loc options			"UE E U XBU"
	_pred_se "`options'" `0'
	if `s(done)' {
		exit
	}
	loc vtype			"`s(typ)'"
	loc varn			"`s(varn)'"
	loc 0				`"`s(rest)'"'
	syntax [if] [in] [, `options']
	marksample touse

	loc prediction		"`ue'`e'`u'`xbu'"
	if "`prediction'" == "" {						// linear prediction excluding unit-specific error component (default)
		if "`xb'" == "" {
			di as txt "(option xb assumed; fitted values)"
		}
		_predict `vtype' `varn' if `touse', xb
		exit
	}
	if "`prediction'" == "ue" {						// combined residual
		tempvar xb
		qui predict double `xb' if `touse', xb
		gen `vtype' `varn' = `e(depvar)' - `xb' if `touse'
		lab var `varn' "u[`e(ivar)'] + e[`e(ivar)',`e(tvar)']"
		exit
	}
	qui replace `touse' = 0 if !e(sample)
	if "`prediction'" == "e" {						// idiosyncratic error component
		tempvar xb u
		qui predict double `xb' if `touse', xb
		qui predict double `u' if `touse', u
		gen `vtype' `varn' = `e(depvar)' - `xb' - `u' if `touse'
		lab var `varn' "e[`e(ivar)',`e(tvar)']"
		exit
	}
	tempvar smpl
	qui gen byte `smpl' = e(sample)
	if "`prediction'" == "u" | "`prediction'" == "xbu" {
		tempvar xb u y_bar xb_bar
		qui predict double `xb' if `smpl', xb
		qui by `e(ivar)': egen double `y_bar' = mean(`e(depvar)') if `smpl'
		qui by `e(ivar)': egen double `xb_bar' = mean(`xb') if `smpl'
		qui gen double `u' = `y_bar' - `xb_bar' if `smpl'
		if "`prediction'" == "u" {					// unit-specific error component
			gen `vtype' `varn' = `u' if `touse'
			lab var `varn' "u[`e(ivar)']"
		}
		else {										// linear prediction including unit-specific error component
			gen `vtype' `varn' = `xb' + `u' if `touse'
			lab var `varn' "Xb + u[`e(ivar)']"
		}
		exit
	}
	error 198
end

*==================================================*
**** computation of parameter-level scores ****
program define xtdpdbc_p_scores, rclass
	version 12.1
	syntax [anything] [if] [in] , SCores
	marksample touse

	tempname isinit
	mata: st_numscalar("`isinit'", findexternal("`e(mopt)'") != J(1, 1, NULL))
	if !`isinit' {
		error 301
	}
	tempvar smpl
	qui gen byte `smpl' = e(sample)
// 	mata: xtdpdbc_init_touse(`e(mopt)', "`smpl'")		// marker variable
	tempname b
	mat `b'				= e(b)
	loc indepvars		: coln `b'
	loc K				: word count `indepvars'
	_stubstar2names `anything', nvars(`K') noverify
	loc vtypes			"`s(typlist)'"
	loc varn			"`s(varlist)'"
	if `: word count `varn'' != `K' {
		error 102
	}
	loc indepvars		: subinstr loc indepvars "_cons" "", w c(loc constant)
	foreach var of loc varn {
		tempvar gen`var'
		qui gen double `gen`var'' = .
		loc scorevars		"`scorevars' `gen`var''"
	}
	mata: xtdpdbc_score(`e(mopt)', "`scorevars'", "`smpl'", `e(steps)')
	forv k = 1 / `K' {
	    loc var				: word `k' of `varn'
		loc vtyp			: word `k' of `vtypes'
		qui gen `vtyp' `var' = `gen`var'' if `touse'
		lab var `var' "parameter-level score from `e(cmd)'"
	}

	ret loc scorevars `varn'
end
