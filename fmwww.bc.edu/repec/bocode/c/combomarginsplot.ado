*! combomarginsplot.ado - Nicholas Winter
*! version 1.5.1 25feb2021
*! based on marginsplot version 1.2.4  21oct2019 (Stata 16 version)

* Changes
* 1.5.1: added compound quotes to allow quotes within labels
* 1.4.0: can chain output into new cmp call.
* 1.2.0: draws official marginsplot version 1.2.1 11jul2019 (Stata 16 version)
*        brought cmp_marginsplot16 into this adofile
*        added functionality of -mplotoffset-
* 0.1.3: downgraded to require Stata 12 r/t 13
* 0.1.5: added -restore- to allow addplot() option to work
* 0.1.6: added mlabfmt() option 


program combomarginsplot
	version 16
	
	#delimit ;
	syntax anything(name=flist id="List of saved margins files") 
			, [ 
				Labels(string asis) 
				SAVEfile(string) 			// the combined margins file
				FILEVarname(string)
				mpsaving(passthru)			// [undocumented] the margins file as modified by -cmp_marginsplot16- 
				debug						// [undocumented]
				level(string)				// catch here -- needs to be specified in margins..., saving call
				mlabfmt(string)				// format for estimates variable (useful when labelling in plot)
				alpha						// alpha-release test feature to add file var to atlist
				* 
			]
		;
	#delimit cr
	
	if !mi("`level'") {
		di as error "Must specify level() option when creating margins files"
		exit 198
	}
	
	if !mi("`debug'") 	local debug 
	else 			local debug *
	
	if mi("`filevarname'") local filevarname _filenumber

	confirm name `filevarname'
	foreach file of local flist {
		capture describe `filevarname' using "`file'"
		if !_rc {
			di as error "variable `filevarname' exists in file `file'; specify different variable name with filevarname() option"
			exit 111
		}
	}
	
	preserve
	clear


	/************************************************************
	*	Cycle through files to coordinate _at, _m, _by variables & save as tempfiles
	*	This accomplishes two things:
	*	
	*		(1) any _at, _m, and _by variables that don't exist in a file are created and set to .o (asobserved)
	*		(2) mappings between _at/_m/_by and real underlying varnames are made consistent across files
	*		(3) char _dta[_atopt#] are coordinated with new mapping
	*		(4) _atopt and _term variables are coordinated across datasets
	*	
	*		Locals used:
	*	
	*		oldnames			file's existing _`type'# variables  (e.g., _at1 _at2 ...)
	*		f_`type'_vars		file's existing varnames associated with _`type'# (e.g., mpg price ...)
	*
	*		newnames			new _`type'# that match across files (e.g., _at2 _at1 ...)
	*		m_`type'_vars		varnames associated with newnames (e.g., price mpg ...)
	*	
	************************************************************/
	
	local typelist at m by		// _at# _m# _by#

	local filenum 0
	foreach file of local flist {
		local ++filenum

		qui use "`file'"
		`debug' di "{txt}Using {res}`file'"
		`debug' di "{txt}***************************************"

		// grab margins-file label from char _dta[cmp_label]
		local cmp_labels `"`cmp_labels' "`:char _dta[cmp_label]'" "'


		foreach type in `typelist' {		

			`debug' di "{txt}type: {res}`type'"
			local oldnames									// file's existing _`type'# variables
			local newnames									// list of corresponding new _`type'# variables from combined, consistent list

			// get list of this file's `type' variables
			if "`type'"=="m" 	local ttype margin				// named inconsistently
			else 				local ttype `type'
			local f_`type'_vars : char _dta[`ttype'_vars]
			
			`debug' di "f_`type'_vars [`f_`type'_vars']"
			/*
				f_`type'_vars			-- original list of vars 
				m_`type'_vars			-- reordered/expanded list of vars ... this is accumulated across all files
			*/

			local i 0
			foreach var of local f_`type'_vars {					
				local ++i										// i indexes position in current file varlist, i.e. old position
				local newpos : list posof "`var'" in m_`type'_vars	// have we already mapped this varname?
				if `newpos'==0 {								// haven't seen it before
					local m_`type'_vars `m_`type'_vars' `var'		// add this variable to master list
					local newpos : list sizeof m_`type'_vars		// update newpos
				}
				`debug' di "   {txt}var:[{res}`var'{txt}] newpos:[{res}`newpos'{txt}] m_`type'_vars:[{res}`m_`type'_vars'{txt}]" 

				// add old and new varnames to respective lists
				local oldnames `oldnames' _`type'`i'
				local newnames `newnames' _`type'`newpos'
			}

			// deal with atstats#
			if "`type'"=="at" {
				`debug' di `"-----> m_at_vars [`m_at_vars']"'
				// cycle through each set of atstats#
				forval j=1/`: char _dta[k_at]' {
					local statlist
					foreach atvar of local m_at_vars {					// this is the full list of at vars, whether or not they appear in this file
						local oldpos : list posof "`atvar'" in f_at_vars	// position of this one in THIS FILE's original ordering
						if `oldpos'==0 {
							local stat asobserved					// this one wasn't here; go with asobserved
						}
						else {
							local stat `: word `oldpos' of `: char _dta[atstats`j']''
						}
						local statlist `statlist' `stat'
					}

					`debug' di " ATSTATS`j':"
					`debug' di "   varlist (old): `f_at_vars'"
					`debug' di "   varlist (new): `m_at_vars'"
					`debug' di ""
					`debug' di "   stats (old)  : `: char _dta[atstats`j']'"
					`debug' di "   stats (new)  : `statlist'"

					`debug' di 
					`debug' di "   SET: atstats_`filenum'_`j' [`statlist']"

					char _dta[atstats`j'] `statlist'
					local atstats_`filenum'_`j' `statlist'

				}
			}
					

			// rename variables to updated names
			if !mi("`oldnames'`newnames'") {							// if there are any variables to process
				local rcmd rename (`oldnames') (`newnames')
				`debug' di `"{txt}`rcmd'"'		
				qui `rcmd'										// note that rename moves the characteristics ... nice
			}

			`debug' di "       m_`type'_vars: [`m_`type'_vars']"

		}

		* deal with _term and _atopt variables
		* list of labels accumulated in m_`type'_labels
		* creates:		newtermlab`type' -- the value labels for the combined file
		*				recodestring`type' -- the recode string for this file to renumber the values into consistent coding across files
		foreach type in _term _atopt {
			local recodestring`type'				// will contain recoding from this file's `type' list to master `type' list
			`debug' di "getting `type' label"

			// if _atopt is missing, then label won't exist
			capture label list `type'
			if !_rc {
				local lmin = r(min)
				local lmax = r(max)

				// make master list of all values of _term/_atopt
				forval ll = `lmin'/`lmax' {
					local curlabel `: label (`type') `ll''
					local newpos : list posof "`curlabel'" in m`type'_labels			// have we seen this label before?

					if `newpos'==0 {											// haven't seen it before
						local m`type'_labels `"`m`type'_labels' "`curlabel'""'			// append this label
						local newpos : list sizeof m`type'_labels					// update newpos
						local newtermlab`type' `newtermlab`type'' `newpos' "`curlabel'"	// add new label to label string (accumulated across all files)
					}

					`debug' di `"{txt}term:[{res}`curlabel'{txt}] newpos:[{res}`newpos'{txt}] m`type'_labels:[{res}`m`type'_labels'{txt}]"'

					local recodestring`type' `recodestring`type'' (`ll'=`newpos')		// add old and new levels to recode string (for this file only)

				}
				`debug' di `"m`type'_labels: [`m`type'_labels']"'
				`debug' di `"recodestring:  [`recodestring`type'']"'
				`debug' di `"newtermlab:    [`newtermlab`type'']"'

				`debug' di `"===> [recode `type' `recodestring`type'']"'				// recode `type' to new values
				qui recode `type' `recodestring`type''								// recode `type' to new values
				la drop `type'													// drop now-incorrect label string 
																			// new value labels get applied after files are appended
			}
		}
		
		// predict_label, margin_label, title
		if `filenum'==1 {
			local predict_label 	: char _dta[predict_label]
			local expression_label 	: char _dta[expression]
			local margin_label  	: variable label _margin
			local title_label   	: char _dta[title]
		}
		else {
			local predict_label = 		cond(`"`predict_label'"'   ==`"`: char _dta[predict_label]'"',`"`predict_label'"'   ,"Predictions")
			local expression_label = 	cond(`"`expression_label'"'==`"`: char _dta[expression]'"'   ,`"`expression_label'"',"Predictions")
			local margin_label  = 		cond(`"`margin_label'"'    ==`"`: variable label _margin'"'  ,`"`margin_label'"'    ,"Prediction")
			local title_label   = 		cond(`"`title_label'"'     ==`"`: char _dta[title]'"'        ,`"`title_label'"'     ,"Combined margins results")

			// if one file has prediction and another has expression, reset both to generic
			if !mi(`"`predict_label'"') & !mi(`"`expression_label'"') {
				local predict_label		Predictions
				local expression_label	Predictions
			}

		}		
						

		// save modified file
		tempfile workingfile
		qui save `workingfile', replace
		local workingflist `workingflist' `workingfile'
	}

	// redundant
	local nfiles : word count `workingflist'
************
* Reconcile atstats# across files
* Inconsistencies should be OK except that 'values' should override
************
	forval i=`nfiles'(-1)1 {											// last file will be comprehensive, so start there
		local j 1
		while !mi(`"`atstats_`i'_`j''"') {								// file _ #
			local nstats : word count `atstats_`i'_`j''
			
			forval k = 1/`=`i'-1' {									// check against all prior files
				forval word = 1/`nstats' {
					local curstat : word `word' of `atstats_`i'_`j''
					local othstat : word `word' of `atstats_`k'_`j''		// same position, same atstat#, different file
					
					if ("`curstat'"!="`othstat'") & "`othstat'"!="" {
						// curstat is the one from the higher file, so it should override if it is 'values'
						local varname : word `word' of `m_at_vars'
						di "{txt}Warning: statistics differ for {res}`varname'{txt}: file {res}`k'{txt}={res}`othstat'{txt}, file {res}`i'{txt}={res}`curstat'{txt};  " _c
						if "`curstat'"=="values" {
							local thefile : word `k' of `workingflist'
							qui use `thefile'
							local oldchar : char _dta[atstats`j']
							forval z = 1/`=`word'-1' {
								local newchar `newchar' `: word `z' of `oldchar''
							}
							local newchar `newchar' values
							forval z = `=`word'+1'/`: word count `oldchar'' {
								local newchar `newchar' `: word `z' of `oldchar''
							}
							char _dta[atstats`j'] `newchar'
							qui save, replace
							local newchar
							di "using {res}values{txt}"
						}
						else {
							di "using first ({res}`othstat'{txt})"
						}
					}
					else {
						`debug' di "   match stats: file `i' stat `word' [`curstat'] " _col(50) "VS. file `k' stat `word' [`othstat']"
					}

				}
			}
			local ++j
		}
	}
	
			
*******************************************
* append modified datasets together
*******************************************
	drop _all
	*clear

	if `"`labels'"'=="" & `"`cmp_labels'"'!="" {
		local labels `"`cmp_labels'"'
	}

	forval i=1/`nfiles' {
		`debug' di "file `i'"
		local lab  : word `i' of `labels'							// user-specified labels for files
		local file : word `i' of `workingflist'
		qui {
			append using `file'

			if `i'==1 {
				local num = `: word count `m_m_vars'' + 1
				gen _m`num' = `i' 
				local m_m_vars `m_m_vars' `filevarname'				// append to m varlist
				if "`alpha'"!="" {
					local m_at_vars `m_at_vars' `filevarname'			// aapend to at varlist *** WHY ***????????
				}
				
				// Grab list of u_at_vars
				// & construct list of _u_at_vars from positions in m_at_vars
				local master_u_at_vars : char _dta[u_at_vars]				// real varnames
				foreach var of local master_u_at_vars {
					local newpos : list posof "`var'" in m_at_vars
					if `newpos'==0 {
						di as error "`var' in u_at_vars doesn't appear in m_at_vars??"
						exit 198
					}
					local master__u_at_vars `master__u_at_vars' _at`newpos'
				}
				//char _dta[_u_at_vars] `master__u_at_vars'
				// blank out so we get next files' when appended
				char _dta[_u_at_vars] 
				char _dta[u_at_vars] 

				`debug' noi di "end of file 1 syntax"

			}
			else {
				replace _m`num' = `i' if mi(_m`num')
				
				// Deal with u_at_vars
				local local_u_at_vars : char _dta[u_at_vars]				// real varnames
				
				local diff : list this_u_at_vars - master_u_at_vars
				if !mi("`diff'") {
					di as error "File `i' has u_at_vars that don't appear in file 1"
					exit 198
				}
				
				local local__u_at_vars
				foreach var of local local_u_at_vars {
					local newpos : list posof "`var'" in m_at_vars
					if `newpos'==0 {
						di as error "`var' in u_at_vars doesn't appear in m_at_vars??"
						exit 198
					}
					local local__u_at_vars `local__u_at_vars' _at`newpos'
				}
				if "`local__u_at_vars'" != "`master__u_at_vars'" {
					noi: di "local: `local__u_at_vars' master: `master__u_at_vars'"
					di as error "file `i' _u_at_vars don't match file 1"
					di "local: `local__u_at_vars' `master__u_at_vars'"
					exit 198
				}
				//char _dta[_u_at_vars] `local__u_at_vars'
				`debug' noi di "end of file `i' syntax"

			}
			
			if !mi(`"`labels'"') 	label define _m`num' `i' `"`lab'"', add
			else					label define _m`num' `i' `"File `i'"', add
		}
	}

	label values _m`num' _m`num'
	label variable _m`num' "File Number"
	char _m`num'[varname] `filevarname'
	char _dta[u_at_vars] `master_u_at_vars'
	char _dta[_u_at_vars] `master__u_at_vars'

	**********************
	* FIX UP CHARACTERISTICS, LABELS, ETC
	*******************
	// label _term & _atopt variables
	foreach type in _term _atopt {
		if !mi(`"`newtermlab`type''"') {
			label define `type' `newtermlab`type''
			label values `type' `type'
		}
	}

	// reconstitute characteristics atopt#
	tokenize `"`newtermlab_atopt'"'
	while !mi("`1'") {
		local num `1'
		local lab `2'
		confirm integer number `1'
		char _dta[atopt`1'] "`2'"
		mac shift
		mac shift
	}


	// set _dta characteristics & labels, titles
	foreach type in `typelist' {		// at m by
		`debug' di `"setting: char _dta[`type'_vars] "`m_`type'_vars'""'
		char _dta[`type'_vars] "`m_`type'_vars'"
	}
	// named inconsistently
	char _dta[margin_vars] "`m_m_vars'"


	char _dta[predict_label] `"`predict_label'"'
	char _dta[expression]    `"`expression_label'"'
	char _dta[title]         `"`title_label'"'

	label variable _margin `"`margin_label'"'

	// create _at variable (OLDATNUM allows combined marginsplot files to be recombined)
	local OLDATNUM 0
	capture confirm variable _oldat`OLDATNUM'
	while !_rc {
		local OLDATNUM = `OLDATNUM'+1
		capture confirm variable _oldat`OLDATNUM'
	}
	rename _at _oldat`OLDATNUM'
	foreach var of varlist _at* {
		qui replace `var' = .o if `var'==.
	}
	egen _at = group(_at*), missing		// _at* includes _atopt as well as all _at? variables
	la var _at `"`: variable label _oldat`OLDATNUM''"'

	//hold options
	local mpopts `options'

	// format _margin variable
	if `"`mlabfmt'"'!="" {
		format _margin `mlabfmt'
	}
	else {
		format _margin %4.1f
	}


	// parse savefile -- the combine margins file
	local 0 `"`savefile'"'
	syntax [ anything(name=savefile id="File name") ] , [ replace cmplabel(string) ]
	if mi("`savefile'") {
		local qui qui
		tempfile savefile
	}
	else {
		local qui
		di "{txt}Saving combined margins file `savefile'"
	}
	char _dta[cmp_label] `"`cmplabel'"'
	`qui' save "`savefile'" , `replace'

	//RUN -marginsplot-
	restore
	local cmd cmp_marginsplot16 using "`savefile'" , filevarname(`filevarname') `mpopts' `mpsaving' 
	`debug' di `"[`cmd']"'

	`cmd'

end



* NJGW - this is modified version of marginsplot 
* version 1.2.1  11jul2019
program cmp_marginsplot16
	version 11
	tempname results
	_return hold `results'
	_return restore `results' , hold
	capture nobreak noisily {
		_marginsplot `0'
	}
	local rc = _rc
	_return restore `results'
	if `rc' {
		exit `rc'
	}

end

program _marginsplot

	syntax [using/] [,			///
		Level(passthru)			///
		MCOMPare(passthru)		///
		DERIVLABels				///
		filevarname(string)  	/// njgw added
		mpsaving(string asis) 	/// njgw added
		noPLOTdrawn 			/// njgw added
		OFFSETswitch			/// turn on -offset-
		OFFset(real -1)			/// njgw
		ovar(string)			/// njgw
		*						///
	]
	local 0 `", `options'"'

	//njgw
	if (`offset'!=(-1)) {
		local offsetswitch offsetswitch
	}
	else if ("`offsetswitch'" != "") {
		local offset 0.05
	}

	local maxticks  25			// max default x ticks
	local plotswrap 15			// unique plot definitions

	local TYPE margins
	if `"`using'"' != "" {
		local filenm : copy local using
	}
	else {
		if !inlist("margins", "`r(cmd)'", "`r(cmd2)'") {
		    local cmdlist	mean		///
					proportion	///
					ratio		///
					total
		    if 0`:list posof "`e(cmd)'" in cmdlist' {
			if missing(e(version)) {
				di as err "{p 0 0 2}"
				di as err ///
"{bf:`e(cmd)'} results are not modern enough to work with {bf:marginsplot}"
				di as err "{p_end}"
				exit 301
			}
		        local TYPE `e(cmd)'s
			if "`e(cmd)'" == "proportion" {
				Parse4Prop, `options'
				local options `"`s(options)'"'
				local percent `"`s(percent)'"'
				local 0 `", `options'"'
			}
		    }
		    else if !inlist("margins", "`e(cmd)'", "`e(cmd2)'") {
			di as error "previous command was not {cmd:margins}"
			exit 301
		    }
		    local eclass eclass
		}
		tempfile filenm				// Save margins file
		_marg_save ,	`eclass'	///
				`level' 	///
				`mcompare'	///
				`percent'	///
				saving(`filenm')
	}

	preserve					// Use margins file
	qui use `"`filenm'"', clear

	if "`derivlabels'" != "" {
		capture label list _derivl
		if c(rc) == 0 {
			label values _deriv _derivl
		}
	}

	if _N == 1 & _margin[1]== 0 & _ci_lb[1]==0 {
		di as text "  No margins, nothing to plot"
		exit
	}

	SetupMV

	char _atopt[varname] "_atopt"
	char _term[varname] "_term"
	char _deriv[varname] "_deriv"
	char _margin[varname] "y"

							// Parse
		// Production notes: dimension options allow plurals but are
		// documented as singular.  Same for option recastcis. option
		// byoptions allowed, but undocumented.

	syntax [, Xdimensions(string asis)				///
		  PLOTdimensions(string asis)				///
		  BYdimensions(string asis) 				///
		  GRaphdimensions(string asis)				///
		  ALLXlabels						///
		  NOLABels						///
		  SEParator(string)					///
		  NOSEParator						///
		  ALLSIMplelabels					///
		  NOSIMplelabels					///
		  recast(string)					///
		  RECASTCIs(string)					///
		  NOCI							///
		  BYOPts(string asis)					///
		  BYOPTIONs(string asis)				///
		  HORIZontal						///
		  NAME(string asis)					///
		  UNIQue						///
		  CSORT							///
		  PCYCle(integer -999)					///
		  ADDPLOT(string asis)					///
		  saving(string asis)					///
		  __swapxp						///
		  *							///
		]
					// __swapxp is not to be documented

	local byoptions `"`macval(byoptions)' `macval(byopts)'"'

	if "`allsimplelabels'" != "" & "`nosimplelabels'" != "" {
	   di as error "options {bf:allsimplelabels} and {bf:nosimplelabels} may not be specified together"
	   exit 198
	}
	local simple = 0 + ("`allsimplelabels'" != "") +		///
		       2 * ("`nosimplelabels'" != "")

	if "`noseparator'" != "" {			// Overall separator
		local sep ""
	}
	else {
		local sep = cond(`"`separator'"'=="", ", ", `"`separator'"')
	}

							// Plot style cycling
	if (`pcycle' != -999) {
		if (`pcycle' <= 0)  local pcycle 1
		local plotswrap `pcycle'
	}


	CheckRecast   `recast'
	CheckRecastCI `recastcis'

	local nolabels = "`nolabels'" != ""

	local defaults `"`nolabels' `simple' `"`sep'"'"'

	if `"`: char _dta[marg_save_version]'"' == "2" {
		local SE _se_margin
	}
	else {
		local SE _se
	}

							// drop derivs for bases
	qui drop if _margin==0 & _ci_lb==0 & _ci_ub==0 & `SE'==0

	if "`_dta[cmd]'" == "pwcompare" {		// manage pwcompare data
		tempvar pwstr vsbeg termstr
		qui decode _pw, gen(`pwstr')

		qui gen int `vsbeg' = strpos(`pwstr', "vs")
		qui gen str _pw1s = bsubstr(`pwstr', 1, `vsbeg'-2)
		qui gen str _pw0s = bsubstr(`pwstr', `vsbeg'+3, .)

		if "`unique'" == "" {
		    tempvar hold
		    qui expand 2
		    sort _term _pw0 _pw1
		    quietly {
			by _term _pw0 _pw1:  replace _margin = -_margin if _n==2
			by _term _pw0 _pw1:  replace _ci_lb  = -_ci_lb  if _n==2
			by _term _pw0 _pw1:  replace _ci_ub  = -_ci_ub  if _n==2
			by _term _pw0   _pw1:  gen str `hold' = _pw0
			by _term _pw0   _pw1:  replace _pw0   = _pw1   if _n==2
			sort _term `hold' _pw1
			by _term `hold' _pw1:  replace _pw1   = `hold' if _n==2
		    }
		}


		qui encode _pw0s, gen(_pw0) label(pw0lbl)
		qui encode _pw1s, gen(_pw1) label(pw1lbl)

		qui decode _term, gen(`termstr')
		drop _pw
		sum _term, meanonly
		if r(min) == r(max) {
		    qui gen str _pws = _pw1s + " vs " + _pw0s
		}
		else {
		    qui gen str _pws = `termstr' + ": " + _pw1s + " vs " + _pw0s
		}
		if "`csort'" == "" {
			sort _term _pw0s _pw1s
		} 
		else {
			sort _term _pw1s _pw0s
		}
		forvalues i = 1/`=_N' {
			local pwlbl `"`pwlbl' `i' `"`=_pws[`i']'"'"'
		}
		label define pwlbl `pwlbl'
		qui encode _pws, gen(_pw) label(pwlbl)
		label var _pw "Comparisons"
		char _pw[varname] "_pw"
		char _pw0[varname] "_pw0"
		char _pw1[varname] "_pw1"
		drop _pws _pw0s _pw1s
	}

	ParseDim x  : `defaults' `xdimensions'		// Parse dimension 
	ParseDim pl : `defaults' `plotdimensions'	// variables and options
	ParseDim by : `defaults' `bydimensions'			
	ParseDim gr : `defaults' `graphdimensions'

						// Find/Report dimensions
	if "`_dta[cmd]'" == "pwcompare" {
		if "`unique'" == "" {
			local dimlist "_pw1 _pw0 _term"
		}
		else {
			local dimlist "_pw _term"
		}
	}
	else	ValuesAtsMsBysRest  dimlist

	local ulist 
	foreach var of local dimlist {
		sum `var', meanonly
		if (r(min) == r(max)) continue
		if "`ulist'" != "" {
			capture by `ulist' (`var'), sort:		///
				assert `var'[1] == `var'[_N]
			if (!_rc) continue
		}
		local ulist `ulist' `var'
		capture by `ulist', sort : assert _N == 1
		if (!_rc) continue, break
	}

	di ""
	ToVarnames ulist : `ulist'
	di in smcl "{text}{p 2 6 2}Variables that uniquely identify "	///
		   "`TYPE': `ulist'{p_end}"
	if "`_dta[cmd]'" == "pwcompare" {
	  di ""
	  di in smcl "{text}{p 6 10 2}_pw enumerates all pairwise "	///
	  	"comparisons; _pw0 enumerates the reference "		///
		"categories; _pw1 enumerates the comparison categories.{p_end}"
	}
	local ats : char _dta[k_at]
	if 0`ats' > 1 {
		di in smcl "{text}  Multiple at() options specified:"
		if `ats' < 10 {
			local fmt "%1.0f"
		}
		else if `ats' < 100 {
			local fmt "%2.0f"
		}
		else {
			local fmt "%4.0f"
		}
		forvalues i = 1/`ats' {
			local is = strofreal(`i', "`fmt'")
			di in smcl "{text}{p 6 10 2}_atoption=`is': "	///
				   "`:char _dta[atopt`i']'{p_end}"
		}
	}


						// Set dimensions
	local speclist
	foreach dim in x pl by gr {
		local speclist `speclist' ``dim'list'
	}
	local trylist : list dimlist - speclist

	local uslist `speclist'
	foreach var of local trylist {
		sum `var', meanonly
		if (r(min) == r(max)) continue
		if "`uslist'" != "" {
			capture by `uslist' (`var'), sort:		///
				assert `var'[1] == `var'[_N]
			if (!_rc) continue
		}
		local uslist `uslist' `var'
		capture by `uslist', sort : assert _N == 1
		if (!_rc) continue, break
	}
	local addlist : list uslist - speclist

	if `:list sizeof uslist' > 0 {
		capture by `uslist', sort : assert _N == 1
		if _rc {
			di `"uslist :`uslist':"'
			di in red "_marg_save has a problem.  Margins "	///
				  "not uniquely identified."
			exit 9999
		}
	}

	if "`_dta[cmd]'" == "pwcompare" {
		if "`speclist'" == "" {
			local t "_term"
			if `:list t in addlist' {
				local grlist "_term"
				local addlist : list addlist - t
			}
		}
	}

	if "`xlist'" == "" {
		gettoken xlist addlist : addlist
	}

	if "`pllist'" == "" {
		local pllist `addlist'
		local addlist ""
	}
	else if "`bylist'" == "" {
		local bylist `addlist'
		local addlist ""
	}
	else if "`grlist'" == "" {
		local grlist `addlist'
		local addlist ""
	}
	else if `:list sizeof addlist' > 0 {
		local pllist `pllist' `addlist'
		di in smcl "{text}{p 2 6 2}Dimension options do not "	///
		           "specify all variables required to "		///
			   "uniquely identify margins.  Variables "	///
			   "`addlist' included in plotdimension()."
	}

	if "`__swapxp'" != "" & `"`pllist'"' != `""' {
		local hold   `xlist'
		local xlist  `pllist'
		local pllist `hold'
	}


							// Better labels
	char _predict[varname]  "predict()"
	char _outcome_mv[varname]  "Outcome"
	char _equation[varname] "Equation"

	if "`_dta[cmd]'" == "pwcompare" {
		char _pw[varname]  "Comparisons"
		char _pw0[varname] "Reference category"
		char _pw1[varname] "Comparison category"
	}


							// Make dimensions

	char _atopt[varname] "at()"
	char _term[varname]  "term"
	char _deriv[varname] "Effects with Respect to"
	foreach dim in x pl by gr {
		local ndim : list sizeof `dim'list

		tempvar `dim'var
		tempname `dim'lab
		MakeDim  ``dim'var' ``dim'lab' `dim'contx :		///
			 `dim' `"`macval(`dim'sep)'"' ``dim'simple'	///
			 ``dim'nolabels' `"`macval(`dim'labs)'"'	///
			 `"`macval(`dim'elabs)'"' : ``dim'list'
	}

							// Build graph command

	sum _deriv , meanonly
	local derivs = r(min) < .
	if r(min) < . {
		local is_derivs 1
		if r(min) == r(max) {
			local termnm : label (_deriv) `=_deriv[1]'
		}
	}
	else {
		sum _term , meanonly
		if r(min) == r(max) {
			local termnm : label (_term) `=_term[1]'
		}
	}
	local citype = cond("`recastcis'" == "", "rcap", "`recastcis'")
	if inlist("`citype'","rarea","rbar") {
		local cistylename = substr("`citype'",2,.)
	}
	local title = proper(`"`: char _dta[title]'"')
	local title : subinstr local title " Of " " of "
	if `"`termnm'"' != `""' & `"`termnm'"' != `"_cons"' {
		local title `"`title' of `termnm'"'
	}
	local ytitle = proper(`"`: char _dta[predict_label]'"')
	if `"`macval(ytitle)'"' == `""' {
		local ytitle : char _dta[expression]
	}
	local pct : word 1 of `:var label _ci_lb'
	if "`_dta[cmd]'" == "pwcompare" {
		local pfx "Comparisons of "
	}
	else if "`_dta[cmd]'" == "contrast" {
		local pfx "Contrasts of "
	}
	else if `derivs' {
		local pfx "Effects on "
	}
	label var _margin `"`pfx'`ytitle'"'
	label var _ci_lb `"`pfx'`ytitle'"'
	label var _ci_ub `"`pfx'`ytitle'"'

	local pltype0 "connected"
	if "`horizontal'" == "" {
		local vlist _margin `xvar'
/*
		local pltype0 = cond("`_dta[cmd]'" == "margins", 	///
				     "connected", "scatter")
*/
		local pltype = cond("`recast'" == "", "`pltype0'", "`recast'")
	}
	else {
		local vlist `xvar' _margin
// 		local pltype0 "scatter"
		local pltype = cond("`recast'" == "", "`pltype0'", "`recast'")
		local angle ", angle(0)"
		if `=inlist("`pltype'",					///
		             "area", "bar", "spike", "dropline", "dot")' {
			local vlist _margin `xvar'
			local horizopt "horizontal"
		}
	}

	if _N == 1 {					// one margin
		label var `xvar' " "
		tempname xvlab
		if `"`termnm'"'==`"_cons"' {
			label define `xvlab' 1 "Overall"
		}
		else {
			label define `xvlab' 1 " "
		}
		label values `xvar' `xvlab'
	}

	local xy = cond("`horizontal'" == "", "x", "y")
//	local xvlab = cond(`xnolabels', "", "`xy'label(, valuelabels)")
	local xvlab "`xy'label(, valuelabels)"
	if "`_dta[cmd]'" == "pwcompare" {
		if "`pllist'" == "_pw1" {
			local legtitle `"title("Comparison category")"'
		}
		else if "`pllist'" == "_pw0" {
			local legtitle `"title("Reference category")"'
		}
	}

	if `"`addplot'"' != `""' {		// addplot() and order()
		local draw "nodraw"		// skip, Must draw to make top
		_parse expand addplot below : addplot , common(BELOW)

		if "`below_op'" == "below" {
			forvalues i = 1/`addplot_n' {
				local order `"`macval(order)' `i'"'
			}
			local addplot_offset = `addplot_n'
		}
	}
	else	local addplot_offset = 0

	capture des , varlist
	local allvars `r(varlist)'

	local 0 `", `options'"'
	syntax [, PLOTOPts(string asis) * ]
	FixPlotOpt plotopts : `macval(plotopts)'
	local 0 `", `options'"'
	syntax [, CIOPts(string asis) * ]
	FixPlotOpt ciopts : `macval(ciopts)'

	local k0 = 0 + 0`addplot_offset'
	local i = 0
	sum `plvar' , meanonly
	local k_pl = r(max)
	local sep ""

	//------------------------------------------------------------
	//NJGW : use FindVar for this!
	// figure out which variable indexes file number
	foreach var of varlist _m* {
		local vn : char `var'[varname]
		if "`vn'"=="`filevarname'" {
			local filemname `var'
		}
	}
	if mi("`filemname'") {
		qui gen _filenumber=1
		local filemname _filenumber
	}
	sum `filemname', meanonly
	local numfiles `r(max)'
	
	// Rename created variables (will only exist if this is a second-tier combied file)
	preserveOldVars lplotnum fileopts fileciopts lplotopts lciopts
	// NJGW create variable that index logical plot associated with each observation
	MakeLPlotNums "`bylist'" "`filemname'" "`xlist'" "`pllist'"
	sum lplotnum, meanonly
	local k_lpl = r(max)
	
	// NJGW initiate string variables to hold additional plot options
	qui {
		gen fileopts   = ""
		gen fileciopts = ""
		gen lplotopts  = ""
		gen lciopts    = ""
	}
	
	// NJGW grab file`i'opts and fileci`i'opts
	forval i=1/`numfiles' {
		local 0 `", `options'"'
		syntax [ , FILE`i'opts(string) FILECI`i'opts(string) * ]
		qui {
			FixPlotOpt file`i'opts : `macval(file`i'opts)' 
			replace fileopts = fileopts + `"`file`i'opts'"' if `filemname'==`i'

			FixPlotOpt fileci`i'opts : `macval(fileci`i'opts)' 
			replace fileciopts = fileciopts + `"`fileci`i'opts'"' if `filemname'==`i'
		}		
	}

	// NJGW deal with logical plot and logical CI options
	// runs up to 15 in order to allow extra lplot# and lci# options, which are ignorred
	forval i=1/15 {			
		local 0 `", `options'"'

		syntax [ , LPLOT`i'opts(string) LCI`i'opts(string) * ]
		qui {
			FixPlotOpt lplot`i'opts : `macval(lplot`i'opts)' 
			replace lplotopts = lplotopts + `"`lplot`i'opts'"' if lplotnum==`i'

			FixPlotOpt lci`i'opts : `macval(lci`i'opts)' 
			replace lciopts = lciopts + `"`lci`i'opts'"' if lplotnum==`i'
		}
	}
	// NJGW END
	//------------------------------------------------------------

	if "`noci'" == "" {				// CI plots
		forvalues i = 1/`k_pl' {
			local pstyle = mod(`i'-1, `plotswrap') + 1
			GetMsymbol symopt : `=`i'-1' `pcycle' `plotswrap' // sic
			local plif "if `plvar' == `i'"

			local 0 `", `options'"'
			syntax [, CI`i'opts(string asis) * ]

			* NJGW -- apply fileci`i'opts and lci`i'opts 
			* at this point they are stored in variables fileciopts & lciopts
			qui {
				levelsof lciopts if `plvar'==`i', local(curlciopts) clean
				levelsof fileciopts if `plvar'==`i', local(curfileciopts) clean
			}
			// NJGW Replaced: 
			//FixPlotOpt ci`i'opts : `macval(ci`i'opts)'
			FixPlotOpt ci`i'opts : `macval(ci`i'opts)' `macval(curfileciopts)' `macval(curlciopts)' 
			
			// njgw replaced:
			// local ci `"`sep'`citype' _ci_lb _ci_ub `xvar' `plif', pstyle(p`pstyle')              `horizontal' `ciopts' `ci`i'opts'"'
			local  ci `"`sep'`citype' _ci_lb _ci_ub `xvar' `plif', pstyle(p`pstyle'`cistylename') `horizontal' `ciopts' `ci`i'opts'"'

			local sep "|| "

			local ciplots `"`ciplots' `ci' `symopt'"'
		}

		local k0 = `k_pl' + 0`addplot_offset'

		local title `"`title' with `pct' CIs"'
	}

	if ("`pltype'" == "area" || "`pltype'" == "bar") {
		local k0 = 0 + 0`addplot_offset'
	}

	local sep ""
	forvalues i = 1/`k_pl' {			// margin plots
		local i1 = `i' - 1
		local pstyle = mod(`i1', `plotswrap') + 1
		GetMsymbol symopt : `i1' `pcycle' `plotswrap'

		local plif "if `plvar' == `i'"

		local 0 `", `options'"'
		syntax [, PLOT`i'opts(string asis) * ]

		// NJGW -- apply file`i'opts and lplot`i'opts to appropriate plots 
		//         at this point they are stored in appropriate observations of -fileopts- and lplotopts-
		qui {
			levelsof lplotopts if `plvar'==`i', local(curlplotopts) clean
			levelsof fileopts if `plvar'==`i', local(curfopts) clean
		}
		FixPlotOpt plot`i'opts : `macval(plot`i'opts)' `macval(curfopts)' `macval(curlplotopts)' 
		// njgw replaced
		// FixPlotOpt plot`i'opts : `macval(plot`i'opts)' 

		local plot `"`sep'`pltype' `vlist' `plif', pstyle(p`pstyle') `symopt' `horizopt' `plotopts' `plot`i'opts'"'
		local sep "|| "

		local order `"`macval(order)' `=`k0'+`i'' `"`:label (`plvar') `i''"'"'

		local mplots `"`mplots' `plot'"'
	}

	local sep = cond("`noci'" == "", "||", "")
	if ("`pltype'" == "area" || "`pltype'" == "bar") {
		local graph `"twoway `mplots' `sep' `ciplots'"'
	}
	else {
		local graph `"twoway `ciplots' `sep' `mplots'"'
	}

	if `"`addplot'"' != `""' {
		local ka = `k_pl' + ("`noci'"=="")*`k_pl'
		if "`below_op'" != "below" {
			forvalues i = 1/`addplot_n' {
				local order `"`macval(order)' `=`ka'+`i''"'
			}
		}
	}


	if (`k_pl' < 2 & `"`addplot'"' == `""') {
		local legend "legend(off)"
		local bylegend "legend(off)"
	}
	else {
		local legend `"legend(order(`macval(order)') `legtitle')"'
	}


							// Draw graphs
	sort `xvar'
	sum `grvar' , meanonly
	local n_gr = r(max)
	if `n_gr' > 1 {
		if `"`name'"' == `""' {
			local name "name(_mp_\`i', replace)"
		}
		else {
			local 0 `name'
			syntax [anything] [, replace]
			local name `"name(`anything'\`i', `replace')"'
		}

		if `"`saving'"' != `""' {
			local hold `macval(options)'
			local 0 `macval(saving)'
			syntax [anything] [, *]
			local saving `"saving(`anything'\`i', `options')"'
			local options `macval(hold)'
		}
	}
	else {
		local name `"name(`name')"'
		local saving `"saving(`macval(saving)')"'
	}

	if `"`addplot'"' != `""' {
		local saveadd `macval(saving)'
		local saving ""
	}

	local titleopt `"title(`"`title'"', span size(*.9))"'
	tempfile marginsdata

	// njgw
	if "`plotdrawn'"!="noplotdrawn" {
		forvalues i = 1/`n_gr' {
			qui levelsof `xvar'
			local levs `r(levels)'
			sum `xvar' if `grvar' == `i', meanonly
			if !`xcontx' & (0`r(max)' < `maxticks' | "`allxlabels'" != "") {
				local xlabopt "`xy'label(1(1)0`r(max)' `angle')"
			}
			else if (`:list sizeof levs' < `maxticks') {
				local xlabopt "`xy'label(`levs' `angle')"
			}
			else if `"`angle'"' != `""' {
				local xlabopt "`xy'label(`angle')"
			}
			if `n_gr' > 1 {
			    local subtitleopt `"subtitle(`"`: label (`grvar') `i''"', span)"'
			}
			if ("`bylist'" != "") {
				local by `"by(`byvar' , title(`"`macval(title)'"') `macval(subtitleopt)' note("") `bylegend' `macval(byoptions)')"'
				local titleopt ""
				local subtitleopt ""
			}
			// njgw begin -- offset
			if "`offsetswitch'"!="" {
				if !mi("`ovar'"){
					// separate based on ovar
					foreach var of varlist _m* {
						if `"`:char `var'[varname]'"'=="`ovar'" {
							local offsetvar `var'
						}
					}
					if mi("`offsetvar'"){
						di as error "Can’t find `ovar' in margins file"
						exit 111
					}
				}
				else {
					//separate by plots 
					local offsetvar `plvar'
				}
				qui ta `offsetvar'
				local nwN = r(r)		// number of plots
				qui replace `xvar' = `xvar' + `offset'*((`offsetvar'-1) - (r(r)-1)/2)
			}
			// njgw end

			`graph' || if `grvar' == `i' , `titleopt' `subtitleopt'	///
				   `xlabopt' `xvlab' `macval(legend)' 		///
				   /*`draw'*/ `name' `saving' `by' `macval(options)'

			if `"`addplot'"' != `""' {
				qui save `"`marginsdata'"', replace
				restore, preserve
				graph addplot || , `macval(legend)' `saveadd' || ///
					`addplot' 
				qui use `"`marginsdata'"', replace
			}
		}
	}
	if !mi(`"`mpsaving'"') {
		// tempvars *should* be unnecessary to new call to cmp or mplotoffset
		qui drop __*
		save `mpsaving'
	}

end

program Parse4Prop, sclass
	syntax [, percent NOPERCENT *]
	local percent `percent' `nopercent'
	opts_exclusive "`percent'"
	sreturn local options `"`options'"'
	sreturn local percent `"`percent'"'
end

program ParseDim
	gettoken pfx      0 : 0
	gettoken colon    0 : 0
	gettoken nolabdef 0 : 0
	gettoken simpdef  0 : 0
	gettoken sepdef   0 : 0

	syntax [anything] [, 						///
		  SEParator(string)					///
		  NOSEParator						///
		  LABels(string asis)					///
		  ELABels(string asis)					///
		  ALLSIMplelabels					///
		  NOSIMplelabels					///
		  NOLABels						///
		]

	if "`allsimplelabels'" != "" & "`nosimplelabels'" != "" {
	   di as error "options {bf:allsimplelabels} and {bf:nosimplelabels} may not be specified together"
	   exit 198
	}
	local simple = 0 + ("`allsimplelabels'" != "") +		///
		       2 * ("`nosimplelabels'" != "")

						// Make and check varlist
	Ats                atlist
	local natlist : list sizeof atlist
	if `natlist' {
		tempname m_atlist
		Mat4FindVar `m_atlist' `atlist'
	}
	MsBysValuesAtsRest truelist
	local ntruelist : list sizeof truelist
	if `ntruelist' {
		tempname m_truelist
		Mat4FindVar `m_truelist' `truelist'
	}
	MsBysAtsRest       fulllist
	local nfulllist : list sizeof fulllist
	if `nfulllist' {
		tempname m_fulllist
		Mat4FindVar `m_fulllist' `fulllist'
	}
	local vlist ""
	foreach tok of local anything {
		if strpos(`"`tok'"', "at(") {
			local 0 , `tok'
			capture syntax , at(string)
			if _rc {
			    di as error "invalid dimension specification: `tok'"
			    exit 198
			}
			FindVar var : `at' 1 "`m_atlist'" `atlist'
		}
		else {
			FindVar var : `tok' 0 "`m_truelist'" `truelist'
			if "`var'" == "" {
				FindVar var : `tok' 1 "`m_fulllist'" `fullist'
			}
		}
		local vlist `vlist' `var'
	}

	c_local `pfx'list `vlist'

							// Save options
	if "`noseparator'" != "" {
	   local sep ""
	}
	else {
	   local sep = cond(`"`separator'"'==`""', `"`sepdef'"',`"`separator'"')
	}

	c_local `pfx'sep   `"`macval(sep)'"'
	c_local `pfx'labs  `"`macval(labels)'"'
	c_local `pfx'elabs `"`macval(elabels)'"'
	c_local `pfx'simple = cond(`simple', `simple', `simpdef')
	c_local `pfx'nolabels = cond("`nolabels'" != "", 1, `nolabdef')
end

program Mat4FindVar
	version 16

	gettoken m 0 : 0
	foreach x of local 0 {
		local v : char `x'[varname]
		capture {
			assert `:list sizeof v' == 1
			confirm name `v'
		}
		if c(rc) {
			local list `list' `x'
		}
		else {
			local list `list' `v'
		}
	}

	local dim : list sizeof list
	matrix `m' = J(1,`dim',0)
	matrix colna `m' = `list'
