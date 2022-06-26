*! v1 24 jun 2022
cap mata: mata drop createable
mata:
void createtable(string mat) { //create a table with mean se CI and z-value basing on the bootstrapped values stored in stata matrix mat (it replaces mat)
	real matrix Mat, mean, sd
	string matrix colstripe
	Mat=st_matrix(mat)
	mean=mean(Mat)
	sd=sqrt(diagonal(variance(Mat)))'
	colstripe=st_matrixcolstripe(mat)
	Mat=mean\sd\(mean-1.96*sd)\(mean+1.96*sd)\ (mean:/sd)
	st_matrix(mat,Mat)
	st_matrixcolstripe(mat,colstripe)
	st_matrixrowstripe(mat, (J(5,1,""),("mean","sd",  "95% CI lcl" ,"95% CI ucl", "z")'))
}

end
/***************THESE FUNCTIONS ARE FOR THE NON-PARAMETRIC BOOTSTRAP*****/
cap pro drop cwmbootstrap 
pro def cwmbootstrap, rclass
version 16.0
syntax [varlist (default=none)], [nreps(int 100)]
if ("`e(cmd)'"!="cwmglm") {
	di as error "last cwmglm estimates not found, please execute this command after {bf: cwmglm}"
	exit 144
}

tempvar touse
//the returned results of the last cwmglm estimates are used as an input to the bootstrap
gen `touse'=e(sample)
quie count if `touse'
local Nobs=r(N)
local posterior `e(posterior)'
local iterate=`e(iterate)'
local depvar `e(depvar)'
local indepvars `e(indepvars)'
local glmfamily `e(glmfamily)'
local xnormal `e(xnormal)'
local xnormmodel `e(xnormmodel)'
local xbinomial `e(xbinomial)'
local xmultinomial_fv `e(xmultinomial_fv)'
local xpoisson `e(xpoisson)'
local convcrit `e(convcrit)'
local nmulti=e(nmulti)
local k=e(k)

tempname _beta _p_binomial _mu _lambda 
if ("`xmultinomial_fv'"!="") { //loading multinomial returned results
		forval i=1/`nmulti' {
		tempname MULT`i'
		local rownames`i':  rownames e(p_multi_`i')
	}
}
di "Starting `nrep' replications"
forval rep=1/`nreps' {
    preserve
	bsample(`Nobs') //sample the observations
	//main is called to re-estimated the CWM: the posterior probabilities are used as initial values, this favours speed and makes label switching less likely
	cap quie m:  main(`k',"",10,`iterate', "`touse'" ,"`posterior'","`depvar'","`indepvars'","`glmfamily'" , "`xnormal'","`xnormmodel'" , "`xbinomial'", "`xmultinomial_fv'","`xpoisson'", `iterate',`convcrit')
	restore

	if !_rc {
			noi di ".", _continue 
			if ("`glmfamily'"!="") matrix `_beta'=nullmat(`_beta') \ `b'
			if ("`xnormal'"!="") matrix `_mu'=nullmat(`_mu') \ `mu'
			if ("`xbinomial'"!="") matrix `_p_binomial'=nullmat(`_p_binomial') \ `p_binomial'
			if ("`xpoisson'"!="") matrix `_lambda'=nullmat(`_lambda') \ `lambda'
			if ("`xmultinomial_fv'"!="") {
				
					forval i=1/`nmulti' {
						tempname _app p_mult`i'
						
							forval j=1/`k' {
								matrix `_app'=`p_multi_`i''[.,"g`j'"]    
								matrix roweq `_app'="g`j'"
								//noi di in red "`:rownames `e(p_multi_`i')'''"
								matrix rownames `_app'= `rownames`i''
								matrix `p_mult`i''=nullmat(`p_mult`i''), `_app''
											}
					
					matrix `MULT`i''=nullmat(`MULT`i'') \ `p_mult`i''
		//matlist `_p_multi_`i''
					}
		}
	}
	else noi di "x", _continue
	if (mod(`rep',10)==0) noi di as result "`rep'"
}
if ("`glmfamily'"!="") {
	mata: createtable("`_beta'")
	return matrix b=`_beta'
	}
	
if ("`xpoisson'"!="") {
	mata: createtable("`_lambda'")
	return matrix lambda=`_lambda'
	}
	if ("`xnormal'"!="") {
		mata: createtable("`_mu'")
		return matrix mu=`_mu'
	}
if ("`xbinomial'"!="") {
	mata: createtable("`_p_binomial'")
	return matrix p_binomial=`_p_binomial'
	}
		if ("`xmultinomial_fv'"!="") {
			
				forval i=1/`nmulti' {
				mata: createtable("`MULT`i''")	
				return matrix p_multi_`i'=`MULT`i''
				}
				
		}

end

