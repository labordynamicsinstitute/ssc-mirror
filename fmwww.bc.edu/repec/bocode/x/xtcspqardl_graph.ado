*! xtcspqardl_graph v1.0.0 — Premium visualization suite
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Date: February 2026
*! 6 graphs: Quantile Process, ECT Heatmap, Half-Life, LR Comparison,
*!           SR Process, Lambda/Rho Process
*! Called internally by xtcspqardl.ado via the 'graph' option

capture program drop xtcspqardl_graph
program define xtcspqardl_graph
	version 15.1
	syntax , TAU(numlist >0 <1 sort) K(integer) ///
		DEPVAR(string) INDEPVARS(string) ///
		ESTIMATOR(string) ///
		[NPANELS(integer 0) IVAR(string) ECM ///
		 LRVARS(string)]
	
	local ntau : word count `tau'
	
	di
	di in smcl in gr "{hline 78}"
	di in smcl in gr "  {bf:╔══════════════════════════════════════════════════════════════════════╗}"
	di in smcl in gr "  {bf:║           XTCSPQARDL VISUALIZATION SUITE                           ║}"
	di in smcl in gr "  {bf:╚══════════════════════════════════════════════════════════════════════╝}"
	di in smcl in gr "{hline 78}"
	
	if `ntau' < 2 {
		di in gr "  (Graphs require ≥2 quantiles for meaningful visualization)"
		di in gr "  (Skipping graph generation)"
		di in smcl in gr "{hline 78}"
		exit
	}
	
	* ================================================================
	* Graph 1: Short-Run Quantile Process
	* ================================================================
	if inlist("`estimator'", "qccemg", "qccepmg") {
		capture noisily _xtcsg_plot_qccemg_process, tau(`tau') k(`k') ///
			depvar(`depvar') indepvars(`indepvars')
	}
	else {
		capture noisily _xtcsg_plot_cspqardl_sr, tau(`tau') k(`k') ///
			indepvars(`indepvars')
	}
	
	* ================================================================
	* Graph 1b: Long-Run Quantile Process
	* ================================================================
	if inlist("`estimator'", "qccemg", "qccepmg") {
		capture noisily _xtcsg_plot_qccemg_lr, tau(`tau') k(`k') ///
			indepvars(`indepvars')
	}
	else {
		capture noisily _xtcsg_plot_cspqardl_beta, tau(`tau') k(`k') ///
			indepvars(`indepvars') lrvars(`lrvars') `ecm'
	}
	
	* ================================================================
	* Graph 2: ECT/Rho Heatmap (CS-PQARDL only)
	* ================================================================
	if !inlist("`estimator'", "qccemg", "qccepmg") & `npanels' > 0 {
		capture matrix list e(rho_all)
		if _rc == 0 {
			capture noisily _xtcsg_plot_ect_heatmap, tau(`tau') ///
				npanels(`npanels') `ecm'
		}
	}
	
	* ================================================================
	* Graph 3: Half-Life Bar Chart
	* ================================================================
	capture matrix list e(halflife_mg)
	if _rc == 0 {
		capture noisily _xtcsg_plot_halflife, tau(`tau') ///
			estimator(`estimator')
	}
	
	* ================================================================
	* Graph 4: Lambda/Rho Process
	* ================================================================
	if inlist("`estimator'", "qccemg", "qccepmg") {
		capture noisily _xtcsg_plot_lambda_process, tau(`tau')
	}
	else {
		capture noisily _xtcsg_plot_rho_process, tau(`tau') `ecm'
	}
	
	di in smcl in gr "{hline 78}"
	di in gr "  Graphs saved. Use " in ye "{bf:graph dir}" in gr " to list."
	di in gr "  Export: " in ye "{bf:graph export file.png, name(xtcspq_*) replace}"
	di in smcl in gr "{hline 78}"
	di
end


* ================================================================
* GRAPH 1a: QCCEMG Quantile Process — β(τ) with CI
* ================================================================
capture program drop _xtcsg_plot_qccemg_process
program define _xtcsg_plot_qccemg_process
	syntax , TAU(numlist) K(integer) DEPVAR(string) INDEPVARS(string)
	
	local ntau : word count `tau'
	
	tempname beta_mat beta_v_mat lambda_mat lambda_v_mat
	matrix `beta_mat' = e(beta_mg)
	matrix `beta_v_mat' = e(beta_V)
	matrix `lambda_mat' = e(lambda_mg)
	matrix `lambda_v_mat' = e(lambda_V)
	
	preserve
	clear
	qui set obs `= `ntau' * (`k' + 1)'
	
	qui gen double tau_val = .
	qui gen double beta_est = .
	qui gen double beta_lo = .
	qui gen double beta_hi = .
	qui gen int var_id = .
	qui gen str32 var_name = ""
	
	local idx = 0
	* Lambda
	forvalues t = 1/`ntau' {
		local ++idx
		local tauval : word `t' of `tau'
		qui replace tau_val = `tauval' in `idx'
		qui replace var_id = 0 in `idx'
		qui replace var_name = "L.`depvar'" in `idx'
		local est = `lambda_mat'[1, `t']
		qui replace beta_est = `est' in `idx'
		local var_val = `lambda_v_mat'[`t', `t']
		if `var_val' > 0 & `var_val' != . {
			local se = sqrt(`var_val')
			qui replace beta_lo = `est' - 1.96 * `se' in `idx'
			qui replace beta_hi = `est' + 1.96 * `se' in `idx'
		}
	}
	
	* Beta
	forvalues j = 1/`k' {
		local xvar : word `j' of `indepvars'
		forvalues t = 1/`ntau' {
			local ++idx
			local tauval : word `t' of `tau'
			qui replace tau_val = `tauval' in `idx'
			qui replace var_id = `j' in `idx'
			qui replace var_name = "`xvar'" in `idx'
			local bcol = (`t' - 1) * `k' + `j'
			local est = `beta_mat'[1, `bcol']
			qui replace beta_est = `est' in `idx'
			local var_val = `beta_v_mat'[`bcol', `bcol']
			if `var_val' > 0 & `var_val' != . {
				local se = sqrt(`var_val')
				qui replace beta_lo = `est' - 1.96 * `se' in `idx'
				qui replace beta_hi = `est' + 1.96 * `se' in `idx'
			}
		}
	}
	
	local colors `" "0 128 128" "220 80 50" "100 60 200" "200 60 140" "50 100 220" "'
	
	local graph_list ""
	forvalues vid = 0/`k' {
		if `vid' == 0 {
			local vname "L.`depvar'"
			local vtitle "λ(τ) — Lag dep. var"
		}
		else {
			local vname : word `vid' of `indepvars'
			local vtitle "β(`vname', τ)"
		}
		local col_idx = mod(`vid', 5) + 1
		local this_color : word `col_idx' of `colors'
		local gname "xtcspq_qp_`vid'"
		
		capture {
			twoway (rarea beta_lo beta_hi tau_val if var_id == `vid', ///
					fcolor("`this_color'%20") lcolor("`this_color'%40") ///
					lwidth(thin)) ///
				   (connected beta_est tau_val if var_id == `vid', ///
					lcolor("`this_color'") mcolor("`this_color'") ///
					lwidth(medthick) msymbol(circle) msize(small)), ///
				title("{bf:`vtitle'}", size(medium) color(black)) ///
				subtitle("QCCEMG with 95% CI", size(small)) ///
				xtitle("Quantile (τ)", size(small)) ///
				ytitle("Coefficient", size(small)) ///
				graphregion(fcolor(white) color(white)) ///
				plotregion(margin(small)) ///
				legend(order(2 "Estimate" 1 "95% CI") ///
					size(vsmall) rows(1) position(6) ///
					region(lcolor(gs14))) ///
				name(`gname', replace) nodraw
		}
		if _rc == 0 {
			local graph_list "`graph_list' `gname'"
			di in gr "  ✓ " in ye "`gname'" in gr " — `vtitle'"
		}
	}
	
	* Combine
	if "`graph_list'" != "" {
		local ngraphs : word count `graph_list'
		local ncols = min(`ngraphs', 3)
		capture {
			graph combine `graph_list', ///
				title("{bf:QCCEMG Quantile Process}", ///
					size(medlarge) color(black)) ///
				subtitle("Short-run coefficients ϑ(τ) with 95% CI", ///
					size(small)) ///
				note("XTCSPQARDL v1.0.0", ///
					size(vsmall) color(gs8)) ///
				cols(`ncols') ///
				graphregion(fcolor(white) color(white)) ///
				name(xtcspq_qprocess, replace)
		}
		if _rc == 0 {
			di in gr "  ✓ " in ye "xtcspq_qprocess" in gr " — combined quantile process"
		}
	}
	
	restore
end


* ================================================================
* GRAPH 1b: CS-PQARDL LR β(τ) Quantile Process
* ================================================================
capture program drop _xtcsg_plot_cspqardl_beta
program define _xtcsg_plot_cspqardl_beta
	syntax , TAU(numlist) K(integer) INDEPVARS(string) ///
		LRVARS(string) [ECM]
	
	local ntau : word count `tau'
	
	* Parse LR variables
	tokenize `lrvars'
	mac shift
	local lr_x `*'
	local k_lrx = wordcount("`lr_x'")
	
	tempname beta_mat beta_v_mat
	matrix `beta_mat' = e(beta_mg)
	matrix `beta_v_mat' = e(beta_V)
	
	preserve
	clear
	qui set obs `= `ntau' * `k_lrx''
	
	qui gen double tau_val = .
	qui gen double beta_est = .
	qui gen double beta_lo = .
	qui gen double beta_hi = .
	qui gen int var_id = .
	
	local idx = 0
	local vnum = 0
	foreach v of local lr_x {
		local ++vnum
		forvalues t = 1/`ntau' {
			local ++idx
			local tauval : word `t' of `tau'
			qui replace tau_val = `tauval' in `idx'
			qui replace var_id = `vnum' in `idx'
			local bcol = (`t' - 1) * `k_lrx' + `vnum'
			local est = `beta_mat'[1, `bcol']
			qui replace beta_est = `est' in `idx'
			local var_val = `beta_v_mat'[`bcol', `bcol']
			if `var_val' > 0 & `var_val' != . {
				local se = sqrt(`var_val')
				qui replace beta_lo = `est' - 1.96 * `se' in `idx'
				qui replace beta_hi = `est' + 1.96 * `se' in `idx'
			}
		}
	}
	
	local colors `" "0 128 128" "220 80 50" "100 60 200" "200 60 140" "50 100 220" "'
	
	local graph_list ""
	local vnum = 0
	foreach v of local lr_x {
		local ++vnum
		local col_idx = mod(`vnum' - 1, 5) + 1
		local this_color : word `col_idx' of `colors'
		local gname "xtcspq_lr_`vnum'"
		
		if "`ecm'" != "" {
			local subtitle "ECM Long-Run β(τ) = −θ_x/φ"
		}
		else {
			local subtitle "Long-Run β(τ) = −coef(x)/ρ"
		}
		
		capture {
			twoway (rarea beta_lo beta_hi tau_val if var_id == `vnum', ///
					fcolor("`this_color'%20") lcolor("`this_color'%40") ///
					lwidth(thin)) ///
				   (connected beta_est tau_val if var_id == `vnum', ///
					lcolor("`this_color'") mcolor("`this_color'") ///
					lwidth(medthick) msymbol(circle) msize(small)), ///
				title("{bf:β(`v', τ)}", size(medium) color(black)) ///
				subtitle("`subtitle'", size(small)) ///
				xtitle("Quantile (τ)", size(small)) ///
				ytitle("LR Coefficient", size(small)) ///
				graphregion(fcolor(white) color(white)) ///
				plotregion(margin(small)) ///
				legend(order(2 "Estimate" 1 "95% CI") ///
					size(vsmall) rows(1) position(6) ///
					region(lcolor(gs14))) ///
				name(`gname', replace) nodraw
		}
		if _rc == 0 {
			local graph_list "`graph_list' `gname'"
			di in gr "  ✓ " in ye "`gname'" in gr " — β(`v') quantile process"
		}
	}
	
	* Combine
	if `k_lrx' > 1 & "`graph_list'" != "" {
		capture {
			graph combine `graph_list', ///
				title("{bf:CS-PQARDL Long-Run Quantile Process}", ///
					size(medlarge) color(black)) ///
				subtitle("LR coefficients β(τ) with 95% CI bands", ///
					size(small)) ///
				note("XTCSPQARDL v1.0.0", ///
					size(vsmall) color(gs8)) ///
				graphregion(fcolor(white) color(white)) ///
				name(xtcspq_lr_combined, replace)
		}
		if _rc == 0 {
			di in gr "  ✓ " in ye "xtcspq_lr_combined" in gr " — combined β(τ) process"
		}
	}
	else if "`graph_list'" != "" {
		graph display `: word 1 of `graph_list''
	}
	
	restore
end


* ================================================================
* GRAPH 1c: QCCEMG Long-Run θ(τ) Quantile Process
* ================================================================
capture program drop _xtcsg_plot_qccemg_lr
program define _xtcsg_plot_qccemg_lr
	syntax , TAU(numlist) K(integer) INDEPVARS(string)
	
	local ntau : word count `tau'
	
	tempname theta_mat
	capture matrix `theta_mat' = e(theta_mg)
	if _rc != 0 exit
	
	preserve
	clear
	qui set obs `= `ntau' * `k''
	
	qui gen double tau_val = .
	qui gen double theta_est = .
	qui gen int var_id = .
	
	local idx = 0
	forvalues j = 1/`k' {
		forvalues t = 1/`ntau' {
			local ++idx
			local tauval : word `t' of `tau'
			qui replace tau_val = `tauval' in `idx'
			qui replace var_id = `j' in `idx'
			local bcol = (`t' - 1) * `k' + `j'
			local est = `theta_mat'[1, `bcol']
			qui replace theta_est = `est' in `idx'
		}
	}
	
	local colors `" "100 60 200" "0 128 128" "220 80 50" "200 60 140" "50 100 220" "'
	
	local graph_list ""
	forvalues j = 1/`k' {
		local xvar : word `j' of `indepvars'
		local col_idx = mod(`j' - 1, 5) + 1
		local this_color : word `col_idx' of `colors'
		local gname "xtcspq_qccemg_lr_`j'"
		
		capture {
			twoway (connected theta_est tau_val if var_id == `j', ///
					lcolor("`this_color'") mcolor("`this_color'") ///
					lwidth(medthick) msymbol(circle) msize(small)), ///
				title("{bf:θ(`xvar', τ)}", size(medium) color(black)) ///
				subtitle("Long-Run Effect = β/(1-λ)", size(small)) ///
				xtitle("Quantile (τ)", size(small)) ///
				ytitle("LR Coefficient", size(small)) ///
				graphregion(fcolor(white) color(white)) ///
				plotregion(margin(small)) ///
				legend(order(1 "Estimate") ///
					size(vsmall) rows(1) position(6) ///
					region(lcolor(gs14))) ///
				name(`gname', replace) nodraw
		}
		if _rc == 0 {
			local graph_list "`graph_list' `gname'"
			di in gr "  ✓ " in ye "`gname'" in gr " — θ(`xvar') long-run process"
		}
	}
	
	* Combine
	if `k' > 1 & "`graph_list'" != "" {
		capture {
			graph combine `graph_list', ///
				title("{bf:QCCEMG Long-Run Process}", ///
					size(medlarge) color(black)) ///
				subtitle("Derived Long-Run Coefficients θ(τ)", ///
					size(small)) ///
				note("XTCSPQARDL v1.0.0", ///
					size(vsmall) color(gs8)) ///
				graphregion(fcolor(white) color(white)) ///
				name(xtcspq_qccemg_lr_combined, replace)
		}
		if _rc == 0 {
			di in gr "  ✓ " in ye "xtcspq_qccemg_lr_combined" in gr " — combined θ(τ) process"
		}
	}
	else if "`graph_list'" != "" {
		graph display `: word 1 of `graph_list''
	}
	
	restore
end


* ================================================================
* GRAPH 1d: CS-PQARDL Short-Run Quantile Process (SR impacts)
* ================================================================
capture program drop _xtcsg_plot_cspqardl_sr
program define _xtcsg_plot_cspqardl_sr
	syntax , TAU(numlist) K(integer) INDEPVARS(string)
	
	local ntau : word count `tau'
	
	tempname sr_mat sr_v_mat
	capture matrix `sr_mat' = e(sr_mg)
	if _rc != 0 exit
	capture matrix `sr_v_mat' = e(sr_V)
	
	local cols = colsof(`sr_mat')
	if `cols' == 1 exit // No SR variables
	
	local ncoefs_sr = `cols' / `ntau'
	
	preserve
	clear
	qui set obs `= `ntau' * `ncoefs_sr''
	
	qui gen double tau_val = .
	qui gen double sr_est = .
	qui gen double sr_lo = .
	qui gen double sr_hi = .
	qui gen int var_id = .
	
	local idx = 0
	forvalues j = 1/`ncoefs_sr' {
		forvalues t = 1/`ntau' {
			local ++idx
			local tauval : word `t' of `tau'
			qui replace tau_val = `tauval' in `idx'
			qui replace var_id = `j' in `idx'
			local bcol = (`t' - 1) * `ncoefs_sr' + `j'
			local est = `sr_mat'[1, `bcol']
			qui replace sr_est = `est' in `idx'
			if "`sr_v_mat'" != "" {
				capture local var_val = `sr_v_mat'[`bcol', `bcol']
				if _rc == 0 & `var_val' > 0 & `var_val' != . {
					local se = sqrt(`var_val')
					qui replace sr_lo = `est' - 1.96 * `se' in `idx'
					qui replace sr_hi = `est' + 1.96 * `se' in `idx'
				}
			}
		}
	}
	
	local colors `" "220 80 50" "0 128 128" "100 60 200" "200 60 140" "50 100 220" "'
	
	local graph_list ""
	forvalues j = 1/`ncoefs_sr' {
		local col_idx = mod(`j' - 1, 5) + 1
		local this_color : word `col_idx' of `colors'
		local gname "xtcspq_sr_`j'"
		
		* Try to extract indepvar name if j <= k (simplification)
		local vname "SR `j'"
		if `j' <= `k' {
			local vname : word `j' of `indepvars'
			local vname "Δ`vname'"
		}
		
		capture {
			twoway (rarea sr_lo sr_hi tau_val if var_id == `j', ///
					fcolor("`this_color'%20") lcolor("`this_color'%40") ///
					lwidth(thin)) ///
				   (connected sr_est tau_val if var_id == `j', ///
					lcolor("`this_color'") mcolor("`this_color'") ///
					lwidth(medthick) msymbol(circle) msize(small)), ///
				title("{bf:`vname'}", size(medium) color(black)) ///
				subtitle("Short-Run Impact Process", size(small)) ///
				xtitle("Quantile (τ)", size(small)) ///
				ytitle("SR Coefficient", size(small)) ///
				graphregion(fcolor(white) color(white)) ///
				plotregion(margin(small)) ///
				legend(order(2 "Estimate" 1 "95% CI") ///
					size(vsmall) rows(1) position(6) ///
					region(lcolor(gs14))) ///
				name(`gname', replace) nodraw
		}
		if _rc == 0 {
			local graph_list "`graph_list' `gname'"
			di in gr "  ✓ " in ye "`gname'" in gr " — `vname' short-run process"
		}
	}
	
	* Combine
	if `ncoefs_sr' > 1 & "`graph_list'" != "" {
		capture {
			graph combine `graph_list', ///
				title("{bf:CS-PQARDL Short-Run Impacts}", ///
					size(medlarge) color(black)) ///
				subtitle("Short-Run dynamics with 95% CI bands", ///
					size(small)) ///
				note("XTCSPQARDL v1.0.0", ///
					size(vsmall) color(gs8)) ///
				graphregion(fcolor(white) color(white)) ///
				name(xtcspq_sr_combined, replace)
		}
		if _rc == 0 {
			di in gr "  ✓ " in ye "xtcspq_sr_combined" in gr " — combined SR process"
		}
	}
	else if "`graph_list'" != "" {
		graph display `: word 1 of `graph_list''
	}
	
	restore
end


* ================================================================
* GRAPH 2: ECT Heatmap — ρ_i(τ) across panels × quantiles
* ================================================================
capture program drop _xtcsg_plot_ect_heatmap
program define _xtcsg_plot_ect_heatmap
	syntax , TAU(numlist) NPANELS(integer) [ECM]
	
	local ntau : word count `tau'
	
	tempname rho_mat
	matrix `rho_mat' = e(rho_all)
	
	preserve
	clear
	qui set obs `= `npanels' * `ntau''
	
	qui gen int panel_id = .
	qui gen double tau_val = .
	qui gen double rho_val = .
	
	local idx = 0
	forvalues i = 1/`npanels' {
		local t = 0
		foreach tauval of local tau {
			local ++t
			local ++idx
			qui replace panel_id = `i' in `idx'
			qui replace tau_val = `tauval' in `idx'
			qui replace rho_val = `rho_mat'[`i', `t'] in `idx'
		}
	}
	
	qui gen color_cat = cond(rho_val < -0.5, 1, ///
		cond(rho_val < -0.1, 2, ///
		cond(rho_val < 0, 3, 4)))
	
	if "`ecm'" != "" {
		local rho_label "φ"
	}
	else {
		local rho_label "ρ"
	}
	
	capture {
		twoway (scatter panel_id tau_val if color_cat == 1, ///
				mcolor("0 140 100") msymbol(square) msize(huge)) ///
			   (scatter panel_id tau_val if color_cat == 2, ///
				mcolor("0 170 170") msymbol(square) msize(huge)) ///
			   (scatter panel_id tau_val if color_cat == 3, ///
				mcolor("240 180 50") msymbol(square) msize(huge)) ///
			   (scatter panel_id tau_val if color_cat == 4, ///
				mcolor("200 60 60") msymbol(square) msize(huge)), ///
			title("{bf:ECT Heatmap — `rho_label'_i(τ) by Panel × Quantile}", ///
				size(medium) color(black)) ///
			xtitle("Quantile (τ)", size(small)) ///
			ytitle("Panel ID", size(small)) ///
			graphregion(fcolor(white) color(white)) ///
			legend(order(1 "`rho_label'<-0.5 (Strong)" ///
				2 "-0.5≤`rho_label'<-0.1 (Moderate)" ///
				3 "-0.1≤`rho_label'<0 (Weak)" ///
				4 "`rho_label'≥0 (No conv.)") ///
				size(vsmall) rows(1) position(6) ///
				region(lcolor(gs14))) ///
			name(xtcspq_ect_heatmap, replace)
	}
	if _rc == 0 {
		di in gr "  ✓ " in ye "xtcspq_ect_heatmap" in gr " — ECT adjustment heatmap"
	}
	
	restore
end


* ================================================================
* GRAPH 3: Half-Life Bar Chart by Quantile
* ================================================================
capture program drop _xtcsg_plot_halflife
program define _xtcsg_plot_halflife
	syntax , TAU(numlist) ESTIMATOR(string)
	
	local ntau : word count `tau'
	
	tempname hl_mat
	matrix `hl_mat' = e(halflife_mg)
	
	preserve
	clear
	qui set obs `ntau'
	
	qui gen double tau_val = .
	qui gen double halflife = .
	
	local t = 0
	foreach tauval of local tau {
		local ++t
		qui replace tau_val = `tauval' in `t'
		qui replace halflife = `hl_mat'[1, `t'] in `t'
	}
	
	capture {
		twoway (bar halflife tau_val, ///
				barwidth(0.06) ///
				fcolor("0 128 128%80") lcolor("0 128 128") lwidth(thin)) ///
			   (scatter halflife tau_val, ///
				mcolor("220 80 50") msymbol(diamond) msize(medlarge)), ///
			title("{bf:Half-Life by Quantile}", ///
				size(medium) color(black)) ///
			subtitle("Periods to close 50% of disequilibrium", ///
				size(small)) ///
			xtitle("Quantile (τ)", size(small)) ///
			ytitle("Half-Life (periods)", size(small)) ///
			graphregion(fcolor(white) color(white)) ///
			legend(order(1 "Half-life" 2 "Value") ///
				size(vsmall) rows(1) position(6) ///
				region(lcolor(gs14))) ///
			name(xtcspq_halflife, replace)
	}
	if _rc == 0 {
		di in gr "  ✓ " in ye "xtcspq_halflife" in gr " — half-life bar chart"
	}
	
	restore
end


* ================================================================
* GRAPH 4a: Lambda Process — λ(τ) with CI (QCCEMG)
* ================================================================
capture program drop _xtcsg_plot_lambda_process
program define _xtcsg_plot_lambda_process
	syntax , TAU(numlist)
	
	local ntau : word count `tau'
	
	tempname lam_mat lam_v_mat
	matrix `lam_mat' = e(lambda_mg)
	matrix `lam_v_mat' = e(lambda_V)
	
	preserve
	clear
	qui set obs `ntau'
	
	qui gen double tau_val = .
	qui gen double lam_est = .
	qui gen double lam_lo = .
	qui gen double lam_hi = .
	
	forvalues t = 1/`ntau' {
		local tauval : word `t' of `tau'
		qui replace tau_val = `tauval' in `t'
		local est = `lam_mat'[1, `t']
		qui replace lam_est = `est' in `t'
		local var_val = `lam_v_mat'[`t', `t']
		if `var_val' > 0 & `var_val' != . {
			local se = sqrt(`var_val')
			qui replace lam_lo = `est' - 1.96 * `se' in `t'
			qui replace lam_hi = `est' + 1.96 * `se' in `t'
		}
	}
	
	capture {
		twoway (rarea lam_lo lam_hi tau_val, ///
				fcolor("100 60 200%20") lcolor("100 60 200%40") ///
				lwidth(thin)) ///
			   (connected lam_est tau_val, ///
				lcolor("100 60 200") mcolor("100 60 200") ///
				lwidth(medthick) msymbol(circle) msize(small)), ///
			title("{bf:Persistence Process — λ(τ)}", ///
				size(medium) color(black)) ///
			subtitle("QCCEMG lag coefficient with 95% CI", ///
				size(small)) ///
			xtitle("Quantile (τ)", size(small)) ///
			ytitle("λ(τ)", size(small)) ///
			yline(0, lcolor(gs12) lpattern(dash) lwidth(thin)) ///
			yline(1, lcolor("200 60 60%50") lpattern(dash) lwidth(thin)) ///
			graphregion(fcolor(white) color(white)) ///
			legend(order(2 "λ̂(τ)" 1 "95% CI") ///
				size(vsmall) rows(1) position(6) ///
				region(lcolor(gs14))) ///
			name(xtcspq_lambda, replace)
	}
	if _rc == 0 {
		di in gr "  ✓ " in ye "xtcspq_lambda" in gr " — λ(τ) persistence process"
	}
	
	restore
end


* ================================================================
* GRAPH 4b: Rho/Phi Process — ρ(τ) with CI (CS-PQARDL)
* ================================================================
capture program drop _xtcsg_plot_rho_process
program define _xtcsg_plot_rho_process
	syntax , TAU(numlist) [ECM]
	
	local ntau : word count `tau'
	
	tempname rho_mat rho_v_mat
	matrix `rho_mat' = e(rho_mg)
	matrix `rho_v_mat' = e(rho_V)
	
	if "`ecm'" != "" {
		local rho_label "φ(τ)"
		local rho_title "ECM Speed of Adjustment — φ(τ)"
	}
	else {
		local rho_label "ρ(τ)"
		local rho_title "Speed of Adjustment — ρ(τ)"
	}
	
	preserve
	clear
	qui set obs `ntau'
	
	qui gen double tau_val = .
	qui gen double rho_est = .
	qui gen double rho_lo = .
	qui gen double rho_hi = .
	
	forvalues t = 1/`ntau' {
		local tauval : word `t' of `tau'
		qui replace tau_val = `tauval' in `t'
		local est = `rho_mat'[1, `t']
		qui replace rho_est = `est' in `t'
		local var_val = `rho_v_mat'[`t', `t']
		if `var_val' > 0 & `var_val' != . {
			local se = sqrt(`var_val')
			qui replace rho_lo = `est' - 1.96 * `se' in `t'
			qui replace rho_hi = `est' + 1.96 * `se' in `t'
		}
	}
	
	capture {
		twoway (rarea rho_lo rho_hi tau_val, ///
				fcolor("220 80 50%20") lcolor("220 80 50%40") ///
				lwidth(thin)) ///
			   (connected rho_est tau_val, ///
				lcolor("220 80 50") mcolor("220 80 50") ///
				lwidth(medthick) msymbol(circle) msize(small)), ///
			title("{bf:`rho_title'}", ///
				size(medium) color(black)) ///
			subtitle("CS-PQARDL with 95% CI", size(small)) ///
			xtitle("Quantile (τ)", size(small)) ///
			ytitle("`rho_label'", size(small)) ///
			yline(0, lcolor(gs12) lpattern(dash) lwidth(thin)) ///
			yline(-1, lcolor("200 60 60%50") lpattern(dash) lwidth(thin)) ///
			graphregion(fcolor(white) color(white)) ///
			legend(order(2 "`rho_label'" 1 "95% CI") ///
				size(vsmall) rows(1) position(6) ///
				region(lcolor(gs14))) ///
			name(xtcspq_rho, replace)
	}
	if _rc == 0 {
		di in gr "  ✓ " in ye "xtcspq_rho" in gr " — `rho_label' process"
	}
	
	restore
end
