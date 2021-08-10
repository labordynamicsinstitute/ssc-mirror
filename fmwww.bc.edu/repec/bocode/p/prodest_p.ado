*! version 1.0.1 27Sep2016
*! version 1.0.2 05Jun2017 major changes in the code and how the whole routine works, added exponential and parameters options
*! version 1.0.3 14Mar2018 add the OMEGA option in order to yield the estimates of omega according to De Loecker & Warzynski (AER, 2012)
*! version 1.1.0 19May2020 add the markups option (+ inputvar() + correction)
*! authors: Gabriele Rovigatti, University of Chicago Booth School of Business & EIEF, Rome, Italy. mailto: gabriele.rovigatti@gmail.com
*!          Vincenzo Mollisi, Bolzano University, Bolzano, Italy & Tor Vergata University, Rome, Italy. mailto: vincenzo.mollisi@gmail.com

/***************************************************************************
** Stata program for prodest Postestimation
**
** Programmed by: Gabriele Rovigatti

**************************************************************************/

cap program drop prodest_p
program define prodest_p, sortpreserve eclass

	version 10.0

	syntax [anything] [if] [in] [, 			   ///
		RESIDuals 				   /// 
		EXPonential 			   ///
		PARameters					///
		OMEGA						///
		MARKups						///
		INPUTvar(varlist numeric min=1 max=1)		///
		CORRected					///
		]

	marksample touse 	// this is not e(sample)
	
	tempvar esample
	qui gen byte `esample' = e(sample)
	
	loc varlist `anything'
	
	loc mod = "`e(PFtype)'"
	loc fsres = "`e(FSres)'"
	loc free = "`e(free)'"
	if "`e(model)'" == "grossoutput"{
		loc proxy = "`e(proxy)'"
		loc free "`free' `proxy'"
	}
	loc state = "`e(state)'"
	
	************************************************************************************************
			********************* PART 1: MARKUPS ESTIMATION ************************
	************************************************************************************************
	if !mi("`markups'"){ 
		/* check for correct usage of options */
		if !mi("`corrected'") & mi("`fsres'"){ // correction à la DLW only available with first-stage residuals
			di as error "Markup correction requires launching prodest with 'fsresiduals(<fsvar>)' option"
			exit 198	
		}
		if !`:list inputvar in free'{ // check whether the input variable specified is in the list of free variables
			di as error "<inputvar> should be either a free or a proxy variables used in the estimation"
			exit 198
		}
		cap confirm var `varlist' // if the variable already exists
		if !_rc{
			di as error "`varlist' already exists"
			exit 198
		}
		if mi("`varlist'"){ // check the outcome variable: if it is missing, use a pre-specified _mkup[number] variable
			loc c = 0
			while (1){
				loc ++c
				loc varlist _mkup`c'
				cap confirm var `varlist'
				if (_rc != 0) continue, break
			} 
			di as error "You should specify <newvarname> to store the estimated markups. They will be stored in `varlist' now"
		}
		
		********* ROUTINE START **************
		tempvar theta alpha
		/* generate the input share, either "raw" or corrected by the first-stage residuals as suggested by DLW */
		loc lhs `e(depvar)' // this is the output - in logs
		qui g `alpha' = exp(`inputvar') / exp(`lhs')
		if !mi("`corrected'"){
			qui replace `alpha' = `alpha' * exp(`fsres')
		}
		/* Generate the elasticity parameter - either the estimated beta (Cobb-Douglas) or a function of it (Translog) */ 
		if "`mod'" == "Cobb-Douglas"{ /* PART I: COBB-DOUGLAS */
			qui g `theta' = _b[`inputvar'] // 
		}
		else { /* PART II: TRANSLOG */
			tempname beta
			mat `beta' = e(b) // extract the estimated betas

			loc controls = "`e(controls)'"
			loc transvars `free' `state' `controls'
			loc translogNum: word count `transvars'
			
			loc n = 1 // regenerate the variables used in the routine in order to fit the values
			foreach x of local transvars{
				tempvar var_`n' betavar_`n' 
				qui g `var_`n'' = `x'
				loc ++n
			}
			forv i = 1/`translogNum'{
				forv j = `i'/`translogNum'{ 
					tempvar var_`i'`j' beta_`i'`j'
					cap g `var_`i'`j'' = (`var_`i'' * `var_`j'')
					cap g `beta_`i'`j'' = `beta'[1,`n']
					loc ++n
				}
			}
			loc varnum:  word count `free' `state' 
			loc inputpos: list posof "`inputvar'" in free // this is the number of the input variable within the free vars
			forv j = 1/`varnum'{
				if `inputpos' != `j'{ /* generate the cross variables part only  */
					cap confirm variable `beta_`inputpos'`j''
					if !_rc{
						loc remainder `remainder' + (`beta_`inputpos'`j'' * `var_`j'') 
					}
					else{
						loc remainder `remainder' + (`beta_`j'`inputpos'' * `var_`j'')
					}
				}
			}
			qui gen `theta' = `beta'[1,`inputpos'] + (2 * `beta_`inputpos'`inputpos'' * `var_`inputpos'') `remainder' // the elasticity for translog is defined as beta_Wtranslog = beta_w + 2*beta_ww * W + beta_wx * X, and here we use the previously generated variables and weight them by the ith variable
		}
		/* Compute the Markups */
		g `varlist' = `theta' / `alpha' `if' // compute the markups, and save the relative variable
	}
	else{ 
	************************************************************************************************
			**************** PART 2: TFP/RESIDUALS/PARAMETERS ESTIMATION *************
	************************************************************************************************
		/* check for options in launching command */
		if ( mi("`residuals'") & mi("`exponential'") & mi("`parameters'") & mi("`omega'") & mi("`varlist'")){
			di as error "You must specify <newvarname>, RESIDuals, EXPonential, PARameters or OMEGA"
			exit 198
		}
		/* check for correct usage of options */
		if ( (!mi("`residuals'") | !mi("`exponential'") | !mi("`omega'")) & !mi("`parameters'")){
			di as error "the 'parameters' option cannot be used with other options"
			exit 198
		}
		if !mi("`omega'") & mi("`fsres'"){
			di as error "the 'omega' option can only be used after launching prodest with 'fsresiduals(newvar)' option"
			exit 198	
		}
		if mi("`parameters'") & mi("`varlist'"){
			di as error "You must specify newvarname to store results"
			exit 198
		}
		/* straight predict: yields yhat */
		if (mi("`residuals'") & mi("`exponential'") & mi("`parameters'") & mi("`omega'")){ 
			loc straightpredict "y"
		}
		
		if "`mod'" == "Cobb-Douglas"{ /* PART I: COBB-DOUGLAS */
			if (mi("`parameters'")) {
				tempname beta
				mat `beta' = e(b)
				tempvar rhs 
				mat score double `rhs' = `beta'
				loc lhs `e(depvar)'
				if !mi("`exponential'"){
					qui gen `varlist' = exp(`lhs' - `rhs') `if'
				}
				else if !mi("`omega'"){ /* generate estimates of omega like:  \hat{W} = \hat{phi} - f(k,l,\hat{beta}) */
					qui gen `varlist' = `lhs' - `fsres' - `rhs' `if'
				}
				else if "`straightpredict'" == "y"{
					qui gen `varlist' = `rhs'
				}
				else{ /* residuals */
					qui gen `varlist' = `lhs' - `rhs' `if'
				}
			}
			else{ /* 'parameters' with cobb-douglas PF yields the results' table */
				_coef_table, level($S_level)
			}
		}
		else { /* PART II: TRANSLOG */
			loc lhs `e(depvar)'
			loc free = "`e(free)'"
			if "`e(model)'" == "grossoutput"{
				loc proxy = "`e(proxy)'"
				loc free "`free' `proxy'"
			}
			loc state = "`e(state)'"
			loc controls = "`e(controls)'"
			loc transvars `free' `state' `controls'
			loc translogNum: word count `transvars'
			
			tempname beta
			mat `beta' = e(b) // extract the estimated betas
			
			loc n = 1 // regenerate the variables used in the routine in order to fit the values
			foreach x of local transvars{
				tempvar var_`n' betavar_`n' 
				*qui g `betavar_`n'' = `beta'[1,`n'] * `x'
				qui g `betavar_`n'' = _b[`x'] * `x'
				qui g `var_`n'' = `x'
				loc fit `fit' - `betavar_`n''
				loc ++n
			}
			forv i = 1/`translogNum'{
				forv j = `i'/`translogNum'{ /* `i' */
					tempvar var_`i'`j' betavar_`i'`j' beta_`i'`j'
					cap g `betavar_`i'`j'' = `beta'[1,`n'] * (`var_`i'' * `var_`j'')
					cap g `var_`i'`j'' = (`var_`i'' * `var_`j'')
					cap g `beta_`i'`j'' = `beta'[1,`n']
					loc fit `fit' - `betavar_`i'`j''
					loc ++n
				}
			}
			if !mi("`exponential'") {
				qui g `varlist' = exp(`lhs' `fit') `if' // here generate the predicted residuals -- exponential
			}
			else if !mi("`omega'"){ /* generate estimates of omega like:  \hat{W} = \hat{phi} - f(k,l,\hat{beta}) */
				qui gen `varlist' = `lhs' - `fsres' `fit' `if'
			}
			else if "`straightpredict'" == "y"{
				qui gen `varlist' = -(`fit')
			}
			else if !mi("`residuals'"){
				qui g `varlist' = `lhs' `fit' `if' // here generate the predicted residuals
			}
			else{ /* in case of 'parameters' option */
				loc freenum: word count `free'
				loc statenum: word count `state'
				loc totnum:  word count `free' `state' 
				loc n = 0
				forv i = 1/`totnum'{
					forv j = 1/`totnum'{
						loc ++n
						if `i' != `j'{ /* generate the cross variables part only  */
							cap confirm variable `betavar_`i'`j''
							if !_rc{
								loc remainder `remainder' + `beta_`i'`j'' * `var_`j'' /* *`var_`i'' */
							}
							else{
								loc remainder `remainder' + `beta_`j'`i'' * `var_`j''
							}
						}
					}
					tempvar betafit_`i' // the parameter for translog is defined as beta_Wtranslog = beta_w + 2*beta_ww * W + beta_wx * X 
					qui gen `betafit_`i'' = `beta'[1,`i'] + 2 * `beta_`i'`i'' * `var_`i'' `remainder' // here we use the previously generated variables and weight them by the ith variable -- *`var_`i''
					qui su `betafit_`i'', meanonly
					loc beta_`i': di %6.3f `r(mean)'
					if !mi("`varlist'"){ /* if the user specified the varlist to store the elasticities, generate the variable(s) */
						loc newvarname: "`varlist'_`i'" 
						qui g `newvarname' = `betafit_`i''
					}
					loc remainder ""
				}
				di _n _n
				di as text "{hline 75}"
				di as text "Translog elasticity estimates" _continue
				di _col(49) "prodest postestimation"
				di as text "{hline 75}"
				di as text "Elasticity Parameter" _continue
				di _col(49) "Value"
				di as text "{hline 75}"
				loc i = 1
				foreach var of varlist `free' `state'{
					di as text "beta_`var'" _continue
					di _col(49) "`beta_`i''"
					eret loc beta_`var' "`beta_`i''"
					loc ++i
				}
				di as text "{hline 75}"
			}
		}
	}
end
