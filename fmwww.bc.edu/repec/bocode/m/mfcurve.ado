*! version 1.0 \ Daniel Krähmer \ June 2023
capture program drop mfcurve

program mfcurve, rclass
	version 16
	syntax varname(numeric) [if] [in], factors(varlist min=1) ///
		[groupvar(varname)		///
		test(str)				///
		level(cilevel) 			///
		show(str)				///
		boxplot					///
		style_m_sig(str)		///
		style_m_nosig(str)		///
		style_ci_sig(str)		///
		style_ci_nosig(str)		///
		style_ind_act(str)		///
		style_ind_pas(str)		///
		style_l_mean(str)		///
		YLABel(numlist)	*		///
		]
qui{
	preserve 

	* Test for fatal conditions
	if ("`boxplot'" == "boxplot") &	("`test'" != "" | "`show'" != "") {
		di as err "boxplot may not be combined with options test() and show()"
		exit
	}
	
	if ("`test'" != "") & !inlist("`test'", "mean", "zero") {
		di as err "option test() incorrectly specified "
		exit
	}
	
	if "`show'" != "" {
		local show_legal mean sig ci_regular ci_gradient groupsize
		local show_chosen: subinstr local show "," ""
		local show_chosen: list uniq show_chosen
		local options_check: list show_chosen in show_legal
		if `options_check' != 1 {
			di as err "option show() incorrectly specified "
			exit
		}
		else if	"`test'" == "" & 	(strpos("`show_chosen'", "sig") 		| ///
									 strpos("`show_chosen'", "ci_regular") 	| ///
									 strpos("`show_chosen'", "ci_gradient") ) {
			di as err "show(sig/ci_regular/ci_gradient) require option test(...) to be specified"
			exit
		} 
	}
	
	* Drop ineligible observations
	marksample touse
	quietly count if `touse'
	if `r(N)' == 0 {
		error 2000
	}
	keep if `touse' == 1
	drop if missing(`varlist')
	local factors_csep = usubinstr("`factors'", " ", ", ", .)
	drop if missing(`factors_csep')

	* Define distinct groups
	tempvar group
	gen `group' = . 
	if "`groupvar'" != "" {				// based on groupvar(...)
		replace `group' = `groupvar'
	}
	else {								// based on factor combinations
		local fcomb = ""
		foreach var of varlist `factors' {
			local fcomb "`fcomb' string(`var') +"
		}
		local fcomb = usubstr("`fcomb'", 1, strlen("`fcomb'") - 1)
		tempvar factorcomb
		gen `factorcomb' = `fcomb'
		bysort `factorcomb': replace `group'= 1 if _n == 1 
		replace `group'= sum(`group')
		drop `factorcomb'
	}

	* Calculate mean outcome
	tempvar group_mean
	bysort `group': egen `group_mean' = mean(`varlist')		// per group
	if strpos("`show_chosen'", "mean") { 					// overall
		summarize `varlist', meanonly
		local meanline "yline(`r(mean)', `style_l_mean')"
	}

	* If option boxplot is used, calculate quartiles and determine outliers 
	if "`boxplot'" == "boxplot"{
		levelsof `varlist'
		if r(r) == 2 {
			di as err "option boxplot may not be used for binary outcomes"
			exit
		}
		else {
			foreach element in median upq loq iqr upper lower outlier {
				tempvar `element'
			}
			egen `median'	= median(`varlist'), by(`group')
			egen `upq' 		= pctile(`varlist'), by(`group') p(75) 
			egen `loq' 		= pctile(`varlist'), by(`group') p(25)
			gen  `iqr'		= `upq' - `loq'
			egen `upper'	= max(`varlist' / (`varlist' < `upq' + 1.5*`iqr')), by(`group')
			egen `lower' 	= min(`varlist' / (`varlist' > `loq' - 1.5*`iqr')), by(`group')
			bysort `group': gen `outlier' = cond(!inrange(`varlist', `lower', `upper'), 1, 0)
		}
	}

	* If option test() is specified, run appropriate tests and flag significant values
	tempvar sig
	gen `sig' = 0
	if inlist("`test'", "mean", "zero") {
		
		if "`test'" == "mean" {
			tempvar ttestgroup
			gen `ttestgroup' = .
			levelsof `group'
			matrix results  = J(11, `r(r)', .)
			foreach i in `r(levels)' {
				replace `ttestgroup' = 0
				replace `ttestgroup' = 1 if `group' == `i'
				ttest `varlist', by(`ttestgroup')
				replace `sig' = 1 if (`group' == `i') & (`r(p)' < (100-`level')/100)
				local mu_diff = `r(mu_2)' - `r(mu_1)'
				local crit_value = invttail(`r(N_2)' - 1, (100 - `level') / 200)
				local ci_lower = `r(mu_2)' - `crit_value' * (`r(sd_2)'/sqrt(`r(N_2)'))
				local ci_upper = `r(mu_2)' + `crit_value' * (`r(sd_2)'/sqrt(`r(N_2)'))
				
				matrix input mat_`i' = ( ///
					`i' 		\ ///
					`r(mu_1)' 	\ ///
					`r(mu_2)' 	\ ///
					`r(sd_1)' 	\ ///
					`r(sd_2)' 	\ ///
					`r(N_1)' 	\ ///
					`r(N_2)' 	\ ///
					`mu_diff' 	\ ///
					`ci_lower'	\ ///
					`ci_upper'	\ ///
					`r(p)' 		)			
				matrix results[1,`i'] = mat_`i'
			}
			matrix rownames results = ///
					group	///
					mu_1	///
					mu_2	///
					sd_1	///
					sd_2	///
					N_1		///
					N_2		///
					mu_diff	///
					ci_l	///
					ci_u	///
					p
		}
		else if "`test'" == "zero" {
			levelsof `group'
			matrix results  = J(5, `r(r)', .)	
			foreach i in `r(levels)' {
				ttest `varlist' == 0 if `group' == `i'
				replace `sig' = 1 if (`group' == `i') & (`r(p)' < (100-`level')/100)
				matrix input mat_`i' = ( ///
					`i' 		\ ///
					`r(mu_1)' 	\ ///
					`r(sd_1)' 	\ ///
					`r(N_1)' 	\ ///
					`r(p)' 		)
				matrix results[1,`i'] = mat_`i'
			}
			matrix rownames results = ///
					group	///
					mu_1	///
					sd_1	///
					N_1		///
					p
		}
		return matrix testresults results
	}
	
	* Keep only one observation per factor combination (+ outliers, if existant)
	tempvar groupcount
	tempvar groupsize
	if "`boxplot'" == "boxplot"{
		sort `group' `outlier'
		bysort `group': gen `groupcount' = _n
		bysort `group': egen `groupsize' = max(`groupcount')
		keep if `groupcount' == 1 | `outlier' == 1
	}
	else{
		sort `group'
		bysort `group': gen `groupcount' = _n
		bysort `group': egen `groupsize' = max(`groupcount')
		keep if `groupcount' == 1 
	}
	
	* Rank factor combinations 
	tempvar rank
	if "`boxplot'" == "boxplot"{		// for boxplot: by median
		sort `outlier' `median'
		gen `rank' = sum(`group' != `group'[_n-1]) if `groupcount' == 1
		sort `group' `rank'
		replace `rank' = `rank'[_n-1] if `rank' == .
	}
	else {								// otherwise: by mean
		sort `group_mean'
		gen `rank' = _n 
	}
	
	* Label values of "rank" using variable group
	forvalues n = 1/`=_N' {
		label define rank_lbl `=`rank'[`n']' "`=`group'[`n']'", modify
	}
	label values `rank' rank_lbl
	
	* If show(groupsize) is used, add case numbers to x-axis 
	if strpos("`show_chosen'", "groupsize") {	
		levelsof `rank'
		local xmlab
		foreach element in `r(levels)' {
			qui sum `groupsize' if `rank' == `element'
			local groupsize_loc `r(mean)'
			qui sum `group' if `rank'  == `element'
			local xmlab `xmlab' `element' "{it:n}{subscript:`r(mean)'}=`groupsize_loc'"
		}
	}
	
	* If option show(ci_gradient) is used, draw rspikes with a gradient
	if strpos("`show_chosen'", "ci_gradient") {
		local gradient_no = 5
		if mod(`level', `gradient_no') != 0 {
			local extra_ci = `level'
		}
		local max = `gradient_no' * floor(`level'/`gradient_no')
		
		levelsof `group'
		foreach i in `r(levels)' {
			foreach C of numlist 0(`gradient_no')`max' `extra_ci' {
				local mean  = mat_`i'[3, 1]
				local sd 	= mat_`i'[5, 1]
				local n  	= mat_`i'[7, 1]
				local se = `sd'/sqrt(`n')
				
				tempvar ub_gr`i'_`C'
				gen `ub_gr`i'_`C'' = `mean' + abs(invttail(`n',(1-`C'/100)/2)) * `se'
				
				tempvar lb_gr`i'_`C'
				gen `lb_gr`i'_`C'' = `mean' - abs(invttail(`n',(1-`C'/100)/2)) * `se'
			}
		}
		foreach i in `r(levels)' {
			forvalues C = `max'(-`gradient_no')0 {
				local ci_nosig `ci_nosig' (rspike `ub_gr`i'_`C'' `lb_gr`i'_`C'' `rank' if `group' == `i' & `sig' == 0, pstyle(p1) `style_ci_nosig' lcolor(*`=(100-`C'/1.1)/100'))
				local ci_sig `ci_sig' (rspike `ub_gr`i'_`C'' `lb_gr`i'_`C'' `rank' if `group' == `i' & `sig' == 1, pstyle(p2) `style_ci_sig' lcolor(*`=(100-`C'/1.1)/100'))
				local ci `ci_nosig' `ci_sig'
			}
		}
	}
		
	* If option show(ci_regular) is used, draw basic rcaps
	if strpos("`show_chosen'", "ci_regular") {
		levelsof `group'
		foreach i in `r(levels)' {
			local mean  = mat_`i'[3, 1]
			local sd 	= mat_`i'[5, 1]
			local n  	= mat_`i'[7, 1]
			local se = `sd'/sqrt(`n')
			
			tempvar ub_gr`i'_`level'
			gen `ub_gr`i'_`level'' = `mean' + abs(invttail(`n',(1-`level'/100)/2)) * `se'
			
			tempvar lb_gr`i'_`level'
			gen `lb_gr`i'_`level'' = `mean' - abs(invttail(`n',(1-`level'/100)/2)) * `se'
			
			local ci_nosig 	`ci_nosig' 	(rcap `ub_gr`i'_`level'' `lb_gr`i'_`level'' `rank' if `group' == `i' & `sig' == 0, pstyle(p1) `style_ci_nosig')
			local ci_sig 	`ci_sig' 	(rcap `ub_gr`i'_`level'' `lb_gr`i'_`level'' `rank' if `group' == `i' & `sig' == 1, pstyle(p2) `style_ci_sig' )
			local ci `ci_nosig' `ci_sig'
		}
	}
	
	* Determine ylabels
	if "`ylabel'" != "" {					// customized by user
		local ylab_count : word count `ylabel'
		local minlab: word 1 of `ylabel'
		local maxlab: word `ylab_count' of `ylabel'
		local maxval = `maxlab'
		local minval = `minlab'
		local stepno = `ylab_count' - 1
		local plotrange = `maxlab' - `minlab'
		local steps = abs(`plotrange'/`stepno')
	}
	else {									// automatically generated
		summarize `group_mean', meanonly
		local maxval 	= `r(max)'
		local minval	= `r(min)'

		if "`boxplot'" == "boxplot" {
			sum `upper'
			local upperbound_boxplot = `r(max)'

			sum `lower', meanonly
			local lowerbound_boxplot = `r(min)'
			
			levelsof `outlier'
			if r(r) > 1 {
				sum `varlist' if `outlier' == 1
				local upperbound_boxplot	= `r(max)'
				local lowerbound_boxplot	= `r(min)'
			} 
			
			local maxval = max(`maxval', `upperbound_boxplot')
			local minval = min(`minval', `lowerbound_boxplot')
		}
		
		if strpos("`show_chosen'", "ci") {
			levelsof `group'
			foreach i in `r(levels)' {
				local ci_max `ci_max' `ub_gr`i'_`level''
				local ci_min `ci_min' `lb_gr`i'_`level''
			}
			
			tempvar maximum_ci
			egen `maximum_ci' = rowmax(`ci_max')
			
			tempvar minimum_ci
			egen `minimum_ci' = rowmin(`ci_min')
			
			sum `maximum_ci', meanonly
			local maxval = `r(mean)'
			
			sum `minimum_ci', meanonly
			local minval = `r(mean)'
		}	
		
		local scinot 	= strofreal(`maxval',"%-9.3e")	
		local expo 		= usubstr("`scinot'", strpos("`scinot'","e") + 1, .)	
		local digits 	= ceil((real(usubstr("`scinot'", 1, strpos("`scinot'","e") - 1))*10))/10
		local maxlab	= `digits' * 10^(`expo')

		local scinot 	= strofreal(`minval',"%-9.3e")
		local expo 		= usubstr("`scinot'", strpos("`scinot'","e") + 1, .)	
		local digits 	= floor((real(usubstr("`scinot'", 1, strpos("`scinot'","e") - 1))*10))/10
		local minlab	= `digits' * 10^(`expo')

		local plotrange = `maxlab' - `minlab'
		if strlen(string(`plotrange'/5)) < strlen(string(`plotrange'/4)) {
			local stepno = 5
		}
		else {
			local stepno = 4
		}
		local steps = abs(`plotrange'/`stepno')
	}
	
	* Determine spacing based on range of upper plot (as ~ 1/10)	
	local spacing = abs((`minlab' - `maxlab')/10)
	
	* Create vertical increment
	local ind = `minlab' - 1.5 * `spacing'
	
	* Iterate over factors (I)
	foreach var of varlist `factors'{ 
		
		* Split factor variable into dummies and collect tempvars in local
		levelsof `var'
		foreach value in `r(levels)' {
			tempvar `var'_d`value'
			gen ``var'_d`value'' = `var' == `value'
			local dummies_`var' `dummies_`var'' "``var'_d`value''"
		}
	}
	
	* Iterate over factors (II)
	foreach var of varlist `factors'{ 	
		
		* Add factors to ymlabels 
		local ymlabels "`ymlabels' `ind' "{bf: `var'}" "
		
		* Label values of dummies using labels from factor variables
		levelsof `var'
		foreach value in `r(levels)' {
			local `var'_vallab_`value': label (`var') `value' 
			lab define `var'_label_d`value' 1 "``var'_vallab_`value''"
			lab val ``var'_d`value'' `var'_label_d`value'
		}
		
		* Within factors, iterate over dummies to...
		foreach dumvar in `dummies_`var''{

			*...generate indicators for each level  
			tempvar ind_`dumvar'
			gen `ind_`dumvar'' = `ind' - 1.2 * `spacing'
			local ind = `ind' - 1.2 * `spacing'

			*...add levels to ymlabels 
			local component_label: label (`dumvar') 1
			local ymlabels "`ymlabels' `ind' "`component_label'" "

			*...generate indicators for active (black), passive (gray)
			local passive 	= "`passive' (scatter `ind_`dumvar'' `rank' if `dumvar'!=., msymbol(S) mcolor(gs15) `style_ind_pas')"
			local active	= "`active'  (scatter `ind_`dumvar'' `rank' if `dumvar'==1, msymbol(S) mcolor(gs2) `style_ind_act')"
		}

		* Add slightly larger increment between dimensions
		local ind = `ind' - 1.5 * `spacing'
	}
	

	* Determine vertical position of ytitle (vertically centered on upper graph)
	local height_upper = `maxlab' - `minlab'
	local height_total = `maxlab' - `ind' + 4.5 * `spacing'
	local rel_h = 100 * (`height_upper' / `height_total')
	
	
	*********************
	* Graph
	*********************

	* Prespecify some useful twoway options to finetune the graph
	levelsof `rank'
	#delimit ;
	local scatterdesign	
	"
	xlabel(1/`r(r)', valuelabel noticks)
	xmlabel(`xmlab', noticks labgap(5))
	ylabel(`minlab'(`steps')`maxlab', valuelabel grid gmin gmax angle(0))
	ymlabel(`ymlabels', angle(0) noticks labsize(medsmall))
	xtitle("Group/Condition", margin(top))
	ytitle("Outcome", width(`rel_h'rs) placement(n)) 
	"
	;
	#delimit cr
	
	* If option show(sig) is used, change style of significant estimates
	if strpos("`show_chosen'", "sig") {
		local style_sig pstyle(p2) `style_sig' 
	}
	foreach plot in nosig sig {
		if "`style_`plot''" != ""{
			local design_`plot' = "`style_`plot''"
		}
	}

	* Draw graph (either boxplots or point estimates)
	if "`boxplot'" == "boxplot"{
		twoway ///
			(rbar 	`median' `upq' 	`rank' if `outlier' == 0, pstyle(p1) barw(0.35)) ///
			(rbar 	`median' `loq' 	`rank' if `outlier' == 0, pstyle(p1) barw(0.35)) ///
			(rspike `upq' `upper' 	`rank' if `outlier' == 0, pstyle(p1)) ///
			(rspike `loq' `lower' 	`rank' if `outlier' == 0, pstyle(p1)) ///
			(rcap 	`upper' `upper' `rank' if `outlier' == 0, pstyle(p1) msize(*2)) ///
			(rcap 	`lower' `lower' `rank' if `outlier' == 0, pstyle(p1) msize(*2)) ///
			(scatter `varlist' 		`rank' if `outlier' == 1, msymbol(X)) ///
			`passive' `active' /// 
			, `scatterdesign' legend(off) `meanline' graphregion(margin(large)) `options'	
	}
	else{
		twoway `ci' ///
			(scatter `group_mean' `rank' if `sig' == 0, pstyle(p1) `style_m_nosig') 	///
			(scatter `group_mean' `rank' if `sig' == 1, pstyle(p2) `style_m_sig') 	///
			`passive' `active'  /// 
			, `scatterdesign' legend(off) `meanline' graphregion(margin(large)) `options'
	}
	
	restore
}
end								