end

// program Mat4FindVar
// 	gettoken m 0 : 0
// 	foreach x of local 0 {
// 		local v : char `x'[varname]
// 		local list `list' `v'
// 	}
// 	local dim : list sizeof list
// 	matrix `m' = J(1,`dim',0)
// 	matrix colna `m' = `list'
// end

program Ats
	args target 

	capture des _at* , varlist
	local list `r(varlist)'
	// local list : subinstr local list "_at" ""
	// local list : subinstr local list "_atopt" ""
	//njgw -- this version doesn't depend on order of variables in DS
	local cuts _at _atopt
	local list : list list - cuts

	c_local `target' `list'
end

program ValuesAts			// Keep only ats with multiple values
	args target

	local i = 1
	while 1 {
		local atstats : char _dta[atstats`i++']
		if ("`atstats'" == "") continue, break

		local j 1
		foreach stat of local atstats {
			if "`stat'" == "values" {
				local atlist `atlist' _at`j'
			}
			local ++j
		}
	}
	local atlist : list uniq atlist

					// Put in order specified in at options
	local atorder `_dta[_u_at_vars]'
	foreach tok of local atorder {
		if `: list tok in atlist' {
			local atlistord `atlistord' `tok'
		}
	}

	c_local `target' `atlistord' 
end

