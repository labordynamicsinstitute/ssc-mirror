*! version 2.0  28nov2025
*! Conditional probability plots for diagnostic test accuracy meta-analysis
capture program drop midas_condiplot
program midas_condiplot, rclass
	version 12
	syntax [if] [in], [Truncated *]  
	
	// Check that previous estimation was from midas package
	capture assert e(package) == "midas"
	if _rc != 0 {
		di as error "Last estimation command was not a midas subcommand"
		di as error "Please run midas mle, qrsim, mh, or inla first"
		error 301
	}

	// Check required estimation results exist
	capture confirm matrix e(bsum)
	if _rc != 0 {
		di as error "Required estimation results not found"
		di as error "Please run a midas estimation command first"
		error 301
	}

	if !missing("`truncated'") {
		// Use truncated prevalence range from estimation
		local mu1 = e(prevmin)
		local mu2 = e(prevmax)
		mat bcprob = e(bsum)
		mat Vcprob = e(Vsum)
		qui _coef_table, bmatrix(bcprob) vmatrix(Vcprob)
		mat cprobmat = r(table)'
		
		// Extract LR+ with confidence limits
		local mlrp = cprobmat[4,1]  
		local mlrplo = cprobmat[4,5]
		local mlrphi = cprobmat[4,6]
		
		// Extract LR- with confidence limits
		local mlrn = cprobmat[5,1]  
		local mlrnlo = cprobmat[5,5]  
		local mlrnhi = cprobmat[5,6]
		
		nois di " "
		nois di as text "Conditional probability plot using truncated prevalence range"
		nois di as text "Prevalence range: " as result %5.3f `mu1' " to " %5.3f `mu2'
		nois di " "
		nois condiprob, pred(`mu1' `mu2') sum1(`mlrp' `mlrplo' `mlrphi') ///
			sum2(`mlrn' `mlrnlo' `mlrnhi') `options'
	}
	else {
		// Use full prevalence range [0,1]
		local mu1 = 0
		local mu2 = 1
		mat bcprob = e(bsum)
		mat Vcprob = e(Vsum)
		qui _coef_table, bmatrix(bcprob) vmatrix(Vcprob)
		mat cprobmat = r(table)'
		
		// Extract LR+ with confidence limits
		local mlrp = cprobmat[4,1]  
		local mlrplo = cprobmat[4,5]
		local mlrphi = cprobmat[4,6]
		
		// Extract LR- with confidence limits
		local mlrn = cprobmat[5,1]  
		local mlrnlo = cprobmat[5,5]  
		local mlrnhi = cprobmat[5,6]
		
		nois di " "
		nois di as text "Conditional probability plot using full prevalence range"
		nois di as text "Prevalence range: " as result "0 to 1"
		nois di " "
		nois condiprob, pred(`mu1' `mu2') sum1(`mlrp' `mlrplo' `mlrphi') ///
			sum2(`mlrn' `mlrnlo' `mlrnhi') `options'
	}
end

capture program drop condiprob
program condiprob, rclass
	version 12
	syntax, [SUM1(numlist min=3 max=3) SUM2(numlist min=3 max=3) ///
		pred(numlist min=2 max=2) LEVEL(integer 95) ///
		PPVopts(string asis) NPVopts(string asis) *]

	qui {
		// Parse LR+ and confidence limits
		tokenize `sum1'
		local convar1 `1'
		local convar1lo `2'
		local convar1hi `3'
	   
		// Parse LR- and confidence limits
		tokenize `sum2'
		local convar2 `1'
		local convar2lo `2'
		local convar2hi `3'

		// Parse prevalence range
		tokenize `pred'
		local c1 `1'
		local c2 `2'

		// Validate level
		if `level' < 10 | `level' > 99 {
			di as error "level() must be between 10 and 99"
			exit 198
		}
		 
		// Validate prevalence range
		if `c1' < 0 | `c2' > 1.0 {
			di as error "Prevalence range must be between 0 and 1"
			exit 198
		}

		if `c1' > `c2' {
			di as error "Lower bound (c1) must be less than upper bound (c2)"
			exit 198
		}
		 
		preserve
		local alph = (100 - `level') / 200
		tempvar PPP1 PPN1 x1 x2
		
		// Generate posterior probability curves
		// Positive test result: post-test probability given positive test
		twoway__function_gen y = `convar1' * x / (1 - x * (1 - `convar1')), ///
			r(`c1' `c2') x(x) gen(`PPP1' `x1', replace) n(1000)
		
		// Negative test result: post-test probability given negative test
		twoway__function_gen y = `convar2' * x / (1 - x * (1 - `convar2')), ///
			r(`c1' `c2') x(x) gen(`PPN1' `x2', replace) n(`c(N)')
		
		// Create the plot
		#delimit;
		nois twoway 
			(line `PPP1' `x1', sort `=cond(!missing("`ppvopts'"), "`ppvopts'", "clpat(dash) clwidth(medium) connect(direct) clcolor(green)")' )
			(line `PPN1' `x2', sort `=cond(!missing("`npvopts'"), "`npvopts'", "clpat(shortdash_dot) clcolor(red) clwidth(medium) connect(direct)")' )
			(function y = x, sort range(0 1) clcolor(black) clpat(solid) 
				clwidth(vthin) connect(direct)),
			ytitle("Posterior Probability", size(*.90)) 
			yscale(range(0 1))  
			ylabel(0(0.2)1, angle(horizontal) format(%3.1f)) 
			xtitle("Prior Probability", size(*.90))
			xscale(range(0 1)) 
			xlabel(0(0.2)1, format(%3.1f)) 
			legend(order(1 "Positive Test Result"  
				2 "Negative Test Result") 
				pos(2) symxsize(6) forcesize col(1) size(*.85) 
				region(lcolor(black))) 
			aspect(1) 
			plotregion(margin(small))
			graphregion(margin(medium))
			`options';
		#delimit cr
		restore
	}
	
	// Return results
	return scalar LRpos = `convar1'
	return scalar LRpos_lb = `convar1lo'
	return scalar LRpos_ub = `convar1hi'
	return scalar LRneg = `convar2'
	return scalar LRneg_lb = `convar2lo'
	return scalar LRneg_ub = `convar2hi'
	return scalar prev_min = `c1'
	return scalar prev_max = `c2'
end
