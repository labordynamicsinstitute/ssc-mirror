* metan_analysis.ado
* Subroutine to run the actual meta-analysis modelling
* Called by metan.ado; do not run directly

*!  version 4.08  David Fisher  17jun2024
*! version 4.08.1  David Fisher  12jul2024

* version 4.08.1
// Minor bug fixes to allow programs to run without error under Stata versions 15 and older


program define metan_analysis, rclass

	syntax varlist(numeric min=3 max=7) [if] [in], OUTVLIST(varlist numeric min=5 max=7) ///
		[ MODELLIST(namelist) TESTSTATLIST(namelist) BY(varname numeric) XOUTVLIST(varlist numeric) ROWNAMES(namelist) ///
		CUmulative INFluence PRoportion noOVerall noSUbgroup OVWt SGWt ALTWt TESTBased ISQParam RFDist ///
		KEEPAll KEEPOrder noTABle noGRaph noHEADER ///
		IFINOPT USERWGT ALLWTNAMES(namelist) * ]		// internal options only (for this subroutine, not for metan_output.ado)
	
	local opts_adm `"`macval(options)' xoutvlist(`xoutvlist')"'
	local oldrownames : copy local rownames
	
	gettoken _USE invlist : varlist
	local params : word count `invlist'
	marksample touse, novarlist	

	// Form `bylist' here, *before* passing to PerformMetaAnalysis
	//   because if `keepall' we may need to construct matrices with missing columns
	//   if some subgroups have insufficient data for analysis
	if `"`keeporder'"'!=`""' local keepall keepall		// `keeporder' implies `keepall' [MOVED UPWARD]
	if `"`by'"'!=`""' {
		if `"`keepall'"'==`""' local anduse1 `"& `_USE'==1"'
		qui levelsof `by' if `touse' `anduse1', missing local(bylist)	// "missing" since `touse' should already be appropriate for missing yes/no
		local byopts `"by(`by') bylist(`bylist')"'
		local nby : word count `bylist'
	}
	
	// Now, first model is "primary" and will be displayed on screen and in forest plot
	//  options such as `ovwt', `sgwt', `altwt' apply here
	// Remaining models are simply fitted, and results saved (in matrices ovstats and bystats).	
	
	// Hence, loop over models *backwards* so that "primary" model is done last
	//  and hence "correct" outvlist is left behind

	// Aug 2023: Hence, reverse order of elements of `allwtnames' so that they align with true model list as specified by user
	if `"`allwtnames'"'!=`""' {
		foreach el in `allwtnames' {
			local allwtnames2 `el' `allwtnames2'
		}
		local allwtnames : copy local allwtnames2
	}
	
	gettoken model1 : modellist
	local UniqModels : list uniq modellist
	local RefFEModList peto mh iv mu			// fixed (common) effect models
	local RefREModList mp pmm ml pl reml bt dlb		// random-effects models where a conf. interval for tausq is estimated
		
	// Before looping, create list of unique colnames
	//  (e.g. if same basic model is run twice, with different options)
	local m = 0
	local zca = 0		// initialize marker of "`model'"!="peto" & float(`ccval')==0
	local zcb = 0		// initialize marker of inlist("`model'", "peto", "mh") | float(`ccval')>0
	local udw = 0		// initialize marker of "user-defined weights"
	local rest : copy local modellist
	while `"`rest'"'!=`""' {
		local ++m
		gettoken model rest : rest
		
		local 0 `", `opts_adm'"'
		syntax [, model`m'opts(string) * ]
		local opts_adm `"`macval(options)'"'
		
		local 0 `", `model`m'opts'"'
		syntax [, HETPooled HKSj RObust KRoger BArtlett SKovgaard WGT(passthru) ///
			CC(string) * ]	// <-- cc() for later checking for missing effect size/std. error
		
		// May 2022: Extract info on user-defined weights to send to metan_output.ado
		if `"`wgt'"'!=`""' {
			local wgtoptlist `wgtoptlist' `wgt'
			local ++udw
		}
		else local wgtoptlist `wgtoptlist' default
		// if `m'==1 local cc1 : copy local cc				// `cc' opt for first model only

		// In case of zero cells (see below)...
		//  a) identify models *without* CC (& not Peto, but including M-H)
		//  b) identify models which are M-H, Peto or (I-V plus CC)
		if `params'==4 | "`proportion'"!="" {
			local 0 `"`cc'"'
			syntax [anything(name=ccval)] [, *]
			if "`model'"!="peto" & float(`ccval')==0               local ++zca
			if inlist("`model'", "peto", "mh") | float(`ccval')>0  local ++zcb
		}
		
		// Append HKSJ if appropriate, since this is a commonly-used option
		// clearer for users to see labelling e.g. "dl; dl_hksj" rather than "dl_1; dl_2"
		// ... and similarly for robust variance estimator
		// and REML Kenward-Roger correction and PL likelihood corrections
		// ... and pooled (across subgroups) heterogeneity [Sep 2023]
		if `"`hksj'"'!=`""' local model `model'_hksj
		if `"`robust'"'!=`""' local model `model'_rob
		if `"`kroger'"'!=`""' local model `model'_kr
		if "`model'"=="pl" {
			if `"`bartlett'"'!=`""' local model `model'_bart
			if `"`skovgaard'"'!=`""' local model `model'_skov
		}
		if `"`hetpooled'"'!=`""' local model `model'_pool
		
		if `: list model in mcolnames' {
			local j=2
			local newname `model'_`j'
			while `: list newname in mcolnames' {
				local ++j
				local newname `model'_`j'
			}
			local mcolnames `mcolnames' `newname'
			if "`model'"=="sa" | "`isqparam'"!="" local hetcolnames `hetcolnames' `newname'	/* modified May 2023 */
			
		}
		else {
			local mcolnames `mcolnames' `model'
			if "`model'"=="sa" | "`isqparam'"!="" local hetcolnames `hetcolnames' `model'	/* modified May 2023 */
		}
		// [Nov 2020:] Note: this forms a copy of `mcolnames' for matrix `hetstats', called `hetcolnames'		

	}
	if !`udw' local wgtoptlist	 // cancel if no user-defined weights
	
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
		if `j'>1 local testbased						// only first model can use `testbased' option
		
		local model    : word `j' of `modellist'
		local teststat : word `j' of `teststatlist'
		
		cap nois PerformMetaAnalysis `invlist' if `touse' & `_USE'==1, outvlist(`outvlist') ///
			model(`model') teststat(`teststat') `overall' `subgroup' `cumulative' `influence' `proportion' ///
			rownames(`rownames') `byopts' `ovwt' `sgwt' `altwt' `model`j'opts' `opts_adm' ///
			`testbased' `isqparam' `first'

		if _rc {
			if inlist(_rc, 2000, 2001, 2002) {
				if `j'==1 {
					return add
					exit _rc
				}
			}
			else {
				if `"`err'"'==`""' {
					if _rc==1 nois disp as err `"User break in {bf:metan_analysis.PerformMetaAnalysis}"'
					else nois disp as err `"Error in {bf:metan_analysis.PerformMetaAnalysis}"'
				}
				c_local err noerr
				exit _rc
			}
		}
		
		// August 2023
		// If requested, store weights from each model under separate varnames
		if `j' > 1 & `"`allwtnames'"'!=`""' {
			tokenize `outvlist'
			args _ES _seES _LCI _UCI _WT _NN _CC
			gettoken wtname allwtnames : allwtnames
			qui clonevar `wtname' = `_WT'
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
					nois disp as err `"Error in {bf:metan_analysis.PerformMetaAnalysis}"'
					c_local err noerr
					exit _rc
				}
				if !inlist("`r(nsg)'", "0", "", ".") mat colnames `checkmat' = iv
				else mat colnames `checkmat' = `mcolname'
				matrix define `ovstats' = `checkmat', nullmat(`ovstats')
				
				local rownames_reduced_new `"`r(rownames_reduced)'"'
				local rownames_reduced : list rownames_reduced | rownames_reduced_new

				// [SEP 2020:] matrices containing "parametrically-defined" het. statistics
				if `"`r(hetstats)'"'!=`""' {
					matrix define `checkmat' = r(hetstats)
					matrix define `hetstats' = `checkmat', nullmat(`hetstats')
				}
			}
			
			// if ((`"`by'"'!=`""' & `"`subgroup'"'==`""') | `"`sgwt'"'!=`""') {
			if `"`by'"'!=`""' & `"`subgroup'"'==`""' {
				tempname bystats`j'
				matrix define `bystats`j'' = r(bystats)
				cap assert rowsof(`bystats`j'') > 1
				if _rc {
					if `m' > 1 local jj = `j'
					nois disp as err `"Matrix {bf:r(bystats`jj')} could not be created"'
					nois disp as err `"Error in {bf:metan_analysis.PerformMetaAnalysis}"'
					c_local err noerr
					exit _rc
				}
				if !inlist("`r(nsg)'", "0", "", ".") {
					local bylist2 : coleq `bystats`j''
					local nsg_list `r(nsg_list)'
					local newmcols
					
					foreach el of numlist `bylist2' {
						if `: list el in nsg_list' local newmcols `newmcols' iv
						else local newmcols `newmcols' `mcolname'
					}
					
					mat colnames `bystats`j'' = `newmcols'
				}
				else mat colnames `bystats`j'' = `mcolname'
				local bystatslist `bystats`j'' `bystatslist'		// form list in reverse order
				
				// Model-specific subgroup weights
				matrix define `mwt' = r(mwt) \ nullmat(`mwt')

				// [SEP 2020:] matrices containing "parametrically-defined" het. statistics
				if `"`r(byhet)'"'!=`""' {
					tempname byhet`j'
					matrix define `byhet`j'' = r(byhet)
				}
			}
		}		// end if "`model'"!="user"
	}		// end forvalues j = `m' (-1) 1

	cap {
		confirm matrix `ovstats'
		assert rowsof(`ovstats') > 1
	}
	if _rc {
		// can't just clear the matrix, because "return add" above may have already returned (a version of) it
		// therefore, instead redefine it as missing and (re-)return it.
		// main routine will then detect that it is missing and discard it.
		matrix define `ovstats' = .
	}
	else {
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
	}
	// else local ovstats		// marker of whether (valid) matrix exists

	// SEP 2020: Same for `hetstats'
	cap {
		confirm matrix `hetstats'
		assert rowsof(`hetstats') > 1
	}
	if _rc {
		// can't just clear the matrix, because "return add" above may have already returned (a version of) it
		// therefore, instead redefine it as missing and (re-)return it.
		// main routine will then detect that it is missing and discard it.
		matrix define `hetstats' = .
	}
	else {
		// reduce rows if necessary
		// if no models which estimate tausq CIs, just keep rows containing point estimates
		if `"`: list UniqModels & RefREModList'"'==`""' {		// RefREModList = mp pmm ml pl reml bt dlb
			matrix define `hetstats' = `hetstats'["tausq", 1...] \ `hetstats'["H", 1...] \ `hetstats'["Isq", 1...] \ `hetstats'["HsqM", 1...]
		}
		matrix colnames `hetstats' = `hetcolnames'
	}
	// else local hetstats		// marker of whether (valid) matrix exists
	
	// Sep 2020:  Q statistics (associated with "primary" model)
	// `byQ' contains subgroup-Q values from *first* model
	// If this model is common-effect,  Q_lci will be from non-central chisq; label with "fe"
	// If this model is random-effects, Q_lci will be from Gamma; label with "re"
	if `"`by'"'!=`""' & (`"`subgroup'"'==`""' | `"`sgwt'"'!=`""') {
	
		// first, check `mwt' (cf. `ovstats' and `hetstats' above)
		cap {
			confirm matrix `mwt'
			assert rowsof(`mwt') == `m'
			assert colsof(`mwt') == `nby'
		}
		if _rc {
			// can't just clear the matrix, because "return add" above may have already returned (a version of) it
			// therefore, instead redefine it as missing and (re-)return it.
			// main routine will then detect that it is missing and discard it.
			matrix define `mwt' = .
		}
		
		if `"`subgroup'"'==`""' {
			tempname byQ
			matrix define `byQ' = r(byQ)
			if `: list model1 in RefFEModList' matrix colnames `byQ' = fe
			else if "`model1'"=="user" local colnames `byQ' = user
			else matrix colnames `byQ' = re
		}
	}

	
	// Display error messages relating to subgroups and/or cumulative/influence runs; each unique error message is only displayed once
	if (`"`by'"'!=`""' & `"`subgroup'"'==`""') | `"`sgwt'`cumulative'`influence'"'!=`""' {
		
		// added June 2022
		if (`"`by'"'!=`""' & `"`subgroup'"'==`""') | `"`sgwt'"'!=`""' local text " subgroups"
		if `"`cumulative'`influence'"'!=`""' {
			if "`text'"!="" local text `"`text' and/or"'
			local text  `"`text' {bf:`cumulative'`influence'}"'
			local text2 `"`text' runs"'
		}
		else local text2 : copy local text

		// process each error marker, returned from PerformMetaAnalysis via c_local, and convert to 0 or 1 for use below
		foreach el in rc_2000 rc_2002 rc_tausq rc_tsq_lci rc_tsq_uci rc_eff_lci rc_eff_uci {
			local n`el' = !inlist("`n`el''", "0", "", ".")
		}
		if `nrc_2000' disp `"{error}Note: insufficient data in one or more`text2'"'
		if `nrc_2002' {
			if "`model1'"=="mh" {
				disp `"{error}Note: in one or more`text', all studies have zero events in the same arm"'
				disp `"{error} so that those pooled effects are undefined without continuity correction"'
			}
			else disp `"{error}Note: pooling failed in one or more`text2'"'
		}
		if `nrc_tausq'   disp `"{error}Note: tau{c 178} point estimate not successfully estimated in one or more`text2'"'
		if `nrc_tsq_lci' disp `"{error}Note: tau{c 178} lower confidence limit not successfully estimated in one or more`text2'"'
		if `nrc_tsq_uci' disp `"{error}Note: tau{c 178} upper confidence limit not successfully estimated in one or more`text2'"'
		if `nrc_eff_lci' disp `"{error}Note: lower confidence limit of effect size not successfully estimated in one or more`text2'"'
		if `nrc_eff_uci' disp `"{error}Note: upper confidence limit of effect size not successfully estimated in one or more`text2'"'
	}
	if "`rfdist'"!="" {
		if !inlist("`r(nrfd)'", "0", "", ".") disp `"{error}Note: Predictive intervals are undefined if less than three studies"'
	}

	// Collect numbers of studies and patients (relevant to "primary" model)
	tempname k totnpts k_mh npts_mh
	scalar `k' = r(k)
	scalar `totnpts' = r(n)
	scalar `k_mh' = r(k_mh)			// June 2022: special case: M-H as primary model
	scalar `npts_mh' = r(npts_mh)
		
	// Obtain (updated) `rownames' from `ovstats' or `bystats'
	// because "return matrix" is destructive
	local rownames : rownames `ovstats'
	if "`rownames'"=="r1" {
		cap local rownames : rownames `: word 1 of `bystatslist''
		if _rc | "`rownames'"=="r1" {
			// nois disp as err "Error in rownames"
			// exit 198
			local rownames
		}
	}

	// markers of specific scenarios e.g. missing data
	return scalar nsg = !inlist("`r(nsg)'", "0", "", ".")
	return scalar nzt = !inlist("`r(nzt)'", "0", "", ".")
	local nmiss = !inlist("`r(nmiss)'", "0", "", ".")
	if `nmiss' assert inlist(`params', 2, 3)
	return add
	
	forvalues j = 1 / `m' {
		cap return matrix bystats`j' = `bystats`j''
		cap return matrix byhet`j' = `byhet`j''
	}
	cap return matrix ovstats = `ovstats'
	cap return matrix hetstats = `hetstats'
	cap return matrix byQ = `byQ'
	cap return matrix mwt = `mwt'

	

	********************************
	* Print summary info to screen *
	********************************
	
	tokenize `outvlist'
	args _ES _seES _LCI _UCI _WT _NN _CC
	
	** Handle studies with insufficient data (_USE==2)
	local keepall_n = 0									// init
	// if `"`keeporder'"'!=`""' local keepall keepall		// `keeporder' implies `keepall' [MOVED UPWARD]
	if `"`keepall'"'==`""' {	
		// print warning of excluded studies (even if no header)
		// but defer printing until just before the header
		// so that other errors can take priority (and be clearly presented) in the meantime
		qui count if `touse' & `_USE'==2
		local keepall_n = r(N)
		qui replace `touse' = 0 if `_USE'==2			// DF MAY 2022: Note, this is also done in main routine (along with `touse2')
	}

	// Updated June 2022:
	// 1. If there are zero cells and any model is *without* CC (& not Peto, but including M-H),
	//     then there may be studies with _USE==1 with missing _ES or _seES.
	
	// 2. If any *other* models are M-H, Peto or I-V plus CC, then the studies are needed; leave them alone.
	//    Then display message "...plus [x] studies with insufficient data for inverse-variance models without continuity correction" (`esmiss').
	
	// 3. But otherwise (including if `m'==1), we can simply set such studies to _USE==2.

	// (also need to be aware of the case of `influence' + `by' + `sgwt' + subgroups with only a single study; see above)
	qui count if `touse' & `_USE'==1 & (missing(`_ES', `_seES') | float(`_seES')==0)
	if r(N)	{
		if `zca' & !`zcb' {
			qui replace `_USE' = 2 if `touse' & `_USE'==1 & (missing(`_ES', `_seES') | float(`_seES')==0)
			if `"`keepall'"'==`""' {
				qui replace `touse' = 0 if `_USE'==2		// affects `touse' only within this subroutine...
			}												// but, since `_USE' is changed "globally",
		}													// we can simply replace `touse'=0 if `_USE'==2 in main routine

		else if `params'!=4 & `"`proportion'"'==`""' & !(`"`influence'"'!=`""' & `"`sgwt'"'!=`""') {
			nois disp as err "Error: effect size or standard error is unexpectedly missing"		// this should never happen
			exit 198
		}
	}
	local esmiss = cond(`m'==1, 0, r(N))
	
	qui count if `touse' & `_USE'==1 & !(missing(`_ES', `_seES') | float(`_seES')==0)
	assert r(N) == cond(!missing(`k_mh'), `k_mh', `k')
	if !missing(`totnpts') {
		summ `_NN' if `touse' & `_USE'==1 & !(missing(`_ES', `_seES') | float(`_seES')==0), meanonly
		assert r(sum) == cond(!missing(`npts_mh'), `npts_mh', `totnpts')

		// number of studies with patient nunbers available MAY be less than total number of studies
		// but only if `nmiss' (and this can only happen if ES+seES or ES+CI)
		local equals = cond(`nmiss', "<", "==")
		assert r(N) `equals' cond(!missing(`k_mh'), `k_mh', `k')
	}
	if (`zca' & !`zcb') | !(`params'==4 | "`proportion'"!="") {
		assert !(missing(`_ES', `_seES') | float(`_seES')==0) if `touse' & `_USE'==1
	}
	// Zero-cell considerations for 2x2 data (assuming no CC and not RD):  [June 2020, updated June 2022]
	// If *all* models are I-V, then any zero event causes a failure (and if OR, same applies to any zero *non*-event)
	// But if M-H / Peto used, then *some* zero-cell studies might be able to be included.  If so, leave them alone.
		
	
	// Print deferred warning of excluded studies (even if no header)
	if `keepall_n' {
		local studies = cond(`keepall_n'==1, "study", "studies")
		local these   = cond(`keepall_n'==1, "this", "these")
		if `esmiss' local extra " (for all models)"
		
		if `"`ifinopt'"'==`""' & `"`summaryonly'"'==`""' & (`"`table'"'==`""' | `"`graph'"'==`""') local colon `";"'

		disp `"{error}Note: `keepall_n' `studies' with missing or insufficient data found`extra'`colon'"'
		if `"`ifinopt'"'!=`""' disp `"{error} within the data range specified by [{it:if}] [{it:in}];"'
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
	// if `"`ovstats'`bystatslist'"'==`""' local pool nopool
	
	// For PrintDesc and DrawTableAD:
	// If first model uses continuity correction or user-defined weights, pass these to DrawTableAD

	// Print summary ("header") text
	if `"`header'"'==`""' {		
		disp _n _c
		disp as text "Studies included: " as res `k'
		qui count if `touse' & `_USE'==2
		if `"`keepall'"'!=`""' {
			if `esmiss' local uc _c
			if r(N) {
				local plural = cond(r(N)==1, "study", "studies")
				disp as text "  plus " as res `r(N)' as text " `plural' with insufficient data" `uc'
			}
			if `esmiss' disp as text "," 	// June 2020
		}
		if `esmiss' {
			local plural = cond(`esmiss'==1, "study", "studies")
			disp as text "  plus " as res `esmiss' as text " `plural' with insufficient data for I-V models without CC"
		}
		
		local dispnpts = cond(missing(`totnpts'), "Unknown", string(`totnpts'))
		disp as text "Participants included: " as res "`dispnpts'"
		if `"`keepall'"'!=`""' & !missing(`totnpts') & r(N) {
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
			summ `_NN' if `touse' & `_USE'==1 & (missing(`_ES', `_seES') | float(`_seES')==0), meanonly
			if `r(sum)'>1 local s s
			disp as text "  plus " as res "`r(sum)'" as text " participant`s' with insufficient data for I-V models without CC"
		}
		if `nmiss' {
			if `"`xoutvlist'"'!=`""' local semicolon ;
			disp as text `"{error}Note: Patient numbers are missing in one or more trials`semicolon'"'
			if `"`xoutvlist'"'!=`""' {
				disp `"{error}      individual {bf:`cumulative'`influence'} patient numbers will not be saved"'
				return local clearnpts clearnpts		// clear macro _NN, so that by-trial patient numbers are no longer available
			}
		}
	}

	
	** Generate study-level CIs for "primary" model (unless pre-specified)
	cap nois GenConfInts `invlist' if `touse' & `_USE'==1, outvlist(`outvlist') ///
		`cumulative' `influence' `proportion' `opts_adm'
	if _rc {
		nois disp as err `"Error in {bf:metan_analysis.GenConfInts}"'
		c_local err noerr
		exit _rc
	}

	** Finally, switch functions of `outvlist' and `xoutvlist',
	//  so that the cumul/infl versions of _ES, _seES etc. are stored in `outvlist' (so overwriting the "standard" _ES, _seES etc.)
	//  for display onscreen, in forest plot and in saved dataset.
	// Then `xoutvlist' just contains the remaining "extra" tempvars _tausq, _Q, _Qdf etc.
	
	// (Note June 2022: do this *after* the above summary info
	//  so that if `cumulative'`influence' the info is compiled using the "basic" _USE, _seES, _ES, _NN corresponding to *actual studies*
	if `"`cumulative'`influence'"'!=`""' {
		return local oldvlist `outvlist'

		// Firstly, tidy up: If nokeepvars *and* altwt not specified, then we can drop
		//   any members of `outvlist' that didn't already exist in the dataset
		if `"`altwt'"'==`""' {
			local todrop
			foreach v of local outvlist {
				if `: list v in tvlist' {		// i.e. if `v' was created by either -ipdmetan- or -metan-
					local todrop `todrop' ``v''
				}
			}
			return local todrop `todrop'
		}
		
		// [Mar 2020, modified Dec 2020:]
		// Recall that `xrownames' is derivable from `rownames'
		// BUT `rownames' may have been altered within PerformMetaAnalysis
		//  so (re-) obtain them from the matrices themselves and check for alterations
		GetXRowNames `oldrownames', `cumulative' `influence' `opts_adm'
		local xrownames `s(xrownames)'
		
		local npts_el npts
		local not_xrownames Q Qdf Q_lci Q_uci sigmasq _WT2 _WT_Final	// these elements *only* appear in `xrownames', *never* in `rownames'
		local toremove : list xrownames - rownames
		local toremove : list toremove - not_xrownames
		local toremove : list toremove - npts_el			// June 2020: npts will be removed from `xoutvlist' *anyway*
															// ... (see note where xoutvlist tempvars are declared, and code a few lines below)	
															// ... so don't also remove it here						
		local oldrownames : list oldrownames - npts_el
		local test : list oldrownames - rownames
		cap assert `"`test'"'==`"`toremove'"'
		if _rc {
			nois disp as err "Something has gone wrong in metan_analysis.ado"		// should never see this error message
			exit _rc
		}

		local xoutvlist `xoutvlist' `_WT'		// Added Feb 2024

		if `"`toremove'"'!=`""' {
			tokenize `xoutvlist'
			foreach el of local toremove {
				local i : list posof `"`el'"' in xrownames
				local xoutvlist : list xoutvlist - `i'
			}
		
			// Now rebuild `xrownames'
			GetXRowNames `rownames', `cumulative' `influence' `opts_adm'
			local xrownames `s(xrownames)'
		}
		assert `: word count `xoutvlist'' == `: word count `xrownames''		
		tokenize `xoutvlist'
		args `xrownames'
		
		// Finally, we can separate off `xoutvlist', and thereby reset `outvlist'
		local outvlist `eff' `se_eff' `eff_lci' `eff_uci' `_WT2' `_NN' `_CC'
		tokenize `outvlist'
		args _ES _seES _LCI _UCI _WT _NN _CC

		// DF added JUNE 2022
		foreach v of varlist `outvlist' {
			qui replace `v' = . if `_USE'==2
		}
		
		local xoutvlist : list xoutvlist - outvlist
	}
	return local outvlist `outvlist'
	return local xoutvlist `xoutvlist'
		
	// N.B. At this point, data processing should be complete.
	// From now on, we will be *using* the data rather than processing it.

