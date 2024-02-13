// Stanislav Anatolyev (sanatoly@nes.ru)
// Cheuk Fai Ng (cfn24@cam.ac.uk)
// Program: vce_mcov
// It computes the Leave-Cluster-Out-Crossfit variance estimates for linear regression models with many covariates (see Anatolyev and Ng 2024).
// v0.0.2, date: 03/06/2023
// v0.0.3, date: 16/01/2024
// v0.0.4, date: 17/01/2024 
// v0.0.5, date: 24/01/2024 
// We thank Prof. Christopher Baum for his useful feedback which improved the functionality of this routine.
program define vce_mcov, eclass
        version 14

		syntax [if] [in] [,numvars(integer 1)]
		
		// Check that reg  has been performed.
		if "`e(cmd)'" == "regress" {
		
		if "`e(vce)'" != "cluster"  {
			display as error "must use option vce(cluster clustvar)"
			error 301
		}
		
		marksample touse
	
		local cmdline "`e(cmdline)'"
		gettoken cmd cmdline : cmdline
		gettoken varlist right: cmdline, parse(",")
		
		gettoken depvar indepvars : varlist
		_fv_check_depvar `depvar'
		// _fv_check_depvar checks whether the dependent variable is a factor variable.

		local cluster_group `e(clustvar)'
		// display "`cluster_group'"
		
		quietly count if `cluster_group'==. & `touse' == 1
		// list `touse'
		if `r(N)' > 0 {
			display as error "missing values in cluster variable"
			error 301
		}

		
		fvexpand ibn.`cluster_group'
		// fvexpand finds the levels and creates a list of the names of factor variabless e.g 1bn.rep78, 2.rep78, 3.rep78, 4.rep78, and 5.rep78.
		display "--------------------------------------------------------------------"
		display "dependent variable: `depvar'"
		local gnames `r(varlist)'
		display "cluster variable(s): `cluster_group'"
		fvexpand `indepvars' 
		local cnames `r(varlist)'
		display "independent + control variable(s): `cnames'"
		display "--------------------------------------------------------------------"
		/*
		Line 54 uses fvexpand to expand the factor variables in indepvars. 
		Line 56 puts the expanded names stored in r(varlist) by fvexpand in the local macro cnames.  
		Mata functions required them.
		*/

		
		
		tempname b V N rank df_r
		
		//matrix `b' = e(b)
		//matrix list `b'
		mata: getVariance2("`depvar'", "`gnames'", "`cnames'", "`touse'", ///
			"`V'", "`N'", "`rank'", "`df_r'", "`numvars'") 
		local cnames `cnames' _cons
		
		// --

		// --
		matrix colnames `V'  = `cnames'
		matrix rownames `V'  = `cnames'
		//matrix list `V'
		display " "
		display "--------------------------------------"
		display "    Table with default estimates:     "
		display "--------------------------------------"
		
		ereturn display
		
		display "--------------------------------------"
		display "    New table with LCOC estimates:    "
		display "--------------------------------------"
	
		ereturn repost V=`V'
		ereturn display
    }	
	else {
		display as error "vce_mcov can only be used after reg"
		error 301
	}
	end

mata:
 
void getVariance2( string scalar depvar,  string scalar clu_var, 
             string scalar indepvars, string scalar touse,
			 string scalar Vname,  string scalar nname,   
			 string scalar rname, string scalar dfrname, string scalar numvars) 
{
	
	// Number of parameters interested
	real scalar p
	p = strtoreal(numvars) 

    real vector y, b, e, e2
    real matrix X, XpXi
    real scalar n, k
	// Note below st_data only take strings as argument
    y    = st_data(., depvar, touse)
	//y    = st_data(., depvar, touse)
	
	id_vars  = st_data(., clu_var, touse)
	adj_mat = id_vars*id_vars'
    X    = st_data(., indepvars, touse)
    n    = rows(X)
	// rows(X) puts the number of observations into n
	
	X    = X,J(n,1,1)
	// Add a column of ones onto X for the constant term
 
    XpX = quadcross(X, X)
	// Use quadcross() to calculate X′X in quad precision.

    XpXi = invsym(XpX)
	// Use invsym() to invert XpXi

    // Get beta estimates stored in e(b) to Mata
	"----------------------------------------------------------"
	"- This might take a while if number of clusters is large -"
	"----------------------------------------------------------"
		e_lg = y*0
		// Looping over each cluster to produce leave-cluster-out residuals
		for(i=1; i<=cols(id_vars); i=i+1){
			
			makenoise(i, cols(id_vars), cols(id_vars))
			X_`i' = X:*id_vars[|.,i|]
			y_`i' = y:*id_vars[|.,i|]
			XpX_leave_`i' = quadcross(X-X_`i', X-X_`i')
			XpXi_leave_`i' = invsym(XpX_leave_`i')
			b_`i'    = quadcross(XpXi_leave_`i',quadcross(X-X_`i', y-y_`i'))
			e_`i' = y - quadcross(X',b_`i')
			e_lg = e_lg + e_`i':*id_vars[|.,i|]
		}
	

	// Compute leave-cluster-out-crossfit covariance matrix,
   	cov_hat   = (y*e_lg'):*adj_mat/n
	
	// Compute the leave-cluster-out crossfit variance estimates for selected coefficents
	V    = quadcross(quadcross(XpXi,X')',quadcross(cov_hat,quadcross(X',XpXi)))
	V_output = st_matrix("e(V)")
	V_output[|1,1 \ p,p|] = V[|1,1 \ p,p|]
	V_output = (V_output' + V_output)/2

	// Return outputs to stata.	
    st_matrix(Vname, V_output)
    st_numscalar(nname, n)
    st_numscalar(rname, k)
    st_numscalar(dfrname, n-k)

}

void makenoise(real scalar its,real scalar draws, real scalar val)
{
    if (round(its/50)==its/50 & its!=draws) {
		printf(".")
    //    printf(" loops completed %f of %g\n",its,val)
        displayflush()
    }
/*	
    else if (& its!=draws) {
        printf(".")
        displayflush()
                             }
    else {
            printf("loops completed \n %f of %g\n ",its,val)
		}
*/
}
 
end
