*! xtcspqardl_graph v1.1.0  29aug2026 -- publication graphics for xtcspqardl
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! github.com/merwanroudane
*!
*! Figures
*!   1  quantile process of the short-run coefficients, with a pointwise
*!      confidence band and a zero reference line
*!      (Harding, Lamarche & Pesaran 2018, Figure 4.1)
*!   2  quantile process of the long-run coefficients, same layout
*!   3  short-run and long-run overlaid, one panel per regressor
*!   4  unit-level error-correction / persistence coefficients, sorted,
*!      with the mean-group line and the convergent band
*!      (Ul-Durar et al. 2025, Figure 3)
*!   5  half-life across quantiles
*!
*! All figures read e() from the last xtcspqardl estimation, honour the
*! level() of that estimation unless overridden, and are drawn with a
*! plain white background so that they drop straight into a manuscript.

capture program drop xtcspqardl_graph
program define xtcspqardl_graph
	version 15.1
	syntax [, LEVel(cilevel) SCHeme(string) NAMEstub(string)          ///
		SAVing(string) EXPORT(string) COMBine NOCOMBine           ///
		WHICH(string) ]

	if "`e(cmd)'" != "xtcspqardl" {
		di as err "xtcspqardl_graph works only after xtcspqardl"
		exit 301
	}
	if "`level'" == "" local level = e(level)
	if "`level'" == "" local level = c(level)
	local z = invnormal(1 - (100 - `level')/200)
	if "`namestub'" == "" local namestub "xtcspq"
	if "`which'" == "" local which "sr lr both unit hl"

	local tau      "`e(tau)'"
	local ntau     : word count `tau'
	local coefnames "`e(coefnames)'"
	local lrnames   "`e(lrnames)'"
	local est       "`e(estimator)'"
	local lstr = string(`level', "%2.0f")

	if "`scheme'" != "" local schopt "scheme(`scheme')"

	tempname b V lr Vlr hl hlse unitb
	matrix `b'    = e(b_sr)
	matrix `V'    = e(V_sr)
	matrix `lr'   = e(b_lr)
	matrix `Vlr'  = e(V_lr)
	matrix `hl'   = e(halflife)
	matrix `hlse' = e(halflife_se)
	matrix `unitb'= e(unit_b)

	local made ""

	* =================================================================
	* Figures 1-3: quantile processes
	* =================================================================
	if `ntau' >= 2 {
		if strpos("`which'", "sr") {
			_xtcspq_gproc, b(`b') v(`V') tau(`tau')            ///
				names(`coefnames') z(`z') lstr(`lstr')     ///
				stub(`namestub'_sr) schopt(`schopt')       ///
				gtitle("Short-run quantile process")
			local made "`made' `r(names)'"
		}
		if strpos("`which'", "lr") & "`lrnames'" != "" {
			_xtcspq_gproc, b(`lr') v(`Vlr') tau(`tau')         ///
				names(`lrnames') z(`z') lstr(`lstr')       ///
				stub(`namestub'_lr) schopt(`schopt')       ///
				gtitle("Long-run quantile process")
			local made "`made' `r(names)'"
		}
		if strpos("`which'", "both") & "`lrnames'" != "" {
			_xtcspq_gboth, b(`b') v(`V') lrb(`lr') lrv(`Vlr') ///
				tau(`tau') names(`coefnames')              ///
				lrnames(`lrnames') z(`z') lstr(`lstr')     ///
				stub(`namestub'_both) schopt(`schopt')
			local made "`made' `r(names)'"
		}
	}
	else if strpos("`which'", "sr") | strpos("`which'", "lr") {
		di as txt "note: the quantile-process figures need at least " ///
			"two quantiles in tau(); skipped."
	}

	* =================================================================
	* Figure 4: unit-level adjustment coefficients
	* =================================================================
	if strpos("`which'", "unit") {
		* The unit matrix stores the persistence parameter lambda for
		* the one-step CS-PQARDL, whereas the reported coefficient is
		* the speed of adjustment phi = lambda - 1.  Shift the unit
		* values so that the figure and the table agree.
		local shift = 0
		local ectype = 0
		if "`est'" == "cspqardl"     local shift = -1
		if "`est'" == "cspqardl"     local ectype = 1
		if "`est'" == "cspqardl_ecm" local ectype = 1
		capture _xtcspq_gunit, unitb(`unitb') tau(`tau')           ///
			schopt(`schopt') shift(`shift') ectype(`ectype')   ///
			stub(`namestub'_unit) b(`b')                       ///
			cname("`: word 1 of `coefnames''")
		if _rc == 0 local made "`made' `r(names)'"
	}

	* =================================================================
	* Figure 5: half-life across quantiles
	* =================================================================
	if strpos("`which'", "hl") & `ntau' >= 2 {
		capture _xtcspq_ghl, hl(`hl') hlse(`hlse') tau(`tau')      ///
			z(`z') stub(`namestub'_hl) schopt(`schopt')
		if _rc == 0 local made "`made' `r(names)'"
	}

	* =================================================================
	if "`made'" == "" {
		di as txt "note: no figures were produced."
		exit
	}
	di
	di as txt "{hline 74}"
	di as txt "{bf:Figures}"
	foreach g of local made {
		di as txt "  " as res "`g'"
	}
	di as txt "  reopen one with " as res "graph display <name>" ///
		as txt ", save with " as res "graph export"
	di as txt "{hline 74}"
	if "`export'" != "" {
		foreach g of local made {
			capture graph export "`export'`g'.png", name(`g') ///
				replace width(2000)
		}
	}
end


* =====================================================================
* Quantile process, one panel per coefficient
* =====================================================================
capture program drop _xtcspq_gproc
program define _xtcspq_gproc, rclass
	syntax , B(name) V(name) TAU(numlist) NAMES(string) Z(real)       ///
		LSTR(string) STUB(string) GTITLE(string) [ SCHOPT(string) ]

	local nv   : word count `names'
	local ntau : word count `tau'

	preserve
	clear
	qui set obs `= `ntau' * `nv''
	qui gen double tau_v = .
	qui gen double est   = .
	qui gen double lo    = .
	qui gen double hi    = .
	qui gen int    vid   = .

	local r = 0
	forvalues j = 1/`nv' {
		local ti = 0
		foreach tv of local tau {
			local ++ti
			local ++r
			local c = (`ti' - 1) * `nv' + `j'
			qui replace tau_v = `tv' in `r'
			qui replace vid   = `j'  in `r'
			local e = `b'[1, `c']
			local s = `v'[`c', `c']
			qui replace est = `e' in `r'
			if `s' > 0 & `s' < . {
				qui replace lo = `e' - `z'*sqrt(`s') in `r'
				qui replace hi = `e' + `z'*sqrt(`s') in `r'
			}
		}
	}

	local glist ""
	forvalues j = 1/`nv' {
		local nm : word `j' of `names'
		local gn "`stub'`j'"
		capture {
			twoway (rarea lo hi tau_v if vid == `j',                 ///
					fintensity(inten20) lwidth(none)                ///
					fcolor(navy%18))                                ///
			       (connected est tau_v if vid == `j',              ///
					lcolor(navy) lwidth(medthick)                   ///
					mcolor(navy) msymbol(O) msize(small)),          ///
				yline(0, lcolor(gs9) lpattern(dash) lwidth(thin))   ///
				title("`nm'", size(medium) color(black))            ///
				xtitle("Quantile {&tau}", size(small))              ///
				ytitle("Coefficient", size(small))                  ///
				xlabel(`tau', labsize(small) format(%4.2f))         ///
				ylabel(, labsize(small) angle(horizontal)           ///
					format(%5.2f) grid glcolor(gs14))           ///
				legend(off)                                         ///
				graphregion(color(white) margin(medsmall))          ///
				plotregion(color(white) lcolor(gs10))               ///
				`schopt' name(`gn', replace) nodraw
		}
		if _rc == 0 local glist "`glist' `gn'"
	}
	restore

	local out ""
	if "`glist'" != "" {
		local ng : word count `glist'
		local nc = min(`ng', 3)
		capture {
			graph combine `glist',                                   ///
				title("`gtitle'", size(medlarge) color(black))   ///
				subtitle("Mean-group estimate with a `lstr'% pointwise band", ///
					size(small) color(gs6))                  ///
				cols(`nc') imargin(small)                        ///
				graphregion(color(white)) `schopt'               ///
				name(`stub', replace)
		}
		if _rc == 0 local out "`stub'"
		else local out "`glist'"
	}
	return local names "`out'"
end


* =====================================================================
* Short-run and long-run overlaid
* =====================================================================
capture program drop _xtcspq_gboth
program define _xtcspq_gboth, rclass
	syntax , B(name) V(name) LRB(name) LRV(name) TAU(numlist)         ///
		NAMES(string) LRNAMES(string) Z(real) LSTR(string)         ///
		STUB(string) [ SCHOPT(string) ]

	local nv   : word count `names'
	local nl   : word count `lrnames'
	local ntau : word count `tau'

	preserve
	clear
	qui set obs `= `ntau' * `nl''
	qui gen double tau_v = .
	qui gen double sr    = .
	qui gen double srlo  = .
	qui gen double srhi  = .
	qui gen double lr    = .
	qui gen double lrlo  = .
	qui gen double lrhi  = .
	qui gen int    vid   = .

	local r = 0
	forvalues j = 1/`nl' {
		local nm : word `j' of `lrnames'
		* position of the same name inside the short-run block
		local pos = 0
		forvalues a = 1/`nv' {
			local cn : word `a' of `names'
			if "`cn'" == "`nm'" local pos = `a'
		}
		local ti = 0
		foreach tv of local tau {
			local ++ti
			local ++r
			qui replace tau_v = `tv' in `r'
			qui replace vid   = `j'  in `r'
			local cl = (`ti' - 1) * `nl' + `j'
			local el = `lrb'[1, `cl']
			local sl = `lrv'[`cl', `cl']
			qui replace lr = `el' in `r'
			if `sl' > 0 & `sl' < . {
				qui replace lrlo = `el' - `z'*sqrt(`sl') in `r'
				qui replace lrhi = `el' + `z'*sqrt(`sl') in `r'
			}
			if `pos' > 0 {
				local cs = (`ti' - 1) * `nv' + `pos'
				local es = `b'[1, `cs']
				local ss = `v'[`cs', `cs']
				qui replace sr = `es' in `r'
				if `ss' > 0 & `ss' < . {
					qui replace srlo = `es' - `z'*sqrt(`ss') in `r'
					qui replace srhi = `es' + `z'*sqrt(`ss') in `r'
				}
			}
		}
	}

	local glist ""
	forvalues j = 1/`nl' {
		local nm : word `j' of `lrnames'
		local gn "`stub'`j'"
		capture {
			twoway (rarea lrlo lrhi tau_v if vid == `j',             ///
					lwidth(none) fcolor(maroon%15))          ///
			       (rarea srlo srhi tau_v if vid == `j',             ///
					lwidth(none) fcolor(navy%15))            ///
			       (connected lr tau_v if vid == `j',                ///
					lcolor(maroon) lwidth(medthick)          ///
					lpattern(dash) mcolor(maroon)            ///
					msymbol(D) msize(small))                 ///
			       (connected sr tau_v if vid == `j',                ///
					lcolor(navy) lwidth(medthick)            ///
					mcolor(navy) msymbol(O) msize(small)),   ///
				yline(0, lcolor(gs9) lpattern(dash) lwidth(thin)) ///
				title("`nm'", size(medium) color(black))         ///
				xtitle("Quantile {&tau}", size(small))           ///
				ytitle("Effect", size(small))                    ///
				xlabel(`tau', labsize(small) format(%4.2f))      ///
				ylabel(, labsize(small) angle(horizontal)        ///
					format(%5.2f) grid glcolor(gs14))        ///
				legend(order(4 "Short run" 3 "Long run")         ///
					size(vsmall) rows(1) position(6)         ///
					region(lstyle(none)))                    ///
				graphregion(color(white) margin(medsmall))       ///
				plotregion(color(white) lcolor(gs10))            ///
				`schopt' name(`gn', replace) nodraw
		}
		if _rc == 0 local glist "`glist' `gn'"
	}
	restore

	local out ""
	if "`glist'" != "" {
		local ng : word count `glist'
		local nc = min(`ng', 3)
		capture {
			graph combine `glist',                                   ///
				title("Short-run and long-run effects by quantile", ///
					size(medlarge) color(black))             ///
				subtitle("`lstr'% pointwise confidence bands",    ///
					size(small) color(gs6))                  ///
				cols(`nc') imargin(small)                        ///
				graphregion(color(white)) `schopt'               ///
				name(`stub', replace)
		}
		if _rc == 0 local out "`stub'"
		else local out "`glist'"
	}
	return local names "`out'"
end


* =====================================================================
* Unit-level adjustment coefficients (Ul-Durar et al. 2025, Figure 3)
* =====================================================================
capture program drop _xtcspq_gunit
program define _xtcspq_gunit, rclass
	syntax , UNITB(name) TAU(numlist) B(name)                         ///
		CNAME(string) STUB(string)                                ///
		[ SCHOPT(string) SHIFT(real 0) ECTYPE(integer 0) ]

	local nrow = rowsof(`unitb')

	* column 1 of each quantile block holds the persistence / adjustment
	* parameter; the figure uses the first requested quantile
	local ids : rownames `unitb'

	preserve
	clear
	qui set obs `nrow'
	qui gen double coefv = .
	qui gen long   unit  = .
	local ri = 0
	foreach i of local ids {
		local ++ri
		qui replace unit = `i' in `ri'
		qui replace coefv = `unitb'[`ri', 1] + `shift' in `ri'
	}
	qui drop if coefv >= .
	qui count
	if r(N) < 2 {
		restore
		return local names ""
		exit
	}
	qui sort coefv
	qui gen long rank = _n
	local nn = _N

	* mean-group value of the same parameter at the first quantile
	local mgval = `b'[1, 1]

	* reference line and wording depend on what the parameter is
	if `ectype' {
		local refline "yline(-1, lcolor(maroon) lpattern(dash) lwidth(thin))"
		local subt "units sorted; green = mean group, red = -1 (convergence needs -2 < phi < 0)"
		local gtit "Unit-level speed of adjustment"
	}
	else {
		local refline "yline(1, lcolor(maroon) lpattern(dash) lwidth(thin))"
		local subt "units sorted; green = mean group, red = 1 (unit root)"
		local gtit "Unit-level persistence"
	}

	local gn "`stub'"
	capture {
		twoway (bar coefv rank, barwidth(0.75) color(navy%70)      ///
				lwidth(none)),                             ///
			yline(0, lcolor(black) lwidth(thin))               ///
			`refline'                                          ///
			yline(`mgval', lcolor(dkgreen) lpattern(shortdash) ///
				lwidth(medium))                            ///
			title("`gtit': `cname'", size(medium)              ///
				color(black))                              ///
			subtitle("`subt'", size(vsmall) color(gs6))        ///
			xtitle("Cross-sectional unit (sorted)", size(small)) ///
			ytitle("`cname'", size(small))                     ///
			xlabel(1 `nn', labsize(small))                     ///
			ylabel(, labsize(small) angle(horizontal)          ///
				format(%5.2f) grid glcolor(gs14))          ///
			legend(off)                                        ///
			graphregion(color(white) margin(medsmall))         ///
			plotregion(color(white) lcolor(gs10))              ///
			`schopt' name(`gn', replace)
	}
	local rc = _rc
	restore
	if `rc' == 0 return local names "`gn'"
	else         return local names ""
end


* =====================================================================
* Half-life across quantiles
* =====================================================================
capture program drop _xtcspq_ghl
program define _xtcspq_ghl, rclass
	syntax , HL(name) HLSE(name) TAU(numlist) Z(real) STUB(string)    ///
		[ SCHOPT(string) ]

	local ntau : word count `tau'
	preserve
	clear
	qui set obs `ntau'
	qui gen double tau_v = .
	qui gen double h     = .
	qui gen double hlo   = .
	qui gen double hhi   = .
	local ti = 0
	foreach tv of local tau {
		local ++ti
		qui replace tau_v = `tv' in `ti'
		local hv = `hl'[1, `ti']
		if `hv' < . {
			qui replace h = `hv' in `ti'
			local hs = .
			capture local hs = `hlse'[1, `ti']
			if `hs' < . {
				qui replace hlo = max(0, `hv' - `z'*`hs') in `ti'
				qui replace hhi = `hv' + `z'*`hs' in `ti'
			}
		}
	}
	qui count if h < .
	if r(N) < 2 {
		restore
		return local names ""
		exit
	}
	local gn "`stub'"
	capture {
		twoway (rcap hlo hhi tau_v, lcolor(gs8) lwidth(thin))      ///
		       (connected h tau_v, lcolor(dkgreen)                 ///
				lwidth(medthick) mcolor(dkgreen)           ///
				msymbol(S) msize(small)),                  ///
			title("Half-life of a shock by quantile",          ///
				size(medium) color(black))                 ///
			xtitle("Quantile {&tau}", size(small))             ///
			ytitle("Periods", size(small))                     ///
			xlabel(`tau', labsize(small) format(%4.2f))        ///
			ylabel(, labsize(small) angle(horizontal)          ///
				format(%4.1f) grid glcolor(gs14))          ///
			legend(off)                                        ///
			graphregion(color(white) margin(medsmall))         ///
			plotregion(color(white) lcolor(gs10))              ///
			`schopt' name(`gn', replace)
	}
	local rc = _rc
	restore
	if `rc' == 0 return local names "`gn'"
	else         return local names ""
end
