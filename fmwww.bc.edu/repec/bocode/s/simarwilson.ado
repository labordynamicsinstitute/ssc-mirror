********************************************************************************************************************************
** SIMAR & WILSON (2007) TRUNCATED REGRESSION FOR DEA-EFFICIENCY SCORES  *******************************************************
********************************************************************************************************************************

*! version 2.2 2017-01-17 ht
*! author Harald Tauchmann
*! Simar & Wilson Efficiency Analysis

capture program drop simarwilson
program simarwilson, eclass
** CHECK VERSION **
if `c(stata_version)' < 14.2 {
    local ustr "str"
    local usubstr "substr"
    version 12
}
else {
    local ustr "ustr"
    local usubstr "usubstr"
    version 14.2
}
if !replay() {
		quietly {
			local cmd "simarwilson"
			local cmdline "`cmd' `*'"
			syntax varlist(fv) [if] [in] [pweight iweight], [REPS(integer 1000)] [noUNIT] [noTWOsided] [LEVel(real `c(level)')] [DOTs] [SAVEAll(name)] [CINormal] [BBOOTstrap] [noCONStant] [noRTNorm] [OFFset(varname)] [DIFficult] [COLlinear] [CONSTraints(passthru)] [TECHnique(passthru)] [ITERate(passthru)] [TOLerance(passthru)] [LTOLerance(passthru)] [NRTOLerance(passthru)] [NONRTOLerance(passthru)] [FROM(passthru)] [CFORMAT(string asis)] [PFORMAT(string asis)] [SFORMAT(string asis)] [VSQUISH]
            ** TEMPORARY FILES, MATRICES, and VARIABLES **
			tempvar __tempid __tempwgh __rnn __yoff __iyy __truncfit __ntruncfit __yboot __rnn1 __esamp
			tempname __borg __coef __sig __cov __bbm __bbias __rank  __Cns __BB __VB __BM __cip
			tempfile __resufile
            ** MANAGE MORE **
            local moreold `c(more)'
            set more off
			** MANAGE LEVEL **
			if `level' >= 10 & `level' <= 99.99 {
                local level = round(`level',0.01)
                local level = substr("`level'",1,5)
			}
			else {
                noisily di as error "warning: level(`level') not allowed, outside [10,99.99] interval"
				local level = `c(level)'			
			}
			** MANAGE WEIGHT **
			if "`weight'" != "" {
				gen `__tempwgh' `exp'
				local weight2 = substr("`weight'",1,2)
			}
			else {
				gen `__tempwgh' = 1
				local weight2 "pw"
			}
			local exp2 "`__tempwgh'"
			** MANAGE TRUNCREG OPTIONS **
			local opttrunc "`constraints' `collinear' `difficult' `technique' `tolerance' `ltolerance' `ntolerance' `nonrtolerance' `from'"
            local itetrunc "`iterate'"
			** TOKENIZE VARLIST **
			tokenize `varlist'
			local yy "`1'"
			local xx : list local(varlist) - local(yy)
			** MANAGE DEPENDENT VARIABLE **
			foreach fo in "##" "#" "." {
				local check = `ustr'pos("`yy'","`fo'")
				if `check' != 0 {
					if "`fo'" == "##" | "`fo'" == "#" {
						display as error "depvar may not be an interaction"
						exit 198					
					}
					else {
						display as error "depvar may not be a factor variable"
						exit 198										
					}
				}
			}
			** MANAGE OFFSET VARIABLE **
			foreach fo in "##" "#" "." {
				local check = `ustr'pos("`offset'","`fo'")
				if `check' != 0 {
					if "`fo'" == "##" | "`fo'" == "#" {
						display as error "interactions not allowed in option offset()"
						exit 101					
					}
					else {
						display as error "factor variable not allowed in option offset()"
						exit 101										
					}
				}
			}
			** MANAGE VARLIST **
			local varlist2 "`varlist'"
			foreach fo in "##" "#" {
				local varlist2 : subinstr local varlist2 "`fo'" " ", all
			}
            foreach vv in `varlist2' {
            	gettoken ll rr : vv, parse(".")
            	if `ustr'len("`rr'") != 0 {
            		local varlist2 : list local(varlist2) - local(vv)
            		local varlist2 : list local(varlist2) | local(rr)
            	}
            }
            local varlist2 : subinstr local varlist2 "." "", all
			local varlist2 : list uniq varlist2
			** SELECT SAMPLE **
			gen `__tempid' = _n
			preserve
			if "`if'" != "" {
				keep `if'
			}
			if "`in'" != "" {
				keep `in'
			}
			keep `__tempid' `__tempwgh' `varlist2' `offset'
			** DROP MISSINGS **
			foreach vv of varlist `varlist2' `offset' {
				keep if `vv' <. 
			}
			** CHECK DEPENDENT VARIABLE **
			sum `yy' if `yy' <.
			if r(min)<= 0 {
				display as error "nonpositive efficiency scores in `yy'"
				restore
				exit 482
			}
			if r(min)< 1 & r(max) > 1 {
				if "`unit'" == "" {
					display as error "warning: values of `yy' not bounded to unit int"
				}
				if "`unit'" == "nounit" {
					display as error "warning: values of `yy' not bounded to [1,+inf) int"
				}
			}
			if r(min) >= 0 & r(max) <= 1 & "`unit'" == "nounit" {
				display as error "warning: all values of `yy' within unit int, option nounit chgd to unit"
				local unit ""
			}
			if r(min) >= 1 & "`unit'" == "" {
				display as error "warning: all values of `yy' within [1,+inf) int, option unit chgd to nounit"
				local unit "nounit"
			} 
            ** CHECK NUMBER of REPS **
			if "`cinormal'" != "cinormal" & `reps' < 1000 {
				display as error "warning: reps(`reps') too small for meaningful percentile CIs"
			}
			** OLS REGRESSION **
			if "`offset'" != "" {
				gen `__yoff' = `yy' - `offset'
			}
			else {
				gen `__yoff' = `yy'
			}
			cap reg `__yoff' `xx' [`weight2' = `exp2']
			local osampsw = e(N)
			count if e(sample)
			local osamps = r(N)
			if "`weight2'" == "pw" {
				local osampsw = `osamps'
			}
			if "`unit'" == "" {				
				reg `__yoff' `xx' [`weight2' = `exp2'] if `yy' <= 1, `constant'
			}
			else {				
				reg `__yoff' `xx' [`weight2' = `exp2'] if `yy' >= 1, `constant'
			}
			local sampsw = e(N)
			count if e(sample)
			local samps = r(N)
			if "`weight2'" == "pw" {
				local sampsw = `samps'
			}
			gen `__esamp' = 1 if e(sample)
			keep if e(sample)
			** INITIAL TRUNCATED REGRESSION **
			if "`unit'" == "" {
                if "`twosided'" == "notwosided" {				
    			    cap truncreg `yy' `xx' [`weight2' = `exp2'], ul(1) `constant' offset(`offset') `opttrunc' `itetrunc'
                }
                else {
                    cap truncreg `yy' `xx' [`weight2' = `exp2'], ll(0) ul(1) `constant' offset(`offset') `opttrunc' `itetrunc'
                }
			}
			else {				
				cap truncreg `yy' `xx' [`weight2' = `exp2'], ll(1) `constant' offset(`offset') `opttrunc' `itetrunc'
			}
			if _rc != 0 | e(converged) != 1 {
				di as error "convergence not achieved"
				ereturn clear
				restore
				exit 430
			}
			local sig = e(sigma)
			predict `__truncfit', xb
			gen `__ntruncfit' = 1-`__truncfit'
			matrix `__borg' = e(b)
			sum `exp2' if e(sample)
			local tsampsw = r(sum)
			local tsamps = r(N)
			if "`weight2'" == "pw" {
				local tsampsw = `tsamps'
			}
			** EXTRACT "EX-POST" VARLIST **
			local cn : colnames e(b)
			local cons "_cons"
			local xx2 : list uniq cn
			local xx2 : list xx2 - cons
			di "`nrl'"
			** TRANSFER of RESULTS **
            local ic = e(ic)
            local k_eq = e(k_eq)
            local converged = e(converged)
            local rc = e(rc)
			local ll = e(ll)
            local df_m = e(df_m)
            local k_aux = e(k_aux)
            ** CHECK for CONSTRAINTS **
            if "`e(Cns)'" != "" {
                matrix `__Cns' = e(Cns)
                local iconstr "iconstr"
            }
			** SIMAR & WILSON BOOTSTRAPP **
            ** PREVENT EXCESSIVE # of ITERATIONS in BOOTSTRAP
            local ic2 = max(3*`ic',25)
            if "`itetrunc'" == "" {
                local itetrunc "iterate(`ic2')"
            }
            else {
                local striter "`itetrunc'"
                local striter = regexr("`striter'","iterate","")
                local striter = `striter'
                if `striter' > `ic2' {
                    local itetrunc "iterate(`ic2')"
                }
            }
            ** START BOOSTRAP ITERATIONS **
            local bb = 1
            local cc = 0
			while `bb' <= `reps' {
                local cc = `cc'+1
                ** ABORT BOOTSTRAP if MANY FAILURES **
				if `cc'-`bb' > `reps' {
                    noisily: display as text " `cc'"
                    noisily: di as error "warning: excessive # of failing bootstr. reps.; bootstr. aborted"
                    local reps = `bb'
                    local nbstrf = `cc'-`bb'
					continue, break
				}
				cap drop `__rnn'
                ** DRAW FROM TRUNCATED NORMAL DISTRIBUTION **
				if "`unit'" == "" {
					if "`twosided'" == "notwosided" {
					   gen `__rnn' = invnormal(runiform()*(normal(`__ntruncfit'/`sig')))*`sig'
					}
					else {
					   gen `__rnn' = invnormal(normal((`__ntruncfit'-1)/`sig')+runiform()*(normal(`__ntruncfit'/`sig')-normal((`__ntruncfit'-1)/`sig')))*`sig'
					}
                }
				else {
					gen `__rnn' = invnormal(normal(`__ntruncfit'/`sig')+runiform()*(1-normal(`__ntruncfit'/`sig')))*`sig'
                }
				cap drop `__yboot'
                ** GENERATE BOOTSTRAP EFFICIENCY SCORES **
				gen `__yboot' = `__truncfit'+ `__rnn'
                ** ESTIMATE TRUNCREG for BOOTRSTRAP SAMPLE **
				if "`unit'" == "" {	
					if "`twosided'" == "notwosided" {
                        cap truncreg `__yboot' `xx2' [`weight2' = `exp2'] if `yy' < 1, ul(1) `constant' offset(`offset') `opttrunc' `itetrunc'
                    }
                    else {
                        cap truncreg `__yboot' `xx2' [`weight2' = `exp2'] if `yy' < 1, ll(0) ul(1) `constant' offset(`offset') `opttrunc' `itetrunc'
                    }
				}
				else {	
					cap truncreg `__yboot' `xx2' [`weight2' = `exp2'] if `yy' > 1, ll(1) `constant' offset(`offset') `opttrunc' `itetrunc'
				}
                ** CONTINUE IF FAILED **
				if _rc != 0 | e(converged) != 1 {
                    ** DISPLAY ITERATION DOTS **
					if "`dots'" == "dots" {
    					if `cc' == 1 {
    						noisily: display _newline as text "Bootstrap replications (" as result "`reps'" as text ")"
                            noisily: display as text "{hline 4}{c +}{hline 3} 1 {hline 3}{c +}{hline 3} 2 {hline 3}{c +}{hline 3} 3 {hline 3}{c +}{hline 3} 4 {hline 3}{c +}{hline 3} 5"
    					}
						if `cc'/50 == round(`cc'/50) {
							noisily: display as error "x" as text " `cc'"
						}
						else {
							noisily: display as error "x" _continue
						}
					}
                    continue
				}
                ** DISPLAY ITERATION DOTS **
				if "`dots'" == "dots"  {
					if `cc' == 1 {
						noisily: display _newline as text "Bootstrap replications (" as result "`reps'" as text ")"
                        noisily: display as text "{hline 4}{c +}{hline 3} 1 {hline 3}{c +}{hline 3} 2 {hline 3}{c +}{hline 3} 3 {hline 3}{c +}{hline 3} 4 {hline 3}{c +}{hline 3} 5"
					}
					if `cc'/50 == round(`cc'/50) | `bb' == `reps' {
						noisily: display as text ". `cc'"
					}
					else {
						noisily: display as text "." _continue
					}
				}
                ** COLLECT BOOTSTRAP COEFFICIENT ESTIMATES **
				if `bb' == 1 {
					mata : `__BB' = st_matrix("e(b)")
				}
				else {
					mata : `__BB' = (`__BB' \ st_matrix("e(b)"))
				}
                ** STOP BOOTSTRAP IF # of REQUESTED REPLICATIONS REALIZED **
				local bb = `bb'+ 1
				if `bb' == `reps'+1 {
                    local nbstrf = `cc'-(`bb'-1)
					continue, break
				}
			}
			** CALCULATE COVARIANCE-MATRIX **
            mata : `__VB' = quadvariance(`__BB')
            mata : st_matrix("`__cov'",`__VB')
			** CALCULATE BOOTSTRAP MEAN and BIAS **
			mata : `__BM' = mean(`__BB')
			mata : st_matrix("`__bbm'",`__BM')
			local colsob = colsof(`__borg')
			local colsbb = colsof(`__bbm')
			mat `__bbias' =  `__bbm' - `__borg'
			** PERCENTILE CONFIDENCE INTERVALLS **
            cipsimarwilson `level' `__BB' `__cip'
            ** CLEAR MATA **
            if "`saveall'" == "" {
                mata : mata drop `__BB' `__VB' `__BM'
            }
            else {
                mata : mata drop `__VB' `__BM' 
                capture mata : mata drop `saveall'   
                mata : mata rename `__BB' `saveall'          
            } 
			** RENAME RESULTS **
			local nc = colsof(`__borg')-1
			local psig = 1+`nc'
			mat `__coef' = `__borg'[1...,1..`nc']
			mat `__sig' = `__borg'[1...,`psig'..`psig']
			mat coleq `__coef' = `yy'
			mat `__borg' = (`__coef',`__sig')
			local cn : colfullnames `__borg'
			matrix colnames `__cov' = `cn'
			matrix rownames `__cov' = `cn'
			matrix rownames `__cip' = `cn'
			matrix colnames `__cip' = cip`level':ll cip`level':ul
			matrix `__cip' = `__cip''
			matrix colnames `__bbias' = `cn'
            matrix colnames `__bbm' = `cn'
           	** RESTORE ORIGNIAL SAMPLE **
			keep `__tempid' `__esamp'
			save `__resufile'
            restore
            merge 1:1 `__tempid' using `__resufile', nogenerate update replace force
            replace `__esamp' = 0 if `__esamp' != 1
            ** POSTING RESULTS **
			ereturn clear            
            if "`iconstr'" == "iconstr" {
                ereturn post `__borg' `__cov' `__Cns', properties(b V) obs(`sampsw') esample(`__esamp') findomitted
            }
            else {
			    ereturn post `__borg' `__cov', properties(b V) obs(`sampsw') esample(`__esamp') findomitted
            }
			** WALD TEST of NULL MODEL **
			if `df_m' > 0 {
				test [`yy']
				local wchi2 = `r(chi2)'
				local wp = `r(p)'
			}
			else {
				local wchi2 = .
				local wp = .			
			}
			** RANK of e(V) **
			mata : st_matrix("`__rank'",rank(st_matrix("e(V)")))
			** SCALARS **
			ereturn scalar N = round(`sampsw')
			ereturn scalar N_lim = round(`sampsw')-round(`tsampsw')
			ereturn scalar N_nolim = round(`tsampsw')
			if "`osampsw'" != "" {
				ereturn scalar N_drop = round(`osampsw')-round(`sampsw')
			}
			else {
				ereturn scalar N_drop = 0
			}
            ereturn scalar sigma = `sig'
            ereturn scalar ll_pseudo =  `ll'
            ereturn scalar ic = `ic'
            ereturn scalar converged =  `converged'
            ereturn scalar rc =  `rc'
            ereturn scalar rank = `__rank'[1,1]
            ereturn scalar k_eq = `k_eq'
            ereturn scalar df_m = `df_m'
            ereturn scalar k_aux = `k_aux'
            ereturn scalar chi2 = `wchi2'
            ereturn scalar p = `wp'
			ereturn scalar N_reps = `reps'
            ereturn scalar N_misreps = `nbstrf'
            ereturn scalar level = `level'
			** MATRICES ** 
			ereturn matrix ci_percentile = `__cip'
			ereturn matrix bias_bstr = `__bbias'
            ereturn matrix b_bstr = `__bbm'
			** MACROS **
            ereturn local saveall `saveall'
			ereturn local offset `offset'
            ereturn local cinormal `cinormal'
            ereturn local bbootstrap `bbootstrap'
			ereturn local depvar "efficiency"
			ereturn local depvarname "`yy'"
			if "`weight'" != "" {			
              ereturn local wexp  "`exp'"
              ereturn local wtype "`weight'"
			}
			if "`unit'" == "" {
				ereturn local unit "unit"
			}
			else {
				ereturn local unit `unit'
			}
			if "`twosided'" == "notwosided" | "`unit'" == "nounit" {
				ereturn local truncation "onesided"
			}
			else {
				ereturn local truncation "twosided"
			}
            ereturn local cmd `cmd'
            ereturn local cmdline `cmdline'
            ereturn local title "Simar & Wilson (2007) eff. analysis"
	   }
	   set more `moreold'
	}
    else {
        if "`e(cmd)'" != "simarwilson" {
			error 301
		}
		else {
			syntax, [LEVel(real `e(level)')] [CINormal] [BBOOTstrap] [CFORMAT(string asis)] [PFORMAT(string asis)] [SFORMAT(string asis)] [VSQUISH]
            ** TEMPORARY MATRIX for PERCENTILE CIs **
            tempname __cip
			** MANAGE LEVEL **
			if `level' >= 10 & `level' <= 99.99 {
                local level = round(`level',0.01)
                local level = substr("`level'",1,5)
			}
			else {
                noisily di as error "warning: level() outside [10,99.99] interval not allowed"
				local level = `e(level)'			
			}
		}
    }
    ** DISPLAY RESULTS **
	** DISPLAY-OPTIONS (Deactivated) **
	if "`cformat'" == "" | "`cformat'" != "" {
		local cformat "%9.0g"
	}
	if "`pformat'" == "" | "`pformat'" != "" {
		local pformat "%5.3f"
	}
	if "`sformat'" == "" | "`sformat'" != "" {
		local sformat "%8.2f"
	}
	** SKIPPING (determine values for _skip()) **
	if "`unit'" == "" {
		local inq "<"
	}
	else {
		local inq ">"
	}
	local inei "inefficient if `e(depvarname)'"
	if "`e(df_m)'" != "" {
    	if `e(df_m)' > 0 {
    		local fskip = 1+floor(log10(`e(df_m)'))
    	}
    	else {
    		local fskip = 1
    	}
	}
	else {
		local fskip = 1
	}
	local tabwidth = 78
	local statwidth = 37
	local statwidth2 = 12
	local statskip = `tabwidth'-`statwidth'
    local ciskip  = 7 - strlen("`level'")
    local ciskip2 = 7 - strlen("`e(level)'")
	local rr = 0 
	foreach disp in "Number of obs" "Number of efficient obs" "Number of bootstr. reps" "Wald chi2(" "Prob > Chi2(" {
	    local rr = `rr'+1
		if `rr' == 1 {
			local statskip`rr' = `statskip' - strlen("`e(title)'") 
		}
		local disp`rr' "`disp'"
		local ldisp`rr'= strlen("`disp'")
		local skip`rr' = `statwidth' - `statwidth2' - `ldisp`rr''
		if `rr' == 4 | `rr' == 5 {
			local skip`rr' = `statwidth' - `ldisp`rr'' - `fskip' - 1 - `statwidth2'
		}
		if `rr' == 4 {
			local statskip`rr' = `statskip' - `ustr'len("`inei'") - 4
		}
		if `rr' == 5 {
			local statskip`rr' = `statskip' - strlen("`e(truncation)'") - 11
		}
	}
	** DISPLAY RESULTS on SCREEN **
	if "`dots'" == "dots" {
		display _newline
	}
	display _newline as text "`e(title)'" _skip(`statskip1') as text "`disp1'" _skip(`skip1') as text " =  " as result %8.0f `e(N)'
	display _skip(`statskip') as text "`disp2'" _skip(`skip2') as text " =  " as result %8.0f `e(N_lim)'
    display _skip(`statskip') as text "`disp3'" _skip(`skip3') as text " =  " as result %8.0f `e(N_reps)'
    if "`e(unit)'" == "nounit" {
    	display _skip(`statskip') as text "`disp4'" as result %`fskip'.0f `e(df_m)' as text ")" _skip(`skip4') as text " =  " as result %8.2f `e(chi2)'
        display as text "`inei'" as result " `inq' " as text "1" _skip(`statskip4') as text "`disp5'" as result %`fskip'.0f `e(df_m)' as text ")" _skip(`skip5') as text " =  " as result %8.4f `e(p)' _newline 
    }
    else {
    	display as text "`inei'" as result " `inq' " as text "1" _skip(`statskip4') as text "`disp4'" as result %`fskip'.0f `e(df_m)' as text ")" _skip(`skip4') as text " =  " as result %8.2f `e(chi2)'
    	display as text "`e(truncation)' truncation" _skip(`statskip5') as text "`disp5'" as result %`fskip'.0f `e(df_m)' as text ")" _skip(`skip5') as text " =  " as result %8.4f `e(p)' _newline 
    }
	if "`cinormal'" == "cinormal" {
        ** DISPLAY REGRESSION TABLE WITH NORMAL-APPROX-CIs **
        local ccn = abbrev("`e(depvar)'",12)
        local colsk = 13 - `ustr'len("`ccn'")
        display as text "{hline 13}{c TT}{hline 64}"
        if "`bbootstrap'" == "" {
            display _column(13) as text " {c |}  Observed" _skip(3) "Bootstrap" _skip(25) "Normal approx."
        }
        else {
            display _column(13) as text " {c |} Bootstrap" _skip(3) "Bootstrap" _skip(25) "Normal approx."
        }
        display _column(`colsk') as text "`ccn' {c |}" _skip(6)  "Coef." _skip(3) "Std. Err." _skip(6) "z" _skip(4) "P>|z|" _skip(`ciskip') "[" as result `level' as text "% Conf. Interval]"
        display as text "{hline 13}{c +}{hline 64}"
        local ccn = `usubstr'(abbrev("`e(depvarname)'",12),1,12)
        local colsk = 13 - `ustr'len("`ccn'")
        display as result "`ccn'" as text _skip(`colsk') "{c |}"
        tempname __dima __dima2
        if "`bbootstrap'" == "" {
            mata : st_matrix("`__dima2'" , st_matrix("e(V)"):^0.5)
            matrix `__dima' = (e(b)',vecdiag(`__dima2')',e(b)'+ invnormal((1-0.01*`level')/2)*vecdiag(`__dima2')',e(b)'- invnormal((1-0.01*`level')/2)*vecdiag(`__dima2')') 
        }
        else {
            mata : st_matrix("`__dima2'" , st_matrix("e(V)"):^0.5)
            matrix `__dima' = (e(b_bstr)',vecdiag(`__dima2')',e(b_bstr)'+ invnormal((1-0.01*`level')/2)*vecdiag(`__dima2')',e(b_bstr)'- invnormal((1-0.01*`level')/2)*vecdiag(`__dima2')') 
        }
    }
    else {
        ** DISPLAY REGRESSION TABLE WITH PERCENTILE-CIs **
        ** RECALCULATE PERCENTILE CIs if REQUIRED **
        if "`e(level)'" != "`level'" & "`e(saveall)'" != "" {
            cipsimarwilson `level' `e(saveall)' `__cip'
            local nlevel "`level'"
            mat scip = `__cip'
        }
        else {
            mat `__cip' = e(ci_percentile)'
            local nlevel "`e(level)'"
        }
        local ccn = abbrev("`e(depvar)'",12) 
        local colsk = 13 - `ustr'len("`ccn'")
        display as text "{hline 13}{c TT}{hline 64}"
        if "`bbootstrap'" == "" {
            display _column(13) as text " {c |}  Observed" _skip(3) "Bootstrap" _skip(27) "Percentile"
        }
        else {
            display _column(13) as text " {c |} Bootstrap" _skip(3) "Bootstrap" _skip(27) "Percentile"
        }
        display _column(`colsk') as text "`ccn' {c |}" _skip(6)  "Coef." _skip(3) "Std. Err." _skip(6) "z" _skip(4) "P>|z|" _skip(`ciskip') "[" as result `nlevel' as text "% Conf. Interval]"
        display as text "{hline 13}{c +}{hline 64}"
        local ccn = `usubstr'(abbrev("`e(depvarname)'",12),1,12)
        local colsk = 13 - `ustr'len("`ccn'")
        display as result "`ccn'" as text _skip(`colsk') "{c |}"
        tempname __dima __dima2
        if "`bbootstrap'" == "" {
            mata : st_matrix("`__dima2'" , st_matrix("e(V)"):^0.5)
            matrix `__dima' = (e(b)',vecdiag(`__dima2')',`__cip') 
        }
        else {
            mata : st_matrix("`__dima2'" , st_matrix("e(V)"):^0.5)
            matrix `__dima' = (e(b_bstr)',vecdiag(`__dima2')',`__cip') 
        }
    }
    local cn = rowsof(`__dima')
    local cns : rownames `__dima'
    tokenize `cns'
    forvalues cc = 1(1)`cn' {
        if `cc' == `cn' {
            local ccn "/sigma"
        }
        else {
            local ccn = abbrev("``cc''",12)
        }
        local colsk = 13 - `ustr'len("`ccn'")
        display _column(`colsk') as text "`ccn' {c |}" _skip(2) as result `cformat' `__dima'[`cc',1] _skip(2) as result `cformat' (`__dima'[`cc',2]) /*
    	*/ _skip(1) as result `sformat' `__dima'[`cc',1]/(`__dima'[`cc',2]) /*
    	*/ _skip(3) as result `pformat' 2*(1-normal(`__dima'[`cc',1]/(`__dima'[`cc',2]))) /*
    	*/ _skip(4) as result `cformat' `__dima'[`cc',3] /*
    	*/ _skip(3) as result `cformat' `__dima'[`cc',4]
        if `cc' == `cn'-1 {
            if "`e(offset)'" != "" {
                local ccn = abbrev("`e(offset)'",12)
                local colsk = 13 - `ustr'len("`ccn'")
                display _column(`colsk') as text "`ccn' {c |}" _skip(2) as result `cformat' 1 _skip(2) as text "(offset)"
            }
            display as text "{hline 13}{c +}{hline 64}"
        } 
        if `cc' == `cn' {
            display as text "{hline 13}{c BT}{hline 64}"
        } 
    }
    ** DISPLAY WARNING if CHANG in LEVEL for PECENTILE CIs is REQUESTED WITHOUT SPCIFYING SAVEALL() **
    if replay() & "`e(level)'" != "`level'" & "`cinormal'" != "cinormal" & "`e(saveall)'" == "" {
        noisily di as text "saveall() not previously specifiyed; cannot change level for percentile CIs"
    }
end

**************************************************************************************************************
** PERCENTILE CONFIDENCE INTERVALLS **************************************************************************
**************************************************************************************************************
capture program drop cipsimarwilson
program cipsimarwilson, nclass
version 12
	args level BB cip
	** TEMPORARY NAMES **
    tempname __CIB __CIBI __cc __rr
    mata : st_numscalar("`__cc'",cols(`BB')) 
    mata : st_numscalar("`__rr'",rows(`BB'))
    local nb = `__cc'
	local llo = 1+floor(`__rr'*((100-`level')/200))
	local ulo =    ceil(`__rr'-`__rr'*((100-`level')/200))
    local cw = min(max(((1-`level'/100)*`__rr'-((`__rr'-`ulo')+(`llo'-1))),0),2)
	forvalues cc = 1(1)`nb' {
        mata : `BB' = sort(`BB',`cc')
        if `llo' > 1 & `ulo' < `__rr' {
        mata : `__CIBI' = (0.5+0.25*`cw')*(`BB'[`llo',`cc'],`BB'[`ulo',`cc'])+ (0.5-0.25*`cw')*(`BB'[`llo'-1,`cc'],`BB'[`ulo'+1,`cc'])
        }
        else {
            mata : `__CIBI' = (`BB'[`llo',`cc'],`BB'[`ulo',`cc'])
        }
		if `cc' == 1 {
			mata : `__CIB' = `__CIBI'
		}
		else {
			mata : `__CIB' = (`__CIB' \ `__CIBI')
		}
	}
	mata : st_matrix("`cip'", `__CIB')
    mata : mata drop `__CIB' `__CIBI'
end



