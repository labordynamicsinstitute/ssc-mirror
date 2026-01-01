*! command: gpsMD; version: 7 02 October 2024
*! Enrico Cristofoletti
*gpsmd +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
/*
History
*gpsMD6 is the same as gpsMD6 but it is converted to a r-class command (before e-class but it was the wrong class)
*version 6 is the same as 5.1 but it is not beta anymore furthermore instead of 5000 obs as threshold for loop I put 11000
*5.1 is the same as 5 but it manages large datasets. 
*/
***************************	
program define gpsmd, rclass
	version 14.2
	*
	#delimit ;
	syntax  varlist(min=2) , 
	exogenous(varlist)
	gpsmd(string) 
	[chosenpoint(string)
	ln(varlist)]
	;
	#delimit cr	
	/*
	varlist: the dimensions of the treatment
	exogenous: the model for the reduced equation estimation
	gpsmd: the name for the variable with the propensity score
	[chosenpoint(string)] the name of the stata vector with the point at which we want to calculate the propensity score 
	ln(numlist integer): the treatment dimensions we want to take the log transform
	*/
	confirm new variable `gpsmd'
	capture: assert `: word count `ln''<= `: word count `varlist'' 
	if _rc!=0 {
		display as error "You are trying to transform a number of dimensions higher than the total number of dimensions "
		error
	}
	/*if there are some trasformation, in the first stage, I need a list with the transformed dimension instead of simply the dimensions
	Moreover I need to generate the transformations : */
	local listvarFS "`varlist'"
	local LNVARGEN ""
	if "`ln'"!=""{
		foreach i of local ln{
			capture: assert strmatch("`varlist'","*`i'*")==1
			if _rc!=0 {
				display as error "You are trying to transform a dimension which has not been previously stated"
				error
			}
			gen double LN_`i'=ln(`i')
			local listvarFS= subinstr("`listvarFS'", "`i'", "LN_`i'",.)
			local LNVARGEN= "LN_`i'" + " " + "`LNVARGEN'"
		}
	}
	*+I remove r-class objects
		return clear
	*-MACRO AND TEMP
		*macro
			*gpsmdNumofDim=M
				local gpsmdNumofDim: word count `listvarFS'
				local gpsmdresiduals ""
			*I generate the names for the rows and column of var covar matrix
			local namesVarCov ""
					foreach element of local listvarFS{
						local namesVarCov="`namesVarCov'" + " " + "`element'" + "Res" 
					}
		*temporary vars and names
			*I generate the temporary names for the var covar matrix and for the GPS for the demeaned treatments
				tempname gpsmdVarCovar gpsmdvec gpsmddemeanedTreat
			/*if chosenpoint different from void i define a tempname for the matrix with residuals and then 
			at b.1 in the loop I will define some tempname for the residuals in each dimension of the treatment
			with the form Predicted`Dim' */
				if "`chosenpoint'"!=""{
					tempname PredMat
				}
	*-CALCULATING THE PROPENSITY SCORE
	*a)
	if "`chosenpoint'"==""{
		*a.1.I run the regression and predict the residuals
				foreach gpsmddimen of local listvarFS {
					*I generate a temporary name for the variables of predicted residuals
						tempvar gpsmdresid`gpsmddimen' 
					*I run the regression
							*some display start
							display _newline "****************" _newline "The regression for dimension: `gpsmddimen'" _newline "****************"
							*some display end
						reg `gpsmddimen' `exogenous' 
					*I predict the residuals
						predict double `gpsmdresid`gpsmddimen'', residuals 
					*I update the local macro with the list of the name of the variables of residuals
						local gpsmdresiduals= "`gpsmdresiduals'" + " " + "`gpsmdresid`gpsmddimen''"
					*I save a an r-class obgect the command
					local cmdline`gpsmddimen'=e(cmdline)
				}
		*a.2.I generate the Variance covariance matrix of the residuals
			qui: correlate `gpsmdresiduals', covariance
			matrix `gpsmdVarCovar'=r(C)
			*I change tha name of the columns and rows
				matrix rownames `gpsmdVarCovar'= `namesVarCov'
				matrix colnames `gpsmdVarCovar'= `namesVarCov'
					*some display start
					display _newline "****************" _newline "The Variance Covariance Matrix:" _newline "****************" 
					matlist `gpsmdVarCovar' 
					*some display end
		*a.3. I generate the vector of propensity score
			*I take the vectors of residuals and I make them a matrix Nxk 
			***mkmat `gpsmdresiduals', matrix(`gpsmddemeanedTreat')
			*I calculate the propensity score
			***mata: `gpsmddemeanedTreat'=st_matrix("`gpsmddemeanedTreat'")
				tempname idx
				mata: `gpsmddemeanedTreat'=st_data(., "`gpsmdresiduals'")
				mata: `gpsmdVarCovar'=st_matrix("`gpsmdVarCovar'")
				*mata: quadcross((`gpsmddemeanedTreat')',(invsym( `gpsmdVarCovar' )))
				mata: `gpsmdvec' = (1/(((2* pi())^(`gpsmdNumofDim'/2))*((det(`gpsmdVarCovar'))^(1/2)))) * exp((-1/2) * loop_prod(`gpsmddemeanedTreat', `gpsmdVarCovar'))
				*mata: `gpsmdvec' = (1/(((2* pi())^(`gpsmdNumofDim'/2))*((det(`gpsmdVarCovar'))^(1/2)))) * exp((-1/2) * diagonal(quadcross((quadcross((`gpsmddemeanedTreat')',(invsym( `gpsmdVarCovar' ))))', ((`gpsmddemeanedTreat')'))))
				mata: `idx'=st_addvar("double", "`gpsmd'")
				mata: st_store(.,`idx',`gpsmdvec')
				*mata: st_matrix("`gpsmdvec'", `gpsmdvec' )
		*a.4. I attach the colvector to the stata dataset
			*svmat double `gpsmdvec', names("`gpsmdvec'")
			*rename `gpsmdvec'1 `gpsmd'
		*check start***
			capture: assert `gpsmd'>=0 
			if _rc!=0 {
				display as error "For some kind of reason the estimated gps lower than zero."
				error
			}
		*check end***
		*a.5. I retrasform the Gps obtained if "`ln'"!="" (the Gps is the density of the variable I want as a dimension not of its transformation)
			if "`ln'"!=""{
				foreach i of local ln{
					replace `gpsmd'=`gpsmd'/`i'
				}
			}
	*+the various r-class objects
		*I remove r-class objects
			return clear
		*I generate those I want
			return local cmdline `"gpsmd `0'"'
			return local cmd `"gpsmd"'
			foreach gpsmddimen of local listvarFS{ 
			return local cmdline`gpsmddimen' `"`cmdline`gpsmddimen''"'
			}
			*the dimension of the treatment and the exogenous vars
			return local Dimensions "`varlist'"
			return local DimensionsFS "`listvarFS'"
			return local LNVarCreated "`LNVARGEN'"
			return local Exogenous "`exogenous'"
			return local gpsmdvar "`gpsmd'"
			*the matrix var covar
			return matrix VarCov = `gpsmdVarCovar'
	}
	*b)
	if "`chosenpoint'"!=""{
			*check start***
			capture: assert rowsof(`chosenpoint')==`gpsmdNumofDim'

			if _rc!=0{
				display as error "You have chosen a vector with the wrong number of components or the vector is a rowvector"
				error
			}
			*check start***
		*b.1.I run the regression and predict the residuals. moreover I estimate the predicted values which I store in the matrix
		*then I calculate the residuals from the chosenpoint at point
			foreach gpsmddimen of local listvarFS {
				*I generate a temporary name for the variables of predicted residuals and predicted residual for the chosenpoint
					tempvar gpsmdresid`gpsmddimen' 
					tempvar Predicted`gpsmddimen' 
				*I run the regression
							*some display start
							display _newline "****************" _newline "The regression for dimension: `gpsmddimen'" _newline "****************"
							*some display end
					reg `gpsmddimen' `exogenous' 
				*I predict the residuals and predicted values
					predict double `gpsmdresid`gpsmddimen'', residuals 
					predict double `Predicted`gpsmddimen'' , xb
				*I calculate the residuals as the chosenpoin minus the predicted treatment
						if strmatch("`LNVARGEN'","*`gpsmddimen'*")!=1{
							replace `Predicted`gpsmddimen''= `chosenpoint'[`: list posof "`gpsmddimen'" in listvarFS', 1] - `Predicted`gpsmddimen'' 
						}
						else if strmatch("`LNVARGEN'","*`gpsmddimen'*")==1{
							replace `Predicted`gpsmddimen''= ln(`chosenpoint'[`: list posof "`gpsmddimen'" in listvarFS', 1]) - `Predicted`gpsmddimen''
						}
				*I update the local macro with the list of the name of the variables of residuals and residuals from predicted value
					local gpsmdresiduals= "`gpsmdresiduals'" + " " + "`gpsmdresid`gpsmddimen''"
					local PredRes= "`PredRes'" + " " + "`Predicted`gpsmddimen''"
				*I save a an r-class obgect the command
				local cmdline`gpsmddimen'=e(cmdline)
			}
		*b.2.I generate the Variance covariance matrix of the residuals
			qui: correlate `gpsmdresiduals', covariance
			matrix `gpsmdVarCovar'=r(C)
			*I change tha name of the columns and rows
				matrix rownames `gpsmdVarCovar'= `namesVarCov'
				matrix colnames `gpsmdVarCovar'= `namesVarCov'
				*some display start
					display _newline "****************" _newline "The Variance Covariance Matrix:" _newline "****************" 
					matlist `gpsmdVarCovar' 
				*some display end
		*b.3 I generate a variable with the propensity score at the desired point
			*I take the vectors of residuals just calculated and I make them a matrix Nxk 
				*mkmat `PredRes', matrix("`PredMat'")
			*I calculate the propensity score
				tempname idx
				mata: `PredMat'=st_data(., "`PredRes'")
				*mata: `PredMat'=st_matrix("`PredMat'")
				mata: `gpsmdVarCovar'=st_matrix("`gpsmdVarCovar'")
				mata: `gpsmdvec' = (1/(((2* pi())^(`gpsmdNumofDim'/2))*((det(`gpsmdVarCovar'))^(1/2)))) * exp((-1/2) * loop_prod(`PredMat', `gpsmdVarCovar'))
				*mata: `gpsmdvec' = (1/(((2* pi())^(`gpsmdNumofDim'/2))*((det(`gpsmdVarCovar'))^(1/2)))) * exp((-1/2) * diagonal(quadcross((quadcross((`PredMat')',(invsym( `gpsmdVarCovar' ))))', ((`PredMat')'))))
				mata: `idx'=st_addvar("double", "`gpsmd'")
				mata: st_store(.,`idx',`gpsmdvec')
				*mata: st_matrix("`gpsmdvec'", `gpsmdvec' )
		*b.4 I attach the colvector to the stata dataset
				*svmat double `gpsmdvec', names("`gpsmdvec'")
				*	rename `gpsmdvec'1 `gpsmd'
				*check start***
					capture: assert `gpsmd'>=0 
					if _rc!=0 {
						display as error "For some kind of reason the estimated gps lower than zero."
						error
					}
				*check end***
		*a.5. I retrasform the Gps obtained if "`ln'"!="" (the Gps is the density of the variable I want as a dimension not of its transformation)
			if "`ln'"!=""{
				foreach i of local ln{
					replace `gpsmd'=`gpsmd'/`chosenpoint'[`: list posof "`i'" in varlist', 1]
				}
			}
		*+the various r-class objects
			*I remove r-class objects
				return clear
			*I generate those I want
				return local cmdline `"gpsmd `0'"'
				return local cmd `"gpsmd"'
				foreach gpsmddimen of local listvarFS{ 
				return local cmdline`gpsmddimen' `"`cmdline`gpsmddimen''"'
				}
				*the dimension of the treatment and the exogenous vars
				return local Dimensions "`varlist'"
				return local DimensionsFS "`listvarFS'"
				return local LNVarCreated "`LNVARGEN'"
				return local Exogenous "`exogenous'"
				return local gpsmdvar "`gpsmd'"
				return local chosenpoint "`chosenpoint'" 
				*the matrix var covar
				return matrix VarCov = `gpsmdVarCovar'		
	}
end 
***************************	
*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
***************************	
//capture: mata: mata drop loop_prod()
mata:

//loop_prod(dta, n)
	real matrix loop_prod(real matrix  mat1, real matrix gpsmdVarCovar)
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
					counter
					result= diagonal(quadcross(temporarymat[.,(1 .. counter)], (mat1[(1 .. counter),.])')) 
					counter=counter+1 
				}
				else if (counter>11000) {
					counter
					result=(result \ diagonal(quadcross(temporarymat[.,(counter .. min((counter+11000, nrowsmat1)))], (mat1[(counter .. min((counter+11000, nrowsmat1))),.])')) )
					counter=min((counter+11000, nrowsmat1))+1
				}
			}
		}
		return(result) 
		//a matrix can be subset by chosing the rows or column with a vector, tecnically also 1..5 define a vector. It is like c(1:5) in R
		}
end


















