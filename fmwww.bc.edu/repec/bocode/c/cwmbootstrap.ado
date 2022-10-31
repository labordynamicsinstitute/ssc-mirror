*! v3 10 Oct 2022


/***************THESE FUNCTIONS ARE FOR THE NON-PARAMETRIC BOOTSTRAP*****/
cap pro drop cwmbootstrap 
pro def cwmbootstrap, rclass
version 16.0
syntax [varlist (default=none)], [nreps(int 100)]
if ("`e(cmd)'"!="cwmglm") {
	di as error "last cwmglm estimates not found, please execute this command after {bf: cwmglm}"
	exit 144
}
tempname _estimates
tempvar touse
//saves current cwmglm estimates to make them available again after boostrapping
quie estimates store `_estimates'
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
local xmultinomial `e(xmultinomial)'
local xpoisson `e(xpoisson)'
local convcrit `e(convcrit)'
local nmulti=e(nmulti)
local k=e(k)

tempname _beta _p_binomial _mu _lambda 
if ("`xmultinomial_fv'"!="") { //loading multinomial returned results
		forval i=1/`nmulti' {
		tempname _mult`i'
		local rownames`i':  rownames e(p_multi_`i')
	}
}
di "Starting `nrep' replications"
forval rep=1/`nreps' {
    preserve
	bsample(`Nobs') //sample the observations
	//main is called to re-estimated the CWM: the posterior probabilities are used as initial values, this favours speed and makes label switching less likely
	cap quie m:  _cwmglm_main(`k',"",10,`iterate', "`touse'" ,"`posterior'","`depvar'","`indepvars'","`glmfamily'" , "`xnormal'","`xnormmodel'" , "`xbinomial'", "`xmultinomial_fv'","`xpoisson'", `iterate',`convcrit')
	restore

	if !_rc {
			noi di ".", _continue 
			if ("`depvar'"!="") matrix `_beta'=nullmat(`_beta') \ `b'
			if ("`xnormal'"!="") {
				matrix `mu'	=`mu''
				matrix `_mu'=nullmat(`_mu') \ vec(`mu')'			
				}
			if ("`xbinomial'"!="") matrix `_p_binomial'=nullmat(`_p_binomial') \ vec(`p_binomial')'
			if ("`xpoisson'"!="") matrix `_lambda'=nullmat(`_lambda') \vec(`lambda')'
			if ("`xmultinomial_fv'"!="") {				
					forval i=1/`nmulti' {
					matrix rownames `p_multi_`i''=`rownames`i''
					matrix `_mult`i''=nullmat(`_mult`i'') \ vec(`p_multi_`i'')'
					}				
			}
		}
	else noi di "x", _continue
	if (mod(`rep',10)==0) noi di as result "`rep'"
}
tempname _bb _VV
if ("`depvar'"!="") {
		mata: _summary_stat_bootstrap("`_beta'","`_bb'","`_VV'")
		di as result "GLM estimates",  _newline   
		_coef_table , bmatrix(`_bb') vmatrix(`_VV') neq(`k') 
		matrix `_beta'=r(table)
		return matrix b=`_beta'
	}
	if ("`xnormal'"!="") {
		mata: _summary_stat_bootstrap("`_mu'","`_bb'","`_VV'")
		di as result "Mean of Gaussian covariates (marginal distribution)",  _newline   
		_coef_table , bmatrix(`_bb') vmatrix(`_VV') neq(`k')
		matrix `_mu'=r(table)
		return matrix mu=`_mu'
	}
if ("`xpoisson'"!="") {
	mata: _summary_stat_bootstrap("`_lambda'","`_bb'","`_VV'")
	di as result "Mean of Poisson covariates (marginal distribution)",  _newline   
	_coef_table , bmatrix(`_bb') vmatrix(`_VV') neq(`k') 
	matrix `_lambda'=r(table)
	return matrix lambda=`_lambda'
	}

if ("`xbinomial'"!="") {
		mata: _summary_stat_bootstrap("`_p_binomial'","`_bb'","`_VV'")
		di as result "Mean of Binomial covariates (marginal distribution)",  _newline  
		_coef_table , bmatrix(`_bb') vmatrix(`_VV') neq(`k')
		matrix `_p_binomial'=r(table)
		return matrix p_binomial=`_p_binomial'
	}
		if ("`xmultinomial_fv'"!="") {
			
				forval i=1/`nmulti' {
					local multvar: word `i'  of `xmultinomial' 
					di as result "Mean of Multinomial covariate `multvar'",  _newline  
					mata: _summary_stat_bootstrap("`_mult`i''","`_bb'","`_VV'")
					_coef_table , bmatrix(`_bb') vmatrix(`_VV') neq(`k')
					matrix `_mult`i''=r(table)
					return matrix p_multi_`i'=`_mult`i''
				}
				
		}
quie estimates restore `_estimates'
end

