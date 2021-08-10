* ipdmetan.ado
* Individual Patient Data (IPD) meta-analysis of main effects or interactions

* Originally written by David Fisher, July 2008

* November 2011/February 2012
* Major updates:
// Screen output coded within -ipdmetan- rather than using -metan- external command
//   to enable specific results to be presented

* September 2012
* Aggregate data and IPD able to be pooled in same meta-analysis

* November 2012
* Forest-plot output coded within -ipdmetan- using code modified from metan v9 (SJ9-2: sbe24_3)
//  Acknowledgements and thanks to the authors of this code.

* November 2012
//  "over()" functionality added

* January 2013
//  Changed to "prefix" -style syntax, following discussion with Patrick Royston

* March 2013
* Functionality of -ipdmetan- and -ipdover- completely separated.
//    -ipdmetan- now ONLY does pooled meta-analysis
//  Anything else, e.g. non trial-level subgroups, over(), general forest plots etc., must be done via -ipdover-
//    and will not use pooling, inverse-variance weights, etc.
//    (although I-V weights still used in forest plots as a visual aid)

* June 2013
* Discussion with Ross Harris
//  Improved ability to analyse aggregate data alone using separate program -admetan-
//     together with some rearrangement of syntax, options & naming conventions

* September 2013
* Presented at UK Stata Users Meeting
//  Reworked the plotid() option as recommended by Vince Wiggins

* version 1.0  David Fisher  31jan2014
* First released on SSC

* version 1.01  David Fisher  07feb2014
* Reason: fixed bug - Mata main routine contained mm_root, so failed at compile even if mm_root wasn't actually called/needed

* version 1.02  David Fisher  10feb2014
* Reason:
//  - fixed bug with _rsample
//  - fixed bug causing syntax errors with "ipdmetan : svy : command" syntax

* version 1.03  David Fisher  02apr2014
* Reason:
//  - return F statistic for subgroups
//  - correct error in `touse' when passed from admetan
//  - correct error in behaviour of stacklabel under certain conditions (line 2307)

* version 1.04  David Fisher  09apr2014
* Reason:
//  - fixed bug with DerSimonian & Laird random-effects
//  - fixed bug which failed to drop tempvar containing held estimates
//  - fixed bug in output table title when using ipdover
//  - _rsample now returned for admetan too
//  - added ovwt/sgwt options

* version 1.05  David Fisher 05jun2014
* Submitted to Stata Journal
//  - added Kontopantelis's bootstrap DL method and Isq sensitivity analysis
//      and Rukhin's Bayesian tausq estimators
//  - revisited syntax for Hartung-Knapp t-based variance estimator (and removed "t" option)
//  - changes to names of some saved results, e.g. mu_hat/se_mu_hat are now eff/se_eff
//      also "study" is preferred to "trial" throughout, except for ipdover
//  - improved parsing of prefix/mixed-effects models (i.e. those containing one or more colons)
//      also improved management of non-convergence and user breaking

* version 1.06  David Fisher 23jul2014
* Reason:
//  - Corrected AD filename bug (line 437)
//  - ipdover now uses subgroup sample size as default weight, rather than inverse-variance
//      (as suggested by Phil Jones, and as seems to be standard practice in literature)

* version 1.07  David Fisher, 29jun2015
* Major update to coincide with publication of Stata Journal article
//  - Corrected "Cochrane Q" to "Cochran Q"
//  - Improved behaviour of "nohet" and "notab"
//  - Added cumulative MA option(cf metacum) (done Dec 2014)
//  - Added Kenward-Roger variance estimator (using expected information, not observed) (done Feb 2015)
//  - Generally deals better with sitations where only one estimate (or zero estimates for specific subgroups)
//  - Work-around for bug in _prefix_command which fails with "if varname="label":lblname" syntax (done May 2015)
//  - Corrected implementation of empirical Bayes random-effects model (done June 2015)
//  - Fixed bugs in forestplot.ado:
//      lcols/rcols varnames without varlabels (the "must specify at least one of target or maxwidth" error)
//      use of char(160) to represent non-breaking spaces (the "dagger" error)

*! version 2.0  David Fisher  11may2017
* Major update to extend functionality beyond estimation commands; now has most of the functionality of -metan-
//  - Reworked so that ipdmetan.ado does command processing and looping, and admetan.ado does RE estimation (including -metan- functionality)
//  - Hence, ipdover calls ipdmetan (but never admetan); ipdmetan calls admetan (if not called by ipdover); admetan can be run alone.
//      Any of the three may call forestplot, which of course can also be run alone.
//  - See admetan.ado for further notes


