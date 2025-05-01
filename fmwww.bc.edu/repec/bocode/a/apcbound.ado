/*******************************************************************************
APCBOUND: A tool for optimizing the identificaiton bounds on APC effects to 
facilitate Fosse-Winship bounding approach to APC analysis.
********************************************************************************
Version: 1.0 (30.04.2025)
Author: Gordey Yastrebov, University of Cologne
License: GPL-3.0
*******************************************************************************/


	pr de apcbound, eclass
		version 14
		syntax, ///
			[a(numlist min=2 max=2 miss)] /// range for linear age effects
			[p(numlist min=2 max=2 miss)] /// range for linear period effects
			[c(numlist min=2 max=2 miss)] /// range for linear cohort effects
			[ap(numlist min=2 max=2 miss)] /// linear age-period effect estimates
			[ac(numlist min=2 max=2 miss)] /// linear age-cohort effect estimates
			[pc(numlist min=2 max=2 miss)] /// linear period-age effect estimates
			[Format(string)] /// format setting
			[ci(string)] // confidence interval setting
		
*** Parse format setting
	if ("`format'" == "") loc format %9.3g // default
	qui tempvar testvar // check if format is correctly specified
	g double `testvar' = 1
	cap form `testvar' `format'
	if _rc {
		di as err `"Invalid format: `format' ({help format:help format})"'
		exit
	}
			
