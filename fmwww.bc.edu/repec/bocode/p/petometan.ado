*! version 7.1.7  04nov2009
* Modified from "sts.ado" and "logrank.ado"

* Originally written by David Fisher, 12th November 2009
* Modified (by David Fisher) as follows:

* May/June 2012, to incorporate aspects of meta-analysis
* ...and tidied up September 2012
* Various bug fixes October 2012

* Re-written to be a Peto meta-analysis command July 2013
* Includes all relevant code from "sts.ado", before the modified code from "logrank.ado"

* Note: This program deals with hazard ratios and meta-analysis
* and is therefore designed to handle TWO treatment groups only.
* For more general log-rank tests, use "sts test" as documented in the Stata manuals.

*! version 1.01  David Fisher  31jan2014

*! version 1.01.1 (beta)  David Fisher, November 2014
* Added glab label values
* Various refinements

* To do:
* Make -petometan- call -admetan- to draw tables/forestplot?? -- NO, TOO DIFFERENT
*   also display p-value and HRs plus O-E/V??

* Syntax:
* petometan trt_var [if] [in], [study(trial_id) by(subgroup) strata(other_strata)]
* where
* trt_var = treatment arm variable (coded such that trt=1, control=0)
* trial_id = trial identifier
* subgroup = optional trial-level subgroup identifier

* Data must be -stset-
* Data can be saved using MATsave option.

