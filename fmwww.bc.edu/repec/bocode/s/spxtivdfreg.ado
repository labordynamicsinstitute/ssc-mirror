*! version 1.4.2  06feb2024
*! Sebastian Kripfganz, www.kripfganz.de
*! Vasilis Sarafidis, sites.google.com/view/vsarafidis

*==================================================*
****** Defactored IV dynamic spatial panel data estimation ******

*** citation ***

/*	Kripfganz, S., and V. Sarafidis. 2024.
	Estimating spatial dynamic panel data models with unobserved common factors in Stata.
	Manuscript.		*/

program define spxtivdfreg, eclass prop(xt)			// option sortpreserve incompatible with package reghdfe
	version 13.0
	if replay() {
		if "`e(cmd)'" != "spxtivdfreg" {
			error 301
		}
		xtivdfreg `0'
	}
	else {
		syntax varlist(num ts fv) [if] [in] , SPMATrix(str) [	TLags(integer 0)					///
																SPLag								///
																SPTLags(integer 0)					///
																SPINDepvars(varlist num ts fv)		///
																noCONStant							///
																*]									// parsed separately: IV()
		loc fv				= ("`s(fvops)'" == "true")
		if `fv' {
			fvexpand `varlist'
			loc varlist			"`r(varlist)'"
		}
		marksample touse
		gettoken depvar indepvars : varlist
		if `fv' {
			_fv_check_depvar `depvar'
		}
		_xt, treq
		if `tlags' > 0 {
			forv l = `tlags'(-1)1 {
				_rmdcoll L`l'.`depvar' `indepvars'
				loc indepvars		"L`l'.`depvar' `indepvars'"
			}
			markout `touse' L(1/`tlags').`depvar'
		}
		if `sptlags' > 0 {
			forv l = `sptlags'(-1)1 {
				_rmdcoll L`l'.`depvar' `spindepvars'
				loc spindepvars		"L`l'.`depvar' `spindepvars'"
			}
		}
		if "`spindepvars'" != "" {
			markout `touse' `spindepvars'
		}
		spxtivdfreg_sample `touse'
		loc N				= r(N)

		*--------------------------------------------------*
		*** spatial weights matrix ***
		loc spmat			"spxtivdfreg_spmat"
		gettoken spmatrix spoptions : spmatrix, parse(",")
		if `"`spoptions'"' == "" {
			loc spoptions		", n(`N') w(`spmat')"
		}
		else {
			loc spoptions		`"`spoptions' n(`N') w(`spmat')"'
		}
		spxtivdfreg_parse_spmatrix `spmatrix' if `touse' `spoptions'
		loc maxeig			= `s(maxeig)'
		loc spmattype		"`s(type)'"

		*--------------------------------------------------*
		*** spatial lags and instruments ***
		if "`splag'" != "" | "`spindepvars'" != "" {
			spxtivdfreg_sample
			_rmcoll `spindepvars', `constant' exp
			if `fv' {
				cap ms_fvstrip `r(varlist)', dropomit
				if _rc {
					di as err "the use of factor variables requires further community-contributed packages:"
					di as err "  type {stata ssc install ftools} to install {bf:ftools}"
					exit 199
				}
			}
			loc spindepvars		"`r(varlist)'"
			loc spregnames		"`spindepvars'"
			if "`splag'" != "" {
				loc splag			"`depvar'"
				loc spregnames		"`depvar' `spregnames'"
				_rmdcoll `splag' `spindepvars', `constant'
				loc spindepvars		"`r(varlist)'"
			}
			foreach var in `splag' `spindepvars' {
				fvrevar `var'
				loc var				"`r(varlist)'"
				tempvar sp`var'
				qui gen double `sp`var'' = `var'
				loc spvarlist		"`spvarlist' `sp`var''"
			}
		}
		while `"`options'"' != "" {
			spxtivdfreg_parse_options , `options'
			if "`s(iv_varlist)'" == "" & "`s(spiv_varlist)'" == "" {
				loc options			`"`s(options)'"'
				continue, break
			}
			loc spivvars		"`s(spiv_varlist)'"
			loc ivvars			"`s(iv_varlist)'"
			loc ivoptions		`"`s(iv_options)'"'
			loc options			`"`s(options)'"'
			if "`spivvars'" == "" {
				loc spiv			`"`spiv' iv(`ivvars', `ivoptions')"'
			}
			else {
				if `fv' {
					cap ms_fvstrip `spivvars', dropomit
					if _rc {
						di as err "the use of factor variables requires further community-contributed packages:"
						di as err "  type {stata ssc install ftools} to install {bf:ftools}"
						exit 199
					}
					loc spivvars		"`r(varlist)'"
				}
				loc spivvarlist		""
				loc spivnames		""
				foreach var in `spivvars' {
					loc spivnames		"`spivnames' W:`var'"
					fvrevar `var'
					loc var				"`r(varlist)'"
					tempvar sp`var'
					qui gen double `sp`var'' = `var'
					loc spivvarlist		"`spivvarlist' `sp`var''"
				}
				loc spiv			`"`spiv' iv(`ivvars' `spivvarlist', `ivoptions' varnames(`ivvars' `spivnames'))"'
			}
		}
		sort `_dta[_TStvar]' `_dta[_TSpanel]', stable
		if "`spvarlist'" != "" {
			cap mata: spxtivdfreg_spgen("`spvarlist'", "`_dta[_TStvar]'", "", `spmat')
		}
		if _rc {
			sort `_dta[_TSpanel]' `_dta[_TStvar]', stable
			exit _rc
		}
		if "`spivvarlist'" != "" {
			cap mata: spxtivdfreg_spgen("`spivvarlist'", "`_dta[_TStvar]'", "", `spmat')
		}
		if _rc {
			sort `_dta[_TSpanel]' `_dta[_TStvar]', stable
			exit _rc
		}
		sort `_dta[_TSpanel]' `_dta[_TStvar]', stable

		*--------------------------------------------------*
		*** estimation ***
		xtivdfreg `depvar' `indepvars' `spvarlist' `if' `in', `constant' `options' `spiv' spvarlist(`spvarlist') spregnames(`spregnames')
		eret sca splag		= ("`splag'" != "")
		eret sca tlags		= `tlags'
		eret sca sptlags	= `sptlags'
		eret sca maxeig		= `maxeig'
		eret loc predict 	"spxtivdfreg_p"
		eret loc estat_cmd 	"spxtivdfreg_estat"
		eret loc cmdline 	`"spxtivdfreg `0'"'
		eret loc cmd		"spxtivdfreg"
		eret hidden loc spmat "`spmat'"
	}
end

*==================================================*
**** sample identification ****
program define spxtivdfreg_sample, rclass
	version 13.0
	syntax [varname(default=none num)]

	if "`varlist'" == "" {
		tempname touse
		qui gen byte `touse' = 1
		loc varlist			"`touse'"
	}
	capture xtdes if `varlist'
	if _rc == 459 {
		error 2000
	}
	if r(min) < r(max) {
		di as err "set of panels not balanced"
		exit 459
	}
	if r(N) == 0 {
		error 2000
	}
	if r(min) < 2 {
		error 2001
	}
	loc N				= r(N)
	loc T				= r(min)
	tempvar consec maxconsec
	qui gen int `consec' = .
	qui by `_dta[_TSpanel]': replace `consec' = cond(L.`consec' == ., 1, L.`consec' + 1) if `varlist'
	qui by `_dta[_TSpanel]': egen int `maxconsec' = max(`consec')
	sum `maxconsec', mean
	if r(min) < `T' {
		di as err "set of panels has gaps"
		exit 459
	}

	ret sca T			= `T'
	ret sca N		 	= `N'