end


program define GetXRowNames, sclass

	syntax namelist(name=rownames) [, CUmulative INFluence SUMMARYONLY SAVING(passthru) CLEAR * ]

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
			local xrownames `xrownames' _WT2 _WT_Final
		}
		sreturn local xrownames `xrownames'
	}
end	



*******************************************************************************

	
* PerformMetaAnalysis
// Create list of "pooling" variables
// Run meta-analysis on whole dataset ("overall") and, if requested, by subgroup
// If cumul/influence, subroutine "CumInfLoop" is run first, to handle the intermediate steps
// Then (in any case), subroutine "PerformPooling" is run.
// (called directly by metan_analysis.ado)

// N.B. [Sep 2018] takes bits of old (v2.2) MainRoutine and PerformMetaAnalysis subroutines

// SEP 2019:  We are now doing this **one model at a time**


program define PerformMetaAnalysis, rclass sortpreserve

	syntax varlist(numeric min=2 max=6) [if] [in], SORTBY(varlist) MODEL(name) ///
		[BY(varname numeric) BYLIST(numlist miss) SUMMSTAT(name) TESTSTAT(name) QSTAT(passthru) ///
		TESTBased ISQParam ROWNAMES(namelist) FIRST /* N.B. "first" is marker that this is the first/main/primary model */ ///
		OUTVLIST(varlist numeric min=5 max=7) XOUTVLIST(varlist numeric) ///
		noOVerall noSUbgroup OVWt SGWt ALTWt WGT(varname numeric) CUmulative INFluence PRoportion noINTeger ///
		LOGRank ILevel(passthru) CC(passthru) KRoger HETPooled /// from `opts_model'; needed in main routine
		* ]

	local opts_model `"`macval(options)' `kroger' `hetpooled'"'	// model`j'opts; add `kroger' and `pooling' back in (this means they are duplicated...
																//  ...but `opts_model' is only used in this subroutine so it shouldn't matter)
	marksample touse, novarlist		// -novarlist- option prevents -marksample- from setting `touse' to zero if any missing values in `varlist'
									// we want to control this behaviour ourselves, e.g. by using KEEPALL option
	local invlist : copy local varlist
	tokenize `outvlist'
	args _ES _seES _LCI _UCI _WT _NN _CC

	local nrfd = 0		// initialize marker of "less than 3 studies" (for rfdist)
	local nmiss = 0		// initialize marker of "pt. numbers are missing in one or more trials"
	local nsg = 0		// initialize marker of "only a single valid estimate" (e.g. for by(), or cumul/infl)
	local nzt = 0		// initialize marker of "HKSJ has resulted in a shorter CI than IV" (for HKSJ)
	
	// sensitivity analysis
	// [Jan 2020: remove this, but first check how "single tausq" subgroup analysis works (c.f. R book)]
	/*
	if "`model'"=="sa" & "`by'"!="" {
		nois disp as err `"Sensitivity analysis cannot be used with {bf:by()}"'
		exit 184
	}
	*/
	
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
		cap nois ProcessPoolingVarlist `invlist' if `touse', ///
			summstat(`summstat') model(`model') teststat(`teststat') outvlist(`outvlist') tvlist(`tvlist') cclist(`cclist') wgt(`wgt') ///
			`proportion' `integer' `logrank' `cc'
		
		if _rc {
			nois disp as err `"Error in {bf:metan_analysis.ProcessPoolingVarlist}"'
			c_local err noerr		// tell -metan- not to also report an "error in metan_analysis.PerformMetaAnalysis"
			exit _rc
		}

		local oevlist  `s(oevlist)'
		local mhvlist  `s(mhvlist)'

		// May 2020: if M-H continuity correction not specified, but found to be necessary due to all studies having zero-cells
		if `"`s(mhallzero)'"'!=`""' {
			if `"`s(invlist)'"'!=`""' local invlist `s(invlist)'	// so that Breslow-Day or Tarone statistics (for ORs) are calculated using corrected counts
			local opts_model `"`macval(opts_model)' `s(mhallzero)'"'
			return local mhallzero `s(mhallzero)'
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
		qui replace `_seES' = (`_UCI_' - `_LCI_') / (2*invnormal(.5 + 95/200)) if `touse'
	}

	// If model is "user",
	//  having generated _ES, _LCI and _UCI, normalise user-supplied weights but then exit
	if "`model'"=="user" {
		if "`first'"!="" {		// if first model is "user"

			// weights
			summ `wgt' if `touse', meanonly
			qui replace `_WT' = 100 * `wgt' / r(sum) if `touse'
			
			// total number of studies
			qui count if `touse'
			local k_user = r(N)
			return scalar k = r(N)

			// total number of patients
			if `"`_NN'"'!=`""' {
				summ `_NN' if `touse', meanonly
				return scalar n = r(sum)
				if r(N)!=`k_user' c_local nmiss = 1		// marker of "pt. numbers are missing in one or more trials"				
			}
			
			// [Nov 2020:] derive Cochran's Q
			// needed in the special case that first model is "user" but at least one later model is not
			// (not an issue with previous -metan- code)
			tempname eff_Q
			summ `_ES' [aw=1/`_seES'^2] if `touse', meanonly
			scalar `eff_Q' = r(mean)
			
			tempvar Qhet
			qui gen double `Qhet' = ((`_ES' - `eff_Q')/`_seES')^2
			summ `Qhet' if `touse', meanonly

			return scalar Q = cond(r(N), r(sum), .)
			return scalar Qdf = cond(r(N), r(N)-1, .)
		}
		
		exit 0					// exit subroutine and continue without error
	}
	
	if `"`_NN'"'!=`""' {
		confirm numeric var `_NN'
		local nptsopt npts(`_NN')	// to send to PerformPooling / CumInfLoop
	}								// N.B. `npts' is otherwise undefined in this subroutine
	if "`model'"=="b0" {
		cap {
			confirm numeric var `_NN'
			cap assert `_NN'>=0 & !missing(`_NN') if `touse'
		}
		if _rc {
			nois disp as err `"Participant numbers not available for all studies; cannot calculate B0 tau{c 178} estimator"'
			exit 416			// 416 = "missing values encountered"
		}
	}
	
	// numbers of studies and patients, plus Q and Qdf for later calculations
	// (use tempnames scQ and scQdf to avoid potential conflict with *tempvars* named Q and Qdf, e.g. if cumulative/influence)
	foreach x in k n scQ scQdf {
		tempname `x'
		scalar ``x'' = .
	}
	
	// Moved/amended March 2020 (replaces `cumulflag')
	if `"`cumulative'`influence'"' != `""' {
		tempvar obsj
		qui gen long `obsj' = .
	}

	// NEW SEP 2023
	// If heterogeneity parameter is "pooled" (i.e. stratified by) subgroup, need to estimate it once, now
	// and pass it through to subsequent analyses as if it were a "sensitivity analysis"
	if `"`hetpooled'"'!=`""' {
		tempvar by2
		egen `by2' = group(`by') if `touse', missing
		qui tab `by2' if `touse'
		cap assert `r(r)'==`: word count `bylist''
		if _rc {
			disp as err "Error in {bf:by()} groups"	// shouldn't ever see this
			exit _rc
		}		

		// Prepare to use xi
		local OldVarsPrefix: char _dta[__xi__Vars__Prefix__]
		local OldVarsToDrop: char _dta[__xi__Vars__To__Drop__]
		foreach X in `c(ALPHA)' {
			local x __`X'`X'
			cap ds __`X'`X'
			if _rc==111 continue, break
			foreach Y in `c(ALPHA)' {
				local x __`X'`Y'
				cap ds __`X'`Y'
				if _rc==111 continue, break
			}
			if !_rc {
				disp as err `"Please remove some variables with names beginning __*"'
				exit 198
			}
		}
		if inlist("`model'", "dl", "reml", "mp") {
			local model2 : copy local model
			if "`model'"=="dl" local model2 mm
			else if "`model'"=="mp" local model2 eb
			cap xi, prefix(`x'): metareg `_ES' i.`by2' if `touse', wsse(`_seES') `model2'
			local opts_model tsqsa(`e(tau2)') `opts_model'
			return scalar tsq_pooled = `e(tau2)'
		}
		else if "`model'"=="mu" {
			tempvar precsq
			gen double `precsq' = 1/`_seES'^2
			cap xi, prefix(`x'): regress `_ES' i.`by2' [aw=`precsq'] if `touse'
			summ `precsq', meanonly
			local phi_pooled = r(mean)*e(rmse)^2
			local opts_model phisa(`phi_pooled') `opts_model'
			return scalar phi_pooled = `phi_pooled'
		}
		else {
			nois disp as err "Invalid model requested"	// shouldn't ever see this
			exit 198
		}
		if _rc {
			if "`model'"=="mu" disp as err "Error in {bf:regress}"
			else disp as err "Error in {bf:metareg}"
			c_local err noerr		// tell -metan- not to also report an "error in metan_analysis.PerformMetaAnalysis"
			exit _rc
		}

		cap drop `by2'
		cap drop `x'*
		char define _dta[__xi__Vars__Prefix__] `OldVarsPrefix'
		char define _dta[__xi__Vars__To__Drop__] `OldVarsToDrop'
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
		cap summ `_CC' if `touse', meanonly
		if !_rc & r(N) local equals `"<="'

		// if ovwt, pass `_WT' to PerformPooling to be filled in
		// otherwise, PerformPooling will generate a tempvar, and `_WT' will remain empty
		local wtvar = cond(`"`ovwt'"'!=`""', `"`_WT'"', `""')


		** Cumulative/influence analysis
		// Run extra loop to store results of each iteration within the currrent dataset (`xoutvlist')
		if `"`cumulative'`influence'"' != `""' {

			// Moved/amended March 2020
			qui bysort `touse' (`sortby') : replace `obsj' = _n if `touse'
		
			cap nois CumInfLoop `_ES' `_seES' if `touse', sortby(`obsj') ///
				model(`model') summstat(`summstat') teststat(`teststat') `qstat' `testbased' `isqparam' ///
				mhvlist(`mhvlist') oevlist(`oevlist') invlist(`invlist') xoutvlist(`xoutvlist') ///
				wgt(`wgt') wtvar(`wtvar') rownames(`rownames') `nptsopt' ///
				`cumulative' `influence' `integer' `logrank' `proportion' `ovwt' `opts_model'
			
			if _rc {
				if _rc==2000 local nrc_2000 = 1
				else if _rc==2001 local nrc_2001 = 1
				else if _rc==2002 local nrc_2002 = 1
				else {
					if `"`err'"'==`""' {
						if _rc==1 nois disp as err `"User break in {bf:metan_analysis.CumInfLoop}"'
						else nois disp as err `"Error in {bf:metan_analysis.CumInfLoop}"'
					}
					c_local err noerr		// tell -metan- not to also report an "error in metan_analysis.PerformMetaAnalysis"
					exit _rc
				}
			}
			
			local xwt `r(xwt)'			// extract _WT2 from `xoutvlist'
		}

		
		** Main meta-analysis
		// If only one study, display warning message if appropriate
		// (the actual change in method is handled by PerformPooling)
		qui count if `touse'
		local rN = r(N)
		if `rN'==1 {
			if !inlist("`model'", "iv", "mh", "peto", "mu") {
				disp `"{error}Note: Only one estimate found; random-effects model not used"'
			}
		}
		
		cap nois PerformPooling `_ES' `_seES' if `touse', ///
			model(`model') summstat(`summstat') teststat(`teststat') `qstat' `testbased' `isqparam' ///
			mhvlist(`mhvlist') oevlist(`oevlist') invlist(`invlist') `nptsopt' wtvar(`wtvar') wgt(`wgt') ///
			`integer' `logrank' `proportion' `opts_model'

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
				if _rc==1 nois disp as err `"User break in {bf:metan_analysis.PerformPooling}"'
				else nois disp as err `"Error in {bf:metan_analysis.PerformPooling}"'
			}
			c_local err noerr		// tell -metan- not to also report an "error in metan_analysis.MetaAnalysisLoop"
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
			local toremove npts
			local xrownames : list rownames - toremove	
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
			args _ES _seES _LCI _UCI _WT _NN _CC
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
			if `"`proportion'"'!=`""' local toremove `toremove' prop_rflci prop_rfuci
		}
		// if "`model'"=="peto" | "`teststat'"=="chi2" local toremove `toremove' z
		if inlist("`teststat'", "chi2", "t") local toremove `toremove' z
		if inlist("`model'", "peto", "mh", "iv", "mu") local toremove `toremove' tausq /*sigmasq*/
		if "`model'"!="mu" local toremove `toremove' phi	// added Sep 2023
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
		scalar `n' = r(npts)			// overall number of patients (if available)
		
		scalar `scQ' = r(Q)
		scalar `scQdf' = r(Qdf)			// Q and Qdf for later calculations
		assert `scQdf' < `k'
		return scalar Qdf = `scQdf'		// one fewer than the number of observations for which ES & seES could be estimated 
										// typically, Qdf = k - 1  BUT may not be in specific circumstances
										// most obviously in the case of uncorrected zero cells

		// [July 2022] r(k_npts) and r(nzt) will have been updated by PerformPooling
		if `"`r(k_npts)'"'!=`""' {
			if r(k_npts) < r(k) local nmiss = 1
		}
		local nzt = !inlist("`r(nzt)'", "0", "", ".")
		
		// Warning messages & error codes r.e. confidence limits for iterative tausq
		if inlist("`model'", "mp", "pmm", "ml", "pl", "reml", "bt") | "`kroger'"!="" {
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
	
		// END OF REFERENCES TO RETURN LIST r() FROM PerformPooling

		// Normalise weights overall (if `ovwt')
		if `"`ovwt'"'!=`""' {

			/* Amended for clarity May 2023 */
			local _WT2 = cond(`"`xwt'"'!=`""', `"`xwt'"', `"`_WT'"')			// use _WT2 from `xoutvlist' if applicable
			summ `_WT' if `touse', meanonly
			qui replace `_WT2' = 100*cond(`"`altwt'"'!=`""', `_WT', `_WT2') / r(sum) if `touse'
			// ^^ use *original* weights (_WT) rather than cumul/infl weights (_WT2) if `altwt'
			if `"`xwt'"'!=`""' & `"`altwt'"'==`""' {
				qui replace `_WT' = 100*`_WT' / r(sum) if `touse'
				// ^^ if *not* altwt, also normalize the "standard" weight, for storing in memory as _WT
				// Use the same value of r(sum);  this is the cumulative sum applicable to both `_WT' and `_WT2'
			}
		
		}
		return matrix ovstats = `ovstats'		// needs to be returned separately from "return add" above, as it has been edited

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
		if "`teststat'"!="t" local toremove `toremove' df
		if inlist("`model'", "mh", "peto", "iv", "ivhet", "qe", "mu") ///
			| inlist("`model'", "bt", "hc", "pl") | "`kroger'"!="" {
			local toremove `toremove' rflci rfuci
			if `"`proportion'"'!=`""' local toremove `toremove' prop_rflci prop_rfuci
		}
		
		// [Sep 2020:]
		// Note: Heterogeneity stats derived from the *data*, independently of model (i.e. Q Qdf H Isq)
		//  are returned in r() rather than stored in a matrix

		// "parametrically-defined Isq" -based heterogeneity values, if requested [i.e. derived from Isq = tsq/(tsq+sigmasq) ]
		// are stored in matrix r(hetstats) [and byhet1...byhet`nby' for subgroups]
		// (plus tsq + CI itself)

		// model-based tausq confidence intervals
		if !inlist("`model'", "mp", "pmm", "ml", "pl", "reml", "bt", "dlb") local toremove `toremove' tsq_lci tsq_uci

		// common-effect models: no tausq
		if inlist("`model'", "peto", "mh", "iv", "mu") local toremove `toremove' tausq /*sigmasq*/
		if "`model'"!="mu" local toremove `toremove' phi	// added Sep 2023
		foreach el in t chi2 u {
			if "`teststat'"!="`el'" local toremove `toremove' `el'
		}
		local rownames_reduced_by : list rownames - toremove
		
		tempname bystats byhet byQ mwt
		
		local nby : word count `bylist'		// N.B. `bylist' derived within metan_analysis, accounting for `keepall'
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
		local wtvar
		if `"`sgwt'"'!=`""' local wtvar `_WT'
		else {		// Jun 2022: else define `mwt' in advance
			matrix define `mwt' = J(1, `nby', .)
			matrix colnames `mwt' = `bylist'
			matrix rownames `mwt' = `modelstr'
		}
		
		forvalues i = 1 / `nby' {
			local byi : word `i' of `bylist'
			qui count if `touse' & float(`by')==float(`byi')
			local rN = r(N)
			
			// May 2020: Usually, `rN' should equal r(k)
			// BUT if 2x2 count data (or proportion data) and nocc then mh and peto will use all studies = `rN'
			//  but iv-based methods can only use studies with non-missing _ES and _seES = r(k)
			// Hence, for later logic-checking, setup r(k)==`rN' or <=`rN' as appropriate.
			// (Note: back in the main routine, a final check will be made that all observations are handled correctly via _USE)
			local equals `"=="'
			cap summ `_CC' if `touse' & float(`by')==float(`byi'), meanonly
			if !_rc & r(N) local equals `"<="'

			
			** Cumulative/influence analysis
			// Run extra loop to store results of each iteration within the currrent dataset (`xoutvlist')
			local rc = 0
			if `"`cumulative'`influence'"' != `""' {
			
				// Moved/amended March 2020:  mainly for cumulative/influence but useful in small ways regardless
				qui bysort `touse' `by' (`sortby') : replace `obsj' = _n if `touse'

				cap nois CumInfLoop `_ES' `_seES' if `touse' & float(`by')==float(`byi'), sortby(`obsj') ///
					model(`model') summstat(`summstat') teststat(`teststat') `qstat' `testbased' `isqparam' ///
					mhvlist(`mhvlist') oevlist(`oevlist') invlist(`invlist') xoutvlist(`xoutvlist') ///
					wgt(`wgt') wtvar(`wtvar') rownames(`rownames') `nptsopt' ///
					`cumulative' `influence' `integer' `logrank' `proportion' `sgwt' `opts_model'

				local rc = _rc
				if _rc {
					if _rc==2000 local nrc_2000 = 1
					else if _rc==2001 local nrc_2001 = 1
					else if _rc==2002 local nrc_2002 = 1
					else {
						if `"`err'"'==`""' {
							if _rc==1 nois disp as err "User break in {bf:metan_analysis.CumInfLoop}"
							else nois disp as err `"Error in {bf:metan_analysis.CumInfLoop}"'
						}	
						c_local err noerr		// tell -metan- not to also report an "error in metan_analysis.PerformMetaAnalysis"
						exit _rc
					}
				}
				else {
					foreach el in rc_tausq rc_tsq_lci rc_tsq_uci rc_eff_lci rc_eff_uci {
						if !inlist(r(`el'), 0, 2, .)   local n`el' = 1
					}
				}
				
				local xwt `r(xwt)'			// extract _WT2 from `xoutvlist'
			}
			
			
			** Main subgroup meta-analysis			    
			cap nois PerformPooling `_ES' `_seES' if `touse' & float(`by')==float(`byi'), ///
				model(`model') summstat(`summstat') teststat(`teststat') `qstat' `testbased' `isqparam' ///
				mhvlist(`mhvlist') oevlist(`oevlist') invlist(`invlist') `nptsopt' wtvar(`wtvar') wgt(`wgt') ///
				`integer' `logrank' `proportion' `opts_model'
			local rc = _rc
			if _rc {
				if _rc==2000 local nrc_2000 = 1
				else if _rc==2001 local nrc_2001 = 1
				else if _rc==2002 local nrc_2002 = 1
				else {
					if `"`err'"'==`""' {					
						if _rc==1 nois disp as err "User break in {bf:metan_analysis.PerformPooling}"
						else nois disp as err `"Error in {bf:metan_analysis.PerformPooling}"'
					}
					c_local err noerr		// tell -metan- not to also report an "error in metan_analysis.PerformMetaAnalysis"
					exit _rc
				}
			}
			else {
				foreach el in rc_tausq rc_tsq_lci rc_tsq_uci rc_eff_lci rc_eff_uci {
					if !inlist(r(`el'), 0, 2, .)   local n`el' = 1
				}
			}
			
			** If `cumulative', copy pooled results into final cumulative observation
			if `"`cumulative'"'!=`""' /*& `rc' != 2000*/ {
				local toremove npts
				local xrownames : list rownames - toremove
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
				args _ES _seES _LCI _UCI _WT _NN _CC
			}		// end if `"`cumulative'"'!=`""' & `rc' != 2000 

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

			local sgk = cond(missing(r(k)), 0, r(k))
			if `sgk'==0 assert `rc'==2000
			assert `sgk' `equals' `rN'
			scalar `kOV' = `kOV' + `sgk'
			if !missing(r(npts)) {
				scalar `nOV' = cond(missing(`nOV'), 0, `nOV') + r(npts)
			}
			
			// [Nov 2020] `nsg' will have been updated by PerformPooling
			// if `nsg' local nsg_list `nsg_list' `byi'
			if `sgk'==1 {
				local nsg_list `nsg_list' `byi'
				local nsg = 1
			}
			if `sgk'<3 local nrfd = 1
			
			// [July 2022] r(k_npts) and r(nzt) will have been updated by PerformPooling
			if `"`r(k_npts)'"'!=`""' {
				if r(k_npts) < r(k) local nmiss = 1
			}
			if "`nzt'"!="1" local nzt = !inlist("`r(nzt)'", "0", "", ".")
			
			
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
				
				// END OF REFERENCES TO RETURN LIST r() FROM PerformPooling
				
				// Normalise weights by subgroup (if `sgwt')
				if `"`sgwt'"'!=`""' {
					local _WT2 = cond(`"`xwt'"'!=`""', `"`xwt'"', `"`_WT'"')		// use _WT2 from `xoutvlist' if applicable
					summ `_WT' if `touse' & float(`by')==float(`byi'), meanonly
					qui replace `_WT2' = 100*cond(`"`altwt'"'!=`""', `_WT', `_WT2') / r(sum) ///
						if `touse' & float(`by')==float(`byi')		// use *original* weights (_WT) rather than cumul/infl weights (_WT2) if `altwt'
				}
				
				// Save subgroup weights from multiple models, in matrix `mwt'
				// N.B. Need to do this here, not within PerformPooling, since otherwise it won't have been normalised
				else {
					summ `_WT' if `touse' & float(`by')==float(`byi'), meanonly
					matrix `mwt'[1, `i'] = r(sum)
				}
			}		// end if [PerformPooling ran successfully]
			
		}	// end forvalues i = 1 / `nby'		
				
		if `"`overall'"'==`""' | `"`ovwt'"'!=`""' {
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
						matrix `bystats2'[rownumb(`bystats2', "`el'"), `i'] = `bystats'["`el'", `i']
					}
					else assert missing(`bystats'[rownumb(`bystats', "`el'"), `i'])
				}
			}	
			matrix define `bystats' = `bystats2'
		}
		
		tempname avg_eff eff_i se_eff_i Qbet Fstat
		scalar `avg_eff' = `avg_eff_num' / `avg_eff_denom'
		scalar `Qbet' = 0
		local nby1 = 0					// alternative `nby' reflecting the number of subgroups *with data in*
		forvalues i = 1 / `nby' {		// use `nby' so that the sum becomes missing if any subgroups are missing
			// Modified July 2024 to avoid errors with Stata 15 and older
			// "matrix operators that return matrices not allowed in this context
			local r = rownumb(`bystats', "eff")
			scalar `eff_i'    = `bystats'[`r', `i']
			local r = rownumb(`bystats', "se_eff")
			scalar `se_eff_i' = `bystats'[`r', `i']
			scalar `Qbet' = `Qbet' + ((`eff_i' - `avg_eff') / `se_eff_i')^2
			if !missing(`eff_i'/`se_eff_i') local ++nby1
		}
		scalar `Fstat' = (`Qbet'/(`nby' - 1)) / (`Qsum'/(`scQdf' - `nby' + 1))
		
		// May 2020:
		// Calculate "common tausq" (across subgroups); and between-subgroup Q statistic
		// c.f. Borenstein et al (2009) "Introduction to Meta-analysis", chapter 19
		tempname tsq_common
		scalar `tsq_common' = max(0, (`Qsum' - (`k' - `nby1')) / `csum')
		
		// Return
		return scalar tsq_common = `tsq_common'
		return scalar Qsum = `Qsum'
		return scalar Qbet = `Qbet'
		return scalar Fstat = `Fstat'
		return scalar nby = `nby1'

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
			if inlist("`model'", "iv", "mh", "peto", "mu") {
				matrix define `byhet' = `byhet'["H", 1...] \ `byhet'["Isq", 1...] \ `byhet'["HsqM", 1...]
			}
			else if !inlist("`model'", "mp", "pmm", "ml", "pl", "reml", "bt", "dlb") {
				matrix define `byhet' = `byhet'["tausq", 1...] \ `byhet'["H", 1...] \ `byhet'["Isq", 1...] \ `byhet'["HsqM", 1...]
			}
			matrix colnames `byhet' = `modelstr'
			matrix coleq    `byhet' = `bylist'
			return matrix byhet = `byhet'
		}
		
	}	// end if `"`by'"'!=`""' & (`"`subgroup'"'==`""' | `"`sgwt'"'!=`""')

	// Error messages
	/*
	foreach el in rc_2000 rc_2002 rc_tausq rc_tsq_lci rc_tsq_uci rc_eff_lci rc_eff_uci {
		c_local n`el' = cond(inlist("`n`el''", "", "."), "0", "`n`el''")
	}
	c_local nrfd = cond(inlist("`nrfd'", "", "."), "0", "`nrfd'")	// update marker of "one or more subgroups has < 3 studies" (for rfdist)
	c_local nsg  = cond(inlist("`nsg'", "", "."), "0", "`nsg'")		// update marker of "one or more subgroups contain only a single valid estimate"
	c_local nzt  = cond(inlist("`nzt'", "", "."), "0", "`nzt'")		// update marker of "HKSJ has resulted in a shorter CI than IV in one or more subgroups"
	// c_local nmiss = cond(inlist("`nmiss'", "", "."), "0", "`nmiss'")	// update marker of "Patient numbers are missing in one or more trials"
	*/
	foreach el in rc_2000 rc_2002 rc_tausq rc_tsq_lci rc_tsq_uci rc_eff_lci rc_eff_uci {
		c_local n`el' `n`el''
	}
	return scalar nmiss = `nmiss'
	return scalar nrfd = `nrfd'
	return scalar nsg = `nsg'
	return scalar nzt = `nzt'
	
	return scalar n = `n'			// number of patients for which `touse' & `_USE'==1 & non-missing effect size
	return scalar k = `k'			// number of observations for which `touse' & `_USE'==1 & non-missing effect size

end



***************************************************
* Stata subroutines called by PerformMetaAnalysis *  (and its subroutines)
***************************************************


* ProcessPoolingVarlist
// subroutine of PerformMetaAnalysis

// subroutine to processes (non-IV) input varlist to create appropriate varlist for the specified pooling method
// That is, generate study-level effect size variables,
// plus variables used to generate overall/subgroup statistics

program define ProcessPoolingVarlist, sclass

	syntax varlist(numeric min=2 max=6 default=none) [if] [in], ///
		SUMMSTAT(name) MODEL(name) TESTSTAT(name) OUTVLIST(varlist numeric min=5 max=7) ///
		[ TVLIST(namelist) CCLIST(namelist) ///
		LOGRank PRoportion noINTeger CC(string) WGT(name) ]
	
	sreturn clear
	marksample touse, novarlist
	
	// unpack varlists
	tokenize `outvlist'
	args _ES _seES _LCI _UCI _WT _NN _CC

	local invlist : copy local varlist
	tokenize `invlist'
	local params : word count `invlist'
	
	
	** Setup for logrank HR (O-E & V)
	if "`logrank'"!="" {
		args oe va
		qui replace `_ES'   = `oe'/`va'    if `touse'		// logHR
		qui replace `_seES' = 1/sqrt(`va') if `touse'		// selogHR
		sreturn local oevlist `oe' `va'
	}

	
	** Setup for proportions
	else if "`proportion'"!="" {
		args succ _NN
		
		// Continuity correction: already prepared by ParseModel (for `ccval'>0)
		if `"`cc'"'!=`""' {
			local 0 `"`cc'"'
			syntax [anything(name=ccval)] [, MHUNCORR /* Internal option only */ * ]
			if "`options'"!="" {
				nois disp as err "options not allowed"
				exit 101
			}
			cap confirm numeric variable `_CC'
			local genreplace = cond(_rc, "gen byte", "replace")
			qui `genreplace' `_CC' = inlist(`succ', 0, `_NN')
			summ `_CC' if `touse', meanonly
			local nz = r(sum)
			if !`nz' local cc		// ... if continuity correction is *applicable*
			else {					// (N.B. from now on, -confirm numeric var `ccvar'- will be used to check if cc was applied)
				tempvar succ_cc fail_cc
				qui gen double `succ_cc' = cond(`_CC', `succ' + `ccval', `succ')
				qui gen double `fail_cc' = cond(`_CC', `_NN' - `succ' + `ccval', `_NN' - `succ')
			}
		}
		if `"`cc'"'==`""' {
			local succ_cc `succ'
			local fail_cc `_NN' - `succ'
		}
		
		// Proportions on original scale (default)
		if "`summstat'"=="pr" {
			qui replace `_ES' = `succ' / `_NN' if `touse'
			qui replace `_seES' = sqrt(`succ_cc' * (`fail_cc') / (`succ_cc' + `fail_cc')^3 ) if `touse'
			qui replace `_seES' = . if `touse' & `_seES'==0
		}
		
		// Transformed proportions, as described by Schwarzer et al, RSM 2019
		// (but note: Freeman-Tukey is as originally described, i.e. as sum of arcsines rather than mean
		//   see Freeman & Tukey, Annals of Mathematical Statistics 1950;  Miller, American Statistician 1978)
		else {
			if "`summstat'"=="ftukey" {
				qui replace `_ES' = asin(sqrt(`succ' / (`_NN' + 1 ))) + asin(sqrt((`succ' + 1 ) / (`_NN' + 1 ))) if `touse'
				qui replace `_seES' = 1 / sqrt(`_NN' + .5) if `touse'
			}
			else if "`summstat'"=="arcsine" {
				qui replace `_ES' = asin(sqrt(`succ' / `_NN')) if `touse'
				qui replace `_seES' = 1 / sqrt(4 * `_NN') if `touse'
			}
			else if "`summstat'"=="logit" {
				qui replace `_ES' = logit(`succ_cc' / (`succ_cc' + `fail_cc')) if `touse'
				qui replace `_seES' = sqrt((1/`succ_cc') + (1/(`fail_cc'))) if `touse'
				qui replace `_seES' = . if `touse' & `_seES'==0
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
				cap confirm numeric variable `_CC'
				local genreplace = cond(_rc, "gen byte", "replace")
				qui `genreplace' `_CC' = `e1'*`f1'*`e0'*`f0'==0
				summ `_CC' if `touse', meanonly
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
						
						// at least one study *without* zero counts needed to estimate "prior"
						// qui count if `touse'
						if r(N) == r(sum) {
							nois disp as err "Insufficient data to implement empirical continuity correction"
							exit 498
						}

						tempvar R cc1 cc0
						qui metan `e1' `f1' `e0' `f0' if `touse', model(`model') `summstat' nocc nograph notable nohet
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
						qui gen double `e1_cc' = cond(`_CC', `e1' + `cc1', `e1')
						qui gen double `f1_cc' = cond(`_CC', `f1' + `cc1', `f1')
						qui gen double `e0_cc' = cond(`_CC', `e0' + `cc0', `e0')
						qui gen double `f0_cc' = cond(`_CC', `f0' + `cc0', `f0')
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
						qui replace `_ES'   = `oe'/`va'    if `touse'	// log(Peto OR)
						qui replace `_seES' = 1/sqrt(`va') if `touse'	// selogOR
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
					
					qui replace `_ES'   = ln(`r'/`s') if `touse'
					qui replace `_seES' = sqrt(`v')   if `touse'
					
					// setup for Mantel-Haenszel method
					if "`model'"=="mh" {
						tempvar p q
						
						if `nz' & "`mhuncorr'"!="" {						// default; uncorrected
							// first, check for zero total R or S, as this means that zero correction is unavoidable ("mhallzero")
							tempvar r2 s2
							local mhallzero
							qui gen double `r2' = `e1' * `f0' / `_NN'		// this is uncorrected `r'
							summ `r2' if `touse', meanonly
							if r(N) & !r(sum) local mhallzero mhallzero

							qui gen double `s2' = `f1' * `e0' / `_NN'		// this is uncorrected `s'
							summ `s2' if `touse', meanonly
							if r(N) & !r(sum) local mhallzero mhallzero

							if `"`mhallzero'"'!=`""' & `ccval' {
								sreturn local mhallzero `mhallzero'			// notify PerformMetaAnalysis
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
				qui replace `_ES'   = ln(`r'/`s') if `touse'					// logRR 
				qui replace `_seES' = sqrt(`v')   if `touse'					// selogRR

				// setup for Mantel-Haenszel method
				if "`model'"=="mh" {
					
					if `nz' & "`mhuncorr'"!="" {						// default; uncorrected
						// first, check for zero total R or S, as this means that zero correction is unavoidable ("mhallzero")
						tempvar r2 s2
						local mhallzero
						qui gen double `r2' = `e1' * `r0' / `_NN'		// this is uncorrected `r'
						summ `r2' if `touse', meanonly
						if r(N) & !r(sum) local mhallzero mhallzero
						
						qui gen double `s2' = `e0' * `r1' / `_NN'		// this is uncorrected `s'
						summ `s2' if `touse', meanonly
						if r(N) & !r(sum) local mhallzero mhallzero

						if `"`mhallzero'"'!=`""' & `ccval' {
							sreturn local mhallzero `mhallzero'			// notify PerformMetaAnalysis
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
				qui replace `_ES'   = `e1'/`r1' - `e0'/`r0' if `touse'
				qui replace `_seES' = sqrt(`v')             if `touse'

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
				qui replace `_ES'   = `mean1' - `mean0'                     if `touse'
				qui replace `_seES' = sqrt((`sd1'^2)/`n1' + (`sd0'^2)/`n0') if `touse'
			}
			else {				// summstat = SMD
				tempvar s
				qui gen double `s' = sqrt( ((`n1'-1)*(`sd1'^2) + (`n0'-1)*(`sd0'^2) )/( `_NN' - 2) )

				if "`summstat'" == "cohend" {
					qui replace `_ES'   = (`mean1' - `mean0')/`s'                                      if `touse'
					qui replace `_seES' = sqrt((`_NN' /(`n1'*`n0')) + (`_ES'*`_ES'/ (2*(`_NN' - 2)) )) if `touse'
				}
				else if "`summstat'" == "glassd" {
					qui replace `_ES'   = (`mean1' - `mean0')/`sd0'                                    if `touse'
					qui replace `_seES' = sqrt(( `_NN' /(`n1'*`n0')) + (`_ES'*`_ES'/ (2*(`n0' - 1)) )) if `touse'
				}
				else if "`summstat'" == "hedgesg" {
					qui replace `_ES'   = (`mean1' - `mean0')*(1 - 3/(4*`_NN' - 9))/`s'                    if `touse'
					qui replace `_seES' = sqrt(( `_NN' /(`n1'*`n0')) + (`_ES'*`_ES'/ (2*(`_NN' - 3.94)) )) if `touse'
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

	syntax varlist(numeric min=2 max=6) [if] [in], SORTBY(varname numeric) ///
		MODEL(passthru) XOUTVLIST(varlist numeric) ///
		[CUmulative INFluence OVWt SGWt ROWNAMES(namelist) * ]
	
	marksample touse, novarlist
	local pvlist : copy local varlist	// pvlist = "pooling varlist"
		
	local toremove npts
	local xrownames : list rownames - toremove
	local xrownames `xrownames' Q Qdf Q_lci Q_uci
	if `: list posof "tausq" in rownames' local xrownames `xrownames' sigmasq
	
	tokenize `xoutvlist'
	args `xrownames' _WT2

	// return name of `_WT2' in `xoutvlist'
	return local xwt `_WT2'

	// Added Jan 2020, amended Mar 2020
	qui count if `touse'
	if !r(N) exit 2000
	
	// Amended Sep 2022
	// If `cumulative' or `influence' and no weights (no `sgwt'`ovwt') or only a single observation
	// exit subroutine early
	if `"`cumulative'`influence'"'!=`""' & (`"`sgwt'`ovwt'"'==`""' | r(N)==1) {
		exit 2001
	}
	
	// Note: if `cumulative', last analysis will be done separately, by PerformMetaAnalysis
	//    Therefore, if `n'=1 then `jmax'==0 and loop below is skipped
	local jmax = `r(N)' - (`"`cumulative'"'!=`""')
	
	tempvar touse2
	forvalues j = 1/`jmax' {

		// Define `touse' for *input* (i.e. which obs to meta-analyse)
		if `"`cumulative'"'!=`""' qui gen byte `touse2' = `touse' * inrange(`sortby', 1, `j')		// cumulative: obs from 1 to `j'
		else                      qui gen byte `touse2' = `touse' * (`sortby' != `j')				// influence: all obs except `j'

		cap nois PerformPooling `pvlist' if `touse2', `model' `options'

		if _rc {
			if _rc==2000 c_local nrc_2000 = 1
			else if _rc==2001 c_local nrc_2001 = 1
			else if _rc==2002 c_local nrc_2002 = 1
			else {
				if _rc==1 nois disp as err `"User break in {bf:metan_analysis.PerformPooling}"'
				else nois disp as err `"Error in {bf:metan_analysis.PerformPooling}"'
				c_local err noerr		// tell -metan- not to also report an "error in metan_analysis.CumInfLoop"
				exit _rc
			}
		}

		
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
	
	//local nrfd = 0		// initialize marker of "less than 3 studies" (for rfdist)
	//local nsg  = 0		// initialize marker of "only a single valid estimate" (e.g. for by(), or cumul/infl)
	//local nzt  = 0		// initialize marker of "HKSJ has resulted in a shorter CI than IV" (for HKSJ)	
	
	marksample touse, novarlist		// in case of binary 2x2 data with no cases in one or both arms; this will be dealt with later
	qui count if `touse'
	if !r(N) {
		// nois disp as err "no observations"
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
		c_local err noerr		// tell -metan- not to also report an "error in metan_analysis.PerformPooling"
		if "`model'"=="mh" return add
		exit _rc
	}
	
	c_local nzt `nzt'		// update marker of "HKSJ has resulted in a shorter CI than IV" (for HKSJ)

	return add
	
end



// Inverse variance (i.e. all except Mantel-Haenszel)
program define PerformPoolingIV, rclass

	syntax varlist(numeric min=2 max=2) [if] [in], MODEL(name) ///
		[SUMMSTAT(name) TESTSTAT(name) QSTAT(passthru) TESTBased ISQParam ///
		OEVLIST(varlist numeric min=2 max=2) INVLIST(varlist numeric min=2 max=6) ///
		NPTS(varname numeric) WGT(varname numeric) WTVAR(varname numeric) ///
		HKsj KRoger BArtlett SKovgaard RObust LOGRank PRoportion TN(string) POVERV(real 2) /*noTRUNCate*/ TRUNCate(string) EIM OIM ///
		ISQSA(real -99) TSQSA(real -99) PHISA(real -99) HETPooled /*Added Sep 2023*/ QWT(varname numeric) INIT(name) ///
		OLevel(cilevel) HLevel(cilevel) RFLevel(cilevel) CItype(passthru) ///
		ITOL(real 1.0x-1a) MAXTausq(real -9) REPS(real 1000) MAXITer(real 1000) QUADPTS(real 100) DIFficult TECHnique(string) * ]

	// N.B. extra options should just be those allowed for PerformPoolingMH

	// if no wtvar, gen as tempvar
	if `"`wtvar'"'==`""' {
		local wtvar
		tempvar wtvar
		qui gen double `wtvar' = .
	}	
	else {
		marksample touse, novarlist		// June 2022: temporary marksample, consistent across models (c.f. I-V and no CC; see elsewhere)
		qui replace `wtvar' = . if `touse'
	}

	local pvlist `varlist'		// for clarity
	tokenize `pvlist'
	args _ES _seES
	qui replace `_seES' = . if float(`_seES')<=0	// added June 2022
	marksample touse			// note: *NO* "novarlist" option here	
	
	// Firstly, check whether only one study
	//   if so, cancel random-effects and set to defaults: iv, cochranq, testbased
	// t-critval ==> es, se, lci, uci returned but nothing else
	tempname k	
	qui count if `touse'
	if !r(N) exit 2000		// no observations *after* effect of marksample, novarlist
	scalar `k' = r(N)
	if `k' == 1 & "`hetpooled'"=="" {
		if !inlist("`model'", "peto", "qe") {
			local model iv
			local isqparam
		}
		local teststat z
		local hksj
	}
	
	// New June 2022
	if `"`npts'"'!=`""' {
		summ `npts' if `touse', meanonly
		return scalar k_npts = r(N)
		if r(N) return scalar npts = r(sum)
		// if r(N)!=`k' c_local nmiss = 1		// marker of "pt. numbers are missing in one or more trials"
	}
	return scalar k = `k'
	
	
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
		
	tempname eff se_eff crit pvalue
	qui replace `wtvar' = 1/`_seES'^2 if `touse'
	qui summ `_ES' [aw=`wtvar'] if `touse' /*, meanonly*/
	scalar `eff' = r(mean)
	scalar `se_eff' = 1/sqrt(r(sum_w))		// I-V common-effect SE

	// Derive Cochran's Q
	assert r(N) == `k'
	tempname Q Qdf
	scalar `Q' = cond(missing(r(Var)), 0, r(Var)*r(sum_w)*(r(N)-1)/r(N))
	scalar `Qdf' = r(N) - 1
	
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
	
	if "`hetpooled'"=="" {
		
		** Setup two-stage estimators sj2s and dk2s
		// consider *initial* estimate of tsq
		if inlist("`model'", "sj2s", "dk2s") {
			local final `model'
			local model `"`init'"'
			
			/*
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
			*/
		}
		
		** Hartung-Makambi estimator (>0)
		// [Note Sep 2023] *NOT* "else if", because of potential role-switch of `model' and `init' above
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
				scalar `tausq' = `var_eff'*(`k' - 1)/`k'
			}
			
			// Hedges aka "variance component" aka Cochran ANOVA-type estimator
			else if "`model'"=="he" {
				scalar `tausq' = `var_eff' - `meanv'
			}
			
			// Rukhin Bayes estimators
			else if inlist("`model'", "b0", "bp") {
				scalar `tausq' = `var_eff'*(`k' - 1)/(`k' + 1)
				if "`model'"=="b0" {
					confirm numeric var `npts'
					summ `npts' if `touse', meanonly	
					scalar `tausq' = `tausq' - ( (`r(sum)' - `k')*`Qdf'*`meanv'/((`k' + 1)*(`r(sum)' - `k' + 2)) )
				}
			}
			scalar `tausq' = max(0, `tausq')	// truncate at zero
		}
	}
	
	// Sensitivity analysis: use given Isq/tausq and sigmasq to generate tausq/Isq
	if "`model'"=="sa" | "`hetpooled'"!="" {		// modified Sep 2023
		if `tsqsa'==-99 scalar `tausq' = `isqsa'*`sigmasq'/(100 - `isqsa')
		else if `phisa'==-99 scalar `tausq' = `tsqsa'
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
	if "`hetpooled'"=="" & inlist("`model'", "dlb", "mp", "pmm", "ml", "pl", "reml") {
	
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
		
		// Mandel-Paule aka empirical Bayes (DerSimonian and Kacker CCT 2007)
		// or median-unbiased estimator suggested by Viechtbauer (2021)
		// N.B. Mata routine also performs the Viechtbauer Q-profiling routine for tausq CI
		// (Viechtbauer Stat Med 2007; 26: 37-52)
		else if inlist("`model'", "mp", "pmm") {
			cap nois mata: GenQ("`_ES' `_seES'", "`touse'", `hlevel', (`maxtausq', `itol', `maxiter'), "`model'")
		}
		
		// REML
		// N.B. Mata routine also performs likelihood profiling to give tausq CI
		else if "`model'"=="reml" {
			local hmethod = cond("`difficult'"!="", "hybrid", "m-marquardt")	// default = m-marquardt
			if "`technique'"=="" local technique nr								// default = nr
			cap nois mata: REML("`_ES' `_seES'", "`touse'", `hlevel', (`maxtausq', `itol', `maxiter'), "`hmethod'", "`technique'")
			if `"`r(ll_negtsq)'"'!=`""' {
			    disp `"{error}tau-squared value from last iteration was negative, so has been set to zero"'
			}
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
			if `"`r(ll_negtsq)'"'!=`""' {
			    disp `"{error}tau-squared value from last iteration was negative, so has been set to zero"'
			}			
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
			else if _rc nois disp `"{error}Error(s) detected during running of Mata code; please check output"'
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
		
	}	// end if inlist("`model'", "dlb", "mp", "pmm", "ml", "pl", "reml")
		// [i.e. iterative tausq estimators]
	
	// end of "Iterative, using Mata" section



	******************************************************
	* User-defined weights; finalise two-step estimators *
	******************************************************

	if `"`wgt'"'!=`""' {
		qui replace `wtvar' = `wgt' if `touse'
	}
	
	tempvar Qhet
	tempname Qr				// will also be used for post-hoc variance correction
	if "`final'"!="" {
		tempvar wt0
		qui gen double `wt0' = 1/((`_seES'^2) + `tausq')
		qui summ `_ES' [aw=`wt0'] if `touse'
		scalar `eff' = r(mean)		
		assert r(N) == `k'
		scalar `Qr' = cond(missing(r(Var)), 0, r(Var)*r(sum_w)*(r(N)-1)/r(N))
		
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
			summ `wt0' [aw=`wt0'] if `touse', meanonly
			scalar `wi1' = r(sum_w)				// sum of weights
			scalar `wi2' = r(sum)				// sum of squared weights				
			summ `wt0' [aw=`_seES'^2] if `touse', meanonly
			scalar `wis1' = r(sum)				// sum of weight * variance
			summ `wt0' [aw=`wt0' * (`_seES'^2)] if `touse', meanonly
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
	// DF: Modified Dec 2021 to avoid rounding errors/negative weights when `qwt' is zero
	if "`model'"=="qe" {

		// check `qwt' >= 0
		cap nois {
			confirm numeric variable `qwt'
			summ `qwt' if `touse', meanonly
			assert r(min) >= 0
		}
		if _rc {
			nois disp as err `"error in option {bf:qwt()}: variable {bf:`qwt'} must be numeric with no negative values"'
			exit 2002
		}
		if r(sum)==0 {
			nois disp as err `"error in option {bf:qwt()}: no non-zero quality weights found"'
			exit 2002
		}
		
		// re-scale scores relative to highest value
		tempname qmax qsum
		scalar `qmax' = r(max)
		scalar `qsum' = r(sum)
		tempvar newqe
		qui gen double `newqe' = `qwt' / `qmax'
		
		tempname sumwt
		summ `wtvar' if `touse', meanonly
		scalar `sumwt' = r(sum)				// sum of original weights (inverse-variances)

		// correction to reduce estimator bias (Appendix A of CCT 2015, but without factor of 1/(k-1) as this cancels anyway)
		tempvar tauqe
		qui gen double `tauqe' = 0
		qui replace `tauqe' = `wtvar' * (1 - `newqe') if `newqe' < 1
		summ `tauqe' if `touse', meanonly
		
		// Point estimate uses weights = qi/vi + tauhati
		// ...but expressions presented in CCT 2015 involve addition & subtraction of very similar quantities with risk of rounding error.
		// Instead, we use the expression below, which can be shown to be equivalent to Equation 7 of CCT 2015
		qui replace `wtvar' = `newqe' * (`wtvar' + (r(sum) * `qmax' / `qsum')) if `touse'		
		summ `wtvar' if `touse', meanonly

		cap assert float(r(sum))==float(`sumwt')	// compare sum of new weights with sum of original weights
		if _rc {
			local rc = _rc
			if r(sum)==0 {
				cap assert `qsum'==0
				if !_rc nois disp as err `"error in option {bf:qwt()}: no non-zero quality weights found"'
				else nois disp as err "Error encountered whilst calculating quality weights"	// DF Dec 2021: this error message should never be seen
			}
			else nois disp as err "Error encountered whilst calculating quality weights"		// DF Dec 2021: this error message should never be seen
			exit `rc'
		}
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
			else if _rc nois disp `"{error}Error(s) detected during running of Mata code; please check output"'
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
			else if _rc nois disp `"{error}Error(s) detected during running of Mata code; please check output"'
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
			qui gen double `Qhet' = ((`_ES' - `eff') / `_seES')^2
			summ `Qhet' if `touse', meanonly
			scalar `Q' = cond(r(N), r(sum), .)
		}
	}
	
	// Standard weighting based on additive tau-squared
	// (N.B. if iv or mu, eff and se_eff have already been calculated)
	else if !inlist("`model'", "iv", "peto", "mu") & `phisa'==-99 {
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
		cap drop `Qhet'
		qui gen double `Qhet' = `wtvar'*((`_ES' - `eff')^2)
		summ `Qhet' if `touse', meanonly
		scalar `Qr' = cond(r(N), r(sum), .)
	}
	scalar `Hstar' = sqrt(`Qr'/`Qdf')
	
	// Multiplicative heterogeneity (e.g. Thompson and Sharp, Stat Med 1999)
	// (equivalent to the "full variance" estimator suggested by Sandercock
	// (https://metasurv.wordpress.com/2013/04/26/
	//    fixed-or-random-effects-how-about-the-full-variance-model-resolving-a-decades-old-bunfight)

	// Hartung-Knapp-Sidik-Jonkman variance estimator
	// (Roever et al, BMC Med Res Methodol 2015; Jackson et al, Stat Med 2017; van Aert & Jackson, Stat Med 2019)

	local nzt = 0
	if "`model'"=="sa" | "`hetpooled'"!="" {	// added Sep 2023
		if `phisa'!=-99 {
			scalar `Hstar' = sqrt(`phisa')
			scalar `se_eff' = `se_eff' * `Hstar'
			scalar `Qr' = `Qr'/`phisa'
		}
	}
	else if "`model'"=="mu" | "`hksj'"!="" {
		tempname tcrit zcrit
		scalar `zcrit' = invnormal(.5 + `olevel'/200)
		scalar `tcrit' = invttail(`Qdf', .5 - `olevel'/200)
		
		// van Aert & Jackson 2019: truncate at z/t
		if "`truncate'"=="zovert" scalar `Hstar' = max(`zcrit'/`tcrit', `Hstar')
		else {
			// (e.g.) Roever 2015: truncate at 1
			// i.e. don't use if *under* dispersion present
			if inlist(`"`truncate'"', `"one"', `"1"') scalar `Hstar' = max(1, `Hstar')
			else if `"`truncate'"'!=`""' {
				nois disp as err `"invalid use of {bf:truncate()} option"'
				exit 184
			}
			if "`hksj'"!="" & `Hstar' < `zcrit'/`tcrit' local nzt = 1		// setup error display for later
		}
		scalar `se_eff' = `se_eff' * `Hstar'
		if "`model'"=="mu" scalar `Qr' = `Qr'/(`Hstar'^2)
	}

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

	return scalar Hstar = `Hstar'
	return scalar nzt = `nzt'
	if "`model'"=="mu" | ("`hetpooled'"!="" & `phisa'!=99) {
		return scalar phi = `Hstar'^2
	}
	if !inlist("`model'", "iv", "peto") {
		return scalar Qr = `Qr'
	}


	**********************************************
	* Critical values, test statistics, p-values *
	**********************************************
	
	// Predictive intervals
	// (uses k-2 df, c.f. Higgins & Thompson 2009; but also see e.g. http://www.metafor-project.org/doku.php/faq#for_random-effects_models_fitt)
	if `k' >= 3 {
		tempname rfcritval rflci rfuci
		scalar `rfcritval' = invttail(`k'-2, .5 - `rflevel'/200)
		scalar `rflci' = `eff' - `rfcritval' * sqrt(`tausq' + `se_eff'^2)
		scalar `rfuci' = `eff' + `rfcritval' * sqrt(`tausq' + `se_eff'^2)
		
		return scalar rflci = `rflci'
		return scalar rfuci = `rfuci'
	}
	
	// Proportions
	if "`proportion'"!="" {
		tempname eff_lci eff_uci
		scalar `crit' = invnormal(.5 + `olevel'/200)
		scalar `eff_lci' = `eff' - `crit' * `se_eff'
		scalar `eff_uci' = `eff' + `crit' * `se_eff'
		
		
		** Back-transforms: special case
		// if k = 1, pass to GenConfIntsPr
		if `k'==1 {
			cap nois GenConfIntsPr `invlist' if `touse', `citype' level(`olevel')
			if _rc {
				if _rc==1 nois disp as err `"User break in {bf:metan_analysis.GenConfIntsPr}"'
				else nois disp as err `"Error in {bf:metan_analysis.GenConfIntsPr}"'
				c_local err noerr		// tell -metan- not to also report an "error in metan_analysis.PerformMetaAnalysis"
				exit _rc
			}
			return scalar prop_eff = r(es)
			return scalar prop_lci = r(lb)
			return scalar prop_uci = r(ub)
			
			if "`summstat'"=="pr" {			// if untransformed, set eff_lci, eff_uci to returned values from GenConfIntsPr
				scalar `eff_lci' = r(lb)
				scalar `eff_uci' = r(ub)
			}
		}
		else {
			tokenize `invlist'
			args succ _NN
		
			** Perform standard back-transforms
			// first, truncate intervals at `mintes' and `maxtes'
			tempname mintes maxtes
			scalar `mintes' = 0
			scalar `maxtes' = 1
			
			// Logit and Single-arcsine
			if inlist("`summstat'", "logit", "arcsine") {

				// Logit transform
				if "`summstat'"=="logit" {
					summ `_NN' if `touse', meanonly
					scalar `mintes' = logit(.1/`r(sum)')			// use limits of 1/10 difference from `totalN'
					scalar `maxtes' = logit(1 - (.1/`r(sum)'))
				}
				
				// Single arcsine transform
				else {
					scalar `mintes' = 0
					scalar `maxtes' = _pi/2
				}
				
				if      `eff' < `mintes' scalar `eff' = `mintes'
				else if `eff' > `maxtes' scalar `eff' = `maxtes'
				
				if      `eff_lci' < `mintes' scalar `eff_lci' = `mintes'
				else if `eff_lci' > `maxtes' scalar `eff_lci' = `maxtes'

				if      `eff_uci' < `mintes' scalar `eff_uci' = `mintes'
				else if `eff_uci' > `maxtes' scalar `eff_uci' = `maxtes'
				
				// Predictive intervals
				if `k' >= 3 {
					if      `rflci' < `mintes' scalar `rflci' = `mintes'
					else if `rflci' > `maxtes' scalar `rflci' = `maxtes'

					if      `rfuci' < `mintes' scalar `rfuci' = `mintes'
					else if `rfuci' > `maxtes' scalar `rfuci' = `maxtes'
				}
				
				
				** Perform back-transforms
				tempname prop_eff prop_lci prop_uci prop_rflci prop_rfuci

				// Logit transform
				if "`summstat'"=="logit" {
					return scalar prop_eff = invlogit(`eff')
					return scalar prop_lci = invlogit(`eff_lci')
					return scalar prop_uci = invlogit(`eff_uci')

					// Predictive intervals
					if `k' >= 3 {
						return scalar prop_rflci = invlogit(`rflci')
						return scalar prop_rfuci = invlogit(`rfuci')
					}
				}
				
				// Single arcsine back-transform
				else {
					return scalar prop_eff = sin(`eff')^2
					return scalar prop_lci = sin(`eff_lci')^2
					return scalar prop_uci = sin(`eff_uci')^2
					
					// Predictive intervals
					if `k' >= 3 {
						return scalar prop_rflci = sin(`rflci')^2
						return scalar prop_rfuci = sin(`rfuci')^2
					}
				}
			}
			
			
			** Freeman-Tukey double-arcsine transform
			// Do this separately, for several reasons; one of which is that, as the value of `hmean' is not fixed...
			// (e.g. suggested as harmonic mean by Miller, but without much justification, with equally reasonable alternatives suggested by e.g. Scharwzer and Doi)
			// ...there is little justification for truncating the transformed values at `mintes' and `maxtes'.
			// "Raw" values are therefore presented if option -nopr-
			// ...but these values *are* truncated prior to back-transformation (if requested) because a specific value of `hmean' then applies.
			else if "`summstat'"=="ftukey" {
				tempname hmean
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
			
				// Back-transform
				tempname prop_eff prop_lci prop_uci
				
				scalar  `prop_eff' = `eff'
				if      `prop_eff' < `mintes' scalar `prop_eff' = `mintes'
				else if `prop_eff' > `maxtes' scalar `prop_eff' = `maxtes'
				
				scalar  `prop_lci' = `eff_lci'
				if      `prop_lci' < `mintes' scalar `prop_lci' = `mintes'
				else if `prop_lci' > `maxtes' scalar `prop_lci' = `maxtes'

				scalar  `prop_uci' = `eff_uci'
				if      `prop_uci' < `mintes' scalar `prop_uci' = `mintes'
				else if `prop_uci' > `maxtes' scalar `prop_uci' = `maxtes'
				
				scalar `prop_eff' = 0.5 * (1 - sign(cos(`prop_eff')) * sqrt(1 - (sin(`prop_eff') + (sin(`prop_eff') - 1/sin(`prop_eff')) / `hmean')^2 ) )
				scalar `prop_lci' = 0.5 * (1 - sign(cos(`prop_lci')) * sqrt(1 - (sin(`prop_lci') + (sin(`prop_lci') - 1/sin(`prop_lci')) / `hmean')^2 ) )
				scalar `prop_uci' = 0.5 * (1 - sign(cos(`prop_uci')) * sqrt(1 - (sin(`prop_uci') + (sin(`prop_uci') - 1/sin(`prop_uci')) / `hmean')^2 ) )
		
				// Predictive intervals
				if `k' >= 3 {				
					tempname prop_rflci prop_rfuci
					
					scalar  `prop_rflci' = `rflci'
					if      `prop_rflci' < `mintes' scalar `prop_rflci' = `mintes'
					else if `prop_rflci' > `maxtes' scalar `prop_rflci' = `maxtes'

					scalar  `prop_rfuci' = `rfuci'
					if      `prop_rfuci' < `mintes' scalar `prop_rfuci' = `mintes'
					else if `prop_rfuci' > `maxtes' scalar `prop_rfuci' = `maxtes'
					
					scalar `prop_rflci' = 0.5 * (1 - sign(cos(`prop_rflci')) * sqrt(1 - (sin(`prop_rflci') + (sin(`prop_rflci') - 1/sin(`prop_rflci')) / `hmean')^2 ) )
					scalar `prop_rfuci' = 0.5 * (1 - sign(cos(`prop_rfuci')) * sqrt(1 - (sin(`prop_rfuci') + (sin(`prop_rfuci') - 1/sin(`prop_rfuci')) / `hmean')^2 ) )
				}
			
				if `"`tn'"'==`"ivariance"' {
					// To avoid problems with boundary values (i.e. proportions ~0 or ~1),
					// Barendregt & Doi use an extra check/truncation:
					// s/v < 2 or (1-s)/v < 2   (`poverv' = p/v = 2 by default but can be changed as undocumented option)
					// where s = sin(eff/2)^2 ~= d/n
					// and where v = se_eff ~= 1/n
					// ==> s/v ~= d;  (1-s)/v ~= n-d
									
					tempname prop_eff_prime
					scalar `prop_eff_prime' = sin(`eff'/2)^2
					if `prop_eff_prime' * `hmean' < `poverv' {
						scalar `prop_eff' = `prop_eff_prime'
						scalar `prop_lci' = 0
						if `k' >= 3 {
							scalar `prop_rflci' = 0
						}
						
						// adjust upper limit(s) if `prop_eff' is now inconsistent
						if `prop_uci'   < `prop_eff' scalar `prop_uci'   = 1
						if `k' >= 3 {
							if `prop_rfuci' < `prop_eff' scalar `prop_rfuci' = 1
						}
					}
					if (1 - `prop_eff_prime') * `hmean' < `poverv' {
						scalar `prop_eff' = `prop_eff_prime'
						scalar `prop_uci' = 1
						if `k' >= 3 {
							scalar `prop_rflci' = 1
						}
						
						// adjust lower limit(s) if `prop_eff' is now inconsistent
						if `prop_lci'   > `prop_eff' scalar `prop_lci'   = 0
						if `k' >= 3 {
							if `prop_rflci' > `prop_eff' scalar `prop_rflci' = 0
						}
					}
				}

				return scalar prop_eff = `prop_eff'
				return scalar prop_lci = `prop_lci'
				return scalar prop_uci = `prop_uci'
				
				// Predictive intervals
				if `k' >= 3 {
					return scalar prop_rflci = `prop_rflci'
					return scalar prop_rfuci = `prop_rfuci'
				}
			}		// end else if "`summstat'"=="ftukey"
			
			else {	// no transformation; "`summstat'"=="pr"
				return scalar prop_eff = `eff'
				return scalar prop_lci = `eff_lci'
				return scalar prop_uci = `eff_uci'
				
				// Predictive intervals
				if `k' >= 3 {			
					return scalar prop_rflci = `rflci'
					return scalar prop_rfuci = `rfuci'
				}
			}
		}		// end if `k'>1
		
		// Proportions: always use z-statistic
		tempname z
		scalar `z' = `eff'/`se_eff'
		scalar `pvalue' = 2*normal(-abs(`z'))		

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
		local tsqlist sa		// [May 2023] for -heterogi- ;  see below
		
		tempname H Isqval HsqM
		if `tsqsa' == -99 {
			scalar `H' = sqrt(100 / (100 - `isqsa'))
			scalar `Isqval' = `isqsa'
			scalar `HsqM' = `isqsa'/(100 - `isqsa')
		}
		else {
			scalar `H' = sqrt((`tsqsa' + `sigmasq') / `sigmasq')
			scalar `Isqval' = 100*`tsqsa'/(`tsqsa' + `sigmasq')
			scalar `HsqM' = `tsqsa'/`sigmasq'
		}
		
		// [Sep 2020] Save values in matrix `hetstats', same as if `isqparam' (see subroutine -heterogi- )
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
		if _rc==1 nois disp as err `"User break in {bf:metan_analysis.Heterogi}"'
		else nois disp as err `"Error in {bf:metan_analysis.Heterogi}"'
		c_local err noerr		// tell -metan- not to also report an "error in metan_analysis.PerformPoolingIV"
		exit _rc
	}
	
	return add
	
	// Return scalars
	return scalar eff = `eff'
	return scalar se_eff = `se_eff'
	return scalar crit = `crit'
	return scalar pvalue = `pvalue'

	if "`kroger'"!="" return scalar df = `df_kr'
	else if "`teststat'"=="t" return scalar df = `Qdf'	

	// return scalar k   = `k'				// k = number of studies (= count if `touse') -- MOVED UPWARDS
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
		CMHNocc noINTeger ISQParam NPTS(varname numeric) WGT(name) WTVAR(varname numeric) OLevel(cilevel) * ]

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
		qui gen double `wtvar' = .
	}
	
	
	** Unpack tempvars for Mantel-Haenszel pooling
	tokenize `mhvlist'
	tempvar Qhet
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
			
			qui gen double `Qhet' = ((`e1' - `afit')^2) * ((1/`afit') + (1/`bfit') + (1/`cfit') + (1/`dfit'))
			summ `Qhet' if `touse', meanonly
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
			drop `Qhet' `afit' `bfit' `cfit' `dfit'
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
	// [June 2022: need to include "petoq" here in case of multiple models
	//   ...otherwise this ifstmt is not run and `Q' is not defined]
	tokenize `qvlist'
	args _ES _seES				// needed for heterogeneity calculations		
	
	// if Cochran's Q, need to calculate I-V effect size
	if "`qstat'"=="cochranq" {
		summ `_ES' [aw=1/`_seES'^2] if `touse', meanonly
		qui gen double `Qhet' = ((`_ES' - r(mean)) / `_seES') ^2
	}		
	else qui gen double `Qhet' = ((`_ES' - `eff') / `_seES') ^2
	summ `Qhet' if `touse', meanonly
	if inlist("`qstat'", "mhq", "cochranq", "petoq") {
		if r(N)>=1 {
			scalar `Q' = r(sum)
			scalar `Qdf' = r(N) - 1
		}
		else {
			scalar `Q' = .
			scalar `Qdf' = .
		}
	}
	// New June 2022: return k and npts to reflect the studies with non-missing _ES and _seES
	// IN ADDITION to the "actual" k and npts from *all* studies in `touse'
	if `"`npts'"'!=`""' {
		summ `npts' if `touse' & !missing(`Qhet'), meanonly
		if r(N) return scalar npts_mh = r(sum)
	}
	return scalar k_mh = r(N)

	
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
		if _rc==1 nois disp as err `"User break in {bf:metan_analysis.Heterogi}"'
		else nois disp as err `"Error in {bf:metan_analysis.Heterogi}"'
		c_local err noerr		// tell -metan- not to also report an "error in metan_analysis.PerformPoolingMH"
		exit _rc
	}
	return add

	// Return other scalars
	qui count if `touse'
	return scalar k   = r(N)	// k = number of studies (= count if `touse')
	return scalar Q   = `Q'		// generic heterogeneity statistic (incl. Peto, M-H, Breslow-Day)
	return scalar Qdf = `Qdf'	// Q degrees of freedom (= `k' - 1)

	if `"`npts'"'!=`""' {
		summ `npts' if `touse', meanonly
		if r(N) return scalar npts = r(sum)
	}	
	
	// Return weights for CumInfLoop
	summ `wtvar' if `touse', meanonly
	local totwt = cond(r(N), r(sum), .)		// sum of (non-normalised) weights
	return scalar totwt = `totwt'

	// check for successful pooling
	if missing(`eff', `se_eff', `totwt') exit 2002
	
end



// Based on heterogi.ado from SSC, with release notes:
// version 2.0 N.Orsini, I. Buchan, 25 Jan 06
// version 1.0 N.Orsini, J.Higgins, M.Bottai, 16 Feb 2005
// (c.f. Higgins & Thompson Stat Med 2002, "Quantifying heterogeneity")

// subroutine called by PerformPoolingIV or PerformPoolingMH

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
			matrix `hetstats'[rownumb(`hetstats', "H"),     1] = sqrt((`tausq' + `sigmasq') / `sigmasq')
			matrix `hetstats'[rownumb(`hetstats', "Isq"),   1] = 100* `tausq' / (`tausq' + `sigmasq')
			matrix `hetstats'[rownumb(`hetstats', "HsqM"),  1] = `tausq' / `sigmasq'
		}
		
		// If `tausq' not defined for this model, store H, Isq and HsqM (& CIs) based on Q instead
		else {
			matrix `hetstats'[rownumb(`hetstats', "H"),    1] = max(1, sqrt(`Q' / `Qdf'))
			matrix `hetstats'[rownumb(`hetstats', "Isq"),  1] = 100* max(0, (`Q' - `Qdf') / `Q')
			matrix `hetstats'[rownumb(`hetstats', "HsqM"), 1] = max(0, (`Q' - `Qdf') / `Qdf')
			
			matrix `hetstats'[rownumb(`hetstats', "H_lci"),    1] = max(1, sqrt(`Q_lci' / `Qdf'))
			matrix `hetstats'[rownumb(`hetstats', "Isq_lci"),  1] = 100* max(0, (`Q_lci' - `Qdf') / `Q_lci')
			matrix `hetstats'[rownumb(`hetstats', "HsqM_lci"), 1] = max(0, (`Q_lci' - `Qdf') / `Qdf')

			matrix `hetstats'[rownumb(`hetstats', "H_uci"),    1] = max(1, sqrt(`Q_uci' / `Qdf'))
			matrix `hetstats'[rownumb(`hetstats', "Isq_uci"),  1] = 100* max(0, (`Q_uci' - `Qdf') / `Q_uci')
			matrix `hetstats'[rownumb(`hetstats', "HsqM_uci"), 1] = max(0, (`Q_uci' - `Qdf') / `Qdf')
		}
		
		// Confidence intervals, if appropriate
		if `"`tsq_lci'"'!=`""' {
			matrix `hetstats'[rownumb(`hetstats', "tsq_lci"),  1] = `tsq_lci'
			matrix `hetstats'[rownumb(`hetstats', "H_lci"),    1] = sqrt((`tsq_lci' + `sigmasq') / `sigmasq')
			matrix `hetstats'[rownumb(`hetstats', "Isq_lci"),  1] = 100* `tsq_lci' / (`tsq_lci' + `sigmasq')
			matrix `hetstats'[rownumb(`hetstats', "HsqM_lci"), 1] = `tsq_lci' / `sigmasq'
			
			matrix `hetstats'[rownumb(`hetstats', "tsq_uci"),  1] = `tsq_uci'
			matrix `hetstats'[rownumb(`hetstats', "H_uci"),    1] = sqrt((`tsq_uci' + `sigmasq') / `sigmasq')
			matrix `hetstats'[rownumb(`hetstats', "Isq_uci"),  1] = 100* `tsq_uci' / (`tsq_uci' + `sigmasq')
			matrix `hetstats'[rownumb(`hetstats', "HsqM_uci"), 1] = `tsq_uci' / `sigmasq'
		}
		
		return matrix hetstats = `hetstats'
	}

end




***********************************************************

* Program to generate confidence intervals for individual studies (NOT pooled estimates)
// subroutine of PerformMetaAnalysis

program define GenConfInts, sortpreserve

	syntax varlist(numeric min=2 max=6 default=none) [if] [in], ///
		CItype(name) OUTVLIST(varlist numeric min=5 max=7) ///
		[ SUMMSTAT(name) noINTeger CUmulative INFluence PRoportion PRVLIST(varlist numeric min=3 max=3) NOPR DF(varname numeric) ILevel(cilevel) * ]

	marksample touse, novarlist
	local invlist `varlist'			// list of "original" vars passed by the user to the program 
	
	// unpack varlists
	tokenize `outvlist'
	args _ES _seES _LCI _UCI _WT _NN _CC
	local params : word count `invlist'
	
	// if no data to process, exit without error
	// return scalar level = `ilevel'
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
		
		tempname alpha z
		scalar `alpha' = .5 + `ilevel'/200
		scalar `z' = invnormal(`alpha')

		// if "`summstat'"!="pr" & "`nopr'"==""
		//    then `prvlist' exists, containing _Prop_ES _Prop_LCI _Prop_UCI
		//    = back-transformed (original) scale
		//    (and _ES, _LCI, _UCI contain values on *transformed* scale)
		
		// else if "`summstat'"!="pr" (i.e. & "`nopr'"!="")
		//    `nopr' suppresses the back-transform
		//    _ES, _LCI, _UCI on transformed scale; no need for `prvlist'
		
		// else (i.e. if "`summstat'"=="pr")
		//    proportions are presented & pooled entirely on their original scale
		//    (i.e. equivalent of "back-transformed", although there was no actual transform in the first place)
		//    use _ES, _LCI, _UCI for this; no need for `prvlist'

		if "`summstat'"!="pr" {
				
			// _ES _LCI _UCI are on transformed (interval) scale
			// so generate CIs using normal distribution
			qui replace `_LCI' = `_ES' - `z' * `_seES' if `touse'
			qui replace `_UCI' = `_ES' + `z' * `_seES' if `touse'
		
			// Now, _Prop_ES _Prop_LCI _Prop_LCI (in `prvlist') contain proportion & CI on "original" (back-transformed) scale
			// March 2021: Don't do this if cumulative/influence, as in this case
			// all observations are mini meta-analyses, so have had _Prop_ES _Prop_LCI _Prop_UCI calculated already via back-transform
			if `"`prvlist'"'!=`""' & `"`cumulative'`influence'"'==`""' {
				tokenize `prvlist'
				args _Prop_ES _Prop_LCI _Prop_UCI
				
				qui replace `_Prop_ES' = `n' / `N' if `touse'
				local newoutvlist `_Prop_ES' `_Prop_LCI' `_Prop_UCI'
			}
		}
		else local newoutvlist `_ES' `_LCI' `_UCI'
		
		if "`newoutvlist'"!="" {	// i.e. all except "`summstat'"!="pr" & !(`"`prvlist'"'!=`""' & `"`cumulative'`influence'"'==`""')
			tokenize `newoutvlist'
			args es lb ub
			
			// if citype=="transform", summstat cannot be "pr" and we must have `prvlist'
			if "`citype'"=="transform" {
				cap {
					assert "`summstat'"!="pr"
					assert "`prvlist'"!=""
				}
				if _rc {
					nois disp as err "option {bf:citype(transform)} is not compatible with some other aspect of the command and/or data"
					exit 198
				}
						
				if "`summstat'"=="logit" {
					qui replace `lb' = invlogit(`_LCI')
					qui replace `ub' = invlogit(`_UCI')
				}
				else if "`summstat'"=="arcsine" {
					qui replace `lb' = sin(`_LCI')^2
					qui replace `ub' = sin(`_UCI')^2
				}
				else if "`summstat'"=="ftukey" {
					qui replace `lb' = 0.5 * (1 - sign(cos(`_LCI')) * sqrt(1 - (sin(`_LCI') + (sin(`_LCI') - 1/sin(`_LCI')) / `N')^2 ) )
					qui replace `ub' = 0.5 * (1 - sign(cos(`_UCI')) * sqrt(1 - (sin(`_UCI') + (sin(`_UCI') - 1/sin(`_UCI')) / `N')^2 ) )
				}
				else {
					nois disp as err "option {bf:citype(transform)} is not compatible with {bf:transform(}`summstat'{bf:)}"
					exit 198
				}
			}
			
			// else, if `prvlist' exists, use it;  if not, assume `outvlist' contains _Prop_ES _Prop_LCI _Prop_UCI
			else {
				cap nois GenConfIntsPr `invlist' if `touse', citype(`citype') outvlist(`newoutvlist') level(`ilevel')
				
				if _rc {
					if _rc==1 nois disp as err `"User break in {bf:metan_analysis.GenConfIntsPr}"'
					else nois disp as err `"Error in {bf:metan_analysis.GenConfIntsPr}"'
					c_local err noerr		// tell -metan- not to also report an "error in metan_analysis.PerformMetaAnalysis"
					exit _rc
				}
			}
		}			// end if "`newoutvlist'"!=""
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
				disp `"{error}Note: Degrees of freedom for {bf:`citype'}-based confidence intervals not supplied; using {it:n-2} as default"'
			}
			else {
				nois disp as err `"Neither degrees-of-freedom nor participant numbers available;"'
				nois disp as err `"  cannot use {bf:`citype'}-based confidence intervals for study estimates"'
				exit 198
			}
		}
		
		tempvar critval
		qui gen double `critval' = invttail(`df', .5 - `ilevel'/200)
		qui replace `_LCI' = `_ES' - `critval'*`_seES' if `touse'
		qui replace `_UCI' = `_ES' + `critval'*`_seES' if `touse'
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

