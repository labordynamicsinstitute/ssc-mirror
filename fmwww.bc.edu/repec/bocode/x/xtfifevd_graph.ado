*! version 1.0.1  27feb2026
*! Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)
*! xtfifevd_graph: Post-estimation graphs for xtfifevd
*! Usage: After running xtfifevd, type:
*!   xtfifevd_graph               — default coefficient plot
*!   xtfifevd_graph, secompare    — SE comparison (FEVD only)
*!   xtfifevd_graph, combined     — both graphs in one
*!   xtfifevd_graph, saving(name) — export to PNG

capture program drop xtfifevd_graph
program define xtfifevd_graph
	syntax [, ///
		COEFplot		///  Coefficient plot with CIs (default)
		SECompare		///  SE comparison: PZ vs Raw (FEVD only)
		COMBined		///  Both graphs combined
		SAVing(string)	///  Export filename (without extension)
		Level(integer `c(level)')  ///
		TItle(string)	///  Custom title
		]
	
	// =====================================================================
	// VALIDATION
	// =====================================================================
	
	if "`e(cmd)'" != "xtfifevd" {
		di as err "xtfifevd_graph is a post-estimation command for {bf:xtfifevd}"
		di as err "Run {bf:xtfifevd} first, then call {bf:xtfifevd_graph}"
		exit 301
	}
	
	// Default to coefplot if nothing specified
	if "`coefplot'" == "" & "`secompare'" == "" & "`combined'" == "" {
		local coefplot "coefplot"
	}
	
	// secompare requires FEVD (which has raw SEs)
	if "`secompare'" != "" | "`combined'" != "" {
		if "`e(method)'" != "FEVD" {
			di as txt "(note: SE comparison only available for FEVD method;"
			di as txt " `e(method)' uses Pesaran-Zhou SEs exclusively)"
			if "`combined'" != "" {
				local coefplot "coefplot"
				local secompare ""
			}
			else {
				local secompare ""
				local coefplot "coefplot"
			}
		}
	}
	
	// Critical value
	local crit = invnormal(1 - (100 - `level') / 200)
	
	// SE type label
	local se_label "Pesaran-Zhou"
	if "`e(vcetype)'" != "" {
		local se_label "`e(vcetype)'"
	}
	
	// =====================================================================
	// EXTRACT e() RESULTS
	// =====================================================================
	
	local method   "`e(method)'"
	local depvar   "`e(depvar)'"
	local xvars    "`e(xvars)'"
	local zinvars  "`e(zinvariants)'"
	local k_x      = e(k_x)
	local k_z      = e(k_z)
	local N_obs    = e(N)
	local N_g      = e(N_g)
	
	// Get coefficient vector and VCE
	tempname b_all V_all
	matrix `b_all' = e(b)
	matrix `V_all' = e(V)
	
	local k_total = colsof(`b_all')
	
	// =====================================================================
	// GRAPH: COEFFICIENT PLOT WITH CIs
	// =====================================================================
	
	if "`coefplot'" != "" | "`combined'" != "" {
		
		if "`title'" != "" {
			local gtitle "`title'"
		}
		else {
			local gtitle "{bf:Coefficients (`level'% CI)}"
		}
		
		// Build temporary dataset for plotting
		preserve
		qui {
			clear
			
			// Total parameters: k_x + k_z + 1 (intercept)
			local nparams = `k_total'
			set obs `nparams'
			
			gen str40 varname = ""
			gen double coef = .
			gen double se = .
			gen double ci_lo = .
			gen double ci_hi = .
			gen double ypos = .
			gen int vartype = .   // 1=time-varying, 2=time-invariant, 3=intercept
			
			// Fill in coefficients
			local row = 0
			
			// --- Time-varying (FE) coefficients ---
			forvalues i = 1/`k_x' {
				local row = `row' + 1
				local vn : word `i' of `xvars'
				local b_i = `b_all'[1, `i']
				local se_i = sqrt(`V_all'[`i', `i'])
				
				replace varname = "`vn'" in `row'
				replace coef = `b_i' in `row'
				replace se = `se_i' in `row'
				replace ci_lo = `b_i' - `crit' * `se_i' in `row'
				replace ci_hi = `b_i' + `crit' * `se_i' in `row'
				replace ypos = `k_total' - `row' + 1 in `row'
				replace vartype = 1 in `row'
			}
			
			// --- Time-invariant (gamma) coefficients ---
			forvalues i = 1/`k_z' {
				local row = `row' + 1
				local vn : word `i' of `zinvars'
				local idx = `k_x' + `i'
				local b_i = `b_all'[1, `idx']
				local se_i = sqrt(`V_all'[`idx', `idx'])
				
				replace varname = "`vn'" in `row'
				replace coef = `b_i' in `row'
				replace se = `se_i' in `row'
				replace ci_lo = `b_i' - `crit' * `se_i' in `row'
				replace ci_hi = `b_i' + `crit' * `se_i' in `row'
				replace ypos = `k_total' - `row' + 1 in `row'
				replace vartype = 2 in `row'
			}
			
			// --- Intercept ---
			local row = `row' + 1
			local idx = `k_total'
			local b_i = `b_all'[1, `idx']
			local se_i = sqrt(`V_all'[`idx', `idx'])
			
			replace varname = "_cons" in `row'
			replace coef = `b_i' in `row'
			replace se = `se_i' in `row'
			replace ci_lo = `b_i' - `crit' * `se_i' in `row'
			replace ci_hi = `b_i' + `crit' * `se_i' in `row'
			replace ypos = `k_total' - `row' + 1 in `row'
			replace vartype = 3 in `row'
		}
		
		// Build ylabel labels
		local ylabels ""
		forvalues r = 1/`nparams' {
			local vn = varname[`r']
			local yp = ypos[`r']
			local vt = vartype[`r']
			if `vt' == 1 {
				local ylabels `"`ylabels' `yp' `""`vn' (FE)""'"'
			}
			else if `vt' == 2 {
				local ylabels `"`ylabels' `yp' `""{bf:`vn'} (`method')""'"'
			}
			else {
				local ylabels `"`ylabels' `yp' `""_cons""'"'
			}
		}
		
		// Separator line between FE and z-coefficients
		local sep_y = `k_total' - `k_x' + 0.5
		
		twoway ///
			(rcap ci_lo ci_hi ypos if vartype==1, horizontal ///
				lcolor("59 130 246") lwidth(medthick))  ///
			(scatter ypos coef if vartype==1, msymbol(O) msize(medlarge) ///
				mcolor("37 99 235") mlcolor(white) mlwidth(thin))  ///
			(rcap ci_lo ci_hi ypos if vartype==2, horizontal ///
				lcolor("16 185 129") lwidth(medthick))  ///
			(scatter ypos coef if vartype==2, msymbol(D) msize(medlarge) ///
				mcolor("5 150 105") mlcolor(white) mlwidth(thin))  ///
			(rcap ci_lo ci_hi ypos if vartype==3, horizontal ///
				lcolor("156 163 175") lwidth(medthick))  ///
			(scatter ypos coef if vartype==3, msymbol(S) msize(medlarge) ///
				mcolor("107 114 128") mlcolor(white) mlwidth(thin))  ///
			, xline(0, lpattern(dash) lcolor(gs10) lwidth(thin))  ///
			yline(`sep_y', lpattern(shortdash) lcolor(gs13))  ///
			ylabel(`ylabels', labsize(vsmall) angle(0) noticks nogrid)  ///
			yscale(range(0.3 `=`k_total'+0.7'))  ///
			xlabel(, grid glcolor(gs14) glwidth(vthin))  ///
			xtitle("Coefficient (`level'% CI)", size(small))  ///
			ytitle("")  ///
			title("`gtitle'", size(medlarge) color(black))  ///
			subtitle("Dep. var: `depvar'  |  N=`N_obs', Groups=`N_g'  |  `se_label' Std. Err.", ///
				size(vsmall) color(gs6))  ///
			legend(order(2 "Time-varying (FE)" ///
				4 "Time-invariant (`method')" 6 "Intercept")  ///
				size(vsmall) rows(1) position(6) region(lcolor(gs14)))  ///
			graphregion(color(white) margin(small))  ///
			plotregion(margin(medium))  ///
			name(_xtfifevd_coefplot, replace)
		
		if "`saving'" != "" & "`combined'" == "" {
			qui graph export "`saving'.png", width(1400) replace
			di in gr "  Graph saved: `saving'.png"
		}
		
		restore
	}
	
	// =====================================================================
	// GRAPH: SE COMPARISON (FEVD only — PZ vs Raw)
	//   Uses twoway bar with different colors per group
	// =====================================================================
	
	if ("`secompare'" != "" | "`combined'" != "") & "`e(method)'" == "FEVD" {
		
		tempname V_pz V_raw
		matrix `V_pz'  = e(V_gamma_pz)
		matrix `V_raw' = e(V_gamma_fevd_raw)
		
		if "`title'" != "" & "`combined'" == "" {
			local gtitle2 "`title'"
		}
		else {
			local gtitle2 "{bf:Standard Error Comparison}"
		}
		
		preserve
		qui {
			clear
			
			local nrows = `k_z' * 2
			set obs `nrows'
			
			gen str40 varname = ""
			gen double se_val = .
			gen int group = .      // 1 = PZ, 2 = Raw
			gen double xpos = .
			
			local row = 0
			local xp = 0
			forvalues i = 1/`k_z' {
				local vn : word `i' of `zinvars'
				local se_pz_i  = sqrt(`V_pz'[`i', `i'])
				local se_raw_i = sqrt(`V_raw'[`i', `i'])
				
				// PZ bar
				local row = `row' + 1
				local xp = `xp' + 1
				replace varname = "`vn'" in `row'
				replace se_val  = `se_pz_i' in `row'
				replace group   = 1 in `row'
				replace xpos    = `xp' in `row'
				
				// Raw bar
				local row = `row' + 1
				local xp = `xp' + 1
				replace varname = "`vn'" in `row'
				replace se_val  = `se_raw_i' in `row'
				replace group   = 2 in `row'
				replace xpos    = `xp' in `row'
				
				// gap between variable groups
				local xp = `xp' + 1
			}
		}
		
		// Build x-axis labels
		local xlabels ""
		local row = 0
		local xp = 0
		forvalues i = 1/`k_z' {
			local vn : word `i' of `zinvars'
			local vn_short = abbrev("`vn'", 8)
			local xp = `xp' + 1
			local xlabels `"`xlabels' `xp' `""PZ""'"'
			local xp = `xp' + 1
			local xlabels `"`xlabels' `xp' `""Raw""'"'
			local xp = `xp' + 1
		}
		
		// Build group labels at midpoints
		local grplabels ""
		local xp = 0
		forvalues i = 1/`k_z' {
			local vn : word `i' of `zinvars'
			local midpt = `xp' + 1.5
			local grplabels "`grplabels' `midpt'"
			local xp = `xp' + 3
		}
		
		// Compute ratio for annotation
		local ratio_note ""
		forvalues i = 1/`k_z' {
			local vn : word `i' of `zinvars'
			local se_pz_i  = sqrt(`V_pz'[`i', `i'])
			local se_raw_i = sqrt(`V_raw'[`i', `i'])
			local ratio_i : di %4.1f (`se_pz_i' / `se_raw_i')
			local ratio_note "`ratio_note' `vn':`ratio_i'x"
		}
		
		twoway ///
			(bar se_val xpos if group==1, ///
				fcolor("16 185 129") lcolor("5 150 105") ///
				lwidth(medium) barwidth(0.8))  ///
			(bar se_val xpos if group==2, ///
				fcolor("239 68 68") lcolor("220 38 38") ///
				lwidth(medium) barwidth(0.8))  ///
			, xlabel(`xlabels', labsize(vsmall) angle(0))  ///
			ylabel(, grid glcolor(gs14) glwidth(vthin))  ///
			ytitle("Std. Error", size(small))  ///
			xtitle("")  ///
			title("`gtitle2'", size(medium) color(black))  ///
			subtitle("PZ (Consistent) vs Raw (Inconsistent)", ///
				size(vsmall) color(gs6))  ///
			legend(order(1 "PZ Corrected" 2 "FEVD Raw")  ///
				size(vsmall) rows(1) position(6) region(lcolor(gs14)))  ///
			note("Ratios:`ratio_note'", ///
				size(vsmall) color(cranberry))  ///
			graphregion(color(white) margin(small))  ///
			plotregion(margin(medium))  ///
			name(_xtfifevd_secompare, replace)
		
		if "`saving'" != "" & "`combined'" == "" {
			qui graph export "`saving'.png", width(1200) replace
			di in gr "  Graph saved: `saving'.png"
		}
		
		restore
	}
	
	// =====================================================================
	// COMBINED: Both graphs side by side
	// =====================================================================
	
	if "`combined'" != "" & "`e(method)'" == "FEVD" {
		graph combine _xtfifevd_coefplot _xtfifevd_secompare,  ///
			rows(1) ///
			title("{bf:`method' Estimation Results}", size(medlarge) color(black))  ///
			subtitle("xtfifevd  |  `depvar'  |  N=`N_obs', Groups=`N_g'", ///
				size(small) color(gs6))  ///
			graphregion(color(white) margin(small))  ///
			note("Left: Coefficients with `level'% CI  |  Right: SE comparison (PZ vs Raw)", ///
				size(vsmall) color(gs8))  ///
			name(_xtfifevd_combined, replace)
		
		if "`saving'" != "" {
			qui graph export "`saving'.png", width(2000) replace
			di in gr "  Graph saved: `saving'.png"
		}
	}
	
	// =====================================================================
	// DISPLAY SUMMARY
	// =====================================================================
	
	di
	di in smcl in gr "{hline 60}"
	di in gr "{bf:xtfifevd_graph}: Post-estimation visualization"
	di in smcl in gr "{hline 60}"
	di in gr "Method:         " in ye "`method'"
	di in gr "Dep. variable:  " in ye "`depvar'"
	di in gr "Observations:   " in ye "`N_obs'" in gr "  Groups: " in ye "`N_g'"
	di in gr "Variance:       " in ye "Pesaran-Zhou (2016)"
	
	if "`coefplot'" != "" {
		di in gr "Graph:          " in ye "Coefficient plot with `level'% CI"
	}
	if "`secompare'" != "" & "`e(method)'" == "FEVD" {
		di in gr "Graph:          " in ye "SE comparison (PZ vs Raw)"
	}
	if "`combined'" != "" & "`e(method)'" == "FEVD" {
		di in gr "Graph:          " in ye "Combined (coefplot + SE comparison)"
	}
	
	if "`saving'" != "" {
		di in gr "Saved to:       " in ye "`saving'.png"
	}
	di in smcl in gr "{hline 60}"
end
