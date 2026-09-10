*! 2.10 Ariel Linden 06Sep2026 // added smin() option to allow users to set minimum required N in all strata
*! 2.00 Ariel Linden 27May2026 // Streamlined validation; fixed bugs
*! 1.21 Ariel Linden 18Feb2017 // Fixed bug in IPTW for multiple treatments
*! 1.20 Ariel Linden 22Jan2017 // Added tlevel option; cleaned up common support code; changed figure to show only values within common support when common is specified
*! 1.10 Ariel Linden 31Dec2014 // Added IPTW option
*! 1.00 Ariel Linden 06Jun2014

program mmws, rclass
version 13.0

	/* obtain settings */
	syntax varlist(min=1 max=1 numeric) [if] [in], 			/// treatment variable
	PScore(varlist min=1 numeric) 		           	  		/// propensity score provided by user
	[ NSTRata(numlist min=1 int)							/// if user wants mmws to provide strata
	STRata(varlist min=1 numeric)		       				/// if user provides strata
	ORDinal                                   				/// if ordinal treatments
	TLEVel(numlist min=1 max=1 int)							/// if ordinal, which level was used for predicting pscore
	NOMinal													///	if nominal treatments
	ATT				       									///	if average treatment effect on the treated (binary treatments only)
	IPTW													/// adds IPTW as an option
	COMMon		                                			/// common support
	FIGure													/// histogram of pscore distribution(s)
	SMIN(integer 1)											///
	REPLace PREfix(str)]

	gettoken treat : varlist

	// ordinal and nominal are mutually exclusive -- check once up front
	if ("`ordinal'" != "") & ("`nominal'" != "") {
		di as err "Either ordinal or nominal options can be specified, but not both"
		exit 198
	}

	if `smin' < 1 {
		di as err "smin() must be a positive integer"
		exit 198
	}

	// define support macros before quietly so they are available everywhere
	if "`common'" != "" {
		local supp  if `prefix'_support == 1
		local supp1 & `prefix'_support == 1
	}

