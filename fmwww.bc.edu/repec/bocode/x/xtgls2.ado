* Version 1.4 in 30 Sep 2025, Manh Hoang Ba (hbmanh9492@gmail.com)
* Following by Kiefer (1980); Wooldridge (2002, 2010)
* Version 1.1 to allow iterated GLS.
* Version 1.2 cov(h) and (fe or fd) are not specified together,
*				and correct number of iterations.
* Version 1.3 to allow combination with bootstrap command.
* Version 1.4 to speed up IGLS; allow IC and lrtest after IGLS; 
*				and fix rounding error in FEGLS and FDGLS

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
		syntax varlist(min=1 fv ts) [if] [in] [, ///
				NOCONstant ///
				ols fe fd ///
				Cov(string) ///
				CLuster(varname) ///			
				nmk minus(integer 0) ///
				Level(cilevel) ///
				igls ///
				ITERate(int 300) ///
				TOLerance(real 1e-7) ///
				NOLOg LOg ///
				]
				
		// Mark sample
		tempvar touse
		mark `touse' `if' `in'
		markout `touse' `varlist'

		// Check for xtset 
		quietly xtset
		if "`r(panelvar)'" == "" {
			display in red "Data must be xtset before using this command"
			exit 459
		}
		
		// Check for unbalnced panel
		if "`r(balanced)'" == "unbalanced" {
			display in red "Panels must be balanced" 
		}
		
		// Check for minus option
		if `minus'>0 & "`cluster'"=="" {
			di in red "{bf:minus()} and {bf:cluster()} must be specified together"
			exit 198
		}
			
		//	Store panel/time variables
		local ivar "`r(panelvar)'"
		local tvar "`r(timevar)'"
			
		//	Determine dependent variable
		local depvar: word 1 of `varlist'
		
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
			sort `ivar' `tvar'
			foreach var of varlist `varlist1' {
				tempvar `var'_d
				qui gen double ``var'_d' = d.`var' if `touse'
				local varlist2 `varlist2' ``var'_d'
			}
			local gap_out : word 1 of `varlist2'
			qui replace `touse'=0 if `gap_out'==. // deal to generated missing!
		}
		
		// Covariance option
		if `"`cov'"'!=`"c"' & `"`cov'"'!=`"h"' {
			di in red "option {bf:cov()} incorrectly specified"
			exit 198
		}
	
		// Perform Gerneral GLS
		qui xtset `tvar' `ivar'
		
		*		(Iterated) GLS
		_xtgls275 `varlist2' if `touse', p(`cov') `noconstant' `nmk' ///
					tolerance(`tolerance') iter(`iterate') `igls'
		
		*		Cluster-robust COV
		if "`cluster'" != "" {
			qui xtglsr_modified, cluster(`cluster') minus(`minus')
		}

		qui xtset `ivar' `tvar' 
		
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
		
		// Save resuls
		*	-	Scalars
		tempname N N_g N_t n_cv df df_pear df_ic ll chi2 rank N_clust Sigma
					
		scalar `N'=e(N)
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
		
		*	-	Matrixs
		tempname b V Sigma
		mat `b'=e(b)
		mat `V'=e(V)
		mat `Sigma'=e(Sigma)
		
		mat coln `b' = `indepvar_name'
		mat coln `V' = `indepvar_name'
		mat rown `V' = `indepvar_name'
			
		*	Post results
		ereturn post `b' `V', esample(`touse') depname(`depvar_name')
		
		// Store in e()
		*	-	Matrix
		ereturn mat Sigma=`Sigma'
		
		*	-	Scalar
		ereturn scalar N=`N'
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
		
		*	-	Macros	
		ereturn local cmd "xtgls2"		
		ereturn local cmdline "xtgls2 `0'"
		ereturn local depvar "`depvar_name'"
		ereturn local ivar "`ivar'"
		ereturn local tvar "`tvar'" 
		
		if "`fe'"=="" & "`fd'"=="" {
			ereturn local model "ols"
		}
		
		else {
			if "`fe'"!="" {
				ereturn local model "fe"
			}
			else ereturn local model "fd"
		}
		
		if "`cluster'" != "" {
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
	else if "`e(model)'"=="fe" {
		local model_ "Fixed-effects"
		local model_sf "FEGLS"
	} 
	else {
		local model_ "First-difference"
		local model_sf "FDGLS"
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
	
end


*************************************************************************
*	Define xtglsr_modified command
*		Modified from xtglsr command (Kolev, 2013)
*			to allowing time series operator and cluster-robust in this case.
*************************************************************************

cap program drop xtglsr_modified
program define xtglsr_modified
        version 11
		preserve 
        syntax [, CLUSTER(varname) MINUS(integer 0)]

/*		
		if "`e(cmd)'" != "xtgls" {
		display as error "Can be used only after xtgls"
        error 301
		}
*/		
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

*	_xtgls275,

end


***************************************************************************
*!	Modify from xtgls version 2.7.5  09dec2024
***************************************************************************

cap program drop _xtgls275
program define _xtgls275, eclass byable(onecall) prop(xt xtbs)
	if replay() {
		if _by() {
			error 190
		}
                if `"`e(cmd)'"'!=`"_xtgls275"' {
                        error 301
                }
		DispRes `0'
		exit
	}
	if _by() {
		local by "by `_byvars'`_byrc0':"
	}
	capture noi `by' Estimate `0'
	nobreak {
		mac drop X_*
	}
	version 10: ereturn local cmdline `"_xtgls275 `0'"'
	exit _rc
end


cap program drop Estimate
program define Estimate, eclass byable(recall)
	version 7.0, missing
	mac drop X_*
	syntax varlist(fv ts) [if] [in] [aw] [, /*
		*/ noCONstant Corr(string) FORCE I(varname) 		/*
		*/ ITERate(int `c(maxiter)') Level(cilevel) IGLS 	/*
		*/ NMK OLS Panels(string) PCSE T(varname) NOLOg LOg	/*
		*/ TOLerance(real 1e-7) RHOtype(string) FORCEPCSE *]

	_get_diopts diopts, `options'
	local fvops = "`s(fvops)'" == "true" | _caller() >= 11
	if `fvops' {
		local vv : display "version " ///
			string(max(11,_caller())) ", missing:"
	}

	if `fvops' {
		fvunab varlist : `varlist'
	}
	else {
		tsunab varlist : `varlist'
	}
	local tol "`tolerance'"
	local toleran

	// New behavior for rhotype 
	
	local corrnuevo = 0
	local rhonuevo  = 1
	if (substr("independent", 1, strlen("`corr'"))=="`corr'") {
		local corrnuevo = 1
	}
	if (inlist("`rhotype'", "")) {
		local rhonuevo = 0
	}
	if (_caller() >= 16 & `rhonuevo' & `corrnuevo') {
		di as err ///
		"{bf:rhotype()} not allowed with default {bf:corr(independent)}"
		di as err "{p 2 2 2}" 
                di as smcl as err "{bf:corr(independent)} means" 
                di as smcl as err " there is no autocorrelation parameter"
		di as smcl as err " to be estimated."
                di as smcl as err "{p_end}"
		exit 198
	}
 
	local rr = cond("`rhotype'"=="", "regress", "`rhotype'")
	global X_rcalc "`rr'"
	global X_nocons `constant'

	if `iterate' < 1 {
		noi di in red `"iterate() must be positive"'
		exit 198
	}

	_parse_iterlog, `log' `nolog'
	local log "`s(nolog)'"
	local qqq = cond("`log'"!="", "quietly", "noisily")
	gettoken depvar varlist: varlist
	_fv_check_depvar `depvar'

	local fvops = "`s(fvops)'" == "true" | _caller() >= 11
	if `fvops' {
		local rmcoll "version 11: _rmcoll"
		local fvexp expand
	}
	else	local rmcoll _rmcoll
	qui `rmcoll' `varlist' [`weight'`exp'] `if' `in', `constant' `fvexp'
	local varlist `r(varlist)'
	global X_indv1 `varlist' 
	local kk : word count `varlist'
	global X_rhok "k(`kk')"

	if "`constant'" == "" {
		local varname `varlist' _cons
	}
	else {
		local varname `varlist'
	}
	local varlist `depvar' `varlist'
	global X_depv2 "`depvar'"

	local origdep "`depvar'"
	tsunab origdep : `origdep'
	local origdep : subinstr local origdep "." "_"
	tsrevar `depvar'
	local depvar "`r(varlist)'"
	if `fvops' {
		fvrevar `varlist'
	}
	else {
		tsrevar `varlist'
	}
	local varlist "`r(varlist)'"

	if "`weight'" != "" {
		tempvar www
		qui gen double `www' `exp'

		summ `www', meanonly
		qui replace `www' = `www'/r(mean)

		local j = 1
		foreach var of varlist `varlist' {
			tempvar var`j'
			qui gen double `var`j'' = `var'*sqrt(`www')
			local varli1 `varli1' `var`j''
					/* replace the first occurrence only */
			local j = `j'+1
		}
		if "`constant'"=="" {
			tempvar cons
			qui gen double `cons' = sqrt(`www')
			local varli1 `varli1' `cons'
			local constant "noconstant"
			local consopt "noconstant"
		}
		local varlist `varli1'
		qui replace `www'=1

		local fixname 1

		global X_wtype "aweight"
		global X_wexp  "`exp'"
		global X_wt `"[aweight=`www']"'
		global X_wtexp `"[aweight`exp']"'
		global X_wtvar `"`www'"'
	}
	else    global X_wt

	if `"`pcse'"' != "" {
		local ols `"ols"'
	}

	global X_if `"`if'"'
	global X_in `"`in'"'

	MapCorr `corr'
	local corr $S_1
	MapPanel `panels'
	local var $S_1
	local panels
	global S_1

/*	
	getPCSE `"`0'"' "`pcse'" "`ols'" "`forcepcse'" `var' 	/*
		*/ "`igls'" "`t'" "`i'"
	if "`r(done)'" == "1" { exit }
*/
	if `"`corr'"' != `"0"' | "`constant'" != "" {
		if "`constant'" == "" & "`weight'" == "" {
			tempvar cons
			gen byte `cons' = 1
			global X_cons `"`cons'"'
			local fixname 1
		}
		local copt "nocons"
		global X_cot "nocons"
	}

	global X_bal = (`var'==2)

	if `corr' > 0 | `var' == 2 {
		_xt, i(`i') t(`t') trequired
		global X_tvar `"`r(tvar)'"'
	}
	else {
		_xt, i(`i')
	}
	global X_ivar `"`r(ivar)'"'
	
	tokenize `varlist'
	global X_depv `"`1'"'
	mac shift
	global X_indv `"`*'"'

	quietly {
		tempvar touse
		mark `touse' $X_if $X_in
		markout `touse' $X_depv $X_indv $X_ivar $X_tvar
		if `"`www'"' != "" {
			replace `touse' = 0 if `www'<= 0
		}

		local nnobs = _N
		if `"`corr'"' != `"0"' {
			local sortlist : sort
			sort $X_ivar $X_tvar
			by $X_ivar : replace `touse'=0 if _N==1
			count if `touse'==0
			local drop = r(N)
			if `drop'>0 {
				if (`drop'>1) {
					local s s
				}
				noi di in blue `"(note: "' in ye `drop' /*
				*/ in blue `" observation`s' "'	 ///
				`"dropped"' /*
				*/ `" because only 1 obs in group)"'
			}
			sort `sortlist'
		}

		preserve
		keep if `touse'

		tempvar ii
		egen `ii' = group($X_ivar)
		compress `ii'
		global X_itemp `"`ii'"'
		sort $X_itemp $X_tvar		/* sic, X_tvar may be blank */

		if "`force'" != "" | `"$X_tvar"' != `""' {
			tempvar tt
			if "`force'" == "" {
				egen `tt' = group($X_tvar)
				compress `tt'
			}
			else	qui by $X_itemp : gen `tt' = _n

			global X_ttemp `"`tt'"'
		}

		sort $X_itemp $X_ttemp
		if `corr' > 0 | `var' == 2 {
			global X_t_delta 1
			// Get the real delta before this re-tsset
			if `"`:char _dta[_TSdelta]'"' != "" {
				global X_t_delta  `=`:char _dta[_TSdelta]''
			}
			qui tsset $X_itemp $X_ttemp , noquery
			global X_ttmp
			tempname ttt
			capture _crcar1 `ttt' opt : $X_itemp , check 	/*
				*/ $X_rcalc $X_rhok
			if _rc {
				local arg $X_rcalc
				di in red "rhotype(`arg') : argument is invalid"
				exit 198
			}
		}
		else if "$X_ttemp" == "" {
			tempvar tvar
			quietly by $X_itemp : gen `tvar' = _n
			quietly compress `tvar'
			global X_tvar `"`tvar'"'
			global X_ttmp 1
			global X_ttemp $X_tvar
			sort $X_itemp $X_ttemp
		}

		if `corr' > 0 & "`force'" == "" {
			checkt $X_tvar `touse'
			if $S_1==2 {
				noi di in red /*
				*/ `"$X_tvar has duplicate values within panel"'
				exit 459
			}
			if $S_1==1 & `"`force'"' == `""' {
				noi di in red /*
*/ `"$X_tvar is not regularly spaced or does not have intervals of delta -- use "'
				no di in red "the force option to treat the"  /*
				*/ " intervals as though they were regular"
				exit 459
			}
		}

		ChkBal
		if $S_1 == 1 {
			noi di in red `"panels must be balanced"'
			exit 459
		}
		if $S_1 == 2 {
			noi di in red /*
				*/ `"$X_tvar has duplicate values within panel"'
			exit 459
		}
		if $S_1 == 3 {
			noi di in red /*
				*/ "$X_tvar has different values across panels"
			exit 459
		}

		GetNKT
		if $X_ng == 1 & `var'==2 {
			local var = 1
		}
		if $X_nt < 2 & `corr' > 0 {
			local corr 0
		}

		tempname sigmat
		mat `sigmat' = J(1,$X_ng,0)
		global X_sig `"`sigmat'"'

		tempname E Ei
		tempname xEx xEix xEiy xxi xty beta vce pcvce bold
		tempname ovce obeta

		global X_Emat `"`E'"'
		global X_beta `"`beta'"'

		local diff = `tol'+1
		local iter = 0

		if `var' < 2 {
			tempvar ee
			gen double `ee' = .
			global X_ee `"`ee'"'
		}
		else {
			gen double _ee = .
			global X_ee `"_ee"'
		}


		while `iter' < `iterate' & `diff' > `tol' {

			if `"`igls'"' == `""' {
				local diff = 0
			}

			`vv' ///
			mc`corr' `iter'
			mv`var'

			if `iter' == 0 {
				mat $X_sig = $X_Emat
			}

			mat `Ei' = syminv(`E')

			sort $X_ttemp $X_itemp

			mat glsaccum `xEx' = $X_indv /*
				*/ $X_cons $X_wt, `copt' /*
				*/ glsmat(`E') row($X_itemp) /*
				*/ group($X_ttemp)

			mat glsaccum `xEix' = $X_depv /*
				*/ $X_indv /*
				*/ $X_cons $X_wt, `copt' /*
				*/ glsmat(`Ei') /*
				*/ row($X_itemp) /*
				*/ group($X_ttemp)

			local s = rowsof(`xEix')
			mat `xEiy' = `xEix'[2..`s',1]
			mat `xEix' = `xEix'[2..`s',2..`s']

			global X_ecoe = `s' - 1

			mat accum `xxi' = $X_indv $X_cons $X_wt, `copt'
			mat `xxi' = syminv(`xxi')

			mat vecaccum `xty' = $X_depv $X_indv /*
				*/ $X_cons $X_wt, `copt'

			local nobs = r(N)
			local p = rowsof(`xxi')

			mat `vce' = syminv(`xEix')
			mat `beta' = (`vce' * `xEiy')'

			if `iter' == 0 {
				mat `bold' = `beta'
			}
			else {
				local diff = mreldif(`beta',`bold')
				mat `bold' = `beta'
				if `iter' < 10 {
					local space " "
				}
				else {
					local space
				}
				if `iter' == 1 {
					`qqq' di
				}
				`qqq' di in gr "Iteration " `iter' /*
				*/ ":`space' Tolerance = " in ye `diff'
			}
			local iter = `iter' + 1
		}
		if `diff' > `tol' {
			noi di in red "convergence not achieved"
			global X_rc 430
		}
		else	global X_rc 0

		`vv' ///
		mc`corr' `iter'

		mat `pcvce' = `vce'
		mat `ovce' = `xxi'*`xEx'*`xxi'
		mat `obeta' = `xty'*`xxi'

		if `"`ols'"' != `""' {
			mat `beta' = `obeta'
			mat `vce' = `ovce'
			global X_tle `"ordinary least squares"'
		}
		else {
			global X_tle `"generalized least squares"'
		}

		tempvar ehat
		mat score double `ehat' = `beta'
		replace `ehat' = $X_depv - `ehat'
		if (`corr' == 0 & "`igls'" != "") | 	/*
		*/ (`corr' == 0 & `var' == 0) {
			calcll `var' `ehat'
		}
		if `"`nmk'"' != `""' {
			tempname s1
			local k = colsof(`beta') - diag0cnt(`vce')
			scalar `s1' = `nobs'/(`nobs'-`k')
			mat `vce' = `vce'*`s1'
		}

		local rho  `"$rho"'

/*
		if `"`fixname'"' != `""' {
			local bnam : colsname(`beta')
			local nnam : word count `bnam'
			tokenize `"`bnam'"'
			local `nnam' `"_cons"'
			local bnam `"`*'"'
*/
			local bnam `varname'

			version 11: mat colnames `beta' = `bnam'
			version 11: mat colnames `vce' = `bnam'
			version 11: mat rownames `vce' = `bnam'
			version 11: mat colnames `pcvce' = `bnam'
			version 11: mat rownames `pcvce' = `bnam'
/*
		}
*/

		global X_miss = `nnobs' - $X_nobs

		if `var' == 0 {
			global X_ecov = 1
		}
		else if `var' == 1 {
			global X_ecov = $X_ng
		}
		else    global X_ecov = $X_ng * ($X_ng + 1) / 2

		global X_ecor : word count $X_rho
		local df = $X_nobs - $X_ecoe - $X_ecov - $X_ecor
		est post `beta' `vce', obs(`nobs') depname("`origdep'") /*
			*/ `dfopt'
		_post_vce_rank

		local bp = e(rank)
		global X_ncf = e(rank) 
		if `"`ols'"'!=`""' { est local vcetype "Panel-corrected" }
		global S_E_vce `"`e(vcetype)'"'     /* double save */

		if `corr' == 0 & "`igls'" != "" {
			est scalar N_ic = `nobs'
			if `"$X_var"' == "homoskedastic" {
				local dfic = 1
			}
			else if `"$X_var"' == "heteroskedastic" {
				local dfic = $X_ng
			}
			else {			// hetero & cross-sect corr.
				local dfic = $X_ng * ($X_ng + 1) / 2
			}
			local dfic = `dfic' + `bp'
			est scalar df_ic = `dfic'
		}
		SetGlob
		restore
		est repost [`weight'`exp'], esample(`touse') buildfvinfo

	}
	if "`opt'" != "" { est local rhotype "`opt'" }

	est local chi2type "Wald"
	est local predict "xtgls_p"
*	est hidden local footnote "xtgls_footnote"
	est local cmd "_xtgls275"
*	noi DispRes, level(`level') `diopts'
end

/*
program define DispRes
	version 7.0, missing
	syntax [, Level(cilevel) *]

	_get_diopts diopts, `options'
	di _n in gr `"`e(title)'"' _n
	di in gr `"Coefficients:  "' in ye `"`e(coefftype)'"'
	di in gr `"Panels:	  "' in ye `"`e(vt)"'
	local nc : word count `e(rho)'
	if `nc' == 1 {
		local myrho : di %9.4f `e(rho)'
		di in gr `"Correlation:   "' in ye `"`e(corr)'"' in gr /*
		*/ `"  ("' in ye trim(`"`myrho'"') in gr `")"'
	}
	else {
		di in gr `"Correlation:   "' in ye `"`e(corr)'"'
	}
	di

	di in gr `"Estimated covariances"' _col(28) `"= "'  /*
	*/ in ye %9.0g e(n_cv) /*
	*/ in gr _col(49) `"Number of obs"' _col(67) `"= "' in ye %10.0fc e(N)

	di in gr `"Estimated autocorrelations"' _col(28) `"= "'  in ye /*
	*/ %9.0g e(n_cr) /*
	*/ in gr _col(49) `"Number of groups"' _col(67) `"= "'in ye %10.0fc e(N_g)

	if e(g_min) == e(g_max) {
		di in gr `"Estimated coefficients"' _col(28) `"= "' /*
		*/ in ye %9.0g e(n_cf) /*
		*/ in gr _col(49) `"Time periods"' /*
		*/ _col(67) `"=  "' in ye %9.0g e(N_t)
	}
	else {
		di in gr `"Estimated coefficients"' _col(28) `"= "' /*
		*/ in ye %9.0g e(n_cf) /*
		*/ in gr _col(49) `"Obs per group:"'
		di in gr _col(63) "min" _col(67) "= " in ye %10.0fc e(g_min)
		di in gr _col(63) "avg" _col(67) "=  " in ye %9.0gc e(g_avg)
		di in gr _col(63) "max" _col(67) "= " in ye %10.0fc e(g_max)
	}

	if e(chi2) > 999999 {
		local cfmt `"%9.0g"'
	}
	else	local cfmt `"%9.2f"'

	di /*
	*/ in gr _col(49) `"Wald chi2("' in ye e(df) in gr `")"' /*
	*/ in gr _col(67) `"=  "' in ye `cfmt' e(chi2)

	if "`e(ll)'" != "" {
		di in gr /*
		*/ `"Log likelihood"' _col(28) `"= "'  in ye %9.0g e(ll) _c
	}
	di in gr _col(49) `"Prob > chi2"' _col(67) `"= "' in ye /*
	*/ %10.4f chiprob(e(df), e(chi2))

	di

	_coef_table, level(`level') `diopts'
	
	if "`e(footnote)'" != "" {
		xtgls_footnote
	}

end
*/

cap program drop SetGlob
program define SetGlob, eclass

	est local title "Cross-sectional time-series FGLS regression"
	est local coefftype `"$X_tle"'
	est local rhotype `"$X_rcalc"'
	capture est scalar rc = $X_rc
	est scalar N = $X_nobs
	est scalar N_g = $X_ng
	est scalar N_t = $X_nt
	est hidden scalar PC  = $X_bal
	if "$X_ntavg" != "" {
		est scalar g_min = $X_ntmin
		est scalar g_avg = $X_ntavg
		est scalar g_max = $X_ntmax
	}
	est local depvar `"$X_depv2"'
	est local ivar `"$X_ivar"'
	if `"$X_ttmp"' == `""' {
		est local tvar `"$X_tvar"'
	}
	est local rho `"$X_rho"'
	est scalar n_cf = $X_ncf
	est scalar n_cv = $X_ecov
	local nrho : word count $X_rho
	est scalar n_cr = `nrho'
	est scalar df_pear =  e(N) - e(n_cv) - e(n_cr) - e(n_cf)
	est scalar N_miss = $X_miss

	est local vt `"$X_var"'
	est local corr `"$X_corr"'
	if `"$X_ll"' != "" {
		est scalar ll =  $X_ll
	}
	*est local wt `"$X_wtexp"'
	est local wtype "$X_wtype"
	est local wexp  "$X_wexp"
	if `"$X_indv1"' != `""' {
		qui test $X_indv1, min
		est scalar df = r(df)
		est scalar chi2 = r(chi2)
	}
	else {
		est scalar df = 0
		est scalar chi2 = .
	}


	if _caller()<6 {
		mat S_E_om = $X_Emat
	}
	est mat Sigma $X_Emat

	/* double saves below here */

	global S_E_tle "`e(title)'"
	global X_tle
	global S_E_nobs e(N)
	global S_E_ng e(N_g)
	global S_E_nt e(N_t)
	global S_E_depv `"`e(depvar)'"'
	global S_E_ivar `"`e(ivar)'"'
	global S_E_tvar `"`e(tvar)'"'
	global S_E_if `"$X_if"'
	global S_E_in `"$X_in"'
	global S_E_rho `"`e(rho)'"'
	global S_E_ncf  e(n_cf)
	global S_E_ncv  e(n_cv)
	global S_E_ncr e(n_cr)
	global S_E_pdf e(df_pear)
	global S_E_mis  e(N_miss)
	global S_E_vt `"`e(vt)'"'
	global S_E_ct `"`e(corr)'"'
	global S_E_ll  e(ll)
	global S_E_wt `"`e(wt)'"'
	global S_E_mdf = e(df)
	global S_E_chi2 = e(chi2)

	global S_E_cmd "xtgls"
end

cap program drop mv0
program define mv0
	quietly {
		mat $X_Emat = J($X_ng,$X_ng,0)
		replace $X_ee = $X_ee * $X_ee
		summ $X_ee $X_wt
		local res = r(mean)
		global S_1 = $X_ng * log(r(mean))
		local i 1
		while `i' <= $X_ng {
			mat $X_Emat[`i',`i'] = `res'
			local i = `i'+1
		}
		global X_var `"homoskedastic"'
	}
end

cap program drop mv1
program define mv1
	quietly {
		mat $X_Emat = J($X_ng,$X_ng,0)
		replace $X_ee = $X_ee * $X_ee
		global S_1 = 0.0
		local i 1
		while `i' <= $X_ng {
			summ $X_ee if $X_itemp == `i' $X_wt
			mat $X_Emat[`i',`i'] = r(mean)
			global S_1 = $S_1 + log(r(mean))
			local i = `i'+1
		}
		global X_var `"heteroskedastic"'
	}
