*! 2.0 Ariel Linden 27May2026	// extended to nominal treatments
*! 1.0 Ariel Linden 14Dec2016

program drmmws_bs, rclass

version 13

	syntax varlist [if] [in] [,			///
			Ovars(string)				///
			Pvars(string)				///
			NSTRata(string)				///
			COMMon						///
			ATT							///
			Family(string)				///
			Link(string)				///
			MEDian						///
			NOMinal						///
			CONTrol(string)				///
			SEED(string)				///
			REPS(string)]

	quietly {

		tokenize `varlist'
		local outcome `1'
		macro shift
		local treat `1'
		macro shift
		local preds `*'

		marksample touse
		count if `touse'
		if r(N) == 0 error 2000
		local N = r(N)
		replace `touse' = -`touse'

		if "`ovars'"   == "" local ovars   `preds'
		if "`pvars'"   == "" local pvars   `preds'
		if "`family'"  == "" local family  gaussian
		if "`link'"    == "" local link    identity

		// binary treatment //
		if "`nominal'" == "" {

			tabulate `treat' if `touse'
			if r(r) != 2 {
				di as err "With a binary treatment, `treat' must have exactly two values (coded 0 or 1)."
				exit 420
			}
			else if r(r) == 2 {
				capture assert inlist(`treat', 0, 1) if `touse'
				if _rc {
					di as err "With a binary treatment, `treat' must be coded as either 0 or 1."
					exit 450
				}
			}

			tempvar pscore
			logit `treat' `pvars' if `touse'
			predict `pscore' if `touse'
			mmws `treat' if `touse', pscore(`pscore') nstrata(`nstrata') `att' `common' replace

			tempvar pom1 pom0 pomdiff

			if "`median'" != "" {
				qreg `outcome' `ovars' [pw=_mmws] if `treat'==1 & `touse'
				if "`common'" != "" predict `pom1' if _support==1 & `touse'
				else                predict `pom1' if `touse'
				sum `pom1', meanonly
				return scalar poms1 = r(mean)

				qreg `outcome' `ovars' [pw=_mmws] if `treat'==0 & `touse'
				if "`common'" != "" predict `pom0' if _support==1 & `touse'
				else                predict `pom0' if `touse'
			}
			else {
				glm `outcome' `ovars' [pw=_mmws] if `treat'==1 & `touse', ///
					link(`link') family(`family')
				if "`common'" != "" predict `pom1' if _support==1 & `touse'
				else                predict `pom1' if `touse'
				sum `pom1', meanonly
				return scalar poms1 = r(mean)

				glm `outcome' `ovars' [pw=_mmws] if `treat'==0 & `touse', ///
					link(`link') family(`family')
				if "`common'" != "" predict `pom0' if _support==1 & `touse'
				else                predict `pom0' if `touse'
			}

			sum `pom0', meanonly
			return scalar poms0 = r(mean)

			gen `pomdiff' = `pom1' - `pom0'
			if "`att'" != "" sum `pomdiff' if `treat'==1, meanonly
			else             sum `pomdiff', meanonly
			return scalar drmmws = r(mean)

		} // end binary bootstrap

		// multivalued treatments //
		else {

			levelsof `treat' if `touse', local(tlevels)
			local K : word count `tlevels'

			// resolve control level
			if "`control'" != "" local control_level = `control'
			else                  local control_level : word 1 of `tlevels'

			// mlogit + predict pscores
			mlogit `treat' `pvars' if `touse', base(`control_level')
			local pscore_list ""
			forvalues k = 1/`K' {
				local lv : word `k' of `tlevels'
				tempvar ps`lv'
				predict `ps`lv'' if `touse', pr outcome(`lv')
				local pscore_list `pscore_list' `ps`lv''
			}

			// build nstrata list: replicate single value or use supplied list
			local n_nstrata : word count `nstrata'
			if `n_nstrata' == 1 {
				local nstrata_list ""
				forvalues k = 1/`K' {
					local nstrata_list `nstrata_list' `nstrata'
				}
			}
			else {
				local nstrata_list `nstrata'
			}
			mmws `treat' if `touse', pscore(`pscore_list') nstrata(`nstrata_list') ///
				`common' nominal replace

			// POM per level
			forvalues k = 1/`K' {
				local lv : word `k' of `tlevels'
				tempvar pom_`lv'

				if "`median'" != "" {
					qreg `outcome' `ovars' [pw=_mmws] if `treat'==`lv' & `touse'
					if "`common'" != "" predict `pom_`lv'' if _support==1 & `touse'
					else                predict `pom_`lv'' if `touse'
				}
				else {
					if "`common'" != "" {
						glm `outcome' `ovars' [pw=_mmws] ///
							if `treat'==`lv' & _support==1 & `touse', ///
							link(`link') family(`family')
					}
					else {
						glm `outcome' `ovars' [pw=_mmws] if `treat'==`lv' & `touse', ///
							link(`link') family(`family')
					}
					if "`common'" != "" predict `pom_`lv'' if _support==1 & `touse'
					else                predict `pom_`lv'' if `touse'
				}

				sum `pom_`lv'', meanonly
				local b_pom`lv' = r(mean)
				return scalar pom`lv' = r(mean)
			}

			// treatment effects (using stored locals, not r() which gets overwritten)
			forvalues k = 1/`K' {
				local lv : word `k' of `tlevels'
				if `lv' != `control_level' {
					return scalar te`lv' = `b_pom`lv'' - `b_pom`control_level''
				}
			}

		} // end nominal bootstrap

	} // end quietly

end
