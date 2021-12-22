*! rcm 2.0.0 Guanpeng Yan and Qiang Chen 31/10/2021

cap program drop rcm
program rcm, eclass sortpreserve
	version 16
	preserve
	qui xtset
    if "`r(panelvar)'" == "" | "`r(timevar)'" == "" {
		di as err "panel variable or time variable missing, please use -{bf:xtset} {it:panelvar} {it:timevar}"
		exit 198
    }
	syntax varlist(min = 1) [if], TRUnit(integer) TRPeriod(integer) ///
		[CTRLUnit(numlist min = 1 int sort) ///
		PREPeriod(numlist min = 1 int sort) ///
		POSTPeriod(numlist min = 1 int sort) ///
		SCope(numlist min = 2 max = 2 int sort) ///
		CRiterion(string) Method(string) ///
		Estimate(string) ///
		fold(numlist min = 1 max = 1 int sort >3) ///
		grid(passthru) ///
		placebo(string) ///
		frame(string) ///
		seed(integer 1) ///
		fill(string) ///
		noFIGure ///
		]
	loc detail = ""
	loc panelVar "`r(panelvar)'"
	loc timeVar "`r(timevar)'"
	if "`criterion'" == "" loc criterion "aicc"
	if "`method'" == "" loc method "best"
	if "`estimate'" == "" loc estimate "ols"
	if "`fold'" == "" loc fold = .
	else loc fold = real("`fold'")
	/* Check varlist */
	foreach i in `varlist' {
		cap confirm numeric var `i'
		if _rc {
			di as err "{bf:`i'} should be a numeric variable in dataset"
			exit 198
		}
	}
	/* Check frame() */
	if "`frame'" == "" tempname frame
	else {
		cap frame drop `frame'
		qui pwf
		if "`frame'" == "`r(currentframe)'" {
			di as err "invalid frame() -- current frame can not be specified"
			exit 198
		}
		loc framename "`frame'"
	}
	/* Check trunit() */
	qui levelsof `panelVar', local(unit_n)
	loc check: list trunit in unit_n
	if `check' == 0 {
		di as err "invalid trunit() -- treatment unit not found in {it:panelvar}"
		exit 198
	}
	/* Check ctrlunit() */
	if "`ctrlunit'" != "" {
		loc check: list ctrlunit in unit_n
		if `check' == 0 {
			di as err "invalid ctrlunit() -- at least one control unit not found in {it:panelvar}"
			exit 198
		}
		loc check: list trunit in ctrlunit
		if `check' == 1 {
			di as err "invalid ctrlunit() -- treatment unit appears among control units"
			exit 198
		}
		foreach i in `unit_n'{
			loc check: list i in ctrlunit
			if `check' == 0 & `i' != `trunit' qui drop if `panelVar' == `i'
		}
	}
	/* Check trperiod() */
	qui levelsof `timeVar', local(time_n)
	loc check: list trperiod in time_n
	if `check' == 0 {
		di as err "invalid trperiod() -- treatment period not found in {it:timelvar}"
		exit 198
	}
	/* Check preperiod() */
	if "`preperiod'" != "" {
		qui levelsof `timeVar' if `timeVar' < `trperiod', local(time_pre)
		loc check: list preperiod in time_pre
		if `check' == 0 {
			di as err "invalid preperiod() -- at least one of pre-treatment periods that not found in {it:timevar} or not ahead of treatment period"
			exit 198
		}
		foreach i in `time_pre'{
			loc check: list i in preperiod
			if `check' == 0 qui drop if `timeVar' == `i'
		}
	}
	/* Check postperiod() */
	if "`postperiod'" != "" {
		qui levelsof `timeVar' if `timeVar' >= `trperiod', local(time_post)
		loc check: list posof "`trperiod'" in postperiod
		if `check' != 1 {
			di as err "invalid postperiod() -- treatment period should be the first period of post-treatment periods"
			exit 198
		}
		loc check: list postperiod in time_post
		if `check' == 0 {
			di as err "invalid postperiod() -- at least one of post-treatment periods not found in {it:timevar}"
			exit 198
		}
		foreach i in `time_post'{
			loc check: list i in postperiod
			if `check' == 0 qui drop if `timeVar' == `i'
		}
	}
	/* Check method() */
	if("`method'" != "best" & "`method'" != "forward" & "`method'" != "backward" & "`method'" != "lasso"){
		di as err "invaild method() -- sel_method must be one of {bf:best forward backward lasso}"
		exit 198
	}
	/* Check criterion() */
	if("`criterion'" != "aicc" & "`criterion'" != "aic" & "`criterion'" != "bic" & "`criterion'" != "mbic" & "`criterion'" != "cv"){
		di as err "invaild criterion() -- sel_criterion must be one of {bf:aicc aic bic mbic cv}"
		exit 198
	}
	if("`criterion'" == "cv" & "`method'" != "lasso"){
		di as err "invaild criterion() or estimate() -- criterion({bf:cv})} is only suitable for method({bf:lasso})"
		exit 198
	}
	if("`estimate'" != "ols" & "`estimate'" != "lasso"){
		di as err "invaild estimate() -- est_method must be one of {bf:ols lasso}"
		exit 198
	}
	if("`estimate'" == "lasso" & "`method'" != "lasso"){
		di as err "invalid method() or estimate() -- estimate({bf:lasso}) is only suitable for method({bf:lasso})"
		exit 198
	}
	/* Check fill() */
	if("`fill'" != "mean" & "`fill'" != "linear" & "`fill'" != ""){
		di as err "invaild fill() -- fil_method must be one of {bf:mean linear}"
		exit 198
	}
	/* Generate panelVarStr */
	tempvar panelVarStr 
	{
		cap decode `panelVar', gen(`panelVarStr')
		if _rc  qui tostring `panelVar', gen(`panelVarStr') usedisplayformat force
		else qui replace `panelVarStr' = subinstr(`panelVarStr', " ", "", .)
		qui replace `panelVarStr' = strtoname(`panelVarStr', 0) 
	}
	/* Obtain all units, the treated unit and the control units */
	qui levelsof `panelVarStr', local(unit_all) clean
	qui levelsof `panelVarStr' if `panelVar' != `trunit', local(unit_ctrl) clean
	qui levelsof `panelVarStr' if `panelVar' == `trunit', local(unit_tr) clean
	/* Obtain dependent variable and indepent variables */
	gettoken depvar indepvars : varlist
	tempvar fillmissing
	if("`fill'" != ""){
	    di _newline as txt "Data Setup: The number of missing values filled by " _continue
		if("`fill'" == "mean") di as txt "sample " as res "mean"_continue
		else if("`fill'" == "linear") di as res "linear" as txt " interpolation" _continue
		di as txt " grouped by " as res "`panelVar'"
	    loc nums : word count `varlist'
		matrix fillmissing = J(`nums', 2, .)
		matrix rownames fillmissing = `varlist'
		loc j = 1
		foreach i in `varlist'{
			qui count if `i' == . & `timeVar' < `trperiod'
			loc missing = r(N)
			matrix fillmissing[`j', 1] = `missing'
			qui count if `i' == . & `timeVar' >= `trperiod'
			loc missing = r(N)
			matrix fillmissing[`j', 2] = `missing'
			loc j = `j' + 1
			cap qui drop `fillmissing'
			if("`fill'" == "mean") qui by `panelVar' : egen `fillmissing' = mean(`i')
			else if ("`fill'" == "linear") qui by `panelVar' : ipolate `i' `timeVar', gen(`fillmissing') epolate
			qui replace `i' = `fillmissing' if `i' == .
		}
		mata: rcm_print(tokens("`varlist'")', ("Variable", "Pre-treatment", " Post-treatment"), ///
			st_matrix("fillmissing"), "", 0, (13, 13), 0, 1)
	}
	frame put `panelVarStr' `timeVar' `varlist', into(`frame')
	/* Implement regress control method */
	frame `frame' {
		tempvar timeVarStr
		qui reshape wide `varlist', i(`timeVar') j(`panelVarStr') string
		cap lab variable `timeVar' "time"
		foreach var of loc varlist {
			foreach unit of loc unit_all {
				rename `var'`unit' `var'·`unit'
				cap lab variable `var'·`unit' "`var' in `unit' "
			}
		}
		qui tsset `timeVar'
		qui tostring `timeVar', gen(`timeVarStr') usedisplayformat force
		qui levelsof `timeVarStr', local(time_all) clean
		qui levelsof `timeVarStr' if `timeVar' < `trperiod', local(time_pre) clean
		qui levelsof `timeVarStr' if `timeVar' >= `trperiod', local(time_post) clean
		qui levelsof `timeVarStr' if `timeVar' == `trperiod', local(time_tr) clean
		mata: rcm("`timeVar'", "`varlist'", "`unit_all'", "`unit_tr'", "`time_all'", "`time_tr'", ///
			"`criterion'", "`method'", "`estimate'","`scope'", "`detail'"== ""? 0 : 1, "`grid'", `fold', `seed')
		if _rc {
			exit
		}
		qui cap drop pred·`depvar'·`unit_tr'
		qui cap predict pred·`depvar'·`unit_tr'
		cap lab variable pred·`depvar'·`unit_tr' "prediction of `depvar' in `unit_tr'"
		qui cap drop tr·`depvar'·`unit_tr'
		qui gen tr·`depvar'·`unit_tr' = `depvar'·`unit_tr' - pred·`depvar'·`unit_tr'
		cap lab variable tr·`depvar'·`unit_tr' "treatment effect of `depvar' in `unit_tr'"
		mata: rcm_summary(st_sdata(., "`timeVarStr'"), st_data(., "`depvar'·`unit_tr' pred·`depvar'·`unit_tr'"), ///
			"`time_tr'", "`predvar_sel'", "`outvar'", "`estimate'", 0, .)
		if("`estimate'" == "ols"){
			regress, cformat(%8.4f) noheader
			loc regcmd "`e(cmd)'"
			loc regcmdline "`e(cmdline)'"
			matrix V = e(V)
		}
		else{
		    qui lassocoef, display(coef, standardized) sort(none)
			matrix standardized = r(coef)
			qui lassocoef, display(coef, penalized) sort(none)
			matrix penalized = r(coef)
			mata: rcm_print(st_matrixrowstripe("penalized")[., 2], ("`outvar'", "Penalized Coef.", "  Standardized Coef."), ///
				(st_matrix("penalized"), st_matrix("standardized")), "", 0, (18, 18), 0, 0)
		}
		mkmat `depvar'·`unit_tr' pred·`depvar'·`unit_tr' tr·`depvar'·`unit_tr' if `timeVar' >= `trperiod', rownames(`timeVar') matrix(pred)
		mat colnames pred = Treated Predicted TrEff
		scalar N = _N
		scalar T1 = N - T0
		matrix b = e(b)
		di _newline as txt "Prediction results in the post-treatment periods`tmp':"
		mata: rcm_print(st_sdata(., "`timeVarStr'"), ("Time", "Actual Outcome", " Predicted Outcome", " Treatment Effect"), ///
			st_data(., "`depvar'·`unit_tr' pred·`depvar'·`unit_tr' tr·`depvar'·`unit_tr'"), "`time_tr'", 1, (13, 17, 16), 0, 0)
	}
	loc graphlist ""
	if("`figure'" == ""){
		frame `frame' {
			qui levelsof `timeVar', local(temp) clean
			loc pos: list posof "`trperiod'" in temp
			loc pos = `pos' - 1
			loc xline: word `pos' of `temp'
			twoway (tsline `depvar'·`unit_tr') (tsline pred·`depvar'·`unit_tr', lpattern(dash)), ///
				title("Actual and Predicted Outcomes") xline(`xline', lp(dot) lc(black)) name(pred, replace) ///
				ytitle(`depvar')  legend(order(1 "Actual" 2 "Predicted")) nodraw
			tsline tr·`depvar'·`unit_tr', xline(`xline', lp(dot) lc(black)) yline(0, lp(dot) lc(black)) ///
				title("Treatment Effects") name(eff, replace) ///
				ytitle("treatment effects of `depvar'") nodraw
			loc graphlist = "`graphlist' pred eff"
		}
	}
	/* Implement placebo test using fake unit and/or time */
	if "`placebo'" != "" {
		ereturn loc trperiod "`trperiod'"
		if(strpos("`placebo'", "unit") != 0 & strpos("`placebo'", "unit(") == 0) loc placebo = subinstr("`placebo'", "unit", "unit(.)", .)
		rcm_placebo `varlist', trunit(`trunit') trperiod(`trperiod') panelVar(`panelVar') timeVar(`timeVar') panelVarStr(`panelVarStr') ///
			unit_all(`unit_all') unit_tr(`unit_tr') unit_ctrl(`unit_ctrl') ///
			time_tr(`time_tr') time_all(`time_all') ///
			scope(`scope') method(`method') criterion(`criterion') estimate(`estimate') ///
			`grid' fold(`fold') seed(`seed') frame(`frame')  ///
			`placebo' `figure'
		loc graphlist = "`graphlist' `e(graphlist)'"
		cap mat pval = e(pval)
	}
	/* Display graphs */
	if "`figure'" == "" foreach graph in `graphlist' {
		cap graph display `graph'
	}
	di _newline as txt "Finished."
	if("`estimate'" == "lasso") ereturn post b
	else ereturn post b V
	cap ereturn matrix pval = pval
	cap if rowsof(mspe) > 1 ereturn matrix mspe = mspe
	ereturn matrix info = info
	ereturn matrix pred = pred
	ereturn loc frame "`framename'"
	if("`method'" == "lasso"){
		ereturn loc seed "`seed'"
		if `fold' ==. ereturn loc fold = T0
		else ereturn loc fold = "`fold'"
		ereturn loc grid "`grid'"
	}
	ereturn loc estimate "`estimate'"
	ereturn loc criterion "`criterion'"
	ereturn loc method "`method'"
	ereturn loc scope "`scope'"
	ereturn loc regcmdline "`regcmdline'"
	ereturn loc regcmd "`regcmd'"
	ereturn loc time_post "`time_post'"
	ereturn loc time_pre "`time_pre'"
	ereturn loc time_tr "`time_tr'"
	ereturn loc time_all "`time_all'"
	ereturn loc unit_ctrl "`unit_ctrl'"
	ereturn loc unit_tr "`unit_tr'"
	ereturn loc unit_all "`unit_all'"
	ereturn loc predvar_sel "`predvar_sel'"
	ereturn loc predvar_all "`predvar_all'"
	ereturn loc outvar "`outvar'"
	ereturn loc varlist "`varlist'"
	ereturn loc timevar "`timeVar'"
	ereturn loc panelvar "`panelVar'"
	ereturn scalar N = N
	ereturn scalar T0 = T0
	ereturn scalar T1 = T1
	ereturn scalar K_preds_all = k_predvar
	ereturn scalar K_preds_sel = k_predvar_sel
	ereturn scalar aicc = aicc
	ereturn scalar aic = aic
	ereturn scalar bic = bic
	ereturn scalar mbic = mbic
	cap ereturn scalar cvmse = cv
	ereturn scalar mae = mae
	ereturn scalar mse = mse
	ereturn scalar rmse = rmse
	ereturn scalar r2 = r2
end

cap program drop rcm_placebo
program rcm_placebo, eclass sortpreserve
	version 16
	loc trperiod = `e(trperiod)'
	syntax varlist, trunit(numlist) trperiod(numlist) [panelVar(string) timeVar(string) panelVarStr(string) ///
		unit_all(string) unit_tr(string) unit_ctrl(string) ///
		time_all(string) time_tr(string) ///
		scope(string) method(string) criterion(string) estimate(string) ///
		grid(passthru) fold(numlist missingokay) seed(numlist) frame(string) ///
		unit(numlist missingokay) period(numlist min = 1 int sort <`trperiod') Cutoff(numlist min = 1 max = 1 >=1) noFIGure]
	
	gettoken depvar indepvars : varlist
	loc graphlist ""
	if("`unit'" != "."){
		loc unit_ctrl ""
		foreach i in `unit'{
			qui levelsof `panelVarStr' if `panelVar' == `i', local(temp) clean
			loc unit_ctrl "`unit_ctrl' `temp'"
		}
	}
	frame `frame'{
		tempvar timeVarStr
		qui tostring `timeVar', gen(`timeVarStr') usedisplayformat force
		qui levelsof `timeVar' if `timeVarStr' == "`time_tr'", local(trperiod) clean
		qui levelsof `timeVar', local(temp) clean
		loc pos: list posof "`trperiod'" in temp
		loc pos = `pos' - 1
		loc xline_tr: word `pos' of `temp'
		if("`unit'" != ""){	
			di _newline as txt "Implementing placebo test using fake treatment unit " _continue
			loc tsline ""
			loc unit_ctrl_sel ""
			loc unit_ctrl_dis ""
			foreach unit_placebo in `unit_ctrl'{
				loc unit_tmp "`unit_placebo'"
				di as res "`unit_placebo'"  as txt "..." _continue
				mata : rcm("`timeVar'", "`varlist'", "`unit_all'", "`unit_placebo'", ///
					"`time_all'", "`time_tr'", "`criterion'", "`method'", "`estimate'", "`scope'", -1, "`grid'", `fold', `seed')
				if _rc {
					exit
				}
				qui predict pred·`depvar'·`unit_placebo'
				cap lab variable pred·`depvar'·`unit_placebo' "prediction of `depvar' in `unit_placebo' generated by 'placebo unit'"
				qui gen tr·`depvar'·`unit_placebo' = `depvar'·`unit_placebo'- pred·`depvar'·`unit_placebo'
				cap lab variable tr·`depvar'·`unit_placebo' "treatment effect of `depvar' in `unit_placebo' generated by 'placebo unit'"
				mata: rcm_summary(st_sdata(., "`timeVarStr'"), st_data(., "`depvar'·`unit_placebo' pred·`depvar'·`unit_placebo'"), ///
					"`time_tr'", "`predvar_sel'", "", "`estimate'", 1, ("`cutoff'" == "" ? . : strtoreal("`cutoff'")))
				if "`unit_placebo'" != "" {
					loc tsline "`tsline' (tsline tr·`depvar'·`unit_placebo', lp(dash) lc(gs11%20))"
					loc unit_ctrl_sel "`unit_ctrl_sel' `unit_placebo'"
				}
				else loc unit_ctrl_dis "`unit_ctrl_dis' `unit_tmp'"
			}
			loc unit_ctrl "`unit_ctrl_sel'"
			di _newline _newline as txt "Placebo test results using fake treatment units:"
			mata: rcm_print(tokens("`unit_tr' `unit_ctrl'")', ("Unit", "Pre MSPE ", " Post MSPE ", "Post/Pre MSPE", "  Pre MSPE of Fake Unit/Pre MSPE of Treated Unit"), st_matrix("mspe"), "", 0, (9, 9, 13, 24), 0, 0)
			mata: st_numscalar("pval", mean((st_matrix("mspe")[1, 3] :< st_matrix("mspe")[2..rows(st_matrix("mspe")), 3])))
			if "`unit_ctrl_dis'" != "" {
				mata: printf("{p 0 6 2}{txt}Note: The excluded unit{res}`unit_ctrl_dis'{txt} " ///
					+ (cols(tokens("`unit_ctrl_dis'")) > 1 ? "have" : "has") + " pre-treatment MSPE " ///
					+ "{res}`cutoff'{txt} times larger than {res}`unit_tr'{txt}'s.{p_end}")
				mata: printf(stritrim(sprintf( ///
				"{p 6 6 2}{txt}The probability of obtaining a post/pre-treatment MSPE ratio as large as {res}`unit_tr'{txt}'s is{res}%10.4f{txt}.{p_end}\n", ///
				mean((st_matrix("mspe")[1, 3] :<= st_matrix("mspe")[. , 3])))))
			}
			else mata: printf(stritrim(sprintf( ///
				"{p 0 6 2}{txt}Note: The probability of obtaining a post/pre-treatment MSPE ratio as large as {res}`unit_tr'{txt}'s is{res}%10.4f{txt}.{p_end}\n", mean((st_matrix("mspe")[1, 3] :<= st_matrix("mspe")[. , 3])))))
			di _newline as txt "Placebo test results using fake treatment units (continued):"
			mata: rcm_placebo("`depvar'", "`unit_tr'", "`unit_ctrl'", "`time_all'", "`time_tr'")
			cap lab variable pvalTwo "two-sided p-value of treatment effect generated by 'placebo unit'"
			cap lab variable pvalRight "right-sided p-value of treatment effect generated by 'placebo unit'"
			cap lab variable pvalLeft "left-sided p-value of treatment effect generated by 'placebo unit'"
			mkmat tr·`depvar'·`unit_tr' pvalTwo pvalRight pvalLeft if `timeVar' >= `trperiod', rownames(`timeVar') matrix(pval)
			mat colnames pval = TrEff twoSidePval RightSidePval leftSidePval
			if "`figure'" == "" {
				twoway (tsline tr·`depvar'·`unit_tr') `tsline', xline(`xline_tr', lp(dot) lc(black)) yline(0, lp(dot) lc(black)) ///
					title("Placebo Test Using Fake Treatment Units") name(eff_pboUnit, replace) ///
					ytitle("treatment/placebo effects of `depvar'") ///
					legend(order(1 "Treatment Effect" 2 "Placebo Effect")) nodraw
				loc graphlist = "`graphlist' eff_pboUnit"
				tempname placeboUnitframe
				matrix colnames mspe = PreMSPE PostMSPE RatioPostPre RatioTrCtrl
				frame create `placeboUnitframe'
				frame `placeboUnitframe'{
					qui svmat mspe, name(col)
					mata: st_sstore(., st_addvar("strL", "unit"), tokens("`unit_tr' `unit_ctrl'")')
					graph hbar (asis) RatioPostPre, over(unit, sort(RatioPostPre) descending label(labsize(vsmall))) ///
					ytitle("Ratios of Post-treatment MSPE to Pre-treatment MSPE") ///
					title("Placebo Test Using Fake Treatment Units") name("ratio_pboUnit", replace) nodraw
				}
				loc graphlist = "`graphlist' ratio_pboUnit"
				twoway connected pvalTwo `timeVar' if  `timeVar' >= `trperiod', ///
					ytitle("two-sided p-values of treatment effects of `depvar'") ///
					yline(0.05 0.1, lp(dot) lc(black)) ylabel(0(0.1)1) ///
					title("Placebo Test Using Fake Treatment Units") name(pvalTwo_pboUnit, replace) nodraw
				twoway connected pvalRight `timeVar' if  `timeVar' >= `trperiod', ///
					ytitle("right-sided p-values of treatment effects of `depvar'") ///
					yline(0.05 0.1, lp(dot) lc(black)) ylabel(0(0.1)1) ///
					title("Placebo Test Using Fake Treatment Units") name(pvalRight_pboUnit, replace) nodraw
				twoway connected pvalLeft `timeVar' if  `timeVar' >= `trperiod', ///
					ytitle("left-sided p-values of treatment effects of `depvar'") ///
					yline(0.05 0.1, lp(dot) lc(black)) ylabel(0(0.1)1) ///
					title("Placebo Test Using Fake Treatment Units") name(pvalLeft_pboUnit, replace) nodraw
				loc graphlist = "`graphlist' pvalTwo_pboUnit pvalRight_pboUnit pvalLeft_pboUnit"
			}
		}
		if("`period'" != ""){
			di _newline as txt "Implementing placebo test using fake treatment time " _continue
			foreach pboperiod in `period'{
			    qui levelsof `timeVar', local(time_n)
				loc check: list pboperiod in time_n
				if `check' == 0 {
					di _newline as err "placebo() invalid -- invalid fake period `pboperiod'"
					exit 198
				}
				qui levelsof `timeVarStr' if `timeVar' == `pboperiod', local(time_pbo) clean
				loc pos: list posof "`pboperiod'" in temp
				loc pos = `pos' - 1
				loc xline_pbo: word `pos' of `temp'
				di as res "`time_pbo'" as txt "..." _continue
				mata: rcm("`timeVar'", "`varlist'", "`unit_all'", "`unit_tr'", "`time_all'", "`time_pbo'", ///
					"`criterion'", "`method'", "`estimate'", "`scope'", -1, "`grid'", `fold', `seed')
				if _rc {
					exit
				}
				loc subvarname = strtoname("`unit_tr'·`time_pbo'")
				qui cap drop pred·`depvar'·`subvarname'
				qui cap predict pred·`depvar'·`subvarname'
				cap lab variable pred·`depvar'·`subvarname' "prediction of `depvar' in `unit_tr' generated by 'placebo period `time_pbo''"
				qui cap drop tr·`depvar'·`subvarname'
				qui cap gen tr·`depvar'·`subvarname' = `depvar'·`unit_tr' - pred·`depvar'·`subvarname'
				cap lab variable tr·`depvar'·`subvarname' "treatment effect of `depvar' in `unit_tr' generated by 'placebo period `time_pbo''"
				if "`figure'" == "" {
					twoway (tsline `depvar'·`unit_tr') (tsline pred·`depvar'·`subvarname', lpattern(dash)), ///
						title("Placebo Test Using Fake Treatment Time `time_pbo'") xline(`xline_pbo' `xline_tr', lp(dot) lc(black)) ///
						name(pred_pboTime`pboperiod', replace) ytitle(`depvar')  ///
						legend(order(1 "Actual" 2 "Predicted")) nodraw
					loc graphlist = "`graphlist' pred_pboTime`pboperiod'"
					tsline tr·`depvar'·`subvarname', xline(`xline_pbo' `xline_tr', lp(dot) lc(black)) yline(0, lp(dot) lc(black)) ///
						title("Placebo Test Using Fake Treatment Time `time_pbo'") name(eff_pboTime`pboperiod', replace) ///
						ytitle("placebo effects of `depvar'") nodraw
					loc graphlist = "`graphlist' eff_pboTime`pboperiod'"
				}
			}
			di
			foreach pboperiod in `period'{
				qui levelsof `timeVarStr' if `timeVar' == `pboperiod', local(time_pbo) clean
				di _newline as txt "Placebo test results using fake treatment time " as res "`time_pbo'" as txt":"
				mata: rcm_print(st_sdata(., "`timeVarStr'"), ("Time", "Actual Outcome", "Predicted Outcome", "Treatment Effect"), ///
					st_data(., "`depvar'·`unit_tr' pred·`depvar'·`subvarname' tr·`depvar'·`subvarname'"), "`time_pbo'", 1, (13, 17, 16), 0, 0)
			}
		}
	}
	ereturn loc graphlist "`graphlist'"
	cap ereturn matrix pval = pval
