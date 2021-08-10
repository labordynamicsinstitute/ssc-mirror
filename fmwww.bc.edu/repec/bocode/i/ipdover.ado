* "over" functionality for ipdmetan
* In separate program on advice of Patrick Royston
* created by David Fisher, February 2013

* version 1.0  David Fisher  31jan2014
* version 1.01 David Fisher  11aug2016

* August 2016:  began adapting code for Syntax 2 of -ipdmetan- (see help file)

* March 2017
// Needs further thought re behaviour of keepall, "study, m" and "by, m"
// when some combinations of study and by do not exist in the data.
// Should they be displayed nevertheless, with the message "(No subgroup data)" or similar?
// (note this is an ipdover issue rather than an ipdmetan/admetan issue)
// (this is for the next version of the package)

*! version 2.0  David Fisher  11may2017
* Major update of all parts of the ipdmetan package, including ipdover.ado


program define ipdover, rclass

	version 11
	* NOTE: mata requires v9 (??)
	* factor variable syntax requires 11.0
	* but neither is vital to ipdover

	// ipdmetan has two possible syntaxes:
	
	// "generic" effect measure / Syntax 1  ==> ipdmetan [exp_list] .... : [command] [if] [in] ...
	// (calculations based on an estimation model fitted within each study)
	
	// "specific" effect measure / Syntax 2  ==> ipdmetan varlist [if] [in] ...  **no colon**
	// (raw event counts or means (SDs) within each study using some variation on -collapse-)
	
	// We can let ipdmetan.ado sort out the details; we just want to parse certain options first
	// (i.e. those that ipdover.ado will need to use after taking back control from ipdmetan.ado)

	// So:
	syntax [anything(everything)], OVER(string) [STUDY(string) BY(string) * ]

	if `"`study'"' != `""' {
		disp as err "cannot specify study() with ipdover; please use over() or the ipdmetan program"
		exit 198
	}
	if `"`by'"' != `""' {
		disp as err "cannot specify by() with ipdover; please use over() or the ipdmetan program"
		exit 198
	}
	
	local Options `"`options'"'		// note capital "O" to distinguish
	local 0 `over'
	syntax varlist [, Missing]
	local over1 `varlist'
	local overlen : word count `over1'
	local missing1 `missing'

	* Parse "over" options and map to study() and by() as appropriate
	* (N.B. "over" as a named option is NOT passed to ipdmetan!)
	local 0 `", `Options'"'
	syntax [, OVER(string) * ]
	local Options `"`options'"'		// note capital "O" to distinguish
	local 0 `over'
	syntax [varlist(default=none)] [, Missing]
	local over2 `varlist'
	local missing2 `missing'

	local 0 `", `Options'"'
	syntax [, OVER(string) * ]
	if `"`over'"'!=`""' {
		di as error "may not specify more than two {bf:over()} options"
		exit 198
	}
	
	local nv2 : word count `over2'		// no. of vars in `over2'
	if `nv2' > 1 {
		disp as err "cannot specify multiple vars to second {bf:over()} option"
		exit 198
	}
	
	local study `over1'
	if `"`missing1'"'!=`""' local study `"`over1', `missing1'"'

	local by `over2'
	if `"`missing2'"'!=`""' local by `"`over2', `missing2'"'

	
	** Now run ipdmetan
	// with "ipdover" option; this is a marker that data should not be pooled (i.e. is not a MA)
	// ipdmetan uses  -preserve- before modifying data
	
	// declare up to 6 tempvars to be used if "`cmdstruc'"=="specific"
	// ...and up to 4 more if logrank (note that we don't know if either of these is true yet!!)
	tempvar tv1 tv2 tv3 tv4 tv5 tv6 tv7 tv8 tv9 tv10
	local outvlist `tv1' `tv2' `tv3' `tv4' `tv5' `tv6'
	local lrvlist `tv7' `tv8' `tv9' `tv10'
	
	tempfile ipdfile labfile
	cap nois ipdmetan `anything', study(`study') by(`by') ///
		ipdover(ipdfile(`ipdfile') labfile(`labfile') outvlist(`outvlist') lrvlist(`lrvlist')) `options'

	if _rc {
		if `"`err'"'==`""' {
			if _rc==1 nois disp as err `"User break in {bf:ipdmetan}"'
			nois disp as err `"Error in {bf:ipdmetan}"'
		}
		exit _rc
	}
	
	// re-load dataset created within ipdmetan
	preserve
	qui use `ipdfile', clear	
	
	// collect "universal" returned statistics
	local cmdstruc  `r(cmdstruc)'
	local effect = cond(`"`r(effect)'"'!="", `"`r(effect)'"', "Effect")
	local eform     `r(eform)'
	local citype    `r(citype)'	
	local fplotopts `"`r(fplotopts)'"'
	local lcols     `"`r(lcols)'"'
	local rcols     `"`r(rcols)'"'
	local wt        `r(wt)'				// returned separately from ipdmetan.ado rather than sending straight to forestplot
	local totnpts = r(n)

	return local citype `citype'
	return scalar n =  `totnpts'
	
	// collect returned statistics specific to particular `cmdstruc'
	if "`cmdstruc'"=="generic" {
		local estvar `r(estvar)'
		local invlist `"_ES _seES"'
		
		return local estvar  `"`r(estvar)'"'
		return local command `"`r(finalcmd)'"'
		return local cmdname `"`r(cmdname)'"'
	}
	else {
		local lrvlist  `r(lrvlist)'
		local invlist  `r(invlist)'
		local summstat `r(summstat)'
		local log      `r(log)'

		local usummstat = upper("`summstat'")
		return local measure `"`log'`usummstat'"'
	}

	// Collect variable labels
	forvalues h=1/`overlen' {
		local varlab`h' `"`r(varlab`h')'"'
	}
	
	local outvlist `"_ES _seES _LCI _UCI _NN"'	// permanent vars, not tempvars
	
	// Now parse options (either originally specified to -ipdover-, or returned by -ipdmetan-
	local 0 `", `r(options)'"'
	syntax [, noOVerall noSUbgroup noTABle KEEPAll KEEPOrder LEVEL(passthru) DF(varname numeric) SAVING(string) noGRaph * ]
	local options_ipdm `"`options'"'
	
	
	** If raw data, more processing is required to obtain _ES, _seES, _LCI and _UCI
	// (processes otherwise done by admetan.ado)
	if "`cmdstruc'"=="specific" {

		// -cc- and -nocc- (N.B. need to do this now, as otherwise the options will conflict later)
		// also take the opportunity to parse other options, required later on, for "specific" effect measure syntax (Syntax 2)
		if `"`options_ipdm'"'!=`""' {
			local 0 `", `options_ipdm'"'
			syntax [, CC(string) COunts GROUP1(string asis) GROUP2(string asis) OEV * ]
			local yescc `"`cc'"'
			local 0 `", `options'"'
			syntax [, noCC * ]
			local options_ipdm `"`options'"'
			if `"`cc'"'!=`""' & `"`yescc'"'!=`""' {
				if `"`yescc'"'!=`"0"' {
					disp as err `"Cannot specify both {bf:cc()} and {bf:nocc}; please choose one or the other"'
					exit 198
				}
				else local cc `"cc(0)"'
			}
			else {
				if `"`yescc'"'!=`""' {
					confirm number `yescc'
				}
				local cc = cond(`"`cc'"'!=`""', `"cc(0)"', cond(`"`yescc'"'!=`""', `"cc(`yescc')"', `""'))	// "`cc'"=="" if not supplied by user
			}																								// will default to 0.5 later, if appropriate		
		}

		cap nois GenEffectVars _USE `invlist', outvlist(`outvlist') ///
			summstat(`summstat') `logrank' `cc' `level' `options_ipdm'
		
		if _rc {
			if `"`err'"'==`""' {
				if _rc==1 nois disp as err `"User break in {bf:ipdover.GenEffectVars}"'
				else nois disp as err `"Error in {bf:ipdover.GenEffectVars}"'
			}
			exit _rc
		}		
		// We now have _ES and _seES defined throughout.
		
		// Next, identify excluded studies, remove them if appropriate, and check that at least one valid estimate exists
		//  (N.B. otherwise, identify them by "_USE==2")
		qui replace _USE=2 if _USE==1 & missing(_ES, _seES)
		if `"`keepall'"'==`""' qui drop if _USE==2
		summ _ES, meanonly
		if !`r(N)' exit 2000
	}

	// Create confidence limit variables if necessary
	cap confirm numeric variable _LCI
	if _rc==7 {
		disp as err "variable {bf:_LCI} exists and is string"
		exit _rc
	}
	else if _rc qui gen double _LCI = .
	cap confirm numeric variable _UCI
	if _rc==7 {
		disp as err "variable {bf:_UCI} exists and is string"
		exit _rc
	}
	else if _rc qui gen double _UCI = .	
	
	// Generate confidence limit values if necessary
	cap nois GenConfInts `invlist' if missing(_LCI, _UCI), citype(`citype') df(`df') `level' outvlist(`outvlist')
	if _rc {
		if `"`err'"'==`""' {
			if _rc==1 nois disp as err `"User break in {bf:ipdover.GenConfInts}"'
			else nois disp as err `"Error in {bf:ipdover.GenConfInts}"'
		}
		exit _rc
	}
	
	
	** Finish off: return stats & matrices; print to screen; saving/forestplot
	
	// remove studies with insufficient data if appropriate
	if `"`keepall'"'==`""' qui drop if _USE==2
	
	// otherwise, maintain original order if requested
	else if `"`keeporder'"'!=`""' {
		tempvar olduse
		qui gen byte `olduse' = _USE
		replace _USE = 1 if _USE==2		// keep "insufficient data" studies in original study order (default is to move to end)
	}

	// markers of existence of _BY and _OVER
	// N.B. only _LEVEL is guaranteed to exist.
	// _OVER will only exist if `overlen'>1 (i.e. if there is a need to distinguish)
	cap confirm var _BY
	local _BY = cond(_rc, "", "_BY")
	cap confirm var _OVER
	local _OVER = cond(_rc, "", "_OVER")

	// need to sort before forming matrix
	// missing values in _BY may cause problems, so need to be careful!
	summ _USE, meanonly
	if r(max)==5 {
		tempvar use5
		qui gen byte `use5' = (_USE==5)			// marker of _USE==5 to sort on *before* _BY (to get around the issue of missing _BY values)
	}	
	local notuse5 = cond("`use5'"=="", "", `"*(!`use5')"')
	
	// return matrix of coefficients
	tempname coeffs
	sort `use5' `_BY' `_OVER' _USE _LEVEL
	mkmat `_OVER' `_BY' _LEVEL _ES _seES _NN if inlist(_USE, 1, 2), matrix(`coeffs')
	return matrix coeffs=`coeffs'

	
	
	********************************************
	* Print summary info and results to screen *
	********************************************

	* Print number of studies/patients to screen
	//  (NB nos. actually analysed as opposed to the number supplied in original data)
	disp _n _c
	if !missing(`totnpts') local dispnpts = string(`totnpts')
	else {
		local dispnpts "Unknown"
		if "`overall'"!="" local textf " (overall estimation not run)"
	}
	local dispnpts = cond(missing(`totnpts'), "Unknown", string(`totnpts'))
	disp as text "Participants included: " as res "`dispnpts'" as text "`textf'"
	
	
	* Full descriptions of `summstat', `method' and `re_model' options, for printing to screen

	// Build up description of effect estimate type (interaction, cumulative etc.)
	if "`cmdstruc'"=="generic" {
		if `"`exp_list'"'!=`""' local disptxt "Trial subgroup analysis of user-specified effect estimate"
		else local disptxt "Trial subgroup analysis of main (treatment) effect estimate"
		di _n as text "`disptxt'" as res " `estvar'"
	}
	else if `"`summstat'"'!=`""' {
		local logtext = cond(`"`log'"'!=`""', `"`log' "', `""')		// add a space if `log'
		if "`summstat'"=="rr" local efftext "`logtext'Risk Ratios"
		else if "`summstat'"=="irr" local efftext "`logtext'Incidence Rate Ratios"
		else if "`summstat'"=="rrr" local efftext "`logtext'Relative Risk Ratios"
		else if "`summstat'"=="or"  local efftext "`logtext'Odds Ratios"
		else if "`summstat'"=="rd"  local efftext " Risk Differences"
		else if "`summstat'"=="hr"  local efftext "`logtext'Hazard Ratios"
		else if "`summstat'"=="shr" local efftext "`logtext'Sub-hazard Ratios"
		else if "`summstat'"=="tr"  local efftext "`logtext'Time Ratios"
		else if "`summstat'"=="wmd" local efftext " Weighted Mean Differences"	
		else if "`summstat'"=="smd" {
			local efftext " Standardised Mean Differences"
			if "`method'"=="cohen"       local efftextf `" as text " by the method of " as res "Cohen""'
			else if "`method'"=="glass"  local efftextf `" as text " by the method of " as res "Glass""'
			else if "`method'"=="hedges" local efftextf `" as text " by the method of " as res "Hedges""'
		}
			
		// Study-level effect derivation method
		if "`logrank'"!="" local efftext "Peto (logrank) `efftext'"
		else if "`method'"=="peto" local efftext "Peto `efftext'"
		di _n as text "Trial subgroup analysis of" as res " `efftext'" `efftextf'
	}

	
	** Table of results
	if `"`table'"'==`""' {

		// find maximum length of labels in LHS column
		tempvar vlablen
		qui gen long `vlablen' = length(_LABELS)
		if `"`_BY'"'!=`""' {
			tempvar bylabels
			cap decode _BY if inlist(_USE, 1, 2), gen(`bylabels')				// if value label
			if _rc qui gen `bylabels' = string(_BY) if inlist(_USE, 1, 2)		// if no value label
			qui replace `vlablen' = max(`vlablen', length(`bylabels'))
			drop `bylabels'
		}
		summ `vlablen', meanonly
		local lablen=r(max)
		drop `vlablen'
			
		forvalues h=1/`overlen' {
			local varlabopt `"`varlabopt' varlab`h'(`"`varlab`h''"')"'
			local len = length(`"`varlab`h''"')
			if `len'>`lablen' local lablen=`len'	
		}
		local stitle = cond(`overlen'>1, "Subgroup", `"`varlab1'"')
		if `"`_BY'"'!=`""' {
			local byvarlab : variable label `_BY'
			local byvarlab = cond(`"`byvarlab'"'!=`""', `"`byvarlab'"', `"`over2'"')
			local stitle `"`byvarlab' and `stitle'"'
		}
	}

	cap nois DrawTableIPD, overlen(`overlen') lablen(`lablen') stitle(`"`stitle'"') etitle(`"`effect'"') ///
		`eform' `varlabopt' `table' `overall' `subgroup'

	if _rc {
		if `"`err'"'==`""' {
			if _rc==1 nois disp as err `"User break in {bf:ipdover.DrawTableIPD}"'
			else nois disp as err `"Error in {bf:ipdover.DrawTableIPD}"'
		}
		exit _rc
	}


	
	******************************************
	* Prepare dataset for graphics or saving *
	******************************************

	if `"`saving'"'!=`""' | `"`graph'"'==`""' {
			
		quietly {
				
			if `"`saving'"'!=`""' {
			
				// Parse `saving' option first, to extract `stacklabel'
				// would like to use _prefix_saving here,
				//  but ipdmetan's 'saving' option has additional sub-options
				//  so have to parse manually
				local 0 `saving'
				cap nois syntax anything(id="file name" name=filename) [, STACKlabel REPLACE * ]
				if !_rc {
					if "`replace'" == "" {
						local ss : subinstr local filename ".dta" ""
						confirm new file `"`ss'.dta"'
					}
				}
				else {
					di as err "invalid saving() option"
					exit _rc
				}
				local saving `"`"`filename'"', `replace' `options'"'				
			}

			// variable name (titles) for "_LABELS" and "_NN"
			label var _LABELS `"`stitle'"'
			if `"`stacklabel'"'!=`""' label var _LABELS "Study ID"
			tempvar strlen
			
			if `"`: variable label _NN'"'==`""' label var _NN "No. pts"
			gen `strlen' = length(string(_NN))
			summ `strlen', meanonly
			local fmtlen = max(`r(max)', 3)		// min of 3, otherwise title ("No. pts") won't fit
			format _NN %`fmtlen'.0f				// right-justified; fixed format (for integers)
			drop `strlen'

			
			** Counts and OE/V
			if "`counts'"!="" {

				// Titles
				local title1 = cond(`"`group2'"'!=`""', `"`group2'"', `"Treatment"')
				local title0 = cond(`"`group1'"'!=`""', `"`group1'"', `"Control"')

				tempvar _counts1 _counts0
				tokenize `invlist'
				local params : word count `invlist'
				
				// Binary data & logrank HR
				if inlist(`params', 2, 4) {
					if `params'==4 {
						args e1 f1 e0 f0
						tempvar n1 n0
						qui gen long `n1' = `e1' + `f1'
						qui gen long `n0' = `e0' + `f0'
					}
					else {
						tokenize `lrvlist'
						args n1 n0 e1 e0
					}			
					qui gen `_counts1' = string(`e1') + "/" + string(`n1') if inlist(_USE, 1, 2, 3, 5)
					qui gen `_counts0' = string(`e0') + "/" + string(`n0') if inlist(_USE, 1, 2, 3, 5)
					label variable `_counts1' `"`title1' n/N"'
					label variable `_counts0' `"`title0' n/N"'
				}
						
				// N mean SD for continuous data
				// counts = "N, mean (SD) in research arm; N, mean (SD) events/total in control arm"
				else {
					tempvar _counts1msd _counts0msd
					args n1 mean1 sd1 n0 mean0 sd0
					
					qui gen long `_counts1' = `n1' if inlist(_USE, 1, 2, 3, 5)
					qui gen `_counts1msd' = string(`mean1', "%7.2f") + " (" + string(`sd1', "%7.2f") + ")" if inlist(_USE, 1, 2, 3, 5)
					label variable `_counts1' "N"
					label variable `_counts1msd' `"`title1' Mean (SD)"'
							
					qui gen long `_counts0' = `n0' if inlist(_USE, 1, 2, 3, 5)
					qui gen `_counts0msd' = string(`mean0', "%7.2f") + " (" + string(`sd0', "%7.2f") + ")" if inlist(_USE, 1, 2, 3, 5)
					label variable `_counts0' "N"
					label variable `_counts0msd' `"`title0' Mean (SD)"'
									
					// Find max number of digits in `_counts1', `_counts0'
					summ `_counts1', meanonly
					if r(N) {
						local fmtlen = floor(log10(`r(max)'))
						format `_counts1' %`fmtlen'.0f
					}
					summ `_counts0', meanonly
					if r(N) {
						local fmtlen = floor(log10(`r(max)'))
						format `_counts0' %`fmtlen'.0f
					}
				}

				if `"`saving'"'!=`""' {
					qui rename `_counts1' _counts1
					qui rename `_counts0' _counts0
					local _counts1 _counts1
					local _counts0 _counts0
					
					if `params'==6 {
						qui rename `_counts1msd' _counts1msd
						qui rename `_counts0msd' _counts0msd
						local _counts1msd _counts1msd
						local _counts0msd _counts0msd
					}
				}				
				
				local counts `"`_counts1' `_counts1msd' `_counts0' `_counts0msd'"'
				compress `counts'
				local lcols `"`counts' `lcols'"'
				local wt "nowt"						// turn off display of weights if counts
			
			}	// end if "`counts'"!=""
			
			if "`oev'"!="" {
				if "`logrank'"=="" {
					disp as err `"Note: {bf:oev} is not applicable without log-rank data and will be ignored"'
					local oev
				}
				else {
					tokenize `invlist'
					args oe v

					label variable `oe' `"O-E(o)"'
					label variable `v' `"V(o)"'
					format `oe' %6.2f
					format `v' %6.2f
					
					if `"`saving'"'!=`""' {
						qui rename `oe' _OE
						qui rename `v' _V
						local oe _OE
						local v _V
					}					
					
					local lcols `"`oe' `v' `lcols'"'
				}
			}		// end if "`oev'"!=""

			
			** Insert extra rows for headings, labels, spacings etc.
			//  Note: in the following routines, "half" values of _USE are used temporarily to get correct order
			//        and are then replaced with whole numbers at the end
			if trim(`"`_BY'`_OVER'"') != `""' { 
			
				tempvar expand
				
				* Subgroup headings (_USE==0) and spacings (_USE==4) for "over" (i.e. `overlen'>1)
				bysort `_BY' `_OVER' : gen byte `expand' = 1 + 2*(_n==1)`notuse5'
				expand `expand'
				replace `expand' = !(`expand' - 1)							// `expand' is now 0 if expanded and 1 otherwise
				sort `_BY' `_OVER' `expand' _USE _LEVEL
				by `_BY' `_OVER' : replace _USE=0 if !`expand' & _n==2		// row for headings
				by `_BY' `_OVER' : replace _USE=4 if !`expand' & _n==3		// row for blank line
				if `"`_OVER'"'!=`""' {
					drop if _USE==0 & missing(_OVER)						// ...but not needed for missing _over
				}
				drop `expand'
						
				// Extra subgroup headings if both "by" *and* "over"
				if `"`_BY'"'!=`""' & `"`_OVER'"'!=`""' {
					bysort _BY : gen byte `expand' =  1 + 3*(_n==1)`notuse5'
					expand `expand'
					replace `expand' = !(`expand' - 1)					// `expand' is now 0 if expanded and 1 otherwise
					sort _BY `expand' _USE _LEVEL
					by _BY : replace _USE=-1   if !`expand' & _n==2  	// row for "by" label (title)
					by _BY : replace _USE=-0.5 if !`expand' & _n==3		// row for blank line below title
					by _BY : replace _USE=4.5  if !`expand' & _n==4		// row for blank line to separate "by" groups
					drop if _USE==4.5 & missing(_OVER)					// ...but not needed for missing _OVER
					replace _OVER=. if _USE==4.5
					drop `expand'
				}
			}
			
			* Blank out effect sizes etc. in new rows
			foreach x of varlist _LABELS _ES _seES _LCI _UCI _NN `lcols' `rcols' {
				cap confirm numeric var `x'
				if !_rc replace `x' = . if !inlist(_USE, 1, 2, 3, 5)
				else replace `x' = "" if !inlist(_USE, 1, 2, 3, 5)
			}
			replace _LEVEL = . if !inlist(_USE, 1, 2)

			** Now insert label info into new rows
			//  over() labels
			if "`_OVER'"!="" {
				forvalues h=1/`overlen' {
					replace _LABELS = `"`varlab`h''"' if _USE==0 & _OVER==`h'
					label define _OVER `h' `"`varlab`h''"', add
				}
				label values _OVER _OVER
			}
			
			// extra row to contain what would otherwise be the leftmost column heading if `stacklabel' specified
			// (i.e. so that heading can be used for forestplot stacking)
			else if `"`stacklabel'"' != `""' {
				local nobs1 = _N+1
				set obs `nobs1'
				replace _USE = -1 in `nobs1'
				replace `use5' = -1 in `nobs1'
				replace _LABELS = `"`varlab1'"' in `nobs1'
			}
				
			// "overall" labels
			if `"`overall'"'==`""' {
				replace _LABELS = "Overall" if _USE==5
			}
			
			// subgroup ("by") headings & labels
			if `"`_BY'"'!=`""' {
				qui levelsof _BY if _USE!=5, missing local(bylist)		// _USE!=5 since that will always be missing!
				local bylab : value label _BY
				foreach byi of local bylist {

					// headings
					local bytext : label `bylab' `byi'
					if `"`_OVER'"'!=`""' replace _LABELS = "`bytext'" if _USE==-1 & _BY==`byi'
					else                 replace _LABELS = "`bytext'" if _USE==0  & _BY==`byi'
					
					// labels
					if `"`subgroup'"'==`""' {
						replace _LABELS = "Subgroup" if _USE==3 & _BY==`byi'
					}
				}
			}

			
			** Sort, and tidy up
			sort `use5' `_BY' `_OVER' _USE _LEVEL
			cap drop `use5'
			
			replace _USE = 0 if _USE == -1
			replace _USE = 6 if _USE == 4
			replace _USE = 3 if _USE == 3.5
			replace _USE = 5 if _USE == 5.5
			replace _USE = 4 if inlist(_USE, -0.5, 2.5, 3.25, 4.5, 5.5)
			if `"`keepall'"'!=`""' & `"`keeporder'"'!=`""' {
				replace _USE = 2 if _USE==1 & `olduse'==2
				drop `olduse'
			}

			// having added "overall", het. info etc., re-format _LABELS using study names only
			gen `strlen' = length(_LABELS)
			summ `strlen' if inlist(_USE, 1, 2), meanonly
			format _LABELS %-`r(max)'s		// left-justified; length equal to longest study name
			drop `strlen'

			compress
			if "`: type _NN'"=="byte" qui recast int _NN		// for forestplot `pc'
			
		}	// end quietly
				
		
		** Pass to forestplot
		if `"`graph'"'==`""' {
			tempvar touse
			qui gen byte `touse' = 1
			cap nois forestplot _ES _LCI _UCI, wgt(_NN, left) `wt' use(_USE) labels(_LABELS) by(`_BY') ///
				ipdover `eform' `keepall' effect(`effect') lcols(`lcols') rcols(`rcols') `fplotopts'

			if _rc {
				if `"`err'"'==`""' {
					if _rc==1 nois disp as err `"User break in {bf:forestplot}"'
					else nois disp as err `"Error in {bf:forestplot}"'
				}
				exit _rc
			}
			
			return add
			/*
			// we are under -preserve- here, but forestplot.ado may have added some observations;
			// remove these before saving or returning control to ipdmetan.ado
			qui drop if `touse'!=1
			cap assert inrange(`_USE', 0, 6)
			*/
		}
		
		
		** Finally, save dataset
		if `"`saving'"'!=`""' {
			keep  _USE `_BY' `_OVER' _LEVEL _LABELS _ES _seES _LCI _UCI _NN `lcols' `rcols'
			
			// for ipdover, weight is _NN, but need to also store this info in _WT
			qui clonevar _WT = _NN
			order _USE `_BY' `_OVER' _LEVEL _LABELS _ES _seES _LCI _UCI _WT _NN `lcols' `rcols'
			qui save `saving'
		}				

	}	// end if `"`saving'"'!=`""' | `"`graph'"'==`""'
		
end





********************************************

* Program to generate effect size variables
// Based on ProcessInputVarlist and ProcessPoolingVarlist in admetan.ado
// but this version is only for use with raw data in ipdover.ado.

program define GenEffectVars, rclass

	syntax varlist(min=3 max=7 default=none), OUTVLIST(namelist min=5 max=8) ///
		[SUMMSTAT(string) noINTEGER CC(string) CORnfield LOGRank LEVEL(real 95) ZTOL(real 1e-6)]
	
	// unpack varlists
	tokenize `outvlist'
	args _ES _seES _LCI _UCI _NN
	gettoken _USE invlist : varlist
	tokenize `invlist'
	local params : word count `invlist'

	// generate effect size vars
	// Note [Oct 2015]: gen as tempvars for now (to accommodate inverse-variance)
	// but will be renamed to permanent variables later if appropriate

	// 2 or 3 vars inverse-variance, or logrank HR
	// (N.B. summstat may be missing for the former only)
	if `params' <= 3 {

		foreach opt in cc cornfield {
			cap assert `"``opt''"' == `""'
			if _rc {
				nois disp as err `"Note: Option {bf:`opt'} is not appropriate without 2x2 count data and will be ignored"' 
				local switchoff `"`switchoff' `opt'"'
			}
		}

		if "`logrank'"!="" {
			args oe va
			qui replace `_USE' = 2 if `_USE'==1 & sqrt(`va') < `ztol'			// insufficient data (`_USE'==2)
			qui gen double `_ES'   = `oe'/`va'    if inlist(`_USE', 1, 3, 5)	// logHR
			qui gen double `_seES' = 1/sqrt(`va') if inlist(`_USE', 1, 3, 5)	// selogHR
		}
		
		// Identify studies with insufficient data (`_USE'==2)
		else if "`3'"=="" { 	// input is ES + SE
			args _ES _seES
			qui replace `_USE' = 2 if `_USE'==1 & missing(`_ES', `_seES')
			qui replace `_USE' = 2 if `_USE'==1 & 1/`_seES' < `ztol'
		}

		else { 	// input is ES + CI
			args _ES _LCI _UCI
			qui replace `_USE' = 2 if `_USE'==1 & missing(`_LCI', `_UCI')
			qui replace `_USE' = 2 if `_USE'==1 & float(`_LCI')==float(`_UCI')
			cap assert `_UCI'>=`_ES' & `_ES'>=`_LCI' if `_USE'==1
			if _rc {
				nois disp as err "Effect size and/or confidence interval limits invalid;"
				nois disp as err `"order should be {it:effect_size} {it:lower_limit} {it:upper_limit}"'
				exit _rc
			}

			// Need to generate _seES
			qui gen double `_seES' = (`_LCI' - `_UCI') / (2*invnormal(.5 + `level'/200)) if inlist(`_USE', 1, 3, 5)
			qui replace `_USE' = 2 if `_USE'==1 & float(`_seES')==0
		}
		
		qui count if inlist(`_USE', 1, 3, 5) & !missing(`_ES', `_seES')
		if !r(N) exit 2000
	}
	
	// setup for Peto OR method
	else if "`method'"=="peto" {
		assert `params' == 4
		tempvar oe
		local a `e1'
		qui gen double `oe' = `a' - `ea'		// N.B. `ea' was created earlier (as was `va')
		qui gen double `_ES'   = `oe'/`va'    if inlist(`_USE', 1, 3, 5)		// logOR or logHR
		qui gen double `_seES' = 1/sqrt(`va') if inlist(`_USE', 1, 3, 5)		// selogOR or selogHR
	}
	
	// Binary outcome (OR, RR, RD)
	else if `params' == 4 {

		assert inlist("`summstat'", "or", "rr", "irr", "rrr", "rd")
		args e1 f1 e0 f0		// events & non-events in trt; events & non-events in control (a.k.a. a b c d)

		if "`integer'"=="" {
			cap {
				assert int(`e1')==`e1'
				assert int(`f1')==`f1'
				assert int(`e0')==`e0'
				assert int(`f0')==`f0'
			}
			if _rc {
				di as err "Non integer cell counts found" 
				exit _rc
			}
		}
		cap assert `e1'>=0 & `f1'>=0 & `e0'>=0 & `f0'>=0
		if _rc {
			di as err "Non-positive cell counts found" 
			exit _rc
		}

		// Find studies with insufficient data (`_USE'==2)			
		qui replace `_USE' = 2 if `_USE'==1 & missing(`e1', `f1', `e0', `f0')
		if "`summstat'"=="or" qui replace `_USE' = 2 if `_USE'==1 & (`e1' + `e0')*(`f1' + `f0')==0
		if inlist("`summstat'", "rr", "irr", "rrr") | "`method'"=="peto" {
			qui replace `_USE' = 2 if `_USE'==1 & ((`e1'==0 & `e0'==0 ) | (`f1'==0 & `f0'==0))
		}
		qui replace `_USE' = 2 if `_USE'==1 & (`e1' + `f1')*(`e0' + `f0')==0		// applies to all cases
		qui count if inlist(`_USE', 1, 3, 5)
		if !r(N) exit 2000

		if `"`cc'"'!=`""' {
			cap assert `cc'>=0 & `cc'<1
			if _rc {
				nois disp as err "Invalid continuity correction: must be in range [0,1)"
				exit _rc
			}
		}
		if "`cornfield'"!="" {
			if !inlist("`summstat'", "or", "") {
				nois disp as err "Note: {bf:cornfield} is only compatible with odds ratios; option will be ignored"' 
				local switchoff `"`switchoff' cornfield"'
			}
			else if "`summstat'"=="" {
				nois disp as err `"Note: Cornfield-type confidence intervals specified; odds ratios assumed"' 
				local summstat "or"
			}
		}

		if inlist("`method'", "cohen", "glass", "hedges", "nostandard") {
			nois disp as err `"Specified method {bf:`method'} is incompatible with the data"'
			exit 184
		}
		if inlist("`summstat'", "hr", "shr", "tr") {
			nois disp as err "Time-to-event outcome types are incompatible with count data"
			exit 184
		}
		if inlist("`summstat'", "wmd", "smd") {
			nois disp as err "Continuous outcome types are incompatible with count data"
			exit 184
		}
		/*
		if "`summstat'"=="" {
			local summstat rr
			local effect `"Risk Ratio"'
		}
		*/
		assert "`summstat'"!=""	// temp error trap 23rd March 2017
		local method = cond("`method'"=="", "mh", "`method'")		// default pooling method is Mantel-Haenszel
			
		// 27th March 2017
		// tokenize `binvlist'
		// args r1 r0
		tempvar r1 r0
		
		local type = cond("`integer'"=="", "long", "double")
		qui gen `type' `r1'  = `e1' + `f1'		// total in trt arm
		qui gen `type' `r0'  = `e0' + `f0'		// total in control arm
		// qui gen `type' `_NN' = `r1' + `r0'		// overall total

		// zero-cell adjustments
		tempvar zeros
		qui gen byte `zeros' = (`_USE'==1) & (`e1'*`f1'*`e0'*`f0'==0)
		summ `zeros', meanonly
		if r(N) & "`cc'"!="" {
			tempvar e1_cont f1_cont e0_cont f0_cont t_cont
			qui gen double `e1_cont' = cond(`zeros', `e1' + `cc', `e1')
			qui gen double `f1_cont' = cond(`zeros', `f1' + `cc', `f1')
			qui gen double `e0_cont' = cond(`zeros', `e0' + `cc', `e0')
			qui gen double `f0_cont' = cond(`zeros', `f0' + `cc', `f0')
				
			tempvar r1_cont r0_cont t_cont
			qui gen double `r1_cont' = `e1_cont' + `f1_cont'
			qui gen double `r0_cont' = `e0_cont' + `f0_cont'
			qui gen double  `t_cont' = `r1_cont' + `r0_cont'
		}
		else {
			local e1_cont `e1'
			local f1_cont `f1'
			local e0_cont `e0'
			local f0_cont `f0'
			local r1_cont `r1'
			local r0_cont `r0'
			local t_cont `_NN'
		}

		 // now branch by outcome measure
		if "`summstat'" == "or" {
			
			if "`method'"=="peto" {
				local a `e1'
				tempvar c1 c0 ae oe va
				qui gen `type' `c1' = `a' + `c'							// total events
				qui gen `type' `c0' = `b' + `d'							// total non-events
				qui gen double `ea' = (`r1'*`c1')/ `_NN'				// expected events in trt arm
				qui gen double `va' = `r1'*`r0'*`c1'*`c0'/( `_NN'*`_NN'*(`_NN' - 1))
				qui gen double `oe' = `a' - `ea'
				qui gen double `_ES'   = `oe'/`va'    if inlist(`_USE', 1, 3, 5)	// logOR or logHR
				qui gen double `_seES' = 1/sqrt(`va') if inlist(`_USE', 1, 3, 5)	// selogOR or selogHR
			}

			else {
				// calculate individual ORs and variances using cc-adjusted counts
				// (on the linear scale, i.e. logOR)
				qui gen double `_ES'   = ln(`e1_cont'*`f0_cont') - ln(`f1_cont'*`e0_cont')           if inlist(`_USE', 1, 3, 5)
				qui gen double `_seES' = sqrt(1/`e1_cont' + 1/`f1_cont' + 1/`e0_cont' + 1/`f0_cont') if inlist(`_USE', 1, 3, 5)
			}
		} 		/* end OR */
			
		// setup for RR 
		else if "`summstat'" == "rr" {
			tempvar r s v
			qui gen double `r' = `e1_cont'*`r0_cont' / `t_cont'
			qui gen double `s' = `e0_cont'*`r1_cont' / `t_cont'
			qui gen double `v' = 1/`e1_cont' + 1/`e0_cont' - 1/`r1_cont' - 1/`r0_cont'
			qui gen double `_ES'   = ln(`r'/`s') if inlist(`_USE', 1, 3, 5)		// logRR
			qui gen double `_seES' = sqrt(`v')   if inlist(`_USE', 1, 3, 5)		// selogRR
		}
			
		// setup for RD
		else if "`summstat'" == "rd" {
			tempvar v
			qui gen double `v'  = `a_cont'*`b_cont'/(`r1_cont'^3) + `c_cont'*`d_cont'/(`r0_cont'^3)
			qui gen double `_ES'   = `a'/`r1' - `c'/`r0' if inlist(`_USE', 1, 3, 5)
			qui gen double `_seES' = sqrt(`v')           if inlist(`_USE', 1, 3, 5)
		}

	}	/* end if `params' == 4 */

	// N mean SD for continuous data
	else {
		assert `params' == 6
		
		assert inlist("`summstat'", "wmd", "smd")
		args n1 mean1 sd1 n0 mean0 sd0

		// input is form N mean SD for continuous data
		if "`integer'"=="" {
			cap assert int(`n1')==`n1' & int(`n0')==`n0'
			if _rc {
				nois disp as err "Non integer sample sizes found"
				exit _rc
			}
		}
		cap assert `n1'>0 & `n0'>0
		if _rc {
			nois disp as err "Non positive sample sizes found" 
			exit _rc
		}
			
		foreach opt in cc cornfield {
			cap assert `"``opt''"' == `""'
			if _rc {
				nois disp as err `"Option {bf:`opt'} is not appropriate without 2x2 count data and will be ignored"' 
				local switchoff `"`switchoff' `opt'"'
			}
		}
			
		// Find studies with insufficient data (`_USE'==2)
		qui replace `_USE' = 2 if `_USE'==1 & missing(`n1', `mean1', `sd1', `n0', `mean0', `sd0')
		qui replace `_USE' = 2 if `_USE'==1 & `n1' < 2  | `n0' < 2
		qui replace `_USE' = 2 if `_USE'==1 & `sd1'<=0  | `sd0'<=0
		qui count if inlist(`_USE', 1, 3, 5)
		if !r(N) exit 2000
			
		if "`method'"=="nostandard" & "`summstat'"=="smd" {
			nois disp as err `"Cannot specify both SMD and the {bf:nostandard} option"'
			exit 184
		}
		if inlist("`method'", "cohen", "glass", "hedges") & "`summstat'"=="wmd" {
			nois disp as err `"Cannot specify both WMD and the {bf:`mdmethod'} option"'
			exit 184
		}
		if inlist("`method'", "mh", "peto") | "`logrank'"!="" {
			nois disp as err `"Specified method {bf:`method'} is incompatible with the data"'
			exit 184
		}
		cap assert inlist("`summstat'", "", "wmd", "smd")
		if _rc {
			nois disp as err "Invalid specifications for combining trials"
			exit 184
		}

		/*
		if "`summstat'"=="" {
			if "`method'"=="nostandard" {	// "nostandard" is a synonym for "wmd"
				local summstat "wmd"
				local effect `"WMD"'
			}
			else {
				local summstat "smd"			// default is standardized mean differences...
				local effect `"SMD"'
			}		
		}
		*/
		assert "`summstat'"!=""	// temp error trap 23rd March 2017
		local method  = cond(inlist("`method'", "", "iv"), "cohen", "`method'")		//   ...by the method of Cohen
			
		// qui gen long `_NN' = `n1' + `n0' if inlist(`_USE', 1, 2, 3, 5)
				
		if "`summstat'" == "wmd" {
			qui gen double `_ES'   = `mean1' - `mean0'                     if inlist(`_USE', 1, 3, 5)
			qui gen double `_seES' = sqrt((`sd1'^2)/`n1' + (`sd0'^2)/`n0') if inlist(`_USE', 1, 3, 5)
		}
		
		else {				// summstat = SMD
			tempvar s
			qui gen double `s' = sqrt( ((`n1'-1)*(`sd1'^2) + (`n0'-1)*(`sd0'^2) )/( `_NN' - 2) )

			if "`mdmethod'" == "cohen" {
				qui gen double `_ES'   = (`mean1' - `mean0')/`s' if inlist(`_USE', 1, 3, 5)
				qui gen double `_seES' = sqrt((`_NN' /(`n1'*`n0')) + (`_ES'*`_ES'/ (2*(`_NN' - 2)) )) if inlist(`_USE', 1, 3, 5)
			}
			else if "`mdmethod'" == "glass" {
				qui gen double `_ES'   = (`mean1' - `mean0')/`sd0' if inlist(`_USE', 1, 3, 5)
				qui gen double `_seES' = sqrt(( `_NN' /(`n1'*`n0')) + (`_ES'*`_ES'/ (2*(`n0' - 1)) )) if inlist(`_USE', 1, 3, 5)
			}
			else if "`mdmethod'" == "hedges" {
				qui gen double `_ES'   = ((`mean1' - `mean0')*(1 - 3/(4*`_NN' - 9))/`s' if inlist(`_USE', 1, 3, 5)
				qui gen double `_seES' = sqrt(( `_NN' /(`n1'*`n0')) + (`_ES'*`_ES'/ (2*(`_NN' - 3.94)) )) if inlist(`_USE', 1, 3, 5)
			}
			drop `s'
		}
	}	/* end else (i.e. if `params' == 6) */
	
end




*********************************************************************

* Program to generate study-level confidence intervals
// identical subroutine also used in admetan.ado

program define GenConfInts

	syntax varlist(min=2 max=6 default=none) [if] [in], OUTVLIST(namelist min=5 max=5) CItype(string) ///
		[DF(varname numeric) LEVEL(real 95)]	

	marksample touse, novarlist
	
	// unpack varlists
	tokenize `outvlist'
	args _ES _seES _LCI _UCI _NN
	local params : word count `varlist'		// `varlist' == `invlist'

	assert !missing(`_ES', `_seES') if `touse'
	assert missing(`_LCI') if `touse'
	assert missing(`_UCI') if `touse'
	
	
	* Calculate confidence limits for original study estimates using specified `citype'
	// (unless limits supplied by user)
	if "`citype'"=="normal" {			// normal distribution - default
		tempname critval
		scalar `critval' = invnormal(.5 + `level'/200)
		qui replace `_LCI' = `_ES' - `critval'*`_seES' if `touse'
		qui replace `_UCI' = `_ES' + `critval'*`_seES' if `touse'
	}
		
	else if inlist("`citype'", "t", "logit") {		// t distribution (if df available)
		cap confirm `df'
		if !_rc {
			summ `df' if `touse', meanonly
			cap assert r(min) != .
		}
		if _rc {
			nois disp as err `"Degrees of freedom not available; cannot use {bf:`citype'}-based confidence intervals"'
			exit 198
		}
		tempvar critval
		qui gen double `critval' = invttail(`df', .5-`level'/200)
			
		if "`citype'"=="t" {
			qui replace `_LCI' = `_ES' - `critval'*`_seES' if `touse'
			qui replace `_UCI' = `_ES' + `critval'*`_seES' if `touse'
		}
		else {								// logit, proportions only (for formula, see Stata manual for -proportion-)
			summ `_ES' if `touse', meanonly
				if r(min)<0 | r(max)>1 {
				nois disp as err "{bf:citype(logit)} may only be used with proportions"
				exit 198
			}
			qui replace `_LCI' = invlogit(logit(`_ES') - `critval'*`_seES'/(`_ES'*(1 - `_ES'))) if `touse'
			qui replace `_UCI' = invlogit(logit(`_ES') + `critval'*`_seES'/(`_ES'*(1 - `_ES'))) if `touse'
		}
		drop `critval'
	}
		
	else if inlist("`citype'", "cornfield", "exact", "woolf") {		// options to pass to -cci-; summstat==OR only
		tokenize `varlist'
		args a b c d		// events & non-events in trt; events & non-events in control (c.f. -metan- help file)

		// sort appropriately, then find observation number of first relevant obs
		tempvar obs
		qui bys `touse' : gen long `obs' = _n if `touse' & missing(`_LCI', `_UCI')	// N.B. MetaAnalysisLoop uses -sortpreserve-
		sort `obs'																	// so this sorting should not affect the original data
		summ `obs' if `touse', meanonly
		forvalues j = 1/`r(max)' {
			nois cci `=`a'[`j']' `=`b'[`j']' `=`c'[`j']' `=`d'[`j']', `citype'
			qui replace `_LCI' = log(`r(lb_or)') in `j'
			qui replace `_UCI' = log(`r(ub_or)') in `j'
		}
	}

end




*********************************************************************
	
* Routine to draw output table (ipdover.ado version)
* Could be done using "tabdisp", but doing it myself means it can be tailored to the situation
* therefore looks better (I hope!)
// DF Aug 2016:
//  N.B. Code taken directly from latest version of DrawTableAD (as used in admetan.ado), but then modified for use with -ipdover- 
// (e.g. "tests and heterogeneity" subroutine is removed, and other small additions/removals)

program define DrawTableIPD

	syntax, OVERLEN(integer) ///
		[LABLEN(integer 0) STITLE(string asis) ETITLE(string asis) ///
		EFORM noTABLE noOVERALL noSUBGROUP *]

	tempvar obs
	qui gen long `obs'=_n
	sort `obs'

	// EXTRA LINES FOR USE WITH IPDOVER
	cap confirm var _BY
	local _BY = cond(_rc, "", "_BY")
	cap confirm var _NN
	local _NN = cond(_rc, "", "_NN")
	cap confirm var _OVER
	local _OVER = cond(_rc, "", "_OVER")
	
	local swidth = 25							// define `swidth' in case noTAB
	if `"`table'"'==`""' {
	
		// EXTRA LINES FOR USE WITH IPDOVER
		if `overlen'>1 {						// if "over", parse "variable label" options
			forvalues h=1/`overlen' {
				local 0 `", `options'"'
				syntax, VARLAB`h'(string) *
			}
		}
	
		* Find maximum length of study title and effect title
		* Allow them to spread over several lines, but only up to a maximum number of chars
		* If a single line must be more than 32 chars, truncate and stop
		local uselen = 25											// default (minimum); max is 32
		if `lablen'>21 local uselen=min(`lablen', 32)
	
		cap nois SpreadTitle `stitle', target(`uselen') maxwidth(32)		// study (+ subgroup) title
		if _rc {
			if _rc==1 nois disp as err `"User break in {bf:ipdover.SpreadTitle}"'
			nois disp as err `"Error in {bf:ipdover.SpreadTitle}"'
			c_local err "noerr"			// tell ipdover not to also report an "error in {bf:ipdover.DrawTableIPD}"
			exit _rc
		}		

		local swidth = max(`uselen', `r(maxwidth)')
		local slines = r(nlines)
		forvalues i=1/`slines' {
			local stitle`i' `"`r(title`i')'"'
		}

		cap nois SpreadTitle `etitle', target(10) maxwidth(15)		// effect title (i.e. "Odds ratio" etc.)
		if _rc {
			if _rc==1 nois disp as err `"User break in {bf:ipdover.SpreadTitle}"'
			nois disp as err `"Error in {bf:ipdover.SpreadTitle}"'
			c_local err "noerr"			// tell ipdover not to also report an "error in {bf:ipdover.DrawTableIPD}"
			exit _rc
		}		
		
		local ewidth = max(10, `r(maxwidth)')
		local elines = r(nlines)
		local diff = `elines' - `slines'
		if `diff'<=0 {
			forvalues i=1/`slines' {
				local etitle`i' `"`r(title`=`i'+`diff'')'"'		// if stitle uses more (or equal) lines ==> line up etitle with stitle
			}
		}
		else {
			forvalues i=`elines'(-1)1 {					// run backwards, otherwise macros are deleted by the time they're needed
				local etitle`i' `"`r(title`i')'"'
				local stitle`i' = cond(`i'>=`diff', `"`stitle`=`i'-`diff'''"', `""')	// if etitle uses more lines ==> line up stitle with etitle
			}
		}
		
		* Now display the title lines, starting with the "extra" lines and ending with the row including CI & weight
		di as text _n "{hline `swidth'}{c TT}{hline `=`ewidth'+35'}"
		local nl = max(`elines', `slines')
		if `nl' > 1 {
			forvalues i=1/`=`nl'-1' {
				di as text "`stitle`i''{col `=`swidth'+1'}{c |} " %~`ewidth's `"`etitle`i''"'
			}
		}
		di as text "`stitle`nl''{col `=`swidth'+1'}{c |} " %~10s `"`etitle`nl''"' "{col `=`swidth'+`ewidth'+4'}[`c(level)'% Conf. Interval]{col `=`swidth'+`ewidth'+27'}No. pts"


		*** Loop over studies, and subgroups if appropriate
		if `"`_BY'"'!=`""' {
			qui levelsof _BY if _USE!=5, missing local(bylist)		// _USE!=5 since that will always be missing!
			local bylab : value label _BY
		}
		local nby = max(1, `: word count `bylist'')
		
		tempvar touse touse2
		qui gen byte `touse' = 1
		
		tempname _ES_ _LCI_ _UCI_
		local xexp = cond("`eform'"!=`""', `"exp"', `""')
		
		forvalues i=1/`nby' {				// this will be 1/1 if no subgroups

			di as text "{hline `swidth'}{c +}{hline `=`ewidth'+35'}"
			
			if `"`_BY'"'!=`""' {
				local byi : word `i' of `bylist'
				qui replace `touse' = (_BY==`byi')
				summ _ES if `touse' & _USE==1, meanonly
				if !r(N) local nodata "{col `=`swidth'+4'} (No subgroup data)"
				else local K`i' = r(N)
				
				if `"`bylab'"'!=`""' {
					local bylabi : label `bylab' `byi'
				}
				else local bylabi `"`byi'"'
				di as text substr(`"`bylabi'"', 1, `swidth'-1) + "{col `=`swidth'+1'}{c |}`nodata'"
				local nodata	// clear macro
			}
			
			// EXTRA LINES FOR USE WITH IPDOVER
			forvalues h=1/`overlen' {
				gen byte `touse2' = `touse'
				if `"`_OVER'"'!=`""' {
					qui replace `touse2' = `touse' * (_OVER==`h')
				}
				
				summ `obs' if `touse2' & inlist(_USE, 1, 2), meanonly
				
				// EXTRA LINES FOR USE WITH IPDOVER
				if `overlen'>1 {
					di as text "{col `=`swidth'+1'}{c |}"
					if !r(N) local nodata "{col `=`swidth'+4'} (Insufficient data)"
					di as text substr(`"`varlab`h''"', 1, `=`swidth'-1') "{col `=`swidth'+1'}{c |}`nodata'"
					local nodata	// clear macro
				}
				
				if r(N) {
					forvalues k = `r(min)' / `r(max)' {
						summ `obs' if `touse2' & inlist(_USE, 1, 2) & _n==`k', meanonly	// 30th March 2017: can this be improved/made more efficient?
						if !r(N) {
							di as text substr(`"`_labels_'"', 1, 32) "{col `=`swidth'+1'}{c |}{col `=`swidth'+4'} (Insufficient data)"
						}
						else {
							scalar `_ES_'  =  _ES[`k']
							scalar `_LCI_' = _LCI[`k']
							scalar `_UCI_' = _UCI[`k']
							local _labels_ = _LABELS[`k']

							di as text substr(`"`_labels_'"', 1, 32) `"{col `=`swidth'+1'}{c |}{col `=`swidth'+`ewidth'-6'}"' ///
								as res %7.3f `xexp'(`_ES_') `"{col `=`swidth'+`ewidth'+5'}"' ///
								as res %7.3f `xexp'(`_LCI_') `"{col `=`swidth'+`ewidth'+15'}"' ///
								as res %7.3f `xexp'(`_UCI_') `"{col `=`swidth'+`ewidth'+26'}"' %7.0f _NN[`k']
						}
					}
				}
				drop `touse2'

			}		// end forvalues j=1/`overlen'
			
			* Subgroup effects
			if `"`_BY'"'!=`""' & `"`subgroup'"'==`""' {
				di as text "{col `=`swidth'+1'}{c |}"

				local byi: word `i' of `bylist'
				summ `obs' if `touse' & _USE==3, meanonly
				if !r(N) {
					di as text "Effect in subset{col `=`swidth'+1'}{c |}{col `=`swidth'+4'} (Insufficient data)"
				}
				else {		
					scalar `_ES_'  =  _ES[`r(min)']
					scalar `_LCI_' = _LCI[`r(min)']
					scalar `_UCI_' = _UCI[`r(min)']
					
					di as text `"Effect in subset{col `=`swidth'+1'}{c |}{col `=`swidth'+`ewidth'-6'}"' ///
						as res %7.3f `xexp'(`_ES_') `"{col `=`swidth'+`ewidth'+5'}"' ///
						as res %7.3f `xexp'(`_LCI_') `"{col `=`swidth'+`ewidth'+15'}"' ///
						as res %7.3f `xexp'(`_UCI_') `"{col `=`swidth'+`ewidth'+26'}"' %7.0f _NN[`r(min)']
				}
			}
		}		// end forvalues i=1/`nby'
		
		drop `touse'	// tidy up
			

		*** Overall effect
		if `"`overall'"'==`""' {
			di as text "{hline `swidth'}{c +}{hline `=`ewidth'+35'}"
		
			summ `obs' if _USE==5, meanonly
			if !r(N) {
				di as text "Overall effect{col `=`swidth'+1'}{c |}{col `=`swidth'+4'} (Insufficient data)"
			}
			else {
				scalar `_ES_'  =  _ES[`r(min)']
				scalar `_LCI_' = _LCI[`r(min)']
				scalar `_UCI_' = _UCI[`r(min)']
				
				di as text %-20s `"Overall effect{col `=`swidth'+1'}{c |}{col `=`swidth'+`ewidth'-6'}"' ///
					as res %7.3f `xexp'(`_ES_') `"{col `=`swidth'+`ewidth'+5'}"' ///
					as res %7.3f `xexp'(`_LCI_') `"{col `=`swidth'+`ewidth'+15'}"' ///
					as res %7.3f `xexp'(`_UCI_') `"{col `=`swidth'+`ewidth'+26'}"' %7.0f _NN[`r(min)']
			}
		}
		di as text "{hline `swidth'}{c BT}{hline `=`ewidth'+35'}"
	
	}	// end if `"`table'"'==`""'
	
