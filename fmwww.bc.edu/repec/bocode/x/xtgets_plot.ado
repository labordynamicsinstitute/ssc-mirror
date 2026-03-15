*! xtgets_plot: Postestimation visualizations for xtgets
*! Version 1.0.0  14mar2026  Dr Merwan Roudane  merwanroudane920@gmail.com
*! Matches R getspanel plot style:
*!   plot(is1)              -> xtgets_plot, type(breaks)     [heatmap]
*!   plot_grid(is1)         -> xtgets_plot, type(grid)       [actual+fitted+vlines]
*!   plot_counterfactual    -> xtgets_plot, type(counter)    [counterfactual]
*!   plot_residuals(is1)    -> xtgets_plot, type(residuals)  [residual plot]

capture program drop xtgets_plot
program define xtgets_plot
	version 15.1
	
	syntax [, Type(string) SAVing(string) PLUSt(integer 0) ///
		COMBine SCHeme(string) TItle(string)]
	
	* Check xtgets was run
	if "`e(cmd)'" != "xtgets" {
		di as err "xtgets_plot requires {bf:xtgets} estimation results"
		exit 301
	}
	
	* Retrieve stored results
	local depvar   `e(depvar)'
	local xvars    `e(xvars)'
	local ivar     `e(ivar)'
	local tvar     `e(tvar)'
	local retained `e(retained)'
	local effect   `e(effect)'
	local n_retained = e(n_retained)
	local N_units  = e(N_units)
	local T_periods = e(T_periods)
	
	* Default type
	if "`type'" == "" local type "grid"
	if !inlist("`type'", "breaks", "heatmap", "grid", "counter", "counterfactual", "residuals") {
		di as err "type() must be: breaks, heatmap, grid, counter, residuals"
		exit 198
	}
	if "`type'" == "counterfactual" local type "counter"
	
	if `n_retained' == 0 & !inlist("`type'", "residuals", "grid") {
		di as err "No indicators retained. Nothing to plot."
		exit 198
	}
	
	* =========================================================================
	* Parse retained indicators into break date lists per unit
	* =========================================================================
	
	local break_info ""
	foreach ind of local retained {
		local bunit = ""
		local btime = ""
		local btype = ""
		
		if substr("`ind'", 1, 7) == "_fesis_" {
			local rest = substr("`ind'", 8, .)
			local pos = strpos("`rest'", "_")
			if `pos' > 0 {
				local bunit = substr("`rest'", 1, `pos'-1)
				local btime = substr("`rest'", `pos'+1, .)
				local btype "FESIS"
			}
		}
		else if substr("`ind'", 1, 5) == "_iis_" {
			local rest = substr("`ind'", 6, .)
			local pos = strpos("`rest'", "_")
			if `pos' > 0 {
				local bunit = substr("`rest'", 1, `pos'-1)
				local btime = substr("`rest'", `pos'+1, .)
				local btype "IIS"
			}
		}
		else if substr("`ind'", 1, 6) == "_csis_" {
			local rest = substr("`ind'", 7, .)
			local lpos = 0
			forvalues pp = 1/50 {
				if substr("`rest'", `pp', 1) == "_" local lpos = `pp'
			}
			if `lpos' > 0 {
				local bunit = "0"
				local btime = substr("`rest'", `lpos'+1, .)
				local btype "CSIS"
			}
		}
		else if substr("`ind'", 1, 5) == "_tis_" {
			local rest = substr("`ind'", 6, .)
			local pos = strpos("`rest'", "_")
			if `pos' > 0 {
				local bunit = substr("`rest'", 1, `pos'-1)
				local btime = substr("`rest'", `pos'+1, .)
				local btype "TIS"
			}
		}
		
		if "`bunit'" != "" & "`btime'" != "" {
			local break_info `break_info' `bunit'_`btime'_`btype'
		}
	}
	
	* =========================================================================
	* Helper: Compute fitted values manually from e(b) 
	* =========================================================================
	
	if inlist("`type'", "grid", "counter", "residuals") {
		preserve
		
		tempname bmat
		mat `bmat' = e(b)
		local bnames : colnames `bmat'
		
		qui gen double _xtg_fitted = 0
		qui gen double _xtg_cf = 0
		
		local col = 0
		foreach v of local bnames {
			local ++col
			local coef = `bmat'[1, `col']
			
			if "`v'" == "_cons" {
				qui replace _xtg_fitted = _xtg_fitted + `coef'
				qui replace _xtg_cf = _xtg_cf + `coef'
			}
			else {
				cap confirm variable `v'
				if _rc == 0 {
					qui replace _xtg_fitted = _xtg_fitted + `coef' * `v'
					
					local is_retained = 0
					foreach ri of local retained {
						if "`v'" == "`ri'" local is_retained = 1
					}
					if `is_retained' == 0 {
						qui replace _xtg_cf = _xtg_cf + `coef' * `v'
					}
				}
				else {
					* Recreate FE dummies
					* New names: idK (e.g. id2, id15)
					* Old names: _xtgets_id_K
					local is_id_fe = 0
					local fe_k = ""
					if substr("`v'", 1, 2) == "id" & real(substr("`v'", 3, .)) != . {
						local is_id_fe = 1
						local fe_k = substr("`v'", 3, .)
					}
					else if substr("`v'", 1, 11) == "_xtgets_id_" {
						local is_id_fe = 1
						local fe_k = substr("`v'", 12, .)
					}
					
					if `is_id_fe' {
						qui gen byte _tmp_`col' = (`ivar' == `fe_k')
						qui replace _xtg_fitted = _xtg_fitted + `coef' * _tmp_`col'
						qui replace _xtg_cf = _xtg_cf + `coef' * _tmp_`col'
						qui drop _tmp_`col'
					}
					* Time FE: timeYEAR (e.g. time1996) or _xtgets_t_K
					else if substr("`v'", 1, 4) == "time" & real(substr("`v'", 5, .)) != . {
						local tval = substr("`v'", 5, .)
						qui gen byte _tmp_`col' = (`tvar' == `tval')
						qui replace _xtg_fitted = _xtg_fitted + `coef' * _tmp_`col'
						qui replace _xtg_cf = _xtg_cf + `coef' * _tmp_`col'
						qui drop _tmp_`col'
					}
					else if substr("`v'", 1, 10) == "_xtgets_t_" {
						local fe_t = substr("`v'", 11, .)
						qui levelsof `tvar', local(tvals)
						local tv : word `fe_t' of `tvals'
						qui gen byte _tmp_`col' = (`tvar' == `tv')
						qui replace _xtg_fitted = _xtg_fitted + `coef' * _tmp_`col'
						qui replace _xtg_cf = _xtg_cf + `coef' * _tmp_`col'
						qui drop _tmp_`col'
					}
					* FESIS: _fesis_ID_YEAR
					else if substr("`v'", 1, 7) == "_fesis_" {
						local rest = substr("`v'", 8, .)
						local pos = strpos("`rest'", "_")
						local fid = substr("`rest'", 1, `pos'-1)
						local fyr = substr("`rest'", `pos'+1, .)
						qui gen byte _tmp_`col' = (`ivar' == `fid' & `tvar' >= `fyr')
						qui replace _xtg_fitted = _xtg_fitted + `coef' * _tmp_`col'
						qui drop _tmp_`col'
					}
					* IIS: _iis_ID_YEAR
					else if substr("`v'", 1, 5) == "_iis_" {
						local rest = substr("`v'", 6, .)
						local pos = strpos("`rest'", "_")
						local iid = substr("`rest'", 1, `pos'-1)
						local iyr = substr("`rest'", `pos'+1, .)
						qui gen byte _tmp_`col' = (`ivar' == `iid' & `tvar' == `iyr')
						qui replace _xtg_fitted = _xtg_fitted + `coef' * _tmp_`col'
						qui drop _tmp_`col'
					}
					* CSIS: _csis_VAR_YEAR
					else if substr("`v'", 1, 6) == "_csis_" {
						local rest = substr("`v'", 7, .)
						local lpos = 0
						forvalues pp = 1/50 {
							if substr("`rest'", `pp', 1) == "_" local lpos = `pp'
						}
						local cvar = substr("`rest'", 1, `lpos'-1)
						local cyr  = substr("`rest'", `lpos'+1, .)
						cap confirm variable `cvar'
						if _rc == 0 {
							qui gen double _tmp_`col' = (`tvar' >= `cyr') * `cvar'
							qui replace _xtg_fitted = _xtg_fitted + `coef' * _tmp_`col'
							qui drop _tmp_`col'
						}
					}
					* TIS: _tis_ID_YEAR
					else if substr("`v'", 1, 5) == "_tis_" {
						local rest = substr("`v'", 6, .)
						local pos = strpos("`rest'", "_")
						local tid = substr("`rest'", 1, `pos'-1)
						local tyr = substr("`rest'", `pos'+1, .)
						qui gen double _tmp_`col' = cond(`ivar'==`tid' & `tvar'>=`tyr', `tvar'-`tyr'+1, 0)
						qui replace _xtg_fitted = _xtg_fitted + `coef' * _tmp_`col'
						qui drop _tmp_`col'
					}
					* JSIS/JIIS
					else if substr("`v'", 1, 6) == "_jsis_" {
						local jyr = substr("`v'", 7, .)
						qui gen byte _tmp_`col' = (`tvar' >= `jyr')
						qui replace _xtg_fitted = _xtg_fitted + `coef' * _tmp_`col'
						qui drop _tmp_`col'
					}
					else if substr("`v'", 1, 6) == "_jiis_" {
						local jyr = substr("`v'", 7, .)
						qui gen byte _tmp_`col' = (`tvar' == `jyr')
						qui replace _xtg_fitted = _xtg_fitted + `coef' * _tmp_`col'
						qui drop _tmp_`col'
					}
				}
			}
		}
		
		qui gen double _xtg_resid = `depvar' - _xtg_fitted
		qui gen double _xtg_zero = 0
	}
	
	* =========================================================================
	* TYPE 1: BREAKS HEATMAP — R: plot(isatpanel_result)
	* Shows effect (coefficient) as colored bars per unit over time
	* =========================================================================
	
	if "`type'" == "breaks" {
		di in gr "{bf:xtgets_plot: Break Effect Heatmap}"
		di in gr "  Replicates R: plot(isatpanel_result)"
		
		if "`title'" == "" local title "Detected Structural Breaks"
		
		preserve
		clear
		local nb = 0
		
		foreach ind of local retained {
			local btype = ""
			local bunit = .
			local btime = .
			
			if substr("`ind'", 1, 7) == "_fesis_" {
				local rest = substr("`ind'", 8, .)
				local btype "FESIS"
				local pos = strpos("`rest'", "_")
				if `pos' > 0 {
					local bunit = substr("`rest'", 1, `pos'-1)
					local btime = substr("`rest'", `pos'+1, .)
				}
			}
			else if substr("`ind'", 1, 5) == "_iis_" {
				local rest = substr("`ind'", 6, .)
				local btype "IIS"
				local pos = strpos("`rest'", "_")
				if `pos' > 0 {
					local bunit = substr("`rest'", 1, `pos'-1)
					local btime = substr("`rest'", `pos'+1, .)
				}
			}
			else if substr("`ind'", 1, 6) == "_csis_" {
				local btype "CSIS"
				local bunit = 0
				local rest = substr("`ind'", 7, .)
				local lpos = 0
				forvalues pp = 1/50 {
					if substr("`rest'", `pp', 1) == "_" local lpos = `pp'
				}
				if `lpos' > 0 local btime = substr("`rest'", `lpos'+1, .)
			}
			else if substr("`ind'", 1, 5) == "_tis_" {
				local rest = substr("`ind'", 6, .)
				local btype "TIS"
				local pos = strpos("`rest'", "_")
				if `pos' > 0 {
					local bunit = substr("`rest'", 1, `pos'-1)
					local btime = substr("`rest'", `pos'+1, .)
				}
			}
			
			if "`btype'" != "" & "`btime'" != "." & "`btime'" != "" {
				local ++nb
				if `nb' == 1 {
					qui set obs 1
					qui gen str20 break_type = ""
					qui gen break_unit = .
					qui gen break_time = .
					qui gen str32 break_name = ""
				}
				else {
					qui set obs `nb'
				}
				qui replace break_type = "`btype'" in `nb'
				qui replace break_unit = real("`bunit'") in `nb'
				qui replace break_time = real("`btime'") in `nb'
				qui replace break_name = "`ind'" in `nb'
			}
		}
		
		if `nb' == 0 {
			di as err "Could not parse break dates."
			restore
			exit
		}
		
		* Scatter with types
		qui gen t_fesis  = break_time if break_type == "FESIS"
		qui gen t_iis    = break_time if break_type == "IIS"
		qui gen t_csis   = break_time if break_type == "CSIS"
		qui gen t_tis    = break_time if break_type == "TIS"
		
		local plots ""
		local legend_items ""
		local legend_n = 0
		
		qui count if break_type == "FESIS"
		if r(N) > 0 {
			local ++legend_n
			local plots `plots' (scatter break_unit t_fesis, ///
				msymbol(O) msize(vlarge) mcolor("24 116 205") ///
				mlwidth(medium) mlcolor(white))
			local legend_items `legend_items' `legend_n' "FESIS"
		}
		qui count if break_type == "IIS"
		if r(N) > 0 {
			local ++legend_n
			local plots `plots' (scatter break_unit t_iis, ///
				msymbol(D) msize(large) mcolor("220 50 47") ///
				mlwidth(medium) mlcolor(white))
			local legend_items `legend_items' `legend_n' "IIS"
		}
		qui count if break_type == "CSIS"
		if r(N) > 0 {
			local ++legend_n
			local plots `plots' (scatter break_unit t_csis, ///
				msymbol(T) msize(vlarge) mcolor("38 166 91") ///
				mlwidth(medium) mlcolor(white))
			local legend_items `legend_items' `legend_n' "CSIS"
		}
		qui count if break_type == "TIS"
		if r(N) > 0 {
			local ++legend_n
			local plots `plots' (scatter break_unit t_tis, ///
				msymbol(S) msize(vlarge) mcolor("255 153 0") ///
				mlwidth(medium) mlcolor(white))
			local legend_items `legend_items' `legend_n' "TIS"
		}
		
		twoway `plots', ///
			title("`title'", color("33 37 41") size(large)) ///
			subtitle("Indicator saturation", ///
				color("108 117 125") size(medium)) ///
			xtitle("`tvar'", color("33 37 41") size(medlarge)) ///
			ytitle("`ivar'", color("33 37 41") size(medlarge)) ///
			ylabel(, angle(0) labcolor("33 37 41") labsize(small) nogrid) ///
			xlabel(, labcolor("33 37 41") labsize(small)) ///
			legend(on order(`legend_items') ///
				rows(1) size(small) position(6) ///
				region(lstyle(none) color(white))) ///
			graphregion(color(white) margin(medium)) ///
			plotregion(color("248 249 250") lstyle(none) margin(medlarge)) ///
			name(_xtgets_breaks, replace) ///
			`=cond("`saving'"!="", `"saving("`saving'", replace)"', "")'
		
		restore
	}
	
	* =========================================================================
	* TYPE 1b: HEATMAP — R: plot(isatpanel_result) 
	* Colored rectangles: blue=positive effect, red=negative effect
	* =========================================================================
	
	else if "`type'" == "heatmap" {
		di in gr "{bf:xtgets_plot: Effect Heatmap}"
		di in gr "  Replicates R: plot(isatpanel_result)"
		
		if "`title'" == "" local title "Intercept (Retained Indicators)"
		
		preserve
		
		* Get time range
		qui su `tvar'
		local tmin = r(min)
		local tmax = r(max)
		
		* Get unit values
		qui levelsof `ivar', local(units)
		local n_u : word count `units'
		
		* Build dataset: one row per break x time-in-effect
		clear
		local nrows = 0
		
		tempname bmat
		mat `bmat' = e(b)
		local bnames : colnames `bmat'
		
		foreach ind of local retained {
			local bunit = ""
			local btime = ""
			local bcoef = 0
			
			* Get coefficient
			local cc = 0
			foreach bn of local bnames {
				local ++cc
				if "`bn'" == "`ind'" {
					local bcoef = `bmat'[1, `cc']
				}
			}
			
			* Parse FESIS: _fesis_ID_YEAR — step from year to end
			if substr("`ind'", 1, 7) == "_fesis_" {
				local rest = substr("`ind'", 8, .)
				local pos = strpos("`rest'", "_")
				if `pos' > 0 {
					local bunit = substr("`rest'", 1, `pos'-1)
					local btime = substr("`rest'", `pos'+1, .)
				}
			}
			* Parse IIS: _iis_ID_YEAR — impulse at single year
			else if substr("`ind'", 1, 5) == "_iis_" {
				local rest = substr("`ind'", 6, .)
				local pos = strpos("`rest'", "_")
				if `pos' > 0 {
					local bunit = substr("`rest'", 1, `pos'-1)
					local btime = substr("`rest'", `pos'+1, .)
				}
			}
			
			if "`bunit'" == "" | "`btime'" == "" continue
			local bt = real("`btime'")
			local bu = real("`bunit'")
			
			* For FESIS: create bars from break_time to tmax
			* For IIS: create bar at single time point
			local is_iis = 0
			if substr("`ind'", 1, 5) == "_iis_" local is_iis = 1
			
			if `is_iis' {
				local ++nrows
				if `nrows' == 1 {
					qui set obs 1
					qui gen double hm_unit = .
					qui gen double hm_time = .
					qui gen double hm_coef = .
					qui gen double hm_ylo = .
					qui gen double hm_yhi = .
				}
				else {
					qui set obs `nrows'
				}
				qui replace hm_unit = `bu' in `nrows'
				qui replace hm_time = `bt' in `nrows'
				qui replace hm_coef = `bcoef' in `nrows'
				qui replace hm_ylo = `bu' - 0.4 in `nrows'
				qui replace hm_yhi = `bu' + 0.4 in `nrows'
			}
			else {
				* FESIS: one bar per year from break to end
				forvalues tt = `bt'/`tmax' {
					local ++nrows
					if `nrows' == 1 {
						qui set obs 1
						qui gen double hm_unit = .
						qui gen double hm_time = .
						qui gen double hm_coef = .
						qui gen double hm_ylo = .
						qui gen double hm_yhi = .
					}
					else {
						qui set obs `nrows'
					}
					qui replace hm_unit = `bu' in `nrows'
					qui replace hm_time = `tt' in `nrows'
					qui replace hm_coef = `bcoef' in `nrows'
					qui replace hm_ylo = `bu' - 0.4 in `nrows'
					qui replace hm_yhi = `bu' + 0.4 in `nrows'
				}
			}
		}
		
		if `nrows' == 0 {
			di as err "No breaks to plot."
			restore
			exit
		}
		
		* For overlapping breaks on same unit, sum coefficients
		* Collapse by unit-time, summing coefficients
		collapse (sum) hm_coef (first) hm_ylo hm_yhi, by(hm_unit hm_time)
		
		* Discretize colors: 6 bins (3 blue positive, 3 red negative)
		qui su hm_coef
		local cmax = max(abs(r(min)), abs(r(max)))
		if `cmax' == 0 local cmax = 1
		
		* Positive bins
		qui gen t_pos3 = hm_time if hm_coef > `cmax'*2/3
		qui gen y_pos3_lo = hm_ylo if hm_coef > `cmax'*2/3
		qui gen y_pos3_hi = hm_yhi if hm_coef > `cmax'*2/3
		
		qui gen t_pos2 = hm_time if hm_coef > `cmax'/3 & hm_coef <= `cmax'*2/3
		qui gen y_pos2_lo = hm_ylo if hm_coef > `cmax'/3 & hm_coef <= `cmax'*2/3
		qui gen y_pos2_hi = hm_yhi if hm_coef > `cmax'/3 & hm_coef <= `cmax'*2/3
		
		qui gen t_pos1 = hm_time if hm_coef > 0 & hm_coef <= `cmax'/3
		qui gen y_pos1_lo = hm_ylo if hm_coef > 0 & hm_coef <= `cmax'/3
		qui gen y_pos1_hi = hm_yhi if hm_coef > 0 & hm_coef <= `cmax'/3
		
		* Negative bins
		qui gen t_neg1 = hm_time if hm_coef < 0 & hm_coef >= -`cmax'/3
		qui gen y_neg1_lo = hm_ylo if hm_coef < 0 & hm_coef >= -`cmax'/3
		qui gen y_neg1_hi = hm_yhi if hm_coef < 0 & hm_coef >= -`cmax'/3
		
		qui gen t_neg2 = hm_time if hm_coef < -`cmax'/3 & hm_coef >= -`cmax'*2/3
		qui gen y_neg2_lo = hm_ylo if hm_coef < -`cmax'/3 & hm_coef >= -`cmax'*2/3
		qui gen y_neg2_hi = hm_yhi if hm_coef < -`cmax'/3 & hm_coef >= -`cmax'*2/3
		
		qui gen t_neg3 = hm_time if hm_coef < -`cmax'*2/3
		qui gen y_neg3_lo = hm_ylo if hm_coef < -`cmax'*2/3
		qui gen y_neg3_hi = hm_yhi if hm_coef < -`cmax'*2/3
		
		* Build layered rbar plot
		* Blue shades: 60 100 170 -> 100 140 210 -> 160 190 230
		* Red shades:  200 100 100 -> 210 150 150 -> 230 190 190
		local plots ""
		local legend_items ""
		local legend_n = 0
		
		qui count if !missing(t_pos3)
		if r(N) > 0 {
			local ++legend_n
			local plots `plots' (rbar y_pos3_lo y_pos3_hi t_pos3, ///
				barwidth(1) fcolor("60 100 170") lwidth(none))
			local legend_items `legend_items' `legend_n' "Strong +"
		}
		qui count if !missing(t_pos2)
		if r(N) > 0 {
			local ++legend_n
			local plots `plots' (rbar y_pos2_lo y_pos2_hi t_pos2, ///
				barwidth(1) fcolor("120 150 210") lwidth(none))
			local legend_items `legend_items' `legend_n' "Moderate +"
		}
		qui count if !missing(t_pos1)
		if r(N) > 0 {
			local ++legend_n
			local plots `plots' (rbar y_pos1_lo y_pos1_hi t_pos1, ///
				barwidth(1) fcolor("180 195 230") lwidth(none))
			local legend_items `legend_items' `legend_n' "Weak +"
		}
		qui count if !missing(t_neg1)
		if r(N) > 0 {
			local ++legend_n
			local plots `plots' (rbar y_neg1_lo y_neg1_hi t_neg1, ///
				barwidth(1) fcolor("230 195 190") lwidth(none))
			local legend_items `legend_items' `legend_n' "Weak -"
		}
		qui count if !missing(t_neg2)
		if r(N) > 0 {
			local ++legend_n
			local plots `plots' (rbar y_neg2_lo y_neg2_hi t_neg2, ///
				barwidth(1) fcolor("210 150 150") lwidth(none))
			local legend_items `legend_items' `legend_n' "Moderate -"
		}
		qui count if !missing(t_neg3)
		if r(N) > 0 {
			local ++legend_n
			local plots `plots' (rbar y_neg3_lo y_neg3_hi t_neg3, ///
				barwidth(1) fcolor("190 100 100") lwidth(none))
			local legend_items `legend_items' `legend_n' "Strong -"
		}
		
		* Get unit labels for y-axis
		local ylabels ""
		foreach u of local units {
			local ylabels `ylabels' `u'
		}
		
		twoway `plots', ///
			title("`title'", color("33 37 41") size(large)) ///
			subtitle("Effect", color("108 117 125") size(medium) ///
				position(2) ring(0)) ///
			xtitle("`tvar'", color("33 37 41") size(medlarge)) ///
			ytitle("`ivar'", color("33 37 41") size(medlarge)) ///
			ylabel(`ylabels', angle(0) labcolor("33 37 41") ///
				labsize(small) nogrid) ///
			xlabel(, labcolor("33 37 41") labsize(small)) ///
			legend(on order(`legend_items') ///
				cols(1) size(vsmall) position(3) ///
				region(lstyle(none) color(white))) ///
			graphregion(color(white) margin(medium)) ///
			plotregion(color(white) lstyle(none) margin(small)) ///
			name(_xtgets_heatmap, replace) ///
			`=cond("`saving'"!="", `"saving("`saving'", replace)"', "")'
		
		restore
	}
	
	* =========================================================================
	* TYPE 2: GRID — R: plot_grid(isatpanel_result)
	* BLACK line = actual (y), BLUE line = fitted, RED vertical lines = breaks
	* Matches the R output style exactly
	* =========================================================================
	
	else if "`type'" == "grid" {
		di in gr "{bf:xtgets_plot: Fitted vs Actual with Break Lines}"
		di in gr "  Replicates R: plot_grid(isatpanel_result)"
		
		if "`title'" == "" local title "Fitted vs Actual by Unit"
		
		qui levelsof `ivar', local(units)
		local n_u : word count `units'
		
		local pnum = 0
		foreach u of local units {
			local ++pnum
			
			* Build red vertical lines for breaks in this unit
			local xlines ""
			foreach ind of local retained {
				local bunit = ""
				local btime = ""
				if substr("`ind'", 1, 7) == "_fesis_" {
					local rest = substr("`ind'", 8, .)
					local pos = strpos("`rest'", "_")
					if `pos' > 0 {
						local bunit = substr("`rest'", 1, `pos'-1)
						local btime = substr("`rest'", `pos'+1, .)
					}
				}
				else if substr("`ind'", 1, 5) == "_iis_" {
					local rest = substr("`ind'", 6, .)
					local pos = strpos("`rest'", "_")
					if `pos' > 0 {
						local bunit = substr("`rest'", 1, `pos'-1)
						local btime = substr("`rest'", `pos'+1, .)
					}
				}
				else if substr("`ind'", 1, 5) == "_tis_" {
					local rest = substr("`ind'", 6, .)
					local pos = strpos("`rest'", "_")
					if `pos' > 0 {
						local bunit = substr("`rest'", 1, `pos'-1)
						local btime = substr("`rest'", `pos'+1, .)
					}
				}
				* CSIS are common (not per-unit), show for all units
				else if substr("`ind'", 1, 6) == "_csis_" {
					local bunit = "`u'"
					local rest = substr("`ind'", 7, .)
					local lpos = 0
					forvalues pp = 1/50 {
						if substr("`rest'", `pp', 1) == "_" local lpos = `pp'
					}
					if `lpos' > 0 local btime = substr("`rest'", `lpos'+1, .)
				}
				
				if "`bunit'" == "`u'" & "`btime'" != "" {
					local xlines `xlines' xline(`btime', lcolor("220 50 47") lwidth(medium) lpattern(solid))
				}
			}
			
			* R style: black=actual (cross markers), blue=fitted, red vlines
			twoway ///
				(connected `depvar' `tvar' if `ivar'==`u', ///
					lcolor(black) lwidth(medium) ///
					msymbol(plus) msize(small) mcolor(black)) ///
				(line _xtg_fitted `tvar' if `ivar'==`u', ///
					lcolor("24 116 205") lwidth(medium)), ///
				title("Unit `u'", size(medsmall) color("33 37 41")) ///
				xtitle("") ytitle("") ///
				xlabel(, labsize(vsmall) labcolor("108 117 125")) ///
				ylabel(, labsize(vsmall) labcolor("108 117 125") ///
					angle(0) nogrid) ///
				`xlines' ///
				legend(off) ///
				graphregion(color(white) margin(tiny)) ///
				plotregion(color(white) lstyle(none) margin(small)) ///
				name(_xtg_`pnum', replace) nodraw
		}
		
		* Combine
		local cmb_names ""
		forvalues pp = 1/`pnum' {
			local cmb_names `cmb_names' _xtg_`pp'
		}
		local ncols = ceil(sqrt(`n_u'))
		
		graph combine `cmb_names', ///
			title("`title'", color("33 37 41") size(large)) ///
			subtitle("{bf:Black}=y  {bf:Blue}=Fitted  {bf:Red}=FESIS", ///
				color("108 117 125") size(medsmall)) ///
			cols(`ncols') ///
			graphregion(color(white) margin(small)) ///
			l1title("`depvar'", color("33 37 41") size(small)) ///
			b1title("`tvar'", color("33 37 41") size(small)) ///
			name(_xtgets_grid, replace) ///
			`=cond("`saving'"!="", `"saving("`saving'", replace)"', "")'
		
		forvalues pp = 1/`pnum' {
			cap graph drop _xtg_`pp'
		}
		
		restore
	}
	
	* =========================================================================
	* TYPE 3: COUNTERFACTUAL — R: plot_counterfactual
	* Blue=Actual, Red dashed=Counterfactual, Green=Fitted
	* =========================================================================
	
	else if "`type'" == "counter" {
		di in gr "{bf:xtgets_plot: Counterfactual Analysis}"
		di in gr "  Replicates R: plot_counterfactual(isatpanel_result)"
		
		if "`title'" == "" local title "Actual vs Counterfactual (No Breaks)"
		
		local break_units ""
		foreach ind of local retained {
			local bunit = ""
			if substr("`ind'", 1, 7) == "_fesis_" {
				local rest = substr("`ind'", 8, .)
				local pos = strpos("`rest'", "_")
				if `pos' > 0 local bunit = substr("`rest'", 1, `pos'-1)
			}
			else if substr("`ind'", 1, 5) == "_iis_" {
				local rest = substr("`ind'", 6, .)
				local pos = strpos("`rest'", "_")
				if `pos' > 0 local bunit = substr("`rest'", 1, `pos'-1)
			}
			else if substr("`ind'", 1, 5) == "_tis_" {
				local rest = substr("`ind'", 6, .)
				local pos = strpos("`rest'", "_")
				if `pos' > 0 local bunit = substr("`rest'", 1, `pos'-1)
			}
			if "`bunit'" != "" {
				local bu = real("`bunit'")
				local already = 0
				foreach existing of local break_units {
					if `bu' == `existing' local already = 1
				}
				if `already' == 0 local break_units `break_units' `bu'
			}
		}
		
		local n_bu : word count `break_units'
		if `n_bu' == 0 {
			di as err "No unit-specific breaks found."
			restore
			exit
		}
		
		local pnum = 0
		foreach u of local break_units {
			local ++pnum
			
			* Red vertical lines at breaks
			local xlines ""
			foreach ind of local retained {
				local bunit = ""
				local btime = ""
				if substr("`ind'", 1, 7) == "_fesis_" {
					local rest = substr("`ind'", 8, .)
					local pos = strpos("`rest'", "_")
					if `pos' > 0 {
						local bunit = substr("`rest'", 1, `pos'-1)
						local btime = substr("`rest'", `pos'+1, .)
					}
				}
				else if substr("`ind'", 1, 5) == "_iis_" {
					local rest = substr("`ind'", 6, .)
					local pos = strpos("`rest'", "_")
					if `pos' > 0 {
						local bunit = substr("`rest'", 1, `pos'-1)
						local btime = substr("`rest'", `pos'+1, .)
					}
				}
				if "`bunit'" == "`u'" & "`btime'" != "" {
					local xlines `xlines' xline(`btime', lcolor("220 50 47%40") lwidth(medium))
				}
			}
			
			twoway ///
				(rarea _xtg_cf _xtg_fitted `tvar' if `ivar'==`u', ///
					fcolor("220 50 47%15") lwidth(none)) ///
				(connected `depvar' `tvar' if `ivar'==`u', ///
					lcolor(black) lwidth(medium) ///
					msymbol(plus) msize(vsmall) mcolor(black)) ///
				(line _xtg_cf `tvar' if `ivar'==`u', ///
					lcolor("220 50 47") lpattern(dash) lwidth(medium)) ///
				(line _xtg_fitted `tvar' if `ivar'==`u', ///
					lcolor("24 116 205") lwidth(medium)), ///
				title("Unit `u'", size(medsmall) color("33 37 41")) ///
				xtitle("") ytitle("") ///
				xlabel(, labsize(vsmall) labcolor("108 117 125")) ///
				ylabel(, labsize(vsmall) labcolor("108 117 125") ///
					angle(0) nogrid) ///
				`xlines' ///
				legend(off) ///
				graphregion(color(white) margin(tiny)) ///
				plotregion(color(white) lstyle(none) margin(small)) ///
				name(_xtgcf_`pnum', replace) nodraw
		}
		
		local cmb_names ""
		forvalues pp = 1/`pnum' {
			local cmb_names `cmb_names' _xtgcf_`pp'
		}
		local ncols = ceil(sqrt(`n_bu'))
		
		graph combine `cmb_names', ///
			title("`title'", color("33 37 41") size(large)) ///
			subtitle("{bf:Black}=Actual  {bf:Red}=Counterfactual  {bf:Blue}=Fitted", ///
				color("108 117 125") size(medsmall)) ///
			cols(`ncols') ///
			graphregion(color(white) margin(small)) ///
			name(_xtgets_counter, replace) ///
			`=cond("`saving'"!="", `"saving("`saving'", replace)"', "")'
		
		forvalues pp = 1/`pnum' {
			cap graph drop _xtgcf_`pp'
		}
		
		restore
	}
	
	* =========================================================================
	* TYPE 4: RESIDUALS — R: plot_residuals
	* =========================================================================
	
	else if "`type'" == "residuals" {
		di in gr "{bf:xtgets_plot: Residual Analysis}"
		di in gr "  Replicates R: plot_residuals(isatpanel_result)"
		
		if "`title'" == "" local title "Residuals by Unit"
		
		qui levelsof `ivar', local(units)
		local n_u : word count `units'
		
		qui su _xtg_resid
		local rabs = max(abs(r(min)), abs(r(max)))
		
		local pnum = 0
		foreach u of local units {
			local ++pnum
			
			twoway ///
				(rarea _xtg_resid _xtg_zero `tvar' if `ivar'==`u', ///
					fcolor("24 116 205%25") lwidth(none)) ///
				(scatter _xtg_resid `tvar' if `ivar'==`u', ///
					msymbol(O) msize(small) mcolor("24 116 205") ///
					mlwidth(vthin) mlcolor(white)) ///
				(line _xtg_resid `tvar' if `ivar'==`u', ///
					lcolor("24 116 205%60") lwidth(thin)), ///
				title("Unit `u'", size(medsmall) color("33 37 41")) ///
				xtitle("") ytitle("") ///
				xlabel(, labsize(vsmall) labcolor("108 117 125")) ///
				ylabel(, labsize(vsmall) labcolor("108 117 125") ///
					angle(0) nogrid) ///
				yline(0, lcolor("220 50 47") lpattern(dash) lwidth(thin)) ///
				yscale(range(`=-`rabs'*1.1' `=`rabs'*1.1')) ///
				legend(off) ///
				graphregion(color(white) margin(tiny)) ///
				plotregion(color(white) lstyle(none) margin(small)) ///
				name(_xtgr_`pnum', replace) nodraw
		}
		
		local cmb_names ""
		forvalues pp = 1/`pnum' {
			local cmb_names `cmb_names' _xtgr_`pp'
		}
		local ncols = ceil(sqrt(`n_u'))
		
		graph combine `cmb_names', ///
			title("`title'", color("33 37 41") size(large)) ///
			subtitle("Residuals (red dashed = zero line)", ///
				color("108 117 125") size(medsmall)) ///
			cols(`ncols') ///
			graphregion(color(white) margin(small)) ///
			name(_xtgets_resid, replace) ///
			`=cond("`saving'"!="", `"saving("`saving'", replace)"', "")'
		
		forvalues pp = 1/`pnum' {
			cap graph drop _xtgr_`pp'
		}
		
		restore
	}
	
end
