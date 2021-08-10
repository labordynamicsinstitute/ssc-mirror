*! version 1.1.1  16mar2021
*! Sebastian Kripfganz, www.kripfganz.de
*! Jan F. Kiviet, sites.google.com/site/homepagejfk/

*==================================================*
***** Kinky least squares estimation *****

*** citation ***

/*	Kripfganz, S., and J. F. Kiviet. 2021.
	kinkyreg: Instrument-free inference for linear regression models with endogenous regressors.
	Manuscript submitted to the Stata Journal.		*/

program define kinkyreg2dta
	version 13.0
	syntax anything(id="varlist" equalok) [if] [in] , [	Range(numlist >=-1 <=1)		///
														STEPsize(numlist >0 <2)		///
														FRame(string asis)			///
														REPLACE						///
														SAVING(string asis)			///
														DOUBLE						///
														SMall						///
														noGRaph						/// ignored
														*]							// parsed separately: COEF() ESTAT()
	kinkyreg2dta_parse_varlist `anything'
	loc depvar			"`s(depvar)'"
	loc exovars			"`s(exovars)'"
	loc endovars		"`s(endovars)'"
	loc K_endo			: word count `endovars'
	if `K_endo' < 1 {
		di as err "too few endogenous variables specified"
		exit 102
	}
	if "`s(ivvars)'" != "" {
		loc ivvars			"= `s(ivvars)'"
	}
	if `"`frame'"' != "" {
		if c(stata_version) < 16 {
			di as err "option frame() requires Stata 16.0 or higher"
			exit 199
		}
		if "`replace'" != "" {
			di as err "options frame() and replace may not be combined"
			exit 184
		}
		kinkyreg2dta_parse_frame `frame'
		loc frame			"`s(name)'"
	}
	else if "`replace'" == "" & c(stata_version) < 16 {
		di as err "option replace required"
		exit 198
	}
	if `"`saving'"' != "" {
		kinkyreg2dta_parse_saving `saving'
		loc saving			"`s(name)'"
		loc sreplace		"`s(replace)'"
	}
	else if "`frame'" == "" & "`replace'" == "" {
		di as err "one of the options frame(), replace, or saving() required"
		exit 198
	}

	*--------------------------------------------------*
	*** options for KLS results ***
	kinkyreg2dta_parse_coef `endovars', `options'
	loc options			`"`s(options)'"'
	loc Rc				= 0
	while `"`s(results)'"' != "" {
	    loc ++Rc
		loc results`Rc'		"`s(results)'"
		loc coefs`Rc'		`"`s(namelist)'"'
		loc results			"`results' `results`Rc''"
		loc coefs			`"`coefs' `coefs`Rc''"'
		kinkyreg2dta_parse_coef `endovars', `options'
		loc options			`"`s(options)'"'
	}
	loc results			: list uniq results
	loc coefs			: list uniq coefs
	kinkyreg2dta_parse_estat , `small' `options'
	loc options			`"`s(options)'"'
	loc Re				= 0
	while `"`s(results)'"' != "" {
	    loc ++Re
		loc estatnum`Re'	= `s(estatnum)'
		loc stats`Re'		"`s(results)'"
		loc cmd`Re'			`"`s(cmd)'"'
		loc estat`Re'		`"`s(cmdline)'"'
		loc estatnumlist	"`estatnumlist' `estatnum`Re''"
		kinkyreg2dta_parse_estat `estatnumlist' , `small' `options'
		loc options			`"`s(options)'"'
	}

	*--------------------------------------------------*
	*** endogeneity correlations ***
	if "`range'" != "" & `: word count `range'' != 2 {
		if `: word count `range'' < 2 * `K_endo' {
			di as err "range() invalid -- invalid numlist has too few elements"
			exit 122
		}
		if `: word count `range'' > 2 * `K_endo' {
			di as err "range() invalid -- invalid numlist has too many elements"
			exit 123
		}
	}
	if "`stepsize'" != "" & `: word count `stepsize'' != 1 {
		if `: word count `stepsize'' < `K_endo' {
			di as err "stepsize() invalid -- invalid numlist has too few elements"
			exit 122
		}
		if `: word count `stepsize'' > `K_endo' {
			di as err "stepsize() invalid -- invalid numlist has too many elements"
			exit 123
		}
	}
	tempname gmin gmax gstep
	forv k = 1 / `K_endo' {
		if `: word count `range'' {
			gettoken rangemin`k' range : range
			gettoken rangemax`k' range : range
			if `rangemax`k'' < `rangemin`k'' {
				di as err "range() invalid -- invalid numlist has elements out of order"
				exit 124
			}
		}
		else if `k' > 1 {
			loc rangemin`k'		= `rangemin`=`k'-1''
			loc rangemax`k'		= `rangemax`=`k'-1''
		}
		else {
			loc rangemin`k'		= -1
			loc rangemax`k'		= 1
		}
		if `: word count `stepsize'' {
			gettoken stepsize`k' stepsize : stepsize
		}
		else if `k' > 1 {
			loc stepsize`k'		= `stepsize`=`k'-1''
		}
		else {
			loc stepsize`k'		= 0.01
		}
		if `stepsize`k'' <= epsfloat() {
			di as err "stepsize() invalid -- invalid numlist has elements outside of allowed range"
			exit 125
		}
		mat `gmin'			= (nullmat(`gmin'), `rangemin`k'')
		mat `gmax'			= (nullmat(`gmax'), `rangemax`k'')
		mat `gstep'			= (nullmat(`gstep'), `stepsize`k'')
		loc endoname`k'		"_rho_`: word `k' of `endovars''"
		loc endoname`k'		: subinstr loc endoname`k' "." "_", all
		loc endoname`k'		: subinstr loc endoname`k' "#" "_", all
		loc endonames		"`endonames' `endoname`k''"
	}
	tempname endocombs
	mata: st_matrix("r(combs)", kinkyreg2dta_combs("`gmin'", "`gstep'", "`gmax'", 0))
	mat `endocombs'		= r(combs)
	mat coln `endocombs' = `endonames'
	if (c(stata_version) < 16) {
		if rowsof(`endocombs') > c(matsize) {
			di as err "number of grid points (`= rowsof(`endocombs')') exceeds the maximum matrix size (`c(matsize)')"
			exit 915
		}
	}
	else {
		if rowsof(`endocombs') > c(max_matdim) {
			di as err "number of grid points (`= rowsof(`endocombs')') exceeds the matrix dimension limit for Stata `c(flavor)' (`c(max_matdim)')"
			exit 915
		}
	}

	*--------------------------------------------------*
	*** KLS estimation ***
	tempname endocomb
	foreach res in `results' {
		tempname `res'
	}
	forv r = 1 / `Re' {
		foreach stat in `stats`r'' {
			tempname `stat'`r'
		}
	}
	if `K_endo' == 1 {
		qui kinkyreg `depvar' `exovars' (`endovars' `ivvars') `if' `in', range(`rangemin1' `rangemax1') stepsize(`stepsize1') `small' nograph `options'
		foreach res in `results' {
			mat ``res''			= e(`res'_kls)
			cap conf mat e(`res'_kls_lincom)
			if !_rc {
				mat ``res''			= (``res'', e(`res'_kls_lincom))
			}
			loc varnames		: coln ``res''
			loc varerror		: list coefs - varnames
			if "`varerror'" != "" {
				di as err `"option coef() incorrectly specified -- `varerror' not found"'
				exit 198
			}
		}
		forv r = 1 / `Re' {
			qui estat `cmd`r'' `estat`r''
			foreach stat in `stats`r'' {
				mat ``stat'`r''		= r(`stat'_kls)
			}
		}
	}
	else {
		mata: st_matrix("r(combs)", kinkyreg2dta_combs("`gmin'", "`gstep'", "`gmax'", 1))
		mat `endocomb'		= r(combs)
		loc J				= rowsof(`endocomb')
		forv j = 1 / `J' {
			loc endocorr		""
			forv k = 1 / `=`K_endo'-1' {
				loc endocorr		"`endocorr' `= el(`endocomb', `j', `k')'"
			}
			qui kinkyreg `depvar' `exovars' (`endovars' `ivvars') `if' `in', endogeneity(`endocorr' .) range(`rangemin`K_endo'' `rangemax`K_endo'') stepsize(`stepsize`K_endo'') `small' nograph `options'
			foreach res in `results' {
			    tempname aux
				mat `aux'			= e(`res'_kls)
			    cap conf mat e(`res'_kls_lincom)
				if !_rc {
				    mat `aux'			= (`aux', e(`res'_kls_lincom))
				}
				if `j' == 1 {
					loc varnames		: coln `aux'
					loc varerror		: list coefs - varnames
					if "`varerror'" != "" {
						di as err `"option coef() incorrectly specified -- `varerror' not found"'
						exit 198
					}
				}
				mat ``res''			= (nullmat(``res'') \ `aux')
			}
			forv r = 1 / `Re' {
				qui estat `cmd`r'' `estat`r''
				foreach stat in `stats`r'' {
					mat ``stat'`r''		= (nullmat(``stat'`r'') \ r(`stat'_kls))
				}
			}
		}
	}

	*--------------------------------------------------*
	*** data set generation ***
	foreach res in `results' {
		tempname `res'_s
	}
	forv r = 1 / `Rc' {
		foreach res in `results`r'' {
			foreach var in `coefs`r'' {
				mat ``res'_s'	= (nullmat(``res'_s'), ``res''[., `"`var'"'])
			}
		}
	}
	foreach res in `results' {
		loc varnames		: coln ``res'_s'
		loc varnames		: subinstr loc varnames "." "_", all
		loc varnames		: subinstr loc varnames "#" "_", all
		mat coln ``res'_s'	= `varnames'
		loc resname			"_`res'_"
		mat coleq ``res'_s'	= `resname'
	}
	tempname stats_s
	forv r = 1 / `Re' {
		foreach stat in `stats`r'' {
			loc varnames		: coln ``stat'`r''
			loc varnames		: subinstr loc varnames "." "_", all
			loc varnames		: subinstr loc varnames "#" "_", all
			mat coln ``stat'`r'' = `varnames'
			loc resname			"_`cmd`r''_`estatnum`r''_`stat'_"
			mat coleq ``stat'`r'' = `resname'
			mat `stats_s'		= (nullmat(`stats_s'), ``stat'`r'')
		}
	}
	if c(stata_version) >= 16 {
		tempname klsframe
		frame create `klsframe'
		frame change `klsframe'
		qui svmat `double' `endocombs', names(col)
		foreach res in `results' {
			qui svmat `double' ``res'_s', names(eqcol)
		}
		if `Re' {
			qui svmat `double' `stats_s', names(eqcol)
		}
		if "`saving'" != "" {
			save `saving', `sreplace'
		}
		if "`frame'" != "" {
			frame rename `klsframe' `frame'
		}
		else if "`replace'" != "" {
			frame drop default
			frame rename `klsframe' default
		}
		else {
			frame change default
			frame drop `klsframe'
		}
	}
	else {
		drop _all
		qui svmat `double' `endocombs', names(col)
		foreach res in `results' {
			qui svmat `double' ``res'_s', names(eqcol)
		}
		if `Re' {
			qui svmat `double' `stats_s', names(eqcol)
		}
		if "`saving'" != "" {
			save `saving', `sreplace'
		}
	}
