*! version 1.0.0  30mar2026
*! midas_eforest — Exploratory forest plot (coupled, no summary diamond)
*! Split from midas_forest.ado
*! Author: Ben Adarkwa Dwamena, MD

capture program drop midas_eforest

program define midas_eforest, rclass byable(recall) sortpreserve
	version 15
	
	#delimit;
	syntax varlist(min=4 max=4 numeric) [if] [in],
		PLOTtype(string)  
		[ID(varlist min=1 max=2)
		LEVEL(integer 95)
		TITLE(passthru)  
		MScale(real 0.75)
		TEXTScale(real 1.0)  
		COMBscale(real 0.5)
		CImethod(string) CIColor(string asis) DIAMcolor(string asis) *];
	#delimit cr

	if !inlist("`plottype'", "generic", "ellipse", "thick", "rain") {
		di as error "plottype() must be one of: generic, ellipse, thick, or rain"
		exit 198
	}

	// Check xsvmat
	capture which xsvmat
	if _rc {
		display as error "You need to install the xsvmat package"
		display as error ". {stata ssc install xsvmat, replace}"
		exit 198
	}

	qui {
		global alph = (100 - `level') / 200
		global midas_noobs = _N
	}

	// Parse varlist
	tokenize `varlist'
	local tp `1'
	local fp `2'
	local fn `3'
	local tn `4'

	// Build the varlist matrix that cforest expects
	marksample touse
	
	preserve
	qui keep if `touse'
	
	if "`id'" != "" {
		egen _midas_studylabel = concat(`id'), p(" ")
	}
	else {
		gen _midas_studylabel = string(_n)
	}
	
	// Create matrix with tp fp fn tn, row-named by study ID
	mkmat `tp' `fp' `fn' `tn', mat(foresters) rownames(_midas_studylabel)
	mat colnames foresters = tp fp fn tn
	
	restore
	
	cforest, plot(`plottype') title(`title') ci(`cimethod') ///
		ms(`mscale') level(`level') text(`textscale') combscale(`combscale') ///
		cicolor(`cicolor') diamcolor(`diamcolor')
end

capture program drop cforest

program define cforest, rclass byable(recall) sortpreserve
	version 13
	
	#delimit;
	syntax [if] [in],
		PLOTtype(string)  
		[LEVEL(integer 95)
		TITLE(passthru)  
		MScale(real 0.75)
		TEXTScale(real 1.0) 
		COMBscale(real 0.5)
		CImethod(string) CIColor(string asis) DIAMcolor(string asis) *];
	#delimit cr

	qui {
		preserve
		local id: rowfullnames foresters
		local x: word count `id'
		tempvar StudyIds
		qui gen `StudyIds' = ""
		forvalues i = 1/`x' {
			local bb: word `i' of `id'
			qui replace `StudyIds' = "`bb'" in `i'
		}
		xsvmat double foresters, norestore names(col) rownames(`StudyIds')
		
		// Calculate study-specific sensitivity with CI
		tempvar sens sensvar sensse senslo senshi sss
		gen __midas_dis = tp + fn
		midas_cii __midas_dis tp, p(`sens') lowerci(`senslo') ///
			upperci(`senshi') cimethod(`cimethod') level(`level')
		gen double `sensse' = (`senshi' - `senslo') / (2 * invnormal(0.975))
		gen double `sensvar' = invnormal(0.975) * `sensse'

		// Calculate study-specific specificity with CI
		tempvar spec specvar specse speclo spechi
		gen __midas_ndis = tn + fp
		midas_cii __midas_ndis tn, p(`spec') lowerci(`speclo') ///
			upperci(`spechi') cimethod(`cimethod') level(`level')
		gen double `specse' = (`spechi' - `speclo') / (2 * invnormal(0.975))
		gen double `specvar' = invnormal(0.975) * `specse'
		
		gen `sss' = strlen(`StudyIds')
		sum `sss', meanonly
		local ss4 = int(r(max) + 50)
		format `StudyIds' %-`ss4's

		local gtitle1 "Sensitivity"
		local gtitle2 "Specificity"

		tempvar studyvar1 studyvar2 studyvar1lo studyvar1hi
		tempvar studyvar2lo studyvar2hi xvar
		tempname obs obs1 obs2 obs3 obs4
		tempname forplot1 forplot2 forplot ellip1 ellip2
		tempname generic1 generic2 thick1 thick2 rain1 rain2
		
		gen `obs' = _n
		gen `obs1' = _n
		gen `obs2' = _n  
		gen `obs3' = _n
		gen `obs4' = _n
		gen `xvar' = 0
		gen double `studyvar1' = `sens'
		gen double `studyvar1lo' = `senslo'
		gen double `studyvar1hi' = `senshi'
		gen double `studyvar2' = `spec'
		gen double `studyvar2lo' = `speclo'
		gen double `studyvar2hi' = `spechi'
		gsort -`StudyIds'
		
		local null1: di " "
		count
		local max = r(N)
		local maxx = `max' + 2
		
		label value `obs' obs
		forval i = 1/`max' {
			local value = `"`value' `i'"'
			label define obs `i' "`=`StudyIds'[`i']'", modify
		}

		local ylab1 "labsize(*`textscale') tl(*2) labgap(*3) labc(bg) tlc(none)"
		local ylabopt "labsize(*`textscale') tl(*0) labgap(*3)"
		local xlab0 "xlab(0(.5)1.0, format(%2.1f) labsize(*`textscale') labc(bg) tlc(none))"
		local xlab1 "xlab(0(.5)1.0, format(%2.1f) labcolor(bg) tlcolor(bg)) xscale(lcolor(bg))"
		local xlab2 "xlab(0(.5)1.0, format(%2.1f) labsize(*`textscale'))"

		qui tostring `studyvar1lo' `studyvar1' `studyvar1hi', ///
			gen(`studyvar1lo'1 `studyvar1'1 `studyvar1hi'1) format(%3.2f) force
		replace `studyvar1lo'1 = " [" + `studyvar1lo'1 + " - "
		replace `studyvar1hi'1 = `studyvar1hi'1 + "]"
		egen studyvar1ci = concat(`studyvar1'1 `studyvar1lo'1 `studyvar1hi'1)
		label value `obs1' obs1

		forval i = 1/`max' {
			local value1 = `"`value' `i'"'
			label define obs1 `i' "`=studyvar1ci[`i']'", modify
		}
		
		qui tostring `studyvar2lo' `studyvar2' `studyvar2hi', ///
			gen(`studyvar2lo'1 `studyvar2'1 `studyvar2hi'1) format(%3.2f) force
		replace `studyvar2lo'1 = " [" + `studyvar2lo'1 + " - "
		replace `studyvar2hi'1 = `studyvar2hi'1 + "]"
		egen studyvar2ci = concat(`studyvar2'1 `studyvar2lo'1 `studyvar2hi'1)
		label value `obs2' obs2

		forval i = 1/`max' {
			local value2 = `"`value' `i'"'
			label define obs2 `i' "`=studyvar2ci[`i']'", modify
		}  

		local null " "

		gen TP = tp
		gen TN = tn
		gen FP = fp
		gen FN = fn

		// Create 2x2 table plots
		foreach k of varlist TP FP FN TN {
			format `k' %9.0f
			egen s`k' = total(`k')
			local total = s`k'[_N]
			local sum: di "`total'"
			local contid: di "`k'"
			gen obs`k' = _n
			gen xvalue`k' = 0
			label value obs`k' obsk
			forval i = 1/`max' {
				local value`k' = `"`value' `i'"'
				label define obsk `i' "`=`k'[`i']'", modify
			}
			local graphlist "`graphlist' plot`k'"
			twoway (scatter obs`k' xvalue`k', ms(i) ///
				ylabel(`maxx' "{bf: `contid'}" `"`value`k''"', ///
				valuelabel `ylabopt' angle(360)) lpat(blank) `xlab0'), ///
				yscale(noline) fxsize(5) ///
				nodraw legend(off) yti("") ///
				plotregion(style(none)) graphregion(style(none)) ///
				xtitle("") name(plot`k', replace)
		}

		twoway (scatter `obs' `xvar', ms(i) ///
			ylabel(`maxx' "{bf: Studyid}" `"`value'"', ///
			valuelabel `ylabopt' angle(360)) ///
			lpat(blank) `xlab0'), xscale(noline) ///
			yscale(noline) ///
			nodraw legend(off) fxsize(20) yti("") xtitle("") ///
			plotregion(style(none)) graphregion(style(none)) ///
			name(`forplot', replace)

		twoway (scatter `obs1' `xvar', ms(i) ///
			ylab(`maxx' "{bf: `gtitle1' `midaconf'}" `"`value1'"', ///
			valuelabel labsize(*`textscale') labgap(*3) angle(360)) lpat(blank) `xlab0') ///
			, plotregion(style(none)) graphregion(style(none)) ///
			yscale(noline) nodraw legend(off) ///
			yti("") xtitle("") fxsize(22) ///
			name(`forplot1', replace) ylab(, noticks)

		twoway (scatter `obs2' `xvar', ms(i) ///
			ylab(`maxx' "{bf: `gtitle2' `midaconf'}" `"`value2'"', ///
			valuelabel labsize(*`textscale') labgap(*3) angle(360)) lpat(blank) `xlab0') ///
			, plotregion(style(none)) graphregion(style(none)) ///
			yscale(noline) nodraw legend(off) ylab(, noticks) ///
			yti("") xtitle("") fxsize(25) ///
			name(`forplot2', replace)
		 
		// Create plots based on plot type
		if (strpos("`plottype'", "ellipse") != 0) {
			forv i = 1/`max' {
				range t`i' 0 `=2*c(pi)' 1000
				local a`i' = `senshi' - `sens' in `i'
				local xc`i' = `sens' in `i'
				local yc`i' = `i' in `i'
				gen xt`i' = max(`xc`i'' + `a`i'' * cos(t`i'), 0)
				gen yt`i' = `yc`i'' + sin(t`i')
				qui replace yt`i' = (yt`i' + `i') * .5
				local graph`i' `"(area yt`i' xt`i', lwidth(none) fcolor(blue))"'
				local xplot1 `"(scatteri `i' `xc`i'', msymbol(|) mcolor(black) msize(medium))"'
				local gellip "`gellip' `graph`i'' `xplot1'"
			}

			#delimit;
			graph twoway `gellip' (scatteri `maxx' 0.5 (3) "{bf: `gtitle1'}", ms(i) mlabc(black) mlabsize(*0.85)), 
				ytitle("") xtitle("") fxsize(20) yscale(off) legend(off) plotregion(style(none)) 
				xlab(0(0.25)1) graphregion(style(none)) title("") nodraw name(`ellip1', replace);
			#delimit cr

			forv i = 1/`max' {
				range st`i' 0 `=2*c(pi)' 1000
				local sa`i' = `spechi' - `spec' in `i'
				local sxc`i' = `spec' in `i'
				local syc`i' = `i' in `i'
				gen sxt`i' = max(`sxc`i'' + `sa`i'' * cos(st`i'), 0)
				gen syt`i' = `syc`i'' + sin(t`i')
				qui replace syt`i' = (syt`i' + `i') * .5
				local sgraph`i' `"(area syt`i' sxt`i', lwidth(none) fcolor(blue))"'
				local xplot2 `"(scatteri `i' `sxc`i'', msymbol(|) mcolor(black) msize(medium))"'
				local spellip "`spellip' `sgraph`i'' `xplot2'"
			}

			#delimit;
			graph twoway `spellip' (scatteri `maxx' 0.5 (3) "{bf: `gtitle2'}", ms(i) mlabc(black) mlabsize(*0.85)), 
				ytitle("") xtitle("") fxsize(20) yscale(off) legend(off) plotregion(style(none)) 
				title("") xlab(0(0.25)1) graphregion(style(none)) nodraw name(`ellip2', replace);
			#delimit cr

			#delimit;
			nois graph combine `forplot' `graphlist' `ellip1' `forplot1' `ellip2' `forplot2', rows(1) ycommon iscale(`combscale');
			#delimit cr
		}
		else if (strpos("`plottype'", "generic") != 0) {
			
			forvalues k = 1/`max' {
				local `sens'`k' = `sens' in `k'
				local `senslo'`k' = `senslo' in `k'
				local `senshi'`k' = `senshi' in `k'
				local plot`k' `"(pci `k' ``senslo'`k'' `k' ``senshi'`k'', lcolor(blue) lwidth(medium) lpat(solid))(scatteri `k' ``sens'`k'', msymbol(S) mcolor(black) msize(*1.0))"'
				local ggeneric1 "`ggeneric1' `plot`k''"
			}
			
			#delimit;
			graph twoway `ggeneric1' (scatteri `maxx' 0.5 (3) "{bf: `gtitle1'}", ms(i) mlabc(black) mlabsize(*0.85)), 
				ytitle("") xtitle("") yscale(off) xlab(0(0.5)1.0) fxsize(20) ylab(none)
				legend(off) plotregion(style(none)) nodraw graphregion(style(none)) name(`generic1', replace);
			#delimit cr
			
			forvalues k = 1/`max' {
				local `spec'`k' = `spec' in `k'
				local `speclo'`k' = `speclo' in `k'
				local `spechi'`k' = `spechi' in `k'
				local plot`k' `"(pci `k' ``speclo'`k'' `k' ``spechi'`k'', lcolor(blue) lwidth(medium) lpat(solid))(scatteri `k' ``spec'`k'', msymbol(S) mcolor(black) msize(*1.0))"'
				local ggeneric2 "`ggeneric2' `plot`k''"
			}
			 
			#delimit;
			graph twoway `ggeneric2' (scatteri `maxx' 0.5 (3) "{bf: `gtitle2'}", ms(i) mlabc(black) mlabsize(*0.85)), 
				ytitle("") xtitle("") fxsize(20) yscale(off) xlab(0(0.5)1.0)
				legend(off) nodraw plotregion(style(none)) graphregion(style(none)) name(`generic2', replace);
			#delimit cr
			
			* Use taller graph to give rows more space
			local _ysize = max(8, `max' * 0.28)
			#delimit;
			nois graph combine `forplot' `graphlist' `generic1' `forplot1' `generic2' `forplot2', rows(1) ycommon  iscale(`combscale')
				ysize(`_ysize') xsize(18);
			#delimit cr
		}
		else if (strpos("`plottype'", "thick") != 0) {
			forvalues k = 1/`max' {
				local `sens'`k' = `sens' in `k'
				local `senslo'`k' = `senslo' in `k'
				local `senshi'`k' = `senshi' in `k'
				local plot11`k' `"(pci `k' ``senslo'`k'' `k' ``senshi'`k'', lcol(blue) lpat(solid) lwidth(medium))"'
				local plot12`k' `"(scatteri `k' ``sens'`k'', msymbol(|) mcolor(black) msize(medium))"'
				local gthick1 `"`gthick1' `plot11`k'' `plot12`k''"'
			}
			 
			#delimit;
			graph twoway `gthick1' (scatteri `maxx' 0.5 (3) "{bf: `gtitle1'}", ms(i) mlabc(black) mlabsize(*0.85)), 
				ytitle("") xtitle("") fxsize(20) yscale(off) xlab(0(0.5)1.0) legend(off) nodraw  
				plotregion(style(none)) graphregion(style(none)) name(`thick1', replace);
			#delimit cr

			forvalues k = 1/`max' {
				local `spec'`k' = `spec' in `k'
				local `speclo'`k' = `speclo' in `k'
				local `spechi'`k' = `spechi' in `k'
				local plot21`k' `"(pci `k' ``speclo'`k'' `k' ``spechi'`k'', lwidth(medium) lcol(blue) lpat(solid))"'
				local plot22`k' `"(scatteri `k' ``spec'`k'', msymbol(|) mcolor(black) msize(medium))"'
				local gthick2 `"`gthick2' `plot21`k'' `plot22`k''"'
			}
			
			#delimit;
			graph twoway `gthick2' (scatteri `maxx' 0.5 (3) "{bf: `gtitle2'}", ms(i) mlabc(black) mlabsize(*0.85)), 
				ytitle("") xtitle("") fxsize(20) yscale(off) xlab(0(0.5)1.0)  
				legend(off) nodraw plotregion(style(none)) graphregion(style(none)) name(`thick2', replace);
			#delimit cr
			
			#delimit;
			nois graph combine `forplot' `graphlist' `thick1' `forplot1' `thick2' `forplot2', rows(1) ycommon iscale(`combscale');
			#delimit cr
		}
		else if (strpos("`plottype'", "rain") != 0) {
			local npoints = 1000
			forvalues k = 1/`max' {
				tempvar x yupper ylower
				local mu`k' = `sens' in `k'
				local musd`k' = `sensse' in `k'
				local mulow`k' = `senslo' in `k'
				local muhi`k' = `senshi' in `k'
				local tp`k' = tp in `k'
				local fn`k' = fn in `k'
				qui range `x'`k' `mulow`k'' `muhi`k'' `npoints'
				qui gen double `yupper'`k' = `tp`k'' * log(`x'`k') + `fn`k'' * log(1 - `x'`k')
				qui summ `yupper'`k'
				local ymax = r(min)
				qui replace `yupper'`k' = (`yupper'`k' - `ymax') * 0.1
				qui gen double `ylower'`k' = -`yupper'`k'
				qui replace `yupper'`k' = `yupper'`k' + `k'
				qui replace `ylower'`k' = `ylower'`k' + `k'
				qui summ `x'`k'
				local xmin`k' = r(min)
				local xmax`k' = r(max)
				local xmean`k' = r(mean)

				local rainplot11`k' `"(rarea `ylower'`k' `yupper'`k' `x'`k', lwidth(none) fcolor(blue))"'
				local rainplot12`k' `"(pci `k' `xmin`k'' `k' `xmax`k'', lcolor(black) lwidth(thin) lpat(solid))"'
				local rainplot13`k' `"(scatteri `k' `xmean`k'', msymbol(|) mcolor(black) msize(medium))"'
				local rainplot`k' `"`rainplot11`k'' `rainplot12`k'' `rainplot13`k''"'
				local grain1 "`grain1' `rainplot`k''"
			}
			
			#delimit;
			graph twoway `grain1' (scatteri `maxx' 0.5 (3) "{bf: `gtitle1'}", ms(i) mlabc(black) mlabsize(*0.85)),
				ytitle("") xtitle("") fxsize(20) yscale(off) legend(off) xlab(0(0.5)1.0) nodraw
				plotregion(style(none)) graphregion(style(none)) name(`rain1', replace);
			#delimit cr

			forvalues k = 1/`max' {
				tempvar x yupper ylower
				local mu`k' = `spec' in `k'
				local musd`k' = `specse' in `k'
				local mulow`k' = `speclo' in `k'
				local muhi`k' = `spechi' in `k'
				local fp`k' = fp in `k'
				local tn`k' = tn in `k'
				qui range `x'`k' `mulow`k'' `muhi`k'' `npoints'
				qui gen double `yupper'`k' = `tn`k'' * log(`x'`k') + `fp`k'' * log(1 - `x'`k')
				qui summ `yupper'`k'
				local ymax = r(min)
				qui replace `yupper'`k' = (`yupper'`k' - `ymax') * 0.1
				qui gen double `ylower'`k' = -`yupper'`k'
				qui replace `yupper'`k' = `yupper'`k' + `k'
				qui replace `ylower'`k' = `ylower'`k' + `k'
				qui summ `x'`k'
				local xmin`k' = r(min)
				local xmax`k' = r(max)
				local xmean`k' = r(mean)
				local rainplot21`k' `"(rarea `ylower'`k' `yupper'`k' `x'`k', lwidth(none) fcolor(blue))"'
				local rainplot22`k' `"(pci `k' `xmin`k'' `k' `xmax`k'', lcolor(black) lwidth(thin) lpat(solid))"'
				local rainplot23`k' `"(scatteri `k' `xmean`k'', msymbol(|) mcolor(black) msize(medium))"'
				local rainplot`k' `"`rainplot21`k'' `rainplot22`k'' `rainplot23`k''"'
				local grain2 "`grain2' `rainplot`k''"
			}
			
			#delimit;
			graph twoway `grain2' (scatteri `maxx' 0.5 (3) "{bf: `gtitle2'}", ms(i) mlabc(black) mlabsize(*0.85)),
				ytitle("") xtitle("") fxsize(20) yscale(off) legend(off) xlab(0(0.5)1.0) nodraw
				plotregion(style(none)) graphregion(style(none)) name(`rain2', replace);
			#delimit cr

			#delimit;
			nois graph combine `forplot' `graphlist' `rain1' `forplot1' `rain2' `forplot2', rows(1) ycommon iscale(`combscale');
			#delimit cr  
		}
		
		capture restore
	}

	capture estimates restore _midas_estimates
end

program define midas_cii
version 16

syntax varlist [if] [in], p(name) lowerci(name) upperci(name) [cimethod(string) level(real 95)]
		
qui {	
		tokenize `varlist'
		gen `p' = .
		gen `lowerci' = .
		gen `upperci' = .
			
		count `if' `in'
		forvalues i = 1/`r(N)' {
		local N = `1'[`i']
		local n = `2'[`i']
		if `N' ==0 & `n' ==0 {
		replace `p' = 0 in `i'
		replace `lowerci' = 0 in `i'
		replace `upperci' = 0 in `i'	
		}
		else {
		cii proportions `N' `n', `cimethod' level(`level')
				
		replace `p' = r(proportion) in `i'
		replace `lowerci' = r(lb) in `i'
		replace `upperci' = r(ub) in `i'
			}
		}
}
end
