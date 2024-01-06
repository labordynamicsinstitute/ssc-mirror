*! opplot version 1.17 - Biostat Global Consulting - 2023-12-22
*******************************************************************************
* Change log
* 				Updated
*				version
* Date 			number 	Name			What Changed
*-------------------------------------------------------------------------------
* 2015-12-21	1.01	MK Trimner		Added Starting comment and VCP globals
*
*										Put error to the vcqi_log as well as screen
*
* 2016-02-24	1.02	Dale Rhoda		Only set VCP and call vcqi_log_comment
*          								if VCQI is running; allows the possibility
*										to call the program from outside VCQI
* 										
* 2016-03-12	1.03	Dale Rhoda		Added option to save the plotting dataset
* 
* 2016-07-04	1.04	Dale Rhoda		I'm seeing ties in coverage across 
*										many strata (often at 100%) and so
* 										added a condition that sorts the plots
*										in descending order of coverage, with
*										ties broken by descending order of
*										weight, and ascending order of 
*										cluster ID (clustvar)
*
* 2016-09-10	1.05	Dale Rhoda		Improve option to save plotting dataset
*
* 2017-08-26	1.06	Mary Prier		Added version 14.1 line
* 
* 2017-12-11 	1.07	Dale Rhoda		Added passthru twoway option
*
* 2017-12-20	1.08	Dale Rhoda		Cleaned up how the pass_thru local works
*
* 2018-06-22	1.09	Dale Rhoda		Added the equalwidth option 
*                                       (which will over-ride the weightvar
*                                       option, if necessary, to yield bars
*                                       of equal width)
*
* 2018-08-14	1.10	Mary Prier		Added line of code that strips out
*                      					double quotes of savedata option, 
*										if user supplied filename in double quotes
*
* 2019-01-22	1.11	Dale Rhoda		Added options to add a line indicating
*      									the number of respondents per cluster.
*										(PLOTN NLINEColor NLINEWIdth NLINEPattern
*										 YTITLE2 and YROUND2)
*
* 2019-06-05	1.12	Dale Rhoda		When bars are tied on other quantities, 
*										sort in descending order of 
*										n_respondents
*
* 2019-12-12	1.13	Dale Rhoda		Cleaned up how the name() option is
*										processed
*
*										Allow the user to specify ytitle(none)
* 										to turn off the ytitle altogether
*										(which shifts the plot slightly 
*										 lefttward)
*
* 2020-06-01	1.14	Dale Rhoda		Implement `if' and `in'
*
* 2023-07-28	1.15	MK Trimner		Added globals with Output Strings for multi-lingual purposes
* 2023-11-03	1.16	MK Trimner		Updated barheight to be a double variable
*										Added options for bar colors for Opplots
*										Added notes with Covg, CI, DEFF, ICC, StratumID , Nam and CI type information to Opplot dataset
*										Added STRATUMNAME as an option for notes
*										Added HIGH value for the cutoff for the high end of the bars. This defaults to 100
* 2023-12-22	1.17	Dale Rhoda		Suppress horizontal line at y=lcthreshold
*******************************************************************************

