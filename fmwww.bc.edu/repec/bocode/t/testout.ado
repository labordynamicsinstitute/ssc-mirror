////////////////////////////////////////////////////////////////////////////////
// STATA FOR  Sasaki, Y. & Wang, Y. (2021): Diagnostic Testing of Finite Moment 
//            Conditions for the Consistency and Root-N Asymptotic Normality
//            of the GMM and M Estimators. Journal of Business & Economic 
//            Statistics, forthcoming.
////////////////////////////////////////////////////////////////////////////////
program define testout, rclass
    version 14.2

    syntax varlist(min=2 numeric) [if] [in] [, iv(varname numeric) k(real 0) alpha(real 0.05) maxw(real 2) prec(real 0.00025)]
    marksample touse
 
    gettoken depvar indepvars : varlist
    _fv_check_depvar `depvar'
    fvexpand `indepvars' 
    local cnames `r(varlist)'

	tempname N K KS Pval1 Pval2
	if "`iv'" == "" {
		mata: test("`depvar'", "`cnames'","`touse'","`N'","`K'","`Pval1'","`Pval2'",`k',`alpha',`maxw',`prec')
	}
	if "`iv'" != "" {
		tempvar ivvar
		gen `ivvar' = `iv'
		mata: test_iv("`depvar'", "`cnames'","`touse'","`ivvar'","`N'","`K'","`Pval1'","`Pval2'",`k',`alpha',`maxw',`prec')
	}

	return scalar pval2 = `Pval2'
	return scalar pval1 = `Pval1'	
    return scalar alpha = `alpha'
    return scalar k = `K'
    return scalar N = `N'
	if(`Pval2'<`alpha'){
	return local test2 "reject"
	}
	if(`Pval2'>=`alpha'){
	return local test2 "fail to reject"
	}
	if(`Pval1'<`alpha'){
	return local test1 "reject"
	}
	if(`Pval1'>=`alpha'){
	return local test1 "fail to reject"
	}
	return local iv "`iv'"
	if "`iv'" == "" {
	return local mtd "reg"
	}
	if "`iv'" != "" {
	return local mtd "ivreg"
	}
    return local cmd "testout"
end
		
mata:
//////////////////////////////////////////////////////////////////////////////// 
// Function: Density Function of the Generalized Pareto Distribution
real vector dpareto(real vector x, real scalar xi){
	return( (1:+xi:*x):^(-1/xi-1) ) 
}
//////////////////////////////////////////////////////////////////////////////// 
// Function: Quantile Function of the Generalized Pareto Distribution
real vector qpareto(real vector p, real scalar xi){
	return( ((1:-p):^(-xi):-1):/xi ) 
}
//////////////////////////////////////////////////////////////////////////////// 
// Function: Get f_{V*} / Gamma(k)
real scalar getfvstar(real vector vstar, real scalar k, real scalar xi, real scalar maxw){
    maxxi = maxw + 0.5
    grid = 100
	ulist = ((1..grid):-0.5):/grid
	knots = qpareto(ulist,maxxi)
	integrand = J(length(ulist),1,0)
	for( idx = 1 ; idx <= length(ulist) ; idx++ ){
	 s = knots[idx]
	 integrand[idx,1] = ( s^(k-2) * exp( (-1-1/xi) * ( log(1+xi*s) + sum(log(1:+xi:*vstar[2..(k-1)]:*s)) ) ) )
	}
	fvstar = J(length(ulist)-1,1,0)
	for( idx = 1 ; idx <= length(ulist)-1 ; idx++ ){
	 fvstar[idx,] = (knots[idx+1]-knots[idx]) * (integrand[idx,1]+integrand[idx+1,1]) / 2
	}
	logfvstar = log(max(fvstar)) :+ log(sum(exp(log(fvstar):-max(log(fvstar)))))
	return( exp(logfvstar) )
}
//////////////////////////////////////////////////////////////////////////////// 
// Function: Get the Test Statistics
real scalar getteststat(real vector vstar, real scalar k, real scalar maxW){
    grid = 10
	W = 1 :+ (0..grid):/grid :* (maxW-1)
	num = 0
	den = getfvstar(vstar,k,1,maxW)
	for( jdx = 1 ; jdx <= length(W) ; jdx++ ){
 	 num = num + (W[2]-W[1]) * getfvstar(vstar,k,W[jdx],maxW)
	}
	return( num/den )
}
//////////////////////////////////////////////////////////////////////////////// 
// Test for reg
void test( string scalar yv, string scalar xv, string scalar touse, string scalar nname, string scalar kname, string scalar pval1name, string scalar pval2name, real scalar k, real scalar alpha, real scalar maxW, real scalar prec) 
{
	printf("\n{hline 78}\n")
	printf("Executing:  Sasaki, Y. & Wang, Y. (2021): Diagnostic Testing of Finite Moment\n")
	printf("            Conditions for the Consistency and Root-N Asymptotic Normality\n")
	printf("            of the GMM and M Estimators. Journal of Business & Economic\n")
	printf("            Statistics, forthcoming.\n")
	printf("{hline 78}\n")
	
	// Set Data ////////////////////////////////////////////////////////////////
    y      = st_data(., yv, touse)
    x      = st_data(., xv, touse)
    n = rows(y)
	x = J(n,1,1),x
	dimx = cols(x)
	if( k < 3 ){
	 k = max(3 \ ceil(0.05*n))
	}

	// Compute The Null Distribution of The Test Statistic /////////////////////
	stat_dist = J(ceil(1/prec),1,0)
	for( idx = 1 ; idx <= ceil(1/prec) ; idx++ ){
	 Estar = lowertriangle(J(k,1,rexponential(1,k,1)))
	 sumEstar = rowsum(Estar)
	 Vorder = sumEstar:^(-1):-1
	 Vstar = ( Vorder :- Vorder[k,1] ) :/ ( Vorder[1] - Vorder[k] )
	 stat_dist[idx,1] = getteststat(Vstar,k,maxW)
	}

	// OLS /////////////////////////////////////////////////////////////////////
	OLS = luinv(x'*x)*x'*y
	u = y - x*OLS
	A1 = rowsum( ( J(1,dimx,u) :* x ):^2 ):^(1/2)
	A2 = rowsum( ( J(1,dimx,u) :* x ):^2 ):^(2/2)

	// COMPUTE TGE TEST STATISTICS AND P VALUES ////////////////////////////////
	A1order = sort(A1,-1)
	A2order = sort(A2,-1)
	A1star = (A1order[1..k]:-A1order[k]) :/ (A1order[1]-A1order[k])
	A2star = (A2order[1..k]:-A2order[k]) :/ (A2order[1]-A2order[k])
	test_stat_r1 = getteststat(A1star,k,maxW)
	test_stat_r2 = getteststat(A2star,k,maxW)
	pval_r1 = mean( stat_dist :> test_stat_r1 )
	pval_r2 = mean( stat_dist :> test_stat_r2 )

	printf("Outlier Test for OLS (reg)                                      Obs = %8.0f\n", n)
	printf("                                                                  k = %8.0f\n", k)
	printf("                                                              alpha =    %4.3f\n", alpha)
	printf("{hline 78}\n")
	if( pval_r1 < alpha ){
	printf("1) Test rejects the null hypothesis of consistency.             (p-value=%3.2f)\n", pval_r1)
	}else{
	printf("1) Test fails to reject the null hypothesis of consistency.     (p-value=%3.2f)\n", pval_r1)
	}
	if( pval_r2 < alpha ){
	printf("2) Test rejects the null hypothesis of root-n normality.        (p-value=%3.2f)\n", pval_r2)
	}else{
	printf("2) Test fails to reject the null hypothesis of root-n normality.(p-value=%3.2f)\n", pval_r2)
	}
	printf("{hline 78}\n")
	printf("Note: Rejection in 1) implies the point estimates of reg are unreliable.\n")
	printf("      Rejection in 2) implies the standard errors of reg are unreliable.\n")
    st_numscalar(nname, n)
    st_numscalar(kname, k)
    st_numscalar(pval1name, pval_r1)
    st_numscalar(pval2name, pval_r2)
}
//////////////////////////////////////////////////////////////////////////////// 
// Test for ivreg
void test_iv( string scalar yv, string scalar xv, string scalar touse, string scalar iv, string scalar nname, string scalar kname, string scalar pval1name, string scalar pval2name, real scalar k, real scalar alpha, real scalar maxW, real scalar prec) 
{
	printf("\n{hline 78}\n")
	printf("Executing:  Sasaki, Y. & Wang, Y. (2021): Diagnostic Testing of Finite Moment\n")
	printf("            Conditions for the Consistency and Root-N Asymptotic Normality\n")
	printf("            of the GMM and M Estimators. Journal of Business & Economic\n")
	printf("            Statistics, forthcoming.\n")
	printf("{hline 78}\n")
	
	// Set Data ////////////////////////////////////////////////////////////////
    y      = st_data(., yv, touse)
    x      = st_data(., xv, touse)
	z = st_data(., iv, touse)
    n = rows(y)
	if( cols(x)>1 ){
	 z = J(n,1,1),z,x[,2..cols(x)]
	}else{
	 z = J(n,1,1),z
	}
	x = J(n,1,1),x
	dimx = cols(x)
	if( k < 3 ){
	 k = max(3 \ ceil(0.05*n))
	}
	
	// Compute The Null Distribution of The Test Statistic /////////////////////
	stat_dist = J(ceil(1/prec),1,0)
	for( idx = 1 ; idx <= ceil(1/prec) ; idx++ ){
	 Estar = lowertriangle(J(k,1,rexponential(1,k,1)))
	 sumEstar = rowsum(Estar)
	 Vorder = sumEstar:^(-1):-1
	 Vstar = ( Vorder :- Vorder[k,1] ) :/ ( Vorder[1] - Vorder[k] )
	 stat_dist[idx,1] = getteststat(Vstar,k,maxW)
	}

	// 2SLS ////////////////////////////////////////////////////////////////////
	OLS = luinv(z'*x)*z'*y
	u = y - x*OLS
	A1 = rowsum( ( J(1,dimx,u) :* x ):^2 ):^(1/2)
	A2 = rowsum( ( J(1,dimx,u) :* x ):^2 ):^(2/2)

	// COMPUTE TGE TEST STATISTICS AND P VALUES ////////////////////////////////
	A1order = sort(A1,-1)
	A2order = sort(A2,-1)
	A1star = (A1order[1..k]:-A1order[k]) :/ (A1order[1]-A1order[k])
	A2star = (A2order[1..k]:-A2order[k]) :/ (A2order[1]-A2order[k])
	test_stat_r1 = getteststat(A1star,k,maxW)
	test_stat_r2 = getteststat(A2star,k,maxW)
	pval_r1 = mean( stat_dist :> test_stat_r1 )
	pval_r2 = mean( stat_dist :> test_stat_r2 )

	printf("Outlier Test for 2SLS (ivreg)                                   Obs = %8.0f\n", n)
	printf("                                                                  k = %8.0f\n", k)
	printf("                                                              alpha =    %4.3f\n", alpha)
	printf("{hline 78}\n")
	if( pval_r1 < alpha ){
	printf("1) Test rejects the null hypothesis of consistency.             (p-value=%3.2f)\n", pval_r1)
	}else{
	printf("1) Test fails to reject the null hypothesis of consistency.     (p-value=%3.2f)\n", pval_r1)
	}
	if( pval_r2 < alpha ){
	printf("2) Test rejects the null hypothesis of root-n normality.        (p-value=%3.2f)\n", pval_r2)
	}else{
	printf("2) Test fails to reject the null hypothesis of root-n normality.(p-value=%3.2f)\n", pval_r2)
	}
	printf("{hline 78}\n")
	printf("Note: Rejection in 1) implies the point estimates of ivreg are unreliable.\n")
	printf("      Rejection in 2) implies the standard errors of ivreg are unreliable.\n")
    st_numscalar(nname, n)
    st_numscalar(kname, k)
    st_numscalar(pval1name, pval_r1)
    st_numscalar(pval2name, pval_r2)
}
end
////////////////////////////////////////////////////////////////////////////////


		
		
		
		
		
		
		
		
		
		
				
