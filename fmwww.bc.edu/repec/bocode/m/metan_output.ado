* metan_output.ado
* Subroutine to handle outputs following a meta-analysis,
*   principally on-screen table and saved dataset (with optional call to -forestplot-)
* Called by metan.ado; do not run directly

*!  version 4.08  David Fisher  17jun2024
*! version 4.08.1  David Fisher  12jul2024

* version 4.08.1
// Minor bug fixes to allow programs to run without error under Stata versions 15 and older


program define metan_output, rclass
// [Note: this subroutine handles output only and does not itself return any values ]
// [rclass only for -return add- following call to -forestplot-]

	syntax varlist(numeric min=3 max=7 default=none) [if] [in] , STUDY(varname numeric) ///
		[ TOUSE2(varname) SAVING(passthru) CLEAR CLEARSTACK BY(varname numeric) noTABle noGRaph ///
		noHEADER noINTeger HETPooled * ]	/* <-- not needed for this subroutine; parse them and then discard */
	
	local use_invlist `varlist'	// for clarity: this contains `_USE' `invlist'
	marksample touse, novarlist		// -novarlist- option prevents -marksample- from setting `touse' to zero if any missing values in `varlist'
									// we want to control this behaviour ourselves, e.g. by using KEEPALL option

	// June 2022: because of use of both `touse' and `touse2' in metan_output.ado
	// need to construct bylist once before passing to subroutines, particularly BuildResultsSet
	if `"`by'"'!=`""' {
		qui levelsof `by' if `touse', missing local(bylist)	// "missing" since `touse' should already be appropriate for missing yes/no
		local byopts by(`by') bylist(`bylist')
	}
	
	if `"`clearstack'"'!=`""' local clear clearstack
		
	// Unless no table AND no graph AND no saving/clear, store study value labels in new var "_LABELS"
	if !(`"`table'"'!=`""' & `"`graph'"'!=`""' & `"`saving'"'==`""' & `"`clear'"'==`""') {
		cap confirm numeric var `touse2'
		if !_rc local useflag useflag
		else local touse2 `touse'		
		
		tempvar _LABELS
		cap decode `study' if `touse2', gen(`_LABELS')			// if value label
		// if _rc qui gen `_LABELS' = string(`study') if `touse2'	// if no value label
		
		if _rc==182 qui gen `_LABELS' = ""								// if no value label
		else if _rc {
			decode `study' if `touse2', gen(`_LABELS')			// otherwise force exit, with appropriate error message
		}
		
		qui replace `_LABELS' = strofreal(`study', `"`: format `study''"') if `touse2' & missing(`_LABELS')
		// ^^ added Aug 2020;  if *some* values are labelled but *not* all, take the values themselves
		// -decode- replaces with missing if no label defined for a particular value
		// hence, use these lines regardless of whether a value label exists

		// missing values of `study'
		// string() works with ".a" etc. but not "." -- contrary to documentation??
		// qui replace `_LABELS' = "." if `touse2' & missing(`_LABELS') & !missing(`study')

	}
	
	

	**************************
	* Print to screen:       *
	*  - summary description *
	*  - results table       *
	**************************
	
	cap nois DrawTableAD `use_invlist' if `touse', labels(`_LABELS') `byopts' `table' `options'

	local options `"`s(opts_adm)'"'
	if `"`s(fpnote)'"'!=`""' local fpnote `"fpnote(`s(fpnote)')"'
	
	if _rc {
		nois disp as err `"Error in {bf:metan_output.DrawTableAD}"'
		c_local err noerr
		exit _rc
	}

	
	********************************
	* Build forestplot results set *
	********************************
	
	// Store contents of existing characteristics
	//  with same names as those to be used by BuildResultsSet
	local char_fpuseopts  `"`char _dta[FPUseOpts]'"'
	local char_fpusevlist `"`char _dta[FPUseVarlist]'"'

	// Blanked out Mar2022 -- variable labels should already be applied
	/*
	if `"`_STUDY'"'!=`""' {
		label variable `_STUDY' `"`svarlab'"'
	}
	if `"`_BY'"'!=`""' {
		label variable `_BY' `"`byvarlab'"'
	}
	*/
	
	* 1. Create the results-set structure
	//  (including some tempvars; hence the subroutine)
	* 2. Send the data to -forestplot- to create the forest plot
	* 3. Save the results-set (in Stata "dta" format)
	//  (after renaming tempvars to permanent names)
	//   and with characteristics set so that "forestplot, useopts" can be called.

	// July 2021:
	// Only need to do this if:
	// - saving a results set
	// - creating a forest plot
	// - clearing the original data, to leave the results set in memory
	if `"`saving'"'!=`""' | `"`clear'"'!=`""' | `"`graph'"'==`""' {
		
		cap nois BuildResultsSet `use_invlist' if `touse2', labels(`_LABELS') `useflag' study(`study') ///
			`fpnote' `graph' `saving' `clear' `options' // <-- passed back from PrintDesc

		if _rc {
			if `"`err'"'==`""' {
				if _rc==1 nois disp as err `"User break in {bf:metan_output.BuildResultsSet}"'
				else nois disp as err `"Error in {bf:metan_output.BuildResultsSet}"'
				nois disp as err `"(Note: meta-analysis model was fitted successfully)"'
			}
			c_local err noerr
			local rc = _rc
			
			// clear/restore characteristics
			char _dta[FPUseOpts]    `char_fpuseopts'
			char _dta[FPUseVarlist] `char_fpusevlist'
			
			exit `rc'
		}	// end if _rc
		
		return add		// [May 2023] from -forestplot-

	}
		
end





********************************************************************************

* Routine to draw output table ( -metan- version)
// Could be done using "tabdisp", but doing it myself means it can be tailored to the situation
// therefore looks better (I hope!)

program define DrawTableAD, sclass sortpreserve


	** First, print to screen a description of the summary statistic and method
	syntax varlist(numeric min=3 max=7) [if] [in] [, LABELS(varname string) * ]
	// ^^ these options have already been parsed in the main routine metan_output.ado, so don't return them in s(options)
	
	marksample touse, novarlist		// -novarlist- option prevents -marksample- from setting `touse' to zero if any missing values in `varlist'
	gettoken _USE invlist : varlist
	
	cap nois PrintDesc if `touse', `options'
	if _rc {
		nois disp as err `"Error in {bf:metan_output.PrintDesc}"'
		c_local err noerr
		exit _rc
	}
	
	local nzt = cond("`s(nzt)'"=="", 0, `s(nzt)')
	sreturn local opts_adm `"`s(options)'"'

	
	** Now setup for output table
	local 0 `", `s(opts_adm)'"'
	syntax , SORTBY(varlist) MODELLIST(namelist) TESTSTATLIST(namelist) QSTAT(name) OUTVLIST(varlist numeric min=5 max=7) ///
		[ SUMMSTAT(name) LABTITLE(string) EFFECT(string) noMODELLABels /* <-- NEW NOV 2020 */ ///
		BY(varname numeric) BYLIST(numlist miss) BYSTATSLIST(namelist) BYQ(name) QLIST(numlist miss min=2 max=7) ///
		HETSTATS(namelist) MWT(name) OVSTATS(name) PRoportion PRVLIST(varlist numeric min=3 max=3) DENOMinator(real 1) ///
		CUmulative INFluence noOVerall noSUbgroup noSECsub SUMMARYONLY OVWt SGWt EFORM ///
		noTABle noHET noBETWeen noWT KEEPOrder ILevel(cilevel) OLevel(cilevel) HLevel(cilevel) TESTBased ISQParam * ]
	
	// [Nov 2020:]
	// extra options may include:
	// - `opts_adm' -- general options
	// - model#opts(string) -- model options, in particular `model1opts' for display based on main/primary model
	// - label#opt(string) -- model label (e.g. IV, or Fixed);  c.f. "desc" in "first(es lci uci desc)" or "second(...)"
	// - extra#opt(string) -- "extra" label (e.g. heterogeneity, for forest plot);  c.f. firststats(), secondstats()
	// - user#stats(numlist min=3 max=3) -- c.f. "es lci uci" in "first(es lci uci desc)" or "second(...)"
	
	// June 2024: improve error message due to similarity between hetstats (matrix) and hetinfo (option)
	if `: word count `hetstats''>1 {
		nois disp as err "option hetstats():  too many names specified"
		nois disp as err "Check whether the option {bf:hetinfo()} was intended instead"
		exit 103
	}
	
	// unpack outvlist
	tokenize `outvlist'
	args _ES _seES _LCI _UCI _WT _NN _CC
	
	// rename `labels' to `_LABELS' to avoid confusion with label#opt() labelling options
	local _LABELS : copy local labels
		
	// Maintain original order if requested
	if `"`keeporder'"'!=`""' {
		tempvar tempuse
		qui gen byte `tempuse' = `_USE'
		qui replace `tempuse' = 1 if `_USE'==2		// keep "insufficient data" studies in original study order (default is to move to end)
	}
	else local tempuse `_USE'
		
	sort `touse' `by' `tempuse' `sortby'
	tempvar obs
	qui gen long `obs' = _n

	// Having assembled `coeffs', we want to display proportions on their original scale
	// (unless -nopr- , but then also no `prvlist' )
	// so point DrawTableAD to _Prop_ES etc.
	if `"`prvlist'"'!=`""' {
		tokenize `prvlist'
		args _ES _LCI _UCI
		
		local eff     prop_eff
		local eff_lci prop_lci
		local eff_uci prop_uci
	}
	else {		// defaults
		local eff     eff
		local eff_lci eff_lci
		local eff_uci eff_uci
	}

	
	** Create table of results
	
	* Multiple models: extract labels etc. before we start
	// Note: `modellist' and `teststatlist' include user-defined models (marked with "user")
	// ... label`j'opt, user`j'stats and wgtopt`j' (latter obtained from within model`j'opts) also include user-defined models
	// However, `ovstats' only has columns for *non* user-defined models
	// ... and `bystatslist' only has elements for *non* user-defined models
	// ... similar for `byhet', `mwt'

	gettoken model1 : modellist	
	local m : word count `modellist'
	local options2 : copy local options
	forvalues j = `m' (-1) 1 {			// in reverse so that `model1opts' are left in memory
		local 0 `", `options2'"'
		syntax [, MODEL`j'opts(string) LABEL`j'opt(string) USER`j'stats(numlist min=3 max=3) * ]
		local options2 `"`macval(options)'"'

		local 0 `", `model`j'opts'"'
		syntax [, WGT(varname) CC(string) ISQSA(real 80) TSQSA(real -99) HKSj KRoger RObust BArtlett SKovgaard * ]
		local wgtopt`j' : copy local wgt

		if "`: word `j' of `modellist''"=="sa" & `"`label`j'opt'"'=="SA" {
			if `tsqsa'==-99 local label`j'opt `"SA(I{c 178}=`isqsa'%)"'
			else local label`j'opt = `"SA(tau{c 178}="' + strofreal(`tsqsa', "%05.3f") + `")"'
		}
	}
	
	// Subgroups: some work needed beforehand in case of -noTABle-
	local swidth = 1
	tempvar vlablen
	if `"`by'"'!=`""' {
		// qui levelsof `by' if `touse', missing local(bylist)		// "missing" since `touse' should already be appropriate for missing yes/no
		// [Mar 2020] Moved oustide DrawTableAD so that subgroups with all _USE==2 are still displayed
		
		local bylab : value label `by'		
		tempvar bylabels
		cap decode `by', gen(`bylabels')
		if _rc local bylabels `"string(`by')"'
		qui gen long `vlablen' = length(`bylabels')
		summ `vlablen' if `touse', meanonly
		local swidth = r(max)
		cap drop `bylabels'
		qui drop `vlablen'
	}
	local nby = max(1, `: word count `bylist'')
	tempname _ES_ _seES_			// will need these two regardless of `table'

	* Expand `cc'
	if `"`cc'"'!=`""' {
		local 0 `cc'
		syntax anything(name=ccval id="value supplied to {bf:cc()}") [, *]
		confirm number `ccval'
	}
	else local ccval = 0	
	
	if `"`table'"'==`""' {
		
		* Find maximum length of labels in LHS column
		qui gen long `vlablen' = length(`_LABELS')		
		if "`cc'"!="" & "`_CC'"!="" {							// cc used with "primary" model
			qui replace `vlablen' = `vlablen' + 2 if `_CC'		// for a space and asterisk if cc
		}
		// update swidth [fixed Mar 2020]
		summ `vlablen' if `touse', meanonly
		local swidth = max(`swidth', r(max))
		drop `vlablen'
		
		* Find maximum length of study title and effect title
		//  Allow them to spread over several lines, but only up to a maximum number of chars
		//  If a single line must be more than 32 chars, truncate and stop
		local uselen = cond("`tarone'"=="", 20, 24)
		
		if `swidth' > `uselen' local uselen = min(`swidth', 31)
		SpreadTitle `"`labtitle'"', target(`uselen') maxwidth(31)		// study (+ subgroup) title
		local swidth = 1 + max(`uselen', `r(maxwidth)')
		local slines = r(nlines)
		forvalues i = 1 / `slines' {
			local stitle`i' `"`r(title`i')'"'
		}
		SpreadTitle `"`effect'"', target(10) maxwidth(15)		// effect title (i.e. "Odds ratio" etc.)
		local ewidth = 1 + max(10, `r(maxwidth)')
		local elines = r(nlines)				
		local diff = `elines' - `slines'
				
		if `diff'<=0 {
			forvalues i = 1 / `slines' {
				local etitle`i' `"`r(title`=`i'+`diff'')'"'		// stitle uses most lines (or equal): line up etitle with stitle
			}
		}
		else {
			forvalues i = `elines' (-1) 1 {				// run backwards, otherwise macros are deleted by the time they're needed
				local etitle`i' `"`r(title`i')'"'
				local stitle`i' = cond(`i'>=`diff', `"`stitle`=`i'-`diff'''"', `""')	// etitle uses most lines: line up stitle with etitle
			}
		}
		
		// June 2020, modified March 2024: now calculate `nl'...
		local nl = max(`elines', `slines')
		if "`wt'"=="" & (`m' > 1 | `"`cumulative'`influence'"'!=`""') local nl = max(`nl', 2)

		// ...and arrange etitle & stitle so they appear together on the lowest lines
		local old_nl = max(`elines', `slines')
		if `old_nl' < `nl' {
			local diff = `nl' - `old_nl'
			forvalues i = `elines' (-1) 1 {				// run backwards, otherwise macros are deleted by the time they're needed
				local etitle`=`i'+`diff'' : copy local etitle`i'
			}
			forvalues i = `slines' (-1) 1 {				// run backwards, otherwise macros are deleted by the time they're needed
				local stitle`=`i'+`diff'' : copy local stitle`i'
			}
			forvalues i = 1 / `diff' {
				local etitle`i'
				local stitle`i'
			}
		}
		
		* Now display the title lines, starting with the "extra" lines and ending with the row including CI & weight
		local nl = max(`elines', `slines')
		local wtitle`nl'
		local wwidth = 1	// nowt
		if "`wt'"=="" {
			local wwidth = 11
			if `"`cumulative'`influence'"'!=`""' {
				local nl = max(`nl', 2)
				local wtitle`=`nl'-1' `"{col `=`swidth'+`ewidth'+27'}Ratio of"'
				local wtitle`nl'      `"{col `=`swidth'+`ewidth'+27'}Variances"'
			}
			else if `m' > 1 {
				local nl = max(`elines', `slines', 2)
				local wtitle`=`nl'-1' `"{col `=`swidth'+`ewidth'+27'}% Weight,"'
				
				if length("`label1opt'") < 5 {
					local wtitle`nl' `"{col `=`swidth'+`ewidth'+30'}`label1opt'"'
				}
				else {
					local abbr = abbrev(`"`label1opt'"', 7)
					local wtitle`nl' `"{col `=`swidth'+`ewidth'+28'}`abbr'"'
				}
			}
			else local wtitle`nl' `"{col `=`swidth'+`ewidth'+27'}% Weight"'
		}
		
		disp as text _n `"{hline `swidth'}{c TT}{hline `=`ewidth'+24+`wwidth''}"'
		if `nl' > 1 {
			forvalues i = 1 / `=`nl'-1' {
				disp as text `"`stitle`i''{col `=`swidth'+1'}{c |} "' %~`ewidth's `"`etitle`i''"' %~`wwidth's `"`wtitle`i''"'
			}
		}
		disp as text `"`stitle`nl''{col `=`swidth'+1'}{c |} "' ///
			%~`ewidth's `"`etitle`nl''"' `"{col `=`swidth'+`ewidth'+4'}[`ilevel'% Conf. Interval]`wtitle`nl''"'


		** Loop over studies, and subgroups if appropriate
		if "`by'"!="" {
			tempvar touse2
			gen byte `touse2' = `touse'
		}
		else local touse2 `touse'
		
		tempname _LCI_ _UCI_ _WT_ critval
		local xexp = cond("`eform'"!="", "exp", "")

		forvalues i = 1 / `nby' {				// this will be 1/1 if no subgroups

			disp as text `"{hline `swidth'}{c +}{hline `=`ewidth'+24+`wwidth''}"'

			if `"`by'"'!=`""' {
				local byi : word `i' of `bylist'
				qui replace `touse2' = `touse' * (float(`by')==float(`byi'))
				
				if `"`bylab'"'!=`""' {
					local bylabi : label `bylab' `byi'
				}
				else local bylabi `"`byi'"'

				local nodata
				summ `_ES' if `touse2', meanonly
				if !r(N) local nodata `"{col `=`swidth'+4'} (No subgroup data)"'
				
				disp as text substr(`"`bylabi'"', 1, `swidth'-1) + `"{col `=`swidth'+1'}{c |}`nodata'"'
				local nodata	// clear macro
			}
			
			summ `obs' if `touse2', meanonly
			if r(N) & `"`summaryonly'"'==`""' {
				forvalues k = `r(min)' / `r(max)' {
					if `_USE'[`k']==2 | missing(`_seES'[`k']) | float(`_seES'[`k'])==0 {
						if `_USE'[`k']==1 & "`model1'"!="qe" /*& `: list posof "mh" in modellist'*/ {		// June 2020, updated June 2022, updated Jan 2024
							disp as text substr(`_LABELS'[`k'], 1, 32) `"{col `=`swidth'+1'}{c |}{col `=`swidth'+4'} (Insufficient data for IV)"'
						}
						else if !missing(`_ES'[`k']) {				// June 2020
							scalar `_ES_'  = `denominator' * `_ES'[`k']
							disp as text substr(`_LABELS'[`k'], 1, 32) ///
								as text `"{col `=`swidth'+1'}{c |}{col `=`swidth'+`ewidth'-6'}"' ///
								as res %7.3f `xexp'(`_ES_') as text `"{col `=`swidth'+`ewidth'+10'} (Insufficient data)"'
						}
						else {
							disp as text substr(`_LABELS'[`k'], 1, 32) `"{col `=`swidth'+1'}{c |}{col `=`swidth'+4'} (Insufficient data)"'
						}
					}
					else {
						scalar `_ES_'  = `denominator' * `_ES'[`k']
						scalar `_LCI_' = `denominator' * `_LCI'[`k']
						scalar `_UCI_' = `denominator' * `_UCI'[`k']
						
						if "`wt'"=="" {
							scalar `_WT_'  = `_WT'[`k']
							local wttext `"as res %7.2f `_WT_'"'
						}
						
						local _labels_ = `_LABELS'[`k']
						local _cc_
						
						local lwidth = 32
						cap confirm numeric var `_CC'
						if !_rc & `ccval' {
							if `_CC'[`k'] local _cc_ `" *"'
							local lwidth = 30
						}
						disp as text substr(`"`_labels_'"', 1, `lwidth') as res `"`_cc_'"' ///
							as text `"{col `=`swidth'+1'}{c |}{col `=`swidth'+`ewidth'-6'}"' ///
							as res %7.3f `xexp'(`_ES_') `"{col `=`swidth'+`ewidth'+5'}"' ///
							as res %7.3f `xexp'(`_LCI_') `"{col `=`swidth'+`ewidth'+15'}"' ///
							as res %7.3f `xexp'(`_UCI_') `"{col `=`swidth'+`ewidth'+26'}"' ///
							`wttext'
					}
				}
			}

			* Subgroup effects
			if `"`by'"'!=`""' & `"`subgroup'"'==`""' & `"`cumulative'"'==`""' {
				if `ilevel'==`olevel' disp as text `"{col `=`swidth'+1'}{c |}"'
				else {
					disp as text `"{col `=`swidth'+1'}{c |}{col `=`swidth'+`ewidth'+3'}{hline 1}[`olevel'% Conf. Interval]{hline 1}"'
				}

				// Multiple models
				forvalues j = 1 / `m' {
								
					// User-defined second model, or nosecsub
					local model : word `j' of `modellist'
					if (`j' > 1 & "`secsub'"!="") | "`model'"=="user" {		// Note: "user" as model1 cannot be used with "by"
						continue, break
					}
					
					if `"`modellabels'"'==`""' & trim(`"`label`j'opt'"')!=`""' {
						local modText `", `label`j'opt'"'	// Nov 2020; added `modellabels' Apr 2021
					}
					local wgtstar
					if `"`wgtopt`j''"'!=`""' local wgtstar " **"
				
					local bystats : word `j' of `bystatslist'
					
					// Modified July 2024 to avoid errors with Stata 15 and older
					// "matrix operators that return matrices not allowed in this context
					local r = rownumb(`bystats', "`eff'")
					scalar `_ES_' = `denominator' * `bystats'[`r', `i']
					if missing(`_ES_') {
						disp as text `"Subgroup`modText'`wgtstar'{col `=`swidth'+1'}{c |}{col `=`swidth'+4'} (Insufficient data)"'
					}
					else {
						local r = rownumb(`bystats', "`eff_lci'")
						scalar `_LCI_' = `denominator' * `bystats'[`r', `i']
						local r = rownumb(`bystats', "`eff_uci'")
						scalar `_UCI_' = `denominator' * `bystats'[`r', `i']

						disp as text `"Subgroup`modText'`wgtstar'{col `=`swidth'+1'}{c |}{col `=`swidth'+`ewidth'-6'}"' ///
							as res %7.3f `xexp'(`_ES_') `"{col `=`swidth'+`ewidth'+5'}"' ///
							as res %7.3f `xexp'(`_LCI_') `"{col `=`swidth'+`ewidth'+15'}"' ///
							as res %7.3f `xexp'(`_UCI_') `"{col `=`swidth'+`ewidth'+26'}"' _c
							
						// subgroup sum of (normalised) weights: will be 1 unless `ovwt'
						// N.B. `mwt' should always exist if `"`by'"'!=`""' & `"`subgroup'"'==`""' & `"`sgwt'"'==`""'						
						if `j' > 1 | "`wt'"!="" di ""		// cancel the _c
						else {
							scalar `_WT_' = 100
							if `"`ovwt'"'!=`""' {
								scalar `_WT_' = `mwt'[`j', `i']
							}
							disp as res %7.2f `_WT_'
						}
					}
				}		// end forvalues j = 1 / `m'
			}		// end if `by'
		}		// end forvalues i = 1 / `nby'
		

		* Overall effect
		if `"`overall'"'==`""' & `"`cumulative'"'==`""' {
			if !(`"`summaryonly'"'!=`""' & `nby'==1) {
				if `ilevel'==`olevel' disp as text `"{hline `swidth'}{c +}{hline `=`ewidth'+24+`wwidth''}"'
				else {
					disp as text `"{hline `swidth'}{c +}{hline `=`ewidth'+2'}[`olevel'% Conf. Interval]{hline `=`ewidth'+`wwidth'-9'}"'
				}
			}

			// Multiple models
			local index = 0
			forvalues j = 1 / `m' {
			
				local model : word `j' of `modellist'
				if `"`modellabels'"'==`""' & trim(`"`label`j'opt'"')!=`""' {
					local modText `", `label`j'opt'"'		// Apr 2021
					if "`model'"=="dlc" & `"`label`j'opt'"'==`"DL (Common)"' local modText `", DL"'	// May 2023
				}
				if "`model'"=="user" {
					tokenize `user`j'stats'
					args _ESuser_ _LCIuser_ _UCIuser_

					disp as text %-20s `"Overall`modText'{col `=`swidth'+1'}{c |}{col `=`swidth'+`ewidth'-6'}"' ///
						as res %7.3f `xexp'(`_ESuser_') `"{col `=`swidth'+`ewidth'+5'}"' ///
						as res %7.3f `xexp'(`_LCIuser_') `"{col `=`swidth'+`ewidth'+15'}"' ///
						as res %7.3f `xexp'(`_UCIuser_') _c
					
					if `j'==1 & "`wt'"=="" disp as res `"{col `=`swidth'+`ewidth'+26'}"' %7.2f 100
					else di ""		// cancel the _c				
				}
				
				else {
				    local ++index
					local wgtstar
					if `"`wgtopt`j''"'!=`""' local wgtstar " **"					

					// Modified July 2024 to avoid errors with Stata 15 and older
					// "matrix operators that return matrices not allowed in this context
					local r = rownumb(`ovstats', "`eff'")
					scalar `_ES_' = `denominator' * `ovstats'[`r', `index']
					if missing(`_ES_') {
						disp as text `"Overall`modText'`wgtstar'{col `=`swidth'+1'}{c |}{col `=`swidth'+4'} (Insufficient data)"'
					}
					else {
						local r = rownumb(`ovstats', "`eff_lci'")
						scalar `_LCI_' = `denominator' * `ovstats'[`r', `index']
						local r = rownumb(`ovstats', "`eff_uci'")
						scalar `_UCI_' = `denominator' * `ovstats'[`r', `index']

						// N.B. sum of (normalised) weights: will be 1 unless `sgwt'
						disp as text %-20s `"Overall`modText'`wgtstar'{col `=`swidth'+1'}{c |}{col `=`swidth'+`ewidth'-6'}"' ///
							as res %7.3f `xexp'(`_ES_') `"{col `=`swidth'+`ewidth'+5'}"' ///
							as res %7.3f `xexp'(`_LCI_') `"{col `=`swidth'+`ewidth'+15'}"' ///
							as res %7.3f `xexp'(`_UCI_') _c
							
						if `j'==1 & `"`sgwt'`wt'"'==`""' disp as res `"{col `=`swidth'+`ewidth'+26'}"' %7.2f 100
						else di ""		// cancel the _c
					}
				}
			}
		}
		disp as text `"{hline `swidth'}{c BT}{hline `=`ewidth'+24+`wwidth''}"'
	
	}	// end if `"`table'"'==`""'

	
	** Test statistics and p-values
	local xtext = cond(`"`cumulative'"'!=`""', `"cumulative "', `""')		// n/a for influence
	local null = (`"`eform'"'!=`""')										// test of pooled effect equal to zero
	
	if `swidth'<=1 local swidth = 21			// define `swidth' in case -noTABle- *and* no `by'	
	local hetWidth = 35
	
	* Count number of "user-supplied" models [Nov 2020]
	forvalues j = 1 / `m' {
		local model : word `j' of `modellist'
		if "`model'"!="user" {
			local indexlist `indexlist' `j'
		}
	}
	local m2 : word count `indexlist'	
	
	tempname testStat df pvalue
	
	* Display by subgroup
	if `"`by'"'!=`""' & `"`subgroup'"'==`""' {
		disp as text _n `"Tests of subgroup `xtext'effect size = "' as res `null' as text ":"
		
		forvalues i = 1 / `nby' {
			local byi: word `i' of `bylist'
			if `"`bylab'"'!=`""' {
				local bylabi : label `bylab' `byi'
			}
			else local bylabi `byi'

			// Multiple models
			forvalues j = 1 / `m2' {
				local index : word `j' of `indexlist'
				local model : word `index' of `modellist'
				local teststat : word `index' of `teststatlist'
				local bystats  : word `index' of `bystatslist'
			
				// User-defined second model, or nosecsub
				if (`j' > 1 & "`secsub'"!="") {		// Note: no need to specify "`model'"!="user" as we are within a loop involving `m2'
					continue, break
				}			

				local wgtstar
				if `m' > 1 & `"`wgtopt`index''"'!=`""' local wgtstar " **"
		
				// Modified July 2024 to avoid errors with Stata 15 and older
				// "matrix operators that return matrices not allowed in this context
				local r = rownumb(`bystats', "`teststat'")
				scalar `testStat' = `bystats'[`r', `i']
				scalar `df' = .
				if "`teststat'"=="t" {
					local r = rownumb(`bystats', "df")
					scalar `df' = `bystats'[`r', `i']
					
					// if only one study, revert to z [IN PRACTICE, THIS SHOULD ALREADY HAVE BEEN DETECTED]
					if `df'==0 {
						local teststat z
						local r = rownumb(`bystats', "`teststat'")
						scalar `testStat' = `bystats'[`r', `i']
						scalar `df' = .
					}
				}
				local r = rownumb(`bystats', "pvalue")
				scalar `pvalue' = `bystats'[`r', `i']
			
				// Text to display: chisq distributions
				local testDist
				local testStatFormat
				if "`teststat'"=="chi2" {
					if "`model'"=="pl" local testDist "LR chi{c 178}"
					else if "`model'"=="mh" & "`cmhnocc'"=="" local testDist "CMH chi{c 178}"
					else local testDist "chi{c 178}"

					local testStatFormat "%6.2f"
					local dfFormat "%1.0f"
					scalar `df' = 1
				}

				// Text to display: t distribution
				else if "`teststat'"=="t" {
					local testStatFormat "%7.3f"
					local dfFormat "%3.0f"
					
					if `"`: word 1 of `: colnames `bystats'''"'=="reml_kr" local dfFormat "%6.2f"		// [NOV 2020] Kenward-Roger
				}

				// Other text formatting
				if "`testDist'"=="" local testDist `teststat'
				if "`testStatFormat'"=="" local testStatFormat "%7.3f"
				local testdistlen = length(`"`= subinstr("`testDist'", "{c 178}", "c", .)'"')
				local testfmtlen = fmtwidth("`testStatFormat'")

				// If only a single model, (potentially truncated) subgroup labels are followed immediately by test statistics.
				// If multiple models, subgroup labels (`bylabi') are printed as headings,
				//   then on subsequent lines, a list of model labels (label`index'opt) followed by test statistics.
				local labtext : copy local label`index'opt
				if `m'==1 {
					local labtext				// clear macro
					local continue _c
					local pos = `swidth' + 1
				}
				else local pos = 20 - `testdistlen' + 1
			
				if `j'==1 {
					disp as text substr("`bylabi'", 1, `swidth'-1) `continue'
				}

				if `"`labtext'`wgtstar'"'!=`""' disp as text `"  `labtext'`wgtstar' "' _c
				if missing(`testStat') disp as text `"{col `pos'}(Insufficient data)"'
				else {
					disp as res `"{col `pos'}`testDist'"' as text " = " as res `testStatFormat' `testStat' _c
					local pos = `pos' + `testdistlen' + 3 + `testfmtlen' + 2
					if !missing(`df') {
						local dffmtlen = fmtwidth("`dfFormat'")
						disp as text "{col `pos'}on " as res `dfFormat' `df' as text " df," _c
						local pos = `pos' + 3 + `dffmtlen' + 6
					}
					disp as text "{col `pos'}p = " as res %5.3f `pvalue'
				}
			}		// end forvalues j = 1 / `m'
		}		// end forvalues i = 1 / `nby'
	}		// 	end if `"`by'"'!=`""' & `"`subgroup'"'==`""' {
	
		
	* Display overall
	if `"`overall'"'==`""' {

		forvalues j = 1 / `m2' {
			local index : word `j' of `indexlist'
			local model : word `index' of `modellist'
			local teststat : word `index' of `teststatlist'
			
			// Extract test statistics from `ovstats'
			// Modified July 2024 to avoid errors with Stata 15 and older
			// "matrix operators that return matrices not allowed in this context
			local r = rownumb(`ovstats', "`teststat'")
			scalar `testStat' = `ovstats'[`r', `j']
			scalar `df' = .
			if "`teststat'"=="t" {
				local r = rownumb(`ovstats', "df")
				scalar `df' = `ovstats'[`r', `j']
			}
			local r = rownumb(`ovstats', "pvalue")
			scalar `pvalue' = `ovstats'[`r', `j']

			// Text to display: chisq distributions
			local testDist
			if "`teststat'"=="chi2" {
				if "`model'"=="pl" local testDist "LR chi{c 178}"
				else if "`model'"=="mh" & "`cmhnocc'"=="" local testDist "CMH chi{c 178}"
				else local testDist "chi{c 178}"

				local testStatFormat "%6.2f"
				local dfFormat "%1.0f"
				scalar `df' = 1
			}
			
			// Text to display: t distribution
			else if "`teststat'"=="t" {
				local testStatFormat "%7.3f"
				local dfFormat "%3.0f"
				
				if `"`: word `j' of `: colnames `ovstats'''"'=="reml_kr" local dfFormat "%6.2f"		// [NOV 2020] Kenward-Roger
			}

			// Text to display: Signed log-likelihood statistic
			else if "`teststat'"=="z" & "`model'"=="pl" {
				local testDist "LL z"
				local testStatFormat "%7.3f"
			}
			
			// Other text formatting
			if "`testDist'"=="" local testDist `teststat'
			if "`testStatFormat'"=="" local testStatFormat "%7.3f"
			local testdistlen = length(`"`= subinstr("`testDist'", "{c 178}", "c", .)'"')
			local testfmtlen = fmtwidth("`testStatFormat'")
	
			local wgtstar
			if `"`wgtopt`index''"'!=`""' local wgtstar " **"
				
			if `m2'==1 {		// if only one model (default)
				if missing(`testStat') {
					disp as text `"Overall{col `=`swidth'+1'}(Insufficient data)"'
				}
				else {
					if `"`by'"'!=`""' & `"`subgroup'"'==`""' {
						disp as text `"Overall`wgtstar'{col `=`swidth'+1'}"' _c
						local pos = `swidth' + 1
						disp as res `"{col `pos'}`testDist'"' as text " = " as res `testStatFormat' `testStat' _c
						
						local pos = `pos' + `testdistlen' + 3 + `testfmtlen' + 2
						if !missing(`df') {
							local dffmtlen = fmtwidth("`dfFormat'")
							disp as text "{col `pos'}on " as res `dfFormat' `df' as text " df," _c
							local pos = `pos' + 3 + `dffmtlen' + 6
						}
						disp as text "{col `pos'}p = " as res %5.3f `pvalue'
					}	
					else {
						disp as text _n `"Test of overall `xtext'effect = "' as res `null' as text ":  " _c
						disp as res "`testDist'" as text " = " as res `testStatFormat' `testStat' _c
						if !missing(`df') {
							disp as text " on " as res `dfFormat' `df' as text " df," _c
						}
						disp as text "  p = " as res %5.3f `pvalue'
					}
				}
			}
		
			else {
				if `j'==1 {		// if multiple models; only display text once
					disp as text _n `"Tests of overall `xtext'effect = "' as res `null' as text ":"
				}
				
				local pos = 20 - `testdistlen' + 1
				disp as text "  `label`index'opt'`wgtstar'" as res "{col `pos'}`testDist'" as text " = " as res `testStatFormat' `testStat' _c
				local pos = `pos' + `testdistlen' + 3 + `testfmtlen' + 2
				if !missing(`df') {
					local dffmtlen = fmtwidth("`dfFormat'")
					disp as text "{col `pos'}on " as res `dfFormat' `df' as text " df," _c
					local pos = `pos' + 3 + `dffmtlen' + 6
				}
				disp as text "{col `pos'}p = " as res %5.3f `pvalue'
			}
		}		// end forvalues i = 1 / `m2'
	}

	* User-defined weights
	local udw = 0
	local dnl _n
	forvalues j = 1 / `m2' {
		local index : word `j' of `indexlist'
		if `"`wgtopt`index''"'!=`""' {
			local udw = 1
			
			if `"`table'`overall'"'==`""' {
				local wgttitle : variable label `wgtopt`index''
				if `"`wgttitle'"'==`""' local wgttitle `wgtopt`index''

				if `m'==1 {
					disp as text _n "** Note: pooled using user-defined weights " as res "`wgttitle'"
				}
				else {
					disp as text `dnl' "** Note: `label`index'opt' pooled using user-defined weights " as res "`wgttitle'"
					local dnl
				}
			}
		}
	}

	// Added Jan 2020 in response to advice from Dan Jackson
	if `nzt' {
		disp _n `"{error}Note: Untruncated HKSJ method is anti-conservative relative to common-effect equivalent"'
		if `nby' > 1 disp `"{error} in one or more subgroups. Consider using the {bf:truncate()} option."'
		else disp `"{error}Consider using the {bf:truncate()} option."'
	}
	
	
	** Heterogeneity statistics
	
	// In all cases, first table of heterogeneity statistics:
	// (If multiple models, use "primary" Q from first model)
	//  - Q (+ df & p-value)
	//  - H, Isq & HsqM, with CIs;
	//   ... by default using ncchi2 if fixed-effect, or Gamma-based if random-effects (ref: Hedges & Pigott, 2001)
	//   ... but could also have -testbased- (test-based CI for lnQ or lnH; Higgins & Thompson 2002) 

	// If random-effects, present table entitled "Heterogeneity variance estimates"
	//  - CIs for tausq (MP, ML, REML, BT) are presented where appropriate.
	
	// If option -isqparam- is specified:
	// (N.B. this option reflects the fact that Isq is to be defined as tau2/(tau2+sigma2) rather than (Q-df)/Q )
	// - additional table of Isq's, based on the tausq's and CIs from the previous table.
	// - direct user to r(ovstats) and/or r(bystats) for other heterogeneity statistics
	
	// (N.B. if "sa", then present a hybrid of random-effects and -isqparam- results, but without Conf. Intervals of course)

	// Finally: if more than one *subgroup*, present table of Q by subgroup, plus between and within,
	// - using the *first* of multiple models if relevant
	// - and with no table of Isq or tausq
	// - direct user to r(ovstats) and/or r(bystats) for other heterogeneity statistics
		
	summ `_ES' if `touse' & `_USE'==1, meanonly
	local het = cond(`r(N)'==1, "nohet", "`het'")		// don't present overall het stats if only one estimate

	if `"`subgroup'`het'"'!=`""' local between nobetween	// added June 2022
	if "`het'"=="" & "`model1'"!="user" {
		
		* Setup: How many unique (tsq + CI) random-effects models are specified?
		local UniqModels : list uniq modellist		
		local UniqREModels = subinword("`UniqModels'", "ivhet", "dl", .)	// tsq + CI for IVhet are the same as for D+L
		local UniqREModels = subinword("`UniqREModels'", "qe", "dl", .)		// tsq + CI for QE are the same as for D+L
		local UniqREModels = subinword("`UniqREModels'", "hc", "dl", .)		// tsq + CI for HC are the same as for D+L
		local UniqREModels = subinword("`UniqREModels'", "pl", "ml", .)		// tsq + CI for PL are the same as for ML
		local UniqREModels : list uniq UniqREModels
		local toremove user iv mh peto mu
		local UniqREModels : list UniqREModels - toremove
		local TotUniqREModels : word count `UniqREModels'
		
		tempname /*Q Qdf*/ Qpval Isq Isqmax
		scalar `Isqmax' = 0
		
		// Sep 2020: Unpack `qlist'
		// DF JUNE 2022: REVISIT -- ADD SOME ASSERT CHECKS HERE??
		// updated May 2023
		tokenize `qlist'
		if `"`overall'"'!=`""' {
			assert inlist(`: word count `qlist'', /*0,*/ 3)
			args Qsum Qbet nbyQ		// if nooverall, only have between-subgroup Q
		}
		else {
			assert inlist(`: word count `qlist'', /*0,*/ 2, 4, 7)
			tokenize `qlist'
			args Q Qdf Q_lci Q_uci Qsum Qbet nbyQ
		}

		
		**********************
		* Multiple subgroups *
		**********************
		
		// In this case, just present table of Q statistics (between, within, total etc.)
		// plus I-squared statistics for each subgroup
		
		if `nby' > 1 & `"`by'"'!=`""' & `"`subgroup'"'==`""' {
			local bystats : word 1 of `bystatslist'
			
			if      "`qstat'"=="petoq"   disp as text _n(2) "Peto Q statistics for heterogeneity"
			else if "`qstat'"=="mhq"     disp as text _n(2) "Mantel-Haenszel Q statistics for heterogeneity"
			else if "`qstat'"=="breslow" disp as text _n(2) "Breslow-Day homogeneity statistics"
			else if "`qstat'"=="tarone"  disp as text _n(2) "Breslow-Day-Tarone homogeneity statistics"
			else disp as text _n(2) "Cochran's Q statistics for heterogeneity"
			disp as text `"(other heterogeneity measures are stored in "' _c
			if `"`overall'"'==`""' {
				disp as text `"matrices "' as res `"{bf:{stata mat list r(ovstats):r(ovstats)}}"' as text `" and "' _c
			}
			else disp as text `"matrix "' _c
			disp as res `"{bf:{stata mat list r(bystats):r(bystats)}}"' as text `")"'

			local hetWidth = 44		// Added Oct 2020			
			disp as text `"{hline `swidth'}{c TT}{hline `hetWidth'}"'
			disp as text `"Measure{col `=`swidth'+1'}{c |}{col `=`swidth'+7'}Value{col `=`swidth'+18'}df{col `=`swidth'+26'}p-value{col `=`swidth'+40'}I{c 178}"'
			disp as text `"{hline `swidth'}{c +}{hline `hetWidth'}"'
		
			forvalues i = 1 / `nby' {
				local byi : word `i' of `bylist'
				if `"`bylab'"'!=`""' {
					local bylabi : label `bylab' `byi'
				}
				else local bylabi `"`byi'"'
				if `"`bylabi'"'!="." local bylabi = substr(`"`bylabi'"', 1, `swidth'-1)
												
				disp as text `"`bylabi'{col `=`swidth'+1'}{c |}"' _c

				tempname Qi Qdfi
				scalar `Qi'   = `byq'[1, `i']
				scalar `Qdfi' = `byq'[2, `i']

				// Update `Isqmax'
				scalar `Isq' = max(0, 100*(`Qi' - `Qdfi') / `Qi')
				if `Qi'==0 | `Qdfi'==0 scalar `Isq' = .
				scalar `Isqmax' = max(`Isqmax', `Isq')
				
				if missing(`Qi') disp as text `"{col `=`swidth'+5'}(Insufficient data)"'
				else {
					scalar `Qpval' = chi2tail(`Qdfi', `Qi')
					disp as text `"{col `=`swidth'+5'}"' as res %7.2f `Qi' `"{col `=`swidth'+18'}"' %3.0f `Qdfi' `"{col `=`swidth'+25'}"' %7.3f `Qpval' `"{col `=`swidth'+38'}"' %4.1f `Isq' _c
					if !missing(`Isq') disp as res "%"
					else disp ""
				}
			}

			if `"`overall'"'==`""' {
				disp as text `"Overall{col `=`swidth'+1'}{c |}"' _c
				if missing(`Q') disp as text `"{col `=`swidth'+5'}(Insufficient data)"'
				else {
					scalar `Qpval' = chi2tail(`Qdf', `Q')
					scalar `Isq' = max(0, 100*(`Q' - `Qdf') / `Q')
					if `Q'==0 | `Qdf'==0 scalar `Isq' = .
					
					disp as text `"{col `=`swidth'+5'}"' as res %7.2f `Q' `"{col `=`swidth'+18'}"' %3.0f `Qdf' `"{col `=`swidth'+25'}"' %7.3f `Qpval' `"{col `=`swidth'+38'}"' %4.1f `Isq' _c
					if !missing(`Isq') disp as res "%"
					else disp ""
				}
			}
			
			// Mar 2020: want `nby' to reflect the number of subgroups *with data in*
			//  so restrict to `_USE'==1
			tempname Qbetpval
			scalar `Qbetpval' = chi2tail(`nbyQ' - 1, `Qbet')

			if `"`between'"'!=`""' {
				disp as text `"{hline `swidth'}{c BT}{hline `hetWidth'}"'
			}
			else {			
				if "`model1'"!="iv" | `"`overall'"'!=`""' {
					disp as text `"Between{col `=`swidth'+1'}{c |}"' as text `"{col `=`swidth'+5'}"' ///
						as res %7.2f `Qbet' `"{col `=`swidth'+18'}"' %3.0f `nbyQ' - 1 `"{col `=`swidth'+25'}"' %7.3f `Qbetpval'
					disp as text `"{hline `swidth'}{c BT}{hline `hetWidth'}"'

					if "`model1'"!="iv" {
						if "`model1'"=="peto" local hetlabel Peto
						else if "`model1'"=="ivhet" local hetlabel IVhet
						else if "`model1'"=="dlb" local hetlabel DLb
						else if "`model1'"=="dlc" local hetlabel "DL (Common)"	/* Added May 2023 */
						else if "`model1'"=="ev" local hetlabel "Emp. Var."
						else if inlist("`model1'", "bp", "b0") local hetlabel = "Rukhin " + upper("`model1'")
						else local hetlabel = upper("`model1'")

						if "`hksj'"!="" local hetlabel "`hetlabel'+HKSJ"
						else if "`kroger'"!="" local hetlabel "`hetlabel'+KR"
						else if "`robust'"!="" local hetlabel "`hetlabel'+Rob."
						else if "`bartlett'"!="" local hetlabel "`hetlabel'+Bart."
						else if "`skovgaard'"!="" local hetlabel "`hetlabel'+Skov."
						
						disp as text `"Note: between-subgroup heterogeneity calculated using `hetlabel' subgroup weights"'
					}
					// Jan 2020: between-subgroups Q can be calculated using either fixed and random-effects
					// c.f. Borenstein et al (2009) "Introduction to Meta-analysis", chapter 19
				}
				
				// I-V model, overall pooled result available
				else {
					tempname Fstat Fpval
					scalar `Fstat' = (`Qbet'/(`nbyQ' - 1)) / (`Qsum'/(`Qdf' - `nbyQ' + 1))		// corrected 17th March 2017
					scalar `Fpval' = Ftail(`nbyQ' - 1, `Qdf' - `nbyQ' + 1, `Fstat')
				
					disp as text `"Between{col `=`swidth'+1'}{c |}"' as text `"{col `=`swidth'+5'}"' ///
						as res %7.2f `Qbet' `"{col `=`swidth'+18'}"' %3.0f `nbyQ' - 1 `"{col `=`swidth'+25'}"' %7.3f `Qbetpval'
					disp as text `"Between:Within (F){col `=`swidth'+1'}{c |}"' as text `"{col `=`swidth'+5'}"' ///
						as res %7.2f `Fstat' `"{col `=`swidth'+14'}"' %3.0f `nbyQ' - 1 as text "," ///
						as res %3.0f `Qdf' - `nbyQ' + 1 `"{col `=`swidth'+25'}"' %7.3f `Fpval'
				
					disp as text `"{hline `swidth'}{c BT}{hline `hetWidth'}"'
					
					// DISPLAY BETWEEN-GROUP TEST WARNINGS [taken from -metan- v3.04]
					if `Isqmax' > 0 {
						if `Isqmax' < 50 {
							disp as text "Note: Some heterogeneity observed (I{c 178} up to " ///
								as res %4.1f `=`Isqmax'' "%" as text ") in one or more subgroups;"
							disp as text "  tests for heterogeneity between subgroups may not be valid"
						}
						else if `Isqmax' < 75 {
							disp as text "Note: Moderate heterogeneity observed (I{c 178} up to " ///
								as res %4.1f `=`Isqmax'' "%" as text ") in one or more subgroups;"
							disp as text "  tests for heterogeneity between subgroups are likely to be invalid"
						}
						else if !missing(`Isqmax') {
							disp as text "Note: Considerable heterogeneity observed (I{c 178} up to " ///
								as res %4.1f `=`Isqmax'' "%" as text ") in one or more subgroups;"
							disp as text "  tests for heterogeneity between subgroups are likely to be invalid"
						}
					}
				}			// end if "`model1'"=="iv"
			}		// end if `"`between'"'==`""'
		}		// end if `nby' > 1 & `"`by'"'!=`""' & `"`subgroup'"'==`""'
		
		
		****************
		* General case *
		****************

		else {
			if `"`cumulative'`influence'"'!=`""' local totality "totality of "
			disp as text _n(2) `"Heterogeneity measures, calculated from the `totality'data"'
			if `m'==1 & "`model1'"=="sa" {
				if `udw' local hetextra `"(based on standard inverse-variance weights)"'
			}
			else {
				disp as text `"with Conf. Intervals based on "' _c
				if "`testbased'"!="" {
					disp as res "Test-based confidence interval for H"
				}
				else if inlist("`model1'", "peto", "mh", "iv", "mu") {
					disp as res `"non-central chi{c 178} (common-effect)"' as text `" distribution for Q"'
				}
				else disp as res `"Gamma (random-effects)"' as text `" distribution for Q"'
			}
						
			disp as text `"{hline `swidth'}{c TT}{hline `hetWidth'}"'
			disp as text `"Measure{col `=`swidth'+1'}{c |}{col `=`swidth'+7'}Value{col `=`swidth'+18'}df{col `=`swidth'+26'}p-value"'
			disp as text `"{hline `swidth'}{c +}{hline `hetWidth'}"'
			
			
			** Display first ("primary") Q, together with H and Isq
			// Plus CIs:  if fixed-effect model, using noncentral chi-squared; if random-effects, using Gamma-based
			// Then, if appropriate, present remainder of multiple Qs
			if      "`qstat'"=="petoq"   local hetText1 "Peto Q"
			else if "`qstat'"=="mhq"     local hetText1 "Mantel-Haenszel Q"
			else if "`qstat'"=="breslow" local hetText1 "Breslow-Day test"
			else if "`qstat'"=="tarone"  local hetText1 "Breslow-Day-Tarone"
			else local hetText1 "Cochran's Q"
			
			disp as text `"`hetText1'{col `=`swidth'+1'}{c |}"' _c
			if missing(`Q') disp as text `"{col `=`swidth'+5'}(Insufficient data)"'
			else {
				scalar `Qpval' = chi2tail(`Qdf', `Q')
				disp as text `"{col `=`swidth'+5'}"' as res %7.2f `Q' `"{col `=`swidth'+18'}"' %3.0f `Qdf' `"{col `=`swidth'+25'}"' %7.3f `Qpval'
			}

			// Special case: Single sensitivity analysis
			if `m'==1 & "`model1'"=="sa" {
				disp as text `"{hline `swidth'}{c BT}{hline `hetWidth'}"'		// end previous box
				
				disp as text _n `"Heterogeneity measures (based on user-defined "' _c
				if `tsqsa'==-99 disp "I{c 178} = " as res "`isqsa'%" as text ")"
				else disp `"tau{c 178} = "' as res `"`=strofreal(`tsqsa', "%05.3f")'"' as text `")"'
				disp as text `"{hline `swidth'}{c TT}{hline 13}"'
				disp as text `"{col `=`swidth'+1'}{c |}{col `=`swidth'+7'}Value"'
				disp as text `"{hline `swidth'}{c +}{hline 13}"'

				// Modified July 2024 to avoid errors with Stata 15 and older
				// "matrix operators that return matrices not allowed in this context
				foreach x in tausq H Isq HsqM {
					tempname `x'
					local r = rownumb(`hetstats', "`x'") 
					scalar ``x'' = `hetstats'[`r', 1]
				}
				
				disp as text `"tau{c 178} {col `=`swidth'+1'}{c |}{col `=`swidth'+4'}"' as res %8.4f `tausq'
				disp as text `"H {col `=`swidth'+1'}{c |}{col `=`swidth'+5'}"' as res %7.3f `H'
				disp as text `"I{c 178} (%) {col `=`swidth'+1'}{c |}{col `=`swidth'+4'}"' as res %7.1f `Isq' "%"
				disp as text `"Modified H{c 178} {col `=`swidth'+1'}{c |}{col `=`swidth'+5'}"' as res %7.3f `HsqM'
				disp as text `"{hline `swidth'}{c BT}{hline 13}"'
			}
			
			// General case (NOT if sensitivity analysis):
			// H and I-squared, based on Q
			else {
				disp as text `"{col `=`swidth'+1'}{c |}{col `=`swidth'+14'}{hline 1}[`hlevel'% Conf. Interval]{hline 1}"'
					
				tempname Isq Isq_lci Isq_uci
				scalar `Isq'     = max(0, 100*(`Q' - `Qdf') / `Q')
				scalar `Isq_lci' = max(0, 100*(`Q_lci' - `Qdf') / `Q_lci')
				scalar `Isq_uci' = max(0, 100*(`Q_uci' - `Qdf') / `Q_uci')				
				
				tempname H H_lci H_uci
				scalar `H'     =        sqrt(`Q' / `Qdf')
				scalar `H_lci' = max(1, sqrt(`Q_lci' / `Qdf'))
				scalar `H_uci' =        sqrt(`Q_uci' / `Qdf')

				disp as text `"H {col `=`swidth'+1'}{c |}{col `=`swidth'+5'}"' ///
					as res %7.3f `H' `"{col `=`swidth'+15'}"' ///
					as res %7.3f `H_lci' `"{col `=`swidth'+25'}"' %7.3f `H_uci'
			
				disp as text `"I{c 178} (%) {col `=`swidth'+1'}{c |}{col `=`swidth'+4'}"' ///
					as res %7.1f `Isq' `"%{col `=`swidth'+14'}"' ///
					as res %7.1f `Isq_lci' `"%{col `=`swidth'+24'}"' %7.1f `Isq_uci' "%"

				disp as text `"{hline `swidth'}{c BT}{hline `hetWidth'}"'
			
				if "`qstat'"=="breslow" local hetText1 "Breslow-Day statistic"
				else if "`qstat'"=="tarone" local hetText1 "Breslow-Day-Tarone statistic"				
				disp as text `"H = relative excess in `hetText1' over its degrees-of-freedom"'
				disp as text `"I{c 178} = proportion of total variation in effect estimate due to between-study heterogeneity (based on Q)"'
			
			
				** Model parameters: heterogeneity variance tausq
				// Present this/these separately from Q, H, I-squared
				// The above stats are calculated directly from the data, independently of the model
				//   whereas tausq is model-based.  (c.f. dicussion with JPTH 1st Sep 2020)
				// CIs for tausq (MP, ML, REML, BT) are presented where appropriate.
				
				local tsq_ci_warn = 0
				if `TotUniqREModels' {
				
					if `"`cumulative'`influence'"'!=`""' local totality ", calculated from the totality of data"
					disp as text _n(2) "Heterogeneity variance estimates`totality'"
					local RefModList mp pmm ml pl reml bt dlb
					if `"`: list UniqModels & RefModList'"'==`""' local newHetWidth = 13
					else {
						local newHetWidth = `hetWidth'
						disp as text `"with Conf. Intervals as appropriate to the method (see {help metan:help metan})"'
					}				
					disp as text `"{hline `swidth'}{c TT}{hline `newHetWidth'}"'
					disp as text `"Method{col `=`swidth'+1'}{c |}{col `=`swidth'+7'}tau{c 178}"' _c
					if `"`: list UniqModels & RefModList'"'==`""' disp ""	// cancel _c
					else {
						disp as text `"{col `=`swidth'+15'}[`hlevel'% Conf. Interval]"'
					}
					disp as text `"{hline `swidth'}{c +}{hline `newHetWidth'}"'

					foreach mod of local UniqREModels {						
						local c : list posof "`mod'" in modellist

						// sort out "duplicate" tsq + CIs associated with more than one model
						if "`mod'"=="ml" {
							if !`c' local c : list posof "pl" in modellist
							local hetlab`c'opt "ML/PL"
						}
						else if "`mod'"=="dl" {
							if !`c' local c : list posof "ivhet" in modellist
							if !`c' local c : list posof "qe" in modellist
							if !`c' local c : list posof "hc" in modellist
							local hetlab`c'opt DL
						} 						
						else if "`mod'"=="reml" local hetlab`c'opt REML		// in case of Kenward-Roger
						else if "`mod'"=="dlb" local hetlab`c'opt DLb
						else if "`mod'"=="ev" local hetlab`c'opt "Emp. Var."
						else if inlist("`mod'", "bp", "b0") local hetlab`c'opt = "Rukhin " + upper("`mod'")
						else local hetlab`c'opt = upper("`mod'")
						
						local c_list `c_list' `c'

						// Modified July 2024 to avoid errors with Stata 15 and older
						// "matrix operators that return matrices not allowed in this context
						tempname tausq
						local r = rownumb(`ovstats', "tausq")
						scalar `tausq' = `ovstats'[`r', `c']

						disp as text `"`hetlab`c'opt'{col `=`swidth'+1'}{c |}{col `=`swidth'+4'}"' ///
							as res %8.4f `tausq' _c
						if `"`: list mod & RefModList'"'==`""' disp ""		// cancel _c
						else {
							tempname tsq_lci tsq_uci
							local r = rownumb(`ovstats', "tsq_lci")
							scalar `tsq_lci' = `ovstats'[`r', `c']
							local r = rownumb(`ovstats', "tsq_uci")
							scalar `tsq_uci' = `ovstats'[`r', `c']
							disp as text `"{col `=`swidth'+14'}"' ///
								as res %8.4f `tsq_lci' `"{col `=`swidth'+24'}"' %8.4f `tsq_uci'
								
							if !(`tsq_lci'<=`tausq' & `tausq'<=`tsq_uci') & !missing(`tsq_lci', `tsq_uci') local tsq_ci_warn = 1								
						}
						
					}	// end forvalues
					
					disp as text `"{hline `swidth'}{c BT}{hline `newHetWidth'}"'
						
					// June 2020: Display tsq_ci warning
					if `tsq_ci_warn' {
						if !inlist("`mod'", "mh", "peto", "mu") local tsq_warn_txt "tau{c 178}"
						else local tsq_warn_txt "I{c 178}"
						disp `"{error}Note: `tsq_warn_txt' point estimate does not lie within estimated confidence limits;"'
						disp `"{error}  some modelling assumptions may be incompatible with the data"'
					}
				
					
					** Optional:  Display set of I-squared values (+ CIs) defined as = tausq / (tausq + sigmasq)
					// (rather than defined as Q - df / Q)
					if "`isqparam'"!="" {
						disp as text _n(2) `"Estimates of I{c 178}, defined parametrically as tau{c 178} / (tau{c 178} + sigma{c 178})"'
						disp as text `"(where sigma{c 178} is the estimated "typical" within-study variance of Higgins & Thompson)"'
						if `"`: list UniqModels & RefModList'"'==`""' {
							disp as text `"with Conf. Intervals as appropriate to the method (see {help metan:help metan})"'
						}
					
						disp as text `"{hline `swidth'}{c TT}{hline `newHetWidth'}"'
						disp as text `"Method{col `=`swidth'+1'}{c |}{col `=`swidth'+7'}I{c 178} (%)"' _c
						if `"`: list UniqModels & RefModList'"'==`""' disp ""		// cancel _c
						else disp as text `"{col `=`swidth'+15'}[`hlevel'% Conf. Interval]"'			
						disp as text `"{hline `swidth'}{c +}{hline `newHetWidth'}"'

						local i = 0
						foreach c of numlist `c_list' {
							foreach x in Isq Isq_lci Isq_uci {
								tempname `x'
								local r = rownumb(`hetstats', "`x'")
								scalar ``x'' = `hetstats'[`r', `c']
							}

							// N.B. `hetlab`c'opt' has already been parsed; no need to do so again
							disp as text `"`hetlab`c'opt'{col `=`swidth'+1'}{c |}{col `=`swidth'+4'}"' ///
								as res %7.1f `Isq' `"%{col `=`swidth'+14'}"' _c

							local ++i
							local mod : word `i' of `UniqREModels'							
							if `"`: list mod & RefModList'"'==`""' disp ""		// cancel _c
							else {
								disp as res %7.1f `Isq_lci' `"%{col `=`swidth'+24'}"' %7.1f `Isq_uci' "%"
							}
						}	// end foreach c
						
						disp as text `"{hline `swidth'}{c BT}{hline `newHetWidth'}"'	
					}
				
				}	// end if `TotUniqREModels'
				
			}	// end else (i.e. general case, no sensitivity analysis)
		
		}	// end else (i.e. general case, no subgroups)
		
	}	// end if `"`het'"'==`""'

