*! version 1.03  Jeremy Ferwerda / Hainmueller / Hazlett 04/29/2026

program krls, eclass
	version 13
	syntax varlist(min=2 numeric ts) [if] [in] [, Deriv ///
			SDERIV(string) ///
			VCov ///
			SVCOV(string) ///
			Keep(string) ///
			Graph ///
			Suppress ///
			LTolerance(numlist max=1 > 0) ///
			Sigma(numlist max=1 > 0) ///
			Quantile(numlist max=3 > 0 < 1) ///
			LOWERbound(numlist max=1 >= 0) ///
			Lambda(numlist max=1 > 0)]

	foreach i of local varlist {
		quietly summ `i'
		if `r(Var)' == 0 {
			display as error "All variables must vary"
			exit 198
		}	
	}
				
	local depvar: word 1 of `varlist'
	local regs: list varlist - depvar
	
	marksample touse
	
	_rmcoll `regs' if `touse', forcedrop
    local regs `r(varlist)'
	
	quietly count if `touse'
	if `r(N)' == 0 error 2000
	
	// Set option indicators
	if ("`sigma'"==""){
		 local sigma = 0
	} 

	if ("`lambda'"=="") local lambda = 0
	if ("`suppress'" != ""){
		 local suppress = "suppress"
		 local deriv = ""
	} 
	else {
	 	if ("`graph'" != "")  local deriv = "deriv"
	 	if ("`sderiv'" != "") local deriv = "deriv"
	} 	
	
	if ("`ltolerance'"=="") local ltolerance = 0
	if ("`lowerbound'"=="") local lowerbound = -1	
	if ("`svcov'" != "") local vcov = "vcov"

	// Handle display options
	capture confirm matrix UQuantile
	if !_rc local mat_exist   = 1
	if  _rc local mat_exist   = 0
	if  `mat_exist'{
	matrix drop UQuantile
	local mat_exist    = 0
	}
	
	if ("`quantile'"!=""){
	numlist "`quantile'"
	local nlist `r(numlist)'
		foreach el of local nlist {
		matrix UQuantile = nullmat(UQuantile),`el'
	}
	}

	// Pass to mata
	mata: m_krls("`depvar'", "`regs'", "`touse'",`ltolerance',`lowerbound',`sigma', `lambda',"`deriv'","`vcov'","`suppress'")
	
	// Eclass results
	ereturn post, esample(`touse')
	ereturn local cmdconstraint "`if'"
	ereturn local depvar "`depvar'"
	ereturn local cmdline "krls `depvar' `regs'"
	ereturn local cmd "krls"
	
	if ("`vcov'"!="") ereturn matrix Varcovfit=Vcovfit
	
	if ("`suppress'" == ""){
		// ereturn matrix VarAvgDeriv=VarAvgDvm	
		// ereturn matrix AvgDeriv=Avgdrv
		ereturn matrix Output=Output
	}
	
	// Note: Using k9tmp_ as prefix for scalars to avoid hassle of poor mata namespace handling.
	
	ereturn scalar Looloss=		k9tmp_le
	ereturn scalar lambda=		k9tmp_lambda
	ereturn scalar sigma=		k9tmp_sigma
	ereturn scalar R2=			k9tmp_R2
	ereturn scalar Eff_Degrees=	k9tmp_eff_df
			
	// Write file with varcov if specified
	if ("`svcov'" != ""){
		preserve
		matrix varcov = e(Varcovfit)
		svmat varcov
		keep varcov*
		save "`svcov'.dta", replace
		restore
	}
	
	if ("`suppress'"==""){
	
	// Write file with derivatives if specified
	if ("`sderiv'" != ""){
		preserve
		keep d_*
		save "`sderiv'.dta", replace
		restore
		drop d_*
	}
	
	// Graph
	if ("`graph'" != ""){
		graph drop _all
		foreach x of local regs{
			hist d_`x', name(d_`x')  percent  scheme(s2mono) title("Pointwise Derivatives") 
		}	
	}

	// Keep
	if ("`keep'" != "" ){
		preserve
		drop _all   
		qui gen x = ""	
		
		ereturn matrix QuartileDeriv=MedianDrv	

		local rowcount = 0
		foreach x of local regs{
			local rowcount = `rowcount' + 1
			qui set obs `rowcount'
			qui replace x = "`x'" if _n == `rowcount'
		}	
		mat krlso = e(Output)
		svmat krlso 
		rename krlso1 avgderiv
		rename krlso2 se
		rename krlso3 t
		rename krlso4 p
		
		if ("`quantile'"==""){
			rename krlso5 p25
			rename krlso6 p50
			rename krlso7 p75
		}

		qui gen n = k9tmp_n
		qui gen lambda = k9tmp_lambda
		qui gen tolerance  = k9tmp_tolerance
		qui gen sigma = k9tmp_sigma
		qui gen looloss = k9tmp_le
		qui gen Eff_df = k9tmp_eff_df
		qui gen R2 = k9tmp_R2
		
		di ""
		save "`keep'", replace
		restore
	}
	}

end

version 13
mata:
mata set matastrict on
mata set matafavor speed

// Evaluate Loo-loss
real scalar eval_opt(lambda){
		external real matrix EVec, EVal, SY
		real matrix Ginv, C

		Ginv = cross(EVec,((EVal :+ lambda) :^-1),EVec) 
		C = cross(Ginv,SY) :/ diagonal(Ginv)
    	return(cross(C,C))	
}

// Optimization function
void m_goldensection_recursivecache(L, U, s1, s2, iteration, itcap,passeval,passtype,opasseval,noisy){
  external real scalar lambda_opt, ltolerance
  real scalar s1eval, s2eval
  external real matrix Sdy

 if (iteration ==1){
 	s1 = L + (.381966)*(U-L)
 	s2 = U - (.381966)*(U-L)
 	s1eval = eval_opt(s1)
	s2eval = eval_opt(s2)
	
 } else {
	if (noisy == 1){
		printf("{txt}Iteration = %2.0f,",iteration - 1)
  		printf(" Looloss: %-9.0g \n",opasseval * Sdy)
	}
			
	// Caching
	 if (passtype ==1){
		s2eval = passeval
		s1eval = eval_opt(s1)
	 } else {
		s2eval = eval_opt(s2)
		s1eval = passeval
	 }
}  
	iteration++

	// Loop termination criteria
	if (abs(s1eval - s2eval) <= ltolerance || iteration == itcap){ 	
 		if (s1eval < s2eval){
 			lambda_opt = s1
 		} else {
 			lambda_opt = s2
 		}
 	
 	} else {
		// Next step
 		if (s1eval < s2eval){
 			U = s2
 			s2 = s1
 			s1 = L + (.381966)*(U-L)
 			m_goldensection_recursivecache(L, U, s1, s2, iteration,itcap,s1eval,1,s2eval,noisy)
 			
 		} else {
 			L = s1
 			s1 = s2
 			s2 = U - (.381966)*(U-L)
 			m_goldensection_recursivecache(L, U, s1, s2, iteration,itcap,s2eval,2,s1eval,noisy)
 		} 
 	
 	}
 	
}

// Initiate lambda/sigma search
void m_krlschooselambda(real scalar sigma, real scalar ulambda, real scalar utolerance, real scalar noisy){
  	 external real matrix K, EDistance, EVec, SY, EVal
 	 external real scalar lambda, ltolerance, n

	// Construct kernel matrix K
			K=exp(EDistance/sigma)
	// Eigen
			symeigensystem(K,EVec=.,EVal=.)
			EVec = EVec'

	// Determine optimal value of lambda if not supplied and solve
			if (ulambda == 0){
				ltolerance = utolerance
				if (ltolerance == 0){
					// Not User specified
					
						ltolerance = 10^-3 * n
					
				} 	
				
			// Golden Section Parameters
					real scalar h, j, q, l
					external real scalar lambda_opt, lowerbound
					
					// Upper bound
					h = n
					while (sum(EVal :/ (EVal :+ h)) < 1){
						h--
					}		
					//h=h/3
					
					// Select Lower bound if not provided
					if (lowerbound == -1){
					
					l = max(EVal) / 1000
					j=1
					
					while(EVal[j] > l){
						j++
					} 
					if (abs(EVal[j] - l) > abs(EVal[j-1] - l)){
								j = j-1
					} 

					lowerbound = 0
					while (sum(EVal :/ (EVal :+ lowerbound)) > j){
						lowerbound = lowerbound +.05	
					}		
					}
    
					// Kick off optimization
					m_goldensection_recursivecache(lowerbound,h,NULL,NULL,1,50,0,NULL,10,noisy)
					lambda = lambda_opt		
						
			}	else {
				lambda = ulambda
			}
}

// Main KRLS wrapper
void m_krls(string scalar yname, ///
		string scalar xname, ///
		string scalar touse, ///
		real scalar utolerance, ///
		real scalar ulowerbound, ///		
		real scalar sigma, ///
		real scalar ulambda, ///
		string scalar deriv, ///
		string scalar vcov, ///
		string scalar noderiv)
		{
			real matrix Xmv,Ymv,Coeffs,Yfit,Ginv,Le,Vcovmc,Rw, ///
				L,Drvmat,VarAvgDvm,Avgdrv,Sdx, Mediandrv, T
			real scalar d,t,i,j,p,vy,r2,S,binarycount
			string scalar Binary, colList
			external real matrix EVec, EVal, SY, EDistance, K, SX, Sdy
			external real scalar n, lambda, ltolerance, trace, lowerbound
			
			lowerbound = ulowerbound
		
			SY = st_data(.,  tokens(yname), touse)
			SX = st_data(.,  tokens(xname), touse)
	
			st_global("xname",xname)
			st_global("yname",yname)
			
			n = rows(SX)
			d = cols(SX)
		 	
	// Determine which columns in X are binary
			binarycount = 0;
			for (i=1; i<=d; i++){
					colList = colList + " " + strofreal(i)
				if (rows(uniqrows(SX[.,i])) == 2){
					Binary = Binary + " " + strofreal(1)
					binarycount++
				} else {
					Binary = Binary + " " + strofreal(0)
				}
			}	
			
			if (binarycount > 0){
				external real matrix SX2
				SX2 = SX
			}
				
	// Rescale	
			Xmv = quadmeanvariance(SX)
			Sdx = sqrt(diagonal(Xmv[|2,1 \ .,.|])')
			SX[ ., . ] = (SX :- Xmv[1,.]) :/ Sdx
			
			Ymv = quadmeanvariance(SY)
			vy =  diagonal(Ymv[|2,1 \ .,.|])
			Sdy = sqrt(vy)
			SY[ ., . ] = (SY :- Ymv[1,.]) :/ Sdy
		
	// Squared Euclidean distance (avoids sqrt that was previously squared back).
			EDistance = -1 :* m_euclidian_distance_sq(SX, n, d)
		
	// Set default sigma
	if (sigma == 0) sigma = d
		
			m_krlschooselambda(sigma,ulambda,utolerance,1)
		
			// Solve with optimal lambda
    		Ginv = cross(EVec,((EVal :+ lambda) :^-1),EVec) 
    		Coeffs = cross(Ginv,SY) 
    		Rw = Coeffs :/ diagonal(Ginv)
    		Le = cross(Rw, Rw) * Sdy
		
			// Free memory
			Rw = 0
			Ginv = 0
			EDistance = 0
			
			// Fitted
			Yfit = cross(K,Coeffs)
	
			real matrix Ytemp
			Ytemp = SY-Yfit
			Vcovmc = cross(EVec,((EVal :+ lambda):^-2),EVec) * cross(Ytemp,(1/n),Ytemp)
       		r2 = 1 - (variance(((Ytemp) * Sdy) :+ Ymv[1,.]) / vy)
       		
			// Degrees of freedom
            trace = sum(EVal :/ (EVal :+ lambda))
                     		
			// Free memory
			Ytemp =0
			EVec = 0
			EVal = 0	
						
			if (vcov == "vcov"){
				// Save some memory if not specified
				real matrix Vcovfit 
				Vcovfit = vy * cross(K,Vcovmc*K)
				st_matrix("Vcovfit",Vcovfit) 
				st_matrix("SEfit",sqrt(diagonal(Vcovfit)))	
				Vcovfit=0
				
			} else {
				st_matrix("SEfit",sqrt(diagonal(vy * cross(K,Vcovmc*K))))	
			}
			Yfit = (Yfit * Sdy) :+ Ymv[1,.]
			st_matrix("Yfitted",Yfit)	
			st_matrix("Vcov",vy * Vcovmc)
			
			// Derivatives
			if (noderiv == ""){
				Drvmat = J(n,d,.)
           		VarAvgDvm = J(1,d,.)

           		for (i=1; i<=d; i++){
        			L = m_distance(SX[,i],n) :*K
        			Drvmat[,i]= cross(L',(-2/sigma),Coeffs)
					VarAvgDvm[1,i] = (1/n^2) * sum(cross(L,(-2/sigma)^2,Vcovmc*L))      
				}
			}

			// Free memory
			L = 0
			K = 0
			Vcovmc=0

       // Rescale and return results

       		if (noderiv == ""){
       			real matrix UQuantile
  				real scalar dq
  				
  				dq = cols(st_matrix("UQuantile"))
  				
  				if (dq > 0){
       				UQuantile = J(dq,1,.)
       			
       				for (i=1; i<=dq; i++){ 
       					UQuantile[i] =  st_matrix("UQuantile")[i]
       				}
       			} else {
       				UQuantile = (0.25 \ 0.5 \ 0.75)
       			}
  
  				Drvmat = Drvmat :* Sdy :/ Sdx
       			Mediandrv = mms_quantile(Drvmat, UQuantile)
       			
       			Avgdrv = colsum(Drvmat) :/ n
       			VarAvgDvm = VarAvgDvm :* ((Sdy :/ Sdx):^2)
       			
				st_matrix("Avgdrv",Avgdrv')
				st_matrix("VarAvgDvm",VarAvgDvm')
				st_matrix("MedianDrv",Mediandrv')
       		}
       		
			// Remaining saved values
			st_matrix("Coeffs",Coeffs)
			st_numscalar("k9tmp_R2",r2)	
			st_numscalar("k9tmp_sigma",sigma)
			st_numscalar("k9tmp_eff_df",trace)
			st_numscalar("k9tmp_n",n)
			st_numscalar("k9tmp_tolerance",ltolerance)	
			st_numscalar("k9tmp_lambda",lambda)
 			st_numscalar("k9tmp_le",Le)	
			st_numscalar("sdy",Sdy)
			st_numscalar("meany",Ymv[1,.])
			st_matrix("sdx",Sdx)
			st_matrix("meanx",Xmv[1,.])
			
			if (noderiv == ""){
			
			// Output	
			real scalar tablelength,tablelength2
			
			tablelength =  strlen(substr(yname,1,30))
			
			// Determine the maxlength 
			for (i=1; i<= d; i++){
				tablelength2 = strlen(substr(tokens(xname)[i],1,30)) + 1
			    if (tablelength2 > tablelength){
			    	tablelength = tablelength2
			    }
			}
	
 			printf("\n")
			printf("{txt}Pointwise Derivatives")
			printf("{txt}{space %2.0f} ",24 + tablelength)
			printf ("Number of obs = {res}%8.0g \n",n)
			printf("{txt}{space %2.0f} ", 45 + tablelength)
			printf("Lambda {space 6} = {res}%8.4g \n",lambda)
			if (ulambda == 0){
				printf("{txt}{space %2.0f} ", 45 + tablelength)
				printf("Tolerance {space 3} = {res}%8.4g \n",ltolerance)
			}
			printf("{txt}{space %2.0f} ", 45 + tablelength)
			printf("Sigma {space 6}  = {res}%8.4g \n",sigma)
			printf("{txt}{space %2.0f} ", 45 + tablelength)
			printf("Eff. df {space 4}  = {res}%8.4g \n",trace)
			printf("{txt}{space %2.0f} ", 45 + tablelength)
			printf("R2 {space 11}= {res}%8.4g \n",r2)
			printf("{txt}{space %2.0f} ", 45 + tablelength)
			printf("Looloss {space 6}= {res}%8.4g",Le)		
			printf("\n")
			printf("\n")
			printf("{txt}{space %2.0f}", tablelength - strlen(substr(yname,1,30)))
			printf("%s {c |}      Avg.{space 7}SE{space 8}t{space 4}P>|t|{space 8}", substr(yname,1,30))
			
			for (j=1; j<=rows(UQuantile); j++){ 
				printf("P%2.0f{space 7}",UQuantile[j] * 100)
			}
			printf("\n{hline %2.0f}{c +}{hline 68}\n",tablelength + 1)
			
			real matrix Contrast, OutputRow, OutputM
			Contrast = .
			OutputM = .
			
			for (i=1; i<= d; i++){
			
				if (tokens(Binary)[i] != "1"){
					printf("{space %2.0f}", tablelength - strlen(substr(tokens(xname)[i],1,30)))
					printf("{txt}%s {c |} ", substr(tokens(xname)[i],1,30))
					printf("{res}%8.0g {space 1}", Avgdrv[i])
					printf("{res}%8.0g", sqrt(VarAvgDvm[i]))
					printf("{res}%9.3f", Avgdrv[i]/sqrt(VarAvgDvm[i]))
					printf("{res}%9.3f {space 1} ", 2*ttail(n-d,abs(Avgdrv[i]/sqrt(VarAvgDvm[i]))))
					
					for (j=1; j<=rows(UQuantile); j++){ 
						printf("{res}%8.0g {space 1}", Mediandrv[j,i])
					}
					printf("\n")

					OutputRow = Avgdrv[i],  sqrt(VarAvgDvm[i]), Avgdrv[i]/sqrt(VarAvgDvm[i]), 2*ttail(n-d,abs(Avgdrv[i]/sqrt(VarAvgDvm[i]))), Mediandrv[,i]'
					
				} else {
				
					real matrix SX0, SX1, Fdif
					external matrix pYfit, pVcovfit
					external scalar binarycol
					
					SX0 = J(n,0,.)
					SX1 = J(n,0,.)
					
										
					for (j=1; j<=cols(tokens(colList)); j++){
						if (i != j){	
							SX0 = (SX0 ,(SX2[.,strtoreal(tokens(colList)[j])])) 
							SX1 = (SX1 ,(SX2[.,strtoreal(tokens(colList)[j])])) 
						} else {
							SX0 = (SX0 , rangen(min(SX2[,i]),min(SX2[,i]),n))
							SX1 = (SX1 , rangen(max(SX2[,i]),max(SX2[,i]),n))
							binarycol = j
						}
					}

					SX0[ ., . ] = (SX0 :- Xmv[1,.]) :/ Sdx
					SX1[ ., . ] = (SX1 :- Xmv[1,.]) :/ Sdx
					
					m_krls_modpredictcore(SX0,SX1,i,1)

					// Create the contrast vector
					if (Contrast == .){
						Contrast = rangen(1/n,1/n,n)
					}
				
	 				real scalar bse
	 				Fdif = cross(Contrast,pYfit)
	 								
	 				bse = sqrt(cross(cross(Contrast,pVcovfit)',Contrast))*sqrt(2)
		
 					real matrix Medianbinary
 					Medianbinary= mms_quantile(pYfit, UQuantile)
 					
 					printf("{space %2.0f}", tablelength - (1 + strlen(substr(tokens(xname)[i],1,29))))
					printf("{txt}%s {c |} ", "*" + substr(tokens(xname)[i],1,29))
					printf("{res}%8.0g {space 1}", Fdif)
					printf("{res}%8.0g", bse)
					printf("{res}%9.3f", (Fdif / bse))	
					printf("{res}%9.3f  {space 1}", 2*ttail(n-d,abs(Fdif / bse)))
					
					for (j=1; j<=rows(UQuantile); j++){ 
						printf("{res}%8.0g {space 1}", Medianbinary[j,])
					}
					printf("\n")
					
					OutputRow = Fdif, bse, (Fdif / bse), 2*ttail(n-d,abs(Fdif / bse)), Medianbinary'

				}
									
					if (i==1){
						OutputM = OutputRow
					} else {
						OutputM = OutputM \ OutputRow 
					}	
			}		
			
			// Return full derivative matrix as columns in dataset
			if (deriv == "deriv"){
				for (i=1; i<=d; i++){
					if (_st_varindex("d_" + tokens(xname)[i])!=.) (void) st_dropvar("d_" + tokens(xname)[i])
					(void)  st_addvar("double","d_" + tokens(xname)[i])
					st_view(T, ., "d_" + tokens(xname)[i] , touse)
					
					if (tokens(Binary)[i] != "1"){
						T[.,.] = Drvmat[,i]
					} else {
						T[.,.] = pYfit
					}
				}
			}	
			
			printf("{txt}{hline %2.0f}{c +}{hline 68}\n",tablelength + 1)
			printf("\n")	   			
	
			if (binarycount > 0){
				printf("* average dy/dx is the first difference using the min and max (i.e. usually 0 to 1)")
 			}
 			
			st_matrix("Output",OutputM)
 			
 			} else {
 				printf("{txt}Derivatives suppressed\n")
 			}
}

// KRLS Predict Core used for binary
void m_krls_modpredictcore(real matrix X0, ///
						real matrix X1, ///
						real scalar subset, ///
						real scalar printlevel){
						
	// Assumes scaled
	real matrix  M
	external real matrix pYfit, pVcovfit, Sdy

	M = m_euclidian_distance_binary(X0,X1,rows(X0))

	pYfit = cross(M',Sdy,st_matrix("Coeffs"))  
	pVcovfit = cross((M * (st_matrix("Vcov") :* (1/(Sdy^2))))',M') :* Sdy^2	
}			

// Modified Euclidean Distance used for binary
matrix m_euclidian_distance_binary(real matrix X0, real matrix X1, real scalar n){
		real matrix D
		external real matrix SX, SX2
		real scalar i,j
		external real scalar binarycol
		D=J(n, n, .)
		
		for (i=n; i>0; i--){
 		   		for (j=1; j<=i; j++){
       	   				D[i,j] = exp(sum((X1[i,]-SX[j,]):^2)/-st_numscalar("k9tmp_sigma")) - exp(sum((X0[i,]-SX[j,]):^2)/-st_numscalar("k9tmp_sigma"))
					
       	   				if (SX2[j, binarycol] != 0 & SX2[i, binarycol] == 0){
       	   					D[j,i] = -D[i,j] 
       	   				} else if (SX2[i, binarycol] == 0 | SX2[j, binarycol] != 0) {
       	   					D[j,i] = D[i,j] 
       	   				} else {
       	   					D[j,i] = -D[i,j]
       	   				}	
   		    	}
			}
		return(D)		
}

// Squared Euclidean distance.
// Vectorized via ||x_i - x_j||^2 = ||x_i||^2 + ||x_j||^2 - 2 x_i' x_j,
// which is one BLAS GEMM (X * X') instead of n^2 d Mata-interpreted iterations.
// Mata's ':+' does NOT broadcast n×1 against 1×n to outer (unlike NumPy),
// so we expand norms explicitly to n×n via J()-products.
// The (sq :> 0) mask floors tiny negative residuals from floating-point at zero.
matrix m_euclidian_distance_sq(real matrix X, real scalar n, real scalar d){
		real colvector norms
		real matrix sq, ones

		norms = rowsum(X :^ 2)
		ones  = J(rows(X), 1, 1)
		sq    = norms * ones' :+ ones * norms' :- 2 :* (X * X')
		return(sq :* (sq :> 0))
}

// Euclidean distance (kept for any external callers that still rely on it).
matrix m_euclidian_distance(real matrix X, real scalar n, real scalar d){
		return(sqrt(m_euclidian_distance_sq(X, n, d)))
}

// Outer-difference, used for derivatives. X is n x 1; D[i,j] = X[i] - X[j].
// Mata's ':-' does NOT broadcast n×1 against 1×n (unlike NumPy), so we
// expand explicitly via two J()-product BLAS calls.
matrix m_distance(real matrix X, real scalar n){
		return(X * J(1, n, 1) :- J(n, 1, 1) * X')
}

// Quantile functions [modified versions of MOREMATA]
real matrix mms_quantile(real matrix X, ///
						 real matrix P)
{
    real rowvector result
    real scalar c, cX, cP, r, i

    if (cols(X)==1 & cols(P)!=1 & rows(P)==1) return(mms_quantile(X,  P')')
    if (missing(P) | missing(X)) _error(3351)
    r = rows(P)
    c = max(((cX=cols(X)), (cP=cols(P))))
    if (cX!=1 & cX<c) _error(3200)
    if (cP!=1 & cP<c) _error(3200)
    if (rows(X)==0 | r==0 | c==0) return(J(r,c,.))
    if (c==1) return(_mms_quantile(X, P))
    result = J(r, c, .)
    if (cP==1) for (i=1; i<=c; i++) result[,i] = _mms_quantile(X[,i], P)
    else if (cX==1) for (i=1; i<=c; i++)
     result[,i] = _mms_quantile(X, P[,i])
    else for (i=1; i<=c; i++)
     result[,i] = _mms_quantile(X[,i], P[,i])
    return(result)
}

real colvector _mms_quantile(real colvector X, ///
							 real colvector P)
{
    real colvector g, j, j1, p
    real scalar N

    N = rows(X)
    p = order(X,1) 
    g = P*N
    j = floor(g)
    g = 0.5 :+ 0.5*((g - j):>0)
    j1 = j:+1
    j = j :* (j:>=1)
    _editvalue(j, 0, 1)
    j = j :* (j:<=N)
    _editvalue(j, 0, N)
    j1 = j1 :* (j1:>=1)
    _editvalue(j1, 0, 1)
    j1 = j1 :* (j1:<=N)
    _editvalue(j1, 0, N)
    return((1:-g):*X[p[j]] + g:*X[p[j1]])
}
end	
