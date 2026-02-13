*! 3.7.0 Ariel Linden 12Jan2026						// streamlined graphing section of MG-ITSA. Now when xvar is specified, graph will be consistent with SG-ITSA
*! 3.6.2 Ariel Linden 06Jan2026						// fixed bug in multigroup graph with xvars without CI.
*! 3.6.1 Ariel Linden 16Dec2025						// fixed CI lines on graphs to consistently display as solid lines
*! 3.6.0 Ariel Linden 24Oct2025						// wrote new programs to create graph legend for multiple group with and without covariates
*! 3.5.2 Ariel Linden 24Sep2025						// fixed code for treated unit that prevented the CI from appearing on the graph in the second treatment period 
*! 3.5.1 Ariel Linden 19Sep2025						// added bwidth option for lowess smoother 
*! 3.5.0 Ariel Linden 16Sep2025						// fixed -cf- to account for different link() types
*! 3.4.0 Ariel Linden 30Jul2025						// added -cf- (counterfactual) option for single-group ITSA
*! 3.3.0 Ariel Linden 23Jul2025						// added smin() and smax() options to allow user to manually set ylabel() for shading 
*! 3.2.5 Ariel Linden 05Jun2025						// fixed bug in ylabel() that didn't allow user to overwrite existing settings 
													// implemented _natscale to get ylabels using shading to replicate standard Stata
*! 3.2.4 Ariel Linden 30Apr2025						// hardcoded lines around the legend box to work with Stata v19
*! 3.2.3 Ariel Linden 04Feb2025						// fixed bug in post-trend output that didn't account for "prefix" when specified 
													// fixed bug in single-group figure that didn't set legend at position 6
*! 3.2.2 Ariel Linden 26Dec2024						// fixed bug in legend for the case when no CI, lowess, or shading is specified 
*! 3.2.1 Ariel Linden 06Nov2024						// fixed shade() to ensure proper ordering 
*! 3.2.0 Ariel Linden 26Oct2024						// fixed trperiods() to ensure proper ordering 
													// coded legend to appear at 6 o'clock (because v18 moves the legend to 3 o'clock) 
													// added shading option
*! 3.1.2 Ariel Linden 12Sep2024						// return matrix r(table) manually to ensure it is available after -itsa-  
*! 3.1.1 Ariel Linden 09Sep2024						// changed code in CI option to utilize -predictnl- for computing predictions and CIs
*! 3.1.0 Ariel Linden 07Aug2024						// added CI option
*! 3.0.0 Ariel Linden 01Apr2024						// changed default model to -glm- with Newey-West std errors
*! 2.3.0 Ariel Linden 28Mar2024						// added lowess option 
*! 2.2.1 Ariel Linden 22Mar2021						// fixed error with trperiod() loop   
*! 2.2.0 Ariel Linden 10Mar2021 					// added parsing code to extract date(s) from trperiod() 
*! 2.1.0 Ariel Linden 03Mar2021						// fixed code to handle depvar when using ts operators (e.g. L.depvar) 
*! 2.0.8 Ariel Linden 02Feb2021						// fixed level() to ensure it is passed on to lincom from estimation model
													// fixed date on output and figure to match date format specified in (trperiod)   
*! 2.0.7 Ariel Linden 03Dec2017 					// added weight to -collapse- when generating figure for multiple group ITSA 
													// added weight to graphs in single group analyses
													// rearranged order of variables in regression output tables so that ITSA variables present first
													// specified "quietly" for generating variables that were previously missed
*! 2.0.6 Ariel Linden 08Sep2017 					// edited single group analyses to allow for segmented fits around trperiod() in figures 
*! 2.0.5 Ariel Linden 03May2017 					// set _t to start at zero
*! 2.0.4 Steve Samuels and Ariel Linden 16Jun2016 	// fixed lincom error lines 541-4, added two_way() option for the figure
*! 2.0.3 Ariel Linden 14Mar2016 					// set _t to start at zero
*! 2.0.2 Steve Samuels 28Apr2015 					// fixed lincom error for control group, multiple interventions
*! 2.0.1 Ariel Linden 								// fixed loop for -posttrend- table with multiple periods and minor changes to verbiage on figures
*! 2.0.0 Ariel Linden and Steve Samuels 17Sep2014 	// major changes include adding posttrend and segmented linear fits in figures
*! 1.1.1 Ariel Linden 06Aug2014 					// added lag(#) to note and "avg." to graphs with controls. Fixed missing `touse' qualifiers
*! 1.0.1 Ariel Linden 24Mar2014
*! 1.0.0 Ariel Linden 12Feb2014
*! 0.0.9 Ariel Linden 01Jan2014