program define opplot
	version 14.1
	
	syntax varlist(max=1) [if] [in], CLUSTVAR(varname fv) ///
	[STRATVAR(varname fv) STRATUM(string) WEIGHTvar(varname) ///
	 TITLE(string) SUBtitle(string) FOOTnote(string) NOTE(string) ///
	 BARCOLOR1(string) LINECOLOR1(string) ///
	 BARCOLOR2(string) LINECOLOR2(string) EQUALWIDTH ///
	 XTITLE(string) YTITLE(string) XLABEL(string) YLABEL(string) ///
	 EXPORTSTRAtumname EXPORT(string) EXPORTWidth(integer 2000) ///
	 SAVING(string asis) NAME(string) SAVEDATA(string asis) ///
	 XSIZE(real -9) YSIZE(real -9) TWOWAY(string asis) PLOTN ///
	 NLINEColor(string asis) NLINEWidth(string) NLINEPattern(string) ///
	 YTITLE2(string asis) YROUND2(integer 5) ///
	 LCTHRESHold(integer 999) ///
	 BARCOLORHIGH1(string) BARCOLORMID1(string) BARCOLORLOW1(string) ///
	 BARCOLORHIGH2(string) BARCOLORMID2(string) BARCOLORLOW2(string) ///
	 LINECOLORHIGH1(string) LINECOLORMID1(string) LINECOLORLOW1(string) ///
	 LINECOLORHIGH2(string) LINECOLORMID2(string) LINECOLORLOW2(string)  ///
	 FOOTNOTECOVG FOOTNOTEDEFF FOOTNOTEICC STRATUMNAME(string) HIGH(integer 100)]
	 
	* Note: opplot.ado is distributed as part of the World Health Organization's
	* Vaccination Coverage Quality Indicators (VCQI) suite of Stata programs.
	* When opplot is called from within VCQI, it interacts with a VCQI log.
	* When opplot is not called from VCQI, it ignores the few lines of
	* VCQI-related code.  The program knows if it is begin called from VCQI
	* because of the value of the global macro: VCQI_LOGOPEN.
	
	if "$VCQI_LOGOPEN" == "1" {		
		local oldvcp $VCP
		global VCP opplot
		vcqi_log_comment $VCP 5 Flow "Starting"
	}
	
	tokenize "`varlist'"
	local yvar `1'
	
	quietly {
	
		preserve
		
		if "`if'" != "" keep `if'
		if "`in'" != "" keep `in'
		
		tempvar wclust wstrat bartop barwidth yweight wsum1 barheight cumulative_barwidth clustvar_copy n_respondents wtvar2 wtsum
		
		* Make a copy of clustvar to save at the end of the program
		clonevar `clustvar_copy' = `clustvar'
		
		* if the user doesn't specify a stratum, generate one for the program to use
		if "`stratvar'" == "" {
			tempvar stratumvariable 
			gen `stratumvariable' = 1
			local stratvar `stratumvariable'
			local stratum 1
		}
		
		* if the user doesn't specify a weight variable, generate one
		if "`weightvar'" == "" {
			tempvar weightvariable
			gen `weightvariable' = 1
			local weightvar `weightvariable'
		}
					
		* if the user requests bars of equal width then
		* set up a new temporary weight variable (`wtvar2') and
		* scale it so that the sum of weights is equal in every cluster
		if "`equalwidth'" == "equalwidth" {
			clonevar `wtvar2' = `weightvar'
			local weightvar `wtvar2'
			tab `clustvar' if !missing(`yvar') // how many bars in the plot
			local wt_per_cluster = `=_N'/r(r)  // total weight per bar
			bysort `clustvar': egen `wtsum' = total(`weightvar')     if !missing(`yvar') // current sum of weights in each bar
			replace `wtvar2' = `wtvar2' * `wt_per_cluster' / `wtsum' if !missing(`yvar') // rescale sum of weights in each bar
		}
			
		* if y contains anything but 0 or 1 or . then fail
		capture tostring `stratvar', replace force
		capture assert inlist(`yvar',0,1,.) if `stratvar' == "`stratum'"
		if _rc == 9 {
			display as error "opplot Error: `yvar' should only have values of 0 or 1 or . when `stratvar' == `stratum'."

			if "$VCQI_LOGOPEN" == "1" {
				vcqi_log_comment $VCP 1 Error "opplot Error: `yvar' should only have values of 0 or 1 or . when `stratvar' == `stratum'."
				vcqi_halt_immediately
			}
		}
		
		
		* If the lcthreshold was not provided, wipe out the default value 
		 if "`lcthreshold'" == "999" local lcthreshold 
		 
		 * check to make sure the colors are valid
		 * If the color is not valid, wipe out and the default value will be applied
		 if "`lcthreshold'" != "" {
			 forvalues n = 1/2 {
				 foreach v in bacrcolor`n' linecolor`n' barcolorhigh`n' barcolormid`n' barcolorlow`n' linecolorhigh`n' linecolormid`n' linecolorlow`n'  {
				 * Check for valid colors
				 local valid 0
					if "``v''" != "" {
						local first = substr("``v''",1,1)
						if !inlist("`first'","1","2","3","4","5","6","7","8","9") {
							capture findfile color-``v''.style
							local valid _rc 
						}
						else {
							foreach col in ``v'' {
								capture assert `col' >=0 & `col' <= 255
								if _rc != 0 local valid 999
							}
						}
						
						 if `valid' != 0 {
							di as error "Option `v' currently takes value ``v''; it should be a valid color option"
							di as text "`msg'"
							capture vcqi_log_comment $VCP 1 Error "Option `v' currently takes value ``v''; it should be a valid color option"
							local `v'
						}
					}
				}
			}		 
		 }
		 
		 * If the VCQI_CI_METHOD is not set, set to WILSON
		 if "$VCQI_CI_METHOD" == "" global VCQI_CI_METHOD WILSON
		 		 
		 * Lets build the syvset command based on variables provided in opplot command
		 local svy `clustvar', singleunit(scaled)
		 if "`stratvar'" != "" local svy `svy' strata(`stratvar')
		 if "`weightvar'" != "" local svy `svy' weight(`weightvar')
		 
		 * Now set the svyset command so we can calculate the coverage below
		 svyset `svy'

		* establish default values if the user doesn't specify them
		if "`ylabel'" == "" local ylabel 0(50)100, angle(h) nogrid
		if "`ytitle'" == "" local ytitle ${OS_316} //Percent of Cluster
		if "`=lower(trim("`ytitle'"))'" == "none" local ytitle
		if "`barcolor1'"  == "" local barcolor1 pink
		if "`linecolor1'" == "" local linecolor1 `barcolor'*1.5
		if "`barcolor2'"  == "" local barcolor2 white
		if "`linecolor2'" == "" local linecolor2 black*0.5
		
		if "`barcolorhigh1'" == "" local barcolorhigh1 "103 169 207"  //"103 169 207" // dark blue
		if "`linecolorhigh1'" == "" local linecolorhigh1 gs15
		if "`barcolorhigh2'" == "" local barcolorhigh2 gs15 //white
		if "`linecolorhigh2'" == "" local linecolorhigh2 black*0.5
		
		if "`barcolormid1'" == "" local barcolormid1 "0 0 128" // light blue
		if "`linecolormid1'" == "" local linecolormid1 gs15
		if "`barcolormid2'" == "" local barcolormid2 gs15 //white
		if "`linecolormid2'" == "" local linecolormid2 black*0.5

		if "`barcolorlow1'" == "" local barcolorlow1 "255 91 0" // orange
		if "`linecolorlow1'" == "" local linecolorlow1 gs15
		if "`barcolorlow2'" == "" local barcolorlow2 gs15 //white
		if "`linecolorlow2'" == "" local linecolorlow2 black*0.5
		

		if "`exportstratumname'" != "" {
			local export `stratum'.png
		}
		if `"`name'"' != "" {
			local stripname `name'
			local stripname = subinstr("`stripname'", ", replace", "", .)
			local stripname = subinstr("`stripname'", ",replace" , "", .)
			local stripname = substr("`stripname'",1,min(32,length("`stripname'")))
			local namestring name(`stripname' , replace)
		}	
		if `"`saving'"' != "" local savingstring saving(`saving')
		if `xsize'  != -9 local xsizestring xsize(`xsize')
		if `ysize'  != -9 local ysizestring ysize(`ysize')

		* keep track of the number of respondents per cluster
		bysort `stratvar' `clustvar': gen `n_respondents' = _N

		* calculate sum of survey weights in each cluster and stratum
		bysort `stratvar' `clustvar': egen `wclust' = total(`weightvar')
		bysort `stratvar'           : egen `wstrat' = total(`weightvar')
		
		* calculate the proportion of the stratum weight in each cluster
		* (this corresponds to the bar width)
		gen `barwidth' = 100 * `wclust' / `wstrat'

		* calculate sum of survey weights for respondents with outcome = 1
		gen `yweight' = `yvar' * `weightvar'
		bysort `stratvar' `clustvar': egen `wsum1' = total(`yweight')

		* the height of each bar is the weighted proportion of respondents
		* with outcome = 1
		gen double `barheight' = (100*`wsum1'/`wclust')
		format %3.1f `barheight'
		
		* keep only observations in the stratum of interest
		keep if `stratvar' == "`stratum'"
		
		* Lets add some notes with the coverage information
		* We will first need to run the svypd command to get the values
		svypd `yvar', adjust method($VCQI_CI_METHOD)

		global covg : di %-3.1f 100*`r(svyp)'
		global lb : di %-2.1f 100*`r(lb_alpha)'
		global ub : di %-3.1f 100*`r(ub_alpha)'
		global deff : di %-5.1f `r(deff)' 
		global covg_info ${covg}% (${lb}-${ub}%)
		
		quietly calcicc `yvar' `clustvar'
		global icc : di %-7.4f `r(anova_icc)' 
		
		note: Estimated Coverage = ${covg_info} // do not inlcude CI in PLOT notes
		
		* Since we will use the estimated coverage later we will also store this in a char
		*char _dta[coverage_info] "${covg_info}"
		
		note: DEFF = $deff
		note: ICC = $icc
		note: StratumID = `stratum'
		if "`stratumname'" == "" {
			capture confirm var level3name 
			if _rc  == 0 local stratumname =level3name[1]
		}
		if "`stratumname'" != "" note: StratumName = `stratumname' 

		note: CI Method = $VCQI_CI_METHOD
		
		* keep only one observation per cluster
		bysort `stratvar' `clustvar': keep if _n == 1
		
		* sort the bars, left-to-right, in descending order of height and width
		* (and if there are ties...then sort the ties by descending n_respondents
		*  and ascending clusterID)
		gsort -`barheight' -`barwidth' -`n_respondents' `clustvar'
		*clonevar barheight = `barheight' 

		* the background bars always have a height of 100%
		gen `bartop' = 100	
		
		* Stata's facility for barcharts with varying widths requires a 
		* variable that codes the cumulative barwidth
		gen `cumulative_barwidth' = sum(`barwidth')
			
		* add an extra row onto the dataset to make the x values work out correctly
		set obs `=_N+1'
		* shift the width up by one observation to make the x values 
		* work out correctly
		forvalues i = `=_N'(-1)2 {
			replace `cumulative_barwidth' = `=`cumulative_barwidth'[`=`i'-1']' in `i'
		}
		replace `cumulative_barwidth' = 0 in 1
		
		* The option footnote is a synonym for note; if both are provided
		* ignore footnote
		if "`note'" == "" & "`footnote'" != "" local note `footnote'
		
		 // BUILD THE FOOTNOTES based on user specified input 
		 // Estimated Covg = XXX.X%
		 // Design Effect = XX.X;
		 //        Intercluster Correlation Coefficient = X.XXXX
		* Create footnotes for opplot		
		if "`footnotecovg'" != "" local opplot_footnote1 Estimated Coverage = $covg%
		if "`footnotedeff'" != "" local opplot_footnote2 Design Effect = $deff
		if "`footnoteicc'" != "" local opplot_footnote3 Intercluster Correlation Coefficient = $icc
		
		if "`opplot_footnote1'" != "" & "`opplot_footnote2'" != "" & "`opplot_footnote3'" != "" local opplot_footnote "`opplot_footnote1'; `opplot_footnote2';" "`opplot_footnote3'"
		if "`opplot_footnote1'" != "" & "`opplot_footnote2'" != "" & "`opplot_footnote3'" == "" local opplot_footnote "`opplot_footnote1'; `opplot_footnote2'" 
		if "`opplot_footnote1'" != "" & "`opplot_footnote2'" == "" & "`opplot_footnote3'" != "" local opplot_footnote "`opplot_footnote1'; `opplot_footnote3'" 
		if "`opplot_footnote1'" != "" & "`opplot_footnote2'" == "" & "`opplot_footnote3'" == "" local opplot_footnote "`opplot_footnote1'"
		
		if "`opplot_footnote1'" == "" & "`opplot_footnote2'" != "" & "`opplot_footnote3'" != "" local opplot_footnote "`opplot_footnote2'; `opplot_footnote3'"
		if "`opplot_footnote1'" == "" & "`opplot_footnote2'" != "" & "`opplot_footnote3'" == "" local opplot_footnote "`opplot_footnote2'"

		if "`opplot_footnote1'" == "" & "`opplot_footnote2'" == "" & "`opplot_footnote3'" != "" local opplot_footnote "`opplot_footnote3'"
		
		if `"`opplot_footnote'"' != "" local note "`opplot_footnote'" "`note'" 
		di `"note"'
		
		foreach o in ylabel title subtitle { // moved note out to be able to include double quotes
			if "``o''" != "" local pass_thru `pass_thru' `o'(``o'')
		}
		
		if `"`note'"' != "" local pass_thru `pass_thru' note("`note'")
		if "`ytitle'" != "" local pass_thru `pass_thru' ytitle("`ytitle'")
		
		* If the user asks to plot the number of respondents (N) then
		* set up the twoway line and twoway scatteri syntax to do it.
		if "`plotn'" != "" {
			if "`nlinecolor'"   == "" local nlinecolor gs10
			if "`nlinewidth'"   == "" local nlinewidth *.5
			if "`nlinepattern'" == "" local nlinepattern dash
			if "`ytitle2'"      == "" local ytitle2 ${OS_317} //Number of Respondents
			sum `n_respondents'
			local y2max = `yround2' * ceil(`=r(max)+1'/`yround2')
			local plotnsyntax (line `n_respondents' `cumulative_barwidth', connect(stairstep) lc(`nlinecolor') lw(`nlinewidth') lp(`nlinepattern') yaxis(2)) ///
			                  (scatteri `=`n_respondents'[`=_N-1']' `=`cumulative_barwidth'[`=_N-1']' `=`n_respondents'[`=_N-1']' `=`cumulative_barwidth'[`=_N']' , ///
							   ms(i) connect(direct) lc(`nlinecolor') lw(`nlinewidth') lp(`nlinepattern') yaxis(2))
			local yaxis2title ytitle("`ytitle2'", axis(2))
			local yaxis2label ylabel(0(`yround2')`y2max', axis(2) angle(0))
		}
		
		
		if "`lcthreshold'" == "" { 
			graph twoway ///
			(bar `bartop' `cumulative_barwidth', bartype(spanning) fcolor(`barcolor2') ///
				lpattern(solid) lcolor(`linecolor2') lwidth(*.1) ) ///
			(bar `barheight' `cumulative_barwidth', bartype(spanning) fcolor(`barcolor1') ///
				lpattern(solid) lcolor(`linecolor1') lwidth(*.1) ) ///
				`plotnsyntax' ,  ///
			graphregion(fcolor(white)) xtitle("`xtitle'") `pass_thru' `twoway' ///
			legend(off)  `namestring' `savingstring' `xsizestring' `ysizestring' ///
			xlabel(none) `yaxis2label' `yaxis2title' `threshold' 
		}
		if "`lcthreshold'" != "" {
			
			* We will make several bar graphs with the different colors for each threshold 
			* and add a yline at the threshold value
						
			local plotit 	(bar `bartop' `cumulative_barwidth' , bartype(spanning) fcolor(`"`barcolorhigh2'"') ///
				lpattern(solid) lcolor(`"`linecolorhigh2'"') lwidth(*.1) ) ///
			(bar `barheight' `cumulative_barwidth', bartype(spanning) fcolor(`"`barcolorhigh1'"') ///
				lpattern(solid) lcolor(`"`linecolorhigh1'"') lwidth(*.1) ) ///
			///	 // Create bars for mid section
			(bar `bartop' `cumulative_barwidth' if `barheight' < `high' | (_n == _N & `barheight'[_n-1] < `high'), bartype(spanning) fcolor(`"`barcolormid2'"') ///
				lpattern(solid) lcolor(`"`linecolormid2'"') lwidth(*.1) ) ///
			(bar `barheight' `cumulative_barwidth' if  `barheight'  < `high' | (_n == _N & `barheight'[_n-1] < `high'), bartype(spanning) fcolor(`"`barcolormid1'"') ///
				lpattern(solid) lcolor(`"`linecolormid1'"') lwidth(*.1) ) ///
			/// // Create bars for below the threshold
			(bar `bartop' `cumulative_barwidth' if `barheight' <= `lcthreshold' | (_n == _N & `barheight'[_n-1] <=`lcthreshold') , bartype(spanning) fcolor(`"`barcolorlow2'"') ///
				lpattern(solid) lcolor(`"`linecolorlow2'"') lwidth(*.1) ) ///
			(bar `barheight' `cumulative_barwidth' if `barheight'  <= `lcthreshold' | (_n == _N & `barheight'[_n-1] <=`lcthreshold'), bartype(spanning) fcolor(`"`barcolorlow1'"') ///
				lpattern(solid) lcolor(`"`linecolorlow1'"') lwidth(*.1) ) 
			
			graph twoway `plotit' `plotnsyntax' ///  (scatteri `lcthreshold' 0 `lcthreshold' 100, lc(gs8) lp(dash) connect(direct) ms(i))  // Removed the dashed line for now because the user doesn't have any control over it
			,  ///	
			graphregion(fcolor(white)) xtitle("`xtitle'") `pass_thru' `twoway' ///
			legend(off)  `namestring' `savingstring' `xsizestring' `ysizestring' ///
			xlabel(none) `yaxis2label' `yaxis2title' `threshold'  
			
		}
		
		if "`export'" != "" {
			graph export "`export'", width(`exportwidth') replace
		}
		
		* If the user has asked for underlying data to be saved, then
		* trim down to a small dataset that summarizes what is shown in 
		* the bars; this is to help users identify the clusterid of a
		* particular bar in the figure; the order in which clusterids
		* appear in the saved dataset is the same order they appear in 
		* the plot
		
		* Strip off double quotes if user supplied filename in double quotes
		local savedata = subinstr(`"`savedata'"', `"""',  "", .)
		
		* Strip off , replace if user supplied it in the savedata option
		local savedata = subinstr(`"`savedata'"', ", replace",  "", .)
		local savedata = subinstr(`"`savedata'"', ",replace" ,  "", .)

		if "`savedata'" != "" {
			drop in `=_N'
			capture drop yvar
			gen yvar = "`yvar'"
			capture drop stratvar
			gen stratvar = "`stratvar'"
			capture drop stratum
			gen stratum = "`stratum'"
			capture drop cluster
			gen cluster = "`clustvar'"
			capture drop `clustvar'
			rename `clustvar_copy' `clustvar'
			capture drop n_respondents
			rename `n_respondents' n_respondents
			capture drop barorder
			gen barorder = _n
			capture drop barwidth
			rename `barwidth' barwidth
			* replace cumulative barwidth with values that start at the width of bar 1
			capture drop cumulative_barwidth
			gen cumulative_barwidth = sum(barwidth)	
			capture drop barheight
			rename `barheight' barheight
			keep  yvar stratvar stratum cluster `clustvar' n_respondents barorder barwidth cumulative_barwidth barheight		
			order yvar stratvar stratum cluster `clustvar' n_respondents barorder barwidth cumulative_barwidth barheight		
			capture save "`savedata'", replace
		}
	}
	
	if "$VCQI_LOGOPEN" == "1" {
		vcqi_log_comment $VCP 5 Flow "Exiting"
		global VCP `oldvcp'
	}
end
