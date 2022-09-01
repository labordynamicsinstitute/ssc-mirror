*! version 1.3.0  26may2022
*! Sebastian Kripfganz, www.kripfganz.de
*! Jörg Breitung, wisostat.uni-koeln.de/en/institute/professors/breitung

*==================================================*
***** postestimation statistics after xtdpdbc *****

program define xtdpdbc_estat, rclass
	version 12.1
	if "`e(cmd)'" != "xtdpdbc" {
		error 301
	}
	gettoken subcmd rest : 0, parse(" ,")
	if "`subcmd'" == substr("serial", 1, max(3, `: length loc subcmd')) {
		loc subcmd			"serial"
	}
	else if "`subcmd'" == substr("overid", 1, max(4, `: length loc subcmd')) {
		loc subcmd			"overid"
	}
	else if "`subcmd'" == substr("hausman", 1, max(4, `: length loc subcmd')) {
		loc subcmd			"hausman"
	}
	else {
		loc subcmd			""
	}
	if "`subcmd'" != "" {
		xtdpdbc_estat_`subcmd' `rest'
	}
	else {
		estat_default `0'
	}
	ret add
end

*==================================================*
**** computation of serial-correlation test statistics ****
program define xtdpdbc_estat_serial, rclass
	version 12.1
	syntax [, AR(numlist int >0)]

	if "`ar'" == "" {
		loc ar				"1 2"
	}
	tempvar smpl dsmpl e
	qui gen byte `smpl' = e(sample)
	qui predict double `e' if `smpl', e
	tempname b
	mat `b'				= e(b)
	loc indepvars		: coln `b'
	loc indepvars		: subinstr loc indepvars "_cons" "`smpl'", w c(loc constant)
	if !`constant' {
		loc indepvars		: subinstr loc indepvars "o._cons" "o.`smpl'", w c(loc constant)
	}
	loc K				: word count `indepvars'
	tempname score
	forv k = 1 / `K' {
		tempvar `score'`k'
		loc scorevars		"`scorevars' `score'`k'"
		loc var				: word `k' of `indepvars'
		_ms_parse_parts `var'
		if "`r(type)'" != "variable" {
			fvrevar `var'
			loc var				"`r(varlist)'"
		}
		loc dindepvars		"`dindepvars' D.`var'"
	}
	loc sigma2e			= e(sigma2e)
	if `sigma2e' == . {
		qui predict double `score'* if `smpl', score
		cap conf mat e(V_modelbased)
		if _rc == 0 {
			loc V				"e(V_modelbased)"
		}
		else {
			loc V				"e(V)"
		}
	}

	di _n as txt "Arellano-Bond test for autocorrelation of the first-differenced residuals"
	foreach order of num `ar' {
		qui gen byte `dsmpl' = `smpl'
		markout `dsmpl' D.`e' L`order'D.`e'
		tsrevar D.`e' if `smpl'
		loc tde				"`r(varlist)'"
		tsrevar L`order'D.`e' if `smpl'
		loc tlde			"`r(varlist)'"
		fvrevar `dindepvars' if `smpl'
		loc tdindepvars		"`r(varlist)'"
		mata: st_numscalar("r(z)", xtdpdbc_serial("`tde'", "`tlde'", "`tdindepvars'", "`scorevars'", "`_dta[_TSpanel]'", "`smpl'", "`dsmpl'", "`V'", "e(V)", `sigma2e'))
		loc z`order'		= r(z)
		loc p`order'		= 2 * normal(- abs(`z`order''))
		qui drop `dsmpl'
		di as txt "H0: no autocorrelation of order " `order' as txt ":" _col(40) "z = " as res %9.4f `z`order'' _col(56) as txt "Prob > |z|" _col(68) "=" _col(73) as res %6.4f `p`order''
	}

	foreach order of num `ar' {
		ret sca p_`order'	= `p`order''
		ret sca z_`order'	= `z`order''
	}
end

*==================================================*
**** computation of overidentification test statistics ****
program define xtdpdbc_estat_overid, rclass
	version 12.1
	if `"`0'"' != "" {
		error 198
	}
	if "`e(model)'" == "fe" {
		di as err "estat overid not allowed after xtdpdbc with option fe"
		exit 321
	}

	loc J				= e(chi2_J)
	if e(zrank_a) < e(zrank) {
		loc df				= e(zrank_a) - e(rank)
		di as txt "note: degrees of freedom adjusted for time effects in unbalanced panels"
	}
	else {
		loc df				= e(zrank) - e(rank)
	}
	if !`df' {
		di as txt "note: coefficients are just-identified"
	}
	else if e(steps) == 1 {
		di as txt "note: asymptotically invalid, use two-step estimator"
	}
	loc p				= chi2tail(`df', `J')
	di _n as txt cond(e(steps) == 1, "Sargan", "Hansen") " test of the overidentifying restrictions" _col(56) "chi2(" as res `df' as txt ")" _col(68) "=" _col(70) as res %9.4f `J'
	di as txt "H0: overidentifying restrictions are valid" _col(56) "Prob > chi2" _col(68) "=" _col(73) as res %6.4f `p'

	ret sca p			= `p'
	ret sca df			= `df'
	ret sca chi2		= `J'
