* Version 1.5 in 19 Nov 2025, Manh Hoang Ba (hbmanh9492@gmail.com)
* Following by Kiefer (1980); Wooldridge (2002, 2010)

* Version 1.1 to allow iterated GLS.
* Version 1.2 cov(h) and (fe or fd) are not specified together,
*				and correct number of iterations.
* Version 1.3 to allow combination with bootstrap command.
* Version 1.4 to speed up IGLS; allow IC and lrtest after IGLS; 
*				and fix rounding error in FEGLS and FDGLS.
* Version 1.5 to allow robust and re options.

cap program drop xtgls2
program define xtgls2, eclass
	version 11
	
	if replay() {
		if "`e(cmd)'"!="xtgls2" {
			di in red "last estimate not xtgls2"
			exit 301
		}
		else syntax [, Level(cilevel)]
	}
	else {
		syntax varlist(min=2 fv ts) [if] [in] [, ///
				NOCONstant ///
				ols fe fd re ///
				Cov(string) ///
				Robust		///
				CLuster(varname) ///			
				nmk minus(integer 0) ///
				Level(cilevel) ///
				igls ///
				ITERate(int 50) ///
				TOLerance(real 1e-7) ///
				NOLOg LOg ///
				]

		// Mark sample
		tempvar touse
		mark `touse' `if' `in'
		markout `touse' `varlist'

		// Check for xtset
		quietly xtset
		local panelvar "`r(panelvar)'"
		local timevar "`r(timevar)'"
		
		if "`panelvar'" == "" {
			display in red "Data must be xtset before using this command"
			exit 459
		}
		
		// Check for minus option
		if `minus'>0 & "`cluster'`robust'"=="" {
			di in red "{bf:minus()} and {bf:cluster()} or {bf:cluster()} must be specified together"
			exit 198
		}	
		
		//	Store panel/time variables
		tempvar ivar tvar
		qui egen long `ivar' = group(`panelvar') 	// ivar = 1 to N
		sort `ivar' `timevar'
		qui by `ivar': gen int `tvar' = _n 		// tvar = 1 to T
		qui xtset `ivar' `tvar'

		// Check for unbalnced panel
		tempvar checkbl
		qui egen `checkbl' = sum(`touse') if `touse', by(`ivar')
		qui sum `checkbl' if `touse'
		if r(min) != r(max) {
			display in red "Panels must be balanced"
			exit 459
		}		
		
		//	Get N, T
		qui xtsum `ivar'
		local N = r(n)
		local T = r(Tbar)
		
		//	Determine dependent variable
		local depvar: word 1 of `varlist'
		
		//	Collinearity
		_rmcoll `varlist', `noconstant'
		local varlist `r(varlist)'
		
		//	Factor variable and time series operator
		fvexpand `varlist'
		local varlist1_name "`r(varlist)'"
		gettoken first rest: varlist1_name
		
		local depvar_name "`first'"
		if "`fe'" != "" | "`fd'" != "" {
			local indepvar_name "`rest'"
		}
		else {
			local indepvar_name "`rest' _cons"
		}
		
		fvrevar `varlist'
		local varlist1 "`r(varlist)'"
		local varlist2
		
		//	Transform data
		*		1. ols option - Original data
		if "`fe'"=="" & "`fd'"=="" {
			local varlist2 `varlist2' `varlist1'
		}
			
		* 		2. fe option - Within tranformation
		if "`fe'" != "" {
			
			if "`cov'"=="h" {
				di in red "{bf:fe} and {bf:cov(h)} may not be specified together"
				exit 198
			}
			
			if "`fd'"!="" {
				di in red "{bf:fe} and {bf:fd} may not be specified together"
				exit 198
			}
			
			if "`noconstant'" == "" {
				di in red "{bf:fe} and {bf:noconstant} must be specified together"
				exit 198
			}
		
			sort `ivar' `tvar'
			foreach var of varlist `varlist1' {
				tempvar `var'_m `var'_dm
				qui by `ivar': egen double ``var'_m' = mean(`var') if `touse'
				qui gen ``var'_dm' double = `var' - ``var'_m' if `touse'
				local varlist2 `varlist2' ``var'_dm'
			}
		}
		
		* 		3. fd option - First difference
		if "`fd'" != "" {
			
			if "`cov'"=="h" {
				di in red "{bf:fd} and {bf:cov(h)} may not be specified together"
				exit 198
			}
			
			if "`fe'"!="" {
				di in red "{bf:fe} and {bf:fd} may not be specified together"
				exit 198
			}
			
			if "`noconstant'" == "" {
				di in red "{bf:fd} and {bf:noconstant} must be specified together"
				exit 198
			}

			foreach var of varlist `varlist1' {
				tempvar `var'_d
				qui gen double ``var'_d' = d.`var' if `touse'
				local varlist2 `varlist2' ``var'_d'
			}
			
			local gap_out : word 1 of `varlist2'
			qui replace `touse'=0 if `gap_out'==. // deal to generated missing!
		}
		
		//	Dep - Indep var
		gettoken first rest : varlist2
		
		// Covariance option
		if `"`cov'"'!=`"c"' & `"`cov'"'!=`"h"' {
			di in red "option {bf:cov()} incorrectly specified"
			exit 198
		}
		
		// RE-GLS require arbitrary covariance structure
		if `"`re'"'!=`""' & `"`cov'"'!=`"c"' {
			di in red "{bf:re} and {bf:cov(c)} must be specified together"
			exit 198
		}
		
*	//	Check for iterated GLS		********** <--- iterated GLS!
		if `iterate' < 1 {
			noi di in red `"iterate() must be positive"'
			exit 198
		}

		// Perform Gerneral GLS
		qui xtset `tvar' `ivar' 

		if "`igls'" == "" {
			qui xtgls `varlist2' if `touse', p(`cov') `noconstant' `nmk'	
		}
		else {
		*		Iterated GLS
			qui xtgls `varlist2' if `touse', p(`cov') `noconstant' `nmk' ///
				tolerance(`tolerance') iter(`iterate') `igls'			
		}
		
		if e(rc) == 430 {
			noi di in red "Convergence not achieved!"
		}
		else if "`igls'" != "" {
			di _n in ye "Convergenced achieved!"
		}
		
		*		Cluster-robust COV
		if "`robust'" != "" {
			qui xtglsr_modified, cluster(`panelvar') minus(`minus')
		}
		
		if "`cluster'" != "" & "`robust'" == "" {
			qui xtglsr_modified, cluster(`cluster') minus(`minus')
		}
		
		// Calculate R-squared
		tempvar xb xb_m xb_dm y_m y_dm
		tempname r2_o r2_w r2_b
		
		qui predict double `xb' if `touse'
		qui sort `ivar' `tvar'
		qui by `ivar': egen double `xb_m'=mean(`xb') if `touse'
		qui by `ivar': egen double `y_m'=mean(`depvar') if `touse'
		qui gen double `xb_dm' = `xb' - `xb_m' if `touse'
		qui gen double `y_dm' = `depvar' - `y_m' if `touse'
		
		*		Overall
		qui corr `depvar' `xb' if `touse'
		scalar `r2_o'=r(rho)^2
		
		*		Within
		qui corr `y_dm' `xb_dm' if `touse'
		scalar `r2_w'=r(rho)^2
		
		*		Between
		qui corr `y_m' `xb_m' if `touse'
		scalar `r2_b'=r(rho)^2
		
		qui xtset `panelvar' `timevar'
		
		// Save resuls
		*	-	Scalars
		tempname N N_ic N_g N_t n_cv df df_pear df_ic ll chi2 rank N_clust rc Sigma
					
		scalar `N'=e(N)
		scalar `N_ic'=e(N_ic)
		scalar `N_g'=e(N_t)
		scalar `N_t'=e(N_g)
		scalar `n_cv'=e(n_cv)
		scalar `df'=e(df)
		scalar `df_pear' = e(df_pear)
		scalar `df_ic' = e(df_ic)
		scalar `ll' = e(ll)
		scalar `chi2'=e(chi2)
		scalar `rank'=e(rank)
		scalar `N_clust'=e(N_clust)
		scalar `rc'=e(rc)
		
		*	-	Matrixs
		tempname b V Sigma
		mat `b'=e(b)
		mat `V'=e(V)
		mat `Sigma'=e(Sigma)
		
		mat coln `b' = `indepvar_name'
		mat coln `V' = `indepvar_name'
		mat rown `V' = `indepvar_name'
		
		*	Post results
		ereturn clear
		ereturn post `b' `V', e(`touse') dep(`depvar_name')
		
		// Store in e()
		*	-	Matrix
		ereturn mat Sigma=`Sigma'
		
		*	-	Scalar
		ereturn scalar N=`N'
		ereturn scalar N_ic=`N_ic'
		ereturn scalar N_g=`N_g'
		ereturn scalar N_t=`N_t'
		ereturn scalar n_cv=`n_cv'
		ereturn scalar df=`df'
		ereturn scalar df_pear = `df_pear'
		ereturn scalar df_ic = `df_ic'
		ereturn scalar ll = `ll'
		ereturn scalar chi2=`chi2'
		ereturn scalar rank=`rank'
		ereturn scalar level = `level'
		ereturn	scalar r2_o = `r2_o'
		ereturn scalar r2_w = `r2_w'
		ereturn scalar r2_b = `r2_b'
		ereturn scalar rc = `rc'
		
		*	-	Macros	
		ereturn local cmd "xtgls2"		
		ereturn local cmdline "xtgls2 `0'"
		ereturn local depvar "`depvar_name'"
		ereturn local ivar "`panelvar'"
		ereturn local tvar "`timevar'"
		
		if "`fe'"=="" & "`fd'"=="" & "`re'"=="" {
			ereturn local model "ols"
		}
		
		else {
			if "`fe'"!="" {
				ereturn local model "fe"
			}
			else if "`fd'"!="" ereturn local model "fd"
			else ereturn local model "re"
		}

		if "`robust'" != "" {
			ereturn scalar N_clust=`N_clust'
			ereturn local vcetype "Robust"
			ereturn local clustvar "`panelvar'"
		}
		
		if "`cluster'" != "" & "`robust'" == "" {
			ereturn scalar N_clust=`N_clust'
			ereturn local vcetype "Robust"
			ereturn local clustvar "`cluster'"
		}
		
	
	}		// End of reply else command
	
	// Display results
	if "`e(model)'"=="ols" {
		local model_ "Pooled"
		local model_sf "PGLS"
	} 
	
	if "`e(model)'"=="fe" {
		local model_ "Fixed-effects"
		local model_sf "FEGLS"
	} 
	
	if "`e(model)'"=="fd" {
		local model_ "First-difference"
		local model_sf "FDGLS"
	}
	
	if "`e(model)'"=="re" {
		local model_ "Random-effects"
		local model_sf "REGLS"
	}	
	
	local h "Heteroskedasticity"
	if "`cov'" == "c" local c `"and serial correlation"'
	else local c `""'	
	
	if e(chi2) > 999999 {
		local cfmt `"%10.0g"'
	}
	else	local cfmt `"%10.3f"'	
	
	di
	di in gr "`model_' Generalized Least Squares (`model_sf') regression" _n
	di in gr "Error covariance structure"
	di in gr _col(6) "Time series:" in ye _col(23) "`h' `c'"
	di in gr _col(6) "Cross-section:" in ye _col(23) "Homoskedasticity (assumed)"
	di
	di in gr "Estimated covariances:"   ///
		in ye _col(25) %3.0fc e(n_cv) ///
		in gr _col(49) `"Number of obs"' _col(67) `"= "' in ye %10.0fc e(N)
		
	di in gr "R-squared:"	///
		in gr _col(49) `"Number of groups"' _col(67) `"= "' in ye %10.0fc e(N_g)
		
	di in gr _col(6) "Within" _col(15) "= " in ye %7.4f e(r2_w) ///
		in gr _col(49) `"Time periods"' _col(67) "= " in ye %10.0fc e(N_t)
		
	di in gr _col(6) "Between" _col(15) "= " in ye %7.4f e(r2_b) ///
		in gr _col(49) `"Wald chi2("' in ye e(df) in gr `")"' ///
		in gr _col(67) `"= "' in ye `cfmt' e(chi2)
		
	di in gr _col(6) "Overall" _col(15) "= " in ye %7.4f e(r2_o) ///
		in gr _col(49) `"Prob > chi2"' _col(67) `"= "' ///
		in ye %10.4f chiprob(e(df), e(chi2))
	di
	
	ereturn display, l(`level') /*noomitted*/ noemptycells
	qui xtset `panelvar' `timevar'
end


*	Define xtglsr_modified command
*		Modified from xtglsr command (Kolev, 2013)
*			to allowing time series operator and cluster-robust in this case.

cap program drop xtglsr_modified
program define xtglsr_modified
        version 11
		preserve 
        syntax [, CLUSTER(varname) MINUS(integer 0)]
		
		if "`e(cmd)'" != "xtgls" {
		display as error "Can be used only after xtgls"
        error 301
		}
		
	qui xtset
	local panelis `r(panelvar)'
	local timeis `r(timevar)'
			if "`r(panelvar)'"=="" | "`r(timevar)'"=="" {
			display as error "You need to xtset your data, and specify both panel and time identifiers"
			error 459
			}
		
	if !missing("`cluster'") qui drop if missing(`cluster')

	tempname residual InvSigma weightedresidual
	tempfile thedata	 

	quietly {
	`e(cmdline)'
	mat `InvSigma' = invsym(e(Sigma))
	egen Individual_Observations = group(`timeis' `panelis') if e(sample)
		
	* Generate the residuals
	predict double `residual' if e(sample), xb
* !!! Modified for cluster-robust SE in FDGLS model!	
	replace `residual' = `e(depvar)' - `residual' if e(sample) 

	* Generate the weighted residual

	save `thedata', replace
	keep if e(sample)
	keep `residual' `panelis' `timeis'
	levelsof `panelis', local(levelspanelis)

	* We reshape the data to wide. matrix score operates on variables.
	reshape wide `residual', i(`timeis') j(`panelis')
	ds `timeis', not 
	local theresiduals `r(varlist)'
	mat colnames `InvSigma' = `theresiduals'
	
	forvalues i = 1/`=rowsof(`InvSigma')' {
		matrix tempvec = `InvSigma'[`i',1...]   
		matrix score `weightedresidual'`: word `i' of `levelspanelis''= tempvec 
	}
	drop `theresiduals' 

	reshape long `weightedresidual', i(`timeis') j(`panelis')

	merge 1:1 `timeis' `panelis' using `thedata', nogenerate

	* We call _robust.
* !!! Modified for using time series operator!	
	sort `panelis' `timeis'
	if "`cluster'" != "" {
		_robust `weightedresidual', minus(`minus') cluster(`cluster')
	}
	else {
		if e(vt) == "heteroskedastic with cross-sectional correlation" {
			_robust `weightedresidual', minus(`minus') cluster(`timeis')
		}
		else {
			_robust `weightedresidual', minus(`minus') ///
				cluster(Individual_Observations)
		} 
	}

	} 	// end of qui

	xtgls,

end