program define petometan, rclass sortpreserve
	
	version 8
	
	st_is 2 analysis
	local wt : char _dta[st_wt]
	if "`wt'"=="pweight" {
		disp as err `"Cannot specify pweights"'
		exit 198
	}
	
	syntax varname [if] [in] ///
		[, STUdy(varname) BY(varname) STRata(varlist) ///
		MATsave(name) noGRaph noHET noSUbgroup noOVerall OVSTAT(string) ///
		noTItle noSHow Level(cilevel) ]

	local arm "`varlist'"		// treatment arm
		
	st_show `show'
	tempvar touse
	st_smpl `touse' `"`if'"' "`in'"
	
	local w : char _dta[st_w]
	if `"`_dta[st_id]'"' != "" {
		local id `"id(`_dta[st_id]')"'
	}
	local t0 "_t0"
	local t1 "_t"
	local dead "_d"

	tempvar touse
	mark `touse' `if' `in' [`weight'`exp']
	markout `touse' `t1' `dead'
	markout `touse' `arm' `study' `by' `strata', strok
	
	* start of added section Nov 2014 (from logrank.ado)
	if `"`t0'"'!=`""' & `"`id'"'!=`""' {
		local id
	}
	if `"`t0'"'==`""' & `"`id'"'==`""' {
		tempvar t0
		qui gen byte `t0' = 0
	}
	else if `"`t0'"' != `""' { 
		markout `touse' `t0'
	}
	else if `"`id'"'!=`""' {
		markout `touse' `id'
		quietly {
			sort `touse' `id' `t1'
			local ty : type `t1'
			by `touse' `id': gen `ty' `t0' = cond(_n==1, 0, `t1'[_n-1])
		}
		capture assert `t1'>`t0'
		if _rc {
			di in red `"repeated records at same `t1' within `id'"'
			exit 498
		}
		* N.B. `id' is not needed any more
	}

	capture assert `t1'>0 if `touse'
	if _rc { 
		di in red `"survival time `t1' <= 0"'
		exit 498
	}
	capture assert `t0'>=0 if `touse'
	if _rc { 
		di in red `"entry time `t0' < 0"'
		exit 498
	}
	capture assert `t1'>`t0' if `touse'
	if _rc {
		di in red `"entry time `t0' >= survival time `t1'"'
		exit 498
	}
	capture assert `dead'==0 if `touse'
	if _rc==0 {
		di in red `"no test possible because there are no failures"'
		exit 2000
	}
	if `"`strata'"' != "" {
		tempvar isdead
		sort `strata'
		qui by `strata': gen long `isdead' = sum(`dead')
		qui by `strata': replace `isdead' = . if _n<_N
		qui count if `isdead' == 0 & `touse'
		local n_omit = r(N)
		if `n_omit' > 0 {
			if `n_omit' == 1 {
				local endng um
			}
			else {
				local endng a
			}
			local note `"Note: `n_omit' strat`endng' omitted because of no failures"'
		}
	}
	* end of added section
	
	* markout `touse' `t0'
	
	qui count if `touse'
	if !r(N) {
		disp as err "no observations"
		exit 2000
	}
	
	tempvar obs
	qui gen long `obs'=_n
	
	* Treatment arm variable should be coded such that "`arm'==1" denotes treatment and "`arm'==0" control
	summ `arm' if `touse', meanonly
	local armok = `r(min)'==0 & `r(max)'==1
	qui tab `arm' if `touse'
	local armok = `armok' * (`r(r)'==2)
	if !`armok' {
		di as err _n `"Treatment arm should be coded 0 = control, 1 = research"'
		exit 498
	}
	local g `arm'
	local glab : value label `g'
	
	if "`glab'"==`""' {
		tempname glab
		label define `glab' 0 "Control" 1 "Treatment"
	}
	
	/*
	tempvar g
	qui bysort `arm': gen long `g' = (_n==1)
	qui replace `g' = sum(`g')
	if `g'[_N]!=2 {
		di in red `"`by' variable is not binary"'
		exit 498
	}
	
	* Transfer labels, values or strings to new treatment arm variable
	tempname glab
	capture confirm string variable `arm'
	forvalues i=1/2 {
		if !_rc {
			summ `obs' if `g'==`i', meanonly
			local glabi = `arm'[`r(min)']
		}
		else {
			summ `arm' if `g'==`i', meanonly
			local glabi : label (`arm') `r(min)'		// N.B. will return `r(min)' if no label
			local glabi = cond("`glabi'"=="`r(min)'", cond(`i'==1, "Treatment", "Control"), "`glabi'")
		}
		label define `glab' `i' `"`glabi'"', add
	}
	*/
	* Store variable label
	local gvarlab : variable label `arm'
	if `"`gvarlab'"'==`""' local gvarlab `"`arm'"'
	
	* Create new study ID based on order of first occurrence
	local ns = 1					// default
	local nby = 0					// default
	if `"`study'"'!=`""' {
		tempvar s sobs
		qui bysort `touse' `study' (`obs') : gen long `sobs' = `obs'[1]
		qui bysort `touse' `by' `sobs' : gen long `s' = (_n==1) * `touse'
		qui replace `s' = sum(`s')
		local ns = `s'[_N]			// number of `study'*`by' groups -- should be equal to no. of studies!

		* Transfer labels, values or strings to new treatment arm variable
		tempname studylab
		capture confirm string variable `study'
		forvalues i=1/`ns' {
			if !_rc {
				summ `obs' if `s'==`i', meanonly
				local si = `study'[`r(min)']
			}
			else {
				summ `study' if `s'==`i', meanonly
				local si : label (`study') `r(min)'		// N.B. will return `r(min)' if no label
			}
			label define `studylab' `i' `"`si'"', add
		}
		* Store variable label
		local svarlab : variable label `study'
		if `"`svarlab'"'==`""' local svarlab `"`study'"'
	
		* Create new subgroup ID (BY) based on "natural ordering"
		if `"`by'"'!=`""' {
			
			* Check that `by' is trial-level
			qui tab `s' if `touse'
			if `r(r)' != `ns' {			// N.B. `ns' is already stratified by `by'
				disp as err _n "Data is not suitable for meta-analysis" _c
				disp as err " as subgroup variable (in option 'by') is not constant within trials."
				exit 198
			}
			else {
				tempvar byobs bygroup
				qui bysort `touse' `by' : gen int `bygroup' = (_n==1) * `touse'
				qui replace `bygroup' = sum(`bygroup')
				local nby = `bygroup'[_N]				// number of subgroups
				
				* Transfer labels, values or strings to new BY variable
				sort `obs'
				tempname bylab
				capture confirm string variable `by'
				forvalues i=1/`nby' {
					if !_rc {
						summ `obs' if `bygroup'== `i', meanonly
						local bylabi = `by'[`r(min)']
					}
					else {
						summ `by' if `bygroup'== `i', meanonly
						local bylabi : label (`by') `r(min)'		// N.B. will return `r(min)' if no label
					}
					label define `bylab' `i' `"`bylabi'"', add
				}
				
				* Store variable label
				local byvarlab : variable label `by'
				if `"`byvarlab'"'==`""' local byvarlab `"`by'"'
				local by `"`bygroup'"'
			}
		}
	}
	else if `"`by'"'!=`""' {
		disp as err "Cannot specify 'by' without 'study'"
		exit 198
	}

	
	* Begin manipulating data
	preserve 
	
	if `"`weight'"' != `""' { 
		tempvar w 
		qui gen double `w' `exp' if `touse'
		local wv `"`w'"'
		local wntype "double"	// "gen double `n`i''" if weights
	}
	else {
		local w 1
		local wntype "long"		// "gen long `n`i''" if no weights (since in that case must be whole numbers)
	}
	tempvar op n d
	quietly {
		keep if `touse'
		qui count
		return scalar N = r(N)
		keep `s' `g' `wv' `t0' `t1' `by' `strata' `dead'
		
		* Denominators
		* (need to calculate these before limiting to unique times only)
		* Only need to know denominators per study, per subgroup, and overall
		* Strata are irrelevant as main calculations don't use denoms, & strata-specific stats are not presented
		if trim(`"`study' `by'"') != `""' {
			local bystr `"by `by' `s':"'
		}
		* forvalues i=1/2 {
		forvalues i=0/1 {
			sort `by' `s' `g' `t1'
			tempvar NN`i'
			`bystr' gen long `NN`i''=sum(cond(`g'==`i',1,0))
			sort `by' `s' `NN`i''
			`bystr' replace `NN`i''=`NN`i''[_N]
		}
		
		* Now re-define "bystr" for main calculations
		* This time "by" is irrelevant since it must be trial-level
		* but "strata" ARE relevant
		if trim(`"`study' `by' `strata'"') != `""' {
			local bystr `"by `s' `strata':"'
		}		
		local N = _N
		expand 2
		gen byte `op' = 3/*add*/ in 1/`N'
		replace `t1' = `t0' in 1/`N'
		drop `t0'
		local ++N
		replace `op' = cond(`dead'==0,2/*cens*/,1/*death*/) in `N'/l

		sort `s' `strata' `t1' `op' `g'
		`bystr' gen `wntype' `n' = sum(cond(`op'==3,`w',-`w'))
		by `s' `strata' `t1': gen `wntype' `d' = sum(`w'*(`op'==1))

		* Numbers at risk, and observed number of events (failures)
		* forvalues i=1/2 {
		forvalues i=0/1 {
			tempvar ni`i' di`i'
			`bystr' gen `wntype' `ni`i'' = sum(cond(`g'==`i', cond(`op'==3,`w',-`w'), 0))
			by `s' `strata' `t1': gen `wntype' `di`i'' = sum(cond(`g'==`i', `w'*(`op'==1), 0))
			* N.B. `w' is not needed any more
		}
		by `s' `strata' `t1': keep if _n==_N		// keep unique times only

		* Shift `n' up one place so it lines up
		tempvar newn
		`bystr' gen `wntype' `newn' = `n'[_n-1]
		drop `n' 
		rename `newn' `n'
		
		* Shift each of the `ni's up one place so they line up
		* forvalues i=1/2 {
		forvalues i=0/1 {
			`bystr' gen `wntype' `newn' = `ni`i''[_n-1] if _n>1
			drop `ni`i''
			rename `newn' `ni`i''	
		}
		* drop if `d'==0			// keep failure times only - DON'T DO THIS, IN CASE SOME STUDIES HAVE NO FAILURES
		capture drop `strata'		// don't need strata vars anymore (and there may be many of them)

		* Calculate E (expected number of events/failures)
		* forvalues i=1/2 {
		forvalues i=0/1 {
			tempvar ei`i'
			gen double `ei`i'' = `ni`i''*`d'/`n'
		}
		* Calculate V (hypergeometric variance)
		tempvar V
		assert float(`ni0' + `ni1') == float(`n')		// arithmetic check
		gen double `V' = `ni0'*`ni1'*`d'*(`n'-`d')/(`n'*`n'*(`n'-1))

		* Calculate O - E
		tempvar OE OEsq
		gen double `OE'=`di1'-`ei1'						// use treatment arm
		assert float(`OE') == float(`ei0'-`di0')		// arithmetic check
		
		* At this point we have one obs per unique failure time per arm per trial.
		* Now "collapse" to one obs per study (or just one obs), plus (sub)totals
		if `"`study'"'!=`""' {
			sort `s'
			local bys `"by `s':"'
		}
		* foreach x of varlist `OE' `V' `di1' `di2' {
		foreach x of varlist `OE' `V' `di0' `di1' {
			`bys' replace `x' = sum(`x')
		}
		`bys' keep if (_n == _N)
		tempvar obs
		gen long `obs' = 1
		
		* Generate new obs for subgroup/overall statistics
		if `"`study'"'!=`""' {
		
			assert `ns' == _N
			local newn = `ns' + (`"`overall'"'==`""') + (`"`subgroup'"'==`""')*`nby'	// create rows to hold subgroup & overall totals
			set obs `newn'
			tempvar newobs
			gen byte `newobs' = (_n > `ns')		// flag new observations
			
			tempvar Q
			gen double `Q'=.
			label var `Q' "Q"
			
			* Subgroup totals
			if `"`by'"'!=`""' & `"`subgroup'"'==`""' {
				forvalues i=1/`nby' {
					local ii = `ns' + `i'
					replace `by' = `i' in `ii'
				}
				sort `by' `s'
				* foreach x of varlist `V' `OE' `di1' `di2' `NN1' `NN2' `obs' {
				foreach x of varlist `V' `OE' `di0' `di1' `NN0' `NN1' `obs' {
					tempvar bysum`x'
					by `by' : gen double `bysum`x'' = sum(`x')
					by `by' : replace `bysum`x'' = `bysum`x''[_N]
				}
				tempvar qpart
				by `by' : gen double `qpart' = sum(`V'*(((`OE'/`V')-(`bysum`OE''/`bysum`V''))^2))
				by `by' : replace `qpart' = `qpart'[_N]
				replace `Q' = `qpart' if `newobs' & !missing(`by')
				drop `qpart'
			}

			* Overall totals
			if `"`overall'"'==`""' {
				* foreach x of varlist `V' `OE' `di1' `di2' `NN1' `NN2' `obs' {
				foreach x of varlist `V' `OE' `di0' `di1' `NN0' `NN1' `obs' {
					tempvar sum`x'
					gen double `sum`x'' = sum(`x')
					replace `sum`x'' = `sum`x''[_N]
					replace `x' = `sum`x'' if `newobs' & missing(`Q')		// insert totals in new rows
				}
			
				tempvar Vsq qtot 
				gen double `Vsq' = `V'^2
				gen double `qtot'=sum(`V'*(((`OE'/`V')-(`sum`OE''/`sum`V''))^2))
				replace `qtot' = `qtot'[_N]
				replace `Q' = `qtot' if `newobs' & missing(`Q')
				
				local OEtot = `sum`OE''
				local Vtot = `sum`V''
			}
		}
		else {						// if `"`study'"'==`""'
			local OEtot = `OE'
			local Vtot = `V'
			local sum`di0' = `di0'
			local sum`di1' = `di1'
			* local sum`di2' = `di2'
		}

		if `"`overall'"'==`""' {
			local lnHR = `OEtot'/`Vtot'
			local selnHR = 1/sqrt(`Vtot')
			local chi2 = (`OEtot'^2)/`Vtot'			

			* return scalar o = `sum`di1''+`sum`di2''
			return scalar o = `sum`di0''+`sum`di1''
			return scalar OE = `OEtot'
			return scalar V = `Vtot'
			return scalar lnHR =`lnHR'
			return scalar selnHR = `selnHR'
			return scalar chi2 = `chi2'			
		}
		
		if `"`study'"'!=`""' {
			if `"`overall'"'==`""' {
				* drop `sum`di1'' `sum`di2'' `sum`NN1'' `sum`NN2'' `sum`OE'' `sum`V''
				drop `sum`di0'' `sum`di1'' `sum`NN0'' `sum`NN1'' `sum`OE'' `sum`V''
			}
			if `"`by'"'!=`""' & `"`subgroup'"'==`""' {
				* foreach x of varlist `V' `OE' `di1' `di2' `NN1' `NN2' `obs' {
				foreach x of varlist `V' `OE' `di0' `di1' `NN0' `NN1' `obs' {
					replace `x' = `bysum`x'' if `newobs' & !missing(`by')	// insert totals in new rows
				}
				* drop `bysum`di1'' `bysum`di2'' `bysum`NN1'' `bysum`NN2'' `bysum`OE'' `bysum`V''
				drop `bysum`di0'' `bysum`di1'' `bysum`NN0'' `bysum`NN1'' `bysum`OE'' `bysum`V''
			}
		}
	}			// end "quietly"
	
	* Print to screen
	tempvar counts0 counts1 /*counts2*/
	qui gen str `counts0' = string(`di0') + "/" + string(`NN0')		// don't use tempvar here so can send to forestplot
	qui gen str `counts1' = string(`di1') + "/" + string(`NN1')		// don't use tempvar here so can send to forestplot
	* qui gen str `counts2' = string(`di2') + "/" + string(`NN2')
	label var `counts0' "`: label `glab' 0'"						// REVISIT: replace with glab value labels?
	label var `counts1' "`: label `glab' 1'"						// REVISIT: replace with glab value labels?
	* label var `counts2' "`: label `glab' 2'"
	label var `OE' "o-E(o)"
	label var `V' "Var(o)"

	local bystr
	if `"`by'"'!=`""' {
		local bystr `"by(`by')"'
		label values `by' `bylab'
		label var `by' `"`byvarlab'"'
	}
	if `"`study'"'!=`""' {
		label values `s' `studylab'
		label var `s' `"`svarlab'"'
	}
	else {
		tempvar s
		qui gen byte `s'=1
		label var `s' "Study"
	}
	* tabdisp `s', cell(`counts1' `counts2' `OE' `V') format(%04.2f) totals concise `bystr'
	tabdisp `s', cell(`counts0' `counts1' `OE' `V') format(%04.2f) totals concise `bystr'
	
	* Display effect sizes & tests
	if `"`overall'"'==`""' {
		local CI_lo=exp(`lnHR'-(invnorm((100+`level')/200)*`selnHR'))
		local CI_hi=exp(`lnHR'+(invnorm((100+`level')/200)*`selnHR'))
		local Qtot = `Q'[_N]
		local df = `ns'-1
		return scalar Q = `Qtot'
		return scalar k = `ns'
		local Qpval = chi2tail(`df', `Qtot')
		disp _n
		if `"`by'"'!=`""' disp as text "Overall"
		disp as text "Pooled hazard ratio = " as res %5.3f `=exp(`lnHR')'
		disp as text "Two-sided `level'% confidence limit = (" as res %5.3f `CI_lo' as text ", " as res %5.3f `CI_hi' as text ")"
	}
		
	if `"`study'"'!=`""' {
		if `"`overall'"'==`""' {
			disp as text "Q for heterogeneity = " as res %5.3f `Qtot' as text " on " as res `df' as text " d.f., p = " as res %5.3f `Qpval'
		}
	
		* Subgroups
		if `"`by'"'!=`""' & `"`subgroup'"'==`""' {
			local Qsum = 0
			sort `newobs' `by' `s'
			forvalues i=1/`nby' {
				local lnHR`i' = `OE'[`=`ns'+`i'']/`V'[`=`ns'+`i'']
				local selnHR`i' = 1/sqrt(`V'[`=`ns'+`i''])
				local Q`i' = `Q'[`=`ns'+`i'']
				local Qsum = `Qsum' + `Q`i''
				local df`i' = `obs'[`=`ns'+`i''] - 1
				local Qpval`i' = chi2tail(`df`i'', `Q`i'')
				local CI_lo=exp(`lnHR`i''-(invnorm((100+`level')/200)*`selnHR`i''))
				local CI_hi=exp(`lnHR`i''+(invnorm((100+`level')/200)*`selnHR`i''))
				disp as text _n `"`: label `bylab' `i''"'
				disp as text "Pooled hazard ratio = " as res %5.3f `=exp(`lnHR`i'')'
				disp as text "Two-sided `level'% confidence limit = (" as res %5.3f `CI_lo' as text ", " as res %5.3f `CI_hi' as text ")"
				disp as text "Q for heterogeneity = " as res %5.3f `Q`i'' as text " on " as res `df`i'' as text " d.f., p = " as res %5.3f `Qpval`i''
			}
			
			* Between-subgroup heterogeneity
			if `"`overall'"'==`""' {
				local Qb = `Qtot' - `Qsum'
				local dfb = `nby' - 1
				local Qbpval = chi2tail(`dfb', `Qb')
				disp as text _n `"Between-subgroup heterogeneity = "' as res %5.3f `Qb' as text " on " as res `dfb' as text " d.f., p = " as res %5.3f `Qbpval'
			}
		}
	}
	
	* Matrix output
	if `"`matsave'"'!=`""' {
		* qui mkmat `s' `by' `NN1' `NN2' `di1' `di2' `ei1' `OE' `V' if !missing(`s'), matrix(`matsave')
		qui mkmat `s' `by' `NN0' `NN1' `di0' `di1' `ei1' `OE' `V' if !missing(`s'), matrix(`matsave')
		if `"`by'"'!=`""' local byname "by"
		matrix colnames `matsave' = s `byname' N1 N2 d1 d2 e OE V
	}

	* Output data to forestplot program
	if `"`graph'"'==`""' {

		quietly {
			* drop `NN1' `NN2' `di1' `di2' `ei1' `ei2'		
			drop `NN0' `NN1' `di0' `di1' `ei0' `ei1'		
			
			rename `OE' OE
			rename `V' V
			format OE %5.2f
			format V %5.2f

			rename `counts0' counts0
			rename `counts1' counts1
			* rename `counts2' counts2
			rename `s' _STUDY
			if `"`by'"'!=`""' {
				rename `by' _BY
				local _by "_BY"
			}
					
			gen _ES = OE/V
			gen _seES = 1/sqrt(V)
			gen _WT = V/`Vtot'
			if `"`: value label _STUDY'"'!=`""'	decode _STUDY, gen(_LABELS)
			else gen _LABELS = string(_STUDY)
			
			gen _USE=.
			replace _USE=1 if !missing(_STUDY)
			if `"`by'"'!=`""' {
				replace _USE=3 if missing(_STUDY) & !missing(_BY)
				replace _USE=5 if missing(_BY)
			}
			else replace _USE=5 if missing(_STUDY) 
			
			tempvar use5
			qui gen `use5' = (_USE==5)
			
			if `"`by'"'!=`""' {					// subgroup titles
				tempvar expand
				bysort _BY : gen byte `expand' = 1 + 2*(_n==1)*(!`use5')
				expand `expand'
				gsort _BY -`expand' _USE _STUDY
				by _BY : replace _USE=0 if `expand'>1 & _n==2		/* row for labels */
				by _BY : replace _USE=4 if `expand'>1 & _n==3		/* row for blank line */
				drop `expand'
				
				if "`subgroup'"=="" & "`het'"=="" {
					tempvar expand
					bysort _BY : gen byte `expand' = 1 + (_n==_N)*(!`use5')
					expand `expand'
					gsort _BY -`expand' _USE _STUDY
					by _BY : replace _USE=3.5 if `expand'>1 & _n==2 		/* extra row for het */
				}
			}
			
			* Overall heterogeneity - extra row
			if `"`overall'"'==`""' & "`het'"=="" {
				local newN = `=_N+1'
				set obs `newN'
				replace _USE=5.5 in `newN'
			}
			
			* Blank out effect sizes etc. in new rows
			foreach x of varlist _LABELS _ES _seES _WT counts0 counts1 OE V {
				capture confirm numeric variable `x'
				if !_rc replace `x' = . if !inlist(_USE, 1, 3, 5)
				else replace `x' = "" if !inlist(_USE, 1, 3, 5)
			}

			* Add between-group heterogeneity info if appropriate
			if `"`by'"'!=`""' & `"`overall'"'==`""' & `"`het'"'==`""' {
				local newN = _N+1
				set obs `newN'
				replace _USE = 4.5 in `newN'
				replace `use5' = 0 in `newN'
				replace _LABELS = "Heterogeneity between groups: p = " + string(`Qbpval', "%5.3f") in `newN'
			}
			
			replace _LABELS = "Overall" if _USE==5
			
			if "`ovstat'"=="q" { 
				local ovlabel "(Q = " + string(`Qtot', "%5.2f") + " on `df' df, p = " + string(`Qpval', "%5.3f") + ")"
			}
			else {
				local Isq = max(0, (`Qtot' - `df') / `Qtot')
				local ovlabel "(I-squared = " + string(100*`Isq', "%5.1f")+ "%, p = " + string(`Qpval', "%5.3f") + ")"
			}
			replace _LABELS = "`ovlabel'" if _USE==5.5
		
			* Subgroup ("by") labels
			forvalues i=1/`nby' {
				replace _LABELS = "Subtotal" if _USE==3 & _BY==`i'
				
				if "`ovstat'"=="q" {
					local ovlabel "(Q = " + string(`Q`i'', "%5.2f") + " on `dfi' df, p = " + string(`Qpval`i'', "%5.3f") + ")"
				}
				else {
					local Isq`i' = max(0, (`Q`i'' - `df`i'') / `Q`i'')
					local ovlabel "(I-squared = " + string(100*`Isq`i'', "%5.1f")+ "%, p = " + string(`Qpval`i'', "%5.3f") + ")"
				}
				replace _LABELS = "`ovlabel'" if _USE==3.5 & _BY==`i'
					
				local bytext : label `bylab' `i'
				replace _LABELS = "`bytext'" if _USE==0 & _BY==`i'
			}
			
			sort `_by' _USE _STUDY
			replace _USE = 0 if _USE == -1
			replace _USE = 4 if inlist(_USE, -0.5, -1.5, 2.5, 4.5)
			replace _USE = 3 if _USE == 3.5
			replace _USE = 5 if _USE == 5.5
			
			gen _LCI = _ES - invnorm(0.975)*_seES
			gen _UCI = _ES + invnorm(0.975)*_seES

		}	// end quietly
		
		order _USE `_by' _STUDY _LABELS _ES _seES _LCI _UCI _WT

		forestplot, nopreserve by(`_by') labels(_LABELS) eform ///
				nowt nostats lcols(counts0 counts1) rcols(OE V)
	}

end

