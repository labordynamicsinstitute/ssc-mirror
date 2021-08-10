*! xtdcce 1.0 23July2016
*! author Jan Ditzen
*! see viewsource xtdcce.ado for more info.
/*
Jan Ditzen - jd219@hw.ac.uk

This program estimates a dynamic common correlated effects model with or without pooled coefficients. The equation is (Eq. 48, Chudik, Pesaran 2015):

y(it) = c(i) + b1(i) y(i,t-1) +  b2(i) x(it) + b3(i) x(it-1) + sum(l=0,pT) bm(l,i) zm(t-l) + e(it)

b1(i) - b3(i) is a K vector of estimated coefficients. For each unit a seperate vector of coefficients is estimated. The constraint
b(i) = b, i.e. homogenous coefficients across groups, is possible.
pT is the number of lags.
zm(t-l) is the cross sectional average of the l-th lag of y and x. zm is partialled out and is the corresponding coefficient bm(l,i) , not estimated and reported. 

In addition the estimator allows that any x(it) can be endogenous and instrumented by z(it), if exogenous_vars and endogenous_vars are defined. 
Endogenous variables (as well as exogenous) can be mean group and pooled. This function requires ivreg2.


Syntax:

xtdcce lhs rhs [if/]  [if/] , [  Pooled(varlist ts) CRosssectional(varlist ts)  EXOgenous_vars(varlist ts) ENDOgenous_vars(varlist ts) lr(varlist ts) 
	cr_lags(string) RESiduals(string) cluster(string asis) lr_options(string) IVREG2options(string)  
	 POOLEDConstant REPORTConstant NOCONSTant full lists NOCROSSsectional nocd NOIsily trend POOLEDTrend fulliv post_full noomit 
	 JACKknife RECursive ]
		
	
where:
	lhs: dependent variable, time series operators allowed.
	rhs: independent variables , if crossectional is not defined, then the cross sectional averages of all variables in rhs are included.
		If crosssectional is defined, then the cross sectional averages in rhs are not included in the equation. Time series operators allowed.

Options:
	Pooled(varlist ts): adds a pooled variable. For this variable the estimated coefficients are constrained to be equal across all units 
		(b(i) = b for all i). Time series operators allowed.
	CRosssectional(varlist): variables for which the cross sectional averages are included in the model. These are the xm(t) variables. 
		crosssectional, pooled and rhs can contain different variables. If not defined, all rhs variables are included as cross sectional
		averages. Time series operators allowed.
	EXOgenous_vars: Exogenous Variables (Instruments). Time series operators allowed.
	ENDOgenous_vars: Endogenous Variables. Time series operators allowed.
	lr: Variables to be included for long-run cointegration vector. Time series operators allowed.
	
	cr_lags(number): Adds lags of cross sectional averages. If not defined but crosssectional contains a variablelist, then no lags are added.
	residuals(variablename): Generates a variable (name variablename) with the residuals.
	lr_options: Options for Long Run coefficients. Only option "nodivide" allowed. If set, then the coefficients are not divided by the error correction speed of adjustment vector
	ivreg2options: further options relating to ivreg2. See ivreg2, options for more informations.
	cluster: clustered standard errors
	
	REPORTConstant: report constant
	POOLEDConstant: pooles constant
	NOCONnstant: suppresses a common intercept (b0) for all units.
	full: reports unit indiviual estimates.
	lists: lists all variable names and lags of cross sectional averges.
	NOCROSSsectional: no cross sectional averages are added
	nocd: suppresses calculation of CD test statistic
	NOIsily: shows regression 
	trend: adds a linear trend
	POOLEDTrend: pools linear trend
	fulliv: post all ereturns form ivreg2
	
	jackknife: jackknife small time series sample  bias correction
	recursive: recursive mean small time series sample  bias correction
	
	post_full: posts b_full and V_full instead of b_p_mg V_p_mg

xtdcce stores the following in e():
scalars:
                  e(N) =  Number of Observations
                e(N_g) =  Number of Groups/Units
                  e(T) =  Time dimension
				  e(K) =  Number of regressors (including partialled out)
				 e(cd) =  CD Statistic
				e(cdp) =  p-value of CD Statistic
			   e(df_m) =  model degrees of freedom
			    e(mss) =  model sum of squares
				e(rss) =  residual sum of squares
			   e(df_r) =  residual degrees of freedom
				 e(r2) =  R-squared
			   e(r2_a) =  adjusted R-squared
				  e(F) =  F statistic
			   e(rmse) =  root mean squared error
			   e(ll)   = log likelihood
		e(N_partial)   = number of variables partialled out
		e(N_omitted)   = number of omitted variables
		e(N_pooled)	   = number of pooled variables
			   e(minT) = minimum time dimension (unbalanced panel)
			   e(maxT) = maximum time dimension (unbalanced panel)
			   e(avgT) = average time dimension (unbalanced panel)
macros:
               e(tvar) : time variable
              e(idvar) : unit variable
             e(depvar) : Name of dependent variable
		   e(indepvar) : Name of independent variables (mean group)
		    e(omitted) : Names of omitted Variables (variablename_id)
			e(insts)   : Instruments
			e(instd)   : Instrumented (RHS endogenous) variables
				e(cmd) : command line
		  e(cmd_full)  : command line including options
			e(pooled)  : Name of pooled variables
			e(lr)	   : long run variables
matrices:
                  e(b) :  Vector of individual or mean group estimates, includes pooled variables
                  e(V) :  Variance/Covariance matrix of individual or mean group estimates and pooled variables
			 e(b_p_mg) :  Vector of mean group estimates, includes pooled variables
             e(V_p_mg) :  Variance/Covariance matrix of mean group estimates and pooled variables.
			 e(b_full) :  Vector of individual estimates, includes pooled variables
             e(V_full) :  Variance/Covariance matrix of individual estimates and pooled variables
functions:
             e(sample) : marks sample


References:
Chudik, Alexander; Pesaran, M. Hashem, 2015, "Large Panel Data Models with Cross-Sectional Dependence: A Survey", The Oxford Handbook Of Panel Data

Chudik, Alexander; Pesaran, M. Hashem, 2013, "Common Correlated Effects Estimation of Heterogeneous Dynamic Panel Data Models with Weakly Exogenous Regressors", CESifo Working Paper

Packages Required:
- ivreg2
- moremata

Changelog:

18.06.2015 Added lhs to variables which are cross sectioned 
19.06.2015 Added option CD for CD test (xtcd2 test required).	
		   Added pooled variables to cross section if not specified cr() not specified.
23.06.2015 Changed calculation of partialling out. Now a regression with cholsolve is performed.
		   Mata matrices are deleted
24.06.2015 - Pooled variables are now removed from rhs variables, thus pooled variables can appear in rhs as well
		   - long Variablenames (>24 characters are allowed)
		   - no output if pooled or mean group is empty.
		   - Corrected Error in number of periods
		   - Clustered SE work again
25.06.2015 - Added degrees of freedom
		   - Added option noi, which showes the regression
		   - Omitted Variables and their number saved in e()		   
01.12.2015 - added check if cce_lags > 0 and "local drop_before = (`=`tmin'-1*`tdelta'') + `cr_lags' * `tdelta'" when comuputing the number of lags		   
xx.12.2015 - added IV	
11.01.2016 - added e(cmd), fixed naming errors in macros for instruments and naming if varnames are too long, temp vars are removed	
18.01.2016 - naming of matrices correct (in case of endogenous regressors)
28.01.2016 - fixed errors if noconstant is not active and constant is pooled variable
05.02.2016 - fixed error if "if" is used; "if `touse' " was missing when sperate was used.
11.02.2016 - changed option CD into nocd
15.02.2016 - partial out on unit level
15.02.2016 - unbalanced panels: missing values are added for balanced panel
17-20.02.2016 	- long run effects included
21-22.02.2016 - ts added, all variables now in varlists
23.02.2016 - xtdcce_err program added
24.02.2016 - added trend
02.03.2016 - added xtpmg names option for lr_options
05.03.2016 - added post_full option
08.03.2016 - changed 	mata b[lr_index] = (b[lr_index] :/ lr_tmp) into mata b[lr_index] = -(b[lr_index] :/ lr_tmp)
07.04.2016 - check for moremata
29.05.2016 - partial out program added, option for reportconstant added

naming convention / variable lists:
lhs: left hand side var
rhs: right hand side exogenous variables for heterogenous coefficients
pooled: rhs exogenous variables for homogenous coefficients
crosssectional: variables added as cross section means
exogenous_vars: exogenous variables for IV regression (coefficients not shown in output!) (heterogenous coefficients)
endogenous_vars: endogenous variables for IV regressions (coefficients in output) (heterogenous coefficients)
endo_pooled: endogenous variables for IV regression (homogenous coefficients)
exo_pooled: exogenous variables for IV regression (homogenous coefficients)
*/

