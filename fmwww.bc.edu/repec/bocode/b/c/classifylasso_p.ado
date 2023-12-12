cap program drop classifylasso_p
program define classifylasso_p, rclass sortpreserve

	version 17.0
	
	syntax newvarname [if] [in] [,  ///
		gid 						/// group memberships; the default
		xb 							/// linear predictions
		xbd							/// linear predictions + fixed effects
		d							/// fixed effects
		Residuals					/// residuals
		Stdp						/// standard error of the prediction (of the xb component)
		*							///
		]							///

	tempname b V a
	loc group = e(group)
	tempfile ereturnlist
	qui estimates save `ereturnlist'
	tempvar touse
	qui gen `touse' = 1 if e(sample)
	qui replace `touse' = 0 if `touse' == .
	
	// Ensure there is only one option
	opts_exclusive "`gid' `xb' `xbd' `d' `residuals' `stdp'"

	// Default option is gid
	if ("`gid'" == "" & "`xb'" == "" & "`xbd'" == "" & "`d'" == "" & "`residuals'" == "" & "`stdp'" == "") {
		di as text "(option gid assumed; group memberships)"
		loc gid "gid"
	}
	if ("`e(coef)'" == "postselection") {
		mat `a' = e(a_post_G`group')
		mat `V' = e(V_post_G`group')
		loc esttype Post_Lasso
	}
	else {
		mat `a' = e(a_classo_G`group') 
		mat `V' = e(V_classo_G`group') 
		loc esttype C_Lasso
	}
	loc p = colsof(`a')
	local indepvar: colname `a'
	loc varlists `e(depvar)' `e(indepvar)'
	// Generate ID 
	tempvar tmpgid
	if ("`group'" == "1") qui gen `tmpgid' = 1 `if' `in'
	else {
		qui gen `tmpgid' = 0 `if' `in'
		if ("`e(absvar)'" != "_cons") loc varnames `e(indepvar)' `e(depvar)' `e(absvar)'
		else loc varnames `e(indepvar)' `e(depvar)'
		foreach v in `varnames' {
			qui replace `tmpgid' = . if `v' == .
		}
		loc N = e(N)
		forvalues i	= 1/`N' {
			qui replace `tmpgid' = e(id)[`i',"GID_G`group'"] if `e(panelvar)' == e(id)[`i',1] & `tmpgid' != .
		}
		qui levelsof `e(panelvar)' if `tmpgid' == 0, local(levels)
		tempname ssr
		foreach i in `levels' {
			mat `ssr' = J(`group',1,0)
			forvalues k = 1/`group' {
				mkmat `e(depvar)' if `e(panelvar)' == `i', matrix(y)
				mkmat `e(indepvar)' if `e(panelvar)' == `i', matrix(x)
				mat x = x, J(rowsof(x),1,1)
				mat `b' = `a'[`k',1..`p']
				mat `ssr'[`k',1] = (y - x * `b'')' * (y - x * `b'')
			}
			loc thisk = 1
			forvalues k = 2/`group' {
				loc kminus1 = `k' - 1
				loc ssrnow = `ssr'[`k',1]
				loc ssrminus1 = `ssr'[`kminus1',1]
				if (`ssrnow' < `ssrminus1') loc thisk `k'
			}
			qui replace `tmpgid' = `thisk' if `e(panelvar)' == `i'
		}
	}

	// New Variables
	if ("`gid'" != "") {
		qui gen `varlist' = `tmpgid'
		cap label drop group_classo
		loc label_group label define group_classo
		forvalues k = 1/`group' {
			loc label_group `label_group' `k' "G`k'"
		}
		`label_group'
		label values `varlist' group_classo
		label var `varlist' "Group Classification by `esttype'"
	}
	else if ("`stdp'" == "") {
		// Fixed effects
		tempvar fakey
		qui gen `fakey' = 0 `if' `in'
		forvalues k = 1/`group' {
			mat `b' = `a'[`k',1..`p']
			mat score `fakey' = `b' if `tmpgid' == `k', replace
		}
		
		// Linear prediction / Residual
		if ("`xb'" != "") {
			qui gen `varlist' = `fakey'
			label var `varlist' "Fitted Value by `esttype'"
		}
		else {
			tempname tempu u
			gen `u' = 0 `if' `in'
			if ("`e(absvar)'" != "_cons") loc fe absorb(`e(absvar)')
			else loc fe noabsorb
			forvalues k = 1/`group' {
				cap drop `tempu'
				qui reghdfe `varlists' if `tmpgid' == `k', `fe' residuals(`tempu')
				qui replace `u' = `tempu' if `tmpgid' == `k'
			}
			if ("`xbd'" != "") {
				qui gen `varlist' = `e(depvar)' - `u'
				label var `varlist' "Fitted Value by `esttype'"
			}
			else if ("`d'" != "") {
				qui gen `varlist' = `e(depvar)' - `u' - `fakey'
				label var `varlist' "Fitted Value by `esttype'"
			}
			else if ("`residuals'" != "") {
				qui gen `varlist' = `u'
				label var `varlist' "Residual by `esttype'"
			}
		}
	}
	else {
		// standard error of prediction
		qui sort `tmpgid' `e(panelvar)' `e(timevar)'
		tempname var
		forvalues k = 1/`group' {
			tempname X`k'
			mat `V'`k' = `V'[(`k'-1)*`p'+1..`k'*`p',1..`p']
			mkmat `e(indepvar)' if `tmpgid' == `k', matrix(`X`k'')
			mat `X`k'' = `X`k'', J(rowsof(`X`k''),1,1)
			if (`k' == 1) mat `var' = vecdiag(`X`k'' * `V'`k' * `X`k''')'
			else mat `var' = `var' \ vecdiag(`X`k'' * `V'`k' * `X`k''')'
		}
		tempvar v
		svmat `var', name(`v')
		qui gen `varlist' = sqrt(`v')
		label var `varlist' "Standard Error of Fitterd Value by `esttype'"
	}
	
	estimates use `ereturnlist'
	estimates esample: if `touse' == 1
end
