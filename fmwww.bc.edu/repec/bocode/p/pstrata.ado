*! 1.10 Ariel Linden 28August2016	/// fixed bugs, added display option
*! 1.00 Ariel Linden 16August2016

program define pstrata, rclass
	version 11.0

	syntax varlist(min=1 max=1 numeric) [if] [in],	///
		PScore(varlist min=1 numeric)				/// propensity score(s) provided by user
		[ Plevel(real 0.05)							/// p-value level used for determining balance
		COMmon										/// common support
		SMIn (int 5)								/// minimum # of strata to start with
		SMAx (int 50)								///  maximum # of strata to try
		REPLace PREfix(str) DISPlay *]

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

		*****************************************************
		*** Generate optimized number of strata by pscore ***
		*****************************************************

		local smin1 = `smin'   // reset for each ps loop
		local bag              // initialize bag to empty

		forval n = 1/`Npscore' {
			local ps : word `n' of `pscore'

			xtile `prefix'strata`n' = `ps' if `touse' `supp1', nq(`smin1')

			while `smin1' <= `smax' {	// default min is 5 and max of 50 strata

				qui tab `prefix'strata`n' if `touse' `supp1'
				local r = r(r)

				// Build p-value matrix directly — no tempvar needed
				matrix _pval`n' = J(`r', 1, .)

				forvalues i = 1/`r' {
					capture anova `ps' `treat' if `prefix'strata`n' == `i' & `touse' `supp1'
					local pvalue = 1 - F(e(df_m), e(df_r), e(F))
					if e(F) == . {		// perfect balance: means/SDs identical across groups
						local pvalue = 1
					}
					if inlist(_rc, 2000, 2001) {	// no obs or insufficient obs: flag as no balance
						local pvalue = 0
					}
					matrix _pval`n'[`i', 1] = `pvalue'
				} //end forval i

				* Evaluate the min pval across strata using mata
				mata: st_local("min", strofreal(min(st_matrix("_pval`n'"))))

				* if the min pval is < the level (0.05) then drop the strata and try again with nq+1
				if `min' < `plevel' {
					drop `prefix'strata`n'
					matrix drop _pval`n'
					local smin1 = `smin1' + 1

					* Terminates code when a solution to any of the PS strata cannot be found
					if `smin1' > `smax' {
						local test = `smin1' - 1	// to get the last strata level tested
						di as err "`test' strata on `ps' were evaluated and no solution could be found. Consider re-estimating the propensity score; see help for details."
						exit 498
					}
					xtile `prefix'strata`n' = `ps' if `touse' `supp1', nq(`smin1')
				}	//end if min

				* if the min pval is >= the level (0.05) end loop, save results, move to next pscore
				else if `min' >= `plevel' {
					// return matrix moves _pval`n' into r(), so copy it first to preserve for display
					matrix _pval`n'_disp = _pval`n'
					return matrix pval`n' = _pval`n'
					// Return the number of strata found for this pscore
					ret scalar nstrata`n' = `smin1'
					// Add the successful variable to bag only once, after solution is found
					local bag `bag' `prefix'strata`n'
					local smin1 = `smin'  // reset for next pscore
					continue, break
				} // end else min

			} //end while
		} // end forvals

		* Store the final set of strata variable names in the dataset characteristic
		char def _dta[`prefix'pstrata] "`bag'"

	} // end quietly

	*****************************************************
	*** Display p-value table by strata (if requested) **
	*****************************************************

	if "`display'" != "" {
		forval n = 1/`Npscore' {
			local ps : word `n' of `pscore'
			local nquant = rowsof(_pval`n'_disp)

			di as txt _newline "{hline 45}"
			di as txt "  Propensity score `n' (`ps'): `nquant' quantiles"
			di as txt "{hline 45}"
			di as txt %10s "Quantile" %15s "P-value" %15s "Balance"
			di as txt "{hline 45}"

			forval i = 1/`nquant' {
				local pv = _pval`n'_disp[`i', 1]
				if `pv' >= `plevel' local bal "Yes"
				else                local bal "No"
				di as txt %10.0f `i' %15.4f `pv' %15s "`bal'"
			}
			di as txt "{hline 45}"
		}
	}

	* Clean up working matrices
	forval n = 1/`Npscore' {
		capture matrix drop _pval`n'_disp
	}

end