*** Parse and check integrity of CI setting:
	if "`ci'" == "" loc no_ci = 1
	else {
		cap conf n `ci'
		if _rc == 0 & (`ci' > 0 & `ci' < 100) {
			loc no_ci = 0
			loc ci_lvl = `ci'
		}
		else {
			di as err "Confidence interval option incorrectly " ///
				"specified ({help apcbound:help apcbound})"
			exit
		}
	}
		
*** Parse and extract bounds:
	foreach v in a p c {
		if "``v''" == "" loc `v' . .
		loc lb`v' = `: word 1 of ``v''' // lower bound assumed value
		loc ub`v' = `: word 2 of ``v''' // upper bound assumed value
		if mi(`: word 1 of ``v''') loc lb`v' = -1e100 // negative googol
		if mi(`: word 2 of ``v''') loc ub`v' = 1e100 // positive googol
		loc lb`v'lab `=string(`lb`v'', "`format'")' // lower bound assumed label
		loc ub`v'lab `=string(`ub`v'', "`format'")' // upper bound assumed label
		if `lb`v'' == -1e100 loc lb`v'lab = "negative infinity"
		if `ub`v'' == 1e100 loc ub`v'lab = "positive infinity"
	}
		
*** Parse custom estimates
	loc drop_apcest = 0
	loc i 0
	foreach ce in ac ap pc {
		if "``ce''" != "" loc ++i
	}
	if `i' > 1 {
		di as err "Too many custom estimates specified ({help apcbound:help apcbound})"
		exit
	}
	else if `i' == 1 {
		if "`ac'" != "" {
			loc theta1point = `:word 1 of `ac''
			loc theta2point = `:word 2 of `ac''	
		}
		if "`ap'" != "" {
			loc theta1point = `:word 1 of `ap'' + `:word 2 of `ap''
			loc theta2point = `:word 1 of `ap''
		}
		if "`pc'" != "" {
			loc theta1point = `:word 1 of `pc''
			loc theta2point	= `:word 1 of `pc'' + `:word 2 of `pc''
		}
		loc theta3point = `theta1point' - `theta2point'
		loc drop_apcest = 1
		loc no_ci = 1
	}
		
*** Retrieve estimates (and CI if requested)
	if !`drop_apcest' {
		loc theta1spec `e(theta1var)'
		loc theta2spec `e(theta2var)'
		loc theta3spec "`e(theta1var)' - `e(theta2var)'"
		forv i=1/3 {
			qui lincom `theta`i'spec', l(`ci_lvl')
			loc theta`i'point = r(estimate)
			if !`no_ci' {
				loc theta`i'lower = r(lb) // theta lower CI bound
				loc theta`i'upper = r(ub) // theta upper CI bound			
			}
		}
	}
	
*** Print all optimization input parameters:
	if `no_ci' {
		loc theta1ci
		loc theta2ci
		loc theta3ci
	} 
	else {
		forv i=1/2 {
			loc theta`i'ci " [`ci_lvl'%CI: `=string(`theta`i'lower', "`format'")'; " ///
				"`=string(`theta`i'upper', "`format'")']"
		}
	}
	di as txt "{hline}" _n _n ///
		"{bf:Bounding assumptions:}" _n ///
		"{p 2 10}1. `lbalab' < {bf:α (β-Age)} < `ubalab'{p_end}" ///
		"{p 2 10}2. `lbplab' < {bf:π (β-Period)} < `ubplab'{p_end}" ///
		"{p 2 10}3. `lbclab' < {bf:γ (β-Cohort)} < `ubclab'{p_end}" ///
		_n _n "{bf:Estimated parameters:}" _n ///
		"{p 2 10}1. {bf:θ₁ = α + π = `=string(`theta1point', "`format'")'}`theta1ci'{p_end}" ///
		"{p 2 10}2. {bf:θ₂ = γ + π = `=string(`theta2point', "`format'")'}`theta2ci'{p_end}" ///
		"{p 1 10}(3. {bf:Δθ = α - γ = `=string(`theta3point', "`format'")'}`theta2ci'){p_end}" _n
		
*** Optimize point estimate bounds:
	loc Amin = max(`lba', `theta1point' - `ubp', `lbc' + `theta1point' - `theta2point')
	loc Pmin = max(`lbp', `theta1point' - `uba', `theta2point' - `ubc')
	loc Cmin = max(`lbc', `lba' - `theta1point' + `theta2point', `theta2point' - `ubp')
	loc Amax = min(`uba', `theta1point' - `lbp', `ubc' + `theta1point' - `theta2point')
	loc Pmax = min(`ubp', `theta1point' - `lba', `theta2point' - `lbc')
	loc Cmax = min(`ubc', `uba' - `theta1point' + `theta2point', `theta2point' - `lbp')
	foreach v in A P C {
		if ``v'min' > ``v'max' {
			di as err "Implausible/contradictory bound assumptions!"
			exit
		}
	}
	
*** Optimize bounds integrating CIs:
	if !`no_ci' {
		loc ciAmin = max(`lba', `theta1lower' - `ubp', `lbc' + `theta3lower')
		loc ciPmin = max(`lbp', `theta1lower' - `uba', `theta2lower' - `ubc')
		loc ciCmin = max(`lbc', `lba' - `theta3upper', `theta2lower' - `ubp')
		loc ciAmax = min(`uba', `theta1upper' - `lbp', `ubc' + `theta3upper')
		loc ciPmax = min(`ubp', `theta1upper' - `lba', `theta2upper' - `lbc')
		loc ciCmax = min(`ubc', `uba' - `theta3lower', `theta2upper' - `lbp')
		foreach v in ciA ciP ciC {
			if ``v'min' > ``v'max' {
				di as err "Implausible/contradictory bound assumptions!"
				exit
			}
		}
	}

*** Label solution values:
	if !`no_ci' loc cioff "ci"
	foreach v in A P C `cioff'A `cioff'P `cioff'C {
		loc `v'minlab `=string(``v'min', "`format'")'
		loc `v'maxlab `=string(``v'max', "`format'")'
		if ``v'min' == -1e100 loc `v'minlab "negative infinity"
		if ``v'max' == 1e100 loc `v'maxlab "positive infinity"
	}
		
*** Print solutions:
	di as txt ///
		"{bf:{ul:Optimized solution ranges using point estimate information only:}}" _n ///
		"{p 2 10}1. `Aminlab' < {bf:α (β-Age)} < `Amaxlab'{p_end}" ///
		"{p 2 10}2. `Pminlab' < {bf:π (β-Period)} < `Pmaxlab'{p_end}" ///
		"{p 2 10}3. `Cminlab' < {bf:γ (β-Cohort)} < `Cmaxlab'{p_end}" _n
	if !`no_ci' {
	di as txt ///
		"{bf:{ul:Optimized solution ranges taking `ci_lvl'% confidence " ///
			"intervals into account:}}" _n ///
		"{p 2 10}1. `ciAminlab' < {bf:α (β-Age)} < `ciAmaxlab'{p_end}" ///
		"{p 2 10}2. `ciPminlab' < {bf:π (β-Period)} < `ciPmaxlab'{p_end}" ///
		"{p 2 10}3. `ciCminlab' < {bf:γ (β-Cohort)} < `ciCmaxlab'{p_end}" _n
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
	loc ci_bounded_solution = 1 // reset
	foreach v in A P C {
		foreach bound in min max {
			if strpos("``v'`bound'lab'", "infinity") {
				loc `v'`bound' = .
				loc ci`v'`bound' = .
			}
			eret sca pe`v'`bound' = ``v'`bound''
			if mi(``v'`bound'') loc pe_bounded_solution = 0
			if mi(`ci`v'`bound'') loc ci_bounded_solution = 0
			if !`no_ci' eret sca ci`v'`bound' = `ci`v'`bound''
		}
	}
	eret sca pe_bounded_solution = `pe_bounded_solution'
	eret sca ci_bounded_solution = `ci_bounded_solution'
	if !`no_ci' eret sca apcboundCI = `ci_lvl'
	if !`drop_apcest' est sto __apcestimate
		
	end