program define ipdmetan, rclass

	version 11.0
	local version : di "version " string(_caller()) ":"
	* NOTE: mata requires v9.x
	* factor variable syntax requires 11.0
	
	// Test for which command structure is being used
	// "generic" effect measure / Syntax 1  ==> ipdmetan [exp_list] .... : [command] [if] [in] ...
	// (calculations based on an estimation model fitted within each study)
	
	// "specific" effect measure / Syntax 2 ==> ipdmetan varlist [if] [in] ...  **no colon**
	// (raw event counts or means (SDs) within each study using some variation on -collapse-)
	
	cap _on_colon_parse `0'
	local rc = _rc
	if !_rc {
		local before `"`s(before)'"'
		local 0      `"`s(before)'"'
		local after  `"`s(after)'"'
	}
	
	// Quick parse to extract `eform', `coef', `level' for _prefix_command
	// and other options needed in early part of the code
	syntax [anything(name=exp_list equalok)] [if] [in] [fw aw pw iw] , [ ///
		Level(passthru) COEF      /// needed for _prefix_command
		STUDY(string) BY(string)  ///
		SORTBY(string)            /// optional sorting varlist
		IPDOVER(string)           /// options passed through from ipdover (see ipdover.ado & help file)
		AD(string)                /// optionally incorporate aggregate-data (mainly used within admetan.ado, but briefly needed here too)
		FORESTplot(string asis)   /// options to pass through to forestplot
		* ]                       // remaining options will be parsed later		
	
	local bif `"`if'"'				// "before" if
	local bin `"`in'"'				// "before" in
	if `"`weight'"' != `""' local bweight `"[`weight'`exp']"'
	local options_ipdm `"`macval(options)'"'

	if !`rc' {
	
		**************************
		* "Estimation" structure *
		**************************
		
		_get_eformopts, soptions eformopts(`options') allowed(__all__)
		local efopt = cond(`"`s(opt)'"'=="",`"`s(eform)'"',`"`s(opt)'"')

		
		* PROBLEM: Main ipdmetan loop needs to add "if `touse' & `StudyID'==`i'" to the command syntax in an appropriate place
	
		* POTENTIAL ISSUES:
		// (a) prefix commands, e.g. svy; these can mostly be left alone, but strip off to identify the actual *estimation* command
		// (b) multilevel models; to be compatible with ipdmetan these can only have one if/in condition.
		//      so use _parse expand to extract if/in conditions, otherwise continue as normal
		// (c) _prefix_command does not like the syntax  if varname=="[label]":[lblname]  so will need to remove `if' before using it.
		
		* STRATEGY:
		// 1. Use "_parse expand" to isolate fe_equation
		// 2. Strip off `if' (and `in', `weights' and `options', for simplicity) and save separately
		// 3. Run _prefix_command repeatedly to separate off any prefixes and to isolate estimation command
		// 5. Re-assemble command and continue (any remaining syntax errors will be found when the command is first run)
		
		* Use "_parse expand" to isolate fe_equation, and to identify first `if' and `in'
		
		// Updated 24th March 2017 so that `if', `in', `wt', `opts' are extracted from `stub1' *and* `stub2'
		// Assume `if', `in', `wt', `opts' are *global* in terms of ipdmetan
		// This in turn implies that multiple `if', `in' or `wt' should not be allowed; therefore test for this here.
		// We can't wait until running the command itself, since the options will have been shuffled around by then, possibly obscuring the error.
		_parse expand stub1 stub2 : after, gweight
		forvalues i=1/`stub1_n' {
			local 0 `stub1_`i''
			syntax [anything] [if] [in] [fw aw pw iw] [, *]

			// code fragment taken from _mixed_parseifin (with modifications)
			if `"`if'"' != `""' {
				if `"`cmdif'"' != `""' {
					di as error "multiple {bf:if} conditions not allowed"
					exit 198
				}
				local cmdif `"`if'"'
			}
			if `"`in'"' != `""' {
				if `"`cmdin'"' != `""' {
					di as error "multiple {bf:in} ranges not allowed"
					exit 198
				}
				local cmdin `"`in'"'
			}
			
			local stubopts
			if `"`weight'"' != `""' local stubopts `"[`weight'`exp']"'
			if `"`options'"' != `""' local stubopts `"`stubopts', `macval(options)'"'	// we can put these two together as they will always appear adjacent
			
			if `i'==1 {
				local command `"`anything'"'
				local cmdopts `"`stubopts'"'
			}
			else local cmdrest `"`macval(cmdrest)' || (`anything' `stubopts')"'
		}
		
		// "Global" if/in conditions
		// code fragment taken from _mixed_parseifin (with modifications)
		if `"`stub2_if'"' != `""' {
			if `"`cmdif'"' != `""' {
				di as error "multiple {bf:if} conditions not allowed"
				exit 198
			}
			local cmdif `"`stub2_if'"'
		}
		if `"`stub2_in'"' != `""' {
			if `"`cmdin'"' != `""' {
				di as error "multiple {bf:in} ranges not allowed"
				exit 198
			}
			local cmdin `"`stub2_in'"'
		}
		local glob_opts `"`stub2_wt', `macval(stub2_op)'"'									// we can put these two (weights and options)
		local glob_opts = cond(trim(`"`glob_opts'"')==`","', `""', trim(`"`glob_opts'"'))	//   together as they will always appear adjacent...
		local checkopts `"`cmdopts' `macval(stub2_op)'"'		// ... but we also need the options separately, for the final check using _prefix_command
		
		* Prefixes should be the only instances of colons outside quotes now
		//  so we can run _prefix_command repeatedly to identify the estimation command
		//  (i.e. the command following the last colon)
		local pcommand
		local before2 "before"
		while `"`before2'"'!=`""' {
			cap _on_colon_parse `command'
			if !_rc {							// if colon found
				local before2 `"`s(before)'"' 
				local after2 `"`s(after)'"' 
				`version' _prefix_command ipdmetan, `level' `efopt' `coef' : `before2'
				local cmdname `"`s(cmdname)'"'						// current prefix command
				local pcommand `"`s(command)' : `pcommand'"'		// all prefix commands
				local command `"`after2'"'							// estimation command
			}
			else continue, break
		}
		
		* Final parse of estimation command (and global options) only
		`version' _prefix_command ipdmetan, `level' `efopt' `coef' : `command' `checkopts'
		local cmdname	`"`s(cmdname)'"'
		local cmdargs	`"`s(anything)'"'
		local level = cond(`"`s(level)'"'!=`""', `"`s(level)'"', `"`c(level)'"')
		local eform		`"`s(efopt)'"'
		
		* Re-assemble full command line and return
		// (do this now to allow for user error-checking with "return list")
		local finalcmd `"`pcommand' `cmdname' `cmdargs' `cmdif' `cmdin' `cmdopts' `cmdrest' `glob_opts'"'
		local finalcmd = trim(itrim(`"`finalcmd'"'))
		return local command `"`finalcmd'"'
		return local cmdname `"`cmdname'"'
		
		local cmdstruc "generic"		// "generic" effect measure, i.e. Syntax 1; "command"-based syntax (see help file)
		local 0 `"`before'"'
	}
	local log = cond(`"`coef'"'!=`""', `"log"', `"`log'"')		// `coef' is a synonym for `log'

	// Continue testing for correct command structure formatting
	local rc = 0
	cap confirm var `exp_list'
	if "`cmdstruc'" == "generic" {
		local rc = cond(_rc, 0, 101)			// give error if _rc is ZERO, i.e. if `exp_list' is a varlist
		cap {
			assert trim(itrim(`"`bif'`bin'"'))==`""'	// [if] [in] cannot be specified before the colon under this structure
			assert trim(itrim(`"`bweight'"'))==`""'		// ...and nor can weights
		}
		local rc = cond(`rc', `rc', _rc)
	}
	else {
		local cmdstruc "specific"				// "specific" effect measure, i.e. Syntax 2; "collapse"-based syntax (see help file)
		local rc = _rc							// give error if _rc is NONZERO, i.e. if `exp_list' is *not* a valid varlist
		local invlist : copy local exp_list
		
		local cmdif `"`bif'"'
		local cmdin `"`bin'"'
		local cmdwt `"`bweight'"'
	}
	
	if `rc' {
		local cmdtxt = cond(`"`ipdover'"'!=`""', "ipdover", "ipdmetan")
		nois disp as err `"Invalid {bf:`cmdtxt'} syntax.  One and only one of the following syntaxes is valid:"'
		nois disp as err `"{bf:1.} "' as text `"{bf:`cmdtxt'} ... : {it:command} ... [{it:if}] [{it:in}] ..."'
		nois disp as err `"or {bf:2.} "' as text `"{bf:`cmdtxt'} {it:varlist} [{it:if}] [{it:in}], ... "'
		
		if "`cmdstruc'" == "generic" {
			disp as err `"Syntax {bf:1.} detected, "' _c
			if `rc'==101 disp as err `"so {it:varlist} cannot be given before the colon."'
			else disp as err `"so [{it:if}] [{it:in}] cannot be given before the colon."'
		}
		else if "`cmdstruc'" == "specific" {
			nois disp as err `"Syntax {bf:2.} detected, "' _c
			if trim(itrim(`"`exp_list'"'))==`""' disp as err `"but {it:varlist} has not been supplied."'
			else nois disp as err `"but one or more elements of {it:varlist} were not found."'
		}
		exit `rc'
	}
		
	
	

	************************************
	* Setup of data currenly in memory * 
	************************************

	local 0 `"`invlist' `cmdif' `cmdin'"'
	syntax [varlist(numeric max=6 default=none)] [if] [in]
	marksample touse
		
	// Quickly extract `study' varname from option
	local studyopt `study'							// full, original option for sending to admetan.ado
	local 0 `study'
	syntax varlist [, Missing]
	local smissing `missing'
	local study `varlist'
	cap confirm var `study'
	if _rc & `"`ipdover'"'==`""' {
		nois disp as err `"{bf:study()} is required with {bf:ipdmetan}"'
		exit 198
	}

	local overlen: word count `study'
	if `overlen'>1 & `"`ipdover'"'==`""' {
		disp as err "{bf:study()} should only contain a single variable name"
		exit 198	
	}
	
	qui count if `touse'
	if !r(N) {
		if `"`ipdover'"'==`""' local errtext `"in {bf:study()}"'
		nois disp as err "no valid observations `errtext'"
		exit 2000
	}
	
	
	// Quickly extract `by' varname from option (N.B. this will be parsed properly later)
	local by_rc = 0
	if `"`by'"'!=`""' {
		local byopt `by'						// full, original option for sending to admetan.ado
		local 0 `by'
		syntax name(name=by) [, Missing]		// only a single (var)name is allowed
		cap confirm var `by'
		if _rc {
			if `"`ad'"'==`""' {															// `by' may only NOT exist in memory
				nois disp as err `"variable {bf:`by'} not found in option {bf:by()}"'	// if an external aggregate-data file is specified.
				exit 111																// (and even then, it must exist there! - tested for later)
			}
		}
		local by_rc = _rc
		local bymissing = cond(!_rc, "`missing'", "")
	}

	// Process `sortby' option
	if `"`sortby'"'!=`""' {
		if `"`ipdover'"'!=`""' {
			nois disp as err `"{bf:sortby()} may not be used with {bf:ipdover}"'
			exit 198
		}
		else {
			cap confirm var `sortby'
			if _rc & `"`sortby'"'!="_n" {
				if `"`ad'"'==`""' {
					nois disp as err `"variable {bf:`sortby'} not found in option {bf:sortby()}"'
					exit _rc
				}
				local ad `"`ad' adsortby(`sortby')"'	// if not found in IPD, add to ad() option to check in AD data
				local sortby							// don't need anymore in -ipdmetan-
			}
		}
	}
	
	
	** Now, if one observation per study, pass directly to -admetan-
	// (with "`ipdmetan'"=="ipdmetan", i.e. simple on/off)
	if `"`ipdover'"'==`""' {
		qui tab `study' if `touse', `smissing'
		if r(r)==r(N) {
			local sortby = cond("`sortby'"=="_n", "", "`sortby'")
			
			if `"`ad'"'!=`""' preserve				// preserve in case something goes wrong in ProcessAD
			cap nois admetan `invlist' if `touse', ipdmetan study(`studyopt') by(`byopt') ///
				sortby(`sortby') ad(`ad') forestplot(`forestplot') `options_ipdm'

			if _rc {
				if `"`err'"'==`""' {
					if _rc==1 nois disp as err `"User break in {bf:admetan}"'
					else nois disp as err `"Error in {bf:admetan}"'
				}
				exit _rc
			}
						
			return add
			exit
		}
		
		// If not sending directly to -admetan-, default sorting is `study'
		local sortby = cond("`sortby'"=="_n", "", cond("`sortby'"!="", "`sortby'", "`study'"))
	}

	
	** If necessary, parse forestplot options to extract those relevant to ipdmetan
	// N.B. Certain options may be supplied EITHER to ipdmetan directly, OR as sub-options to forestplot()
	//      (e.g. if relevant whether or not a forestplot is requested).

	* First, process -eform- for ipdmetan
	cap nois MyGetEFormOpts `cmdname', `options_ipdm'
	if _rc {
		if _rc==1 nois disp as err `"User break in {bf:ipdmetan.MyGetEFormOpts}"'
		else nois disp as err `"Error in {bf:ipdmetan.MyGetEFormOpts}"'
		exit _rc
	}
	local eform = cond(`"`r(eform)'"'!=`""', "eform", "")	// convert to simple on/off option
	local log          `"`r(log)'"'
	local summstat     `"`r(summstat)'"'
	local seffect      `"`r(effect)'"'		// N.B. `seffect' contains automatic effect text from -eform-; `effect' contains user-specified text
	local options_ipdm `"`r(options)'"'

	
	* "Forestplot options" are prioritised over "ipdmetan options" in the event of a clash.
	// These options are:
	// nograph, nohet, nooverall, nosubgroup, nowarning, nowt
	// effect, ovstat, lcols, rcols, plotid, ovwt, sgwt, sgweight
	// cumulative, efficacy, influence, interaction
	// counts, group1, group2 (for compatibility with metan.ado)
	// rfdist, rflevel (for compatibility with metan.ado)	

	// For estimation commands, -eform- options (plus extra stuff parsed by MyGetEformOpts e.g. `rr', `rd', `md', `smd', `wmd', `log')
	//   behave the same way.
	// However, for "raw data", these options may only "clash" (i.e. be subject to prioritisation) in terms of whether on/off,
	//   not in terms of the actual statistic used (that would be a "true" clash, resulting in an exit with error).
	
	// N.B. At this stage we also want to isolate the effect MEASURE, to be sent to admetan.ado in the summstat() option.
	// (METHODs of analysis are not dealt with here, but in admetan.ado.)
	
	if trim(`"`forestplot'"') != `""' {

		cap nois ParseFPlotOpts, cmdname(`cmdname') `eform' `log' mainprog(ipdmetan) summstat(`summstat') seffect(`seffect') ///
			mainopts(`options_ipdm') fplotopts(`forestplot')
			
		if _rc {
			if _rc==1 nois disp as err `"User break in {bf:ipdmetan.ParseFPlotOpts}"'
			else nois disp as err `"Error in {bf:ipdmetan.ParseFPlotOpts}"'
			c_local err "noerr"		// tell ipdover not to also report an "error in {bf:ipdmetan}"
			exit _rc
		}
		
		local eform    `"`r(eform)'"'
		local log      `"`r(log)'"'
		local summstat `"`r(summstat)'"'
		local seffect  `"`r(seffect)'"'		// N.B. `seffect' contains automatic effect text from -eform-; `effect' contains user-specified text
		
		local options_ipdm `"`r(parsedopts)' `r(mainopts)'"'	// options as listed above, plus other options supplied directly to ipdmetan
		local fplotopts    `"`r(fplotopts)'"'					// other options supplied as sub-options to forestplot()		
	}
	
	// Sort out whether parsed options go into `fplotopts' or not
	// ...and also parse any options that will be needed in ipdmetan.ado but have not yet been parsed
	local 0 `", `options_ipdm'"'
	syntax [, ///	
		/// General options
		CItype(string)            /// CIs for individual studies (NOT for pooled results)
		EFFect(string)            /// user-defined effect label
		SAVING(string)            /// specify filename in which to save results set
		noRSample                 /// don't leave behind "_rsample" [analog of e(sample), used here as ipdmetan.ado is not e-class]
		SGWt SGWEIGHT             /// if `by', weight by subgroup rather than overall
		noOVerall noSUbgroup      /// suppress reporting of by-sugbroup or overall pooled effects
		/// Options relevant to particular subroutines
		INTERaction noTOTal       /// mainly relevant to ProcessCommand but also needed beforehand
		MEssages                  /// only relevant to ProcessCommand
		POOLvar(string)           /// mainly relevant to ProcessCommand but also needed beforehand (N.B. "string" as may include equation names)
		STrata(varlist) noSHow    /// only relevant to LogRankHR
		Over(string)              /// for error-trapping only
		/// Options mostly relevant to forestplot, but also needed beforehand
		LCols(string asis) RCols(string asis) PLOTID(string) ///
		noGRaph noHET noWT ///
		COunts GROUP1(passthru) GROUP2(passthru) OEV ///
		/// Undocumented options
		ZTOL(passthru)            /// ztol = tolerance for z-score (abs(ES/seES))
		* ]                       // Remaining options will be passed through to admetan.ado

	local sgwt = cond("`sgweight'"!="", "sgwt", "`sgwt'")		// sgweight is a synonym (for compatibility with metan.ado)
	local options_ipdm = trim(`"`macval(options)' `counts' `group1' `group2' `sgwt' `oev'"')

	
	// if ipdover, return `wt' separately; otherwise, add to `fplotopts'
	if "`ipdover'"!="" cap return local wt `wt'
	else local fplotopts = trim(`"`macval(fplotopts)' `wt'"')		// add straight to fplotopts; not needed any more by ipdmetan

	
	** Option compatibility tests relevant to -ipdover- and "generic" vs "specific" effect measure
	// (N.B. leave more specific MA-related compatibility tests to admetan.ado)
	if `"`exp_list'"'!=`""' & `"`interaction'"'!=`""' {
		nois disp as err `"{it:exp_list} and {bf:interaction} may not be combined"'
		exit 184
	}
	if `"`exp_list'"'!=`""' & `"`poolvar'"'!=`""' {
		nois disp as err `"{it:exp_list} and {bf:poolvar()} may not be combined"'
		exit 184
	}
	if `"`command'"'!=`""' & `"`total'"'!=`""' {
		if `"`exp_list'"'==`""' & `"`poolvar'"'==`""' {
			nois disp as err `"Cannot specify {bf:nototal} without one of {it:exp_list} or {bf:poolvar()}"'
			exit 198
		}
		if `"`ipdover'"'!=`""' local overall "nooverall"
	}
	if `"`over'"'!=`""' {
		nois disp as err `"Cannot specify {bf:over()} with {bf:ipdmetan}; please use {bf:ipdover} instead"'
		exit 198
	}
	if `"`cmdstruc'"'==`"generic"' {
		local 0 `", `options_ipdm'"'
		syntax [, MH PETO LOGRank COHen HEDges GLAss noSTANdard * ]		// N.B. `counts', `group1' and `group2' have already been parsed
		if trim(`"`mh'`peto'`logrank'`cohen'`hedges'`glass'`standard'`counts'`group1'`group2'"') != `""' {
			local erropt : word 1 of `mh' `peto' `logrank' `cohen' `hedges' `glass' `standard' `counts'
			local erropt = cond("`erropt'"=="" & "`group1'"!="", "group1", "`erropt'")
			local erropt = cond("`erropt'"=="" & "`group2'"!="", "group2", "`erropt'")
			nois disp as err `"option {bf:`erropt'} is incompatible with {it:command}-based syntax (Syntax 1)"'
			exit 198
		}
		local options_ipdm `"`macval(options)'"'
	}

	// Check for options supplied to ipdover which should only be supplied to the ad() option of ipdmetan
	if `"`ipdover'"'!=`""' {
		local 0 `", `options_ipdm'"'
		syntax [, NPTS(string) BYAD VARS(string) * ]
		if trim(`"`ad'`npts'`byad'`vars'"') != `""' {
			local erropt = cond("`ad'"!="", "ad()", "")
			local erropt = cond("`erropt'"=="", "`: word 1 of `npts' `byad' `vars''", "`erropt'")
			nois disp as err `"option {bf:`erropt'} is an invalid option with {bf:ipdover}"'
			exit 198
		}
		local options_ipdm `"`macval(options)'"'
	}

	
	* Parse `plotid'
	// (but keep original contents to pass to forestplot for later re-parsing)
	//  - allow "_LEVEL", "_BY", "_OVER" with ipdover (because data manipulation means can't specify a single current varname)
	//  - else allow "_BYAD" in case of byad, but otherwise must be a variable in memory (in either IPD or AD, if relevant)
	local 0 `plotid'
	syntax [name(name=plname)] [, *]
	local plotidopts = cond(`"`options'"'==`""', `""', `", `options'"')
	
	if `"`ipdover'"'!=`""' {
		if "`plname'" != "" {
			if !inlist("`plname'", "_BY", "_OVER", "_LEVEL", "_n") {
				nois disp as err `"{bf:plotid()} with {bf:ipdover} must contain one of {bf:_BY}, {bf:_OVER}, {bf:_LEVEL} or {bf:_n}"'
				exit 198
			}
			if "`plname'"=="_BY" & "`by'"=="" {
				nois disp as err `"Note: {bf:plotid(_BY)} cannot be specified without {bf:by()} and will be ignored"'
				local plotid		// remove entire `plotid' option
			}
			local plname		// ...but in any case, don't need plname further in -ipdmetan-
		}
	}
	else {
		if "`plname'"=="_BYAD" | ("`plname'"=="`by'" & "`by'"!="" & `by_rc') {		// either BYAD or `by' in AD only
			if "`plname'"=="_BYAD" & "`ad'"=="" {
				nois disp as err `"Note: {bf:plotid(_BYAD)} cannot be specified without aggregate data and will be ignored"'
				local plotid
			}
			local plname		// i.e. don't use further in -ipdmetan- (but plotid() will be used in -admetan-)
		}
		else if "`plname'"=="`by'" & "`by'"!="" & !`by_rc' local plotid `"_BY`plotidopts'"'
		else if "`plname'"=="`study'" local plotid `"_STUDY`plotidopts'"'
		else if "`plname'"!="" {
			cap confirm var `plname'				// if `plname' contains a variable name other than _STUDY/_BY
			if _rc {								// check to see if it is in current memory
				if "`ad'"=="" {
					nois disp as err `"variable {bf:`plname'} not found in option {bf:plotid()}"'
					exit _rc
				}
				local ad `"`ad' adplotvar(`plname')"'		// if not found in IPD, add to ad() option to check in AD data
				local plname								// don't need anymore in -ipdmetan-
			}
			else {
				local cclist `"(firstnm) `plname'"'		// for -collapse-
				
				cap confirm numeric var `plname'
				if !_rc local coldnames `"`plname'"'	// for LogRankHR, if numeric...
				else local csoldnames `"`plname'"'		// ...else if string
			}
		}
	}
	if `"`plotid'"'!=`""' {																		// `plotid' not needed anymore in -ipdmetan- ...
		if `"`ipdover'"'==`""' local options_ipdm `"`macval(options_ipdm)' plotid(`plotid')"'	// if passing to `admetan', add to `options_ipdm'...
		else                   local fplotopts       `"`macval(fplotopts)' plotid(`plotid')"'	// ... else, add to `fplotopts'
	}
	
	
	* Sort out subgroup identifier (BY) and labels
	// (N.B. `by' might only exist in an external (aggregate) dataset)
	local bystr=0
	tempvar bytemp
	if `"`by'"'!=`""' & !`by_rc' {				// if `by' is present in the current dataset -- this much has already been established
		local byvarlab : variable label `by'
		if `"`byvarlab'"'==`""' local byvarlab `"`by'"'
		
		if `"`bymissing'"'==`""' {
			markout `touse' `by', strok		// ignore observations with missing "by" if appropriate
			qui count if `touse'
			if !r(N) {
				nois disp as err `"No non-missing observations in variable {bf:`by'} (in option {bf:by()})"'
				nois disp as err `"Please use the {bf:missing} suboption to {bf:by()} if appropriate"'
				exit 2000
			}
		}
	
		// Now see if `by' is numeric or string
		tempname bylab
		cap confirm numeric var `by'
		assert inlist(_rc, 0, 7)
		local bystr = _rc	// var exists but is string, not numeric (save in local so that -capture- can be used again)

		if !`bystr' {		// if numeric
			tempname bymat
			local matrowopt `"matrow(`bymat')"'
		}
			
		cap tab `by' if `touse', `bymissing' `matrowopt'
			if _rc {
			nois disp as err `"variable {bf:`by'} in option {bf:by()} has too many levels"'
			exit 134
		}

		if `bystr' {
			qui encode `by' if `touse', gen(`bytemp') lab(`bylab')			// save label
			local by_in_IPD `bytemp'										// refer to new variable
		}
		else {
			cap assert `by'==round(`by')
			if _rc {
				nois disp as err `"variable {bf:`by'} in option {bf:by()} must be integer-valued or string"'
				exit 198
			}
			
			// form value label from bymat
			forvalues i=1/`r(r)' {
				local byi = `bymat'[`i', 1]
				if `byi'!=. {
					local labname : label (`by') `byi'
					label define `bylab' `byi' "`labname'", add
				}
			}
			local by_in_IPD `by'		// `by_in_IPD' is a marker of `by' existing in the data currently in memory
		}
			
		// save "by" value label
		cap lab list `bylab'
		if !_rc {
			tempfile bylabfile
			qui label save `bylab' using `bylabfile'
		}
	}		// end if `"`by'"'!=`""'

	else {
		// Unless ad(), test for `subgroup' without `by'
		if `"`subgroup'"'!=`""' & `"`ad'"'==`""' {
			nois disp as err `"Note: {bf:nosubgroup} cannot be specified without {bf:by()} and will be ignored"'
			local subgroup
		}
	}
		
	// declare a tempvar name for each element in `study', in case any string vars need to be decoded
	forvalues h=1/`overlen' {
		tempvar tv`h'
		local tvlist `"`tvlist' `tv`h''"'		// tvlist = "temp varlist"
		tempname vallab`h'
		local tnlist `"`tnlist' `vallab`h''"'	// tnlist = "temp namelist" (to store value labels)
	}

	// If "`ipdover'"=="", `StudyID' is an ordinal identifier based on requested sort order,
	//   and will be needed throughout the code (regardless of `cmdstruc')
	// Otherwise, it will be used within ProcessCommand to identify over() groups (and simplify coding)
	//   but is not strictly necessary and can be dropped as soon as `ipdfile' is loaded.
	// Not needed for "`cmdstruc'"=="specific" at all.
	if `"`ipdover'"'==`""' {
		tempvar StudyID
		tempfile ipdfile labfile
	}
	else {
		local 0 `", `ipdover'"'
		syntax [, IPDFILE(string asis) LABFILE(string asis) OUTVLIST(namelist) LRVLIST(namelist)]
		local ipdover "ipdover"
	}
	tempvar obs

	* Sort out study ID (or 'over' vars)
	// - if IPD/AD meta-analysis (i.e. not ipdover), create subgroup ID based on order of first occurrence
	// - decode any string variables
	cap nois ProcessIDs if `touse', study(`studyopt') studyid(`StudyID') by(`by_in_IPD') obs(`obs') ///
		tvlist(`tvlist') tnlist(`tnlist') labfile(`labfile') ///
		sortby(`sortby') cmdstruc(`cmdstruc') plname(`plname') `ipdover'
	
	if _rc {
		if _rc==1 nois disp as err `"User break in {bf:ipdmetan.ProcessIDs}"'
		else nois disp as err `"Error in {bf:ipdmetan.ProcessIDs}"'
		c_local err "noerr"		// tell ipdover not to also report an "error in {bf:ipdmetan}"
		exit _rc
	}

	if `"`ipdover'"'!=`""' {
		local overtype "`r(overtype)'"
		forvalues h=1/`overlen' {
			return local varlab`h' `"`r(varlab`h')'"'
		}
	}
	else {
		// If IPD+AD, we may also need to know if `study' was originally (i.e. in IPD) string: this is `ipdstr'
		if `"`ad'"'!=`""' {
			local ipdstr = cond(trim(`"`study'"') == trim(`"`r(study)'"'), "", "ipdstr")
			local ad `"`ad' `ipdstr'"'
		}
		local study "`r(study)'"			// contains de-coded string vars if present
		local svarlab `"`r(varlab1)'"'
	}


	
	*******************
	* lcols and rcols *
	*******************
	
	foreach x in na nc ncs nr nrn nrs ni {
		local `x'=0		// initialise
	}
	
	local _STUDY = cond(`"`ipdover'"'!=`""', "_LEVEL", "_STUDY")
	local het = cond(`"`ipdover'"'==`""', `"`het'"', `"nohet"')
	
	* If citype is other than normal, or if cumulative and using dlt/KR, will need a column for df
	//  sort out citype here, as that requires the returned stat e(df_r).
	//  we will sort out dlt/KR later on.
	local citype = cond(inlist(`"`citype'"', `""', `"z"'), `"normal"', `"`citype'"')	// default is citype(normal)
	if `"`citype'"'!=`"normal"' {
		tempvar _df
		local rcols `"`_df' = (e(df_r)) `rcols'"'	// use tempvar; if user wishes to see it, they can specify it in l/rcols as usual using e(df_r)
	}												//  (N.B. validity, e.g. e-class etc., will be tested later)
	
	if trim(`"`lcols'`rcols'"')==`""' | (`"`saving'"'==`""' & `"`graph'"'!=`""' & `"`citype'"'==`"normal"') {
		// if lcols/rcols will not be used,
		// (either because not specified, or because no savefile and no graph and no need for _df)
		// clear the macros
		local lcols
		local rcols
	}
	
	else {
		cap nois ParseCols `lcols' : `rcols'
		if _rc {
			if _rc==1 nois disp as err `"User break in {bf:ipdmetan.ParseCols}"'
			else nois disp as err `"Error in {bf:ipdmetan.ParseCols}"'
			c_local err "noerr"		// tell ipdover not to also report an "error in {bf:ipdmetan}"
			exit _rc
		}
		
		local lcols								// clear macro
		local rcols								// clear macro

		local itypes     `"`r(itypes)'"'		// item types ("itypes")
		local fmts       `"`r(fmts)'"'			// formats
		local cclist = trim(`"`cclist' `r(cclist)'"')	// clist of expressions for -collapse- (may already contain `"(firstnm) `plname'"')
		local statsr     `"`r(rstatlist)'"'		// list of "as-is" returned stats		
		local sidelist   `"`r(sidelist)'"'		// list of "sides"; left=0, right=1
		local csoldnames = trim(`"`csoldnames' `r(csoldnames)'"')	// list of original varnames for strings (may already contain `plname')
		local coldnames = trim(`"`coldnames' `r(coldnames)'"')		// list of original varnames for -collapse- (may already contain `plname')
		local lrcols     `"`r(newnames)'"'		// item names (valid Stata names)
		
		* Test validity of names -- cannot be any of the names ipdmetan uses for other things
		local badnames `"_BY _STUDY _OVER _LEVEL _ES _seES _WT _NN"'
		if `"`counts'"'!=`""' local badnames `"`badnames' _counts1 _counts1msd _counts0 _counts0msd"'
		if `"`oev'"'!=`""'    local badnames `"`badnames' _OE _V"'
		local badnames : list lrcols & badnames
		if `"`badnames'"'!=`""' {
			local badname1 : word 1 of `badnames'
			nois disp as err `"Variable name {bf:`badname1'} in lcols() or rcols() is reserved for use by {bf:ipdmetan}"'
			nois disp as err `"Please choose an alternative {it:target_varname} for this variable (see {help collapse})"'
			exit 101
		}
		
		* Get total number of "items" and loop, perfoming housekeeping tasks for each item
		local ni : word count `itypes'
		forvalues i=1/`ni' {
		
			// form new `lcols' and `rcols', just containing new varnames
			if !`: word `i' of `sidelist'' local lcols `"`lcols' `: word `i' of `lrcols''"'
			else                           local rcols `"`rcols' `: word `i' of `lrcols''"' 
	
			// separate lists of names for the different itypes
			if "`: word `i' of `itypes''"=="a" {						// a: AD-only vars, not currently in memory
				local ++na
				local namesa `"`namesa' `: word `i' of `lrcols''"'		// AD varlist, to be passed on to -admetan-
			}
			else if "`: word `i' of `itypes''"=="c" {					// c: Numeric vars to collapse
				local ++nc
				local namesc `"`namesc' `: word `i' of `lrcols''"'
				local nclab`nc' `"`r(cvarlab`nc')'"'
			}
			else if "`: word `i' of `itypes''"=="cs" {					// cs: String vars to "collapse"
				local ++ncs
				local svars `"`svars' `: word `i' of `lrcols''"'
				local ncslab`ncs' `"`r(csvarlab`ncs')'"'
			}
			else if "`: word `i' of `itypes''"=="r" {					// r: Returned stats (e-class or r-class)
				local ++nr												// (validity to be tested later)
				local namesr `"`namesr' `: word `i' of `lrcols''"'
				local nrlab`nr' `"`r(rvarlab`nr')'"'
			}
			if `"`het'"'==`""' & inlist("`: word `i' of `itypes''", "c", "r") & !`: word `i' of `sidelist'' {
				local extraline "extraline"				// if "c" or "r" in "lcols" then a new line will be needed for forestplots (for het etc.)
			}
		}		// end forvalues i=1/`ni'
		
		if `"`namesa'"'!=`""' local ad `"`ad' adcolvars(`namesa'))"'
		
	}		// end else (i.e. if not trim(`"`lcols'`rcols'"')==`""' | (`"`saving'"'==`""' & `"`graph'"'!=`""'))

	
	
	**********
	* Branch * - depending on whether we've got an estimation command or raw count data
	**********

	if "`rsample'" != "" {
		cap confirm var _rsample
		if !_rc {
			nois disp as err _n `"Warning: option {bf:norsample} specified, but "stored" variable {bf:_rsample} already exists"'
			nois disp as err  "Note that this variable is therefore NOT associated with the most recent analysis."
		}
	}
	
	* "command"-based syntax (Syntax 1, see help file)
	if "`cmdstruc'"=="generic" {
		
		// if ad(), record "overall" (_USE==5) anyway, regardless of `overall' macro (unless `nototal' of course!)
		//  (may be removed again later)
		local overallopt = cond(`"`ad'"'!=`""', `""', `"`overall'"')
		local strata_opt = cond(`"`strata'"'==`""', `""', `"strata(`strata')"')		// for error-trapping (Aug 2016)

		// if "`ipdover'"!="", need to pass something to ProcessCommand's studyid() option (as a convenience only)
		//  but we don't want to confuse this with `StudyID' as declared for "`ipdover'"=="" (as that will actually be needed).
		//  so use a different tempvar name.
		if `"`ipdover'"'!=`""' tempvar OverID
		local studyidopt = cond(`"`ipdover'"'!=`""', `"`OverID'"', `"`StudyID'"')
		
		cap nois `version' ProcessCommand `exp_list' if `touse', ///
			pcommand(`pcommand') cmdname(`cmdname') cmdargs(`cmdargs') cmdopts(`cmdopts') cmdrest(`cmdrest') ///
			sortby(`obs') study(`study', `smissing') studyid(`studyidopt') ipdfile(`ipdfile') poolvar(`poolvar') ///
			by(`by_in_IPD', `bymissing') `ipdover' `interaction' `overallopt' `subgroup' `total' `rsample' ///
			overlen(`overlen') nr(`nr') statsr(`statsr') namesr(`namesr') nrs(`nrs') nrn(`nrn') level(`level') `messages' `ztol' ///
			`strata_opt'
			
		if _rc {
			if _rc==1 nois disp as err `"User break in {bf:ipdmetan.ProcessCommand}"'
			else nois disp as err `"Error in {bf:ipdmetan.ProcessCommand}"'
			c_local err "noerr"		// tell ipdover not to also report an "error in {bf:ipdmetan}"
			exit _rc
		}

		return local estvar `"`r(estvar)'"'
		local n = r(n)
		
		local estvar `"`r(estvar)'"'
		local outvlist `"_ES _seES"'
		
		preserve
		
	}		// end if "`cmdstruc'"=="generic"

	
	* "Specific" effect measures; "collapse"-based syntax
	else {
		cap assert !`nr'
		if _rc {
			nois disp as err "Cannot specify returned statistics to lcols/rcols without an estimation command"
			exit _rc
		}
		
		
		** For this syntax, how the data is converted from IPD to AD depends on what sort of data it is,
		// i.e. what the summary statistic (`summstat') is.
		// (This isn't as crucial if already AD, as by then it is more obvious what sort of data it is.)
		
		// MyGetEFormOpts will have stored the following in summstat():
		// or, hr, shr, irr, rr, rrr, rd, smd or wmd (N.B. md is assumed to be a synonym for wmd)

		// If `summstat' does not yet exist, check remaining options for iv, mh, peto, logrank, cohen, hedges, glass, (no)standard
		//   If no `summstat' yet, use this info to generate a default value for `summstat'
		//   Otherwise, check for conflicts between these options and existing value of `summstat'
		// (N.B. A full parse of `method' will be done by admetan.ado)
		
		local 0 `", `options_ipdm'"'
		syntax [, IV MH PETO LOGRank COHen HEDges GLAss noSTANdard NPTS(string) BYAD VARS(string) * ]
		local options_ipdm `options'

		
		// First, take opportunity to check for options supplied to -ipdmetan-
		//  which should only be supplied to the ad() option
		if `"`byad'"'!=`""' {
			nois disp as err `"option {bf:byad} may only be supplied to {bf:ad()}"'
			exit 198
		}
		foreach opt in vars npts {
			if `"``opt''"'!=`""' {
				nois disp as err `"option {bf:`opt'()} may only be supplied to {bf:ad()}"'
				exit 198
			}
		}

		// Now continue with `summstat' processing
		if `"`summstat'"'!=`""' {
			cap {
				if trim(`"`cohen'`glass'`hedges'"')!=`""' assert `"`summstat'"'==`"smd"'
				if `"`standard'"'!=`""' assert `"`summstat'"'==`"wmd"'
				if `"`peto'"'!=`""'     assert `"`summstat'"'==`"or"'
				if `"`logrank'"'!=`""'  assert inlist(`"`summstat'"', "hr", "shr")
				if `"`mh'"'!=`""'       assert inlist(`"`summstat'"', "or", "rr", "irr", "rrr", "rd") 
			}
			if _rc {
				nois disp as err "Conflicting summary statistic options supplied"
				exit 198
			}
		}
		else {
			if `"`logrank'"'!=`""' {
				local summstat "hr"
				local seffect = cond(`"`effect'"'==`""', `"Haz. Ratio"', `"`effect'"')
				local log = cond(`"`log'"'!=`""', "log", cond(`"`eform'"'==`""', "log", ""))	// if no other influences, logrank ==> log 
			}
			else if `"`peto'"'!=`""' {
				local summstat "or"
				local seffect = cond(`"`effect'"'==`""', `"Odds Ratio"', `"`effect'"')
			}
			else if `"`mh'"'!=`""' {
				local summstat "rr"
				local seffect = cond(`"`effect'"'==`""', `"Risk Ratio"', `"`effect'"')
			}
			else if trim(`"`cohen'`glass'`hedges'"')!=`""' {
				local summstat "smd"
				local seffect = cond(`"`effect'"'==`""', `"SMD"', `"`effect'"')
			}
			else if `"`standard'"'!=`""' {
				local summstat "wmd"
				local seffect = cond(`"`effect'"'==`""', `"WMD"', `"`effect'"')
			}
		}
		
		if "`summstat'"=="" {
			nois disp as err `"Must specify an outcome measure (summary statistic) if no estimation command"'
			exit 198
		}
		
		local logrank = cond(inlist("`summstat'", "hr", "shr"), "logrank", "")
		local options_ipdm = trim(`"`macval(options_ipdm)' `iv' `mh' `peto' `logrank' `cohen' `hedges' `glass' `standard'"')
		// now logrank has potentially been altered, put all these options back into `options_ipdm' for passing to -admetan-
		
		local invlen : word count `invlist'		
		local expect = cond("`logrank'"!="", "one", "two")
		if `invlen' > 2 - ("`logrank'"!="") {
			nois disp as err "Too many variables supplied; was expecting `expect'"
			exit 198
		}
		if `invlen' < 2 - ("`logrank'"!="") {											// this should only trigger if "`logrank'"==""
			nois disp as err "Too few variables supplied; was expecting `expect'"		//  since `invlen'>0 has already been tested for
			if "`peto'"!="" nois disp as err `"(N.B. {bf:peto} option implies Odds Ratios; use {bf:logrank} option for Hazard Ratios)"'
			exit 198
		}
		
		* Preserve, and limit to necessary data only
		// N.B. data will now be preserved in any case (i.e. regardless of `cmdstruc')
		preserve
		qui keep if `touse'
		if `"`logrank'"'!=`""' local stvars `"_st _d _t0 _t"'

		keep `touse' `study' `StudyID' `invlist' `by_in_IPD' `stvars' `strata' `coldnames'

		
		* Setup `outvlist' ("output" varlist, to become the *input* into -admetan-, or to be returned to -ipdover-)
		// (as opposed to `invlist' which is the varlist *inputted by the user* into -ipdmetan- or -ipdover- !)
		// ... and `cclist' (to pass to -collapse-)
		tokenize `invlist'
		if "`2'"=="" {
			assert "`logrank'"!=""
			args trt
		}
		else args outcome trt

		summ `trt' if `touse', meanonly
		local trtok = `r(min)'==0 & `r(max)'==1
		qui tab `trt' if `touse'
		local trtok = `trtok' * (`r(r)'==2)
		if !`trtok' {
			di as err `"Treatment variable should be coded 0 = control, 1 = research"'
			exit 450
		}

		* Continuous data; word count = 6
		if inlist("`summstat'", "smd", "wmd") {
			if `"`ipdover'"'==`""' tempvar n1 mean1 sd1 n0 mean0 sd0
			else {
				tokenize `outvlist'
				args n1 mean1 sd1 n0 mean0 sd0
			}			
			local outvlist `n1' `mean1' `sd1' `n0' `mean0' `sd0'
			
			tempvar tv1 tv2
			local tvlist `tv1' `tv2'
		}
		
		* Raw count (2x2) data; word count = 4
		else if inlist("`summstat'", "or", "rr", "irr", "rrr", "rd") {
			summ `outcome' if `touse', meanonly
			local outok = `r(min)'==0 & `r(max)'==1
			qui tab `outcome' if `touse'
			local outok = `outok' * (`r(r)'==2)
			if !`outok' {
				nois disp as err `"Outcome variable should be coded 0 = no event, 1 = event"'
				exit 450
			}
		
			if `"`ipdover'"'==`""' tempvar e1 f1 e0 f0
			else {
				tokenize `outvlist'
				args e1 f1 e0 f0
			}
			local outvlist `e1' `f1' `e0' `f0'
			
			tempvar tv1 tv2
			local tvlist `tv1' `tv2'
		}
			
		* logrank HR; word count = 2
		else if "`logrank'"!="" {
			if `"`ipdover'"'==`""' {
				tempvar oe v n1 n0
				if `"`counts'"'!=`""' {
					tempvar e1 e0						// `lrvlist' is for LogRankHR and then -collapse-
				}										// if no `counts', it contains only `n1', `n0' (total pts. by arm);
				local lrvlist `"`n1' `n0' `e1' `e0'"'	// o/w, it also contains `e1' `e0' (no. events by arm)
			}											// (N.B. `e1', `e0' will be referred to as `di1', `di0' within LogRankHR)
			else {
				tokenize `outvlist'
				args oe v

				tokenize `lrvlist'
				if `"`counts'"'!=`""' args n1 n0 e1 e0
				else {
					args n1 n0
					local lrvlist `n1' `n0'
				}
			}
			local outvlist `oe' `v'	
		}
	}			// end else (i.e. if "`cmdstruc'"=="specific")


	// Finalise "ipdmetan" options to send to admetan.ado
	local lrvlist = cond(`"`logrank'"'==`""', `""', `"`lrvlist'"')		// in case `lrvlist' passed from -ipdover-
	local ipdmetan `"ipdfile(`ipdfile') cmdstruc(`cmdstruc') summstat(`summstat') estvar(`estvar') `extraline' lrvlist(`lrvlist')"'

	
	*** Perform -collapse- on `cclist' supplied to lcols/rcols, plus processing of raw data

	// Notes:
	// For estimation commands, `ipdfile' exists but is not currently in memory.
	// Otherwise (i.e. if "collapse"-type syntax), nothing permanent has been done to the data yet.
	// If Peto logrank, at the study (or `overh') level run LogRankHR *once*,
	//   to obtain processed data (O-E & V at unique times).
	// This process also retains any original varnames (`coldnames') from lcols/rcols needed for -collapse-.
	tempvar touse2 tempuse			// touse2 will have various uses later on; tempuse is for comparing with _USE after merging

	if `"`cmdstruc'"'==`"specific"' | trim(`"`cclist'`svars'"') != `""' {

		if `"`cmdstruc'"'==`"specific"' | trim(`"`cclist'"') != `""' {		// i.e. all except if `svars' alone
			forvalues h=1/`overlen' {
				local overh : word `h' of `study'
				gen byte `touse2' = `touse'
				if `"`smissing'"'==`""' markout `touse2' `overh', strok
				tempfile extra1_`h'

				local show = cond(`h'==1, "`show'", "noshow")
				if `"`cmdstruc'"'==`"specific"' {
					cap nois ProcessRawData `invlist' if `touse', ///
						study(`overh') by(`by_in_IPD') outvlist(`outvlist') tvlist(`tvlist') ///
						lrvlist(`lrvlist') coldnames(`coldnames') strata(`strata') `show'

					if _rc {
						if _rc==1 nois disp as err `"User break in {bf:ipdmetan.ProcessRawData}"'
						else nois disp as err `"Error in {bf:ipdmetan.ProcessRawData}"'
						c_local err "noerr"		// tell ipdover not to also report an "error in {bf:ipdmetan}"
						exit _rc
					}
				}				
				qui collapse `cclist' `r(cclist)' if `touse2' `cmdwt' `r(cmdwt)', fast by(`by_in_IPD' `overh' `StudyID')
				qui gen byte `tempuse' = 1
				qui save `extra1_`h''
				restore, preserve
			}
			
			// Now do lcols/rcols only by subgroup and overall
			if `"`ipdover'"'!=`""' local lrvlist2 : copy local lrvlist		// so that `lrvlist' is *only* used if `ipdover'
			
			if `"`by_in_IPD'"'!=`""' & "`subgroup'"==`""' {
				if `"`cmdstruc'"'==`"specific"' {
					cap nois ProcessRawData `invlist' if `touse', ///
						study(`by_in_IPD') outvlist(`outvlist') tvlist(`tvlist') ///
						lrvlist(`lrvlist2') coldnames(`coldnames') strata(`strata') noshow

					if _rc {
						if _rc==1 nois disp as err `"User break in {bf:ipdmetan.ProcessRawData}"'
						else nois disp as err `"Error in {bf:ipdmetan.ProcessRawData}"'
						c_local err "noerr"		// tell ipdover not to also report an "error in {bf:ipdmetan}"
						exit _rc
					}
				}
				if trim(`"`cclist'`r(cclist)'"')!=`""' {
					tempfile extra1_by
					qui collapse `cclist' `r(cclist)' if `touse' `cmdwt' `r(cmdwt)', fast by(`by_in_IPD')	// by-level
					qui gen byte `tempuse' = 3
					qui save `extra1_by'
				}
				restore, preserve
			}
				
			if `"`overall'"'==`""' {
				if `"`cmdstruc'"'==`"specific"' {
					tempvar cons
					gen byte `cons' = 1
					cap nois ProcessRawData `invlist' if `touse', ///
						study(`cons') outvlist(`outvlist') tvlist(`tvlist') ///
						lrvlist(`lrvlist2') coldnames(`coldnames') strata(`strata') noshow

					if _rc {
						if _rc==1 nois disp as err `"User break in {bf:ipdmetan.ProcessRawData}"'
						else nois disp as err `"Error in {bf:ipdmetan.ProcessRawData}"'
						c_local err "noerr"		// tell ipdover not to also report an "error in {bf:ipdmetan}"
						exit _rc
					}
				}
				if trim(`"`cclist'`r(cclist)'"')!=`""' {
					tempfile extra1_tot
					qui collapse `cclist' `r(cclist)' if `touse' `cmdwt' `r(cmdwt)', fast 		// overall
					qui gen byte `tempuse' = 5													// (or "subgroup" level for byad...
					qui save `extra1_tot'														//   ...this will be changed within admetan.ProcessAD)
				}
				restore, preserve
			}
		}
	
		* Perform manual "collapse" of any string vars in "over" files
		//  this could take a bit of to-ing and fro-ing, but it's a niche case
		if `"`svars'"' != `""' {
			assert `ncs' == `: word count `csoldnames''
			forvalues i=1/`ncs' {
				if `"`: word `i' of `csoldnames''"'!=`"`: word `i' of `svars''"' {
					rename `: word `i' of `csoldnames'' `: word `i' of `svars''
				}
			}
			forvalues h=1/`overlen' {
				local overh : word `h' of `study'
				gen byte `touse2' = `touse'
				if `"`smissing'"'==`""' markout `touse2' `overh', strok
				qui bysort `touse2' `by_in_IPD' `overh': keep if _n==_N & `touse2'
				keep `by_in_IPD' `overh' `svars' `bystudyopt'
				
				if `"`extra1_`h''"' != `""' {				// if file(s) already created above
					qui merge 1:1 `by_in_IPD' `overh' using `extra1_`h'', nogen assert(match)
					qui save `extra1_`h'', replace
				}
				else {										// if file(s) not yet created
					qui gen byte `tempuse' = 1
					tempfile extra1_`h'
					qui save `extra1_`h''
				}

				restore, preserve
			}
		}
	
		* Append files to form a single "extra" file
		qui use `extra1_1', clear
		if `overlen'>1 {								// if "over", append files
			qui gen _OVER=1
			forvalues h=2/`overlen' {
				local prevoverh : word `=`h'-1' of `study'
				local overh : word `h' of `study'
				rename `prevoverh' `overh'				// rename study var to match with next dataset
				qui append using `extra1_`h''
				qui replace _OVER=`h' if missing(_OVER)
			}
		}		
		if `"`extra1_by'"' != `""' {					// if file exists
			qui append using `extra1_by'
		}
		if `"`extra1_tot'"' != `""' {					// if file exists
			qui append using `extra1_tot'
		}

		* Apply variable labels to "collapse" vars
		forvalues i=1/`nc' {
			label var `: word `i' of `namesc'' `"`nclab`i''"'
		}
		if `"`svars'"'!=`""' {			// ...and "string" collapse vars
			forvalues i=1/`ncs' {
				label var `: word `i' of `svars'' `"`ncslab`i''"'
			}
		}
		
		// `overh' now contains the last element of `study',
		// but the variable itself contains observations from all elements stacked together (see preceding code)
		// Therefore, rename to either "_STUDY" or "_LEVEL" as appropriate
		if `"`overh'"' != `"`_STUDY'"' {
			rename `overh' `_STUDY'
		}
		if `"`by_in_IPD'"'!=`"_BY"' & `"`by_in_IPD'"'!=`""' {
			rename `by_in_IPD' _BY		// this slightly convoluted code is to avoid using "capture"
		}
		local _OVER = cond(`overlen'>1, "_OVER", "")
		local _BY = cond(`"`by_in_IPD'"'!=`""', "_BY", "")
		// N.B. although `_OVER' implies `ipdover', the converse is not true, as `overlen' might be 1.
		
		if `"`cmdstruc'"'==`"generic"' {
			tempvar merge
			qui merge 1:1 `_BY' `_OVER' `_STUDY' using `ipdfile', assert(match using) gen(`merge')
			qui assert inlist(_USE, 1, 2) if `merge'==3 & `tempuse'==1
			qui assert _USE==`tempuse' if `merge'==3 & `tempuse'!=1
			qui assert inlist(_USE, 3, 5) if `merge'==2		// N.B. only applies if no cclist (subgroup/overall not applicable for svars alone)
			qui drop `tempuse' `merge'
		}
		else qui rename `tempuse' _USE
		
	}	// end if `"`cmdstruc'"'==`"specific"' | trim(`"`cclist'`svars'"') != `""'

	else {	// load saved results from estimation command
		assert `"`cmdstruc'"'==`"generic"'
		use `ipdfile', clear
	}
	
	// apply variable labels to lcols/rcols "returned data"
	if `"`namesr'"'!=`""' {
		qui compress `namesr'		// compress first, but then apply formatting if applicable
		forvalues i=1/`nr' {
			local temp : word `i' of `namesr'
			label var `temp' `"`nrlab`i''"'
		}
	}
		
	// apply formats to lcols/rcols
	if `"`fmts'"'!=`""' {
		forvalues i=1/`ni' {
			local temp : word `i' of `lrcols'
			local fmti : word `i' of `fmts'
			if `"`fmti'"'!=`"null"' {
				format `temp' `fmti'
			}
		}
	}
	
	// Apply variable and value labels to _BY
	if `"`by_in_IPD'"'!=`""' {
		confirm numeric var _BY
		label var _BY `"`byvarlab'"'

		if `"`bylabfile'"'!=`""' {
			qui do `bylabfile'
			cap label drop _BY
			label copy `bylab' _BY
			label values _BY _BY
		}
	}

	
	** Raw data post-"collapse" tidying:
	if `"`cmdstruc'"'==`"specific"' {

		// check sort order
		sort _USE `StudyID'
	
		// non-events for 2x2 raw count data
		// (N.B. `f1' and `f0' have already been declared as part of `outvlist')
		if inlist("`summstat'", "or", "rr", "irr", "rrr", "rd") {
			tokenize `tvlist'
			args n1 n0
			qui gen long `f1' = `n1' - `e1'
			qui gen long `f0' = `n0' - `e0'
		}

		// _NN for logrank
		else if "`logrank'"!="" {
			qui gen long _NN = `n0' + `n1'		// total numbers of patients by study
			// local npts "_NN"					// N.B. (logrank) HR now implies existence of _NN (if Syntax 2)
		}
	}
	/*
	else {
		summ _NN, meanonly
		local npts = cond(r(N), `"_NN"', "")
	}
	*/

	
	
	*******************************
	* Pass to admetan for pooling *  -- or prepare to return data to ipdover
	*******************************

	// Load study/over value labels
	qui do `labfile'
	
	// Sort out effect text
	local effect = cond(`"`effect'"'!="", `"`effect'"', ///
		cond(`"`seffect'"'!=`""', `"`seffect'"', "Effect"))
	
	// Branch by admetan or ipdover 
	if `"`ipdover'"'==`""' {
	
		if `"`StudyID'"'!=`"_STUDY"' qui drop `StudyID'
		confirm numeric var _STUDY
		cap label drop _STUDY
		label copy `vallab1' _STUDY			// standardise value label name
		label values _STUDY _STUDY
		label var _STUDY `"`svarlab'"'

		// Remove `_df' from rcols
		if `"`_df'"'!=`""' {
			gettoken tok rest : rcols
			assert `"`tok'"'==`"`_df'"'		// it should be the first token
			local rcols `rest'
		}
		
		// N.B. `touse', `bymissing' `smissing' not necessary; assume that ALL observations are to be used.
		cap nois admetan `outvlist', study(`studyopt') by(`byopt') citype(`citype') `interaction' ///
			effect(`effect') /*`logrank' npts(`npts')*/ df(`_df') `eform' `log' ///
			`graph' `overall' `subgroup' `keepall' `keeporder' `het' ///
			forestplot(`fplotopts') lcols(`lcols') rcols(`rcols') saving(`saving') `ztol' level(`level') ///
			ipdmetan(`ipdmetan') ad(`ad') `options_ipdm'

		if _rc {
			if `"`err'"'==`""' {
				if _rc==1 nois disp as err `"User break in {bf:admetan}"'
				else nois disp as err `"Error in {bf:admetan}"'
			}
			exit _rc
		}

		return add
		
		// Sort out _rsample (already done if "estimation")
		if `"`cmdstruc'"'==`"specific"' & "`rsample'"=="" {
			qui keep if _USE==1
			qui keep _STUDY
			qui rename _STUDY `study'
			qui save `ipdfile', replace
			
			restore
			qui merge m:1 `study' using `ipdfile', assert(match master) gen(`touse2')
			cap drop _rsample
			gen byte _rsample = `touse' * (`touse2'==3)
		}
	}
	
	
	*** -ipdover- stuff ***
	
	// Else, more processing is required to obtain _ES, _seES, _LCI and _UCI before passing back to ipdover.ado
	// (N.B. these are mostly processes otherwise done by admetan.ado)
	else {
	
		// Add prefixes to `effect' text
		if `"`log'"'!=`""'         local effect `"log `effect'"'
		if `"`interaction'"'!=`""' local effect `"Interact. `effect'"'

		// Store "over" value labels in new var "_LABELS"
		tempvar labelh
		qui gen _LABELS=""
		forvalues h=1/`overlen' {
			local overh : word `h' of `study'
			if `"`vallab`h''"'!=`""' {				// use value labels loaded from `labfile'
				label values _LEVEL `vallab`h''
				qui decode _LEVEL, gen(`labelh')
				if `overlen'>1 {
					qui replace _LABELS=`labelh' if _OVER==`h'
				}
				else qui replace _LABELS=`labelh'
				drop `labelh'	
			}
			else {
				if `overlen'>1 {
					qui replace _LABELS=string(_LEVEL) if _OVER==`h'
				}
				else qui replace _LABELS=string(_LEVEL)
			}
		}
		label values _LEVEL		// finally, remove labels from _LEVEL

		// Generate _NN for "specific" `cmdstruc' (already done for logrank)
		if `"`cmdstruc'"'==`"specific"' & "`logrank'"=="" {
			qui gen long _NN = `n0' + `n1'
			if inlist("`summstat'", "or", "rr", "irr", "rrr", "rd") qui drop `n1' `n0'		// to minimize transfer of tempvars back to -ipdover- 
		}
				
		cap drop `OverID'				// remove `OverID' [`StudyID']
		qui save `ipdfile', replace
		
		// Return "universal" info to ipdover
		return local cmdstruc `cmdstruc'
		return local logrank `logrank'
		return local effect `"`effect'"'
		return local eform  `"`eform'"'
		return local citype `citype'
		return local fplotopts `"`fplotopts'"'
		return local lcols  `"`lcols'"'
		return local rcols  `"`rcols'"'
		// plus: `wt' (already done)
		
		// Overall number of participants for ipdover.ado
		// (this is otherwise handled by admetan.ado)
		qui gen long `obs' = _n				// tempvar has already been declared
		summ `obs' if _USE==5, meanonly
		if r(N) {
			assert r(N)==1
			return scalar n = _NN[`r(min)']
		}
		
		// return statistics for to "specific" effect measures (Syntax 2)
		if `"`cmdstruc'"'==`"specific"' {
			return local lrvlist  `lrvlist'
			return local invlist  `outvlist'				// N.B. `outvlist' becomes `invlist' for clearer comparison with admetan.ado code
			return local summstat `summstat'
			return local log      `log'
		}
		// N.B. if estimation, `estvar' already returned
		
		// return everything else in `options'
		return local options `"`macval(options_ipdm)' `overall' `subgroup' `graph' saving(`saving')"'

	}
	
end


	
	
	
******************************************************************



*********************
* Stata subroutines *
*********************


* Sort out study ID (or 'over' vars)
//  if IPD/AD meta-analysis (i.e. not ipdover), create subgroup ID based on order of first occurrence
//  so that -preserve- is not needed, and hence can be done *after* `ni0', `ni1' are generated (by LogRankHR).
// That way, we can restore and preserve, and keep `ni0', `ni1' in memory.

program define ProcessIDs, rclass sortpreserve

	syntax [if] [in], STUDY(string) CMDSTRUC(string) LABFILE(string) OBS(name) TVLIST(namelist) TNLIST(namelist) ///
		[BY(varname) SORTBY(varname) PLNAME(varname) IPDOVER STUDYID(name) ]
	
	marksample touse

	// parse `study' (could be a varlist if ipdover) and extract `missing'
	local 0 `"`study'"'
	syntax varlist [, Missing]
	local study `varlist'
	
	// Generate tempvar `obs', containing a unique observation ID
	// to be generated after sorting on `sortby' *within this subroutine* (with -sortpreserve-)
	// Hence, since `obs' is passed from the main routine, it will be retained AND the original sorting preserved.
	if `"`sortby'"'!=`""' sort `sortby'
	qui gen long `obs' = _n

	* Sort out study ID (or 'over' vars)
	//  if IPD/AD meta-analysis (i.e. not ipdover), create subgroup ID based on order of first occurrence
	//  (overh will be a single var, =study, so keep StudyID and stouse for later)
	local overtype "int"				// default
	tempvar stouse
	
	local overlen: word count `study'
	forvalues h=1/`overlen' {
		local overh : word `h' of `study'
		
		cap drop `stouse'
		qui gen byte `stouse' = `touse'
		if `"`missing'"'==`""' markout `stouse' `overh', strok
		
		if `"`ipdover'"'==`""' {
			tempvar sobs
			qui bysort `stouse' `overh' (`obs') : gen long `sobs' = `obs'[1]
			qui bysort `stouse' `by' `sobs' : gen long `studyid' = (_n==1)*`stouse'
			qui replace `studyid' = sum(`studyid')
			local ns = `studyid'[_N]					// number of studies, equal to max(`sgroup')
			qui drop `sobs'
		
			// test to see if subgroup variable varies within studies; if it does, exit with error
			if `"`cmdstruc'"'==`"generic"' {

				qui tab `overh' if `stouse', m
				if r(r) != `ns' {					// N.B. `ns' is already stratified by `by'
					nois disp as err "Data is not suitable for meta-analysis"
					nois disp as err " as variable {bf:`by'} (in option {bf:by()}) is not constant within studies."
					nois disp as err "Use alternative command {bf:ipdover} if appropriate."
					exit 198
				}
					
				// also test plname in the same way (if exists)
				if `"`plname'"'!=`""' {
					tempvar tempgp
					qui bysort `stouse' `plname' `overh' : gen long `tempgp' = (_n==1)*`stouse'
					qui replace `tempgp' = sum(`tempgp')
					summ `tempgp', meanonly
					local ntg = r(max)
					drop `tempgp'
					
					qui tab `overh' if `stouse', m
					if r(r) != `ntg' {
						nois disp as err `"variable {bf:`plname'} in option {bf:plotid()} is not constant within studies"'
						exit 198
					}
				}
			}		// end if `"`cmdstruc'"'==`"generic"'
		}		// end if `"`ipdover'"'==`""'
		
		* Store variable label
		local varlab`h' : variable label `overh'
		if `"`varlab`h''"'==`""' local varlab`h' `"`overh'"'
		return local varlab`h' `varlab`h''

		// numeric type
		if `"`overtype'"'=="int" & inlist(`"`: type `overh''"', "long", "float", "double") {
			local overtype `"`: type `overh''"'		// "upgrade" if more precision needed
		}
		
		* If any string variables, "decode" them
		//   and replace string var with numeric var in list "study"
		// If numeric, make a copy of each (original) value label value-by-value
		//   to avoid unlabelled values being displayed as blanks
		//   (also, for `study' with IPD+AD it needs to be added to)
		//   then store value label
		local vallab`h' : word `h' of `tnlist'
		cap confirm string var `overh'
		if !_rc {
			local overtemp : word `h' of `tvlist'
			qui encode `overh' if `stouse', gen(`overtemp') label(`vallab`h'')
			local study : subinstr local study `"`overh'"' `"`overtemp'"', all word
		}
		else {
			cap assert `overh'==round(`overh')
			if _rc {
				if `"`ipdover'"'!=`""' local errtext `"variables in {bf:over()}"'
				else local errtext `"variable {bf:`study'} in option {bf:study()}"'
				nois disp as err `"`errtext' must be integer-valued or string"'
				exit 198
			}
			qui levelsof `overh' if `stouse', missing local(levels)
			if `"`levels'"'!=`""' {
				foreach x of local levels {
					if `x'!=. {
						local labname : label (`overh') `x'
						label define `vallab`h'' `x' `"`labname'"', add
					}
				}
			}
		}
		assert `"`vallab`h''"' != `""'
		local lablist `"`lablist' `vallab`h''"'
	}	// end forvalues h=1/`overlen'

	if `"`lablist'"'!=`""' {
		qui label save `lablist' using `labfile'		// save "study"/"over" value labels
	}

	return local overtype "`overtype'"
	return local study "`study'"
	
