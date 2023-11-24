*! qcm 1.0.0 Guanpeng Yan and Qiang Chen 2023.11.19

* cap prog drop qcm
* cap prog drop qcm_placebo
* cap prog drop qcm_savegraph
program qcm,  eclass sortpreserve
	version 16
	preserve
	qui xtset
	if "`r(panelvar)'" == "" | "`r(timevar)'" == "" {
		di as err "panel variable or time variable missing, please use -{bf:xtset} {it:panelvar} {it:timevar}"
		exit 198
	}
	else if "`r(balanced)'" != "strongly balanced" {
		di as err "strongly balanced panel data is required"
		exit 198
	}
	syntax varlist(min = 1) [if], TRUnit(integer) TRPeriod(integer) ///
		[COUnit(numlist min=1 integer sort) ///
		PREPeriod(numlist min=1 integer sort) ///
		POSTPeriod(numlist min=1 integer sort) ///
		NTree(integer 500) ///
		MTry(numlist > 0 min=1 max=1 integer) ///
		MAXDepth(numlist > 0 min=1 max=1 integer) ///
		MINSsize(integer 10) ///
		MINLsize(integer 5) ///
		CILevel(numlist >0 <100 min=1 max=1) ///
		CIStyle(integer 1) ///
		QType(numlist >=0 <=11 min=1 max=1 integer) ///
		seed(integer 1) ///
		placebo(string) ///
		fill(string) ///
		frame(string) ///
		noIMPortance ///
		noFIGure ///
		show(numlist min = 1 max = 1 >=1) ///
		SAVEGraph(string) ///
		]
	qui cap mata mata which mm_quantile()
    if _rc == 111 {
		di as err `"{bf:moremata} must be installed (use Stata command "{bf:ssc install moremata, replace}")."'
		exit 198
    }
	if "`cilevel'" == "" loc cilevel = 0.95
	else loc cilevel = `cilevel'/100
	if "`qtype'" == "" local qtype = 10
 	loc cilevelp = `cilevel' * 100
 	if "`frame'" == "" tempname frame
	else {
		capture frame drop `frame'
		local framename "`frame'"
	}
    if "`r(panelvar)'" == "" | "`r(timevar)'" == "" {
		di as err "panel variable or time variable missing, please use -{bf:xtset} {it:panelvar} {it:timevar}"
		exit 198
    }
	local panelVar "`r(panelvar)'"
	local timeVar "`r(timevar)'"
	qui levelsof `panelVar', local(unit_n)
	loc check: list trunit in unit_n
	if `check' == 0 {
		di as err "treated unit not found in panelvar - check {bf:trunit()}"
		exit 198
	}
	if "`counit'" != "" {
		loc check: list counit in unit_n
		if `check' == 0 {
			di as err "at least one control unit not found in panelvar - check {bf:counit()}"
			exit 198
		}
		loc check: list trunit in counit
		if `check' == 1 {
			di as err "treated unit appears among control units  - check {bf:trunit()} and {bf:counit()}"
			exit 198
		}
		foreach i in `unit_n'{
			loc check: list i in counit
			if `check' == 0 & `i' != `trunit' qui drop if `panelVar' == `i'
		}
	}
	qui mata: qcm_levelsof("`timeVar'", "time_n")
	loc check: list trperiod in time_n
	if `check' == 0 {
		di as err "treatment period not found in timelvar - check {bf:trperiod()}"
		exit 198
	}
	if "`preperiod'" != "" {
		qui mata: qcm_levelsofsel("`timeVar'", "time_pre", st_data(., "`timeVar'"):<`trperiod')
		loc check: list preperiod in time_pre
		if `check' == 0 {
			di as err "at least one pretreatment period not found in timevar or not ahead of treatment period - check {bf:postperiod()}"
			exit 198
		}
		foreach i in `time_pre'{
			loc check: list i in preperiod
			if `check' == 0 qui drop if `timeVar' == `i'
		}
	}
	if "`postperiod'" != "" {
		qui mata: qcm_levelsofsel("`timeVar'", "time_post", st_data(., "`timeVar'") :>= `trperiod')
		loc check: list posof "`trperiod'" in postperiod
		if `check' != 1 {
			di as err "treatment period not be the first of posttreatment periods - check {bf:trperiod()} and {bf:postperiod()}"
			exit 198
		}
		loc check: list postperiod in time_post
		if `check' == 0 {
			di as err "at least one period in posttreatment periods not found in timevar - check {bf:postperiod()}"
			exit 198
		}
		foreach i in `time_post'{
			loc check: list i in postperiod
			if `check' == 0 qui drop if `timeVar' == `i'
		}
	}
	mata: mata set matafavor speed
	/* Check fill() */
	if("`fill'" != "mean" & "`fill'" != "linear" & "`fill'" != ""){
		di as err "invaild fill() -- fil_method must be one of {bf:mean linear}"
		exit 198
	}
	/* Generate panelVarStr*/
	tempvar panelVarStr 
	{
		capture decode `panelVar', gen(`panelVarStr')
		if _rc  qui tostring `panelVar', gen(`panelVarStr') usedisplayformat force
		else qui replace `panelVarStr' = subinstr(`panelVarStr', " ", "", .)
		qui replace `panelVarStr' = strtoname(`panelVarStr', 0) 
	}
	/* Obtain all units, the treated unit and the control units*/
	qui levelsof `panelVarStr', local(unit_all) clean
	qui levelsof `panelVarStr' if `panelVar' != `trunit', local(unit_ctrl) clean
	qui levelsof `panelVarStr' if `panelVar' == `trunit', local(unit_tr) clean
	/* Obtain dependent variable and indepent variables */
	gettoken depvar indepvars : varlist
	local graphlist ""
	
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
			mata: qcm_print(tokens("`varlist'")', ("Variable", "pretreatment", " posttreatment"), ///
					st_matrix("fillmissing"), "", 0, (13, 13), 0, 1, 0)
	}
	foreach i in `varlist'{
		qui count if `i' == .
		if `r(N)' != 0 {
			di as err "There are {bf:`r(N)'} missing values in variable {bf:`i'}, which is not allowed by {bf:qcm}"
			exit 198
		}
	}
	
	/* Define Temporary frame: `frame' for regress */
	frame put `panelVarStr' `timeVar' `varlist', into(`frame')
	/* Implement quantile random forest (QRF) for program evaluation */
	frame `frame' {
		tempvar timeVarStr
		qui reshape wide `varlist', i(`timeVar') j(`panelVarStr') string
		cap label variable `timeVar' "time"
		foreach var of local varlist{
			foreach unit of local unit_all {
				rename `var'`unit' `var'·`unit'
				cap lab variable `var'·`unit' "`var' in `unit' "
			}
		}
		qui tsset `timeVar'
		qui tostring `timeVar', gen(`timeVarStr') usedisplayformat force
        mata: qcm_slevelsof("`timeVarStr'", "time_all")
        mata: qcm_slevelsofsel("`timeVarStr'", "time_pre", st_data(., "`timeVar'") :< `trperiod')
        mata: qcm_slevelsofsel("`timeVarStr'", "time_post", st_data(., "`timeVar'") :>= `trperiod')
        mata: qcm_slevelsofsel("`timeVarStr'", "time_tr", st_data(., "`timeVar'") :== `trperiod')
		
		cap mata: qcm("`varlist'", "`unit_all'", "`unit_tr'", "`time_all'", "`time_tr'", 0, `ntree', "`mtry'", "`maxdepth'" ///
			, `minlsize', `seed', `minssize', `cilevel', `qtype', "`importance'" == "" ? 1 : 0)
		if _rc {
			exit
		}
		
		di _newline "{txt}Parameters of random forest:"
		mata: qcm_train_summary(`ntree', `mtry', "`maxdepth'", `minlsize', `seed', `minssize')
		
		di _newline as txt "Fitting results in the pretreatment periods:"
		mata: qcm_summary(st_sdata(., "`timeVarStr'"), st_data(., "`depvar'·`unit_tr' pred_e·`depvar'·`unit_tr'") ///
			, "`unit_tr'", "`time_tr'", "`predvar'", "`outvar'", "", 0, .)

		/* Importance */
		if("`importance'" == ""){
			mata: st_local("varsNum", strofreal(cols(tokens("`varlist'"))))
			di _newline as txt "Variable Importance:"
			if `varsNum' == 1 {
				matrix define imp = imp_U
				mata: qcm_print_imp("imp", "Unit")
				cap matrix drop imp_U
			}
			else{
				mata: qcm_print_imp_preds("imp")
			}
			if "`figure'" == "" {
				tempname impFrame
				cap frame create `impFrame'
				frame `impFrame'{
					qui svmat imp, name(col)
					mata: st_sstore(., st_addvar("strL", "preds"), st_matrixrowstripe("imp")[., 2])
					qui sum Importance
					qui local ymax= r(max)*1.1
					if ("`show'" != "") {
						qui gsort -Importance
						qui drop if _n >`show'
					}
					graph hbar (asis) Importance, over(preds, sort(Importance) descending) ytitle(importance) ///
						name(imp, replace) title(Variable Importance) blabel(total, format(%9.4f)) ysc(r(0 `ymax')) nodraw 
					local graphlist = "`graphlist' imp"
				}
			}
			if `varsNum' > 1 {
				di _newline as txt "Variable Importance by Units:"
				mata: qcm_print_imp("imp_U", "Unit")
				mata: printf("{p 0 6 2}{txt}Note: The above table lists variable importance aggregated by units.{p_end}")
				if "`figure'" == "" {
					tempname impUnitFrame
					cap frame create `impUnitFrame'
					frame `impUnitFrame'{
						qui svmat imp_U, name(col)
						mata: st_sstore(., st_addvar("strL", "unit"), st_matrixrowstripe("imp_U")[., 2])
						qui sum Importance
						qui local ymax= r(max)*1.1
						if ("`show'" != "") {
							qui gsort -Importance
							qui drop if _n >`show'
						}
						graph hbar (asis) Importance, over(unit, sort(Importance) descending) ytitle(importance) ///
							name(imp_units, replace) title(Variable Importance by Units) blabel(total, format(%9.4f)) ysc(r(0 `ymax')) nodraw 
						local graphlist = "`graphlist' imp_units"
					}
				}
				di _newline as txt "Variable Importance by Variables:"
				mata: qcm_print_imp("imp_V", "Variable")
				mata: printf("{p 0 6 2}{txt}Note: The above table lists variable importance aggregated by variables.{p_end}")
				if "`figure'" == ""  {
					tempname impVarsFrame
					cap frame create `impVarsFrame'
					frame `impVarsFrame'{
						qui svmat imp_V, name(col)
						mata: st_sstore(., st_addvar("strL", "variable"), st_matrixrowstripe("imp_V")[., 2])
						qui sum Importance
						qui local ymax= r(max)*1.1
						if ("`show'" != "") {
							qui gsort -Importance
							qui drop if _n >`show'
						}
						graph hbar (asis) Importance, over(variable, sort(Importance) descending) ytitle(importance) ///
							name(imp_vars, replace) blabel(total, format(%9.4f)) ysc(r(0 `ymax')) title(Variable Importance by Variables) nodraw
						local graphlist = "`graphlist' imp_vars"
					}
				}
			}
		}
			
		di _newline "{txt}Prediction results in the posttreatment periods:"
        mata: qcm_print(st_sdata(., "`timeVarStr'"), ("Time", " Actual Outcome ", "  Predicted Outcome" ///
			, sprintf("   [%2.0f%% Confidence", `cilevel'*100), "Interval]      ") ///
			, st_data(., "`depvar'·`unit_tr' pred_e·`depvar'·`unit_tr' " ///
			+ " pred_l·`depvar'·`unit_tr'  pred_u·`depvar'·`unit_tr'") ///
			, "`time_tr'", 0, (11, 15, 15, 15), 0, 0, 1)
		mkmat `depvar'·`unit_tr' pred_e·`depvar'·`unit_tr' ///
			pred_l·`depvar'·`unit_tr' pred_u·`depvar'·`unit_tr' if `timeVar' >= `trperiod', rownames(`timeVar') matrix(pred)
		mat colnames pred = Treated Pred LowerPred UpperPred
		
		/* Treatment Effect */
		qui gen tr_e·`depvar'·`unit_tr' = `depvar'·`unit_tr' - pred_e·`depvar'·`unit_tr'
		label variable tr_e·`depvar'·`unit_tr' "mean treatment effects on `depvar' in `unit_tr'"
		qui gen tr_m·`depvar'·`unit_tr' = `depvar'·`unit_tr' - pred_m·`depvar'·`unit_tr'
		label variable tr_m·`depvar'·`unit_tr' "median treatment effects on `depvar' in `unit_tr'"
		qui gen tr_l·`depvar'·`unit_tr' = `depvar'·`unit_tr' - pred_u·`depvar'·`unit_tr'
		label variable tr_l·`depvar'·`unit_tr' "lower treatment effects on `depvar' in `unit_tr'"
		qui gen tr_u·`depvar'·`unit_tr' = `depvar'·`unit_tr' - pred_l·`depvar'·`unit_tr'
		label variable tr_u·`depvar'·`unit_tr' "upper treatment effects on `depvar' in `unit_tr'"
		di _newline "{txt}Estimation results in the posttreatment periods:"
        mata: qcm_print(st_sdata(., "`timeVarStr'"), ("Time", " Treatment Effect" ///
					, sprintf("     [%2.0f%% Confidence", `cilevel'*100), "Interval]       ") ///
			, st_data(., "tr_e·`depvar'·`unit_tr' " ///
			+ "tr_l·`depvar'·`unit_tr' tr_u·`depvar'·`unit_tr'"), "`time_tr'", 1, (11, 15, 15), 0, 0, 1)
		mkmat tr_e·`depvar'·`unit_tr' tr_l·`depvar'·`unit_tr' tr_u·`depvar'·`unit_tr' ///
			if `timeVar' >= `trperiod', rownames(`timeVar') matrix(eff)
		mat colnames eff = TrEff LowerTrEff UpperTrEff

	}
	
	capture graph drop pred
	capture graph drop eff
	if "`figure'" == "" {
		frame `frame' {
			tempvar timeVarL
			mata: qcm_levelsof("`timeVar'", "temp")
			loc pos: list posof "`trperiod'" in temp
			loc pos = `pos' - 1
			loc xline: word `pos' of `temp'
			twoway (tsline `depvar'·`unit_tr') (tsline pred_e·`depvar'·`unit_tr', lpattern(dash)), ///
				title("Actual and Predicted Outcomes") xline(`xline', lp(dash) lc(cranberry%40)) name(pred, replace) ///
				ytitle(`depvar')  legend(order(1 "Actual" 2 "Predicted") ///
				rows(1) cols(2) position(6)) nodraw
			if `cistyle' == 1 {
				twoway (rcap tr_l·`depvar'·`unit_tr' tr_u·`depvar'·`unit_tr' `timeVar' if `timeVar' >= `trperiod', ///
					color(navy) lpattern(dash)) ///
					(connected tr_e·`depvar'·`unit_tr' `timeVar', lcolor(forest_green) msymbol(smcircle_hollow) mcolor(navy)), ///
					xline(`xline', lp(dash) lc(cranberry%40)) yline(0, lp(dash) lc(cranberry%40)) ///
					title("Treatment Effects") name(eff, replace) ///
					legend(order(2 "Treatment Effect" 1 "`cilevelp'% Confidence Interval") ///
					rows(1) position(6)) ytitle("treatment effects on `depvar'") nodraw
			}
			else if `cistyle' == 2 {
				twoway (rarea tr_l·`depvar'·`unit_tr' tr_u·`depvar'·`unit_tr' `timeVar' if `timeVar' >= `trperiod', ///
					fcolor(gs8%30) lwidth(none)) ///
					(connected tr_e·`depvar'·`unit_tr' `timeVar', lcolor(forest_green) msymbol(smcircle_hollow) mcolor(navy)), ///
					xline(`xline', lp(dash) lc(cranberry%40)) yline(0, lp(dash) ///
					lc(cranberry%40)) title("Treatment Effects") name(eff, replace) ///
					legend(order(2 "Treatment Effect" 1 "`cilevelp'% Confidence Interval") ///
					rows(1) position(6)) ytitle("treatment effects on `depvar'") nodraw
			}
			else if `cistyle' == 3 {
				twoway (line tr_u·`depvar'·`unit_tr' `timeVar' if `timeVar' >= `trperiod', fcolor(none) lcolor(gs8%50)) ///
					(line tr_l·`depvar'·`unit_tr' `timeVar' if `timeVar' >= `trperiod', fcolor(none) lcolor(gs8%50)) ///
					(connected tr_e·`depvar'·`unit_tr' `timeVar', lcolor(forest_green) msymbol(smcircle_hollow) mcolor(navy)), ///
					xline(`xline', lp(dash) lc(cranberry%40)) ///
					yline(0, lp(dash) lc(cranberry%40)) title("Treatment Effects") name(eff, replace) ///
					legend(order(3 "Treatment Effect" 1 "`cilevelp'% Confidence Interval") ///
					rows(1) position(6)) ytitle("treatment effects on `depvar'") nodraw
			}
			local graphlist = "`graphlist' pred eff"
		}
	}
	
	/* Implement placebo tests using fake units and/or times */
	if "`placebo'" != "" {
		ereturn loc trperiod "`trperiod'"
		if(strpos("`placebo'", "unit") != 0 & strpos("`placebo'", "unit(") == 0) loc placebo = ///
			subinstr("`placebo'", "unit", "unit(.)", .)
		qcm_placebo `varlist', trunit(`trunit') trperiod(`trperiod') panelVar(`panelVar') timeVar(`timeVar') ///
			panelVarStr(`panelVarStr') unit_all(`unit_all') unit_tr(`unit_tr') unit_ctrl(`unit_ctrl') ///
			time_tr(`time_tr') time_all(`time_all') cilevelp(`cilevelp') ///
			ntree(`ntree') mtry("`mtry'") maxdepth("`maxdepth'") minlsize(`minlsize') minssize(`minssize') cilevel(`cilevel') ///
			qtype(`qtype') cistyle(`cistyle') seed(`seed') frame(`frame') show(`show') ///
			`placebo' `figure'
		loc graphlist = "`graphlist' `e(graphlist)'"
		cap mat pval = e(pval)
	}

	/* Display graphs */
	if "`figure'" == "" {
		if "`savegraph'" == "" foreach graph in `graphlist'{
			capture graph display `graph'
		}
		else{
			di
			ereturn local graphlist "`graphlist'"
			qcm_savegraph `savegraph'
		}
	}
	ereturn clear
	loc G: word count `unit_all'
	ereturn scalar G = `G'
	ereturn scalar T = T
	ereturn scalar T0 = T0
 	ereturn scalar T1 = T - T0
	ereturn scalar K = K
	ereturn scalar mae = mae
	ereturn scalar mse = mse
	ereturn scalar rmse = rmse
	ereturn scalar r2 = r2
	ereturn scalar att = att
	ereturn local frame "`framename'"
	ereturn local seed = `seed'
	mata: st_local("maxdepth", "`maxDepth'" == ""? ".":"`maxdepth'")
	ereturn local maxdepth "`maxdepth'"
	ereturn local minlsize = `minlsize'
	ereturn local minssize = `minssize'
	ereturn local mtry "`mtry'"
	ereturn local ntree = `ntree'
	ereturn local time_post "`time_post'"
	ereturn local time_pre "`time_pre'"
	ereturn local time_tr "`time_tr'"
	ereturn local time_all "`time_all'"
	ereturn local unit_ctrl "`unit_ctrl'"
	ereturn local unit_tr "`unit_tr'"
	ereturn local unit_all "`unit_all'"
	ereturn local predictor "`predvar'"
	ereturn local response "`outvar'"
	ereturn local varlist "`varlist'"
	ereturn local timevar "`timeVar'"
	ereturn local panelvar "`panelVar'"
	capture ereturn matrix pval = pval	
	cap ereturn matrix imp_V = imp_V
	cap ereturn matrix imp_U = imp_U
	cap ereturn matrix imp = imp
	ereturn matrix eff = eff
	ereturn matrix pred = pred
	
	di _newline as txt "Finished."
end

capture program drop qcm_placebo
program qcm_placebo, eclass sortpreserve
	version 16
	loc trperiod = `e(trperiod)'
	syntax varlist, trunit(numlist) trperiod(numlist) [panelVar(string) timeVar(string) panelVarStr(string) ///
		unit_all(string) unit_tr(string) unit_ctrl(string) ///
		time_all(string) time_tr(string) ///
		ntree(integer 500) ///
		mtry(numlist > 0 min = 1 max = 1 integer) ///
		maxdepth(numlist > 0 min = 1 max = 1 integer) ///
		minssize(integer 10) ///
		minlsize(integer 5) ///
		cilevel(numlist) ///
		cilevelp(numlist) ///
		cistyle(integer 1) ///
		qtype(integer 1) ///
		seed(integer 1) ///
		frame(string) ///
		show(numlist) ///
		unit(numlist missingokay) ///
		period(numlist min = 1 int sort <`trperiod') ///
		Cutoff(numlist min = 1 max = 1 >=1) noFIGure]
	
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
		mata: qcm_levelsof("`timeVar'", "temp")
		loc pos: list posof "`trperiod'" in temp
		loc pos = `pos' - 1
		loc xline_tr: word `pos' of `temp'
		if("`unit'" != ""){
			di _newline as txt "Implementing in-space placebo test using fake treatment unit " _continue
			loc tsline ""
			loc unit_ctrl_sel ""
			loc unit_ctrl_dis ""
			foreach unit_placebo in `unit_ctrl'{
				loc unit_tmp "`unit_placebo'"
				di as res "`unit_placebo'"  as txt "..." _continue
				cap mata: qcm("`varlist'", "`unit_all'", "`unit_placebo'", "`time_all'", "`time_tr'", 1, ///
					`ntree', "`mtry'", "`maxdepth'", `minlsize', `seed', `minssize', `cilevel', `qtype', 0)
				if _rc {
						exit
				}
				qui capture gen tr_e·`depvar'·`unit_placebo' = `depvar'·`unit_placebo'- pred_e·`depvar'·`unit_placebo'
				label variable tr_e·`depvar'·`unit_placebo' ///
					"mean treatment effects on `depvar' in `unit_placebo' generated by 'placebo unit'"
				qui capture gen tr_m·`depvar'·`unit_placebo' = `depvar'·`unit_placebo'- pred_m·`depvar'·`unit_placebo'
				label variable tr_m·`depvar'·`unit_placebo' ///
					"median treatment effects on `depvar' in `unit_placebo' generated by 'placebo unit'"
				mata: qcm_summary(st_sdata(., "`timeVarStr'"), st_data(., "`depvar'·`unit_placebo' pred_e·`depvar'·`unit_placebo'") ///
					, "`unit_tr'", "`time_tr'", "`predvar_sel'", "", "", 1, ("`cutoff'" == "" ? . : strtoreal("`cutoff'")))
				if "`unit_placebo'" != "" {
					loc tsline "`tsline' (tsline tr_e·`depvar'·`unit_placebo', lp(solid) lc(gs10%40))"
					loc unit_ctrl_sel "`unit_ctrl_sel' `unit_placebo'"
				}
				else loc unit_ctrl_dis "`unit_ctrl_dis' `unit_tmp'"
			}
			di _newline _newline as txt "In-space placebo test results using fake treatment units:"
			mata: qcm_print(tokens("`unit_tr' `unit_ctrl'")', ("Unit", "Pre MSPE ", " Post MSPE ", "Post/Pre MSPE", ///
				"  Pre MSPE of Fake Unit/Pre MSPE of Treated Unit"), st_matrix("mspe"), "", 0, (9, 9, 13, 24), 0, 0, 0)
			mata: st_numscalar("pval", mean((st_matrix("mspe")[1, 3] :< st_matrix("mspe")[2..rows(st_matrix("mspe")), 3])))
			if "`unit_ctrl_dis'" != "" {
				mata: printf(stritrim(sprintf( ///
					"{p 0 6 2}{txt}Note: (1) Using all control units, the probability of obtaining a post/pretreatment MSPE " ///
					+ "ratio as large as {res}`unit_tr'{txt}'s is{res}%10.4f{txt}.{p_end}\n", ///
					mean((st_matrix("mspe")[1, 3] :<= st_matrix("mspe")[. , 3])))))
				mata: printf(stritrim(sprintf( ///
					"{p 6 6 2}{txt}(2) Excluding control units with pretreatment MSPE {res}`cutoff'{txt} times larger " ///
					+ "than the treated unit, the probability of obtaining a post/pretreatment MSPE ratio " ///
					+ "as large as {res}`unit_tr'{txt}'s is {res}%10.4f{txt}.{p_end}\n", ///
					mean((st_matrix("mspe_cut")[1, 3] :<= st_matrix("mspe_cut")[. , 3])))))
				mata: printf(stritrim(sprintf( "{p 6 6 2}{txt}(3) The pointwise p-values below are computed by excluding control" + ///
					" units with pretreatment MSPE {res}`cutoff'{txt} times larger than the treated unit.{p_end}")))
				mata: printf("{p 6 6 2}{txt}(4) There " ///
					+ (cols(tokens("`unit_ctrl_dis'")) > 1 ? "are" : "is") + "{res} " + strofreal(cols(tokens("`unit_ctrl_dis'"))) ///
					+ " {txt}"+ (cols(tokens("`unit_ctrl_dis'")) > 1 ? "units" : "unit") ///
					+ " with pretreatment MSPE {res}`cutoff' {txt}times larger than the treated " ///
					+ "unit, including {res}`unit_ctrl_dis'{txt}.{p_end}")
			}
			else mata: printf(stritrim(sprintf( ///
				"{p 0 6 2}{txt}Note: The probability of obtaining a post/pretreatment " ///
				+ "MSPE ratio as large as {res}`unit_tr'{txt}'s is{res}%10.4f{txt}.{p_end}\n", ///
				mean((st_matrix("mspe")[1, 3]:<= st_matrix("mspe")[., 3])))))
			mata: printf("\n{txt}In-space placebo test results using fake treatment units (continued" ///
				+ ("`cutoff'" == "" ? "" : (", cutoff = {res}`cutoff'")) + "{txt}):\n")
			mata: qcm_placebo("`depvar'", "`unit_tr'", "`unit_ctrl_sel'", "`time_all'", "`time_tr'")
			cap lab variable pvalTwo "two-sided p-value of treatment effect generated by 'placebo unit'"
			cap lab variable pvalRight "right-sided p-value of treatment effect generated by 'placebo unit'"
			cap lab variable pvalLeft "left-sided p-value of treatment effect generated by 'placebo unit'"
			mkmat tr_e·`depvar'·`unit_tr' pvalTwo pvalRight pvalLeft if `timeVar' >= `trperiod', rownames(`timeVar') matrix(pval)
			mat colnames pval = TrEff twoSidePval RightSidePval leftSidePval
			if "`figure'" == "" {
				loc order_tr = wordcount("`unit_ctrl_sel'") + 1
	
				twoway `tsline' (tsline tr_e·`depvar'·`unit_tr', lw(0.4) lc(gs3%80) lp(solid)), ///
					xline(`xline_tr', lp(dot) lc(black)) yline(0, lp(dot) lc(black)) ///
					title("In-space Placebo Test") name(eff_pboUnit, replace) ///
					ytitle("treatment/placebo effects on `depvar'") ///
					legend(order(`order_tr' "Treatment Effect" 2 "Placebo Effect")) nodraw
					loc graphlist = "`graphlist' eff_pboUnit"
				tempname placeboUnitframe
				matrix colnames mspe = PreMSPE PostMSPE RatioPostPre RatioTrCtrl
				frame create `placeboUnitframe'
				frame `placeboUnitframe'{
					qui svmat mspe, name(col)
					mata: st_sstore(., st_addvar("strL", "unit"), tokens("`unit_tr' `unit_ctrl'")')
					if ("`show'" != "") {
							qui gsort -RatioPostPre
							qui drop if _n >`show'
					}
					graph hbar (asis) RatioPostPre, over(unit, sort(RatioPostPre) descending label(labsize(vsmall))) ///
					ytitle("Ratios of posttreatment MSPE to pretreatment MSPE") ///
					title("In-space Placebo Test") name("ratio_pboUnit", replace) nodraw
				}
				loc graphlist = "`graphlist' ratio_pboUnit"
				twoway connected pvalTwo `timeVar' if  `timeVar' >= `trperiod', ///
					ytitle("two-sided p-values of treatment effects on `depvar'") ///
					yline(0.05 0.1, lp(dot) lc(black)) ylabel(0(0.1)1) ///
					title("In-space Placebo Test") name(pvalTwo_pboUnit, replace) nodraw
				twoway connected pvalRight `timeVar' if  `timeVar' >= `trperiod', ///
					ytitle("right-sided p-values of treatment effects on `depvar'") ///
					yline(0.05 0.1, lp(dot) lc(black)) ylabel(0(0.1)1) ///
					title("In-space Placebo Test") name(pvalRight_pboUnit, replace) nodraw
				twoway connected pvalLeft `timeVar' if  `timeVar' >= `trperiod', ///
					ytitle("left-sided p-values of treatment effects on `depvar'") ///
					yline(0.05 0.1, lp(dot) lc(black)) ylabel(0(0.1)1) ///
					title("In-space Placebo Test") name(pvalLeft_pboUnit, replace) nodraw
				loc graphlist = "`graphlist' pvalTwo_pboUnit pvalRight_pboUnit pvalLeft_pboUnit"
			}
		}
		if("`period'" != ""){
			di _newline as txt "Implementing in-time placebo test using fake treatment time " _continue
			foreach pboperiod in `period'{
				mata: qcm_levelsof("`timeVar'", "time_n")
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
				
				cap mata: qcm("`varlist'", "`unit_all'", "`unit_tr'", "`time_all'", "`time_pbo'", 2, `ntree', "`mtry'" ///
					, "`maxdepth'", `minlsize', `seed', `minssize', `cilevel', `qtype', 0)
				if _rc {
					exit
				}
				
				qui capture gen tr_e·`depvar'·`unit_tr'·`time_pbo' = `depvar'·`unit_tr' ///
					- pred_e·`depvar'·`unit_tr'·`time_pbo'
				label variable tr_e·`depvar'·`unit_tr'·`time_pbo' "mean treatment effects on `depvar' in `unit_tr' generated by 'placebo period `pboperiod''"
				qui capture gen tr_m·`depvar'·`unit_tr'·`time_pbo' = `depvar'·`unit_tr' ///
					- pred_m·`depvar'·`unit_tr'·`time_pbo'
				label variable tr_m·`depvar'·`unit_tr'·`time_pbo' "median treatment effects on `depvar' in `unit_tr' generated by 'placebo period `pboperiod''"
				qui capture gen tr_l·`depvar'·`unit_tr'·`time_pbo' = `depvar'·`unit_tr' ///
					- pred_u·`depvar'·`unit_tr'·`time_pbo'
				label variable tr_l·`depvar'·`unit_tr'·`time_pbo' "lower treatment effects on `depvar' in `unit_tr' generated by 'placebo period `pboperiod''"
				qui capture gen tr_u·`depvar'·`unit_tr'·`time_pbo' = `depvar'·`unit_tr' ///
					- pred_l·`depvar'·`unit_tr'·`time_pbo'
				label variable tr_u·`depvar'·`unit_tr'·`time_pbo' "upper treatment effects on `depvar' in `unit_tr' generated by 'placebo period `pboperiod''"
				
				if "`figure'" == "" {
					twoway (tsline `depvar'·`unit_tr') (tsline pred_e·`depvar'·`unit_tr'·`time_pbo', lpattern(dash)), ///
						title("In-time Placebo Test (fake treatment time = `time_pbo')") ///
						xline(`xline_pbo' `xline_tr', lp(dash) lc(cranberry%40)) name(pred_pboTime`pboperiod', replace) ///
						ytitle(`depvar')  ///
						legend(order(1 "Actual" 2 "Predicted") ///
						rows(1) cols(2) position(6)) nodraw
					if `cistyle' == 1 {
						twoway (rcap tr_l·`depvar'·`unit_tr'·`time_pbo' tr_u·`depvar'·`unit_tr'·`time_pbo' `timeVar' ///
							if `timeVar' >= `pboperiod', color(navy) lpattern(dash)) ///
							(connected tr_e·`depvar'·`unit_tr'·`time_pbo' `timeVar', ///
							lcolor(forest_green) msymbol(smcircle_hollow) mcolor(navy)), ///
							xline(`xline_pbo' `xline_tr', lp(dash) lc(cranberry%40)) yline(0, lp(dash) lc(cranberry%40)) ///
							title("In-time Placebo Test (fake treatment time = `time_pbo')") ///
							name(eff_pboTime`pboperiod', replace) ///
							legend(order(2 "Treatment Effect" 1 "`cilevelp'% Confidence Interval") ///
							rows(1) position(6)) ytitle("treatment effects on `depvar'") nodraw
					}
					else if `cistyle' == 2 {
						twoway (rarea tr_l·`depvar'·`unit_tr'·`time_pbo' tr_u·`depvar'·`unit_tr'·`time_pbo' `timeVar' ///
							if `timeVar' >= `pboperiod', fcolor(gs8%30) lwidth(none)) ///
							(connected tr_e·`depvar'·`unit_tr'·`time_pbo' `timeVar', ///
							lcolor(forest_green) msymbol(smcircle_hollow) mcolor(navy)), ///
							xline(`xline_pbo' `xline_tr', lp(dash) lc(cranberry%40)) ///
							yline(0, lp(dash) ///
							lc(cranberry%40)) title("In-time Placebo Test (fake treatment time = `time_pbo')") ///
							name(eff_pboTime`pboperiod', replace) ///
							legend(order(2 "Treatment Effect" 1 "`cilevelp'% Confidence Interval") ///
							rows(1) position(6)) ytitle("treatment effects on `depvar'") nodraw
					}
					else if `cistyle' == 3 {
						twoway (line tr_u·`depvar'·`unit_tr'·`time_pbo' `timeVar' if `timeVar' >= `pboperiod', ///
							fcolor(none) lcolor(gs8%50)) ///
							(line tr_l·`depvar'·`unit_tr'·`time_pbo' `timeVar' if `timeVar' >= `pboperiod', ///
							fcolor(none) lcolor(gs8%50)) ///
							(connected tr_e·`depvar'·`unit_tr'·`time_pbo' `timeVar', ///
							lcolor(forest_green) msymbol(smcircle_hollow) mcolor(navy)), ///
							xline(`xline_pbo' `xline_tr', lp(dash) lc(cranberry%40)) ///
							yline(0, lp(dash) lc(cranberry%40)) ///
							title("In-time Placebo Test (fake treatment time = `time_pbo')") ///
							name(eff_pboTime`pboperiod', replace) ///
							legend(order(2 "Treatment Effect" 1 "`cilevelp'% Confidence Interval") ///
							rows(1) position(6)) ytitle("treatment effects on `depvar'") nodraw
					}
					loc graphlist = "`graphlist' pred_pboTime`pboperiod' eff_pboTime`pboperiod'"
				}
			}
			di
			foreach pboperiod in `period'{
				qui levelsof `timeVarStr' if `timeVar' == `pboperiod', local(time_pbo) clean
				di _newline as txt "In-time placebo test results using fake treatment time " as res "`time_pbo'" as txt":"
				mata: qcm_print(st_sdata(., "`timeVarStr'"), ("Time", " Actual Outcome ", "  Predicted Outcome" ///
					, sprintf("   [%2.0f%% Confidence", `cilevel'*100), "Interval]      ") ///
					, st_data(., "`depvar'·`unit_tr' pred_e·`depvar'·`unit_tr'·`time_pbo' " ///
					+ "pred_l·`depvar'·`unit_tr'·`time_pbo'  pred_u·`depvar'·`unit_tr'·`time_pbo'"), "`time_pbo'", 0 ///
					, (11, 15, 15, 15), 0, 0, 1)
				mkmat `depvar'·`unit_tr' pred_e·`depvar'·`unit_tr' pred_m·`depvar'·`unit_tr' pred_l·`depvar'·`unit_tr' ///
					pred_u·`depvar'·`unit_tr' if `timeVar' >= `trperiod', rownames(`timeVar') matrix(pred)
				mat colnames pred = Treated MeanPred MedianPred LowerPred UpperPredestimate
				di _newline as txt "In-time placebo test results using fake treatment time " as res "`time_pbo'" as txt " (continued):" 
				mata: qcm_print(st_sdata(., "`timeVarStr'"), ("Time", "  Treatment Effect" ///
					, sprintf("     [%2.0f%% Confidence", `cilevel'*100), "Interval]       ") ///
					, st_data(., "tr_e·`depvar'·`unit_tr'·`time_pbo' " ///
					+ "tr_l·`depvar'·`unit_tr'·`time_pbo' " ///
					+ "tr_u·`depvar'·`unit_tr'·`time_pbo'"), "`time_tr'", 1, (12, 15, 15), 0, 0, 1)
			}
		}
	}
	ereturn loc graphlist "`graphlist'"
	cap ereturn matrix pval = pval
end

program qcm_savegraph
	version 16
	preserve
	syntax [anything], [asis replace]
	foreach graph in `e(graphlist)'{
		capture graph display `graph'
		graph save `anything'_`graph', `asis' `replace' 
	}
end

version 16.0
mata:
	real matrix qcm_uniqrows(real matrix m){
		tmp = J(0, 1, .)
		for(i = 1;i<=rows(m); i++){
			if(i == 1) tmp = tmp\m[i,.]
			else{
				if(sum(tmp:==m[i,.])==0) tmp = tmp\m[i,.]
			}
		}
		return(tmp)
	}
	string matrix qcm_suniqrows(string matrix m){
		tmp = J(0, 1, "")
		for(i = 1;i<=rows(m); i++){
			if(i == 1) tmp = tmp\m[i,.]
			else{
				if(sum(tmp:==m[i,.])==0) tmp = tmp\m[i,.]
			}
		}
		return(tmp)
	}
	void qcm_levelsof(string scalar varname, string scalar localname){
		st_local(localname, "")
		tmp = qcm_uniqrows(st_data(., varname)); 
		for(i=1; i<=rows(tmp);i++) st_local(localname, st_local(localname) + (i==1?"":" ")+ strofreal(tmp[i]))
	}
	void qcm_levelsofsel(string scalar varname, string scalar localname, real matrix selvar){
		st_local(localname, "")
		tmp = qcm_uniqrows(st_data(selectindex(selvar), varname)); 
		for(i=1; i<=rows(tmp);i++) st_local(localname, st_local(localname) + (i==1?"":" ")+ strofreal(tmp[i]))
	}
	void qcm_slevelsof(string scalar varname, string scalar localname){
		st_local(localname, "")
		tmp = qcm_suniqrows(st_sdata(., varname));
		for(i=1; i<=rows(tmp); i++) st_local(localname, st_local(localname) + (i==1?"":" ") + tmp[i])
	}
	void qcm_slevelsofsel(string scalar varname, string scalar localname, real matrix selvar){
		st_local(localname, "")
		tmp = qcm_suniqrows(st_sdata(selectindex(selvar), varname)); 
		for(i=1; i<=rows(tmp);i++) st_local(localname, st_local(localname) + (i==1?"":" ")+ tmp[i])
	}
	string matrix qcm_paste(string scalar vars, string matrix units){
		string matrix tempvar, result; real scalar i, j;
		tempvar = tokens(vars)
		result = J(rows(units)*cols(tempvar), 1, "")
		for(i = 1; i<=rows(units); i++) for(j = 1; j<=cols(tempvar); j++){
				result[(i - 1) * cols(tempvar) + j] = tempvar[j] + "·"+ units[i,1]
		}
		return(result)
	}
	void qcm_print(string matrix rownames, string matrix colnames, real matrix M, string scalar startstr, real scalar isMean, real matrix wideM, real scalar extend, real scalar isInt, real scalar saveatt){
		if(isMean == 2) wide = max(udstrlen(("Total"\rownames[1..rows(rownames),1]\colnames[1]))); else ///
			wide = max(udstrlen((rownames[1..rows(rownames),1]\colnames[1])));
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
		if(isMean == 2) printf(sprintf("{hline %g}{c +}", wide + 2)); else printf(sprintf("{hline %g}{c BT}", wide + 2));
		for(j = 1; j <= cols(colnames) - 1; j++) printf(sprintf("{hline %g}", wideM[j] + 2))
		printf(sprintf("{hline %g}\n", extend))
		if(isMean == 1){
			printf(stritrim(sprintf("{p 0 6 2}{txt}Note: The average treatment effect " ///
				+ "over the posttreatment periods is{res} %10.4f{txt}.{p_end}\n", meanM[., 1])))
			if(saveatt == 1) st_numscalar("att", meanM[., 1])
		} else if (isMean == 2){
			sumM = sum(M[1..rows(M), .])
			printf(sprintf(" {txt}%%~%guds {c |}{res}", wide), "Total")
			for(j = 1; j <= cols(M); j++){
				printf(sprintf(" %%%g.4f ", wideM[j]), sumM[., j])
			}
			printf("\n")
			printf(sprintf("{hline %g}{c BT}", wide + 2))
			for(j = 1; j <= cols(colnames) - 1; j++) printf(sprintf("{hline %g}", wideM[j] + 2))
			printf(sprintf("{hline %g}\n", extend))
		}
	}
	void qcm_summary(string matrix rownames, real matrix M, string scalar unit_tr, string scalar time_tr, string scalar predvar, string scalar respo, string scalar estimate, real matrix isPlacobo, real scalar discard){
		T0 = selectindex(rownames :== time_tr) - 1
		T1 = rows(rownames) - T0
		K = cols(tokens(predvar))
		y = M[1..T0, 1]
		pred = M[1..T0, 2]
		MSE = sum((y :- pred) :* (y :- pred))/T0
		MAE = sum(abs(y :- pred))/T0
		RMSE = sqrt(MSE)
		R2 = 1 - sum((y :- pred) :* (y :- pred))/sum((y :- mean(y)) :* (y :- mean(y)))
		if(isPlacobo == 0){
			wide = max(udstrlen((tokens(predvar[.,1]), respo)))
			wide = wide < 9 ? 9 : (wide + 67 > st_numscalar("c(linesize)") ? max((st_numscalar("c(linesize)") - 67, 9)) : wide)
			printf("{hline " + strofreal(wide + 66) + "}\n")
			printf(" {txt}%-22uds : {res}%9uds {space "+ strofreal(wide - 9) 
				+ "} {txt}%-24uds  =  {res}%9uds\n", "Treated Unit", abbrev(unit_tr, 9), "Treatment Time", abbrev(time_tr, 9))         
			printf("{hline " + strofreal(wide + 66) + "}\n")
			printf(" {txt}%-22uds =  {res}%8.0f {space "+ strofreal(wide - 9) 
				+ "} {txt}%-24uds  =   {res}%8.5f\n", "Number of Observations", T0, "Root Mean Squared Error", RMSE)
			printf(" {txt}%-22uds =  {res}%8.0f {space "+ strofreal(wide - 9) 
				+ "} {txt}%-24uds  =   {res}%8.5f\n", "Number of Predictors", K,  "R-squared", R2)
			printf("{hline " + strofreal(wide + 66) + "}\n")
			st_numscalar("T", rows(rownames))
			st_numscalar("T0", T0)
			st_numscalar("K", K)
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
			st_matrix("mspe", st_matrix("mspe")\(MSPE_in, MSPE_out, MSPE_out/MSPE_in, MSPE_in/(st_matrix("mspe")[1, 1])))
			if((discard != .) & ((MSPE_in/(st_matrix("mspe")[1, 1])) > discard)) st_local("unit_placebo", "")
			else st_matrix("mspe_cut", st_matrix("mspe_cut")\(MSPE_in, MSPE_out, MSPE_out/MSPE_in ///
				, MSPE_in/(st_matrix("mspe_cut")[1, 1])))
		}else{
			st_matrix("mspe", (MSPE_in, MSPE_out, MSPE_out/MSPE_in, 1))
			st_matrix("mspe_cut", (MSPE_in, MSPE_out, MSPE_out/MSPE_in, 1))
		}
	}
	void qcm(string scalar varlist, string scalar unit, string scalar unit_tr, string scalar time, string scalar time_tr, real scalar isplacebo, real scalar nTree, string scalar mTry, string scalar maxDepth, real scalar minLeafSize, real scalar seed, real scalar minSamplesSplit, real scalar cilevel, real scalar qtype, real matrix isimp){
		struct regTree rowvector parent; string matrix vars;
		unit = tokens(unit)'
		unit_ctrl = select(unit, unit :!= unit_tr)
		time = tokens(time)'
		vars = tokens(varlist)
		depvar = vars[1]
		T0 = selectindex(time :== time_tr) - 1
		{
			featu = qcm_paste(varlist, (unit_tr\unit_ctrl))
			respo = featu[1]
			preds = featu[2..rows(featu)]
			K = rows(preds)
		}
		data = (st_data(., respo), st_data(., invtokens(preds')))
		data_train = data[1..T0, .]
		parent = J(nTree, 1, regTree())
		mTry_real = (mTry == "" ? floor((cols(data_train) - 1) / 3) : strtoreal(mTry))
		mTry_real = min((mTry_real, cols(data_train) - 1))
		maxDepth = (maxDepth == "" ? .: strtoreal(maxDepth))
		rseed(seed)
		isSORT = J(1, cols(data_train), 0)
		dataORDER = J(rows(data_train), cols(data_train), .)
		for(i = 1; i <= nTree; i++){
			parent[i].index = 1::T0
			qcm_creatTree(&data_train, &(parent[i]), mTry_real, maxDepth, minLeafSize, minSamplesSplit, &isSORT, &dataORDER)
		}
		y_predict_mean = J(rows(data), 1,.)
		y_predict_quantile = J(rows(data), 3,.)
		for(j = 1; j<=rows(data); j++){
			W = J(rows(data_train), nTree, 0)
			for(i = 1; i <= nTree; i++){
				qcm_forcastTree(&data_train, &(parent[i]), &data[j,.], &W, i)
			}
			w = mean(W')'
			y_predict_mean[j, .] = w' * data_train[,1]
			if(qtype == 10){
				y_predict_quantile[j, .] = mm_quantile(data_train[,1], w, ((1 - cilevel)/2 \ 0.5 \ 0.5 + 0.5 * cilevel), qtype, (T0)^(-1/2))'
			} else y_predict_quantile[j, .] = mm_quantile(data_train[,1], w, ((1 - cilevel)/2 \ 0.5 \ 0.5 + 0.5 * cilevel), qtype)';
		}
		outcome = tokens(varlist)[1]
		if(isplacebo == 0){
			st_store(., st_addvar("float", "pred_e·"+ respo), y_predict_mean)
			st_varlabel("pred_e·" + respo, "mean prediction of " + outcome + " in " + unit_tr)
			st_store(., st_addvar("float", "pred_l·"+ respo), y_predict_quantile[,1])
			st_varlabel("pred_l·" + respo, "lower prediction of " + outcome + " in " + unit_tr)
			st_store(., st_addvar("float", "pred_m·"+ respo), y_predict_quantile[,2])
			st_varlabel("pred_m·" + respo, "median prediction of " + outcome + " in " + unit_tr)
			st_store(., st_addvar("float", "pred_u·"+ respo), y_predict_quantile[,3])
			st_varlabel("pred_u·" + respo, "upper prediction of " + outcome + " in " + unit_tr)
			if(isimp == 1){
				importance = J(nTree, cols(data_train), 0)
				for(i = 1; i <= nTree; i++){
					qcm_important(&data_train, &(parent[i]), &(importance), i)
					importance[i,.] = importance[i,.] :/ sum(importance[i,.])
				}
				importance = colsum(importance)[2..cols(importance)]
				importance = importance:/ sum(importance)
				st_matrix("imp", importance')
				st_matrixcolstripe("imp", ("", "Importance"))
				st_matrixrowstripe("imp", (J(rows(preds), 1, ""), preds))
				if(cols(vars) == 1){
					st_matrix("imp_U", importance')
					st_matrixrowstripe("imp_U", (J(rows(preds), 1, ""), unit_ctrl))
					st_matrixcolstripe("imp_U", ("", "Importance"))
				}else{
					num_unit = rows(unit)
					num_vars = cols(vars)
					imp_V = (0, importance[., 1..(num_vars - 1)])'
					imp_U = (sum(importance[., 1..(num_vars - 1)]) \ J(num_unit - 1, 1, 0))
					for(i = 1; i < num_unit; i++){
						imp_V = imp_V + importance[., (i*num_vars)..((i + 1) * num_vars - 1)]';
						imp_U[i + 1, .] = imp_U[i + 1, .] + sum(importance[, (i * num_vars)..((i + 1) * num_vars - 1)]);
					}
					st_matrix("imp_V", imp_V)
					st_matrixrowstripe("imp_V", (J(cols(vars), 1, ""), vars'))
					st_matrixcolstripe("imp_V", ("", "Importance"))
					st_matrix("imp_U", imp_U)
					st_matrixrowstripe("imp_U", (J(rows(unit), 1, ""), unit))
					st_matrixcolstripe("imp_U", ("", "Importance"))
				}
			}
			st_local("outvar", respo)
			st_local("predvar", invtokens(preds'))
			st_local("mtry", strofreal(mTry_real))
		} else if (isplacebo == 1){
			st_store(., st_addvar("float", "pred_e·"+ respo), y_predict_mean)
			st_varlabel("pred_e·" + respo, "mean prediction of " + outcome + " in " + unit_tr + " generated by 'placebo unit'")
			st_store(., st_addvar("float", "pred_m·"+ respo), y_predict_quantile[,2])
			st_varlabel("pred_m·" + respo, "median prediction of " + outcome + " in " + unit_tr + " generated by 'placebo unit'")
		} else if (isplacebo == 2){
			st_store(., st_addvar("float", "pred_e·"+ respo + "·" + time_tr), y_predict_mean)
			st_varlabel("pred_e·" + respo + "·" + time_tr, "mean prediction of " + outcome + " in " + unit_tr ///
				+ " generated by 'placebo period " + time_tr + "'")
			st_store(., st_addvar("float", "pred_l·"+ respo + "·" + time_tr), y_predict_quantile[,1])
			st_varlabel("pred_l·" + respo + "·" + time_tr, "lower prediction of " + outcome + " in " + unit_tr ///
				+ " generated by 'placebo period " + time_tr + "'")
			st_store(., st_addvar("float", "pred_m·"+ respo + "·" + time_tr), y_predict_quantile[,2])
			st_varlabel("pred_m·" + respo + "·" + time_tr, "median prediction of " + outcome + " in " + unit_tr ///
				+ " generated by 'placebo period " + time_tr + "'")
			st_store(., st_addvar("float", "pred_u·"+ respo + "·" + time_tr), y_predict_quantile[,3])
			st_varlabel("pred_u·" + respo + "·" + time_tr, "upper prediction of " + outcome + " in " + unit_tr ///
				+ " generated by 'placebo period " + time_tr + "'")
		}
	}
	void qcm_train_summary(real scalar nTree, real scalar mTry, string scalar maxDepth, real scalar minLeafSize, real scalar seed, real scalar minSamplesSplit){
		printf("{hline 70}\n")
		printf("{txt} %-60s = {res}%5.0g\n", "Number of trees to grow", nTree);
		printf("{txt} %-60s = {res}%5.0g\n", "Maximum depth of the trees", (maxDepth == ""?.:strtoreal(maxDepth)));
		printf("{txt} %-60s = {res}%5.0g\n", "Number of predictors randomly selected at each split", mTry);
		printf("{txt} %-60s = {res}%5.0g\n", "Minimum number of obs required at each terminal node", minLeafSize);
		printf("{txt} %-60s = {res}%5.0g\n", "Minimum number of obs required to split an internal node", minSamplesSplit);
		printf("{txt} %-60s = {res}%5.0g\n", "Seed used by the random number generator", seed);
		printf("{hline 70}\n")
	}
	void qcm_placebo(string scalar depvar, string scalar unit_tr, string scalar unit_ctrl, string scalar time, string scalar time_tr){
		time = tokens(time)'
		tr_eff = st_data(., "tr_e·"+ depvar + "·"+ unit_tr)
		eff = (tr_eff, st_data(., invtokens("tr_e·"+ depvar + "·" :+ tokens(unit_ctrl))))
		pval = J(rows(eff), 3, .)
		for(i = 1; i <= rows(pval); i++) {
			pval[i, 1] = mean((abs(tr_eff[i, 1]) :<= abs(eff[i, .]))')
			pval[i, 2] = mean((tr_eff[i, 1] :<= eff[i, .])')
			pval[i, 3] = mean((tr_eff[i, 1] :>= eff[i, .])')
		}
		qcm_print_pval(time, ("Time", "Treatment Effect", "Two-sided ", "Right-sided", "Left-sided"), "p-value of Treatment Effect", (tr_eff, pval), time_tr, 0, (16, 11, 11, 11), 0, 0)
		printf("{p 0 6 2}{txt}Note: (1) The two-sided p-value of the treatment effect for a particular period is " 
			+ "defined as the frequency that the absolute values of the placebo effects are greater than or equal " 
			+ "to the absolute value of treatment effect.\n{p_end}")
		printf("{p 6 6 2}{txt}(2) The right-sided (left-sided) p-value of the treatment effect for a particular period " 
			+ "is defined as the frequency that the placebo effects are greater (smaller) than or equal to the " 
			+ "treatment effect.\n{p_end}")
		printf("{p 6 6 2}{txt}(3) If the estimated treatment effect is positive, then the right-sided p-value is " 
			+ "recommended; whereas the left-sided p-value is recommended if the estimated treatment effect is negative.{p_end}")
		stata("cap drop pvalTwo"); stata("cap drop pvalRight"); stata("cap drop pvalLeft");
		st_store(., st_addvar("float", "pvalTwo"), pval[.,1])
		st_store(., st_addvar("float", "pvalRight"), pval[.,2])
		st_store(., st_addvar("float", "pvalLeft"), pval[.,3])
	}
	void qcm_print_pval(string matrix rownames, string matrix colnames, string scalar colname, real matrix M, string scalar startstr, real scalar isMean, real matrix wideM, real scalar extend, real scalar isInt){
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
			printf(stritrim(sprintf("{txt}Note: The average treatment effect over the posttreatment periods " 
				+ "is{res} %10.4f{txt}.\n", meanM[., 3])))
	}
	void qcm_print_imp(string scalar name, string scalar sheetlabel){
		rownames = st_matrixrowstripe(name)[., 2]
		M = st_matrix(name)[., .]
		M = sort(((1..rows(M))', M), -2)
		rownames = rownames[M[., 1], .]
		M = M[., 2]
		st_matrix(name, M)
		st_matrixcolstripe(name, ("", "Importance"))
		st_matrixrowstripe(name, (J(rows(M), 1, ""), rownames))
		qcm_print(rownames, (sheetlabel, "Importance"), M, "", 2, (10, 10), 0, 0, 0)
	}
	void qcm_print_imp_preds(string scalar name){
		rownames = st_matrixrowstripe(name)[., 2]
		M = st_matrix(name)[., .]
		temp = (vec(1..rows(M)), M)
		temp = sort(temp, 2)
		temp = temp[rows(temp)..1, .]
		M = temp[., 2]
		rownames = rownames[temp[., 1], .]
		colnames = ("Pred", "ictor", "Importance")
		rownamesList = J(rows(rownames), 2, "")
		for(i = 1; i <= rows(rownames); i++){
			rownamesList[i, .] = ustrsplit(rownames[i], "·")
		}
		wide1 = max(strlen((rownamesList[., 1]\colnames[1])))
		wide2 = max(strlen((rownamesList[., 2]\colnames[2])))
		printf("{hline " + strofreal(wide1 + wide2 + 3) + "}{c TT}{hline 11}\n")
		printf(" {txt}%~" + strofreal(wide1 + wide2 + 1) + "s ", "Predictor")
		printf("{c |} %10s \n", colnames[3])
		printf("{hline " + strofreal(wide1 + wide2 + 3) + "}{c +}{hline 11}\n")
		for(i = 1; i <= rows(M); i++){
			printf(" {txt}%" + strofreal(wide1) + "s", rownamesList[i, 1])
			printf("{txt}·%-" + strofreal(wide2) + "s ", rownamesList[i, 2])
			printf("{c |} {res}%9.4f \n", M[i])
		}
		printf("{hline " + strofreal(wide1 + wide2 + 3) + "}{c +}{hline 11}\n")
		sumM = sum(M[1..rows(M), .])
		printf(" {txt}%~" + strofreal(wide1 + wide2 + 1) + "s ", "Total")
		printf("{c |} {res}%9.4f \n", sumM)
		printf("{hline " + strofreal(wide1 + wide2 + 3) + "}{c BT}{hline 11}\n")
	}
end

* 1.0.0 (2023.11.19) Submit the initial version of qcm to SSC
