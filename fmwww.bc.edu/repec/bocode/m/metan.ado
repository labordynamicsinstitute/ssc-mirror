* metan.ado
* Study-level (aka "aggregate-data" or "published data") meta-analysis

*! version 4.02  23feb2021
*! Current version by David Fisher
*! Previous versions by Ross Harris and Michael Bradburn



*****************************
* metan.ado version history *
*****************************
// by Ross Harris and others; further details at end

* Based on previous version: 1.86 1Apr2004
* Based on 2.34 11May2007
* Based on 3.01 07Jul2008

* 3.03 19May2009
* fixes prediction interval calculation for non-ratio measures and change of variable type in lcols() rcols()
* think latter is ok actually- check download, perhaps was using old version!

* 3.04 21Sep2010
* fixed small bug in counts option (`rawcounts' var truncated as str20)


*******************************
* admetan.ado version history *
*******************************
// by David Fisher; further details at end

* originally written by David Fisher, June 2013
// to perform the second stage of two-stage IPDMA, using ipdmetan.ado

* version 1.0  David Fisher  31jan2014
* version 2.0  David Fisher  11may2017
// Major update to extend functionality beyond "estimation commands" (cf ipdmetan);
//   now has most of the functionality of -metan-

* version 2.1  David Fisher  14sep2017
// various bug fixes

* version 3.0  David Fisher  08nov2018
// IPD+AD code now moved to ipdmetan.ado
//   so that -admetan- is completely self-contained, with minimal reference to -ipdmetan-

* version 3.1  David Fisher  04dec2018
// various bug fixes

* version 3.2  David Fisher  28jan2019
// added some new estimators
// some bug fixes

* version 3.3 (beta; never released)  David Fisher 14nov2019
// restored previous -metan- second() option, and extended to multiple models using model(.. \ .. \ ..)
// improvements to handling of zero cells;  added Tarone and CMH statistics for M-H
// minor bug fixes

* version 3.4 (beta; never released)  David Fisher 12dec2019
// added meta-analysis of proportions
// restored previous -metan- behaviour of sorting string by() by order of appearance, rather than alphabetically
// minor bug fixes

* version 3.5 (beta; never released)  David Fisher 21jan2020
// various bug fixes and code improvements

* version 3.6 (beta; never released)  David Fisher 22may2020
// restored -double- option to -forestplot-
// corrected code for between-study heterogeneity under random-effects

* version 3.7 (beta; never released)  David Fisher 19jun2020
// allow all previously-valid -metan- options to continue working as documented...
//  ...including options now expected in forestplot()
//  ... (but with a warning message if appropriate, explaining syntax changes)
// responded to other minor comments from JS and JPTH
// moved Mata functions to a separate library file; improved some routines using optimize()

* version 3.8 (beta; never released)  David Fisher 07sep2020
// Following discussion with JPTH 1st Sep 2020:
// - make "qncchi2" the default method for heterogeneity CIs, rather than Higgins & Thompson test-based
// - by default, I-squared and H should always be Q-based ... introduce an "advanced" option for presenting tausq-based het. stats
// - plus, change explanatory text underneath table to match.

// Other fixes:  study is blank if undefined (should be 1, 2, 3 etc.)
// [Note: -twoway- doesn't seem to like text starting with double-quotes... this doesn't seem to be a -metan- problem specifically]

* version 4.00
// 7th October 2020, following email from JPTH
// "higgins" --> "testbased"
// "tsqbased" --> "isqparam"

// - added possibility of "labelling" models so that e.g. model(iv \ dl) can be labelled "Fixed" and "Random"
// - also allow user-supplied effect estimates within model(...), rather than only with -metan9- first() and second() options

* version 4.01
// - added Barendregt-Doi proposed denominator for double-arcsine back-transform for proportions

// Bug fixes:
// - corrected "syntax" statement in BuildResultsSet so that it works with Stata versions pre-15
//   (option list was >70, which was too long for Stata pre-15, causing "invalid syntax" error)
// - cumulative/influence with saving() now stores all relevant variables, including Q, sigmasq etc.
// - improved user control over labelling of RE models
// - fixed minor bug in display of SMD options (always said Cohen even if Glass/Hedges; pooled results were correct)

* version 4.02
// Bug fixes: for future reference, MUST ensure that metan_pooling.ado and metan.PerformPoolingIV are kept in sync!


program define metan, rclass
	
	version 11.0
	local version : di "version " string(_caller()) ":"

	if _caller() >= 12 {
	    local hidden hidden
		local historical historical
	}
	return `hidden' local metan_version "4.02"

	// Clear historical global macros (see metan9.ado)
	forvalues i = 1/15 {
		global S_`i'
	}
	global S_51
	
	syntax varlist(numeric min=2 max=6) [if] [in] [, SORTBY(varlist) ///
		LABEL(passthru) BY(passthru) ///
		FORESTplot(passthru) CLEAR   /// forestplot (ultimately -twoway-) options; leave results-set in memory
		///
		IPDMETAN PRESERVE USE(varname numeric) ESTEXP(passthru) EXPLIST(passthru) noHEADER STUDY(passthru) ///
		/// ^^ undocumented options (for use with e.g. -ipdmetan- )
		* ]											// all other options, to be parsed later
	
	local ifopt : copy local if		// for warning message regarding missing/insufficient data
	local inopt : copy local in		// for warning message regarding missing/insufficient data

	marksample touse, novarlist		// `novarlist' option so that entirely missing/nonexistent studies/subgroups may be included
	local invlist `varlist'			// list of "original" vars passed by the user to the program 

	
	*******************
	* Initial parsing *
	*******************

	** Parse -forestplot- options to extract those relevant to -metan-
	// N.B. Certain options may be supplied EITHER to metan directly, OR as sub-options to forestplot()
	//  with "forestplot options" prioritised over "metan options" in the event of a clash.
	
	// These options are:
	// effect options parsed by CheckOpts (e.g. `rr', `rd', `md', `smd', `wmd', `log')
	// nograph, nohet, nooverall, nosubgroup, nowarning, nowt, nostats
	// effect, hetinfo, lcols, rcols, plotid, ovwt, sgwt, sgweight
	// cumulative, efficacy, influence, interaction
	// counts, group1, group2 (for compatibility with previous version of metan.ado)
	// rfdist, rflevel (for compatibility with previous version of metan.ado)

	// N.B. if -metan- was called by -ipdmetan- , some of this may already have been done

	cap nois ParseFPlotOpts, cmdname(`cmdname') mainprog(metan) options(`options') `forestplot'
	if _rc {
		if `"`err'"'==`""' {
			if _rc==1 nois disp as err `"User break in {bf:metan.ParseFPlotOpts}"'
			else nois disp as err `"Error in {bf:metan.ParseFPlotOpts}"'
		}
		c_local err noerr		// if called by -ipdmetan- , no need to also report an "error in {bf:metan}"
		exit _rc
	}
	
	local eform    `s(eform)'
	local log      `s(log)'
	local summstat `s(summstat)'
	local effect     `"`s(effect)'"'
	local opts_adm   `"`s(opts_parsed)' `s(options)'"'		// options as listed above, plus other options supplied directly to -metan-
	local opts_fplot `"`s(opts_fplot)'"'					// other options supplied as sub-options to forestplot()
	
	
	****************************************
	* Establish basic data characteristics *
	****************************************
	
	// Generate stable ordering to pass to future subroutines
	tempvar obs
	qui gen long `obs' = _n


	** Parse `study' and `by'
	// Checks for problems with `study' and `by'
	//  and, amongst other things, converts them from string to numeric if necessary
	tempname newstudylab newbylab
	tempvar  newstudy    newby	
	
	// Before proceeding, extract `lcols' and `denominator' from list of options
	//  - First element of `lcols' might be used to label studies
	// May 2020: also sort out `ilevel' and `olevel'
	local 0 `", `opts_adm'"'
	syntax [, LCols(passthru) ILevel(passthru) OLevel(passthru) LEVEL(passthru) * ]
	local opts_adm `"`macval(options)'"'

	if `"`level'"'!=`""' {
		if `"`ilevel'"'!=`""' {
			nois disp as err "Cannot specify both {bf:level()} and {bf:ilevel()}"
			exit 184
		}
		if `"`olevel'"'!=`""' {
			nois disp as err "Cannot specify both {bf:level()} and {bf:olevel()}"
			exit 184			
		}
		local ilevel `"i`level'"'
		local olevel `"o`level'"'
		local level
	}
	
	cap nois ProcessLabels `invlist' if `touse', sortby(`sortby' `obs') ///
		`study' `label' `by' `lcols' ///
		newstudy(`newstudy')       newby(`newby') ///
		newstudylab(`newstudylab') newbylab(`newbylab')
	
	if _rc {
		if _rc==1 nois disp as err `"User break in {bf:metan.ProcessLabels}"'
		else nois disp as err `"Error in {bf:metan.ProcessLabels}"'
		c_local err noerr
		exit _rc
	}
	
	// In case `lcols' has been modified, return it back to list of options
	if `"`s(lcols)'"'!=`""' local opts_adm `"`macval(opts_adm)' lcols(`s(lcols)')"'
	local _STUDY `s(study)'
	local _BY `s(by)'
	local bymissing `s(bymissing)'
	local sfmtlen sfmtlen(`s(sfmtlen)')
	
	if `"`s(smissing)'"'==`""'  markout `touse' `_STUDY'
	if `"`_BY'"'!=`""' {
		if `"`s(bymissing)'"'==`""' markout `touse' `_BY'
	}
	// `_STUDY' and `_BY' are the "working" variables from now on; guaranteed numeric.
	// We don't need `study' and `by' anymore; instead `_STUDY' and `_BY' indicate the existence of these variables (e.g. in validity checks).
	
	
	** Process `invlist' to finalise `summstat', and to establish method of constructing _ES, _seES
	// (and also detect observations with insufficient data; _USE==2)	
	if `"`use'"'!=`""' {				// e.g. if passed from -ipdmetan-
		local _USE : copy local use
		cap assert inlist(`_USE', 1, 2, 3, 5) if `touse'
		if _rc {
		    nois disp as err `"error in {bf:use}{it:varname}{bf:)}"'
			exit 198
		}
		local ifopt
		local inopt
		
		// re-define `touse' as if running -metan- directly; other values of _USE are not needed until BuildResultsSet
		tempvar touse_build
		qui gen byte `touse_build' = `touse'
		qui replace `touse' = `touse' * inlist(`_USE', 1, 2)
	}
	else {
		tempvar _USE							// Note that `_USE' is defined if-and-only-if `touse'
		qui gen byte `_USE' = 1 if `touse'		// i.e.  !missing(`_USE') <==> `touse'
		local touse_build `touse'
	}
	
	cap nois ProcessInputVarlist `_USE' `invlist' if `touse', ///
		summstat(`summstat') `eform' `log' `opts_adm'

	if _rc {
		if _rc==2000 nois disp as err "No studies found with sufficient data to be analysed"
		else if _rc==1 nois disp as err `"User break in {bf:metan.ProcessInputVarlist}"'
		else nois disp as err `"Error in {bf:metan.ProcessInputVarlist}"'
		c_local err noerr
		exit _rc
	}

	local opts_adm `"`s(options)'"'
	local user_effect : copy local effect
	if `"`user_effect'"'==`""' local effect `"`s(effect)'"'						// don't override user-specified value
		
	if `"`s(summorig)'"'!=`""' local summorig summorig(`s(summorig)')
	local summstat    `s(summstat)'
	local params    = `s(params)'
	local eform       `s(eform)'
	local log         `s(log)'
	local citype      `s(citype)'

	return local citype `citype'						// citype is now established
	
	// If 2x2 data, return tger and cger
	if `params'==4 {
		return scalar tger = `s(tger)'
		return scalar cger = `s(cger)'
		
		// Historical
		global S_13 = `s(tger)'
		global S_14 = `s(cger)'
	}

	
	** Identify models
	// Process meta-analysis modelling options
	// (random-effects, test & het stats, etc.)
	// Could be given in a variety of ways, e.g. stand-alone options, random(), second(), model() etc.
	cap nois ProcessModelOpts, `opts_adm' summstat(`summstat') `summorig' params(`params')
	if _rc {
		if `"`err'"'==`""' {
			if _rc==1 nois disp as err `"User break in {bf:metan.ProcessModelOpts}"'
			else nois disp as err `"Error in {bf:metan.ProcessModelOpts}"'
		}
		c_local err noerr
		exit _rc
	}

	local rownames     `s(rownames)'
	local modellist    `s(modellist)'
	local teststatlist `s(teststatlist)'
	local qstat        `s(qstat)'
	local wgtoptlist   `s(wgtoptlist)'		// to send to DrawTableAD
	local m = `s(m)'
	local labelopts  `"`s(labelopts)'"'		// [Nov 2020] list of labelling options
	local opts_adm   `"`s(opts_adm)'"'		// all other options (rationalised)

	gettoken model1 : modellist
	local UniqModels : list uniq modellist
	local RefFEModList peto mh iv mu			// fixed (common) effect models
	local RefREModList mp ml pl reml bt dlb		// random-effects models where a conf. interval for tausq is estimated

	return scalar m = `m'
	return local model `modellist'				// model(s) are now established
	forvalues j = 1 / `m' {
		local model`j'opts `"`s(model`j'opts)'"'
		if `m'==1 return local modelopts    `"`s(model`j'opts)'"'		// return model options
		else      return local model`j'opts `"`s(model`j'opts)'"'
	}

	if `"`s(summnew)'"'==`"or"' {
		local summstat or
		if `"`user_effect'"'==`""' local effect `"Odds Ratio"'
	}
	if "`summstat'"!="" {			// summstat is now established (though can be missing, e.g. if "generic" input varlist)
		if      "`summstat'"=="cohend"  local measure "Cohen's d SMD"
		else if "`summstat'"=="glassd"  local measure "Glass's delta SMD"
		else if "`summstat'"=="hedgesg" local measure "Hedges's g SMD"
		else if "`summstat'"=="ftukey"  local measure "Freeman-Tukey transformed proportion"
		else if "`summstat'"=="arcsine" local measure "Arcsine-transformed proportion"
		else if "`summstat'"=="logit"   local measure "Logit-transformed proportion"
		else if "`summstat'"=="pr"      local measure "Untransformed proportion"
		else local measure = upper("`summstat'")
		return local measure `"`measure'"'
	}
	local first `s(first)'		// marker that first/main analysis is user-supplied
	
	// Return historical, from first() or second()
	local ES `s(ES)'
	local ci_low `s(ci_low)'
	local ci_upp `s(ci_upp)'

	local ES_2 `s(ES_2)'
	local ci_low_2 `s(ci_low_2)'
	local ci_upp_2 `s(ci_upp_2)'
	

	
	***************************************
	* Prepare for meta-analysis modelling *
	***************************************

	** Extract options relevant to PerformMetaAnalysis
	//  and carry out basic option compatibility checks
	local 0 `", `opts_adm'"'
	syntax [, CUmulative INFluence PRoportion ///
		noOVerall noSUbgroup noSECsub SUMMARYONLY INTERaction OVWt SGWt ALTWt ///
		LOGRank NPTS(string) noINTeger KEEPOrder KEEPAll noTABle noGRaph noHET noWT SAVING(passthru) ///
		noKEEPvars noRSample        		/// whether to leave behind study-estimate variables
		DF(passthru) TSQLEVEL(passthru) HLevel(passthru) RFLevel(passthru) DENOMinator(passthru) NOPR TESTBased ISQParam * ]

	// May 2020:
	// Restore -metan9- behaviour that noOVerall ==> noHET and noWT
	if `"`overall'"'!=`""' & !(`"`_BY'"'!=`""' & `"`subgroup'"'==`""') {
		local het nohet
		local wt nowt
	}
		
	if `"`hlevel'"'==`""' local hlevel : copy local tsqlevel	// TSQLEVEL is a legacy -admetan- synonym for HLEVEL	
	local keepvars = cond(`"`rsample'"'!=`""', `"nokeepvars"', `"`keepvars'"')			// noRSample implies noKEEPVars
	local opts_adm `"`macval(options)'"'	// remaining options
											// [note that npts(string) is NOT now part of `opts_adm'; it stands alone]	

	// ProcessInputVarlist has set studies with insufficient data to _USE==2
	// Having done so, we can form `bylist'
	local keepall_n = 0									// init
	if `"`keeporder'"'!=`""' local keepall keepall		// `keeporder' implies `keepall'
	if `"`keepall'"'==`""' {	
		// print warning of excluded studies (even if no header)
		// but defer printing until just before the header
		// so that other errors can take priority (and be clearly presented) in the meantime
		qui count if `touse' & `_USE'==2
		local keepall_n = r(N)
		qui replace `touse' = 0 if `_USE'==2
	}
	if `"`_BY'"'!=`""' {
		qui levelsof `_BY' if `touse', missing local(bylist)	// "missing" since `touse' should already be appropriate for missing yes/no
		local byopts `"by(`_BY') bylist(`bylist')"'				// [Mar 2020] Do this now, and pass `bylist' to all subsequent subroutines, to be consistent

		// Mar 2020: for statistical calculations (e.g. Qbet), want `nby' to reflect the number of subgroups *with data in*
		//  so restrict to `_USE'==1
		qui levelsof `_BY' if `touse' & `_USE'==1, missing local(bylist_use1)
	}
	
	// cumulative and influence
	// if `by', cumulative *must* be done by subgroup and not overall ==> nooverall is "compulsory"
	opts_exclusive `"`cumulative' `influence'"' `""' 184
	if `"`cumulative'"'!=`""' {
		if `"`subgroup'"'!=`""' {
			disp `"{error}Note: {bf:nosubgroup} is not compatible with {bf:cumulative} and will be ignored"'
			local subgroup
		}
		if `"`summaryonly'"'!=`""' {
			nois disp as err `"Options {bf:cumulative} and {bf:summaryonly} are not compatible"'
			exit 184
		}
		
		if `"`_BY'"'==`""' {
			if `"`overall'"'!=`""' {
				disp `"{error}Note: {bf:nooverall} is not compatible with {bf:cumulative} (unless with {bf:by()}) and will be ignored"'
				local overall
			}
		}
		else {
			if `"`overall'"'!=`""' {
				disp `"{error}Note: {bf:nooverall} is compulsory with {bf:cumulative} and {bf:by()}"'
			}
		}
	}
	else if `"`influence'"'!=`""' & `"`summaryonly'"'!=`""' {
		disp `"{error}Note: {bf:influence} is not compatible with {bf:summaryonly} and will be ignored"'
		local influence
	}
	
	// Multiple models cannot be specified with cumulative or influence (for simplicity)
	if `"`cumulative'`influence'"'!=`""' {
		if `m' > 1 {
			nois disp as err `"Option {bf:`cumulative'`influence'} cannot be specified with multiple pooling methods"'
			exit 184
		}
		if "`model1'"=="user" {
			nois disp as err "Cannot use option {bf:`cumulative'`influence'} with user-defined main analysis"
			exit 184
		}
	}
	
	// Compatibility tests for ovwt, sgwt, altwt
	// [modified Jan 2020]
	opts_exclusive `"`ovwt' `sgwt'"' `""' 184
	if `"`_BY'"'==`""' {
		if `"`subgroup'"'!=`""' {
			disp `"{error}Note: {bf:nosubgroup} cannot be specified without {bf:by()} and will be ignored"' 
			local subgroup
		}
	
		if `"`sgwt'"'!=`""' {
			disp `"{error}Note: {bf:sgwt} is not applicable without {bf:by()} and will be ignored"'
			local sgwt
		}
		local ovwt ovwt		
	}
	else {
		if `"`cumulative'`influence'"'==`""' {		// default handling of sgwt and ovwt
			if `"`ovwt'`sgwt'"'==`""' {
				if `"`overall'"'!=`""' & `"`subgroup'"'==`""' local sgwt sgwt
				else local ovwt ovwt
			}
		}
		else if `"`cumulative'"'!=`""' {
			if `"`ovwt'"'!=`""' disp `"{error}Note: {bf:ovwt} is not compatible with {bf:cumulative} and {bf:by()}, and will be ignored"'
			local ovwt
			local sgwt sgwt
		}
		else {
			// If `influence', `nooverall' and `sgwt' are synonyms
			// ...and `nosubgroup' and `ovwt' are synonyms
			if `"`overall'"'!=`""'  & `"`subgroup'"'!=`""' {
				nois disp as err `"With {bf:influence}, only one of {bf:nooverall} or {bf:nosubgroup} is allowed"'
				exit 184
			}
			if `"`overall'"'!=`""'  | `"`sgwt'"'!=`""' {
				local overall nooverall
				local sgwt sgwt
			}
			else {
				local subgroup nosubgroup
				local ovwt ovwt
			}
		}

		if "`model1'"=="user" {
			nois disp as err "Cannot use option {bf:by()} with user-defined main analysis"
			exit 184
		}
	}	
	if `"`altwt'"'!=`""' & `"`cumulative'`influence'"'==`""' {
		disp `"{error}Note: {bf:altwt} is not applicable without {bf:cumulative} or {bf:influence}, and will be ignored"'
		local altwt
	}	

	// proportions
	if `"`denominator'"'!=`""' {
		if `"`proportion'"'==`""' {
			nois disp as err `"Cannot specify {bf:denominator(}#{bf:)} without {bf:proportion}"'
			exit 184
		}
		if `"`nopr'"'!=`""' {
			nois disp as err `"Cannot specify both {bf:nopr} and {bf:denominator(}#{bf:)}"'
			exit 184
		}
	}
	if `"`nopr'"'!=`""' & `"`proportion'"'==`""' {
		nois disp as err `"Cannot specify {bf:nopr} without {bf:proportion}"'
		exit 184
	}
	
	// [SEP 2020:] error message relating to `isqparam'
	if "`isqparam'"!="" {
		local notsqb peto mh iv mu user
		if `"`: list modellist - notsqb'"'==`""' {
			disp "{error}Note: heterogeneity measures based on tau{c 178} and sigma{c 178} cannot be estimated under " _c
			if `m'==1 disp `"{error}the specified model; {bf:isqparam} will be ignored"'
			else disp `"{error}any of the specified models; {bf:isqparam} will be ignored"'
			local isqparam
		}
	}


	** Setup tempvars
	// The "core" elements of `outvlist' are _ES, _seES, _LCI, _UCI, _WT and _NN
	// By default, these will be left behind in the dataset upon completion of -metan-
	
	// _ES, _seES, _LCI and _UCI are *always* on the linear/interval scale, for pooling
	//   and so may need to be back-transformed to the original scale for display on-screen or in the forestplot.
	// Typically this just involves exponentiating; but for proportions using e.g. Freeman-Tukey,
	//   the back-transform is too complex, so we create separate variables _Prop_ES, _Prop_LCI, _Prop_UCI
	//   containing the proportion and CI on the original scale.
	// `tvlist' = list of elements of `outvlist' that need to be generated as *tempvars* (i.e. do not already exist)
	//  (whilst ensuring that any overlapping elements in `invlist' and `outvlist' point to the same actual variables)
	tokenize `invlist'
	local params : word count `invlist'
	
	// Process "npts(varname)": only permitted with 2- or 3-element varlist AD;
	// that is, "ES, seES", "ES, LCI, UCI", or "OE, V"
	if `"`npts'"'!=`""' {
		if `params' > 3 | "`proportion'"!="" {
			nois disp as err `"option {bf:npts(}{it:varname}{bf:)} syntax only valid with generic inverse-variance model or with logrank (O-E & V) HR"'
			exit 198
		}
		
		local old_integer `integer'
		local 0 `"`npts'"'
		syntax varname(numeric) [, noPlot noINTeger]
		local _NN `varlist'													// the varname which was stored in npts(varname) will now be stored in _NN
		if `"`integer'"'==`""' local integer `old_integer'
		
		if `"`integer'"'==`""' {
			cap assert int(`_NN')==`_NN' if `touse'
			if _rc {
				nois disp as err `"Non-integer counts found in {bf:npts()} option"'
				exit _rc
			}
		}
		if `"`plot'"'==`""' local opts_adm `"`macval(opts_adm)' npts"'		// send simple on/off option to BuildResultsSet (e.g. for forestplot)
	}
	
	if `"`logrank'"'!=`""' local tvlist _ES _seES _LCI _UCI
	else if "`proportion'"!="" {
		args succ _NN
		local tvlist _ES _seES _LCI _UCI
		tempvar ccvar
		local ccvaropt ccvar(`ccvar')
		
		if "`summstat'"!="pr" & "`nopr'"=="" {
			forvalues i = 1 / 3 {
				tempvar prv`i'
				qui gen double `prv`i'' = .
				local prvlist `prvlist' `prv`i''
			}
			local prv_opt prvlist(`prvlist')
		}
	}
	else if `params'==2 {
		args _ES _seES						// `_ES' and `_seES' supplied
		local tvlist _LCI _UCI				// `_LCI', `_UCI' need to be created (at `ilevel'%)
	}
	else if `params'==3 {
		args _ES _LCI _UCI					// `_ES', `_LCI' and `_UCI' supplied (assumed 95% CI)
		
		local tvlist _seES						// `_seES' needs to be created
		if `"`ilevel'"'!=`""' {					// but if ilevel() option supplied, requesting coverage other than 95%
			local tvlist `tvlist' _LCI _UCI		// then tempvars for _LCI, _UCI are needed too
		}
	}
	else {			// `params'==4 or 6
		local tvlist _ES _seES _LCI _UCI _NN		// need to create everything, including _NN ...
		if `params'==4 {							// ... and, if 2x2 data, _CC (for continuity correction)
			tempvar ccvar
			local ccvaropt ccvar(`ccvar')
		}
	}		
	
	// Finally, _WT always needs to be generated as tempvar
	local tvlist `tvlist' _WT
	
	// Create tempvars based on `tvlist'
	//   and finally create `outvlist' = list of "standard" vars = _ES, _seES, _LCI, _UCI, _WT, [_NN]
	//   where _NN is optional if `params'==2 or 3 (excluding `proportion'; see above).
	foreach tv of local tvlist {
		tempvar `tv'
		qui gen double ``tv'' = .
	}
	local outvlist `_ES' `_seES' `_LCI' `_UCI' `_WT' `_NN'

	// If cumulative or influence, need to generate additional tempvars.
	// `xoutvlist' ("extra" outvlist) contains results of each individual analysis
	//   to be printed to screen, displayed in forestplot and stored in saved dataset.
	//   (plus Q, tausq, sigmasq, df from each analysis.)
	// Meanwhile `outvlist' contains effect sizes etc. for each individual *study*, as usual,
	//   which will be left behind in the current dataset.
	if `"`cumulative'`influence'"'!=`""' {
		local npts_el npts
		local xrownames : copy local rownames
		local xrownames : list xrownames - npts_el
		local xrownames `xrownames' Q Qdf Q_lci Q_uci
		if `: list posof "tausq" in rownames' local xrownames `xrownames' sigmasq
		local xrownames `xrownames' _WT2
		
		local nt = `: word count `xrownames''
		forvalues i = 1 / `nt' {
			tempvar tv`i'
			qui gen double `tv`i'' = .
			local xoutvlist `xoutvlist' `tv`i''
		}
		local xv_opt xoutvlist(`xoutvlist')
	}
	// N.B. `xoutvlist' now contains the tempvars which will hold the relevant returned stats...
	//  - with the same contents as the elements of `rownames'
	//  - but *without* npts (as _NN is handled separately)
	//  - and with the addition of Q, Qdf, Q_lci, Q_uci, [sigmasq]
	//  - and with the addition of a separate weight variable (`_WT2')

	// Subsequently, `rownames' will be passed between subroutines
	// and `xrownames' will be re-derived whenever needed
	// by taking `rownames' and applying the "algorithm" above.

	
	
	******************************************
	* Run the actual meta-analysis modelling *
	******************************************
	
	// Now, first model is "primary" and will be displayed on screen and in forest plot
	//  options such as `ovwt', `sgwt', `altwt' apply here
	// Remaining models are simply fitted, and results saved (in matrices ovstats and bystats).	
	
	// Hence, loop over models *backwards* so that "primary" model is done last
	//  and hence "correct" outvlist is left behind

	local nrfd = 0		// initialize marker of "less than 3 studies" (for rfdist)
	local nmiss = 0		// initialize marker of "pt. numbers are missing in one or more trials"
	local nsg = 0		// initialize marker of "only a single valid estimate" (e.g. for by(), or cumul/infl)
	local nzt = 0		// initialize marker of "HKSJ has resulted in a shorter CI than IV" (for HKSJ)
	
	// Before looping, create list of unique colnames
	//  (e.g. if same basic model is run twice, with different options)
	local c = 0
	local rest : copy local modellist
	while `"`rest'"'!=`""' {
		local ++c
		gettoken model rest : rest
			
		// append HKSJ if appropriate, since this is a commonly-used option
		// clearer for users to see labelling e.g. "dl; dl_hksj" rather than "dl_1; dl_2"
		if `: list posof "hksj" in model`c'opts' local model `model'_hksj
				
		// similarly for robust variance estimator
		if `: list posof "robust" in model`c'opts' local model `model'_robust
		
		// similarly for REML Kenward-Roger correction
		if `: list posof "kroger" in model`c'opts' local model `model'_kr

		// similarly for PL likelihood corrections
		if "`model'"=="pl" {
			if `: list posof "bartlett" in model`c'opts' local model `model'_bart
			if `: list posof "skovgaard" in model`c'opts' local model `model'_skov
		}
		
		if `: list model in mcolnames' {
			local j=2
			local newname `model'_`j'
			while `: list newname in mcolnames' {
				local ++j
				local newname `model'_`j'
			}
			local mcolnames `mcolnames' `newname'
			if "`model'"!="user" local hetcolnames `hetcolnames' `newname'
		}
		else {
			local mcolnames `mcolnames' `model'
			if "`model'"!="user" local hetcolnames `hetcolnames' `model'
		}
		// [Nov 2020:] Note: this forms a copy of `mcolnames' for matrix `hetstats', called `hetcolnames'
	}
	
	// [Nov 2020:] If duplicate, e.g. dl dl_2: rename e.g. dl to dl_1
	foreach name of local mcolnames {
		if substr("`name'", -2, 2)=="_2" {
			local name_orig = substr("`name'", 1, `=length("`name'")-2')
			local mcolnames   = subinstr("`mcolnames'",   "`name_orig'", "`name_orig'_1", 1)
			local hetcolnames = subinstr("`hetcolnames'", "`name_orig'", "`name_orig'_1", 1)
		}
	}

	tempname checkmat ovstats hetstats mwt
	forvalues j = `m' (-1) 1 {
		local first  = cond(`j'==1, "first", "")		// marker of this being the first (aka main, aka primary) model
		local tb_opt = cond(`j'==1, "`testbased'", "")	// only first model can use `testbased' option
		
		local model    : word `j' of `modellist'
		local teststat : word `j' of `teststatlist'
		
		cap nois PerformMetaAnalysis `_USE' `invlist' if `touse', sortby(`sortby' `obs') `byopts' ///
			summstat(`summstat') model(`model') teststat(`teststat') qstat(`qstat') `model`j'opts' ///
			outvlist(`outvlist') rownames(`rownames') `xv_opt' ///
			`cumulative' `influence' `proportion' `overall' `subgroup' `secsub' ///
			`ovwt' `sgwt' `altwt' `ccvaropt' `integer' ///
			`logrank' `ilevel' `olevel' `hlevel' `rflevel' `first' `isqparam' `tb_opt'

		if _rc {
			if `"`err'"'==`""' {
				if _rc==1 nois disp as err `"User break in {bf:metan.PerformMetaAnalysis}"'
				else nois disp as err `"Error in {bf:metan.PerformMetaAnalysis}"'
			}
			c_local err noerr
			
			if _rc==2002 & `j'==1 return add
			
			exit _rc
		}
		
		// create matrices of pooled results
		if "`model'"!="user" {
			local mcolname : word `j' of `mcolnames'
		
			// if (`"`overall'"'==`""' | `"`ovwt'"'!=`""') {
			if `"`overall'"'==`""' {
				matrix define `checkmat' = r(ovstats)
				cap assert rowsof(`checkmat') > 1
				if _rc {
					nois disp as err `"Matrix r(ovstats) could not be created"'
					nois disp as err `"Error in {bf:metan.PerformMetaAnalysis}"'
					c_local err noerr
					exit _rc
				}
				if `nsg' mat colnames `checkmat' = iv
				else mat colnames `checkmat' = `mcolname'
				matrix define `ovstats' = `checkmat', nullmat(`ovstats')
				
				local rownames_reduced_new `"`r(rownames_reduced)'"'
				local rownames_reduced : list rownames_reduced | rownames_reduced_new
			// }

				// [SEP 2020:] matrices containing "parametrically-defined" het. statistics
				if `"`r(hetstats)'"'!=`""' {
					matrix define `checkmat' = r(hetstats)
					matrix define `hetstats' = `checkmat', nullmat(`hetstats')
				}
			}
			
			// if ((`"`by'"'!=`""' & `"`subgroup'"'==`""') | `"`sgwt'"'!=`""') {
			if `"`by'"'!=`""' & `"`subgroup'"'==`""' {
				if `m' > 1 local jj = `j'
				tempname bystats`jj'
				matrix define `bystats`jj'' = r(bystats)
				cap assert rowsof(`bystats`jj'') > 1
				if _rc {
					nois disp as err `"Matrix {bf:r(bystats`jj')} could not be created"'
					nois disp as err `"Error in {bf:metan.PerformMetaAnalysis}"'
					c_local err noerr
					exit _rc
				}
				if `nsg' {
					local bylist : coleq `bystats`jj''
					local nsg_list `r(nsg_list)'
					local newmcols
					
					foreach el of numlist `bylist' {
						if `: list el in nsg_list' local newmcols `newmcols' iv
						else local newmcols `newmcols' `mcolname'
					}
					
					mat colnames `bystats`jj'' = `newmcols'
				}
				else mat colnames `bystats`jj'' = `mcolname'
				return matrix bystats`jj' = `bystats`jj'', copy
				local bystatslist `bystats`jj'' `bystatslist'		// form list in reverse order
				
				// Model-specific subgroup weights
				matrix define `mwt' = r(mwt) \ nullmat(`mwt')
				
				// [SEP 2020:] matrices containing "parametrically-defined" het. statistics
				if `"`r(byhet)'"'!=`""' {
					tempname byhet`jj'
					matrix define `byhet`jj'' = r(byhet)
					return matrix byhet`jj' = `byhet`jj'', copy
					local byhetlist `byhet`jj'' `byhetlist'			// form list in reverse order
				}
			}
		}		// end if "`model'"!="user"
	}		// end forvalues j = `m' (-1) `1'

	cap {
		confirm matrix `ovstats'
		assert rowsof(`ovstats') > 1
	}
	if !_rc {
		// reduce rows if necessary
		local rownames_ov : rownames `ovstats'
		assert `: word count `rownames_ov'' >= `: word count `rownames_reduced''
		if `: word count `rownames_ov'' > `: word count `rownames_reduced'' {
			tempname ovstats_temp
			local r = rowsof(`ovstats')
			forvalues i = 1 / `r' {
				local rn : word `i' of `rownames_ov'
				if `: list rn in rownames_reduced' {
					matrix define `ovstats_temp' = nullmat(`ovstats_temp') \ `ovstats'[`i', 1...]
				}
			}
			matrix rownames `ovstats_temp' = `rownames_reduced'
			matrix colnames `ovstats_temp' = `: colnames `ovstats''
			matrix define `ovstats' = `ovstats_temp'
		}
		return matrix ovstats = `ovstats', copy
	}
	else local ovstats		// marker of whether (valid) matrix exists

	// SEP 2020: Same for `hetstats'
	cap {
		confirm matrix `hetstats'
		assert rowsof(`hetstats') > 1
	}
	if !_rc {
		// reduce rows if necessary
		// if no models which estimate tausq CIs, just keep rows containing point estimates
		if `"`: list UniqModels & RefREModList'"'==`""' {		// RefREModList = mp ml pl reml bt dlb
			matrix `hetstats' = `hetstats'[rownumb(`hetstats', "tausq"), 1...] \ `hetstats'[rownumb(`hetstats', "H"), 1...] ///
				\ `hetstats'[rownumb(`hetstats', "Isq"), 1...] \ `hetstats'[rownumb(`hetstats', "HsqM"), 1...]
		}
		matrix colnames `hetstats' = `hetcolnames'
		return matrix hetstats = `hetstats', copy
	}
	else local hetstats		// marker of whether (valid) matrix exists
	
	// Sep 2020:  Q statistics
	local qlist `r(Q)' `r(Qdf)' `r(Q_lci)' `r(Q_uci)'
	if `"`by'"'!=`""' & `"`subgroup'"'==`""' {
		tempname byQ
		matrix `byQ' = r(byQ)
		
		// `byQ' contains subgroup-Q values from *first* model
		// If this model is common-effect,  Q_lci will be from non-central chisq; label with "fe"
		// If this model is random-effects, Q_lci will be from Gamma; label with "re"
		if `: list model1 in RefFEModList' matrix colnames `byQ' = fe
		else if "`model1'"=="user" local colnames `byQ' = user
		else matrix colnames `byQ' = re
		return matrix byQ = `byQ', copy
		local qlist `qlist' `r(Qsum)' `r(Qbet)'
	}
	
	
	
	*** RETURN STATISTICS
	
	// Display error messages relating to subgroups; each unique error message is only displayed once
	if (`"`by'"'!=`""' & `"`subgroup'"'==`""') | `"`sgwt'"'!=`""' {
		if `nrc_2000'    disp `"{error}Note: insufficient data in one or more subgroups"'
		if `nrc_2002' {
			if "`model1'"=="mh" {
				disp `"{error}Note: in one or more subgroups, all studies have zero events in the same arm"'
				disp `"{error} so that the subgroup pooled effect is undefined without continuity correction"'
			}
			else disp `"{error}Note: pooling failed in one or more subgroups"'
		}
		if `nrc_tausq'   disp `"{error}Note: tau{c 178} point estimate not successfully estimated in one or more subgroups"'
		if `nrc_tsq_lci' disp `"{error}Note: tau{c 178} lower confidence limit not successfully estimated in one or more subgroups"'
		if `nrc_tsq_uci' disp `"{error}Note: tau{c 178} upper confidence limit not successfully estimated in one or more subgroups"'
		if `nrc_eff_lci' disp `"{error}Note: lower confidence limit of effect size not successfully estimated in one or more subgroups"'
		if `nrc_eff_uci' disp `"{error}Note: upper confidence limit of effect size not successfully estimated in one or more subgroups"'
	}
	if "`rfdist'"!="" {
		if `nrfd' disp `"{error}Note: Predictive intervals are undefined if less than three studies"'
	}

	// Collect numbers of studies and patients (relevant to "primary" model)
	tempname k totnpts
	scalar `k' = r(k)
	scalar `totnpts' = r(n)
	return scalar k = r(k)
	return scalar n = r(n)
	
	// Subgroup statistics
	if `"`_BY'"'!=`""' {
		
		// Mar 2020: want `nby' to reflect the number of subgroups *with data in*
		//  so restrict to `_USE'==1
		local nby_use1 : word count `bylist_use1'
		return scalar nby = `nby_use1'

		// Subgroup heterogeneity
		if `"`subgroup'"'==`""' {
			return scalar Qbet = `r(Qbet)'		// between-subgroup heterogeneity [Jan 2020]

			if "`model1'"=="iv" & `"`ovstats'"'!=`""' {
				tempname Fstat
				// tempname Qdf Fstat
				// scalar `Qdf' = `ovstats'[rownumb(`ovstats', "df"), 1]
				scalar `Fstat' = (`r(Qbet)'/(`nby_use1' - 1)) / (`r(Qsum)'/(`r(Qdf)' - `nby_use1' + 1))
				// ^^ Amended Jan 2020 to use Qbet rather than Qdiff
				return scalar Qsum  = `r(Qsum)'
				return scalar F = `Fstat'
			}
		}

		// June 2020: "common" tausq across subgroups
		if !missing(r(tausq)) return scalar tsq_common = r(tsq_common)
	}
	
	// Return other scalars (relevant to "primary" model)
	//  some of which are also saved in r(ovstats)
	if `"`ovstats'"'!=`""' {
		return scalar eff    = r(eff)
		return scalar se_eff = r(se_eff)
		return scalar Q_uci = r(Q_uci)
		return scalar Q_lci = r(Q_lci)
		return scalar Q     = r(Q)
		return scalar Isq  = r(Isq)
		return scalar H    = r(H)
		return scalar HsqM = r(HsqM)
	
		if `"`proportion'"'!=`""' & `"`nopr'"'==`""' {
			return scalar prop_eff = r(prop_eff)
			return scalar prop_lci = r(prop_lci)
			return scalar prop_uci = r(prop_uci)
		}
		
		if `params'==4 {
			if !missing(r(RR)) return scalar RR = r(RR)
			if !missing(r(OR)) return scalar OR = r(OR)
		}
	
		if !missing(`ovstats'[rownumb(`ovstats', "tausq"), 1]) {
			return scalar Hstar = r(Hstar)
			return scalar tausq = r(tausq)
			return scalar sigmasq = r(sigmasq)
			
			// May 2020: Qr deprecated in favour of Hstar: latter is more interpretable, and has appeared in print
			// (van Aert & Jackson 2019)
			return `historical' scalar Qr = r(Qr)
		}

		if `: list model1 in RefREModList' {
			return scalar tsq_var    = r(tsq_var)
			return scalar rc_tsq_lci = r(rc_tsq_lci)
			return scalar rc_tsq_uci = r(rc_tsq_uci)
			
			if "`model'"=="pl" {
				return scalar rc_eff_lci = r(rc_eff_lci)
				return scalar rc_eff_uci = r(rc_eff_uci)
			}
			if inlist("`model1'", "qprofile", "bt") {
				return scalar rc_tausq = r(rc_tausq)
			}
			else {
				return scalar converged = r(converged)
			}
		}
	}

	// User-defined estimates via "legacy" -metan- options first() and/or second()
	// These values were returned by subroutine ProcessModelOpts
	// (N.B. value of `olduser' is set via c_local)
	if "`olduser'"!="" & "`model1"=="user" {		// first(es lci uci)
		return `historical' scalar ES = `ES'
		return `historical' scalar ci_low = `ci_low'
		return `historical' scalar ci_upp = `ci_upp'
		
		global S_1 = `ES'
		global S_3 = `ci_low'
		global S_4 = `ci_upp'

		if "`: word 2 of `modellist''"=="user" {	// second(es lci uci)
			return `historical' scalar ES_2 = `ES_2'
			return `historical' scalar ci_low_2 = `ci_low_2'
			return `historical' scalar ci_upp_2 = `ci_upp_2'
		}
	}
	
	else {
		if "`eform'"!="" {
			return `historical' scalar ES = exp(r(eff))
			return `historical' scalar selogES = r(se_eff)
			return `historical' scalar ci_low = exp(r(eff_lci))
			return `historical' scalar ci_upp = exp(r(eff_uci))
			
			global S_1 = exp(r(eff))
			global S_2 =     r(se_eff)
			global S_3 = exp(r(eff_lci))
			global S_4 = exp(r(eff_uci))
			
			if "`olduser'"!="" {
			    if "`: word 2 of `modellist''"=="user" {		// second(es lci uci)
					return `historical' scalar ES_2 = `ES_2'
					return `historical' scalar ci_low_2 = `ci_low_2'
					return `historical' scalar ci_upp_2 = `ci_upp_2'
				}
				else if `m'==2 {			// if `second' is a model name e.g. "second(random)"
					return `historical' scalar ES_2      = exp(`ovstats'[rownumb(`ovstats', "eff"), 2])
					return `historical' scalar selogES_2 =     `ovstats'[rownumb(`ovstats', "se_eff"), 2]
					return `historical' scalar ci_low_2  = exp(`ovstats'[rownumb(`ovstats', "eff_lci"), 2])
					return `historical' scalar ci_upp_2  = exp(`ovstats'[rownumb(`ovstats', "eff_uci"), 2])
				}
			}
		}
		else {
			return `historical' scalar ES = r(eff)
			return `historical' scalar seES = r(se_eff)
			return `historical' scalar ci_low = r(eff_lci)
			return `historical' scalar ci_upp = r(eff_uci)

			global S_1 = r(eff)
			global S_2 = r(se_eff)
			global S_3 = r(eff_lci)
			global S_4 = r(eff_uci)
			
			if "`olduser'"!="" {
			    if "`: word 2 of `modellist''"=="user" {		// second(es lci uci)
					return `historical' scalar ES_2 = `ES_2'
					return `historical' scalar ci_low_2 = `ci_low_2'
					return `historical' scalar ci_upp_2 = `ci_upp_2'
				}
				else if `m'==2 {				// if `second' is a model name e.g. "second(random)"
					return `historical' scalar ES_2     = `ovstats'[rownumb(`ovstats', "eff"), 2]
					return `historical' scalar seES_2   = `ovstats'[rownumb(`ovstats', "se_eff"), 2]
					return `historical' scalar ci_low_2 = `ovstats'[rownumb(`ovstats', "eff_lci"), 2]
					return `historical' scalar ci_upp_2 = `ovstats'[rownumb(`ovstats', "eff_uci"), 2]
				}
			}
		}
		global S_7 = r(Q)
		global S_8 = r(Qdf)
		global S_9 = chi2tail(r(Qdf), r(Q))	
		global S_51 = r(Isq)
	}
	
	// if "`second'"!="" {
	if "`olduser'"!="" & `m'==2 {		// NOV 2020
		tokenize `modellist'
		if `"`3'"'!=`""' {
			nois disp as err "Invalid use of option {bf:second()}"
			exit 198
		}
		forvalues i = 1/2 {
			if "``i''"=="mh" local method_`i' "M-H"
			else if "``i''"=="peto" local method_`i' "Peto"
			else if "``i''"=="iv" local method_`i' "I-V"
			else if "``i''"=="dl" local method_`i' "D+L"
			else if "``i''"=="user" local method_`i' "USER"
			else {
				nois disp as err "Invalid use of option {bf:second()}"
				exit 198
			}
			if `i'==1 & "`userwgt'"!="" local method_1 "*"
			return `historical' local method_`i' `method_`i''
		}
	}

	if !missing(r(z)) {
		return `historical' scalar z = r(z)
		return `historical' scalar p_z = r(pvalue)
		global S_5 = abs(r(z))
		global S_6 = r(pvalue)		
	}
	return `historical' scalar i_sq = r(Isq)
	return `historical' scalar het = r(Q)
	return `historical' scalar df = r(Qdf)
	return `historical' scalar p_het = chi2tail(r(Qdf), r(Q))
	if !missing(r(chi2)) {
		return `historical' scalar chi2 = r(chi2)
		return `historical' scalar p_chi2 = chi2tail(1, r(chi2))
		global S_10 = r(chi2)
		global S_11 = chi2tail(1, r(chi2))
	}
	if !missing(r(tausq)) {
		return `historical' scalar tau2 = r(tausq)
		global S_12 = r(tausq)
	}
	// END OF RETURN HISTORICAL


	** Generate study-level CIs for "primary" model

	// We should now have _ES and _seES defined throughout.
	// [June 2020:] But if M-H / Peto used with zero cells, there may be studies with missing _ES or _seES (with _USE==1)
	//   (e.g. if primary model is IV)
	// In this case, also display message "...plus [x] studies with insufficient data for all models".
	// Otherwise (if M-H / Peto *not* used), set such studies to _USE==2.
	qui count if `touse' & `_USE'==1 & missing(`_ES', `_seES')
	local mhpeto mh peto
	if r(N) & `"`: list modellist & mhpeto'"'==`""' {
		qui replace `_USE' = 2 if `touse' & `_USE'==1 & missing(`_seES')
		if `"`keepall'"'==`""' qui replace `touse' = 0 if `_USE'==2
	}
	local esmiss = cond(`m'==1, 0, r(N))
	
	// Now generate the study-level CIs (unless pre-specified)
	cap nois GenConfInts `invlist' if `touse' & `_USE'==1, summstat(`summstat') ///
		citype(`citype') outvlist(`outvlist') `integer' `proportion' `prv_opt' `df' `ilevel'
	if _rc {
		nois disp as err `"Error in {bf:metan.GenConfInts}"'
		c_local err noerr
		exit _rc
	}
	
	// Now switch functions of `outvlist' and `xoutvlist',
	//  so that the cumul/infl versions of _ES, _seES etc. are stored in `outvlist' (so overwriting the "standard" _ES, _seES etc.)
	//  for display onscreen, in forest plot and in saved dataset.
	// Then `xoutvlist' just contains the remaining "extra" tempvars _tausq, _Q, _Qdf etc.
	if `"`xoutvlist'"'!=`""' {

		// Firstly, tidy up: If nokeepvars *and* altwt not specified, then we can drop
		//   any members of `outvlist' that didn't already exist in the dataset
		if `"`keepvars'"'!=`""' & `"`altwt'"'==`""' {
			foreach v of local outvlist {
				if `: list v in tvlist' {		// i.e. if `v' was created by either -ipdmetan- or -metan-
					drop ``v''
				}
			}
		}
		
		// [Mar 2020, modified Dec 2020:]
		// Recall that `xrownames' is derivable from `rownames'
		// BUT `rownames' may have been altered within PerformMetaAnalysis
		//  so (re-) obtain them from the matrices themselves and check for alterations
		local rownames
		cap local rownames : rownames `ovstats'
		if _rc cap local rownames : rownames `bystatslist'			// if `xoutvlist', multiple models not allowed
		if !_rc assert inlist(`: word count `bystatslist'', 0, 1)	// so `bystatslist' should contain (at most) a single element

		local npts_el npts
		local not_xrownames Q Qdf Q_lci Q_uci sigmasq _WT2		// these elements *only* appear in `xrownames', *never* in `rownames'
		local toremove : list xrownames - rownames
		local toremove : list toremove - not_xrownames
		local toremove : list toremove - npts_el			// June 2020: npts will be removed from `xoutvlist' *anyway*
															// ... (see note where xoutvlist tempvars are declared, and code a few lines below)	
		if `"`toremove'"'!=`""' {							// ... so don't also remove it here
			tokenize `xoutvlist'
			foreach el of local toremove {
				local i : list posof `"`el'"' in xrownames
				local xoutvlist : list xoutvlist - `i'
			}
		
			// Now rebuild `xrownames'
			local xrownames : list rownames - npts_el
			local xrownames `xrownames' Q Qdf Q_lci Q_uci
			if `: list posof "tausq" in rownames' local xrownames `xrownames' sigmasq
			local xrownames `xrownames' _WT2
		}
		
		assert `: word count `xoutvlist'' == `: word count `xrownames''		
		tokenize `xoutvlist'
		args `xrownames'
		
		// Finally, we can separate off `xoutvlist', and thereby reset `outvlist'
		local outvlist `eff' `se_eff' `eff_lci' `eff_uci' `_WT2' `_NN'
		local xoutvlist : list xoutvlist - outvlist
		local xv_opt xoutvlist(`xoutvlist')
		
		tokenize `outvlist'
		args _ES _seES _LCI _UCI _WT _NN
	}
	
	// Finally: unless `influence' + `by' + `sgwt' + subgroups with only a single study (see above),
	//   ...or if 2x2 data and M-H, or user-defined... (see above) [May 2020]
	// _ES and _seES should never be missing if _USE==1.
	if !(`"`influence'"'!=`""' & `"`sgwt'"'!=`""') & !`: list posof "mh" in modellist' {
		cap assert !missing(`_ES', `_seES') if `touse' & `_USE'==1
		if _rc {		// this should never happen
			nois disp as err "Error: effect size or standard error is unexpectedly missing"
			exit 198
		}
	}
	// N.B. At this point, data processing should be complete.
	// From now on, we will be *using* the data rather than processing it.

	

	********************************
	* Print summary info to screen *
	********************************

	// print deferred warning of excluded studies (even if no header)
	if `keepall_n' {
		local studies = cond(`keepall_n'==1, "study", "studies")
		local these   = cond(`keepall_n'==1, "this", "these")
		
		if `"`ifopt'`inopt'"'==`""' & `"`summaryonly'"'==`""' & (`"`table'"'==`""' | `"`graph'"'==`""') local colon `";"'

		disp `"{error}Note: `keepall_n' `studies' with missing or insufficient data found`colon'"'
		if `"`ifopt'`inopt'"'!=`""' disp `"{error} within the data range specified by [{it:if}] [{it:in}];"'
		if `"`summaryonly'"'==`""' & (`"`table'"'==`""' | `"`graph'"'==`""') {
			disp `"{error} use the {bf:{help metan##options_main:keepall}} option to include `these' `studies' in the "' _c
			if `"`table'"'==`""' {
				disp `"{error}summary table"' _c
				if `"`graph'"'==`""' disp `"{error} and forest plot"'
				else disp ""		// cancel _c
			}
			else {
				if `"`graph'"'==`""' disp `"{error}forest plot"'
				else disp ""		// cancel _c
			}
		}
	}	
	
	// Instead of passing `ovstats' and `bystats' to PrintDesc, pass "`pool'"=="nopool" if neither exist
	if `"`ovstats'`bystatslist'"'==`""' local pool nopool
	
	// For PrintDesc and DrawTableAD:
	// If first model uses continuity correction or user-defined weights, pass these to DrawTableAD
	
	// Print summary text
	if "`header'"=="" {
		disp _n _c
		disp as text "Studies included: " as res `k'
		qui count if `touse' & `_USE'==2
		if "`keepall'"!="" {
			if r(N) {
				local plural = cond(r(N)==1, "study", "studies")
				disp as text "  plus " as res `r(N)' as text " `plural' with insufficient data" _c
			}
			
			// June 2020
			if `esmiss' disp as text ","
			else disp ""	// cancel _c
		}
		if `esmiss' {
			local plural = cond(`esmiss'==1, "study", "studies")
			disp as text "  plus " as res `esmiss' as text " `plural' with insufficient data for inverse-variance models"
		}
		
		local dispnpts = cond(missing(`totnpts'), "Unknown", string(`totnpts'))
		disp as text "Participants included: " as res "`dispnpts'"
		if "`keepall'"!="" & !missing(`totnpts') & r(N) {
			summ `_NN' if `touse' & `_USE'==2, meanonly
			local dispnpts = cond(!r(N), "Unknown", string(`r(sum)'))
			local s = cond(r(sum)>1 | !r(N), "s", "")
			disp as text "  plus " as res "`dispnpts'" as text " participant`s' with insufficient data" _c
			
			// June 2020
			if `esmiss' disp as text ","
			else disp ""	// cancel _c
		}
		if `esmiss' {
			// `_NN' should always exist in this situation, since must be 2x2 count data
			summ `_NN' if `touse' & `_USE'==1 & missing(`_ES', `_seES'), meanonly
			disp as text "  plus " as res "`r(sum)'" as text " participant`s' with insufficient data for inverse-variance models"
		}		
		if "`npts'"!="" {
			if `nmiss' disp as text _n "Note: Patient numbers are missing in one or more trials"
		}
	}
	

	** Full descriptions of `summstat', `esmethod' and `model' options, for printing to screen	
	// Involves `opts_model', so pass to a subroutine	
	PrintDesc if `touse', summstat(`summstat') modellist(`modellist') wgtoptlist(`wgtoptlist') ///
		sortby(`sortby') /* N.B. not sortby(`sortby' `obs') here, as PrintDesc is purely descriptive */ ///
		`byopts' `pool' `ccvaropt' `model1opts' `altwt' `subgroup' `overall' ///
		`log' `logrank' `cumulative' `influence' `proportion' `summaryonly' `table' `graph' ///
		`mhallzero' `interaction' `ipdmetan' `estexp' `explist'
	
	if `"`s(fpnote)'"'!=`""' local fpnote `"fpnote(`s(fpnote)')"'

	if `nsg' & !inlist("`model'", "iv", "mh", "peto", "mu") {
		disp as text _n "Note: one or more subgroups contain only a single valid estimate;"
		disp as text "  common-effect models have been fitted in those subgroups,"
		if `"`influence'"'!=`""' & `"`sgwt'"'!=`""' {
			disp as text "  and {bf:influence} analysis cannot be done within them"
		}
	}

	

	*********************************
	* Print results table to screen *
	*********************************

	// Unless no table AND no graph AND no saving/clear, store study value labels in new var "_LABELS"
	if !(`"`table'"'!=`""' & `"`graph'"'!=`""' & `"`saving'"'==`""' & `"`clear'"'==`""') {
		tempvar _LABELS
		cap decode `_STUDY' if `touse_build', gen(`_LABELS')			// if value label
		// if _rc qui gen `_LABELS' = string(`_STUDY') if `touse_build'	// if no value label
		
		if _rc==182 qui gen `_LABELS' = ""								// if no value label
		else if _rc {
			decode `_STUDY' if `touse_build', gen(`_LABELS')			// otherwise force exit, with appropriate error message
		}
		
		qui replace `_LABELS' = strofreal(`_STUDY', `"`: format `_STUDY''"') if `touse_build' & missing(`_LABELS')
		// ^^ added Aug 2020;  if *some* values are labelled but *not* all, take the values themselves
		// -decode- replaces with missing if no label defined for a particular value
		// hence, use these lines regardless of whether a value label exists

		// missing values of `_STUDY'
		// string() works with ".a" etc. but not "." -- contrary to documentation??
		// qui replace `_LABELS' = "." if `touse_build' & missing(`_LABELS') & !missing(`_STUDY')

	}
	
	// Titles
	if `"`_BY'"'!=`""' {
		local byvarlab : variable label `_BY'
		if `"`byvarlab'"'==`""' local byvarlab Subgroup
		local bytitle `"`byvarlab' and "'
		local byopts `"`byopts' bystatslist(`bystatslist')"'
	}
	local svarlab : variable label `_STUDY'
	if `"`svarlab'"'==`""' {
		local svarlab = cond(`"`summaryonly'"'!=`""', `""', `"Study"')
	}
	local stitle `"`bytitle'`svarlab'"'
	if `"`influence'"'!=`""' local stitle `"`stitle' omitted"'

	if `"`effect'"'==`""'      local effect "Effect"
	if `"`log'"'!=`""'         local effect `"log `effect'"'
	if `"`interaction'"'!=`""' local effect `"Interact. `effect'"'	

	cap nois DrawTableAD `_USE' `outvlist' if `touse', sortby(`sortby' `obs') ///
		modellist(`modellist') teststatlist(`teststatlist') summstat(`summstat') ///
		qstat(`qstat') qlist(`qlist') byq(`byQ') hetstats(`hetstats') wgtoptlist(`wgtoptlist') ///
		`cumulative' `influence' `proportion' `overall' `subgroup' `secsub' `summaryonly' `ccvaropt' `prv_opt' `denominator' `nopr' ///
		labels(`_LABELS') stitle(`stitle') etitle(`effect') `model1opts' `labelopts' ///
		study(`_STUDY') `byopts' mwt(`mwt') ovstats(`ovstats') nzt(`nzt') `testbased' `isqparam' ///
		`ovwt' `sgwt' `eform' `table' `het' `wt' `keepvars' `keeporder' `ilevel' `olevel' `tsqlevel' `opts_adm'

	if _rc {
		nois disp as err `"Error in {bf:metan.DrawTableAD}"'
		c_local err noerr
		exit _rc
	}		
	
	if `"`r(coeffs)'"'!=`""' {
		tempname coeffs
		matrix `coeffs' = r(coeffs)
		return matrix coeffs = `coeffs'
	}

	
	
	********************************
	* Build forestplot results set *
	********************************
	
	* 1. Create the results-set structure
	//  (including some tempvars; hence the subroutine)
	* 2. Send the data to -forestplot- to create the forest plot
	* 3. Save the results-set (in Stata "dta" format)
	//  (after renaming tempvars to permanent names)
	//   and with characteristics set so that "forestplot, useopts" can be called.

	// default is to preserve data later, if forestplot/saving [UNLESS option -clear- is used!]
	if "`clear'"=="" & "`ipdmetan'"=="" local preserve preserve
	`preserve'
	
	// Store contents of existing characteristics
	//  with same names as those to be used by BuildResultsSet
	local char_fpuseopts  `"`char _dta[FPUseOpts]'"'
	local char_fpusevlist `"`char _dta[FPUseVarlist]'"'

	if `"`_STUDY'"'!=`""' {
		label variable `_STUDY' `"`svarlab'"'
	}
	if `"`_BY'"'!=`""' {
		label variable `_BY' `"`byvarlab'"'
	}

	cap nois BuildResultsSet `_USE' `invlist' if `touse_build', labels(`_LABELS') ///
		modellist(`modellist') summstat(`summstat') ///
		qstat(`qstat') qlist(`qlist') byq(`byQ') hetstats(`hetstats') byhetlist(`byhetlist') ///
		sortby(`sortby' `obs') study(`_STUDY') `byopts' mwt(`mwt') ovstats(`ovstats') ///
		`cumulative' `influence' `proportion' `subgroup' `overall' `secsub' `het' `wt' `summaryonly' ///
		`ovwt' `sgwt' `altwt' effect(`effect') `eform' `logrank' `ccvaropt' `model1opts' `labelopts' `isqparam' ///
		outvlist(`outvlist') `xv_opt' `prv_opt' `denominator' `nopr' `sfmtlen' ///
		forestplot(`opts_fplot' `interaction') `fpnote' `graph' `saving' `clear' ///
		`keepall' `keeporder' `ilevel' `olevel' `tsqlevel' `rflevel' `ipdmetan' `opts_adm'
	
	if _rc {
		if `"`err'"'==`""' {
			if _rc==1 nois disp as err `"User break in {bf:metan.BuildResultsSet}"'
			else nois disp as err `"Error in {bf:metan.BuildResultsSet}"'
			nois disp as err `"(Note: meta-analysis model was fitted successfully)"'
		}
		c_local err noerr
		local rc = _rc
						
		// in case *not* under -preserve- (e.g. if _rsample required)
		summ `_USE', meanonly
		if r(N) & r(max) > 9 {
			qui replace `_USE' = `_USE' / 10	// in case break was while _USE was scaled up -- see latter part of BuildResultsSet
		}
		qui drop if `touse' & !inlist(`_USE', 1, 2)
		
		// clear/restore characteristics
		char _dta[FPUseOpts]    `char_fpuseopts'
		char _dta[FPUseVarlist] `char_fpusevlist'
		exit `rc'
	}		// end if _rc	
		
	// Restore original data; but preserve it again temporarily while "stored" variables are processed
	//   if all goes well, this -preserve- will be cancelled later with -restore, not- ...
	if `"`preserve'"'!=`""' {
		restore, preserve
	}
	
	// exit early if no -preserve- (e.g. -clear- option, or if called from -ipdmetan- )
	if `"`preserve'"' == `""' exit

	
	** Stored (left behind) variables
	// Unless -noKEEPVars- (i.e. "`keepvars'"!=""), leave behind _ES, _seES etc. in the original dataset
	// List of these "permanent" names = _ES _seES _LCI _UCI _WT _NN ... plus _CC if applicable
	//   (as opposed to `outvlist', which contains the *temporary* names `_ES', `_seES', etc.)
	//   (N.B. this code applies whether or not cumulative/influence options are present)	
	if `"`keepvars'"'==`""' {

		// June 2020: _CC is defined within BuildResultsSet using c_local
		local tostore _ES _seES _LCI _UCI _WT _NN _CC
		
		foreach v of local tostore {
			if `"``v''"'!=`""' {
				if `"``v''"'!=`"`v'"' {		// If pre-existing var has the same name (i.e. was named _ES etc.), nothing needs to be done.
					cap drop `v'			// Else, first drop any existing var named _ES (e.g. left over from previous analysis)
				
					// If in `tvlist', we can directly rename
					if `: list v in tvlist' {
						qui rename ``v'' `v'
					}
					
					// Otherwise, ``v'' is a pre-existing var which needs to be retained at program termination
					// so, use -clonevar-
					else qui clonevar `v' = ``v'' if `touse'
				}
				local `v' `v'				// for use with subsequent code (local _ES now contains "_ES", etc.)
			}
			else cap drop `v'				// in any case, drop existing vars named _ES etc.
		}
		qui compress `tvlist'
		order `_ES' `_seES' `_LCI' `_UCI' `_WT' `_NN' `_CC' `_rsample', last
		
		// Obtain `ilevel' for labelling LCI/UCI
		local 0 `", `ilevel' `olevel'"'
		syntax [, ILevel(cilevel) OLevel(cilevel) ]
		char define `_LCI'[Level] `ilevel'
		char define `_UCI'[Level] `ilevel'
		char define `_LCI'[LevelPooled] `olevel'
		char define `_UCI'[LevelPooled] `olevel'

		// variable labels
		label variable `_ES' "Effect size"
		label variable `_seES' "Standard error of effect size"
		label variable `_LCI' "`ilevel'% lower confidence limit"
		label variable `_UCI' "`ilevel'% upper confidence limit"
		label variable `_WT' "% Weight"
		format `_WT' %6.2f
		if `"`_NN'"'!=`""' {
			label variable `_NN' "No. pts"
		}
		if `"`_CC'"'!=`""' {
			label variable `_CC' "Continuity correction applied?"
		}
		if `"`_rsample'"'==`""' {
			cap drop _rsample
			qui gen byte _rsample = `_USE'==1		// this shows which observations were used
			label variable _rsample "Sample included in most recent model"
		}		
	}	
	
	// else (if -noKEEPVars- specified), check for existence of pre-existing vars named _ES, _seES etc. and give warning if found
	else {
		cap confirm numeric var `ccvar'
		if !_rc {
			local _CC _CC
			local ortext `", {bf:_NN} or {bf:_CC})"'
		}
		else local ortext `" or {bf:_NN}"'

		// If -noKEEPVars- but not -noRSample-, need to create _rsample as above
		if "`rsample'"=="" {

			// create _rsample
			cap drop _rsample
			qui gen byte _rsample = `_USE'==1		// this shows which observations were used
			label variable _rsample "Sample included in most recent model"
			
			local warnlist
			local rc = 111
			foreach v in _ES _seES _LCI _UCI _WT _NN `_CC' {
				cap confirm var `v'
				if !_rc local warnlist `"`warnlist' {bf:`v'}"'
				local rc = min(`rc', _rc)
			}
			if !`rc' {
				disp _n `"{error}Warning: option {bf:nokeepvars} specified, but the following "stored" variables already exist:"'
				disp `"{error}`warnlist'"'
				disp `"{error}Note that these variables are therefore no longer associated with the most recent analysis"'
				disp `"{error}(although {bf:_rsample} {ul:is})."'
			}
		}
		
		// -noKEEPVars- *and* -noRSample-
		else {
		
			// give warning if variable named _rsample already existed
			cap confirm var _rsample
			if !_rc {
				disp _n `"{error}Warning: option {bf:norsample} specified, but "stored" variable {bf:_rsample} already exists"'
			}
			local rsrc = _rc

			local warnlist
			local rc = 111
			foreach v in _ES _seES _LCI _UCI _WT _NN _CC {
				cap confirm var `v'
				if !_rc {
					local warnlist `"`warnlist' {bf:`v'}"'
					local rc = 0
				}
			}
			if !`rc' {
				if !`rsrc' disp `"{error}as do the following "stored" variables:"'
				else disp _n `"{error}Warning: option {bf:norsample} specified, but the following "stored" variables may already exist:"'
				disp `"{error}`warnlist'"'
			}
			local plural = cond(!`rc', "these variables are", "this variable is")
			if !`rsrc' | !`rc' disp `"{error}Note that `plural' therefore NOT associated with the most recent analysis."'
		}
	}
		
	// Clear/restore characteristics
	char _dta[FPUseOpts]    `char_fpuseopts'
	char _dta[FPUseVarlist] `char_fpusevlist'
	
	// Finally, cancel -preserve-
	restore, not
	
end





********************************************************************************

**********************************************
* Stata subroutines called from main routine *  (and its "minor" subroutines)
**********************************************


* Program to process `study' and `by' labels
// (called directly by metan.ado)

program define ProcessLabels, sclass sortpreserve

	syntax varlist(numeric min=2 max=6) [if] [in], SORTBY(varlist) ///
		NEWSTUDY(name) NEWSTUDYLAB(name) NEWBY(name) NEWBYLAB(name) ///
		[ STUDY(string) LABEL(string) BY(string) LCols(namelist) * ]

	marksample touse, novarlist		// `novarlist' option so that entirely missing/nonexistent studies/subgroups may be included
	local invlist `varlist'			// list of "original" vars passed by the user to the program 
	
	local opts_adm : copy local options
	sreturn clear
	

	** Parse `by'
	// N.B. do this before `study' in case `by' is string and contains missings.
	// Stata sorts string missings to be *first* rather than last.
	if `"`by'"'!=`""' {
		local 0 `"`by'"'
		syntax name [, Missing]		// only a single (var)name is allowed

		cap confirm var `namelist'
		if _rc {
			nois disp as err `"variable {bf:`namelist'} not found in option {bf:by()}"'
			exit 111
		}
		local _BY `namelist'		// `"`_BY'"'!=`""' is a marker of `by' being present in the current data
		if `"`missing'"'==`""' markout `touse' `_BY', strok
		sreturn local bymissing `missing'
	}
	
	
	** Now, parse ways of supplying study names
	// label([namevar=namevar], [yearvar=yearvar]), carried forward from -metan- v9
	// Note, there is some inconsistency in the way this option is documented
	//   option list says "yearvar", but Examples and code itself uses "yearid"
	// Here, either is permitted; but only "yearvar" is documented, to match with "namevar"
	if `"`label'"'!=`""' {	
		if `"`study'"'!=`""' {
			nois disp as err `"Cannot specify both {bf:label()} and {bf:study()}; please choose just one"'
			exit 184
		}
		
		// while loop taken directly from metan9.ado by Ross Harris:
		tokenize "`label'", parse("=, ")
		while "`1'"!="" {
			cap assert inlist(`"`1'"', "namevar", "yearvar", "yearid")
			if _rc local rc = _rc
			else {
				cap confirm var `3'
				if _rc & `: word count `3''==1 {
					nois disp as err `"Variable {bf:`3'} not found in option {bf:label()}"'
					exit _rc
				}
				local rc = _rc
			}
			if `rc' {
				nois disp as err `"Syntax of option {bf:label()} is {bf:label(}[{bf:namevar}={it:namevar}]{bf:,} [{bf:yearvar}={it:yearvar}]{bf:)}"'
				exit _rc
			}
			local `1' "`3'"
			mac shift 4
		}
		if `"`yearid'"'!=`""' {
			if `"`yearvar'"'!=`""'  {
				nois disp as err `"option {bf:label()} invalid;"'
				nois disp as err `"only one of {bf:yearvar} or {bf:yearid} is allowed"'
				exit 184
			}
			local yearvar : copy local yearid
		}
		
		// put name/year variables into appropriate macros
		if `: word count `namevar' `yearvar''==1 local _STUDY `namevar' `yearvar'
		else {
			tempvar _STUDY
			cap confirm string var `namevar'
			if !_rc local namestr `namevar'
			else {
				tempvar namestr
				cap decode `namevar', gen(`namestr')
				if _rc==182 qui gen `namestr' = ""				// if no value label
				else if _rc {
					decode `namevar', gen(`namestr')			// otherwise force exit, with appropriate error message
				}
				qui replace `namestr' = strofreal(`namevar', `"`: format `namevar''"') if missing(`"`namestr'"')
				// ^^ added Aug 2020;  if *some* values are labelled but *not* all, take the values themselves
				// -decode- replaces with missing if no label defined for a particular value
				// hence, use these lines regardless of whether a value label exists
				
				// if _rc==182 qui gen `namestr' = string(`namevar')	// no value label
			}
			cap confirm string var `yearvar'
			if !_rc local yearstr `yearvar'
			else {
				tempvar yearstr
				cap decode `yearvar', gen(`yearstr')
				if _rc==182 qui gen `yearstr' = ""				// if no value label
				else if _rc {
					decode `yearvar', gen(`yearstr')			// otherwise force exit, with appropriate error message
				}
				qui replace `yearstr' = strofreal(`yearvar', `"`: format `yearvar''"') if missing(`yearstr')
				// ^^ added Aug 2020;  if *some* values are labelled but *not* all, take the values themselves
				// -decode- replaces with missing if no label defined for a particular value
				// hence, use these lines regardless of whether a value label exists
				
				// if _rc==182 qui gen `yearstr' = string(`yearvar')	// no value label
			}

			qui gen `_STUDY' = `namestr' + " (" + `yearstr' + ")"
			local namevarlab : variable label `namevar'
			if `"`namevarlab'"'==`""' local namevarlab `namevar'
			local yearvarlab : variable label `yearvar'
			if `"`yearvarlab'"'==`""' local yearvarlab `yearvar'
			label variable `_STUDY' `"`namevarlab' (`yearvarlab')"'
		}

	}	// end if `"`label'"'!=`""'

	// If `study' not supplied:
	// First, look at `lcols' as per -metan- syntax proposed in Harris et al, SJ 2008
	else if `"`study'"'==`""' {
		gettoken _STUDY lcols : lcols		// remove _STUDY from lcols

		if `"`_STUDY'"'!=`""' {
			cap confirm var `_STUDY'
			if _rc {
				nois disp as err `"option {bf:label()} not supplied; variable {bf:`_STUDY'} in option {bf:lcols()} not found"'
				exit _rc
			}
			markout `touse' `_STUDY', strok
			local slcol slcol		// mark as being actually lcols() rather than label() or study(); used later for error message
		}
	
		// Else, start by assuming entire dataset is to be used
		//  and remove any observations with no (i.e. missing) data in `invlist'.
		// (code fragment taken from _grownonmiss.ado)
		else {
			tokenize `invlist'
			qui gen byte `newstudy' = (`1'<.) if `touse'
			mac shift
			while "`1'" != "" {
				qui replace `newstudy' = `newstudy' + (`1'<.) if `touse'
				mac shift
			}
			qui replace `newstudy' = . if `newstudy' == 0		// set to missing for benefit of markout
			markout `touse' `newstudy'
			
			// now generate dummy numbering
			qui bysort `touse' (`sortby') : replace `newstudy' = _n if `touse'
			label variable `newstudy' "Study"
			local _STUDY `newstudy'
		}
	}
	
	// If study is supplied directly
	else {
		local 0 `"`study'"'
		syntax varname [, Missing]
		local _STUDY `varlist'
		if `"`missing'"'==`""' markout `touse' `_STUDY', strok
		sreturn local smissing `missing'
	}
	
	confirm variable `_STUDY'
	local svarlab : variable label `_STUDY'			// extract original variable label...
	if `"`svarlab'"'==`""' local svarlab `_STUDY'	// ...or varname

	// Dec 2020: If labelled-integer, format length may also have an effect on the displayed string
	// Hence, *always* save format length to apply to _LABELS later
	local sfmtlen = fmtwidth("`: format `_STUDY''")

	
	** Check that `touse' is populated (after markout)
	qui count if `touse'
	if !r(N) {
		if `"`slcol'"'!=`""' local errtext `"in first {bf:lcols()} variable"'
		else                 local errtext `"in {bf:study()} variable"'
		if `"`_BY'"'!=`""'   local errtext `"`errtext' or in {bf:by()} variable"'
		nois disp as err `"no valid observations `errtext'"'
		exit 2000
	}	
	local ns = r(N)
	
	
	** Sort out value labels of `_STUDY' and/or `_BY' if either are string
	local rc_by = 1
	if `"`_BY'"'!=`""' {
		cap confirm string variable `_BY'
		local rc_by = _rc
		if !_rc {
			qui gen long `newby' = .
		}

		// May 2020: also be careful with double, if there are ambiguities when recast to float
		if "`: type `_BY''"=="double" {
			tempvar bycheck
			qui clonevar `bycheck' = `_BY'
			qui recast float `bycheck', force
			qui tab `_BY' if `touse', m
			local r = r(r)
			qui tab `bycheck' if `touse', m
			cap assert `r' == r(r)
			if _rc {
				nois disp as err "Variable {bf:`_BY'} in option {bf:by()} has {help data_type} {bf:double}"
				nois disp as err " and has values which are ambiguous when {bf:{help recast}} to {bf:float}."
				nois disp as err "Please check, and re-evaluate or re-label if necessary"
				exit 184
			}
		}
	}
	
	cap confirm string var `_STUDY'
	local rc_study = _rc
	if !_rc {
		qui gen long `newstudy' = .
		qui bysort `touse' (`sortby') : replace `newstudy' = _n if `touse'
		
		// If study is string, save format length to apply to _LABELS later
		// sreturn local sfmtlen = fmtwidth("`: format `_STUDY''")
	}
	
	// May 2020: also be careful with double, if there are ambiguities when recast to float
	else if "`: type `_STUDY''"=="double" {
		tempvar scheck
		qui clonevar `scheck' = `_STUDY'
		qui recast float `scheck', force
		qui tab `_STUDY' if `touse', m
		local r = r(r)
		qui tab `scheck' if `touse', m
		cap assert `r' == r(r)
		if _rc {
			nois disp as err "Variable {bf:`_STUDY'} has {help data_type} {bf:double}"
			nois disp as err " and has values which are ambiguous when {bf:{help recast}} to {bf:float}."
			nois disp as err "Please check, and re-evaluate or re-label if necessary"
			exit 184
		}
	}

	// Now generate new label(s)
	if !`rc_study' | !`rc_by' {
		qui replace `touse' = !`touse'		// place `touse' first
		sort `touse' `sortby'				// studies of interest should now be the first `ns' observations
		local j = 0							// for `by' labels
		forvalues i = 1 / `ns' {
		
			// If `study' is string
			if !`rc_study' {
				local si = `_STUDY'[`i']
				label define `newstudylab' `i' `"`si'"', add
			}
	
			// If `by' is string:
			// Check whether current `by' group has already been defined by a previous study (or studies)
			// If not, create it now.
			if !`rc_by' {
				local byi = `_BY'[`i']
				summ `newby' if !`touse' & `_BY'==`"`byi'"', meanonly
				if !r(N) {
					local ++j
					qui replace `newby' = `j' if !`touse' & `_BY'==`"`byi'"'
					label define `newbylab' `j' `"`byi'"', add
				}
			}
		}
		
		// Apply variable and value label
		if !`rc_study' {
			local svarlab : variable label `_STUDY'			// extract original variable label...
			if `"`svarlab'"'==`""' local svarlab `_STUDY'	// ...or varname
			label variable `newstudy' `"`svarlab'"'
			label values `newstudy' `newstudylab'
			local _STUDY `newstudy'
		}
		
		if !`rc_by' {
			local byvarlab : variable label `_BY'			// extract original variable label...
			if `"`byvarlab'"'==`""' local byvarlab `_BY'	// ...or varname
			label variable `newby' `"`byvarlab'"'
			label values `newby' `newbylab'
			local _BY `newby'
		}
	}
		
	// Check that `_STUDY' and `_BY' are not identical
	if `"`_STUDY'"'!=`""' {
		cap assert `"`_STUDY'"'!=`"`_BY'"'
		if _rc {
			nois disp as err `"the same variable cannot be used in both {bf:study()} and {bf:by()}"'
			exit 184
		}
		confirm numeric variable `_STUDY'
	}
	if `"`_BY'"'!=`""' {
		confirm numeric variable `_BY'
	}
	
	// Return
	sreturn local by `_BY'
	sreturn local study `_STUDY'
	sreturn local sfmtlen `sfmtlen'
	
	// In case `lcols' has been modified, return it back to main routine
	sreturn local lcols `lcols'
	
end





***************************************************

** Routine to parse main options and forestplot options together, and:
//  a. Parse some general options, such as -eform- options and counts()
//  b. Check for conflicts between main options and forestplot() suboptions.
// (called directly by metan.ado)

* Notes:
// N.B. This program is used by both -metan- and -ipdmetan-
// Certain options may be supplied EITHER to -(ipd)metan- directly, OR as sub-options to forestplot()
//   with "forestplot options" prioritised over "main options" in the event of a clash.
// These options are:
// - effect/eform options parsed by CheckOpts (e.g. `rr', `rd', `md', `smd', `wmd', `log')
// - nograph, nohet, nooverall, nosubgroup, nowarning, nowt, nostats
// - effect, hetinfo, lcols, rcols, plotid, ovwt, sgwt, sgweight
// - cumulative, efficacy, influence, interaction
// - counts, group1, group2 (for compatibility with metan.ado)
// - rfdist, rflevel (for compatibility with metan.ado)

program define ParseFPlotOpts, sclass

	** Parse top-level summary info and option lists
	syntax [, CMDNAME(string) MAINPROG(string) OPTIONS(string asis) FORESTplot(string asis)]

		
	** Parse "main options" (i.e. options supplied directly to -(ipd)metan- )
	local 0 `", `options'"'
	syntax [, noGRaph noHET noOVerall noSUbgroup noWARNing noWT noSTATs ///
		EFFect(string asis) COUNTS(string asis) PLOTID(passthru) LCols(passthru) RCols(passthru) ///
		HETINFO(string) HETStat(string) OVStat(string) /// /* N.B. `hetstat' and `ovstat' are legacy synonyms for `hetinfo' */
		OVWt SGWt OVWEIGHT SGWEIGHT CUmulative INFluence INTERaction EFFIcacy RFDist RFLevel(passthru) ///
		COUNTS2 GROUP1(passthru) GROUP2(passthru) NOPR * ]

	local opts_main `"`macval(options)'"'
	local sgwt = cond("`sgweight'"!="", "sgwt", "`sgwt'")		// sgweight is a synonym (for compatibility with -metan9- )
	local sgweight
	local ovwt = cond("`ovweight'"!="", "ovwt", "`ovwt'")		// ovweight is a synonym (for consistency with sgweight)
	local ovweight

	if (`"`hetinfo'"'!=`""') + (`"`hetstat'"'!=`""') + (`"`ovstat'"'!=`""') > 1 {
		nois disp as err `"only one of {bf:hetinfo()}, {bf:hetstat()}, or {bf:ovstat()} is allowed"'
		exit 184												// hetstat and ovstat are synonyms (carried over from -admetan- )
	}
	if `"`hetinfo'"'==`""' local hetinfo : copy local hetstat
	if `"`hetinfo'"'==`""' local hetinfo : copy local ovstat
	if `"`hetinfo'"'!=`""' local hetinfo `"hetinfo(`hetinfo')"'
	local hetstat
	local ovstat
	
	// Process -counts- options
	if `"`counts'"' != `""' {
		local group1_main : copy local group1
		local group2_main : copy local group2
		local 0 `", `counts'"'
		syntax [, COUNTS GROUP1(passthru) GROUP2(passthru) ]
		foreach opt in group1 group2 {
			if `"``opt''"'!=`""' & `"``opt'_main'"'!=`""' & `"``opt''"'!=`"``opt'_main'"' {
				disp `"{error}Note: Conflicting option {bf:`opt'()}; {bf:counts()} suboption will take priority"' 
			}
			if `"``opt''"'==`""' & `"``opt'_main'"'!=`""' local `opt' : copy local `opt'_main
			local `opt'_main
		}
	}
	else local counts : copy local counts2
	if `"`counts'"'!=`""' local counts `"counts(counts `group1' `group2')"'		// counts(counts...) so that contents are never null
	local group1
	local group2

	// Process -eform- options
	cap nois CheckOpts, soptions opts(`opts_main')
	if _rc {
		if _rc==1 nois disp as err `"User break in {bf:`mainprog'.CheckOpts}"'
		else nois disp as err `"Error in {bf:`mainprog'.CheckOpts}"'
		c_local err noerr		// tell main program not to also report an error in ParseFPlotOpts
		exit _rc
	}

	local opts_main `"`s(options)'"'
	local eform     `"`s(eform)'"'
	local log       `"`s(log)'"'
	local summstat  `"`s(summstat)'"'
	if `"`effect'"'==`""' local effect `"`s(effect)'"'
	// N.B. `s(effect)' contains automatic effect text from -eform-; `effect' contains user-specified text


	** Now parse "forestplot options" if applicable
	local optlist1 graph het overall subgroup warning wt stats ovwt sgwt nopr
	local optlist1 `optlist1' cumulative efficacy influence interaction rfdist	// "stand-alone" options
	local optlist2 plotid hetinfo rflevel counts								// options requiring content within brackets
	local optlist3 lcols rcols 													// options which cannot conflict
	
	if `"`forestplot'"'!=`""' {
	
		// Need to temp rename options which may be supplied as either "main options" or "forestplot options"
		//  (N.B. `effect' should be part of `optlist2', but needs to be treated slightly differently)
		local optlist `optlist1' `optlist2' `optlist3' effect
		foreach opt of local optlist {
			local `opt'_main : copy local `opt'
		}
		
		// (Note: extraline() is a forestplot() suboption only,
		//   but is unique in that it is needed *only* by -metan.BuildResultsSet- and *not* by -forestplot-)
		local 0 `", `forestplot'"'
		syntax [, noGRaph noHET noOVerall noSUbgroup noWARNing noWT noSTATs ///
			EFFect(string asis) COUNTS(string asis) PLOTID(passthru) LCols(passthru) RCols(passthru) ///
			HETINFO(string) HETStat(string) OVStat(string) /// /* N.B. `hetstat' and `ovstat' are legacy synonyms for `hetinfo' */
			OVWt SGWt SGWEIGHT CUmulative INFluence INTERaction EFFIcacy RFDist RFLevel(passthru) ///
			COUNTS2 GROUP1(passthru) GROUP2(passthru) EXTRALine(passthru) NOPR * ]

		local opts_fplot `"`macval(options)'"'
		local sgwt = cond("`sgweight'"!="", "sgwt", "`sgwt'")		// sgweight is a synonym (for compatibility with -metan9- )
		local sgweight
		local ovwt = cond("`ovweight'"!="", "ovwt", "`ovwt'")		// ovweight is a synonym (for consistency with sgweight)
		local ovweight

		if (`"`hetinfo'"'!=`""') + (`"`hetstat'"'!=`""') + (`"`ovstat'"'!=`""') > 1 {
			nois disp as err `"only one of {bf:hetinfo()}, {bf:hetstat()}, or {bf:ovstat()} is allowed"'
			exit 184												// hetstat and ovstat are synonyms (carried over from -admetan- )
		}
		if `"`hetinfo'"'==`""' local hetinfo : copy local hetstat
		if `"`hetinfo'"'==`""' local hetinfo : copy local ovstat
		if `"`hetinfo'"'!=`""' local hetinfo `"hetinfo(`hetinfo')"'
		local hetstat
		local ovstat
		
		// counts, group1, group2
		if `"`counts'"' != `""' {
			local group1_main : copy local group1
			local group2_main : copy local group2
			local 0 `", `counts'"'
			syntax [, COUNTS GROUP1(passthru) GROUP2(passthru) ]
			foreach opt in group1 group2 {
				if `"``opt''"'!=`""' & `"``opt'_main'"'!=`""' & `"``opt''"'!=`"``opt'_main'"' {
					disp `"{error}Note: Conflicting option {bf:`opt'()}; {bf:counts()} suboption will take priority"' 
				}
				if `"``opt''"'==`""' & `"``opt'_main'"'!=`""' local `opt' : copy local `opt'_main
				local `opt'_main
			}
		}
		else local counts : copy local counts2
		if `"`counts'"'!=`""' local counts `"counts(counts `group1' `group2')"'		// counts(counts...) so that contents are never null
		local group1
		local group2
		
		// Process -eform- for forestplot, and check for clashes/prioritisation
		cap nois CheckOpts `cmdname', soptions opts(`opts_fplot')
		if _rc {
			if _rc==1 nois disp as err `"User break in {bf:`mainprog'.CheckOpts}"'
			else nois disp as err `"Error in {bf:`mainprog'.CheckOpts}"'
			c_local err noerr		// tell main program not to also report an error in ParseFPlotOpts
			exit _rc
		}
		local opts_fplot `"`s(options)'"'
		
		if `"`summstat'"'!=`""' & `"`s(summstat)'"'!=`""' & `"`summstat'"'!=`"`s(summstat)'"' {
			nois disp as err `"Conflicting summary statistics supplied to {bf:`mainprog'} and to {bf:forestplot()}"'
			exit 184
		}
	}
	
	
	** Finalise locals & scalars as appropriate; forestplot options take priority
	local eform = cond(`"`s(eform)'"'!=`""', `"`s(eform)'"', cond(trim(`"`log'`s(log)'"')!=`""', `""', `"`eform'"'))
	local log = cond(`"`s(log)'"'!=`""', `"`s(log)'"', `"`log'"')
	local summstat = cond(`"`s(summstat)'"'!=`""', `"`s(summstat)'"', `"`summstat'"')
	if `"`effect'"'==`""' local effect `"`s(effect)'"'
	// N.B. `s(effect)' contains automatic effect text from -eform-; `effect' contains user-specified text

	
	// `optlist1' and `optlist2':  allowed to conflict, but forestplot will take priority
	foreach opt of local optlist1 {
		if `"``opt''"'==`""' & `"``opt'_main'"'!=`""' local `opt' : copy local `opt'_main
		if `"``opt''"'!=`""' {
			local opts_parsed `"`macval(opts_parsed)' ``opt''"'
		}
	}
	
	// Display warning for options requiring content within brackets (`optlist2')
	foreach opt in `optlist2' effect {
		if `"``opt'_main'"'!=`""' {
			if `"``opt''"'!=`""' {
				if `"``opt''"'!=`"``opt'_main'"' {
					disp `"{error}Note: Conflicting option {bf:`opt'()}; {bf:forestplot()} suboption will take priority"' 
				}
			}
			else local `opt' : copy local `opt'_main
		}
		
		// Don't add `effect' to opts_parsed; needed separately in main routine
		if `"``opt''"'!=`""' & "`opt'"!="effect" {
			local opts_parsed = `"`macval(opts_parsed)' ``opt''"'
		}
	}

	// `optlist3':  these *cannot* conflict
	foreach opt in `optlist3' {
		if `"``opt'_main'"'!=`""' {
			if `"``opt''"'!=`""' {
				cap assert `"``opt''"'==`"``opt'_main'"'
				if _rc {
					nois disp as err `"Conflicting option {bf:`opt'} supplied to {bf:`mainprog'} and to {bf:forestplot()}"'
					exit 184
				}
				local `opt'
			}
		}
		if `"``opt'_main'``opt''"'!=`""' {
			local opts_parsed `"`macval(opts_parsed)' ``opt'_main'``opt''"'
		}
	}
	
	// Return locals
	sreturn clear
	sreturn local effect `"`effect'"'
	sreturn local eform    `eform'
	sreturn local log      `log'
	sreturn local summstat `summstat'

	sreturn local options     `"`macval(opts_main)'"'
	sreturn local opts_fplot  `"`macval(opts_fplot)'"'
	sreturn local opts_parsed `"`macval(opts_parsed)' `extraline'"'
	
end



* CheckOpts
// Based on the built-in _check_eformopt.ado,
//   but expanded from -eform- to general effect specifications.
// This program is used by -metan-, -ipdmetan- and -forestplot-
// Not all aspects are relevant to all programs,
//   but easier to maintain just a single subroutine!

// subroutine of ParseFPlotOpts

program define CheckOpts, sclass

	syntax [name(name=cmdname)] [, soptions OPts(string asis) ESTEXP(string) ]		// estexp(string), as could include equation term
	
	if "`cmdname'"!="" {
		_check_eformopt `cmdname', `soptions' eformopts(`opts')
	}
	else _get_eformopts, `soptions' eformopts(`opts') allowed(__all__)
	local summstat = cond(`"`s(opt)'"'==`"eform"', `""', `"`s(opt)'"')

	if "`summstat'"=="rrr" {
		local effect `"Risk Ratio"'		// Stata by default refers to this as a "Relative Risk Ratio" or "RRR"
		local summstat rr				//  ... but in MA context most users will expect "Risk Ratio"
	}
	else if "`summstat'"=="nohr" {		// nohr and noshr are accepted by _get_eformopts
		local effect `"Haz. Ratio"'		//  but are not assigned names; do this manually
		local summstat hr
		local logopt nohr
	}
	else if "`summstat'"=="noshr" {
		local effect `"SHR"'
		local summstat shr
		local logopt noshr
	}
	else local effect `"`s(str)'"'

	if "`estexp'"=="_cons" {			// if constant model, make use of eform_cons_ti if available
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
	opts_exclusive "`coef' `log' `nohr' `noshr'" `""' 184
	if `"`summstat'"'!=`""' {
		opts_exclusive `"`summstat' `md' `smd' `wmd' `rr' `rd' `nohr' `noshr'"' `""' 184
	}
	
	// if "nonstandard" effect option used
	else {
		if `"`md'`wmd'"'!=`""' {		// MD and WMD are synonyms
			local effect WMD
			if `"`eform'"'!=`""' local effect `"exp(WMD)"'
			local summstat wmd
		}
		else if `"`smd'`rd'"'!=`""' {
			if "`smd'"!="" local effect SMD
			else if "`rd'"!="" local effect `"`"Risk Diff."'"'		// May 2020: double quotes to ensure it ends up on a separate line from "95% CI"
			if `"`eform'"'!=`""' local effect `"exp(`effect')"'
			local summstat `smd'`rd'
		}
		else if "`nohr'"!="" {
			local effect `"Haz. Ratio"'
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
					disp `"{error}Note: option {bf:`summstat'} does not appear in properties of command {bf:`cmdname'}"'
				}
			}
		}
	}
	
	// log always takes priority over eform
	// ==> cancel eform if appropriate
	local log = cond(`"`coef'`logopt'"'!=`""', "log", "`log'")					// `coef' is a synonym for `log'; `logopt' was defined earlier
	if `"`log'"'!=`""' {
		if inlist("`summstat'", "rd", "smd", "wmd") {
			nois disp as err "Log option only appropriate with ratio statistics"
			exit 184
		}
		local eform
	}
	
	sreturn clear
	sreturn local logopt   `coef'`logopt'			// "original" log option
	sreturn local log      `log'					// either "log" or nothing
	sreturn local eform    `eform'					// either "eform" or nothing
	sreturn local summstat `summstat'				// if `eform', original eform option
	sreturn local effect   `"`effect'"'
	sreturn local options  `"`macval(options)'"'

end




*********************************************************************

* Program to parse inputted varlist structure and
// - identify studies with insufficient data (`_USE'==2)
// - check for validity
// (called directly by metan.ado)

/*
Syntax:
a) binary data (4 vars):
		metan #events_research #nonevents_research #events_control #nonevents_control , ...
b) cts data (6 vars):     
		metan #N_research mean_research sd_research  #N_control mean_control sd_control , ...
c) logrank survival (OE & V) (2 vars): 
		metan theta oe v, [NPTS(varname numeric] ...
d) generic inverse-variance (2 vars): 
		metan theta se_theta , [NPTS(varname numeric] ...
e) generic inverse-variance with CI instead of SE (3 vars): 
		metan theta lowerlimit upperlimit , [NPTS(varname numeric] ...
*/

program define ProcessInputVarlist, sclass
	
	syntax varlist(numeric min=3 max=7 default=none) [if] [in], [SUMMSTAT(name) ///
		COHend GLAssd HEDgesg noSTANdard TRansform(string) FTT /// model options (`ftt' included for compatibility with -metaprop-)
		CORnfield EXact WOolf CItype(name) CIMEThod(name)  /// individual study CI options
		MH PETO BREslow TArone CMH CMHNocc CHI2 CC(passthru) noCC2 /// 
		/*options which can be checked against `summstat' and/or `params' for "quick wins", since not model-dependent*/ ///
		EFORM LOG LOGRank PRoportion NOPR DENOMinator(string) noINTeger ZTOL(real 1.0x-1a) * ]
	
	local opts_adm `"`macval(options)'"'
	
	// if missing values in `invlist', set _USE==2 immediately
	gettoken _USE invlist : varlist
	marksample touse, novarlist
	foreach v of local invlist {
	    qui replace `_USE' = 2 if `touse' & missing(`v')
	}
	
	opts_exclusive `"`logrank' `proportion'"' `""' 184
	
	// Parse explicitly-specified SMD/WMD options, and store in `summstat'
	opts_exclusive `"`cohend' `glassd' `hedgesg' `standard'"' `""' 184
	if `"`cohend'`glassd'`hedgesg'"'!=`""' {
		if inlist("`summstat'", "", "smd") local summstat `cohend'`glassd'`hedgesg'
		else {
			nois disp as err `"Option {bf:`cohend'`glassd'`hedgesg'} incompatible with `=upper(`summstat')'s"'
			exit 184
		}
	}
	else if `"`standard'"'!=`""' {
		if inlist("`summstat'", "", "wmd") local summstat wmd
		else {
			nois disp as err `"Option {bf:`standard'} incompatible with `=upper(`summstat')'s"'
			exit 184
		}
	}
	else if "`summstat'"=="smd" local summstat cohend		// default SMD is Cohen's d
	
	// Parse explicitly-specified `citype' options
	// [N.B. cornfield, exact, woolf were main options to -metan- so are also allowed here
	//  however the preferred -metan- syntax is "citype()" ]
	if `"`cimethod'"'!=`""' {		// added Mar 2020 to allow compatibility with -metaprop- syntax
		if `"`citype'"'!=`""' {
			nois disp as err `"only one of {bf:citype()} or {bf:cimethod()} is allowed"'
			exit 184
		}
		local citype : copy local cimethod
	}
	opts_exclusive `"`cornfield' `exact' `woolf'"' `""' 184
	local cimainopt `cornfield'`exact'`woolf'					// marker as whether supplied as a "main" option (cf -metan-)
	local 0 `", `citype'"'										// now parse preferred "citype()" syntax
	syntax [, CORnfield EXact WOolf * ]
	cap assert `: word count `cimainopt' `cornfield' `exact' `woolf' `options'' <= 1
	if _rc {
		nois disp as err `"Conflict between options {bf:citype(`citype')} and {bf:`cimainopt'}"'
		exit _rc
	}
	local citype `citype'`cimainopt'
	// if inlist(`"`citype'"', `""', `"z"') local citype normal

	
	** Now begin parsing `invlist'
	tokenize `invlist'
	
	cap assert "`7'" == ""
    if _rc {
		nois disp as err "Too many variables specified"
		exit _rc
	}

	if "`6'"=="" {

		// input is generic inverse-variance (2 or 3 vars)
		// or 2 vars with options -logrank- or -proportion-
		if "`4'"=="" {
			
			// incompatible options
			foreach opt in mh peto breslow tarone cmh cmhnocc {
				cap assert `"``opt''"' == `""'
				if _rc {
					nois disp as err `"Option {bf:`opt'} is not appropriate without 2x2 count data"' 
					exit 184
				}
			}
			
			if inlist("`summstat'", "wmd", "cohend", "glassd", "hedgesg") {
				nois disp as err "Specified method of constructing effect size {bf:`summstat'} is incompatible with the data"
				exit 184
			}		
			
			// input is HR logrank (2 vars: OE & V)
			if "`logrank'" != "" {
				cap assert "`3'"=="" & "`2'"!=""
				if _rc {
					nois disp as err "Option {bf:logrank} is only appropriate with two-variable syntax"
					exit 184
				}
				local params = 2
				local summstat hr
				local effect `"Haz. Ratio"'
				args _OE _V
				
				cap assert `_V'>=0 if `touse'
				if _rc {
					nois disp as err "Variances cannot be negative" 
					exit _rc
				}
				
				foreach opt in cc cc2 {
					cap assert `"``opt''"' == `""'
					if _rc {
						if `"`opt'"'==`"cc2"' local opt nocc
						nois disp as err `"Option {bf:`opt'} is not appropriate without proportion or 2x2 count data"' 
						exit 184
					}
				}
				
				// Identify studies with insufficient data (`_USE'==2)
				qui replace `_USE' = 2 if `touse' & `_V'==0
				qui replace `_USE' = 2 if `touse' & sqrt(`_V') < `ztol'
			}
			
			// input is proportions, n & N
			else if "`proportion'"!="" {
				cap assert "`3'"=="" & "`2'"!=""
				if _rc {
					nois disp as err "Option {bf:proportion} is only appropriate with two-variable syntax"
					exit 184
				}
				local params = 2
				
				if "`denominator'"=="" local effect "Proportion"
				else {
					cap confirm number `denominator'
					if _rc {
						nois disp as err `"`denominator' found where number expected in option {bf:denominator(#)}"'
						exit 198
					}
					if `denominator'==1 local effect "Proportion"
					else if `denominator'==100 local effect "Percentage"
					else local effect `"Events per `denominator' obs."'
					local denom_opt denominator(`denominator')
				}
				if "`nopr'"!="" local effect "Transformed proportion"
				
				args succ _NN
				cap assert `succ'<=`_NN' if `touse'
				if _rc {
					nois disp as err "Number of events must be at most equal to the sample size"
					exit _rc
				}
				if "`integer'"=="" {
					cap {
						assert int(`succ')==`succ' if `touse'
						assert int(`_NN')==`_NN' if `touse'
					}
					if _rc {
						nois disp as err "Non-integer cell counts found; use the {bf:nointeger} option if appropriate" 
						exit _rc
					}
				}
				else if !inlist(`"`citype'"', `""', `"wald"') {
					nois disp as err `"Cannot specify {bf:citype(`citype')} with {bf:nointeger}"'
					exit 198
				}
				
				cap assert `succ'>=0 & `_NN'>=0 if `touse'
				if _rc {
					nois disp as err "Non-positive cell counts found" 
					exit _rc
				}
				
				if `"`ftt'"'!=`""' {
				    if `"`transform'"'!=`""' {
					    nois disp as err `"Cannot specify both {bf:ftt} and {bf:transform()}"'
						exit 184
					}
					local transform ftt
				}
				
				local 0 `transform'
				syntax [name(name=transform id="transform" ) ] [, N(string) Arithmetic Geometric Harmonic IVariance INVVariance ]
				// N.B. `n' is an undocumented generalisation of `arithmetic' | `geometric' | `harmonic'
				// Jan 2021: added Barendregt/Doi's suggested "inverse-variance"-based back-transform
				
				local 0 `", `transform'"'
				syntax [, FTT FTukey ARcsine ASine DOUblearcsine LOGIT ]
				if "`ftt'"!="" local ftukey ftukey
				if "`doublearcsine'"!="" local ftukey ftukey
				if "`asine'"!="" local arcsine arcsine
				opts_exclusive `"`ftukey' `arcsine' `logit'"' transform 184
				local summstat `ftukey'`arcsine'`logit'
				if "`summstat'"=="ftukey" {
					if `"`n'"'!=`""' {
						cap {
							confirm number `n'
							assert `n' > 0 & !missing(`n')
						}
						if _rc {
							nois disp as err `"In option {bf:transform(ftukey, n(#))}, # must be > 0 and non-missing"'
							exit 198
						}
						if `"`arithmetic'`geometric'`harmonic'`ivariance'`invvariance'"'!=`""' {
							local erropt : word 1 of `arithmetic' `geometric' `harmonic' `ivariance' `invvariance'
							nois disp as err `"option {bf:transform()} invalid;"'
							nois disp as err `"only one of {bf:n(#)} or {bf:`erropt'} is allowed"'
							exit 184
						}
					}
					else {
						opts_exclusive `"`arithmetic' `geometric' `harmonic' `ivariance' `invvariance'"' transform 184
						local n `arithmetic'`geometric'`harmonic'`ivariance'`invvariance'
						if "`n'"=="invvariance" local n ivariance		// these are synonyms
					}
					local tnopt `"tn(`n')"'
				}
				else if "`summstat'"=="" local summstat pr

				// Identify studies with insufficient data (`_USE'==2)
				qui replace `_USE' = 2 if `touse' & `_NN' < 2
				
				// Note: with proportions, `citype' *must* be sent to -cii- , so it will pick up any invalid citypes
				// (set default to -wilson- , as with -metaprop- )
				if `"`citype'"'==`""' local citype wilson
			}
			
			// input is generic inverse-variance (2 or 3 vars)
			else {
				if "`transform'"!="" {
					nois disp as err "Option {bf:transform()} only valid with {bf:proportion}"
					exit 184
				}
				foreach opt in cc cc2 {
					cap assert `"``opt''"' == `""'
					if _rc {
						if `"`opt'"'==`"cc2"' local opt nocc
						nois disp as err `"Option {bf:`opt'} is not appropriate without proportion or 2x2 count data"' 
						exit 184
					}
				}				
	
				// citype
				cap assert !inlist("`citype'", "cornfield", "exact", "woolf")
				if _rc {
					if `"`cimainopt'"'!=`""' {
						nois disp as err `"Option {bf:`citype'} is not appropriate without 2x2 count data"'
					}
					else nois disp as err `"{bf:citype(`citype')} is not appropriate without 2x2 count data"'
					exit 184
				}
			
				// Identify studies with insufficient data (`_USE'==2)
				if "`3'"=="" { 	// input is ES + SE
					local params = 2
					args _ES _seES
					cap assert `_seES'>=0 if `touse'
					if _rc {
						nois disp as err "Standard errors cannot be negative" 
						exit _rc
					}
					qui replace `_USE' = 2 if `touse' & `_seES'==0
					qui replace `_USE' = 2 if `touse' & 1/`_seES' < `ztol'
				}

				else { 		// input is ES + 95% CI
					local params = 3
					args _ES _LCI _UCI
					qui replace `_USE' = 2 if `touse' & float(`_LCI')==float(`_UCI')
					cap assert `_UCI'>=`_ES' & `_ES'>=`_LCI' if `touse' & `_USE'==1
					if _rc {
						nois disp as err "Effect size and/or confidence interval limits invalid;"
						nois disp as err `"order should be {it:effect_size} {it:lower_limit} {it:upper_limit}"'
						exit _rc
					}
					cap assert `_UCI'>=`_LCI' if `touse' & `_USE'==2 & missing(`_ES') & !missing(`_LCI') & !missing(`_UCI') ///
						& !(float(`_LCI')==float(`_UCI'))
					if _rc {
						nois disp as err "Effect size and/or confidence interval limits invalid;"
						nois disp as err `"order should be {it:effect_size} {it:lower_limit} {it:upper_limit}"'
						exit _rc
					}
					qui replace `_USE' = 2 if `touse' & 2*invnormal(.975)/(`_UCI' - `_LCI') < `ztol'
				}
			}			
		}       // end of inverse-variance setup

		// input is 2x2 tables
		else {
			cap assert "`5'"==""
			if _rc {
				nois disp as err "Invalid number of variables specified" 
				exit _rc
			}
			local params = 4
			args e1 f1 e0 f0	// events, non-events in trt group; events, non-events in ctrl group (a.k.a. a b c d)
			
			if "`integer'"=="" {
				cap {
					assert int(`e1')==`e1' if `touse'
					assert int(`f1')==`f1' if `touse'
					assert int(`e0')==`e0' if `touse'
					assert int(`f0')==`f0' if `touse'
				}
				if _rc {
					nois disp as err "Non-integer cell counts found; use the {bf:nointeger} option if appropriate" 
					exit _rc
				}
			}
			else if !inlist(`"`citype'"', `""', `"normal"') {
				nois disp as err `"Cannot specify {bf:citype(`citype')} with {bf:nointeger}"'
				exit 198
			}			
			
			cap assert `e1'>=0 & `f1'>=0 & `e0'>=0 & `f0'>=0 if `touse'
			if _rc {
				nois disp as err "Non-positive cell counts found" 
				exit _rc
			}

			// citype
			cap assert !inlist("`citype'", "cornfield", "exact", "woolf")
			if _rc {			
				if !inlist("`summstat'", "or", "") {
					if `"`cimainopt'"'!=`""' {
						nois disp as err `"Option {bf:`citype'} is only compatible with odds ratios"'
					}
					else nois disp as err `"Option {bf:citype(`citype')} is only compatible with odds ratios"' 
					exit 184
				}
				else if "`summstat'"=="" {
					if "`citype'"=="cornfield" {
						disp `"{error}Note: Cornfield-type confidence intervals specified; odds ratios assumed"'
					}
					else if "`citype'"=="exact" {
						disp `"{error}Note: Exact confidence intervals specified; odds ratios assumed"'
					}
					else disp `"{error}Note: Woolf-type confidence intervals specified; odds ratios assumed"'
					local summstat or
					local effect `"Odds Ratio"'
				}
			}

			if "`chi2'"!="" {
				if !inlist("`summstat'", "or", "") {
					nois disp as err `"Option {bf:chi2} is only compatible with odds ratios"'
					exit 184
				}
				else if "`summstat'"=="" {
					disp `"{error}Note: Chi-squared option specified; odds ratios assumed"' 
					local summstat or
					local effect `"Odds Ratio"'
				}
			}
						
			foreach opt in breslow tarone cmh cmhnocc {
				if "``opt''"!="" {
					if !inlist("`summstat'", "or", "") {
						nois disp as err `"Option {bf:`opt'} is only compatible with odds ratios"' 
						exit 184
					}
					else if "`summstat'"=="" {
						local opttxt = cond("`opt'"=="breslow", "Breslow-Day homogeneity test", ///
							cond("`opt'"=="tarone", `"Breslow-Day-Tarone homogeneity test"', ///
							cond(inlist("`opt'", "cmh", "cmhnocc"), "Cochran-Mantel-Haenszel test", "")))
						
						disp `"{error}`opttxt' specified; odds ratios assumed"'
						local summstat or
						local effect `"Odds Ratio"'
					}
				}
			}
			if "`peto'"!="" {
				if !inlist("`summstat'", "or", "") {
					nois disp as err "Peto method option can only be used with odds ratios"
					exit 184
				}
				else if "`summstat'"=="" {
					disp `"{error}Note: Peto method specified; odds ratios assumed"' 
					local summstat or
					local effect `"Odds Ratio"'
				}
				local chi2 chi2
			}
			
			if `"`logrank'`proportion'"'!=`""' {
				nois disp as err "Option {bf:`logrank'`proportion'} is only appropriate with two-variable syntax"
				exit 184
			}
			if "`transform'"!="" {
				nois disp as err "Option {bf:transform()} only valid with {bf:proportion}"
				exit 184
			}
			if inlist("`summstat'", "hr", "shr", "tr") {
				nois disp as err "Time-to-event outcome types are incompatible with count data"
				exit 184
			}
			else if inlist("`summstat'", "wmd", "cohend", "glassd", "hedgesg") {
				nois disp as err "Continuous outcome types are incompatible with count data"
				exit 184
			}
			else if "`summstat'"=="" {
				local summorig null			// marker that summstat was *not* specified by user
				local summstat rr
				local effect `"Risk Ratio"'
			}

			** Average event rate (binary outcomes only)
			// (do this before any 0.5 adjustments or excluding 0-0 studies)
			tempname e_sum
			summ `e1' if `touse', meanonly
			scalar `e_sum' = cond(r(N), r(sum), .)
			summ `f1' if `touse', meanonly
			local tger = cond(r(N), `e_sum'/(`e_sum' + `r(sum)'), .)
			
			summ `e0' if `touse', meanonly
			scalar `e_sum' = cond(r(N), r(sum), .)
			summ `f0' if `touse', meanonly
			local cger = cond(r(N), `e_sum'/(`e_sum' + `r(sum)'), .)
			
			// Find studies with insufficient data (`_USE'==2)
			qui replace `_USE' = 2 if `touse' & (`e1' + `f1')*(`e0' + `f0')==0		// No data AT ALL in at least one arm
			if "`summstat'"!="rd" {																// i.e. `r1'==0 or `r0'==0

				// M-H RR: double-zero *non*-event (i.e. ALL events in both arms; unusual but not impossible) is OK
				if "`summstat'"=="rr" qui replace `_USE' = 2 if `touse' & `e1' + `e0'==0
				
				// Else: any double-zero
				else qui replace `_USE' = 2 if `touse' & (`e1' + `e0'==0 | `f1' + `f0'==0)
			}
		}		// end of binary variable setup

		// log only allowed if OR, RR, RRR, HR, SHR, TR
		if "`log'"!="" & !inlist("`summstat'", "or", "rr", "rrr", "hr", "shr", "tr") {
			disp `"{error}{bf:log} may only be specified with 2x2 count data or log-rank HR; option will be ignored"'
			local log
		}
		
	} // end of all non-6 variable setup

	if "`6'"!="" {
		
		// log not allowed
		if "`log'"!="" {
			disp `"{error}{bf:log} may only be specified with 2x2 count data or log-rank HR; option will be ignored"'
			local log
		}

		local params = 6
		args n1 mean1 sd1 n0 mean0 sd0

        // input is form N mean SD for continuous outcome data
		if "`integer'"=="" {
			cap assert int(`n1')==`n1' & int(`n0')==`n0' if `touse'
			if _rc {
				nois disp as err "Non integer sample sizes found"
				exit _rc
			}
		}
		
        cap assert `n1'>0 & `n0'>0 if `touse'
		if _rc {
			nois disp as err "Non positive sample sizes found" 
			exit _rc
		}
		cap assert `sd1'>=0 & `sd0'>=0 if `touse'
		if _rc {
			nois disp as err "Standard errors cannot be negative" 
			exit _rc
		}

		foreach opt in mh peto breslow cc cc2 chi2 tarone cmh cmhnocc {
			cap assert `"``opt''"' == `""'
			if _rc {
				nois disp as err `"Option {bf:`opt'} is not appropriate without 2x2 count data"' 
				exit 184
			}
		}
		if `"`logrank'`proportion'"'!=`""' {
			nois disp as err "Option {bf:`logrank'`proportion'} is only appropriate with two-variable syntax"
			exit 184
		}
		if "`transform'"!="" {
			nois disp as err "Option {bf:transform()} only valid with {bf:proportion}"
			exit 184
		}
		
		// citype
		cap assert !inlist("`citype'", "cornfield", "exact", "woolf")
		if _rc {
			if `"`cimainopt'"'!=`""' {
				nois disp as err `"Option {bf:`citype'} is not appropriate without 2x2 count data"'
			}
			else nois disp as err `"Note: {bf:citype(`citype')} is not appropriate without 2x2 count data"' 
			exit 184
		}
		
		// summstat
		cap assert inlist("`summstat'", "", "wmd", "cohend", "glassd", "hedgesg")
		if _rc {
			nois disp as err "Invalid specifications for combining trials"
			exit 184
		}
		if "`summstat'"=="" {
			local summstat cohend		// default is Cohen's d standardised mean difference
			local effect SMD
		}

		// Find studies with insufficient data (`_USE'==2)
		qui replace `_USE' = 2 if `touse' & `n1' < 2  | `n0' < 2
		qui replace `_USE' = 2 if `touse' & `sd1'==0  | `sd0'==0

	} 	// end of 6-var set-up
	
	qui count if `touse' & `_USE'==1
	if !r(N) exit 2000
	
	// If `params'==4, default to eform unless Risk Diff.
	if `params'==4 & `"`summstat'"'!=`"rd"' & `"`log'"'==`""' {
		local eform eform
	}
	
	// Similarly: if `logrank', default to log
	else if "`logrank'"!="" {
		local log = cond(`"`log'"'!=`""', "log", cond(`"`eform'"'==`""', "log", ""))
	}
	
	// summstat should be NON-MISSING *UNLESS* "generic" es/se
	if `params'>3 | "`logrank'"!="" {
		assert `"`summstat'"'!=`""'
	}
	
	// Finalize citype
	if inlist(`"`citype'"', `""', `"z"') local citype normal	
	
	sreturn clear
	
	local options `breslow' `tarone' `cmh' `cmhnocc' `chi2'
	local options `options' `logrank' `proportion' `denom_opt' `nopr' `mh' `peto' `integer' `cc' `cc2' `tnopt'
	sreturn local options `"`macval(opts_adm)' `options'"'
	
	sreturn local effect `"`effect'"'
	sreturn local summorig `summorig'
	sreturn local summstat `summstat'
	sreturn local params   `params'
	sreturn local citype   `citype'
	sreturn local eform    `eform'
	sreturn local log      `log'

	if `params'==4 {
		sreturn local tger `tger'
		sreturn local cger `cger'
	}
	
end





*****************************************************************

* Parse meta-analysis modelling options (incl. random-effects)
// compatibility, error checking
// (called directly by metan.ado)

// Note: First part updated Nov 2020 for restructuring of first() / second() options

program define ProcessModelOpts, sclass
	
	** First, parse options needed throughout this subroutine
	syntax, PARAMS(passthru) ///
		[ SUMMSTAT(passthru) SUMMORIG(passthru) ///
		RFDist CUmulative INFluence LOGRank PRoportion TN(passthru) ///
		/// /* Test (`teststat') and heterogeneity (`hetstat') statistics */
		T Z CHI2 CMH CMHNocc BREslow TArone COCHranq ///
		///
		/// /* Other "global" options, for passing to ParseModel */
		CC(string) noCC2 WGT(passthru) * ]
	
	
	** Next, sort out:
	// - legacy -metan- options first() and second()
	// - options permitted outside of model() option (either legacy -metan- or otherwise) 
	cap nois ProcessFirstSecond, `params' `logrank' `options'
	if _rc {
		if _rc==1 nois disp as err `"User break in {bf:metan.ProcessFirstSecond}"'
		else nois disp as err `"Error in {bf:metan.ProcessFirstSecond}"'
		c_local err noerr		// tell -metan- not to also report an "error in metan.ProcessModelOpts"
		exit _rc
	}
	
	local model    `"`s(model)'"'
	local opts_adm `"`s(options)'"'
	
	// Internal macro lists
	local teststat `t' `z' `chi2' `cmh' `cmhnocc'
	local qstat `breslow' `tarone' `cochranq'
	opts_exclusive `"`teststat'"' `""' 184
	opts_exclusive `"`qstat'"'    `""' 184

	if `"`cc'"'!=`""' local ccopt `"cc(`cc')"'
	else local ccopt `cc2'
	
	
	
	*****************
	* Parse model() *
	*****************
	
	// Multiple models, separated with a backslash
	// [Nov 2020] use gettoken ... parse(",") instead of strpos(",")
	local m = 1
	if `"`model'"'!=`""' {
		gettoken model`m' rest : model, parse("\") bind
		if trim(`"`model`m''"')=="null" local model`m'			// remove temporary "null" marker
		gettoken foo comma : model`m', parse(",") bind
		if `"`comma'"'==`""' local model`m' `model`m'',			// add comma if no options
		while `"`rest'"'!=`""' {
			gettoken bs rest2 : rest, parse("\") bind
			assert "`bs'"=="\"
			if `"`rest2'"'==`""' continue, break
			else {
				local ++m
				gettoken model`m' rest : rest2, parse("\") bind
				gettoken foo comma : model`m', parse(",") bind
				if `"`comma'"'==`""' local model`m' `model`m'',		// add comma if no options
			}
		}
	}
	else local model1 ,		// add comma (so that ParseModel doesn't complain)

	// Now process each model in turn using ParseModel to return "canonical" form
	forvalues j = 1 / `m' {

		// [Nov 2020:]
	    local first      = cond(`j'==1, "first", "")		// marker of this model being the first/main/primary model
		cap nois ParseModel `model`j'' `summstat' `summorig' `params' `logrank' `proportion' `tn' `first' ///
			globalopts(`teststat' `wgt' `ccopt' `opts_adm')
		if _rc {
			if _rc==1 nois disp as err `"User break in {bf:metan.ParseModel}"'
			else nois disp as err `"Error in {bf:metan.ParseModel}"'
			c_local err noerr		// tell -metan- not to also report an "error in metan.ProcessModelOpts"
			exit _rc
		}

		cap assert `"`s(model)'"'!=`""'
		if _rc {
			nois disp as err "No model found"
			exit 198
		}

		// corrective macro
		if `"`summnew'"'==`""' local summnew `s(summnew)'

		// standard macros
		local model`j'opts `"`s(modelopts)'"'
		if `: list posof "kroger" in model`j'opts' local kroger kroger		// for later error messages e.g. relating to predictive interval
		
		// labelling macro
		local labelopts `"`labelopts' label`j'opt(`s(labelopt)')"'
		
		// [Nov 2020:] user-supplied effect sizes
		if `"`s(extralabel)'"'!=`""' {
			local labelopts `"`labelopts' extra`j'opt(`s(extralabel)')"'
		}
		if `"`s(userstats)'"'!=`""' {
			local labelopts `"`labelopts' user`j'stats(`s(userstats)')"'
			local user`j'stats `s(userstats)'						// for -return historical-
		}
		
		local modellist    `modellist' `s(model)'
		local teststatlist `teststatlist' `s(teststat)'
		local wgtoptlist   `wgtoptlist' `s(wgtopt)'
		
		// Error prompts
		local gl_error `gl_error' `s(gl_error)'
	}
	
	// collect remaining options
	local opts_adm `"`s(opts_adm)'"'
	
	// Compare `qstat' to `model1'
	gettoken model1 : modellist
	if "`model1'"=="mh" {
		if "`qstat'"=="" local qstat mhq		// default if M-H method
	}
	else if inlist("`qstat'", "breslow", "tarone") {
		nois disp as err "cannot specify {bf:`qstat'} heterogeneity option without Mantel-Haenszel odds ratios"
		exit 184
	}
	if "`model1'"=="peto" {
		if "`qstat'"=="" local qstat petoq		// default if Peto method
	}
	if "`qstat'"=="" local qstat cochranq		// default otherwise

	// Display other error prompts
	local gl_error : list uniq gl_error
	foreach opt of local gl_error {
		if `m'==1 {
			nois disp as err "Option {bf:`opt'} is not compatible with model {bf:`modellist'}"
			exit 184
		}
		disp `"{error}Note: global option {bf:`opt'} is not applicable to all models; local defaults will apply"'
	}
	if "`rfdist'"!="" {
		if `"`cumulative'"'!=`""' {
			nois disp as err `"Options {bf:cumulative} and {bf:rfdist} are not compatible"'
			exit 184
		}
		if `"`influence'"'!=`""' {
			nois disp as err `"Options {bf:influence} and {bf:rfdist} are not compatible"'
			exit 184
		}		// Note: cumulative and influence have not yet been tested for exclusivity, hence the repetition here
		
		local nopredint mh iv peto bt hc ivhet qe mu pl user
		if `"`: list modellist - nopredint'"'==`""' | (`m'==1 & "`kroger'"!="") {
			disp `"{error}Note: predictive interval cannot be estimated under "' _c
			if `m'==1 disp `"{error}the specified model; {bf:rfdist} will be ignored"'
			else disp as err `"{error}any of the specified models; {bf:rfdist} will be ignored"'
			local rfdist
		}		
		else if `"`: list modellist & nopredint'"'!=`""' | "`kroger'"!="" {
			disp as err `"{error}Note: predictive interval cannot be estimated for all models"'
		}
	}

	
	
	***********************
	* Initialise rownames *
	***********************
	// of matrices to hold overall/subgroup pooling results
	//  ... and "parametrically-defined Isq" -based heterogeneity if specified and appropriate [Sep 2020]
	// (c.f. r(table) after regression)

	local rownames eff se_eff eff_lci eff_uci 
	if "`proportion'"!="" & "`summstat'"!="pr" local rownames `rownames' prop_eff prop_lci prop_uci
	
	// effect size; std. err.; conf. limits; no. pts.; critical value
	// plus, add z by default as a fall-back e.g. if t-dist requested but only 1 study; can always be removed later
	local rownames `rownames' npts crit z
	
	// test statistics: remove duplicates, then use set ordering: z, t, chi2, u
	local rowtest : copy local teststatlist
	local rowtest : list uniq rowtest
	foreach el in t chi2 u {
		if `: list el in rowtest' local rownames `rownames' `el'	// test statistics, in pre-defined order
	}
	if `: list posof "t" in rowtest' local rownames `rownames' df	// df for t (including Kenward-Roger)
	local rownames `rownames' pvalue								// p-value

	if "`logrank'"!="" | `: list posof "peto" in modellist' local rownames `rownames' OE V	// logrank and Peto OR only
	
	local UniqModels : list uniq modellist
	local NoTau2Models mh peto mu iv
	local UniqModels : list UniqModels - NoTau2Models
	if `"`UniqModels'"'!=`""' local rownames `rownames' tausq	// tausq, *unless* all models are common-effect (M-H, Peto, IV or MU)

	// [Sep 2020:]
	// Note: Heterogeneity stats derived from the *data*, independently of model (i.e. Q Qdf H Isq)
	//  are returned in r() rather than stored in a matrix

	// "parametrically-defined Isq" -based heterogeneity values, if requested [i.e. derived from Isq = tsq/(tsq+sigmasq) ]
	// are stored in matrix r(hetstats) [and byhet1...byhet`nby' for subgroups]
	// (plus tsq + CI itself)

	// model-based tausq confidence intervals
	local RefModList mp ml pl reml bt dlb
	if `"`: list UniqModels & RefModList'"'!=`""' {
		local rownames `rownames' tsq_lci tsq_uci
	}
		
	if "`rfdist'"!="" {
		local rownames `rownames' rflci rfuci			// if predictive distribution
		if "`proportion'"!="" & "`summstat'"!="pr" local rownames `rownames' prop_rflci prop_rfuci
	}
	
	// Return options
	sreturn clear
	sreturn local rownames     `rownames'
	sreturn local modellist    `modellist'
	sreturn local teststatlist `teststatlist'
	sreturn local qstat        `qstat'
	sreturn local wgtoptlist   `wgtoptlist'
	sreturn local summnew      `summnew'
	sreturn local labelopts  `"`labelopts'"'	// Nov 2020
	
	forvalues j = 1 / `m' {
		sreturn local model`j'opts `"`model`j'opts'"'
	}
	sreturn local m `m'
	sreturn local opts_adm `"`macval(opts_adm)' `logrank' `rfdist' `cumulative' `influence' `proportion'"'		// non model-specific options

	// Internal markers
	if "`wgt'"!="" {
		c_local userwgt userwgt		// marker of user-defined weights, c.f. previous versions of -metan-
	}
	c_local olduser `olduser'		// marker that "legacy" -metan- options first() and/or second() were supplied

	// June 2020: Return historical
	if `"`user2stats'"'!=`""' {
		tokenize `user2stats'
		sreturn local ES_2     `1'
		sreturn local ci_low_2 `2'
		sreturn local ci_upp_2 `3'
	}
	if `"`user1stats'"'!=`""' {
		tokenize `user1stats'
		sreturn local ES     `1'
		sreturn local ci_low `2'
		sreturn local ci_upp `3'
	}
		
end




// Process legacy -metan- options first() and second()
// Display "legacy" error messages etc. if necessary, and return as "canonical" form

// This subroutine is called by ProcessModelOpts

program define ProcessFirstSecond, sclass
	
	
	*** (1) Legacy -metan- options first() and second() ***
	syntax, [ FIRST(string asis) FIRSTSTATS(string asis) SECOND(string asis) SECONDSTATS(string asis) * ]
		
	local opts_adm `"`macval(options)'"'
	
	if `"`second'"'!=`""' {	
		local olduser olduser		// marker that "legacy" -metan- options first() and/or second() were supplied
		
		gettoken _ES2_ rest : second
		cap confirm number `_ES2_'
		if !_rc {		// if user-defined pooled effect
			gettoken _LCI2_ rest : rest
			gettoken _UCI2_ desc : rest
			cap {
				confirm number `_LCI2_'
				confirm number `_UCI2_'
				assert `_LCI2_' <= `_ES2_'
				assert `_UCI2_' >= `_ES2_'
			}
			if _rc {
				nois disp as err `"Error in option {bf:second()}: must supply user-defined main analysis in the format:"'
				nois disp as err "  {it:ES lci uci desc}"
				exit 198
			}

			// [Nov 2020:]
			// "gettoken _UCI2_ desc" leaves a space as the first character of "`desc'"
			local desc = ltrim(`"`desc'"')
			
			local second `"`_ES2_' `_LCI2_' `_UCI2_', label(`desc') extralabel(`secondstats')"'
		}
		
		// Else, assume that "`second'" is a model name...
		else {
		    if "`rest'"!="" {
				nois disp as err `"Error in option {bf:second()}: must supply user-defined main analysis in the format:"'
				nois disp as err "  {it:ES lci uci desc}"
				exit 198
			}
			
			// ...in which case it must be fixed (common), random, mh, or peto
			local 0 `", `second'"'
			cap syntax [, FIXEDi IVariance INVVariance IVCommon COMMON RANDOMi MHaenszel PETO ]
			if _rc {
				nois disp as err "Option {bf:second()} can be one of {bf:fixed}|{bf:{ul:iv}common}, {bf:random}, {bf:{ul:mh}aenzel} or {bf:peto}"
				nois disp as err " or a user-defined estimate with confidence intervals in the format:  {it:ES lci uci desc}"
				exit 198
			}
			if `"`secondstats'"'!=`""' {
				disp `"{error}Note: {bf:secondstats()} is only valid with {bf:second(}{it:ES lci uci desc}{bf:)}, so will be ignored"'
				local secondstats
			}
			if "`second'"=="randomi" local second random		// Jan 2021: "randomi" is not understood by model()
			
			// Use existing ("legacy") error message from -metan-
			if `"`first'"'!=`""' {
				nois disp as err "Cannot have user-defined analysis as main analysis,"
				nois disp as err "  and a standard analysis as second analysis."
				nois disp as err "You can do it the other way round, or have two user defined analyses,"
				nois disp as err "  but you can't do this particular thing. Sorry, that's just the way it is."
				exit 198
			}
		}
	}
	else if `"`secondstats'"'!=`""' {
		disp `"{error}Note: {bf:secondstats()} is only valid with {bf:second(}{it:ES lci uci desc}{bf:)}, so will be ignored"'
	}

	if `"`first'"'!=`""' {
		local olduser olduser		// marker that "legacy" -metan- options first() and/or second() were supplied
  
		gettoken _ES_  rest : first
		gettoken _LCI_ rest : rest
		gettoken _UCI_ desc : rest
		cap {
			confirm number `_ES_'
			confirm number `_LCI_'
			confirm number `_UCI_'
			assert `_LCI_' <= `_ES_'
			assert `_UCI_' >= `_ES_'
		}
		if _rc {
			nois disp as err `"Error in option {bf:first()}: must supply user-defined main analysis in the format:"'
			nois disp as err "  {it:ES lci uci desc}"
			exit _rc
		}

		local first `"`_ES_' `_LCI_' `_UCI_', label(`desc') extralabel(`firststats')"'
	}
	else if `"`firststats'"'!=`""' {
		disp `"{error}Note: {bf:firststats()} is only valid with {bf:first(}{it:es lci uci desc}{bf:)}, so will be ignored"'
	}
	
	
	*** (2) Other options ***
	
	local 0 `", `opts_adm'"'	
	syntax, PARAMS(integer) [ MODEL(string asis) ///
		RAndom1 RAndom(string) RE1 RE(string) RANDOMI ///			// synonyms for D+L random-effects inverse-variance
		FIXEDI FIXED COMMON FE INVVariance IVariance IVCommon ///	// synonyms for common-effect inverse-variance
		MHaenszel PETO LOGRank ///									// MH/Peto (N.B. `fixed' imples MH if count data; `logrank' mostly for use with -ipdmetan-)
		IVHet QE(varname numeric) * ]								// for backwards-compatibility with -admetan-
	
	local opts_adm `"`macval(options)'"'
	
	// re/re() and random/random() as main options
	if `"`random'"'!=`""' local rabr `"()"'
	if     `"`re'"'!=`""' local rebr `"()"'

	if `"`random1'"'!=`""' & `"`random'"'==`""' local random random
	if     `"`re1'"'!=`""' & `"`re'"'==`""'     local re re

	if `"`re'"'!=`""' {
		if `"`random'"'!=`""' {
			nois disp as err `"Cannot specify both {bf:re`rebr'} and {bf:random`rabr'}; please choose just one"'
			exit 184
		}
		else if `"`randomi'"'!=`""' {
			nois disp as err `"Cannot specify both {bf:re`rebr'} and {bf:randomi}; please choose just one"'
			exit 184
		}
		local re_orig re`rebr'				// store actual supplied option for error displays
		local newModel : copy local re		// `re' is a synonym for `model'; henceforth use the latter		
	}
	else if `"`randomi'"'!=`""' {
		if `"`random'"'!=`""' {
			nois disp as err `"Cannot specify both {bf:randomi} and {bf:random`rabr'}; please choose just one"'
			exit 184
		}
		local re_orig randomi				// store actual supplied option for error displays
		local newModel re					// "randomi" is a synonym for "re"; henceforth use the latter		
	}
	else if `"`random'"'!=`""' {
		local re_orig random`rabr'			// store actual supplied option for error displays
		local newModel : copy local random	// `random' is a synonym for `model'; henceforth use the latter
	}

	// NOTE: Only minimal validity checking here; just want to identify single unique model
	if "`logrank'"!="" {
		opts_exclusive `"`logrank' `fixedi' `fixed' `common' `mhaenszel' `ivcommon' `invvariance' `ivariance' `fe' `peto' `re_orig'"' `""' 184
		local peto peto
	}
	opts_exclusive `"`fixedi' `fixed' `common' `mhaenszel' `ivcommon' `invvariance' `ivariance' `fe' `peto' `re_orig'"' `""' 184
	
	// Similarly, `fe' etc. are synonyms for model(ivcommon)...
	if `"`fixedi'`fe'`ivcommon'`common'`invvariance'`ivariance'"'!=`""' {
		local model_orig `fixedi'`fe'`ivcommon'`common'`invvariance'`ivariance'		// store actual supplied option for error displays
		local newModel ivcommon
	}
	
	// ...`mhaenszel' is a synonym for model(mhaenszel)...
	if `"`mhaenszel'"'!=`""' {
		local model_orig mhaenszel			// store actual supplied option for error displays
		local newModel mhaenszel
	}
	
	// and ...`peto' is a synonym for model(peto)
	if `"`peto'"'!=`""' {
		local model_orig peto				// store actual supplied option for error displays
		local newModel peto
	}
	
	// `fixed' is a synonym for model(mhaenszel) if 2x2 data; otherwise it is a synonym for model(ivcommon)
	if `"`fixed'"'!=`""' {
		local model_orig fixed				// store actual supplied option for error displays
		local newModel = cond(`params'==4, "mhaenszel", "ivcommon")
	}

	// qe() and ivhet
	if `"`qe'"'!=`""' {
		local model_orig qe()				// store actual supplied option for error displays
		local newModel qe, qwt(`qe')		// format to pass to ParseModel
	}
	if `"`ivhet'"'!=`""' {
		local model_orig ivhet				// store actual supplied option for error displays
		local newModel ivhet
	}
	
	if `"`model'"'!=`""' & `"`first'"'!=`""' {
		nois disp as err `"Cannot specify both {bf:model()} and {bf:first()}; please choose just one"'
		exit 184
	}
	if `"`model_orig'`re_orig'"'!=`""' {
		if `"`model_orig'"'!=`""' & `"`re_orig'"'!=`""' {
			nois disp as err `"Cannot specify both {bf:`re_orig'} and {bf:`model_orig'}; please choose just one"'
			exit 184
		}
		if `"`model'`first'"'!=`""' {
			nois disp as err `"Cannot specify both {bf:`model_orig'`re_orig'} and {bf:`model'`first'()}; please choose just one"'
			exit 184
		}
		local model : copy local newModel
	}
	
	// Return options
	sreturn clear
	sreturn local options `"`opts_adm'"'
	
	if `"`first'"'!=`""' {
		local model : copy local first
	}
	if `"`second'"'!=`""' {
	    if `"`model'"'==`""' local model null		// temporary marker; will be re-parsed later
		local model `"`model' \ `second'"'
	}
	sreturn local model `"`model'"'
	
	c_local olduser `olduser'		// internal marker that "legacy" -metan- options first() and/or second() were supplied
	
end




// Simply parse multiple models one-at-a-time, and return the results
// Validity checking is done elsewhere.

// This subroutine is called by ProcessModelOpts

program define ParseModel, sclass

	syntax [anything(name=model id="meta-analysis model")] ///
		, PARAMS(integer) [ SUMMSTAT(name) SUMMORIG(name) GLOBALOPTS(string asis) ///	// default/global options: `teststat' `hetstat' [WGT() CC() etc.]
		Z T CHI2 CMH CMHNocc ///														// test statistic options
		HKSj HKnapp KHartung KRoger BArtlett PETO RObust SKovgaard EIM OIM QWT(varname numeric) /*contains quality weights*/ ///
		INIT(name) CC(passthru) noCC2 LOGRank PRoportion TN(passthru) ///
		LAbel(string asis) EXtralabel(string asis) FIRST /*SECOND*/ ///		// [Oct 2020:] user-defined model labelling
		WGT(passthru) TRUNCate(passthru) ISQ(string) TAUSQ(string) ///
		ITOL(passthru) MAXTausq(passthru) REPS(passthru) MAXITer(passthru) QUADPTS(passthru) DIFficult TECHnique(passthru) ]
		// last line ^^  "global" opts to compare with "specific model" opts

	// tausq() option added 24th July 2017
	// bartlett and z (i.e. "not LR" options) added 5th March 2018; "z" returns signed LR statistic (as opposed to Wald-type) as of Jan 2019
	// robust option added 13th Dec 2018
	// skovgaard option added 5th Jan 2019

	// Jan 2021: `label'
	local islabel = (`"`label'"'!=`""')		// user has invoked the option in some form
	gettoken label : label					// remove outer quotes
	
	// Oct 2020: `model' can either be a set of three numeric values, or a (valid) model name
	tokenize `model'
	if `"`2'"'!=`""' {
		cap numlist "`model'", min(3) max(3)
		if _rc {
		    nois disp as err `"Invalid model name:  `model'"'
			exit 198
		}
		args _ES_ _LCI_ _UCI_
		cap {
			assert `_LCI_' <= `_ES_'
			assert `_UCI_' >= `_ES_'
		}
		if _rc {
			nois disp as err `"Must supply user-defined analysis in the format  {it:ES lci uci}"'
			nois disp as err `"(supplied was `model')"'
			exit _rc
		}
		local userstats : copy local model
		local model user
		local teststat user
	}
		
	// Else, assume that `model' is a (valid) model name; continue parsing
	else {
	
		// global options
		if "`hksj'`hknapp'`khartung'"!="" local hksj_opt hksj
		if "`kroger'"!="" local kr_opt kroger

		// Test statistic and heterogeneity options: should be unique
		local teststat `t' `z' `chi2' `cmh' `cmhnocc'
		opts_exclusive `"`teststat'"' `""' 184
		
		// Tausq estimators, with synonyms
		local 0 `", `model'"'
		syntax [, COMMON IVCommon INVVariance IVariance FIXed MHaenszel Random DLaird HMakambi MLe MPaule PMandel EBayes CAnova HEdges SEnsitivity * ]
		if inlist("`model'", "fe", "iv") ///
			| "`fixed'`common'`ivcommon'`invvariance'`ivariance'"!="" local model iv	// Fixed (common)-effects inverse-variance	
		else if "`model'"=="re" | "`random'`dlaird'"!="" local model dl			// DerSimonian-Laird random-effects
		else if "`mhaenszel'"!="" local model mh								// Mantel-Haenszel methods
		else if "`hmakambi'"!="" local model hm									// Hartung-Makambi non-zero estimator
		else if "`mle'"!="" local model ml										// Maximum Likelihood estimator
		else if inlist("`model'", "bdl", "dlb") local model dlb					// Bootstrap DerSimonian-Laird (Kontopantelis)
		else if inlist("`model'", "gq", "genq", "vb") ///
			| "`mpaule'`pmandel'`ebayes'"!="" local model mp					// Mandel-Paule aka Generalised Q aka Empirical Bayes
		else if "`model'"=="vc" | "`canova'`hedges'"!="" local model he			// Hedges aka "variance-component" aka Cochran's ANOVA-type estimator
		else if inlist("`model'", "sj2", "sj2s") local model sj2s				// Sidik-Jonkman two-step (default init=vc)
		else if inlist("`model'", "dk2", "dk2s") local model dk2s				// DerSimonian-Kacker two-step (default init=vc)
		else if "`model'"=="sa" | "`sensitivity'"!="" local model sa			// Sensitivity analysis (at fixed Isq) as suggested by Kontopantelis
		
		// Other model types (with synonyms)
		else {
			local 0 `", `options'"'
			syntax [, Gamma BTweedie HCopas MUltiplicative FVariance FULLVariance IVHet HKSj HKnapp KHartung KRoger QEffects QUality * ]
			if "`model'"=="bs" | "`gamma'`btweedie'"!="" local model bt				// Biggerstaff-Tweedie approx. Gamma-based model
			else if "`hcopas'"!="" local model hc									// Henmi-Copas model
			else if "`multiplicative'`fvariance'`fullvariance'"!="" local model mu	// Multiplicative heterogeneity (aka Sandercock's "full variance")
			else if "`ivhet'"!="" local model ivhet									// Doi's IVhet ("inverse-variance heterogeneity") model
			else if "`hksj'`hknapp'`khartung'"!="" local model hksj					// Hartung-Knapp-Sidik-Jonkman variance correction
			else if "`kroger'"!="" local model kr									// Kenward-Roger variance correction
			else if "`qeffects'`quality'"!="" local model qe						// Doi's Quality Effects model
		}
		
		// Hartung-Knapp-Sidik-Jonkman variance correction
		if "`hksj_opt'"!="" {
			if "`model'"=="hksj" local model dl
			else if inlist("`model'", "mu", "bt", "kr", "hc", "ivhet", "qe", "pl") {
				nois disp as err `"Specified random-effects model is incompatible with Hartung-Knapp-Sidik-Jonkman variance estimator"'
				exit 184
			}
		}
		else if "`model'"=="hksj" {
			local model dl		// DL is default tausq estimator
			local hksj_opt hksj
		}
				
		// Kenward-Roger variance correction: this is basically REML, so allow "reml, kr" as an alternative
		if "`kr_opt'"!="" {
			if !inlist("`model'", "", "kr", "reml") {
				nois disp as err "Kenward-Roger variance estimator may only be combined"
				nois disp as err " with the REML estimator of tau{c 178}"
				exit 184
			}
			local model reml
		}
		else if "`model'"=="kr" {
			local model reml
			local kr_opt kroger
		}
		
		// observed/expected information matrix for Kenward-Roger
		if `"`eim'`oim'"'!=`""' {
			cap assert "`kr_opt'"!=""
			if _rc {
				nois disp as err `"Options {bf:eim} and {bf:oim} are only appropriate with the Kenward-Roger variance estimator"'
				exit 184
			}
			else {
				cap assert `: word count `eim' `oim'' == 1
				if _rc {
					nois disp as err `"May only specify one of {bf:eim} or {bf:oim}, not both"'
					exit _rc
				}
			}
		}
		else if "`kr_opt'"!="" local eim eim		// default		
		
		// Sidik-Jonkman robust ("sandwich-like") variance estimator
		if "`robust'"!="" {
			if inlist("`model'", "mu", "bt", "hc", "ivhet", "qe", "pl") | "`kr_opt'"!="" {
				nois disp as err `"Specified random-effects model is incompatible with Sidik-Jonkman robust variance estimator"'
				exit 184
			}
		}
		
		// Two-step models
		if !inlist("`model'", "sj2s", "dk2s") {
			if "`init'"!=`""' {
				nois disp as err `"Option {bf:init()} is only valid with two-step estimators of tausq"'
				exit 184
			}
		}
		else {
			// default initial estimate
			if "`init'"==`""' {
				local init = cond("`model'"=="sj2s", "ev", "he")
			}
			
			// user-specified initial estimate
			else {
				local 0 `", `init'"'
				syntax [, CAnova HEdges /*SEnsitivity*/ DLaird HMakambi MPaule PMandel EBayes * ]
				if "`canova'`hedges'"!="" | "`init'"=="vc" local init he										// Hedges/Cochran/Variance-component
				else if inlist("`init'", "gq", "genq", "vb") | "`mpaule'`pmandel'`ebayes'"!="" local init mp	// Mandel-Paule aka Generalised Q aka Empirical Bayes
				// else if "`init'"=="sa" | "`sensitivity'"!="" local init sa
				else if "`hmakambi'"!="" local init hm
				else if "`dlaird'"!="" local init dl
				else if "`init'"=="bdl" local init dlb
			}
			
			if "`model'"=="dk2s" {						// DerSimonian-Kacker two-step is valid for MM estimators only
				// if !inlist("`init'", "he", "dl", "sa") {
				if !inlist("`init'", "he", "dl") {
					nois disp as err `"Option {bf:init()} must be {bf:hedges} or {bf:dlaird} with DerSimonian-Kacker two-step estimator"'
					exit 184
				}
			}
			else {
				if !(inlist("`init'", "he", "dl", "dlb", "ev", "hm") /*, "sa"*/ | inlist("`init'", "b0", "bp", "mp", "ml", "reml")) {
					nois disp as err `"Invalid {bf:init()} option with Sidik-Jonkman two-step estimator"'
					exit 184
				}
			}
			local init_opt `"init(`init')"'
		}
			
		// Quality effects
		if "`model'"=="qe" {
			if `"`qwt'"'==`""' {
				nois disp as err "Quality-effects model specified but no quality weights found"
				exit 198
			}
			local qe_opt `"qwt(`qwt')"'
		}
		else if `"`qwt'"'!=`""' {
			nois disp as err "Quality weights cannot be specified without quality-effects model"
			exit 198
		}

		// conflicting options: variance modifications
		opts_exclusive `"`hksj_opt' `bartlett' `skovgaard' `robust'"' model 184

		// Bartlett and Skovgaard likelihood corrections: profile likelihood only
		if `"`bartlett'`skovgaard'"'!=`""' {
			cap assert "`model'"=="pl"
			if _rc {
				local errtext = cond(`"`bartlett'"'!=`""', `"Bartlett's"', `"Skovgaard's"')
				nois disp as err `"`errtext' correction is only valid with Profile Likelihood"'
				exit 184
			}
		}
		
		// truncate() option: multiplicative or HKSJ only
		if `"`truncate'"'!=`""' {
			cap assert "`model'"=="mu" | "`hksj_opt'"!=""
			if _rc {
				nois disp as err `"{bf:truncate()} option is only valid with HKSJ model or with Multiplicative Heterogeneity"'
				exit 184
			}
		}	
		
		// dependencies
		if inlist("`model'", "mp", "ml", "pl", "reml", "bt", "hc") {
			capture mata mata which mm_root()
			if _rc {
				nois disp as err `"Iterative tau-squared calculations require the Mata function {bf:mm_root()} from {bf:moremata}"'
				nois disp as err `"Type {stata ssc describe moremata:ssc install moremata} to install it"'
				exit 499
			}
			if inlist("`model'", "bt", "hc") {
				capture mata mata which integrate()
				if _rc {
					if "`model'"=="bt" nois disp as err `"Biggerstaff-Tweedie model requires the Mata function {bf:integrate()}"'
					else nois disp as err `"Henmi-Copas model requires the Mata function {bf:integrate()}"'
					nois disp as err `"Type {stata ssc describe integrate:ssc install integrate} to install it"'
					exit 499
				}
			}
		}
		if "`model'"=="dlb" {
			capture mata mata which mm_bs()
			local rc1 = _rc
			capture mata mata which mm_jk()
			if _rc | `rc1' {
				nois disp as err `"Bootstrap DerSimonian-Laird method requires the Mata functions {bf:mm_bs()} and {bf:mm_jk()} from {bf:moremata}"'
				nois disp as err `"Type {stata ssc describe moremata:ssc install moremata} to install them"'
				exit 499
			}
		}
		
		// final check for valid random-effects models:
		if !inlist("`model'", "", "user", "iv", "mh", "peto", "mu") ///         I-V common-effect, Mantel-Haenszel, Peto, mult. het. [PLUS USER-DEFINED]
			& !inlist("`model'", "dl", "dlb", "ev", "he", "hm", "b0", "bp") /// simple tsq estimators (non-iterative)
			& !inlist("`model'", "mp", "ml", "reml") ///                        simple tsq estimators (iterative)
			& !inlist("`model'", "sj2s", "dk2s", "sa") ///                      two-step estimators; sensitivity analysis at fixed tsq/Isq
			& !inlist("`model'", "pl", "bt", "hc", "qe", "ivhet") {			// complex models
			nois disp as err `"Invalid random-effects model"'
			nois disp as err `"Please see {help metan_model:help metan} for a list of valid model names"'
			exit 198
		}
		
		// default model if none defined
		if `"`model'"'==`""' {
			local modelorig null			// marker that model was *not* specified by user
			local model = cond(`params'==4, "mh", "iv")
		}
		
		if inlist("`model'", "mh", "peto") {
			cap assert `params'==4 | "`logrank'"!=""
			if _rc {
				nois disp as err "Mantel-Haenszel and Peto options only valid with 2x2 count data"
				exit 184
			}
		}
	}
	
	
	** PARSE "GLOBAL" OPTIONS (if applicable)
	// N.B. global opts will already have been checked against the data structure by ProcessInputVarlist
	//  it only remains to check them against the *model* (and teststat/hetstat)
	opts_exclusive `"`cc' `cc2'"' `""' 184
	local old_ccopt `"`cc'`cc2'"'
	foreach opt in wgt truncate isq tausq tn itol maxtausq reps maxiter quadpts difficult technique {
		local old_`opt' : copy local `opt'
	}
		
	local 0 `", `globalopts'"'
	syntax [, Z T CHI2 CMH CMHNocc ///
		CC(passthru) noCC2 WGT(passthru) TRUNCate(passthru) ISQ(string) TAUSQ(string) TN(passthru) ///
		ITOL(passthru) MAXTausq(passthru) REPS(passthru) MAXITer(passthru) QUADPTS(passthru) DIFficult TECHnique(passthru) * ]
		// last line ^^  "global" opts to compare with "specific model" opts
		// add "*" as this macro also contains `opts_adm' (not relevant to this subroutine)

	local opts_adm `"`macval(options)'"'
	
	local gTestStat `t' `z' `chi2' `cmh' `cmhnocc'
	opts_exclusive `"`gTestStat'"' `""' 184
	
	opts_exclusive `"`cc' `cc2'"' `""' 184
	local ccopt    `"`cc'`cc2'"'

	foreach opt in ccopt wgt truncate isq tausq tn itol maxtausq reps maxiter quadpts difficult technique {
		if `"`old_`opt''"'!=`""' {
			local `opt' : copy local old_`opt'
		}
	}
	
	// If user-defined weights, summstat not specified and `params'==4, assume I-V Common rather than exit with error
	// This matches with previous -metan9- behaviour.
	// (do this now, so that hetstat is processed correctly.  user-defined weights are otherwise processed later)
	if `"`wgt'"'!=`""' & "`model'"=="mh" & "`modelorig'"=="null" {
		local model iv
		disp `"{error}Note: user-defined weights supplied; inverse-variance model assumed"'
	}

	
	** TEST STATISTICS
	if "`model'"!="mh" | "`summstat'"!="or" {
		if inlist("`teststat'", "cmh", "cmhnocc") {
			nois disp as err "Cannot specify {bf:`teststat'} test option without Mantel-Haenszel odds ratios"
			exit 184
		}
		else if "`teststat'"=="" & inlist("`gTestStat'", "cmh", "cmhnocc") {
			// disp `"{error}Note: global option {bf:`gTestStat'} is not applicable to all models; local defaults will apply"'
			local gl_error `gl_error' `gTestStat'
		}
	}
	
	// Profile likelihood: cannot use t-based confidence interval
	// (or z with Bartlett's correction)
	if "`model'"=="pl" {
		if "`bartlett'"!="" {
			if "`teststat'"=="z" {
				nois disp as err `"Cannot specify option {bf:z} with Bartlett's correction"'
				exit 184
			}
			else if "`teststat'"=="" & "`gTestStat'"=="z" {
				// disp `"{error}Note: global option {bf:z} is not applicable to all models; local defaults will apply"'
				local gl_error `gl_error' z
			}
		}
		else if "`teststat'"=="t" {
			nois disp as err `"Cannot specify option {bf:t} with Profile Likelihood"'
			exit 184
		}
		else if "`teststat'"=="" & "`gTestStat'"=="t" {
			// disp `"{error}Note: global option {bf:t} is not applicable to all models; local defaults will apply"'
			local gl_error `gl_error' t
		}		
	}
	
	// MH, Peto and PL uses chi2 as default; HKSJ and Robust methods use t as default.
	// All three can be overridden with "z" option.
	// (Note that PL with "z" uses signed likelihood statistic.)
	else if "`model'"=="hc" {
		if "`teststat'"!="" {
			nois disp as err "Cannot specify option {bf:`teststat'} with Henmi-Copas model"
			exit 184
		}
		else if "`gTestStat'"!="" {
			// disp `"{error}Note: global option {bf:`gTestStat'} is not applicable to all models; local defaults will apply"'
			local gl_error `gl_error' `gTestStat'
		}		
		local teststat u
	}
	
	// Default teststat
	if !inlist("`summstat'", "or", "") & !(inlist("`summstat'", "hr", "") & "`logrank'"!="") {
		if "`teststat'"=="chi2" {
			nois disp as err "Cannot specify {bf:chi2} test option without Mantel-Haenszel odds ratios"
			exit 184
		}
	}	
	if "`teststat'"=="" {
		if "`gTestStat'"!="" local teststat `gTestStat'
		else {
			if "`model'"=="peto" | "`logrank'"!="" local teststat chi2
			else if "`bartlett'"!="" local teststat chi2_lr						// [Jan 2020]
			if "`hksj_opt'`kr_opt'`robust'"!="" local teststat t
			if "`teststat'"=="" local teststat z
		}
	}
	if "`model'"=="mh" {
		local cmhnocc
		if inlist("`teststat'", "cmh", "cmhnocc", "chi2") {
			if "`teststat'"!="cmh" local cmhnocc cmhnocc		// MH: cmhnocc is the same as chi2
			local teststat chi2
		}
		// N.B. Example reference for the difference between "cmh" and "cmhnocc" is:
		// McDonald, J.H. 2014. Handbook of Biological Statistics, 3rd ed. Sparky House Publishing, Baltimore, Maryland
		// cmhnocc is undocumented, since McDonald suggests use of correction factor is best
		// (correction factor is also implemented by default in "metafor" by Wolfgang Viechtbauer)
	}
	
	
	** SENSITIVITY ANALYSIS
	if "`model'"=="sa" {
		if `"`tausq'"'!=`""' {
			cap confirm number `tausq'
			if _rc {
				nois disp as err `"Error in {bf:tausq()} suboption to {bf:sa()}; a single number was expected"'
				exit _rc
			}
			if `tausq'<0 {
				nois disp as err `"tau{c 178} value for sensitivity analysis cannot be negative"'
				exit 198
			}
			local tsqsa_opt `"tsqsa(`tausq')"'
			if !`islabel' local label = `"SA(tau{c 178}="' + strofreal(`tausq', "%05.3f") + `")"'
		}
		
		else {
			if `"`isq'"'==`""' local isq = 80
			else {
				cap confirm number `isq'
				if _rc {
					nois disp as err `"Error in {bf:isq()} suboption to {bf:sa()}; a single number was expected"'
					exit _rc
				}
				if `isq'<0 | `isq'>=100 {
					nois disp as err `"I{c 178} value for sensitivity analysis must be at least 0% and less than 100%"'
					exit 198
				}
			}
			local isqsa_opt `"isqsa(`isq')"'
			if !`islabel' local label `"SA(I{c 178}=`isq'%)"'
		}
		
		if `: word count `tsqsa' `isqsa'' >=2 {
			nois disp as err `"Only one of {bf:isq()} or {bf:tausq()} may be supplied as suboptions to {bf:sa()}"'
			exit 184
		}
	}
	
	// if NOT sensitivity analysis
	else {
		if `"`isq'"'!=`""' {
			nois disp as err `"option {bf:isq()} may only be specified when requesting a sensitivity analysis model"'
			exit 184
		}
		if `"`tausq'"'!=`""' {
			nois disp as err `"option {bf:tausq()} may only be specified when requesting a sensitivity analysis model"'
			exit 184
		}
	}
	

	** OTHER OPTIONS
	// Continuity correction: some checks needed for specific option, others for global... do them all together here
	if `params'!=4 & "`proportion'"=="" {
		if `"`ccopt'"'!=`""' {
			nois disp as err "Continuity correction only valid with proportions or 2x2 count data"
			exit 184
		}
	}
	else {
		local 0 `", `ccopt'"'
		syntax [, CC(string) noCC2]

		if `"`cc'"'!=`""' {
			local 0 `"`cc'"'
			syntax [anything(name=ccval id="value supplied to {bf:cc()}")] [, ALLifzero OPPosite EMPirical]
			if `"`ccval'"'!=`""' {
				confirm number `ccval'
			}
			else local ccval = 0.5
			
			if `"`cc2'"'!=`""' & `ccval' != 0 {
				nois disp as err `"Cannot specify both {bf:cc()} and {bf:nocc}; please choose one or the other"'
				exit 184
			}

			if "`proportion'"!="" {
				if "`opposite'"!="" {
					nois disp as err "Opposite-arm continuity correction only valid with 2x2 count data"
					exit 184
				}
				if "`empirical'"!="" {
					nois disp as err "Empirical continuity correction only valid with 2x2 count data"
					exit 184
				}
			}
			opts_exclusive `"`opposite' `empirical'"' cc 184

			// Empirical CC valid with odds ratio only
			if `"`empirical'"'!=`""' & "`summstat'"!="or" {
				nois disp as err "Empirical continuity correction only valid with odds ratios"
				exit 184
			}

			// ensure continuity correction is valid
			if "`model'"=="peto" {
				nois disp as err "Continuity correction is incompatible with Peto method"
				exit 184
			}
			else if "`proportion'"!="" & inlist("`summstat'", "arcsine", "ftukey") {
				disp `"{error}Note: Continuity correction is not necessary with {bf:`summstat'} transformed proportions; option will be ignored"'
			}
			else {
				cap assert `ccval'>=0 & `ccval'<1
				if _rc {
					nois disp as err "Invalid continuity correction: must be in range [0,1)"
					exit _rc
				}
			}
			local ccval_orig : copy local ccval
		}
		else {							// Amended May 2020
			if `"`cc2'"'!=`""' | inlist("`model'", "mh", "peto", "user") ///
				| ("`proportion'"!="" & inlist("`summstat'", "arcsine", "ftukey")) {
				local ccval = 0
			}
			else local ccval = 0.5		// default
			local ccval_orig = 0.5
		}
		
		if `ccval'==0 & !(`"`cc2'"'!=`""' | `ccval_orig'==0) & "`summstat'"!="rd" {
			// Macro for uncorrected M-H, so that study estimates & weights *are* corrected if necessary
			// [ but *not* if correction was explicitly set to zero, via either nocc or cc(0) ]
			// [ and *not* for Risk Differences ]
			if "`model'"=="mh" local ccopt_final `"cc(0.5, `allifzero' mhuncorr)"'
		}
		else local ccopt_final `"cc(`ccval', `allifzero' `opposite' `empirical')"'
	}

	// chi2 is only valid with:
	// - 2x2 Odds Ratios (including Peto)
	// - logrank HR
	// - Profile Likelihood ... but this is stored separately, as `chi2_lr' [Jan 2020]
	if "`teststat'"=="chi2" {
		if "`summstat'"=="rr" & "`summorig'"=="null" & `params'==4 {
			local summstat or
			local summnew or
			disp `"{error}Note: Chi-squared option or Peto model specified; odds ratios assumed"'
		}
	
		cap assert (inlist("`summstat'", "or", "") & `params'==4) | "`logrank'"!=""
		if _rc {
			nois disp as err `"Option {bf:chi2} is incompatible with other options"' 
			exit 184
		}
	}
	else if "`teststat'"=="chi2_lr" local teststat chi2		// now combine the two [Jan 2020]
	
	// User-defined weights
	if `"`wgt'"'!=`""' {
	
		// Only "vanilla" random-effects models are compatible
		// (i.e. those which simply estimate tau-squared and use it in the standard way)
		if "`model'"=="peto"    local model_err peto
		else if "`model'"=="mh" local model_err mhaenszel
		else if "`model'"=="bt" local model_err btweedie
		else if "`model'"=="hc" local model_err hcopas
		else if "`model'"=="ivhet" local model_err ivhet
		else if "`model'"=="qe" local model_err qe
		else if "`model'"=="mu" local model_err mult
		else if "`model'"=="pl" local model_err pl
		else if "`kr_opt'"!="" local model_err kroger
		if "`model_err'"!="" {
			nois disp as err "User-defined weights can only be used with models based on the inverse-variance method"
			nois disp as err "  which does not include {bf:`model_err'}"
			exit 184
		}
	}
	else if "`model'"=="user" & "`first'"!="" {
		nois disp as err `"Must supply weight variable with option {bf:wgt(}{it:varname}{bf:)}"'
		nois disp as err `" with user-supplied effect sizes"'
		exit 198
	}

	// [Modified Oct 2020]
	// Model description to display on-screen (shorthand, in case of multiple models)
	if !`islabel' {
		if "`model'"=="peto" local label Peto
		else if "`model'"=="ivhet" local label IVhet
		else if "`model'"=="dlb" local label DLb
		else if "`model'"=="ev" local label "Emp. Var."
		else if inlist("`model'", "bp", "b0") local label = "Rukhin " + upper("`model'")	
		else if "`model'"=="user" local label User
		else if "`model'"!="sa" local label = upper("`model'")

		if "`hksj_opt'"!="" local label "`label'+HKSJ"
		if "`kr_opt'"!=""   local label "`label'+KR"
		if "`robust'"!=""   local label "`label'+Rob."
		if "`bartlett'"!="" local label "`label'+Bart."
		if "`skovgaard'"!="" local label "`label'+Skov."
	}
	
	if "`model'"!="user" & `"`extralabel'"'!=`""' {
		nois disp as err `"Cannot specify option {bf:extralabel()} other than with user-specified effect sizes"'
		exit 198
	}	
	
	
	** COLLECT OPTIONS AND RETURN
	sreturn clear

	// Model options
	local modelopts `"`cmhnocc' `robust' `hksj_opt' `kr_opt' `bartlett' `skovgaard' `eim' `oim' `ccopt_final' `tn'"'
	local modelopts `"`modelopts' `wgt' `truncate' `tsqlevel' `isqsa_opt' `tsqsa_opt' `qe_opt' `init_opt'"'
	local modelopts `"`modelopts' `itol' `maxtausq' `reps' `maxiter' `quadpts' `difficult' `technique'"'
	local modelopts = trim(itrim(`"`modelopts'"'))
	
	// Return
	sreturn local model `model'
	sreturn local modelorig `modelorig'
	sreturn local teststat `teststat'
	if `"`wgt'"'!=`""' sreturn local wgtopt `"`wgt'"'
	else sreturn local wgtopt default

	sreturn local modelopts  `"`modelopts'"'		// Additional model options (for PerformPooling)
	sreturn local labelopt   `"`label'"'			// Model label (for DrawTableAD)
	sreturn local extralabel `"`extralabel'"'		// "Extra" model label (e.g. heterogeneity; for DrawTableAD)
	sreturn local userstats  `"`userstats'"'		// User-supplied effect sizes
	
	// Remaining options
	sreturn local opts_adm `"`macval(opts_adm)'"'
	
	// Corrective macro
	sreturn local summnew `summnew'
	
	// Error prompts
	sreturn local gl_error `gl_error'
	
end





********************************************************************************

* PerformMetaAnalysis
// Create list of "pooling" variables
// Run meta-analysis on whole dataset ("overall") and, if requested, by subgroup
// If cumul/influence, subroutine "CumInfLoop" is run first, to handle the intermediate steps
// Then (in any case), subroutine "PerformPooling" is run.
// (called directly by metan.ado)

// N.B. [Sep 2018] takes bits of old (v2.2) MainRoutine and PerformMetaAnalysis subroutines

// SEP 2019:  We are now doing this **one model at a time**


program define PerformMetaAnalysis, rclass sortpreserve

	syntax varlist(numeric min=3 max=7) [if] [in], SORTBY(varlist) MODEL(name) ///
		[BY(string) BYLIST(numlist miss) SUMMSTAT(name) TESTSTAT(name) QSTAT(passthru) ///
		TESTBased ISQParam ROWNAMES(namelist) FIRST /* N.B. "first" is marker that this is the first/main/primary model */ ///
		OUTVLIST(varlist numeric min=5 max=9) XOUTVLIST(varlist numeric) PRVLIST(passthru) ///
		noOVerall noSUbgroup OVWt SGWt ALTWt WGT(varname numeric) CUmulative INFluence PRoportion noINTeger ///
		LOGRank ILevel(passthru) OLevel(passthru) RFDist RFLevel(passthru) HLevel(passthru) CCVAR(name) CC(passthru) KRoger /// from `opts_model'; needed in main routine
		* ]

	local opts_model `"`macval(options)' `kroger'"'		// model`j'opts; add `kroger' back in
														// (this means it is duplicated, but `opts_model' is only used in this subroutine so it shouldn't matter)
	marksample touse, novarlist		// -novarlist- option prevents -marksample- from setting `touse' to zero if any missing values in `varlist'
									// we want to control this behaviour ourselves, e.g. by using KEEPALL option
	gettoken _USE invlist : varlist
	tokenize `outvlist'
	args _ES _seES _LCI _UCI _WT _NN

	local nrfd = 0		// initialize marker of "less than 3 studies" (for rfdist)
	local nmiss = 0		// initialize marker of "pt. numbers are missing in one or more trials"
	local nsg = 0		// initialize marker of "only a single valid estimate" (e.g. for by(), or cumul/infl)
	local nzt = 0		// initialize marker of "HKSJ has resulted in a shorter CI than IV" (for HKSJ)
	
	// sensitivity analysis
	// [Jan 2020: remove this, but first check how "single tausq" subgroup analysis works (c.f. R book)]
	if "`model'"=="sa" & "`by'"!="" {
		nois disp as err `"Sensitivity analysis cannot be used with {bf:by()}"'
		exit 184
	}

	* Create list of "pooling" tempvars to pass to ProcessPoolingVarlist
	// and thereby create final generic list of "pooling" vars to use within MetaAnalysisLoop
	// (i.e. tempvars that are only needed within this subroutine)
	
	// Logic:
	// If M-H pooling, then M-H heterogeneity
	// If Peto pooling, then Peto heterogeneity
	// If generic I-V with 2x2 count data, then either Cochran or M-H heterogeneity (or Breslow-Day, but only if OR)
	
	// So:
	// M-H heterogeneity if (a) M-H pooling or (b) generic I-V (common or random) with 2x2 count data and cochran/breslow not specified (M-H is default in this situation)
	// Peto heterogeneity if (a) Peto pooling or (b) generic I-V (common or random) with 2x2 count data and cochran/breslow not specified AND OR/HR ONLY
	// Breslow-Day heterogeneity only if OR and user-specified
	// Cochran heterogeneity only if generic I-V (and user-specified if necessary)
	
	// So:
	// If OR + M-H then het can be only be M-H
	// If OR + Peto then het can only be Peto
	// If OR + Random I-V then het can be M-H (default), Peto, Breslow or Cochran -- the only situation where "peto" option can be combined
	// If OR + Common I-V then het can be Cochran (default) or Breslow

	// If HR + Peto then het can only be Peto
	// If HR + RE I-V then het can be Peto (default) or Cochran
	
	// If RR/RD + M-H then het can only be M-H
	// If RR/RD + RE I-V then het can be M-H (default) or Cochran
	
	// If anything else + Common I-V then het can only be Cochran
	
	local params : word count `invlist'
	if `params' > 3 | `"`logrank'`proportion'"'!=`""' {			// all except generic inverse-variance input

		if `params' == 4 {		// Binary outcome (OR, Peto, RR, RD)

			// only really need to define *here* for special case: M-H with all-zero cells in one arm, and Breslow-Day or Tarone requested
			// but tempvars would have to be defined within ProcessPoolingVarlist in any case, if zero cells
			tempvar e1_cc f1_cc e0_cc f0_cc
			local cclist `e1_cc' `f1_cc' `e0_cc' `f0_cc'	
		
			if "`summstat'"=="or" {
				if "`model'"=="mh" {							// extra tempvars for Mantel-Haenszel OR and/or het
					tempvar r s pr ps qr qs
					local tvlist `r' `s' `pr' `ps' `qr' `qs'
				}
				if inlist("`teststat'", "chi2", "cmh") | "`model'"=="peto" {	// extra tempvars for chi-squared test (incl. Peto OR and M-H CMH test)
					tempvar oe va
					local tvlist `tvlist' `oe' `va'
				}
			}

			else if inlist("`summstat'", "rr", "rrr") {			// RR/RRR
				tempvar r s
				local tvlist `r' `s'
				
				if "`model'"=="mh" {							// extra tempvars for Mantel-Haenszel OR and/or het
					tempvar p
					local tvlist `tvlist' `p'
				}
			}
			
			else if "`summstat'" == "rd" & "`model'"=="mh" {		// RD
				tempvar rdwt rdnum vnum
				local tvlist `rdwt' `rdnum' `vnum'
			}
			
			// May 2020: extra tempvar for M-H weights, in case of zero cells
			if "`model'"=="mh" & "`cc'"!="" {
				cap assert "`wgt'"==""
				if _rc {
					nois disp as err "User-defined weights can only be used with models based on the inverse-variance method"
					nois disp as err "  which does not include {bf:`model_err'}"
					exit 184
				}
				tempvar wgt
			}
		}
		
		//  Generate study-level effect size variables `_ES' and `_seES',
		//  plus variables used to generate overall/subgroup statistics
		cap nois ProcessPoolingVarlist `_USE' `invlist' if `touse', ///
			summstat(`summstat') model(`model') teststat(`teststat') outvlist(`outvlist') tvlist(`tvlist') cclist(`cclist') wgt(`wgt') ///
			`proportion' `prvlist' `integer' `logrank' `cc' ccvar(`ccvar') `ilevel' `olevel'
		
		if _rc {
			nois disp as err `"Error in {bf:metan.ProcessPoolingVarlist}"'
			c_local err noerr		// tell -metan- not to also report an "error in metan.PerformMetaAnalysis"
			exit _rc
		}

		local oevlist  `s(oevlist)'
		local mhvlist  `s(mhvlist)'

		// May 2020: if M-H continuity correction not specified, but found to be necessary due to all zero-cells
		if `"`mhallzero'"'!=`""' {
			if `"`s(invlist)'"'!=`""' local invlist `s(invlist)'	// so that Breslow-Day or Tarone statistics (for ORs) are calculated using corrected counts
			local opts_model `"`macval(opts_model)' `mhallzero'"'
			c_local mhallzero `mhallzero'
		}
		
	}	// end if `params' > 3 | "`logrank'`proportion'"!=""

	// Special case:  need to generate `_seES' if ES + CI were provided; assume normal distribution and 95% coverage
	else if `params'==3 {
		if `"`ilevel'"'!=`""' {
			tokenize `invlist'			// if ilevel() option supplied, requesting coverage other than 95%,
			args _ES_ _LCI_ _UCI_		// need to derive _seES from the *original* confidence limits supplied in `invlist' (assumed to be 95% !!)
		}
		else {
			local _LCI_ `_LCI'
			local _UCI_ `_UCI'
		}
		qui replace `_seES' = (`_UCI_' - `_LCI_') / (2*invnormal(.5 + 95/200)) if `touse' & `_USE'==1
	}
	
	// If model is "user",
	//  having generated _ES, _LCI and _UCI, normalise user-supplied weights but then exit
	if "`model'"=="user" {
		if "`first'"!="" {		// if first model is "user"

			// weights
			summ `wgt' if `touse', meanonly
			qui replace `_WT' = 100 * `wgt' / r(sum) if `touse' & `_USE'==1
			
			// total number of patients
			if `"`_NN'"'!=`""' {
				summ `_NN' if `touse' & `_USE'==1, meanonly
				return scalar n = r(sum)
			}
			
			// total number of studies
			qui count if `touse' & `_USE'==1		
			return scalar k = r(N)
			
			// [Nov 2020:] derive Cochran's Q
			// needed in the special case that first model is "user" but at least one later model is not
			// (not an issue with previous -metan- code)
			tempname eff
			summ `_ES' [aw=1/`_seES'^2] if `touse', meanonly
			scalar `eff' = r(mean)
			
			tempvar qhet
			qui gen double `qhet' = ((`_ES' - `eff')/`_seES')^2
			summ `qhet' if `touse', meanonly

			return scalar Q = cond(r(N), r(sum), .)
			return scalar Qdf = cond(r(N), r(N)-1, .)
		}
		
		c_local nrfd  = `nrfd'		// update marker of "less than 3 studies" (for rfdist)
		c_local nmiss = `nmiss'		// update marker of "pt. numbers are missing in one or more trials"
		c_local nsg   = `nsg'		// update marker of "only a single valid estimate" (e.g. for by(), or for cumul/infl)
		c_local nzt   = `nzt'		// update marker of "HKSJ has resulted in a shorter CI than IV" (for HKSJ)
		
		exit 0					// exit subroutine and continue without error
	}
	
	// if B0 estimator, must have _NN for all studies with an effect size (i.e. `_USE'==1)
	if "`model'"=="b0" {
		cap {
			confirm numeric var `_NN'
			assert `_NN'>=0 & !missing(`_NN') if `_USE'==1
		}
		if _rc {
			nois disp as err `"Participant numbers not available for all studies; cannot calculate B0 tau{c 178} estimator"'
			exit 416				// 416 = "missing values encountered"
		}
		local nptsopt npts(`_NN')	// to send to PerformPooling / CumInfLoop
	}								// N.B. `npts' is otherwise undefined in this subroutine
	
	// numbers of studies and patients
	tempname k n
	scalar `k' = .
	scalar `n' = .
	
	// Moved/amended March 2020 (replaces `cumulflag')
	if `"`cumulative'`influence'"' != `""' {
		tempvar obsj
		qui gen long `obsj' = .
	}
	
	
	
	********************
	* Overall analysis *
	********************
		
	if `"`overall'"'==`""' | `"`ovwt'"'!=`""' {
		
		// May 2020: Usually, `rN' should equal r(k)
		// BUT if 2x2 count data (or proportion data) and nocc then mh and peto will use all studies = `rN'
		//  but iv-based methods can only use studies with non-missing _ES and _seES = r(k)
		// Hence, for later logic-checking, setup r(k)==`rN' or <=`rN' as appropriate.
		// (Note: back in the main routine, a final check will be made that all observations are handled correctly via _USE)
		local equals `"=="'
		cap confirm numeric variable `ccvar'
		if !_rc & (`params'==4 | `"`proportion'"'!=`""') {
			summ `ccvar' if `touse' & `_USE'==1, meanonly
			if r(N) local equals `"<="'
		}

		// if ovwt, pass `_WT' to PerformPooling to be filled in
		// otherwise, PerformPooling will generate a tempvar, and `_WT' will remain empty
		local wtvar = cond(`"`ovwt'"'!=`""', `"`_WT'"', `""')

		
		** Cumulative/influence analysis
		// Run extra loop to store results of each iteration within the currrent dataset (`xoutvlist')
		if `"`cumulative'`influence'"' != `""' {

			// Moved/amended March 2020
			qui bysort `touse' `_USE' (`sortby') : replace `obsj' = _n if `touse' & `_USE'==1
		
			cap nois CumInfLoop `_USE' `_ES' `_seES' if `touse' & `_USE'==1, sortby(`obsj') ///
				model(`model') summstat(`summstat') teststat(`teststat') `qstat' `testbased' `isqparam' ///
				mhvlist(`mhvlist') oevlist(`oevlist') invlist(`invlist') xoutvlist(`xoutvlist') ///
				wgt(`wgt') wtvar(`wtvar') rownames(`rownames') `nptsopt' ///
				`cumulative' `influence' `integer' `logrank' `proportion' `ovwt' ///
				`olevel' `rfdist' `rflevel' `hlevel' `opts_model'
			
			if _rc {
				if `"`err'"'==`""' {
					if _rc==1 nois disp as err `"User break in {bf:metan.CumInfLoop}"'
					else nois disp as err `"Error in {bf:metan.CumInfLoop}"'
				}
				c_local err noerr		// tell -metan- not to also report an "error in metan.PerformMetaAnalysis"
				exit _rc
			}

			local xwt `r(xwt)'			// extract _WT2 from `xoutvlist'
		}

		
		** Main meta-analysis
		// If only one study, display warning message if appropriate
		// (the actual change in method is handled by PerformPooling)
		qui count if `touse' & `_USE'==1
		local rN = r(N)
		if `rN'==1 {
			if !inlist("`model'", "iv", "mh", "peto", "mu") {
				disp `"{error}Note: Only one estimate found; random-effects model not used"'
			}
		}
		
		cap nois PerformPooling `_ES' `_seES' if `touse' & `_USE'==1, ///
			model(`model') summstat(`summstat') teststat(`teststat') `qstat' `testbased' `isqparam' ///
			mhvlist(`mhvlist') oevlist(`oevlist') invlist(`invlist') `nptsopt' wtvar(`wtvar') wgt(`wgt') ///
			`integer' `logrank' `proportion' `rfdist' `rflevel' `olevel' `hlevel' `opts_model'

		if _rc {
			if _rc==2002 {
				if "`model'"=="mh" {
					nois disp as err _n "All studies have zero events in the same arm"
					nois disp as err "Mantel-Haenszel model cannot be used without continuity correction"
				}
				else nois disp as err "Pooling failed; either pooled effect size or standard error is undefined"
				
				if "`teststat'"=="chi2" {
					return scalar chi2 = r(chi2)
					return scalar crit = r(crit)
					return scalar pvalue = r(pvalue)
				}
			}
			if `"`err'"'==`""' {
				if _rc==1 nois disp as err `"User break in {bf:metan.PerformPooling}"'
				else nois disp as err `"Error in {bf:metan.PerformPooling}"'
			}
			c_local err noerr		// tell -metan- not to also report an "error in metan.MetaAnalysisLoop"
			exit _rc
		}
		
		// pooling failed
		cap assert !missing(r(eff), r(se_eff))
		if _rc {
			nois disp as err "Pooling failed; either pooled effect size or standard error is undefined"
			exit 2002
		}
		
		
		** If `cumulative', copy pooled results into final cumulative observation
		if `"`cumulative'"'!=`""' {
			local npts_el npts
			local xrownames : list rownames - npts_el			
			local xrownames `xrownames' Q Qdf Q_lci Q_uci
			if `: list posof "tausq" in rownames' local xrownames `xrownames' sigmasq
			
			tokenize `xoutvlist'
			args `xrownames' _WT2
			
			// Store (non-normalised) weight in the dataset
			qui replace `_WT2' = r(totwt) if `obsj' == `rN'

			// Store other returned statistics in the dataset
			foreach el of local xrownames {
				qui replace ``el'' = r(`el') if `obsj' == `rN'
			}
			
			// reset tokenize
			tokenize `outvlist'
			args _ES _seES _LCI _UCI _WT _NN
		}

		
		** Save statistics in matrix
		tempname ovstats
		local r : word count `rownames'
		matrix define   `ovstats' = J(`r', 1, .)
		matrix rownames `ovstats' = `rownames'
		
		// Remove unnecessary rownames from ovstats, e.g. if insufficient data to run desired model
		local toremove
		if inlist("`model'", "mh", "peto", "iv", "ivhet", "qe", "mu") ///
			| inlist("`model'", "bt", "hc", "pl") | "`kroger'"!="" {
			local toremove rflci rfuci
		}
		// if "`model'"=="peto" | "`teststat'"=="chi2" local toremove `toremove' z
		if inlist("`teststat'", "chi2", "t") local toremove `toremove' z
		if inlist("`model'", "peto", "mh", "iv", "mu") local toremove `toremove' tausq /*sigmasq*/
		cap confirm numeric var `_NN'
		if _rc local toremove `toremove' npts
		local rownames_reduced : list rownames - toremove
		return local rownames_reduced `"`rownames_reduced'"'
		
		foreach el of local rownames_reduced {
			local rownumb = rownumb(`ovstats', "`el'")
			if !missing(`rownumb') {
				matrix `ovstats'[`rownumb', 1] = r(`el')
			}
		}
				
		assert r(k) `equals' `rN'
		scalar `k' = r(k)				// overall number of studies
		
		// Warning messages & error codes r.e. confidence limits for iterative tausq
		if inlist("`model'", "mp", "ml", "pl", "reml", "bt") | "`kroger'"!="" {
			local maxtausq2 = r(maxtausq)		// take maxtausq from PerformPooling (10* D+L estimate)
			local 0 `", `opts_model'"'
			syntax [, MAXTausq(real -9) MAXITer(real 1000) * ]

			if !inlist("`model'", "dlb", "bt") {
				if r(rc_tausq)==1 disp `"{error}Note: tau{c 178} point estimate failed to converge within `maxiter' iterations"'
				else if r(rc_tausq)==3 {
					if `maxtausq'==-9 disp `"{error}Note: tau{c 178} greater than default value {bf:maxtausq(}`maxtausq2'{bf:)}; try increasing it"'
					else disp `"{error}Note: tau{c 178} greater than `maxtausq'; try increasing {bf:maxtausq()}"'
				}
				else if missing(r(tausq)) {
					nois disp as err `"Note: tau{c 178} point estimate could not be found; possible discontinuity in search interval"'
					exit 498
				}
				return scalar rc_tausq = r(rc_tausq)		// whether tausq point estimate converged
			}
			
			if "`model'"!="dlb" {
				local rc_tsq_lci = r(rc_tsq_lci)
				if r(rc_tsq_lci)==1 disp `"{error}Note: Lower confidence limit of tau{c 178} failed to converge within `maxiter' iterations; try increasing {bf:maxiter()}"'
				else if missing(r(tsq_lci)) {
					disp `"{error}Note: Lower confidence limit of tau{c 178} could not be found; possible discontinuity in search interval"'
					if `rc_tsq_lci'<=1 local rc_tsq_lci = 498
				}
					
				local rc_tsq_uci = r(rc_tsq_uci)
				if r(rc_tsq_uci)==1 disp `"{error}Note: Upper confidence limit of tau{c 178} failed to converge within `maxiter' iterations; try increasing {bf:maxiter()}"'
				else if r(rc_tsq_uci)==3 {
					if `maxtausq'==-9 disp `"{error}Note: Upper confidence limit of tau{c 178} greater than default value {bf:maxtausq(}`maxtausq2'{bf:)}; try increasing it"'
					else disp `"{error}Note: Upper confidence limit of tau{c 178} greater than `maxtausq'; try increasing {bf:maxtausq()}"'
				}
				else if missing(r(tsq_uci)) {
					disp `"{error}Note: Upper confidence limit of tau{c 178} could not be found; possible discontinuity in search interval"'
					if `rc_tsq_uci'<=1 local rc_tsq_uci = 498
				}
				return scalar rc_tsq_lci = `rc_tsq_lci'		// whether tausq lower confidence limit converged
				return scalar rc_tsq_uci = `rc_tsq_uci'		// whether tausq upper confidence limit converged
			}

			if "`model'"=="pl" {
				local rc_eff_lci = r(rc_eff_lci)
				if r(rc_eff_lci)==1 disp `"{error}Note: Lower confidence limit of effect size failed to converge within `maxiter' iterations; try increasing {bf:maxiter()}"'
				else if r(rc_eff_lci)>1 | missing(`r(eff_lci)') {
					disp `"{error}Note: Lower confidence limit of effect size could not be found; possible discontinuity in search interval"'
					if `rc_eff_lci'<=1 local rc_eff_lci = 498
				}
				local rc_eff_uci = r(rc_eff_uci)
				if r(rc_eff_uci)==1 disp `"{error}Note: Upper confidence limit of effect size failed to converge within `maxiter' iterations; try increasing {bf:maxiter()}"'
				else if r(rc_eff_uci)>1 | missing(`r(eff_uci)') {
					disp `"{error}Note: Upper confidence limit of effect size could not be found; possible discontinuity in search interval"'
					if `rc_eff_uci'<=1 local rc_eff_uci = 498
				}				
				return scalar rc_eff_lci = `rc_eff_lci'		// whether ES lower confidence limit converged
				return scalar rc_eff_uci = `rc_eff_uci'		// whether ES upper confidence limit converged					
			}
		}

		return add					// add anything else returned by PerformPooling to return list of PerformMetaAnalysis
									// e.g. r(OR), r(RR); tsq-related stuff; chi2; data-derived heterogeneity (e.g. Cochran's Q); matrix hetstats
	
		// Normalise weights overall (if `ovwt')
		if `"`ovwt'"'!=`""' {
			local _WT2 = cond(`"`xwt'"'!=`""', `"`xwt'"', `"`_WT'"')			// use _WT2 from `xoutvlist' if applicable
			summ `_WT' if `touse', meanonly
			qui replace `_WT2' = 100*cond(`"`altwt'"'!=`""', `_WT', `_WT2') / r(sum) ///
				if `touse' & `_USE'==1		// use *original* weights (_WT) rather than cumul/infl weights (_WT2) if `altwt'
		}

		// Find and store number of participants
		if `"`_NN'"'!=`""' {
			summ `_NN' if `touse' & `_USE'==1, meanonly
			matrix `ovstats'[rownumb(`ovstats', "npts"), 1] = r(sum)
			scalar `n' = r(sum)
		}
		
		return matrix ovstats = `ovstats'		// needs to be returned separately from "return all" above, as it has been edited

	}		// end if `"`overall'"'==`""' | `"`ovwt'"'!=`""'

	
	
	******************************************
	* Analysis within study subgroups (`by') *
	******************************************
	
	if `"`by'"'!=`""' & (`"`subgroup'"'==`""' | `"`sgwt'"'!=`""') {
		
		// Amended May 2020
		tempname Qsum csum avg_eff_num avg_eff_denom
		scalar `Qsum' = 0			// sum of subgroup-specific Q statistics
		scalar `csum' = 0			// sum of tausq scaling factors, for deriving tsq_common
		scalar `avg_eff_num' = 0	// weighted average of subgroup effects (numerator), for deriving Qbet
		scalar `avg_eff_denom' = 0	// weighted average of subgroup effects (denominator), for deriving Qbet

		** Initialize markers of subgroup-related errors
		// (plus Mata iterative functions failed to converge etc ... this is done on-the-fly for `overall')
		foreach el in rc_2000 rc_2002 rc_tausq rc_tsq_lci rc_tsq_uci rc_eff_lci rc_eff_uci {
			local n`el' = 0
		}
		local nsg = 0		// reset
		local nsg_list		// init list of subgroups with only one study ==> random-effects models become iv/mh

		** Initialize counts of studies and of pts., in case not already counted by `overall'
		tempname kOV nOV
		scalar `kOV' = 0
		scalar `nOV' = .
		
		** Initialise matrix to hold subgroup stats (matrix bystats)		
		// Remove unnecessary rownames from bystats (e.g. oe, v; df_kr; tausq, sigmasq, rfdist)
		// (N.B. bystats matrices are separated by model, and each model might need different set of rownames
		//    whereas ovstats includes *all* models simultaneously)
		local toremove
		if !("`logrank'"!="" | "`model'"=="peto") local toremove OE V
		// if "`kroger'"=="" local toremove `toremove' df_kr
		if "`teststat'"!="t" local toremove `toremove' df
		if inlist("`model'", "mh", "peto", "iv", "ivhet", "qe", "mu") ///
			| inlist("`model'", "bt", "hc", "pl") | "`kroger'"!="" {
			local toremove `toremove' rflci rfuci
		}
		
		// [Sep 2020:]
		// Note: Heterogeneity stats derived from the *data*, independently of model (i.e. Q Qdf H Isq)
		//  are returned in r() rather than stored in a matrix

		// "parametrically-defined Isq" -based heterogeneity values, if requested [i.e. derived from Isq = tsq/(tsq+sigmasq) ]
		// are stored in matrix r(hetstats) [and byhet1...byhet`nby' for subgroups]
		// (plus tsq + CI itself)

		// model-based tausq confidence intervals
		if !inlist("`model'", "mp", "ml", "pl", "reml", "bt", "dlb") local toremove `toremove' tsq_lci tsq_uci

		// common-effect models: no tausq
		if inlist("`model'", "peto", "mh", "iv", "mu") local toremove `toremove' tausq /*sigmasq*/
		foreach el in t chi2 u {
			if "`teststat'"!="`el'" local toremove `toremove' `el'
		}
		cap confirm numeric var `_NN'
		if _rc local toremove `toremove' npts
		local rownames_reduced_by : list rownames - toremove
		
		tempname bystats byhet byQ mwt
		
		local nby : word count `bylist'
		matrix define   `bystats' = J(`: word count `rownames_reduced_by'', `nby', .)
		matrix rownames `bystats' = `rownames_reduced_by'
		local modelstr = strtoname("`model'", 0)
		matrix colnames `bystats' = `modelstr'
		matrix coleq    `bystats' = `bylist'
	
		local rownames_byQ Q Qdf Q_lci Q_uci
		if `: list posof "tausq" in rownames_reduced_by' local rownames_byQ `rownames_byQ' sigmasq
		local r : word count `rownames_byQ'
		matrix define   `byQ' = J(`r', `nby', .)
		matrix rownames `byQ' = `rownames_byQ'
		matrix colnames `byQ' = `modelstr'
		matrix coleq    `byQ' = `bylist'

		// if sgwt, pass `_WT' to PerformPooling to be filled in
		// otherwise, PerformPooling will generate a tempvar, and `_WT' will remain empty
		local wtvar = cond(`"`sgwt'"'!=`""', `"`_WT'"', `""')
		
		forvalues i = 1 / `nby' {
			local byi : word `i' of `bylist'
			qui count if `touse' & `_USE'==1 & float(`by')==float(`byi')
			local rN = r(N)
			
			// May 2020: Usually, `rN' should equal r(k)
			// BUT if 2x2 count data (or proportion data) and nocc then mh and peto will use all studies = `rN'
			//  but iv-based methods can only use studies with non-missing _ES and _seES = r(k)
			// Hence, for later logic-checking, setup r(k)==`rN' or <=`rN' as appropriate.
			// (Note: back in the main routine, a final check will be made that all observations are handled correctly via _USE)
			local equals `"=="'
			cap confirm numeric variable `ccvar'
			if !_rc & (`params'==4 | `"`proportion'"'!=`""') {
				summ `ccvar' if `touse' & `_USE'==1 & float(`by')==float(`byi'), meanonly
				if r(N) local equals `"<="'
			}

		
			** Cumulative/influence analysis
			// Run extra loop to store results of each iteration within the currrent dataset (`xoutvlist')
			local rc = 0
			if `"`cumulative'`influence'"' != `""' {
			
				// Moved/amended March 2020:  mainly for cumulative/influence but useful in small ways regardless
				qui bysort `touse' `_USE' `by' (`sortby') : replace `obsj' = _n if `touse' & `_USE'==1

				cap nois CumInfLoop `_USE' `_ES' `_seES' if `touse' & `_USE'==1 & float(`by')==float(`byi'), sortby(`obsj') ///
					model(`model') summstat(`summstat') teststat(`teststat') `qstat' `testbased' `isqparam' ///
					mhvlist(`mhvlist') oevlist(`oevlist') invlist(`invlist') xoutvlist(`xoutvlist') ///
					wgt(`wgt') wtvar(`wtvar') rownames(`rownames') `nptsopt' ///
					`cumulative' `influence' `integer' `logrank' `proportion' `sgwt' ///
					`olevel' `rfdist' `rflevel' `hlevel' `opts_model'

				local rc = _rc
				if _rc {
					if _rc==1 {
						nois disp as err "User break in {bf:metan.CumInfLoop}"
						c_local err noerr		// tell -metan- not to also report an "error in metan.PerformMetaAnalysis"
						exit _rc
					}
					else if !inlist(_rc, 2000, 2002) {
						if `"`err'"'==`""' nois disp as err `"Error in {bf:metan.CumInfLoop}"'
						c_local err noerr		// tell -metan- not to also report an "error in metan.PerformMetaAnalysis"
						exit _rc
					}
					else if _rc==2000 local nrc_2000 = 1
					else if _rc==2002 local nrc_2002 = 1
				}
				else {
					foreach el in rc_tausq rc_tsq_lci rc_tsq_uci rc_eff_lci rc_eff_uci {
						if !inlist(r(`el'), 0, 2, .)   local n`el' = 1
					}
				}
				
				local xwt `r(xwt)'			// extract _WT2 from `xoutvlist'
			}

			
			** Main subgroup meta-analysis
			if `rc' != 2000 {
			    
				cap nois PerformPooling `_ES' `_seES' if `touse' & `_USE'==1 & float(`by')==float(`byi'), ///
					model(`model') summstat(`summstat') teststat(`teststat') `qstat' `testbased' `isqparam' ///
					mhvlist(`mhvlist') oevlist(`oevlist') invlist(`invlist') `nptsopt' wtvar(`wtvar') wgt(`wgt') ///
					`integer' `logrank' `proportion' `rfdist' `rflevel' `olevel' `hlevel' `opts_model'

				local rc = _rc
				if _rc {
					if _rc==1 {
						nois disp as err "User break in {bf:metan.PerformPooling}"
						c_local err noerr		// tell -metan- not to also report an "error in metan.PerformMetaAnalysis"
						exit _rc
					}
					else if !inlist(_rc, 2000, 2002) {
						if `"`err'"'==`""' nois disp as err `"Error in {bf:metan.PerformPooling}"'
						c_local err noerr		// tell -metan- not to also report an "error in metan.PerformMetaAnalysis"
						exit _rc
					}
					else if _rc==2000 local nrc_2000 = 1
					else if _rc==2002 local nrc_2002 = 1
				}
				else {
					foreach el in rc_tausq rc_tsq_lci rc_tsq_uci rc_eff_lci rc_eff_uci {
						if !inlist(r(`el'), 0, 2, .)   local n`el' = 1
					}
				}
				

				** If `cumulative', copy pooled results into final cumulative observation
				if `"`cumulative'"'!=`""' {
					local npts_el npts
					local xrownames : list rownames - npts_el
					local xrownames `xrownames' Q Qdf Q_lci Q_uci
					if `: list posof "tausq" in rownames' local xrownames `xrownames' sigmasq
					
					tokenize `xoutvlist'
					args `xrownames' _WT2
					
					// Store (non-normalised) weight in the dataset
					qui replace `_WT2' = r(totwt) if float(`by')==float(`byi') & `obsj' == `rN'
				
					// Store other returned statistics in the dataset
					foreach el of local xrownames {
						qui replace ``el'' = r(`el') if float(`by')==float(`byi') & `obsj' == `rN'
					}
					
					// reset tokenize
					tokenize `outvlist'
					args _ES _seES _LCI _UCI _WT _NN
				}
			}		// end if `rc' != 2000

			// [SEP 2020:] "parametrically-defined Isq" -based heterogeneity -- do this regardless of _rc
			if "`isqparam'"!="" {
			    if "`r(hetstats)'"!="" {
					matrix define `byhet' = nullmat(`byhet'), r(hetstats)
				}
				else {	// if e.g. pooling failed, or HKSJ but only one study
						// fill in tausq, Isq and HsqM with zeroes, and H with ones
				    matrix define `byhet' = nullmat(`byhet'), ( J(3, 1, 0) \ J(3, 1, 1) \ J(6, 1, 0) )
				}
			}
			
			
			** If PerformPooling ran successfully, update `bystats' matrix and return subgroup stats
			if !`rc' | (`rc'==2002 & "`model'"=="mh") {

				// update `bystats' matrix
				foreach el of local rownames_reduced_by {
					local rownumb = rownumb(`bystats', "`el'")
					if !missing(`rownumb') {
						matrix `bystats'[rownumb(`bystats', "`el'"), `i'] = r(`el')
					}
				}
				
				// update `byQ' matrix
				foreach el of local rownames_byQ {
					local rownumb = rownumb(`byQ', "`el'")
					if !missing(`rownumb') {
						matrix `byQ'[rownumb(`byQ', "`el'"), `i'] = r(`el')
					}
				}
				
				// update running sums
				scalar `Qsum' = `Qsum' + r(Q)
				scalar `csum' = `csum' + r(c)
				// scalar `Qbet' = `Qbet' + ((r(eff) - `eff_ov') / r(se_eff))^2	// added Jan 2020
				// Amended May 2020, as follows:
				scalar `avg_eff_num'   = `avg_eff_num'   + ( r(eff) / (r(se_eff)^2) )
				scalar `avg_eff_denom' = `avg_eff_denom' + (      1 / (r(se_eff)^2) )
				
				assert r(k) `equals' `rN'
				scalar `kOV'  = `kOV' + cond(missing(r(k)), 0, r(k))
				if `"`_NN'"'!=`""' {
					summ `_NN' if `touse' & `_USE'==1 & float(`by')==float(`byi'), meanonly
					matrix `bystats'[rownumb(`bystats', "npts"), `i'] = r(sum)
					scalar `nOV' = cond(missing(`nOV'), 0, `nOV') + r(sum)
				}
				
				// Normalise weights by subgroup (if `sgwt')
				if `"`sgwt'"'!=`""' {
					local _WT2 = cond(`"`xwt'"'!=`""', `"`xwt'"', `"`_WT'"')		// use _WT2 from `xoutvlist' if applicable
					summ `_WT' if `touse' & `_USE'==1 & float(`by')==float(`byi'), meanonly
					qui replace `_WT2' = 100*cond(`"`altwt'"'!=`""', `_WT', `_WT2') / r(sum) ///
						if `touse' & `_USE'==1 & float(`by')==float(`byi')		// use *original* weights (_WT) rather than cumul/infl weights (_WT2) if `altwt'
				}
				
				// Save subgroup weights from multiple models, in matrix `mwt'
				// N.B. Need to do this here, not within PerformPooling, since otherwise it won't have been normalised
				else {
					summ `_WT' if `touse' & `_USE'==1 & float(`by')==float(`byi'), meanonly
					matrix define `mwt' = nullmat(`mwt') , r(sum)
				}
			}		// end if [PerformPooling ran successfully]
			else if `"`sgwt'"'==`""' {
				matrix define `mwt' = nullmat(`mwt') , .		// add a col to `mwt' for each element of `bylist' even if pooling failed
			}
			
			// [Nov 2020] `nsg' will have been updated by PerformPooling
			if `nsg' local nsg_list `nsg_list' `byi'
			
		}	// end forvalues i = 1 / `nby'

		if (`"`overall'"'==`""' | `"`ovwt'"'!=`""') {
			assert `kOV' == `k'		// check that sum of subgroup `k's = previously-calculated overall `k'
			assert `nOV' == `n'		// check that sum of subgroup `n's = previously-calculated overall `n'
		}
		else {
			scalar `k' = `kOV'		// if no previously-calculated overall `k', *define* it to be sum of subgroup `k's
			scalar `n' = `nOV'		// if no previously-calculated overall `n', *define* it to be sum of subgroup `n's
		}
		
		// Finalise and return `bystats' and byQ' matrices
		// First: check for any unnecessary rownames (again!)
		//  e.g. if t-based model and all went well, no need for z
		local toremove
		local nsg_sum : word count `nsg_list'
		if !`nsg_sum' {
			foreach el in z t chi2 u {
				if "`teststat'"!="`el'" local toremove `toremove' `el'
			}
			if "`teststat'"!="t" local toremove `toremove' df
		}
		else {
			return local nsg_list `nsg_list'
			
			// Niche case: *all* subgroups turn out to have only one study
			//  ==> revert to IV throughout ==> remove random-effects elements
			if `nsg_sum'==`nby' {
				local toremove df rflci rfuci sigmasq
				local toremove `toremove' tausq tsq_lci tsq_uci
				local toremove `toremove' H H_lci H_uci 
				local toremove `toremove' Isq Isq_lci Isq_uci 
				local toremove `toremove' HsqM HsqM_lci HsqM_uci
				foreach el in z t chi2 u {
					if "`teststat'"!="`el'" local toremove `toremove' `el'
				}
			}
		}
		if `"`toremove'"'!=`""' {
			local old_rownames `rownames_reduced_by'
			local rownames_reduced_by : list rownames_reduced_by - toremove
			
			tempname bystats2
			matrix define   `bystats2' = J(`: word count `rownames_reduced_by'', `nby', .)
			matrix rownames `bystats2' = `rownames_reduced_by'
			matrix coleq    `bystats2' = `bylist'
	
			foreach el of local old_rownames {
				forvalues i = 1 / `nby' {	
					if `: list el in rownames_reduced_by' {
						matrix `bystats2'[rownumb(`bystats2', "`el'"), `i'] = `bystats'[rownumb(`bystats', "`el'"), `i']
					}
					else assert missing(`bystats'[rownumb(`bystats', "`el'"), `i'])
				}
			}	
			matrix define `bystats' = `bystats2'
		}		

		// May 2020:
		// Calculate "common tausq" (across subgroups); and between-subgroup Q statistic
		// c.f. Borenstein et al (2009) "Introduction to Meta-analysis", chapter 19
		tempname tsq_common avg_eff Qbet eff_i se_eff_i
		scalar `tsq_common' = max(0, (`Qsum' - (`k' - `nby')) / `csum')
		scalar `avg_eff' = `avg_eff_num' / `avg_eff_denom'
		scalar `Qbet' = 0
		forvalues i = 1 / `nby' {
			scalar `eff_i'    = `bystats'[rownumb(`bystats', "eff"),    `i']
			scalar `se_eff_i' = `bystats'[rownumb(`bystats', "se_eff"), `i']
			scalar `Qbet' = `Qbet' + ((`eff_i' - `avg_eff') / `se_eff_i')^2
		}
		return scalar tsq_common = `tsq_common'
		return scalar Qsum = `Qsum'
		return scalar Qbet = `Qbet'
		return matrix bystats = `bystats'
		return matrix byQ     = `byQ'
		
		// Return `mwt' matrix, containing (normalised) model-specific subgroup weights
		cap confirm matrix `mwt'
		if !_rc {
			matrix colnames `mwt' = `bylist'
			matrix rownames `mwt' = `modelstr'
			return matrix mwt = `mwt'
		}
		
		// [SEP 2020]: Return `byhet' matrix, containing "parametrically-defined Isq" -based heterogeneity values
		cap confirm matrix `byhet'
		if !_rc {
			// reduce rows if necessary
			// if current model does not estimate tausq CIs, just keep rows containing point estimates
			if inlist("`model'", "iv", "mh", "peto") {
				matrix define `byhet' = `byhet'[rownumb(`byhet', "H"), 1...] ///
					\ `byhet'[rownumb(`byhet', "Isq"), 1...] \ `byhet'[rownumb(`byhet', "HsqM"), 1...]
			}
			else if !inlist("`model'", "mp", "ml", "pl", "reml", "bt", "dlb") {
				matrix define `byhet' = `byhet'[rownumb(`byhet', "tausq"), 1...] \ `byhet'[rownumb(`byhet', "H"), 1...] ///
					\ `byhet'[rownumb(`byhet', "Isq"), 1...] \ `byhet'[rownumb(`byhet', "HsqM"), 1...]
			}
			matrix colnames `byhet' = `modelstr'
			matrix coleq    `byhet' = `bylist'
			return matrix byhet = `byhet'
		}
		
		// Error messages: return as c_local, in order that each unique error message is only displayed once
		foreach el in rc_2000 rc_2002 rc_tausq rc_tsq_lci rc_tsq_uci rc_eff_lci rc_eff_uci {
			c_local n`el' = `n`el''
		}
		
	}	// end if `"`by'"'!=`""' & (`"`subgroup'"'==`""' | `"`sgwt'"'!=`""')

	c_local nrfd = `nrfd'			// update marker of "one or more subgroups has < 3 studies" (for rfdist)
	c_local nsg  = `nsg'			// update marker of "one or more subgroups contain only a single valid estimate"
	c_local nzt  = `nzt'			// update marker of "HKSJ has resulted in a shorter CI than IV in one or more subgroups"
	
	
	** Check numbers of participants
	// This part is now just a check that patients and trials are behaving themselves for each model
	if `"`_NN'"'!=`""' {
		summ `_NN' if `touse' & `_USE'==1, meanonly

		// Check if we have same number of values for _NN as there are trials
		// if not, some _NN values must be missing; display warning
		cap assert `r(N)'==`k'
		if _rc {
			if `"`by'"'!=`""' & `"`subgroup'"'==`""' {
				cap assert !`nmiss'
				if !_rc local nmiss = 1
			}
			if `"`xoutvlist'"'!=`""' {
				disp `"{error}      `=upper(`cumulative'`influence')' patient numbers cannot be returned"'
				c_local _NN		// clear macro _NN, so that by-trial patient numbers are no longer available
			}
		}
		else scalar `n' = r(sum)
		return scalar n = cond(`n'==0, ., `n')
	}
	c_local nmiss = `nmiss'
	
	return scalar k = `k'
	
end





**********************************************************************

* PrintDesc
// Print descriptive text to screen, above table

program define PrintDesc, sclass
	
	syntax [if] [in], MODELLIST(namelist) [SUMMSTAT(name) SORTBY(varlist) BYLIST(numlist miss) ///
		WGTOPTLIST(string) LOG LOGRank CUmulative INFluence PRoportion SUMMARYONLY ISQParam ///
		noOVerall noSUbgroup noPOOL noTABle noGRaph ///
		CC(string) CCVAR(name) ISQSA(real 80) TSQSA(real -99) INIT(name) ///
		ESTEXP(string) EXPLIST(passthru) IPDMETAN INTERaction ALTWt ///
		BArtlett HKsj KRoger RObust SKovgaard TRUNCate(string) MHALLZERO /* Internal option */ * ]

	marksample touse
	local m : word count `modellist'
	local nby = max(1, `: word count `bylist'')
	gettoken model1 rest : modellist
	gettoken model2 rest : rest

	// Build up description of effect estimate type (interaction, cumulative etc.)
	local pooltext = cond(`"`cumulative'"'!=`""', "Cumulative meta-analysis of", ///
		cond(`"`influence'"'!=`""', "Influence meta-analysis of", ///
		cond(`"`pool'"'==`""' | "`model1'"=="user", "Meta-analysis pooling of", "Presented effect estimates are")))
	
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
		if `"`pool'"'==`""' | `"`model1'"'=="user" | `"`ipdmetan'"'!=`""' di _n as text "`pooltext' aggregate data"
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
			local efftext " Standardised Mean Differences"
			local ss_proper = strproper(reverse(substr(reverse("`summstat'"), 2, .)))
			local efftextf `" as text " by the method of " as res "`ss_proper'""'
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
		di _n as text "`pooltext'" as res " `efftext'" `efftextf' `continue'
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
			if `nby' > 1 & `"`subgroup'"'==`""' {
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
					local modeltext "random-effects inverse-variance"
					if "`model1'"!="sa" local fpnote "NOTE: Weights `insert'are from random-effects model"		// for forestplot
				}
				local the = cond("`model1'"=="qe", "", "the ")
				disp as text `"using `the'"' as res `"`modeltext'"' as text " model"
			}
			
			// Doi's IVhet and Quality Effects models
			else if "`model1'"!="peto" {
				local modeltext = cond("`model1'"=="ivhet", "Doi's IVhet", "Doi's Quality Effects")
				disp as text "using " as res `"`modeltext'"' as text " model"
				local fpnote `"NOTE: Weights `insert'are from `modeltext' model"'				// for forestplot
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
				disp as text "with " as res `"multiplicative heterogeneity"'
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
				if inlist("`model1'", "dl", "bt", "ivhet", "qe", "hc") local tsqtext "DerSimonian-Laird"
				else if "`model1'"=="dlb" local tsqtext "Bootstrap DerSimonian-Laird"
				else if "`model1'"=="mp"  local tsqtext "Mandel-Paule"
				else if "`model1'"=="he"  local tsqtext "Hedges's"
				else if "`model1'"=="ev"  local tsqtext "Empirical variance"
				else if "`model1'"=="hm"  local tsqtext "Hartung-Makambi"
				else if inlist("`model1'", "ml",   "pl") local tsqtext ML
				else if "`model1'"=="reml" | "`kroger'"!="" local tsqtext REML
				else if "`model1'"=="bp"  local tsqtext "Rukhin's BP"
				else if "`model1'"=="b0"  local tsqtext "Rukhin's B0"
			
				local linktext = cond(`"`hksj'`kroger'`robust'"'!=`""' | inlist("`model1'", "pl", "bt", "ivhet", "qe", "hc"), "based on", "with")
				
				// Sensitivity analysis
				if "`model1'"=="sa" {
					disp as text "Sensitivity analysis with user-defined " _c
					if `tsqsa'==-99 {
						disp "I{c 178} = " as res "`isqsa'%"
						local fpnote `"Sensitivity analysis with user-defined I{c 178}"'
					}
					else {
						disp `"tau{c 178} = "' as res `"`=strofreal(`tsqsa', "%05.3f")'"'
						local fpnote `"Sensitivity analysis with user-defined tau{c 178}"'
					}
				}
				
				// Two-step estimators
				else if inlist("`model1'", "sj2s", "dk2s") {
					if "`init'"=="he" local inittxt "Hedges's"
					else local inittxt = upper("`init'")
					disp as text `"with "' as res "`inittxt'" as text `" initial estimate of tau{c 178}"'
				}
				
				// Default
				else disp as text `"`linktext' "' as res `"`tsqtext'"' as text `" estimate of tau{c 178}"'
			}
		}
	}		// end if `"`ovstats'`bystats'"'!=`""' 
	
	// User-defined weights
	local udw = 0
	local j = 1
	tokenize `wgtoptlist'
	while `"`1'"'!=`""' {
		if `"`1'"'!="default" {
			local udw = 1
			local 0 `", `1'"'
			syntax [, WGT(varname numeric) ]
	
			if `m'==1 {
				local wgttitle : variable label `wgt'
				if `"`wgttitle'"'==`""' local wgttitle `wgt'
				if `"`pool'"'==`""' {
					disp as text "and with user-defined weights " as res `"`wgttitle'"'
				}
				else disp as text "Weights " as res `"`wgttitle'"' as text " are user-defined"
				
				if `"`fpnote'"'!=`""' local fpnote `"`fpnote' and with user-defined weights"'
				else local fpnote `"NOTE: Weights `insert'are based on user-defined quantities"'
			}
		}
		macro shift
	}
	if `udw' & `m' > 1 {
		if `"`pool'"'==`""' {
			disp as text "and with user-defined weights for one or more models; see below"
		}
		else disp as text "Weights are user-defined for one or more models; see below"

		if `"`fpnote'"'!=`""' local fpnote `"`fpnote' and with user-defined weights for some models"'
		else local fpnote `"NOTE: Weights for some models are user-defined"'
	}
	
	// Continuity correction
	cap confirm numeric var `ccvar'
	if !_rc & `"`cc'"'!=`""' {
		summ `ccvar' if `touse', meanonly
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
				local allifzerotext = cond("`allifzero'"=="", "", "studies with zero cells ")

				if `"`allifzero'"'!=`""' disp as text " applied to all studies"
				else disp as text " applied to studies with zero cells"
				
				if `"`summaryonly'`table'"'==`""' & "`model1'"=="mh" {
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
		if `"`sortby'"'==`""' local sortby : sort
		if `"`sortby'"'!=`""' {
			disp as text _n "Studies added cumulatively in order of " as res `"`sortby'"'
		}
	}
	
	// SEP 2020:
	// "Parametrically-defined Isq" -based heterogeneity [i.e. based on tausq & sigmasq]
	if "`isqparam'"!="" & "`model1'"!="dl" {
		local fptext `"Heterogeneity measures based on {&tau}{sup:2} and {&sigma}{sup:2} rather than on Q"'
	    if `"`fpnote'"'!=`""' {
			local fpnote `"`"`fpnote'."' `"`fptext'"'"'		// add full stop and new line before continuing
		}
		else local fpnote `"NOTE: `fptext'"'				// else just use text as-is
	}
	
	sreturn clear
	sreturn local fpnote `"`fpnote'"'

end





*******************************************************

* Routine to draw output table (metan.ado version)
// Could be done using "tabdisp", but doing it myself means it can be tailored to the situation
// therefore looks better (I hope!)

program define DrawTableAD, rclass sortpreserve

	// N.B. This program is rclass to enable return of matrix r(coeffs); nothing else is returned

	// N.B. no max in varlist() since xoutvlist may contain extra vars e.g. tausq/sigmasq, which are not relevant here
	syntax varlist(numeric min=6) [if] [in], SORTBY(varlist) ///
		MODELLIST(namelist) TESTSTATLIST(namelist) QSTAT(name) WGTOPTLIST(string) ///
		[ CUmulative INFluence noOVerall noSUbgroup noSECsub SUMMARYONLY OVWt SGWt ///
		LABELS(varname string) STITLE(string asis) ETITLE(string asis) CC(string) CCVAR(name) SUMMSTAT(name) TESTBased ISQParam ///
		STUDY(varname numeric) BY(varname numeric) BYLIST(numlist miss) BYSTATSLIST(namelist) ///
		QLIST(numlist miss min=2 max=6) BYQ(name) HETSTATS(name) MWT(name) OVSTATS(name) PRoportion PRVLIST(varlist numeric) DENOMinator(real 1) ///
		EFORM noTABle noHET noWT noKEEPvars KEEPOrder ILevel(cilevel) OLevel(cilevel) HLevel(cilevel) NZT(real 0) ISQSA(real 80) TSQSA(real -99) ///
		 * ]

	// [Nov 2020:]
	// extra options are `model1opts' (i.e. for display based on main/primary model), `opts_adm' (general options), plus:
	// - label#opt(string asis) -- model label (e.g. IV, or Fixed);  c.f. "desc" in "first(es lci uci desc)" or "second(...)"
	// - extra#opt(string asis) -- "extra" label (e.g. heterogeneity, for forest plot);  c.f. firststats(), secondstats()
	// - user#stats(numlist min=3 max=3) -- c.f. "es lci uci" in "first(es lci uci desc)" or "second(...)"
	
	local opts_drawtab : copy local options
	marksample touse, novarlist		// -novarlist- option prevents -marksample- from setting `touse' to zero if any missing values in `varlist'
	
	// rename `labels' to `_LABELS' to avoid confusion with label#opt() labelling options
	local _LABELS : copy local labels
	
	// unpack varlists
	tokenize `varlist'
	args _USE _ES _seES _LCI _UCI _WT _NN
	
	// Maintain original order if requested
	if `"`keeporder'"'!=`""' {
		tempvar tempuse
		qui gen byte `tempuse' = `_USE'
		qui replace `tempuse' = 1 if `_USE'==2		// keep "insufficient data" studies in original study order (default is to move to end)
	}
	else local tempuse `_USE'
	
	gettoken model1 : modellist
	
	** Now, if `nokeepvars' specified...  including if called by -ipdmetan-, but *not* if first() ...
	//  re-create `obs', sorting by `sortby', and create matrix of coefficients
	// (N.B. not done earlier as want to take account of `keepall' & `keeporder')
	tempvar obs
	if `"`keepvars'"'!=`""' {
		qui count if `touse'
		if r(N) > c(matsize) {
			disp `"{error}matsize too small to store matrix of study coefficients; this step will be skipped"'
			disp `"{error}  (see {bf:help matsize})"'
			sort `touse' `by' `tempuse' `sortby'			
		}
		
		else {
			// create `study' if missing
			if `"`study'"'==`""' {
				tempvar study
				qui gen long `obs' = _n
				qui bysort `touse' (`obs'): gen long `study' = _n if `touse'
				drop `obs'
			}
			sort `touse' `by' `tempuse' `sortby'
			
			tempname coeffs
			mkmat `by' `study' `_ES' `_seES' `_NN' `_WT' if `touse', matrix(`coeffs')

			local _BYexist = cond( `"`by'"'!=`""', "_BY", "")
			local _NNexist = cond(`"`_NN'"'!=`""', "_NN", "")
			local _WTexist = cond(`"`_WT'"'!=`""', "_WT", "")
			matrix colnames `coeffs' = `_BYexist' _STUDY _ES _seES `_NNexist' `_WTexist'
			return matrix coeffs = `coeffs'
		}
	}
	else {
	    sort `touse' `by' `tempuse' `sortby'			// to avoid sorting twice
	}
	qui gen long `obs' = _n

	// Having assembled `coeffs', we want to display proportions on their original scale
	// (unless -nopr- , but then also no `prvlist' )
	// so point DrawTableAD to _Prop_ES etc.
	if `"`prvlist'"'!=`""' {
		tokenize `prvlist'
		args _ES _LCI _UCI
	}

	
	** Create table of results
	
	// Multiple models: extract labels etc. before we start
	local m : word count `modellist'
	forvalues j = 1 / `m' {
		local 0 `", `opts_drawtab'"'
		syntax [, LABEL`j'opt(string) USER`j'stats(numlist min=3 max=3) * ]
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

	// [Nov 2020] Count number of "user-supplied" models
	forvalues j = 1 / `m' {
		local model : word `j' of `modellist'
		if "`model'"!="user" {
			local indexlist `indexlist' `j'
			local modellist2 `modellist2' `model'
			local teststatlist2 `teststatlist2' `: word `j' of `teststatlist''
			local wgtoptlist2 `wgtoptlist2' `: word `j' of `wgtoptlist''
		}
	}
	local m2 : word count `modellist2'	
	
	if `"`table'"'==`""' {

		* Expand `cc'
		if `"`cc'"'!=`""' {
			local 0 `cc'
			syntax anything(name=ccval id="value supplied to {bf:cc()}") [, *]
			confirm number `ccval'
		}
		else local ccval = 0

		* Find maximum length of labels in LHS column
		qui gen long `vlablen' = length(`_LABELS')		
		if "`cc'"!="" & "`ccvar'"!="" {							// cc used with "primary" model
			qui replace `vlablen' = `vlablen' + 2 if `ccvar'	// for a space and asterisk if cc
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
		SpreadTitle `"`stitle'"', target(`uselen') maxwidth(31)		// study (+ subgroup) title
		local swidth = 1 + max(`uselen', `r(maxwidth)')
		local slines = r(nlines)
		forvalues i = 1 / `slines' {
			local stitle`i' `"`r(title`i')'"'
		}
		SpreadTitle `"`etitle'"', target(10) maxwidth(15)		// effect title (i.e. "Odds ratio" etc.)
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
		
		// June 2020
		if "`wt'"=="" & `m' > 1 & `elines'==1 & `slines'==1 {
			local etitle2 : copy local etitle1
			local etitle1
			local stitle2 : copy local stitle1
			local stitle1
		}
		
		
		* Now display the title lines, starting with the "extra" lines and ending with the row including CI & weight
		local nl = max(`elines', `slines')
		local wwidth = 1	// nowt
		if "`wt'"=="" {
			local wwidth = 11
			local wtitle`nl' `"{col `=`swidth'+`ewidth'+27'}% Weight"'
			if `m' > 1 {
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
					if missing(`_ES'[`k']) {
						
						// June 2020
						if `_USE'[`k']==1 & `: list posof "mh" in modellist' {
							disp as text substr(`_LABELS'[`k'], 1, 32) `"{col `=`swidth'+1'}{c |}{col `=`swidth'+4'} (Insufficient data for IV)"'
						}
						else {
							disp as text substr(`_LABELS'[`k'], 1, 32) `"{col `=`swidth'+1'}{c |}{col `=`swidth'+4'} (Insufficient data)"'
						}
					}
					else if missing(`_seES'[`k']) {						// June 2020
						scalar `_ES_'  = `denominator' * `_ES'[`k']
						disp as text substr(`_LABELS'[`k'], 1, 32) ///
							as text `"{col `=`swidth'+1'}{c |}{col `=`swidth'+`ewidth'-6'}"' ///
							as res %7.3f `xexp'(`_ES_') as text `"{col `=`swidth'+`ewidth'+10'} (Insufficient data)"'
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
						cap confirm numeric var `ccvar'
						if !_rc & `ccval' {
							if `ccvar'[`k'] local _cc_ `" *"'
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
					
					if `"`label`j'opt'"'!=`""' local modText `", `label`j'opt'"'	// Nov 2020
					local wgtstar
					local wgtopt : word `j' of `wgtoptlist'
					if `"`wgtopt'"'!="default" local wgtstar " **"
				
					local bystats : word `j' of `bystatslist'
					if `"`prvlist'"'!=`""' {
						scalar `_ES_' = `denominator' * `bystats'[rownumb(`bystats', "prop_eff"), `i']
					}
					else scalar `_ES_' = `bystats'[rownumb(`bystats', "eff"), `i']
					if missing(`_ES_') {
						disp as text `"Subgroup`modText'`wgtstar'{col `=`swidth'+1'}{c |}{col `=`swidth'+4'} (Insufficient data)"'
					}
					else {
						if `"`prvlist'"'!=`""' {
							scalar `_LCI_' = `denominator' * `bystats'[rownumb(`bystats', "prop_lci"), `i']
							scalar `_UCI_' = `denominator' * `bystats'[rownumb(`bystats', "prop_uci"), `i']
						}
						else {
							scalar `_LCI_' = `bystats'[rownumb(`bystats', "eff_lci"), `i']
							scalar `_UCI_' = `bystats'[rownumb(`bystats', "eff_uci"), `i']
						}

						disp as text `"Subgroup`modText'`wgtstar'{col `=`swidth'+1'}{c |}{col `=`swidth'+`ewidth'-6'}"' ///
							as res %7.3f `xexp'(`_ES_') `"{col `=`swidth'+`ewidth'+5'}"' ///
							as res %7.3f `xexp'(`_LCI_') `"{col `=`swidth'+`ewidth'+15'}"' ///
							as res %7.3f `xexp'(`_UCI_') `"{col `=`swidth'+`ewidth'+26'}"' _c
							
						// subgroup sum of (normalised) weights: will be 1 unless `ovwt'
						if `j' > 1 | "`wt'"!="" di ""		// cancel the _c
						else {
							scalar `_WT_' = cond(`"`ovwt'"'==`""', 100, `mwt'[`j', `i'])
							disp as res %7.2f `_WT_'
						}
					}
				}		// end forvalues j = 1 / `m'
			}		// end if `by'
		}		// end forvalues i = 1 / `nby'
		
		if "`by'"!="" {
			drop `touse2'	// tidy up
		}

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
				if `"`label`j'opt'"'!=`""' local modText `", `label`j'opt'"'

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
					local wgtopt : word `j' of `wgtoptlist'
					if `"`wgtopt'"'!="default" local wgtstar " **"

					if `"`prvlist'"'!=`""' {
						scalar `_ES_' = `denominator' * `ovstats'[rownumb(`ovstats', "prop_eff"), `index']
					}
					else scalar `_ES_' = `ovstats'[rownumb(`ovstats', "eff"), `index']
					if missing(`_ES_') {
						disp as text `"Overall`modText'`wgtstar'{col `=`swidth'+1'}{c |}{col `=`swidth'+4'} (Insufficient data)"'
					}
					else {
						if `"`prvlist'"'!=`""' {
							scalar `_LCI_' = `denominator' * `ovstats'[rownumb(`ovstats', "prop_lci"), `index']
							scalar `_UCI_' = `denominator' * `ovstats'[rownumb(`ovstats', "prop_uci"), `index']
						}
						else {
							scalar `_LCI_' = `ovstats'[rownumb(`ovstats', "eff_lci"), `index']
							scalar `_UCI_' = `ovstats'[rownumb(`ovstats', "eff_uci"), `index']
						}
						
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
				local model : word `j' of `modellist2'
				local teststat : word `j' of `teststatlist2'
				local wgtopt   : word `j' of `wgtoptlist2'
				local bystats  : word `j' of `bystatslist'
				
				// User-defined second model, or nosecsub
				local colnames : colnames `bystats'
				if (`j' > 1 & "`secsub'"!="") {		// Note: no need to specify "`model'"!="user" as we are within a loop involving `m2'
					continue, break
				}			

				local wgtstar
				if `"`wgtopt'"'!="default" local wgtstar " **"
		
				scalar `testStat' = `bystats'[rownumb(`bystats', "`teststat'"), `i']
				scalar `df' = .
				if "`teststat'"=="t" {
					scalar `df' = `bystats'[rownumb(`bystats', "df"), `i']
					
					// if only one study, revert to z [IN PRACTICE, THIS SHOULD ALREADY HAVE BEEN DETECTED]
					if `df'==0 {
						local teststat z
						scalar `testStat' = `bystats'[rownumb(`bystats', "`teststat'"), `i']
						scalar `df' = .
					}
				}
				scalar `pvalue' = `bystats'[rownumb(`bystats', "pvalue"), `i']
			
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
				
				local labtext : copy local label`index'opt
				if `m'==1 {
					local labtext				// clear macro
					local continue _c
					local pos = `swidth' + 1
				}
				else local pos = 20 - `testdistlen' + 1
			
				if `j'==1 {
					disp as text substr("`bylabi'", 1, `swidth'-3) `continue'
				}

				disp as text `"  `labtext'`wgtstar' "' _c
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
			local model : word `j' of `modellist2'
			local teststat : word `j' of `teststatlist2'
			
			// Extract test statistics from `ovstats'
			scalar `testStat' = `ovstats'[rownumb(`ovstats', "`teststat'"), `j']
			scalar `df' = .
			if "`teststat'"=="t" {
				scalar `df' = `ovstats'[rownumb(`ovstats', "df"), `j']
			}
			scalar `pvalue' = `ovstats'[rownumb(`ovstats', "pvalue"), `j']

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
	
			if `m2'==1 {		// if only one model (default)
				if missing(`testStat') {
					disp as text `"Overall{col `=`swidth'+1'}(Insufficient data)"'
				}
				else {
					if `"`by'"'!=`""' & `"`subgroup'"'==`""' {
						disp as text `"Overall{col `=`swidth'+1'}"' _c
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
				
				local wgtstar
				local wgtopt : word `j' of `wgtoptlist2'
				if `"`wgtopt'"'!="default" local wgtstar " **"
				
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
	forvalues j = 1 / `m2' {
		local index : word `j' of `indexlist'
		local model  : word `j' of `modellist2'
		local wgtopt : word `j' of `wgtoptlist2'
		if `"`wgtopt'"'!="default" {
			local udw = 1
			
			if "`table'`overall'"=="" {
				local 0 `", `wgtopt'"'
				syntax [, WGT(varname numeric) ]
				local wgttitle : variable label `wgt'
				if `"`wgttitle'"'==`""' local wgttitle `wgt'

				if `m'==1 {
					disp as text _n "** Note: pooled using user-defined weights " as res "`wgttitle'"
				}
				else {
					local dnl = cond(`j'==1, "_n", "")
					disp as text `dnl' "** Note: `label`index'opt' pooled using user-defined weights " as res "`wgttitle'"
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
		tokenize `qlist'
		if `"`overall'"'!=`""' args Qsum Qbet		// if nooverall, only have between-subgroup Q
		else args Q Qdf Q_lci Q_uci Qsum Qbet
		
		
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
				
				if !missing(`Qi') {
					scalar `Qpval' = chi2tail(`Qdfi', `Qi')
					// local dfcol = cond(`"`overall'"'==`""', 18, 16)
					disp as text `"{col `=`swidth'+5'}"' as res %7.2f `Qi' `"{col `=`swidth'+18'}"' %3.0f `Qdfi' `"{col `=`swidth'+25'}"' %7.3f `Qpval' `"{col `=`swidth'+38'}"' %4.1f `Isq' _c
					if !missing(`Isq') disp as res "%"
					else disp ""
				}
				else disp as text `"{col `=`swidth'+5'}(Insufficient data)"'
				
			}

			if `"`overall'"'==`""' {
				disp as text `"Overall{col `=`swidth'+1'}{c |}"' _c
				if !missing(`Q') {
					scalar `Qpval' = chi2tail(`Qdf', `Q')
					scalar `Isq' = max(0, 100*(`Q' - `Qdf') / `Q')
					if `Q'==0 | `Qdf'==0 scalar `Isq' = .
					
					// local dfcol = cond(`"`overall'"'==`""', 18, 16)
					disp as text `"{col `=`swidth'+5'}"' as res %7.2f `Q' `"{col `=`swidth'+18'}"' %3.0f `Qdf' `"{col `=`swidth'+25'}"' %7.3f `Qpval' `"{col `=`swidth'+38'}"' %4.1f `Isq' _c
					if !missing(`Isq') disp as res "%"
					else disp ""
				}
				else disp as text `"{col `=`swidth'+5'}(Insufficient data)"'
			}
			
			// Mar 2020: want `nby' to reflect the number of subgroups *with data in*
			//  so restrict to `_USE'==1
			tempname Qbetpval
			qui levelsof `by' if `touse' & `_USE'==1, missing local(bylist_use1)
			local nby_use1 : word count `bylist_use1'
			scalar `Qbetpval' = chi2tail(`nby_use1' - 1, `Qbet')
			
			if "`model1'"!="iv" | `"`overall'"'!=`""' {
				disp as text `"Between{col `=`swidth'+1'}{c |}"' as text `"{col `=`swidth'+5'}"' ///
					as res %7.2f `Qbet' `"{col `=`swidth'+18'}"' %3.0f `nby_use1' - 1 `"{col `=`swidth'+25'}"' %7.3f `Qbetpval'
				disp as text `"{hline `swidth'}{c BT}{hline `hetWidth'}"'
				local endbox endbox

				if "`model1'"!="iv" {
					if "`model1'"=="peto" local hetlabel Peto
					else if "`model1'"=="ivhet" local hetlabel IVhet
					else if "`model1'"=="dlb" local hetlabel DLb
					else if "`model1'"=="ev" local hetlabel "Emp. Var."
					else if inlist("`model1'", "bp", "b0") local hetlabel = "Rukhin " + upper("`model1'")
					else local hetlabel = upper("`model1'")

					if `: list posof "hksj" in opts_drawtab'   local hetlabel "`hetlabel'+HKSJ"
					if `: list posof "kroger" in opts_drawtab' local hetlabel "`hetlabel'+KR"
					if `: list posof "robust" in opts_drawtab' local hetlabel "`hetlabel'+Rob."
					if `: list posof "bartlett" in opts_drawtab' local hetlabel "`hetlabel'+Bart."
					if `: list posof "skovgaard" in opts_drawtab' local hetlabel "`hetlabel'+Skov."
					
				    disp as text `"Note: between-subgroup heterogeneity calculated using `hetlabel' subgroup weights"'
				}
				// Jan 2020: between-subgroups Q can be calculated using either fixed and random-effects
				// c.f. Borenstein et al (2009) "Introduction to Meta-analysis", chapter 19
			}
			
			// I-V model, overall pooled result available
			else {
				// scalar `Qdiff' = `Q_ov' - `Qsum'		// between-subgroup heterogeneity (Qsum = within-subgroup het.)
				// scalar `Qdiffpval' = chi2tail(`nby' - 1, `Qdiff')
				
				tempname Fstat Fpval
				scalar `Fstat' = (`Qbet'/(`nby_use1' - 1)) / (`Qsum'/(`Qdf' - `nby_use1' + 1))		// corrected 17th March 2017
				scalar `Fpval' = Ftail(`nby_use1' - 1, `Qdf' - `nby_use1' + 1, `Fstat')
			
				disp as text `"Between{col `=`swidth'+1'}{c |}"' as text `"{col `=`swidth'+5'}"' ///
					as res %7.2f `Qbet' `"{col `=`swidth'+18'}"' %3.0f `nby_use1' - 1 `"{col `=`swidth'+25'}"' %7.3f `Qbetpval'
				disp as text `"Between:Within (F){col `=`swidth'+1'}{c |}"' as text `"{col `=`swidth'+5'}"' ///
					as res %7.2f `Fstat' `"{col `=`swidth'+14'}"' %3.0f `nby_use1' - 1 as text "," ///
					as res %3.0f `Qdf' - `nby_use1' + 1 `"{col `=`swidth'+25'}"' %7.3f `Fpval'
			
				disp as text `"{hline `swidth'}{c BT}{hline `hetWidth'}"'
				local endbox yes
				
				// DISPLAY BETWEEN-GROUP TEST WARNINGS [taken from -metan- v3.04]
				// (needs to be *outside* the box, hence `endbox')
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
		}		// end if `nby' > 1 & `"`by'"'!=`""' & `"`subgroup'"'==`""'
		
		
		****************
		* General case *
		****************

		else {
			disp as text _n(2) `"Heterogeneity measures, calculated from the data"'
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
			if !missing(`Q') {
				scalar `Qpval' = chi2tail(`Qdf', `Q')
				// local dfcol = cond(`"`overall'"'==`""', 18, 16)
				disp as text `"{col `=`swidth'+5'}"' as res %7.2f `Q' `"{col `=`swidth'+18'}"' %3.0f `Qdf' `"{col `=`swidth'+25'}"' %7.3f `Qpval'
			}
			else disp as text `"{col `=`swidth'+5'}(Insufficient data)"'

			// Special case: Single sensitivity analysis
			if `m'==1 & "`model1'"=="sa" {
				disp as text `"{hline `swidth'}{c BT}{hline `hetWidth'}"'		// end previous box
				
				disp as text _n `"Heterogeneity measures (based on user-defined "' _c
				if `tsqsa'==-99 disp "I{c 178} = " as res "`isqsa'%" as text ")"
				else disp `"tau{c 178} = "' as res `"`=strofreal(`tsqsa', "%05.3f")'"' as text `")"'
				disp as text `"{hline `swidth'}{c TT}{hline 13}"'
				disp as text `"{col `=`swidth'+1'}{c |}{col `=`swidth'+7'}Value"'
				disp as text `"{hline `swidth'}{c +}{hline 13}"'

				foreach x in tausq H Isq HsqM {
					tempname `x'
					scalar ``x'' = `hetstats'[rownumb(`hetstats', "`x'"), 1]
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
				
					disp as text _n(2) "Heterogeneity variance estimates"
					local RefModList mp ml pl reml bt dlb
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
						local c : list posof "`mod'" in modellist2

						// sort out "duplicate" tsq + CIs associated with more than one model
						if "`mod'"=="ml" {
							if !`c' local c : list posof "pl" in modellist2
							local label`c'opt "ML/PL"
						}
						else if "`mod'"=="dl" {
							if !`c' local c : list posof "ivhet" in modellist2
							if !`c' local c : list posof "qe" in modellist2
							if !`c' local c : list posof "hc" in modellist2
							local label`c'opt DL
						} 						
						else if "`mod'"=="reml" local label`c'opt REML		// in case of Kenward-Roger
						else if "`mod'"=="dlb" local label`c'opt DLb
						else if "`mod'"=="ev" local label`c'opt "Emp. Var."
						else if inlist("`mod'", "bp", "b0") local label`c'opt = "Rukhin " + upper("`mod'")
						else local label`c'opt = upper("`mod'")
						
						local c_list `c_list' `c'

						tempname tausq
						scalar `tausq' = `ovstats'[rownumb(`ovstats', "tausq"), `c']

						disp as text `"`label`c'opt'{col `=`swidth'+1'}{c |}{col `=`swidth'+4'}"' ///
							as res %8.4f `tausq' _c
						if `"`: list mod & RefModList'"'==`""' disp ""		// cancel _c
						else {
							tempname tsq_lci tsq_uci
							scalar `tsq_lci' = `ovstats'[rownumb(`ovstats', "tsq_lci"), `c']
							scalar `tsq_uci' = `ovstats'[rownumb(`ovstats', "tsq_uci"), `c']
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
								scalar ``x'' = `hetstats'[rownumb(`hetstats', "`x'"), `c']
							}

							// N.B. `label`c'opt' has already been parsed; no need to do so again
							disp as text `"`label`c'opt'{col `=`swidth'+1'}{c |}{col `=`swidth'+4'}"' ///
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

// (called directly by metan.ado)

// [N.B. mostly end part of old (v2.2) MainRoutine subroutine]


program define BuildResultsSet, rclass
	
	
	*****************
	* Initial setup *
	*****************
	syntax varlist(numeric min=3 max=7) [if] [in], ///
		OUTVLIST(varlist numeric min=5 max=9) MODELLIST(namelist) QSTAT(name) SORTBY(varlist) [ NPTS * ]
	
	marksample touse, novarlist	// -novarlist- option prevents -marksample- from setting `touse' to zero if any missing values in `varlist'
								// we want to control this behaviour ourselves, e.g. by using KEEPALL option
	
	// unpack varlists
	gettoken _USE invlist : varlist
	tokenize `outvlist'
	args _ES _seES _LCI _UCI _WT _NN

	if `"`npts'"'!=`""' {
		cap confirm numeric var `_NN'
		if _rc {
			nois disp as err _n "cannot use {bf:npts} option; no patient numbers available"
			nois disp as err "maybe the option {bf:npts(}{it:varname}{bf:)} was intended?"
			exit 198
		}
		local npts npts(`_NN')
		local nptsvar `_NN'
	}
		

	******************************
	* Initial parsing of options *
	******************************

	// Need to parse *all* (expected) options here,
	// so that we can see what is "left over", and exit with error if necessary
	
	// Jan 2021: Before Stata 15, -syntax- statements could only have 70 named options
	// Therefore, to avoid errors, we need to parse options in two smaller groups:
	local 0 `", `options'"'
	syntax, [LABELS(varname) SUMMSTAT(string) STUDY(varname numeric) BY(varname numeric) BYLIST(numlist miss) BYSTATSLIST(namelist) ///
		QLIST(numlist miss min=2 max=6) BYQ(name) HETSTATS(name) BYHETLIST(namelist) MWT(name) OVSTATS(name) ///
		CUmulative INFluence PRoportion noOVerall noSUbgroup noSECsub SUMMARYONLY OVWt SGWt ALTWt WGT(varname numeric) ///
		EFORM EFFect(string asis) LOGRank CC(string) CCVAR(name) ISQParam /* <-- NEW SEP 2020*/ ///
		* ]
		
	local 0 `", `options'"'
	syntax, [LCols(varlist) RCols(varlist) COUNTS(string asis) EFFIcacy OEV ///
		XOUTVLIST(varlist numeric) PRVLIST(varlist numeric) DENOMinator(real 1) NOPR RFDist RFLevel(cilevel) ILevel(cilevel) OLevel(cilevel) ///
		EXTRALine(string) HETINFO(string) noHET HLevel(cilevel) noWT noSTATs ///
		KEEPAll KEEPOrder noGRaph noWARNing SAVING(string) CLEAR FORESTplot(string asis) FPNOTE(string asis) ///
		SFMTLEN(integer 8) PLOTID(passthru) noRSample noMODELLABels /* <-- NEW NOV 2020 */ ///
		///
		SOURCE(varname numeric) LRVLIST(varlist numeric) ESTEXP(string) EXPLIST(passthru) IPDMETAN * ] /* IPD+AD options; undocumented */
		
	// [Nov 2020:]
	// remaining options are `model1opts' (i.e. for display based on main/primary model), plus:
	// - label#opt(string asis) -- model label (e.g. IV, or Fixed);  c.f. "desc" in "first(es lci uci desc)" or "second(...)"
	// - extra#opt(string asis) -- "extra" label (e.g. heterogeneity, for forest plot);  c.f. firststats(), secondstats()
	// - user#stats(numlist min=3 max=3) -- c.f. "es lci uci" in "first(es lci uci desc)" or "second(...)"

	// rename locals for consistency with rest of metan.ado
	local _BY     `by' 
	local _STUDY  `study'
	local _LABELS `labels'
	local _SOURCE `source'

	
	// Multiple models
	local m : word count `modellist'
	gettoken model1 : modellist
	forvalues j = 1 / `m' {
		local 0 `", `options'"'
		syntax [, LABEL`j'opt(string asis) EXTRA`j'opt(string asis) USER`j'stats(numlist min=3 max=3) * ]
	}

	// Trap any additional options; give suitable error message
	// Should only be un-parsed elements of `model1opts', i.e. suitable for PerformPooling
	//  remove these, as they are irrelevant here
	local 0 `", `options'"'
	syntax [, HKsj BArtlett SKovgaard RObust TN(passthru) QWT(passthru) ///
		ISQsa(passthru) TSQsa(passthru) INIT(passthru) TRUNCate(passthru) KRoger EIM OIM CMHNocc ///
		ITOL(passthru) MAXTausq(passthru) REPS(passthru) MAXITer(passthru) QUADPTS(passthru) DIFficult TECHnique(passthru) * ]
	
	if `"`options'"'!=`""' {
		
		// May 2020:
		// Following discussion with Jonathan Sterne, this part of the code has been modified, so that:
		//  - any valid -metan9- options relevant to the forest plot are let through with a "warning" (see later code)
		//  - similarly for any valid -twoway- options (as they also would have been valid for -metan9- )
		//  - otherwise, exit with error.  This is done immediately below; the others are done later.
		
		// Plot-related options valid with -metan- version 4 only
		local 0 `", `options'"'
		syntax [, KEEPAll USESTRICT LEFTJustify COLSONLY ///
			noNAmes noNULL /*NULL2(passthru)*/ /*NULL() is a valid -metan9- option*/ DATAID(string) SAVEDIms(name) USEDIms(name) noADJust ///
			FP(passthru) KEEPXLabs RAnge(passthru) CIRAnge(passthru) SPacing(passthru) ADDHeight(passthru) ///
			noLCOLSCHeck TArget(passthru) MAXWidth(passthru) MAXLines(passthru) noTRUNCate ///
			NLINEOPts(passthru) OCILINEOPts(passthru) RFOPts(passthru) RFCILINEOPts(passthru) * ]
		
		local badopts keepall usestrict leftjustify colsonly names null adjust keepxlabs lcolscheck truncate
		foreach op of local badopts {
			if `"``op''"'!=`""' {
				nois disp as err _n `"Option {bf:``op''} may only be supplied as a sub-option to the {bf:forestplot()} option; see {help metan:help metan}"'
				exit 198
			}
		}
		local badopts dataid savedims usedims fp range cirange spacing addheight target maxwidth maxlines
		local badopts `badopts' nlineopts ocilineopts rfopts rfcilineopts
		foreach op of local badopts {
			if `"``op''"'!=`""' {
				nois disp as err _n `"Option {bf:`op'()} may only be supplied as a sub-option to the {bf:forestplot()} option; see {help metan:help metan}"'
				exit 198
			}
		}
		
		// May 2020: parse for options of the form "[plot]#opts"
		// If found, exit with error
		if `"`plotid'"'!=`""' {
			CheckPlotIDOpts if `touse', `plotid' twowayopts(`options')
		}
		local twowayopts : copy local options		// any remaining options are assumed to be -twoway- options

		// May 2020:
		// Assume that remaining options (stored in `options') are valid -twoway- options (if they are not, -forestplot- will exit with error!)
		// These may have been valid with -metan9- (i.e. metan v3.x and earlier) and hence must also be allowed here, for backwards compatibility.
		// However, if no graph, but `saving' or `clear' is requested, we are in -metan- v4+ territory
		// and therefore *any* remaining option is an error
		if (`"`saving'"'!=`""' | `"`clear'"'!=`""') & `"`graph'"'!=`""' & `"`options'"'!=`""' {
			local op : word 1 of `options'
			nois disp as err _n `"Option {bf:`op'} may only be supplied as a sub-option to the {bf:forestplot()} option; see {help metan:help metan}"'
			exit 198
		}
		// Otherwise: after -metan- has taken back control from -forestplot- , check these options again and print warning message if applicable.
	}	
	
	// Now, if !(`"`saving'"'!=`""' | `"`clear'"'!=`""' | `"`graph'"'==`""'), exit the subroutine without error
	if !(`"`saving'"'!=`""' | `"`clear'"'!=`""' | `"`graph'"'==`""') {
		exit
	}
	if `"`_LABELS'"'==`""' {
		nois disp as err "option {bf:labels()} required"
		exit 198
	}
	
	
	********************************
	* Test validity of lcols/rcols *
	********************************
	// Cannot be any of the names -metan- (or -ipdmetan- etc.) uses for other things
	// To keep things simple, forbid any varnames:
	//  - beginning with a single underscore followed by a capital letter
	//  - beginning with "_counts" 
	// (Oct 2018: N.B. was `badnames')
	local lrcols `lcols' `rcols'
	local check = 0	
	if trim(`"`lrcols'"') != `""' {
		local cALPHA `c(ALPHA)'

		foreach el of local lrcols {
			local el2 = substr(`"`el'"', 2, 1)
			if substr(`"`el'"', 1, 1)==`"_"' & `: list el2 in cALPHA' {
				nois disp as err _n `"Error in option {bf:lcols()} or {bf:rcols()}:  Variable names such as {bf:`el'}, beginning with an underscore followed by a capital letter,"'
				nois disp as err `" are reserved for use by {bf:ipdmetan}, {bf:ipdover} and {bf:forestplot}."'
				nois disp as err `"In order to save the results set, please rename this variable or use {bf:{help clonevar}}."'
				exit 101
			}
			else if substr(`"`el'"', 1, 7)==`"_counts"' {
				nois disp as err _n `"Error in option {bf:lcols()} or {bf:rcols()}:  Variable names beginning {bf:_counts} are reserved for use by {bf:ipdmetan}, {bf:ipdover} and {bf:forestplot}."'
				nois disp as err `"In order to save the results set, please rename this variable or use {bf:{help clonevar}}."'
				exit 101
			}
		
			// `saving' / `clear' only:
			// Test validity of (value) *label* names: just _BY, _STUDY, _SOURCE as applicable
			// Value labels are unique within datasets. Hence, not a problem for a var in lcols/rcols to have same value label as the by() or study() variable.
			// However, a var in lcols/rcols **cannot** use the label name _BY or _STUDY **unless** the by() or study() variable is already sharing that label name.
			// (Also, cannot use _SOURCE as a value label if `"`_SOURCE'"'!=`""')
			if `"`saving'"'!=`""' | `"`clear'"'!=`""' {
			
				local lrlab : value label `el'
				if `"`lrlab'"'==`"_BY"' {
					if `"`_BY'"'==`""' local check = 1
					else {
						if `"`: value label `_BY''"'!=`"_BY"' local check = 1
					}
				}
				if `"`lrlab'"'==`"_STUDY"' {
					if `"`_STUDY'"'==`""' local check = 1
					else {
						if `"`: value label `_STUDY''"'!=`"_STUDY"' local check = 1
					}
				}
				if `"`lrlab'"'==`"_SOURCE"' {
					if `"`_SOURCE'"'==`""' local check = 1
					else {
						if `"`: value label `_SOURCE''"'!=`"_SOURCE"' local check = 1
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
	
	
	
	********************************
	* Subgroup and Overall effects *
	********************************
	// Create new observations to hold subgroup & overall effects (_USE==3, 5)
	//   (these can simply be removed again to restore the original data.)

	// N.B. Such observations may already have been created if passed through from -ipdmetan-
	//   but in any case, cover all bases by checking for (if applicable) a _USE==3 corresponding to each `by'-value,
	//   plus a single overall _USE==5.
	
	// If `saving' or `clear', need to -preserve- at this point
	//  (also take the opportunity to test validity of filename)
	if `"`saving'"'!=`""' | `"`clear'"'!=`""'{
	
		if `"`saving'"'!=`""' {
			// use modified version of _prefix_saving.ado to handle `stacklabel' option
			my_prefix_savingAD `saving'
			local saving `"`s(filename)'"'
			local 0 `", `s(options)'"'
			syntax [, STACKlabel * ]
			local saveopts `"`options'"'
		}
		
		// (N.B. if _rsample!="", i.e. no saved vars: already preserved)
		if `"`rsample'"'==`""' preserve
		
		// keep `touse' itself for now to make subsequent coding easier
		qui keep if `touse'

	}		// end if `"`saving'"'!=`""' | `"`clear'"'!=`""'
	
	tempvar obs
	qui gen long `obs' = _n

	// Sep 2020: Unpack `qlist'
	tokenize `qlist'
	if `"`overall'"'!=`""' args Qsum Qbet		// if nooverall, only have between-subgroup Q
	else args Q Qdf Q_lci Q_uci Qsum Qbet

	// Setup "translation" from ovstats/bystats matrix rownames to stored varnames
	if `"`xoutvlist'"'!=`""' {
		local rownames
		cap local rownames : rownames `ovstats'
		if _rc cap local rownames : rownames `bystatslist'	// if `xoutvlist', multiple models not allowed
															// so `bystatslist' should contain (at most) a single element
		if `"`rownames'"'!=`""' {
			// [DEC 2020:] re-form `xrownames' from `rownames'
			local core eff se_eff eff_lci eff_uci npts
			local xrownames : list rownames - core
			local xrownames `xrownames' Q Qdf Q_lci Q_uci
			if `: list posof "tausq" in rownames' local xrownames `xrownames' sigmasq
			
			local nx : word count `xoutvlist'
			assert `nx' == `: word count `xrownames''
			forvalues i = 1 / `nx' {
				local el : word `i' of `xrownames'
				if      `"`el'"'==`"Q_lci"' local vnames `vnames' _Qlci
				else if `"`el'"'==`"Q_uci"' local vnames `vnames' _Quci
				else local vnames `vnames' _`el'
				local      rnames `rnames'  `el'
			}
			
			tokenize `xoutvlist'
			args `vnames'			// for later
		}
	}
	if "`prvlist'"!="" {
		local pr_vnames	_Prop_ES _Prop_LCI _Prop_UCI
		local pr_rnames prop_eff  prop_lci  prop_uci
		tokenize `prvlist'
		args `pr_vnames'
	}
	local vnames _ES  _seES    _LCI    _UCI `pr_vnames' `vnames'
	local rnames eff se_eff eff_lci eff_uci `pr_rnames' `rnames'
	
	// if rfdist, obtain appropriate varnames
	if `"`rfdist'"'!=`""' {			
		tempvar _rfLCI _rfUCI
		qui gen double `_rfLCI' = .
		qui gen double `_rfUCI' = .
		local rfdnames _rfLCI _rfUCI
		local vnames `vnames' `rfdnames'
		
		if "`prvlist'"!="" local rnames `rnames' prop_rflci prop_rfuci
		else local rnames `rnames' rflci rfuci
	}
	local na : word count `vnames'
		
	// subgroup effects (`_USE'==3)
	local nby : word count `bylist'
	if `"`_BY'"'!=`""' & `"`subgroup'"'==`""' {
		forvalues i = 1 / `nby' {
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
				else {
				    local ++index
					local bystats : word `index' of `bystatslist'
					if "`bystats'"!="" {
						forvalues k = 1 / `na' {
							local v  : word `k' of `vnames'
							local el : word `k' of `rnames'
							local rownumb = rownumb(`bystats', "`el'")
							if !missing(`rownumb') {
								qui replace ``v'' = `bystats'[`rownumb', `i'] in `=`omin' - 1 + `j''
							}
							
							// ... or from `hetstats'
							else if "`hetstats'"!="" {
								local hetstats : word `index' of `byhetlist'
								local rownumb = rownumb(`hetstats', "`el'")
								if !missing(`rownumb') {
									qui replace ``v'' = `hetstats'[`rownumb', `i'] in `=`omin' - 1 + `j''
								}
							}
							
							// ... or from `byQ'
							else {
								local rownumb = rownumb(`byq', "`el'")
								if !missing(`rownumb') {
									qui replace ``v'' = `byq'[`rownumb', `i'] in `=`omin' - 1 + `j''
								}
							}
						}
					}
					
					// `mwt' should always exist if `"`by'"'!=`""' & `"`subgroup'"'==`""' & `"`sgwt'"'==`""'
					if `"`sgwt'"'==`""' {
						qui replace `_WT' = `mwt'[`index', `i'] in `=`omin' - 1 + `j''
					}
					qui replace `obs' = `j' in `=`omin' - 1 + `j''
				}
			}
			if `"`sgwt'"'!=`""' qui replace `_WT' = cond(!missing(`_ES'), 100, .) in `omin'		// only for the first model
			
		}	// end forvalues i = 1 / `nby'
	}	// end if `"`_BY'"'!=`""' & `"`subgroup'"'==`""'

	// overall effect (`_USE'==5)
	if `"`overall'"'==`""' {
		
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
			qui replace `obs' = `j' in `=`omin' - 1 + `j''
			
			// insert user-defined stats if appropriate...
			if "`model'"=="user" {
				tokenize `user`j'stats'
				qui replace `_ES'  = `1' in `=`omin' - 1 + `j''
				qui replace `_LCI' = `2' in `=`omin' - 1 + `j''
				qui replace `_UCI' = `3' in `=`omin' - 1 + `j''
			}

			// ... o/w insert statistics from `ovstats'
			else if "`ovstats'"!="" {
				local ++index
				forvalues k = 1 / `na' {
					local v  : word `k' of `vnames'
					local el : word `k' of `rnames'
					local rownumb = rownumb(`ovstats', "`el'")
					if !missing(`rownumb') {
						qui replace ``v'' = `ovstats'[`rownumb', `index'] in `=`omin' - 1 + `j''
					}
					
					// ... or from `hetstats'
					else if "`hetstats'"!="" {
						local rownumb = rownumb(`hetstats', "`el'")
						if !missing(`rownumb') {
							qui replace ``v'' = `hetstats'[`rownumb', `index'] in `=`omin' - 1 + `j''
						}
					}
						
					// ... or from `qlist'
					else if "`el'"=="Q"     qui replace ``v'' = `Q'     in `=`omin' - 1 + `j''
					else if "`el'"=="Qdf"   qui replace ``v'' = `Qdf'   in `=`omin' - 1 + `j''
					else if "`el'"=="Q_lci"	qui replace ``v'' = `Q_lci' in `=`omin' - 1 + `j''
					else if "`el'"=="Q_uci" qui replace ``v'' = `Q_uci' in `=`omin' - 1 + `j''
				}
			}
		}
		
		if `"`ovwt'"'!=`""' qui replace `_WT' = cond(!missing(`_ES'), 100, .) in `omin'		// only for the first model
		
	}		// end if `"`overall'"'==`""'
	

	// June 2020: If `ipdmetan', may need to remove `_USE'==3, 5 if `nooverall' / `nosubgroup' (e.g. if `influence')
	if `"`ipdmetan'"'!=`""' {
		if `"`subgroup'"'!=`""' cap drop if `_USE'==3
		if `"`overall'"'!=`""'  cap drop if `_USE'==5
	}

	
	// _BY will typically be missing for _USE==5, so need to be careful when sorting
	// Hence, generate marker of _USE==5 to sort on *before* _BY
	tempvar use5
	qui gen byte `use5' = 0 if `touse'
	summ `_USE' if `touse', meanonly
	if r(max)==5 & `"`_BY'"'!=`""' {
		qui replace `use5' = (`_USE'==5)
	}

	// `obs' is not needed anymore, so use it to identify models for USE==3, 5
	qui replace `obs' = 0 if !inlist(`_USE', 3, 5)
	qui assert inrange(`obs', 1, `m') if `obs' > 0
	local useModel `obs'				// rename
	
	
	
	*******************************
	* Fill down counts, npts, oev *
	*******************************	
	local params : word count `invlist'
	
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
			label variable `_OE' `"O-E(o)"'
			label variable `_V'  `"V(o)"'
			format `_OE' %6.2f
			format `_V' %6.2f
		}
	}			// end if `"`counts'"'!=`""' | `"`oev'"'!=`""'

	// Create `sumvlist' containing list of vars to fill down
	if `"`counts'"'!=`""' {
		if "`proportion'"!="" {
			local sumvlist e0 n0
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
	if `"`oev'"'!=`""' local sumvlist `sumvlist' _OE _V
	if "`nptsvar'"!="" local sumvlist `sumvlist' _NN
	
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
					summ ``x'' if `touse' & `_USE'==5, meanonly
					
					if !(`"`_BY'"'!=`""' & `"`subgroup'"'==`""') {
						qui gen `xtype' `sum_`x'' = `tempsum' if `touse' & `_USE'==5
						qui replace `sum_`x'' = r(sum) - ``x'' if `touse' & `_USE'==1
					}
					else {
						qui replace `sum_`x'' = `tempsum' if `touse' & `_USE'==5	// `useModel' not relevant as cumulative/influence not compatible with multiple models
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
	//  ... but _NN needs to be treated differently)
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

		if "`proportion'"!="" local countsvl _counts0
		else local countsvl _counts1 _counts0
		if `params'==6 local countsvl `countsvl' _counts1msd _counts0msd

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
	
		if `"`saving'"'!=`""' | `"`clear'"'!=`""' {
			cap drop _VE
			local _VE _VE
		}
		else tempvar _VE
		qui gen `_VE' = string(100*(1 - exp(`_ES')), "%4.0f") + " (" ///
			+ string(100*(1 - exp(`_LCI')), "%4.0f") + ", " ///
			+ string(100*(1 - exp(`_UCI')), "%4.0f") + ")" if `_USE'==1 | (inlist(`_USE', 3, 5) & `useModel'==1)
		
		label variable `_VE' "Vaccine efficacy (%)"
		
		qui gen `strlen' = length(`_VE')
		summ `strlen', meanonly
		format %`r(max)'s `_VE'
		qui compress `_VE'
		drop `strlen'
	}

	

	*****************************************
	* Rename tempvars to permanent varnames *
	*****************************************

	// Modified and moved downwards June 2020
	cap confirm numeric var `ccvar'
	if !_rc & `"`cc'"'!=`""' {
		local 0 `cc'
		syntax anything(name=ccval) [, *]
		if `ccval' {
			local _CC `ccvar'
			c_local _CC `ccvar'
		}
	}
	
	// Initialize varlists to save in Results Set:
	// `core':  "core" variables (N.B. *excluding* _NN)
	local core _ES _seES _LCI _UCI `pr_vnames' _WT
	
	// tosave':  additional "internal" vars created by specific options
	// [may contain:  _NN;  _OE _V if `oev';  `countsvl' if `counts';  _VE if `efficacy';  _CC if `cc';  _rfLCI _rfUCI if `rfdist']
	if `"`_NN'"'!=`""' local tosave _NN
	if `"`oev'"'!=`""' local tosave `tosave' _OE _V
	if `"`counts'"'!=`""' local tosave `tosave' `countsvl'
	if `"`efficacy'"'!=`""' local tosave `tosave' _VE
	if `"`_CC'"'!=`""' local tosave `tosave' _CC
	if `"`rfdist'"'!=`""' local tosave `tosave' _rfLCI _rfUCI
	if `"`xoutvlist'"'!=`""' local tosave : list tosave | vnames
	local tosave : list tosave - core
	
	// "Labelling" variables: _USE, _STUDY, _BY etc.
	local labelvars _USE
	local _BY = cond(`"`byad'"'!=`""', `""', `"`_BY'"')
	if `"`_BY'"'!=`""'     local labelvars `labelvars' _BY
	if `"`_SOURCE'"'!=`""' local labelvars `labelvars' _SOURCE
	local labelvars `labelvars' _STUDY _LABELS

	// If `saving' / `clear', finish off renaming tempvars to permanent varnames
	// ...in order to store them in the *saved* dataset (NOT the data in memory)
	if `"`saving'"'!=`""' | `"`clear'"'!=`""' {
		
		local tocheck `labelvars' `core' `tosave'
		foreach v of local tocheck {
			if `"``v''"'!=`""' {						// N.B. xoutvlist is independent of [no]keepvars.
				confirm variable ``v''

				// For numeric _STUDY, _BY and _SOURCE,
				//   check if pre-existing var (``v'') has the "correct" value label name (`v').
				// If it does not, drop any existing value label `v', and copy current value label across to `v'.
				if inlist("`v'", "_STUDY", "_BY", "_SOURCE") {
					if `"`: value label ``v'''"' != `""' & `"`: value label ``v'''"' != `"`v'"' {
						cap label drop `v'
						label copy `: value label ``v''' `v'
						label values ``v'' `v'
					}
				}
			
				// Similar logic now applies to variable names:
				// Check if pre-existing var has the same name (i.e. was named _BY, _STUDY etc.)
				// If it does not, first drop any existing var named _BY, _STUDY (e.g. left over from previous -metan- call), then rename.
				if `"``v''"'!=`"`v'"' {
					cap drop `v'
					
					// If ``v'' is in `lrcols', use -clonevar-, so as also to keep original name
					if `: list `v' in lrcols' {
						qui clonevar `v' = ``v'' if `touse'
					}
					else qui rename ``v'' `v'
				}

				// IF RENAMING, DON'T REFORMAT; KEEP ORIGINAL FORMAT
				// SO THAT -forestplot- USES ORIGINAL FORMAT
				// APPLIES TO _ES, _seES, _LCI, _UCI
				else if inlist("`v'", "_ES", "_seES", "_LCI", "_UCI") {
					format  %6.3f ``v''
					label variable ``v'' "`v'"
				}
				
				local `v' `v'				// for use with subsequent code

				// Added Jan 2019 [CHECK IF THERE IS A BETTER WAY TO HANDLE THIS]
				if "`v'"=="_NN" & `"`npts'"'!=`""' {
					local npts npts(_NN)
					local nptsvar _NN
				}				
			}
		}
	}		// end if `"`saving'"'!=`""' | `"`clear'"'!=`""'

				
	// Label variables with short-ish names for display on forest plots
	// Use characteristics to store longer, explanatory names
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
	
	// variable name (title) and format for "_NN" (if appropriate)
	if `"`_NN'"'!=`""' {
		if `"`: variable label `_NN''"'==`""' label variable `_NN' "No. pts"
		qui gen `strlen' = length(string(`_NN'))
		summ `strlen' if `touse', meanonly
		local fmtlen = max(`r(max)', 3)		// min of 3, otherwise title ("No. pts") won't fit
		format `_NN' %`fmtlen'.0f			// right-justified; fixed format (for integers)
		drop `strlen'

		if      `"`cumulative'"'!=`""' label variable `_NN' "Cumulative no. pts"
		else if `"`influence'"'!=`""'  label variable `_NN' "Remaining no. pts"
	}
	
	
	*********************
	* Insert extra rows *
	*********************
	// ... for headings, labels, spacings etc.
	//  Note: in the following routines, "half" values of _USE are used temporarily to get correct order
	//        and are then replaced with whole numbers at the end			
	
	// variable name (titles) for "_LABELS" or `stacklabel'
	if `"`_BY'"'!=`""' {
		local byvarlab : variable label `_BY'
	}
	if `"`summaryonly'"'!=`""' & `"`_BY'"'!=`""' local labtitle `"`byvarlab'"'
	else {
		if `"`_BY'"'!=`""' local bytitle `"`byvarlab' and "'
		if `"`_STUDY'"'!=`""' & `"`summaryonly'"'==`""' {
			local svarlab : variable label `_STUDY'
		}
		local stitle `"`bytitle'`svarlab'"'
		if `"`influence'"'!=`""' local stitle `"`stitle' omitted"'
		local labtitle `"`stitle'"'
	}
	if `"`stacklabel'"'==`""' label variable `_LABELS' `"`labtitle'"'
	else label variable `_LABELS'		// no title if `stacklabel'


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
	
	// Now temporarily multiply _USE by 10
	// to enable intermediate numberings for sorting the extra rows
	qui replace `_USE' = `_USE'	* 10
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
		if "`subgroup'"=="" & `"`extraline'"'==`"yes"' {	// modified Sep 2020
			qui bysort `touse' `_BY' (`sortby') : gen byte `expand' = 1 + `touse'*(_n==_N)*(!`use5')
			qui expand `expand'
			qui replace `expand' = !(`expand' > 1)						// `expand' is now 0 if expanded and 1 otherwise (for sorting)
			sort `touse' `_BY' `expand' `_USE' `useModel' `_SOURCE' `sortby'
			qui by `touse' `_BY' : replace `_USE' = 39 if `touse' & !`expand' & _n==2	// extra row for het if lcols
			// qui replace `useModel'=1 if `_USE'==39									// place extra row after last model
			qui replace `useModel' = cond("`isqparam'"!="", 1, `m') if `_USE'==39		// Sep 2020: ... but after *first* model if `isqparam'
			drop `expand'
		}
	}
	
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
	local tosave2 : list tosave - rfdnames
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
	cap drop `use5'
	qui gen byte `use5' = 0 if `touse'
	if `"`stacklabel'"' != `""' {
		local newN = _N + 1
		qui set obs `newN'
		qui replace `touse' = 1  in `newN'
		qui replace `use5' = -1  in `newN'
		qui replace `_USE' = -10 in `newN'
		qui replace `_LABELS' = `"`labtitle'"' in `newN'
	}

	
	** Now insert label info into new rows

	if "`hetinfo'"=="" {
		local hetinfo = cond("`isqparam'"=="", "isq p", "isq")	// default, to match with -metan- v3.04
	}

	local disperr_tsqb  = 0		// init
	local disperr_tausq = 0		// init
	
	// Multiple models
	local index_ov = 0
	local index_by = 0
	forvalues j = 1 / `m' {
		local model : word `j' of `modellist'
		local first = cond(`j'==1, "first", "")		// marker of this being the first (aka main, aka primary) model

		// "overall" labels
		if `"`overall'"'==`""' {
			local ovhetlab
			
			if `"`het'"'==`""' {
				if "`model'"=="user" {
					local ovhetlab : copy local extra`j'opt
				}
				else {
				    local ++index_ov
					ParseHetInfo `hetinfo', ovstats(`ovstats') hetstats(`hetstats') ///
						col(`index_ov') `first' qlist(`Q' `Qdf') `isqparam' extraline(`extraline')
					local ovhetlab `"`s(hetlab)'"'
					local part_tausq `"`s(part_tausq)'"'						
				}
				if `"`ovhetlab'"'!=`""' local ovhetlab `"(`ovhetlab')"'
				
				// Overall heterogeneity - extra row if lcols
				// Usually placed after the *last* model ... but instead placed after the *first* model if `isqparam'
				// (doesn't apply to tausq, which is always appended to the model name)
				if "`extraline'"=="yes" & "`first'"!="" {
					local newN = _N + 1
					qui set obs `newN'
					qui replace `touse' = 1  in `newN'
					qui replace `use5'  = 1  in `newN'
					qui replace `_USE'  = 59 in `newN'
					qui replace `useModel' = cond("`isqparam'"!="", 1, `m') in `newN'
					qui replace `_LABELS' = `"`ovhetlab'"' if `_USE'==59
					local ovhetlab				// ovlabel on line below so no conflict with lcols; then clear macro
				}
			}		// end if `"`het'"'==`""'
		
			// Model labels (including hetinfo if appropriate)
			local addText
			if `"`modellabels'"'==`""' & trim(`"`label`j'opt'"')!=`""' ///
									local addText `", `label`j'opt'"'				// Nov 2020
			if `ilevel'!=`olevel'   local addText `"`addText' (`olevel'% CI)"'
			
			if `"`ovhetlab'"'!=`""' local addText `"`addText' `ovhetlab'"'
			else if `"`part_tausq'"'!=`""' local addText `"`addText' (`part_tausq')"'
			
			qui replace `_LABELS' = `"Overall`addText'"' if `_USE'==50 & `useModel'==`j'
			local ovhetlab
		}

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
					local sghetlab
				
					if `"`het'"'==`""' {
						
						// User-defined second model, or nosecsub
						local model : word `j' of `modellist'
						if ("`first'"=="" & "`secsub'"!="") | "`model'"=="user" {		// Note: "user" as model1 cannot be used with "by"
							continue, break
						}
						
						scalar `Qi'   = `byq'[rownumb(`byq', "Q"),  `i']
						scalar `Qdfi' = `byq'[rownumb(`byq', "Qdf"), `i']
						
						ParseHetInfo `hetinfo', ovstats(`bystats') hetstats(`byhet') ///
							col(`index_by') `first' qlist(`=`Qi'' `=`Qdfi'') `isqparam' extraline(`extraline')
		
						if `"`s(hetlab)'"'!=`""' local sghetlab `"(`s(hetlab)')"'
						local part_tausq `"`s(part_tausq)'"'
				
						// extra row:
						if `"`extraline'"'==`"yes"' & "`first'"!="" {
							qui replace `_LABELS' = "`sghetlab'" if `_USE'==39 & `_BY'==`byi'
							local sghetlab			// sghetlab on line below so no conflict with lcols; then clear macro
						}
					}		// end if `"`het'"'==`""'
					
					// Model labels (including hetinfo if appropriate)
					local addText
					if `"`modellabels'"'==`""' & trim(`"`label`j'opt'"')!=`""' ///
											local addText `", `label`j'opt'"'				// Nov 2020
					if `ilevel'!=`olevel'   local addText `"`addText' (`olevel'% CI)"'

					if `"`sghetlab'"'!=`""' local addText `"`addText' `sghetlab'"'
					else if `"`part_tausq'"'!=`""' local addText `"`addText' (`part_tausq')"'
					
					qui replace `_LABELS' = `"`sglabel'`addText'"' if `_USE'==30 & `_BY'==`byi' & `useModel'==`j'

				}		// end if `"`subgroup'"'==`""'
			}		// end forvalues i = 1 / `nby'
			
			// add between-group heterogeneity info
			// ONLY USE "PRIMARY" (FIRST) MODEL
			// Amended Jan 2020 to use Qbet rather than Qdiff:
			if "`first'"!="" & `"`subgroup'`het'"'==`""' {
				local newN = _N + 1
				qui set obs `newN'
				qui replace `touse' = 1  in `newN'
				qui replace `use5'  = 0  in `newN'
				qui replace `_USE'  = 49 in `newN'

				// Mar 2020: want `nby' to reflect the number of subgroups *with data in*
				//  so restrict to `_USE'==10
				qui levelsof `_BY' if `touse' & `_USE'==10, missing local(bylist_use1)
				local nby_use1 : word count `bylist_use1'
		
				tempname Qbetpval
				scalar `Qbetpval' = chi2tail(`nby_use1' - 1, `Qbet')
				qui replace `_LABELS' = "Heterogeneity between groups: p = " + string(`Qbetpval', "%5.3f") in `newN'
			}
		}		// end if `"`_BY'"'!=`""'
	}		// end forvalues j = 1 / `m'

	// Added Sep 2020
	if `disperr_tsqb' | `disperr_tausq' {
	    disp _n
		if `disperr_tsqb' {
			disp `"{error}Note: Elements {bf:Q} and {bf:pvalue} to option {bf:hetinfo()} are ignored if option {bf:isqparam} is specified"'
		}
		if `disperr_tausq' {
			disp `"{error}Note: Element {bf:tausq} to option {bf:hetinfo()} is not applicable to "' _c 
			if `m'==1 disp `"{error}model {bf:`model1'}"'
			else disp `"{error}all models"'
		}
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
	if "`proportion'"!="" & `denominator'!=1 {
		if "`prvlist'"!="" local toscale _Prop_ES _Prop_LCI _Prop_UCI
		else local toscale _ES _LCI _UCI
		if "`rfdist'"!="" local toscale `toscale' _rfLCI _rfUCI
		
		foreach v of local toscale {
			qui replace ``v'' = `denominator' * ``v''
		}
	}	
	

	*********************
	* Sort, and tidy up *
	*********************

	if `"`keeporder'"'!=`""' {
		tempvar tempuse
		qui gen byte `tempuse' = `_USE'
		qui replace `tempuse' = 10 if `_USE'==20		// keep "insufficient data" studies in original study order (default is to move to end)
	}
	else local tempuse `_USE'
	
	qui isid `touse' `use5' `_BY' `useModel' `tempuse' `_SOURCE' `sortby', sort missok
	
	// Tidy up `_USE' (and scale back down by 10)
	cap drop `use5'
	quietly {
		gen byte `use5' = inlist(`_USE', 35, 55)		// now `use5' is a marker of predictive interval data, if applicable
		replace `_USE' =  0 if `_USE' == -10
		replace `_USE' = 60 if `_USE' ==  41
		replace `_USE' = 30 if `_USE' ==  35
		replace `_USE' = 50 if `_USE' ==  55
		replace `_USE' = 40 if inlist(`_USE', 39, 49, 59)
		replace `_USE' = `_USE' / 10
	}	

	// Format and title weights
	if `m' > 1 label variable `_WT' `"`"% Weight,"' `"`label1opt'"'"'
	// May 2020: ^^ if modeltext is included, use compound quotes to force "% Weight" into a single line, with modeltext underneath
	else label variable `_WT' "% Weight"
	format `_WT' %6.2f
	
	// Check predictive interval data (after sorting and finalising _USE)
	// March 2020: added "& !missing(`_LCI')" to end of 3rd & 4th lines, in case of "empty" subgroups
	// May 2020: if `rflevel' < `olevel' and low heterogeneity, then (rfLCI, rfUCI) might be tighter than (LCI, UCI)
	if `"`rfdist'"'!=`""' {
		cap {
			if "`prvlist'"!="" {
				assert `_rfLCI' <= `_Prop_LCI'    if `touse' & !missing(`_rfLCI', `_Prop_LCI') & `rflevel'>=`olevel'
				assert `_rfUCI' >= `_Prop_UCI'    if `touse' & !missing(`_rfUCI', `_Prop_UCI') & `rflevel'>=`olevel'
				assert `use5' &  missing(`_Prop_ES')       if `touse' & inlist(`_USE', 3, 5) ///
					& float(`_rfLCI')==float(`_Prop_LCI') & float(`_rfUCI')==float(`_Prop_UCI') & !missing(`_Prop_LCI')
				assert `use5' & !missing(`_Prop_ES'[_n-1]) if `touse' & inlist(`_USE', 3, 5) ///
					& float(`_rfLCI')==float(`_Prop_LCI') & float(`_rfUCI')==float(`_Prop_UCI') & !missing(`_Prop_LCI')
			}
			else {
				assert `_rfLCI' <= `_LCI'    if `touse' & !missing(`_rfLCI', `_LCI') & `rflevel'>=`olevel'
				assert `_rfUCI' >= `_UCI'    if `touse' & !missing(`_rfUCI', `_UCI') & `rflevel'>=`olevel'
				assert `use5' &  missing(`_ES')       if `touse' & inlist(`_USE', 3, 5) ///
					& float(`_rfLCI')==float(`_LCI') & float(`_rfUCI')==float(`_UCI') & !missing(`_LCI')
				assert `use5' & !missing(`_ES'[_n-1]) if `touse' & inlist(`_USE', 3, 5) ///
					& float(`_rfLCI')==float(`_LCI') & float(`_rfUCI')==float(`_UCI') & !missing(`_LCI')
			}
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
		
		// special case: see ParseHetInfo
		if `"`part_tausq'"'!=`""' {
		    qui replace `strlen' = `strlen' - 11 if inlist(`_USE', 3, 5)
		}
		
		summ `strlen' if `touse' & inlist(`_USE', 1, 2, 3, 5) & !`use5', meanonly
		local sfmtlen = r(max)
		drop `strlen'
	    
		// Format as left-justified; default length equal to longest study name
		// But, niche case: in case study names are very short, look at title as well
		// If user really wants ultra-short width, they can convert to string and specify %-s format
		tokenize `"`: variable label `_LABELS''"'
		while `"`1'"'!=`""' {
			local sfmtlen = max(`sfmtlen', length(`"`1'"'))
			macro shift
		}
	}
	else local sfmtlen = abs(`sfmtlen')
	format `_LABELS' %-`sfmtlen's		// left justify _LABELS
	cap drop `use5'
	
	// Define varlist for passing to forestplot
	if "`prvlist'"!="" local fpvlist `_Prop_ES' `_Prop_LCI' `_Prop_UCI'
	else local fpvlist `_ES' `_LCI' `_UCI'

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
			
		cap drop _EFFECT
		qui gen str _EFFECT = string(`xexp'(`_ES'), `"%`fmtx'.`dp'f"') if !missing(`_ES')
		qui replace _EFFECT = _EFFECT + " " if !missing(_EFFECT)
		qui replace _EFFECT = _EFFECT + "(" + string(`xexp'(`_LCI'), `"%`fmtx'.`dp'f"') + ", " + string(`xexp'(`_UCI'), `"%`fmtx'.`dp'f"') + ")"
		qui replace _EFFECT = `""' if !(`touse' & inlist(`_USE', 1, 3, 5))
		qui replace _EFFECT = "(Insufficient data)" if `touse' & `_USE' == 2
		qui replace _EFFECT = "(Insufficient data)" if `touse' & inlist(`_USE', 3, 5) & missing(`_LCI')	// added March 2020, in case of "empty" subgroups

		local f = abs(fmtwidth("`: format _EFFECT'"))
		format _EFFECT %-`f's		// left-justify
		label variable _EFFECT `"`effect' (`ilevel'% CI)"'
		local _EFFECT _EFFECT
	}



	***************
	* Forest plot *
	***************
	// Finalise forestplot options
	// (do this whether or not `"`graph'"'==`""', so that options can be stored!)
	
	** Save _dta characteristic containing all the options passed to -forestplot-
	// so that they may be called automatically using "forestplot, useopts"
	// (N.B. `_USE', `_LABELS' and `_WT' should always exist)
	
	// May 2020: remove unnecessary spacing where possible
	// *BUT* watch out for options that contain text strings!  They must be left alone.
	// This involves: effect() and note(), plus `forestplot' and `twowayopts' which could contain anything
	if "`prvlist'"=="" local proportion			// only pass `proportion' to -forestplot- if on original scale
	local useopts  = trim(itrim(`"use(`_USE') labels(`_LABELS') wgt(`_WT') `cumulative' `influence' `proportion' `eform'"'))
	local useopts2 = trim(itrim(`"`keepall' `overall' `subgroup' `het' `wt' `stats' `warning' `plotid'"'))
	
	if `"`effect'"'!=`""'     local useopts `"`macval(useopts)' effect(`effect')"'
	local useopts `"`macval(useopts)' `macval(useopts2)'"'
	if `"`forestplot'"'!=`""' local useopts `"`macval(useopts)' `forestplot'"'
	if `"`twowayopts'"'!=`""' local useopts `"`macval(useopts)' `twowayopts'"'
	if `"`_BY'"'!=`""'        local useopts `"`macval(useopts)' by(`_BY')"'

	if `"`lcols'`nptsvar'`_counts1'`_counts1msd'`_counts0'`_counts0msd'`_OE'`_V'"' != `""' {
		local useopts2 = trim(itrim(`"`nptsvar' `_counts1' `_counts1msd' `_counts0' `_counts0msd' `_OE' `_V'"'))
		local useopts `"`macval(useopts)' lcols(`lcols' `useopts2') `lcolscheck'"'
	}
	if `"`_VE'`rcols'"' != `""' local useopts `"`macval(useopts)' rcols(`_VE' `rcols')"'
	if `"`rfdist'"'!=`""' local useopts `"`macval(useopts)' rfdist(`_rfLCI' `_rfUCI')"'
	if `"`fpnote'"'!=`""' local useopts `"`macval(useopts)' note(`fpnote')"'
	// local useopts = trim(itrim(`"`useopts'"'))		// May 2020: itrim() might remove intended multiple spaces within a string
	
	// Store data characteristics
	// NOTE: Only relevant if `saving' / `clear' (but setup anyway; no harm done)
	char define _dta[FPUseOpts] `"`useopts'"'
	char define _dta[FPUseVarlist] `fpvlist'


	** Pass to forestplot
	if `"`graph'"'==`""' {
	
		// Where necessary, set certain obs to "`touse'==0"
		//   note that they will still appear in the saved dataset!
		if `"`summaryonly'"'!=`""' {
			qui replace `touse' = 0 if inlist(`_USE', 1, 2)
		}

		cap nois forestplot `fpvlist' if `touse', `useopts'
		
		if _rc {
			if `"`err'"'==`""' {
				if _rc==1 nois disp as err _n `"User break in {bf:forestplot}"'
				else nois disp as err _n `"Error in {bf:forestplot}"'
			}
			c_local err noerr		// tell -metan- not to also report an "error in metan.BuildResultsSet"
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
		keep  `labelvars' `core' `tosave' `_EFFECT' `_WT' `lrcols'
		order `labelvars' `core' `tosave' `_EFFECT' `_WT' `lrcols'
			
		if `"`summaryonly'"'!=`""' qui drop if inlist(`_USE', 1, 2)
			
		local sourceprog = cond(`"`ipdmetan'"'!=`""', "ipdmetan", "metan")
		label data `"Results set created by `sourceprog'"'
		qui compress
		
		if `"`saving'"'!=`""' {
			qui save `"`saving'"', `saveopts'
		}
		if `"`clear'"'!=`""' cap restore, not
	}

end



* CheckPlotIDOpts
// May 2020: parse for options of the form "[plot]#opts"
// If found, exit with error

program define CheckPlotIDOpts

	syntax [if] [in] [, PLOTID(varname numeric) TWOWAYOPTS(string asis)]

	marksample touse
	local badopts box diam point ci oline nline ociline rf rficline
	local 0 `", `twowayopts'"'
	summ `plotid' if `touse', meanonly
	forvalues p = 1/`r(max)' {
		syntax [, BOX`p'opts(passthru) DIAM`p'opts(passthru) POINT`p'opts(passthru) CI`p'opts(passthru) ///
			OLINE`p'opts(passthru) NLINE`p'opts(passthru) OCILINE`p'opts(passthru) RF`p'opts(passthru) RFCILINE`p'opts(passthru) * ]

		foreach op of local badopts {
			if `"``op'`p'opts'"'!=`""' {
				nois disp as err _n `"Option {bf:`op'`p'opts()} may only be supplied as a sub-option to the {bf:forestplot()} option; see {help metan:help metan}"'
				exit 198
			}
		}
	}
	
end



* Modified version of _prefix_saving.ado
// [AD version] modified so as to include `stacklabel' option
// April 2018, for admetan v2.2

// subroutine of BuildResultsSet

program define my_prefix_savingAD, sclass
	 
	cap nois syntax anything(id="file name" name=fname) [, REPLACE * ]
	if !_rc {
		if "`replace'" == "" {
			local ss : subinstr local fname ".dta" ""
			confirm new file `"`ss'.dta"'
		}
	}
	else {
		nois disp as err "invalid saving() option"
		exit _rc
	}
	
	sreturn clear
	sreturn local filename `"`fname'"'
	sreturn local options `"`replace' `options'"'

end



* Subroutine to parse requested heterogeneity info for display on forest plot
// Sep 2020

program define ParseHetInfo, sclass

	syntax anything, OVSTATS(name) /// /* matrix containing overall/subgroup stats (required)
		COL(numlist integer min=1 max=1 >0) /// /* ... and column index for referencing matrix
		QLIST(numlist min=2 max=2) /// /* Q and Qdf for current analysis (required) */
		[ISQParam HETSTATS(name) /// /* matrix containing het. stats based on "parametric" Isq (optional) */
		FIRST /// /* marker that model is the first/main/primary model */
		EXTRALine(string) ]	/* placing of het. info on separate line from pooled estimate(s) */

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
	local hetlab
	tokenize `anything'
	while "`1'"!="" {
		local part

		// special case:  if element is tausq, and if extraline(yes) and not `isqparam',
		// then display alongside model name [e.g. DL (t2=0.xx) ] instead of with other heterogeneity stats
		if inlist("`1'", "tausq", "tau2") {
			local tausq = `ovstats'[rownumb(`ovstats', "tausq"), `col']
			if missing(`tausq') c_local disperr_tausq = 1
			else {
				if substr(`"`2'"', 1, 1) == `"%"' local fmt : copy local 2
				else local fmt "%05.3f"
				local part = `"{&tau}{sup:2} = "' + string(`tausq', "`fmt'")
				if `"`isqparam'"'==`""' & `"`extraline'"'==`"yes"' & "`first'"!="" {
					local part_tausq : copy local part
					local part
				}
			}
		}

		// if not `isqparam', parse other elements only for *first* model
		else if !("`first'"=="" & "`isqparam'"=="") {
			if lower("`1'")=="q" {
				if "`isqparam'"!="" c_local disperr_tsqb = 1
				else {
					if substr(`"`2'"', 1, 1) == `"%"' local fmt : copy local 2
					else local fmt "%5.2f"
					local part = `"Q = "' + string(`Q', "`fmt'") + `" on `=`Qdf'' df"'
				}
			}
			else if inlist("`1'", "p", "pv", "pva", "pval", "pvalu", "pvalue") {
				if "`isqparam'"!="" c_local disperr_tsqb = 1
				else {
					local Qpval = chi2tail(`Qdf', `Q')
					if substr(`"`2'"', 1, 1) == `"%"' local fmt : copy local 2
					else local fmt "%05.3f"
					local part = `"p = "' + string(`Qpval', "`fmt'")
				}
			}
			else if inlist("`1'", "h", "H") {
				if "`hetstats'"!="" {
					local H = `hetstats'[rownumb(`hetstats', "H"), `col']
				}
				else local H = sqrt(`Q' / `Qdf')
				if substr(`"`2'"', 1, 1) == `"%"' local fmt : copy local 2
				else local fmt "%5.2f"
				local part = `"H = "' + string(`H', "`fmt'")
			}
			else if inlist(lower("`1'"), "isq", "i2") {
				if "`hetstats'"!="" {
					local Isq = `hetstats'[rownumb(`hetstats', "Isq"), `col']
				}
				else local Isq = max(0, 100*(`Q' - `Qdf') / `Q')
				if substr(`"`2'"', 1, 1) == `"%"' local fmt : copy local 2
				else local fmt "%5.1f"
				local part = `"I{sup:2} = "' + string(`Isq', "`fmt'") + `"%"'
			}
			else if inlist(lower("`1'"), "h2m", "hsqm") {
				if "`hetstats'"!="" {
					local HsqM = `hetstats'[rownumb(`hetstats', "HsqM"), `col']
				}
				else local HsqM = `Isq' / (100 - `Isq')
				if substr(`"`2'"', 1, 1) == `"%"' local fmt : copy local 2
				else local fmt "%5.2f"
				local part = `"H{sup:2}{sub:M} = "' + string(`HsqM', "`fmt'")
			}
			else if `"`1'"'!=`""' {
				nois disp as err `"Error in option {bf:hetinfo()}: element {bf:`1'} is invalid"'
				exit 198
			}
		}		// end else if !(`col' > 1 & `"`isqparam'"'==`""')
		
		if "`part'"!="" {
			if "`hetlab'"=="" local hetlab : copy local part
			else local hetlab `"`hetlab', `part'"'
		}
		
		if substr(`"`2'"', 1, 1) == `"%"' macro shift 2
		else macro shift
		
	}	// end while "`1'"!=""
	
	sreturn clear
	sreturn local hetlab `"`hetlab'"'
	sreturn local part_tausq `"`part_tausq'"'		// only in special case; see above
	
end





*******************************************************************************

***************************************************
* Stata subroutines called by PerformMetaAnalysis *  (and its subroutines)
***************************************************


* ProcessPoolingVarlist
// subroutine of PerformMetaAnalysis

// subroutine to processes (non-IV) input varlist to create appropriate varlist for the specified pooling method
// That is, generate study-level effect size variables,
// plus variables used to generate overall/subgroup statistics

program define ProcessPoolingVarlist, sclass

	syntax varlist(numeric min=3 max=7 default=none) [if] [in], ///
		SUMMSTAT(name) MODEL(name) TESTSTAT(name) OUTVLIST(varlist numeric min=5 max=9) ///
		[PRVLIST(varlist numeric) TVLIST(namelist) CCLIST(namelist) ///
		LOGRank PRoportion noINTeger CC(string) CCVAR(name) WGT(name) OLevel(cilevel) ILevel(cilevel)]
	
	sreturn clear
	marksample touse, novarlist
	
	// unpack varlists
	tokenize `outvlist'
	args _ES _seES _LCI _UCI _WT _NN

	gettoken _USE invlist : varlist
	tokenize `invlist'
	local params : word count `invlist'
	
	
	** Setup for logrank HR (O-E & V)
	if "`logrank'"!="" {
		args oe va
		qui replace `_ES'   = `oe'/`va'    if `touse' & `_USE'==1		// logHR
		qui replace `_seES' = 1/sqrt(`va') if `touse' & `_USE'==1		// selogHR
		sreturn local oevlist `oe' `va'
	}

	
	** Setup for proportions
	else if "`proportion'"!="" {
		args succ _NN
		
		// Continuity correction: already prepared by ParseModel (for `ccval'>0)
		if `"`cc'"'!=`""' {
			local 0 `"`cc'"'
			syntax [anything(name=ccval)] [, *]
			if "`options'"!="" {
				nois disp as err "options not allowed"
				exit 101
			}
			cap confirm numeric variable `ccvar'
			local genreplace = cond(_rc, "gen byte", "replace")
			qui `genreplace' `ccvar' = inlist(`succ', 0, `_NN')
			summ `ccvar', meanonly
			local nz = r(sum)
			if !`nz' local cc		// ... if continuity correction is *applicable*
			else {					// (N.B. from now on, -confirm numeric var `ccvar'- will be used to check if cc was applied)
				tempvar succ_cc fail_cc
				qui gen double `succ_cc' = cond(`ccvar', `succ' + `ccval', `succ')
				qui gen double `fail_cc' = cond(`ccvar', `_NN' - `succ' + `ccval', `_NN' - `succ')
			}
		}
		if `"`cc'"'==`""' {
			local succ_cc `succ'
			local fail_cc `_NN' - `succ'
		}
		
		// Proportions on original scale
		// as described by Schwarzer et al, RSM 2019
		if "`summstat'"=="pr" {			// default
			qui replace `_ES' = `succ' / `_NN' if `touse' & `_USE'==1
			qui replace `_seES' = sqrt(`succ_cc' * (`fail_cc') / (`succ_cc' + `fail_cc')^3 ) if `touse' & `_USE'==1
			qui replace `_seES' = . if `_seES'==0 & `touse' & `_USE'==1
		}
		else {
			if "`summstat'"=="ftukey" {
				qui replace `_ES' = asin(sqrt(`succ' / (`_NN' + 1 ))) + asin(sqrt((`succ' + 1 ) / (`_NN' + 1 ))) if `touse' & `_USE'==1
				qui replace `_seES' = 1 / sqrt(`_NN' + .5) if `touse' & `_USE'==1
			}
			else if "`summstat'"=="arcsine" {
				qui replace `_ES' = asin(sqrt(`succ' / `_NN')) if `touse' & `_USE'==1
				qui replace `_seES' = 1 / sqrt(4 * `_NN') if `touse' & `_USE'==1
			}
			else if "`summstat'"=="logit" {
				qui replace `_ES' = logit(`succ_cc' / (`succ_cc' + `fail_cc')) if `touse' & `_USE'==1
				qui replace `_seES' = sqrt((1/`succ_cc') + (1/(`fail_cc'))) if `touse' & `_USE'==1
				qui replace `_seES' = . if `_seES'==0 & `touse' & `_USE'==1
			}
		}
	}

	
	** Otherwise, expect `params' to be 4 or 6
	else {
	
		** Generate effect size vars
		// (N.B. gen as tempvars for now, to accommodate inverse-variance;
		//       but will be renamed to permanent variables later if appropriate)
		
		// Binary outcome (OR, RR, RD)
		if `params' == 4 {
			
			// assert inlist("`summstat'", "or", "rr", "irr", "rrr", "rd")
			// MODIFIED APR 2019 FOR v3.3: REMOVE REFERENCE TO IRR
			assert inlist("`summstat'", "or", "rr", "rrr", "rd")
			args e1 f1 e0 f0		// events & non-events in trt; events & non-events in control (aka a b c d)

			tempvar r1 r0
			local type = cond("`integer'"=="", "long", "double")
			qui gen `type' `r1' = `e1' + `f1'		// total in trt arm (aka a + b)
			qui gen `type' `r0' = `e0' + `f0'		// total in control arm (aka c + d)
			qui replace   `_NN' = `r1' + `r0'		// overall total
			
			// Continuity correction: already prepared by ParseModel
			if `"`cc'"'!=`""' {
				local 0 `"`cc'"'
				syntax [anything(name=ccval id="value supplied to {bf:cc()}")] ///
					[, ALLifzero OPPosite EMPirical MHUNCORR /* Internal option only */ ]
				cap confirm numeric variable `ccvar'
				local genreplace = cond(_rc, "gen byte", "replace")
				qui `genreplace' `ccvar' = `e1'*`f1'*`e0'*`f0'==0
				summ `ccvar', meanonly
				local nz = r(sum)
				if !`nz' local cc		// ... if continuity correction is *applicable*
				else {					// (N.B. from now on, -confirm numeric var `ccvar'- will be used to check if cc was applied)
						
					// Sweeting's "opposite treatment arm" correction
					if `"`opposite'"'!=`""' {
						tempvar cc1 cc0
						qui gen `cc1' = 2*`ccval'*`r1' / (`r1' + `r0')
						qui gen `cc0' = 2*`ccval'*`r0' / (`r1' + `r0')
					}
					
					// Empirical correction
					// (N.B. needs estimate of theta using trials without zero cells)
					else if `"`empirical'"'!=`""' {
						
						// common-effect models only
						if !inlist("`model'", "iv", "peto", "mh", "mu") {
							nois disp as err "Empirical continuity correction only valid under common-effect models"
							exit 184
						}
						
						// more than one study without zero counts needed to estimate "prior"
						qui count if `touse' & `_USE'==1
						if r(N) == `nz' {
							nois disp as err "Insufficient data to implement empirical continuity correction"
							exit 498
						}

						tempvar R cc1 cc0
						qui metan `e1' `f1' `e0' `f0' if `touse' & `_USE'==1, model(`model') `summstat' nocc nograph notable nohet
						qui gen `R' = `r0'/`r1'
						qui gen `cc1' = 2*`ccval'*exp(r(eff))/(`R' + exp(r(eff)))
						qui gen `cc0' = 2*`ccval'*`R'        /(`R' + exp(r(eff)))
						drop `R'
					}
					else {
						local cc1 = `ccval'
						local cc0 = `ccval'
					}
				
					tokenize `cclist'
					args e1_cc f1_cc e0_cc f0_cc
					
					if "`allifzero'"!="" {
						qui gen double `e1_cc' = `e1' + `cc1'
						qui gen double `f1_cc' = `f1' + `cc1'
						qui gen double `e0_cc' = `e0' + `cc0'
						qui gen double `f0_cc' = `f0' + `cc0'
					}
					else {
						qui gen double `e1_cc' = cond(`ccvar', `e1' + `cc1', `e1')
						qui gen double `f1_cc' = cond(`ccvar', `f1' + `cc1', `f1')
						qui gen double `e0_cc' = cond(`ccvar', `e0' + `cc0', `e0')
						qui gen double `f0_cc' = cond(`ccvar', `f0' + `cc0', `f0')
					}
					
					tempvar r1_cc r0_cc t_cc
					qui gen double `r1_cc' = `e1_cc' + `f1_cc'
					qui gen double `r0_cc' = `e0_cc' + `f0_cc'
					qui gen double  `t_cc' = `r1_cc' + `r0_cc'
					
					if `"`opposite'`empirical'"' != `""' {
						drop `cc1' `cc0'		// tidy up
					}
				}
			}
			if `"`cc'"'==`""' {
				local e1_cc `e1'
				local f1_cc `f1'
				local e0_cc `e0'
				local f0_cc `f0'
				local r1_cc `r1'
				local r0_cc `r0'
				local t_cc `_NN'
			}
			
			
			** Now branch by outcome measure
			tokenize `tvlist'
			if "`summstat'"=="or" {
			
				if `: word count `tvlist'' == 2 args oe va		// i.e. chi2opt (incl. Peto), but *not* M-H
				else args r s pr ps qr qs oe va					// M-H, and optionally also chi2opt
			
				if inlist("`teststat'", "chi2", "cmh") | "`model'"=="peto" {
					tempvar c1 c0 ea
					local a `e1'									// synonym; makes it easier to read code involving chi2
					qui gen `type' `c1' = `e1' + `e0'				// total events (aka a + c)
					qui gen `type' `c0' = `f1' + `f0'				// total non-events (aka b + d)
					qui gen double `ea' = (`r1'*`c1')/ `_NN'		// expected events in trt arm, i.e. E(a) where a = e1
					qui gen double `va' = `r1'*`r0'*`c1'*`c0'/( `_NN'*`_NN'*(`_NN' - 1))	// V(a) where a = e1
					qui gen double `oe' = `a' - `ea'										// O - E = a - E(a) where a = e1
					
					sreturn local oevlist `oe' `va'
					
					// Peto method
					if "`model'"=="peto" {
						qui replace `_ES'   = `oe'/`va'    if `touse' & `_USE'==1		// log(Peto OR)
						qui replace `_seES' = 1/sqrt(`va') if `touse' & `_USE'==1		// selogOR
					}
				}

				if "`model'"!="peto" {
				
					// M-H or I-V method
					tempvar v
					if "`model'"!="mh" {	// r and s already exist if "mh", as they are needed for pooling
						tempvar r s
					}

					// calculate individual ORs and variances using cc-adjusted counts
					// (on the linear scale, i.e. logOR)
					qui gen double `r' = `e1_cc' * `f0_cc' / `t_cc'
					qui gen double `s' = `f1_cc' * `e0_cc' / `t_cc'
					qui gen double `v' = 1/`e1_cc' + 1/`f1_cc' + 1/`e0_cc' + 1/`f0_cc'
					
					qui replace `_ES'   = ln(`r'/`s') if `touse' & `_USE'==1
					qui replace `_seES' = sqrt(`v')   if `touse' & `_USE'==1
					
					// setup for Mantel-Haenszel method
					if "`model'"=="mh" {
						tempvar p q
						
						if `nz' & "`mhuncorr'"!="" {						// default; uncorrected
							// first, check for zero total R or S, as this means that zero correction is unavoidable ("mhallzero")
							tempvar r2 s2
							local mhallzero = 0
							qui gen double `r2' = `e1' * `f0' / `_NN'		// this is uncorrected `r'
							summ `r2' if `touse', meanonly
							if r(N) & !r(sum) local mhallzero = 1

							qui gen double `s2' = `f1' * `e0' / `_NN'		// this is uncorrected `s'
							summ `s2' if `touse', meanonly
							if r(N) & !r(sum) local mhallzero = 1

							if `mhallzero' & `ccval' {
								c_local mhallzero mhallzero					// notify PerformMetaAnalysis
								sreturn local invlist `e1_cc' `f1_cc' `e0_cc' `f0_cc'
								
								qui gen double `p' = (`e1_cc' + `f0_cc') / `t_cc'
								qui gen double `q' = (`f1_cc' + `e0_cc') / `t_cc'
							}
							else {
								qui drop `r' `s'
								qui rename `r2' `r'
								qui rename `s2' `s'								
								qui gen double `p' = (`e1' + `f0') / `_NN'
								qui gen double `q' = (`f1' + `e0') / `_NN'
								
								// weights: pass to wgt() option, which is otherwise not valid with MH
								qui gen double `wgt' = `s'
							}
						}
						else {					// optional; continuity-corrected MH
							qui gen double `p' = (`e1_cc' + `f0_cc') / `t_cc'
							qui gen double `q' = (`f1_cc' + `e0_cc') / `t_cc'
						}						
						qui gen double `pr' = `p'*`r'
						qui gen double `ps' = `p'*`s'
						qui gen double `qr' = `q'*`r'
						qui gen double `qs' = `q'*`s'

						sreturn local mhvlist `r' `s' `pr' `ps' `qr' `qs'		// for M-H pooling
					}
				}
			} 		/* end OR */

			// setup for RR/IRR/RRR
			// else if inlist("`summstat'", "rr", "irr", "rrr") {
			// MODIFIED APR 2019 FOR v3.3: REMOVE REFERENCE TO IRR
			else if inlist("`summstat'", "rr", "rrr") {
				args r s p
				tempvar v
				
				qui gen double `r' = `e1_cc'*`r0_cc' / `t_cc'
				qui gen double `s' = `e0_cc'*`r1_cc' / `t_cc'
				qui gen double `v' = 1/`e1_cc' + 1/`e0_cc' - 1/`r1_cc' - 1/`r0_cc'
				qui replace `_ES'   = ln(`r'/`s') if `touse' & `_USE'==1		// logRR 
				qui replace `_seES' = sqrt(`v')   if `touse' & `_USE'==1		// selogRR

				// setup for Mantel-Haenszel method
				if "`model'"=="mh" {
					
					if `nz' & "`mhuncorr'"!="" {						// default; uncorrected
						// first, check for zero total R or S, as this means that zero correction is unavoidable ("mhallzero")
						tempvar r2 s2
						local mhallzero = 0
						qui gen double `r2' = `e1' * `r0' / `_NN'		// this is uncorrected `r'
						summ `r2' if `touse', meanonly
						if r(N) & !r(sum) local mhallzero = 1
						
						qui gen double `s2' = `e1' * `r0' / `_NN'		// this is uncorrected `s'
						summ `s2' if `touse', meanonly
						if r(N) & !r(sum) local mhallzero = 1

						if `mhallzero' & `ccval' {
							c_local mhallzero mhallzero					// notify PerformMetaAnalysis
							
							qui gen double `p' = `r1_cc'*`r0_cc'*(`e1_cc' + `e0_cc')/(`t_cc'*`t_cc') - `e1_cc'*`e0_cc'/`t_cc'
						}
						else {
							drop `r' `s'
							qui rename `r2' `r'
							qui rename `s2' `s'
							qui gen double `p' = `r1'*`r0'*(`e1' + `e0')/(`_NN'*`_NN') - `e1'*`e0'/`_NN'
							
							// weights: pass to wgt() option, which is otherwise not valid with MH
							qui gen double `wgt' = `s'
						}
					}
					else {					// optional; continuity-corrected MH
						qui gen double `p' = `r1_cc'*`r0_cc'*(`e1_cc' + `e0_cc')/(`t_cc'*`t_cc') - `e1_cc'*`e0_cc'/`t_cc'
					}
					
					sreturn local mhvlist `tvlist'							// for M-H pooling
				}
			}
			
			// setup for RD
			else if "`summstat'" == "rd" {
				args rdwt rdnum vnum
				tempvar v
				
				// N.B. `_ES' is calculated *without* cc adjustment, to ensure 0/n1 vs 0/n2 really *is* RD=0
				qui gen double `v'  = `e1_cc'*`f1_cc'/(`r1_cc'^3) + `e0_cc'*`f0_cc'/(`r0_cc'^3)
				qui replace `_ES'   = `e1'/`r1' - `e0'/`r0' if `touse' & `_USE'==1
				qui replace `_seES' = sqrt(`v')             if `touse' & `_USE'==1

				// setup for Mantel-Haenszel method
				// Note: no need to consider `mhuncorr' here, as RD can always be calculated
				// Use x_cc, where cc is either 0 (default) or not (user-specified)
				if "`model'"=="mh" {
					qui gen double `rdwt'  = `r1_cc'*`r1_cc' / `t_cc'
					qui gen double `rdnum' = (`e1_cc'*`r0_cc' - `e0_cc'*`r1_cc') / `t_cc'
					qui gen double `vnum'  = (`e1_cc'*`f1_cc'*(`r0_cc'^3) + `e0_cc'*`f0_cc'*(`r1_cc'^3)) / (`r1_cc'*`r0_cc'*`t_cc'*`t_cc')

					sreturn local mhvlist `tvlist'					// for M-H pooling
				}
			}		// end "rd"
		}		// end if `params' == 4
		
		else {
		
			cap assert `params' == 6
			if _rc {
				nois disp as err `"Invalid {it:varlist}"'
				exit 198
			}
		
			// N mean SD for continuous outcome data
			assert inlist("`summstat'", "wmd", "cohend", "glassd", "hedgesg")
			args n1 mean1 sd1 n0 mean0 sd0

			qui replace `_NN' = `n1' + `n0' if `touse'
				
			if "`summstat'" == "wmd" {
				qui replace `_ES'   = `mean1' - `mean0'                     if `touse' & `_USE'==1
				qui replace `_seES' = sqrt((`sd1'^2)/`n1' + (`sd0'^2)/`n0') if `touse' & `_USE'==1
			}
			else {				// summstat = SMD
				tempvar s
				qui gen double `s' = sqrt( ((`n1'-1)*(`sd1'^2) + (`n0'-1)*(`sd0'^2) )/( `_NN' - 2) )

				if "`summstat'" == "cohend" {
					qui replace `_ES'   = (`mean1' - `mean0')/`s'                                      if `touse' & `_USE'==1
					qui replace `_seES' = sqrt((`_NN' /(`n1'*`n0')) + (`_ES'*`_ES'/ (2*(`_NN' - 2)) )) if `touse' & `_USE'==1
				}
				else if "`summstat'" == "glassd" {
					qui replace `_ES'   = (`mean1' - `mean0')/`sd0'                                    if `touse' & `_USE'==1
					qui replace `_seES' = sqrt(( `_NN' /(`n1'*`n0')) + (`_ES'*`_ES'/ (2*(`n0' - 1)) )) if `touse' & `_USE'==1
				}
				else if "`summstat'" == "hedgesg" {
					qui replace `_ES'   = (`mean1' - `mean0')*(1 - 3/(4*`_NN' - 9))/`s'                    if `touse' & `_USE'==1
					qui replace `_seES' = sqrt(( `_NN' /(`n1'*`n0')) + (`_ES'*`_ES'/ (2*(`_NN' - 3.94)) )) if `touse' & `_USE'==1
				}
			}			
		}		// end else (i.e. if `params' == 6)
	}		// end if `params' > 3
	
end




***************************************************************

** Extra loop for cumulative/influence meta-analysis
// - If cumulative, loop over observations one by one
// - If influence, exclude observations one by one

program define CumInfLoop, rclass

	syntax varlist(numeric min=3 max=7) [if] [in], SORTBY(varname numeric) ///
		MODEL(passthru) XOUTVLIST(varlist numeric) ///
		[CUmulative INFluence OVWt SGWt ROWNAMES(namelist) * ]
	
	marksample touse, novarlist
	gettoken _USE varlist : varlist
		
	local npts_el npts
	local xrownames : list rownames - npts_el
	local xrownames `xrownames' Q Qdf Q_lci Q_uci
	if `: list posof "tausq" in rownames' local xrownames `xrownames' sigmasq
	
	tokenize `xoutvlist'
	args `xrownames' _WT2

	// return name of `_WT2' in `xoutvlist'
	return local xwt `_WT2'

	// Added Jan 2020, amended Mar 2020
	// If only one study, return `nsg' to prompt error message later...
	qui count if `touse'
	if !r(N) exit 2000
	if r(N)==1 c_local nsg = 1
	local n = r(N)
	assert `_USE'==1 if `touse'

	// ...and if `influence', exit subroutine early
	// (since we cannot look at the influence of removing the *only* study!)
	if `"`influence'"'!=`""' & (`"`sgwt'`ovwt'"'==`""' | r(N)==1) {
		//if r(N)==1 qui replace `_USE' = 2 if `touse'
		exit
	}	
	
	// N.B. if `cumulative', last analysis will be done separately, by PerformMetaAnalysis
	// Therefore, if `n'=1 then `jmax'==0 and loop below is skipped
	local jmax = `n' - (`"`cumulative'"'!=`""')
	local jmin = cond(`"`sgwt'`ovwt'"'!=`""', 1, `jmax')
	
	tempvar touse2
	forvalues j = `jmin'/`jmax' {

		// Define `touse' for *input* (i.e. which obs to meta-analyse)
		if `"`cumulative'"'!=`""' qui gen byte `touse2' = `touse' * inrange(`sortby', 1, `j')		// cumulative: obs from 1 to `j'-1
		else                      qui gen byte `touse2' = `touse' * (`sortby' != `j')				// influence: all obs except `j'

		cap nois PerformPooling `varlist' if `touse2', `model' `options'

		if _rc {
			if _rc==1 nois disp as err `"User break in {bf:metan.PerformPooling}"'
			else nois disp as err `"Error in {bf:metan.PerformPooling}"'
			c_local err noerr		// tell -metan- not to also report an "error in metan.CumInfLoop"
			exit _rc
		}
	
		// pooling failed (may not have caused an actual error)
		if missing(r(eff), r(se_eff), r(totwt)) exit 2002
		
		
		** Store statistics returned by PerformPooling in the dataset
		// Same statistics as in `rownames', plus (non-normalised) weights
		
		// First, re-define `touse2' for *output* (i.e. where to store the results of the meta-analysis)
		qui replace `touse2' = `touse' * (`sortby'==`j')

		// Store (non-normalised) weight in the dataset
		qui replace `_WT2' = r(totwt) if `touse2'
		
		// Store other returned statistics in the dataset
		foreach el of local xrownames {
			qui replace ``el'' = r(`el') if `touse2'
		}
		
		drop `touse2'	// tidying up

	}		// end forvalues j=`jmin'/`jmax'
		
	// Check consistency of numbers of *studies*
	if `n' > 1 {					// if `n'<=1 then r(k) will not have been returned
		assert `n' - 1 == r(k)		// number of studies will be one less than true number, due to how this subroutine works
	}

end





*******************************************************************
	
* PerformPooling
// subroutine of PerformMetaAnalysis

// This routine actually performs the pooling itself.
// non-IV calculations are done in Stata (partly using code taken from metan.ado by Ross Harris et al);
//   iterative IV analyses are done in Mata.

// N.B. study-level results _ES, _seES, _LCI, _UCI are assumed *always* to be on the linear scale (i.e. logOR etc.)
// as this makes building the forestplot easier, and keeps things simple in general.
// For non-IV 2x2 count data, however, the exponentiated effect size may also be returned, e.g. r(OR), r(RR).

program define PerformPooling, rclass
	
	syntax varlist [if] [in], MODEL(name) [*]
	
	local nrfd = 0		// initialize marker of "less than 3 studies" (for rfdist)
	local nsg  = 0		// initialize marker of "only a single valid estimate" (e.g. for by(), or cumul/infl)
	local nzt  = 0		// initialize marker of "HKSJ has resulted in a shorter CI than IV" (for HKSJ)	
	
	marksample touse, novarlist		// in case of binary 2x2 data with no cases in one or both arms; this will be dealt with later
	qui count if `touse'
	if !r(N) {
		nois disp as err "no observations"
		exit 2000
	}
	
	cap nois {
		if "`model'"=="mh" PerformPoolingMH `0'
		else {
			
			// Nov 2020: fork depending on whether v16.1+ or not
			// If v16.1+, use pre-complied Mata library; otherwise use on-the-fly Mata code
			local v161 = 0
			if "`c(stata_version)'"!="" {
				if c(stata_version) >= 16.1 local v161 = 1
			}
			if `v161' PerformPoolingIV `0'
			else metan_pooling `0'
		}
	}
	if _rc {
		c_local err noerr		// tell -metan- not to also report an "error in metan.PerformPooling"
		if "`model'"=="mh" return add
		exit _rc
	}
	
	c_local nrfd  = `nrfd'		// update marker of "less than 3 studies" (for rfdist)
	c_local nsg   = `nsg'		// update marker of "only a single valid estimate" (e.g. for by(), or cumul/infl)
	c_local nzt   = `nzt'		// update marker of "HKSJ has resulted in a shorter CI than IV" (for HKSJ)

	return add
	
end



// Inverse variance (i.e. all except Mantel-Haenszel)
program define PerformPoolingIV, rclass

	syntax varlist(numeric min=2 max=2) [if] [in], MODEL(name) ///
		[SUMMSTAT(name) TESTSTAT(name) QSTAT(passthru) TESTBased ISQParam ///
		OEVLIST(varlist numeric min=2 max=2) INVLIST(varlist numeric min=2 max=6) ///
		NPTS(varname numeric) WGT(varname numeric) WTVAR(varname numeric) ///
		HKsj KRoger BArtlett SKovgaard RObust LOGRank PRoportion TN(string) /*noTRUNCate*/ TRUNCate(string) EIM OIM ///
		ISQSA(real 80) TSQSA(real -99) QWT(varname numeric) INIT(name) OLevel(cilevel) HLevel(cilevel) RFLevel(cilevel) ///
		ITOL(real 1.0x-1a) MAXTausq(real -9) REPS(real 1000) MAXITer(real 1000) QUADPTS(real 100) DIFficult TECHnique(string) * ]

	// N.B. extra options should just be those allowed for PerformPoolingMH

	marksample touse			// note: *NO* "novarlist" option here
	local pvlist `varlist'		// for clarity
	
	// if no wtvar, gen as tempvar
	if `"`wtvar'"'==`""' {
		local wtvar
		tempvar wtvar
		qui gen `wtvar' = .
	}	
	
	// Firstly, check whether only one study
	//   if so, cancel random-effects and set to defaults: iv, cochranq, testbased
	// t-critval ==> es, se, lci, uci returned but nothing else
	tempname k	
	qui count if `touse'
	scalar `k' = r(N)
	if `k' == 1 {
		if "`model'"!="peto" {
			local model iv
			local isqparam
		}
		if "`teststat'"!="z" local teststat z
		local hksj
		c_local nsg = 1
	}

	
	** Chi-squared test (OR only; includes Peto OR) or logrank HR
	if "`oevlist'"!="" {
		tokenize `oevlist'
		args oe va

		tempname OE VA chi2
		summ `oe' if `touse', meanonly
		scalar `OE' = cond(r(N), r(sum), .)
		summ `va' if `touse', meanonly
		scalar `VA' = cond(r(N), r(sum), .)
		scalar `chi2' = (`OE'^2 )/`VA'

		if "`model'"=="peto" | "`logrank'"!="" {
			return scalar OE = `OE'
			return scalar V = `VA'
		}
	}


	*************************************
	* Standard inverse-variance methods *
	*************************************
	
	tokenize `pvlist'
	args _ES _seES
		
	tempname eff se_eff crit pvalue
	qui replace `wtvar' = 1/`_seES'^2 if `touse'
	summ `_ES' [aw=`wtvar'] if `touse', meanonly
	scalar `eff' = r(mean)
	scalar `se_eff' = 1/sqrt(r(sum_w))		// I-V common-effect SE

	// Derive Cochran's Q
	tempvar qhet
	qui gen double `qhet' = `wtvar'*((`_ES' - `eff')^2)
	summ `qhet' if `touse', meanonly

	tempname Q Qdf
	scalar `Q'   = cond(r(N), r(sum), .)
	scalar `Qdf' = cond(r(N), r(N)-1, .)
	
	// Derive sigmasq and tausq
	tempname c sigmasq tausq
	summ `wtvar' [aw=`wtvar'] if `touse', meanonly
	scalar `c' = r(sum_w) - r(mean)
	scalar `sigmasq' = `Qdf'/`c'						// [general note: can this be generalised to other (non-IV) methods?]
	scalar `tausq' = max(0, (`Q' - `Qdf')/`c')			// default: D+L estimator



	**********************************
	* Non-iterative tausq estimators *
	**********************************
	// (other than D+L, already derived above)
	
	** Setup two-stage estimators sj2s and dk2s
	// consider *initial* estimate of tsq
	if inlist("`model'", "sj2s", "dk2s") {
		local final `model'
		local model `"`init'"'
		
		if substr(trim(`"`model'"'), 1, 2)==`"sa"' {
			tempname tausq0
			scalar `tausq0' = `tausq'
		
			_parse comma model 0 : model
			syntax [, ISQ(string) TAUSQ(string)]
			
			if `"`tausq'"'!=`""' & `"`isq'"'==`""' {
				nois disp as err `"Only one of {bf:isq()} or {bf:tausq()} may be supplied as suboptions to {bf:sa()}"'
				exit 184
			}
		
			else if `"`tausq'"'!=`""' {
				cap confirm number `tausq'
				if _rc {
					nois disp as err `"Error in {bf:tausq()} suboption to {bf:sa()}; a single number was expected"'
					exit _rc
				}
				if `tausq' < 0 {
					nois disp as err `"tau{c 178} value for sensitivity analysis cannot be negative"'
					exit 198
				}
				local tsqsa = `tausq'
				local isqsa
			}
			else {
				if `"`isq'"'==`""' local isq = 80
				else {
					cap confirm number `isq'
					if _rc {
						nois disp as err `"Error in {bf:isq()} suboption to {bf:sa()}; a single number was expected"'
						exit _rc
					}
					if `isq'<0 | `isq'>=100 {
						nois disp as err `"I{c 178} value for sensitivity analysis must be at least 0% and less than 100%"'
						exit 198
					}
				}
				local isqsa = `isq'
				local tsqsa = -99
			}

			scalar `tausq' = `tausq0'
		}
	}
	
	** Hartung-Makambi estimator (>0)
	if "`model'"=="hm" {
		scalar `tausq' = `Q'^2 / (`c'*(`Q' + 2*`Qdf'))
	}
	
	** Non-iterative, making use of the sampling variance of _ES
	else if inlist("`model'", "ev", "he", "b0", "bp") {
		tempname var_eff meanv
		qui summ `_ES' if `touse'
		scalar `var_eff' = r(Var)

		tempvar v
		qui gen double `v' = `_seES'^2
		summ `v' if `touse', meanonly
		scalar `meanv' = r(mean)
		
		// empirical variance (>0)
		if "`model'"=="ev" {
			tempvar residsq
			qui gen double `residsq' = (`_ES' - r(mean))^2
			summ `residsq', meanonly
			scalar `tausq' = r(mean)
		}
		
		// Hedges aka "variance component" aka Cochran ANOVA-type estimator
		else if "`model'"=="he" {
			scalar `tausq' = `var_eff' - `meanv'
		}
		
		// Rukhin Bayes estimators
		else if inlist("`model'", "b0", "bp") {
			scalar `tausq' = `var_eff'*(`k' - 1)/(`k' + 1)
			if "`model'"=="b0" {
				summ `npts' if `touse', meanonly	
				scalar `tausq' = `tausq' - ( (`r(sum)' - `k')*`Qdf'*`meanv'/((`k' + 1)*(`r(sum)' - `k' + 2)) )
			}
		}
		scalar `tausq' = max(0, `tausq')			// truncate at zero
	}
	
	// Sensitivity analysis: use given Isq/tausq and sigmasq to generate tausq/Isq
	else if "`model'"=="sa" {
		if `tsqsa'==-99 scalar `tausq' = `isqsa'*`sigmasq'/(100 - `isqsa')
		else scalar `tausq' = `tsqsa'
	}



	******************************
	* Iterative tausq estimators *
	******************************
	
	// Check validity of iteropts
	cap assert (`maxtausq'>=0 & !missing(`maxtausq')) | `maxtausq'==-9
	if _rc {
		nois disp as err "maxtausq() cannot be negative"
		exit 198
	}			
	cap assert `itol'>=0 & !missing(`itol')
	if _rc {
		nois disp as err "itol() cannot be negative"
		exit 198
	}
	cap {
		assert (`maxiter'>0 & !missing(`maxiter'))
		assert round(`maxiter')==`maxiter'
	}
	if _rc {
		nois disp as err "maxiter() must be an integer greater than zero"
		exit 198
	}

	// maxtausq: use 10*`tausq' if not specified
	// (and 10 times that for uci -- done in Mata)
	local maxtausq = cond(`maxtausq'==-9, max(10*`tausq', 100), `maxtausq')
		
	// Iterative, using Mata
	if inlist("`model'", "dlb", "mp", "ml", "pl", "reml") {
	
		// Bootstrap D+L
		// (Kontopantelis PLoS ONE 2013)
		if "`model'"=="dlb" {
			cap {
				assert (`reps'>0 & !missing(`reps'))
				assert round(`reps')==`reps'
			}
			if _rc {
				nois disp as err "reps() must be an integer greater than zero"
				exit 198
			}
			cap nois mata: DLb("`_ES' `_seES'", "`touse'", `olevel', `reps')
		}
		
		// Mandel-Paule aka empirical Bayes
		// (DerSimonian and Kacker CCT 2007)
		// N.B. Mata routine also performs the Viechtbauer Q-profiling routine for tausq CI
		// (Viechtbauer Stat Med 2007; 26: 37-52)
		else if "`model'"=="mp" {
			cap nois mata: GenQ("`_ES' `_seES'", "`touse'", `hlevel', (`maxtausq', `itol', `maxiter'))
		}
		
		// REML
		// N.B. Mata routine also performs likelihood profiling to give tausq CI
		else if "`model'"=="reml" {
			local hmethod = cond("`difficult'"!="", "hybrid", "m-marquardt")	// default = m-marquardt
			if "`technique'"=="" local technique nr								// default = nr
			cap nois mata: REML("`_ES' `_seES'", "`touse'", `hlevel', (`maxtausq', `itol', `maxiter'), "`hmethod'", "`technique'")
			return scalar converged = r(converged)
			return scalar tsq_var = r(tsq_var)
			return scalar ll = r(ll)
		}
		
		// ML, including Profile Likelihood
		// with optional Bartlett's (Huizenga Br J Math Stat Psychol 2011) or Skovgaard's (Guolo Stat Med 2012) correction to the likelihood
		// N.B. Mata routine also performs likelihood profiling to give tausq CI
		else if inlist("`model'", "ml", "pl") {
			local mlpl `model'
			if "`bartlett'"!="" local mlpl plbart
			else if "`skovgaard'"!="" local mlpl plskov
			local hmethod = cond("`difficult'"!="", "hybrid", "m-marquardt")	// default = m-marquardt
			if "`technique'"=="" local technique nr								// default = nr
			cap nois mata: MLPL("`_ES' `_seES'", "`touse'", (`olevel', `hlevel'), (`maxtausq', `itol', `maxiter'), "`hmethod'", "`technique'", "`mlpl'")			
			return scalar converged = r(converged)
			return scalar tsq_var = r(tsq_var)
			return scalar ll = r(ll)

			if "`model'"=="pl" {
				return scalar eff_lci = r(eff_lci)
				return scalar eff_uci = r(eff_uci)
				return scalar rc_eff_lci = r(rc_eff_lci)
				return scalar rc_eff_uci = r(rc_eff_uci)
				
				// Need to store these as scalars, in order to calculate critical values
				tempname chi2 z
				scalar `chi2' = r(lr)			// Likelihood ratio test statistic
				scalar `z'    = r(sll)			// Signed log-likelihood test statistic

				if "`teststat'"=="chi2" return scalar chi2 = r(lr)		// Bartlett's correction to the likelihood
				else                    return scalar z    = r(sll)		// Skovgaard's correction to the likelihood
			}
		}
		
		if _rc {
			if _rc==1 exit _rc				// User break
			else if _rc==2000 exit _rc		// No studies found with sufficient data to be analysed
			else if _rc>=3000 {
				nois disp as err "Mata compile-time or run-time error"
				exit _rc
			}
			else if _rc disp `"{error}Error(s) detected during running of Mata code; please check output"'
		}

		scalar `tausq' = r(tausq)

		// check tausq limits and set to missing if necessary
		tempname tsq_lci tsq_uci
		scalar `tsq_lci' = r(tsq_lci)
		scalar `tsq_uci' = r(tsq_uci)
		if "`model'"!="dlb" {
			scalar `tsq_lci' = cond(r(rc_tsq_lci)>1 & r(tsq_lci)!=0, ., r(tsq_lci))
			scalar `tsq_uci' = cond(r(rc_tsq_uci)>1, ., r(tsq_uci))
		}
		
		// return extra scalars
		return scalar maxtausq = `maxtausq'
		return scalar tsq_lci  = `tsq_lci'
		return scalar tsq_uci  = `tsq_uci'
		return scalar rc_tausq   = r(rc_tausq)
		return scalar rc_tsq_lci = r(rc_tsq_lci)
		return scalar rc_tsq_uci = r(rc_tsq_uci)
		
	}	// end if inlist("`model'", "dlb", "mp", "ml", "pl", "reml")
		// [i.e. iterative tausq estimators]
	
	
	// SEP 2020: Remove this option.  If MP CI is desired, the entire MP model can be run.
	// (Doesn't affect forestplot, so why is it needed?  just makes options more complicated)
	/*
	// Viechtbauer Q-profiling routine for tausq CI, if *not* Mandel-Paule tsq estimator
	// (Viechtbauer Stat Med 2007; 26: 37-52)
	if "`hetci'"=="qprofile" & "`model'"!="mp" {
		cap nois mata: GenQ("`_ES' `_seES'", "`touse'", `hlevel', (`maxtausq', `itol', `maxiter'))
		
		if _rc {
			if _rc==1 exit _rc				// User break
			else if _rc==2000 exit _rc		// No studies found with sufficient data to be analysed
			else if _rc>=3000 {
				nois disp as err "Mata compile-time or run-time error"
				exit _rc
			}
			else if _rc disp `"{error}Error(s) detected during running of Mata code; please check output"'
		}				
	
		tempname tsq_lci tsq_uci
		scalar `tsq_lci' = cond(r(rc_tsq_lci)>1 & r(tsq_lci)!=0, ., r(tsq_lci))
		scalar `tsq_uci' = cond(r(rc_tsq_uci)>1, ., r(tsq_uci))
		
		// return extra scalars
		return scalar tsq_lci  = `tsq_lci'
		return scalar tsq_uci  = `tsq_uci'
		return scalar rc_tsq_lci = r(rc_tsq_lci)
		return scalar rc_tsq_uci = r(rc_tsq_uci)
	
	}
	*/
	// end of "Iterative, using Mata" section



	******************************************************
	* User-defined weights; finalise two-step estimators *
	******************************************************

	if `"`wgt'"'!=`""' {
		qui replace `wtvar' = `wgt' if `touse'
	}
	
	tempname Qr				// will also be used for post-hoc variance correction
	if "`final'"!="" {		
		qui replace `qhet' = ((`_ES' - `eff')^2)/((`_seES'^2) + `tausq')
		summ `qhet' if `touse', meanonly
		scalar `Qr' = r(sum)
		
		if "`final'"=="sj2s" {					// two-step Sidik-Jonkman
			// scalar `tausq' = cond(`tausq'==0, `sigmasq'/99, `tausq') * `Qr'/`Qdf'		// March 2018: if tsq=0, use Isq=1%
			scalar `tausq' = `tausq' * `Qr'/`Qdf'
			
			/*
			// Sidik-Jonkman's suggested confidence interval for tausq; not recommended for use
			tempname tsq_lci tsq_uci
			scalar `tsq_lci' = `tausq' * `Qdf' / invchi2(`Qdf', .5 - `hlevel'/200)
			scalar `tsq_uci' = `tausq' * `Qdf' / invchi2(`Qdf', .5 + `hlevel'/200)
			*/
		}
		else if "`final'"=="dk2s" {				// two-step DerSimonian-Kacker (MM only)
			tempname wi1 wi2 wis1 wis2 
			summ `wtvar' if `touse', meanonly
			scalar `wi1' = r(sum)				// sum of weights
			summ `wtvar' [aw=`wtvar'] if `touse', meanonly
			scalar `wi2' = r(sum)				// sum of squared weights				
			summ `wtvar' [aw=`_seES'^2] if `touse', meanonly
			scalar `wis1' = r(sum)				// sum of weight * variance
			summ `wtvar' [aw=`wtvar' * (`_seES'^2)] if `touse', meanonly
			scalar `wis2' = r(sum)				// sum of squared weight * variance
			
			scalar `tausq' = (`Qr' - (`wis1' - `wis2'/`wi1')) / (`wi1' - `wi2'/`wi1')
			scalar `tausq' = max(0, `tausq')	// truncate at zero
		}
		
		local model `final'		// switch back, so that `model' contains dk2s or sj2s again
	}	



	*********************************
	* Alternative weighting schemes *
	*********************************
	// (not user-defined)
	
	// Quality effects (QE) model (extension of IVhet to incorporate quality scores)
	// (Doi et al, Contemporary Clinical Trials 2015; 45: 123-9)
	if "`model'"=="qe" {
		tempvar newqe tauqe
		
		// re-scale scores relative to highest value
		confirm numeric variable `qwt'
		summ `qwt' if `touse', meanonly
		qui gen double `newqe' = `qwt'/r(max)

		// taui and tauhati
		qui gen double `tauqe' = (1 - `newqe')/(`_seES'*`_seES'*`Qdf')
		summ `tauqe' if `touse', meanonly
		local sumtauqe = r(sum)

		summ `newqe' if `touse', meanonly
		if r(min) < 1 {				// additional correction if any `newqe' are < 1, to avoid neg. weights
			tempvar newqe_adj
			qui gen double `newqe_adj' = `newqe' + r(sum)*`tauqe'/(`sumtauqe'*`Qdf')
			summ `newqe_adj' if `touse', meanonly
			qui replace `tauqe' = (`sumtauqe'*`k'*`newqe_adj'/r(sum)) - `tauqe'
		}
		else qui replace `tauqe' = (`sumtauqe'*`k'*`newqe'/r(sum)) - `tauqe'
		
		// Point estimate uses weights = qi/vi + tauhati
		qui replace `wtvar' = (`newqe'/(`_seES'^2)) + `tauqe' if `touse'
	}
	
	// Biggerstaff and Tweedie approximate Gamma-based weighting
	// (also derives a variance and confidence interval for tausq_DL)
	else if "`model'"=="bt" {
		cap nois mata: BTGamma("`_ES' `_seES'", "`touse'", "`wtvar'", `hlevel', (`maxtausq', `itol', `maxiter', `quadpts'))
		if _rc {
			if _rc==1 exit _rc
			else if _rc>=3000 {
				nois disp as err "Mata compile-time or run-time error"
				exit _rc
			}
			else if _rc disp `"{error}Error(s) detected during running of Mata code; please check output"'
		}
		
		// check tausq limits and set to missing if necessary
		tempname tsq_lci tsq_uci
		scalar `tsq_lci' = r(tsq_lci)
		scalar `tsq_uci' = r(tsq_uci)
		scalar `tsq_lci' = cond(r(rc_tsq_lci)>1 & `tsq_lci'!=0, ., `tsq_lci')
		scalar `tsq_uci' = cond(r(rc_tsq_uci)>1, ., `tsq_uci')
	
		// return extra scalars
		return scalar maxtausq = `maxtausq'
		return scalar rc_tausq = r(rc_tausq)
		return scalar tsq_var = r(tsq_var)
		
		return scalar tsq_lci  = `tsq_lci'
		return scalar tsq_uci  = `tsq_uci'
		return scalar rc_tsq_lci = r(rc_tsq_lci)
		return scalar rc_tsq_uci = r(rc_tsq_uci)
	}
	
	// Henmi and Copas method also belongs here
	//  (Henmi and Copas, Stat Med 2010; DOI: 10.1002/sim.4029)
	// Begins along the same lines as IVhet; that is, a RE model with inv-variance weighting
	//   but goes on to estimate the distribution of pivotal quantity U using a Gamma distribution (c.f. Biggerstaff & Tweedie).
	// `se_eff' is the same as IVhet, but conf. interval around `eff' is different.
	else if "`model'"=="hc" {
		cap nois mata: HC("`_ES' `_seES'", "`touse'", `olevel', (`itol', `maxiter', `quadpts'))
		if _rc {
			if _rc==1 exit _rc
			else if _rc>=3000 {
				nois disp as err "Mata compile-time or run-time error"
				exit _rc
			}
			else if _rc disp `"{error}Error(s) detected during running of Mata code; please check output"'
		}
		
		return scalar u = r(u)
		scalar `crit'   = r(crit)
		scalar `pvalue' = r(p)
	}

	// end of "Alternative weighting schemes" section



	**********************************
	* Generate pooled eff and se_eff *
	**********************************
	
	// Alternative or user-defined weighting
	if `"`wgt'"'!=`""' | inlist("`model'", "ivhet", "qe", "bt", "hc") {

		// Apply weighting
		summ `_ES' [aw=`wtvar'] if `touse', meanonly
		scalar `eff' = r(mean)
		
		// Specify underlying model: IV common-effect, or random-effects with additive heterogeneity
		// (N.B. if *multiplicative* heterogeneity, factor simply multiplies the final pooled variance)
		local vi = cond("`model'"=="iv", "`_seES'^2", "`_seES'^2 + `tausq'")
		
		tempvar wtvce
		summ `wtvar' if `touse', meanonly
		qui gen double `wtvce' = (`vi') * `wtvar'^2 / r(sum)^2
		summ `wtvce' if `touse', meanonly
		scalar `se_eff' = sqrt(r(sum))
		
		// May 2020:
		// Similarly to M-H and Peto methods, re-calculate Q based on standard variance weights
		// but with respect to the *weighted* pooled effect size
		if `"`wgt'"'!=`""' {
			qui replace `qhet' = ((`_ES' - `eff') / `_seES')^2
			summ `qhet' if `touse', meanonly
			scalar `Q' = cond(r(N), r(sum), .)
		}
	}
	
	// Standard weighting based on additive tau-squared
	// (N.B. if iv or mu, eff and se_eff have already been calculated)
	else if !inlist("`model'", "iv", "peto", "mu") {
		qui replace `wtvar' = 1/(`_seES'^2 + `tausq') if `touse'
		summ `_ES' [aw=`wtvar'] if `touse', meanonly
		scalar `eff' = r(mean)
		scalar `se_eff' = 1/sqrt(r(sum_w))
	}
	
	// Return weights for CumInfLoop
	summ `wtvar' if `touse', meanonly
	return scalar totwt = cond(r(N), r(sum), .)		// sum of (non-normalised) weights	


	*********************************
	* Post-hoc variance corrections *
	*********************************

	// First, calculate "generalised" (i.e. random-effects) version of Cochran's Q.
	// Note that the multiplier sqrt(`Q'/`Qdf') is equal to Higgins & Thompson's (Stat Med 2002) `H' statistic
	//  and that van Aert & Jackson (2019) use H* to refer to a "generalised/random-effects" H-statistic, similar to Qr.
	tempname Hstar
	scalar `Qr' = `Q'
	if !inlist("`model'", "iv", "peto", "mu") | "`wgt'"!="" {		// Note: if I-V common-effect (e.g. for "mu"), Qr = Q and Hstar = H
		qui replace `qhet' = `wtvar'*((`_ES' - `eff')^2)
		summ `qhet' if `touse', meanonly
		scalar `Qr' = cond(r(N), r(sum), .)
		return scalar Qr = `Qr'
	}
	scalar `Hstar' = sqrt(`Qr'/`Qdf')
	
	// Multiplicative heterogeneity (e.g. Thompson and Sharp, Stat Med 1999)
	// (equivalent to the "full variance" estimator suggested by Sandercock
	// (https://metasurv.wordpress.com/2013/04/26/
	//    fixed-or-random-effects-how-about-the-full-variance-model-resolving-a-decades-old-bunfight)

	// Hartung-Knapp-Sidik-Jonkman variance estimator
	// (Roever et al, BMC Med Res Methodol 2015; Jackson et al, Stat Med 2017; van Aert & Jackson, Stat Med 2019)

	if "`model'"=="mu" | "`hksj'"!="" {
		tempname tcrit zcrit
		scalar `zcrit' = invnormal(.5 + `olevel'/200)
		scalar `tcrit' = invttail(`Qdf', .5 - `olevel'/200)
		
		// van Aert & Jackson 2019: truncate at z/t
		if `"`truncate'"'==`"zovert"' scalar `Hstar' = max(`zcrit'/`tcrit', `Hstar')
		else {
			if "`hksj'"!="" & `Hstar' < `zcrit'/`tcrit' c_local nzt = 1		// setup error display for later
		
			// (e.g.) Roever 2015: truncate at 1
			// i.e. don't use if *under* dispersion present
			if inlist(`"`truncate'"', `"one"', `"1"') scalar `Hstar' = max(1, `Hstar')
			else if `"`truncate'"'!=`""' {
				nois disp as err `"invalid use of {bf:truncate()} option"'
				exit 184
			}
		}
		scalar `se_eff' = `se_eff' * `Hstar'
	}
	return scalar Hstar = `Hstar'

	// Sidik-Jonkman robust ("sandwich-like") variance estimator
	// (Sidik and Jonkman, Comp Stat Data Analysis 2006)
	// (N.B. HKSJ estimator also described in the same paper)
	else if "`robust'"!="" {
		tempname sumwi
		tempvar vr_part
		summ `wtvar' if `touse', meanonly
		scalar `sumwi' = r(sum)
		qui gen double `vr_part' = `wtvar' * `wtvar' * ((`_ES' - `eff')^2) / (1 - (`wtvar'/`sumwi'))
		summ `vr_part' if `touse', meanonly
		scalar `se_eff' = sqrt(r(sum))/`sumwi'
	}

	// Kenward-Roger variance inflation method
	// (Morris et al, Stat Med 2018)
	else if "`kroger'"!="" {
		tempname wi1 wi2 wi3 nwi2 nwi3
		summ `wtvar' if `touse', meanonly
		scalar `wi1' = r(sum)				// sum of weights
		summ `wtvar' [aw=`wtvar'] if `touse', meanonly
		scalar `wi2' = r(sum)				// sum of squared weights
		summ `wtvar' [aw=`wtvar'^2] if `touse', meanonly
		scalar `wi3' = r(sum)				// sum of cubed weights
		scalar `nwi2' = `wi2'/`wi1'			// "normalised" sum of squared weights [i.e. sum(wi:^2)/sum(wi)]
		scalar `nwi3' = `wi3'/`wi1'			// "normalised" sum of cubed weights [i.e. sum(wi:^3)/sum(wi)]		
		
		// expected information
		tempname I
		scalar `I' = `wi2'/2 - `nwi3' + (`nwi2'^2)/2
		
		// observed information
		if "`oim'"!="" {
			tempvar resid resid2
			tempname q2 q3
			
			qui gen double `resid' = `_ES' - `eff'
			summ `resid' [aw=`wtvar'^2] if `touse', meanonly
			scalar `q2' = r(sum)			// quadratic involving squared weights and residual
			
			qui gen double `resid2' = `resid'^2
			summ `resid2' [aw=`wtvar'^3] if `touse', meanonly
			scalar `q3' = r(sum)			// quadratic involving cubed weights and squared residual
			
			scalar `I' = max(0, (`q2'^2)/`wi1' + `q3' - `I')
		}
		
		// corrected se_eff [sqrt(Phi_A) in Kenward-Roger papers]
		tempname W V
		scalar `W' = 1/`I'		// approximation of var(tausq)
		scalar `V' = (1/`wi1') + 2*`W'*(`wi3' - (`wi2'^2)/`wi1')/(`wi1'^2)
		scalar `se_eff' = sqrt(`V')
		
		// denominator degrees of freedom
		tempname A df_kr
		scalar `A' = `W' * (`V'*`wi2')^2
		scalar `df_kr' = 2 / `A'
		// return scalar df_kr = `df_kr'
	}
	
	// check for successful pooling
	if missing(`eff', `se_eff') exit 2002



	**********************************************
	* Critical values, test statistics, p-values *
	**********************************************
	
	// Predictive intervals
	// (uses k-2 df, c.f. Higgins & Thompson 2009; but also see e.g. http://www.metafor-project.org/doku.php/faq#for_random-effects_models_fitt)
	if `k' < 3 c_local nrfd = 1		// setup error display for later
	else {
		tempname rfcritval rflci rfuci
		scalar `rfcritval' = invttail(`k'-2, .5 - `rflevel'/200)
		scalar `rflci' = `eff' - `rfcritval' * sqrt(`tausq' + `se_eff'^2)
		scalar `rfuci' = `eff' + `rfcritval' * sqrt(`tausq' + `se_eff'^2)
		
		return scalar rflci = `rflci'
		return scalar rfuci = `rfuci'
	}
	
	// Proportions
	if "`proportion'"!="" {
		tempname z eff_lci eff_uci
		scalar `z' = `eff'/`se_eff'
		scalar `crit' = invnormal(.5 + `olevel'/200)
		scalar `pvalue' = 2*normal(-abs(`z'))
		scalar `eff_lci' = `eff' - `crit' * `se_eff'
		scalar `eff_uci' = `eff' + `crit' * `se_eff'

		if "`summstat'"=="ftukey" {
			tokenize `invlist'
			args succ _NN
			
			tempname hmean mintes maxtes prop_eff prop_lci prop_uci
			qui ameans `_NN' if `touse'
			if      "`tn'"=="arithmetic" scalar `hmean' = r(mean)				// Arithmetic mean
			else if "`tn'"=="geometric"  scalar `hmean' = r(mean_g)				// Geometric mean
			else if inlist("`tn'", "", "harmonic") scalar `hmean' = r(mean_h)	// Harmonic mean (Miller 1978; default)
			else if "`tn'"=="ivariance"  scalar `hmean' = 1/`se_eff'^2			// Barendregt & Doi's suggestion: inverse of pooled variance
			else {
				confirm number `tn'
				scalar `hmean' = `tn'
			}
			
			// recall: transform is = asin(sqrt(`succ' / (`_NN' + 1 ))) + asin(sqrt((`succ' + 1 ) / (`_NN' + 1 )))
			// so to get our limits `mintes' and `maxtes', we subsitute `hmean' for `_NN', and let `succ' vary from 0 to `hmean'.
			scalar `mintes' = /*asin(sqrt(0      /(`hmean' + 1))) + */        asin(sqrt((0       + 1)/(`hmean' + 1 )))
			scalar `maxtes' =   asin(sqrt(`hmean'/(`hmean' + 1))) + asin(1) /*asin(sqrt((`hmean' + 1)/(`hmean' + 1 )))*/

			// Barendregt & Doi use s/v < 2 or (1-s)/v < 2
			// where s = sin(eff/2)^2 ~= d/n
			// and where v = se_eff ~= 1/n
			// ==> s/v ~= d;  (1-s)/v ~= n-d
			
			// ... in order to avoid "blow up" when sin(eff) is near zero
			// Personal communication:  "blow up" may result in confidence limits which do not include the point estimate
			// Therefore, test for this; and use simplified formula sin(eff)^2 in those cases
		
			if      `eff' < `mintes' scalar `prop_eff' = 0
			else if `eff' > `maxtes' scalar `prop_eff' = 1
			else scalar `prop_eff' = 0.5 * (1 - sign(cos(`eff')) * sqrt(1 - (sin(`eff') + (sin(`eff') - 1/sin(`eff')) / `hmean')^2 ) )
			
			if      `eff_lci' < `mintes' scalar `prop_lci' = 0
			else if `eff_lci' > `maxtes' scalar `prop_lci' = 1
			else scalar `prop_lci' = 0.5 * (1 - sign(cos(`eff_lci')) * sqrt(1 - (sin(`eff_lci') + (sin(`eff_lci') - 1/sin(`eff_lci')) / `hmean')^2 ) )

			if      `eff_uci' < `mintes' scalar `prop_uci' = 0
			else if `eff_uci' > `maxtes' scalar `prop_uci' = 1
			else scalar `prop_uci' = 0.5 * (1 - sign(cos(`eff_uci')) * sqrt(1 - (sin(`eff_uci') + (sin(`eff_uci') - 1/sin(`eff_uci')) / `hmean')^2 ) )
			
			cap {
			    assert `prop_lci' <= `prop_eff' & `prop_eff' <= `prop_uci'
				assert !missing(`prop_eff', `prop_lci', `prop_uci')
			}
			if _rc {
				scalar `prop_eff' = sin(`eff'    /2)^2
				scalar `prop_lci' = sin(`eff_lci'/2)^2
				scalar `prop_uci' = sin(`eff_uci'/2)^2
			}
			
			scalar `z' = 0
			if `eff' > `mintes' scalar `z' = abs(`eff' - `mintes') / `se_eff'
			
			return scalar prop_eff = `prop_eff'
			return scalar prop_lci = `prop_lci'
			return scalar prop_uci = `prop_uci'
			
			// Predictive intervals
			if `k' >= 3 {
				tempname prop_rflci prop_rfuci
				
				if      `rflci' < `mintes' scalar `prop_rflci' = 0
				else if `rflci' > `maxtes' scalar `prop_rflci' = 1
				else scalar `prop_rflci' = 0.5 * (1 - sign(cos(`rflci')) * sqrt(1 - (sin(`rflci') + (sin(`rflci') - 1/sin(`rflci')) / `hmean')^2 ) )

				if      `rfuci' < `mintes' scalar `prop_rfuci' = 0
				else if `rfuci' > `maxtes' scalar `prop_rfuci' = 1
				else scalar `prop_rfuci' = 0.5 * (1 - sign(cos(`rfuci')) * sqrt(1 - (sin(`rfuci') + (sin(`rfuci') - 1/sin(`rfuci')) / `hmean')^2 ) )

				if _rc {		// from earlier "cap assert"
					scalar `prop_rflci' = sin(`rflci'/2)^2
					scalar `prop_rfuci' = sin(`rfuci'/2)^2
				}
				
				return scalar prop_rflci = `prop_rflci'
				return scalar prop_rfuci = `prop_rfuci'
			}
		}
		else if "`summstat'"=="arcsine" {
			return scalar prop_eff = sin(`eff')^2
			return scalar prop_lci = sin(`eff_lci')^2
			return scalar prop_uci = sin(`eff_uci')^2
			
			// Predictive intervals
			if `k' >= 3 {
				return scalar prop_rflci = sin(`rflci')^2
				return scalar prop_rfuci = sin(`rfuci')^2
			}
		}
		else if "`summstat'"=="logit" {
			return scalar prop_eff = invlogit(`eff')
			return scalar prop_lci = invlogit(`eff_lci')
			return scalar prop_uci = invlogit(`eff_uci')
			
			// Predictive intervals
			if `k' >= 3 {
				return scalar prop_rflci = invlogit(`rflci')
				return scalar prop_rfuci = invlogit(`rfuci')
			}
		}
		else {
			return scalar prop_eff = `eff'
			return scalar prop_lci = `eff_lci'
			return scalar prop_uci = `eff_uci'
			
			// Predictive intervals
			if `k' >= 3 {			
				return scalar prop_rflci = `rflci'
				return scalar prop_rfuci = `rfuci'
			}
		}
		
		return scalar z = `z'
		return scalar eff_lci = `eff_lci'
		return scalar eff_uci = `eff_uci'
	}

	// All other data types
	else {
		if "`model'"=="pl" {				// N.B. PL confidence limits have already been calculated
			if "`teststat'"=="chi2" {
				scalar `crit' = invchi2(1, `olevel'/100)
				scalar `pvalue' = chi2tail(1, `chi2')
			}
			else {
				scalar `crit' = invnormal(.5 + `olevel'/200)
				scalar `pvalue' = 2*normal(-abs(`z'))
			}
		}
		else {
			if "`teststat'"=="chi2" { 
				scalar `crit' = invchi2(1, `olevel'/100)
				scalar `pvalue' = chi2tail(1, `chi2')
				return scalar chi2 = `chi2'
			}
			else if "`kroger'"!="" {
				tempname t
				scalar `crit' = invttail(`df_kr', .5 - `olevel'/200)
				scalar `t' = `eff'/`se_eff'
				scalar `pvalue' = 2*ttail(`df_kr', abs(`t'))
				return scalar t = `t'
			}
			else if "`teststat'"=="t" {
				tempname t
				scalar `crit' = invttail(`Qdf', .5 - `olevel'/200)
				scalar `t' = `eff'/`se_eff'
				scalar `pvalue' = 2*ttail(`Qdf', abs(`eff'/`se_eff'))
				return scalar t = `t'
			}
			else if "`model'"!="hc" {		// N.B. HC crit + p-value have already been calculated
				tempname z
				scalar `crit' = invnormal(.5 + `olevel'/200)
				scalar `z' = `eff'/`se_eff'
				scalar `pvalue' = 2*normal(-abs(`z'))
				return scalar z = `z'
			}
			
			// Confidence intervals
			if "`oevlist'"!="" {		// crit.value is chi2, but CI is based on z
				return scalar eff_lci = `eff' - invnormal(.5 + `olevel'/200) * `se_eff'
				return scalar eff_uci = `eff' + invnormal(.5 + `olevel'/200) * `se_eff'
			}
			else {						// else we can use crit.value (z or t, or u if HC)
				return scalar eff_lci = `eff' - `crit' * `se_eff'
				return scalar eff_uci = `eff' + `crit' * `se_eff'
			}
		}
	}	
	

	*****************************************
	* Derive other heterogeneity statistics *
	*****************************************
	// e.g. H, I-squared and (modified) H-squared; plus Q-based confidence intervals
	
	// Sensitivity analysis
	// (Note: tausq has already been established, whether `tsqsa' or `Isqsa')
	if "`model'"=="sa" {
		tempname H Isqval HsqM
		if `tsqsa' == -99 {
			scalar `H' = sqrt(100 / (100 - `isqsa'))
			scalar `Isqval' = `isqsa'
			scalar `HsqM' = `isqsa'/(100 - `isqsa')
			return scalar H = `H'
			return scalar Isq = `Isqval'
			return scalar HsqM = float(`HsqM')			// If user-defined I^2 is a round(ish) number, so should H^2 be
		}
		else {
			scalar `H' = sqrt((`tsqsa' + `sigmasq') / `sigmasq')
			scalar `Isqval' = 100*`tsqsa'/(`tsqsa' + `sigmasq')
			scalar `HsqM' = `tsqsa'/`sigmasq'
			return scalar H = `H'
			return scalar Isq = `Isqval'
			return scalar HsqM = `HsqM'
		}
		
		// [Sep 2020] Also save values in matrix `hetstats', same as if `isqparam' (see subroutine -heterogi- )
		local t2rownames tausq tsq_lci tsq_uci H H_lci H_uci Isq Isq_lci Isq_uci HsqM HsqM_lci HsqM_uci
		tempname hetstats
		local r : word count `t2rownames'
		matrix define `hetstats' = J(`r', 1, .)
		matrix rownames `hetstats' = `t2rownames'
		
		matrix `hetstats'[rownumb(`hetstats', "tausq"), 1] = `tausq'
		matrix `hetstats'[rownumb(`hetstats', "H"),     1] = `H'
		matrix `hetstats'[rownumb(`hetstats', "Isq"),   1] = `Isqval'
		matrix `hetstats'[rownumb(`hetstats', "HsqM"),  1] = `HsqM'
		
		return matrix hetstats = `hetstats'
	}
	
	else {
		if !inlist("`model'", "iv", "peto", "mu") {
			local tausqlist `tausq' `tsq_lci' `tsq_uci'
			cap assert "`tausqlist'"!="" if "`isqparam'"!=""
			if _rc {
				nois disp as err "Heterogeneity confidence interval not valid"
				exit 198
			}
		}
		
		cap nois Heterogi `Q' `Qdf' if `touse', `testbased' `isqparam' ///
			stderr(`_seES') tausqlist(`tausqlist') level(`hlevel')

		if _rc {
			if _rc==1 nois disp as err `"User break in {bf:metan.Heterogi}"'
			else nois disp as err `"Error in {bf:metan.Heterogi}"'
			c_local err noerr		// tell -metan- not to also report an "error in metan.PerformPoolingIV"
			exit _rc
		}
		
		return add
	}
	
	// Return scalars
	return scalar eff = `eff'
	return scalar se_eff = `se_eff'
	return scalar crit = `crit'
	return scalar pvalue = `pvalue'

	if "`kroger'"!="" return scalar df = `df_kr'
	else if "`teststat'"=="t" return scalar df = `Qdf'	

	return scalar k   = `k'				// k = number of studies (= count if `touse')
	return scalar Q   = `Q'				// Cochran's Q heterogeneity statistic
	return scalar Qdf = `Qdf'			// Q degrees of freedom (= `k' - 1)
	return scalar sigmasq = `sigmasq'	// "typical" within-study variance (Higgins & Thompson 2002)
	return scalar tausq = `tausq'		// between-study heterogeneity variance
	return scalar c = `c'				// scaling factor

end




** Mantel-Haenszel methods (binary outcomes only)
program define PerformPoolingMH, rclass

	syntax varlist(numeric min=2 max=2) [if] [in], ///
		INVLIST(varlist numeric min=4 max=4) MHVLIST(varlist numeric min=3 max=6) SUMMSTAT(name) ///
		[ TESTSTAT(name) QSTAT(name) TESTBased OEVLIST(varlist numeric min=2 max=2) ///
		CMHNocc noINTeger ISQParam WGT(name) WTVAR(varname numeric) OLevel(cilevel) * ]

	// N.B. extra options should just be those allowed for PerformPoolingIV
	
	marksample touse, novarlist		// in case of binary 2x2 data with no cases in one or both arms; this will be dealt with later
	local qvlist `varlist'			// for heterogeneity
	
	// Unpack `invlist' and `hetopt' [added May 2020]
	tokenize `invlist'
	args e1 f1 e0 f0
	
	// if no wtvar, gen as tempvar
	if `"`wtvar'"'==`""' {
		local wtvar
		tempvar wtvar
		qui gen `wtvar' = .
	}
	
		
	** Unpack tempvars for Mantel-Haenszel pooling
	tokenize `mhvlist'
	tempvar qhet
	tempname Q Qdf
	
	if "`summstat'"=="or" {
		args r s pr ps qr qs
		assert !missing(`r', `s', `pr', `ps', `qr', `qs') if `touse'
		
		// First, carry out CMH test if requested, since this can always be done, even with all-zero cells
		if "`teststat'"=="chi2" {
			tokenize `oevlist'
			args oe va
			assert !missing(`oe', `va') if `touse'

			tempname OE VA
			summ `oe' if `touse', meanonly
			scalar `OE' = cond(r(N), r(sum), .)
			summ `va' if `touse', meanonly
			scalar `VA' = cond(r(N), r(sum), .)
		
			tempname chi2 crit pvalue
			scalar `chi2' = ((abs(`OE') - cond("`cmhnocc'"!="", 0, 0.5))^2 ) / `VA'
			scalar `crit' = invchi2(1, `olevel'/100)
			scalar `pvalue' = chi2tail(1, `chi2')
			
			return scalar `teststat' = `chi2'
			return scalar crit = `crit'
			return scalar pvalue = `pvalue'
		}
		
		// weight
		cap confirm numeric variable `wgt'
		if !_rc qui replace `wtvar' = `wgt' if `touse'		// cc-corrected weights, for display purposes
		else qui replace `wtvar' = `s' if `touse'

		tempname R S OR eff
		summ `r' if `touse', meanonly
		scalar `R' = cond(r(N), r(sum), .)
		summ `s' if `touse', meanonly
		scalar `S' = cond(r(N), r(sum), .)

		scalar `OR'  = `R'/`S'
		scalar `eff' = ln(`OR')
			
		tempname PR PS QR QS se_eff
		summ `pr' if `touse', meanonly
		scalar `PR' = cond(r(N), r(sum), .)
		summ `ps' if `touse', meanonly
		scalar `PS' = cond(r(N), r(sum), .)
		summ `qr' if `touse', meanonly
		scalar `QR' = cond(r(N), r(sum), .)
		summ `qs' if `touse', meanonly
		scalar `QS' = cond(r(N), r(sum), .)
		
		// selogOR
		scalar `se_eff' = sqrt( (`PR'/(`R'*`R') + (`PS'+`QR')/(`R'*`S') + `QS'/(`S'*`S')) /2 )
		
		// return scalars
		return scalar OR = `OR'
		return scalar eff = `eff'
		return scalar se_eff = `se_eff'
			

		* Breslow-Day heterogeneity (M-H Odds Ratios only)
		// (Breslow NE, Day NE. Statistical Methods in Cancer Research: Vol. I - The Analysis of Case-Control Studies.
		//  Lyon: International Agency for Research on Cancer 1980)
		if inlist("`qstat'", "breslow", "tarone") {
			tempname Q_Breslow Q_Tarone
			tempvar r1 r0 c1 c0 n

			local type = cond("`integer'"=="", "long", "double")
			qui gen `type' `r1' = `e1' + `f1'		// total in research arm (= a + b)
			qui gen `type' `r0' = `e0' + `f0'		// total in control arm (= c + d)
			qui gen `type' `c1' = `e1' + `e0'		// total events (= a + c)
			qui gen `type' `c0' = `f1' + `f0'		// total non-events (= b + d)				
			qui gen `type' `n'  = `r1' + `r0'		// overall total
			
			tempvar bfit cfit dfit
			tempvar sterm cterm root
			qui gen double `sterm' = `r0' - `c1' + `OR'*(`r1' + `c1')
			qui gen double `cterm' = -`OR'*`c1'*`r1'
			qui gen double `root' = (-`sterm' + sqrt(`sterm'*`sterm' - 4*(1 - `OR')*`cterm'))/(2*(1 - `OR'))
			cap assert !missing(`root') if `touse'
			if _rc {
				assert abs(`OR' - 1) < 0.0001
				tempvar afit
				qui gen double afit = `r1'*`c1'/ `n'
				qui gen double bfit = `r1'*`c0'/ `n'
				qui gen double cfit = `r0'*`c1'/ `n'
				qui gen double dfit = `r0'*`c0'/ `n'
			}
			else {
				if `root' < 0 | `root' > `c1' | `root' > `r1' {
					replace `root' = (-`sterm' - sqrt(`sterm'*`sterm' - 4*(1 - `OR')*`cterm'))/(2*(1 - `OR'))				
					if `root' < 0 | `root' > `c1' | `root' > `r1' {
						replace `root' = .
					}
				}
				local afit `root'
				qui gen double `bfit' = `r1' - `afit'
				qui gen double `cfit' = `c1' - `afit'
				qui gen double `dfit' = `r0' - `cfit'
			}
			drop `sterm' `cterm'
			
			qui gen double `qhet' = ((`e1' - `afit')^2) * ((1/`afit') + (1/`bfit') + (1/`cfit') + (1/`dfit'))
			summ `qhet' if `touse', meanonly
			scalar `Q'   = cond(r(N), r(sum), .)
			scalar `Qdf' = cond(r(N), r(N)-1, .)
		
			// Tarone correction to Breslow-Day statistic
			if "`qstat'"=="tarone" {
				tempvar tarone_num tarone_denom
				qui gen double `tarone_num' = `e1' - `afit'
				summ `tarone_num' if `touse', meanonly
				local tsum = r(sum)
				qui gen double `tarone_denom' = 1/((1/`afit') + (1/`bfit') + (1/`cfit') + (1/`dfit'))
				summ `tarone_denom' if `touse', meanonly
				scalar `Q' = `Q' - (`tsum')^2 / r(sum)
				drop `tarone_num' `tarone_denom'
			}
			drop `qhet' `afit' `bfit' `cfit' `dfit'
		}
	}		// end M-H OR
	
	// Mantel-Haenszel RR/IRR/RRR
	// else if inlist("`summstat'", "rr", "irr", "rrr") {
	// MODIFIED APR 2019 FOR v3.3: REMOVE REFERENCE TO IRR
	else if inlist("`summstat'", "rr", "rrr") {
		args r s p
		assert !missing(`r', `s', `p') if `touse'

		// weight
		cap confirm numeric variable `wgt'
		if !_rc qui replace `wtvar' = `wgt' if `touse'		// cc-corrected weights, for display purposes		
		else qui replace `wtvar' = `s' if `touse'

		tempname R S RR eff
		summ `r' if `touse', meanonly
		scalar `R' = cond(r(N), r(sum), .)
		summ `s' if `touse', meanonly
		scalar `S' = cond(r(N), r(sum), .)

		scalar `RR'  = `R'/`S'
		scalar `eff' = ln(`RR')
			
		tempname P se_eff
		summ `p' if `touse', meanonly
		scalar `P' = cond(r(N), r(sum), .)

		// selogRR
		scalar `se_eff' = sqrt(`P'/(`R'*`S'))
				
		// return scalars
		return scalar RR = `RR'
		return scalar eff = `eff'
		return scalar se_eff = `se_eff'
	}

	// Mantel-Haenszel RD
	else if "`summstat'"=="rd" {
		args rdwt rdnum vnum
		assert !missing(`rdwt', `rdnum', `vnum') if `touse'
		
		// weight:  note that, unlike for OR and RR, cc-corrected weights are not needed for RD
		qui replace `wtvar' = `rdwt' if `touse'

		tempname W eff
		summ `rdwt' if `touse', meanonly
		scalar `W' = cond(r(N), r(sum), .)
		summ `rdnum' if `touse', meanonly
		scalar `eff' = r(sum)/`W'						// pooled RD

		tempname se_eff
		summ `vnum' if `touse', meanonly
		scalar `se_eff' = sqrt( r(sum) /(`W'*`W') )		// SE of pooled RD
		
		// return scalars
		return scalar eff = `eff'
		return scalar se_eff = `se_eff'
	}
	
	// Standard heterogeneity
	if inlist("`qstat'", "mhq", "cochranq") {
		tokenize `qvlist'
		args _ES _seES				// needed for heterogeneity calculations		
		
		// if Cochran's Q, need to calculate I-V effect size
		if "`qstat'"=="cochranq" {
			summ `_ES' [aw=1/`_seES'^2] if `touse', meanonly
			qui gen double `qhet' = ((`_ES' - r(mean)) / `_seES') ^2
		}		
		else qui gen double `qhet' = ((`_ES' - `eff') / `_seES') ^2
		summ `qhet' if `touse', meanonly

		if r(N)>=1 {
			scalar `Q' = r(sum)
			scalar `Qdf' = r(N) - 1
		}
		else {
			scalar `Q' = .
			scalar `Qdf' = .
		}
	}
	

	** Critical values, p-values, confidence intervals
	if "`oevlist'"=="" {				// i.e. all unless CMH (done previously)
		tempname crit z pvalue
		scalar `crit' = invnormal(.5 + `olevel'/200)
		scalar `z' = `eff'/`se_eff'
		scalar `pvalue' = 2*normal(-abs(`z'))
		return scalar crit = `crit'
		return scalar z = `z'
		return scalar pvalue = `pvalue'
	}
	
	// Confidence intervals
	return scalar eff_lci = `eff' - invnormal(.5 + `olevel'/200) * `se_eff'
	return scalar eff_uci = `eff' + invnormal(.5 + `olevel'/200) * `se_eff'
	
	
	** Derive and return:  H, I-squared, and (modified) H-squared	
	cap nois Heterogi `Q' `Qdf', `testbased' `isqparam'
	
	if _rc {
		if _rc==1 nois disp as err `"User break in {bf:metan.Heterogi}"'
		else nois disp as err `"Error in {bf:metan.Heterogi}"'
		c_local err noerr		// tell -metan- not to also report an "error in metan.PerformPoolingMH"
		exit _rc
	}
	return add
	
	// Return other scalars
	qui count if `touse'
	return scalar k   = r(N)	// k = number of studies (= count if `touse')
	return scalar Q   = `Q'		// generic heterogeneity statistic (incl. Peto, M-H, Breslow-Day)
	return scalar Qdf = `Qdf'	// Q degrees of freedom (= `k' - 1)

	// Return weights for CumInfLoop
	summ `wtvar' if `touse', meanonly
	return scalar totwt = cond(r(N), r(sum), .)		// sum of (non-normalised) weights

	// check for successful pooling
	if missing(`eff', `se_eff') exit 2002
	
end



// Based on heterogi.ado from SSC, with release notes:
// version 2.0 N.Orsini, I. Buchan, 25 Jan 06
// version 1.0 N.Orsini, J.Higgins, M.Bottai, 16 Feb 2005
// (c.f. Higgins & Thompson Stat Med 2002, "Quantifying heterogeneity")

program define Heterogi, rclass
	
	syntax anything [if] [in], [ TESTBased ISQParam ///
		STDERR(varname numeric) TAUSQLIST(namelist min=1 max=3) LEVEL(cilevel) ]

	marksample touse
	tokenize `anything'
	assert `"`3'"'==`""'
	args Q Qdf

	// setup W1, W2 for tausq if stderr available (e.g. not for M-H)
	if "`stderr'"!="" {
		tempvar wtvar
		qui gen double `wtvar' = 1/`stderr'^2

		tempname W1 W2
		summ `wtvar' if `touse', meanonly
		scalar `W1' = r(sum)				// sum of weights
		summ `wtvar' [aw=`wtvar'] if `touse', meanonly
		scalar `W2' = r(sum)				// sum of squared weights
		
		tempname sigmasq
		scalar `sigmasq' = (r(N) - 1) / (`W1' - `W2'/`W1')		
	}

	
	********************
	* Standard Q-based *
	********************

	tempname Q_lci Q_uci
	scalar `Q_lci' = .
	scalar `Q_uci' = .
	
	
	** Confidence intervals:

	// Test-based interval for ln(Q) [ or, equivalently, ln(H) ]
	// (Higgins & Thompson, Stats in Medicine 2002)
	if "`testbased'"!="" {
		tempname k selogQ
		scalar `k' = `Qdf' + 1
		
		// Formula 26.4.13 of Abramowitz and Stegun (1965):
		// Z = sqrt(2Q) - sqrt(2k - 3) is standard normal
		// Now, expected value of Q is k-1, so form a standard normal variate as follows (taking logs to reduce skew):
		// Z = [ ln(Q) - ln(k-1) ] / se[ ln(Q) ]
		// ==> se[ ln(Q) ] = [ ln(Q) - ln(k-1) ] / [ sqrt(2Q) - sqrt(2k - 3) ]
		scalar `selogQ' = (ln(`Q') - ln(`Qdf')) / ( sqrt(2*`Q') - sqrt(2*`k' - 3) )
		
		// Formula 26.4.36 of Abramowitz and Stegun (1965):
		// Var[ ln(Q/k-1) ] = [ 2/(k-2) ] * [ 1 - (1/ {3(k-2)^2} ) ]
		// (use if Q <= k)
		if `Q' <= `k' {
		    scalar `selogQ' = sqrt( ( 2/(`k'-2)) * (1 - 1/(3*(`k'-2)^2)) )
		}
		
		tempname Q_lci Q_uci
		scalar `Q_lci' = max(0, exp( ln(`Q') - invnormal(.5 + `level'/200) * `selogQ' ))
		scalar `Q_uci' =        exp( ln(`Q') + invnormal(.5 + `level'/200) * `selogQ' )
		
		/*
		// Original code from heterogi.ado
		// used confidence intervals for lnH rather than for lnQ, but these differ only by a constant:
		// If, as above, Var[ ln(Q/k-1) ] = [ 2/(k-2) ] * [ 1 - (1/ {3(k-2)^2} ) ]
		// then if ln(H) = .5 * ln(Q/k-1), then Var[ ln(H) ] = .25 * Var[ ln(Q/k-1) ] = [ 1/ 2(k-2) ] * [ 1 - (1/ {3(k-2)^2} ) ]
		
		scalar `selogH' = cond(`Q' > `k', ///
			.5*( (ln(`Q') - ln(`Qdf')) / ( sqrt(2*`Q') - sqrt(2*`k' - 3) ) ), ///
			sqrt( ( 1/(2*(`k'-2)) * (1 - 1/(3*(`k'-2)^2)) ) ))
		
		scalar `H_lci' = max(1, exp( ln(`H') - invnormal(.5 + `level'/200) * `selogH' ))
		scalar `H_uci' =        exp( ln(`H') + invnormal(.5 + `level'/200) * `selogH' )
		*/
	}

	// Q-based confidence intervals
	// using ncchi2 if fixed-effect; Gamma-based if random-effects (ref: Hedges & Pigott, 2001)
	// ncchi2 previously recommended by JPTH based on personal communications
	else {
		if "`tausqlist'"=="" {			// fixed (common) effect
			tempname nc
			scalar `nc' = max(0, `Q' - `Qdf')
 
			// If Q < df, no need to seek the lower bound
			tempname Q_lci Q_uci
			scalar `Q_lci' = cond(`nc'==0, 0, invnchi2(`Qdf', `nc', .5 - `level'/200))
			scalar `Q_uci' =                  invnchi2(`Qdf', `nc', .5 + `level'/200)
		}

		else {							// random-effects
			cap assert "`stderr'"!=""
			if _rc {
				nois disp as err "Heterogeneity confidence interval not valid"
				exit 198
			}
		
			tempname W3 tsq_dl
			summ `wtvar' [aw=`wtvar'^2] if `touse', meanonly
			scalar `W3' = r(sum)									// sum of cubed weights
			scalar `tsq_dl' = (`Q' - `Qdf') / (`W1' - `W2'/`W1')	// non-truncated tsq_DL
		
			tempname btVarQ
			scalar `btVarQ' = 2*`Qdf' + 4*`tsq_dl'*(`W1' - `W2'/`W1') + 2*(`tsq_dl'^2)*(`W2' - 2*`W3'/`W1' + (`W2'/`W1')^2)
			
			// If Q < df, no need to seek the lower bound
			tempname Q_lci Q_uci
			scalar `Q_lci' = cond(`Q' < `Qdf', 0, invgammap(`Q'^2 / `btVarQ', .5 - `level'/200) * `btVarQ' / `Q')
			scalar `Q_uci' =                      invgammap(`Q'^2 / `btVarQ', .5 + `level'/200) * `btVarQ' / `Q'
		}
	}

	// standard, transformed CIs for Isq, as outputted by heterogi.ado
	// Taken from heterogi.ado by N.Orsini, J.Higgins, M.Bottai, N.Buchan (2005-2006)
	return scalar Q_lci = `Q_lci'
	return scalar Q_uci = `Q_uci'

	return scalar H     = max(1, sqrt(`Q' / `Qdf'))
	return scalar H_lci = max(1, sqrt(`Q_lci' / `Qdf'))
	return scalar H_uci =        sqrt(`Q_uci' / `Qdf')			
		
	return scalar Isq     = 100* max(0, (`Q' - `Qdf') / `Q')
	return scalar Isq_lci = 100* max(0, (`Q_lci' - `Qdf') / `Q_lci')
	return scalar Isq_uci = 100* min(1, (`Q_uci' - `Qdf') / `Q_uci')
		
	return scalar HsqM     = max(0, (`Q'     - `Qdf') / `Qdf')
	return scalar HsqM_lci = max(0, (`Q_lci' - `Qdf') / `Qdf')
	return scalar HsqM_uci = max(0, (`Q_uci' - `Qdf') / `Qdf')
	
	

	*********************
	* Tau-squared based *
	*********************
	
	if "`isqparam'"!="" {
		tokenize `tausqlist'
		args tausq tsq_lci tsq_uci
		
		// Save values in matrix `hetstats'
		local t2rownames tausq tsq_lci tsq_uci H H_lci H_uci Isq Isq_lci Isq_uci HsqM HsqM_lci HsqM_uci
		tempname hetstats
		local r : word count `t2rownames'
		matrix define `hetstats' = J(`r', 1, .)
		matrix rownames `hetstats' = `t2rownames'
		
		if "`tausqlist'"!="" {
			matrix `hetstats'[rownumb(`hetstats', "tausq"), 1] = `tausq'
			matrix `hetstats'[rownumb(`hetstats', "H"), 1]     = sqrt((`tausq' + `sigmasq') / `sigmasq')
			matrix `hetstats'[rownumb(`hetstats', "Isq"), 1]   = 100* `tausq' / (`tausq' + `sigmasq')
			matrix `hetstats'[rownumb(`hetstats', "HsqM"), 1]  = `tausq' / `sigmasq'
		}
		
		// If `tausq' not defined for this model, store H, Isq and HsqM (& CIs) based on Q instead
		else {
			matrix `hetstats'[rownumb(`hetstats', "H"), 1]    = max(1, sqrt(`Q' / `Qdf'))
			matrix `hetstats'[rownumb(`hetstats', "Isq"), 1]  = 100* max(0, (`Q' - `Qdf') / `Q')
			matrix `hetstats'[rownumb(`hetstats', "HsqM"), 1] = max(0, (`Q' - `Qdf') / `Qdf')
			
			matrix `hetstats'[rownumb(`hetstats', "H_lci"), 1]    = max(1, sqrt(`Q_lci' / `Qdf'))
			matrix `hetstats'[rownumb(`hetstats', "Isq_lci"), 1]  = 100* max(0, (`Q_lci' - `Qdf') / `Q_lci')
			matrix `hetstats'[rownumb(`hetstats', "HsqM_lci"), 1] = max(0, (`Q_lci' - `Qdf') / `Qdf')

			matrix `hetstats'[rownumb(`hetstats', "H_uci"), 1]    = max(1, sqrt(`Q_uci' / `Qdf'))
			matrix `hetstats'[rownumb(`hetstats', "Isq_uci"), 1]  = 100* max(0, (`Q_uci' - `Qdf') / `Q_uci')
			matrix `hetstats'[rownumb(`hetstats', "HsqM_uci"), 1] = max(0, (`Q_uci' - `Qdf') / `Qdf')
		}
		
		// Confidence intervals, if appropriate
		if `"`tsq_lci'"'!=`""' {
			matrix `hetstats'[rownumb(`hetstats', "tsq_lci"), 1]  = `tsq_lci'
			matrix `hetstats'[rownumb(`hetstats', "H_lci"), 1]    = sqrt((`tsq_lci' + `sigmasq') / `sigmasq')
			matrix `hetstats'[rownumb(`hetstats', "Isq_lci"), 1]  = 100* `tsq_lci' / (`tsq_lci' + `sigmasq')
			matrix `hetstats'[rownumb(`hetstats', "HsqM_lci"), 1] = `tsq_lci' / `sigmasq'
			
			matrix `hetstats'[rownumb(`hetstats', "tsq_uci"), 1]  = `tsq_uci'
			matrix `hetstats'[rownumb(`hetstats', "H_uci"), 1]    = sqrt((`tsq_uci' + `sigmasq') / `sigmasq')
			matrix `hetstats'[rownumb(`hetstats', "Isq_uci"), 1]  = 100* `tsq_uci' / (`tsq_uci' + `sigmasq')
			matrix `hetstats'[rownumb(`hetstats', "HsqM_uci"), 1] = `tsq_uci' / `sigmasq'
		}
		
		return matrix hetstats = `hetstats'
	}

end




***********************************************************

* Program to generate confidence intervals for individual studies (NOT pooled estimates)
// subroutine of PerformMetaAnalysis

program define GenConfInts, rclass sortpreserve

	syntax varlist(numeric min=2 max=6 default=none) [if] [in], ///
		CItype(string) OUTVLIST(varlist numeric min=5 max=9) ///
		[ SUMMSTAT(name) noINTeger PRoportion PRVLIST(varlist numeric) NOPR DF(varname numeric) ILevel(cilevel) ]

	marksample touse, novarlist
	local invlist `varlist'			// list of "original" vars passed by the user to the program 
	
	// unpack varlists
	tokenize `outvlist'
	args _ES _seES _LCI _UCI _WT _NN
	local params : word count `invlist'
	
	// if no data to process, exit without error
	return scalar level = `ilevel'
	qui count if `touse'
	if !r(N) exit	
	
	// Confidence limits need calculating if:
	//  - not supplied by user (i.e. `params'!=3); or
	//  - desired coverage is not c(level)%
	if `params'==3 & `ilevel'==c(level) exit
	
	
	* Proportions
	if "`proportion'"!="" {
		tokenize `invlist'
		args n N

		// `prvlist' exists if "`summstat'"!="pr" & "`nopr'"==""
		// 		_ES, _LCI, _UCI on transformed scale
		//		_Prop_ES etc. on back-transformed (original) scale
		// else if "`summstat'"!="pr"
		// 		_ES, _LCI, _UCI on transformed scale
		// else 
		//		_ES, _LCI, _UCI are on *original* scale
		if "`summstat'"!="pr" {
			
			// Unless "`summstat'"=="pr",
			// _ES _LCI _UCI will be on transformed (interval) scale
			// so generate CIs using normal distribution
			qui replace `_LCI' = `_ES' - invnormal(.5 + `ilevel'/200) * `_seES' if `touse'
			qui replace `_UCI' = `_ES' + invnormal(.5 + `ilevel'/200) * `_seES' if `touse'
		
			// _Prop_ES _Prop_LCI _Prop_LCI (in `prvlist') contain proportion & CI on "original" (back-transformed) scale
			// so use built-in -cii-
			if "`prvlist'"!="" {
				tokenize `prvlist'
				args _Prop_ES _Prop_LCI _Prop_UCI
				qui replace `_Prop_ES' = `n' / `N' if `touse'
			
				// non-integer values: calculate Wald CI "manually"
				if `"`integer'"'!=`""' {
					qui replace `_Prop_LCI' = `_Prop_ES' - invnormal(.5 + `ilevel'/200) * sqrt(`_Prop_ES' * (1 - `_Prop_ES') / `N') if `touse'
					qui replace `_Prop_UCI' = `_Prop_ES' + invnormal(.5 + `ilevel'/200) * sqrt(`_Prop_ES' * (1 - `_Prop_ES') / `N') if `touse'
				}
			
				else {
					// sort appropriately, then find observation number of first relevant obs
					tempvar obs
					qui bysort `touse' : gen long `obs' = _n if `touse'
					sort `obs'
					summ `obs' if `touse', meanonly
					forvalues j = 1/`r(max)' {
						`version' qui cii `=`N'[`j']' `=`n'[`j']', `citype' level(`ilevel')
						qui replace `_Prop_LCI' = `r(lb)' in `j'
						qui replace `_Prop_UCI' = `r(ub)' in `j'
					}
				}
			}
		}

		// If "`summstat'"=="pr", proportions are presented & pooled entirely on their original scale
		// so use built-in -cii- (unless -nointeger- )
		else {
			if `"`integer'"'!=`""' {
				qui replace `_LCI' = `_ES' - invnormal(.5 + `ilevel'/200) * sqrt(`_ES' * (1 - `_ES') / `N') if `touse'
				qui replace `_UCI' = `_ES' + invnormal(.5 + `ilevel'/200) * sqrt(`_ES' * (1 - `_ES') / `N') if `touse'
			}

			else {
				tempvar obs
				qui bysort `touse' : gen long `obs' = _n if `touse'
				sort `obs'
				summ `obs' if `touse', meanonly
				forvalues j = 1/`r(max)' {
					`version' qui cii `=`N'[`j']' `=`n'[`j']', `citype' level(`ilevel')
					qui replace `_LCI' = `r(lb)' in `j'
					qui replace `_UCI' = `r(ub)' in `j'
				}
			}
		}
	}
	
	
	* Calculate confidence limits for original study estimates using specified `citype'
	// (unless limits supplied by user)
	else if "`citype'"=="normal" {			// normal distribution - default
		qui replace `_LCI' = `_ES' - invnormal(.5 + `ilevel'/200) * `_seES' if `touse'
		qui replace `_UCI' = `_ES' + invnormal(.5 + `ilevel'/200) * `_seES' if `touse'
	}
		
	// else if inlist("`citype'", "t", "logit") {		// t or logit distribution
	else if "`citype'"=="t" {
		cap confirm numeric variable `df'
		if !_rc {
			summ `df' if `touse', meanonly			// use supplied df if available
			cap assert r(max) < .
			if _rc {
				nois disp as err `"Degrees-of-freedom variable {bf:`df'} contains missing values;"'
				nois disp as err `"  cannot use {bf:`citype'}-based confidence intervals for study estimates"'
				exit 198
			}
		}
		else {
			cap confirm numeric variable `_NN'
			if !_rc {
				summ `_NN' if `touse', meanonly			// otherwise try using npts
				cap assert r(max) < .
				if _rc {
					nois disp as err `"Participant numbers not available for all studies;"'
					nois disp as err `"  cannot use {bf:`citype'}-based confidence intervals for study estimates"'
					exit 198
				}
				tempvar df
				qui gen `: type `_NN'' `df' = `_NN' - 2			// use npts-2 as df for t distribution of df not explicitly given
				local disperr `"disp `"{error}Note: Degrees of freedom for {bf:`citype'}-based confidence intervals not supplied; using {it:n-2} as default"'"'
				// delay error message until after checking _ES is between 0 and 1 for logit
			}
			else {
				nois disp as err `"Neither degrees-of-freedom nor participant numbers available;"'
				nois disp as err `"  cannot use {bf:`citype'}-based confidence intervals for study estimates"'
				exit 198
			}
		}
		
		tempvar critval
		qui gen double `critval' = invttail(`df', .5 - `ilevel'/200)
		
		// if "`citype'"=="t" {
			qui replace `_LCI' = `_ES' - `critval'*`_seES' if `touse'
			qui replace `_UCI' = `_ES' + `critval'*`_seES' if `touse'
		// }
		/*
		else {								// logit, proportions only (for formula, see Stata manual for -proportion-)
			summ `_ES' if `touse', meanonly
				if r(min)<0 | r(max)>1 {
				nois disp as err "option {bf:citype(logit)} may only be used with proportions"
				exit 198
			}
			qui replace `_LCI' = invlogit(logit(`_ES') - `critval'*`_seES'/(`_ES'*(1 - `_ES'))) if `touse'
			qui replace `_UCI' = invlogit(logit(`_ES') + `critval'*`_seES'/(`_ES'*(1 - `_ES'))) if `touse'
		}
		*/
	}
		
	else if inlist("`citype'", "cornfield", "exact", "woolf") {		// options to pass to -cci-; summstat==OR only
		tokenize `invlist'
		args a b c d		// events & non-events in trt; events & non-events in control (c.f. -metan- help file)

		// sort appropriately, then find observation number of first relevant obs
		tempvar obs
		qui bysort `touse' : gen long `obs' = _n if `touse'		// N.B. MetaAnalysisLoop uses -sortpreserve-
		sort `obs'												// so this sorting should not affect the original data
		summ `obs' if `touse', meanonly
		forvalues j = 1/`r(max)' {
			`version' qui cci `=`a'[`j']' `=`b'[`j']' `=`c'[`j']' `=`d'[`j']', `citype' level(`ilevel')
			qui replace `_LCI' = ln(`r(lb_or)') in `j'
			qui replace `_UCI' = ln(`r(ub_or)') in `j'
		}
	}
	
	// Now display delayed error message if appropriate
	`disperr'

end





********************************************************************************

***************************************
* metan.ado detailed revision notes *
***************************************

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

//	v1.4 WAS GETTING THERE
// 	v1.5 SORT OUT EXTRA LINE AT THE TOP AND ALLOW "DOUBLE LINES"
//	FOR FIXED AND RANDOM EFFECTS

//	SOMETHING TO ADD- RETURN ES_2?
//	v1.7 - TRY TO SORT OUT LABELLING
//	CHANGED LABELS TO 7.3g -WORKS NICELY
//	"FAVOURS" NOW WORKS- USES xmlabel
//	v1.8 ADDED IN COUNTS OPTION, SORTED OUT TEXTSIZE, PROPER DEFINITION AND SPLIT OF VAR LABELS

// 	v1.9 DELETE UNECESSARY OPTIONS
//	OH, AND ADD effect OPTION
//	v1.10 FINAL TIDYING, USED Jeff Pitblado's SUGGESTION FOR getWidth

//	v1.11 USE label() OPTIONS IF NO lcols rcols, WORK ON AUTO FIT TEXT
//	v1.12 FURTHER WORK...

//	v1.14 DONE ON 12TH OCTOBER, FINALLY DISCOVERED WHAT IS CAUSING PROBLEM
//	WITH "NON-MATCHING CLOSE BRACE" AT END OF FILE- NO v7 STYLE IF STATEMENTS!
//	EVERYTHING GOES ON A SEPARATE LINE NOW. PHEW.

//	v1.15 NOW ADDING IN OPTIONS TO CONTROL BOXES, CI LINES, OVERALL
//	TITLES WEREN'T SPREADING ACROSS SINCE OPTION TO CONTROL OVERALL TEXT- FIXED AGAIN

//	v1.16 LAST ATTEMPT TO GET TEXT SIZE RIGHT! WORK OUT WHAT ASPECT SHOULD BE AND USE
//	IF ASPECT DEFINED THEN DECREASE TEXT SIZE BY RATIO TO IDEAL ASPECT

//	TEXT SCALING WORKING BETTER NOW
//	LAST THING TO TRY TO SORT IS LOOK FOR LEFT OF DIAMOND AND MOVE HET STATS
//	COULD PUT UNDERNEATH IF NOT MUCH SPACE? THIS WOULD BE GOOD v1.17
//	STILL DEBATING WHETHER TO PUT favours BIT BELOW xticks...

//	V19 LOTS OF COMMENTS FROM JONATHAN AND BITS TO DO. SUMMARY:
//	aspect 				Y
//	note if random weights		Y
//	update to v8			Y
//	graph in mono			Y
//	extend overall text into plot	Y
//	labels				Y
//	help file				not v8 yet

//	v1.21 EVERY PROGRAM NOW CONVERTED TO v9.0, NO "CODE FOLLOWS BRACES!"

//	WHAT ELSE DID PATRICK DO TO UPDATE TO v8?

//	NO "#delimit ;" 					- I QUITE LIKE THIS THOUGH!
//	GLOBALS ARE DECLARED WITHOUT = SIGN		- EXCEPT WHEN USING STRING FUNCTION ETC. IT DOESN'T LIKE THIS!
//								- WILL THIS EVER CAUSE PROBLEMS?
//								- CAN'T BE BOTHERED TO CHANGE ALL THE NUMERIC ONES
//	USE TOKENIZE INSTEAD OF PARSE			- DONE
//	USE di as err NOT in red, EXIT		- DONE, PROPER RETURN CODES STILL NEEDED, MAYBE SOMEDAY!
//	DECENT HELP FILE					- USED, JUST ADD IN NEW BITS

//	v1.22 ENCODE STUFF FOR metanby NOW LABORIOUSLY RECODED SO THAT GROUPS ARE IN ORIGINAL SORT ORDER
//	THIS IS USEFUL IF YOU DON'T WANT STUFF IN ALPHA-NUMERIC ORDER, OR TO PUT "1..." "2..." ETC.

//	counts OPTION DOES NOT WORK WITH MEAN DIFFERENCES- AND LOOKS LIKE IT NEVER DID- PUT IN
//	DO OWN LINES FOR OVERALL ETC. EXTENDS TOO FAR
//	LABELS NEVER RUN TO FOUR LINES- SORT OUT- QUICK SOLU- DO FIVE TIMES AND DROP ONE!

//	v1.23 USES pcspike FOR OVERALL AND NULL LINES TO PREVENT OVER-EXTENDING
//	NOW HAS OPTION FOR USER DEFINED "SECOND" ANALYSIS

//	v1.24 ALLOW USER TO COMPLETELY DEFINE ANALYSIS WITH WEIGHTS

// 	v2.34 problem with nosubgroup nooverall sorted out (this combination failed)

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

// May 2009
//	prediction interval sorted out. Note error in Higgins presentation (too wide- there is no heterogeneity in data!)
//	so don't check with this! George Kelley has sent example data




***************************************
* admetan.ado detailed revision notes *
***************************************

* originally written by David Fisher, June 2013

* version 1.0  David Fisher  31jan2014

* version 2.0  David Fisher  11may2017
* Major update to extend functionality beyond estimation commands; now has most of the functionality of -metan-
//  - Reworked so that ipdmetan.ado does command processing and looping, and admetan.ado does RE estimation (including -metan- functionality)
//  - Hence, ipdover calls ipdmetan (but never admetan); ipdmetan calls admetan (if not called by ipdover); admetan can be run alone.
//      Any of the three may call forestplot, which of course can also be run alone.

* version 2.1  David Fisher  14sep2017
// various bug fixes
// Note: for harmonisation with metan/metaan, Isq input and output is now in the range 0 to 100, rather than 0 to 1.

// Corrected error whereby tausq could not be found by iterative methods if >> 0
//  due to assumptions based on me mostly using ratio statistics, where tausq < 1, and not mean differences where tausq can be any magnitude.


* version 3.0  David Fisher  08nov2018
// IPD+AD code now moved to ipdmetan.ado
//   so that admetan is completely self-contained, with minimal reference to -ipdmetan-
// various bug fixes and minor improvements
// implemented -useopts- facility and _EFFECT variable

* version 3.1  David Fisher  04dec2018
// Allow `oev' with Peto ORs
// Specify default format & title for numeric vars in results sets, so that they display nicely in forestplot
// Fixed bug which meant "HKSJ method" was not displayed on screen (although the method itself was used)
// `hksj' and `bartlett' are returned (if applicable) in r(vce_model)

* version 3.2  David Fisher  28jan2019
// Do not allow `study' and `by' to have the same name
// Added SJ Robust ("sandwich-like") variance estimator (Sidik & Jonkman CompStatDataAnalysis 2006)
// Added Skovgaard's correction to the signed likelihood statistic (Guolo Stat Med 2012)
// Corrected bug when continuity correction options were specified; also added new on-screen text r.e. cc [ADDED FEB 2019]
// Corrected returned statistics for `chi2opts' and Henmi-Copas model
// Corrected bug when specifying npts(varname) with "generic" effect measures
// Generalised the two-step estimators (Sidik-Jonkman and DerSimonian-Kacker)
// `hksj', `bartlett', `skovgaard' and `robust' are returned (if applicable) as part of r(model)
// Some text in help file has been changed/updated

* version 3.3 (beta; never released)  David Fisher 30aug2019

// Zero cells and the Mantel-Haenszel method:  default is to add cc=0.5 for display purposes only...
//   ...including "double-zero" studies, as they still contribute to the MH pooled estimate
// (if M-H) If -nocc- is explicitly requested, *KEEP ALL STUDIES IN* and print appropriate warning message
// Zero-cell studies must be *explicitly excluded* using if/in in this scenario.

// Q, tausq etc. based on MH vs Inverse-Variance pooled estimate:  No tausq/Isq if M-H.

// Also if M-H:  CMH with/without correction; "Old" Breslow/Day; "New" Breslow/Day/Tarone.

* Current version 3.4 (beta; will be 4.0 upon release)  David Fisher 23oct2019

// Fixed bug where main options (e.g. nograph) would be ignored under certain circumstances
// Fixed bug where id would be repeated if given as lcols(id)

// Major addition: multiple models, either as backslash-separated list e.g. model(fe\dl\reml\pl)
//  or, as in -metan-  first() second()

// Also now incorporating code from "heterogi.ado" for calculating CIs for Isq
// (c.f. Higgins & Thompson Stat Med 2002, "Quantifying heterogeneity")
//  - test-based (for lnH or lnQ)
//  - noncentral Q
//  - Q profiling

// Major addition: added meta-analysis of proportions

// Restored previous -metan- behaviour of sorting string by() by order of appearance, rather than alphabetically
// Improved behaviour of -influence- : corrected bug in weight normalisation with subgroups;
//    -forestplot- now by default displays -influence- pooled results as vertical lines rather than diamonds


