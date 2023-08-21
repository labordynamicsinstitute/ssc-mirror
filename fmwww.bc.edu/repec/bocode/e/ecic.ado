////////////////////////////////////////////////////////////////////////////////
// Stata Command for Sasaki, Y. & Wang, Y. (2022): Extreme Changes in Changes.
////////////////////////////////////////////////////////////////////////////////
 program define ecic, eclass
    version 14.2
 
    syntax varlist(min=3 max=3 numeric) [if] [in] [, q(real 0.99)]
    marksample touse
 
    gettoken depvar indepvars : varlist
    _fv_check_depvar `depvar'
    fvexpand `indepvars' 
    local cnames `r(varlist)'
 
    tempname b V N n00 n01 n10 n11 k00 k01 k10 k11

	mata: estimation("`depvar'", "`cnames'", `q', "`touse'", "`b'", "`V'",  ///
					 "`N'", "`n00'", "`n01'", "`n10'", "`n11'", ///
					 "`k00'", "`k01'", "`k10'", "`k11'" ) 

	local cnames QTE
 
	matrix colnames `b' = `cnames'
	matrix colnames `V' = `cnames'
	matrix rownames `V' = `cnames'

    ereturn post `b' `V', esample(`touse') buildfvinfo
    ereturn scalar N    = `N'
	ereturn scalar n00  = `n00'
	ereturn scalar n01  = `n01'
	ereturn scalar n10  = `n10'
	ereturn scalar n11  = `n11'
	ereturn scalar k00  = `k00'
	ereturn scalar k01  = `k01'
	ereturn scalar k10  = `k10'
	ereturn scalar k11  = `k11'
	ereturn scalar q    = `q'
    ereturn local  cmd  "ecic"
 
    ereturn display
	di "*  ecic is based on Sasaki, Y. & Wang, Y: Extreme Changes in Changes."
	di "   Journal of Business & Economic Statistics, Forthcoming."
end
////////////////////////////////////////////////////////////////////////////////
 
