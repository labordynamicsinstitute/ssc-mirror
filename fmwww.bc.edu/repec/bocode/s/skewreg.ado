*! version 1.0  Qiang Chen 20July2020
*! version 2.0  Qiang Chen 12December2023

program define skewreg, eclass byable(recall) sortpreserve
    local cmdline : copy local 0
	version 16 	
	
	syntax varlist(numeric fv) [if] [in] [, Detail Graph Level(cilevel) Predict(string) Quantile(real 0.25) Reps(integer 50) Seed(integer 1)]
    marksample touse
	
	gettoken depvar indeps : varlist
    _fv_check_depvar `depvar'
	
	tempname tao 1_tao b_numerator V_numerator b_denominator V_denominator
	local tao `quantile'
	local 1_tao = 1 - `quantile'
	
	if "`detail'" != "" {
		set seed `seed'
		qrprocess `depvar' `indeps' if `touse', q(`tao' 0.50 `1_tao') vce(boot, reps(`reps')) level(`level')
		display _n as txt "Fitting skewness regression..."
	}
	else {
		display _n as txt "Fitting skewness regression..."
		set seed `seed'
		quietly qrprocess `depvar' `indeps' if `touse', q(`tao' 0.50 `1_tao') vce(boot, reps(`reps')) level(`level')
	}
	
	local N = e(N)               
    local df_r = e(df_r) 	
	
	local pr2_q1 = 1-e(sum_mdev)[1,1]/e(sum_rdev)[1,1]
	local pr2_q2 = 1-e(sum_mdev)[1,2]/e(sum_rdev)[1,2]
	local pr2_q3 = 1-e(sum_mdev)[1,3]/e(sum_rdev)[1,3]
	
	if "`predict'" != "" {
	quietly capture drop qra1 qra2 qra3
	quietly predict qra,rearranged(`tao' 0.50 `1_tao')	
	quietly label variable qra1 "`tao' conditional quantile rearranged to remove quantile crossing"
	quietly label variable qra2 ".5 conditional quantile rearranged to remove quantile crossing"
	quietly label variable qra3 "`1_tao' conditional quantile rearranged to remove quantile crossing"
	quietly capture drop `predict'
	quietly predictnl `predict' = (qra3 + qra1 - 2*qra2)/(qra3-qra1) if `touse'
	quietly label variable `predict' "predicted conditional skewness"
	}
	
	quietly margins if `touse',dydx(*) expression((xb(#3) + xb(#1) - 2*xb(#2))/(xb(#3) - xb(#1)))
	if "`graph'" != "" {
		quietly marginsplot,yline(0) ytitle("Effects on Conditional Skewness") level(`level')
	}
	tempname b_ame V_ame
	matrix `b_ame' = r(b)
	matrix `V_ame' = r(V)
	
	if "`detail'" != "" {
		quietly margins if `touse',dydx(*) expression(xb(#3) + xb(#1) - 2*xb(#2))
		tempname b_numerator V_numerator
		matrix `b_numerator' = r(b)
		matrix `V_numerator' = r(V)		
		
		quietly margins if `touse',dydx(*) expression(xb(#3) - xb(#1))
		tempname b_denominator V_denominator
		matrix `b_denominator' = r(b)
		matrix `V_denominator' = r(V)
		
		ereturn post `b_numerator' `V_numerator', buildfvinfo depname(Numerator) dof(`df_r') obs(`N') 
		display _n as txt "Skewness regression: The numerator part" _column(54) "Number of obs =  " as result %8.0fc `N'
		display _column(1) as txt "[Q(`1_tao'|x)-Q(0.5|x)]-[Q(0.5|x)-Q(`tao'|x)]" ///
				_column(56) "Random seed =  " as result %8.0fc `seed'
		display _column(53) as txt "Number of reps =  " as result %8.0fc `reps' _continue
		display _newline(1)
		ereturn display,level(`level')  
	
		ereturn post `b_denominator' `V_denominator', buildfvinfo depname(Denominator) dof(`df_r') obs(`N') 
		display _n as txt "Skewness regression: The denominator part" _column(54) "Number of obs =  " as result %8.0fc `N'
		display _column(1) as txt "[Q(`1_tao'|x)-Q(`tao'|x)]" _column(56) "Random seed =  " as result %8.0fc `seed'
		display as txt "(same as spread/interquantile regression)" _column(53) as txt "Number of reps =  " as result %8.0fc `reps' _continue
		display _newline(1)
		ereturn display,level(`level')  
	}
		
	ereturn post `b_ame' `V_ame', buildfvinfo depname(Skewness) dof(`df_r') obs(`N') esample(`touse') 
	display _n as txt "Skewness regression: Average marginal effects" _column(54) "Number of obs =  " as result %8.0fc `N'
	display _column(2) as txt "[Q(`1_tao'|x)-Q(0.5|x)]-[Q(0.5|x)-Q(`tao'|x)]" ///
	        _column(56) "Random seed =  " as result %8.0fc `seed'
	display _column(1) as text "{hline 41}" _column(53) "Number of reps =  " as result %8.0fc `reps' 
	display _column(13) as txt "Q(`1_tao'|x)-Q(`tao'|x)" _continue 
	display _newline(1)
	ereturn display,level(`level') 
	display "Note: Std. Err. computed by the delta method from bootstrap standard errors."	

	ereturn scalar N   = `N'
	ereturn scalar df_r   = `df_r'
	ereturn scalar reps = `reps'
	ereturn scalar seed = `seed'
	ereturn scalar q1 = `tao'
	ereturn scalar q2 = 0.5
	ereturn scalar q3 = 1-`tao'
	ereturn scalar pr2_q1 = `pr2_q1'
	ereturn scalar pr2_q2 = `pr2_q2'
	ereturn scalar pr2_q3 = `pr2_q3'
	ereturn local cmd "skewreg"	
	ereturn local cmdline `"skewreg `cmdline'"'
	ereturn local eqnames "`eqnames'"
	ereturn local vcetype "Delta-method"
end 
exit
 
 
 
