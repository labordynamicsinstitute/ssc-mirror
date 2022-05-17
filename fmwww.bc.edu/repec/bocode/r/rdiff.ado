*! version 1.0.0
*! 10/05/2022
*! Author: Xiaokun Yang, Lanzhou University
*! E-mail: yangxk19@lzu.edu.com

capture program drop rdiff
program define rdiff
	version 14.0

	syntax anything(name=0) [, Correct]
	
	local args_number: word count `0'
	if `args_number' != 4 {
		dis in error "only four arguments should be specified"
		exit 499
	}
	
	foreach arg in `0' {
		capture confirm integer number `arg'
		if _rc {
			dis in error "arguments specified must all be integers"
			exit 499
		}
	}
	
	foreach arg in `0' {
		capture assert `arg' >= 0
		if _rc {
			dis in error "arguments specified must all be non-negative"
			exit 499
		}
	}
	
	/* Parse. */
	
		gettoken 1 0 : 0
		gettoken 2 0 : 0
		gettoken 3 0 : 0
		gettoken 4 0 : 0
		
		local param "`1' `2' `3' `4'"
			
		/* Computation. */
			
			if "`correct'" == "" {
				WithoutContinuityCorrection `param'
			}	
			else {
				ContinuityCorrection `param'
			}
end

/* Calculation without continuity correction. */

capture program drop WithoutContinuityCorrection
program define WithoutContinuityCorrection, rclass
	args n1 s1 n2 s2
	
	local z = invnormal(0.975)
	local p1 = `s1'/`n1'
	local p2 = `s2'/`n2'
	local q1 = 1-`p1'
	local q2 = 1-`p2'
	local theta = `p1'-`p2'
	
	if `p1' < `p2' {
		dis in error "the proportion of #succ1 among #n1 should be equal to or" ///
			" greater than the proportion of #succ2 among #n2"
		exit 499
	}
	
		/* Normal approximation method. */
		
			local d = `z'*sqrt((`p1'*`q1'/`n1')+(`p2'*`q2'/`n2'))
			local ll1 = `theta'-`d'
			local ul1 = `theta'+`d'
	
		/* Wilson score method. */
		
			local d1 = `z'*sqrt(4*`n1'*`p1'*`q1'+`z'^2)
			local l1 = 1/(2*`n1'+2*`z'^2)*((2*`n1'*`p1'+`z'^2)-`d1')
			local u1 = 1/(2*`n1'+2*`z'^2)*((2*`n1'*`p1'+`z'^2)+`d1')
			local d2 = `z'*sqrt(4*`n2'*`p2'*`q2'+`z'^2)
			local l2 = 1/(2*`n2'+2*`z'^2)*((2*`n2'*`p2'+`z'^2)-`d2')
			local u2 = 1/(2*`n2'+2*`z'^2)*((2*`n2'*`p2'+`z'^2)+`d2')
			local ll2 = `theta'-sqrt((`p1'-`l1')^2+(`u2'-`p2')^2)
			local ul2 = `theta'+sqrt((`u1'-`p1')^2+(`p2'-`l2')^2)
		
/* Display the results. */

	#delimit ;
	di in smcl in gr _n 
	"95% confidence interval without continuity correction" _n
	"{hline 16}{c TT}{hline 44}" _n
	_col(10) "Method" _col(17) "{c |}"
	_col(22) "Rate Diff." _col(38) "[95% Conf. Interval]" _n
	"{hline 16}{c +}{hline 44}" _n
	_col(6) "Asymptotic" _col(17) "{c |}"
	in ye _col(24) %6.4f `theta'
	in ye _col(38) %6.4f `ll1' in ye _col(52) %6.4f `ul1' _n
	in gr _col(4) "Wilson Score" _col(17) "{c |}"
	in ye _col(24) %6.4f `theta'
	in ye _col(38) %6.4f `ll2' in ye _col(52) %6.4f `ul2' _n
	in gr "{hline 16}{c BT}{hline 44}";
	#delimit cr
	
/* Save in r(). */

	ret scalar rd = `theta'
	ret scalar ll_a = `ll1'
	ret scalar ul_a = `ul1'
	ret scalar ll_w = `ll2'
	ret scalar ul_w = `ul2'
end

/* Calculation with continuity correction. */

capture program drop ContinuityCorrection
program define ContinuityCorrection, rclass
	args n1 s1 n2 s2
	
	local z = invnormal(0.975)
	local p1 = `s1'/`n1'
	local p2 = `s2'/`n2'
	local q1 = 1-`p1'
	local q2 = 1-`p2'
	local theta = `p1'-`p2'
	
	if `p1' < `p2' {
		dis in error "the proportion of #succ1 for #n1 should be equal to" ///
			" or greater than the proportion of #succ2 for #n2"
		exit 499
	}
	
		/* Normal approximation method. */
		
			local d = (1/`n1'+1/`n2')/2+ ///
				`z'*sqrt((`p1'*`q1'/`n1')+(`p2'*`q2'/`n2'))
			local ll1 = `theta'-`d'
			local ul1 = `theta'+`d'
	
		/* Wilson score method. */
		
			local d1 = (1+`z'*sqrt(`z'^2-2-1/`n1'+4*`p1'* ///
				(`n1'*`q1'+1)))/(2*`n1'+2*`z'^2)
			local l1 = (2*`n1'*`p1'+`z'^2)/(2*`n1'+2*`z'^2)-`d1'
			local u1 = (2*`n1'*`p1'+`z'^2)/(2*`n1'+2*`z'^2)+`d1'
			local d2 = (1+`z'*sqrt(`z'^2-2-1/`n2'+4*`p2'* ///
				(`n2'*`q2'+1)))/(2*`n2'+2*`z'^2)
			local l2 = (2*`n2'*`p2'+`z'^2)/(2*`n2'+2*`z'^2)-`d2'
			local u2 = (2*`n2'*`p2'+`z'^2)/(2*`n2'+2*`z'^2)+`d2'
			local ll2 = `theta'-sqrt((`p1'-`l1')^2+(`u2'-`p2')^2)
			local ul2 = `theta'+sqrt((`u1'-`p1')^2+(`p2'-`l2')^2)
			
/* Display the results. */

	#delimit ;
	di in smcl in gr _n 
	"95% confidence interval with continuity correction" _n
	"{hline 16}{c TT}{hline 44}" _n
	_col(10) "Method" _col(17) "{c |}"
	_col(22) "Rate Diff." _col(38) "[95% Conf. Interval]" _n
	"{hline 16}{c +}{hline 44}" _n
	_col(6) "Asymptotic" _col(17) "{c |}"
	in ye _col(24) %6.4f `theta'
	in ye _col(38) %6.4f `ll1' in ye _col(52) %6.4f `ul1' _n
	in gr _col(4) "Wilson Score" _col(17) "{c |}"
	in ye _col(24) %6.4f `theta'
	in ye _col(38) %6.4f `ll2' in ye _col(52) %6.4f `ul2' _n
	in gr "{hline 16}{c BT}{hline 44}";
	#delimit cr
	
/* Save in r(). */

	ret scalar rd = `theta'
	ret scalar ll_a = `ll1'
	ret scalar ul_a = `ul1'
	ret scalar ll_w = `ll2'
	ret scalar ul_w = `ul2'
end