end

cap program drop mv2
program define mv2
	quietly {
		tempfile svme
		save "`svme'"
		sort $X_itemp $X_ttemp
		replace $X_ee = $X_ee / sqrt($X_nt)
		keep $X_ee $X_itemp $X_ttemp

		local i $X_ng
		while `i' >= 2 {
			local b0 = (`i'-1)*$X_nt
			gen double ${X_ee}`i' = $X_ee[`b0'+_n] in 1/$X_nt
			local b0 = `b0' + 1
			drop in `b0'/l
			local i = `i' - 1
		}
		local elist `"$X_ee"'
		local i 2
		while `i' <= $X_ng {
			local elist `"`elist' ${X_ee}`i'"'
			local i = `i' + 1
		}

		mat accum $X_Emat = `elist', nocons
		global S_1 = 0.0
		local p 1
		while `p' <= $X_ng {
			global S_1 = $S_1 + log($X_Emat[`p',`p']/2)
			local p = `p'+1
		}
		use "`svme'", clear
		global X_var /*
		*/ `"heteroskedastic with cross-sectional correlation"'
	}
end

cap program drop mc0
program define mc0
	local vv : display "version " string(_caller()) ", missing:"
	version 7.0, missing
	local flag `1'

	if `flag' == 0 {
		capture drop $X_ee
		`vv' ///
		_regress $X_depv $X_indv $X_cons $X_wt, $X_cot
		predict double $X_ee, resid
		global X_corr `"no autocorrelation"'
	}
	else {
		capture drop $X_ee
		mat score double $X_ee = $X_beta
		replace $X_ee = $X_depv - $X_ee
	}
end

cap program drop mc1
program define mc1
	local vv : display "version " string(_caller()) ", missing:"
	version 7.0, missing
	local flag `1'

	if `flag' == 0 {
		tempvar mm v1 q

		gen byte `mm' = 0
		gen double `v1' = .
		sort $X_itemp $X_ttemp
		by $X_itemp : replace `mm' = 1 if _n==1
		`vv' ///
		_regress $X_depv $X_indv $X_cons $X_wt, nocons
		capture drop $X_ee
		predict double $X_ee, resid

		tempname ttt
		local nn = 0
		local rho = 0
		local i 1
		while `i' <= $X_ng {
			_crcar1 `ttt' opt : $X_ee if $X_itemp==`i', /*
				*/ $X_rcalc $X_rhok
			if `ttt' <. {
				count if $X_itemp == `i'
				local rho = `rho'+ `ttt'*r(N)
				local nn = `nn'+r(N)
			}
			local i = `i'+1
		}
		global X_rho = `rho'/`nn'

		recast double $X_depv $X_indv $X_cons
		gen double `q' = .
		local rho = $X_rho
		local i 1
		while `i' <= $X_ng {
			tokenize `"$X_depv $X_indv $X_cons"'
			local j 1
			while `"``j''"' != `""' {
				replace `q' = ``j'' - `rho' * ``j''[_n-1] /*
					*/ if `mm'==0 & $X_itemp==`i'
				replace `q' = sqrt(1-`rho'*`rho') * ``j'' /*
					*/ if `mm'==1 & $X_itemp == `i'
				replace ``j'' = `q' if $X_itemp==`i'
				local j = `j'+1
			}
			local i = `i'+1
		}
		drop `q' `mm'
		capture drop $X_ee
		`vv' ///
		_regress $X_depv $X_indv $X_cons $X_wt, nocons
		predict double $X_ee, resid
		global X_corr `"common AR(1) coefficient for all panels"'
	}
	else {
		capture drop $X_ee
		mat score double $X_ee = $X_beta
		replace $X_ee = $X_depv - $X_ee
	}