end





**********************************************

* MyGetEFormOpts
// Basically _get_eformopts plus a bit extra!
// This program is used by both -ipdmetan- and -admetan-
//   and not all aspects are relevant to both.
// Easier to maintain just a single program, though.

program define MyGetEFormOpts, rclass
	
	// First, parse RR, since we want to stop it being interpreted as RRR by _get_eformopts
	syntax [name(name=cmdname)] , [ RR * ]

	** Estimation command syntax: use standard _check_eformopt
	if `"`cmdname'"'!=`""' {
		_check_eformopt `cmdname', eformopts(`options') soptions
		local eform = cond(`"`s(eform)'"'!=`""', "eform", "")
		local effect  `"`s(str)'"' 
		local summstat = cond(`"`s(opt)'"'==`"eform"', `""', `"`s(opt)'"')
	}
	
	** Non-estimation command syntax:
	// First, try _get_eformopts
	else {
		_get_eformopts, soptions eformopts(`options') allowed(__all__)
		local eform = cond(`"`s(eform)'"'!=`""', "eform", "")
		local effect  `"`s(str)'"' 
		local summstat = cond(`"`s(opt)'"'==`"eform"', `""', `"`s(opt)'"')
	}
	
	// Next, parse `anything' to extract anything that wouldn't usually be interpreted by _get_eformopts
	//  that is: mean differences (`md', `smd', `wmd'); `rd';
	//  `rr' (since this would usually be interpreted as `rrr' by _get_eformopts)
	//  `coef'/`log', and `nohr' & `noshr' (which imply `log')
	// (N.B. do this even if a valid option was found by _get_eformopts, since we still need to check for multiple options)
	local 0 `", `s(options)' `rr'"'
	syntax , [ COEF LOG MD SMD WMD RR RD NOHR NOSHR * ]

	// identify multiple options; exit with error if found
	if `"`summstat'"'!=`""' & trim(`"`md'`smd'`wmd'`rr'`rd'`nohr'`noshr'"')!=`""' {
		opts_exclusive "`summstat' `md' `smd' `wmd' `rr' `rd' `nohr' `noshr'"
	}
	
	if trim(`"`md'`wmd'"')!=`""' {		// MD and WMD are synonyms
		local effect `"WMD"'
		local summstat "wmd"
	}
	else if "`rr'"!="" {
		local effect `"Risk Ratio"'
		local summstat "rr"
		local eform `"eform"'
	}
	else {
		local effect = cond("`smd'"!="", `"SMD"', ///
			cond("`rd'"!="", `"Risk Diff."', ///
			cond("`rr'"!="", `"Risk Ratio"', `"`effect'"')))
		local summstat = cond(`"`summstat'"'==`""', trim(`"`smd'`rd'`rr'"'), `"`summstat'"')
	}
	else local summstat = cond(`"`nohr'"'!=`""', "hr", cond(`"`noshr'"'!=`""', "shr", `"`summstat'"'))

	// log always takes priority over eform
	// ==> cancel eform if appropriate
	local log = cond(`"`coef'"'!=`""', `"log"', `"`log'"')					// `coef' is a synonym for `log'
	if `"`log'"'!=`""' & inlist("`summstat'", "rd", "smd", "wmd") {
		nois disp as err "Log option only appropriate with ratio statistics"
		exit 198
	}
	if trim(`"`log'`nohr'`noshr'"')!=`""' {
		local eform
		local log "log"
	}

	return local eform    `"`eform'"'
	return local log      `"`log'"'
	return local summstat `"`summstat'"'
	return local effect   `"`effect'"'
	return local options  `"`macval(options)'"'

end




************************************************************************

* Routine to parse main options and forestplot options, and check for conflicts
// This program is used by both -ipdmetan- and -admetan-

// Certain options may be supplied EITHER to ipdmetan/admetan directly, OR as sub-options to forestplot()
//  with "forestplot options" prioritised over "main options" in the event of a clash.
// These options are:
//  -eform- options (plus extra stuff parsed by MyGetEformOpts e.g. `rr', `rd', `md', `smd', `wmd', `log')
//  nograph, nohet, nooverall, nosubgroup, nowarning, nowt
//  effect, ovstat, lcols, rcols, plotid, ovwt, sgwt, sgweight
//  cumulative, efficacy, influence, interaction
//  counts, group1, group2 (for compatibility with metan.ado)
//  rfdist, rflevel (for compatibility with metan.ado)

program define ParseFPlotOpts, rclass

	// Obtain summary info and lists from main routine
	syntax [, CMDNAME(string) EFORM LOG MAINPROG(string) SUMMSTAT(string) SEFFECT(string) ///
		MAINOPTS(string asis) FPLOTOPTS(string asis)]

	// Parse "main options" (i.e. options supplied directly to -ipdmetan- or -admetan-)
	local 0 `", `mainopts'"'
	syntax [, noGRaph noHET noOVerall noSUbgroup noWARNing noWT ///
		EFFect(passthru) OVStat(passthru) PLOTID(passthru) LCols(passthru) RCols(passthru) OVWt SGWt SGWEIGHT ///
		CUmulative EFFIcacy INFluence INTERaction COunts GROUP1(passthru) GROUP2(passthru) RFDist RFLevel(passthru) * ]

	return local mainopts `"`macval(options)'"'							// return anything else
		
	// Temporarily rename options which may be supplied as either "main options" or "forestplot options"
	local sgwt = cond("`sgweight'"!="", "sgwt", "`sgwt'")		// sgweight is a synonym (for compatibility with metan.ado)
	local sgweight
	
	local optionlist1 `"graph het overall subgroup warning wt ovwt sgwt"'
	local optionlist1 `"`optionlist1' cumulative efficacy influence interaction counts rfdist"'		// "stand-alone" options
	local optionlist2 `"effect ovstat plotid group1 group2 rflevel"'								// options requiring content within brackets
	local optionlist = trim(`"`optionlist1' `optionlist2' lcols rcols"')
	
	foreach opt of local optionlist {
		local `opt'_main : copy local `opt'
	}
		
	// Now parse forestplot options in the same way
	local 0 `", `fplotopts'"'
	syntax [, noGRaph noHET noOVerall noSUbgroup noWARNing noWT ///
		EFFect(passthru) OVStat(passthru) PLOTID(passthru) LCols(passthru) RCols(passthru) OVWt SGWt SGWEIGHT ///
		CUmulative EFFIcacy INFluence INTERaction COunts GROUP1(passthru) GROUP2(passthru) RFDist RFLevel(passthru) * ]

	local sgwt = cond("`sgweight'"!="", "sgwt", "`sgwt'")		// sgweight is a synonym (for compatibility with metan.ado)
	local sgweight
	
	// Process -eform- for forestplot, and check for clashes/prioritisation
	cap nois MyGetEFormOpts `cmdname', `log' `options'
	if _rc exit _rc
	return local fplotopts `"`r(options)'"'						// return anything else

	if `"`summstat'"'!=`""' & `"`r(summstat)'"'!=`""' & `"`summstat'"'!=`"`r(summstat)'"' {
		nois disp as err `"Conflicting summary statistics supplied to {bf:`mainprog'} and to {bf:forestplot()}"'
		exit 198
	}	
	
	// Forestplot options take priority
	return local eform = cond(`"`log'"'!=`""', `""', cond(`"`r(eform)'"'!=`""', `"eform"', `"`eform'"'))
	return local log = cond(`"`r(log)'"'!=`""', `"`r(log)'"', `"`log'"')
	return local summstat = cond(`"`r(summstat)'"'!=`""', `"`r(summstat)'"', `"`summstat'"')
	return local seffect = cond(`"`r(effect)'"'!=`""', `"`r(effect)'"', `"`seffect'"')
	
	// lcols, rcols: these *cannot* conflict
	foreach opt in lcols rcols {
		if `"``opt''"'!=`""' & `"``opt'_main'"'!=`""' & `"``opt''"'!=`"``opt'_main'"' {
			nois disp as err `"Conflicting option {bf:`opt'} supplied to {bf:`mainprog'} and to {bf:forestplot()}"'
			exit 198
		}
		if `"``opt''"'==`""' & `"``opt'_main'"'!=`""' local `opt' : copy local `opt'_main
		local parsedopts `"`parsedopts' ``opt''"'
	}
	
	// Remaining options are allowed to conflict, but forestplot will take priority
	// However, display warning for options requiring content within brackets (`optionlist2')
	foreach opt of local optionlist1 {
		if `"``opt''"'==`""' & `"``opt'_main'"'!=`""' local `opt' : copy local `opt'_main
		local parsedopts = trim(`"`parsedopts' ``opt''"')
	}
	foreach opt of local optionlist2 {
		if `"``opt''"'!=`""' & `"``opt'_main'"'!=`""' & `"``opt''"'!=`"``opt'_main'"' {
			nois disp as err `"Note: Conflicting option {bf:`opt'()}; {bf:forestplot()} suboption will take priority"' 
		}
		if `"``opt''"'==`""' & `"``opt'_main'"'!=`""' local `opt' : copy local `opt'_main
		local parsedopts = trim(`"`parsedopts' ``opt''"')
	}

	return local parsedopts "`parsedopts'"
	
end





*********************************************************************

* Process model estimation command and loop over trials	
// N.B. `sortby' contains `obs', i.e. a unique observation ID
program define ProcessCommand, rclass sortpreserve

	version 11.0
	local version : di "version " string(_caller()) ":"
	
	syntax [anything(name=exp_list equalok)] [if] [in] [fw aw pw iw], IPDFILE(string) CMDNAME(string) STUDY(string) STUDYID(name) ///
		[PCOMMAND(string) CMDARGS(string) CMDOPTS(string) CMDREST(string) noOVERALL noSUBGROUP noTOTAL noRSample ///
		BY(string) SORTBY(varname numeric) POOLVAR(string) INTERACTION ///
		IPDOVER OVERLEN(integer 1) LEVEL(passthru) ZTOL(real 1e-6) EFORM ADopt ///
		NR(integer 0) STATSR(string) NAMESR(string) NRS(integer 0) NRN(integer 0) MESSAGES ]
	
	// Save any existing estimation results, and clear return & ereturn
	tempname est_hold
	_estimates hold `est_hold', restore nullok
	_prefix_clear, e r

	local eclass=0				// initialise
	local nosortpreserve=0		// initialise
	
	* Unless specified otherwise (`noTOTAL'), run command on entire dataset
	// (to test validity, and also to find default poolvar and/or store overall returned stats if appropriate)
	marksample touse
	if `"`total'"'==`""' {
		sort `sortby'
		cap `version' `pcommand' `cmdname' `cmdargs' if `touse' `cmdopts' `cmdrest'
		local rc = _rc
		if `rc' {
			local errtext = cond(`"`pcommand'"'!=`""', `"`pcommand'"', `"`cmdname'"')
			_prefix_run_error `rc' ipdmetan `errtext'
		}
		tempname obs
		qui gen long `obs'=_n
		cap assert `obs'==`sortby'
		local nosortpreserve = (_rc!=0)		// if running `cmdname' changes sort order, "sortpreserve" is not used, therefore must sort manually
		drop `obs'
		
		// check if modifies e(b)
		// (N.B. doesn't necessarily mean we're going to *use* e(b);
		//  an `exp_list' could have been supplied, e.g. if `pcommand' is an r-class wrapper for an e-class routine
		cap mat list e(b)
		if !_rc {
			
			// If exp_list supplied by user, then *not* e-class (i.e. e(b) will not be used)
			if `"`exp_list'"'==`""' {
				if `"`poolvar'"'!=`""' local exp_list `"(_b[`poolvar']) (_se[`poolvar'])"'		// N.B. e(N) will be added later
				local eclass=1
			}
		}
		else if `"`poolvar'"'!=`""' {
			nois disp as err `"cannot specify {bf:poolvar()} without an e-class command; please specify {it:exp_list} instead"'
			exit 198
		}
			
		// check for string-valued returned stats (`statsrs'), and separate them out
		forvalues j=1/`nr' {
			local statsrj : word `j' of `statsr'
			local val = `statsrj'
			cap confirm number `val'
			if _rc & `"`val'"'!=`"."' {					// if ".", assume numeric missing
				local namesrj : word `j' of `namesr'
				local namesrs `"`namesrs' `namesrj'"'
				local statsrs `"`statsrs' `statsrj'"'
			}
		}
		if `"`statsrs'"'!=`""' {
			local statsrn : list statsr - statsrs
			local namesrn : list namesr - namesrs
			local nrn     : word count `statsrn'
			local nrs     : word count `statsrs'
		}
		else {
			local statsrn : copy local statsr
			local namesrn : copy local namesr
			local nrn = `nr'
		}
			
		// identify estvar
		cap nois FindEstVar `exp_list', eclass(`eclass') statsrn(`statsrn') nrn(`nrn') poolvar(`poolvar') `interaction'
		if _rc exit _rc
		local estvar   `"`r(estvar)'"'
		local estvareq `"`r(estvareq)'"'
		local estexp   `"`r(estexp)'"'
		local beta     `"`r(beta)'"'
		local sebeta   `"`r(sebeta)'"'
		local nbeta    `"`r(nbeta)'"'
		forvalues j=1/`nrn' {
			local us_`j' `"`r(us_`j')'"'
		}
	}			// end if `"`total'"'==`""'
		
	else {		// i.e. if noTOTAL
		
		// Define expressions if noTOTAL
		if `"`poolvar'"'!=`""' local exp_list `"(_b[`poolvar']) (_se[`poolvar']) (e(N))"'
		local estexp `poolvar'
		local nexp : word count `exp_list'
		tokenize `exp_list'
		local beta `1'
		local sebeta `2'
		local nbeta = cond(`nexp'==3, `"`3'"', ".")		// July 2016: cond(`nexp'==3, `3', .)??  i.e. why use quotes?
		
		// cannot use returned stats if noTOTAL since they cannot be pre-checked with _prefix_expand
		if `nr' {
			nois disp as err `"Cannot collect returned statistics with {bf:nototal}"'
			exit 198
		}
	}

	return local estvar `"`estexp'"'	// return this asap in case of later problems
	
	** Set up postfile
	tempname postname
	local _STUDY = cond(`"`ipdover'"'!=`""', "_LEVEL", "_STUDY")
	
	// parse `by' and form `bylist'
	local by = cond(trim(`"`by'"')==`","', `""', trim(`"`by'"'))
	if `"`by'"'!=`""' {
		local 0 `"`by'"'
		syntax varlist [, Missing]
		local by `varlist'
		qui levelsof `by' if `touse', `missing' local(bylist)
		local byopt `"`: type `by'' _BY"'
	}
	
	// parse `study' (could be a varlist if ipdover) and extract `missing'
	local 0 `"`study'"'
	syntax varlist [, Missing]
	local study `varlist'
	local smissing `missing'

	local overlen : word count `study'
	local overopt = cond(`overlen'>1, `"int _OVER"', "")
	local namesrsopt = cond(`"`namesrs'"'!=`""', `"str20(`namesrs')"', "")			// use 20 as default string length;
																					// we can't know in advance what to choose, but -postfile- demands a length
																					// (N.B. `namesrn' will default to float, see help newvarlist)
	postfile `postname' long `studyid' `byopt' `overopt' `overtype' `_STUDY' byte _USE double(_ES _seES) long _NN `namesrn' `namesrsopt' using `ipdfile'
	
	// overall (non-pooled): post values or blanks, as appropriate
	if `"`overall'"'==`""' {
	
		// post "(.) (5)" if overall (will eventually be treated as subgroup if byad, and _USE changed to 3)
		local postreps : di _dup(3) `" (.)"'
		if `"`ipdover'"'!=`""' & `"`total'"'==`""' {
			local postexp `"(.) (5) (`beta') (`sebeta') (`nbeta')"'		// only post non-pooled overall stats if ipdover
			return scalar n = `nbeta'
		}
		else local postexp `"(.) (5) `postreps'"'						// total of 5 expressions
		if `overlen'>1 local postexp `"(.) `postexp'"'					// add a sixth if _OVER required
		if `"`by'"'!=`""' local postexp `"(.) `postexp'"'				// add a sixth/seventh if _BY required

		if `"`total'"'==`""' {
			forvalues j=1/`nrn' {						// returned numeric stats
				local postexp `"`postexp' (`us_`j'')"'
			}
			local postexp `"`postexp' `statsrs'"'		// returned strings
		}
		else {
			local postrepsn : di _dup(`nrn') `" (.)"'	// returned numeric stats
			local postrepss : di _dup(`nrs') `" ()"'	// returned strings
			local postexp `"`postexp' `postrepsn' `postrepss'"'
		}

		post `postname' (.) `postexp'

	}	// end if `"`overall'"'==`""'
		
	
	** Analysis loop
	if "`rsample'"=="" {
		cap drop _rsample
		qui gen byte _rsample=0		// this will show which observations were used
	}
	local userbreak=0				// initialise
	local noconverge=0				// initialise
	
	tempvar stouse
	forvalues h=1/`overlen' {		// if over() not specified this will be 1/1
									// else, make `StudyID' equal to (`h')th over variable
		local overh : word `h' of `study'

		// If ipdover, order studies "naturally", i.e. numerically/alphabetically
		// Otherwise, use existing `StudyID'
		if `"`ipdover'"'==`""' {
			confirm numeric var `studyid'
			summ `studyid' if `touse', meanonly
			local ns = r(max)
		}
		else {
			qui gen byte `stouse' = `touse'
			if `"`smissing'"'==`""' markout `stouse' `overh', strok
			
			cap drop `studyid'
			qui bysort `stouse' `by' `overh' : gen long `studyid' = (_n==1)*`stouse'
			qui replace `studyid' = sum(`studyid')
			local ns = `studyid'[_N]				// total number of studies (might be repeats if `by' is not study-level)
			drop `stouse'
		}
		sort `sortby'	// N.B. recall that `sortby' distinctly identifies observations
		
		* Loop over study IDs (or levels of `h'th "over" var)
		forvalues i=1/`ns' {
			summ `sortby' if `touse' & `studyid'==`i', meanonly
			
			// find value of by() for current study ID (as identified by r(min))
			if `"`by'"'!=`""' {
				local val = `by'[`r(min)']
				local postby `"(`val')"'
			}
			if `overlen' > 1 local postover `"(`h')"'			// add over() var ID
			
			* Create label containing original values or strings,
			//  then add (original) study ID (which might be the same as StudyID; that is, `i')
			local val = `overh'[`r(min)']
			local poststudy `"(`val')"'
			local trlabi : label (`overh') `val'
			if `"`messages'"'!=`""' disp as text  "Fitting model for `overh' = `trlabi' ... " _c				
			cap `version' `pcommand' `cmdname' `cmdargs' if `touse' & `studyid'==`i' `cmdopts' `cmdrest'
			local rc = c(rc)
			
			if `rc' {	// if unsuccessful, insert blanks
				if `"`messages'"'!=`""' {
					nois disp as err "Error: " _c
					if `rc'==1 {
						nois disp as err "user break"
					}
					else cap noisily error _rc
				}
				local reps = 3 + `nrn'
				local postrepsn : di _dup(`reps') `" (.)"'			// returned numeric stats
				local postrepss : di _dup(`nrs') `" ()"'			// returned strings
				local postcoeffs `"(2) `postrepsn' `postrepss'"'	// N.B. "(2)" is for _USE ==> unsuccessful
			}														//  (to be kept/removed as specified by `keepall' option)
			else {
			
				// if model was fitted successfully but desired coefficient was not estimated
				if `eclass' {
					local colna : colnames e(b)
					local coleq : coleq e(b)
					if e(converged)==0 {
						local noconverge=1
						local nocvtext " (convergence not achieved)"
					}
				}
				if `eclass' & (!`: list estvar in colna' | (`"`estvareq'"'!=`""' & !`: list estvareq in coleq')) {
					if `"`messages'"'!=`""' {
						nois disp as err "Coefficent could not be estimated"
					}
					local postcoeffs `"(2) (.) (.) (`nbeta')"'
				}
				else if missing(`beta'/`sebeta') | (abs(`beta')>=`ztol' & abs(`beta'/`sebeta')<`ztol') {	// improved Mar 2017
					if `"`messages'"'!=`""' {
						nois disp as err "Coefficent could not be estimated"
					}
					local postcoeffs `"(2) (.) (.) (`nbeta')"'
				}
				else {
					local postcoeffs `"(1) (`beta') (`sebeta') (`nbeta')"'
					if `"`messages'"'!=`""' disp as res "Done`nocvtext'"
					if !`eclass' & `"`total'"'!=`""' {
						cap mat list e(b)
						local eclass = (!_rc)
					}
					if "`rsample'"=="" {
						if `eclass' qui replace _rsample=1 if e(sample)				// if e-class
						else qui replace _rsample=1 if `touse' & `studyid'==`i'		// if non e-class
					}
				}
				forvalues j=1/`nrn' {
					local postcoeffs `"`postcoeffs' (`us_`j'')"'
				}
				local postcoeffs `"`postcoeffs' `statsrs'"'

				local nocvtext		// clear macro
			}
			
			post `postname' (`i') `postby' `postover' `poststudy' `postcoeffs'
			local postby
			local postover
			local postcoeffs
			
			if `nosortpreserve' | `"`total'"'!=`""' {
				sort `sortby'		// if `cmdname' doesn't use sortpreserve (or noTOTAL), re-sort before continuing
			}
		}	// end forvalues i=1/`ns'
	}		// end forvalues h=1/`overlen'

	* If appropriate, generate blank subgroup observations
	//   and fill in with user-requested statistics (and, if ipdover, non-pooled effect estimates)
	if `"`by'"'!=`""' & `"`subgroup'"'==`""' {
		foreach byi of local bylist {
			local blank=0
			
			if (`"`ipdover'"'!=`""' | `nr') {
				cap `version' `pcommand' `cmdname' `cmdargs' if `by'==`byi' & `touse' `cmdopts' `cmdrest'
				if !_rc {
					local postexp `"(.) (3) (`beta') (`sebeta') (`nbeta')"'
					if `nr' & `"`ad'"'==`""' {
						forvalues j=1/`nrn' {
							local postexp `"`postexp' (`us_`j'')"'
						}
						local postexp `"`postexp' `statsrs'"'
					}
				}
				else local blank=1
			}
			else local blank=1
			if `blank' {
				local reps = 3 + `nrn'
				local postrepsn : di _dup(`reps') `" (.)"'			// returned numeric stats
				local postrepss : di _dup(`nrs') `" ()"'			// returned strings
				local postexp `"(.) (3) `postrepsn' `postrepss'"'
			}
			if `overlen' > 1 local postexp `"(.) `postexp'"'
			local postexp `"(.) (`byi') `postexp'"'
			post `postname' `postexp'

		}		// end foreach byi of local bylist
	}		// end if `"`by'"'!=`""' & `"`subgroup'"'==`""'
	
	postclose `postname'

	// Warning messages
	if `"`total'"'!=`""' {
		nois disp as err _n "Caution: initial model fitting in full sample was suppressed"
	}
	if `"`pcommand'"'!=`""' {
		nois disp as err _n `"Caution: prefix command supplied to {bf:ipdmetan}. Please check estimates carefully"'
	}
	if `noconverge' {
		nois disp as err _n "Caution: model did not converge for one or more studies. Pooled estimate may not be accurate"
	}
	if `userbreak' {
		nois disp as err _n "Caution: model fitting for one or more studies was stopped by user. Pooled estimate may not be accurate"
	}
	
