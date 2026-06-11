*! xtcsnardl_graph v1.0.0  28may2026  Dr Merwan Roudane  merwanroudane920@gmail.com
*! Publication-quality graphs for CS-NARDL (no author names in titles).
*! Called by xtcsnardl with option {bf:graph}.
*!
*! Produces:
*!   1. ECT panel-bar     (phi_i per cross-section)        name(csn_ect)
*!   2. LR asymmetry      (beta+ vs beta- grouped bar+CI)  name(csn_lr_asym)
*!   3. Dynamic multiplier(m+, m- with asymmetry CI band)  name(csn_multip_<v>)
*!   4. IRF +/- shock     (impulse responses)              name(csn_irf_<v>)
*!   5. CSA loadings      (heatmap-style horizontal bar)   name(csn_csa)

capture program drop xtcsnardl_graph
program define xtcsnardl_graph
	version 15.1
	syntax, EC(string) IVar(string) ///
		ASYMvars(string) POSvars(string) NEGvars(string) ///
		[Periods(integer 20) DEPvar(string)]

	di
	di in smcl in gr "{hline 78}"
	di in gr "  {bf:Generating publication-quality CS-NARDL plots}"
	di in smcl in gr "{hline 78}"

	* ---------------------------------------------------------------
	* 1. ECT bar chart per panel
	* ---------------------------------------------------------------
	_csn_plot_ect, ec(`ec') ivar(`ivar')

	* ---------------------------------------------------------------
	* 2. LR asymmetric beta+ vs beta-
	* ---------------------------------------------------------------
	_csn_plot_lr_asym, ec(`ec') ///
		posvars(`posvars') negvars(`negvars') asymvars(`asymvars')

	* ---------------------------------------------------------------
	* 3+4. Dynamic multiplier + IRF for every asymmetric variable
	* ---------------------------------------------------------------
	local nasym : word count `asymvars'
	forvalues i = 1/`nasym' {
		local av : word `i' of `asymvars'
		local pv : word `i' of `posvars'
		local nv : word `i' of `negvars'

		_csn_plot_multiplier, ec(`ec') ivar(`ivar') ///
			av(`av') pv(`pv') nv(`nv') periods(`periods') idx(`i')

		_csn_plot_irf, ec(`ec') ivar(`ivar') ///
			av(`av') pv(`pv') nv(`nv') periods(`periods') idx(`i')
	}

	* ---------------------------------------------------------------
	* 5. CSA loadings panel
	* ---------------------------------------------------------------
	capture _csn_plot_csa, ec(`ec') depvar(`depvar')

	di in smcl in gr "{hline 78}"
end


* =============================================================================
* PLOT 1: ECT per panel
* =============================================================================
program define _csn_plot_ect
	syntax, EC(string) IVar(string)

	local n = wordcount("$iis")
	if `n' == 0 exit

	preserve
	clear
	qui set obs `n'
	qui gen panel_num = _n
	qui gen str20 panel_lbl = ""
	qui gen phi = .
	qui gen lo = .
	qui gen hi = .
	qui gen cat = .

	local k = 0
	foreach i of global iis {
		local ++k
		qui replace panel_lbl = "`i'" in `k'
		capture local b  = _b[`ivar'_`i':`ec']
		if !_rc {
			qui replace phi = `b' in `k'
			capture local se = _se[`ivar'_`i':`ec']
			if !_rc & `se' > 0 {
				qui replace lo = `b' - 1.96*`se' in `k'
				qui replace hi = `b' + 1.96*`se' in `k'
			}
			if `b' < -0.5       qui replace cat = 1 in `k'
			else if `b' < -0.1  qui replace cat = 2 in `k'
			else if `b' < 0     qui replace cat = 3 in `k'
			else                qui replace cat = 4 in `k'
		}
	}

	qui count if phi != .
	if r(N) == 0 {
		di in ye "  ECT graph: no per-panel coefficients available (DFE pools them)."
		restore
		exit
	}

	qui sum phi
	local mean_phi = r(mean)

	* yline only if mean_phi is non-missing
	local meanline ""
	if `mean_phi' != . {
		local meanline yline(`mean_phi', lcolor("128 0 128") lwidth(medthin) lpattern(dash))
	}

	#delimit ;
	twoway
		(bar phi panel_num if cat==1, color("31 119 180%85") lcolor("31 119 180")
		    barwidth(0.7))
		(bar phi panel_num if cat==2, color("44 160 44%85")  lcolor("44 160 44")
		    barwidth(0.7))
		(bar phi panel_num if cat==3, color("255 127 14%85") lcolor("255 127 14")
		    barwidth(0.7))
		(bar phi panel_num if cat==4, color("214 39 40%85")  lcolor("214 39 40")
		    barwidth(0.7))
		(rcap hi lo panel_num, lcolor(gs6) lwidth(thin)),
		title("{bf:Error-correction speed of adjustment by panel}",
		    size(medlarge) color(black))
		subtitle("Cross-sectionally augmented panel NARDL",
		    size(small) color(gs5))
		ytitle("ECT coefficient {&phi}{sub:i}", size(small))
		xtitle("Panel (cross-section)", size(small))
		xlabel(1/`n', valuelabel labsize(vsmall) angle(45))
		ylabel(, format(%5.2f) angle(0) labsize(small)
		    grid glcolor(gs14) glpattern(dot))
		yline(0, lcolor(gs8) lwidth(thin))
		`meanline'
		legend(order(1 "Strong ({&phi}<-0.5)" 2 "Moderate" 3 "Weak"
		             4 "Non-convergent" 5 "95% CI")
		    position(6) ring(1) rows(1) size(vsmall)
		    region(lcolor(gs14) fcolor(white%90)))
		note("Dashed purple line: mean {&phi} across panels.",
		    size(vsmall) color(gs7))
		graphregion(fcolor(white) lcolor(white))
		plotregion(fcolor(white) lcolor(gs14) margin(small))
		name(csn_ect, replace);
	#delimit cr

	di in gr "  Graph saved: " in ye "csn_ect"
	restore
end


* =============================================================================
* PLOT 2: LR beta+ vs beta-
* =============================================================================
program define _csn_plot_lr_asym
	syntax, EC(string) POSvars(string) NEGvars(string) ASYMvars(string)

	local nasym : word count `asymvars'
	if `nasym' == 0 exit

	preserve
	clear
	qui set obs `=`nasym'*2'
	qui gen str20 vlbl = ""
	qui gen xpos = .
	qui gen coef = .
	qui gen lo = .
	qui gen hi = .
	qui gen shock = .

	local row = 0
	forvalues i = 1/`nasym' {
		local av : word `i' of `asymvars'
		local pv : word `i' of `posvars'
		local nv : word `i' of `negvars'

		* positive
		local ++row
		qui replace vlbl  = "`av'" in `row'
		qui replace xpos  = `i' - 0.17 in `row'
		qui replace shock = 1 in `row'
		capture local bp = _b[`ec':`pv']
		if !_rc {
			qui replace coef = `bp' in `row'
			capture local sep = _se[`ec':`pv']
			if !_rc & `sep' > 0 {
				qui replace lo = `bp' - 1.96*`sep' in `row'
				qui replace hi = `bp' + 1.96*`sep' in `row'
			}
		}

		* negative
		local ++row
		qui replace vlbl  = "`av'" in `row'
		qui replace xpos  = `i' + 0.17 in `row'
		qui replace shock = 2 in `row'
		capture local bn = _b[`ec':`nv']
		if !_rc {
			qui replace coef = `bn' in `row'
			capture local sen = _se[`ec':`nv']
			if !_rc & `sen' > 0 {
				qui replace lo = `bn' - 1.96*`sen' in `row'
				qui replace hi = `bn' + 1.96*`sen' in `row'
			}
		}
	}

	* Label X values for each variable label
	qui gen xtick = floor(xpos+0.5)
	qui levelsof xtick, local(xticks)
	local lbls ""
	foreach x of local xticks {
		qui levelsof vlbl if xtick == `x', local(lbl) clean
		local lbls `lbls' `x' "`lbl'"
	}

	#delimit ;
	twoway
		(bar coef xpos if shock==1, color("31 119 180%80") lcolor("31 119 180")
		    barwidth(0.30))
		(bar coef xpos if shock==2, color("214 39 40%80")  lcolor("214 39 40")
		    barwidth(0.30))
		(rcap hi lo xpos, lcolor(gs6) lwidth(thin)),
		title("{bf:Long-run asymmetric coefficients}",
		    size(medlarge) color(black))
		subtitle("{&beta}{sup:+} vs {&beta}{sup:-} in the cointegrating vector",
		    size(small) color(gs5))
		ytitle("Long-run coefficient", size(small))
		xtitle("Asymmetric regressor", size(small))
		xlabel(`lbls', labsize(small))
		ylabel(, format(%5.3f) angle(0) labsize(small)
		    grid glcolor(gs14) glpattern(dot))
		yline(0, lcolor(gs8) lwidth(thin))
		legend(order(1 "{&beta}{sup:+} (positive)" 2 "{&beta}{sup:-} (negative)" 3 "95% CI")
		    position(6) ring(1) rows(1) size(small)
		    region(lcolor(gs14) fcolor(white%90)))
		graphregion(fcolor(white) lcolor(white))
		plotregion(fcolor(white) lcolor(gs14) margin(small))
		name(csn_lr_asym, replace);
	#delimit cr

	di in gr "  Graph saved: " in ye "csn_lr_asym"
	restore
end


* =============================================================================
* PLOT 3: cumulative dynamic multiplier with asymmetry CI band
* =============================================================================
program define _csn_plot_multiplier
	syntax, EC(string) IVar(string) AV(string) PV(string) NV(string) ///
		Periods(integer) IDX(integer)

	* Mean ECT across convergent panels (or pooled if MG-style not present)
	local sum_b = 0
	local n_conv = 0
	local sum_se2 = 0
	foreach i of global iis {
		local b = .
		capture local b  = _b[`ivar'_`i':`ec']
		if _rc continue
		if `b' == . continue
		if `b' < 0 & `b' > -2 {
			local sum_b = `sum_b' + `b'
			local n_conv = `n_conv' + 1
			local se = .
			capture local se = _se[`ivar'_`i':`ec']
			if !_rc & `se' != . local sum_se2 = `sum_se2' + (`se')^2
		}
	}
	local mean_phi = .
	local se_phi = .
	if `n_conv' == 0 {
		capture local mean_phi = _b[SR:`ec']
		if _rc local mean_phi = .
		capture local se_phi   = _se[SR:`ec']
		if _rc local se_phi = .
		if `mean_phi' == . {
			capture local mean_phi = _b[`ec']
			capture local se_phi   = _se[`ec']
		}
		if `mean_phi' == . {
			di in ye "  multiplier plot: ECT unavailable for `av'."
			exit
		}
	}
	else {
		local mean_phi = `sum_b'/`n_conv'
		local se_phi   = sqrt(`sum_se2')/`n_conv'
	}

	capture local bp  = _b[`ec':`pv']
	capture local sep = _se[`ec':`pv']
	capture local bn  = _b[`ec':`nv']
	capture local sen = _se[`ec':`nv']
	if _rc {
		di in ye "  multiplier plot: LR coefs unavailable for `av'."
		exit
	}

	preserve
	clear
	qui set obs `=`periods'+1'
	qui gen period = _n - 1
	qui gen m_pos  = .
	qui gen m_neg  = .
	qui gen lr_pos = `bp'
	qui gen lr_neg = `bn'
	qui gen asym   = .
	qui gen asym_lo = .
	qui gen asym_hi = .

	local gap_p = 1
	local gap_n = -1
	forvalues h = 0/`periods' {
		if `h' == 0 {
			local mp = 0
			local mn = 0
		}
		else {
			local gap_p = `gap_p' + `mean_phi'*(`gap_p' - `bp')
			local gap_n = `gap_n' + `mean_phi'*(`gap_n' - `bn')
			local mp = `gap_p'
			local mn = `gap_n'
		}
		qui replace m_pos = `mp' in `=`h'+1'
		qui replace m_neg = `mn' in `=`h'+1'
		local a = `mp' - `mn'
		local se_a = sqrt((`sep')^2 + (`sen')^2)
		qui replace asym    = `a' in `=`h'+1'
		qui replace asym_lo = `a' - 1.96*`se_a' in `=`h'+1'
		qui replace asym_hi = `a' + 1.96*`se_a' in `=`h'+1'
	}

	* Three-panel layout: multipliers + asymmetry band
	#delimit ;
	twoway
		(rarea asym_hi asym_lo period, color("128 128 128%25") lwidth(none))
		(line m_pos  period, lcolor("31 119 180") lwidth(medthick))
		(line m_neg  period, lcolor("214 39 40")  lwidth(medthick))
		(line lr_pos period, lcolor("31 119 180") lwidth(vthin) lpattern(dash))
		(line lr_neg period, lcolor("214 39 40")  lwidth(vthin) lpattern(dash))
		(line asym   period, lcolor("0 0 0")      lwidth(medthin) lpattern(longdash)),
		title("{bf:Cumulative dynamic multipliers: `av'}",
		    size(medlarge) color(black))
		subtitle("Response to positive vs negative shocks (CS-NARDL)",
		    size(small) color(gs5))
		ytitle("Cumulative response", size(small))
		xtitle("Periods after shock (h)", size(small))
		xlabel(0(`=ceil(`periods'/10)')`periods', labsize(small))
		ylabel(, format(%5.3f) angle(0) labsize(small)
		    grid glcolor(gs14) glpattern(dot))
		yline(0, lcolor(gs8) lwidth(thin))
		legend(order(2 "m{sup:+}(h)" 3 "m{sup:-}(h)"
		             4 "{&beta}{sup:+} long-run" 5 "{&beta}{sup:-} long-run"
		             6 "Asymmetry m{sup:+}-m{sup:-}"
		             1 "95% CI on asymmetry")
		    position(6) ring(1) cols(3) size(vsmall)
		    region(lcolor(gs14) fcolor(white%90)))
		note("Mean {&phi}=" "`: di %6.4f `mean_phi''" "    {&beta}{sup:+}=" "`: di %6.4f `bp''"
		     "    {&beta}{sup:-}=" "`: di %6.4f `bn''",
		    size(vsmall) color(gs6))
		graphregion(fcolor(white) lcolor(white))
		plotregion(fcolor(white) lcolor(gs14) margin(small))
		name(csn_multip_`idx', replace);
	#delimit cr

	di in gr "  Graph saved: " in ye "csn_multip_`idx'" in gr "  (`av')"
	restore
end


* =============================================================================
* PLOT 4: IRF for +/- shocks
* =============================================================================
program define _csn_plot_irf
	syntax, EC(string) IVar(string) AV(string) PV(string) NV(string) ///
		Periods(integer) IDX(integer)

	local sum_b = 0
	local n_conv = 0
	foreach i of global iis {
		local b = .
		capture local b = _b[`ivar'_`i':`ec']
		if _rc continue
		if `b' == . continue
		if `b' < 0 & `b' > -2 {
			local sum_b = `sum_b' + `b'
			local n_conv = `n_conv' + 1
		}
	}
	local mean_phi = .
	if `n_conv' == 0 {
		capture local mean_phi = _b[SR:`ec']
		if _rc local mean_phi = .
		if `mean_phi' == . {
			capture local mean_phi = _b[`ec']
			if _rc local mean_phi = .
		}
		if `mean_phi' == . exit
	}
	else local mean_phi = `sum_b'/`n_conv'

	capture local bp = _b[`ec':`pv']
	capture local bn = _b[`ec':`nv']
	if _rc exit

	preserve
	clear
	qui set obs `=`periods'+1'
	qui gen period = _n - 1
	qui gen y_pos = .
	qui gen y_neg = .
	qui gen tgt_pos = `bp'
	qui gen tgt_neg = `bn'

	local yp = 0
	local yn = 0
	forvalues h = 0/`periods' {
		if `h' == 0 {
			local yp = 0
			local yn = 0
		}
		else {
			local yp = `yp' + `mean_phi'*(`yp' - `bp')
			local yn = `yn' + `mean_phi'*(`yn' - `bn')
		}
		qui replace y_pos = `yp' in `=`h'+1'
		qui replace y_neg = `yn' in `=`h'+1'
	}

	#delimit ;
	twoway
		(line y_pos   period, lcolor("31 119 180") lwidth(medthick))
		(line tgt_pos period, lcolor("31 119 180") lwidth(vthin) lpattern(dash))
		(line y_neg   period, lcolor("214 39 40")  lwidth(medthick))
		(line tgt_neg period, lcolor("214 39 40")  lwidth(vthin) lpattern(dash)),
		title("{bf:Asymmetric impulse responses: `av'}",
		    size(medlarge) color(black))
		subtitle("Unit-shock response to positive (+) and negative (-) components",
		    size(small) color(gs5))
		ytitle("Response of Y", size(small))
		xtitle("Periods after shock", size(small))
		xlabel(0(`=ceil(`periods'/10)')`periods', labsize(small))
		ylabel(, format(%5.3f) angle(0) labsize(small)
		    grid glcolor(gs14) glpattern(dot))
		yline(0, lcolor(gs8) lwidth(thin))
		legend(order(1 "y after positive shock"
		             3 "y after negative shock"
		             2 "long-run target ({&beta}{sup:+})"
		             4 "long-run target ({&beta}{sup:-})")
		    position(6) ring(1) cols(2) size(vsmall)
		    region(lcolor(gs14) fcolor(white%90)))
		graphregion(fcolor(white) lcolor(white))
		plotregion(fcolor(white) lcolor(gs14) margin(small))
		name(csn_irf_`idx', replace);
	#delimit cr

	di in gr "  Graph saved: " in ye "csn_irf_`idx'" in gr "  (`av')"
	restore
end


* =============================================================================
* PLOT 5: CSA loadings (one bar per CSA variable)
* =============================================================================
program define _csn_plot_csa
	syntax, EC(string) [DEPvar(string)]

	* Discover CSA variables from the model: coefs with name pattern csa_*
	tempname b
	matrix `b' = e(b)
	local ncoef = colsof(`b')
	if `ncoef' == 0 exit

	local rownames : colfullnames `b'

	preserve
	clear
	tempfile tmp
	qui set obs 1
	qui gen str40 name = ""
	qui gen coef = .
	qui gen lo = .
	qui gen hi = .
	qui save `tmp', replace

	local row = 0
	foreach cn of local rownames {
		* Match patterns containing "csa_" in second token after ':'
		local eqname : word 1 of `=subinstr("`cn'",":"," ",.)'
		local vname  : word 2 of `=subinstr("`cn'",":"," ",.)'
		if "`eqname'" != "`ec'" continue
		if !regexm("`vname'", "csa_") continue

		capture local b1  = _b[`cn']
		if _rc continue
		capture local se1 = _se[`cn']
		if _rc | `se1' == 0 | `se1' == . continue

		clear
		qui set obs 1
		qui gen str40 name = "`vname'"
		qui gen coef = `b1'
		qui gen lo   = `b1' - 1.96*`se1'
		qui gen hi   = `b1' + 1.96*`se1'
		qui append using `tmp'
		qui save `tmp', replace
	}

	use `tmp', clear
	qui drop if coef == .
	qui count
	if r(N) == 0 {
		restore
		exit
	}
	qui gen ord = _n

	#delimit ;
	twoway
		(bar coef ord, color("100 100 200%80") horizontal barwidth(0.65))
		(rcap hi lo ord, lcolor(gs6) lwidth(thin) horizontal),
		title("{bf:CSA (cross-sectional average) loadings}",
		    size(medlarge) color(black))
		subtitle("Nuisance coefficients absorbing unobserved common factors",
		    size(small) color(gs5))
		xtitle("Loading on cross-sectional average", size(small))
		ytitle("CSA proxy", size(small))
		ylabel(1(1)`r(N)', valuelabel labsize(vsmall))
		xlabel(, format(%5.3f) labsize(small) grid glcolor(gs14) glpattern(dot))
		xline(0, lcolor(gs8) lwidth(thin))
		legend(order(1 "Coef." 2 "95% CI")
		    position(6) ring(1) rows(1) size(vsmall)
		    region(lcolor(gs14) fcolor(white%90)))
		graphregion(fcolor(white) lcolor(white))
		plotregion(fcolor(white) lcolor(gs14) margin(small))
		name(csn_csa, replace);
	#delimit cr

	di in gr "  Graph saved: " in ye "csn_csa"
	restore
end