end

cap program drop mc2
program define mc2
	local vv : display "version " string(_caller()) ", missing:"
	version 7.0, missing
	local flag `1'

	if `flag' == 0 {
		tempvar mm v1 q

		gen byte `mm' = 0
		gen double `v1' = .
		sort $X_itemp $X_ttemp
		qui by $X_itemp : replace `mm' = 1 if _n==1
		`vv' ///
		_regress $X_depv $X_indv $X_cons $X_wt, nocons
		capture drop $X_ee
		predict double $X_ee, resid

		recast double $X_depv $X_indv $X_cons
		tempname ttt
		gen double `q' = .
		global X_rho `""'
		local i 1
		while `i' <= $X_ng {
			_crcar1 `ttt' opt : $X_ee if $X_itemp == `i', /*
				*/ $X_rcalc $X_rhok
			if `ttt' >=. {
				qui sum $X_ivar if $X_itemp == `i' , meanonly
				di in red "rho_i could not be computed " /*
					*/ "for panel $X_ivar=" r(mean)  /*
					*/ " using rhotype method $X_rcalc"
				exit 459
			}
			local rho = `ttt'
			global X_rho `"$X_rho `rho'"'

			tokenize `"$X_depv $X_indv $X_cons"'
			local k 1
			while `"``k''"' != `""' {
				qui replace `q' = ``k'' - `rho' * /*
					*/ ``k''[_n-1] /*
					*/ if `mm'==0 & $X_itemp==`i'
				qui replace `q' = sqrt(1-`rho'*`rho') * /*
					*/ ``k'' /*
					*/ if `mm'==1 & $X_itemp == `i'
			 	qui replace ``k'' = `q' if $X_itemp==`i'
				local k = `k'+1
			}

			local i = `i'+1
		}
		capture drop $X_ee
		`vv' ///
		_regress $X_depv $X_indv $X_cons $X_wt, nocons
		predict double $X_ee, resid
		global X_corr `"panel-specific AR(1)"'
	}
	else {
		capture drop $X_ee
		mat score double $X_ee = $X_beta
		qui replace $X_ee = $X_depv - $X_ee
	}
