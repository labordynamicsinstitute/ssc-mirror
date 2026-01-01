*! command: gpsmdpolest; version: 18 26 November 2025
*! Enrico Cristofoletti
***************************	
*VERSION HISTORY
*gpsMDPolEst18 is the same as gpsMDPolEst17 but it is converted to a r-class command (before e-class but it was the wrong class)
*gpsMDPolEst17 is the same as the gpsMDPolEst16.5 but it is not beta anymore
*gpsMDPolEst16.5 can manage large datasets by the function loop_prod2 that substitutes for diagonal(quadcross((quadcross((`gpsmddemeanedTreat')',(invsym( `gpsmdVarCovar' ))))', ((`gpsmddemeanedTreat')')))
*gpsMDPolEst16.4 generates the variables naming them starting with double underscore __. NON BC bootstrapp confidence intervals return at a testing stage 
*				 remove the part under the heading "*Non BC bootstrap confidence intervals are at a testing stage therefore only Bias Corrected standard intervals are available start ***"
*				 to continue testing it
*gpsMDPolEst16.3 does not generate results for plotmatrix in case of treatments with 2 dimensions.
*gpsMDPolEst16.2 is the non test version of gpsMDPolEst16.2_test. It does not stop anymore. Versions previus than gpsMDPolEst16.2_test does not implement (ln(GPS)*GPS)^exponent neither more complex exponent like (T1^2*GPS^4)
*Note power like (T1*GPS^4) need to be expressed as (T1^1*GPS^4) otherwise (T1*GPS)^(4) is implemented
*from gpsMDPolEst16.2 fractional polinomial are implemented gpsMDPolEst16.2_test is a test version because it stops since I wanted to check matfromstring function
*from gpsMDPolEst16.1 I start to implement that when no bootstrap is required, confidence intervals not accounting for generated regressors are provided
*gpsMDPolEst16 is the same as the gpsMDPolEst15.11 but it is not beta anymore
*gpsMDPolEst15.11 makes available and tested "Percentile_t" bootstrap
***************************
*gpsmdpolest +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
***************************	
*********************************************************************************
*+++++++++++++++++++++++++++++++STATA START++++++++++++++++++++++++++++++++++++++
*********************************************************************************
****	
program define gpsmdpolest, rclass
	version 14.2
	#delimit ;
	syntax  varlist(min=2), 
	gpsmd(string)
	model(string)
	exogenous(varlist)
	file_pred(string)
	numboot(numlist integer max=1)
	[boottype(string)
	dividingint(numlist integer max=1)
	matrtreat(string)
	level(numlist max=1)
	index(string) 
	cutpoints(numlist integer max=1)
	ln(varlist)
	matrixwithresults(string)
	]
	;
	#delimit cr	
	/*
	varlist: indep Dimensions
	model: a string with the rigth side of the model. It which should be explicit e.g. "T1 + T2 + `gpsmd' + T1*`gpsmd' + T2*`gpsmd' + T1^(2) + T2^2 + (`gpsmd'^2) + ((T1*`gpsmd')^(2)) + (T2*`gpsmd')^2 + ln(T1) + ln(T1)^2 + ln(T1)*gps"
	dividingint: an integer with the number of intervals for each dimension. The program create a matrix with a set of points to estimate of order (dividingint +1)^(number of dimension)
	matrtreat: string with the name of a matrix with the points the user is interested in. Dimensions must be in columns such that a single point is identified by a row
	exogenous: the exogenous variables the user want to use in the reduced equations
	file_pred: the incipit of the name for the files dta with the results
	level: the confidence level for the confidence intervals (default 0.05)
	numboot: the number of bootstrap
	boottype(string): a string that determine the type of bootrap, it must be "" for the default "BC", bias corrected, the default, "Percentile_t" for Percentile_t bootstrap Poi, B. P. (2004). From the help desk: Some bootstrapping techniques. The Stata Journal, 4(3), 312–328.
	index(string): the point where you want to calculate gpsmd (can be "mean" or "p50") when calculate the common support
	cutpoints: the number of discrete intervals of the dimensions of the treatment when you calculate the common support
	ln(varlist): the treatment dimensions we want to take the log transform
	matrixwithresults(string): if T a matrix with results is generated, default==T
	*/
	
	*controls:
	capture: assert ("`matrtreat'"=="" & "`dividingint'"!="")|("`matrtreat'"!="" & "`dividingint'"=="")
	if _rc!=0 {
		display as error "or matrtreat or dividingint must be non empty"
		error 
	}
	*I define the default confidence level
	if "`level'"==""{
		local level "0.05"
	}
	*I define the default for index and cutpoints options
	if ("`cutpoints'"=="" & "`index'"!="") | ("`cutpoints'"!="" & "`index'"==""){
		display as error "If you want to drop unbalanced observations then you need to specify both cutpoints and index"
		error
	}
	if "`index'"==""{
		local index "0"
	}
	if "`cutpoints'"==""{
		local cutpoints=0
	}
	if "`matrixwithresults'"!="F"{
		local matrixwithresults "T"
	}
	*I define the default type of bootstrap
	if `numboot'==0 {
		
	}
		*Non BC bootstrap confidence intervals are at a testing stage therefore only Bias Corrected standard intervals are available start ***
		capture: assert `numboot'>0
		if _rc!=0 {
			display as error "numboot==0. You must specify the number of bootstrapp iterations"
			error 
		}
		*Non BC bootstrap confidence interval are at a testing stage therefore only Bias Corrected standard intervals are available end ***
		
	capture: assert("`boottype'"=="" | "`boottype'"=="BC" | "`boottype'"=="Percentile_t")
	if _rc!=0 {
		display as error "Only BC or Percentile_t bootstrap allowed"
		error 
	}
	if "`boottype'"=="" {
		local boottype "BC"
		//possibilities "BC" "Percentile_t"
	}
	*I check, in case of "ln"!="" if ln option has been previously specified
	if "`ln'" != ""{
		capture: assert strmatch(`"`r(cmdline)'"',"*ln(*)*")==1
		if _rc!=0 {
			display as error "gpsmd should be run with the option ln before running gpsmdpolest with the option ln"
			error 
		}
	}
	*I define a local for the Outcome and one for the dimensions
	local Outcome="`:word 1 of `varlist''"
	local Dimensions="`: list varlist - Outcome'" 
	
/*index
if common support is required
1. I generate the model if IterativelyRESETFirstShot is required I generate the model with it
	if  IterativelyRESETFirstShot is not used the regression for the polynomial estimation is
	reg `Outcome' `Dimensions'`gpsmd' `ListGenVar'
	when IterativelyRESETFirstShot is used it is possible that only a subset of "`Dimensions' `gpsmd'" is selected
	since the commands in mata internally generate the regression by binding "`Dimensions' `gpsmd'" with `ListGenVar'
	I define a vector with the position of the variables in "`Dimensions' `gpsmd'" which are selected by IterativelyRESETFirstShot (called `Shelvector')
	if IterativelyRESETFirstShot is not used this vector is (1..`=wordcount("`Dimensions' `gpsmd'")')
	then the commands in mata run the regression binding "`Dimensions' `gpsmd'"[.,Shelvector] with `ListGenVar'
2. I make an output of the dose response function I generate a matrix with the treatment point which i want to estimate (each row correspond to a point) matrtreatGPS
3. I generate the prediction
*/

	*1./2. 
	*tempobject defined: matrtreatGPS vectreat pseudotruthvec
		*before everything I remove the plus from the model macro
		local model=subinstr("`model'"," ","",.)
		local model=subinstr("`model'","+"," ",.)
		*I generate a local with the variables that must be generated
		local VariablesToGen: list model - Dimensions
		local VariablesToGen: list VariablesToGen - gpsmd
		*I generate a local with the basevar in the model (e.g. basevar={`Dimensions' `gpsmd'}, if the model is  Y=ln(gps) none of the basevar is used)
		local BaseVarToBeUsed "`Dimensions' `gpsmd'"
		local BaseVarToBeRemoved: list BaseVarToBeUsed - model
		local BaseVarToBeUsed: list BaseVarToBeUsed - BaseVarToBeRemoved
		
		
		*starting with the meat (we have two main cases, with common support restriction, without common support restriction
		tempname Shelvector
		if "`index'"!="0" {
				tempvar SuppCommTemp
				if "`ln'"!=""{
					quietly: gpsmdcomsup  `Dimensions' , exogenous(`exogenous') index(`index')  cutpoints(`cutpoints') obs_notsup(`SuppCommTemp') ln(`ln')
				}
				else if "`ln'"==""{
					quietly: gpsmdcomsup  `Dimensions' , exogenous(`exogenous') index(`index')  cutpoints(`cutpoints') obs_notsup(`SuppCommTemp') 
				}
				*I generate the model
					qui: GenVarFromAString, model("`VariablesToGen'") //GenVarFromAString is a program defined in AUXILIARY PROGRAMS
					local ListGenVar=r(ListGenVar)
					local ComplModel "`BaseVarToBeUsed' `ListGenVar'"
					display _newline "****************" _newline ///
					"The regression estimating the dose-response function is calculated only on the common support. The output is the following:" ///
					_newline "****************" _newline 
					mata: `Shelvector' = selectindex(colsum(strpos((tokens("`Dimensions' `gpsmd'")), (tokens("`ComplModel'"))')):>=1)
					reg `Outcome' `ComplModel' if `SuppCommTemp'!=1
				*I generate the matrix with the treatment
				if "`matrtreat'"=="" {
					tempname matrtreatGPS vectreat pseudotruthvec
					*I generate a local with the total number of combination qwhich is 1+`dividingint' 
					*because we add the zero (eg. `dividingint'=3 then possibilities are delta*(0,1,2,3))
					local totnum=(1+`dividingint')^(`:word count `Dimensions'')
					*I define the delta and i generate a vector with the chosenpoint
					foreach i of local Dimensions{
						quietly: summarize `i' if `SuppCommTemp'!=1
						local delta= abs(r(max)- r(min))/`dividingint'
						*I generate a vector with the chosenpoints for the i dimension and the base vector for the column of matrtreatGPS
						local j=0
						while `j' <=  `dividingint' {
							if `j'==0{
								matrix define `vectreat'= ( `=r(min)' )
								matrix define `pseudotruthvec'=J(`totnum'/((1+`dividingint')^(`: list posof "`i'" in Dimensions')), 1, `vectreat'[1,1] )
								local j=`j'+1
							}
							else if ( `j'>0 ) & ( `j'< `= 1 + `dividingint'' ) {
								matrix define `vectreat'= ( `=r(min) + `delta'*`j'' )
								matrix define `pseudotruthvec'=(`pseudotruthvec'\ J(`totnum'/((1+`dividingint')^(`: list posof "`i'" in Dimensions')), 1, `vectreat'[1,1] ))
								local j=`j'+1
							}
							else if `j'== `dividingint' {
								matrix define `vectreat'= ( `=r(max)' )
								matrix define `pseudotruthvec'=(`pseudotruthvec'\ J(`totnum'/((1+`dividingint')^(`: list posof "`i'" in Dimensions')), 1, `vectreat'[1,1] ))
								local j=`j'+1
							}	
						}
						*I generate matrtreatGPS by multiplying pseudotruthvec for the required times
						if `: list posof "`i'" in Dimensions'==1{
							mata: `pseudotruthvec'= st_matrix("`pseudotruthvec'")
							mata: `matrtreatGPS'=J(((1+`dividingint')^(`: list posof "`i'" in Dimensions'-1)), 1, `pseudotruthvec' )
						}
						else if (`: list posof "`i'" in Dimensions'>1) & (`: list posof "`i'" in Dimensions'< `:word count `Dimensions'' ){
							mata: `pseudotruthvec'= st_matrix("`pseudotruthvec'")
							mata: `matrtreatGPS'=(`matrtreatGPS', J(((1+`dividingint')^(`: list posof "`i'" in Dimensions'-1)), 1, `pseudotruthvec' ))
						}
						else if (`: list posof "`i'" in Dimensions'== `:word count `Dimensions'' ){
							mata: `pseudotruthvec'= st_matrix("`pseudotruthvec'")
							mata: `matrtreatGPS'=(`matrtreatGPS', J(((1+`dividingint')^(`: list posof "`i'" in Dimensions'-1)), 1, `pseudotruthvec' ))
							*I export again in stata
							mata: st_matrix("`matrtreatGPS'", `matrtreatGPS' )
							matrix colnames `matrtreatGPS'= `Dimensions'
						}

					}
				}
				else if "`matrtreat'"!="" {
					tempname matrtreatGPS
					matrix define `matrtreatGPS'= `matrtreat'
				}
			}
			else if "`index'"=="0"{
				*I generate the model
					qui: GenVarFromAString, model("`VariablesToGen'") //GenVarFromAString is a program defined in AUXILIARY PROGRAMS
					local ListGenVar=r(ListGenVar)
					local ComplModel "`BaseVarToBeUsed' `ListGenVar'"
					display _newline "****************" _newline ///
					"The regression estimating the dose-response function is calculated. The output is the following:" ///
					_newline "****************" _newline 
					mata: `Shelvector' = selectindex(colsum(strpos((tokens("`Dimensions' `gpsmd'")), (tokens("`ComplModel'"))')):>=1)
					reg `Outcome' `ComplModel'
				*I generate the matrix with the treatment
				if "`matrtreat'"=="" {
					tempname matrtreatGPS vectreat pseudotruthvec
					*I generate a local with the total number of combination qwhich is 1+`dividingint' 
					*because we add the zero (eg. `dividingint'=3 then possibilities are delta*(0,1,2,3))
					local totnum=(1+`dividingint')^(`:word count `Dimensions'')
					*I define the delta and i generate a vector with the chosenpoint
					foreach i of local Dimensions{
						quietly: summarize `i'
						local delta= abs(r(max)- r(min))/`dividingint'
						*I generate a vector with the chosenpoints for the i dimension and the base vector for the column of matrtreatGPS
						local j=0
						while `j' <=  `dividingint' {
							if `j'==0{
								matrix define `vectreat'= ( `=r(min)' )
								matrix define `pseudotruthvec'=J(`totnum'/((1+`dividingint')^(`: list posof "`i'" in Dimensions')), 1, `vectreat'[1,1] )
								local j=`j'+1
							}
							else if ( `j'>0 ) & ( `j'< `= 1 + `dividingint'' ) {
								matrix define `vectreat'= ( `=r(min) + `delta'*`j'' )
								matrix define `pseudotruthvec'=(`pseudotruthvec'\ J(`totnum'/((1+`dividingint')^(`: list posof "`i'" in Dimensions')), 1, `vectreat'[1,1] ))
								local j=`j'+1
							}
							else if `j'== `dividingint' {
								matrix define `vectreat'= ( `=r(max)' )
								matrix define `pseudotruthvec'=(`pseudotruthvec'\ J(`totnum'/((1+`dividingint')^(`: list posof "`i'" in Dimensions')), 1, `vectreat'[1,1] ))
								local j=`j'+1
							}	
						}
						*I generate matrtreatGPS by multiplying pseudotruthvec for the required times
						if `: list posof "`i'" in Dimensions'==1{
							mata: `pseudotruthvec'= st_matrix("`pseudotruthvec'")
							mata: `matrtreatGPS'=J(((1+`dividingint')^(`: list posof "`i'" in Dimensions'-1)), 1, `pseudotruthvec' )
						}
						else if (`: list posof "`i'" in Dimensions'>1) & (`: list posof "`i'" in Dimensions'< `:word count `Dimensions'' ){
							mata: `pseudotruthvec'= st_matrix("`pseudotruthvec'")
							mata: `matrtreatGPS'=(`matrtreatGPS', J(((1+`dividingint')^(`: list posof "`i'" in Dimensions'-1)), 1, `pseudotruthvec' ))
						}
						else if (`: list posof "`i'" in Dimensions'== `:word count `Dimensions'' ){
							mata: `pseudotruthvec'= st_matrix("`pseudotruthvec'")
							mata: `matrtreatGPS'=(`matrtreatGPS', J(((1+`dividingint')^(`: list posof "`i'" in Dimensions'-1)), 1, `pseudotruthvec' ))
							*I export again in stata
							mata: st_matrix("`matrtreatGPS'", `matrtreatGPS' )
							matrix colnames `matrtreatGPS'= `Dimensions'
						}

					}
				}
				else if "`matrtreat'"!="" {
					tempname matrtreatGPS
					matrix define `matrtreatGPS'= `matrtreat'
				}
			}
		
		
	*3
	*I generate the predictions for each point in the vector. I store them in a vector, I generate a new dataset with the name the user has chosen.
		*I generate the list of variables that need to be created in the mata function (All those in the model but gps and dimensione
			local VariabiliTuttoMata: list model - Dimensions
			local VariabiliTuttoMata: list VariabiliTuttoMata - gpsmd
			*VariabiliTuttoMata are variables that have to be created in order to estimate the model
		*I import the in mata necessary variables
		
			*Simple import
			tempname OutcomeTuttoMata TreatmentTuttoMata ExogenousTuttoMata ChosentreatTuttoMata ResultsTuttoMata UpperBounds LowerBounds
			mata: `OutcomeTuttoMata'=st_data(.,"`Outcome'")
			mata: `TreatmentTuttoMata'=st_data(.,"`Dimensions'")
			mata: `ExogenousTuttoMata'=st_data(.,"`exogenous'")
			mata: `ChosentreatTuttoMata'=st_matrix("`matrtreatGPS'")
			*Moreover I generate the vector with the position of the variables which are logtransformed (logTrans)
			tempname logTrans
			if "`ln'"==""{
				mat define `logTrans' = (0)
			}
			else if "`ln'"!="" {
				foreach i of local ln{
					if `: list posof "`i'" in ln'==1{
						mat define `logTrans'=( `: list posof "`i'" in Dimensions' )
					}
					else if `: list posof "`i'" in ln'!=1{
						mat define `logTrans'=( `logTrans', `: list posof "`i'" in Dimensions' )
					}
				}
			}
			mata: `logTrans' = st_matrix("`logTrans'")
			*display start***
			*display _newline "****************" _newline ///
			*"The following is the position of the variables which are transformed" ///
			*_newline "****************" _newline
			*mata: `logTrans'
			*display end***
		*I generate the results
			mata: `ResultsTuttoMata'=PolEst(`Shelvector', `OutcomeTuttoMata', `TreatmentTuttoMata', "`Dimensions' `gpsmd'", "`VariabiliTuttoMata'", `ExogenousTuttoMata', `ChosentreatTuttoMata', "`index'", `cutpoints', `logTrans')
			if "`numboot'"=="0" {
				mata: `UpperBounds' =1
				mata: `LowerBounds' =1
				
				tempname ResPolEstTP
				mata: `ResPolEstTP'=PolEstTP(`Shelvector', `OutcomeTuttoMata', `TreatmentTuttoMata', "`Dimensions' `gpsmd'", "`VariabiliTuttoMata'", `ExogenousTuttoMata', `ChosentreatTuttoMata', "`index'", `cutpoints', `logTrans')
				//I need also the variance in this case using ResultsTuttoMata for PrevEstB is not enough. I keep this in the if statement because I prefer to change only subsets of the code
				
				mata: SimpleConf(`Shelvector', `OutcomeTuttoMata', `TreatmentTuttoMata', "`Dimensions' `gpsmd'", "`VariabiliTuttoMata'", `ExogenousTuttoMata', `ChosentreatTuttoMata', `ResPolEstTP', `UpperBounds', `LowerBounds', `level' , `numboot', "`index'", `cutpoints', `logTrans')
				display _newline "****************" _newline ///
				"Theoretical confidence intervals that do not account for the generated regressor are provided" _newline ///
				"****************" _newline
			}
			else if "`numboot'"!="0" {
				if "`boottype'"=="BC" {
					mata: `UpperBounds' =1
					mata: `LowerBounds' =1
					*display start***
					display _newline "****************" _newline ///
					"It starts the bootstrap BC, it may take a while" _newline ///
					"****************" _newline
					*display end***
					mata: BootstrapPolEsBC(`Shelvector', `OutcomeTuttoMata', `TreatmentTuttoMata', "`Dimensions' `gpsmd'", "`VariabiliTuttoMata'", `ExogenousTuttoMata', `ChosentreatTuttoMata', `ResultsTuttoMata', `UpperBounds', `LowerBounds', `level' , `numboot', "`index'", `cutpoints', `logTrans')
					display _newline "****************" _newline ///
					"Bootstrap ended" _newline ///
					"****************" _newline
				}
				else if "`boottype'"=="Percentile_t" {
					mata: `UpperBounds' =1
					mata: `LowerBounds' =1
					*display start***
					tempname ResPolEstTP
					mata: `ResPolEstTP'=PolEstTP(`Shelvector', `OutcomeTuttoMata', `TreatmentTuttoMata', "`Dimensions' `gpsmd'", "`VariabiliTuttoMata'", `ExogenousTuttoMata', `ChosentreatTuttoMata', "`index'", `cutpoints', `logTrans')
					//I need also the variance in this case using ResultsTuttoMata for PrevEstB is not enough. I keep this in the if statement because I prefer to change only subsets of the code
					display _newline "****************" _newline ///
					"It starts the bootstrap Percentile_t, it may take a while" _newline ///
					"****************" _newline
					*display end***
					mata: BootstrapPolEsTP(`Shelvector', `OutcomeTuttoMata', `TreatmentTuttoMata', "`Dimensions' `gpsmd'", "`VariabiliTuttoMata'", `ExogenousTuttoMata', `ChosentreatTuttoMata', `ResPolEstTP', `UpperBounds', `LowerBounds', `level' , `numboot', "`index'", `cutpoints', `logTrans')
					display _newline "****************" _newline ///
					"Bootstrap ended" _newline ///
					"****************" _newline
				}
			}
			*I generate the datasets with the results (not bostrapped, highboottstrap, lowbootstrap): a)with the predictions(dta) 
				*a)with the prediction and partial derivatives (dta) (treatments, predictions, partial derivatives)
					preserve
						*I generate the names for the new variables of the dataset
							foreach i in "`ResultsTuttoMata'" "`UpperBounds'" "`LowerBounds'"{
								if "`i'"=="`UpperBounds'"{
									local Bootname "BootH_"
								}
								else if "`i'"=="`LowerBounds'"{
									local Bootname "BootL_"
								}
								local namepartial ""
								foreach j of local Dimensions {
										local namepartial `"`namepartial' `=strtoname("`Bootname'PD_`j'")'"'
										local namepartial=strtrim(`"`namepartial'"')
									}
								local booteddimname
								foreach j of local Dimensions {
										local booteddimname `"`booteddimname' `=strtoname("`Bootname'`j'")'"'
										local booteddimname=strtrim(`"`booteddimname'"')
									}
									local Nomi`Bootname' `""`=subinstr(`"`booteddimname' `Bootname'response `namepartial'"'," ",`"" , ""',.)'""'
									local Bootname ""
							}
							
							
						*importo i dati
							clear
							qui: set obs `=rowsof(`matrtreatGPS')'
							foreach i in "`ResultsTuttoMata'" "`UpperBounds'" "`LowerBounds'" {
								if "`i'"=="`UpperBounds'"{
									local Bootname "BootH_"
								}
								else if "`i'"=="`LowerBounds'"{
									local Bootname "BootL_"
								}
								mata: (void) st_addvar("double", (`Nomi`Bootname''))
								mata: st_store(., (`Nomi`Bootname''), `i' )
								}
						*I drop useless vars
							foreach i of local Dimensions{
								drop Boot?_`i'
							}
						*I save
						qui: save "`file_pred'.dta", replace
					restore
					
	*+the various e-class objects
			*I remove e-class objects
				return clear
			*I generate those I want
				return local cmdline `"gpsmdpolest `0'"'
				return local cmd `"gpsmdpolest"'
				return local regmodel "reg `Outcome' `ComplModel'"
				return local listgenvar "`ListGenVar'"

				*the dimension of the treatment and the exogenous vars
				return local Outcome "`Outcome'"
				return local Dimensions "`Dimensions'"
				return local exogenous "`exogenous'"
				return local gpsmd "`gpsmd'" 
				
				*error miscellanea
				return local error506 "`error506'"
				return local error499 "`error499'"
				return local error499_2 "`error499_2'"
				return local itNumbRude "`itNumbRude'"
				// mata: `ResultsTuttoMata'
				
				*the matrix var covar
				return matrix matrtreat = `matrtreatGPS'
				if "`matrixwithresults'"=="T" {
					tempname returnresults
					if "`numboot'"=="0"{
							mata: `returnresults'=(`ResultsTuttoMata', `UpperBounds'[.,((cols(`TreatmentTuttoMata')+1).. cols(`UpperBounds'))], `LowerBounds'[.,((cols(`TreatmentTuttoMata')+1)..cols(`LowerBounds'))] )
							mata: st_matrix("`returnresults'", `returnresults')
							foreach i of local Dimensions {
								if `:list posof "`i'" in Dimensions'==1{
								local matrixname "PD_`i'"
								}
								else {
									local matrixname "`matrixname' PD_`i'"
								}
							}
							foreach i of local Dimensions {
								if `:list posof "`i'" in Dimensions'==1{
								local matrixnameBootH "BootH_PD_`i'"
								}
								else {
									local matrixnameBootH "`matrixnameBootH' BootH_PD_`i'"
								}
							}
							foreach i of local Dimensions {
								if `:list posof "`i'" in Dimensions'==1{
								local matrixnameBootL "BootL_PD_`i'"
								}
								else {
									local matrixnameBootL "`matrixnameBootL' BootL_PD_`i'"
								}
							}
							matrix colnames `returnresults'= `Dimensions' Response `matrixname' BootH_response `matrixnameBootH' BootL_response `matrixnameBootL'
							return matrix returnresults=`returnresults'
					}
					else if "`numboot'"!="0"{
							mata: `returnresults'=(`ResultsTuttoMata', `UpperBounds'[.,((cols(`TreatmentTuttoMata')+1).. cols(`UpperBounds'))], `LowerBounds'[.,((cols(`TreatmentTuttoMata')+1)..cols(`LowerBounds'))] )
							mata: st_matrix("`returnresults'", `returnresults')
							foreach i of local Dimensions {
								if `:list posof "`i'" in Dimensions'==1{
								local matrixname "PD_`i'"
								}
								else {
									local matrixname "`matrixname' PD_`i'"
								}
							}
							foreach i of local Dimensions {
								if `:list posof "`i'" in Dimensions'==1{
								local matrixnameBootH "BootH_PD_`i'"
								}
								else {
									local matrixnameBootH "`matrixnameBootH' BootH_PD_`i'"
								}
							}
							foreach i of local Dimensions {
								if `:list posof "`i'" in Dimensions'==1{
								local matrixnameBootL "BootL_PD_`i'"
								}
								else {
									local matrixnameBootL "`matrixnameBootL' BootL_PD_`i'"
								}
							}
							matrix colnames `returnresults'= `Dimensions' Response `matrixname' BootH_response `matrixnameBootH' BootL_response `matrixnameBootL'
							return matrix returnresults=`returnresults'
						}
				}
end
*********************************************************************************
*+++++++++++++++++++++++++++++++STATA END++++++++++++++++++++++++++++++++++++++
*********************************************************************************

*--------------------------------------------------------------------------------
*+++++++++++++++++++++++++++++++MATA START++++++++++++++++++++++++++++++++++++++
*--------------------------------------------------------------------------------
mata: mata drop LinReg()

mata: mata drop LinRegS()

mata:

//sampleRPVec(dta, n)
	real matrix sampleRPVec(dta, n)
		{
		//adapted from here https://www.stata.com/statalist/archive/2005-11/msg00135.html
		//A sample with replacement of the rows of A is drawn
		//dta: the matrix whose rows we want to sample
		//n: the number of rows we want to draw
		nrowsdta = rows(dta)
		return(ceil(nrowsdta * runiform(n, 1))) 
		//a matrix can be subset by chosing the rows or column with a vector, tecnically also 1..5 define a vector. It is like c(1:5) in R
		}
//************
//sampleRP(dta)
	function sampleRP(dta, n)
		{
		//adapted from here https://www.stata.com/statalist/archive/2005-11/msg00135.html
		//A sample with replacement of the rows of A is drawn
		//dta: the matrix whose rows we want to sample
		//n: the number of rows we want to draw
		nrowsdta = rows(dta)
		return(dta[(ceil(nrowsdta * runiform(n, 1))), (1 .. cols(dta))]) 
		//a matrix can be subset by chosing the rows or column with a vector, tecnically also 1..5 define a vector. It is like c(1:5) in R
		}
//************
//LinReg(dep, indep)
	struct LinRegS
	{
	real matrix B, RES, PRE
	//B: coefficients; RES: residuals ; PRE: predictions. But actually it is simply  new object with three spaces that are matrixes
	}
	struct LinRegS scalar LinReg(real matrix depvar, real matrix indepvar)
		{
		struct LinRegS scalar LR
		real matrix indep
		real matrix dep
		//adapted from here https://blog.stata.com/2016/01/05/programming-an-estimation-command-in-stata-computing-ols-objects-in-mata/
		//see also https://www.stata-journal.com/sjpdf.html?articlenum=pr0035
			indep=(indepvar, J(rows(indepvar),1,1))
			dep=depvar
		//formula OLS: B= (X'X)^-1 (X'Y)
		LR.B=invsym(quadcross(indep, indep)) * quadcross(indep, dep)
		//formula residuals RES=Y- X*B
		LR.RES = dep - indep*LR.B
		//formula Prediction 
		LR.PRE = indep*LR.B
		return(LR)
		}
//************
//loop_prod2(dta, n)
	real matrix loop_prod2(real matrix  mat1, real matrix gpsmdVarCovar)
		{
			real matrix result
			real matrix temporarymat
			real scalar nrowsmat1
			real scalar i
			real scalar counter
		//this function substitutes diagonal(quadcross((quadcross((`gpsmddemeanedTreat')',(invsym( `gpsmdVarCovar' ))))', ((`gpsmddemeanedTreat')')))
		temporarymat=(quadcross((mat1)',(invsym( gpsmdVarCovar ))))'
		nrowsmat1 = rows(mat1)
		if (nrowsmat1<=11000) {
			result= diagonal(quadcross(temporarymat, (mat1)')) 
		}
		else if (nrowsmat1>11000) {
			counter=11000
			while (counter<=nrowsmat1) {
				if (counter==11000) {
					//counter
					result= diagonal(quadcross(temporarymat[.,(1 .. counter)], (mat1[(1 .. counter),.])')) 
					counter=counter+1 
				}
				else if (counter>11000) {
					//counter
					result=(result \ diagonal(quadcross(temporarymat[.,(counter .. min((counter+11000, nrowsmat1)))], (mat1[(counter .. min((counter+11000, nrowsmat1))),.])')) )
					counter=min((counter+11000, nrowsmat1))+1
				}
			}
		}
		return(result) 
		//a matrix can be subset by chosing the rows or column with a vector, tecnically also 1..5 define a vector. It is like c(1:5) in R
		}
//************
//gpsmd
	real matrix gpsmd(real matrix Dim, real matrix exogenous, real matrix LogTranslist)  
		{
		struct LinRegS scalar LMFirstStage
		real matrix usedDIM
		real matrix ResMat
		real matrix VarMat
		real matrix gps
		//for the loops I define:
		real scalar i, N_i
		//N_i is the number of loops in the main loop 
		usedDIM=Dim
		if (LogTranslist!=0){
			for (i=1; i<=cols(LogTranslist); i++){
				usedDIM[., LogTranslist[1, i]]=ln(usedDIM[.,LogTranslist[1, i]])
			}	
		}
		//Dim: matrix with one col for every dimension of the treatment
		//exogenous: matrix with the exogenous variables and possibly the interactions
		//LogTranslist: rowvector, each dimension includes the position in Dim of the treatment dimension we want to transform 
		//I generate the residuals for the regression:
			LMFirstStage=LinReg( usedDIM[.,1] , exogenous )
			ResMat=LMFirstStage.RES
				N_i=cols(usedDIM)
			for (i=2;i<=N_i;i++){
				LMFirstStage=LinReg( usedDIM[.,i] , exogenous )
				ResMat=(ResMat, LMFirstStage.RES)
			}
		//I calculate the variance covariance of the residuals
			VarMat=variance(ResMat)
		//I calculate the gps vector
			gps=(1/(((2* pi())^(cols(usedDIM)/2))*((det(VarMat))^(1/2)))) * exp((-1/2) * loop_prod2(ResMat, VarMat))
		//if (LogTranslist!=0) I retransform
			if (LogTranslist!=0){
					N_i=cols(LogTranslist)
				for (i=1; i<=N_i; i++){
				gps = gps :/ Dim[., LogTranslist[1, i]]
				}	
			}
			return(gps)
		}
//************
//************
//gpsmdGivenPoint
	real matrix gpsmdGivenPoint(real matrix Dim, real matrix exogenous, real matrix Chosentreat, real matrix LogTranslist)  
		{
		struct LinRegS scalar LMFirstStage
		real matrix usedDIM
		real matrix usedChosentreat
		real matrix ResMat
		real matrix usedChosentreatMat
		real matrix ResfromChoTrMat
		real matrix VarMat
		real matrix gps
		usedDIM=Dim
		usedChosentreat=Chosentreat
		if (LogTranslist!=0){
			for (i=1; i<=cols(LogTranslist); i++){
				usedDIM[., LogTranslist[1, i]]=ln(usedDIM[.,LogTranslist[1, i]])
				usedChosentreat[., LogTranslist[1, i]] = ln(usedChosentreat[.,LogTranslist[1, i]])
			}	
		}
		//Dim: matrix with one col for every dimension of the treatment
		//exogenous: matrix with the exogenous variables and possibly the interactions
		//Chosentreat: is a rowvector with the chosen treatment in each dimension
		//LogTranslist: rowvector, each dimension includes the position in Dim of the treatment dimension we want to transform 
		//I generate the residuals for the regression and from the prediction and the chosen treatment:
			for (i=1;i<=cols(usedDIM);i++){
				LMFirstStage=LinReg( usedDIM[.,i] , exogenous )
				if (i==1){
					ResMat=LMFirstStage.RES
					usedChosentreatMat=J(rows(usedDIM), 1, usedChosentreat[1,i])
					ResfromChoTrMat = usedChosentreatMat - LMFirstStage.PRE
				}
				else if (i>1){
					ResMat=(ResMat, LMFirstStage.RES)
					usedChosentreatMat=J(rows(usedDIM), 1, usedChosentreat[1,i])
					ResfromChoTrMat = (ResfromChoTrMat, (usedChosentreatMat - LMFirstStage.PRE))
				}
			}
		//I calculate the variance covariance of the residuals
			VarMat = variance(ResMat)
		//I calculate the gps vector
			gps=(1/(((2* pi())^(cols(usedDIM)/2))*((det(VarMat))^(1/2)))) * exp((-1/2) * loop_prod2(ResfromChoTrMat, VarMat))
		//if (LogTranslist!=0) I retransform
		if (LogTranslist!=0){
			for (i=1; i<=cols(LogTranslist); i++){
			gps = gps :/ Chosentreat[1, LogTranslist[1, i]]
			}	
		}	
			return(gps)
		}
//************
//************
//Com_supp_PE
	real matrix Com_supp_PE(real matrix treatments, real matrix exogenous, real scalar cutpoints, string scalar index, real matrix LogTranslist)
		{
		//***************
		//(BASICALLY IT IS THE SAME AS gpsmdcomsup BUT I MAKE IN POLEST gpsmdcomsup MORE PARSIMONIOUS 
		//IN RESPECT TO gpsmdcomsup IN ORDER TO ENHANCE SPEED (THIS IS THE REASON WHY  I NAME IT Com_supp_PE)
		//***************
		//the output is a vector which is 1 if the obs must be dropped and 0 otherwise (Obs_unbal)
		//treatments: matrix with the column with the treatments
		//exogenous: matrix with the exogenous variables and possibly the interactions
		//cutpoints: the number of discrete intervals of the dimensions of the treatment
		//index if you want the chosenpoint evaluated at the mean or at the median "mean"|"p50"
		//LogTranslist: rowvector, each dimension includes the position in Dim of the treatment dimension we want to transform 
		real matrix Obs_unbal
		real scalar ntreatments
		real matrix dta
		real matrix tempPercetile
		real matrix groupsid
		real matrix Groupsindta
		real matrix chosenpoints
		real matrix tempchosenpointsCol
		real matrix tempmed
		real scalar rowtempmed
		real matrix tempgroupandgps
		real matrix tempgroup
		real matrix tempnogroup
		
		//for the loops I define:
		real scalar i, j, N_i, N_j
		//N_i is the number of loops in the main loop N_j in the nested loop
			//I define the number of treatment
			ntreatments= cols(treatments)
			//I generate a new matrix with all together treatments plus as the first column a vector with the numbers 
			//from 1 to rows(treatments) in order to keep the order
				dta=( (1 .. rows(treatments))',  treatments)
			//I generate the percentile needed for the ith treatment
					N_i=ntreatments+1
					N_j=rows(dta)
				for (i=2; i<=N_i;i++){
					//I sort dta for the ith treatment
						dta= dta[order(dta[., i], 1),.]
					//I add a vector at the end for the quantiles calculated as in https://www.nber.org/percentiles-and-quantiles
						tempPercetile=trunc( (cutpoints :* ( (1.. rows(dta))':-1 )) :/ rows(dta) ) :+1  
					//I substitute with tempPercetile[_n-1, 1] if dta[_n, 1+1]==dta[_n-1, 1+1]
						for (j=2;j<=N_j;j++){
							if (dta[j, i]==dta[(j-1), i]){
								tempPercetile[j,1]=tempPercetile[(j-1),1]
							}
						}
					//I add the column with the percentiles
						dta=(dta, tempPercetile)
					}
			//I generate the groupsid
				//I generate a matrix with the unique rows of percentiles
					groupsid=uniqrows(dta[.,((ntreatments+2)..cols(dta))]) 
				//I add a column for the identifiers of the group
					groupsid=((1.. rows(groupsid))', groupsid)
				//I add the group as a the last column in dta
					Groupsindta=J(rows(dta), 1 ,0)
						N_i=rows(groupsid)
						N_j=rows(dta)
					for (i=1; i<=N_i; i++){
						Groupsindta[selectindex(rowsum(( dta[.,((ntreatments+2)..cols(dta))]:==groupsid[ i, (2..cols(groupsid))] )):==(cols((2..cols(groupsid))))), 1 ] = ///
						J(rows(selectindex(rowsum(( dta[.,((ntreatments+2)..cols(dta))]:==groupsid[ i, (2..cols(groupsid))] )):==cols((2..cols(groupsid))))), 1,i)
					}
					//I remove the percentiles and I add Groupsindta to  dta
						dta= dta[.,(1..(ntreatments+1))]
						dta=(dta , Groupsindta)
				//dta is now (colvec id, matrix dimension, colvec grupsid)
			//I generate the matrix with the treatments it will have a column for each treatment and a row for each discrete group
				chosenpoints= J(rows(groupsid), ntreatments, 0)
					N_i=ntreatments+1
					N_j=rows(groupsid)
				if (index=="p50"){
					for (i=2; i<=N_i; i++){
						tempchosenpointsCol= J(rows(groupsid),1,0)
						for (j=1; j<=N_j; j++){
							//see https://www.statalist.org/forums/forum/general-stata-discussion/mata/1335405-can-i-use-mata-to-calculate-a-median-of-the-outcome-in-the-exposed-and-unexposed-groups-following-matching-with-teffects-psmatch
							tempmed=dta[selectindex((Groupsindta :== j)), i]
							tempmed=tempmed[order(tempmed,1), 1 ]
							rowtempmed=rows(tempmed)
							if (ceil((rowtempmed *0.5))==(rowtempmed*0.5)){
								tempchosenpointsCol[j,1]= (tempmed[(rowtempmed*0.5),1] + tempmed[((rowtempmed *0.5) + 1 ),1])/2
							}
							else {
								tempchosenpointsCol[j,1]= 	tempmed[ceil(rowtempmed*0.5),1]							
							}
						}
						chosenpoints[., (i-1)]= tempchosenpointsCol[., 1]
					}
				}
				else if (index=="mean"){
					for (i=2; i<=N_i; i++){
					tempchosenpointsCol= J(rows(groupsid),1,0)
					for (j=1; j<=N_j; j++) {
						tempchosenpointsCol[j,1]= mean(select(dta[., i], (dta[., cols(dta)] :== j )))
					}
					chosenpoints[., (i-1)]= tempchosenpointsCol[., 1]
					}
				}

			//I generate the propensity score at a given point for each chosenpoint and I update the vector Obs_unbal with the unbalanced obs
				//since exogenous is sorted as in the dataset, I sort dta as the dataset
					dta=dta[order(dta[.,1], 1), .]
				//I calculate the gps and I update Obs_unbal
					Obs_unbal= J(rows(dta), 1, 0)
					N_i=rows(chosenpoints)
					for (i=1; i<=N_i; i++){
						tempgroupandgps= (dta[., (cols(dta))] , gpsmdGivenPoint(dta[.,(2..(ntreatments+1))], exogenous, chosenpoints[i, .] , LogTranslist)) 
						tempgroup=select(tempgroupandgps[., (cols(tempgroupandgps))], (tempgroupandgps[.,1]:==i))
						tempnogroup=select(tempgroupandgps[., (cols(tempgroupandgps))], (tempgroupandgps[.,1]:!=i))
						assert(cols(tempgroupandgps)==2) //check (in the defining of Obs_unbal I have substituted cols(tempgroupandgps) with 2. then if you read 2 you should understand cols(tempgroupandgps). I have written this comment so you know what column correspond to 2)
						assert(cols(tempgroup)==1) //check
						assert(cols(tempnogroup)==1) //check
						Obs_unbal[ selectindex( ( tempgroupandgps[., 2] :< max( ( min(tempgroup), min(tempnogroup) ) ) ) :| ( tempgroupandgps[., 2] :> min( ( max(tempgroup), max(tempnogroup ) ) ) ) :| (Obs_unbal:==1)) , 1] = ///
						J(rows(selectindex( ( tempgroupandgps[., 2] :< max( ( min(tempgroup), min(tempnogroup) ) ) ) :| ( tempgroupandgps[., 2] :> min( ( max(tempgroup), max(tempnogroup ) ) ) ) :| (Obs_unbal:==1))), 1, 1)		
					}
					//tempgroup
					//tempnogroup
					//tempgroupandgps
					//chosenpoints
					//(dta, Obs_unbal)
					return(Obs_unbal)
		}
//************		
//************
//MatFromString
	real matrix MatFromString(real matrix Basedata, string scalar BasedataNameS, string scalar vartobecreatedS)
		{
			//********************
			//Basedata: a matrix with the obs un the variables named as BasedataName
			//BasedataNameS: a string with the name of the variables in Basedata separated by a space
			//vartobecreatedS: a string with the variables that needs to be created
			//it has to have the form as in the example "bina*tina (bina*tina)^(3) tina^2"
			//********************
			//I tokenize BasedataName and vartobecreated
				BasedataName=tokens(BasedataNameS)
				vartobecreated=tokens(vartobecreatedS)
			//I generate a dataset (Xt) which will be updated with the variables
			// created accordingly to vartobecreated by using BasedataName every iteration 
			//starting from Basedata
				Xt=Basedata
			for (i=1; i<= cols(vartobecreated); i++) {
				regressor=vartobecreated[1,i]
				//1. the power 1
				if (regexm(regressor,"(\^)(\()?(\-)?([0-9])+(\))?(\))?$")!=1){ 
					//1.1 the interaction without log
					if ((regexm(regressor,"(.)+(\*)(.)+")==1) & (regexm(regressor,"ln\(")!=1)) {
						//I clean regressor thus creating tocs
						tocs=subinstr(regressor," ","",.)
						tocs=subinstr(tocs,"*"," ",.)
						tocs=subinstr(tocs,"(","",.)
						tocs=subinstr(tocs,")","",.)
						//I tokenize tocs
						tocs=tokens(tocs)
						if (cols(tocs)==2){
							newcol =	select(Basedata, strmatch(BasedataName, tocs[1,1]))	:* select(Basedata, strmatch(BasedataName, tocs[1, 2])) 
							//I update the matrix with regressors
							Xt = ( Xt , newcol )
						}
						else if (cols(tocs)!=2){
							exit(error(1))
						}	
					}
					//1.2 the logs
					else if (regexm(regressor,"ln\(")==1) {
						//1.2.1 simply the log
						if (regexm(regressor,"(.)+(\*)(.)+")!=1){
							tocs=subinstr(regressor," ","",.)
							tocs=subinstr(tocs,"ln(","",.)
							tocs=subinstr(tocs,"(","",.)
							tocs=subinstr(tocs,")","",.)
							//I tokenize tocs
							tocs=tokens(tocs)
							if (cols(tocs)==1){
								newcol =	ln(select(Basedata, strmatch(BasedataName, tocs[1,1])))
								//I update the matrix with regressors
								Xt = ( Xt , newcol )
							}
							else if (cols(tocs)!=1){
								exit(error(1))
							}
						}
						//1.2.2 the log and the interaction
						else if (regexm(regressor,"(.)+(\*)(.)+")==1){
							//I generate a new Basedata (Basedatalog) where I change to log what needs to be changed to log)
							tocs=subinstr(regressor," ","",.)
							tocs=subinstr(tocs,"*"," ",.) 
								prelogtoc=tokens(tocs)
								Basedatalog=Basedata
								for (j=1;j<=2;j++){
									if (regexm(prelogtoc[1,j] ,"ln\(")==1){
										nome=subinstr(prelogtoc[1,j],"ln(","",.)
										nome=subinstr(nome,"(","",.)
										nome=subinstr(nome,")","",.)
										Basedatalog[.,selectindex(strmatch(BasedataName, nome))]=ln(select(Basedata, strmatch(BasedataName, nome)))
									}
								}
							//I generate the interactions
							tocs=subinstr(tocs,"ln(","",.)
							tocs=subinstr(tocs,"(","",.)
							tocs=subinstr(tocs,")","",.)
							tocs=tokens(tocs)
							if (cols(tocs)==2){
							//I enumerate all the possibilities but (no,no): (ln, no),(ln,ln), (no,ln))
								if ((regexm(prelogtoc[1,1] ,"ln\(")==1) & (regexm(prelogtoc[1,2] ,"ln\(")!=1)) {
									//select(X,v) selects from X the rows (if the vector v is a column one otherwise the columns) that correspond to v==0,
									newcol =	select(Basedatalog, strmatch(BasedataName, tocs[1,1]))	:* select(Basedata, strmatch(BasedataName, tocs[1, 2])) 
								}
								else if ((regexm(prelogtoc[1,1] ,"ln\(")==1) & (regexm(prelogtoc[1,2] ,"ln\(")==1)) {
									//select(X,v) selects from X the rows (if the vector v is a column one otherwise the columns) that correspond to v==0,
									newcol =	select(Basedatalog, strmatch(BasedataName, tocs[1,1]))	:* select(Basedatalog, strmatch(BasedataName, tocs[1, 2])) 
								}
								else if ((regexm(prelogtoc[1,1] ,"ln\(")!=1) & (regexm(prelogtoc[1,2] ,"ln\(")==1)) {
									//select(X,v) selects from X the rows (if the vector v is a column one otherwise the columns) that correspond to v==0,
									newcol =	select(Basedata, strmatch(BasedataName, tocs[1,1]))	:* select(Basedatalog, strmatch(BasedataName, tocs[1, 2]))  
								}
								Xt = ( Xt , newcol )
							}
							else if (cols(tocs)!=2){
								exit(error(1))
							}
						}
					}
				}
				//2. interaction power # and power # 
				else if (regexm(regressor,"(\^)(\()?(\-)?([0-9])+(\))?(\))?$")==1){
					//2.1 i select the interaction 
					if (regexm(regressor,"(.)+(\*)(.)+")==1){
						// 2.1.1 without log
						if (regexm(regressor,"ln\(")!=1) { 
							//I clean regressor thus creating tocs
							tocs=subinstr(regressor," ","",.)
							tocs=subinstr(tocs,"*"," ",.) 
							tocs=subinstr(tocs,"^"," ",.) 
							tocs=subinstr(tocs,"(","",.)
							tocs=subinstr(tocs,")","",.)
							//I tokenize tocs
							tocs=tokens(tocs)
							if (cols(tocs)==3){
								//select(X,v) selects from X the rows (if the vector v is a column one otherwise the columns) that correspond to v==0,
								newcol =	( select(Basedata, strmatch(BasedataName, tocs[1,1])) :* select(Basedata, strmatch(BasedataName, tocs[1, 2])) ) :^ strtoreal(tocs[1 , 3]) 
								//I update the matrix with regressors
								Xt = ( Xt , newcol )
							}
							if (cols(tocs)==4){
								//for different power in different element of the interaction (this kind of interaction must be of the form (a^2)*(b^3) or (a^1)*b^3 no a*b^3 otherwise a*b^3 becomes (a*b)^3)
								//select(X,v) selects from X the rows (if the vector v is a column one otherwise the columns) that correspond to v==0,
								newcol =	( select(Basedata, strmatch(BasedataName, tocs[1,1])):^ strtoreal(tocs[1 , 2]))  :* (select(Basedata, strmatch(BasedataName, tocs[1, 3])) :^ strtoreal(tocs[1 , 4]) )
								//I update the matrix with regressors
								Xt = ( Xt , newcol )
							}
							else if (cols(tocs)!=3 & cols(tocs)!=4){
								exit(error(1))
							}
						}
						//2.1.2 with log
						if (regexm(regressor,"ln\(")==1) { 
							//I generate a new Basedata (Basedatalog) where I change to log what needs to be changed to log)
							tocs=subinstr(regressor," ","",.)
							tocs=subinstr(tocs,"*"," ",.) 
							tocs=subinstr(tocs,"^"," ",.) 
							prelogtoc=tokens(tocs)
								Basedatalog=Basedata
								//this if else can be improved for speed but it should not be too slow then I leave as it is so it is easier to debug 
								if (cols(prelogtoc)==3){
									for (j=1;j<=2;j++){
										if (regexm(prelogtoc[1,j] ,"ln\(")==1){
											nome=subinstr(prelogtoc[1,j],"ln(","",.)
											nome=subinstr(nome,"(","",.)
											nome=subinstr(nome,")","",.)
											Basedatalog[.,selectindex(strmatch(BasedataName, nome))]=ln(select(Basedata, strmatch(BasedataName, nome)))
										}
									}
								}
								else if (cols(prelogtoc)==4){
									for (j=1;j<=3;j++){
										if ((regexm(prelogtoc[1,j] ,"ln\(")==1)&(j!=2)){
											nome=subinstr(prelogtoc[1,j],"ln(","",.)
											nome=subinstr(nome,"(","",.)
											nome=subinstr(nome,")","",.)
											Basedatalog[.,selectindex(strmatch(BasedataName, nome))]=ln(select(Basedata, strmatch(BasedataName, nome)))
										}
									}
								}
							//I generate the interactions
							tocs=subinstr(tocs,"ln(","",.)
							tocs=subinstr(tocs,"(","",.)
							tocs=subinstr(tocs,")","",.)
							tocs=tokens(tocs)
							if (cols(tocs)==3){
								//I enumerate all the possibilities but (no,no): (ln, no),(ln,ln), (no,ln))
								if ((regexm(prelogtoc[1,1] ,"ln\(")==1) & (regexm(prelogtoc[1,2] ,"ln\(")!=1)) {
								//select(X,v) selects from X the rows (if the vector v is a column one otherwise the columns) that correspond to v==0,
								newcol =	( select(Basedatalog, strmatch(BasedataName, tocs[1,1])) :* select(Basedata, strmatch(BasedataName, tocs[1, 2])) ) :^ strtoreal(tocs[1 , 3]) 
								}
								else if ((regexm(prelogtoc[1,1] ,"ln\(")==1) & (regexm(prelogtoc[1,2] ,"ln\(")==1)) {
								//select(X,v) selects from X the rows (if the vector v is a column one otherwise the columns) that correspond to v==0,
								newcol =	( select(Basedatalog, strmatch(BasedataName, tocs[1,1])) :* select(Basedatalog, strmatch(BasedataName, tocs[1, 2])) ) :^ strtoreal(tocs[1 , 3]) 
								}
								else if ((regexm(prelogtoc[1,1] ,"ln\(")!=1) & (regexm(prelogtoc[1,2] ,"ln\(")==1)) {
									//select(X,v) selects from X the rows (if the vector v is a column one otherwise the columns) that correspond to v==0,
									newcol =	( select(Basedata, strmatch(BasedataName, tocs[1,1])) :* select(Basedatalog, strmatch(BasedataName, tocs[1, 2])) ) :^ strtoreal(tocs[1 , 3]) 
								}
								//I update the matrix with regressors
								Xt = ( Xt , newcol )
							}
							if (cols(tocs)==4){
								//I enumerate all the possibilities but (no,no): (ln, no),(ln,ln), (no,ln))
								if ((regexm(prelogtoc[1,1] ,"ln\(")==1) & (regexm(prelogtoc[1,3] ,"ln\(")!=1)) {
									//for different power in different element of the interaction (this kind of interaction must be of the form (a^2)*(b^3) or (a^1)*b^3 no a*b^3 otherwise a*b^3 becomes (a*b)^3)
									//select(X,v) selects from X the rows (if the vector v is a column one otherwise the columns) that correspond to v==0,
									newcol =	( select(Basedatalog, strmatch(BasedataName, tocs[1,1])):^ strtoreal(tocs[1 , 2]))  :* (select(Basedata, strmatch(BasedataName, tocs[1, 3])) :^ strtoreal(tocs[1 , 4]) )
								}
								else if ((regexm(prelogtoc[1,1] ,"ln\(")==1) & (regexm(prelogtoc[1,3] ,"ln\(")==1)) {
									//for different power in different element of the interaction (this kind of interaction must be of the form (a^2)*(b^3) or (a^1)*b^3 no a*b^3 otherwise a*b^3 becomes (a*b)^3)
									//select(X,v) selects from X the rows (if the vector v is a column one otherwise the columns) that correspond to v==0,
									newcol =	( select(Basedatalog, strmatch(BasedataName, tocs[1,1])):^ strtoreal(tocs[1 , 2]))  :* (select(Basedatalog, strmatch(BasedataName, tocs[1, 3])) :^ strtoreal(tocs[1 , 4]) )
								}
								else if ((regexm(prelogtoc[1,1] ,"ln\(")!=1) & (regexm(prelogtoc[1,3] ,"ln\(")==1)) {
									//for different power in different element of the interaction (this kind of interaction must be of the form (a^2)*(b^3) or (a^1)*b^3 no a*b^3 otherwise a*b^3 becomes (a*b)^3)
									//select(X,v) selects from X the rows (if the vector v is a column one otherwise the columns) that correspond to v==0,
									newcol =	( select(Basedata, strmatch(BasedataName, tocs[1,1])):^ strtoreal(tocs[1 , 2]))  :* (select(Basedatalog, strmatch(BasedataName, tocs[1, 3])) :^ strtoreal(tocs[1 , 4]) )
								}
								//I update the matrix with regressors
								Xt = ( Xt , newcol )
							}
							else if (cols(tocs)!=3 & cols(tocs)!=4){
								exit(error(1))
							}
						}
					}
					//2.2 I select the only power 
					else if (regexm(regressor,"(.)+(\*)(.)+")!=1) { 
						//2.2.1 nolog
						if ((regexm(regressor,"ln\(")!=1)){
							//I clean regressor thus creating tocs
							//printf("the result is %f\n", i)
							tocs= subinstr(regressor,"^"," ",.) 
							tocs=subinstr(tocs,"(","",.) 
							tocs=subinstr(tocs,")","",.) 
							//printf("the substr is %s\n", tocs)
							//I tokenize tocs
							tocs=tokens(tocs)
							if (cols(tocs)==2){
								newcol =	( select(Basedata, strmatch(BasedataName, tocs[1,1])) ) :^ strtoreal(tocs[1 , 2]) 
								//I update the matrix with regressors
								Xt = ( Xt , newcol )
							}
							else if (cols(tocs)!=2){
								exit(error(1))
							}
						}
						//2.2.2 log
						else if ((regexm(regressor,"ln\(")==1)) {
							tocs= subinstr(regressor,"^"," ",.) 
							tocs=subinstr(tocs,"ln(","",.)
							tocs=subinstr(tocs,"(","",.) 
							tocs=subinstr(tocs,")","",.) 
							tocs=tokens(tocs)
							if (cols(tocs)==2){
								newcol =	ln(( select(Basedata, strmatch(BasedataName, tocs[1,1])) )) :^ strtoreal(tocs[1 , 2]) 
								//I update the matrix with regressors
								Xt = ( Xt , newcol )
							}
							else if (cols(tocs)!=2){
								exit(error(1))
							}
						}
					}
				}
			}
		return(Xt[.,((cols(Basedata)+1) .. cols(Xt))])
		}
//************
//************
//PolEst
	real matrix PolEst(real vector Shelvector, real matrix outcome, real matrix treatment, string scalar treatmentPlusgpsmd, string scalar restmodel, real matrix exogenous, real matrix Chosenpoints, string scalar index, real scalar cutpoints, real matrix LogTranslist)
	{
	real matrix DTAEstPol 
	real matrix TGPS
	struct LinRegS scalar LMPol
	real matrix Beta
	real matrix DTABasePred
	real matrix TGPSPred
	if ((cutpoints!=0)&(index!="0")){
		real matrix ComSup
	}
	real matrix response
	real matrix dtaResult
	real matrix panset
	real matrix nplus1
	//for the loops I define:
	real scalar i, j, N_i, N_j
	//N_i is the number of loops in the main loop N_j in the nested loop
	//Shelvector: if the model is generated by IterativelyRESETFirstShot it is not obvius that dimensions and gdp are in the model. Shelvector
	//				is a vector of the position of the variables in (dimensions, gps) that are also in the model so we can generate the rigth matrix when we do the linear regression
	//outcome: matrix with the outcome (rows are the obs)
	//treatment: matrix with the obs for the treatment (rows are the obs)
	//treatmentPlusgpsmd: string with the name of the treatment dimension plus the name of gps
	//restmodel: string with the model but not the treatment and the gps alone
	//exogenous: exogenous variables (rows are the obs)
	//Chosenpoints: the matrix with the points chosen for the estimation (every row is a combination of the dimensions
	//index: the point where you want to calculate gpsmd (can be "mean" or "p50" or "0" if 0 not only the common support is kept)
	//cutpoints: the number of discrete intervals of the dimensions of the treatment(if 0 not only the common support is kept)
	//LogTranslist: rowvector, each dimension includes the position in Dim of the treatment dimension we want to transform 
	
	//1. I calculate the gps
		DTAEstPol=(treatment, gpsmd(treatment, exogenous, LogTranslist))
	//2. I estimate the coefficients then for each Chosenpoint I calculate the effect and I store it in a matrix
		//2.1
		//if we do not care about common support
		if ((cutpoints==0)&(index=="0")){
			// I generate the variables needed as defined in the restmodel
			//and I add a column for the constant
			TGPS = (DTAEstPol[.,Shelvector] , MatFromString(DTAEstPol, treatmentPlusgpsmd, restmodel)) 
			// I estimate and save the coefficients
			LMPol=LinReg(outcome, TGPS) 
			Beta=LMPol.B
			//for each Chosenpoint I calculate the effect and I store it in a matrix
				N_i=rows(Chosenpoints)
			DTABasePred=(J(rows(DTAEstPol), 1, Chosenpoints[1,.] ), gpsmdGivenPoint(treatment, exogenous, Chosenpoints[1,.], LogTranslist)) 
			TGPSPred= (DTABasePred[.,Shelvector] , MatFromString(DTABasePred, treatmentPlusgpsmd, restmodel), J( rows(DTABasePred), 1, 1 ))
			response=mean(TGPSPred*Beta)
			for (i=2;i<=N_i; i++){
				DTABasePred=(J(rows(DTAEstPol), 1, Chosenpoints[i,.] ), gpsmdGivenPoint(treatment, exogenous, Chosenpoints[i,.], LogTranslist)) 
				TGPSPred= (DTABasePred[.,Shelvector] , MatFromString(DTABasePred, treatmentPlusgpsmd, restmodel), J( rows(DTABasePred), 1, 1 ))
				response=(response \ mean(TGPSPred*Beta))
			}
		}
		//if we decide to keep only the common support
		else if ((cutpoints!=0)&(index!="0")){
			// I generate the variables needed as defined in the restmodel
			//and I add a column for the constant
			TGPS = (DTAEstPol[.,Shelvector], MatFromString(DTAEstPol, treatmentPlusgpsmd, restmodel))
			//st_matrix(("pippo") ,  TGPS) I let this command here in needs of debugging MatFromString
			//I estimate the common support and drop the obs not in the common support
			ComSup = Com_supp_PE(treatment, exogenous, cutpoints, index , LogTranslist)
			TGPS = TGPS[selectindex(ComSup:==0),.]
			// I estimate and save the coefficients only with the common support observations
			LMPol=LinReg(outcome[selectindex(ComSup:==0),.], TGPS)
			Beta=LMPol.B
			//for each Chosenpoint I calculate the effect and I store it in a matrix
				N_i=rows(Chosenpoints)
			DTABasePred=(J(rows(DTAEstPol), 1, Chosenpoints[1,.] ), gpsmdGivenPoint(treatment, exogenous, Chosenpoints[1,.], LogTranslist)) 
			TGPSPred= (DTABasePred[.,Shelvector] , MatFromString(DTABasePred, treatmentPlusgpsmd, restmodel), J( rows(DTABasePred), 1, 1 ))
			TGPSPred= TGPSPred[selectindex(ComSup:==0),.]
			response=mean(TGPSPred*Beta)
			for (i=2;i<=N_i; i++){
				DTABasePred=(J(rows(DTAEstPol), 1, Chosenpoints[i,.] ), gpsmdGivenPoint(treatment, exogenous, Chosenpoints[i,.], LogTranslist)) 
				TGPSPred= (DTABasePred[.,Shelvector] , MatFromString(DTABasePred, treatmentPlusgpsmd, restmodel), J( rows(DTABasePred), 1, 1 ))
				TGPSPred= TGPSPred[selectindex(ComSup:==0),.]
				response=(response \ mean(TGPSPred*Beta))	
			}
		}
	//4. I generate the partial derivatives (by simply creating a vector which is response n+1)
		dtaResult=((1..rows(Chosenpoints))',Chosenpoints, response) 
			N_i=(1+cols(Chosenpoints))
		for (i=2;i<=N_i; i++){
			dtaResult=sort(dtaResult, (( select((2..(1+cols(Chosenpoints))), ((2..(1+cols(Chosenpoints))):!=i) ) ), i ) )
			panset= panelsetup(dtaResult, ( select((2..(1+cols(Chosenpoints))), ((2..(1+cols(Chosenpoints))):!=i) ) ) )
			nplus1=dtaResult[., (cols(dtaResult)- i + 2)]
			nplus1=(nplus1[2..rows(nplus1),.] \ 1)
			nplus1= nplus1-dtaResult[., (cols(dtaResult)- i + 2)]
			//I set the maximum value at 0
				N_j=(rows(panset))
			for (j=1;j<=N_j; j++){
				nplus1[panset[j,2], 1]=0
			}
			dtaResult=(dtaResult, nplus1)
		}
		dtaResult=sort(dtaResult, 1) 
		dtaResult=dtaResult[.,2..(cols(dtaResult))]
		//the matrix returned is (dim1, dim2, ..., response, partial1, partial2...)
		return(dtaResult)

	}
//************
//************
//BootstrapPolEsBC
	void BootstrapPolEsBC(real vector Shelvector, real matrix outcome, real matrix treatment, string scalar treatmentPlusgpsmd, string scalar restmodel, real matrix exogenous, real matrix Chosenpoints, real matrix PrevEstB, real scalar UpperBounds, real scalar LowerBounds,  real scalar ConfLev, real scalar numBoot, string scalar index, real scalar cutpoints, real matrix LogTranslist)
	{
		real matrix Boot_Vec
		real matrix Boot_outcome
		real matrix Boot_treatment
		real matrix Boot_exogenous
		real matrix Boot_dta
		real matrix Boot_Results
		real matrix BootedsingleChosenpoints
		real scalar b
		real scalar QH
		real scalar QL
		real matrix upperpartial
		real matrix lowerpartial
		real matrix upperres
		real matrix lowerres
		//for the loops I define:
		real scalar i, j, N_i, N_j, N_j2
		//N_i is the number of loops in the main loop N_j in the nested loop  N_j2 is some constant needed for some conditions
		//Shelvector: if the model is generated by IterativelyRESETFirstShot it is not obvius that dimensions and gdp are in the model. Shelvector
		//				is a vector of the position of the variables in (dimensions, gps) that are also in the model so we can generate the rigth matrix when we do the linear regression
		//outcome: matrix with the outcome (rows are the obs)
		//treatment: matrix with the obs for the treatment (rows are the obs)
		//treatmentPlusgpsmd: string with the name of the treatment dimension plus the name of gps
		//restmodel: string with the model but not the treatment and the gps alone
		//exogenous: exogenous variables (rows are the obs)
		//Chosenpoints: the matrix with the points chosen for the estimation (every row is a combination of the dimensions
		//PrevEstB: the not boostrapped estimation done in a previous run of PolEst
		//UpperBounds: the matrix in which I store the results for the upper bound (It should be generated before running BootstrapPolEsBC and it will be overwritten)
		//LowerBounds: the matrix in which I store the results for the lower bound (It should be generated before running BootstrapPolEsBC and it will be overwritten)
		//ConfLev: the confidence level we want
		//numBoot: the number of bbotstrap sample
		//index: the point where you want to calculate gpsmd (can be "mean" or "p50" or "0" if 0 not only the common support is kept)
		//cutpoints: the number of discrete intervals of the dimensions of the treatment(if 0 not only the common support is kept)
		//LogTranslist: rowvector, each dimension includes the position in Dim of the treatment dimension we want to transform 
		
		i=numBoot+1
		while (--i>0){
			//I bootrstrap a vector
				Boot_Vec=sampleRPVec(outcome, rows(outcome))
			//I generate the bootstrap sample
				Boot_outcome=outcome[Boot_Vec,.]
				Boot_treatment=treatment[Boot_Vec,.]
				Boot_exogenous=exogenous[Boot_Vec,.]
			//I run PolEst an I pack the results in boot_results
				Boot_dta=PolEst(Shelvector, Boot_outcome, Boot_treatment, treatmentPlusgpsmd, restmodel, Boot_exogenous, Chosenpoints, index, cutpoints, LogTranslist)
				if (i<numBoot){
					Boot_Results=(Boot_Results \ ((1..(rows(Boot_dta)))', Boot_dta))
				}
				else if (i==numBoot){
					Boot_Results=((1..(rows(Boot_dta)))', Boot_dta)	
				}
		}
		//I calculate the lower and the upper bound by panel
		//The names for bootstrap, where possible follow Carpenter, James, e John Bithell. 2000. 
		//«Bootstrap confidence intervals: when, which, what? A practical guide for medical statisticians». Statistics in medicine 19 (9). Wiley Online Library: 1141–1164.
		//Boot_Results has the form (index, dim1,dim2,..., response, partial1, partial2...) therefore I sort by index, I loop over index (which is
		//over treatment points) and for each treatment point for each variable of interest (response, partial1, ...) I calculate the upper bound and the lower bound
		//I pack them in two matrixes upperres and lowerres of the form: (responseUP, partial1UP, partial2UP,...), (responseLow, partial1Low, partial2Low,...)
			N_i=rows(Chosenpoints)
		for (i=1;i<=N_i;i++){
			BootedsingleChosenpoints= select(Boot_Results, (Boot_Results[.,1]:==i))
				N_j=(cols(BootedsingleChosenpoints))
				N_j2=(cols(Chosenpoints)+2)
			for (j=N_j2; j<=N_j; j++){
				//(cols(Chosenpoints)+2) because index+cols(Chosenpoints) are out of the loop
				BootedsingleChosenpoints= sort(BootedsingleChosenpoints, j)
				//b=invnormal(p/B)
				b=invnormal(rows(select(BootedsingleChosenpoints[.,j], (BootedsingleChosenpoints[.,j]:<PrevEstB[i,(j-1)])))/numBoot)
				//PrevEstB has the form (dim1,dim2,..., response, partial1, partial2...) this is why j-1
				//upper 
				QH=round( ( (numBoot + 1) * normal(2*b- invnormal(ConfLev/2)) ) ,1)
				//lower
				QL=round( ( (numBoot + 1) * normal(2*b+ invnormal(ConfLev/2)) ) ,1)
				if (j> N_j2 ){
					//QH
					if (QH==.){
						upperpartial=(upperpartial,(.))
					}
					else if (QH>rows(BootedsingleChosenpoints)){
						upperpartial=(upperpartial,(BootedsingleChosenpoints[rows(BootedsingleChosenpoints), j]))
					}
					else if (QH==0){
						upperpartial=(upperpartial,(BootedsingleChosenpoints[1, j]))
					}
					else{
						upperpartial=(upperpartial, BootedsingleChosenpoints[QH,j])
					}
					//QL
					if (QL==.){
						lowerpartial=(lowerpartial, (.))
					}
					else if (QL>rows(BootedsingleChosenpoints)){
						lowerpartial=(lowerpartial, (BootedsingleChosenpoints[rows(BootedsingleChosenpoints), j]))
					}
					else if (QL==0){
						lowerpartial=(lowerpartial, (BootedsingleChosenpoints[1, j]))
					}
					else{
						lowerpartial=(lowerpartial, BootedsingleChosenpoints[QL,j])
					}
				}
				else if (j==N_j2){	
					//QH
					if (QH==.){
						upperpartial=(.)
					}
					else if (QH>rows(BootedsingleChosenpoints)){
						upperpartial=(BootedsingleChosenpoints[rows(BootedsingleChosenpoints), j])
					}
					else if (QH==0){
						upperpartial=(BootedsingleChosenpoints[1, j])
					}
					else{
						upperpartial=BootedsingleChosenpoints[QH,j]
					}
					//QL
					if (QL==.){
						lowerpartial=(.)
					}
					else if (QL>rows(BootedsingleChosenpoints)){
						lowerpartial=(BootedsingleChosenpoints[rows(BootedsingleChosenpoints), j])
					}
					else if (QL==0){
						lowerpartial=(BootedsingleChosenpoints[1, j])
					}
					else{
						lowerpartial=BootedsingleChosenpoints[QL,j]
					}
				}
			}
			if (i>1){
				upperres=(upperres \ upperpartial)
				lowerres=(lowerres \ lowerpartial)
			}
			else if (i==1){
				upperres=upperpartial
				lowerres=lowerpartial
			}
		}
		//I generate the matrixes with the results
		UpperBounds=(Chosenpoints, upperres)
		LowerBounds=(Chosenpoints, lowerres)
	}
//************
//NEW PART
//************
//struct PolEstTP_S
	struct PolEstTP_S
	{
		real matrix dtaResult, VarPE, VarPD
		//dtaResult: point estimates matrix of the form (dim1, dim2, ..., response, partial1, partial2...)
		//VarPE: Variance point estimates (dim1, dim2, ..., V_response)
		//VarPD: Variance derivative (dim1, dim2, ..., V_partial1, V_partial2...)
	}
	
//PolEstTP
	struct PolEstTP_S PolEstTP(real vector Shelvector, real matrix outcome, real matrix treatment, string scalar treatmentPlusgpsmd, string scalar restmodel, real matrix exogenous, real matrix Chosenpoints, string scalar index, real scalar cutpoints, real matrix LogTranslist)
	{
	struct PolEstTP_S scalar PETP
	real matrix DTAEstPol 
	real matrix TGPS
	struct LinRegS scalar LMPol
	real matrix Beta
	real matrix DTABasePred
	//real matrix TGPSPred not needed anymore because the pointer Ptodtader
	if ((cutpoints!=0)&(index!="0")){
		real matrix ComSup
	}
	real matrix response
	real matrix dtaResult
	real matrix panset
	real matrix nplus1
	real matrix vec1
	real scalar Nobs
	real matrix VarPE
	real matrix VarPD
	//for the loops I define:
	real scalar i, j, N_i , N_j //not needed in see belove "substituted for speed" but in calculating the variance of the "derivative"
	pointer(real vector) Ptodtader
	//N_i is the number of loops in the main loop N_j in the nested loop // N_j //not needed in see belove "substituted for speed" but in calculating the variance of the "derivative"
	//Shelvector: if the model is generated by IterativelyRESETFirstShot it is not obvius that dimensions and gdp are in the model. Shelvector
	//				is a vector of the position of the variables in (dimensions, gps) that are also in the model so we can generate the rigth matrix when we do the linear regression
	//outcome: matrix with the outcome (rows are the obs)
	//treatment: matrix with the obs for the treatment (rows are the obs)
	//treatmentPlusgpsmd: string with the name of the treatment dimension plus the name of gps
	//restmodel: string with the model but not the treatment and the gps alone
	//exogenous: exogenous variables (rows are the obs)
	//Chosenpoints: the matrix with the points chosen for the estimation (every row is a combination of the dimensions
	//index: the point where you want to calculate gpsmd (can be "mean" or "p50" or "0" if 0 not only the common support is kept)
	//cutpoints: the number of discrete intervals of the dimensions of the treatment(if 0 not only the common support is kept)
	//LogTranslist: rowvector, each dimension includes the position in Dim of the treatment dimension we want to transform 
	//I need to use pointer to sace the sevaral matrices I am going to use in the calculation of the variance of the "derivatives"
	//Some info otherwise I forget:
		//help m2_pointers##remarks13
		//Pointers to expressions
		//You can code
		//p = &(2+3)
		//and the result will be to create *p containing 5.  Mata creates a temporary variable to contain the evaluation of the expression and sets p to the address of the temporary variable.  That temporary variable will be freed when p
		//is freed or, before that, when the value of p is changed, just as tmp was freed in the example in the previous section.
		//When you code
		//p = &X[2,3]
		//the result is the same.  The expression is evaluated and the result of the expression stored in a temporary variable.  That is why subsequently coding *p=2 does not change X[2,3].  All *p=2 does is change the value of the
		//temporary variable.
		//Setting pointers equal to the value of expressions can be useful.  In the following code fragment, we create n 5 x 5 matrices for later use:
		//pvec = J(1, n, NULL)
		//for (i=1; i<=n; i++) pvec[i] = &(J(5, 5, .))

	//1. I calculate the gps
		DTAEstPol=(treatment, gpsmd(treatment, exogenous, LogTranslist))
	//2. I estimate the coefficients then for each Chosenpoint I calculate the effect and I store it in a matrix
		//2.1
		//if we do not care about common support
		if ((cutpoints==0)&(index=="0")){
			// I generate the variables needed as defined in the restmodel
			//and I add a column for the constant
			TGPS = (DTAEstPol[.,Shelvector] , MatFromString(DTAEstPol, treatmentPlusgpsmd, restmodel)) 
			// I estimate and save the coefficients
			LMPol=LinReg(outcome, TGPS) 
			Beta=LMPol.B
			//for each Chosenpoint I calculate the effect and I store it in a matrix
				N_i=rows(Chosenpoints)
				//I set the vector with pointers Ptodtader
				Ptodtader=J(N_i,1,NULL)
				//
			DTABasePred=(J(rows(DTAEstPol), 1, Chosenpoints[1,.] ), gpsmdGivenPoint(treatment, exogenous, Chosenpoints[1,.], LogTranslist)) 
			Ptodtader[1,1]=&(DTABasePred[.,Shelvector] , MatFromString(DTABasePred, treatmentPlusgpsmd, restmodel), J( rows(DTABasePred), 1, 1 ))
			response=mean((*Ptodtader[1,1])*Beta)
			//I also calculate the variance of the point estimate at the same time
			vec1=J(rows((*Ptodtader[1,1])), 1, 1) // for VarPE
			Nobs=rows((*Ptodtader[1,1])) // for VarPE
			VarPE=((Nobs^(-2):* Beta' ) * ((*Ptodtader[1,1])'*(*Ptodtader[1,1]) - Nobs^(-1):* (*Ptodtader[1,1])' * vec1 * vec1' * (*Ptodtader[1,1]))* Beta) // for VarPE
			for (i=2;i<=N_i; i++){
				DTABasePred=(J(rows(DTAEstPol), 1, Chosenpoints[i,.] ), gpsmdGivenPoint(treatment, exogenous, Chosenpoints[i,.], LogTranslist)) 
				Ptodtader[i,1]=&(DTABasePred[.,Shelvector] , MatFromString(DTABasePred, treatmentPlusgpsmd, restmodel), J( rows(DTABasePred), 1, 1 ))
				response=(response \ mean((*Ptodtader[i,1])*Beta))
				VarPE= (VarPE \ ((Nobs^(-2):* Beta' ) * ((*Ptodtader[i,1])'*(*Ptodtader[i,1]) - Nobs^(-1):* (*Ptodtader[i,1])' * vec1 * vec1' * (*Ptodtader[i,1]))* Beta)) // for VarPE
			}
		}
		//if we decide to keep only the common support
		else if ((cutpoints!=0)&(index!="0")){
			// I generate the variables needed as defined in the restmodel
			//and I add a column for the constant
			TGPS = (DTAEstPol[.,Shelvector], MatFromString(DTAEstPol, treatmentPlusgpsmd, restmodel))
			//I estimate the common support and drop the obs not in the common support
			ComSup = Com_supp_PE(treatment, exogenous, cutpoints, index , LogTranslist)
			TGPS = TGPS[selectindex(ComSup:==0),.]
			// I estimate and save the coefficients only with the common support observations
			LMPol=LinReg(outcome[selectindex(ComSup:==0),.], TGPS)
			Beta=LMPol.B
			//for each Chosenpoint I calculate the effect and I store it in a matrix
				N_i=rows(Chosenpoints)
				//I set the vector with pointers Ptodtader
				Ptodtader=J(N_i,1,NULL)
				//
			DTABasePred=(J(rows(DTAEstPol), 1, Chosenpoints[1,.] ), gpsmdGivenPoint(treatment, exogenous, Chosenpoints[1,.], LogTranslist)) 
			Ptodtader[1,1]=&(DTABasePred[.,Shelvector] , MatFromString(DTABasePred, treatmentPlusgpsmd, restmodel), J( rows(DTABasePred), 1, 1 ))
			(*Ptodtader[1,1])= (*Ptodtader[1,1])[selectindex(ComSup:==0),.]
			response=mean((*Ptodtader[1,1])*Beta)
			//I also calculate the variance of the point estimate at the same time
			vec1=J(rows((*Ptodtader[1,1])), 1, 1) // for VarPE
			Nobs=rows((*Ptodtader[1,1])) // for VarPE
			//VarPE2=((Nobs^(-2):* Beta' ) * ((*Ptodtader[1,1])'*(*Ptodtader[1,1]) - Nobs^(-1):* (*Ptodtader[1,1])' * vec1 * vec1' * (*Ptodtader[1,1]))* Beta) // for VarPE
			VarPE= Nobs^(-1) * quadcross(Beta, quadcross(quadvariance((*Ptodtader[1,1])), Beta)) // for VarPE
				//check start
					//assert(all(VarPE:> 0)) 
					//assert(all(VarPE:!= .))
				//check end
			for (i=2;i<=N_i; i++){
				DTABasePred=(J(rows(DTAEstPol), 1, Chosenpoints[i,.] ), gpsmdGivenPoint(treatment, exogenous, Chosenpoints[i,.], LogTranslist)) 
				Ptodtader[i,1]= &(DTABasePred[.,Shelvector] , MatFromString(DTABasePred, treatmentPlusgpsmd, restmodel), J( rows(DTABasePred), 1, 1 ))
				(*Ptodtader[i,1])= (*Ptodtader[i,1])[selectindex(ComSup:==0),.]
				response=(response \ mean((*Ptodtader[i,1])*Beta))
				//VarPE= (VarPE \ ((Nobs^(-2):* Beta' ) * ((*Ptodtader[i,1])'*(*Ptodtader[i,1]) - Nobs^(-1):* (*Ptodtader[i,1])' * vec1 * vec1' * (*Ptodtader[i,1]))* Beta)) // for VarPE
				VarPE= (VarPE \(Nobs^(-1) * quadcross(Beta, quadcross(quadvariance((*Ptodtader[i,1])), Beta))) )
				
				//check start
					//assert(all(VarPE:> 0)) 
					//assert(all(VarPE:!= .))
				//check end
			}
		}
		
	//4. I generate the partial derivatives (by simply creating a vector which is response n+1)
		dtaResult=((1..rows(Chosenpoints))',Chosenpoints, response) 
			N_i=(1+cols(Chosenpoints))
			N_j= rows(dtaResult)
			//I define VarPD as only . then I will substitute
			VarPD=(dtaResult[.,1], Chosenpoints,J(N_j,cols(Chosenpoints), .)) //the VarPD matrix has the columns ((1..rows(Chosenpoints))',Chosenpoints) in common with dtaResult
			//VarPD
		for (i=2;i<=N_i; i++){
			dtaResult=sort(dtaResult, (( select((2..(1+cols(Chosenpoints))), ((2..(1+cols(Chosenpoints))):!=i) ) ), i ) )
			panset= panelsetup(dtaResult, ( select((2..(1+cols(Chosenpoints))), ((2..(1+cols(Chosenpoints))):!=i) ) ) )
			nplus1=dtaResult[., (cols(dtaResult)- i + 2)]
			nplus1=(nplus1[2..rows(nplus1),.] \ 1)
			nplus1= nplus1-dtaResult[., (cols(dtaResult)- i + 2)]
			

			//I set the maximum value at 0 //substituted for speed
				//	N_j=(rows(panset)) //substituted for speed
				//for (j=1;j<=N_j; j++){ //substituted for speed
				//	nplus1[panset[j,2], 1]=0 //substituted for speed
				//} //substituted for speed
			nplus1[panset[.,2], 1]=J(rows(panset),1,0) //added for speed
			//I calculate the variance using the first vector (1..rows(Chosenpoints))' that has the same order of the loop for the point estimates and therefore 
			//it is an index for Ptodtader
			//N_j= rows(dtaResult)			
			
			VarPD=sort(VarPD, (( select((2..(1+cols(Chosenpoints))), ((2..(1+cols(Chosenpoints))):!=i) ) ), i ) ) //I have to sort otherwise every loop 

			//estimates are packed in a wrong order
			for (j=1;j<=N_j; j++){
				if (nplus1[j]!=0) {
				//C=Ptodtader[dtaResult[(i+1),1]]
				//K=Ptodtader[dtaResult[i,1]]
				//the derivative is considering the difference effectat(C)-effectat(K) 
				/*
					//previous way to generate variance and check // start
					//dtaResult[j,1] //for check
					//dtaResult[j+1,1] //for check
					//Ptodtader[dtaResult[(j+1),1]]==Ptodtader[dtaResult[j,1]] //for check
					//(*Ptodtader[dtaResult[(j+1),1]])==(*Ptodtader[dtaResult[j,1]]) //for check
					VarPD[j,i+cols(Chosenpoints)] = ((Nobs^(-2):* Beta' ) * ///
					( ((*Ptodtader[dtaResult[(j+1),1]])'*(*Ptodtader[dtaResult[(j+1),1]]) - Nobs^(-1):* (*Ptodtader[dtaResult[(j+1),1]])' * vec1 * vec1' * (*Ptodtader[dtaResult[(j+1),1]])) + ///
					((*Ptodtader[dtaResult[j,1]])'*(*Ptodtader[dtaResult[j,1]]) - Nobs^(-1):* (*Ptodtader[dtaResult[j,1]])' * vec1 * vec1' * (*Ptodtader[dtaResult[j,1]])) + ///
					((*Ptodtader[dtaResult[(j+1),1]])'*(*Ptodtader[dtaResult[j,1]]) - Nobs^(-1):* (*Ptodtader[dtaResult[(j+1),1]])' * vec1 * vec1' * (*Ptodtader[dtaResult[j,1]])) + ///
					((*Ptodtader[dtaResult[j,1]])'*(*Ptodtader[dtaResult[(j+1),1]]) - Nobs^(-1):* (*Ptodtader[dtaResult[j,1]])' * vec1 * vec1' * (*Ptodtader[dtaResult[(j+1),1]])) ) * Beta)
					
					all((*Ptodtader[j,1]):==(*Ptodtader[(j+1),1]))
				
					VarPD[j,i+cols(Chosenpoints)]
					//VarPD[j,i+cols(Chosenpoints)]-((Nobs^(-1) * quadcross(Beta, quadcross(quadvariance((*Ptodtader[dtaResult[(j+1),1]])-(*Ptodtader[dtaResult[(j),1]])), Beta))) )
					
					quadvariance((*Ptodtader[dtaResult[(j),1]]))
					quadvariance((*Ptodtader[dtaResult[(j+1),1]]))
					
					(Nobs^(-1):*(*Ptodtader[dtaResult[j,1]])'*(*Ptodtader[dtaResult[j,1]]) - Nobs^(-2):* (*Ptodtader[dtaResult[j,1]])' * vec1 * vec1' * (*Ptodtader[dtaResult[j,1]])) 
					(Nobs^(-1):*(*Ptodtader[dtaResult[(j+1),1]])'*(*Ptodtader[dtaResult[(j+1),1]]) - Nobs^(-2):* (*Ptodtader[dtaResult[(j+1),1]])' * vec1 * vec1' * (*Ptodtader[dtaResult[(j+1),1]])) 
					//previous way to generate variance and check // end
					*/
					
					VarPD[j,i+cols(Chosenpoints)]= ( Nobs^(-1) * quadcross(Beta, quadcross(quadvariance((*Ptodtader[dtaResult[(j+1),1]])-(*Ptodtader[dtaResult[(j),1]])), Beta)) )
					
					//check start
					//assert(VarPD[j,i+cols(Chosenpoints)]> 0 & VarPD[j,i+cols(Chosenpoints)]!=.)
					//check end
				}
			} 
			dtaResult=(dtaResult, nplus1)
		}
		dtaResult=sort(dtaResult, 1) 
		dtaResult=dtaResult[.,2..(cols(dtaResult))]
		//the matrix returned is (dim1, dim2, ..., response, partial1, partial2...)
		PETP.dtaResult=dtaResult 
		//I return the variance
		PETP.VarPE = VarPE //already sorted as dtaResult 
			//but before I order as I do for dtaResult (maybe non necessary) start *** 
			VarPD=sort(VarPD, 1) 
			VarPD=VarPD[.,2..(cols(VarPD))]
			//but before I order as I do for dtaResult (maybe non necessary) end ***
		PETP.VarPD= VarPD //I need to check however and modify if ((cutpoints==0)&(index=="0")){
		return(PETP)

	}
//************
//************
//BootstrapPolEsTP
	void BootstrapPolEsTP(real vector Shelvector, real matrix outcome, real matrix treatment, string scalar treatmentPlusgpsmd, string scalar restmodel, real matrix exogenous, real matrix Chosenpoints, struct PolEstTP_S PrevEstB, real scalar UpperBounds, real scalar LowerBounds,  real scalar ConfLev, real scalar numBoot, string scalar index, real scalar cutpoints, real matrix LogTranslist)
	{
		struct PolEstTP_S scalar PETP
		real matrix Boot_Vec
		real matrix Boot_outcome
		real matrix Boot_treatment
		real matrix Boot_exogenous
		real matrix Boot_dta
		real matrix Boot_Results
		real matrix BootedsingleChosenpoints
		real matrix upperres
		real matrix lowerres
		real matrix Real_dtaResult
		real matrix Real_se
		//for the loops I define:
		real scalar i, j, N_i, N_j
		real scalar tlow
		real scalar thigh
		real matrix bottvecpar
		//N_i is the number of loops in the main loop N_j in the nested loop  
		//Shelvector: if the model is generated by IterativelyRESETFirstShot it is not obvius that dimensions and gdp are in the model. Shelvector
		//				is a vector of the position of the variables in (dimensions, gps) that are also in the model so we can generate the rigth matrix when we do the linear regression
		//outcome: matrix with the outcome (rows are the obs)
		//treatment: matrix with the obs for the treatment (rows are the obs)
		//treatmentPlusgpsmd: string with the name of the treatment dimension plus the name of gps
		//restmodel: string with the model but not the treatment and the gps alone
		//exogenous: exogenous variables (rows are the obs)
		//Chosenpoints: the matrix with the points chosen for the estimation (every row is a combination of the dimensions
		//PrevEstB: the not boostrapped estimation done in a previous run of PolEstTP
		//UpperBounds: the matrix in which I store the results for the upper bound (It should be generated before running BootstrapPolEsTP and it will be overwritten)
		//LowerBounds: the matrix in which I store the results for the lower bound (It should be generated before running BootstrapPolEsTP and it will be overwritten)
		//ConfLev: the confidence level we want
		//numBoot: the number of bbotstrap sample
		//index: the point where you want to calculate gpsmd (can be "mean" or "p50" or "0" if 0 not only the common support is kept)
		//cutpoints: the number of discrete intervals of the dimensions of the treatment(if 0 not only the common support is kept)
		//LogTranslist: rowvector, each dimension includes the position in Dim of the treatment dimension we want to transform 
		
		//I define the various matrices in PrevEstB removing the columns with the chosenpoints so that it is easier to do the things (when needed I also take the sqrt)
		Real_dtaResult = PrevEstB.dtaResult[.,(cols(Chosenpoints)+1 ..cols(PrevEstB.dtaResult))]
		//I also put together the variances because I do not need then dinstinct
		Real_se = (sqrt(PrevEstB.VarPE) ,  sqrt(PrevEstB.VarPD[.,(cols(Chosenpoints)+1 ..cols(PrevEstB.VarPD))]))
		
		//every iteration I calculate the t statistics for each Chosenpoint
		//then make an index for chosenpoints so that I can identify the different Chosenpoint ((1..(rows(Chosenpoints)))'
		//I pack the bootstrap estimates
		
		//I bootrstrap a vector (first iteration)
			Boot_Vec=sampleRPVec(outcome, rows(outcome))
		//I generate the bootstrap sample
			Boot_outcome=outcome[Boot_Vec,.]
			Boot_treatment=treatment[Boot_Vec,.]
			Boot_exogenous=exogenous[Boot_Vec,.]
		//I run PolEstTP an I pack the results in boot_results
			PETP=PolEstTP(Shelvector, Boot_outcome, Boot_treatment, treatmentPlusgpsmd, restmodel, Boot_exogenous, Chosenpoints, index, cutpoints, LogTranslist) //it seems that you need to make an assignment before selecting an object within the structure
			Boot_dta=(PETP.dtaResult[.,(cols(Chosenpoints)+1 ..cols(PrevEstB.dtaResult))] :- Real_dtaResult) :/ (sqrt(PETP.VarPE), sqrt(PETP.VarPD[.,(cols(Chosenpoints)+1 ..cols(PETP.VarPD))]))
		
			Boot_Results=((1..(rows(Chosenpoints)))', Boot_dta)	
			
		i=numBoot
		while (--i>0){
			//I bootrstrap a vector (remaining iterations)
				Boot_Vec=sampleRPVec(outcome, rows(outcome))
			//I generate the bootstrap sample
				Boot_outcome=outcome[Boot_Vec,.]
				Boot_treatment=treatment[Boot_Vec,.]
				Boot_exogenous=exogenous[Boot_Vec,.]
			//I run PolEstTP an I pack the results in boot_results
				PETP=PolEstTP(Shelvector, Boot_outcome, Boot_treatment, treatmentPlusgpsmd, restmodel, Boot_exogenous, Chosenpoints, index, cutpoints, LogTranslist) //it seems that you need to make an assignment before selecting an object within the structure
				Boot_dta=(PETP.dtaResult[.,(cols(Chosenpoints)+1 ..cols(PrevEstB.dtaResult))] :- Real_dtaResult) :/ (sqrt(PETP.VarPE), sqrt(PETP.VarPD[.,(cols(Chosenpoints)+1 ..cols(PETP.VarPD))]))
				
				Boot_Results=(Boot_Results \ ((1..(rows(Chosenpoints)))', Boot_dta))
		}
		printf("bootstrappato tutto")
		//Now I need to select foreach chosenpoint the alpha/2 and 1-alpha/2 percentiles
		//then I am ready to calculate confidence intervals
		//I define the two matrixes with the results. Then I will replace when needed
		upperres= J(rows(Chosenpoints), cols(Real_dtaResult),.)
		lowerres= J(rows(Chosenpoints), cols(Real_dtaResult),.)
		N_i=rows(Chosenpoints)
		for (i=1;i<=N_i;i++){
			BootedsingleChosenpoints= select(Boot_Results, (Boot_Results[.,1]:==i))
				N_j=(cols(BootedsingleChosenpoints))
				for (j=2; j<=N_j; j++){
					//starting from 2 because at column one we have the index
					if (BootedsingleChosenpoints[1,j]!=.) { //I ve read that moremata does not manage missings value but the partial derivative for the mazimum are missing
						bottvecpar=BootedsingleChosenpoints[.,j] 

						//I generate talpha/2 and t(1-alpha/2)
						thigh= mm_quantile(bottvecpar, 1, (1-(ConfLev/2))) // mm_quantile from moremata
						tlow= mm_quantile(bottvecpar, 1, (ConfLev/2)) 
						//I calculate the lower and upper bound
						lowerres[i,j-1]=Real_dtaResult[i,j-1]- thigh * Real_se[i, j-1]
						upperres[i,j-1]=Real_dtaResult[i,j-1]- tlow * Real_se[i, j-1]
					}
				}
			}
		
		UpperBounds=(Chosenpoints, upperres)
		LowerBounds=(Chosenpoints, lowerres)	
		
	}
//************
//************
//SimpleConf
	void SimpleConf(real vector Shelvector, real matrix outcome, real matrix treatment, string scalar treatmentPlusgpsmd, string scalar restmodel, real matrix exogenous, real matrix Chosenpoints, struct PolEstTP_S PrevEstB, real scalar UpperBounds, real scalar LowerBounds,  real scalar ConfLev, real scalar numBoot, string scalar index, real scalar cutpoints, real matrix LogTranslist)
	{
		struct PolEstTP_S scalar PETP
		real matrix upperres
		real matrix lowerres
		real matrix Real_dtaResult
		real matrix Real_se
		//for the loops I define:
		real scalar i, j, N_i, N_j
		real scalar tlow
		real scalar thigh
		//N_i is the number of loops in the main loop N_j in the nested loop  
		//Shelvector: if the model is generated by IterativelyRESETFirstShot it is not obvius that dimensions and gdp are in the model. Shelvector
		//				is a vector of the position of the variables in (dimensions, gps) that are also in the model so we can generate the rigth matrix when we do the linear regression
		//outcome: matrix with the outcome (rows are the obs)
		//treatment: matrix with the obs for the treatment (rows are the obs)
		//treatmentPlusgpsmd: string with the name of the treatment dimension plus the name of gps
		//restmodel: string with the model but not the treatment and the gps alone
		//exogenous: exogenous variables (rows are the obs)
		//Chosenpoints: the matrix with the points chosen for the estimation (every row is a combination of the dimensions
		//PrevEstB: the not boostrapped estimation done in a previous run of PolEstTP
		//UpperBounds: the matrix in which I store the results for the upper bound (It should be generated before running BootstrapPolEsTP and it will be overwritten)
		//LowerBounds: the matrix in which I store the results for the lower bound (It should be generated before running BootstrapPolEsTP and it will be overwritten)
		//ConfLev: the confidence level we want
		//numBoot: the number of bbotstrap sample
		//index: the point where you want to calculate gpsmd (can be "mean" or "p50" or "0" if 0 not only the common support is kept)
		//cutpoints: the number of discrete intervals of the dimensions of the treatment(if 0 not only the common support is kept)
		//LogTranslist: rowvector, each dimension includes the position in Dim of the treatment dimension we want to transform 
		
		//I define the various matrices in PrevEstB removing the columns with the chosenpoints so that it is easier to do the things (when needed I also take the sqrt)
		Real_dtaResult = PrevEstB.dtaResult[.,(cols(Chosenpoints)+1 ..cols(PrevEstB.dtaResult))]
		//I also put together the variances because I do not need then dinstinct
		Real_se = (sqrt(PrevEstB.VarPE) ,  sqrt(PrevEstB.VarPD[.,(cols(Chosenpoints)+1 ..cols(PrevEstB.VarPD))]))
		
		//then I am ready to calculate confidence intervals
		//I define the two matrixes with the results. Then I will replace when needed
		upperres= J(rows(Chosenpoints), cols(Real_dtaResult),.)
		lowerres= J(rows(Chosenpoints), cols(Real_dtaResult),.)
		N_i=rows(Chosenpoints)
		for (i=1;i<=N_i;i++){
				N_j=(cols(Real_dtaResult))
				for (j=1; j<=N_j; j++){
					//starting from 2 because at column one we have the index
					if (Real_dtaResult[i,j]!=.) { //I ve read that moremata does not manage missings value but the partial derivative for the mazimum are missing
						//I generate talpha/2 and t(1-alpha/2)
						thigh= invnormal((1-(ConfLev/2))) 
						tlow= invnormal((ConfLev/2))
						//I calculate the lower and upper bound
						lowerres[i,j]=Real_dtaResult[i,j]- thigh * Real_se[i, j]
						upperres[i,j]=Real_dtaResult[i,j]- tlow * Real_se[i, j]
						Real_dtaResult[i,j]
						lowerres[i,j]
						upperres[i,j]
						Real_se[i, j]
						
					}
				}
			}
	Real_se
		UpperBounds=(Chosenpoints, upperres)
		LowerBounds=(Chosenpoints, lowerres)	

		UpperBounds >LowerBounds
	}
end
*--------------------------------------------------------------------------------
*+++++++++++++++++++++++++++++++MATA END++++++++++++++++++++++++++++++++++++++
*--------------------------------------------------------------------------------
*+++++++++++++++++++++++++++++++gpsmdpolest END++++++++++++++++++++++++++++++++++++++
*--------------------------------------------------------------------------------



********************************************************************************
********************************************************************************
*AUXILIARY PROGRAMS
*1. GenVarFromAString
********************************************************************************
********************************************************************************
********************************************************************************
********************************************************************************
*1. GenVarFromAString
********************************************************************************
/*The program generate the variables in model which are not in vartobeexcluded
two macros are returned 
a. ListGenVar: the list of generated variables
b. ComplModel: the list of all the variable in the model (the union between vartobeexcluded ListGenVar)
c. modelwithoutplus: what there is in the string model but without plus
*/
		program define GenVarFromAString, rclass
			version 14.2
			#delimit ;
			syntax, 
			model(string)
			[
			vartobeexcluded(varlist) 
			removeplus(string)
			]
			;
			#delimit cr	
			// model(string) a string of the form "T1 + T2 + gps + T1*gps + T2*gps + T1^(2) + T2^2 + (gps^2) + ((T1*gps)^(2)) + (T2*gps)^2 ln(T1) + ln(T1)^2 + ln(T1)*gps" 
			// or of the form "T1  T2  gps  T1*gps  T2*gps  T1^(2)  T2^2  (gps^2)  ((T1*gps)^(2))  (T2*gps)^2 "
			// vartobeexcluded(varlist) the list of the variable that we do not need to generate but that are present in the string with the model
			// removeplus(string): if the string is of the form "T1 + T2 + gps + T1*gps + T2*gps + T1^(2) + T2^2 + (gps^2) + ((T1*gps)^(2)) + (T2*gps)^2 ln(T1) + ln(T1)^2 + ln(T1)*gps" 
			// must be equal to Y
			////for different power in different element of the interaction (this kind of interaction must be of the form (a^2)*(b^3) or (a^1)*b^3 no a*b^3 otherwise a*b^3 becomes (a*b)^3)
			*I generate the model
				if "`removeplus'"=="Y"{
				*I create from `model' a list with the variables in the model
					local model=subinstr("`model'"," ","",.)
					local model=subinstr("`model'","+"," ",.)
				}
				*I generate each variable needed (which is all but the variable in vartobeexcluded) and I store the names in the macro ListGenVar
					local modelClean: list model - vartobeexcluded //I remove the vartobeexcluded from the list of variable I want to generate (if vartobeexcluded is empty then modelClean is equal to model)
					if "`modelClean'"!="" {
						local ListGenVar ""
						foreach i of local modelClean {
							display "`i'" //check
							*a. I select the power 1
							if `=regexm("`i'","(\^)(\()?(\-)?([0-9])+(\))?(\))?$")'!=1 {
								*a.1 i select the interaction
								if `=regexm("`i'","(.)+(\*)(.)+")'==1 {
									*I generate the variable for the interaction starting with I_
									local name "`=subinstr("`i'","ln(","LN(",.)'" //needed since if there is the log a variable cannot be named with "(" ")" inside
									local name "`=subinstr("`name'","(","",.)'" //needed since if there is the log a variable cannot be named with "(" ")" inside
									local name "`=subinstr("`name'",")","",.)'" //needed since if there is the log a variable cannot be named with "(" ")" inside
									tokenize "`=subinstr("`name'","*"," ",.)'" 
									gen double `=strtoname("__I_`1'_`2'")'= `i'
								local ListGenVar="`ListGenVar'" + " " + "`=strtoname("__I_`1'_`2'")'"
								}
								*a.1 I select the only log
								else if `=regexm("`i'","(.)+(\*)(.)+")'!=1 {
									local name "`=subinstr("`i'","ln(","",.)'" //needed since if there is the log a variable cannot be named with "(" ")" inside
									local name "`=subinstr("`name'",")","",.)'"
									gen double `=strtoname("__LN_`name'")'= `i'
								local ListGenVar="`ListGenVar'" + " " + "`=strtoname("__LN_`name'")'"
								}
							}
							*b. I select all the power higher than 1
							else if `=regexm("`i'","(\^)(\()?([0-9])+(\))?(\))?$")'==1 {
								*b.1 i select the interaction
								if `=regexm("`i'","(.)+(\*)(.)+")'==1 {
									local name "`=subinstr("`i'","*"," ",.)'"  
									local name "`=subinstr("`name'","ln(","LN(",.)'"
									local name "`=subinstr("`name'","^"," ",.)'"  
									local name "`=subinstr("`name'","(","",.)'" 
									local name "`=subinstr("`name'",")","",.)'" 
									if `:list sizeof name'==3 {
										tokenize "`name'"
										gen double `=strtoname("__P_`3'_I_`1'_`2'")'= `i'
										local ListGenVar="`ListGenVar'" + " " + "`=strtoname("__P_`3'_I_`1'_`2'")'"
									}
									else if `:list sizeof name'==4 {
										tokenize "`name'"
										gen double `=strtoname("__P_`2'_`1'_I_P_`4'_`3'")'= `i'
										local ListGenVar="`ListGenVar'" + " " + "`=strtoname("__P_`2'_`1'_I_P_`4'_`3'")'"
									}
								}
								*b.2 I select the only power 
								else if `=regexm("`i'","(.)+(\*)(.)+")'!=1 { 
									local name "`=subinstr("`i'","^"," ",.)'"  
									local name "`=subinstr("`name'","ln(","LN(",.)'"
									local name "`=subinstr("`name'","(","",.)'" 
									local name "`=subinstr("`name'",")","",.)'" 
									tokenize "`name'"
									gen double `=strtoname("__P_`2'_`1'")'= `i'
								local ListGenVar="`ListGenVar'" + " " + "`=strtoname("__P_`2'_`1'")'"
								}
							}
							*c.I select the power lower than 0
							else if `=regexm("`i'","(\^)(\()?(\-)([0-9])+(\))?(\))?$")'==1 {
								*b.1 i select the interaction
								if `=regexm("`i'","(.)+(\*)(.)+")'==1 {
									local name "`=subinstr("`i'","*"," ",.)'"  
									local name "`=subinstr("`name'","ln(","LN(",.)'"
									local name "`=subinstr("`name'","^"," ",.)'"  
									local name "`=subinstr("`name'","(","",.)'" 
									local name "`=subinstr("`name'",")","",.)'" 
									local name "`=subinstr("`name'","-","m",.)'" //added for negtive powers
									if `:list sizeof name'==3 {
										tokenize "`name'"
										gen double `=strtoname("__P_`3'_I_`1'_`2'")'= `i'
										local ListGenVar="`ListGenVar'" + " " + "`=strtoname("__P_`3'_I_`1'_`2'")'"
									}
									else if `:list sizeof name'==4 {
										tokenize "`name'"
										gen double `=strtoname("__P_`2'_`1'_I_P_`4'_`3'")'= `i'
										local ListGenVar="`ListGenVar'" + " " + "`=strtoname("__P_`2'_`1'_I_P_`4'_`3'")'"
									}
								}
								*b.2 I select the only power 
								else if `=regexm("`i'","(.)+(\*)(.)+")'!=1 { 
									local name "`=subinstr("`i'","^"," ",.)'"  
									local name "`=subinstr("`name'","ln(","LN(",.)'"
									local name "`=subinstr("`name'","(","",.)'" 
									local name "`=subinstr("`name'",")","",.)'" 
									local name "`=subinstr("`name'","-","m",.)'" //added for negtive powers
									tokenize "`name'"
									gen double `=strtoname("__P_`2'_`1'")'= `i'
								local ListGenVar="`ListGenVar'" + " " + "`=strtoname("__P_`2'_`1'")'"
								}
							} 
						}
					}
				*I return the list of generated variable
				return local ListGenVar "`ListGenVar'"
				return local ComplModel "`="`vartobeexcluded'" + "`ListGenVar'"'" //we do not need a space since in the loop in the the first iteration ListGenVar is empty
				return local modelwithoutplus "`model'"
				return local ListGenVarAsModel "`modelClean'"
		***
		end
		
