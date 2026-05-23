*! version 1.0.0 22may2026

prog define upset_plot, rclass
	
	version 18.5
	
	return clear
	
	syntax varlist(numeric) [if] [in] [fweight], 							///
		[																	///
			over(string asis)												///
			sort(string) 													///
			INTopts(string asis)											///
			SETopts(string asis)											///
			GRIDopts(string asis)											///
			bar(passthru)													///
			addplot(string asis)											///
			noTABle															///
			KEEPfirst(passthru)												///
			FILLin 															///
			by(string asis)													/// Capture illegal command (not documented)
			recast(string asis)												/// Capture illegal command (not documented)
			*																///
		]
	
	/**************************************************************************/
	/*** Data filter and initial parsing **************************************/
	/**************************************************************************/
	
	local nvars : word count `varlist'
	
	/// Capture illegal commands
	
	while (`"`by'"' != "") {
		
		local by
		local recast
		local 0, `options'
		syntax, [ by(string asis) recast(string asis) * ]
		
	}
	
	preserve
	
	marksample touse
	
	qui keep if `touse'
	
	mata: upsetvalid("`varlist'")
	
	if (`"`over'"' != "") {
		
		_upsetoverparse `over'
		
		local nover    = s(nover)
		local overvar  = s(overvar)
		local overvals = s(overvals)
		local overlabs = s(overlabs)
		
		local s_overvals : list sort overvals
		
		local checkover : subinstr local s_overvals " " " \`_s'freq", all
		local checkover \`_s'freq`checkover'
		
		local byover by `overvar' :
		
	}
	
	else local nover = 1
		
	// Ensure new variable names do not already exist
	
	local n_ = 0
	
	while (1) {
		
		local _s = `n_' * "_"
		local checkvars `_s'binary `_s'decimal `_s'freq `checkover'
				
		cap confirm new v `checkvars'
		
		if _rc local ++n_
		else continue, break
		
	}
	
	local binary `_s'binary
	local decimal `_s'decimal
	local frequency `_s'freq
	
	/**************************************************************************/
	/*** Intersection and set frequencies *************************************/
	/**************************************************************************/
	
	/*** Intersection frequencies *********************************************/
	
	contract `overvar' `varlist' [`weight' `exp'], f(`frequency') z
	
	qui gen `decimal' = `: word `nvars' of `varlist''
	
	qui forvalues i = 1 / `=`nvars' - 1' {
		
		local j = `nvars' - `i'
		local varj : word `j' of `varlist'
		replace `decimal' = `decimal' + (`varj' * 2 ^ `i')
		
	}
	
	tempname intmat
	mkmat *, mat(`intmat') obs
	
	qui egen `binary' = concat(`varlist')
		
	if ("`table'" == "") {
		
		di ""
		di as txt "{bf:Intersection frequencies}"
		
		sort `overvar' `decimal'
		order `overvar' `varlist' `binary' `decimal' `frequency'
		list `overvar' `varlist' `binary' `decimal' `frequency'
		
	}
	
	tempfile datafmt
	qui save `datafmt'
	
	/*** Set frequencies ******************************************************/
	
	tempname setmat tsetmat
	
	collapse (sum) `varlist' [fweight=`frequency'], by(`overvar')
	
	if ("`table'" == "") {
		
		di ""
		di as txt "{bf:Set frequencies}"
		
		list
		
	}
	
	local setmax = 0
	foreach i of local varlist {
		qui sum `i', meanonly
		if r(sum) > `setmax' local setmax = r(sum)
	}
	
	mkmat `varlist', mat(`setmat') rownames(`overvar')
	mat `tsetmat' = `setmat''
	
	if (`nover' == 1) {
		tempvar setn
		local setns `setn'
	}
	
	else forvalues i = 1 / `nover' {
		
		local s_ival : word `i' of `s_overvals'
		
		tempvar setn`s_ival'
		local setns `setns' `setn`s_ival''
		
	}
	
	mat colnames `tsetmat' = `setns'
	
	/**************************************************************************/
	/*** Data manipulation ****************************************************/
	/**************************************************************************/
	
	/*** Convert to wide (if necessary) ***************************************/
	
	use `datafmt', clear
	
	if (`nover' > 1) {
		
		qui cap reshape wide `frequency', i(`varlist') j(`overvar')
		
		if _rc {
						
			qui ds
			local dsvars `r(varlist)'
			
			local freqvars : subinstr local overvals " " " `frequency'", all
			local freqvars `frequency'`freqvars'
			
			local cfvars : list dsvars & freqvars
			
			di as err "variables {bf:`cfvars'} already defined"
			exit 198
			
		}
		
		qui egen `frequency' = rowtotal(`frequency'*)
		
		local legsyn legend(order(`overlabs'))
		
	}
	
	else local legsyn legend(off)
	
	qui sum `frequency', meanonly
	local intmax = r(max)
	local tweight = r(sum)
	
	/*** Drop and sort ********************************************************/
	
	tempvar sortorder
	
	if !strpos(`"`sort'"', ",") local sortcomma ,
	
	_upsetsortparse `sort' `sortcomma' dvar(`decimal') 			 			///
									   bvar(`binary') 						///
									   freq(`frequency')					///
									   newvar(`sortorder')					///
									   `keepfirst' `fillin'
	
	svmat `tsetmat', names(col)
	
	/**************************************************************************/
	/*** Bar chart specification **********************************************/
	/**************************************************************************/
	
	/*** Class setup **********************************************************/
	
	.int = .upsetclass.new
	.set = .upsetclass.new
	
	.int.over `nover', `bar' `options'
	
	.int.set 1 `=_N' `intmax', `intopts'
	.set.set 0 `nvars' `setmax', `setopts'
	
	/*** Rescaling ************************************************************/
	
	tempvar intpos setpos
	qui gen `intpos' =   (3 * `sortorder' - 1) / (3 * _N + 1)
	qui gen `setpos' = - (3 * _n - 1) / (3 * `nvars' + 1) if _n <= `nvars'
	
	tempvar sc_intcum0 sc_setcum0
	qui gen `sc_intcum0' =	 `.int.axisgap'
	qui gen `sc_setcum0' = - `.set.axisgap' if _n <= `nvars'
	
	forvalues i = 1 / `nover' {
				
		local imin = `i' - 1
		local ival : word `i' of `overvals'
		local ipos : list posof "`ival'" in s_overvals
		
		local intcums `intcums' `frequency'`ival'
		local setcums `setcums' `setn`ival''
		
		tempvar intcum`i' setcum`i' sc_intcum`i' sc_setcum`i'
		
		egen `intcum`i'' = rowtotal(`intcums')
		egen `setcum`i'' = rowtotal(`setcums')
		
		qui gen `sc_intcum`i'' =   `.int.axisgap' + `intcum`i'' *			///
									   `.int.axissize' / `.int.axismax'
		
		qui gen `sc_setcum`i'' = - `.set.axisgap' - `setcum`i'' *			///
									   `.set.axissize' / `.set.axismax'
		
		local intbarsyn `intbarsyn' (rbar `sc_intcum`imin'' 				///
										  `sc_intcum`i'' 					///
										  `intpos', 						///
										  `.int.baropts[`i']' 				///
										  barw(`.int.bwidth'))
		
		local setbarsyn `setbarsyn' (rbar `sc_setcum`imin'' 				///
										  `sc_setcum`i'' 					///
										  `setpos', 						///
										  `.set.baropts[`i']'				///
										  barw(`.set.bwidth') hor)
		
		local isc `isc' (scatteri . ., `.int.baropts[`ipos']' recast(bar)) ||
		
	}
	
	if (`nover' == 1) local iscsyn 
	
	if !(`.int.onoff') local intbarsyn
	if !(`.set.onoff') local setbarsyn
		
	/*** Labelling ************************************************************/
	
	local verts int set
	
	qui foreach vert of local verts {
		
		if !(`.`vert'.onoff') continue
				
		else if ("`vert'" == "int") {
			local plotorder "\`intlabpos\`i'' `intpos'"
			local vm ""
		}
		
		else {
			local plotorder "`setpos' \`setlabpos\`i''"
			local vm "-"
		}
		
		if (`.`vert'.blabstyle' == 3) {
			
			local i 1
			tempvar `vert'labpos1
			
			if (`.`vert'.blabperc') {
				tempvar percfmt
				gen `percfmt' = string(100 * ``vert'cum`nover'' / `tweight', "`.`vert'.blabfmt'") + "%"
				local labpointer `percfmt'
			}
			
			else local labpointer ``vert'cum`nover''
			
			if (`.`vert'.blabpos' == 1) gen ``vert'labpos1' = `vm' `.`vert'.axisgap'
			else if (`.`vert'.blabpos' == 3) gen ``vert'labpos1' = `sc_`vert'cum`nover''
			else gen ``vert'labpos1' = `vm' (`.`vert'.axisgap' + `sc_`vert'cum`nover'') / 2
			
			local blabplot `blabplot' (scatter `plotorder', 				///
									   mlab(`labpointer') 					///
									   mlabf(`.`vert'.blabfmt') 			///
									   `.`vert'.blabopts')
			
		}
		
		else if inlist(`.`vert'.blabstyle', 1, 2) {
			
			local labval = cond(`.`vert'.blabstyle' == 2, 					///
								"\``vert'cum\`i''",							///
								cond("`vert'" == "int", 					///
									 "`frequency'\`ival'", 					///
									 "\`setn\`ival''"))
						
			forvalues i = 1 / `nover' {
				
				local imin = `i' - 1
				local ival : word `i' of `overvals'
				
				tempvar `vert'labpos`i'
				
				if (`.`vert'.blabperc') {
					tempvar percfmt`i'
					gen `percfmt`i'' = string(100 * `labval' / `tweight', "`.`vert'.blabfmt'") + "%"
					local labpointer `percfmt`i''
				}
				
				else local labpointer `labval'
				
				if (`.`vert'.blabpos' == 1) local `vert'labpos`i' `sc_`vert'cum`imin''
				else if (`.`vert'.blabpos' == 3) local `vert'labpos`i' `sc_`vert'cum`i''
				else gen ``vert'labpos`i'' = (`sc_`vert'cum`imin'' + `sc_`vert'cum`i'') / 2
				
				local blabplot `blabplot' (scatter `plotorder', 			///
										   mlab(`labpointer') 				///
										   mlabf(`.`vert'.blabfmt') 		///
										   `.`vert'.blabopts')
				
			}
			
		}
		
	}
	
	/**************************************************************************/
	/*** Grid setup ***********************************************************/
	/**************************************************************************/
	
	_upsetgridparse `nvars' `nover', `gridopts'
	
	local oncols   = s(oncols)
	local offcols  = s(offcols)
	local lopts    = s(lineopts)
	local labopts  = s(labopts)
	local mopts `"`s(gridopts)'"'
	
	tempvar varlabs
	qui gen `varlabs' = ""
		
	qui forvalues i = 1 / `nvars' {
		
		local ivar : word `i' of `varlist'
		local ival = - (3 * `i' - 1) / (3 * `nvars' + 1)
		local ilab : variable label `ivar'
		
		replace `varlabs' = `"`ilab'"' in `i'
		
		tempvar dots`i' nodots`i'
		gen `dots`i'' = `ival' if `ivar' == 1
		gen `nodots`i'' = `ival' if `ivar' == 0
		
		local onsyn "`onsyn' `dots`i''"
		local offsyn "`offsyn' `nodots`i''"
		
	}
	
	tempvar labpos
	qui gen `labpos' = 0 if _n <= `nvars'
	
	tempvar dotmin dotmax
	qui egen `dotmin' = rowmin(`onsyn')
	qui egen `dotmax' = rowmax(`onsyn')
	
	/**************************************************************************/
	/*** Twoway call **********************************************************/
	/**************************************************************************/
	
	twoway 																	///
			`isc'															///
			(scatter `offsyn' `intpos', `offcols' `mopts')					///
			(rspike `dotmax' `dotmin' `intpos', `lopts') 					///
			(scatter `onsyn' `intpos', `oncols' `mopts') 					///
			(scatter `setpos' `labpos', mlab(`varlabs') msize(0) 			///
										mcol(none) `labopts') 				///
			`.int.gridsyn' 													///
			`.set.gridsyn' 													///
			`intbarsyn' 													///
			`setbarsyn' 													///
			`.int.plotsyn' 													///
			`.set.plotsyn' 													///
			`blabplot'														///
			`addplot'														///
			,																///
			xsc(off range(-`.set.ymax' 1)) xlab(minmax, nogrid) 			///
			ysc(off range(-1 `.int.ymax')) ylab(minmax, nogrid) 			///
			`.int.optsyn' 													///
			`.set.optsyn' 													///
			`legsyn'		 												///
			`.int.useropts'
	
	/**************************************************************************/
	/*** Return ***************************************************************/
	/**************************************************************************/
	
	return scalar n_var = `nvars'
	return scalar n_over = `nover'
	return scalar N = `tweight'
	
	return local overvar `overvar'
	return local varlist `varlist'
	return local cmdline `0'
	return local cmd upset_plot
	
	return mat setmatrix = `setmat'
	return mat intmatrix = `intmat'
	
end

prog define _upsetoverparse, sclass
	
	sreturn clear
		
	syntax varname(numeric), 												///
		[																	///
			RElabel(string asis)											///
			SORTby(string)													///
			DEScending														///
		]
		
	cap assert !missing(`overvar'), fast
	if _rc {
		di as err "missing values found in {bf:`overvar'}"
		exit 198
	}
	
	qui levelsof `varlist', local(overvals)
	local nover = r(r)
	
	if ("`sortby'" != "") local valid_sort : list sortby & overvals
	local overvals : list valid_sort | overvals
	
	if (`"`relabel'"' != "") {
		
		_upsetruleparse `relabel', labvar(`varlist') admit(`overvals') int
		local overvals = s(ticks)
		local userflags = s(userlabs)
		local userlabs = s(labs)
		
		forvalues i = 1 / `nover' {
			
			local levi  : word `i' of `overvals'
			local useri : word `i' of `userflags'
			local labi  : word `i' of `userlabs'
			
			if (`useri' == 1) local reloverlabs `"`reloverlabs' `i' `"`labi'"'"'
			else local reloverlabs `"`reloverlabs' `i' `"`: label (`varlist') `levi''"'"'
			
		}
		
		local overlabs `reloverlabs'
		
	}
	
	else forvalues i = 1 / `nover' {
		local levi  : word `i' of `overvals'
		local overlabs `"`overlabs' `i' `"`: label (`varlist') `levi''"'"'
	}
	
	if ("`descending'" != "") {
		forvalues i = `nover'(-1)1 {
			local revovervals `revovervals' `: word `i' of `overvals''
		}
		local overvals `revovervals'
	}
	
	sreturn local nover  = `nover'
	sreturn local overvar  `varlist'
	sreturn local overvals `overvals'
	sreturn local overlabs `overlabs'
	
end

prog _upsetgridparse, sclass
	
	sreturn clear
	
	syntax anything, 														///
		[																	///
			ONCOLor(string)													///
			OFFCOLor(string)												///
			MColor(string)													///
			LColor(string)													///
			MLABColor(string)												///
			Msymbol(passthru)												///
			MSIZe(passthru)													///
			MSAngle(passthru)												///
			MFColor(passthru)												///
			MLColor(passthru)												///
			MLWidth(passthru)												///
			MLAlign(passthru)												///
			MLSTYle(passthru)												///
			MSTYle(passthru)												///
			MLABGap(passthru)												///
			MLABSTYle(passthru)												///
			MLABANGle(passthru)												///
			MLABTextstyle(passthru)											///
			MLABSize(passthru)												///
			MLABFormat(passthru)											///
			LPattern(passthru)												///
			LWidth(passthru)												///
			LAlign(passthru)												///
			LSTYle(passthru)												///
		]
	
	tokenize `anything'
	local nvar = `1'
	local nover = `2'
	
	if ("`oncolor'" == "") & ("`mcolor'" != "") local oncolor `mcolor'
	
	local n_on : word count `oncolor'
	local n_off : word count `offcolor'
	
	local diff_on = `nvar' - `n_on'
	local diff_off = `nvar' - `n_off'
	
	if (`n_on' < `nvar') forvalues i = 1 / `diff_on' {
		local j = `nover' + `i'
		local oncolor `oncolor' stc`j'
	}
	
	if (`n_off' < `nvar') {
		local addoff = `diff_off' * "gs12 "
		local offcolor "`offcolor' `addoff'"
	}
	
	if ("`lcolor'" == "") local lcolor black
	if ("`mlabcolor'" == "") local mlabcolor black
	
	sreturn local oncols 	mc(`oncolor')
	sreturn local offcols 	mc(`offcolor')
	sreturn local lineopts	lc(`lcolor') `lpattern' `lwidth' `lalign' 		///
							`lstyle'
	
	sreturn local gridopts	`msymbol' `msize' `msangle' `mfcolor' `mlcolor'	///
							`mlwidth' `mlalign' `mlstyle' `mstyle'
	
	sreturn local labopts	mlabc(`mlabcolor') mlabp(9) 					///
							`mlabgap' `mlabstyle' `mlabangle' 				///
							`mlabtextstyle' `mlabsize' `mlabformat'
	
end

prog _upsetsortparse, sclass
	
	sreturn clear
		
	syntax [anything], 														///
		dvar(varname numeric)												///
		bvar(varname string)												///
		FREQuency(varname numeric)											///
		NEWVARiable(string)													///
		[																	///
			intwo															///
			inten															///
			KEEPfirst(numlist max=1 int >0)									///
			FILLin 															///
		]
	
	/*** Error checking *******************************************************/
	
	if ("`inten'" != "") & ("`intwo'" != "") {
		di as err "only one of {bf:inten} and {bf:intwo} may be specified"
		exit 198
	}
	
	/*** Deal with given binary/decimal values ********************************/
	
	tempvar intsort nflags
	qui gen `intsort' = .
	
	local cexp = cond("`inten'" == "", `"strpos("\`lhs'", `bvar')"', "\`lhs' == `dvar'")
	
	gettoken lhs rhs: anything
	
	cap confirm integer n `lhs'
	
	qui while (!_rc) {
		
		sum `intsort', meanonly
		local currmax = max(0, r(max))
		
		tempvar tempsort
		gen `tempsort' = `cexp'
		recode `tempsort' (0 = .)
		
		replace `intsort' = `currmax' + `tempsort' if missing(`intsort')
		
		gettoken lhs rhs: rhs
		cap confirm integer n `lhs'
		
	}
	
	/*** Non-integer **********************************************************/
	
	local nvars = length(`bvar') in 1
	
	gen `nflags' = `nvars' - length(subinstr(`bvar', "1", "", .))
	
	foreach i in `lhs' `rhs' {
		
		if inlist(`"`i'"', "-", "+") local strsort `strsort' `i'
		
		else if regexm(`"`i'"', "^([-+])?([a-z]+)$") {
			
			local dir = regexs(1)
			local cont = regexs(2)
			
			if strpos(".frequency", `".`cont'"') local strsort `strsort' `dir' `frequency'
			
			else if strpos(".bitsum", `".`cont'"') local strsort `strsort' `dir' `nflags'
			
			else if strpos(".pattern", `".`cont'"') local strsort `strsort' `dir' `bvar'
			
			else if strpos(".random", `".`cont'"') {
				tempvar rand
				gen `rand' = runiform()
				local strsort `strsort' `rand'
			}
			
			else {
				di as err `"unrecognised sort rule {bf:`i'}"'
				exit 198
			}
			
		}
		
		else {
			di as err `"unrecognised sort rule {bf:`i'}"'
			exit 198
		}
		
	}
	
	/*** Final sort ***********************************************************/
	
	gsort `intsort' `strsort' -`frequency' `dvar'
	
	qui if ("`fillin'" == "") drop if `frequency' == 0
	qui if ("`keepfirst'" != "") keep if _n <= `keepfirst'
	
	gen `newvariable' = _n
	
end

mata

mata clear

void upsetvalid(string scalar vars) {
	
	real matrix varmat
	
	st_view(varmat, ., (vars))
	
	if (!all(varmat :== 0 :| varmat :== 1)) {
		
		errprintf("invalid values found in %s: only 1s and 0s permitted\n", vars)
		exit(450)
		
	}
	
}

end
