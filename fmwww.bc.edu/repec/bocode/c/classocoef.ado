cap program drop classocoef
program define classocoef, rclass

	version 17.0
	
	syntax [anything] [if] [in] [, 	///
		Level(cilevel)				/// confidence level, default is controlled by "set level xxx"
		COLors(string)				/// color of each group, default is "maroon dkorange sand forest_green navy"
		COEFLWidth(string)			/// line width of group estimation coefficients; default is 1
		COEFLPattern(string)		/// line pattern of group estimation coefficients; default is solid
		CILWidth(string)			/// line width of the confidence interval of estimation coefficients; default is 0.5
		CILPattern(string)			/// line pattern of the confidence interval of estimation coefficients; default is dash
		TSMSize(string)				/// scatter size of time series estimation coefficients; default is 0.5
		ZEROLWidth(string)			/// line width of horizontal zero; default is 0.5
		ZEROLPattern(string)		/// line pattern of horizontal zero; default is solid
		ZEROLColor(string)			/// line color of horizontal; default is "black"
		NOCOEFplot					/// suppress the group estimation coefficients
		NOCIplot					/// suppress the confidence interval of estimation coefficients
		NOTSscatter					/// suppress the time series estimation coefficients
		NOZEROline					/// suppress the zero line
		TItle(string)				/// default is "Coefficient Plot of xxx"
		SUBtitle(string)			/// default is "Number of Individuals: N; Number of Groups: group"
		LEGend(string)				/// default is "off"
		YTItle(string)				/// defalut if "Coefficient of xxx"
		XTItle(string)				/// default is "Individual ID"
		YLabel(string)				/// default is ",nogrid"
		XLabel(string)				/// default is "1(step)N", where step = ceil(N/20)
		name(string)				/// default is "coefficient_varname"
		saving(string)				/// default is not save
		export(string)				/// default is not export
		NOWINdow					/// suppress the graph window
		COEFOPTions(string)			/// additional option for the line of group estimation coefficients
		CIOPTions(string)			/// additional option for the line of confidence interval of estimation coefficients
		TSOPTions(string)			/// additional option for the scatter of time series estimation coefficients
		ZEROOPTions(string)			/// additional option for the zero line
		TWOPTions(string)			/// additional option for the graph
		scheme(string)				/// graphics scheme to be used 
		*							///
	]								///

	tempname a a_temp std std_temp V_temp gid yrange tsbeta colorid step number tstrue
	loc group = e(group)
	loc N = e(N)
	// input data
	if ("`scheme'" == "") local scheme `c(scheme)'
	if ("`e(coef)'" == "postselection") {
		mat `a_temp' = e(a_post_G`group')
		mat `V_temp' = e(V_post_G`group')
	} 
	else {
		mat `a_temp' = e(a_classo_G`group')
		mat `V_temp' = e(V_classo_G`group')
	}
	mat `gid' = e(id)[....,"GID_G`group'"]
	// empty group
	mat define `number' = J(`group',1,0)
	forvalues i = 1/`N' {
		forvalues k = 1/`group' {
			if (e(id)[`i',"GID_G`group'"] == `k') {
				mat `number'[`k',1] = `number'[`k',1] + 1
			}
		}
	}
	loc empty = 0
	forvalues k = 1/`group' {
		if (`number'[`k',1] == 0) loc empty = `empty' + 1
	}
	if (`empty' > 0) loc group = `group' - `empty'
	if (`empty' == 1) di as text "Within `group' groups, there is " as result `empty' as text " empty group."
	else if (`empty' > 1) di as text "Within `group' groups, there are " as result `empty' as text " empty groups."
	// extract data
	loc indepvar: colname `a_temp'
	foreach v in `indepvar' {
		loc p = `p' + 1
	}
	mat define `std_temp' = J(`group',`p',0)
	forvalues k = 1/`group' {
		forvalues j = 1/`p' {
			mat `std_temp'[`k',`j'] = sqrt(`V_temp'[(`k'-1)*`p'+`j',`j'])
		}
	}
	mat colnames `std_temp' = `indepvar'
	mat `a' = J(`group',1,0)
	mat `std' = J(`group',1,0)
	mat `tsbeta' = e(id)[....,1], `gid'
	if ("`anything'" == "") loc anything `indepvar'
	foreach v in `anything' {
		mat `a' = `a', `a_temp'[1..`group',"`v'"]
		mat `std' = `std', `std_temp'[1..`group',"`v'"]
		mat `tsbeta' = `tsbeta', e(id)[....,"`v'"]
	}
	mat `a' = `a'[....,2...]
	mat `std' = `std'[....,2...]
	loc p = colsof(`a')
	
	// plot
	if ("`coeflwidth'" == "") loc coeflwidth = 1
	if ("`coeflpattern'" == "") loc coeflpattern solid
	if ("`cilwidth'" == "") loc cilwidth = 0.5
	if ("`cilpattern'" == "") 	loc cilpattern dash
	if ("`tsmsize'" == "") loc tsmsize = 0.5
	if ("`zerolwidth'" == "") loc zerolwidth = 0.5
	if ("`zerolpattern'" == "") loc zerolpattern solid
	if ("`zerolcolor'" == "") 	loc zerolcolor black
	if ("`colors'" == "") 		loc colors maroon dkorange sand forest_green navy
	tokenize `colors'
	loc i = 1
	while ("``i''" != "") {
		loc i = `i' + 1
	}
	loc numColor = `i' - 1
	mata: tsbeta = sort(st_matrix("`tsbeta'"),(2,1))
	mata: a = st_matrix("`a'")
	mata: std = st_matrix("`std'")
	mata: lower_bounds = a - invnormal(1-(1-`level'/100)/2) :* std
	mata: upper_bounds = a + invnormal(1-(1-`level'/100)/2) :* std
	mata: step = ceil(`N'/20)
	mata: st_numscalar("`step'", step)
	mata: number = number(st_matrix("`gid'"),`group',`N')
	loc stepp = `step'
	forvalues j = 1/`p' {
		mata: ts = tsbeta[.,`j'+2]
		mata: yrange = yrange(ts, lower_bounds, upper_bounds, `j')
		mata: st_matrix("`yrange'",yrange)
		if (0 >= `yrange'[1,1] & 0 <= `yrange'[2,1] & "`nozeroline'" == "") loc zeroline yline(0, lc(`zerolcolor') lw(`zerolwidth') `zerooptions') 
		mata: ts = tsinrange(ts, yrange, `N') // if the coefficient is out of range, then dont plot it!
		loc grcommand 
		tokenize `colors'
		forvalues k = 1/`group' {
			mata: ts`k' = tsgroup(ts, number, `k')
			mata: idx = tstrue(ts`k'); st_numscalar("`tstrue'", idx)
			mata: alpha`k' = alphagroup(a, number, `j', `k')
			mata: lower`k' = alphagroup(lower_bounds, number, `j', `k')
			mata: upper`k' = alphagroup(upper_bounds, number, `j', `k')
			mata: colorid = mod0(`k', `numColor'); st_numscalar("`colorid'", colorid)
			loc coloridd = `colorid'
			if ("`nocoefplot'" == "") loc coefplot line matamatrix(alpha`k'), lp(`coeflpattern') lwidth(`coeflwidth') lc(``coloridd'') `coefoptions' ||
			else loc coefplot
			if ("`nociplot'" == "") loc ciplot line matamatrix(lower`k'), lp(`cilpattern') lwidth(`cilwidth') lc(``coloridd'') || line matamatrix(upper`k'), lp(`cilpattern') lwidth(`cilwidth') lc(``coloridd'') `cioptions' || 
			else loc ciplot
			if ("`notsscatter'" == "" & `tstrue' == 1) loc tsscatter sc matamatrix(ts`k'), msymbol(circle) msize(`tsmsize') mc(``coloridd'') `tsoptions' ||  
			else loc tsscatter
			loc grcommand `grcommand' `coefplot' `ciplot' `tsscatter'
		}
		tokenize `anything'
		if ("`title'" == "") loc title_use Coefficient Plot of ``j''
		else loc title_use `title'
		if ("`subtitle'" == "") loc subtitle_use Number of Individuals: `N'; Number of Groups: `group'
		else loc subtitle_use `subtitle'
		if ("`name'" == "") loc name_use coefficient_``j''
		else loc name_use `name'
		if ("`legend'" == "") loc legend_use off
		else loc legend_use `legend'
		if ("`ytitle'" == "") loc ytitle_use Coefficient of ``j''
		else loc ytitle_use `ytitle'
		if ("`xtitle'" == "") loc xtitle_use Individual ID
		else loc xtitle_use `xtitle'
		if ("`ylabel'" == "") loc ylabel_use ,nogrid
		else loc ylabel_use `ylabel'
		if ("`xlabel'" == "") loc xlabel_use 1(`stepp')`N'
		else loc xlabel_use `xlabel'
		if ("`saving'" != "") loc save saving(`saving')
		cap graph drop `name_use'
		gr tw `grcommand' ,/*
		*/title(`title_use') /*
		*/subtitle(`subtitle_use')/*
		*/ytitle(`ytitle_use') xtitle(`xtitle_use') /*
		*/xlabel(`xlabel_use') ylabel(`ylabel_use') /*
		*/legend(`legend_use')/*
		*/name(`name_use') `save'/*
		*/`zeroline' `twoptions' scheme(`scheme')
		if ("`nowindow'" != "") graph close `name_use'
		if ("`export'" != "") graph export `export'
	}
end

mata: 
 mata clear
 real matrix tstrue(tspart) {
 	real scalar i, idx
	idx = 0
	for (i=1;i<=rows(tspart);i++) {
		if (tspart[i,1] != .) {
			idx = 1
			break
		}
	}

	return(idx)
 }
 real matrix number(gid, k, N) {
 	real matrix num 
	real scalar i
	real scalar kk
	
	num = J(k, 1, 0)
	for (i=1;i<=N;i++) {
		kk = 1
		while (kk < gid[i]) {
			kk = kk + 1
		}
		num[kk] = num[kk] + 1
	}
	
	return(num)
 }
 
 real matrix tsgroup(ts, number, k) {
 	real matrix tspart
	real scalar kk
	real scalar pre
	
	if (k == 1) {
		tspart = ts[1..number[1],1], range(1, number[1], 1)
	}
	if (k > 1) {
		pre = 0
		for (kk=1; kk<k; kk++) {
			pre = pre + number[kk]
		}
		tspart = ts[pre+1..pre+number[k],1], range(pre+1, pre+number[k], 1)
	}
	
	return(tspart)
 }
 
 real matrix alphagroup(input, number, j, k) {
 	real matrix output
	real scalar kk
	real scalar pre
	
	if (k == 1) {
		output = J(number[k], 1, input[k,j]), range(1, number[k], 1)
	}
	if (k > 1) {
		pre = 0
		for (kk=1; kk<k; kk++) {
			pre = pre + number[kk]
		}
		output = J(number[k], 1, input[k,j]), range(pre+1, pre+number[k], 1)
	}
	
	return(output)
 }
 
 real scalar mod0(k, num) {

	while (k > num) {
		k = k - num
	}

	return(k)
 }
 
 real matrix yrange(ts, lower_bounds, upper_bounds, j) {
 	real matrix yrange
	real matrix interval
	real matrix tempupper
	real matrix templower
	real scalar maxint
	real scalar maxupper
	real scalar minlower
	real scalar maxts
	real scalar mints
	
	yrange = J(2, 1, 0)
	tempupper = upper_bounds[.,j]
	templower = lower_bounds[.,j]
	interval = tempupper - templower
	maxint = max(interval)
	maxupper = max(tempupper)
	minlower = min(templower)
	maxts = max(ts)
	mints = min(ts)
	if (minlower <= mints) {
		yrange[1,1] = minlower
	}
	if (maxupper >= maxts) {
		yrange[2,1] = maxupper
	}
	if (minlower > mints) {
		if (mints >= minlower - 1.5 * maxint) {
			yrange[1,1] = mints
		}
		if (mints < minlower - 1.5 * maxint) {
			yrange[1,1] = minlower - 1.5 * maxint
		}
	}
	if (maxupper < maxts) {
		if (maxts <= maxupper + 1.5 * maxint) {
			yrange[2,1] = maxts
		}
		if (maxts > maxupper + 1.5 * maxint) {
			yrange[2,1] = maxupper + 1.5 * maxint
		}
	}
	
	return(yrange)
 }
 
 real matrix tsinrange(ts, yrange, N) {
 	real matrix tstemp
	real scalar i
	
	tstemp = J(N, 1, .)
	for (i=1; i<=N; i++) {
		if (ts[i,1] >= yrange[1,1] & ts[i,1] <= yrange[2,1]) {
			tstemp[i,1] = ts[i,1]
		}
	}	
	return(tstemp)
 }
end
