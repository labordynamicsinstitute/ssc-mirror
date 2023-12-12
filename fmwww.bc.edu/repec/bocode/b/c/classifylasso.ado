// Package for Classifier-Lasso (Liangjun Su, Zhentao Shi, Peter C.B. Phillips (2016))
// Author: Wenxin HUANG, Yiru WANG, Lingyun ZHOU

cap program drop classifylasso
cap program drop Estimate
cap program drop Replay
program define classifylasso, eclass

    version 17.0

	if replay() {
		Replay `0'
	}
	else {
		cap noi Estimate `0'
	}
	
end

program define Estimate, eclass
	syntax [varlist] [if] [in] [,						 ///
		/// *************** Optimization *************** ///
		Grouplist(string) 						 		 /// possible numbers of groups; default is group(2)
		LAMbda(real 0.2) 								 /// tuning parameter for classification; default is lambda(0.2)
		rho(real 0.67)									 /// tuning parameter for selection; default is rho(0.67)
		TOLerance(real 0.01) 							 /// convergence criterion; default is tolerance(0.01)
		MAXITerations(integer 20) 						 /// maximum iteration; default is maxiterations(20)
		OPTPtol(real 1e-6) 				    		     /// optimization options
		OPTVtol(real 1e-7) 					  		     /// optimization options
		OPTNRtol(real 1e-5) 				     	     /// optimization options
		OPTMAXiter(real 150) 				     		 /// optimization options
		OPTIGNorenrtol(string) 						     /// optimization options
		OPTTECHnique(string) 							 /// optimization options
		OPTSINGularHmethod(string)						 /// optimization options
		/// **************** Regression **************** ///
		Absorb(varlist) NOAbsorb						 /// categorical variables that identify the fixed effects to be absorbed
		vce(string)	Robust CLuster(string)  			 /// vcetype may be ols, robust, cluster clustvar, bootstrap, jackknife, hc2, or hc3
		DYnamic											 /// use half panel Jackknife and HAC standard error in post-Lasso estimation
		NOTABle1										 ///
		*												 ///
	] 													 ///

	timer clear
	timer on 1
	
	* Panel structure
	cap tsset
	if _rc {
		di as err "panel and time variable not set, use -tsset panelvar timevar [, options]"
		exit 101
	}
    loc panelvar "`r(panelvar)'"
    loc timevar  "`r(timevar)'"
	marksample touse
	qui gsort -`touse' `panelvar' `timevar'
	preserve
	qui keep if `touse'
	if ("`dynamic'" != "") {
		tempname subpanel
		qui xtset `panelvar' `timevar'
		qui gen `subpanel' = 1 if `timevar' <= floor((`r(tmins)'+`r(tmaxs)' - 1)/2)
		qui replace `subpanel' = 2 if `subpanel' == .
	}
	
	* Group selection
	if ("`grouplist'" == "") 				loc grouplist = 2
	foreach k of numlist `grouplist' {
		loc numK = `numK' + 1
		loc groupnumlist `groupnumlist' `k'
	}
	
	* Optimize options
	if ("`optignorenrtol'" == "")			loc optignorenrtol off
	if ("`opttechnique'" == "")				loc opttechnique bfgs
	if ("`optsingularHmethod'" == "")		loc optsingularHmethod m-marquardt
	if (`rho' <= 0 | `lambda' <= 0) 		di as err "Tuning parameter should be a positive number."
	if (`tolerance' <= 0) 					di as err "Convergence criterion should be a positive number."
	if (`maxiterations' <= 0) 				di as err "Maximum iteration should be a positive integer."
	if (`maxiterations'<= 0 | `rho' <= 0 | `lambda' <= 0 | `tolerance' <= 0) exit
	
	* Standard error
	if ("`cluster'" != "") 					loc vce cluster `cluster'
	if ("`robust'" != "") 					loc vce robust
	if ("`vce'" == "") 						loc vce ols
	
	* Fixed effects
	if ("`absorb'" == "" & "`noabsorb'" == "") loc absorb `panelvar'
	if ("`absorb'" != "" & "`noabsorb'" == "") loc fe a(`absorb')
	else if ("`absorb'" == "" & "`noabsorb'" != "") loc fe noabsorb
	else di as err "absorb() and noabsorb cannot appear simultaneously."
	foreach v in `varlist' {
		tempvar `v'_mean `v'_temp `v'1 `v'2 `v'3 `v'4
		loc varlist1 `varlist1' ``v'1' // zero-mean
		loc varlist2 `varlist2' ``v'2' // FWL
		loc varlist3 `varlist3' ``v'3' // zero-mean, by group
		loc varlist4 `varlist4' ``v'4' // FWL, by group
		qui egen ``v'_mean' = mean(`v')
		qui reghdfe `v', `fe' residuals(``v'1')
		qui gen ``v'2' = ``v'1' + ``v'_mean'
	}
	
	* Transfer data to mata
	cap tsset `panelvar' `timevar'
	qui xtdescribe
	loc N = r(N)
	loc obs = r(sum)	
	gettoken depvar indepvar: varlist
	loc indepvar`indepvar'
	loc p = 1
	foreach v in `indepvar' {
		loc p = `p' + 1
	}
	sort `panelvar' `timevar'
	order `varlist' `panelvar' `timevar'
	mata: Y = st_data(.,1) // original data
	mata: X = st_data(.,(2..`p')), J(`obs',1,1)
	mata: panelvar = st_data(.,`p'+1)
	mata: timevar = st_data(.,`p'+2)
	mata: tlist = gentlist(panelvar, `N')
	mata: tidx = cum(tlist)
	sort `panelvar' `timevar'
	order `varlist1' `panelvar' `timevar'
	mata: Y1 = st_data(.,1) // de-meaned (zero mean)
	mata: X1 = st_data(.,(2..`p'))
	order `varlist2' `panelvar' `timevar'
	mata: Y2 = st_data(.,1) // de-meaned (FWL)
	mata: X2 = st_data(.,(2..`p')), J(`obs',1,1)
	mata: lambda 	 = `lambda' * (`obs' / `N')^(-1/3)
	mata: rho 		 = `rho' * `obs'^(-1/2)

	* Estimation & Group Selection
	mata: mata set mataoptimize on
	mata: mata set matafavor speed
	mata: selection = J(`numK', 4, 0), J(`numK',1,`maxiterations') // groupNum IC lnMSE iter maxIter
	tempname id tlist selection numiter time groupstar b0 Kmax groupvar gidmat
	mat define `time' = J(`numK',1,0)
	mata: st_matrix("`tlist'", tlist)
	foreach K of numlist `grouplist' {
		loc k = `k' + 1
		if (`numK' > 1) di as text "Estimation " as result `k' as text ": " _col(15) as text "Group Number = " as result `K' as text "; Iteration: " _continue
		else di as text "Iteration: " _continue
		timer on 2
		tempname a_classo_G`K' a_post_G`K' V_classo_G`K' V_post_G`K' group_id_G`K' df_G`K' rsq_G`K' rsq_classo_G`K' rsq_post_G`K' a_post_G`K'_1 a_post_G`K'_2
		* Classifier-Lasso
		if (`K' > 1) {
			mata: classo(Y1, X1, tidx, `K', lambda, /* data
			*/ `tolerance', `maxiterations', `optptol', `optvtol', `optnrtol', `optmaxiter', /* optimize options
			*/ "`optignorenrtol'", "`opttechnique'", "`optsingularHmethod'", /* optimize options
			*/ "`numiter'", "`a_classo_G`K''", "`group_id_G`K''") // returns
			mata: a_classo = st_matrix("`a_classo_G`K''")
			mata: group_id = st_matrix("`group_id_G`K''")
			mata: a_classo = updatea(a_classo, group_id, Y2, X2, tidx)
			mata: st_matrix("`a_classo_G`K''", a_classo)
		}
		else {
			mata: a_classo = (pinv(X2' * X2) * X2' * Y2)'
			mata: st_matrix("`a_classo_G`K''", a_classo)
			mat `group_id_G`K'' = J(`N',1,1)
			mata: group_id = st_matrix("`group_id_G`K''")
			scalar `numiter' = 0
		} // a_classo_GK
		di as text "√"
		if ("`dynamic'" != "") mata: inference_dynamic(Y2, X2, timevar, tidx, a_classo, group_id, "`V_classo_G`K''")
		else mata: inference_static(Y2, X2, tidx, a_classo, group_id, "`V_classo_G`K''") // V_classo_GK
		mata: st_numscalar("`Kmax'", max(group_id))
		loc maxK = `Kmax'
		forvalues i = 1/`N' {
			loc ti = `tlist'[`i',1]
			if (`i' == 1) mat define `gidmat'  = `group_id_G`K''[`i',1] * J(`ti', 1, 1)
			else mat `gidmat' = `gidmat' \ `group_id_G`K''[`i',1] * J(`ti', 1, 1)
		}
		sort `panelvar' `timevar'
		cap drop `groupvar'
		svmat `gidmat', names("`groupvar'")
		* Post-Lasso
		mat define `df_G`K'' = J(`K',6,0)
		forvalues kk = 1/`maxK' {
			qui reghdfe `varlist' if `groupvar' == `kk', vce(`vce') `fe'
			if (`kk' == 1) mat define `a_post_G`K'' = e(b) // a_post_GK
			else mat `a_post_G`K'' = `a_post_G`K'' \ e(b)
			if (`kk' == 1) mat define `V_post_G`K'' = e(V) // V_post_GK
			else mat `V_post_G`K'' = `V_post_G`K'' \ e(V)
			mat `df_G`K''[`kk',1] = e(N)
			mat `df_G`K''[`kk',2] = e(df_m) // model degrees of freedom
			mat `df_G`K''[`kk',3] = e(df_r) // residual degrees of freedom
			mat `df_G`K''[`kk',4] = e(df_a) // degrees of freedom lost due to the fixed effects
			mat `df_G`K''[`kk',5] = round(e(rss)/(e(rmse)*e(rmse))) // residual degrees of freedom
			mat `df_G`K''[`kk',6] = e(N) - `df_G`K''[`kk',5] - `p' + 1 // degrees of freedom lost due to the fixed effects
		}
		mata: a_post = st_matrix("`a_post_G`K''")
		foreach v in `varlist' {
			cap drop ``v'_mean'
			bysort `groupvar': egen ``v'_mean' = mean(`v')
			cap drop ``v'3' ``v'4'
			gen ``v'3' = `v'
			gen ``v'4' = `v'
			forvalues kk = 1/`maxK' {
				cap drop ``v'_temp'
				qui reghdfe `v' if `groupvar' == `kk', `fe' residuals(``v'_temp')
				qui replace ``v'3' = ``v'_temp' if `groupvar' == `kk'
				qui replace ``v'4' = ``v'3' + ``v'_mean' if `groupvar' == `kk'
			}
		}
		sort `panelvar' `timevar'
		order `varlist3' `panelvar' `timevar'
		mata: Y3 = st_data(.,1) // de-meaned by group (zero mean)
		mata: X3 = st_data(.,(2..`p'))
		order `varlist4' `panelvar' `timevar'
		mata: Y4 = st_data(.,1) // de-meaned by group (FWL)
		mata: X4 = st_data(.,(2..`p')), J(`obs',1,1)
		if ("`dynamic'" != "") {
			if ("`vce'" == "ols") mata: inference_dynamic(Y4, X4, timevar, tidx, a_post, group_id, "`V_post_G`K''") // V_post_GK
			forvalues kk = 1/`maxK' {
				qui reghdfe `varlist' if `groupvar' == `kk' & `subpanel' == 1, `fe'
				if (`kk' == 1) mat define `a_post_G`K'_1' = e(b) 
				else mat `a_post_G`K'_1' = `a_post_G`K'_1' \ e(b)
				qui reghdfe `varlist' if `groupvar' == `kk' & `subpanel' == 2, `fe'
				if (`kk' == 1) mat define `a_post_G`K'_2' = e(b) 
				else mat `a_post_G`K'_2' = `a_post_G`K'_2' \ e(b)
			}
			mat `a_post_G`K'' = 2 * `a_post_G`K'' - 0.5 * (`a_post_G`K'_1' + `a_post_G`K'_2')
			mata: a_post = st_matrix("`a_post_G`K''") // a_post_GK
		}
		mata: df = st_matrix("`df_G`K''")
		mata: selection[`k',1] = `K'
		mata: selection[`k',2] = ln(mse(Y4, X4, tidx, a_post, group_id, df))
		mata: selection[`k',3] = selection[`k',2] + rho * (`p' - 1) * `K'
		mata: selection[`k',4] = st_numscalar("`numiter'")
		di as text "Information Criterion = " _continue
		mata: printf("%f\n", selection[`k',3])
		mata: rsq = rsquared(Y4, X4, Y, X, tidx, a_classo, a_post, group_id, df)
		mata: st_matrix("`rsq_G`K''",rsq)
		mat `rsq_classo_G`K'' = `rsq_G`K''[....,1..5]
		mat `rsq_post_G`K'' = `rsq_G`K''[....,6..10]
		timer off 2
		qui timer list
		mat `time'[`k',1] = r(t2)
		timer clear 2
	}
	mata: estid = 0
	mata: w = 0
	mata: minindex(selection[.,3], 1, estid, w)
	mata: st_numscalar("`groupstar'", selection[estid,1])
	if (`numK' > 1) di as text "* Selected Group Number: " as result `groupstar'

	* ereturn list
	// e(selection)
	mata: st_matrix("`selection'", selection)
	mat `selection' = `selection', `time'
	mat colnames `selection' = groupNum lnMSE IC iter maxIter time
	// e(id)
	qui levelsof `panelvar', local(levels)
	tokenize `levels'
	mat define `id' = J(`N',1,0)
	forvalues i = 1/`N' {
		mat `id'[`i',1] = ``i''
	}
	loc idcolname
	foreach K of numlist `grouplist' {
		mat `id' = `id', `group_id_G`K''
		loc idcolname `idcolname' GID_G`K'
	}
	mata: st_matrix("`b0'", rowshape(initbeta(Y2, X2, tidx), `N'))
 	mat `id' = `id', `b0', `tlist'
	mat colnames `id' = ID `idcolname' `indepvar' _cons T
	// e(a) and e(V)
	foreach K of numlist `grouplist' {
		loc Ktrue = rowsof(`a_post_G`K'')
		if (`Ktrue' < `K') {
			foreach esttype in classo post {
				mat `a_`esttype'_G`K'' = `a_`esttype'_G`K'' \ J(`K'-`Ktrue',`p',.)
				mat `V_`esttype'_G`K'' = `V_`esttype'_G`K'' \ J(`p'*(`K'-`Ktrue'),`p',.)
			}
		}
		loc arownames
		loc Vrownames
		forvalues k = 1/`K' {
			loc arownames `arownames' G`k'
			foreach v in `indepvar' _cons {
				loc Vrownames `Vrownames' G`k'_`v'
			}
		}
		foreach esttype in classo post {
			mat colnames `a_`esttype'_G`K'' = `indepvar' _cons
			mat rownames `a_`esttype'_G`K'' = `arownames'
			mat colnames `rsq_`esttype'_G`K'' = R-sq. "Adj R-sq." "Within R-sq." "Adj Within R-sq." RMSE
			mat rownames `rsq_`esttype'_G`K'' = `arownames'
			mat colnames `V_`esttype'_G`K'' = `indepvar' _cons
			mat rownames `V_`esttype'_G`K'' = `Vrownames'
		}
		mat colnames `df_G`K'' = obs df_m df_r df_a df_r_noc df_a_noc
		mat rownames `df_G`K'' = `arownames'
	}
	return clear
	restore
	ereturn post, esample(`touse') buildfvinfo depname(`depvar')
	ereturn scalar obs = `obs'
	ereturn scalar N = `N'
	ereturn scalar group = `groupstar'
	ereturn local coef = "postselection"
	ereturn local grouplist = "`groupnumlist'"
	if ("`absorb'" != "") ereturn local absvar = "`absorb'"
	else ereturn local absvar = "_cons"
	ereturn local indepvar = "`indepvar'"
	ereturn local depvar = "`depvar'"
	ereturn local timevar = "`timevar'"
	ereturn local panelvar = "`panelvar'"
	ereturn local cmdline = "classifylasso `0'"
	ereturn local predict = "classifylasso_p"
	ereturn local cmd = "classifylasso"
	ereturn local title = "Classify-Lasso"
	foreach K of numlist `grouplist' {
		ereturn matrix rsq_post_G`K' = `rsq_post_G`K''
		ereturn matrix V_post_G`K' = `V_post_G`K''
		ereturn matrix a_post_G`K' = `a_post_G`K''
		ereturn matrix rsq_classo_G`K' = `rsq_classo_G`K''
		ereturn matrix V_classo_G`K' = `V_classo_G`K''
		ereturn matrix a_classo_G`K' = `a_classo_G`K''
		ereturn matrix df_G`K' = `df_G`K''
	}
	ereturn matrix selection = `selection'
	ereturn matrix id = `id'

	* Clear
	timer off 1
	tempname seconds minutes hours
	di as text "The algorithm takes " _continue
	qui timer list
	scalar `seconds' = r(t1)					
	if (`seconds' < 60) di as result %3.2f `seconds' as text "s."
	else if (`seconds' < 3600) {
		scalar `minutes' = floor(`seconds'/60)
		scalar `seconds' = `seconds' - `minutes' * 60
		di as result %1.0f `minutes' as text "min" as result %1.0f `seconds' as text "s."
	}
	else {
		scalar `hours' = floor(`seconds'/3600)
		scalar `minutes' = floor((`seconds' - `hours' * 3600)/60)
		scalar `seconds' = `seconds' - `hours' * 3600 - `minutes' * 60
		di as result %1.0f `hours' as text "h" as result %1.0f `minutes' as text "min" as result %1.0f `seconds' as text "s."
	}
	timer clear
	
	* Display table
	if ("`notable'" == "") {
		di as text ""
		 _get_diopts diopts options, `options' // store in `diopts', and the rest back to `options'
		Replay, `diopts'
	}
end

program define Replay, eclass
	version 17.0
	
	syntax [if] [in] [, OUTreg2(string)	*]
	
	 _get_diopts diopts options, `options' // store in `diopts', and the rest back to `options'

	loc group = e(group)
	* save ereturn list
	tempfile ereturnlist
	qui estimates save `ereturnlist'
	tempvar touse
	qui gen `touse' = 1 if e(sample)
	qui replace `touse' = 0 if `touse' == .
	* generate matrix
	tempname a number
	if ("`e(coef)'" == "postselection") loc esttype post
	else loc esttype classo
	loc p = 0
	mat `a' = e(a_classo_G`group')
	local indepvar: colname `a'
	loc p = colsof(`a')
	loc N = e(N)
	loc rownames
	forvalues k = 1/`group' {
		tempname a`k' V`k'
		mat define `a`k'' = e(a_`esttype'_G`group')[`k',....]
		mat define `V`k'' = e(V_`esttype'_G`group')[(`k'-1)*`p'+1..`k'*`p',....]
		mat colnames `a`k'' = `indepvar'
		mat rownames `a`k'' = `e(depvar)'
		mat colnames `V`k'' = `indepvar'
		mat rownames `V`k'' = `indepvar'
	}
	mat define `number' = J(`group',1,0)
	forvalues i = 1/`N' {
		forvalues k = 1/`group' {
			if (e(id)[`i',"GID_G`group'"] == `k') {
				mat `number'[`k',1] = `number'[`k',1] + 1
			}
		}
	}
	* header
	local width 78
	local colwidths 1 14 51 67
	local i 0
	foreach c of local colwidths {
		local ++i
		local c`i' `c'
		local C`i' _col(`c')
	}

	local c2wfmt 6
	local c4wfmt 10
	local c4wfmt1 = `c4wfmt' + 1
	
	di as text `C1' "Classifier-Lasso linear model" `C3' "Number of obs" `C4' "= " as res %`c4wfmt'.0fc e(obs)
	if (e(group) > 1) loc plural s
	if ("`esttype'" == "post") di as text `C1' "Postestimation with " as text e(group) as text " group`plural'" `C3' "Number of units" `C4' "= " as res %`c4wfmt'.0fc e(N)
	else di as text `C1' "PLS estimation with " as text e(group) as text " group`plural'" `C3' "Number of units" `C4' "= " as res %`c4wfmt'.0fc e(N)
	di as text ""
	* tables
	forvalues k = 1/`group' {
		if (`number'[`k',1] == 0) {
			estimates use `ereturnlist'
			if ("`e(absvar)'" == "_cons") di as text "Linear estimation with Group `k' (Empty)"
			else di as text `C1' "Fixed effect estimation with Group `k' (Empty)"
		}
		else {
			estimates use `ereturnlist'
			loc obsk = e(df_G`group')[`k',1]
			* row 1
			if ("`e(absvar)'" == "_cons") di as text "Linear estimation with Group `k'" _continue
			else di as text `C1' "Fixed effect estimation with Group `k'" _continue
			di as text `C3' "R-squared" `C4' "= " as res %`c4wfmt'.4fc e(rsq_`esttype'_G`group')[`k',1]
			* row 2
 			if ("`e(absvar)'" == "_cons") di as text "" _continue
			else di as text "Absorbing: " as result "`e(absvar)'" _continue
			di as text `C3' "Adj R-squared" `C4' "= " as res %`c4wfmt'.4fc e(rsq_`esttype'_G`group')[`k',2]
			* row 3
			di as text `C1' "No. of obs" `C2' "= " as res %`c2wfmt'.0fc `obsk' _continue
			di as text `C3' "Within R-sq." `C4' "= " as res %`c4wfmt'.4fc e(rsq_`esttype'_G`group')[`k',3]
			* row 4
			di as text `C1' "No. of units" `C2' "= " as res %`c2wfmt'.0fc `number'[`k',1] _continue
			di as text `C3' "Root MSE" `C4' "= " as res %`c4wfmt'.4fc e(rsq_`esttype'_G`group')[`k',5]
			ereturn post `a`k'' `V`k'', buildfvinfo depname(`e(depvar)') obs(`obsk')
			ereturn display, `diopts'
			if ("`outreg2'" != "") outreg2 using `outreg2'
		}
	}
	* reload ereturn list
	estimates use `ereturnlist'
	estimates esample: if `touse' == 1
end

findfile "classifylasso.mata"
include "`r(fn)'"
exit
