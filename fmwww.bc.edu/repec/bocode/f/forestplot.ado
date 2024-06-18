* Program to generate forestplots -- used by ipdmetan etc. but can also be run by itself
* April 2013
*   Forked from main ipdmetan code
* September 2013
*   Following UK Stata Users Meeting, reworked the plotid() option as recommended by Vince Wiggins

* version 1.0  David Fisher  31jan2014

* version 1.01  David Fisher  07feb2014
* Reason: fixed bug - random-effects note being overlaid on x-axis labels

* version 1.02  David Fisher  20feb2014
* Reason: allow user to affect null line options

* version 1.03  David Fisher  23jul2014
* Reason: implented a couple of suggestions from Phil Jones
* Weighting is now consistent across plotid groups
* Tidying up some code that unnecessarily restricted where user-defined lcols/rcols could be plotted
* Minor bug fixes and code simplification
* New (improved?) textsize and aspect ratio algorithm

* version 1.04  David Fisher 29jun2015
// Reason: Major update to coincide with publication of Stata Journal article

* Aug 2014: fixed issue with _labels
* updated SpreadTitle to accept null strings
* added 'noBOX' option

* Oct 2014: added "newwt" option to "dataid" to reset weights

* Jan 2015: re-written leftWD/rightWD sections to use variable formats and manually-calculated indents
* rather than using char(160), since this isn't necessarily mapped to "non-breaking space" on all machines

* May 2015: Fixed issue with "clipping" long column headings
* May 2015: Option to save parameters (aspect ratio, text size, positioning of text columns relative to x-axis tickmarks)
* in a matrix, to be used by a subsequent -forestplot- call to maintain consistency

* October 2015: Minor fixes to agree with new ipdmetan/admetan versions

* July 2016: added rfdist

* 30th Sep 2016: added "range(min max)" option so that range = min(_LCI) to max(_UCI)

* Coding of _USE:
* _USE == 0  subgroup labels (headings)
* _USE == 1  successfully estimated trial-level effects
* _USE == 2  unsuccessfully estimated trial-level effects ("Insufficient data")
* _USE == 3  subgroup effects
* _USE == 4  between-subgroup heterogeneity info and/or `hetinfo' placed on new line 
* _USE == 5  overall effect
* _USE == 6  blank lines (text/data in such rows will be ignored in the plot)
* _USE == 7  prediction interval data
* _USE == 9  titles (internal only)

* version 2.0  David Fisher  11may2017
// Not updated nearly as much as -admetan-, -ipdmetan- and -ipdover-
// but up-versioned to match

* version 2.1  David Fisher  14sep2017
// various bug fixes
// improvements to range() and cirange()
// improvements to rfopts

// - N.B. cannot override "interaction" option with pointopts(msymbol(square)) -- is this a bug or a feature?
// for next version:  include addplot() option ?

* version 3.0  David Fisher  08nov2018

* version 3.1  David Fisher  03dec2018
// only implement lalign() if c(stata_version)>=15
// corrected order of `graphopts' and `fpuseopts' so that -useopts- works as intended
// -forestplot- now consistently honours blank varlabels in lcols/rcols (whether string or numeric)

* version 3.2  David Fisher  28jan2019
// corrected error which caused first help-file example to fail
// some text in help file is updated
// improved counting of rows in titles containing compound quotes

* version 4.00  David Fisher  25nov2020
// changes to `xlabopts'
// changes to `influence' plot (including "hide" option)
// changes to fp() option
// -double- option added back in; "height" etc. now calculated using values of `id' rather than by counting observations
// minor change to ProcessColumns to ensure "95% CI" (in _EFFECT varlabel) is not broken across lines
// upversioned to match with -metan-

* version 4.01  David Fisher  12feb2021
// minor change to behaviour of -extraline()- and -lcolscheck-
// fixed bug in -favours()- which sometimes caused quotes to appear in plot
// improvements to code so that earlier versions of Stata do not truncate plot macros
//  (thanks to Daniel Klein for assistance with testing of earlier versions)

* version 4.02  David Fisher  23feb2021
// No changes to -forestplot- code; upversioned to match with -metan-

* version 4.03  David Fisher  28apr2021
// fixed automated choice of x-axis with proportions with denominator(#)
// now catches extreme cases where `DXmin' or `DXmax' are missing
// only implement lalign() if 15.1+ , following user reports that fails with 15.0
// corrected bug which failed to show diamonds correctly if off-scale

* version 4.04  David Fisher  16aug2021
// added prefix() option

* version 4.05  David Fisher  29nov2021
// fixed bug preventing plotid() and dataid() being specified together
// added ability to modify "border line" between the data and the column headings
// new option "nooverlay" in two new places:
//  - for drawing weighted boxes on top of conf. ints. (instead of default = overlaying CIs on top of boxes)
//  - for drawing data (boxes, CIs etc.) on top of null and/or overall line(s)

* version 4.06  David Fisher  12oct2022
// new option "sepline" for drawing prediction interval lines separately (below) confidence interval lines instead of straddling them

* version 4.07  David Fisher  15sep2023
// no changes; upversioned to v4.07 alongside metan.ado

*! version 4.08  David Fisher  17jun2024
// Q heterogeneity p-value now shows in forestplot as "< 0.001" rather than "= 0.000"
// right-alignment of columns in -forestplot- now done via mlabpos() rather than explicit indentation
// works with metan v4.07+ : new value _USE==7 defining prediction intervals
// fixed bug whereby matname `usedims' might be misinterpreted by Stata as a varname, leading to error
// fixed bug whereby untransformed proportions led to forestplot expecting _Prop_ES etc. rather than _ES, leading to error
// improvements to ocilineopts() and rfcilineopts()
// text printed to screen no longer includes "use() labels() wgt() by()" if these options are empty
// `colsonly' option moved out of beta and fully documented