capture program drop xtdcce

program define xtdcce , eclass sortpreserve
syntax varlist(min=1 ts) [if/] , [ /* 
	*/ Pooled(varlist ts) CRosssectional(varlist ts)  EXOgenous_vars(varlist ts) ENDOgenous_vars(varlist ts) lr(varlist ts)  /*
	*/ cr_lags(string) RESiduals(string) cluster(string asis) lr_options(string) IVREG2options(string)  /*
	*/ POOLEDConstant REPORTConstant NOCONSTant full lists NOCROSSsectional nocd NOIsily trend POOLEDTrend fulliv post_full noomit /*
	*/ JACKknife RECursive ]
	
	version 10
	
	tempvar id_t  esmpl Y_tilde idvar tvar
	
	local cmd_line xtdcce `0'
	
	*Check for Version - necessary for detection of omitted variables in reg
	if `c(stata_version)' < 11 {
		display "Version smaller than 11 - omitted variables will not be detected!"
	}
	else if `c(stata_version)' > 10 {
		version `c(stata_version)'
	}
	*Check for moremata
	capture mata mm_nunique((10,1))
	if _rc != 0 {
		xtdcce_err 3499 `d_idvar' `d_tvar' , msg("moremata not installed.")
	}
	qui{
		tsset
		local d_idvar  `r(panelvar)'
		local d_tvar  `r(timevar)'
		local d_balanced  `r(balanced)'
		egen `idvar' = group(`d_idvar')
		egen `tvar' = group(`d_tvar')
		sort `idvar' `tvar'
		gen `id_t' = _n
		putmata idt = `id_t' , replace
		preserve
			tsset `idvar' `tvar'
			marksample touse
			**find ts operators
			if "`s(tsops)'"  == "true" {
				foreach  liste in varlist pooled crosssectional exogenous_vars endogenous_vars lr {
					if "``liste''" != "" {
						tsunab stripped_name: ``liste''
						tsrevar	``liste''
						local l_tmp `r(varlist)'
						
						local changed_name : list l_tmp - `liste'
						local stripped_name : list stripped_name - l_tmp
						
						local `liste' `l_tmp'
						local change_list `change_list' `changed_name'						
						local old_list `old_list' `stripped_name'
					}
				}
			}
			recast double `varlist' `crosssectional' `pooled' `exogenous_vars' `endogenous_vars' `lr'
			**tsfill if panel is unbalanced
			if "`d_balanced'" != "strongly balanced" {
				tsfill, full
				replace `id_t' = _N + _n + 1 if `id_t' == .
			}
			
			sort `idvar' `tvar'
			
			*Check for IV and if ivreg2 is installed
			if "`exogenous_vars'" != "" & "`endogenous_vars'" != "" {
				local IV = 1
				capture ivreg2, version
				if _rc != 0 {
					restore
					xtdcce_err 199 `d_idvar' `d_tvar' , msg("ivreg2 not installed.")					
				}
				if "`ivdiag'" != "" {
					local ivdiag nocollin noid
				}
			}
			else {
				local endogenous_vars ""
				local exogenous_vars ""
				local IV = 0
			}
			*Check for bias correction
			if "`jackknife'" == "jackknife" & "`recursive'" == "recursive" {
				restore
				xtdcce_err 184 `d_idvar' `d_tvar' , msg("options jackknife and recursive may not be combined.")	
			}
			
			*Check for clustered SE
			if "`cluster'" != "" {
				local cluster "cluster(`cluster')"
			}
					
			*Check for long run coefficients
			if "`lr'" == "" {
				local lr_options ""
			}
			
			*Check for variablename length
			local i = 1
			local complist `varlist' `pooled' `crosssectional' `exogenous_vars' `endogenous_vars' `lr'
			local complist : list uniq complist
			foreach var in `complist' {
				if length("`var'") > 24 {
					tempname short_`i'
					local change_list `change_list' `short_`i''
					local old_list `old_list' `var'
					rename `var' `short_`i''
						
					local varlist = subinword("`varlist'","`var'","`short_`i''",.)
					local pooled = subinword("`pooled'","`var'","`short_`i''",.)
					local crosssectional = subinword("`crosssectional'","`var'","`short_`i''",.)
					local exogenous_vars = subinword("`exogenous_vars'","`var'","`short_`i''",.)
					local endogenous_vars = subinword("`endogenous_vars'","`var'","`short_`i''",.)
					local lr = subinword("`lr'","`lr'","`short_`i''",.)
					
					local i = `i' + 1
				}				
			}
			
			gettoken lhs rhs : varlist	
			
			*Remove pooled variables from rhs
			local rhs : list rhs - pooled
			local rhs : list rhs - endogenous_vars
			local rhs : list rhs - exogenous_vars
			
			*Identify LR not in pooled, endogenous or exogenous vars
			local lr_single: list lr - pooled
			local lr_single: list lr_single - rhs
			local lr_single: list lr_single - endogenous_vars
			local lr_single: list lr_single - exogenous_vars
			
			local rhs `rhs' `lr_single'
			
			local endo_pooled: list endogenous_vars & pooled
			local exo_pooled: list exogenous_vars & pooled
			
			local endogenous_vars : list endogenous_vars - endo_pooled
			local exogenous_vars : list exogenous_vars - exo_pooled
			
			local pooled: list pooled - endo_pooled
			local pooled: list pooled - exo_pooled
						
			* if crosssectional empty, put all rhs vars and lhs
			if "`crosssectional'" == "" {
				local crosssectional `lhs' `rhs' `pooled' `endogenous_vars' `endo_pooled' 
			}			
			
			*Add trend
			if "`pooledtrend'" != "" | "`trend'" != "" {
				tempvar trend
				sum `d_tvar'
				*gen `trend' = `d_tvar' - `r(min)'
				gen `trend' = `tvar'
				if "`pooledtrend'" == "" & "`trend'" != "" {
					local rhs `rhs' `trend' 
				}
				else if "`pooledtrend'" != "" & "`trend'" == "" {
					local pooled `pooled' `trend'
				}
				else {
					restore
					xtdcce_err 184 `d_idvar' `d_tvar' , msg("options trend and pooledtrend may not be combined.")	
				}
				local change_list `change_list' `trend' 
				local old_list `old_list' trend
			}
			/*
			Constant/Intercept block
			if reportconstant is switched on, constant will be reported, 
			otherwise it will be partialled out (if poolconstant not defined) 
			or all variables will be demeaned to remove homogenous constant
			 Types of constant: 
				1 heterogenous & partialled out
				2 homogenous (pooled) & removed (set to zero) as it is zero (only in case of balanced panel)
				3 heterogenous & displayed
				4 homogenous & not displayed (calculated but supressed)
				5 homogenous & displayed
			*/
			if "`noconstant'" == "" {
				if "`reportconstant'" != "reportconstant" {
					if "`pooledconstant'" != "pooledconstant" {
						tempvar constant
						gen `constant' = 1	
						local constant_type = 1
					}
					else if "`pooledconstant'" == "pooledconstant" {
						*Check if all vars are in crosssectional mean, if so, no constant needed
						local lhsrhs `lhs' `rhs' `pooled' `endogenous_vars' `endo_pooled' 
						local const_check : list lhsrhs - crosssectional
						if "`d_balanced'" == "strongly balanced" & "`rhs'`endogenous_vars'" == "" & "`const_check'" == "" {
							local constant_type = 2	
							local noconstant noconstant					
						}
						else {
							tempvar constant 
							gen `constant' = 1
							local pooled `pooled' `constant'
							local constant_type = 4 
						}
					}
					local noconstant_reg noconstant
				}
				else if "`reportconstant'" == "reportconstant" {
					tempvar constant 
					gen `constant' = 1
					local noconstant_reg noconstant
					if "`pooledconstant'" == "pooledconstant" {
						local pooled `pooled' `constant'
						local constant_type = 5
					}
					else if "`pooledconstant'" != "pooledconstant" {
						*constant not pooled
						local rhs `rhs' `constant'
						local constant_type = 3 
					}				
				}
			}
			else {
				local noconstant_reg noconstant
			}	

			
			if "`nocrosssectional'" == "nocrosssectional" {
				local crosssectional ""
				local cr_lags = 0
			}
			if "`crosssectional'" != "" & "`cr_lags'" == ""{
				local cr_lags = 0
			}
			
			**Recursive Mean adjustment
			if "`recursive'" == "recursive" {
				tempvar s_mean
				gen `s_mean' = 0
				local r_varlist `lhs' `rhs' `pooled' `crosssectional' `endogenous_vars' `exogenous_vars' `endo_pooled' `exo_pooled'
				local r_varlist: list uniq r_varlist
				local r_varlist: list r_varlist - constant

				foreach var in `r_varlist' {
					by `idvar' (`tvar'), sort: replace `s_mean' = sum(`var'[_n-1]) / (`tvar'-1) if `touse'
					replace `s_mean' = 0 if `s_mean' == .
					replace `var' = `var' - `s_mean' 
				}
				sort `idvar' `tvar'
			}			
			
			*Check if number of variables exceeds number of observations
			local rhs_endo `rhs' `endogenous_vars' 
			local num_rhs : list sizeof rhs_endo
			local endo_tot `pooled' `endo_pooled' `exo_pooled'
			local num_pooled : list sizeof endo_tot
			local num_crosssectional : list sizeof crosssectional
			
			putmata `idvar' if `touse' , replace 
			mata: N_g = mm_nunique(`idvar') 
			mata: st_local("N_g",strofreal(N_g)) 
			qui sum `lhs' if `touse'
			local N = `r(N)'
			local num_partialled_out = `N_g' * ((`cr_lags' + 1 *("`nocrosssectional'"=="") ) * (`num_crosssectional' ))
			local num_mg_regression = `num_pooled' + `N_g' * `num_rhs'
			local num_K = `num_pooled' +  `num_rhs'
			local K_total = `num_mg_regression' + `num_partialled_out'
			if `N' < `K_total' {
				restore
				xtdcce_err 2001 `d_idvar' `d_tvar' , msg("More variables (`K_total') than observations (`N').")
			}	
						
			*create CR Lags
			if "`cr_lags'" != "" {
				tempvar cr_mean
				foreach var in `crosssectional' { 
					by `tvar' , sort: egen double `cr_mean' = mean(`var') if `touse'
					forvalues lag=0(1)`cr_lags' {
						sort `idvar' `tvar'
						gen double L`lag'_m_`var' = L`lag'.`cr_mean'  if `touse'
						local clist1  `clist1'  L`lag'_m_`var' 
					}
					drop `cr_mean' 
				}
			}
			local num_demeaned = 0
			
			***Restrict dataset - Remove time periods which are lost because of lags
			if "`cr_lags'" > "0" {
				replace `touse' = 0 if `tvar' <= `cr_lags' 
			}
			
			**Add constant if heterogenous to list with variables to partialled out
			if  "`constant_type'" == "1" {
				local clist1 `clist1' `constant'
				local crosssectional `crosssectional' `constant'
				local num_partialled_out = `num_partialled_out' + 1
			}
			
			*Check if CD is activated but not residuals 
			if "`residuals'" == "" {
				tempvar residuals_var	
				local residuals `residuals_var'
			}	
			local num_adjusted = `num_partialled_out' 
			*Restrict set and exclude variables with missings
			markout `touse' `lhs' `pooled' `rhs' `exogenous_vars' `endogenous_vars' `endo_pooled' `exo_pooled' 
			if "`omit'" == "" {
				local omitted `lhs' `rhs'  `pooled'  `endo_pooled' 
				noi _rmcoll `omitted' if `touse' , noconstant forcedrop
				local omitted_var `r(varlist)'
				local omitted : list omitted - omitted_var
				local omitted_N : list sizeof omitted
				
				local rhs : list rhs - omitted
				local pooled : list pooled - omitted
				local endo_pooled : list endo_pooled - omitted
			}			
**********************************************************************************************************
*******************************************  Partialling Out *********************************************
**********************************************************************************************************
			*only partial out if list with variables to partial out is not empty
			if "`clist1'" != "" {			
				tempvar touse_ctry
				gen `touse_ctry' = 0
				sort `idvar' `tvar'	
				forvalues ctry = 1(1)`N_g' {
					replace `touse_ctry' =  1 if `touse'  & `ctry' == `idvar'
					mata xtdcce_m_partialout("`lhs' `pooled' `rhs' `exogenous_vars' `endogenous_vars' `endo_pooled' `exo_pooled'","`clist1'","`touse_ctry'",rk=.)
					replace `touse_ctry' =  0
					*Check if X1X1 matrix is full rank
					mata st_local("rk",strofreal(rk[1,1]))
					mata st_local("rkrow",strofreal(rk[1,2]))
					if "`rk'" < "`rkrow'" {
						restore
						xtdcce_err 506 `d_idvar' `d_tvar' , msg("Rank condition on cross section means not satisfied.")
					}
				}
			}

			local rhs_list
			foreach var in `rhs' {
				qui separate `var' if `touse' , by(`idvar')
				local rhs_list `rhs_list' `r(varlist)'
				recode `r(varlist)' (missing = 0) if `touse'	
			}		

			foreach var in `exogenous_vars' {
				qui separate `var' if `touse'  , by(`idvar')
				local exo_list `exo_list' `r(varlist)'
				recode `r(varlist)' (missing = 0) if `touse'	
			}
			local exo_list `exo_pooled'	 `exo_list' 
					
			foreach var in `endogenous_vars' {
				qui separate `var' if `touse' , by(`idvar')
				local endo_list `endo_list' `r(varlist)'
				recode `r(varlist)' (missing = 0) if `touse'	
			}
			local endo_list `endo_pooled' `endo_list' 