end

*==================================================*
**** computation of generalized Hausman test statistic ****
program define xtdpdbc_estat_hausman, rclass
	version 12.1
	syntax anything(id="estimation results") , [DF(integer 0)]
	gettoken estname anything : anything , match(paren) bind
	if `: word count `estname'' != 1 | `"`paren'"' != "" {
		error 198
	}
	gettoken varlist anything : anything, match(paren) bind
 	if (`"`paren'"' == "" & `"`varlist'"' != "") | (`"`paren'"' != "" & `"`anything'"' != "") {
		error 198
	}
	if `df' < 0 {
		di as err "option df() incorrectly specified -- outside of allowed range"
		exit 198
	}

	forv e = 1 / 2 {
		if `e' == 2 {
			tempname xtdpdbc_e
			_est hold `xtdpdbc_e'
			qui est res `estname'
			if "`e(cmd)'" != "xtdpdbc" {
				_est unhold `xtdpdbc_e'
				di as err "`estname' is not supported by estat hausman"
				exit 322
			}
		}
		tempname b`e'
		mat `b`e''			= e(b)
		loc bvars`e'		: coln `b`e''
		if `e' == 1 {
			if `"`varlist'"' == "" {
				loc cons			"_cons o._cons"
				loc varlist			: list bvars`e' - cons
			}
			else {
				fvexpand `varlist'
				loc varlist			"`r(varlist)'"
			}
			if `df' > `: word count `varlist'' {
				di as err "option df() incorrectly specified -- outside of allowed range"
				exit 198
			}
			tempvar touse
			qui gen byte `touse' = e(sample)
		}
		else {
			tempvar aux
			qui gen byte `aux' = e(sample)
			qui replace `aux' = `aux' - `touse'
			sum `aux', mean
			if r(max) | r(min) {
				_est unhold `xtdpdbc_e'
				di as err "estimation samples must coincide"
				exit 322
			}
			drop `aux'
		}
		if !`: list varlist in bvars`e'' {
			if `e' == 2 {
				_est unhold `xtdpdbc_e'
			}
			di as err "`: list varlist - bvars`e'' not found"
			exit 111
		}
		tempname score`e'
		forv k = 1/`: word count `bvars`e''' {
			tempvar `score`e''`k'
			loc scorevars`e' "`scorevars`e'' `score`e''`k'"
		}
		qui predict double `score`e''* if `touse', score
		tempname V`e'
		cap conf mat e(V_modelbased)
		if _rc == 0 {
			mat `V`e''			= e(V_modelbased)
		}
		else {
			mat `V`e''			= e(V)
		}
		tempname pos`e' aux
		foreach var of loc varlist {
			loc k				: list posof "`var'" in bvars`e'
			mat `pos`e''		= (nullmat(`pos`e''), `k')
			mat `aux'			= (nullmat(`aux'), `b`e''[1, "`var'"])
		}
		mat `b`e''			= `aux'
		if !`df' {
			loc df`e'			= e(zrank) - e(rank)
			loc df`e'_a			= (e(zrank_a) < e(zrank))
		}
	}
	_est unhold `xtdpdbc_e'

	mata: xtdpdbc_hausman(	"`scorevars1'",			///
							"`scorevars2'",			///
							"`_dta[_TSpanel]'",		///
							"`touse'",				///
							"`b1'",					///
							"`b2'",					///
							"`pos1'",				///
							"`pos2'",				///
							"`V1'",					///
							"`V2'")
	loc chi2			= r(chi2)
	if !`df' {
		loc df				= min(abs(`df1' - `df2'), r(df_max))
		if `df1_a' | `df2_a' {
			di as txt "note: degrees of freedom might be incorrect -- use option df()"
		}
	}
	loc p				= chi2tail(`df', `chi2')
	di _n as txt "Generalized Hausman test" _col(56) "chi2(" as res `df' as txt ")" _col(68) "=" _col(70) as res %9.4f `chi2'
	di as txt "H0: coefficients do not systematically differ" _col(56) "Prob > chi2" _col(68) "=" _col(73) as res %6.4f `p'

	ret sca p			= `p'
	ret sca df			= `df'
	ret sca chi2		= `chi2'
end