end
	

	

*****************************************************************************

* ProcessRawData

* Setup `outvlist' ("output" varlist, to become the *input* into -admetan-, or to be returned to -ipdover-)
// (as opposed to `invlist' which is the varlist *inputted by the user* into -ipdmetan- or -ipdover- !)
// ... and `cclist' (to pass to -collapse-)

* Then pass to LogRankHR if appropriate.

// N.B. This subroutine needs to be called at the study level, and then again at the by or overall level if necessary
//   since the tempvars created will be erased upon -restore, preserve-

program define ProcessRawData, rclass

	syntax varlist(min=1 max=2 default=none numeric fv) [if] [in], ///
		STUDY(varname numeric) OUTVLIST(namelist) [ BY(varname numeric) ///
		TVLIST(namelist) LRVLIST(namelist) COLDNAMES(varlist numeric) STRATA(varlist) noSHow ]

	tokenize `varlist'
	if "`2'"=="" args trt
	else {
		assert `"`lrvlist'"'==`""'
		args outcome trt
	}
	
	marksample touse	
	tokenize `outvlist'
	local params : word count `outvlist'
	
	* Continuous data; word count = 6
	if `params' == 6 {
		args n1 mean1 sd1 n0 mean0 sd0

		tokenize `tvlist'
		args outcome1 outcome0
		qui gen `outcome1' = `outcome' if `trt'==1 & `touse'
		qui gen `outcome0' = `outcome' if `trt'==0 & `touse'
		local cclist `"(count) `n1'=`outcome1' `n0'=`outcome0' (mean) `mean1'=`outcome1' `mean0'=`outcome0' (sd) `sd1'=`outcome1' `sd0'=`outcome0'"'
	}
		
	* Raw count (2x2) data; word count = 4
	else if `params' == 4 {
		args e1 f1 e0 f0
		
		tokenize `tvlist'
		args outcome1 outcome0
		qui gen byte `outcome1' = `outcome' if `trt'==1 & `touse'
		qui gen byte `outcome0' = `outcome' if `trt'==0 & `touse'
		local cclist `"(count) `outcome1' `outcome0' (sum) `e1'=`outcome1' `e0'=`outcome0'"'
	}
		
	* logrank HR; word count = 2 (but only if `lrvlist' is supplied)
	else if "`lrvlist'"!="" {
		args oe v

		tokenize `lrvlist'
		args n1 n0 e1 e0
		
		// LogRankHR
		// If no `ipdover' (i.e. no `lrvlist'), we *only* need to collapse `cclist' at the *study* level;
		//   we can then restore the *original* data for any subsequent lcols/rcols work.
		// However, if `ipdover' we need to collapse `cclist' at the subgroup and overall levels too.
		cap nois LogRankHR `trt' if `touse', study(`study') by(`by') strata(`strata') `show' ///
			outvlist(`outvlist') lrvlist(`lrvlist') coldnames(`coldnames')
			
		if _rc {
			if _rc==1 nois disp as err `"User break in {bf:ipdmetan.LogRankHR}"'
			else nois disp as err `"Error in {bf:ipdmetan.LogRankHR}"'
			c_local err "noerr"		// tell ipdover not to also report an "error in {bf:ipdmetan}"
			exit _rc
		}
			
		local cclist `"`r(cclist)'"'
		return local cmdwt `"`r(cmdwt)'"'
	}

	return local cclist `"`cclist'"'

