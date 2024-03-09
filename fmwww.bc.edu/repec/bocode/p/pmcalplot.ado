
******************************************************************
*												 				 *
*  PROGRAM TO PRODUCE FLEXIBLE CALIBRATION PLOTS 				 *
*  24/05/17 									 				 *
*  Updated: 24/05/2017											 *
*  	- added cutpoints option					 				 *
*  Updated: 21/10/2018 											 *
*	- added survival model observed data		 				 *
*  Updated: 27/10/2018 											 *
*	- added linear model capabilities			 				 *
*  Updated: 2/4/2019 											 *
*	- removed width default in histograms for cont outcomes		 *
*  Updated: 23/12/2019											 *
*	- updated range() option to ensure plotting of smoother 	 *
*		& spike plot inside range only							 *
*	- updated range() option to ensure correct scaling of spike  *
*		plot at any range										 *
*	- updated graph axes defaults when using range()			 *
*	- added 'zoom' option, which automatically scales the plot 	 *
*		to fit all groupings & CI's (smoother & spikes plotted	 *
*		within this zoomed range only)							 *
*	- updated survival plot: displays groupings at 1 if all 	 *
*		patients had an event before the time point of interest  *
*	- updated survival plot to allow spike plot					 *
*	Updated: 17/12/2021											 *
*	- fixing bug in the spike plots								 *
*	Updated: 13/01/2022											 *
*	- CI for smoother for binary outcomes						 *
*   Updated: 04/05/2022											 *
*	- uses pmcstat to calc c-stat now for binary outcomes 		 *
*	 giving dramatic speed increase with large datasets 		 *
*  Updated: 12/06/2023											 *
*	ADDED:													  	 *
*	- fix to R2 calculation for cont. outcomes using corr 		 *
*	- switch smoother to running, allowing CIs (only bin.)		 *
*	- addplot option (only added to cont. for now)				 *
*	- nosmootherci option (to turn off the CI for the smoother)	 *
*	- smootherciopts option 									 *
*   Updated: 14/06/2023											 *
*	- added smoother & CI for survival outcomes 				 *
*	- added option to alter rendition of survival smoother 		 *
*	- added ttesmoothergroups() to define bins for smoother      *
*	- updated "lowess" language to "smoother" in general		 *	
*	Updated: 06/03/2024											 *
*	- bug fix for smoother package dependency					 *
*																 *
*  2.2.2 J. Ensor								 				 *
******************************************************************

*! 2.2.2 J.Ensor 06Mar2024

program define pmcalplot, rclass

version 12.1						

/* Syntax
	VARLIST = A list of two variables, the predicted probabilities from the model,
				and the event indicator (observed outcome) for binary 
				[not input for survival outcomes]
	Bin = Number of bins used to group patients average observed
					& expected probabilities
	CUTpoints = A numeric list of cutpoints based on risk to be used instead
		of equally sized bins. Real numbers in the interval [0,1].
	NOSMoother = Remove smoother line
	NOSPike = Remove spike plot
	CI = add 95% CI's for the groups (CI's for proportions)
	SCatteropts = twoway options to affect rendition of the groups
	Range = a range for the plot describing the square size of the plot
	SMootheropts = twoway options to affect rendition of the smoother line
	SPikeopts = twoway options to affect rendition of the spikes
	CIopts = twoway options to affect rendition of the confidence intervals
	* = all other twoway options e.g. titles, legends (defaults apply otherwise)
	SURVival = calibration plot for survival models (uses KM estimates 
					for observed data)
	Timepoint = must be provided if survival option is on. A single time point 
					at which calibration is plotted. Units of time are defined by 
					the stset command prior to using pmcalplot. 
					Default = 1 unit of time.
	NOHist = Remove histograms from axes for continuous outcome models
	HIstopts = twoway options to affect rendition of the histograms
	KEEP = return variables for the expected, observed, & risk groups
	ZOOM = produces a plot displaying all data but in a narrower range than [0 1]

*/
	syntax varlist(min=1 max=2 numeric) [if] [in], [Bin(int 10) ///
						CUTpoints(numlist >=0 <=1 sort) noSMoother noSPike ///
						CI noSMOOTHERCI SCatteropts(string asis) ///
						Range(numlist min=2 max=2 sort) ///
						SMootheropts(string asis) SMOOTHERCIopts(string asis) ///
						SPikeopts(string asis) CIopts(string asis) noStatistics SURVival ///
						Timepoint(int 1) KEEP CONTinuous noHist ADDPLOT(string asis) ///
						OBSHIstopts(string asis) EXPHIstopts(string asis) ///
						P(int 0) LP(varname numeric) TTEsmoothergroups(int 5) ZOOM *] 

