////////////////////////////////////////////////////////////////////////////////
// STATA FOR CHIANG, HANSEN, SASAKI
////////////////////////////////////////////////////////////////////////////////
!* version 14.2  12may2022
program define xtregtwo, eclass
    version 14.2
 
    syntax varlist(numeric) [if] [in] [, NOConstant FE TWFE]
    marksample touse
 
	qui xtset
	local panelid = r(panelvar)
	local timeid  = r(timevar)

    gettoken depvar indepvars : varlist
    _fv_check_depvar `depvar'
    fvexpand `indepvars' 
    local cnames `r(varlist)'

    tempname b V N T NT M
	
	local const = 0
	if "`noconstant'" == "" {
	  local const = 1
	}
	
	local fixedeffect = 1
	if "`fe'" == "" {
	  local fixedeffect = 0
	}
	
	local twowayfixedeffect = 1
	if "`twfe'" == "" {
	  local twowayfixedeffect = 0
	}
	
	mata: estimation("`depvar'","`cnames'","`panelid'","`timeid'",		 ///
					 "`touse'","`b'","`V'","`N'","`T'","`NT'","`M'",     ///
					 `const',`fixedeffect',`twowayfixedeffect')
	
	local cnames `cnames'
	if "`noconstant'" == "" & "`fe'" == "" & "`twfe'" == "" {
		local cnames "`cnames' _cons"
	}
	matrix colnames `b' = `cnames'
	matrix colnames `V' = `cnames'
	matrix rownames `V' = `cnames'
	
	ereturn post `b' `V', esample(`touse') buildfvinfo
	ereturn scalar N    = `N'
	ereturn scalar T    = `T'
	ereturn scalar NT   = `NT'
	ereturn scalar M    = `M'
	ereturn local  cmd  "xtregtwo"
	ereturn display
	di "Reference: Chiang, H.D., B.E. Hansen, and Y. Sasaki (2024) Standard Errors for"
	di "Two-Way Clustering with Serially Correlated Time Effects. Review of Economics"
	di "and Statistics, forthcoming."
end
////////////////////////////////////////////////////////////////////////////////
 
