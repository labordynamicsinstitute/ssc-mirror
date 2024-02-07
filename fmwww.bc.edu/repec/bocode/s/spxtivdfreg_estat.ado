*! version 1.4.2  06feb2024
*! Sebastian Kripfganz, www.kripfganz.de
*! Vasilis Sarafidis, sites.google.com/view/vsarafidis

*==================================================*
***** postestimation statistics after spxtivdfreg *****

program define spxtivdfreg_estat, rclass
	version 13.0
	if "`e(cmd)'" != "spxtivdfreg" {
		error 301
	}
	gettoken subcmd rest : 0, parse(" ,")
	if "`subcmd'" == "impact" {
		spxtivdfreg_estat_`subcmd' `rest'
	}
	else {
		xtivdfreg_estat `0'
	}
	ret add
end

*==================================================*
**** computation of direct, indirect, and total impacts ****
program define spxtivdfreg_estat_impact, rclass sort
	version 13.0
	syntax [varlist(num ts fv default=none)] [, SR LR CONStant POST FORCE *]

	if "`e(vcetype)'" == "Delta-method" {
		error 321
	}
	if "`sr'" != "" & "`lr'" != "" {
		di as err "options sr and lr may not be combined"
		exit 184
	}
	if "`lr'" != "" & e(tlags) == 0 & e(sptlags) == 0 {
		di as txt "note: no time lags or spatial time lags founds; long-run impacts equal short-run impacts"
		loc lr				""
	}
	loc sr				= ("`sr'" != "")
	loc lr				= ("`lr'" != "")
	if !`sr' & !`lr' {
		loc sr				= 1
	}
	_get_diopts diopts, `options'
	tempvar touse
	gen byte `touse' = e(sample)
	tempname b b0 b1
	mat `b'				= e(b)
	loc K				= colsof(`b')
	loc regnames		: coln `b'
	if "`constant'" == "" {
		loc cons			"_cons"
		loc regnames		: list regnames - cons
	}
	loc depvar			"`e(depvar)'"
