*! synth2 0.0.1 Guanpeng Yan and Qiang Chen 11/23/2021
capture program drop synth2
program synth2, eclass sortpreserve
	version 16
	preserve
	qui xtset
    if "`r(panelvar)'" == "" | "`r(timevar)'" == "" {
		di as err "panel variable or time variable missing, please use -{bf:xtset} {it:panelvar} {it:timevar}"
		exit 198
    }
	syntax anything, TRUnit(integer) TRPeriod(integer) ///
		[CTRLUnit(numlist min = 1 int sort) ///
		PREPeriod(numlist min = 1 int sort) ///
		POSTPeriod(numlist min = 1 int sort) ///
		XPeriod(passthru) ///
		MSPEPeriod(passthru) ///
		CUStomV(passthru) ///
		nested ///
		allopt ///
		margin(passthru) ///
		maxiter(passthru) ///
		sigf(passthru) ///
		bound(passthru) ///
		placebo(string) ///
		loo ///
		frame(string) ///
		noFIGure ///
		]
	local panelVar "`r(panelvar)'"
	local timeVar "`r(timevar)'"
	cap synth
    if _rc== 199 {
	    di as err `"{bf:synth} must be installed (use Stata command "{bf:ssc install synth, replace}")."'
		exit 198
	}
	/* Check frame */
	if "`frame'" == "" tempname frame
	else {
		capture frame drop `frame'
		qui pwf
		if "`frame'" == "`r(currentframe)'" {
			di as err "invalid frame() -- current frame can not be specified"
			exit 198
		}
		local framename "`frame'"
	}
	/* Check trunit */
	qui levelsof `panelVar', local(unit_n)
	loc check: list trunit in unit_n
	if `check' == 0 {
		di as err "invalid trunit() -- treatment unit not found in {it:panelvar}"
		exit 198
	}
	/* Check ctrlunit */
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
	/* Check trperiod */
	qui levelsof `timeVar', local(time_n)
	loc check: list trperiod in time_n
	if `check' == 0 {
		di as err "invalid trperiod() -- treatment period not found in {it:timelvar}"
		exit 198
	}
	/* Check preperiod */
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
	/* Check postperiod */
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
	gettoken depvar indepvars : anything
	local indepvars = strltrim("`indepvars'")
	qui ds
	mata: synth2_abstract("`anything'", "`r(varlist)'", "`depvar'")
	frame put `panelVar' `timeVar' `depvar' `covariates', into(`frame')
	local graphlist ""
	frame `frame'{
		tempvar panelVarStr timeVarStr
		{
			capture decode `panelVar', gen(`panelVarStr')
			if _rc  qui tostring `panelVar', gen(`panelVarStr') usedisplayformat force
			else qui replace `panelVarStr' = subinstr(`panelVarStr', " ", "", .)
			qui replace `panelVarStr' = strtoname(`panelVarStr', 0) 
		}
		qui levelsof `panelVarStr', local(unit_all) clean
		qui levelsof `panelVarStr' if `panelVar' != `trunit', local(unit_ctrl) clean
		qui levelsof `panelVarStr' if `panelVar' == `trunit', local(unit_tr) clean
		
		qui tostring `timeVar', gen(`timeVarStr') usedisplayformat force
		qui levelsof `timeVarStr', local(time_all) clean
		qui levelsof `timeVarStr' if `timeVar' < `trperiod', local(time_pre) clean
		qui levelsof `timeVarStr' if `timeVar' >= `trperiod', local(time_post) clean
		qui levelsof `timeVarStr' if `timeVar' == `trperiod', local(time_tr) clean
	}	
	qui cap synth `anything', trunit(`trunit') trperiod(`trperiod') `xperiod' `mspeperiod' `customV' `margin' `maxiter' `sigf' `bound' `nested' `allopt'
	if (_rc){
		error _rc
		exit
	}
	matrix weight_vars = vecdiag(e(V_matrix))'
	matrix V_wt = e(V_matrix)
	matrix colname weight_vars = Weight
	frame `frame'{
		capture gen pred·`depvar' = .
		label variable pred·`depvar' "prediction of `depvar'
		mata: synth2_insertMatrix("`panelVar'", "`timeVar'", `trunit', st_matrix("e(Y_synthetic)"), "pred·`depvar'")
		capture gen tr·`depvar' = `depvar' - pred·`depvar'
		label variable tr·`depvar' "treatment effect of `depvar'"
		di as txt "Fitting results in the pre-treatment periods:"
		mata: synth2_sum("`panelVar'", "`timeVar'", `trunit', `trperiod', "`unit_tr'", "`time_tr'", cols(tokens("`unit_ctrl'")), ///
			cols(tokens("`indepvars'")), st_data(., "pred·`depvar'"), st_data(., "tr·`depvar'"), 0, .)
		matrix balance = e(X_balance), J(rowsof(e(X_balance)), 1 ,.)
		matrix colnames balance = Treated Synthetic Control
	}
	if "`preperiod'" == "" qui levelsof `timeVar' if `timeVar' < `trperiod', local(preperiod)
	synth2_balance `indepvars', panelVar(`panelVar') timeVar(`timeVar') trunit(`trunit') `xperiod' preperiod(`preperiod') frame(`frame')
	matrix coljoinbyname balance = weight_vars balance
	mata: temp = st_matrixrowstripe("balance"); ///
		st_matrix("balance", (st_matrix("balance")[., 1..2], st_matrix("balance")[.,3], ((st_matrix("balance")[.,3] :/ st_matrix("balance")[.,2]) :- 1) :* 100, st_matrix("balance")[.,4], ((st_matrix("balance")[.,4] :/ st_matrix("balance")[.,2]) :- 1) :* 100)); ///
		st_matrixrowstripe("balance", temp);
	mata: st_matrixcolstripe("balance", (J(6, 1, ""), ("Vweight", "Treated", "ValueSyntheticControl", "BaisSyntheticControl", "ValueAverageControl", "BiasAverageControl")'))
	tempname balanceFrame
	cap frame create `balanceFrame'
	frame `balanceFrame'{
		qui svmat balance, name(col)
		mata: st_sstore(., st_addvar("strL", "variable"), st_matrixrowstripe("balance")[., 2])
		cap replace BaisSyntheticControl = BaisSyntheticControl
		cap replace BiasAverageControl = BiasAverageControl
		graph dot (asis) BiasAverageControl BaisSyntheticControl, over(variable) yline(0, lcolor(gs10))  marker(1, ///
			msymbol(O)) marker(2, msymbol(X)) ytitle("Standardized % Bias across Covariates") ///
			legend(lab(2 "Synthetic Control") lab(1 "Average Control")) name(bias, replace) title("Predictor Balance") nodraw
			//legend(pos(5) ring(0) lab(1 "Control") lab(2 "Synthetic")) name(bias, replace) nodraw
		local graphlist = "`graphlist' bias"
	}
	di _newline "{p 0 0 2}{txt}Predictor balance in the pre-treatment periods:{p_end}"
	mata: synth2_print4(st_matrixrowstripe("balance")[., 2], ("Covariate", "V.weight", "Treated ", "Value     ", "Bias", "Value    ", "Bias "), ///
		(" Synthetic Control", " Average Control"), st_matrix("balance"), ., 0, (8, 10, 10, 7, 10, 7), 0, 0)
	di `"{p 0 6 2}{txt}Note: "V.weight" is the optimal covariate weight in the diagonal of V matrix.{p_end}"'
	di `"{p 6 6 2}{txt}"Synthetic Control" is the weighted average of control units in the donor pool with optimal weights.{p_end}"'
	di `"{p 6 6 2}{txt}"Average Control" is the simple average of control units in the donor pool with equal weights.{p_end}"'
	di
	tempname weightVarsFrame
	cap frame create `weightVarsFrame'
	frame `weightVarsFrame'{
		qui svmat weight_vars, name(col)
		mata: st_sstore(., st_addvar("strL", "variable"), st_matrixrowstripe("weight_vars")[., 2])
		graph hbar (asis) Weight, over(variable, sort(Weight) descending) ytitle(weight) name(weight_vars, replace) title(Optimal Covariate Weights) nodraw
		local graphlist = "`graphlist' weight_vars"
	}
	di "{p 0 6 2}{txt}Optimal Unit Weights:{p_end}"
	frame `frame'{
		mata: synth2_weight("e(W_weights)")
	}
	tempname weightUnitFrame
	cap frame create `weightUnitFrame'
	frame `weightUnitFrame'{
		qui svmat weight_unit, name(col)
		mata: st_sstore(., st_addvar("strL", "unit"), st_matrixrowstripe("weight_unit")[., 2])
		graph hbar (asis) Weight, over(unit, sort(Weight) descending) ytitle(weight) name(weight_unit, replace) title(Optimal Unit Weights) nodraw
		local graphlist = "`graphlist' weight_unit"
	}
	di
	frame `frame'{
		di _newline as txt "Prediction results in the post-treatment periods:"
		mata: synth2_print(st_sdata(., "`timeVarStr'"), ("Time", "Actual Outcome", " Predicted Outcome", " Treatment Effect"), ///
			st_data(., "`depvar' pred·`depvar' tr·`depvar'"), ///
			selectindex((st_data(., "`panelVar'") :== `trunit') :& (st_data(., "`timeVar'") :>= `trperiod')), 1, (13, 17, 16), 0, 0)
		if("`figure'" == ""){
			qui levelsof `timeVar', local(temp) clean
			loc pos: list posof "`trperiod'" in temp
			loc pos = `pos' - 1
			loc xline: word `pos' of `temp'
			twoway (line `depvar' `timeVar') (line pred·`depvar' `timeVar', lpattern(dash)) if `panelVar' == `trunit', ///
					title("Actual and Predicted Outcomes") xline(`xline', lp(dot) lc(black)) name(pred, replace) ///
					ytitle(`depvar')  legend(order(1 "Actual" 2 "Predicted")) nodraw
			line tr·`depvar' `timeVar', xline(`xline', lp(dot) lc(black)) yline(0, lp(dot) lc(black)) ///
					title("Treatment Effects") name(eff, replace) ///
					ytitle("treatment effects of `depvar'") nodraw
			local graphlist = "`graphlist' pred eff"
		}
	}
	/* Implement the placebo test using fake unit and/or time */
	if "`placebo'" != "" {
		ereturn local trperiod "`trperiod'"
		ereturn local trunit "`trunit'"
		if(strpos("`placebo'", "unit") != 0 & strpos("`placebo'", "unit(") == 0) local placebo = subinstr("`placebo'", "unit", "unit(.)", .)
		synth2_placebo `anything', trunit(`trunit') trperiod(`trperiod') ///
			panelVar(`panelVar') timeVar(`timeVar') panelVarStr(`panelVarStr') timeVarStr(`timeVarStr') ///
			unit_all(`unit_all') unit_tr(`unit_tr') unit_ctrl(`unit_ctrl') time_tr(`time_tr') time_all(`time_all') ///
			frame(`frame') `xperiod' `mspeperiod' `placebo' `figure' `nested' `allopt' `margin' `maxiter' `sigf' `bound'
		local graphlist = "`graphlist' `e(graphlist)'"
		capture mat pval = e(pval)
	}
	/* Implement Robustness Test */
	if("`loo'" != ""){
		di _newline as txt "Implementing leave-one-out robustness test that excludes one control unit with a nonzero weight " _continue
		local linePred ""
		local lineEff ""
		foreach loounit in `loounitlist'{
			frame `frame': qui levelsof `panelVarStr' if `panelVar' == `loounit', local(unit_loo) clean
			di as res "`unit_loo'"  as txt "..." _continue
			qui levelsof `panelVar' if (`panelVar' != `trunit') & (`panelVar' != `loounit'), local(remunitlist)
			qui cap synth `anything', trunit(`trunit') trperiod(`trperiod') counit(`remunitlist') `xperiod' `mspeperiod' `customV' `margin' `maxiter' `sigf' `bound' `nested' `allopt'
			if(_rc){
			    error _rc
				exit
			}
			frame `frame'{
				qui cap gen pred·`depvar'·rmv`unit_loo' = .
				qui label variable pred·`depvar'·rmv`unit_loo' "prediction of `depvar' (`unit_loo' excluded) generated by 'robustness test'"
				mata: synth2_insertMatrix("`panelVar'", "`timeVar'", `trunit', st_matrix("e(Y_synthetic)"), "pred·`depvar'·rmv`unit_loo'")
				qui cap gen tr·`depvar'·rmv`unit_loo' = `depvar' - pred·`depvar'·rmv`unit_loo'
				qui label variable tr·`depvar'·rmv`unit_loo' "treatment effect of `depvar' (`unit_loo' excluded) generated by 'robustness test'"
				local linePred " `linePred' (line pred·`depvar'·rmv`unit_loo' `timeVar', lc(gs8%20) lp(solid)) "
				local lineEff " `lineEff' (line tr·`depvar'·rmv`unit_loo' `timeVar', lc(gs8%20) lp(solid)) "
			}
		}
		di _newline _newline as txt "Robustness test results in the post-treatment periods:"
		frame `frame'{
			mata: st_store(., (st_addvar("float", "pred·`depvar'·loomin"), st_addvar("float", "pred·`depvar'·loomax")), ///
				rowminmax(st_data(., ("pred·`depvar'·rmv" :+ tokens("`unit_loolist'")))))
			qui label variable pred·`depvar'·loomin "min prediction of `depvar' generated by 'robustness test'"
			qui label variable pred·`depvar'·loomax "max prediction of `depvar' generated by 'robustness test'"
			mata: st_store(., (st_addvar("float", "tr·`depvar'·loomin"), st_addvar("float", "tr·`depvar'·loomax")), ///
				rowminmax(st_data(., ("tr·`depvar'·rmv" :+ tokens("`unit_loolist'")))))
			qui label variable tr·`depvar'·loomin "min treatment effect of `depvar' generated by 'robustness test'"
			qui label variable tr·`depvar'·loomax "max treatment effect of `depvar' generated by 'robustness test'"
			mata: synth2_print3(st_sdata(., "`timeVarStr'"), ("Time", "Actual ", "Predicted ", "Min ", "Max "), ("Outcome", "Outcome (LOO)"), st_data(., "`depvar' pred·`depvar' pred·`depvar'·loomin pred·`depvar'·loomax"), selectindex((st_data(., "`panelVar'") :== `trunit') :& (st_data(., "`timeVar'") :>= `trperiod')), 0, (10, 10, 10, 10), 0, 0)
			di "{p 0 6 2}{txt}Note: The last two columns report the minimum and maximum outcomes when one control unit with a nonzero weight is excluded at a time.{p_end}"
			di
			mata: synth2_print2(st_sdata(., "`timeVarStr'"), ("Time", "Treatment Effect", "Min ", "Max "), "Treatment Effect (LOO)", st_data(., "tr·`depvar' tr·`depvar'·loomin tr·`depvar'·loomax"), selectindex((st_data(., "`panelVar'") :== `trunit') :& (st_data(., "`timeVar'") :>= `trperiod')), 0, (18, 12, 12), 0, 0)
			di "{p 0 6 2}{txt}Note: The last two columns report the minimum and maximum treatment effects when one control unit with a nonzero weight is excluded at a time.{p_end}"
		}
		if "`figure'" == ""{
			frame `frame'{
				qui levelsof `timeVar', local(temp) clean
				loc pos: list posof "`trperiod'" in temp
				loc pos = `pos' - 1
				loc xline: word `pos' of `temp'
				twoway (line `depvar' `timeVar', lp(solid)) (line pred·`depvar' `timeVar', lp(dash)) `linePred' ///
					if `panelVar' == `trunit', xline(`xline', lp(dot) lc(black)) title("Leave-one-out Robustness Test") ///
					legend(order(1 "Actual" 2 "Predicted" 3 "Predicted (LOO)")  rows(1)) ///
					name(pred_loo, replace) ytitle(`depvar') nodraw
				twoway (line tr·`depvar' `timeVar', lp(solid)) `lineEff' if `panelVar' == `trunit', ///
					xline(`xline', lp(dot) lc(black)) yline(0, lp(dot) lc(black)) ///
					title("Leave-one-out Robustness Test") name(eff_loo, replace) ///
					ytitle("treatment effects of `depvar'") ///
					legend(order(1 "Treatment Effect" 2 "Treatment Effect (LOO)")) nodraw
				local graphlist = "`graphlist' pred_loo eff_loo"
			}
		}
	}
	/* Display graphs */
	if "`figure'" == "" foreach graph in `graphlist'{
		capture graph display `graph'
	}
	ereturn clear
	capture ereturn matrix pval = pval
	capture if rowsof(mspe) > 1 ereturn matrix mspe = mspe
	ereturn matrix bal = balance
	ereturn matrix U_wt= weight_unit
	ereturn matrix V_wt = V_wt
	ereturn local frame "`framename'"
	ereturn local time_post "`time_post'"
	ereturn local time_pre "`time_pre'"
	ereturn local time_tr "`time_tr'"
	ereturn local time_all "`time_all'"
	ereturn local unit_ctrl "`unit_ctrl'"
	ereturn local unit_tr "`unit_tr'"
	ereturn local unit_all "`unit_all'"
	ereturn local preds "`indepvars'"
	ereturn local respo "`depvar'"
	ereturn local varlist "`anything'"
	ereturn local timevar "`timeVar'"
	ereturn local panelvar "`panelVar'"
	ereturn scalar N = _N
	ereturn scalar T = wordcount("`time_all'")
	ereturn scalar T0 = wordcount("`time_pre'")
	ereturn scalar T1 = wordcount("`time_post'")
	ereturn scalar K = wordcount("`indepvars'")
	ereturn scalar J = wordcount("`unit_all'")
	ereturn scalar mae = mae
	ereturn scalar mse = mse
	ereturn scalar rmse = rmse
	ereturn scalar r2 = r2

	di _newline as txt "Finished."