program Ms
	args target 

	capture des _m*  , varlist
	local list `list' `r(varlist)'
	//njgw: doesn't rely on variable order in DS
	// local list : subinstr local list "_margin" ""
	local cut _margin
	local list : list list - cut

	c_local `target' `list'
end

program Bys
	args target 

	capture des _by* , varlist

	c_local `target' `r(varlist)'
end

program Rest
	args target

	local altvar : char _dta[altvar]

	local list
	foreach v in _atopt _term _deriv _equation ///
		     _outcome `altvar' ///
		     _outcome_mv _predict ///
		     _pw _pw0 _pw1 {
		capture confirm variable `v'
		if !_rc {
			local list `list' `v'
		}
	}

	c_local `target' `list'
end

program ValuesAtsMsBysRest
	args target

	ValuesAts atlist
	Ms        mlist
	Bys       bylist
	Rest      restlist

	c_local `target' `atlist' `mlist' `bylist' `restlist'
end

program AtsMsBysRest
	args target 

	Ats  list
	Ms   mlist
	Bys  bylist
	Rest restlist

	c_local `target' `atlist' `mlist' `bylist' `restlist'
end

program MsBysValuesAtsRest 
	args target

	ValuesAts atlist
	Ms        mlist
	Bys       bylist
	Rest      restlist

	c_local `target' `mlist' `bylist' `atlist' `restlist'