//SET UP TEMPVARS
tempvar binvar obs obsn exp binvar2 exp2 events nonevents outcomp ///
			lci uci obsse lowvar spikejitter binary_lp thresh lowvar_se ///
			lowvar_lci lowvar_uci histbinvar histeventn histnoneventn histexp ///
			droplinebase pseudo groups

			
// check for packages 
	local package running
	foreach pack of local package {
		capture which `pack'
		if _rc==111 {	
			di as txt "Package 'running' is required for this version on pmcalplot" _n "Installation will begin now ..."
			ssc install `pack', replace
			}
		}
		
// check on the if/in statement
marksample touse
qui count if `touse'
local n = `r(N)'
if `r(N)'==0 { 
	di as err "if statement identifies subgroup with no data?"
	error 2000
	}
	
// check only one of the surv or cont options is specified
if "`continuous'"=="continuous" & "`survival'"=="survival" {
	di as err "Only one outcome type can be selected (default=binary, surv=survival, cont=continuous)."
	error 198
	}
	else if "`survival'"=="survival" {
		di as inp "Survival option selected: Calibration plot for survival prediction model displaying..."
		}
		else if "`continuous'"=="continuous" {
			di as inp "Continuous option selected: Calibration plot for linear prediction model displaying..."
			}
			else {
				di as inp "Binary option selected: Calibration plot for logistic prediction model displaying..."
				}
			
// parse varlist
tokenize `varlist' , parse(" ", ",")

// run checks on user input variables in varlist
// check if user has input both exp and obs (for binary/survival outcomes)
local varcountcheck: word count `varlist'
if "`survival'"=="survival" {
	if `varcountcheck'!=1 {
		di as err "Varlist contains too many variables. For survival outcomes only predicted probabilities (expected values) are required"
		error 103
		}
	}
	else if "`continuous'"=="continuous" {
			if `varcountcheck'!=2 {
					di as err "Varlist must contain two variables. Predicted values (expected values), followed by observed values are required"
					error 102
					}
			}
			else {
				if `varcountcheck'!=2 {
					di as err "Varlist must contain two variables. Predicted probabilities (expected values), followed by observed outcomes (binary variable) are required"
					error 102
					}
					
				// check first var in varlist is a binary outcome (0 1) var
				qui levelsof `2', l(distinct)
				local sum = 0
				local prod = 1
				foreach i in `distinct' {
					local count = `count'+1
					local sum = `sum'+`i'
					local prod = `prod'*`i'
					}
					
				if `count'!=2 {	
						di as err "Event indicator not binary? Check which type of outcome you're using."
						error 450 
						}
						else if (`sum'!=1 & `prod'!=0) {
							di as err "Event indicator must be coded 0 or 1"
							error 450 
							}			
				}
			
// check the first var in varlist is probabilities lying btwn 0-1 (binary/survival)
if "`continuous'"!="continuous" {
	qui su `1'
	if `r(min)'>=0 & `r(max)'<=1 { 
		}
		else {
			di as err "1st element of varlist must be probabilities in the interval [0,1]"
			error 459
			}
		}
		
