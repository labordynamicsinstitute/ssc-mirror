*! version 1.0.2  19jul2024
*! Sebastian Kripfganz, www.kripfganz.de

*==================================================*
****** Panel data serial correlation testing ******

*** version history at the end of the file ***

program define xtdpdserial, rclass prop(xt)
	version 13.0
	_xt, treq
	syntax [varname(default=none num ts)] [if] [in] [, Statistics(string) noResiduals *]
	
	if "`varlist'" == "" {
		if "`residuals'" != "" {
			di as err "option noresiduals not allowed"
			exit 198
		}
		if "`e(cmd)'" == "" {
			error 301
		}
		if "`e(cmd)'" == "regress" {
			if "`e(absvar)'" != "" {
				di as err "requested action not valid after regress with option absorb()"
				exit 321
			}
		}
		else if inlist("`e(cmd)'", "xtdpdbc", "xtdpdgmm", "xtreg") {
			if "`e(cmd)'" == "xtreg" {
				if !inlist("`e(model)'", "fe", "re") {
					di as err "requested action not valid after xtreg with option `e(model)'"
					exit 321
				}
				if "`e(absvar)'" != "" & "`e(absvar)'" != "`e(ivar)'" {
					di as err "requested action not valid after xtreg with option absorb()"
					exit 321
				}
			}
		}
		else {
			error 321
		}
	}
	if `"`statistics'"' == "" & `"`options'"' == "" {
		loc statistics		"pm sdc dc fullc"
	}
	else if `"`statistics'"' != "" & `"`options'"' != "" {
		exit 198
	}
	if `"`statistics'"' == "" {
		xtdpdserial_stat `varlist' `if' `in', `residuals' `options'
	}
	else {
		xtdpdserial_parse_stats , `statistics'
		loc J				= `s(statnum)'
		loc statistics		`"`s(stats)'"'
		forv j = 1 / `J' {
			loc options`j'		`"`s(stat`j')'"'
		}
		tempname S
		forv j = 1 / `J' {
			cap noi xtdpdserial_stat `varlist' `if' `in', `residuals' `options`j'' `options'
			if "`r(chi2)'" != "" {
				ret loc chi2_`j'	= r(chi2)
				ret loc df_`j'		= r(df)
				ret loc p_`j'		= r(p)
			}
		}
	}
end

program define xtdpdserial_stat, rclass prop(xt)
	version 13.0
	syntax [varname(default=none num ts)] [if] [in] [, noResiduals *]
	marksample touse

	*--------------------------------------------------*
	*** syntax parsing of options ***
	xtdpdserial_parse_options , `options'
	loc collapse		= `s(collapse)'
	loc difference		= `s(difference)'
	loc forward			= `s(forward)'
	loc backward		= `s(backward)'
	loc order			`"`s(order)'"'
	loc lagrange		`"`s(lagrange)'"'
	loc ts				`"`s(ts)'"'
	loc label			"`s(label)'"

	*--------------------------------------------------*
	*** estimation results ***
	tempvar e
	if "`varlist'" == "" {
		qui replace `touse' = 0 if !e(sample)
		if "`e(cmd)'" == "xtreg" & "`e(model)'" == "re" {
			qui predict double `e' if `touse', ue
			loc varlist			"`e'"
		}
		else {
			if "`e(cmd)'" == "regress" {
				qui predict double `e' if `touse', r
			}
			else {
				qui predict double `e' if `touse', ue
			}

			tempname b
			mat `b'				= e(b)
			loc indepvars		: coln `b'
			loc indepvars		: subinstr loc indepvars "_cons" "`touse'", w c(loc constant)
			if !`constant' {
				loc indepvars		: subinstr loc indepvars "o._cons" "o.`touse'", w c(loc constant)
			}
			loc K				: word count `indepvars'

			if inlist("`e(cmd)'", "regress", "xtreg") {
				if e(N_clust) < . {
					loc q				= sqrt(e(N_clust) / (e(N_clust) - 1) * (e(N) - 1) / (e(N) - e(rank)))
				}
				else {
					loc q				= sqrt(e(N) / (e(N) - e(rank)))
				}
			}
			if "`e(cmd)'" == "regress" {
				forv k = 1 / `K' {
					tempvar score`k'
					qui gen double `score`k'' = `q' * `: word `k' of `indepvars'' * `e' if `touse'
					loc scorevars		"`scorevars' `score`k''"
				}
			}
			else if "`e(cmd)'" == "xtreg" {
				tempvar score
				qui predict double `score' if `touse', e
				forv k = 1 / `K' {
					tempvar score`k'
					loc var				: word `k' of `indepvars'
					if "`var'" == "`touse'" {
						qui gen double `score`k'' = `q' * `var' * `e' if `touse'
					}
					else {
						qui gen double `score`k'' = `q' * `var' * `score' if `touse'
					}
					loc scorevars		"`scorevars' `score`k''"
				}
			}
			else {
				forv k = 1 / `K' {
					tempvar score`k'
					loc scorevars		"`scorevars' `score`k''"
				}
				qui predict double `scorevars' if `touse', sc
			}
			cap conf mat e(V_modelbased)
			if !_rc {
				loc V				"e(V_modelbased)"
			}
			else if "`e(cmd)'" == "regress" {
				tempname V
				mat `V'				= (e(N) - e(rank)) / e(rss) * e(V)
			}
			else if "`e(cmd)'" == "xtreg" {
				tempname V
				mat `V'				= e(V) / e(sigma_e)^2
			}
			else {
				loc V				"e(V)"
			}
		}
	}
	else {
		qui gen double `e'	= `varlist' if `touse'
		if "`residuals'" == "" {
			tempvar resid
			foreach res in ue e resid {
				cap predict `resid' if `touse', `res'
				if !_rc {
					cap _rmdcoll `e' `resid'
					if _rc {
						di as err "test not valid for regression residuals"
						exit 459
					}
				}
				cap drop `resid'
			}
		}
		else {
			di as txt "note: test not valid for regression residuals"
		}
	}
	tempvar dtouse
	qui gen byte `dtouse' = `touse'
	markout `dtouse' D.`e'

	*--------------------------------------------------*
	*** lag order ***
	if "`ts'" != "" {
		cap tsrevar `ts'.`e' if `touse'
		if _rc {
			di as err "option ts() incorrectly specified"
			exit 198
		}
	}
	if `backward' {
		if "`ts'" == "" {
			sum `_dta[_TStvar]' if `touse', mean
			loc maxlag			= (r(max) - r(min)) / `_dta[_TSdelta]'
			if `maxlag' < 2 + (`difference' != 0) {
				error 2001
			}
			xtdpdserial_lagrange , maxlag(`maxlag') difference(`difference') `lagrange' `order'
			loc ts				"`s(ts)'"
			loc order			= `s(order)'
		}
		loc eL				"`ts'.`e'"
	}
	else if "`ts'" == "" {
		loc order			= 2
	}
	if `forward' {
		loc eF				"F.`e'"
	}
	if "`varlist'" == "" {
		foreach var of loc indepvars {
			if `backward' {
				if "`var'" != "`touse'" {
					if `difference' {
						_ms_parse_parts `var'
						if "`r(type)'" != "variable" | "`r(op)'" != "" {
							fvrevar `var'
							loc var				"`r(varlist)'"
						}
					}
					fvrevar `ts'.`var' if `touse'
					loc indepL			"`indepL' `r(varlist)'"
				}
				else {
					loc indepL			"`indepL' `ts'.`touse'"
				}
			}
			if `forward' {
				fvrevar F.`var' if `touse'
				loc indepF			"`indepF' `r(varlist)'"
			}
		}
	}

	*--------------------------------------------------*
	*** serial correlation test ***
	tempname serial
	mata: `serial' = xtdpdserial_init()
	mata: xtdpdserial_init_touse(`serial', "", "`touse'")
	mata: xtdpdserial_init_touse(`serial', "diff", "`dtouse'")
	mata: xtdpdserial_init_varname(`serial', "", "`e'")
	if `backward' {
		mata: xtdpdserial_init_varname(`serial', "L", "`eL'")
	}
	if `forward' {
		mata: xtdpdserial_init_varname(`serial', "F", "`eF'")
	}
	if "`varlist'" == "" {
		mata: xtdpdserial_init_indepvars(`serial', "", "`indepvars'")
		if `backward' {
			mata: xtdpdserial_init_indepvars(`serial', "L", "`indepL'")
		}
		if `forward' {
			mata: xtdpdserial_init_indepvars(`serial', "F", "`indepF'")
		}
		mata: xtdpdserial_init_scorevars(`serial', "`scorevars'")
		mata: xtdpdserial_init_covmat(`serial', st_matrix("`V'"))
	}
	mata: xtdpdserial_init_by(`serial', "`_dta[_TSpanel]'")
	mata: xtdpdserial_init_time(`serial', "`_dta[_TStvar]'")
	if `collapse' {
		mata: xtdpdserial_init_collapse(`serial', `collapse')
	}
	mata: xtdpdserial(`serial')
	mata: st_numscalar("r(chi2)", xtdpdserial_result_chi2(`serial'))
	mata: st_numscalar("r(df)", xtdpdserial_result_rank(`serial'))
	loc chi2			= r(chi2)
	loc df				= r(df)
	loc p				= chi2tail(`df', `chi2')

	*--------------------------------------------------*
	*** display of test results ***
	di _n as txt "`label'" _c
	di _col(56) "chi2(" as res `df' as txt ")" _col(68) "=" _col(70) as res %9.4f `chi2'
	di as txt "H0: no autocorrelation " _c
	if `difference' < 3 {
		if `order' == . {
			di "of any order" _c
		}
		else {
			di "up to order `order'" _c
		}
	}
	di _col(56) as txt "Prob > chi2" _col(68) "=" _col(73) as res %6.4f `p'

	*--------------------------------------------------*
	*** returned test results ***
	ret sca p			= `p'
	ret sca df			= `df'
	ret sca chi2		= `chi2'
end

*==================================================*
**** syntax parsing of tests ****
program define xtdpdserial_parse_stats, sclass
	version 13.0
	syntax , [*]

	loc statistics		`"`options'"'
	loc j				= 0
	while `"`statistics'"' != "" {
		gettoken stat statistics : statistics, bind
		loc ++j
		loc collapse		""
		loc stats			`"`stats' `stat'"'
		gettoken stat order : stat, p("(") bind
		if `"`order'"' != "" {
			loc 0				`", order`order'"'
			syntax , Order(numlist max=2)
			if `: word count `order'' == 1 {
				loc order			`"order(`order')"'
			}
			else {
				loc order			`"lagrange(`order')"'
			}
		}
		loc stat			: list retok stat
		if `"`stat'"' != "pm" & `"`stat'"' != "fullc" {
			gettoken stat collapse : stat, p("c") bind
			loc stat			: list retok stat
			loc label			""
		}
		cap xtdpdserial_parse_options , `stat' `collapse' `order'
		if _rc {
			di as err "option statistics() incorrectly specified"
			exit 198
		}
		sret loc stat`j'	`"`stat' `collapse' `order'"'
	}
	sret loc statnum	= `j'
	sret loc stats		`"`stats'"'
end

*==================================================*
**** syntax parsing of options ****
program define xtdpdserial_parse_options, sclass
	version 13.0
	syntax , [PM Difference SDifference Order(passthru) Lagrange(passthru) Collapse FULLCollapse noForward noBackward TS(string)]

	if `"`order'"' != "" & `"`lagrange'"' != "" {
		di as err "options order() and lagrange() may not be combined"
		exit 184
	}
	if "`collapse'" != "" & "`fullcollapse'" != "" {
		di as err "options collapse and fullcollapse may not be combined"
		exit 184
	}
	loc collapse		= ("`collapse'" != "") + 2 * ("`fullcollapse'" != "")
	if "`ts'" != "" {								// undocumented expert option (might result in invalid tests if used incorrectly)
		if "`difference'`sdifference'`forward'`backward'" != "" {
			di as err "options ts() and `: word 1 of `difference' `sdifference' `forward' `backward'' may not be combined"
			exit 184
		}
		if `"`order'"' != "" {
			di as err "options ts() and order() may not be combined"
			exit 184
		}
		if `"`lagrange'"' != "" {
			di as err "options ts() and lagrange() may not be combined"
			exit 184
		}
		loc difference		= 3
		loc forward			= 0
		loc backward		= 1
	}
	else if "`difference'" != "" {
		if "`sdifference'`backward'" != "" {
			di as err "options difference and `: word 1 of `sdifference' `backward'' may not be combined"
			exit 184
		}
		loc difference		= 1
		loc forward			= 0
		loc backward		= 1
		loc label			"test in first differences"
	}
	else if "`sdifference'" != "" {
		if "`forward'`backward'" != "" {
			di as err "options sdifference and `: word 1 of `forward' `backward'' may not be combined"
			exit 184
		}
		loc difference		= 2
		loc forward			= 0
		loc backward		= 1
		loc label			"test in seasonal differences"
	}
	else {
		if "`forward'" != "" & "`backward'" != "" {
			di as err "options noforward and nobackward may not be combined"
			exit 184
		}
		loc difference		= 0
		loc forward			= ("`forward'" == "")
		loc backward		= ("`backward'" == "")
		if `forward' & `backward' {
			loc label			"portmanteau test"
		}
		else {
			loc label			"restricted portmanteau test"
		}
	}
	if `collapse' == 1 {
		loc label			"collapsed `label'"
	}
	else if `collapse' == 2 {
		loc label			"fully-collapsed `label'"
	}

	sret loc collapse	= `collapse'
	sret loc difference	= `difference'
	sret loc forward	= `forward'
	sret loc backward	= `backward'
	sret loc order		`"`order'"'
	sret loc lagrange	`"`lagrange'"'
	sret loc ts			`"`ts'"'
	sret loc label		"`label'"
