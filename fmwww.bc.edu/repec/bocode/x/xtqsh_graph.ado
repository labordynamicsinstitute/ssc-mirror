*! xtqsh_graph v1.0.0 — Premium visualization suite for xtqsh
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Date: February 2026
*! 5 graphs: P-Value Process, Marginal Heatmap, Coefficient Fan Chart,
*!           MD-QR Process with CI, Summary Dashboard

capture program drop xtqsh_graph
program define xtqsh_graph
	version 15.1
	syntax , TAU(numlist >0 <1 sort) K(integer) ///
		DEPVAR(string) INDEPVARS(string) ///
		NPANELS(integer) [MARGinal]
	
	local ntau : word count `tau'
	
	di
	di in smcl in gr "{hline 78}"
	di in smcl in gr ///
		"  {bf:╔══════════════════════════════════════════════════════════════════════╗}"
	di in smcl in gr "  {bf:║}" _col(5) in ye ///
		"        XTQSH VISUALIZATION SUITE" ///
		_col(72) in gr "{bf:║}"
	di in smcl in gr ///
		"  {bf:╚══════════════════════════════════════════════════════════════════════╝}"
	di in smcl in gr "{hline 78}"
	
	if `ntau' < 2 {
		di in gr "  (Graphs require ≥2 quantiles for meaningful visualization)"
		di in gr "  (Skipping graph generation)"
		di in smcl in gr "{hline 78}"
		exit
	}
	
	* ================================================================
	* Graph 1: P-Value Process Plot
	* ================================================================
	capture noisily _xtqsh_plot_pvalue_process, tau(`tau')
	
	* ================================================================
	* Graph 2: Marginal P-Value Heatmap (if marginal tests available)
	* ================================================================
	if "`marginal'" != "" {
		capture matrix list e(pval_D_marginal)
		if _rc == 0 {
			capture noisily _xtqsh_plot_marginal_heatmap, ///
				tau(`tau') k(`k') indepvars(`indepvars')
		}
	}
	
	* ================================================================
	* Graph 3: Coefficient Distribution Fan Chart (Figure 1 in paper)
	* ================================================================
	capture noisily _xtqsh_plot_fan_chart, ///
		tau(`tau') k(`k') indepvars(`indepvars') npanels(`npanels')
	
	* ================================================================
	* Graph 4: MD-QR Coefficient Process with CI
	* ================================================================
	capture noisily _xtqsh_plot_md_process, ///
		tau(`tau') k(`k') indepvars(`indepvars')
	
	* ================================================================
	* Graph 5: Summary Dashboard
	* ================================================================
	capture noisily _xtqsh_plot_dashboard, ///
		tau(`tau') k(`k') indepvars(`indepvars') npanels(`npanels')
	
	di in smcl in gr "{hline 78}"
	di in gr "  Graphs saved. Use " in ye "{bf:graph dir}" in gr " to list."
	di in gr "  Export: " in ye ///
		"{bf:graph export file.png, name(xtqsh_*) replace}"
	di in smcl in gr "{hline 78}"
	di
end


* ================================================================
* GRAPH 1: P-VALUE PROCESS — p(Ŝ) and p(D̂) across quantiles
* ================================================================
capture program drop _xtqsh_plot_pvalue_process
program define _xtqsh_plot_pvalue_process
	syntax , TAU(numlist)
	
	local ntau : word count `tau'
	
	tempname pS_mat pD_mat
	matrix `pS_mat' = e(pval_S)
	matrix `pD_mat' = e(pval_D)
	
	preserve
	clear
	qui set obs `ntau'
	
	qui gen double tau_val = .
	qui gen double pval_S = .
	qui gen double pval_D = .
	
	local t = 0
	foreach tauval of local tau {
		local ++t
		qui replace tau_val = `tauval' in `t'
		qui replace pval_S = `pS_mat'[1, `t'] in `t'
		qui replace pval_D = `pD_mat'[1, `t'] in `t'
	}
	
	* Cap extreme values for display
	qui replace pval_S = min(pval_S, 1.05)
	qui replace pval_D = min(pval_D, 1.05)
	
	* Add OLS mean-based test as point
	local pS_ols = e(pval_S_ols)
	local pD_ols = e(pval_D_ols)
	
	capture {
		twoway (connected pval_S tau_val, ///
				lcolor("0 100 180") mcolor("0 100 180") ///
				lwidth(medthick) msymbol(circle) msize(medsmall) ///
				lpattern(solid)) ///
			   (connected pval_D tau_val, ///
				lcolor("200 60 60") mcolor("200 60 60") ///
				lwidth(medthick) msymbol(diamond) msize(medsmall) ///
				lpattern(dash)) ///
			   , ///
			yline(0.01, lcolor("200 60 60%40") lpattern(shortdash) ///
				lwidth(thin)) ///
			yline(0.05, lcolor("220 130 30%50") lpattern(shortdash) ///
				lwidth(thin)) ///
			yline(0.10, lcolor("100 160 60%40") lpattern(shortdash) ///
				lwidth(thin)) ///
			title("{bf:Slope Homogeneity Test — P-Value Process}", ///
				size(medium) color(black)) ///
			subtitle("Joint test across all covariates", size(small)) ///
			xtitle("Quantile (τ)", size(small)) ///
			ytitle("p-value", size(small)) ///
			ylabel(0(0.1)1, labsize(vsmall) grid glcolor(gs14%30)) ///
			xlabel(, labsize(vsmall)) ///
			text(0.01 0.92 "1%", size(vsmall) color("200 60 60%80")) ///
			text(0.05 0.92 "5%", size(vsmall) color("220 130 30%80")) ///
			text(0.10 0.92 "10%", size(vsmall) color("100 160 60%80")) ///
			graphregion(fcolor(white) color(white)) ///
			plotregion(margin(small) fcolor(white)) ///
			legend(order(1 "Ŝ (Swamy)" 2 "D̂ (Std. Swamy)") ///
				size(vsmall) rows(1) position(6) ///
				region(lcolor(gs14) fcolor(white))) ///
			note("XTQSH v1.0.0 — Galvao et al. (2017)", ///
				size(vsmall) color(gs8)) ///
			name(xtqsh_pvalue, replace)
	}
	if _rc == 0 {
		di in gr "  ✓ " in ye "xtqsh_pvalue" ///
			in gr " — p-value process plot"
	}
	
	restore
end


* ================================================================
* GRAPH 2: MARGINAL P-VALUE HEATMAP
* ================================================================
capture program drop _xtqsh_plot_marginal_heatmap
program define _xtqsh_plot_marginal_heatmap
	syntax , TAU(numlist) K(integer) INDEPVARS(string)
	
	local ntau : word count `tau'
	
	tempname pD_marg
	matrix `pD_marg' = e(pval_D_marginal)
	
	* ---- Compute tile boundaries (half-distance between quantiles) ----
	local t = 0
	foreach tauval of local tau {
		local ++t
		local tau_`t' = `tauval'
	}
	
	forvalues t = 1/`ntau' {
		if `t' == 1 {
			if `ntau' > 1 {
				local half = (`tau_2' - `tau_1') / 2
			}
			else {
				local half = 0.05
			}
			local xleft_`t' = `tau_1' - `half'
			local xright_`t' = `tau_1' + `half'
		}
		else if `t' == `ntau' {
			local tm1 = `t' - 1
			local half = (`tau_`t'' - `tau_`tm1'') / 2
			local xleft_`t' = `tau_`t'' - `half'
			local xright_`t' = `tau_`t'' + `half'
		}
		else {
			local tm1 = `t' - 1
			local tp1 = `t' + 1
			local xleft_`t' = (`tau_`tm1'' + `tau_`t'') / 2
			local xright_`t' = (`tau_`t'' + `tau_`tp1'') / 2
		}
	}
	
	* ---- Build dataset: each obs is one tile ----
	preserve
	clear
	local ncells = `k' * `ntau'
	qui set obs `ncells'
	
	qui gen double xmid = .
	qui gen double ymid = .
	qui gen double ybot = .
	qui gen double ytop = .
	qui gen double pval = .
	qui gen int sig_cat = .
	qui gen double bw = .
	qui gen str8 pvlabel = ""
	
	local idx = 0
	forvalues j = 1/`k' {
		local t = 0
		foreach tauval of local tau {
			local ++t
			local ++idx
			
			local xl = `xleft_`t''
			local xr = `xright_`t''
			qui replace xmid   = (`xl' + `xr') / 2 in `idx'
			qui replace bw     = `xr' - `xl'       in `idx'
			qui replace ybot   = `j' - 0.45        in `idx'
			qui replace ytop   = `j' + 0.45        in `idx'
			qui replace ymid   = `j'               in `idx'
			
			local pv = `pD_marg'[`j', `t']
			qui replace pval = `pv' in `idx'
			
			local pvs : di %5.3f `pv'
			local pvs = strtrim("`pvs'")
			qui replace pvlabel = "`pvs'" in `idx'
			
			if `pv' < 0.01 {
				qui replace sig_cat = 1 in `idx'
			}
			else if `pv' < 0.05 {
				qui replace sig_cat = 2 in `idx'
			}
			else if `pv' < 0.10 {
				qui replace sig_cat = 3 in `idx'
			}
			else {
				qui replace sig_cat = 4 in `idx'
			}
		}
	}
	
	* ---- Compute a common bar width (use first cell's width) ----
	qui su bw in 1/1
	local common_bw = r(mean)
	
	* ---- Y-axis labels ----
	local ylbl ""
	forvalues j = 1/`k' {
		local vname : word `j' of `indepvars'
		local ylbl `"`ylbl' `j' "`vname'""'
	}
	
	* ---- X-axis labels ----
	local xlbl ""
	foreach tauval of local tau {
		local xlbl `"`xlbl' `tauval'"'
	}
	
	* ---- Draw heatmap: 4 rbar layers + 2 scatter-label layers ----
	* No dynamic command construction — all layers are fixed.
	* Labels use scatter with mlabel() so text comes from dataset vars.
	* sig_cat 3 (amber) gets black text; all others get white text.
	capture {
		twoway (rbar ybot ytop xmid if sig_cat == 1, ///
				barwidth(`common_bw') ///
				fcolor("180 30 30") lcolor("180 30 30%60") lwidth(thin)) ///
			   (rbar ybot ytop xmid if sig_cat == 2, ///
				barwidth(`common_bw') ///
				fcolor("220 100 30") lcolor("220 100 30%60") lwidth(thin)) ///
			   (rbar ybot ytop xmid if sig_cat == 3, ///
				barwidth(`common_bw') ///
				fcolor("230 190 60") lcolor("230 190 60%60") lwidth(thin)) ///
			   (rbar ybot ytop xmid if sig_cat == 4, ///
				barwidth(`common_bw') ///
				fcolor("50 150 80") lcolor("50 150 80%60") lwidth(thin)) ///
			   (scatter ymid xmid if sig_cat != 3, ///
				msymbol(none) mlabel(pvlabel) mlabposition(0) ///
				mlabsize(small) mlabcolor(white)) ///
			   (scatter ymid xmid if sig_cat == 3, ///
				msymbol(none) mlabel(pvlabel) mlabposition(0) ///
				mlabsize(small) mlabcolor(black)) ///
			   , ///
			title("{bf:Marginal Slope Homogeneity — P-Value Heatmap}", ///
				size(medium) color(black)) ///
			subtitle("D̂ test p-values by variable × quantile", ///
				size(small)) ///
			xtitle("Quantile (τ)", size(small)) ///
			ytitle("Variable", size(small)) ///
			ylabel(`ylbl', labsize(small) angle(0) nogrid) ///
			xlabel(`xlbl', labsize(small)) ///
			yscale(range(0.3 `= `k' + 0.7')) ///
			graphregion(fcolor(white) color(white)) ///
			plotregion(margin(small) fcolor(white)) ///
			legend(order(1 "p<0.01 (Reject)" ///
				2 "p<0.05 (Reject)" ///
				3 "p<0.10 (Weak)" ///
				4 "p≥0.10 (Accept)") ///
				size(vsmall) rows(1) position(6) ///
				region(lcolor(gs14) fcolor(white))) ///
			note("XTQSH v1.0.0", size(vsmall) color(gs8)) ///
			name(xtqsh_heatmap, replace)
	}
	if _rc == 0 {
		di in gr "  ✓ " in ye "xtqsh_heatmap" ///
			in gr " — marginal p-value heatmap"
	}
	else {
		di in gr "  ✗ heatmap failed with rc = " _rc
	}
	
	restore
end


* ================================================================
* GRAPH 3: COEFFICIENT DISTRIBUTION FAN CHART
* (Replicates Figure 1 from the paper)
* ================================================================
capture program drop _xtqsh_plot_fan_chart
program define _xtqsh_plot_fan_chart
	syntax , TAU(numlist) K(integer) INDEPVARS(string) NPANELS(integer)
	
	local ntau : word count `tau'
	
	tempname beta_all_mat beta_md_mat beta_ols_mat
	matrix `beta_all_mat' = e(beta_all)
	matrix `beta_md_mat' = e(beta_md)
	matrix `beta_ols_mat' = e(beta_ols)
	
	preserve
	clear
	
	* For each variable, compute percentiles of β̂_i across panels
	* Percentiles: 5, 10, 20, 80, 90, 95 (as in Figure 1 of the paper)
	local obs_needed = max(`ntau' * `k', `npanels')
	qui set obs `obs_needed'
	
	qui gen double tau_val = .
	qui gen int var_id = .
	qui gen double p05 = .
	qui gen double p10 = .
	qui gen double p20 = .
	qui gen double p50 = .
	qui gen double p80 = .
	qui gen double p90 = .
	qui gen double p95 = .
	qui gen double md_est = .
	qui gen double ols_est = .
	
	local idx = 0
	forvalues j = 1/`k' {
		local t = 0
		foreach tauval of local tau {
			local ++t
			local ++idx
			
			qui replace tau_val = `tauval' in `idx'
			qui replace var_id = `j' in `idx'
			
			* MD estimate
			qui replace md_est = `beta_md_mat'[`t', `j'] in `idx'
			
			* Collect β̂_i values for this variable and quantile
			local bcol = (`t' - 1) * `k' + `j'
			
			* Store in a tempvar to compute percentiles
			tempvar bvals
			qui gen double `bvals' = .
			local valid_n = 0
			forvalues i = 1/`npanels' {
				local bv = `beta_all_mat'[`i', `bcol']
				if `bv' != . {
					local ++valid_n
					qui replace `bvals' = `bv' in `valid_n'
				}
			}
			
			if `valid_n' >= 10 {
				qui _pctile `bvals' in 1/`valid_n', ///
					percentiles(5 10 20 50 80 90 95)
				qui replace p05 = r(r1) in `idx'
				qui replace p10 = r(r2) in `idx'
				qui replace p20 = r(r3) in `idx'
				qui replace p50 = r(r4) in `idx'
				qui replace p80 = r(r5) in `idx'
				qui replace p90 = r(r6) in `idx'
				qui replace p95 = r(r7) in `idx'
			}
			
			drop `bvals'
		}
		
		* OLS mean estimate for this variable  
		* Compute mean of individual OLS betas
		local ols_sum = 0
		local ols_n = 0
		forvalues i = 1/`npanels' {
			local bv = `beta_ols_mat'[`i', `j']
			if `bv' != . {
				local ols_sum = `ols_sum' + `bv'
				local ++ols_n
			}
		}
		if `ols_n' > 0 {
			local ols_mean = `ols_sum' / `ols_n'
			forvalues t = 1/`ntau' {
				local row = (`j' - 1) * `ntau' + `t'
				qui replace ols_est = `ols_mean' in `row'
			}
		}
	}
	
	* Create individual graph for each variable
	local colors `" "0 100 180" "200 60 60" "100 60 200" "0 140 100" "220 130 30" "200 60 140" "50 100 220" "'
	
	local graph_list ""
	forvalues j = 1/`k' {
		local vname : word `j' of `indepvars'
		local col_idx = mod(`j' - 1, 7) + 1
		local this_color : word `col_idx' of `colors'
		local gname "xtqsh_fan_`j'"
		
		capture {
			twoway (rarea p05 p95 tau_val if var_id == `j', ///
					fcolor("`this_color'%10") lwidth(none)) ///
				   (rarea p10 p90 tau_val if var_id == `j', ///
					fcolor("`this_color'%18") lwidth(none)) ///
				   (rarea p20 p80 tau_val if var_id == `j', ///
					fcolor("`this_color'%28") lwidth(none)) ///
				   (connected p50 tau_val if var_id == `j', ///
					lcolor("`this_color'") mcolor("`this_color'") ///
					lwidth(medthick) msymbol(circle) msize(small)) ///
				   (connected md_est tau_val if var_id == `j', ///
					lcolor("`this_color'%60") mcolor("`this_color'%60") ///
					lwidth(medium) msymbol(circle_hollow) msize(small) ///
					lpattern(solid)) ///
				   (line ols_est tau_val if var_id == `j', ///
					lcolor(gs6) lpattern(dash) lwidth(medium)) ///
				   , ///
				title("{bf:`vname'}", size(medium) color(black)) ///
				subtitle("Distribution of β̂ᵢ across panels", ///
					size(small)) ///
				xtitle("Quantile (τ)", size(small)) ///
				ytitle("Coefficient", size(small)) ///
				graphregion(fcolor(white) color(white)) ///
				plotregion(margin(small) fcolor(white)) ///
				legend(order(4 "Median β̂ᵢ" 5 "MD-QR β̂" 6 "OLS" ///
					3 "20–80th pctile" ///
					2 "10–90th pctile" ///
					1 "5–95th pctile") ///
					size(vsmall) rows(2) position(6) ///
					region(lcolor(gs14) fcolor(white))) ///
				name(`gname', replace) nodraw
		}
		if _rc == 0 {
			local graph_list "`graph_list' `gname'"
			di in gr "  ✓ " in ye "`gname'" ///
				in gr " — `vname' coefficient fan chart"
		}
	}
	
	* Combine
	if "`graph_list'" != "" {
		local ngraphs : word count `graph_list'
		local ncols = min(`ngraphs', 3)
		capture {
			graph combine `graph_list', ///
				title("{bf:Coefficient Distribution Fan Chart}", ///
					size(medlarge) color(black)) ///
				subtitle("Percentiles of firm-specific β̂ᵢ across quantiles" ///
					" (cf. Galvao et al. 2017, Figure 1)", ///
					size(small)) ///
				note("XTQSH v1.0.0", size(vsmall) color(gs8)) ///
				cols(`ncols') ///
				graphregion(fcolor(white) color(white)) ///
				name(xtqsh_fan_combined, replace)
		}
		if _rc == 0 {
			di in gr "  ✓ " in ye "xtqsh_fan_combined" ///
				in gr " — combined fan chart"
		}
	}
	
	restore
end


* ================================================================
* GRAPH 4: MD-QR COEFFICIENT PROCESS with CI
* ================================================================
capture program drop _xtqsh_plot_md_process
program define _xtqsh_plot_md_process
	syntax , TAU(numlist) K(integer) INDEPVARS(string)
	
	local ntau : word count `tau'
	
	tempname beta_md_mat beta_se_mat
	matrix `beta_md_mat' = e(beta_md)
	matrix `beta_se_mat' = e(beta_md_se)
	
	preserve
	clear
	qui set obs `= `ntau' * `k''
	
	qui gen double tau_val = .
	qui gen int var_id = .
	qui gen double est = .
	qui gen double lo = .
	qui gen double hi = .
	
	local idx = 0
	forvalues j = 1/`k' {
		local t = 0
		foreach tauval of local tau {
			local ++t
			local ++idx
			qui replace tau_val = `tauval' in `idx'
			qui replace var_id = `j' in `idx'
			local b = `beta_md_mat'[`t', `j']
			local se = `beta_se_mat'[`t', `j']
			qui replace est = `b' in `idx'
			if `se' != . & `se' > 0 {
				qui replace lo = `b' - 1.96 * `se' in `idx'
				qui replace hi = `b' + 1.96 * `se' in `idx'
			}
		}
	}
	
	local colors `" "0 128 128" "220 80 50" "100 60 200" "200 60 140" "50 100 220" "0 140 100" "220 130 30" "'
	
	local graph_list ""
	forvalues j = 1/`k' {
		local vname : word `j' of `indepvars'
		local col_idx = mod(`j' - 1, 7) + 1
		local this_color : word `col_idx' of `colors'
		local gname "xtqsh_mdqr_`j'"
		
		capture {
			twoway (rarea lo hi tau_val if var_id == `j', ///
					fcolor("`this_color'%20") lcolor("`this_color'%40") ///
					lwidth(thin)) ///
				   (connected est tau_val if var_id == `j', ///
					lcolor("`this_color'") mcolor("`this_color'") ///
					lwidth(medthick) msymbol(circle) msize(small)), ///
				title("{bf:β̂_MD(`vname', τ)}", size(medium) color(black)) ///
				subtitle("Minimum Distance QR with 95% CI", size(small)) ///
				xtitle("Quantile (τ)", size(small)) ///
				ytitle("MD-QR Coefficient", size(small)) ///
				yline(0, lcolor(gs12) lpattern(dash) lwidth(thin)) ///
				graphregion(fcolor(white) color(white)) ///
				plotregion(margin(small) fcolor(white)) ///
				legend(order(2 "β̂_MD(τ)" 1 "95% CI") ///
					size(vsmall) rows(1) position(6) ///
					region(lcolor(gs14) fcolor(white))) ///
				name(`gname', replace) nodraw
		}
		if _rc == 0 {
			local graph_list "`graph_list' `gname'"
			di in gr "  ✓ " in ye "`gname'" ///
				in gr " — β̂_MD(`vname') quantile process"
		}
	}
	
	* Combine
	if "`graph_list'" != "" {
		local ngraphs : word count `graph_list'
		local ncols = min(`ngraphs', 3)
		capture {
			graph combine `graph_list', ///
				title("{bf:MD-QR Quantile Process}", ///
					size(medlarge) color(black)) ///
				subtitle("β̂_MD(τ) = (ΣV̂ᵢ⁻¹)⁻¹ΣV̂ᵢ⁻¹β̂ᵢ with 95% CI", ///
					size(small)) ///
				note("XTQSH v1.0.0 — Galvao et al. (2017)", ///
					size(vsmall) color(gs8)) ///
				cols(`ncols') ///
				graphregion(fcolor(white) color(white)) ///
				name(xtqsh_mdqr_combined, replace)
		}
		if _rc == 0 {
			di in gr "  ✓ " in ye "xtqsh_mdqr_combined" ///
				in gr " — combined MD-QR process"
		}
	}
	
	restore
end


* ================================================================
* GRAPH 5: SUMMARY DASHBOARD — combined overview
* ================================================================
capture program drop _xtqsh_plot_dashboard
program define _xtqsh_plot_dashboard
	syntax , TAU(numlist) K(integer) INDEPVARS(string) NPANELS(integer)
	
	* Combine the p-value process and fan chart (first variable) into
	* a summary dashboard
	
	local have_pval = 0
	local have_fan = 0
	local have_mdqr = 0
	
	capture graph describe xtqsh_pvalue
	if _rc == 0 local have_pval = 1
	
	capture graph describe xtqsh_fan_1
	if _rc == 0 local have_fan = 1
	
	capture graph describe xtqsh_mdqr_1
	if _rc == 0 local have_mdqr = 1
	
	local dash_list ""
	if `have_pval' local dash_list "`dash_list' xtqsh_pvalue"
	if `have_mdqr' local dash_list "`dash_list' xtqsh_mdqr_1"
	if `have_fan' local dash_list "`dash_list' xtqsh_fan_1"
	
	if "`dash_list'" != "" {
		capture {
			graph combine `dash_list', ///
				title("{bf:XTQSH — Slope Homogeneity Test Summary}", ///
					size(medlarge) color(black)) ///
				subtitle("`e(depvar)' — n = `npanels' panels, k = `k' vars", ///
					size(small)) ///
				note("Galvao, Juhl, Montes-Rojas & Olmo (2017)" ///
					" | XTQSH v1.0.0 — Dr Merwan Roudane", ///
					size(vsmall) color(gs8)) ///
				cols(2) rows(2) ///
				graphregion(fcolor(white) color(white)) ///
				name(xtqsh_dashboard, replace)
		}
		if _rc == 0 {
			di in gr "  ✓ " in ye "xtqsh_dashboard" ///
				in gr " — summary dashboard"
		}
	}
end


exit
