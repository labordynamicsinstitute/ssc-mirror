*! version 1.0.0  15mar2026
*! ivlpirf2 — IV Local Projection IRFs with Panel Data & Driscoll-Kraay
*! Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)
*! Based on Jordà (2005) and Driscoll-Kraay (1998)

capture program drop ivlpirf2
program define ivlpirf2, eclass sortpreserve
	version 14

	if replay() {
		Playback `0'
	}
	else {
		Estimate `0'
	}
end

program Playback
	syntax [, *]
	if ("`e(cmd)'" != "ivlpirf2") {
		di as err "results for {bf:ivlpirf2} not found"
		exit 301
	}
	else {
		Display, `options'
	}
end

* ─────────────────────────────────────────────────────────
*  Main estimation program
* ─────────────────────────────────────────────────────────
program define Estimate, eclass sortpreserve

	syntax varlist(ts fv) [if] [in] ,         ///
		ENDOGenous(string)                    ///
		[                                     ///
		STep(integer 4)                       ///
		LAgs(numlist min=1 sort integer >=0)  ///
		exog(varlist fv ts)                   ///
		VCE(string)                           ///
		FE                                    ///
		CUMULative                            ///
		noCONStant                            ///
		GRaph                                 ///
		LEVel(numlist sort)                   ///
		FIRSTstage                            ///
		NOTable                               ///
		TItle(string)                         ///
		SAVing(string)                        ///
		METHod(string)                        ///
		]

	* ── Parse endogenous(depvar = instruments) ──────────────
	ParseEndogenous `endogenous'
	local x    "`r(endog)'"
	local z    "`r(inst)'"
	local k_inst : word count `z'

	if (`k_inst' < 1) {
		di as err "at least one instrument required in {bf:endogenous()}"
		exit 198
	}

	* ── Response variables ──────────────────────────────────
	local y "`varlist'"
	local k_resp : word count `y'

	* ── Defaults ────────────────────────────────────────────
	if ("`lags'" == "") local lags 1 2
	if ("`level'" == "") local level 68 90 95

	if (`step' < 0) {
		di as err "option {bf:step()} requires a nonnegative integer"
		exit 198
	}

	* ── Parse method ────────────────────────────────────────
	if ("`method'" == "") local method "2sls"
	if ("`method'" != "2sls" & "`method'" != "gmm") {
		di as err "option {bf:method()} must be {bf:2sls} or {bf:gmm}"
		exit 198
	}

	* ── Determine data structure (panel vs time series) ─────
	qui tsset
	local timevar "`r(timevar)'"
	local panelvar "`r(panelvar)'"
	local is_panel = ("`panelvar'" != "")

	if ("`fe'" != "" & `is_panel' == 0) {
		di as err "option {bf:fe} requires panel data; use {bf:xtset} first"
		exit 198
	}

	* ── Parse VCE ───────────────────────────────────────────
	local vce_type "robust"     // default
	local vce_cluster ""
	local vce_dk = 0
	local vce_hac = 0
	local vce_hac_lags = 0

	if (`"`vce'"' != "") {
		local vce_first : word 1 of `vce'
		if ("`vce_first'" == "robust") {
			local vce_type "robust"
		}
		else if ("`vce_first'" == "cluster") {
			local vce_type "cluster"
			local vce_cluster : word 2 of `vce'
			if ("`vce_cluster'" == "") {
				di as err "option {bf:vce(cluster)} requires a variable name"
				exit 198
			}
		}
		else if ("`vce_first'" == "dkraay" | "`vce_first'" == "dk") {
			local vce_type "dkraay"
			local vce_dk = 1
			local dk_lags : word 2 of `vce'
			if ("`dk_lags'" == "") local dk_lags = 0
		}
		else if ("`vce_first'" == "hac") {
			local vce_type "hac"
			local vce_hac = 1
			local vce_hac_lags : word 3 of `vce'
			if ("`vce_hac_lags'" == "") local vce_hac_lags = 0
		}
		else if ("`vce_first'" == "conventional") {
			local vce_type "conventional"
		}
		else {
			di as err "option {bf:vce(`vce')} not recognized"
			exit 198
		}
	}

	* ── Check: DK requires panel + xtscc ────────────────────
	if (`vce_dk' == 1 & `is_panel' == 0) {
		di as err "vce(dkraay) requires panel data; use {bf:xtset} first"
		exit 198
	}

	* ── Build control variable list ─────────────────────────
	local y_ctrl `y' `x'
	if (`lags' == 0) {
		local ctrl `exog'
	}
	else {
		local ctrl ""
		foreach v of local y_ctrl {
			foreach l of local lags {
				local ctrl "`ctrl' L`l'.`v'"
			}
		}
		if ("`exog'" != "") {
			local ctrl "`ctrl' `exog'"
		}
	}

	* ── Sample ──────────────────────────────────────────────
	marksample touse
	markout `touse' `x' `z' `ctrl'

	qui tsreport if `touse'
	local e_tmin  = r(start)
	local e_tmax  = r(end)
	local e_tsfmt "`r(tsfmt)'"
	local e_tmins = trim(string(`e_tmin', "`e_tsfmt'"))
	local e_tmaxs = trim(string(`e_tmax', "`e_tsfmt'"))

	* ── First-stage diagnostics ─────────────────────────────
	if ("`firststage'" != "") {
		di
		di as txt "{hline 68}"
		di as txt "First-stage regression: `x' on instruments"
		di as txt "{hline 68}"

		if (`is_panel' & "`fe'" != "") {
			qui xtreg `x' `z' `ctrl' if `touse', fe
		}
		else {
			qui regress `x' `z' `ctrl' if `touse', `constant'
		}
		local fs_F = e(F)
		local fs_r2 = e(r2)
		qui test `z'
		local fs_Fexcl = r(F)
		local fs_pexcl = r(p)

		di as txt "  F-statistic (overall)    = " as res %9.3f `fs_F'
		di as txt "  R-squared                = " as res %9.4f `fs_r2'
		di as txt "  F-test (excl. instruments)  = " as res %9.3f `fs_Fexcl'
		di as txt "  p-value                     = " as res %9.4f `fs_pexcl'
		if (`fs_Fexcl' < 10) {
			di as err "  {bf:Warning:} F < 10 — potential weak instruments"
		}
		di as txt "{hline 68}"
	}

	* ══════════════════════════════════════════════════════════
	*  ESTIMATION
	* ══════════════════════════════════════════════════════════

	local n_coefs = (`step' + 1) * `k_resp'
	tempname bb VV
	tempname g_b g_se g_df
	mat `g_b'  = J(`step' + 1, `k_resp', 0)
	mat `g_se' = J(`step' + 1, `k_resp', 0)
	mat `g_df' = J(`step' + 1, `k_resp', 0)

	local stripe ""
	local N_est = 0

	if ("`method'" == "gmm") {
		* ══════════════════════════════════════════════════════
		*  GMM: Joint estimation (same as Stata 19 ivlpirf)
		*  Partial out controls, then estimate all horizons
		*  simultaneously via gmm
		* ══════════════════════════════════════════════════════

		* ── Partial out controls from LHS ────────────────────
		local j = 1
		local y_po ""
		tempvar y_adjust
		qui gen double `y_adjust' = .

		foreach v of local y {
			tempvar y_cum_g
			qui gen double `y_cum_g' = 0 if `touse'
			forvalues h = 0/`step' {
				local stripe "`stripe' `x':f`h'.`v'"
				tempvar lhs_`j'
				if ("`cumulative'" == "cumulative") {
					if (`h' == 0) {
						qui replace `y_adjust' = `v' if `touse'
					}
					else {
						qui replace `y_adjust' = ///
							`y_adjust' + F`h'.`v' if `touse'
					}
				}
				else {
					qui replace `y_adjust' = F`h'.`v' if `touse'
				}
				qui regress `y_adjust' `ctrl' if `touse', `constant'
				qui predict double `lhs_`j'', residuals
				local y_po "`y_po' `lhs_`j''"
				local ++j
			}
			qui drop `y_cum_g'
		}

		* ── Partial out controls from endogenous RHS ─────────
		tempvar x_po
		qui regress `x' `ctrl' if `touse', `constant'
		qui predict double `x_po', residuals

		* ── Partial out controls from instruments ─────────────
		local z_po ""
		local zi = 1
		foreach v of local z {
			tempvar z_`zi'
			qui regress `v' `ctrl' if `touse', `constant'
			qui predict double `z_`zi'', residuals
			local z_po "`z_po' `z_`zi''"
			local ++zi
		}

		* ── Set up GMM moment conditions ───────────────────
		local i = 1
		local main_spec ""
		local deriv_spec ""
		foreach v of local y_po {
			local main_spec "`main_spec' (`v' - {b`i'}*`x_po')"
			local deriv_spec "`deriv_spec' derivative(`i'/b`i' = -`x_po')"
			local ++i
		}

		* ── Collinearity check on instruments ─────────────
		qui _rmcoll `z_po', noconstant
		local inst_spec "instruments(`r(varlist)', noconstant)"

		* ── VCE for GMM ──────────────────────────────────
		local gmm_wmat "wmatrix(robust)"
		local gmm_vce ""
		if ("`vce_type'" == "robust") {
			local gmm_wmat "wmatrix(robust)"
		}
		else if ("`vce_type'" == "hac") {
			if (`vce_hac_lags' > 0) {
				local gmm_vce "vce(hac nw `vce_hac_lags')"
			}
			else {
				local gmm_vce "vce(hac nw)"
			}
		}
		else if ("`vce_type'" == "cluster") {
			local gmm_vce "vce(cluster `vce_cluster')"
		}
		else if ("`vce_type'" == "conventional") {
			local gmm_wmat "wmatrix(unadjusted)"
			local gmm_vce "vce(unadjusted)"
		}

		* ── Run GMM ──────────────────────────────────────
		gmm `main_spec' if `touse',     ///
			`deriv_spec'                ///
			`inst_spec'                 ///
			winitial(unadjusted, independent) ///
			`gmm_wmat' `gmm_vce'        ///
			fiterlogonly

		local N_est = e(N)
		tempname gmm_b gmm_V
		mat `gmm_b' = e(b)
		mat `gmm_V' = e(V)

		* ── Extract coefficients into storage matrices ────
		mat `bb' = `gmm_b'
		mat `VV' = `gmm_V'

		local col = 1
		local resp_idx = 1
		foreach resp of local y {
			forvalues h = 0/`step' {
				mat `g_b'[`h' + 1, `resp_idx'] = `gmm_b'[1, `col']
				mat `g_se'[`h' + 1, `resp_idx'] = sqrt(`gmm_V'[`col', `col'])
				mat `g_df'[`h' + 1, `resp_idx'] = `N_est'
				local ++col
			}
			local ++resp_idx
		}
	}
	else {
		* ══════════════════════════════════════════════════════
		*  2SLS: Per-horizon estimation (default)
		* ══════════════════════════════════════════════════════

		mat `bb' = J(1, `n_coefs', 0)
		mat `VV' = J(`n_coefs', `n_coefs', 0)
		local col = 1

		foreach resp of local y {
			tempvar y_cum
			qui gen double `y_cum' = 0 if `touse'

			forvalues h = 0/`step' {
				local stripe "`stripe' `x':f`h'.`resp'"

				tempvar lhs_h
				if ("`cumulative'" == "cumulative") {
					qui replace `y_cum' = `y_cum' + F`h'.`resp' if `touse'
					qui gen double `lhs_h' = `y_cum' if `touse'
				}
				else {
					qui gen double `lhs_h' = F`h'.`resp' if `touse'
				}

				local resp_idx = 0
				local rr = 1
				foreach rv of local y {
					if ("`rv'" == "`resp'") local resp_idx = `rr'
					local ++rr
				}

				if (`vce_dk' == 1) {
					if (`dk_lags' > 0) {
						qui xtscc `lhs_h' `x' `ctrl' if `touse', `fe' lag(`dk_lags')
					}
					else {
						qui xtscc `lhs_h' `x' `ctrl' if `touse', `fe'
					}
					local b_h = _b[`x']
					local se_h = _se[`x']
					local df_h = e(df_r)
				}
				else if (`is_panel' & "`fe'" != "") {
					if ("`vce_type'" == "cluster") {
						qui xtivreg `lhs_h' `ctrl' (`x' = `z') if `touse', fe vce(cluster `vce_cluster')
					}
					else if ("`vce_type'" == "robust") {
						qui xtivreg `lhs_h' `ctrl' (`x' = `z') if `touse', fe vce(robust)
					}
					else {
						qui xtivreg `lhs_h' `ctrl' (`x' = `z') if `touse', fe
					}
					local b_h = _b[`x']
					local se_h = _se[`x']
					local df_h = e(df_r)
				}
				else {
					if ("`vce_type'" == "robust") {
						qui ivregress 2sls `lhs_h' `ctrl' (`x' = `z') ///
							if `touse', `constant' vce(robust)
					}
					else if ("`vce_type'" == "cluster") {
						qui ivregress 2sls `lhs_h' `ctrl' (`x' = `z') ///
							if `touse', `constant' vce(cluster `vce_cluster')
					}
					else if ("`vce_type'" == "hac") {
						if (`vce_hac_lags' > 0) {
							qui ivregress 2sls `lhs_h' `ctrl' (`x' = `z') ///
								if `touse', `constant' vce(hac nw `vce_hac_lags')
						}
						else {
							qui ivregress 2sls `lhs_h' `ctrl' (`x' = `z') ///
								if `touse', `constant' vce(hac nw)
						}
					}
					else {
						qui ivregress 2sls `lhs_h' `ctrl' (`x' = `z') ///
							if `touse', `constant'
					}
					local b_h = _b[`x']
					local se_h = _se[`x']
					local df_h = e(df_r)
				}

				if (`h' == 0 & `resp_idx' == 1) local N_est = e(N)

				mat `bb'[1, `col'] = `b_h'
				mat `VV'[`col', `col'] = `se_h'^2
				mat `g_b'[`h' + 1, `resp_idx'] = `b_h'
				mat `g_se'[`h' + 1, `resp_idx'] = `se_h'
				mat `g_df'[`h' + 1, `resp_idx'] = `df_h'

				local ++col
				qui drop `lhs_h'
			}
			qui drop `y_cum'
		}
	}

	* ── Stripe matrices ─────────────────────────────────────
	mat colnames `bb' = `stripe'
	mat rownames `VV' = `stripe'
	mat colnames `VV' = `stripe'

	* ── Post results ────────────────────────────────────────
	ereturn post `bb' `VV', esample(`touse')

	ereturn local cmd "ivlpirf2"
	ereturn local cmdline `"ivlpirf2 `0'"'
	if ("`method'" == "gmm") {
		ereturn local title "IV local-projection IRFs (joint GMM)"
	}
	else {
		ereturn local title "IV local-projection IRFs (per-horizon 2SLS)"
	}
	ereturn local method "`method'"
	ereturn local depvar "`varlist'"
	ereturn local impulse "`x'"
	ereturn local responses "`y'"
	ereturn local instruments "`z'"
	ereturn local controls "`ctrl'"
	ereturn local exog "`exog'"
	ereturn local vce "`vce_type'"
	ereturn local tvar "`timevar'"
	if ("`panelvar'" != "") ereturn local pvar "`panelvar'"

	ereturn scalar N = `N_est'
	ereturn scalar step = `step'
	ereturn scalar k_impulses = 1
	ereturn scalar k_responses = `k_resp'
	ereturn scalar k_instruments = `k_inst'
	ereturn scalar k_controls = `: word count `ctrl''

	if ("`cumulative'" == "cumulative") {
		ereturn scalar cumul = 1
	}
	else {
		ereturn scalar cumul = 0
	}

	ereturn matrix irf_b = `g_b'
	ereturn matrix irf_se = `g_se'
	ereturn matrix irf_df = `g_df'

	* ── Display table ───────────────────────────────────────
	if ("`notable'" == "") {
		Display
	}

	* ── Graph ───────────────────────────────────────────────
	if ("`graph'" != "") {
		DrawGraph, level(`level') title(`title') saving(`saving')
	}

