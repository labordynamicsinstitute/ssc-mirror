*!sgpv-multiple-null-hypotheses-example.do
*!Example code how to calculate the SGPVs if each coefficient has its own null-hypothesis 	
	preserve 
	sysuse auto,clear
	regress price mpg weight foreign
	local coeflist mpg weight foreign // Put here the coefficients for which you want to calculate the SGPVs
	local nulllb 20 2 3000 // lower bounds of null-hypotheses
	local nullub 40 4 6000 // upper bounds of null-hypotheses
	local i 1
	foreach coef of local coeflist{
	 sgpv ,coefficient(`coef') nulllo(`=word("`nulllb'",`i')') nullhi(`=word("`nullub'",`i')') quietly
	 mat res = r(comparison) // collect the results in matrix for further processing
	 mat results =(nullmat(results) \ res ) 
	 local ++i
	}
	matlist results, title("Collection of results") rowtitle(Coefficients)
	restore
