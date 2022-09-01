*! version 1.3.0  26may2022
*! Sebastian Kripfganz, www.kripfganz.de
*! Jörg Breitung, wisostat.uni-koeln.de/en/institute/professors/breitung

*==================================================*
****** Bias-corrected linear dynamic panel data estimation ******

*** citation ***

/*	Breitung, J., S. Kripfganz, and K. Hayakawa (2021).
	Bias-corrected method of moments estimators for dynamic panel data models.
	Econometrics and Statistics, forthcoming.		*/

*** version history at the end of the file ***

program define xtdpdbc, eclass prop(xt)
	version 12.1
	if replay() {
		if "`e(cmd)'" != "xtdpdbc" {
			error 301
		}
		xtdpdbc_parse_display `0'
		if `"`s(options)'"' != "" {
			di as err `"`s(options)' invalid"'
			exit 198
		}
		xtdpdbc_display `0'
	}
	else {
		_xt, treq
		syntax varlist(num ts fv) [if] [in] [, *]
		xtdpdbc_parse_display , `options'
		loc diopts			`"`s(diopts)'"'
		xtdpdbc_mm_init , `s(options)'
		loc mopt			"`s(mopt)'"
		xtdpdbc_mm `varlist' `if' `in', mopt(`mopt') `s(options)'

		eret loc marginsok	"XB default"
		eret loc predict	"xtdpdbc_p"
		eret loc estat_cmd	"xtdpdbc_estat"
		eret loc tvar		"`_dta[_TStvar]'"
		eret loc ivar		"`_dta[_TSpanel]'"
		eret loc cmdline 	`"xtdpdbc `0'"'
		eret loc cmd		"xtdpdbc"
		eret hidden loc mopt	"`mopt'"			// undocumented
		xtdpdbc_display , `diopts'
	}
end

program define xtdpdbc_mm, eclass prop(xt)
	version 12.1
	syntax varlist(num ts fv) [if] [in] , MOPT(name) [	noCONStant						///
														LAgs(integer 1)					///
														FE								///
														RE								///
														HYbrid(varlist num ts fv)		///
														TEffects						///
														ONEstep							///
														FROM(passthru)					///
														VCE(passthru)					///
														SMall							///
														noCORrection]					// undocumented
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

	*--------------------------------------------------*
	*** model ***
	if "`re'" != "" {
		if "`fe'" != "" {
			di as err "options fe and re may not be combined"
			exit 184
		}
		if "`hybrid'" != "" {
			di as err "options re and hybrid() may not be combined"
			exit 184
		}
		loc hybrid			"`indepvars'"
	}
	else if "`hybrid'" != "" {
		if "`fe'" != "" {
			di as err "options fe and hybrid() may not be combined"
			exit 184
		}
		if `fv' {
			fvexpand `hybrid'
			loc hybrid			"`r(varlist)'"
		}
		if "`: list hybrid - indepvars'" != "" {
			di as err "option hybrid() incorrectly specified"
			exit 198
		}
		if "`: list indepvars - hybrid'" == "" {
			loc re				"re"
		}
	}
	else if "`fe'" == "" {
		loc fe				"fe"
	}
	if "`fe'" == "" {
		tempname exopos
		loc k				= `lags'
		if "`indepvars'" != "" {
			foreach var in `indepvars' {
				loc ++k
				if `: list var in hybrid' {
					mat `exopos'		= (nullmat(`exopos'), `k')
				}
			}
		}
	}
	else if "`onestep'" == "" {
		loc onestep			"onestep"
	}
	mata: xtdpdbc_init_steps(`mopt', ("`onestep'" == "") + 1)

	*--------------------------------------------------*
	*** lags of the dependent variable ***
	xtdpdbc_sample `touse', depvar(`depvar') lags(`lags')
	loc balanced		= r(balanced)
	loc exovars			"`indepvars'"
	if `fv' {
		fvexpand L(1/`lags').`depvar' `indepvars'
		loc indepvars		"`r(varlist)'"
	}
	else {
		tsunab indepvars	: L(1/`lags').`depvar' `indepvars'
	}
	mata: xtdpdbc_init_lags(`mopt', `lags')

	*--------------------------------------------------*
	*** time effects ***
	if "`teffects'" != "" {
		sum `_dta[_TStvar]' if `touse', mean
		loc tdelta			= `_dta[_TSdelta]'
		cap _rmcoll i(`= r(min)+`tdelta'*("`constant'" == "" | "`fe'" != "")'(`tdelta')`= r(max)')bn.`_dta[_TStvar]' if `touse', exp `constant'
		if _rc != 0 {
			error 451
		}
		loc teffects		"`r(varlist)'"
		loc indepvars		"`indepvars' `teffects'"
		if "`fe'" == "" {
// 			loc hybrid			"`hybrid' `teffects'"
			tempname exopos0
			mat `exopos0'		= nullmat(`exopos')
			foreach var in `teffects' {
				loc ++k
				mat `exopos'		= (nullmat(`exopos'), `k')
			}
		}
	}
	if "`indepvars'" != "" {
		if "`fe'" != "" {
			xtdpdbc_col `indepvars' if `touse', depvar(`depvar') hybrid(`hybrid')
		}
		else {
			xtdpdbc_col `indepvars' if `touse', depvar(`depvar') hybrid(`hybrid') `const'
		}
		loc indepvars		"`s(indepvars)'"
	}

	*--------------------------------------------------*
	*** type of variance-covariance matrices ***
	if `"`vce'"' != "" {
		xtdpdbc_parse_vce , balanced(`balanced') `vce'
		loc vce				"`s(vce)'"
		loc csd				= ("`s(csd)'" == "csd")
		if `csd' & "`fe'" == "" {
			di as err "option csd not allowed with options re or hybrid()"
			exit 198
		}
	}
	else {
		loc vce				"conventional"
		loc csd				= 0
	}
	if "`correction'" != "" & "`vce'" == "conventional" {
		loc vce				"unadjusted"
	}

	*--------------------------------------------------*
	*** initial estimates ***
	if "`constant'" == "" {
		loc regnames		"`indepvars' _cons"
	}
	else {
		loc regnames		"`indepvars'"
	}
	tempname b0
	if `"`from'"' == "" {
		if c(stata_version) >= 16 {
			version 16: qui xtreg `depvar' `indepvars', fe		// bug in Stata 15 under version control
		}
		else {
			mat `b0'			= J(1, `: word count `regnames'', 0)
			if "`teffects'" == "" {
				qui xtdpdbc `depvar' `exovars', fe lags(`lags') `cons' nocorrection from(`b0', copy)
			}
			else {
				qui xtdpdbc `depvar' `exovars', fe lags(`lags') `cons' teffects nocorrection from(`b0', copy)
			}
		}
		mat `b0'			= e(b)
		_mkvec `b0', from(`b0', skip) col(`regnames')
	}
	else {
		_mkvec `b0', `from' col(`regnames') first err("from()")
	}

	*--------------------------------------------------*
	*** estimation ***
	mata: xtdpdbc_init_touse(`mopt', "`touse'")				// marker variable
	mata: xtdpdbc_init_by(`mopt', "`_dta[_TSpanel]'")		// panel identifier
// 	mata: xtdpdbc_init_time(`mopt', "`_dta[_TStvar]'")		// time identifier
	mata: xtdpdbc_init_depvar(`mopt', "`depvar'")			// dependent variable
	if "`constant'" != "" {
		mata: xtdpdbc_init_cons(`mopt', "off")				// constant term
	}
	mata: xtdpdbc_init_indepvars(`mopt', "`indepvars'")		// independent variables
	if "`fe'" == "" & `: word count `indepvars'' > `lags' {
		mata: xtdpdbc_init_exopos(`mopt', 1, st_matrix("`exopos'"))		// exogenous variables
		if "`teffects'" != "" {
			mata: xtdpdbc_init_exopos(`mopt', 0, st_matrix("`exopos0'"))		// exogenous variables excluding time dummies
		}
	}
	if "`vce'" == "robust" {
		mata: xtdpdbc_init_vcetype(`mopt', "robust")		// VCE type
	}
	else if "`vce'" == "unadjusted" {
		mata: xtdpdbc_init_vce_adj(`mopt', "no")			// VCE adjustment for bias correction
	}
	if `csd' {
		mata: xtdpdbc_init_vce_csd(`mopt', "yes")			// VCE robust to cross-sectional dependence
	}
	mata: xtdpdbc_init_coefs(`mopt', st_matrix("`b0'"))		// initial coefficient vector
	if "`correction'" != "" {
		mata: xtdpdbc_init_bc(`mopt', "no")					// uncorrected estimation
	}
	di _n as txt "Bias-corrected estimation"
	mata: xtdpdbc(`mopt')

	mata: st_numscalar("r(reconv)", xtdpdbc_result_reinit_converged(`mopt'))
	if !r(reconv) {
		di as err "correct solution not found -- try alternative initial values"
// 		if "`force'" == "" {
// 			exit 498
// 		}
	}
	mata: st_numscalar("r(N)", xtdpdbc_result_N(`mopt'))
	mata: st_numscalar("r(N_g)", xtdpdbc_result_Ng(`mopt'))
	mata: st_numscalar("r(rank)", xtdpdbc_result_rank(`mopt'))
	mata: st_numscalar("r(maxeig)", xtdpdbc_result_maxeig(`mopt'))
	mata: st_matrix("r(b)", xtdpdbc_result_coefs(`mopt'))
	mata: st_matrix("r(V)", xtdpdbc_result_V(`mopt'))
	mata: st_matrix("r(V_modelbased)", xtdpdbc_result_V_oim(`mopt'))
	loc N				= r(N)
	loc N_g				= r(N_g)
	loc rank			= r(rank)
	loc maxeig			= r(maxeig)
	tempname b V V0 log
	mat `b'				= r(b)
	mat `V'				= r(V)
	mat `V0'			= r(V_modelbased)
	mat `log'			= r(log)
	if "`small'" != "" {
		loc df				= `N_g' - 1
		mat `V'				= `N_g' / `df' * (`N' - 1) / (`N' - `rank') * `V'
	}
	mat coln `b'		= `regnames'
	mat rown `V'		= `regnames'
	mat coln `V'		= `regnames'
	mat rown `V0'		= `regnames'
	mat coln `V0'		= `regnames'

	*--------------------------------------------------*
	*** estimation results ***
	if "`small'" != "" {
		loc small			"dof(`df')"
	}
	if `fv' {
		loc fvopt			"buildfv"
	}
	eret post `b' `V', dep(`depvar') o(`N') `small' e(`touse') `fvopt' findomitted
	eret sca N_g		= `N_g'
	mata: st_numscalar("e(g_min)", xtdpdbc_result_Tmin(`mopt'))
	eret sca g_avg		= e(N) / e(N_g)
	mata: st_numscalar("e(g_max)", xtdpdbc_result_Tmax(`mopt'))
	mata: st_numscalar("e(f)", xtdpdbc_result_value(`mopt'))
	if "`fe'" == "" {
		mata: st_numscalar("e(chi2_J)", xtdpdbc_result_overid(`mopt'))
	}
	eret sca rank		= `rank'
	mata: st_numscalar("e(zrank)", xtdpdbc_result_zrank(`mopt', 1))
	if "`teffects'" != "" & "`fe'" == "" {
		mata: st_numscalar("e(zrank_a)", xtdpdbc_result_zrank(`mopt', 0))
	}
	eret sca lags		= `lags'
	if "`vce'" != "robust" & "`onestep'" != "" {
		mata: st_numscalar("e(sigma2e)", xtdpdbc_result_sigma2(`mopt'))
	}
	eret sca steps		= ("`onestep'" == "") + 1
	mata: st_numscalar("e(ic)", xtdpdbc_result_iterations(`mopt'))
	mata: st_numscalar("e(converged)", xtdpdbc_result_converged(`mopt'))
	eret sca maxeig		= `maxeig'
	if "`vce'" == "robust" {
		if `csd' {
			eret loc vcetype	"CSD-Robust"
		}
		else {
			eret loc vcetype	"Robust"
		}
	}
	else if `csd' {
		eret loc vcetype	"CSD"
	}
	eret loc vce		"`vce'"
	if "`fe'`re'" != "" {
		eret loc model		"`fe'`re'"
	}
	else {
		eret loc model		"hybrid(`: list retok hybrid')"
	}
	eret loc teffects	"`teffects'"
	mata: st_matrix("e(ilog)", xtdpdbc_result_iterationlog(`mopt'))
	eret mat V_modelbased	= `V0'
end


*==================================================*
**** display of estimation results ****
program define xtdpdbc_display
	version 12.1
	syntax [, noOMITted noHEader noTABle *]

	if "`header'" == "" {
		di _n as txt "Group variable: " as res abbrev("`e(ivar)'", 12) _col(46) as txt "Number of obs" _col(68) "=" _col(70) as res %9.0f e(N)
		di as txt "Time variable: " as res abbrev("`e(tvar)'", 12) _col(46) as txt "Number of groups" _col(68) "=" _col(70) as res %9.0f e(N_g)
		if "`e(model)'" == "fe" {
			di _n as txt "Fixed-effects" _c
		}
		else if "`e(model)'" == "re" {
			di _n as txt "Random-effects" _c
		}
		else {
			di _n as txt "Hybrid" _c
		}
		di " model" _col(46) as txt "Obs per group:" _col(64) "min =" _col(70) as res %9.0g e(g_min)
		di _col(64) as txt "avg =" _col(70) as res %9.0g e(g_avg)
		di _col(64) as txt "max =" _col(70) as res %9.0g e(g_max)
	}
	if "`table'" == "" {
		di ""
		_coef_table, `options'
	}
end

*==================================================*
**** syntax parsing of additional display options ****
program define xtdpdbc_parse_display, sclass
	version 12.1
	sret clear
	syntax , [noHEader noTABle PLus *]
	_get_diopts diopts options, `options'

	sret loc diopts		`"`header' `table' `plus' `diopts'"'
	sret loc options	`"`options'"'
end

*==================================================*
**** syntax parsing of the optimization options ****
program define xtdpdbc_mm_init, sclass
	version 12.1
	sret clear
	loc maxiter			= c(maxiter)
	syntax [,	METHOD(string)						///
				CONCentration						///
				REINit(integer 10)					///
				EIGTOLerance(real 0)				///
				ITERate(integer `maxiter')			///
				noLOg								///
				SHOWSTEP							///
				SHOWTOLerance						///
				TOLerance(real 1e-6)				///
				LTOLerance(real 1e-7)				///
				NRTOLerance(real 1e-5)				///
				NONRTOLerance						///
				RE									///
				HYbrid(passthru)					///
				*]

	tempname isinit
	sca `isinit'		= 1
	loc j				= 1
	while `isinit' {
		mata: st_numscalar("`isinit'", findexternal("xtdpdbc_opt_`j'") != J(1, 1, NULL))
		if `isinit' {
			loc ++j
		}
		else {
			loc mopt			"xtdpdbc_opt_`j'"
			mata: `mopt' = xtdpdbc_init()
		}
	}
	if `"`method'"' == "" {
		loc method			"q1"
	}
	else {
		loc method			: subinstr loc method "quadratic" "q", all
		loc methods			"q0 q1 q1debug"
		if `: word count `method'' > 1 | !`: list method in methods' {
			di as err "option method() incorrectly specified -- invalid evaluator type"
			exit 198
		}
	}
	mata: xtdpdbc_init_evaluatortype(`mopt', "`method'")
	if "`concentration'" != "" {
		if `"`re'`hybrid'"' != "" {
			di as err "option concentration not allowed with options re or hybrid()"
			exit 198
		}
		mata: xtdpdbc_init_concentrate(`mopt', "on")
	}
	mata: xtdpdbc_init_reinit(`mopt', `reinit')
	mata: xtdpdbc_init_reinit_tol(`mopt', `eigtolerance')
	mata: xtdpdbc_init_conv_maxiter(`mopt', `iterate')
	mata: xtdpdbc_init_conv_ptol(`mopt', `tolerance')
	mata: xtdpdbc_init_conv_vtol(`mopt', `ltolerance')
	if "`nonrtolerance'" == "" {
		mata: xtdpdbc_init_conv_nrtol(`mopt', `nrtolerance')
	}
	else {
		mata: xtdpdbc_init_conv_ignorenrtol(`mopt', "on")
	}
	if "`log'" != "" {
		mata: xtdpdbc_init_tracelevel(`mopt', "none")
	}
	if "`showstep'" != "" {
		mata: xtdpdbc_init_trace_step(`mopt', "on")
	}
	if "`showtolerance'" != "" {
		mata: xtdpdbc_init_trace_tol(`mopt', "on")
	}

	sret loc mopt		"`mopt'"
	sret loc method		`"`method'"'
	sret loc options	`"`re' `hybrid' `options'"'
end

*==================================================*
**** sample identification ****
program define xtdpdbc_sample, rclass
	version 12.1
	syntax varname(num) , DEPvar(varname num ts) LAgs(integer)

	if `lags' < 1 {
		di as err "option lags() incorrectly specified -- outside of allowed range"
		exit 198
	}
	cap xtdes if `varlist'
	if _rc == 459 {
		error 2000
	}
	loc N_g				= r(N)
	tempvar consec maxconsec obstotal
	qui gen `consec' = .
	qui by `_dta[_TSpanel]': replace `consec' = cond(L.`consec' == ., 1, L.`consec' + 1) if `varlist'
	qui by `_dta[_TSpanel]': egen `maxconsec' = max(`consec')
	qui by `_dta[_TSpanel]': egen `obstotal' = total(`varlist')
	qui replace `varlist' = 0 if `maxconsec' != `obstotal'			// markout groups with gaps
	qui replace `varlist' = 0 if `obstotal' < 2 * `lags' + 1		// markout groups with insufficient number of observations
	cap xtdes if `varlist'
	if _rc == 459 {
		error 2000
	}
	loc balanced		= (r(min) == r(max))
	if r(N) != `N_g' {
		di as txt "note: " as res `N_g' - r(N) as txt " groups are dropped due to gaps or insufficient number of observations"
	}
	markout `varlist' L(1/`lags').`depvar'

	ret sca balanced	= `balanced'
end

*==================================================*
**** detection of collinear variables ****
program define xtdpdbc_col, sclass
	version 12.1
	sret clear
	syntax anything(id="varlist") [if] [in], depvar(varname num ts) [HYbrid(string) noCONStant]

	_rmdcoll `depvar' `anything' `if' `in', exp `constant'
	loc indepvars		"`r(varlist)'"

	*--------------------------------------------------*
	*** time-invariant regressors ***
	foreach var in `anything' {
		tempvar aux sd
		qui gen `aux' = `var' `if' `in'
		qui by `_dta[_TSpanel]': egen `sd' = sd(`aux') `if' `in'
		sum `sd' `if' `in', mean
		if r(mean) == 0 & !`: list var in hybrid' {
			fvexpand o.`var'
			loc indepvars		: subinstr loc indepvars "`var'" "`r(varlist)'", w
		}
	}

	sret loc indepvars		"`indepvars'"
	sret loc depvar			"`depvar'"
end

*==================================================*
**** syntax parsing for variance-covariance matrix ****
program define xtdpdbc_parse_vce, sclass
	version 12.1
	syntax , BALANCED(integer) [VCE(passthru)]

	cap _vce_parse , opt(CONVENTIONAL UNadjusted Robust) : , `vce'
	if "`r(vce)'" == "" {
		cap _vce_parse , : , `vce'
	}
	if _rc != 0 {
		cap _vce_parse , argopt(CONVENTIONAL UNadjusted Robust) : , `vce'
		if _rc != 0 {
			_vce_parse , : , `vce'
		}
		loc vceargs			"`r(vceargs)'"
		loc vceargs			: subinstr loc vceargs "," ""
		loc vceargs			: list retok vceargs
		if "`vceargs'" == "csd" {
			if !`balanced' {
				di as err "option csd not allowed with unbalanced panel data"
				exit 459
			}
			loc csd				"csd"
		}
		else if "`vceargs'" != "" {
			di as err "option vce() incorrectly specified"
			exit 198
		}
	}
	loc vce				"`r(vce)'"

	sret loc csd		"`csd'"
	if "`vce'" == "" {
		sret loc vce		"conventional"
	}
	else {
		sret loc vce		"`vce'"
	}
end

*==================================================*
*** version history ***
* version 1.3.0  26may2022  bug with calculation of maximum eigenvalue fixed; automatic reinitialization if convergence to an incorrect solution
* version 1.2.1  09apr2022  bug fixed that was introduced in version 1.2.0
* version 1.2.0  08apr2022  options re and hybrid() added; option vce(unadjusted) added; postestimation commands estat serial, estat overid, and estat hausman added; collinearity check added; bug fixed with option concentration; bug fixed with option scores of predict
* version 1.1.0  30jul2021  factor variables supported; option small added
* version 1.0.0  16jul2021  available online at www.kripfganz.de
* version 0.3.1  13jul2021
* version 0.3.0  12jul2021
* version 0.2.3  17mar2021
* version 0.2.2  24apr2019
* version 0.2.1  22mar2019
* version 0.2.0  17mar2019
* version 0.1.1  15aug2018
* version 0.1.0  13aug2018
* version 0.0.1  12aug2018
