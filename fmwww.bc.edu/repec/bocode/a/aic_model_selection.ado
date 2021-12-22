// program to compute AIC for sequence of regression models
program aic_model_selection
*! 1.0.0   12 Sep 2021 Matthias Schonlau 
    version 16.1
	syntax anything(id="argument name" name=arg) [if] [in], [ bic ]

	local command = word("`arg'",1)   // regress, logistic ... 
	local model= word("`arg'",2) // y variable
	local i=3   // first x variable
	local ic="AIC"
	if "`bic'"!="" local ic="BIC"
	di 
	di as res  %9.0g "      `ic' Model"
	
	while  word("`arg'",`i')  !="" {
		local model= "`model' " + word("`arg'",`i')
		local i=`i'+1
		qui `command' `model'  `if' `in'
		qui estat ic
	    matrix m= r(S)
		local aic =  m[1,5]
		if "`bic'"!=""  local aic=m[1,6]  // use BIC instead
		di as text  %9.0g `aic' " `model'" 
	}
end 

