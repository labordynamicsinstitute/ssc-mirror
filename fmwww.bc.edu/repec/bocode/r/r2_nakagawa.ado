*! version 1.0.0  25jun2024 // Daniel Klein & Ariel Linden

program r2_nakagawa , rclass
    
	version 16.1
    
	syntax // nothing allowed
    
	if ("`e(cmd)'" != "mixed") {
		display as err "r2_nakagawa is only valid after {bf:mixed}"
		exit 321
    }
    
	re_equation_no_fv_or_ts_varlist
    
	quietly estat recovariance // error for single-level models intended
    
	/* 
		Do not call any commands that return r()
		after the call to -estat recovariance- !
	*/
    
	tempvar esample xb cons
    
	quietly {
		generate double `esample' = e(sample)
		predict `xb' if `esample' , xb
		generate byte `cons' = 1
    }
    
	tempname Var_e
    
	// variance of the residual
	scalar `Var_e' = exp(_b[/lnsig_e])^2
    
	mata : r2_nakagawa(         ///
		"`xb'",                 ///
		"`esample'",            ///
		"`cons'",               ///
		st_numscalar("`Var_e'") ///
	)
    
	return add
    
	display
	display as txt "Nakagawa's R-squared for Mixed Models"
	display
	display as txt %31s "Conditional R-squared: " as res %5.4f return(r2_c)
	display as txt %31s    "Marginal R-squared: " as res %5.4f return(r2_m)
    
end


program re_equation_no_fv_or_ts_varlist
    
	local e_revars = subinstr(subinstr(" `e(revars)' "," ","  ",.)," _cons ","",.) // sic!
	local e_revars `e_revars' // strip leading and trailing whitespaces
    
	if ("`e_revars'" == "") /// random intercepts only
		exit
    
	local e_revars = ustrtrim(ustrregexra("`e_revars'","R\.\S+",""))
    
	if ("`e_revars'" == "") /// random intercepts or R.varname only
		exit
    
	fvexpand `e_revars'
    
	if ( !inlist("true","`r(fvops)'","`r(tsops)'") ) /// no fv or ts operators
		exit
    
	display as err "{bf:r2_nakagawa} does not support" ///
		" factor variable and time-series operators in {it:re_equation}"
	exit 321
    
end


version 16.1


mata :

mata set matastrict   on
mata set mataoptimize on

void r2_nakagawa(
	string scalar xb,
	string scalar esample,
	string scalar cons,
	real scalar Var_e
    )
{
	real scalar Var_fe
	real scalar Var_re
	real scalar r2_c
	real scalar r2_m
    
	// variance of the fixed effects
    Var_fe = variance(st_data(.,xb,esample))
    
	// variance of the random effects
	Var_re = Var_re(cons,esample)
    
	// conditional R^2
	r2_c = (Var_fe + Var_re) / (Var_fe + Var_re + Var_e)
	// marginal R^2
	r2_m = (Var_fe         ) / (Var_fe + Var_re + Var_e)
    
	st_rclear()
	st_numscalar("r(Var_e)",Var_e)
	st_numscalar("r(Var_re)",Var_re)
	st_numscalar("r(Var_fe)",Var_fe)
	st_numscalar("r(r2_m)",r2_m)
	st_numscalar("r(r2_c)",r2_c)
}


real scalar Var_re(
	string scalar cons,
	string scalar esample
	)
{
	real   scalar    Var_re
	string rowvector e_revars
	real colvector   revars_idx
	real   scalar    k
	real   scalar    i
	real   matrix    Sigma
	string rowvector colnames
	string rowvector e_revars_i
	real matrix      Z
    
	pragma unset Z

    Var_re = 0
    
	e_revars = tokens(st_global("e(revars)"))
    
	revars_idx = (0 \ 0)
    
	k = st_numscalar("r(relevels)")
    
	for (i=2;i<=k;i++) {
		Sigma = st_matrix(sprintf("r(Cov%f)",i))
		colnames = st_matrixcolstripe(sprintf("r(Cov%f)",i))[,2]'
		colnames = ustrregexrf(colnames,"^_cons$",cons)
        
		revars_idx = ((revars_idx[2]+1) \ (revars_idx[2]+cols(Sigma)))
		e_revars_i = ustrregexrf(e_revars[|revars_idx|],"^_cons$",cons)
        
		if ( any(ustrregexm(e_revars_i,"^R\.")) )
			R_varname(e_revars_i,colnames,cons)
		else if (e_revars_i != colnames)
			unexpected_error() // NotReached
        
		if ( allof(e_revars_i,cons) ) {
            
			/*
				Shortcut for random intercepts or R. notation
			*/
            
			Var_re = Var_re + sum(Sigma)
			continue
		}
        
        // Johnson (2014, eqn 10 & eqn 11)
        
		st_view(Z,.,e_revars_i,esample)
		Var_re = Var_re + ( trace(Z*Sigma*Z') / rows(Z) )
	}
    
	return(Var_re)
}


void R_varname(
	string rowvector e_revars_i,
	string rowvector colnames,
	string scalar    cons
	)
{
	if (ustrregexrf(e_revars_i,"^R\.","R_") != colnames)
		unexpected_error() // NotReached
	e_revars_i = ustrregexrf(e_revars_i,"^R\..*$",cons)
}


void unexpected_error()
{
	errprintf("unexpected error in {bf:r2_nakagawa}\n")
	errprintf("variable names in e(revars) do not match")
	errprintf(" column names of random-effects covariance matrix\n")
	exit(322)
}


end


exit