end

*==================================================*
**** determination of lag range ****
program define xtdpdserial_lagrange, sclass
	version 13.0
	syntax , MAXLag(integer) Difference(integer) [Lagrange(numlist max=2 int miss >1) Order(numlist max=1 int miss >1)]

	if "`order'" == "" {
		loc order			= .
	}
	else {
		if `difference' == 1 & `order' < . {
			loc --order
		}
		if `order' == 1 {
			di as err "order() invalid -- invalid numlist has elements outside of allowed range"
			exit 125
		}
		if `order' > `maxlag' {
			loc order			= `maxlag'
		}
		loc lagrange		"2 `order'"
		if `difference' == 1 {
			loc ++order
		}
	}
	if `difference' == 1 {
		loc --maxlag
	}
	if "`lagrange'" != "" {
		gettoken lag1 lag2 : lagrange
		if `lag1' == . {
			loc lag1			= 2
		}
		if "`lag2'" == "" {
			loc lag2			= `lag1'
		}
		else if `lag2' == . {
			loc lag2			= `maxlag'
		}
		if `lag1' > `lag2' {
			di as err "lagrange() invalid -- invalid numlist has elements out of order"
			exit 124
		}
		else if `lag1' > `maxlag' {
			error 2001
		}
		else if `lag2' > `maxlag' {
			loc lag2			= `maxlag'
			loc order			= `maxlag' + (`difference' == 1)
		}
		else if `order' == . {
			loc order			= `lag2'
			if `difference' == 1 {
				loc ++order
			}
		}
		if `difference' == 2 {
			loc ++lag1
			loc ++lag2
		}
	}
	else if `difference' == 2 {
		loc lag1			= 3
		loc lag2			= `maxlag' + 1
	}
	else {
		loc lag1			= 2
		loc lag2			= `maxlag'
	}
	loc lagrange		"`lag1'/`lag2'"
	if `difference' == 1 {
		loc ts				"L(`lagrange')D"
	}
	else if `difference' == 2 {
		loc ts				"FS(`lagrange')"
	}
	else {
		loc ts				"L(`lagrange')"
	}

	sret loc lag1		= `lag1'
	sret loc lag2		= `lag2'
	sret loc order		= `order'
	sret loc ts			"`ts'"
end

*==================================================*
*** version history ***
* version 1.0.2  19jul2024  bug fixed with fully collapsed tests in unbalanced panels
* version 1.0.1  12jul2024  support added for xtreg, re
* version 1.0.0  11jul2024  available online at www.kripfganz.de
* version 0.0.1  02jul2024