end
*/

cap program drop ChkBal
program define ChkBal
	global S_1 = 0
	if $X_bal == 0 {
		exit
	}

	/* Check for balanced panels */

	global S_1 0
	tempvar use
	mark `use'
	markout `use' $X_depv $X_indv $X_ivar $X_tvar
	*replace `use' = `use' * $X_ttemp
	tempvar test
	egen `test' = sum(`use'), by($X_itemp)
	summ `test'
	if r(min) != r(max) {
		global S_1 1		/* Not balanced */
		exit
	}

	/* Check for duplicate values in panel & equal values across panels */
	tempvar t1 t2
	sort $X_ttemp 
	quietly by $X_ttemp: gen `c(obs_t)' `t1' = 1 if _n==1
	qui replace `t1' = sum(`t1')
	sort $X_itemp $X_ttemp
	capture by $X_itemp : assert `t1' != `t1'[_n-1] if _n>1
	if _rc {
		global S_1 2		/* Duplicate values in panel */
		exit
	}

	egen `t2' = sum(`t1') if `use', by($X_itemp)
	summ `t2'
	if r(min) != r(max) {
		global S_1 3		/* Unequal values across panels */
		exit
	}
	sort $X_itemp $X_ttemp
end

cap program drop GetNKT
program define GetNKT
	summ $X_itemp
	global X_nobs  = r(N)
	global X_ng = r(max)
	tempname XX
	mat `XX' = I($X_ng)
	summ $X_ttemp
	global X_nt = r(max)

	tempvar T
	sort $X_itemp $X_ttemp
	by $X_itemp : gen `c(obs_t)' `T' = _N if _n==_N
	summ `T'
	global X_ntmin = r(min)
	global X_ntavg = r(mean)
	global X_ntmax = r(max)
end


cap program drop MapCorr
program define MapCorr /* corr */
	local l = length(`"`1'"')

	if `"`1'"'==bsubstr(`"independent"',1,`l') | `l'==0 {
		global S_1 0
		exit
	}
	if `"`1'"'==bsubstr(`"ar1"',1,`l') {
		global S_1 1
		exit
	}
	if `"`1'"'==bsubstr(`"psar1"',1,`l') {
		global S_1 2
		exit
	}
	if `"`1'"'==`"0"' | `"`1'"'==`"1"' | `"`1'"'==`"2"' {
		global S_1 `1'
		exit
	}
	di in red `"corr(`1') invalid"'
	exit 198