end

* ─────────────────────────────────────────────────────────
*  Parse endogenous(depvar = instruments)
* ─────────────────────────────────────────────────────────
program define ParseEndogenous, rclass
	local 0 `"`0'"'

	* Split on "="
	gettoken left right : 0, parse("=")
	gettoken eq right : right, parse("=")

	local left = strtrim("`left'")
	local right = strtrim("`right'")

	if ("`left'" == "" | "`right'" == "" | "`eq'" != "=") {
		di as err "option {bf:endogenous()} requires syntax: " ///
			"{it:depvar} = {it:instruments}"
		exit 198
	}

	return local endog "`left'"
	return local inst "`right'"
end

* ─────────────────────────────────────────────────────────
*  Display results table
* ─────────────────────────────────────────────────────────
program define Display

	local cumul = e(cumul)
	if (`cumul' == 1) {
		local irf_label "CIRF"
	}
	else {
		local irf_label "IRF"
	}

	di
	di as txt "{bf:`e(title)'}"
	di
	di as txt "Impulse variable:  " as res "`e(impulse)'"
	di as txt "Response variable" cond(e(k_responses)>1, "s: ", ":  ") ///
		as res "`e(responses)'"
	di as txt "Instruments:       " as res "`e(instruments)'"
	di as txt "VCE:               " as res "`e(vce)'"
	di as txt "Sample:            " as res "`e(N)' observations"
	di as txt "Max horizon:       " as res "`e(step)'"
	di

	* Table header
	di as txt "{hline 78}"
	di as txt %16s "`irf_label'" " {c |}" ///
		%12s "Coef." %12s "Std. Err." ///
		%10s "z" %10s "P>|z|" ///
		"   [95% Conf. Interval]"
	di as txt "{hline 16}{c +}{hline 61}"

	* Table body
	tempname b V
	mat `b' = e(b)
	mat `V' = e(V)
	local k = colsof(`b')

	local colnames : colnames `b'
	forvalues i = 1/`k' {
		local nm : word `i' of `colnames'
		local coef = `b'[1, `i']
		local se = sqrt(`V'[`i', `i'])
		if (`se' > 0) {
			local zval = `coef' / `se'
			local pval = 2 * normal(-abs(`zval'))
		}
		else {
			local zval = 0
			local pval = 1
		}
		local lo = `coef' - 1.96 * `se'
		local hi = `coef' + 1.96 * `se'

		di as txt %16s "`nm'" " {c |}" ///
			as res %12.6f `coef' %12.6f `se' ///
			%10.2f `zval' %10.3f `pval' ///
			%12.6f `lo' %12.6f `hi'
	}
	di as txt "{hline 78}"
end

* ─────────────────────────────────────────────────────────
*  Draw IRF graph with layered confidence bands
*  Style: cranberry shaded bands (68%, 90%, 95%)
*  Multi-panel grid for multiple responses (Saadaoui style)
* ─────────────────────────────────────────────────────────
program define DrawGraph

	syntax [, LEVel(numlist sort) TItle(string) SAVing(string)]

	if ("`level'" == "") local level 68 90 95

	tempname irf_b irf_se irf_df
	mat `irf_b'  = e(irf_b)
	mat `irf_se' = e(irf_se)
	mat `irf_df' = e(irf_df)

	local step = e(step)
	local k_resp = e(k_responses)
	local responses "`e(responses)'"
	local impulse "`e(impulse)'"

	local cumul = e(cumul)
	if (`cumul' == 1) {
		local ytitle_prefix "Cumulative response"
	}
	else {
		local ytitle_prefix "Response"
	}

	* ── xlabel for all panels ───────────────────────────────
	local xlab ""
	if (`step' <= 8) {
		forvalues hh = 0/`step' {
			local xlab "`xlab' `hh'"
		}
	}
	else if (`step' <= 24) {
		local xlab_step = cond(`step' > 16, 4, 2)
		forvalues hh = 0(`xlab_step')`step' {
			local xlab "`xlab' `hh'"
		}
	}
	else {
		forvalues hh = 0(6)`step' {
			local xlab "`xlab' `hh'"
		}
	}

	* ── Determine plotting layout ───────────────────────────
	local use_grid = (`k_resp' > 1)
	local graph_list ""

	* ── Loop over response variables ────────────────────────
	local resp_idx = 1
	foreach resp of local responses {

		preserve
		qui drop _all
		qui set obs `= `step' + 1'
		qui gen h = _n - 1
		qui gen double b = .
		qui gen double se = .
		qui gen double df = .

		forvalues hh = 0/`step' {
			qui replace b  = `irf_b'[`hh' + 1, `resp_idx'] in `= `hh' + 1'
			qui replace se = `irf_se'[`hh' + 1, `resp_idx'] in `= `hh' + 1'
			qui replace df = `irf_df'[`hh' + 1, `resp_idx'] in `= `hh' + 1'
		}

		* ── Build CIs for each level ────────────────────────
		local n_levels : word count `level'

		foreach lev of local level {
			local alpha = (100 - `lev') / 200
			local zcrit = invnormal(1 - `alpha')
			qui gen double lo`lev' = b - `zcrit' * se
			qui gen double hi`lev' = b + `zcrit' * se
		}

		* ── Build twoway plot layers ────────────────────────
		local plot_cmd ""
		local legend_labels ""
		local plot_num = 0

		* Sort levels descending for outer-to-inner plotting
		local rev_levels ""
		foreach lev of local level {
			local rev_levels "`lev' `rev_levels'"
		}

		* Opacity gradient: outer=30%, middle=50%, inner=70%
		local opacities ""
		if (`n_levels' == 1) {
			local opacities "50"
		}
		else if (`n_levels' == 2) {
			local opacities "30 60"
		}
		else if (`n_levels' == 3) {
			local opacities "30 50 70"
		}
		else {
			forvalues i = 1/`n_levels' {
				local op = 10 + (`i' - 1) * 30 / (`n_levels' - 1)
				local opacities "`opacities' `op'"
			}
		}

		local op_idx = 1
		foreach lev of local rev_levels {
			local ++plot_num
			local op : word `op_idx' of `opacities'
			local plot_cmd `"`plot_cmd' (rarea hi`lev' lo`lev' h, sort fcolor(cranberry%`op') lcolor(cranberry) lwidth(vvthin))"'
			local legend_labels `"`legend_labels' `plot_num' "`lev'% CI""'
			local ++op_idx
		}

		* IRF line
		local ++plot_num
		local plot_cmd `"`plot_cmd' (line b h, sort lcolor(cranberry) lwidth(medthick))"'
		local legend_labels `"`legend_labels' `plot_num' "IRF""'

		* ── Panel-specific titles & options ──────────────────
		local gname "irf_`resp'"
		local graph_list "`graph_list' `gname'"

		if (`use_grid') {
			* Multi-panel: column header on top, shock label on left
			local panel_title "Response: `resp'"
			if (`resp_idx' == 1) {
				local panel_ytitle "Shock: `impulse'"
			}
			else {
				local panel_ytitle ""
			}
			* x-axis label only on last panel
			if (`resp_idx' == `k_resp') {
				local panel_xtitle "Horizon"
			}
			else {
				local panel_xtitle ""
			}
			local nodraw_opt "nodraw"
			local legend_opt "legend(off)"
		}
		else {
			* Single-response: standard titles
			if ("`title'" != "") {
				local panel_title "`title'"
			}
			else {
				local panel_title "`ytitle_prefix' of `resp' to `impulse' shock"
			}
			local panel_ytitle "`ytitle_prefix' of `resp'"
			local panel_xtitle "Horizon"
			local nodraw_opt ""
			local legend_opt "legend(order(`legend_labels') rows(1) size(small))"
		}

		* ── Draw individual panel ───────────────────────────
		twoway `plot_cmd' , ///
			yline(0, lpattern(dash) lcolor(gs10)) ///
			xlabel(`xlab') ///
			xscale(range(0 `step')) ///
			xtitle("`panel_xtitle'", size(small)) ///
			ytitle("`panel_ytitle'", size(small) margin(r=2)) ///
			title("`panel_title'", size(medium)) ///
			`legend_opt' ///
			graphregion(color(white)) ///
			plotregion(color(white)) ///
			ysize(4) xsize(4) ///
			name(`gname', replace) `nodraw_opt'

		restore
		local ++resp_idx
	}

	* ── Combine into grid if multiple responses ─────────────
	if (`use_grid') {
		if ("`title'" == "") {
			local grid_title "IV-LP IRF: `impulse' shock"
		}
		else {
			local grid_title "`title'"
		}

		graph combine `graph_list', ///
			cols(`k_resp') ///
			title("`grid_title'", size(medlarge)) ///
			b1title("Horizon", size(small)) ///
			graphregion(color(white)) ///
			imargin(small) ///
			ysize(4) xsize(`= 3 * `k_resp'') ///
			name(irf_combined, replace)

		* Add a note about confidence bands
		local ci_note ""
		foreach lev of local level {
			if ("`ci_note'" == "") {
				local ci_note "`lev'%"
			}
			else {
				local ci_note "`ci_note'/`lev'%"
			}
		}
		di as txt "  Note: Shaded bands show `ci_note' confidence intervals."
	}

	* ── Save graph if requested ─────────────────────────────
	if ("`saving'" != "") {
		if (`use_grid') {
			qui graph export "`saving'.png", as(png) width(3000) replace
		}
		else {
			qui graph export "`saving'.png", as(png) width(3000) replace
		}
	}
end