*************************************************************************************************************
**************************************Regression*************************************************************
*************************************************************************************************************
			sort `idvar' `tvar'	
			if `IV' == 0 {
				local reg_varlist `pooled' `rhs_list'
				
				if "`cluster'" != "" {
					local cluster = subinstr("`cluster'","cluster(","",.)
					local cluster = subinstr("`cluster'",")","",.)
				}
				markout `touse' `lhs' `reg_varlist'
				
				if "`jackknife'" == "jackknife" {
					tempvar jack_indicator_a jack_indicator_b
					
					sum `tvar' if `touse'
					local jack_T = int(`r(max)' / 2)
					
					gen `jack_indicator_a' = `touse' * (`tvar' <= `jack_T')
					gen `jack_indicator_b' = `touse' * (`tvar' > `jack_T')
					
					mata xtdcce_m_reg("`lhs' `reg_varlist'","`jack_indicator_a'",`num_adjusted',b_a=., `residuals'=. , V_a=.,stats=.,"`cluster'")
					mata xtdcce_m_reg("`lhs' `reg_varlist'","`jack_indicator_b'",`num_adjusted',b_b=., `residuals'=. , V_b=.,stats=.,"`cluster'")
				}
				
				mata xtdcce_m_reg("`lhs' `reg_varlist'","`touse'",`num_adjusted',b=., `residuals'=. , V=.,stats=.,"`cluster'")		
				gen `esmpl' = `touse'
				putmata `esmpl' `esmpl'_id = `id_t' `id_t'_res = `id_t'  if `touse' , replace
				
				if "`jackknife'" == "jackknife" {
					mata cov_ma = mean(b:*b_a) :- mean(b) :* mean(b_a)
					mata cov_ab = mean(b_b:*b_a) :- mean(b_b) :* mean(b_a)
					mata cov_mb = mean(b:*b_b) :- mean(b) :* mean(b_b)
					
					mata b = 2:*b :- 0.5:*(b_a :+ b_b)
					mata V = 4:*V :+ 0.25:* V_a :+ 0.25 :* V_b  :+ 2:*(cov_ab :-cov_ma :- cov_mb)
				}
				
				mata st_matrix("b",b')
				mata st_matrix("V",V)
				mata st_local("n_reg",strofreal(stats[1,1]))
				
				matrix colnames b = `reg_varlist'
				matrix colnames V = `reg_varlist'
				matrix rownames V = `reg_varlist'
									
				ereturn clear
				ereturn post b V , obs(`n_reg') esample(`esmpl') depname(`lhs')
				
				mata st_matrix("stats",stats)
				local i = 1
				foreach stat in N K K_reg df_r  rss  mss  sst  s2  r2  r2_a  F rmse {
					scalar `stat' = stats[`i',1]
					ereturn scalar `stat' = stats[`i',1]
					local i = `i' + 1
				}
				ereturn scalar df_m = e(K_reg)
				scalar df_m = e(df_m)
			}			
			if `IV' == 1 {
				if "`jackknife'" == "jackknife" {
					tempvar jack_indicator_a jack_indicator_b
					
					sum `tvar' if `touse'
					local jack_T = int(`r(max)' / 2)
					
					gen `jack_indicator_a' = `touse' * (`tvar' <= `jack_T')
					gen `jack_indicator_b' = `touse' * (`tvar' > `jack_T')
										
					`noisily' ivreg2 `lhs' `pooled' `rhs_list' (`endo_list' = `exo_list') if `jack_indicator_a' , `cluster' `noconstant_reg' `ivdiag' `ivreg2options' sdofminus(`num_partialled_out')
					mata b_a = st_matrix("e(b)")
					mata V_a = st_matrix("e(V)")						
					`noisily' ivreg2 `lhs' `pooled' `rhs_list' (`endo_list' = `exo_list') if `jack_indicator_b' , `cluster' `noconstant_reg' `ivdiag' `ivreg2options' sdofminus(`num_partialled_out')
					mata b_b = st_matrix("e(b)")
					mata V_b = st_matrix("e(V)")
				}			
			
				`noisily' ivreg2 `lhs' `pooled' `rhs_list' (`endo_list' = `exo_list') if `touse' , `cluster' `noconstant_reg' `ivdiag' `ivreg2options' sdofminus(`num_partialled_out')
				local instd = e(instd)
				local insts = e(insts)
				local collin = e(collin)
				scalar df_r = e(Fdf2)
				if "`ivdiag'" != "" {
					noi overid
				}
				if "`fulliv'" == "fulliv" {
					foreach scal in N yy yyc rss mss df_m df_r r2u r2c r2 r2_a ll rankxx rankzz rankV ranks rmse F N_clust /*
						*/ N_clust1 N_clust2 bw lambda kclass full sargan sarganp sargandf j jp arubin /*
						*/ arubinp arubin_lin arubin_linp arubindf idstat idp iddf widstat arf arfp archi2 /*
						*/ archi2p ardf ardf_r redstat redp reddf cstat cstatp cstatdf cons center partialcons partial_ct {
							if "`e(`scal')'" != "" scalar ivreg2_`scal' = e(`scal')
					}
					foreach macr in cmd cmdline ivreg2cmd version model depvar instd insts inexog exexog collin dups ecollin clist redlist partial small wtype /*	
						*/ wexp clustvar vcetype kernel firsteqs rfeq sfirsteq predict {
							if "`e(`macr')'" != "" local ivreg2_`macr'  "`e(`macr')'"
					}
					foreach matr in S W first ccev dcef {
							if "`e(`matr')'" != "" matrix  ivreg2_`matr' = e(`matr') 
					}
					
					if "`jackknife'" == "jackknife" {
						mata b = st_matrix("e(b)")
						mata V = st_matrix("e(V)")
						mata cov_ma = mean(b:*b_a) :- mean(b) :* mean(b_a)
						mata cov_ab = mean(b_b:*b_a) :- mean(b_b) :* mean(b_a)
						mata cov_mb = mean(b:*b_b) :- mean(b) :* mean(b_b)
						
						mata b = 2:*b :- 0.5:*(b_a :+ b_b)
						mata V = 4:*V :+ 0.25:* V_a :+ 0.25 :* V_b  :+ 2:*(cov_ab :-cov_ma :- cov_mb)
						
						mata st_matrix("b",b)
						mata st_matrix("V",V)
						
						ereturn repost b V
					}
					
				}				
				gen `esmpl' = e(sample) & `touse'
				putmata `esmpl' `esmpl'_id = `id_t' if `touse' , replace
				if "`residuals'" != "" | "`cd'" == ""{
					capture drop `residuals'
					predict `residuals' if e(sample) & `touse' , residuals
					putmata `residuals' `id_t'_res = `id_t' if e(sample) & `touse' , replace
				}
				
				scalar K = e(df_m)
				scalar df_m = K	
				scalar N = e(N)
				scalar F = e(F)
				scalar r2 = e(r2)
				scalar r2_a = e(r2_a)
				scalar rmse = e(rmse)
				scalar ll = e(ll)
				scalar rss = e(rss)
				scalar mss = e(mss)
				local N = e(N)
				
				local omitted `e(collin)'
				local omitted_N : list sizeof omitted 				
			}	
		
		restore
		getmata `esmpl' , update id(`id_t' = `esmpl'_id)
		getmata `residuals' , update id(`id_t' = `id_t'_res)
	
		**Remove omitted variables from variablelists
		foreach var in rhs rhs_list pooled endogenous_vars exogenous_vars endo_list endo_pooled exo_pooled lr {
			local `var' : list `var' - omitted		
		}		
		
		*Remove constant if type 4 from pooled list and matrices
		if "`constant_type'" == "4" {
			local pooled: list pooled - constant
		}		
		
		local b_v_names : colnames e(b)
		mata b_v_names = tokens(("`b_v_names'"))
		
		mata b = st_matrix("e(b)")
		mata V = st_matrix("e(V)")

		matrix b = e(b)
		matrix V = e(V)
****************************************************************************
***********************************LR Computation***************************
****************************************************************************
		*Change coefficients for LR if option divide activated
		*Use Delta Method to calculate variance-covariance matrix, where g is derivative 
		*and variance becomes g*V*g'
		if strmatch("`lr_options'","*nodivide*") == 0 {
			gettoken lr_1 lr_rest : lr
			mata lr_1_indic = strmatch(b_v_names,"`lr_1'*")
			mata lr_1 = select(b,lr_1_indic)
			mata lr_1_index = selectindex(lr_1_indic)
			mata lr_tmp = lr_1
			mata g = I(rows(V))
			
			foreach var in `lr_rest' {
				mata lr_indic = strmatch(b_v_names,"`var'*")
				mata lr_index = selectindex(lr_indic)
				**check if running lr variable is pooled, if so, then take mean of lr_1
				mata st_local("lr_num",strofreal(sum(lr_indic)))
				mata lr_tmp = lr_1
				if "`lr_num'" == "1" { 
					mata lr_tmp = mean(lr_1')
				}
				mata g = xtdcce_PointByPoint(lr_index,lr_index, (1:/ lr_tmp),g)
				mata g = xtdcce_PointByPoint(lr_index,lr_1_index, (- b[lr_index] :/ (lr_tmp:^2)), g)
				mata b[lr_index] = -(b[lr_index] :/ lr_tmp)
			}			
			mata V = g*V*g'
			
			mata st_matrix("V",V)
			mata st_matrix("b",b)
			matrix b = e(b)
			matrix V = e(V)
		}
****************************************************************************
***********************************Coefficients*****************************
****************************************************************************
		*Change Names back (needed for ts vars)
		tempname t_p_mg se_p_mg b_full  V_full V_p_mg b_p_mg
		
		local i = 1
		foreach var in `change_list' {
			local old_name = word("`old_list'",`i')
			local rhs = subinstr("`rhs'","`var'","`old_name'",.)
			local rhs_list = subinstr("`rhs_list'","`var'","`old_name'",.)
			local pooled = subinstr("`pooled'","`var'","`old_name'",.)
			local crosssectional = subinstr("`crosssectional'","`var'","`old_name'",.)	
			local endogenous_vars = subinstr("`endogenous_vars'","`var'","`old_name'",.)
			local exogenous_vars = subinstr("`exogenous_vars'","`var'","`old_name'",.)
			local endo_list = subinstr("`endo_list'","`var'","`old_name'",.)
			local endo_pooled = subinstr("`endo_pooled'","`var'","`old_name'",.)
			local exo_pooled  = subinstr("`endo_pooled'","`var'","`old_name'",.)
			local b_v_names  = subinstr("`b_v_names'","`var'","`old_name'",.)
			local lr = subinstr("`lr'","`var'","`old_name'",.)
			local lhs = subinstr("`lhs'","`var'","`old_name'",.)
			local clist1 = subinstr("`clist1'","`var'","`old_name'",.)
			local i = `i' + 1
		}	
				
		*Rename constant in rhs and variable lists
		local rhs = subinstr("`rhs'","`constant'","_cons",.)
		local rhs_list = subinstr("`rhs_list'","`constant'","_cons",.)
		local pooled = subinstr("`pooled'","`constant'","_cons",.)
		local b_v_names  = subinstr("`b_v_names'","`constant'","_cons",.)
		local crosssectional = subinstr("`crosssectional'","`constant'","_cons",.) 
		local clist1 = subinstr("`clist1'","`constant'","_cons",.)
		matrix colnames b = `b_v_names'
		matrix rownames V = `b_v_names'
		matrix colnames V = `b_v_names'
		local constant "_cons"
		
		mata b_v_names = tokens(("`b_v_names'"))
		
		**Here only MG Variables (pooled variables are below, even if endogenous!!)
		if "`endogenous_vars'`rhs'" != "" {
			mata b_mg = J(1,0,.)
			mata ri = 0
			foreach var in `endogenous_vars' `rhs' {
				mata b_mg = (b_mg ,(select(b,strmatch(b_v_names,"`var'*"))))	
				mata ri = ri + 1
			}
			mata: b_mg = rowshape(b_mg,ri)'
			**Divide by rows (n) as this is the variance of a sample mean (see Eberhardts xtmg for example), small sample adjustment (-1) done in quadvariance! 
			mata: b_V = quadmeanvariance(b_mg)
			mata: V_mg = b_V[|2,1 \ ., .|]/(rows(b_mg))
			mata: b_mg = b_V[1,.]
		}
		**Here only pooled variables (inclduing endogenous vars!!)
		if "`pooled'`endo_pooled'" != "" {
			mata b_p = J(1,0,.)
			mata V_p_liste = J(1,0,.)
			foreach var in `pooled' `endo_pooled' {
				mata b_p = (b_p ,(select(b,strmatch(b_v_names,"`var'"))))
				mata V_p_liste =  (V_p_liste, selectindex(strmatch(b_v_names,"`var'")))
			}
			mata V_p = V[V_p_liste,V_p_liste]
			mata mata drop V_p_liste
		}
		**Correct Order of Variance/Covariance and Coefficient matrix
		mata V_p_liste = J(1,0,.)
		foreach var in `pooled' `endo_list' `rhs_list' {
			mata V_p_liste =  (V_p_liste, selectindex(strmatch(b_v_names,"`var'")))
		}
		mata b = b[.,V_p_liste]
		mata V = V[V_p_liste,V_p_liste]
		mata mata drop V_p_liste
		***Construct V_p_mg and b_p_mg
		**Only Pooled Vars
		if "`endo_pooled'`pooled'" != "" &  "`endogenous_vars'`rhs'" == "" {
			mata b_p_mg = b_p
			mata V_p_mg = V_p
		}
		**Only Endo \ RHS Vars
		if "`endo_pooled'`pooled'" == "" &  "`endogenous_vars'`rhs'" != "" {
			mata b_p_mg = b_mg
			mata V_p_mg = V_mg
		}
		**Endo \ RHS Vars and Pooled
		if "`endo_pooled'`pooled'" != "" &  "`endogenous_vars'`rhs'" != "" {
			mata b_p_mg = (b_p , b_mg)
			mata V_p_mg = ( (V_p , J(rows(V_p),cols(V_mg),0)) \ (J(rows(V_mg),cols(V_p),0) , V_mg)) 
		}
		**Transfer back to Stata
		mata st_matrix("`b_p_mg'",b_p_mg)
		mata st_matrix("`V_p_mg'",V_p_mg)
		matrix `V_full' = V
		matrix `b_full' = b
		
		if strmatch("`lr_options'","*xtpmg*") == 1 {
			gettoken lr_1 lr_rest : lr
	
			local lr = subinstr("`lr'","`lr_1'","ec",.)
			foreach liste in pooled endo_pooled  endogenous_vars rhs {
				local `liste' = subinstr("``liste''","`lr_1'","ec",.)
			}
			
			local sr_var `pooled' `endo_pooled'  `endogenous_vars' `rhs'
			local sr_var : list sr_var - lr
			local mat_names  `lr_rest' ec `sr_var'
			
			mata names_indic = tokens("`pooled' `endo_pooled'  `endogenous_vars' `rhs'")
			mata indic_lr = J(1,cols(names_indic),0)
			foreach vars in `lr' {
				mata indic_lr = indic_lr + strmatch(names_indic,"`vars'")
			}
			mata indic_sr = (indic_lr :== 0)
			mata indic_lr_sr = (selectindex(indic_lr) , selectindex(indic_sr))
			*move first element of lr into 1st of sr
			mata indic_lr_sr = indic_lr_sr[1,(2..sum(indic_lr),1,sum(indic_lr)+1..cols(indic_lr_sr))]
			mata b_p_mg = b_p_mg[1,indic_lr_sr]
			mata V_p_mg = V_p_mg[indic_lr_sr,indic_lr_sr]
			
			mata st_matrix("`b_p_mg'",b_p_mg)
			mata st_matrix("`V_p_mg'",V_p_mg)
			
			mata names_eq = invtokens((J(1,sum(indic_lr)-1,"ec"),J(1,sum(indic_sr)+1,"SR")))
			mata st_local("names_eq",names_eq)
			
			matrix coleq `b_p_mg' = `names_eq'
			matrix coleq `V_p_mg' = `names_eq'
			matrix roweq `V_p_mg' = `names_eq'
			matrix rownames `b_p_mg' = y1			
		}
		else {
			*Matrix Names for b_p_mg and V_p_mg
			local mat_names `pooled' `endo_pooled'  `endogenous_vars' `rhs'
		}
		matrix colnames `b_p_mg' = `mat_names'
		matrix rownames `V_p_mg' = `mat_names'
		matrix colnames `V_p_mg' = `mat_names'
		
		*Standard Errors and t stat for b_p_mg
		mata: se_p_mg = sqrt(diagonal(V_p_mg))
		mata: st_matrix("`se_p_mg'",se_p_mg)
		
		mata: t_p_mg = b_p_mg':/se_p_mg
		mata: st_matrix("`t_p_mg'",t_p_mg)
		
		matrix rownames `se_p_mg' = `mat_names'
		matrix rownames `t_p_mg' = `mat_names'
		
		local T = N / `N_g'
		scalar N_g = `N_g'
		scalar T = `T'

		if "`full'" != "" {
			mata: se_full = sqrt(diagonal(st_matrix("`V_full'")))
			mata: st_matrix("se_full",se_full)
			
			mata: b_full = st_matrix("`b_full'")
			mata: t_full = b_full':/se_full
			mata: st_matrix("t_full",t_full)
			local b_full_names: colnames `b_full'
			matrix rownames se_full = `b_full_names'
			matrix rownames t_full = `b_full_names'
		}
				
		*Get Tmin, Tmax and Tmin in case of unbalanced dataset
		if "`d_balanced'" != "strongly balanced" {
			tempvar ts_stats
			by `esmpl' `idvar' , sort: gen `ts_stats' = _N 
			sum `ts_stats' if `esmpl' == 1
			local minT = `r(min)'
			local maxT = `r(max)'
			local meanT = `r(mean)'
		}
****************************************************************************
***********************************Return***********************************
****************************************************************************
		*replace missings in esample
		qui tsset `d_idvar' `d_tvar'
		replace `esmpl' = 0 if `esmpl' == .
		if "`post_full'" == "post_full" {
			matrix b = `b_full'
			matrix V = `V_full'
		}
		else {
			matrix b = `b_p_mg'
			matrix V = `V_p_mg'
		}
		
		ereturn clear
		ereturn post b V , obs(`N') esample(`esmpl') depname(`lhs')
		
		if `IV' == 1 {
			ereturn local insts "`insts'"
			ereturn local instd "`instd'"
			
			if "`fulliv'" == "fulliv" {
				foreach scal in N yy yyc rss mss df_m df_r r2u r2c r2 r2_a ll rankxx rankzz rankV ranks rmse F N_clust /*
					*/ N_clust1 N_clust2 bw lambda kclass full sargan sarganp sargandf j jp arubin /*
					*/ arubinp arubin_lin arubin_linp arubindf idstat idp iddf widstat arf arfp archi2 /*
					*/ archi2p ardf ardf_r redstat redp reddf cstat cstatp cstatdf cons center partialcons partial_ct {
						if "`ivreg2_`scal''" != "" ereturn scalar ivreg2_`scal' = `ivreg2_`scal''
				}
				foreach macr in cmd cmdline ivreg2cmd version model depvar instd insts inexog exexog collin dups ecollin clist redlist partial small wtype /*	
					*/ wexp clustvar vcetype kernel firsteqs rfeq sfirsteq predict{
					if "`ivreg2_`macr''" != "" 	ereturn local  ivreg2_`macr'  "`ivreg2_`macr''"
				}
				foreach matr in b V S W first ccev dcef {
					if "`ivreg2_`matr''" != "" matrix  ivreg2_`matr' = `ivreg2_`matr''
				}
			} 			
		}
		ereturn scalar N = N
		ereturn scalar N_g = N_g
		if "`d_balanced'" != "strongly balanced" {
			ereturn scalar minT = `minT'
			ereturn scalar maxT = `maxT'
			ereturn scalar avgT = `meanT'		
		}
		ereturn scalar T = T
		ereturn scalar K = K
		ereturn scalar N_partial = `num_partialled_out'
		ereturn scalar F = F
		ereturn scalar r2 = r2
		ereturn scalar r2_a = r2_a
		ereturn scalar rmse = rmse
		ereturn scalar df_m = df_m
		ereturn scalar df_r = df_r
		ereturn scalar rss = rss
		ereturn scalar mss = mss
		ereturn scalar N_pooled = `num_pooled'
		
		ereturn local changed_names "`old_list'"
		ereturn local indepvar "`pooled' `rhs'"
		ereturn local idvar = "`d_idvar'"
		ereturn local tvar = "`d_tvar'"
		
		ereturn local cmd "xtdcce"
		ereturn local cmd_full "`cmd_line'"
		ereturn local pooled "`pooled'"
		ereturn local lr "`lr'"
		
		if "`omitted'" != "" {
			ereturn local omitted "`omitted'"
			ereturn scalar N_omitted = `omitted_N'
		}
		
		if "`post_full'" == "post_full" {
			ereturn matrix b_p_mg = `b_p_mg' , copy
			ereturn matrix V_p_mg = `V_p_mg' , copy
		}
		else {
			ereturn matrix b_full = `b_full' , copy
			ereturn matrix V_full = `V_full' , copy
		}
		if "`cd'" == "" {
			capture xtcd2 `residuals' , noest rho 
			if _rc != 0 {
				noi display as error "xtcd2 not installed" 
				local nocd nocd
				}
			else {
				ereturn scalar cd = `r(CD)'
				ereturn scalar cdp = `r(p)'
			}
		}
	
		if "`cluster'" == "" {
			local pf = 1 - F(e(df_m),e(df_r),e(F))
		}
		else {
			local pf = 1- chi2(`=`e(K)'-1',e(F))
		}
	}
****************************************************************************
***********************************Output***********************************
****************************************************************************
	di ""
	di ""
	if "`pooled'" != "" {
		local textpooled "Pooled "
	}
	if `IV' == 1 {
		local textiv " IV"
	}
	display as text "Dynamic Common Correlated Effects - `textpooled'Mean Group`textiv'"
	#delimit ;
		di _n in gr "Panel Variable (i): " in ye e(idvar) 
				   _col(60) in gr "Number of obs" _col(79) "=" 
				   _col(81) in ye %9.0f e(N) ;
		di in gr "Time Variable (t): " in ye abbrev(e(tvar),12) in gr
					_col(60) "Number of groups" _col(79) "="
					_col(81) in ye %9.0g e(N_g) ;
	#delimit cr
	if "`d_balanced'" == "strongly balanced" {
		#delimit ;
			di in gr _col(60) in gr "Obs per group (T)" _col(79) "="
					_col(81) in ye %9.0f e(T) ;
		#delimit cr
	}
	else {	
		#delimit ;
			di "" ;
			di in gr _col(60) in gr "Obs per group:" _col(79) ;
			di in gr _col(75) in gr "min = "
					_col(81) in ye %9.0f e(minT) ;	
			di in gr _col(75) in gr "avg = " 
					_col(81) in ye %9.0f e(meanT) ;	
			di in gr _col(75) in gr "max = " 
					_col(81) in ye %9.0f e(maxT) ;
		#delimit cr	
	}
	#delimit ;
		di "" ;
		di in gr _col(60) in gr "F("
					in ye %7.0f e(df_m) ", " in ye %7.0f e(df_r) ")" _col(79) "="
					_col(81) in ye %9.2f e(F) ;
		di in gr _col(60) in gr "Prob > F" _col(79) "="
					_col(81) in ye %9.2f `pf' ;
		di in gr _col(60) in gr "R-squared" _col(79) "="
					_col(81) in ye %9.2f e(r2) ;
		di in gr _col(60) in gr "Adj. R-squared" _col(79) "="
					_col(81) in ye %9.2f e(r2_a) ;
		di in gr _col(60) in gr "Root MSE" _col(79) "="
					_col(81) in ye %9.2f e(rmse) ;
	#delimit cr
	
	if "`cd'" == "" {
		di ""
		#delimit ;
			di _col(60) in gr "CD Statistic" _col(79) "="
			   _col(81) in ye in ye %9.2f e(cd) ;
			di _col(60) in gr "   p-value" _col(79) "="
			   _col(81) in ye in ye %9.4f e(cdp) ;	
		#delimit cr
	
	}

	local level =  `c(level)'
	local col_i = 24
	
	di as text "{hline `col_i'}{c TT}{hline `=89-`col_i''}"
	di as text %`col_i's abbrev("`lhs'",`col_i') "{c |}" _c
	local col = `col_i' + 9
	di as text _col(`col') "Coef." _c
	local col = `col' + 8
	di as text _col(`col') "Std. Err."  _c
	local col = `col' + 15
	di as text _col(`col') "z"  _c
	local col = `col' + 5
	di as text _col(`col') "P>|z|"  _c
	local col = `col' + 10
	di as text _col(`col') "[`level'% Conf. Interval]"    

	di as text "{hline `col_i'}{c +}{hline `=89-`col_i''}"
	scalar cv = invnorm(1 - ((100-`level')/100)/2)
	if "`lr'" != "" {
		di "Short Run Estimates:" _col(`col_i') " {c |}" 
		di as text "{hline `col_i'}{c +}{hline `=89-`col_i''}"
		local sr_text "  "
	}
	
	local pooled_vars `pooled' `endo_pooled'
	local pooled_vars : list pooled_vars - lr
	if "`pooled_vars'" != "" { 
		di "`sr_text'Pooled Variables:" _col(`col_i') " {c |}" 
		foreach var in `pooled_vars' {
			xtdcce_output_table `var' `col_i' `b_p_mg' `se_p_mg' `t_p_mg' cv `var'
		}
	}
	local rhs_vars `endogenous_vars' `rhs'
	local rhs_vars : list rhs_vars - lr
	if "`rhs_vars'" != ""   {
		di "`sr_text'Mean Group Estimates:" _col(`col_i') " {c |}"
		foreach var in `rhs_vars' {
			xtdcce_output_table `var' `col_i' `b_p_mg' `se_p_mg' `t_p_mg' cv `var'
			if "`full'" != "" {
				di "`sr_text'`sr_text'Individual Results" _col(`col_i') " {c |}"
				local ip = wordcount("`pooled'")
				forvalues j = 1(1)`N_g' {
					xtdcce_output_table `var'_`j' `col_i' `b_full' se_full t_full cv `var'`j'
				}
			}
		}		
	}	
	if "`lr'" != "" {
		local lr_pooled : list lr & pooled
		local lr_rest : list lr - lr_pooled
		di as text "{hline `col_i'}{c +}{hline `=89-`col_i''}"
		di "Long Run Estimates:" _col(`col_i') " {c |}"
		di as text "{hline `col_i'}{c +}{hline `=89-`col_i''}"
		if "`lr_pooled'" != "" { 
			di "  Pooled Variables:" _col(`col_i') " {c |}" 
			foreach var in `lr_pooled' {
				xtdcce_output_table `var' `col_i' `b_p_mg' `se_p_mg' `t_p_mg' cv `var'
			}
		}
		if "`lr_rest'" != ""   {
			di "  Mean Group Estimates:" _col(`col_i') " {c |}"
			foreach var in `lr_rest' {
				xtdcce_output_table `var' `col_i' `b_p_mg' `se_p_mg' `t_p_mg' cv `var'
				if "`full'" != "" {
					di "  Individual Results" _col(`col_i') " {c |}"
					local ip = wordcount("`pooled'")
					forvalues j = 1(1)`N_g' {
						xtdcce_output_table `var'_`j' `col_i' `b_full' se_full t_full cv `var'`j'
					}
				}
			}		
		}
	}	
	
	di as text "{hline `col_i'}{c BT}{hline `=89-`col_i''}"
	if "`pooled'" != "" {
		display "Pooled Variables: `endo_pooled' `pooled'"
	}
	if "`rhs'" != "" {
		display "Mean Group Variables: `rhs'"
	}
	if "`crosssectional'" != "" {
		if "`constant_type'" == "2" | "`constant_type'" == "1" {
			local crosssectional_output : list crosssectional - constant
			if "`crosssectional_output'" != "" {
				display "Cross Sectional Averaged Variables: `crosssectional_output'"
			}
		}
		else {
			display "Cross Sectional Averaged Variables: `crosssectional'"
		}
	}
	if "`lr'" != "" {
		display "Long Run Variables: `lr'"
	}
	if `IV' == 1 {
		display "Endogenous Variables: `endo_pooled' `endogenous_vars'"
		display "Exogenous Variables: `exogenous_vars'"
	}
	display "Degrees of freedom per country:" 
	display _col(2) "in mean group estimation" _continue
	display _col(38) "=" _col(41) e(T)-`num_pooled' - `num_rhs'
	display _col(2) "with cross-sectional averages" _continue
	display _col(38) "=" _col(41) e(T)-`num_pooled' - `num_rhs' - `cr_lags'*`num_crosssectional'
	display "Number of "
	display _col(2) "cross sectional lags" _continue
	display _col(38) "=" _col(41) "`cr_lags'"
	display _col(2) "variables in mean group regression" _continue
	display _col(38) "=" _col(41) "`=K'"
	display _col(2) "variables partialled out" _continue
	display _col(38) "=" _col(41)  "`num_partialled_out'"
	if "`lists'" != "" {
		display "Full Cross Sectional Averages list: `clist1'"
	}
	
	if "`omitted'" != "" {
		display "Omitted Variables:"
		display _col(2) "number of" _continue
		display _col(38) "=" _col(41) e(N_omitted)
		display _col(2) "variables: `omitted'"
	}
	if "`constant_type'" == "1" {
		display "Heterogenous constant partialled out." , _c
	}
	if "`constant_type'" == "2" {
		display "Homogenous constant removed from model." , _c
	}
	if "`constant_type'" == "4" {
		display "Homogenous constant removed." , _c
	}
	if "`jackknife'" == "jackknife" {
		display "Jackknife bias correction used." , _c
	}
	if "`recursive'" == "recursive" {
		display "Recursive mean adjustment used to correct for small sample time series bias." , _c
	}
	foreach matamat in X1 X1X1 X2 X1X2 X1Y X2_tilde Y V V_p V_p_mg b_p_mg b_p b_mg b b_v_names idt g lr lr_1 lr_tmp  lr_1_index  lr_1_indic ri rk se_p_mg t_p_mg N_g id_t `Y_tilde' `id_t'_tmp `id_t'_res `id_t'_c V_a V_b V_mg b_a b_b b_V cov_ab cov_ma cov_mb{
		capture mata mata drop `matamat'
	}
	di ""
end

capture program drop xtdcce_output_table
program define xtdcce_output_table
	syntax anything

	tokenize `anything'
	local var `1'
	local col =  `2'
	local b_p_mg `3'
	local se_p_mg `4'
	local t_p_mg `5' 
	local cv  `6'
	local i `7'

	di as text %`col's abbrev("`var'",`col')  "{c |}" as result _column(`=`col'+4') %8.7g `b_p_mg'[1,colnumb(`b_p_mg',"`i'")] _c
	local col = `col' + 16
	di as result _column(`col') %8.7g `se_p_mg'[rownumb(`se_p_mg',"`i'"),1] _continue
	local col = `col' + 11
	di as result _column(`col') %6.2f `t_p_mg'[rownumb(`t_p_mg',"`i'"),1] _continue
	scalar pval= 2*(1 - normal(abs(`t_p_mg'[rownumb(`t_p_mg',"`i'"),1])))
	local col = `col' + 9
	di as result _column(`col') %5.3f pval _continue
	local col = `col' + 10
	di as result _column(`col') %9.7g ( `b_p_mg'[1,colnumb(`b_p_mg',"`i'")] - `cv'*`se_p_mg'[rownumb(`se_p_mg',"`i'"),1]) _continue
	local col = `col' + 11
	di as result _column(`col') %9.7g ( `b_p_mg'[1,colnumb(`b_p_mg',"`i'")] + `cv'*`se_p_mg'[rownumb(`se_p_mg',"`i'"),1])
end


// Mata utility for sequential use of solvers
// Default is cholesky;
// if that fails, use QR;
// if overridden, use QR.
// By Mark Schaffer 2015
capture mata mata drop cholqrsolve()
mata:
	function cholqrsolve (  numeric matrix A,
							numeric matrix B,
						  | real scalar useqr)
	{
			if (args()==2) useqr = 0
			
			real matrix C

			if (!useqr) {
					C = cholsolve(A, B)
					if (C[1,1]==.) {
							C = qrsolve(A, B)
					}
			}
			else {
					C = qrsolve(A, B)
			}
			return(C)

	};
end


capture mata mata drop cholqrinv()
mata:
	function cholqrinv (  numeric matrix A,
						  | real scalar useqr)
	{
			if (args()==2) useqr = 0
			
			real matrix C

			if (!useqr) {
					C = cholinv(A)
					if (C[1,1]==.) {
							C = qrinv(A)
					}
			}
			else {
					C = qrinv(A)
			}
			return(C)

	};
end

***Point by point mata program
capture mata mata drop xtdcce_PointByPoint()
mata:
	function xtdcce_PointByPoint(real matrix nrows,
						   real matrix ncols,
						   real matrix expres,
						   real matrix XChange)
	{	
		p_ncols = ncols
		p_nrows = nrows
		p_expres = expres
		
		if (cols(p_ncols) == 1 & cols(p_nrows) > 1) p_ncols = J(1,cols(p_nrows),p_ncols)
		if (cols(p_ncols) > 1 & cols(p_nrows) == 1) p_nrows = J(1,cols(p_ncols),p_nrows)
		if (cols(expres) == 1 & cols(p_nrows) > 1 & cols(p_ncols) > 1) p_expres = J(1,cols(p_nrows),p_expres)
		
		for (i=1 ;i <=cols(p_ncols) ; i++) {
			XChange[p_nrows[i],p_ncols[i]] = p_expres[i]
		}
		return(XChange)
	}
end

**** Error program
capture program drop xtdcce_err
program define xtdcce_err
	syntax anything , msg(string)
	tokenize `anything'
	local code `1'
	local idvar `2'
	local tvar `3'
	
	tsset `2' `3'
	di as error _n  "`msg'" 
	
	exit `code'
end


*** Partial Out Program
** quadcross automatically removes missing values and therefore only uses (and updates) entries without missing values
capture mata mata drop xtdcce_m_partialout()
mata:
	function xtdcce_m_partialout (  string scalar X2_n,
									string scalar X1_n, 
									string scalar touse,
									| real matrix rk)
	{
		real matrix X1
		real matrix X2
		real matrix to
		st_view(X2,.,tokens(X2_n),touse)
		st_view(X1,.,tokens(X1_n),touse)
		X1X1 = quadcross(X1,X1)
		X1X2 = quadcross(X1,X2)
		//Get Rank
		s = qrinv(X1X1,rk=.)		
		rk = (rk=rows(X1X1))
		rk = (rk,rows(X1X1))
		X2[.,.] = (X2 - X1*cholqrsolve(X1X1,X1X2))
	}
end

**Mata OLS Program
**no_partial = 0 if no partialled out, otherwise number of partialled out variables
**allows for clustered ses, then F is donbe by hand
** checks automatically for constant
capture mata mata drop xtdcce_m_reg()
mata:
	function xtdcce_m_reg (  string scalar variablenames, 
									string scalar touse, 
									real scalar no_partial,
									| real matrix b_output,
									real matrix e_output,
									real matrix cov_output ,
									real matrix stats_output,
									string scalar cluster_var,
									real matrix ccep )
	{
		lhs = tokens(variablenames)[1]
		rhs = tokens(variablenames)[2..cols(tokens(variablenames))]
		
		Y = st_data(.,lhs,touse)
		X = st_data(.,rhs,touse)
		// check if constant
		has_c = 0
		if (sum((colsum(X):==rows(X)))) {
			has_c = 1
		}
		if (args() < 9) {
			XX = quadcross(X,X)
			XY = quadcross(X,Y)
			b_output = cholqrsolve(XX,XY)
			ccep_i = 0
		}
		else {
			real matrix rsum1 
			real matrix rsum2
			real matrix indicator

			indicator = J(0,1,.)
			rsum1 = J(cols(X),cols(X),0)
			rsum2 = J(cols(X),1,0)
						
			//create indicator
			i = 1
			while (i <= rows(ccep)) {
				indicator = (indicator \ J(ccep[i,2],1,i))
				i++
			}
			i = 1
			while (i <= rows(ccep)) {
				X_i = select(X,(indicator:==i))
				Y_i = select(Y,(indicator:==i))
				rsum1 = rsum1 + quadcross(X_i,X_i) :* ccep[i,1]
				rsum2 = rsum2 + quadcross(X_i,Y_i) :* ccep[i,1]
				i++
			}
			b_output = cholqrsolve(rsum1,rsum2)
			ccep_i = 1
		}
		
		Y_hat = X*b_output
		e_output = Y - Y_hat
		
		N = rows(Y)
		K_reg = cols(X)
		K = K_reg + no_partial
		dfr = N - K

		sse = e_output'*e_output 
		s2 = sse  / dfr	
		
		if (has_c == 1) {
			ssr = sum((Y_hat:-mean(Y)):^2)
			r2 = 1 - ssr/(ssr+sse)
			r2_a = 1 - (1-r2) * (N - 1) / (N - K - 1)
		}
		else if (has_c == 0) {
			ssr = sum((Y_hat):^2)
			r2 = ssr/(ssr+sse)
			r2_a = r2
		}
		sst = ssr + sse
		
		if (args() < 8 ) {
			cov_output = cholqrinv(XX) * s2
			F = ssr/(K-has_c) / (sse/(N-K))
		}
		else {
			if (cluster_var[1,1] != "") {
				cluster = st_data(.,cluster_var,touse)
				indicator = uniqrows(cluster)
				u_j = J(cols(X),cols(X),0)
				i = 1
				while (i <= rows(indicator)) {
					e_j = select(e_output,(cluster:==indicator[i]))
					x_j = select(X,(cluster:==indicator[i]))
					u_j = u_j+colsum(e_j :* x_j)'*colsum(e_j :* x_j)
					i++					
				}
				XX1 = cholqrinv(XX)
				cov_output = XX1 * u_j * XX1
				// small sample adjustment (to match Stata Results)
				cov_output = cov_output * (N-1)/(N-K) * rows(indicator)/(rows(indicator)-1)
				// Wald Test instead of F test
				const_indic = selectindex(((colsum(X) :== X[1,.] * rows(X))))
				R = I(cols(X))
				R = xtdcce_PointByPoint(const_indic,const_indic, 0,R)
				q = 0																
				m = R * b_output :- q
				Va = cholqrinv(R*cov_output*R')
				F = m' * Va * m / (sum(R))								
			}
			else {
				cov_output = cholqrinv(XX) * s2
				F = ssr/(K-has_c) / (sse/(N-K))
			}			
		}
		rmse = sqrt(s2)		
		stats_output = (N \ K  \ K_reg \ dfr \ sse \ ssr \ sst \ s2 \ r2 \ r2_a \ F \ rmse \ ccep_i )
	}	
end

