*! APCBOUND by Gordey Yastrebov, version 2.2, released 16.9.2026
/*******************************************************************************
A tool for optimizing the identification bounds on APC effects to 
facilitate Fosse-Winship bounding approach to APC analysis.
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
- corrected the functioning of "nogradient" option in APCPLOT
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

	pr de apcbound, eclass
		version 14
		syntax, ///
			[a(numlist min=2 max=2 miss)] /// range for linear age effects
			[p(numlist min=2 max=2 miss)] /// range for linear period effects
			[c(numlist min=2 max=2 miss)] /// range for linear cohort effects
			[ap(numlist min=2 max=2)] /// linear age-period effect estimates
			[ac(numlist min=2 max=2)] /// linear age-cohort effect estimates
			[pc(numlist min=2 max=2)] /// linear period-cohort effect estimates
			[Format(string)] /// format setting
			[ci] /// request confidence intervals
			[Level(numlist min=1 max=1)] // confidence level

*** Parse format setting
	if ("`format'" == "") loc format %9.3g // default
	qui tempvar testvar // check if format is correctly specified
	qui g double `testvar' = 1
	cap form `testvar' `format'
	if _rc {
		di as err `"Invalid format: `format' ({help format:help format})"'
		exit 198
	}

*** Parse confidence interval options
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
	if !`no_ci' {
		if `level_specified' loc ci_lvl = `level'
		else loc ci_lvl = c(level)
	}

*** Parse and extract the assumed bounds:
	foreach v in a p c {
		if "``v''" == "" loc `v' . .
		loc lb`v' = `: word 1 of ``v'''
		loc ub`v' = `: word 2 of ``v'''
		if mi(`lb`v'') loc lb`v' = -1e100
		if mi(`ub`v'') loc ub`v' =  1e100
		if `lb`v'' > `ub`v'' {
			if "`v'" == "a" loc effect "age"
			if "`v'" == "p" loc effect "period"
			if "`v'" == "c" loc effect "cohort"
			di as err "Lower `effect' bound exceeds upper `effect' bound " ///
				"({help apcbound:help apcbound})."
			exit 198
		}
		loc lb`v'lab `=string(`lb`v'', "`format'")'
		loc ub`v'lab `=string(`ub`v'', "`format'")'
		if `lb`v'' == -1e100 loc lb`v'lab = "negative infinity"
		if `ub`v'' ==  1e100 loc ub`v'lab = "positive infinity"
	}

*** Parse custom APC slope estimates
	loc drop_apcest = 0
	loc i 0
	foreach ce in ac ap pc {
		if "``ce''" != "" loc ++i
	}
	if `i' > 1 {
		di as err "Too many custom estimates specified ({help apcbound:help apcbound})"
		exit 198
	}
	else if `i' == 1 {
		if !`no_ci' {
			di as err "Option {bf:ci} cannot be combined with custom APC estimates " ///
				"because no standard errors were supplied."
			exit 198
		}
		if "`ac'" != "" {
			loc theta1point = `:word 1 of `ac''
			loc theta2point = `:word 2 of `ac''	
		}
		if "`ap'" != "" {
			loc theta1point = `:word 1 of `ap'' + `:word 2 of `ap''
			loc theta2point = `:word 2 of `ap''
		}
		if "`pc'" != "" {
			loc theta1point = `:word 1 of `pc''
			loc theta2point	= `:word 1 of `pc'' + `:word 2 of `pc''
		}
		loc theta3point = `theta1point' - `theta2point'
		loc drop_apcest = 1
		loc no_ci = 1
	}

*** Retrieve APC slope estimates from APCEST (and CI if requested)
	if !`drop_apcest' {
		loc theta1spec `"`e(theta1spec)'"'
		loc theta2spec `"`e(theta2spec)'"'
		if `"`theta1spec'"' == "" | `"`theta2spec'"' == "" {
			di as err "APCEST estimation results not found or incompatible."
			exit 301
		}
		loc theta3spec "`theta1spec' - `theta2spec'"
		forv i=1/3 {
			if !`no_ci' loc lincom_ci , l(`ci_lvl')
			qui lincom `theta`i'spec' `lincom_ci'
			loc theta`i'point = r(estimate)
			if !`no_ci' loc theta`i'lower = r(lb) // theta lower CI bound
			if !`no_ci' loc theta`i'upper = r(ub) // theta upper CI bound
		}
	}

*** Print all optimization input parameters:
	if `no_ci' {
		loc theta1ci
		loc theta2ci
		loc theta3ci
	} 
	else {
		forv i=1/3 {
			loc theta`i'ci " [`ci_lvl'%CI: `=string(`theta`i'lower', "`format'")'; " ///
				"`=string(`theta`i'upper', "`format'")']"
		}
	}
	loc Aassumptions = "`lbalab' < {bf:α (β-Age)} < `ubalab'"
	loc Passumptions = "`lbplab' < {bf:π (β-Period)} < `ubplab'"
	loc Cassumptions = "`lbclab' < {bf:γ (β-Cohort)} < `ubclab'"
	di as txt "{hline}" _n _n ///
		"{bf:Bounding assumptions:}" _n "{p 2 10}1. `Aassumptions'{p_end}" ///
		"{p 2 10}2. `Passumptions'{p_end}" "{p 2 10}3. `Cassumptions'{p_end}" ///
		_n _n "{bf:Estimated parameters:}" _n ///
		"{p 2 10}1. {bf:θ₁ = α + π = `=string(`theta1point', "`format'")'}`theta1ci'{p_end}" ///
		"{p 2 10}2. {bf:θ₂ = γ + π = `=string(`theta2point', "`format'")'}`theta2ci'{p_end}" ///
		"{p 1 10}(3. {bf:Δθ = α - γ = `=string(`theta3point', "`format'")'}`theta3ci'){p_end}" _n

*** Optimize point estimate bounds:
	loc pe_implausible = 0
	loc peAmin = max(`lba', `theta1point' - `ubp', `lbc' + `theta1point' - `theta2point')
	loc pePmin = max(`lbp', `theta1point' - `uba', `theta2point' - `ubc')
	loc peCmin = max(`lbc', `lba' - `theta1point' + `theta2point', `theta2point' - `ubp')
	loc peAmax = min(`uba', `theta1point' - `lbp', `ubc' + `theta1point' - `theta2point')
	loc pePmax = min(`ubp', `theta1point' - `lba', `theta2point' - `lbc')
	loc peCmax = min(`ubc', `uba' - `theta1point' + `theta2point', `theta2point' - `lbp')
	foreach v in A P C {
		if `pe`v'min' > `pe`v'max' {
			di as err "Implausible/contradictory bound assumptions!"
			loc pe_implausible = 1
			continue, break
		}
	}

*** Optimize bounds integrating CIs:
	loc ci_implausible = 0
	if !`no_ci' {
		loc ciAmin = max(`lba', `theta1lower' - `ubp', `lbc' + `theta3lower')
		loc ciPmin = max(`lbp', `theta1lower' - `uba', `theta2lower' - `ubc')
		loc ciCmin = max(`lbc', `lba' - `theta3upper', `theta2lower' - `ubp')
		loc ciAmax = min(`uba', `theta1upper' - `lbp', `ubc' + `theta3upper')
		loc ciPmax = min(`ubp', `theta1upper' - `lba', `theta2upper' - `lbc')
		loc ciCmax = min(`ubc', `uba' - `theta3lower', `theta2upper' - `lbp')
		foreach v in A P C {
			if `ci`v'min' > `ci`v'max' {
				di as err "Implausible/contradictory bound assumptions!"
				loc ci_implausible = 1
				continue, break
			}
		}
	}

*** Label solution values:
	if !`no_ci' loc ci_labels ciA ciP ciC
	foreach v in peA peP peC `ci_labels' {
		loc `v'minlab `=string(``v'min', "`format'")'
		loc `v'maxlab `=string(``v'max', "`format'")'
		if ``v'min' == -1e100 loc `v'minlab "negative infinity"
		if ``v'max' == 1e100 loc `v'maxlab "positive infinity"
	}

*** Save optimized solution ranges as strings
	loc peAbounds = "`peAminlab' < {bf:α (β-Age)} < `peAmaxlab'"
	loc pePbounds = "`pePminlab' < {bf:π (β-Period)} < `pePmaxlab'"
	loc peCbounds = "`peCminlab' < {bf:γ (β-Cohort)} < `peCmaxlab'"
	if !`no_ci' {
		loc ciAbounds = "`ciAminlab' < {bf:α (β-Age)} < `ciAmaxlab'"
		loc ciPbounds = "`ciPminlab' < {bf:π (β-Period)} < `ciPmaxlab'"
		loc ciCbounds = "`ciCminlab' < {bf:γ (β-Cohort)} < `ciCmaxlab'"
	}

*** Print solutions:
	if !`pe_implausible' {
		di as txt ///
			"{bf:{ul:Optimized solution ranges using point estimate information only:}}" _n ///
			"{p 2 10}1. `peAbounds'{p_end}" "{p 2 10}2. `pePbounds'{p_end}" ///
			"{p 2 10}3. `peCbounds'" _n
	}
	if !`no_ci' & !`ci_implausible' {
		di as txt ///
			"{bf:{ul:Optimized solution ranges taking `ci_lvl'% confidence " ///
				"intervals into account:}}" _n ///
			"{p 2 10}1. `ciAbounds'{p_end}" "{p 2 10}2. `ciPbounds'{p_end}" ///
			"{p 2 10}3. `ciCbounds'" _n
	}
	di "{hline}"

*** Store estimates as return:
	foreach v in A P C {
		foreach bound in min max {
			eret sca pe`v'`bound' = . // wipe clean first
			eret sca ci`v'`bound' = . // wipe clean first
		}
	}
	foreach v in A P C {
		foreach bound in min max {
			foreach s in pe ci {
				if strpos("``s'`v'`bound'lab'", "infinity") loc `s'`v'`bound' = .
			}
			if !`pe_implausible' eret sca pe`v'`bound' = `pe`v'`bound''
			if !`no_ci' & !`ci_implausible' eret sca ci`v'`bound' = `ci`v'`bound''
		}
	}
	foreach v in A P C {
		foreach s in pe ci {
			eret loc `s'`v'bounds = "``s'`v'bounds'"
		}
		eret loc `v'assumptions = "``v'assumptions'"
	}
	if `no_ci' eret sca apcboundCI = .
	else eret sca apcboundCI = `ci_lvl'
	cap conf var __apcest_esample
	if !_rc {
		cap est drop __apcestimates
		est sto __apcestimates
	}

	end