end

	


*******************************************

* Program to carry out Peto/logrank collapsing to one-obs-per-study
* (based on peto_st.ado)

program define LogRankHR, rclass
	
	st_is 2 analysis
	local wt : char _dta[st_wt]
	if "`wt'"=="pweight" {
		nois disp as err `"Cannot specify pweights"'
		exit 198
	}
	
	syntax varname [if] [in], STUDY(varname) OUTVLIST(namelist) LRVLIST(namelist) ///
		[BY(varname) STrata(varlist) noSHow COLDNAMES(varlist numeric) ]
	
	tokenize `outvlist'
	args oe v						// use alternative names for a, b, c, d here
									// for ease of calculation (and partly for comparison with "sts test" code)
	tokenize `lrvlist'
	args ni1 ni0 di1 di0			// these are really: n1 n0 e1 e0 (total in trt; total in ctrl; events in trt; events in ctrl)
									// but use different names here to avoid confusion with e = expected
	local nocounts = (`: word count `lrvlist''==2)
	if `nocounts' tempvar di1 di0
	
	local arm `varlist'		// treatment arm
		
	st_show `show'
	tempvar touse
	st_smpl `touse' `"`if'"' "`in'"
	
	local w : char _dta[st_w]
	return local cmdwt `"`w'"'
	
	if `"`_dta[st_id]'"' != "" {
		local id `"id(`_dta[st_id]')"'
	}
	local t0 "_t0"
	local t1 "_t"
	local dead "_d"

	tempvar touse
	mark `touse' `if' `in' `w'
	markout `touse' `t1' `dead'
	markout `touse' `arm' `strata', strok
	
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
			di as err `"repeated records at same `t1' within `id'"'
			exit 498
		}
		drop `id'
	}

	capture assert `t1'>0 if `touse'
	if _rc { 
		di as err `"survival time `t1' <= 0"'
		exit 498
	}
	capture assert `t0'>=0 if `touse'
	if _rc { 
		di as err `"entry time `t0' < 0"'
		exit 498
	}
	capture assert `t1'>`t0' if `touse'
	if _rc {
		di as err `"entry time `t0' >= survival time `t1'"'
		exit 498
	}
	capture assert `dead'==0 if `touse'
	if _rc==0 {
		di as err `"analysis not possible because there are no failures"'
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
	
	qui count if `touse'
	if !r(N) {
		nois disp as err "no observations"
		exit 2000
	}
		
	// store "treatment arm" variable label
	local gvarlab : variable label `arm'
	if `"`gvarlab'"'==`""' local gvarlab `"`arm'"'
	
	// weights
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
	tempvar op r d

	// Denominators
	//  (need to calculate these before limiting to unique times only)
	//  Only need to know denominators per study, per subgroup, and overall
	//  Strata are irrelevant as main calculations don't use denoms, & strata-specific stats are not presented
	forvalues i=0/1 {
		sort `by' `study' `arm' `t1'
		qui by `by' `study' : gen long `ni`i'' = sum(cond(`arm'==`i', 1, 0))
		sort `by' `study' `ni`i''
		qui by `by' `study' : replace `ni`i'' = `ni`i''[_N]
	}

	
	*** Begin manipulating data
	
	quietly {
	
		* Now re-define "bystr" for main calculations
		// This time "by" is irrelevant since it must be trial-level
		// but "strata" ARE relevant
		tempvar obs
		qui gen long `obs'=_n
		
		tempvar expand
		expand 2 if `touse', gen(`expand')
		gen byte `op' = cond(!`expand', 3, cond(`dead'==0,2/*cens*/,1/*death*/)) if `touse'
		replace `t1' = `t0' if `touse' & !`expand'

		sort `touse' `study' `strata' `t1' `op' `arm'
		by `touse' `study' `strata' :      gen `wntype' `r' = sum(cond(`op'==3, `w', -`w')) if `touse'
		by `touse' `study' `strata' `t1' : gen `wntype' `d' = sum(`w'*(`op'==1))            if `touse'

		* Numbers at risk, and observed number of events (failures)
		forvalues i=0/1 {
			tempvar ri`i'
			by `touse' `study' `strata' :      gen `wntype' `ri`i'' = sum(cond(`arm'==`i', cond(`op'==3,`w',-`w'), 0)) if `touse'
			by `touse' `study' `strata' `t1' : gen `wntype' `di`i'' = sum(cond(`arm'==`i', `w'*(`op'==1), 0))          if `touse'
			* N.B. `w' is not needed any more
		}

		// Again, if no `coldnames' we can simplify the dataset considerably
		tempvar touse2
		if `"`coldnames'"'==`""' {
			by `touse' `study' `strata' `t1': keep if _n==_N		// keep unique times only
			gen byte `touse2' = `touse'
		}	
		
		// Else: `touse'*`expand' preserves a copy of the original dataset in terms of auxiliary vars (lcols, rcols) to collapse
		// But we now need to work with unique times only, so define `touse2' for this -- a subset of `touse'*`expand'
		else {
			by `touse' `study' `strata' `t1' : gen byte `touse2' = `touse' * (_n==_N)
			// N.B. *sort* is not unique, but _n==_N keeps max(`r') within sort group
		}

		sort `touse2' `study' `strata' `t1' `op' `arm'	

		* Shift `r' up one place so it lines up
		tempvar newr
		by `touse2' `study' `strata' : gen `wntype' `newr' = `r'[_n-1] if `touse2'
		drop `r' 
		rename `newr' `r'
		
		* Shift each of the `ri's up one place so they line up
		forvalues i=0/1 {
			by `touse2' `study' `strata' : gen `wntype' `newr' = `ri`i''[_n-1] if _n>1 & `touse2'
			drop `ri`i''
			rename `newr' `ri`i''	
		}

		local todrop `"`t0' `t1' `arm' `dead' `strata'"'
		if `"`weight'"'!=`""' local todrop `"`todrop' `w'"'
		local todrop : list strata - coldnames
		if `"`todrop'"'!=`""' drop `todrop'				// don't need strata vars anymore (and there may be many of them)

		* Calculate:
		// E (expected number of events/failures)
		tempvar ei0 ei1
		gen double `ei0' = `ri0'*`d'/`r' if `touse2'
		gen double `ei1' = `ri1'*`d'/`r' if `touse2'

		tempvar zerocheck
		gen `zerocheck' = (`di1' - float(`ei1') == 0) | (float(`ei0') - `di0' == 0) if `touse2'
		assert float(`di1' - `ei1') == float(`ei0' - `di0') if !`zerocheck' & `touse2'				// arithmetic check
		assert float(1 + `di1' - `ei1') == float(1 + `ei0' - `di0') if `zerocheck' & `touse2'		// arithmetic check
		drop `zerocheck'
		
		// V (hypergeometric variance)
		assert float(`ri0' + `ri1') == float(`r') if `touse2'										// arithmetic check
		gen double `v' = `ri0'*`ri1'*`d'*(`r'-`d')/(`r'*`r'*(`r'-1)) if `touse2'
		drop `ri0' `ri1' `r' `d'

		// O - E
		gen double `oe' = `di1' - `ei1' if `touse2'													// use treatment arm
		
		* At this point we have one obs per unique failure time per arm per trial (`touse2').
		
		
		// Prepare and return `cclist'
		local sumvars `"`oe' `v'"'
		if !`nocounts' local sumvars `"`sumvars' `di0' `di1'"'

		if `"`coldnames'"'!=`""' {
			sort `obs' `expand'
			foreach x of local sumvars {
				by `obs' : replace `x' = sum(`x')
			}
			keep if `expand'		// N.B. this implies `touse'
		}

		local cclist `"(firstnm) `ni0' `ni1' (sum) `sumvars'"'
		return local cclist `"`cclist'"'
		
	}	// end quietly
	
