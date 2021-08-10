*! version 2.0.3 18dec2013 MJC

/*
History
MJC 18dec2013 version 2.0.3 - tde() with logcumh() or cumh() caused an error. Now fixed.
MJC 10oct2013 version 2.0.2 - bug fix -> exact option added to confirm vars
MJC 08jul2013 version 2.0.1 - minor bug fix in mixture models
MJC 04jan2013 version 2.0.0 - maxtime() added to specify maximum generated survival time and event indicator
							- n() removed so must set obs
							- loghazard() and hazard() added for user-defined hazard functions, simulated using quadrature and root finding
							- default centol() changed to 1E-08
							- varnames can now appear in loghazard()/hazard() allowing time-dependent covariates
							- mixture models now use Brent method -> much more reliable than NR, and allows tdes
							- cumhazard() and logcumhazard() now added which just use root finding
MJC 15Nov2011 version 1.1.2 - Fixed bug when generating covariate tempvars with competing risks.
MJC 20sep2011 version 1.1.1 - Exponential distribution added.
MJC 10sep2011 version 1.1.0 - Added Gompertz distribution. Time-dependent effects available for all models except mixture. showerror option added.
MJC 09sep2011 version 1.0.1 - Time dependent effects now allowed for standard Weibull.
*/

program define survsim
	version 11.2
	syntax newvarname(min=1 max=2), 										///
																			///
									[										/// -Options-
																			///
										Lambdas(numlist min=1)				///	-Scale parameters-
										Gammas(numlist min=1)				///	-Shape parameters-
										Distribution(string)				/// -Parametric distribution-
										MAXTime(string)						///	-Maximum simulated time-
										CENTOL(real 1E-08)					///	-Tolerance of root finder-
																			///
										COVariates(string)					///	-Baseline covariates, e.g, (sex 0.5 race -0.4)-
										TDE(string)							///	-Time dependent effects to interact with log(time)-
																			///
									/* Mixture */							///
										MIXture								///	-Simulate 2-component mixture-
										PMix(real 0.5)						///	-Mixture parameter-
																			///
									/* Competing risks */					///
										CR									///	-Simulate competing risks-
										NCR(string)							///	-Number of competing risks-
										SHOWdiff							///	-Dislay error of N-R iterations-
																			///
									/* User-defined */						///
										LOGHazard(string)					///	-User defined log baseline hazard function-
										Hazard(string)						///	-User defined baseline hazard function-
										LOGCUMHazard(string)				/// -User defined log baseline cumulative hazard function-
										CUMHazard(string)					/// -User defined baseline cumulative hazard function-
										NODES(int 30)						///	-Quadrature nodes-
										TDEFUNCtion(string)					///	-function of time to interact with time-dependent effects-
										ITerations(int 1000)				///	-max iterations in root finding-	
										MINTime(string)						///	-minimum time for use in user-defined generation-
										ENTER(varname)						///
									]

	if _N==0 {
		di as error "You must set obs"
		exit 198
	}
	
	if ("`loghazard'"!="" | "`hazard'"!="") & ("`distribution'"!="" | "`cr'"!="" | "`ncr'"!="" | "`mixture'"!="") {
		di as error "Syntax error"
		exit 198
	}
	
	if ("`loghazard'"=="" & "`hazard'"=="" & "`mixture'"=="" & "`logcumhazard'"=="" & "`cumhazard'"=="" & "`tdefunction'"!="") {
		di as error "tdefunction() cannot be used"
		exit 198
	}
	
	//call user-defined subroutine and exit
	if ("`loghazard'"!="" | "`hazard'"!="" | "`mixture'"!="" | "`logcumhazard'"!="" | "`cumhazard'"!="") {
		gensurvsim `0'
		exit
	}
	
	local newvarname `varlist'
	local nvars : word count `varlist'

	//===============================================================================================================================================================//
	// Distribution
	
	if "`distribution'"=="" {
		local dist "weibull"
	}
	else {
		local l = length("`distribution'")
		if substr("exponential",1,max(1,`l')) == "`distribution'" local dist "exp"
		else if substr("gompertz",1,max(3,`l')) == "`distribution'" local dist "gompertz"
		else if substr("weibull",1,max(1,`l')) == "`distribution'" local dist "weibull"
		else {
			di as error "Unknown distribution"
			exit 198
		}
	}
	
	//===============================================================================================================================================================//
	// Error checks
		
		foreach l of numlist `lambdas' {
			if `l'<0 {
				di as error "lambdas must be > 0"
				exit 198
			}
		}
		
		if "`dist'"=="exp" & "`gammas'"!="" {
			di as error "gammas cannot be specified with distribution(exponential)"
			exit 198
		}
		
		if "`dist'"=="weibull" {
			foreach g of numlist `gammas' {
				if `g'<0 {
					di as error "gammas must be > 0"
					exit 198
				}
			}
		}
				
		if "`mixture'"!="" & "`cr'"!="" {
			di as error "Can only specify one of mixture/cr"
			exit 198
		} 
		
		if `nvars'>1 & "`cr'"=="" & "`maxtime'"=="" {
			di as error "Two variables can only be specified when cr or maxtime() is used"
			exit 198
		}
		
		local nlambdas : word count `lambdas'
		local ngammas  : word count `gammas'
				
		if "`cr'"=="" & "`mixture'"=="" {
			if "`nlambdas'"!="1"{
				di as error "Number of lambda's must be 1 under a standard parametric model"
				exit 198
			}
			if "`ngammas'"!="1" & "`gammas'"!="" {
				di as error "Number of gamma's must be 1 under a standard parametric model"
				exit 198
			}				
		}
		
		if "`cr'"!="" & "`nvars'"!="2" {
			di as error "2 variables must be specified for cr"
			exit 198
		}
		
		if "`cr'"!="" {
		
			if "`ncr'"=="" {
				di as error "ncr must be specified"
				exit 198
			}
			
			cap confirm integer number `ncr'
			if _rc>0 {
				di as error "ncr must be an integer"
				exit 198
			}
			
			if `ncr'<2 {
				di as error "ncr must be >1"
				exit 198
			}
			
			if "`nlambdas'"!="`ncr'"{
				di as error "Number of lambdas must equal ncr"
				exit 198
			}
			if "`ngammas'"!="`ncr'" & "`dist'"!="exp" {
				di as error "Number of gammas must equal ncr"
				exit 198
			}
			
		}
		
		if "`cr'"=="" & "`showdiff'"!="" {
			di as error "showdiff only available when cr is specified"
			exit 198
		}
				
		if `nvars'<2 & "`maxtime'"!="" {
			di as error "2 new varnames must be specified when using maxtime()"
			exit 198
		}
		
		if "`maxtime'"!="" {
			cap confirm number `maxtime'
			if _rc | `maxtime'<0 {
				di as error "maxtime() must be a number > 0"
				exit 198
			}
		}
		
	//===============================================================================================================================================================//
	// Defaults
	
		if wordcount(`"`mixture' `cr'"')>0 local model = trim("`mixture' `cr'")
		else local model "`dist'"
		
		local show "quietly"
		if "`showdiff'"!="" local show "noisily"
		
	//===============================================================================================================================================================//
	// Baseline covariates and time-dependent effects
	
		if "`covariates'"!="" {
			
			/* Standard parametric or mixture*/
			if "`model'"!="cr" {
				tokenize `covariates'
				local ncovlist : word count `covariates'
				local ncovvars = `ncovlist'/2
				cap confirm integer number `ncovvars'
				if _rc>0 {
					di as error "Variable/number missing in covariates"
					exit 198
				}
				local ind = 1
				forvalues i=1/`ncovvars' {
					cap confirm var ``ind'', exact
					if _rc {
						local errortxt "invalid covariates(... ``ind'' ``=`ind'+1'' ...)"
						local error = 1
					}
					cap confirm num ``=`ind'+1''
					if _rc {
						local errortxt "invalid covariates(... ``ind'' ``=`ind'+1'' ...)"
						local error = 1
					}
					tempvar vareffect`i'
					gen double `vareffect`i'' = ``ind''*``=`ind'+1'' 
		
					local ind = `ind' + 2
				}
				if "`error'"=="1" {
					di as error "`errortxt'"
					exit 198
				}
				local cov_linpred "`vareffect1'"
				if `ncovvars'>1 {
					forvalues k=2/`ncovvars' {
						local cov_linpred "`cov_linpred' + `vareffect`k''"
					}
				}
				local cov_linpred "* exp(`cov_linpred')"
			}
			
			/* Competing risks */
			else {
				tokenize `covariates'
				local ncovlist : word count `covariates'	
				local ncovvars = `ncovlist'/`=`ncr'+1'
				cap confirm integer number `ncovvars'
				if _rc>0 {
					di as error "Variable/number missing in covariates"
					exit 198
				}

				local ind = 1
				forvalues i=1/`ncovvars' {
					cap confirm var ``ind'', exact
					if _rc {
						local errortxt "invalid covariates(... ``ind'' ``=`ind'+1'' ...)"
						local error = 1
					}
					forvalues j=1/`ncr' {
						cap confirm num ``=`ind'+`j'''
						if _rc {
							local errortxt "invalid covariates(... ``ind'' ``=`ind'+`j''' ...)"
							local error = 1
						}
						/* Create effect for ith variable and jth risk */
						tempvar vareffect_`i'_`j'
						gen double `vareffect_`i'_`j'' = ``ind''*``=`ind'+`j''' 
					}
					local ind = `ind' + `ncr' + 1
				}
				if "`error'"=="1" {
					di as error "`errortxt'"
					exit 198
				}
				forvalues k=1/`ncr' {
					local cov_linpred_`k' "`vareffect_1_`k''"
				}
				if `ncovvars'>1 {
					forvalues p=2/`ncovvars' {
						forvalues m=1/`ncr' {
							local cov_linpred_`m' "`cov_linpred_`m'' + `vareffect_`p'_`m''"
						}
					}
				}
				forvalues k=1/`ncr' {
					local cov_linpred_`k' "* exp(`cov_linpred_`k'')"
				}			
					
			}
		}
		
		if "`tde'"!="" {
			/* Standard parametric or mixture*/
			if "`model'"!="cr" {
				tokenize `tde'
				local ntde : word count `tde'	
				local ntdevars = `ntde'/2
				cap confirm integer number `ntdevars'
				if _rc>0 {
					di as error "Variable/number missing in tde"
					exit 198
				}

				local ind = 1
				forvalues i=1/`ntdevars' {
					cap confirm var ``ind'', exact
					if _rc {
						local errortxt "invalid tde(... ``ind'' ``=`ind'+1'' ...)"
						local error = 1
					}
					cap confirm num ``=`ind'+1''
					if _rc {
						local errortxt "invalid tde(... ``ind'' ``=`ind'+1'' ...)"
						local error = 1
					}
					tempvar tdeeffect`i'
					gen double `tdeeffect`i'' = ``ind''*``=`ind'+1'' 

					local ind = `ind' + 2
				}
				if "`error'"=="1" {
					di as error "`errortxt'"
					exit 198
				}
				local tde_linpred "`tdeeffect1'"
				if `ntdevars'>1 {
					forvalues k=2/`ntdevars' {
						local tde_linpred "`tde_linpred' + `tdeeffect`k''"
					}
				}
				local tde_linpred "+ `tde_linpred'"
			}
			
			/* Competing risks */
			else {
				tokenize `tde'
				local ntdelist : word count `tde'	
				local ntdevars = `ntdelist'/`=`ncr'+1'
				cap confirm integer number `ntdevars'
				if _rc>0 {
					di as error "Variable/number missing in tde"
					exit 198
				}
				local ind = 1
				forvalues i=1/`ntdevars' {
					cap confirm var ``ind'', exact
					if _rc {
						local errortxt "invalid tde(... ``ind'' ``=`ind'+1'' ...)"
						local error = 1
					}
					forvalues j=1/`ncr' {
						cap confirm num ``=`ind'+`j'''
						if _rc {
							local errortxt "invalid tde(... ``ind'' ``=`ind'+`j''' ...)"
							local error = 1
						}
						/* Create effect for ith variable and jth risk */
						tempvar tdeeffect_`i'_`j'
						gen double `tdeeffect_`i'_`j'' = ``ind''*``=`ind'+`j''' 
					}
					local ind = `ind' + `ncr' + 1
				}
				if "`error'"=="1" {
					di as error "`errortxt'"
					exit 198
				}
				forvalues k=1/`ncr' {
					local tde_linpred_`k' "`tdeeffect_1_`k''"
				}
				if `ntdevars'>1 {
					forvalues p=2/`ntdevars' {
						forvalues m=1/`ncr' {
							local tde_linpred_`m' "`tde_linpred_`m'' + `tdeeffect_`p'_`m''"
						}
					}
				}
				forvalues k=1/`ncr' {
					local tde_linpred_`k' "+ `tde_linpred_`k''"
				}			
			}
		}
		
	//===============================================================================================================================================================//
	// Preliminaries

		tempvar u
		qui gen double `u' = runiform() 

	//===============================================================================================================================================================//
	// Equations for N-R
	
		tempvar nr_time nr_time_old
	
		/* Standard exponential */
			if "`model'"=="exp" {
				local lambdastart : word 1 of `lambdas'
			}

		/* Standard Weibull/Gompertz */
			else if "`model'"=="weibull" | "`model'"=="gompertz" {
				local lambdastart : word 1 of `lambdas'
				local gammastart  : word 1 of `gammas'	
			}
			
		/* Competing risks */
			else if "`model'"=="cr"{
				local lambdastart = 0
				forvalues i=1/`ncr' {
					local l`i' : word `i' of `lambdas'
					local lambdastart = `lambdastart' + `l`i''
				}
				if "`dist'"!="exp" {
					local gammastart = 1
					forvalues i=1/`ncr' {
						local g`i' : word `i' of `gammas'				
						local gammastart = `gammastart' * `g`i''
					}				
				}
				
				/* Equations */
				if "`dist'"=="exp" {
					local eqn_xb "exp((-`l1'*`nr_time_old'^(1 `tde_linpred_1')) `cov_linpred_1' /(1 `tde_linpred_1'))"
					local eqn_dxb "(-`l1'*`nr_time_old'^((1 `tde_linpred_1')-1)`cov_linpred_1')"
					forvalues j=2/`ncr' {
						local eqn_xb "`eqn_xb' * exp((-`l`j''*`nr_time_old'^(1 `tde_linpred_`j'')) `cov_linpred_`j'' /(1 `tde_linpred_`j''))"			
						local eqn_dxb "`eqn_dxb' - (`l`j''*`nr_time_old'^((1 `tde_linpred_`j'')-1)`cov_linpred_`j'')"
					}
				}
				else if "`dist'"=="weibull" {
					local eqn_xb "exp((-`l1'*`g1'*`nr_time_old'^(`g1' `tde_linpred_1')) `cov_linpred_1' /(`g1' `tde_linpred_1'))"
					local eqn_dxb "(-`l1'*`g1'*`nr_time_old'^((`g1' `tde_linpred_1')-1)`cov_linpred_1')"
					forvalues j=2/`ncr' {
						local eqn_xb "`eqn_xb' * exp((-`l`j''*`g`j''*`nr_time_old'^(`g`j'' `tde_linpred_`j'')) `cov_linpred_`j'' /(`g`j'' `tde_linpred_`j''))"			
						local eqn_dxb "`eqn_dxb' - (`l`j''*`g`j''*`nr_time_old'^((`g`j'' `tde_linpred_`j'')-1)`cov_linpred_`j'')"
					}
				}
				else {
					local eqn_xb "exp((`l1'/(`g1' `tde_linpred_1'))`cov_linpred_1'*(1-exp((`g1' `tde_linpred_1')*`nr_time_old')))"
					local eqn_dxb "(`l1' `cov_linpred_1' *(-1)*exp((`g1' `tde_linpred_1')*`nr_time_old'))"
					forvalues j=2/`ncr' {
						local eqn_xb "`eqn_xb' * exp((`l`j''/(`g`j'' `tde_linpred_`j''))`cov_linpred_`j''*(1-exp((`g`j'' `tde_linpred_`j'')*`nr_time_old')))"			
						local eqn_dxb "`eqn_dxb' + (`l`j'' `cov_linpred_`j'' *(-1)*exp((`g`j'' `tde_linpred_`j'')*`nr_time_old'))"
					}
				}
				local eqn_dxb "(`eqn_xb') * (`eqn_dxb')"
			}
		
		if "`gammas'"!="" {
			if `gammastart'==0 {
				local gammastart = 0.0001
			}
		}
		if `lambdastart'==0 {
			local lambdastart = 0.0001
		}

	//===============================================================================================================================================================//
	// Standard Weibull/Gompertz calculations OR Starting values
	
		if "`model'"!="cr" {
			if "`dist'"=="exp" {
				qui gen double `nr_time' 		= (-ln(`u')*(1 `tde_linpred')/(`lambdastart' `cov_linpred'))^(1/(1 `tde_linpred'))
				qui gen double `nr_time_old' 	= `nr_time'
			}
			else if "`dist'"=="weibull" {
				qui gen double `nr_time' 		= (-ln(`u')*(`gammastart' `tde_linpred')/(`lambdastart'*`gammastart' `cov_linpred'))^(1/(`gammastart' `tde_linpred')) 
				qui gen double `nr_time_old' 	= `nr_time'
			}
			else{
				qui gen double `nr_time' 		= (1/(`gammastart' `tde_linpred'))*log(1-(((`gammastart' `tde_linpred')*log(`u'))/(`lambdastart' `cov_linpred'))) 
				qui gen double `nr_time_old'	= `nr_time'
			}
		}
		else if "`model'"=="cr"{
			if "`dist'"=="exp" {
				qui gen double `nr_time' 		= -ln(`u')/(`lambdastart') 
				qui gen double `nr_time_old' 	= `nr_time'	
			}
			else if "`dist'"=="weibull" {
				qui gen double `nr_time' 		= (-ln(`u')/(`lambdastart'))^(1/`gammastart') 
				qui gen double `nr_time_old' 	= `nr_time'
			}
			else {
				qui gen double `nr_time' 		= (1/(`gammastart'))*log(1-(`gammastart'*log(`u')/(`lambdastart'))) 
				qui gen double `nr_time_old' 	= `nr_time'
			}
		}

	//===============================================================================================================================================================//
	// Newton-Raphson 

		if "`model'"=="cr" {
			
			/* Based on Therese Andersson's centile prediction option of stpm2_pred */
			local done 0
			while !`done' {
				qui gen double _nr_xb  = `eqn_xb' - `u'
				qui gen double _nr_dxb = `eqn_dxb'
				qui replace `nr_time'  = max(`nr_time_old' - _nr_xb/_nr_dxb,0.0000000000000001)
				qui gen double _error  = abs(`nr_time' - `nr_time_old')
				qui su _error 
				`show' di in green `r(max)'
				if `r(max)'<`centol' {
					local done 1
				}
				else {
					drop _nr_xb _nr_dxb _error
					qui replace `nr_time_old' = `nr_time' 
				}
			}
			cap drop _nr_xb _nr_dxb _error		
			
		}
		
	//===============================================================================================================================================================//
	// Final variables 
	
		if "`model'"!="cr" {
			if "`maxtime'"=="" {
				qui gen double `newvarname' = `nr_time'
				qui count if `newvarname'==. 
				if `r(N)'>0 di in yellow "warning: `r(N)' missing values generated in `var1'"
			}
			else {
				local var1 : word 1 of `varlist'
				local var2 : word 2 of `varlist'
				qui gen double `var1' = min(`nr_time',`maxtime') if `nr_time'!=.
				qui gen byte `var2' = `nr_time'<`maxtime' if `nr_time'!=.
				qui count if `var1'==.
				if `r(N)'>0 di in yellow "warning: `r(N)' missing values generated in `var1'"
			}
		}
		else {
			local var1 : word 1 of `varlist'
			local var2 : word 2 of `varlist'
			qui gen double `var1' = `nr_time'
			
			/* Generate cause specific hazards at survival times */
			if "`dist'"=="exp" {
				local totalhaz "`l1'*(`nr_time')^(1 `tde_linpred_1'-1) `cov_linpred_1'"
				forvalues i=1/`ncr' {
					tempvar haz_`i'
					qui gen double `haz_`i'' = `l`i''*(`nr_time')^(1  `tde_linpred_`i''-1) `cov_linpred_`i''		
					if "`i'"!="1" {
						local totalhaz "`totalhaz' + `haz_`i''"
					}
				}			
			}
			else if "`dist'"=="weibull" {
				local totalhaz "`l1'*`g1'*(`nr_time')^(`g1' `tde_linpred_1'-1) `cov_linpred_1'"
				forvalues i=1/`ncr' {
					tempvar haz_`i'
					qui gen double `haz_`i'' = `l`i''*`g`i''*(`nr_time')^(`g`i''  `tde_linpred_`i''-1) `cov_linpred_`i''		
					if "`i'"!="1" {
						local totalhaz "`totalhaz' + `haz_`i''"
					}
				}
			}
			else {
				local totalhaz "`l1'*exp((`g1' `tde_linpred_1')*`nr_time') `cov_linpred_1'"
				forvalues i=1/`ncr' {
					tempvar haz_`i'
					qui gen double `haz_`i'' = `l`i''*exp((`g`i'' `tde_linpred_`i'')*`nr_time') `cov_linpred_`i''		
					if "`i'"!="1" {
						local totalhaz "`totalhaz' + `haz_`i''"
					}
				}
			}
			tempvar haz_all
			qui gen double `haz_all' = `totalhaz'
			forvalues i=1/`ncr' {
				tempvar p`i'
				qui gen double `p`i'' = `haz_`i''/`haz_all'
				local pvars "`pvars' `p`i''"
			}
			/* Event code */
			mata: pmatrix = st_data(.,tokens(st_local("pvars")))
			
			tempvar status
			qui gen `status'=.
			mata: genstatus("`status'",pmatrix)		
			qui gen `var2' = `status'
			
			if "`maxtime'"!="" {
				qui replace `var2' = 0 if `var1'>=`maxtime' & `var1'!=.	
				qui replace `var1' = `maxtime' if `var1' >= `maxtime' & `var1'!=.
			}		
			
			qui count if `var1'==. 
			if `r(N)'>0 di in yellow "Warning: `r(N)' missing values generated in `var1'"
		}
	
end

/* Mata program to generate status indicator under a competing risks model */
mata:
mata set matastrict off
  void genstatus(string scalar name,		///
				 numeric matrix pmatrix)
  {
    st_view(final=.,.,name)
    N = st_nobs()
	
	for (i=1; i<=N; i++) {
		p = pmatrix[i,.]
		final[i,.] = rdiscrete(1,1,p)
	}
  }
end
