

capture program drop pretty_logistic
	program define pretty_logistic
	version 17.0
	syntax [if] [in] [fweight], ///
	PREDictor(varname) ///
	[LOGtype(string)] ///
	[OUTcomes(varlist)] ///
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
		
	foreach level of local levelcheck{
	local m = `m' + 1
	local vl`m':label `vlname' `level'
	}
	
	}
	
	if `:word count `levelcheck'' > 2 {
		di as error "Predictor contains more than two levels"
		exit
	}

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
	
************************
** NO OPTION DEFINED **
************************
	
	******************************************************************
	** Creating empty table if no variables defined except predictor**
	******************************************************************
	
		if `:word count `outcomes'' == 0 {
		
		qui table `weight', stat(fvfrequency `predictor') ///
		stat(fvpercent `predictor')

		qui collect recode result ///
		`"fvfrequency"' = `"1"' `"fvpercent"' = `"2"'
		qui collect layout () (`predictor'#result[1 2])
		qui collect label levels result 1 "N" 2 "(%)", modify
		qui collect style cell result[2], ///
		nformat (`fcateg') sformat("(%s%%)")
		
			
		*Counts
		qui count if `predictor' == 0
		local A_N `r(N)'
		
		qui count if `predictor' == 1 
		local B_N `r(N)'

		*Label and combine counts and frequencies
		qui collect label levels `predictor' 0 ///
		"`a' [N = `A_N']" 1 "`b' [N = `B_N']", replace 
		
		qui collect style cell colname#result[2], ///
		nformat(%5.1fc) sformat("(%s%%)")
		
		qui collect label dim `predictor' "Treatment Arm"
	 
	 
		*Recode frequency and percent results
		qui collect recode result `"fvfrequency"' = `"1"' ///
		`"fvpercent"' = `"2"'

		
		*Relabel count and frequency
		qui collect label levels result 1 "N" 2 "(%)" ///

		
		***************************************
		** GENERAL FORMATTING FOR ALL TABLES ** 		
		****************************************
			
			******************
			** Adding title	**
			******************
			if `"`title'"' != "" {
				collect title "`title'"
			}

			
			***************************
			** Setting export format **
			***************************
		
			collect style putdocx, layout(autofitcontents)
			
			************************
			** Exporting document **
			************************
			if `"`saving'"' != "" {
			collect export "`saving'/`title'", as(docx) `replace'
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
		
		
	
**********************************
** SET LOOP FOR MULTIPLE TABLES **	
**********************************	

	else {
	
	foreach j of numlist 1/ `:word count `logtype'' {
	
	collect clear 
	
	macro drop _i _z _firstvarlabels _nextvarlabel _finalrows ///
	_nextrow A_N B_N _m 
		
************************************************
** CALCULATE DESCRIPTIVES FOR LOGISTIC TABLES **
************************************************ 
	*Freq and Percent
	qui table () (`predictor') `weight', ///
	stat(fvfrequency `outcomes') ///
	stat(fvpercent `outcomes')
		
	*Counts
	qui count if `predictor' == 0
	local A_N `r(N)'
		
	qui count if `predictor' == 1 
	local B_N `r(N)'
		
		
		
*********************
** RISK DIFFERENCE **
*********************		


		****************************
		** RD with no confounder **
		****************************
		if `"`:word `j' of `logtype''"' == "rd"{
		
		if `:word count `confounders'' == 0 & ///
		`:word count `reequation'' == 0 {		
		
		** Calculate risk difference
		qui foreach var of local outcomes{
		melogit `var' i.`predictor' `weight', or allbase
		collect get _r_b _r_lb _r_ub: margins, dydx(`predictor')
		local i = `i' + 1
		collect remap colname[1.`predictor']=colname[1.`var'], ///
		fortags(cmdset[`i'])
		collect recode result _r_p = _r_incorrect
		}
		
		*Collecting correct p-value
		qui foreach var of local outcomes{
		melogit `var' i.`predictor' `weight', or allbase
		collect get _r_p
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
		melogit `var' i.`predictor' `confounders' `weight', ///
		or allbase
		collect get _r_b _r_lb _r_ub _r_p: margins, dydx(`predictor')
		local i = `i' + 1
		collect remap colname[1.`predictor']=colname[1.`var'], ///
		fortags(cmdset[`i'])
		collect recode result _r_p = _r_incorrect
		}
		
		
		*Collecting correct p-value
		qui foreach var of local outcomes{
		melogit `var' i.`predictor' `confounders' `weight', or allbase
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
	
		
		**********************************************
		** RD with no confounder and random effects **
		**********************************************		
		
		else if `:word count `confounders'' == 0 & ///
		`:word count `reequation'' != 0 {		
		
		** Calculate risk difference
		qui foreach var of local outcomes{
		melogit `var' i.`predictor' `weight' || `reequation', or allbase
		collect get _r_b _r_lb _r_ub _r_p: margins, dydx(`predictor')
		local i = `i' + 1
		collect remap colname[1.`predictor']=colname[1.`var'], ///
		fortags(cmdset[`i'])
		collect recode result _r_p = _r_incorrect
		}
		
		
		*Collecting correct p-value
		qui foreach var of local outcomes{
		melogit `var' i.`predictor' `weight' || `reequation', or allbase
		collect get _r_p
		collect remap colname[1.`predictor'] = colname[1.`var'], fortags(result[_r_p]#`predictor'[1])
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
		melogit `var' i.`predictor' `confounders' `weight' || `reequation', or allbase
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
		
	qui collect label levels result _r_b "Risk Difference", modify
	
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
		melogit `var' i.`predictor' `weight', or allbase
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
		melogit `var' i.`predictor' `weight', or allbase
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
		melogit `var' i.`predictor' `confounders' `weight', ///
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
		melogit `var' i.`predictor' `confounders' `weight', or allbase
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
		melogit `var' i.`predictor' `weight' || `reequation', or allbase
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
		melogit `var' i.`predictor' `confounders' `weight' || `reequation', or allbase
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
		melogit `var' i.`predictor' `confounders' `weight' || `reequation', ///
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
		melogit `var' i.`predictor' `confounders' `confounders' `weight' || `reequation', or allbase
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
		melogit `var' i.`predictor' `weight', or allbase
		local i = `i' + 1
		collect remap colname[1.`predictor']=colname[1.`var'], ///
		fortags(cmdset[`i'])
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
		melogit `var' i.`predictor' `confounders' `weight', ///
		or allbase
		local i = `i' + 1
		collect remap colname[1.`predictor']=colname[1.`var'], ///
		fortags(cmdset[`i'])
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
		melogit `var' i.`predictor' `weight' || `reequation', or allbase
		local i = `i' + 1
		collect remap colname[1.`predictor']=colname[1.`var'], ///
		fortags(cmdset[`i'])
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
		melogit `var' i.`predictor' `confounders' `weight' || `reequation', ///
		or allbase
		local i = `i' + 1
		collect remap colname[1.`predictor']=colname[1.`var'], ///
		fortags(cmdset[`i'])
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
	qui collect composite define _r_combined = _r_lb _r_ub, ///
	delimiter(" to ") replace trim
		
	*Collect risk difference and probibility statistics
	qui collect composite define _r_logistic= _r_b , replace
		
	qui collect composite define _r_prob = _r_p, replace



	*****************************************
	** Formatting results for all logistic **
	*****************************************
	
	*Label and combine counts and frequencies
	qui collect label levels `predictor' ///
	0 "`a' [N = `A_N']" ///
	1 "`b' [N = `B_N']" ///
	, replace 
	
	qui collect label dim `predictor' "Treatment Arm"
 
 
	*Recode frequency and percent results
	qui collect recode result `"fvfrequency"' = `"1"' ///
	`"fvpercent"' = `"2"'

	
	*Relabel statistics
	qui collect label levels result 1 "N" 2 "(%)" ///
	_r_combined "95% CI" ///
	_r_prob "p-Value", modify

	
	*Format minimum p-value
	collect style cell result[_r_p], minimum(0.001)

	*Format decimal places
	qui collect style cell result[_r_combined], ///
	sformat("(%s)") nformat(`fci')
	
	qui collect style cell result[2 ], nformat(`fp')
	
	qui collect style cell result[_r_b], nformat(`flog')
	
	
	**********************
	** Formatting table **
	**********************
	
	*Hide base level of outcome variables
	qui foreach var of local outcomes {
	qui collect style header colname[0.`var'], ///
	level(hide) title(hide) 
	}
	
	qui collect style header `outcomes', level(hide) title(label)
	
	*Hide Tag Labels 
	qui collect style header vartype, title(hide)
	
	*Format horizontal alignment of headings
	qui collect style cell, halign(left)
	
	qui collect style cell colname#result[2], ///
	nformat(%5.1fc) sformat("(%s)") halign(left)
	
	qui collect style cell colname#result[1], halign(right)
	
	qui collect style cell result[_r_combined], halign(center)
	
	qui collect style cell result[1], halign(right)
	
	qui collect style cell result[2], halign(left)
	
	*Format vertical alignment 
	qui collect style cell, valign(center)
	
	*Hide Tag Lables 
	qui collect style header vartype, title(hide)
	
	*Widen margins
	qui collect style putdocx, ///
	cellmargin(bottom, 0.08) cellmargin(top, 0.03) ///
	layout(autofitcontents)
	
	*Change font size of notes
	collect style notes, font(calibri, size(10))
	
		************************************
		** Assembing Final Logistic Table **
		************************************
		qui foreach v of local outcomes {
		local k = `k' + 1
		if `k' == 1 {
				local finalrows "1.`v'"
					}
					else {
						local nextrow "1.`v'"
						local finalrows `finalrows' + `nextrow'
					}
			} 
			
			
		*COLLECT LAYOUT FOR 1 ROW TABLE 
		if `:word count `outcomes'' == 1 | ///
		`:word count `nosubheadings'' != 0 {
		qui collect layout (colname[`finalrows']) ///
		(`predictor'[0 1]#result[1 2] ///
		result[_r_logistic _r_combined _r_prob])
		
		}
			
		*COLLECT LAYOUT FOR MULTIPLE RDs
		else {
			
		*Add in Subheadings
		tokenize "`outcomes'"
		local first "`1'"
		macro shift
		local rest "`*'"
		
		qui collect addtags vartype["Primary Outcome"], ///
		fortags(colname[`first'])
		
		qui collect addtags vartype["Secondary Outcomes"], ///
		fortags(colname[`rest']) 
		
		*Bold Row Subheadings
		qui collect style cell vartype, font(Calibri, bold)
		qui collect style cell result, font(Calibri, nobold)
		qui collect style cell (colname[1.`outcomes']), ///
		font(Calibri, nobold)
		
		
		qui collect style row stack, spacer
		
		qui collect layout (vartype#colname[`finalrows']) ///
		(`predictor'[0 1]#result[1 2] ///
		result[_r_logistic _r_combined _r_prob])
		}
		
	
	
		
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
	collect export "`saving'/`exporttitle'", as(docx) `replace'	
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
		
	}
	
	end
	