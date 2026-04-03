*! version 1.0.0  30mar2026
*! midas_sforest — Summary forest plot (post-estimation with pooled diamond)
*! Split from midas_forest.ado
*! Author: Ben Adarkwa Dwamena, MD

capture program drop midas_sforest

program define midas_sforest, rclass byable(recall) sortpreserve
	version 15
	
	#delimit;
	syntax [if] [in],
		PLOTtype(string)  
		[LEVEL(integer 95)
		TITLE(passthru)  
		MScale(real 1.0)
		TEXTScale(real 1.0)
		PREDinterval
		OVLine
		CImethod(string) CIColor(string asis) DIAMcolor(string asis) *];
	#delimit cr

	// Restore midas estimates if available
	cap estimates restore _midas_estimates
	
	// Check that previous estimation was from midas package
	capture assert e(package) == "midas"
	if _rc != 0 {
		di as error "Last estimation command was not a midas subcommand"
		di as error "Please run midas mle, qrsim, mh, hmc, or inla first"
		error 301
	}

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

	if "`predinterval'" == "predinterval" {
		sforest, plot(`plottype') title(`title') ci(`cimethod') ///
			ms(`mscale') level(`level') text(`textscale') ///
			cicolor(`cicolor') diamcolor(`diamcolor') `predinterval' `ovline'
	}
	else {
		sforest, plot(`plottype') title(`title') ci(`cimethod') ///
			ms(`mscale') level(`level') text(`textscale') `ovline'
	}
end

capture program drop sforest

program define sforest, rclass byable(recall) sortpreserve
	version 15
	
	#delimit;
	syntax [if] [in],
		PLOTtype(string)  
		[LEVEL(integer 95)
		TITLE(passthru)  
		MScale(real 1.0)
		TEXTScale(real 1.0)
		PREDinterval
		OVLine
		CImethod(string) CIColor(string asis) DIAMcolor(string asis) *];
	#delimit cr

	capture preserve
	qui {
		// Extract summary estimates based on estimation method
		if e(cmd) == "midas_mle" {
			tempname bfor Vfor forestmat
			mat `bfor' = e(bsum)
			mat `Vfor' = e(Vsum)
			_coef_table, bmatrix(`bfor') vmatrix(`Vfor')
			mat `forestmat' = r(table)'
			local mvar1 = `forestmat'[1,1]
			local mvar1lo = `forestmat'[1,5]
			local mvar1hi = `forestmat'[1,6]
			local mvar2 = `forestmat'[2,1]
			local mvar2lo = `forestmat'[2,5]
			local mvar2hi = `forestmat'[2,6]
		}
		else if e(cmd) == "midas_inla" | e(cmd) == "midas_mh" | e(cmd) == "midas_hmc" {
			tempvar sen spe
			if e(cmd) == "midas_mh" {
				local _mf = e(midas_filename)
				clear
				qui use "`_mf'", clear
			}
			else {
				mat data = e(midas_sim_data)
				clear
				qui svmat data, names(col)
			}
			gen double `sen' = invlogit(logitsen)
			gen double `spe' = invlogit(logitspe)
			midas sumstats `sen' `spe'
			local mvar1 = r(mn1)
			local mvar1lo = r(lb1)
			local mvar1hi = r(ub1)
			local mvar2 = r(mn2)
			local mvar2lo = r(lb2)
			local mvar2hi = r(ub2)
		}
		
		// Extract study data
		mat foresters = e(varlist)
		
		// Normalize column names — may be tempvar names after bayesparallel
		local nc = colsof(foresters)
		if `nc' >= 4 {
			mat colnames foresters = tp fp fn tn
		}
		local id: rowfullnames foresters
		local x: word count `id'
		tempvar StudyIds
		qui gen `StudyIds' = ""
		forvalues i = 1/`x' {
			local bb: word `i' of `id'
			qui replace `StudyIds' = "`bb'" in `i'
		}
		xsvmat double foresters, norestore names(col) rownames(`StudyIds')
		
		if ~missing(e(sortby)) {
			gen idd = _n
			gsort -idd
		}
		
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
		
		// Format study IDs
		gen `sss' = strlen(`StudyIds')
		sum `sss', meanonly
		local ss4 = int(r(max) + 50)
		format `StudyIds' %-`ss4's

		local gtitle1 "Sensitivity"
		local gtitle2 "Specificity"
		local wgttitle1 "SeWgt(%)"
		local wgttitle2 "SpWgt(%)"

		// Create variables for plotting
		tempvar studyvar1 studyvar2 studyvar1lo studyvar1hi
		tempvar studyvar2lo studyvar2hi xvar wgtsen wgtspe
		 
		tempname obs obs1 obs2 obs3 obs4 ellip1 ellip2
		tempname forplot1 forplot2 forplot3 forplot4 forplot
		tempname generic1 generic2 thick1 thick2 rain1 rain2
		tempvar senswgt specwgt
		
		gen `obs' = _n
		gen `obs1' = _n
		gen `obs2' = _n
		gen `obs3' = _n
		gen `obs4' = _n
		gen `xvar' = 0
		gen `studyvar1' = `sens'
		gen `studyvar1lo' = `senslo'
		gen `studyvar1hi' = `senshi'
		gen `studyvar2' = `spec'
		gen `studyvar2lo' = `speclo'
		gen `studyvar2hi' = `spechi'

		// Extract study weights
		// Extract study weights via standardized helper
		tempvar _bivwgt
		_midas_getwgts, senwgt(`wgtsen') spewgt(`wgtspe') bivwgt(`_bivwgt')
		gsort -`StudyIds'
		
		local null1: di " "
		count
		local max = r(N)
		local maxx = `max' + 2
		local maxxx = `max' + 3
		
		// Create value labels for study IDs
		label value `obs' obs
		forval i = 1/`max' {
			local value = `"`value' `i'"'
			label define obs `i' "`=`StudyIds'[`i']'", modify
		}

		// Define label options
		local ylab1 "labsize(*`textscale') tl(*2) labgap(*5) labc(bg) tlc(none)"
		local ylabopt "labsize(*`textscale') tl(*0) labgap(*5)"
		local xlab0 "xlab(0(.5)1.0, format(%2.1f) labsize(*`textscale') labc(bg) tlc(none))"
		local xlab1 "xlab(0(.5)1.0, format(%2.1f) labcolor(bg) tlcolor(bg)) xscale(lcolor(bg))"
		local xlab2 "xlab(0(.5)1.0, format(%2.1f) labsize(*`textscale'))"

		// Format confidence intervals for sensitivity
		tostring `studyvar1lo' `studyvar1' `studyvar1hi', ///
			gen(`studyvar1lo'1 `studyvar1'1 `studyvar1hi'1) format(%3.2f) force
		replace `studyvar1lo'1 = " [" + `studyvar1lo'1 + " - "
		replace `studyvar1hi'1 = `studyvar1hi'1 + "]"
		egen studyvar1ci = concat(`studyvar1'1 `studyvar1lo'1 `studyvar1hi'1)
		label value `obs1' obs1

		forval i = 1/`max' {
			local value1 = `"`value' `i'"'
			label define obs1 `i' "`=studyvar1ci[`i']'", modify
		}
		
		// Format confidence intervals for specificity
		tostring `studyvar2lo' `studyvar2' `studyvar2hi', ///
			gen(`studyvar2lo'1 `studyvar2'1 `studyvar2hi'1) format(%3.2f) force
		replace `studyvar2lo'1 = " [" + `studyvar2lo'1 + " - "
		replace `studyvar2hi'1 = `studyvar2hi'1 + "]"
		egen studyvar2ci = concat(`studyvar2'1 `studyvar2lo'1 `studyvar2hi'1)
		 
		label value `obs2' obs2

		forval i = 1/`max' {
			local value2 = `"`value' `i'"'
			label define obs2 `i' "`=studyvar2ci[`i']'", modify
		}

		// Format weights
		tostring `wgtsen', gen(`wgtsen'1) format(%3.2f) force
		tostring `wgtspe', gen(`wgtspe'1) format(%3.2f) force
		label value `obs3' obs3
		label value `obs4' obs4
		
		forval i = 1/`max' {
			local value3 = `"`value' `i'"'
			label define obs3 `i' "`=`wgtsen'1[`i']'", modify
		}

		forval i = 1/`max' {
			local value4 = `"`value' `i'"'
			label define obs4 `i' "`=`wgtspe'1[`i']'", modify
		}

		local null " "

		// Create 2x2 table variables
		gen TP = tp
		gen TN = tn
		gen FP = fp
		gen FN = fn

		// Format summary statistics
		local note1f: di " " %3.2f `mvar1' "[" %3.2f `mvar1lo' " - " %3.2f `mvar1hi' "]"
		local note2f: di " " %3.2f `mvar2' "[" %3.2f `mvar2lo' " - " %3.2f `mvar2hi' "]"
		local graphlist ""
		
		// Summary point markers
		local spoint11 "(scatteri -0.8 `mvar1' -1.2 `mvar1lo' -1.6 `mvar1' -1.2 `mvar1hi' -1.6 `mvar1' -1.2 `mvar1hi',"
		local _dcol = cond(!missing("`diamcolor'"), "`diamcolor'", "green")
		local spoint12 " bcolor(`_dcol') c(l) s(i) nodropbase recast(area))"
		local spoint21 "(scatteri -0.8 `mvar2' -1.2 `mvar2lo' -1.6 `mvar2' -1.2 `mvar2hi' -1.6 `mvar2' -1.2 `mvar2hi',"
		local spoint22 " bcolor(`_dcol') c(l) s(i) nodropbase recast(area))"

		// Calculate prediction interval if requested
		if !missing("`predinterval'") {
			tempname blogit Vlogit predmat
			mat `blogit' = e(b)
			mat `Vlogit' = e(V)
			_coef_table, bmatrix(`blogit') vmatrix(`Vlogit')
			mat `predmat' = r(table)'
			local theta1 = `predmat'[1,1]
			local theta2 = `predmat'[2,1]
			local vartheta1 = `predmat'[3,1]
			local vartheta2 = `predmat'[4,1]
			local tausq1 = `predmat'[1,2] * `predmat'[1,2]
			local tausq2 = `predmat'[2,2] * `predmat'[2,2]
			local pialpha = (100 - `level') / 200
			local senspil = invlogit(`theta1' + invt($midas_noobs - 3.0, `pialpha') * sqrt(`vartheta1' + `tausq1'))
			local senspiu = invlogit(`theta1' + invt($midas_noobs - 3.0, 1 - `pialpha') * sqrt(`vartheta1' + `tausq1'))
			local predpoint1 "(scatteri -3.0 `senspil' -3.0 `senspiu', clcolor(red) c(l) s(i) lpat(solid) lwidth(medthick))"
			local specpil = invlogit(`theta2' + invt($midas_noobs - 3.0, `pialpha') * sqrt(`vartheta2' + `tausq2'))
			local specpiu = invlogit(`theta2' + invt($midas_noobs - 3.0, 1 - `pialpha') * sqrt(`vartheta2' + `tausq2'))
			local predpoint2 "(scatteri -3.0 `specpil' -3.0 `specpiu', clcolor(red) c(l) s(i) lpat(solid) lwidth(medthick))"
			local prednote1: di "[" %3.2f `senspil' " - " %3.2f `senspiu' "]"
			local prednote2: di "[" %3.2f `specpil' " - " %3.2f `specpiu' "]"
			local predint: di "{bf:Prediction Interval}"
		}

		// Extract I² statistics for heterogeneity
		tempname bIsquareds VIsquareds hetsmat
		mat `bIsquareds' = e(bIsquared)
		mat `VIsquareds' = e(VIsquared)
		_coef_table, bmatrix(`bIsquareds') vmatrix(`VIsquareds')
		mat `hetsmat' = r(table)'
		local I2sen_md = `hetsmat'[1,1]
		local I2sen_lb = max(`hetsmat'[1,5], 0)
		local I2sen_ub = min(1, `hetsmat'[1,6])
		local I2spe_md = `hetsmat'[2,1]
		local I2spe_lb = max(`hetsmat'[2,5], 0)
		local I2spe_ub = min(1, `hetsmat'[2,6])
		local I2_md = `hetsmat'[3,1]
		local I2_lb = max(`hetsmat'[3,5], 0)
		local I2_ub = min(1, `hetsmat'[3,6])
		local notef1a: di "{bf:I{sup:2}(Sensitivity)} = " %3.2f `I2sen_md' " [" %3.2f `I2sen_lb' "-" %3.2f `I2sen_ub' "]"
		local notef2a: di "{bf:I{sup:2}(Specificity)} = " %3.2f `I2spe_md' " [" %3.2f `I2spe_lb' "-" %3.2f `I2spe_ub' "]"
		local note1c: di "{bf:I{sup:2}(Bivariate)} = " %3.2f `I2_md' " [" %3.2f `I2_lb' "-" %3.2f `I2_ub' "]"
		local i2note `"note("`notef1a'    `notef2a'    `note1c'", size(*0.6) span)"'

		// Create plots for 2x2 table cells
		foreach k of varlist TP FP FN TN {
			format `k' %9.0f
			egen s`k' = total(`k')
			local total = s`k'[_N]
			local sum: di "`total'"
			local contid: di "{bf:`k'}"
			gen obs`k' = _n
			gen xvalue`k' = 0
			label value obs`k' obsk
			forval i = 1/`max' {
				local value`k' = `"`value' `i'"'
				label define obsk `i' "`=`k'[`i']'", modify
			}
			local graphlist "`graphlist' plot`k'"
			#delimit;
			twoway (scatter obs`k' xvalue`k', ms(i)
				ylabel(`maxx' "`contid'" -1 "`sum'" -3.0 "`null'" -5.0 "`null1'" `"`value`k''"',
				valuelabel `ylabopt' angle(360)) lpat(blank) `xlab0'),
				yscale(noline) fxsize(5) plotregion(style(none)) graphregion(style(none))
				nodraw legend(off) yti("") xtitle("") name(plot`k', replace);
			#delimit cr
		}
		
		// Create main study ID plot
		if !missing("`predinterval'") {
			#delimit;
			twoway (scatter `obs' `xvar', ms(i) 
				ylab(`maxx' "{bf:Studyid}" -1 "{bf:Overall}" -3.0 "`predint'" `"`value'"', 
				valuelabel `ylabopt' angle(360)) lpat(blank) `xlab0'), 
				ytick(none) xscale(noline) plotregion(style(none))
				graphregion(style(none)) ysc(alternate) yscale(noline) nodraw legend(off) fxsize(25) yti("") xtitle("") name(`forplot', replace);
			#delimit cr
		}
		else {
			#delimit;
			twoway (scatter `obs' `xvar', ms(i) 
				ylab(`maxx' "{bf:Studyid}" -1 "{bf:Overall}" `"`value'"', 
				valuelabel `ylabopt' angle(360)) lpat(blank) `xlab0'), 
				ytick(none) xscale(noline) plotregion(style(none))
				graphregion(style(none)) ysc(alternate) yscale(noline) nodraw legend(off) fxsize(25) yti("") xtitle("") name(`forplot', replace);
			#delimit cr
		}

		// Create weight plots
		#delimit;
		twoway (scatter `obs3' `xvar', ms(i) 
			ylab(`maxx' "{bf:`wgttitle1'}" -1 "100.00" `"`value3'"', 
			valuelabel labsize(*`textscale') labgap(*5) angle(360)) lpat(blank) `xlab0'), 
			ylabel(, noticks) yscale(noline) fxsize(10) nodraw legend(off) yti("") xtitle("") 
			graphregion(style(none)) plotregion(style(none)) name(`forplot1', replace);
		#delimit cr
		
		#delimit;
		twoway (scatter `obs4' `xvar', ms(i) 
			ylab(`maxx' "{bf:`wgttitle2'}" -1 "100.00" `"`value4'"',
			valuelabel labsize(*`textscale') labgap(*5) angle(360)) lpat(blank) `xlab0'), 
			nodraw legend(off) xtitle("") fxsize(10)
			ylabel(, noticks) yti("") yscale(noline) plotregion(style(none)) graphregion(style(none)) name(`forplot2', replace);
		#delimit cr
		
		// Create CI plots with or without prediction intervals
		if !missing("`predinterval'") {
			#delimit;
			twoway (scatter `obs1' `xvar', ms(i) 
				ylab(`maxx' "{bf:`gtitle1' `midaconf'}" -3.0 "`prednote1'" -1 "`note1f'"
				`"`value1'"', valuelabel labsize(*`textscale') labgap(*5) angle(360)) lpat(blank) `xlab0'), 
				ylabel(, noticks) plotregion(style(none)) graphregion(style(none)) yscale(noline) nodraw legend(off) yti("")
				xtitle("") fxsize(20) name(`forplot3', replace);
			#delimit cr

			#delimit;
			twoway (scatter `obs2' `xvar', ms(i) 
				ylab(`maxx' "{bf:`gtitle2' `midaconf'}" -3.0 "`prednote2'" -1 "`note2f'"
				`"`value2'"', valuelabel labsize(*`textscale') labgap(*5) angle(360)) lpat(blank) `xlab0'), 
				plotregion(style(none)) graphregion(style(none)) yscale(noline) nodraw legend(off) ylabel(, noticks) yti("")
				xtitle("") fxsize(20) name(`forplot4', replace);
			#delimit cr
		}
		else {
			#delimit;
			twoway (scatter `obs1' `xvar', ms(i) 
				ylab(`maxx' "{bf:`gtitle1' `midaconf'}" -1 "`note1f'"
				`"`value1'"', valuelabel labsize(*`textscale') labgap(*5) angle(360)) lpat(blank) `xlab0'), 
				ylabel(, noticks) plotregion(style(none)) graphregion(style(none)) yscale(noline) nodraw legend(off) yti("")
				xtitle("") fxsize(20) name(`forplot3', replace);
			#delimit cr

			#delimit;
			twoway (scatter `obs2' `xvar', ms(i) 
				ylab(`maxx' "{bf:`gtitle2' `midaconf'}" -1 "`note2f'"
				`"`value2'"', valuelabel labsize(*`textscale') labgap(*5) angle(360)) lpat(blank) `xlab0'), 
				plotregion(style(none)) graphregion(style(none)) yscale(noline) nodraw legend(off) ylabel(, noticks) yti("")
				xtitle("") fxsize(20) name(`forplot4', replace);
			#delimit cr    
		}

		// Add overall lines if requested
		if !missing("`ovline'") {
			local ovline1 "xline(`mvar1', lpatt(-) noextend)"
			local ovline2 "xline(`mvar2', lpatt(-) noextend)"
		}

		// Create plots based on plot type
		if (strpos("`plottype'", "generic") != 0) {
			// Generic plot type with squares and confidence intervals
			forvalues k = 1/`max' {
				local `senswgt'`k' = `wgtsen' in `k'
				local `sens'`k' = `sens' in `k'
				local `senslo'`k' = `senslo' in `k'
				local `senshi'`k' = `senshi' in `k'
				local weight`k' = 0.25 * ``senswgt'`k''
				local wgt`k': di "`weight`k''"
				local _cicol = cond(!missing("`cicolor'"), "`cicolor'", "black")
				local plot`k' `"(pci `k' ``senslo'`k'' `k' ``senshi'`k'', lcolor(`_cicol') lwidth(vthin) lpat(solid))(scatteri `k' ``sens'`k'', msymbol(S) mcolor(blue*`wgt`k'') msize(*`wgt`k''))"'
				local ggeneric1 "`ggeneric1' `plot`k''"
			}

			#delimit;
			graph twoway `ggeneric1' (scatteri `maxx' 0.5 (3) "{bf: `gtitle1'}", ms(i) mlabc(black))
				(scatter `obs1' `xvar', ms(i) ylabel(`maxx' "{bf:`gtitle1'}" -1 "`null1'" `"`value'"', 
				valuelabel angle(360)) blpattern(solid) blwidth(vthin) blcolor(black) lpat(blank) `xlab2') 
				`spoint11' `spoint12' `predpoint1', 
				plotregion(style(none)) graphregion(style(none)) yscale(off) fxsize(30) ylab(none) `ovline1' 
				ytitle("") xtitle("") legend(off) nodraw name(`generic1', replace);
			#delimit cr
			
			forvalues k = 1/`max' {
				local `specwgt'`k' = `wgtspe' in `k'
				local `spec'`k' = `spec' in `k'
				local `speclo'`k' = `speclo' in `k'
				local `spechi'`k' = `spechi' in `k'
				local weight`k' = 0.25 * ``specwgt'`k''
				local wgt`k': di "`weight`k''"
				local plot`k' `"(pci `k' ``speclo'`k'' `k' ``spechi'`k'', lcolor(black) lwidth(vthin) lpat(solid))(scatteri `k' ``spec'`k'', msymbol(S) mcolor(blue*`wgt`k'') msize(*`wgt`k''))"'
				local ggeneric2 "`ggeneric2' `plot`k''"
			}
			
			#delimit;
			graph twoway `ggeneric2' (scatteri `maxx' 0.5 (3) "{bf: `gtitle2'}", ms(i) mlabc(black))
				(scatter `obs2' `xvar', ms(i) ylabel(`maxx' "{bf:`gtitle2'}" -1 "`null1'" `"`value'"', 
				valuelabel angle(360)) blpattern(solid) blwidth(vthin) blcolor(black) lpat(blank) `xlab2') 
				`spoint21' `spoint22' `predpoint2', 
				ytitle("") xtitle("") fxsize(25) yscale(off) ylab(none) `ovline2' legend(off) nodraw
				plotregion(style(none)) graphregion(style(none)) name(`generic2', replace);
			#delimit cr

			#delimit;
			nois graph combine `forplot' `graphlist' `generic1' `forplot3' `forplot1' `generic2' `forplot4' `forplot2', ycommon rows(1) `i2note';
			#delimit cr
		}
		else if (strpos("`plottype'", "thick") != 0) {
			// Thick plot type with weighted confidence intervals
			forvalues k = 1/`max' {
				local `senswgt'`k' = `wgtsen' in `k'
				local `sens'`k' = `sens' in `k'
				local `senslo'`k' = `senslo' in `k'
				local `senshi'`k' = `senshi' in `k'
				local weight`k' = 0.75 * ``senswgt'`k''
				local wgt`k': di "`weight`k''"
				local plot11`k' `"(pci `k' ``senslo'`k'' `k' ``senshi'`k'', lcolor(blue*`wgt`k'') lpat(solid) lwidth(*`wgt`k''))"'
				local plot12`k' `"(scatteri `k' ``sens'`k'', msymbol(|) mcolor(black) msize(vlarge))"'
				local gthick1 `"`gthick1' `plot11`k''`plot12`k''"'
			}
			
			#delimit;
			graph twoway `gthick1' (scatteri `maxx' 0.5 (3) "{bf: `gtitle1'}", ms(i) mlabc(black))
				(scatter `obs1' `xvar', ms(i) ylabel(`maxx' "{bf:`gtitle1'}" -1 "`null1'" `"`value'"', 
				nolabel angle(360)) blpattern(solid) blwidth(vthin) blcolor(black) lpat(blank) `xlab2') 
				`spoint11' `spoint12' `predpoint1', 
				plotregion(style(none)) graphregion(style(none)) yscale(off) fxsize(30) ylab(none) `ovline1' 
				ytitle("") xtitle("") legend(off) nodraw name(`thick1', replace);
			#delimit cr

			forvalues k = 1/`max' {
				local `specwgt'`k' = `wgtspe' in `k'
				local `spec'`k' = `spec' in `k'
				local `speclo'`k' = `speclo' in `k'
				local `spechi'`k' = `spechi' in `k'
				local weight`k' = 0.75 * ``specwgt'`k''
				local wgt`k': di "`weight`k''"
				local plot21`k' `"(pci `k' ``speclo'`k'' `k' ``spechi'`k'', lcolor(blue*`wgt`k'') lpat(solid) lwidth(*`wgt`k''))"'
				local plot22`k' `"(scatteri `k' ``spec'`k'', msymbol(|) mcolor(black) msize(vlarge))"'
				local gthick2 "`gthick2' `plot21`k''`plot22`k''"
			}
			
			#delimit;
			graph twoway `gthick2' (scatteri `maxx' 0.5 (3) "{bf: `gtitle2'}", ms(i) mlabc(black))
				(scatter `obs2' `xvar', ms(i) ylabel(`maxx' "{bf:`gtitle2'}" -1 "`null1'" `"`value'"', 
				valuelabel angle(360)) lpat(blank) blpattern(solid) blwidth(vthin) blcolor(black) `xlab2') 
				`spoint21' `spoint22' `predpoint2', 
				ylab(none) ytitle("") xtitle("") fxsize(25) yscale(off) `ovline2' legend(off) nodraw
				plotregion(style(none)) graphregion(style(none)) name(`thick2', replace);
			#delimit cr

			#delimit;
			nois graph combine `forplot' `graphlist' `thick1' `forplot3' `forplot1' `thick2' `forplot4' `forplot2', ycommon rows(1) `i2note';
			#delimit cr
		}
		else if (strpos("`plottype'", "rain") != 0) {
			// Rain plot type with likelihood distributions
			local npoints = 1000
			forvalues k = 1/`max' {
				tempvar x yupper ylower
				local `senswgt'`k' = `wgtsen' in `k'
				local weight`k' = 0.2 * ``senswgt'`k''
				local xlower`k' = `senslo' in `k'
				local xupper`k' = `senshi' in `k'
				local tp`k' = tp in `k'
				local fn`k' = fn in `k'
				qui range `x'`k' `xlower`k'' `xupper`k'' `npoints'
				qui gen double `yupper'`k' = `tp`k'' * log(`x'`k') + `fn`k'' * log(1 - `x'`k')
				qui summ `yupper'`k'
				local ymin = r(min)
				qui replace `yupper'`k' = (`yupper'`k' - `ymin') * `weight`k'' * 0.1
				qui gen double `ylower'`k' = -`yupper'`k'
				qui replace `yupper'`k' = `yupper'`k' + `k'
				qui replace `ylower'`k' = `ylower'`k' + `k'
				qui summ `x'`k'
				local xmin`k' = r(min)
				local xmax`k' = r(max)
				local xmean`k' = r(mean)
				 
				local wgt`k': di "``senswgt'`k''"
				local rainplot11`k' `"(rarea `ylower'`k' `yupper'`k' `x'`k', lwidth(none) fcolor(blue) fintensity(*`wgt`k''))"'
				local rainplot12`k' `"(pci `k' `xmin`k'' `k' `xmax`k'', lcolor(black) lwidth(medthick) lpat(solid))"'
				local rainplot13`k' `"(scatteri `k' `xmean`k'', msymbol(|) mcolor(black) msize(vlarge))"'
				local rainplot`k' `"`rainplot11`k'' `rainplot12`k'' `rainplot13`k''"'
				local graphrain1 "`graphrain1' `rainplot`k''"
			}
			
			#delimit;
			graph twoway `graphrain1' (scatteri `maxx' 0.5 (3) "{bf: `gtitle1'}", ms(i) mlabc(black))
				(scatter `obs1' `xvar', ms(i) ylabel(`maxx' "{bf:`gtitle1'}" -1 "`null1'" `"`value'"', 
				valuelabel angle(360)) lpat(blank) blpattern(solid) blwidth(vthin) blcolor(black) `xlab2') 
				`spoint11' `spoint12' `predpoint1',
				plotregion(style(none)) graphregion(style(none)) yscale(off) fxsize(30) ylab(none) `ovline1'
				ytitle("") xtitle("") legend(off) nodraw name(`rain1', replace);
			#delimit cr
			
			forvalues k = 1/`max' {
				tempvar x yupper ylower
				local `specwgt'`k' = `wgtspe' in `k'
				local weight`k' = 0.2 * ``specwgt'`k''
				local xlower`k' = `speclo' in `k'
				local xupper`k' = `spechi' in `k'
				local fp`k' = fp in `k'
				local tn`k' = tn in `k'
				qui range `x'`k' `xlower`k'' `xupper`k'' `npoints'
				qui gen double `yupper'`k' = `tn`k'' * log(`x'`k') + `fp`k'' * log(1 - `x'`k')
				qui summ `yupper'`k'
				local ymax = r(min)
				qui replace `yupper'`k' = (`yupper'`k' - `ymax') * `weight`k'' * 0.1
				qui gen double `ylower'`k' = -`yupper'`k'
				qui replace `yupper'`k' = `yupper'`k' + `k'
				qui replace `ylower'`k' = `ylower'`k' + `k'
				qui summ `x'`k'
				local xmin`k' = r(min)
				local xmax`k' = r(max)
				local xmean`k' = r(mean)
				local wgt`k': di "``specwgt'`k''"
				local rainplot21`k' `"(rarea `ylower'`k' `yupper'`k' `x'`k', lwidth(none) fcolor(blue) fintens(*`wgt`k''))"'
				local rainplot22`k' `"(pci `k' `xmin`k'' `k' `xmax`k'', lcolor(black) lwidth(medthick) lpat(solid))"'
				local rainplot23`k' `"(scatteri `k' `xmean`k'', msymbol(|) mcolor(black) msize(vlarge))"'
				local rainplot`k' `"`rainplot21`k'' `rainplot22`k'' `rainplot23`k''"'
				local graphrain2 "`graphrain2' `rainplot`k''"
			}
			
			#delimit;
			graph twoway `graphrain2' (scatteri `maxx' 0.5 (3) "{bf: `gtitle2'}", ms(i) mlabc(black))
				(scatter `obs2' `xvar', ms(i) ylabel(`maxx' "{bf:`gtitle2'}" -1 "`null1'" `"`value'"', 
				valuelabel angle(360)) lpat(blank) blpattern(solid) blwidth(vthin) blcolor(black) `xlab2') 
				`spoint21' `spoint22' `predpoint2',
				plotregion(style(none)) graphregion(style(none)) ytitle("") xtitle("") fxsize(25) yscale(off) ylab(none)
				legend(off) `ovline2' nodraw name(`rain2', replace);
			#delimit cr
			
			#delimit;
			nois graph combine `forplot' `graphlist' `rain1' `forplot3' `forplot1' `rain2' `forplot4' `forplot2', ycommon rows(1) `i2note';
			#delimit cr
		}
		else if (strpos("`plottype'", "ellipse") != 0) {
			// Ellipse plot type
			forvalues k = 1/`max' {
				local `senswgt'`k' = `wgtsen' in `k'
				local weight`k' = 0.1 * ``senswgt'`k''
				range t`k' 0 `=2*c(pi)' 1000
				local a`k' = `senshi' - `sens' in `k'
				local b`k' = `weight`k''
				local xc`k' = `sens' in `k'
				local yc`k' = `k' in `k'
				gen xt`k' = max(`xc`k'' + `a`k'' * cos(t`k'), 0)
				gen yt`k' = `yc`k'' + `b`k'' * sin(t`k')
				qui replace yt`k' = yt`k'
				local wgt`k': di "``senswgt'`k''"
				local graph`k' `"(area yt`k' xt`k', lwidth(none) fcolor(blue) fintensity(*`wgt`k''))"'
				local xplot1 `"(scatteri `k' `xc`k'', msymbol(|) mcolor(black) msize(vlarge))"'
				local gellip "`gellip' `graph`k'' `xplot1'"
			}

			#delimit;
			graph twoway (scatteri `maxx' 0.5 (3) "{bf: `gtitle1'}", ms(i) mlabc(black))
				(scatter `obs1' `xvar', ms(i) ylabel(`maxx' "{bf:`gtitle1'}" -1 "`null1'" `"`value'"', 
				nolabel angle(360)) lpat(blank) blpattern(solid) blwidth(vthin) blcolor(black) `xlab2') 
				`spoint11' `spoint12' `predpoint1' `gellip', 
				ytitle("") xtitle("") fxsize(30) ylab(none) yscale(off) `ovline1' legend(off)
				plotregion(style(none)) graphregion(style(none)) nodraw name(`ellip1', replace);
			#delimit cr

			forv k = 1/`max' {
				local `specwgt'`k' = `wgtspe' in `k'
				local weight`k' = 0.1 * ``specwgt'`k''
				range st`k' 0 `=2*c(pi)' 1000
				local sa`k' = `spechi' - `spec' in `k'
				local sb`k' = `weight`k''
				local sxc`k' = `spec' in `k'
				local syc`k' = `k' in `k'
				gen sxt`k' = max(`sxc`k'' + `sa`k'' * cos(st`k'), 0)
				gen syt`k' = `syc`k'' + `sb`k'' * sin(t`k')
				qui replace syt`k' = syt`k'
				local swgt`k': di "``specwgt'`k''"
				local sgraph`k' `"(area syt`k' sxt`k', lwidth(none) fcolor(blue) fintensity(*`swgt`k''))"'
				local xplot2 `"(scatteri `k' `sxc`k'', msymbol(|) mcolor(black) msize(vlarge))"'
				local sgellip "`sgellip' `sgraph`k'' `xplot2'"
			}

			#delimit;
			graph twoway (scatteri `maxx' 0.5 (3) "{bf: `gtitle2'}", ms(i) mlabc(black))
				(scatter `obs1' `xvar', ms(i) ylabel(`maxx' "{bf:`gtitle2'}" -1 "`null1'" `"`value'"',
				nolabel angle(360)) lpat(blank) blpattern(solid) blwidth(vthin) blcolor(black) `xlab2')
				`spoint21' `spoint22' `predpoint2' `sgellip',
				ytitle("") xtitle("") fxsize(25) yscale(off) ylab(none) `ovline2' legend(off) 
				plotregion(style(none)) graphregion(style(none)) nodraw name(`ellip2', replace);
			#delimit cr

			#delimit;
			nois graph combine `forplot' `graphlist' `ellip1' `forplot3' `forplot1' `ellip2' `forplot4' `forplot2', ycommon rows(1) `i2note';
			#delimit cr
		}
		
		capture restore
	}
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

// Standardized weight extraction from e(studywgts)
capture program drop _midas_getwgts
program define _midas_getwgts
    version 16
    syntax, SENwgt(string) SPEwgt(string) BIVwgt(string)
    
    * Try to grab the weight matrix
    tempname wgtmat
    capture mat `wgtmat' = e(studywgts)
    local gotmat = (_rc == 0)
    
    if `gotmat' {
        local ncol = colsof(`wgtmat')
        local nrow = rowsof(`wgtmat')
    }
    else {
        local ncol = 0
        local nrow = 0
    }
    
    if `gotmat' == 0 | `ncol' < 3 | `nrow' == 0 {
        * Fallback: equal weights
        qui gen double `senwgt' = 100 / _N
        qui gen double `spewgt' = 100 / _N
        qui gen double `bivwgt' = 100 / _N
        exit
    }
    
    * Match rows to dataset: use matrix row names to align with study IDs
    * The dataset after xsvmat has StudyIds; the matrix has rownames.
    * Use positional assignment (row i of matrix -> row i of dataset).
    qui gen double `senwgt' = .
    qui gen double `spewgt' = .
    qui gen double `bivwgt' = .
    local maxrow = min(`nrow', _N)
    forvalues i = 1/`maxrow' {
        qui replace `senwgt' = `wgtmat'[`i', 1] in `i'
        qui replace `spewgt' = `wgtmat'[`i', 2] in `i'
        qui replace `bivwgt' = `wgtmat'[`i', 3] in `i'
    }
end