end
		



**************************

* PrintDesc
// Print descriptive text to screen, above table

// subroutine of DrawTableAD

program define PrintDesc, sclass

	// First, parse options needed *only* in this subroutine; don't return these to DrawTableAD
	syntax [if] [in], [, LOG ///
			ESTEXP(string) EXPLIST(passthru) /* passed through from -ipdmetan */ ///
			noPOOL noSORTED MHALLZERO EXTRA(numlist integer min=2 max=2) /* Internal options */ * ]

	// Now parse additional options needed here but also in DrawTableAD
	tokenize `extra'
	args nsg nzt
	sreturn local nzt `nzt'
	sreturn local options `"`macval(options)'"'

	marksample touse
	local 0 `", `options'"'
	
	syntax [if] [in], MODELLIST(namelist) OUTVLIST(varlist numeric min=5 max=7) ///
		[SUMMSTAT(name) SORTBY(varlist) BY(varname numeric) BYLIST(numlist miss) ///
		LOGRank CUmulative INFluence PRoportion SUMMARYONLY INTERaction SGWt ALTWt ISQParam ///
		noOVerall noSUbgroup noBETWeen noTABle noGRaph ///
		TOUSE2(passthru) * ]	// <--just need to know if this exists

	marksample touse	
	local m : word count `modellist'
	local nby = max(1, `: word count `bylist'')
	gettoken model1 rest : modellist
	gettoken model2 rest : rest
	tokenize `outvlist'
	args _ES _seES _LCI _UCI _WT _NN _CC
	
	// Extract model options (from first model if multiple)
	// Plus user-defined weights
	local opts_adm `"`macval(options)'"'	
	local toparse1 CC(string) ISQSA(real -99) TSQSA(real -99) PHISA(real -99) HETPooled INIT(name) BArtlett HKsj KRoger RObust SKovgaard TRUNCate(string)
	local udw = 0
	forvalues j = 1 / `m' {
		local 0 `", `opts_adm'"'
		syntax [, MODEL`j'opts(string) * ]
		local opts_adm `"`macval(options)'"'
		if `"`model`j'opts'"'==`""' continue
		
		local 0 `", `model`j'opts'"'
		syntax [, WGT(varname) `toparse1' * ]
		local toparse1	// cancel for `j' > 1
		if `"`wgt'"'!=`""' {
			if "`: word `j' of `modellist''"!="user" local ++udw
			if `j'==1 {
				local wgttitle : variable label `wgt'
				if `"`wgttitle'"'==`""' local wgttitle `wgt'
			}
		}
	}	

	// Build up description of effect estimate type (interaction, cumulative etc.)
	local pooltext = cond(`"`cumulative'"'!=`""', "Cumulative meta-analysis of", ///
		cond(`"`influence'"'!=`""', "Influence meta-analysis of", ///
		cond(`"`pool'"'==`""' | "`model1'"=="user", "Meta-analysis pooling of", "Presented values are")))
	// NOTE: if no pooling the message is "Presented values are..." (not "...effect estimates are...")
	// because the phrase "effect estimates" may be used in the text below
	
	// Again, if passed from -ipdmetan- with "generic" effect measure,
	//   print non-standard text including `estexp':
	if "`estexp'"!="" {
		if `"`interaction'"'!=`""' local pooltext "`pooltext' interaction effect estimate"
		else if `"`explist'"'!=`""' local pooltext "`pooltext' user-specified effect estimate"
		else local pooltext "`pooltext' main (treatment) effect estimate"
		di _n as text "`pooltext'" as res " `estexp'"
	}

	// Standard -metan- text:
	else if `"`summstat'"'==`""' {
		if `"`pool'"'==`""' | `"`model1'"'=="user" | `"`touse2'"'!=`""' di _n as text "`pooltext' aggregate data"
	}
	else {
		local logtext = cond(`"`log'"'!=`""', `"log "', `""')			// add a space if `log'
		
		if "`summstat'"=="rr" local efftext `"`logtext'Risk Ratios"'
		else if "`summstat'"=="irr" local efftext `"`logtext'Incidence Rate Ratios"'
		else if "`summstat'"=="rrr" local efftext `"`logtext'Relative Risk Ratios"'
		else if "`summstat'"=="or"  local efftext `"`logtext'Odds Ratios"'
		else if "`summstat'"=="rd"  local efftext `" Risk Differences"'
		else if "`summstat'"=="hr"  local efftext `"`logtext'Hazard Ratios"'
		else if "`summstat'"=="shr" local efftext `"`logtext'Sub-hazard Ratios"'
		else if "`summstat'"=="tr"  local efftext `"`logtext'Time Ratios"'
		else if "`summstat'"=="wmd" local efftext `" Weighted Mean Differences"'
		else if inlist("`summstat'", "cohend", "glassd", "hedgesg") {
			local efftext "Standardised Mean Differences"
			local ss_proper = strproper(reverse(substr(reverse("`summstat'"), 2, .)))
			// local efftextf `" as text " by the method of " as res "`ss_proper'""'
		}
		else if "`proportion'"!="" {
			if "`summstat'"=="pr" local efftext "(untransformed) Proportions"
			else if "`summstat'"=="logit" local efftext "Logit-transformed Proportions"
			else if "`summstat'"=="arcsine" local efftext "Arcsine-transformed Proportions"
			else if "`summstat'"=="ftukey" local efftext "Freeman-Tukey transformed Proportions"
		}
			
		// Study-level effect derivation method
		if "`logrank'"!="" local efftext "Peto (logrank) `efftext'"
		else if "`model1'"=="peto" & `m'==1 local efftext "Peto `efftext'"
		disp _n as text "`pooltext'" as res " `efftext'" `efftextf' `continue'
		if "`ss_proper'"!="" {
			disp as text "  by the method of " as res "`ss_proper'"
		}
	}
	
	if `"`pool'"'!=`""' {
		if `"`model1'"'=="user" {
			disp as text "with " as res "user-specified pooled estimates"
		}
	}
	else {
		if `m' > 1 disp as text "using " as res "multiple analysis methods"
	
		else {	
			// fpnote = "NOTE: Weights are from Mantel-Haenszel model"
			// or "NOTE: Weights are from random-effects model"
			// or "NOTE: Weights are user-defined"
			// NOTE for multiple models: fpnote refers to weights ==> first model only

			// [Jan 2020]
			// If `by', may need to explain that between-subgroup heterogeneity was derived from random-effects model
			if `"`subgroup'`het'"'!=`""' local between nobetween	// added June 2022
			if `nby' > 1 & `"`subgroup'"'==`""' & `"`between'"'==`""' {
				local insert `"and between-subgroup heterogeneity test "'
			}
			
			// Pooling method (Mantel-Haenszel; common-effect; IVhet; random-effects)
			if "`model1'"=="mh" {
				disp as text "using the " as res "Mantel-Haenszel" as text " method"
				local fpnote "NOTE: Weights `insert'are from Mantel-Haenszel model"				// for forestplot
			}
			else if !inlist("`model1'", "ivhet", "qe", "peto") {
				if "`model1'"=="iv" {
					local modeltext "common-effect inverse-variance"
					if `m' > 1 local fpnote "NOTE: Weights are from common-effect model"		// for forestplot, if multiple models
				}
				else {
					if "`model1'"=="mu" local modeltext "inverse-variance"
					else {
						local modeltext "random-effects inverse-variance"
						if "`model1'"!="sa" local fpnote "NOTE: Weights `insert'are from random-effects model"		// for forestplot
					}
				}
				local the = cond("`model1'"=="qe", "", "the ")
				disp as text `"using `the'"' as res `"`modeltext'"' as text " model"
			}
			
			// Doi's IVhet and Quality Effects models
			else if inlist("`model1'", "ivhet", "qe") {
				local modeltext = cond("`model1'"=="ivhet", "Doi's IVhet", "Doi's Quality Effects")
				disp as text "using " as res `"`modeltext'"' as text " model"
				local fpnote `"NOTE: Weights `insert'are from `modeltext' model"'				// for forestplot
			}
			else {
				cap assert "`model1'"=="peto"
				if _rc {
					disp as err "Error identifying model"
					nois disp as err _n `"Error in {bf:metan_output.PrintDesc}"'
					c_local err noerr		// tell -metan- not to also report an "error in metan_output.DrawTableAD"
					exit _rc
				}					
			}
			
			// Profile likelihood
			if "`model1'"=="pl" {
				local continue = cond(`"`bartlett'`skovgaard'"'!=`""', "_c", "")
				disp as text `"estimated using "' as res "Profile Likelihood" `continue'
				if "`bartlett'"!="" disp as text " with " as res `"Bartlett's correction"'
				else if "`skovgaard'"!="" disp as text " with " as res `"Skovgaard's correction"'
			}
			
			// Biggerstaff-Tweedie approximate Gamma alternative weighting
			else if "`model1'"=="bt" {
				disp as text `"with "' as res "Biggerstaff-Tweedie approximate Gamma" as text `" weighting"'
			}

			// HKSJ, Kenward-Roger, and SJ Robust variance estimators
			else if `"`hksj'`kroger'`robust'"'!=`""' {
				local the "the "
				if "`hksj'"!="" {
					if `"`truncate'"'==`""' local vcetext `" (untruncated)"'
					else if inlist(`"`truncate'"', `"one"', `"1"') local vcetext `" (truncated at 1)"'
					else if `"`truncate'"'==`"zovert"' local vcetext `" (truncated at {it:z}/{it:t})"'
					local vcetext `"Hartung-Knapp-Sidik-Jonkman`vcetext'"'
				}
				else if "`robust'"!="" local vcetext "Sidik-Jonkman robust"
				else {
					local vcetext "Kenward-Roger"
					local the
				}
				disp as text "with `the'" as res "`vcetext'" as text " variance estimator"
			}
				
			// Henmi-Copas
			else if "`model1'"=="hc" {
				disp as text "estimated using " as res `"Henmi and Copas's approximate exact distribution"'
			}
			
			// Multiplicative heterogeneity model
			else if "`model1'"=="mu" {
				if "`hetpooled'"!="" local pooledtext ", pooled across subgroups"
				disp as text "with " as res `"multiplicative heterogeneity`pooledtext'"'
			}
			
			// Two-step estimators
			else if "`model1'"=="sj2s" {
				disp as text "with the " as res `"Sidik-Jonkman two-step tau{c 178} estimator"'
			}
			else if "`model1'"=="dk2s" {
				disp as text "with the " as res `"DerSimonian-Kacker two-step tau{c 178} estimator"'
			}

			// Estimators of tausq
			if !inlist("`model1'", "mh", "peto", "iv", "mu") {
				if inlist("`model1'", "dl", "bt", "ivhet", "qe", "hc", "dlc") local tsqtext "DerSimonian-Laird"
				else if "`model1'"=="dlb" local tsqtext "Bootstrap DerSimonian-Laird"
				else if "`model1'"=="mp"  local tsqtext "Mandel-Paule"
				else if "`model1'"=="pmm" local tsqtext "Median-unbiased Mandel-Paule"
				else if "`model1'"=="he"  local tsqtext "Hedges's"
				else if "`model1'"=="ev"  local tsqtext "Empirical variance"
				else if "`model1'"=="hm"  local tsqtext "Hartung-Makambi"
				else if inlist("`model1'", "ml",   "pl") local tsqtext ML
				else if "`model1'"=="reml" | "`kroger'"!="" local tsqtext REML
				else if "`model1'"=="bp"  local tsqtext "Rukhin's BP"
				else if "`model1'"=="b0"  local tsqtext "Rukhin's B0"
			
				local linktext = cond(`"`hksj'`kroger'`robust'"'!=`""' | inlist("`model1'", "pl", "bt", "ivhet", "qe", "hc"), "based on", "with")
				
				// Added May 2023, modified Sep 2023
				if "`hetpooled'"!="" local pooledtext ", pooled across subgroups"
				
				// Sensitivity analysis
				if "`model1'"=="sa" {
					disp as text "Sensitivity analysis with user-defined " _c
					if `isqsa'!=-99 {
						disp "I{c 178} = " as res "`isqsa'%"
						local fpnote `"Sensitivity analysis with user-defined I{c 178}"'
					}
					else if `tsqsa'!=-99 {
						disp `"tau{c 178} = "' as res `"`=strofreal(`tsqsa', "%05.3f")'"'
						local fpnote `"Sensitivity analysis with user-defined tau{c 178}"'
					}
					else if `phisa'!=-99 {
						disp `"phi = "' as res `"`=strofreal(`phisa', "%05.3f")'"'
						local fpnote `"Sensitivity analysis with user-defined multiplicative heterogeneity"'
					}
				}
				
				// Two-step estimators
				else if inlist("`model1'", "sj2s", "dk2s") {
					if "`init'"=="he" local inittxt "Hedges's"
					else local inittxt = upper("`init'")
					disp as text `"with "' as res "`inittxt'" as text `" initial estimate of tau{c 178}"'
				}
				
				// Default
				else disp as text `"`linktext' "' as res `"`tsqtext'"' as text `" estimate of tau{c 178}`pooledtext'"'
			}
		}
	}		// end if `"`pool'"'==`""' 
	
	// User-defined weights
	if `"`wgttitle'"'!=`""' {		// if *first* model has user-defined weights
		if `"`pool'"'==`""' {
			disp as text "and with user-defined weights " as res `"`wgttitle'"'
		}
		else disp as text "Weights " as res `"`wgttitle'"' as text " are user-defined"
		
		if `"`fpnote'"'!=`""' local fpnote `"`fpnote' and with user-defined weights"'
		else local fpnote `"NOTE: Weights `insert'are based on user-defined quantities"'
	}
	else if `udw' {					// else if any other model(s) have user-defined weights
		if `"`pool'"'==`""' {
			disp as text "and with user-defined weights for one or more models; see below"
		}
		else disp as text "Weights are user-defined for one or more models; see below"

		if `"`fpnote'"'!=`""' local fpnote `"`fpnote' and with user-defined weights for some models"'
		else local fpnote `"NOTE: Weights for some models are user-defined"'
	}
	
	// Continuity correction
	cap confirm numeric var `_CC'
	if !_rc & `"`cc'"'!=`""' {
		summ `_CC' if `touse', meanonly
		if r(sum) {
			local 0 `cc'
			syntax anything(name=ccval id="value supplied to {bf:cc()}") [, ALLifzero OPPosite EMPirical MHUNCORR /*Internal option only*/ ]

			local mhpeto mh peto			
			if `ccval' & !("`model1'"=="mh" & "`mhuncorr'"!="" & `"`summaryonly'`table'"'!=`""') {
				if `"`opposite'"'!=`""' disp as text _n "Opposite-arm continuity correction" _c
				else if `"`empirical'"'!=`""' disp as text _n "Empirical continuity correction" _c
				else {
				    local ccvallen = length(strofreal(`ccval'))		// Modified Nov 2020
					local plus  = `ccvallen' + 1
					local minus = `ccvallen' - 1
				    disp as text _n "Continuity correction of " as res %0`plus'.`minus'f `ccval' _c
				}
				
				local mhcorrtext = cond("`mhallzero'"=="", "uncorrected", "corrected")
				local plural = cond(`nby' > 1, "effects are", "effect is")

				if `"`allifzero'"'!=`""' {
					disp as text " applied to all studies"
					local allifzerotext "studies with zero cells "
				}
				else disp as text " applied to studies with zero cells"
				
				if `"`summaryonly'`table'"'==`""' {
					if "`model1'"=="mh" {
						if "`mhuncorr'"!="" {
							local andfplot = cond("`graph'"=="", "and forest plot ", "")
							disp as text `" for inclusion in summary table `andfplot'(`allifzerotext'marked with "' as res "*" as text ")"
							
							disp as text "Mantel-Haenszel pooled `plural' estimated from " as res "`mhcorrtext'" as text " counts"
							if "`mhallzero'"!="" disp as text " due to all studies having zero events in the same arm"
						}
						else {
							disp as text " (`allifzerotext'marked with " as res "*" as text ")"
							disp as text "Mantel-Haenszel pooled `plural' estimated from " as res "corrected" as text " counts"
						}
					}
					else {
						disp as text " (marked with " as res "*" as text ")"
					}
				}
			}		// end if `cc' & !("`model1'"=="mh" & "`mhuncorr'"!="" & `"`summaryonly'`table'"'!=`""')
			
			if `ccval' & !("`model1'"=="mh" & "`mhuncorr'"!="") {
				if `"`fpnote'"'!=`""' local fpnote `"`fpnote'; continuity correction applied to studies with zero cells"'
				else local fpnote `"NOTE: Continuity correction applied to studies with zero cells"'
			}
			else if !`ccval' & `: list posof "mh" in modellist' & `"`: list modellist - mhpeto'"'!=`""' {
				local s = cond(`nby' > 1, "s", "")
				disp as text _n "Note: Continuity correction suppressed, but Mantel-Haenszel pooled effect`s'"
				disp as text "  still estimated using all studies with sufficient data"
			}
		}
	}
	
	// cumulative/influence notes
	// (N.B. all notes (`fpnote') are passed to -forestplot- regardless of `nowarning'; this is then implemented within forestplot.ado)
	if `"`fpnote'"'!=`""' & !inlist("`model1'", "iv", "mh") & `"`altwt'"'!=`""' {
		if `"`cumulative'"'!=`""' {
			local fpnote `""`fpnote';" "changes in heterogeneity may mean that cumulative weights are not monotone increasing""'
		}
		else if `"`influence'"'!=`""' {
			local fpnote `""`fpnote'," "expressed relative to the total weight in the overall model""'
		}
	}
	if `"`cumulative'"'!=`""' {
		if `"`sorted'"'!=`""' local sortby : sort
		if `"`sortby'"'!=`""' {
			disp as text _n "Studies added cumulatively in order of " as res `"`sortby'"'
		}
	}
	
	// SEP 2020:
	// "Parametrically-defined Isq" -based heterogeneity [i.e. based on tausq & sigmasq]
	/*
	if "`isqparam'"!="" & "`model1'"!="dl" {
		local fptext `"Heterogeneity measures based on {&tau}{sup:2} and {&sigma}{sup:2} rather than on Q"'
	    if `"`fpnote'"'!=`""' {
			local fpnote `"`"`fpnote'."' `"`fptext'"'"'		// add full stop and new line before continuing
		}
		else local fpnote `"NOTE: `fptext'"'				// else just use text as-is
		sreturn local fpnote `"`fpnote'"'
	}
	*/
	
	// Print message regarding single estimates within subgroups
	// local m : word count `modellist'
	if `nsg' & `"`by'"'!=`""' & !inlist("`model1'", "iv", "mh", "peto", "mu") {
		if `"`influence'"'!=`""' & `"`sgwt'"'!=`""' local comma ,
		disp as text _n "Note: one or more subgroups contain only a single valid estimate;"
		disp as text "  common-effect models have been fitted in those subgroups`comma'"
		if `"`influence'"'!=`""' & `"`sgwt'"'!=`""' {
			disp as text "  and {bf:influence} analysis cannot be done within them"
		}
	}
	
	sreturn local fpnote `"`fpnote'"'

