*! xtpqardl_graph v1.0.1 — Premium visualization for Panel QARDL
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Date: February 2026
*! 6 graphs: Quantile Process, ECT Heatmap, Half-Life, LR Comparison,
*!           IRF Fan, Persistence Profile

capture program drop xtpqardl_graph
program define xtpqardl_graph
	version 15.1
	syntax , TAU(numlist >0 <1 sort) P(integer) Q(integer) K(integer) ///
		DEPVAR(string) INDEPVARS(string) ///
		[ECM NPANELS(integer 0) IVAR(string)]
	
	local ntau : word count `tau'
	
	di
	di in smcl in gr "{hline 78}"
	di in smcl in gr "  {bf:╔══════════════════════════════════════════════════════════════════════╗}"
	di in smcl in gr "  {bf:║   XTPQARDL Premium Visualizations                     v1.0.1       ║}"
	di in smcl in gr "  {bf:╚══════════════════════════════════════════════════════════════════════╝}"
	di in smcl in gr "{hline 78}"
	
	* ================================================================
	* Graph 1: Quantile Process Plot — β(τ) with CI bands
	* ================================================================
	capture matrix list e(beta_mg)
	if _rc == 0 {
		capture noisily _xtpq_plot_qprocess, tau(`tau') k(`k') ///
			depvar("`depvar'") indepvars("`indepvars'")
	}
	
	* ================================================================
	* Graph 2: ECT Heatmap — ρ_i(τ) across panels × quantiles
	* ================================================================
	capture matrix list e(rho_all)
	if _rc == 0 & `npanels' > 0 {
		capture noisily _xtpq_plot_ect_heatmap, tau(`tau') ///
			npanels(`npanels')
	}
	
	* ================================================================
	* Graph 3: Half-Life by Quantile (bar + diamond)
	* ================================================================
	capture matrix list e(halflife_mg)
	if _rc == 0 {
		capture noisily _xtpq_plot_halflife, tau(`tau')
	}
	
	* ================================================================
	* Graph 4: LR Coefficient Comparison (connected lines)
	* ================================================================
	capture matrix list e(beta_mg)
	if _rc == 0 {
		capture noisily _xtpq_plot_lr_comparison, tau(`tau') k(`k') ///
			indepvars("`indepvars'")
	}
	
	* ================================================================
	* Graph 5: IRF Fan Chart by Quantile
	* ================================================================
	capture matrix list e(rho_mg)
	if _rc == 0 {
		capture noisily _xtpq_plot_irf_fan, tau(`tau')
	}
	
	* ================================================================
	* Graph 6: Persistence Profile — (1+ρ)^h across quantiles
	* ================================================================
	capture matrix list e(rho_mg)
	if _rc == 0 {
		capture noisily _xtpq_plot_persistence, tau(`tau')
	}
	
	di in smcl in gr "{hline 78}"
	di in gr "  Graphs saved. Use " in ye "{bf:graph dir}" in gr " to list."
	di in gr "  Export: " in ye "{bf:graph export file.png, name(xtpqardl_*) replace}"
	di in smcl in gr "{hline 78}"
	di
end


* ================================================================
* GRAPH 1: Quantile Process Plot — β(τ) with CI bands
* ================================================================
capture program drop _xtpq_plot_qprocess
program define _xtpq_plot_qprocess
	syntax , TAU(numlist) K(integer) DEPVAR(string) INDEPVARS(string)
	
	local ntau : word count `tau'
	
	tempname beta_mat beta_v_mat
	matrix `beta_mat' = e(beta_mg)
	matrix `beta_v_mat' = e(beta_V)
	
	preserve
	clear
	qui set obs `= `ntau' * `k''
	
	qui gen double tau_val = .
	qui gen double beta_est = .
	qui gen double beta_lo = .
	qui gen double beta_hi = .
	qui gen int var_id = .
	
	local idx = 0
	local vnum = 0
	foreach v of local indepvars {
		local ++vnum
		forvalues t = 1/`ntau' {
			local ++idx
			local tauval : word `t' of `tau'
			local bcol = (`t' - 1) * `k' + `vnum'
			
			qui replace tau_val = `tauval' in `idx'
			qui replace beta_est = `beta_mat'[1, `bcol'] in `idx'
			qui replace var_id = `vnum' in `idx'
			
			local se_val = 0
			capture local se_val = sqrt(`beta_v_mat'[`bcol', `bcol'])
			if `se_val' > 0 & `se_val' != . {
				qui replace beta_lo = `beta_mat'[1, `bcol'] - 1.96 * `se_val' in `idx'
				qui replace beta_hi = `beta_mat'[1, `bcol'] + 1.96 * `se_val' in `idx'
			}
		}
	}
	
	* Colors for each variable
	local colors `" "0 128 128" "220 80 50" "100 60 200" "200 60 140" "50 100 220" "'
	
	local vnum = 0
	local graph_list ""
	foreach v of local indepvars {
		local ++vnum
		local col_idx = mod(`vnum' - 1, 5) + 1
		local this_color : word `col_idx' of `colors'
		local gname "xtpqardl_qp_`vnum'"
		
		capture {
			twoway (rarea beta_lo beta_hi tau_val if var_id == `vnum', ///
					fcolor("`this_color'%25") lcolor("`this_color'%50") lwidth(none)) ///
				   (connected beta_est tau_val if var_id == `vnum', ///
					mcolor("`this_color'") lcolor("`this_color'") ///
					msize(large) msymbol(circle) lwidth(medthick) ///
					lpattern(solid)), ///
				title("{bf:`v': Long-Run β(τ)}", size(medlarge) color(black)) ///
				subtitle("Quantile process with 95% CI band", size(small) color(gs5)) ///
				xtitle("Quantile (τ)", size(small)) ///
				ytitle("β(τ)", size(small)) ///
				xlabel(, labsize(small) grid gstyle(dot)) ///
				ylabel(, labsize(small) grid gstyle(dot)) ///
				plotregion(fcolor(white) lcolor(gs14)) ///
				graphregion(fcolor(white) color(white) margin(small)) ///
				legend(off) ///
				yline(0, lcolor(gs12) lpattern(dash) lwidth(thin)) ///
				name(`gname', replace)
		}
		if _rc == 0 {
			local graph_list "`graph_list' `gname'"
			di in gr "  ✓ " in ye "`gname'" in gr " — β(`v') quantile process"
		}
	}
	
	* Combine if multiple variables
	if `k' > 1 & "`graph_list'" != "" {
		capture {
			graph combine `graph_list', ///
				title("{bf:PQARDL Quantile Process Plot}", ///
					size(medlarge) color(black)) ///
				subtitle("Long-run β(τ) with 95% confidence bands", ///
					size(small) color(gs5)) ///
				note("XTPQARDL v1.0.1", ///
					size(vsmall) color(gs8)) ///
				graphregion(fcolor(white) color(white)) ///
				name(xtpqardl_qprocess, replace)
		}
		if _rc == 0 {
			di in gr "  ✓ " in ye "xtpqardl_qprocess" in gr " — combined quantile process"
		}
	}
	
	restore
end


* ================================================================
* GRAPH 2: ECT Heatmap — ρ_i(τ) by panel × quantile
* ================================================================
capture program drop _xtpq_plot_ect_heatmap
program define _xtpq_plot_ect_heatmap
	syntax , TAU(numlist) NPANELS(integer)
	
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
		forvalues t = 1/`ntau' {
			local ++idx
			local tauval : word `t' of `tau'
			qui replace panel_id = `i' in `idx'
			qui replace tau_val = `tauval' in `idx'
			qui replace rho_val = `rho_mat'[`i', `t'] in `idx'
		}
	}
	
	* Categorize for coloring
	qui gen color_cat = cond(rho_val < -0.5, 1, ///
		cond(rho_val < -0.1, 2, ///
		cond(rho_val < 0, 3, 4)))
	
	capture {
		twoway (scatter panel_id tau_val if color_cat == 1, ///
				mcolor("0 140 100") msymbol(square) msize(huge)) ///
			   (scatter panel_id tau_val if color_cat == 2, ///
				mcolor("0 170 170") msymbol(square) msize(huge)) ///
			   (scatter panel_id tau_val if color_cat == 3, ///
				mcolor("230 160 20") msymbol(square) msize(huge)) ///
			   (scatter panel_id tau_val if color_cat == 4, ///
				mcolor("220 60 40") msymbol(square) msize(huge)), ///
			title("{bf:ECT Speed of Adjustment Heatmap}", ///
				size(medlarge) color(black)) ///
			subtitle("ρ_i(τ) across panels and quantiles", ///
				size(small) color(gs5)) ///
			xtitle("Quantile (τ)", size(small)) ///
			ytitle("Panel", size(small)) ///
			xlabel(, labsize(small)) ///
			ylabel(1(1)`npanels', labsize(vsmall) grid gstyle(dot)) ///
			plotregion(fcolor(white) lcolor(gs14)) ///
			graphregion(fcolor(white) color(white) margin(small)) ///
			legend(order(1 "Strong (ρ<-0.5)" 2 "Moderate" ///
				3 "Weak" 4 "Non-conv.") ///
				size(vsmall) rows(1) position(6) ///
				region(lcolor(gs14))) ///
			name(xtpqardl_ect_heatmap, replace)
	}
	if _rc == 0 {
		di in gr "  ✓ " in ye "xtpqardl_ect_heatmap" in gr " — ECT adjustment heatmap"
	}
	
	restore
