*! rqr 1.0.2 15june2022 Nicolai T. Borgen 

program define rqr, eclass
	
	version 12 
	
	syntax varlist(min=2 max=2) [if] [in] [aw fw iw],		///
		[Quantile(string)]									///
		[Controls(varlist fv)]								///
		[absorb(varlist fv)]								///
		[STEP1command(string)]								///
		[STEP2command(string)]								///
		[options_qreg(string asis)]							///	
		[options_step1(string asis)]						///
		[options_qrprocess(string asis)]					/// 
		[generate_r(namelist max=1)]						///
		[options_predict(string asis)]						///
		[print1step]										///
		[SMOOTHING(string asis)]								

	local cmdline `*'
	
	if "`quantile'"=="" local quantile .50
	
	local nq: word count `quantile'
	if strpos("`quantile'","(")!=0 local nq 2 	
	
	local nabsorb: word count `absorb'
			
	* Error messages *
	
	if !inlist("`step2command'", "","qreg","qrprocess") {
		di in red "error in step2command() option"
		exit 
	}

	if inlist("`step2command'","qrprocess") {
		capture which qrprocess
		if _rc {
			di as result in smcl "Please install user-written package {it:qrprocess} from SSC to estimate effects across multiple quantiles;"		///
				_newline `"click the following link to install package: {stata "ssc install qrprocess":ssc install qrprocess}"'
			exit 498
		}
	}

	if `nq'>1 {
		capture which qrprocess
		if _rc {
			di as result in smcl "Please install user-written package {it:qrprocess} from SSC to estimate effects across multiple quantiles;"		///
				_newline `"click the following link to install package: {stata "ssc install qrprocess":ssc install qrprocess}"'
			exit 498
		}
	}
		
	if inlist("`step1command'","reghdfe") {
		capture which reghdfe
		if _rc {
			di as result in smcl "Please install user-written package {it:reghdfe} from SSC to include multiple fixed effects;"		///
				_newline `"click the following link to install package: {stata "ssc install reghdfe":ssc install reghdfe}"'
			exit 498
		}
	}
	
	if `nabsorb'>1 {
		capture which reghdfe
		if _rc {
			di as result in smcl "Please install user-written package {it:reghdfe} from SSC to include multiple fixed effects;"		///
				_newline `"click the following link to install package: {stata "ssc install reghdfe":ssc install reghdfe}"'
			exit 498
		}
	}
		
	
	* Confidence level
	
	local levela=strpos("`options_qreg' `options_qrprocess'","level(") 	
	if `levela'!=0 local levelb=`levela'+9
	if `levela'==0 {
		local levela=strpos("`options_qreg' `options_qrprocess'","leve(") 	
		if `levela'!=0 local levelb=`levela'+8
	}
	if `levela'==0 {
		local levela=strpos("`options_qreg' `options_qrprocess'","lev(") 	
		if `levela'!=0 local levelb=`levela'+7
	}
	if `levela'==0 {
		local levela=strpos("`options_qreg' `options_qrprocess'","le(") 	
		if `levela'!=0 local levelb=`levela'+6
	}
	if `levela'==0 {
		local levela=strpos("`options_qreg' `options_qrprocess'","l(") 
		if `levela'!=0 local levelb=`levela'+5
	}
	if `levela'!=0 {
		local level=substr("`options_qreg' `options_qrprocess'",`levela',`levelb')
	}

		
	marksample touse
	markout `touse' `varlist' `controls' `absorb'
		
	tokenize `varlist'
		local y `1'
		local yname `1'
		macro shift
		local treatment `1'
	
	* Smoothing *
		
	if "`smoothing'"!="" {	
		tempvar yjitter u
		gen double `u'=runiform(`jitter') 
		/*qui */ su `u'
		gen double `yjitter'=`y'+`u'-r(mean)
	}
	
	tempvar treat

	* Residualize *
	
	if "`print1step'"=="" local qui qui 
	if "`print1step'"!="" local qui 
	
	if "`options_predict'"=="" local options_predict residuals

	if "`absorb'"==""  {
	    if "`step1command'"=="" local step1command regress
	    `qui' `step1command' `treatment' `controls' if `touse' [`weight' `exp'], `step1options'
	}
	if "`absorb'"!="" {
		tempvar resid
			
		if "`step1command'"!="" {
			if "`step1command'"=="xtreg" `qui' `step1command' `treatment' `controls' if `touse', fe i(`absorb') `step1options'
			else `qui' `step1command' `treatment' `controls' if `touse' [`weight' `exp'], absorb(`absorb') `step1options'
		} 
		if `nabsorb'==1 & "`step1command'"=="" `qui' areg `treatment' `controls' if `touse' [`weight' `exp'], absorb(`absorb') `step1options'
		if `nabsorb'>1 & "`step1command'"=="" `qui' reghdfe `treatment' `controls' if `touse' [`weight' `exp'], absorb(`absorb') residuals(`resid') `step1options'
		if `nabsorb'>1 local step1command "reghdfe"
	}
	qui predict double `treat' if `touse', `options_predict'		
	if "`generate_r'"!="" clonevar `generate_r'=`treat'

	local r2=e(r2)
	local r2_a=e(r2_a)
	
	* Estimate unconditional QTE *
	
	if "`smoothing'"!="" local y `yjitter'		
	
	if "`step2command'"!="" local qrmodel `step2command'
	else {
		if `nq'==1 local qrmodel qreg 
		if `nq'>1 local qrmodel qrprocess
	}
		
	if 	("`qrmodel'"=="qreg" & "`options_qrprocess'"!="") |		///
		("`qrmodel'"=="qrprocess" & "`options_qreg'"!="") {
		di as error "Mismatch between options (options_qreg/options_qrprocess) and command (qrprocess/qreg)" 
		exit
	}
	
	if "`qrmodel'"=="qreg" & `nq'>=2 {
		di as error "The option step2command(qreg) cannot be combined with multiple quantiles"
		exit
	}
		
	qui `qrmodel' `y' `treat' if `touse' [`weight' `exp'], q(`quantile') 	///
		`options_qreg' `options_qrprocess'
	
	tempname matquantile 
	
	if "`qrmodel'"=="qrprocess" {
		local nquantile=rowsof(e(quantiles))
		local colrownames
		forvalues n=1/`nquantile' {
			matrix `matquantile'=e(quantiles)
			local nn=`matquantile'[`n',1]
			local colrownames `colrownames' Q`nn':`treatment' Q`nn':_cons		
		}
	}
				
	if "`qrmodel'"=="qreg" {
		local colrownames `treatment' _cons
	}
	
	tempname b v
	mat `b'=e(b)
	mat `v'=e(V)

	mat colnames `b'=`colrownames'
	if rowsof(`v')!=0 mat colnames `v'=`colrownames'
	if rowsof(`v')!=0 mat rownames `v'=`colrownames'

	
	if "`qrmodel'"=="qrprocess" {
		
		foreach s in N df_r df_m {
			local `s'_my=e(`s')
		}
		
		foreach m in title depvar method vce bwmethod predict estat_cmd properties {
			local `m'_my `e(`m')'
		}
		
		foreach mat in sum_mdev sum_rdev quantiles coefmat {
			mat my_`mat'=e(`mat')
		}
	}
	
	if "`qrmodel'"=="qreg" {
		foreach s in df_m df_r f_r N sum_w q_v q sum_rdev sum_adev convcode {
			local `s'_my=e(`s')
		}
		
		foreach m in predict properties marginsnotok vce denmethod bwmethod depvar {
			local `m'_my `e(`m')'
		}
	}

	if rowsof(`v')!=0 ereturn post `b' `v', esample(`touse')
	else ereturn post `b', esample(`touse')

	if "`qrmodel'"=="qrprocess" {
		foreach s in N df_r df_m {
			ereturn scalar `s'=``s'_my'
		}
		
		foreach m in title depvar method vce bwmethod predict estat_cmd properties {
			ereturn local `m' "``m'_my'"
		}
		
		foreach mat in sum_mdev sum_rdev quantiles coefmat {
			ereturn matrix `mat' my_`mat'
		}
	}
	
	if "`qrmodel'"=="qreg" {
		foreach s in df_m df_r f_r N sum_w q_v q sum_rdev sum_adev convcode {
			ereturn scalar `s'=``s'_my'
		}
		
		foreach m in predict properties marginsnotok vce denmethod bwmethod depvar {
			ereturn local `m' "``m'_my'"
		}
	}
	
	if "`smoothing'"!="" ereturn local depvar "`yname'"

	ereturn local cmd "`qrmodel'"
	ereturn local cmdname "rqr"
	ereturn local controls "`controls' `absorb'"
	ereturn local treatment "`treatment'"
	ereturn local cmdline "rqr `cmdline'"
	ereturn scalar first_step_r2=`r2'
	ereturn scalar first_step_r2_a=`r2_a'

	di _newline(2)
	di as text "Residualized Quantile Regression                         Number of obs = " as result e(N) 
	di as text "Quantiles: " as result " `quantile'"
	ereturn display, `level'
	di as text "Control variables: `controls' "
	if "`step1command'"=="" | "`step1command'"=="areg" local femethod areg 
	if "`step1command'"=="reghdfe" local femethod reghdfe 
	if "`absorb'"!="" di as text "Fixed effects: `absorb' (absorbed in first step using `femethod')"
	if "`qrmodel'"=="qreg" local alg qreg
	if "`qrmodel'"=="qrprocess" { 
		if e(method)=="qreg" local alg qreg (from qrprocess)
		if e(method)=="fn" local alg Frisch-Newton interior point (from qrprocess)
		if e(method)=="pqreg" local alg  qreg with preprocessing (from qrprocess)
		if e(method)=="pfn" local alg  Frisch-Newton interior point with preprocessing (from qrprocess)
		if e(method)=="proqreg" local alg Discretized quantile regression process with qreg (from qrprocess)
		if e(method)=="profn " local alg Discretized quantile regression process with Frisch-Newton (from qrprocess)
		if e(method)=="1step" local alg One-step estimator (from qrprocess)
	}
	di as text "Algorithm: `alg'"
	if "`smoothing'"!="" {
		di as text "The outcome variable is smoothed"
	}

	
end