end





*********************************

* -ParseCols-
* by David Fisher, August 2013

* Parses a list of "items" and outputs local macros for other programs (e.g. ipdmetan or collapse)
* Written for specific use within -ipdmetan-
//   identifying & returning expressions (e.g. "returned values" from regression commands)
//   identifying & returning "collapse-style" items to pass to collapse
//   identifying & returning labels (within quotation marks) and formats (%fmt) for later use

* N.B. Originally written (by David Fisher) as -collapsemat- , November 2012
// This did both the parsing AND the "collapsing", including string vars and saving to matrix or file.
// The current program instead *prepares* the data and syntax so that the official -collapse- command can be used.

* Minor updates Oct 2016

program define ParseCols, rclass
	version 8, missing
	
	syntax anything(name=clist id=clist equalok)
	
	local clist: subinstr local clist "[]" "", all
	local na=0					// counter of vars not in IPD (i.e. in aggregate dataset only)
	local nc=0					// counter of "collapse" vars
	local ncs=0					// counter of "collapse" vars that are strings (cannot be processed by -collapse-)
	local nr=0					// counter of "returned" vars
	local stat "null"			// GetOpStat needs a "placeholder" stat at the very least. Gets changed later if appropriate
	local fmt "null"			// placeholder format
	local fmtnotnull=0			// marker of whether *any* formatting has been specified
	local flag=0				// marker of what stage in the process we are
	local rcols=0				// marker of whether we're currently in lcols or rcols
	
	* Each loop of "while" should process an "item group", defined as
	// [(stat)] [newname=]item [%fmt "label"]
	while `"`clist'"' != "" {
	
		gettoken next rest : clist, parse(`":"')
		if `"`next'"'==`":"' {
			local rcols=1					// colon indicates partition from lcols to rcols
			local clist `"`rest'"'
			if `"`clist'"'==`""' {
				continue, break
			}
		}
		
		// Get statistic
		if !`flag' {
			GetOpStat stat clist : "`stat'" `"`clist'"'
			local flag=1
		}

		// Get newname and/or format
		// Get next two tokens -- first should be a (new)name, second might be "=" or a format (%...)
		else if inlist(`flag', 1, 2) {
			gettoken next rest : clist, parse(`" ="') bind qed(qed1)
			gettoken tok2 rest2 : rest, parse(`" ="') bind qed(qed2)
			if `qed1' {			// quotes around first element
				nois disp as err `"Error in {bf:lcols()} or {bf:rcols()}; check ordering/structure of elements"'
				exit 198
			}
			
			if `flag'==1 {
				if "`tok2'" == "=" {
					gettoken newname rest : clist, parse(" =")		// extract `newname'
					gettoken equal clist : rest, parse(" =")		// ...and start loop again
					continue
				}
				local flag=2
			}
			
			if `flag'==2 {
				if substr(`"`tok2'"', 1, 1) == `"%"' {		// var followed by format
					confirm format `tok2'
					local fmt `"`tok2'"'
					local fmtnotnull=1
					local clist : subinstr local clist "`tok2'" ""	// remove (first instance of) tok2 from clist and start loop again
					continue
				}
				local flag=3
			}
		}
		
		// Prepare variable itself (possibly followed with label in quotes)
		else if `flag'==3 {
		
			if `qed2' {					// quotes around second element ==> var followed by "Label"
				gettoken lhs rest : clist, bind
				gettoken rhs clist : rest, bind
			}
			else {						// var not followed by "Label"
				gettoken lhs clist : clist, bind
			}
			
			// Test whether `lhs' is a possible Stata variable name
			// If it is, assume "collapse"; if not, assume "returned statistic"
			cap confirm name `lhs'
			if _rc {
			
				// assume "returned statistic", in which case should be an expression within parentheses
				gettoken tok rest : lhs, parse("()") bind match(par)
				if `"`par'"'=="" {
					cap confirm name `lhs'
					if _rc==7 {
						nois disp as err `"invalid name or expression {bf:`lhs'} found in {bf:lcols()} or {bf:rcols()}"'
						nois disp as err `"check that expressions are enclosed in parentheses"'
						exit _rc
					}
					else if _rc confirm name `lhs'
				}
				else {
					local ++nr
					local rstatlist `"`rstatlist' `lhs'"'				// add expression "as-is" to overall ordered list
					if `"`rhs'"' != `""' {
						return local rvarlab`nr'=trim(`"`rhs'"')		// return varlab
						local rhs
					}
					if `"`newname'"'==`""' GetNewname newname : `"`lhs'"' `"`newnames'"'
					else if `"`: list newnames & newname'"' != `""' {
						nois disp as err `"naming conflict in {bf:lcols()} or {bf:rcols()}"'
						exit 198
					}
					local sidelist `"`sidelist' `rcols'"'				// add to (overall, ordered) list of "sides" (l/r)
					local newnames `"`newnames' `newname'"'				// add to (overall, ordered) list of newnames
					local itypes `"`itypes' r"'							// add to (overall, ordered) list of "item types"
					local newfmts `"`newfmts' `fmt'"'					// add to (overall, ordered) list of formats
				}
			}
			
			// If "collapse", convert "ipdmetan"-style clist into "collapse"-style clist
			else {
				cap confirm var `lhs'			// this time test if it's an *existing* variable
				if _rc {
				
					// AD variable only; not present in IPD
					local ++na
					if trim(`"`newname'`rhs'"')!=`""' {
						nois disp as err `"variable {bf:`lhs'} not found in IPD dataset"'
						nois disp as err `"cannot specify {it:newname} or {it:variable label}"'
						exit 198
					}
					local sidelist `"`sidelist' `rcols'"'		// add to (overall, ordered) list of "sides" (l/r)
					local newnames "`newnames' `lhs'"			// add to (overall, ordered) list of newnames (but keep original name in this case)
					local itypes `"`itypes' a"'					// add to (overall, ordered) list of "item types"
				}

				else {
					cap confirm string var `lhs'
					
					// String vars
					if !_rc {
						local ++ncs
						if `"`newname'"'==`""' GetNewname newname : `"`lhs'"' `"`newnames'"'
						else if `"`: list newnames & newname'"' != `""' {
							nois disp as err `"naming conflict in {bf:lcols()} or {bf:rcols()}"'
							exit 198
						}
						local sidelist `"`sidelist' `rcols'"'		// add to (overall, ordered) list of "sides" (l/r)
						local newnames "`newnames' `newname'"		// add to (overall, ordered) list of newnames
						local csoldnames "`csoldnames' `lhs'"		// add to sub-list of original string varnames
						local itypes `"`itypes' cs"'				// add to (overall, ordered) list of "item types"
						local newfmts `"`newfmts' `fmt'"'			// add to (overall, ordered) list of formats
						if `"`rhs'"' != `""' {
							local varlab=trim(`"`rhs'"')
							local rhs
						}
						else local varlab : var label `lhs'
						return local csvarlab`ncs' = `"`varlab'"'	// return varlab
					}
					
					// Numeric vars: build "clist" expression for -collapse-
					else {
						local ++nc
						if `"`stat'"'==`"null"' {
							local stat "mean"				// otherwise default to "mean"
						}
						local keep `"`keep' `lhs'"'
						if `"`rhs'"' != `""' {
							local varlab = trim(`"`rhs'"')
							local rhs
						}
						else local varlab : var label `lhs'
						return local cvarlab`nc' = `"`varlab'"'			// return varlab
						local stat=subinstr(`"`stat'"',`" "',`""',.)	// remove spaces from stat (e.g. p 50 --> p50)
						
						if `"`newname'"'==`""' GetNewname newname : `"`lhs'"' `"`newnames'"'
						else if `"`: list newnames & newname'"' != `""' {
							nois disp as err `"naming conflict in {bf:lcols()} or {bf:rcols()}"'
							exit 198
						}					
						if trim(`"`fmt'"')==`"null"' {
							local fmt : format `lhs'						// use format of original var if none specified
						}
						local sidelist `"`sidelist' `rcols'"'				// add to (overall, ordered) list of "sides" (l/r)
						local newnames `"`newnames' `newname'"'				// add to (overall, ordered) list of newnames
						local coldnames "`coldnames' `lhs'"					// add to sub-list of original varnames
						local itypes `"`itypes' c"'							// add to (overall, ordered) list of "item types"
						local newfmts `"`newfmts' `fmt'"'					// add to (overall, ordered) list of formats

						local cclist `"`cclist' (`stat') `newname'=`lhs'"'		// add to "collapse" clist

					}		// end  if !_rc (i.e. is `lhs' string or numeric)
				}		// end else (i.e. if `lhs' found in data currently in memory)
			}		// end else (i.e. if "collapse")

			local fmt "null"
			local newname
			local flag=0
		}		// end else (i.e. "parse variable itself")
		
		else {
			nois disp as err `"Error in {bf:lcols()} or {bf:rcols()}; check ordering/structure of elements"'
			exit 198
		}
	}		// end "while" loop

	
	// Check length of macro lists
	local nnewnames : word count `newnames'
	local nitypes : word count `itypes'
	local nsidelist : word count `sidelist'
	assert `nnewnames' == `nitypes'						// check newnames & itypes equal
	assert `nnewnames' == `nsidelist'					// check newnames & sidelist equal
	assert `nnewnames' == `na' + `nc' + `ncs' + `nr'	// ... and equal to total number of "items"
	
	if `fmtnotnull' {
		local nfmts : word count `newfmts'
		assert `nfmts' == `nnewnames'		// check fmts also equal, if appropriate
	}
	
	// Return macros & scalars
	return local newnames=trim(itrim(`"`newnames'"'))		// overall ordered list of newnames
	return local itypes  =trim(itrim(`"`itypes'"'))			// overall ordered list of "item types"
	return local sidelist=trim(itrim(`"`sidelist'"'))		// overall ordered list of "sides" (l/r)
	if `fmtnotnull' {
		return local fmts=trim(itrim(`"`newfmts'"'))		// overall ordered list of formats (if any specified)
	}
	if `nc' {
		return local coldnames=trim(itrim(`"`coldnames'"'))		// list of original varnames used in "collapse"
		return local cclist   =trim(itrim(`"`cclist'"'))		// "collapse" clist
	}
	if `ncs' {
		return local csoldnames=trim(itrim(`"`csoldnames'"'))	// list of original varnames for strings
	}
	if `nr' {
		return local rstatlist=trim(itrim(`"`rstatlist'"'))	// list of returned stats "as is"
	}
	