end


* ================================================================
* GRAPH 3: Half-Life Bar Chart by Quantile
* ================================================================
capture program drop _xtpq_plot_halflife
program define _xtpq_plot_halflife
	syntax , TAU(numlist)
	
	local ntau : word count `tau'
	
	tempname hl_mat
	matrix `hl_mat' = e(halflife_mg)
	
	preserve
	clear
	qui set obs `ntau'
	
	qui gen double tau_val = .
	qui gen double halflife = .
	
	forvalues t = 1/`ntau' {
		local tauval : word `t' of `tau'
		qui replace tau_val = `tauval' in `t'
		local hv = `hl_mat'[1, `t']
		if `hv' != . & `hv' > 0 & `hv' < 100 {
			qui replace halflife = `hv' in `t'
		}
	}
	
	capture {
		twoway (bar halflife tau_val, ///
				barwidth(0.06) fcolor("100 60 200%70") ///
				lcolor("100 60 200") lwidth(medium)) ///
			   (scatter halflife tau_val, ///
				mcolor("100 60 200") msize(vlarge) msymbol(diamond)), ///
			title("{bf:Half-Life of Adjustment by Quantile}", ///
				size(medlarge) color(black)) ///
			subtitle("HL(τ) = ln(2)/|ρ(τ)| — mean across panels", ///
				size(small) color(gs5)) ///
			xtitle("Quantile (τ)", size(small)) ///
			ytitle("Half-life (periods)", size(small)) ///
			xlabel(, labsize(small)) ///
			ylabel(, labsize(small) grid gstyle(dot)) ///
			plotregion(fcolor(white) lcolor(gs14)) ///
			graphregion(fcolor(white) color(white) margin(small)) ///
			legend(off) ///
			yline(1, lcolor(gs12) lpattern(shortdash) lwidth(thin)) ///
			note("XTPQARDL v1.0.1", size(vsmall) color(gs8)) ///
			name(xtpqardl_halflife, replace)
	}
	if _rc == 0 {
		di in gr "  ✓ " in ye "xtpqardl_halflife" in gr " — half-life bar chart"
	}
	
	restore