mata:
//////////////////////////////////////////////////////////////////////////////// 
// Estimation Function
void estimation(string scalar depvar, 	string scalar indepvars, 			 ///
                string scalar panelid, 	string scalar timeid,    			 ///
				string scalar touse, 	string scalar bname,	 			 ///
				string scalar Vname,   	string scalar nname,	 			 ///
				string scalar tname,	string scalar ntname,				 ///
				string scalar mname,	real scalar constant,				 ///
				real scalar fe,			real scalar twfe)
{
    Y = st_data(., depvar, touse)
    X = st_data(., indepvars, touse)
    t = st_data(., timeid, touse)
	i = st_data(., panelid, touse)
	uniq_i = uniqrows(i)
	uniq_t = uniqrows(t)
	N = rows(uniq_i)
	T = rows(uniq_t)
	
	if( constant > 0.5 & fe < 0.5 & twfe < 0.5 ){
		ones = J(rows(X),1,1)
		X = X,ones
	}
	
//////////////////////////////////////////////////////////////////////////////// 
// Within-Transformation If One-Way Fixed Effect
	if( fe > 0.5 & twfe < 0.5 ){
		for( uidx = 1 ; uidx <= N ; uidx++ ){
			idx = uniq_i[uidx,1]
			for( jdx = 1 ; jdx <= cols(X) ; jdx++ ){
				X[select((1..rows(X))',i:==idx),jdx] = X[select((1..rows(X))',i:==idx),jdx] :- mean(X[select((1..rows(X))',i:==idx),jdx])
			}	
			Y[select((1..rows(X))',i:==idx),  1] = Y[select((1..rows(X))',i:==idx),  1] :- mean(Y[select((1..rows(X))',i:==idx),  1])
		}
		//X = X[select((1..rows(X))',t:!=uniq_t[1,1]),]
		//Y = Y[select((1..rows(Y))',t:!=uniq_t[1,1]),]
		//i = i[select((1..rows(i))',t:!=uniq_t[1,1]),]
		//t = t[select((1..rows(t))',t:!=uniq_t[1,1]),]
		uniq_i = uniqrows(i)
		uniq_t = uniqrows(t)
		N = rows(uniq_i)
		T = rows(uniq_t)
	}
	
//////////////////////////////////////////////////////////////////////////////// 
// Within-Transformation If Two-Way Fixed Effect
	if( twfe > 0.5 ){
		for( uidx = 1 ; uidx <= N ; uidx++ ){
			idx = uniq_i[uidx,1]
			for( jdx = 1 ; jdx <= cols(X) ; jdx++ ){
				X[select((1..rows(X))',i:==idx),jdx] = X[select((1..rows(X))',i:==idx),jdx] :- mean(X[select((1..rows(X))',i:==idx),jdx])
			}	
			Y[select((1..rows(X))',i:==idx),  1] = Y[select((1..rows(X))',i:==idx),  1] :- mean(Y[select((1..rows(X))',i:==idx),  1])
		}
		for( utdx = 1 ; utdx <= T ; utdx++ ){
			tdx = uniq_t[utdx,1]
			for( jdx = 1 ; jdx <= cols(X) ; jdx++ ){
				X[select((1..rows(X))',t:==tdx),jdx] = X[select((1..rows(X))',t:==tdx),jdx] :- mean(X[select((1..rows(X))',t:==tdx),jdx])
			}	
			Y[select((1..rows(X))',t:==tdx),  1] = Y[select((1..rows(X))',t:==tdx),  1] :- mean(Y[select((1..rows(X))',t:==tdx),  1])
		}
		for( jdx = 1 ; jdx <= cols(X) ; jdx++ ){
			X[,jdx] = X[,jdx] :+ mean(X[,jdx])
		}
		Y[,1] = Y[,1] :+ mean(Y[,1])
		
		//X = X[select((1..rows(X))',t:!=uniq_t[1,1]),]
		//Y = Y[select((1..rows(Y))',t:!=uniq_t[1,1]),]
		//i = i[select((1..rows(i))',t:!=uniq_t[1,1]),]
		//t = t[select((1..rows(t))',t:!=uniq_t[1,1]),]
		uniq_i = uniqrows(i)
		uniq_t = uniqrows(t)
		N = rows(uniq_i)
		T = rows(uniq_t)
	}

//////////////////////////////////////////////////////////////////////////////// 
// OLS and Residual
	beta = luinv(X'*X)*X'*Y	
	Uhat = Y :- X*beta
	
//////////////////////////////////////////////////////////////////////////////// 
// Variance Estimation

	// Omega Hat 1st Term
	Omega_hat_1 = J(cols(X),cols(X),0)
	for( uidx = 1 ; uidx <= N ; uidx++ ){
		idx = uniq_i[uidx,1]
		for( jdx = 1 ; jdx <= cols(X) ; jdx++ ){
			for( kdx = 1 ; kdx <= jdx ; kdx++ ){
				Omega_hat_1[jdx,kdx] = Omega_hat_1[jdx,kdx] + sum((X[select((1..rows(X))',i:==idx),jdx]:*Uhat[select((1..rows(X))',i:==idx),1]) * (X[select((1..rows(X))',i:==idx),kdx]:*Uhat[select((1..rows(X))',i:==idx),1])')
				Omega_hat_1[kdx,jdx] = Omega_hat_1[jdx,kdx]
	}}}
	Omega_hat_1 = min((N,T)')/N/(N*T^2) :* Omega_hat_1
	
	// Omega Hat 2nd Term
	Omega_hat_2 = J(cols(X),cols(X),0)
	for( utdx = 1 ; utdx <= T ; utdx++ ){
		tdx = uniq_t[utdx,1]
		for( jdx = 1 ; jdx <= cols(X) ; jdx++ ){
			for( kdx = 1 ; kdx <= jdx ; kdx++ ){
				Omega_hat_2[jdx,kdx] = Omega_hat_2[jdx,kdx] + sum((X[select((1..rows(X))',t:==tdx),jdx]:*Uhat[select((1..rows(X))',t:==tdx),1]) * (X[select((1..rows(X))',t:==tdx),kdx]:*Uhat[select((1..rows(X))',t:==tdx),1])')
				Omega_hat_2[kdx,jdx] = Omega_hat_2[jdx,kdx]
	}}}
	Omega_hat_2 = min((N,T)')/T/(N^2*T) :* Omega_hat_2
	
	// Omega Hat 3rd Term
	Omega_hat_3 = J(cols(X),cols(X),0)
	for( jdx = 1 ; jdx <= cols(X) ; jdx++ ){
		for( kdx = 1 ; kdx <= jdx ; kdx++ ){
			Omega_hat_3[jdx,kdx] = (X[,jdx]:*Uhat[,1])' * (X[,kdx]:*Uhat[,1])
			Omega_hat_3[kdx,jdx] = Omega_hat_3[jdx,kdx]
	}}
	Omega_hat_3 = min((N,T)')/(N*T)/(N*T) :* Omega_hat_3
	
	// Select M Hat
	rho_hat = J(cols(X),1,0)
	for( kdx = 1 ; kdx <= cols(X) ; kdx++ ){	
		utdx = 2
		tdx = uniq_t[utdx,1]
		tdx_lag = uniq_t[utdx-1,1]
		S = sum( X[select((1..rows(X))',t:==tdx),kdx]:*Uhat[select((1..rows(X))',t:==tdx),1] )
		S_lag = sum( X[select((1..rows(X))',t:==tdx_lag),kdx]:*Uhat[select((1..rows(X))',t:==tdx_lag),1] )
		for( utdx = 3 ; utdx <= T ; utdx++ ){
			tdx = uniq_t[utdx,1]
			tdx_lag = uniq_t[utdx-1,1]
			S = S \ sum( X[select((1..rows(X))',t:==tdx),kdx]:*Uhat[select((1..rows(X))',t:==tdx),1] )
			S_lag = S_lag \ sum( X[select((1..rows(X))',t:==tdx_lag),kdx]:*Uhat[select((1..rows(X))',t:==tdx_lag),1] )
		}
		rho_hat[kdx] = ( luinv((S_lag)' * (S_lag)) * (S_lag)'*S )[1,1]
	}
	m = floor( 1.8171 * ( sum(rho_hat:^2:/(1:-rho_hat):^4) / sum((1:-rho_hat:^2):^2:/(1:-rho_hat):^4) )^(1/3) * T^(1/3) )
	
	// Omega Hat 4th Term
	Omega_hat_4 = J(cols(X),cols(X),0)
	for( j = 1 ; j <= m ; j++ ){
		temp_Omega_hat_4 = J(cols(X),cols(X),0)
		w = 1 - (j/(m+1))
		for( utdx = (j+1) ; utdx <= T ; utdx++ ){
			tdx = uniq_t[utdx,1]
			tdxminus = uniq_t[utdx-j,1]
			for( jdx = 1 ; jdx <= cols(X) ; jdx++ ){
				for( kdx = 1 ; kdx <= cols(X) ; kdx++ ){
					temp_Omega_hat_4[jdx,kdx] = temp_Omega_hat_4[jdx,kdx] + sum((X[select((1..rows(X))',t:==tdx),jdx]:*Uhat[select((1..rows(X))',t:==tdx),1]) * (X[select((1..rows(X))',t:==tdxminus),kdx]:*Uhat[select((1..rows(X))',t:==tdxminus),1])')
		}}}
		temp_Omega_hat_4 = w / (N^2*T) * temp_Omega_hat_4
		Omega_hat_4 = Omega_hat_4 + temp_Omega_hat_4
	}
	Omega_hat_4 = min((N,T)')/T :* Omega_hat_4
	
	// Omega Hat 5th Term
	Omega_hat_5 = J(cols(X),cols(X),0)
	for( j = 1 ; j <= m ; j++ ){
		temp_Omega_hat_5 = J(cols(X),cols(X),0)
		w = 1 - (j/(m+1))
		for( utdx = (j+1) ; utdx <= T ; utdx++ ){
			tdx = uniq_t[utdx,1]
			tdxminus = uniq_t[utdx-j,1]
			for( jdx = 1 ; jdx <= cols(X) ; jdx++ ){
				for( kdx = 1 ; kdx <= cols(X) ; kdx++ ){
					temp_Omega_hat_5[jdx,kdx] = temp_Omega_hat_5[jdx,kdx] + sum((X[select((1..rows(X))',t:==tdxminus),jdx]:*Uhat[select((1..rows(X))',t:==tdxminus),1]) * (X[select((1..rows(X))',t:==tdx),kdx]:*Uhat[select((1..rows(X))',t:==tdx),1])')
		}}}
		temp_Omega_hat_5 = w / (N^2*T) * temp_Omega_hat_5
		Omega_hat_5 = Omega_hat_5 + temp_Omega_hat_5
	}
	Omega_hat_5 = min((N,T)')/T :* Omega_hat_5
	
	// Add the 5 Terms to Get Omega Hat
	Omega_hat = Omega_hat_1 :+ Omega_hat_2 :- Omega_hat_3 :+ Omega_hat_4 :+ Omega_hat_5

	// Q Hat
	Q_hat = X' * X :/ rows(X)
	
	// Variance
	V = luinv(Q_hat) * Omega_hat * luinv(Q_hat) :/ min((N,T)')

//////////////////////////////////////////////////////////////////////////////// 
// Output
    st_matrix(bname, beta')
    st_matrix(Vname, V)
    st_numscalar(nname, N)
	st_numscalar(tname, T)
	st_numscalar(ntname, N*T)
	st_numscalar(mname, m)
}
end
////////////////////////////////////////////////////////////////////////////////