program define itsa, rclass sort
version 11.0

	/* obtain settings */
	syntax varlist(min=1 numeric ts fv) [if] [in] [aweight] ,	/// weight only relevant for -newey-
	TRPeriod(string)											///	when the intervention began
	[ TREATid(numlist min=1 max=1 int sort)						/// the ID of the treated unit
	SINGle														/// specify single group ITSA
	CONTid(numlist int sort)									/// IDs of controls
	LAG(int -1)													/// lag only relevant for -newey-
	PRAIS														/// estimate Prais-Winsten model
    POSTTRend													/// produce post-trend estimates
	FIGure   FIGure2(str asis)									/// generate figure
	SHADe(string)												/// shading area of graph (for wash-out)
	SMIN(numlist min=1 max=1)									/// manually adjust min y-label for shade
	SMAX(numlist min=1 max=1)									///	manually adjust max y-label for shade
	LOWess														/// lowess smoother line
	BWidth(string)												/// adjust bandwidth for lowess smoother
	CI															/// confidence interval
	CF															/// counterfactual (single-group only)
	NAT(int 5)													/// UNDOCUMENTED change _natscale #_n (for shade())
	REPLace PREfix(str) *]

	if "`exp'" != "" & "`prais'" != "" {
		di as err "weights may not be specified with prais option"
		exit 101
	}

	if "`prais'" != "" {
		if `lag' != -1 {
			di as err "lag() may not be specified with prais option"
			exit 198
		}
	}
	else if `lag' == -1 local lag 0

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
		local multi_pnl = (r(imax)-r(imin)) > 0 & (r(imax)-r(imin)<.)
		
		/* check for gaps in the tvar */
		if `r(gaps)' ==  1 {
			di as err "" "`r(timevar)'" " (the time variable specified in -tsset-), must be evenly-spaced with no gaps" 
			exit 498			
		}
		
		/* make sure that panel is strongly balanced */
		if "`pvar'" != "" & "`single'" == "" {
			if "`r(balanced)'" != "strongly balanced" {
				di as err "strong balance required"
				exit 498
			}
		}		
		
		/* get format for timevar for output */
		* format specified for the timevar (used for lincom title and figure title)
		loc tsf `r(tsfmt)'
		* format used in regression output
		if substr("`tsf'",2,1) == "t" {
			local tsfr = substr("`tsf'",1,3)
			local period = lower(substr("`tsf'", 3, 1))
		}
		else local tsfr `tsf'

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
		/* ensure correct ordering of trperiods */		
		local trperiod = subinstr("`trperiod'", " ", "\ ", .)
		mata: st_local("trperiod",  invtokens(strofreal(sort(`trperiod',1))'))		
		
		/* check if trperiod is among tvars */
		levelsof `tvar' if `touse', local(levt)
		if !`: list trperiod in levt' {
			di as err "{p}Treatment period(s) not found in the time variable: check {bf:trperiod()} to ensure that dates are specified correctly,{p_end}"
			di as err "{p} and that multiple dates are separated by semicolons (;).{p_end}"
			exit 198
		}
		
		/* parse dates in shade() */
		if "`shade'" != "" {
			tokenize "`shade'" , parse(";")
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
					local shade`count' = `period'(`next') 
					local shading `shading' `shade`count''
					local shadeperiod `shading'
				}  // end if
			} // end while
			
			// ensure correct ordering of shade1 and shade2
			if `shade1' == `shade2' {
				di as err "shade() must contain two different values"
				exit 198
			}
			if `shade1' > `shade2' {
				local shade3 = `shade2'
				local shade4 = `shade1'
				local shade1 = `shade3'
				local shade2 = `shade4'
			}
			
			local shadecnt: word count `shadeperiod'	
			if `shadecnt' != 2 {
				di as err "shade() must contain two time values"
				exit 498
			}

		} // end parse shade

		/* check if shadeperiod is among tvars */
		levelsof `tvar' if `touse', local(levt)
		if !`: list shadeperiod in levt' {
			di as err "{p}Shade period(s) not found in the time variable: check {bf:shade()} to ensure that dates are specified correctly{p_end}"
			exit 198
		}
		
		/* New error 1 */
		if "`treatid'" !="" & "`pvar'"==""{
			di as err "treatid requires a tsset panel variable"
			exit 498
		}

		/* new error 2 */
		if `multi_pnl'==0 & "`contid'"!="" {
			di as err "only one panel in data: contid not allowed "
			exit 498
		}

		/* new error 3 */
		if `multi_pnl'== 1 & "`treatid'"==""{
			di as error "treatid required when there is more than 1 panel"
			exit 498
		}
		/* new error 4 */
		if "`single'" !="" & "`contid'"!="" {
			di as error "single & contid options may not combined"
			exit 498
		}
		
		/* verify that CF is specified with single */
		if "`cf'" != "" & "`single'" =="" {
			di as error "{bf:single} must be specified together with the {bf:cf} option"
			exit 198
		}			
		

	 /********************* SET ANALYSIS TYPES ******************
	  *		  Type 1: Single panel in data set					 *
	  *		  Type 2: Single group amongst multiple panels		 *
	  *		  Type 3: Multiple group analysis (one vs controls)	 *
	  ************************************************************/
		if `multi_pnl'==0 {
			local atype = 1
		}
		else if `multi_pnl'== 1 &  "`single'" !="" {
			local atype = 2
		}
		else if `multi_pnl'== 1 &  "`single'" =="" {
			local atype = 3
		}
		if "`contid'" !="" {
			/* check if all supplied contids are found in pvar */
			quietly levelsof `pvar', local(levp)
			if !`: list contid in levp' {
				di as err "at least one control unit not found in panel variable: check contid()"
 				exit 498
			}
			/* check if treatid is among the controls */
			if `: list treatid in contid' {
				di as err "Treated ID appears among control units: check contid() and treatid()"
				exit 498
			}
		}
		/* identify specified controls and insert commas */
		if "`contid'" != "" & !strpos("`contid'", ",") {
			local contid : subinstr local contid " " ",", all
			local contid , `contid'
		}

		/* verify the use of controls and generate inlist for use in model */
		if "`contid'" != "" {
			local if2 & inlist(`pvar', `treatid' `contid')
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
			local w : variable label `dvar1'
			if `"`w'"' != "" label variable `dvar' `"`w'"'			
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

		/* ensure no repeated values of timevar (implying multiple panels) */
		tempvar _timedif
		bysort `touse' (`tvar'): ///
		gen `_timedif' = `tvar'[_n+1] - `tvar' if `touse'
		sum `_timedif', meanonly
		local min = r(min)
	} // end quietly
	
	/*************************************************
	  TYPE 1 ANALYSIS: SINGLE GROUP IN DATA
	**************************************************/
	if `atype'== 1 {
		quietly {
			sort `touse' `tvar'
			/* gen t (time from start to end) */
			/* not _n as there may be gaps    */
		 	gen `prefix'_t = `tvar' - `tvar'[1] if `touse'
			local rhs `prefix'_t // collating RHS variables

			foreach t in `trperiod' {
				local tper = strofreal(`t',"`tsfr'")
				/* x will test change in level after intervention */
				gen `prefix'_x`tper' = `tvar' >= `t' if `touse'
				/* xt will test difference in pre-post slopes */
				gen `prefix'_x_t`tper' = (`tvar' - `t') * `prefix'_x`tper' if `touse'
				local rhs `rhs' `prefix'_x`tper' `prefix'_x_t`tper'
			}

		}  // end quietly
	
		/* run Prais or Newey regression */
		tsset
		if "`prais'" != "" {
			prais `dvar' `rhs' `xvar' if `touse' , `options'
			/* create matrix of r(table) to ensure it is available */
			matrix table = r(table)
			
			local z_t t
			local z_t_p P>|t|
			
			/* capture level specified in estimation model */
			local clv `r(level)'		
			local cil `=length("`clv'")'			
			
			if "`ci'" == "" {
				quietly predictnl `prefix'_s_`dvar1'_pred = predict() if e(sample)
			}
			else {
				tempvar lcl ucl
				quietly predictnl `prefix'_s_`dvar1'_pred = predict() if e(sample), ci(`lcl' `ucl')  df(`e(df_r)') level(`clv')	
			}
			local itsavars `dvar' `rhs' `prefix'_s_`dvar1'_pred
			char def _dta[`prefix'_itsavars] "`itsavars'"
		} // end prais
		/* run a GLM model */
		else {
			* first run is to get values for vfactor
			qui glm2 `dvar' `rhs' `xvar'  if `touse' [`weight' `exp'], force nodisplay `options'
			local vfac =  `e(N)'  /  `e(df)'
			* rerun it again, now with adjustment for autocorrelation
			glm2 `dvar' `rhs' `xvar'  if `touse' [`weight' `exp'], force vce(hac nwest `lag') vfactor(`vfac') `options'	
			/* create matrix of r(table) to ensure it is available */
			matrix table = r(table)
			
			local z_t z			
			local z_t_p P>|z|
			
			/* capture level specified in estimation model */
			local clv `r(level)'		
			local cil `=length("`clv'")'			
			
			if "`ci'" == "" {
				quietly predictnl `prefix'_s_`dvar1'_pred = predict() if e(sample)
			}
			else {
				tempvar lcl ucl
				quietly predictnl `prefix'_s_`dvar1'_pred = predict() if e(sample), ci(`lcl' `ucl') level(`clv') 
			}
			local itsavars `dvar' `rhs' `prefix'_s_`dvar1'_pred
			char def _dta[`prefix'_itsavars] "`itsavars'"
		} // end glm	
		
		if "`cf'" != "" {
			// get xvars from r(table)
			local colnames: colnames table
			gen_cf , cmdlne(`colnames') prefix(`prefix')
			local text = r(expr)
			tempvar _cf
			
			// GLM model
			if e(cmd) == "glm" {
			
				// if logit link, predict probabilities
				if e(linkt) == "Logit" {
					qui gen `_cf' = exp(`text') if `touse'
					qui replace `_cf' =  `_cf' / (1 + `_cf') if `touse'				
				}
			
				// if probit link, predict probabilities
				else if e(linkt) == "Probit" {
					qui gen `_cf' = normal(`text') if `touse'				
				}
	
				// if log link, predict count
				else if e(linkt) == "Log" {
					qui gen `_cf' = exp(`text') if `touse'				
				}	
			
				// if cloglog link, predict probabilities
				else if e(linkt) == "Complementary log–log" {
					qui gen `_cf' = 1 - exp(-exp(`text')) if `touse'
				}
			
				// if nbinomial link, predict probabilities
				else if e(linkt) == "Neg. Binomial" {
					qui gen `_cf' = exp(`text') if `touse'
					qui replace `_cf' = 1 * `_cf' / (1 - `_cf') if `touse'
				}
			
				// if log-log link, predict probabilities
				else if e(linkt) == "Log-log" {
					qui gen `_cf' = `text' if `touse'				
					qui replace `_cf' = exp(-exp(-`_cf')) if `touse'
				}
			
				// if reciprical (power -1) link, predict probabilities
				else if e(linkt) == "Reciprocal" {	
					qui gen `_cf' = `text' if `touse'	
					qui replace `_cf' = 1 / `_cf' if `touse'
				}
			
				// if (power -2) link, predict probabilities
				else if e(linkt) == "Power(-2)" {	
					qui gen `_cf' = 1/sqrt(`text') if `touse'	
				}
			
				// if another power is specified as the link, predict probabilities
				else if e(linkt) == "Power" {
					if ustrregexm(e(linkf), "\(([-0-9]+)\)") {
						local power = ustrregexs(1)
						qui gen `_cf' = `text' if `touse'
						qui replace `_cf' = `_cf'^(1/`power') if `touse'
					}
				}
			
				// if odds power link, predict probabilities
				else if e(linkt) == "Odds power" {
					if ustrregexm(e(linkf), "\(([-0-9]+)\)") {
						local power = ustrregexs(1)		
						qui gen `_cf' = `text' if `touse'	
						replace `_cf' = 1 / (1 + (1 + `power' * `_cf')^(-1 / `power')) if `touse'
					}
				}	

				// if log complement link, predict probabilities
				else if e(linkt) ==	"Log complement" {
					qui gen `_cf' = 1-exp(`text') if `touse'				
				}

				// if identity link, predict xb
				else if e(linkt) == "Identity" {
					qui gen `_cf' = `text' if `touse'
				}
			} // end glm
			
			// Prais model
			else {
				qui gen `_cf' = `text' if `touse'				
			}
			
		} // end "cf"
	
		/*********************************************************
		*  LINCOM: SINGLE GROUP SINGLE PANEL                     *
		**********************************************************/
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
				di _newline(1)
				di in smcl in green _col(20) " Postintervention Linear Trend: `tperl'"  _newline
				di  "Treated: `bexp'"
				#delim ;
				di in smcl in gr "{hline 13}{c TT}{hline 64}"
				_newline "Linear Trend {c |}"
				_col(21) "Coef. "
				_col(29) "Std. Err."
				_col(44) "`z_t'"
				_col(49) "`z_t_p'"
				_col(`=61-`cil'') `"[`clv'% Conf. Interval]"'
				_newline
				in gr in smcl "{hline 13}{c +}{hline 64}"
				_newline
				_col(1) "     Treated"  /* ARGUMENT */
				_col(14) "{c |}" in ye
				_col(17) %9.7g r(estimate)
				_col(28) %9.7g r(se)
				_col(38) %8.2f r(`z_t')
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
			if `"`ydesc'"' == "" local ydesc "`dvar1'"
			local tdesc : var label `tvar'
			if `"`tdesc'"' == "" local tdesc "`tvar'"
			if "`prais'" !="" {
				local note "Prais-Winsten and Cochrane-Orcutt regression - lag(1)"
			}
			else {
				local note "GLM model: family(`e(varfunct)'), link(`e(linkt)') with Newey-West standard errors - lag(`lag')"
			} 

		/* CREATE PREDICTED VALUE FOR PLOTS */
		quietly {
			tempvar ypred_t
			gen `ypred_t' = `prefix'_s_`dvar1'_pred
			local tct: word count `trperiod'
			local tmax: word `tct' of `trperiod'
			local k = 0
				foreach t in `trperiod' {
					local k = `k' + 1
					tempvar tp_t`k' plt_t`k'
					if `k'== 1 {
						gen `tp_t`k'' = `ypred_t' if `tvar'<=`t'
						replace `tp_t`k''=. if `tvar'==`t'
						ipolate `tp_t`k'' `tvar' if `tvar' <=`t', gen(`plt_t`k'') epolate
					}
					if `k'> 1 & `k'<=`tct' {
						local klast = `k'-1
						local tlast: word `klast' of `trperiod'
						gen `tp_t`k'' = `ypred_t' if `tvar'>=`tlast' & `tvar'<=`t' // & e(sample)
						replace `tp_t`k'' = . if `tvar'==`t'
						ipolate `tp_t`k'' `tvar' if `tvar'>=`tlast' & `tvar'<=`t', gen(`plt_t`k'') epolate
					}
					if `k' ==`tct' {
						tempvar pltx
						gen `pltx' = `ypred_t' if `tvar'>=`tmax'
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
						gen `lp_t`k'' = `lcl_t' if `tvar'<=`t'
						replace `lp_t`k''=. if `tvar'==`t'
						ipolate `lp_t`k'' `tvar' if `tvar' <=`t', gen(`llt_t`k'') epolate
						gen `up_t`k'' = `ucl_t' if `tvar'<=`t'
						replace `up_t`k''=. if `tvar'==`t'
						ipolate `up_t`k'' `tvar' if `tvar' <=`t', gen(`ult_t`k'') epolate						
					}
					if `k'> 1 & `k'<=`tct' {
						local klast = `k'-1
						local tlast: word `klast' of `trperiod'
						gen `lp_t`k'' = `lcl_t' if `tvar'>=`tlast' & `tvar'<=`t'
						replace `lp_t`k'' = . if `tvar'==`t'
						ipolate `lp_t`k'' `tvar' if `tvar'>=`tlast' & `tvar'<=`t', gen(`llt_t`k'') epolate
						gen `up_t`k'' = `ucl_t' if `tvar'>=`tlast' & `tvar'<=`t'
						replace `up_t`k'' = . if `tvar'==`t'
						ipolate `up_t`k'' `tvar' if `tvar'>=`tlast' & `tvar'<=`t', gen(`ult_t`k'') epolate						
					}
					if `k' ==`tct' {
						tempvar lltx ultx
						gen `lltx' = `lcl_t' if `tvar'>=`tmax' 
						gen `ultx' = `ucl_t' if `tvar'>=`tmax' 						
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
					local plotvarsU `plotvarsU' `ult_t`k''
					local plotvarsL `plotvarsL' `llt_t`k'' 
					local lp `lp' solid
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
			local lp lp(solid `lp' solid)
			local lc2 lcolor(blue `lblue' blue)
			local plotvarsL `plotvarsL' `lltx'
			local plotvarsU `plotvarsU' `ultx'
		}
	
		/* separate multiple trperiods for subtitle */
		foreach t in `trperiod' {
			local tper = strofreal(`t',"`tsf'")
			local tperlist `tperlist' `tper'
		}
		if "`shade'" != "" {
			if "`ci'" != "" { 
				sum `dvar' if `touse', meanonly
				local mindvar_t = r(min)
				local maxdvar_t = r(max)
				sum `ypred_t' if `touse', meanonly
				local minypred_t = r(min)			
				local maxypred_t = r(max)
				sum `ucl_t' if `touse', meanonly
				local maxucl = r(max)
				sum `lcl_t' if `touse', meanonly
				local minlcl = r(min)	
				local down = min(`mindvar_t', `minypred_t',`minlcl')			
				local up = max(`maxdvar_t', `maxypred_t', `maxucl')				
			}
			else if "`ci'" == "" {
				sum `dvar' if `touse', meanonly
				local mindvar_t = r(min)
				local maxdvar_t = r(max)
				sum `ypred_t' if `touse', meanonly
				local minypred_t = r(min)			
				local maxypred_t = r(max)
				local down = min(`mindvar_t', `minypred_t')			
				local up = max(`maxdvar_t', `maxypred_t')
			}
			/* if user specifies smin and/or smax */
			if "`smin'" != "" {
				local down = `smin'
			}
			if "`smax'" != "" {
				local up = `smax'
			}			
			/* use _natscale to get "nice" lower and upper values for the shading */	
			 _natscale `down' `up' `nat'
			local ylab ylabel(`r(min)'(`r(delta)')`r(max)') 
			tempvar upy
			gen `upy' = `r(max)' if `touse'
			local shhh (area `upy' `tvar' if inrange(`tvar', `shade1',`shade2') & `touse', base(`r(min)') bcolor(gs14) plotregion(margin(b=0 t=0)))	
			
		}	// end shade		
		
		/* CF graph */
		if "`cf'" != "" {
			local cf (line `_cf' `tvar' if `touse', lcolor(gs8) lpattern(longdash))		
		}

		/* lowess graph */
		if "`lowess'" != "" {
			if "`bwidth'" != "" {
				local low (lowess `dvar' `tvar' if `touse', lcolor(red) lpattern(solid) bw(`bwidth'))
			}
			else {
				local low (lowess `dvar' `tvar' if `touse', lcolor(red) lpattern(solid))				
			}
		}
	
		/* CI graph */
		if "`ci'" != "" {
			local lcl (line `plotvarsL' `tvar' if `touse' [`weight' `exp'],  `lc2' `lp')
			local ucl (line `plotvarsU' `tvar' if `touse' [`weight' `exp'],  `lc2' `lp')
		}
		
		/* get legend specs */
		get_leg_single , tperlist(`tperlist') tct(`tct') clv(`clv') lowess(`lowess') ci(`ci') shade(`shade') cf(`cf')
		local leg = r(leg)
		
		**************
		/* graph it */
		**************
		#delim ;
		tw 
		`shhh'			
		`low'
		`lcl'
		`ucl'
		`cf'
 		(scatter  `dvar' `plotvars' `tvar' if `touse' [`weight' `exp'],		
			`cpart' `mspart' `lc'
			xline(`trperiod', lpattern(shortdash) lcolor(black))
			mcolor(black)
			note(`"`note'"')
			ytitle("`ydesc'")
			xtitle("`tdesc'")
			title("`treatdesc'")
			`ylab' ///
			`leg'
            `figure2'
		;
		#delim cr
		}  /* End of Plot Loop */
	}  /* End of TYPE 1 LOOP */

	/*************************************************
	  TYPE 2 ANALYSIS: SINGLE GROUP MULTIPLE PANELS
	**************************************************/
	else if `atype'==2 {
		/* is treatid in panelvar? */
		quietly {
			levelsof `pvar', local(levp)
			if !`: list treatid in levp' {
			di as err "treatid() not found in panel variable:" ///
			" check treatid()"
			exit 498
			}

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

		/* run Prais or GLM (Newey) regression */
		tsset
		if "`prais'" != "" {
			prais `dvar' `rhs' `xvar' if `touse' & `pvar'==`treatid' , `options'
			/* create matrix of r(table) to ensure it is available */
			matrix table =r(table)
			
			local z_t t
			local z_t_p P>|t|
			
			/* capture level specified in estimation model */
			local clv `r(level)'		
			local cil `=length("`clv'")'
			
			if "`ci'" == "" {
				quietly predictnl `prefix'_s_`dvar1'_pred = predict() //if e(sample)
			}
			else {
				tempvar lcl ucl
				quietly predictnl `prefix'_s_`dvar1'_pred = predict() if e(sample), ci(`lcl' `ucl')  df(`e(df_r)') level(`clv')	
			}
			local itsavars `dvar' `rhs' `prefix'_s_`dvar1'_pred
			char def _dta[`prefix'_itsavars] "`itsavars'"
		
		} // end prais
		/* GLM */
		else {
			* first run is to get values for vfactor
			qui glm2 `dvar' `rhs' `xvar' if `touse' & `pvar'==`treatid' [`weight' `exp'], force nodisplay `options'
			local vfac =  `e(N)'  /  `e(df)'
			* rerun it again, now with adjustment for autocorrelation
			glm2 `dvar' `rhs' `xvar' if `touse' & `pvar'==`treatid' [`weight' `exp'], force vce(hac nwest `lag') vfactor(`vfac') `options'	
			/* create matrix of r(table) to ensure it is available */
			matrix table =r(table)
			
			local z_t z
			local z_t_p P>|z|
			
			/* capture level specified in estimation model */
			local clv `r(level)'		
			local cil `=length("`clv'")'
			
			if "`ci'" == "" {
				quietly predictnl `prefix'_s_`dvar1'_pred = predict() if e(sample)
			}
			else {
				tempvar lcl ucl
				quietly predictnl `prefix'_s_`dvar1'_pred = predict() if e(sample), ci(`lcl' `ucl') level(`clv') 
			}
			local itsavars `dvar' `rhs' `prefix'_s_`dvar1'_pred
			char def _dta[`prefix'_itsavars] "`itsavars'"
		
		}
		
		if "`cf'" != "" {
			// get xvars from r(table)
			local colnames: colnames table
			gen_cf , cmdlne(`colnames') prefix(`prefix')
			local text = r(expr)
			tempvar _cf
			
			// GLM model
			if e(cmd) == "glm" {
			
				// if logit link, predict probabilities
				if e(linkt) == "Logit" {
					qui gen `_cf' = exp(`text') if `touse'
					qui replace `_cf' =  `_cf' / (1 + `_cf') if `touse'				
				}
			
				// if probit link, predict probabilities
				else if e(linkt) == "Probit" {
					qui gen `_cf' = normal(`text') if `touse'				
				}
	
				// if log link, predict count
				else if e(linkt) == "Log" {
					qui gen `_cf' = exp(`text') if `touse'				
				}	
			
				// if cloglog link, predict probabilities
				else if e(linkt) == "Complementary log–log" {
					qui gen `_cf' = 1 - exp(-exp(`text')) if `touse'
				}
			
				// if nbinomial link, predict probabilities
				else if e(linkt) == "Neg. Binomial" {
					qui gen `_cf' = exp(`text') if `touse'
					qui replace `_cf' = 1 * `_cf' / (1 - `_cf') if `touse'
				}
			
				// if log-log link, predict probabilities
				else if e(linkt) == "Log-log" {
					qui gen `_cf' = `text' if `touse'				
					qui replace `_cf' = exp(-exp(-`_cf')) if `touse'
				}
			
				// if reciprical (power -1) link, predict probabilities
				else if e(linkt) == "Reciprocal" {	
					qui gen `_cf' = `text' if `touse'	
					qui replace `_cf' = 1 / `_cf' if `touse'
				}
			
				// if (power -2) link, predict probabilities
				else if e(linkt) == "Power(-2)" {	
					qui gen `_cf' = 1/sqrt(`text') if `touse'	
				}
			
				// if another power is specified as the link, predict probabilities
				else if e(linkt) == "Power" {
					if ustrregexm(e(linkf), "\(([-0-9]+)\)") {
						local power = ustrregexs(1)
						qui gen `_cf' = `text' if `touse'
						qui replace `_cf' = `_cf'^(1/`power') if `touse'
					}
				}
			
				// if odds power link, predict probabilities
				else if e(linkt) == "Odds power" {
					if ustrregexm(e(linkf), "\(([-0-9]+)\)") {
						local power = ustrregexs(1)		
						qui gen `_cf' = `text' if `touse'	
						replace `_cf' = 1 / (1 + (1 + `power' * `_cf')^(-1 / `power'))
					}
				}	

				// if log complement link, predict probabilities
				else if e(linkt) ==	"Log complement" {
					qui gen `_cf' = 1-exp(`text') if `touse'				
				}

				// if identity link, predict xb
				else if e(linkt) == "Identity" {
					qui gen `_cf' = `text' if `touse'
				}
			} // end glm
			
			// Prais model
			else {
				qui gen `_cf' = `text' if `touse'				
			}
			
		} // end "cf"

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
				di _newline(1)
				di in smcl in green _col(20) " Postintervention Linear Trend: `tperl'"  _newline
				di  "Treated: `bexp'"
				#delim ;
				di in smcl in gr "{hline 13}{c TT}{hline 64}"
				_newline "Linear Trend {c |}"
				_col(21) "Coef. "
				_col(29) "Std. Err."
				_col(44) "`z_t'"
				_col(49) "`z_t_p'"
				_col(`=61-`cil'') `"[`clv'% Conf. Interval]"'
				_newline
				in gr in smcl "{hline 13}{c +}{hline 64}"
				_newline
				_col(1) "     Treated"  /* ARGUMENT */
				_col(14) "{c |}" in ye
				_col(17) %9.7g r(estimate)
				_col(28) %9.7g r(se)
				_col(38) %8.2f r(`z_t')
				_col(46) %8.3f r(p)
				_col(58) %9.7g r(lb)
				_col(70) %9.7g r(ub)
				_newline
				in gr in smcl "{hline 13}{c BT}{hline 64}"
				;
				#delim cr
			} /* end trperiod */
		
		} /* end if posttrend and lincom block */
		
		
		/************************************************
		*             PLOT SECTION FOR TYPE 2           *
		*************************************************/
		if `"`figure'`figure2'"' != "" {   /* Start Figure Loop */
			/* graph; get variable labels if they exist */
			local ydesc : var label `dvar'
			if `"`ydesc'"' == "" local ydesc "`dvar1'"
			local tdesc : var label `tvar'
			if `"`tdesc'"' == "" local tdesc "`tvar'"

			local treatdesc: label ( `pvar' )  `treatid'
			if "`treatdesc'" == "" local treatdesc "Treated"

			if "`prais'" !="" {
				local note "Prais-Winsten and Cochrane-Orcutt regression - lag(1)"
			}
			else {
				local note "GLM model: family(`e(varfunct)'), link(`e(linkt)') with Newey-West standard errors - lag(`lag')"
			}

			/* CREATE PREDICTED VALUES FOR PLOTS */
			quietly {
				tempvar ypred_t
				gen `ypred_t' = `prefix'_s_`dvar1'_pred

				local tct: word count `trperiod'
				local tmax: word `tct' of `trperiod'

				local k = 0
				foreach t in `trperiod' {
					local k = `k' + 1
					tempvar tp_t`k' plt_t`k'
					if `k'== 1 {
						gen `tp_t`k'' = `ypred_t' if `tvar'<=`t' 
						replace `tp_t`k''=. if `tvar'==`t'
						ipolate `tp_t`k'' `tvar' if `tvar' <=`t', gen(`plt_t`k'') epolate
					}
					if `k'> 1 & `k'<=`tct' {
						local klast = `k'-1
						local tlast: word `klast' of `trperiod'
						gen `tp_t`k'' = `ypred_t' if `tvar'>=`tlast' & `tvar'<=`t'
						replace `tp_t`k'' = . if `tvar'==`t'
						ipolate `tp_t`k'' `tvar' if `tvar'>=`tlast' & `tvar'<=`t', gen(`plt_t`k'') epolate
					}
					if `k' ==`tct' {
						tempvar pltx
						gen `pltx' = `ypred_t' if `tvar'>=`tmax'
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
							gen `lp_t`k'' = `lcl_t' if `tvar'<=`t'
							replace `lp_t`k''=. if `tvar'==`t'
							ipolate `lp_t`k'' `tvar' if `tvar' <=`t', gen(`llt_t`k'') epolate
							gen `up_t`k'' = `ucl_t' if `tvar'<=`t' 
							replace `up_t`k''=. if `tvar'==`t'
							ipolate `up_t`k'' `tvar' if `tvar' <=`t', gen(`ult_t`k'') epolate						
						}
						if `k'> 1 & `k'<=`tct' {
							local klast = `k'-1
							local tlast: word `klast' of `trperiod'
							gen `lp_t`k'' = `lcl_t' if `tvar'>=`tlast' & `tvar'<=`t'
							replace `lp_t`k'' = . if `tvar'==`t'
							ipolate `lp_t`k'' `tvar' if `tvar'>=`tlast' & `tvar'<=`t', gen(`llt_t`k'') epolate
							gen `up_t`k'' = `ucl_t' if `tvar'>=`tlast' & `tvar'<=`t'
							replace `up_t`k'' = . if `tvar'==`t'
							ipolate `up_t`k'' `tvar' if `tvar'>=`tlast' & `tvar'<=`t', gen(`ult_t`k'') epolate						
						}
						if `k' ==`tct' {
							tempvar lltx ultx
							gen `lltx' = `lcl_t' if `tvar'>=`tmax' 
							gen `ultx' = `ucl_t' if `tvar'>=`tmax'						
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
						local plotvarsU `plotvarsU' `ult_t`k''
						local plotvarsL `plotvarsL' `llt_t`k'' 
						local lp `lp' solid
						local lblue `lblue' blue
					}
				} // end CI

				/* connect and msymbol options (affects post-intervention periods) */
				local cpart c(. l `cpart')
				local lc lcolor(black `lblack' black)
				local mspart  ms(O none `mspart')
				local plotvars `plotvars' `pltx' 
			
				/* affects post-intervention periods */
				if "`ci'" != "" {
					local lp lp(solid `lp' solid)
					local lc2 lcolor(blue `lblue' blue)
					local plotvarsL `plotvarsL' `lltx'
					local plotvarsU `plotvarsU' `ultx'
				}			

				/* separate multiple trperiods for subtitle */
				foreach t in `trperiod' {
					local tper = strofreal(`t',"`tsf'")
					local tperlist `tperlist' `tper'
				}
			
				if "`shade'" != "" {
					if "`ci'" != "" { 
						sum `dvar' if `pvar'==`treatid' & `touse', meanonly
						local mindvar_t = r(min)
						local maxdvar_t = r(max)
						sum `ypred_t' if `pvar'==`treatid' & `touse', meanonly
						local minypred_t = r(min)			
						local maxypred_t = r(max)
						sum `ucl_t' if `pvar'==`treatid' & `touse', meanonly
						local maxucl = r(max)
						sum `lcl_t' if `pvar'==`treatid' & `touse', meanonly
						local minlcl = r(min)	
						local down = min(`mindvar_t', `minypred_t',`minlcl')			
						local up = max(`maxdvar_t', `maxypred_t', `maxucl')				
					}
					else if "`ci'" == "" {
						sum `dvar' if `pvar'==`treatid' & `touse', meanonly
						local mindvar_t = r(min)
						local maxdvar_t = r(max)
						sum `ypred_t' if `pvar'==`treatid' & `touse', meanonly
						local minypred_t = r(min)			
						local maxypred_t = r(max)
						local down = min(`mindvar_t', `minypred_t')			
						local up = max(`maxdvar_t', `maxypred_t')
					}
					/* if user specifies smin and/or smax */
					if "`smin'" != "" {
						local down = `smin'
					}
					if "`smax'" != "" {
						local up = `smax'
					}				
					/* use _natscale to get "nice" lower and upper values for the shading */			
					_natscale `down' `up' `nat'
					local ylab ylabel(`r(min)'(`r(delta)')`r(max)') 
					tempvar upy
					gen `upy' = `r(max)' if `touse'
					local shhh (area `upy' `tvar' if `pvar'==`treatid' & inrange(`tvar', `shade1',`shade2') & `touse', base(`r(min)') bcolor(gs14) plotregion(margin(b=0 t=0)))	
				}	// end shade		
		
				/* CF graph */
				if "`cf'" != "" {
					local cf (line `_cf' `tvar' if `pvar'==`treatid' & `touse', lcolor(gs8) lpattern(longdash))		
				}

				/* lowess graph */
				if "`lowess'" != "" {
					if "`bwidth'" != "" {
						local low (lowess `dvar' `tvar' if `pvar'==`treatid' & `touse', lcolor(red) lpattern(solid) bw(`bwidth'))				
					}
					else {
						local low (lowess `dvar' `tvar' if `pvar'==`treatid' & `touse', lcolor(red) lpattern(solid))			
					}
				}			
			
				/* CI graph */			
				if "`ci'" != "" {
					local lcl (line `plotvarsL' `tvar' if `pvar'==`treatid' & `touse' [`weight' `exp'], `lc2' `lp') 
					local ucl (line `plotvarsU' `tvar' if `pvar'==`treatid' & `touse' [`weight' `exp'], `lc2' `lp') 	
				}
			
				/* get legend specs */
				get_leg_single , tperlist(`tperlist') tct(`tct') clv(`clv') lowess(`lowess') ci(`ci') shade(`shade') cf(`cf')
				local leg = r(leg)
			
			} // end quietly
			
			**************
			/* graph it */
			**************
			#delim ;
			noi tw 
			`shhh'					
			`low'
			`lcl'
			`ucl'
			`cf'
			(scatter  `dvar' `plotvars' `tvar' if `pvar'==`treatid' & `touse' [`weight' `exp'],
			`cpart' `mspart' `lc'
			xline(`trperiod', lpattern(shortdash) lcolor(black))
			mcolor(black)
			note(`"`note'"')
			ytitle("`ydesc'")
			xtitle("`tdesc'")
			title("`treatdesc'")
			`ylab'
			`leg'
			`figure2'
			;
			#delim cr
		} /* END OF FIGURE BLOCK */
	} /* END OF TYPE 2 BLOCK */

	/*************************************************
	TYPE 3 ANALYSIS: MULTIPLE GROUP ANALYSIS
	**************************************************/
	else if `atype'== 3 {
		/* variables based on trperiod */
  		quietly {
			bysort `touse' `pvar' (`tvar'): gen `prefix'_t = `tvar' - `tvar'[1] if `touse'
			gen byte `prefix'_z = `pvar' == `treatid' if `touse'
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
			} /* end trperiod */
		} //end quietly

		/* run Prais or Newey regression */
		tsset
		if "`prais'" != "" {
			prais `dvar' `rhs' `xvar' if `touse' `if2' , `options'
			/* create matrix of r(table) to ensure it is available for -itsamatch- */
			matrix table =r(table)
			
			local z_t t
			local z_t_p P>|t|				
		}
		else {
			* first run is to get values for vfactor
			qui glm2 `dvar' `rhs' `xvar' if `touse' `if2' [`weight' `exp'], force nodisplay `options'
			local vfac =  `e(N)'  /  `e(df)'
			* rerun it again, now with adjustment for autocorrelation
			glm2 `dvar' `rhs' `xvar' if `touse' `if2' [`weight' `exp'], force vce(hac nwest `lag') vfactor(`vfac') `options'
			
			/* create matrix of r(table) to ensure it is available for -itsamatch- */
			matrix table =r(table)
			
			local z_t z
			local z_t_p P>|z|			
		}
		
		/* capture level specified in estimation model */
		local clv `r(level)'
		local cil `=length("`clv'")'
		
		/* generating CI values depending on whether the model was prais or GLM */
		if "`ci'" == "" {
			quietly predictnl `prefix'_m_`dvar'_pred = predict() if e(sample)
			local itsavars `dvar' `rhs' `prefix'_m_`dvar'_pred
			char def _dta[`prefix'_itsavars] "`itsavars'"
		}
		else {
			tempvar lcl ucl
			if "`prais'" != "" {
				quietly predictnl `prefix'_m_`dvar'_pred = predict() if e(sample), ci(`lcl' `ucl')  df(`e(df_r)') level(`clv')	
			}
			else {
				quietly predictnl `prefix'_m_`dvar'_pred = predict() if e(sample), ci(`lcl' `ucl') level(`clv') 
			}
			local itsavars `dvar' `rhs' `prefix'_m_`dvar'_pred
			char def _dta[`prefix'_itsavars] "`itsavars'"			
		} // end CI			
	
		/*******************************************
		 LINCOM:   MULTIPLE GROUP COMPARISON       *
		********************************************/
		if "`posttrend'" != "" {
		
			/* Start Loop over time */
         	local btexp "_b[`prefix'_t] + _b[`prefix'_z_t]"
            local bcexp "_b[`prefix'_t]"
           	local bdexp "_b[`prefix'_z_t]"

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
				_col(44) "`z_t'"
				_col(49) "`z_t_p'"
				_col(`=61-`cil'') `"[`clv'% Conf. Interval]"'
				_newline
				in gr in smcl "{hline 13}{c +}{hline 64}"
				_newline

				_col(1) "     Treated"
				_col(14) "{c |}" in ye
				_col(17) %9.7g r(estimate)
				_col(28) %9.7g r(se)
				_col(38) %8.2f r(`z_t')
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
				_col(38) %8.2f r(`z_t')
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
				_col(38) %8.2f r(`z_t')
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

		if `"`figure'`figure2'"' != "" {   /* Start Figure Loop */

			/* graph; get variable labels if they exist */
			local ydesc : var label `dvar'
					if `"`ydesc'"' == "" local ydesc "`dvar1'"
			local tdesc : var label `tvar'
			if `"`tdesc'"' == "" local tdesc "`tvar'"

			local treatdesc: label (`pvar')  `treatid'
			if "`treatdesc'" == "" local treatdesc "Treated"

			if "`prais'" !="" {
				local note "Prais-Winsten and Cochrane-Orcutt regression - lag(1)"
			}
			else {
				local note "GLM model: family(`e(varfunct)'), link(`e(linkt)') with Newey-West standard errors - lag(`lag')"
			}

			preserve

			 /* Collapse actual & predicted for treat/control means */
			collapse (mean) `dvar' `prefix'_m_`dvar'_pred `lcl' `ucl' ///
				if `touse' `if2' [`weight' `exp'], by(`tvar' `prefix'_z)

			local istreat   `prefix'_z==1
			local iscontrol `prefix'_z==0

			/* Start quietly loop */			
			quietly {   
				
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
						local plotvars_t_U `plotvars_t_U' `ult_t`k''
						local lblue `lblue' blue
						local lp `lp' solid
					}
				} // end CI					

				/* affects post-intervention periods */
				if "`ci'" != "" {
					local lc2 lcolor(blue `lblue' blue)
					local lp lp(solid `lp' solid)						
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
						local plotvars_c_U `plotvars_c_U' `ult_c`k''
						local lgreen `lgreen' green
						local lp3 `lp3' solid
					}
				} // end CI	
					
				/* affects post-intervention periods */
				if "`ci'" != "" {
					local lc3 lcolor(green `lgreen' green)
					local lp3 lp(solid `lp3' solid)		
					local plotvars_c_L `plotvars_c_L' `llcon'
					local plotvars_c_U `plotvars_c_U' `ulcon'
					
					local lclt (line `plotvars_t_L' `tvar', `lc2' `lp') 
					local uclt (line `plotvars_t_U' `tvar', `lc2' `lp')
					local lclc (line `plotvars_c_L' `tvar', `lc3' `lp3') 
					local uclc (line `plotvars_c_U' `tvar', `lc3' `lp3')
					
				}
				
				tempvar dvar_t dvar_c
				gen `dvar_t' = `dvar' if `istreat'
				gen `dvar_c' = `dvar' if `iscontrol'

				/* separate multiple trperiods for subtitle */
				foreach t in `trperiod' {
					local tper = strofreal(`t',"`tsf'")
					local tperlist `tperlist' `tper'
				}
			
				if "`shade'" != "" {
					if "`ci'" != "" { 
						sum `dvar_t', meanonly
						local mindvar_t = r(min)
						local maxdvar_t = r(max)
					
						sum `ypred_t', meanonly
						local minypred_t = r(min)			
						local maxypred_t = r(max)
					
						sum `dvar_c', meanonly
						local mindvar_c = r(min)
						local maxdvar_c = r(max)
					
						sum `ypred_c', meanonly
						local minypred_c = r(min)			
						local maxypred_c = r(max)
					
						sum `ucl_t', meanonly
						local maxucl_t = r(max)
					
						sum `ucl_c', meanonly
						local maxucl_c = r(max)
					
						sum `lcl_t', meanonly
						local minlcl_t = r(min)
					
						sum `lcl_c', meanonly
						local minlcl_c = r(min)					
					
						local down = min(`mindvar_t', `minypred_t',`minlcl_t',`mindvar_c', `minypred_c',`minlcl_c')			
						local up = max(`maxdvar_t', `maxypred_t', `maxucl_t', `maxdvar_c', `maxypred_c', `maxucl_c')				
					}
					else if "`ci'" == "" {
						sum `dvar_t', meanonly
						local mindvar_t = r(min)
						local maxdvar_t = r(max)
					
						sum `ypred_t', meanonly
						local minypred_t = r(min)			
						local maxypred_t = r(max)
					
						sum `dvar_c', meanonly
						local mindvar_c = r(min)
						local maxdvar_c = r(max)
					
						sum `ypred_c', meanonly
						local minypred_c = r(min)			
						local maxypred_c = r(max)
					
						local down = min(`mindvar_t', `minypred_t',`mindvar_c', `minypred_c')			
						local up = max(`maxdvar_t', `maxypred_t',`maxdvar_c', `maxypred_c')
					}
					/* if user specifies smin and/or smax */
					if "`smin'" != "" {
						local down = `smin'
					}
					if "`smax'" != "" {
						local up = `smax'
					}				
					/* use _natscale to get "nice" lower and upper values for the shading */				
					_natscale `down' `up' `nat'
					local ylab ylabel(`r(min)'(`r(delta)')`r(max)') 
					tempvar upy
					gen `upy' = `r(max)' 
					local shhh (area `upy' `tvar' if inrange(`tvar', `shade1',`shade2'), base(`r(min)')  bcolor(gs14) plotregion(margin(b=0 t=0)))				
				}	// end shade		

				#delim ;
				/* Titles for Two-Group Comparison */
				local titlesec
				ytitle("`ydesc'")
				xtitle("`tdesc'")
				title("`treatdesc' and average of controls")
				subtitle("Intervention starts: `tperlist'")
				;
				#delim cr

				if "`lowess'" != "" {
					if "`bwidth'" != "" {
						local lowt (lowess `dvar_t'  `tvar', lcolor(red) lpattern(solid) bw(`bwidth')) 
						local lowc (lowess `dvar_c'  `tvar', lcolor(orange) lpattern(solid) bw(`bwidth'))	
					}
					else {
						local lowt (lowess `dvar_t'  `tvar', lcolor(red) lpattern(solid)) 
						local lowc (lowess `dvar_c'  `tvar', lcolor(orange) lpattern(solid))		
					}
				} // end lowess	
				

			
				/* get legend specs */
				get_leg_multi , treatdesc(`treatdesc')  tperlist(`tperlist') tct(`tct') clv(`clv') lowess(`lowess') ci(`ci') shade(`shade')
				local mleg = r(mleg)
				
			} // end quietly				
				
			// * graph it * //
			twoway ///
				`shhh' ///				
				(scatter  `dvar_t' `plotvars_t' `tvar', `cpart' `tmspart' `lc' `mc') ///
				(scatter  `dvar_c' `plotvars_c' `tvar', `cpart' `cmspart' `lc' `mc' `clp') ///
				`lowt' ///
				`lowc' ///
				`lclt' ///
				`uclt' ///	
				`lclc' ///
				`uclc' ///	
				, xline(`trperiod', lpattern(shortdash) lcolor(black)) ///
				`ylab' ///						
				`mleg' ///
				`titlesec' note(`"`note'"') `figure2'
		}   /* End of Figure Block */
	}   /* End of Type 3 */
	
	// save estimation table
	return matrix table = table	

end

// program to generate the counterfactual
program define gen_cf, rclass
version 11.0
    syntax, cmdlne(string) [prefix(string)]

    // loop to filter command line list
    foreach var in `cmdlne' {
        // skip _cons
        if "`var'" == "_cons" continue

        // handle interaction terms (e.g., c.var1#c.var2)
        if strpos("`var'", "#") {
            local cmdlne_filtered `cmdlne_filtered' `var'
            continue
        }

        // extract clean (base) variable name (after last . if any)
        local base = "`var'"
        while strpos("`base'", ".") {
            local base = substr("`base'", strpos("`base'", ".") + 1, .)
        }

        // remove user-defined prefix from base (if any)
        local base_noprefix = "`base'"
        if strpos("`base'", "`prefix'") == 1 {
            local base_noprefix = substr("`base'", length("`prefix'") + 1, .)
        }

        // Skip _x* and _y
        if "`base_noprefix'" != "_y" & substr("`base_noprefix'", 1, 2) != "_x" {
            local cmdlne_filtered `cmdlne_filtered' `var'
        }
    }

    // build expression
    local first = 1
    foreach var of local cmdlne_filtered {
        // keep interaction terms as-is
        if strpos("`var'", "#") {
            local term "_b[`var'] * `var'"
        }
        else {
            // get clean (base) variable name (after last .)
            local base = "`var'"
            while strpos("`base'", ".") {
                local base = substr("`base'", strpos("`base'", ".") + 1, .)
            }

            // apply user-defined prefix only to _t
            if "`base'" == "_t" {
                local base_with_prefix "`prefix'`base'"
            }
            else {
                local base_with_prefix "`base'"
            }

            // reapply operator(s) stripped earlier
            local final_var "`var'"
            if strpos("`var'", ".") {
                local operator = substr("`var'", 1, strpos("`var'", "."))
                local final_var "`operator'`base_with_prefix'"
            }
            else {
                local final_var "`base_with_prefix'"
            }

            local term "_b[`var'] * `final_var'"
        }

        // ensure that the expression doesn't start with "+"
        if `first' {
            local expr "`term'"
            local first = 0
        }
        else {
            local expr "`expr' + `term'"
        }
    }

    // add constant term at the end
    local expr "`expr' + _b[_cons]"
	
	// save the local
	ret local expr `expr'
end

// program to get legend for single group
program define get_leg_single, rclass
version 11.0
    syntax, [ tperlist(string) tct(string) LOWess(string) clv(string) ci(string) SHade(string) cf(string) ] 

		// [1,1,1,1]
		if "`lowess'" != "" & "`ci'" != "" & "`shade'" != "" & "`cf'" != "" {		
			local x = `tct' - 1	
			local act1 = `tct' + 7 + `x'
			local pred1 = `tct' + 8 + `x'
			local ci1 = 3
			local low1 = 2
			local cf1 = `act1' - 1
			local leg subtitle("Intervention starts: `tperlist'") legend(rows(1) region(lcolor(black)) order(`act1' `pred1' `low1' `ci1' `cf1') label(`act1' "Actual") ///
				label(`pred1' "Predicted") label(`low1' "Lowess") label(`ci1' "`clv'% CI") label(`cf1' "Counterfactual") position(6))),	
		}
		// [1,1,0,1]
		if "`lowess'" != "" & "`ci'" != "" & "`shade'" == "" & "`cf'" != "" {	
			local x = `tct' - 1	
			local act1 = `tct' + 6 + `x'
			local pred1 = `tct' + 7 + `x'
			local ci1 = 3
			local low1 = 1
			local cf1 = `act1' - 1
			local leg subtitle("Intervention starts: `tperlist'") legend(rows(1) region(lcolor(black)) order(`act1' `pred1' `low1' `ci1' `cf1') label(`act1' "Actual") ///
				label(`pred1' "Predicted") label(`low1' "Lowess") label(`ci1' "`clv'% CI") label(`cf1' "Counterfactual") position(6))),	
		}
		// [1,0,1,1]
		if "`lowess'" != "" & "`ci'" == "" & "`shade'" != "" & "`cf'" != "" {	
			local act1 = 4
			local pred1 = 5
			local low1 = 2
			local cf1 = 3
			local leg subtitle("Intervention starts: `tperlist'") legend(rows(1) region(lcolor(black)) order(`act1' `pred1' `low1' `cf1') label(`act1' "Actual") ///
				label(`pred1' "Predicted") label(`low1' "Lowess") label(`cf1' "Counterfactual") position(6))),	
		}
		// [1,0,0,1]
		if "`lowess'" != "" & "`ci'" == "" & "`shade'" == "" & "`cf'" != "" {	
			local act1 = 3
			local pred1 = 4
			local low1 = 1			
			local cf1 = 2
			local leg subtitle("Intervention starts: `tperlist'") legend(rows(1) region(lcolor(black)) order(`act1' `pred1' `low1' `cf1') label(`act1' "Actual") ///
				label(`pred1' "Predicted") label(`low1' "Lowess") label(`cf1' "Counterfactual") position(6))),	
		}
		// [1,1,1,0]
		if "`lowess'" != "" & "`ci'" != "" & "`shade'" != "" & "`cf'" == "" {
			local x = `tct' - 1	
			local act1 = `tct' + 6 + `x'
			local pred1 = `tct' + 7 + `x'
			local ci1 = 3
			local low1 = 2
			local leg subtitle("Intervention starts: `tperlist'") legend(rows(1) region(lcolor(black)) order(`act1' `pred1' `low1' `ci1') label(`act1' "Actual") ///
				label(`pred1' "Predicted") label(`low1' "Lowess") label(`ci1' "`clv'% CI") position(6))),				
		}
		// [1,1,0,0]
		if "`lowess'" != "" & "`ci'" != "" & "`shade'" == "" & "`cf'" == "" {
			local x = `tct' - 1	
			local act1 = `tct' + 5 + `x'
			local pred1 = `tct' + 6 + `x'
			local ci1 = 2
			local low1 = 1
			local leg subtitle("Intervention starts: `tperlist'") legend(rows(1) region(lcolor(black)) order(`act1' `pred1' `low1' `ci1') label(`act1' "Actual") ///
				label(`pred1' "Predicted") label(`low1' "Lowess") label(`ci1' "`clv'% CI") position(6))),
		}			
		// [1,0,0,0]
		if "`lowess'" != "" & "`ci'" == "" & "`shade'" == "" & "`cf'" == "" {
			local leg subtitle("Intervention starts: `tperlist'") legend(rows(1)  region(lcolor(black)) order(2 3 1) label(1 "Lowess") label(2 "Actual") ///
				label(3 "Predicted") position(6))),
		}
		// [1,0,1,0]		
		if "`lowess'" != "" & "`ci'" == "" & "`shade'" != "" & "`cf'" == "" {		
			local shading = 8
			local leg subtitle("Intervention starts: `tperlist'") legend(rows(1) region(lcolor(black)) order(3 4 2) label(3 "Actual") label(4 "Predicted") ///
				label(2 "Lowess") position(6))),
		}
		// [0,1,0,0]
		if "`lowess'" == "" & "`ci'" != "" & "`shade'" == "" & "`cf'" == "" {		
			local x = `tct' - 1	
			local act1 = `tct' + 4 + `x'
			local pred1 = `tct' + 5 + `x'
			local ci1 = 1
			local leg subtitle("Intervention starts: `tperlist'") legend(rows(1) region(lcolor(black)) order(`act1' `pred1' `ci1') label(`act1' "Actual") ///
				label(`pred1' "Predicted") label(`ci1' "`clv'% CI") position(6))),
		}
		// [0,1,0,1]
		if "`lowess'" == "" & "`ci'" != "" & "`shade'" == "" & "`cf'" != "" {
			local x = `tct' - 1	
			local act1 = `tct' + 5 + `x'
			local pred1 = `tct' + 6 + `x'
			local ci1 = `pred1' - 3
			local cf1 = `pred1' - 2
			local leg subtitle("Intervention starts: `tperlist'") legend(rows(1) region(lcolor(black)) order(`act1' `pred1' `ci1' `cf1') label(`act1' "Actual") ///
				label(`pred1' "Predicted") label(`ci1' "`clv'% CI") label(`cf1' "Counterfactual") position(6))),
		}			
		// [0,1,1,1]
		if "`lowess'" == "" & "`ci'" != "" & "`shade'" != "" & "`cf'" != "" {
			local x = `tct' - 1	
			local act1 = `tct' + 6 + `x'
			local pred1 = `tct' + 7 + `x'
			local ci1 = `pred1' - 3
			local cf1 = `pred1' - 2
			local leg subtitle("Intervention starts: `tperlist'") legend(rows(1) region(lcolor(black)) order(`act1' `pred1' `ci1' `cf1') label(`act1' "Actual") ///
				label(`pred1' "Predicted") label(`ci1' "`clv'% CI") label(`cf1' "Counterfactual") position(6))),
		}				
		// [0,0,1,1]
		if "`lowess'" == "" & "`ci'" == "" & "`shade'" != "" & "`cf'" != "" {
			local act1 = 3
			local pred1 = 4
			local cf1 = 2
			local leg subtitle("Intervention starts: `tperlist'") legend(rows(1) region(lcolor(black)) order(`act1' `pred1' `cf1') label(`act1' "Actual") ///
				label(`pred1' "Predicted") label(`cf1' "Counterfactual") position(6))),
		}	
		// [0,0,0,1]
		if "`lowess'" == "" & "`ci'" == "" & "`shade'" == "" & "`cf'" != "" {
			local act1 = 2
			local pred1 = 3
			local cf1 = 1
			local leg subtitle("Intervention starts: `tperlist'") legend(rows(1) region(lcolor(black)) order(`act1' `pred1' `cf1') label(`act1' "Actual") ///
				label(`pred1' "Predicted") label(`cf1' "Counterfactual") position(6))),
		}				
		// [0,1,1,0]
		if "`lowess'" == "" & "`ci'" != "" & "`shade'" != "" & "`cf'" == "" {				
			local x = `tct' - 1	
			local act1 = `tct' + 5 + `x'
			local pred1 = `tct' + 6 + `x'
			local ci1 = 2
			local leg subtitle("Intervention starts: `tperlist'") legend(rows(1) region(lcolor(black)) order(`act1' `pred1' `ci1') label(`act1' "Actual") ///
				label(`pred1' "Predicted") label(`ci1' "`clv'% CI") position(6))),					
		}	
		// [0,0,1,0]		
		if "`lowess'" == "" & "`ci'" == "" & "`shade'" != "" & "`cf'" == "" {
			local leg subtitle("Intervention starts: `tperlist'")  legend(rows(1) region(lcolor(black)) order(2 4) label(2 "Actual")label(4 "Predicted") ///
				position(6))), 		
		}
		// [0,0,0,0]			
		if "`lowess'" == "" & "`ci'" == "" & "`shade'" == "" & "`cf'" == "" {		
			local leg subtitle("Intervention starts: `tperlist'")  legend(rows(1) region(lcolor(black)) order(1 2) label(1 "Actual")label(2 "Predicted") ///
				position(6))), 
		}
	
		// save the local
		ret local leg `leg'
		
end	

// program to get legend for multiple groups
program define get_leg_multi, rclass
version 11.0
    syntax, [ treatdesc(string) tperlist(string) tct(string) LOWess(string) clv(string) ci(string) SHade(string) ] 

		// [1,1,1]
		if "`lowess'" != "" & "`ci'" != "" & "`shade'" != "" {
			local x = `tct' - 1	
			local ctrl1 = `tct' + 4				
			local ctrl2 = `tct' + 5	
			local low1 = `ctrl2' + `tct' + 1
			local low2 = `ctrl2' + `tct' + 2
			local cl1 = `low1' + 2
			local cl2 = `tct' + `low2' + (7 + `x')
			local mleg subtitle("Intervention starts: `tperlist'") legend(rows(2) ///
				region(lcolor(black)) order(- "`treatdesc': " 2 3 `low1' `cl1' - "Controls average:" `ctrl1' `ctrl2' `low2' `cl2') ///
				label(3 "Predicted") label(2 "Actual") label(`ctrl1' "Actual") label(`ctrl2' "Predicted") ///					
				label(`low1' "Lowess") label(`low2' "Lowess") label(`cl1' "`clv'% CI") label(`cl2' "`clv'% CI") symxsize(8) position(6))
		}
		// [1,1,0]
		if "`lowess'" != "" & "`ci'" != "" & "`shade'" == "" {			
			local x = `tct' - 1	
			local ctrl1 = `tct' + 3				
			local ctrl2 = `tct' + 4	
			local low1 = `ctrl2' + `tct' + 1
			local low2 = `ctrl2' + `tct' + 2
			local cl1 = `low1' + 2
			local cl2 = `tct' + `low2' + (7 + `x')
			local mleg subtitle("Intervention starts: `tperlist'") legend(rows(2) ///
				region(lcolor(black)) order(- "`treatdesc': " 1 2 `low1' `cl1' - "Controls average:" `ctrl1' `ctrl2' `low2' `cl2') ///
				label(1 "Actual") label(2 "Predicted") label(`ctrl1' "Actual") label(`ctrl2' "Predicted") ///					
				label(`low1' "Lowess") label(`low2' "Lowess") label(`cl1' "`clv'% CI") label(`cl2' "`clv'% CI") symxsize(8) position(6))
		}
		// [1,0,1]
		if "`lowess'" != "" & "`ci'" == "" & "`shade'" != "" {
			local ctrl1 = `tct' + 4				
			local ctrl2 = `tct' + 5	
			local low1 = `ctrl2' + `tct' + 1
			local low2 = `ctrl2' + `tct' + 2
			local mleg subtitle("Intervention starts: `tperlist'") legend(rows(2) region(lcolor(black))  ///
				order(- "`treatdesc': " 2 3 `low1' - "Controls average:" `ctrl1' `ctrl2' `low2') ///
				label(3 "Predicted") label(2 "Actual") label(`ctrl1' "Actual") label(`ctrl2' "Predicted") ///					
				label(`low1' "Lowess") label(`low2' "Lowess") symxsize(8) position(6))			
		}
		// [1,0,0]
		if "`lowess'" != "" & "`ci'" == "" & "`shade'" == "" {			
			local ctrl1 = `tct' + 3				
			local ctrl2 = `tct' + 4	
			local low1 = `ctrl2' + `tct' + 1
			local low2 = `ctrl2' + `tct' + 2
			local mleg subtitle("Intervention starts: `tperlist'") legend(rows(2) region(lcolor(black)) ///
				order(- "`treatdesc': " 1 2 `low1' - "Controls average:" `ctrl1' `ctrl2' `low2') ///
				label(1 "Actual") label(2 "Predicted") label(`ctrl1' "Actual") label(`ctrl2' "Predicted") ///					
				label(`low1' "Lowess") label(`low2' "Lowess") symxsize(8) position(6))		
		}
		// [0,1,1]
		if "`lowess'" == "" & "`ci'" != "" & "`shade'" != "" {
			local ctrl1 = `tct' + 4				
			local ctrl2 = `tct' + 5	
			local cl1 = `ctrl2' + `tct' + 1
			local cl2 = `tct' + `ctrl1' + `ctrl2' + 3						
			local mleg subtitle("Intervention starts: `tperlist'") legend(rows(2) region(lcolor(black)) ///
				order(- "`treatdesc': " 2 3 `cl1' - "Controls average:" `ctrl1' `ctrl2' `cl2') ///
				label(3 "Predicted") label(2 "Actual") label(`ctrl1' "Actual") label(`ctrl2' "Predicted") ///					
				label(`cl1' "`clv'% CI") label(`cl2' "`clv'% CI") symxsize(8) position(6))							
		}
		// [0,1,0]
		if "`lowess'" == "" & "`ci'" != "" & "`shade'" == "" {
			local ctrl1 = `tct' + 3				
			local ctrl2 = `tct' + 4	
			local cl1 = `ctrl2' + `tct' + 1
			local cl2 = `tct' + `ctrl1' + `ctrl2' + 4						
			local mleg subtitle("Intervention starts: `tperlist'") legend(rows(2) region(lcolor(black))  ///
				order(- "`treatdesc': " 1 2 `cl1' - "Controls average:" `ctrl1' `ctrl2' `cl2') ///
				label(1 "Actual") label(2 "Predicted") label(`ctrl1' "Actual") label(`ctrl2' "Predicted") ///					
				label(`cl1' "`clv'% CI") label(`cl2' "`clv'% CI") symxsize(8) position(6))
		}	
		// [0,0,1]
		if "`lowess'" == "" & "`ci'" == "" & "`shade'" != "" {
			local ctrl1 = `tct' + 4				
			local ctrl2 = `tct' + 5	
			local mleg subtitle("Intervention starts: `tperlist'") legend(rows(2) region(lcolor(black))  ///
				order(- "`treatdesc': " 2 3 - "Controls average:" `ctrl1' `ctrl2') ///
				label(3 "Predicted") label(2 "Actual") label(`ctrl1' "Actual") label(`ctrl2' "Predicted") symxsize(8) position(6))			
		}	
		// [0,0,0]
		if "`lowess'" == "" & "`ci'" == "" & "`shade'" == "" {	
			local ctrl1 = `tct' + 3				
			local ctrl2 = `tct' + 4	
			local mleg subtitle("Intervention starts: `tperlist'") legend(rows(2) region(lcolor(black)) ///
				order(- "`treatdesc': " 1 2 - "Controls average:" `ctrl1' `ctrl2') ///
				label(1 "Actual") label(2 "Predicted") label(`ctrl1' "Actual") label(`ctrl2' "Predicted") symxsize(8) position(6))			
		}	
		// save the local
		ret local mleg `mleg'			

end	