program define forestplot, sortpreserve rclass

	version 11.0		// needs v11 for SMCL in graphs

	// June 2018 [updated Oct 2018]: check for "useopts", which recreates previous -metan- (or ipdmetan/ipdover) call
	syntax [varlist(numeric max=5 default=none)] [if] [in] [, USEOPTs * ]
	local graphopts `"`options'"'

	local usevlist `varlist'
	local useifin  `if' `in'

	if `"`useopts'"'!=`""' {
		local orig_gropts : copy local graphopts
	
		local fpusevlist : char _dta[FPUseVarlist]
		local fpuseifin : char _dta[FPUseIfIn]
		local fpuseopts : char _dta[FPUseOpts]

		if `"`fpusevlist'`fpuseifin'`fpuseopts'"'==`""' {
			nois disp as err `"No stored {bf:forestplot} options found"'
			exit 198
		}
	
		// varlist and if/in:  if supplied directly, overwrite characteristics
		if `"`usevlist'"'==`""' local usevlist `fpusevlist'
		if `"`useifin'"'==`""'  local useifin  `fpuseifin'

		local fpcmdline = trim(itrim(`"forestplot `usevlist' `if' `in', `fpuseopts' `graphopts'"'))
		nois disp as text `"Full command line as defined by {bf:useopts} is as follows:"'
		nois disp as res `"  `fpcmdline'"'
		nois disp as text `"(Note: any or all of this information may be over-ridden by other options;"'
		nois disp as text `" in general only the rightmost of any repeated options will be honoured, but see {help repeated_options})"'
	}

	// Nov 2018: note that -syntax- is *leftmost*, not rightmost; so `graphopts' must come first to overrule `fpuseopts'
	local 0 `"`usevlist' `useifin', `graphopts' `fpuseopts'"'
	
	// June 2018: main parse
	syntax [varlist(numeric max=5 default=none)] [if] [in] [, WGT(varname numeric) USE(varname numeric) PREfix(name local) ///
		///
		/// /* General user-specified -forestplot- options */
		BY(varname) EFORM EFFect(string asis) LABels(varname string) DP(integer 2) KEEPAll USESTRICT /*(undocumented)*/ ///
		INTERaction LCols(namelist) RCols(namelist) LEFTJustify COLSONLY RFDIST(varlist numeric min=2 max=2) RFLevel(passthru) ///
		NULLOFF noNAmes noNULL NULL2(string) noKEEPVars noOVerall noSUbgroup noSTATs noWT noHET LEVEL(passthru) ILevel(passthru) OLevel(passthru) ///
		XTItle(passthru) /*FAVours(passthru)*/ /// /* N.B. -xtitle- is parsed here so that a blank title can be inserted if necessary */
		CUmulative INFluence /*PRoportion*/ DENOMinator(passthru) /// /* undocumented; passed through from -metan-; needed in order to implement "hide" option... */
		/// /* ...and to control default null line/x-axis (e.g. for proportion/influence)
		/// /* Sub-plot identifier for applying different appearance options, and dataset identifier to separate plots */
		PLOTID(string) DATAID(string) ///
		///
		TEXTSize(passthru) /// /* legacy -metan9- option, implemented here as a post-hoc option; use at own risk */
		/// /* "fine-tuning" options */
		SAVEDIms(name) USEDIms(name) ASText(real -9) noADJust ///
		noPREFIXWARN ///	/*(undocumented; suppress "using default varlist" message if passing directly from -metan- using prefix()*/
		KEEPXLabs * ]		/*(undocumented; colsonly option)*/

	local graphopts `"`options'"'			// "graph region" options (also includes plotopts for now)		
	marksample touse, novarlist				// do this immediately, so that -syntax- can be used again
	
	
	** N.B. Parts of this early setup may repeat work already done by calling program (e.g. -metan- )
	//  but hopefully the extra overhead is negligible

	// Set up variable names
	if `"`varlist'"'!=`""' {
		tokenize `varlist'
		if `"`4'"'!=`""' {
			nois disp as err `"Syntax has changed as of ipdmetan v2.0 09may2017"'
			nois disp as err `"{bf:_WT} and {bf:_USE} should now be specified using options {bf:wgt()} and {bf:use()}"'
			exit 198
		}
		if `"`2'"'==`""' | `"`3'"'==`""' {
			nois disp as err `"{it:varlist} detected but with too few members; syntax is {it:es lci uci}"'
			exit 198
		}		
	}
	else {		// if not specified, assume "standard" varnames
		if `"`denominator'"'==`""' {
			local varlist `prefix'_ES `prefix'_LCI `prefix'_UCI
			if `"`prefixwarn'"'==`""' nois disp as text `"Note: no {it:varlist} specified; using default {it:varlist}"' as res `" {bf:`varlist'}"'
		}
		else {
			local varlist `prefix'_Prop_ES `prefix'_Prop_LCI `prefix'_Prop_UCI		// August 2023
			if `"`prefixwarn'"'==`""' {
				nois disp as text `"Note: no {it:varlist} specified; using default {it:varlist}"' as res `" {bf:`varlist'}"'
				nois disp as text `" due to option {bf:denominator(}{it:#}{bf:)} being specified"'
			}
			foreach x in Prop_ES Prop_LCI Prop_UCI {
				cap confirm var `prefix'_`x'
				if _rc {
					if `"`prefixwarn'"'==`""' {
						nois disp as text `"Note: expected to find variable "' as res `"{bf:`prefix'_`x'}"' as text `", but failed;"'
						nois disp as text `"assuming proportions pooled on untransformed scale using variables "' as res `"{bf:`prefix'_ES}, {bf:`prefix'_LCI}, {bf:`prefix'_UCI}"'
					}
					local varlist `prefix'_ES `prefix'_LCI `prefix'_UCI				// March 2024
					continue, break
				}
			}
		}
		tokenize `varlist'
	}
	args _ES _LCI _UCI
	foreach x in _ES _LCI _UCI {
		confirm numeric var ``x''
	}

	// Set up data sample to use
	local _USE `use'
	if `"`use'"'==`""' {
		cap confirm numeric var `prefix'_USE
		if !_rc {
			if `"`prefixwarn'"'==`""' {
				nois disp as text `"Note: option {bf:use(}{it:varname}{bf:)} not specified; using default {it:varname}"' as res `" {bf:`prefix'_USE}"'
			}
			local _USE `prefix'_USE
		}
		else {
			if _rc!=7 {			// if _USE does not exist
				tempvar _USE
				qui gen byte `_USE' = cond(missing(`_ES', `_LCI', `_UCI'), 2, 1)
				nois disp as text `"Note: default variable"' as res `" {bf:`prefix'_USE} "' as text `"not found; all included observations will be assumed to contain study estimates"'
			}
			else {
				nois disp as err `"Default variable {bf:`prefix'_USE} exists but is not numeric"'
				exit 198
			}
		}
	}
	confirm numeric variable `_USE'
	markout `touse' `_USE'		// observations for which _USE is missing

	qui replace `touse' = 0 if inlist(`_USE', 3, 4) & `"`subgroup'"'!=`""'
	qui replace `touse' = 0 if `_USE' == 4 & `"`het'"'!=`""'
	qui replace `touse' = 0 if `_USE' == 5 & `"`overall'"'!=`""'	
	// qui replace `touse' = 0 if inlist(`_USE', 3, 5) & missing(`_ES') & `"`stats'"'!=`""' & `"`rfdist'"'!=`""'
	qui replace `touse' = 0 if `_USE' == 7 & `"`stats'"'!=`""' & `"`rfdist'"'!=`""'
	
	if `"`keepall'"'==`""' qui replace `touse' = 0 if `_USE'==2		// "keepall" option (see -metan-)
	qui count if `touse'
	if !r(N) {
		nois disp as err "no observations"
		exit 2000
	}
	// return scalar obs = r(N)
	// Jan 2020: do this later, after BuildPlotCmds, in case of "hidden" pooled observations

	// Check that UCI is greater than LCI
	cap assert `_UCI' > `_LCI' if `touse' & !missing(`_UCI') & !(float(`_LCI')==float(`_ES') & float(`_ES')==float(`_UCI'))
	if _rc {
		nois disp as err "Error in confidence interval data; please check the following observations:"
		nois list `_USE' `_LCI' `_UCI' if `touse' & !missing(`_UCI') & !(`_UCI' > `_LCI') & !(float(`_LCI')==float(`_ES') & float(`_ES')==float(`_UCI'))
		exit 198
	}		

	// Weighting variable
	local _WT `wgt'
	if `"`wgt'"'==`""' {
		cap confirm numeric var `prefix'_WT
		if !_rc {
			if `"`prefixwarn'"'==`""' {
				nois disp as text `"Note: option {bf:wgt(}{it:varname}{bf:)} not specified; using default {it:varname}"' as res `" {bf:`prefix'_WT}"'
			}
			local _WT `prefix'_WT
		}
		else {
			if _rc!=7 {			// if _WT does not exist
				tempvar _WT
				qui gen byte `_WT' = 1 if `touse' & inlist(`_USE', 1, 3, 5)		// generate as constant if doesn't exist
				nois disp as text `"Note: default variable"' as res `" {bf:`prefix'_WT} "' as text `"not found; all observations will have equal weights"'
				local wt nowt						// don't display as text column
			}
			else {
				nois disp as err `"Default variable {bf:`prefix'_WT} exists but is not numeric"'
				exit 198
			}
		}
	}
	confirm numeric variable `_WT'

	// Check existence of `labels' (string) and `by' (should really be numeric but doesn't actually matter)
	foreach x in labels by {
		local X = upper("`x'")
		if `"``x''"'!=`""' local _`X' ``x''
		else {
			cap confirm var `prefix'_`X'
			if !_rc {
				local _`X' `prefix'_`X'		// use default varnames if they exist and option not explicitly given
				if "`x'"=="labels" {		// don't print message r.e. `by' as it is only used in a minor way by -forestplot-
					if `"`prefixwarn'"'==`""' {
						nois disp as text `"Note: option {bf:labels(}{it:varname}{bf:)} not specified; using default {it:varname}"' as res `" {bf:`prefix'_LABELS}"'
					}
				}
			}
			
			// Jan 2019
			else if "`x'"=="labels" {
				nois disp as text `"Note: option {bf:labels(}{it:varname}{bf:)} not specified and default {it:varname} {bf:`prefix'_LABELS} not found; observations will be unlabelled"'
				local names nonames
			}
		}
	}
	if `"`_LABELS'"'!=`""' {
		confirm string var `_LABELS'
	}
	if `"`_BY'"'!=`""' {
		confirm var `_BY'
	}

	// Check validity of `_USE' (already sorted out existence)
	//  if `usestrict'; otherwise responsibility is with user
	if `"`usestrict'"'!=`""' {
		tempvar flag
		qui gen byte `flag' =      `touse' & `_USE'==1 &  missing(`_ES', `_LCI', `_UCI', `_WT')
		qui replace  `flag' = 1 if `touse' & `_USE'==2 & !missing(`_ES', `_LCI', `_UCI')
		if `"`names'"'==`""' {		// Jan 2019
			qui replace  `flag' = 1 if `touse' & `_USE'==6 & !missing(`_LABELS')
		}
		qui replace  `flag' = 1 if `touse' & inlist(`_USE', 2, 6) & !missing(`_WT') & `"`wt'"'==`""'
		qui replace  `flag' = 1 if `touse' & `_USE' > 6 & !missing(`_USE')
		qui count if `flag'
		if r(N) {
			nois disp as err `"The following observations are inconsistent with {bf:_USE}:"'
			nois list `_USE' `_LABELS' `_ES' `_LCI' `_UCI' `_WT' if `flag'
			exit 198
		}
		qui drop `flag'
	}
	
	
	// Sort out `dataid' and `plotid'
	tempvar obs touse2
	qui gen long `obs' = _n

	// local nd=1
	local 0 `dataid'
	syntax [varname(default=none)] [, NEWwt]
	if `"`varlist'"'!=`""' {
		cap tab `varlist' if `touse', m
		if _rc {
			nois disp as err `"error in option {bf:dataid()}"'
			qui tab `varlist' if `touse', m
		}

		if `"`newwt'"'==`""' local dataid `varlist'
		else {
			qui gen byte `touse2' = `touse' * inlist(`_USE', 1, 2, 3, 5, 7)
			
			local dataid
			tempvar dtobs dataid					// create ordinal version of dataid
			qui bysort `touse2' `varlist' (`obs') : gen long `dtobs' = `obs'[1] if `touse2'
			qui bysort `touse2' `dtobs' : gen long `dataid' = (_n==1) if `touse2'
			qui replace `dataid' = sum(`dataid') if `touse2'
			label variable `dataid' "dataid"
		}
	}
	
	if `"`plotid'"'==`""' {
		tempvar plotid
		qui gen byte `plotid' = 1 if `touse'	// create plotid as constant if not specified; this makes BuildPlotCmds much easier
	}
	else {
		disp _n _c								// spacing, in case following on from ipdmetan (etc.)
		cap confirm var `prefix'_OVER
		local _OVER = cond(_rc, `""', `"`prefix'_OVER"')
		
		local 0 `plotid'
		syntax name(name=plname id="plotid") [, List noGRaph]
		local plotid		// clear macro; will want to define a tempvar named plotid

		if "`plname'"!="_n" {
			confirm var `plname'
			cap tab `plname' if `touse', m
			if _rc {
				nois disp as err `"error in option {bf:plotid()}"'
				qui tab `plname' if `touse', m
			}
			if `"`_OVER'"'==`""' {
				qui count if `touse' & inlist(`_USE', 1, 2) & missing(`plname')
				if r(N) {
					nois disp as err `"Warning: variable {bf:`plname'} (in option {bf:plotid()}) contains missing values"'
					nois disp as err `"{bf:plotid()} groups and/or allocated numeric codes may not be as expected"'
					if "`list'"=="" nois disp as err `"This may be checked using the {bf:list} suboption to {bf:plotid()}"'
				}
			}
		}
		
		* Create ordinal version of plotid...
		// tempvar touse2
		cap confirm variable `touse2'
		if _rc {
			qui gen byte `touse2' = `touse' * inlist(`_USE', 1, 2, 3, 5, 7)
		}
		// local plvar `plname'

		// ...extra tweaking if passed through from (ad)metan/ipdmetan/ipdover (i.e. _STUDY, and possibly _OVER, exists)
		if inlist("`plname'", "_STUDY", "_n", "_LEVEL", "_OVER") {
			cap confirm var `prefix'_STUDY
			local _STUDY = cond(_rc, `"`prefix'_LEVEL"', `"`prefix'_STUDY"')
			tempvar smiss
			qui gen byte `smiss' = missing(`_STUDY')
			
			if inlist("`plname'", "_STUDY", "_n") {
				tempvar plvar
				qui bysort `touse2' `smiss' (`_OVER' `_STUDY') : gen long `plvar' = _n if `touse2' & !`smiss'
			}
			else if "`plname'"=="_LEVEL" {
				tempvar plvar
				qui bysort `touse2' `smiss' `_BY' (`_OVER' `_STUDY') : gen long `plvar' = _n if `touse2' & !`smiss'
			}
			else local plvar `prefix'_OVER
		}
		else local plvar `plname'
		
		tempvar plobs plotid
		qui bysort `touse2' `smiss' `plvar' (`obs') : gen long `plobs' = `obs'[1] if `touse2'
		qui bysort `touse2' `smiss' `plobs' : gen long `plotid' = (_n==1) if `touse2'
		qui replace `plotid' = sum(`plotid') if `touse2'
		local np = `plotid'[_N]					// number of `plotid' levels (N.B. `plotid' is guaranteed to be ordinal)
		label variable `plotid' "plotid"
		
		* Optionally list observations contained within each plotid group
		if "`list'" != "" {
			sort `obs'
			nois disp as text _n "plotid: observations marked by " as res "`plname'" as text ":"
			forvalues p=1/`np' {
				nois disp as text _n "-> plotid = " as res `p' as text ":"
				nois list `dataid' `_USE' `_BY' `_OVER' `_LABELS' if `touse2' & `plotid'==`p', table noobs sep(0)
			}
			if `"`graph'"'!=`""' exit
		}
		qui drop `touse2' `plobs' `smiss'
	}
	// qui drop `obs'	// don't drop yet; use again later
	
	// Parse eform option and finalise "effect" text
	cap nois CheckOpts, soptions opts(`eform' `graphopts')
	if _rc {
		if _rc==1 nois disp as err "User break"
		else nois disp as err `"Error in {bf:forestplot.CheckOpts}"'
		c_local err noerr		// tell calling subroutine not to also report an error
		exit _rc
	}
	local eform `"`s(eform)'"'			// either "eform" or nothing
	local graphopts `"`s(options)'"'

	if `"`effect'"'==`""' {
		// amended Feb 2018 due to local x = "" issue with version <13
		// local effect = cond(`"`r(effect)'"'=="", "Effect", `"`r(effect)'"')
		local effect `"`s(effect)'"'
		if `"`effect'"'==`""'      local effect "Effect"
		if `"`interaction'"'!=`""' local effect `"Interact. `effect'"'
	}

	// May 2020: significance levels
	// If a -metan- results set is used, specifying level() is unnecessary
	//  as the relevant values will be taken from variable characteristics
	// But levels can be specified manually if necessary.
	if `"`level'"'!=`""' {
		if `"`ilevel'"'!=`""' {
			nois disp as err "Cannot specify both {bf:level()} and {bf:ilevel()}"
			exit 184
		}
		if `"`olevel'"'!=`""' {
			nois disp as err "Cannot specify both {bf:level()} and {bf:olevel()}"
			exit 184			
		}
		local ilevel : copy local level
		local olevel : copy local level
		local level
	}	
	local 0 `", `olevel'"'
	syntax [, OLevel(cilevel) ]
	
	* Default placing of labels, effect sizes and weights:
	// unless noSTATS and/or noWT, effect sizes and weights are first two elements of `rcols'
	if `"`eform'"'!=`""' local xexp exp
	if `"`stats'"'==`""' {
	
		// determine format
		summ `_UCI' if `touse', meanonly
		local fmtx = max(1, ceil(log10(abs(`xexp'(r(max)))))) + 1 + `dp'
	
		if `"`keepvars'"'!=`""' tempvar _EFFECT
		else {
			cap drop `prefix'_EFFECT
			local _EFFECT `prefix'_EFFECT
		}
		qui gen str `_EFFECT' = string(`xexp'(`_ES'), `"%`fmtx'.`dp'f"') if !missing(`_ES')
		qui replace `_EFFECT' = `_EFFECT' + " " if !missing(`_EFFECT')
		qui replace `_EFFECT' = `_EFFECT' + "(" + string(`xexp'(`_LCI'), `"%`fmtx'.`dp'f"') + ", " + string(`xexp'(`_UCI'), `"%`fmtx'.`dp'f"') + ")"
		qui replace `_EFFECT' = `""' if !(`touse' & inlist(`_USE', 1, 3, 5, 7))
		qui replace `_EFFECT' = "(Insufficient data)" if `touse' & `_USE'==2
		
		// March 2020:  extra lines to handle "empty" subgroups, and single-study subgroups with `influence'
		qui replace `_EFFECT' = "(Insufficient data)" if `touse' & inlist(`_USE', 3, 5) & missing(`_LCI')
		qui replace `_EFFECT' = "(Insufficient data)" if `touse' & `_USE'==1 & missing(`_LCI') & `"`influence'"'!=`""'

		local f = abs(fmtwidth("`: format `_EFFECT''"))
		format `_EFFECT' %-`f's		// left-justify
		
		// variable label
		if `"`effect'"' == `""' {
			local effect = cond("`interaction'"!="", "Interaction effect", "Effect")
		}
		if `"`ilevel'"'==`""' {
			local lciLevel : char `_LCI'[Level]
			local uciLevel : char `_UCI'[Level]
			if `"`lciLevel'"'!=`""' & `"`uciLevel'"'!=`""' & `"`lciLevel'"'!=`"`uciLevel'"' {
				nois disp as err "Conflicting confidence limit coverages"
				exit 198
			}
			local ilevel `lciLevel'
			if `"`ilevel'"'==`""' local ilevel `uciLevel'
		}
		if `"`ilevel'"'==`""' {		// if `ilevel' manually specified, use it in preference to the value stored in the variable characteristics
			local 0 `", `ilevel'"'
			syntax [, ILevel(cilevel) ]
		}
		label variable `_EFFECT' `"`effect' (`ilevel'% CI)"'
	}
	if `"`names'"'==`""' local lcols `_LABELS' `lcols'		// unless noNAMES specified, add `_LABELS' to `lcols'
	if "`wt'" == "" local rcols `_WT' `rcols'				// unless noWT specified, add `_WT' to `rcols'
	local rcols `_EFFECT' `rcols'							// unless noSTATS specified, add `_EFFECT' to `rcols'			

	// finalise lcols and rcols
	foreach x of local lcols {
		cap confirm var `x' 
		if _rc {
			nois disp as err `"variable {bf:`x'} not found in option {bf:lcols()}"'
			exit _rc
		}
	}
	foreach x of local rcols {
		cap confirm var `x' 
		if _rc {
			nois disp as err `"variable {bf:`x'} not found in option {bf:rcols()}"'
			exit _rc
		}
	}
	local lcolsN : word count `lcols'
	local rcolsN : word count `rcols'

	// [Revised May 2024 for v4.08]
	// `colsonly' option expects exactly one of `lcolsN' or `rcolsN' to be nonzero
	if `"`colsonly'"'!=`""' {
		if !`lcolsN' & !`rcolsN' {
			disp as err `"Option {bf:colsonly} supplied with no columns of data; nothing to plot"'
			exit 2000
		}
		else if `lcolsN' & `rcolsN' {
			disp as err `"Option {bf:colsonly} requires either left-side or right-side data columns, but not both"'
			exit 198
		}
	}
	// Check that `keepxlabs' implies `colsonly';  so that later we may use `keepxlabs' in place of `colsonly' where appropriate
	else if `"`keepxlabs'"'!=`""' {
		disp as err `"Option {bf:keepxlabs} cannot be specified without {bf:colsonly}"'
		exit 198
	}
	
	
	** GET MIN AND MAX DISPLAY
	// [comments from _dispgby subroutine of metan.ado follow]
	// SORT OUT TICKS- CODE PINCHED FROM MIKE AND FIDDLED. TURNS OUT I'VE BEEN USING SIMILAR NAMES...
	// AS SUGGESTED BY JS JUST ACCEPT ANYTHING AS TICKS AND RESPONSIBILITY IS TO USER!
	
	// N.B. `DXmin', `DXmax' are the left and right co-ords of the graph part
	// These are NOT NECESSARILY the same as the limits of xlabels, xticks etc.
	// In particular, if range() is specified then DXmin, DXmax == range;  regardless of xlabels, xticks etc.
	
	// First, sort out null-line
	local h0 = 0							// default
	
	// if `"`null2'"'!=`""' local nullopt `"null(`null2')"'	
	// Amended Jan 2020
	if inlist(trim("`null2'"), "none", "off") local nullopt `"null(`null2')"'
	opts_exclusive `"`nulloff' `null' `nullopt'"'

	if `"`nulloff'"'!=`""' local null nonull
	// "nulloff" and "nonull" are permitted alternatives to null(none|off),
	//  for compatibility with previous versions of -metan-
	
	else if `"`null2'"'!=`""' {
		if inlist("`null2'", "none", "off") local null nonull
		else {
			cap nois numlist "`null2'", min(1) max(1)
			if _rc {
				disp as err "error in {bf:null()} option"
				exit _rc
			}
			// local h0 = `null2'
			// May 2020: null2() should be given on same scale as xlabels, to match with fp()
			local h0 = cond(`"`eform'"'!=`""', ln(`null2'), `null2')
			
			if "`null'"!="nonull" local null
		}
	}
	if `"`influence'`denominator'"'!=`""' & inlist(trim("`null2'"), "", "none", "off") local null nonull
	// N.B. `null' now either contains nothing, or "nonull"
	//  and `h0' contains a number (defaulting to 0), denoting where the null-line will be placed if "`null'"==""
	// If `influence' or proportion (i.e. `denominator'), "nonull" is the default unless null2(#) is supplied.
	
	// Now find DXmin, DXmax; xticklist, xlablist, xlablim1
	summ `_LCI' if `touse', meanonly
	local DXmin = r(min)				// minimum confidence limit
	summ `_UCI' if `touse', meanonly
	local DXmax = r(max)				// maximum confidence limit

	if `"`rfdist'"'!=`""' {
		tokenize `rfdist'
		args _rfLCI _rfUCI

		if `"`rflevel'"'==`""' {
			local lciRFLevel : char `_rfLCI'[RFLevel]
			local uciRFLevel : char `_rfUCI'[RFLevel]
			if `"`lciRFLevel'"'!=`""' & `"`uciRFLevel'"'!=`""' & `"`lciRFLevel'"'!=`"`uciRFLevel'"' {
				nois disp as err "Conflicting confidence limit coverages for predictive interval"
				exit 198
			}
			local rflevel `lciRFLevel'
			if `"`rflevel'"'==`""' local rflevel `uciRFLevel'
		}
		if `"`rflevel'"'==`""' {		// if `rflevel' manually specified, use it in preference to the value stored in the variable characteristics
			local 0 `", `rflevel'"'
			syntax [, RFLevel(cilevel) ]
		}
		
		// Note, May 2020: if `rflevel' < `olevel' and low heterogeneity, then (rfLCI, rfUCI) might be tighter than (LCI, UCI)
		cap {
			assert missing(`_rfLCI', `_rfUCI') if `touse' & !inlist(`_USE', 3, 5, 4, 7)
			assert float(`_rfLCI') <= float(`_LCI') if `touse' & !missing(`_rfLCI', `_LCI') & float(`rflevel')>=float(`olevel')
			assert float(`_rfUCI') >= float(`_UCI') if `touse' & !missing(`_rfUCI', `_UCI') & float(`rflevel')>=float(`olevel')
		}
		if _rc {
			nois disp as err "Error in predictive interval data"
			exit 198
		}
	
		summ `_rfLCI' if `touse', meanonly		// N.B. unnecessary if passed thru from -metan-, since included in `_LCI'/`_UCI'
		local DXmin = min(`DXmin', r(min))		//  but need to do it anyway 
		summ `_rfUCI' if `touse', meanonly
		local DXmax = max(`DXmax', r(max))
		
		if `"`stats'"'==`""' {
			// Generate `rfdindent' to send to -ProcessColumns-
			// strwid is width of "_ES[_n-1]" as formatted by "%`fmtx'.`dp'f" so it lines up
			tempvar rfindent
			qui gen `rfindent' = string(`xexp'(`_ES'[_n-1]), `"%`fmtx'.`dp'f"') if `touse' & `_USE'==7
			/*
			qui gen `rfindent' = cond(`touse' * missing(`_ES') * !missing(`_rfLCI', `_rfUCI'), ///
				string(`xexp'(`_ES'[_n-1]), `"%`fmtx'.`dp'f"'), `""')
			*/
			
			// Find which column effect sizes (including predictive distribution limits) should appear in, to apply rfindent
			local rfcol=1
			while `"`: word `rfcol' of `rcols''"'!=`"_EFFECT"' & `rfcol' <= `rcolsN' {
				local ++rfcol
			}
			
			local rfcolopts `"rfindent(`rfindent') rfcol(`rfcol')"'
		}
		else {
			disp as err "Note: options {bf:rfdist} and {bf:nostats} specified together;"
			disp as err " predictive intervals will be presented graphically but will not appear in text columns"
		}
	}
	
	// March 2021: handle extreme case
	if missing(`DXmin') | missing(`DXmax') {
		summ `_ES' if `touse', meanonly
		if r(N) {
			if missing(`DXmin') local DXmin = r(min)
			if missing(`DXmax') local DXmax = r(max)
		}
		else {
			if missing(`DXmin') local DXmin = `h0'
			if missing(`DXmax') local DXmax = `h0'
		}
	}	
	
	cap nois ProcessXAxis `DXmin' `DXmax', `eform' h0(`h0') `null' `denominator' `colsonly' `graphopts'
	if _rc {
		if _rc==1 nois disp as err `"User break in {bf:forestplot.ProcessXAxis}"'
		nois disp as err `"Error in {bf:forestplot.ProcessXAxis}"'
		c_local err noerr		// tell calling program (e.g. -metan- ) not to also report an error
		exit _rc
	}
	if "`twowaynote'"!="" c_local twowaynote notwowaynote	// so that -metan- does not print an additional message regarding "xlabel" or "force"
	
	local CXmin = r(CXmin)		// limits of data plotting (i.e. off-scale arrows)... = DX by default
	local CXmax = r(CXmax)
	local DXmin = r(DXmin)		// limits of data plot region
	local DXmax = r(DXmax)
	
	return local range `"`DXmin' `DXmax'"'
	
	local xtitleval = r(xtitleval)	// position of xtitle [May 2024: not currently implemented]

	// May 2024
	local graphopts `"`r(xlabopt2)' `r(xlabopt)' `r(xmlabopt2)' `r(xmlabopt)' `r(favopt)' `r(xtickopt2)' `r(xtickopt)' `r(xmtickopt2)' `r(xmtickopt)' `r(options)'"'
	
	// Nov 2017
	local null      `"`r(null)'"'
	local rowsxlab  = r(rowsxlab)
	local rowsxmlab = r(rowsxmlab)
	local rowsfav   = r(rowsfav)
	
	
	** Need to make changes to pre-existing data now
	// e.g. adding new obs to the dataset to contain multi-line column headings
	//  so use -preserve-
	preserve

	// [added Nov 2018]
	// Make data obey the conventions of _USE
	qui replace `_USE' = 6 if !inrange(`_USE', 0, 7) & `touse'
	qui replace `_ES' = .  if `touse' & `_USE'==2
	qui replace `_LCI' = . if `touse' & `_USE'==2
	qui replace `_UCI' = . if `touse' & `_USE'==2
	if `"`names'"'==`""' {
		qui replace `_LABELS' = "" if `touse' & `_USE'==6
	}
	qui replace `_WT' = . if `touse' & inlist(`_USE', 2, 6) & `"`wt'"'==`""'
			
	
	* Find `lcimin' = left-most confidence limit among the "diamonds" (including predictive intervals)
	* (Note: this is *only* used within the `adjust' subroutine within ProcessColumns)
    tempvar lci2
	qui gen `lci2' = cond(`"`null'"'==`""', cond(`_LCI'>`h0', `h0', ///
		cond(`_LCI'>`CXmin', `_LCI', `CXmin')), cond(`_LCI'>`CXmin', `_LCI', `CXmin'))
	if `"`rfdist'"'!=`""' {
		qui replace `lci2' = cond(`"`null'"'==`""', cond(`_rfLCI'>`h0', `h0', ///
			cond(`_rfLCI'>`CXmin', `_rfLCI', `CXmin')), cond(`_rfLCI'>`CXmin', `_rfLCI', `CXmin'))
	}
	summ `lci2' if `touse' & inlist(`_USE', 3, 5, 7), meanonly
	local lcimin = cond(r(N), r(min), cond(`"`null'"'==`""', `h0', `CXmin'))
	drop `lci2'	

	* Unpack `usedims'
	local DXwidthChars = -9			// initialize
	if `"`usedims'"'!=`""' {
		cap confirm matrix `usedims'
		if _rc {
			nois disp as err "Error in option {bf:usedims()}: " _c
			confirm matrix `usedims'
		}
		
		local DXwidthChars = `usedims'[1, `=colnumb(matrix(`usedims'), "cdw")']
		confirm number `DXwidthChars'
		assert `DXwidthChars' >= 0

		local oldLCImin = `usedims'[1, `=colnumb(matrix(`usedims'), "lcimin")']
		confirm number `oldLCImin'		// can be <0
		local lcimin = min(`lcimin', `oldLCImin')
	}

	// Pass exactly one of `DXwidthChars' or `astext' to ProcessColumns
	// (if specified, `astext' trumps `DXwidthChars')
	if `"`usedims'"'!=`""' & `astext'==-9 {
		local astextopt `"dxwidthchars(`DXwidthChars')"'
	}
	else {
		local astext = cond(`astext'==-9, 50, `astext')
		cap assert `astext' > 0
		if _rc {
		    nois disp as err "error in option {bf:astext(}{it:#}{bf:)}: {it:#} must be in the range (0, 100]"
			exit 125
		}		
		local astextopt `"astext(`astext')"'
	}
	

	** Generate ordering variable (reverse sequential, since y axis runs bottom to top)
	// Need to do this *before* extra obs are added by ProcessColumns to hold title text
	// Apr 2020: furthermore, sort such that `touse' obs come *first* ... so need to sort on "negated" `touse'
	tempvar touse_neg id
	qui gen byte `touse_neg' = 1 - `touse'
	qui bysort `touse_neg' (`obs') : gen long `id' = _N - _n + 1 if `touse'
	drop `touse_neg'
	
	
	
	************************
	* LEFT & RIGHT COLUMNS *
	************************
	
	// Setup: generate tempvars to send to ProcessColumns
	foreach xx in left right {
		local x = substr("`xx'", 1, 1)		// extract "l" from "left" and "r" from "right"

		forvalues i=1/``x'colsN' {		// N.B. if `lcolsN' or `rcolsN'==0, this loop will be skipped
			tempvar `xx'`i'
			local `x'vallist ``x'vallist' ``xx'`i''			// store x-axis positions of columns
				
			local `x'coli : word `i' of ``x'cols'
			local f : format ``x'coli'
			tokenize `"`f'"', parse("%~s.,")
			if "`2'"=="~" {									// Modified Aug2023 to handle centered format
				confirm number `3'
				if `"`leftjustify'"'!=`""' local flen = -abs(`3')
				else local flen `2'`3'
			}
			else {
				confirm number `2'
				local flen = `2'
				if `"`leftjustify'"'!=`""' local flen = -abs(`2')
			}
			
			cap confirm string var ``x'coli'
			if !_rc local `xx'LB`i' : copy local `x'coli	// if string
			else {											// if numeric
				tempvar `xx'LB`i'
				if `"`: value label ``x'coli''"'!=`""' {	// if labelled (10th July 2017)
					qui decode ``x'coli', gen(``xx'LB`i'')
				}
				else qui gen str ``xx'LB`i'' = string(``x'coli', "`f'")
				qui replace ``xx'LB`i'' = "" if ``xx'LB`i'' == "."
				
				local colName : variable label ``x'coli'
				// Removed v3.0.1 for consistency with string variables
				// Now -forestplot- consistently honours *blank* varlabels
				// if `"`colName'"' == "" & `"``x'coli'"' !=`"`labels'"' local colName = `"``x'coli'"'
				label variable ``xx'LB`i'' `"`colName'"'
			}
			
			local `x'lablist ``x'lablist' ``xx'LB`i''	// store contents (text/numbers) of columns
			local `x'fmtlist ``x'fmtlist' `flen'		// desired max no. of characters based on format
		}
		
		if !`lcolsN' {
			tempvar left1
			local lvallist `left1'
		}
		
		local `x'optlist `x'vallist(``x'vallist') `x'lablist(``x'lablist') `x'fmtlist(``x'fmtlist')
	}
		
	
	// niche case:  possible that user-specified `_USE' already contains values of 9 for some reason
	// if so, change them to 99 (doesn't matter what value they are as long as not 0 to 6, or 9)
	// (and we are under -preserve- )
	qui replace `_USE' = 99 if `touse' & `_USE'==9	
	
	local oldN = _N
	cap nois ProcessColumns `_USE' `_EFFECT' if `touse', id(`id') `wt' ///
		lrcolsn(`lcolsN' `rcolsN') lcimin(`lcimin') dx(`DXmin' `DXmax') ///
		`loptlist' `roptlist' `rfcolopts' `astextopt' `adjust' `colsonly' `graphopts'
	
	if _rc {
		if _rc==1 nois disp as err `"User break in {bf:forestplot.ProcessColumns}"'
		else nois disp as err `"Error in {bf:forestplot.ProcessColumns}"'
		c_local err noerr		// tell calling program (e.g. -metan- ) not to also report an error
		exit _rc
	}
	
	local leftWDtot = r(leftWDtot)
	local rightWDtot = r(rightWDtot)
	local astext = r(astext)

	local AXmin = r(AXmin)
	local AXmax = r(AXmax)
	if `"`colsonly'"'!=`""' {
		if       `lcolsN' & !`rcolsN' local AXmax = `DXmin'
		else if !`lcolsN' &  `rcolsN' local AXmin = `DXmax'
		local AXval = (`AXmax' + `AXmin') / 2
	}
	
	// June 2023
	local lposlist `r(lposlist)'
	local rposlist `r(rposlist)'

	local graphopts `"`r(graphopts)'"'

	// Amended Apr 2020
	// New observations, added by ProcessColumns
	qui replace `touse' = 1 if missing(`touse') & !missing(`id')

	
	*** FIND OPTIMAL TEXT SIZE AND ASPECT RATIOS (given user input)
	// We already have an estimate of the height taken up by x-axis labelling (this is `rowsxlab' from ProcessXAxis)
	// Next, find basic height to send to GetAspectRatio
	// Apr 2020: Note that this was previously derived in terms of number of observations
	// but now we use `id' instead due to `double' option
	// qui count if `touse'
	// local height = r(N)
	summ `id' if `touse', meanonly
	if r(N) local height = r(max)
	else local height = 0
	

	// Jan 2020
	// need to account for observations which will ultimately *not* be displayed
	// i.e. either removed using "nooverall"/"nosubgroup"; or "hidden" using OCILineOpts
	local reduceHeight = 0
	if `"`overall'`subgroup'"'!=`""' {
		if `"`subgroup'"'!=`""' {
			qui count if `touse' & `_USE'==3
			local reduceHeight = r(N)
		}
		if `"`overall'"'!=`""' {
			qui count if `touse' & inlist(`_USE', 4, 5, 7)
			local reduceHeight = `reduceHeight' + r(N)
		}
	}
	else if `"`cumulative'`influence'"'!=`""' {
		// `cumulative' or `influence' implies "hide"
		qui count if `touse' & inlist(`_USE', 3, 5, 7)
		local reduceHeight = r(N)
	}
	else {			// user-specified "hide"
		UserSpecHide `_USE' if `touse', plotid(`plotid') `graphopts'
		local reduceHeight = r(N)
	}
	local height = `height' - `reduceHeight'
	
	qui count if `touse' & `_USE'==9
	if r(N) local ++height				// add 1 to overall height if titles present, to account for the "gap" in `id' (see later)
		
	local colWDtot = `leftWDtot' + `rightWDtot'
	if `"`usedims'"'==`""' {
		local DXwidthChars = `colWDtot'*((100/`astext') - 1)
	}

	// height of "xmlabel" text is assumed to be ~60% of "xlabel" text ... unless favours which uses xmlabel differently!
	local rowsxlabval = cond(`rowsfav', `rowsxlab', max(`rowsxlab', .6*`rowsxmlab'))
	
	GetAspectRatio, astext(`astext') colwdtot(`colWDtot') height(`height') rowsxlab(`rowsxlabval') rowsfav(`rowsfav') ///
		usedims(`usedims') `xtitle' `textsize' `colsonly' `graphopts'

	local graphopts `"`r(graphopts)'"'

	local xsize = r(xsize)
	local ysize = r(ysize)
	local fxsize = r(fxsize)
	local fysize = r(fysize)
	local yheight = r(yheight)
	local spacing = r(spacing)
	local textSize = r(textsize)			// textsize as calculated by GetAspectRatio
	local textSize2 = r(textsize2)			// textsize as modified post-hoc by textscale() option [May 2020]
	local approxChars = r(approxchars)
	local graphAspect = r(graphaspect)
	local plotAspect = r(plotaspect)

	* If specified, store in a matrix the quantities needed to recreate proportions in subsequent forestplot(s)
	// [`lcimin' added Sep 2017; `height' added Nov 2017]
	if `"`savedims'"'!=`""' {
		mat `savedims' = `DXwidthChars', `spacing', `plotAspect', `ysize', `xsize', `textSize', `height', `yheight', `lcimin'
		mat colnames `savedims' = cdw spacing aspect ysize xsize textsize height yheight lcimin
	}

	* Insert labsize(`textSize2') into existing x[m]labopt(s)
	local 0 `", `graphopts'"'
	syntax [, XLAbel(string asis) XMLabel(string asis) * ]
	local graphopts `"`options'"'

	while trim(`"`xlabel'`xmlabel'"')!=`""' {
		foreach xop in xlabel xmlabel {
			if `"``xop''"'!=`""' {
				local 0 `"``xop''"'
				syntax [anything(name=xcmd)] , [LABSize(string) LABGAP(string) FAVOURS * ]

				// colsonly: now add in "dummy" value to x[m]label command
				if `"`colsonly'"'!=`""' {
					gettoken tok rest : xcmd
					if `"`tok'"'==`"__DUMMY__"' local xcmd `AXval' `rest'
				}
				if "`xop'"=="xlabel" {
					local labsizeopt labsize(`textSize2')
					local labgapopt
				}
				else {
					local labsize = cond(`"`favours'"'!=`""', `textSize2', .6*`textSize2')
					local labsizeopt labsize(`labsize')
					if `"`favours'"'!=`""' local labgapopt labgap(5)
				}
				local newopts `"`newopts' `xop'(`xcmd', `labsizeopt' `labgapopt' `options')"'
			}
		}

		// Test for repeated options and loop if necessary
		// Parse for "add" and discard repeated options if appropriate
		// so that later parsing and updating/replacing of "labsize()" is accurate
		local 0 `", `graphopts'"'
		syntax [, XLAbel(string asis) XMLabel(string asis) * ]
		local graphopts `"`options'"'
	}		// end while loop

	// local graphopts `"xsize(`xsize') ysize(`ysize') fxsize(`fxsize') fysize(`fysize') aspect(`plotAspect') `graphopts'"'
	// Modified Jan 2018: f{x|y}size only if usedims/savedims
	local graphopts `"xsize(`xsize') ysize(`ysize') aspect(`plotAspect') `newopts' `macval(graphopts)'"'
	if trim(`"`savedims'`usedims'"')!=`""' local graphopts `"fxsize(`fxsize') fysize(`fysize') `macval(graphopts)'"'
		
	// Return useful quantities
	return scalar aspect = `plotAspect'
	return scalar astext = `astext'
	return scalar ldw = `leftWDtot'			// display width of left-hand side
	return scalar rdw = `rightWDtot'		// display width of right-hand side
	// local DXwidthChars = cond(`"`usedims'"'!=`""', `DXwidthChars', `colWDtot'*((100/`astext') - 1))
	return scalar cdw = `DXwidthChars'		// display width of centre (i.e. the "data" part of the plot)
	return scalar height = `height'
	return scalar spacing = `spacing'
	return scalar ysize = `ysize'
	return scalar xsize = `xsize'
	return scalar textsize = `textSize2'		// May 2020: if -metan9- option textsize() was applied, returns "post-hoc modified" textsize....
	if trim(`"`savedims'`usedims'"')!=`""' {	// ... which may differ from the `textsize' value stored in matrix `savedims'
		return scalar fysize = `fysize'
		return scalar fxsize = `fxsize'
	}


	
	************************************
	* Build plot commands from options *
	************************************

	// Commands for plotting columns of text (lcols/rcols)
	forvalues i = 1/`lcolsN' {
		gettoken lpos`i' lposlist : lposlist
		local lcolCommands `"`macval(lcolCommands)' scatter `id' `left`i'' if `touse', msymbol(none) mlabel(`leftLB`i'') mlabcolor(black) mlabpos(`lpos`i'') mlabgap(0) mlabsize(`textSize2') ||"'
	}
	forvalues i = 1/`rcolsN' {
		gettoken rpos`i' rposlist : rposlist
		local rcolCommands `"`macval(rcolCommands)' scatter `id' `right`i'' if `touse', msymbol(none) mlabel(`rightLB`i'') mlabcolor(black) mlabpos(`rpos`i'') mlabgap(0) mlabsize(`textSize2') ||"'
	}	
	

	** Prepare tempvars...
	// ...for diamonds
	tempvar DiamX DiamY1 DiamY2
	local diamlist `DiamX' `DiamY1' `DiamY2'

	// ...for "overall effect" lines
	// Jan 2020: now including overall confidence limit lines
	tempvar ovLine ovMin ovMax ovLineLCI ovLineUCI ovLineX
	local ovlist `ovLine' `ovMin' `ovMax' `ovLineLCI' `ovLineUCI' `ovLineX'

	// ...for off-scale arrows
	tempvar offscaleL offscaleR
	local offsclist `offscaleL' `offscaleR'

	// ...for predictive intervals
	// Jan 2020: now including confidence limit lines
	if `"`rfdist'"'!=`""' {
		tempvar rfLoffscaleL rfLoffscaleR rfRoffscaleL rfRoffscaleR rfLineLCI rfLineUCI rfLineX
		local rflist `rfLoffscaleL' `rfLoffscaleR' `rfRoffscaleL' `rfRoffscaleR' `rfLineLCI' `rfLineUCI' `rfLineX'
	}
		
	// ...for multiple plotids and/or for area plots
	tempvar tousePlotID touseDiam touseOCI touseRFCI
	local tvopts `"diamlist(`diamlist') ovlist(`ovlist') offsclist(`offsclist') rflist(`rflist') touseextra(`tousePlotID' `touseDiam' `touseOCI' `touseRFCI')"'
	
	// August 2018: N.B. unusually, have to pass `touse' as an option here (rather than using marksample)
	// since we need to have the same tempname appearing in the created plot commands
	cap nois BuildPlotCmds `_USE' `_ES' `_LCI' `_UCI', touse(`touse') id(`id') ///
		plotid(`plotid') dataid(`dataid') `newwt' h0(`h0') `null' `colsonly' ///
		`cumulative' `influence' `interaction' `overall' `subgroup' `graphopts' ///
		wgt(`_WT') rfdist(`_rfLCI' `_rfUCI') cxlist(`CXmin' `CXmax') `tvopts'
	
	if _rc {
		if _rc==1 disp as err "User break"
		else disp as err `"Error in {bf:forestplot.BuildPlotCmds}"'
		c_local err noerr		// tell calling subroutine not to also report an error
		exit _rc
	}

	local RFPlot        `"`s(rfplot)'"'
	local PCIPlot       `"`s(pciplot)'"'
	local diamPlot      `"`s(diamplot)'"'
	local pointPlot     `"`s(pointplot)'"'
	local ppointPlot    `"`s(ppointplot)'"'
	local olineAreaPlot `"`s(olineareaplot)'"'
	local borderCommand `"`s(bordercommand)'"'

	local graphopts     `"`s(options)'"'
	
	// Nov 2021: see notes within BuildPlotCmds
	if `"`s(g_overlay_ci)'"'!=`""' {
		local firstPlot  `"`s(ciplot)'"'
		local secondPlot `"`s(scplot)'"'
	}
	else {		// current default
		local firstPlot  `"`s(scplot)'"'
		local secondPlot `"`s(ciplot)'"'
	}
	if `"`s(g_olinefirst)'"'!=`""' {
		local olinePlotFirst `"`s(olineplot)'"'
	}
	else local olinePlot     `"`s(olineplot)'"'
	if `"`s(g_nlinefirst)'"'!=`""' {
		local nullCommandFirst `"`s(nullcommand)'"'
	}
	else local nullCommand     `"`s(nullcommand)'"'
	

	qui count if `touse'
	if !r(N) {
		nois disp as err "no observations"
		exit 2000
	}
	return scalar obs = r(N)

	
	
	***************************
	***     DRAW GRAPH      ***
	***************************

	// First, if `useopts' and `graphopts' both supplied, check for repeated (non-Stata graph) options in `graphopts' which would cause -twoway- to fail
	//  (otherwise, onus is on user as usual)
	if `"`useopts'"'!=`""' & `"`orig_gropts'"'!=`""' {
		local 0 `", `graphopts'"'
		syntax [, BY(varname) EFORM EFFect(string asis) LABels(varname string) DP(integer 2) KEEPALL ///
			INTERaction LCols(namelist) RCols(namelist) LEFTJustify COLSONLY RFDIST(varlist numeric min=2 max=2) ///
			NULLOFF noNAmes noNULL NULL2(string) noKEEPVars noOVerall noSTATs noSUbgroup noWT LEVEL(cilevel) ///
			XTItle(passthru) FAVours(passthru) /// /* N.B. -xtitle- is parsed here so that a blank title can be inserted if necessary */
			CUmulative INFluence /// /* only needed in order to switch _USE==3 back to _USE==1
			/// /* Sub-plot identifier for applying different appearance options, and dataset identifier to separate plots */
			PLOTID(string) DATAID(string) ///
			/// /* "fine-tuning" options */
			SAVEDIms(name) USEDIms(name) ASText(real -9) noADJust ///
			FP(string) /// 		/*(deprecated; now a favours() suboption)*/
			KEEPXLabs /// 	/*(undocumented; colsonly option)*/
			RAnge(string) CIRAnge(string) /// /* from ProcessXAxis*/
			DXWIDTHChars(real -9) LBUFfer(real 0) RBUFfer(real 1) /// /* from ProcessColumns */
			noADJust noLCOLSCHeck TArget(integer 0) MAXWidth(integer 0) MAXLines(integer 0) noTRUNCate ///
			ADDHeight(real 0) /// /* from GetAspectRatio */
			CLASSIC noDIAmonds WGT(varname numeric) NEWwt BOXscale(real 100.0) noBOX /// /* from BuildPlotCmds */
			/// /* standard options */
			BOXOPts(string asis) DIAMOPts(string asis) POINTOPts(string asis) CIOPts(string asis) OLINEOPts(string asis) ///
			NLINEOPts(string asis) HLINEOPts(string asis) ///
			/// /* non-diamond and predictive interval options */
			PPOINTOPts(string asis) PCIOPts(string asis) RFOPts(string asis) * ]
		
		local graphopts `"`macval(options)'"'
	}
	
	// August 2023: quickly parse for legend() option; if not present, set legend(off)
	// Legends cannot (currently) be automated; responsibility is to the user to sort them out
	local 0 `", `graphopts'"'
	syntax [, LEGend(string asis) * ]
	if `"`legend'"'==`""' local legend_opt legend(off)
	
	local xtitleopt = cond(`"`xtitle'"'==`""', `"xtitle("")"', `"`xtitle'"')		// to prevent tempvar name being printed as xtitle

	summ `id', meanonly
	// local DYmin = r(min) - 1			// amended Apr 2020
	local DYmin = 0
	local DYmax = r(max) + 1
		
	// Re-ordered 28th June 2017 so that all twoway options are given together at the end	
	#delimit ;

	twoway

	/* Nov 2017: order was: columns, overall, weighted, diamonds */

	/* Nov 2021: if requested, place overall and null lines underneath everything else */
		`olinePlotFirst' `nullCommandFirst'
	
	/* Jan 2020: if applicable, OVERALL CI AREA PLOT first, so that data points remain visible */
		`olineAreaPlot'
	
	/* WEIGHTED SCATTERPLOT BOXES (plus plot-specific options) */ 
	/*  and CONFIDENCE INTERVALS (incl. "offscale" if necessary) */
		`firstPlot' `secondPlot'
	
	/* OVERALL AND NULL LINES (plus plot-specific options) (Nov 2021: unless placed underneath; see above) */ 
		`olinePlot' `nullCommand'
	
	/* DIAMONDS (or markers+CIs if appropriate) FOR SUMMARY ESTIMATES */
	/* (and Prediction Intervals if appropriate; plus plot-specific options) */
	/*  then last of all PLOT EFFECT MARKERS to clarify */
		`RFPlot' `PCIPlot' `diamPlot' `pointPlot' `ppointPlot' 
	
	/* COLUMN VARIBLES (including effect sizes and weights on RHS by default) */
		`lcolCommands' `rcolCommands'

	/* FAVOURS OR XTITLE */
	/* do these first, so that their options may be overwritten by the user */
		, `favopt' `xtitleopt'
	
	/* Y-AXIS OPTIONS */
	// Note that, as yscale is merged-implicit, range(`AXmin' `AXmax') noline will take precedence over any user-specified range() sub-option to yscale,
	// ...but other yscale() options will be honored.  Users cannot over-ride the y-range; nor can they supply ylabels or ytitle.
		yscale(range(`DYmin' `DYmax') noline) ylabel(none) ytitle(`""') `borderCommand'
	
	/* X-AXIS OPTIONS */
	// Note that, as xscale is merged-implicit, range(`AXmin' `AXmax') will take precedence over any user-specified range() sub-option to xscale,
	// ...but other xscale() options will be honored.  Users should specify the x-range via the separate, command-specific range() option.
		xscale(range(`AXmin' `AXmax')) `xlabopt' `xmlabopt' `xtickopt' `xmtickopt' `legend_opt'

	/* OTHER TWOWAY OPTIONS (`graphopts' = user-specified) */
		`graphopts' plotregion(margin(zero)) ;

	#delimit cr

end





program define getWidth, sortpreserve
version 9.0

//	ROSS HARRIS, 13TH JULY 2006
//	TEXT SIZES VARY DEPENDING ON CHARACTER
//	THIS PROGRAM GENERATES APPROXIMATE DISPLAY WIDTH OF A STRING
//  (in terms of the current graphics font)
//	FIRST ARG IS STRING TO MEASURE, SECOND THE NEW VARIABLE

//	PREVIOUS CODE DROPPED COMPLETELY AND REPLACED WITH SUGGESTION
//	FROM Jeff Pitblado

// Updated August 2016 by David Fisher (added "touse" and "replace" functionality)

syntax anything [if] [in] [, REPLACE]

assert `: word count `anything''==2
tokenize `anything'
marksample touse

if `"`replace'"'==`""' {		// assume `2' is newvar
	confirm new variable `2'
	qui gen `2' = 0 if `touse'
}
else {
	confirm numeric variable `2'
	qui replace `2' = 0 if `touse'
}

qui {
	count if `touse'
	local N = r(N)
	tempvar obs
	bys `touse' : gen int `obs' = _n if `touse'
	sort `obs'
	forvalues i = 1/`N'{
		local this = `1'[`i']
		local width: _length `"`this'"'
		replace `2' =  `width' /*+1*/ in `i'	// "+1" blanked out by DF; add back on at point of use if necessary
	}
} // end qui

end



* exit

//	METAN UPDATE
//	ROSS HARRIS, DEC 2006
//	MAIN UPDATE IS GRAPHICS IN THE _dispgby PROGRAM
//	ADDITIONAL OPTIONS ARE lcols AND rcols
//	THESE AFFECT DISPLAY ONLY AND ALLOW USER TO SPECIFY
//	VARIABLES AS A FORM OF TABLE. THIS EXTENDS THE label(namevar yearvar)
//	SYNTAX, ALLOWING AS MANY LEFT COLUMNS AS REQUIRED (WELL, LIMIT IS 10)
//	IF rcols IS OMMITTED DEFAULT IS THE STUDY EFFECT (95% CI) AND WEIGHT
//	AS BEFORE- THESE ARE ALWAYS IN UNLESS OMITTED USING OPTIONS
//	ANYTHING ADDED TO rcols COMES AFTER THIS.


********************
** May 2007 fixes **
********************

//	"nostandard" had disappeared from help file- back in
//	I sq. in return list
//	sorted out the extra top line that appears in column labels
//	fixed when using aspect ratio using xsize and ysize so inner bit matches graph area- i.e., get rid of spaces for long/wide graphs
//	variable display format preserved for lcols and rcols
//	abbreviated varlist now allowed
//	between groups het. only available with fixed
//	warnings if any heterogeneity with fixed (for between group het if any sub group has het, overall est if any het)
// 	nulloff option to get rid of line




******************
* DF subroutines *
******************


* CheckOpts
// Based on the built-in _check_eformopt.ado,
//   but expanded from -eform- to general effect specifications.
// This program is used by -ipdmetan-, -(ad)metan- and -forestplot-
// Not all aspects are relevant to all programs,
//   but easier to maintain just a single subroutine!

program define CheckOpts, sclass

	syntax [name(name=cmdname)] [, soptions OPts(string asis) ESTVAR(name) ]
	
	if "`cmdname'"!="" {
		_check_eformopt `cmdname', `soptions' eformopts(`opts')
	}
	else _get_eformopts, `soptions' eformopts(`opts') allowed(__all__)
	local summstat = cond(`"`s(opt)'"'==`"eform"', `""', `"`s(opt)'"')

	if "`summstat'"=="rrr" {
		local effect `"Risk ratio"'		// Stata by default refers to this as a "Relative Risk Ratio" or "RRR"
		local summstat rr				//  ... but in MA context most users will expect "Risk Ratio"
	}
	else if "`summstat'"=="nohr" {		// nohr and noshr are accepted by _get_eformopts
		local effect `"Haz. ratio"'		//  but are not assigned names; do this manually
		local summstat hr
		local logopt nohr
	}
	else if "`summstat'"=="noshr" {
		local effect `"SHR"'
		local summstat shr
		local logopt noshr
	}
	else local effect `"`s(str)'"'

	if "`estvar'"=="_cons" {			// if constant model, make use of eform_cons_ti if available
		local effect = cond(`"`s(eform_cons_ti)'"'!=`""', `"`s(eform_cons_ti)'"', `"`effect'"')
	}
	
	local 0 `", `s(eform)'"'
	syntax [, EFORM(string asis) * ]
	local eform = cond(`"`eform'"'!=`""', "eform", "")
	
	// Next, parse `s(options)' to extract anything that wouldn't usually be interpreted by _check_eformopt
	//  that is: mean differences (`smd', `wmd' with synonym `md'); `rd' (unless -binreg-);
	//  `coef'/`log' and `nohr'/`noshr' (which all imply `log')
	// (N.B. do this even if a valid option was found by _check_eformopt, since we still need to check for multiple options)
	local 0 `", `s(options)'"'
	syntax [, COEF LOG NOHR NOSHR RD SMD WMD MD * ]

	// identify multiple options; exit with error if found
	opts_exclusive "`coef' `log' `nohr' `noshr'"
	if `"`summstat'"'!=`""' {
		if trim(`"`md'`smd'`wmd'`rr'`rd'`nohr'`noshr'"')!=`""' {
			opts_exclusive "`summstat' `md' `smd' `wmd' `rr' `rd' `nohr' `noshr'"
		}
	}
	
	// if "nonstandard" effect option used
	else {
		if trim(`"`md'`wmd'"')!=`""' {		// MD and WMD are synonyms
			local effect WMD
			local summstat wmd
		}
		else {
			local effect = cond("`smd'"!="", `"SMD"', ///
				cond("`rd'"!="", `"Risk Diff."', `"`effect'"'))
			local summstat = cond(`"`summstat'"'==`""', trim(`"`smd'`rd'"'), `"`summstat'"')
		}
		else if "`nohr'"!="" {
			local effect `"Haz. ratio"'
			local summstat hr
			local logopt nohr
		}
		else if "`noshr'"!="" {
			local effect `"SHR"'
			local summstat shr
			local logopt noshr
		}		

		// now check against program properties and issue warning
		if "`cmdname'"!="" {
			local props : properties `cmdname'
			if "`cmdname'"=="binreg" local props `props' rd
			if !`:list summstat in props' {
				cap _get_eformopts, eformopts(`summstat')
				if _rc {
					disp as err `"Note: option {bf:`summstat'} does not appear in properties of command {bf:`cmdname'}"'
				}
			}
		}
	}
	
	// log always takes priority over eform
	// ==> cancel eform if appropriate
	local log = cond(trim(`"`coef'`logopt'"')!=`""', "log", "`log'")					// `coef' is a synonym for `log'; `logopt' was defined earlier
	if `"`log'"'!=`""' {
		if inlist("`summstat'", "rd", "smd", "wmd") {
			nois disp as err "Log option only appropriate with ratio statistics"
			exit 198
		}
		local eform
	}
	
	sreturn clear
	sreturn local logopt = trim(`"`coef'`logopt'"')		// "original" log option
	sreturn local log      `"`log'"'					// either "log" or nothing
	sreturn local eform    `"`eform'"'					// either "eform" or nothing
	sreturn local summstat `"`summstat'"'				// if `eform', original eform option
	sreturn local effect   `"`effect'"'
	sreturn local options  `"`macval(options)'"'

end




*********************************************************************************

* Subroutine to sort out labels and ticks for x-axis, and find DXmin/DXmax (and CXmin/CXmax if different)
* Created August 2016
* Modified & renamed May 2024

program define ProcessXAxis, rclass

	syntax anything [, RAnge(string) CIRAnge(string) EFORM H0(real 0) noNULL DENOMinator(passthru) COLSONLY FAVours(string asis) ///
		FP(string) FORCE /* deprecated -metan9- options; now handled differently */ * ]
		
	local graphopts `"`options'"'
	tokenize `anything'
	args DXmin DXmax	

	
	* Initial parse of xlabel and xtick
	// [added May 2020] In case old (v3.x and earlier) syntax is used, with comma-separated values and no sub-options
	// Otherwise, ignore and send through as-is to -twoway- to pick up any other issues
	// Note: doesn't apply to xmlabel, xmtick as these were not allowed by -metan9-
	// Note: MAY 2024: Look for repeated options -- these would not have been *expected* by -metan9-
	// ... but -twoway- would still have accepted them if supplied
	local 0 `", `graphopts'"'
	syntax [, XLAbel(string asis) XTick(string) * ]
	local graphopts `"`options'"'

	while trim(`"`xlabel'`xtick'"')!=`""' {
		foreach xop in xlabel xtick {
			ParseOldXLabel `"``xop''"', xop(`xop') h0(`h0') `eform' `force' `twowaynote'
			if `"`r(xlablist)'"'!=`""' local `xop'new `"``xop'new' `xop'(`r(xlablist)')"'
		}
		local 0 `", `graphopts'"'
		syntax [, XLAbel(string asis) XTick(string) * ]
		local graphopts `"`options'"'
	}
	if "`twowaynote'"!="" c_local twowaynote notwowaynote	// so that -metan- does not print an additional message regarding "xlabel" or "force"	
	
	* If `eform', need to extract correct format to use when assembling labels in exponentiated scale
	if `"`eform'"'!=`""' {
		local use_format
		local formatopts `"`graphopts' `xlabelnew'"'
		local 0 `", `formatopts'"'
		syntax [, XLAbel(string asis) XMLabel(string asis) * ]
		local formatopts `"`options'"'
		while trim(`"`xlabel'`xmlabel'"')!=`""' {
			foreach xop in xlabel xmlabel {
				local 0 `"``xop''"'		// xlabel, xmlabel
				syntax [anything] , [FORMAT(string) * ]	
				if `"`format'"'!=`""' local use_format : copy local format		// format() is right-most
			}
			local 0 `", `formatopts'"'
			syntax [, XLAbel(string asis) XMLabel(string asis) * ]
			local formatopts `"`options'"'			
		}
	}	
	
	* Full parse x[m]label and x[m]tick, if supplied by user
	* (Note: we now assume all options follow standard Stata -twoway- syntax)
	*  - Extract numlists for labels & ticks, from which to calculate size of plot (CXmin/max, DXmin/max etc.)
	*  - If `eform', interpret user-supplied label values as on the exponentiated scale; apply labels on the interval scale accordingly
	*  - Calculate no. of rows in case of `colsonly'
	* But keep repeated options etc. as-is to send to -twoway- , so that subtleties are honoured
	local 0 `", `graphopts' `xlabelnew' `xticknew'"'
	syntax [, XLAbel(string asis) XMLabel(string asis) XTick(string) XMTick(string) * ]
	local graphopts `"`options'"'
	
	local rowsxmlab = 0
	local rowsxlab = 0
	local firstadd = 1
	while trim(`"`xlabel'`xmlabel'`xtick'`xmtick'"')!=`""' {
		foreach xop in xlabel xmlabel xtick xmtick {
			local xab : copy local xop
			if "`xop'"=="xlabel" local xab xlab
			else if "`xop'"=="xmlabel" local xab xmlab
			
			local 0 `"``xop''"'
			syntax [anything(name=`xab'cmd)] , [FORCE ADD ADDNEW /*colsonly-specific option*/ ALTernate /*rightmost, unless "add|addnew" */ * ]
			
			// Parse x[m]lablist and obtain numlist (Nov 2017)
			ProcessXLabels ``xab'cmd', dx(`DXmin' `DXmax') xop(`xop') format(`use_format') `eform' `colsonly'
			
			// Add results to previous (if repeated options with `add')
			if trim(`"`add'`addnew'"')==`""' {
				local `xab'list `"`r(xlablist)'"'
				if trim(`"`r(xlabcmd)'`options'"')!=`""' {
					local `xab'opt `"`xop'(`r(xlabcmd)', `options')"'
				}
			}
			else {
				if `"`colsonly'"'!=`""' & `"`addnew'"'!=`""' {
					if `firstadd' local firstadd = 0
					else local addopt add
					
					local `xab'list2 `"``xab'list2' `r(xlablist)'"'							// append values
					if trim(`"`r(xlabcmd)'`options'"')!=`""' {
						local `xab'opt2 `"``xab'opt2' `xop'(`r(xlabcmd)', `options' `addopt')"'	// repeated options + sub-options
					}					
					if trim(`"``xab'opt2'"')!=`""' local addcustom add custom		// for later
				}

				local `xab'list `"``xab'list' `r(xlablist)'"'						// append values
				if trim(`"`r(xlabcmd)'`options'"')!=`""' {
					local `xab'opt `"``xab'opt' `xop'(`r(xlabcmd)', `options' add)"'	// repeated options + sub-options
				}
			}
			if !inlist("`xop'", "xtick", "xmtick") {
				local rows`xab' = max(`rows`xab'', `=`r(rows)' + (`"`alternate'"'!=`""')')
			}
			
			// `force' option
			if `"`force'"'!=`""' {
				if `"`xop'"'!=`"xlabel"' {			// "force" option only applies to xlab, not xmlab or ticks
					nois disp as err "option {bf:force} is not allowed with {bf:`xop'()}"
					exit 198
				}
				if "`cirange'"!="" {
					disp as err `"Note: both {bf:cirange()} and {bf:xlabel(, force)} were specifed; {bf:cirange()} takes precedence"'
				}
				else if `"`xlablist'"'!=`""' {
					local xlablist2 : copy local xlablist
					local min : word 1 of `xlablist2'
					if inlist(`"`min'"', `"none"', `"."') {
						gettoken none xlablist2 : xlablist
					}
					numlist `"`xlablist2'"', sort
					local n : word count `r(numlist)'
					local min : word 1 of `r(numlist)'
					local max : word `n' of `r(numlist)'
					if `"`CRXmin'"'==`""' local CRXmin = `min'
					else {
						local CRXmin = max(`CRXmin', `min')		// if multiple "force" options, use most restrictive
					}
					if `"`CRXmax'"'==`""' local CRXmax = `max'
					else {
						local CRXmax = min(`CRXmax', `max')		// if multiple "force" options, use most restrictive
					}
					local forceopt force	// indicator that "force" has been specified
				}
			}
		}		// end foreach

		// Test for repeated options and loop if necessary
		// Parse for "add" and discard repeated options if appropriate
		// so that later parsing and updating/replacing of "labsize()" is accurate
		local 0 `", `graphopts'"'
		syntax [, XLAbel(string asis) XMLabel(string asis) XTick(string) XMTick(string) * ]
		local graphopts `"`options'"'
	}		// end while loop
		
	
	* If `colsonly', blank out the labels, and make ticks and gridlines invisible
	if `"`colsonly'"'!=`""' {
		foreach xop in xlabel xmlabel xtick xmtick {
			local xab : copy local xop
			if "`xop'"=="xlabel" local xab xlab
			else if "`xop'"=="xmlabel" local xab xmlab

			if inlist("`xop'", "xlabel", "xmlabel") {
				if `"``xab'opt'"'!=`""' {
					forvalues i=1/`rows`xab'' {
						local `xab'txt `"``xab'txt' `" "'"'
					}
					if `rows`xab'' > 1 local `xab'txt `"`"``xab'txt'"'"'
					local `xab'opt `"`xop'( __DUMMY__ ``xab'txt', tlc(none) glc(none) `addcustom')"'
				}
			}
			else {		// Process ticklists: these are easier as no labels
				if `"``xab'opt'"'!=`""' {
					local `xab'opt `"`xop'( __DUMMY__ , tlc(none) glc(none) `addcustom')"'
				}
			}
		}
	}
	
	
	* Parse `range' and `cirange'
	// in both cases, "min" and "max" refer to range of data in terms of LCI, UCI
	// (that is, initial values of `DXmin', `DXmax')
	foreach op in range cirange {
		if `"``op''"'==`""' continue
		local opmin = cond("`op'"=="range", "RXmin", "CXmin")
		local opmax = cond("`op'"=="range", "RXmax", "CXmax") 
		
		tokenize `"``op''"'
		cap {
			assert `"`2'"'!=`""'
			assert `"`3'"'==`""'
		}
		if _rc {
			disp as err `"option {bf:`op'()} must contain exactly two elements"'
			exit 198
		}
		
		// if "min", "max" used
		if inlist(`"`1'"', "min", "max") | inlist(`"`2'"', "min", "max") {
			if `"`eform'"'!=`""' {
				forvalues i=1/2 {
					cap confirm number ``i''
					if !_rc local `i' = ln(``i'')
				}
			}
			local `op' `"`1' `2'"'
			local `op' = subinstr(`"``op''"', `"min"', `"`DXmin'"', .)
			local `op' = subinstr(`"``op''"', `"max"', `"`DXmax'"', .)
			numlist `"``op''"', min(2) max(2) sort
			local `op' = r(numlist)
			tokenize `"``op''"'
			args `opmin' `opmax'
		}	
		
		else {
			if `"`eform'"'!=`""' {
				numlist `"``op''"', min(2) max(2) range(>0) sort
				local `op' `"`=ln(`1')' `=ln(`2')'"'
			}
			else {
				numlist `"``op''"', min(2) max(2) sort
				local `op' = r(numlist)
			}
			tokenize `"``op''"'
			args `opmin' `opmax'
		}
	}
	
	// "force" option
	if trim(`"`CRXmin'`CRXmax'"')!=`""' {
		if `"`range'"'==`""' {				// if `range' not specified, default to "forced" xlab limits
			local RXmin = `CRXmin'
			local RXmax = `CRXmax'
			local range = trim(`"`CRXmin' `CRXmax'"')
		}
		else {				// otherwise, set `cirange' instead (see message above)
			local CXmin = `CRXmin'
			local CXmax = `CRXmax'
			local cirange = trim(`"`CRXmin' `CRXmax'"')
		}
	}
	
	* Check validity of user-defined values
	if `"`range'"'!=`""' & `"`cirange'"'!=`""' {
		cap {
			assert `RXmin' <= `CXmin'
			assert `RXmax' >= `CXmax'
		}
		if _rc {
			disp as err "interval defined by {opt cirange()} (or {bf:xlabel(, force)}) must lie within that defined by {opt range()}"
			exit 198
		}
	}

	// changed Sep 2017 for v2.1
	else if `"`cirange'"'==`""' & `"`range'"'!=`""' {
		local CXmin = max(`RXmin', `DXmin')
		local CXmax = min(`RXmax', `DXmax')
	}
	
	// Jan 2018: Now re-set DXmin/DXmax if RXmin/RXmax are defined
	// CHECK CONSEQUENCES OF THIS CAREFULLY
	if trim(`"`RXmin'`RXmax'"')!=`""' {
		local DXmin = `RXmin'
		local DXmax = `RXmax'
	}
	
	// remove null line if lies outside range of x values to be plotted
	if `"`null'"'==`""' & trim(`"`cirange'`range'`forceopt'"')!=`""' {
		local removeNull = 0
		if `"`cirange'"'!=`""' local removeNull = (`h0' < `CXmin' | `h0' > `CXmax')
		else                   local removeNull = (`h0' < `RXmin' | `h0' > `RXmax')
		if `removeNull' {
			nois disp as err "null line lies outside of user-specified x-axis range and will be suppressed"
			local null nonull
		}
	}
	return local null `null'

	
	* Apply automated values if -xlabel- not supplied by user
	// MAY 2024: Note: if xmlabel() is used, AutoXLabel is still potentially run; this matches with standard -twoway- behaviour
	local xlablim1 = 0		// init
	local xlablist_all `"`xlablist' `xlablist2'"'
	local xlablist_all : list uniq xlablist_all
	if inlist(`"`xlablist_all'"', `"none"', `"."', `"none ."', `". none"') local xlablist_all none
	if `"`xlablist_all'"'==`""' {
		AutoXLabel `DXmin' `DXmax', range(`range') `eform' format(`use_format') h0(`h0') `null' `denominator'
		
		local DXmin = `r(DXmin)'
		local DXmax  = `r(DXmax)'
		local xlablim1 = `r(xlablim1)'
		
		local xlablist `"`r(xlablist)'"'
		local xlabopt `"`r(xlabopt)' `xlabopt'"'
		
		// Added Feb 2018: If automatic labelling, set rows to 1 (rowsxmlab remains at 0)
		local rowsxlab = 1
		if `"`colsonly'"'!=`""' local xlabopt `"xlabel(__DUMMY__ `" "', tlc(none) glc(none))"'
	}		// end if "`xlablist'" == ""
		
	// Final parsing of x-axis labelling quantities (excluding "favours" and [xab]list2/newadd ), to form `XLmin' `XLmax'
	local xlablist_all `"`xlablist' `xticklist' `xmticklist'"'
	local xlablist_all : list uniq xlablist_all
	if inlist(`"`xlablist_all'"', `"none"', `"."', `"none ."', `". none"') local xlablist_all none
	cap assert `"`xlablist_all'"'!=`""'
	if _rc {
		disp as err "Something has gone wrong with x-axis value labelling"
		exit 198
	}
	if `"`xlablist_all'"'==`"none"' {
		local XLmin = `h0'
		local XLmax = `h0'
	}
	else {
		numlist `"`xlablist' `xticklist' `xmticklist'"', sort
		local n : word count `r(numlist)' 
		local XLmin : word 1 of `r(numlist)'
		local XLmax : word `n' of `r(numlist)'
	}
	
	* Use symmetrical plot area (around `h0'), unless data "too far" from null
	if trim(`"`range'`cirange'`forceopt'"')==`""' {

		// if "too far", adjust `CXmin' and/or `CXmax' to reflect this
		//   where "too far" ==> max(abs(`CXmin'-`h0'), abs(`CXmax'-`h0')) > `CXmax' - `CXmin'
		local TooFar = 0
		if "`null'"=="" | `h0' != 0 {		
			if `h0' - `DXmax' > `DXmax' - `DXmin' {							// data "too far" to the left
				local DXmax = max(`h0' + .5*(`DXmax'-`DXmin'), `XLmax')		// clip the right-hand side
				local TooFar = 1
			}	
			if `DXmin' - `h0' > `DXmax' - `DXmin' {							// data "too far" to the right
				local DXmin = min(`h0' - .5*(`DXmax'-`DXmin'), `XLmin')		// clip the left-hand side
				local TooFar = 1
			}
		}
		if `TooFar' {
			local DXmin = -max(abs(`DXmin'), abs(`DXmax'))
			local DXmax =  max(abs(`DXmin'), abs(`DXmax'))
		}
	}
	
	* Final calculation of DXmin, DXmax
	if trim(`"`RXmin'`RXmax'"')!=`""' {
		numlist `"`RXmin' `RXmax'"', sort
	}
	else {
		numlist `"`DXmin' `DXmax' `XLmin' `XLmax'"', sort
	}
	local n : word count `r(numlist)' 
	local DXmin : word 1 of `r(numlist)'
	local DXmax : word `n' of `r(numlist)'
	
	if trim(`"`CXmin'`CXmax'"')==`""' {
		local CXmin = `DXmin'
		local CXmax = `DXmax'
	}	
	
	
	* Now parse `favours' option
	*  - Use similar approach to x[m]label, and ultimately translate into an additional xmlabel option
	*  - Calculate no. of rows in case of `colsonly'
	local rowsfav = 0
	if `"`favours'"' != `""' {
		local oldfp : copy local fp	
		local 0 `"`favours'"'
		syntax [anything(everything)] [, FP(string) noSYMmetric /// /* these two are needed right now, others parsed simply to isolate inappropriate options */
			FORMAT(string) ANGLE(string) LABGAP(string) LABSTYLE(string) LABSize(string) LABColor(string) noSYMmetric * ]
		if `"`oldfp'"'!=`""' local fp : copy local oldfp
		if `"`options'"' != `""' {
			nois disp as err `"inappropriate suboptions found in {bf:favours()}"'
			exit 198
		}
		
		* Parse text, and count how many rows of text there are (i.e. separated with pairs of quotes)
		local rowsleftfav = 0
		local rowsrightfav = 0

		gettoken leftfav rest : anything, parse("#") quotes		
		if `"`leftfav'"'!=`"#"' {
			while `"`rest'"'!=`""' {
				local ++rowsleftfav
				gettoken next rest : rest, parse("#") quotes
				if `"`next'"'==`"#"' continue, break
				local leftfav `"`leftfav' `next'"'
			}
		}
		else local leftfav `""'		
		local rightfav = trim(`"`rest'"')
		if `"`rightfav'"'!=`""' {
			while `"`rest'"'!=`""' {
				local ++rowsrightfav
				gettoken next rest : rest, quotes
			}
		}
		local rowsfav = max(1, `rowsleftfav', `rowsrightfav')

		// Feb 2021: Remove quotes if only a single line
		if `rowsleftfav'==1 {
		    gettoken new : leftfav, qed(qed)
			if `qed' local leftfav : copy local new
		}
		if `rowsrightfav'==1 {
		    gettoken new : rightfav, qed(qed)
			if `qed' local rightfav : copy local new
		}

		// modified Jan 30th 2018, and again May 21st 2018
		if `"`fp'"'==`""' {
			// August 2018: default is...
			// May 2018: use smaller of distances from h0 to min(DXmin, XLmin) or max(DXmax, XLmax)
			local fpmin = min(`DXmin', `XLmin')
			local fpmax = max(`DXmax', `XLmax')
			
			if `"`symmetric'"'==`""' {
				local fp =  min(cond(`fpmin' <= `h0' & `"`leftfav'"'!=`""',  (`h0' - `fpmin')/2, .), ///
								cond(`fpmax' >= `h0' & `"`rightfav'"'!=`""', (`fpmax' - `h0')/2, .))
				local leftfp  = cond(`fpmin' <= `h0' & `"`leftfav'"'!=`""',  `"`=`h0' - `fp'' `"`leftfav'"'"',  `""')
				local rightfp = cond(`fpmax' >= `h0' & `"`rightfav'"'!=`""', `"`=`h0' + `fp'' `"`rightfav'"'"', `""')
			}
			
			// ...but may be overruled with option `nosymmetric', e.g. if distances are extremely unbalanced
			else {
				local leftfp  = cond(`fpmin' <= `h0' & `"`leftfav'"'!=`""',  `"`=(`h0' + `fpmin')/2' `"`leftfav'"'"',  `""')
				local rightfp = cond(`fpmax' >= `h0' & `"`rightfav'"'!=`""', `"`=(`h0' + `fpmax')/2' `"`rightfav'"'"', `""')
			}
		}
		
		// modified Jan 2020
		// User-specified fp()
		else {
			numlist `"`fp'"', miss max(2)
			tokenize `fp'
			args fpleft fpright
			if `"`eform'"'!=`""' local fpleft = ln(`fpleft')			// fp() should be given on same scale as xlabels

			if `"`fpright'"'==`""' {		// only one value given
				local fpleft  = cond(`fpleft' <= `h0', `fpleft', 2*`h0' - `fpleft')
				local fpright = 2*`h0' - `fpleft'
			}
			else {		// two values given: should be one either side of null line)
				cap assert `fpleft' <= `h0'
				if _rc {
					if `h0' != 0 local extra `" (`h0')"'
					nois disp as err `"Error in {bf:fp()}: left-hand value should lie to the left of the null value`extra'"'
					exit 198
				}
				cap assert `fpright' >= `h0'
				if _rc {
					if `h0' != 0 local extra `" (`h0')"'
					nois disp as err `"Error in {bf:fp()}: right-hand value should lie to the right of the null value`extra'"'
					exit 198
				}
			}
			local leftfp  `fpleft' `"`leftfav'"'
			local rightfp `fpright' `"`rightfav'"'
		}

		// Nov 2017 [modified Feb 2018]
		assert (`rowsfav'>0) == (trim(`"`leftfp'`rightfp'"')!=`""')
		if `rowsfav' {
			if `"`colsonly'"'!=`""' {
				forvalues i=1/`rowsfav' {
					local favtxt `"`favtxt' `" "'"'
				}
				if `rowsfav' > 1 local favtxt `"`"`favtxt'"'"'
				local dummy __DUMMY__
			}
			else local favtxt `leftfp' `rightfp'
			local favopt `"xmlabel(`dummy' `favtxt', tlc(none) glc(none) favours `addcustom' `favopt')"'		
		}
	}		
	
	// Position of xtitle [May 2024: not currently implemented]
	local xtitleval = cond("`xlablist'"=="", `xlablim1', .5*(`CXmin' + `CXmax'))
	return scalar xtitleval = `xtitleval'	
	
	// Return scalars
	return scalar CXmin = `CXmin'
	return scalar CXmax = `CXmax'
	return scalar DXmin = `DXmin'
	return scalar DXmax = `DXmax'
	
	// moved Feb 2018; modified Oct 2018; modified May 2024
	return scalar rowsxlab  = `rowsxlab'
	return scalar rowsxmlab = `rowsxmlab'
	return scalar rowsfav   = `rowsfav'

	return local xlabopt   `"`xlabopt'"'
	return local xmlabopt  `"`xmlabopt'"'
	return local favopt    `"`favopt'"'
	return local xtickopt  `"`xtickopt'"'
	return local xmtickopt `"`xmtickopt'"'
	
	// New May 2024: for use with `colsonly'
	return local xlabopt2   `"`xlabopt2'"'
	return local xmlabopt2  `"`xmlabopt2'"'
	return local xtickopt2  `"`xtickopt2'"'
	return local xmtickopt2 `"`xmtickopt2'"'	

	return local options `"`graphopts'"'

end


* ParseOldXLabel: Initial parse of xlabel and xtick, in case old (v3.x and earlier) syntax is used
// (with comma-separated values and no sub-options)
// Originally written May 2020; moved into separate subroutine May 2024
// subroutine of ProcessXAxis
program define ParseOldXLabel, rclass

	syntax [anything(name=xlabcmd)], XOP(string) /*for error messages*/ [ H0(real 0) EFORM FORCE noTWOWAYNOTE ]

	local done = 0
	local comma = 0
	local csv = 1
	local lblcmd
	tokenize `xlabcmd', parse(",")

	if inlist(`"`1'"', `"none"', `"minmax"') | substr(`"`1'"', 1, 1)==`"#"' {
		gettoken xlablist : xlabcmd		// return original xlabel option as-is; presumably using modern Stata -twoway- syntax
	}
	else {
		while `"`1'"' != `""' {
			cap confirm number `1'
			if !_rc {
				if `"`2'"'==`""' & `"`lblcmd'"'==`""' local csv = 0
				local lblcmd `"`lblcmd' `1'"'
			}
			else {
				cap assert `"`1'"'==`","'
				if !_rc local comma = 1
				else local csv = 0
			}
			mac shift
		}
		if `csv' {		// originally a comma-separated list of numbers; but now commas replaced by spaces
			if `"`lblcmd'"'!=`""' {
				capture numlist `"`lblcmd'"'
				if _rc {
					nois disp as err `"error in option {bf:`xlname'()}: invalid numlist"'
					exit _rc
				}
				local xlablist = r(numlist)

				if `comma' {										
					// [Oct 2020:] If `h0' is absent, add it back in.
					// Previous versions of -metan- added h0 by default (unless "nonull"), so that e.g. "xlabel(.1, 10) eform" would result in .1, 1 and 10 being marked.
					// With the "new" syntax based on standard -twoway- options, `h0' needs to be included in xlabel() in order for it to appear.					
					if `"`null'"'==`""' {
						local newh0 = cond(`"`eform'"'!=`""', exp(`h0'), `h0')
						if !`: list newh0 in xlablist' local xlablist `xlablist' `newh0'
					}
					numlist `"`xlablist'"', sort
					local xlablist = r(numlist)
					
					if !`done' & `"`twowaynote'"'==`""' {
						nois disp as err _n `"Note: with {bf:metan} version 4 and above, the preferred syntax is for {bf:`xop'()}"'
						nois disp as err `" to contain a standard Stata numlist, so e.g. {bf:`xop'(`xlablist')}; see {help numlist:help numlist}"'
					}
					local done = 1
					c_local twowaynote notwowaynote		// so that -metan- does not print an additional message regarding "force"
				}
			}
		}
		else gettoken xlablist : xlabcmd		// return original xlabel option as-is; presumably using modern Stata -twoway- syntax

		// convert legacy -force- option into modern twoway xlabel option
		if `"`xop'"'==`"xlabel"' & `"`force'"'!=`""' & `csv' {
			if `done' local xlablist `"`xlablist', force"'
			else {
				if `"`xlablist'"'==`""' {
					nois disp as err `"main option {bf:force} not allowed without {bf:xlabel()}"'
				}
				else nois disp as err `"option {bf:force} only allowed as a suboption to {bf:xlabel()}"'
				exit 198
			}
			c_local twowaynote notwowaynote		// so that -metan- does not print an additional message regarding "force"
		}
	}
	
	return local xlablist `"`xlablist'"'

end


* ProcessXLabels: Parse user-specified x[m]label() and x[m]tick() options
// Moved into separate subroutine May 2024; now also handles repeated options
// subroutine of ProcessXAxis
program define ProcessXLabels, rclass
	
	syntax [anything(name=xlabcmd)], XOP(string) /*for error messages*/ DX(numlist min=2 max=2) /*in case of "minmax" rule*/ ///
		[ EFORM COLSONLY FORMAT(string) /*KEEPXLabs*/ ]

	local rows = 0	// init
		
	// First, look at ticks; these are easier (no labels!)
	if inlist("`xop'", "xtick", "xmtick") {
		if `"`xlabcmd'"'!=`""' {
			cap numlist `"`xlabcmd'"'
			if _rc {
				disp as err `"invalid label specifier, : `xlabcmd'"'
				exit 198
			}
			if `"`eform'"'!=`""' {						// assume given on exponentiated scale if "eform" specified, so need to take logs
				cap numlist "`xlabcmd'", range(>0)		// ...in which case, all values must be greater than zero
				if _rc {
					disp as err `"option {bf:eform} specified, but {bf:`xop'()} contains non-positive values"'
					exit 198
				}
				local exlabcmd `"`xlabcmd'"'
				local xlabcmd
				foreach xi of numlist `exlabcmd' {
					local xlabcmd `"`xlabcmd' `=ln(`xi')'"'
				}
			}
			local newxlabcmd: copy local xlabcmd	// to match with code further down
			local xlablist: copy local xlabcmd		// to match with code further down
		}
	}
	// end of ticks
	
	else {
		local rest : copy local xlabcmd
		while `"`rest'"'!=`""' | `"`lbl'"'!=`""' {			// Feb 2018: added the second part of this stmt
			if `"`lbl'"'!=`""' local lbl2 `"`lbl'"'			// Nov 2017: user-specified labels need to go round the loop once, before being applied
			local lbl
			
			gettoken tok rest : rest, qed(qed)
			if `"`tok'"'!=`""' {
			
				// if text label found, check for embedded quotes (i.e. multiple lines)
				if `qed' {
					local rest2 `"`"`tok'"'"'
					gettoken el : rest2, qed(qed2)
					if !`qed2' {
						disp as err `"invalid label specifier, : ``xl'list':"'
						exit 198
					}
					local newxlabcmd `"`newxlabcmd' `rest2'"'
					local newlist
					local rest2 : copy local el
					while `"`rest2'"'!=`""' {
						gettoken el rest3 : rest2, quotes
						if `"`el'"'==`"`""'"' {
							// local newlist : list rest2 - el	// modified Feb 2018; check
							continue, break
						}
						local newlist `"`newlist' `el'"'
						local rest2 `"`rest3'"'
					}
					local rows = max(`rows', `: word count `newlist'')
					local lbl2				
				}	// end if `qed'
				
				// else, check if valid numlist
				else {
					if substr(`"`tok'"', 1, 1)==`"#"' {
						local hash `"#"'
						if substr(`"`tok'"', 2, 1)==`"#"' local hash `"##"'
						disp as err `"Cannot use the {bf:`hash'}# syntax in the {bf:`xop'()} option of {bf:forestplot}; please use a {it:numlist} instead"'
						exit 198
					}
					if inlist(`"`tok'"', `"none"', `"."') local rule_none : copy local tok
					else {
						if `"`tok'"'==`"minmax"' local tok `DXmin' `DXmax'
						numlist `"`tok'"'
						local rows = max(`rows', 1)

						if `"`eform'"'!=`""' {
							cap numlist `"`tok'"', range(>0)
							if _rc {
								disp as err `"option {bf:eform} specified, but {bf:`xop'()} contains non-positive values"'
								exit 198
							}
						
							// if eform, need to expand numlist and take logs
							local nl = r(numlist)
							local N : word count `nl'
							forvalues i=1/`N' {
								local el : word `i' of `nl'
								local xlablist `"`xlablist' `=ln(`el')'"'
								local newxli `"`=ln(`el')'"'
								
								local lbl = cond("`format'"=="", string(`el'), string(`el', "`format'"))
								if `i'==1 & `"`lbl2'"'!=`""' local newxli `"`"`lbl2'"' `newxli'"'
								if `i'<`N'                   local newxli `"`newxli' `"`lbl'"'"'
								local lbl2
								// don't add the last label yet, in case user has specified their own label
								
								local newxlabcmd `"`newxlabcmd' `newxli'"'
							}
						}
					
						// else, can simply add unexpanded numlist
						else {
							local xlablist `"`xlablist' `tok'"'
							local newxlabcmd `"`newxlabcmd' `tok'"'
							local lbl2
						}
					}
				}		// end else
			}		// end if `"`tok'"'!=`""'
				
			// if lbl, add it now
			if `"`lbl2'"'!=`""' {
				local newxlabcmd `"`newxlabcmd' `"`lbl2'"'"'
				local lbl
				local lbl2
			}

		}	// end while loop
	}		// end else (if not ticks)
	
	local xlablist = trim(`"`rule_none' `xlablist'"')
	local xlabcmd = trim(`"`rule_none' `newxlabcmd'"')

	cap assert `"`xlabcmd'"'==`""' if `"`xlablist'"'==`""'
	if _rc {
		disp as err "Error in {bf:`xop'()}"
		exit 198
	}

	return local xlablist `"`xlablist'"'
	return local xlabcmd `"`xlabcmd'"'		// Note: xlabcmd and xlablist should be identical except that xlabcmd may also have labels
	
	return scalar rows = `rows'
end


* AutoXLabel: If xlabel not supplied by user, choose sensible values.
// Default is for symmetrical limits, with 3 labelled values including null
// N.B. First modified from original -metan- code by DF, March 2013
//  with further improvements by DF, January 2015
// Modifed April 2017 to avoid interminable looping if [base]^`mag' = missing
// Modified & renamed May 2024
// subroutine of ProcessXAxis
program define AutoXLabel, rclass

	syntax anything [, RANGE(numlist min=2 max=2) EFORM FORMAT(string) H0(real 0) noNULL FORCE DENOMinator(string) ]
	tokenize `anything'
	args DXmin DXmax
	tokenize `range'
	args RXmin RXmax

	local xlablim1 = 0	// init
	
	// [Mar 2020] If `proportion', simply choose 0, .5 and 1 ... [Mar 2021] multiplied by `denominator'
	// [Apr 2021] ... but only if `range' not specified and smaller than DXmin/DXmax
	if "`denominator'"!="" {
		cap confirm number `denominator'
		if _rc {
			nois disp as err `"`denominator' found where number expected in option {bf:denominator(#)}"'
			exit 198
		}
		
		local xlablist
		if `"`range'"'!=`""' {
			local ii = max(`RXmin', 0)
			local xlablist `"`xlablist' `ii'"'
			local ii = min(`RXmax', `denominator')
			local xlablist `"`xlablist' `ii'"'
		}
		else {
			foreach i of numlist 0 .5 1 {
				local ii = `denominator' * `i'
				local xlablist `"`xlablist' `ii'"'
			}
		}
		local xlabopt `"`xlablist'"'
	}
	else {

		// If null line, choose values based around `h0'
		// (i.e. `xlabinit1' = `h0'... but `h0' is automatically selected anyway so no need to explicitly define `xlabinit1')
		if "`null'" == "" | `h0' != 0 {		// [N.B. "h0 != 0" added Jan 2020]
			local xlabinit2 = max(abs(`DXmin' - `h0'), abs(`DXmax' - `h0'))
			local xlabinit "`xlabinit2'"
		}
		
		// if `nulloff', choose values in two stages: firstly based on the midpoint between CXmin and CXmax (`xlab[init|lim]1')
		//  and then based on the difference between CXmin/CXmax and the midpoint (`xlab[init|lim]2')
		else {
			local xlabinit1 = (`DXmax' + `DXmin')/2
			local xlabinit2 = abs(`DXmax' - `xlabinit1')		// N.B. same as abs(`CXmin' - `xlabinit1')
			if float(`xlabinit1') != 0 {
				local xlabinit "`=abs(`xlabinit1')' `xlabinit2'"
			}
			else local xlabinit `xlabinit2'
		}
		assert "`xlabinit'"!=""
		assert "`xlabinit2'"!=""
		assert `: word count `xlabinit'' == ("`null'"!="" & `h0'==0)*(float(`DXmax')!=-float(`DXmin')) + 1		// should be >= 1
		
		local counter = 1
		foreach xval of numlist `xlabinit' {
		
			if `"`eform'"'==`""' {						// linear scale
				local mag = floor(log10(`xval'))
				local xdiff = abs(`xval'-`mag')
				foreach i of numlist 1 2 5 10 {
					local ii = `i' * 10^`mag'
					if missing(`mag') local ii = 0		// March 2021: catch extreme case
					if missing(`ii') {
						local ii = `=`i'-1' * 10^`mag'
						local xdiff = abs(float(`xval' - `ii'))
						local xlablim = `ii'
						continue, break
					}
					else if abs(float(`xval' - `ii')) <= float(`xdiff') {
						local xdiff = abs(float(`xval' - `ii'))
						local xlablim = `ii'
					}
				}
			}
			else {										// log scale
				local mag = round(`xval'/ln(2))
				local xdiff = abs(`xval' - ln(2))
				forvalues i=1/`mag' {
					local ii = ln(2^`i')
					if missing(`ii') {
						local ii = ln(2^`=`i'-1')
						local xdiff = abs(float(`xval' - `ii'))
						local xlablim = `ii'
						continue, break
					}
					else if abs(float(`xval' - `ii')) <= float(`xdiff') {
						local xdiff = abs(float(`xval' - `ii'))
						local xlablim = `ii'
					}
				}
				
				// if effect is small, use 1.5, 1.33, 1.25 or 1.11 instead, as appropriate
				foreach i of numlist 1.5 `=1/0.75' 1.25 `=1/0.9' {
					local ii = ln(`i')
					if abs(float(`xval' - `ii')) <= float(`xdiff') {
						local xdiff = abs(float(`xval' - `ii'))
						local xlablim = `ii'
					}
				}	
			}
			
			// if nonull, center limits around `xlablim1', which should have been optimized by the above code
			if "`null'" != "" & `h0'==0 {		// nonull
				if `counter'==1 {
					local xlablim1 = `xlablim'*sign(`xlabinit1')
				}
				if `counter'>1 | `: word count `xlabinit''==1 {
					local xlablim2 = `xlablim'
					local xlablims `"`=`xlablim1'+`xlablim2'' `=`xlablim1'-`xlablim2''"'
				}
			}
			else local xlablims `"`xlablims' `xlablim'"'
			local ++counter

		}	// end foreach xval of numlist `xlabinit'
			
		// if nulloff, don't recalculate CXmin/CXmax
		if "`null'" != "" & `h0'==0 numlist `"`xlablim1' `xlablims'"'
		else {
			numlist `"`=`h0' - `xlablims'' `h0' `=`h0' + `xlablims''"', sort	// default: limits symmetrical about `h0'
			tokenize `"`r(numlist)'"'

			// if data are "too far" from null (`h0'), take one limit (but not the other) plus null
			//   where "too far" ==> abs(`CXmin' - `h0') > `CXmax' - `CXmin'
			//   (this works whether data are "too far" to the left OR right, since our limits are symmetrical about `h0')
			if abs(`DXmin' - `h0') > `DXmax' - `DXmin' {
				if `3' > `DXmax'      numlist `"`1' `h0'"'
				else if `1' < `DXmin' numlist `"`h0' `3'"'
			}
			else if trim("`range'`cirange'`forceopt'")=="" {		// "standard" situation
				numlist `"`1' `h0' `3'"'
				local DXmin = `h0' - `xlabinit2'
				local DXmax = `h0' + `xlabinit2'
			}
		}
		local xlablist=r(numlist)
	}
		
	// if log scale, label with exponentiated values
	local xlabopt `"`xlablist'"'
	if `"`eform'"'!=`""' {
		local xlabopt
		foreach xi of numlist `xlablist' {
			local lbl = cond("`format'"=="", string(exp(`xi')), string(exp(`xi'), "`format'"))
			local xlabopt `"`xlabopt' `xi' `"`lbl'"'"'				
		}
	}

	return scalar DXmin = `DXmin'
	return scalar DXmax = `DXmax'
	return scalar xlablim1 = `xlablim1'
	
	return local xlablist `"`xlablist'"'
	return local xlabopt `"xlabel(`xlabopt')"'

end

// End of subroutines of ProcessXAXis


	
*********************************************************************************

* Process left and right columns -- obtain co-ordinates etc.
program define ProcessColumns, rclass

	syntax varlist(min=1 max=2) [if] [in], ID(varname numeric) LRCOLSN(numlist integer >=0) LCIMIN(real) DX(numlist min=2 max=2) ///
		[LVALlist(namelist) LLABlist(varlist) LFMTLIST(string) ///
		 RVALlist(namelist) RLABlist(varlist) RFMTLIST(string) RFINDENT(varname) RFCOL(integer 1) ///
		 DXWIDTHChars(real -9) ASText(integer -9) LBUFfer(real 0) RBUFfer(real 1) ///
		 noADJust noLCOLSCHeck TArget(integer 0) MAXWidth(integer 0) MAXLines(integer 0) noTRUNCate noWT DOUBLE COLSONLY * ]
	
	local graphopts `"`options' `double'"'
	
	marksample touse, novarlist
	
	// rename and unpack
	local DXwidthChars : copy local dxwidthchars

	tokenize `varlist'
	args _USE _EFFECT		// Oct 2020: _EFFECT is only used if `double', to prevent doubling of _EFFECT variable

	tokenize `lrcolsn'
	args lcolsN rcolsN
	
	tokenize `dx'
	args DXmin DXmax
	
	tempvar strlen strwid
	local digitwid : _length 0		// width of a digit (e.g. "0") in current graphics font = roughly average non-space character width
	local spacewid : _length " "	// width of a space in current graphics font

	summ `id' if `touse', meanonly
	assert r(min)==1
	local maxid = r(max)
	local multip = 1
	local add = 0

	quietly {
		// Apr 2020
		// DOUBLE LINE OPTION
		if `"`double'"'!=`""' & (`lcolsN' + `rcolsN' - ("`_EFFECT'"!="") - ("`wt'"=="")) {
			tempvar expand
			expand 2 if `touse' & inlist(`_USE', 1, 2), gen(`expand')
			replace `_USE' = 6 if `touse' & `expand'
			
			// TITLES CLOSER TOGETHER, GAP BENEATH
			local multip = 0.45
			local add = 0.5
		}
		local maxN = _N
		
		
		** Left columns
		local leftWDtot = 0
		local nlines = 0
		forvalues i = 1 / `lcolsN' {
			local leftLB`i' : word `i' of `llablist'
			local fmtlen    : word `i' of `lfmtlist'
			
			// Aug 2023: remove "~" symbol (centered format) if necessary
			tokenize `fmtlen', parse("~")
			if "`1'"=="~" local fmtlen `2'
			confirm integer number `fmtlen'
			
			gen long `strlen' = length(`leftLB`i'')
			summ `strlen' if `touse', meanonly
			local maxlen = r(max)		// max length of existing text

			// Apr 2020
			** DOUBLE LINE OPTION
			if `"`double'"'!=`""' {
			    forvalues j = 1 / `maxid' {
					summ `_USE' in `j', meanonly
					if inlist(`r(min)', 1, 2) {
						summ `id' in `j', meanonly
						local idj = r(min)
						local leftLBj = `leftLB`i''[`j']
						SpreadTitle `"`leftLBj'"', target(`=round(`maxlen'/2)') maxlines(2) notruncate
						replace `leftLB`i'' = `"`r(title1)'"' if `touse' & `id'==`idj' & !`expand'
						replace `leftLB`i'' = `"`r(title2)'"' if `touse' & `id'==`idj' & `expand'
					}
				}				
				getWidth `leftLB`i'' `strwid'
				summ `strwid' if `touse', meanonly
				local leftWD`i' = r(max)	// exact width of `maxlen' string
			}
			
			else {
				getWidth `leftLB`i'' `strwid'
				summ `strwid' if `touse', meanonly
				local maxwid = r(max)		// max width of existing text
				
				local leftWD`i' = cond(abs(`fmtlen') <= `maxlen', `maxwid', ///		// exact width of `maxlen' string
					abs(`fmtlen')*`digitwid')										// approx. max width (based on `digitwid')
			}

			
			** Check whether title string is longer than the data itself
			// If so, potentially allow spread over a suitable number of lines
			// [DF JAN 2015: Future work might be to re-write (incl. SpreadTitle) to use width rather than length??]

			// If more than one lcol, restrict to width of "data only" (i.e. _USE==1, 2).
			// Otherwise, title may be as long as the max string length in the column.
			// [Note that, as the title isn't stored as data (yet), the max string length does NOT account for the title string itself.]
			if `lcolsN' > 1 local anduse `"& inlist(`_USE', 1, 2)"'
			summ `strlen' if `touse' `anduse', meanonly
			local maxlen = r(max)
	
			local colName : variable label `leftLB`i''
			if `"`colName'"'!=`""' {

				if `target' <= 0 | missing(`target') {
					if `maxwidth' local target_opt = `maxwidth'
					else if "`double'"=="" {
						local target_opt = max(abs(`fmtlen'), `maxlen')
					}
					else local target_opt = `maxlen'
				}
				local maxwidth_opt = cond(`maxwidth', `maxwidth', `=2*`target_opt'')
				SpreadTitle `"`colName'"', target(`target_opt') maxwidth(`maxwidth_opt') maxlines(`maxlines') `truncate'
				
				if `r(nlines)' > `nlines' {
					local oldN = _N
					set obs `=`oldN' + `r(nlines)' - `nlines''
					local nlines = r(nlines)
					
					replace `_USE' = 9 if _n > `oldN'
					replace `touse' = 1 if _n > `oldN'
					replace `id' = `maxid' + (_n - `maxN')*`multip' + `add' + 1 if _n > `oldN'
					// "+1" leaves a one-line gap between titles & main data
				}
				
				local l = `nlines' - `r(nlines)'
				forvalues j = `r(nlines)'(-1)1 {
					local k = _N - (`j' + `l') + 1
					replace `leftLB`i'' = `"`r(title`j')'"' in `k'
				}
				
				getWidth `leftLB`i'' `strwid', replace			// re-calculate `strwid' to include titles

				summ `strwid' if `touse', meanonly
				local maxwid = r(max)
				local leftWD`i' = max(`leftWD`i'', `maxwid')	// in case title is necessarily longer than the variable, even after SpreadTitle
			}
			
			local leftWD`i' = `leftWD`i'' + (2 - (`i'==`lcolsN'))*`digitwid'	// having calculated the indent, add a buffer (2x except for last col)
			local leftWDtot = `leftWDtot' + `leftWD`i''							// running calculation of total width (including titles)
			
			drop `strlen' `strwid'
		}								// end of forvalues i=1/`lcolsN'
		
		
		** Right columns
		local rightWDtot = 0
		forvalues i=1/`rcolsN' {		// if `rcolsN'==0, loop will be skipped
			local rightLB`i' : word `i' of `rlablist'
			local fmtlen     : word `i' of `rfmtlist'

			// Aug 2023: remove "~" symbol (centered format) if necessary
			tokenize `fmtlen', parse("~")
			if "`1'"=="~" local fmtlen `2'
			confirm integer number `fmtlen'		
			
			gen long `strlen' = length(`rightLB`i'')
			summ `strlen' if `touse', meanonly
			local maxlen = r(max)		// max length of existing text

			// Apr 2020
			** DOUBLE LINE OPTION
			if `"`double'"'!=`""' {
			    forvalues j = 1 / `maxid' {
					summ `_USE' in `j', meanonly
					if inlist(`r(min)', 1, 2) {
						summ `id' in `j', meanonly
						local idj = r(min)
						local rightLBj = `rightLB`i''[`j']
						
						if `"`rightLB`i''"'!=`"`_EFFECT'"' {
							SpreadTitle `"`rightLBj'"', target(`=round(`maxlen'/2)') maxlines(2) notruncate
							replace `rightLB`i'' = `"`r(title1)'"' if `id'==`idj' & !`expand'
							replace `rightLB`i'' = `"`r(title2)'"' if `id'==`idj' & `expand'
						}
						else {		// Oct 2020: if _EFFECT, simply blank out the duplicated second line
							replace `rightLB`i'' = `""' if `id'==`idj' & `expand'							
						}
					}
				}
				getWidth `rightLB`i'' `strwid'
				summ `strwid' if `touse', meanonly
				local rightWD`i' = r(max)	// exact width of `maxlen' string
			}
			
			else {
				getWidth `rightLB`i'' `strwid'
				summ `strwid' if `touse', meanonly		
				local maxwid = r(max)		// max width of existing text

				local rightWD`i' = cond(abs(`fmtlen') <= `maxlen', `maxwid', ///	// exact width of `maxlen' string
					abs(`fmtlen')*`digitwid')										// approx. max width (based on `digitwid')
			}
			
			
			** Check whether title string is longer than the data itself
			// If so, spread it over a suitable number of lines
			// [DF JAN 2015: Future work might be to re-write (incl. SpreadTitle) to use width rather than length??]
			local colName : variable label `rightLB`i''
			if `"`colName'"'!=`""' {

				// June 2020
				// If _EFFECT column, make sure a line break is not placed in the middle of "(95% CI)"
				local ci_break = 0
				local strpos1 = strpos(`"`colName'"', `"("')
				local strpos2 = strpos(`"`colName'"', `"% CI)"')
				if `strpos2' & (`strpos2' - `strpos1' <= 3) {
				    local colName = subinstr(`"`colName'"', `"% CI)"', `"%_CI)"', 1)
					local ci_break = 1
				}
			
				if `target' <= 0 | missing(`target') {
					if `maxwidth' local target_opt = `maxwidth'
					else if "`double'"=="" {
						local target_opt = max(abs(`fmtlen'), `maxlen')
					}
					else local target_opt = `maxlen'
				}
				local maxwidth_opt = cond(`maxwidth', `maxwidth', `=2*`target_opt'')
				SpreadTitle `"`colName'"', target(`target_opt') maxwidth(`maxwidth_opt') maxlines(`maxlines') `truncate'

				if `r(nlines)' > `nlines' {
					local oldN = _N
					set obs `=`oldN' + `r(nlines)' - `nlines''
					local nlines = r(nlines)
					
					replace `_USE' = 9 if _n > `oldN'
					replace `touse' = 1 if _n > `oldN'
					replace `id' = `maxid' + (_n - `maxN')*`multip' + `add' + 1 if _n > `oldN'
					// "+1" leaves a one-line gap between titles & main data
				}
				
				local l = `nlines' - `r(nlines)'
				forvalues j = `r(nlines)'(-1)1 {
					local k = _N - (`j' + `l') + 1
					
					// June 2020
					// Reset the "(95% CI)" string, if appropriate
					local rtitlej `"`r(title`j')'"'
					if `ci_break' {
						local strpos1 = strpos(`"`rtitlej'"', `"("')
						local strpos2 = strpos(`"`rtitlej'"', `"%_CI)"')
						if `strpos2' & (`strpos2' - `strpos1' <= 3) {
							local rtitlej = subinstr(`"`rtitlej'"', `"%_CI)"', `"% CI)"', 1)
							local ci_break = 1
						}
					}
					replace `rightLB`i'' = `"`rtitlej'"' in `k'
				}
				
				getWidth `rightLB`i'' `strwid', replace			// re-calculate `strwid' to include titles
				
				summ `strwid' if `touse', meanonly
				local maxwid = r(max)
				local rightWD`i' = max(`rightWD`i'', `maxwid')		// in case title is necessarily longer than the variable, even after SpreadTitle
			}
			
			local rightWD`i' = `rightWD`i'' + (2 - (`i'==`rcolsN'))*`digitwid'		// having calculated the indent, add a buffer (2x except for last col)
			local rightWDtot = `rightWDtot' + `rightWD`i''							// running calculation of total width (incl. buffer)
			drop `strlen' `strwid'
		}								// end of forvalues i=1/`rcols'

		if !`rcolsN' & `"`colsonly'"'!=`""' local rightWDtot = 0		// if `colsonly', set to zero... [ADDED MAY 2024]
		else {
			local rightWDtot = `rightWDtot' + `rbuffer'*`digitwid'		// ...otherwise use a minimal buffer (default 1x but can be overwritten)
			local leftWDtot = max(`leftWDtot', `digitwid')				// ...before first RHS column and after last
		}

		
		** "Adjust" routine
		
		*  Notes:
		// Unless we're dealing with a very non-standard user-specific case,
		//   effect sizes corresponding to pooled diamonds (_USE==3, 5) will usually be much tighter around the null value than individual effects (_USE==1, 2).
		// The longest strings of text are also likely to be found in _USE==0, 3, 4, 5, since these contain subgroup headings and heterogeneity info.
		// Therefore, we may be able to improve the aesthetics of the plot by:
		//  (1) allowing text in LH columns for _USE==3, 5 to overlap text in LH columns for _USE==1, 2;
		//  (2) allowing text in LH columns for _USE==3, 5 to extend into the central plot area, beyond the default limit of `DXmin' but without overwriting plot elements.
		
		*  However, there are some considerations:
		// - LH text columns for _USE==1, 2 must *never* extend beyond `DXmin' (o/w long study labels and long CI limits might be overwritten)
		// - Column titles (i.e. variable labels; _USE==9) may only be extended for the last (i.e. right-most) left-hand column
		// - LH text columns for _USE==0, 3, 4, 5 may only be extended if there is no data in the remaining LH columns (if any) to their right
		// - In particular, if data exists in LH columns to the right, default behaviour is for "heterogeneity info" to be placed on a new line (_USE==4)
		//     rather than at the end of the "pooled overall/subgroup" text (_USE==3, 5).
		//     This may be overruled using `noextraline' with -(ad)metan- which implies `nolcolcheck' with -forestplot-
		// - _USE==6 represents a blank line, so these rows are irrelevant to the calculations.  The user may place text in such rows at their own discretion; it may get overwritten.
		
		*  Hence, the strategy is:
		// - Recalculate column widths (`leftWD`i'') restricting to _USE==1, 2, 9 (except last column, for which exclude _USE==9)
		// - BUT if a subsequent LH column has data in _USE==0, 3, 5 then previous adjustments are cancelled (unless `nolcolcheck')
		// - In this way, build up a recalculated total width (`leftWDtotNoTi').  If this is less than the original total (`leftWDtot'), then there is scope for "adjustment" (see below).

		if "`adjust'" == "" {

			// initialise locals
			local leftWDtotTi = 0
			local leftWDtotNoTi = 0
			// local adjustTot = 0
			// local adjustNew = 0
			
			// May 2018
			// If `nocolscheck', any lengthy text will be in _USE==4 rather than 3 or 5;  and such text should only exist in the first column so may be ignored

			// June 2018: this section re-written
			// Re-calculate widths of `lcols' for study estimates only (i.e. _USE==1, 2; this is `leftWD`i'NoTi')
			local lastcol = 1
			forvalues i=1/`lcolsN' {
				local fmtlen : word `i' of `lfmtlist'	// desired max no. of characters based on format -- also shows whether left- or right-justified

				// Aug 2023: remove "~" symbol (centered format) if necessary
				tokenize `fmtlen', parse("~")
				if "`1'"=="~" local fmtlen `2'
				
				// Check for data in observations *other* than study estimates (i.e. _USE==0, 3, 5, 7)
				// if there is, this becomes `lastcol'
				gen long `strlen' = length(`leftLB`i'')
				summ `strlen' if `touse' & inlist(`_USE', 0, 3, 5, 7), meanonly
				if r(N) & r(max) local lastcol = `i'

				// Now compare "total width" with "width for study estimates only" for current column only
				// (including titles, UNLESS last column of all (`lcolsN'); so that, if multiple columns, adjusted width of first column includes title
				//   and hence, second column doesn't obscure it)
				summ `strlen' if `touse' & (inlist(`_USE', 1, 2) | (`i'<`lcolsN' & `_USE'==9)), meanonly
				if !r(N) local leftWD`i'NoTi = 0		// if summary diamonds only (added Sep 2017 for v2.1)
				else {
					local maxlen = r(max)				// max length of text for study estimates only
					
					getWidth `leftLB`i'' `strwid'
					summ `strwid' if `touse' & (inlist(`_USE', 1, 2) | (`i'<`lcolsN' & `_USE'==9)), meanonly
					local maxwid = r(max)				// max width of text for study estimates only
					
					if "`double'"!="" local leftWD`i'NoTi = `maxwid'
					else {
						local leftWD`i'NoTi = cond(abs(`fmtlen') <= `maxlen', `maxwid', ///		// exact width of `maxlen' string
							abs(`fmtlen')*`digitwid')											// approx. max width (based on `digitwid')
					}
					// replace `lindent`i'NoTi' = cond(`fmtlen'>0, `leftWD`i'NoTi' - `strwid', 0)	// indent if right-justified
					drop `strwid'
				}
				local leftWD`i'NoTi = `leftWD`i'NoTi' + (2 - (`i'==`lcolsN'))*`digitwid'	// having calculated the indent, add a buffer (2x except for last col)
				
				drop `strlen'
			}
			
			// Finally, iterate `leftWDtotTi' ("unadjusted" widths up to and including `lastcol')
			//  and `leftWDtotNoTi' ("unadjusted" widths up to `lastcol', then "adjusted" widths)
			// Plus, if appropriate, cancel previous *single* adjustments
			//  (the above code only handles the running totals)
			if `"`lcolscheck'"'!=`""' local lastcol = 1
			forvalues i=1/`lcolsN' {
				if `i' < `lastcol' {
					local leftWD`i'NoTi = `leftWD`i''
					// replace `lindent`i'NoTi' = `lindent`i''
					local leftWDtotTi = `leftWDtotTi' + `leftWD`i''
				}
				else if `i' == `lastcol' {
					local leftWDtotTi = `leftWDtotTi' + `leftWD`i''
				}
				local leftWDtotNoTi = `leftWDtotNoTi' + `leftWD`i'NoTi'
			}
		
			// If appropriate, allow _USE=0,3,4,5 to extend into main plot by a factor of (lcimin-DXmin)/DXwidth
			//  where `lcimin' is the left-most confidence limit among the "diamonds" (including prediction intervals)
			// i.e. 1 + ((`lcimin'-`DXmin')/`DXwidth') * ((100-`astext')/`astext')) is the percentage increase
			// to apply to `leftWDtot'+`rightWDtot' in order to obtain `newleftWDtot'+`rightWDtot'.
			// Then rearrange to find `newleftWDtot'.
			if `leftWDtotNoTi' < `leftWDtot' {
			
				// June 2018:
				// Firstly, reset `leftWDtot'
				local leftWDtot = max(`leftWDtotTi', `leftWDtotNoTi')

				// sort out astext... need to do this now, but will be recalculated later (line 890)
				if `DXwidthChars'!=-9 & `astext'==-9 {
					local astext2 = (`leftWDtot' + `rightWDtot')/`DXwidthChars'
					local astext = 100 * `astext2'/(1 + `astext2')
				}
				else {
					local astext = cond(`astext'==-9, 50, `astext')
					assert `astext' >= 0
					local astext2 = `astext'/(100 - `astext')
				}
				
				// define some additional locals to make final formula clearer
				local totWD = `leftWDtot' + `rightWDtot'
				local lciWD = (`lcimin' - `DXmin')/(`DXmax' - `DXmin')
				local newleftWDtot = cond(`DXwidthChars'==-9, ///
					(`totWD' / ((`lciWD'/`astext2') + 1)) - `rightWDtot', ///
					`leftWDtot' - `lciWD'*`DXwidthChars')
					
				// Finally, reset `leftWDtot' once more
				// BUT don't make it any less than `leftWDtotNoTi', *unless* there are no obs with inlist(`_USE', 1, 2)
				// o/w longest study labels might overwrite longest CIs.
				count if `touse' & inlist(`_USE', 1, 2)
				local leftWDtot = cond(r(N), max(`leftWDtotNoTi', `newleftWDtot'), `newleftWDtot')
				
				// ...and similarly replace individual column widths
				forvalues i=1/`lcolsN' {
					local leftWD`i' = `leftWD`i'NoTi'
					// replace `lindent`i'' = `lindent`i'NoTi'
				}
			}
		}		// end if "`adjust'" == ""

		if !`lcolsN' & `"`colsonly'"'!=`""' local leftWDtot = 0			// if `colsonly', set to zero... [ADDED MAY 2024]
		else {
			local leftWDtot = `leftWDtot' + `lbuffer'*`digitwid'		// LHS buffer; default is zero
			local leftWDtot = max(`leftWDtot', `digitwid')				// ...otherwise use a minimal buffer for LHS of plotted data
		}
		
		// Calculate `textWD', using `astext' (% of graph width taken by text)
		//  to relate the width of plot area in "plot units" to the width of the columns in "text units"
		if `DXwidthChars'!=-9 & (`astext'==-9 | `"`newleftWDtot'"'!=`""') {
			local astext2 = (`leftWDtot' + `rightWDtot')/`DXwidthChars'
			local astext = 100 * `astext2'/(1 + `astext2')
			// local astext = cond(`DXwidthChars'>0, 100 * `astext2'/(1 + `astext2'), 100)		// added Feb 2018
		}
		else {
			local astext = cond(`astext'==-9, 50, `astext')
			assert `astext' >= 0
			local astext2 = `astext'/(100 - `astext')
		}
		local textWD = `astext2' * (`DXmax' - `DXmin')/(`leftWDtot' + `rightWDtot')

		// Generate positions of columns, in terms of "plot co-ordinates"
		// (N.B. although the "starting positions", `leftWD`i'' and `rightWD`i'', are constants, there will be indents if right-justified
		//      and anyway, all will need to be stored in variables for use with -twoway-)
		local leftWDruntot = 0
		forvalues i = 1/`lcolsN' {
			local left`i' : word `i' of `lvallist'		// extract next tempvar name from predefined list
			
			// June 2023: deprecate indentation in favour of use of mlabpos()
			local nextval = `DXmin' - (`leftWDtot' - `leftWDruntot')*`textWD'
			local leftWDruntot = `leftWDruntot' + `leftWD`i''	// iterate
			local nextpos 3
			gen double `left`i'' = `nextval'			// default, if left-justified

			// Aug 2023: allow centered formatting
			local fmtlen : word `i' of `lfmtlist'
			tokenize `fmtlen', parse("~")
			if "`1'"=="~" {
				// if centered, place halfway between this position and the next and use mlabpos(0)
				local nextnextval = `DXmin' - (`leftWDtot' - `leftWDruntot' + (2 - (`i'==`lcolsN'))*`digitwid')*`textWD'
				replace `left`i'' = (`left`i'' + `nextnextval')/2
				local nextpos 0
			}
			else if `fmtlen'>=0 {
				local nextnextval = `DXmin' - (`leftWDtot' - `leftWDruntot' + (2 - (`i'==`lcolsN'))*`digitwid')*`textWD'
				replace `left`i'' = `nextnextval'		// if right-justified; remove buffer from position value
				local nextpos 9
			}
			local lposlist `lposlist' `nextpos'
		}
		if !`lcolsN' {		// Added July 2015
			local left1 : word 1 of `lvallist'
			gen `left1' = `DXmin' - 2*`digitwid'*`textWD'
		}
		
		if `"`rfindent'"'!=`""' {
			tempvar rindent
			gen `rindent' = .
		}
		local rightWDruntot = `digitwid'		// initial 1x buffer
		forvalues i = 1/`rcolsN' {				// if `rcolsN'=0 then loop will be skipped
			local right`i' : word `i' of `rvallist'		// extract next tempvar name from predefined list
			
			// June 2023: deprecate indentation in favour of use of mlabpos()
			local nextval = `DXmax' + `rightWDruntot'*`textWD'
			local rightWDruntot = `rightWDruntot' + `rightWD`i''	// iterate
			local nextpos 3
			gen double `right`i'' = `nextval'			// default, if left-justified
			
			local fmtlen : word `i' of `rfmtlist'
			tokenize `fmtlen', parse("~")
			if "`1'"=="~" {
				// if centered, place halfway between this position and the next and use mlabpos(0)
				local nextnextval = `DXmax' + (`rightWDruntot' - (2 - (`i'==`rcolsN'))*`digitwid')*`textWD'
				replace `right`i'' = (`right`i'' + `nextnextval')/2
				local nextpos 0
			}

			// special case: if rfdist and left-justified, impose a small indent so that the CIs line up
			else if `"`rfindent'"'!=`""' & `i'==`rfcol' & `fmtlen'<0 {
				getWidth `rfindent' `rindent' if `touse' & !missing(`rfindent'), replace
				replace `right`i'' = `right`i'' + (`rindent' + `spacewid')*`textWD' if `touse' & !missing(`rfindent')
			}
			
			// if right-justified, obtain position of *next* column and use mlabpos(); but remove buffer from position value
			else if `fmtlen'>=0 {
				local nextnextval = `DXmax' + (`rightWDruntot' - (2 - (`i'==`rcolsN'))*`digitwid')*`textWD'
				replace `right`i'' = `nextnextval'
				local nextpos 9
			}
			
			local rposlist `rposlist' `nextpos'
		}		

		// Finish off `double'
		if `"`double'"'!=`""' {
			recast float `id' 
			replace `id' = `id' - 0.45 if `expand'==1
		}
	
	}		// end quietly
	
	
	// AXmin AXmax ARE THE OVERALL LEFT AND RIGHT COORDS
	summ `left1' if `touse', meanonly
	local AXmin = r(min)
	local AXmax = `DXmax' + `rightWDtot'*`textWD'
	
	return scalar leftWDtot = `leftWDtot'
	return scalar rightWDtot = `rightWDtot'
	return scalar AXmin = `AXmin'
	return scalar AXmax = `AXmax'
	return scalar astext = `astext'
	
	// June 2023
	return local lposlist `lposlist'
	return local rposlist `rposlist'
	
	return local graphopts `"`graphopts'"'

