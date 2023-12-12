////////////////////////////////////////////////////////////////////////////////
// STATA FOR        Chiang, H., Kato, K., Ma, Y. & Sasaki, Y. (2021): Multiway 
// Cluster Robust Double/Debiased Machine Learning. Journal of Business & 
// Economic Statistics, forthcoming.
////////////////////////////////////////////////////////////////////////////////
program define crhdreg, eclass
    version 14.2
 
    syntax varlist(numeric  min=3) [if] [in] [, cluster1(varname) cluster2(varname) iv(varlist) dimension(real 1) folds(real 1) resample(real 10) median alpha(real 1) tol(real 0.000001) maxiter(real 1000)]
    marksample touse
 
    gettoken depvar indepvars : varlist
    _fv_check_depvar `depvar'
    fvexpand `indepvars' 
    local cnames `r(varlist)'
	
	local varnames
	local iter = 0
	foreach var of varlist `varlist' {
		if( 1 <= `iter' & `iter' <= `dimension' ){
			local varnames `varnames' "`var'"
		}
		local iter = `iter' + 1
	}
	
	local rob = 1
	local fsa = "median"
	if "`median'" == "" {  // Median version of finite-sample adjustment
	  local rob = 0
	  local fsa = "mean"
	}

    tempname b V N p ways K G1 G2
	
	////////////////////////////////////////////////////////////////////////////
	// Regression 
	if "`iv'" == "" & "`cluster1'" == "" {
		mata: reg0("`depvar'", "`cnames'", "`touse'", ///
				   `dimension', `folds', `alpha', `resample', `rob', `tol', `maxiter', ///
				   "`b'", "`V'", "`N'", "`p'", "`ways'", "`K'", "`G1'", "`G2'")
	}
				   
	////////////////////////////////////////////////////////////////////////////
	// IV Regression 
	if "`iv'" != "" & "`cluster1'" == "" {
		//tempvar ivvar
		//gen `ivvar' = `iv'
		mata: ivreg0("`depvar'", "`cnames'", "`touse'", "`iv'", ///
				     `dimension', `folds', `alpha', `resample', `rob', `tol', `maxiter', ///
				     "`b'", "`V'", "`N'", "`p'", "`ways'", "`K'", "`G1'", "`G2'")
	}
	
	////////////////////////////////////////////////////////////////////////////
	// 1-Way Cluster Robust Regression 
	if "`iv'" == "" & "`cluster1'" != "" & "`cluster2'" == "" {
		tempvar c1
		gen `c1' = `cluster1'
		mata: reg1("`depvar'", "`cnames'", "`touse'", "`c1'", ///
				   `dimension', `folds', `alpha', `resample', `rob', `tol', `maxiter', ///
				   "`b'", "`V'", "`N'", "`p'", "`ways'", "`K'", "`G1'", "`G2'")
	}
	
	////////////////////////////////////////////////////////////////////////////
	// 1-Way Cluster Robust IV Regression 
	if "`iv'" != "" & "`cluster1'" != "" & "`cluster2'" == "" {
		//tempvar ivvar
		//gen `ivvar' = `iv'
		tempvar c1
		gen `c1' = `cluster1'
		mata: ivreg1("`depvar'", "`cnames'", "`touse'", "`iv'", "`c1'", ///
				     `dimension', `folds', `alpha', `resample', `rob', `tol', `maxiter', ///
				     "`b'", "`V'", "`N'", "`p'", "`ways'", "`K'", "`G1'", "`G2'")
	}
	
	////////////////////////////////////////////////////////////////////////////
	// 2-Way Cluster Robust Regression 
	if "`iv'" == "" & "`cluster1'" != "" & "`cluster2'" != "" {
		tempvar c1
		gen `c1' = `cluster1'
		tempvar c2
		gen `c2' = `cluster2'
		mata: reg2("`depvar'", "`cnames'", "`touse'", "`c1'", "`c2'", ///
				   `dimension', `folds', `alpha', `resample', `rob', `tol', `maxiter', ///
				   "`b'", "`V'", "`N'", "`p'", "`ways'", "`K'", "`G1'", "`G2'")
	}
	
	////////////////////////////////////////////////////////////////////////////
	// 2-Way Cluster Robust IV Regression 
	if "`iv'" != "" & "`cluster1'" != "" & "`cluster2'" != "" {
		//tempvar ivvar
		//gen `ivvar' = `iv'
		tempvar c1
		gen `c1' = `cluster1'
		tempvar c2
		gen `c2' = `cluster2'
		mata: ivreg2("`depvar'", "`cnames'", "`touse'", "`iv'", "`c1'", "`c2'", ///
				     `dimension', `folds', `alpha', `resample', `rob', `tol', `maxiter', ///
				     "`b'", "`V'", "`N'", "`p'", "`ways'", "`K'", "`G1'", "`G2'")
	}

	matrix colnames `b' = `varnames'
	matrix colnames `V' = `varnames'
	matrix rownames `V' = `varnames'
		
    ereturn post `b' `V', esample(`touse') buildfvinfo
    ereturn scalar N = `N'
	ereturn scalar ways = `ways'
	ereturn scalar G1 = `G1'
	ereturn scalar G2 = `G2'
	ereturn scalar dimD = `dimension'
	ereturn scalar dimX = `p'
	ereturn scalar K = `K'
	ereturn scalar alpha = `alpha'
	ereturn scalar fsa_n = `resample'
    ereturn local cmd "crhdreg"
	ereturn local cluster1 "`cluster1'"
	ereturn local cluster2 "`cluster2'"
	ereturn local iv "`iv'"
	ereturn local fsa_m "`fsa'" //Finite sample adjustment method
    ereturn display

	di "* crhdreg is based on Chiang, H., K. Kato, Y. Ma, & Y. Sasaki (2022) Multiway"
	di "          Cluster Robust Double/Debiased Machine Learning. Journal of Business"
	di "          & Economic Statistics, 40(3), pp. 1046-1056."

end

		
			
		
mata:
//////////////////////////////////////////////////////////////////////////////// 
// ELASTIC NET OBJECTIVE FUNCTION
////////////////////////////////////////////////////////////////////////////////
void objective(todo,beta,Y,X,lambda,alpha,crit,g,H){
	crit = ( mean((Y:-X*beta'):^2)/2 + lambda * ((1-alpha)*sum(beta:^2)/2 + alpha*sum(abs(beta)) ) )
}

//////////////////////////////////////////////////////////////////////////////// 
// GLMNET FUNCTION
////////////////////////////////////////////////////////////////////////////////
real vector glmnet(Y,X,lambda,alpha,TOLERANCE,MAXITER){
	S = optimize_init()
	optimize_init_evaluator(S,&objective())
	optimize_init_which(S,"min")
	optimize_init_evaluatortype(S, "d0")
	optimize_init_technique(S,"nm")
	optimize_init_nmsimplexdeltas(S,1)
	optimize_init_singularHmethod(S,"hybrid") 
	optimize_init_argument(S,1,Y)
	optimize_init_argument(S,2,X)
	optimize_init_argument(S,3,lambda)
	optimize_init_argument(S,4,alpha)
	optimize_init_params(S, J(1,cols(X),0))
	optimize_init_conv_ptol(S,TOLERANCE)
	optimize_init_conv_maxiter(S,MAXITER)
	optimize_init_conv_warning(S,"off")
	optimize_init_tracelevel(S,"none")
	est=optimize(S)	
	return( est' )
}

//////////////////////////////////////////////////////////////////////////////// 
// GET SCALE FUNCTION
////////////////////////////////////////////////////////////////////////////////
real matrix get_scale(X){
	sd = J(cols(X),1,0)
	for( idx = 1 ; idx <= cols(X) ; idx++ ){
		sd[idx,1] = variance(X[,idx])^0.5
	}
	return( sd )
}

//////////////////////////////////////////////////////////////////////////////// 
// SCALE FUNCTION
////////////////////////////////////////////////////////////////////////////////
real matrix scale(X){
	for( idx = 1 ; idx <= cols(X) ; idx++ ){
		X[,idx] = (X[,idx] :- mean(X[,idx])):/(variance(X[,idx])^0.5)
	}
	return( X )
}

//////////////////////////////////////////////////////////////////////////////// 
// MEDIAN FUNCTION
////////////////////////////////////////////////////////////////////////////////
real matrix median(x){
	return ( sort(x,1)[ceil(rows(x)/2),1] )
}

//////////////////////////////////////////////////////////////////////////////// 
// REGRESSION FOR 0 WAY CLUSTERING /////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
void reg0( string scalar yv,     string scalar dxv,	   string scalar touse,
		   real scalar dimtheta, 					   real scalar K,
		   real scalar alpha,						   real scalar num_resample,
		   real scalar robust,						
		   real scalar TOLERANCE,					   real MAXITER,
		   string scalar bname,  string scalar Vname,  string scalar nname,
		   string scalar pname,	 string scalar wname,  string scalar fname,
		   string scalar g1name, string scalar g2name) 
{
	////////////////////////////////////////////////////////////////////////////
	// DATA ORGANIZATION
    real vector y, d, x
    real scalar n, p

    Y = st_data(., yv, touse)
    dx = st_data(., dxv, touse)
    N = rows(dx)
	D = dx[.,1..dimtheta]
	Z = D
	X = dx[.,(dimtheta+1)..(cols(dx))]
	p = cols(X)
	
	if( K <= 1 ){
	 K = 5
	}
	
	sdD = get_scale(D)
	sdZ = get_scale(Z)
	D = scale(D)
	Z = scale(Z)
	X = scale(X)
	
	list_thetahat = J(dimtheta,num_resample,0)
	list_Var = J(dimtheta,dimtheta*num_resample,0)
	for( iter = 1 ; iter <= num_resample ; iter++ ){
	printf("\nResampled Cross-Fitting: Iteration %3.0f/%f",iter,num_resample)
		fold = ceil(uniform(N,1)*K)
		////////////////////////////////////////////////////////////////////////
		// DML
		lambda_Z = J(dimtheta,1,0)
		lambda_D = J(dimtheta,1,0)
		for( idx = 1 ; idx <= dimtheta ; idx++ ){
			lambda_Z[idx,1] = 0.01*variance(Z[,idx])*((N*(K-1)/K)*log((N*(K-1)/K)*p))^0.5/(N*(K-1)/K)
			lambda_D[idx,1] = 0.01*variance(D[,idx])*((N*(K-1)/K)*log((N*(K-1)/K)*p))^0.5/(N*(K-1)/K)
		}
		lambda_Y = 0.01*variance(Y[,1])*((N*(K-1)/K)*log((N*(K-1)/K)*p))^0.5/(N*(K-1)/K)
		pre_Z = Z
		res_Z = Z
		pre_D = D
		res_D = D
		pre_Y = Y
		res_Y = Y
		for( kdx = 1 ; kdx <= K ; kdx++ ){
			indices = selectindex(fold:!=kdx)
			
			for( idx = 1 ; idx <= dimtheta ; idx++ ){
				xihat = glmnet(Z[indices,idx],(X,J(N,1,1))[indices,],lambda_Z[idx,1],alpha,TOLERANCE,MAXITER)
				pre_Z[indices,idx] = (X,J(N,1,1))[indices,] * xihat
				res_Z[indices,idx] = Z[indices,idx] - pre_Z[indices,idx]
			}
			
			for( idx = 1 ; idx <= dimtheta ; idx++ ){
				gammahat = glmnet(D[indices,idx],(X,J(N,1,1))[indices,],lambda_D[idx,1],alpha,TOLERANCE,MAXITER)
				pre_D[indices,idx] = (X,J(N,1,1))[indices,] * gammahat
				res_D[indices,idx] = D[indices,idx] - pre_D[indices,idx]
			}

			betahat = glmnet(Y[indices,1],(X,J(N,1,1))[indices,],lambda_Y,alpha,TOLERANCE,MAXITER)
			pre_Y[indices,1] = (X,J(N,1,1))[indices,] * betahat
			res_Y[indices,1] = Y[indices,1] - pre_Y[indices,1]
		}
		
		thetahat = 0
		for( kdx = 1 ; kdx <= K ; kdx++ ){
			indices = selectindex(fold:==kdx)
			thetahat = thetahat :+ luinv( res_Z[indices,]' * res_D[indices,] ) * res_Z[indices,]' * res_Y[indices,1]
		}
		thetahat = thetahat :/ K
		list_thetahat[,iter] = thetahat
		res = res_Y :- res_D * thetahat
		
		////////////////////////////////////////////////////////////////////////
		// VARIANCE
		J = res_Z' * res_D :/ N
		sigma2 = 0
		for( kdx = 1 ; kdx <= K ; kdx++ ){
			indices = selectindex(fold:==kdx)
			sigma2 = sigma2 :+(((res*J(1,dimtheta,1)) :* res_Z)[indices,])' * (((res*J(1,dimtheta,1)) :* res_Z)[indices,]) :/ rows(indices)
		}
		Var = luinv(J) * (sigma2:/K) * luinv(J)'
		list_Var[1..dimtheta,(1..dimtheta):+(dimtheta*(iter-1))] = Var
	}

	////////////////////////////////////////////////////////////////////////////
	// MEAN RESULTS
	b = mean(list_thetahat')
	V = 0
	for( iter = 1 ; iter <= num_resample ; iter++ ){
		V = V :+ list_Var[1..dimtheta,(1..dimtheta):+(dimtheta*(iter-1))] + (list_thetahat[,iter]:-b')*(list_thetahat[,iter]:-b')'
	}
	V = V :/ num_resample :/ N
	
	////////////////////////////////////////////////////////////////////////////
	// MEDIAN RESULTS
	rb = b
	list_rVar = list_Var
	for( idx = 1 ; idx <= dimtheta ; idx++ ){
		rb[1,idx] = median(list_thetahat[idx,]')
	}
	for( iter = 1 ; iter <= num_resample ; iter++ ){
		list_rVar[1..dimtheta,(1..dimtheta):+(dimtheta*(iter-1))] = list_Var[1..dimtheta,(1..dimtheta):+(dimtheta*(iter-1))] + (list_thetahat[,iter]:-rb')*(list_thetahat[,iter]:-rb')'
	}
	rV = V
	for( idx = 1 ; idx <= dimtheta ; idx++ ){
		for( jdx = 1 ; jdx <= dimtheta ; jdx++ ){
			rV[idx,jdx] = median((list_rVar[idx,((1..num_resample):-1):*dimtheta:+jdx])')
		}
	}
	rV = rV :/ N

	////////////////////////////////////////////////////////////////////////////
	// RETURN THE RESULTS
	if( robust == 0 ){
		st_matrix(bname, b*diag(1:/sdD))
		st_matrix(Vname, diag(1:/sdD)*V*diag(1:/sdD))
	}
	
	if( robust == 1 ){
		st_matrix(bname, rb*diag(1:/sdD))
		st_matrix(Vname, diag(1:/sdD)*rV*diag(1:/sdD))
	}

	st_numscalar(nname, N)
	st_numscalar(pname, p)
	st_numscalar(wname, 0)
	st_numscalar(fname, K)
	st_numscalar(g1name, 0)
	st_numscalar(g2name, 0)
	
	printf("\n{hline 78}\n")
	printf("                                                    Observations: %12.0f\n",N)
	printf("                                                     Cluster Way:            0\n")
	printf("                                                          dim(D): %12.0f\n",dimtheta)
	printf("                                                          dim(X): %12.0f\n",p)
	printf("                                                         Folds K: %12.0f\n",K)
	printf("{hline 78}\n")
	printf("                   High-Dimensional Regression Based on DML                   \n") 
}
////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////// 
// IV REGRESSION FOR 0 WAY CLUSTERING //////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
void ivreg0( string scalar yv,     string scalar dxv,	   string scalar touse,
			 string scalar iv,
		     real scalar dimtheta, 					   real scalar K,
		     real scalar alpha,						   real scalar num_resample,
		     real scalar robust,						
		     real scalar TOLERANCE,					   real MAXITER,
		     string scalar bname,  string scalar Vname,  string scalar nname,
		     string scalar pname,  string scalar wname,  string scalar fname,
		     string scalar g1name, string scalar g2name)  
{
	////////////////////////////////////////////////////////////////////////////
	// DATA ORGANIZATION
    real vector y, d, x
    real scalar n, p

    Y = st_data(., yv, touse)
    dx = st_data(., dxv, touse)
    N = rows(dx)
	D = dx[.,1..dimtheta]
	Z = st_data(., iv, touse)
	if( dimtheta > 1 ){
		Z = Z, D[,2..dimtheta]
	}
	X = dx[.,(dimtheta+1)..(cols(dx))]
	p = cols(X)
	
	if( K <= 1 ){
	 K = 5
	}
	
	sdD = get_scale(D)
	sdZ = get_scale(Z)
	D = scale(D)
	Z = scale(Z)
	X = scale(X)
	
	list_thetahat = J(dimtheta,num_resample,0)
	list_Var = J(dimtheta,dimtheta*num_resample,0)
	for( iter = 1 ; iter <= num_resample ; iter++ ){
	printf("\nResampled Cross-Fitting: Iteration %3.0f/%f",iter,num_resample)
		fold = ceil(uniform(N,1)*K)
		////////////////////////////////////////////////////////////////////////
		// DML
		lambda_Z = J(dimtheta,1,0)
		lambda_D = J(dimtheta,1,0)
		for( idx = 1 ; idx <= dimtheta ; idx++ ){
			lambda_Z[idx,1] = 0.01*variance(Z[,idx])*((N*(K-1)/K)*log((N*(K-1)/K)*p))^0.5/(N*(K-1)/K)
			lambda_D[idx,1] = 0.01*variance(D[,idx])*((N*(K-1)/K)*log((N*(K-1)/K)*p))^0.5/(N*(K-1)/K)
		}
		lambda_Y = 0.01*variance(Y[,1])*((N*(K-1)/K)*log((N*(K-1)/K)*p))^0.5/(N*(K-1)/K)
		pre_Z = Z
		res_Z = Z
		pre_D = D
		res_D = D
		pre_Y = Y
		res_Y = Y
		for( kdx = 1 ; kdx <= K ; kdx++ ){
			indices = selectindex(fold:!=kdx)
			
			for( idx = 1 ; idx <= dimtheta ; idx++ ){
				xihat = glmnet(Z[indices,idx],(X,J(N,1,1))[indices,],lambda_Z[idx,1],alpha,TOLERANCE,MAXITER)
				pre_Z[indices,idx] = (X,J(N,1,1))[indices,] * xihat
				res_Z[indices,idx] = Z[indices,idx] - pre_Z[indices,idx]
			}
			
			for( idx = 1 ; idx <= dimtheta ; idx++ ){
				gammahat = glmnet(D[indices,idx],(X,J(N,1,1))[indices,],lambda_D[idx,1],alpha,TOLERANCE,MAXITER)
				pre_D[indices,idx] = (X,J(N,1,1))[indices,] * gammahat
				res_D[indices,idx] = D[indices,idx] - pre_D[indices,idx]
			}

			betahat = glmnet(Y[indices,1],(X,J(N,1,1))[indices,],lambda_Y,alpha,TOLERANCE,MAXITER)
			pre_Y[indices,1] = (X,J(N,1,1))[indices,] * betahat
			res_Y[indices,1] = Y[indices,1] - pre_Y[indices,1]
		}
		
		thetahat = 0
		for( kdx = 1 ; kdx <= K ; kdx++ ){
			indices = selectindex(fold:==kdx)
			thetahat = thetahat :+ luinv( res_Z[indices,]' * res_D[indices,] ) * res_Z[indices,]' * res_Y[indices,1]
		}
		thetahat = thetahat :/ K
		list_thetahat[,iter] = thetahat
		res = res_Y :- res_D * thetahat
		
		////////////////////////////////////////////////////////////////////////
		// VARIANCE
		J = res_Z' * res_D :/ N
		sigma2 = 0
		for( kdx = 1 ; kdx <= K ; kdx++ ){
			indices = selectindex(fold:==kdx)
			sigma2 = sigma2 :+(((res*J(1,dimtheta,1)) :* res_Z)[indices,])' * (((res*J(1,dimtheta,1)) :* res_Z)[indices,]) :/ rows(indices)
		}
		Var = luinv(J) * (sigma2:/K) * luinv(J)'
		list_Var[1..dimtheta,(1..dimtheta):+(dimtheta*(iter-1))] = Var
	}

	////////////////////////////////////////////////////////////////////////////
	// MEAN RESULTS
	b = mean(list_thetahat')
	V = 0
	for( iter = 1 ; iter <= num_resample ; iter++ ){
		V = V :+ list_Var[1..dimtheta,(1..dimtheta):+(dimtheta*(iter-1))] + (list_thetahat[,iter]:-b')*(list_thetahat[,iter]:-b')'
	}
	V = V :/ num_resample :/ N
	
	////////////////////////////////////////////////////////////////////////////
	// MEDIAN RESULTS
	rb = b
	list_rVar = list_Var
	for( idx = 1 ; idx <= dimtheta ; idx++ ){
		rb[1,idx] = median(list_thetahat[idx,]')
	}
	for( iter = 1 ; iter <= num_resample ; iter++ ){
		list_rVar[1..dimtheta,(1..dimtheta):+(dimtheta*(iter-1))] = list_Var[1..dimtheta,(1..dimtheta):+(dimtheta*(iter-1))] + (list_thetahat[,iter]:-rb')*(list_thetahat[,iter]:-rb')'
	}
	rV = V
	for( idx = 1 ; idx <= dimtheta ; idx++ ){
		for( jdx = 1 ; jdx <= dimtheta ; jdx++ ){
			rV[idx,jdx] = median((list_rVar[idx,((1..num_resample):-1):*dimtheta:+jdx])')
		}
	}
	rV = rV :/ N
	
	////////////////////////////////////////////////////////////////////////////
	// RETURN THE RESULTS
	if( robust == 0 ){
		st_matrix(bname, b*diag(1:/sdD))
		st_matrix(Vname, diag(1:/sdD)*V*diag(1:/sdD))
	}
	
	if( robust == 1 ){
		st_matrix(bname, rb*diag(1:/sdD))
		st_matrix(Vname, diag(1:/sdD)*rV*diag(1:/sdD))
	}

	st_numscalar(nname, N)
	st_numscalar(pname, p)
	st_numscalar(wname, 0)
	st_numscalar(fname, K)
	st_numscalar(g1name, 0)
	st_numscalar(g2name, 0)
	
	printf("\n{hline 78}\n")
	printf("                                                    Observations: %12.0f\n",N)
	printf("                                                     Cluster Way:            0\n")
	printf("                                                          dim(D): %12.0f\n",dimtheta)
	printf("                                                          dim(X): %12.0f\n",p)
	printf("                                                         Folds K: %12.0f\n",K)
	printf("{hline 78}\n")
	printf("                 High-Dimensional IV Regression Based on DML                  \n") 
}
////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////// 
// REGRESSION FOR 1 WAY CLUSTERING /////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
void reg1( string scalar yv,     string scalar dxv,	   string scalar touse,
		   string scalar cluster1,
		   real scalar dimtheta, 					   real scalar K,
		   real scalar alpha,						   real scalar num_resample,
		   real scalar robust,						
		   real scalar TOLERANCE,					   real MAXITER,
		   string scalar bname,  string scalar Vname,  string scalar nname,
		   string scalar pname,	 string scalar wname,  string scalar fname,
		   string scalar g1name, string scalar g2name)  
{
	////////////////////////////////////////////////////////////////////////////
	// DATA ORGANIZATION
    real vector y, d, x
    real scalar n, p

    Y = st_data(., yv, touse)
    dx = st_data(., dxv, touse)
	g = st_data(., cluster1, touse)
    N = rows(dx)
	D = dx[.,1..dimtheta]
	Z = D
	X = dx[.,(dimtheta+1)..(cols(dx))]
	p = cols(X)
	
	if( K <= 1 ){
	 K = 5
	}
	
	sdD = get_scale(D)
	sdZ = get_scale(Z)
	D = scale(D)
	Z = scale(Z)
	X = scale(X)
	uniqueg = uniqrows(g)
	Ghat = rows(uniqueg)

	list_thetahat = J(dimtheta,num_resample,0)
	list_Var = J(dimtheta,dimtheta*num_resample,0)
	for( iter = 1 ; iter <= num_resample ; iter++ ){
	printf("\nResampled Cross-Fitting: Iteration %3.0f/%f",iter,num_resample)
		fold = ceil(uniform(Ghat,1)*K)
		foldi = J(N,1,0)
		for( idx = 1 ; idx <= N ; idx++ ){
			foldi[idx] = fold[selectindex(g[idx,1] :== uniqueg),1]
		}
		////////////////////////////////////////////////////////////////////////
		// DML
		lambda_Z = J(dimtheta,1,0)
		lambda_D = J(dimtheta,1,0)
		for( idx = 1 ; idx <= dimtheta ; idx++ ){
			lambda_Z[idx,1] = 0.01*variance(Z[,idx])*((N*(K-1)/K)*log((N*(K-1)/K)*p))^0.5/(N*(K-1)/K)
			lambda_D[idx,1] = 0.01*variance(D[,idx])*((N*(K-1)/K)*log((N*(K-1)/K)*p))^0.5/(N*(K-1)/K)
		}
		lambda_Y = 0.01*variance(Y[,1])*((N*(K-1)/K)*log((N*(K-1)/K)*p))^0.5/(N*(K-1)/K)
		pre_Z = Z
		res_Z = Z
		pre_D = D
		res_D = D
		pre_Y = Y
		res_Y = Y
		for( kdx = 1 ; kdx <= K ; kdx++ ){
			indices = selectindex(foldi:!=kdx)
			
			for( idx = 1 ; idx <= dimtheta ; idx++ ){
				xihat = glmnet(Z[indices,idx],(X,J(N,1,1))[indices,],lambda_Z[idx,1],alpha,TOLERANCE,MAXITER)
				pre_Z[indices,idx] = (X,J(N,1,1))[indices,] * xihat
				res_Z[indices,idx] = Z[indices,idx] - pre_Z[indices,idx]
			}
			
			for( idx = 1 ; idx <= dimtheta ; idx++ ){
				gammahat = glmnet(D[indices,idx],(X,J(N,1,1))[indices,],lambda_D[idx,1],alpha,TOLERANCE,MAXITER)
				pre_D[indices,idx] = (X,J(N,1,1))[indices,] * gammahat
				res_D[indices,idx] = D[indices,idx] - pre_D[indices,idx]
			}

			betahat = glmnet(Y[indices,1],(X,J(N,1,1))[indices,],lambda_Y,alpha,TOLERANCE,MAXITER)
			pre_Y[indices,1] = (X,J(N,1,1))[indices,] * betahat
			res_Y[indices,1] = Y[indices,1] - pre_Y[indices,1]
		}
		
		thetahat = 0
		for( kdx = 1 ; kdx <= K ; kdx++ ){
			indices = selectindex(foldi:==kdx)
			thetahat = thetahat :+ luinv( res_Z[indices,]' * res_D[indices,] ) * res_Z[indices,]' * res_Y[indices,1]
		}
		thetahat = thetahat :/ K
		list_thetahat[,iter] = thetahat
		res = res_Y :- res_D * thetahat
		
		////////////////////////////////////////////////////////////////////////
		// VARIANCE
		J = res_Z' * res_D :/ Ghat
		sigma2 = 0
		for( gdx = 1 ; gdx <= Ghat ; gdx++ ){
			indices = selectindex(g:==uniqueg[gdx,1])
			sigma2 = sigma2 :+(((res*J(1,dimtheta,1)) :* res_Z)[indices,])' * (((res*J(1,dimtheta,1)) :* res_Z)[indices,])
		}
		Var = luinv(J) * (sigma2:/Ghat) * luinv(J)'
		list_Var[1..dimtheta,(1..dimtheta):+(dimtheta*(iter-1))] = Var
	}

	////////////////////////////////////////////////////////////////////////////
	// MEAN RESULTS
	b = mean(list_thetahat')
	V = 0
	for( iter = 1 ; iter <= num_resample ; iter++ ){
		V = V :+ list_Var[1..dimtheta,(1..dimtheta):+(dimtheta*(iter-1))] + (list_thetahat[,iter]:-b')*(list_thetahat[,iter]:-b')'
	}
	V = V :/ num_resample :/ Ghat
	
	////////////////////////////////////////////////////////////////////////////
	// MEDIAN RESULTS
	rb = b
	list_rVar = list_Var
	for( idx = 1 ; idx <= dimtheta ; idx++ ){
		rb[1,idx] = median(list_thetahat[idx,]')
	}
	for( iter = 1 ; iter <= num_resample ; iter++ ){
		list_rVar[1..dimtheta,(1..dimtheta):+(dimtheta*(iter-1))] = list_Var[1..dimtheta,(1..dimtheta):+(dimtheta*(iter-1))] + (list_thetahat[,iter]:-rb')*(list_thetahat[,iter]:-rb')'
	}
	rV = V
	for( idx = 1 ; idx <= dimtheta ; idx++ ){
		for( jdx = 1 ; jdx <= dimtheta ; jdx++ ){
			rV[idx,jdx] = median((list_rVar[idx,((1..num_resample):-1):*dimtheta:+jdx])')
		}
	}
	rV = rV :/ Ghat

	////////////////////////////////////////////////////////////////////////////
	// RETURN THE RESULTS
	if( robust == 0 ){
		st_matrix(bname, b*diag(1:/sdD))
		st_matrix(Vname, diag(1:/sdD)*V*diag(1:/sdD))
	}
	
	if( robust == 1 ){
		st_matrix(bname, rb*diag(1:/sdD))
		st_matrix(Vname, diag(1:/sdD)*rV*diag(1:/sdD))
	}

	st_numscalar(nname, N)
	st_numscalar(pname, p)
	st_numscalar(wname, 1)
	st_numscalar(fname, K)
	st_numscalar(g1name, Ghat)
	st_numscalar(g2name, 0)
	
	printf("\n{hline 78}\n")
	printf("                                                    Observations: %12.0f\n",N)
	printf("                                                     Cluster Way:            1\n")
	printf("                                                    Cluster Size: %12.0f\n",Ghat)
	printf("                                                          dim(D): %12.0f\n",dimtheta)
	printf("                                                          dim(X): %12.0f\n",p)
	printf("                                                         Folds K: %12.0f\n",K)
	printf("{hline 78}\n")
	printf("            High-Dimensional Regression Based on Cluster-Robust DML           \n") 
}
////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////// 
// IV REGRESSION FOR 1 WAY CLUSTERING //////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
void ivreg1( string scalar yv,     string scalar dxv,	   string scalar touse,
		     string scalar iv,     string scalar cluster1,
		     real scalar dimtheta, 					   	   real scalar K,
		     real scalar alpha,						   	   real scalar num_resample,
		     real scalar robust,						
		     real scalar TOLERANCE,					   	   real MAXITER,
		     string scalar bname,  string scalar Vname,    string scalar nname,
		     string scalar pname,  string scalar wname,    string scalar fname,
		     string scalar g1name, string scalar g2name)  
{
	////////////////////////////////////////////////////////////////////////////
	// DATA ORGANIZATION
    real vector y, d, x
    real scalar n, p

    Y = st_data(., yv, touse)
    dx = st_data(., dxv, touse)
	g = st_data(., cluster1, touse)
    N = rows(dx)
	D = dx[.,1..dimtheta]
	Z = st_data(., iv, touse)
	if( dimtheta > 1 ){
		Z = Z, D[,2..dimtheta]
	}
	X = dx[.,(dimtheta+1)..(cols(dx))]
	p = cols(X)
	
	if( K <= 1 ){
	 K = 5
	}
	
	sdD = get_scale(D)
	sdZ = get_scale(Z)
	D = scale(D)
	Z = scale(Z)
	X = scale(X)
	uniqueg = uniqrows(g)
	Ghat = rows(uniqueg)

	list_thetahat = J(dimtheta,num_resample,0)
	list_Var = J(dimtheta,dimtheta*num_resample,0)
	for( iter = 1 ; iter <= num_resample ; iter++ ){
	printf("\nResampled Cross-Fitting: Iteration %3.0f/%f",iter,num_resample)
		fold = ceil(uniform(Ghat,1)*K)
		foldi = J(N,1,0)
		for( idx = 1 ; idx <= N ; idx++ ){
			foldi[idx] = fold[selectindex(g[idx,1] :== uniqueg),1]
		}
		////////////////////////////////////////////////////////////////////////
		// DML
		lambda_Z = J(dimtheta,1,0)
		lambda_D = J(dimtheta,1,0)
		for( idx = 1 ; idx <= dimtheta ; idx++ ){
			lambda_Z[idx,1] = 0.01*variance(Z[,idx])*((N*(K-1)/K)*log((N*(K-1)/K)*p))^0.5/(N*(K-1)/K)
			lambda_D[idx,1] = 0.01*variance(D[,idx])*((N*(K-1)/K)*log((N*(K-1)/K)*p))^0.5/(N*(K-1)/K)
		}
		lambda_Y = 0.01*variance(Y[,1])*((N*(K-1)/K)*log((N*(K-1)/K)*p))^0.5/(N*(K-1)/K)
		pre_Z = Z
		res_Z = Z
		pre_D = D
		res_D = D
		pre_Y = Y
		res_Y = Y
		for( kdx = 1 ; kdx <= K ; kdx++ ){
			indices = selectindex(foldi:!=kdx)
			
			for( idx = 1 ; idx <= dimtheta ; idx++ ){
				xihat = glmnet(Z[indices,idx],(X,J(N,1,1))[indices,],lambda_Z[idx,1],alpha,TOLERANCE,MAXITER)
				pre_Z[indices,idx] = (X,J(N,1,1))[indices,] * xihat
				res_Z[indices,idx] = Z[indices,idx] - pre_Z[indices,idx]
			}
			
			for( idx = 1 ; idx <= dimtheta ; idx++ ){
				gammahat = glmnet(D[indices,idx],(X,J(N,1,1))[indices,],lambda_D[idx,1],alpha,TOLERANCE,MAXITER)
				pre_D[indices,idx] = (X,J(N,1,1))[indices,] * gammahat
				res_D[indices,idx] = D[indices,idx] - pre_D[indices,idx]
			}

			betahat = glmnet(Y[indices,1],(X,J(N,1,1))[indices,],lambda_Y,alpha,TOLERANCE,MAXITER)
			pre_Y[indices,1] = (X,J(N,1,1))[indices,] * betahat
			res_Y[indices,1] = Y[indices,1] - pre_Y[indices,1]
		}
		
		thetahat = 0
		for( kdx = 1 ; kdx <= K ; kdx++ ){
			indices = selectindex(foldi:==kdx)
			thetahat = thetahat :+ luinv( res_Z[indices,]' * res_D[indices,] ) * res_Z[indices,]' * res_Y[indices,1]
		}
		thetahat = thetahat :/ K
		list_thetahat[,iter] = thetahat
		res = res_Y :- res_D * thetahat
		
		////////////////////////////////////////////////////////////////////////
		// VARIANCE
		J = res_Z' * res_D :/ Ghat
		sigma2 = 0
		for( gdx = 1 ; gdx <= Ghat ; gdx++ ){
			indices = selectindex(g:==uniqueg[gdx,1])
			sigma2 = sigma2 :+(((res*J(1,dimtheta,1)) :* res_Z)[indices,])' * (((res*J(1,dimtheta,1)) :* res_Z)[indices,])
		}
		Var = luinv(J) * (sigma2:/Ghat) * luinv(J)'
		list_Var[1..dimtheta,(1..dimtheta):+(dimtheta*(iter-1))] = Var
	}

	////////////////////////////////////////////////////////////////////////////
	// MEAN RESULTS
	b = mean(list_thetahat')
	V = 0
	for( iter = 1 ; iter <= num_resample ; iter++ ){
		V = V :+ list_Var[1..dimtheta,(1..dimtheta):+(dimtheta*(iter-1))] + (list_thetahat[,iter]:-b')*(list_thetahat[,iter]:-b')'
	}
	V = V :/ num_resample :/ Ghat
	
	////////////////////////////////////////////////////////////////////////////
	// MEDIAN RESULTS
	rb = b
	list_rVar = list_Var
	for( idx = 1 ; idx <= dimtheta ; idx++ ){
		rb[1,idx] = median(list_thetahat[idx,]')
	}
	for( iter = 1 ; iter <= num_resample ; iter++ ){
		list_rVar[1..dimtheta,(1..dimtheta):+(dimtheta*(iter-1))] = list_Var[1..dimtheta,(1..dimtheta):+(dimtheta*(iter-1))] + (list_thetahat[,iter]:-rb')*(list_thetahat[,iter]:-rb')'
	}
	rV = V
	for( idx = 1 ; idx <= dimtheta ; idx++ ){
		for( jdx = 1 ; jdx <= dimtheta ; jdx++ ){
			rV[idx,jdx] = median((list_rVar[idx,((1..num_resample):-1):*dimtheta:+jdx])')
		}
	}
	rV = rV :/ Ghat

	////////////////////////////////////////////////////////////////////////////
	// RETURN THE RESULTS
	if( robust == 0 ){
		st_matrix(bname, b*diag(1:/sdD))
		st_matrix(Vname, diag(1:/sdD)*V*diag(1:/sdD))
	}
	
	if( robust == 1 ){
		st_matrix(bname, rb*diag(1:/sdD))
		st_matrix(Vname, diag(1:/sdD)*rV*diag(1:/sdD))
	}

	st_numscalar(nname, N)
	st_numscalar(pname, p)
	st_numscalar(wname, 1)
	st_numscalar(fname, K)
	st_numscalar(g1name, Ghat)
	st_numscalar(g2name, 0)
	
	printf("\n{hline 78}\n")
	printf("                                                    Observations: %12.0f\n",N)
	printf("                                                     Cluster Way:            1\n")
	printf("                                                    Cluster Size: %12.0f\n",Ghat)
	printf("                                                          dim(D): %12.0f\n",dimtheta)
	printf("                                                          dim(X): %12.0f\n",p)
	printf("                                                         Folds K: %12.0f\n",K)
	printf("{hline 78}\n")
	printf("          High-Dimensional IV Regression Based on Cluster-Robust DML          \n") 
}
////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////// 
// REGRESSION FOR 2 WAY CLUSTERING /////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
void reg2( string scalar yv,     string scalar dxv,	   string scalar touse,
		   string scalar cluster1,					   string scalar cluster2,
		   real scalar dimtheta, 					   real scalar K,
		   real scalar alpha,						   real scalar num_resample,
		   real scalar robust,						
		   real scalar TOLERANCE,					   real MAXITER,
		   string scalar bname,  string scalar Vname,  string scalar nname,
		   string scalar pname,	 string scalar wname,  string scalar fname,
		   string scalar g1name, string scalar g2name)  
{
	////////////////////////////////////////////////////////////////////////////
	// DATA ORGANIZATION
    real vector y, d, x
    real scalar n, p

    Y = st_data(., yv, touse)
    dx = st_data(., dxv, touse)
	g1 = st_data(., cluster1, touse)
	g2 = st_data(., cluster2, touse)
    N = rows(dx)
	D = dx[.,1..dimtheta]
	Z = D
	X = dx[.,(dimtheta+1)..(cols(dx))]
	p = cols(X)
	
	if( K <= 1 ){
	 K = 3
	}
	
	sdD = get_scale(D)
	sdZ = get_scale(Z)
	D = scale(D)
	Z = scale(Z)
	X = scale(X)
	uniqueg1 = uniqrows(g1)
	Ghat1 = rows(uniqueg1)
	uniqueg2 = uniqrows(g2)
	Ghat2 = rows(uniqueg2)

	list_thetahat = J(dimtheta,num_resample,0)
	list_Var = J(dimtheta,dimtheta*num_resample,0)
	for( iter = 1 ; iter <= num_resample ; iter++ ){
	printf("\nResampled Cross-Fitting: Iteration %3.0f/%f",iter,num_resample)
		fold1 = ceil(uniform(Ghat1,1)*K)
		fold2 = ceil(uniform(Ghat2,1)*K)
		fold1i = J(N,1,0)
		fold2i = J(N,1,0)
		for( idx = 1 ; idx <= N ; idx++ ){
			fold1i[idx] = fold1[selectindex(g1[idx,1] :== uniqueg1),1]
			fold2i[idx] = fold2[selectindex(g2[idx,1] :== uniqueg2),1]
		}
		////////////////////////////////////////////////////////////////////////
		// DML
		lambda_Z = J(dimtheta,1,0)
		lambda_D = J(dimtheta,1,0)
		for( idx = 1 ; idx <= dimtheta ; idx++ ){
			lambda_Z[idx,1] = 0.01*variance(Z[,idx])*((N*(K-1)^2/K^2)*log((N*(K-1)^2/K^2)*p))^0.5/(N*(K-1)^2/K^2)
			lambda_D[idx,1] = 0.01*variance(D[,idx])*((N*(K-1)^2/K^2)*log((N*(K-1)^2/K^2)*p))^0.5/(N*(K-1)^2/K^2)
		}
		lambda_Y = 0.01*variance(Y[,1])*((N*(K-1)^2/K^2)*log((N*(K-1)^2/K^2)*p))^0.5/(N*(K-1)^2/K^2)
		pre_Z = Z
		res_Z = Z
		pre_D = D
		res_D = D
		pre_Y = Y
		res_Y = Y
		for( kdx1 = 1 ; kdx1 <= K ; kdx1++ ){
			for( kdx2 = 1 ; kdx2 <= K ; kdx2++ ){
				indices = selectindex(fold1i:!=kdx1 :& fold2i:!=kdx2)
				
				for( idx = 1 ; idx <= dimtheta ; idx++ ){
					xihat = glmnet(Z[indices,idx],(X,J(N,1,1))[indices,],lambda_Z[idx,1],alpha,TOLERANCE,MAXITER)
					pre_Z[indices,idx] = (X,J(N,1,1))[indices,] * xihat
					res_Z[indices,idx] = Z[indices,idx] - pre_Z[indices,idx]
				}
				
				for( idx = 1 ; idx <= dimtheta ; idx++ ){
					gammahat = glmnet(D[indices,idx],(X,J(N,1,1))[indices,],lambda_D[idx,1],alpha,TOLERANCE,MAXITER)
					pre_D[indices,idx] = (X,J(N,1,1))[indices,] * gammahat
					res_D[indices,idx] = D[indices,idx] - pre_D[indices,idx]
				}

				betahat = glmnet(Y[indices,1],(X,J(N,1,1))[indices,],lambda_Y,alpha,TOLERANCE,MAXITER)
				pre_Y[indices,1] = (X,J(N,1,1))[indices,] * betahat
				res_Y[indices,1] = Y[indices,1] - pre_Y[indices,1]
			}
		}
		
		thetahat = 0
		for( kdx1 = 1 ; kdx1 <= K ; kdx1++ ){
			for( kdx2 = 1 ; kdx2 <= K ; kdx2++ ){
				indices = selectindex(fold1i:==kdx1 :& fold2i:==kdx2)
				thetahat = thetahat :+ luinv( res_Z[indices,]' * res_D[indices,] ) * res_Z[indices,]' * res_Y[indices,1]
			}
		}
		thetahat = thetahat :/ K^2
		list_thetahat[,iter] = thetahat
		res = res_Y :- res_D * thetahat
		
		////////////////////////////////////////////////////////////////////////
		// VARIANCE
		J = (res_Z' * res_D) :/ (Ghat1/K) :/ (Ghat2/K) :/ K^2
		
		sigma2 = 0
		for( kdx1 = 1 ; kdx1 <= K ; kdx1++ ){
			for( kdx2 = 1 ; kdx2 <= K ; kdx2++ ){
				for( idx1 = 1 ; idx1 <= rows(uniqueg1) ; idx1++ ){
					for( jdx1 = 1 ; jdx1 <= rows(uniqueg2) ; jdx1++ ){
						indices1 = selectindex(fold1i:==kdx1 :& fold2i:==kdx2 :& g1:==uniqueg1[idx1,1] :& g2:==uniqueg2[jdx1,1])
						if( rows(indices1) > 0 ){
							for( jdx2 = 1 ; jdx2 <= rows(uniqueg2) ; jdx2++ ){
								indices2 = selectindex(fold1i:==kdx1 :& fold2i:==kdx2 :& g1:==uniqueg1[idx1,1] :& g2:==uniqueg2[jdx2,1])
								if( rows(indices2) > 0 ){
									sigma2 = sigma2 :+ rowsum((((res*J(1,dimtheta,1)) :* res_Z)[indices1,])') * colsum((((res*J(1,dimtheta,1)) :* res_Z)[indices2,]))
		}}}}}}}
		for( kdx1 = 1 ; kdx1 <= K ; kdx1++ ){
			for( kdx2 = 1 ; kdx2 <= K ; kdx2++ ){
				for( idx1 = 1 ; idx1 <= rows(uniqueg1) ; idx1++ ){
					for( jdx1 = 1 ; jdx1 <= rows(uniqueg2) ; jdx1++ ){
						indices1 = selectindex(fold1i:==kdx1 :& fold2i:==kdx2 :& g1:==uniqueg1[idx1,1] :& g2:==uniqueg2[jdx1,1])
						if( rows(indices1) > 0 ){
							for( idx2 = 1 ; idx2 <= rows(uniqueg1) ; idx2++ ){
								indices2 = selectindex(fold1i:==kdx1 :& fold2i:==kdx2 :& g1:==uniqueg1[idx2,1] :& g2:==uniqueg2[jdx1,1])
								if( rows(indices2) > 0 ){
									sigma2 = sigma2 :+ rowsum((((res*J(1,dimtheta,1)) :* res_Z)[indices1,])') * colsum((((res*J(1,dimtheta,1)) :* res_Z)[indices2,]))
		}}}}}}}
		
		Var = luinv(J) * (sigma2:*min((Ghat1/K,Ghat2/K)'):/((Ghat1/K)^2*(Ghat2/K)^2):/K^2) * luinv(J)'
		list_Var[1..dimtheta,(1..dimtheta):+(dimtheta*(iter-1))] = Var
	}

	////////////////////////////////////////////////////////////////////////////
	// MEAN RESULTS
	b = mean(list_thetahat')
	V = 0
	for( iter = 1 ; iter <= num_resample ; iter++ ){
		V = V :+ list_Var[1..dimtheta,(1..dimtheta):+(dimtheta*(iter-1))] + (list_thetahat[,iter]:-b')*(list_thetahat[,iter]:-b')'
	}
	V = V :/ num_resample :/ min((Ghat1,Ghat2)')
	
	////////////////////////////////////////////////////////////////////////////
	// MEDIAN RESULTS
	rb = b
	list_rVar = list_Var
	for( idx = 1 ; idx <= dimtheta ; idx++ ){
		rb[1,idx] = median(list_thetahat[idx,]')
	}
	for( iter = 1 ; iter <= num_resample ; iter++ ){
		list_rVar[1..dimtheta,(1..dimtheta):+(dimtheta*(iter-1))] = list_Var[1..dimtheta,(1..dimtheta):+(dimtheta*(iter-1))] + (list_thetahat[,iter]:-rb')*(list_thetahat[,iter]:-rb')'
	}
	rV = V
	for( idx = 1 ; idx <= dimtheta ; idx++ ){
		for( jdx = 1 ; jdx <= dimtheta ; jdx++ ){
			rV[idx,jdx] = median((list_rVar[idx,((1..num_resample):-1):*dimtheta:+jdx])')
		}
	}
	rV = rV :/ min((Ghat1,Ghat2)')

	////////////////////////////////////////////////////////////////////////////
	// RETURN THE RESULTS
	if( robust == 0 ){
		st_matrix(bname, b*diag(1:/sdD))
		st_matrix(Vname, diag(1:/sdD)*V*diag(1:/sdD))
	}
	
	if( robust == 1 ){
		st_matrix(bname, rb*diag(1:/sdD))
		st_matrix(Vname, diag(1:/sdD)*rV*diag(1:/sdD))
	}

	st_numscalar(nname, N)
	st_numscalar(pname, p)
	st_numscalar(wname, 2)
	st_numscalar(fname, K)
	st_numscalar(g1name, Ghat1)
	st_numscalar(g2name, Ghat2)
	
	printf("\n{hline 78}\n")
	printf("                                                    Observations: %12.0f\n",N)
	printf("                                                    Cluster Ways:            2\n")
	printf("                                                  Cluster Size 1: %12.0f\n",Ghat1)
	printf("                                                  Cluster Size 2: %12.0f\n",Ghat2)	
	printf("                                                          dim(D): %12.0f\n",dimtheta)
	printf("                                                          dim(X): %12.0f\n",p)
	printf("                                                         Folds K: %12.0f\n",K)
	printf("{hline 78}\n")
	printf("         High-Dimensional Regression Based on 2-Way Cluster-Robust DML        \n") 
}
////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////// 
// IV REGRESSION FOR 2 WAY CLUSTERING //////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
void ivreg2( string scalar yv,     string scalar dxv,	 string scalar touse,
		     string scalar iv,
		     string scalar cluster1,					 string scalar cluster2,
		     real scalar dimtheta, 					     real scalar K,
		     real scalar alpha,						     real scalar num_resample,
		     real scalar robust,						
		     real scalar TOLERANCE,					     real MAXITER,
		     string scalar bname,  string scalar Vname,  string scalar nname,
		     string scalar pname,  string scalar wname,  string scalar fname,
		     string scalar g1name, string scalar g2name)  
{
	////////////////////////////////////////////////////////////////////////////
	// DATA ORGANIZATION
    real vector y, d, x
    real scalar n, p

    Y = st_data(., yv, touse)
    dx = st_data(., dxv, touse)
	g1 = st_data(., cluster1, touse)
	g2 = st_data(., cluster2, touse)
    N = rows(dx)
	D = dx[.,1..dimtheta]
	Z = st_data(., iv, touse)
	if( dimtheta > 1 ){
		Z = Z, D[,2..dimtheta]
	}
	X = dx[.,(dimtheta+1)..(cols(dx))]
	p = cols(X)
	
	if( K <= 1 ){
	 K = 3
	}
	
	sdD = get_scale(D)
	sdZ = get_scale(Z)
	D = scale(D)
	Z = scale(Z)
	X = scale(X)
	uniqueg1 = uniqrows(g1)
	Ghat1 = rows(uniqueg1)
	uniqueg2 = uniqrows(g2)
	Ghat2 = rows(uniqueg2)

	list_thetahat = J(dimtheta,num_resample,0)
	list_Var = J(dimtheta,dimtheta*num_resample,0)
	for( iter = 1 ; iter <= num_resample ; iter++ ){
	printf("\nResampled Cross-Fitting: Iteration %3.0f/%f",iter,num_resample)
		fold1 = ceil(uniform(Ghat1,1)*K)
		fold2 = ceil(uniform(Ghat2,1)*K)
		fold1i = J(N,1,0)
		fold2i = J(N,1,0)
		for( idx = 1 ; idx <= N ; idx++ ){
			fold1i[idx] = fold1[selectindex(g1[idx,1] :== uniqueg1),1]
			fold2i[idx] = fold2[selectindex(g2[idx,1] :== uniqueg2),1]
		}
		////////////////////////////////////////////////////////////////////////
		// DML
		lambda_Z = J(dimtheta,1,0)
		lambda_D = J(dimtheta,1,0)
		for( idx = 1 ; idx <= dimtheta ; idx++ ){
			lambda_Z[idx,1] = 0.01*variance(Z[,idx])*((N*(K-1)^2/K^2)*log((N*(K-1)^2/K^2)*p))^0.5/(N*(K-1)^2/K^2)
			lambda_D[idx,1] = 0.01*variance(D[,idx])*((N*(K-1)^2/K^2)*log((N*(K-1)^2/K^2)*p))^0.5/(N*(K-1)^2/K^2)
		}
		lambda_Y = 0.01*variance(Y[,1])*((N*(K-1)^2/K^2)*log((N*(K-1)^2/K^2)*p))^0.5/(N*(K-1)^2/K^2)
		pre_Z = Z
		res_Z = Z
		pre_D = D
		res_D = D
		pre_Y = Y
		res_Y = Y
		for( kdx1 = 1 ; kdx1 <= K ; kdx1++ ){
			for( kdx2 = 1 ; kdx2 <= K ; kdx2++ ){
				indices = selectindex(fold1i:!=kdx1 :& fold2i:!=kdx2)
				
				for( idx = 1 ; idx <= dimtheta ; idx++ ){
					xihat = glmnet(Z[indices,idx],(X,J(N,1,1))[indices,],lambda_Z[idx,1],alpha,TOLERANCE,MAXITER)
					pre_Z[indices,idx] = (X,J(N,1,1))[indices,] * xihat
					res_Z[indices,idx] = Z[indices,idx] - pre_Z[indices,idx]
				}
				
				for( idx = 1 ; idx <= dimtheta ; idx++ ){
					gammahat = glmnet(D[indices,idx],(X,J(N,1,1))[indices,],lambda_D[idx,1],alpha,TOLERANCE,MAXITER)
					pre_D[indices,idx] = (X,J(N,1,1))[indices,] * gammahat
					res_D[indices,idx] = D[indices,idx] - pre_D[indices,idx]
				}

				betahat = glmnet(Y[indices,1],(X,J(N,1,1))[indices,],lambda_Y,alpha,TOLERANCE,MAXITER)
				pre_Y[indices,1] = (X,J(N,1,1))[indices,] * betahat
				res_Y[indices,1] = Y[indices,1] - pre_Y[indices,1]
			}
		}
		
		thetahat = 0
		for( kdx1 = 1 ; kdx1 <= K ; kdx1++ ){
			for( kdx2 = 1 ; kdx2 <= K ; kdx2++ ){
				indices = selectindex(fold1i:==kdx1 :& fold2i:==kdx2)
				thetahat = thetahat :+ luinv( res_Z[indices,]' * res_D[indices,] ) * res_Z[indices,]' * res_Y[indices,1]
			}
		}
		thetahat = thetahat :/ K^2
		list_thetahat[,iter] = thetahat
		res = res_Y :- res_D * thetahat
		
		////////////////////////////////////////////////////////////////////////
		// VARIANCE
		J = (res_Z' * res_D) :/ (Ghat1/K) :/ (Ghat2/K) :/ K^2
		
		sigma2 = 0
		for( kdx1 = 1 ; kdx1 <= K ; kdx1++ ){
			for( kdx2 = 1 ; kdx2 <= K ; kdx2++ ){
				for( idx1 = 1 ; idx1 <= rows(uniqueg1) ; idx1++ ){
					for( jdx1 = 1 ; jdx1 <= rows(uniqueg2) ; jdx1++ ){
						indices1 = selectindex(fold1i:==kdx1 :& fold2i:==kdx2 :& g1:==uniqueg1[idx1,1] :& g2:==uniqueg2[jdx1,1])
						if( rows(indices1) > 0 ){
							for( jdx2 = 1 ; jdx2 <= rows(uniqueg2) ; jdx2++ ){
								indices2 = selectindex(fold1i:==kdx1 :& fold2i:==kdx2 :& g1:==uniqueg1[idx1,1] :& g2:==uniqueg2[jdx2,1])
								if( rows(indices2) > 0 ){
									sigma2 = sigma2 :+ rowsum((((res*J(1,dimtheta,1)) :* res_Z)[indices1,])') * colsum((((res*J(1,dimtheta,1)) :* res_Z)[indices2,]))
		}}}}}}}
		for( kdx1 = 1 ; kdx1 <= K ; kdx1++ ){
			for( kdx2 = 1 ; kdx2 <= K ; kdx2++ ){
				for( idx1 = 1 ; idx1 <= rows(uniqueg1) ; idx1++ ){
					for( jdx1 = 1 ; jdx1 <= rows(uniqueg2) ; jdx1++ ){
						indices1 = selectindex(fold1i:==kdx1 :& fold2i:==kdx2 :& g1:==uniqueg1[idx1,1] :& g2:==uniqueg2[jdx1,1])
						if( rows(indices1) > 0 ){
							for( idx2 = 1 ; idx2 <= rows(uniqueg1) ; idx2++ ){
								indices2 = selectindex(fold1i:==kdx1 :& fold2i:==kdx2 :& g1:==uniqueg1[idx2,1] :& g2:==uniqueg2[jdx1,1])
								if( rows(indices2) > 0 ){
									sigma2 = sigma2 :+ rowsum((((res*J(1,dimtheta,1)) :* res_Z)[indices1,])') * colsum((((res*J(1,dimtheta,1)) :* res_Z)[indices2,]))
		}}}}}}}
		
		Var = luinv(J) * (sigma2:*min((Ghat1/K,Ghat2/K)'):/((Ghat1/K)^2*(Ghat2/K)^2):/K^2) * luinv(J)'
		list_Var[1..dimtheta,(1..dimtheta):+(dimtheta*(iter-1))] = Var
	}

	////////////////////////////////////////////////////////////////////////////
	// MEAN RESULTS
	b = mean(list_thetahat')
	V = 0
	for( iter = 1 ; iter <= num_resample ; iter++ ){
		V = V :+ list_Var[1..dimtheta,(1..dimtheta):+(dimtheta*(iter-1))] + (list_thetahat[,iter]:-b')*(list_thetahat[,iter]:-b')'
	}
	V = V :/ num_resample :/ min((Ghat1,Ghat2)')
	
	////////////////////////////////////////////////////////////////////////////
	// MEDIAN RESULTS
	rb = b
	list_rVar = list_Var
	for( idx = 1 ; idx <= dimtheta ; idx++ ){
		rb[1,idx] = median(list_thetahat[idx,]')
	}
	for( iter = 1 ; iter <= num_resample ; iter++ ){
		list_rVar[1..dimtheta,(1..dimtheta):+(dimtheta*(iter-1))] = list_Var[1..dimtheta,(1..dimtheta):+(dimtheta*(iter-1))] + (list_thetahat[,iter]:-rb')*(list_thetahat[,iter]:-rb')'
	}
	rV = V
	for( idx = 1 ; idx <= dimtheta ; idx++ ){
		for( jdx = 1 ; jdx <= dimtheta ; jdx++ ){
			rV[idx,jdx] = median((list_rVar[idx,((1..num_resample):-1):*dimtheta:+jdx])')
		}
	}
	rV = rV :/ min((Ghat1,Ghat2)')

	////////////////////////////////////////////////////////////////////////////
	// RETURN THE RESULTS
	if( robust == 0 ){
		st_matrix(bname, b*diag(1:/sdD))
		st_matrix(Vname, diag(1:/sdD)*V*diag(1:/sdD))
	}
	
	if( robust == 1 ){
		st_matrix(bname, rb*diag(1:/sdD))
		st_matrix(Vname, diag(1:/sdD)*rV*diag(1:/sdD))
	}

	st_numscalar(nname, N)
	st_numscalar(pname, p)
	st_numscalar(wname, 2)
	st_numscalar(fname, K)
	st_numscalar(g1name, Ghat1)
	st_numscalar(g2name, Ghat2)
	
	printf("\n{hline 78}\n")
	printf("                                                    Observations: %12.0f\n",N)
	printf("                                                    Cluster Ways:            2\n")
	printf("                                                  Cluster Size 1: %12.0f\n",Ghat1)
	printf("                                                  Cluster Size 2: %12.0f\n",Ghat2)	
	printf("                                                          dim(D): %12.0f\n",dimtheta)
	printf("                                                          dim(X): %12.0f\n",p)
	printf("                                                         Folds K: %12.0f\n",K)
	printf("{hline 78}\n")
	printf("       High-Dimensional IV Regression Based on 2-Way Cluster-Robust DML       \n") 
}
////////////////////////////////////////////////////////////////////////////////
end
