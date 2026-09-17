*! APCPLOT by Gordey Yastrebov, version 2.2, released 16.9.2026
/*******************************************************************************
A tool for visualizing APC effects to facilitate Fosse-Winship bounding
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

	pr de apcplot
		syntax [anything(name=graphs)], /// APC effect selection option
		///
			[Bounded] /// plot bounded or semi-bounded solution
			[Keepshape] /// keep shapes
			[Info] /// display assumptions / bounds legend
			[Matrix(name)] /// store bounded-solution matrices
			[CI] /// plot confidence intervals
			[Level(numlist min=1 max=1)] /// confidence level when not inherited
			[a(numlist min=1 max=1)] /// exact linear components
			[p(numlist min=1 max=1)] ///
			[c(numlist min=1 max=1)] ///
			[PEAbounds(numlist min=2 max=2 miss)] /// custom p.-e. bounds
			[PEPbounds(numlist min=2 max=2 miss)] ///
			[PECbounds(numlist min=2 max=2 miss)] ///
			[CIAbounds(numlist min=2 max=2 miss)] /// custom c.-i. bounds
			[CIPbounds(numlist min=2 max=2 miss)] ///
			[CICbounds(numlist min=2 max=2 miss)] ///
		///
			[Grid(str)] /// diagnostic grid
			[GRIDLABels(str)] /// grid labels selection (off/right/left)
			[ANChorgrid] /// grid anchoring (A=-P=C)
			[gridlabops(str)] /// grid labels customization
			[gridline(str)] /// grid line decoration
			[GRIDPALette(str)] /// grid color palette
		///
			[NOGRadient] /// suppress gradient
			[GRADes(int 100)] /// gradient grades
			[FADESpeed(numlist min=1 max=1)] /// semi-bound fading-speed factor
			[FADEWidth(numlist min=1 max=1)] /// semi-bound artificial-range width
			[AREACONtour(str asis)] /// gradient area contour
			[AREAPALette(str)] /// gradient area color palette
		///
			[SHAPEPLotops(str asis)] /// shape line options
			[PLotops(str)] /// common plot options
			[APLotops(str asis)] /// APC-specific plot options
			[PPlotops(str asis)] ///
			[CPlotops(str asis)] ///
			[CIPLotops(str)] /// custom CI plot options
			[RECASTci(str)] /// custom CI rendering
			[COMBined] /// combine graphs
			[COMBPLotops(str asis)] // combined plot options

*** Variable symbols for printing
	loc a_letter α
	loc p_letter π
	loc c_letter γ
	loc nu_letter ν

*** Restore estimates from APCEST
	capture estimates restore __apcestimates
	if _rc {
		di as err "The return from {it:apcest} not found!"
		exit 301
	}

*** Parse all binary options
	foreach switch in bounded keepshape info anchorgrid nogradient combined ci {
		if "``switch''" != "" loc `switch' = 1
		else loc `switch' = 0
	}
	loc fadespeed_specified = ("`fadespeed'" != "")
	loc fadewidth_specified = ("`fadewidth'" != "")
	if (`fadespeed_specified' | `fadewidth_specified') & !`bounded' {
		di as err "Options {bf:fadespeed()} and {bf:fadewidth()} " ///
			"apply only to semi-bounded solutions and require {bf:bounded}."
		exit 198
	}
	if !`fadespeed_specified' loc fadespeed = 1
	if !`fadewidth_specified' loc fadewidth = 1
	if `grades' < 2 {
		di as err "Option {bf:grades()} must be an integer greater than or equal to 2."
		exit 198
	}
	if `fadespeed' <= 0 {
		di as err "Option {bf:fadespeed()} must be greater than 0."
		exit 198
	}
	if `fadewidth' <= 0 {
		di as err "Option {bf:fadewidth()} must be greater than 0."
		exit 198
	}

*** Parse custom bounds
	foreach est in pe ci {
		foreach apcvar in a p c {
			if "``est'`apcvar'bounds'" != "" {
				loc supplied ``est'`apcvar'bounds'
				loc custom_lower : word 1 of `supplied'
				loc custom_upper : word 2 of `supplied'
				if mi(`custom_lower') & mi(`custom_upper') {
					loc est_label = cond("`est'" == "pe", "point-estimate", "confidence-interval")
					di as err "Custom `est_label' bounds for ``apcvar'_letter' cannot be open at both endpoints."
					di as err "Omit the custom bounds option when no finite bound is available."
					exit 198
				}
			}
		}
	}

*** Parse which graphs requested
	loc graphs = strlower(strtrim(`"`graphs'"'))
	loc selection
	if `"`graphs'"' == "" loc selection a p c
	else {
		loc ngraphs : word count `graphs'
		if !inrange(`ngraphs', 1, 3) {
			di as err "Graph selection incorrectly specified."
			di as err "Specify one or more of {bf:A}, {bf:P}, and {bf:C}."
			exit 198
		}
		foreach graph of local graphs {
			if !inlist("`graph'", "a", "p", "c") {
				di as err "Invalid APC graph selection: {bf:`graph'}."
				di as err "Specify only {bf:A}, {bf:P}, and/or {bf:C}."
				exit 198
			}
			if strpos(" `selection' ", " `graph' ") {
				di as err "APC graph {bf:`graph'} was specified more than once."
				exit 198
			}
			loc selection `selection' `graph'
		}
	}
	loc nplots : word count `selection'
	loc suppress = (`combined' & `nplots' > 1)

*** Parse confidence interval options
	loc no_ci = !`ci'
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
	loc custom_ci_bounds = ("`ciabounds'" != "" | "`cipbounds'" != "" | "`cicbounds'" != "")
	if `custom_ci_bounds' & `no_ci' {
		di as err "Custom confidence-interval bounds require option {bf:ci}."
		exit 198
	}
	if `custom_ci_bounds' & !`level_specified' {
		di as err "Custom confidence-interval bounds require an explicit " ///
			"{bf:level(#)}."
		exit 198
	}
	loc uses_apcbound_ci = 0
	if `bounded' & !`no_ci' {
		foreach apcvar in `selection' {
			loc ci_option ci`apcvar'bounds
			if "``ci_option''" == "" {
				loc letter = upper("`apcvar'")
				loc returned_label `"`e(ci`letter'bounds)'"'
				if `"`returned_label'"' != "" {
					loc uses_apcbound_ci = 1
				}
			}
		}
	}
	loc apcbound_ci = .
	if `uses_apcbound_ci' {
		cap loc apcbound_ci = e(apcboundCI)
		if _rc loc apcbound_ci = .
		if mi(`apcbound_ci') {
			di as err "The confidence level associated with the " ///
				"CI-adjusted bounds from {it:apcbound} is unavailable."
			exit 498
		}
	}
	if !`no_ci' {
		if `uses_apcbound_ci' {
			if `level_specified' {
				if `level' != `apcbound_ci' {
					di as err "Option {bf:level(`level')} does not match the " ///
						"`apcbound_ci'% confidence level used by {it:apcbound}."
					exit 198
				}
			}
			loc ci_lvl = `apcbound_ci'
		}
		else if `level_specified' loc ci_lvl = `level'
		else loc ci_lvl = c(level)
		di as txt "`ci_lvl'% confidence intervals assumed."
	}

*** Parse matrix output option
	if "`matrix'" != "" & !`bounded' {
		di as err "Option {bf:matrix()} requires option {bf:bounded}."
		exit 198
	}
	if "`matrix'" != "" {
		foreach apcvar in `selection' {
			loc output_matrix_pe `apcvar'PE_`matrix'
			cap conf names `output_matrix_pe'
			if _rc {
				di as err "Invalid output matrix name {bf:`output_matrix_pe'}."
				di as err "Specify a shorter or otherwise valid suffix in {bf:matrix()}."
				exit 198
			}
			if !`no_ci' {
				loc output_matrix_ci `apcvar'CI_`matrix'
				cap conf name `output_matrix_ci'
				if _rc {
					di as err "Invalid output matrix name {bf:`output_matrix_ci'}."
					di as err "Specify a shorter suffix in {bf:matrix()}."
					exit 198
				}
			}
		}
	}

*** Classify supplied solutions separately by estimate and APC effect
	loc any_semibounded = 0
	loc any_pe_semibounded = 0
	foreach est in pe ci {
		foreach apcvar in `selection' {
			loc `est'_`apcvar'_lower = .
			loc `est'_`apcvar'_upper = .
			loc `est'_`apcvar'_status unbounded
			loc `est'_`apcvar'_source none
			loc `est'_`apcvar'_open both
			loc `est'_`apcvar'_info "unbounded"
		}
	}
	if !`bounded' di as txt "A bounded solution not requested, " ///
			"only the nonlinear shapes will be rendered."
	else {
		di as txt "Bounded-solution visualization requested."
		loc pe_text "point-estimate"
		if !`no_ci' loc ci_text "`ci_lvl'% confidence-interval"
		if `no_ci' loc estimates pe
		else loc estimates pe ci
		foreach est in `estimates' {
			foreach apcvar in `selection' {
				loc letter = upper("`apcvar'")
				loc lower = .
				loc upper = .
				loc source none
				if "``est'`apcvar'bounds'" != "" {
					loc supplied ``est'`apcvar'bounds'
					loc lower : word 1 of `supplied'
					loc upper : word 2 of `supplied'
					loc source custom
				}
				else {
					loc returned_label `"`e(`est'`letter'bounds)'"'
					if `"`returned_label'"' != "" {
						cap loc lower = e(`est'`letter'min)
						if _rc loc lower = .
						cap loc upper = e(`est'`letter'max)
						if _rc loc upper = .
						loc source apcbound
					}
				}
				if !mi(`lower') & !mi(`upper') {
					if `lower' > `upper' {
						di as err "Lower ``est'_text' bound exceeds upper " ///
							"bound for ``apcvar'_letter'."
						exit 198
					}
					loc status bounded
					loc open none
				}
				else if mi(`lower') & mi(`upper') {
					loc status unbounded
					loc open both
				}
				else {
					loc status semibounded
					loc any_semibounded = 1
					if "`est'" == "pe" loc any_pe_semibounded = 1
					if mi(`lower') loc open lower
					else loc open upper
				}
				loc `est'_`apcvar'_lower = `lower'
				loc `est'_`apcvar'_upper = `upper'
				loc `est'_`apcvar'_status `status'
				loc `est'_`apcvar'_source `source'
				loc `est'_`apcvar'_open `open'
				if mi(`lower') loc lower_label "negative infinity"
				else loc lower_label = string(`lower', "%9.3g")
				if mi(`upper') loc upper_label "positive infinity"
				else loc upper_label = string(`upper', "%9.3g")
				loc `est'_`apcvar'_info "`lower_label' < ``apcvar'_letter' < `upper_label'"
				if "`source'" == "custom" loc source_text "specified as custom"
				else if "`source'" == "apcbound" loc source_text "supplied by {it:apcbound}"
				else loc source_text "supplied"
				if "`status'" == "bounded" di as txt "   A fully bounded ``est'_text' " ///
						"solution for ``apcvar'_letter' `source_text'."
				else if "`status'" == "semibounded" di as txt "   A semi-bounded " ///
					"``est'_text' solution for ``apcvar'_letter' `source_text' (`open' end open)."
				else if "`source'" == "none" di as txt "   No ``est'_text' bounds for " ///
						"``apcvar'_letter' supplied; shape only."
				else di as txt "   An unbounded ``est'_text' solution for " ///
						"``apcvar'_letter' `source_text'; shape only."
			}
		}
	}
	if `fadespeed_specified' & !`any_pe_semibounded' {
		di as err "Option {bf:fadespeed()} applies only when at least one " ///
			"selected point-estimate solution is semi-bounded."
		exit 198
	}
	if `fadewidth_specified' & !`any_pe_semibounded' {
		di as err "Option {bf:fadewidth()} applies only when at least one " ///
			"selected point-estimate solution is semi-bounded."
		exit 198
	}

*** Parse exact linear component parameters
	loc parameters `a' `p' `c'
	if `: word count `parameters'' > 1 {
		di as err "Only a single linear parameter (α, π or γ) can be specified."
		exit 198
	}
	else if `: word count `parameters'' == 0 {
		loc a_value = 0
		loc p_value = 0
		loc c_value = 0
	}
	else {
		if "`a'" != "" {
			loc letter a
			loc a_value = `a'
			loc p_value = `e(theta1)' - `a'
			loc c_value = `a' - `e(theta1)' + `e(theta2)'
			loc remaining p c
		}
		if "`p'" != "" {
			loc letter p
			loc a_value = `e(theta1)' - `p'
			loc p_value = `p'
			loc c_value = `e(theta2)' - `p'
			loc remaining a c
		}
		if "`c'" != "" {
			loc letter c
			loc a_value = `e(theta1)' - `e(theta2)' + `c'
			loc p_value = `e(theta2)' - `c'
			loc c_value = `c'
			loc remaining a p
		}
		forvalues i=1/2 {
			loc imply`i' = "``: word `i' of `remaining''_letter' = " + ///
				string(``: word `i' of `remaining''_value', "%9.3g")
		}
		di as txt "Parameter {bf:``letter'_letter'} set to {bf:``letter'_value'} " ///
			"(implies {bf:`imply1'} and {bf:`imply2'})".
	}

*** Parse grid parameters
	loc no_grid = ("`grid'" == "")
	loc gridlabels = lower(strtrim(`"`gridlabels'"'))
	if "`gridlabels'" != "" & ///
			!inlist("`gridlabels'", "off", "left", "right") {
		di as err "Option {bf:gridlabels()} must be {bf:off}, {bf:left}, or {bf:right}."
		exit 198
	}
	if `no_grid' & "`gridlabels'" != "" {
		di as err "Option {bf:gridlabels()} requires option {bf:grid()}."
		exit 198
	}
	if !`no_grid' {
		loc invalid = 0
		loc grid_sign "- +"
		loc grid_steps = 1
		loc nargs : word count `grid'
		if !inlist(`nargs', 1, 2) loc invalid = 1
		else {
			gettoken step_arg count_arg : grid
			loc grid_step = real("`step_arg'")
			if mi(`grid_step') | `grid_step' <= 0 loc invalid = 1
		}
		if !`invalid' & `nargs' == 2 {
			loc count_arg = trim("`count_arg'")
			if !regexm("`count_arg'", "^[+-]?[0-9]+$") loc invalid = 1
			else {
				loc first = substr("`count_arg'", 1, 1)
				if inlist("`first'", "+", "-") {
					loc grid_sign "`first'"
					loc count_arg = substr("`count_arg'", 2, .)
				}
				loc grid_steps = real("`count_arg'")
				if mi(`grid_steps') | `grid_steps' < 1 loc invalid = 1
			}
		}
		if `invalid' {
			di as err "Inappropriate input in {it:grid()} option!"
			exit 198
		}
	}

*** Extract values and CIs into plot matrices
	if !`no_ci' loc lincom_ci , level(`ci_lvl')
	foreach apcvar in `selection' {
		loc V = upper("`apcvar'")
		loc variable `e(`apcvar'varname)'
		loc specification `e(`apcvar'spec)'
		loc type `e(`apcvar'type)'
		loc ncols = 16
		tempname ests
	* polynomial specification
		if "`type'" == "polynomial" {
			__apcplot_value_range `variable' if __apcest_esample
			loc xvalues = r(xvalues)
			mat `ests' = J(`: word count `xvalues'', `ncols', .)
			forvalues i=1/`=rowsof(`ests')' {
				loc x = `: word `i' of `xvalues''
				mat `ests'[`i', 1] = `x'
				mat `ests'[`i', 2] = `x' - `e(`apcvar'center)'
				loc formula 0
				forvalues j=1/`: word count `specification'' {
					loc xpowered = `ests'[`i', 2]^(`=`j'+1')
					loc formula `formula'+_b[`: word `j' of `specification'']*`xpowered'
				}
				qui lincom `formula' `lincom_ci'
				mat `ests'[`i', 3] = r(estimate)
				if `no_ci' mat `ests'[`i', 4] = .
				else mat `ests'[`i', 4] = r(lb)
				if `no_ci' mat `ests'[`i', 5] = .
				else mat `ests'[`i', 5] = r(ub)
			}
		}
	* categorical/grouped specification
		else if inlist("`type'", "categorical", "grouped") {
			loc nlvar __apcest_nl`V'
			loc coeflist : colnames e(b)
			loc coefficients
			loc xvalues
			loc varname_length = strlen("`nlvar'")
			foreach coef in `coeflist' {
				if strpos("`coef'", ".`nlvar'") & ///
						(strlen("`coef'") - strpos("`coef'", ".`nlvar'")) ///
						== `varname_length' {
					loc value = substr("`coef'", 1, strpos("`coef'", ".") - 1)
					loc value : subinstr local value "bn" "", all
					loc value : subinstr local value "b" "", all
					loc value : subinstr local value "o" "", all
					loc xvalues `xvalues' `value'
					loc coefficients `coefficients' `coef'
				}
			}
			qui sum `variable' if `nlvar' == `e(`apcvar'ref)' & __apcest_esample
			loc xref = r(mean)
			mat `ests' = J(`: word count `xvalues'', `ncols', .)
			forvalues i=1/`=rowsof(`ests')' {
				loc xcat = `: word `i' of `xvalues''
				qui sum `variable' if `nlvar' == `xcat' & __apcest_esample
				loc x = r(mean)
				mat `ests'[`i', 1] = `x'
				mat `ests'[`i', 2] = `x' - `xref'
				qui lincom _b[`: word `i' of `coefficients''] `lincom_ci'
				mat `ests'[`i', 3] = r(estimate)
				if `no_ci' mat `ests'[`i', 4] = .
				else mat `ests'[`i', 4] = cond(mi(r(lb)), 0, r(lb))
				if `no_ci' mat `ests'[`i', 5] = .
				else mat `ests'[`i', 5] = cond(mi(r(ub)), 0, r(ub))
			}
		}

	* linear specification
		else if "`type'" == "linear" {
			__apcplot_value_range `variable' if __apcest_esample
			loc xvalues = r(xvalues)
			mat `ests' = J(`: word count `xvalues'', `ncols', .)
			forvalues i=1/`=rowsof(`ests')' {
				loc x = `: word `i' of `xvalues''
				mat `ests'[`i', 1] = `x'
				mat `ests'[`i', 2] = `x' - `e(`apcvar'center)'
				mat `ests'[`i', 3] = 0
				if `no_ci' mat `ests'[`i', 4] = .
				else matrix `ests'[`i', 4] = 0
				if `no_ci' mat `ests'[`i', 5] = .
				else mat `ests'[`i', 5] = 0
			}
		}
		else {
			di as error "Variable specifications unclear! Please check."
			exit 498
		}

	* joint linear + nonlinear calculations
		loc baseline = ``apcvar'_value'
		loc key pe_`apcvar'_status
		loc pe_status "``key''"
		loc key pe_`apcvar'_lower
		loc pe_lower = ``key''
		loc key pe_`apcvar'_upper
		loc pe_upper = ``key''
		loc key ci_`apcvar'_status
		loc ci_status "``key''"
		loc key ci_`apcvar'_lower
		loc ci_lower = ``key''
		loc key ci_`apcvar'_upper
		loc ci_upper = ``key''
		if `bounded' & "`pe_status'" == "bounded" {
			loc pe_slp_min = `pe_lower'
			loc pe_slp_max = `pe_upper'
			if "`apcvar'" == "p" {
				loc pe_slp_min = `pe_upper'
				loc pe_slp_max = `pe_lower'
			}
		}
		else if `bounded' & "`pe_status'" == "semibounded" {
			if mi(`pe_lower') {
				loc pe_finite = `pe_upper'
				loc pe_direction = -1
			}
			else {
				loc pe_finite = `pe_lower'
				loc pe_direction = 1
			}
			loc pe_`apcvar'_finite = `pe_finite'
			loc pe_`apcvar'_direction = `pe_direction'
		}
		if !`no_ci' & `bounded' & "`ci_status'" == "bounded" {
			loc ci_slp_min = `ci_lower'
			loc ci_slp_max = `ci_upper'
		}
		else if !`no_ci' & `bounded' & "`ci_status'" == "semibounded" {
			if mi(`ci_lower') {
				loc ci_finite = `ci_upper'
				loc ci_direction = -1
			}
			else {
				loc ci_finite = `ci_lower'
				loc ci_direction = 1
			}
			if "`pe_status'" == "semibounded" {
				if `pe_direction' != `ci_direction' {
					di as err "Point-estimate and confidence-interval bounds " ///
						"for ``apcvar'_letter' are open in opposite directions."
					exit 498
				}
				loc ci_anchor = `pe_finite'
			}
			else if "`pe_status'" == "bounded" {
				if `ci_direction' == -1 loc ci_anchor = `pe_lower'
				else loc ci_anchor = `pe_upper'
			}
			else {
				di as err "A semi-bounded confidence-interval plot for " ///
					"``apcvar'_letter' requires a corresponding finite " ///
					"point-estimate boundary."
				exit 198
			}
			loc ci_`apcvar'_finite = `ci_finite'
			loc ci_`apcvar'_direction = `ci_direction'
			loc ci_`apcvar'_anchor = `ci_anchor'
		}
		forvalues i=1/`=rowsof(`ests')' {
			loc x = `ests'[`i', 2]
			mat `ests'[`i', 6] = `ests'[`i', 3] + `baseline' * `x'
			if `no_ci' {
				mat `ests'[`i', 7] = .
				mat `ests'[`i', 8] = .
			}
			else {
				mat `ests'[`i', 7] = `ests'[`i', 4] + `baseline' * `x'
				mat `ests'[`i', 8] = `ests'[`i', 5] + `baseline' * `x'
			}
			forvalues j=9/16 {
				mat `ests'[`i', `j'] = .
			}
			if `bounded' & "`pe_status'" == "bounded" {
				mat `ests'[`i', 9] = `pe_slp_min' * `x'
				mat `ests'[`i', 10] = `pe_slp_max' * `x'
				mat `ests'[`i', 11] = `ests'[`i', 9] + `ests'[`i', 3]
				mat `ests'[`i', 12] = `ests'[`i', 10] + `ests'[`i', 3]
			}
			else if `bounded' & "`pe_status'" == "semibounded" {
				loc finite_L = `pe_finite' * `x'
				loc finite_Y = `finite_L' + `ests'[`i', 3]
				loc open_y_direction = `pe_direction' * `x'
				if `open_y_direction' > 0 {
					mat `ests'[`i', 9] = `finite_L'
					mat `ests'[`i', 11] = `finite_Y'
				}
				else if `open_y_direction' < 0 {
					mat `ests'[`i', 10] = `finite_L'
					mat `ests'[`i', 12] = `finite_Y'
				}
				else {
					mat `ests'[`i', 9] = 0
					mat `ests'[`i', 10] = 0
					mat `ests'[`i', 11] = `ests'[`i', 3]
					mat `ests'[`i', 12] = `ests'[`i', 3]
				}
			}
			if !`no_ci' {
				if `bounded' & "`ci_status'" == "bounded" {
					mat `ests'[`i', 13] = min(`ci_slp_min' * `x', `ci_slp_max' * `x') ///
						+ `ests'[`i', 4]
					mat `ests'[`i', 14] = max(`ci_slp_min' * `x', `ci_slp_max' * `x') ///
						+ `ests'[`i', 5]
					mat `ests'[`i', 15] = `ests'[`i', 13]
					mat `ests'[`i', 16] = `ests'[`i', 14]
				}
				else if `bounded' & "`ci_status'" == "semibounded" {
					loc finite_ci_lower = `ests'[`i', 4] + `ci_finite' * `x'
					loc finite_ci_upper = `ests'[`i', 5] + `ci_finite' * `x'
					loc open_y_direction = `ci_direction' * `x'
					if `open_y_direction' > 0 mat `ests'[`i', 13] = `finite_ci_lower'
					else if `open_y_direction' < 0 mat `ests'[`i', 14] = `finite_ci_upper'
					else {
						mat `ests'[`i', 13] = `ests'[`i', 4]
						mat `ests'[`i', 14] = `ests'[`i', 5]
					}
				}
			}
		}
		mat colnames `ests' = x xL NL NLlbCI NLubCI ///
			NLshift NLlbCIshift NLubCIshift ///
			lbL ubL lb ub lbCI ubCI plotlbCI plotubCI
		if `bounded' & "`pe_status'" == "semibounded" {
			__apcplot_semistep `ests' `pe_finite' `pe_direction' `grades' `fadewidth'
			loc pe_`apcvar'_semistep = r(step)
			loc pe_`apcvar'_outer = r(outer)
			loc canonical_direction = cond("`apcvar'" == "p", -1, 1)
			loc pe_`apcvar'_reverse = ///
				(`pe_direction' != `canonical_direction')
		}
		if !`no_ci' & `bounded' & "`ci_status'" == "semibounded" {
			forvalues i=1/`=rowsof(`ests')' {
				loc x = `ests'[`i', "xL"]
				loc pe_boundary = `ests'[`i', "NL"] + `ci_anchor' * `x'
				loc finite_ci_lower = `ests'[`i', 13]
				loc finite_ci_upper = `ests'[`i', 14]
				if !mi(`finite_ci_lower') & !mi(`finite_ci_upper') {
					loc plot_ci_lower = ///
						min(`finite_ci_lower', `finite_ci_upper', `pe_boundary')
					loc plot_ci_upper = ///
						max(`finite_ci_lower', `finite_ci_upper', `pe_boundary')
				}
				else if !mi(`finite_ci_lower') {
					loc plot_ci_lower = min(`finite_ci_lower', `pe_boundary')
					loc plot_ci_upper = max(`finite_ci_lower', `pe_boundary')
				}
				else if !mi(`finite_ci_upper') {
					loc plot_ci_lower = min(`finite_ci_upper', `pe_boundary')
					loc plot_ci_upper = max(`finite_ci_upper', `pe_boundary')
				}
				else {
					di as err "Unable to construct the semi-bounded " ///
						"confidence interval for ``apcvar'_letter'."
					exit 498
				}
				mat `ests'[`i', 15] = `plot_ci_lower'
				mat `ests'[`i', 16] = `plot_ci_upper'
			}
		}
		tempname `apcvar'_ests
		mat ``apcvar'_ests' = `ests'
	}

*** Grid palette, matrix and label rendering (if requested)
	if !`no_grid' {
	* palettes
		if "`gridpalette'" == "" loc gridpalette = "tableau"
		if strpos("`gridpalette'", ",") {
			loc comma = strpos("`gridpalette'", ",")
			loc pal1 = trim(substr("`gridpalette'", `comma' + 1, .))
			loc pal2 = trim(substr("`gridpalette'", 1, `comma' - 1))
			forvalues i=1/2 {
				colorpalette `pal`i'', nogr n(`grid_steps')
				forvalues j=1/`grid_steps' {
					loc pal`i'color`j' = r(p`j')
				}
			}
		}
		else {
			loc ncolors = 2 * `grid_steps'
			colorpalette `gridpalette', nogr n(`ncolors')
			forvalues j=1/`grid_steps' {
				loc pal1color`j' = r(p`j')
				loc k = `grid_steps' + `j'
				loc pal2color`j' = r(p`k')
			}
		}
	* matrices and labels
		foreach apcvar in `selection' {
			loc signs `grid_sign'
			if `anchorgrid' & "`apcvar'" == "p" {
				if "`grid_sign'" == "-" loc signs +
				if "`grid_sign'" == "+" loc signs -
				if "`grid_sign'" == "- +" loc signs + -
			}
			loc colnames
			forvalues i=1/`: word count `signs'' {
				loc sign `: word `i' of `signs''
				__apcplot_make_gradient ``apcvar'_ests' ///
					NLshift `=`sign'`grid_step'' `grid_steps' grid 0
				tempname grid_matrix
				mat `grid_matrix' = r(gradient_matrix)
				loc style place(c)
				if "`gridlabops'" != "" loc style `gridlabops'
				loc xmin = ``apcvar'_ests'[1, "x"]
				loc xmax = ``apcvar'_ests'[`=rowsof(``apcvar'_ests')', "x"]
				loc grid_labels
				forvalues j=1/`grid_steps' {
					if "`gridlabels'" != "off" {
						loc y_xmin = `grid_matrix'[1, `j']
						loc y_xmax = `grid_matrix'[`=rowsof(`grid_matrix')', `j']
						loc left_label = "`sign'" + string(`grid_step' * `j', "%9.3g")
						loc right_label `left_label'
						if "`gridlabels'" == "left" loc right_label
						if "`gridlabels'" == "right" loc left_label
						loc color `pal`i'color`j''
						if "`left_label'" != "" {
							loc grid_labels `grid_labels' ///
								text(`y_xmin' `xmin' "`left_label'", color("`color'") `style')
						}
						if "`right_label'" != "" {
							loc grid_labels `grid_labels' ///
								text(`y_xmax' `xmax' "`right_label'", color("`color'") `style')
						}
					}
					loc colnames `colnames' grid`=`j'+(`i'-1)*`grid_steps''
				}
				loc `apcvar'_grid_labels ``apcvar'_grid_labels' `grid_labels'
				tempname grid_matrix`i'
				mat `grid_matrix`i'' = `grid_matrix'
				loc nruns = `i'
			}
			tempname `apcvar'_grid_matrix
			if `nruns' == 1 mat ``apcvar'_grid_matrix' = `grid_matrix1'
			else {
				mat ``apcvar'_grid_matrix' = (`grid_matrix1', `grid_matrix2')
				mat colnames ``apcvar'_grid_matrix' = `colnames'
			}
		}
	}

*** Render bounded or semi-bounded solution matrices
	if `bounded' {
		foreach apcvar in `selection' {
			loc key pe_`apcvar'_status
			loc pe_status "``key''"
			if inlist("`pe_status'", "bounded", "semibounded") {
				tempname `apcvar'_gradient_matrix
				if "`pe_status'" == "bounded" {
					if !`nogradient' {
						if "`areapalette'" == "" loc areapalette "CET R1"
						colorpalette `areapalette', nogr n(`grades')
						forvalues i=1/`grades' {
							loc gradcolor`i' = r(p`i')
						}
						loc key pe_`apcvar'_lower
						loc lower = ``key''
						loc key pe_`apcvar'_upper
						loc upper = ``key''
						loc step = (`upper' - `lower') / (`grades' - 1)
						if "`apcvar'" == "p" loc step = -`step'
						__apcplot_make_gradient ``apcvar'_ests' lb `step' `grades' grad 1
					}
					else {
						loc key pe_`apcvar'_lower
						loc lower = ``key''
						loc key pe_`apcvar'_upper
						loc upper = ``key''
						loc step = `upper' - `lower'
						if "`apcvar'" == "p" loc step = -`step'
						__apcplot_make_gradient ``apcvar'_ests' lb `step' 2 grad 1
					}
				}
				else {
					if !`nogradient' {
						if "`areapalette'" == "" loc areapalette "CET R1"
						colorpalette `areapalette', nogr n(`grades')
						forvalues i=1/`grades' {
							loc gradcolor`i' = r(p`i')
						}
					}
					loc key pe_`apcvar'_finite
					loc finite = ``key''
					loc key pe_`apcvar'_semistep
					loc step = ``key''
					__apcplot_make_semigradient ``apcvar'_ests' ///
						`finite' `step' `grades' grad
				}
				mat ``apcvar'_gradient_matrix' = r(gradient_matrix)
			}
		}
	}

*** Combine matrices
	foreach apcvar in `selection' {
		tempname `apcvar'_plot_matrix
		mat ``apcvar'_plot_matrix' = ``apcvar'_ests'
		if !`no_grid' mat ``apcvar'_plot_matrix' = ///
				(``apcvar'_plot_matrix', ``apcvar'_grid_matrix')
		loc key pe_`apcvar'_status
		loc pe_status "``key''"
		if `bounded' & inlist("`pe_status'", "bounded", "semibounded") ///
			mat ``apcvar'_plot_matrix' = ///
			(``apcvar'_plot_matrix', ``apcvar'_gradient_matrix')
	}

*** Render graphs and assemble the plot
	if "`recastci'" == "" loc recastci rarea
	loc atitle Age
	loc ptitle Period
	loc ctitle Cohort
	foreach apcvar in `selection' {
		loc pe_plot
		loc cipe_plot
		loc contour_plot
		loc grid_plot
		loc bounded_plot
		loc cibounded_plot
		loc infos
		loc key pe_`apcvar'_status
		loc pe_status "``key''"
		loc key ci_`apcvar'_status
		loc ci_status "``key''"
		loc pe_range = `bounded' & inlist("`pe_status'", "bounded", "semibounded")
		loc ci_range = `bounded' & inlist("`ci_status'", "bounded", "semibounded")
		loc xlabels : value label `e(`apcvar'varname)'
		preserve
		clear
		qui svmat ``apcvar'_plot_matrix', names(col)
		label values x `xlabels'
		if `pe_range' {
			cap conf variable grad1
			if _rc {
				di as err "Internal APCPLOT error: bounded gradient variables were not created."
				exit 498
			}
		}
		if !`pe_range' | `keepshape' loc pe_plot (line NLshift x, lc(black) sort `shapeplotops')
		if !`no_ci' & !`ci_range' loc cipe_plot (`recastci' NLlbCIshift NLubCIshift x, sort `ciplotops')
		if "`areacontour'" != "" & `pe_range' {
			if "`pe_status'" == "semibounded" loc contour_plot (line grad1 x, sort lp(solid) `areacontour')
			else {
				qui ds grad*
				loc gradlast : word `: word count `r(varlist)'' of `r(varlist)'
				loc contour_plot (rline grad1 `gradlast' x, sort lp(solid) `areacontour')
			}
		}
		if !`no_grid' {
			forvalues i=1/`: word count `grid_sign'' {
				forvalues j=1/`grid_steps' {
					loc color `pal`i'color`j''
					loc ivar = `j' + (`i' - 1) * `grid_steps'
					loc grid_plot `grid_plot' (line grid`ivar' x, sort ///
							lcolor("`color'") lpattern(dash) `gridline')
				}
			}
		}
		if `info' & (`pe_range' | `ci_range') {
			loc assumptions ///
				`""{bf:Linear parameter assumptions:}" "`=e(Aassumptions)'" "`=e(Passumptions)'" "`=e(Cassumptions)'""'
			loc key pe_`apcvar'_info
			loc pe_info "``key''"
			if !`no_ci' {
				loc key ci_`apcvar'_info
				loc ci_info "``key''"
			}
			if `combined' {
				if `no_ci' loc infos note("{bf:Linear parameter solution bounds:}" "`pe_info'")
				else loc infos note("{bf:Linear parameter solution bounds:}" "`pe_info'" "`ci_info' (CI-adjusted)")
				loc infos_comb note(`assumptions', pos(6) span justification(center))
			}
			else {
				if `no_ci' loc infos note("{bf:Linear parameter solution bounds:}" "`pe_info'" " " `assumptions')
				else loc infos ///
					note("{bf:Linear parameter solution bounds:}" "`pe_info'" "`ci_info' (CI-adjusted)" " " `assumptions')
			}
		}
		if `pe_range' {
			if "`pe_status'" == "semibounded" {
				loc gradient_plot
				loc key pe_`apcvar'_reverse
				loc reverse = ``key''
				forvalues i=1/`grades' {
					loc fade_position = (`i' - 1) / (`grades' - 1)
					loc alpha = round(100 * (1 - `fade_position')^`fadespeed')
					if !`nogradient' {
						loc k = cond(`reverse', `grades' - `i' + 1, `i')
						loc color `gradcolor`k''
					}
					else {
						if "`areapalette'" == "" loc color C1
						else loc color `areapalette'
					}
					loc color_alpha "`color'%`alpha'"
					loc gradient_plot `gradient_plot' (line grad`i' x, sort ///
							lcolor("`color_alpha'") lpattern(solid))
				}
				loc bounded_plot `gradient_plot'
			}
			else if !`nogradient' {
				loc gradient_plot
				loc i = 1
				foreach v of varlist grad* {
					loc color `gradcolor`i''
					loc gradient_plot `gradient_plot' ///
						(line grad`i' x, sort lcolor("`color'") lpattern(solid))
					loc ++i
				}
				loc bounded_plot `gradient_plot'
			}
			else {
				if "`areapalette'" == "" loc areapalette C1
				loc bounded_plot (rarea grad1 grad2 x, sort ///
						lwidth(0) fcolor(`areapalette'))
			}
		}
		if !`no_ci' & `ci_range' loc cibounded_plot ///
			(`recastci' plotlbCI plotubCI x, sort `ciplotops')
	* MASTER PLOT
		loc plot `cibounded_plot' `bounded_plot' `contour_plot' ///
			`cipe_plot' `grid_plot' `pe_plot'
		loc nodraw
		if `suppress' loc nodraw nodraw
		loc nameopt name(``apcvar'title', replace)
		if `nplots' == 1 loc nameopt
		cap noi twoway `plot', ``apcvar'_grid_labels' ///
			ytitle("") xtitle(``apcvar'title', height(7)) legend(off) ///
			`nameopt' `plotops' ``apcvar'plotops' `infos' `nodraw'
		loc rc = _rc
		restore
		if `rc' exit `rc'
		loc plots_to_combine `plots_to_combine' ``apcvar'title'
	}
	* COMBINED PLOT
	if `combined' & `nplots' > 1 {
		graph combine `plots_to_combine', rows(1) ycommon ///
			xsize(`: word count `plots_to_combine'') ysize(1) ///
			`combplotops' `infos_comb'
	}
	* MATRICES
	if "`matrix'" != "" {
		loc stored_matrices
		foreach apcvar in `selection' {
			loc output_matrix_pe `apcvar'PE_`matrix'
			mat `output_matrix_pe' = ///
				(``apcvar'_ests'[1..., "lb"], ///
				 ``apcvar'_ests'[1..., "ub"], ///
				 ``apcvar'_ests'[1..., "x"])
			forvalues i=1/`=rowsof(`output_matrix_pe')' {
				loc y1 = `output_matrix_pe'[`i', 1]
				loc y2 = `output_matrix_pe'[`i', 2]
				if !mi(`y1') & !mi(`y2') {
					mat `output_matrix_pe'[`i', 1] = min(`y1', `y2')
					mat `output_matrix_pe'[`i', 2] = max(`y1', `y2')
				}
			}
			mat colnames `output_matrix_pe' = lower_Y upper_Y X
			loc stored_matrices `stored_matrices' `output_matrix_pe'
			if !`no_ci' {
				loc output_matrix_ci `apcvar'CI_`matrix'
				mat `output_matrix_ci' = ///
					(``apcvar'_ests'[1..., "lbCI"], ///
					 ``apcvar'_ests'[1..., "ubCI"], ///
					 ``apcvar'_ests'[1..., "x"])
				mat colnames `output_matrix_ci' = lower_Y upper_Y X
				loc stored_matrices `stored_matrices' `output_matrix_ci'
			}
		}
		loc nstored : word count `stored_matrices'
		if `nstored' == 1 di as txt "Plot values matrix stored: {bf:`stored_matrices'}"
		else di as txt "Plot values matrices stored: {bf:`stored_matrices'}"
	}
end

*** Routines *******************************************************************

	pr de __apcplot_value_range, rclass
		syntax varlist(min=1 max=1) [if]
		quietly summarize `varlist' `if'
		loc xmin = r(min)
		loc xmax = r(max)
		if `xmin' == `xmax' {
			ret loc xvalues "`xmin'"
			exit
		}
		loc step = (`xmax' - `xmin') / 20
		numlist "`xmin'(`step')`xmax'", sort
		loc xvalues `r(numlist)'
		ret loc xvalues "`xvalues'"
	end

	pr de __apcplot_make_gradient, rclass
		args input_matrix reference_col step grades col_prefix offset
		tempname gradient
		mat `gradient' = J(`=rowsof(`input_matrix')', `grades', .)
		loc col_names
		forvalues j=1/`grades' {
			forvalues i=1/`=rowsof(`gradient')' {
				loc x = `input_matrix'[`i', "xL"]
				loc reference = `input_matrix'[`i', "`reference_col'"]
				mat `gradient'[`i', `j'] = ///
					`reference' + `x' * `step' * (`j' - `offset')
			}
			loc col_names `col_names' `col_prefix'`j'
		}
		mat colnames `gradient' = `col_names'
		ret mat gradient_matrix = `gradient'
	end

	pr de __apcplot_make_semigradient, rclass
		args input_matrix finite_slope step grades col_prefix
		tempname gradient
		mat `gradient' = J(`=rowsof(`input_matrix')', `grades', .)
		loc col_names
		forvalues j=1/`grades' {
			loc slope = `finite_slope' + `step' * (`j' - 1)
			forvalues i=1/`=rowsof(`gradient')' {
				loc x = `input_matrix'[`i', "xL"]
				loc nonlinear = `input_matrix'[`i', "NL"]
				matrix `gradient'[`i', `j'] = ///
					`nonlinear' + `x' * `slope'
			}
			loc col_names `col_names' `col_prefix'`j'
		}
		mat colnames `gradient' = `col_names'
		ret mat gradient_matrix = `gradient'
	end

	pr de __apcplot_semistep, rclass
		args input_matrix finite_slope direction grades width
		loc ymin = .
		loc ymax = .
		loc maxabsx = 0
		forvalues i=1/`=rowsof(`input_matrix')' {
			loc x = `input_matrix'[`i', "xL"]
			loc absx = abs(`x')
			if `absx' > `maxabsx' loc maxabsx = `absx'
			loc y1 = `input_matrix'[`i', "NLshift"]
			loc y2 = `input_matrix'[`i', "NL"] + `finite_slope' * `x'
			loc y3 = `input_matrix'[`i', "NLlbCI"] + `finite_slope' * `x'
			loc y4 = `input_matrix'[`i', "NLubCI"] + `finite_slope' * `x'
			foreach y in y1 y2 y3 y4 {
				if !mi(``y'') {
					if mi(`ymin') | ``y'' < `ymin' loc ymin = ``y''
					if mi(`ymax') | ``y'' > `ymax' loc ymax = ``y''
				}
			}
		}
		if mi(`ymin') | mi(`ymax') loc yrange = 1
		else loc yrange = `ymax' - `ymin'
		if `yrange' <= 0 loc yrange = max(abs(`ymin'), abs(`ymax'), 1)
		if `maxabsx' <= 0 {
			loc slope_span = 0
			loc step = 0
		}
		else {
			loc slope_span = (`yrange' / `maxabsx') * `width'
			loc step = `direction' * `slope_span' / (`grades' - 1)
		}
		ret sca step = `step'
		ret sca outer = `finite_slope' + `direction' * `slope_span'
		ret sca yrange = `yrange'
		ret sca slope_span = `slope_span'
	end

	pr de __apcplot_refine_values, rclass
		syntax, values(str) n(int)
		loc output
		tokenize `values'
		loc nvalues : word count `values'
		forvalues i=1/`=`nvalues'-1' {
			loc a = ``i''
			loc b = ``=`i'+1''
			loc step = (`b' - `a') / (`n' + 1)
			loc output `output' `a'
			forvalues j=1/`n' {
				loc newval = `a' + `j' * `step'
				loc output `output' `newval'
			}
		}
		loc output `output' ``nvalues''
		ret loc extended `output'
	end