******************** BINARY OUTCOMES
if "`survival'"!="survival" & "`continuous'"!="continuous" {
	// check if user specified cutpoints
	if "`cutpoints'"!="" {
		qui gen `thresh' = .
		local q = 1
		foreach i in `cutpoints' {
			qui replace `thresh' = `i' in `q'
			local ++q
			}	
		
		* warning message for transparent reporting 
		di as err _n "WARNING: Do not use the cut-point option unless the model has prespecified clinically relevant cut-points."
		
		* create risk groups based on cutpoints
		xtile `binvar' = `1' if `touse', cutpoints(`thresh')
		}
		else {
			// create equally sized risk groups by number of bins
			xtile `binvar' = `1' if `touse', n(`bin')
			}
			
	// average the observed & expected over the bins 
	qui egen `obs' = mean(`2') if `touse', by(`binvar')
	qui egen `obsn' = count(`2') if `touse', by(`binvar')
	qui egen `exp' = mean(`1') if `touse', by(`binvar')

	// CIs for scatter points
	if "`ci'"=="ci" {
		qui gen `obsse' = ((`obs'*(1-`obs'))/`obsn')^.5
		qui gen `lci' = max(0,(`obs' - (1.96*`obsse')))
		qui gen `uci' = min(1,(`obs' + (1.96*`obsse')))
		}
		
	// create spike plot
	qui gen byte `events' = 0
	qui replace `events' = 1 if `2'==1 
	qui replace `events'=. if `1'==.
	qui gen `outcomp'= 1-`2'
	qui gen byte `nonevents' = 0
	qui replace `nonevents' = -1 if `outcomp'==1 
	qui replace `nonevents'=. if `1'==.
	}

******************** SURVIVAL OUTCOMES
if "`survival'"=="survival" & "`continuous'"!="continuous" {
	
	********************
	// check if user specified cutpoints
	if "`cutpoints'"!="" {
		qui gen `thresh' = .
		local q = 1
		foreach i in `cutpoints' {
			qui replace `thresh' = `i' in `q'
			local ++q
			}	
	
		* warning message for transparent reporting 
		di as err _n "WARNING: Do not use the cut-point option unless the model has prespecified clinically relevant cut-points."
		
		* create risk groups based on cutpoints
		xtile `binvar' = `1' if `touse', cutpoints(`thresh')
		}
		else {
			// create equally sized risk groups by number of bins
			xtile `binvar' = `1' if `touse', n(`bin')
			}
			
	// identify the bin numbers in binvar (particularly when using cutpoints)
	qui levelsof `binvar', l(newbins)
		
	// average the observed over the bins - survival outcomes
	*Slightly more complicated for observed
	qui gen `obs'=.
	qui gen `lci'=.
	qui gen `uci'=.
	tempfile temp
		foreach i in `newbins' {
			qui sts list if `binvar'==`i' , at(0 `timepoint') saving(`temp', replace)
			preserve
				qui use `temp', clear
				qui drop if time==0
				local cal_obs=1-survivor
				local cal_obs_lb=1-lb
				local cal_obs_ub=1-ub

			restore
			if `cal_obs'==. {
				qui replace `obs'=1 if `binvar'==`i'
				qui replace `lci'=. if `binvar'==`i'
				qui replace `uci'=. if `binvar'==`i'
				}
				else {
					qui replace `obs'=`cal_obs' if `binvar'==`i'
					qui replace `lci'=`cal_obs_lb' if `binvar'==`i'
					qui replace `uci'=`cal_obs_ub' if `binvar'==`i'
					}
		}

	// average the expected over the bins - survival outcomes
	qui egen `exp' = mean(`1') if `touse', by(`binvar')
		
	
	// create spike plot
	qui gen byte `events' = 0
	qui replace `events' = 1 if _d==1 & _t<=`timepoint'
	qui replace `events'=. if `1'==. 
	//qui gen `outcomp'= 1-_d
	qui gen byte `nonevents' = 0
	qui replace `nonevents' = -1 if `events'!=1 
	qui replace `nonevents'=. if `1'==. 
	}

******************** CONTINUOUS OUTCOMES
if "`survival'"!="survival" & "`continuous'"=="continuous" {
	// average the observed & expected over the bins 
	qui gen `obs' = `2' if `touse'
	qui gen `exp' = `1' if `touse'
	
	// turn spike plot off as continuous outcomes uses histograms
	local spike = "nospike"
	
	// turn off ci for continuous outcomes
	local ci = ""
	}

********************
************************************
// calculate range locals from user input (or default 0 1)
if "`range'"!="" {
		gettoken first second : range
		local minr = `first'
		local maxr = `second'
		di as err _n "WARNING: Plot range has been manually restricted. Be aware that information may lie outside of this range." _n "Groupings & CI's will not be displayed if they lie outside of the specified range" _n "Further, smoother values outside of the specified range will not be plotted"
		
		local range_diff = abs(`maxr'-`minr')
		local adj = `minr' -(.05*`range_diff')
		local adjdown = `minr' -(.04*`range_diff')
		local adjup = `minr' -(.06*`range_diff')
		
		// scale the spike plot to fit along the bottom of the cal plot
		if "`continuous'"!="continuous" {
			qui replace `events' = (`events'/30)*(`range_diff') + `adj'
			qui replace `nonevents' = (`nonevents'/30)*(`range_diff') + `adj' 
			qui gen `spikejitter' = `1'+(runiform()*0.00001)
			}
		
		local sp1 = cond("`spike'"=="nospike","",`"|| rspike `events' `nonevents' `spikejitter' if (`spikejitter'<`maxr') & (`spikejitter'>`minr') & (`touse'), yline(`adj') text(`adjdown' `maxr' "1", place(n)) text(`adjup' `maxr' "0", place(s)) lw(thin) lcol(maroon) `spikeopts'"')
		local ci1 = cond("`ci'"=="ci","|| rspike `uci' `lci' `exp' if (`exp'<=`maxr') & (`exp'>=`minr') & (`uci'<=`maxr') & (`uci'>=`minr') & (`lci'<=`maxr') & (`lci'>=`minr'), lcol(forest_green) `ciopts'","")
		}
		else if "`range'"=="" & "`continuous'"=="continuous" {
			qui su `2'
			
			local minr = r(min)
			local maxr = r(max)
			}
			else if "`zoom'"=="zoom" {
				if "`survival'"=="survival" {
					qui su `uci'
					local ci_minr = r(min)
					qui su `lci'
					local ci_maxr = r(max) 
					qui su `obs'
					local obs_minr = r(min)
					local obs_maxr = r(max)
					qui su `exp'
					local exp_minr = r(min)
					local exp_maxr = r(max)
					local minr = min(`exp_minr', `obs_minr', `ci_minr')
					local maxr = max(`exp_maxr', `obs_maxr', `ci_maxr')
					}
					else {
						qui su `uci'
						local ci_maxr = r(max)
						qui su `lci'
						local ci_minr = r(min)
						qui su `obs'
						local obs_minr = r(min)
						local obs_maxr = r(max)
						qui su `exp'
						local exp_minr = r(min)
						local exp_maxr = r(max)
						local minr = min(`exp_minr', `obs_minr', `ci_minr')
						local maxr = max(`exp_maxr', `obs_maxr', `ci_maxr')
						}
				
				local ci1 = cond("`ci'"=="ci","|| rspike `uci' `lci' `exp' if (`exp'<=`maxr') & (`exp'>=`minr'), lcol(forest_green) `ciopts'","") 
				di as err _n "WARNING: Plot range has been manually restricted. Be aware that information may lie outside of this range." _n "Smoother & Spike plot values may lie outside of the plot range when using zoom option"
		
				local range_diff = abs(`maxr'-`minr')
				local adj = `minr' -(.05*`range_diff')
				local adjdown = `minr' -(.04*`range_diff')
				local adjup = `minr' -(.06*`range_diff')
				
				// scale the spike plot to fit along the bottom of the cal plot
				if "`continuous'"!="continuous" {
					qui replace `events' = (`events'/30)*(`range_diff') + `adj'
					qui replace `nonevents' = (`nonevents'/30)*(`range_diff') + `adj' 
					qui gen `spikejitter' = `1'+(runiform()*0.00001)
					}
		
				local sp1 = cond("`spike'"=="nospike","",`"|| rspike `events' `nonevents' `spikejitter' if (`spikejitter'<`maxr') & (`spikejitter'>`minr') & (`touse'), yline(`adj') text(`adjdown' `maxr' "1", place(n)) text(`adjup' `maxr' "0", place(s)) lw(thin) lcol(maroon) `spikeopts'"')
				}
				else {
					local minr = 0
					local maxr = 1
					
					// scale the spike plot to fit along the bottom of the cal plot
					if "`continuous'"!="continuous" {
						qui replace `events' = (`events'/30)-.05
						qui replace `nonevents' = (`nonevents'/30)-.05 
						qui gen `spikejitter' = `1'+(runiform()*0.00001)
						}
					
					local sp1 = cond("`spike'"=="nospike","",`"|| rspike `events' `nonevents' `spikejitter' if (`spikejitter'<`maxr') & (`spikejitter'>`minr') & (`touse'), yline(-.05) text(-.04 `maxr' "1", place(n)) text(-.06 `maxr' "0", place(s)) lw(thin) lcol(maroon) `spikeopts'"')
					local ci1 = cond("`ci'"=="ci","|| rspike `uci' `lci' `exp' if (`exp'<=`maxr') & (`exp'>=`minr') & (`uci'<=`maxr') & (`uci'>=`minr') & (`lci'<=`maxr') & (`lci'>=`minr'), lcol(forest_green) `ciopts'","")
					}

					
// derive and save smoother variable
if "`smoother'"!="nosmoother" {
	if "`survival'"!="survival" & "`continuous'"!="continuous" {
		qui running `2' `1' if `touse', span(1) ci generate(`lowvar') gense(`lowvar_se') replace nog
		qui gen `lowvar_lci' = `lowvar' - (1.96*`lowvar_se')
		qui replace `lowvar_lci'=0 if `lowvar_lci'<0
		qui gen `lowvar_uci' = `lowvar' + (1.96*`lowvar_se')
		qui replace `lowvar_uci'=1 if `lowvar_uci'>1
	}
	if "`survival'"=="survival" {
		if "`lp'"!="" {
			qui egen `groups' = cut(`lp') if `touse', group(`ttesmoothergroups')
			qui replace `groups' = `groups' + 1
			
			forvalues i = 1/`ttesmoothergroups' {
				* generate pseudo values at t years
				tempvar pseudo`i'
				qui capture stpci if `groups' == `i', at(`timepoint') gen(`pseudo`i'') 
				if _rc {
					di as err "Sample size is too small to allow estimation of the smoother using `ttesmoothergroups' groups and may lead to inappropriate smoothers/CIs. Try reducing the number of groups using ttesmoothergroups()"
					}
			}

			* merge pseudo observations into a single variable
			qui gen `pseudo' = .
			forvalues i = 1/`ttesmoothergroups' {
				qui replace `pseudo' = `pseudo`i'' if `groups' == `i'
			}

			qui running `pseudo' `1' if `touse', span(1) ci generate(`lowvar') gense(`lowvar_se') replace nog
			qui gen `lowvar_lci' = `lowvar' - (1.96*`lowvar_se')
			qui replace `lowvar_lci'=0 if `lowvar_lci'<0
			qui gen `lowvar_uci' = `lowvar' + (1.96*`lowvar_se')
			qui replace `lowvar_uci'=1 if `lowvar_uci'>1
		}
		else {
			local smoother = "nosmoother"
			di as inp "NB: LP variable not provided therefore smoother cannot be calculated/displayed"
		}
	}

	if "`continuous'"=="continuous" {
		qui running `2' `1' if `touse', span(1) ci generate(`lowvar') gense(`lowvar_se') replace nog
		qui gen `lowvar_lci' = `lowvar' - (1.96*`lowvar_se')
		*qui replace `lowvar_lci'=0 if `lowvar_lci'<0
		qui gen `lowvar_uci' = `lowvar' + (1.96*`lowvar_se')
		*qui replace `lowvar_uci'=1 if `lowvar_uci'>1
	}
	
	}

