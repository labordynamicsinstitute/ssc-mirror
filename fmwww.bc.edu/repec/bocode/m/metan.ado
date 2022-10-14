* metan.ado
* Study-level (aka "aggregate-data" or "published data") meta-analysis

*! version 4.06  12oct2022
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

* version 4.03
// - added new option -nobetween- : suppresses reporting of between-subgroup heterogeneity (in table and forestplot)

// Bug fixes:
// - improved behaviour with single-study subgroups
// - corrected placement of between-group heterogeneity in forest plot
// - corrected behaviour of `proportion' with `cumulative'/`influence'; also denominator(#) in forest plot
// - with Mantel-Haenszel Risk Ratios with zero cells, pooled result sometimes displayed erroneously as 1.000

* version 4.04
// - improvements to Freeman-Tukey double-arcsine transformation for proportions
// - fixed bug which prevented saving when calling from -ipdmetan- under certain circumstances
// - improvements to "clear" option to enable it to be used within ipdmetan/ipdover

* version 4.05
// - option "summaryonly" now saves the same (extended) set of variables as cumulative/influence
// - fixed bug that meant "summaryonly" with "saving()/clear" and "nograph" saved the *full* results-set (i.e. as if ignoring "summaryonly")
// - addition of prefix() option so that saved variables are `prefix'_ES etc.
// - tweaked _rsample so that it takes on 0, 1, 2;  where 2 corresponds to "insufficient data"
//   ... note that r(n), r(ovstats) and r(bystats) always give the counts for _USE/_rsample==1 *only*.

* version 4.06
// Bug fixes:
// - `proportion' with `cumulative'/`influence', when combined with `saving' or `clear', resulted in an error; this has been fixed
// - `proportion' with `counts' gives incorrect denominators for subgroups (they are doubled); this has been fixed
// - with hetinfo(tausq), the code only picked up the tsq value from the first subgroup, and repeated it across all other subgroups; this has been fixed
// Improvements:
// - improved code to avoid rounding errors/negative weights when `qwt' is zero
// - new option "labtitle" to over-ride the default "Subgroup and Study" title with by()
// - minor improvements to behaviour with zero cells in special cases (by, cumulative, influence)
// - for proportion data, where a "pooled" result is actually just a single study,
//      CIs on the proportion scale are handled by -cii- rather than by back-transformation
// Plus: code subroutines re-organized for improved readability and debugging going forward