end


* The following subroutine has a similar name and function to GetNewnameEq in the official "collapse.ado"
*  but has been re-written by David Fisher, Aug 2013
program GetNewname
	args mnewname colon oldname namelist
	
	local newname=strtoname(`"`oldname'"')		// matrix colname (valid Stata varname)
				
	// Adjust newname if duplicates
	if `"`: list namelist & newname'"' != `""' {
		local j=2
		local newnewname `"`newname'"'
		while `"`: list namelist & newnewname'"' != `""' {
			local newnewname `"`newname'_`j'"'
			local ++j
		}
		local newname `"`newnewname'"'
	}
	
	c_local `mnewname' `"`newname'"'
end
				

* The following subroutine has been modified slightly from its equivalent in the official "collapse.ado"
* by David Fisher, Sep 2013
program GetOpStat 
	args mstat mrest colon stat line

	gettoken thing nline : line, parse("() ") match(parens)
	
	* If `thing' is a single word in parentheses, check if it matches a single "stat" word
	if "`parens'"!="" & `:word count `thing'' == 1 {
		local 0 `", `thing'"'
		cap syntax [, mean median sd SEMean SEBinomial SEPoisson ///
			sum rawsum count max min iqr first firstnm last lastnm null]
		
		// fix thing if abbreviated
		if "`semean'" != "" local thing "semean"
		if "`sebinomial'" != "" local thing "sebinomial"
		if "`sepoisson'" != "" local thing "sepoisson"

		// if syntax executed without error, simply update locals and exit
		if _rc == 0 {
			c_local `mstat' `thing'
			c_local `mrest' `"`nline'"'
			if ("`median'"!="") c_local `mstat' "p 50"
			exit
		}
		
		// if not, check for percentile stats
		local thing = trim("`thing'")
		if (substr("`thing'",1,1) == "p") {
			local thing = substr("`thing'",2,.)
			cap confirm integer number `thing'
			if _rc==0 { 
				if 1<=`thing' & `thing'<=99 {
					c_local `mstat' "p `thing'"
					c_local `mrest' `"`nline'"'
					exit
				}
			}
		}
	}
		
	* Otherwise, assume `thing' is an expression (this will be tested later by _prefix_explist)
	//  update locals and return to main loop
	c_local `mstat' "`stat'"
	c_local `mrest' `"`line'"'
		