end

cap program drop MapPanel
program define MapPanel /* panel */
	local l = length(`"`1'"')
	if `"`1'"'==bsubstr(`"iid"',1,`l') | `l'==0 {
		global S_1 0
		exit
	}
	if `"`1'"'==bsubstr(`"heteroskedastic"',1,`l') | /*
	*/ `"`1'"'==bsubstr(`"heteroscedastic"',1,`l') {
		global S_1 1
		exit
	}
	if `"`1'"'==bsubstr(`"correlated"',1,`l') {
		global S_1 2
		exit
	}
	if `"`1'"'==`"0"' | `"`1'"'==`"1"' | `"`1'"'==`"2"' {
		global S_1 `1'
		exit
	}
	di in red `"panel(`1') invalid"'
	exit 198
end
*/

cap program drop checkt
program define checkt
	args tvar touse

	global S_1 = 0
	sort $X_itemp `tvar'
	tempvar tt
	qui by $X_itemp : gen double `tt' = `tvar'-`tvar'[_n-1] if `touse'<.
	qui by $X_itemp : replace `tt' = `tt'[_N] if _n==1
	summ `tt'
	if r(min) == 0 {
		global S_1 = 2
		exit
	}
	if r(min) != $X_t_delta | r(max) != $X_t_delta {
		global S_1 = 1
	}
end

cap program drop calcll
program define calcll
	args var ehat
	tempname Sigi lndet xEix

	if $X_bal {				/* -panel(correlated)- */
		scalar `lndet' = $X_nt*ln(det($X_Emat))
	}
	else {					/* Sigma is diagonal    */
		tempvar var_ij
		gen double `var_ij' = ln($X_Emat[$X_itemp, $X_itemp])
		sum `var_ij', meanonly
		scalar `lndet' = r(sum)
	}

	mat `Sigi' = syminv($X_Emat)
	sort $X_ttemp $X_itemp
	mat glsaccum `xEix' =  `ehat' $X_wt, nocons glsmat(`Sigi')  /*
		*/ row($X_itemp) group($X_ttemp)

	global X_ll = -.5 * ( _N*ln(2*_pi) + `lndet' + `xEix'[1,1] )
end

cap program drop calcllo
program define calcllo
	args var ehat
	tempname Sigi tr xEix  ss

	scalar `ss' = rowsof($X_Emat)/trace($X_Emat)
	mat `Sigi' = $X_Emat*`ss'
	scalar `tr' = ln(det(`Sigi')^(1/$X_ng)) - ln(`ss')
	mat `Sigi' = syminv($X_Emat) * (1/sqrt(_N))
	sort $X_ttemp $X_itemp
	mat glsaccum `xEix' =  `ehat' /*
		*/ $X_wt, nocons /*
		*/ glsmat(`Sigi') /*
		*/ row($X_itemp) /*
		*/ group($X_ttemp)
	global X_ll = -_N/2*ln(2*_pi) - _N*`tr'/2 - `xEix'[1,1]/2
end


