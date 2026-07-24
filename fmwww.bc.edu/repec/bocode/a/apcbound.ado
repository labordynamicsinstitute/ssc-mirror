/*******************************************************************************
APCBOUND: A tool for optimizing the identification bounds on APC effects to 
facilitate Fosse-Winship bounding approach to APC analysis.
********************************************************************************
Version: 2.0 (23.7.2026)
Author: Gordey Yastrebov, University of Cologne
License: GPL-3.0
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
			[ci(string)] // confidence interval setting
		
*** Parse format setting
	if ("`format'" == "") loc format %9.3g // default
	qui tempvar testvar // check if format is correctly specified
	qui g double `testvar' = 1
	cap form `testvar' `format'
	if _rc {
		di as err `"Invalid format: `format' ({help format:help format})"'
		exit 198
	}
			
*** Parse and check the integrity of CI setting:
	if "`ci'" == "" loc no_ci = 1
	else {
		cap conf n `ci'
		if _rc {
			di as err "Confidence interval option incorrectly " ///
				"specified ({help apcbound:help apcbound})"
			exit 198
		}
		if `ci' <= 0 | `ci' >= 100 {
			di as err "Confidence level must be greater than 0 and less than 100."
			exit 198
		}
		loc no_ci = 0
		loc ci_lvl = `ci'
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
		if "`ci'" != "" {
			di as err "ci() cannot be combined with custom APC estimates " ///
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
		loc theta1spec __apcest_a
		loc theta2spec __apcest_c
		loc theta3spec "__apcest_a - __apcest_c"
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
	loc pe_error = 0
	loc peAmin = max(`lba', `theta1point' - `ubp', `lbc' + `theta1point' - `theta2point')
	loc pePmin = max(`lbp', `theta1point' - `uba', `theta2point' - `ubc')
	loc peCmin = max(`lbc', `lba' - `theta1point' + `theta2point', `theta2point' - `ubp')
	loc peAmax = min(`uba', `theta1point' - `lbp', `ubc' + `theta1point' - `theta2point')
	loc pePmax = min(`ubp', `theta1point' - `lba', `theta2point' - `lbc')
	loc peCmax = min(`ubc', `uba' - `theta1point' + `theta2point', `theta2point' - `lbp')
	foreach v in A P C {
		if `pe`v'min' > `pe`v'max' {
			di as err "Implausible/contradictory bound assumptions!"
			loc pe_error = 1
			continue, break
		}
	}
	
*** Optimize bounds integrating CIs:
	loc ci_error = 0
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
				loc ci_error = 1
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
	if !`pe_error' {
		di as txt ///
			"{bf:{ul:Optimized solution ranges using point estimate information only:}}" _n ///
			"{p 2 10}1. `peAbounds'{p_end}" "{p 2 10}2. `pePbounds'{p_end}" ///
			"{p 2 10}3. `peCbounds'" _n
	}
	if !`no_ci' & !`ci_error' {
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
	loc pe_bounded_solution = 1 // reset
	loc ci_bounded_solution = 0 // reset
	if !`no_ci' loc ci_bounded_solution = 1
	foreach v in A P C {
		foreach bound in min max {
			foreach s in pe ci {
				if strpos("``s'`v'`bound'lab'", "infinity") loc `s'`v'`bound' = .
			}
			if !`pe_error' eret sca pe`v'`bound' = `pe`v'`bound''
			if !`no_ci' & !`ci_error' eret sca ci`v'`bound' = `ci`v'`bound''
			if mi(`pe`v'`bound'') loc pe_bounded_solution = 0
			if !`no_ci' & mi(`ci`v'`bound'') loc ci_bounded_solution = 0
		}
	}
	foreach v in A P C {
		foreach s in pe ci {
			eret loc `s'`v'bounds = "``s'`v'bounds'"
		}
		eret loc `v'assumptions = "``v'assumptions'"
	}
	if `pe_error' loc pe_bounded_solution = 0
	if `ci_error' loc ci_bounded_solution = 0
	eret sca pe_bounded_solution = `pe_bounded_solution'
	eret sca ci_bounded_solution = `ci_bounded_solution'
	if `no_ci' eret sca apcboundCI = .
	else eret sca apcboundCI = `ci_lvl'
	cap conf var __apcest_esample
	if !_rc {
		cap est drop __apcestimates
		est sto __apcestimates
	}
		
	end