end

program	MsBysAtsRest
	args target 

	Ats  list
	Ms   mlist
	Bys  bylist
	Rest restlist

	c_local `target' `mlist' `bylist' `atlist' `restlist'
end

program CheckRecast

	if `:word count `0'' > 1 {
		di as error `"option {bf:recast(`0')} not allowed"'
		exit 198
	}

	local a `"`0'"'
	local 0 `", `0'"'
	capture syntax [, scatter line connected area bar spike dropline dot ]
	if _rc {
		di as error `"option {bf:recast(`a')} not allowed"'
		exit 198
	}
end

program CheckRecastCI

	if `:word count `0'' > 1 {
		di as error `"option {bf:recast(`0')} not allowed"'
		exit 198
	}

	local a `"`0'"'
	local 0 `", `0'"'
	capture syntax [, rscatter rline rconnected rarea rbar rspike	///
			  rcap rcapsymdropline ]
	if _rc {
		di as error `"recast(`a') not allowed"'
		exit 198
	}
end


//njgw
program FindVarPlotOpt
	gettoken varmac 0 : 0
	gettoken colon  0 : 0
	gettoken nm     0 : 0
	gettoken report 0 : 0

	local nm : tsnorm `nm' , varname

	foreach var of local 0 {
		if `"`nm'"' == `"`: char `var'[varname]'"' {
			local fvar `var'
			continue, break
		}
	}

	if `"`fvar'"' == `""' {
		if `report' == 1 {
		    di as error "`nm' not a dimension in {cmd:margins} results"
		    exit 322
		}
		else if `report' == 2 {
		    local fvar `nm'
		}
	}

	c_local `varmac' `fvar'
