cap program drop classogroup
program define classogroup, rclass

	version 17.0
	
	syntax [if] [in] [,  ///
		NOICplot					/// suppress the ic plot
		NOITERplot					/// suppress the iteration plot
		ICLPattern(string)			/// default is solid
		ICLWidth(string)			/// default is 0.5
		ICLColor(string)			/// default is black
		ICMSize(string)				/// default is 2
		ICMColor(string)			/// default is black
		ICLEGend(string)			/// default is "Information Criterion"
		ICConnect(string)			/// default is direct
		ITERLPattern(string)		/// default is dash
		ITERLWidth(string)			/// default is 0.5
		ITERLColor(string)			/// default is blue
		ITERMSize(string)			/// default is 2
		ITERMColor(string)			/// default is blue
		ITERLEGend(string)			/// default is "Number of Iterations"
		ITERConnect(string)			/// default is direct
		TItle(string)				/// default is "Detail of Group Number Selection"
		SUBtitle(string)			/// default is "Maximum Number of Groups: `maxgroup'; Chosen Number of Groups: `group'"
		XTitle(string)				/// default is "Number of Groups"
		ylabel1(string)				/// default is nothing
		ylabel2(string)				/// default is 0(5)maxIter
		ytitle1(string)				/// default is "IC"
		ytitle2(string)				/// default is "Number of Iterations"
		XLabel(string)				/// default is "1(1)`maxgroup'"
		name(string)				/// default is "selection"
		saving(string)				/// defalut is not save
		export(string)				/// default is not export
		NOWINdow					/// suppress the graph window
		ICOPTion(string)			/// additional option for the ic plot
		ITEROPTion(string)			/// additional option for the iteration plot
		TWOPTions(string)			/// additional option for the graph
		scheme(string)				/// graphics scheme to be used 
		*							///
	]								///
	
	tempname groupNum IC iter ICbest
	loc maxgroup = rowsof(e(selection))
	loc maxit =  e(selection)[1,5]
	loc group = e(group)
	if ("`title'" == "") loc title Detail of Group Number Selection
	if ("`subtitle'" == "") loc subtitle Maximum Number of Groups: `maxgroup'; Chosen Number of Groups: `group'
	if ("`ytitle1'" == "") loc ytitle1 Information Criterion
	if ("`ytitle2'" == "") loc ytitle2 Number of Iterations
	if ("`ylabel1'" != "") loc ylabel1 ylabel(`ylabel1', axis(1))
	if ("`ylabel2'" == "") loc ylabel2 0(5)`maxit'
	if ("`xtitle'" == "") loc xtitle Number of Groups
	if ("`xlabel'" == "") loc xlabel 1(1)`maxgroup'
	if ("`name'" == "") loc name selection
	if ("`scheme'" == "") local scheme `c(scheme)'
	cap gr drop `name'
	mat define `groupNum' = e(selection)[....,"groupNum"]
	foreach v in IC iter {
		mat define ``v'' = e(selection)[....,"`v'"]
		mata: `v' = st_matrix("``v''"), st_matrix("`groupNum'")
	}
	loc grcommand
	if ("`iclpattern'" == "") loc iclpattern solid
	if ("`iclwidth'" == "") loc iclwidth = 0.5
	if ("`iclcolor'" == "") loc iclcolor black
	if ("`icmsize'" == "") loc icmsize = 2
	loc icmsize2 = 1.5 * `icmsize'
	if ("`icmcolor'" == "") loc icmcolor black
	if ("`iclegend'" == "") loc iclegend Information Criterion
	if ("`icconnect'" == "") loc icconnect direct
	if ("`iterlpattern'" == "") loc iterlpattern dash
	if ("`iterlwidth'" == "") loc iterlwidth = 0.5
	if ("`iterlcolor'" == "") loc iterlcolor blue
	if ("`itermsize'" == "") loc itermsize = 2
	if ("`itermcolor'" == "") loc itermcolor blue
	if ("`iterlegend'" == "") loc iterlegend Number of Iterations
	if ("`iterconnect'" == "") loc iterconnect direct
	loc numK = rowsof(e(selection))
	forvalues k = 1/`numK' {
		if (e(selection)[`k',1]==e(group)) mat define `ICbest' = e(selection)[`k',"IC"], e(selection)[`k',1]
	}
	mata: ICbest = st_matrix("`ICbest'")
	if ("`noicplot'" == "") loc icplot sc matamatrix(IC), msize(`icmsize') mc(`icmcolor') connect(`icconnect') lp(`iclpattern') lwid(`iclwidth') lc(`iclcolor') `icoption' yaxis(1) ytitle(`ytitle1', axis(1)) `ylabel1' || 
	if ("`noicplot'" == "") loc icbest sc matamatrix(ICbest), msize(`icmsize2') mc(`icmcolor') yaxis(1) msymbol("triangle") ||
	if ("`noiterplot'" == "") loc iterplot sc matamatrix(iter), msize(`itermsize') mc(`itermcolor') connect(`iterconnect') lp(`iterlpattern') lwid(`iterlwidth') lc(`iterlcolor') `iteroption' yaxis(2) ytitle(`ytitle2', axis(2)) ylabel(`ylabel2', axis(2)) || 
	if ("`noicplot'" == "" & "`noiterplot'" == "") loc legend legend(order(1 "`iclegend'" 3 "`iterlegend'"))
	else loc legend legend(off)
	if ("`saving'" != "") loc save saving(`saving')
	gr tw `icplot' `icbest' `iterplot', /*
		*/xtitle(`xtitle') xlabel(`xlabel')/*
		*/title(`title') /*
		*/subtitle(`subtitle') /*
		*/name(`name') `save' `legend' `twoptions' scheme(`scheme')
	if ("`nowindow'" != "") graph close `name'
	if ("`export'" != "") graph export `export'
end