end

*==================================================*
**** syntax parsing of options for spatial instruments ****
program define spxtivdfreg_parse_options, sclass
	version 13.0
	sret clear
	syntax , [IV(string) *]

	if `"`iv'"' != "" {
		spxtivdfreg_parse_iv `iv'
	}

	sret loc options	`"`options'"'
end

*==================================================*
**** syntax parsing for instruments ****
program define spxtivdfreg_parse_iv, sclass
	version 13.0
	syntax [varlist(default=none num ts fv)] [, SPiv(string) SPLags FVAR(varlist num ts fv) *]

	if "`varlist'" == "" & ("`spiv'" == "" | "`splags'" != "") {
		di as err "option iv() incorrectly specified"
		exit 198
	}
	if "`spiv'" != "" {
		spxtivdfreg_parse_spiv `spiv'
	}
	if "`s(fvar)'" != "" {
		loc fvar			"`fvar' `s(fvar)'"
	}
	else if "`fvar'" == "" {
		loc fvar			= cond("`varlist'" == "", "`s(spiv_varlist)'", "`varlist'")
	}
	if "`splags'" != "" {
		spxtivdfreg_parse_spiv `s(spiv_varlist)' `varlist'
	}

	sret loc iv_varlist	"`varlist'"
	sret loc iv_options	`"fvar(`fvar') `options'"'
end

*==================================================*
**** syntax parsing for spatial instruments ****
program define spxtivdfreg_parse_spiv, sclass
	version 13.0
	syntax varlist(num ts fv) [, FVAR]				// undocumented

	if ("`s(fvops)'" == "true") {
		fvexpand `varlist'
		loc varlist			"`r(varlist)'"
	}

	if "`fvar'" != "" {
		sret loc fvar		"`varlist'"
	}
	sret loc spiv_varlist "`varlist'"
end

*==================================================*
**** syntax parsing for the spatial weights matrix ****
program define spxtivdfreg_parse_spmatrix, sclass
	version 13.0
	sret clear
	syntax anything(id="matrix name") [if] [in], N(integer) W(name) [SPmatrix Mata STata IMPORT *]

	if `: word count `spmatrix' `mata' `stata' `import'' > 1 {
		di as err "option spmatrix() incorrectly specified"
		exit 198
	}
	if "`import'" == "" {
		cap conf name `anything'
		if _rc {
			di as err "option spmatrix() incorrectly specified -- invalid name"
			exit 198
		}
		if `"`options'"' != "" {
			di as err `"`options' not allowed"'
			exit 198
		}
	}
	if "`mata'" != "" {
		mata: st_numscalar("r(ismatrix)", findexternal("`anything'") != J(1, 1, NULL))
		if !r(ismatrix) {
			di as err "matrix `anything' not found"
			exit 111
		}
		mata: st_numscalar("r(isreal)", isreal(`anything'))
		if !r(isreal) {
			di as err "element type of matrix `anything' is not real"
			exit 504
		}
		mata: st_numscalar("r(miss)", hasmissing(`anything'))
		loc miss			= r(miss)
		mata: st_numscalar("r(rows)", rows(`anything'))
		loc rows			= r(rows)
		mata: st_numscalar("r(cols)", cols(`anything'))
		loc cols			= r(cols)
	}
	else if "`stata'" != "" {
		conf mat `anything'
		loc miss			= matmissing(`anything')
		loc rows			= rowsof(`anything')
		loc cols			= colsof(`anything')
	}
	else if "`import'" != "" {
		conf file `"`anything'"'
		cap loc xls			= ustrpos(`"`anything'"', ".xls")
		if _rc == 133 {
			di as err "option import requires Stata 14.0 or higher"
			exit 199
		}
		tempname W
		if c(stata_version) < 16 {
			preserve
			if `xls' {
				qui import exc `"`anything'"', clear `options'
			}
			else {
				qui import delim `"`anything'"', clear `options'
			}
			mata: `W' = st_data(., .)
			restore
		}
		else {
			tempname spmatframe
			frame create `spmatframe'
			frame change `spmatframe'
			if `xls' {
				qui import exc `"`anything'"', `options'
			}
			else {
				qui import delim `"`anything'"', `options'
			}
			mata: `W' = st_data(., .)
			frame change default
			frame drop `spmatframe'
		}
		mata: st_numscalar("r(miss)", hasmissing(`W'))
		loc miss			= r(miss)
		mata: st_numscalar("r(rows)", rows(`W'))
		loc rows			= r(rows)
		mata: st_numscalar("r(cols)", cols(`W'))
		loc cols			= r(cols)
	}
	else {
		capture spmatrix dir
		if _rc == 199 {
			di as err "option spmatrix requires Stata 15.0 or higher"
			exit 199
		}
		loc splist			"`r(names)'"
		if !`: list anything in splist' {
			di as err "matrix `anything' not found"
			exit 111
		}
		loc miss			= 0
		qui spmatrix summarize `anything'
		loc rows			= r(n)
		loc cols			= r(n)
		loc diag0			= r(n)
	}
	if `miss' {
		di as err "matrix `anything' has missing values"
		exit 504
	}
	if `rows' != `cols' {
		di as err "conformability error -- matrix `anything' not square"
		exit 503
	}
	if `rows' < `n' {
		di as err "conformability error -- matrix `anything' too small"
		exit 503
	}
	if `rows' > `n' {
		di as err "conformability error -- matrix `anything' too large"
		exit 503
	}
	if "`mata'" != "" {
		mata: st_numscalar("r(diag0)", diag0cnt(`anything'))
		loc diag0			= (r(diag0) == `n')
	}
	else if "`stata'" != "" {
		loc diag0			= (diag0cnt(`anything') == `n')
	}
	else if "`import'" != "" {
		mata: st_numscalar("r(diag0)", diag0cnt(`W'))
		loc diag0			= (r(diag0) == `n')
	}
	if !`diag0' {
		di as err "matrix `anything' has nonzero values on diagonal"
		exit 508
	}
	if "`mata'" != "" {
		mata: `w' = `anything'
	}
	else if "`stata'" != "" {
		mata: `w' = st_matrix("`anything'")
	}
	else if "`import'" != "" {
		mata: `w' = `W'
		mata: mata drop `W'
	}
	else {
		tempvar touse
		gen byte `touse' = 0
		qui replace `touse' = 1 `if' `in'
		sum `_dta[_TStvar]' if `touse', mean
		qui replace `touse' = 0 if `_dta[_TStvar]' != r(min)
		tempname W id1 id2
		spmatrix matafromsp `W' `id1' = `anything'
		mata: st_view(`id2' = ., ., "`_dta[_TSpanel]'", "`touse'")
		mata: st_numscalar("r(match)", colmax((`id1' :== `id2')))
		mata: mata drop `id1' `id2'
		if !r(match) {
			mata: mata drop `W'
			di as err "matrix `anything' has elements out of order"
			exit 5
		}
		mata: `w' = `W'
		mata: mata drop `W'
		if "`spmatrix'" == "" {
			loc spmatrix		"spmatrix"
		}
	}
// 	tempname Wsum
// 	mata: `Wsum' = quadrowsum(`w')
// 	mata: st_numscalar("r(rowst)", (mean(abs(`Wsum' :- mean(`Wsum'))) < 1e-5))		// row-standardized spatial weights matrix
// 	mata: mata drop `Wsum'
	mata: st_numscalar("r(maxeig)", abs((issymmetric(`w') ? symeigenvalues(`w') : eigenvalues(`w'))[1]))

// 	sret loc rowst		= r(rowst)
	sret loc maxeig		= r(maxeig)
	sret loc type		"`spmatrix'`mata'`stata'"
end