mata:
//////////////////////////////////////////////////////////////////////////////// 
// Function: Choose k
real scalar chooseK(real vector vY){
	N = rows(vY)
	minK = ceil(1.0*N/100)+1
	maxK = ceil(10.0*N/100)-1
	TK = J(maxK,1,0)
	
	for( K = minK ; K <= maxK ; K++ ){
		Zi = (1..K)' :* log(vY[1..K] :/ vY[2..(K+1)])
		xi_hat = mean( log(vY[1..K]) :- log(vY[K+1]) )
		wi = sign(K:-2:*(1..K)':+1) :* abs(K:-2:*(1..K)':+1)
		UK = sum( wi:*Zi )
		TK[K,1] = UK / xi_hat / (sum(wi:^2))^0.5
	}
	
 	CK = J(maxK,1,0)
	for( K = ceil(maxK/50) ; K+floor(K/2) <=maxK ; K++ ){
		l = floor(K/2)
		CK[K] = sum(TK[K:+(-l..l),1]:^2) / (2*l + 1)
	}
	K = min( select((1..rows(CK))',CK :> 1) )
	if( K == . ){
		K = minK
	}
	return( ceil(K^0.9) ) 
}
//////////////////////////////////////////////////////////////////////////////// 
// Estimation and Inference
void estimation( string scalar depvar,  string scalar indepvars, 
				 real scalar q,
				 string scalar touse,   string scalar bname,   
				 string scalar Vname,   string scalar nname,
				 string scalar n00name,	string scalar n01name, 
				 string scalar n10name, string scalar n11name,
				 string scalar k00name,	string scalar k01name, 
				 string scalar k10name, string scalar k11name ) 
{
	if( 0.05 < q & q < 0.95 ){
	 printf("\n\n                Warning: q = %f is not an extreme quantile\n\n",q)
	}
    
    y    = st_data(., depvar, touse)
	y    = y :- mean(y)
    gt   = st_data(., indepvars, touse)
	G    = gt[.,1]
	T    = gt[.,2]
	Y00  = select(y,(G:==0 :& T:==0))
	Y01  = select(y,(G:==0 :& T:==1))
	Y10  = select(y,(G:==1 :& T:==0))
	Y11  = select(y,(G:==1 :& T:==1))
    n    = rows(y)
	n00  = rows(Y00)
	n01  = rows(Y01)
	n10  = rows(Y10)
	n11  = rows(Y11)
	
	LEFT = 0
	if( q < 0.5 ){
		LEFT = 1
		q = 1 - q
	}
	
	////////////////////////////////////////////////////////////////////////////
	// Choose Tuning Parameter Values
	k00 = chooseK(sort(Y00,-1))
	k01 = chooseK(sort(Y01,-1))
	k10 = chooseK(sort(Y10,-1))
	k11 = chooseK(sort(Y11,-1))

	////////////////////////////////////////////////////////////////////////////
	// Estimate Pareto Exponents
	alpha00hat = mean( log(sort(Y00,-1)[1..k00,1]) :- log(sort(Y00,-1)[k00+1,1]) )^(-1)
	alpha01hat = mean( log(sort(Y01,-1)[1..k01,1]) :- log(sort(Y01,-1)[k01+1,1]) )^(-1)
	alpha10hat = mean( log(sort(Y10,-1)[1..k10,1]) :- log(sort(Y10,-1)[k10+1,1]) )^(-1)
	alpha11hat = mean( log(sort(Y11,-1)[1..k11,1]) :- log(sort(Y11,-1)[k11+1,1]) )^(-1)
	
	////////////////////////////////////////////////////////////////////////////
	// Estimate QTE
	tauhat = sort(Y11,-1)[k11+1,1] * (k11/n11/(1-q))^(1/alpha11hat) - sort(Y01,-1)[k01+1,1] * (k01/n01*n00/k00 * ( ( sort(Y10,-1)[k10+1,1] * (k10/n10/(1-q) )^(1/alpha10hat) ) / sort(Y00,-1)[k00+1,1] )^(alpha00hat) )^(1/alpha01hat)
	
	////////////////////////////////////////////////////////////////////////////
	// Variance Estimation
	varsigma1 = sort(Y11,-1)[k11+1,1] * (k11/n11/(1-q))^(1/alpha11hat)
	varsigma2 = sort(Y01,-1)[k01+1,1] * ( k01/n01*n00/k00 * (( sort(Y10,-1)[k10+1,1] * (k10/n10/(1-q))^(1/alpha10hat) ) / sort(Y00,-1)[k00+1,1] )^(alpha00hat) )^(1/alpha01hat) 
	Omega = varsigma1^2 / alpha11hat^2 +
        varsigma2^2 * (k11/k10)^2/(n11/n10)^2 *
        (k11/k00*alpha00hat^2/alpha10hat^2/alpha01hat^2 + 
         k11/k10*alpha00hat^2/alpha10hat^2/alpha01hat^2 + 
         k11/k01*alpha00hat^2/alpha10hat^2/alpha01hat^2 )
	minD = 10
	V_tauhat = Omega * (log(max((minD,k11/(n11*(1-q))))))^2 / k11
	
	if( LEFT > 0 ){
		q = 1 - q
		tauhat = -tauhat
	}

	printf("\n{hline 78}")
	printf("\nExtreme Changes in Changes\nQuantile Treatment Effect (QTE) at the %f-th Quantile",q)
	printf("\n{hline 78}")
	printf("\n     Observations: n00 =%8.0f; n01 =%8.0f; n10 =%8.0f; n11 =%8.0f",n00,n01,n10,n11)
	printf("\n Order Statistics: k00 =%8.0f; k01 =%8.0f; k10 =%8.0f; k11 =%8.0f",k00,k01,k10,k11)
	printf("\n         Quantile: q = %f",q)
	printf("\n")
	b = tauhat
	V = V_tauhat

    st_matrix(bname, b)
    st_matrix(Vname, V)
    st_numscalar(nname, n)
    st_numscalar(n00name, n00)
    st_numscalar(n01name, n01)
    st_numscalar(n10name, n10)
    st_numscalar(n11name, n11)
    st_numscalar(k00name, k00)
    st_numscalar(k01name, k01)
    st_numscalar(k10name, k10)
    st_numscalar(k11name, k11)
}

end
////////////////////////////////////////////////////////////////////////////////

