********************************************************************************************************************************
** First-Differences IV Estimation of the Linear Discrete-Time Hazard Model ****************************************************
********************************************************************************************************************************
*! version 2.2.0 2023-12-18 ht (option interactinst())
*! version 2.1.2 2023-12-18 ht (adjustment for cfbinout option order())
*! version 2.1.1 2023-12-12 ht (improved checks for collinearity and degenerated first-stage)
*! version 2.1 2023-11-24 ht (call of cfbinout for nonlinear link function)
*! version 2.0.3 2023-11-10 ht (option instruments() to allow for additional non-technical instruments)
*! version 2.0.2 2023-11-08 ht (multiple-differences IV estimation)
*! version 2.0.1 2023-11-07 ht (option underid added)
*! version 2.0.0 2023-10-31 ht (ivregress 2sls used for linear IV estimation)
*! version 1.1.3 2019-12-16 ht (egen - if possible - avoided to reduce run time)
*! version 1.1.2 2019-11-14 ht (more efficient check for collinear variables)
*! version 1.1.1 2019-09-12 ht (improved handling of factor-variables)
*! version 1.1 2019-03-14 ht (higher-order differences considered)
*! version 1.0 2019-01-29 ht
*! author Harald Tauchmann 
*! Own-Differences IV/CF Estimation of Discrete-Time Hazard Model
cap program drop xtdhazard
program xtdhazard, eclass
	version 14
	if !replay() {
		quietly {
			** STORE COMMAND-LINE ENTRY **
			local cmd "xtdhazard"
			local cmdline "`cmd' `*'"
			** DISPLAY-FORMAT for WARNINGS **
			local ls = c(linesize)-7
			** SYNTAX **
			syntax /*varlist(ts fv)*/ anything [if/] [in] [pweight fweight aweight iweight/], [Difference(numlist integer >0 sort)] [noABSORBing] [Robust] [CLuster(varname)] [VCE(string)] /*
			*/ [LEVel(real `c(level)')] [noci] [noPValues] [noOMITted] [VSQUISH] [noEMPTYcells] [BASElevels] [ALLBASElevels] [noFVLABel] [fvwrap(integer 1)] [fvwrapon(string asis)] [CFORMAT(string asis)] [PFORMAT(string asis)] /*
			*/ [SFORMAT(string asis)] [nolstretch] /*
			*/ [INSTRuments(varlist numeric fv ts)] /* [Link(string)] 
			** OPTIONS FOR LINK LINEAR **
			*/ [UNDerid(string asis)] [SHOWtest] [noFIRSTstage] [ASESTimator(name)] [INTERactinst] /*
			** OPTIONS FOR LINK LOGIT/PROBIT/CLOGLOG **
			*/ [noRESGenerate] [RESName(string)] [REPLace] [Order(integer 1)] [TERza(integer 2023)] [FSKeep] [noSEARCH] [FSLink(string)] [noANAlytic] [noSANDwich] /*[noEOMITted]
			** OPTIMIZATION OPTION FOR logit, probit, AND cloglog **
			*/ [DIFficult] [TECHnique(passthru)] [ITERate(passthru)] [TOLerance(passthru)] [LTOLerance(passthru)] [NRTOLerance(passthru)] [QTOLerance(passthru)] [NONRTOLerance] [FROM(passthru)]
			** TEMPNAMES and TEMPVARS **		
			tempname _borg _Vorg _XdXd _XdX _G _Gsm _bsm _Vsm _bmvreg _sbmvreg _borg0d _Vorg0d _estimatorresu _newgradient _newmns _tmpgradient _tmpmns _Vorg_model _Vsm_model _rules
			tempvar _ly _fail _one _zero _fdesamp _ww _lhs
			** MANAGE ESTIMATOR **
			gettoken estimator varlist : anything
			if "`estimator'" != "2sls" & "`estimator'" != "logit" & "`estimator'" != "probit" & "`estimator'" != "cloglog" {
				noi di as error "{p 0 2 2 `ls'}{bf:`estimator'} is not a valid estimator; 2sls, logit, probit, and cloglog allowed{p_end}"
				exit 198
			}
			else {
				if "`estimator'" == "logit" | "`estimator'" == "probit" | "`estimator'" == "cloglog" {
					local link "`estimator'"
				}
				else {
					local link "linear"
				}
			}
			** CHECK IF VARLIST INCLUDES TS or FV VARIABLES **
			fvrevar `varlist' `iff' `inn', list
			local exvarlist "`r(varlist)'"
			local fv : list local(varlist) === local(exvarlist)
			** IDENTIFY lhs VARIABLE **
			tokenize "`varlist'"
			local lhs "`1'"
			tokenize "`lhs'", parse(".")
			if "`2'" != "" {
				noi di as error "{p 0 2 2 `ls'}factor-variable and time-series operators not allowed for depvar{p_end}"
				exit 101
			}
			** CHECK PANEL-DATA DECLARATION **
			_xt, treq
			local ivar "`r(ivar)'"
			local tvar "`r(tvar)'"
			** MANAGE OPTION LINK **
			if "`link'" == "" | "`link'" == "identity" {
				local link "linear"
			}
			if ("`link'" != "linear") & ("`link'" != "probit") & ("`link'" != "logit") & ("`link'" != "cloglog") {
				noi di as error "{p 0 2 2 `ls'}link {bf:`link'} not allowed{p_end}"
				exit 198
			}
			if ("`link'" == "probit") | ("`link'" == "logit") | ("`link'" == "cloglog") {
				cap which cfbinout
				if _rc != 0 {
					noi display as error "{p 0 2 2 `ls'}{bf:`link'} link reqires {bf:cfbinout.ado} to be installed{p_end}"
					exit 198
				}
			}
			** CHECK IF RHS-VARIABLES ARE SPECIFIED **
			tokenize "`varlist'"
			if "`2'" == "" {
				noi di as error "{p 0 2 2 `ls'}at least one indepvar must be specified{p_end}"
				exit 102
			}			
			** HANDLE ENPTY CELLS **
			set emptycells drop
			** MANAGE IF
			if "`if'" != "" {
				local iff "if (`if')"
			}
			else {
				local iff "if (1==1)"
			}
			** MANAGE WEIGHT **
			if "`exp'" != "" {
				local eqs "="
			}
			** MANAGE OPTION DIFFERENCE **
			if "`difference'" == "" {
				local difference = 1
			}
			local countdiff : list sizeof local(difference)
			if `countdiff' > 1 {
				local multidiff = 1
			}
			else {
				local multidiff = 0
			}
			foreach dd in `difference' {
					local maxdiff = max(`dd',1)
			}
            ** MAMAGE ERRORANEOUSLY SPECIFYING vce(bootstrap) **
            gettoken vceboot : vce, parse(",")
            local vceboot : list retokenize vceboot
            if "`vceboot'" == "bootstrap" | "`vceboot'" == "bootstra" | "`vceboot'" == "bootstr" | "`vceboot'" == "bootst" | "`vceboot'" == "boots" | "`vceboot'" == "boot" {
				noi display as error "{p 0 2 2 `ls'}vcetype {bf:`vce'} not allowed, use prefix command bootstrap{p_end}"
				exit 198            
            }
			** MANAGE DEFAULT VCE OPTION **
			if "`robust'" == "" & "`cluster'" == "" & "`vce'" == "" {
				if "`estimator'" == "2sls" {
					local vce "robust"
				}
				else {
					local vce "robust" /*"oim"*/
				}
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
			if "`1'" == "unadjusted" | "`1'" == "unadjuste" | "`1'" == "unadjust" | "`1'" == "unadjus" | "`1'" == "unadju" | "`1'" == "unadj" | "`1'" == "unad" | "`1'" == "una" | "`1'" == "un" {
				local vce "unadjusted"
			}
			if "`1'" == "robust" | "`1'" == "robus" | "`1'" == "robu" | "`1'" == "rob" | "`1'" == "ro" | "`1'" == "r" {
				local vce "robust"
			}
			if "`1'" == "cluster" | "`1'" == "cluste" | "`1'" == "clust" | "`1'" == "clus" | "`1'" == "clu" | "`1'" == "cl" {
				local clustvar "`2'"
				local vce "cluster `clustvar'"
			}
			** CHECK FOR INCONSISTENCY OF LINK() AND VCE() **
			if ("`vce'" == "opg" | "`vce'" == "oim") & "`link'" == "linear" {
				noi display as error "{p 0 2 2 `ls'}vcetype {bf:`vce'} not allowed with estimator {bf:2sls}{p_end}"
				exit 198
			}
			if ("`vce'" == "unadjusted") & ("`link'" != "linear") {
				noi display as error "{p 0 2 2 `ls'}vcetype {bf:`vce'} not allowed with estimator {bf:`link'}{p_end}"
				exit 198
			}
			** MANAGE OPTION STOREAESTIMATOR **
			if "`asestimator'" == "" {
				local eststore "`_estimatorresu'"
			}
			else {
				local eststore "`asestimator'"
			}
			** MANAGE OPTION UNDERID **
			if `"`underid'"' != "" {
				if "`link'" != "linear" {
					noi display as error "{p 0 2 2 `ls'}option underid not allowed with link(`link'), no test carried out{p_end}"
				}
				cap which underid
				local undercheck = _rc
				if _rc != 0 {
					local underidinst
					noi display as error "{p 0 2 2 `ls'}option underid requires underid.ado to be installed, no test carried out{p_end}"
					exit 198
				}
				else {
					gettoken underidcom underid2 : underid, parse(",") quotes bind
					gettoken komma underidopt : underid2, parse(",") quotes bind
					if "`showtest'" == "showtest" {
						local disptest "noisily"
					}
					else {
						local disptest ""
					}
				}
			}
			** CHECK WETHER lhs VAR IS BINARY **
			cap confirm numeric variable `lhs'
			if _rc != 0 {
				egen byte `_lhs' = group(`lhs') /*`in' `iff'*/ 
				replace `_lhs' = `_lhs'-1
				sum `_lhs'
				if `r(min)' != 0 | `r(max)' != 1 {
					noi di as error "{p 0 2 2 `ls'}depvar {bf: `lhs'} not binary{p_end}" 
					mata : st_rclear()
					exit 2000        
				}
				local lhsvar "`_lhs'"
			}
			else {
				sum `lhs'
				local lmin = r(min)
				local lmax = r(max)
				count if `lhs' <. & `lhs' != `lmin' & `lhs' != `lmax'
				if r(N) > 0 {
					noi di as error "{p 0 2 2 `ls'}depvar {bf: `lhs'} not binary{p_end}" 
					mata : st_rclear()
					exit 2000          
				}
				else {
					if `lmin' == 0 & `lmax' == 1 {
						local lhsvar "`lhs'"
					}
					else {
						gen byte `_lhs' = 0 if `lhs' == `lmin'
						replace  `_lhs' = 1 if `lhs' == `lmax'
						local lhsvar "`_lhs'"
					}
				}
			} 
			** CHECK ABSORBING STATE **
			gen byte `_ly' = l.`lhsvar' `iff' & !missing(`lhsvar') `in'
			count `iff' & (`lhsvar' == 0 & `_ly' == 1) `in'
			if r(N) > 0 {
				count `iff' & (`lhsvar' == 1 & `_ly' == 0) `in'
				if r(N) == 0 {
					noi di as error "{p 0 2 2 `ls'}recode depvar as ({bf: 1-`lhs'}){p_end}" 
					mata : st_rclear()
					exit 2000				
				}
				else {
					noi di as error "{p 0 2 2 `ls'}variable {bf: `lhs'} does not indicate an absorbing state{p_end}" 
					if "`absorbing'" != "noabsorbing" {
						mata : st_rclear()
						exit 198
					}
					else {
						local irregular = 1
					}
				}
			} 
			** CHECK CODING of ABSORBING STATE **
			if "`absorbing'" != "noabsorbing" {
				gen byte `_fail' = 0
				replace `_fail' = 1 if (`lhsvar' == 1 & `_ly' == 1)
			}
			else {
				gen byte `_fail' = 0
			}  
			local nfail  "& (`_fail' != 1)"
			** DE-FACTOR-VARIABLERIZE VARLIST and IDENTIFY COLLINEAR VARIABLES **
			local rhsvars : list local(varlist) - local(lhs)
			_rmcoll `rhsvars' `iff' & (l.`lhsvar' !=.) `nfail' `inn', expand
			local rhsvars "`r(varlist)'"
			** SAVE ORIGINAL FV-RHS-VARLIST **
			local cn "`r(varlist)' _cons"
			local cn : list retokenize cn
			local kko : list sizeof local(cn)
			local kkom1 = `kko'-1
			local kkoi = `countdiff'*`kkom1'+1
			local fvinl = strpos("`cn'",".")  
			** GENERATE TEMPORARY VARIBLES for RHS and COLLECT NON-COLLINEAR VARS **
			fvrevar `rhsvars'
			local expvarlist "`r(varlist)'"
			_rmcoll `expvarlist' `iff' & (l.`lhsvar' !=.) `nfail' `inn', expand	
			local expvarlist "`r(varlist)'"		
			local diffvarlist ""
			foreach dd in `difference' {
				foreach vv in `expvarlist' {
					gettoken prefix var : vv, parse(".") match(paren) 
					if strpos(strreverse("`prefix'"),"o") != 1 | "`var'" == "" {
						local diffvarlist "`diffvarlist' D`dd'.`vv'"
					} 
					else {
						local diffvarlist "`diffvarlist' D`dd'`vv'"
					}
				}
			}
			** MARK TIME-INVARIATE RHS VARS AS TO BE OMITTED **							
			_rmdcoll `lhsvar' `diffvarlist' `iff' & (l.`lhsvar' !=.) `nfail' `inn'				
			tokenize `r(varlist)'	
			if `r(k_omitted)' > 0 {
				local newexpvarlist ""
				local newrhsvars ""
				local cc = 0
				foreach vv in `expvarlist' {
					gettoken var rhsvars : rhsvars 
					local cc = `cc'+1			
					local colex = 0
					foreach dd in `difference' {
						if  ustrrpos("``cc''","oD.") != 0 | ustrrpos("``cc''","oD`dd'.") != 0 {
							local colex = `colex'+1
						}
					}
					if `colex' == 0 {
						local auxx "`auxx' `vv'"
						local noomc "`noomc' `cc'"
					}
					else {
						if strpos("`vv'",".") == 0 {
							local vv "o.`vv'"
						}
						else if strpos("`vv'","o.") == 0 {
							local vv = ustrregexrf("`vv'","\.","o\.")
						}
						if strpos("`var'",".") == 0 {
							local var "o.`var'"
						}
						else if (strpos("`var'","o.") == 0 & strpos("`var'","b.") == 0) {
							local var = ustrregexrf("`var'","\.","o\.")
						}
					}
					local newexpvarlist "`newexpvarlist' `vv'"
					local newrhsvars "`newrhsvars' `var'"
				}
				local auxx : list retokenize auxx
				local noomc_noc "`noomc'"
				local noomc "`noomc' `kko'"
				local expvarlist "`newexpvarlist'"
				local expvarlist : list retokenize local(expvarlist)
				local rhsvars "`newrhsvars'"
				local rhsvars : list retokenize local(rhsvars)				
			}
			else {
				local nocollin "nocollin"
				local auxx "`expvarlist'"
			}
			if "`auxx'" == "" {
				**noi di as error "{p 0 2 2 `ls'}no indepvar exhibits variation over time{p_end}" 
				noi di as error "{p 0 2 2 `ls'}all own-differences instruments collinear with `lhsvar'{p_end}" 
				ereturn clear
				exit 409        
			}
			_rmcoll `rhsvars' `iff' `nfail' `inn'
			** CORRESPONDENCE LIST OF auxx AND cn **
			local correspauxx ""
			if `r(k_omitted)' > 0 {
				foreach pp in `noomc' {
					foreach oo in `cn' {
						local poo : list posof "`oo'" in cn
						if `poo' == `pp' & "`oo'" != "_cons" {
							local correspauxx "`correspauxx' `oo'"
						}
					}
				}
			}
			else {
				local noconsin "_cons"
				local correspauxx : list local(cn) - local(noconsin)
			}
			** MANAGE OPTION INSTRUMENTS **
			local instlist ""
			foreach dd in `difference' {
				local instlist "`instlist' D`dd'.(`auxx')"
				_rmcoll `instlist' `iff' & (l.`lhsvar' !=.) `nfail' `inn', expand
				local instlist "`r(varlist)'"
			}
			local ntechinst : list sizeof local(instlist)
			if "`instruments'" != "" {
				_rmcoll `instlist' `instruments' `iff' & (l.`lhsvar' !=.) `nfail' `inn', expand
				local oinstlist "`r(varlist)'"
				local oinstruments : list local(oinstlist) - local(instlist)
				local instlist "`oinstlist'"
			}	
			if "`link'" == "linear" {
				** EXECUTE ivregress 2sls **
				if "`interactinst'" == "" {
					ivregress 2sls `lhsvar' (`rhsvars' = `instlist') `iff' `nfail' `in' [`weight' `eqs' `exp'], perfect vce(`vce') 
				}
				else {
					ivregress 2sls `lhsvar' (`rhsvars' = c.(`instlist')##c.(`instlist')) `iff' `nfail' `in' [`weight' `eqs' `exp'], perfect vce(`vce') 
				}
				estimates store `eststore'
				gen `_fdesamp' = e(sample)
				** SAVE RESULTS FROM ivregress 2sls **
				matrix `_bsm' = e(b)
				matrix `_Vsm' = e(V)
				local p = chi2tail(`e(df_m)',`e(chi2)')
				** CALCULATE NUMB. of GROUPS WEIGHT-SUM and NUMB of CLUSTERS **
				sort `_fdesamp' `ivar' `tvar', stable
				count if `_fdesamp' == 1 & (`ivar' != `ivar'[_n-1] | _n == 1)
				sort `ivar' `tvar', stable
				local mgs = r(N)
				if "`weight'" != "" {
					gen `_ww' = `exp'
					sum `_ww' if `_fdesamp' == 1
					local wmat = r(sum)
				}
				if "`clustvar'" != "" {
					local N_clust = e(N_clust)
				} 
				** CALCULATE MATRIX OF FIRST-STAGE COEFFICIENTS (IF ALLOWED mvreg OTHERWISE regress) **
				if "`firststage'" != "nofirststage" {
					local fsregc = 0
					local perfectcount = 0
					local perfectnum ""
					foreach vv in `auxx' {
						local fsregc = `fsregc'+ 1
						if "`interactinst'" == "" {
							cap reg `vv' `instlist' if `_fdesamp' == 1  [`weight' `eqs' `exp']
						}
						else {
							cap reg `vv' c.(`instlist')##c.(`instlist') if `_fdesamp' == 1  [`weight' `eqs' `exp']
						}
						if `fsregc' ==  1 {
							matrix `_Gsm' = e(b)
						}
						else {
							matrix `_Gsm' = (`_Gsm' \ e(b))
						}
						if `e(r2)' == 1 {
							local perfectcount = `perfectcount'+ 1
							local perfectnum "`perfectnum' `fsregc'"
						}
					}
					** COLUMNNAMES FOR MATRIX OF FIRST-STAGE COEFFICIENTS **
					local gocoln : colnames `_Gsm'
					local gorown "`auxx'"
					local gncoln ""
					local gnrown ""
					tokenize `correspauxx'
					foreach cc in `gocoln' {
						local techinst : list posof "`cc'" in local(gocoln)
						foreach auxv in `auxx' {
							local oo : list posof "`auxv'" in local(auxx)
							gettoken prefix var : cc, parse(".") match(paren) 
							if (strpos(strreverse("`prefix'"),"o") != 1 & strpos(strreverse("`prefix'"),"b") != 1) | "`var'" == "" {
								foreach dd in `difference' {
									if `dd' == 1 {
										local dd ""
									}
									if "D`dd'.`auxv'" == "`cc'" {
										if `fvinl' == 0 {
											if `techinst' <= `ntechinst' {
												local gncoln "`gncoln' D`dd'.``oo''"
											}
										}
										else {
											if `techinst' <= `ntechinst' {
												local gncoln "`gncoln' D`dd':``oo''"
											}
										}
									}
									if "oD`dd'.`auxv'" == "`cc'" {
										if `fvinl' == 0 {
											if `techinst' <= `ntechinst' {
												local gncoln "`gncoln' D`dd'.``oo''"
											}
										}
										else {
											if `techinst' <= `ntechinst' {
												local gncoln "`gncoln' D`dd':``oo''"
											}
										}
									}
								}
							}
						}
					}
					foreach rr in `gorown' {
						foreach auxv in `auxx' {
							local oo : list posof "`auxv'" in local(auxx)
							if "`auxv'" == "`rr'" {
								local gnrown "`gnrown' ``oo''"	
							}
						}
					}
					local gncoln : list retokenize local(gncoln)
					matrix colnames `_Gsm' = `gncoln' `oinstruments' _cons
					** RENAME COLUMNS OF e(G) IF INTERACTIONS OF INSTRUMENTS ENTER FIRST-STAGE **
					if "`interactinst'" == "interactinst" {
						local gcoloname "`gncoln' `oinstruments'"
						local gcoloname : list retokenize local(gcoloname)
						local colsg : list sizeof local(gcoloname) 
						tokenize "`gcoloname'"
						local gcoliname ""
						forvalues ii = 1(1)`colsg' {
							gettoken eq2 var2 : `ii', parse(:)
							if "`var2'" == "" {
								local var2 "`eq2'"
								local eq2 ""
							}
							else {
								local var2 = ustrtoname(ustrregexra("`var2'",":",""),0)
							}
							forvalues jj = `ii'(1)`colsg' {
								gettoken eq1 var1 : `jj', parse(:)
								if "`var1'" == "" {
									local var1 "`eq1'"
									local eq1 ""
								}
								else {
									local var1 = ustrtoname(ustrregexra("`var1'",":",""),0)
								}
								if "`eq1'" != "" & "`eq2'" != "" {
									local gcoliname "`gcoliname' `eq1'#`eq2':`var1'#`var2'"
								}
								if "`eq1'" == "" & "`eq2'" != "" {
									local gcoliname "`gcoliname' D0#`eq2':`var1'#`var2'"
								}
								if "`eq1'" != "" & "`eq2'" == "" {
									local gcoliname "`gcoliname' `eq1'#D0:`var1'#`var2'"
								}
								if "`eq1'" == "" & "`eq2'" == "" {
									local gcoliname "`gcoliname' `var1'#`var2'"
								}
							}
						}
						local gicolname "`gcoloname' `gcoliname' _cons"						
						local gicolname : list retokenize local(gicolname)
						matrix colnames `_Gsm' = `gicolname'
					}
					local gnrown : list retokenize local(gnrown)
					cap matrix rownames `_Gsm' = `gnrown'
					mat `_G' = `_Gsm'
					estimates restore `eststore'
				}
				mat `_borg'  = `_bsm'
				mat `_Vorg' = `_Vsm'
				if "perfectnum" != "" {
					local perfect ""
					tokenize `gnrown'
					foreach nn in `perfectnum' {
						local perfect "`perfect' ``nn''"
					}
					local perfect : list retokenize local(perfect)
				}
				** PERFORM IV TEST BY CALLING underid (Mark E. Schaffer & Frank Windmeijer) **
				if `"`underid'"' != "" {
					if `undercheck' == 0 {
						estimates restore `eststore'
						** CHANGE ROW & COLUMN NAMES OF e(b) and e(V) TO MAKE RESULTS FROM underid INFORMATIVE **	
						mata : delete_0("`_borg'", "`_Vorg'", "`_borg0d'", "`_Vorg0d'")'
						ereturn repost b = `_borg0d' V = `_Vorg0d', rename buildfvinfo resize
						** EXECUTE underid **
						cap `disptest' callunderid `underidopt'
						if _rc != 0 {
							noi di as error "{p 0 2 2 `ls'}underid failed, possibly invalid syntax{p_end}" 
						}
						** SAVE RESULTS FROM underid **
						foreach rr in b_uid V_uid S_uid b0_uid b_oid V_oid S_oid b0_oid sw_uid {
							if "`r(`rr')'" != "" {
								tempname _`rr'
								matrix `_`rr'' = r(`rr')
								if "`nocollin'" != "nocollin" {
									tokenize `correspauxx'
									foreach colrow in col row {
										local underidn`colrow' ""
										local underid`colrow' : `colrow'names `_`rr''
										foreach ud`colrow' in `underid`colrow'' {
											foreach auxv in `auxx' {
												local o`colrow' : list posof "`auxv'" in local(auxx)
												if "`auxv'" == "`ud`colrow''" {
													local underidn`colrow' "`underidn`colrow'' ``o`colrow'''"
												}
												foreach dd in `difference' {
													if `dd' == 1 {
														local dd ""
													}
													if "D`dd'.`auxv'" == "`ud`colrow''" {
														if `fvinl' == 0 {
															local underidn`colrow' "`underidn`colrow'' D`dd'.``o`colrow'''"
														}
														else {
															local underidn`colrow' "`underidn`colrow'' D`dd':``o`colrow'''"
														}
													}
												}
											}
										}							
										if ("`colrow'" == "col") & (("`rr'" == "b_uid") | ("`rr'" == "V_uid") | ("`rr'" == "S_uid") | ("`rr'" == "b0_uid") | ("`rr'" == "b_oid") | ("`rr'" == "V_oid") | ("`rr'" == "S_oid") | ("`rr'" == "b0_oid")) {
											mat colnames `_`rr'' = `underidncol'
										}
										if ("`colrow'" == "row") & (("`rr'" == "V_uid") | ("`rr'" == "S_uid") | ("`rr'" == "V_oid") | ("`rr'" == "S_oid") | ("`rr'" == "sw_uid")) {
											mat rownames `_`rr'' = `underidnrow'
										}
									}
								}
							}
						}
					}
				}
				** REPOST e(b) AND e(V) **
				ereturn repost b =`_borg' V =`_Vorg', properties(b V) esample(`_fdesamp') resize buildfvinfo
			}
			** ESTIMATE NONLINEAR BINARY OUTCOME MODEL **
			else {
				cfbinout `link' `lhsvar' (`auxx' = `instlist') `iff' `nfail' `in' [`weight' `eqs' `exp'], vce(`vce') `replace' `resgenerate' resname(`resname') /*fslink(linear)*/ /*
				*/ fslink(`fslink') fsswitch order(`order') terza(`terza') `fskeep' `search' `analytic' `sandwich' /*
				*/ `difficult' `technique' `iterate' `tolerance' `ltolerance' `nrtolerance' `nonrtolerance' `nonrtolerance' `from' 
				estimates store `eststore'
				gen `_fdesamp' = e(sample)
				** SAVE RESULTS FROM cfbinout WHICH NEED TO BE ADJUSTED **
				matrix `_bsm' = e(b)
				matrix `_Vsm' = e(V)
				matrix `_Gsm' = e(G)
				if "`vce'" != "opg" & "`vce'" != "oim" {
					matrix `_Vsm_model' = e(V_modelbased)	
				}
				else {
					matrix `_Vsm_model' = e(V)
				}
				matrix `_tmpgradient' = e(gradient)
				if "`link'" != "cloglog" { 
					matrix `_tmpmns' = e(mns)					
				}
				local p = chi2tail(`e(df_m)',`e(chi2)')
				** CALCULATE NUMB. of GROUPS WEIGHT-SUM and NUMB of CLUSTERS **
				sort `_fdesamp' `ivar' `tvar', stable
				count if `_fdesamp' == 1 & (`ivar' != `ivar'[_n-1] | _n == 1)
				sort `ivar' `tvar', stable
				local mgs = r(N)
				if "`weight'" != "" {
					gen `_ww' = `exp'
					sum `_ww' if `_fdesamp' == 1
					local wmat = r(sum)
				}
				if "`clustvar'" != "" {
					local N_clust = e(N_clust)
				} 
				** CORRESPONDENCE OF ROW NAMES OF e(rules) AND `_Gsm' **
				cap confirm matrix e(rules)
				if _rc == 0 {
					local tmprnfs : rownames `_Gsm'
					local tmprnrules : rownames e(rules)
					local cGrule ""
					local nocGrule ""
					foreach rr in `tmprnrules' {
						local posrule : list posof "`rr'" in local(tmprnfs)
						if `posrule' != 0 {
							local cGrule "`cGrule' `posrule'"
							local nocGrule "`nocGrule' 0"
						}
						else {
							local nocGrule "`nocGrule' 1"						
						}
					}	
				}
				** COLUMNNAMES FOR MATRIX OF FIRST-STAGE COEFFICIENTS **
				local gocoln : colnames `_Gsm'			
				local gorown "`auxx'"
				local gncoln ""
				local gnrown ""
				local resnamelist ""
				tokenize `correspauxx'
				if "`resname'" == "" {
					local resname "res"
				}
				foreach cc in `gocoln' {
					local techinst : list posof "`cc'" in local(gocoln)
					foreach auxv in `auxx' {
						local oo : list posof "`auxv'" in local(auxx)
						foreach dd in `difference' {
							if `dd' == 1 {
								local dd ""
							}
							if "D`dd'.`auxv'" == "`cc'" {
								if `fvinl' == 0 {
									if `techinst' <= `ntechinst' {
										local gncoln "`gncoln' D`dd'.``oo''"
									}
								}
								else {
									if `techinst' <= `ntechinst' {
										local gncoln "`gncoln' D`dd':``oo''"
									}
								}
							}
							if "oD`dd'.`auxv'" == "`cc'" {
								if `fvinl' == 0 {
									if `techinst' <= `ntechinst' {
										local gncoln "`gncoln' D`dd'.``oo''"
									}
								}
								else {
									if `techinst' <= `ntechinst' {
										local gncoln "`gncoln' D`dd':``oo''"
									}
								}
							}
						}
					}
				}
				foreach rr in `gorown' {
					foreach auxv in `auxx' {
						local oo : list posof "`auxv'" in local(auxx)
						gettoken prefix var : auxv, parse(".") match(paren) 
						if strpos(strreverse("`prefix'"),"o") != 1 | "`var'" == "" {
							if "`auxv'" == "`rr'" {
								local gnrown "`gnrown' ``oo''"
								if "`resgenerate'" != "noresgenerate" {
									forvalues ss = 1(1)`order' {
										if `ss' == 1 {
											local resstorename = strtoname("`resname'_``oo''",0)
											if ("`replace'" == "replace") & ("`resname'_`rr'" != "`resstorename'") {
												cap drop `resstorename'
											}	
											cap confirm variable `resname'_`rr'
											if _rc == 0 {
												rename `resname'_`rr' `resstorename'
												local resnamelist "`resnamelist' `resstorename'"
											}
										}
										else {
											local resstorename = strtoname("`resname'`ss'_``oo''",0)
											if ("`replace'" == "replace") & ("`resname'`ss'_`rr'" != "`resstorename'") {
												cap drop `resstorename'
											}	
											cap confirm variable `resname'`ss'_`rr'
											if _rc == 0 {
												rename `resname'`ss'_`rr' `resstorename'
												local resnamelist "`resnamelist' `resstorename'"
											}	
										}
									}
								}								
								** NAMES OF IN FIRST-STAGE PERFECTLY PREDICTED ENDOGENEOUS VARS **
								if "`e(perfect)'" != "" {
									if "`oldperfect'" == "" {
										local oldperfect "`e(perfect)'"
									}
									gettoken op oldperfect : oldperfect
									if "`rr'" == "`op'" {
										local perfect "`perfect' ``oo''"
										local perfect : list retokenize local(perfect)
									}
									else {
										local oldperfect "`op' `oldperfect'"
									}
								}
								** SWITCHES (not requited since xtdhazard always specifies fslink(linear) **
							}
						}
					}
				}
				** RETOKENIZE LIST FOR BETTER STORAGE IN e() **
				local resnamelist : list retokenize local(resnamelist)
				local gnrown : list retokenize local(gnrown)
				local gncoln : list retokenize local(gncoln)
				matrix colnames `_Gsm' = `gncoln' `oinstruments' _cons
				cap matrix rownames `_Gsm' = `gnrown'
				mat `_G' = `_Gsm'
				estimates restore `eststore'
				** CORRECT ROW NAMES OF e(rules) **
				cap confirm matrix e(rules)
				if _rc == 0 {
					tokenize `gnrown'
					local counter = 0
					foreach rr in `tmprnrules' {
						local counter = `counter'+ 1
						gettoken corresprule nocGrule : nocGrule
						if "`corresprule'" == "1" {
							local newrnrules "`newrnrules' `rr'"
						}
						else {
							gettoken correspruleno cGrule : cGrule
							local newrnrules "`newrnrules' ``correspruleno''"
						}
					}
					mat `_rules' = e(rules)	
					mat rownames `_rules' = `newrnrules'
				}
				** WRITE NON-ZERO ENTRIES TO e(b) AND e(Var) AND ADJUST TO INCLUSION OF RESITUALS **
				if "`resgenerate'" != "noresgenerate" {
					local numres : list sizeof local(resnamelist) 
					local kkocf = `kko'+`numres'
					local ex_cons "_cons"
					local cncf : list local(cn)-local(ex_cons)
					local cncf "`cncf' `resnamelist' _cons"
					local cncf : list retokenize local(cncf)
					forvalues cc = 1(1)`numres' {
						local ccm1 = (`kko'-1)+`cc'
						if `cc' == 1 {
							local addnoomc "`ccm1'" 
						}
						else {
							local addnoomc "`addnoomc' `ccm1'" 
						}
					}
					local noomccf "`noomc_noc' `addnoomc' `kkocf'"
				}
				else {
					local kkocf = `kko'
					local cncf "`cn'"
					local noomccf "`noomc'"
				}
				if "`eomitted'" != "noeomitted" & "`nocollin'" != "nocollin" {				
					mat `_borg' = J(1,`kkocf',0)
					mat colnames `_borg' = `cncf'
					mat `_newgradient'	= J(1,`kkocf',0)
					mat colnames `_newgradient' = `cncf'
					if "`link'" != "cloglog" {
						mat `_newmns'	= J(1,`kkocf',0)
						mat colnames `_newmns' = `cncf'	
					}				
					mat `_Vorg' = J(`kkocf',`kkocf',0)
					mat colnames `_Vorg' = `cncf'
					mat rownames `_Vorg' = `cncf'
					mat `_Vorg_model' = J(`kkocf',`kkocf',0)
					mat colnames `_Vorg_model' = `cncf'
					mat rownames `_Vorg_model' = `cncf'
					local ii = 0
					foreach cc in `noomccf' {
						local jj = 0
						local ii = `ii' +1
						mat `_borg'[1,`cc'] = `_bsm'[1, `ii']
						mat `_newgradient'[1,`cc'] = `_tmpgradient'[1, `ii']
						if "`link'" != "cloglog" {
							mat `_newmns'[1,`cc'] = `_tmpmns'[1, `ii']
						}
						foreach rr in `noomccf' {
							local jj = `jj' +1
							mat `_Vorg'[`rr',`cc'] = `_Vsm'[`jj', `ii']
							mat `_Vorg_model'[`rr',`cc'] = `_Vsm_model'[`jj', `ii']
						}
					}
				}                
				** CHANGE ROW AND COLUMNAMES OF e(b) AND e(V) **
				else {
					if "`nocollin'" == "nocollin" {
						local scn "`cncf'"
					}
					else {
						tokenize `cncf'		
						foreach cc in `noomc' {
							local scn "`scn' ``cc''"
						}
					}
					mat `_borg'  = `_bsm'
					mat colnames `_borg' = `scn'
					mat `_newgradient'	= `_tmpgradient'
					mat colnames `_newgradient' = `scn'
					if "`link'" != "cloglog" {
						mat `_newmns'	= `_tmpmns'
						mat colnames `_newmns' = `scn'	
					}				
					mat `_Vorg' = `_Vsm'
					mat colnames `_Vorg' = `scn'
					mat rownames `_Vorg' = `scn'
					if "`vce'" != "opg" & "`vce'" != "oim" {				
						mat `_Vorg_model' = `_Vsm_model'
						mat colnames `_Vorg_model' = `scn'
						mat rownames `_Vorg_model' = `scn'
					}
				}
				** CORRECT COLUMNAMES FOR OMITTED VARS **
				mata : st_local("comit",strofreal(diag0cnt(diag(st_matrix("`_borg'")))))
				if "`comit'" != "0" {
					local bcn : colfullnames `_borg'
					tokenize "`bcn'"
					local nbcn ""
					local bcs : colsof `_borg'
					forvalues cc = 1(1)`bcs' {
						local bb = `_borg'[1,`cc']
						if `bb' == 0 {
							if strpos("``cc''","b.") == 0 & strpos("``cc''","o.") == 0 {
								if strpos("``cc''",".") != 0 {
									local cnrep = ustrregexrf("``cc''","\.","o\.")
								}
								else {
									local cnrep  "o.``cc''"
								}
							}
							else {
								local cnrep "``cc''"
							}
							local nbcn "`nbcn' `cnrep'"
						}
						else {
							local nbcn "`nbcn' ``cc''"
						}
					}
					mat colnames `_borg' = `nbcn'
					mat colnames `_newgradient' = `nbcn'
					if "`link'" != "cloglog" {
						mat colnames `_newmns' = `nbcn'	
					}
					mat colnames `_Vorg' = `nbcn'
					mat rownames `_Vorg' = `nbcn'
					if "`vce'" != "opg" & "`vce'" != "oim" {
						mat colnames `_Vorg_model' = `nbcn'
						mat rownames `_Vorg_model' = `nbcn'
					}
				}
				** REPOST e(b) AND e(V) **
				ereturn repost b =`_borg' V =`_Vorg', properties(b V) esample(`_fdesamp') resize buildfvinfo
			}
			** POST RESULTS TO e() **
			ereturn scalar N_g = `mgs'
			if `multidiff' == 0 {
				ereturn scalar difference = `difference'
			}
			ereturn scalar level = `level'
			ereturn scalar p = `p'
			if ("`link'" == "linear") & ("`firststage'" != "nofirststage") & ("`perfectcount'" != "") {
				ereturn scalar k_perfect = `perfectcount'
			}
			if "`absorbing'" == "noabsorbing" {
				if "`irregular'" == "1" {
					ereturn scalar irregular = 1
				}
				else {
					if "`aabs'" == "1" {
						ereturn scalar irregular = -1
					}
					else {
						ereturn scalar irregular = 0
					}
				}
			}
			if `'"`underid'"' != "" {
				 foreach rr in j_uid df_uid p_uid j_oid df_oid p_oid {
					if "`r(`rr')'" != "" {
						cap ereturn scalar `rr' = r(`rr')
					}
				 }
			}
			** MATRICES in e() **
			if "`firststage'" != "nofirststage" | "`link'" != "linear" {
				ereturn matrix G = `_G'
			}
			if `"`underid'"' != "" {
				foreach rr in b_uid V_uid S_uid b0_uid b_oid V_oid S_oid b0_oid sw_uid {
					cap ereturn matrix `rr' = `_`rr''
				}
			}
			if "`link'" != "linear" {
				if "`vce'" != "opg" & "`vce'" != "oim" {
					ereturn matrix V_modelbased = `_Vorg_model'
				}
				ereturn matrix gradient = `_newgradient'
				if "`link'" != "cloglog" {
					ereturn matrix mns = `_newmns'
					ereturn matrix rules = `_rules'
				}
			}
			** MACROS in e() **
			ereturn local link `link'
			if "`link'" == "linear" {
				ereturn local cmd "ivregress"
				ereturn local estimator "2sls"
			}
			else {
				ereturn local cmd `link'
				ereturn local estimator "cf"
			}
			ereturn local cmd2 "xtdhazard"
			ereturn local cmdline `cmdline'
			if "`link'" == "linear" { 
				ereturn local title "Own-differences IV estimation of linear discrete-time hazard model"
			}
			else {
				ereturn local title "Own-differences instruments CF estimation of discrete-time hazard model"
			}
			if `multidiff' != 0 {
				ereturn local difference "`difference'"
			}
			if "`interactinst'" == "interactinst" {
				ereturn local interactinst "interactions"
			}
			else if "`link'" == "linear" {
				ereturn local interactinst "nointeractions"
			}
			if "`weight'" != "" {			
				ereturn local wexp  "=`exp'"
				ereturn local wtype "`weight'"
				ereturn scalar wgtsum = `wmat'
			}
			if "`vce'" == "robust" | ("`weight'" == "pweight" & "`vce'" == "ols") {
				ereturn local vcetype "Robust"
				ereturn local vcest "robust"
			}
			if "`clustvar'" != "" {
				ereturn local vcetype "Clustered"
				ereturn local vcest "cluster"
				ereturn local clustvar "`clustvar'"
				ereturn scalar N_clust = round(`N_clust')
			}
			if ("`link'" != "linear") | ("`firststage'" != "nofirststage") {
				ereturn local endog `gnrown'
				ereturn local exog "`gncoln' `oinstruments'"
			}
			ereturn local instruments ""
			if ("`link'" != "linear") & ("`resgenerate'" != "noresgenerate") {
				ereturn local generated "`resnamelist'"
			}
			if ("`perfectcount'" != "" | "`e(perfect)'" != "")  &  (("`link'" == "linear" & "`firststage'" != "nofirststage") | ("`link'" != "linear"))  {
				ereturn local perfect "`perfect'"
			}
			ereturn local depvar "`lhs'"
			ereturn local chi2type "Wald"
			ereturn local ivar "`ivar'"
			ereturn local tvar "`tvar'"		
			if `"`underid'"' != "" {
				 foreach rr in rkstat vceopt rkopt {
					if "`r(`rr')'" != "" {
						cap ereturn local `rr' = r(`rr')
					}
				 }
			}		
		}
		** DISPLAY RESULTS **
		_outdispxtdhazard, level(`level') `ci' `pvalues' `omitted' `vsquish' `emptycells' `baselevels' `allbaselevels' `fvdisp' cformat(`cformat') pformat(`pformat') sformat(`sformat') `lstretch'
	}
	** REPLAY RESULTS **
	else {
		if "`e(cmd2)'" != "xtdhazard" {
			error 301
		}
		else {
			syntax, [LEVel(real `e(level)')] [noci] [noPValues] [noOMITted] [VSQUISH] [noEMPTYcells] [BASElevels] [ALLBASElevels] [noFVLABel] [fvwrap(integer 1)] [fvwrapon(string asis)] [CFORMAT(string asis)] /*
			*/ [PFORMAT(string asis)] [SFORMAT(string asis)] [nolstretch]  
			** DISPLAY RESULTS **
			_outdispxtdhazard, level(`level') `ci' `pvalues' `omitted' `vsquish' `emptycells' `baselevels' `allbaselevels' `fvdisp' cformat(`cformat') pformat(`pformat') sformat(`sformat') `lstretch'
		}
	}
end

********************************************************************************
** SUPPLEMENTARY PROGRAMS ******************************************************
********************************************************************************

** CALL OF UNDERID **
cap program drop callunderid
program callunderid, rclass
	syntax [anything] 
	if "`anything'" != "" {
		underid, `anything'
	}
	else {
		underid
	}
	return add
end

** MATA FUNCTION delet_0() FOR DELETING COLUMS AND ROWS in e(b) AND e(V) REFERRING TO COLLINEAR VARS **
** Code (mainly) borrowed from Daniel Klein (statalist 04 Jul 2016, 15:34)
cap mata : mata drop delete_0()
mata :
void delete_0(string scalar nameb, string scalar namev, string scalar newnameb, string scalar newnamev)
{
    real matrix __B
	real matrix __V
    string matrix cnames, rnames
    real rowvector __s
    __B = st_matrix(nameb)
	__V = st_matrix(namev)
    cnames = st_matrixcolstripe(nameb)
    rnames = st_matrixrowstripe(nameb)
    __s = (__B :!= 0)
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
 
 ** DISPLAY RESULTS **
cap program drop _outdispxtdhazard
program _outdispxtdhazard, nclass
	syntax, [LEVel(real `e(level)')] [noci] [noPValues] [noOMITted] [VSQUISH] [noEMPTYcells] [BASElevels] [ALLBASElevels] [noFVLABel] [fvwrap(integer 1)] [fvwrapon(string asis)] [CFORMAT(string asis)] [PFORMAT(string asis)] /*
	*/ [SFORMAT(string asis)] [nolstretch] 
    ** DISPLAY RESULTS **
    local statskip = 46
    local equalskip = 68
    local statend = 70
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
    ** DISPLAY ORDER of DIFFERENCE IN OUTPUT **
	cap confirm number `e(difference)'
	if _rc == 0 {
		local r2d = `e(difference)'
		if `e(difference)' == 1 {
			local odiff `"as text "first""'
			local r2d "f"
		}
		if `e(difference)' == 2 {
			local odiff `"as result `e(difference)' as text "nd""'
		}
		if `e(difference)' == 3 {
			local odiff `"as result `e(difference)' as text "rd""'
		}
		if `e(difference)' >= 4 {
			local odiff `"as result `e(difference)' as text "th""'
		}  
	}
	else {
			local odiff `"as text "multiple""'
	}
	** DISPLAY TYPE OF MODEL **
	if "`e(estimator)'" == "2sls" {
		local caplink "Linear"
		local method "IV"
	}
	else {
		local caplink = strproper("`e(link)'")
		local method "CF"
	}
    di _newline as text "`caplink' discrete-time hazard model" _continue
    di          _column(`statskip') as text "Number of obs"                                      _column(`equalskip') as text  "=" _column(`statend') as result %9.0gc `e(N)'
    di as text `odiff' as text "-differences `method' estimation" _continue
    di          _column(`statskip') as text "Number of groups"                                   _column(`equalskip') as text  "=" _column(`statend') as result %9.0gc `e(N_g)'
    if "`e(irregular)'" == "1" {
        di      as text "`e(depvar)' inconsistent with hazard model" _continue
    }
    if "`e(irregular)'" == "-1" {
        di      as text "obs. after abs. state reached considered" _continue
    }
    di          _column(`statskip') as text "Wald chi2(" as result %1.0f `e(df_m)' as text ")"   _column(`equalskip') as text  "=" _column(`statend') as result %9.2f  `e(chi2)'
    di          _column(`statskip') as text "Prob > chi2"                                        _column(`equalskip') as text  "=" _column(`statend') as result %9.3f  `e(p)'
	if "`e(estimator)'" == "2sls" { 
		di          _column(`statskip') as text "R-sq"                                               _column(`equalskip') as text  "=" _column(`statend') as result %9.3f  `e(r2)' _newline
	}
	else {
		di as text "Log pseudolikelihood = " as result %9.3f `e(ll)'
	}
    ereturn display, level(`level') `ci' `pvalues' `omitted' `vsquish' `emptycells' `baselevels' `allbaselevels' `fvdisp' cformat(`cformat') pformat(`pformat') sformat(`sformat') `lstretch'
	if "`e(interactinst)'" == "interactions" {
		di in smcl as text "{p 0 6 0 `fullpara'}Squares and cross-products of instruments included in first-stage regressions{p_end}"
	}
	** REPORT RESULT FROM UNDERIDENTIFICATION TEST **
	if ("`e(df_uid)'" != "" ) & ("`disptest'" != "noisily") {
		di as text "Underidentification test: " as text "j = " as result %9.2f  `e(j_uid)' as text "; Chi-sq(" as result %4.0g  `e(df_uid)'  as text "); p-value = " as result %5.4f  `e(p_uid)' /*_newline*/
	}
	if ("`e(df_oid)'" != "" ) & ("`disptest'" != "noisily") {
		di as text "Overidentification test: " as text "j = " as result %9.2f  `e(j_oid)' as text "; Chi-sq(" as result %4.0g  `e(df_oid)'  as text "); p-value = " as result %5.4f  `e(p_oid)' /*_newline*/
	}
	if "`e(k_perfect)'" != "" {	
		if `e(k_perfect)' > 0 {
			if `e(k_perfect)' > 1 {
				local plural "s"
			}
			if "`e(link)'" != "linear" {
				di in smcl as result "{p 0 6 0 `fullpara'}`e(k_perfect)'" as text " first-stage residual`plural' collinear, dropped from second stage: " as result "`e(perfect)'{p_end}"
			}
			else {
				di in smcl as result "{p 0 6 0 `fullpara'}`e(k_perfect)'" as text " rhs variable`plural' perfectly predicted in first-stage regression: " as result "`e(perfect)'{p_end}"
			}
		}
	}
end
