*! APCEST by Gordey Yastrebov, version 2.2, 16.9.2026
/*******************************************************************************
An estimation wrapper command to facilitate Fosse-Winship bounding
approach to APC analysis.
Author: Gordey Yastrebov, University of Cologne
License: GPL-3.0
********************************************************************************
PACKAGE VERSION HISTORY

Version 2.2 updates:
- assigned the default color line to be black (can be overridden by the shapeplotops() options) in APCPLOT
- fixed the bug preventing the use of the name() option within the combplotops() option in APCPLOT and APCDESCRIBE
- fixed APCPLOT and APCDESCRIBE to prevent it from clearing the graphs window with every run
- made APCPLOT position categorical APC effects at the mean value of the original APC variable within each category rather than at the category code or lower cutpoint
- standardized confidence level handling across APCBOUND, APCDESCRIBE, and APCPLOT ("ci" and "level()" options)
- revised APCEST to separate linear APC components from grouped/categorical nonlinear representations, centered the original APC variables on the estimation sample while preserving the exact APC identity, introduced dedicated nonlinear working variables, and updated APCBOUND and APCPLOT accordingly, including correct original-scale handling of grouped specifications in APCPLOT
- updated all documentation files in line with the changes

Version 2.1 updates:
- added support for visualizing semi-bounded solutions in APCPLOT, with fading gradients extending from the finite boundary
- added the fadespeed() and fadewidth() options to APCPLOT to control the appearance of semi-bounded solution plots; removed the redundant gridfading() option
- revised confidence-interval syntax and handling in APCPLOT: "ci" now requests confidence intervals, while level() specifies the confidence level; the former ci() option is no longer supported
- added further input validation and more informative error messages across APCBOUND, APCPLOT, and APCDESCRIBE
- made minor optimization and consistency fixes across the commands and documentation files

Version 2.0 updates:
- fixed incorrect matching of categorical APC coefficients in APCEST and APCPLOT when variable names overlap (e.g., "year" and "yearofbirth")
- fixed a bug preventing APCPLOT from retrieving bounded solutions when custom estimates were specified in APCBOUND
- added the matrix() option to APCPLOT for storing point-estimate and confidence-interval-adjusted plot values as matrices
- changed the grid option rendering in APCPLOT to allow unique colors for negative and positive offsets
- added APCDESCRIBE subcommand for producing descriptive APC plots (including the documentation file)
- fixed the incorrect derivation of the theta_2 value with ap() custom estimate specification in APCBOUND
- redefined the syntax for APCEST (optimized to accommodate a broader range of estimation commands than previously afforded)
- minor optimization and consistency fixes to APCPLOT and APCBOUND
- minor updates to APCEST, APCBOUND and APCPLOT documentation files

Version 1.3 updates:
- required Stata version downgraded to 14
- fixed the behavior of [if] and [in] conditions in APCEST in how it is applied in variable centering
- added estimation sample variable after APCEST (used by APCPLOT)
- corrected the error breaking the execution of APCBOUND under implausible constraints
- corrected the returned scalar names for the bounds after APCBOUND to match those in the documentation
- corrected the formulas for calculating the specific solution, when a single parameter is specified in APCPLOT
- minor updates to APCEST, APCBOUND and APCPLOT documentation files

Version 1.2 updates:
- added the "info" option to APCPLOT and its documentation
- changed the default gradient area palette to rainbow colors (CET R1) in APCPLOT
- corrected the description of "grid()" option in APCPLOT
- corrected the functioning of the "nogradient" option in APCPLOT
- fixed the bug with "areapalette()" option in APCPLOT
- corrected APCPLOT documentation examples
- various minor accuracy updates to the commands' code and documentation

Version 1.1 updates:
- fixed the incorrect calculation of the bounded solutions adjusted for confidence intervals
- fixed the incorrect processing and visualization of linear-only APC effects by APCPLOT
- fixed the labelling of linear component parameters in the console output of APCPLOT when using "a()", "p()", or "c()" options
- fixed the bug in APCEST that created problems with the use of "if" option when conditioning on temporarily centered continuous APC variables
- added the option to specify two grid palettes for the separate rendering of positive and negative grid increments with APCPLOT (with corresponding edits in the documentation)
- updated documentation for APCEST, APCBOUND and APCPLOT with demonstration examples that work with Stata sample datasets
- added minor accuracy updates to APCEST documentation
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

*** Clean previous APCEST estimation output and working variables
	cap est drop __apcestimates
	foreach est in esample A P C nlA nlP nlC a p c {
		cap drop __apcest_`est'
	}

*** Parse APC variable specifications
	foreach v in a p c {
		if "`v'" == "a" {
			loc V A
			loc `v'label age
		}
		else if "`v'" == "p" {
			loc V P
			loc `v'label period
		}
		else {
			loc V C
			loc `v'label cohort
		}
		loc `v'linvar __apcest_`V'
		loc `v'nlvar  __apcest_nl`V'
		loc `v'numlist
		loc `v'power
		loc `v'prefix
		loc `v'spec
	* categorical argument defined as "i.anything/ib.anything"
		if strpos("``v''", ".") {
			loc dotpos = strpos("``v''", ".")
			loc varname = substr("``v''", `dotpos' + 1, .)
			loc prefix = substr("``v''", 1, `dotpos' - 1)
			unab `v'varname : `varname'
			__apcest_confirm_exists ``v'varname'
			loc `v'prefix `prefix'
			loc `v'type categorical
			loc `v'continuous = 0
		}
	* categorical argument defined as "var:numlist"
		else if strpos("``v''", ":") {
			loc colonpos = strpos("``v''", ":")
			loc varname = substr("``v''", 1, `colonpos' - 1)
			loc numlist = substr("``v''", `colonpos' + 1, .)
			unab `v'varname : `varname'
			__apcest_confirm_exists ``v'varname'
			numlist "`numlist'", sort
			loc `v'numlist `"`numlist'"'
			loc `v'type grouped
			loc `v'continuous = 0
		}
	* polynomial argument ("var^#")
		else if strpos("``v''", "^") {
			loc hatpos = strpos("``v''", "^")
			loc varname = substr("``v''", 1, `hatpos' - 1)
			loc power = real(substr("``v''", `hatpos' + 1, .))
			unab `v'varname : `varname'
			__apcest_confirm_exists ``v'varname'
			__apcest_check_power `power'
			loc `v'power = `power'
			loc `v'type polynomial
			loc `v'continuous = 1
		}
	* linear argument
		else {
			unab `v'varname : ``v''
			__apcest_confirm_exists ``v'varname'
			loc `v'type linear
			loc `v'continuous = 1
		}
	}

*** Parse the estimation command
	loc estimation_prefix
	loc estimation_base `"`estimation_cmd'"'
	loc 0 `"`estimation_cmd'"'
	cap _on_colon_parse `0'
	if !_rc {
		loc prefix_candidate `"`s(before)'"'
		loc estimator_candidate `"`s(after)'"'
		gettoken prefix_name prefix_rest : prefix_candidate, parse(",")
		loc prefix_name = lower(trim("`prefix_name'"))
		if "`prefix_name'" == "svy" {
			loc estimation_prefix `"`prefix_candidate'"'
			loc estimation_base `"`estimator_candidate'"'
		}
	}
	gettoken cmd model : estimation_base
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
	syntax anything(name=vars) [if] [in] [aw fw pw iw] [, *]
	gettoken depvar indepvars : vars
	loc command_options
	if `"`options'"' != "" loc command_options `", `options'"'

*** Define the preliminary estimation sample
	marksample ifin
	qui reg `depvar' `indepvars' `avarname' `pvarname' `cvarname' ///
		if `ifin' [`weight'`exp']
	cap drop __apcest_esample
	qui g byte __apcest_esample = e(sample)

*** Generate nonlinear APC representations where required
	foreach v in a p c {
		if "`v'" == "a" loc V A
		else if "`v'" == "p" loc V P
		else loc V C
		if "``v'type'" == "categorical" {
			qui g double __apcest_nl`V' = ``v'varname' if __apcest_esample
			loc `v'spec ``v'prefix'.__apcest_nl`V'
			la var __apcest_nl`V' ///
				"APCEST nonlinear ``v'label' variable"
		}
		else if "``v'type'" == "grouped" {
			qui egen __apcest_nl`V' = cut(``v'varname') ///
				if __apcest_esample, at(``v'numlist')
			qui replace __apcest_esample = 0 ///
				if mi(__apcest_nl`V') & __apcest_esample
			qui levelsof __apcest_nl`V' if __apcest_esample, l(values)
			loc base = `:word `=ceil(`:word count `values''/2)' of `values''
			loc `v'spec ib`base'.__apcest_nl`V'
			la var __apcest_nl`V' ///
				"APCEST grouped nonlinear ``v'label' variable"
		}
	}

*** Generate and mean-center the original numerical APC variables
	foreach v in a p c {
		if "`v'" == "a" loc V A
		else if "`v'" == "p" loc V P
		else loc V C
		qui g double __apcest_`V' = ``v'varname' if __apcest_esample
		qui sum __apcest_`V' if __apcest_esample, meanonly
		loc `v'center = r(mean)
		qui replace __apcest_`V' = __apcest_`V' - ``v'center' if __apcest_esample
		la var __apcest_`V' "APCEST centered ``v'label' variable"
	}

*** Build polynomial nonlinear specifications from centered APC variables
	foreach v in a p c {
		if "``v'type'" == "polynomial" {
			if "`v'" == "a" loc V A
			else if "`v'" == "p" loc V P
			else loc V C
			loc `v'spec
			loc term c.__apcest_`V'#c.__apcest_`V'
			forv i = 2/``v'power' {
				loc `v'spec ``v'spec' `term'
				loc term `term'#c.__apcest_`V'
			}
		}
	}

*** Check consistency of APC scales
	loc Aimplied "__apcest_P - __apcest_C"
	loc Pimplied "__apcest_A + __apcest_C"
	loc Cimplied "__apcest_P - __apcest_A"
	tempvar implied
	foreach V in A P C {
		qui g double `implied' = ``V'implied' if __apcest_esample
		qui reg __apcest_`V' `implied' if __apcest_esample
		if !inrange(_b[`implied'], .95, 1.05) {
			di as err "APC variables do not appear to be measured on consistent scales " ///
				"({help apcbound:help apcbound})."
			exit 459
		}
		drop `implied'
	}

*** Run estimation command and store estimates
	loc runprefix
	if `"`estimation_prefix'"' != "" loc runprefix `"`estimation_prefix':"'
	n `runprefix' `cmd' `depvar' __apcest_A __apcest_C ///
		`aspec' `pspec' `cspec' `indepvars' ///
		if __apcest_esample [`weight'`exp'] ///
		`command_options' `random_part'

*** Identify reference categories for categorical/grouped nonlinear components
	foreach v in a p c {
		if !``v'continuous' {
			if "`v'" == "a" loc V A
			else if "`v'" == "p" loc V P
			else loc V C
			loc colnames : colnames e(b)
			loc varname_length = strlen("__apcest_nl`V'")
			foreach colname of loc colnames {
				if strpos("`colname'", "b.__apcest_nl`V'") & (strlen("`colname'") ///
					- strpos("`colname'", ".__apcest_nl`V'")) == `varname_length' ///
					loc `v'ref = substr("`colname'", 1, strpos("`colname'", "b.") - 1)
			}
		}
		else loc `v'ref = 0
	}

*** Store APCEST results and metadata
	eret sca theta1 = _b[__apcest_A]
	eret sca theta2 = _b[__apcest_C]
	eret loc theta1spec "__apcest_A"
	eret loc theta2spec "__apcest_C"
	foreach v in a p c {
		cap eret sca `v'ref = ``v'ref'
		cap eret sca `v'center = ``v'center'
		eret loc `v'varname "``v'varname'"
		eret loc `v'spec "``v'spec'"
		eret loc `v'type "``v'type'"
		if "``v'numlist'" != "" eret loc `v'numlist "``v'numlist'"
		if "``v'power'" != "" eret sca `v'power = ``v'power'
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