cap program drop tsti
program define tsti, rclass
	*Syntax: estimate se rope_lb rope_ub, options. df has a second companion 'ghost' option designed to see whether it has been provided
	version 9.0
	*Get tokens
	gettoken estimate 0 : 0, parse(" ,")
	gettoken se 0 : 0, parse(" ,")
	gettoken rope_lb 0 : 0, parse(" ,")
	gettoken rope_ub 0 : 0, parse(" ,")
	
	*Confirm that all entries are numbers
	confirm number `estimate'
	confirm number `se'
	confirm number `rope_lb'
	confirm number `rope_ub'
	
	*If se <= 0...
	if (`se' <= 0) {
		
		*... then stop the function
		display "{it:se} must be strictly greater than zero"
		exit
		
	}
	
	*If rope_lb >= rope_ub...
	if (`rope_lb' >= `rope_ub') {
		
		*... then stop the function
		display "{it:rope_lb} must be strictly less than {it:rope_ub}"
		exit
		
	}
	
	syntax [, df(real 10000000000000000000) alpha(real 0.05) df2(real 10000000000000000000)]
	
	*************************
	***** ERRORS & PREP *****
	*************************
	
	*If alpha is not between 0 and 0.5...
	if (`alpha' <= 0 | `alpha' >= 0.5) {
		
		*... then stop the function
		display "{opt alpha()} must be between 0 and 0.5"
		exit
		
	}
	
	*If the estimate is exactly midway between the lower and upper bounds of the ROPE...
	if (`estimate' == (`rope_lb' + `rope_ub')/2) {
		
		*Then select the upper bound as the relevant TOST bound
		local bound = `rope_ub'
		
	}
	
	*Otherwise...
	if (`estimate' != (`rope_lb' + `rope_ub')/2) {
		
		*If the upper bound is closer to the estimate than the lower bound...
		if (abs(`estimate' - `rope_ub') < abs(`estimate' - `rope_lb')) {
			
			*Then select the upper bound as the relevant TOST bound
			local bound = `rope_ub'
			
		}
		
		*Otherwise...
		if (abs(`estimate' - `rope_ub') > abs(`estimate' - `rope_lb')) {
			
			*Select the lower bound as the relevant TOST bound
			local bound = `rope_lb'
			
		}
		
	}
	
	*Generate confidence percentage
	local confidence_pct = round(1 - `alpha', .01)*100
	
	*Generate a test matrix
	tempname test_mat
	matrix `test_mat' = J(3, 3, .)
	
	*If the estimate is located above the ROPE...
	if (`estimate' > `rope_ub') {
		
		*Then designate the test for bounding above the ROPE as relevant and the other two tests as irrelevant
		mat `test_mat'[1, 3] = 1
		mat `test_mat'[2, 3] = 0
		mat `test_mat'[3, 3] = 0
		
	}
	
	*If the estimate is located below the ROPE...
	if (`estimate' < `rope_lb') {
		
		*Then designate the test for bounding below the ROPE as relevant and the other two tests as irrelevant
		mat `test_mat'[1, 3] = 0
		mat `test_mat'[2, 3] = 0
		mat `test_mat'[3, 3] = 1
		
	}
	
	*If the estimate is located inside the ROPE...
	if (`estimate' <= `rope_ub' & `estimate' >= `rope_lb') {
		
		*Then designate the TOST p-value as relevant and the other two tests as irrelevant
		mat `test_mat'[1, 3] = 0
		mat `test_mat'[2, 3] = 1
		mat `test_mat'[3, 3] = 0
		
	}
	
	************************
	***** SUB-ROUTINES *****
	************************
	
	*If df is not provided...
	if (`df' == `df2') {
		
		*Generate the bounds of the ECI
		local ECI_LB = `estimate' - invnormal(1 - `alpha')*`se'
		local ECI_UB = `estimate' + invnormal(1 - `alpha')*`se'

		*Generate the bounds of the classic confidence interval
		local CI_classic_LB = `estimate' - invnormal(1 - `alpha'/2)*`se'
		local CI_classic_UB = `estimate' + invnormal(1 - `alpha'/2)*`se'

		*Generate the bounds of the TST confidence interval
		if (`estimate' < `rope_lb' + invnormal(1 - `alpha')*`se') {

			local CI_TST_LB = `estimate' - invnormal(1 - `alpha')*`se'

		}
		if (`estimate' >= `rope_lb' + invnormal(1 - `alpha')*`se' & `estimate' <= `rope_lb' + invnormal(1 - `alpha'/2)*`se') {

			local CI_TST_LB = `rope_lb'

		}
		if (`estimate' > `rope_lb' + invnormal(1 - `alpha'/2)*`se' & `estimate' < `rope_ub' + invnormal(1 - `alpha'/2)*`se') {

			local CI_TST_LB = `estimate' - invnormal(1 - `alpha'/2)*`se'

		}
		if (`estimate' >= `rope_ub' + invnormal(1 - `alpha'/2)*`se') {

			local CI_TST_LB = `rope_ub'

		}
		if (`estimate' <= `rope_lb' - invnormal(1 - `alpha'/2)*`se') {

			local CI_TST_UB = `rope_lb'

		}
		if (`estimate' > `rope_lb' - invnormal(1 - `alpha'/2)*`se' & `estimate' < `rope_ub' - invnormal(1 - `alpha'/2)*`se') {

			local CI_TST_UB = `estimate' + invnormal(1 - `alpha'/2)*`se'

		}
		if (`estimate' >= `rope_ub' - invnormal(1 - `alpha'/2)*`se' & `estimate' <= `rope_ub' - invnormal(1 - `alpha')*`se') {

			local CI_TST_UB = `rope_ub'

		}
		if (`estimate' > `rope_ub' - invnormal(1 - `alpha')*`se') {

			local CI_TST_UB = `estimate' + invnormal(1 - `alpha')*`se'

		}
		
		
		*Store the z-statistic and p-value of the two-sided test for bounding above the ROPE
		mat `test_mat'[1, 1] = (`estimate' - `rope_ub')/`se'
		mat `test_mat'[1, 2] = min((1 - normal(`test_mat'[1, 1]))*2, 1)
		
		*If the lower bound of the ROPE is the relevant TOST bound...
		if (`bound' == `rope_lb') {
			
			*Then store the z-statistic as estimate - min(ROPE) in standard error units...
			mat `test_mat'[2, 1] = (`estimate' - `rope_lb')/`se'
			*... and store the p-value of the one-sided test in the upper tail
			mat `test_mat'[2, 2] = 1 - normal(`test_mat'[2, 1])
			
		}
		
		*If the upper bound of the ROPE is the relevant TOST bound...
		if (`bound' == `rope_ub') {
			
			*Then store the z-statistic as estimate - max(ROPE) in standard error units...
			mat `test_mat'[2, 1] = (`estimate' - `rope_ub')/`se'
			*... and store the p-value of the one-sided test in the lower tail
			mat `test_mat'[2, 2] = normal(`test_mat'[2, 1])
			
		}
		
		*Store the z-statistic and p-value of the two-sided test for bounding below the ROPE
		mat `test_mat'[3, 1] = (`estimate' - `rope_lb')/`se'
		mat `test_mat'[3, 2] = min(normal(`test_mat'[3, 1])*2, 1)
		
		*If no p-value is < alpha...
		if (`test_mat'[1, 2] >= `alpha' & `test_mat'[2, 2] >= `alpha' & `test_mat'[3, 2] >= `alpha') {
			
			*Then store the conclusion
			local conclusion "The practical significance of the estimate is inconclusive."
			
		}
		
		*If the p-value of the two-sided test for bounding above the ROPE < alpha...
		if (`test_mat'[1, 2] < `alpha') {
			
			*Then store the conclusion
			local conclusion "The estimate is significantly bounded above the ROPE."
			
		}
		
		*If the p-value of the TOST procedure < alpha...
		if (`test_mat'[2, 2] < `alpha') {
			
			*Then store the conclusion
			local conclusion "The estimate is significantly bounded within the ROPE."
			
		}
		
		*If the p-value of the two-sided test for bounding below the ROPE < alpha...
		if (`test_mat'[3, 2] < `alpha') {
			
			*Then store the conclusion
			local conclusion "The estimate is significantly bounded below the ROPE."
			
		}
		
		********************
		*** BOUNDS TABLE ***
		********************
		
		disp ""
		disp in smcl in gr "{ralign 59: Approximate bounds}" 																_col(59) " {c |}" 	_col(71) in gr "Lower bound"  		 _col(94) in gr "Upper bound"
		disp in smcl in gr "{hline 60}{c +}{hline 52}"
		disp in smcl in gr "{ralign 59:Region of practical equivalence (ROPE)}"        										_col(59) " {c |} " 	_col(71) as result %9.3f `rope_lb'   _col(94) %9.3f  `rope_ub'
		disp in smcl in gr "{ralign 59:`confidence_pct'% TST confidence interval (for precision)}"    						_col(59) " {c |} " 	_col(71) as result %9.3f `CI_TST_LB'    _col(94) %9.3f  `CI_TST_UB'   
		disp in smcl in gr "{ralign 59:`confidence_pct'% equivalence confidence interval (for conclusions)}"    						_col(59) " {c |} " 	_col(71) as result %9.3f `ECI_LB'    _col(94) %9.3f  `ECI_UB'
		disp in smcl in gr "{ralign 59:`confidence_pct'% classic confidence interval (for conclusions)}"    						_col(59) " {c |} " 	_col(71) as result %9.3f `CI_classic_LB'    _col(94) %9.3f  `CI_classic_UB'   
		
		*********************
		*** RESULTS TABLE ***
		*********************
		
		disp ""
		disp in smcl in gr "{ralign 46: Testing results}" 							   _col(47) " {c |} " _col(52) in gr "z-statistic"			  _col(67) in gr "p-value"	    _col(80) in gr "Relevant"
		disp in smcl in gr "{hline 47}{c +}{hline 40}"
		disp in smcl in gr "{ralign 46:Test: Estimate bounded above ROPE (two-sided)}" _col(47) " {c |} " _col(52) as result %9.3f `test_mat'[1, 1] _col(64) %9.3f `test_mat'[1, 2]	_col(76) %9.0f  `test_mat'[1, 3]
		disp in smcl in gr "{ralign 46:Test: Estimate bounded within ROPE (TOST)}"     _col(47) " {c |} " _col(52) as result %9.3f `test_mat'[2, 1] _col(64) %9.3f `test_mat'[2, 2]	_col(76) %9.0f  `test_mat'[2, 3]
		disp in smcl in gr "{ralign 46:Test: Estimate bounded below ROPE (two-sided)}" _col(47) " {c |} " _col(52) as result %9.3f `test_mat'[3, 1] _col(64) %9.3f `test_mat'[3, 2]	_col(76) %9.0f  `test_mat'[3, 3]
		
		*************************
		*** PRINT DISCLAIMERS ***
		*************************
		disp ""
		disp "`conclusion'"
		disp ""
		disp "Asymptotically approximate equivalence confidence intervals (ECIs) and three-sided testing (TST) results reported"
		disp "If using for academic/research purposes, please cite the papers underlying this program:"
		disp "Fitzgerald, J. (2025). The Need for Equivalence Testing in Economics. MetaArXiv, https://doi.org/10.31222/osf.io/d7sqr_v1."
		disp "Isager, P. & Fitzgerald, J. (2024). Three-Sided Testing to Establish Practical Significance: A Tutorial. https://doi.org/10.31234/osf.io/8y925."
		
	}
	
	*If df is provided...
	if (`df' != `df2') {
		
		*If df is not greater than zero...
		if (`df' <= 0) {
			
			*... then stop the function
			display "If {opt df()} is specified, then it must be greater than zero"
			exit
			
		}

		*Generate the bounds of the TST confidence interval
		if (`estimate' < `rope_lb' + invt(`df', 1 - `alpha')*`se') {

			local CI_TST_LB = `estimate' - invt(`df', 1 - `alpha')*`se'

		}
		if (`estimate' >= `rope_lb' + invt(`df', 1 - `alpha')*`se' & `estimate' <= `rope_lb' + invt(`df', 1 - `alpha'/2)*`se') {

			local CI_TST_LB = `rope_lb'

		}
		if (`estimate' > `rope_lb' + invt(`df', 1 - `alpha'/2)*`se' & `estimate' < `rope_ub' + invt(`df', 1 - `alpha'/2)*`se') {

			local CI_TST_LB = `estimate' - invt(`df', 1 - `alpha'/2)*`se'

		}
		if (`estimate' >= `rope_ub' + invt(`df', 1 - `alpha'/2)*`se') {

			local CI_TST_LB = `rope_ub'

		}
		if (`estimate' <= `rope_lb' - invt(`df', 1 - `alpha'/2)*`se') {

			local CI_TST_UB = `rope_lb'

		}
		if (`estimate' > `rope_lb' - invt(`df', 1 - `alpha'/2)*`se' & `estimate' < `rope_ub' - invt(`df', 1 - `alpha'/2)*`se') {

			local CI_TST_UB = `estimate' + invt(`df', 1 - `alpha'/2)*`se'

		}
		if (`estimate' >= `rope_ub' - invt(`df', 1 - `alpha'/2)*`se' & `estimate' <= `rope_ub' - invt(`df', 1 - `alpha')*`se') {

			local CI_TST_UB = `rope_ub'

		}
		if (`estimate' > `rope_ub' - invt(`df', 1 - `alpha')*`se') {

			local CI_TST_UB = `estimate' + invt(`df', 1 - `alpha')*`se'

		}
		
		*Generate the bounds of the ECI
		local ECI_LB = `estimate' - invt(`df', 1 - `alpha')*`se'
		local ECI_UB = `estimate' + invt(`df', 1 - `alpha')*`se'

		*Generate the bounds of the classic confidence interval
		local CI_classic_LB = `estimate' - invt(`df', 1 - `alpha'/2)*`se'
		local CI_classic_UB = `estimate' + invt(`df', 1 - `alpha'/2)*`se'
		
		*Store the t-statistic and p-value of the two-sided test for bounding above the ROPE
		mat `test_mat'[1, 1] = (`estimate' - `rope_ub')/`se'
		mat `test_mat'[1, 2] = min((1 - t(`df', `test_mat'[1, 1]))*2, 1)
		
		*If the lower bound of the ROPE is the relevant TOST bound...
		if (`bound' == `rope_lb') {
			
			*Then store the t-statistic as estimate - min(ROPE) in standard error units...
			mat `test_mat'[2, 1] = (`estimate' - `rope_lb')/`se'
			*... and store the p-value of the one-sided test in the upper tail
			mat `test_mat'[2, 2] = 1 - t(`df', `test_mat'[2, 1])
			
		}
		
		*If the upper bound of the ROPE is the relevant TOST bound...
		if (`bound' == `rope_ub') {
			
			*Then store the t-statistic as estimate - max(ROPE) in standard error units...
			mat `test_mat'[2, 1] = (`estimate' - `rope_ub')/`se'
			*... and store the p-value of the one-sided test in the upper tail
			mat `test_mat'[2, 2] = t(`df', `test_mat'[2, 1])
			
		}
		
		*Store the t-statistic and p-value of the two-sided test for bounding below the ROPE
		mat `test_mat'[3, 1] = (`estimate' - `rope_lb')/`se'
		mat `test_mat'[3, 2] = min(t(`df', `test_mat'[3, 1])*2, 1)
		
		*If no p-value is < alpha...
		if (`test_mat'[1, 2] >= `alpha' & `test_mat'[2, 2] >= `alpha' & `test_mat'[3, 2] >= `alpha') {
			
			*Then store the conclusion
			local conclusion "The practical significance of the estimate is inconclusive."
			
		}
		
		*If the p-value of the two-sided test for bounding above the ROPE < alpha...
		if (`test_mat'[1, 2] < `alpha') {
			
			*Then store the conclusion
			local conclusion "The estimate is significantly bounded above the ROPE."
			
		}
		
		*If the p-value of the TOST procedure < alpha...
		if (`test_mat'[2, 2] < `alpha') {
			
			*Then store the conclusion
			local conclusion "The estimate is significantly bounded within the ROPE."
			
		}
		
		*If the p-value of the two-sided test for bounding below the ROPE < alpha...
		if (`test_mat'[3, 2] < `alpha') {
			
			*Then store the conclusion
			local conclusion "The estimate is significantly bounded below the ROPE."
			
		}
		
		********************
		*** BOUNDS TABLE ***
		********************
		
		disp ""
		disp in smcl in gr "{ralign 59: Exact bounds}" 																		_col(59) " {c |}" 	_col(71) in gr "Lower bound"  		 _col(94) in gr "Upper bound"
		disp in smcl in gr "{hline 60}{c +}{hline 52}"
		disp in smcl in gr "{ralign 59:Region of practical equivalence (ROPE)}"        										_col(59) " {c |} " 	_col(71) as result %9.3f `rope_lb'   _col(94) %9.3f  `rope_ub'
		disp in smcl in gr "{ralign 59:`confidence_pct'% TST confidence interval (for precision)}"    						_col(59) " {c |} " 	_col(71) as result %9.3f `CI_TST_LB'    _col(94) %9.3f  `CI_TST_UB'   
		disp in smcl in gr "{ralign 59:`confidence_pct'% equivalence confidence interval (for conclusions)}"    						_col(59) " {c |} " 	_col(71) as result %9.3f `ECI_LB'    _col(94) %9.3f  `ECI_UB'
		disp in smcl in gr "{ralign 59:`confidence_pct'% classic confidence interval (for conclusions)}"    						_col(59) " {c |} " 	_col(71) as result %9.3f `CI_classic_LB'    _col(94) %9.3f  `CI_classic_UB'   
		
		*********************
		*** RESULTS TABLE ***
		*********************
		
		disp ""
		disp in smcl in gr "{ralign 46: Testing results}" 							   _col(47) " {c |} " _col(52) in gr "z-statistic"			  _col(67) in gr "p-value"	    _col(80) in gr "Relevant"
		disp in smcl in gr "{hline 47}{c +}{hline 40}"
		disp in smcl in gr "{ralign 46:Test: Estimate bounded above ROPE (two-sided)}" _col(47) " {c |} " _col(52) as result %9.3f `test_mat'[1, 1] _col(64) %9.3f `test_mat'[1, 2]	_col(76) %9.0f  `test_mat'[1, 3]
		disp in smcl in gr "{ralign 46:Test: Estimate bounded within ROPE (TOST)}"     _col(47) " {c |} " _col(52) as result %9.3f `test_mat'[2, 1] _col(64) %9.3f `test_mat'[2, 2]	_col(76) %9.0f  `test_mat'[2, 3]
		disp in smcl in gr "{ralign 46:Test: Estimate bounded below ROPE (two-sided)}" _col(47) " {c |} " _col(52) as result %9.3f `test_mat'[3, 1] _col(64) %9.3f `test_mat'[3, 2]	_col(76) %9.0f  `test_mat'[3, 3]
		
		*************************
		*** PRINT DISCLAIMERS ***
		*************************
		disp ""
		disp "`conclusion'"
		disp ""
		disp "Exact equivalence confidence intervals (ECIs) and three-sided testing (TST) results reported"
		disp "If using for academic/research purposes, please cite the papers underlying this program:"
		disp "Fitzgerald, J. (2025). The Need for Equivalence Testing in Economics. MetaArXiv, https://doi.org/10.31222/osf.io/d7sqr_v1."
		disp "Isager, P. & Fitzgerald, J. (2024). Three-Sided Testing to Establish Practical Significance: A Tutorial. https://doi.org/10.31234/osf.io/8y925."
		
	}
	
	*Return results
	return local estimate = `estimate'
	return local se = `se'
	return local ROPE_LB = `rope_lb'
	return local ROPE_UB = `rope_ub'
	return local alpha = `alpha'
	return local CI_classic_LB = `CI_classic_LB'
	return local CI_classic_UB = `CI_classic_UB'
	return local CI_TST_LB = `CI_TST_LB'
	return local CI_TST_UB = `CI_TST_UB'
	return local ECI_LB = `ECI_LB'
	return local ECI_UB = `ECI_UB'
	return local ts_above = `test_mat'[1, 1]
	return local p_above = `test_mat'[1, 2]
	return local relevant_above = `test_mat'[1, 3]
	return local ts_TOST = `test_mat'[2, 1]
	return local p_TOST = `test_mat'[2, 2]
	return local relevant_TOST = `test_mat'[2, 3]
	return local ts_below = `test_mat'[3, 1]
	return local p_below = `test_mat'[3, 2]
	return local relevant_below = `test_mat'[3, 3]
	return local conclusion `conclusion'
	
	end
	