end

version 16
mata:
	string matrix rcm_paste(string scalar vars, string matrix units){
		tempvar = tokens(vars)
		result = J(rows(units)*cols(tempvar), 1, "")
		for(i = 1; i<=rows(units); i++) for(j = 1; j<=cols(tempvar); j++){
			result[(i - 1) * cols(tempvar) + j] = tempvar[j] + "·"+ units[i,1]
		}
		return(result)
	}
	string matrix rcm_enter(string matrix S, real scalar n){
		string matrix result1
		string matrix result2
		string matrix result
		str = tokens(S[., 1])
		for(i = 1; i<= cols(str); i++){
			if(i == 1) result1 = (str[i])
			else if (udstrlen(result1[rows(result1), 1] + " " + str[i]) > n) result1 = result1\str[i]
			else result1[rows(result1), 1] = result1[rows(result1), 1] + " " + str[i]
		}
		str = tokens(S[., 2])
		for(i = 1; i<= cols(str); i++){
			if(i == 1) result2 = (str[i])
			else if (udstrlen(result2[rows(result2), 1] + " " + str[i]) > n) result2 = result2\str[i]
			else result2[rows(result2), 1] = result2[rows(result2), 1] + " " + str[i]
		}
		result = J(0, 1, "")
		if(rows(result1) != 0){
			for(i = 1; i <= rows(result1); i++){
				if(i == 1) result1[1, 1] = "{txt}add {res}" + result1[1, 1]
				else result1[i, 1] = "    {res}" + result1[i, 1]
				result = result\result1[i, 1]
			}
		}
		if(rows(result2) != 0){
			for(i = 1; i <= rows(result2); i++){
				if(i == 1) result2[1, 1] = "{txt}drop {res}" + result2[1, 1]
				else result2[i, 1] = "     {res}" + result2[i, 1]
				result = result\result2[i, 1]
			}
		}
		if(rows(result) == 0) result = "."
		return(result)
	}
	void rcm_print(string matrix rownames, string matrix colnames, real matrix M, string scalar startstr, real scalar isMean, real matrix wideM, real scalar extend, real scalar isInt){
		wide = max(udstrlen((rownames[1..rows(rownames),1]\colnames[1])))
		printf(sprintf("{hline %g}{c TT}", wide + 2))
		for(j = 1; j <= cols(colnames) - 1; j++) printf(sprintf("{hline %g}", wideM[j] + 2))
		printf(sprintf("{hline %g}\n", extend))
		
		printf(sprintf(" {txt}%%~%guds {c |}", wide), colnames[1])
		for(j = 2; j <= cols(colnames); j++){
			if(j == cols(colnames) & (udstrlen(colnames[j]) > wideM[j - 1] + 2)){
				printf(sprintf("%%%guds\n", wideM[j - 1] + 2), substr(colnames[j], 1, wideM[j - 1]))
				printf(" {space %g} {c |}", wide)
				for(k = 2; k <= cols(colnames); k++){
					if(k != cols(colnames)){
						printf("{space %g}", wideM[k - 1] + 2)
					}
					else printf(sprintf("%%%guds", wideM[k - 1] + 2), substr(colnames[k], wideM[k - 1] +1))
				}
			}
			else printf(sprintf("%%%guds", wideM[j - 1] + 2), colnames[j])
		}
		printf(sprintf("\n{hline %g}{c +}", wide + 2))
		for(j = 1; j <= cols(colnames) - 1; j++) printf(sprintf("{hline %g}", wideM[j] + 2))
		printf(sprintf("{hline %g}\n", extend))
		start = startstr == "" ? 1 : selectindex(rownames :== startstr)[1]
		for(i = start; i <= rows(M); i++){
			printf(sprintf(" {txt}%%%guds {c |}{res}", wide), rownames[i])
			for(j = 1; j <= cols(M); j++){
			    if(isInt == 0) printf(sprintf(" %%%g.4f ", wideM[j]), M[i,j])
				else printf(sprintf(" %%%g.0g ", wideM[j]), M[i,j])
			}
			printf("\n")
		}
		if(isMean == 1){
			printf(sprintf("{hline %g}{c +}", wide + 2))
			for(j = 1; j <= cols(colnames)-1; j++) printf(sprintf("{hline %g}", wideM[j] + 2))
			printf(sprintf("{hline %g}\n", extend))
			meanM = mean(M[start..rows(M), .])
			printf(sprintf(" {txt}%%~%guds {c |}{res}", wide), "Mean")
			for(j = 1; j <= cols(M); j++){
				printf(sprintf(" %%%g.4f ", wideM[j]), meanM[., j])
			}
			printf("\n")
		}
		printf(sprintf("{hline %g}{c BT}", wide + 2))
		for(j = 1; j <= cols(colnames) - 1; j++) printf(sprintf("{hline %g}", wideM[j] + 2))
		printf(sprintf("{hline %g}\n", extend))
		if(isMean == 1) 
			printf(stritrim(sprintf("{p 0 6 2}{txt}Note: The average treatment effect over the post-treatment periods is{res} %10.4f{txt}.\n", 
				meanM[., 3])))
	}
	void rcm_printPval(string matrix rownames, string matrix colnames, string scalar colname, real matrix M, string scalar startstr, real scalar isMean, real matrix wideM, real scalar extend, real scalar isInt){
		
		wide = max(udstrlen((rownames[1..rows(rownames),1]\colnames[1])))
		printf(sprintf("{hline %g}{c TT}", wide + 2))
		for(j = 1; j <= cols(colnames) - 1; j++) printf(sprintf("{hline %g}", wideM[j] + 2))
		printf(sprintf("{hline %g}\n", extend))
		
		printf(sprintf(" {txt}%%~%guds {c |}", wide), colnames[1])
		printf(sprintf("{txt}%%%guds", wideM[1] + 2), colnames[2])
		printf(sprintf("{txt}%%~%guds\n", wideM[2] + wideM[3] + wideM[4] + 6), colname)
		
		printf(sprintf("{space %g}{c |}", wide + 2))
		for(j = 2; j <= cols(colnames); j++){
			if(j == cols(colnames) & (udstrlen(colnames[j]) > wideM[j - 1] + 2)){
				printf(sprintf("%%%guds\n", wideM[j - 1] + 2), substr(colnames[j], 1, wideM[j - 1]))
				printf(" {space %g} {c |}", wide)
				for(k = 2; k <= cols(colnames); k++){
					if(k != cols(colnames)){
						printf("{space %g}", wideM[k - 1] + 2)
					}
					else printf(sprintf("%%%guds", wideM[k - 1] + 2), substr(colnames[k], wideM[k - 1] +1))
				}
			}
			else{
				if(j == 2) printf("{space %g}", wideM[j - 1] + 2)
				else printf(sprintf("%%%guds", wideM[j - 1] + 2), colnames[j])
			}
		}
		printf(sprintf("\n{hline %g}{c +}", wide + 2))
		for(j = 1; j <= cols(colnames) - 1; j++) printf(sprintf("{hline %g}", wideM[j] + 2))
		printf(sprintf("{hline %g}\n", extend))
		start = startstr == "" ? 1 : selectindex(rownames :== startstr)[1]
		for(i = start; i <= rows(M); i++){
			printf(sprintf(" {txt}%%%guds {c |}{res}", wide), rownames[i])
			for(j = 1; j <= cols(M); j++){
			    if(isInt == 0) printf(sprintf(" %%%g.4f ", wideM[j]), M[i,j])
				else printf(sprintf(" %%%g.0g ", wideM[j]), M[i,j])
			}
			printf("\n")
		}
		if(isMean == 1){
			printf(sprintf("{hline %g}{c +}", wide + 2))
			for(j = 1; j <= cols(colnames)-1; j++) printf(sprintf("{hline %g}", wideM[j] + 2))
			printf(sprintf("{hline %g}\n", extend))
			meanM = mean(M[start..rows(M), .])
			printf(sprintf(" {txt}%%~%guds {c |}{res}", wide), "Mean")
			for(j = 1; j <= cols(M); j++){
				printf(sprintf(" %%%g.4f ", wideM[j]), meanM[., j])
			}
			printf("\n")
		}
		printf(sprintf("{hline %g}{c BT}", wide + 2))
		for(j = 1; j <= cols(colnames) - 1; j++) printf(sprintf("{hline %g}", wideM[j] + 2))
		printf(sprintf("{hline %g}\n", extend))
		if(isMean == 1) 
			printf(stritrim(sprintf("{txt}Note: The average treatment effect over the post-treatment periods is{res} %10.4f{txt}.\n", 
				meanM[., 3])))
	}
	void rcm_summary(string matrix rownames, real matrix M, string scalar time_tr, string scalar predvar, string scalar respo, string scalar estimate, real matrix isPlacobo, real scalar discard){
		T0 = selectindex(rownames :== time_tr) - 1
		T1 = rows(rownames) - T0
		K = cols(tokens(predvar))
		y = M[1..T0, 1]
		pred = M[1..T0, 2]
		MSE = (T0 - K - 1 > 0 ? (sum((y :- pred) :* (y :- pred))/(T0 - K - 1)) : .)
		MAE = (T0 - K - 1 > 0 ? (sum(abs(y :- pred))/(T0 - K - 1)) : . )
		RMSE = sqrt(MSE)
		R2 = 1 - sum((y :- pred) :* (y :- pred))/sum((y :- mean(y)) :* (y :- mean(y)))
		if(isPlacobo == 0){
			wide = max(udstrlen((tokens(predvar[.,1]), respo)))
			wide = wide < 9 ? 9 : (wide + 67 > st_numscalar("c(linesize)") ? max((st_numscalar("c(linesize)") - 67, 9)) : wide)
			printf("{hline " + strofreal(wide + 66) + "}\n")
			printf(" {txt}%-24uds =  {res}%8.5f {space "+ strofreal(wide - 9) + "} {txt}%-22uds  =   {res}%8.0f\n", "Mean Absolute Error", MAE, "Number of Observations", T0)
			printf(" {txt}%-24uds =  {res}%8.5f {space "+ strofreal(wide - 9) + "} {txt}%-22uds  =   {res}%8.0f\n", "Mean Squared Error", MSE, "Number of Predictors", K)
			printf(" {txt}%-24uds =  {res}%8.5f {space "+ strofreal(wide - 9) + "} {txt}%-22uds  =   {res}%8.5f\n", "Root Mean Squared Error", RMSE, "R-squared", R2)
			printf("{hline " + strofreal(wide + 66) + "}\n")
			st_numscalar("T0", T0)
			st_numscalar("mse", MSE)
			st_numscalar("mae", MAE)
			st_numscalar("rmse", RMSE)
			st_numscalar("r2", R2)
		}
		y = M[(T0 + 1)..(T0 + T1), 1]
		pred = M[(T0 + 1)..(T0 + T1), 2]
		MSPE_in = MSE
		MSPE_out = mean((y :- pred) :* (y :- pred))
		if(isPlacobo == 1){
			if((discard == .) | ((MSPE_in/(st_matrix("mspe")[1, 1])) <= discard))
				st_matrix("mspe", st_matrix("mspe")\(MSPE_in, MSPE_out, MSPE_out/MSPE_in, MSPE_in/(st_matrix("mspe")[1, 1])))
			else st_local("unit_placebo", "")
		}else st_matrix("mspe", (MSPE_in, MSPE_out, MSPE_out/MSPE_in, 1))
	}
	void rcm_print_info(string matrix rownames, string matrix colnames, real matrix M, real scalar wideM, real scalar limit, real scalar isOperation, real scalar best){
		limit = max((min((max(udstrlen(rownames)) + 5, limit)), udstrlen(colnames[cols(colnames)])))
		wide = max(floor((log10(M[., 1]) :+ 1))\udstrlen(colnames[1]))
		for(j = 1; j <= cols(colnames); j++){
			if(j == 1) printf(sprintf("{hline %g}{c TT}", wide + 2))
			else if (j == cols(colnames)) printf((isOperation == 1? sprintf("{c TT}{hline %g}\n", limit + 1) : sprintf("{hline %g}\n", wideM + 2)))
			else printf(sprintf("{hline %g}", wideM + 2))
		}
		for(j = 1; j <= cols(colnames); j++){
			if(j == 1) printf(sprintf("{txt}%%~%guds{c |}", wide + 2), colnames[j])
			else if(j == cols(colnames)) printf((isOperation == 1 ? sprintf("{c |}{txt}%%~%guds\n", limit + 1) : sprintf("{txt}%%~%guds\n", wideM + 2)), colnames[j])
			else printf(sprintf("{txt}%%~%guds", wideM + 2), colnames[j])
		}
		for(j = 1; j <= cols(colnames); j++){
			if(j == 1) printf(sprintf("{hline %g}{c +}", wide + 2))
			else if (j == cols(colnames)) printf((isOperation == 1 ? sprintf("{c +}{hline %g}\n", limit + 1) : sprintf("{hline %g}\n", wideM + 2)))
			else printf(sprintf("{hline %g}", wideM + 2))
		}
		for(i = 1; i <= rows(M); i++){
			for(j = 1; j <= cols(M); j++){
				if(j == 1){
				    if(i == best) printf(sprintf(" {txt}%%%g.0f {c |}", wide), M[i,j])
					else printf(sprintf(" {txt}%%%g.0f {c |}", wide), M[i,j])
				}else printf(sprintf("{res} %%%g.4f ", wideM), M[i,j])
			}
			if(isOperation == 1){
				temp = rcm_enter(rownames[i, .], limit)
				for(j = 1; j <= rows(temp); j++){
					if(j == 1) printf(sprintf("{c |} %%-%guds \n", limit), temp[j])
					else printf(sprintf("{space %g}{c |}{space %g}{c |} %%-%guds \n", wide + 2, (wideM + 2) * (cols(colnames)-2), limit), temp[j])
				}
				
			}else printf("\n")
		}
		for(j = 1; j <= cols(colnames); j++){
			if(j == 1) printf(sprintf("{hline %g}{c BT}", wide + 2))
			else if (j == cols(colnames)) printf((isOperation == 1 ? sprintf("{c BT}{hline %g}\n", limit + 1) : sprintf("{hline %g}\n", wideM + 2)))
			else printf(sprintf("{hline %g}", wideM + 2))
		}
	}
	void function rcm_MtoR(pointer(real matrix) scalar YCXYCX, pointer(real matrix) scalar M, pointer(real matrix) scalar R, real scalar T0){
		R = &J(rows((*M)), 2, .)
		for(i = 1; i <= rows((*M)); i++){
			temp = (2, select((*M)[i, .], (*M)[i, .] :> 0) :+ 2)
			(*R)[i, .] = (sum((*M)[i, .] :> 0), (*YCXYCX)[1, 1] - (*YCXYCX)[1, temp] * luinv((*YCXYCX)[temp, temp], T0) * (*YCXYCX)[temp, 1])
			(*R)[i, 2] = (((*R)[i, 2] < 0) ? 0 : (*R)[i, 2])
		}
	}
	void function rcm_RtoI(pointer(real matrix) scalar R, pointer(real matrix) scalar I, real scalar TSS, real scalar T0){
		I = &J(rows(*(R)), 6, .)
		for(i = 1; i <= rows((*I)); i++){
			p = (*R)[i, 1]
			aic = T0 * log((*R)[i, 2]/T0) + 2 * (p + 2)
			bic = T0 * log((*R)[i, 2]/T0) + (p + 2) * log(T0)
			mbic = T0 * log((*R)[i, 2]/T0) + (p + 2) * log(T0) * log(log(p + 1)) 
			aicc = T0 - (p + 1) - 2 >= 1 ? aic + (2 * (p + 2) * (p + 3))/(T0 - (p + 2) - 1) : .
			r2 = 1 - (*R)[i, 2]/TSS
			(*I)[i, .] = (p, aicc, aic, bic, mbic, r2)
		}
	}
	real scalar rcm_sortMSIorR(pointer(real matrix) scalar M, pointer(real matrix) scalar S, pointer(real matrix) scalar IorR, string scalar criterion, real matrix scope, real scalar isSort){
		real scalar result
		col = (criterion == "rss" | criterion == "aicc") ? 3 : (criterion == "aic" ? 4 : (criterion == "bic" ? 5 : (criterion == "mbic" ? 6 : 7)))
		ord = sort((vec(1..rows((*IorR))), (*IorR)), (col, 2, 1))[., (1, 2)]
		if(scope != (., .)) {
			tmpord = select(ord, (ord[., 2] :>= scope[1]) :& (ord[., 2] :<= scope[2]))
			if (rows(tmpord) > 0){
			    ord = tmpord
				result = ord[1, 1]
			}
			else result = 00
		}
		if(isSort == 1){
		    if(M != NULL) (*M) = (*M)[ord[., 1], .]
			if(S != NULL) (*S) = (*S)[ord[., 1], .]
			if(IorR != NULL) (*IorR) = (*IorR)[ord[., 1], .]
		}
		return(result)
	}
	void function rcm_MStoMS(pointer(real matrix) scalar M, pointer(string matrix) scalar S, string scalar method, string matrix preds){
		if(method == "forward"){
			if(M == NULL){
				M = &(vec(1..rows(preds)), J(rows(preds), rows(preds) - 1, 0))
				S = &(J(rows(preds), 1, ""), preds, J(rows(preds), 1, ""))
			}else{
				M = &((*M)[2..rows((*M)), 1], J(rows((*M)) - 1, 1, (*M)[1, 1]), (*M)[1..rows((*M)) - 1, 2..cols((*M)) - 1])
				(*S) = (*S)[2..rows((*S)), .]
			}
		}else if(method == "backward"){
			if(M == NULL){
				M = &(1..rows(preds))
				S = &("", "*", "")
			}else{
				nextM = &J(sum((*M)[1, .] :> 0), cols((*M)), 0)
				S = &J(sum((*M)[1, .] :> 0), 3, "")
				for(i = 1; i <= rows((*nextM)); i++){
					(*nextM)[i, .] = (select((*M)[1, .], 1 :- e(i, cols((*M)))), 0)
					(*S)[i, 3] = preds[(*M)[1, i]]
				}
				M = nextM
				nextM = NULL
			}
		}
	}
	string matrix rcm_path(string matrix varlistM){
		result = J(rows(varlistM), 2, "")
		for(i = 1; i <= rows(varlistM); i++){
			if(i == 1) result[i, 1] = varlistM[i]
			else{
				result[i, 1] =  rcm_diff(varlistM[i - 1], varlistM[i])
				temp = rcm_diff(varlistM[i], varlistM[i - 1])
				result[i, 2] =  temp
			}
		}
		return(result)
	}
	string scalar rcm_diff(string scalar M, string scalar N){
		tokensM = tokens(M)
		tokensN = tokens(N)
		result = ""
		for(i = 1; i <= cols(tokensN); i++){
			for(j = 1; j<= cols(tokensM); j++) if(tokensN[i] == tokensM[j]) break
			if(j == cols(tokens(M)) + 1) if(result == "") result = tokensN[i]; else result = result + " " + tokensN[i]
		}
		return(result)
	}
	struct rcm_node{
		rowvector preds
		real matrix inverse
		pointer (struct rcm_node scalar) rowvector child
		pointer (struct rcm_node scalar) scalar parent, leaf
		real index, rss
	}
	void function rcm_update(pointer(struct rcm_node scalar) scalar rcm_node, pointer(real matrix) scalar YCXYCX, 
						 pointer(real matrix) scalar bestR, pointer(real matrix) scalar bestM, 
						 real scalar T0 , real scalar speed){
		if((*rcm_node).leaf != NULL){
			(*(*rcm_node).leaf).rss = 
				(*YCXYCX)[1, 1] - (*YCXYCX)[1, (2, (*(*rcm_node).leaf).preds :+ 2)] * 
					invsym((*YCXYCX)[(2, (*(*rcm_node).leaf).preds :+ 2), (2, (*(*rcm_node).leaf).preds :+ 2)]) * 
					(*YCXYCX)[(2, (*(*rcm_node).leaf).preds :+ 2), 1]
		}
		(*rcm_node).rss = 
			(*YCXYCX)[1, 1] - (*YCXYCX)[1, (2, (*rcm_node).preds :+ 2)] * invsym((*YCXYCX)[(2, (*rcm_node).preds :+ 2), (2, (*rcm_node).preds :+ 2)]) * (*YCXYCX)[(2, (*rcm_node).preds :+ 2), 1]
		if((*bestR)[cols((*rcm_node).preds), 2] ==. | ((*bestR)[cols((*rcm_node).preds), 2] > (*rcm_node).rss)){
			(*bestR)[cols((*rcm_node).preds), 2] = (*rcm_node).rss
			(*bestM)[cols((*rcm_node).preds), .] = ((*rcm_node).preds, J(1, cols((*bestM))- cols((*rcm_node).preds), 0))
		}
		if((*rcm_node).leaf != NULL){
			if((*bestR)[cols((*(*rcm_node).leaf).preds), 2] ==. | ((*bestR)[cols((*(*rcm_node).leaf).preds), 2] > (*(*rcm_node).leaf).rss)){
				(*bestR)[cols((*(*rcm_node).leaf).preds), 2] = (*(*rcm_node).leaf).rss
				(*bestM)[cols((*(*rcm_node).leaf).preds), .] = ((*(*rcm_node).leaf).preds, J(1, cols((*bestM))- cols((*(*rcm_node).leaf).preds), 0))
			}
		}
	}
	void rcm_traverse(
		pointer(struct rcm_node scalar) scalar parent, pointer(real matrix) scalar YCXYCX, 
		pointer(real matrix) scalar bestR, pointer(real matrix) scalar bestM, real scalar T0, real scalar speed){
		struct rcm_node child
		struct rcm_node leaf
		rcm_update(parent, YCXYCX, bestR, bestM, T0, speed)
		child = rcm_node(cols((*parent).preds) - (*parent).index)
		(*parent).child = J(1, cols((*parent).preds) - (*parent).index, NULL)
		leaf = rcm_node(cols(child))
		for(i = (*parent).index; i <= cols((*parent).preds) - 1; i++){
			j = cols((*parent).preds)- i
			child[j].preds = 
				i == 1? (*parent).preds[(i + 1)..cols((*parent).preds)] : (*parent).preds[(1..(i - 1), (i + 1)..cols((*parent).preds))]
			child[j].index = i
			leaf[j].preds = (*parent).preds[1..i]
			child[j].leaf = &(leaf[j])
			((*parent).child)[j] = &(child[j])
			child[j].parent = parent
		}
		for(limit = 1; limit <= cols((*parent).preds) - 1; limit++){
			if (((*bestR)[limit, 2] != .) & ((*parent).rss >= (*bestR)[limit, 2])) break
		}
		for(i = 1; i <= cols(child); i++) 
			if (child[i].index < limit) rcm_traverse((*parent).child[i], YCXYCX, bestR, bestM, T0, speed)
		for (i = 1; i <= cols((*parent).child); i++) {
			(*((*parent).child[i])).parent = NULL
			(*((*parent).child[i])).leaf = NULL
			((*parent).child)[i] = NULL
		}
	}
	void rcm_leaps(pointer(real matrix) scalar YCXYCX, pointer(real matrix) scalar bestM, pointer(string matrix) scalar bestS, pointer(real matrix) scalar bestR, real scalar K, real scalar T0){
		struct rcm_node scalar parent
		df_m = rank((*YCXYCX)[2..(K + 2), 2..(K + 2)])
		RSS = df_m > (T0 - 1) ? 0 : ((*YCXYCX)[1, 1] - (*YCXYCX)[1, 2..(K + 2)] * invsym((*YCXYCX)[2..(K + 2), 2..(K + 2)]) * (*YCXYCX)[2..(K + 2), 1])
		inv = invsym((*YCXYCX)[2..(K + 2), 2..(K + 2)])
		b = invsym((*YCXYCX)[2..(K + 2), 2..(K + 2)]) * (*YCXYCX)[2..(K + 2), 1]
		ord = J(K, 2, .)
		for(i = 1; i <= K; i++){
			ord[i, .] = (i, (b[i + 1]^2 / inv[i + 1, i + 1]))
		}
		ord = sort(ord, (-2, 1))
		rep = J(K, K, .)
		for(i = 1; i <= rows(ord); i++) rep[i, .] = e(ord[i, 1], K)
		rep = blockdiag(I(2), rep)
		(*YCXYCX) = rep * (*YCXYCX) * rep'
		(*bestR) = J(K, 2, .)
		(*bestR)[., 1] = 1::K
		(*bestM) = J(K, K, .)
		(*bestS) = J(K, 3, "")
		parent.preds = 1..K
		parent.index = 1
		speed = rank((*YCXYCX)[2..(K + 2), 2..(K +2)])> (T0 - 1) ? 0 : 1
		rcm_traverse(&parent, YCXYCX, bestR, bestM, T0, 0)
		for(i = 1; i <= K; i++){
			temp = (2, select((*bestM)[i, .], (*bestM)[i, .] :> 0) :+ 2)
			if((*bestR)[i, 2] <= 0 | rank((*YCXYCX)[temp, temp]) > (T0 - 1)) (*bestR)[i, 2] = 0
			(*bestM)[i, 1..i] = ord[select((*bestM)[i, .],(*bestM)[i, .] :> 0) , 1]'
			(*bestS)[i, 2] = "{txt}from combination({res}" + strofreal(i) + "{txt}, {res}" + strofreal(K)  + ")"
		}
	}
	void rcm(string scalar timeVar, string scalar varlist, string scalar unit, string scalar unit_tr, string scalar time, string scalar time_tr, string scalar criterion, string scalar method, string scalar estimate, string scalar scopeStr, real scalar detail, string scalar grid, real scalar fold, real scalar seed){
		pointer(real matrix) scalar M, R, II, bestI, bestM, data
		pointer(string matrix) scalar S, bestS
		real matrix A
		if(detail >= 0) printf("\n")
		unit = tokens(unit)'
		unit_ctrl = select(unit, unit :!= unit_tr)
		time = tokens(time)'
		T0 = selectindex(time :== time_tr) - 1
		{
			featu = rcm_paste(varlist, (unit_tr\unit_ctrl))
			respo = featu[1]
			preds = featu[2..rows(featu)]
			K = rows(preds)
		}
		if (fold == .) fold = T0
		data = &(st_data(., respo), J(rows(time), 1, 1), st_data(., invtokens(preds')))
		(*data) = (*data)[1..T0, .]
		YCXYCX = cross((*data), (*data))
		TSS = cross((*data)[., 1] :- mean((*data)[., 1]), (*data)[., 1] :- mean((*data)[., 1]))
		bestS = &J(0, 3, "")
		bestR = &J(0, 2, .)
		bestM = &J(0, K, .)
		if(scopeStr != "") scope = strtoreal(tokens(scopeStr)); else scope = (1, rows(preds))
		if(detail >= 0) printf("{txt}Step 1: Select the suboptimal models\n(method {res}%uds {txt}specified)\n", method)
		if(method == "best"){
			if(detail >= 0) printf("{p 0 6 2}{txt}Note: If this takes too long, you may wish to try {bf:method(lasso)}(recommended), {bf:method(forward)} or {bf:method(backward)}. Alternatively, you may restrict {it:indepvars}, and/or the donor pool by the option {bf:ctrlunit()}.{p_end}\n")
		}else if(method == "backward" & K > T0) {
			printf("{p 0 0 2}{err}backward stepwise selection can not be implemented for high-dimensional data with the number of predictors exceeding the number of pre-treatment periods, you may use lasso, best subset or forward stepwise selection instead{p_end}\n")
			exit(198)
		}
		if(detail >= 0) printf("\n")
		if(method == "lasso"){
			if(detail >= 0) printf("Selecting the suboptimal model...\n")
			error = _stata(sprintf("qui lasso linear %uds in 1/%g, %uds sel(%uds) rseed(%g)", 
				invtokens((respo, preds')), T0, grid, (criterion == "cv" ? sprintf("cv, fold(%g) alllambdas gridminok", fold) : "none"), seed), 1)
			if(error == 198){
			   exit(_stata(sprintf("qui lasso linear %uds in 1/%g, %uds sel(%uds) rseed(%g)", 
				invtokens((respo, preds')), T0, grid, (criterion == "cv" ? sprintf("cv, fold(%g) alllambdas gridminok", fold) : "none"), seed), 0))
			}
			if (criterion == "cv"){
				stata("qui lassoknots, di(nonzero cvmpe r2 )")
				head = ("K", " AICc", "AIC", "BIC", " MBIC", "CVMSE", "R-squared", " lambda", "Operation")
			}else{
				stata("qui lassoknots, di(nonzero r2)")
				head = ("K", "AICc", "AIC", "BIC", " MBIC", "R-squared", " lambda", "Operation")
			}
			tmp = st_matrix("r(table)")
			bestR = &J(rows(tmp), 2, .)
			bestS = &J(rows(tmp), 1, "")
			for(i = 1; i<= rows(tmp); i++){
				id = tmp[i, 1]
				stata(sprintf("qui lassoselect id = %g", id))
				stata(sprintf("qui lassogof in 1/%g", T0))
				(*bestR)[i, 1] = tmp[i, 3]
				(*bestR)[i, 2] = st_matrix("r(table)")[1, 1] * T0
				(*bestS)[i, 1] = st_global("e(allvars_sel)")
			}
			rcm_RtoI(bestR, bestI, TSS, T0)
			(*bestI) = ((*bestI)[., 1..5], tmp[., 4..cols(tmp)], tmp[., 2])
			(*bestS) = ((*bestS), rcm_path((*bestS)))
			bestM = NULL		
			if(detail >= 0) printf("\n")
		}else if(method == "best"){
			if(detail >= 0) printf("Selecting the suboptimal model with number of predictors {res}%g-%g...\n", scope[1], scope[2])
			rcm_leaps(&YCXYCX, bestM, bestS, bestR, K, T0)
			head = ("K", "AICc", "AIC", "BIC", " MBIC", "R-squared")
			rcm_RtoI(bestR, bestI, TSS, T0)
			if(detail >= 0) printf("\n")
		}else{
			if(detail == 0) printf("{txt}Selecting the suboptimal model with number of predictors ")
			for(i = (method == "best"? scope[1] : 1); i <= (method == "backward" ? rows(preds) - scope[1] + 1 : scope[2]); i++){
				if(detail == 0) printf("{res}%g{txt}...", method == "backward" ? K - i + 1 : i)
				displayflush()
				rcm_MStoMS(M, S, method, preds)
				rcm_MtoR(&YCXYCX, M, R, T0)
				if(detail == 1){
					printf("{txt}Comparing the models containing {res}%g {txt}predictors:\n", (*R)[1, 1])
					rcm_print_info((*S)[., 2..3], ("K", "RSS", "Operation"), (*R), 10, 30, 1, 0)
					expand = rcm_sortMSIorR(M, S, R, "rss", (., .), 1)
					printf(stritrim(sprintf("{txt}Among models with {res}%g{txt} predictors, the suboptimal model with {res}RSS = %10.4f{txt} %uds.\n\n",
						(*R)[1, 1], (*R)[1, 2], ((*S)[1, 2] != "" ? sprintf("(add {res}%uds{txt})", (*S)[1, 2]): ((*S)[1, 3] != "" ? sprintf("(drop {res}%uds{txt})", (*S)[1, 3]) : "")))))
				}else expand = rcm_sortMSIorR(M, S, R, "rss", (., .), 1)
				(*bestM) = ((*bestM) \ (*M)[1, .])
				(*bestS) = ((*bestS) \ (*S)[1, .])
				(*bestR) = ((*bestR) \ (*R)[1, .])
				
			}
			if(detail == 0) printf("\n\n")
			head = ("K","AICc","AIC","BIC"," MBIC","R-squared","Operation")
			rcm_RtoI(bestR, bestI, TSS, T0)
		}
		{
			if(detail >= 0){
				printf("{txt}Step 2: Select the optimal model from the suboptimal models\n(criterion {res}%uds {txt}specified%s)\n\n", 
					criterion, (criterion == "cv" ? (fold != T0 ? sprintf(" for {res}%g-fold{txt} cross-validation", fold) : 
					sprintf(" for {res}leave-one-out{txt} cross-validation")) : ""))
				printf("{txt}Comparing the suboptimal models containing different set of predictors:\n")
				expand = rcm_sortMSIorR(bestM, bestS, bestI, criterion, scope, 0)
				if (criterion == "cv"){
					rcm_print_info((*bestS)[., 2..3], head[(1,8,6,7,9)], (*bestI)[.,(1,8,6,7)], 10, 30, (method == "best" ? 0 : 1), expand) //
					st_matrix("info", (*bestI)[.,(1,8,6,7)])
					st_matrixcolstripe("info", (J(4, 1, ""), head[(1,8,6,7)]'))
				}
				else{
					rcm_print_info((*bestS)[., 2..3], (head), (*bestI), 10, 30, (method == "best" ? 0 : 1), expand) //
					st_matrix("info", (*bestI))
					if(head[cols(head)] == "Operation") st_matrixcolstripe("info", (J(cols(head) - 1, 1, ""), head[1..cols(head) - 1]'))
					else st_matrixcolstripe("info", (J(cols(head), 1, ""), head[1..cols(head)]'))
				}
			}
			expand = rcm_sortMSIorR(bestM, bestS, bestI, criterion, scope, 1) //
			if(expand == 1) scope = (1, K)
			if(detail >= 0){
				printf(stritrim(sprintf("{p 0 0 2}{txt}Among models with {res}%g-%g{txt} predictors, the optimal model contains {res}%g{txt} %uds with {res}%uds = %10.4f.{p_end}\n", scope[1], scope[2], (*bestI)[1, 1], ((*bestI)[1, 1] > 1 ? "predictors" : "predictor"), (criterion == "cv" ? "CVMSE" : ((criterion == "aicc") ? "AICc" : strupper(criterion))), (*bestI)[1, criterion == "aicc" ? 2 : (criterion == "aic" ? 3 : (criterion == "bic" ? 4 : (criterion == "mbic" ? 5 : 6)))])))
				if(expand == 1) printf("{txt}Note: {res}scope{txt} is automatically changed to {res}%g-%g{txt} for expanding selection.\n", scope[1], scope[2])
				printf("\n")
				tmp = (method == "lasso" ? (estimate == "lasso" ? " using {res}lasso{txt}" : " using {res}post-lasso OLS{txt}") : " using {res}OLS{txt}")
				printf("{txt}Fitting results in the pre-treatment periods%s:\n", tmp)
			}
			if(estimate == "ols")
				stata(sprintf("qui reg %uds %uds in 1/%g, noheader", respo,
					((*bestS)[1, 1] = ((*bestS)[1, 1] == "" ? (invtokens(preds[select((*bestM)[1, .], (*bestM)[1, .] :> 0)]')) : (*bestS)[1, 1])), T0))
			else stata(sprintf("qui lassoselect lambda = %g", (*bestI)[1, cols(*bestI)]))
		}
		if(detail >= 0){
			st_numscalar("k_predvar", rows(preds))
			st_numscalar("k_predvar_sel", (*bestI)[1, 1])
			if(method == "lasso" & criterion == "cv") st_numscalar("cvmse", (*bestI)[1, 5])
			st_numscalar("aicc", (*bestI)[1, 2])
			st_numscalar("aic", (*bestI)[1, 3])
			st_numscalar("bic", (*bestI)[1, 4])
			st_numscalar("mbic", (*bestI)[1, 5])
			st_numscalar("r2", (*bestI)[1, 6])
			st_local("outvar", respo)
			st_local("predvar_all", invtokens(preds'))
			st_local("predvar_sel", (*bestS)[1, 1])
			st_local("tmp", tmp)
		}else st_local("predvar_sel", (*bestS)[1, 1])
	}
	void rcm_placebo(string scalar depvar, string scalar unit_tr, string scalar unit_ctrl, string scalar time, string scalar time_tr){
		time = tokens(time)'
		tr_eff = st_data(., "tr·"+ depvar + "·"+ unit_tr)
		eff = (tr_eff, st_data(., invtokens("tr·"+ depvar + "·" :+ tokens(unit_ctrl))))
		pval = J(rows(eff), 3, .)
		for(i = 1; i <= rows(pval); i++) {
			pval[i, 1] = mean((abs(tr_eff[i, 1]) :<= abs(eff[i, .]))')
			pval[i, 2] = mean((tr_eff[i, 1] :<= eff[i, .])')
			pval[i, 3] = mean((tr_eff[i, 1] :>= eff[i, .])')
		}
		rcm_printPval(time, ("Time", "Treatment Effect", "Two-sided ", "Right-sided", "Left-sided"), "p-value of Treatment Effect", (tr_eff, pval), time_tr, 0, (16, 11, 11, 11), 0, 0)
		printf("{p 0 6 2}{txt}Note: (1) The two-sided p-value of the treatment effect for a particular period is definded as the frequency that the absolute values of the placebo effects are greater than or equal to the absolute value of treatment effect.\n{p_end}")
		printf("{p 6 6 2}{txt}(2) The right-sided (left-sided) p-value of the treatment effect for a particular period is definded as the frequency that the placebo effects are greater (smaller) than or equal to the treatment effect.\n{p_end}")
		printf("{p 6 6 2}{txt}(3) If the treatment effects are mostly positive, then the right-sided p-values are recommended; whereas the left-sided p-values are recommended if the treatment effects are mostly negative.\n{p_end}")
		stata("cap drop pval")
		st_store(., st_addvar("float", "pvalTwo"), pval[.,1])
		st_store(., st_addvar("float", "pvalRight"), pval[.,2])
		st_store(., st_addvar("float", "pvalLeft"), pval[.,3])
	}
end

* Version history
* 2.0.0 Optimize the result displayed
* 1.0.1 Add two-sided p-value, right-sided p-value and left-sided p-value
* 1.0.0 Update the display of results
* 0.0.2 Revise the calculation of the p-value
* 0.0.1 Revise the calculation of the p-value and the probability of obtaining a post/pre-treatment MSPE ratio as large as that of treated unit
* 0.0.0 Submit the initial version of rcm