quietly {
		marksample touse
		count if `touse'
		if r(N) == 0 error 2000

		/* drop program variables if option "replace" is chosen */
		if "`replace'" != "" {
			local mmws : char _dta[`prefix'_mmws]
			if "`mmws'" != "" {
				foreach v of local mmws {
					capture drop `v'
				}
			}
		}

*********************************
***** Binary treatments *********
*********************************
	if "`ordinal'`nominal'" == "" {

		* validate treatment variable *
		_validatetreat `treat', touse(`touse') binary

		* treatment must be coded 0/1 *
		capture assert inlist(`treat', 0, 1) if `touse'
		if _rc {
			di as err "With a binary treatment, `treat' must be coded as either 0 or 1."
			exit 450
		}

		local Npscore : word count `pscore'
		if `Npscore' > 1 {
			di as err "With binary treatments, only one pscore can be specified"
			exit 198
		}

		local Nstrata : word count `nstrata'
		if `Nstrata' > 1 {
			di as err "With binary treatments, only one Nstrata can be specified"
			exit 198
		}

		* Common support *
		gen `prefix'_support = 1 if `touse'
		label var `prefix'_support "common support"
		sum `pscore' if `treat'==0 & `touse', meanonly
		replace `prefix'_support = 0 if `pscore' < r(min) & `treat'==1 & `touse'
		sum `pscore' if `treat'==1 & `touse', meanonly
		replace `prefix'_support = 0 if `pscore' > r(max) & `treat'==0 & `touse'

		* Test for strata vs nstrata and generate 5 quantiles if nstrata not specified *
		if ("`strata'" != "") & ("`nstrata'" != "") {
			di as err "Either strata or nstrata may be specified, but not both"
			exit 198
		}
		if ("`strata'" == "") & ("`nstrata'" != "") {
			local nstrata `nstrata'
		}
		else if ("`strata'" == "") & ("`nstrata'" == "") {
			local nstrata = 5
		}

		if ("`strata'" == "") {
			xtile `prefix'_strata = `pscore' if `touse' `supp1', nq(`nstrata')
		}
		else {
			clonevar `prefix'_strata = `strata' if `touse'
		}

		* get min/max support for later use in graphs *
		sum `pscore' if `prefix'_support==1 & `touse', meanonly
		local suppmin = r(min)
		local suppmax = r(max)
		ret scalar suppmin = `suppmin'
		ret scalar suppmax = `suppmax'

		* Get overall sample size and treatment proportions *
		count if `touse' `supp1'
		local Ntot = r(N)
		count if `treat'==1 `supp1' & `touse'
		local Ntreat = r(N)
		local treatprop = `Ntreat' / `Ntot'						// Proportion treated in sample (Pr=Z1)
		count if `treat'==0 `supp1' & `touse'
		local Ncontrol = r(N)
		local controlprop = `Ncontrol' / `Ntot'					// Proportion non-treated in sample (Pr=Z0)

		* Generate ATT weights *
		if "`att'" != "" {

			gen `prefix'_mmws =. if `touse'
			label var `prefix'_mmws "ATT weights for binary treatment"

			local propatt = (1 - `treatprop') / `treatprop'

			tempvar keep isT isC nt nc
			gen byte `keep' = `touse' `supp1'
			gen byte `isT' = `keep' & `treat'==1
			gen byte `isC' = `keep' & `treat'==0
			bysort `prefix'_strata: egen long `nt' = total(`isT')
			bysort `prefix'_strata: egen long `nc' = total(`isC')

			count if `keep' & (`nt' < `smin' | `nc' < `smin')
			if r(N) > 0 {
				levelsof `prefix'_strata if `keep' & (`nt' < `smin' | `nc' < `smin'), local(badstrata)
				di as err "`prefix'_strata level(s) `badstrata' do not contain at least `smin' observation(s) of both treatment levels; reduce nstrata(), revise strata(), or lower smin()"
				exit 459
			}

			replace `prefix'_mmws = (`nt'/`nc') * `propatt' if `treat'==0 & `touse' & (`nt'+`nc')>0
			replace `prefix'_mmws = 1 if `treat'==1 & `touse' & (`nt'+`nc')>0
			drop `keep' `isT' `isC' `nt' `nc'

			if "`common'" != "" {
				replace `prefix'_mmws = 0 if `prefix'_support != 1 & `touse'
			}

			* Generate IPTW weights for ATT *
			if "`iptw'" != "" {
				gen `prefix'_iptw = cond(`treat'==1, 1, `pscore'/(1-`pscore')) if `touse'
				if "`common'" != "" {
					replace `prefix'_iptw = 0 if `prefix'_support != 1 & `touse'
				}
				label var `prefix'_iptw "IPTW (ATT) weights for binary treatment"
				count if missing(`prefix'_iptw) & `touse'
				if r(N) > 0 {
					noisily di as err "`prefix'_iptw contains `=r(N)' missing value(s); check `pscore' for values of exactly 0 or 1"
				}
			}

			local mmws `prefix'_support `prefix'_strata `prefix'_mmws `prefix'_iptw
			char def _dta[`prefix'_mmws] "`mmws'"

		} //end att

		* Generate ATE weights *
		else {

			gen `prefix'_mmws =. if `touse'
			label var `prefix'_mmws "ATE weights for binary treatment"

			tempvar keep isT isC nt nc ntot
			gen byte `keep' = `touse' `supp1'
			gen byte `isT' = `keep' & `treat'==1
			gen byte `isC' = `keep' & `treat'==0
			bysort `prefix'_strata: egen long `nt' = total(`isT')
			bysort `prefix'_strata: egen long `nc' = total(`isC')

			count if `keep' & (`nt' < `smin' | `nc' < `smin')
			if r(N) > 0 {
				levelsof `prefix'_strata if `keep' & (`nt' < `smin' | `nc' < `smin'), local(badstrata)
				di as err "`prefix'_strata level(s) `badstrata' do not contain at least `smin' observation(s) of both treatment levels; reduce nstrata(), revise strata(), or lower smin()"
				exit 459
			}

			gen long `ntot' = `nt' + `nc'

			replace `prefix'_mmws = (`ntot'/`nc') * `controlprop' if `treat'==0 & `touse' & `ntot'>0
			replace `prefix'_mmws = (`ntot'/`nt') * `treatprop' if `treat'==1 & `touse' & `ntot'>0
			drop `keep' `isT' `isC' `nt' `nc' `ntot'

			if "`common'" != "" {
				replace `prefix'_mmws = 0 if `prefix'_support != 1 & `touse'
			}

		} // end ATE

		* Generate IPTW weights for ATE *
		if "`iptw'" != "" & "`att'" == "" {
			gen `prefix'_iptw = cond(`treat'==1, 1/`pscore', 1/(1-`pscore')) if `touse'
			if "`common'" != "" {
				replace `prefix'_iptw = 0 if `prefix'_support != 1 & `touse'
			}
			label var `prefix'_iptw "IPTW (ATE) weights for binary treatment"
			count if missing(`prefix'_iptw) & `touse'
			if r(N) > 0 {
				noisily di as err "`prefix'_iptw contains `=r(N)' missing value(s); check `pscore' for values of exactly 0 or 1"
			}
		}

		local mmws `prefix'_support `prefix'_strata `prefix'_mmws `prefix'_iptw
		char def _dta[`prefix'_mmws] "`mmws'"

		* figure *
		if ("`figure'" != "") {
			if ("`common'" != "") {
				histogram `pscore' `supp', dens by(`treat', cols(1) legend(off)) ///
					xline(`suppmin' `suppmax') xla(0(.20)1) kdensity
			}
			else {
				histogram `pscore', dens by(`treat', cols(1) legend(off)) ///
					xline(`suppmin' `suppmax') xla(0(.20)1) kdensity
			}
		} //end fig

	}	// Closing bracket for binary treatments

**********************************
***** Ordinal treatments *********
**********************************
	if ("`ordinal'" != "") {

		* validate treatment variable *
		_validatetreat `treat', touse(`touse')

		* Verify there is a matching number of pscores and nstrata defined *
		local Npscore : word count `pscore'
		if `Npscore' > 1 {
			di as err "With ordinal treatments, only one pscore can be specified"
			exit 198
		}

		local Nstrata : word count `nstrata'
		if `Nstrata' > 1 {
			di as err "With ordinal treatments, only one Nstrata can be specified"
			exit 198
		}

		* Common support - default is lowest treatment level in data *
		if ("`tlevel'" == "") {
			sum `treat' if `touse', meanonly
			local tlevel = r(min)
		}

		count if `treat'==`tlevel' & `touse'
		if r(N) == 0 {
			di as err "tlevel(`tlevel') does not occur in `treat' within the estimation sample"
			exit 459
		}

		gen `prefix'_support = 1 if `touse'
		label var `prefix'_support "common support"
		sum `pscore' if `treat'==`tlevel' & `touse', meanonly
		replace `prefix'_support = 0 if (`pscore' < r(min) | `pscore' > r(max)) & `touse'

		* Test for strata vs nstrata *
		if ("`strata'" != "") & ("`nstrata'" != "") {
			di as err "Either strata or nstrata may be specified, but not both"
			exit 198
		}
		if ("`strata'" == "") & ("`nstrata'" != "") {
			local nstrata `nstrata'
		}
		else if ("`strata'" == "") & ("`nstrata'" == "") {
			local nstrata = 5
		}

		if ("`strata'" == "") {
			xtile `prefix'_strata = `pscore' if `touse' `supp1', nq(`nstrata')
		}
		else {
			clonevar `prefix'_strata = `strata' if `touse'
		}

		* get min/max support for later use in graphs *
		sum `pscore' if `prefix'_support==1 & `touse', meanonly
		local suppmin = r(min)
		local suppmax = r(max)
		ret scalar suppmin = `suppmin'
		ret scalar suppmax = `suppmax'

		* Total N *
		count if `touse' `supp1'
		local Nall = r(N)

		* Generate weights *
		gen `prefix'_mmws =. if `touse'
		label var `prefix'_mmws "weights for ordinal treatments"

		tempvar keep nstratum nij ntreat
		gen byte `keep' = `touse' `supp1'

		levelsof `treat' if `keep', local(chklevels)
		local chkK : word count `chklevels'
		tempvar chkcnt chkfirst chkndist
		bysort `prefix'_strata `treat': egen long `chkcnt' = total(`keep')
		bysort `prefix'_strata `treat': gen byte `chkfirst' = (_n==1) & `chkcnt'>0
		bysort `prefix'_strata: egen long `chkndist' = total(`chkfirst')
		count if `keep' & (`chkndist' < `chkK' | `chkcnt' < `smin')
		if r(N) > 0 {
			levelsof `prefix'_strata if `keep' & (`chkndist' < `chkK' | `chkcnt' < `smin'), local(badstrata)
			di as err "`prefix'_strata level(s) `badstrata' do not contain at least `smin' observation(s) of every level of `treat'; reduce nstrata(), revise strata(), or lower smin()"
			exit 459
		}
		drop `chkcnt' `chkfirst' `chkndist'

		bysort `prefix'_strata: egen long `nstratum' = total(`keep')
		bysort `prefix'_strata `treat': egen long `nij' = total(`keep')
		bysort `treat': egen long `ntreat' = total(`keep')

		replace `prefix'_mmws = (`nstratum'/`nij') * (`ntreat'/`Nall') if `touse' `supp1'
		drop `keep' `nstratum' `nij' `ntreat'

		if "`common'" != "" {
			replace `prefix'_mmws = 0 if `prefix'_support != 1 & `touse'
		}

		* Generate IPTW weights *
		if ("`iptw'" != "") {
			gen `prefix'_iptw = 1/`pscore' if `touse'
			if "`common'" != "" {
				replace `prefix'_iptw = 0 if `prefix'_support != 1 & `touse'
			}
			label var `prefix'_iptw "IPTW weights for ordinal treatment"
			count if missing(`prefix'_iptw) & `touse'
			if r(N) > 0 {
				noisily di as err "`prefix'_iptw contains `=r(N)' missing value(s); check `pscore' for values of exactly 0 or 1"
			}
		}

		local mmws `prefix'_support `prefix'_strata `prefix'_mmws `prefix'_iptw
		char def _dta[`prefix'_mmws] "`mmws'"

		* figure *
		if ("`figure'" != "") {
			if ("`common'" != "") {
				histogram `pscore' `supp', dens by(`treat', cols(1) legend(off)) ///
					xline(`suppmin' `suppmax') xla(0(.20)1) kdensity
			}
			else {
				histogram `pscore', dens by(`treat', cols(1) legend(off)) ///
					xline(`suppmin' `suppmax') xla(0(.20)1) kdensity
			}
		} // end fig

	} // Closing bracket for ordinal treatments