end

program FindVar 
	gettoken varmac 0 : 0
	gettoken colon  0 : 0
	gettoken nm     0 : 0
	gettoken report 0 : 0
	gettoken m      0 : 0

	if "`m'" != "" {
		local pos = colnumb(`m', "`nm'")
	}
	else	local pos .

	if missing(`pos') {
		if `report' == 1 {
		    di as error "`nm' not a dimension in {cmd:margins} results"
		    exit 322
		}
		else if `report' == 2 {
		    local fvar `nm'
		}
	}
	else	local fvar : word `pos' of `0'

	c_local `varmac' `fvar'
end

program ToVarnames
	gettoken macnm 0 : 0
	gettoken colon 0 : 0

	foreach var of local 0 {				// non ats
		if bsubstr("`var'",1,3) != "_at" {
			local nats `nats' ``var'[varname]'
		}
	}

	foreach var of local 0 {				// map names
		if bsubstr("`var'",1,3) == "_at" {
			local varnm ``var'[varname]'
			if `:list varnm in nats' {
				local list `"`list' at(``var'[varname]')"'
			}
			else {
				local list `list' ``var'[varname]'
			}
		}
		else {
			local list `list' ``var'[varname]'
		}
	}

	c_local `macnm' `list'

end


program MakeDim
	gettoken dimvar  0 : 0
	gettoken dimlab  0 : 0
	gettoken contx   0 : 0
	gettoken colon   0 : 0
	gettoken dim     0 : 0
	gettoken sep     0 : 0
	gettoken simple  0 : 0
	gettoken nolab   0 : 0
	gettoken labels  0 : 0
	gettoken elabels 0 : 0
	gettoken colon   0 : 0

	local 0 `0'
	local k : list sizeof 0

	c_local `contx' 0

	if `k' == 0 {					// No variables
		qui gen byte `dimvar' = 1
		label var `dimvar' "No `dim' dimension"

		exit						// Exit
	}

	tempvar tag revtag
	qui by `0', sort: gen byte `tag' = _n==1
	qui gen byte `revtag' = !`tag'


	sort `revtag' `0'				// Dim variable
	if (`k' == 1 & "`dim'" == "x" & `simple' != 2) {
		qui clonevar `dimvar' = `0'
	}
	else	qui gen `c(obs_t)' `dimvar' = _n if `tag'

	if ! (`k' == 1 & (						    ///
	   (bsubstr("`0'",1,3) == "_at" & "`0'"!="_at" & "`0'"!="_atopt") | ///
	   (bsubstr("`0'",1,2) == "_m"  & "`0'"!="_margin") |		    ///
	   (bsubstr("`0'",1,3) == "_by") |				    ///
	   "`0'" == "_outcome" ) ) {
	     forvalues i=1/`k' {			// variable label
		local msep = cond(`i'==1, "", `"`sep'"')
		local lab `"`lab'`msep'`:char `:word `i' of `0''[varname]'"'
	     }
	     label variable `dimvar' `"`lab'"'
	}
	else {
		label var `dimvar' `"`:var label `0''"'
	}