end


	

* Subroutine to "spread" titles out over multiple lines if appropriate
// Updated July 2014
// August 2016: identical program now used here, in admetan.ado, and in ipdover.ado
// May 2017: updated to accept substrings delineated by quotes (c.f. multi-line axis titles)
// August 2017: updated for better handling of maxlines()
// March 2018: updated to receive text in quotes, hence both avoiding parsing problems with commas, and maintaining spacing
// May 2018 and Nov 2018: updated truncation procedure

// subroutine of ProcessColumns

program define SpreadTitle, rclass

	syntax [anything(name=title id="title string")] [, TArget(integer 0) MAXWidth(integer 0) MAXLines(integer 0) noTRUNCate noUPDATE ]
	* Target = aim for this width, but allow expansion if alternative is wrapping "too early" (i.e before line is adequately filled)
	//         (may be replaced by `titlelen'/`maxlines' if `maxlines' and `notruncate' are also specified)
	* Maxwidth = absolute maximum width ... but will be increased if a "long" string is encountered before the last line
	* Maxlines = maximum no. lines (default 3)
	* noTruncate = don't truncate final line if "too long" (even if greater than `maxwidth')
	* noUpdate = don't update `target' if `maxwidth' is increased (see above)
	
	tokenize `title'
	if `"`1'"'==`""' {
		return scalar nlines = 0
		return scalar maxwidth = 0
		exit
	}
	
	if `maxwidth' & !`maxlines' {
		cap assert `maxwidth'>=`target'
		if _rc {
			nois disp as err `"{bf:maxwidth()} must be greater than or equal to {bf:target()}"'
			exit 198
		}
	}


	** Find length of title string, or maximum length of multi-line title string
	// First run: strip off outer quotes if necessary, but watch out for initial/final spaces!
	gettoken tok : title, qed(qed)
	cap assert `"`tok'"'==`"`1'"'
	if _rc {
		gettoken tok rest : tok, qed(qed)
		assert `"`tok'"'==`"`1'"'
		local title1 title1				// specifies that title is not multi-line
	}
	local currentlen = length(`"`1'"')
	local titlelen   = length(`"`1'"')
	
	// Subsequent runs: successive calls to -gettoken-, monitoring quotes with the qed() option
	macro shift
	while `"`1'"'!=`""' {
		local oldqed = `qed'
		gettoken tok rest : rest, qed(qed)
		assert `"`tok'"'==`"`1'"'
		if !`oldqed' & !`qed' local currentlen = `currentlen' + 1 + length(`"`1'"')
		else {
			local titlelen = max(`titlelen', `currentlen')
			local currentlen = length(`"`1'"')
		}
		macro shift
	}
	local titlelen = max(`titlelen', `currentlen')
	
	// Save user-specified parameter values separately
	local target_orig = `target'
	local maxwidth_orig = `maxwidth'
	local maxlines_orig = `maxlines'
	
	// Now finalise `target' and calculate `spread'
	local maxlines = cond(`maxlines_orig', `maxlines_orig', 3)	// use a default value for `maxlines' of 3 in these calculations
	local target = cond(`target_orig', `target_orig', ///
		cond(`maxwidth_orig', min(`maxwidth_orig', `titlelen'/`maxlines'), `titlelen'/`maxlines'))
	local spread = min(int(`titlelen'/`target') + 1, `maxlines')
	local crit = cond(`maxwidth_orig', min(`maxwidth_orig', `titlelen'/`spread'), `titlelen'/`spread')


	** If substrings are present, delineated by quotes, treat this as a line-break
	// Hence, need to first process each substring separately and obtain parameters,
	// then select the most appropriate overall parameters given the user-specified options,
	// and finally create the final line-by-line output strings.
	tokenize `title'
	local line = 1
	local title`line' : copy local 1				// i.e. `"`title`line''"'==`"`1'"'
	local newwidth = length(`"`title`line''"')

	// if first "word" is by itself longer than `maxwidth' ...
	if `maxwidth' & !(`maxlines' & (`line'==`maxlines')) {
	
		// ... reset parameters and start over
		while length(`"`1'"') > `maxwidth' {
			local maxwidth = length(`"`1'"')
			local target = cond(`target_orig', cond(`"`update'"'!=`""', `target_orig', `target_orig' + `maxwidth' - `maxwidth_orig'), ///
				cond(`maxwidth', min(`maxwidth', `titlelen'/`maxlines'), `titlelen'/`maxlines'))
			local spread = min(int(`titlelen'/`target') + 1, `maxlines')
			local crit = cond(`maxwidth', min(`maxwidth', `titlelen'/`spread'), `titlelen'/`spread')
		}
	}
	
	macro shift
	local next : copy local 1		// i.e. `"`next'"'==`"`1'"' (was `"`2'"' before macro shift!)
	while `"`1'"' != `""' {
		// local check = `"`title`line''"' + `" "' + `"`next'"'			// (potential) next iteration of `title`line''
		local check `"`title`line'' `next'"'							// (amended Apr 2018 due to local x = "" issue with version <13)
		if length(`"`check'"') > `crit' {								// if longer than ideal...
																		// ...and further from target than before, or greater than maxwidth
			if abs(length(`"`check'"') - `crit') > abs(length(`"`title`line''"') - `crit') ///
					| (`maxwidth' & (length(`"`check'"') > `maxwidth')) {
				if `maxlines' & (`line'==`maxlines') {					// if reached max no. of lines
					local title`line' : copy local check				//   - use next iteration anyway (to be truncated)

					macro shift
					local next : copy local 1
					local newwidth = max(`newwidth', length(`"`title`line''"'))		// update `newwidth'					
					continue, break
				}
				else {										// otherwise:
					local ++line							//  - new line
					
					// if first "word" of new line (i.e. `next') is by itself longer than `maxwidth' ...
					if `maxwidth' & (length(`"`next'"') > `maxwidth') {
					
						// ... if we're on the last line or last token, continue as normal ...
						if !((`maxlines' & (`line'==`maxlines')) | `"`2'"'==`""') {
						
							// ... but otherwise, reset parameters and start over
							local maxwidth = length(`"`next'"')
							local target = cond(`target_orig', cond(`"`update'"'!=`""', `target_orig', `target_orig' + `maxwidth' - `maxwidth_orig'), ///
								cond(`maxwidth', min(`maxwidth', `titlelen'/`maxlines'), `titlelen'/`maxlines'))
							local spread = min(int(`titlelen'/`target') + 1, `maxlines')
							local crit = cond(`maxwidth', min(`maxwidth', `titlelen'/`spread'), `titlelen'/`spread')
							
							// restart loop
							tokenize `title'
							local tok = 1
							local line = 1
							local title`line' : copy local 1				// i.e. `"`title`line''"'==`"`1'"'
							local newwidth = length(`"`title`line''"')
							macro shift
							local next : copy local 1		// i.e. `"`next'"'==`"`1'"' (was `"`2'"' before macro shift!)
							continue
						}
					}
					
					local title`line' : copy local next		//  - begin new line with next word
				}
			}
			else local title`line' : copy local check		// else use next iteration
			
		}
		else local title`line' : copy local check			// else use next iteration

		macro shift
		local next : copy local 1
		local newwidth = max(`newwidth', length(`"`title`line''"'))		// update `newwidth'
	}																	// (N.B. won't be done if reached max no. of lines, as loop broken)


	* Return strings
	forvalues i=1/`line' {
	
		// truncate if appropriate (last line only)
		if `i'==`line' & "`truncate'"=="" & `maxwidth' {
			local title`i' = substr(`"`title`i''"', 1, `maxwidth')
		}
		return local title`i' `"`title`i''"'
	}
	
	* Return values
	return scalar nlines = `line'
	return scalar maxwidth = min(`newwidth', `maxwidth')
	return scalar target = `target'
	
end




*********************************************************************************

program define UserSpecHide, rclass

	syntax varname [if] [in], PLOTID(varname numeric) [ OCILINEOPts(string asis) RFCILINEOPts(string asis) * ]
	local _USE : copy local varlist
	marksample touse
	local reduceHeight = 0
	
	local 0 `", `ocilineopts'"'
	syntax [, HIDE * ]
	if `"`hide'"'!=`""' {
		qui count if `touse' & inlist(`_USE', 3, 5, 7)
		local reduceHeight = r(N)
	}
	else {
		local 0 `", `rfcilineopts'"'
		syntax [, HIDE * ]
		if `"`hide'"'!=`""' {
			qui count if `touse' & inlist(`_USE', 3, 5, 7)
			local reduceHeight = r(N)
		}
		else {
			summ `plotid' if `touse', meanonly
			forvalues p = 1/`r(max)' {
				local hide
				local 0 `", `graphopts'"'
				syntax [, OCILINE`p'opts(string asis) RFCILINE`p'opts(string asis) * ]
				local 0 `", `ociline`p'opts'"'
				syntax [, HIDE * ]
				if `"`hide'"'!=`""' {
					qui count if `touse' & `plotid'==`p' & inlist(`_USE', 3, 5, 7)
					local reduceHeight = `reduceHeight' + r(N)
				}
				else {
					local 0 `", `rfciline`p'opts'"'
					syntax [, HIDE * ]
					if `"`hide'"'!=`""' {
						qui count if `touse' & `plotid'==`p' & inlist(`_USE', 3, 5, 7)
						local reduceHeight = `reduceHeight' + r(N)
					}
				}
			}
		}
	}
	return scalar N = `reduceHeight'
	
end




*********************************************************************************

*** FIND OPTIMAL TEXT SIZE AND ASPECT RATIOS (given user input)

// Notes:  (David Fisher, July 2014)
	
// Let X, Y be dimensions of graphregion (outer; controlled by xsize(), ysize()); x, y be dimensions of plotregion (inner; controlled by aspect()).
// `approxChars' is the approximate width of the plot, in "character units" (i.e. width of [LHS text + RHS text] divided by `astext')
	
// Note that a "character unit" is the width of a character relative to its height; 
//  hence `height' is the approximate height of the plot, in terms of both rows of text (with zero gap between rows) AND "character units".
	
// If Y/X = `graphAspect'<1, `textSize' is the height of a row of text relative to Y; otherwise it is height relative to X.
// (Note that the default `graphAspect' = 4/5.5 = 0.73 < 1)
// We then let `approxChars' = x, and manipulate to find the optimum text size for the plot layout.

// FEB 2015: `textsize' is deprecated, since it causes problems with spilling on the RHS.
// Instead, using `spacing' to fine-tune the aspect ratio (and hence the text size)
//   or use `aspect' to completely user-define the aspect ratio.
// MAY 2020: Following discussion with Jonathan Sterne, option textsize() has been reinstated
// But it works *at the end*, after the aspect ratio has already been calculated -- so it's "use at your own risk"
// Internally, it is renamed to `textscale', since it is actually a scale, and it avoids clashing with already-coded `textsize'

//  - Note that this code has been changed considerably from the original -metan9- code.

// Moved into separate subroutine Nov 2017 (for v2.2 beta)

program define GetAspectRatio, rclass

	syntax [, ASTEXT(real 50) COLWDTOT(real 0) HEIGHT(real 0) USEDIMS(name) ///
		ASPECT(real -9) SPacing(real -9) XSIZe(real -9) YSIZe(real -9) FXSIZe(real -9) FYSIZe(real -9) ///
		TItle(string asis) SUBtitle(string asis) CAPTION(string asis) NOTE2(string asis) noNOTE noWARNing ///
		XTItle(string asis) ROWSFAV(real 0) ADDHeight(real 0) /*(undocumented)*/ ///
		TEXTSize(real 100.0) /// /* legacy -metan9- option, implemented here as a post-hoc option; use at own risk */
		ROWSXLAB(real 0) /*DXWIDTHChars(real -9)*/ DOUBLE COLSONLY * ]
	
	local graphopts `"`options'"'
	
	// Error message copied directly from -metan9-
	if `textsize' < 20 | `textsize' > 500 {
		di as error "Text scale (TEXTSize) must be within 20-500"
		di as error "Value is character size relative to graph"
		di as error "Outside range will either be unreadable or too large"
		exit 198
	}
	local textscale : copy local textsize	// rename to `textscale' for internal use...
	local textsize							// ... and reset `textsize' macro [May 2020]
	
	* Unpack `usedims'
	local DXwidthChars : copy local dxwidthchars		// added Feb 2018: clarity
	local DXwidthChars = -9		// initialize
	local oldTextSize = -9		// initialize
	if `"`usedims'"'!=`""' {
		local DXwidthChars = `usedims'[1, `=colnumb(matrix(`usedims'), "cdw")']
		local spacing = cond(`spacing'==-9, `usedims'[1, `=colnumb(matrix(`usedims'), "spacing")'], `spacing')
		local oldPlotAspect = `usedims'[1, `=colnumb(matrix(`usedims'), "aspect")']		// modified Nov 2017
		local oldXSize = `usedims'[1, `=colnumb(matrix(`usedims'), "xsize")']
		local oldYSize = `usedims'[1, `=colnumb(matrix(`usedims'), "ysize")']
		local oldTextSize = `usedims'[1, `=colnumb(matrix(`usedims'), "textsize")']
		local oldHeight = `usedims'[1, `=colnumb(matrix(`usedims'), "height")']			// added Sep 2017
		local oldYheight = `usedims'[1, `=colnumb(matrix(`usedims'), "yheight")']		// added Sep 2017
		
		numlist "`DXwidthChars' `spacing' `oldPlotAspect' `oldXSize' `oldYSize' `oldTextSize' `oldHeight' `oldYheight'", min(8) max(8) range(>=0)
	}


	* Obtain number of rows within each title element
	// (see help title_options)
	// [modified Nov 2017]
	// (N.B. favours will be done separately)
	// [modified Feb 2018]
	// [Jan 2019: converted to subroutine for better parsing of compound quotes]
	foreach opt in title subtitle caption note xtitle {
		GetRows ``opt''
		local rows`opt' = r(rows)
	}

	local condtitle = 2*`rowstitle' + 1.5*`rowssubtitle' + 1.25*`rowscaption' + 1.25*`rowsnote'	// approximate multipliers for different text sizes + gaps
	local condtitle = `condtitle' + (`"`title'"'!=`""' & `"`subtitle'"'!=`""')					// additional gap between title and subtitle, if *both* specified
	local condtitle = `condtitle' + 2 + `addheight'												// add 2 for graphregion(margin())

	// Now derive small amounts `xdelta', `ydelta', to take account of the space taken up by titles etc.
	// Assume that, if plot is "full-width", then X = x * xdelta
	//  and that, if plot is "full-height", then Y = y * ydelta	
	// local ydelta = (`height' + `condtitle' + (`"`xlablist'"'!=`""') + `rowsfav' + `rowsxtitle')/`height'
	local ydelta = (`height' + `condtitle' + `rowsxlab' + `rowsfav' + `rowsxtitle')/`height'			// Nov 2017
	local xdelta = (`height' + `condtitle')/`height'		// Oct 2016: check logic of this, why difference in what is added??
	// Notes Feb 2015:
	// - could maybe be improved, but for now `addheight' option (undocumented) allows user to tweak
	// - also think about line widths (thicknesses), can we keep them constant-ish??
	// May 2016: yes, should be quite easy -- choose a reasonable value based on the height, then amend it in the same way as textsize	

	
	* Derive `approxChars', `spacing' and `plotAspect'
	// (possibly using saved "dimensions")
	// (for future: investigate using margins to "centre on DXwidth" within graphregion??)
	if `"`usedims'"'==`""' {
		local approxChars = 100*`colwdtot'/`astext'
		
		if `aspect' != -9 {					// user-specified aspect of plotregion
			if `spacing' == -9 local spacing = `aspect' * `approxChars' / `height'		// [modified Nov 2017]
			local plotAspect = `aspect'
		}
		else {								// if not user-specified
			// if "natural aspect" (`height'/`approxChars') is 2x1 or wider, use double spacing; else use 1.5-spacing
			// Apr 2020: if -double- option, increase the spacing again... 4/3 seems to work (N.B. this is 2/1.5, i.e. ratio of usual options)
			// (unless user-specified, in which case use that)
			if `spacing' == -9 local spacing = cond(`height'/`approxChars' <= .5, 2, 1.5)
			if `"`double'"'!=`""' local spacing = (4/3) * `spacing'
			local plotAspect = `spacing' * `height' / `approxChars'
		}
	}
	else {	// if `usedims' supplied
		local approxChars = `colwdtot' + cond(`"`colsonly'"'!=`""', 0, `DXwidthChars')		// modified Feb 2018
		local plotAspect = cond(`aspect'==-9, `spacing'*`height'/`approxChars', `aspect')
		// `spacing' here is from `usedims' unless over-ridden by user
	}
	numlist "`plotAspect' `spacing'", range(>=0)

	
	* Derive graphAspect = Y/X (defaults to 4/5.5  = 0.727 unless specified)
	// [modified Nov 2017]
	if `"`usedims'"'==`""' {
		local oldYSize = 4
		local oldXSize = 5.5
	}
	local graphAspect = cond(`ysize'==-9, `oldYSize', `ysize') ///
		/ cond(`xsize'==-9, `oldXSize', `xsize')
	
	// July 2015
	* Standard approach is now to use `graphAspect' and `plotAspect' to determine `textSize'.
	if `"`usedims'"'==`""' {
		
		// (1) If y/x < Y/X < 1 (i.e. plot takes up full width of "wide" graph) then X = x * xdelta
		//     ==> `textSize' = 100/Y = 100/(X * `graphAspect') = 100/(`xdelta' * `approxChars' * `graphAspect')
		if `graphAspect' <= 1 & `plotAspect' <= `graphAspect' {
			local textSize = 100 / (`xdelta' * `approxChars' * `graphAspect')
		}
		
		// (2) If Y/X < 1 and y/x > Y/X (i.e. plot is less wide than "wide" graph) then Y = y * ydelta
		//     ==> `textSize' = 100/Y = 100/(ydelta * x * `plotAspect') = 100 / (`ydelta' * `approxChars' * `plotAspect')
		else if `graphAspect' <= 1 & `plotAspect' > `graphAspect' {
			local textSize = 100 / (`ydelta' * `approxChars' * `plotAspect')
		}
			
		// (3) If y/x > Y/X > 1 (i.e. plot takes up full height of "tall" graph) then Y = y * ydelta
		//     ==> `textSize' = 100/X = 100 * `graphAspect'/(y * ydelta) = 100 * `graphAspect' / (`ydelta' * `approxChars' * `plotAspect')
		else if `graphAspect' > 1 & `plotAspect' > `graphAspect' {
			local textSize = (100 * `graphAspect') / (`ydelta' * `approxChars' * `plotAspect')
		}
			
		// (4) If Y/X > 1 and y/x < Y/X (i.e. plot is less tall than "tall" graph) then X = x * xdelta
		//     ==> `textSize' = 100/X = 100 / (`xdelta' * `approxChars')
		else if `graphAspect' > 1 & `plotAspect' <= `graphAspect' {
			local textSize = 100 / (`xdelta' * `approxChars')
		}
		
		// [added Nov 2017]
		// If Y/X = `graphAspect' <= 1 ("wide"), set fysize to 100; else ("tall") set fxsize to 100
		// in other words, min dimension is always 100; the other is >100
		local fxsize = cond(`fxsize' == -9, cond(`graphAspect' <= 1, 100/`graphAspect', 100), `fxsize')
		local fysize = cond(`fysize' == -9, cond(`graphAspect' <= 1, 100, 100*`graphAspect'), `fysize')
	}

	* Else if `usedims' supplied:
	* oldGraphAspect and oldPlotAspect would have been derived using the rules above
	* we immediately know the new plotAspect = `spacing'*`height'/`approxChars' (using new `approxChars')
	* (assuming the height is the same -- come back to this point maybe)
	* So:
	// (1) old y/x < Y/X < 1 ==> plot takes up full width
	// (a) if newplotAspect is wider still (new y/x < old y/x) then it will have to "shrink" (i.e. lose height)
	//     ==> widen newgraphAspect by the same amount?? (minus delta, because that will be constant)
	//     But, since in all cases Y is less than X, `textSize' is based on Y, so should still be correct.
	// (b) if newplotAspect is less wide (new y/x > old y/x) it will fit fine, so again `textSize' will be fine.
		
	// (2) old Y/X < 1, old y/x > Y/X (i.e. old plot is less wide than "wide" graph)
	// (a) if newplotAspect is wider, then everything is fine UNLESS new y/x ends up <Y/X.
	//     However, we're then in case (1)(a) so once newgraphAspect is widened, `textSize' should be fine.
	// (b) if newplotAspect is less wide, it will fit fine, so again `textSize' will be fine.
		
	// (3) If y/x > Y/X > 1 (i.e. plot takes up full height of "tall" graph)
	// (a) if newplotAspect is wider, then everything is fine UNLESS new y/x ends up <Y/X.
	//     ==> need to widen newgraphAspect (minus delta, because that will be constant)
	//     Then if newgraphAspect is still > 1, we're in case (1)(a) again
	//     BUT if newgraphAspect is now < 1, then we'll need to amend `textSize'.
	// (b) if newplotAspect is less wide, it will fit fine, so again `textSize' will be fine.
		
	// (4) If Y/X > 1 and y/x < Y/X (i.e. plot is less tall than "tall" graph) 
	// (a) if newplotAspect is wider, newgraphAspect will ALWAYS need to be widened to avoid "shrinkage"
	//     Then if newgraphAspect is still > 1, we're in case (1)(a) again
	//     BUT if newgraphAspect is now < 1, then we'll need to amend `textSize'.
	// (b) if newplotAspect is less wide, it will have to "expand" (i.e. gain height)	
	//     ==> *reduce* width of newgraphAspect	by the same amount
	//     But, since in all cases X is less than Y, `textSize' is based on X, so should still be correct.
		
	* So, scenarios in which to take action are:
	// (1)(a): increase width of newgraphAspect;
	//         no change to `textSize'
	// (2)(a): check new y/x: if y/x < Y/X then increase width of newgraphAspect;
	//         no change to `textSize'
	// (3)(a): check new y/x: if y/x < Y/X then increase width of newgraphAspect;
	//         then check new Y/X: if <1 then need to amend `textSize'
	// (4)(a): increase width of newgraphAspect;
	//         check new Y/X: if <1 then need to amend `textSize'
	// (4)(b): reduce width of newgraphAspect;
	//         no change to `textSize'		
	
	else {
		local textSize = `oldTextSize'				// tidy this up
			
		// 1a & 2a
		if `graphAspect' <= 1 & `plotAspect' <= `graphAspect' {
		
			if `xsize'==-9 | `ysize'==-9 {
				local graphAspect = `graphAspect' * `plotAspect' / `oldPlotAspect'

				// Modified Nov 2017
				if `xsize'==-9 & `ysize'==-9 local xsize = `oldYSize' / `graphAspect'
				else {
					if `xsize'==-9 local xsize = `ysize' / `graphAspect'
					else           local ysize = `xsize' * `graphAspect'
				}
			}
		}
			
		// 3a, 4a, 4b
		else if `graphAspect' > 1 & ///
			((`oldPlotAspect' > `graphAspect' & `plotAspect' <= `graphAspect') ///
			| (`oldPlotAspect' <= `graphAspect')) {

			if `xsize'==-9 | `ysize'==-9 {
				local oldGraphAspect = `graphAspect'
				local graphAspect = `oldGraphAspect' * `plotAspect' / `oldPlotAspect'

				// Modified Nov 2017
				if `xsize'==-9 & `ysize'==-9 local xsize = `oldYSize' / `graphAspect'
				else {
					if `xsize'==-9 local xsize = `ysize' / `graphAspect'
					else           local ysize = `xsize' * `graphAspect'
				}

				// 3a, 4a
				if `graphAspect' <= 1 {
					local textSize = `textSize' / `oldGraphAspect'
				}
			}
		}
		
		// Added Nov 2017, revised Feb 2018
		local fxsize = cond(`fxsize'==-9, 100*(`oldPlotAspect'/`plotAspect')*(`height'/`oldHeight')*(`oldXSize'/`oldYSize'), `fxsize')
		local fysize = cond(`fysize'==-9, 100*`ydelta'*`height'/`oldYheight', `fysize')
	}
	
	* Notes: for random-effects analyses, sample-size weights, or user-defined (will overwrite the first two)
	if `"`note2'"'!=`""' {
		local 0 `"`note2'"'
		syntax [anything(name=notetxt everything)] [, SIze(string) * ]
		if "`size'"=="" local size = `textSize' * .75 * `textscale'/100		// use 75% of text size used for rest of plot
		if "`colsonly'"!="" local notetxt `"" ""'							// added Feb 2018
		
		// May 2018: Having parsed the note, now suppress it if noWARNing or noNOTE
		if `"`warning'`note'"'==`""' local noteopt `"note(`notetxt', size(`size') `options')"'
	}
	
	// collect options relevant to GetAspectRatio which also need ultimately to be passed to -twoway-
	// N.B. *not* favours; instead returned as `leftfav' and 'rightfav'
	// [Feb 2018] Also *not* xtitle, as already parsed at beginning of code
	foreach opt in /*xtitle*/ title subtitle caption {
		if trim(`"``opt''"')!=`""' {
			local graphopts `"`graphopts' `opt'(``opt'')"'
		}
	}
	return local graphopts `"`graphopts' `noteopt'"'
	
	
	* Return scalars
	return scalar xsize = cond(`xsize'==-9, 5.5, `xsize')		// added Nov 2017
	return scalar ysize = cond(`ysize'==-9, 4, `ysize')			// added Nov 2017
	return scalar fxsize = `fxsize'
	return scalar fysize = `fysize'
	return scalar yheight = `ydelta'*`height'
	return scalar textsize = `textSize'						// textsize as calculated by this routine
	return scalar textsize2 = `textSize' * `textscale'/100	// textsize as modified post-hoc by textscale() option [May 2020]
	return scalar spacing = `spacing'
	return scalar approxchars = `approxChars'
	return scalar graphaspect = `graphAspect'
	return scalar plotaspect = `plotAspect'
		
end
		

* GetRows: subroutine of GetAspectRatio
// added Jan 2019
program define GetRows, rclass
	syntax [anything(id="text string")] [, *]
	local rows = 0
	if `"`anything'"'!=`""' {
		// March 2018
		// word count has trouble with apostrophes (but not double-quotes)
		// so replace them with "a" for the purposes of word-counting
		/*
		local rest : subinstr local anything `"'"' `"a"', all
		gettoken foo bar : rest, qed(q) quotes
		local rows = cond(`q', `: word count `rest'', 1)
		*/

		// Jan 2019: if title() etc. finds "" or `""' at the start, the title is set to nothing
		if substr(trim(`"`anything'"'), 1, 2)==`""""' | substr(trim(`"`anything'"'), 1, 4)==`"`""'"' {
			return scalar rows = 0
			exit
		}
		
		// Jan 2019: else, remove quotes using gettoken
		gettoken foo bar : anything, qed(q) quotes
		local rows = cond(`q', `: word count `anything'', 1)
	}
	return scalar rows = `rows'
end



*********************************************************************************

** Program to build plot commands for the different elements
// from plotopts and plot`p'opts

// August 2018: removed "sortpreserve" (since we are adding new obs).
// Instead, repect sort order (of `touse' `id') "manually".
// (N.B. no further sorting takes place in main routine hereafter.)

// August 2018: N.B. unusually, have to pass `touse' as an option here (rather than using marksample)
// since we need to have the same tempname appearing in the created plot commands

program define BuildPlotCmds, sclass

	syntax varlist(numeric min=4 max=4 default=none), TOUSE(varname numeric) ID(varname numeric) ///
		CXLIST(numlist min=2 max=2) ///
		[PLOTID(varname numeric) DATAID(varname numeric) NEWwt H0(real 0) noNULL ///
		CLASSIC noDIAmonds INTERaction COLSONLY CUmulative INFluence noOVerall noSUbgroup ///
		WGT(varname numeric) RFDIST(varlist numeric) BOXscale(real 100.0) noBOX ///
		DIAMLIST(namelist) OVLIST(namelist) OFFSCLIST(namelist) RFLIST(namelist) TOUSEEXTRA(namelist) * ]

	
	// JAN 2020:  This subroutine has been rearranged.
	// GENERAL IDEA:  we don't *need* the actual variables in order to build the plot commands; we just to know the variable *names*.
	// Therefore, we can build the plot commands *first*, and then mess about with the variables themselves afterwards.
	// This means e.g. we can first identify whether, and where, -expand- is needed for area plots (e.g. diamonds or CI area plots)
	//   and then do this work *later*, whilst accounting for "hidden" pooled observations (needed e.g. for `cumulative' or `influence').
	
	tokenize `varlist'
	args _USE _ES _LCI _UCI
	
	tokenize `cxlist'
	args CXmin CXmax
	
	local _WT `wgt'
	local awweight `"[aw= `_WT']"'		// moved here 30th Jan 2018
	
	if "`box'"!="" local oldbox nobox		// allow "global" option `nobox' for compatibility with -metan-
											// N.B. can't be used with plotid; instead box`p'opts(msymbol(none)) can be used

	** Some initial setup
	summ `plotid' if `touse', meanonly
	local np = r(max)
	cap confirm var `dataid'
	if _rc local nd = 1
	else {
		qui tab `dataid' if `touse'		// Nov 2021: changed from "summ `dataid'" as may not be ordinal
		local nd = r(r)
		local dataidopt `"& `dataid'==`dataid'[_n-1]"'
	}
		

	** SETUP OFF-SCALE ARROWS -- fairly straightforward
	// (include use==3, 5, 7 in case of pciopts/rfopts)
	tokenize `offsclist'
	args offscaleL offscaleR
	qui gen byte `offscaleL' = `touse' * inlist(`_USE', 1, 3, 5, 7) * (float(`_LCI') < float(`CXmin'))
	qui gen byte `offscaleR' = `touse' * inlist(`_USE', 1, 3, 5, 7) * (float(`_UCI') > float(`CXmax') & !missing(`_UCI'))

	// rfdist: only applies to use==3, 5, 7
	// BUT may need up to four tempvars in niche cases (e.g. only part of the rfCI is visible)
	// ==> to save on tempvars, only use them if more than one; o/w use local macros
	if `"`rfdist'"'!=`""' {
		tokenize `rfdist'
		args _rfLCI _rfUCI
	
		tokenize `rflist'
		args rfLoffscaleL rfRoffscaleR rfRoffscaleL rfLoffscaleR rfLineLCI rfLineUCI rfLineX

		local touse3 `"`touse' & inlist(`_USE', 3, 5, 7)"'
		qui count if `touse3'
		if r(N) {
			gen byte `rfLoffscaleL' = `touse3' * (float(`_rfLCI') < float(`CXmin'))
			gen byte `rfRoffscaleR' = `touse3' * (float(`_rfUCI') > float(`CXmax') & !missing(`_rfUCI'))
			
			qui count if `touse3' & float(`_UCI') < float(`CXmin')
			if r(N) {
				gen byte `rfRoffscaleL' = `touse3' * (float(`_UCI') < float(`CXmin'))
			}
			else {
				gen byte `rfRoffscaleL' = `touse3' * (float(`_LCI') > float(`CXmax') & !missing(`_LCI'))
			}
			
			qui count if `touse3' & float(`_LCI') > float(`CXmax') & !missing(`_LCI')
			if r(N) {
				gen byte `rfLoffscaleR' = `touse3' * (float(`_LCI') > float(`CXmax') & !missing(`_LCI'))
			}
			else {
				gen byte `rfLoffscaleR' = `touse3' * (float(`_UCI') < float(`CXmin'))
			}
		}
		else {
		    local rfLoffscaleL = 0
			local rfRoffscaleR = 0
		}
	}

	
	** "OVERALL EFFECT" LINES
	tokenize `ovlist'
	args ovLine ovMin ovMax ovLineLCI ovLineUCI ovLineX		// `ovLineLCI' `ovLineUCI' `ovLineX' added Jan 2020
		
	qui gen float `ovLine' = .
		
	// Construct groups of observations containing a single obs where _USE==3 or 5
	// Within each `dataid', such groups ("olinegroup") are identified by _USE==5 if present ("overall"), or _USE==3 otherwise ("subgroup").
	qui count if `touse' & inlist(`_USE', 3, 5)
	if r(N) {
		tempvar useno
		qui gen byte `useno' = `_USE' * inlist(`_USE', 3, 5) if `touse'
	
		sort `touse' `dataid' `id'
		qui by `touse' : replace `useno' = `useno'[_n-1] if _n>1 & `useno'<=`useno'[_n-1] `dataidopt'		// find the largest value (from 3 & 5) "so far"

		tempvar olinegroup check
		qui gen int `olinegroup' = (`_USE'==`useno') * (`useno'>0)
		qui by `touse' `dataid' : replace `olinegroup' = sum(`olinegroup') if inlist(`_USE', 1, 2, 3, 5)	// study obs & pooled results

		// "check": only draw oline if there are study obs in the same olinegroup
		qui gen byte `check' = inlist(`_USE', 1, 2) if `touse'
		qui bysort `touse' `dataid' `olinegroup' (`check') : replace `check' = `check'[_N]
		sort `touse' `dataid' `olinegroup' `id'
	
		// Store values for later plotting
		// [modified Jan 2020]
		qui by `touse' `dataid' `olinegroup' : replace `ovLine' = `_ES'[1] if `touse' & `check' & !( `_ES'[1] > `CXmax' |  `_ES'[1] < `CXmin')
	}
		
	// "flags" to identify dummy variables for multiple plotids,
	// and/or where area plots are needed, for later -expand- [added Jan 2020]
	tokenize `touseextra'
	args tv0 touseDiam touseOCI touseRFCI
	qui gen byte `touseDiam' = 2 * `touse' * (`"`cumulative'`influence'"'==`""')
	// 0 = hide (+ ociline); 1 = pci/ppoint (line); 2 = diamonds (area + no lines; default)
	qui gen byte `touseOCI' = 0		// 0 = no lines or area (default); 1 = lines; 2 = area (+ lines)
	if `"`rfdist'"'!=`""' qui gen byte `touseRFCI' = 0		// same
	
	
	
	** IF MULTIPLE PLOTIDs, or if dataid(varname, newwt) specified,
	// create dummy obs with global min & max weights, to maintain correct weighting throughout
	if (`np' > 1 | `"`newwt'"'!=`""') {		// Amended June 2015

		// create new `touse', including new dummy obs
		qui gen byte `tv0' = `touse'
		local tousePlotID `tv0'
		
		// find global min & max weights, to maintain consistency across subgroups
		if `"`newwt'"'==`""' {		// weight consistent across dataid, so just do this once
			summ `_WT' if `touse' & inlist(`_USE', 1, 2), meanonly
			local minwt = r(min)
			local maxwt = r(max)
		}
		
		local oldN = _N
		local newN = `oldN' + 2*`nd'*`np'	// N.B. `nd' indexes `dataid'; `np' indexes `plotid'
		qui set obs `newN'
		forvalues i=1/`nd' {
			forvalues j=1/`np' {
				
				// dataid-specific min/max weights required
				if `"`newwt'"'!=`""' {		// weight consistent across dataid, so just use locals
					summ `_WT' if `touse' & inlist(`_USE', 1, 2) & `dataid'==`i', meanonly	
					local minwt = r(min)
					local maxwt = r(max)
				}
				
				local k = `oldN' + (`i'-1)*2*`np' + 2*`j'
				if `"`dataidopt'"'!=`""' {
					qui replace `dataid' = `i' in `=`k'-1' / `k'
				}
				qui replace `plotid' = `j' in `=`k'-1' / `k'
				qui replace `_WT' = `minwt' in `=`k'-1'
				qui replace `_WT' = `maxwt' in `k'
			}
		}
		qui replace `_USE'   = 1 in `=`oldN' + 1' / `newN'
		qui replace `touse'  = 0 in `=`oldN' + 1' / `newN'
		qui replace `tousePlotID' = 1 in `=`oldN' + 1' / `newN'
	}
	// these dummy obs are identifiable by "`tousePlotID' & !`touse'"

	else local tousePlotID `touse'		// else, no need for separate variable `tousePlotID'
	
	
	
	** DEFAULTS
	
	* Default options for simple graph elements
	cap assert `boxscale' >=0
	if _rc == 9 {
		disp as err `"value of {bf:boxscale()} must be >= 0"'
		exit 125
	}
	else if _rc {
		disp as err `"error in {bf:boxscale()} option"'
		exit _rc
	}
	local boxSize = `boxscale'/150	
	
	local defShape = cond("`interaction'"!="", "circle", "square")
	local defColor = cond("`classic'"!="", "black", "180 180 180")
	local defBoxOpts `"mcolor("`defColor'") msymbol(`defShape') msize(`boxSize')"'
	if `"`oldbox'"'!=`""' local defBoxOpts `"msymbol(none)"'	// -metan- "nobox" option
	local defCIOpts `"lcolor(black) mcolor(black)"'				// includes "mcolor" for arrows (doesn't affect rspike/rcap)
	local defPointOpts `"msymbol(diamond) mcolor(black) msize(vsmall)"'
	local defOlineOpts `"lwidth(thin) lcolor(maroon) lpattern(shortdash)"'
	local defOCIlineOpts  `"`defOlineOpts'"'					// CI of overall effect
	local defRFCIlineOpts `"`defOlineOpts'"'					// CI of predictive interval
	
	// ...and for "pooled" estimates
	local defShape = cond("`interaction'"!="", "circle", "diamond")
	local defColor "0 0 100"
	// local defDiamOpts `"lcolor("`defColor'") lalign(center) fcolor("none")"'
	local defDiamOpts `"lcolor("`defColor'") fcolor("none")"'
	if "`c(stata_version)'"!="" {
		if c(stata_version)>=15.1 local defDiamOpts `"`defDiamOpts' lalign(center)"'	// v3.0.1: lalign() only valid for Stata 15+
	}
	local defPPointOpts `"msymbol("`defShape'") mlcolor("`defColor'") mfcolor("none")"'	// "pooled" point options (alternative to diamond)
	local defPCIOpts `"lcolor("`defColor'") mcolor("`defColor'")"'						// "pooled" CI options (alternative to diamond)
	local defRFOpts `"`defPCIOpts'"'													// prediction interval options (includes "mcolor" for arrows)

	local defHlineOpts `"lwidth(thin) lcolor(gs12)"'	// horizontal upper border line
	local defNlineOpts `"lwidth(thin) lcolor(black)"'	// null line
	
	
	** Default options for graph elements that may be plotted in more than one way
	// (plus, may as well parse some other options too, including disallowed ones)
	local 0 `", `options'"'
	syntax [, ///
		/// /* standard options */
		BOXOPts(string asis) DIAMOPts(string asis) POINTOPts(string asis) CIOPts(string asis) ///
		OLINEOPts(string asis) OCILINEOPts(string asis) RFCILINEOPts(string asis) ///
		HLINEOPts(string asis) NLINEOPts(string asis) ///
		/// /* non-diamond and prediction interval options */
		PPOINTOPts(string asis) PCIOPts(string asis) RFOPts(string asis) * ]

	local rest `"`options'"'
	
	* Overall and Null lines
	// NOTE NOV 2021: parse to find "global" noOVerlay options
	// everything else will be parsed later, with plot#opts
	foreach plot in oline nline {
		local 0 `", ``plot'opts'"'
		syntax [, noOVerlay * ]
		local g_`plot'first : copy local overlay
		local `plot'opts `"`macval(options)'"'
	}
	
	* Confidence intervals
	// since capped lines require a different -twoway- command (-rcap- vs -rspike-)
	if `"`rfdist'"'==`""' & `"`rfopts'"'!=`""' {
		nois disp as err `"predictive interval not specified; relevant options will be ignored"'
		local rfopts
	}

	// Same routine applies to study CIs, "pooled" CIs (alternative to diamond), and to prediction intervals:
	foreach plot in ci pci rf {

		// NOTE NOV 2021:
		// Currently we have an option "overlay" here for use with rfplotopts only
		// the default is "nooverlay" meaning that the pred. int. lines extend outwards from extremities of diamond
		// the option "overlay" instead places a single line passing straight through and over the top of the diamond.
		
		// It has been brought to my attention that it may be desirable for confidence interval lines to be *obscured* by weighted boxes
		// rather than to be seen overlaid on weighted boxes (current default -- so you can see e.g. very short CIs over large boxes)
		// however, the default behaviour should not be changed due to backwards-compatibility
		// solution: use *two* options:  "OVerlay" for rf;  and "noOVerlay" for ci/pci.
		
		// However, the new option noOVerlay behaves differently from old option OVerlay2:
		// - not allowed within the plotid-specific loops later on (because it's currently implemented as a "global" ordering of plot elements with the -twoway- command)
		// - similarly: it's not really *used* here; it's simply returned as-is (as an extra soption) to be picked up by the main -twoway- command.
		
		// options specific to rfplot
		if `"`plot'"'==`"rf"' local overlay_opt OVerlay SEPLine
		else                  local overlay_opt noOVerlay
		
		local 0 `", ``plot'opts'"'
		syntax [, LColor(passthru) MColor(passthru) LWidth(passthru) MLWidth(passthru) ///
			RCAP `overlay_opt' HORizontal VERTical * ]
			
		// disallowed options
		if `"`horizontal'"'!=`""' | `"`vertical'"'!=`""' {
			nois disp as err `"suboptions {bf:horizontal} and {bf:vertical} not allowed in option {bf:`plot'opts()}"'
			exit 198
		}
		/*
		if `"`overlay'"'!=`""' & "`plot'"!="rf" {
			nois disp as err `"suboption {bf:overlay} not allowed in option {bf:`plot'opts()}"'
			exit 198
		}
		*/

		// rebuild the option list
		if `"`lcolor'"'!=`""' & `"`mcolor'"'==`""'  local mcolor = subinstr(`"`lcolor'"', "l", "m", 1)		// for pc(b)arrow
		if `"`lwidth'"'!=`""' & `"`mlwidth'"'==`""' local mlwidth m`lwidth'									// for pc(b)arrow
		local `plot'opts `"`mcolor' `lcolor' `mlwidth' `lwidth' `options'"'
		
		// "overlay" options (see "Note" above)
		local g_overlay_`plot' : copy local overlay
		if `"`plot'"'==`"rf"' {
			local g_sepline_`plot' : copy local sepline
			if `"`sepline'"'!=`""' local g_overlay_`plot' overlay		// -sepline- implies -overlay-
		}
		
		local uplot = upper("`plot'")
		local `uplot'PlotType = cond("`rcap'"=="", "rspike", "rcap")
	}
	
	* Diamonds
	// since if truncated (offscale), line options are removed from -rarea- and drawn separately
	local 0 `", `diamopts'"'
	syntax [, Color(passthru) LColor(passthru) ///
		HORizontal VERTical CMISsing(passthru) SORT * ]

	// disallowed options
	if `"`horizontal'"'!=`""' | `"`vertical'"'!=`""' {
		nois disp as err `"suboptions {bf:horizontal} and {bf:vertical} not allowed in option {bf:diamopts()}"'
		exit 198
	}			
	if `"`cmissing'"'!=`""' {
		nois disp as err `"suboption {bf:cmissing()} not allowed in option {bf:diamopts()}"'
		exit 198
	}
	if `"`sort'"'!=`""' {
		nois disp as err `"suboption {bf:sort} not allowed in option {bf:diamopts()}"'
		exit 198
	}
	
	// rebuild the option list
	if `"`color'"'!=`""' & `"`lcolor'"'==`""' local lcolor l`color'		// convert `color' -rarea- option to `lcolor' -line- option
	local diamopts `"`color' `lcolor' `options'"'
	
	tokenize `diamlist'
	args DiamX DiamY1 DiamY2
	

	** PARSE PLOT#OPTS
	
	// Loop over possible values of `plotid' and test for plot#opts relating specifically to each value
	numlist "1/`np'"
	local plvals=r(numlist)			// need both of these as explicit numlists,
	local pplvals `plvals'			//    for later macro manipulations to remove specific values if necessary
	forvalues p = 1/`np' {

		local hide
		local 0 `", `rest'"'
		syntax [, ///
			/// /* standard options */
			BOX`p'opts(string asis) DIAM`p'opts(string asis) POINT`p'opts(string asis) CI`p'opts(string asis) ///
			OLINE`p'opts(string asis) OCILINE`p'opts(string asis) RFCILINE`p'opts(string asis) ///
			/// /* non-diamond and prediction interval options */
			PPOINT`p'opts(string asis) PCI`p'opts(string asis) RF`p'opts(string asis) * ]

		local rest `"`options'"'

		* Check if any options were found specifically for this value of `p'
		local checkopt = 0
		local optslist box diam point ci oline ociline rfciline ppoint pci rf
		foreach op of local optslist {
			if trim(`"``op'`p'opts'"') != `""' local checkopt = 1
		}
		if `checkopt' {
			
			local pplvals : list pplvals - p			// remove from list of "default" plotids
			
			
			* INDIVIDUAL STUDY MARKERS
			local touse2 `"`touse' & `_USE'==1 & `plotid'==`p'"'		// use local, not tempvar, so conditions are copied into plot commands
			qui count if `touse2'
			if r(N) {
			
				* WEIGHTED SCATTER PLOT
				local 0 `", `box`p'opts'"'
				syntax [, MLABEL(passthru) MSIZe(passthru) * ]			// check for disallowed options
				if `"`mlabel'"' != `""' {
					nois disp as err `"suboption {bf:mlabel()} not allowed in option {bf:box`p'opts()}"'
					exit 198
				}
				if `"`msize'"' != `""' {
					nois disp as err `"suboption {bf:msize()} not allowed in option {bf:box`p'opts()}"'
					exit 198
				}
				local scPlotOpts `"`defBoxOpts' `boxopts' `box`p'opts'"'
				summ `_WT' if `touse2', meanonly
				if !r(N) nois disp as err `"No weights found for {bf:plotid}==`p'"'
				else if `nd'==1 local scPlot`"`macval(scPlot)' scatter `id' `_ES' `awweight' if `tousePlotID' & `_USE'==1 & `plotid'==`p', `macval(scPlotOpts)' ||"'
				else {
					forvalues d=1/`nd' {
						local scPlot `"`macval(scPlot)' scatter `id' `_ES' `awweight' if `tousePlotID' & `_USE'==1 & `plotid'==`p' & `dataid'==`d', `macval(scPlotOpts)' ||"'
					}
				}		// N.B. scatter if `tousePlotID' <-- "dummy obs" for consistent weighting
				
				* CONFIDENCE INTERVAL PLOT
				local 0 `", `ci`p'opts'"'
				syntax [, LColor(passthru) MColor(passthru) LWidth(passthru) MLWidth(passthru) ///
					RCAP HORizontal VERTical /*Connect(string)*/ * ]								// check for disallowed options + rcap
				
				// disallowed options
				if `"`horizontal'"'!=`""' | `"`vertical'"'!=`""' {
					nois disp as err `"suboptions {bf:horizontal} and {bf:vertical} not allowed in option {bf:ci`p'opts()}"'
					exit 198
				}
				/*
				if `"`connect'"'!=`""' {
					nois disp as err `"suboption {bf:connect()} not allowed in option {bf:ci`p'opts()}"'
					exit 198
				}
				*/
				
				// rebuild option list
				if `"`lcolor'"'!=`""' & `"`mcolor'"'==`""'  local mcolor = subinstr(`"`lcolor'"', "l", "m", 1)	// for pc(b)arrow
				if `"`lwidth'"'!=`""' & `"`mlwidth'"'==`""' local mlwidth m`lwidth'								// for pc(b)arrow
				local CIPlot`p'Opts `"`defCIOpts' `ciopts' `mcolor' `lcolor' `mlwidth' `lwidth' `options'"'		// main options first, then options specific to plot `p'
				local CIPlot`p'Type = cond("`rcap'"=="", "`CIPlotType'", "rcap")
				
				// default: both ends within scale (i.e. no arrows)
				local CIPlot`"`macval(CIPlot)' `CIPlot`p'Type' `_LCI' `_UCI' `id' if `touse2' & !`offscaleL' & !`offscaleR', hor `macval(CIPlot`p'Opts)' ||"'

				// if arrows required
				qui count if `touse2' & `offscaleL' & `offscaleR'
				if r(N) {													// both ends off scale
					local CIPlot `"`macval(CIPlot)' pcbarrow `id' `_LCI' `id' `_UCI' if `touse2' & `offscaleL' & `offscaleR', `macval(CIPlot`p'Opts)' ||"'
				}
				qui count if `touse2' & `offscaleL' & !`offscaleR'
				if r(N) {													// only left off scale
					local CIPlot `"`macval(CIPlot)' pcarrow `id' `_UCI' `id' `_LCI' if `touse2' & `offscaleL' & !`offscaleR', `macval(CIPlot`p'Opts)' ||"'
					if "`CIPlot`p'Type'" == "rcap" {			// add cap to other end if appropriate
						local CIPlot `"`macval(CIPlot)' rcap `_UCI' `_UCI' `id' if `touse2' & `offscaleL' & !`offscaleR', hor `macval(CIPlot`p'Opts)' ||"'
					}
				}
				qui count if `touse2' & !`offscaleL' & `offscaleR'
				if r(N) {													// only right off scale
					local CIPlot `"`macval(CIPlot)' pcarrow `id' `_LCI' `id' `_UCI' if `touse2' & !`offscaleL' & `offscaleR', `macval(CIPlot`p'Opts)' ||"'
					if "`CIPlot`p'Type'" == "rcap" {			// add cap to other end if appropriate
						local CIPlot `"`macval(CIPlot)' rcap `_LCI' `_LCI' `id' if `touse2' & !`offscaleL' & `offscaleR', hor `macval(CIPlot`p'Opts)' ||"'
					}
				}

				* POINT PLOT (point estimates -- except if "classic")
				if "`classic'" == "" {
					local pointPlot`"`macval(pointPlot)' scatter `id' `_ES' if `touse2', `defPointOpts' `pointopts' `point`p'opts' ||"'
				}
			}			// end if r(N) [i.e. if any obs with _USE==1 & plotid==`p']

			
			* OVERALL LINE(S) (if appropriate)
			summ `ovLine' if `plotid'==`p', meanonly
			if r(N) {
				local olinePlot `"`macval(olinePlot)' rspike `ovMin' `ovMax' `ovLine' if `touse' & `plotid'==`p', `defOlineOpts' `olineopts' `oline`p'opts' ||"'
			
			
				* PREDICTIVE INTERVAL CI LINES (and/or areas)
				// Do these before standard overall lines, in case of area plots
				//  want pred. int. area plot to be underneath the "standard" CI area plot
				// Added Jan 2020
				if trim(`"`rfcilineopts'`rfciline`p'opts'"') != `""' {
					if `"`rfdist'"'==`""' {
						nois disp as err `"predictive interval not specified; relevant suboptions for {bf:plotid==`p'} will be ignored"'
					}
					else {
						local 0 `", `rfciline`p'opts'"'
						syntax [, LINE AREA HIDE HORizontal VERTical Color(passthru) FColor(passthru) FIntensity(passthru) * ]
				
						// disallowed options
						if `"`horizontal'"'!=`""' | `"`vertical'"'!=`""' {
							nois disp as err `"suboptions {bf:horizontal} and {bf:vertical} not allowed in option {bf:rfciline`p'opts()}"'
							exit 198
						}
						
						if `"`hide'"'!=`""' qui replace `touseDiam' = 0 if `plotid'==`p'

						// August 2023: don't display vertical lines if: (1) area plot requested; and (2) no explicit line options
						if !(`"`area'`color'`fcolor'`fintensity'"'!=`""' & `"`line'`options'"'==`""') {
							local olinePlot `"`macval(olinePlot)' rspike `ovMin' `ovMax' `rfLineLCI' if `touse' & `plotid'==`p', `defRFCIlineOpts' `rfcilineopts' `options' ||"'
							local olinePlot `"`macval(olinePlot)' rspike `ovMin' `ovMax' `rfLineUCI' if `touse' & `plotid'==`p', `defRFCIlineOpts' `rfcilineopts' `options' ||"'
						}
						
						// area plot -- use `touseRFCI'
						if `"`area'`color'`fcolor'`fintensity'"'!=`""' {
							local rfciline`p'opts `"`macval(rfciline`p'Opts)' `color' `fcolor' `fintensity' `options'"'
							local olineAreaPlot `"`macval(olineAreaPlot)' rarea `ovMin' `ovMax' `rfLineX' if `touseRFCI' & `plotid'==`p', `macval(rfciline`p'opts)' lwidth(none) cmissing(n) ||"'
							qui replace `touseRFCI' = 2 if `plotid'==`p'
						}
						else qui replace `touseRFCI' = 1 if `plotid'==`p'
					}
				}
			
				* OVERALL LINE(S) (and/or areas)
				// Added Jan 2020
				if `"`ocilineopts'`ociline`p'opts'`influence'"'!=`""' {
					local 0 `", `ociline`p'opts'"'
					syntax [, LINE AREA HIDE HORizontal VERTical Color(passthru) FColor(passthru) FIntensity(passthru) * ]

					// disallowed options
					if `"`horizontal'"'!=`""' | `"`vertical'"'!=`""' {
						nois disp as err `"suboptions {bf:horizontal} and {bf:vertical} not allowed in option {bf:ociline`p'opts()}"'
						exit 198
					}
					
					if `"`hide'"'!=`""' qui replace `touseDiam' = 0 if `plotid'==`p'

					// August 2023: don't display vertical lines if: (1) area plot requested; and (2) no explicit line options
					if !(`"`area'`color'`fcolor'`fintensity'"'!=`""' & `"`line'`options'"'==`""') {
						local olinePlot `"`macval(olinePlot)' rspike `ovMin' `ovMax' `ovLineLCI' if `touse' & `plotid'==`p', `defOCIlineOpts' `ocilineopts' `options' ||"'
						local olinePlot `"`macval(olinePlot)' rspike `ovMin' `ovMax' `ovLineUCI' if `touse' & `plotid'==`p', `defOCIlineOpts' `ocilineopts' `options' ||"'
					}
					
					// area plot -- use `touseOCI'
					if "`area'`color'`fcolor'`fintensity'"!=`""' {
						local ociline`p'opts `"`ocilineopts' `color' `fcolor' `fintensity' `options'"'
						local olineAreaPlot `"`macval(olineAreaPlot)' rarea `ovMin' `ovMax' `ovLineX' if `touseOCI' & `plotid'==`p', `macval(ociline`p'opts)' lwidth(none) cmissing(n) ||"'
						qui replace `touseOCI' = 2 if `plotid'==`p'
					}
					else qui replace `touseOCI' = 1 if `plotid'==`p'
				}
			}			// end if r(N) [i.e. if any obs with `ovline' & plotid==`p']
				
			
			* POOLED EFFECT MARKERS
			local touse2 `"`touseDiam' & inlist(`_USE', 3, 5) & `plotid'==`p'"'		// use local, not tempvar, so conditions are copied into plot commands
																					// N.B. `touseDiam' implies `touse'
			// local touse3 : copy local touse2
			
			// June 2023: "don't plot data..." -- this is now assured, since that data is _USE==7, not included in touse3

			/*
			if `"`rfdist'"'!=`""' {													// Oct 2022: don't plot data from "second" _USE==3|5 row containing pred.int. text
				// local touse3 `"`touse3' & float(`_rfLCI')!=float(`_LCI') & float(`_rfUCI')!=float(`_UCI')"'
				local touse3 `"`touse3' & float(`_rfLCI')<=float(`_LCI') & float(`_rfUCI')>=float(`_UCI')"'
			}
			*/
			qui count if `touse2'
			if r(N) {
			
				* DIAMONDS:  DRAW POLYGONS WITH -twoway rarea-
				* Assume diamond if no "pooled point/CI" options and no "interaction" option
				if trim(`"`ppointopts'`ppoint`p'opts'`pciopts'`pci`p'opts'`interaction'`diamonds'"') == `""' {
				
					local 0 `", `diam`p'opts'"'
					syntax [, Color(passthru) LColor(passthru) ///
						HORizontal VERTical CMISsing(passthru) SORT * ]

					// disallowed options
					if `"`horizontal'"'!=`""' | `"`vertical'"'!=`""' {
						nois disp as err `"suboptions {bf:horizontal} and {bf:vertical} not allowed in option {bf:diamopts()}"'
						exit 198
					}			
					if `"`cmissing'"'!=`""' {
						nois disp as err `"suboption {bf:cmissing()} not allowed in option {bf:diamopts()}"'
						exit 198
					}
					if `"`sort'"'!=`""' {
						nois disp as err `"suboption {bf:sort} not allowed in option {bf:diamopts()}"'
						exit 198
					}
					
					// rebuild option list
					if `"`color'"'!=`""' & `"`lcolor'"'==`""' local lcolor l`color'						// convert `color' -rarea- option to `lcolor' -line- option
					local diamPlot`p'Opts `"`defDiamOpts' `diamopts' `color' `lcolor' `options'"'		// main options first, then options specific to plot `p'
					
					// Now check whether any diamonds are offscale (niche case -- see also comments on ppoint below)
					// If so, will need to draw round the edges of the polygon, excepting the "offscale edges"
					//   and switch off the line options to -twoway rarea-
					// (draw these lines *after* drawing the area, though, so that the lines appear on top)
					qui count if `touse2' & (`offscaleL' | `offscaleR')
					if r(N) {
						local diam`p'Line `"line `DiamY1' `DiamX' if `touse2', `macval(diamPlot`p'Opts)' cmissing(n) ||"'
						local diam`p'Line `"`macval(diam`p'Line)' line `DiamY2' `DiamX' if `touse2', `macval(diamPlot`p'Opts)' cmissing(n) ||"'
						local diam`p'LWidth `"lwidth(none)"'
					}
					local diamPlot `"`macval(diamPlot)' rarea `DiamY1' `DiamY2' `DiamX' if `touse2', `macval(diamPlot`p'Opts)' `diam`p'LWidth' cmissing(n) || `diam`p'Line' "'
				}
				
				* POOLED EFFECTS - PPOINT/PCI
				else {
					if trim(`"`diam`p'opts'"') != `""' {
						nois disp as err `"Note: suboptions for both diamond and pooled point/CI specified for {bf:plotid}==`p';"'
						nois disp as err `"      diamond suboptions will be ignored"'
					}
				
					// shouldn't need to bother with arrows etc. here, as pooled effect should always be narrower than individual estimates
					// but do it anyway, just in case of non-obvious use case
					local 0 `", `pci`p'opts'"'
					syntax [, LColor(passthru) MColor(passthru) LWidth(passthru) MLWidth(passthru) ///
						RCAP HORizontal VERTical /*Connect(string)*/ * ]											// check for disallowed options + rcap
					
					// disallowed options
					if `"`horizontal'"'!=`""' | `"`vertical'"'!=`""' {
						nois disp as err `"suboptions {bf:horizontal} and {bf:vertical} not allowed in option{bf:pci`p'opts()}"'
						exit 198
					}
					/*
					if `"`connect'"' != `""' {
						nois disp as err `"suboption {bf:connect()} not allowed in option {bf:pci`p'opts}"'
						exit 198
					}
					*/
					
					// rebuild option list
					if `"`lcolor'"'!=`""' & `"`mcolor'"'==`""'  local mcolor = subinstr(`"`lcolor'"', "l", "m", 1)		// for pc(b)arrow
					if `"`lwidth'"'!=`""' & `"`mlwidth'"'==`""' local mlwidth m`lwidth'									// for pc(b)arrow
					local PCIPlot`p'Opts `"`defPCIOpts' `pciopts' `mcolor' `lcolor' `mlwidth' `lwidth' `options'"'		// main options first, then options specific to plot `p'
					local PCIPlot`p'Type = cond("`rcap'"=="", "`PCIPlotType'", "rcap")
					
					// default: both ends within scale (i.e. no arrows)
					local PCIPlot `"`macval(PCIPlot)' `PCIPlot`p'Type' `_LCI' `_UCI' `id' if `touse2' & !`offscaleL' & !`offscaleR', hor `macval(PCIPlot`p'Opts)' ||"'

					// if arrows are required
					qui count if `touse2' & `offscaleL' & `offscaleR'
					if r(N) {													// both ends off scale
						local PCIPlot `"`macval(PCIPlot)' pcbarrow `id' `_LCI' `id' `_UCI' if `touse2' & `offscaleL' & `offscaleR', `macval(PCIPlot`p'Opts)' ||"'
					}
					qui count if `touse2' & `offscaleL' & !`offscaleR'
					if r(N) {													// only left off scale
						local PCIPlot `"`macval(PCIPlot)' pcarrow `id' `_UCI' `id' `_LCI' if `touse2' & `offscaleL' & !`offscaleR', `macval(PCIPlot`p'Opts)' ||"'
						if "`PCIPlot`p'Type'" == "rcap" {			// add cap to other end if appropriate
							local PCIPlot `"`macval(PCIPlot)' rcap `_UCI' `_UCI' `id' if `touse2' & `offscaleL' & !`offscaleR', hor `macval(PCIPlot`p'Opts)' ||"'
						}
					}
					qui count if `touse2' & !`offscaleL' & `offscaleR'
					if r(N) {													// only right off scale
						local PCIPlot `"`macval(PCIPlot)' pcarrow `id' `_LCI' `id' `_UCI' if `touse2' & !`offscaleL' & `offscaleR', `macval(PCIPlot`p'Opts)' ||"'
						if "`PCIPlot`p'Type'" == "rcap" {			// add cap to other end if appropriate
							local PCIPlot `"`macval(PCIPlot)' rcap `_LCI' `_LCI' `id' if `touse2' & !`offscaleL' & `offscaleR', hor `macval(PCIPlot`p'Opts)' ||"'
						}
					}				
					local ppointPlot `"`macval(ppointPlot)' scatter `id' `_ES' if `touse2', `defPPointOpts' `ppointopts' `ppoint`p'opts' ||"'
					
					qui replace `touseDiam' = 1 if `plotid'==`p'	// line, not area
				}
				
				* PREDICTION INTERVAL
				// if trim(`"`ppointopts'`ppoint`p'opts'`pciopts'`pci`p'opts'`interaction'`diamonds'"') == `""' {
				
				if trim(`"`rfopts'`rf`p'opts'"') != `""' {
					if `"`rfdist'"'==`""' {
						nois disp as err `"predictive interval not specified; relevant suboptions for {bf:plotid==`p'} will be ignored"'
					}
					else {
						local 0 `", `rf`p'opts'"'
						syntax [, LColor(passthru) MColor(passthru) LWidth(passthru) MLWidth(passthru) ///
							RCAP HORizontal VERTical /*Connect(string)*/ OVerlay SEPLine * ]				// check for disallowed options + rcap,
																											// plus additional options -overlay- and -sepline-
						if `"`sepline'"'!=`""' local overlay overlay	// -sepline- implies -overlay-
																										
						// disallowed options
						if `"`horizontal'"'!=`""' | `"`vertical'"'!=`""' {
							nois disp as err `"suboptions {bf:horizontal} and {bf:vertical} not allowed in option {bf:rf`p'opts}"'
							exit 198
						}
						/*
						if `"`connect'"' != `""' {
							nois disp as err `"suboption {bf:connect()} not allowed in option {bf:rf`p'opts()}"'
							exit 198
						}
						*/
						
						// rebuild option list
						if `"`lcolor'"'!=`""' & `"`mcolor'"'==`""'  local mcolor = subinstr(`"`lcolor'"', "l", "m", 1)		// for pc(b)arrow
						if `"`lwidth'"'!=`""' & `"`mlwidth'"'==`""' local mlwidth m`lwidth'									// for pc(b)arrow
						local RFPlot`p'Opts `"`defRFOpts' `rfopts' `mcolor' `lcolor' `mlwidth' `lwidth' `options'"'		// main options first, then options specific to plot `p'
						local RFPlot`p'Type = cond("`rcap'"=="", "`RFPlotType'", "rcap")
						
						// if overlay, use same approach as for CI/PCI
						if trim(`"`overlay'`g_overlay_rf'"') != `""' {
							local touse_add `"`touseDiam' & `plotid'==`p' & float(`_rfUCI')>=float(`CXmin') & float(`_rfLCI')<=float(`CXmax')"'
							// ^^ Note: `touseDiam' & `plotid'==`p' is the previous definition of `touse2'

							// Oct 2022: option to plot prediction interval as separate line from confidence interval
							if trim(`"`sepline'`g_sepline_rf'"') != `""' local touse_add `"`touse_add' & `_USE'==7"'
							else                                         local touse_add `"`touse_add' & inlist(`_USE', 3, 5)"'

							/*
							if trim(`"`sepline'`g_sepline_rf'"') != `""' {
								 local touse_add `"`touse_add' & float(`_rfLCI')==float(`_LCI') & float(`_rfUCI')==float(`_UCI')"'
							}
							else local touse_add `"`touse_add' & float(`_rfLCI')!=float(`_LCI') & float(`_rfUCI')!=float(`_UCI')"'
							*/
							
							// default: both ends within scale (i.e. no arrows)
							// local touse3 `"`touse2' & !`rfLoffscaleL' & !`rfRoffscaleR' & `touse_add'"'
							local touse3 `"`touse_add' & !`rfLoffscaleL' & !`rfRoffscaleR'"'
							local RFPlot `"`macval(RFPlot)' `RFPlot`p'Type' `_rfLCI' `_rfUCI' `id' if `touse3', hor `macval(RFPlot`p'Opts)' ||"'

							// if arrows required
							// local touse3 `"`touse2' & `rfLoffscaleL' & `rfRoffscaleR' & `touse_add'"'
							local touse3 `"`touse_add' & `rfLoffscaleL' & `rfRoffscaleR'"'
							qui count if `touse3'
							if r(N) {													// both ends off scale
								local RFPlot `"`macval(RFPlot)' pcbarrow `id' `_rfLCI' `id' `_rfUCI' if `touse3', `macval(RFPlot`p'Opts)' ||"'
							}
							// local touse3 `"`touse2' & `rfLoffscaleL' & !`rfRoffscaleR' & `touse_add'"'
							local touse3 `"`touse_add' & `rfLoffscaleL' & !`rfRoffscaleR'"'
							qui count if `touse3'
							if r(N) {													// only left off scale
								local RFPlot `"`macval(RFPlot)' pcarrow `id' `_rfUCI' `id' `_rfLCI' if `touse3', `macval(RFPlot`p'Opts)' ||"'
								if "`RFPlotType'" == "rcap" {			// add cap to other end if appropriate
									local RFPlot `"`macval(RFPlot)' rcap `_rfUCI' `_rfUCI' `id' if `touse3', hor `macval(RFPlot`p'Opts)' ||"'
								}
							}
							// local touse3 `"`touse2' & !`rfLoffscaleL' & `rfRoffscaleR' & `touse_add'"'
							local touse3 `"`touse_add' & !`rfLoffscaleL' & `rfRoffscaleR'"'
							qui count if `touse3'
							if r(N) {													// only right off scale
								local RFPlot `"`macval(RFPlot)' pcarrow `id' `_rfLCI' `id' `_rfUCI' if `touse3', `macval(RFPlot`p'Opts)' ||"'
								if "`RFPlotType'" == "rcap" {			// add cap to other end if appropriate
									local RFPlot `"`macval(RFPlot)' rcap `_rfLCI' `_rfLCI' `id' if `touse3', hor `macval(RFPlot`p'Opts)' ||"'
								}
							}
						}
						
						// otherwise, need to do it slightly differently, as we are dealing with two separate (left/right) lines
						// plus, note that `sepline' is assumed *not* to be relevant in this case; this simplies matters slightly
						// (because, if we are "not overlaying" around a diamond, then the line must be on the same row as the diamond)
						else {
							
							// June 2023: we can just use `touse2' as is; that is (reminder):
							// local touse2 `"`touseDiam' & inlist(`_USE', 3, 5) & `plotid'==`p'"'
						
							// identify special cases where only one line required, with two arrows
							local touse3 `"`touse2' & (`rfLoffscaleL' & `rfLoffscaleR') | (`rfRoffscaleL' & `rfRoffscaleR')"'
							qui count if `touse3'
							if r(N) {
								local RFPlot `"`macval(RFPlot)' pcbarrow `id' `_rfLCI' `id' `_rfUCI' if `touse3', `macval(RFPlot`p'Opts)' ||"'
							}
							
							// left-hand line
							local touse_add `"float(`_rfLCI')<=float(`CXmax') & float(`_rfLCI')!=float(`_LCI')"'

							local touse3 `"`touse2' & !`rfLoffscaleL' & !`rfLoffscaleR' & !`offscaleL' & `touse_add'"'
							local RFPlot `"`macval(RFPlot)' `RFPlot`p'Type' `_LCI' `_rfLCI' `id' if `touse3', hor `macval(RFPlot`p'Opts)' ||"'
							
							local touse3 `"`touse2' & `rfLoffscaleL' & !`rfLoffscaleR' & !`offscaleL' & `touse_add'"'
							qui count if `touse3'
							if r(N) {										// left-hand end off scale
								local RFPlot `"`macval(RFPlot)' pcarrow `id' `_LCI' `id' `_rfLCI' if `touse3', `macval(RFPlot`p'Opts)' ||"'
							}

							local touse3 `"`touse2' & !`rfLoffscaleL' & `rfLoffscaleR' & !`offscaleL' & `touse_add'"'
							qui count if `touse3'
							if r(N) {										// right-hand end off scale
								local RFPlot `"`macval(RFPlot)' pcarrow `id' `_rfLCI' `id' `_LCI' if `touse3', `macval(RFPlot`p'Opts)' ||"'
							}

							// right-hand line
							local touse_add `"float(`_rfUCI')>=float(`CXmin') & float(`_rfUCI')!=float(`_UCI')"'
							
							local touse3 `"`touse2' & !`rfRoffscaleL' & !`rfRoffscaleR' & !`offscaleR' & `touse_add'"'
							local RFPlot `"`macval(RFPlot)' `RFPlot`p'Type' `_UCI' `_rfUCI' `id' if `touse3', hor `macval(RFPlot`p'Opts)' ||"'
							
							local touse3 `"`touse2' & `rfRoffscaleL' & !`rfRoffscaleR' & !`offscaleR' & `touse_add'"'
							qui count if `touse3'
							if r(N) {										// left-hand end off scale
								local RFPlot `"`macval(RFPlot)' pcarrow `id' `_rfUCI' `id' `_UCI' if `touse3', `macval(RFPlot`p'Opts)' ||"'
							}

							local touse3 `"`touse2' & !`rfRoffscaleL' & `rfRoffscaleR' & !`offscaleR' & `touse_add'"'
							qui count if `touse3'
							if r(N) {										// right-hand end off scale
								local RFPlot `"`macval(RFPlot)' pcarrow `id' `_UCI' `id' `_rfUCI' if `touse3', `macval(RFPlot`p'Opts)' ||"'
							}
						}
					}			// end else [i.e. if rfdist]
				}			// if trim(`"`rf`p'opts'"')!=`""'
			}			// end if r(N) [i.e. if any obs with _USE==3,5 & plotid==`p']
		}		// end if trim(`"`box`p'opts'`diam`p'opts'`point`p'opts'`ci`p'opts'`oline`p'opts'`ppoint`p'opts'`pci`p'opts'"') != `""'
	}		// end forvalues p = 1/`np'


	* Find invalid/repeated options
	// any such options would generate a suitable error message at the plotting stage
	// so just exit here with error, to save the user's time
	if regexm(`"`rest'"', "(box|diam|point|ci|oline|ociline|ppoint|pci|rf|rfciline)([0-9]+)opt") {
		local badopt = regexs(1)
		local badp = regexs(2)
		
		if `: list badp in plvals' nois disp as err `"option {bf:`badopt'`badp'opts} supplied multiple times; should only be supplied once"'
		else nois disp as err `"`badp' is not a valid {bf:plotid} value"'
		exit 198
	}

	local opts_rest : copy local rest
	// sreturn local options `"`rest'"'	// This is now *just* the standard "twoway" options
										//   i.e. the specialist "forestplot" options have been filtered out
	
	
	* FORM "DEFAULT" TWOWAY PLOT COMMAND (if appropriate)
	// Changed so that FOR WEIGHTED SCATTER each pplval is plotted separately (otherwise weights get messed up)
	// Other (nonweighted) plots can continue to be plotted as before
	if `"`pplvals'"'!=`""' {
	
		local pplvals2 : copy local pplvals						// copy; only needed for weighted scatter plots
		local pplvals : subinstr local pplvals " " ",", all		// so that "inlist" may be used
		local hide
		
		
		* INDIVIDUAL STUDY MARKERS
		local touse2 `"`touse' & `_USE'==1 & inlist(`plotid', `pplvals')"'		// use local, not tempvar, so conditions are copied into plot commands
		qui count if `touse2'
		if r(N) {
		
			* WEIGHTED SCATTER PLOT
			local 0 `", `boxopts'"'
			syntax [, MLABEL(passthru) MSIZe(passthru) * ]	// check for disallowed options
			if `"`mlabel'"' != `""' {
				disp as err "boxopts: option mlabel() not allowed"
				exit 198
			}
			if `"`msize'"' != `""' {
				disp as err "boxopts: option msize() not allowed"
				exit 198
			}
			local scPlotOpts `"`defBoxOpts' `boxopts'"'
			
			if `"`pplvals'"'==`"`plvals'"' {		// if no plot#opts specified, can plot all plotid groups at once
				summ `_WT' if `touse2', meanonly
				if r(N) {
					if `nd'==1 local scPlot `"`macval(scPlot)' scatter `id' `_ES' `awweight' if `tousePlotID' & `_USE'==1 & inlist(`plotid', `pplvals'), `macval(scPlotOpts)' ||"'
					else {
						forvalues d=1/`nd' {
							local scPlot `"`macval(scPlot)' scatter `id' `_ES' `awweight' if `tousePlotID' & `_USE'==1 & inlist(`plotid', `pplvals') & `dataid'==`d', `macval(scPlotOpts)' ||"'
						}
					}
				}
			}
			else {		// else, need to plot each group separately to maintain correct weighting (July 2014)
				foreach p of local pplvals2 {
					summ `_WT' if `touse' & `_USE'==1 & `plotid'==`p', meanonly
					if r(N) {
						if `nd'==1 local scPlot `"`macval(scPlot)' scatter `id' `_ES' `awweight' if `tousePlotID' & `_USE'==1 & `plotid'==`p', `macval(scPlotOpts)' ||"'
						else {
							forvalues d=1/`nd' {
								local scPlot `"`macval(scPlot)' scatter `id' `_ES' `awweight' if `tousePlotID' & `_USE'==1 & `plotid'==`p' & `dataid'==`d', `macval(scPlotOpts)' ||"'
							}
						}
					}
				}
			}		// N.B. scatter if `tousePlotID' <-- "dummy obs" for consistent weighting
			
			
			* CONFIDENCE INTERVAL PLOT
			// N.B. options already processed
			local CIPlotOpts `"`defCIOpts' `ciopts'"'
			
			// default: both ends within scale (i.e. no arrows)
			local CIPlot `"`macval(CIPlot)' `CIPlotType' `_LCI' `_UCI' `id' if `touse2' & !`offscaleL' & !`offscaleR', hor `macval(CIPlotOpts)' ||"'

			// if arrows required
			qui count if `touse2' & `offscaleL' & `offscaleR'
			if r(N) {													// both ends off scale
				local CIPlot `"`macval(CIPlot)' pcbarrow `id' `_LCI' `id' `_UCI' if `touse2' & `offscaleL' & `offscaleR', `macval(CIPlotOpts)' ||"'
			}
			qui count if `touse2' & `offscaleL' & !`offscaleR'
			if r(N) {													// only left off scale
				local CIPlot `"`macval(CIPlot)' pcarrow `id' `_UCI' `id' `_LCI' if `touse2' & `offscaleL' & !`offscaleR', `macval(CIPlotOpts)' ||"'
				if "`CIPlotType'" == "rcap" {			// add cap to other end if appropriate
					local CIPlot `"`macval(CIPlot)' rcap `_UCI' `_UCI' `id' if `touse2' & `offscaleL' & !`offscaleR', hor `macval(CIPlotOpts)' ||"'
				}
			}
			qui count if `touse2' & !`offscaleL' & `offscaleR'
			if r(N) {													// only right off scale
				local CIPlot `"`macval(CIPlot)' pcarrow `id' `_LCI' `id' `_UCI' if `touse2' & !`offscaleL' & `offscaleR', `macval(CIPlotOpts)' ||"'
				if "`CIPlotType'" == "rcap" {			// add cap to other end if appropriate
					local CIPlot `"`macval(CIPlot)' rcap `_LCI' `_LCI' `id' if `touse2' & !`offscaleL' & `offscaleR', hor `macval(CIPlotOpts)' ||"'
				}
			}

			
			* POINT PLOT (point estimates -- except if "classic")
			if "`classic'" == "" {
				local pointPlot `"`macval(pointPlot)' scatter `id' `_ES' if `touse2', `defPointOpts' `pointopts' ||"'
			}
		}			// end if r(N) [i.e. if any obs with _USE==1 & plotid==`ppvals']
		
		
		* OVERALL LINE(S) (if appropriate)
		summ `ovLine' if inlist(`plotid', `pplvals'), meanonly
		if r(N) {
			local olinePlot `"`macval(olinePlot)' rspike `ovMin' `ovMax' `ovLine' if `touse' & inlist(`plotid', `pplvals'), `defOlineOpts' `olineopts' ||"'


			* PREDICTIVE INTERVAL CI LINES (and/or areas)
			// Do these before standard overall lines, in case of area plots
			//  want pred. int. area plot to be underneath the "standard" CI area plot
			// Added Jan 2020
			if trim(`"`rfcilineopts'"') != `""' {
				if `"`rfdist'"'==`""' {
					nois disp as err `"predictive interval not specified; relevant suboptions will be ignored"'
				}
				else {
					local 0 `", `rfcilineopts'"'
					syntax [, LINE AREA HIDE HORizontal VERTical Color(passthru) FColor(passthru) FIntensity(passthru) * ]
			
					// disallowed options
					if `"`horizontal'"'!=`""' | `"`vertical'"'!=`""' {
						nois disp as err `"suboptions {bf:horizontal} and {bf:vertical} not allowed in option {bf:rfcilineopts()}"'
						exit 198
					}
					
					if `"`hide'"'!=`""' qui replace `touseDiam' = 0 if inlist(`plotid', `pplvals')

					// August 2023: don't display vertical lines if: (1) area plot requested; and (2) no explicit line options
					if !(`"`area'`color'`fcolor'`fintensity'"'!=`""' & `"`line'`options'"'==`""') {
						local olinePlot `"`macval(olinePlot)' rspike `ovMin' `ovMax' `rfLineLCI' if `touse' & inlist(`plotid', `pplvals'), `defRFCIlineOpts' `options' ||"'
						local olinePlot `"`macval(olinePlot)' rspike `ovMin' `ovMax' `rfLineUCI' if `touse' & inlist(`plotid', `pplvals'), `defRFCIlineOpts' `options' ||"'
					}
					
					// area plot -- use `touseRFCI'
					if `"`area'`color'`fcolor'`fintensity'"'!=`""' {
						local rfcilineopts `"`color' `fcolor' `fintensity' `options'"'
						local olineAreaPlot `"`macval(olineAreaPlot)' rarea `ovMin' `ovMax' `rfLineX' if `touseRFCI' & inlist(`plotid', `pplvals'), `rfcilineopts' lwidth(none) cmissing(n) ||"'
						qui replace `touseRFCI' = 2 if inlist(`plotid', `pplvals')
					}
					else qui replace `touseRFCI' = 1 if inlist(`plotid', `pplvals')
				}
			}
						
			* OVERALL CI LINES (and/or areas)
			// Added Jan 2020
			if `"`ocilineopts'`influence'"'!=`""' {
				local 0 `", `ocilineopts'"'
				syntax [, LINE AREA HIDE HORizontal VERTical Color(passthru) FColor(passthru) FIntensity(passthru) * ]

				// disallowed options
				if `"`horizontal'"'!=`""' | `"`vertical'"'!=`""' {
					nois disp as err `"suboptions {bf:horizontal} and {bf:vertical} not allowed in option {bf:ociline`p'opts()}"'
					exit 198
				}
				
				if `"`hide'"'!=`""' qui replace `touseDiam' = 0 if inlist(`plotid', `pplvals')

				// August 2023: don't display vertical lines if: (1) area plot requested; and (2) no explicit line options
				if !(`"`area'`color'`fcolor'`fintensity'"'!=`""' & `"`line'`options'"'==`""') {
					local olinePlot `"`macval(olinePlot)' rspike `ovMin' `ovMax' `ovLineLCI' if `touse' & inlist(`plotid', `pplvals'), `defOCIlineOpts' `options' ||"'
					local olinePlot `"`macval(olinePlot)' rspike `ovMin' `ovMax' `ovLineUCI' if `touse' & inlist(`plotid', `pplvals'), `defOCIlineOpts' `options' ||"'
				}
				
				// area plot -- use `touseOCI'
				if `"`area'`color'`fcolor'`fintensity'"'!=`""' {
					local ocilineopts `"`color' `fcolor' `fintensity' `options'"'
					local olineAreaPlot `"`macval(olineAreaPlot)' rarea `ovMin' `ovMax' `ovLineX' if `touseOCI' & inlist(`plotid', `pplvals'), `macval(ocilineopts)' lwidth(none) cmissing(n) ||"'
					qui replace `touseOCI' = 2 if inlist(`plotid', `pplvals')
				}
				else qui replace `touseOCI' = 1 if inlist(`plotid', `pplvals')
			}
		}			// end if r(N) [i.e. if any obs with `ovline' & inlist(plotid, `pplvals')]

		
		* POOLED EFFECT MARKERS		
		local touse2 `"`touseDiam' & inlist(`_USE', 3, 5) & inlist(`plotid', `pplvals')"'	// use local, not tempvar, so conditions are copied into plot commands
		// local touse3 : copy local touse2
		// nois list `_USE' `_ES' `_LCI' `_UCI' `_rfLCI' `_rfUCI' _EFFECT if `touse3'

		// June 2023: "don't plot data..." -- this is now assured, since that data is _USE==7, not included in touse3

		/*
		if `"`rfdist'"'!=`""' {																// Oct 2022: don't plot data from "second" _USE==3|5 row containing pred.int. text
			// local touse3 `"`touse3' & float(`_rfLCI')!=float(`_LCI') & float(`_rfUCI')!=float(`_UCI')"'
			local touse3 `"`touse3' & float(`_rfLCI')<=float(`_LCI') & float(`_rfUCI')>=float(`_UCI')"'
		}
		*/
		qui count if `touse2'
		if r(N) {

			* DIAMONDS - DRAW POLYGONS WITH -twoway rarea-
			* Assume diamond if no "pooled point/CI" options and no "interaction" option
			if trim(`"`ppointopts'`pciopts'`interaction'`diamonds'"') == `""' {
				local diamPlotOpts `"`defDiamOpts' `diamopts'"'
				
				// Now check whether any diamonds are offscale (niche case!)
				// If so, will need to draw round the edges of the polygon, excepting the "offscale edges"
				//   and switch off the line options to -twoway rarea-
				// (draw these lines *after* drawing the area, though, so that the lines appear on top)
				qui count if `touse2' & (`offscaleL' | `offscaleR')
				if r(N) {
					local diamLine `"line `DiamY1' `DiamX' if `touse2', `macval(diamPlotOpts)' cmissing(n) ||"'
					local diamLine `"`macval(diamLine)' line `DiamY2' `DiamX' if `touse2', `macval(diamPlotOpts)' cmissing(n) ||"'
					local diamLWidth `"lwidth(none)"'
				}
				local diamPlot `"`macval(diamPlot)' rarea `DiamY1' `DiamY2' `DiamX' if `touse2', `macval(diamPlotOpts)' `diamLWidth' cmissing(n) || `diamLine' "'
			}
			
		
			* POOLED EFFECT - PPOINT/PCI
			else {
				if trim(`"`diamopts'"') != `""' {
					nois disp as err `"Note: suboptions for both diamond and pooled point/CI specified;"'
					nois disp as err `"      diamond suboptions will be ignored"'
				}	

				// N.B. options already processed
				local PCIPlotOpts `"`defPCIOpts' `pciopts'"'
				
				// default: both ends within scale (i.e. no arrows)
				local PCIPlot `"`macval(PCIPlot)' `PCIPlotType' `_LCI' `_UCI' `id' if `touse2' & !`offscaleL' & !`offscaleR', hor `macval(PCIPlotOpts)' ||"'

				// if arrows are required
				qui count if `touse2' & `offscaleL' & `offscaleR'
				if r(N) {													// both ends off scale
					local PCIPlot `"`macval(PCIPlot)' pcbarrow `id' `_LCI' `id' `_UCI' if `touse2' & `offscaleL' & `offscaleR', `macval(PCIPlotOpts)' ||"'
				}
				qui count if `touse2' & `offscaleL' & !`offscaleR'
				if r(N) {													// only left off scale
					local PCIPlot `"`macval(PCIPlot)' pcarrow `id' `_UCI' `id' `_LCI' if `touse2' & `offscaleL' & !`offscaleR', `macval(PCIPlotOpts)' ||"'
					if "`PCIPlotType'" == "rcap" {			// add cap to other end if appropriate
						local PCIPlot `"`macval(PCIPlot)' rcap `_UCI' `_UCI' `id' if `touse2' & `offscaleL' & !`offscaleR', hor `macval(PCIPlotOpts)' ||"'
					}
				}
				qui count if `touse2' & !`offscaleL' & `offscaleR'
				if r(N) {													// only right off scale
					local PCIPlot `"`macval(PCIPlot)' pcarrow `id' `_LCI' `id' `_UCI' if `touse2' & !`offscaleL' & `offscaleR', `macval(PCIPlotOpts)' ||"'
					if "`PCIPlotType'" == "rcap" {			// add cap to other end if appropriate
						local PCIPlot `"`macval(PCIPlot)' rcap `_LCI' `_LCI' `id' if `touse2' & !`offscaleL' & `offscaleR', hor `macval(PCIPlotOpts)' ||"'
					}
				}				
				local ppointPlot `"`macval(ppointPlot)' scatter `id' `_ES' if `touse2', `defPPointOpts' `ppointopts' ||"'
				
				qui replace `touseDiam' = 1 if inlist(`plotid', `pplvals')		// line, not area
			}
		

			* PREDICTION INTERVAL
			if `"`rfdist'"'==`""' {
				if trim(`"`rfopts'"') != `""' {
					nois disp as err `"predictive interval not specified; relevant suboptions will be ignored"'
				}
			}
			
			else {
			
				// N.B. options already processed
				local RFPlotOpts `"`defRFOpts' `rfopts'"'
			
				// if overlay, use same approach as for CI/PCI
				if `"`g_overlay_rf'"'!=`""' {
					
					// local touse_add `"float(`_rfUCI')>=float(`CXmin') & float(`_rfLCI')<=float(`CXmax')"'
					local touse_add `"`touseDiam' & inlist(`plotid', `pplvals') & float(`_rfUCI')>=float(`CXmin') & float(`_rfLCI')<=float(`CXmax')"'
					// ^^ Note: `touseDiam' & inlist(`plotid', `pplvals') is the previous definition of `touse2'

					// Oct 2022: option to plot prediction interval as separate line from confidence interval
					// if `"`g_sepline_rf'"'!=`""' local touse_add `"`touse_add' & float(`_rfLCI')==float(`_LCI') & float(`_rfUCI')==float(`_UCI')"'
					// else                        local touse_add `"`touse_add' & float(`_rfLCI')!=float(`_LCI') & float(`_rfUCI')!=float(`_UCI')"'
					if `"`g_sepline_rf'"'!=`""' local touse_add `"`touse_add' & `_USE'==7"'
					else                        local touse_add `"`touse_add' & inlist(`_USE', 3, 5)"'
			
					// default: both ends within scale (i.e. no arrows)
					// local touse3 `"`touse2' & !`rfLoffscaleL' & !`rfRoffscaleR' & `touse_add'"'
					local touse3 `"`touse_add' & !`rfLoffscaleL' & !`rfRoffscaleR'"'
					local RFPlot `"`macval(RFPlot)' `RFPlotType' `_rfLCI' `_rfUCI' `id' if `touse3', hor `macval(RFPlotOpts)' ||"'

					// if arrows required
					// local touse3 `"`touse2' & `rfLoffscaleL' & `rfRoffscaleR' & `touse_add'"'
					local touse3 `"`touse_add' & `rfLoffscaleL' & `rfRoffscaleR'"'
					qui count if `touse3'
					if r(N) {													// both ends off scale
						local RFPlot `"`macval(RFPlot)' pcbarrow `id' `_rfLCI' `id' `_rfUCI' if `touse3', `macval(RFPlotOpts)' ||"'
					}
					// local touse3 `"`touse2' & `rfLoffscaleL' & !`rfRoffscaleR' & `touse_add'"'
					local touse3 `"`touse_add' & `rfLoffscaleL' & !`rfRoffscaleR'"'
					qui count if `touse3'
					if r(N) {													// only left off scale
						local RFPlot `"`macval(RFPlot)' pcarrow `id' `_rfUCI' `id' `_rfLCI' if `touse3', `macval(RFPlotOpts)' ||"'
						if "`RFPlotType'" == "rcap" {			// add cap to other end if appropriate
							local RFPlot `"`macval(RFPlot)' rcap `_rfUCI' `_rfUCI' `id' if `touse3', hor `macval(RFPlotOpts)' ||"'
						}
					}
					// local touse3 `"`touse2' & !`rfLoffscaleL' & `rfRoffscaleR' & `touse_add'"'
					local touse3 `"`touse_add' & !`rfLoffscaleL' & `rfRoffscaleR'"'
					qui count if `touse3'
					if r(N) {													// only right off scale
						local RFPlot `"`macval(RFPlot)' pcarrow `id' `_rfLCI' `id' `_rfUCI' if `touse3', `macval(RFPlotOpts)' ||"'
						if "`RFPlotType'" == "rcap" {			// add cap to other end if appropriate
							local RFPlot `"`macval(RFPlot)' rcap `_rfLCI' `_rfLCI' `id' if `touse3', hor `macval(RFPlotOpts)' ||"'
						}
					}
				}
				
				// otherwise, need to do it slightly differently, as we are dealing with two separate (left/right) lines
				// plus, note that `sepline' is assumed *not* to be relevant in this case; this simplies matters slightly
				// (because, if we are "not overlaying" around a diamond, then the line must be on the same row as the diamond)				
				else {
				
					// June 2023: we can just use `touse2' as is; that is (reminder):
					// local touse2 `"`touseDiam' & inlist(`_USE', 3, 5) & inlist(`plotid', `pplvals')"'
				
					// identify special cases where only one line required, with two arrows
					local touse3 `"`touse2' & (`rfLoffscaleL' & `rfLoffscaleR') | (`rfRoffscaleL' & `rfRoffscaleR')"'
					qui count if `touse3'
					if r(N) {
						local RFPlot `"`macval(RFPlot)' pcbarrow `id' `_rfLCI' `id' `_rfUCI' if `touse3', `macval(RFPlotOpts)' ||"'
					}
					
					// left-hand line
					local touse_add `"float(`_rfLCI')<=float(`CXmax') & float(`_rfLCI')!=float(`_LCI')"'

					local touse3 `"`touse2' & !`rfLoffscaleL' & !`rfLoffscaleR' & !`offscaleL' & `touse_add'"'
					local RFPlot `"`macval(RFPlot)' `RFPlotType' `_LCI' `_rfLCI' `id' if `touse3', hor `macval(RFPlotOpts)' ||"'
					
					local touse3 `"`touse2' & `rfLoffscaleL' & !`rfLoffscaleR' & !`offscaleL' & `touse_add'"'
					qui count if `touse3'
					if r(N) {										// left-hand end off scale
						local RFPlot `"`macval(RFPlot)' pcarrow `id' `_LCI' `id' `_rfLCI' if `touse3', `macval(RFPlotOpts)' ||"'
					}

					local touse3 `"`touse2' & !`rfLoffscaleL' & `rfLoffscaleR' & !`offscaleL' & `touse_add'"'
					qui count if `touse3'
					if r(N) {										// right-hand end off scale
						local RFPlot `"`macval(RFPlot)' pcarrow `id' `_rfLCI' `id' `_LCI' if `touse3', `macval(RFPlotOpts)' ||"'
					}

					// right-hand line
					local touse_add `"float(`_rfUCI')>=float(`CXmin') & float(`_rfUCI')!=float(`_UCI')"'
					
					local touse3 `"`touse2' & !`rfRoffscaleL' & !`rfRoffscaleR' & !`offscaleR' & `touse_add'"'
					local RFPlot `"`macval(RFPlot)' `RFPlotType' `_UCI' `_rfUCI' `id' if `touse3', hor `macval(RFPlotOpts)' ||"'
					
					local touse3 `"`touse2' & `rfRoffscaleL' & !`rfRoffscaleR' & !`offscaleR' & `touse_add'"'
					qui count if `touse3'
					if r(N) {										// left-hand end off scale
						local RFPlot `"`macval(RFPlot)' pcarrow `id' `_rfUCI' `id' `_UCI' if `touse3', `macval(RFPlotOpts)' ||"'
					}

					local touse3 `"`touse2' & !`rfRoffscaleL' & `rfRoffscaleR' & !`offscaleR' & `touse_add'"'
					qui count if `touse3'
					if r(N) {										// right-hand end off scale
						local RFPlot `"`macval(RFPlot)' pcarrow `id' `_UCI' `id' `_rfUCI' if `touse3', `macval(RFPlotOpts)' ||"'
					}
				}
			}		// end if `"`rfdist'"'!=`""'
		}		// end if r(N) [i.e. if any obs with _USE==3,5 & plotid==`ppvals']
	}		// end if `"`pplvals'"'!=`""'
	
	// END GRAPH OPTS	
	
	
	* If necessary, finish off storing values for later plotting
	// added Jan 2020
	qui count if `touse' & `touseOCI'
	if r(N) {
		sort `touse' `dataid' `olinegroup' `id'
		qui by `touse' `dataid' `olinegroup' : gen `ovLineLCI' = `_LCI'[1] if `touse' & `check' & !(`_LCI'[1] > `CXmax' | `_LCI'[1] < `CXmin')
		qui by `touse' `dataid' `olinegroup' : gen `ovLineUCI' = `_UCI'[1] if `touse' & `check' & !(`_UCI'[1] > `CXmax' | `_UCI'[1] < `CXmin')
	}
	if `"`rfdist'"'!=`""' {
		qui count if `touse' & `touseRFCI'
		if r(N) {
			sort `touse' `dataid' `olinegroup' `id'
			qui by `touse' `dataid' `olinegroup' : gen `rfLineLCI' = `_rfLCI'[1] if `touse' & `check' & !(`_rfLCI'[1] > `CXmax' | `_rfLCI'[1] < `CXmin')
			qui by `touse' `dataid' `olinegroup' : gen `rfLineUCI' = `_rfUCI'[1] if `touse' & `check' & !(`_rfUCI'[1] > `CXmax' | `_rfUCI'[1] < `CXmin')
		}
	}
	
	
	// Now, having completed parsing graph opts, reset `touse' and `id' in case of any changes (e.g. "hidden" pooled obs)
	tempvar touse_id35
	qui gen byte `touse_id35' = `touse' * inlist(`_USE', 3, 5, 7) * !`touseDiam'		// `hide'
	
	// `id' : identify obs with `_USE'==3 or 5, and subtract 1 from obs above
	qui count if `touse_id35'
	if r(N) {
		tempvar id35
		qui bysort `touse' (`id') : gen long `id35' = sum(`touse_id35')
		qui replace `id' = `id' - `id35' if `touse'
		qui replace `touse' = 0 if `touse_id35'
	}
	
	// Having done this, limit the ovline variables to just the first observation within each olinegroup
	// (to prevent multiple overlapping lines from being drawn)
	sort `touse' `dataid' `olinegroup' `id'
	qui by `touse' `dataid' `olinegroup' : replace `ovLine'  = . if _n > 1
	qui by `touse' `dataid' `olinegroup' : gen `ovMin' = `id'[1]  - 0.5 if `touse' & _n==1 & !missing(`ovLine')
	qui by `touse' `dataid' `olinegroup' : gen `ovMax' = `id'[_N] + 0.5 if `touse' & _n==1 & !missing(`ovLine')

	qui count if `touse' & `touseOCI'
	if r(N) {
		qui by `touse' `dataid' `olinegroup' : replace `ovLineLCI' = . if _n > 1
		qui by `touse' `dataid' `olinegroup' : replace `ovLineUCI' = . if _n > 1
	}
	if `"`rfdist'"'!=`""' {
		qui count if `touse' & `touseRFCI'
		if r(N) {
			qui by `touse' `dataid' `olinegroup' : replace `rfLineLCI' = . if _n > 1
			qui by `touse' `dataid' `olinegroup' : replace `rfLineLCI' = . if _n > 1
		}
	}
	
	
	*** AREA PLOTS
	// Jan 2020: consider all these together, so that their sort orders don't cause conflicts

	// August 2018
	// DRAW DIAMONDS AS POLYGONS USING -twoway rarea-
	// SO THAT THEY MAY BE FILLED IN (also requires fewer variables)
	qui count if `touse' & inlist(`_USE', 3, 5) & `touseDiam'==2		// 2 = area (default)
	if !r(N) qui replace `touseDiam' = 1 if `touseDiam'>1				// to avoid error if no obs with _USE=3 or 5
	else {
		qui expand 4 if `touseDiam'==2 & inlist(`_USE', 3, 5)
		qui bysort `touse' `id' : replace `touseDiam' = (`touseDiam'>0) * _n
		qui replace `touseDiam' = 1 if `touseDiam'>1 & !inlist(`_USE', 3, 5)
		
		// x-coords
		qui gen float `DiamX' = cond(`offscaleL', `CXmin', `_LCI') if `touseDiam'==1 & float(`_ES') >= float(`CXmin')
		qui replace   `DiamX' = `_ES' if `touseDiam'==2
		qui replace   `DiamX' = `CXmin' if `touseDiam'==2 & float(`_ES') < `CXmin'
		qui replace   `DiamX' = `CXmax' if `touseDiam'==2 & float(`_ES') > `CXmax'
		qui replace   `DiamX' = . if `touseDiam'==2 & (float(`_UCI') < `CXmin' | float(`_LCI') > `CXmax')
		qui replace   `DiamX' = cond(`offscaleR', `CXmax', `_UCI') if `touseDiam'==3 & float(`_ES') <= float(`CXmax')
		qui replace   `DiamX' = . if `touseDiam'==4
		
		// upper y-coords
		qui gen float `DiamY1' = cond(`offscaleL', `id' + 0.4*( abs((`CXmin'-`_LCI')/(`_ES'-`_LCI')) ), `id') if `touseDiam'==1 & float(`_ES') >= float(`CXmin')
		qui replace   `DiamY1' = `id' + 0.4 if `touseDiam'==2
		qui replace   `DiamY1' = `id' + 0.4*( abs((`_UCI'-`CXmin')/(`_UCI'-`_ES')) ) if `touseDiam'==2 & float(`_ES') < float(`CXmin')
		qui replace   `DiamY1' = `id' + 0.4*( abs((`CXmax'-`_LCI')/(`_ES'-`_LCI')) ) if `touseDiam'==2 & float(`_ES') > float(`CXmax')
		qui replace   `DiamY1' = cond(`offscaleR', `id' + 0.4*( abs((`_UCI'-`CXmax')/(`_UCI'-`_ES')) ), `id') if `touseDiam'==3 & float(`_ES') <= float(`CXmax')
		qui replace   `DiamY1' = . if `touseDiam'==4
		
		// lower y-coords
		qui gen float `DiamY2' = cond(`offscaleL', `id' - 0.4*( abs((`CXmin'-`_LCI')/(`_ES'-`_LCI')) ), `id') if `touseDiam'==1 & float(`_ES') >= float(`CXmin')
		qui replace   `DiamY2' = `id' - 0.4 if `touseDiam'==2
		qui replace   `DiamY2' = `id' - 0.4*( abs((`_UCI'-`CXmin')/(`_UCI'-`_ES')) ) if `touseDiam'==2 & float(`_ES') < float(`CXmin')
		qui replace   `DiamY2' = `id' - 0.4*( abs((`CXmax'-`_LCI')/(`_ES'-`_LCI')) ) if `touseDiam'==2 & float(`_ES') > float(`CXmax')
		qui replace   `DiamY2' = cond(`offscaleR', `id' - 0.4*( abs((`_UCI'-`CXmax')/(`_UCI'-`_ES')) ), `id') if `touseDiam'==3 & float(`_ES') <= float(`CXmax')
		qui replace   `DiamY2' = . if `touseDiam'==4
	}
	
	// OCILine area plots
	qui count if `touse' & `touseOCI'==2		// 2 = area
	if r(N) {
		qui count if `touse' & `touseOCI'==2 & !missing(`ovLineLCI', `ovLineUCI')
		if r(N) {
			qui expand 3 if `touse' & `touseOCI'==2 & !missing(`ovLineLCI', `ovLineUCI')
			qui bysort `touse' `id' (`touseDiam') : replace `touseOCI' = (`touseOCI'>0) * _n
			qui gen float `ovLineX' = cond(`offscaleL', `CXmin', `ovLineLCI') if `touseOCI'==1 & float(`_ES') >= float(`CXmin')
			qui replace   `ovLineX' = cond(`offscaleR', `CXmax', `ovLineUCI') if `touseOCI'==2 & float(`_ES') <= float(`CXmax')
			qui replace   `ovLineX' = . if `touseOCI'==3
		}
	}
		
	// RFCILine area plots
	if `"`rfdist'"'!=`""' {
		qui count if `touse' & `touseRFCI'==2		// 2 = area
		if r(N) {
			qui count if `touse' & `touseRFCI'==2 & !missing(`rfLineLCI', `rfLineUCI')
			if r(N) {
				qui expand 3 if `touse' & `touseRFCI'==2 & !missing(`rfLineLCI', `rfLineUCI')
				qui bysort `touse' `id' (`touseDiam' `touseOCI') : replace `touseRFCI' = (`touseRFCI'>0) * _n
				qui gen float `rfLineX' = cond(`rfLoffscaleL', `CXmin', `rfLineLCI') if `touseRFCI'==1 & float(`_ES') >= float(`CXmin')
				qui replace   `rfLineX' = cond(`rfRoffscaleR', `CXmax', `rfLineUCI') if `touseRFCI'==2 & float(`_ES') <= float(`CXmax')
				qui replace   `rfLineX' = . if `touseRFCI'==3
			}
		}
	}

	qui replace `touse' = 0 if `touseDiam' > 1 | `touseOCI' > 1
	if `"`rfdist'"'!=`""' {
		qui replace `touse' = 0 if `touseRFCI' > 1
	}
	
	* Now truncate CIs at CXmin/CXmax
	qui {
		local touse2 `"`touse' * inlist(`_USE', 1, 3, 5, 7)"'

		replace `_LCI' = `CXmin' if `offscaleL'
		replace `_UCI' = `CXmax' if `offscaleR'
		replace `_LCI' = . if `touse2' & float(`_UCI') < float(`CXmin')
		replace `_UCI' = . if `touse2' & float(`_LCI') > float(`CXmax')
		replace `_ES'  = . if `touse2' & float(`_ES')  < float(`CXmin')
		replace `_ES'  = . if `touse2' & float(`_ES')  > float(`CXmax')

		if `"`rfdist'"'!=`""' {
			
			// Standard case:
			tempvar rflci2
			clonevar `rflci2' = `_rfLCI'
			replace `_rfLCI' = . if `touse2' & (`offscaleL' | float(`_rfLCI') < float(`CXmin'))
			replace `_rfUCI' = . if `touse2' & (`offscaleR' | (float(`rflci2') > float(`CXmax') & !missing(`rflci2')))
			drop `rflci2'
			
			replace `_rfLCI' = `CXmin' if `rfLoffscaleL'
			replace `_rfUCI' = `CXmax' if `rfRoffscaleR'
		
			// Niche case:
			// If one end of both CI and rfCI are offscale in same direction,
			// and the other end of the CI is *also* outside the CXmin/CXmax limits (albeit not marked as offscale)
			// (i.e. the only visible piece will be *part of one end* of the rfCI)
			// then that piece of the rfCI needs an arrow pointing *towards* _ES.
			// (This will need checking for again when it comes to constructing the rfplot)
			cap confirm numeric var `rfRoffscaleL'
			if !_rc {
				replace `_rfLCI' = `CXmin' if `touse2' & `rfRoffscaleL'
				replace `_UCI'   = `CXmin' if `touse2' & `rfRoffscaleL'
			}
			else local rfRoffscaleL = 0
			
			cap confirm numeric var `rfLoffscaleR'
			if !_rc {
				replace `_rfUCI' = `CXmax' if `touse2' & `rfLoffscaleR'
				replace `_LCI'   = `CXmax' if `touse2' & `rfLoffscaleR'
			}
			else local rfLoffscaleR = 0
		}
	}
	
	// null line, and upper horizontal border line
	// amended Nov 2021	
	summ `id' if `touse' & `_USE'==9, meanonly
	if r(N) {
		local borderline = r(min) - 1 - 0.25
	}
	else {
		summ `id' if `touse' & `_USE'!=9, meanonly
		local borderline = r(max) + 1 - 0.25
	}	
	
	// horizontal "border" line between data and headings
	local 0 `", `hlineopts'"'
	syntax [, HORizontal VERTical /*Connect(string)*/ * ]
	if `"`horizontal'"'!=`""' | `"`vertical'"'!=`""' {
		nois disp as err `"suboptions {bf:horizontal} and {bf:vertical} not allowed in option {bf:hlineopts()}"'
		exit 198
	}
	local borderCommand `"yline(`borderline', `defHlineOpts' `options')"'

	// null line (unless switched off)
	if "`null'" == "" {
		local 0 `", `nlineopts'"'
		syntax [, HORizontal VERTical /*Connect(string)*/ * ]
		if `"`horizontal'"'!=`""' | `"`vertical'"'!=`""' {
			nois disp as err `"suboptions {bf:horizontal} and {bf:vertical} not allowed in option {bf:nlineopts()}"'
			exit 198
		}
		/*
		if `"`connect'"' != `""' {
			nois disp as err `"suboption {bf:connect()} not allowed in option {bf:nlineopts()}"'
			exit 198
		}
		*/
		
		// DF: modified to use added line approach instead of pcspike (less complex & poss. more efficient as fewer vars)
		local nullCommand `" function y=`h0', horiz range(0 `borderline') n(2) `defNlineOpts' `options' ||"'
	}

	
	sreturn clear
	sreturn local options `"`macval(opts_rest)'"'	// This is now *just* the standard "twoway" options
													//   i.e. the specialist "forestplot" options have been filtered out
	
	// Return plot commands...
	sreturn local bordercommand `"`borderCommand'"'
	
	// ... unless `colsonly'
	if `"`colsonly'"'==`""' {
		sreturn local scplot        `"`scPlot'"'
		sreturn local ciplot        `"`CIPlot'"'
		sreturn local rfplot        `"`RFPlot'"'
		sreturn local pciplot       `"`PCIPlot'"'
		sreturn local diamplot      `"`diamPlot'"'
		sreturn local pointplot     `"`pointPlot'"'
		sreturn local ppointplot    `"`ppointPlot'"'
		sreturn local olineplot     `"`olinePlot'"'
		sreturn local olineareaplot `"`olineAreaPlot'"'
		sreturn local nullcommand   `"`nullCommand'"'
		
		// Nov 2021: see notes above
		sreturn local g_olinefirst  `"`g_olinefirst'"'
		sreturn local g_nlinefirst  `"`g_nlinefirst'"'
		sreturn local g_overlay_ci  `"`g_overlay_ci'"'
	}
	
end	
	

