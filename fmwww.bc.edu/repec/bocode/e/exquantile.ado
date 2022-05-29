////////////////////////////////////////////////////////////////////////////////
// Stata fpr Sasaki, Y. & Wang, Y. (2022): Fixed-k Inference for Conditional 
// Extremal Quantiles. Journal of Business & Economic Statistics, 40(2): 829-837
////////////////////////////////////////////////////////////////////////////////
 program define exquantile, eclass
    version 14.2
 
    syntax varlist(min=1 max=2 numeric) [if] [in] [, q(real 0.99), k(real 0), xval(real 999999)]
    marksample touse
 
    gettoken depvar indepvars : varlist
    _fv_check_depvar `depvar'
    fvexpand `indepvars' 
    local cnames `r(varlist)'
 
    tempname b V N kk

	// The following part focuses on the case of conditional quantiles with
	// panel data or repeated cross sections
	if "`cnames'" != "" {
			qui xtset
			local panelid   = r(panelvar)
			local timeid  = r(timevar)
	
			mata: estimation("`depvar'", "`cnames'", `q', `k', `xval', ///
						 "`panelid'", "`timeid'", ///
						 "`touse'", "`b'", "`V'", "`N'", "`kk'") 
 
			local cnames Quantile
 
			matrix colnames `b' = `cnames'
			matrix colnames `V' = `cnames'
			matrix rownames `V' = `cnames'
	}
	// The following part focuses on the case of unconditional quantiles
	if "`cnames'" == "" {
			mata: estimation_noX("`depvar'", `q', `k', ///
							 "`touse'", "`b'", "`V'", "`N'", "`kk'") 
 
			local cnames Quantile 
 
			matrix colnames `b' = `cnames'
			matrix colnames `V' = `cnames'
			matrix rownames `V' = `cnames'
	}

    ereturn post `b' `V', esample(`touse') buildfvinfo
    ereturn scalar N    = `N'
	ereturn scalar k    = `kk'
	ereturn scalar q    = `q'
    ereturn local  cmd  "exquantile"
 
    ereturn display
	di "*  exquantile is based on Sasaki, Y. & Wang, Y. (2022): Fixed-k Inference for"
	di "   Conditional Extremal Quantiles. Journal of Business & Economic Statistics,"
	di "   40 (2): 829-837."
end
////////////////////////////////////////////////////////////////////////////////
 
mata:
//////////////////////////////////////////////////////////////////////////////// 
// Estimation with X
void estimation( string scalar depvar,  string scalar indepvars, 
				 real scalar q,         real scalar k,         real scalar xval,
				 string scalar panelid, string scalar timeid,  
				 string scalar touse,   string scalar bname,   
				 string scalar Vname,   string scalar nname,
				 string scalar kname) 
{
    real vector y, x, year
    real matrix X
    real scalar n
	
    y    = st_data(., depvar, touse)
    x    = st_data(., indepvars, touse)
    year = st_data(., timeid, touse)
	id   = st_data(., panelid, touse)
    n    = rows(y)
	
	if( 0.05 < q & q < 0.95 ){
	 printf("\n\n                Warning: q = %f is not an extreme quantile\n\n",q)
	}
	
	////////////////////////////////////////////////////////////////////////////
	// Get Nearest Neighbor y
	////////////////////////////////////////////////////////////////////////////
	if( xval == 999999 ){
  	 xval = mean(x)
	}

	uniqueids = uniqrows(id)
	nnY = J(length(uniqueids),1,0)
	real scalar minidx
	for( idx = 1 ; idx <= length(uniqueids) ; idx ++ ){
	 curr_xy = select((x,y),id:==uniqueids[idx]) 
	 minindex(abs(curr_xy[.,1] :- xval),1,minidx=.,.)
	 nnY[idx,1] = curr_xy[minidx[1,1],2]
	}
	y = nnY
	n = rows(y)
	
	////////////////////////////////////////////////////////////////////////////
	// Set k = 0.05*n If Not Set & And Normalize y
	////////////////////////////////////////////////////////////////////////////
	if( k <= 0 ){
	 k = floor(0.05*n^0.99)
	}
	normy = y :- sort(y,1)[floor(n/2),1]
	
	////////////////////////////////////////////////////////////////////////////
	// Estimator
	////////////////////////////////////////////////////////////////////////////
	hill_right = mean( log(sort(normy,1)[(n-k+1..n),1] :/ sort(normy,1)[n-k+1,1]) )
	hill_quantile_right_normalized = sort(normy,1)[n-k,1] * (k/(n*(1-q)))^hill_right
	hill_quantile_right = sort(normy,1)[n-k,1] * (k/(n*(1-q)))^hill_right :+ sort(y,1)[floor(n/2),1]
	hill = hill_right
	hill_quantile = hill_quantile_right
	
	hill_left  = mean( log(sort(normy,1)[(1..k),1] :/ sort(normy,1)[k,1]) )
	hill_quantile_left_normalized = sort(normy,1)[k+1,1] * (k/(n*q))^hill_right
	hill_quantile_left = sort(normy,1)[k+1,1] * (k/(n*q))^hill_right :+ sort(y,1)[floor(n/2),1]
	if( q < 0.5 ){
 	 hill = hill_left
	 hill_quantile = hill_quantile_left
	}

	////////////////////////////////////////////////////////////////////////////
	// Variance of Estimator
	////////////////////////////////////////////////////////////////////////////
	hill_quantile_right_variance = hill_right^2 * hill_quantile_right_normalized^2 * ( log( k / n / (1-q) ) )^2 / k
	hill_quantile_variance = hill_quantile_right_variance
	hill_quantile_left_variance = hill_left^2 * hill_quantile_left_normalized^2 * ( log( k / n / q ) )^2 / k
	if( q < 0.5 ){
	 hill_quantile_variance = hill_quantile_left_variance
	}

	printf("\n{hline 58}")
	printf("\nConditional %f-th Extreme Quantile Given X=%f",q,xval)
	printf("\nObservations: %f",n)
	printf("\n           k: %f",k)
	printf("\n           q: %f",q)
	printf("\n           x: %f",xval)
	printf("\n{hline 58}")
	printf("\n\n")
	b = hill_quantile
	V = hill_quantile_variance

    st_matrix(bname, b')
    st_matrix(Vname, V)
    st_numscalar(nname, n)
	st_numscalar(kname, k)
}

//////////////////////////////////////////////////////////////////////////////// 
// Estimation with NO X
void estimation_noX( string scalar depvar,  real scalar q,         real scalar k,
					 string scalar touse,   string scalar bname,   
					 string scalar Vname,   string scalar nname,
					 string scalar kname) 
{
    real vector y
    real scalar n
 
    y = st_data(., depvar, touse)
    n = rows(y)
	
	if( 0.05 < q & q < 0.95 ){
	 printf("\n\n                Warning: q = %f is not an extreme quantile\n\n",q)
	}

	////////////////////////////////////////////////////////////////////////////
	// Set k = 0.05*n If Not Set & And Normalize y
	////////////////////////////////////////////////////////////////////////////
	if( k <= 0 ){
	 k = floor(0.05*n^0.99)
	}
	normy = y :- sort(y,1)[floor(n/2),1]

	////////////////////////////////////////////////////////////////////////////
	// Estimator
	////////////////////////////////////////////////////////////////////////////
	hill_right = mean( log(sort(normy,1)[(n-k+1..n),1] :/ sort(normy,1)[n-k+1,1]) )
	hill_quantile_right_normalized = sort(normy,1)[n-k,1] * (k/(n*(1-q)))^hill_right
	hill_quantile_right = sort(normy,1)[n-k,1] * (k/(n*(1-q)))^hill_right :+ sort(y,1)[floor(n/2),1]
	hill = hill_right
	hill_quantile = hill_quantile_right
	
	hill_left  = mean( log(sort(normy,1)[(1..k),1] :/ sort(normy,1)[k,1]) )
	hill_quantile_left_normalized = sort(normy,1)[k+1,1] * (k/(n*q))^hill_right
	hill_quantile_left = sort(normy,1)[k+1,1] * (k/(n*q))^hill_right :+ sort(y,1)[floor(n/2),1]
	if( q < 0.5 ){
 	 hill = hill_left
	 hill_quantile = hill_quantile_left
	}

	////////////////////////////////////////////////////////////////////////////
	// Variance of Estimator
	////////////////////////////////////////////////////////////////////////////
	hill_quantile_right_variance = hill_right^2 * hill_quantile_right_normalized^2 * ( log( k / n / (1-q) ) )^2 / k
	hill_quantile_variance = hill_quantile_right_variance
	hill_quantile_left_variance = hill_left^2 * hill_quantile_left_normalized^2 * ( log( k / n / q ) )^2 / k
	if( q < 0.5 ){
	 hill_quantile_variance = hill_quantile_left_variance
	}

	printf("\n{hline 37}")
	printf("\nUnconditional %f-th Extreme Quantile",q)
	printf("\nObservations: %f",n)
	printf("\n           k: %f",k)
	printf("\n           q: %f",q)
	printf("\n{hline 37}")
	printf("\n\n")
	b = hill_quantile
	V = hill_quantile_variance

    st_matrix(bname, b')
    st_matrix(Vname, V)
    st_numscalar(nname, n)
	st_numscalar(kname, k)
}

end
////////////////////////////////////////////////////////////////////////////////