end

capture program drop synth2_placebo
program synth2_placebo, eclass sortpreserve
	version 16
	preserve
	local trperiod = `e(trperiod)'
	local trunit = `e(trunit)'
	syntax anything, trunit(numlist) trperiod(numlist) [panelVar(string) timeVar(string) panelVarStr(string) timeVarStr(string) ///
		unit_all(string) unit_tr(string) unit_ctrl(string) ///
		time_all(string) time_tr(string) frame(string) ///
		xperiod(passthru) ///
		mspeperiod(passthru) ///
		customV(passthru) ///
		margin(passthru) ///
		maxiter(passthru) ///
		sigf(passthru) ///
		bound(passthru) ///
		unit(numlist missingokay) period(numlist min = 1 int sort <`trperiod') Cutoff(numlist min = 1 max = 1 >=1) ///
		show(numlist min = 1 max = 1 >=1) noFIGure nested allopt]
	
	gettoken depvar indepvars : anything
	local graphlist ""
	if("`unit'" != "."){
		local unit_pboList ""
		frame `frame'{
			foreach i in `unit'{
				qui levelsof `panelVarStr' if `panelVar' == `i', local(temp) clean
				local unit_pboList "`unit_pboList' `temp'"
			}			
		}
	}
	else local unit_pboList "`unit_ctrl'"
	
	qui levelsof `timeVar', local(temp) clean
	loc pos: list posof "`trperiod'" in temp
	loc pos = `pos' - 1
	loc xline: word `pos' of `temp'
	if("`unit'" != ""){
		di _newline as txt "Implementing placebo test using fake treatment unit " _continue
		local tsline ""
		local unit_pboSel ""
		local unit_pboRmv ""
		foreach unit_pbo in `unit_pboList'{
			di as res "`unit_pbo'"  as txt "..." _continue
			qui frame `frame': levelsof `panelVar' if `panelVarStr' == "`unit_pbo'", local(pbounit) clean
			qui cap synth `anything', trunit(`pbounit') trperiod(`trperiod') `xperiod' `mspeperiod' `customV' `margin' `maxiter' `sigf' `bound' `nested' `allopt'
			if _rc {
			    error _rc
				exit
			}
			frame `frame'{
				capture gen pred·`depvar' = .
				mata: synth2_insertMatrix("`panelVar'", "`timeVar'", `pbounit', st_matrix("e(Y_synthetic)"), "pred·`depvar'")
				qui replace tr·`depvar' = `depvar'- pred·`depvar' if `panelVar' == `pbounit'
				mata: synth2_sum("`panelVar'", "`timeVar'", `pbounit', `trperiod', "`unit_tr'", "`time_tr'", ., ., st_data(., "pred·`depvar'"), ///
					st_data(., "tr·`depvar'"), 1, ("`cutoff'" == "" ? . : strtoreal("`cutoff'")))
				if(`isRmv' == 0){
					local unit_pboSel "`unit_pboSel' `unit_pbo'"
					local line " `line' (line tr·`depvar' `timeVar' if `panelVar' == `pbounit', lp(solid) lc(gs8%20)) "
				}
				else local unit_pboRmv "`unit_pboRmv' `unit_pbo'"
			}
		}
		matrix colnames mspe = PreMSPE PostMSPE RatioPostPre RatioTrCtrl
		matrix rownames mspe = `unit_tr' `unit_pboList'
		di _newline _newline as txt "Placebo test results using fake treatment units:"
		mata: synth2_print(tokens("`unit_tr' `unit_pboList'")', ("Unit", "Pre MSPE ", " Post MSPE ", "Post/Pre MSPE", "  Pre MSPE of Fake Unit/Pre MSPE of Treated Unit"), st_matrix("mspe"), ., 0, (9, 9, 13, 24), 0, 0)
		if "`unit_pboRmv'" != "" {
			mata: printf(stritrim(sprintf( ///
			"{p 0 6 2}{txt}Note: (1) The probability of obtaining a post/pre-treatment MSPE ratio as large as {res}`unit_tr'{txt}'s is{res}%10.4f{txt}.{p_end}\n", mean((st_matrix("mspe")[1, 3] :<= st_matrix("mspe")[. , 3])))))
			di "{p 6 6 2}{txt}(2) Total{res}", wordcount("`unit_pboRmv'"), "{txt}units with pre-treatment MSPE {res}`cutoff' {txt}times larger than the treated unit are excluded in computing pointwise p-values, including {res}`unit_pboRmv'{txt}.{p_end}"
		}
		else mata: printf(stritrim(sprintf( ///
			"{p 0 6 2}{txt}Note: The probability of obtaining a post/pre-treatment MSPE ratio as large as {res}`unit_tr'{txt}'s is{res}%10.4f{txt}.{p_end}\n", mean((st_matrix("mspe")[1, 3] :<= st_matrix("mspe")[. , 3])))))
		mata: printf("\n{txt}Placebo test results using fake treatment units (continued" + ///
			("`cutoff'" == "" ? "" : (", cutoff = {res}`cutoff'")) + "{txt}):\n")
		frame `frame'{
			mata: synth2_placebo(st_data(., "`timeVar'"), st_sdata(., "`panelVarStr'"), st_sdata(., "`timeVarStr'"), "`unit_tr'", "`unit_pboSel'", `trperiod', st_data(., "tr·`depvar'"))
			di "{p 0 6 2}{txt}Note: (1) The two-sided p-value of the treatment effect for a particular period is defined as the frequency that the absolute values of the placebo effects are greater than or equal to the absolute value of treatment effect.{p_end}"
			di "{p 6 6 2}{txt}(2) The right-sided (left-sided) p-value of the treatment effect for a particular period is defined as the frequency that the placebo effects are greater (smaller) than or equal to the treatment effect.{p_end}"
			di "{p 6 6 2}{txt}(3) If the treatment effects are mostly positive, then the right-sided p-values are recommended; whereas the left-sided p-values are recommended if the treatment effects are mostly negative.{p_end}"
			label variable pvalTwo "two-sided p-value of treatment effect generated by 'placebo unit'"
			label variable pvalRight "right-sided p-value of treatment effect generated by 'placebo unit'"
			label variable pvalLeft "left-sided p-value of treatment effect generated by 'placebo unit'"
		}
		if "`figure'" == ""{
			frame `frame'{
				twoway (line tr·`depvar' `timeVar' if `panelVar' == `trunit') `line', ///
					xline(`xline', lp(dot) lc(black)) yline(0, lp(dot) lc(black)) ///
					title("Placebo Test Using Fake Treatment Units") name(eff_pboUnit, replace) ///
					ytitle("treatment/placebo effects of `depvar'") ///
					legend(order(1 "Treatment Effect" 2 "Placebo Effect")) nodraw
				local graphlist = "`graphlist' eff_pboUnit"
			}
			tempname placeboUnitframe
			
			frame create `placeboUnitframe'
			frame `placeboUnitframe'{
				qui svmat mspe, name(col)
				mata: st_sstore(., st_addvar("strL", "unit"), tokens("`unit_tr' `unit_pboList'")')
				if ("`show'" != "") {
					qui gsort -RatioPostPre
					qui drop if _n >`show'
				}
				graph hbar (asis) RatioPostPre, over(unit, sort(RatioPostPre) descending label(labsize(vsmall))) ///
				ytitle("Ratios of Post-treatment MSPE to Pre-treatment MSPE") ///
				title("Placebo Test Using Fake Treatment Units") name("ratio_pboUnit", replace) nodraw
			}
			local graphlist = "`graphlist' ratio_pboUnit"
			frame `frame'{
				twoway connected pvalTwo `timeVar' if `panelVar' == `trunit' & `timeVar' >= `trperiod', ///
					ytitle("two-sided p-values of treatment effects of `depvar'") ///
					yline(0.05 0.1, lp(dot) lc(black)) ylabel(0(0.1)1) ///
					title("Placebo Test Using Fake Treatment Units") name(pvalTwo_pboUnit, replace) nodraw
				twoway connected pvalRight `timeVar' if `panelVar' == `trunit' & `timeVar' >= `trperiod', ///
					ytitle("right-sided p-values of treatment effects of `depvar'") ///
					yline(0.05 0.1, lp(dot) lc(black)) ylabel(0(0.1)1) ///
					title("Placebo Test Using Fake Treatment Units") name(pvalRight_pboUnit, replace) nodraw
				twoway connected pvalLeft `timeVar' if `panelVar' == `trunit' & `timeVar' >= `trperiod', ///
					ytitle("left-sided p-values of treatment effects of `depvar'") ///
					yline(0.05 0.1, lp(dot) lc(black)) ylabel(0(0.1)1) ///
					title("Placebo Test Using Fake Treatment Units") name(pvalLeft_pboUnit, replace) nodraw
				local graphlist = "`graphlist' pvalTwo_pboUnit pvalRight_pboUnit pvalLeft_pboUnit"
			}
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
			frame `frame': qui levelsof `timeVarStr' if `timeVar' == `pboperiod', local(time_pbo) clean
			loc pos: list posof "`pboperiod'" in temp
			loc pos = `pos' - 1
			loc xlinePbo: word `pos' of `temp'
			di as res "`time_pbo'" as txt "..." _continue
			qui cap synth `anything', trunit(`trunit') trperiod(`pboperiod') `xperiod' `mspeperiod' `customV' `margin' `maxiter' `sigf' `bound' `nested' `allopt'
			if _rc {
			    error _rc
				exit
			}
			frame `frame'{
				loc pboTimeVar = strtoname("`depvar'·`time_pbo'")
				capture gen pred·`pboTimeVar' = .
				mata: synth2_insertMatrix("`panelVar'", "`timeVar'", `trunit', st_matrix("e(Y_synthetic)"), "pred·`pboTimeVar'")
				capture gen tr·`pboTimeVar' = `depvar' - pred·`pboTimeVar'
				label variable pred·`pboTimeVar' "prediction of `depvar' generated by 'placebo period `time_pbo''"
				label variable tr·`pboTimeVar' "treatment effect of `depvar' generated by 'placebo period `time_pbo''"
				if "`figure'" == "" {
					twoway (line `depvar' `timeVar' if `panelVar' == `trunit') ///
						(line pred·`pboTimeVar' `timeVar' if `panelVar' == `trunit', lpattern(dash)), ///
						title("Placebo Test Using Fake Treatment Time `time_pbo'") xline(`xline' `xlinePbo', lp(dot) lc(black)) ///
						name(pred_pboTime`pboperiod', replace) ytitle(`depvar')  ///
						legend(order(1 "Actual" 2 "Predicted")) nodraw
					local graphlist = "`graphlist' pred_pboTime`pboperiod'"
					line tr·`pboTimeVar' `timeVar' if `panelVar' == `trunit', ///
						xline(`xline' `xlinePbo', lp(dot) lc(black)) yline(0, lp(dot) lc(black)) ///
						title("Placebo Test Using Fake Treatment Time `time_pbo'") name(eff_pboTime`pboperiod', replace) ///
						ytitle("placebo effects of `depvar'") nodraw
					local graphlist = "`graphlist' eff_pboTime`pboperiod'"
				}
			}
		}
		di
		foreach pboperiod in `period'{
			frame `frame': qui levelsof `timeVarStr' if `timeVar' == `pboperiod', local(time_pbo) clean
			loc pboTimeVar = strtoname("`depvar'·`pboperiod'")
			di _newline as txt "Placebo test results using fake treatment time " as res "`time_pbo'" as txt":"
			frame `frame': mata: synth2_print(st_sdata(., "`timeVarStr'"), ("Time", "Actual Outcome", " Predicted Outcome", " Treatment Effect"), ///
				st_data(., "`depvar' pred·`pboTimeVar' tr·`pboTimeVar'"), ///
				selectindex((st_data(., "`panelVar'") :== `trunit') :& (st_data(., "`timeVar'") :>= `pboperiod')), 1, (13, 17, 16), 0, 0)
		}
	}
	capture ereturn matrix pval = pval
	ereturn local graphlist "`graphlist'"
