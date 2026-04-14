*! 1.0.0 Ariel Linden 09Apr2026 

program define mlm_gof, rclass
	version 11

	syntax [, Groups(integer -1)]

	local ngroups = `groups'

	// verify that melogit was estimated
	local iscmd  = ("`e(cmd)'"  == "meglm")
	local iscmd2 = ("`e(cmd2)'" == "melogit")
	if !`iscmd' & !`iscmd2' {
		di as error "mlm_gof must be run immediately after melogit"
		exit 321
	}

	// outcome and covariates
	local depvar    = e(depvar)
	local indepvars = e(covariates)

	// e(ivars) lists all random effects variables, outermost first.
	// n_levels = number of random effects variables + 1 (for the observation level).
	local all_ivars = e(ivars)
	local n_levels  = wordcount("`all_ivars'") + 1

	if `n_levels' < 2 {
		di as error "mlm_gof requires a multilevel model with at least two levels."
		di as error "The fitted model has `n_levels' levels."
		exit 301
	}

	// build the || chain for the augmented model re-fit (Step 6).
	local re_spec ""
	forvalues lv = 1/`=`n_levels'-1' {
		local re_spec "`re_spec' || `=word("`all_ivars'", `lv')':"
	}

	// ensure random effects specified
	local cmdline `"`e(cmdline)'"'
	local cmdline = strtrim(substr(`"`cmdline'"', length("melogit ") + 1, .))
	local pipe_pos = strpos(`"`cmdline'"', " || ")
	if `pipe_pos' == 0 {
		di as error cCould not parse e(cmdline): no '||' found"
		exit 301
	}
	local randpart = strtrim(substr(`"`cmdline'"', `pipe_pos' + 4, .))

	local remaining `"`randpart'"'
	local chk_level = 2
	while `"`remaining'"' != "" {
		local next_pipe = strpos(`"`remaining'"', " || ")
		if `next_pipe' > 0 {
			local this_spec = strtrim(substr(`"`remaining'"', 1, `next_pipe' - 1))
			local remaining = strtrim(substr(`"`remaining'"', `next_pipe' + 4, .))
		}
		else {
			local this_spec = strtrim(`"`remaining'"')
			local remaining = ""
		}
		local comma_pos = strpos(`"`this_spec'"', ",")
		if `comma_pos' > 0 {
			local this_spec = strtrim(substr(`"`this_spec'"', 1, `comma_pos' - 1))
		}
		local colon_pos = strpos(`"`this_spec'"', ":")
		if `colon_pos' == 0 {
			di as error "could not find ':' in random-effects grouping: `this_spec'"
			exit 301
		}
		local after_colon = strtrim(substr(`"`this_spec'"', `colon_pos' + 1, .))
		if `"`after_colon'"' != "" {
			di as error "Random slopes are not supported by mlm_gof"
			exit 301
		}
		local chk_level = `chk_level' + 1
	}

	// mark estimation sample
	tempvar touse
	quietly gen byte `touse' = e(sample)
	quietly count if `touse'
	local N = r(N)

	// validate user-specified value of groups() if provided
	if `ngroups' != -1 {
		if `ngroups' < 2 {
			di as error "groups() must be >= 2"
			exit 198
		}
		if `ngroups' >= floor(`N' / 10) {
			di as error "groups(`ngroups') too large for n=`N'; must be < " ///
				floor(`N' / 10)
			exit 198
		}
	}

	// for models with 3+ levels
	local _any_warn = 0
	local _nwarn    = 0
	if `n_levels' > 2 {
		forvalues _lv = 1/`=`n_levels'-2' {
			local _outer  = word("`all_ivars'", `_lv')
			local _inner  = word("`all_ivars'", `_lv' + 1)
			local _odepth = `n_levels' - `_lv' + 1
			local _idepth = `n_levels' - `_lv'
			tempvar _n_inner
			quietly bysort `touse' `_outer': ///
				egen long `_n_inner' = nvals(`_inner') if `touse'
			quietly summarize `_n_inner' if `touse', meanonly
			local _min_inner = r(min)
			local _max_inner = r(max)

			if `_max_inner' < 2 {
				di as error "Every level-`_odepth' cluster contains"
				di as error "  only one level-`_idepth' unit."
				di as error "  The test cannot be run."
				di as error "  Consider fitting a `=`n_levels'-1'-level model."
				exit 459
			}

			// warning if some outer clusters have only one inner unit
			if `_min_inner' < 2 {
				local _any_warn = 1
				local _nwarn = `_nwarn' + 1
				local _warn`_nwarn' "Warning: some level-`_odepth' clusters contain only one level-`_idepth' unit."
				local _warn`_nwarn'b "  those clusters contribute a single cell to the grouping. Results should be interpreted with caution."
			}
			else if `_min_inner' < 5 {
				local _any_warn = 1
				local _nwarn = `_nwarn' + 1
				local _warn`_nwarn' "Warning: some level-`_odepth' clusters contain fewer than 5 level-`_idepth' units (minimum = `_min_inner')."
				local _warn`_nwarn'b "  This is below the range studied in the simulation evidence. Results should be interpreted with caution."
			}
		}
	}

	// minimum observations per innermost cell.
	tempvar _cell_n_check
	quietly bysort `touse' `all_ivars': gen long `_cell_n_check' = _N if `touse'
	quietly summarize `_cell_n_check' if `touse', meanonly
	local min_cell_n = r(min)

	if `min_cell_n' < 10 & `min_cell_n' >= 2 {
		local _any_warn = 1
		local _nwarn = `_nwarn' + 1
		local _warn`_nwarn' "Warning: some cluster cells contain fewer than 10 observations (minimum = `min_cell_n')."
		local _warn`_nwarn'b "  This is below the range studied in the simulation evidence. Results should be interpreted with caution."
	}

	// set G
	if `ngroups' == -1 {
		// Default: data-driven choice, capped at 10
		local ngroups = min(10, `min_cell_n')
	}
	else {
		// user-specified: cap at min_cell_n if necessary and warn
		if `ngroups' > `min_cell_n' {
			local _any_warn = 1
			local _nwarn = `_nwarn' + 1
			local _warn`_nwarn' "Note: the number of groups has been reduced to `min_cell_n' (df = `=`min_cell_n'-1') because some cluster cells contain only `min_cell_n' observation(s)."
			if `min_cell_n' < 6 {
				local _warn`_nwarn'b "  This is a property of the data structure. Fewer than 6 groups may reduce the reliability of the test."
			}
			else {
				local _warn`_nwarn'b "  This is a property of the data structure."
			}
			local ngroups = `min_cell_n'
		}
	}

	if `ngroups' < 2 {
		di as error "The smallest cluster cell has only 1 observation."
		di as error "  The test cannot be run."
		exit 459
	}

	// header
	di as txt _n "Goodness-of-fit test after `n_levels'-level " ///
		"mixed-effects logistic regression with random intercepts"
	di as txt "Variable: {bf:`depvar'}"
	di as txt ""

	// save the base model estimation results to allow the program to be re-run without re-estimating the model
	tempname base_est
	quietly estimates store `base_est'

	tempvar xbhat phat
	quietly predict `xbhat' if `touse', xb

	// predict all random effects
	local relist ""
	forvalues lv = 1/`=`n_levels'-1' {
		tempvar _re`lv'
		local relist "`relist' `_re`lv''"
	}
	quietly predict `relist', reffects

	// conditional predictor = xb + sum of all random effect EB estimates
	quietly gen double `phat' = `xbhat' if `touse'
	forvalues lv = 1/`=`n_levels'-1' {
		quietly replace `phat' = `phat' + `_re`lv'' if `touse'
	}
	quietly replace `phat' = invlogit(`phat') if `touse'

	// sort within innermost cluster cell, assign group labels
	tempvar orig_order cell_n gi rank_w grp

	quietly gen long `orig_order' = _n

	// number of obs in the innermost cluster cell
	quietly bysort `touse' `all_ivars': gen long `cell_n' = _N if `touse'

	quietly gen long `gi' = floor(`cell_n' / `ngroups') if `touse'

	// sort estimation sample by all cluster levels then ascending phat
	sort `touse' `all_ivars' `phat' `orig_order'
	quietly by `touse' `all_ivars': gen long `rank_w' = _n if `touse'

	quietly gen byte `grp' = min(`ngroups', ceil(`rank_w' / `gi')) if `touse'

	// restore original dataset order
	sort `orig_order'

	// G-1 pooled indicator variables
	local indvars ""
	forvalues g = 2/`ngroups' {
		tempvar ind`g'
		quietly gen byte `ind`g'' = (`grp' == `g') if `touse'
		local indvars `indvars' `ind`g''
	}

	// augmented model
	quietly melogit `depvar' `indepvars' `indvars' if `touse' `re_spec'

	// joint Wald test
	local test_expr ""
	forvalues g = 2/`ngroups' {
		local test_expr `"`test_expr' (`ind`g'' = 0)"'
	}
	quietly test `test_expr'

	local chi2stat = r(chi2)
	local df_test  = r(df)
	local pvalue   = r(p)

	// restore the base model so e() reflects the original melogit results.
	quietly estimates restore `base_est'
	quietly estimates drop `base_est'

	// display results
	local Gm1 = `ngroups' - 1

	local _lbl "Number of observations"
	di as txt "`_lbl'" _dup(`=30-length("`_lbl'")') " " " = " as res %9.0f `N'

	// cluster counts at each level (innermost first)
	forvalues _lv = `=`n_levels'-1'(-1)1 {
		local _lvar   = word("`all_ivars'", `_lv')
		local _ldepth = `n_levels' - `_lv' + 1
		tempvar _nclust
		quietly egen long `_nclust' = nvals(`_lvar') if `touse'
		quietly summarize `_nclust' if `touse', meanonly
		local _nc = r(mean)
		local _lbl "Number of level-`_ldepth' clusters"
		di as txt "`_lbl'" _dup(`=30-length("`_lbl'")') " " " = " as res %9.0f `_nc'
	}

	local _lbl "Number of groups"
	di as txt "`_lbl'" _dup(`=30-length("`_lbl'")') " " " = " as res %9.0f `ngroups'
	local _lbl "Wald chi2({bf:`Gm1'})"
	di as txt "`_lbl'" _dup(`=35-length("`_lbl'")') " " " = " as res %9.4f `chi2stat'
	local _lbl "Prob > chi2"
	di as txt "`_lbl'" _dup(`=30-length("`_lbl'")') " " " = " as res %9.4f `pvalue'
	di as txt ""

	if `pvalue' >= 0.05 {
		di as txt "  Model fits the data adequately"
	}
	else {
		di as txt "  Model has a questionable fit"
	}

	// display any warnings at the bottom
	if `_any_warn' {
		di as txt ""
		forvalues _w = 1/`_nwarn' {
			di as txt "`_warn`_w''"
			di as txt "`_warn`_w'b'"
		}
	}

	// return results
	return scalar chi2   = `chi2stat'
	return scalar df     = `df_test'
	return scalar p      = `pvalue'
	return scalar N      = `N'
	return scalar groups = `ngroups'
	return scalar levels = `n_levels'

end
