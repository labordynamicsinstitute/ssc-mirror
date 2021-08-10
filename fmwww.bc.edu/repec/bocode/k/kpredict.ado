*! version 1.01  Jeremy Ferwerda

program kpredict
version 11
	syntax name(name=newvarname) [if] [, Se, Fitted, Residuals]
	
	if ("`e(cmd)'" != "krls") error 301


	// Use [if/in] constraints from original call

	tempvar kpredictif
	tempvar trainingset
	tempvar testset
	
	mark `kpredictif' `if'	
	mark `trainingset' 
	mark `testset' 
	
	
	confirm new var `newvarname'
	
	// Display Settings
	if ("`se'" == "se") local seflag = "1"
	else local seflag = "0" // default fitted
	
	qui: replace `testset' = 0 
	qui: replace `trainingset' = 1 
		
	qui: replace `trainingset' = 0 if `e(depvar)' == . | e(sample) != 1 | `kpredictif' != 1 
	qui: replace `testset' = 1     if `e(depvar)' == . | e(sample) != 1 | `kpredictif' != 1 
	
	mata: m_krls_predict_wrapper("`trainingset'","`testset'","`newvarname'","`seflag'","`e(depvar)'")

	if ("`residuals'" == "residuals"){
	
		gen krlstep =  `e(depvar)' - `newvarname'
		drop `newvarname'
		rename krlstep `newvarname'
		
	}
		
end


version 11
mata:
mata set matastrict on
mata set matafavor speed

// KRLS Predict Core
void m_krls_predictcore(real matrix X, ///
						real scalar subset, ///
						real scalar printlevel){
						
	// Assumes scaled
	real matrix K
	external real matrix pYfit, pSEfit

	K= exp((-1*m_euclidian_distance(X,rows(X),cols(X)):^2)/st_numscalar("k9tmp_sigma"))
	if (subset != 0){
		K = K[1::subset,(subset+1)::cols(K)]		
	}
		
	pYfit = cross(K',st_numscalar("sdy"),st_matrix("Coeffs")) :+ st_numscalar("meany")
	
	if (printlevel == 1){
    	pSEfit = sqrt(diagonal(cross((K * (st_matrix("Vcov") :* (1/(st_numscalar("sdy")^2))))',K') :* st_numscalar("sdy")^2))  	
    } 

}			
	
	
// KRLS Predict Function  - Command Line
void m_krls_predict_wrapper(string scalar trainingset, ///
						    string scalar testset, ///
					        string scalar newvarname, ///
					        string scalar saveseflag, ///
					        string scalar depvar){
							     
	real matrix X, X2, T, Z, Y
	external real matrix pYfit, pSEfit, nonmissingrows
	real scalar i,d,j,k,missing,missingtrain,missingy,maxiterate,subset
	
	
	// If training indicator passed, appends test data to training data. Otherwise, uses entire dataset
		X = st_data(.,  tokens(st_global("xname")), trainingset)
		Y = st_data(.,  tokens(depvar), trainingset)

		if (testset != ""){
			X2 = st_data(.,  tokens(st_global("xname")), testset) 
			X = (X2 \ X)
			Y = (st_data(.,  tokens(depvar), testset) \ Y)

		} else {
			maxiterate = rows(X) + 1
		}
		subset = rows(X)

		// Handle missing values
			missingy = 0
			nonmissingrows = rownonmissing(Y)
			for (i=1;i<=rows(nonmissingrows);i++){
				if (nonmissingrows[i,1] == 0 & i <= rows(X2)){
					nonmissingrows[i,1] = 1
					missingy++
				}
			}
			
			nonmissingrows = nonmissingrows + rownonmissing(X)
			d = cols(X) + 1
			missing=0
			missingtrain=0
			for (i=1;i<=rows(nonmissingrows);i++){
				if (nonmissingrows[i,1] < d){
					nonmissingrows[i,1] = 0
					missing++
					if (i > rows(X2)){
						missingtrain++
					}
				}
			}
			X = select(X,nonmissingrows)
	
	// Rescale
		X[ ., . ] = (X :- st_matrix("meanx")) :/ st_matrix("sdx")
		
	// Predict
		if (testset != ""){
			maxiterate = rows(X2)
			m_krls_predictcore(X,rows(X2)-missing+missingtrain,1)
		} else {
			m_krls_predictcore(X,0,1)
		}

		// Add values
       (void) st_addvar("double",newvarname)
       		st_view(T, ., newvarname, trainingset)
       		st_view(Z, ., newvarname, testset)
        	if (rows(Z) > 0){
				if (missingtrain == 0 & missingy==0){
					if (saveseflag == "1"){
						T[.,.] = st_matrix("SEfit")
					} else {
						T[.,.] = st_matrix("Yfitted")
					}	
				} 
				st_view(Z, ., newvarname, trainingset)
				st_view(T, ., newvarname, testset)
 			}
 			
 		
 			// Handle missing values
 			if (missing == 0 & missingy==0){ 
 			
 				if (testset != ""){
 					if (saveseflag == "1"){
 						T[.,.] =  pSEfit
 					} else {
 						T[.,.] = pYfit
 					}
 				} else {
 			
 					if (saveseflag == "1"){
 						T[.,.] = st_matrix("SEfit")
 					} else {
 						T[.,.] = st_matrix("Yfitted")
 					}	
 				}	
 				
 			} else {
 			
 				j = 1
 				for (i=1;i<=rows(T);i++){	
 					if (nonmissingrows[i,1] != 0){
 						if (saveseflag == "1"){
 							T[i,1] = pSEfit[j] 
 						} else {
 							T[i,1] = pYfit[j]
 						}
 						j++
 					} 			
 				}	
				
 				if (testset != "" & (missingtrain != 0 | missingy!= 0)){
 				 	k = i
 					j = 1	
 					
 					for (i=1;i<=rows(Z);i++){	
 						d = k + i - 1
 						if (nonmissingrows[d,1] != 0){	
 							if (saveseflag == "1"){
 								Z[i,1] = st_matrix("SEfit")[j]
 							} else {
 								Z[i,1] = st_matrix("Yfitted")[j]
 							}
 							j++
 						}	
 					}	
 				}		
 			}   
 	}				
		
// Euclidean Distance
matrix m_euclidian_distance(real matrix X, real scalar n, real scalar d){

		real matrix D
		real scalar i,j
		D=J(n, n, .)
		
		for (i=n; i>0; i--){
 		   		for (j=1; j<=i; j++){
       	   				D[i,j] = sqrt(sum((X[i,]-X[j,]):^2))
       	   				D[j,i] = D[i,j]
   		    	}
			}
		return(D)	
}
end