end

**# Balance
capture program drop synth2_balance
program synth2_balance
	version 16
	preserve
	syntax anything, panelVar(string) timeVar(string) trunit(integer) preperiod(numlist) [xperiod(numlist)] frame(string)
	if "`xperiod'" == "" mata: st_local("ifperiod", "(" + invtokens("`timeVar' == " :+ tokens("`preperiod'"), " | ") + ")")
	else mata: st_local("ifperiod", "(" + invtokens("`timeVar' == " :+ tokens("`xperiod'"), " | ") + ")")
	foreach var of local anything{
		local period ""
		local rownumb = rownumb(balance,"`var'")
		if(strpos("`var'","(") > 0){
			local period = substr("`var'", strpos("`var'", "(") + 1, strlen("`var'") - strpos("`var'","(") - 1)
			qui numlist "`period'"
			local period "`r(numlist)'"
			local var = substr("`var'", 1, strpos("`var'","(") - 1)
		}
		if("`period'" == "") local period "`ifperiod'"
		else mata: st_local("period", "(" + invtokens("`timeVar' == " :+ tokens("`period'"), " | ") + ")")
		cap qui sum `var' if `period' & `panelVar' != `trunit'
		matrix balance[`rownumb', 3] = r(mean)
	}
end

version 16
mata:
	void synth2_abstract(string scalar anything, string scalar varlist, string scalar depvar){
		anything = tokens(usubinstr(usubinstr(anything, "(", " ", .), ")", " ", .))
		covariates = ""
		for(i = 1; i <= cols(anything); i++){
			if((sum(anything[i] :==  tokens(varlist)) > 0) & (anything[i] != depvar)) covariates = covariates + " " + anything[i]
		}
		st_local("covariates", invtokens(uniqrows(tokens(covariates)')'))
	}
	void synth2_insertMatrix(string scalar panelVar, string scalar timeVar, real scalar unit_tr, real matrix M, string scalar insertVar){
		real matrix data
		st_view(data, ., invtokens((panelVar, timeVar, invtokens(insertVar))))
		data[selectindex(data[., 1] :== unit_tr), 3..cols(data)] = M
	}
	void synth2_sum(string scalar panelVar, string scalar timeVar, real scalar trunit, real scalar trperiod, string scalar unit_tr, string scalar time_tr, real scalar J, real scalar K, real matrix respo, real matrix effect, real scalar isplacebo, real scalar cut){
		indexPre = selectindex((st_data(., timeVar) :< trperiod) :& (st_data(., panelVar) :== trunit))
		indexPost = selectindex((st_data(., timeVar) :>= trperiod) :& (st_data(., panelVar) :== trunit))
		// MSPE_pre = mean(effect[indexPre, .] :^ 2)
		MSPE_pre =  st_matrix("e(RMSPE)")^2
		MSPE_post = mean(effect[indexPost, .] :^ 2)
		// MSE = MSPE_pre
		MSE = st_matrix("e(RMSPE)")^2
		// RMSE = sqrt(MSE)
		RMSE = st_matrix("e(RMSPE)")
		MAE = mean(abs(effect[indexPre, .]))
		R2 = 1 - sum(effect[indexPre, .] :^ 2)/sum((respo[indexPre, .] :- mean(respo[indexPre, .])):^ 2)
		if(isplacebo == 0){
			wide = 3
			printf("{hline " + strofreal(wide + 77) + "}\n")
			printf(" {txt}%-24uds : {res}%10uds {space "+ strofreal(wide) + "} {txt}%-24uds : {res}%10uds\n", "Treated Unit", abbrev(unit_tr, 10), "Treatment Time", abbrev(time_tr, 10))
			printf("{hline " + strofreal(wide + 77) + "}\n")
			printf(" {txt}%-24uds =  {res}%9.5f {space "+ strofreal(wide) + "} {txt}%-24uds =  {res}%9.0f\n", "Mean Absolute Error", MAE, "Number of Control Units", J)
			printf(" {txt}%-24uds =  {res}%9.5f {space "+ strofreal(wide) + "} {txt}%-24uds =  {res}%9.0f\n", "Mean Squared Error", MSE, "Number of Covariates", K)
			printf(" {txt}%-24uds =  {res}%9.5f {space "+ strofreal(wide) + "} {txt}%-24uds =  {res}%9.5f\n", "Root Mean Squared Error", RMSE, "R-squared", R2)
			printf("{hline " + strofreal(wide + 77) + "}\n")
			st_numscalar("mse", MSE)
			st_numscalar("mae", MAE)
			st_numscalar("rmse", RMSE)
			st_numscalar("r2", R2)
			st_matrix("mspe", (MSPE_pre, MSPE_post, MSPE_post/MSPE_pre, 1))
		}
		else{
			ratio = MSPE_pre/st_matrix("mspe")[1, 1]
			st_matrix("mspe", st_matrix("mspe")\(MSPE_pre, MSPE_post, MSPE_post/MSPE_pre, ratio))
			if((cut == .) | (ratio <= cut)) st_local("isRmv", "0")
			else st_local("isRmv", "1")
		}
	}
	void synth2_weight(string scalar name){
		rownames = st_matrixrowstripe(name)[., 2]
		M = st_matrix(name)[., .]
		delRownames = rownames[selectindex(M[., 2] :== 0), .]'
		rownames = rownames[selectindex(M[., 2] :> 0), .]
		M = M[selectindex(M[., 2] :> 0), .]
		M = sort(((1..rows(M))', M), -3)
		rownames = rownames[M[., 1], .]
		st_local("loounitlist", invtokens(strofreal(M[., 2]')))
		st_local("unit_loolist", invtokens(rownames'))
		M = M[., 3]
		st_matrix("weight_unit", M)
		st_matrixcolstripe("weight_unit", ("", "Weight"))
		st_matrixrowstripe("weight_unit", (J(rows(M), 1, ""), rownames))
		synth2_print(rownames, ("Unit", "U.weight"), M, ., 0, 10, 0, 0)
		if(cols(delRownames) > 0) printf("{p 0 6 2}{txt}Note: The unit {res}" + invtokens(delRownames) ///
			+ "{txt} in the donor pool " + (cols(delRownames) > 1? "get" : "gets") + " a weight of {res}0{txt}.\n")
	}
	void synth2_print(string matrix rownames, string matrix colnames, real matrix M, real matrix indexRow, real scalar isMean, real matrix wideM, real scalar extend, real scalar isInt){
		if (rows(indexRow) != 1){
			rownames = rownames[indexRow, .]
			M = M[indexRow, .]
		}
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
		for(i = 1; i <= rows(M); i++){
			printf(sprintf(" {txt}%%%guds {c |}{res}", wide), rownames[i])
			for(j = 1; j <= cols(M); j++){
			    if(isInt == 0) printf(sprintf(" %%%g.4f ", wideM[j]), M[i,j])
				else printf(sprintf(" %%%g.0g ", wideM[j]), M[i,j])
			}
			printf("\n")
		}
		if(isMean == 1){
			printf(sprintf("{hline %g}{c +}", wide + 2))
			for(j = 1; j <= cols(colnames) - 1; j++) printf(sprintf("{hline %g}", wideM[j] + 2))
			printf(sprintf("{hline %g}\n", extend))
			meanM = mean(M[1..rows(M), .])
			printf(sprintf(" {txt}%%~%guds {c |}{res}", wide), "Mean")
			for(j = 1; j <= cols(M); j++){
				printf(sprintf(" %%%g.4f ", wideM[j]), meanM[., j])
			}
			printf("\n")
		}else if(isMean == 2){
			printf(sprintf("{hline %g}{c +}", wide + 2))
			for(j = 1; j <= cols(colnames) - 1; j++) printf(sprintf("{hline %g}", wideM[j] + 2))
			printf(sprintf("{hline %g}\n", extend))
			sumM = sum(M[1..rows(M), .])
			printf(sprintf(" {txt}%%~%guds {c |}{res}", wide), "Sum")
			for(j = 1; j <= cols(M); j++){
				printf(sprintf(" %%%g.4f ", wideM[j]), sumM[., j])
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
	void synth2_print2(string matrix rownames, string matrix colnames, string scalar colname, real matrix M, real matrix indexRow, real scalar isMean, real matrix wideM, real scalar extend, real scalar isInt){
		if (rows(indexRow) != 1){
			rownames = rownames[indexRow, .]
			M = M[indexRow, .]
		}
		wide = max(udstrlen((rownames[1..rows(rownames),1]\colnames[1])))
		printf(sprintf("{hline %g}{c TT}", wide + 2))
		for(j = 1; j <= cols(colnames) - 1; j++) printf(sprintf("{hline %g}", wideM[j] + 2))
		printf(sprintf("{hline %g}\n", extend))
		
		printf(sprintf(" {txt}%%~%guds {c |}", wide), colnames[1])
		printf(sprintf("{txt}%%%guds", wideM[1] + 2), colnames[2])
		printf(sprintf("{txt}%%~%guds\n", sum(wideM[2..cols(wideM)]) + 2*(cols(wideM)-1)), colname)
		
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
		for(i = 1; i <= rows(M); i++){
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
			meanM = mean(M[1..rows(M), .])
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
	void synth2_print3(string matrix rownames, string matrix colnames, string matrix colname, real matrix M, real matrix indexRow, real scalar isMean, real matrix wideM, real scalar extend, real scalar isInt){
		if (rows(indexRow) != 1){
			rownames = rownames[indexRow, .]
			M = M[indexRow, .]
		}
		wide = max(udstrlen((rownames[1..rows(rownames),1]\colnames[1])))
		printf(sprintf("{hline %g}{c TT}", wide + 2))
		for(j = 1; j <= cols(colnames) - 1; j++) printf(sprintf("{hline %g}", wideM[j] + 2))
		printf(sprintf("{hline %g}\n", extend))
		
		printf(sprintf(" {txt}%%~%guds {c |}", wide), colnames[1])
		printf(sprintf("{txt}%%~%guds", sum(wideM[1..2]) + 4), colname[1])
		printf(sprintf("{txt}%%~%guds\n", sum(wideM[3..4]) + 4), colname[2])
		
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
			else printf(sprintf("%%%guds", wideM[j - 1] + 2), colnames[j])
		}
		printf(sprintf("\n{hline %g}{c +}", wide + 2))
		for(j = 1; j <= cols(colnames) - 1; j++) printf(sprintf("{hline %g}", wideM[j] + 2))
		printf(sprintf("{hline %g}\n", extend))
		for(i = 1; i <= rows(M); i++){
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
			meanM = mean(M[1..rows(M), .])
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
	void synth2_print4(string matrix rownames, string matrix colnames, string matrix colname, real matrix M, real matrix indexRow, real scalar isMean, real matrix wideM, real scalar extend, real scalar isInt){
		if (rows(indexRow) != 1){
			rownames = rownames[indexRow, .]
			M = M[indexRow, .]
		}
		wide = max(udstrlen((rownames[1..rows(rownames),1]\colnames[1])))
		printf(sprintf("{hline %g}{c TT}", wide + 2))
		for(j = 1; j <= cols(colnames) - 1; j++) printf(sprintf("{hline %g}", wideM[j] + 2))
		printf(sprintf("{hline %g}\n", extend))
		
		printf(sprintf(" {txt}%%~%guds {c |}", wide), colnames[1])
		printf(sprintf("{txt}%%%guds", wideM[1] + 2), colnames[2])
		printf(sprintf("{txt}%%%guds", wideM[2] + 2), colnames[3])
		printf(sprintf("{txt}%%~%guds", sum(wideM[3..4]) + 4), colname[1])
		printf(sprintf("{txt}%%~%guds\n", sum(wideM[5..6]) + 4), colname[2])
		
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
				if(j == 2 | j == 3) printf("{space %g}", wideM[j - 1] + 2)
				else printf(sprintf("%%%guds", wideM[j - 1] + 2), colnames[j])
			}
		}
		printf(sprintf("\n{hline %g}{c +}", wide + 2))
		for(j = 1; j <= cols(colnames) - 1; j++) printf(sprintf("{hline %g}", wideM[j] + 2))
		printf(sprintf("{hline %g}\n", extend))
		for(i = 1; i <= rows(M); i++){
			printf(sprintf(" {txt}%%%guds {c |}{res}", wide), rownames[i])
			for(j = 1; j <= cols(M); j++){
			    if(j != 4 & j != 6) printf(sprintf(" %%%g.4f ", wideM[j]), M[i,j])
				else printf(sprintf(" %%%g.2f%%%%", wideM[j]), M[i,j])
			}
			printf("\n")
		}
		if(isMean == 1){
			printf(sprintf("{hline %g}{c +}", wide + 2))
			for(j = 1; j <= cols(colnames)-1; j++) printf(sprintf("{hline %g}", wideM[j] + 2))
			printf(sprintf("{hline %g}\n", extend))
			meanM = mean(M[1..rows(M), .])
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
	void synth2_placebo(real matrix timeVar, string matrix panelVarStr, string matrix timeVarStr, string scalar unit_tr, string scalar unit_pboSel, real scalar trperiod, real matrix respo){
		real matrix pvalM
		indexRow = selectindex((panelVarStr :== unit_tr) :& (timeVar :>= trperiod))
		tr_eff = respo[indexRow,]
		unit_list = tokens(unit_pboSel)
		eff = tr_eff
		for(i = 1; i<= cols(unit_list); i++){
			tempIndexRow = selectindex((panelVarStr :== unit_list[i]) :& (timeVar :>= trperiod))
			eff = (eff, respo[tempIndexRow, .])
		}
		pval = J(rows(eff), 3, .)
		for(i = 1; i <= rows(pval); i++) {
			pval[i, 1] = mean((abs(tr_eff[i, 1]) :<= abs(eff[i, .]))')
			pval[i, 2] = mean((tr_eff[i, 1] :<= eff[i, .])')
			pval[i, 3] = mean((tr_eff[i, 1] :>= eff[i, .])')
		}
		synth2_print2(timeVarStr[indexRow, .], ("Time", "Treatment Effect", "Two-sided ", "Right-sided", "Left-sided"), "p-value of Treatment Effect", (tr_eff, pval), ., 0, (16, 11, 11, 11), 0, 0)
		st_matrix("pval", (tr_eff, pval))
		st_matrixcolstripe("pval", (("", "p-value", "p-value", "p-value")',("Tr.Eff.", "two-sided", "right-sided", "left-sided")'))
		st_matrixrowstripe("pval",(J(rows(timeVarStr[indexRow, .]), 1, ""), timeVarStr[indexRow, .]))
		temp = _st_addvar("float", "pvalTwo")
		temp = _st_addvar("float", "pvalRight")
		temp = _st_addvar("float", "pvalLeft")
		st_view(pvalM, ., ("pvalTwo", "pvalRight", "pvalLeft"))
		pvalM[indexRow, .] = pval
	}
end

* 0.0.1 Fix the issue of parameter transfer in the placebo test
* 0.0.0 Submit the initial version of synth2