// graph command locals (all combinations of hist/smoother or not)
if "`smootherci'"!="nosmootherci" {
local lo1 = cond("`smoother'"=="nosmoother","","|| line `lowvar' `1' if (`lowvar'<=`maxr') & (`lowvar'>=`minr') & (`1'<=`maxr') & (`1'>=`minr') & (`touse'), sort lcol(midblue) `smootheropts' || rarea `lowvar_uci' `lowvar_lci' `1' if `touse', sort fc(midblue%20) lc(midblue%20) `smootherciopts'")
}
else {
local lo1 = cond("`smoother'"=="nosmoother","","|| line `lowvar' `1' if (`lowvar'<=`maxr') & (`lowvar'>=`minr') & (`1'<=`maxr') & (`1'>=`minr') & (`touse'), sort lcol(midblue) `smootheropts'")
}

// create local to manage the legend ordering
if ("`smoother'"=="nosmoother") & ("`ci'"=="ci") {
	local leglaborder "1 2 3"
	local labs "lab(1 Reference) lab(2 Groups) lab(3 95% CIs) "
	}
	else if ("`smoother'"=="") & ("`ci'"=="") {
		local leglaborder "1 2 3"
		local labs "lab(1 Reference) lab(2 Groups) lab(3 Smoother)"
		}
		else if ("`smoother'"=="nosmoother") & ("`ci'"=="")  {
			local leglaborder "1 2"
			local labs "lab(1 Reference) lab(2 Groups)"
			}
			else {
				local leglaborder "1 2 3 4"
				local labs "lab(1 Reference) lab(2 Groups) lab(3 95% CIs) lab(4 Smoother)"
				} 

				 
