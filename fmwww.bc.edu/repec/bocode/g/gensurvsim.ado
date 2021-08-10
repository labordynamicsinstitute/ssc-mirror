*! version 1.1.3 18dec2013 MJC


/*
History
MJC 18dec2013: version 1.1.3 - bug fix -> tdefunction() incorrectly parsed when logcumh() or cumh() specified
MJC 10oct2013: version 1.1.2 - bug fix -> exact option added to confirm vars
MJC 08jul2013: version 1.1.1 - minor bug fix in mixture models
MJC 17oct2012: version 1.1.0 - mixture model now done in here
							 - tvc's can now be included in logh()/h()
							 - cumhazard() and logcumhazard() added
MJC 27aug2012: version 1.0.0
*/

program define gensurvsim
	version 11.2
	
	syntax newvarname(min=1 max=2), 										///
																			///
									[										/// -Options-
																			///
										MAXTime(string)						///	-Maximum simulated time-
										MINTime(string)						///	-minimum time for use in user-defined generation-
										LOGHazard(string)					///	-User defined log baseline hazard function-
										Hazard(string)						///	-User defined baseline hazard function-
										LOGCUMHazard(string)				/// -User defined log baseline cumulative hazard function-
										CUMHazard(string)					/// -User defined baseline cumulative hazard function-
										NODES(int 15)						///	-Quadrature nodes-
																			///
										MIXTURE								///
										Distribution(string)				///
										Lambdas(numlist)					///
										Gammas(numlist)						///
										PMIX(real 0.5)						///
																			///
										COVariates(string)					///	-Baseline covariates, e.g, (sex 0.5 race -0.4)-
										TDE(string)							///	-Time dependent effects to interact with tdefunc()-
										TDEFUNCtion(string)					///	-function of time to interact with time-dependent effects-
																			///
										ITerations(int 1000)				///
										CENTOL(real 1E-08)					///
										ENTER(varname)						///
										*									///
									]
		
		local nvars : word count `varlist'
		local nvar1 : word 1 of `varlist'
		if `nvars'==2 local nvar2 : word 2 of `varlist'
		
		cap which lmoremata.mlib
		if _rc {
			display in yellow "You need to install the moremata package. This can be installed using,"
			display in yellow ". {stata ssc install moremata}"
			exit 198
		}
		
		if "`maxtime'"=="" {
			di as error "maxtime() must be specified"
			exit 198
		}
		
		cap confirm number `maxtime'
		if _rc {
			di as error "maxtime() must be a number >0"
			exit 198
		}
		if `maxtime'<=0 {
			di as error "maxtime() must be a number >0"
			exit 198
		}
		
		if "`mintime'"=="" {
			local mintime = 1E-08
			local nodelentry = 1
		}
		else {
			local nodelentry = 0
			cap confirm number `mintime'
			if _rc {
				di as error "mintime() must be a number >0"
				exit 198
			}
			if `mintime'<=0 {
				di as error "mintime() must be a number >0"
				exit 198
			}				
		}
		
		if "`hazard'"!="" & "`loghazard'"!="" {
			di as error "Can only specify one of hazard()/loghazard()"
			exit 198
		}
		
		if "`cumhazard'"!="" & "`logcumhazard'"!="" {
			di as error "Can only specify one of cumhazard()/logcumhazard()"
			exit 198
		}		
		
		if "`enter'"!="" {
			qui su `enter', meanonly
			if `r(min)'<0 {
				di as error "min(`enter') must be > 0"
				exit 198
			}
			local enter enter(`enter')
		}
		
		
		if "`mixture'"!="" {
			local nlambdas : word count `lambdas'
			local ngammas  : word count `gammas'
			
			if "`nlambdas'"!="2" {
				di as error "Number of lambdas must be 2 under a mixture model"
				exit 198
			}
			if "`ngammas'"!="2" & "`gammas'"!="" {
				di as error "Number of gamma must be 2 under a mixture model"
				exit 198
			}		
		
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
		}
		
		qui ds							//keep here
		local allvars `r(varlist)'

	//===============================================================================================================================================================//
	// Baseline covariates
		
		tempvar xbcovs
		if "`covariates'"!="" {
			
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
				qui gen double `vareffect`i'' = ``ind''*``=`ind'+1''
	
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
			
			qui gen double `xbcovs' = exp(`cov_linpred')
			
		}
		else qui gen byte `xbcovs' = 1
	
	//===============================================================================================================================================================//
	// Time-dependent effects
	
		if "`tde'"!="" {
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
				qui gen double `tdeeffect`i'' = ``ind''*``=`ind'+1''

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
			tempvar tdexb
			qui gen double `tdexb' = `tde_linpred'
		}
		
	//===============================================================================================================================================================//
	// Core stuff

		qui gen double `nvar1' = .
		tempvar tempu
		qui gen double `tempu' = runiform()
		cap drop _survsim_rc
		qui gen _survsim_rc = .
		
		if "`loghazard'"!="" | "`hazard'"!="" | ("`mixture'"!="" & "`tde'"!="") {
		
			//nodes and weights
			gaussquad_ss, n(`nodes') leg
								
			// handle loghazard() or hazard()
			if "`mixture'"!="" & "`tde'"!="" {
				local nlambdas : word count `lambdas'
				forvalues i=1/`nlambdas' {
					local l`i' : word `i' of `lambdas'
				}
				if "`dist'"=="weibull" | "`dist'"=="gompertz" {
					forvalues i=1/2 {
						local g`i' : word `i' of `gammas'
					}
				}
				
				if "`dist'"=="exp" {
					local base_surv "( `pmix':*exp(-`l1':*#t) :+ (1:-`pmix'):*exp(-`l2':*#t) )"
					local numer "(`l1':*`pmix':*exp(-`l1':*#t) :+ `l2':*(1:-`pmix'):*exp(-`l2':*#t))"
					local hazard "`numer' :/ `base_surv'"
				}
				else if "`dist'"=="weibull" {
					local base_surv "( `pmix':*exp(-`l1':*#t:^(`g1')) :+ (1:-`pmix'):*exp(-`l2':*#t:^(`g2')) )"
					local numer "(`l1':*`g1':*`pmix':*#t:^(`g1':-1):*exp(-`l1':*#t:^(`g1')) :+ `l2':*`g2':*(1:-`pmix'):*#t:^(`g2':-1):*exp(-`l2':*#t:^(`g1')))"
					local hazard "`numer' :/ `base_surv'"
				}
				else {
					local base_surv "( `pmix':*exp((`l1':/`g1'):*(1:-exp(`g1':*#t))) :+  (1:-`pmix'):*exp((`l2':/`g2'):*(1:-exp(`g2':*#t))) )"
					local numer "`pmix':*exp((`l1':/`g1'):*(1:-exp(`g1':*#t))) :* (-`l1':*exp(`g1':*#t)) + (1:-`pmix'):*exp((`l2':/`g2'):*(1:-exp(`g2':*#t))) :* (-`l2':*exp(`g2':*#t))"
					local hazard "(`numer') :/ `base_surv'"
				}
			
			}
			
			mata: st_local("tempcumhaz",subinstr("`loghazard'`hazard'","#t","tnodes"))
			if "`loghazard'"!="" local tempcumhaz exp(`tempcumhaz')
			local tempcumhaz (`tempcumhaz'):*xb
			
			//tde's
			if "`tde'"!="" {
				local temptde temptde(`tdexb')
				if "`tdefunction'"=="" local tdefunction tnodes
				else mata: st_local("tdefunction",subinstr(st_local("tdefunction"),"#t","tnodes"))
				local tempcumhaz (`tempcumhaz') :* exp(tdexb :* (`tdefunction'))
			}
			
			//chuck variables found in loghazard()/hazard() into Mata
			if "`mixture'"=="" {
				local nhazvars = 0
				macro drop overallsyntax1 overallsyntax2 mmrootsyntax1 mmrootsyntax2				
				gettoken first rest : tempcumhaz, parse("[ ,\^\*\(\)-\+/:<>=]")
				while "`rest'"!="" {
					if trim("`first'")!="," {
						cap confirm var `first', exact
						if !_rc {
							local test1 = 0
							foreach var in `covlist' {
								if "`first'"=="`var'" local test1 = 1
							}
							if `test1'==0 {
								local covlist `covlist' `first'		//contains a list of all varnames specified, be they time-indep or time-dependent
								local nhazvars = `nhazvars' + 1
								mata: st_local("tempcumhaz",subinstr(st_local("tempcumhaz"),"`first'","hazvars[1,`nhazvars']"))
							}
						}
					}
					gettoken first rest : rest, parse("[ ,\^\*\(\)-\+/:<>=]")
				}			
				if `nhazvars' {
					mata: st_view(hazvars=.,.,tokens("`covlist'"))
					global overallsyntax1 numeric matrix hazvars
					global overallsyntax2 hazvars
					global mmrootsyntax1 , hazvars[i,]
					global mmrootsyntax2 , hazvars
				}
			}

			//hazard function
			global cumhaz `tempcumhaz'	
			global cumhaz0 0 		//lets it compile
			if `nhazvars'==0 {
				//test
				mata: tnodes = xb = tdexb = 0.1
				cap mata: test1 = $cumhaz
				if _rc {
					di as error "Error in loghazard()/hazard()"
					exit 198
				}
				mata mata drop tnodes xb tdexb test1
			}		
			
			cap pr drop gensurvsim_core
			gensurvsim_core, maxtime(`maxtime') tempnewvarname(`nvar1') tempu(`tempu') rc(_survsim_rc) tempcovs(`xbcovs') `temptde'	///
								iterations(`iterations') centol(`centol') mintime(`mintime') `enter' `mixture'
			cap macro drop cumhaz cumhaz0
			if `nhazvars' {
				cap macro drop overallsyntax1 overallsyntax2 mmrootsyntax1 mmrootsyntax2
			}
		}
		
		if ("`mixture'"!="" & "`tde'"==""){
		
			local nlambdas : word count `lambdas'
			forvalues i=1/`nlambdas' {
				local l`i' : word `i' of `lambdas'
			}
			if "`dist'"=="weibull" | "`dist'"=="gompertz" {
				forvalues i=1/2 {
					local g`i' : word `i' of `gammas'
				}
			}
			
			//-log(survival) to synch with ch version
			if "`dist'"=="exp" {
				local tempcumhaz -log(`pmix':*exp(-`l1':*t) :+ (1:-`pmix'):*exp(-`l2':*t))
			}
			else if "`dist'"=="weibull" {
				local tempcumhaz -log(`pmix':*exp(-`l1':*t:^(`g1')) :+ (1:-`pmix'):*exp(-`l2':*t:^(`g2')))
			}
			else {
				local tempcumhaz -log(`pmix':*exp((`l1':/`g1'):*(1:-exp(`g1':*t))) :+  (1:-`pmix'):*exp((`l2':/`g2'):*(1:-exp(`g2':*t))))
			}
			global cumhaz (`tempcumhaz'):*xb		
			global cumhaz0 0 		//ignore
			
			cap pr drop gensurvsim_core
			gensurvsim_core, maxtime(`maxtime') tempnewvarname(`nvar1') tempu(`tempu') rc(_survsim_rc) tempcovs(`xbcovs') `temptde'	///
								iterations(`iterations') centol(`centol') mintime(`mintime') `enter' ch
			cap macro drop cumhaz cumhaz0
	
		}
		
		if ("`cumhazard'"!="" | "`logcumhazard'"!="") {
			
			mata: st_local("tempcumhaz",subinstr("`logcumhazard'`cumhazard'","#t","t"))
			mata: st_local("tempcumhaz0",subinstr("`logcumhazard'`cumhazard'","#t","enter"))
			if "`logcumhazard'"!="" {
				local tempcumhaz exp(`tempcumhaz')
				local tempcumhaz0 exp(`tempcumhaz0')
			}
			local tempcumhaz (`tempcumhaz'):*xb
			local tempcumhaz0 (`tempcumhaz0'):*xb
			
			//tde's
			if "`tde'"!="" {
				local temptde temptde(`tdexb')
				if "`tdefunction'"=="" {
					local tdefunction #t	
				}
				mata: st_local("tdefunction1",subinstr(st_local("tdefunction"),"#t","t"))
				local tempcumhaz (`tempcumhaz') :* exp(tdexb :* (`tdefunction1'))
				
				mata: st_local("tdefunction0",subinstr(st_local("tdefunction"),"#t","enter"))
				local tempcumhaz0 (`tempcumhaz0') :* exp(tdexb :* (`tdefunction0'))
			}
		
			//any variables in cumh() or logcumh()
			local nhazvars = 0
			macro drop overallsyntax1 overallsyntax2 mmrootsyntax1 mmrootsyntax2				
			gettoken first rest : tempcumhaz, parse("[ ,\^\*\(\)-\+/:<>=]")
			while "`rest'"!="" {
				if trim("`first'")!="," {
					cap confirm var `first', exact
					if !_rc {
						local test1 = 0
						foreach var in `covlist' {
							if "`first'"=="`var'" local test1 = 1
						}
						if `test1'==0 {
							local covlist `covlist' `first'		//contains a list of all varnames specified, be they time-indep or time-dependent
							local nhazvars = `nhazvars' + 1
							mata: st_local("tempcumhaz",subinstr(st_local("tempcumhaz"),"`first'","hazvars[1,`nhazvars']"))
							mata: st_local("tempcumhaz0",subinstr(st_local("tempcumhaz0"),"`first'","hazvars[1,`nhazvars']"))
						}
					}
				}
				gettoken first rest : rest, parse("[ ,\^\*\(\)-\+/:<>=]")
			}			
			if `nhazvars' {
				mata: st_view(hazvars=.,.,tokens("`covlist'"))
				global overallsyntax1 numeric matrix hazvars
				global overallsyntax2 hazvars
				global mmrootsyntax1 , hazvars[i,]
				global mmrootsyntax2 , hazvars
			}
				
			//hazard function
			global cumhaz `tempcumhaz'		
			global cumhaz0 `tempcumhaz0'		
			if `nhazvars'==0 {
				//test
				mata: t = xb = tdexb = 0.1
				cap mata: test1 = $cumhaz
				if _rc {
					di as error "Error in logcumhazard()/cumhazard()"
					exit 198
				}
				mata mata drop t xb tdexb test1
			}		
			
			cap pr drop gensurvsim_core
			gensurvsim_core, maxtime(`maxtime') tempnewvarname(`nvar1') tempu(`tempu') rc(_survsim_rc) tempcovs(`xbcovs') `temptde'	///
								iterations(`iterations') centol(`centol') mintime(`mintime') `enter' ch
			cap macro drop cumhaz cumhaz0
			if `nhazvars'!=0 {
				cap macro drop overallsyntax1 overallsyntax2 mmrootsyntax1 mmrootsyntax2
			}

		}
		
		
	//===============================================================================================================================================================//
	//summarise _survsim_rc
	
		qui su _survsim_rc if _survsim_rc==1, meanonly
		if r(N)>0 {
			di in yellow "Warning: `r(N)' survival times did not converge"
			di in yellow "         They have been set to final iteration"
			di in yellow "         You can identify them by _survsim_rc = 1"
		}
		qui su _survsim_rc if _survsim_rc==2, meanonly
		if r(N)>0 {
			di in yellow "Warning: `r(N)' survival times were below the lower limit of `mintime'"
			di in yellow "         They have been set to `mintime'"
			di in yellow "         You can identify them by _survsim_rc = 2"
		}
		qui su _survsim_rc if _survsim_rc==3, meanonly
		if r(N)>0 {
			di in yellow "Warning: `r(N)' survival times were above the upper limit of `maxtime'"
			di in yellow "         They have been set to `maxtime' and can be considered censored"
			di in yellow "         You can identify them by _survsim_rc = 3"
		}
		
		//event indicator
		if `nvars'==2 gen byte `nvar2' = `nvar1'<`maxtime' if `nvar1'!=.
		
