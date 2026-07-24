/*******************************************************************************
APCEST: An estimation wrapper command to facilitate Fosse-Winship bounding 
approach to APC analysis.
********************************************************************************
Version: 2.0 (23.7.2026)
Author: Gordey Yastrebov, University of Cologne
License: GPL-3.0
*******************************************************************************/

	pr de apcest, eclass properties(prefix)
		version 14

*** Parse APCEST options and estimation command
	cap _on_colon_parse `0'
	if _rc {
		di as err "Estimation command must be specified after a colon."
		exit 198
	}
	loc apcest_options `"`s(before)'"'
	loc estimation_cmd `"`s(after)'"'
	if `"`estimation_cmd'"' == "" {
		di as err "Estimation command must be specified after a colon."
		exit 198
	}
	loc 0 `"`apcest_options'"'
	syntax, a(string) p(string) c(string)

*** Cleans previous APCEST estimation output (if any)
	cap est drop __apcestimates
	foreach est in esample a p c {
		cap drop __apcest_`est'
	}

*** Parse APC variable specification arguments 
	foreach v in a p c {
	* categorical argument defined as "i.anything/ib.anything"
		if strpos("``v''", ".") {
			loc dotpos = strpos("``v''", ".")
			loc varname = substr("``v''", `dotpos' + 1, .)
			loc prefix = substr("``v''", 1, `dotpos' - 1)
			unab `v'varname : `varname'
			__apcest_confirm_exists ``v'varname'
			loc `v'spec `prefix'.__apcest_`v'
			loc `v'continuous = 0
		}
	* categorical argument defined as "var:numlist"
		else if strpos("``v''", ":") {
			loc colonpos = strpos("``v''", ":")
			loc varname = substr("``v''", 1, `colonpos' - 1)
			unab `v'varname : `varname'
			__apcest_confirm_exists ``v'varname'
			loc `v'spec // defined later below
			loc `v'continuous = 0
		}
	* polynomial argument ("var^#"):
		else if strpos("``v''", "^") { 
			loc hatpos = strpos("``v''", "^")
			loc varname = substr("``v''", 1, `hatpos' - 1)
			loc power = real(substr("``v''", `hatpos' + 1, .))
			unab `v'varname : `varname'
			__apcest_confirm_exists ``v'varname'
			__apcest_check_power `power'
			loc `v'spec 
			loc term c.__apcest_`v'#c.__apcest_`v'
			forv i=2/`power' {
				loc `v'spec ``v'spec' `term'
				loc term `term'#c.__apcest_`v'
			}
			loc `v'continuous = 1
		}
	* linear argument:
		else {
			unab `v'varname : ``v''
			__apcest_confirm_exists ``v'varname'
			loc `v'spec
			loc `v'continuous = 1
		}
	}

*** Parse the estimation command
	gettoken cmd model : estimation_cmd
	if "`cmd'" == "" | `"`model'"' == "" {
		di as err "Invalid estimation command."
		exit 198
	}

* isolate random-effects equations, if any
	loc pipepos = strpos(`"`model'"', "||")
	if `pipepos' {
		loc fixed_part = substr(`"`model'"', 1, `pipepos' - 1)
		loc random_part = substr(`"`model'"', `pipepos', .)
	}
	else {
		loc fixed_part `"`model'"'
		loc random_part
	}

* parse the fixed-effects equation
	loc 0 `"`fixed_part'"'
	syntax anything(name=vars) ///
		[if] [in] [aw fw pw iw] [, *]
	gettoken depvar indepvars : vars

	loc command_options
	if `"`options'"' != "" loc command_options `", `options'"'

*** Sanity check + estimation sample definition
	marksample ifin
	qui reg `depvar' `indepvars' `avarname' `cvarname' if `ifin'
	cap drop __apcest_esample
	qui g __apcest_esample = e(sample)

*** Generate estimation variables
	loc alabel age
	loc plabel period
	loc clabel cohort
	foreach v in a p c {
		if strpos("``v''", ".") qui g __apcest_`v' = ``v'varname' if __apcest_esample
		if strpos("``v''", ":") {
			loc colonpos = strpos("``v''", ":")
			loc numlist = substr("``v''", `colonpos' + 1, .)
			numlist "`numlist'", sort
			qui egen __apcest_`v' = cut(``v'varname') if __apcest_esample, at(`numlist')
			qui levelsof __apcest_`v', l(values)
			loc base = `:word `=ceil(`:word count `values''/2)' of `values''
			loc `v'spec ib`base'.__apcest_`v'
		}
		if ``v'continuous' {
			qui g __apcest_`v' = ``v'varname' if __apcest_esample
			qui sum __apcest_`v' 
			loc `v'center = r(mean)
			qui replace __apcest_`v' = __apcest_`v' - r(mean)
			loc `v'ref = 0
		}
		la var __apcest_`v' "APCEST ``v'label' estimation variable"
	}

*** Scale consistency check (rough)
	tempvar acheck pcheck ccheck
	qui g `acheck' = `pvarname' - `cvarname' if __apcest_esample
	qui g `pcheck' = `cvarname' + `avarname' if __apcest_esample
	qui g `ccheck' = `pvarname' - `avarname' if __apcest_esample
	foreach v in a p c {
		qui reg ``v'varname' ``v'check' if __apcest_esample `wgt'
		if !inrange(_b[``v'check'], .95, 1.05) {
			di as err "APC variables possibly inconsistently measured " ///
				"({help apcbound:help apcbound})."
			exit 459
		}
	}

*** Run estimation command and store estimates
	n `cmd' `depvar' __apcest_a __apcest_c `aspec' `pspec' `cspec' `indepvars' ///
		if __apcest_esample [`weight'`exp'] `command_options' `random_part'
	foreach v in a p c {
		if !``v'continuous' {
			loc colnames : colnames e(b)
			loc varname_length = strlen("__apcest_`v'")
			foreach colname of loc colnames {
				if strpos("`colname'", "b.__apcest_`v'") & ///
				(strlen("`colname'") - strpos("`colname'", ".__apcest_`v'")) == `varname_length' ///
					loc `v'ref = substr("`colname'", 1, strpos("`colname'", "b.") - 1)
				* identifies reference category for categorical variables
			}
		}
	}
	eret sca theta1 = _b[__apcest_a]
	eret sca theta2 = _b[__apcest_c]
	foreach v in a p c {
		foreach info in ref center {
			cap eret sca `v'`info' = ``v'`info''
		}
		foreach info in varname spec {
			cap eret loc `v'`info' = "``v'`info''"
		}
	}
	est sto __apcestimates
	drop _est___apcestimates
	la var __apcest_esample "APCEST estimation sample"

	end

*** Routines: ******************************************************************
	pr de __apcest_confirm_exists
		syntax varlist(min=1 max=1)
		cap conf v `varlist'
		if _rc {
			di as error "Variable {bf:`varlist'} not found."
			exit 111
		}
	end

	pr de __apcest_check_power
		args power
		cap conf n `power'
		if _rc | floor(`power') != `power' | `power' <= 1 | mi(`power') {
			di as error "Power must be an integer greater than one."
			exit 198
		}
	end