// Calibration performance statistics
if "`statistics'"!="nostatistics"  {
	// stats for binary outcomes
	if "`survival'"!="survival" & "`continuous'"!="continuous" {
		* calculating linear predictor
		qui gen `binary_lp' = ln(`1'/(1-`1')) if `touse'

		* calculating c-slope
		qui logistic `2' `binary_lp' if `touse', coef 
		local cslope = _b[`binary_lp']
		local cslope : di %4.3f `cslope'
		return scalar cslope = `cslope'

		* calculating calibration-in-the-large (CITL)
		qui logistic `2' if `touse', offset(`binary_lp') coef
		local citl = _b[_cons]
		local citl : di %4.3f `citl'
		return scalar citl = `citl'

		* exp/obs ratio
		qui su `2' if `touse'
		local o = r(mean)
		qui su `1' if `touse'
		local e = r(mean)
		local oe = `o'/`e'
		local oe : di %4.3f `oe'
		return scalar oe_ratio = `oe'

		* c-index
		qui pmcstat `binary_lp' `2' if `touse'
		local cstat = r(cstat) 
		local cstat : di %4.3f `cstat'
		return scalar cstat = `cstat'
		
		local st1 = `" text(`maxr' `minr' "O:E = `oe'" "CITL = `citl'" "Slope = `cslope'" "AUC = `cstat'", size(small) place(se) just(left))"'
		}
		
		// stats for survival outcomes
	if "`survival'"=="survival" {
		* calculating linear predictor
		if "`lp'"!="" {
			* calculating c-slope
			qui stcox `lp' if `touse', nohr
			local cslope = _b[`lp']
			local cslope : di %4.3f `cslope'
			return scalar cslope = `cslope'
			
			* c-index
			qui estat concordance
			local cstat = r(C) 
			local cstat : di %4.3f `cstat'
			return scalar cstat = `cstat'
			
			
			local st1 = `" text(`maxr' `minr' "Slope = `cslope'" "C-statistic = `cstat'", size(small) place(se) just(left))"'
			}
		}
		
		// stats for continuous outcomes
	if "`continuous'"=="continuous" {
		* calculating c-slope
		qui reg `2' `1' if `touse' 
		local cslope = _b[`1']
		local cslope : di %4.3f `cslope'
		return scalar cslope = `cslope'
		
		* r-sq
		qui corr `2' `1' if `touse' 
		local r2 = r(rho)^2
		if `p'!=0 {
			* r-sq adjusted
			local r2a = (((`n'-1)*`r2')-`p')/(`n'-`p'-1)
			local r2a : di %4.3f `r2a'
			return scalar r2a = `r2a'
			}
			
		local r2 : di %4.3f `r2'
		return scalar r2 = `r2'
		
		
		* calculating calibration-in-the-large (CITL)
		qui constraint 1 `1'=1
		qui cnsreg `2' `1' if `touse', constraint(1)
		local citl = _b[_cons]
		local citl : di %4.3f `citl'
		return scalar citl = `citl'
		
		if `n'!=0 & `p'!=0 {
			local st1 = `" text(`maxr' `minr' "R-squared = `r2'" "Adj R-squared = `r2a'" "CITL = `citl'" "Slope = `cslope'", size(small) place(se) just(left))"'
			}
			else {
				local st1 = `" text(`maxr' `minr' "R-squared = `r2'" "CITL = `citl'" "Slope = `cslope'", size(small) place(se) just(left))"'
				}
		
		}
	}


// Graph command combining user selected features (binary & survival)
if "`continuous'"!="continuous" {
	graph twoway function y=x, range(`minr' `maxr') lp(-) || ///
		scatter `obs' `exp' if (`exp'<=`maxr') & (`exp'>=`minr') & (`obs'<=`maxr') & (`obs'>=`minr'), mcol(dkgreen) ///
		msym(Oh)  graphr(col(white)) ///
		xlab(#5, angle(h) format(%3.1f)) ylab(#5, angle(h) format(%3.1f)) ///
		ytitle("Observed") xtitle("Expected") aspect(1) ///
				legend(pos(3) order(`leglaborder') ///
						`labs' col(1) size(small)) ///
						`scatteropts' `options' `ci1' `lo1' `sp1' `st1' 
	}

******************* 	

// Graph commands for continuous outcomes
if "`continuous'"=="continuous" {
// if histogram is on then produce and combine graphs
	if "`hist'"!="nohist" {
		* set up tempmnames for graphs
		tempname obs_graph sc_graph exp_graph
		
		* graphs
		qui graph twoway function y=x, range(`minr' `maxr') lp(-) || ///
			scatter `obs' `exp' if (`1'<`maxr') & (`1'>`minr'), mcol(dkgreen) ///
			msym(Oh) graphr(col(white)) ///
			xlab(#5, angle(h)) ylab(#5, angle(h)) nodraw ///
			ytitle("") xtitle("") aspect(1)	legend(off) saving(`sc_graph', replace) ///
							`scatteropts' `options' `ci1' `st1' `addplot'  `lo1'
		
		qui twoway histogram `obs', graphr(col(white))  xlab(minmax, angle(v) ///
			format(%3.2f)) xsca(reverse) ylab(#5) ysca() ytitle("Observed") xtitle("") ///
			horiz fxsize(15) saving(`obs_graph', replace) col(maroon) nodraw `obshistopts'

		qui twoway histogram `exp', graphr(col(white))  ylab(minmax, angle(h) ///
			format(%3.2f)) xlab(#5) ytitle("") xtitle("Expected") ///
			fysize(15) saving(`exp_graph', replace) col(maroon) nodraw `exphistopts'

		* Combine the above plots in one plot. 
		graph combine `obs_graph'.gph `sc_graph'.gph `exp_graph'.gph, hole(3) imargin(1 0 1 0) ///
		graphregion(margin(l=1 r=3)) xsize(4) ysize(4) graphr(col(white)) `options' 
		}
		else {
			graph twoway function y=x, range(`minr' `maxr') lp(-) || ///
			scatter `obs' `exp' if (`1'<`maxr') & (`1'>`minr'), mcol(dkgreen) ///
			msym(Oh) graphr(col(white)) ///
			xlab(#5, angle(h)) ylab(#5, angle(h)) ///
			ytitle("Observed") xtitle("Expected") aspect(1) ///
					legend(pos(3) order(`leglaborder') ///
							`labs' col(1) size(small)) ///
							`scatteropts' `options' `ci1' `st1' `addplot' `lo1' 
			}
		}
		
****************************************************************************
/* give user the option to leave behind the cutpoints/bins variable
	so they can see if there were no patients in a specific risk group */
if "`keep'"=="keep" {
	capture confirm variable obs_pmcalplot
	if !_rc {
		di as err "Variable with name 'obs_pmcalplot' already exists, pmcalplot cannot generate required variables"
		}
		else {
			rename `obs' obs_pmcalplot
		    }
	
	capture confirm variable exp_pmcalplot
	if !_rc {
		di as err "Variable with name 'exp_pmcalplot' already exists, pmcalplot cannot generate required variables"
		}
		else {
			rename `exp' exp_pmcalplot
		    }
	
	if "`continuous'"!="continuous" {
	capture confirm variable groups_pmcalplot
		if !_rc {
			di as err "Variable with name 'groups_pmcalplot' already exists, pmcalplot cannot generate required variables"
			}
			else {
				rename `binvar' groups_pmcalplot
				}	
			}
	}

end 	

// END OF PROGRAM
*********************************************************************************


**************************************************
*												 *
*  PROGRAM TO CALCULATE C-STAT					 *
*  16/06/21 									 *
*  			 									 *
*												 *
*  1.0.0 J. Ensor								 *
**************************************************

*! 1.0.0 J.Ensor 16Jun2021

program define pmcstat, rclass

/* Syntax
	VARLIST = A list of two variables, the linear predictor for the model,
			and the event indicator (observed outcome)
	NOPRINT = suppress the onscreen output of performance stats
	MATRIX = specify the name of a matrix storing the performance stats 
*/

syntax varlist(min=1 max=2 numeric) [if] [in], [noPRINT  ///
				MATrix(name local) HANley FASTER]

*********************************************** SETUP/CHECKS
*SET UP TEMPs
tempvar p rank_disc rank2_disc diff_disc inv_outcome rank_cord rank2_cord diff_cord

// check on the if/in statement 
marksample touse
qui count if `touse'
local samp=r(N)
if `r(N)'==0 { 
	di as err "if statement identifies subgroup with no data?"
	error 2000
	}
	
// parse varlist
tokenize `varlist' , parse(" ", ",")
local lp = `"`1'"'
local outcome = `"`2'"'

// generate probabilities
qui gen `p' = exp(`lp')/(1+exp(`lp'))

// run checks on user input variables in varlist
// check if user has input both LP and obs (for binary outcome)
local varcountcheck: word count `varlist'

if `varcountcheck'!=2 {
	di as err "Varlist must contain two variables. Linear predictor values, followed by observed outcomes (binary variable) are required"
	error 102
	}

// check outcome is binary
cap assert `outcome'==0 | `outcome'==1 if `touse'
        if _rc~=0 {
                noi di as err "Event indicator `outcome' must be coded 0 or 1"
                error 450
        }

// preserve data & keep only the touse sample
preserve
keep if `touse'

*********************************************** C-STAT

if "`faster'"=="faster" {
	// check for packages 
	local packs gtools
	foreach pkg of local packs {
		capture which `pkg'
		if _rc==111 {	
			ssc install `pkg'
			}
		}
		
	// discordant pairs
	hashsort `p' `outcome' 		
	qui gen `rank_disc' = _n if `touse'

	hashsort `outcome' `p' `rank_disc'
	qui gen `rank2_disc' = _n if `touse'

	qui gen `diff_disc' = (`rank_disc' - `rank2_disc') if (`outcome'==0) & (`touse')

	// concordant pairs
	qui gen `inv_outcome' = (`outcome'==0)
	hashsort `p' `inv_outcome'
	qui gen `rank_cord' = _n if `touse'

	hashsort `inv_outcome' `p' `rank_cord'
	qui gen `rank2_cord' = _n if `touse'

	qui gen `diff_cord' = (`rank_cord' - `rank2_cord') if `inv_outcome'==0

	// total possible pairs
	qui gstats sum `outcome' if (`outcome'!=.) & (`touse'), meanonly
	local obs = r(N)
	local prev = r(mean)
	local events = r(sum)
	local nonevents = r(N) - r(sum)
	local pairs = `events'*`nonevents'  

	// compute c-stat (allowing for ties)
	qui gstats sum `diff_disc' if `touse'
	local disc = r(sum)
	qui gstats sum `diff_cord' if `touse'
	local cord = r(sum)

	local ties = `pairs'-`disc'-`cord'

	local cstat = (`cord'+(0.5*`ties'))/(`pairs')
	}
	else {
		// discordant pairs
		sort `p' `outcome' 		
		qui gen `rank_disc' = _n if `touse'

		sort `outcome' `p' `rank_disc' 
		qui gen `rank2_disc' = _n if `touse'

		qui gen `diff_disc' = (`rank_disc' - `rank2_disc') if (`outcome'==0) & (`touse')

		// concordant pairs
		qui gen `inv_outcome' = (`outcome'==0) if `touse'
		sort `p' `inv_outcome' 
		qui gen `rank_cord' = _n if `touse'

		sort `inv_outcome' `p' `rank_cord' 
		qui gen `rank2_cord' = _n if `touse'

		qui gen `diff_cord' = (`rank_cord' - `rank2_cord') if (`inv_outcome'==0) & (`touse')

		// total possible pairs
		qui su `outcome' if (`outcome'!=.) & (`touse'), meanonly
		local obs = r(N)
		local prev = r(mean)
		local events = r(sum)
		local nonevents = r(N) - r(sum)
		local pairs = `events'*`nonevents'  

		// compute c-stat (allowing for ties)
		qui su `diff_disc' if `touse'
		local disc = r(sum)
		qui su `diff_cord' if `touse'
		local cord = r(sum)

		local ties = `pairs'-`disc'-`cord'

		local cstat = (`cord'+(0.5*`ties'))/(`pairs')
	}
	
***************************************** CI

if "`hanley'"=="" {
	// default use necombe SE formula
	local newcombe_c = `cstat'
	local cstat_se = ((`cstat'*(1-`cstat'))*(1+(((`obs'/2)-1)*((1-`cstat')/(2-`cstat'))) ///
	+((((`obs'/2)-1)*`cstat')/(1+`cstat')))/((`obs'^2)*`prev'*(1-`prev')))^.5
	local cstat_lb = `cstat' - (1.96*`cstat_se')
	local cstat_ub = `cstat' + (1.96*`cstat_se')
}
else {
	// if hanley option set then use hanley SE formula 
	local Q1 = `cstat' / (2 - `cstat')
	local Q2 = 2 * `cstat'^2 / (1 + `cstat')
	local hanley_c = `cstat'
	local cstat_se = sqrt((`cstat' * (1 - `cstat') + (`nonevents' - 1) * (`Q1' - `cstat'^2) + (`events' - 1) * (`Q2' - `cstat'^2)) / (`nonevents' * `events'))
	local cstat_lb = `cstat' - (1.96*`cstat_se')
	local cstat_ub = `cstat' + (1.96*`cstat_se')
}


