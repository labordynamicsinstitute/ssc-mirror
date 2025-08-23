// Package for weak-IV test (Daniel J. Lewis and Karel Mertens, 2024)
// Author: Lingyun ZHOU

// Version 03/29/2024: The first version: test based on relative bias criterion
// Version 07/31/2024: incorporating ivreghdfe
// Version 07/19/2025: incorporating functions in the accepted version of Lewis and Mertens (2025), including 1. test based on absolute bias criterion; 2. test for individual coefficients; 3. test under local-to-rank-reduction-to-1.
// Version 08/15/2025: 1. fixing the dof adjustment and variable indexing when N > 2 for the LRR1 test; 2. allow for the partial option in ivreg2.
// This version: 08/15/2025

program weakivtest2, rclass
	version 17

	syntax [, level(string) 		///
			  tau(string) 			///
			  points(real 1000)		///
			  ASYMPtotics(string)	/// l0 / lrr1
			  INDex(real 0)			/// for LRR1 test
			  TARget(real 0)		/// for L0/LRR1 test. When asymptotics(llr1) is declared, targent can only be 0 or the integer claimed in index().
			  CRITerion(string)		/// absolute / relative
			  fast					///
			  record				///
		   ]
	
	* If "avar" command is not installed in user's computer, display the error message.
	capture which avar
	if _rc==111 {
		di as err `"User contributed command avar is needed to run weakivtest. Install avar by typing "ssc install avar"."'
		exit
	}
	
	* weakivtest2 is a postestimation command to ivreg2 or xtivreg2 or ivreghdfe; otherwise display error message.
	if (!inlist("`e(cmd)'", "ivreg2", "xtivreg2", "ivreghdfe")) {
		di as err `"Weakivtest is a postestimation command after running ivreg2 or xtivreg2."'
		exit
	}
	else if (("`e(cmd)'" == "xtivreg2") & ("`e(xtmodel)'" != "fe")) {
		di as err "Weakivtest is a postestimation command after running xtivreg2 only with fixed effects."
		exit
	}

	* Hold and copy ereturn list
	tempname myereturn
    _estimates hold  `myereturn' , copy
	
	* Adjust the ereturn list if using ivreghdfe
	adjust_ereturn2
	loc ivcmd `e(cmd)'
	
	* tau, level and alpha
	tempname taulist levellist alphalist
	if ("`tau'" == "") local tau 0.05 0.1 0.2 0.3
	if ("`level'" == "") local level 95 90
	foreach i of numlist `tau' {
		local tautemp `tautemp' `i'
	}
	foreach i of numlist `level' {
		local leveltemp `leveltemp' `i'
	}
	loc tau `tautemp'
	loc level `leveltemp'
	loc nlevel = wordcount("`level'")
	forvalues i = 1/`nlevel' {
		loc leveli = word("`level'",`i')
		loc alphai = 1 - `leveli' / 100
		loc alpha `alpha' `alphai' 
	}
	foreach para in tau level alpha {
		loc n`para' = wordcount("``para''")
		mat define ``para'list' = J(`n`para'', 1, 0)
		forvalues i = 1/`n`para'' {
			loc parai = word("``para''",`i')
			mat ``para'list'[`i',1] = `parai'
			loc parai100 = `parai' * 100
			loc `para'name ``para'name' `para'=`parai100'%
		}
		mata: `para'list = st_matrix("``para'list'")
	}

	* Use observations from e(sample).
	tempvar touse
	gen byte `touse' = e(sample)
   
	* Use weights
	if ("`e(wtype)'" != "") local addweight "[`e(wtype)'`e(wexp)']"
	
	* asymptotic embedding
	if ("`asymptotics'" == "") local asymptotics l0
	
	* bias criterion 
	if ("`criterion'" == "") local criterion absolute
	
	* Use only simplified version
	if ("`fast'" != "") loc fast = 1
	else loc fast = 0
	
	* Record the iteration
	if ("`record'" != "") loc record = 1
	else loc record = 0
	
	* Check for noconst_flag
	local noconst_flag = ( "`e(constant)'"=="noconstant") | ( "`e(cons)'"=="0")
	
	* Save ereturn results
	local K = e(exexog_ct) // Excluded Instrumental Variables
	local L = e(inexog_ct) // Exogenous Regressors
	if ("`ivcmd'" == "xtivreg2") local L = `L' + e(N_g)
	else if ( `noconst_flag' == 0) local L = `L' + 1
	local N = e(endog_ct)  // Endogenous Regressors
	local T = e(N)
	if strpos("`e(vce)'","bw"){
		local vcet=regexr("`e(vce)'","ac bartlett", "")
		local vcet=regexr("`vcet'","h", "")
		local vcet=regexr("`vcet'","=", "(")+")"
	}
	else if strpos("`e(vce)'","cluster") local vcet "robust cluster(`e(clustvar)')"
	else local vcet `e(vce)'
	fvrevar `e(depvar)'
	local y  "`r(varlist)'" 
	fvrevar `e(instd)'
	local Y   "`r(varlist)'"  
	fvrevar `e(exexog)'
	local Z  "`r(varlist)'" 
	fvrevar `e(inexog)'
	local X "`r(varlist)'"
	
	* Check for LRR1 test
	if ("`asymptotics'" == "lrr1") {
		if (`index' == 0) {
			di as err `"Specified the location of retained regressor for test under local-to-rank-reduction-of-one via index()."'
			exit
		}
		if ((`target' > 0) & (`index' != `target')) {
			di as err `"Target coefficient "target()" must be the same as retained regressor "index()" for test under local-to-rank-reduction-of-one."'
			exit
		}
		if (`K' < 2) {
			di as err `"At least two instrumental variables are required for test under local-to-rank-reduction-of-one."'
			exit
		}
		if ("`criterion'" == "relative") {
			di as err `"Only absolute bias criterion is supported for test under local-to-rank-reduction-of-one."'
			exit
		}
	}
	
	* Generate residuals of y, Y, Z
	foreach type in y Y Z { // yo, Yo, Zo
		local `type'o "" 
		foreach var in ``type'' {
			tempvar `var'temp
			if ("`ivcmd'" == "ivreg2") {
				if (`noconst_flag' == 1) qui reg `var' `X' if `touse' `addweight', noconstant
				else qui reg `var' `X' if `touse' `addweight'
			}
			else if ("`ivcmd'" == "xtivreg2") qui xtreg `var' `X' if `touse' `addweight', fe
			qui predict double ``var'temp' if `touse', r
			if ("`ivcmd'" == "xtivreg2") {
				tempvar `var'temp1
				qui by `e(ivar)': egen ``var'temp1' = mean(``var'temp')
				qui replace ``var'temp' = ``var'temp' - ``var'temp1'
			}
			local `type'o ``type'o' ``var'temp'
		}
	}
	
	* Orthogonize instruments
// 	mata: Zo = st_data(.,"`Zo'")
// 	mata: Zo = Zo - J(`T',1,1) * mean(Zo)
// 	mata: Zo = Zo * pinv(sqrtmat(Zo' * Zo / `T'))
// 	loc i = 0
// 	foreach z in `Zo' {
// 		loc i = `i' + 1
// 		mata: st_store(.,"`z'",Zo[.,`i'])
// 	}
	tempname Zs 
	qui orthog `Zo' if `touse' `addweight', gen(`Zs'*)
	fvrevar `Zs'*
	local Zo "`r(varlist)'"
	
	* Run second stage regression and save residuals as v1 in mata.
	tempvar v1 Pyo
	qui reg `yo' `Zo' if `touse' `addweight', noconstant
	qui predict double `Pyo', xb
	qui predict double `v1', r

	* Run first stage regression and save residuals as v2 in mata.
	local v2 ""
	loc PYo ""
	foreach var in `Yo' {
		tempvar v2`var' PYo`var'
		qui reg `var' `Zo' if `touse' `addweight', noconstant
		qui predict double `PYo`var'', xb
		qui predict double `v2`var'', r
		local PYo `PYo' `PYo`var''
		local v2 `v2' `v2`var''
	}
	 
	if ("`asymptotics'" == "l0") {
		* Transform variables to mata
		preserve
		qui drop if `Pyo' == .
		foreach vlist in yo Yo Zo PYo Pyo v1 v2 {
			mata: `vlist' = st_data(.,"``vlist''")
		}
		restore
		
		* Get W matrix and statistics
		tempname W Sig W2 RNK Phi Svv
		tempname stat1 stat2 cv1 cv2 cv3
		/*
		stat1: gmin_generalized
		stat2: gmin_stock_yogo
		cv1: gmin_generalized_critical_value
		cv2: gmin_generalized_critical_value_simplified
		cv3: stock_yogo_critical_values_nagar
		*/
		qui avar (`v1' `v2') (`Zo') `addweight' if `touse', `vcet' noconstant
		mata: `W' = st_matrix("r(S)") * `T' / (`T' - `K' - `L')
		tempvar constant
		gen `constant' = 1
		qui avar (`v1' `v2') (`constant') `addweight' if `touse', `vcet' noconstant
		mata: `Sig' = st_matrix("r(S)") * `T' / (`T' - `K' - `L')
		mata: `W2' = `W'[`K'+1..`K'*(`N'+1),`K'+1..`K'*(`N'+1)]
		mata: `RNK' = I(`N') # vec(I(`K'))
		mata: `Phi' = `RNK'' * (`W2' # I(`K')) * `RNK'
		mata: `Phi' = pinv(sqrtmat(`Phi'))
		mata: `stat1' = min(symeigenvalues(`Phi' * (PYo' * PYo) * `Phi'))
		mata: `Svv' = v2' * v2 / (`T' - `K' - `L')
		mata: `Svv' = pinv(sqrtmat(`Svv'))
		mata: `stat2' = min(symeigenvalues((`Svv' * (PYo' * PYo) * `Svv') / `K'))
		mata: cvresult = gweakivtest_critical_values(`W',`K',`Sig',alphalist,taulist,`points',`target',"`criterion'",`fast',`record')
		mata: `cv1' = cvresult.cv1
		mata: `cv2' = cvresult.cv2
		mata: `cv3' = cvresult.cv3
	}
	else if ("`asymptotics'" == "lrr1") {
		loc PYo_nind ""
		loc i = 0
		foreach var in `PYo' {
			loc i = `i' + 1
			if (`i' != `index') loc PYo_nind `PYo_nind' `var'
		}
		loc Yo_ind ""
		loc i = 0
		foreach var in `Yo' {
			loc i = `i' + 1
			if (`i' == `index') loc Yo_ind `Yo_ind' `var'
		}
		
		loc v2_nind ""
		loc v2_ind ""
		loc i = 0
		foreach var in `v2' {
			loc i = `i' + 1
			if (`i' != `index') loc v2_nind `v2_nind' `var'
			else if (`i' == `index') loc v2_ind `v2_ind' `var'
		}

		* project out PYo_nind from Yo_ind
		tempvar Ystar 
		tempname dtilde
		qui reg `Yo_ind' `PYo_nind' if `touse' `addweight', noconstant
		qui predict double `Ystar', r
		mat define `dtilde' = e(b)
		
		* create v2star
		tempvar v2star
		gen `v2star' = `v2_ind'
		loc i = 0
		foreach var in `v2_nind' {
			loc i = `i' + 1
			qui replace `v2star' =  `v2star' - `var' * `dtilde'[1,`i']
		}
		
		* project out PYo_nind from yo
		tempvar ystar
		qui reg `yo' `PYo_nind' if `touse' `addweight', noconstant
		qui predict double `ystar', r
		
		* project out PYo_nind from Ztilde
		loc Zstar
		loc i = 0
		foreach var in `Zo' {
			loc i = `i' + 1
			if (`i' >= `N') {
				tempvar Zstar`var'
				qui reg `var' `PYo_nind' if `touse' `addweight', noconstant
				qui predict double `Zstar`var'', r
				loc Zstar `Zstar' `Zstar`var''
			}
		}
		loc Kstar = `K' - `N' + 1
		
		* project Ystar on Zstar
		tempvar Ystaro
		qui reg `Ystar' `Zstar' if `touse' `addweight', noconstant
		qui predict double `Ystaro', xb
		
		* Orthogonize instruments
		tempname Zstars 
		qui orthog `Zstar' if `touse' `addweight', gen(`Zstars'*)
		fvrevar `Zstars'*
		local Zstar "`r(varlist)'"
		
		* Transform variables to mata
		preserve
		qui drop if `Pyo' == .
		foreach vlist in yo Yo Zo PYo Pyo v1 v2 v2star Ystar Ystaro ystar Zstar {
			mata: `vlist' = st_data(.,"``vlist''")
		}
		restore
		mata: dtilde = st_matrix("`dtilde'")
		
		* Get W matrix and statistics
		tempname Wstar Sstar S_full W2 RNK Phi Svv
		tempname stat1 stat2 cv1 cv2 cv3
		/*
		stat1: gmin_generalized
		stat2: gmin_stock_yogo
		cv1: gmin_generalized_critical_value
		cv2: gmin_generalized_critical_value_simplified
		cv3: stock_yogo_critical_values_nagar
		*/		
		qui avar (`v1' `v2star') (`Zstar') `addweight' if `touse', `vcet' noconstant
		mata: `Wstar' = st_matrix("r(S)") * `T' / (`T' - `K' - `L')
		tempvar constant
		gen `constant' = 1
		qui avar (`v1' `v2star') (`constant') `addweight' if `touse', `vcet' noconstant
		mata: `Sstar' = st_matrix("r(S)") * `T' / (`T' - `K' - `L')
		qui avar (`v2') (`constant') `addweight' if `touse', `vcet' noconstant
		mata: `S_full' = st_matrix("r(S)")
// 		mata: `stat1' = Ystaro' * Ystaro / trace(`Wstar'[`K'..2*(`K'-1),`K'..2*(`K'-1)])
// 		mata: `stat2'  = Ystaro' * Ystaro / ((`K' - 1) * v2star' * v2star / `T')
		mata: `stat1' = Ystaro' * Ystaro / trace(`Wstar'[`Kstar'+1..2*`Kstar',`Kstar'+1..2*`Kstar'])
		mata: `stat2'  = Ystaro' * Ystaro / (`Kstar' * (v2star - J(`T',1,mean(v2star)))' * (v2star - J(`T',1,mean(v2star))) / `T')
		mata: cvresult = gweakivtest_critical_valuesLRR1(`Wstar',`K'-`N'+1,`Sstar',`S_full',alphalist,taulist,`points',`target',"`criterion'",`fast',`record')
		mata: `cv1' = cvresult.cv1
		mata: `cv2' = cvresult.cv2
		mata: `cv3' = cvresult.cv3
	}

	foreach num in stat1 stat2 {
		mata: st_numscalar("``num''", ``num'')
	}
	foreach mat in cv1 cv2 cv3 {
		mata: st_matrix("``mat''", ``mat'')
		mat rownames ``mat'' = `tauname'
		mat colnames ``mat'' = `alphaname'
	}
	tempname cv_active
	if (`fast' == 0) mat define `cv_active' = `cv1'
	else if (`fast' == 1) mat define `cv_active' = `cv2'

	* Generate output table
	display as text "Lewis-Mertens robust weak instrument test"
	if ("`asymptotics'" == "l0") {
		if ("`criterion'" == "absolute") display "Test under local-to-zero (absolute bias)"
		else if ("`criterion'" == "relative") display "Test under local-to-zero (relative bias)"
	}
	else if ("`asymptotics'" == "lrr1") display "Test under local-to-rank-reduction-of-one"
	display as text "Number of observations  = " as result %15.0fc `T'
	display as text "Test statistic (gmin)   = " as result %15.3fc `stat1'
	loc length = 15 + 13 * `nalpha'
	loc length2 = `length' - 18
	loc length3 = max(1, `length2' - 14)
	display "{txt}{hline `length'}"
	if (`fast' == 0) display "{txt}{space `length2'}Significance Level"
	else if (`fast' == 1) display "Conversative{txt}{space `length3'}Significance Level"
	display "Critical Values" _continue
	forvalues i = 1/`nalpha' {
		loc alphai = `alphalist'[`i',1] * 100
		display "    alpha=" %2.0fc `alphai' "%" _continue
	}
	display ""
	display "{txt}{hline `length'}"
	forvalues i1 = 1/`ntau' {
		loc taui = `taulist'[`i1',1] * 100
		display as text "tau=" %2.0fc `taui' "%{txt}{space 8}" _continue
		forvalues i2 = 1/`nalpha' {
			loc cv = `cv_active'[`i1',`i2']
			display as result %13.3fc `cv' _continue
		}
		display ""
	}
	display "{txt}{hline `length'}"

	* Return list
	return scalar stat = `stat1'
	return matrix cv = `cv1'
	return matrix cv_simp = `cv2'
	if ("`asymptotics'" == "l0") {
		return matrix cv_sy = `cv3'
		return scalar stat_sy = `stat2'
	}
	else if ("`asymptotics'" == "lrr1") {
		return matrix cv_sw = `cv3'
		return scalar stat_sw = `stat2'
	}
	return scalar points = `points'
	return scalar K = `K' // Excluded Instrumental Variables
	return scalar L = `L' // Exogenous Regressors
	return scalar N = `N' // Endogenous Regressors
	return scalar T = `T' // Observations
	if (`fast' == 1) return local fast = "yes"
	else if (`fast' == 0) return local fast = "no"
	if (`record' == 1) return local record = "yes"
	else if (`record' == 0) return local record = "no"
	return local criterion = "`criterion'"
	if ("`asymptotics'" == "lrr1") return scalar index = `index'
	if (`target' == 0) return local target = "beta"
	else if (`target' > 0) return local target = "beta`target'"
	if ("`asymptotics'" == "l0") return local asymptotics = "local-to-zero"
	else if ("`asymptotics'" == "lrr1") return local asymptotics = "local-to-rank-reduction-of-one"	
	return matrix alpha = `alphalist'
	return matrix tau = `taulist'

	* Unhold ereturn result
	_estimates unhold `myereturn'
	
end

program adjust_ereturn2, eclass
	version 17
	
	if `"`e(cmd)'"' == "ivreg2" {
		local pos_2 = strpos("`e(cmdline)'", "partial")
		if `pos_2' > 0 {
			* Update for e(inexog_ct): When we use the partial option in the ivreg2 case, we delete the varlist specified (including the constant) in this option. So now we update the number of included exogenous regressors as the number of this deleted variables minus 1.
			ereturn scalar inexog_ct = `e(partial_ct)' - 1
			* Update for e(cons): Activate the option for a constant in each regression (because when we use partial option we delete the constant of the
>  regression).
			ereturn scalar cons = 1
		}
	}       


	if( inlist(`"`e(cmd)'"', "reghdfe", "ivreghdfe") & `"`e(model)'"' == "iv") {
		* Update for e(inexog): Create labels of all feasible fixed effects in each regression (weakivtest command need this to count the number of feasible fixed effects in each regression).
		local inexog_aux = " " + "`e(absvars)'"
		local r_aux_1 = 0
		local r_aux_2 = 0
		local rep1 = 1
		local rep2 = 1
		foreach name of local inexog_aux {
    			local pos = strpos("`name'", " ") + 1
    			local name = substr("`name'", `pos', .)
				local pos_aux = strpos("`name'", "#")
				if `pos_aux' > 0 {
					local name_1 = substr("`name'", `pos_aux'+1, .)
					local name_2 = substr("`name'", 1, `pos_aux'-1)
					qui distinct `name_1' `name_2', joint
					if `rep1' == 1 {
						local r_aux_1 = `r(ndistinct)'
					}
					else if `rep1' > 1 {
					    local r_aux1 = `r(ndistinct)'
						local r_aux_1 = `r_aux_1' + `r_aux1'
					}
					local name_1 = "i." + "`name_1'"
					local name_2 = "i." + "`name_2'"
					local name_full = "`name_1'" + "#" + "`name_2'"
					local inexog_fe `inexog_fe' `name_full'
					local rep1 = `rep1' + 1 
				}			
				else {
					local name_aux = "`name'"
					qui distinct `name_aux'
					if `rep2' == 1 {
						local r_aux_2 = `r(ndistinct)'
					}
					else if `rep2' > 1 {
					    local r_aux2 = `r(ndistinct)'
						local r_aux_2 = `r_aux_2' + `r_aux2'
					}
					local name = "i." + "`name'"
					local inexog_fe `inexog_fe' `name'
					local rep2 = `rep2' + 1 
				}
		}
		if ("`e(inexog)'" == "") ereturn local inexog = "`inexog_fe'"
		else ereturn local inexog = "`e(inexog)'" + " " + "`inexog_fe'"
		
		if `"`e(cmd)'"' == "ivreghdfe" & "`e(df_a)'" != "" & "`e(N_full)'" != ""  {
			* Update for e(inexog_ct): For the ivreghdfe case, we set the number of included exogenous regressors equal to the number of degrees of freedom lost due to the estimation of the model, plus singleton observations according to fixed effects, plus the number of regressors minus 1.
			ereturn scalar inexog_ct = `e(num_singletons)' + `e(inexog_ct)' + `e(df_a)' - 1
			* Update for e(N): Change the number of observations to fit the ivreg2 case (N_full considers singleton observations according to fixed effects).
			ereturn scalar N = `e(N_full)'
		}
		else if (`"`e(cmd)'"' == "reghdfe" & `r_aux_1' > 0) {
		    * Update for e(inexog_ct): For the reghdfe case, we set the number of included exogenous regressors equal to the number of degrees of freedom lost due to the estimation of the model, plus singleton observations according to fixed effects, plus the number of regressors minus 1.
			local singleton_obs = `r_aux_1' + `r_aux_2' - `e(df_a)' - `e(inexog_ct)'
			ereturn scalar inexog_ct = `singleton_obs' + `e(inexog_ct)' + `e(df_a)' - 1 
			* Update for e(N): Change the number of observations to fit the ivreg2 case (Now e(N) considers singleton observations according to fixed effects).
			ereturn scalar N = `e(N)' + `singleton_obs'
		}
		else {
		    * Update for e(inexog_ct): For the reghdfe case (when we don't have singleton observations), we set the number of included exogenous regressors equal to the number of degrees of freedom lost due to the estimation of the model, plus the number of regressors minus 1.
		    ereturn scalar inexog_ct = `e(inexog_ct)' + `e(df_a)' - 1
		}
		
		* Update for e(cons): Activate the option for a constant in each regression (I think that this is not explicit in reghdfe and ivreghdfe cases, but they show the results as they used a constant).
		ereturn scalar cons = 1

		* Update for e(vce): Change the name of the type of robust variance-covariance estimator to fit the ivreg2 case
		if `"`e(vce)'"' == "cluster" {
			ereturn local vce = "robust cluster"
		}
		else if `"`e(vce)'"' == "ols" {
			ereturn local vce = ""
		}
		
		* Update for e(cmd): Change the name of the estimator to fit the ivreg2 case
		ereturn local cmd = "ivreg2" 
	}	
end

/* MATA CODE PART */
mata
	version 17
	mata clear
	
	real matrix sqrtmat(A) {
		real matrix eigvec, eigval, Ahalf
		real scalar i
		
		eigvec = 1; eigval = 1
		symeigensystem(A, eigvec, eigval)
		for (i=1;i<=cols(eigval);i++) if (abs(eigval[i]) < 1e-10) eigval[i] = 0
		Ahalf = eigvec * sqrt(diag(eigval)) * eigvec'
		return(Ahalf)
	}
	
	real matrix norm(A) { // L2 matrix norm
		return(max(svdsv(A)))
	}
	
	real matrix normfor(A) { // frobenius norm
		return(sqrt(sum(A :* A)))
	}
	
	struct CVresult {
		real matrix cv1, cv2, cv3
	}
	
	struct CVresult scalar gweakivtest_critical_values(W, K, Sig, alphalist, taulist, points, target, criterion, fast, record) {
		real scalar N, j, lmin, n, ome, nu, cc, iter, mxitr, xtol, gtol, ftol, eta, gamma, nt, crit, tiny, ttau, rhols, i1, i2, tau, alpha, kt_cond1, kt_cond2, kt_cond3, kt_cond
		real matrix RNK, RNN, RNpK, M1, M2, W1, W2, W12, Phi, iPhi, S, Sigma, Psibar, Psi, X1, M2PsiM2, Bmax, Bmax_iters, Q, R, L0, k, knew
		struct CVresult scalar result
		
		mxitr = 1000
		xtol = 1e-5
		gtol = 1e-5
		ftol = 1e-7
		eta = 0.1
		gamma = 0.85
		nt = 5
		tiny = 1e-13
		ttau = 1e-3
		rhols = 1e-4
		
		N = rows(W) / K - 1
		RNK = I(N) # vec(I(K))
		RNN = I(N) # vec(I(N))
		RNpK = I(N+1) # vec(I(K))
		M1 = RNN' * (I(N^3) + (Kgen(N,N) # I(N)))
		M2 = RNK * RNK' / (1 + N) - I(N * K^2)

		W1 = W[1..K,1..K]
		W2 = W[K+1..K*(N+1),K+1..K*(N+1)]
		W12 = W[1..K,K+1..K*(N+1)]

		Phi = RNK' * (W2 # I(K)) * RNK
		S = (pinv(sqrtmat(Phi / K)) # I(K)) * sqrtmat(W2)
		Sigma = S * S'
		
		Psibar = (((pinv(sqrtmat(Phi / K)) # I(K)) * (W12 \ W2)') # I(K)) * RNpK
		if (criterion == "relative") Psi = Psibar * invsym(sqrtmat(RNpK' * (W # I(K)) * RNpK))
		else if (criterion == "absolute") Psi = Psibar * pinv(sqrtmat(Sig)) * norm(pinv(sqrtmat(Phi))*sqrtmat(Sig[2..N+1,2..N+1]))
		X1 = ((I(N) # Kgen(K^2,N)) # I(N^2)) * (vec(I(N)) # I(N^2*K^2)) * ((I(K) # Kgen(K,N)) # I(N)) * (I(N^2*K^2) + Kgen(N*K,N*K))
		M2PsiM2 = M2 * (Psi * Psi') * M2'

		Bmax = J(3,1,0)
		if ((N == 1) & (criterion == "relative")) {
			if (K > N + 1) Bmax[2] = min((min((sqrt(2*(N+1)/K)*norm(M2*Psi),norm(Psi))),1))
			else Bmax[2] = min((max((sqrt(2*(N+1)/K)*norm(M2*Psi),norm(Psi))),1))
		}
		else {
			if (K > N + 1) Bmax[2] = min((sqrt(2*(N+1)/K)*norm(M2*Psi),norm(Psi)))
			else Bmax[2] = max((sqrt(2*(N+1)/K)*norm(M2*Psi),norm(Psi)))
		}
		
		if (fast == 0) {
			if (K > N + 1) {
				// Sharp upper bound
				Bmax_iters = J(points,1,0)
				Q = J(K, K, 0)
				R = J(K, K, 0)
				if (record == 1) printf("{txt}Iteration Counter:\n")
				for (iter=1;iter<=points;iter++) {
					qrd(rnormal(K,K,0,1), Q, R)
					L0 = Q[.,1..N]
					Bmax_iters[iter] = sqrt(- OptStiefelGBB(L0, M1, M2PsiM2, X1, mxitr, xtol, gtol, ftol, eta, gamma, nt, tiny, ttau, rhols))
					if (record == 1) {
						if (iter/50 == ceil(iter/50) | iter == points) printf("{txt} %s\n",strofreal(iter))
						else printf("{txt}·")
						displayflush()
					}
				}
				if (record == 1) printf("{txt}\n")
				Bmax[1] = max(Bmax_iters)
			}
			else Bmax[1] = Bmax[2]
		}
		else if (fast == 1) Bmax[1] = .
		
		// Stock-Yogo under nagar Approximation
		if (K > N + 1) Bmax[3] = (K - (N + 1)) / K
		else Bmax[3] = .
		
		// Rescale tau if necessary for median bias
		if (K == N) {
			printf("{txt}Note: Model is just-identified, test is for median bias.\n")
			if (N == 1) taulist = taulist / 0.455
		}
		
		// Rescale tau if necessary for single-coefficient test
		if ((target > 0) & (criterion == "absolute")) {
			iPhi = pinv(sqrtmat(Phi))
			taulist = taulist / (sqrt(Sig[target+1,target+1]) * norm(iPhi[target,1..N])) * norm(iPhi * sqrtmat(Sig[2..N+1,2..N+1]))
		}
		
		// Get critical value
		k = J(3,1,0)
		result.cv1 = J(rows(taulist),rows(alphalist),.)
		result.cv2 = J(rows(taulist),rows(alphalist),.)
		result.cv3 = J(rows(taulist),rows(alphalist),.)
		for (i1=1;i1<=rows(taulist);i1++) {
			tau = taulist[i1]
			for (i2=1;i2<=rows(alphalist);i2++) {
				alpha = alphalist[i2]
				for (j=1;j<=3;j++) {
					lmin = Bmax[j] / tau
					if (j < 3) { // Imhof Approximation
						for (n=1;n<=3;n++) k[n] = 2^(n-1)*factorial(n-1)*(norm(RNK'*(matpowersym(Sigma,n) # I(K))*RNK)+n*K*lmin*(norm(Sigma))^(n-1))
						ome = k[2] / k[3]
						nu = 8 * k[2] * ome^2
						cc = invchi2(nu,1-alpha)
						// Check Kuhn-Tucker Conditions at the corner solution
						if ((fast == 0) | (j == 2))  {
							kt_cond1 = ID1fun(((cc-nu)/4/ome+k[1]), .z, ome, nu, k) 
							kt_cond2 = ID2fun(((cc-nu)/4/ome+k[1]), .z, ome, nu, k) 
							kt_cond3 = ID3fun(((cc-nu)/4/ome+k[1]), .z, ome, nu, k) 
							kt_cond = (kt_cond1 >= 0) & (kt_cond2 >= 0) & (kt_cond3 >= 0)
						}
						else kt_cond = 1
						// If Kuhn-Tucker Conditions fail, find cumulants that maximize the critical value at alfa numerically
						if (kt_cond != 1) {
							if (N > 1) {
								knew = argminCV1fun(k, alpha)
								k = knew
							}
							else {	
								knew = argminCV2fun(k, alpha)
								k[2..3] = knew
							}
							ome = k[2] / k[3]
							nu = 8 * k[2] * ome^2
							cc = invchi2(nu,1-alpha)	
						}
						if (j == 1) result.cv1[i1,i2] = ((cc - nu) / (4 * ome) + k[1]) / K
						else if (j == 2) result.cv2[i1,i2] = ((cc - nu) / (4 * ome) + k[1]) / K
					}
					else if (j == 3) result.cv3[i1,i2] = invnchi2(K, K*lmin, 1-alpha) / K
				}
			}
		}
		
		return(result)
	}
	
	struct CVresult scalar gweakivtest_critical_valuesLRR1(W, K, Sig, Sigv, alphalist, taulist, points, target, criterion, fast, record) {
		real scalar N, j, lmin, n, ome, nu, cc, iter, mxitr, xtol, gtol, ftol, eta, gamma, nt, crit, tiny, ttau, rhols, i1, i2, tau, alpha
		real matrix RNK, RNN, RNpK, M1, M2, W1, W2, W12, Phi, iPhi, S, Sigma, Psibar, Psi, X1, M2PsiM2, Bmax, Bmax_iters, Q, R, L0, k, knew
		struct CVresult scalar result
		
		mxitr = 1000
		xtol = 1e-5
		gtol = 1e-5
		ftol = 1e-7
		eta = 0.1
		gamma = 0.85
		nt = 5
		tiny = 1e-13
		ttau = 1e-3
		rhols = 1e-4
		
		N = rows(W) / K - 1
		RNK = I(N) # vec(I(K))
		RNN = I(N) # vec(I(N))
		RNpK = I(N+1) # vec(I(K))
		M1 = RNN' * (I(N^3) + (Kgen(N,N) # I(N)))
		M2 = RNK * RNK' / (1 + N) - I(N * K^2)

		W1 = W[1..K,1..K]
		W2 = W[K+1..K*(N+1),K+1..K*(N+1)]
		W12 = W[1..K,K+1..K*(N+1)]

		Phi = RNK' * (W2 # I(K)) * RNK
		S = (pinv(sqrtmat(Phi / K)) # I(K)) * sqrtmat(W2)
		Sigma = S * S'
		
		Psibar = (((pinv(sqrtmat(Phi / K)) # I(K)) * (W12 \ W2)') # I(K)) * RNpK
		Psi = Psibar * pinv(sqrtmat(Sig)) * norm(pinv(sqrtmat(Phi))*sqrtmat(Sig[2..N+1,2..N+1]))
		X1 = ((I(N) # Kgen(K^2,N)) # I(N^2)) * (vec(I(N)) # I(N^2*K^2)) * ((I(K) # Kgen(K,N)) # I(N)) * (I(N^2*K^2) + Kgen(N*K,N*K))
		M2PsiM2 = M2 * (Psi * Psi') * M2'

		Bmax = J(3,1,0)

		if (K > N + 1) Bmax[2] = min((sqrt(2*(N+1)/K)*norm(M2*Psi),norm(Psi)))
		else Bmax[2] = max((sqrt(2*(N+1)/K)*norm(M2*Psi),norm(Psi)))
		
		if (fast == 0) {
			if (K > N + 1) {
				// Sharp upper bound
				Bmax_iters = J(points,1,0)
				Q = J(K, K, 0)
				R = J(K, K, 0)
				if (record == 1) printf("{txt}Iteration Counter:\n")
				for (iter=1;iter<=points;iter++) {
					qrd(rnormal(K,K,0,1), Q, R)
					L0 = Q[.,1..N]
					Bmax_iters[iter] = sqrt(- OptStiefelGBB(L0, M1, M2PsiM2, X1, mxitr, xtol, gtol, ftol, eta, gamma, nt, tiny, ttau, rhols))
					if (record == 1) {
						if (iter/50 == ceil(iter/50) | iter == points) printf("{txt} %s\n",strofreal(iter))
						else printf("{txt}·")
						displayflush()
					}
				}
				if (record == 1) printf("{txt}\n")
				Bmax[1] = max(Bmax_iters)
			}
			else Bmax[1] = Bmax[2]
		}
		else if (fast == 1) Bmax[1] = .
		
		// Stock-Yogo under nagar Approximation
		if (K > N + 1) Bmax[3] = (K - (N + 1)) / K
		else Bmax[3] = .
		
		// Rescale tau if necessary for median bias
		if (K == N) {
			printf("{txt}Note: Model is just-identified, test is for median bias.\n")
			if (N == 1) taulist = taulist / 0.455
		}
		
		// Rescale tau if necessary for single-coefficient test
		if (target > 0) taulist = taulist * sqrt(Sig[2,2]) / sqrt(Sigv[target,target])
		
		// Get critical value
		k = J(3,1,0)
		result.cv1 = J(rows(taulist),rows(alphalist),.)
		result.cv2 = J(rows(taulist),rows(alphalist),.)
		result.cv3 = J(rows(taulist),rows(alphalist),.)
		for (i1=1;i1<=rows(taulist);i1++) {
			tau = taulist[i1]
			for (i2=1;i2<=rows(alphalist);i2++) {
				alpha = alphalist[i2]
				for (j=1;j<=3;j++) {
					lmin = Bmax[j] / tau
					if (j < 3) { // Imhof Approximation
						for (n=1;n<=3;n++) k[n] = 2^(n-1)*factorial(n-1)*(norm(RNK'*(matpowersym(Sigma,n) # I(K))*RNK)+n*K*lmin*(norm(Sigma))^(n-1))
						ome = k[2] / k[3]
						nu = 8 * k[2] * ome^2
						cc = invchi2(nu,1-alpha)
						// Check Kuhn-Tucker Conditions at the corner solution
						if ((fast == 0) | (j == 2))  {
							kt_cond1 = ID1fun(((cc-nu)/4/ome+k[1]), .z, ome, nu, k) 
							kt_cond2 = ID2fun(((cc-nu)/4/ome+k[1]), .z, ome, nu, k) 
							kt_cond3 = ID3fun(((cc-nu)/4/ome+k[1]), .z, ome, nu, k) 
							kt_cond = (kt_cond1 >= 0) & (kt_cond2 >= 0) & (kt_cond3 >= 0)
						}
						else kt_cond = 1
						// If Kuhn-Tucker Conditions fail, find cumulants that maximize the critical value at alfa numerically
						if (kt_cond != 1) {
							if (N > 1) {
								knew = argminCV1fun(k, alpha)
								k = knew
							}
							else {	
								knew = argminCV2fun(k, alpha)
								k[2..3] = knew
							}
							ome = k[2] / k[3]
							nu = 8 * k[2] * ome^2
							cc = invchi2(nu,1-alpha)	
						}
						if (j == 1) result.cv1[i1,i2] = ((cc - nu) / (4 * ome) + k[1]) / K
						else if (j == 2) result.cv2[i1,i2] = ((cc - nu) / (4 * ome) + k[1]) / K
					}
					else if (j == 3) result.cv3[i1,i2] = invnchi2(K, K*lmin, 1-alpha) / K
				}
			}
		}
		
		return(result)
	}
	
	struct objresult {
		real scalar fval
		real matrix gradient
	}
	
	struct objresult scalar objL0(x, M1, M2PsiM2, X1, N, K) {
		real scalar fval, k
		real matrix gradient, g, L0, vecL0, QLL, Mobj, Qobj, Dobj, ev
		struct objresult scalar result
		
		L0 = x'
		vecL0 = vec(L0)
		QLL = (I(N) # L0) # L0
		Mobj = M1 * QLL * M2PsiM2 * QLL' * M1' / K
		Mobj = 0.5 * (Mobj + Mobj')
		Mobj = nearestSPD(Mobj)
		Qobj = 1; Dobj = 1
		symeigensystem(Mobj, Qobj, Dobj)
		Dobj = diag(Dobj)
		ev = Qobj[.,1]
		fval = - ev' * Mobj * ev
		g = 2 * ((ev' * M1 * QLL * M2PsiM2) # (ev' * M1)) * X1 * (I(N * K) # vecL0)
		g = vec(g)
		gradient = J(N,K,0)
		for (k=1;k<=K;k++) gradient[.,k] = g[(k-1)*N+1..k*N]
		gradient = - 1 * gradient'

		result.fval = fval
		result.gradient = gradient
		return(result)
	}
	
	real matrix Kgen(m,n) {
		real scalar mm, nn
		real matrix K
		
		K = J(m*n, m*n, 0)
		for (nn=1;nn<=n;nn++) for (mm=1;mm<=m;mm++) K[nn+(mm-1)*n,(nn-1)*m+mm] = 1
		return(K)
	}
	
	real scalar OptStiefelGBB(X, M1, M2PsiM2, X1, mxitr, xtol, gtol, ftol, eta, gamma, nt, tiny, ttau, rhols) {
		real scalar N, K, F, nrmG, Q, Cval, itr, XP, FP, GP, nls, deriv, XDiff, FDiff, SY, Qp
		real matrix crit, G, GX, dtX, dtXP, S, Y, mcrit
		struct objresult scalar result
		
		K = rows(X); N = cols(X)
		crit = J(mxitr, 3, 0)
		result = objL0(X, M1, M2PsiM2, X1, N, K)
		F = result.fval
		G = result.gradient
		GX = G' * X
		dtX = G - X * GX; nrmG = normfor(dtX)
		Q = 1; Cval = F

		for (itr=1;itr<=mxitr;itr++) {
			XP = X; FP = F; GP = G; dtXP = dtX
			nls = 1; deriv = rhols * nrmG^2
			while (nls <= 5) {
				X = myQR(XP - ttau * dtX)
				if (normfor(X' * X - I(N)) > tiny) X = myQR(X)
				result = objL0(X, M1, M2PsiM2, X1, N, K)
				F = result.fval
				G = result.gradient
				if (F <= Cval - ttau * deriv) break
				ttau = eta * ttau; nls = nls + 1
			}
			GX = G' * X
			dtX = G - X * GX; nrmG = normfor(dtX)
			S = X - XP; XDiff = normfor(S) / sqrt(K)
			FDiff = abs(FP - F) / (abs(FP) + 1)
			Y = dtX - dtXP
			SY = abs(sum(S :* Y))
			if (mod(itr, 2) == 0) ttau = (normfor(S))^2 / SY
			else ttau = SY / (normfor(Y))^2
			ttau = max((min((ttau, 1e20)), 1e-20))
			crit[itr,.] = (nrmG, XDiff, FDiff)
			mcrit = mean(crit[itr-min((nt,itr))+1..itr,.])
			if (((XDiff < xtol) & (FDiff < ftol)) | (nrmG < gtol) | ((mcrit[2] < 10 * xtol) & (mcrit[3] < 10 * ftol))) break
			Qp = Q; Q = gamma * Qp + 1; Cval = (gamma * Qp * Cval + F) / Q
		}
		
		return(F)
	}
	
	real matrix myQR(XX) { // cols(XX) <= rows(XX)
		real matrix Q, RR, diagRR
		real scalar k
		
		k = cols(XX); Q = 1; RR = 1
		qrd(XX, Q, RR)
		diagRR = sign(diagonal(RR))
		Q = Q[.,1..k] * diag(diagRR)
		
		return(Q)
	}
	
	real matrix nearestSPD(A) { // the nearest (in Frobenius norm) Symmetric Positive Definite matrix to A
		real scalar p, k, mineig
		real matrix Ahat, B, U, Sigma, V, H
		
		B = (A + A') / 2
		U = 1; Sigma = 1; V = 1
		svd(B, U, Sigma, V)
		H = V' * diag(Sigma) * V
		Ahat = (B + H) / 2
		Ahat = (Ahat + Ahat') / 2
		p = 1
		k = 0
		while (p == 1) {
			mineig = min(symeigenvalues(Ahat))
			if (mineig > 0) p = 0
			else {
				k = k + 1
				Ahat = Ahat + (- mineig * k^2 + epsilon(mineig)) * I(rows(A))
			}
			
		}
		
		return(Ahat)
	}
	
	
	real scalar fun_phiz(z, ome, nu, k) {
		return(ome * (1 + (z - k[1]) / (2 * k[2] * ome))^(nu / 2 - 1) * exp(- nu / 2 * (1 + (z - k[1]) / (2 * k[2] * ome))) * nu^(nu / 2 - 1) / (2^(nu / 2 - 2)) / gamma(nu / 2))
	}
	
	real scalar G1fun(q, nu) {
		return(- 1 / 2 * (q - 2 * nu * (nu-2) / q + nu) + 3 * nu / 2 * ((log(q / 2)) - digamma(nu/2)))
	}
	
	real scalar G2fun(q, nu) {
		return(1 / 2 * (q - nu * (nu - 2) / q) - nu * ((log(q / 2)) - digamma(nu/2)))
	}
	
	real scalar D1fun(q, ome, nu, k) {
		return((1 + (q - k[1]) * 2 * ome) / (2 * k[2] * ome) * (1 + (q - k[1]) / (2 * k[2] * ome))^(-1) * fun_phiz(q, ome, nu, k))
	}

	real scalar D2fun(q, ome, nu, k) {
		return(fun_phiz(q, ome, nu, k) / k[2] * G1fun(nu+(q-k[1])*4*ome, nu))
	}

	real scalar D3fun(q, ome, nu, k) {
		return(G2fun(nu+(q-k[1])*4*ome, nu) / k[3] * fun_phiz(q, ome, nu, k))
	}
	
	real scalar ID1fun(a, b, ome, nu, k) {
		class Quadrature scalar q
		
		q = Quadrature()
		q.setEvaluator(&D1fun())
		q.setLimits((a, b))
		q.setArgument(1, ome)
		q.setArgument(2, nu)
		q.setArgument(3, k)
		
		return(q.integrate())
	}
	
	real scalar ID2fun(a, b, ome, nu, k) {
		class Quadrature scalar q
		
		q = Quadrature()
		q.setEvaluator(&D2fun())
		q.setLimits((a, b))
		q.setArgument(1, ome)
		q.setArgument(2, nu)
		q.setArgument(3, k)
		
		return(q.integrate())
	}
	
	real scalar ID3fun(a, b, ome, nu, k) {
		class Quadrature scalar q
		
		q = Quadrature()
		q.setEvaluator(&D3fun())
		q.setLimits((a, b))
		q.setArgument(1, ome)
		q.setArgument(2, nu)
		q.setArgument(3, k)
		
		return(q.integrate())
	}
 
	void CV1fun(todo, real matrix x, alfa, k, obj, g, H) {
		real scalar cv1, penalty
		
		cv1 = -((invchi2(8*x[2]*(x[2]/x[3])^2, 1-alfa) - 8 * x[2] * (x[2] / x[3])^2) / 4 / (x[2] / x[3]) + x[1])
// 		penalty = 1e5 * ((max((x[1]-k[1],0)))^2 + (max((x[2]-k[2],0)))^2 + (max((x[3]-k[3],0)))^2 + (max((0.01-x[1],0)))^2 + (max((0.01-x[2],0)))^2 + (max((0.01-x[3],0)))^2)
		penalty = 1e10 * ((max((x[1]-k[1],0)))^3 + (max((x[2]-k[2],0)))^3 + (max((x[3]-k[3],0)))^3 + (max((0.01-x[1],0)))^3 + (max((0.01-x[2],0)))^3 + (max((0.01-x[3],0)))^3)
		obj = cv1 + penalty // objective function
	}
	
	void CV2fun(todo, real matrix x, alfa, k, obj, g, H) {
		real scalar cv2, penalty
		
		cv2 = -((invchi2(8*x[1]*(x[1]/x[2])^2, 1-alfa) - 8 * x[1] * (x[1] / x[2])^2) / 4 / (x[1] / x[2]) + k[1])
		penalty = 1e5 * ((max((x[1]-k[1],0)))^2 + (max((x[2]-k[2],0)))^2 + (max((0.01-x[1],0)))^2 + (max((0.01-x[2],0)))^2)
		obj = cv2 + penalty // objective function
	}
	
	real matrix argminCV1fun(k, alfa) {
		real scalar errcode
		real matrix knew, deltas
		transmorphic S

		S = optimize_init()
		optimize_init_which(S, "min")
		optimize_init_evaluator(S, &CV1fun())
		optimize_init_evaluatortype(S, "d0")
		optimize_init_argument(S, 1, alfa)
		optimize_init_argument(S, 2, k)
		optimize_init_tracelevel(S, "none")
		optimize_init_verbose(S, 0)
		optimize_init_conv_warning(S, "off")
		optimize_init_params(S, k')
		
		deltas = - (k[1]*0.9, k[2]*0.9, k[3]*0.9)
		optimize_init_technique(S, "nm")
		optimize_init_nmsimplexdeltas(S, deltas)
		errcode = _optimize(S)
		
		if (errcode != 0) {
			optimize_init_technique(S, "nr")
			errcode = _optimize(S)
			if (errcode != 0) {
				optimize_init_technique(S, "bgfs")
				errcode = _optimize(S)
				if (errcode != 0) {
					optimize_init_technique(S, "dfp")
					errcode = _optimize(S)
					if (errcode != 0) {
						optimize_init_technique(S, "bhhh")
						errcode = _optimize(S)
						if (errcode != 0) {
							errprintf("Kuhn-Tucker Conditions fail and cumulants that maximize the critical value at alfa cannot be found numerically.\n")
							exit(198)		
						}
					}
				}
			}
		}
		
		knew = optimize_result_params(S)
		return(knew')
	}
	
	real matrix argminCV2fun(k, alfa) {
		real matrix knew
		real scalar errcode
		transmorphic S

		S = optimize_init()
		optimize_init_which(S, "min")
		optimize_init_evaluator(S, &CV2fun())
		optimize_init_evaluatortype(S, "d0")
		optimize_init_argument(S, 1, alfa)
		optimize_init_argument(S, 2, k[2..3])
		optimize_init_tracelevel(S, "none")
		optimize_init_verbose(S, 0)
		optimize_init_conv_warning(S, "off")
		optimize_init_params(S, (k[2..3])')
		
		deltas = - (k[2]*0.9, k[3]*0.9)
		optimize_init_technique(S, "nm")
		optimize_init_nmsimplexdeltas(S, deltas)
		errcode = _optimize(S)
		
		if (errcode != 0) {
			optimize_init_technique(S, "nr")
			errcode = _optimize(S)
			if (errcode != 0) {
				optimize_init_technique(S, "bgfs")
				errcode = _optimize(S)
				if (errcode != 0) {
					optimize_init_technique(S, "dfp")
					errcode = _optimize(S)
					if (errcode != 0) {
						optimize_init_technique(S, "bhhh")
						errcode = _optimize(S)
						if (errcode != 0) {
							errprintf("Kuhn-Tucker Conditions fail and cumulants that maximize the critical value at alfa cannot be found numerically.\n")
							exit(198)		
						}
					}
				}
			}
		}
		
		knew = optimize_result_params(S)
		return(knew')
	}
	
// 	real scalar dinvchi2(df, x) {
// 		return(1/chi2den(df,invchi2(df,x)))
// 	}
//	
// 	real scalar d2invchi2(df, x) {
// 		return(-(df/(2*invchi2(df,x))-1/2)*(1/chi2den(df,invchi2(df,x)))^2)
// 	}
end
