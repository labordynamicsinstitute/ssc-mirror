********************************************************************************************************************************
** Control Function Estimation of Non-Linear Binary Outcome Models *************************************************************
********************************************************************************************************************************
*! version 2.1 2024-12-13 ey & ht (analytical cross-stage derivatives for Terza (2023))
*! version 2.0 2024-12-02 ht (Terza (2023) variance-covariance estimation)
*! version 1.3 2023-12-17 ht (option order())
*! version 1.2 2023-12-03 ht (non-linear first stage, options fslink() and fsswitch)
*! version 1.1 2023-11-23 ht (new syntax, various checks, factor vars., handling of results)
*! version 1.0 2023-11-14 ey
*! authors Elena Yurkevich & Harald Tauchmann 
*! Control Function Estimation of Non-Linear Binary Outcome Models
cap program drop cfbinout
program cfbinout, eclass
	version 14
	if !replay() {	
		quietly {
			** STORE COMMAND-LINE ENTRY **			
			local cmd "cfbinout"
			local cmdline "`cmd' `*'"
			** DISPLAY-FORMAT for WARNINGS **
			local ls = c(linesize)-7
			syntax anything(equalok) [if/] [in] [iweight fweight pweight/], /*outcome(varname ts) endog(varlist fv ts) ivset(varlist fv ts) controls(varlist fv ts) 
			 Link(string) 
			*/ [noRESGenerate] [RESName(string)] [REPLace] [FSLink(string)] [FSSwitch] [Order(integer 1)] [TERza(integer 2023)] [FSKeep] [noSEARCH] [noANAlytic] [EDTZERO(real 0.0001)] [noSANDwich] [] /*
			*/ [Robust] [CLuster(varname)] [VCE(string)] /*
			*/ [LEVel(real `c(level)')] [noci] [noPValues] [noOMITted] [VSQUISH] [noEMPTYcells] [BASElevels] [ALLBASElevels] [noFVLABel] [fvwrap(integer 1)] [fvwrapon(string asis)] /*
			*/ [CFORMAT(string asis)] [PFORMAT(string asis)] [SFORMAT(string asis)] [nolstretch] /*
			*/ [DIFficult] [TECHnique(passthru)] [ITERate(passthru)] [TOLerance(passthru)] [LTOLerance(passthru)] [NRTOLerance(passthru)] [QTOLerance(passthru)] [NONRTOLerance] [FROM(passthru)]
			** RESERVE NAME FOR TEMPORARY OBJECTS **
			tempname _bfs _Vfs _alphaxtd _betaxtd _Bbeta _Balpha _Valphaxtd _Vbetaxtd _W _X _Bu _BW _SCORE _WVEC _EACCM _b _V _G _DER _omit	_checkvfs _Vmissing	
			tempvar _tempweight _one _id _tmpres _score2s _xb2s _esample _fsesample _touse _2spr
			** PARSEING Of ANYTHING **				
			local outexo = ustrregexrf("`anything'"," \((.)+\)","", 1)
			local endoinst = ustrregexrf("`anything'","`outexo'","", 1)
			gettoken link outexo : outexo
			if "`link'" != "logit" & "`link'" != "probit" & "`link'" != "cloglog" {
				noi di as error "{p 0 2 2 `ls'}link {bf:`link'} not allowed {p_end}"
				exit 111
			}
			gettoken outcome controls : outexo			
			gettoken endoinst : endoinst, parse("=")  match(paren)
			gettoken endog ivset : endoinst, parse("=")  match(paren) bind
			gettoken dump ivset : ivset, parse("=")
			local controls : list uniq local(controls)
			local endog : list uniq local(endog)
			local ivset : list uniq local(ivset)
			** CHECK VALIDITY OF SYTAX WITHIN anything **
			foreach vl in controls endog ivset {
				if ("`vl'" == "controls" & "`controls'" != "") | "`vl'" != "controls" {
					local rr = 0
					foreach cc in "," "(" ")" "=" {					
						local lc : list posof "`cc'" in local(`vl')
						local rr = `rr'+ `lc'
					}
					if `lc' != 0 {
						if "`vl'" == "controls" {
							noi di as error "{p 0 2 2 `ls'}varlist1 incorrectly specified{p_end}" 
						}
						else if "`vl'" == "controls" {
							noi di as error "{p 0 2 2 `ls'}varlist2 incorrectly specified{p_end}" 							
						}
						else {
							noi di as error "{p 0 2 2 `ls'}varlist_iv incorrectly specified{p_end}" 							
						}
						exit 111
					}
					fvrevar ``vl'', list
				}
			}
			** CHECK VALIDITY OF OUTCOME VARIABLE **
			if "`outcome'" == "" {
				noi di as error "{p 0 2 2 `ls'}no depvar specified{p_end}"
				exit 102
			}
			else {
				cap confirm variable `outcome'
				if _rc != 0 {
					noi di as error "{p 0 2 2 `ls'}variable {bf:`outcome'} not found{p_end}"
					exit 111
				}
				else {
					cap confirm numeric variable `outcome'
					if _rc != 0 {
						noi di as error "{p 0 2 2 `ls'}variable {bf:`outcome'} is string, string vars. not allowed {p_end}"
						exit 111
					}
				}
			}
			** HANDLE ENPTY CELLS **
			set emptycells drop
			** HANDLE DEPENDENT VARIABLE **
			foreach fo in "##" "#" "." {
				local check = ustrpos("`outcome'","`fo'")
				if `check' != 0 {
					if "`fo'" == "##" | "`fo'" == "#" {
						display as error "{p 0 2 2 `ls'}depvar must not be an interaction{p_end}"
						exit 198					
					}
					else {
						display as error "{p 0 2 2 `ls'}depvar must not be a factor variable{p_end}"
						exit 510										
					}
				}
			}
			** CHECK FOR OVERLAP IN VARLISTS **
			fvexpand `endog'
			local expaenames "`r(varlist)'"
			fvexpand `controls'
			local expacoames "`r(varlist)'"
			fvexpand `ivset'
			local expainames "`r(varlist)'"
			local overlap : list local(expaenames) & local(expacoames)
			if "`overlap'" != "" {
				noi di as text "{p 0 2 2 `ls'}warning: {bf:`overlap'} included in both, list of exogneous vars. and list of endogneous regressors{p_end}"
			}
			local overlap : list local(expaenames) & local(expainames)
			if "`overlap'" != "" {
				noi di as text "{p 0 2 2 `ls'}warning: {bf:`overlap'} included in both, list of endogneous regressors and list of instruments{p_end}"
			}
			local overlap : list local(expacoames) & local(expainames)
			if "`overlap'" != "" {
				noi di as text "{p 0 2 2 `ls'}warning: {bf:`overlap'} included in both, list of exogneous regressors and list of instruments{p_end}"
			}
			** MANAGE IF **
			if "`if'" != "" {
				local iff "if (`if' & `outcome' <.)"
			}
			else {
				local iff "if (1==1 & `outcome' <.)"
			}
			** MANAGE WEIGHT **
			if "`exp'" != "" {
				local eqs "="
			}
			if "`weight'" != "pweight" {
				local l1sweight "`weight'"
			}
			else {
				local l1sweight "iweight"	
			}
			local 2sweight "`weight'"
			** CHECK FOR outcome BEEING BINARY **
			_checkbinvar `outcome' `iff' `in' [`l1sweight' `eqs' `exp']
			if "`r(checkbin)'" != "binary" {
				di as error "{p 0 2 2 `ls'}{bf: `outcome'} not binary{p_end}"
				exit 2000
			}
			** NEW: Terza (2023) ***********************************************************			
			** MANAGE OPTION TERZA **
			if (`terza' != 2023) & (`terza' != 2017) {
				di as error "{p 0 2 2 `ls'}option {bf:terza()} incorrectly specified; only 2017 and 2023 allowed{p_end}"
				exit 198
			}
			********************************************************************************
			** MANAGE OPTION LINK **
			if "`link'" != "logit" & "`link'" != "probit" & "`link'" != "cloglog" {
				di as error "{p 0 2 2 `ls'}link function {bf:`link'} not allowed{p_end}"
				exit 198
			}
			** MANAGE OPTION FSLINK **
			if "`fslink'" == "" {
				local fslink "logit"
			}
			else {
				if "`fslink'" != "linear" & "`fslink'" != "logit" & "`fslink'" != "probit" {
					di as error "{p 0 2 2 `ls'}first-stage link function {bf:`fslink'} not allowed{p_end}"
					exit 198
				}
			}
			** NEW: Terza (2023) ***********************************************************			
			** MANAGE OPTION noANALYTIC **
			if `terza' == 2017 {
				local analytic ""
			}
			/*
			if "`link'" != "logit" & "`analytic'" != "noanalytic" {
				local analytic "noanalytic"
				noi di as text "{p 0 2 2 `ls'}analytical cross-stage derivatives only available for link {bf:logit}; switched to {bf:noanalytic}{p_end}"
			}
			*/
			if "`fslink'" == "probit" & "`analytic'" != "noanalytic" {
				local analytic "noanalytic"
				noi di as text "{p 0 2 2 `ls'}analytical cross-stage derivatives not available with first-stage link {bf:probit}; switched to {bf:noanalytic}{p_end}"
			}
			if `order' > 1 & "`analytic'" != "noanalytic" {
				local analytic "noanalytic"
				noi di as text "{p 0 2 2 `ls'}analytical cross-stage derivatives not available with with {bf:order > 1}; switched to {bf:noanalytic}{p_end}"
			}
			*******************************************************************************
            ** MAMAGE ERRORANEOUSLY SPECIFYING vce(bootstrap) **
            gettoken vceboot : vce, parse(",")
            local vceboot : list retokenize vceboot
            if "`vceboot'" == "bootstrap" | "`vceboot'" == "bootstra" | "`vceboot'" == "bootstr" | "`vceboot'" == "bootst" | "`vceboot'" == "boots" | "`vceboot'" == "boot" {
				noi display as error "{p 0 2 2 `ls'}vcetype {bf:`vce'} not allowed, use prefix command bootstrap{p_end}"
				exit 198            
            }
			** DEFAULT VCE **
			if ("`vce'" == "") & ("`robust'" == "") & ("`cluster'" == "") {
				local vce "oim"
			}
			** MANAGE OPTIONS ROBUST and CLUSTER **
			if "`robust'" == "r" | "`robust'" == "ro" | "`robust'" == "rob" | "`robust'" == "robu" | "`robust'" == "robus" | "`robust'" == "robust" {
				local vce "robust"
			}
			if "`cluster'" != "" {
				local vce "cluster `cluster'"
			}
			local vce : list retokenize local(vce)
			tokenize "`vce'"
			if "`1'" == "robust" | "`1'" == "robus" | "`1'" == "robu" | "`1'" == "rob" | "`1'" == "ro" | "`1'" == "r" {
				local vce "robust"
			}
			if "`1'" == "cluster" | "`1'" == "cluste" | "`1'" == "clust" | "`1'" == "clus" | "`1'" == "clu" | "`1'" == "cl" {
				local clustvar "`2'"
				local vce "cluster `clustvar'"
			}
			if "`clustvar'" == "" {
				local suestclust "`_id'"
			}
			else {
				local suestclust "`clustvar'"
			}
			** MANAGE OPTION VCE **
			tokenize "`vce'"
			if ("`1'" != "cluster") & ("`1'" != "robust") & ("`1'" != "opg") & ("`1'" != "oim") {				
				di as error "{p 0 2 2 `ls'}vcetype {bf: `1'} not allowed{p_end}"
				exit 198
			}
			** MANAGE OPTION RESNAME **
			if "`resname'" == "" {
				local resname "res"
			}
			** MANAGE OPTION ORDER **
			if `order' < 1 {
				di as error "{p 0 2 2 `ls'}option {bf:order()} incorrectly specified; only integer >= 1 allowed{p_end}"
				exit 198
			}
			** GENERATE TEMPORARY COMSTANT **
			gen byte `_one' = 1
			gen double `_id' =_n
			** EVALUATE REDUCED-FORM-MODEL TO ALIGN ESTIMATION SAPMPLES BETWEEN STAGES **
			cap `link' `outcome' `endog' `controls' `ivset' `iff' `in' [`2sweight' `eqs' `exp'], iterate(0) /*
			*/ vce(`vce') `difficult' `technique' `tolerance' `ltolerance' `nrtolerance' `nonrtolerance' `nonrtolerance' `from'
			if _rc != 0 {
				di as error "{p 0 2 2 `ls'}reduced-form model ill-defined; check model specification{p_end}"
			}			
			gen byte `_touse' = e(sample)
			local iff "if (`_touse' == 1)"
			** CHECK FOR COMPLETE AND QUASI-COMPLETE SEPARATION **
			cap _rmdcoll `outcome' `endog' `controls' `iff' `in' [`2sweight' `eqs' `exp'] 
			if _rc != 0 {
				di as error "{p 0 2 2 `ls'}complete separation, {bf: `outcome'} perfectly explained; check model specification{p_end}"
				exit 2000
			}
			cap _rmdcoll `outcome' `controls' `ivset' `iff' `in' [`2sweight' `eqs' `exp'] 
			if _rc != 0 {
				di as error "{p 0 2 2 `ls'}complete separation, {bf: `outcome'} perfectly explained by instruments{p_end}"
				exit 2000
			}
			cap _rmcoll `endog' `controls' `iff' `in' [`2sweight' `eqs' `exp'], expand 
			local orgvarl "`r(varlist)'" 
			foreach yy in `miny' `maxy' {
				if `yy' == `miny' {
					local yya = `maxy'
				}
				else {
					local yya = `miny'
				}
				cap _rmcoll `endog' `controls' `iff' & `outcome' == `yy' `in' [`2sweight' `eqs' `exp'], expand  
				local subvarl "`r(varlist)'"
				if "`subvarl'" != "`orgvarl'" {
					di as error "{p 0 2 2 `ls'}quasi-complete separation, {bf: `outcome' = `yya'} perfectly predited; check model specification{p_end}"
					exit 2000
				} 
			}
			cap _rmcoll `controls' `ivset' `iff' `in' [`2sweight' `eqs' `exp'], expand 
			local orgvarl "`r(varlist)'" 
			foreach yy in `miny' `maxy' {
				if `yy' == `miny' {
					local yya = `maxy'
				}
				else {
					local yya = `miny'
				}
				cap _rmcoll `controls' `ivset' `iff' & `outcome' == `yy' `in' [`2sweight' `eqs' `exp'], expand 
				local subvarl "`r(varlist)'" 
				if "`subvarl'" != "`orgvarl'" {
					di as error "{p 0 2 2 `ls'}quasi-complete separation, {bf: `outcome' = `yya'} perfectly predicted by instruments{p_end}"
					exit 2000
				}
			}
			** CHECK FOR FACTOR VARIABLES IN endog **
			fvexpand `endog'
			local expaenames "`r(varlist)'"
			tokenize `expaenames'
			fvrevar `endog'
			local expaendog "`r(varlist)'"
			_rmcoll `expaendog' `iff' `in' [`l1sweight' `eqs' `exp']
			local flagexpaendog "`r(varlist)'"
			if `r(k_omitted)' > 0 {
				local cc = 0
				foreach ee in `flagexpaendog' {
					local cc = `cc'+1
					if  ustrrpos("`ee'","o.") != 0  {
						local nof = ustrregexrf("`ee'","o.","")
						local expaendog : list local(expaendog) - local(nof)
						local expaenames : list local(expaenames) - local(`cc')
					}
				}
			}
			local stexpaenames ""
			foreach ee in `expaenames' {
				local stname = ustrtoname("`ee'",0)
				local stexpaenames "`stexpaenames' `stname'"
			}
			tokenize `stexpaenames'
			** ESTIMATE FIRST-STAGE AND SAVED (GENERALIZED) RESIDUALS **
			local EstXTD ""
			local ResXTD ""
			local DerivXTD ""
			local fsswitched ""
			local rescount = 0
			local perfectcount = 0	
			local fscount = 1
			** NEW: Version Terza 2023 numeric *********************************************			
			if `terza' == 2023 & "`analytic'" == "noanalytic" {
				global cfll ""	
				global cflist ""
				local omit1s = 0
			}
			********************************************************************************					
			foreach ee of varlist `expaendog' {	
				local fsfail = 1
				local fsperfect = 1
				local switchindi = 0
				if "`fslink'" == "linear" {
					cap regress `ee' `controls' `ivset' `iff' `in' [`l1sweight' `eqs' `exp']
					if _rc == 0  {
						local fsfail = 0
						if  `e(r2)' != 1 {
							local fsperfect = 0
						}
					}
				}
				else {
					** CHECK FOR BINARY ENDOGENEOUS REGRESSORS **
					_checkbinvar `ee' `iff' `in' [`l1sweight' `eqs' `exp']
					local checkbin "`r(checkbin)'"
					if "`checkbin'" != "binary" {	
						cap regress `ee' `controls' `ivset' `iff' `in' [`l1sweight' `eqs' `exp']				
						if _rc == 0  {
							local fsfail = 0
							if  `e(r2)' != 1 {
								local fsperfect = 0
							}
						}
					}
					else {
						** CHECK FOR QUASI-COMPLETE SEPARATION **
						local mine = r(min)
						local maxe = r(max)
						cap _rmcoll `controls' `ivset' `iff' `in' [`l1sweight' `eqs' `exp'], expand 
						local orgvarl "`r(varlist)'" 
						local countqcs = 0
						foreach yy in `mine' `maxe' {
							cap _rmcoll `controls' `ivset' `iff' & (`ee' == `yy') `in' [`l1sweight' `eqs' `exp'], expand 
							local subvarl "`r(varlist)'" 
							if "`subvarl'" != "`orgvarl'" {
								local countqcs = `countqcs' +1
							}
						}					
						if `countqcs' != 0 {
							if "`fsswitch'" != "fsswitch" {
								di as error "{p 0 2 2 `ls'}quasi-complete separation in first-stage, consider sypecifying option {bf:fsswitch}{p_end}"
								exit 2000
							}
							else {
								cap regress `ee' `controls' `ivset' `iff' `in' [`l1sweight' `eqs' `exp']							
								local switchindi = 1
								local fsswitched "`fsswitched' ``fscount''"
								local fsswitched : list retokenize local(fsswitched) 
								if _rc == 0  {
									local fsfail = 0
									if  `e(r2)' != 1 {
										local fsperfect = 0
									}
								}
							}
						}
						else {
							cap `fslink' `ee' `controls' `ivset' `iff' `in' [`l1sweight' `eqs' `exp']						
							if _rc == 0 {
								local fsfail = 0
								local fsperfect = 0
							}
							if e(rules)[1,4] > 0 {
								if "`fsswitch'" != "fsswitch" {
									di as error "{p 0 2 2 `ls'}quasi-complete separation in first-stage, consider sypecifying option {bf:fsswitch}{p_end}"
									exit 2000
								}
								else {
									cap regress `ee' `controls' `ivset' `iff' `in' [`l1sweight' `eqs' `exp']							
									local switchindi = 1
									local fsswitched "`fsswitched' ``fscount''"
									local fsswitched : list retokenize local(fsswitched) 
									if _rc == 0  {
										local fsfail = 0
										if  `e(r2)' != 1 {
											local fsperfect = 0
										}
									}
								}								
							}
						}
					}
				}
				if `fsfail' == 0 {
					cap confirm matrix `_G'
					if _rc != 0 {
						mat `_G' = e(b)
					}
					else {
						mat `_G' = (`_G' \ e(b))
					}
				}
				cap drop `_tmpres'
				if `fsfail' == 0 & `fsperfect' == 0 {
					cap predict `_tmpres' if e(sample), score			
				}
				else {
					gen byte `_tmpres' = 0
				}			
				cap _rmdcoll `_tmpres' `endog' `controls' `ResXTD' `iff' `in' [`2sweight' `eqs' `exp']
				if _rc != 0 {
					local perfectcount = `perfectcount'+ 1
					local perfect "`perfect' ``fscount''"
					local perfect : list retokenize local(perfect)
				}
				else {
					local rescount = `rescount'+1
					estimates store fs_`rescount'
					local EstXTD "`EstXTD' fs_`rescount'"
					** NEW: Version Terza 2023 numeric *********************************************
					** SAVE INFORMATION ON OMITTED VARS IN FIRST-STAGE **
					if `terza' == 2023 & "`analytic'" == "noanalytic" {					
						_ms_omit_info e(b)
						if r(k_omit) >0 {
							local omit1s = 1
						}
						local komit = r(k_omit)
						matrix `_omit' = r(omit)
						local omitind = `omitind' + `komit'
						tempname _T`rescount' _a`rescount' _C`rescount'
						if `r(k_omit)' > 0 {
							makecns
							matcproc `_T`rescount'' `_a`rescount'' `_C`rescount''
						}
						else {
							matrix `_T`rescount'' = I(colsof(e(b)))
							matrix `_a`rescount'' = J(1,colsof(e(b)),0)
						}
						if `rescount' == 1 {
							local ffscoef = 1
							local lfscoef = colsof(e(b)) - `komit'

						}
						else {
							local ffscoef = `lfscoef'+ 1
							local lfscoef = `lfscoef'+ (colsof(e(b)) - `komit')
						}
					}
					********************************************************************************
					forvalues oo = 1(1)`order' {
						local ncfcoef = (`rescount'-1)*`order'+ `oo'
						if "`resgenerate'" == "noresgenerate" {
							tempvar _ResXTD_`fscount'_`oo'
							if `oo' == 1 {
								rename `_tmpres' `_ResXTD_`fscount'_`oo''
							}
							else {
								gen double `_ResXTD_`fscount'_`oo'' = (`_ResXTD_`fscount'_1')^(`oo')
							}
							local ResXTD "`ResXTD' `_ResXTD_`fscount'_`oo''"
						}
						else {
							if "`replace'" == "replace" {
								if `oo' == 1 {
									cap drop `resname'_``fscount''
								}
								else {
									cap drop `resname'`oo'_``fscount''
								}
							}
							if `oo' == 1 {
								rename `_tmpres' `resname'_``fscount''
								local ResXTD "`ResXTD' `resname'_``fscount''"
							}
							else {
								gen double  `resname'`oo'_``fscount'' = (`resname'_``fscount'')^(`oo')
								local ResXTD "`ResXTD' `resname'`oo'_``fscount''"
							}
						} 
						tempvar _PDS_`rescount'_`oo'
						if "`fslink'" == "linear" | "`checkbin'" != "binary" | `switchindi' == 1 {
							if `oo' == 1 {
								gen byte `_PDS_`rescount'_`oo'' = 1
							}
							else {
								if "`resgenerate'" == "noresgenerate" {
									gen double `_PDS_`rescount'_`oo'' = `oo'*(`_ResXTD_`fscount'_1')^(`oo'-1)
								}
								else {
									gen `_PDS_`rescount'_`oo'' = `oo'*(`resname'_``fscount'')^(`oo'-1)
								}
							}
							** NEW: Version Terza (2023) ***************************************************
							** STORE INFORMATION FOR BUILDING EVALUATOR FUNCTION IN GLOBAL MACROS **
							if `terza' == 2023 & "`analytic'" == "noanalytic" {
								global cflist "${cflist} ; cf`fscount'`oo' = _betacoefsres[`ncfcoef'] :* ((_XVARS[.,`fscount'] :- _EXOGVARS*st_matrix("`_T`rescount''")*_alfacoefs[`ffscoef'::`lfscoef']')) :^`oo'"
								global cfll "${cfll} :+ cf`fscount'`oo'"
							}
							********************************************************************************							
						}
						else {
							if `oo' == 1 {
								tempvar _PDS_`rescount'
								cap predict `_PDS_`rescount'' if e(sample), xb 
							}
							if "`fslink'" == "logit" {
								if "`resgenerate'" == "noresgenerate" {
									gen double `_PDS_`rescount'_`oo'' = `oo'*(`_ResXTD_`fscount'_1')^(`oo'-1)*logisticden(`_PDS_`rescount'')
								}
								else {
									gen double `_PDS_`rescount'_`oo'' = `oo'*(`resname'_``fscount'')^(`oo'-1)*logisticden(`_PDS_`rescount'')
								}
								** NEW: Version Terza (2023) ***************************************************
								** STORE INFORMATION FOR BUILDING EVALUATOR FUNCTION IN GLOBAL MACROS **
								if `terza' == 2023 & "`analytic'" == "noanalytic" {
									global cflist "${cflist} ; cf`fscount'`oo' = _betacoefsres[`ncfcoef'] :* ((_XVARS[.,`fscount'] :- logistic(_EXOGVARS*st_matrix("`_T`rescount''")*_alfacoefs[`ffscoef'::`lfscoef']'))) :^`oo'"
									global cfll "${cfll} :+ cf`fscount'`oo'"
								}
								********************************************************************************	
							}
							if "`fslink'" == "probit" {
								if "`resgenerate'" == "noresgenerate" {
									gen double `_PDS_`rescount'_`oo'' = `oo'*(`_ResXTD_`fscount'_1')^(`oo'-1)* /*
									*/ `_PDS_`rescount''*normalden(`_PDS_`rescount'')/normal(`_PDS_`rescount'')    +(normalden(`_PDS_`rescount'')/normal(`_PDS_`rescount''))^2 if `ee' != 0
									cap replace `_PDS_`rescount'_`oo'' = `oo'*(`_ResXTD_`fscount'_1')^(`oo'-1)* /*
									*/ `_PDS_`rescount''*normalden(`_PDS_`rescount'')/(1-normal(`_PDS_`rescount''))-(normalden(`_PDS_`rescount'')/(1-normal(`_PDS_`rescount'')))^2 if `ee' == 0
								}
								else {
									gen double `_PDS_`rescount'_`oo'' = `oo'*(`resname'_``fscount'')^(`oo'-1)* /*
									*/ `_PDS_`rescount''*normalden(`_PDS_`rescount'')/normal(`_PDS_`rescount'')    +(normalden(`_PDS_`rescount'')/normal(`_PDS_`rescount''))^2 if `ee' != 0
									cap replace `_PDS_`rescount'_`oo'' = `oo'*(`resname'_``fscount'')^(`oo'-1)* /*
									*/ `_PDS_`rescount''*normalden(`_PDS_`rescount'')/(1-normal(`_PDS_`rescount''))-(normalden(`_PDS_`rescount'')/(1-normal(`_PDS_`rescount'')))^2 if `ee' == 0									
								}
								** NEW: Version Terza (2023) ***************************************************
								** STORE INFORMATION FOR BUILDING EVALUATOR FUNCTION IN GLOBAL MACROS **
								if `terza' == 2023 & "`analytic'" == "noanalytic" {
									global cflist "${cflist} ; cf`fscount'`oo' = _betacoefsres[`ncfcoef'] :* ((_XVARS[.,`fscount'] :- normal(_EXOGVARS*st_matrix("`_T`rescount''")*_alfacoefs[`ffscoef'::`lfscoef']')) :* normalden(_EXOGVARS*st_matrix("`_T`rescount''")*_alfacoefs[`ffscoef'::`lfscoef']') :/ (normal(_EXOGVARS*st_matrix("`_T`rescount''")*_alfacoefs[`ffscoef'::`lfscoef']') :* normal(-1 :* _EXOGVARS*st_matrix("`_T`rescount''")*_alfacoefs[`ffscoef'::`lfscoef']'))) :^`oo'"
									global cfll "${cfll} :+ cf`fscount'`oo'"
								}
								********************************************************************************
							}
						}
						local DerivXTD "`DerivXTD' `_PDS_`rescount'_`oo''"
					}
				}
				local fscount = `fscount'+ 1				
			}
			** CHECK FOR SUFFICIENT NUMBER OF (NON-COLLINEAR) INSTRUMENTs **
			_rmcoll `endog' `controls' `iff' `in' [`2sweight' `eqs' `exp']
			local orgomitted = r(k_omitted) 
			_rmcoll `endog' `controls' `ResXTD' `iff' `in' [`2sweight' `eqs' `exp']
			local instomitted = r(k_omitted) 			
			if (`instomitted'-`perfectcount') > `orgomitted' {
				cap drop `ResXTD'
				di as error "{p 0 2 2 `ls'}equation not identified; too few (non-collinear) instruments{p_end}"
				exit 481
			}
			// Step 1.2: Retrieve the estimated coefficients and covariance matrix
			if "`EstXTD'" == "" & "`ResXTD'" == "" {
				di as error "{p 0 2 2 `ls'}all first-stage residuals collinear with rhs vars{p_end}"
				exit 481
			}		
			cap suest `EstXTD', vce(cluster `suestclust')
			local _rcsuest = _rc
			cap matrix `_checkvfs' = trace(e(V))
			if `_rcsuest' !=0 | _rc !=0 | `_checkvfs'[1,1] == 0 | `_checkvfs'[1,1] ==. {
				cap estimates drop `EstXTD'
				di as error "{p 0 2 2 `ls'}calculation of first-stage covariance matrix failed{p_end}"
				exit 2000        
			}
			cap estimates drop `EstXTD'			
			local suestbn : colfullnames e(b)
			local suestnb : colsof e(b)
			matrix `_bfs'= e(b)
			matrix `_Vfs'= e(V)		
			// Step 1.3: `_alphaxtd' and `_Valphaxtd' is reduced (deleted EstXTD_endog_lnvar _cons)
			** Create a list of varlists ivset and controls
			local count_ivc = 0
			local tokeep ""
			** Loop through the varlists and calculate the number of elements in each
			foreach cc in `suestbn' {
				local count_ivc = `count_ivc'+1
				local checkcoef = ustrrpos("`cc'","lnvar:")
				if `checkcoef' != 0 {
					matrix `_bfs'[1,`count_ivc'] =.
					forvalues ee = 1/`suestnb' {
						matrix `_Vfs'[`ee',`count_ivc'] =.
						matrix `_Vfs'[`count_ivc',`ee'] =.
					}
				}	
			}		
			mata : delete_missing("`_bfs'", "`_Vfs'", "`_bfs'", "`_Vfs'")
			mata : `_alphaxtd' = st_matrix("`_bfs'") // vector of first stage coefficients
			mata : `_Valphaxtd' = st_matrix("`_Vfs'") // corresponding covariance matrix		
			// Step 2: Estimate the final model 
			cap `link' `outcome' `endog' `controls' `ResXTD' `iff' `in' [`2sweight' `eqs' `exp'], vce(`vce') /*
			*/ `difficult' `technique' `iterate' `tolerance' `ltolerance' `nrtolerance' `nonrtolerance' `nonrtolerance' `from'	
			if _rc != 0 {
				mata : mata drop `_alphaxtd' `_Valphaxtd' 
				di as error "{p 0 2 2 `ls'}estimation of second-stage model failed{p_end}"
				exit 430
			}
			** CHECK FOR PERFECT PREDICTIONS **
			predict `_2spr' if e(sample), pr
			count if `_2spr' == 0 & `outcome' == 0
			local n0 = r(N)
			count if `_2spr' == 1 & `outcome' == 1
			local n1 = r(N)
			if `n0' > 0 | `n1' > 0 {
				noi di as text "{p 0 2 2 `ls'}note: `n0' failures and `n1' successes completely determined; variance estimation may fail{p_end}"
			}
			** STORE SOME RESLTS FROM 2ND STAGE **		
			local cn : colnames e(b)
			local 2sbn : colfullnames e(b)	
			local 2sbcols = colsof(e(b))
			local _N = e(N)
			local ll = e(ll)
			if "`clustvar'" != "" {
				local N_clust = e(N_clust)
			}
			gen byte `_esample' = 1 if e(sample)
			replace `_esample' = 0 if `_esample' != 1
			predict `_score2s' if e(sample), score
			** NEW: Terza (2023) ***********************************************************
			if `terza' == 2023 & "`analytic'" != "noanalytic" & "`link'" != "logit" { 
				predict `_xb2s' if e(sample), xb
			}
			if `terza' == 2023 & "`analytic'" == "noanalytic" {
				_ms_omit_info e(b)
				if `r(k_omit)' > 0 {
					local omit2s = 1
					makecns 
					tempname _T2s _as2 _C2s
					matcproc `_T2s' `_as2' `_C2s'
				}
				else {
					local omit2s = 0
				}
			}
			********************************************************************************
			** CLEAN VARLISTS OF BASE-LEVELS AND OMITTET VARS (just for reporting) **
			_exclubaom `endog' if e(sample)
			local cleanendog "`r(varlist)'"
			local cleanendog : list uniq local(cleanendog)
			_exclubaom `controls' `ivset' if e(sample) [`2sweight' `eqs' `exp']
			local cleanexog "`r(varlist)'"
			local cleanexog : list uniq local(cleanexog)
			_exclubaom `ivset' if e(sample) [`2sweight' `eqs' `exp']
			local cleaninstru "`r(varlist)'"
			local cleaninstru : list uniq local(cleaninstru)
			if "`resgenerate'" != "noresgenerate" {
				_exclubaom `ResXTD' if e(sample) [`2sweight' `eqs' `exp']
				local cleanResXTD "`r(varlist)'"
			}
			** DERIVE WEIGHTS FOR MATRIX OPERATIONS **
			if "`exp'" != "" {
				gen double `_tempweight' = `exp' if e(sample)
				sum `_tempweight'
				local wgtsum = r(sum)
				replace `_tempweight' = (r(N)/r(sum))*`_tempweight' if e(sample) 
				if "`weight'" == "iweight" {
					local iwcorrect = r(sum)/r(N)
				}
				else {
					local iwcorrect = 1
				}
			} 
			else {
				gen byte `_tempweight' = 1 if e(sample)
				local iwcorrect = 1
			}
			mata : `_betaxtd' = st_matrix("e(b)") // vector of second stage coefficients			
			mata : `_Vbetaxtd' = `iwcorrect'*st_matrix("e(V)") // corresponding covariance matrix	
			** EXTRACT COEFFICIENTS OF RESIDUALS **	
			local corrsf = `2sbcols'-`rescount'*`order'
			local corrsl = `2sbcols'-1		
			mata : `_Bu' = `_betaxtd'[|1,`corrsf' \ 1,`corrsl'|]
			** TRANSFER DATA TO MATA **
			mata : `_WVEC' = st_data(.,("`_tempweight'"),"`_esample'")
			// Step 3.2: Calculate matrices `_X', `_W'
			fvrevar `endog' `controls' `ResXTD' `iff' `in'
			mata : `_X' = st_data(.,("`r(varlist)' `_one'"),"`_esample'")
			// CREATE MATRIX  `_DER'  
			mata : `_DER' = st_data(.,("`DerivXTD'"),"`_esample'")				
			// Step 3.3: Calculate `_Bbeta' and `_Balpha'
			mata : `_SCORE' = st_data(.,("`_score2s'"),"`_esample'")
			fvrevar  `controls' `ivset' `iff' `in'
			mata : `_W' = st_data(.,("`r(varlist)' `_one'"),"`_esample'") 
			** BUILD MATRICES FOR DETERMINING COVARIANCE MATRIX
			mata : `_Bbeta' = (`_WVEC':^0.5):*(`_SCORE':*`_X')			
			mata : `_BW' = -(((`_Bu':*`_DER')*(I(`rescount')#J(`order',1,1)))#J(1,cols(`_W'),1)):*(J(1,`rescount',1)#`_W')		
			mata : `_Balpha' = (`_WVEC':^0.5):*(`_SCORE':*`_BW')
			// Step 3.4: Get Assymptotic Covariance Matrix, assymptotic se, vector of asymptotic t statistics
			if `terza' == 2017 {	
				mata : `_EACCM' = `_Vbetaxtd' * (`_Bbeta''*`_Balpha') * `_Valphaxtd' * (`_Bbeta''*`_Balpha')' * `_Vbetaxtd' + `_Vbetaxtd' // assymptotic covariance matrix
			}
			** NEW Terza (2023) ************************************************************************
			** ANALYTIC VARIANCE-COVARIANCE MATRIX FOR Terza (2023) **
			if `terza' == 2023 & "`analytic'" != "noanalytic" {
				tempvar _derivgenres2s
				tempname _DGENR2S _CROSSALFABETA dgenres2s
				if "`link'" == "logit" {
					gen double `_derivgenres2s' = (`outcome'-`_score2s')^2*((`outcome'-`_score2s')^(-1)-1) if `_esample' == 1
					** gen double `_derivgenres2s' = logisticden(`_xb2s') if `_esample' == 1
					replace `_derivgenres2s' = 0 if (`_derivgenres2s' ==. & `_esample' == 1 & (((`_2spr' > 1-`edtzero' & `_2spr' <.) & `outcome' == 1) | (`_2spr' < `edtzero' & `outcome' == 0))) 
				}
				if "`link'" == "probit" {
					gen double `_derivgenres2s' = `outcome'*(-`_xb2s'*normalden(`_xb2s')/normal(`_xb2s')    - (normalden(`_xb2s')/normal(`_xb2s'))^2) /*
					                     */  -(1-`outcome')*(-`_xb2s'*normalden(`_xb2s')/(1-normal(`_xb2s'))+ (normalden(`_xb2s')/(1-normal(`_xb2s')))^2) /*
										 */ if `_esample' == 1
					replace `_derivgenres2s' = 0 if (`_derivgenres2s' ==. & `_esample' == 1 & (((`_2spr' > 1-`edtzero' & `_2spr' <.) & `outcome' == 1) | (`_2spr' < `edtzero' & `outcome' == 0)))
				}
				if "`link'" == "cloglog" {
					gen double `_derivgenres2s' = `outcome'*(exp(`_xb2s'-exp(`_xb2s'))*(1-exp(`_xb2s')))/(1-exp(-exp(`_xb2s'))) /*
										    */   -`outcome'*((exp(`_xb2s'-exp(`_xb2s'))/(1-exp(-exp(`_xb2s'))))^2) /*
										  */ -(1-`outcome')*(exp(`_xb2s'-exp(`_xb2s'))*(1-exp(`_xb2s')))/(exp(-exp(`_xb2s'))) /*
										  */ -(1-`outcome')*((exp(`_xb2s'-exp(`_xb2s'))/(exp(-exp(`_xb2s'))))^2)  /*
										  */ if `_esample' == 1
					replace `_derivgenres2s' = 0 if (`_derivgenres2s' ==. & `_esample' == 1 & (((`_2spr' > 1-`edtzero' & `_2spr' <.) & `outcome' == 1) | (`_2spr' < `edtzero' & `outcome' == 0)))
				}
				mata : `_DGENR2S' = st_data(., ("`_derivgenres2s'"),0)
                ** CHECK FOR DERIVS OF 2ND-STAGE GENERALIZED RESIDUALS FOR FULL ESTIMATION SAMPLE **
                mata : st_numscalar("`dgenres2s'",rows(`_WVEC') - rows(`_DGENR2S')) 
				if `dgenres2s' != 0 {
					local dgr2serror = `dgenres2s'
					mata : mata drop `_alphaxtd' `_betaxtd' `_Bbeta' `_Balpha' `_Valphaxtd' `_Vbetaxtd' `_W' `_X' `_Bu' `_BW' `_SCORE' `_WVEC' `_DER' `_DGENR2S'
					noi di as error "{p 0 2 2 `ls'}cannot determine derivs of 2nd-stage generalized residuals for `dgr2serror' obs; consider specifying {bf:noanalytic}{p_end}"
					exit 416
				}			
                ** DETERMINE MATRIX OF CORSS-STAGE DERIVATIVES OF PSEUDO-LOG-LIKELIHOOD FUNCTION ANALYTICALLY **
				mata : `_CROSSALFABETA' = ((`_DGENR2S'#J(1,cols(`_X'),1)):*`_X')'diag(`_WVEC')*(((`_Bu')#(J(rows(`_X'),cols(`_W'),1))):*((`_DER')#J(1,cols(`_W'),1)):*(J(1,cols(`_Bu'),1)#`_W'))- /*
				*/ (J(rows(`_X'),(cols(`_X')-cols(`_Bu')-1),0),J(rows(`_X'),cols(`_Bu'),1),J(rows(`_X'),1,0))'diag(`_WVEC')*((((`_SCORE'#J(1,cols(`_Bu'),1)):*`_DER')#J(1,cols(`_W'),1)):*(J(1,cols(`_Bu'),1)#`_W')):* /*
				*/(J(cols(`_X')-cols(`_Bu')-1,cols(`_Bu'),0) \ I(cols(`_Bu')) \ J(1,cols(`_Bu'),0))#J(1,cols(`_W'),1)
				mata : `_EACCM' = `_Vbetaxtd' * (`_CROSSALFABETA') * `_Valphaxtd' * (`_CROSSALFABETA'') * `_Vbetaxtd'' + `_Vbetaxtd' * (`_Bbeta''*`_Bbeta') * `_Vbetaxtd'  /* assymptotic covariance matrix Terza (2023) */ 
				mata : mata drop `_DGENR2S' `_CROSSALFABETA'
			}
			** NUMERIC VARIANCE-COVARIANCE MATRIX FOR Terza (2023) **
			if `terza' == 2023 & "`analytic'" == "noanalytic" {
				** Call _llcfbin_v.do to build Evaluator Function for deriv() **
				cap findfile _llcfbin_v.do 
				if "`r(fn)'" == "" {
					di as error "{p 0 2 2 `ls'}{bf:_llcfbin_v.do} not found; save _llcfbin_v.do in adopath, or switch to {bf:analytic}, or specify {bf:terza(2017)}{p_end}"
					mata : mata drop `_betaxtd' `_Vbetaxtd' `_WVEC' `_Bu' `_X' `_W' `_DER' `_SCORE' `_Bbeta' `_BW' `_Balpha' `_EACCM' `_alphaxtd' `_Valphaxtd'
					exit 601
				}				
				else {
					run `r(fn)'
				}
				** GENERATE ARGUMENTS TO BE PASSED TO deriv() **
				tempname _Y _OX _allxtd _TO2s _tb0 _TO1s _as1 _ta0 _TALL _CROSSDEV _CROSSBETA _CROSSALFABETA _D _checknumd _checksym _checkzero _SCORES _DERIV
				mata : `_Y' =  st_data(.,("`outcome'"),"`_esample'")
				fvrevar `endog' `controls' `iff' `in'
				mata : `_OX' = st_data(.,("`r(varlist)' `_one'"),"`_esample'")
				if `omit2s' == 1 {
					mata : `_TO2s' = st_matrix("`_T2s'")[|1,1 \ rows(st_matrix("`_T2s'"))-cols(`_Bu')-1,cols(st_matrix("`_T2s'"))-cols(`_Bu')-1|]
					mata : `_TO2s' = (`_TO2s', J(rows(`_TO2s'),1,0) \ J(1,cols(`_TO2s'),0),1)
					mata : `_OX' = `_OX'*`_TO2s' 	
					mata : `_tb0' = (`_betaxtd' :- st_matrix("`_as2'"))*st_matrix("`_T2s'")
				}
				if `omit1s' == 1 { 
					forvalues ff = 1(1)`rescount' {
						if `ff' == 1 {
							mata : `_TO1s' = st_matrix("`_T1'")
							mata : `_as1' = st_matrix("`_a1'")
						}
						else {
							mata : `_TO1s' = (`_TO1s' , J(rows(`_TO1s'),cols(st_matrix("`_T`ff''")),0) \ J(rows(st_matrix("`_T`ff''")),cols(`_TO1s'),0), st_matrix("`_T`ff''"))
							mata : `_as1' = (`_as1', st_matrix("`_a`ff''"))
						}
					}
					mata : `_ta0' = (`_alphaxtd' :- `_as1')*`_TO1s'
				}
				if `omit2s' == 0 & `omit1s' == 0 {
					mata : `_allxtd' = (`_betaxtd', `_alphaxtd') 
					mata : `_TALL' = I(cols(`_allxtd'))
				}
				if `omit2s' == 1 & `omit1s' == 0 {
					mata : `_allxtd' = (`_tb0', `_alphaxtd')
					mata : `_TALL' = (st_matrix("`_T2s'"),J(rows(st_matrix("`_T2s'")),cols(`_alphaxtd'),0) \ J(cols(`_alphaxtd'),cols(st_matrix("`_T2s'")),0), I(cols(`_alphaxtd')))
				}
				if `omit2s' == 0 & `omit1s' == 1 {
					mata : `_allxtd' = (`_betaxtd',`_ta0')
					mata : `_TALL' = (I(cols(`_betaxtd')),J(cols(`_betaxtd'),cols(`_TO1s'),0) \ J(rows(`_TO1s'),cols(`_betaxtd'),0), `_TO1s')
				}
				if `omit2s' == 1 & `omit1s' == 1 {
					mata : `_allxtd' = (`_tb0',`_ta0')
					mata : `_TALL' = (st_matrix("`_T2s'"),J(rows(st_matrix("`_T2s'")),cols(`_TO1s'),0) \ J(rows(`_TO1s'),cols(st_matrix("`_T2s'")),0), `_TO1s')
				}
				** CALL deriv() TO COMPUTE NUMERICAL CROSS_PARTIAL DERIVATIVES **
                cap {
    				mata : _D = deriv_init()
    				mata : deriv_init_evaluator(_D, &llcfbin_v())
    				mata : deriv_init_evaluatortype(_D, "v")
    				mata : deriv_init_params(_D, `_allxtd') /* full (first and scond stage) coefficient vector */
    				mata : deriv_init_weights(_D, `_WVEC') /* weights */
    				mata : deriv_init_argument(_D, 1, `_Y')  /* outcome variable */
    				mata : deriv_init_argument(_D, 2, `_W')  /* exogenous variables */
    				mata : deriv_init_argument(_D, 3, `_OX')  /* endogenous variables and controls */
    				mata : deriv_init_argument(_D, 4, `rescount')  /* number of first stage regressions */
    				mata : deriv_init_argument(_D, 5, `order')  /* order */
    				mata : deriv_init_argument(_D, 6, "`link'")  /* linkfunction */ 			
    				if "`search'" == "nosearch" {
    					mata : deriv_init_search(_D, "off")
    				}
					mata : `_DERIV' = deriv(_D, 2)
					if ("`vce'" != "oim" & "`vce'" != "opg") & "`sandwich'" != "nosandwich" {
						mata : `_SCORES' = deriv_result_scores(_D)
						mata : st_numscalar("`_checksym'",issymmetric(((`_SCORES')'(`_SCORES'))))
						mata : st_numscalar("`_checkzero'",diag0cnt(invsym((((`_SCORES')'(`_SCORES'))))))						
						if `_checksym' != 1 | `_checkzero' != 0 {
							noi di as text "{p 0 2 2 `ls'}note: OPG matrix invalid; sandwich estimator not used for cross-stage derivatives{p_end}"
							mata : `_CROSSDEV' = `_TALL'*`_DERIV'*`_TALL''
							local sandwich "nosandwich"
						}
						else {
							mata : `_CROSSDEV' = `_TALL'*`_DERIV'*(invsym(((`_SCORES')'(`_SCORES'))))*`_DERIV'*`_TALL''
							local sandwich "sandwich"
						}
						cap mata : mata drop `_SCORES'
					}
					else {
						** DETERMINE MATRIX OF CORSS-STAGE DERIVATIVES OF PSEUDO-LOG-LIKELIHOOD FUNCTION USING deriv() **
						mata : `_CROSSDEV' = `_TALL'*`_DERIV'*`_TALL''
					}
					cap mata : mata drop `_DERIV'
                    mata : st_numscalar("`_checknumd'",rows(`_CROSSDEV'))
                }
                cap confirm scalar `_checknumd'
                if _rc == 0 {
                    if `_checknumd' == 0 {
                        local emptycsd "1"
                    }
                }
                if _rc != 0 | "`emptycsd'" == "1" {
                    cap mata : mata drop `_alphaxtd' `_betaxtd' `_Bbeta' `_Balpha' `_Valphaxtd' `_Vbetaxtd' `_W' `_X' `_Bu' `_BW' `_SCORE' `_WVEC' `_DER'
                    cap mata : mata drop _D `_Y' `_OX' `_allxtd' `_TALL'
                    cap mata : mata drop `_CROSSDEV'  
                    cap mata : mata drop `_TO2s' `_tb0'
                    cap mata : mata drop `_TO1s' `_as1' `_ta0'
				    cap mata : mata drop llcfbin_v() llcfcloglog_v() llcflogit_v() llcfprobit_v()
                    cap macro drop cflist cfll
                    di as error "{p 0 2 2 `ls'}deriv() cannot compute cross-stage derivatives; consider specifying {bf:analytic} if available{p_end}"
                    exit 498
                }
				mata :  `_CROSSALFABETA' = `_CROSSDEV'[(1..cols(`_betaxtd')),(cols(`_betaxtd')+1::cols(`_CROSSDEV'))]
				mata : `_EACCM' = `_Vbetaxtd' * (`_CROSSALFABETA') * `_Valphaxtd' * (`_CROSSALFABETA'') * `_Vbetaxtd'' + `_Vbetaxtd' * (`_Bbeta''*`_Bbeta') * `_Vbetaxtd'  /* assymptotic covariance matrix Terza (2023) */
				** CLEAR Mata FROM MATRICES and POINTERS REQURED FOR CALLING deriv() **
                mata : mata drop _D `_Y' `_OX' `_allxtd' `_CROSSDEV' `_CROSSALFABETA' `_TALL' 
                ** CLEAR Mata FROM TEMP FUNCTIONS REQURED FOR CALLING deriv() **
				mata : mata drop llcfbin_v() llcfcloglog_v() llcflogit_v() llcfprobit_v()
				if `omit2s' == 1 {
					mata : mata drop `_TO2s' `_tb0'
				}	
				if `omit1s' == 1 {
					mata : mata drop `_TO1s' `_as1' `_ta0'
				}
				** CLEAR Stata FROM GLOBAL MACROS REQUIRED FOR BUILDING EVALUATOR FUNCTION **
				cap macro drop cflist cfll
			}
			********************************************************************************
			** STORING RESULTS IN Stata MATRICES **
			if "`resgenerate'" == "noresgenerate" {
				local coer = `corrsf'-1 
				local conr = `corrsl'+1 	
				mata : `_betaxtd' = `_betaxtd'[1,(1:: `coer' \ `conr' )]
				mata : `_EACCM' = `_EACCM'[(1:: `coer' \ `conr' ),(1:: `coer' \ `conr' )]
				tokenize `cn'
				forvalues nn = `corrsf'(1)`corrsl' {
					local cn : list local(cn) - local(`nn')
				}
			}
			mata : st_matrix("`_b'",`_betaxtd')
			mata : st_matrix("`_V'",`_EACCM')
			mata : mata drop `_alphaxtd' `_betaxtd' `_Bbeta' `_Balpha' `_Valphaxtd' `_Vbetaxtd' `_W' `_X' `_Bu' `_BW' `_SCORE' `_WVEC' `_EACCM' `_DER'				
			** RESET e(sample) **
			replace `_esample' = `_esample' == 1 
			** CHECK VALIDITY OF e(V) **
			matrix `_Vmissing' = matmissing(`_V')
			if `_Vmissing'[1,1] == 1 {
				di as error "{p 0 2 2 `ls'}estimated variance-covariance matrix incomplete/invalid{p_end}"
                exit 498
			}
			** ASSIGN ROW AND COLUMNNANES TO e(b) AND e(V) **
			matrix colnames `_b' = `cn'
			matrix rownames `_b' = `outcome'
			matrix colnames `_V' = `cn'
			matrix rownames `_V' = `cn'
			** STORE RESULTS IN e()
			ereturn repost b =`_b' V =`_V' [`2sweight' `eqs' `exp'], esample(`_esample') properties(b V) buildfvinfo findomitted resize
			** TEST JOINED SIGNIFICANCE AND EXOGENEITY OF REGRESSORS **
			testparm `endog' `controls'
			local chi2 = r(chi2)
			local df_m = r(df)
			local p = r(p)
			if "`resgenerate'" != "noresgenerate" {	
				testparm `ResXTD'
				local chi2_exog = r(chi2)
				local df_exog = r(df)
				local p_exog = r(p)
			}
			** MATRICES FOR e() **
			if "`fskeep'" == "fskeep" {
				ereturn matrix Vfs = `_Vfs'	
				ereturn matrix bfs = `_bfs'		
			}
			cap matrix rownames `_G' = `cleanendog'
			matrix coleq `_G' = ""
			ereturn matrix G = `_G'
			** SCALARS FOR e() **
			ereturn scalar N = `_N' 
			ereturn scalar ll = `ll'
			ereturn scalar chi2 = `chi2'
			ereturn scalar df_m = `df_m'
			ereturn scalar p = `p'
			ereturn scalar level = `level'
			ereturn scalar order = `order'
			if "`exp'" != "" { 
				ereturn scalar wgtsum = `wgtsum'
			}
			ereturn scalar k_perfect = `perfectcount'
			ereturn scalar k_eq_model = 1+ `rescount'
			ereturn scalar terza = `terza'
			** MACROS FOR e() **
			ereturn local link `link'
			ereturn local fslink `fslink'
			if ("`fsswitch'" == "fsswitch") & ("`fslink'" != "linear") {
				ereturn local fsswitched "`fsswitched'"
			}
			if "`k_perfect'" != "0" {
				ereturn local perfect "`perfect'"
			}
			ereturn local cmdline `cmdline'
			ereturn local exog `cleanexog'
			ereturn local endog `cleanendog' 
			ereturn local instruments `cleaninstru'
			if `terza' == 2023 & "`analytic'" == "noanalytic" {
				ereturn local crossderiv "numeric"
			}
			if `terza' == 2023 & "`analytic'" != "noanalytic" {
				ereturn local crossderiv "analytic"
			}
			if "`sandwich'" != "" {
				ereturn local sandwich "`sandwich'"
			}
			**ereturn local estat_cmd "`link'_estat"
			if "`resgenerate'" != "noresgenerate" {
				ereturn local generated `cleanResXTD'
			}
			ereturn local chi2type "Wald"
			ereturn local title "Control function `link' regression"
			if "`vce'" == "robust" {
				ereturn local vcetype "Robust"
				ereturn local vcest "robust"
			}
			if "`clustvar'" != "" {
				ereturn local vcetype "Clustered"
				ereturn local vcest "cluster"
				ereturn local clustvar "`clustvar'"
				ereturn scalar N_clust = round(`N_clust')
			}
			** DO NOT SAVE TEST OF EXOGENEITY AFTER BOOTSTRAPPING **
			if "`resgenerate'" != "noresgenerate" & "`e(vcetype)'" != "Bootstrap" {	
				ereturn scalar chi2_exog = `chi2_exog'
				ereturn scalar df_exog = `df_exog'
				ereturn scalar p_exog = `p_exog'
			}
			ereturn local cmd `cmd'
		}
		** DISPLAY RESULTS ON SCREEN **
		_outcfbinout, level(`level') `ci' `pvalues' `omitted' `vsquish' `emptycells' `baselevels' `allbaselevels' `fvdisp' cformat(`cformat') pformat(`pformat') sformat(`sformat') `lstretch'		
	}
	** REPLAY RESULTS **
	else {
		if "`e(cmd)'" != "cfbinout" {
			error 301
		}
		else {
			syntax, [LEVel(real `e(level)')] [noci] [noPValues] [noOMITted] [VSQUISH] [noEMPTYcells] [BASElevels] [ALLBASElevels] [noFVLABel] [fvwrap(integer 1)] [fvwrapon(string asis)] [CFORMAT(string asis)] /*
			*/ [PFORMAT(string asis)] [SFORMAT(string asis)] [nolstretch]  
			** DISPLAY RESULTS **
			_outcfbinout, level(`level') `ci' `pvalues' `omitted' `vsquish' `emptycells' `baselevels' `allbaselevels' `fvdisp' cformat(`cformat') pformat(`pformat') sformat(`sformat') `lstretch'
		}
	}
end

********************************************************************************
** SUPPLEMENTARY PROGRAMS ******************************************************
********************************************************************************

** CHECK FOR FV IN endo **
cap program drop _endogfv
program define _endogfv
	syntax varlist(fv)
end

** EXCLUDE BASELEVELS AND OMITTED VARIBLES FROM VARLIST **
cap program drop _exclubaom
program define _exclubaom, rclass
	syntax varlist(fv ts) [if] [in] [aweight pweight fweight iweight]
	cap fvexpand `varlist' `if' /*[`weight' `exp']*/
	local varlist "`r(varlist)'"
	local nee : list sizeof varlist
	local cleanfvl ""
	tokenize `varlist'
	local counter = 0
	forvalues ee = 1(1)`nee' {
		gettoken prefix var : `ee', parse(".") match(paren) 
		if (ustrpos(ustrreverse("`prefix'"),"o") != 1 & ustrpos(ustrreverse("`prefix'"),"b") != 1) | "`var'" == "" {
			local cleanfvl "`cleanfvl' ``ee''"
		}
	}
	return local varlist `cleanfvl'
end

** CHECK FOR BINARY VARIABLE **
cap program drop _checkbinvar
program define _checkbinvar, rclass
	syntax varlist(min=1 max=1 numeric fv ts) [if] [in] [aweight pweight fweight iweight]
	if "`weight'" == "pweight" {
		local checkweight "iweight"
	}
	else {
		local checkweight "`weight'"
	}
	sum `varlist' `if' `in' [`checkweight' `exp']
	local checkmin = r(min)
	local checkmax = r(max)
	count `in' `if' & `varlist'<. & (`varlist' != `checkmin' & `varlist' != `checkmax')
	if r(N) > 0 | `checkmin' != 0 {
		local checkbin "nonbinary"
	}
	else {
		local checkbin "binary"
	}
	return local checkbin "`checkbin'"
	return scalar min = `checkmin'
	return scalar max = `checkmax'
end

** MATA FUNCTION delet_missing() FOR DELETING COLUMS AND ROWS in e(b) AND e(V) WITH MISSINGS **
** Code (mainly) borrowed from Daniel Klein (statalist 04 Jul 2016, 15:34)
cap mata : mata drop delete_missing()
mata :
void delete_missing(string scalar nameb, string scalar namev, string scalar newnameb, string scalar newnamev)
{
    real matrix __B
	real matrix __V
    string matrix cnames, rnames
    real rowvector __s
    __B = st_matrix(nameb)
	__V = st_matrix(namev)
    cnames = st_matrixcolstripe(nameb)
    rnames = st_matrixrowstripe(nameb)
    __s = (__B :!= .)
	__st = __s'
    if (orgtype(__B) == "colvector") {
        rnames = select(rnames, __s)
    }
    else if (orgtype(__B) == "rowvector") {
        cnames = select(cnames, __st)
    }
    else {
        _error(3201)
    }
    st_matrix(newnameb, select(__B, __s))
    st_matrixcolstripe(newnameb, cnames)
    st_matrixrowstripe(newnameb, rnames)
	st_matrix(newnamev, select(__V, __s))
	st_matrix(newnamev, select(st_matrix(newnamev), __st))
    st_matrixcolstripe(newnamev, cnames)
    st_matrixrowstripe(newnamev, cnames)
 }
end

*** DISPLAY RESULTS **
cap program drop _outcfbinout
program _outcfbinout, nclass
	syntax, [LEVel(real `e(level)')] [noci] [noPValues] [noOMITted] [VSQUISH] [noEMPTYcells] [BASElevels] [ALLBASElevels] [noFVLABel] [fvwrap(integer 1)] [fvwrapon(string asis)] [CFORMAT(string asis)] [PFORMAT(string asis)] /*
	*/ [SFORMAT(string asis)] [nolstretch] 
	local ls = c(linesize)-7
	local statskip = 46
	local equalskip = 68
	local statend = 70
	local statendfoot = `statend'+3
	local tabfnskip = 56
	local fullpara = 80
	** FV-DISPLAY OPTIONS DEPENDING ON STATA VERSION **
	if `c(stata_version)' < 14 {
		local fvdisp ""
	}
	else {
		local fvdisp `"`fvlabel' fvwrap(`fvwrap') fvwrapon(`fvwrapon')"'
	}
	if "`e(wtype)'" != "" {
	   di as text "(sum of wgt is" as text %10.7e `e(wgtsum)' as text ")"
	}
	di _newline as text "Control function " as result "`e(link)'" as text " estimation"         _continue
	di          _column(`statskip') as text "Number of obs"                                      _column(`equalskip') as text  "=" _column(`statend') as result %9.0gc `e(N)'
	di          _column(`statskip') as text "Wald chi2(" as result %1.0f `e(df_m)' as text ")"   _column(`equalskip') as text  "=" _column(`statend') as result %9.2f  `e(chi2)'
	di          _column(`statskip') as text "Prob > chi2"                                        _column(`equalskip') as text  "=" _column(`statend') as result %9.3f  `e(p)' 
	di as text "Log pseudolikelihood = " as result %9.3f `e(ll)' /*_newline*/
	ereturn display, first level(`level') `ci' `pvalues' `omitted' `vsquish' `emptycells' `baselevels' `allbaselevels' `fvdisp' cformat(`cformat') pformat(`pformat') sformat(`sformat') `lstretch'
	if "`e(chi2_exog)'" != "" & "`e(vcetype)'" != "Bootstrap" {
		di as text "Wald test of exogeneity: chi2(" as result %1.0f `e(df_exog)' as text ") =" as result %5.2f `e(chi2_exog)'        _continue
		di           _column(`tabfnskip') as text "Prob > chi2 = " _column(`statendfoot') as result %5.4f  `e(p_exog)'
	}
	di in smcl as text "{p 0 12 0 `fullpara'}Endogenous: " as result "`e(endog)'{p_end}"
	di in smcl as text "{p 0 12 0 `fullpara'}Exogenous:  " as result "`e(exog)'{p_end}"
	if wordcount("`e(endog)'") > wordcount("`e(instruments)'") {
		di as text "Under-identification issue: less instruments than endogeneous rhs vars."
	}
	if "`e(k_perfect)'" != "" & `e(k_perfect)' > 0 {
		if `e(k_perfect)' > 1 {
			local plural "s"
		}
		di as result `e(k_perfect)' as text " first-stage residual`plural' collinear, dropped from second stage"
	}
end