// 	if `lr' & (e(tlags) > 0 | e(sptlags) > 0) {
	if e(tlags) > 0 | e(sptlags) > 0 {
		tsunab ldepvar : L(1/`=max(e(tlags),e(sptlags))').`e(depvar)'
		loc varerror		= ("`: list varlist - regnames'" != "" | `: list depvar in varlist' | "`: list ldepvar & varlist'" != "")
	}
	else {
		loc varerror		= ("`: list varlist - regnames'" != "" | `: list depvar in varlist')
	}
	if `varerror' {
		di as err "the specified varlist contains variables not in the model"
		exit 111
	}
	if "`varlist'" == "" {
		loc varlist			"`regnames'"
	}
	else if "`constant'" != "" {
		loc varlist			"`varlist' _cons"
	}
	cap mat `b1'		= `b'[1, "W:"]
	if _rc == 303 {
		loc K1				= 0
		loc lambda			= 0
	}
	else {
		mata: st_numscalar("r(ismatrix)", findexternal("`e(spmat)'") != J(1, 1, NULL))
		if !r(ismatrix) {
			error 301
		}
		loc K1				= colsof(`b1')
		loc spvars			: coln `b1'
		if e(splag) {
			if el(`b1', 1, 1) >= 1 / e(maxeig) {
				if "`force'" == "" {
					di as err "stability condition of the model violated"
					exit 322
				}
				else {
					di as txt "note: stability condition of the model violated"
				}
			}
			loc spvars			: list spvars - depvar
			loc lambda			= `b1'[1, 1]
		}
		else {
			loc lambda			= 0
		}
// 		if `lr' & e(sptlags) > 0 {
		if e(sptlags) > 0 {
			tempname rho
			tsunab ldepvar : L(1/`e(sptlags)').`depvar'
			loc spvars			: list spvars - ldepvar
			mat `rho'			= `b1'[1, `=1+e(splag)'..`=e(splag)+e(sptlags)']
		}
	}
	if `K1' < `K' {
		mat `b0'			= `b'[1, ":"]
		loc K0				= colsof(`b0')
		loc indepvars		: coln `b0'
// 		if `lr' & e(tlags) > 0 {
		if e(tlags) > 0 {
			tempname alpha
			tsunab ldepvar : L(1/`e(tlags)').`depvar'
			loc indepvars		: list indepvars - ldepvar
			mat `alpha'			= `b0'[1, 1..e(tlags)]
		}
	}
	else {
		loc K0				= 0
	}
	if "`indepvars'" == "" & "`spvars'" == "" {
		error 321
	}
	if `lr' {
		if e(tlags) > 0 {
			mata: st_numscalar("r(tsum)", quadrowsum(st_matrix("`alpha'")))
			loc tsum			= r(tsum)
		}
		else {
			loc tsum			= 0
		}
		if e(sptlags) > 0 {
			mata: st_numscalar("r(sptsum)", quadrowsum(st_matrix("`rho'")))
			loc sptsum			= r(sptsum)
		}
		else {
			loc sptsum			= 0
		}
		if (`tsum' + `sptsum' * e(maxeig)) / (1 - `lambda' * e(maxeig)) >= 1 {
			if "`force'" == "" {
				di as err "stability condition of the model violated"
				exit 322
			}
			else {
				di as txt "note: stability condition of the model violated"
			}
		}
	}
	tempname imp0_d imp0_t imp1_d imp1_t coefpos0 coefpos1
// 	loc k				= cond(`lr', 1 + e(tlags), 1)
	loc k				= 1 + e(tlags)
	if "`indepvars'" != "" {
		foreach var in `indepvars' {
			if `: list var in varlist' {
				loc indepnames		"`indepnames' `var'"
				if "`var'" == "_cons" {
					loc var				"`touse'"
				}
				else {
					fvrevar `var'
					loc var				"`r(varlist)'"
				}
				tempvar `var'_d `var'_i `var'_t
				qui gen double ``var'_d' = 1
				qui gen double ``var'_t' = 1
				loc indepvarlist_d	"`indepvarlist_d' ``var'_d'"
				loc indepvarlist_t	"`indepvarlist_t' ``var'_t'"
				mat `coefpos0'		= (nullmat(`coefpos0'), `k')
			}
			loc ++k
		}
		if "`indepnames'" != "" {
			mata: st_matrix("r(b)", st_matrix("`b'")[1, st_matrix("`coefpos0'")])
			mat `imp0_d'		= r(b)
			mat coln `imp0_d'	= `indepnames'
			mat `imp0_t'		= `imp0_d'
		}
	}
	if "`spvars'" != "" {
// 		loc k				= cond(`lr', `k' + e(splag) + e(sptlags), `k' + e(splag))
		loc k				= `k' + e(splag) + e(sptlags)
		foreach var in `spvars' {
			if `: list var in varlist' {
				loc spnames			"`spnames' `var'"
				fvrevar `var'
				loc var				"`r(varlist)'"
				tempvar sp`var'_d sp`var'_i sp`var'_t
				qui gen double `sp`var'_d' = 1
				qui gen double `sp`var'_t' = 1
				loc spvarlist_d		"`spvarlist_d' `sp`var'_d'"
				loc spvarlist_t		"`spvarlist_t' `sp`var'_t'"
				mat `coefpos1'		= (nullmat(`coefpos1'), `k')
			}
			loc ++k
		}
		if "`spnames'" != "" {
			mata: st_matrix("r(b)", st_matrix("`b'")[1, st_matrix("`coefpos1'")])
			mat `imp1_d'		= r(b)
			mat coln `imp1_d'	= `spnames'
			mat `imp1_t'		= `imp1_d'
		}
	}
	tempname coefs V
	mat `coefs'			= (`lambda', nullmat(`alpha'), nullmat(`rho'))
	sort `_dta[_TStvar]' `_dta[_TSpanel]'
	if `sr' {
		if "`indepnames'" != "" {
			mata: spxtivdfreg_spgen("`indepvarlist_d'", "`_dta[_TStvar]'", "", `e(spmat)', "`coefs'", 3, "`imp0_d'")
			mata: spxtivdfreg_spgen("`indepvarlist_t'", "`_dta[_TStvar]'", "", `e(spmat)', "`coefs'", 1, "`imp0_t'")
		}
		if "`spnames'" != "" {
			mata: spxtivdfreg_spgen("`spvarlist_d'", "`_dta[_TStvar]'", "", `e(spmat)', "`coefs'", 4, "`imp1_d'")
			mata: spxtivdfreg_spgen("`spvarlist_t'", "`_dta[_TStvar]'", "", `e(spmat)', "`coefs'", 2, "`imp1_t'")
		}
	}
	else {
		if "`indepnames'" != "" {
			mata: spxtivdfreg_spgen("`indepvarlist_d'", "`_dta[_TStvar]'", "", `e(spmat)', "`coefs'", 3, "`imp0_d'", `=e(tlags)', `=e(sptlags)')
			mata: spxtivdfreg_spgen("`indepvarlist_t'", "`_dta[_TStvar]'", "", `e(spmat)', "`coefs'", 1, "`imp0_t'", `=e(tlags)', `=e(sptlags)')
		}
		if "`spnames'" != "" {
			mata: spxtivdfreg_spgen("`spvarlist_d'", "`_dta[_TStvar]'", "", `e(spmat)', "`coefs'", 4, "`imp1_d'", `=e(tlags)', `=e(sptlags)')
			mata: spxtivdfreg_spgen("`spvarlist_t'", "`_dta[_TStvar]'", "", `e(spmat)', "`coefs'", 2, "`imp1_t'", `=e(tlags)', `=e(sptlags)')
		}
	}
	sort `_dta[_TSpanel]' `_dta[_TStvar]'
	tempname coefpos
	mat `coefpos'		= (cond(e(splag), `K0'+1, 0))
	if `lr' {
		mat `coefpos'		= (`coefpos', cond(e(tlags) > 0, e(tlags), 0))
		if e(sptlags) > 0 {
			mat `coefpos'		= (`coefpos', `K0'+1+e(splag), `K0'+e(splag)+e(sptlags))
		}
	}
	mata: spxtivdfreg_delta("`b'", "e(V)", "`coefpos0'", "`coefpos1'", "`coefpos'", `e(spmat)')
	mat `V'				= r(V)

	loc cvars			: list indepnames & spnames
	tempname imp_d imp_i imp_t
	if "`cvars'" == "" {
		mat `imp_d'			= (nullmat(`imp0_d'), nullmat(`imp1_d'))
		mat `imp_t'			= (nullmat(`imp0_t'), nullmat(`imp1_t'))
	}
	else {
		loc K				= colsof(`V')
		tempname s
		loc k				= 1
		if "`indepnames'" != "" {
			foreach var in `indepnames' {
				mat `s'				= (nullmat(`s') \ J(1, `K', 0))
				if `: list var in cvars' {
					mat `imp_d'			= (nullmat(`imp_d'), `imp0_d'[1, "`var'"] + `imp1_d'[1, "`var'"])
					mat `imp_t'			= (nullmat(`imp_t'), `imp0_t'[1, "`var'"] + `imp1_t'[1, "`var'"])
					mat `s'[`k', colnumb(`imp0_d', "`var'")] = 1
					mat `s'[`k', colnumb(`imp1_d', "`var'")] = 1
					loc spnames			: list spnames - var
				}
				else {
					mat `imp_d'			= (nullmat(`imp_d'), `imp0_d'[1, "`var'"])
					mat `imp_t'			= (nullmat(`imp_t'), `imp0_t'[1, "`var'"])
					mat `s'[`k', colnumb(`imp0_d', "`var'")] = 1
				}
				loc ++k
			}
		}
		if "`spnames'" != "" {
			foreach var in `spnames' {
				mat `s'				= (nullmat(`s') \ J(1, `K', 0))
				mat `imp_d'			= (nullmat(`imp_d'), `imp1_d'[1, "`var'"])
				mat `imp_t'			= (nullmat(`imp_t'), `imp1_t'[1, "`var'"])
				mat `s'[`k', colnumb(`imp1_d', "`var'")] = 1
				loc ++k
			}
		}
		mat `s'				= (`s' \ `s' \ `s')
		mata: st_matrix("r(V)", st_matrix("`s'") * st_matrix("`V'") * st_matrix("`s'")')
		mat `V'				= r(V)
	}
	mat `imp_i'			= `imp_t' - `imp_d'
	mat coleq `imp_d'	= direct
	mat coleq `imp_i'	= indirect
	mat coleq `imp_t'	= total
	tempname imp spxtivdfreg_e
	mat `imp'			= (`imp_d', `imp_i', `imp_t')
	loc impnames		: colf `imp'
	mat coln `V'		= `impnames'
	mat rown `V'		= `impnames'

	if "`post'" == "" {
		_est hold `spxtivdfreg_e', restore
	}
	spxtivdfreg_estat_impact_post `imp' `V'
	if `sr' {
		di _n as txt "Short-run impacts"
	}
	else {
		di _n as txt "Long-run impacts"
	}
	_coef_table, coeft("Impact") `diopts'

	tempname b V
	mat `b'				= e(b)
	mat `V'				= e(V)
	ret mat V			= `V'
	ret mat b			= `b'
end


*==================================================*
**** posting of direct, indirect, and total impacts ****
program define spxtivdfreg_estat_impact_post, eclass
	version 13.0
	syntax namelist(min=2 max=2)

	if "`e(cmd)'" == "spxtivdfreg" {
		gettoken b V : namelist
		eret repost b=`b' V=`V', resize
	}
	else {
		eret post `namelist'
	}
	eret loc vcetype	"Delta-method"
end