end

*==================================================*
**** syntax parsing of the variable list ****
// (inspired by _iv_parse.ado)
program define kinkyreg2dta_parse_varlist, sclass
	version 13.0
	gettoken depvar 0 : 0, p(" ,[") m(paren) bind

	if inlist(`"`depvar'"', "[", ",", "if", "in") | `"`depvar'"' == "" {
		error 198
	}
	_fv_check_depvar `depvar'
	gettoken var 0 : 0, p(" ,[") m(paren) bind
	while !inlist(`"`var'"', "[", ",", "if", "in") & `"`var'"' != "" {
		if "`paren'" == "(" {
			if `"`endovars'"' != "" | `"`ivvars'"' != "" {
				error 198
			}
			gettoken endovar var : var, parse(" =") bind
			while `"`endovar'"' != "" & `"`endovar'"' != "=" {
				loc endovars		`"`endovars' `endovar'"'
				gettoken endovar var : var, parse(" =") bind
			}
			loc ivvars			`"`var'"'
		}
		else {
			loc exovars			`"`exovars' `var'"'
		}
		gettoken var 0 : 0, p(" ,[") m(paren) bind
	}

	sret loc rest		`"`0'"'
	sret loc ivvars		`"`: list retok ivvars'"'
	sret loc endovars	`"`: list retok endovars'"'
	sret loc exovars	`"`: list retok exovars'"'
	sret loc depvar		`"`depvar'"'
