*===================================================================================*
* Ado-file: 	ModPlot Version 1.1
* Author: 		Shutter Zor(左祥太)
* Affiliation: 	Accounting Department, Xiamen University
* E-mail: 		Shutter_Z@outlook.com 
* Date: 		2024/3/14 launch project
*				2025/2/26 first attempt    
*				2025/3/4  fix bug                                      
*===================================================================================*


capture program drop modplot
program define modplot, rclass
	version 13
	
	syntax, Model(string) [Plot Scheme(string) Dot Right *]
	
	*- check the model() option	
	local condition_if = subinword("`model'", "if", "S-Z-if", .)
	local condition_in = subinword("`model'", "in", "S-Z-in", .)
	if strpos("`condition_if'","S-Z-if")>0 | strpos("`condition_in'","S-Z-in")>0{
		dis as error "[if] or [in] can not specified in model() option"
		exit 198	   	    
	}
	
	*- parse dependent, independent, moderate and control variable
	local model_text = subinstr("`model'", ",", "++", .)
	tokenize "`model_text'", parse("++")
	local cmdvlist "`1'"
	
	if strpos("`model_text'","++") != 0 {
		local opts ", `4'"  // options 
	}
	else{
		local opts ""
	}
	
	gettoken cmd vlist: cmdvlist  // before ,
	gettoken depvar indepvars: vlist
	gettoken indepvar modctrlvar: indepvars
	gettoken modvar ctrlvar: modctrlvar
	
	/*
	dis "`depvar'"
	dis "`indepvar'"
	dis "`modvar'"
	dis "`ctrlvar'"
	dis "`cmd'"
	dis "`cmdvlist'"
	dis "`opts'"
	*/
	
	*- record independent and moderate variable levels
	*- command tab has limitation
	capture tab `indepvar'
	if _rc == 0 {
		local indepvar_level = r(r)
	}
	else {
		local indepvar_level = 3
	}
	capture tab `modvar'
	if _rc == 0 {
		local modvar_level = r(r)
	}
	else {
		local modvar_level = 3
	}
	
	*- y = coefaX + coefbM + coefcXM + coefd
	qui sum `depvar'
	local depvar_min = r(min)
	local depvar_sd  = r(sd)
	local depvar_max = r(max)
	qui sum `indepvar'
	local indepvar_min = r(min)
	local indepvar_sd  = r(sd)
	local indepvar_max = r(max)
	qui sum `modvar'
	local modvar_min = r(min)
	local modvar_sd  = r(sd)
	local modvar_max = r(max)
	
	*- case1: biclassified X and M
	if (`indepvar_level' == 2) & (`modvar_level' == 2) {
		
		*- print moderating regression
		dis " "
		dis "Your Regression:"
		if "`opts'" != "" {
			dis as result "`cmd' `depvar' i.`indepvar'##i.`modvar'`ctrlvar'`opts'" _n
			dis as input "Regression Result:"
		}
		else {
			dis as result "`cmd' `depvar' i.`indepvar'##i.`modvar'`ctrlvar'" _n
			dis as input "Regression Result:"
		}
		
		*- moderating regression and record parameters
		`cmd' `depvar' i.`indepvar'##i.`modvar' `ctrlvar' `opts'
		local coefa = _b[`indepvar_max'.`indepvar']
		local coefb = _b[`modvar_max'.`modvar']
		local coefc = _b[`indepvar_max'.`indepvar'#`modvar_max'.`modvar']
		local coefd = _b[_cons]
	}
	
	*- case2: biclassified X and continous M
	if (`indepvar_level' == 2) & (`modvar_level' != 2) {
		
		*- print moderating regression
		dis " "
		dis "Your Regression:"
		if "`opts'" != "" {
			dis as result "`cmd' `depvar' i.`indepvar'##c.`modvar'`ctrlvar'`opts'" _n
			dis as input "Regression Result:"
		}
		else {
			dis as result "`cmd' `depvar' i.`indepvar'##c.`modvar'`ctrlvar'" _n
			dis as input "Regression Result:"
		}
		
		*- moderating regression and record parameters
		`cmd' `depvar' i.`indepvar'##c.`modvar' `ctrlvar' `opts'
		local coefa = _b[`indepvar_max'.`indepvar']
		local coefb = _b[`modvar']
		local coefc = _b[`indepvar_max'.`indepvar'#c.`modvar']
		local coefd = _b[_cons]
	}

	*- case3: continous X and continous M
	if (`indepvar_level' != 2) & (`modvar_level' != 2) {
		
		*- print moderating regression
		dis " "
		dis "Your Regression:"
		if "`opts'" != "" {
			dis as result "`cmd' `depvar' c.`indepvar'##c.`modvar'`ctrlvar'`opts'" _n
			dis as input "Regression Result:"
		}
		else {
			dis as result "`cmd' `depvar' c.`indepvar'##c.`modvar'`ctrlvar'" _n
			dis as input "Regression Result:"
		}
		
		*- moderating regression and record parameters
		`cmd' `depvar' c.`indepvar'##c.`modvar' `ctrlvar' `opts'
		local coefa = _b[`indepvar']
		local coefb = _b[`modvar']
		local coefc = _b[c.`indepvar'#c.`modvar']
		local coefd = _b[_cons]
	}

	*- case4: continous X and biclassified M
	if (`indepvar_level' != 2) & (`modvar_level' == 2) {
		
		*- print moderating regression
		dis " "
		dis "Your Regression:"
		if "`opts'" != "" {
			dis as result "`cmd' `depvar' c.`indepvar'##i.`modvar'`ctrlvar'`opts'" _n
			dis as input "Regression Result:"
		}
		else {
			dis as result "`cmd' `depvar' c.`indepvar'##i.`modvar'`ctrlvar'" _n
			dis as input "Regression Result:"
		}
		
		*- moderating regression and record parameters
		`cmd' `depvar' c.`indepvar'##i.`modvar' `ctrlvar' `opts'
		local coefa = _b[`indepvar']
		local coefb = _b[`modvar_max'.`modvar']
		local coefc = _b[c.`indepvar'#`modvar_max'.`modvar']
		local coefd = _b[_cons]
	}
	
	*- return moderating results
	local function_ll_cons = `coefb' * `modvar_min' + `coefd'
	local function_ll_coefx = `coefa' + `coefc' * `modvar_min'
	local function_ul_cons = `coefb' * `modvar_max' + `coefd'
	local function_ul_coefx = `coefa' + `coefc' * `modvar_max'		
	
	local function_ll_dot1_y = `function_ll_coefx' * `indepvar_min' + `function_ll_cons'
	local function_ll_dot1_x = `indepvar_min'
	local function_ll_dot2_y = `function_ll_coefx' * `indepvar_max' + `function_ll_cons'
	local function_ll_dot2_x = `indepvar_max'		
	local function_ul_dot1_y = `function_ul_coefx' * `indepvar_min' + `function_ul_cons'
	local function_ul_dot1_x = `indepvar_min'
	local function_ul_dot2_y = `function_ul_coefx' * `indepvar_max' + `function_ul_cons'
	local function_ul_dot2_x = `indepvar_max'	
	
	local plot_ytitle_y_max = max(`function_ll_dot1_y', `function_ll_dot2_y', `function_ul_dot1_y', `function_ul_dot2_y')
	local plot_ytitle_y_min = min(`function_ll_dot1_y', `function_ll_dot2_y', `function_ul_dot1_y', `function_ul_dot2_y')
	local plot_xtitle_x_max = max(`function_ll_dot1_x', `function_ll_dot2_x', `function_ul_dot1_x', `function_ul_dot2_x')
	local plot_xtitle_x_min = min(`function_ll_dot1_x', `function_ll_dot2_x', `function_ul_dot1_x', `function_ul_dot2_x')
	
	return local mod_func = "`depvar' = `coefa'*`indepvar' + `coefb'*`modvar' + `coefc'*`indepvar'*`modvar' + `coefd'"
	return local mod_func_ll = "y = `function_ll_coefx'*x + `function_ll_cons'"
	return local mod_func_ul = "y = `function_ul_coefx'*x + `function_ul_cons'"
	
	*- draw a graph
	if "`plot'" != "" {
		local ylabel_begin = `plot_ytitle_y_min' - 0.5*`depvar_sd'   
		local ylabel_end   = `plot_ytitle_y_max' + 0.5*`depvar_sd'
		local xlabel_begin = `plot_xtitle_x_min' - 0.5*`indepvar_sd'
		local xlabel_end   = `plot_xtitle_x_max' + 0.5*`indepvar_sd'
		
		if "`right'" != "" {
			local legend_position = 3
		}
		else {
			local legend_position = 6
		}
		
		if "`dot'" == "" {
			twoway (function y = `function_ll_coefx'*x + `function_ll_cons'					///
								 , lp(dash) range(`plot_xtitle_x_min' `plot_xtitle_x_max')) ///
				   (function y = `function_ul_coefx'*x + `function_ul_cons'					///
								 , lp(dash) range(`plot_xtitle_x_min' `plot_xtitle_x_max'))	///	   
				   , legend(order(1 "Low MV (`modvar'=`modvar_min')" 						///
								  2 "High MV (`modvar'=`modvar_max')") col(1)				///
							pos(`legend_position'))											///
					 ylabel(`ylabel_begin' " " `plot_ytitle_y_min' "Low DV" 				///
					        `plot_ytitle_y_max' "High DV" `ylabel_end' " ", noticks)		///
					 xlabel(`xlabel_begin' " " `plot_xtitle_x_min' "Low IV" 				///
					        `plot_xtitle_x_max' "High IV" `xlabel_end' " ", noticks)		///
					 xtitle("") ytitle("") scheme(`scheme')	`options'		
		}
		else {
			twoway (function y = `function_ll_coefx'*x + `function_ll_cons'					///
								 , lp(dash) range(`plot_xtitle_x_min' `plot_xtitle_x_max')) ///
				   (function y = `function_ul_coefx'*x + `function_ul_cons'					///
								 , lp(dash) range(`plot_xtitle_x_min' `plot_xtitle_x_max'))	///
				   (scatteri `function_ll_dot1_y' `function_ll_dot1_x', mc(gs10) m(O))		///
				   (scatteri `function_ll_dot2_y' `function_ll_dot2_x', mc(gs10) m(O))		///
				   (scatteri `function_ul_dot1_y' `function_ul_dot1_x', mc(gs10) m(O))		///
				   (scatteri `function_ul_dot2_y' `function_ul_dot2_x', mc(gs10) m(O))		///	
				   , legend(order(1 "Low MV (`modvar'=`modvar_min')" 						///
								  2 "High MV (`modvar'=`modvar_max')") col(1)				///
							pos(`legend_position'))											///
					 ylabel(`ylabel_begin' " " `plot_ytitle_y_min' "Low DV" 				///
					        `plot_ytitle_y_max' "High DV" `ylabel_end' " ", noticks)		///
					 xlabel(`xlabel_begin' " " `plot_xtitle_x_min' "Low IV" 				///
					        `plot_xtitle_x_max' "High IV" `xlabel_end' " ", noticks)		///
					 xtitle("") ytitle("") scheme(`scheme')	`options'
		}			
	}



end