/*
	if `k' == 1 & (							    ///
	   (bsubstr("`0'",1,3) == "_at" & "`0'"!="_at" & "`0'"!="_atopt") | ///
	   (bsubstr("`0'",1,2) == "_m"  & "`0'"!="_margin") |		    ///
	   (bsubstr("`0'",1,3) == "_by") ) {
		label var `dimvar' `"`:var label `0''"'
	}
*/
	if (`k' == 1 & "`dim'" == "x" & `simple' != 2) {
	    if `"`labels'`elabels'"' == "" {
		if (`nolab')  label values `dimvar'
		c_local `contx' 1
		exit						// Exit
	    }
	}

	qui count if `tag'				// value labels
	forvalues i = 1/`=r(N)' {
		local lab ""
		local j 0
		foreach var of local 0 {
			if `++j' > 1 {
				local lab `"`lab'`sep'"'
			}

			local iscontrast = "`:char _dta[cmd]'" == "contrast"
			local ism = bsubstr("`var'",1,2) == "_m"
			local islabeled =				///
			      ("`:value label `var''" != "") &		///
			      !`nolab'
			local olab = `islabeled' & ! (`iscontrast' & `ism')
			if `simple' == 2 | 				///
			   (`simple' == 0 & 				///
			   (!`olab' & (`k' > 1 | "`dim'" != "x"))) {
				if `iscontrast' & `ism' {
				     local lab `"`lab'`:char `var'[varname]': "'
				}
				else local lab `"`lab'`:char `var'[varname]'="'
			}

			if `nolab' {
				local value = 				///
				      strofreal(`var'[`i'], "`:format `var''")
			}
			else if `var'[`i'] >= . {
				local value : label (_atopt) `=_atopt[`i']'
				if `"`value'"' == `"."' {
					local value "asobserved"
				}
				else if `"`value'"' == 			///
					`"(mean) _factor (mean) _continuous"' {
					local value "(mean)"
				}
			}
			else {
				if `islabeled' {
				      local value : label (`var') `=`var'[`i']'
				}
				else {
				      local value = 			///
					strofreal(`var'[`i'], "`:format `var''")
				}
			}
			local lab `"`lab'`value'"'
		}
		label define `dimlab' `i' `"`lab'"' , add
	}

	if `"`labels'"' != `""' {
		label drop `dimlab'
		local i 0
		foreach lab of local labels {
			label define `dimlab' `++i' `"`macval(lab)'"' , add
		}
	}

	if `"`elabels'"' != `""' {
		label define `dimlab' `macval(elabels)' , modify
	}

	label values `dimvar' `dimlab'

	qui by `0' (`tag'), sort:  replace `dimvar' = `dimvar'[_N]


end

program FixPlotOpt 
	gettoken plotopt  0    : 0
	gettoken colon    opts : 0

	local 0 `", `macval(opts)'"'
	syntax [, MLabel(string asis) *]

	if "`mlabel'" == "" {
		c_local `plotopt' `"`macval(opts)'"'
		exit
	}

	capture des , varlist
	local allvars `r(varlist)'

	tempname m_allvars
	Mat4FindVar `m_allvars' `allvars'
	foreach nm of local mlabel {


		FindVar var : `nm' 2 "`m_allvars'" `allvars'
		local vlist `vlist' `var'
	}

	c_local `plotopt' mlabel(`vlist') `macval(options)'