end



* Subroutine to DrawTable: "spreads" titles out over multiple lines if appropriate
// Updated July 2014
// August 2016: identical program now used here, in forestplot.ado, and in admetan.ado 
// May 2017: updated to accept substrings delineated by quotes (c.f. multi-line axis titles)

program define SpreadTitle, rclass

	syntax anything(name=title id="title string"), [TArget(integer 0) MAXWidth(integer 0) MAXLines(integer 0) noTRUNCate ]
	* Target = aim for this width, but allow expansion if alternative is wrapping "too early" (i.e before line is adequately filled)
	//         (may be replaced by `titlelen'/`maxlines' if `maxlines' and `notruncate' are also specified)
	* Maxwidth = absolute maximum width
	* Maxlines = maximum no. lines
	* noTruncate = don't truncate final line if "too long" (even if greater than `maxwidth')
	//             (also allows `maxlines' to adjust `target' upwards if necessary)

	if `"`title'"'==`""' {
		return scalar nlines = 0
		return scalar maxwidth = 0
		exit
	}
	
	if !`target' & !`maxwidth' & !`maxlines' {
		nois disp as err `"must specify at least one of {bf:target()}, {bf:maxwidth()} or {bf:maxlines()}"'
		exit 198
	}
	
	if `maxwidth' & !`maxlines' {
		cap assert `maxwidth'>=`target'
		if _rc {
			nois disp as err `"{bf:maxwidth()} must be greater than or equal to {bf:target()}"'
			exit 198
		}
	}
	
	// Finalise `target' and calculate `spread'
	local titlelen = length(`title')
	
	local target = cond(`target', ///
		cond(`maxlines' & "`truncate'"!="", max(`target', `titlelen'/`maxlines'), `target'), ///
		cond(`maxlines', `titlelen'/`maxlines', cond(`maxwidth', `maxwidth', .)))
	
	if missing(`target') {
		nois disp as err `"must specify at least one of {bf:target()}, {bf:maxwidth()} or {bf:maxlines()}"'
		exit 198
	}	
	
	local spread = cond(`maxlines', `maxlines', int(`titlelen'/`target') + 1)

		
	** If substrings are present, delineated by quotes, treat this as a line-break
	// Hence, need to first process each substring separately and obtain parameters,
	// then select the most appropriate overall parameters given the user-specified options,
	// and finally create the final line-by-line output strings.
	
	local line = 0
	local rest `title'

	while `"`rest'"'!=`""' {
		gettoken title rest : rest, bind qed(qed)
		if !`qed' {
			local title `"`title'`rest'"'
			local rest
		}
		
		local ++line
		local title`line' = word(`"`title'"', 1)
		local newwidth = length(`"`title`line''"')

		local count = 2
		local next = word(`"`title'"', `count')
		
		while `"`next'"' != "" {
			local check = trim(`"`title`line''"' + " " +`"`next'"')			// (potential) next iteration of `title`line''
			if length(`"`check'"') > `titlelen'/`spread' {					// if longer than ideal...
																			// ...and further from target than before, or greater than maxwidth
				if abs(length(`"`check'"')-(`titlelen'/`spread')) > abs(length(`"`title`line''"')-(`titlelen'/`spread')) ///
						| (`maxwidth' & length(`"`check'"') > `maxwidth') {
					if `maxlines' & `line'==`maxlines'  {					// if reached max no. of lines
						local title`line' `"`check'"'						//   - use next iteration anyway (to be truncated)
						continue, break										//   - break loop
					}
					else {													// otherwise:
						local ++line										//  - new line
						local title`line' `"`next'"'						//  - begin new line with next word
					}
				}
				else local title`line' `"`check'"'		// else use next iteration
				
			}
			else local title`line' `"`check'"'		// else use next iteration

			local ++count
			local next = word(`"`title'"', `count')
			local newwidth = max(`newwidth', length(`"`title`line''"'))		// update `newwidth'
		}																	// (N.B. won't be done if reached max no. of lines, as loop broken)
		
		if `maxlines' & `line'==`maxlines' continue, break					// break out of outer loop too
	}		
		

	* If last string is too long (including in above case), truncate
	if `newwidth' > `target' & "`truncate'"=="" {
		local maxwidth = cond(`maxwidth', min(`newwidth', `maxwidth'), `newwidth')
		if length(`"`title`line''"') > `maxwidth' local title`line' = substr(`"`title`line''"', 1, `maxwidth')
	}
	
	* Return strings
	forvalues i=1/`line' {
		return local title`i' = trim(`"`title`i''"')
	}
	return scalar nlines = `line'
	return scalar maxwidth = min(`newwidth', `maxwidth')
	
end	
	
	