end



****************************

* Subroutine to "spread" titles out over multiple lines if appropriate
// Updated July 2014
// Copied directly to updated version of admetan.ado September 2015 without modification
// August 2016: identical program now used here, in forestplot.ado, and in ipdover.ado 
// May 2017: updated to accept substrings delineated by quotes (c.f. multi-line axis titles)
// August 2017: updated for better handling of maxlines()
// March 2018: updated to receive text in quotes, hence both avoiding parsing problems with commas, and maintaining spacing
// May 2018 and Nov 2018: updated truncation procedure

// subroutine of DrawTableAD

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
	forvalues i = 1 / `line' {
	
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





************************************************

** BuildResultsSet

// Having performed the meta-analysis (see PerformMetaAnalysis subroutine)
// ... and displayed results on-screen (see DrawTableAD subroutine)
// ... optionally prepare "results set" for either saving, or for constructing the forest plot (using forestplot.ado).
// The saving and/or running of -forestplot- is done from within this subroutine, due to tempvars being created.
// Note that meta-analysis is now complete, with stats returned in r(); if error in BuildResultsSet, error message explains this.

// (called directly by metan_output.ado)

// [N.B. mostly end part of old (v2.2) MainRoutine subroutine]


program define BuildResultsSet, rclass
	
	
	*****************
	* Initial setup *  ... starting with "required options" (plus by() and source() )
	*****************
	syntax varlist(numeric min=3 max=7) [if] [in], STUDY(varname numeric) LABELS(varname) ///
		OUTVLIST(varlist numeric min=5 max=7) MODELLIST(namelist) QSTAT(name) SORTBY(varlist) ///
		TESTSTATLIST(namelist) [ noTABle /// <-- May 2022: options not needed in BuildResultsSet, but parse out here to prevent passing to -twoway-
		BY(varname numeric) BYLIST(numlist miss) SOURCE(varname numeric) ///
		CLEARNPTS * ]	/* <-- internal options from elsewhere [July 2022, May 2023] */
		
	marksample touse, novarlist	// -novarlist- option prevents -marksample- from setting `touse' to zero if any missing values in `varlist'
								// we want to control this behaviour ourselves, e.g. by using KEEPALL option
	qui keep if `touse'
	tempvar obs
	qui gen long `obs' = _n

	// unpack varlists
	gettoken _USE invlist : varlist
	local params : word count `invlist'
	tokenize `outvlist'
	args _ES _seES _LCI _UCI _WT _NN _CC
	
	// Multiple models
	local m : word count `modellist'
	gettoken model1 : modellist
	forvalues j = 1 / `m' {
		local 0 `", `options'"'
		syntax [, MODEL`j'opts(string) LABEL`j'opt(string asis) EXTRA`j'opt(string asis) USER`j'stats(numlist min=3 max=3) * ]
	}
	local opts_adm `"`macval(options)'"'
	local 0 `", `model1opts'"'
	syntax [, WGT(varname) CC(string) ISQSA(real 80) TSQSA(real -99) * ]

	// rename locals for consistency with rest of -metan-
	local _BY     `by' 
	local _STUDY  `study'
	local _LABELS `labels'
	local _SOURCE `source'
	if `"`clearnpts'"'!=`""' local _NN				// [July 2022] cancel _NN if cumul/infl but at least one missing value
	else if `"`_NN'"'!=`""' local NN_opt _NN		// [AUG 2021] for `tosave' further down

	
	********************************
	* Subgroup and Overall effects *
	********************************
	// Create new observations to hold subgroup & overall effects (_USE==3, 5)
	//   (these can simply be removed again to restore the original data.)

	// N.B. Such observations may already have been created if passed through from -ipdmetan-
	//   but in any case, cover all bases by checking for (if applicable) a _USE==3 corresponding to each `by'-value,
	//   plus a single overall _USE==5.

	local 0 `", `opts_adm'"'
	syntax [, noOVerall noSUbgroup noSECsub QLIST(numlist miss min=2 max=7) ///
		BYSTATSLIST(namelist) OVSTATS(name) HETSTATS(namelist) BYHETLIST(namelist) BYQ(name) ///
		MWT(name) SGWt OVWt ALLWTNAMES(namelist) CUmulative INFluence ///
		XOUTVLIST(varlist numeric) PRVLIST(varlist numeric min=3 max=3) RFDist USEFLAG * ]

	// June 2024: improve error message due to similarity between hetstats (matrix) and hetinfo (option)
	if `: word count `hetstats''>1 {
		nois disp as err "option hetstats():  too many names specified"
		nois disp as err "Check whether the option {bf:hetinfo()} was intended instead"
		exit 103
	}		
		
	// Sep 2020: Unpack `qlist'
	tokenize `qlist'
	if `"`overall'"'!=`""' args Qsum Qbet nbyQ		// if nooverall, only have between-subgroup Q
	else args Q Qdf Q_lci Q_uci Qsum Qbet nbyQ

	// Setup "translation" from ovstats/bystats matrix rownames to stored varnames
	if `"`xoutvlist'"'!=`""' {
		local rownames
		cap local rownames : rownames `ovstats'
		if _rc cap local rownames : rownames `: word 1 of `bystatslist''

		if `"`rownames'"'!=`""' {
			// [DEC 2020:] re-form `xrownames' from `rownames'
			local core eff se_eff eff_lci eff_uci npts
			local xrownames : list rownames - core
			local xrownames `xrownames' Q Qdf Q_lci Q_uci
			if `: list posof "tausq" in rownames' local xrownames `xrownames' sigmasq
			if `"`cumulative'`influence'"'!=`""' local xrownames `xrownames' WT_Final
			
			local nx : word count `xoutvlist'
			assert `nx' == `: word count `xrownames''
			forvalues i = 1 / `nx' {
				local el : word `i' of `xrownames'
				if      `"`el'"'==`"Q_lci"' local vnames `vnames' _Qlci
				else if `"`el'"'==`"Q_uci"' local vnames `vnames' _Quci
				else if `"`el'"'==`"prop_eff"' local vnames `vnames' _Prop_ES
				else if `"`el'"'==`"prop_lci"' local vnames `vnames' _Prop_LCI
				else if `"`el'"'==`"prop_uci"' local vnames `vnames' _Prop_UCI
				else local vnames `vnames' _`el'
				local      rnames `rnames'  `el'
			}
			tokenize `xoutvlist'
			args `vnames'			// for later
		}
	}
	else if "`prvlist'"!="" {
		local PR_vnames _Prop_ES _Prop_LCI _Prop_UCI
		local PR_rnames prop_eff  prop_lci  prop_uci
		tokenize `prvlist'
		args `PR_vnames'
	}
	local vnames _ES  _seES    _LCI    _UCI `PR_vnames' `vnames'
	local rnames eff se_eff eff_lci eff_uci `PR_rnames' `rnames'
	
	// if rfdist, obtain appropriate varnames
	if `"`rfdist'"'!=`""' {			
		tempvar _rfLCI _rfUCI
		qui gen double `_rfLCI' = .
		qui gen double `_rfUCI' = .
		local RFDnames _rfLCI _rfUCI
		local vnames `vnames' `RFDnames'
		
		if "`prvlist'"!="" local rnames `rnames' prop_rflci prop_rfuci
		else local rnames `rnames' rflci rfuci
	}
	local na : word count `vnames'
	
	// subgroup effects (`_USE'==3)
	local nby = max(1, `: word count `bylist'')
	if `"`_BY'"'!=`""' & `"`subgroup'"'==`""' {
		forvalues i = 1 / `nby' {
			local allwtnames2 : copy local allwtnames	
			local byi : word `i' of `bylist'
			
			summ `obs' if `touse' & `_USE'==3 & `_BY'==`byi', meanonly
			// should be a maximum of one, if created by -ipdmetan-
			// if none, add to end;  if one, expand.  That way, they are all together
			
			// Also: Note that `obs' will not needed beyond this section, so use it to identify models
			if r(N)==0 {
				local omin = _N
				local omax = `omin' + `m'
				qui set obs `omax'
				local ++omin
				qui replace `_BY' = `byi' in `omin'/`omax'
				qui replace `_USE' = 3 in `omin'/`omax'
				qui replace `touse' = 1 in `omin'/`omax'
			}
			else if r(N)==1 {
				local omin = r(min)
				qui expand `m' if `obs' == `omin'
				local omax = `omin' + `m'
			}
			else {		// this should never actually happen
				nois disp as err "Error in data structure: more than one observation with _USE==3"
				exit 198
			}
			
			// insert statistics from `bystats'
			local index = 0
			forvalues j = 1 / `m' {
				local model : word `j' of `modellist'
				if (`j' > 1 & "`secsub'"!="") | "`model'"=="user" {
					qui drop in `=`omin' - 1 + `j'' / `omax'
					continue, break
				}
				if `j' > 1 gettoken wtname allwtnames2 : allwtnames2

				local ++index
				local bystats : word `index' of `bystatslist'
				local byhet   : word `index' of `byhetlist'
				forvalues k = 1 / `na' {
					local v  : word `k' of `vnames'
					local el : word `k' of `rnames'
					
					if "`bystats'"!="" {
						local r = rownumb(`bystats', "`el'")
						if !missing(`r') {
							qui replace ``v'' = `bystats'[`r', `i'] in `=`omin' - 1 + `j''
						}
					}
						
					// ... or from `hetstats'
					else if "`byhet'"!="" {
						local r = rownumb(`byhet', "`el'")
						if !missing(`r') {
							qui replace ``v'' = `byhet'[`r', `i'] in `=`omin' - 1 + `j''
						}
					}
					
					// ... or from `byQ'
					else if "`byQ'"!="" {
						local r = rownumb(`byq', "`el'")
						if !missing(`r') {
							qui replace ``v'' = `byq'[`r', `i'] in `=`omin' - 1 + `j''
						}
					}
					
					else {		// this should never happen
						nois disp as err "matrix {bf:byQ} not found"
						exit 198
					}
				}
				
				// `mwt' should always exist if `"`by'"'!=`""' & `"`subgroup'"'==`""' & `"`sgwt'"'==`""'
				if `"`sgwt'"'==`""' {
					cap assert "`mwt'"!=""
					if _rc {	// this should never happen
						nois disp as err "matrix {bf:mwt} not found"
						exit 198
					}
					
					if `j'==1 qui replace `_WT' = `mwt'[`index', `i'] in `omin'
					else if `"`wtname'"'!=`""' {
						qui replace `wtname' = `mwt'[`index', `i'] in `=`omin' - 1 + `j''
					}
				}
				else {
					if `j'==1 qui replace `_WT' = cond(!missing(`_ES'), 100, .) in `omin'
					else if `"`wtname'"'!=`""' {
						qui replace `wtname' = cond(!missing(`_ES'), 100, .) in `=`omin' - 1 + `j''
					}
				}
				qui replace `obs' = `j' in `=`omin' - 1 + `j''

			}	// end forvalues j = 1 / `m'
		}	// end forvalues i = 1 / `nby'
	}	// end if `"`_BY'"'!=`""' & `"`subgroup'"'==`""'

	// overall effect (`_USE'==5)
	if `"`overall'"'==`""' {
		local allwtnames2 : copy local allwtnames
		
		summ `obs' if `_USE'==5 & `touse', meanonly
		// should be a maximum of one, if created by -ipdmetan-
		// if none, add to end;  if one, expand.  That way, they are all together
		if r(N)==0 {
			local omin = _N
			local omax = `omin' + `m'
			qui set obs `omax'
			local ++omin
			qui replace `_USE' = 5 in `omin'/`omax'
			qui replace `touse' = 1 in `omin'/`omax'
		}
		else if r(N)==1 {
			local omin = r(min)
			qui expand `m' if `obs' == `omin'
			local omax = `omin' + `m'
		}
		else {		// this should never actually happen
			nois disp as err "Error in data structure: more than one observation with _USE==5"
			exit 198
		}
		
		local index = 0
		forvalues j = 1 / `m' {
			local model : word `j' of `modellist'
			if `j' > 1 gettoken wtname allwtnames2 : allwtnames2
			qui replace `obs' = `j' in `=`omin' - 1 + `j''
			
			// insert user-defined stats if appropriate...
			if "`model'"=="user" {
				tokenize `user`j'stats'
				
				// Modified Apr 2021: wherever `_ES' `_LCI' `_UCI' appear, use "_Prop" versions instead if `prvlist'
				if "`prvlist'"!="" {
					qui replace `_Prop_ES'  = `1' in `=`omin' - 1 + `j''
					qui replace `_Prop_LCI' = `2' in `=`omin' - 1 + `j''
					qui replace `_Prop_UCI' = `3' in `=`omin' - 1 + `j''
				}
				else {
					qui replace `_ES'  = `1' in `=`omin' - 1 + `j''
					qui replace `_LCI' = `2' in `=`omin' - 1 + `j''
					qui replace `_UCI' = `3' in `=`omin' - 1 + `j''
				}
			}

			// ... o/w insert statistics from `ovstats'
			else if "`ovstats'"!="" {
				local ++index
				forvalues k = 1 / `na' {
					local v  : word `k' of `vnames'
					local el : word `k' of `rnames'
					local r = rownumb(`ovstats', "`el'")
					if !missing(`r') {
						qui replace ``v'' = `ovstats'[`r', `index'] in `=`omin' - 1 + `j''
					}
					
					// ... or from `hetstats'
					else if "`hetstats'"!="" {
						local r = rownumb(`hetstats', "`el'")
						if !missing(`r') {
							qui replace ``v'' = `hetstats'[`r', `index'] in `=`omin' - 1 + `j''
						}
					}
						
					// ... or from `qlist'
					else if "`el'"=="Q"     qui replace ``v'' = `Q'     in `=`omin' - 1 + `j''
					else if "`el'"=="Qdf"   qui replace ``v'' = `Qdf'   in `=`omin' - 1 + `j''
					else if "`el'"=="Q_lci"	qui replace ``v'' = `Q_lci' in `=`omin' - 1 + `j''
					else if "`el'"=="Q_uci" qui replace ``v'' = `Q_uci' in `=`omin' - 1 + `j''
				}
			}
		
			if `"`ovwt'"'!=`""' {
				if `j'==1 qui replace `_WT' = cond(!missing(`_ES'), 100, .) in `omin'
				else if `"`wtname'"'!=`""' {
					qui replace `wtname' = cond(!missing(`_ES'), 100, .) in `=`omin' - 1 + `j''
				}
			}
		}		// end forvalues j = 1 / `m'
	}		// end if `"`overall'"'==`""'


	// June 2020: If passed from -ipdmetan- , may need to remove `_USE'==3, 5 if `nooverall' / `nosubgroup' (e.g. if `influence')
	// March 2021: modified to use the option `useflag' as the identifying characteristic
	if `"`useflag'"'!=`""' {
		if `"`subgroup'"'!=`""' cap drop if `_USE'==3
		if `"`overall'"'!=`""'  cap drop if `_USE'==5
		
		// June 2021: niche case - passed from -ipdmetan- with subgroup observations (_USE==3) for which no data
		//  - need to set `obs' to something else to avoid being caught by "assert"
		if `"`_BY'"'!=`""' {
			local bylist2 : subinstr local bylist " " ",", all
			qui replace `obs' = -`obs' if `_USE'==3 & !inlist(`_BY', `bylist2')
			qui replace `touse' = 0 if `_USE'==3 & !inlist(`_BY', `bylist2')
		}
	}
	
	// `obs' is not needed anymore, so use it to identify models for USE==3, 5
	qui replace `obs' = 0 if `touse' & !inlist(`_USE', 3, 5)
	cap assert inrange(`obs', 1, `m') if `touse' & `obs' > 0
	if _rc {
	    nois disp as err `"error in {bf:use(}{it:varname}{bf:)}"'
		exit 198
	}
	local useModel `obs'				// rename
	
	// _BY will typically be missing for _USE==5, so need to be careful when sorting
	// Hence, generate marker of _USE==5 to sort on *before* _BY
	tempvar use5
	qui gen byte `use5' = 0 if `touse'
	qui count if `_USE'==5
	// if `"`_BY'"'!=`""' & r(N) {
		qui replace `use5' = 1 if `touse' & `_USE'==5
	//}
	
	
	
	*******************************
	* Fill down counts, npts, oev *
	*******************************	
	
	local 0 `", `options'"'
	syntax [, SUMMSTAT(string) COUNTS(string asis) EBShrinkage EFFIcacy OEV LRVLIST(varlist numeric) LOGRank /*CUmulative INFluence*/ ALTWt ///
		PRoportion NOPR DENOMinator(real 1) * ]
	local opts_adm `"`macval(options)'"'		// because -syntax- used below with `counts'
	
	// Setup `counts' and `oev' options
	if `"`counts'"'!=`""' | `"`oev'"'!=`""' {
		tokenize `invlist'

		if `"`counts'"'!=`""' {
			if `params' == 6 args n1 mean1 sd1 n0 mean0 sd0			// `invlist'
			else {
				tempvar sum_e1 sum_e0
			
				// Log-rank (Peto) HR from -ipdmetan-
				// counts = "events/total in research arm; events/total in control arm"
				if `"`lrvlist'"'!=`""' {
					cap assert `params'==2 & "`logrank'"!=""
					if _rc {
						nois disp as err _n `"Error in communication between {bf:ipdmetan} and {bf:metan}"'
						exit 198
					}
					tokenize `lrvlist'
					args n1 n0 e1 e0
				}

				// Binary outcome (OR, Peto, RR, RD)
				// counts = "events/total in research arm; events/total in control arm"
				else if `params'==4 {
					args e1 f1 e0 f0		// `invlist'
					tempvar n1 n0
					qui gen long `n1' = `e1' + `f1'
					qui gen long `n0' = `e0' + `f0'
				}
				
				// Single-group proportion data
				else if "`proportion'"!="" args e0 n0
				else {
					disp _n `"{error}Note: {bf:counts} is only valid with 2x2 count data, continuous outcome data,"'
					disp    `"{error}  or single-group proportion data, so will be ignored"'
					local counts
				}	
			}
		}
		
		if `"`oev'"'!=`""' {
			if "`logrank'"!="" {
				tokenize `invlist'
				args _OE _V
			}
			else if "`model1'"=="peto" {
				tempvar _OE _V
				qui gen double `_OE' = `_ES' / `_seES'^2
				qui gen double `_V'  =    1  / `_seES'^2
			}
			else {
				disp _n `"{error}Note: {bf:oev} is not applicable without log-rank data or Peto ORs, so will be ignored"'
				local oev
			}
		}
		if `"`oev'"'!=`""' {
			local OEV_vlist _OE _V
			label variable `_OE' `"O-E(o)"'
			label variable `_V'  `"V(o)"'
			format `_OE' %6.2f
			format `_V' %6.2f
		}
	}			// end if `"`counts'"'!=`""' | `"`oev'"'!=`""'

	// Create `sumvlist' containing list of vars to fill down
	if `"`counts'"'!=`""' {
		if "`proportion'"!="" {
			// local sumvlist e0 n0
			local sumvlist e0				// DF 2022: only e0, because n0 and _NN are the same; don't repeat
			tempvar _counts0
		}
		else {
			local sumvlist n1 n0 
			if inlist(`params', 2, 4) {				// i.e. either logrank or 2x2 binary
				local sumvlist `sumvlist' e1 e0 
			}
			tempvar _counts1 _counts0
		}
	}
	local sumvlist `sumvlist' `OEV_vlist' `NN_opt'
	
	if `"`cumulative'`influence'"'!=`""' & `"`altwt'"'==`""' {
		foreach x of local sumvlist {
			tempvar sum_`x'
		}
	}
	
	// Now do the actual "filling down".
	// If `cumulative' or `influence', keep *both* versions: the original (to be stored in the current dataset, unless `nokeepvars')
	//   and the "filled down" (for the forestplot and/or saved dataset)...
	//   ...unless `altwt', in which case just keep the original.
	qui isid `touse' `use5' `_BY' `_USE' `useModel' `_SOURCE' `sortby', sort missok
	tempvar tempsum
	
	// subgroup totals
	if `"`_BY'"'!=`""' & `"`subgroup'"'==`""' {
		foreach x of local sumvlist {
			local xtype : type ``x''
			local xtype = cond(inlist("`xtype'", "float", "double"), "double", "long")
			qui by `touse' `use5' `_BY' : gen `xtype' `tempsum' = sum(``x'') if `touse'
			qui replace ``x'' = `tempsum' if `touse' & `_USE'==3 & `useModel'==1	// only for first model, as will repeat
			qui replace ``x'' = .         if `touse' & `_USE'==3 & `useModel' >1
			
			if `"`cumulative'`influence'"'!=`""' & `"`altwt'"'==`""' {
				if `"`influence'"'!=`""' {
					qui gen `xtype' `sum_`x'' = `tempsum' if `touse' & `_USE'==3	// `useModel' not relevant as cumulative/influence not compatible with multiple models
					
					qui by `touse' `use5' `_BY' : replace `tempsum' = ``x''[_N]
					qui replace `sum_`x'' = `tempsum' - ``x'' if `touse' & `_USE'==1
				}
				else qui gen `xtype' `sum_`x'' = `tempsum'
			}
			drop `tempsum'
		}
	}

	// overall totals
	if `"`overall'"'==`""' {
		foreach x of local sumvlist {
			local xtype : type ``x''
			local xtype = cond(inlist("`xtype'", "float", "double"), "double", "long")
			qui gen `xtype' `tempsum' = sum(``x'') if `touse' & `_USE'!=3
			qui replace ``x'' = `tempsum' if `touse' & `_USE'==5 & `useModel'==1	// only for first model, as will repeat
			qui replace ``x'' = .         if `touse' & `_USE'==5 & `useModel' >1

			if `"`cumulative'`influence'"'!=`""' & `"`altwt'"'==`""' {
				if `"`influence'"'!=`""' {
					summ ``x'' if `touse' & `_USE'==5, meanonly		// Note: `useModel' not relevant as cumulative/influence not compatible with multiple models
					
					if !(`"`_BY'"'!=`""' & `"`subgroup'"'==`""') {
						qui gen `xtype' `sum_`x'' = `tempsum' if `touse' & `_USE'==5
						qui replace `sum_`x'' = r(sum) - ``x'' if `touse' & `_USE'==1
					}
					else {
						qui replace `sum_`x'' = `tempsum' if `touse' & `_USE'==5
					}
				}
				// modified March 2020
				else {
					if !(`"`_BY'"'!=`""' & `"`subgroup'"'==`""') qui gen `xtype' `sum_`x'' = `tempsum'
					else qui replace `sum_`x'' = `tempsum' if `touse' & `_USE'==5
				}
			}
			drop `tempsum'
		}
	}

	// Reassign locals `x' to reference vars previously referenced by locals `sum_`x''
	// That is, "rename" our filled-down vars to their "original/natural" names.
	// (N.B. vars  n1, n0, e1, e0, _OE, _V are only relevant to *saved* datasets, not to the *original* dataset...
	//  ... plus _NN needs to be treated differently)
	// [Corrected Jan 2020]
	if `"`cumulative'`influence'"'!=`""' & `"`altwt'"'==`""' ///
		& ((`"`_BY'"'!=`""' & `"`subgroup'"'==`""') | `"`overall'"'==`""') {
		foreach x of local sumvlist {
			local `x' `sum_`x''
		}
	}

	
	** Finally, create `counts' string for forestplot
	if `"`counts'"'!=`""' {

		// option "counts" is guaranteed to be present (see ParseFPlotOpts); hence going forward local counts = "counts"
		local 0 `", `counts'"'
		syntax [, COUNTS GROUP1(string asis) GROUP2(string asis) ]
	
		// Titles
		// amended Feb 2018 due to local x = "" issue with version <13
		// local title1 = cond(`"`group2'"'!=`""', `"`group2'"', `"Treatment"')
		// local title0 = cond(`"`group1'"'!=`""', `"`group1'"', `"Control"')
		if `"`group1'"'!=`""' local title0 `"`group1'"'
		if "`proportion'"=="" {
			if `"`group2'"'!=`""' local title1 `"`group2'"'
			else local title1 "Treatment"
			if `"`group1'"'==`""' local title0 "Control"
		}
		else if `"`group2'"'!=`""' {
			disp _n `"{error}Note: {bf:group2()} is only valid with 2x2 count data or continuous outcome data, so will be ignored"'
			local group2
		}
		
		// Binary data, proportion data or logrank HR
		if inlist(`params', 2, 4) {
			qui gen `_counts0' = string(`e0') + "/" + string(`n0') if inlist(`_USE', 1, 2) | (inlist(`_USE', 3, 5) & `useModel'==1)
			label variable `_counts0' `"`title0' n/N"'
			
			if "`proportion'"=="" {
				qui gen `_counts1' = string(`e1') + "/" + string(`n1') if inlist(`_USE', 1, 2) | (inlist(`_USE', 3, 5) & `useModel'==1)
				label variable `_counts1' `"`title1' n/N"'
				drop `n1' `n0'		// tidy up
			}
		}
		
		// N mean SD for continuous outcome data
		// counts = "N, mean (SD) in research arm; N, mean (SD) events/total in control arm"
		else {
			tempvar _counts1msd _counts0msd

			qui gen long `_counts1' = `n1' if inlist(`_USE', 1, 2) | (inlist(`_USE', 3, 5) & `useModel'==1)
			qui gen `_counts1msd' = string(`mean1', "%7.2f") + " (" + string(`sd1', "%7.2f") + ")" if inlist(`_USE', 1, 2)
			label variable `_counts1' "N"
			label variable `_counts1msd' `"`title1' Mean (SD)"'
					
			qui gen long `_counts0' = `n0' if inlist(`_USE', 1, 2) | (inlist(`_USE', 3, 5) & `useModel'==1)
			qui gen `_counts0msd' = string(`mean0', "%7.2f") + " (" + string(`sd0', "%7.2f") + ")" if inlist(`_USE', 1, 2)
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

		if "`proportion'"!="" local COUNTSvl _counts0
		else local COUNTSvl _counts1 _counts0
		if `params'==6 local COUNTSvl `COUNTSvl' _counts1msd _counts0msd

	}	// end if `"`counts'"'!=`""'
	
	// end of "filling-down counts" section

	
	** Vaccine efficacy
	// (carried over from -metan- )
	tempvar strlen
	if `"`efficacy'"'!=`""' {

		// check: OR and RR only
		cap assert inlist("`summstat'", "or", "rr")
		if _rc {
			nois disp as err _n "Vaccine efficacy statistics only possible with odds ratios and risk ratios"
			exit _rc
		}
	
		tempvar _VE
		qui gen `_VE' = string(100*(1 - exp(`_ES')), "%4.0f") + " (" ///
			+ string(100*(1 - exp(`_LCI')), "%4.0f") + ", " ///
			+ string(100*(1 - exp(`_UCI')), "%4.0f") + ")" if `_USE'==1 | (inlist(`_USE', 3, 5) & `useModel'==1)
		
		label variable `_VE' "Vaccine efficacy (%)"
		local VE_opt _VE		// for `tosave' below
		
		qui gen `strlen' = length(`_VE')
		summ `strlen', meanonly
		format %`r(max)'s `_VE'
		qui compress `_VE'
		drop `strlen'
	}

	** [FEB 2024] Empirical Bayes shrinkage estimates
	// (carried over from -metan5- )
	if `"`ebshrinkage'"'!=`""' {
		tempvar _EBS_ES _EBS_seES
		qui gen double `_EBS_ES' = .
		qui gen double `_EBS_seES' = .
		format %6.3f `_EBS_ES' `_EBS_seES'
		label variable `_EBS_ES' "Empirical Bayes shrinkage estimate"
		label variable `_EBS_seES' "Standard error of empirical Bayes shrinkage estimate"
		local EBS_opt _EBS_ES _EBS_seES			// for `tosave' below

		tempname eff se_eff tausq
		if `"`sgwt'"'!=`""' {
			local bystats : word 1 of `bystatslist'		// use first model only
			forvalues i = 1 / `nby' {
				local byi : word `i' of `bylist'
				
				// Modified July 2024 to avoid errors with Stata 15 and older
				// "matrix operators that return matrices not allowed in this context
				local r = rownumb(`bystats', "eff")
				scalar `eff' = `bystats'[`r', `i']
				local r = rownumb(`bystats', "se_eff")
				scalar `se_eff' = `bystats'[`r', `i']
				local r = rownumb(`bystats', "tausq")				
				scalar `tausq' = `bystats'[`r', `i']
				
				qui replace `_EBS_ES' = (`_ES'*`tausq' + `eff'*`_seES'^2) / (`_seES'^2 + `tausq') if `_USE'==1 & `_BY'==`byi'
				qui replace `_EBS_seES' = sqrt( `_seES'^2 *`tausq'/(`_seES'^2 + `tausq') + (`se_eff'*`_seES'^2 / (`_seES'^2 + `tausq'))^2  ) if `_USE'==1 & `_BY'==`byi'
			}
		}
		else {
			// Modified July 2024 to avoid errors with Stata 15 and older
			// "matrix operators that return matrices not allowed in this context
			local r = rownumb(`ovstats', "eff")
			scalar `eff' = ovstats[`r', 1]			// use first model only
			local r = rownumb(`ovstats', "se_eff")
			scalar `se_eff' = ovstats[`r', 1]
			local r = rownumb(`ovstats', "tausq")
			scalar `tausq' = ovstats[`r', 1]
			qui replace `_EBS_ES' = (`_ES'*`tausq' + `eff'*`_seES'^2) / (`_seES'^2 + `tausq') if `_USE'==1
			qui replace `_EBS_seES' = sqrt( `_seES'^2 *`tausq'/(`_seES'^2 + `tausq') + (`se_eff'*`_seES'^2 / (`_seES'^2 + `tausq'))^2  ) if `_USE'==1
		}
	}
	
	
	** Weights
	// Aug 2023: moved upwards, and expand to include multiple models if `allwtnames'
	// May 2020: if modeltext is included, use compound quotes to force "% Weight" into a single line, with modeltext underneath
	if `m' > 1 {
		label variable `_WT' `"`"% Weight,"' `"`label1opt'"'"'
		if `"`allwtnames'"'!=`""' {
			local allwtnames2 : copy local allwtnames
			forvalues j = 2/`m' {
				gettoken wtname allwtnames2 : allwtnames2
				format `wtname' %6.2f
				label variable `wtname' `"`"% Weight,"' `"`label`j'opt'"'"'
				local newwtnamej = strtoname(`"_WT_`label`j'opt'"')
				local newwtnames `newwtnames' `newwtnamej'
			}
			tokenize `allwtnames'
			args `newwtnames'		// for `tosave' below
		}
	}
	// NEW JAN 2024: If cumulative or influence, replace "% Weight" with "Ratio of Variances"
	else if `"`cumulative'`influence'"'!=`""' {
		label variable `_WT' `"`"Ratio of"' `"Variances"'"'
		label variable `_WT_Final' "% Weight from final model"
	}
	else label variable `_WT' "% Weight"
	format `_WT' %6.2f
	

	*****************************************
	* Rename tempvars to permanent varnames *
	*****************************************

	local 0 `", `opts_adm'"'
	syntax [, SAVING(string) CLEAR CLEARSTACK RFLevel(cilevel) ILevel(cilevel) OLevel(cilevel) HLevel(cilevel) ///
		PREfix(name local) LCols(varlist) RCols(varlist) * ] /* <-- NEW JUL 2021*/ 
	local opts_adm `"`macval(options)'"'		// because -syntax- used below with `saving'
	
	* Test validity of lcols/rcols 
	// Cannot be any of the names -metan- (or -ipdmetan- etc.) uses for other things
	// To keep things simple, forbid any varnames:
	//  - beginning with a single underscore followed by a capital letter
	//  - beginning with "_counts" 
	// (Oct 2018: N.B. was `badnames'; Nov 2021 new `badnames' code added below)
	local badnames _USE _SOURCE _STUDY _LABELS _BY
	local badnames `badnames' _ES _seES _LCI _UCI _WT _NN _rfLCI _rfUCI _OE _V _CC _VE _EBS_ES _EBS_seES
	if `"`cumulative'`influence'"'!=`""' {
		local badnames `badnames' _crit _chi2 _dfkr _pvalue _Q _Qdf _Qlci _Quci _H _Isq _HsqM _sigmasq _tausq _tsq_lci _tsq_uci _WT_Final
	}
	// also _Prop*, _counts* ; see below
	
	local lrcols `lcols' `rcols'
	local check = 0
	if trim(`"`lrcols'"') != `""' {
		// local cALPHA `c(ALPHA)'

		foreach el of local lrcols {
		    foreach bad of local badnames {
			    local el_len = length(`"`el'"')
			    local badlen = length(`"`bad'"')
				if (substr(`"`el'"', 1, `badlen')==`"`bad'"') | (substr(`"`bad'"', 1, `el_len')==`"`el'"') {
					nois disp as err _n `"Error in option {bf:lcols()} or {bf:rcols()}:"'
					nois disp as err `" Variable name {bf:`el'} is reserved for use by {bf:ipdmetan}, {bf:ipdover} and {bf:forestplot}."'
					nois disp as err `"In order to save the results set, please rename this variable or use {bf:{help clonevar}}."'
					exit 101
				}
			}
			
			/*
			local el2 = substr(`"`el'"', 2, 1)
			if substr(`"`el'"', 1, 1)==`"_"' & `: list el2 in cALPHA' {
				nois disp as err _n `"Error in option {bf:lcols()} or {bf:rcols()}:  Variable names such as {bf:`el'}, beginning with an underscore followed by a capital letter,"'
				nois disp as err `" are reserved for use by {bf:ipdmetan}, {bf:ipdover} and {bf:forestplot}."'
				nois disp as err `"In order to save the results set, please rename this variable or use {bf:{help clonevar}}."'
				exit 101
			}
			*/
			
			else if substr(`"`el'"', 1, 7)==`"_counts"' {
				nois disp as err _n `"Error in option {bf:lcols()} or {bf:rcols()}:  Variable names beginning {bf:_counts} are reserved for use by {bf:ipdmetan}, {bf:ipdover} and {bf:forestplot}."'
				nois disp as err `"In order to save the results set, please rename this variable or use {bf:{help clonevar}}."'
				exit 101
			}
		
			else if `"`proportion'"'!=`""' & substr(`"`el'"', 1, 6)==`"_Prop_"' {
				nois disp as err _n `"Error in option {bf:lcols()} or {bf:rcols()}:  Variable names beginning {bf:_Prop_} are reserved for use by {bf:ipdmetan}, {bf:ipdover} and {bf:forestplot}."'
				nois disp as err `"In order to save the results set, please rename this variable or use {bf:{help clonevar}}."'
				exit 101
			}
			
			// Added Aug 2023
			else if `"`allwtnames'"'!=`""' & substr(`"`el'"', 1, 4)==`"_WT_"' {
				nois disp as err _n `"Error in option {bf:lcols()} or {bf:rcols()}:  Variable names beginning {bf:_WT_} are reserved for use by {bf:ipdmetan}, {bf:ipdover} and {bf:forestplot}."'
				nois disp as err `"In order to save the results set, please rename this variable or use {bf:{help clonevar}}."'
				exit 101
			}

			// `saving' / `clear' only:
			// Test validity of (value) *label* names: just _BY, _STUDY, _SOURCE as applicable
			// Value labels are unique within datasets. Hence, not a problem for a var in lcols/rcols to have same value label as the by() or study() variable.
			// However, a var in lcols/rcols **cannot** use the label name _BY or _STUDY **unless** the by() or study() variable is already sharing that label name.
			// (Also, cannot use _SOURCE as a value label if `"`_SOURCE'"'!=`""')
			if `"`saving'"'!=`""' | `"`clear'`clearstack'"'!=`""' {
			
				local lrlab : value label `el'
				if `"`lrlab'"'==`"`prefix'_BY"' {
					if `"`_BY'"'==`""' local check = 1
					else {
						if `"`: value label `_BY''"'!=`"`prefix'_BY"' local check = 1
					}
				}
				if `"`lrlab'"'==`"`prefix'_STUDY"' {
					if `"`_STUDY'"'==`""' local check = 1
					else {
						if `"`: value label `_STUDY''"'!=`"`prefix'_STUDY"' local check = 1
					}
				}
				if `"`lrlab'"'==`"`prefix'_SOURCE"' {
					if `"`_SOURCE'"'==`""' local check = 1
					else {
						if `"`: value label `_SOURCE''"'!=`"`prefix'_SOURCE"' local check = 1
					}
				}
				if `check' {
					nois disp as err _n `"Error in option {bf:lcols()} or {bf:rcols()}:  Label name {bf:`lrlab'} attached to variable {bf:`el'}"'
					nois disp as err `"  is reserved for use by {bf:metan} and {bf:forestplot}."'
					nois disp as err `"In order to save the results set, please rename the label attached to this variable (e.g. using {bf:{help label copy}})."'
					exit 101
				}
			}		// end if `"`saving'"'!=`""' | `"`clear'"'!=`""'
		}		// end foreach el of local lrcols
	}		// end if trim(`"`lrcols'"') != `""'
		
	// Initialize varlists to save in Results Set:
	// `core':  "core" variables (N.B. *excluding* _NN)
	local core _ES _seES _LCI _UCI `PR_vnames' _WT
	
	// tosave':  additional "internal" vars created by specific options
	// [may contain: _NN; _OE _V if `oev'; `COUNTSvl' if `counts'; _VE if `efficacy'; _EBS_ES _EBS_seES if `ebshrinkage'; _CC if `cc'; _rfLCI _rfUCI if `rfdist']
	cap confirm numeric var `_CC'
	if !_rc local CC_opt _CC
	
	local tosave `NN_opt' `OEV_vlist' `COUNTSvl' `VE_opt' `EBS_opt' `CC_opt' `RFDnames' `newwtnames'
	if `"`xoutvlist'"'!=`""' local tosave : list tosave | vnames
	local tosave : list tosave - core
	
	// "Labelling" variables: _USE, _STUDY, _BY etc.
	local labelvars _USE
	if `"`_BY'"'!=`""'     local labelvars `labelvars' _BY
	if `"`_SOURCE'"'!=`""' local labelvars `labelvars' _SOURCE
	local labelvars `labelvars' _STUDY _LABELS

	// If `saving' / `clear', finish off renaming tempvars to permanent varnames
	// ...in order to store them in the *saved* dataset (NOT the data in memory)
		
	// ... also, if `saving', need to extract `stacklabel' option
	// [July 2021: moved downwards]
	if `"`saving'"'!=`""' {
		// use modified version of built-in _prefix_saving.ado
		my_prefix_saving `saving'
		local fname `"`s(filename)'"'
		local 0 `", `s(opts_saving)'"'
		syntax [, REPLACE STACKlabel ]
	}
	if `"`clearstack'"'!=`""' {
		local clear clear
		local stacklabel stacklabel		// July 2021; see explanation above
	}
	
	local allwtnames
	local finalvars
	local tocheck `labelvars' `core' `tosave'
	foreach v of local tocheck {
		confirm variable ``v''

		if `"`saving'"'!=`""' | `"`clear'"'!=`""' {
			
			// For "saved" variable names, 
			//   check if pre-existing var (``v'') has the "correct" name (`prefix'`v').
			// If it does not, first drop any existing var named `prefix'`v' (e.g. left over from previous -metan- call), then rename.
			if `"``v''"'!=`"`prefix'`v'"' {
				cap drop `prefix'`v'
				
				// If ``v'' is in `lrcols' or `sortby', use -clonevar-, so as also to keep original name
				if `: list `v' in lrcols' | `: list `v' in sortby' {
					qui clonevar `prefix'`v' = ``v'' if `touse'
				}
				else qui rename ``v'' `prefix'`v'
			}
			
			// Similar logic also applies to value labels for numeric _STUDY, _BY and _SOURCE:
			//   check if pre-existing var (``v'') has the "correct" value label name (`prefix'`v').
			// If it does not, drop any existing value label `v', and copy current value label across to `prefix'`v'.
			if inlist("`v'", "_STUDY", "_BY", "_SOURCE") {
				if `"`: value label `prefix'`v''"' != `""' & `"`: value label `prefix'`v''"' != `"`prefix'`v'"' {
					cap label drop `prefix'`v'
					label copy `: value label `prefix'`v'' `prefix'`v'
					label values `prefix'`v' `prefix'`v'
				}
			}

			// IF RENAMING, DON'T REFORMAT; KEEP ORIGINAL FORMAT
			// SO THAT -forestplot- USES ORIGINAL FORMAT
			// APPLIES TO _ES, _seES, _LCI, _UCI
			else if inlist("`v'", "_ES", "_seES", "_LCI", "_UCI") {
				// format %6.3f `prefix'`v'
				label variable `prefix'`v' `"`prefix'`v'"'
			}

			local `v' `prefix'`v'				// for use with subsequent code
		}		// end if `"`saving'"'!=`""' | `"`clear'"'!=`""'
		
		local finalvars `finalvars' ``v''
		
		// Aug 2023
		if `: list v in newwtnames' local allwtnames `allwtnames' ``v''
		
	}		// end foreach v of local tocheck
		
	// Now, label variables with short-ish names for display on forest plots
	//  and apply characteristics to store longer, explanatory names
	// [July 2022] Note: ApplyLabels works independently of re-naming above, including use of `prefix'
	ApplyLabels if `touse', tvlist(`finalvars') vnames(`tocheck') xoutvlist(`xoutvlist') ///
		summstat(`summstat') `cumulative' `influence' `proportion' `nopr' `rfdist' ///
		rflevel(`rflevel') ilevel(`ilevel') olevel(`olevel') hlevel(`hlevel')


	
	*********************
	* Insert extra rows *
	*********************
	// ... for headings, labels, spacings etc.
	//  Note: in the following routines, "half" values of _USE are used temporarily to get correct order
	//        and are then replaced with whole numbers at the end			

	local 0 `", `opts_adm'"'
	syntax [, SUMMARYONLY noBETWeen LABTITLE(string asis) EXTRALine(string) NPTS noMODELLABels noHET HETINFO(string) ISQParam * ]
	local opts_adm `"`macval(options)'"'
	
	// Variable name (titles) for "_LABELS" or `stacklabel' [modified Mar 2022]
	if `"`stacklabel'"'!=`""' | (`"`_BY'"'==`""' & `"`summaryonly'"'!=`""') {
		label variable `_LABELS'		// no title if `stacklabel',  or if `summaryonly' without by()
	}
	else label variable `_LABELS' `"`labtitle'"'
	
	// Extra line for heterogeneity in forest plot
	local extraline = trim(`"`extraline'"')
	if      inlist(`"`extraline'"', "off", "n", "no", "non", "none") local extraline no
	else if inlist(`"`extraline'"', "on", "y", "ye", "yes") local extraline yes
	else if `"`extraline'"'!=`""' {
		nois disp as err `"invalid option {bf:extraline(`extraline')}"'
		exit 198
	}
	
	// If `npts', `counts', `oev' or `efficacy' requested for display on forest plot
	//   then heterogeneity stats will need to be on a new line [ unless manually overruled with extraline(off) ]
	if `"`het'`extraline'"'==`""' & `"`npts'`counts'`oev'`efficacy'"'!=`""' local extraline yes

	// [May 2020] Similarly if `ilevel'!=`olevel', implying extra text for subgroup/overall effects
	if `ilevel'!=`olevel' local extraline yes
	
	// Now temporarily multiply `_USE' and `useModel' by 10
	// to enable intermediate numberings for sorting the extra rows
	qui replace `_USE' = `_USE' * 10
	tempvar expand
	
	* Subgroup headings
	// Idea is to expand for "all values of _BY", but leave the "overall" row(s) alone (_USE==5).
	// _BY is missing for _USE==5, but this won't work as "missing" could equally be a legitimate value for _BY!!
	// So, instead, we have generated `use5' to mark those observations (_USE==5) where we don't want _BY groups to be expanded.
	if `"`_BY'"'!=`""' {
		if `"`summaryonly'"'==`""' {
			qui bysort `touse' `_BY' (`sortby') : gen byte `expand' = 1 + 2*`touse'*(_n==1)*(!`use5')
			qui expand `expand'
			qui replace `expand' = !(`expand' > 1)							// `expand' is now 0 if expanded and 1 otherwise (for sorting)
			sort `touse' `_BY' `expand' `_USE' `useModel' `_SOURCE' `sortby'
			qui by `touse' `_BY' : replace `_USE' = 0  if `touse' & !`expand' & _n==2	// row for headings (before)
			qui by `touse' `_BY' : replace `_USE' = 41 if `touse' & !`expand' & _n==3	// row for blank line (after)
		}
		else {
			summ `_BY' if `touse', meanonly
			qui bysort `touse' `_BY' (`sortby') : gen byte `expand' = 1 + `touse'*(`_BY'==`r(max)')*(_n==_N)*(!`use5')
			qui expand `expand'
			qui replace `expand' = !(`expand' > 1)							// `expand' is now 0 if expanded and 1 otherwise (for sorting)
			sort `touse' `_BY' `expand' `_USE' `useModel' `_SOURCE' `sortby'
			qui by `touse' `_BY' : replace `_USE' = 41 if `touse' & !`expand' & _n==2	// row for blank line (only after last subgroup)
		}
		drop `expand'
		qui replace `useModel' = . if `_USE'==41	// ensure blank lines come at the end
					
		// Subgroup spacings & heterogeneity
		// if "`subgroup'"=="" & `"`extraline'"'==`"yes"' & !(`m' > 1 & inlist("`model1'", "iv", "mh", "peto", "mu")) {
		// if "`subgroup'"=="" & `"`extraline'"'==`"yes"' {	// modified Sep 2020
		if "`subgroup'"=="" & `"`het'"'==`""' {							// modified Aug 2023
			qui bysort `touse' `_BY' (`sortby') : gen byte `expand' = 1 + 2*`touse'*(_n==_N)*(!`use5')
			qui expand `expand'
			qui replace `expand' = !(`expand' > 1)						// `expand' is now 0 if expanded and 1 otherwise (for sorting)
			sort `touse' `_BY' `expand' `_USE' `useModel' `_SOURCE' `sortby'
			qui by `touse' `_BY' : replace `_USE' = 38 if `touse' & !`expand' & _n==2	// extra row after *first* model (may not be needed)
			qui replace `useModel' = 1 if `_USE'==38
			qui by `touse' `_BY' : replace `_USE' = 39 if `touse' & !`expand' & _n==3	// extra row after *last* model (may not be needed)
			qui replace `useModel' = `m' if `_USE'==39								
			drop `expand'
		}
	}	// end if `"`_BY'"'!=`""'
	
	// Predictive intervals
	if `"`rfdist'"'!=`""' {
		local oldN = _N
		qui gen byte `expand' = 1 + `touse'*inlist(`_USE', 30, 50) * !missing(`_rfLCI')
		qui expand `expand'
		drop `expand'
		qui replace `_USE' = 35 if `touse' & _n>`oldN' & `_USE'==30
		qui replace `_USE' = 55 if `touse' & _n>`oldN' & `_USE'==50
	}
	
	// Blank out effect sizes etc. in `expand'-ed rows
	// Dec 2019: don't blank out `_rfLCI' `_rfUCI', as they haven't been copied across yet
	local tosave2 : list tosave - RFDnames
	foreach x in _LABELS `core' `tosave2' {
		cap confirm numeric var ``x''
		if !_rc qui replace ``x'' = .  if `touse' & !inlist(`_USE', 10, 20, 30, 50)
		else    qui replace ``x'' = "" if `touse' & !inlist(`_USE', 10, 20, 30, 50)
	}
	
	// In the above foreach x... , the elements are tempvars.
	// Now blank out `lrcols', which (if defined) contains actual variables.
	// Dec 2018: if `_BY' is also in `lrcols', exclude from this procedure
	if `"`_BY'"'!=`""' {
		local lrcols2 : list lrcols - _BY
	}
	else local lrcols2 : copy local lrcols
	if `"`lrcols2'"'!=`""' {
		foreach v of varlist `lrcols2' {
			cap confirm numeric var `v'
			if !_rc qui replace `v' = .  if `touse' & !inlist(`_USE', 10, 20, 30, 50)
			else    qui replace `v' = "" if `touse' & !inlist(`_USE', 10, 20, 30, 50)
		}
	}
	
	if `"`summaryonly'"'==`""' {
		if `"`_STUDY'"'!=`""' {
			qui replace `_STUDY' = . if `touse' & !inlist(`_USE', 10, 20)
		}
	}
	
	// extra row to contain what would otherwise be the leftmost column heading if `stacklabel' specified
	// (i.e. so that heading can be used for forestplot stacking)
	// cap drop `use5'
	// qui gen byte `use5' = 0 if `touse'
	if `"`stacklabel'"' != `""' {
		local newN = _N + 1
		qui set obs `newN'
		qui replace `touse' = 1  in `newN'
		qui replace `use5' = -1  in `newN'
		qui replace `_USE' = -10 in `newN'
		qui replace `_LABELS' = `"`labtitle'"' in `newN'
	}

	
	** Now insert label info into new rows
	if trim(`"`hetinfo'"')==`""' {
		local defhetinfo defhetinfo
		
		// default, to match with -metan- v3.04, is Isq + p-value
		local hetinfo isq p
		//  -- unless `isqparam', in which case default is Isq alone
		if `"`isqparam'"'!=`""' local hetinfo isq
		//  -- or if `model1' is sensitivity analysis with tausq, in which case default is tausq (+ Isq if `isqparam')
		local sa sa
		if `: list sa in modellist' {
			local hetinfo tausq
			if `"`isqparam'"'!=`""' local hetinfo tausq isq
		}
	}

	// local disperr_tsqb  = 0		// init
	local disperr_tausq = 0		// init
	local derived = 0			// init -- added Aug2023
	
	local index_ov = 0
	local index_by = 0
	local allwtnames2 : copy local allwtnames
	
	// Multiple models
	forvalues j = 1 / `m' {
		local model : word `j' of `modellist'
		local first = cond(`j'==1, cond(`m'==1, "firstonly", "first"), "")		// marker of this being the first (aka main, aka primary) model

		// "overall" labels
		if `"`overall'"'==`""' {
			local ovhetlab1
			local ovhetlab2
			
			if `"`het'"'==`""' {
				if `"`extra`j'opt'"'!=`""' | "`model'"=="user" {	// May 2023: if model=user, `extra`j'opt' might be blank; still don't want to run ParseHetInfo
					local ovhetlab1 : copy local extra`j'opt
					if `"`defhetinfo'"'==`""' {
						nois disp `"{error}Note: option {bf:extra`j'label()} will take precedence over {bf:hetinfo()}"'
					}
				}
				else {
				    local ++index_ov
					ParseHetInfo `hetinfo', ovstats(`ovstats') hetstats(`hetstats') ///
						col(`index_ov') model(`model') `first' qlist(`Q' `Qdf') `isqparam'
					local ovhetlab1 `"`s(hetlab1)'"'			// Modified Aug2023
					local ovhetlab2 `"`s(hetlab2)'"'
				}

				if `"`first'"'!=`""' {					
					// Heterogeneity info to be placed after the *first* model if extraline=yes (modified Aug 2023)
					if `"`ovhetlab1'"'!=`""' & `"`extraline'"'==`"yes"' {
						local newN = _N + 1
						qui set obs `newN'
						qui replace `touse' = 1  in `newN'
						cap confirm variable `use5'
						if !_rc {
							qui replace `use5' = 1  in `newN'
						}
						qui replace `_USE' = 58 in `newN'
						qui replace `useModel' = 1 in `newN'
						qui replace `_LABELS' = `"(`ovhetlab1')"' in `newN'
						local ovhetlab1				// ovlabel on line below so no conflict with lcols; then clear macro
					}
				
					// Final heterogeneity info to be placed after the *last* model (modified Aug 2023)
					if `"`ovhetlab2'"'!=`""' {
						local newN = _N + 1
						qui set obs `newN'
						qui replace `touse' = 1  in `newN'
						cap confirm variable `use5'
						if !_rc {
							qui replace `use5' = 1  in `newN'
						}
						qui replace `_USE'  = 59 in `newN'
						qui replace `useModel' = `m' in `newN'
						qui replace `_LABELS' = `"(`ovhetlab2')"' in `newN'		// N.B. `ovhetlab2' is not used henceforth
					}
				}		// end if `"`first'"'!=`""'
			}		// end if `"`het'"'==`""'
		
			// Model labels (including hetinfo if appropriate)
			local addText
			if `"`modellabels'"'==`""' & trim(`"`label`j'opt'"')!=`""' {
				local addText `", `label`j'opt'"'	// Nov 2020
				if "`model'"=="dlc" & `"`label`j'opt'"'==`"DL (Common)"' local addtext `", DL"'	// May 2023
			}
			if `ilevel'!=`olevel' local addText `"`addText' (`olevel'% CI)"'			
			if `"`ovhetlab1'"'!=`""' local addText `"`addText' (`ovhetlab1')"'
			qui replace `_LABELS' = `"Overall`addText'"' if `_USE'==50 & `useModel'==`j'
			
		}	// end if `"`overall'"'==`""'
		
		// subgroup ("by") headings & labels
		if `"`_BY'"'!=`""' {
			tempname Qi Qdfi
			
			if "`model'"!="user" local ++index_by
			
			forvalues i = 1 / `nby' {
				local bystats : word `index_by' of `bystatslist'
				if "`byhetlist'"!="" {
					local byhet : word `index_by' of `byhetlist'
				}
				
				// headings
				local byi : word `i' of `bylist'
				local bylabi : label (`_BY') `byi'
				if `"`summaryonly'"'==`""' {
					qui replace `_LABELS' = "`bylabi'" if `_USE'==0 & `_BY'==`byi'
				}
				
				// labels + heterogeneity
				if `"`subgroup'"'==`""' {
					
					if `"`summaryonly'"'!=`""' local sglabel `"`bylabi'"'
					else local sglabel "Subgroup"		// amended Feb 2018 due to local x = ... issue with version <13
					local sghetlab1
					local sghetlab2
				
					if `"`het'"'==`""' {
						
						// User-defined second model, or nosecsub
						local model : word `j' of `modellist'
						if ("`first'"=="" & "`secsub'"!="") | "`model'"=="user" {		// Note: "user" as model1 cannot be used with "by"
							continue, break
						}
						
						// Modified July 2024 to avoid errors with Stata 15 and older
						// "matrix operators that return matrices not allowed in this context
						local r = rownumb(`byq', "Q")
						scalar `Qi'   = `byq'[`r', `i']
						local r = rownumb(`byq', "Qdf")
						scalar `Qdfi' = `byq'[`r', `i']
						
						ParseHetInfo `hetinfo', ovstats(`bystats') hetstats(`byhet') ///
							col(`i') model(`model') `first' qlist(`=`Qi'' `=`Qdfi'') `isqparam'
						local sghetlab1 `"`s(hetlab1)'"'			// Modified Aug2023
						local sghetlab2 `"`s(hetlab2)'"'
						
						if `"`first'"'!=`""' {
							
							// Heterogeneity info to be placed after the *first* model if extraline=yes (modified Aug 2023)
							if `"`sghetlab1'"'!=`""' & `"`extraline'"'==`"yes"' {
								qui replace `_LABELS' = `"(`sghetlab1')"' if `_USE'==38 & `_BY'==`byi' & `useModel'==1
								local sghetlab1			// sghetlab on line below so no conflict with lcols; then clear macro
							}
							else qui drop if `_USE'==38 & `_BY'==`byi' & `useModel'==1

							// Final heterogeneity info to be placed after the *last* model (modified Aug 2023)
							if `"`sghetlab2'"'!=`""' {
								qui replace `_LABELS' = `"(`sghetlab2')"' if `_USE'==39 & `_BY'==`byi' & `useModel'==`m'
							}
							else qui drop if `_USE'==39 & `_BY'==`byi' & `useModel'==`m'
						}
					}		// end if `"`het'"'==`""'
					
					// Model labels (including hetinfo if appropriate)
					local addText
					if `"`modellabels'"'==`""' & trim(`"`label`j'opt'"')!=`""' {
						local addText `", `label`j'opt'"'			// Nov 2020
					}
					if `ilevel'!=`olevel' local addText `"`addText' (`olevel'% CI)"'
					if `"`sghetlab1'"'!=`""' local addText `"`addText' (`sghetlab1')"'
					qui replace `_LABELS' = `"`sglabel'`addText'"' if `_USE'==30 & `_BY'==`byi' & `useModel'==`j'

				}		// end if `"`subgroup'"'==`""'
			}		// end forvalues i = 1 / `nby'
			
			// add between-group heterogeneity info
			// ONLY USE "PRIMARY" (FIRST) MODEL
			// Amended Jan 2020 to use Qbet rather than Qdiff:
			if `"`subgroup'`het'"'!=`""' local between nobetween	// added June 2022
			if "`first'"!="" & `"`between'"'==`""' {
				local newN = _N + 1
				qui set obs `newN'
				qui replace `touse' = 1  in `newN'
				qui replace `use5'  = 0  in `newN'
				qui replace `_USE'  = 49 in `newN'
				qui replace `useModel'=1 in `newN'
		
				tempname Qbetpval
				scalar `Qbetpval' = chi2tail(`nbyQ' - 1, `Qbet')
				qui replace `_LABELS' = "Heterogeneity between groups: p = " + string(`Qbetpval', "%5.3f") in `newN'
			}
		}		// end if `"`_BY'"'!=`""'
	}		// end forvalues j = 1 / `m'

	// Added Sep 2020, modified Aug 2023
	if `disperr_tausq' {
		disp _n
		disp `"{error}Note: Element {bf:tausq} to option {bf:hetinfo()} is not applicable to "' _c 
		if `m'==1 disp `"{error}model {bf:`model1'}"'
		else disp `"{error}all models"'
	}
	
	// Insert predictive interval data (will be checked later)
	if `"`rfdist'"'!=`""' {
		qui replace `_LABELS' = `"with estimated `rflevel'% predictive interval"' if inlist(`_USE', 35, 55)
		
		if "`prvlist'"!="" {
			qui replace `_Prop_LCI' = `_rfLCI' if inlist(`_USE', 35, 55)
			qui replace `_Prop_UCI' = `_rfUCI' if inlist(`_USE', 35, 55)
		}
		else {
			qui replace `_LCI' = `_rfLCI' if inlist(`_USE', 35, 55)
			qui replace `_UCI' = `_rfUCI' if inlist(`_USE', 35, 55)
		}
		// qui drop if missing(`_LCI', `_UCI') & inlist(`_USE', 35, 55)		// if predictive interval was undefined
	}
	
	// If proportion with denominator, scale appropriately
	if "`proportion'"!="" & "`nopr'"=="" {
		if `denominator'!=1 {
			if "`prvlist'"!="" local toscale _Prop_ES _Prop_LCI _Prop_UCI
			else local toscale _ES _LCI _UCI
			if "`rfdist'"!="" local toscale `toscale' _rfLCI _rfUCI
			
			foreach v of local toscale {
				qui replace ``v'' = `denominator' * ``v''
			}
		}
		local denom_opt denominator(`denominator')		// March 2021: for forest plot
	}
	
	

	*********************
	* Sort, and tidy up *
	*********************

	local 0 `", `opts_adm'"'
	syntax [, KEEPALL KEEPOrder noWT noSTATs noWARNing noGRaph INTERaction PLOTID(string) EFORM EFFect(string asis) WGT(varname numeric) ///
		CREATEDBY(string) FORESTplot(string asis) FPNOTE(string asis) SFMTLEN(integer 8) * ]
	local twowayopts `"`macval(options)'"'

	if `"`keeporder'"'!=`""' {
		tempvar tempuse
		qui gen byte `tempuse' = `_USE'
		qui replace `tempuse' = 10 if `_USE'==20		// keep "insufficient data" studies in original study order (default is to move to end)
		local keepall keepall
	}
	else local tempuse `_USE'
	
	/* MAY 2024 */
	local 0 `plotid'
	syntax [name(name=plname id="plotid")] [, *]
	if `"`plname'"'==`"_BYAD"' {
		cap confirm numeric variable `_SOURCE'
		if _rc {
			nois disp as err "option {bf:plotid(_BYAD)} supplied, but identifier of data source not found"
			exit 198
		}
		local plotid `"plotid(`_SOURCE', `options')"'
	}
	else if `"`plname'"'!=`""' local plotid `"plotid(`plotid')"'
	
	qui isid `touse' `use5' `_BY' `useModel' `tempuse' `_SOURCE' `sortby', sort missok
	
	** Tidy up `_USE' (and scale back down by 10)
	cap drop `use5'
	quietly {
		// gen byte `use5' = inlist(`_USE', 35, 55)		// now `use5' is a marker of predictive interval data, if applicable
		replace `_USE' =  0 if `_USE' == -10				// 0 = blank row
		// replace `_USE' = 30 if `_USE' ==  35				// 3 = subgroup pooled effect
		replace `_USE' = 40 if inlist(`_USE', 38, 39, 49, 58, 59)	// 4 = heterogeneity info (either between-subgroup, or extra rows for het. stats if needed)
		// replace `_USE' = 50 if `_USE' ==  55				// 5 = overall pooled effect
		replace `_USE' = 60 if `_USE' ==  41				// 6 = blank line
		replace `_USE' = 70 if inlist(`_USE', 35, 55)		// 7 = predictive interval data (if applicable)
		replace `_USE' = `_USE' / 10
	}
	
	// Check predictive interval data (after sorting and finalising _USE)
	// March 2020: added "& !missing(`_LCI')" to end of 3rd & 4th lines, in case of "empty" subgroups
	// May 2020: if `rflevel' < `olevel' and low heterogeneity, then (rfLCI, rfUCI) might be tighter than (LCI, UCI)
	if `"`rfdist'"'!=`""' {
		cap {
			if "`prvlist'"!="" {
				assert float(`_rfLCI') <= float(`_Prop_LCI')  if `touse' & !missing(`_rfLCI', `_Prop_LCI') & `rflevel'>=`olevel'
				assert float(`_rfUCI') >= float(`_Prop_UCI')  if `touse' & !missing(`_rfUCI', `_Prop_UCI') & `rflevel'>=`olevel'
				assert `_USE'==7 &  missing(`_Prop_ES')       if `touse' & !missing(`_Prop_LCI') & float(`_rfLCI')==float(`_Prop_LCI') & float(`_rfUCI')==float(`_Prop_UCI')
				assert `_USE'==7 & !missing(`_Prop_ES'[_n-1]) if `touse' & !missing(`_Prop_LCI') & float(`_rfLCI')==float(`_Prop_LCI') & float(`_rfUCI')==float(`_Prop_UCI')
			}
			else {
				assert float(`_rfLCI') <= float(`_LCI')  if `touse' & !missing(`_rfLCI', `_LCI') & `rflevel'>=`olevel'
				assert float(`_rfUCI') >= float(`_UCI')  if `touse' & !missing(`_rfUCI', `_UCI') & `rflevel'>=`olevel'
				assert `_USE'==7 &  missing(`_ES')       if `touse' & !missing(`_LCI') & float(`_rfLCI')==float(`_LCI') & float(`_rfUCI')==float(`_UCI')
				assert `_USE'==7 & !missing(`_ES'[_n-1]) if `touse' & !missing(`_LCI') & float(`_rfLCI')==float(`_LCI') & float(`_rfUCI')==float(`_UCI')
			}
			assert missing(`_ES') if `touse' & `_USE'==7	// added June 2023
		}
		if _rc {
			nois disp as err _n "Error in predictive interval data"
			exit _rc
		}
	}

	// `extraline' then becomes `nolcolscheck' for passing to -forestplot-
	// Logic here is:  `extraline' can be "yes", "no" or missing (i.e. undefined)
	// If definitely "yes", suppress the check in -forestplot- for columns which might clash with heterogeneity info etc.
	// Hence, it is possible to suppress this check *even if* such columns actually exist, if we think they *don't* in fact clash.	
	local lcolscheck = cond(`"`extraline'"'==`"yes"', `"nolcolscheck"', `""')
	// Feb 2021:  above line (and comments) moved down from earlier
	
	// Having added "overall", het. info etc., re-format _LABELS using `sfmtlen'
	// Feb 2021: unless filled-down variables (counts, npts, efficacy, OEV)
	if `"`npts'`counts'`oev'`efficacy'"'!=`""' {
		qui gen `strlen' = length(`_LABELS')	

		// Aug 2023: account for SMCL code within labels, which makes `strlen' excessively large
		// Note: currently this code only corrects SMCL generated from within -metan- itself, i.e. heterogeneity-related stuff
		// Future work may involve generalization to detect and correct for *any* SMCL found in _LABELS
		forvalues i=1/`=_N' {
			if !inlist(`_USE'[`i'], 3, 5) continue
			local labstr = `_LABELS'[`i']
			if strpos(`"`labstr'"', `"{&tau}"') qui replace `strlen' = `strlen' - 5 in `i'
			if strpos(`"`labstr'"', `"{sup:2}"') qui replace `strlen' = `strlen' - 6 in `i'
			if strpos(`"`labstr'"', `"{sub:M}"') qui replace `strlen' = `strlen' - 6 in `i'
		}
		summ `strlen' if `touse' & inlist(`_USE', 1, 2, 3, 5) & `useModel'<2, meanonly
		local newsfmtlen = r(max)
		drop `strlen'
	    
		// Format as left-justified; default length equal to longest study name
		// But, niche case: in case study names are very short, look at title as well
		// If user really wants ultra-short width, they can convert to string and specify %-s format
		tokenize `"`: variable label `_LABELS''"'
		while `"`1'"'!=`""' {
			local newsfmtlen = max(`newsfmtlen', length(`"`1'"'))
			macro shift
		}
		local sfmtlen = max(`sfmtlen', `newsfmtlen')	// Sep 2023
	}
	else local sfmtlen = abs(`sfmtlen')
	format `_LABELS' %-`sfmtlen's		// left justify _LABELS
	// cap drop `use5'
	
	// Define varlist for passing to forestplot
	if "`prvlist'"!="" local fpvlist `_Prop_ES' `_Prop_LCI' `_Prop_UCI'
	else local fpvlist `_ES' `_LCI' `_UCI'

	foreach x in _LABELS _STUDY _BY _USE _WT {
		local fp`x' : copy local `x'
	}
	
	// Generate effect-size column *here*,
	//  so that it exists immediately when results-set is opened (i.e. before running -forestplot-)
	//  for user editing e.g. adding p-values etc.
	// However, *if* it is edited, -forestplot- must be called as "forestplot, nostats rcols(_EFFECT)" otherwise it will be overwritten!
	//  (or use option `nokeepvars')
	if `"`saving'"'!=`""' | `"`clear'"'!=`""' {
		tokenize `fpvlist'
		args _ES _LCI _UCI
		
		// need to peek into forestplot options to extract `dp'
		local 0 `", `forestplot'"'
		syntax [, DP(integer 2) * ]
		if `"`eform'"'!=`""' local xexp exp
		summ `_UCI' if `touse', meanonly
		local fmtx = max(1, ceil(log10(abs(`xexp'(r(max)))))) + 1 + `dp'
			
		local _EFFECT `prefix'_EFFECT
		cap drop `_EFFECT'
		qui gen str `_EFFECT' = string(`xexp'(`_ES'), `"%`fmtx'.`dp'f"') if !missing(`_ES')
		qui replace `_EFFECT' = `_EFFECT' + " " if !missing(`_EFFECT')
		qui replace `_EFFECT' = `_EFFECT' + "(" + string(`xexp'(`_LCI'), `"%`fmtx'.`dp'f"') + ", " + string(`xexp'(`_UCI'), `"%`fmtx'.`dp'f"') + ")"
		qui replace `_EFFECT' = `""' if !(`touse' & inlist(`_USE', 1, 3, 5))
		qui replace `_EFFECT' = "(Insufficient data)" if `touse' & `_USE'==2
		qui replace `_EFFECT' = "(Insufficient data for IV)" if `touse' & `_USE'==1 & (missing(`_ES') | float(`_LCI')==float(`_UCI'))	// added June 2022, in case of IV+noCC
		qui replace `_EFFECT' = "(Insufficient data)" if `touse' & inlist(`_USE', 3, 5) & missing(`_LCI')	// added March 2020, in case of "empty" subgroups

		local f = abs(fmtwidth(`"`: format `_EFFECT''"'))
		format `_EFFECT' %-`f's		// left-justify
		label variable `_EFFECT' `"`effect' (`ilevel'% CI)"'
		
		// July 2022:
		// prefix() is only applied if saving | clear (see "Rename tempvars to permanent varnames" above)
		// But -forestplot- automatically applies prefix() (if supplied) to "core" variables
		// Therefore, in this case do not explicitly send these varnames to -forestplot-
		local fpvlist
		foreach x in LABELS STUDY BY USE WT {
			local fp_`x'
		}
		local noprefixwarn noprefixwarn		// suppress "using default varlist" message in -forestplot-
	}

	
	***************
	* Forest plot *
	***************
	
	// May 2020:
	// Assume that remaining options (stored in `twowayopts' from last -syntax- call) are valid -twoway- options (if they are not, -forestplot- will exit with error!)
	// These may have been valid with -metan9- (i.e. metan v3.x and earlier) and hence must also be allowed here, for backwards compatibility.
	// However, if no graph, but `saving' or `clear' is requested, we are in -metan- v4+ territory
	// and therefore *any* remaining option is an error
	if `"`twowayopts'"'!=`""' & `"`graph'"'!=`""' & (`"`saving'"'!=`""' | `"`clear'"'!=`""') {
		local op : word 1 of `twowayopts'
		nois disp as err _n `"Option {bf:`op'} may only be supplied as a sub-option to the {bf:forestplot()} option; see {help metan:help metan}"'
		exit 198
	}
	// Otherwise: after -metan- has taken back control from -forestplot- , check these options again and print warning message if applicable.	
	
	// Finalise forestplot options
	// (do this whether or not `"`graph'"'==`""', so that options can be stored!)
	
	** Save _dta characteristic containing all the options passed to -forestplot-
	// so that they may be called automatically using "forestplot, useopts"
	// (N.B. `_USE', `_LABELS' and `_WT' should always exist)
	
	// May 2020: remove unnecessary spacing where possible
	// *BUT* watch out for options that contain text strings!  They must be left alone.
	// This involves: effect() and note(), plus `forestplot' and `twowayopts' which could contain anything
	// if "`prvlist'"=="" local proportion			// only pass `proportion' to -forestplot- if on original scale
	local useopts
	if `"`prefix'"'!=`""' local useopts prefix(`prefix')
	foreach x in USE LABELS WT {
		local lowerx = cond("`x'"=="WT", "wgt", lower("`x'"))
		if `"`fp_`x''"'!=`""' local useopts `"`useopts' `lowerx'(`fp_`x'')"'
	}
	local useopts `"`macval(useopts)' `cumulative' `influence' `denom_opt' `eform'"'
	if `"`effect'"'!=`""' local useopts `"`macval(useopts)' effect(`effect')"'
	local useopts = trim(itrim(`"`macval(useopts)' `interaction' `keepall' `overall' `subgroup' `het' `wt' `stats' `warning' `plotid'"'))

	// lcols() option [tweaked AUG 2021]
	if `"`npts'"'!=`""' local lcols_opt `_NN'
	local lcols_opt = trim(itrim(`"`lcols' `lcols_opt' `_counts1' `_counts1msd' `_counts0' `_counts0msd' `_OE' `_V'"'))
	if `"`lcols_opt'"'!=`""' {
		// July 2023: fix bug if user passes "nolcolscheck" as an undocumented option to forestplot()
		local lcolscheck2 : copy local lcolscheck
		local 0 `", `forestplot'"'
		syntax [, noLCOLSCHeck * ]
		local forestplot `"`macval(options)'"'
		if `"`lcolscheck2'"'!=`""' local lcolscheck nolcolscheck
		local useopts `"`macval(useopts)' lcols(`lcols_opt') `lcolscheck'"'	    
	}
	if `"`forestplot'"'!=`""'   local useopts `"`macval(useopts)' `forestplot'"'
	if `"`twowayopts'"'!=`""'   local useopts `"`macval(useopts)' `twowayopts'"'
	if `"`fp_BY'"'!=`""'        local useopts `"`macval(useopts)' by(`fp_BY')"'	
	if `"`allwtnames'`_VE'`rcols'"' != `""' local useopts `"`macval(useopts)' rcols(`allwtnames' `_VE' `rcols')"'	// modified Aug 2023
	if `"`rfdist'"'!=`""'       local useopts `"`macval(useopts)' rfdist(`_rfLCI' `_rfUCI')"'
	
	// August 2023: finalize fpnote option(s)
	if `derived' & "`model1'"!="dl" {
		local fptext `"Heterogeneity measures based on {&tau}{sup:2} and {&sigma}{sup:2} rather than on Q"'
	    if `"`fpnote'"'!=`""' {
			local fpnote `"`"`fpnote'."' `"`fptext'"'"'		// add full stop and new line before continuing
		}
		else local fpnote `"NOTE: `fptext'"'				// else just use text as-is
	}
	if `"`fpnote'"'!=`""' local useopts `"`macval(useopts)' note(`fpnote')"'
	
	// Store data characteristics
	// NOTE: Only relevant if `saving' / `clear' (but setup anyway; no harm done)
	// if `"`prefix'"'!=`""' char define _dta[FPUsePrefix] `prefix'
	char define _dta[FPUseOpts] `"`useopts'"'
	char define _dta[FPUseVarlist] `fpvlist'

	// If `summaryonly', limit observations to _USE==1 or 2
	if `"`summaryonly'"'!=`""' {
		qui replace `touse' = 0 if inlist(`_USE', 1, 2)
	}

	
	** Pass to forestplot
	if `"`graph'"'==`""' {
	
		cap nois forestplot `fpvlist' if `touse', `useopts' `noprefixwarn'
		
		if _rc {
			if `"`err'"'==`""' {
				if _rc==1 nois disp as err _n `"User break in {bf:forestplot}"'
				else nois disp as err _n `"Error in {bf:forestplot}"'
			}
			c_local err noerr		// tell -metan- not to also report an "error in metan_output.BuildResultsSet"
			exit _rc
		}

		return add					// add scalars returned by -forestplot-
				
		// May 2020:
		// Now check `twowayopts' again, and print warning message if applicable (see earlier explanations)
		// (N.B. `twowaynote' is set, via c_local, by -forestplot- )
		if `"`twowayopts'"'!=`""' & `"`twowaynote'"'==`""' {
			gettoken op : twowayopts, bind
			disp _n `"{error}Note: with {bf:metan} version 4 and above, the preferred syntax is for options such as {bf:`op'}"'
			disp    `"{error} to be supplied as sub-options to the {bf:forestplot()} option; see {help metan:help metan}"'
		}
	}


	** Finally, save dataset
	if `"`saving'"'!=`""' | `"`clear'"'!=`""' {
		qui keep if `touse'
		
		// Note: recall that `finalvars' is formed from `labelvars' `core' `tosave'
		keep  `finalvars' `_EFFECT' `_WT' `lrcols'
		order `finalvars' `_EFFECT' `_WT' `lrcols'
			
		if `"`createdby'"'==`""' local createdby metan
		label data `"Results set created by `createdby'"'
		qui compress
		
		if `"`saving'"'!=`""' {
			qui save `"`fname'"', `replace'
		}
	}

end



* Modified version of _prefix_saving.ado
// Previous version April 2018, for admetan v2.2
// This version June 2022, for metan v4.6 / ipdmetan v4.3

// subroutine of BuildResultsSet
program define my_prefix_saving, sclass
	cap nois syntax anything(id="file name" name=fname) [, EXISTS REPLACE * ]
	local rc = `c(rc)'
	if !`rc' {
		opts_exclusive "`exists' `replace'" `""' 184
		if `"`exists'"'!=`""' {
			cap confirm file `"`fname'"'
			if _rc {		// try adding ".dta" suffix
				confirm file `"`fname'.dta"'
			}
		}
		else if `"`replace'"'==`""' {	// use code from _prefix_saving.ado
			local ss : subinstr local fname ".dta" ""
			confirm new file `"`ss'.dta"'
		}
	}
	if `rc' {
		di as err "invalid saving() option"
		exit `rc'
	}
	sreturn local filename `"`fname'"'
	sreturn local opts_saving `"`replace' `options'"'
end



// Program to label "saved variables" with short-ish names for display on forest plots
//  and apply characteristics to store longer, explanatory names
program define ApplyLabels
	syntax [if] [in] [, TVLIST(varlist) VNAMES(namelist) XOUTVLIST(passthru) ///
		SUMMSTAT(name) CUmulative INFluence PRoportion NOPR RFDist ///
		RFLevel(cilevel) ILevel(cilevel) OLevel(cilevel) HLevel(cilevel) ]

	marksample touse
	tokenize `tvlist'
	args `vnames'
	
	if "`summstat'"=="pr" {
		char define `_ES'[Desc] "Proportion"
		char define `_seES'[Desc] "Standard error of proportion"
		char define `_LCI'[Desc] "`ilevel'% lower confidence limit for proportion"
		char define `_UCI'[Desc] "`ilevel'% upper confidence limit for proportion"		
	}
	else if "`proportion'"!="" {
		char define `_ES'[Desc] "Effect size on transformed scale"
		char define `_seES'[Desc] "Standard error of transformed effect size"
		char define `_LCI'[Desc] "`ilevel'% lower confidence limit of transformed effect size"
		char define `_UCI'[Desc] "`ilevel'% upper confidence limit of transformed effect size"
		
		if "`nopr'"=="" {
			char define `_Prop_ES'[Desc] "Proportion"
			char define `_Prop_LCI'[Desc] "`ilevel'% lower confidence limit for proportion"
			char define `_Prop_UCI'[Desc] "`ilevel'% upper confidence limit for proportion"
			char define `_Prop_LCI'[Level] `ilevel'
			char define `_Prop_UCI'[Level] `ilevel'
			char define `_Prop_LCI'[LevelPooled] `olevel'
			char define `_Prop_UCI'[LevelPooled] `olevel'
		}
	}
	else {
		char define `_ES'[Desc]  "Effect size"
		char define `_seES'[Desc] "Standard error of effect size"
		char define `_LCI'[Desc] "`ilevel'% lower confidence limit"
		char define `_UCI'[Desc] "`ilevel'% upper confidence limit"
	}
	char define `_LCI'[Level] `ilevel'
	char define `_UCI'[Level] `ilevel'
	char define `_LCI'[LevelPooled] `olevel'
	char define `_UCI'[LevelPooled] `olevel'
	
	// variable name (title) and format for "_NN" (if appropriate)
	if `"`_NN'"'!=`""' {
		if `"`: variable label `_NN''"'==`""' label variable `_NN' "No. pts"
		tempvar strlen
		qui gen `strlen' = length(string(`_NN'))
		summ `strlen' if `touse', meanonly
		local fmtlen = max(`r(max)', 3)		// min of 3, otherwise title ("No. pts") won't fit
		format `_NN' %`fmtlen'.0f			// right-justified; fixed format (for integers)

		if      `"`cumulative'"'!=`""' label variable `_NN' "Cumulative no. pts"
		else if `"`influence'"'!=`""'  label variable `_NN' "Remaining no. pts"
	}
	
	if `"`rfdist'"'!=`""' {
		label variable `_rfLCI' "rfLCI"
		label variable `_rfUCI' "rfUCI"
		char define `_rfLCI'[Desc] "`rflevel'% lower limit of predictive distribution"
		char define `_rfUCI'[Desc] "`rflevel'% upper limit of predictive distribution"
		char define `_rfLCI'[RFLevel] `rflevel'
		char define `_rfUCI'[RFLevel] `rflevel'
	}
	
	if `"`xoutvlist'"'!=`""' {
		if `"`_crit'"'!=`""' {
			label variable `_crit' "Crit. val."
			char define `_crit'[Desc] "Critical value"
			format %6.2f `_crit'
		}
		if `"`_chi2'"'!=`""' {
			label variable `_chi2' "chi2"
			char define `_chi2'[Desc] "Chi-square statistic"
			format %6.2f `_chi2'
		}
		if `"`_dfkr'"'!=`""' {
			label variable `_dfkr' "Kenward-Roger df"
			char define `_dfkr'[Desc] "Kenward-Roger degrees of freedom"
			format %6.2f `_dfkr'
		}
		if `"`_pvalue'"'!=`""' {
			label variable `_pvalue' "p"
			char define `_pvalue'[Desc] "p-value for effect size"
			format %05.3f `_pvalue'
		}
		if `"`_Q'"'!=`""' {
			label variable `_Q' "Q"
			char define `_Q'[Desc] "Cochran's Q heterogeneity statistic"
			format %6.2f `_Q'
		}
		if `"`_Qdf'"'!=`""' {
			label variable `_Qdf' "Q df"
			char define `_Qdf'[Desc] "Degrees of freedom for Cochran's Q"
			format %6.0f `_Qdf'
		}
		if `"`_Qlci'"'!=`""' {
			label variable `_Qlci' "Q LCI"
			char define `_Qlci'[Desc] "`hlevel'% lower confidence limit for Q"
			format %6.2f `_Qlci'
		}
		if `"`_Quci'"'!=`""' {
			label variable `_Quci' "Q UCI"
			char define `_Quci'[Desc] "`hlevel'% upper confidence limit for Q"
			format %6.2f `_Quci'
		}
		if `"`_H'"'!=`""' {
			label variable `_H' "H"
			char define `_H'[Desc] "H heterogeneity statistic"
			format %6.2f `_H'
		}
		if `"`_Isq'"'!=`""' {
			label variable `_Isq' "I2"
			char define `_Isq'[Desc] "I-squared heterogeneity statistic"
			format %6.1f `_Isq'
		}
		if `"`_HsqM'"'!=`""' {
			label variable `_HsqM' "HsqM"
			char define `_HsqM'[Desc] "Modified H-squared (H^2 - 1) heterogeneity statistic"
			format %6.2f `_HsqM'
		}
		if `"`_sigmasq'"'!=`""' {
			label variable `_sigmasq' "sigma2"
			char define `_sigmasq'[Desc] "Estimated average within-trial heterogeneity"
			format %6.3f `_sigmasq'
		}
		if `"`_tausq'"'!=`""' {
			label variable `_tausq' "tau2"
			char define `_tausq'[Desc] "Estimated between-trial heterogeneity"
			format %6.3f `_tausq'
		}
		if `"`_tsq_lci'"'!=`""' {
			label variable `_tsq_lci' "tau2 LCI"
			char define `_tsq_lci'[Desc] "`hlevel'% lower confidence limit for tau-squared"
			format %6.3f `_tsq_lci'
		}
		if `"`_tsq_uci'"'!=`""' {
			label variable `_tsq_uci' "tau2 UCI"
			char define `_tsq_uci'[Desc] "`hlevel'% upper confidence limit for tau-squared"
			format %6.3f `_tsq_uci'
		}
	}
	
end



* Subroutine to parse requested heterogeneity info for display on forest plot
// Sep 2020

program define ParseHetInfo, sclass

	syntax anything, OVSTATS(name) /// /* matrix containing overall/subgroup stats (required)
		COL(numlist integer min=1 max=1 >0) /// /* ... and column index for referencing matrix
		QLIST(numlist min=2 max=2 miss) /// /* Q and Qdf for current analysis (required) */
		MODEL(name) /// /* model - for whether to display additional stats or not */
		[ISQParam HETSTATS(name) /// /* matrix containing het. stats based on "parametric" Isq (optional) */
		FIRST FIRSTONLY ] /* marker that model is the first/main/primary model */

	// first, unpack `qlist'
	tokenize `qlist'
	args Q Qdf
	
	// `hetinfo' can contain [hetinfo] in any order, with optional formats
	// where [hetinfo] can be:
	// - tausq
	// - Q = Q + df
	// - p = p-value for Q + df
	// - H, Isq, HsqM are based on Q...
	//   ... *unless* option -isqparam- specified, in which case Isq is defined "parametrically" [i.e. based on tausq & sigmasq]
	
	// Clarifying note (Aug 2023): `r(hetstats)' only exists if (a) -isqparam- *or* (b) if model==sa
	// Therefore, we cannot rely on `r(hetstats)'==isqparam; have to check for isqparam explicitly
	
	local hetlab1
	local hetlab2
	tokenize `anything'
	while "`1'"!="" {
		local part1
		local part2

		// default: if not `isqparam', parse other elements only for *first* model; tausq is a special case
		if inlist("`1'", "tausq", "tau2") {
			local tausq = .
			local r = rownumb(`ovstats', "tausq")
			if !missing(`r') {
				local tausq = `ovstats'[`r', `col']
			}
			if missing(`tausq') c_local disperr_tausq = 1
			else {
				if substr(`"`2'"', 1, 1) == `"%"' local fmt : copy local 2
				else local fmt "%05.3f"
				
				// special case:  if element is tausq and *not* `isqparam',
				// it is still displayed alongside each model rather than with other heterogeneity stats (e.g. Q)
				// [Modified Aug 2023]
				local part1 = `"{&tau}{sup:2} = "' + string(`tausq', "`fmt'")
			}
		}

		// if not `isqparam', parse other elements only for *first* model
		else if `"`first'`firstonly'"'!=`""' | (`"`isqparam'"'!=`""' & !inlist("`model'", "iv", "mh", "peto", "mu")) {
			if lower("`1'")=="q" {
				if substr(`"`2'"', 1, 1) == `"%"' local fmt : copy local 2
				else local fmt "%5.2f"
				
				// Modified Aug 2023
				if `"`firstonly'"'!=`""' local part_opt part1
				else local part_opt part2
				local `part_opt' = `"Q = "' + string(`Q', "`fmt'") + `" on `=`Qdf'' df"'			
			}
			else if inlist("`1'", "p", "pv", "pva", "pval", "pvalu", "pvalue") {
				local Qpval = chi2tail(`Qdf', `Q')
				if substr(`"`2'"', 1, 1) == `"%"' local fmt : copy local 2
				else local fmt "%05.3f"
				confirm format `fmt'
				local yes = regexm(strtrim("`fmt'"), "^%[0-9]+.([0-9]+)[efg]c?$")
				if !`yes' {
					nois disp as err `"'`fmt'' found where format expected"'
					exit 7
				}
				local dp = regexs(1)
				
				// Modified Aug 2023
				if `"`firstonly'"'!=`""' local part_opt part1
				else local part_opt part2
				if -log10(`Qpval') > `dp' {
					local `part_opt' = `"p < "' + string(1e-`dp', "`fmt'")
				}
				else local `part_opt' = `"p = "' + string(`Qpval', "`fmt'")
			}
			else if inlist("`1'", "h", "H") {
				if `"`hetstats'"'!=`""' {
					// Modified July 2024 to avoid errors with Stata 15 and older
					// "matrix operators that return matrices not allowed in this context
					local r = rownumb(`hetstats', "H")
					local H = `hetstats'[`r', `col']
				}
				else local H = sqrt(`Q' / `Qdf')
				
				if substr(`"`2'"', 1, 1) == `"%"' local fmt : copy local 2
				else local fmt "%5.2f"
				
				if `"`firstonly'"'!=`""' | (`"`isqparam'"'!=`""' & !inlist("`model'", "iv", "mh", "peto", "mu")) {
					 local part_opt part1		// Modified Aug 2023
				}
				else if `"`isqparam'"'==`""' local part_opt part2
				if `"`part_opt'"'!=`""' {
					local `part_opt' = `"H = "' + string(`H', "`fmt'")
					if `"`isqparam'"'!=`""' c_local derived = 1		// Added Aug 2023
				}
			}
			else if inlist(lower("`1'"), "isq", "i2") {
				if "`hetstats'"!="" {
					// Modified July 2024 to avoid errors with Stata 15 and older
					// "matrix operators that return matrices not allowed in this context
					local r = rownumb(`hetstats', "Isq")
					local Isq = `hetstats'[`r', `col']
				}
				else local Isq = max(0, 100*(`Q' - `Qdf') / `Q')
				if substr(`"`2'"', 1, 1) == `"%"' local fmt : copy local 2
				else local fmt "%5.1f"
		
				if `"`firstonly'"'!=`""' | (`"`isqparam'"'!=`""' & !inlist("`model'", "iv", "mh", "peto", "mu")) {
					 local part_opt part1		// Modified Aug 2023
				}
				else if `"`isqparam'"'==`""' local part_opt part2
				if `"`part_opt'"'!=`""' {
					local `part_opt' = `"I{sup:2} = "' + string(`Isq', "`fmt'") + `"%"'
					if `"`isqparam'"'!=`""' c_local derived = 1		// Added Aug 2023
				}
			}
			else if inlist(lower("`1'"), "h2m", "hsqm") {
				if "`hetstats'"!="" {
					// Modified July 2024 to avoid errors with Stata 15 and older
					// "matrix operators that return matrices not allowed in this context
					local r = rownumb(`hetstats', "HsqM")				
					local HsqM = `hetstats'[`r', `col']
				}
				else local HsqM = `Isq' / (100 - `Isq')
				if substr(`"`2'"', 1, 1) == `"%"' local fmt : copy local 2
				else local fmt "%5.2f"

				if `"`firstonly'"'!=`""' | (`"`isqparam'"'!=`""' & !inlist("`model'", "iv", "mh", "peto", "mu")) {
					 local part_opt part1		// Modified Aug 2023
				}
				else if `"`isqparam'"'==`""' local part_opt part2
				if `"`part_opt'"'!=`""' {
					local `part_opt' = `"H{sup:2}{sub:M} = "' + string(`HsqM', "`fmt'")
					if `"`isqparam'"'!=`""' c_local derived = 1		// Added Aug 2023
				}
			}
			else if `"`1'"'!=`""' {
				nois disp as err `"Error in option {bf:hetinfo()}: element {bf:`1'} is invalid"'
				exit 198
			}
		}		// end else if !(`col' > 1 & `"`isqparam'"'==`""')
		
		/* Special case [TO DO/REVISIT JAN 2024]
		If `"`part1'"'!=`""' & `"`part2'"'!=`""' but DL is the only random-effects model
		then concatenate `part1' and `part2' together, and return as `part2'
		*/
		// nois disp `"part1: `part1'"'
		// nois disp `"part2: `part2'"'
		
		if `"`part1'"'!=`""' {
			if `"`hetlab1'"'==`""' local hetlab1 : copy local part1
			else local hetlab1 `"`hetlab1', `part1'"'
		}
		if `"`part2'"'!=`""' {
			if `"`hetlab2'"'==`""' local hetlab2 : copy local part2
			else local hetlab2 `"`hetlab2', `part2'"'
		}		
		
		if substr(`"`2'"', 1, 1) == `"%"' macro shift 2
		else macro shift
		
	}	// end while "`1'"!=""
	
	sreturn clear
	sreturn local hetlab1 `"`hetlab1'"'
	// sreturn local part_tausq `"`part_tausq'"'	// only in special case; see above
	sreturn local hetlab2 `"`hetlab2'"'		// only in special case; see above [added Aug2023]
	
end