program define metan, rclass properties(hr nohr shr noshr irr or rrr)

	version 11.0
	local version : di "version " string(_caller()) ":"

	if _caller() >= 12 {
	    local hidden hidden
		local historical historical
	}
	return `hidden' local metan_version "4.06"

	// Clear historical global macros (see metan9.ado)
	forvalues i = 1/15 {
		global S_`i'
	}
	global S_51
	
	syntax varlist(numeric min=2 max=6) [if] [in] [, SORTBY(varlist) ///
		FORESTplot(passthru) /// forestplot (ultimately -twoway-) options
		USE(varname numeric) /// undocumented option, for use with e.g. -ipdmetan-
		* ]					  // all other options, to be parsed later
	
	local ifopt : copy local if			// for warning message regarding missing/insufficient data
	local inopt : copy local in			// for warning message regarding missing/insufficient data

	marksample touse, novarlist			// `novarlist' option so that entirely missing/nonexistent studies/subgroups may be included
	local invlist `varlist'				// list of "original" vars passed by the user to the program 

	if `"`use'"'!=`""' {				// e.g. if passed from -ipdmetan-
		local _USE : copy local use
		cap assert inlist(`_USE', 1, 2, 3, 5) if `touse'
		if _rc {
		    nois disp as err `"error in {bf:use(}{it:varname}{bf:)}"'
			exit 198
		}
		local ifopt
		local inopt
		
		// re-define `touse' as if running -metan- directly;
		//  values of _USE other than 1 and 2 will not be needed until BuildResultsSet.
		tempvar touse2
		qui gen byte `touse2' = `touse'
		qui replace `touse' = `touse' * inlist(`_USE', 1, 2)
		local touse2opt touse2(`touse2')
	}
	else {
		tempvar _USE							// Note that `_USE' is defined if-and-only-if `touse'
		qui gen byte `_USE' = 1 if `touse'		// i.e.  !missing(`_USE') <==> `touse'
		local touse2 `touse'
	}	
	if `"`ifopt'`inopt'"'!=`""' local ifinopt ifinopt
		
	
	*******************
	* Initial parsing *
	*******************

	** Parse -forestplot- options to extract those relevant to -metan-
	// N.B. Certain options may be supplied EITHER to metan directly, OR as sub-options to forestplot()
	//  with "forestplot options" prioritised over "metan options" in the event of a clash.
	
	// These options are:
	// effect options parsed by CheckOpts (e.g. `rr', `rd', `md', `smd', `wmd', `log')
	// nograph, nohet, nobetween, nooverall, nosubgroup, nowarning, nowt, nostats
	// effect, hetinfo, lcols, rcols, plotid, ovwt, sgwt, sgweight
	// cumulative, efficacy, influence, interaction
	// counts, group1, group2 (for compatibility with previous version of metan.ado)
	// rfdist, rflevel (for compatibility with previous version of metan.ado)

	// N.B. if -metan- was called by -ipdmetan- , some of this may already have been done

	cap nois ParseFPlotOpts, cmdname(`cmdname') touse(`touse') options(`options') `forestplot'
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
	local opts_adm = trim(`"`s(opts_parsed)' `s(options)'"')	// options as listed above, plus other options supplied directly to -metan-
	local opts_fplot = trim(`"`s(opts_fplot)'"')
	local forestplot forestplot(`opts_fplot')		// other options supplied as sub-options to forestplot(), or main options with relevance *only* to forestplot.ado

	
	****************************************
	* Establish basic data characteristics *
	****************************************
	
	// Generate stable ordering to pass to future subroutines
	tempvar obs
	qui gen long `obs' = _n


	** Parse `study' and `by' (including first element of `lcols' if appropriate)
	// Checks for problems with `study' and `by'
	//  and, amongst other things, converts them from string to numeric if necessary
	tempname newstudylab newbylab
	tempvar  newstudy    newby	
	
	cap nois ProcessLabels `invlist' if `touse', sortby(`sortby' `obs') `opts_adm' ///
		newstudy(`newstudy')       newby(`newby') ///
		newstudylab(`newstudylab') newbylab(`newbylab')

	if _rc {
		if _rc==1 nois disp as err `"User break in {bf:metan.ProcessLabels}"'
		else nois disp as err `"Error in {bf:metan.ProcessLabels}"'
		c_local err noerr
		exit _rc
	}

	// Parse and re-define lcols(), which may have been altered by ProcessLabels
	// and remove original options by(), study() and label() from options list
	// (replacements for these are returned by ProcessLabels)
	// plus labtitle() will be stored in `output_opts', not `opts_adm'
	local 0 `", `opts_adm'"'
	syntax , [ STUDY(string) BY(string) LABEL(string) LCols(namelist) LABTITLE(string asis) * ]

	// study/title options, to pass onto metan_output.ado
	local opts_adm `"`macval(options)'"'
	local output_opts `"study(`s(study)') sfmtlen(`s(sfmtlen)') labtitle(`s(labtitle)') lcols(`s(lcols)')"'
	
	// `_STUDY' and `_BY' are the "working" variables from now on; guaranteed numeric.
	// We don't need `study' and `by' anymore (except for -markout- immediately below);
	//   instead `_STUDY' and `_BY' indicate the existence of these variables (e.g. in validity checks).	
	local _STUDY `s(study)'
	local _BY `s(by)'
	if `"`s(smissing)'"'==`""' markout `touse' `study', strok
	if `"`_BY'"'!=`""' {
		if `"`s(bymissing)'"'==`""' markout `touse' `by', strok
		
		// Form `bylist'
		qui levelsof `_BY' if `touse', missing local(bylist)	// "missing" since `touse' should already be appropriate for missing yes/no
	}	
	
	
	** Setup data and model(s)
	// - Parse inputted varlist structure and check for validity
	// - Parse models and modelling options
	cap nois ProcessData `_USE' `invlist' if `touse', summstat(`summstat') ///
		`eform' `log' `opts_adm' `touse2opt' // <-- this latter is a marker of being passed from -ipdmetan-

	if _rc {
		if `"`err'"'==`""' {
			if _rc==2000 nois disp as err "No studies found with sufficient data to be analysed"
			else if _rc==1 nois disp as err `"User break in {bf:metan.ProcessData}"'
			else nois disp as err `"Error in {bf:metan.ProcessData}"'
		}
		c_local err noerr
		exit _rc
	}

	local opts_adm `"`s(options)' `s(eform)' `s(log)'"'		// all other options (rationalised)
	local params = `s(params)'
	local eform    `s(eform)'		// needed later (just once) in this main routine, for return historical

	local rownames `s(rownames)'
	local qstat `s(qstat)'
	local citype `s(citype)'
	assert `"`citype'"'!=`""'
	return local citype `citype'		// citype is now established

	// internal options, to send to metan_analysis.ado
	local userwgt `s(userwgt)'
	local olduser `s(olduser)'
	
	// Finalize `effect'
	if `"`effect'"'==`""' local effect `"`s(effect)'"'	// don't override user-specified value
	if `"`effect'"'==`""' local effect "Effect"
	if `"`s(log)'"'!=`""' local effect `"log `effect'"'
	if `"`s(interaction)'"'!=`""' local effect `"Interact. `effect'"'

	// options to send to metan_output.ado	
	local output_opts `"`macval(output_opts)' effect(`"`effect'"') `s(labelopts)' `s(interaction)'"'
	// N.B. labelopts here are MODEL labels, not to be confused with LABTITLE()

	local m = `s(m)'
	local modellist `s(modellist)'
	local teststatlist `s(teststatlist)'
	return scalar m = `m'
	return local model `modellist'				// model(s) are now established
	forvalues j = 1 / `m' {
		local modelopts `"`macval(modelopts)' model`j'opts(`s(model`j'opts)')"'	// to pass to metan_analysis.ado
		if `m'==1 return local modelopts    `"`s(model`j'opts)'"'		// return model options
		else      return local model`j'opts `"`s(model`j'opts)'"'
	}
	
	local summstat `s(summstat)'	
	if      "`summstat'"=="cohend"  local measure "Cohen's d SMD"
	else if "`summstat'"=="glassd"  local measure "Glass's delta SMD"
	else if "`summstat'"=="hedgesg" local measure "Hedges's g SMD"
	else if "`summstat'"=="ftukey"  local measure "Freeman-Tukey transformed proportion"
	else if "`summstat'"=="arcsine" local measure "Arcsine-transformed proportion"
	else if "`summstat'"=="logit"   local measure "Logit-transformed proportion"
	else if "`summstat'"=="pr"      local measure "Untransformed proportion"
	else if "`summstat'"!=""        local measure = upper("`summstat'")
	return local measure `"`measure'"'
	
	// If 2x2 data, return tger and cger
	if `params'==4 {
		return scalar tger = `s(tger)'
		return scalar cger = `s(cger)'
		
		// Historical
		global S_13 = `s(tger)'
		global S_14 = `s(cger)'
	}

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
	
	// Basic option compatibility checks
	ParseOptions, modellist(`modellist') by(`_BY') `opts_adm'
	local opts_adm `"`s(newopts)' `s(options)'"'
	local keepvars `s(keepvars)'

	
	** Setup tempvars
	// The "core" elements of `outvlist' are _ES, _seES, _LCI, _UCI, _WT (plus _NN and _CC if appropriate)
	// By default, these will be left behind in the dataset upon completion of -metan-
	
	// _ES, _seES, _LCI and _UCI are *always* on the linear/interval scale, for pooling
	//   and so may need to be back-transformed to the original scale for display on-screen or in the forestplot.
	// Typically this just involves exponentiating; but for proportions using e.g. Freeman-Tukey,
	//   the back-transform is too complex, so we create separate variables _Prop_ES, _Prop_LCI, _Prop_UCI (`prvlist')
	//   containing the proportion and CI on the original scale.
	// `tvlist' = list of elements of `outvlist' that need to be generated as *tempvars* (i.e. do not already exist)
	//  (whilst ensuring that any overlapping elements in `invlist' and `outvlist' point to the same actual variables)
	
	cap nois SetupOutVList `invlist' if `touse', rownames(`rownames') `opts_adm'
	if _rc {
		if `"`err'"'==`""' {
			if _rc==1 nois disp as err `"User break in {bf:metan.SetupOutVList}"'
			else nois disp as err `"Error in {bf:metan.SetupOutVList}"'
		}
		c_local err noerr
		exit _rc
	}
	local opts_adm `"`s(options)'"'
	local xrownames `"`s(xrownames)'"'
	
	// Create tempvars based on `tvlist'
	//   and finally create `outvlist' = list of "standard" vars = _ES _seES _LCI _UCI _WT [_NN _CC]
	//   where _NN is optional if `params'==2 or 3 (excluding `proportion'; see above)
	//   and where _CC is optional if `params'==4 (or `proportion'; note that in either case, _NN must exist, so there is no ambiguity of argument names)
	local tvlist `s(tvlist)'
	foreach tv of local tvlist {
		tempvar `tv'
		qui gen double ``tv'' = .
	}
	tokenize `invlist' `s(nptsvar)'		// N.B. `s(nptsvar)' is only applicable with 2- or 3-variable syntax (ES seES or ES LCI UCI), in which case _CC is *not* applicable
	args `s(arglist)'
	local outvlist `_ES' `_seES' `_LCI' `_UCI' `_WT' `_NN' `_CC'
	if `"`s(intopt)'"'==`""' {
		cap recast int `_NN'		// `s(intopt)' records whether the -nointeger- option was supplied
	}
	cap recast byte `_CC'
		
	// If transformed proportions ("`summstat'"!="pr"), default is to display back-transformed effect sizes ("`nopr'"=="")
	// March 2021: Not applicable to `cumulative' or `influence'; this functionality is handled differently, see below
	local 0 `", `opts_adm'"'
	syntax [, PRoportion NOPR CUmulative INFluence * ]
	
	if `"`xrownames'"'!=`""' {
		local nt = `: word count `xrownames''
		forvalues i = 1 / `nt' {
			tempvar tv`i'
			qui gen double `tv`i'' = .
			local xoutvlist `xoutvlist' `tv`i''
		}
		local xv_opt xoutvlist(`xoutvlist')

		// March 2021: `prvlist' is a subset of `xoutvlist'
		if "`proportion'"!="" & "`summstat'"!="pr" & "`nopr'"=="" {
			local prvlist
			tokenize `xoutvlist'
			foreach el in prop_eff prop_lci prop_uci {
				local i : list posof `"`el'"' in xrownames
				local prvlist `prvlist' ``i''
			}
			local prv_opt prvlist(`prvlist')
		}
	}		
	else if "`proportion'"!="" & "`summstat'"!="pr" & "`nopr'"=="" {
		local prvlist
		forvalues i = 1 / 3 {	// _Prop_ES, _Prop_LCI, _Prop_UCI
			tempvar prv`i'
			qui gen double `prv`i'' = .
			local prvlist `prvlist' `prv`i''
		}
		local prv_opt prvlist(`prvlist')
	}

	// N.B. `xoutvlist' now contains the tempvars which will hold the relevant returned stats...
	//  - with the same contents as the elements of `rownames'
	//  - but *without* npts (as _NN is handled separately)
	//  - and with the addition of Q, Qdf, Q_lci, Q_uci, [sigmasq]
	//  - and with the addition of a separate weight variable (`_WT2') if cumulative/inflence

	// Subsequently, `rownames' will be passed between subroutines
	// and `xrownames' will be re-derived whenever needed
	// by taking `rownames' and applying the "algorithm" above.
	
	
	******************************************
	* Run the actual meta-analysis modelling *
	******************************************
	// ... and collect pooled statistics
	
	metan_analysis `_USE' `invlist' if `touse', `ifinopt' `touse2opt' `opts_adm' `prv_opt' `xv_opt' `forestplot' ///
		sortby(`sortby' `obs') summstat(`summstat') qstat(`qstat') citype(`citype') rownames(`rownames') ///
		teststatlist(`teststatlist') modellist(`modellist') outvlist(`outvlist') by(`_BY') ///
		`modelopts' /// list of options for each model, in the form "model`j'opts(`s(model`j'opts)')"
		`userwgt'   // internal option from ProcessData

	// Form final list of matrices to send to metan_output.ado
	forvalues j = 1 / `m' {
		cap {
			confirm matrix r(bystats`j')
			assert rowsof(r(bystats`j')) > 1
		}
		if _rc continue
		tempname bystats`j'
		matrix `bystats`j'' = r(bystats`j')
		local bystatslist `"`bystatslist' `bystats`j''"'
		if `m' > 1 local jj = `j'
		return matrix bystats`jj' = `bystats`j'', copy
	}
	if `"`bystatslist'"'!=`""' local mmatlist `"`mmatlist' bystatslist(`bystatslist')"'

	foreach x in ovstats hetstats byQ {
		cap {
			confirm matrix r(`x')
			assert rowsof(r(`x')) > 1
		}
		if !_rc {
			local lowerx = lower("`x'")
			tempname `x'
			matrix ``x'' = r(`x')
			local mmatlist `"`mmatlist' `lowerx'(``x'')"'
			return matrix `x' = ``x'', copy
		}
	}
	cap {
		confirm matrix r(mwt)
		assert rowsof(r(mwt)) == `m'
		assert colsof(r(mwt)) >= `r(nby)'					// r(nby) may be less than colsof(mwt) if missing subgroups
		assert colsof(r(mwt)) <= `: word count `bylist''	// `bylist' is the *maximum* number of subgroups to be analysed
	}
	if !_rc {
		tempname mwt
		matrix `mwt' = r(mwt)
		local mmatlist `"`mmatlist' mwt(`mwt')"'
		// N.B. don't return matrix `mwt'; this is for internal use only
	}	

	// Simple marker of whether above matrices exist; if not, no pooling has taken place
	if `"`mmatlist'"'==`""' local mmatlist nopool
	
	// Return other scalars (relevant to "primary" model)
	//  some of which are also saved in r(ovstats)
	return scalar k = r(k)
	return scalar n = r(n)
	
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

		gettoken model1 : modellist
		local RefREModList mp ml pl reml bt dlb		// random-effects models where a conf. interval for tausq is estimated
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
	
	if `"`bystatslist'"'!=`""' {
		return scalar tsq_common = r(tsq_common)
		return scalar Qsum = r(Qsum)
		return scalar Qbet = r(Qbet)
		return scalar F   = r(Fstat)
		return scalar nby = r(nby)
	}

	// User-defined estimates via "legacy" -metan- options first() and/or second()
	// These values were returned by subroutine ProcessModelOpts
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

	if `"`keepvars'"'!=`""' {		// tidy up [moved Jun 2022]
		cap drop `r(todrop)'
	}
	
	
	***********************************************
	* Outputs to screen, saved datasets and plots *
	***********************************************
	
	local qlist `r(Q)' `r(Qdf)' `r(Q_lci)' `r(Q_uci)' `r(Qsum)' `r(Qbet)' `r(nby)'
	local extra `r(nsg)' `r(nzt)'
	local outvlist `r(outvlist)'
	if `"`r(xoutvlist)'"'!=`""' {
		local xv_opt xoutvlist(`r(xoutvlist)')
		local oldvlist `r(oldvlist)'
	}
	if `"`sortby'"'==`""' local sorted nosorted	// for PrintDesc
	
	// Remove options not needed for metan_ouput but needed in main routine
	local 0 `", `opts_adm' `keepvars'"'
	syntax [, noPRESERVE noKEEPvars noRSample * ]
	local opts_adm `"`macval(options)'"'
	if `"`rsample'"'!=`""' local keepvars nokeepvars	// noRSample implies noKEEPVars

	// Now parse additional options needed in this part of the code (AND in metan_output)
	local 0 `", `opts_adm'"'
	syntax [, SAVING(passthru) CLEAR CLEARSTACK noGRaph KEEPAll KEEPOrder PREfix(name local) ILevel(cilevel) OLevel(cilevel) * ] 
	
	// July 2021: prefix() option
	if length("`prefix'") > 5 {
		disp as err `"{bf:prefix()} invalid; stub name too long ( >5 )"'
		exit 198
	}
	
	
	** Handle studies with insufficient data (_USE==2)
	// N.B. additional changes of `_USE' from 1 to 2 may have been done within metan_analysis (e.g. if no zero-cell corrections)
	if `"`keepall'`keeporder'"'==`""' {
		qui replace `touse' = 0 if `_USE'==2
		qui replace `touse2' = 0 if `_USE'==2
	}
	

	** Create and return matrix of coefficients
	// if cumul/influence, `outvlist' contains cumul/influence effect sizes
	// but r(coeffs) and saved variables should contain original study-specific effect sizes
	if `"`oldvlist'"'!=`""' tokenize `oldvlist'
	else tokenize `outvlist'
	args _ES _seES _LCI _UCI _WT _NN _CC	
	
	if `"`keepvars'"'!=`""' {
		
		// Maintain original order if requested
		if `"`keeporder'"'!=`""' {
			tempvar tempuse
			qui gen byte `tempuse' = `_USE'
			qui replace `tempuse' = 1 if `_USE'==2		// keep "insufficient data" studies in original study order (default is to move to end)
		}
		else local tempuse `_USE'		
		
		qui count if `touse'
		if r(N) > c(matsize) {
			disp `"{error}matsize too small to store matrix of study coefficients; this step will be skipped"'
			disp `"{error}  (see {bf:help matsize})"'
		}
		
		else {			
			// do this in a subroutine, so that we can use -sortpreserve-
			GetMatCoeffs `_BY' `_STUDY' `_ES' `_seES' `_NN' `_WT' if `touse', sortby(`_BY' `tempuse' `sortby' `obs')
			tempname coeffs
			matrix `coeffs' = r(coeffs)
			
			if `"`_BY'"'!=`""' local _BYexist _BY
			if `"`_NN'"'!=`""' local _NNexist _NN
			if `"`_WT'"'!=`""' local _WTexist _WT
			
			matrix colnames `coeffs' = `_BYexist' _STUDY _ES _seES `_NNexist' `_WTexist'			
			return matrix coeffs = `coeffs'
		}
	}

	// July 2021:
	// Only need to -preserve- if:
	// - saving a results set
	// - creating a forest plot
	// - clearing the original data, to leave the results set in memory
	if `"`saving'"'!=`""' | `"`clear'`clearstack'"'!=`""' | `"`graph'"'==`""' {

		// Note: if option -nopreserve- , assumption is that (original) data is *already* preserved (e.g. by -ipdmetan-)
		if `"`preserve'"'==`""' {
			local preserve_opt preserve
			`preserve_opt'
		}
	}
	
	metan_output `_USE' `invlist' if `touse', `touse2opt' `opts_adm' `prv_opt' `xv_opt' `forestplot' ///
		sortby(`sortby' `obs') `sorted' summstat(`summstat') qstat(`qstat') ///
		teststatlist(`teststatlist') modellist(`modellist') outvlist(`outvlist') ///
		`modelopts'            /// list of options for each model, in the form "model`j'opts(`s(model`j'opts)')"
		by(`_BY') `output_opts' /// by() bylist() study() plus suboptions relating to titling of tables etc.
		`mmatlist' qlist(`qlist') /// results matrices (including subgroups & heterogeneity) from "metan_analysis"
		extra(`extra') `r(mhallzero)' `r(clearnpts)' /* internal macros from metan_analysis */



	*************
	* Finish up *
	*************

	// exit early:
	// (1) if option -nopreserve- (e.g. if called from -ipdmetan- )
	// (2) if option "clear" (so no need for stored variables)
	if `"`clear'`clearstack'"'!=`""' | `"`preserve'"'!=`""'{
		if `"`preserve_opt'"'!=`""' {
			restore, not
		}
		exit
	}

	// Otherwise, restore "original" data (that is, original *observations* but with added tempvars);
	//   but preserve it again temporarily while "stored" variables are processed
	//   if all goes well, this -preserve- will be cancelled later with -restore, not- ...
	if `"`preserve_opt'"'!=`""' local restore_opt restore,
	`restore_opt' preserve
	
	
	** Stored (left behind) variables
	// Unless -noKEEPVars- (i.e. "`keepvars'"!=""), leave behind _ES, _seES etc. in the original dataset
	// List of these "permanent" names = _ES _seES _LCI _UCI _WT _NN ... plus _CC if applicable
	//   (as opposed to `outvlist', which contains the *temporary* names `_ES', `_seES', etc.)
	//   (N.B. this code applies whether or not cumulative/influence options are present)	
	if `"`keepvars'"'==`""' {
	
		// July 2021: _CC is defined within DrawTableAD using c_local
		local tostore _ES _seES _LCI _UCI _WT _NN _CC
		
		foreach v of local tostore {
			if `"``v''"'!=`""' {
				if `"``v''"'!=`"`prefix'`v'"' {		// If pre-existing var has the same name (i.e. was named _ES etc.), nothing needs to be done.
					cap drop `prefix'`v'			// Else, first drop any existing var named _ES (e.g. left over from previous analysis)
				
					// If in `tvlist', we can directly rename
					if `: list v in tvlist' {
						qui rename ``v'' `prefix'`v'
					}
					
					// Otherwise, ``v'' is a pre-existing var which needs to be retained at program termination
					// so, use -clonevar-
					else qui clonevar `prefix'`v' = ``v'' if `touse'
				}
				local `v' `prefix'`v'		// for use with subsequent code (local _ES now contains "_ES", etc.)
			}
			else cap drop `prefix'`v'		// in any case, drop existing vars named _ES etc.
		}
		// qui compress `tvlist'
		order `_ES' `_seES' `_LCI' `_UCI' `_WT' `_NN' `_CC' `_rsample', last
		
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
			qui gen byte _rsample = 0
			qui replace _rsample = `_USE' if inlist(`_USE', 1, 2)		// this shows which observations were used
			label variable _rsample "Sample included in most recent model"
		}		
	}	
	
	// else (if -noKEEPVars- specified), check for existence of pre-existing vars named _ES, _seES etc. and give warning if found
	else {
		cap confirm numeric var `_CC'
		if !_rc {
			local _CCexist _CC
			local ortext `", {bf:_NN} or {bf:_CC})"'
		}
		else local ortext `" or {bf:_NN}"'

		// If -noKEEPVars- but not -noRSample-, need to create _rsample as above
		if `"`rsample'"'==`""' {

			// create _rsample
			cap drop _rsample
			qui gen byte _rsample = 0
			qui replace _rsample = `_USE' if inlist(`_USE', 1, 2)		// this shows which observations were used
			label variable _rsample "Sample included in most recent model"
			
			local warnlist
			local rc = 111
			foreach v in _ES _seES _LCI _UCI _WT _NN `_CCexist' {
				cap confirm var `prefix'`v'
				if !_rc local warnlist `"`warnlist' {bf:`prefix'`v'}"'
				local rc = min(`rc', _rc)
			}
			if !`rc' {
				disp _n `"{error}Warning: option {bf:nokeepvars} specified, but the following "stored" variables already exist:"'
				disp `"{error}`warnlist'"'
				disp `"{error}Note that these variables are therefore no longer associated with the most recent analysis"'
				disp `"{error}(although {bf:`prefix'_rsample} {ul:is})."'
			}
		}
		
		// -noKEEPVars- *and* -noRSample-
		else {
		
			// give warning if variable named _rsample already existed
			cap confirm var `prefix'_rsample
			if !_rc {
				disp _n `"{error}Warning: option {bf:norsample} specified, but "stored" variable {bf:`prefix'_rsample} already exists"'
			}
			local rsrc = _rc

			local warnlist
			local rc = 111
			foreach v in _ES _seES _LCI _UCI _WT _NN _CC {
				cap confirm var `prefix'`v'
				if !_rc {
					local warnlist `"`warnlist' {bf:`prefix'`v'}"'
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


program define GetMatCoeffs, rclass sortpreserve
	syntax varlist [if] [in], [SORTBY(varlist)]	
	marksample touse, novarlist
	sort `touse' `sortby'
	tempname coeffs
	mkmat `varlist' if `touse', matrix(`coeffs')
	return matrix coeffs = `coeffs'
end		
		
		


********************************************************************************************************

** Routine to parse main options and forestplot options together, and:
//  a. Parse some general options, such as -eform- options and counts()
//  b. Check for conflicts between main options and forestplot() suboptions.
// (called directly by metan.ado)

* Notes:
// N.B. This program was originally designed to be used as a subroutine for both -metan- and -ipdmetan-
// Certain options may be supplied EITHER to -(ipd)metan- directly, OR as sub-options to forestplot()
//   with "forestplot options" prioritised over "main options" in the event of a clash.
// These options are:
// - effect/eform options parsed by CheckOpts (e.g. `rr', `rd', `md', `smd', `wmd', `log')
// - nograph, nohet, nobetween, nooverall, nosubgroup, nowarning, nowt, nostats, nopr
// - effect, hetinfo, lcols, rcols, plotid, ovwt, sgwt, sgweight
// - cumulative, efficacy, influence, interaction
// Plus, specifically for compatibility with metan9.ado:
// - counts, group1, group2, rfdist, rflevel, nobox, boxsca(#), force

program define ParseFPlotOpts, sclass

	** Parse top-level summary info and option lists
	// Note June 2022: touse() is only here for use with `plotid', see below
	syntax [, CMDNAME(string) TOUSE(varname numeric) OPTIONS(string asis) FORESTplot(string asis)]
		
	
	** Plot-related options valid with -metan- version 4 only
	local badopts0 ADJust LCOLSCHeck NAmes NULL TRUNCate
	local badopts1 COLSONLY KEEPXLabs LEFTJustify USESTRICT
	local badopts2 ADDHeight CIRAnge DATAID FP MAXWidth MAXLines NLINEOPts OCILINEOPts
	local badopts2 `badopts2' RAnge RFOPts RFCILINEOPts SAVEDIms SPacing TArget USEDIms

	local nobadopts0
	foreach op of local badopts0 {				// optionally off (badopts1 = optionally on)
		local nobadopts0 `nobadopts0' no`op'
	}	
	local badopts2p
	foreach op of local badopts2 {				// content in brackets
		local badopts2p `badopts2p' `op'(passthru)
	}

	local 0 `", `options'"'
	syntax [, `nobadopts0' `badopts1' `badopts2p' * ]
	
	foreach op of local badopts0 {
		local lop = lower(`"`op'"')
		if `"``lop''"'!=`""' {
			nois disp as err _n `"Option {bf:no``lop''} may only be supplied as a sub-option to the {bf:forestplot()} option; see {help metan:help metan}"'
			exit 198
		}
	}
	foreach op of local badopts1 {
		local lop = lower(`"`op'"')
		if `"``lop''"'!=`""' {
			nois disp as err _n `"Option {bf:``lop''} may only be supplied as a sub-option to the {bf:forestplot()} option; see {help metan:help metan}"'
			exit 198
		}
	}
	foreach op of local badopts2 {
		local lop = lower(`"`op'"')
		if `"``lop''"'!=`""' {
			nois disp as err _n `"Option {bf:``lop''()} may only be supplied as a sub-option to the {bf:forestplot()} option; see {help metan:help metan}"'
			exit 198
		}
	}
	
	
	** Quick initial parse, to extract specific options and correct for synonyms etc.
	local 0 `", `options'"'
	syntax [, EFFect(string asis) ///
		HETINFO(string) HETStat(string) OVStat(string) /// /* N.B. `hetstat' and `ovstat' are legacy synonyms for `hetinfo' */
		OVWt SGWt OVWEIGHT SGWEIGHT /// /* synonyms */
		COUNTS2 COUNTS(string asis) GROUP1(passthru) GROUP2(passthru) * ]
		/* ^^ modern syntax has "group1" and "group2" as sub-options to "count"; older syntax had them as separate options */

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
		if _rc==1 nois disp as err `"User break in {bf:metan.CheckOpts}"'
		else nois disp as err `"Error in {bf:metan.CheckOpts}"'
		c_local err noerr		// tell main program not to also report an error in ParseFPlotOpts
		exit _rc
	}

	local eform     `"`s(eform)'"'
	local log       `"`s(log)'"'
	local summstat  `"`s(summstat)'"'
	if `"`effect'"'==`""' local effect `"`s(effect)'"'
	// N.B. `s(effect)' contains automatic effect text from -eform-; `effect' contains user-specified text
	
	
	** Main parse of options supplied directly to -(ipd)metan- 
	local optlist0 GRaph HET BETWeen OVerall SUbgroup WARNing WT STATs BOX					// "stand-alone" options: optionally-off
	local optlist1 CUmulative INFluence INTERaction EFFIcacy RFDist	OVWt SGWt FORCE NOPR	// "stand-alone" options: optionally-on (note "NOPR")
	local optlist2 PLOTID HETINFO RFLevel COUNTS BOXSCale EXTRALine							// options requiring content within brackets (passthru)
	local optlist3 LCOLS RCOLS 																// options which cannot conflict
	
	local nooptlist0
	foreach op of local optlist0 {
		local nooptlist0 `nooptlist0' no`op'
	}
	local optlist2p
	foreach op of local optlist2 {
		local optlist2p `optlist2p' `op'(passthru)
	}
	local optlist3p
	foreach op of local optlist3 {
		local optlist3p `optlist3p' `op'(passthru)
	}
	
	local 0 `", `s(options)' `counts' `ovwt' `sgwt' `hetinfo'"'
	syntax [, `nooptlist0' `optlist1' `optlist2p' `optlist3p' * ]
	local opts_main `"`macval(options)'"'
	
	if `"`forestplot'"'!=`""' {
	
		// Need to temp rename options which may be supplied as either "main options" or "forestplot options"
		//  (N.B. `effect' should be part of `optlist2', but needs to be treated slightly differently)
		local optlist `optlist0' `optlist1' `optlist2' `optlist3' effect
		foreach opt of local optlist {
			local lopt = lower(`"`opt'"')
			local `lopt'_main : copy local `lopt'
		}
		
		** Quick initial parse, to extract specific options and correct for synonyms etc.
		local 0 `", `forestplot'"'
		syntax [, EFFect(string asis) ///
			HETINFO(string) HETStat(string) OVStat(string) /// /* N.B. `hetstat' and `ovstat' are legacy synonyms for `hetinfo' */
			OVWt SGWt OVWEIGHT SGWEIGHT /// /* synonyms */
			COUNTS2 COUNTS(string asis) GROUP1(passthru) GROUP2(passthru) * ]
			/* ^^ modern syntax has "group1" and "group2" as sub-options to "count"; older syntax had them as separate options */

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
		
		// Process -counts- options
		if `"`counts'"' != `""' {
			local group1_fplot : copy local group1
			local group2_fplot : copy local group2
			local 0 `", `counts'"'
			syntax [, COUNTS GROUP1(passthru) GROUP2(passthru) ]
			foreach opt in group1 group2 {
				if `"``opt''"'!=`""' & `"``opt'_fplot'"'!=`""' & `"``opt''"'!=`"``opt'_fplot'"' {
					disp `"{error}Note (referring to {bf:forestplot()} option): Conflicting option {bf:`opt'()}; {bf:counts()} suboption will take priority"' 
				}
				if `"``opt''"'==`""' & `"``opt'_fplot'"'!=`""' local `opt' : copy local `opt'_fplot
				local `opt'_fplot
			}
		}
		else local counts : copy local counts2
		if `"`counts'"'!=`""' local counts `"counts(counts `group1' `group2')"'		// counts(counts...) so that contents are never null
		local group1
		local group2
		
		// Process -eform- for forestplot, and check for clashes/prioritisation
		cap nois CheckOpts `cmdname', soptions opts(`opts_fplot')
		if _rc {
			if _rc==1 nois disp as err `"User break in {bf:metan.CheckOpts}"'
			else nois disp as err `"Error in {bf:metan.CheckOpts}"'
			c_local err noerr		// tell main program not to also report an error in ParseFPlotOpts
			exit _rc
		}
		
		
		** Main parse of options supplied within -forestplot- option 
		local 0 `", `s(options)' `counts' `ovwt' `sgwt' `hetinfo'"'
		syntax [, `nooptlist0' `optlist1' `optlist2p' `optlist3p' * ]
		local opts_fplot `"`macval(options)'"'
		
		if `"`summstat'"'!=`""' & `"`s(summstat)'"'!=`""' & `"`summstat'"'!=`"`s(summstat)'"' {
			nois disp as err `"Conflicting summary statistics supplied to {bf:metan} and to {bf:forestplot()}"'
			exit 184
		}
	
		// Finalise locals & scalars as appropriate; forestplot options take priority
		local eform = cond(`"`s(eform)'"'!=`""', `"`s(eform)'"', cond(trim(`"`log'`s(log)'"')!=`""', `""', `"`eform'"'))
		local log = cond(`"`s(log)'"'!=`""', `"`s(log)'"', `"`log'"')
		local summstat = cond(`"`s(summstat)'"'!=`""', `"`s(summstat)'"', `"`summstat'"')
		if `"`effect'"'==`""' local effect `"`s(effect)'"'
		// N.B. `s(effect)' contains automatic effect text from -eform-; `effect' contains user-specified text
	}
	
	// `optlist0' and `optlist1':  allowed to conflict, but forestplot will take priority
	foreach opt in `optlist0' `optlist1' {
		local lopt = lower(`"`opt'"')
		if `"``lopt''"'==`""' & `"``lopt'_main'"'!=`""' local `lopt' : copy local `lopt'_main
		if `"``lopt''"'!=`""' {
			if inlist("`opt'", "BOX", "FORCE") {
				local opts_fplot `"`macval(opts_fplot)' ``lopt''"'
			}
			else local opts_parsed `"`macval(opts_parsed)' ``lopt''"'
		}
	}
	
	// `optlist2': Same, but this time display warning for options requiring content within brackets (`optlist2')
	foreach opt in `optlist2' effect {
		local lopt = lower(`"`opt'"')		
		if `"``lopt'_main'"'!=`""' {
			if `"``lopt''"'!=`""' {
				if `"``lopt''"'!=`"``lopt'_main'"' {
					disp `"{error}Note: Conflicting option {bf:`lopt'()}; {bf:forestplot()} suboption will take priority"' 
				}
			}
			else local `lopt' : copy local `lopt'_main
		}
		
		// Don't add `effect' to opts_parsed; needed separately in main routine
		if `"``lopt''"'!=`""' & "`lopt'"!="effect" {
			if "`opt'"=="BOXSCale" {
				local opts_fplot `"`macval(opts_fplot)' ``lopt''"'
			}
			else local opts_parsed `"`macval(opts_parsed)' ``lopt''"'
		}
	}

	// `optlist3':  these *cannot* conflict (also see `summstat' above)
	foreach opt in `optlist3' {
		local lopt = lower(`"`opt'"')
		if `"``lopt'_main'"'!=`""' {
			if `"``lopt''"'!=`""' {
				cap assert `"``lopt''"'==`"``lopt'_main'"'
				if _rc {
					nois disp as err `"Conflicting option {bf:`lopt'()} supplied to {bf:metan} and to {bf:forestplot()}"'
					exit 184
				}
				local `lopt'
			}
		}
		if `"``lopt'_main'``lopt''"'!=`""' {
			local opts_parsed `"`macval(opts_parsed)' ``lopt'_main'``lopt''"'
		}
	}
	
	// May 2020: parse for options of the form "[plot]#opts" outside of forestplot() option
	// If found, exit with error
	// Note: do this *after* finalizing possible plotid() options in opts_main and in opts_fplot
	if `"`plotid'"'!=`""' {
		local 0 `", `plotid'"'
		syntax [, PLOTID(string) ]
		local 0 `plotid'
		syntax varname [, *]
		qui levelsof `varlist' if `touse'
		CheckPlotIDOpts, plotid(`r(levels)') `opts_main'
	}
	
	// Return locals
	sreturn clear
	sreturn local effect `"`effect'"'
	sreturn local eform    `eform'
	sreturn local log      `log'
	sreturn local summstat `summstat'

	sreturn local options     `"`macval(opts_main)'"'
	sreturn local opts_fplot  `"`macval(opts_fplot)'"'
	sreturn local opts_parsed `"`macval(opts_parsed)'"'
	
