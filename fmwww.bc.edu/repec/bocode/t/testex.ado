////////////////////////////////////////////////////////////////////////////////
// STATA FOR  D'Haultfoeuille, X., Hoderlein, S & Sasaki, Y. (2021): Testing and 
//            Relaxing the Exclusion Restriction in the Control Function 
//            Approach. Journal of Econometrics, forthcoming.
//
// Use it when you consider running an IV regression and want to test the
// exclusion restriction of the instrumental variable.
////////////////////////////////////////////////////////////////////////////////
program define testex, rclass
    version 14.2
 
    syntax varlist(numeric) [if] [in] [, numboot(real 1000)]
    marksample touse
 
    gettoken depvar indepvars : varlist
    _fv_check_depvar `depvar'
    fvexpand `indepvars' 
    local cnames `r(varlist)'

	tempname N h KS Pval
	mata: test("`depvar'", "`cnames'","`touse'",`numboot',"`N'","`KS'","`Pval'","`h'")

	return scalar p = `Pval'
	return scalar KS = `KS'
	return scalar bw = `h'
	return scalar nb = `numboot'
    return scalar N = `N'
    return local cmd "testex"
end
		
mata:
//////////////////////////////////////////////////////////////////////////////// 
// Kernel Function
void kernel(u, kout){
	kout = 0.75 :* ( 1 :- (u:^2) ) :* ( -1 :< u ) :* ( u :< 1 )
}
//////////////////////////////////////////////////////////////////////////////// 
// Test
void test( string scalar yv, string scalar xv, string scalar touse, real scalar numboot, string scalar nname, string scalar ksname, string scalar pvalname, string scalar hname) 
{
	printf("\n{hline 78}\n")
	printf("Executing:  D'Haultfoeuille, X., Hoderlein, S & Sasaki, Y. (2021): Testing and\n")
	printf("            Relaxing the Exclusion Restriction in the Control Function \n")
	printf("            Approach. Journal of Econometrics, forthcoming.\n")
	printf("{hline 78}\n")
    real vector y, xz 
    real scalar n
 
    y      = st_data(., yv, touse)
    xz      = st_data(., xv, touse)
	x = xz[,1]
	z = xz[,2]
	z = z:>mean(z)
    n = rows(y)
	
//////////////////////////////////////////////////////////////////////////////// 
// Make xlist
	x1 = sort(x,1)[floor(0.01*n)]
	x2 = sort(x,1)[floor(0.99*n)]
	xlist = (0..1000) :/ 1000 :*(x2-x1) :+ x1
	
//////////////////////////////////////////////////////////////////////////////// 
// Make ylist
	y1 = sort(y,1)[floor(0.01*n)]
	y2 = sort(y,1)[floor(0.99*n)]
	ylist = (0..1000) :/ 1000 :*(y2-y1) :+ y1

//////////////////////////////////////////////////////////////////////////////// 
// Get F_{X|Z} And x*
	printf("\n  Computing x star.\n")
	FXZ0 = J(length(xlist),1,0)
	FXZ1 = J(length(xlist),1,0)
	for( idx=1 ; idx<=length(xlist) ; idx++ ){
		FXZ0[idx] = sum( ( x :<= xlist[idx] ) :* (z :== 0) ) / sum( z :== 0 )
		FXZ1[idx] = sum( ( x :<= xlist[idx] ) :* (z :== 1) ) / sum( z :== 1 )
	}
	real colvector v
	minindex(abs(FXZ1-FXZ0),1, v=., .)
	xstar = x[v[1]]
	
	if( abs(FXZ1[v[1]]-FXZ0[v[1]])>0.01 ){
	 printf("  (Warning: no CDF crossing at the tolerance level of 1%%.)\n")
	}

//////////////////////////////////////////////////////////////////////////////// 
// Bandwidth
	printf("\n  Computing the bandwidth.\n")
	hlist = (1..20)/10 :* variance(x)^0.5;
	medy = sort(y,1)[floor(n*0.5)]

	cvSSE = 0 :* hlist;

	for( jdx = 1 ; jdx <= length(hlist) ;jdx++ ){
		h = hlist[jdx]

		for( idx = 1 ; idx <= n ; idx++ ){
			allbutidx = selectindex((1..n) :!= idx)
			real vector kout
			kernel((x[allbutidx] :- x[idx]):/ h, kout)
			predict = mean( ( y[allbutidx] :<= medy ) :* ( kout ) :* ( z[allbutidx] :== z[idx] ) ) / mean( ( kout ) :* ( z[allbutidx] :== z[idx] ) :+ 0.000001 )
			sqerr = ( ( y[idx] <= medy ) - predict )^2;
			cvSSE[jdx] = cvSSE[jdx] + sqerr;
		}
	}
	
	minindex(cvSSE,1, v=., .)
	h = hlist[v[1]] * n^( 1/5 - 5/12 );

//////////////////////////////////////////////////////////////////////////////// 
// Estimate F_{Y|XZ} And KS-Statistic
	printf("\n  Computing the KS statistic.\n")
	FYXZ0 = J(length(ylist),1,0)
	FYXZ1 = J(length(ylist),1,0)
	kernel((x :- xstar):/ h, kout)

	for( idx = 1 ; idx <= length(ylist) ; idx++ ){
		yval = ylist[idx]
		FYXZ0[idx] = mean( ( y :<= yval ) :* ( kout ) :* ( z :== 0 ) ) / mean( ( kout ) :* ( z :== 0 ) :+ 0.000001 )
		FYXZ1[idx] = mean( ( y :<= yval ) :* ( kout ) :* ( z :== 1 ) ) / mean( ( kout ) :* ( z :== 1 ) :+ 0.000001 )
	}
	KS = (n*h)^0.5 * max( abs( FYXZ1 - FYXZ0 ) )

//////////////////////////////////////////////////////////////////////////////// 
// Multiplier Bootstrap
	printf("\n  Executing multiplier bootstrap.\n")
	IFZ0 = J(n,length(ylist),0)
	IFZ1 = J(n,length(ylist),0)
	xindices = J(n,1,0)
	for( idx = 1 ; idx <= n ; idx++ ){
		minindex(abs( x[idx] :- xlist ),1, v=., .)
		xindices[idx] = v[1]
	}
	
	for( idx = 1 ; idx <= length(ylist) ; idx++ ){
	yval = ylist[idx]
	
	IFZ0[,idx] = (n*h)^0.5 :* ( ( y :<= yval ) :- FYXZ0[xindices,] ) :* ( kout ) :* ( z :== 0 ) :/ sum( ( kout ) :* ( z :== 0 ) :+ 0.000001 / n )
	IFZ1[,idx] = (n*h)^0.5 :* ( ( y :<= yval ) :- FYXZ1[xindices,] ) :* ( kout ) :* ( z :== 1 ) :/ sum( ( kout ) :* ( z :== 1 ) :+ 0.000001 / n )
	}
	
	MB = J(numboot,1,0)
	for( idx = 1 ; idx <= numboot ; idx++ ){
		xi = invnormal(uniform(n,1))
		MB[idx] = max( abs( colsum( J(1,length(ylist),xi) :* ( IFZ1 - IFZ0 ) ) ) )
	}
	pval = sum( sort(MB,1) :> KS ) / numboot
	
//////////////////////////////////////////////////////////////////////////////// 
// Display Results
	printf("\n{hline 78}\n")
	printf("  Null hypothesis: Exclusion restriction is satified.")
	printf("\n{hline 78}\n")
	printf("                                                     KS statistic = %10.3f\n",KS)
	printf("                                                          p-value = %10.3f\n",pval)
	printf("                                                     {hline 25}\n")
	if( pval <= 0.10 ){
	printf("             Reject the null hypothesis at the significance level of 10%%.\n")
	}else{
	printf("     Fail to reject the null hypothesis at the significance level of 10%%.\n")
	}
	if( pval <= 0.05 ){
	printf("             Reject the null hypothesis at the significance level of  5%%.\n")
	}else{
	printf("     Fail to reject the null hypothesis at the significance level of  5%%.\n")
	}
	if( pval <= 0.01 ){
	printf("             Reject the null hypothesis at the significance level of  1%%.\n")
	}else{
	printf("     Fail to reject the null hypothesis at the significance level of  1%%.\n")
	}
	printf("{hline 78}\n")
	
    st_numscalar(nname, n)
	st_numscalar(ksname, KS)
	st_numscalar(pvalname, pval)
	st_numscalar(hname, h)
}
end
////////////////////////////////////////////////////////////////////////////////


		
		
		
		
		
		
		
		
		
		
				
