*! version 1.0  Qiang Chen 20July2020
*! version 2.0  Qiang Chen 12December2023

program define kurtosisreg, eclass byable(recall) sortpreserve
    local cmdline : copy local 0
	version 16
	
	syntax varlist(numeric fv) [if] [in] [, Detail Graph Level(cilevel) Predict(string) Reps(integer 50) Seed(integer 1)]
    marksample touse
	
	gettoken depvar indeps : varlist
    _fv_check_depvar `depvar'
	
	tempname b_numerator V_numerator b_denominator V_denominator
	local q1 = .125
	local q2 = .25
	local q3 = .375
	local q4 = .625
	local q5 = .75
	local q6 = .875
	
	if "`detail'" != "" {
		set seed `seed'
		qrprocess `depvar' `indeps' if `touse', q(`q1' `q2' `q3' `q4' `q5' `q6') vce(boot, reps(`reps')) level(`level')
		display _n as txt "Fitting kurtosis regression..."
	}
	else {
		display _n as txt "Fitting kurtosis regression..."
		set seed `seed'
		quietly qrprocess `depvar' `indeps' if `touse', q(`q1' `q2' `q3' `q4' `q5' `q6') vce(boot, reps(`reps')) level(`level')		
	}
	
	local N = e(N)               
    local df_r = e(df_r) 
	
	local pr2_q1 = 1-e(sum_mdev)[1,1]/e(sum_rdev)[1,1]
	local pr2_q2 = 1-e(sum_mdev)[1,2]/e(sum_rdev)[1,2]
	local pr2_q3 = 1-e(sum_mdev)[1,3]/e(sum_rdev)[1,3]
	local pr2_q4 = 1-e(sum_mdev)[1,4]/e(sum_rdev)[1,4]
	local pr2_q5 = 1-e(sum_mdev)[1,5]/e(sum_rdev)[1,5]
	local pr2_q6 = 1-e(sum_mdev)[1,6]/e(sum_rdev)[1,6]

	if "`predict'" != "" {
	quietly capture drop qra1 qra2 qra3 qra4 qra5 qra6
	quietly predict qra,rearranged(`q1' `q2' `q3' `q4' `q5' `q6')	
	quietly label variable qra1 "`q1' conditional quantile rearranged to remove quantile crossing"
	quietly label variable qra2 "`q2' conditional quantile rearranged to remove quantile crossing"
	quietly label variable qra3 "`q3' conditional quantile rearranged to remove quantile crossing"
	quietly label variable qra4 "`q4' conditional quantile rearranged to remove quantile crossing"
	quietly label variable qra5 "`q5' conditional quantile rearranged to remove quantile crossing"
	quietly label variable qra6 "`q6' conditional quantile rearranged to remove quantile crossing"
	quietly capture drop `predict'
	quietly predictnl `predict' = (3/1.2331)*(xb(#6)-xb(#4)+xb(#3)-xb(#1))/(xb(#5)-xb(#2)) if `touse'
	quietly label variable `predict' "predicted conditional kurtosis"
	}	
	
	quietly margins if `touse',dydx(*) expression((3/1.2331)*(xb(#6)-xb(#4)+xb(#3)-xb(#1))/(xb(#5)-xb(#2)))
	if "`graph'" != "" {
		quietly marginsplot,yline(0) ytitle("Effects on Conditional Kurtosis") level(`level')
	}
	tempname b_ame V_ame
	matrix `b_ame' = r(b)
	matrix `V_ame' = r(V)
	
	if "`detail'" != "" {
		quietly margins if `touse',dydx(*) expression(3*(xb(#6)-xb(#4)+xb(#3)-xb(#1)))
		tempname b_numerator V_numerator
		matrix `b_numerator' = r(b)
		matrix `V_numerator' = r(V)		
		
		quietly margins if `touse',dydx(*) expression(1.2331*(xb(#5)-xb(#2)))
		tempname b_denominator V_denominator
		matrix `b_denominator' = r(b)
		matrix `V_denominator' = r(V)
		
		ereturn post `b_numerator' `V_numerator', buildfvinfo depname(Numerator) dof(`df_r') obs(`N') 
		display _n as txt "Kurtosis regression: The numerator part" _column(54) "Number of obs =  " as result %8.0fc `N'
		display _column(1) as txt "3*[Q(7/8|x)-Q(5/8|x)]-[Q(3/8|x)-Q(1/8|x)]" _column(56) "Random seed =  " as result %8.0fc `seed'
		display _column(53) as txt "Number of reps =  " as result %8.0fc `reps' _continue
		display _newline(1)
		ereturn display,level(`level')  
	
		ereturn post `b_denominator' `V_denominator', buildfvinfo depname(Denominator) dof(`df_r') obs(`N') 
		display _n as txt "Kurtosis regression: The denominator part" _column(54) "Number of obs =  " as result %8.0fc `N'
		display _column(1) as txt "1.2331*[Q(6/8|x)-Q(2/8|x)]" _column(56) "Random seed =  " as result %8.0fc `seed'
		display _column(53) as txt "Number of reps =  " as result %8.0fc `reps' _continue
		display _newline(1)
		ereturn display,level(`level')  
	}
		
	ereturn post `b_ame' `V_ame', buildfvinfo depname(Kurtosis) dof(`df_r') obs(`N') esample(`touse') 
	display _n as txt "Kurtosis regression: Average marginal effects" _column(54) "Number of obs =  " as result %8.0fc `N'
	display _column(3) as txt "3*[Q(7/8|x)-Q(5/8|x)]-[Q(3/8|x)-Q(1/8|x)]" _column(56) "Random seed =  " as result %8.0fc `seed'
	display _column(1) as text "{hline 45}" _column(53) "Number of reps =  " as result %8.0fc `reps' 
	display _column(9) as txt "1.2331*[Q(6/8|x)-Q(2/8|x)]" _continue 
	display _newline(1)
	ereturn display,level(`level') 
	display "Note: Std. Err. computed by the delta method from bootstrap standard errors."	
	
	ereturn scalar N   = `N'
	ereturn scalar df_r   = `df_r'
	ereturn scalar reps = `reps'
	ereturn scalar seed = `seed'
	ereturn scalar  q1 = `q1'
	ereturn scalar  q2 = `q2'
	ereturn scalar  q3 = `q3'
	ereturn scalar  q4 = `q4'
	ereturn scalar  q5 = `q5'
	ereturn scalar  q6 = `q6'
	ereturn scalar pr2_1 = `pr2_q1'
	ereturn scalar pr2_2 = `pr2_q2'
	ereturn scalar pr2_3 = `pr2_q3'
	ereturn scalar pr2_4 = `pr2_q4'
	ereturn scalar pr2_5 = `pr2_q5'
	ereturn scalar pr2_6 = `pr2_q6'
	ereturn local cmd "kurtosisreg"	
	ereturn local cmdline `"kurtosisreg `cmdline'"'
		ereturn local vcetype "Delta-method"
end       
 
 
 
 
