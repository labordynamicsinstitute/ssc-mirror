

cap program drop regoptwgt_loglik3plusendog
program regoptwgt_loglik3plusendog
	
	local arglist todo b lnf
	
	forvalues endognum=1/${powerlaw_numendog} {
		local arglist `arglist' g_xb`endognum'
		local arglist `arglist' g_lnetasq`endognum'
		local arglist `arglist' g_lnnusq`endognum'
	}
	forvalues i=1/${powerlaw_numendog} {
	forvalues j=`=`i'+1'/${powerlaw_numendog} {
		local arglist `arglist' g_fceta_`i'_`j' g_fcnu_`i'_`j'
	}
	}
	args `arglist'
	
	local eqnum 1
	forvalues endognum=1/${powerlaw_numendog} {
		tempvar xb`endognum'
		mleval `xb`endognum'' = `b', eq(`eqnum')
		local ++eqnum
		tempvar lnetasq`endognum'
		mleval `lnetasq`endognum'' = `b', eq(`eqnum')
		local ++eqnum
		tempvar lnnusq`endognum'
		mleval `lnnusq`endognum'' = `b', eq(`eqnum')
		local ++eqnum
	}
	forvalues i=1/${powerlaw_numendog} {
	forvalues j=`=`i'+1'/${powerlaw_numendog} {
	foreach currerr in eta nu {
		tempvar fc`currerr'_`i'_`j'
		mleval `fc`currerr'_`i'_`j'' = `b', eq(`eqnum')
		local ++eqnum
	}
	}
	}
	
	* Set up matrices as variables
	forvalues i = 1/${powerlaw_numendog} {
		tempvar gbmat_`i'
		gen double `gbmat_`i'' = ${ML_y`i'} - `xb`i''
		tempvar sigmat_`i'_`i'
		gen double `sigmat_`i'_`i'' = (${powerlaw_wgt})^(-1) * exp(`lnetasq`i'') + exp(`lnnusq`i'')
		forvalues j = 1/${powerlaw_numendog} {
		if `i'<`j' {
			tempvar sigmat_`i'_`j' sigmat_`j'_`i'
			gen double `sigmat_`i'_`j'' = (${powerlaw_wgt})^(-1) * (2*invlogit(`fceta_`i'_`j'')-1)*sqrt(exp(`lnetasq`i'')*exp(`lnetasq`j'')) ///
				 + (2*invlogit(`fcnu_`i'_`j'')-1)*sqrt(exp(`lnnusq`i'')*exp(`lnnusq`j''))
			gen double `sigmat_`j'_`i'' = `sigmat_`i'_`j''
		}
		}
	}
	
	* GB matrix
	mata: gbmat = st_data(., "`gbmat_1'")
	forvalues i = 2/${powerlaw_numendog} {
		mata: gbmat_readin = st_data(., "`gbmat_`i''")
		mata: gbmat = gbmat , gbmat_readin
	}
	
	* Sigma matrix
	mata: sigmat = st_data( ., "`sigmat_1_1'")
	forvalues i = 1/${powerlaw_numendog} {
	forvalues j = 1/${powerlaw_numendog} {
	if `i'!=1 | `j'!=1 {
		mata: sigmat_readin = st_data(., "`sigmat_`i'_`j''")
		mata: sigmat = sigmat , sigmat_readin
	}
	}
	}
	
	* Matrices to save results
	mata: lnfmat = J(rows(gbmat),1,.)
	mata: derivmat_gb  = J(rows(gbmat),${powerlaw_numendog},.)
	mata: derivmat_sig = J(rows(gbmat),${powerlaw_numendog}^2,.)
	
	* Iterate through each observation and calculate key values
	forvalues i = 1/`=_N' {
		
		* Temporary matrices with values for this observation
		mata: gbmat_oneobs = J(${powerlaw_numendog},1,.)
		forvalues j = 1/${powerlaw_numendog} {
			mata: gbmat_oneobs[`j',1] = gbmat[`i',`j']
		}
		mata: sigmat_oneobs = J(${powerlaw_numendog},${powerlaw_numendog},.)
		forvalues j = 1/`=${powerlaw_numendog}^2' {
			mata: sigmat_oneobs[ceil(`j'/${powerlaw_numendog}),mod(`j'-1,${powerlaw_numendog})+1] = sigmat[`i',`j']
		}
		
		* For use in other analysis
		mata: lusolvesiggb = lusolve(sigmat_oneobs,gbmat_oneobs)
		
		* lnf for each observation
		mata: lnfmat[`i',1] = -.5*ln(det(sigmat_oneobs)) - .5*(gbmat_oneobs' * lusolvesiggb)
		
		* Derivative with respect to gb matrix
		mata: derivmat_gb[`i',.] = lusolvesiggb'
		
		* Derivative with respect to sigma matrix
		mata: derivmat_sig[`i',.] = colshape(-.5 * invsym(sigmat_oneobs) + .5 * lusolvesiggb * lusolvesiggb',${powerlaw_numendog}^2)
		
	}
	
	* Save results for objective function
	qui getmata `lnf' = lnfmat, replace double
	if (`todo'==0) exit
	
	* Save results for derivative wrt GB matrix
	local gxblist 
	forvalues endognum=1/${powerlaw_numendog} {
		local gxblist `gxblist' `g_xb`endognum''
	}
	qui getmata (`gxblist') = derivmat_gb, replace double
	
	* Save results for derivative wrt sigma matrix.
	* Note that this is for derivative wrt elements of sigma matrix, whereas we are interested
	*  in derivatives wrt parameters, so more calculations are required.
	local g_sigmatlist 
	forvalues i=1/${powerlaw_numendog} {
	forvalues j=1/${powerlaw_numendog} {
		tempvar g_sigmat_`i'_`j'
		local g_sigmatlist `g_sigmatlist' `g_sigmat_`i'_`j''
	}
	}
	qui getmata (`g_sigmatlist') = derivmat_sig, replace double
	
	* Deriv wrt correlation
	forvalues i=1/${powerlaw_numendog} {
	forvalues j=`=`i'+1'/${powerlaw_numendog} {
		qui replace `g_fceta_`i'_`j'' = 2 * `g_sigmat_`i'_`j'' * (${powerlaw_wgt})^(-1) * sqrt(exp(`lnetasq`i'')*exp(`lnetasq`j'')) * ///
			2*invlogit(`fceta_`i'_`j'')*(1-invlogit(`fceta_`i'_`j''))
		qui replace `g_fcnu_`i'_`j'' = 2 * `g_sigmat_`i'_`j'' * sqrt(exp(`lnnusq`i'')*exp(`lnnusq`j'')) * ///
			2*invlogit(`fcnu_`i'_`j'')*(1-invlogit(`fcnu_`i'_`j''))
	}
	}
	
	* Deriv wrt eta, nu
	forvalues i=1/${powerlaw_numendog} {
		qui replace `g_lnetasq`i'' = `g_sigmat_`i'_`i'' * (${powerlaw_wgt})^(-1) * exp(`lnetasq`i'')
		qui replace `g_lnnusq`i''  = `g_sigmat_`i'_`i'' * exp(`lnnusq`i'')
	}
	forvalues i=1/${powerlaw_numendog} {
	forvalues j=1/${powerlaw_numendog} {
	if `i'!=`j' {
		local minij = min(`i',`j')
		local maxij = max(`i',`j')
		qui replace `g_lnetasq`i'' = `g_lnetasq`i'' + 2 * `g_sigmat_`i'_`j'' * .5 * sqrt(exp(`lnetasq`j'')*exp(`lnetasq`i''))*(${powerlaw_wgt})^(-1) * (2*invlogit(`fceta_`minij'_`maxij'')-1)
		qui replace `g_lnnusq`i''  = `g_lnnusq`i''  + 2 * `g_sigmat_`i'_`j'' * .5 * sqrt(exp(`lnnusq`j'')*exp(`lnnusq`i'')) * (2*invlogit(`fcnu_`minij'_`maxij'')-1)
	}
	}
	}
	
end // program regoptwgt_loglikendog3plus
