

capture program drop pretty_logistic
	program define pretty_logistic
	version 18.0
	syntax [if] [in] [fweight], ///
	PREDictor(varname) ///
	LOGtype(string) ///
	OUTcomes(varlist) ///
	[CONfounders(varlist fv ts)] ///
	[TITLE(string)] ///
	[SAVing(string)] ///
	[NOSUBheadings] ///
	[FLOG(string)] ///
	[FP(string)] ///
	[FCI(string)] ///
	[REequation(string)] ///
	[REPLACE]

	
	************************************************
	** Setting up environment and clearing macros **
	************************************************
	collect clear
	marksample touse
	tempfile data
	qui save `data'
	macro drop _m
	
	cap qui keep if `touse'
	
	if "`saving'" != "" {
	putdocx clear 
	}
	
	***************************************************
	** Setting decimal place options if none defined **
	***************************************************
	if `:word count `flog'' == 0{
	 	local flog "%9.3fc"
	 }
	 
	if `:word count `fp'' == 0{
	 	local fp "%9.3fc"
	 }
	 
	if `:word count `fci'' == 0{
	 	local fci "%9.3fc"
	 }
	
	
	********************************************
	** Generating macro for frequency weight **
	********************************************
	
	local weight "[`weight'`exp']"
	
	if "`weight'" == "[]"{
		local weight
	}
	
	
	***********************************
	** Recoding predictor if not 0/1 **
	***********************************
	qui levelsof(`predictor'), local(levelcheck)
	
	local vlname: value label `predictor'
		
	if "`vlname'" != "" {
		
	qui foreach level of local levelcheck{
		
	local m = `m' + 1
	local vl`m':label `vlname' `level'
	
	}
	
	}
	
	if `:word count `levelcheck'' > 2 {
		/*di as error "Predictor contains more than two levels"
		exit*/
		
		local levelnotbinary = 1 
		
	}
	
		else {
			
			local levelnotbinary = 0 
		}

	if `levelnotbinary' == 0 {
		
		tokenize "`levelcheck'"
		
		qui recode `predictor' (`1' = 0) (`2' = 1)
		
		***********************************************
		** Collecting value labels for the predictor ** 
		***********************************************	
		
		if "`vlname'" != "" {
			
		label define predictorlabel 0 "`vl1'" 1 "`vl2'"
		label values `predictor' predictorlabel
		
			
		local a: label(`predictor') 0
		local b: label(`predictor') 1
		
		label drop predictorlabel
		
		}
		
		
		else {
		
		local a "a"
		local b "b"
	
	}
	
		*********************************************
		** Creating local for factor specification **
		********************************************
		
		local predictorspecific i.`predictor'
		
		di "`predictorspecific'"
		
	}
	
	else {
	
	local predictorspecific `predictor'
	
	}
	
	****************************************
	** Labelling outcomes if not labelled ** 
	****************************************
	
	foreach var of local outcomes {
		
		if "`: variable label `var''" == "" {
			
			la var `var' `var'
			
		} 
		
	}
	
	
**********************************
** SET LOOP FOR MULTIPLE TABLES **	
**********************************	
	
	qui foreach j of numlist 1/ `:word count `logtype'' {
	
	collect clear 
	
	macro drop _i _z _firstvarlabels _nextvarlabel _finalrows ///
	_nextrow A_N B_N _m 
		
************************************************
** CALCULATE DESCRIPTIVES FOR LOGISTIC TABLES **
************************************************ 
	*Freq and Percent
	if `levelnotbinary' != 1 {
		
	table () (`predictor') `weight', ///
	stat(fvfrequency `outcomes') ///
	stat(fvpercent `outcomes')
	
	*Counts
	count if `predictor' == 0
	local A_N `r(N)'
		
	count if `predictor' == 1 
	local B_N `r(N)'
		
	}	
	
	else {
		
	table ()() `weight', ///
	stat(fvfrequency `outcomes') ///
	stat(fvpercent `outcomes')
		
	}
		
	** Bold Category Headings 	
 	qui foreach var of local outcomes {
	local q = `q' + 1
	local variablelabel :variable label `var'
	
	levelsof `var', local(`var'f)
	
	qui foreach l of local `var'f {
	
	local `var'fl ``var'fl' `l'.`var'
	
	}
	

	if "`variablelabel'" != "" {
	collect addtags varheading`q'["`:variable label `var''"], ///
	fortags(colname[``var'fl'])

	}

	
	else {
	collect addtags varheading`q'[`var'], fortags(colname[``var'fl'])
	}
	
	collect style cell varheading`q'#cell_type[row-header], ///
	font(, bold)
	
	collect style cell colname[``var'fl']#cell_type[row-header], ///
	font(, nobold)
	
	collect style header varheading`q'#cell_type[row-header], title(hide) level(label)
	
	collect style header colname[``var'fl'], title(hide)

	}
	
		** Hide New Dimension Headings 
		qui foreach var of local outcomes {
		local p = `p' + 1
			
			if `p' == 1 {
			local categoricalheading varheading`p'#colname[``var'fl'] 
			local tagheading ``var'fl'
		}
		
			else {
			local categoricalheading `categoricalheading' varheading`p'#colname[``var'fl'] 
			local tagheading `tagheading' ``var'fl'
			}
		
		}		
			
		
*********************
** RISK DIFFERENCE **
*********************		


		****************************
		** RD with no confounder **
		****************************
		if `"`:word `j' of `logtype''"' == "rd" {
		
		if `:word count `confounders'' == 0 & ///
		`:word count `reequation'' == 0 {		
		
		** Calculate risk difference
		noisily foreach var of local outcomes {
		melogit `var' `predictorspecific' `weight', or allbase
		collect get _r_b _r_lb _r_ub: margins, dydx(`predictor')
		local i = `i' + 1
		
		if `levelnotbinary' == 0 {
		collect remap colname[1.`predictor']=colname[1.`var'], ///
		fortags(cmdset[`i'])
		collect remap colname[0.`predictor']=colname[0.`var'], ///
		fortags(cmdset[`i'])
		collect recode result _r_p = _r_incorrect
		}
		
		else {
		collect remap colname[`predictor']=colname[1.`var'], ///
		fortags(cmdset[`i'])	
		}
		
	
		}
		
		*Collecting correct p-value
		qui foreach var of local outcomes{
		melogit `var' `predictorspecific' `weight', or allbase
		collect get _r_p
		
		if `levelnotbinary' == 0 {
		collect remap colname[1.`predictor'] = colname[1.`var'], fortags(result[_r_p]#`predictor'[1])
		}
		
		}

		
		
		*************************
		** RD with confounders **
		*************************
		
		else if `:word count `confounders'' != 0 & ///
		`:word count `reequation'' == 0 {
			
		** Calculate adjusted risk difference
		qui foreach var of local outcomes{
		melogit `var' `predictorspecific' `confounders' `weight', ///
		or allbase
		collect get _r_b _r_lb _r_ub _r_p: margins, dydx(`predictor')
		local i = `i' + 1
		
		if `levelnotbinary' == 0 {
		collect remap colname[1.`predictor']=colname[1.`var'], ///
		fortags(cmdset[`i'])
		collect recode result _r_p = _r_incorrect
		}
		
		else {
		collect remap colname[`predictor']=colname[1.`var'], ///
		fortags(cmdset[`i'])	
		}	
		
		}
		
		*Collecting correct p-value
		qui foreach var of local outcomes{
		melogit `var' `predictorspecific' `confounders' `weight', or allbase
		collect get _r_p
		
		if `levelnotbinary' == 0 {
		collect remap colname[1.`predictor'] = colname[1.`var'], fortags(result[_r_p]#`predictor'[1])
		}
		
		}
		
		** Add note for confounders
		fvrevar `confounders', list
		
		local basevar `r(varlist)'
		
		foreach var of local basevar {
		local z = `z' + 1
		if `z' == 1 {
				local firstvarlabels "`:var label `var''"
				local varlabels `firstvarlabels'
					}
					else {
						local nextvarlabel "`:var label `var''"
						local varlabels `firstvarlabels', `nextvarlabel'
					}
					
		}
		
		foreach var of local basevar {
		local has_label = ("`: var label `var''" != "")
		}
		
		if `has_label' != 0 {
		collect notes "Adjusted for `varlabels'"
		}
		
		else {
		collect notes "Adjusted for `basevar'"
		}
		
		
		
		}
	
		
		**********************************************
		** RD with no confounder and random effects **
		**********************************************		
		
		else if `:word count `confounders'' == 0 & ///
		`:word count `reequation'' != 0 {		
		
		** Calculate risk difference
		qui foreach var of local outcomes{
		melogit `var' `predictorspecific' `weight' || `reequation', or allbase
		collect get _r_b _r_lb _r_ub _r_p: margins, dydx(`predictor')
		local i = `i' + 1
		
		if `levelnotbinary' == 0 {
		collect remap colname[1.`predictor']=colname[1.`var'], ///
		fortags(cmdset[`i'])
		collect recode result _r_p = _r_incorrect
		}
		
		else {
		collect remap colname[`predictor']=colname[1.`var'], ///
		fortags(cmdset[`i'])	
		}
	
		}
		
		*Collecting correct p-value
		qui foreach var of local outcomes{
		melogit `var' `predictorspecific' `weight' || `reequation', or allbase
		collect get _r_p
		
		if `levelnotbinary' == 0 
		collect remap colname[1.`predictor'] = colname[1.`var'], fortags(result[_r_p]#`predictor'[1])
		}
		
		}
		}
		
		
		********************************************
		** RD with confounders and random effects **
		********************************************
		
		else if `:word count `confounders'' != 0 & ///
		`:word count `reequation'' != 0 {
			
		** Calculate adjusted risk difference
		qui foreach var of local outcomes{
		melogit `var' i.`predictor' `confounders' `weight' || `reequation', ///
		or allbase
		collect get _r_b _r_lb _r_ub _r_p: margins, dydx(`predictor')
		local i = `i' + 1
		collect remap colname[1.`predictor']=colname[1.`var'], ///
		fortags(cmdset[`i'])
		collect recode result _r_p = _r_incorrect
		}
		
		*Collecting correct p-value
		qui foreach var of local outcomes{
		melogit `var' `predictorspecific' `confounders' `weight' || `reequation', or allbase
		collect get _r_p
		collect remap colname[1.`predictor'] = colname[1.`var'], fortags(result[_r_p]#`predictor'[1])
		}
		
		** Add note for confounders
		fvrevar `confounders', list
		
		local basevar `r(varlist)'
		
		foreach var of local basevar {
		local z = `z' + 1
		if `z' == 1 {
				local firstvarlabels "`:var label `var''"
				local varlabels `firstvarlabels'
					}
					else {
						local nextvarlabel "`:var label `var''"
						local varlabels `firstvarlabels', `nextvarlabel'
					}
					
		}
		
		foreach var of local basevar {
		local has_label = ("`: var label `var''" != "")
		}
		
		if `has_label' != 0 {
		collect notes "Adjusted for `varlabels'"
		}
		
		else {
		collect notes "Adjusted for `basevar'"
		}
		
		
		
		}
		
	collect label levels result _r_b "Risk Difference", modify
	
		}
		
			
****************
** RISK RATIO **
****************

		************************************
		** Risk ratio with no confounders **
		************************************
		
		else if `"`:word `j' of `logtype''"' == "rr"{

		if `:word count `confounders'' == 0 & ///
		`:word count `reequation'' == 0 {
		
		** Calculate risk ratio
		qui foreach var of local outcomes{
		melogit `var' `predictorspecific' `weight', or allbase
		margins `predictor', post
		collect get _r_b _r_lb _r_ub: ///
		nlcom _b[1.`predictor'] / _b[0.`predictor']  
		local i = `i' + 1
		collect remap colname[_nl_1]=colname[1.`var'], ///
		fortags(cmdset[`i'])
		collect recode result _r_p = _r_incorrect
		}
	
		*Collecting correct p-value
		qui foreach var of local outcomes{
		melogit `var' `predictorspecific' `weight', or allbase
		collect get _r_p
		collect remap colname[1.`predictor'] = colname[1.`var'], fortags(result[_r_p]#`predictor'[1])
		}
	
	} 
		

		*************************
		** RR with confounders **
		*************************
		
		else if `:word count `confounders'' != 0 & ///
		`:word count `reequation'' == 0 {
			
		** Calculate adjusted risk ratio
		qui foreach var of local outcomes{
		melogit `var' `predictorspecific' `confounders' `weight', ///
		or allbase
		margins `predictor', post
		collect get _r_b _r_lb _r_ub: ///
		nlcom _b[1.`predictor'] / _b[0.`predictor']  
		local i = `i' + 1
		collect remap colname[_nl_1]=colname[1.`var'], ///
		fortags(cmdset[`i'])
		collect recode result _r_p = _r_incorrect
		}
		
		*Collecting correct p-value
		qui foreach var of local outcomes{
		melogit `var' `predictorspecific' `confounders' `weight', or allbase
		collect get _r_p
		collect remap colname[1.`predictor'] = colname[1.`var'], fortags(result[_r_p]#`predictor'[1])
		}
		
	
		** Add note for confounders
		fvrevar `confounders', list
		
		local basevar `r(varlist)'
		
		foreach var of local basevar {
		local z = `z' + 1
		if `z' == 1 {
				local firstvarlabels "`:var label `var''"
				local varlabels `firstvarlabels'
					}
					else {
						local nextvarlabel "`:var label `var''"
						local varlabels `firstvarlabels', `nextvarlabel'
					}
					
		}
		
		foreach var of local basevar {
		local has_label = ("`: var label `var''" != "")
		}
		
		if `has_label' != 0 {
		collect notes "Adjusted for `varlabels'"
		}
		
		else {
		collect notes "Adjusted for `basevar'"
		}
		
		
		}
		
		*******************************************************
		** Risk ratio with no confounders and random effects **
		*******************************************************

		else if `:word count `confounders'' == 0 & ///
		`:word count `reequation'' != 0 {
		
		** Calculate risk ratio
		qui foreach var of local outcomes{
		melogit `var' `predictorspecific' `weight' || `reequation', or allbase
		margins `predictor', post
		collect get _r_b _r_lb _r_ub: ///
		nlcom _b[1.`predictor'] / _b[0.`predictor']  
		local i = `i' + 1
		collect remap colname[_nl_1]=colname[1.`var'], ///
		fortags(cmdset[`i'])
		collect recode result _r_p = _r_incorrect
		}
		
		*Collecting correct p-value
		qui foreach var of local outcomes{
		melogit `var' `predictorspecific' `confounders' `weight' || `reequation', or allbase
		collect get _r_p
		collect remap colname[1.`predictor'] = colname[1.`var'], fortags(result[_r_p]#`predictor'[1])
		}
	
		} 
		

		********************************************
		** RR with confounders and random effects **
		********************************************
		
		else if `:word count `confounders'' != 0 & ///
		`:word count `reequation'' != 0 {
			
		** Calculate adjusted risk ratio
		qui foreach var of local outcomes{
		melogit `var' `predictorspecific' `confounders' `weight' || `reequation', ///
		or allbase
		margins `predictor', post
		collect get _r_b _r_lb _r_ub: ///
		nlcom _b[1.`predictor'] / _b[0.`predictor']  
		local i = `i' + 1
		collect remap colname[_nl_1]=colname[1.`var'], ///
		fortags(cmdset[`i'])
		collect recode result _r_p = _r_incorrect
		}
		
		*Collecting correct p-value
		qui foreach var of local outcomes{
		melogit `var' `predictorspecific' `confounders' `confounders' `weight' || `reequation', or allbase
		collect get _r_p
		collect remap colname[1.`predictor'] = colname[1.`var'], fortags(result[_r_p]#`predictor'[1])
		}
		
	
		** Add note for confounders
		fvrevar `confounders', list
		
		local basevar `r(varlist)'
		
		foreach var of local basevar {
		local z = `z' + 1
		if `z' == 1 {
				local firstvarlabels "`:var label `var''"
				local varlabels `firstvarlabels'
					}
					else {
						local nextvarlabel "`:var label `var''"
						local varlabels `firstvarlabels', `nextvarlabel'
					}
					
		}
		
		foreach var of local basevar {
		local has_label = ("`: var label `var''" != "")
		}
		
		if `has_label' != 0 {
		collect notes "Adjusted for `varlabels'"
		}
		
		else {
		collect notes "Adjusted for `basevar'"
		}
		
		
		}
		qui collect label levels result _r_b "Risk Ratio", modify
	
		}
			
****************
** ODDS RATIO **
****************

		************************************
		** Odds ratio with no confounders **
		************************************
		else if `"`:word `j' of `logtype''"' == "or"{
			
		if `:word count `confounders'' == 0 & ///
		`:word count `reequation'' == 0 {
		
		** Calculate odds ratio
		qui foreach var of local outcomes{
		collect get _r_b _r_lb _r_ub _r_p: ///
		melogit `var' `predictorspecific' `weight', or allbase
		local i = `i' + 1

		if `levelnotbinary' == 0 {
		collect remap colname[1.`predictor']=colname[1.`var'], ///
		fortags(cmdset[`i'])
		collect remap colname[0.`predictor']=colname[0.`var'], ///
		fortags(cmdset[`i'])
		}
		
		else {
		collect remap colname[`predictor']=colname[1.`var'], ///
		fortags(cmdset[`i'])	
		}	
		
		}
						
		} 
		
		*************************
		** OR with confounders **
		*************************
		
		else if `:word count `confounders'' != 0  & ///
		`:word count `reequation'' == 0 {
			
		** Calculate adjusted odds ratio
		qui foreach var of local outcomes{
		collect get _r_b _r_lb _r_ub _r_p: ///
		melogit `var' `predictorspecific' `confounders' `weight', ///
		or allbase
		local i = `i' + 1
		
		if `levelnotbinary' = 0 {
		collect remap colname[1.`predictor']=colname[1.`var'], ///
		fortags(cmdset[`i'])
		}
		
		else {
		collect remap colname[`predictor']=colname[1.`var'], ///
		fortags(cmdset[`i'])	
		}	
		
		}
		
		** Add note for confounders
		fvrevar `confounders', list
		
		local basevar `r(varlist)'
		
		foreach var of local basevar {
		local z = `z' + 1
		if `z' == 1 {
				local firstvarlabels "`:var label `var''"
				local varlabels `firstvarlabels'
					}
					else {
						local nextvarlabel "`:var label `var''"
						local varlabels `firstvarlabels', `nextvarlabel'
					}
					
		}
		
		foreach var of local basevar {
		local has_label = ("`: var label `var''" != "")
		}
		
		if `has_label' != 0 {
		collect notes "Adjusted for `varlabels'"
		}
		
		else {
		collect notes "Adjusted for `basevar'"
		}
		
		
		
		}

		******************************************************
		** Odds ratio with no confounders and random effects**
		******************************************************
			
		else if `:word count `confounders'' == 0 & /// 
		`:word count `reequation'' != 0 {
		
		** Calculate odds ratio
		qui foreach var of local outcomes{
		collect get _r_b _r_lb _r_ub _r_p: ///
		melogit `var' `predictorspecific' `weight' || `reequation', or allbase
		local i = `i' + 1
		
		if `levelnotbinary' == 0 {
		collect remap colname[1.`predictor']=colname[1.`var'], ///
		fortags(cmdset[`i'])
		} 
		
		
		else {
		collect remap colname[`predictor']=colname[1.`var'], ///
		fortags(cmdset[`i'])	
		}	
		
		}
						
		} 
		
		*************************
		** OR with confounders **
		*************************
		
		else if `:word count `confounders'' != 0 & /// 
		`:word count `reequation'' != 0 {
			
		** Calculate adjusted odds ratio
		qui foreach var of local outcomes{
		collect get _r_b _r_lb _r_ub _r_p: ///
		melogit `var' `predictorspecific' `confounders' `weight' || `reequation', ///
		or allbase
		local i = `i' + 1
		
		if `levelnotbinary' == 0 {
		collect remap colname[1.`predictor']=colname[1.`var'], ///
		fortags(cmdset[`i'])
		collect remap colname[0.`predictor']=colname[0.`var'], ///
		fortags(cmdset[`i'])
		}
		
		else {
		collect remap colname[`predictor']=colname[1.`var'], ///
		fortags(cmdset[`i'])	
		}	
		}
		
		** Add note for confounders
		fvrevar `confounders', list
		
		local basevar `r(varlist)'
		
		foreach var of local basevar {
		local z = `z' + 1
		if `z' == 1 {
				local firstvarlabels "`:var label `var''"
				local varlabels `firstvarlabels'
					}
					else {
						local nextvarlabel "`:var label `var''"
						local varlabels `firstvarlabels', `nextvarlabel'
					}
					
		}
		
		foreach var of local basevar {
		local has_label = ("`: var label `var''" != "")
		}
		
		if `has_label' != 0 {
		collect notes "Adjusted for `varlabels'"
		}
		
		else {
		collect notes "Adjusted for `basevar'"
		}
		
		
		
		}

	qui collect label levels result _r_b "Odds Ratio", modify
	
		}
		
		
*****************************************
** COLLECTING RESULTS FOR ALL LOGISTIC **
*****************************************

	*Combine upper and lower limits for 95% CI
	collect composite define _r_combined = _r_lb _r_ub, ///
	delimiter(" to ") replace trim
		
	*Collect risk difference and probibility statistics
	collect composite define _r_logistic= _r_b , replace
		
	collect composite define _r_prob = _r_p, replace
	
	foreach var of local outcomes {
		
	local outcomecount = `outcomecount' + 1

	collect addtags varheading`outcomecount'["`:variable label `var''"], fortags(result[_r_logistic _r_prob _r_combined])
	 
	}

	if `levelnotbinary' == 0 {
	
	foreach var of local outcomes {
		
	collect addtags extra[logistic], fortags(result[_r_logistic]#colname[1.`var'])
	collect addtags extra[probability], fortags(result[_r_prob]#colname[1.`var'])
	collect addtags extra[ci], fortags(result[_r_combined]#colname[1.`var'])
	
	}
	
	}
	
	else {
		
	foreach var of local outcomes {
		
	collect addtags extra[logistic], fortags(result[_r_logistic]#colname[1.`var'])	
		
	}	
		
	}

	*****************************************
	** Formatting results for all logistic **
	*****************************************
	
	*Label and combine counts and frequencies
	if `levelnotbinary' != 1 {
		
	collect label levels `predictor' ///
	0 "`a' [N = `A_N']" ///
	1 "`b' [N = `B_N']" ///
	, replace 
	
	}
	
	collect label dim `predictor' "Treatment Arm"
	
	
	
	*Recode frequency and percent results
	collect recode result `"fvfrequency"' = `"1"' ///
	`"fvpercent"' = `"2"'

	
	*Relabel statistics
	collect label levels result 1 "N" 2 "(%)" ///
	_r_combined "95% CI" ///
	_r_prob "p-Value", modify

	
	*Format minimum p-value
	collect style cell result[_r_p], minimum(0.001)

	*Format decimal places
	collect style cell result[_r_combined], ///
	sformat("(%s)") nformat(`fci')
	
	collect style cell result[2 ], nformat(`fp')
	
	collect style cell result[_r_b], nformat(`flog')
	
	
	**********************
	** Formatting table **
	**********************
	
	** Hid tag headings of column headers
	collect style header extra[probability ci logistic], ///
	level(hide) title(hide)
	
	
	** General alignment formatting
	collect style cell, halign(left)
	
	** Formatting % and N headers
	collect style cell colname#result[2], ///
	nformat(%5.1fc) sformat("(%s)") halign(left)
	
	collect style cell colname#result[1], halign(right)
	
	if `levelnotbinary' == 1 {

	collect label dim result "`: variable label `predictor''", modify
	
	collect style header result[1 2], title(label)
	
	}
	
	
	
	** Formatting Results alignment
	collect style cell result[1], halign(right)
	
	collect style cell result[2], halign(right)
	
	collect style cell result[_r_prob _r_logistic _r_combined], halign(center)

	** Bold column headings
	collect style cell cell_type[column-header], font(, bold)
	
	*Format vertical alignment 
	collect style cell, valign(center)
	
	collect style cell result[_r_prob _r_logistic _r_combined]#cell_type[column-header], valign(bottom) 
	
	*Widen margins
	collect style putdocx, ///
	cellmargin(bottom, 0.08) cellmargin(top, 0.03) ///
	layout(autofitcontents)
	
	*Change font size of notes
	collect style notes, font(calibri, size(10))
	
	
		************************************
		** Assembing Final Logistic Table **
		************************************
		
		if `levelnotbinary' == 0 {
			
		qui collect layout (`categoricalheading') ///
		(`predictor'[0 1]#result[1 2] ///
		extra[logistic ci probability]#result[_r_logistic _r_combined _r_prob])

		}
		
		else {
		
		collect label dim result "`:var l `predictor''"
	
		qui collect layout (`categoricalheading') ///
		(result[1 2] ///
		result[_r_logistic _r_combined _r_prob])
			
		}
	
		*Add a space between lines
		collect style row stack, spacer nobinder
	
***************************************
** GENERAL FORMATTING FOR ALL TABLES ** 		
****************************************
	
	******************
	** Adding title	**
	******************
	
	if `"`title'"' != "" {
	
	tokenize "`title'", parse(",")
	
	local x = `x' + 1
	
	if `j' == 1 {
	collect title "`1'"
	local exporttitle "`1'"
	}
	
	if `j' == 2 {
	collect title "`3'"
	local exporttitle "`3'" 
	}
	
	if `j' == 3 {
	collect title "`5'"
	local exporttitle "`5'"
	}
	
	}
	
	
	***************************
	** Setting export format **
	***************************
	
	collect style putdocx, layout(autofitcontents)
	
	
	************************
	** Exporting document **
	************************
		
	if "`saving'" != "" {
	collect export "`saving'", as(docx) `replace'	
	}

		
	
	*********************************
	** Displaying table on console **
	*********************************
	collect preview
	
	
	*********************************
	** Replacing original dataset **
	*********************************
	qui use `data', clear
	
	
	
	}
	
	collect preview
	
	end
	
	
	
	
	
	