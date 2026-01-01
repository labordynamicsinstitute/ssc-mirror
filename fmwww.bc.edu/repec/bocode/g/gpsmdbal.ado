*! command: gpsMDbal; version: 9 02 October 2024
*! Enrico Cristofoletti
***************************	
*VERSION HISTORY
*gpsMDbal9 is the same as gpsMDbal8 but it is converted to a r-class command (before e-class but it was the wrong class)
*version: 8 uses __ptile as default and not _ptile
***************************
*gpsmdbal +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
***************************	
program define gpsmdbal, rclass
	version 14.2
	*
	#delimit ;
	syntax varlist (min=2), 
	cutpoints(numlist max=1)
	index(string)
	nq_gpsmd(numlist max=1)
	discrtreat(string)
	[ptile(string)
	gpsmdtequalt(string)
	obs_notsup(string)
	ln(varlist)
	level(numlist max=1)
	]
	;
	#delimit cr	
	capture assert "`varlist'"=="`:list uniq varlist'"
		if _rc!=0{
			display as error "Variables cannot be repeated"
			error
		}

	/*
	varlist: The variable we want to test if balance
	cutpoints: the number of discrete intervals of the dimensions of the treatment(min 2)
	index: the point at which we want to calculate the gps in each subset of the treatment
	nq_gpsmd: the number of discrete subset of the propensity score
	discrtreat: the name for the variables with the discrete treatment
	ptile: the rooth for the discrete sets of the dimensions of the treatment 
	gpsmdtequalt: the rooth for the variable with the various gpsmd calculated (for each discrete set of the treatment 
				a point is chosen and the gpsmd at that point is calculated)
	obs_notsup: the string with the name of the variables 0-1 calculated with ComSupp
	ln(numlist integer): the treatment dimensions we want to take the log transform
	level(numlist max=1): significance level for the final output default .05
	the program does:
	*test before conditioning on propensity score
	1. the treatment dimensions are divided in `cutpoints' quantiles
	2. each observation is assigned to one of the `cutpoints'x`cutpoints' sets
	3. test the equality of means 
	*/
	
	*I create a local with the treatment dimensions as well as other useful stuff from the previous
	*gpsmd command and default values
		*check start***
			*I assess if a previous gpsmd has been run
			capture assert "`r(cmd)'"== "gpsmd"
			if _rc!=0 {
				display as error "gpsmd should be run before gpsmdbal"
				error 
			}
		*check end***
	local Dimensions=r(Dimensions)
	if "`ln'" == ""{
		local listvarFS= r(Dimensions)
		*listvarFS is equal to Dimensions if ln=="" otherwise I fill it 
		*with the number of the transformed variables
	}
	else if "`ln'" != ""{
		capture: assert strmatch(`"`r(cmdline)'"',"*ln(*)*")==1
		if _rc!=0 {
			display as error "gpsmd should be run with the option ln before running gpsmdbal with the option ln"
			error 
		}
		local listvarFS= r(DimensionsFS)
		local LNVARGEN=r(LNVarCreated)
	}
	local gpsmdNumofDim: word count `listvarFS'
	local gpsmdvar=r(gpsmdvar) 
	local Exogenous=r(Exogenous)
	tempname VarCov 
	matrix `VarCov'=r(VarCov)
	*level
	if "`level'"==""{
		local level=0.05
	}
	
	*check start***
		*discrtreat
			confirm new variable `discrtreat'
		*definition Numsubset
			local Numsubset= `cutpoints'^(`gpsmdNumofDim')
		*ptile
			local ptilenonmesso=0
			if "`ptile'"==""{
				local ptile "__ptile"
				local ptilenonmesso=1
			}
			foreach Dim of local Dimensions{
				capture: confirm new variable `ptile'`Dim'
				if _rc!=0 & `ptilenonmesso'==0{
					display as error "variable `ptile'`Dim' already defined choose another rooth"
					error 
				}
				else if _rc!=0 & `ptilenonmesso'==1{
					display as error "variable `ptile'`Dim' already defined choose a rooth different from the default one"
					error 
				}
			}
		*gpsmdtequalt
			if "`gpsmdtequalt'"!=""{
				forvalues i=1(1)`Numsubset'{
					capture: confirm new variable `gpsmdtequalt'`i'
					if _rc!=0{
						display as error "variable `gpsmdtequalt'`i' already defined choose another rooth"
						error 
					}
				}
			}
	*check end***
	*I generate a local with the name of the variables with quantiles that I will update in the loop
		local QuantVars ""
	*temporary vars and names
			*for 2 
				*I generate the temporary names for the variable that will help me to discriminate quantiles
				tempvar nn 
			*for 3
				*tempvar for indexing the ttest
				tempvar ttestind
				*tempname for the matrixes with the results of ttest
				tempname ResMat
			*for 4
				*name for the marix of chosenpoints foreach discretized treatment i
					*tempname Chosenpoint`i' i \in discretized treatment
					*I generate these matrixes in the loop
				*Varname for the predicted treatment 
					*tempvar Predicted`j' for `j' \in Dimension
					*I generate these vars in the loop
				*name for the matrix of predicted treatment
					*tempvar PredMat`i' i \in discretized treatment
					*I generate these matrixes in the loop
				*name for vectors of gps and variables of gps
					*tempvar gpsBalvec`i' i \in discretized treatment
					*I generate these variables in the loop
				*name for the variables with the discrete gps
					*tempvar Discrgpsmd`i' i \in discretized treatment
					*I generate these variables in the loop 
				*name for the matrix with the results
					*tempvar ResultAdj`=subinstr("`i'","`ttestind'","",.)' i \in discretized treatment
					*I generate these variables in the loop 

	
	*1. The treatment dimensions are divided in `cutpoints' quantiles
		foreach Dim of local Dimensions{
			*Quantiles are computed as http://www.nber.org/stata/efficient/percentiles.html
			sort `Dim'
			gen double `ptile'`Dim' = int((`cutpoints'*(_n-1))/_N)+1
			qui: replace `ptile'`Dim'=`ptile'`Dim'[_n-1] if `Dim'[_n]==`Dim'[_n-1]
			local QuantVars="`QuantVars'" + " " + "`ptile'`Dim'"
		}
	*2. Each observation is assigned to one of the `cutpoints'^`cutpoints' sets
			sort `QuantVars'
			gen `nn'=_n
			bysort `QuantVars': egen double `discrtreat'=max(`nn')
				*I rename the sets from one to `cutpoints'x`gpsmdNumofDim' (now the 
				*name is the maximum value of _n within the set which is not the best)
				qui: levelsof `discrtreat', local(levels)
				local j=1
				foreach i of local levels{
					qui: replace `discrtreat'=`j' if `discrtreat'==`i'
					local j=`j'+1
				}
			*check start***
				capture: assert `: word count `levels''==`Numsubset'
				if _rc!=0{
					display as error "There are less subsets of the treatment than you have chosen: check the distribution of the treatment dimensions"
					error
				}
			*check end***
			
	*3. Testing the equality of means
		*I do the ttest for the equality of means for each discrete treatment
		*A matrix foreach discrete treatment is generated where, in column, there are all the r objects of ttest
		qui: tab `discrtreat', gen(`ttestind') 
		*Part that changes when obs_notsup START********
		/*If obs_notsup is provided then U calculate every stuff dropping these obs when I calculate the gps groups and statistics BUT NOT  when I subset the treatment 
		when I calculate the several gps*/
		if "`obs_notsup'"!=""{
			tempfile NODropWithobs_notsup
			qui: save `NODropWithobs_notsup', replace
			qui: drop if `obs_notsup'==1
		}
			foreach i of varlist `ttestind'* {
				foreach exogen of local varlist{
						qui: display _newline "******************************************************************************************************" ///
						        _newline "TTEST" _newline "SET: `=subinstr("`i'","`ttestind'","",.)'" _newline "VARIABLE: `exogen' " ///
						        _newline "******************************************************************************************************" _newline
					if "`exogen'"=="`:word 1 of `varlist''"{		
						*for the first variable I calculate the t test and the base matrix where I will add every other variable for that set (In the matrix there are all the r objects of ttest) 
						qui: ttest `exogen', by (`i')
						matrix `ResMat'_`=subinstr("`i'","`ttestind'","",.)' =(r(mu_1)-r(mu_2), r(level), r(sd), r(sd_2), r(sd_1), r(se), r(p_u), r(p_l), r(p), r(t), r(df_t), r(mu_2),r(N_2), r(mu_1), r(N_1) )
						matrix rownames `ResMat'_`=subinstr("`i'","`ttestind'","",.)' = "`exogen'"
						matrix colnames `ResMat'_`=subinstr("`i'","`ttestind'","",.)' = "r(mu_1)-r(mu_2)" "r(level)" "r(sd)" "r(sd_2)" "r(sd_1)" "r(se)" "r(p_u)" "r(p_l)" "r(p)" "r(t)" "r(df_t)" "r(mu_2)" "r(N_2)" "r(mu_1)" "r(N_1)"
					}
					else if "`exogen'"!="`:word 1 of `varlist''" {
						*for the other variables I calculate the t test and I update the base matrix
						qui: ttest `exogen', by (`i')
						matrix `ResMat'_`=subinstr("`i'","`ttestind'","",.)'_`exogen' = (r(mu_1)-r(mu_2), r(level), r(sd), r(sd_2), r(sd_1), r(se), r(p_u), r(p_l), r(p), r(t), r(df_t), r(mu_2),r(N_2), r(mu_1), r(N_1) )
						matrix rownames `ResMat'_`=subinstr("`i'","`ttestind'","",.)'_`exogen' = "`exogen'"
						matrix colnames `ResMat'_`=subinstr("`i'","`ttestind'","",.)'_`exogen' = "r(mu_1)-r(mu_2)" "r(level)" "r(sd)" "r(sd_2)" "r(sd_1)" "r(se)" "r(p_u)" "r(p_l)" "r(p)" "r(t)" "r(df_t)" "r(mu_2)" "r(N_2)" "r(mu_1)" "r(N_1)"
						matrix `ResMat'_`=subinstr("`i'","`ttestind'","",.)' = `ResMat'_`=subinstr("`i'","`ttestind'","",.)' \ `ResMat'_`=subinstr("`i'","`ttestind'","",.)'_`exogen'
					}
				}
			}
		if "`obs_notsup'"!=""{
			use `NODropWithobs_notsup', clear
		}
		*Part that changes when obs_notsup END********
		
	*4.Generating the test for the equality of mean conditional on propensity score
		*the steps:
		*for each discrete set of the treatment
		*(a)I generate a vector with the desired point 
		*(b)I run the reduced regressions and I predict the treatment given covariates which I store in the matrix
		*(c)then I will subtract the prediction from the regression thus obtaining the vector of residuals at the desired point
		*(d)I generate a variable with the propensity score at the desired point
		*(e)I discretize the propensity score just calculated in nq_gpsmd sets
		*(f)I estimate the statistic for the test
		*(g)I run the ttest
		*(h)I generate a matrix foreach discrete treatment is generated where, in column, there are all the r objects of ttest
		foreach i of varlist `ttestind'* {
			*(a)I generate the vector
				tempname Chosenpoint`i'
				foreach Dim of local Dimensions{ 
					if "`Dim'"=="`:word 1 of `Dimensions''"{
						quietly: summarize `Dim' if `i'==1, detail
						matrix `Chosenpoint`i''=(r(`index'))
					}
					else if "`Dim'"!="`:word 1 of `Dimensions''"{
						quietly: summarize `Dim' if `i'==1, detail
						matrix `Chosenpoint`i''=(`Chosenpoint`i'' \ r(`index'))
					}
				}
				
			
			*(b)(c)I run the regressions and I estimate the predicted values which I store in the matrix
			*then I calculate the residuals from the chosenpoint at point (a)
				*before I generate a macro for the mkmat
				local PredRes ""
				foreach Dim of local listvarFS {
					*I generate a temporary name for the variables of predicted resitual at the given point
						tempvar Predicted`Dim' 
					*I run the regression
						qui: reg `Dim' `Exogenous' 
					*I predict the means
						predict double `Predicted`Dim'' , xb
					*I calculate the residuals as the chosenpoin minus the predicted treatment
						if strmatch("`LNVARGEN'","*`Dim'*")!=1{
							qui: replace `Predicted`Dim''= `Chosenpoint`i''[`: list posof "`Dim'" in listvarFS', 1] - `Predicted`Dim''
							}
						else if strmatch("`LNVARGEN'","*`Dim'*")==1{
							qui: replace `Predicted`Dim''= ln(`Chosenpoint`i''[`: list posof "`Dim'" in listvarFS', 1]) - `Predicted`Dim''
						}
					*I update the local macro with the list of the name of the variables of residuals
						local PredRes= "`PredRes'" + " " + "`Predicted`Dim''"
				}
				
				
			*(d)I generate a variable with the propensity score at the desired point
				*I take the vectors of residuals and I make them a matrix Nxk 
					tempname PredMat`i'
					mkmat `PredRes', matrix("`PredMat`i''")
				*I generate the name for the new var of propensity score
					tempname gpsBalvec`i'
				*I calculate the propensity score
					mata: `PredMat`i''=st_matrix("`PredMat`i''")
					mata: `VarCov'=st_matrix("`VarCov'")
					mata: `gpsBalvec`i'' = (1/(((2* pi())^(`gpsmdNumofDim'/2))*((det(`VarCov'))^(1/2)))) * exp((-1/2) * diagonal((`PredMat`i'') * (invsym( `VarCov' )) * ((`PredMat`i'')')))
					mata: st_matrix("`gpsBalvec`i''", `gpsBalvec`i'' )
						*I clean a bit mata
						mata: mata drop `VarCov'
						mata: mata drop `PredMat`i''
						mata: mata drop `gpsBalvec`i''
				*I attach the colvector to the stata dataset
					svmat double `gpsBalvec`i'', names("`gpsBalvec`i''")
						matrix drop `gpsBalvec`i''
						rename `gpsBalvec`i''1 `gpsBalvec`i''
					*check start***
						capture: assert `gpsBalvec`i''>=0 
						if _rc!=0 {
							display as error "For some kind of reason the estimated gps lower than zero. It could be that you have selected an index which does not correspond to any r-class object of summarize"
							error
						}
				*I retrasform if needed
					if "`ln'"!=""{
						foreach transformed of local ln{
							qui: replace `gpsBalvec`i''=`gpsBalvec`i''/`Chosenpoint`i''[`: list posof "`transformed'" in Dimensions', 1]
						}
					}
					*check end***
				*I save the gpsmd for the level T=t_`i' for whom that want it 
				if "`gpsmdtequalt'"!="" {
					gen double `gpsmdtequalt'`=subinstr("`i'","`ttestind'","",.)'=`gpsBalvec`i''
				}
			*Part that changes when obs_notsup START********
			/*If obs_notsup is provided then U calculate every stuff dropping these obs when I calculate the gps groups and statistics BUT NOT  when I subset the treatment 
			when I calculate the several gps*/
			if "`obs_notsup'"!=""{
				tempfile NODropWithobs_notsup
				qui: save `NODropWithobs_notsup', replace
				qui: drop if `obs_notsup'==1
			}
			*(e)I discretize the propensity score just calculated in nq_gpsmd sets
				*I divide `gpsBalvec`i'' in nq_gpsmd quantiles
				tempvar Discrgpsmd`i'
				sort `gpsBalvec`i''
				gen double `Discrgpsmd`i'' = int((`nq_gpsmd'*(_n-1))/_N)+1
				qui: replace `Discrgpsmd`i''= `Discrgpsmd`i''[_n-1] if `gpsBalvec`i''[_n]==`gpsBalvec`i''[_n-1]
					*check start***
						qui: levelsof `Discrgpsmd`i'', local(levels)
						capture: assert `: word count `levels''==`nq_gpsmd'
						if _rc!=0{
							display "gpsmdNumofDim =`gpsmdNumofDim'"
							display as error "assert `: word count `levels''==`nq_gpsmd' not zero. It seems impossible to divide gpsmd" _newline ///
							"in the number of intervals you require. Probably this is due to a chosen treatment t that determine a g(t,X)" _newline ///
							"identical for a large set of observations" _newline ///
							"In order to make you check some variables can be generated" _newline ///
							"If you do not care simply push enter. Otherwise, if you want to choose the names for the objects (text: Y), if you want the default names (text: D)" _newline ///
							_request(_Decision)
							if "`Decision'"=="Y"{
								display as error "If you do not care about an object simply push enter and nothing will be generated" _newline ///
								"The discrete gpsmd generated with less intervals than required. Tell the name you want" _newline ///
								_request(_Variabileinerrore)
									if "`Variabileinerrore'"!="" {
										gen double `Variabileinerrore'=`Discrgpsmd`i''
									}
								display as error "The the residuals generated for each dimension. Tell the root you want" _newline ///
								_request(_ResRoot)
									if "`ResRoot'"!="" {
										foreach Dim of local listvarFS {
											gen double `ResRoot'`=subinstr("`i'","`ttestind'","",.)'`Dim'=`Predicted`Dim''
											} 
										}
								display as error "The gpsmd generated for the discrete subset of the treatment that has reported error. Tell the root you want" _newline ///
								_request(_gpsmdError)
									if "`gpsmdError'"!="" {
										gen double `gpsmdError'`=subinstr("`i'","`ttestind'","",.)'=`gpsBalvec`i''
									} 
								display as error "The Variance covariance matrix. Tell the name you want" _newline ///
								_request(_Varianzacovarianza)
									if "`Varianzacovarianza'"!="" {
										matrix `Varianzacovarianza'= `VarCov'
									}
								display as error "The matrix with the chosen treatment for the discrete subset of the treatment that has reported error. Tell the name you want" _newline ///
								_request(_Chosenpoint)
									if "`Chosenpoint'"!="" {
										matrix `Chosenpoint'`=subinstr("`i'","`ttestind'","",.)'= `Chosenpoint`i''
									}
							}
							else if "`Decision'" == "D" {
								display as error "you have chosen default"
								gen double Discrgpsmd`=subinstr("`i'","`ttestind'","",.)'ERR =`Discrgpsmd`i''
								foreach Dim of local listvarFS {
										gen double PredMat`=subinstr("`i'","`ttestind'","",.)'`Dim'=`Predicted`Dim''
										}
								gen double gpsBalvec`=subinstr("`i'","`ttestind'","",.)'=`gpsBalvec`i''
								matrix VarCov= `VarCov'
								matrix Chosenpoint`=subinstr("`i'","`ttestind'","",.)'= `VarCov'
							}
							else if "`Decision'" == "" {
								display as error "you do not care"
							}
							display _newline(2)
							error
						}
					*check end***
			*(f)(g)(h)I estimate the statistic (see notes for the formula) for the test I run the test and I store the results in
			*`ResultAdj`=subinstr("`i'","`ttestind'","",.)''
				foreach exogen of local varlist{
					*I generate the following scalar that correspond to parts of the test statistic
					tempname Num1 Denum1 Num2 Denum2 Tstatistics
					scalar define `Num1' = 0
					scalar define `Denum1' = 0
					scalar define `Num2' = _N - 2*`nq_gpsmd'
					scalar define `Denum2' = 0
					*since the statistics sum over the interval of Gps I loop over it
					qui: levelsof `Discrgpsmd`i'', local(Discrgpsmdlevels)
					foreach gpsmdlevel of local Discrgpsmdlevels {
						*I run a ttest  foreach couple at a given GPS level since in this way I have a lot of the necessary macro
							*check start***
								qui: count if `Discrgpsmd`i''==`gpsmdlevel' & `i'==1
								local checkGroup1=r(N)
								qui: count if `Discrgpsmd`i''==`gpsmdlevel' & `i'==0
								local checkGroup2=r(N)
								capture: assert `checkGroup1'>0 & `checkGroup2'>0
								if _rc!=0{
									if `checkGroup1'==0{
									display as error "In calculating the test using the chosen treatment for the discrete subset of the treatment `=subinstr("`i'","`ttestind'","",.)' " _newline /// 
									"there is the discrete subset `gpsmdlevel' of the gpsmd which appear only for the discrete subsets of the treatment different from `=subinstr("`i'","`ttestind'","",.)'"
									}
									if `checkGroup2'==0{
									display as error "In calculating the test using the chosen treatment for the discrete subset of the treatment `=subinstr("`i'","`ttestind'","",.)' " _newline /// 
									"there is the discrete subset `gpsmdlevel' of the gpsmd which appear only for the discrete subsets `=subinstr("`i'","`ttestind'","",.)'"
									}
									error
								}
							*check end***
						qui: ttest `exogen' if `Discrgpsmd`i''==`gpsmdlevel', by(`i')
						scalar define `Num1'= scalar(`Num1') + ((r(N_1) + r(N_2)) * (r(mu_1) - r(mu_2)))  
						scalar define `Denum1'= scalar(`Denum1') + ( ((r(N_1) + r(N_2))^(2)) * ((1 / r(N_1))+ (1/ r(N_2))) ) 
						scalar define `Denum2'= scalar(`Denum2') + ( ((r(N_1)-1)*(r(sd_1)^(2))) + ((r(N_2)-1)*(r(sd_2)^(2))) )  
					}
					*I generate the statistics by putting together all the partial stuff
					scalar define `Tstatistics'= ( (scalar(`Num1')/((scalar(`Denum1'))^(1/2))) * (( scalar(`Num2') / scalar(`Denum2') )^(1/2)) )
					*I put all in a matrix ResultAdj`=subinstr("`i'","`ttestind'","",.)'
						if "`exogen'"=="`:word 1 of `varlist''"{
							tempname ResultAdj`=subinstr("`i'","`ttestind'","",.)'
							matrix `ResultAdj`=subinstr("`i'","`ttestind'","",.)''= ( (scalar(`Num1')/`=_N') , scalar(`Tstatistics'), 2*t(scalar(`Num2'), -abs( scalar(`Tstatistics') )), scalar(`Num2'))
						}
						if "`exogen'"!="`:word 1 of `varlist''"{
							matrix `ResultAdj`=subinstr("`i'","`ttestind'","",.)'' = (`ResultAdj`=subinstr("`i'","`ttestind'","",.)'' \ (scalar(`Num1')/`=_N'), scalar(`Tstatistics'), 2*t(scalar(`Num2'), -abs( scalar(`Tstatistics') )), scalar(`Num2'))
						}					
				}
				*I change the name of the rows and columns
				matrix rownames `ResultAdj`=subinstr("`i'","`ttestind'","",.)'' = `varlist'
				matrix colnames `ResultAdj`=subinstr("`i'","`ttestind'","",.)'' = "Weighted mean difference" "t" "p-value" "DegOfFree" 
				*****
		if "`obs_notsup'"!=""{
			use `NODropWithobs_notsup', clear
		}
		*Part that changes when obs_notsup END********
		}
		
*I drow a table with the most important results
	tempname TabellaRes TabellaAdjRes TableImpRes
		*for the results not adjusted
		foreach i of varlist `ttestind'* { 
			if `=subinstr("`i'","`ttestind'","",.)'==1{
			matrix `TabellaRes' = `ResMat'_`=subinstr("`i'","`ttestind'","",.)'[1..., "r(p)"]
			}
			if `=subinstr("`i'","`ttestind'","",.)'!=1{
			matrix `TabellaRes' = (`TabellaRes', `ResMat'_`=subinstr("`i'","`ttestind'","",.)'[1..., "r(p)"])
			}
		}
		local counter=1
		foreach i in `: colfullnames `TabellaRes''{
		local NomiTabellaRes="`NomiTabellaRes'"+ " " + "`counter'"+"`i'"
		local counter=`counter'+1
		}
		 matrix colnames `TabellaRes' = `NomiTabellaRes'
		 *for the results adjusted

		 foreach i of varlist `ttestind'* { 
			if `=subinstr("`i'","`ttestind'","",.)'==1{
			matrix `TabellaAdjRes' = `ResultAdj`=subinstr("`i'","`ttestind'","",.)''[1..., "p-value"]
			}
			if `=subinstr("`i'","`ttestind'","",.)'!=1{
			matrix `TabellaAdjRes' = (`TabellaAdjRes', `ResultAdj`=subinstr("`i'","`ttestind'","",.)''[1..., "p-value"])
			}
		}
		local counter=1
		foreach i in `: colfullnames `TabellaAdjRes''{
		local NomiTabellaAdjRes="`NomiTabellaAdjRes'"+ " " + "`counter'"+"Adj_r(p)"
		local counter=`counter'+1
		}
		 matrix colnames `TabellaAdjRes' = `NomiTabellaAdjRes'
		*I define the matrix with the important results and I print the table considering the user defined level 
		 matrix `TableImpRes'= (`TabellaRes', `TabellaAdjRes')
		 display _newline "********" _newline "P-VALUES" _newline "********"
		 display _newline "****************" _newline "In the following TableImpRes is reported" _newline "****************" _newline
		 matlist `TableImpRes'
		 tempname TableImpRes2
		 mata: st_matrix("`TableImpRes2'", mm_cond(st_matrix("`TableImpRes'"):> `level' , ., st_matrix("`TableImpRes'"))) //moremata is a dependency 
		 mat rownames `TableImpRes2'= `: rownames `TableImpRes'' 
		 mat colnames `TableImpRes2'= `: colnames `TableImpRes'' 
		 display _newline "****************" _newline "In the following TableImpRes is reported but p-values higher than the threshold specified in level(string) are omitted" _newline "****************" _newline
		 matlist `TableImpRes2'
		 
		 * Idefine a matrix with the means differences and the weigthed mean difference
		 tempname Tabmeandiff Tabmeandiff2
			 *I pack the difference in mean
			 foreach i of varlist `ttestind'* { 
				if `=subinstr("`i'","`ttestind'","",.)'==1{
				matrix `Tabmeandiff' = `ResMat'_`=subinstr("`i'","`ttestind'","",.)'[1..., "r(mu_1)-r(mu_2)"]
				}
				if `=subinstr("`i'","`ttestind'","",.)'!=1{
				matrix `Tabmeandiff' = (`Tabmeandiff', `ResMat'_`=subinstr("`i'","`ttestind'","",.)'[1..., "r(mu_1)-r(mu_2)"])
				}
			}
			*I define the names for the means
				local counter=1
				foreach i in `: colfullnames `Tabmeandiff''{
					local NomiTabmeandiff="`NomiTabmeandiff'"+ " " + "`counter'"+"mean_diff"
					local counter=`counter'+1
				}
			*I pack the weigthed difference in means to the difference in means	
			foreach i of varlist `ttestind'* { 
				matrix `Tabmeandiff' = (`Tabmeandiff', `ResultAdj`=subinstr("`i'","`ttestind'","",.)''[1..., "Weighted mean difference"])
			}
			*I define the names for the weigthed difference in means
			local counter=1
			foreach i in `=`: colfullnames `Tabmeandiff''/2' {
				local NomiTabmeandiff="`NomiTabmeandiff'"+ " " + "`counter'"+"Weigh_mean_diff"
				local counter=`counter'+1
			}
			 matrix colnames `Tabmeandiff' = `NomiTabmeandiff'
		*I define the matrix with the table considering the user defined level (Tabmeandiff)
		*and I print the results (both Tabmeandiff and Tabmeandiff2)
			display _newline "********" _newline "MEAN DIFFERENCES" _newline "********"
			display _newline "****************" _newline "In the following Tabmeandiff is reported" _newline "****************" _newline
			matlist `Tabmeandiff'
			mata: st_matrix("`Tabmeandiff2'", mm_cond(st_matrix("`TableImpRes'"):> `level' , ., st_matrix("`Tabmeandiff'"))) //moremata is a dependency 
			mat rownames `Tabmeandiff2'= `: rownames `Tabmeandiff'' 
			mat colnames `Tabmeandiff2'= `: colnames `Tabmeandiff'' 
			display _newline "****************" _newline "In the following Tabmeandiff is reported but mean differences whose p-values are higher than the threshold specified in level(string) are omitted" _newline "****************" _newline
			matlist `Tabmeandiff2'
		 
*+the various e-class objects
	*I remove e-class objects
	return clear
	*I add the needed
	return local cmdline `"gpsmdbal `0'"'
	return local cmd `"gpsmdbal"'
	qui: ds `ttestind'*
	return local NofDiscTreat "`: word count `r(varlist)''"
	
	foreach i of varlist `ttestind'* { 
	return matrix Chosenpoint`=subinstr("`i'","`ttestind'","",.)' = `Chosenpoint`i''
	return matrix Result`=subinstr("`i'","`ttestind'","",.)' = `ResMat'_`=subinstr("`i'","`ttestind'","",.)'
	return matrix ResultAdj`=subinstr("`i'","`ttestind'","",.)' = `ResultAdj`=subinstr("`i'","`ttestind'","",.)''
	}
	return matrix TableImpRes=`TableImpRes'
	return matrix TableImpRes2=`TableImpRes2'
	return matrix Tabmeandiff=`Tabmeandiff'
	return matrix Tabmeandiff2=`Tabmeandiff2'
	return local Dimensions "`Dimensions'"
	return local DimensionsFS "`listvarFS'"
	return local LNVarCreated  "`LNVARGEN'"

end
*end*******
