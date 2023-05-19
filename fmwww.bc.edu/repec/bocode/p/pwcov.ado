*! pwcov 1.1.1  CFBaum 18 May 2023  
*! pwcov 1.0.1  22jul2006  
program pwcov, rclass
	version 9.2
	syntax varlist(min=2) [if] [in] [fweight pweight/], [PRINT] [SAVE]

// do not exclude missing values in touse
	marksample touse, novarlist
	qui count if `touse'
        if r(N) == 0 error 2000

	if "`save'" == "save" {   
		confirm new var pw_t
		confirm new var pw_tk
		confirm new var pw_cov
		confirm new var pw_N
		qui {
			g pw_t = .
			g pw_tk = .
			g pw_cov = .
			g pw_N = .
			}
		local varlist1 pw_t pw_tk pw_cov pw_N
	}
	if "`weight'" != "" {
		confirm numeric variable `exp'
	}
	
	mata: pwcov("`varlist'","`varlist1'","`touse'","`exp'")

		mat colnames cov = `varlist'
		mat rownames cov = `varlist'
		if "`print'" == "print" {
		if "`weight'" != "" {
			local wexp "[ `weight' = `exp' ]" 
		}
		mat list cov, ti("Pairwise VCE  `wexp'")
	}
	
return matrix pwcov = cov
end

mata: 
void pwcov( string scalar vname,
			string scalar vname1, 
			string scalar touse, 
			string scalar wtvar)

  {
	string rowvector vars, vars1
	string scalar v, v1
	real scalar i, j, k, var
	real matrix pwcov, two, vv, Y
  
	vars = tokens(vname)
	v = vars[|1,.|]
	st_view(X,.,v,touse)
	if (vname1 ~= "") {
		vars1 = tokens(vname1)
		v1 = vars1[|1,.|]
		st_view(Y,.,v1,.)
  	}
  	if (wtvar ~= "") {
  		vars2 = tokens(wtvar)
  		v2 = vars2[|1,.|]
  		st_view(W,.,v2,touse)
  	}
  	else {
  		W = J(rows(X),1,1)
  	}
// number of variables for which pairwise covariances needed
	k = cols(X)
	pwcov= J(k,k,.)
	e = 1
	for(i=1;i<=k-1;i++) {
		vv = variance(X[.,i],W)
		pwcov[i,i] = vv[1,1]
  		for(j=i+1;j<=k;j++) {
  			two = variance((X[.,i],X[.,j]),W)
	  		pwcov[j,i] = two[2,1]
			pwcov[i,j] = two[2,1]
	  		if (vname1 ~= "") {	
// number of elements entering covariance
  				Y[e,1] = i
  				Y[e,2] = j
  				Y[e,3] = two[2,1]
  				Y[e,4] = sum(nonmissing(X[.,i] :* X[.,j]))
  				e++
  			}
  		}
  	}
	vv = variance(X[.,k],W)
	pwcov[i,i] = vv[1,1]
	st_matrix("cov",pwcov)
  }
 end
 
