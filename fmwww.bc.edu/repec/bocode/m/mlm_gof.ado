*! 1.0.0 Ariel Linden 18Apr2026

program define mlm_gof, rclass
	version 16

	syntax [, Groups(integer -1)]

	local ngroups = `groups'

	// clean up any stale tempvar group indicator variables left by a previously failed run
	capture quietly drop __0000*

	// verify that melogit was the last estimation model 
	local iscmd  = ("`e(cmd)'"  == "meglm")
	local iscmd2 = ("`e(cmd2)'" == "melogit")
	if !`iscmd' & !`iscmd2' {
		di as error "the current estimation results must be from {bf:melogit}"
		exit 321
	}

	local depvar    = e(depvar)
	local indepvars = e(covariates)
	local all_ivars = e(ivars)
	local n_levels  = wordcount("`all_ivars'") + 1

	if `n_levels' < 2 {
		di as error "mlm_gof requires a multilevel model with at least two levels"
		exit 301
	}

	// reconstruct the random-effects specification from e(b) and e(cmdline)
	local cmdline = e(cmdline)
	local cmdline = strtrim(substr("`cmdline'", length("melogit ") + 1, .))
	local pipe_pos = strpos("`cmdline'", " || ")
	if `pipe_pos' == 0 {
		di as error "Could not parse e(cmdline): no '||' found"
		exit 301
	}
	local repart = strtrim(substr("`cmdline'", `pipe_pos' + 4, .))
	local scan_rem "`repart'"
	while "`scan_rem'" != "" {
		// get next || segment
		local scan_pipe = strpos("`scan_rem'", " || ")
		if `scan_pipe' > 0 {
			local scan_seg = strtrim(substr("`scan_rem'", 1, `scan_pipe' - 1))
			local scan_rem = strtrim(substr("`scan_rem'", `scan_pipe' + 4, .))
		}
		else {
			local scan_seg = strtrim("`scan_rem'")
			local scan_rem = ""
		}
		// extract options after the comma in this segment
		local scan_comma = strpos("`scan_seg'", ",")
		if `scan_comma' > 0 {
			local seg_opts = strtrim(substr("`scan_seg'", `scan_comma' + 1, .))
			// keep only options that are NOT cov(...) -- those are RE-specific
			if substr(strtrim("`seg_opts'"), 1, 4) != "cov(" {
				// no cov() prefix: all options after comma are global
				local est_opts = strtrim("`est_opts' `seg_opts'")
			}
			else {
				// cov() present: strip it and keep the rest
				local cov_end = strpos("`seg_opts'", ")")
				if `cov_end' < length("`seg_opts'") {
					local after_cov = strtrim(substr("`seg_opts'", `cov_end' + 1, .))
					// strip leading comma if present
					if substr("`after_cov'", 1, 1) == "," {
						local after_cov = strtrim(substr("`after_cov'", 2, .))
					}
					local est_opts = strtrim("`est_opts' `after_cov'")
				}
			}
		}
	}

	// parse cov() option from each || segment
	local n_re_segs = 0
	local remaining "`repart'"
	while "`remaining'" != "" {
		local next_pipe = strpos("`remaining'", " || ")
		if `next_pipe' > 0 {
			local this_seg = strtrim(substr("`remaining'", 1, `next_pipe' - 1))
			local remaining = strtrim(substr("`remaining'", `next_pipe' + 4, .))
		}
		else {
			local this_seg = strtrim("`remaining'")
			local remaining = ""
		}
		local ++n_re_segs
		// extract ONLY the cov() option for this segment
		local re_opt`n_re_segs' = ""
		local comma_pos = strpos("`this_seg'", ",")
		if `comma_pos' > 0 {
			local seg_after = strtrim(substr("`this_seg'", `comma_pos' + 1, .))
			// keep only cov(...) -- it is RE-specific and belongs in re_spec
			if substr("`seg_after'", 1, 4) == "cov(" {
				// extract just the cov(...) token
				local cov_end = strpos("`seg_after'", ")")
				local re_opt`n_re_segs' = ", " + substr("`seg_after'", 1, `cov_end')
			}
			// non-cov options are global and already in est_opts -- skip them here
		}
	}

	// parse e(b) var() entries to get slope TERMs per level
	tempname b_mat
	matrix `b_mat' = e(b)
	local np = colsof(`b_mat')
	local n_reterms = 0
	local re_gvars_abbr = ""   // abbreviated groupvars from e(b), for matching
	forvalues k = 1/`np' {
		local nm : word `k' of `: colnames `b_mat''
		if substr("`nm'", 1, 4) == "var(" {
			local ++n_reterms
			// parse var(TERM[GROUPVAR_abbr]) -> extract TERM and abbreviated GROUPVAR
			local inner = substr("`nm'", 5, length("`nm'") - 5)
			local brack = strpos("`inner'", "[")
			local re_term`n_reterms' = strtrim(substr("`inner'", 1, `brack' - 1))
			local gv_abbr = strtrim(substr("`inner'", `brack' + 1, length("`inner'") - `brack' - 1))
			local re_gvar_abbr`n_reterms' = "`gv_abbr'"
			// track unique abbreviated groupvars in order (for position matching)
			if !`:list gv_abbr in re_gvars_abbr' {
				local re_gvars_abbr = "`re_gvars_abbr' `gv_abbr'"
			}
		}
	}

	// reassemble re_spec using FULL groupvar names from e(ivars)
	local seg_idx = 0
	local n_abbr_gvars : word count `re_gvars_abbr'
	forvalues seg = 1/`n_abbr_gvars' {
		local ++seg_idx
		local gv_abbr : word `seg' of `re_gvars_abbr'
		// full groupvar name from e(ivars) by position
		local gv_full : word `seg' of `all_ivars'
		// collect slope terms for this groupvar (exclude _cons)
		local slopes_this = ""
		forvalues t = 1/`n_reterms' {
			if "`re_gvar_abbr`t''" == "`gv_abbr'" & "`re_term`t''" != "_cons" {
				// use the expanded term directly (e.g. 1.urban)
				local slopes_this = "`slopes_this' `re_term`t''"

			}
		}
		local slopes_this = strtrim("`slopes_this'")
		// get cov() option for this segment from e(cmdline) parse
		local opt_this = "`re_opt`seg_idx''"
		// build: || full_groupvar: [slopes] [, cov(...)]
		local re_spec = "`re_spec' || `gv_full': `slopes_this'`opt_this'"
	}
	local re_spec = strtrim("`re_spec'")

	// cluster size and group number checks
	tempvar touse
	quietly gen byte `touse' = e(sample)
	quietly count if `touse'
	local N = r(N)

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
				di as error "Every level-`_odepth' cluster contains only one level-`_idepth' unit"
				di as error "  The test cannot be run."
				exit 459
			}
			if `_min_inner' < 2 {
				local _any_warn = 1
				local _nwarn = `_nwarn' + 1
				local _warn`_nwarn' "Warning: Some level-`_odepth' clusters contain only one level-`_idepth' unit."
				local _warn`_nwarn'b "         Results should be interpreted with caution."
			}
			else if `_min_inner' < 5 {
				local _any_warn = 1
				local _nwarn = `_nwarn' + 1
				local _warn`_nwarn' "Warning: Some level-`_odepth' clusters contain fewer than 5 level-`_idepth' units (minimum = `_min_inner')."
				local _warn`_nwarn'b "         Results should be interpreted with caution."
			}
		}
	}

	tempvar _cell_n_check
	quietly bysort `touse' `all_ivars': gen long `_cell_n_check' = _N if `touse'
	quietly summarize `_cell_n_check' if `touse', meanonly
	local min_cell_n = r(min)

	if `ngroups' == -1 {
		// data-driven default: G = min(10, min_cell_n)
		local ngroups = min(10, `min_cell_n')
		// note if G was reduced below 10
		if `min_cell_n' < 10 & `min_cell_n' >= 2 {
			local _any_warn = 1
			local _nwarn = `_nwarn' + 1
			local _warn`_nwarn' "Note:    The number of groups was set to `ngroups' (the minimum level-2 cluster cell size)"
			local _warn`_nwarn'b "         because some clusters contain fewer than 10 observations."
		}
	}
	else {
		// user-specified G: warn if G exceeds minimum cell size, but still attempt the test
		if `ngroups' > `min_cell_n' {
			local _any_warn = 1
			local _nwarn = `_nwarn' + 1
			local _warn`_nwarn' "Warning: groups(`ngroups') exceeds the minimum level-2 cluster cell size (`min_cell_n' obs)."
			local _warn`_nwarn'b "         Some smaller clusters cannot be divided into `ngroups' groups; results should be interpreted with caution."
		}
	}

	if `ngroups' < 2 {
		di as error "The smallest cluster cell has only 1 observation. The test cannot be run."
		exit 459
	}

	// header
	di as txt _n "Goodness-of-fit test after `n_levels'-level " ///
		"mixed-effects logistic regression with random effects"
	di as txt "Variable: {bf:`depvar'}"
	di as txt ""

	// conditional predicted probabilities
	tempname base_est
	quietly estimates store `base_est'

	tempvar xbhat phat
	quietly predict `xbhat' if `touse', xb

	forvalues t = 1/`n_reterms' {
		tempvar _re`t'
		local relist "`relist' `_re`t''"
	}
	quietly predict `relist', reffects

	quietly gen double `phat' = `xbhat' if `touse'
	forvalues t = 1/`n_reterms' {
		quietly replace `phat' = `phat' + `_re`t'' if `touse'
	}
	quietly replace `phat' = invlogit(`phat') if `touse'

	// sort, assign group labels, create indicators
	tempvar orig_order cell_n gi rank_w grp

	quietly gen long `orig_order' = _n
	quietly bysort `touse' `all_ivars': gen long `cell_n' = _N if `touse'
	quietly gen long `gi' = floor(`cell_n' / `ngroups') if `touse'

	sort `touse' `all_ivars' `phat' `orig_order'
	quietly by `touse' `all_ivars': gen long `rank_w' = _n if `touse'
	quietly gen byte `grp' = min(`ngroups', ceil(`rank_w' / `gi')) if `touse'

	sort `orig_order'

	local indvars ""
	forvalues g = 2/`ngroups' {
		tempvar ind`g'
		quietly gen byte `ind`g'' = (`grp' == `g') if `touse'
		local indvars `indvars' `ind`g''
	}

	// augmented model re-fit — use preserve/restore to guarantee clean data state
	local _aug_ok = 1
	local chi2stat = .
	local df_test  = .
	local pvalue   = .

	preserve

		if "`est_opts'" != "" {
			local scan_pos = 1
			while strpos(substr("`re_spec'", `scan_pos', .), " || ") > 0 {
				local scan_pos = `scan_pos' + strpos(substr("`re_spec'", `scan_pos', .), " || ") + 3
			}
			local last_seg_only = strtrim(substr("`re_spec'", `scan_pos', .))
			local last_seg_has_comma = (strpos("`last_seg_only'", ",") > 0)
			if `last_seg_has_comma' {
				capture quietly melogit `depvar' `indepvars' `indvars' if `touse' `re_spec' `est_opts'
			}
			else {
				capture quietly melogit `depvar' `indepvars' `indvars' if `touse' `re_spec', `est_opts'
			}
		}
		else {
			capture quietly melogit `depvar' `indepvars' `indvars' if `touse' `re_spec'
		}
		if _rc != 0 | "`e(converged)'" == "0" {
			local _aug_ok = 0
		}

		// joint Wald test
		if `_aug_ok' {
			forvalues g = 2/`ngroups' {
				local test_expr `"`test_expr' (`ind`g'' = 0)"'
			}
			capture quietly test `test_expr'
			if _rc != 0 {
				local _aug_ok = 0
			}
			else {
				local chi2stat = r(chi2)
				local df_test  = r(df)
				local pvalue   = r(p)
				if missing(`chi2stat') local _aug_ok = 0
			}
		}

	restore

	// always restore baseline estimates after preserve/restore
	quietly estimates restore `base_est'
	quietly estimates drop `base_est'

	// if augmented model failed or returned missing results, exit cleanly
	if !`_aug_ok' | missing(`chi2stat') {
		di as error "{bf:mlm_gof} could not produce a result."
		di as error "This typically means that {bf:groups(`ngroups')} is set too large for the available data."
		di as error "Omit {bf:groups()} to use the data-driven default, or specify a smaller value of {bf:groups()}."
		exit 430
	}

	// display results
	local Gm1 = `ngroups' - 1

	local _lbl "Number of observations"
	di as txt "`_lbl'" _dup(`=30-length("`_lbl'")') " " " = " as res %9.0f `N'

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
		di as txt "  {bf:Model fits the data adequately}"
	}
	else {
		di as txt "  {bf:Model has a questionable fit}"
	}

	if `_any_warn' {
		di as txt ""
		forvalues _w = 1/`_nwarn' {
			di as txt "`_warn`_w''"
			di as txt "`_warn`_w'b'"
		}
	}

	// return results
	return scalar chi2    = `chi2stat'
	return scalar df      = `df_test'
	return scalar p       = `pvalue'
	return scalar N       = `N'
	return scalar groups  = `ngroups'
	return scalar levels  = `n_levels'
	return scalar reterms = `n_reterms'

end