end


* CheckPlotIDOpts
// May 2020: parse for options of the form "[plot]#opts"
// If found, exit with error

program define CheckPlotIDOpts

	syntax, [ PLOTID(numlist integer) * ]

	local badopts box diam point ci oline nline ociline rf rficline
	local 0 `", `options'"'
	foreach p of local plotid {
		local optlist
		foreach op of local badopts {
			local uop = upper("`op'")
			local optlist `optlist' `uop'`p'opts(passthru)
		}
		syntax [, `optlist' * ]
		foreach op of local badopts {
			if `"``op'`p'opts'"'!=`""' {
				nois disp as err _n `"Option {bf:`op'`p'opts()} may only be supplied as a sub-option to the {bf:forestplot()} option; see {help metan:help metan}"'
				exit 198
			}
		}
	}
	
end


* CheckOpts
// Based on the built-in _check_eformopt.ado,
//   but expanded from -eform- to general effect specifications.
// This program is used by -metan- and -forestplot- , and also by -ipdmetan-
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

program define SetupOutVList, sclass

	// Locals needed for reference, but not to be altered:
	syntax varlist [if] [in], [ TOUSE2(passthru) LOGRank PRoportion ILevel(cilevel) noINTeger * ]
	
	syntax varlist [if] [in], [ NPTS(string) ROWNAMES(namelist) * ]		// do not return these options within s(options)
	marksample touse, novarlist
	tokenize `varlist'
	local params : word count `varlist'
	local opts_adm `"`macval(options)'"'
	
	// Optional "npts(varname)": only permitted with 2- or 3-element varlist AD;
	// that is, "ES, seES", "ES, LCI, UCI", or "OE, V"
	if `"`npts'"'!=`""' {
		if `params' > 3 | "`proportion'"!="" {
			if `"`touse2'"'!=`""' local orwith `" or with logrank (O-E & V) HR"'		// if passed from -ipdmetan-
			nois disp as err `"option {bf:npts(}{it:varname}{bf:)} syntax only valid with generic inverse-variance model`orwith'"'
			nois disp as err `"maybe the option {bf:npts} was intended?"'
			exit 198
		}

		local old_integer `integer'
		local 0 `"`npts'"'
		syntax varname(numeric) [, noPlot noINTeger]
		local nptsvar `varlist'
		if `"`integer'"'==`""' local integer `old_integer'
		
		if `"`integer'"'==`""' {
			cap assert int(`nptsvar')==`nptsvar' if `touse'
			if _rc {
				nois disp as err `"Non-integer counts found in {bf:npts()} option"'
				exit _rc
			}
		}
		if `"`plot'"'==`""' local nptsflag npts					// send simple on/off option to BuildResultsSet (e.g. for forestplot)
		local _NN _NN
	}
	
	// Now assemble `tvlist'
	if `"`logrank'"'!=`""' {
		local arglist OE V `_NN'			 	// OE and V supplied (optional `_NN')
		local tvlist _ES _seES _LCI _UCI		// ...need to create everything (except _NN)
	}
	else if `"`proportion'"'!=`""' {
		local arglist succ _NN					// n and N supplied (latter is _NN)
		local tvlist _ES _seES _LCI _UCI _CC	// ...need to create everything (except _NN) including _CC
	}
	else if `params'==2 {
		local arglist _ES _seES `_NN'			// `_ES' and `_seES' supplied (optional `_NN')
		local tvlist _LCI _UCI					// `_LCI', `_UCI' need to be created (at `ilevel'%)
	}
	else if `params'==3 {
		local arglist _ES _LCI _UCI `_NN'		// `_ES', `_LCI' and `_UCI' supplied (assumed 95% CI); optional `_NN'
		
		local tvlist _seES						// `_seES' needs to be created
		if `ilevel'!=c(level) {					// but if ilevel() option supplied, requesting coverage other than 95% ...
			local tvlist `tvlist' _LCI _UCI		// ... then tempvars for _LCI, _UCI are needed too
		}
	}
	else {
		local tvlist _ES _seES _LCI _UCI _NN		// `params'==4 or 6: need to create everything, including _NN...
		if `params'==4 local tvlist `tvlist' _CC	// ...including _CC if `params'==4
	}
	
	// Finally, _WT always needs to be generated as tempvar
	local tvlist `tvlist' _WT

	// If cumulative or influence, need to generate additional tempvars.
	// `xoutvlist' ("extra" outvlist) contains results of each individual analysis
	//   to be printed to screen, displayed in forestplot and stored in saved dataset.
	//   (plus Q, tausq, sigmasq, df from each analysis.)
	// Meanwhile `outvlist' contains effect sizes etc. for each individual *study*, as usual,
	//   which will be left behind in the current dataset.
	
	// Nov 2021: a simplified version of `xoutvlist' is also needed if `summaryonly' and saving()/clear.
	
	// Return locals
	sreturn clear
	sreturn local tvlist `tvlist'
	sreturn local arglist `arglist'
	if `"`_NN'"'!=`""' {
		sreturn local nptsvar `nptsvar'
		sreturn local intopt `integer'
	}
	sreturn local options `"`macval(opts_adm)' `nptsflag'"'

	GetXRowNames `rownames', `opts_adm'		// returns s(xrownames)	
