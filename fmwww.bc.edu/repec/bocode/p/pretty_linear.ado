

capture program drop pretty_linear
	program define pretty_linear
	version 18.0
	syntax [if] [in] [fweight], ///
	DEPendent(varlist) ///
	INDependent(varname) ///
	[CONfounders(varlist fv ts)] ///
	[TITLE(string)] ///
	[SAVing(string)] ///
	[NOSUBheadings] ///
	[FLIN(string)] ///
	[FP(string)] ///
	[FCI(string)] ///
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
	if `:word count `flin'' == 0{
	 	local flin "%9.3fc"
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
		
	****************************************
	** Labelling independent if not labelled ** 
	****************************************
	
	foreach var of local independent {
		
		if "`: variable label `var''" == "" {
			
			la var `var' `var'
			
		} 
		
	}
	
	
**********************************
** SET LOOP FOR MULTIPLE TABLES **	
**********************************	
	
	qui foreach j of numlist 1/ `:word count `logtype'' {
	
	collect clear 
		
		
****************************
** Calculating Statistics **
****************************		


		*******************************
		** Linear with no confounder **
		*******************************
		if `:word count `confounders'' == 0 {		
		
		** Calculate linear coefficient
		qui foreach var of local independent {
		collect get _r_b _r_lb _r_ub: regress `var' `dependent' `weight'
		local i = `i' + 1
		}
		
		}

		
		
		*************************
		** Linear with confounders **
		*************************
		
		else if `:word count `confounders'' != 0 {
			
		** Calculate adjusted risk difference
		qui foreach var of local independent{
		collect get _r_b _r_lb _r_ub _r_p: regress `var' `dependent' `confounders' `weight'
		}
	
		** Add note for confounders
		fvrevar `confounders', list

		
		local basevar `r(varlist)'
		
		foreach var of local basevar{
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
		
		macro drop _z
		
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
		
		
*****************************************
** COLLECTING RESULTS FOR ALL LOGISTIC **
*****************************************

	*Combine upper and lower limits for 95% CI
	collect composite define _r_combined = _r_lb _r_ub, ///
	delimiter(" to ") replace trim
		
	*Collect risk difference and probibility statistics
	collect composite define _r_linear= _r_b , replace
		
	collect composite define _r_prob = _r_p, replace
	
	foreach var of local independent {
		
	local outcomecount = `outcomecount' + 1
	 
	}


	*****************************************
	** Formatting results for all logistic **
	*****************************************
	
	*Relabel statistics
	collect label levels result 1 "N" ///
	_r_combined "95% CI" ///
	_r_prob "p-Value", modify

	
	*Format minimum p-value
	collect style cell result[_r_p], minimum(0.001)

	*Format decimal places
	collect style cell result[_r_combined], ///
	sformat("(%s)") nformat(`fci')
	
	collect style cell result[_r_b], nformat(`flin')
	
	
	**********************
	** Formatting table **
	**********************
	
	** Hide tag headings of column headers
	collect style header extra[probability ci linear], ///
	level(hide) title(hide)
	
	
	** General alignment formatting
	collect style cell, halign(left)
	
	** Formatting % and N headers
	collect style cell colname#result[1], halign(right)

	collect label dim result "`: variable label `independent''", modify
	
	collect style header result[1], title(label)
	
	** Formatting Results alignment
	collect style cell result[1], halign(right)
	
	collect style cell result[_r_prob _r_linear _r_combined], halign(center)

	** Bold column headings
	collect style cell cell_type[column-header], font(, bold)
	
	*Format vertical alignment 
	collect style cell, valign(center)
	
	*Hide coefficient and p-value
	collect style header result[_r_b], title(hide)
	collect style header result[_r_p], title(hide)
	collect style header result[_r_combined], title(hide)
	
	
	collect style cell result[_r_prob _r_linear _r_combined]#cell_type[column-header], valign(bottom) 
	
	*Widen margins
	collect style putdocx, ///
	cellmargin(bottom, 0.08) cellmargin(top, 0.03) ///
	layout(autofitcontents)
	
	*Change font size of notes
	collect style notes, font(calibri, size(10))
	
	
		************************************
		** Assembing Final Logistic Table **
		************************************
		collect label dim result "`:var l `independent''"
	
		qui collect layout (colname[`dependent']) ///
		(result[_r_b _r_combined _r_prob])
			
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
	
	
	
	
	
	