end




*********************************

* Parse output of initial model fitted to entire dataset to identify "estvar" and associated info
program define FindEstVar, rclass

	syntax [anything(name=exp_list equalok)], [ECLASS(integer 0) STATSRN(string) NRN(integer 0) POOLVAR(string) INTERACTION]

	// Parse <exp_list>
	local nexp=0
	local neexp=0
	_prefix_explist `exp_list', stub(_df_) edefault
	if `"`exp_list'"'!=`""' {
		cap assert `s(k_eexp)'==0 & inlist(`s(k_exp)', 2, 3)	// if exp_list supplied, must be 2 or 3 exps, no eexps
		local nexp = `s(k_exp)'
	}
	else {
		cap assert `s(k_eexp)'==1 & `s(k_exp)'==0				// otherwise, must be a single eexp (_b) and no exps
		local neexp = `s(k_eexp)'
	}
	local rc = _rc
	
	local eqlist	`"`s(eqlist)'"'
	local idlist	`"`s(idlist)'"'
	local explist	`"`s(explist)'"'
	local eexplist	`"`s(eexplist)'"'

	// Expand <exp_list>
	tempname b
	cap _prefix_expand `b' `explist' `statsrn', stub(_df_) eexp(`eexplist') colna(`idlist') coleq(`eqlist') eqstub(_df)
	local rc  = cond(`rc', `rc', _rc)
	
	if `rc' {
		nois disp as err `"{it:explist} error. Possible reasons include:"'
		if `"`poolvar'"'!=`""' nois disp as err "- coefficient in {bf:poolvar()} not found in the model"
		if `"`statsrn'"'!=`""' nois disp as err "- an expression in {bf:lcols()} or {bf:rcols()} that evaluates to a string"
		nois disp as err "- an expression not enclosed in parentheses"
		exit `rc'
	}
	local nexp = cond(`neexp', `s(k_eexp)', `nexp')		// if eexps, update `neexp' and rename it to `nexp'

	// Form list of "returned statistic" expressions to post
	forvalues j=1/`nrn' {
		local i = `nexp' + `j'
		return local us_`j' `"`s(exp`i')'"'
	}
	
	// Identify estvar
	if !`eclass' {							// not using e(b)
		local beta `"`s(exp1)'"'
		local sebeta `"`s(exp2)'"'
		local nbeta = cond(`nexp'==3, `"`s(exp3)'"', ".")		// July 2016: cond(`nexp'==3, `3', .) ??  i.e. why use quotes?
	}
	else {
		// If e-class, parse e(b) using _ms_parse_parts
		// Choose the first suitable coeff, then check for conflicts with other coeffs (e.g. interactions)
		// Can we also check for badly-fitted coeffs here?  i.e. v high/low b or se?
		local ecolna `"`s(ecolna)'"'	// from _prefix_expand
		local ecoleq `"`s(ecoleq)'"'	// from _prefix_expand
		local colna : colnames e(b)		// from e(b)
		local coleq : coleq e(b)		// from e(b)

		// If not poolvar (i.e. basic syntax), results from _prefix_expand should match those from e(b)
		assert (`"`ecolna'"'!=`""') == (`"`poolvar'"'==`""')
		assert (`"`ecoleq'"'!=`""') == (`"`poolvar'"'==`""')

		if `"`poolvar'"'==`""' {				// MAY 2014: only check for conflicts if poolvar not supplied
			assert `"`ecolna'"'==`"`colna'"'
			if substr(`"`coleq'"', 1, 1)!=`"_"' {
				assert `"`ecoleq'"'==`"`coleq'"'
			}
			local name1
			local name2

			forvalues i=1/`nexp' {
				local colnai : word `i' of `colna'
				local coleqi : word `i' of `coleq'

				_ms_parse_parts `colnai'
				if !r(omit) {

					// If estvar already exists, check for conflicts with subsequent coeffs
					// (cannot currently check for difference between, e.g. "arm" and "1.arm"
					//  - i.e. how to tell when a var is factor if not made explicit... is this a problem?)
					if `"`estvar'"'!=`""' {
						if `"`coleqi'"'==`"`estvareq'"' {			// can only be a conflict if same eq
							if `"`r(type)'"'=="interaction" {
								local rname1 = cond(`"`r(op1)'"'==`""', `"`r(name1)'"', `"`r(op1)'.`r(name1)'"')
								local rname2 = cond(`"`r(op2)'"'==`""', `"`r(name2)'"', `"`r(op2)'.`r(name2)'"')

								if (`"`interaction'"'!=`""' & ///
										( inlist(`"`name1'"',`"`rname1'"',`"`rname2'"') ///
										| inlist(`"`name2'"',`"`rname1'"',`"`rname2'"') )) ///
									| (`"`interaction'"'==`""' & inlist(`"`estvar'"',`"`rname1'"',`"`rname2'"')) {
									nois disp as err "Automated identification of {it:estvar} failed; please supply {bf:poolvar()} or {it:exp_list}"'
									exit 198
								}
							}
							else if inlist(`"`r(type)'"', "variable", "factor") {
								local rname = cond(`"`r(op)'"'==`""', `"`r(name)'"', `"`r(op)'.`r(name)'"')

								if (`"`interaction'"'!=`""' & inlist(`"`rname'"',`"`name1'"',`"`name2'"')) ///
									| (`"`interaction'"'==`""' & `"`rname'"'==`"`estvar'"') {
									nois disp as err "Automated identification of {it:estvar} failed; please supply {bf:poolvar()} or {it:exp_list}"'
									exit 198
								}
							}
						}
					}		// end if `"`estvar'"'!=`""'

					// Else define estvar
					else if `"`interaction'"'!=`""' {
						if `"`r(type)'"'=="interaction" {
							local estvar `colnai'
							local estvareq `coleqi'
							local name1 `"`r(name1)'"'
							local name2 `"`r(name2)'"'
						}
					}
					else {
						local estvar `colnai'
						local estvareq `coleqi'							
					}		// end else
				}		// end if !r(omit)
			}		// end forvalues i=1/`nexp'

			if `"`estvar'"'==`""' {
				nois disp as err "Automated identification of {it:estvar} failed; please supply {bf:poolvar()} or {it:exp_list}"'
				exit 198
			}
			
			if inlist(`"`estvareq'"', "_", "") local estexp `"`estvar'"'
			else local estexp `"`estvareq':`estvar'"'

		}		// end if `"`poolvar'"'==`""'

		else {		// parse `poolvar' -- assume "estvareq:estvar" format
			local estexp `poolvar'
			cap _on_colon_parse `estexp'
			if _rc local estvar `"`estexp'"'	// no colon found
			else {
				local estvareq `"`s(before)'"'
				local estvar `"`s(after)'"'
			}
		}

		local beta `"_b[`estexp']"'
		local sebeta `"_se[`estexp']"'
		local nbeta `"e(N)"'

	}		// end else (i.e. if eclass)
	
	// Return macros
	return local estvar   `"`estvar'"'
	return local estvareq `"`estvareq'"'
	return local estexp   `"`estexp'"'
	return local beta     `"`beta'"'
	return local sebeta   `"`sebeta'"'
	return local nbeta    `"`nbeta'"'

end





