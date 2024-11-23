program define tvpreg_p, rclass

	version 17.0
	
	syntax newvarlist [if] [in] [,  ///
		xb 							/// linear predictions
		residual					/// residuals
		coef(string)				///
		coefub(string)				///
		coeflb(string)				///
		varirf(string)				///
		varirfub(string)			///
		varirflb(string)			///
		y(string)					/// name of dependent variables (or instrumented variables); default is the first dependent variable
		h(integer -1)				/// number of horizons; default is the smallest number in e(horizon)
		*							///
		]							///
	
	* Sample indicator
	tempvar touse
	qui gen `touse' = 1 if e(sample)
	qui replace `touse' = 0 if `touse' == .
	qui describe
	loc Tall = r(N)
	loc T = e(T)
	cap tsset
	loc timevar `r(timevar)'
	gsort -`touse' `timevar'

	* Variable name
	if ("`coef'" != "") {
		loc ematrix coef
		loc varname `coef'
	}
	else if ("`coefub'" != "") {
		loc ematrix coef_ub
		loc varname `coefub'
	}
	else if ("`coeflb'" != "") {
		loc ematrix coef_lb
		loc varname `coeflb'
	}
	else if ("`varirf'" != "") {
		loc ematrix varirf
		loc varname `varirf'
	}
	else if ("`varirfub'" != "") {
		oc ematrix varirf_ub
		loc varname `varirfub'
	}
	else if ("`varirflb'" != "") {
		loc ematrix varirf_lb
		loc varname `varirflb'
	}
	else if (("`residual'" != "") | ("`xb'" != "")) {
		loc ematrix residual
		if ("`y'" != "") loc varname `y'
		else loc varname = word("`e(depvar)'",1)
		
	}
	
	if (`h' == -1) {
		loc Nh = 1
		foreach hh in `e(horizon)' {
			if (`Nh' == 1) loc h = `hh'
			else if (`hh' < `h') loc h = `hh'
			loc Nh = `Nh' + 1
		}
	}
	if (`h' != 0) {
		foreach v in `varname' {
			loc rowname `rowname' h`h'.`v'
		}
	}
	else loc rowname `varname'
	
	* Construct variable
	loc n1 = wordcount("`rowname'")
	loc n2 = wordcount("`varlist'")
	if (`n1' != `n2') {
		di as err "Number of new varnames is inconsistent with number of inputs."
	}
	forvalues i = 1/`n1' {
		loc vv = word("`varname'", `i')
		loc v = word("`rowname'", `i')
		loc newv = word("`varlist'", `i')
		tempname varmat
		mat define `varmat' = e(`ematrix')["`v'",....]
		mata: varmat = (st_matrix("`varmat'"))'
		mata: newvar = J(`Tall',1,.)
		mata: newvar[1..`T'-`h'] = varmat[1..`T'-`h']
		cap drop `newv'
		qui getmata `newv' = newvar
		if ("`xb'" != "") {
			sort `timevar'
			if ("`e(model)'" != "var") {
				if (("`e(lplagged)'" == "yes") & regexm("`e(instd)'","`vv'")) {
					qui replace `newv' = `vv' - `newv'
				}
				else {
					if ("`e(cumulative)'" == "no") qui replace `newv' = F`h'.`vv' - `newv'
					else {
						qui replace `newv' =  - `newv'
						forvalues h = 0/`h' {
							qui replace `newv' = `newv' + F`h'.`vv'
						}
					}
				}
			}
			else qui replace `newv' = `vv' - `newv'
		}
	}
	sort `timevar'
	
end
