*! v4 29 Nov 2023
/***************THESE FUNCTIONS ARE FOR THE NON-PARAMETRIC BOOTSTRAP*****/
pro def cwmbootstrap, rclass
version 16.0
syntax [varlist (default=none)], [Reps(int 100)]
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
tempname _p
quie predict `_p', posterior
quie describe `_p'*, varlist
local posterior `r(varlist)'
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
local nmulti=e(nmult)
local k=e(k)
matrix BB=e(b)
tempname _beta _p_binomial _mu _lambda 
if ("`xmultinomial_fv'"!="") { //loading multinomial returned results
		forval i=1/`nmulti' {
		tempname _mult`i' _xmult_p`i'
		local rownames`i':  rownames e(p_multi_`i')
		matrix `_xmult_p`i''=vec(e(p_multi_`i'))'
	}
}
if ("`depvar'"!="")  {
	tempname _b
	matrix `_b'=e(b)
	}
	if ("`xnormal'"!="") {
		tempname _xnormal_mu
		matrix `_xnormal_mu'= vec(e(mu))'

	}
	
	if ("`xpoisson'"!="") {
		tempname _xpoisson_lambda
		matrix `_xpoisson_lambda'=vec(e(lambda))'
	}
	if ("`xbinomial'"!=""){
		tempname _xbinomial_p
		matrix `_xbinomial_p'=vec(e(p_binomial))'
	}

_dots 0, title("Bootstrap replications") reps(`reps') nodots
forval rep=1/`reps' {
    preserve
	bsample(`Nobs') if `touse' //sample the observations
	//main is called to re-estimated the CWM: the posterior probabilities are used as initial values, this favours speed and makes label switching less likely
	quie cap m:   _cwmglm_main(`k',"custom",10,`iterate', "`touse'" ,"`posterior'","`depvar'","`indepvars'","`glmfamily'" , "`xnormal'","`xnormmodel'" , "`xbinomial'", "`xmultinomial_fv'","`xpoisson'", `iterate',`convcrit',"off")
	restore

	if !_rc {
			nois _dots `rep' 0
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
	else nois _dots `rep' 1
	//if (mod(`rep',10)==0) noi di as result "`rep'"
}

display _newline
tempname _bb _VV
if ("`depvar'"!="") {
		mata: st_matrix("`_VV'", variance(st_matrix("`_beta'") ) )
		matrix colnames `_VV'=`:colnames `_b''
		matrix rownames `_VV'=`:colnames `_b''
		matrix coleq `_VV'=`:coleq `_b''
		matrix roweq `_VV'=`:coleq `_b''
		di as result "GLM estimates",  _newline   
ereturn post `_b' `_VV'
		_coef_table , neq(`k')  
		*_coef_table , bmatrix(`_b') vmatrix(`_VV') neq(`k')  
		matrix `_beta'=r(table)
		return matrix b=`_beta'
	}
	if ("`xnormal'"!="") {
		mata: st_matrix("`_VV'", variance(st_matrix("`_mu'") ) )
		di as result "Mean of Gaussian covariates (marginal distribution)",  _newline   
		_coef_table , bmatrix(`_xnormal_mu') vmatrix(`_VV') neq(`k')
		matrix `_mu'=r(table)
		return matrix mu=`_mu'
	}
if ("`xpoisson'"!="") {
	mata: st_matrix("`_VV'", variance(st_matrix("`_lambda'") ) )
	di as result "Mean of Poisson covariates (marginal distribution)",  _newline   
	_coef_table , bmatrix(`_xpoisson_lambda') vmatrix(`_VV') neq(`k') 
	matrix `_lambda'=r(table)
	return matrix lambda=`_lambda'
	}

if ("`xbinomial'"!="") {
		mata: st_matrix("`_VV'", variance(st_matrix("`_p_binomial'") ) )
		di as result "Mean of Binomial covariates (marginal distribution)",  _newline  
		_coef_table , bmatrix(`_xbinomial_p') vmatrix(`_VV') neq(`k')
		matrix `_p_binomial'=r(table)
		return matrix p_binomial=`_p_binomial'
	}
		if ("`xmultinomial_fv'"!="") {
				forval i=1/`nmulti' {
					local multvar: word `i'  of `xmultinomial' 
					di as result "Mean of Multinomial covariate `multvar'",  _newline  
					//mata: _summary_stat_bootstrap("`_mult`i''","`_bb'","`_VV'")
					mata: st_matrix("`_VV'", variance(st_matrix("`_mult`i''") ) )
					_coef_table , bmatrix(`_xmult_p`i'') vmatrix(`_VV') neq(`k')
					matrix `_mult`i''=r(table)
					return matrix p_multi_`i'=`_mult`i''
				}
				
		}
quie estimates restore `_estimates'
end

