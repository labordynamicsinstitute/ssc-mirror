*! 2.0.0 Ariel Linden 24Aug2024 // added lowess and CI options
*! 1.1.1 Ariel Linden 22Mar2021 // fixed bug in trperiod() loop
*! 1.1.0 Ariel Linden 10Mar2021 // added parsing code to extract date(s) from trperiod() 
*! 1.0.1 Ariel Linden 21Feb2021 // fixed code to handle depvar when using ts operators (e.g. L.depvar) 
*! 1.0.1 Ariel Linden 29Apr2023 // fixed regexm code to find "ef" of "eform"
*! 1.0.0 Ariel Linden 13Jan2021

program define xtitsa, sort
version 11.0

	syntax varlist(min=1 numeric ts fv) [if] [in] [iweight fweight pweight],	///
	TRPeriod(string)															///	
	[ TREAT(varname numeric)													///
 	SINGle																		///
	POSTTRend																	///
	FIGure   FIGure2(str asis)													///
	LOWess																		///
	CI																			///	
	REPLace PREfix(str) *]
	
	
	/* ensure that "eform" was not specified */
	if regexm("`0'", substr(" ef", 1, 3))==1 {
		di as err "eform cannot be used in xtitsa" 
		exit 198
	}
	
	gettoken dvar1 xvar : varlist
	
	di _n // new line between command line and tsset in output
	quietly {
		marksample touse
		count if `touse'
		if r(N) == 0 error 2000
		local N = r(N)
		replace `touse' = -`touse'

		/* check if data is tsset with panel and time var */
		/* -tsset- errors out if no time variable set */
		tsset
		local tvar `r(timevar)'
		local pvar `r(panelvar)'
		
		/* get format for timevar for output */
		* format specified for the timevar (used for lincom title and figure title)
		loc tsf `r(tsfmt)'
		* format used in regression output and parsing trperiod()
		if substr("`tsf'",2,1) == "t" {
			local tsfr = substr("`tsf'",1,3)
			local period = lower(substr("`tsf'", 3, 1))
		}
		else local tsfr `tsf'

		if "`pvar'" != "" & "`single'" == "" {
			if "`r(balanced)'" != "strongly balanced" {
				di as err "strong balance required"
				exit 498
			}
		}
		/* parse dates in trperiod() */
		tokenize "`trperiod'", parse(";")
		local done = 0
		local i = 0
		local count = 0
		while !`done' {  
			local ++i
			local next = "``i''"
			local done = ("`next'" == "")
			// keep dates only (exclude semicolon)
			if ("`next'" != ";") & (!`done') {
				local ++count
				local trp`count' = `period'(`next') 
				local trp `trp' `trp`count''
				local trperiod `trp'
			}  // end if
		} // end while
		/* sort the trperiods! */
		local trperiod : list sort local(trperiod)		

		/* check if trperiod is among tvars */
		levelsof `tvar' if `touse', local(levt)
		if !`: list trperiod in levt' {
			di as err "Treatment periods not found in time variable:" ///
			" check trperiod() and/or tsset settings"
			exit 498
		}
		
		* verify that treat is coded 1/0
		if "`treat'" != "" {
			tabulate `treat' if `touse' 
                if r(r) != 2 { 
                        di as err "`treat' must have exactly two values (coded 0 or 1)."
                exit 420  
                } 
                else if r(r) == 2 { 
                        capture assert inlist(`treat', 0, 1) if `touse' 
                        if _rc { 
                        di as err "`treat' must be coded as either 0 or 1."
                exit 450 
                        }
                }
		} //end treat


	 /********************* SET ANALYSIS TYPES ***********************************
	  *		  Type 1: Treatment group only in data set (single group ITSA)		 *
	  *		  Type 2: Treatment group amongst other data (single group ITSA)	 *
	  *		  Type 3: Multiple group analysis (treatment vs controls)			 *
	  ***************************************************************************/
		if "`treat'" == ""  &  "`single'" !="" {
			local atype = 1
		}
		else if "`treat'" != ""  &  "`single'" !="" {
			local atype = 2
		}
		else if "`treat'" != ""  &  "`single'" =="" {
			local atype = 3
		}

		/* drop program variables if option "replace" is chosen */
		if "`replace'" != "" {
			local itsavars : char _dta[`prefix'_itsavars]
			if "`itsavars'" != "" {
				foreach v of local itsavars {
					capture drop `v'
				}
			}
		}

		/* clone dvar and replace "." with "_" if dvar includes time series operator (e.g. l1. or d1.)  */
		if strpos("`dvar1'",".") != 0 {
			tempvar dvar2
			gen `dvar2' = `dvar1'
			local dvar = "_" + subinstr("`dvar1'",".","_",.)
			local dvar  `prefix'`dvar'
			rename `dvar2' `dvar'
		}
		else {
			tempvar dvar2
			gen `dvar2' = `dvar1'
			local dvar _`dvar1'
			local dvar  `prefix'`dvar'
			rename `dvar2' `dvar'
			local w : variable label `dvar1'
			if `"`w'"' != "" label variable `dvar' `"`w'"'
		}
				
	} // end quietly

	/*************************************************
	  TYPE 1 ANALYSIS: SINGLE GROUP IN DATA
	**************************************************/
	if `atype'==1 {
		quietly {
			bysort `touse' `pvar' (`tvar'): gen `prefix'_t = `tvar' - `tvar'[1] if `touse'
			local rhs `prefix'_t
	
			foreach t in `trperiod' {
				local tper = strofreal(`t',"`tsfr'")
				/* x will test change in level after intervention */
				gen `prefix'_x`tper' = `tvar' >= `t' if `touse'
				/* xt will test difference in pre-post slopes */
				gen `prefix'_x_t`tper' = (`tvar' - `t') * `prefix'_x`tper' if `touse'
				local rhs `rhs' `prefix'_x`tper' `prefix'_x_t`tper'
			}
		} // end quietly
			
		/* run xtgee */
		tsset
		xtgee `dvar' `rhs' `xvar'  if `touse' [`weight' `exp'], `options'
		
		/* generating CI values depending on whether the model was prais or GLM */
		if "`ci'" == "" {
			quietly predict `prefix'_s_`dvar'_pred if e(sample)
			local itsavars `dvar' `rhs' `prefix'_s_`dvar'_pred
			char def _dta[`prefix'_itsavars] "`itsavars'"
		}
		else {
			tempvar stdp lcl ucl
			quietly predict `prefix'_s_`dvar'_pred if e(sample)
			quietly predict `stdp' if e(sample), stdp
			local tz = abs(invnorm(1-(1-`=string(r(level))'/100)/2))	
			quietly gen `lcl' = `prefix'_s_`dvar'_pred - (`tz' * `stdp')
			quietly gen `ucl' = `prefix'_s_`dvar'_pred + (`tz' * `stdp')			
			local itsavars `dvar' `rhs' `prefix'_s_`dvar'_pred
			char def _dta[`prefix'_itsavars] "`itsavars'"			
		}		
		
		/* capture level specified in estimation model */
		local clv `=string(r(level))'
		local cil `=length("`clv'")'		

		/*********************************************************
		*  LINCOM: SINGLE GROUP SINGLE PANEL                     *
		**********************************************************/
		if "`posttrend'" != "" {

			local bexp "_b[`prefix'_t]"
	
			/* Start Loop over time */
			foreach t in `trperiod' {
				* format trperiod date for lincom output
				local tper = strofreal(`t',"`tsfr'")
				* format trperiod date for lincom title
				local tperl = strofreal(`t',"`tsf'")
				local bexp = "`bexp'+_b[`prefix'_x_t`tper']"
				qui lincom `"`bexp'"', level(`clv')
				qui return list
				local zp P>|z|
				di _newline(1)
				di in smcl in green _col(20) " Postintervention Linear Trend: `tperl'"  _newline
				di  "Treated: `bexp'"
				#delim ;
				di in smcl in gr "{hline 13}{c TT}{hline 64}"
				_newline "Linear Trend {c |}"
				_col(21) "Coef. "
				_col(29) "Std. Err."
				_col(44) "z"
				_col(49) "`zp'"
				_col(`=61-`cil'') `"[`clv'% Conf. Interval]"'
				_newline
				in gr in smcl "{hline 13}{c +}{hline 64}"
				_newline
				_col(1) "     Treated"  /* ARGUMENT */
				_col(14) "{c |}" in ye
				_col(17) %9.7g r(estimate)
				_col(28) %9.7g r(se)
				_col(38) %8.2f r(z)
				_col(46) %8.3f r(p)
				_col(58) %9.7g r(lb)
				_col(70) %9.7g r(ub)
				_newline
				in gr in smcl "{hline 13}{c BT}{hline 64}"
				;
				#delim cr
			}
		} /* END IF POSTTREND & LINCOM BLOCK */
		
		/*************************************************************
		 *                PLOT SECTION FOR TYPE 1                    *
		 *************************************************************/
		if `"`figure'`figure2'"' != "" {   /* Start Figure Loop */
			/* graph; get variable labels if they exist */
			local ydesc : var label `dvar'
			if `"`ydesc'"' == "" local ydesc "`dvar'"
			local tdesc : var label `tvar'
			if `"`tdesc'"' == "" local tdesc "`tvar'"

			local note "GEE model: family(`e(family)'), link(`e(link)'), correlation(`e(corr)')"
			
			/* Collapse actual & predicted for treated means over time */
			preserve
			collapse (mean) `dvar' `prefix'_s_`dvar'_pred `lcl' `ucl' ///
				if `touse' [`weight' `exp'], by(`tvar')
				
			/* CREATE PREDICTED VALUE FOR PLOTS */
			qui{
				tempvar ypred_t
				gen `ypred_t' = `prefix'_s_`dvar'_pred

				local tct: word count `trperiod'
				local tmax: word `tct' of `trperiod'
				local k = 0
					foreach t in `trperiod' {
						local k = `k' + 1
						tempvar tp_t`k' plt_t`k'
						if `k'== 1 {
							gen `tp_t`k'' = `ypred_t' if `tvar'<=`t' & e(sample)
							replace `tp_t`k''=. if `tvar'==`t'
							ipolate `tp_t`k'' `tvar' if `tvar' <=`t', gen(`plt_t`k'') epolate
						}
						if `k'> 1 & `k'<=`tct' {
							local klast = `k'-1
							local tlast: word `klast' of `trperiod'
							gen `tp_t`k'' = `ypred_t' if `tvar'>=`tlast' & `tvar'<=`t' & e(sample)
							replace `tp_t`k'' = . if `tvar'==`t'
							ipolate `tp_t`k'' `tvar' if `tvar'>=`tlast' & `tvar'<=`t', ///
							gen(`plt_t`k'') epolate
						}
						if `k' ==`tct' {
							tempvar pltx
							gen `pltx' = `ypred_t' if `tvar'>=`tmax' & e(sample)
						}
					}  /* end of TRPERIOD LOOP */
					
				/* CREATE CI VALUES FOR PLOTS */				
				if "`ci'" != "" {	
					tempvar lcl_t ucl_t
					gen `lcl_t' = `lcl'
					gen `ucl_t' = `ucl'			
					local tct: word count `trperiod'
					local tmax: word `tct' of `trperiod'
					local k = 0
					foreach t in `trperiod' {
						local k = `k' + 1
						tempvar lp_t`k' llt_t`k' up_t`k' ult_t`k'
						if `k'== 1 {
							gen `lp_t`k'' = `lcl_t' if `tvar'<=`t' & e(sample)
							replace `lp_t`k''=. if `tvar'==`t'
							ipolate `lp_t`k'' `tvar' if `tvar' <=`t', gen(`llt_t`k'') epolate
							gen `up_t`k'' = `ucl_t' if `tvar'<=`t' & e(sample)
							replace `up_t`k''=. if `tvar'==`t'
							ipolate `up_t`k'' `tvar' if `tvar' <=`t', gen(`ult_t`k'') epolate						
						}
						if `k'> 1 & `k'<=`tct' {
							local klast = `k'-1
							local tlast: word `klast' of `trperiod'
							gen `lp_t`k'' = `lcl_t' if `tvar'>=`tlast' & `tvar'<=`t' & e(sample)
							replace `lp_t`k'' = . if `tvar'==`t'
							ipolate `lp_t`k'' `tvar' if `tvar'>=`tlast' & `tvar'<=`t', gen(`llt_t`k'') epolate
							gen `up_t`k'' = `ucl_t' if `tvar'>=`tlast' & `tvar'<=`t' & e(sample)
							replace `up_t`k'' = . if `tvar'==`t'
							ipolate `up_t`k'' `tvar' if `tvar'>=`tlast' & `tvar'<=`t', gen(`ult_t`k'') epolate						
						}
						if `k' ==`tct' {
							tempvar lltx ultx
							gen `lltx' = `lcl_t' if `tvar'>=`tmax' & e(sample)
							gen `ultx' = `ucl_t' if `tvar'>=`tmax' & e(sample)						
						}
					}  /* end of TRPERIOD LOOP */
				}	// end CI						
	

				/* Set up Plot Variables */
				forvalues k = 1/`tct' {
					local plotvars `plotvars' `plt_t`k'' 
					local cpart `cpart' l
					local mspart `mspart' none
					local lblack `lblack' black
				}
				if "`ci'" != "" {
					forvalues k = 1/`tct' {
						local plotvarsL `plotvarsL' `llt_t`k'' 
						local lblue `lblue' blue
					}
					forvalues k = 1/`tct' {
						local plotvarsU `plotvarsU' `ult_t`k''
						local lblue `lblue' blue
					}
				} // end CI
			} /* end of quietly loop */
			
			/* connect and msymbol options (affects post-intervention periods) */
			local cpart c(. l `cpart')
			local lc lcolor(black `lblack' black)
			local mspart  ms(O none `mspart')
			local plotvars `plotvars' `pltx' 
		
			/* affects post-intervention periods */
			if "`ci'" != "" {
				local lc2 lcolor(blue `lblue' blue)
				local plotvarsL `plotvarsL' `lltx'
				local plotvarsU `plotvarsU' `ultx'
			}
		
			/* separate multiple trperiods for subtitle */
			foreach t in `trperiod' {
				local tper = strofreal(`t',"`tsf'")
				local tperlist `tperlist' `tper'
			}
			
	
			/* set up legend when lowess and/or CIs are specified */
			if "`lowess'" != "" {
				local low (lowess `dvar' `tvar' , lcolor(red))
				if "`ci'" != "" {
					local x = `tct' - 1	
					local act1 = `tct' + 5 + `x'
					local pred1 = `tct' + 6 + `x'
					local ci1 = 2
					local low1 = 1
					local lowleg subtitle("Intervention starts: `tperlist'") legend(rows(1) order(`act1' `pred1' `low1' `ci1') label(`act1' "Actual") ///
					label(`pred1' "Predicted") label(`low1' "Lowess") label(`ci1' "`clv'% CI"))),
				}
				if "`ci'" == "" {
					local lowleg subtitle("Intervention starts: `tperlist'") legend(rows(1) order(2 3 1) label(1 "Lowess") label(2 "Actual") label(3 "Predicted"))),
				}			
			} // end lowess

			else if "`lowess'" == "" {
				if "`ci'" != "" {
					local x = `tct' - 1	
					local act1 = `tct' + 4 + `x'
					local pred1 = `tct' + 5 + `x'
					local ci1 = 1
					local nolow subtitle("Intervention starts: `tperlist'") legend(rows(1) order(`act1' `pred1' `ci1') label(`act1' "Actual") ///
					label(`pred1' "Predicted") label(`ci1' "`clv'% CI"))),
				}
				if "`ci'" == "" {			
					local nolow subtitle("Intervention starts: `tperlist'") legend(rows(1) order(1 2) label(1 "Actual") label(2 "Predicted"))),
				}
			}	
			if "`ci'" != "" {
				local lcl (line `plotvarsL' `tvar' , `lc2') 
				local ucl (line `plotvarsU' `tvar' , `lc2') 	
			}

			#delim ;
			tw 
			`low'
			`lcl'
			`ucl'		
			(scatter  `dvar' `plotvars' `tvar' , `cpart' `mspart' `lc'
				xline(`trperiod', lpattern(shortdash) lcolor(black))
				mcolor(black)
				note(`"`note'"')
				ytitle("`ydesc'")
				xtitle("`tdesc'")
				title("`treatdesc'")
			`nolow'
			`lowleg'			
			`figure2'
			;
			#delim cr			
			
		}  /* End of Plot Loop */
		
	}  /* End OF TYPE 1 LOOP */				
				

	/*************************************************
	  TYPE 2 ANALYSIS: SINGLE GROUP MULTIPLE PANELS
	**************************************************/
	else if `atype'==2 {

		quietly {
			bysort `touse' `pvar' (`tvar'): gen `prefix'_t = `tvar' - `tvar'[1] if `touse'
			local rhs `prefix'_t // collating RHS variables

			foreach t in `trperiod' {
				local tper = strofreal(`t',"`tsfr'")
				/* x will test change in level after intervention */
				gen `prefix'_x`tper' = `tvar' >= `t' if `touse'
				/* xt will test difference in pre-post slopes */
				gen `prefix'_x_t`tper' = (`tvar' - `t') * `prefix'_x`tper' if `touse'
				local rhs `rhs' `prefix'_x`tper' `prefix'_x_t`tper'
			}
		} // end quietly

		/* run xtgee */
		tsset
		xtgee `dvar' `rhs' `xvar' if `touse' & `treat'==1 [`weight' `exp'], `options'
		
		/* generating CI values depending on whether the model was prais or GLM */
		if "`ci'" == "" {
			quietly predict `prefix'_s_`dvar'_pred if e(sample)
			local itsavars `dvar' `rhs' `prefix'_s_`dvar'_pred
			char def _dta[`prefix'_itsavars] "`itsavars'"
		}
		else {
			tempvar stdp lcl ucl
			quietly predict `prefix'_s_`dvar'_pred if e(sample)
			quietly predict `stdp' if e(sample), stdp
			local tz = abs(invnorm(1-(1-`=string(r(level))'/100)/2))	
			quietly gen `lcl' = `prefix'_s_`dvar'_pred - (`tz' * `stdp')
			quietly gen `ucl' = `prefix'_s_`dvar'_pred + (`tz' * `stdp')			
			local itsavars `dvar' `rhs' `prefix'_s_`dvar'_pred
			char def _dta[`prefix'_itsavars] "`itsavars'"			
		}		
		
		/* capture level specified in estimation model */
		local clv `=string(r(level))'
		local cil `=length("`clv'")'	
		
		/**************************************************************
		*  LINCOM: SINGLE GROUP MULTIPLE PANELS                     *
		***************************************************************/
		if "`posttrend'" != ""{

			local bexp "_b[`prefix'_t]"
			
			/* Start Loop over time */
			foreach t in `trperiod' {
				* format trperiod date for lincom output
				local tper = strofreal(`t',"`tsfr'")
				* format trperiod date for lincom title
				local tperl = strofreal(`t',"`tsf'")
				local bexp = "`bexp'+_b[`prefix'_x_t`tper']"
				qui lincom `"`bexp'"', level(`clv')
				qui return list
				local zp P>|z|
				di _newline(1)
				di in smcl in green _col(20) " Postintervention Linear Trend: `tperl'"  _newline
				di  "Treated: `bexp'"
				#delim ;
				di in smcl in gr "{hline 13}{c TT}{hline 64}"
				_newline "Linear Trend {c |}"
				_col(21) "Coef. "
				_col(29) "Std. Err."
				_col(44) "z"
				_col(49) "`zp'"
				_col(`=61-`cil'') `"[`clv'% Conf. Interval]"'
				_newline
				in gr in smcl "{hline 13}{c +}{hline 64}"
				_newline
				_col(1) "     Treated"  /* ARGUMENT */
				_col(14) "{c |}" in ye
				_col(17) %9.7g r(estimate)
				_col(28) %9.7g r(se)
				_col(38) %8.2f r(z)
				_col(46) %8.3f r(p)
				_col(58) %9.7g r(lb)
				_col(70) %9.7g r(ub)
				_newline
				in gr in smcl "{hline 13}{c BT}{hline 64}"
				;
				#delim cr
			}
		} /* END IF POSTTREND & LINCOM BLOCK */

		/************************************************
		*             PLOT SECTION FOR TYPE 2           *
		*************************************************/
		if `"`figure'`figure2'"' != "" {   /* Start Figure Loop */
			/* graph; get variable labels if they exist */
			local ydesc : var label `dvar'
			if `"`ydesc'"' == "" local ydesc "`dvar'"
			local tdesc : var label `tvar'
			if `"`tdesc'"' == "" local tdesc "`tvar'"
			local treatdesc: var label `treat'
			if "`treatdesc'" == "" local treatdesc "Treated"
			
			local note "GEE model: family(`e(family)'), link(`e(link)'), correlation(`e(corr)')"
			
			/* Collapse predicted for treated means over time */
			preserve
			collapse (mean)  `dvar' `prefix'_s_`dvar'_pred `lcl' `ucl' ///
				if `touse' & `treat' == 1 [`weight' `exp'], by(`tvar')
				
			/* CREATE PREDICTED VALUE FOR PLOTS */
			qui{
				tempvar ypred_t
				gen `ypred_t' = `prefix'_s_`dvar'_pred

				local tct: word count `trperiod'
				local tmax: word `tct' of `trperiod'
				local k = 0
					foreach t in `trperiod' {
						local k = `k' + 1
						tempvar tp_t`k' plt_t`k'
						if `k'== 1 {
							gen `tp_t`k'' = `ypred_t' if `tvar'<=`t' & e(sample)
							replace `tp_t`k''=. if `tvar'==`t'
							ipolate `tp_t`k'' `tvar' if `tvar' <=`t', gen(`plt_t`k'') epolate
						}
						if `k'> 1 & `k'<=`tct' {
							local klast = `k'-1
							local tlast: word `klast' of `trperiod'
							gen `tp_t`k'' = `ypred_t' if `tvar'>=`tlast' & `tvar'<=`t' & e(sample)
							replace `tp_t`k'' = . if `tvar'==`t'
							ipolate `tp_t`k'' `tvar' if `tvar'>=`tlast' & `tvar'<=`t', ///
							gen(`plt_t`k'') epolate
						}
						if `k' ==`tct' {
							tempvar pltx
							gen `pltx' = `ypred_t' if `tvar'>=`tmax' & e(sample)
						}
					}  /* end of TRPERIOD LOOP */
					
				/* CREATE CI VALUES FOR PLOTS */				
				if "`ci'" != "" {	
					tempvar lcl_t ucl_t
					gen `lcl_t' = `lcl'
					gen `ucl_t' = `ucl'			
					local tct: word count `trperiod'
					local tmax: word `tct' of `trperiod'
					local k = 0
					foreach t in `trperiod' {
						local k = `k' + 1
						tempvar lp_t`k' llt_t`k' up_t`k' ult_t`k'
						if `k'== 1 {
							gen `lp_t`k'' = `lcl_t' if `tvar'<=`t' & e(sample)
							replace `lp_t`k''=. if `tvar'==`t'
							ipolate `lp_t`k'' `tvar' if `tvar' <=`t', gen(`llt_t`k'') epolate
							gen `up_t`k'' = `ucl_t' if `tvar'<=`t' & e(sample)
							replace `up_t`k''=. if `tvar'==`t'
							ipolate `up_t`k'' `tvar' if `tvar' <=`t', gen(`ult_t`k'') epolate						
						}
						if `k'> 1 & `k'<=`tct' {
							local klast = `k'-1
							local tlast: word `klast' of `trperiod'
							gen `lp_t`k'' = `lcl_t' if `tvar'>=`tlast' & `tvar'<=`t' & e(sample)
							replace `lp_t`k'' = . if `tvar'==`t'
							ipolate `lp_t`k'' `tvar' if `tvar'>=`tlast' & `tvar'<=`t', gen(`llt_t`k'') epolate
							gen `up_t`k'' = `ucl_t' if `tvar'>=`tlast' & `tvar'<=`t' & e(sample)
							replace `up_t`k'' = . if `tvar'==`t'
							ipolate `up_t`k'' `tvar' if `tvar'>=`tlast' & `tvar'<=`t', gen(`ult_t`k'') epolate						
						}
						if `k' ==`tct' {
							tempvar lltx ultx
							gen `lltx' = `lcl_t' if `tvar'>=`tmax' & e(sample)
							gen `ultx' = `ucl_t' if `tvar'>=`tmax' & e(sample)						
						}
					}  /* end of TRPERIOD LOOP */
				}	// end CI						
	

				/* Set up Plot Variables */
				forvalues k = 1/`tct' {
					local plotvars `plotvars' `plt_t`k'' 
					local cpart `cpart' l
					local mspart `mspart' none
					local lblack `lblack' black
				}
				if "`ci'" != "" {
					forvalues k = 1/`tct' {
						local plotvarsL `plotvarsL' `llt_t`k'' 
						local lblue `lblue' blue
					}
					forvalues k = 1/`tct' {
						local plotvarsU `plotvarsU' `ult_t`k''
						local lblue `lblue' blue
					}
				} // end CI
			} /* end of quietly loop */
			
			/* connect and msymbol options (affects post-intervention periods) */
			local cpart c(. l `cpart')
			local lc lcolor(black `lblack' black)
			local mspart  ms(O none `mspart')
			local plotvars `plotvars' `pltx' 
		
			/* affects post-intervention periods */
			if "`ci'" != "" {
				local lc2 lcolor(blue `lblue' blue)
				local plotvarsL `plotvarsL' `lltx'
				local plotvarsU `plotvarsU' `ultx'
			}
		
			/* separate multiple trperiods for subtitle */
			foreach t in `trperiod' {
				local tper = strofreal(`t',"`tsf'")
				local tperlist `tperlist' `tper'
			}
			
			/* set up legend when lowess and/or CIs are specified */
			if "`lowess'" != "" {
				local low (lowess `dvar' `tvar' , lcolor(red))
				if "`ci'" != "" {
					local x = `tct' - 1	
					local act1 = `tct' + 5 + `x'
					local pred1 = `tct' + 6 + `x'
					local ci1 = 2
					local low1 = 1
					local lowleg subtitle("Intervention starts: `tperlist'") legend(rows(1) order(`act1' `pred1' `low1' `ci1') label(`act1' "Actual") ///
					label(`pred1' "Predicted") label(`low1' "Lowess") label(`ci1' "`clv'% CI"))),
				}
				if "`ci'" == "" {
					local lowleg subtitle("Intervention starts: `tperlist'") legend(rows(1) order(2 3 1) label(1 "Lowess") label(2 "Actual") label(3 "Predicted"))),
				}			
			} // end lowess

			else if "`lowess'" == "" {
				if "`ci'" != "" {
					local x = `tct' - 1	
					local act1 = `tct' + 4 + `x'
					local pred1 = `tct' + 5 + `x'
					local ci1 = 1
					local nolow subtitle("Intervention starts: `tperlist'") legend(rows(1) order(`act1' `pred1' `ci1') label(`act1' "Actual") ///
					label(`pred1' "Predicted") label(`ci1' "`clv'% CI"))),
				}
				if "`ci'" == "" {			
					local nolow subtitle("Intervention starts: `tperlist'") legend(rows(1) order(1 2) label(1 "Actual") label(2 "Predicted"))),
				}
			}	
			if "`ci'" != "" {
				local lcl (line `plotvarsL' `tvar' , `lc2') 
				local ucl (line `plotvarsU' `tvar' , `lc2') 	
			}

			#delim ;
			tw 
			`low'
			`lcl'
			`ucl'		
			(scatter  `dvar' `plotvars' `tvar' , `cpart' `mspart' `lc'
				xline(`trperiod', lpattern(shortdash) lcolor(black))
				mcolor(black)
				note(`"`note'"')
				ytitle("`ydesc'")
				xtitle("`tdesc'")
				title("`treatdesc'")
			`nolow'
			`lowleg'			
			`figure2'
			;
			#delim cr			
			
		}  /* End of Plot Loop */
		
	}  /* End OF TYPE 2 LOOP */							
				
	/*************************************************
	TYPE 3 ANALYSIS: MULTIPLE GROUP ANALYSIS
	**************************************************/
	else if `atype'==3 {
		/* variables based on trperiod */
  		quietly {
			bysort `touse' `pvar' (`tvar'): gen `prefix'_t = `tvar' - `tvar'[1] if `touse'
			gen byte `prefix'_z = `treat' if `touse'
			gen `prefix'_z_t = `prefix'_z * `prefix'_t if `touse'
			local rhs `prefix'_t `prefix'_z `prefix'_z_t

			foreach t in `trperiod' {
				local tper = strofreal(`t',"`tsfr'")
				/* x will test change in level after intervention - controls */
				gen `prefix'_x`tper' = `tvar' >= `t' if `touse'
				/* xt will test difference in pre-post slopes - controls */
				gen `prefix'_x_t`tper' = (`tvar' - `t') * `prefix'_x`tper' if `touse'
				/* zx will test difference between groups in level after intervention */
				gen `prefix'_z_x`tper' = `prefix'_z * `prefix'_x`tper' if `touse'
				/* zxt will test difference between groups in pre-post slopes */
				gen `prefix'_z_x_t`tper' = `prefix'_x_t`tper' * `prefix'_z if `touse'
				local rhs `rhs' `prefix'_x`tper' `prefix'_x_t`tper' `prefix'_z_x`tper' `prefix'_z_x_t`tper'
			}
		} //end quietly
		
		/* run xtgee */
		tsset
		xtgee `dvar' `rhs' `xvar' if `touse' [`weight' `exp'], `options'

		quietly predict `prefix'_m_`dvar'_pred // consider adding "if e(sample)"
		local itsavars `dvar' `rhs' `prefix'_m_`dvar'_pred
		char def _dta[`prefix'_itsavars] "`itsavars'"
		
		/* generating CI values */
		if "`ci'" != "" {
			tempvar stdp lcl ucl
			quietly predict `stdp' if e(sample), stdp
			local tz = abs(invnorm(1-(1-`=string(r(level))'/100)/2))	
			quietly gen `lcl' = `prefix'_m_`dvar'_pred - (`tz' * `stdp')
			quietly gen `ucl' = `prefix'_m_`dvar'_pred + (`tz' * `stdp')			
		}	
		local itsavars `dvar' `rhs' `prefix'_m_`dvar'_pred
		char def _dta[`prefix'_itsavars] "`itsavars'"
		
		/* capture level specified in estimation model */
		local clv `=string(r(level))'
		local cil `=length("`clv'")'		

		/*******************************************
		 LINCOM:   MULTIPLE GROUP COMPARISON       *
		********************************************/
		if "`posttrend'" != "" {
		
			/* Start Loop over time */
         	local btexp "_b[`prefix'_t] + _b[`prefix'_z_t]"
            local bcexp "_b[`prefix'_t]"
           	local bdexp "_b[_z_t]"

			foreach t in `trperiod' {
				* format trperiod date for lincom output
				local tper = strofreal(`t',"`tsfr'")
				* format trperiod date for lincom title
				local tperl = strofreal(`t',"`tsf'")
				di _newline(1)
				di in smcl in green _col(20) "Comparison of Linear Postintervention Trends: `tperl'"
				di _newline

				local btexp "`btexp' + _b[`prefix'_x_t`tper'] + _b[`prefix'_z_x_t`tper']"
				local bcexp "`bcexp' + _b[`prefix'_x_t`tper']"
  				local bdexp "`bdexp' +  _b[`prefix'_z_x_t`tper']"

				di  "Treated    : `btexp'"
				di  "Controls   : `bcexp'"
		    	di  "Difference : `bdexp'"

				/* TREATED */
				qui lincom `"`btexp'"', level(`clv')
				qui return list
				#delim ;

				di in smcl in gr "{hline 13}{c TT}{hline 64}"
				_newline "Linear Trend {c |}"
				_col(21) "Coef. "
				_col(29) "Std. Err."
				_col(44) "z"
				_col(49) "P>|z|"
				_col(`=61-`cil'') `"[`clv'% Conf. Interval]"'
				_newline
				in gr in smcl "{hline 13}{c +}{hline 64}"
				_newline

				_col(1) "     Treated"
				_col(14) "{c |}" in ye
				_col(17) %9.7g r(estimate)
				_col(28) %9.7g r(se)
				_col(38) %8.2f r(z)
				_col(46) %8.3f r(p)
				_col(58) %9.7g r(lb)
				_col(70) %9.7g r(ub)
				;

				#delim cr

				/* CONTROLS */
				qui lincom `"`bcexp'"', level(`clv')
				qui return list
				#delim ;
				di  in smcl in gr
				_col(1) "    Controls"
				_col(14) "{c |}" in ye
				_col(17) %9.7g r(estimate)
				_col(28) %9.7g r(se)
				_col(38) %8.2f r(z)
				_col(46) %8.3f r(p)
				_col(58) %9.7g r(lb)
				_col(70) %9.7g r(ub);
				#delim cr
				di in gr in smcl "{hline 13}{c +}{hline 64}"

				/* DIFFERENCE */
				qui lincom `"`bdexp'"', level(`clv')
				qui return list
				#delim ;
				di  in smcl in gr
				_col(1) "  Difference"
				_col(14) "{c |}" in ye
				_col(17) %9.7g r(estimate)
				_col(28) %9.7g r(se)
				_col(38) %8.2f r(z)
				_col(46) %8.3f r(p)
				_col(58) %9.7g r(lb)
				_col(70) %9.7g r(ub);
				di in smcl in gr "{hline 13}{c BT}{hline 64}";
				#delim cr
			} /* End of TRPERIOD LOOP */
		}  /* END OF two-group posttrend LINCOM */


		/************************************************
		 *             PLOT SECTION FOR TYPE 3          *
		 ************************************************/
		if `"`figure'`figure2'"' != ""{   /* Start Figure Loop */

			/* graph; get variable labels if they exist */
			local ydesc : var label `dvar'
					if `"`ydesc'"' == "" local ydesc "`dvar'"
			local tdesc : var label `tvar'
			if `"`tdesc'"' == "" local tdesc "`tvar'"

			local treatdesc: var label `treat'
			if "`treatdesc'" == "" local treatdesc "Treated"

			local note "GEE model: family(`e(family)'), link(`e(link)'), correlation(`e(corr)')"
			
			 preserve

			 /* Collapse actual & predicted for treat/control means */
			collapse (mean) `dvar' `prefix'_m_`dvar'_pred `lcl' `ucl' ///
				if `touse' `if2' [`weight' `exp'], by(`tvar' `prefix'_z)

			local istreat   `prefix'_z==1
			local iscontrol `prefix'_z==0

			/* Start quietly loop */			
			qui {   
				
				tempvar ypred_t ypred_c
				gen `ypred_t' =  `prefix'_m_`dvar'_pred if `istreat'
				gen `ypred_c' =  `prefix'_m_`dvar'_pred if `iscontrol'
				
				if "`ci'" != "" {
					tempvar lcl_t ucl_t lcl_c ucl_c
					gen `lcl_t' = `lcl' if `istreat'
					gen `ucl_t' = `ucl' if `istreat'	
					gen `lcl_c' = `lcl' if `iscontrol'					
					gen `ucl_c' = `ucl' if `iscontrol'					
				}
 
				
				/* TREATMENT GROUP */
				/* PREDICT no xvars */
				if "`xvar'" == "" {   
					local tct: word count `trperiod'
					local tmax: word `tct' of `trperiod'

					local k = 0
					foreach t in `trperiod' {
						local k = `k' + 1
						tempvar tp_t`k' plt_t`k'
						if `k'== 1 {
							gen `tp_t`k'' = `ypred_t' if `tvar'<=`t' & `istreat'
							replace `tp_t`k''=. if `tvar'==`t' & `istreat'
							ipolate `tp_t`k'' `tvar' if `tvar' <=`t' & `istreat', gen(`plt_t`k'') epolate
						}
						if `k'> 1 & `k'<=`tct' {
							local klast = `k'-1
							local tlast: word `klast' of `trperiod'
							gen `tp_t`k'' = `ypred_t' if `tvar'>=`tlast' & `tvar'<=`t' & `istreat'
							replace `tp_t`k'' = . if `tvar'==`t' & `istreat'
							ipolate `tp_t`k'' `tvar' if `tvar'>=`tlast' & `tvar'<=`t' & `istreat', gen(`plt_t`k'') epolate
						}
						if `k' ==`tct' {
							tempvar pltx_t
							gen `pltx_t' = `ypred_t' if `tvar'>=`tmax' &  `istreat'
						}
					} /* end "predict" trperiod loop - treatment */
					
	
					/* CREATE CI VALUES FOR PLOTS - TREATMENT */				
					if "`ci'" != "" {	
						local tct: word count `trperiod'
						local tmax: word `tct' of `trperiod'
						local k = 0
						foreach t in `trperiod' {
							local k = `k' + 1
							tempvar lp_t`k' llt_t`k' up_t`k' ult_t`k'
							if `k'== 1 {
								gen `lp_t`k'' = `lcl_t' if `tvar'<=`t' & `istreat'
								replace `lp_t`k''=. if `tvar'==`t' & `istreat'
								ipolate `lp_t`k'' `tvar' if `tvar' <=`t' & `istreat', gen(`llt_t`k'') epolate
								gen `up_t`k'' = `ucl_t' if `tvar'<=`t' & `istreat'
								replace `up_t`k''=. if `tvar'==`t' & `istreat'
								ipolate `up_t`k'' `tvar' if `tvar' <=`t' & `istreat', gen(`ult_t`k'') epolate						
							}
							if `k'> 1 & `k'<=`tct' {
								local klast = `k'-1
								local tlast: word `klast' of `trperiod'
								gen `lp_t`k'' = `lcl_t' if `tvar'>=`tlast' & `tvar'<=`t' & `istreat'
								replace `lp_t`k'' = . if `tvar'==`t'
								ipolate `lp_t`k'' `tvar' if `tvar'>=`tlast' & `tvar'<=`t' & `istreat', gen(`llt_t`k'') epolate
								gen `up_t`k'' = `ucl_t' if `tvar'>=`tlast' & `tvar'<=`t' & `istreat'
								replace `up_t`k'' = . if `tvar'==`t' & `istreat'
								ipolate `up_t`k'' `tvar' if `tvar'>=`tlast' & `tvar'<=`t' & `istreat', gen(`ult_t`k'') epolate						
							}
							if `k' ==`tct' {
								tempvar lltx ultx
								gen `lltx' = `lcl_t' if `tvar'>=`tmax' & `istreat'
								gen `ultx' = `ucl_t' if `tvar'>=`tmax' & `istreat'						
							}
						}  /* end of TRPERIOD LOOP */
					}	// end CI	
				

					/* Set up plot variables for Treated */
					forvalues k = 1/`tct' {
						local plotvars_t `plotvars_t'  `plt_t`k''
						local cpart `cpart' l
						local mspart `mspart' none
						local lblack `lblack' black
						local mblack `mblack' black
					}

					/* connect and msymbol options */
					local cpart c(. l `cpart')
					local lc lcolor(black `lblack' black)
					local mc mcolor(black `mblack' black)

					local tmspart  ms(O none `mspart')
					local plotvars_t `plotvars_t' `pltx_t'		
				
					if "`ci'" != "" {
						forvalues k = 1/`tct' {
							local plotvars_t_L `plotvars_t_L' `llt_t`k'' 
							local lblue `lblue' blue
						}
						forvalues k = 1/`tct' {
							local plotvars_t_U `plotvars_t_U' `ult_t`k''
							local lblue `lblue' blue
						}
					} // end CI

					/* affects post-intervention periods */
					if "`ci'" != "" {
						local lc2 lcolor(blue `lblue' blue)
						local plotvars_t_L `plotvars_t_L' `lltx'
						local plotvars_t_U `plotvars_t_U' `ultx'
					}
					
					/* New CONTROLS plot section */
					/* PREDICT no xvars */
					local k = 0
					foreach t in `trperiod' {
						local k = `k' + 1
						tempvar tp_c`k' plt_c`k'
						if `k'== 1 {
							gen `tp_c`k'' = `ypred_c' if `tvar'<=`t' & `iscontrol'
							replace `tp_c`k''=. if `tvar'==`t' & `iscontrol'
							ipolate `tp_c`k'' `tvar' if `tvar' <=`t' & `iscontrol', gen(`plt_c`k'') epolate
						}
						if `k'> 1 & `k'<=`tct' {
							local klast = `k'-1
							local tlast: word `klast' of `trperiod'
							gen `tp_c`k'' = `ypred_c' if `tvar'>=`tlast' & `tvar'<=`t' & `iscontrol'
							replace `tp_c`k'' = . if `tvar'==`t' & `iscontrol'
							ipolate `tp_c`k'' `tvar' if `tvar'>=`tlast' & `tvar'<=`t' & `iscontrol', gen(`plt_c`k'') epolate
						}
						if `k' ==`tct' {
							tempvar pltx_c
							gen `pltx_c' = `ypred_c' if `tvar'>=`tmax' &  `iscontrol'
						}
					} /* end trperiod loop - controls */
					
					/* CREATE CI VALUES FOR PLOTS - CONTROLS */				
					if "`ci'" != "" {	
						local tct: word count `trperiod'
						local tmax: word `tct' of `trperiod'
						local k = 0
						foreach t in `trperiod' {
							local k = `k' + 1
							tempvar lp_c`k' llt_c`k' up_c`k' ult_c`k'
							if `k'== 1 {
								gen `lp_c`k'' = `lcl_c' if `tvar'<=`t' & `iscontrol'
								replace `lp_c`k''=. if `tvar'==`t' & `iscontrol'
								ipolate `lp_c`k'' `tvar' if `tvar' <=`t' & `iscontrol', gen(`llt_c`k'') epolate
								gen `up_c`k'' = `ucl_c' if `tvar'<=`t' & `iscontrol'
								replace `up_c`k''=. if `tvar'==`t' & `iscontrol'
								ipolate `up_c`k'' `tvar' if `tvar' <=`t' & `iscontrol', gen(`ult_c`k'') epolate						
							}
							if `k'> 1 & `k'<=`tct' {
								local klast = `k'-1
								local tlast: word `klast' of `trperiod'
								gen `lp_c`k'' = `lcl_c' if `tvar'>=`tlast' & `tvar'<=`t' & `iscontrol'
								replace `lp_c`k'' = . if `tvar'==`t'
								ipolate `lp_c`k'' `tvar' if `tvar'>=`tlast' & `tvar'<=`t' & `iscontrol', gen(`llt_c`k'') epolate
								gen `up_c`k'' = `ucl_c' if `tvar'>=`tlast' & `tvar'<=`t' & `iscontrol'
								replace `up_c`k'' = . if `tvar'==`t' & `iscontrol'
								ipolate `up_c`k'' `tvar' if `tvar'>=`tlast' & `tvar'<=`t' & `iscontrol', gen(`ult_c`k'') epolate						
							}
							if `k' ==`tct' {
								tempvar llcon ulcon
								gen `llcon' = `lcl_c' if `tvar'>=`tmax' & `iscontrol'
								gen `ulcon' = `ucl_c' if `tvar'>=`tmax' & `iscontrol'						
							}
						}  /* end of TRPERIOD LOOP */
					}	// end CI	

			
					/* Set up plot variables - CONTROLS */
					forvalues k = 1/`tct' {
					local plotvars_c `plotvars_c' `plt_c`k''
					local clp `clp' dash
					}

					/* connect and msymbol options for controls */
					local cmspart  ms(Oh `mspart' none)
					local clp lpattern(blank `clp' dash)

					local plotvars_c `plotvars_c' `pltx_c'
					
					if "`ci'" != "" {
						forvalues k = 1/`tct' {
							local plotvars_c_L `plotvars_c_L' `llt_c`k'' 
							local lgreen `lgreen' green
						}
						forvalues k = 1/`tct' {
							local plotvars_c_U `plotvars_c_U' `ult_c`k''
							local lgreen `lgreen' green
						}
					} // end CI

					/* affects post-intervention periods */
					if "`ci'" != "" {
						local lc3 lcolor(green `lgreen' green)
						local plotvars_c_L `plotvars_c_L' `llcon'
						local plotvars_c_U `plotvars_c_U' `ulcon'
					}					
				} /* end no xvars  */				
				
				/* if xvars */
				if "`xvar'" != "" {   
					local plotvars_t `ypred_t'
					local plotvars_c `ypred_c'
					local plotvars_c_L `lcl_c' 
					local plotvars_c_U `ucl_c'
					local plotvars_t_L `lcl_t' 
					local plotvars_t_U `ucl_t'
					local lc2 lcolor(blue `lblue' blue)					
					local lc3 lcolor(green `lgreen' green)
				}
				tempvar dvar_t dvar_c
				gen `dvar_t' = `dvar' if `istreat'
				gen `dvar_c' = `dvar' if `iscontrol'

			/* separate multiple trperiods for subtitle */
			foreach t in `trperiod' {
				local tper = strofreal(`t',"`tsf'")
				local tperlist `tperlist' `tper'
			}
			
			#delim ;
			 /* Titles for Two-Group Comparison */
			local titlesec
			ytitle("`ydesc'")
			xtitle("`tdesc'")
			title("`treatdesc' and Average of Controls")
			subtitle("Intervention starts: `tperlist'")
			;
			#delim cr
			
			if "`ci'" != "" {
				local lclt (line `plotvars_t_L' `tvar', `lc2') 
				local uclt (line `plotvars_t_U' `tvar', `lc2')
				local lclc (line `plotvars_c_L' `tvar', `lc3') 
				local uclc (line `plotvars_c_U' `tvar', `lc3')				
			}
			
			if "`lowess'" != "" {
				local lowt (lowess `dvar_t'  `tvar', lcolor(red)) 
				local lowc (lowess `dvar_c'  `tvar', lcolor(orange))
			}	
			
			
		} // end quietly	
			
			/* if no covariates */
			if "`xvar'" == "" {
				/* set up legend when lowess and/or CIs are specified */
				if "`lowess'" != "" {
					local lowt (lowess `dvar_t'  `tvar', lcolor(red)) 
					local lowc (lowess `dvar_c'  `tvar', lcolor(orange))
					if "`ci'" == "" {
						local ctrl1 = `tct' + 3				
						local ctrl2 = `tct' + 4	
						local low1 = `ctrl2' + `tct' + 1
						local low2 = `ctrl2' + `tct' + 2
						local lowleg subtitle("Intervention starts: `tperlist'") legend(rows(2) order(- "`treatdesc': " 1 2 `low1' - "Controls average:" `ctrl1' `ctrl2' `low2') ///
							label(1 "Actual") label(2 "Predicted") label(`ctrl1' "Actual") label(`ctrl2' "Predicted") ///					
							label(`low1' "Lowess") label(`low2' "Lowess") symxsize(8))
					}
					if "`ci'" != "" {
						local x = `tct' - 1	
						local ctrl1 = `tct' + 3				
						local ctrl2 = `tct' + 4	
						local low1 = `ctrl2' + `tct' + 1
						local low2 = `ctrl2' + `tct' + 2
						local cl1 = `low1' + 2
						local cl2 = `tct' + `low2' + (7 + `x')
						local lowleg subtitle("Intervention starts: `tperlist'") legend(rows(2) order(- "`treatdesc': " 1 2 `low1' `cl1' - "Controls average:" `ctrl1' `ctrl2' `low2' `cl2') ///
							label(1 "Actual") label(2 "Predicted") label(`ctrl1' "Actual") label(`ctrl2' "Predicted") ///					
							label(`low1' "Lowess") label(`low2' "Lowess") label(`cl1' "`clv'% CI") label(`cl2' "`clv'% CI") symxsize(5))
					}
				} // end yes lowess
				
				if "`lowess'" == "" {
					if "`ci'" == "" {
						local ctrl1 = `tct' + 3				
						local ctrl2 = `tct' + 4	
						local lowleg subtitle("Intervention starts: `tperlist'") legend(rows(2) order(- "`treatdesc': " 1 2 - "Controls average:" `ctrl1' `ctrl2') ///
							label(1 "Actual") label(2 "Predicted") label(`ctrl1' "Actual") label(`ctrl2' "Predicted") symxsize(8))					
					}
					if "`ci'" != "" {
						local ctrl1 = `tct' + 3				
						local ctrl2 = `tct' + 4	
						local cl1 = `ctrl2' + `tct' + 1
						local cl2 = `tct' + `ctrl1' + `ctrl2' + 4						
						local lowleg subtitle("Intervention starts: `tperlist'") legend(rows(2) order(- "`treatdesc': " 1 2 `cl1' - "Controls average:" `ctrl1' `ctrl2' `cl2') ///
							label(1 "Actual") label(2 "Predicted") label(`ctrl1' "Actual") label(`ctrl2' "Predicted") ///					
							label(`cl1' "`clv'% CI") label(`cl2' "`clv'% CI") symxsize(8))
					}
				} // end no lowess
			
				// * graph it - no xvars *//
				twoway ///
					(scatter  `dvar_t' `plotvars_t' `tvar', `cpart' `tmspart' `lc' `mc') ///
					(scatter  `dvar_c' `plotvars_c' `tvar', `cpart' `cmspart' `lc' `mc' `clp') ///
					`lowt' ///
					`lowc' ///
					`lclt' ///
					`uclt' ///	
					`lclc' ///
					`uclc' ///	
					, xline(`trperiod', lpattern(shortdash) lcolor(black)) ///
					`lowleg' ///
					 `titlesec' note(`"`note'"') `figure2'
			
			} // end no xvars

			/* with xvars */
			if "`xvar'" != "" {
				/* set up legend when lowess and/or CIs are specified */
				if "`lowess'" != "" {
					local lowt (lowess `dvar_t'  `tvar', lcolor(red)) 
					local lowc (lowess `dvar_c'  `tvar', lcolor(orange))
					if "`ci'" == "" {
						local lowleg subtitle("Intervention starts: `tperlist'") legend(rows(2) order(- "`treatdesc': " 1 2 5 - "Controls average:" 3 4 6) ///
							label(1 "Actual") label(2 "Predicted") label(3 "Actual") ///
							label(4 "Predicted") label(5 "Lowess") label(6 "Lowess") symxsize(8))
					} // end no ci
					
					if "`ci'" != "" {
						local lowleg subtitle("Intervention starts: `tperlist'") legend(rows(2) order(- "`treatdesc': " 1 2 5 7 - "Controls average:" 3 4 6 9) ///
							label(1 "Actual") label(2 "Predicted") label(3 "Actual") label(4 "Predicted") ///					
							label(5 "Lowess") label(6 "Lowess") label(7 "`clv'% CI") label(9 "`clv'% CI") symxsize(5))
					} // end yes ci
				} // end yes lowess			

				if "`lowess'" == "" {
					if "`ci'" == "" {
						local lowleg subtitle("Intervention starts: `tperlist'") legend(rows(2) order(- "`treatdesc': " 1 2 - "Controls average:" 3 4) ///
							label(1 "Actual") label(2 "Predicted") label(3 "Actual") label(4 "Predicted") symxsize(8))					
					}
					if "`ci'" != "" {
						local lowleg subtitle("Intervention starts: `tperlist'") legend(rows(2) order(- "`treatdesc': " 1 2 5 - "Controls average:" 3 4 7) ///
							label(1 "Actual") label(2 "Predicted") label(3 "Actual") label(4 "Predicted") ///					
							label(5 "`clv'% CI") label(7 "`clv'% CI") symxsize(8))
					}
				} // end no lowess				
			
				
				// * graph it - xvars *//		
				twoway ///
					(scatter `dvar_t' `ypred_t' `dvar_c' `ypred_c'  `tvar', c(. l . l) ms(O none Oh none) mcolor(black black black black) ///
						lcolor(black black black black) lpattern(blank solid blank dash) xline(`trperiod', lpattern(shortdash) lcolor(black))) ///
					`lowt' ///
					`lowc' ///
					`lclt' ///
					`uclt' ///	
					`lclc' ///
					`uclc' ///	
					, `lowleg' ///
					 `titlesec' note(`"`note'"') `figure2'	
					 
			} // end xvars
		}   /* End of Figure Block */
	}   /* End of Type 3 */
			
end