***************************************** OUTPUT

// Creating matrix of results
local res cstat 

	tempname rmat
	matrix `rmat' = J(1,5,.)
	local i=0
	foreach r of local res {
		local ++i
		matrix `rmat'[`i',1] = `obs'
		matrix `rmat'[`i',2] = ``r''
		matrix `rmat'[`i',3] = ``r'_se'
		matrix `rmat'[`i',4] = ``r'_lb'
		matrix `rmat'[`i',5] = ``r'_ub'

		//local rown "`rown' `r'"
		}
		mat colnames `rmat' = Obs Estimate SE Lower_CI Upper_CI
		mat rownames `rmat' = "C-Statistic" //`rown'

		
// print matrix 
if "`matrix'"!="" {
			matrix `matrix' = `rmat'
			
			//return matrix `matrix' = `rmat' 
			if "`print'"!="noprint" {
				//di as res _n "Discrimination statistics ..."
				matlist `matrix', border(all) //format(%9.3f)
							
				}
				*return matrix `matrix' = `rmat'
			}
			else { 
				if "`print'"!="noprint" {
					//di as res _n "Discrimination statistics ..."
					matlist `rmat', border(all) //format(%9.3f)
							
					}
				*return matrix rmat = `rmat'
				}
				
// Return scalars
local res cstat cstat_se cstat_lb cstat_ub cord disc ties  obs
 
		foreach r of local res {
			return scalar `r' = ``r''
			}
			
		if "`matrix'"!="" {
		    matrix `matrix' = `rmat'
			return matrix `matrix' = `rmat'
		}
		else {
		    return matrix rmat = `rmat'
		}
		
restore

end