end


* ================================================================
* GRAPH 4: LR Coefficient Comparison (connected lines per variable)
* ================================================================
capture program drop _xtpq_plot_lr_comparison
program define _xtpq_plot_lr_comparison
	syntax , TAU(numlist) K(integer) INDEPVARS(string)
	
	local ntau : word count `tau'
	
	tempname beta_mat beta_v_mat
	matrix `beta_mat' = e(beta_mg)
	matrix `beta_v_mat' = e(beta_V)
	
	preserve
	clear
	qui set obs `= `ntau' * `k''
	
	qui gen double tau_val = .
	qui gen double beta_est = .
	qui gen double beta_lo = .
	qui gen double beta_hi = .
	qui gen int var_id = .
	
	local idx = 0
	local vnum = 0
	foreach v of local indepvars {
		local ++vnum
		forvalues t = 1/`ntau' {
			local ++idx
			local tauval : word `t' of `tau'
			local bcol = (`t' - 1) * `k' + `vnum'
			
			qui replace tau_val = `tauval' in `idx'
			qui replace beta_est = `beta_mat'[1, `bcol'] in `idx'
			qui replace var_id = `vnum' in `idx'
			
			local se_val = 0
			capture local se_val = sqrt(`beta_v_mat'[`bcol', `bcol'])
			if `se_val' > 0 & `se_val' != . {
				qui replace beta_lo = `beta_mat'[1, `bcol'] - 1.96 * `se_val' in `idx'
				qui replace beta_hi = `beta_mat'[1, `bcol'] + 1.96 * `se_val' in `idx'
			}
		}
	}
	
	local colors `" "0 128 128" "220 80 50" "100 60 200" "200 60 140" "50 100 220" "'
	local symbols `" "circle" "diamond" "triangle" "square" "plus" "'
	
	local plots ""
	local legend_order ""
	local vnum = 0
	foreach v of local indepvars {
		local ++vnum
		local col_idx = mod(`vnum' - 1, 5) + 1
		local this_color : word `col_idx' of `colors'
		local this_sym : word `col_idx' of `symbols'
		
		* CI band
		local plots `"`plots' (rarea beta_lo beta_hi tau_val if var_id == `vnum', fcolor("`this_color'%15") lwidth(none))"'
		* Connected line
		local plots `"`plots' (connected beta_est tau_val if var_id == `vnum', lcolor("`this_color'") mcolor("`this_color'") msymbol(`this_sym') msize(large) lwidth(medthick))"'
		
		local pnum = `vnum' * 2
		local legend_order `"`legend_order' `pnum' "`v'""'
	}
	
	capture {
		twoway `plots', ///
			title("{bf:Long-Run β(τ) — All Variables}", ///
				size(medlarge) color(black)) ///
			subtitle("Panel QARDL estimates across quantiles with 95% CI", ///
				size(small) color(gs5)) ///
			xtitle("Quantile (τ)", size(small)) ///
			ytitle("Long-run coefficient", size(small)) ///
			xlabel(, labsize(small) grid gstyle(dot)) ///
			ylabel(, labsize(small) grid gstyle(dot)) ///
			plotregion(fcolor(white) lcolor(gs14)) ///
			graphregion(fcolor(white) color(white) margin(small)) ///
			legend(order(`legend_order') size(small) rows(1) ///
				position(6) region(lcolor(gs14))) ///
			yline(0, lcolor(gs12) lpattern(dash) lwidth(thin)) ///
			note("XTPQARDL v1.0.1", ///
				size(vsmall) color(gs8)) ///
			name(xtpqardl_lr_coefs, replace)
	}
	if _rc == 0 {
		di in gr "  ✓ " in ye "xtpqardl_lr_coefs" in gr " — LR coefficient comparison"
	}
	
	restore
