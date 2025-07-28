*! 1.0 N.Orsini 20 Jul 2025

capture program drop ctohri
program define ctohri , rclass 
	version 12
	args n1 c1 t1 n0 c0 t0 
	tempname s1 s0 h1 h0 ln_hr se_ln_hr hr lb_hr ub_hr 

	scalar `s1' = 1-`c1'/`n1'
	scalar `s0' = 1-`c0'/`n0'
	scalar `h1' = -ln(`s1')/`t1'
	scalar `h0' = -ln(`s0')/`t0'
	scalar `hr' = `h1'/`h0'
	scalar `ln_hr' = ln(`hr')
	scalar `se_ln_hr' = sqrt(1/`c1' + 1/`c0')
	scalar `lb_hr' = exp(`ln_hr'+invnormal(.025)*`se_ln_hr')
	scalar `ub_hr' = exp(`ln_hr'+invnormal(.975)*`se_ln_hr')

	display _n "Hazard Ratio: " as res %4.3f `hr' as text "   95% Confidence Interval: " %4.3f as res `lb_hr' "-"  %4.3f as res `ub_hr'
	*display "0.025 Confidence: " %4.3f `lb_hr' 
	*display "0.975 Confidence: "  %4.3f `ub_hr'
	display as text "Test ln(HR)=0 (z=" as res  %4.3f as res `ln_hr'/`se_ln_hr' as text ") 2-sided p-value: " %4.3f as res 2*normal(-abs(`ln_hr'/`se_ln_hr'))

	return scalar t1 = `t1'
	return scalar t0 = `t0'
	return scalar p1 = `c1'/`n1'
	return scalar p0 = `c0'/`n0'
	return scalar surv1 = `s1'
	return scalar surv0 = `s0'
	return scalar h1 = `h1'
	return scalar h0 = `h0'

	return scalar ln_hr = `ln_hr'
	return scalar se_ln_hr = `se_ln_hr'
	return scalar hr = `hr'
	return scalar lb_hr = `lb_hr'
	return scalar ub_hr = `ub_hr'
	return scalar p_hr = 2*normal(-abs(`ln_hr'/`se_ln_hr'))
end

*ctohri 3051 306 4 3054 319 4
