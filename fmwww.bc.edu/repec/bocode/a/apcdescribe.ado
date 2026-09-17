*! APCDESCRIBE by Gordey Yastrebov, version 2.2, released 16.9.2026
/*******************************************************************************
A tool for producing descriptive diagnostic APC graphs.
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
- standardized confidence-interval syntax and handling across APCBOUND, APCPLOT, and APCDESCRIBE: "ci" requests confidence intervals, while level() specifies the confidence level; the former ci() syntax is no longer supported
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

	version 14

	pr de apcdescribe, rclass
		syntax varlist(min=1 max=1 numeric) [if] [in] [aw fw pw iw], ///
			[A(string asis) /// age variable + specification
			 P(string asis) /// period variable + specification
			 C(string asis) /// cohort variable + specification
			 Binpos(string) /// bin positioning for grouped data
			 ci /// request confidence intervals
			 Level(numlist min=1 max=1) /// confidence level
			 RECASTci(string) /// CI rendering
			 LIneops(string asis) /// common estimate-line and marker options
			 ALIneops(string asis) /// age-specific estimate-line and marker options
			 PLIneops(string asis) /// period-specific estimate-line and marker options
			 CLIneops(string asis) /// cohort-specific estimate-line and marker options
			 CIPLotops(string asis) /// common CI-layer options
			 ACIPLotops(string asis) /// age-specific CI-layer options
			 PCIPLotops(string asis) /// period-specific CI-layer options
			 CCIPLotops(string asis) /// cohort-specific CI-layer options
			 PLotops(string asis) /// common graph options
			 APLotops(string asis) /// age-specific graph options
			 PPLotops(string asis) /// period-specific graph options
			 CPLotops(string asis) /// cohort-specific graph options
			 COMBined /// combine requested plots
			 COMBPLotops(string asis)] // combined graph options

	loc depvar `varlist'
	marksample touse

*** Parse common options
	loc binpos = lower(strtrim(`"`binpos'"'))
	if `"`binpos'"' == "" loc binpos center
	if !inlist(`"`binpos'"', "center", "mean") {
		di as err "Option {bf:binpos()} must be either {bf:center} or {bf:mean}."
		exit 198
	}
	loc no_ci = ("`ci'" == "")
	loc level_specified = ("`level'" != "")
	if `level_specified' & `no_ci' {
		di as err "Option {bf:level()} requires option {bf:ci}."
		exit 198
	}
	if `level_specified' {
		if `level' <= 0 | `level' >= 100 {
			di as err "Confidence level must be greater than 0 " ///
				"and less than 100."
			exit 198
		}
	}
	loc ci_lvl .
	if !`no_ci' {
		if `level_specified' loc ci_lvl = `level'
		else loc ci_lvl = c(level)
	}
	loc recastci = lower(strtrim(`"`recastci'"'))
	if `no_ci' & `"`recastci'"' != "" {
		di as err "Option {bf:recastci()} requires option {bf:ci}."
		exit 198
	}
	if !`no_ci' {
		if `"`recastci'"' == "" loc recastci rarea
		if !inlist(`"`recastci'"', "rcap", "rspike", "rline", "rarea") {
			di as err "Option {bf:recastci()} must be {bf:rcap}, {bf:rspike}, {bf:rline}, or {bf:rarea}."
			exit 198
		}
		if inlist(`"`weight'"', "pweight", "iweight") {
			di as err "Option {bf:ci} is not supported with probability or importance weights."
			exit 198
		}
	}
	else if `"`ciplotops'`aciplotops'`pciplotops'`cciplotops'"' != "" {
		di as err "CI styling options require option {bf:ci}."
		exit 198
	}
	loc combined = (`"`combined'"' != "")
	if !`no_ci' di as txt "`ci_lvl'% confidence intervals assumed."

*** Parse requested APC dimensions
	loc selection
	foreach apcvar in a p c {
		if strtrim(`"``apcvar''"') != "" loc selection `selection' `apcvar'
	}
	if `"`selection'"' == "" {
		di as err "At least one of {bf:a()}, {bf:p()}, or {bf:c()} must be specified."
		exit 198
	}
	loc has_lpoly 0
	foreach apcvar of loc selection {
		loc spec = strtrim(`"``apcvar''"')
		loc colon = strpos(`"`spec'"', ":")
		loc rawvar
		loc rawcuts
		loc method means
		loc lpolyopts
		loc lpoly_ciopts 0
		if `colon' {
			loc rawvar = strtrim(substr(`"`spec'"', 1, `colon' - 1))
			loc rhs    = strtrim(substr(`"`spec'"', `colon' + 1, .))
			if `"`rawvar'"' == "" | `"`rhs'"' == "" {
				di as err "Option {bf:`apcvar'()} is incorrectly specified."
				exit 198
			}
			loc comma = strpos(`"`rhs'"', ",")
			if `comma' {
				loc rhs_head = strtrim(substr(`"`rhs'"', 1, `comma' - 1))
				loc rhs_opts = strtrim(substr(`"`rhs'"', `comma' + 1, .))
				if `"`rhs_opts'"' == "" {
					di as err "No options were specified after the comma in {bf:`apcvar'(`spec')}."
					exit 198
				}
			}
			else {
				loc rhs_head `rhs'
				loc rhs_opts
			}
			if lower(`"`rhs_head'"') == "lpoly" {
				loc method lpoly
				loc has_lpoly 1
				if `"`rhs_opts'"' != "" {
					cap noi _apcdescribe_parse_lpoly, `rhs_opts'
					if _rc exit _rc

					loc lpolyopts `"`r(options)'"'
					loc lpoly_ciopts = r(ci_options)
				}
				if `no_ci' & `lpoly_ciopts' {
					di as err ///
						"Options {bf:pwidth()} and {bf:var()} within an {bf:lpoly} specification require option {bf:ci}."
					exit 198
				}
			}
			else {
				if `comma' {
					di as err ///
						"A comma within {bf:`apcvar'()} is allowed only after the {bf:lpoly} method."
					exit 198
				}
				loc method grouped
				loc rawcuts `rhs'
			}
		}
		else loc rawvar `spec'
		cap unab xvar : `rawvar'
		if _rc {
			di as err "Variable {bf:`rawvar'} specified in {bf:`apcvar'()} not found."
			exit 111
		}
		if `: word count `xvar'' != 1 {
			di as err "Specification {bf:`rawvar'} in {bf:`apcvar'()} must identify one variable."
			exit 198
		}
		cap conf numeric var `xvar'
		if _rc {
			di as err "Variable {bf:`xvar'} specified in {bf:`apcvar'()} must be numeric."
			exit 109
		}
		loc `apcvar'var `xvar'
		loc `apcvar'method `method'
		loc `apcvar'cuts
		loc `apcvar'lpolyopts `"`lpolyopts'"'
		if `"`method'"' == "grouped" {
			cap numlist `"`rawcuts'"'
			if _rc {
				di as err ///
					"The specification after the colon in {bf:`apcvar'()} must be either {bf:lpoly} or a valid numlist."
				exit 198
			}
			loc cuts `r(numlist)'
			loc ncuts : word count `cuts'
			if `ncuts' < 2 {
				di as err "The numlist in {bf:`apcvar'()} must contain at least two cut points."
				exit 198
			}
			forv j = 2/`ncuts' {
				loc k = `j' - 1
				loc prev : word `k' of `cuts'
				loc curr : word `j' of `cuts'
				if `curr' <= `prev' {
					di as err "Cut points in {bf:`apcvar'()} must be strictly increasing."
					exit 198
				}
			}
			loc `apcvar'cuts `cuts'
		}
	}
	if `has_lpoly' & inlist(`"`weight'"', "pweight", "iweight") {
		di as err ///
			"Local-polynomial descriptive curves are not supported with probability or importance weights."
		exit 198
	}

*** Generate inputs and plots
	loc wgt
	if `"`weight'"' != "" loc wgt [`weight'`exp']
	loc a_title Age
	loc p_title Period
	loc c_title Cohort
	tempname a_input p_input c_input
	loc nplots : word count `selection'
	loc suppress = (`combined' & `nplots' > 1)
	loc plots
	foreach apcvar of loc selection {
		loc method "``apcvar'method'"
		loc dim_lpolyopts `"``apcvar'lpolyopts'"'
		if `"`method'"' == "lpoly" {
			loc lp_arg
			if `"`dim_lpolyopts'"' != "" loc lp_arg lpolyopts(`dim_lpolyopts')
			loc ci_arg
			if !`no_ci' loc ci_arg cilevel(`ci_lvl')
			_apcdescribe_build_lpoly_input `depvar' if `touse' `wgt', ///
				xvar(``apcvar'var') dimension(``apcvar'_title') ///
				no_ci(`no_ci') `lp_arg' `ci_arg'
		}
		else {
			loc opts xvar(``apcvar'var') binpos(`binpos') ///
				dimension(``apcvar'_title') no_ci(`no_ci')
			if `"`method'"' == "grouped" loc opts `opts' cuts(``apcvar'cuts')
			if !`no_ci' loc opts `opts' cilevel(`ci_lvl')
			_apcdescribe_build_input `depvar' if `touse' `wgt', `opts'
		}
		mat ``apcvar'_input' = r(input)
		preserve
			qui clear
			cap qui svmat double ``apcvar'_input', names(col)
			loc rc = _rc
			if !`rc' {
				loc ci_layer
				if !`no_ci' loc ci_layer ///
					(`recastci' y_lower y_upper x_value, sort ///
					`ciplotops' ``apcvar'ciplotops')
				loc estimate_defaults
				if `"`method'"' == "lpoly" loc estimate_defaults msymbol(none)
				loc nodraw
				if `suppress' loc nodraw nodraw
				loc nameopt name(``apcvar'_title', replace)
				if `nplots' == 1 loc nameopt
				cap noi twoway `ci_layer' ///
					(scatter y_mean x_value, sort connect(l) ///
					`estimate_defaults' ///
					`lineops' ``apcvar'lineops'), ///
					yti("") xti(`"``apcvar'_title'"', height(7)) leg(off) ///
					`plotops' ``apcvar'plotops' `nameopt' `nodraw'
				loc rc = _rc
			}
		restore
		if `rc' exit `rc'
		loc plots `plots' ``apcvar'_title'
	}

*** Combine and return
	if `combined' & `nplots' > 1 gr combine `plots', ///
		r(1) ycom `combplotops'
	ret clear
	ret loc dimensions `selection'
	ret loc binpos `binpos'
	ret scalar ci = `ci_lvl'
	if !`no_ci' ret loc recastci `recastci'
	if `"`a'"' != "" {
		ret mat age = `a_input'
		ret loc age_method `amethod'
	}
	if `"`p'"' != "" {
		ret mat period = `p_input'
		ret loc period_method `pmethod'
	}
	if `"`c'"' != "" {
		ret mat cohort = `c_input'
		ret loc cohort_method `cmethod'
	}
		
	end

*** Routines: ******************************************************************

	pr de _apcdescribe_parse_lpoly, rclass
    /* One-letter abbreviations are accepted: k(), b(), d(), n(), p(), v().
       Optional numeric descriptors in syntax require defaults.  Capture the
       arguments as strings instead so that omission can be distinguished from
       any valid numeric value, then validate explicitly. */
		syntax [, Kernel(string) Bwidth(string) Degree(string) N(string) ///
			Pwidth(string) Var(string)]
		loc kernel = lower(strtrim(`"`kernel'"'))
		if `"`kernel'"' != "" & ///
			!inlist(`"`kernel'"', "epanechnikov", "epan2", "biweight", ///
			"cosine", "gaussian", "parzen", "rectangle", "triangle") {
			di as err ///
				"Option {bf:kernel()} must specify a kernel supported by Stata's {bf:lpoly} command."
			exit 198
		}
		/* bwidth() and var() accept either a number or a numeric variable. */
		foreach opt in bwidth var {
			loc value = strtrim(`"``opt''"')
			if `"`value'"' != "" {
				cap conf number `value'
				if !_rc {
					if `"`opt'"' == "bwidth" & `value' <= 0 {
						di as err "Option {bf:bwidth()} must be greater than zero."
						exit 198
					}
					if `"`opt'"' == "var" & `value' < 0 {
						di as err "Option {bf:var()} must be nonnegative."
						exit 198
					}
				}
				else {
					cap conf numeric var `value'
					if _rc {
						di as err ///
							"Option {bf:`opt'()} must contain one number or identify one numeric variable."
						exit 198
					}
				}
				loc `opt' `value'
			}
		}
		loc pwidth = strtrim(`"`pwidth'"')
		if `"`pwidth'"' != "" {
			cap conf number `pwidth'
			if _rc {
				di as err "Option {bf:pwidth()} must contain one numeric value."
				exit 198
			}
			if `pwidth' <= 0 {
				di as err "Option {bf:pwidth()} must be greater than zero."
				exit 198
			}
		}
		foreach opt in degree n {
			loc value = strtrim(`"``opt''"')
			if `"`value'"' != "" {
				cap conf number `value'
				if _rc | `value' != floor(`value') {
					di as err "Option {bf:`opt'()} must contain one integer."
					exit 198
				}
				if `"`opt'"' == "degree" & `value' < 0 {
					di as err "Option {bf:degree()} must be a nonnegative integer."
					exit 198
				}
				if `"`opt'"' == "n" & `value' <= 0 {
					di as err "Option {bf:n()} must be a positive integer."
					exit 198
				}
				loc `opt' `value'
			}
		}
		loc options
		if `"`kernel'"' != "" loc options `options' kernel(`kernel')
		if `"`bwidth'"' != "" loc options `options' bwidth(`bwidth')
		if `"`degree'"' != "" loc options `options' degree(`degree')
		if `"`n'"' != "" loc options `options' n(`n')
		if `"`pwidth'"' != "" loc options `options' pwidth(`pwidth')
		if `"`var'"' != "" loc options `options' var(`var')
		loc ci_options = (`"`pwidth'"' != "" | `"`var'"' != "")
		ret loc options `"`options'"'
		ret scalar ci_options = `ci_options'
	end

	pr de _apcdescribe_build_lpoly_input, rclass
		syntax varlist(min=1 max=1 numeric) [if] [in] [aw fw], ///
			XVAR(varname numeric) DIMENSION(string) no_ci(integer) ///
			[CILEVEL(real 95) LPOLYOPTS(string asis)]
		loc depvar `varlist'
		marksample sample
		loc wgt
		if `"`weight'"' != "" loc wgt [`weight'`exp']
		preserve
			qui keep if `sample'
			qui drop if mi(`depvar', `xvar')
			qui count
			if !r(N) {
				restore
				di as err "No observations remain for the `dimension' local-polynomial plot."
				exit 2000
			}
			tempvar x_value x_label y_mean y_se y_lower y_upper
			loc seopt
			if !`no_ci' loc seopt se(`y_se')
			cap qui lpoly `depvar' `xvar' `wgt', ///
				generate(`x_value' `y_mean') `seopt' nograph `lpolyopts'
			loc rc = _rc
			if `rc' {
				restore
				exit `rc'
			}
			qui keep if !mi(`x_value', `y_mean')
			qui count
			if !r(N) {
				restore
				di as err ///
					"The local-polynomial estimator produced no usable values for the `dimension' plot."
				exit 2000
			}
			qui gen double `x_label' = `x_value'
			qui gen double `y_lower' = .
			qui gen double `y_upper' = .
			if !`no_ci' {
				loc alpha2 = (100 - `cilevel') / 200
				loc zcrit = invnormal(1 - `alpha2')
				qui replace `y_lower' = `y_mean' - `zcrit' * `y_se' ///
					if !mi(`y_se')
				qui replace `y_upper' = `y_mean' + `zcrit' * `y_se' ///
					if !mi(`y_se')
			}
			qui sort `x_value'
			tempname input
			cap qui mkmat `x_value' `x_label' `y_mean' `y_lower' `y_upper', ///
				mat(`input')
			loc rc = _rc
			if `rc' {
				restore
				exit `rc'
			}
			mat colnames `input' = x_value x_label y_mean y_lower y_upper
		restore
		ret mat input = `input'
	end

	pr de _apcdescribe_build_input, rclass
		syntax varlist(min=1 max=1 numeric) [if] [in] [aw fw pw iw], ///
			XVAR(varname numeric) BINPOS(string) DIMENSION(string) no_ci(integer) ///
			[CUTS(string asis) CILEVEL(real 95)]
		loc depvar `varlist'
		marksample sample
		loc grouped = (`"`cuts'"' != "")
		loc wgt
		if `"`weight'"' != "" loc wgt [`weight'`exp']
		preserve
			qui keep if `sample'
			qui drop if mi(`xvar')
			tempvar group x_value x_label y_mean y_se n y_lower y_upper
			if `grouped' {
				cap qui egen long `group' = cut(`xvar'), at(`cuts') icodes
				loc rc = _rc
				if `rc' {
					restore
					exit `rc'
				}
				qui drop if mi(`group')
			}
			else qui clonevar `group' = `xvar'
			qui count
			if !r(N) {
				restore
				di as err "No observations remain for the `dimension' descriptive plot."
				exit 2000
			}
			loc xpos
			if `grouped' & `"`binpos'"' == "mean" loc xpos `x_value' = `xvar'

			if `no_ci' {
				cap qui collapse (mean) `y_mean' = `depvar' `xpos' `wgt', ///
					by(`group')
			}
			else {
				cap qui collapse ///
					(mean)   `y_mean' = `depvar' `xpos' ///
					(semean) `y_se'   = `depvar' ///
					(count)  `n'      = `depvar' `wgt', by(`group')
			}
			loc rc = _rc
			if `rc' {
				restore
				exit `rc'
			}
			if `grouped' {
				qui gen double `x_label' = .
				loc nbins = `: word count `cuts'' - 1
				forv j = 1/`nbins' {
					loc next = `j' + 1
					loc lower : word `j' of `cuts'
					loc upper : word `next' of `cuts'
					loc code = `j' - 1
					qui replace `x_label' = (`lower' + `upper') / 2 ///
						if `group' == `code'
				}
				if `"`binpos'"' == "center" ///
					qui gen double `x_value' = `x_label'
			}
			else {
				qui gen double `x_value' = `group'
				qui gen double `x_label' = `group'
			}
			qui gen double `y_lower' = .
			qui gen double `y_upper' = .
			if !`no_ci' {
				loc alpha2 = (100 - `cilevel') / 200
				qui replace `y_lower' = ///
					`y_mean' - invttail(`n' - 1, `alpha2') * `y_se' ///
					if `n' >= 2 & !mi(`y_se')
				qui replace `y_upper' = ///
					`y_mean' + invttail(`n' - 1, `alpha2') * `y_se' ///
					if `n' >= 2 & !mi(`y_se')
			}
			qui sort `x_value'
			tempname input
			cap qui mkmat `x_value' `x_label' `y_mean' `y_lower' `y_upper', ///
				mat(`input')
			loc rc = _rc
			if `rc' {
				restore
				exit `rc'
			}
			mat colnames `input' = x_value x_label y_mean y_lower y_upper
		restore
		ret mat input = `input'
	end