end


* ================================================================
* GRAPH 5: IRF Fan Chart — Impulse Response by Quantile
* ================================================================
capture program drop _xtpq_plot_irf_fan
program define _xtpq_plot_irf_fan
	syntax , TAU(numlist)
	
	local ntau : word count `tau'
	local periods = 20
	
	tempname rho_mat
	matrix `rho_mat' = e(rho_mg)
	
	preserve
	clear
	qui set obs `= (`periods' + 1) * `ntau''
	
	qui gen int horizon = .
	qui gen double irf_val = .
	qui gen double tau_val = .
	qui gen int tau_id = .
	
	local idx = 0
	local ti = 0
	foreach tauval of local tau {
		local ++ti
		local rv = `rho_mat'[1, `ti']
		
		forvalues h = 0/`periods' {
			local ++idx
			qui replace horizon = `h' in `idx'
			qui replace tau_val = `tauval' in `idx'
			qui replace tau_id = `ti' in `idx'
			
			if `rv' != . & `rv' < 0 {
				qui replace irf_val = (1 + `rv')^`h' in `idx'
			}
		}
	}
	
	local colors `" "0 128 128" "220 80 50" "100 60 200" "200 60 140" "50 100 220" "230 160 20" "80 140 220" "'
	
	local plots ""
	local legend_order ""
	local ti = 0
	foreach tauval of local tau {
		local ++ti
		local col_idx = mod(`ti' - 1, 7) + 1
		local this_color : word `col_idx' of `colors'
		
		local plots `"`plots' (connected irf_val horizon if tau_id == `ti', lcolor("`this_color'") mcolor("`this_color'") msymbol(circle) msize(small) lwidth(medthick))"'
		local legend_order `"`legend_order' `ti' "τ=`tauval'""'
	}
	
	capture {
		twoway `plots', ///
			title("{bf:Impulse Response Function by Quantile}", ///
				size(medlarge) color(black)) ///
			subtitle("Response to 1-unit shock via ECM mechanism", ///
				size(small) color(gs5)) ///
			xtitle("Horizon (periods)", size(small)) ///
			ytitle("Response", size(small)) ///
			xlabel(0(5)`periods', labsize(small) grid gstyle(dot)) ///
			ylabel(0(0.2)1, labsize(small) grid gstyle(dot)) ///
			plotregion(fcolor(white) lcolor(gs14)) ///
			graphregion(fcolor(white) color(white) margin(small)) ///
			legend(order(`legend_order') size(small) rows(1) ///
				position(6) region(lcolor(gs14))) ///
			yline(0, lcolor(gs12) lpattern(dash) lwidth(thin)) ///
			yline(0.5, lcolor("220 80 50%40") lpattern(shortdash) lwidth(thin)) ///
			note("50% line shown dashed. XTPQARDL v1.0.1", ///
				size(vsmall) color(gs8)) ///
			name(xtpqardl_irf_fan, replace)
	}
	if _rc == 0 {
		di in gr "  ✓ " in ye "xtpqardl_irf_fan" in gr " — IRF fan chart by quantile"
	}
	
	restore
end


* ================================================================
* GRAPH 6: Persistence Profile — ρ(τ) and (1+ρ(τ)) across quantiles
* ================================================================
capture program drop _xtpq_plot_persistence
program define _xtpq_plot_persistence
	syntax , TAU(numlist)
	
	local ntau : word count `tau'
	
	tempname rho_mat hl_mat
	matrix `rho_mat' = e(rho_mg)
	capture matrix `hl_mat' = e(halflife_mg)
	
	preserve
	clear
	qui set obs `ntau'
	
	qui gen double tau_val = .
	qui gen double rho_val = .
	qui gen double persist = .
	qui gen double halflife = .
	
	forvalues t = 1/`ntau' {
		local tauval : word `t' of `tau'
		local rv = `rho_mat'[1, `t']
		qui replace tau_val = `tauval' in `t'
		qui replace rho_val = `rv' in `t'
		qui replace persist = 1 + `rv' in `t'
		capture {
			local hv = `hl_mat'[1, `t']
			if `hv' > 0 & `hv' < 100 {
				qui replace halflife = `hv' in `t'
			}
		}
	}
	
	capture {
		twoway (bar rho_val tau_val, ///
				barwidth(0.04) fcolor("220 60 40%60") ///
				lcolor("220 60 40") lwidth(medium)) ///
			   (connected persist tau_val, ///
				lcolor("0 128 128") mcolor("0 128 128") ///
				msize(vlarge) msymbol(diamond) lwidth(thick) ///
				lpattern(solid) yaxis(2)) ///
			   (connected halflife tau_val, ///
				lcolor("100 60 200") mcolor("100 60 200") ///
				msize(large) msymbol(triangle) lwidth(medthick) ///
				lpattern(dash) yaxis(2)), ///
			title("{bf:Persistence Profile Across Quantiles}", ///
				size(medlarge) color(black)) ///
			subtitle("ρ(τ), persistence (1+ρ), and half-life", ///
				size(small) color(gs5)) ///
			xtitle("Quantile (τ)", size(small)) ///
			ytitle("ρ(τ) — speed of adjustment", size(small) axis(1)) ///
			ytitle("Persistence | Half-life", size(small) axis(2)) ///
			xlabel(, labsize(small) grid gstyle(dot)) ///
			ylabel(, labsize(small) axis(1) grid gstyle(dot)) ///
			ylabel(, labsize(small) axis(2)) ///
			plotregion(fcolor(white) lcolor(gs14)) ///
			graphregion(fcolor(white) color(white) margin(small)) ///
			legend(order(1 "ρ(τ)" 2 "1+ρ(τ)" 3 "Half-life") ///
				size(small) rows(1) position(6) ///
				region(lcolor(gs14))) ///
			yline(0, lcolor(gs12) lpattern(dash) lwidth(thin) axis(1)) ///
			note("XTPQARDL v1.0.1", ///
				size(vsmall) color(gs8)) ///
			name(xtpqardl_persistence, replace)
	}
	if _rc == 0 {
		di in gr "  ✓ " in ye "xtpqardl_persistence" in gr " — persistence profile"
	}
	
	restore
end
