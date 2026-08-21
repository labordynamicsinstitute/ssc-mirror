*! 1.0.0 Ariel Linden 15Aug2026

program define varatio, rclass
	version 11.0

	syntax varname [pweight aweight iweight] [if] [in], ///
		BY(varname)

	tempvar touse
	marksample touse, novarlist
	markout `touse' `varlist'

	// handle the by() variable separately to avoid markout issues with strings
	qui replace `touse' = 0 if missing(`by')

	local depvar `varlist'
	local origby "`by'"

	// weights
	tempvar w
	local hasweight = ("`weight'" != "")
	if `hasweight' {
		local wexp = trim(`"`exp'"')
		if substr(`"`wexp'"', 1, 1) == "=" {
			local wexp = trim(substr(`"`wexp'"', 2, .))
		}
		quietly gen double `w' = `wexp' if `touse'
		quietly replace `touse' = 0 if `touse' & (`w' <= 0 | missing(`w'))
	}
	else {
		quietly gen double `w' = 1 if `touse'
	}

	// check if there are any observations in the sample
	qui count if `touse'
	if r(N) == 0 {
		di as error "no observations in the sample"
		exit 2000
	}

	// get distinct values of by() variable
	qui levelsof `by' if `touse', local(by_vals)
	local num_groups : word count `by_vals'

	if `num_groups' < 2 {
		di as error "{bf:by()} variable must have at least 2 distinct values"
		exit 420
	}

	// build numeric group codes (recoding string by() to 1..k), and labels
	capture confirm numeric variable `by'
	local needrecode = _rc != 0

	tempvar numby
	if `needrecode' {
		qui gen `numby' = .
	}

	local i = 0
	foreach lv of local by_vals {
		local ++i
		if `needrecode' {
			qui replace `numby' = `i' if `origby' == "`lv'" & `touse'
			local grouplabel`i' "`lv'"
			local grpval`i' "`i'"
		}
		else {
			capture local lbl : label (`by') `lv'
			if "`lbl'" == "" local lbl "`lv'"
			local grouplabel`i' "`lbl'"
			local grpval`i' "`lv'"
		}
	}
	if `needrecode' local by "`numby'"

	// per-group N, weighted mean, direct weighted variance
	tempvar w2 sqdev
	quietly gen double `w2' = `w'^2
	quietly gen double `sqdev' = .

	if `hasweight' {
		local wtclause "[`weight'=`w']"
	}
	else {
		local wtclause ""
	}

	local N = 0
	forvalues j = 1/`num_groups' {
		qui count if `by' == `grpval`j'' & `touse'
		local n`j' = r(N)
		local N = `N' + `n`j''

		quietly mean `depvar' `wtclause' if `by' == `grpval`j'' & `touse'
		local mean`j' = _b[`depvar']

		qui summarize `w' if `by' == `grpval`j'' & `touse', meanonly
		local sumw`j' = r(sum)
		qui summarize `w2' if `by' == `grpval`j'' & `touse', meanonly
		local sumw2`j' = r(sum)
		local ess`j' = (`sumw`j''^2) / `sumw2`j''

		quietly replace `sqdev' = `w' * (`depvar' - `mean`j'')^2 ///
			if `by' == `grpval`j'' & `touse'
		qui summarize `sqdev' if `by' == `grpval`j'' & `touse', meanonly
		local var`j' = r(sum) / `sumw`j''
		local logvar`j' = ln(`var`j'')
	}

	// omnibus group weights w_j = n_j/N, weighted mean log-variance
	local lbar = 0
	forvalues j = 1/`num_groups' {
		local wj`j' = `n`j''/`N'
		local lbar = `lbar' + `wj`j'' * `logvar`j''
	}
	forvalues j = 1/`num_groups' {
		local dev`j' = `logvar`j'' - `lbar'
	}

	// F_VR: size-weighted quadratic (RMS) combination
	local FVR2 = 0
	forvalues j = 1/`num_groups' {
		local FVR2 = `FVR2' + `wj`j'' * (`logvar`j'' - `lbar')^2
	}
	local FVR = sqrt(`FVR2')

	// pairwise log-differences, VR*, GMVR, max(VR*)
	local npairs = `num_groups' * (`num_groups' - 1) / 2
	local pr = 0
	local sumlogvr = 0
	local maxvr = .
	forvalues a = 1/`=`num_groups'-1' {
		forvalues b = `=`a'+1'/`num_groups' {
			local ++pr
			local absdiff`pr' = abs(`logvar`a'' - `logvar`b'')
			local vrstar`pr' = exp(`absdiff`pr'')
			local rn`pr' "`grouplabel`a'' vs `grouplabel`b''"
			local sumlogvr = `sumlogvr' + `absdiff`pr''
			if `vrstar`pr'' > `maxvr' | `maxvr' == . {
				local maxvr = `vrstar`pr''
			}
		}
	}
	local GMVR = exp(`sumlogvr' / `npairs')

	// display
	if `hasweight' == 0 {
		di _newline as text "K-group variance-ratio balance diagnostics"
		di "{hline 65}"
	}
	else {
		di _newline as text "{bf:Weighted} k-group variance-ratio balance diagnostics"
		di "{hline 65}"
	}
	di as txt "Groups:  `origby'"
	forvalues j = 1/`num_groups' {
		di as txt "  `j'. `grouplabel`j''" _col(35) "N = " as res %6.0fc `n`j''
	}
	di "{hline 65}"
	di as txt %-34s "F_VR (omnibus, quadratic):" as res %6.4f `FVR'
	di as txt %-34s "GMVR (geometric mean):" as res %6.4f `GMVR'
	di as txt %-34s "Max VR* (Lopez-Gutman-style):" as res %6.4f `maxvr'
	
	di "{hline 65}"

	di as txt _n "Per-group variance"
	di "{hline 65}"
	di as txt %-20s "Group" "  Variance    log(Variance)   log(Var) - lbar"
	di "{hline 65}"
	forvalues j = 1/`num_groups' {
		di as txt %-20s "`grouplabel`j''" as res ///
			%10.4f `var`j'' "   " %10.4f `logvar`j'' "        " %8.4f `dev`j''
	}
	di "{hline 65}"

	di as txt _n "Pairwise comparisons (" as res `npairs' as txt " pairs)"
	di "{hline 55}"
	di as txt %-25s "Groups" "     VR*    log(VR*)"
	di "{hline 55}"
	forvalues pr = 1/`npairs' {
		di as txt %-25s "`rn`pr''" as res %9.4f `vrstar`pr'' "  " %9.4f `absdiff`pr''
	}
	di "{hline 55}"
	di as txt "For GMVR and max(VR*): > 0.50 and < 2.0 - groups are well balanced"
	di as txt "For F_VR: < 0.10 - groups are well balanced"
	di as txt "          > 0.30 - groups are imbalanced"
	di as txt "          >= 0.10 and <= 0.30 - balance is uncertain (inspect the per-group and pairwise results)"
	
	// return values
	return scalar F_VR = `FVR'
	return scalar GMVR = `GMVR'
	return scalar maxVR = `maxvr'
	return scalar N = `N'
	return scalar k = `num_groups'
	return scalar npairs = `npairs'
	return local by = "`origby'"

	// per-group variance, log-variance, and deviation from the weighted mean log-variance 
	tempname pergroup
	matrix `pergroup' = J(`num_groups', 3, .)
	local grouprows ""
	forvalues j = 1/`num_groups' {
		matrix `pergroup'[`j',1] = `var`j''
		matrix `pergroup'[`j',2] = `logvar`j''
		matrix `pergroup'[`j',3] = `dev`j''
		local grouprows `"`grouprows' "`grouplabel`j''""'
	}
	matrix colnames `pergroup' = Variance LogVariance Deviation
	matrix rownames `pergroup' = `grouprows'
	return matrix pergroup = `pergroup'

	// pairwise VR* and log(VR*)
	tempname pairwise
	matrix `pairwise' = J(`npairs', 2, .)
	local pairrows ""
	forvalues pr = 1/`npairs' {
		matrix `pairwise'[`pr',1] = `vrstar`pr''
		matrix `pairwise'[`pr',2] = `absdiff`pr''
		local pairrows `"`pairrows' "`rn`pr''""'
	}
	matrix colnames `pairwise' = VRstar LogVRstar
	matrix rownames `pairwise' = `pairrows'
	return matrix pairwise = `pairwise'

	// clean up temporary variable if created
	if `needrecode' {
		capture drop `numby'
	}
end
