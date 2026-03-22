*! Program to compute Households' Employment Deprivation Index
*! Carlos Gradin
*! Version 2.0, March 2026 (original version 1.0, October 2014; version 1.1, November 2019)
*!
*! Based on: Gradin, C., Canto, O., and Del Rio, C. (2017), "Measuring employment
*!   deprivation in the EU using a household-level index",
*!   Review of Economics of the Household, 15(2): 639-667.

program define unemp, rclass byable(recall) sortpreserve
	version 10
	syntax varname [aweight iweight fweight] [if] [in], ///
		hid(varname) ///
		[HSize(varname) THao(real 0) Format(string) ///
		Gamma(string) Alpha(string) GENerate(string) DEComp]

	marksample touse

	// ================================================================
	// Validate inputs
	// ================================================================

	if `thao' < 0 | `thao' > 1 {
		di as error "Error: threshold thao() must be between 0 and 1"
		error 198
	}

	tempname gap
	qui: gen `gap' = `1' if `touse'

	// Check that gap variable is in [0, 1] range
	qui: sum `gap' if `touse'
	if r(min) < 0 | r(max) > 1 {
		di as error "Error: `1' must be between 0 and 1 (individual employment gap)"
		error 198
	}

	// Default parameter values
	if "`gamma'" == "" {
		local gamma 0 1 2
	}
	if "`alpha'" == "" {
		local alpha 0 1 2
	}

	// If decomposition requested, ensure alpha=0 is included
	local k = 100
	foreach j in `alpha' {
		if `j' < `k' {
			local k = `j'
		}
	}
	if "`decomp'" ~= "" & `k' > 0 {
		local alpha 0 `alpha'
		di ""
		di as text "Note: with decomposition, alpha=0 (headcount) is also reported"
	}

	// ================================================================
	// Step 1: Household employment deprivation indices u_i(gamma)
	// ================================================================
	// Paper Eq. 2: u_i = (1/H_i) * sum_j g^gamma_ij
	// where g^gamma_ij is the individual gap raised to the power gamma

	tempname indw

	// indw = 1 for each active individual (unit weight within household)
	gen `indw' = 1

	// g^gamma: individual gaps raised to power gamma
	tempname g_0 g_1

	// gamma = 1: the raw gap (proportion of hours gap)
	qui: gen `g_1' = `gap' if `touse'

	// gamma = 0: indicator of individual deprivation (1 if gap > 0)
	qui: gen `g_0' = 0 if `touse'
	qui: replace `g_0' = 1 if `g_1' > 0 & `touse'

	// gamma >= 2: gap raised to power gamma
	foreach i in `gamma' {
		if `i' >= 2 {
			tempname g_`i'
			qui: gen `g_`i'' = `g_1'^`i' if `touse'
		}
	}

	// u_i(gamma) = (1/H_i) * sum_j g^gamma_ij for each household
	foreach i in `gamma' {
		tempname pi_`i' indw_`i'
		qui: bysort `hid': egen `pi_`i''   = sum(`g_`i'' * `indw') if `touse'
		qui: bysort `hid': egen `indw_`i'' = sum(`indw')           if `touse'
		qui: bysort `hid': replace `pi_`i'' = `pi_`i'' / `indw_`i'' if `touse'
	}

	// Ensure u_i(gamma=1) exists (needed for threshold censoring)
	if "`pi_1'" == "" {
		tempname pi_1 indw_1
		qui: bysort `hid': egen `pi_1'   = sum(`g_1' * `indw') if `touse'
		qui: bysort `hid': egen `indw_1' = sum(`indw')          if `touse'
		qui: bysort `hid': replace `pi_1' = `pi_1' / `indw_1'   if `touse'
	}

	// Threshold censoring: household is deprived only if u_i(gamma=1) > thao
	// (Paper: threshold s, with u_i = 0 if u_i(g^1, s) <= s for s < 1,
	//  or u_i = 0 if u_i(g^1, s) < 1 for s = 1)
	tempname hhrate
	qui: gen `hhrate' = `pi_1' if `touse'

	foreach i in `gamma' {
		qui: bysort `hid': replace `pi_`i'' = 0 if `hhrate' <= `thao' & `touse' & `thao' < 1
		qui: bysort `hid': replace `pi_`i'' = 0 if `hhrate' <  `thao' & `touse' & `thao' == 1
	}

	// ================================================================
	// Step 2: Aggregate index U(gamma, alpha) = mean(u_i^alpha)
	// ================================================================
	// Paper Eq. 3: U_alpha = (1/N) * sum_i u_i^alpha

	// Compute u_i(gamma)^alpha for each combination
	foreach i in `gamma' {
		foreach j in `alpha' {
			tempname pi_`i'_`j'
			qui: gen `pi_`i'_`j'' = 0 if `touse'
			qui: replace `pi_`i'_`j'' = `pi_`i''^`j' if `pi_`i'' > 0 & `touse'
		}
	}

	// If hsize specified: weight households by hsize instead of active members
	if "`hsize'" ~= "" {
		qui: bysort `hid': replace `touse' = 0 if _n > 1
		local exp "`exp'*`hsize'"
	}

	// Compute weighted mean of u_i^alpha = U(gamma, alpha)
	tempname _alpha _gamma P
	qui: gen `P'      = .
	qui: gen `_alpha'  = .
	qui: gen `_gamma'  = .

	local k = 1
	foreach i in `gamma' {
		foreach j in `alpha' {
			qui: sum `pi_`i'_`j'' [`weight' `exp'] if `touse'
			qui: replace `P'       = r(mean) if _n == `k'
			qui: replace `_gamma'  = `i'     if _n == `k'
			qui: replace `_alpha'  = `j'     if _n == `k'
			local k = `k' + 1
		}
	}

	// ================================================================
	// Step 3: Decomposition (if requested)
	// ================================================================
	// Paper: U_alpha = H * I^alpha * (1 + Ep)
	//   H  = headcount ratio (proportion of deprived households)
	//   I  = intensity (mean deprivation among deprived)
	//   Ep = inequality of deprivation among deprived (alpha > 1)
	//
	// For alpha = 2, alternative decomposition:
	//   U_2 = H * [I^2 + V(u)]
	//   where V(u) = Var(u among deprived), CV2(1-u) = V(u) / (1-I)^2

	if "`decomp'" ~= "" {

		tempname H I V CV2 Ep xx yy

		// H = U(gamma, alpha=0) = headcount ratio
		qui: gen `H'   = `P'[1]

		qui: gen `I'   = .
		qui: gen `V'   = .
		qui: gen `CV2' = .
		qui: gen `Ep'  = .
		qui: gen `xx'  = .
		qui: gen `yy'  = .

		local k = 1
		foreach i in `gamma' {
			foreach j in `alpha' {

				// I = mean deprivation among deprived households
				qui: sum `pi_`i'' [`weight' `exp'] if `touse' & `pi_`i'' > 0
				qui: replace `I' = r(mean) if _n == `k'

				// For alpha=2: variance-based decomposition
				if `j' == 2 {
					qui: replace `V'   = r(Var)              if _n == `k'
					qui: replace `CV2' = `V' / (1 - `I')^2   if _n == `k'
					// Verification: U_2 = H * [I^2 + V(u)]
					qui: replace `yy'  = `H' * (`I'^2 + `V') if _n == `k'
				}

				// Ep = inequality among deprived
				// Ep = mean[(u_i/I)^alpha - 1] among deprived
				tempname ppi_`i'_`j'
				qui: gen `ppi_`i'_`j'' = (`pi_`i'' / r(mean))^`j' - 1 if `touse'
				qui: sum `ppi_`i'_`j'' [`weight' `exp'] if `touse' & `pi_`i'_`j'' > 0
				qui: replace `Ep' = r(mean) if _n == `k'
				qui: replace `Ep' = 0       if `Ep' < 0
				// Note: Ep may be slightly negative due to numerical precision;
				// set to 0 in that case

				// Verification: U_alpha = H * I^alpha * (1 + Ep)
				qui: replace `xx' = `H' * (`I'^`j') * (1 + `Ep') if _n == `k'

				local k = `k' + 1
			}
		}
	}

	// ================================================================
	// Step 4: Save generated variables (if requested)
	// ================================================================

	if "`generate'" ~= "" {
		cap drop `generate'_*
		foreach i in `gamma' {
			qui: gen `generate'_`i' = `pi_`i'' if `touse'
			lab var `generate'_`i' "Household employment deprivation index, gamma=`i'"
		}
	}

	// ================================================================
	// Step 5: Display results
	// ================================================================

	lab var `_alpha' "alpha"
	lab var `_gamma' "gamma"

	lab def `_alpha' -1 ""
	lab def `_gamma' -1 ""

	lab var `P' "Household employment deprivation, U()"

	cap lab var `H'   "H"
	cap lab var `CV2' "CV2(1-u)"
	cap lab var `I'   "I"
	cap lab var `V'   "V(u)"
	cap lab var `Ep'  "Ep(u)"

	foreach j in `alpha' {
		lab def `_alpha' `j' "`j'", add
	}
	foreach i in `gamma' {
		lab def `_gamma' `i' "`i'", add
	}

	lab val `_alpha' `_alpha'
	lab val `_gamma' `_gamma'

	if "`format'" == "" {
		loc format "%9.4f"
	}

	di ""
	di as text "{hline 100}"
	di ""
	di as result "Household Employment Deprivation Index"
	di ""
	di as text "Based on Gradin, C., Canto, O., and Del Rio, C. (2017),"
	di as text "Review of Economics of the Household, 15(2): 639-667."
	di ""

	di as text "Individual employment gaps: " as result "`1'"
	di as text "{col 5}(only observations with nonmissing values used)"
	di ""

	qui count if `touse'
	di as text "N observations = " as result r(N)
	return scalar N = r(N)
	di ""

	di as text "Threshold = " as result `thao'
	if `thao' == 0 {
		di as text "{col 5}(all households with u(gamma=1) > 0 are deprived)"
	}
	else if `thao' > 0 & `thao' < 1 {
		di as text "{col 5}(only households with u(gamma=1) > " ///
			as result `thao' as text " are deprived)"
	}
	else if `thao' == 1 {
		di as text "{col 5}(only households with u(gamma=1) = 1 are deprived)"
	}

	di ""
	if "`hsize'" ~= "" {
		di as text "Aggregate index U(.) — households weighted by " as result "`hsize'"
	}
	else {
		di as text "Aggregate index U(.) — households weighted by number of active members"
	}

	tabdisp `_alpha' `_gamma' if `P' ~= ., c(`P') f(`format') ///
		concise stubwidth(10) csepwidth(1)

	di ""
	di as text "Parameters:"
	di as text " - gamma: sensitivity to variability of employment gaps within household"
	di as text " - alpha: sensitivity to inequality of deprivation among deprived households"

	if "`decomp'" ~= "" {
		di ""
		di as result "Decomposition: U_alpha = H * I^alpha * (1 + Ep)"
		tabdisp `_alpha' `_gamma' if `P' ~= ., c(`H' `I' `Ep') f(`format') ///
			concise stubwidth(10) csepwidth(1)

		di as text "H = headcount ratio; I = intensity; Ep = inequality among deprived (alpha>1)"
	}

	di ""

	qui: sum `_alpha'
	if "`decomp'" ~= "" & r(max) >= 2 {
		di ""
		di as result "For alpha=2: U_2 = H * [I^2 + V(u)], where V(u) = CV2(1-u) * (1-I)^2"
		di ""
		tabdisp `_gamma' if `P' ~= . & `_alpha' == 2, ///
			c(`H' `I' `CV2' `V') f(`format') concise stubwidth(10) csepwidth(1)

		di as text "(1) H = headcount ratio       (3) CV2(1-u) = squared coef. of variation of 1-u"
		di as text "(2) I = intensity              (4) V(u) = variance of u among deprived"
	}

	// ================================================================
	// Step 6: Return results
	// ================================================================

	local k = 1
	foreach i in `gamma' {
		foreach j in `alpha' {
			tempname U_`i'_`j'
			scalar `U_`i'_`j'' = `P'[`k']
			ret scalar U_`i'_`j' = `U_`i'_`j''
			local k = `k' + 1
		}
	}

	tempname pov dec dec2
	cap mkmat `_gamma' `_alpha' `P' if `P' ~= ., mat(`pov')
	cap mat colnames `pov' = gamma alpha U

	if "`decomp'" ~= "" {
		mkmat `H' `I' `Ep' if `P' ~= ., mat(`dec')
		mat colnames `dec' = H I Ep
		mat `pov' = `pov', `dec'

		cap mkmat `_gamma' `_alpha' `P' `H' `I' `CV2' `V' ///
			if `P' ~= . & `_alpha' == 2, mat(`dec2')
		cap mat colnames `dec2' = gamma alpha U H I CV2 V
		cap return matrix dec2 = `dec2'
	}
	return matrix unemp = `pov'

	di as text "{hline 100}"

end