end


* Program to generate confidence intervals for individual studies (NOT pooled estimates)
// SPECIFICALLY FOR PROPORTIONS
// run if either:
//  - nointeger; i.e. some non-integer n, N so that -cii- fails; or
//  - `"`citype'"'==`"transform"', so back-transformed LCI, UCI is required, which cannot be done by -cii-
// subroutine of GenConfInts

program define GenConfIntsPr, rclass
	version 11.0

	syntax varlist(numeric min=2 max=2 default=none) [if] [in], CItype(name) ///
		[ OUTVLIST(varlist numeric min=3 max=3) Level(cilevel) SCALAR ]

	marksample touse, novarlist
	tokenize `varlist'
	args n N
	
	if `"`outvlist'"'!=`""' {	
		tokenize `outvlist'
		args es lb ub
	}
	else {
		tempvar es lb ub
		qui gen `es' =  `n' / `N' if `touse'
		qui gen `lb' = .
		qui gen `ub' = .
	}

	tempname alpha crit
	scalar `alpha' = .5 + `level'/200
	scalar `crit' = invnormal(`alpha')

	if "`citype'"=="exact" {
		qui replace `lb' = cond(float(`n')==0,   0, invbinomialtail(`N', `n', 1-`alpha')) if `touse'
		qui replace `ub' = cond(float(`n')==`N', 1, invbinomial(    `N', `n', 1-`alpha')) if `touse'
	}
	else if "`citype'"=="wald" {
		qui replace `lb' = cond(inlist(float(`es'), 0, 1), `es', `es' - `crit' * sqrt(`es' * (1 - `es') / `N')) if `touse'
		qui replace `ub' = cond(inlist(float(`es'), 0, 1), `es', `es' + `crit' * sqrt(`es' * (1 - `es') / `N')) if `touse'
	}
	else if inlist("`citype'", "wilson", "agresti") {
		tempvar n_tilde N_tilde p_tilde
		qui gen double `n_tilde' = `n' + (`crit'^2) / 2
		qui gen double `N_tilde' = `N' + (`crit'^2)
		qui gen double `p_tilde' = `n_tilde' / `N_tilde'
		
		if "`citype'"=="wilson" {
			qui replace `lb' = cond(float(`n'==0), 0,                   `p_tilde' - (`crit' * sqrt(`N') / `N_tilde') * sqrt(`es'*(1 - `es') + (`crit'^2)/(4*`N') )) if `touse'
			qui replace `ub' = cond(float(`n'==0), min(1, 2*`p_tilde'), `p_tilde' + (`crit' * sqrt(`N') / `N_tilde') * sqrt(`es'*(1 - `es') + (`crit'^2)/(4*`N') )) if `touse'
		} 
		else {		// Agresti-Coull
			qui replace `lb' = max(0, `p_tilde' - `crit' * sqrt(`p_tilde' * (1 - `p_tilde') / `N_tilde')) if `touse'
			qui replace `ub' = min(1, `p_tilde' + `crit' * sqrt(`p_tilde' * (1 - `p_tilde') / `N_tilde')) if `touse'
		}
	}
	else if "`citype'"=="jeffreys" {
		qui replace `lb' = invibeta(`n' + .5, `N' - `n' + .5, 1-`alpha') if `touse'
		qui replace `ub' = invibeta(`n' + .5, `N' - `n' + .5,   `alpha') if `touse'
	}
	else {
		nois disp as err "invalid {bf:citype()}"
		exit 198
	}
	
	// Return mean values -- but note these are meaningless unless there is only a single observation in the sample
	// This is for use if called from within PerformPoolingIV in the special case of pooling where there is only one valid study
	summ `es' if `touse', meanonly
	if r(N)==1 {
		return scalar es = r(mean)
		summ `lb' if `touse', meanonly
		return scalar lb = r(mean)
		summ `ub' if `touse', meanonly
		return scalar ub = r(mean)
	}
	
end