end

// program FixPlotOpt 
// 	gettoken plotopt  0    : 0
// 	gettoken colon    opts : 0

// 	local 0 `", `macval(opts)'"'
// 	syntax [, MLabel(string asis) *]

// 	if "`mlabel'" == "" {
// 		c_local `plotopt' `"`macval(opts)'"'
// 		exit
// 	}

// 	capture des , varlist
// 	local allvars `r(varlist)'

// 	foreach nm of local mlabel {
// 		//njgw fix
// 		FindVarPlotOpt var : `nm' 2 `allvars'
// 		// FindVar var : `nm' 2 `allvars'
// 		local vlist `vlist' `var'
// 	}

// 	c_local `plotopt' mlabel(`vlist') `macval(options)'
// end


program SetupMV
	// Improve labels for multivariate, multinomial, and ordinal multiple
	// models that default to multiple predicts().

	qui clonevar _outcome_mv  = _predict
	qui clonevar _equation = _predict

	char _predict[varname]  "_predict"
	char _outcome_mv[varname]  "_outcome"
	char _equation[varname] "_equation"

	sum _predict, meanonly
	if (r(min) == r(max))  exit				// exit

	tempvar predstr loc sep stat subopt eo1 eo2 rest
	qui decode _predict, gen(`predstr')

	qui replace `predstr' = bsubstr(`predstr', 9, .)	// rid predict(
	qui gen int `sep' = strpos(`predstr', " ")
	qui gen str `stat' = bsubstr(`predstr', 1, `sep'-1)

	capture assert `stat' == `stat'[_n-1] in 2/l		// one stat
	if (_rc)  exit						// exit
	
	qui replace `predstr' = bsubstr(`predstr', `sep'+1, .)	
	qui gen int `loc' = strpos(`predstr', "(")
	if (`loc'[1] == 0)  exit				// exit

	capture assert `loc' == `loc'[_n-1] in 2/l		// same opt
	if (_rc)  exit						// exit
	capture assert bsubstr(`predstr',       1, `loc') ==		///
		       bsubstr(`predstr'[_n-1], 1, `loc') in 2/l
	if (_rc)  exit						// exit

	local subopt = bsubstr(`predstr'[1], 1, `loc'-1)

	if (! inlist(`"`subopt'"', "outcome", "equation"))  exit	// exit

	qui replace `predstr' = bsubstr(`predstr', `loc'+1, .)	

	qui replace `loc' = strpos(`predstr', "))")
	if (`loc'[1] == 0)  exit				// exit
	qui gen str `rest' = bsubstr(`predstr', `loc'+2, .)
	capture assert `rest' == ""
	if (_rc)  exit						// exit

	qui replace `sep' = strpos(`predstr', " ")

	if (`sep'[1] == 0) {					// outcome | eqn
		LabelY `=`stat'[1]'

		qui gen str `eo1' = bsubstr(`predstr', 1, `loc'-1)

		if "`subopt'" == "equation" {
			qui replace _outcome_mv = .
			qui drop _equation
			qui gen _equation = real(`eo1')
			capture assert _equation != .
			if _rc {
			      drop _equation
			      qui encode `eo1', gen(_equation) label(_equation)
			}
			char _equation[varname] "_equation"
		}
		else {						// "outcome"
			qui replace _equation = .
			qui drop _outcome_mv
			qui gen _outcome_mv = real(`eo1')
			capture assert _outcome_mv != .
			if _rc {
				drop _outcome_mv
				qui encode `eo1', gen(_outcome_mv) ///
					label(_outcome_mv)
			}
			char _outcome_mv[varname]  "_outcome"
		}

		exit						// exit
	}

					// possible multivariate ordered outcome

	qui gen str `eo1' = bsubstr(`predstr', 1, `sep'-1)
	qui replace `predstr' = bsubstr(`predstr', `sep'+1, .)	

	qui replace `sep' = strpos(`predstr', " ")
	capture assert `sep' == 0
	if (_rc)  exit						// exit

	qui replace `loc' = strpos(`predstr', "))")
	if (`loc'[1] == 0)  exit				// exit
	qui gen str `eo2' = bsubstr(`predstr', 1, `loc'-1)

	qui drop _equation _outcome_mv
	qui gen _equation = real(`eo1')
	capture assert _equation != .
	if _rc {
		drop _equation
		qui encode `eo1', gen(_equation) label(_equation)
	}

	qui gen _outcome_mv = real(`eo2')
	capture assert _outcome_mv != .
	if _rc {
		drop _outcome_mv
		qui encode `eo2', gen(_outcome_mv)  label(_outcome_mv)
	}
	char _outcome_mv[varname]  "_outcome"
	char _equation[varname] "_equation"

	LabelY `=`stat'[1]'
end


program LabelY
	args stat

	if `"`stat'"' == "xb" {
		char _dta[predict_label] "Linear prediction"
	}
	else if `"`stat'"' == "pr" {
		char _dta[predict_label] "Probability"
	}
	else {
		char _dta[predict_label] "`stat'"
	}
end


program GetMsymbol
	args symmac colon i pcycle plotswrap

	if `pcycle' == -999 {
		if floor(`i' / `plotswrap') == 1 {
			local symopt "msymbol(triangle)"
		}
		else if floor(`i' / `plotswrap') == 2 {
			local symopt "msymbol(square)"
		}
		else if floor(`i' / `plotswrap') == 3 {
			local symopt "msymbol(diamond)"
		}
		else if floor(`i' / `plotswrap') == 4 {
			local symopt "msymbol(x)"
		}
		else if floor(`i' / `plotswrap') == 5 {
			local symopt "msymbol(plus)"
		}
	}
	
	c_local `symmac' `symopt'
end

//NJGW
program MakeLPlotNums, sortpreserve
	args bylist filemname xlist pllist 

	by `bylist' `filemname' `xlist' (`pllist'), sort: gen lplotnum=_n

end

//NJGW
program preserveOldVars
	foreach var in `0' {
		// if this is a second-tier combined file...
		capture confirm variable `var'
		if !_rc {
			local nn 0
			capture confirm variable `var'`nn'
			while !_rc {
				local nn = `nn'+1
				capture confirm variable `var'`nn'
			}
			rename `var' `var'`nn'
		}
	}
end

exit


// Order preference:  

	_userlist_ _at#s _m#s _by#s _atopt _term 			///
		   _predict|_outcome|_outcome_mv|_equation _deriv



