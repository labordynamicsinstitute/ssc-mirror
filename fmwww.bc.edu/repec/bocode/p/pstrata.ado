*! 2.00 Ariel Linden 12Sep2026		/// replaced Bonferroni-adjusted ANOVA search with local split/exclude/floor-force refinement using fixed max-pairwise-SMD balance instead (smdlevel())
*! 1.20 Ariel Linden 07Sep2026		/// Bonferroni-adjust the balance threshold for the number of strata tested simultaneously
*! 1.10 Ariel Linden 28Aug2016		/// fixed bugs, added display option
*! 1.00 Ariel Linden 16Aug2016

program define pstrata, rclass
	version 11.0

	syntax varlist(min=1 max=1 numeric) [if] [in],	///
		PScore(varlist min=1 numeric)				/// propensity score(s) provided by user
		[ SMDlevel(real 0.25)						/// max pairwise standardized mean difference allowed for a stratum to count as balanced
		COMmon										/// common support
		SMIn (int 0)								/// initial # of strata to start with; 0 = auto
		SMAx (int 50)								///  maximum # of strata to try
		REPLace PREfix(str) DISPlay *]

	if `smin' < 0 {
		di as err "smin() must be nonnegative"
		exit 198
	}

	* Parse varlist and call it treat
	gettoken treat : varlist

	* Validate prefix if provided
	if "`prefix'" != "" {
		capture confirm name `prefix'x   // append a char to test as a valid name fragment
		if _rc {
			di as err "prefix() must be a valid Stata name fragment (no spaces or special characters)"
			exit 198
		}
	}

	quietly {

		marksample touse
		count if `touse'
		if r(N) == 0 error 2000
		local N = r(N)

		* drop program variables if option "replace" is chosen *
		if "`replace'" != "" {
			local pstrata_old : char _dta[`prefix'pstrata]
			if "`pstrata_old'" != "" {
				foreach v of local pstrata_old {
					capture drop `v'
				}
			}
		}

		* Data verification *
		local Npscore : word count `pscore'

		tabulate `treat' if `touse'
		local treatcnt = r(r)

		* Verify minimum number of treatment groups *
		if `treatcnt' < 2 {
			di as err "There must be at least two levels of `treat'"
			exit 420
		}

		* Verify there is a matching number of treatment levels and pscores (if not a binary treatment) *
		if `treatcnt' > 2 & `treatcnt' != `Npscore' {
			di as err "For `treatcnt' treatments, there should be `treatcnt' propensity scores, one for each treatment level"
			exit 198
		}

		* minsize is a per-group reliability target derived from smdlevel()
		local minsize = ceil(5.4 / (`smdlevel'^2))

		* does the rarest treatment level have enough observations
		tempname treatfreq
		quietly tabulate `treat' if `touse', matcell(`treatfreq')
		local minlevN = .
		forvalues i = 1/`treatcnt' {
			local thisN = `treatfreq'[`i', 1]
			if `minlevN' == . | `thisN' < `minlevN' local minlevN = `thisN'
		}
		local minlevshare = `minlevN' / `N'

		if `minlevN' < `minsize' {
			di as err "{p 4 4 2}pstrata warning: rarest level of `treat' has only "	///
				"`minlevN' obs (" %4.1f 100*`minlevshare' "% of N), below the "		///
				"minsize target of `minsize' -- floor-forced everywhere. Consider "	///
				"collapsing it with an adjacent level.{p_end}"
		}

		ret scalar minlevN     = `minlevN'
		ret scalar minlevshare = `minlevshare'

		* smin() is the number of equal-frequency quantile bins the search starts with
		if `smin' == 0 {
			local target_minlevperbin = 100
			local smin = max(5, floor(`N' * `minlevshare' / `target_minlevperbin'))
			if `smin' > `smax' local smin = `smax'
		}

		ret scalar minsize  = `minsize'
		ret scalar sminused = `smin'

		***********************
		**** Common support ***
		***********************
		tempvar support
		if "`common'" != "" {
			local supp1 & `support' == 1
		}

		if "`common'" != "" & `treatcnt' == 2 {		// binary treatments
			gen `support' = 1 if `touse'
			sum `pscore' if `treat' == 0 & `touse', meanonly
			replace `support' = 0 if (`pscore' < r(min) | `pscore' > r(max)) & `treat' == 1 & `touse'
			sum `pscore' if `treat' == 1 & `touse', meanonly
			replace `support' = 0 if (`pscore' < r(min) | `pscore' > r(max)) & `treat' == 0 & `touse'

			* get min/max support for return scalar
			sum `pscore' if `support' == 1 & `touse', meanonly
			ret scalar suppmin = r(min)
			ret scalar suppmax = r(max)
		}
		else if "`common'" != "" & `treatcnt' > 2 {	// multiple treatments

			* Compute the intersection of all groups' ranges for each pscore
			gen `support' = 1 if `touse'
			levelsof `treat', local(levels)

			forval i = 1/`Npscore' {
				local p : word `i' of `pscore'

				* Find the overlapping range across all treatment groups for this pscore
				local overmin = .
				local overmax = .
				foreach tr of local levels {
					sum `p' if `treat' == `tr' & `touse', meanonly
					* overall min is the max of the group minimums (tightest lower bound)
					if `overmin' == . | r(min) > `overmin' local overmin = r(min)
					* overall max is the min of the group maximums (tightest upper bound)
					if `overmax' == . | r(max) < `overmax' local overmax = r(max)
				}
				* Exclude observations outside the common support range
				replace `support' = 0 if (`p' < `overmin' | `p' > `overmax') & `touse'
			}

			* get min/max support for return scalars
			forval i = 1/`Npscore' {
				local v : word `i' of `pscore'
				sum `v' if `support' == 1 & `touse', meanonly
				ret scalar suppmin`i' = r(min)
				ret scalar suppmax`i' = r(max)
			}
		}

		***** end common support *****

		*****************************************************************
		*** Generate strata by pscore via local split/exclude refinement
		*****************************************************************

		local bag              // initialize bag to empty

		forval n = 1/`Npscore' {
			local ps : word `n' of `pscore'

			tempvar exclflag
			gen byte `exclflag' = 0 if `touse' `supp1'

			xtile `prefix'strata`n' = `ps' if `touse' `supp1', nq(`smin')

			local nextlabel = `smin'
			local worklist ""
			forvalues i = 1/`smin' {
				local worklist "`worklist' `i'"
			}

			local naccepted = 0
			local nfloorforced = 0
			local nexclstrata = 0
			local exclobs = 0
			local ntotal = `smin'
			local capped = 0

			while ("`worklist'" != "") {

				gettoken cur worklist : worklist

				* has every treatment level been observed within this region?
				levelsof `treat' if `prefix'strata`n' == `cur' & `touse' `supp1' & `exclflag' == 0, local(levelspresent)
				local nlevels : word count `levelspresent'

				count if `prefix'strata`n' == `cur' & `touse' `supp1' & `exclflag' == 0
				local curN = r(N)

				if `nlevels' < `treatcnt' {
					* missing at least one treatment level -- splitting can never fix this
					replace `exclflag' = 1 if `prefix'strata`n' == `cur' & `touse' `supp1'
					local nexclstrata = `nexclstrata' + 1
					local exclobs = `exclobs' + `curN'
					if `nexclstrata' == 1 {
						matrix _excl`n' = (`cur', `curN', 1)
					}
					else {
						matrix _excl`n' = _excl`n' \ (`cur', `curN', 1)
					}
					continue
				}

				* mean/variance/N of the pscore within each treatment-group level
				local i = 0
				local mingrpn = .
				foreach lv of local levelspresent {
					local i = `i' + 1
					summarize `ps' if `prefix'strata`n' == `cur' & `touse' `supp1' & `exclflag' == 0 & `treat' == `lv'
					local grpn`i'    = r(N)
					local grpmean`i' = r(mean)
					local grpvar`i'  = r(Var)
					* smallest present level's count in this strata, used below
					* to decide whether splitting further is worth attempting
					if `mingrpn' == . | `grpn`i'' < `mingrpn' local mingrpn = `grpn`i''
				}

				local maxsmd = 0
				local sumsmd = 0
				local npairs = 0
				local baddiag = 0
				forvalues a = 1/`=`nlevels'-1' {
					local b0 = `a' + 1
					forvalues b = `b0'/`nlevels' {
						local npairs = `npairs' + 1
						if `grpvar`a'' == . | `grpvar`b'' == . {
							* a group with <2 observations in this strata -- variance
							* undefined, treat as an unreliable/failing comparison
							local thissmd = 999
							local baddiag = 1
						}
						else {
							local denom = sqrt((`grpvar`a'' + `grpvar`b'')/2)
							if `denom' == 0 {
								if abs(`grpmean`a''-`grpmean`b'') < 1e-12 local thissmd = 0
								else                                     local thissmd = 999
							}
							else {
								local thissmd = abs(`grpmean`a''-`grpmean`b'')/`denom'
							}
						}
						if `thissmd' > `maxsmd' local maxsmd = `thissmd'
						local sumsmd = `sumsmd' + `thissmd'
					}
				}

				* mean pairwise SMD
				if `baddiag' {
					local meansmd = .
					local cohenf  = .
				}
				else {
					local meansmd = `sumsmd' / `npairs'

					local pooledmean = 0
					local sswithin = 0
					forvalues i = 1/`nlevels' {
						local pooledmean = `pooledmean' + (`grpn`i''/`curN') * `grpmean`i''
						local sswithin   = `sswithin' + (`grpn`i''-1) * `grpvar`i''
					}
					local sdpooled = sqrt(`sswithin' / (`curN' - `nlevels'))

					local cohenf2 = 0
					forvalues i = 1/`nlevels' {
						local dj = (`grpmean`i'' - `pooledmean') / `sdpooled'
						local cohenf2 = `cohenf2' + (`grpn`i''/`curN') * `dj'^2
					}
					local cohenf = sqrt(`cohenf2')
				}

				if `maxsmd' < `smdlevel' {
					* balance achieved -- accept this region as a final stratum
					local naccepted = `naccepted' + 1
					if `naccepted' == 1 {
						matrix _accept`n' = (`cur', `curN', `maxsmd', 0, `meansmd', `cohenf')
					}
					else {
						matrix _accept`n' = _accept`n' \ (`cur', `curN', `maxsmd', 0, `meansmd', `cohenf')
					}
				}
				else if (`mingrpn' < 2*`minsize' | `ntotal' >= `smax') {
					* worst pairwise SMD still >= smdlevel()
					local naccepted = `naccepted' + 1
					local nfloorforced = `nfloorforced' + 1
					if `naccepted' == 1 {
						matrix _accept`n' = (`cur', `curN', `maxsmd', 1, `meansmd', `cohenf')
					}
					else {
						matrix _accept`n' = _accept`n' \ (`cur', `curN', `maxsmd', 1, `meansmd', `cohenf')
					}
					if `ntotal' >= `smax' local capped = 1
				}
				else {
					* split this region's own observations into two sub-strata and requeue both
					local newlabel1 = `nextlabel' + 1
					local newlabel2 = `nextlabel' + 2
					local nextlabel = `newlabel2'
					local ntotal = `ntotal' + 1		// net one new region (one in, two out)

					tempvar substrat
					xtile `substrat' = `ps' if `prefix'strata`n' == `cur' & `touse' `supp1' & `exclflag' == 0, nq(2)
					replace `prefix'strata`n' = `newlabel1' if `substrat' == 1 & `prefix'strata`n' == `cur' & `touse' `supp1'
					replace `prefix'strata`n' = `newlabel2' if `substrat' == 2 & `prefix'strata`n' == `cur' & `touse' `supp1'
					drop `substrat'

					local worklist "`worklist' `newlabel1' `newlabel2'"
				}
			} //end while

			* excluded regions' strata membership is left missing
			replace `prefix'strata`n' = . if `exclflag' == 1

			* Renumber accepted strata 1..n accepted in ascending order of mean pscore
			if `naccepted' > 0 {
				tempvar meanps neworder
				egen `meanps'   = mean(`ps') if `touse' `supp1' & `prefix'strata`n' < ., by(`prefix'strata`n')
				egen `neworder' = group(`meanps') if `touse' `supp1' & `prefix'strata`n' < .

				forvalues i = 1/`naccepted' {
					local oldlbl = _accept`n'[`i', 1]
					summarize `neworder' if `prefix'strata`n' == `oldlbl' & `touse' `supp1', meanonly
					matrix _accept`n'[`i', 1] = r(mean)
				}

				* sort rows by the new column-1 label so row order matches label order
				mata: st_matrix("_accept`n'", sort(st_matrix("_accept`n'"), 1))

				replace `prefix'strata`n' = `neworder' if `touse' `supp1' & `prefix'strata`n' < .
			}

			if `naccepted' > 0 {
				matrix _accept`n'_disp = _accept`n'
				return matrix smd`n' = _accept`n'
			}
			if `nexclstrata' > 0 {
				matrix _excl`n'_disp = _excl`n'
				return matrix excl`n' = _excl`n'
			}
			ret scalar nstrata`n'      = `naccepted'
			ret scalar nfloorforced`n' = `nfloorforced'
			ret scalar nexcluded`n'    = `nexclstrata'
			ret scalar exclobs`n'      = `exclobs'
			ret scalar smdlevel`n'     = `smdlevel'
			ret scalar capped`n'       = `capped'

			local bag `bag' `prefix'strata`n'

		} // end forvals

		* Store the final set of strata variable names in the dataset characteristic
		char def _dta[`prefix'pstrata] "`bag'"

	} // end quietly

	*****************************************************
	*** Display accepted/excluded tables (if requested) **
	*****************************************************

	if "`display'" != "" {
		forval n = 1/`Npscore' {
			local ps : word `n' of `pscore'

			capture confirm matrix _accept`n'_disp
			if _rc local nacc = 0
			else    local nacc = rowsof(_accept`n'_disp)

			capture confirm matrix _excl`n'_disp
			if _rc local nexc = 0
			else    local nexc = rowsof(_excl`n'_disp)

			di as txt _newline "{hline 45}"
			di as txt "  Propensity score `n' (`ps'): `nacc' strata, `nexc' excluded (smdlevel = " %6.4f `smdlevel' ")"
			di as txt "{hline 45}"
			di as txt %10s "Stratum" %15s "Max SMD" %15s "Balance"
			di as txt "{hline 45}"
			forval i = 1/`nacc' {
				local lbl = _accept`n'_disp[`i', 1]
				local sm  = _accept`n'_disp[`i', 3]
				if `sm' < `smdlevel' local bal "Yes"
				else                  local bal "No"
				di as txt %10.0f `lbl' %15.4f `sm' %15s "`bal'"
			}
			di as txt "{hline 45}"
		}
	}

	* Clean up working matrices
	forval n = 1/`Npscore' {
		capture matrix drop _accept`n'
		capture matrix drop _excl`n'
		capture matrix drop _accept`n'_disp
		capture matrix drop _excl`n'_disp
	}

end