**********************************
***** Nominal treatments *********
**********************************
	if ("`nominal'" != "") {

		* validate treatment variable *
		_validatetreat `treat', touse(`touse')

		* Verify matching number of pscores and nstrata *
		local Npscore : word count `pscore'

		tabulate `treat' if `touse'
		if r(r) != `Npscore' {
			di as err "For nominal treatments, there should be one pscore for each treatment level"
			exit 198
		}

		if ("`strata'" != "") & ("`nstrata'" != "") {
			di as err "Either strata or nstrata may be specified, but not both"
			exit 198
		}

		local Nstrata : word count `nstrata'
		if `Nstrata' != `Npscore' & `Nstrata' != 0 {
			di as err "For nominal treatments, there should be one stratification specified for each pscore"
			exit 198
		}

		local Nstratae : word count `strata'
		if `Nstratae' != `Npscore' & `Nstratae' != 0 {
			di as err "For nominal treatments, there should be one stratification specified for each pscore"
			exit 198
		}

		* Common support *
		gen `prefix'_support = 1 if `touse'
		label var `prefix'_support "common support"
		levelsof `treat' if `touse', local(levels)
		foreach tr of local levels {
			foreach p of varlist `pscore' {
				sum `p' if `treat'==`tr' & `touse', meanonly
				replace `prefix'_support = 0 if (`p' < r(min) | `p' > r(max)) & `treat'!=`tr' & `touse'
			}
		}

		* Generate strata *
		if ("`strata'" != "") & ("`nstrata'" == "") {
			forval i = 1/`Nstratae' {
				local n : word `i' of `strata'
				clonevar `prefix'_strata`i' = `n' if `touse'
				local bag `bag' `prefix'_strata`i'
			}
		}
		else if ("`nstrata'" != "") & ("`strata'" == "") {
			forval i = 1/`Npscore' {
				local v : word `i' of `pscore'
				local n : word `i' of `nstrata'
				xtile `prefix'_strata`i' = `v' if `touse' `supp1', nq(`n')
				local bag `bag' `prefix'_strata`i'
			}
		}
		else {
			// default: 5 quantiles per pscore
			forval i = 1/`Npscore' {
				local v : word `i' of `pscore'
				xtile `prefix'_strata`i' = `v' if `touse' `supp1', nq(5)
				local bag `bag' `prefix'_strata`i'
			}
		}

		* get min/max support for later use in graphs *
		forval i = 1/`Npscore' {
			local v : word `i' of `pscore'
			sum `v' if `prefix'_support==1 & `touse', meanonly
			local suppmin`i' = r(min)
			local suppmax`i' = r(max)
			ret scalar suppmin`i' = `suppmin`i''
			ret scalar suppmax`i' = `suppmax`i''
		}

		* Generate weights *
		levelsof `treat' if `touse', local(treatment)
		matrix input A = (`treatment')

		gen `prefix'_mmws =. if `touse'
		label var `prefix'_mmws "weights for nominal treatments"

		count if `touse' `supp1'
		local sN = r(N)

		tempvar keep
		gen byte `keep' = `touse' `supp1'

		local T = 1
		foreach s of varlist `prefix'_strata* {
			local tr = el("A", 1, `T')

			tempvar chkT chkpres
			gen byte `chkT' = `keep' & `treat'==`tr'
			bysort `s': egen long `chkpres' = total(`chkT')
			count if `keep' & `chkpres' < `smin'
			if r(N) > 0 {
				levelsof `s' if `keep' & `chkpres' < `smin', local(badstrata)
				di as err "`s' level(s) `badstrata' contain fewer than `smin' observation(s) with `treat'==`tr'; reduce nstrata(), revise strata(), or lower smin()"
				exit 459
			}
			drop `chkT' `chkpres'

			tempvar nst nstr
			bysort `s': egen long `nst' = total(`keep')
			bysort `s' `treat': egen long `nstr' = total(`keep')

			count if `treat'==`tr' `supp1' & `touse'
			local treatprop = r(N) / `sN'

			replace `prefix'_mmws = (`nst'/`nstr') * `treatprop' if `treat'==`tr' & `touse'
			drop `nst' `nstr'

			local T = `T' + 1
		}
		drop `keep'

		if "`common'" != "" {
			replace `prefix'_mmws = 0 if `prefix'_support != 1 & `touse'
		}

		* Generate IPTW weights *
		if "`iptw'" != "" {
			gen `prefix'_iptw = . if `touse'
			label var `prefix'_iptw "IPTW weights for nominal treatment"
			forvalues x = 1/`Npscore' {
				local tr = el("A", 1, `x')
				local v : word `x' of `pscore'
				replace `prefix'_iptw = 1/`v' if `treat'==`tr' & `touse'
			}
			if "`common'" != "" {
				replace `prefix'_iptw = 0 if `prefix'_support != 1 & `touse'
			}
			count if missing(`prefix'_iptw) & `touse'
			if r(N) > 0 {
				noisily di as err "`prefix'_iptw contains `=r(N)' missing value(s); check the pscore variables for values of exactly 0 or 1"
			}
		}

		local mmws `prefix'_support `bag' `prefix'_mmws `prefix'_iptw
		char def _dta[`prefix'_mmws] "`mmws'"

		* figure *
		if ("`figure'" != "") {
			forval i = 1/`Npscore' {
				local v : word `i' of `pscore'
				local fig fig`i'
				if ("`common'" != "") {
					histogram `v' `supp', dens by(`treat', cols(1) legend(off)) ///
						xline(`suppmin`i'' `suppmax`i'') xla(0(.20)1) name(`fig', replace) nodraw kdensity
				}
				else {
					histogram `v', dens by(`treat', cols(1) legend(off)) ///
						xline(`suppmin`i'' `suppmax`i'') xla(0(.20)1) name(`fig', replace) nodraw kdensity
				}
				local figname `figname' `fig'
			}
			graph combine `figname', altshrink name(combined, replace)
		} // end fig

	} // Closing bracket for nominal treatments

} // Closing bracket for quietly

end

program _validatetreat, rclass

	syntax varname, touse(varname) [ binary ]

	local tvar `varlist'

	// must be non-negative integers
	qui count if (trunc(`tvar') != `tvar' | `tvar' < 0) & `touse'
	if r(N) > 0 {
		di as err "{p}treatment variable {bf:`tvar'} must contain " ///
		 "nonnegative integers{p_end}"
		exit 459
	}

	// count distinct levels within sample
	qui levelsof `tvar' if `touse', local(_lv)
	local klev : word count `_lv'

	// must have at least 2 levels
	if `klev' == 1 {
		di as err "{p}there is only one level in treatment variable " ///
		 "{bf:`tvar'}; this is not allowed{p_end}"
		exit 459
	}

	// binary: must have exactly 2 levels
	if "`binary'" != "" & `klev' != 2 {
		di as err "{p}treatment variable {bf:`tvar'} must have 2 " ///
		 "levels, but `klev' were found{p_end}"
		exit 459
	}

	// nominal (non-binary): limit of 20 categories
	if "`binary'" == "" & `klev' > 20 {
		di as err "{p}treatment variable {bf:`tvar'} has `klev' " ///
		 "levels exceeding the maximum of 20{p_end}"
		exit 459
	}

	return local klev = `klev'

end
