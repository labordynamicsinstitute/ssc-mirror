*! version 1.0.0
program define oga, eclass
    version 14
    // Require at least y, d, and one x variable
    syntax varlist(min=3 numeric) [if] [in], [, DIMension(integer 1) FOLds(integer 5) REPdml(integer 5) CSTar(real 2) cluster(varname)]
    marksample touse
 
    gettoken depvar indepvars : varlist
    _fv_check_depvar `depvar'
    fvexpand `indepvars' 
    local cnames `r(varlist)'
	
	local nvars : word count `indepvars'
	if `nvars' < `dimension' {
		di as error "dimension() cannot be smaller than the number of independent variables."
		exit 198  // exit with custom error code (can use 198-199 for user-defined errors)
	}

    tempname b V N

	if "`cluster'" == "" {
		mata: estimation("`depvar'", "`cnames'", "`touse'", `dimension', `repdml', `folds', `cstar', "`b'", "`V'", "`N'") 
	}
	
	if "`cluster'" != "" {
		tempvar cl
		gen `cl' = `cluster'
		capture confirm string variable `cluster'
		if _rc == 0 {
			encode `cl', gen(cl_cat)
			label values cl
			mata: estimation_cluster("`depvar'", "`cnames'", "`touse'", `dimension', `repdml', `folds', `cstar', "`b'", "`V'", "`N'",  "cl") 
		}
		if _rc != 0 {
			mata: estimation_cluster("`depvar'", "`cnames'", "`touse'", `dimension', `repdml', `folds', `cstar', "`b'", "`V'", "`N'",  "`cl'") 
		}
	}
		
	local first_vars
	forvalues j = 1/`dimension' {
		local varname : word `j' of `cnames'
		local first_vars `first_vars' `varname'
	}

	matrix colnames `b' = `first_vars'
	matrix colnames `V' = `first_vars'
	matrix rownames `V' = `first_vars'
	
	ereturn post `b' `V'
    ereturn scalar N = `N'
	ereturn scalar dimension = `dimension'
	ereturn scalar folds = `folds'
	ereturn scalar repdml = `repdml'
	ereturn scalar cstar = `cstar'
    ereturn local  cmd  "oga"
    ereturn display
	di "*  oga is based on Cha, J., Chiang, H.D., and Sasaki, Y.: Inference in High-"
	di "   Dimensional-Regression Models without the Exact or Lp Sparsity, Review of"
	di "   Economics and Statistics. (DOI: 10.1162/rest_a_01349)"

end

mata:
//////////////////////////////////////////////////////////////////////////////// 
// OGA-HDAIC
real matrix oga_hdaic(real vector y, real matrix X, real scalar c) {

    n = rows(X)
    p = cols(X)
	sel = J(p,1,0)
	used = J(p,1,0)
    resid = y
    H = J(p,1,0)
    for (i=1; i<=p; i++) {
        best = -1
        bestj = 1
        for (j=1; j<=p; j++){ if (!used[j]) {
            mu = abs(X[.,j]'*resid) / sqrt(X[.,j]'*X[.,j])
            if (mu > best) { 
				best = mu
				bestj = j 
			}
        }}
        used[bestj] = 1
        sel[i] = bestj
        Xm = X[., sel[1..i]]
        bs = invsym(Xm'*Xm) * Xm' * y
        resid = y - Xm*bs
        H[i] = (resid'*resid / n) * (1 + c*(i*log(p)/n))
    }
    rowsH = rows(H)
    mhat = 1
    Hmin = H[1]
    for (i = 2; i <= rowsH; i++) {
        if (H[i] < Hmin) {
            Hmin = H[i]
            mhat = i
        }
    }
    Xf = X[., sel[1..mhat]]
    bf = invsym(Xf'*Xf) * Xf' * y
    beta = J(p,1,0)
    beta[sel[1..mhat]] = bf
    return(beta)
}

//////////////////////////////////////////////////////////////////////////////// 
// Estimation and Inference
void estimation( string scalar depvar,  string scalar indepvars, 
				 string scalar touse,   real scalar dim,
				 real scalar repdml,	real scalar K,
				 real scalar c,			string scalar bname,   
				 string scalar Vname, 	string scalar nname) 
{
	Y = st_data(., depvar, touse)
	DX = st_data(., indepvars, touse)
	N = rows(Y)
	D = DX[,1..dim]
	if( dim+1 <= cols(DX) ){
		X = DX[,(dim+1)..cols(DX)]
		X = X, J(rows(X),1,1)
	}else{
		X = J(rows(DX),1,1)
	}
	
	folds = J(ceil(N/K)*K,1,0)
	for(k=1 ; k<=K; k++){
		folds[(ceil(N/K)*(k-1)) :+ (1..(ceil(N/K))),1] = J(ceil(N/K),1,k)
	}
	folds = folds[1..N,1]
	
	theta_list = J(repdml,dim,0)
	var_sum = J(dim,dim,0)
	for(rep=1; rep<=repdml; rep++){
		num = J(dim,1,0)
		den = 0
		psi2 = J(dim,dim,0)
		wss = J(dim,dim,0)
		indices = folds[runiformint(N, 1, 1, N), 1]
		for (k=1; k<=K; k++) {
			Ysel = select(Y,(indices:==k))
			Dsel = select(D,(indices:==k))
			Xsel = select(X,(indices:==k))
			Yunsel = select(Y,(indices:!=k))
			Dunsel = select(D,(indices:!=k))
			Xunsel = select(X,(indices:!=k))
			W = J(rows(Dsel),dim,0)
			for(d=1; d<=dim; d++){
				beta = oga_hdaic(Dunsel[,d], Xunsel, c)
				W[,d] = Dsel[,d] :- Xsel * beta
			}
			gamma = oga_hdaic(Yunsel, Xunsel, c)
			R = Ysel :- Xsel * gamma
			for(d=1; d<=dim; d++){
				num[d,1] = num[d,1] + sum(W[,d] :* R)
			}
			den = den + sum(W :* W)
			psi = J(rows(R),dim,0)
			for(d=1; d<=dim; d++){
				psi[,d] = (R :- W[,d] :* (num[d,1]/den)) :* W[,d]
			}
			for(d1=1; d1<=dim; d1++){
				for(d2=1; d2<=dim; d2++){
					psi2[d1,d2] = psi2[d1,d2] :+ sum(psi[,d1] :* psi[,d2])
					wss[d1,d2] = wss[d1,d2] + sum(W[,d1] :* W[,d2])
				}
			}
		}
		
		theta_list[rep,] = num':/den
		var_sum = var_sum + invsym(wss:/N) :* psi2 :/ N :* invsym(wss:/N) :/ N

		theta = num:/den
		var = invsym(wss) :* psi2 :* invsym(wss)
	
	}

	theta = colsum(theta_list) / repdml
	var = var_sum / repdml + (theta_list :- J(repdml,1,1)*theta)' * (theta_list :- J(repdml,1,1)*theta) :/ repdml

	st_matrix(bname, theta)
    st_matrix(Vname, var)
    st_numscalar(nname, N)
}

//////////////////////////////////////////////////////////////////////////////// 
// Estimation and Inference under Cluster Sampling
void estimation_cluster( 
				 string scalar depvar,  string scalar indepvars, 
				 string scalar touse,   real scalar dim,
				 real scalar repdml,	real scalar K,
				 real scalar c,			string scalar bname,   
				 string scalar Vname, 	string scalar nname,
				 string scalar cluster) 
{
	Y = st_data(., depvar, touse)
	DX = st_data(., indepvars, touse)
	N = rows(Y)
	D = DX[,1..dim]
	
	g = st_data(., cluster, touse)
	u = uniqrows(sort(g,1))
	g_new = J(rows(g), 1, 0)
	for (i=1; i<=rows(u); i++) {
		//g_new[ (g :== u[i,1]), 1 ] = i
		g_new[selectindex(g:==u[i,1]),1] = g_new[selectindex(g:==u[i,1]),1] :+ i
	}
	g = g_new
	G = max(g)

	if( dim+1 <= cols(DX) ){
		X = DX[,(dim+1)..cols(DX)]
		X = X, J(rows(X),1,1)
	}else{
		X = J(rows(DX),1,1)
	}
	
	folds = J(ceil(G/K)*K,1,0)
	for(k=1 ; k<=K; k++){
		folds[(ceil(G/K)*(k-1)) :+ (1..(ceil(G/K))),1] = J(ceil(G/K),1,k)
	}
	folds = folds[1..G,1]
	
	theta_list = J(repdml,dim,0)
	var_sum = J(dim,dim,0)
	for(rep=1; rep<=repdml; rep++){
		num = J(dim,1,0)
		den = 0
		psi2 = J(dim,dim,0)
		wss = J(dim,dim,0)
		temp_indices = folds[runiformint(G, 1, 1, G), 1]
		indices = temp_indices[g,1]
		for (k=1; k<=K; k++) {
			Ysel = select(Y,(indices:==k))
			Dsel = select(D,(indices:==k))
			Xsel = select(X,(indices:==k))
			gsel = select(g,(indices:==k))
			Yunsel = select(Y,(indices:!=k))
			Dunsel = select(D,(indices:!=k))
			Xunsel = select(X,(indices:!=k))
			W = J(rows(Dsel),dim,0)
			for(d=1; d<=dim; d++){
				beta = oga_hdaic(Dunsel[,d], Xunsel, c)
				W[,d] = Dsel[,d] :- Xsel * beta
			}
			gamma = oga_hdaic(Yunsel, Xunsel, c)
			R = Ysel :- Xsel * gamma
			for(d=1; d<=dim; d++){
				num[d,1] = num[d,1] + sum(W[,d] :* R)
			}
			den = den + sum(W :* W)
			psi = J(rows(R),dim,0)
			for(d=1; d<=dim; d++){
				psi[,d] = (R :- W[,d] :* (num[d,1]/den)) :* W[,d]
			}
			psi_cluster = J(G,dim,0)
			for(gdx=1;gdx<=G;gdx++){
				for(d=1;d<=dim;d++){
					psi_cluster[gdx,d] = sum(select(psi[,d],(gsel:==gdx)))
				}
			}
//			psi_cluster
			for(d1=1; d1<=dim; d1++){
				for(d2=1; d2<=dim; d2++){
					psi2[d1,d2] = psi2[d1,d2] :+ sum(psi_cluster[,d1] :* psi_cluster[,d2])
					wss[d1,d2] = wss[d1,d2] + sum(W[,d1] :* W[,d2])
				}
			}
		}
		
		theta_list[rep,] = num':/den
		var_sum = var_sum + invsym(wss) :* psi2 :* invsym(wss)
	}

	theta = colsum(theta_list) / repdml
	var = var_sum / repdml + (theta_list :- J(repdml,1,1)*theta)' * (theta_list :- J(repdml,1,1)*theta) :/ repdml

	st_matrix(bname, theta)
    st_matrix(Vname, var)
    st_numscalar(nname, N)
}
end