end

*==================================================*
**** syntax parsing of frame option ****
program define kinkyreg2dta_parse_frame, sclass
	version 13.0
	sret clear
	syntax name(id="frame"), [REPLACE]

	if "`replace'" == "" {
		conf new frame `namelist'
	}
	else {
		cap frame drop `namelist'
	}

	sret loc name		"`namelist'"
end

*==================================================*
**** syntax parsing of saving option ****
program define kinkyreg2dta_parse_saving, sclass
	version 13.0
	sret clear
	syntax name(id="filename"), [REPLACE]

	loc namelist		: subinstr loc namelist ".dta" ""
	loc namelist		"`namelist'.dta"
	if "`replace'" == "" {
		conf new file `namelist'
	}

	sret loc name		"`namelist'"
	sret loc replace	"`replace'"
end

*==================================================*
**** syntax parsing of options for KLS estimation results ****
program define kinkyreg2dta_parse_coef, sclass
	version 13.0
	sret clear
	syntax [varlist(num fv ts min=1)], [COEF(string asis) *]

	if `"`coef'"' != "" {
	    loc results			"b se ciub cilb"
		gettoken res coef : coef, parse(":")
		loc reserror		: list res - results
		if `"`reserror'"' != "" {
		    di as error `"option coef() incorrectly specified -- `reserror' not allowed"'
			exit 198
		}
		gettoken colon coef : coef, parse(":")
		if `"`colon'"' != ":" {
			di as err "option coef() incorrectly specified"
			exit 198
		}
		if !`: word count `coef'' {
			loc coef			"`varlist'"
		}

		sret loc results	"`res'"
		sret loc namelist	`"`coef'"'
	}
	sret loc options	`"`options'"'
end

*==================================================*
**** syntax parsing of options for KLS postestimation results ****
program define kinkyreg2dta_parse_estat, sclass
	version 13.0
	sret clear
	syntax [anything(id="numlist" equalok)], [ESTAT(string asis) SMall *]

	if `"`estat'"' != "" {
		gettoken estatnum estat : estat
		cap conf integer n `estatnum'
		if _rc {
			di as err "option estat() incorrectly specified"
			exit 198
		}
		if `estatnum' < 0 {
			di as err "option estat() incorrectly specified"
			exit 198
		}
		loc numerror		: list estatnum - anything
		if "`numerror'" == "" {
			di as err `"option estat() incorrectly specified -- duplicate `estatnum'"'
			exit 198
		}
	    loc results			= cond("`small'" != "", "F", "chi2")
	    loc results			"`results' p"
		gettoken res estat : estat, parse(":")
		loc reserror		: list res - results
		if `"`reserror'"' != "" {
		    di as error `"option estat() incorrectly specified -- `reserror' not allowed"'
			exit 198
		}
		gettoken colon estat : estat, parse(":")
		if `"`colon'"' != ":" | !`: word count `estat'' {
			di as err "option estat() incorrectly specified"
			exit 198
		}
		gettoken cmd estat : estat
		if `"`cmd'"' == "estat" {
			gettoken cmd estat : estat
		}
		if `"`cmd'"' == substr("exclusion", 1, max(4, `: length loc cmd')) {
			loc cmd				"excl"
		}
		else if `"`cmd'"' == substr("hettest", 1, max(4, `: length loc cmd')) {
			loc cmd				"hett"
		}
		else if `"`cmd'"' == "reset" | "`cmd'" == substr("ovtest", 1, max(3, `: length loc cmd')) {
			loc cmd				"reset"
		}
		else if `"`cmd'"' == substr("durbinalt", 1, max(3, `: length loc cmd')) {
			loc cmd				"dur"
		}
		else if `"`cmd'"' != "test" {
			di as err `"option estat() incorrectly specified -- estat `cmd' not valid"'
			exit 198
		}
		kinkyreg2dta_parse_estat_nograph `estat'
		loc estat			"`s(anything)', nograph `s(options)'"

		sret loc estatnum	= `estatnum'
		sret loc results	"`res'"
		sret loc cmd		`"`cmd'"'
		sret loc cmdline	`"`estat'"'
	}
	sret loc options	`"`options'"'
end

*==================================================*
**** syntax parsing for nograph option ****
program define kinkyreg2dta_parse_estat_nograph, sclass
	version 13.0
	syntax [anything(id="varlist" equalok)], [noGRaph *]

	sret loc anything	`"`anything'"'
	sret loc options	`"`options'"'
end