end

	
program define GetXRowNames, sclass

	syntax namelist(name=rownames) [ , CUmulative INFluence SUMMARYONLY SAVING(passthru) CLEAR CLEARSTACK * ]
	if `"`clearstack'"'!=`""' local clear clearstack
	
	// Note: a simplified version of `xoutvlist' is also needed if `summaryonly' and saving()/clear
	if `"`cumulative'`influence'"'!=`""' ///
		| (`"`summaryonly'"'!=`""' & !(`"`saving'"'==`""' & `"`clear'"'==`""')) {

		local toremove npts
		if `"`cumulative'`influence'"'==`""' {
			local toremove `toremove' eff se_eff eff_lci eff_uci
		}
		local xrownames : copy local rownames
		local xrownames : list xrownames - toremove
		local xrownames `xrownames' Q Qdf Q_lci Q_uci
		if `: list posof "tausq" in rownames' local xrownames `xrownames' sigmasq
		if `"`cumulative'`influence'"'!=`""' {
			local xrownames `xrownames' _WT2
		}
		sreturn local xrownames `xrownames'
	}
end
	
	
* Program to process `study' and `by' labels
// (called directly by metan.ado)

program define ProcessLabels, sclass sortpreserve

	syntax varlist(numeric min=2 max=6) [if] [in], SORTBY(varlist) ///
		NEWSTUDY(name) NEWSTUDYLAB(name) NEWBY(name) NEWBYLAB(name) ///
		[ STUDY(string) LABTITLE(string asis) LABEL(string) BY(string) LCols(namelist) SUMMARYONLY INFluence * ]

	marksample touse, novarlist		// `novarlist' option so that entirely missing/nonexistent studies/subgroups may be included
	local invlist `varlist'			// list of "original" vars passed by the user to the program 
	
	local opts_adm : copy local options
	

	** Parse `by'
	// N.B. do this before `study' in case `by' is string and contains missings.
	// Stata sorts string missings to be *first* rather than last.
	if `"`by'"'!=`""' {
		local 0 `"`by'"'
		syntax name [, Missing ]		// only a single (var)name is allowed

		cap confirm var `namelist'
		if _rc {
			nois disp as err `"error in option {bf:by()}: "' _c
			confirm var `namelist'
		}
		local _BY `namelist'		// `"`_BY'"'!=`""' is a marker of `by' being present in the current data
		local bymissing `missing'
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
					nois disp as err `"error in option {bf:label()}: "' _c
					confirm var `3'
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
				nois disp as err `"option {bf:label()} not supplied; variable {bf:`_STUDY'} in option {bf:lcols()} not found or ambiguous abbreviation"'
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
		syntax varname [, Missing ]
		local _STUDY `varlist'
		if `"`missing'"'==`""' markout `touse' `_STUDY', strok
	}

	// Dec 2020: If labelled-integer, format length may also have an effect on the displayed string
	// Hence, *always* save format length to apply to _LABELS later
	confirm variable `_STUDY'
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
			local svarlab : variable label `_STUDY'				// extract original variable label...
			if `"`svarlab'"'==`""' local svarlab `_STUDY'		// ...or varname
			label variable `newstudy' `"`svarlab'"'
			label values `newstudy' `newstudylab'
			local _STUDY `newstudy'
		}
		
		if !`rc_by' {
			local byvarlab : variable label `_BY'				// extract original variable label...
			if `"`byvarlab'"'==`""' local byvarlab `_BY'		// ...or varname
			label variable `newby' `"`byvarlab'"'
			label values `newby' `newbylab'
			local _BY `newby'
		}
	}
		
	// Check that `_STUDY' and `_BY' are not identical
	confirm numeric variable `_STUDY'
	cap assert `"`_STUDY'"'!=`"`_BY'"'
	if _rc {
		nois disp as err `"the same variable cannot be used in both {bf:study()} and {bf:by()}"'
		exit 184
	}
	
	
	** Titles	
	if `"`labtitle'"'==`""' {
		if `"`influence'"'!=`""' local omitted " omitted"
		
		local svarlab : variable label `_STUDY'			// Note: `_STUDY' is guaranteed to exist (but might have no varlabel)
		if `"`svarlab'"'==`""' & `"`summaryonly'"'==`""' local svarlab Study
		local labtitle `"`svarlab'`omitted'"'
		
		if `"`_BY'"'!=`""' {
			confirm numeric variable `_BY'
			local byvarlab : variable label `_BY'
			if `"`byvarlab'"'==`""' local byvarlab Subgroup
			
			if `"`summaryonly'"'!=`""' local labtitle `"`byvarlab'"'	// NEW Mar 2022
			else local labtitle `"`byvarlab' and `svarlab'`omitted'"'
		}
	}	

	// Return
	sreturn clear
	sreturn local by `_BY'
	sreturn local bymissing `bymissing'
	sreturn local study `_STUDY'
	sreturn local smissing `missing'
	sreturn local sfmtlen `sfmtlen'
	sreturn local lcols `lcols'
	sreturn local labtitle `"`labtitle'"'
	
end



* Program to parse inputted varlist structure and
// - identify studies with insufficient data (`_USE'==2)
// - check for validity
// (called directly by metan.ado)

// ...and then to parse models and modelling options
// via subroutine "ProcessModelOpts"

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

program define ProcessData, sclass
	
	syntax varlist(numeric min=3 max=7 default=none) [if] [in] [, SUMMSTAT(name) TOUSE2(passthru) ///
		COHend GLAssd HEDgesg noSTANdard TRansform(string) FTT /// model options (`ftt' included for compatibility with -metaprop-)
		CORnfield EXact WOolf CItype(name) CIMEThod(name)  /// individual study CI options///
		/*options which can be checked against `summstat' and/or `params' for "quick wins", since not model-dependent*/ ///
		INTERaction EFORM LOG ZTOL(real 1.0x-1a) * ]
	
	local opts_adm `"`macval(options)'"'
	
	// if missing values in `invlist', set _USE==2 immediately
	gettoken _USE invlist : varlist
	marksample touse, novarlist
	foreach v of local invlist {
	    qui replace `_USE' = 2 if `touse' & missing(`v')
	}	
	
	// Now parse options needed for reference only; pass these back to main routine as-is
	local 0 `", `opts_adm'"'
	syntax [, BREslow TArone CMH CMHNocc CHI2 CC(passthru) noCC2 NPTS ///
		LOGRank PRoportion NOPR DENOMinator(string) noINTeger MH PETO * ]
	
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
				if "`npts'"!="" {		// [MOVED HERE AUG 2021]
					nois disp as err _n `"Option {bf:npts} is not appropriate with logrank OE & V data"'
					nois disp as err `"maybe the option {bf:npts(}{it:varname}{bf:)} was intended?"'
					exit 198
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
					cap assert `denominator' > 0
					if _rc {
						nois disp as err `"Error in option {bf:denominator(#)}: value must be greater than zero"'
						exit 198
					}
					if `denominator'==1 local effect "Proportion"
					else if `denominator'==100 local effect "Percentage"
					else local effect `"Events per `denominator' obs."'
				}
				if "`nopr'"!="" local effect "Transformed proportion"
				
				args succ _NN
				cap assert `succ'<=`_NN' if `touse' & !missing(`succ')
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
				/*
				else if !inlist(`"`citype'"', `""', `"wald"') {
					nois disp as err `"Cannot specify {bf:citype(`citype')} with {bf:nointeger}"'
					exit 198
				}
				*/
				// DF July 2021: Removed; since CIs for proportions may have to be generated manually anyway (see GenConfIntsPr)
				// there is no real need for this restriction
				
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
				syntax [name(name=transform id="transform" ) ] [, N(string) POVERV(real 2) Arithmetic Geometric Harmonic IVariance INVVariance ]
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
							nois disp as err `"In option {bf:transform(ftukey, n(}{it:#}{bf:))}, {it:#} must be > 0 and non-missing"'
							exit 198
						}
						if `"`arithmetic'`geometric'`harmonic'`ivariance'`invvariance'"'!=`""' {
							local erropt : word 1 of `arithmetic' `geometric' `harmonic' `ivariance' `invvariance'
							nois disp as err `"option {bf:transform()} invalid;"'
							nois disp as err `"only one of {bf:n(}{it:#}{bf:)} or {bf:`erropt'} is allowed"'
							exit 184
						}
					}
					else {
						opts_exclusive `"`arithmetic' `geometric' `harmonic' `ivariance' `invvariance'"' transform 184
						local n `arithmetic'`geometric'`harmonic'`ivariance'`invvariance'
						if `"`n'"'==`"invvariance"' local n ivariance		// these are synonyms
					}					
					if `"`n'"'==`"ivariance"' {
						cap {
							confirm number `poverv'
							assert `poverv' >= 0 & !missing(`poverv')
						}
						if _rc {
							nois disp as err `"In option {bf:transform(ftukey, ivariance poverv(}{it:#}{bf:))}, {it:#} must be >= 0 and non-missing"'
							exit 198
						}
					}
					local tnopt `"tn(`n') poverv(`poverv')"'
				}
				else {
					if `"`n'"'!=`""' {
						nois disp as err `"option {bf:transform()} invalid;"'
						nois disp as err `"option {bf:n(}#{bf:)} only allowed with {bf:transform(ftukey)}"'
						exit 198
					}
					if `"`arithmetic'`geometric'`harmonic'`ivariance'`invvariance'"'!=`""' {
						local erropt : word 1 of `arithmetic' `geometric' `harmonic' `ivariance' `invvariance'
						nois disp as err `"option {bf:transform()} invalid;"'
						nois disp as err `"option {bf:`erropt'} only allowed with {bf:transform(ftukey)}"'
						exit 198
					}
					if "`summstat'"=="" local summstat pr
				}
				
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
				if "`npts'"!="" {		// [MOVED HERE AUG 2021]
					nois disp as err _n `"Option {bf:npts} is not appropriate without proportion or 2x2 count data"'
					nois disp as err `"maybe the option {bf:npts(}{it:varname}{bf:)} was intended?"'
					exit 198
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
			qui replace `_USE' = 2 if `touse' & (`e1' + `f1')*(`e0' + `f0')==0		// No data AT ALL in at least one arm (i.e. `r1'==0 or `r0'==0)
			/*
			if "`summstat'"!="rd" {																// i.e. `r1'==0 or `r0'==0

				// M-H RR: double-zero *non*-event (i.e. ALL events in both arms; unusual but not impossible) is OK
				if "`summstat'"=="rr" qui replace `_USE' = 2 if `touse' & `e1' + `e0'==0
				
				// Else: any double-zero
				else qui replace `_USE' = 2 if `touse' & (`e1' + `e0'==0 | `f1' + `f0'==0)
			}
			*/
		}		// end of binary variable setup

		// log only allowed if OR, RR, RRR, HR, SHR, TR
		if "`log'"!="" {
			cap assert (`params'==4 & "`summstat'"!="rd") | "`logrank'"!="" | "`touse2'"!=""
			if _rc {
				disp `"{error}{bf:log} may only be specified with 2x2 count data or log-rank HR; option will be ignored"'
				local log
			}
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
		
        cap assert `n1'>=0 & `n0'>=0 if `touse'
		if _rc {
			nois disp as err "Non-positive sample sizes found" 
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
		
	
	** Identify models
	// Process meta-analysis modelling options
	// (random-effects, test & het stats, etc.)
	// Could be given in a variety of ways, e.g. stand-alone options, random(), second(), model() etc.
	cap nois ProcessModelOpts, `opts_adm' `tnopt' summstat(`summstat') /*`summorig'*/ params(`params')
	if _rc {
		if `"`err'"'==`""' {
			if _rc==1 nois disp as err `"User break in {bf:metan.ProcessModelOpts}"'
			else nois disp as err `"Error in {bf:metan.ProcessModelOpts}"'
		}
		c_local err noerr		// tell main program not to also report an error in ProcessData
		exit _rc
	}

	// Note: sclass is cleared by ProcessModelOpts
	// ...and since sclass is static, no need to repeat "sreturn local" here
	/*
	sreturn local rownames     `s(rownames)'
	sreturn local modellist    `s(modellist)'
	sreturn local teststatlist `s(teststatlist)'
	sreturn local qstat        `s(qstat)'
	sreturn local wgtoptlist   `s(wgtoptlist)'		// to send to DrawTableAD
	sreturn local labelopts  `"`s(labelopts)'"'		// [Nov 2020] list of labelling options	

	local m = `s(m)'
	forvalues j = 1 / `m' {
		sreturn local model`j'opts `"`s(model`j'opts)'"'
	}
	*/
	
	if `params'==4 {
		if `"`s(summnew)'"'==`"or"' {	// corrective macro: only applies to 2x2 count data; is either "or" or nothing
			local summstat or
			local effect `"Odds Ratio"'
		}
		else if `"`summstat'"'==`""' {
			local summstat rr
			local effect `"Risk Ratio"'
		}
	
		// Finalize studies with insufficient data (`_USE'==2)
		// (following possible corrective macro `summnew')
		if "`summstat'"!="rd" {
		
			// RR: double-zero *non*-event (i.e. ALL events in both arms; unusual but not impossible) is OK
			if "`summstat'"=="rr" qui replace `_USE' = 2 if `touse' & `e1' + `e0'==0
			
			// Else: any double-zero
			else qui replace `_USE' = 2 if `touse' & (`e1' + `e0'==0 | `f1' + `f0'==0)
		}
		
		// If `params'==4, default to eform unless Risk Diff...
		if `"`summstat'"'!=`"rd"' & `"`log'"'==`""' local eform eform
	}	
	// ...similarly, if `logrank' then default to log
	else if `"`logrank'"'!=`""' & `"`eform'"'==`""' local log log
	
	// summstat should be NON-MISSING *UNLESS* "generic" es/se
	if `params' > 3 | `"`logrank'"'!=`""' {
		assert `"`summstat'"'!=`""'
	}
	
	// Finalize citype
	if inlist(`"`citype'"', `""', `"z"') local citype normal
	
	sreturn local effect `"`effect'"'
	sreturn local summstat `summstat'
	sreturn local params   `params'
	sreturn local citype   `citype'
	sreturn local eform    `eform'
	sreturn local log      `log'
	sreturn local interaction `interaction'

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
	
	syntax, PARAMS(passthru) [ SUMMSTAT(passthru) TN(passthru) POVERV(passthru) ///
		/// /* Test (`teststat') and heterogeneity (`hetstat') statistics */
		T Z CHI2 CMH CMHNocc BREslow TArone COCHranq ///
		/// /* Other "global" options, for passing to ParseModel */
		CC(string) noCC2 WGT(passthru) * ]
	
	
	** First, sort out:
	// - legacy -metan- options first() and second()
	// - options permitted outside of model() option (either legacy -metan- or otherwise) 
	cap nois ProcessFirstSecond, `params' `options'
	if _rc {
		if _rc==1 nois disp as err `"User break in {bf:metan.ProcessFirstSecond}"'
		else nois disp as err `"Error in {bf:metan.ProcessFirstSecond}"'
		c_local err noerr		// tell -metan- not to also report an "error in metan.ProcessModelOpts"
		exit _rc
	}
	
	local opts_adm `"`s(options)'"'
	local model    `"`s(model)'"'
	local olduser    `s(olduser)'
	
	// Internal macro lists
	local teststat `t' `z' `chi2' `cmh' `cmhnocc'
	local qstat `breslow' `tarone' `cochranq'
	opts_exclusive `"`teststat'"' `""' 184
	opts_exclusive `"`qstat'"'    `""' 184

	if `"`cc'"'!=`""' local ccopt `"cc(`cc')"'
	else local ccopt `cc2'
	
	// Now parse options needed for reference only; pass these back to main routine as-is
	local 0 `", `opts_adm'"'
	syntax [, RFDist CUmulative INFluence LOGRank PRoportion * ]

	
	
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
			cap assert "`bs'"=="\"
			if _rc {
				nois disp as err `"Multiple models or heterogeneity estimators must be specified in the following form (see {help metan_model}):"'
				nois disp as err `"  {bf:model(} {it:model} [ {bf:\} {it:model} [ {bf:\} {it:model} [...]]] {bf:)}"'
				exit 198
			}
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
	    local first = cond(`j'==1, "first", "")			// marker of this model being the first/main/primary model
		cap nois ParseModel `model`j'' `summstat' `params' `logrank' `proportion' `tn' `poverv' `first' ///
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

		// corrective macro: only applies to 2x2 count data; is either "or" or nothing
		if `"`s(summnew)'"'!=`""' {
			assert `"`summstat'"'==`""'
			local summnew `s(summnew)'
			local summstat summstat(`summnew')
		}
		
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
	if "`proportion'"!="" {
		local 0 `", `summstat'"'
		syntax, SUMMSTAT(name)
		if "`summstat'"!="pr" local rownames `rownames' prop_eff prop_lci prop_uci
	}
	
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
	sreturn local options `"`macval(opts_adm)'"'	// non model-specific options
	sreturn local rownames     `rownames'
	sreturn local modellist    `modellist'
	sreturn local teststatlist `teststatlist'
	sreturn local qstat        `qstat'
	sreturn local summnew      `summnew'		// corrective macro: only applies to 2x2 count data; is either "or" or nothing
	sreturn local labelopts  `"`labelopts'"'	// Nov 2020
	
	forvalues j = 1 / `m' {
		sreturn local model`j'opts `"`model`j'opts'"'
	}
	sreturn local m `m'

	// Internal markers
	if "`wgt'"!="" {
		sreturn local userwgt userwgt		// marker of user-defined weights, c.f. previous versions of -metan-
	}
	sreturn local olduser `olduser'		// marker that "legacy" -metan- options first() and/or second() were supplied

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
			cap syntax [, FIXEDI FIXED IVariance INVVariance IVCommon COMMON RANDOMi MHaenszel PETO ]
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
		RANDOM1 RANDOM(string) RE1 RE(string) RANDOMI ///			// synonyms for D+L random-effects inverse-variance
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
	sreturn local options `"`opts_adm' `logrank'"'
	
	if `"`first'"'!=`""' {
		local model : copy local first
	}
	if `"`second'"'!=`""' {
	    if `"`model'"'==`""' local model null		// temporary marker; will be re-parsed later
		local model `"`model' \ `second'"'
	}
	sreturn local model `"`model'"'
	sreturn local olduser `olduser'		// internal marker that "legacy" -metan- options first() and/or second() were supplied
	
end




// Simply parse multiple models one-at-a-time, and return the results
// Validity checking is done elsewhere.

// This subroutine is called by ProcessModelOpts

program define ParseModel, sclass

	syntax [anything(name=model id="meta-analysis model")] ///
		, PARAMS(integer) [ SUMMSTAT(name) /*SUMMNEW*/ GLOBALOPTS(string asis) ///	// default/global options: `teststat' `hetstat' [WGT() CC() etc.]
		Z T CHI2 CMH CMHNocc ///													// test statistic options
		HKSj HKnapp KHartung KRoger BArtlett PETO RObust SKovgaard EIM OIM QWT(varname numeric) /*contains quality weights*/ ///
		INIT(name) CC(passthru) noCC2 LOGRank PRoportion TN(passthru) POVERV(passthru) ///
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
	foreach opt in wgt truncate isq tausq tn poverv itol maxtausq reps maxiter quadpts difficult technique {
		local old_`opt' : copy local `opt'
	}
		
	local 0 `", `globalopts'"'
	syntax [, Z T CHI2 CMH CMHNocc ///
		CC(passthru) noCC2 WGT(passthru) TRUNCate(passthru) ISQ(string) TAUSQ(string) TN(passthru) POVERV(passthru) ///
		ITOL(passthru) MAXTausq(passthru) REPS(passthru) MAXITer(passthru) QUADPTS(passthru) DIFficult TECHnique(passthru) * ]
		// last line ^^  "global" opts to compare with "specific model" opts
		// add "*" as this macro also contains `opts_adm' (not relevant to this subroutine)

	local opts_adm `"`macval(options)'"'
	
	local gTestStat `t' `z' `chi2' `cmh' `cmhnocc'
	opts_exclusive `"`gTestStat'"' `""' 184
	
	opts_exclusive `"`cc' `cc2'"' `""' 184
	local ccopt    `"`cc'`cc2'"'

	foreach opt in ccopt wgt truncate isq tausq tn poverv itol maxtausq reps maxiter quadpts difficult technique {
		if `"`old_`opt''"'!=`""' {
			local `opt' : copy local old_`opt'
		}
	}
	
	// default model if none defined
	if `"`model'"'==`""' {
		local model = cond(`params'==4, "mh", "iv")
		
		// If user-defined weights, model not specified and `params'==4, assume I-V Common rather than exit with error
		// This matches with previous -metan9- behaviour.
		// (do this now, so that hetstat is processed correctly.  user-defined weights are otherwise processed later)
		if `"`wgt'"'!=`""' & `params'==4 {
			local model iv
			disp `"{error}Note: user-defined weights supplied; inverse-variance model assumed"'
		}
	}

	
	** TEST STATISTICS
	if inlist("`teststat'", "cmh", "cmhnocc") {
		if "`model'"!="mh" | !inlist("`summstat'", "or", "") {
			nois disp as err "Cannot specify {bf:`teststat'} test option without Mantel-Haenszel odds ratios"
			exit 184
		}
		if "`summstat'"=="" & `params'==4 {
			local summnew or
			disp `"{error}Note: {bf:`teststat'} test option specified; odds ratios assumed"'
		}
	}
	else if "`teststat'"=="" & inlist("`gTestStat'", "cmh", "cmhnocc") {
		if "`model'"!="mh" | !inlist("`summstat'", "or", "") {
			// disp `"{error}Note: global option {bf:`gTestStat'} is not applicable to all models; local defaults will apply"'
			local gl_error `gl_error' `gTestStat'
		}
		if "`summstat'"=="" & `params'==4 {
			local summnew or
			disp `"{error}Note: {bf:`teststat'} test option specified; odds ratios assumed"'
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
			if `"`empirical'"'!=`""' {
				if "`summstat'"=="" {
					local summnew or
					disp `"{error}Note: Empirical continuity correction specified; odds ratios assumed"'
				}
				else if "`summstat'"!="or" {
					nois disp as err "Empirical continuity correction only valid with odds ratios"
					exit 184
				}
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
			if "`model'"=="mh" {
				local ccval = 0.5
				local mhuncorr mhuncorr
			}
		}
		local ccopt_final `"cc(`ccval', `allifzero' `opposite' `empirical' `mhuncorr')"'
	}

	// chi2 is only valid with:
	// - 2x2 Odds Ratios (including Peto)
	// - logrank HR
	// - Profile Likelihood ... but this is stored separately, as `chi2_lr' [Jan 2020]
	if "`teststat'"=="chi2" {
		if "`summstat'"=="" & `params'==4 {
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
	
	
	** COLLECT OPTIONS AND RETURN
	sreturn clear

	// Model options
	local modelopts `"`cmhnocc' `robust' `hksj_opt' `kr_opt' `bartlett' `skovgaard' `eim' `oim' `ccopt_final' `tn' `poverv'"'
	local modelopts `"`modelopts' `wgt' `truncate' `isqsa_opt' `tsqsa_opt' `qe_opt' `init_opt'"'	// `tsqlevel' removed June 2022
	local modelopts `"`modelopts' `itol' `maxtausq' `reps' `maxiter' `quadpts' `difficult' `technique'"'
	local modelopts = trim(itrim(`"`modelopts'"'))
	
	// Return
	sreturn local model `model'
	sreturn local modelorig `modelorig'
	sreturn local teststat `teststat'

	sreturn local modelopts  `"`modelopts'"'		// Additional model options (for PerformPooling)
	sreturn local labelopt   `"`label'"'			// Model label (for DrawTableAD)
	sreturn local extralabel `"`extralabel'"'		// "Extra" model label (e.g. heterogeneity; for DrawTableAD)
	sreturn local userstats  `"`userstats'"'		// User-supplied effect sizes
	
	// Remaining options
	sreturn local opts_adm `"`macval(opts_adm)'"'
	
	// Corrective macro: only applies to 2x2 count data; is either "or" or nothing
	sreturn local summnew `summnew'
	
	// Error prompts
	sreturn local gl_error `gl_error'
	
end



** Basic option compatibility checks
// Locals to be altered in main routine:
// ilevel olevel (+ level to be discarded)
// ccvar() added (if params==4 or proportion)
// hlevel (+ tsqlevel discarded)
// (no)keepvars (no)rsample clear (could be "", "clear", "clearstack")
// (no)het (no)wt (no)subgroup (no)overall
// sgwt ovwt altwt
// isqparam	

program define ParseOptions, sclass

	// Locals needed for reference, but not to be altered:
	syntax [, BY(varname numeric) * ]	// do not return `byopts' in `opts_adm'
	local 0 `", `macval(options)'"'	
	syntax [, SAVING(passthru) CREATEDBY(passthru) DENOMinator(passthru) ///
		PRoportion CUmulative INFluence SUMMARYONLY NOPR TESTBased * ]
	
	// Locals potentially to be altered here:
	syntax [, LEVEL(passthru) ILevel(passthru) OLevel(passthru) TSQLEVEL(passthru) HLevel(passthru) ///
		noKEEPvars noRSample CLEARSTACK CLEAR noHET noWT noOVerall noSUbgroup OVWt SGWt ALTWt ISQParam ///
		MODELLIST(namelist) * ]	// <-- *not* to be altered; but also not to be returned within `opts_adm'
	
	local opts_adm `"`macval(options)'"'
	local m : word count `modellist'
	gettoken model1 : modellist

	// Significance levels
	if `"`hlevel'"'==`""' local hlevel : copy local tsqlevel	// TSQLEVEL is a legacy -admetan- synonym for HLEVEL
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

	if `"`clearstack'"'!=`""' local clear clearstack	// Added July 2021
	if `"`clear'"'!=`""' & `"`createdby'"'==`""' {
		if `"`keepvars'"'!=`""' {
			nois disp as err `"Option {bf:`clear'} specified; option {bf:nokeepvars} will be ignored"'
			local keepvars
		}
		if `"`rsample'"'!=`""' {
			nois disp as err `"Option {bf:`clear'} specified; option {bf:norsample} will be ignored"'
			local rsample
		}
	}
	if `"`rsample'"'!=`""' local keepvars nokeepvars	// noRSample implies noKEEPVars

	// May 2020:
	// Restore -metan9- behaviour that noOVerall ==> noHET and noWT
	if `"`overall'"'!=`""' & !(`"`by'"'!=`""' & `"`subgroup'"'==`""') {
		local het nohet
		local wt nowt
	}

	// cumulative and influence
	// if `by', cumulative *must* be done by subgroup and not overall ==> nooverall is "compulsory"
	opts_exclusive `"`cumulative' `influence'"' `""' 184
	if `"`cumulative'"'!=`""' {
		if `"`subgroup'"'!=`""' {
			disp `"{error}Note: {bf:nosubgroup} is not compatible with {bf:cumulative} and will be ignored"'
			local subgroup
		}
		if `"`by'"'==`""' {
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

	if `"`cumulative'`influence'"'!=`""' {
		if `"`summaryonly'"'!=`""' {
			disp `"{error}Note: {bf:`cumulative'`influence'} and {bf:summaryonly} are not compatible"'
			exit 184
		}

		// Multiple models cannot be specified with cumulative or influence (for simplicity)
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
	if `"`by'"'==`""' {
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
			// `"`influence'"'!=`""' ==> `nooverall' and `sgwt' are synonyms
			// ...and ==> `nosubgroup' and `ovwt' are synonyms
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

	// April 2021
	// if `"`subgroup'`het'"'!=`""' local between nobetween		// June 2022 -- moved to metan_output.ado

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

	// Re-assemble options list
	// (see "Prepare for meta-analysis modelling" section above)
	local newopts `ilevel' `olevel' `hlevel' `clear'
	local newopts `newopts' `het' `wt' `subgroup' `overall' `sgwt' `ovwt' `altwt' `isqparam'
	
	sreturn local newopts `"`newopts'"'
	sreturn local keepvars `keepvars' `rsample'
	sreturn local options `"`macval(opts_adm)'"'
	
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