end

program define gaussquad_ss, rclass
	syntax [, N(integer -99) LEGendre CHEB1 CHEB2 HERmite JACobi LAGuerre alpha(real 0) beta(real 0)]
	
    if `n' < 0 {
        display as err "need non-negative number of nodes"
		exit 198
	}
	if wordcount(`"`legendre' `cheb1' `cheb2' `hermite' `jacobi' `laguerre'"') > 1 {
		display as error "You have specified more than one integration option"
		exit 198
	}
	local inttype `legendre'`cheb1'`cheb2'`hermite'`jacobi'`laguerre' 
	if "`inttype'" == "" {
		display as error "You must specify one of the integration type options"
		exit 198
	}

	tempname weights nodes
	mata ss_gq("`weights'","`nodes'")
	return matrix weights = `weights'
	return matrix nodes = `nodes'
end

mata:
	void ss_gq(string scalar weightsname, string scalar nodesname)
{
	n =  strtoreal(st_local("n"))
	inttype = st_local("inttype")
	i = range(1,n,1)'
	i1 = range(1,n-1,1)'
	alpha = strtoreal(st_local("alpha"))
	beta = strtoreal(st_local("beta"))
		
	if(inttype == "legendre") {
		muzero = 2
		a = J(1,n,0)
		b = i1:/sqrt(4 :* i1:^2 :- 1)
	}
	else if(inttype == "cheb1") {
		muzero = pi()
		a = J(1,n,0)
		b = J(1,n-1,0.5)
		b[1] = sqrt(0.5)
    }
	else if(inttype == "cheb2") {
		muzero = pi()/2
		a = J(1,n,0)
		b = J(1,n-1,0.5)
	}
	else if(inttype == "hermite") {
		muzero = sqrt(pi())
		a = J(1,n,0)
		b = sqrt(i1:/2)
	}
	else if(inttype == "jacobi") {
		ab = alpha + beta
		muzero = 2:^(ab :+ 1) :* gamma(alpha + 1) * gamma(beta + 1):/gamma(ab :+ 2)
		a = i
		a[1] = (beta - alpha):/(ab :+ 2)
		i2 = range(2,n,1)'
		abi = ab :+ 2 :* i2
		a[i2] = (beta:^2 :- alpha^2):/(abi :- 2):/abi
		b = i1
        b[1] = sqrt(4 * (alpha + 1) * (beta + 1):/(ab :+ 2):^2:/(ab :+ 3))
        i2 = i1[2..n-1]
        abi = ab :+ 2 :* i2
        b[i2] = sqrt(4 :* i2 :* (i2 :+ alpha) :* (i2 :+ beta) :* (i2 :+ ab):/(abi:^2 :- 1):/abi:^2)
	}
	else if(inttype == "laguerre") {
		a = 2 :* i :- 1 :+ alpha
		b = sqrt(i1 :* (i1 :+ alpha))
		muzero = gamma(alpha :+ 1)
    }

	A= diag(a)
	for(j=1;j<=n-1;j++){
		A[j,j+1] = b[j]
		A[j+1,j] = b[j]
	}
	symeigensystem(A,vec,nodes)
	weights = (vec[1,]:^2:*muzero)'
	weights = weights[order(nodes',1)]
	nodes = nodes'[order(nodes',1)']
	st_matrix(weightsname,weights)
	st_matrix(nodesname,nodes)
}
		
end
