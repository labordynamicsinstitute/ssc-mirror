*! reweight 11.2 - September  2012
*! Author: Daniele Pacifico, danielepacifico@tesoro.it

program reweight, sortpreserve rclass
	version 11.2

syntax varlist [in] [if], 		///
	SWeight(string) 			///
	NWeight(string) 			///
	TOTal(string) 				///
	DFunction(string) [			///
	TOLerance(real 0.000001) 	///
	niter(int 50)				///
	UPBound(real 3)				///
	LOWBound(real 0.2) 			///
	MLOWBound(real 0.1) 		///
	MUPBound(real 6)			///
	NTries(int 0)				///
	SValues(string) 			///
	]


tempname missing  id tp ttp tpm t difft X m lm u w x s nvar nro nco N err fun cfun fun_o too okay
marksample touse
markout `touse' `varlist' `sweight'

*--------------------------------
*	Start preliminary checks	|
*--------------------------------
confirm integer number `niter'
confirm integer number `ntries'
cap confirm matrix `total'

if _rc!=0	{
display in re  "Total should contain a Stata Matrix with the new population totals"
exit
			}
cap confirm numeric variable `varlist'
if _rc!=0	{
display in re  "Calibrating variables should be numeric"
exit
			}	
cap confirm numeric variable `sweight'
if _rc!=0	{
display in re  "Survey weights should be numeric"
exit
			}
if 	"`dfunction'" != "" 	& ///
	"`dfunction'" != "chi2" & ///
	"`dfunction'" != "a" 	& ///
	"`dfunction'" != "b" 	& ///
	"`dfunction'" != "c" 	& ///
	"`dfunction'" != "ds" 	{
	display in red 	"Only the functions named chi2, a, b, c, ds are allowed for DFunction(). See the help for references"
	exit 
						}
if "`dfunction'"=="ds" & (`lowbound'<=0 |`lowbound'>=1 | `upbound'<=1) 	{
display in red "lowbound should be between 0-1 and upbound must be bigger than 1"
exit
													}
if "`dfunction'"=="ds" & (`mlowbound'<=0 | `mlowbound'>=1 | `mupbound'<=1) 	{
display in red "mlowbound should be between 0-1 and mupbound must be bigger than 1"
exit
													}
capture assert (`sweight'>=0 )
if _rc!=0	{
display in red  "`sweight' should not be negative"
exit
			}
		
*check conformability of entry matrices:
local nvar: word count `varlist' 
scalar `nro'=rowsof(`total')
scalar `nco'=colsof(`total')
if (`nro'!=`nvar' | `nco'!=1)	{
display in red  "matrix `total' must be a column vector with as many rows as the number of calibrating variables"
exit
								}
if "`svalues'" != "" {
confirm matrix `svalues'
scalar `nro'=rowsof(`svalues')
scalar `nco'=colsof(`svalues')							
	if (`nro'!=`nvar' | `nco'!=1)	{
	display in red  "matrix `svalues' must be a column vector with as many rows as the number of calibrating variables"
	exit
									}								
						}	

** Check if there are missing values and do not consider these observations during the estimation**
qui su `touse'
if r(mean) != 1 {
	di in g "Note: missing values encountered. Rows with missing values are not included in the calibration procedure"
				}
*----------------------------
*	end preliminary checks	|
*----------------------------
						

*--------------------
*	define setup	|
*--------------------
*number of relevant observations:
qui count if `touse'
local N=r(N)
*generate a mata vector containing values that uniquely identify the observations in stata (by row):
gen `id'=_n
qui putmata `id' if `touse', replace
**Compute survey totals using survey weights**
qui tabstat `varlist' [w=`sweight'] if `touse', s(su) save
matrix `tpm' = r(StatTotal)'
mata: `tp'=st_matrix("`tpm'")
mata: `t'=st_matrix("`total'")
**compute the vector of differences**
mata: `difft'=(`t'-`tp')
*X=matrix of variable(s) to be calibrated
qui putmata `X'=(`varlist') if `touse', replace
*s=vector of survey weight to be adjusted
qui putmata `s'=(`sweight') if `touse', replace

*------------------------------------
*	Chi-square distance functions	|
*------------------------------------
if ("`dfunction'" =="chi2") {
mata: `m'=(`X'':*`s'')*`X'
mata: `lm'=invsym(`m')*`difft'
mata: `u'=(`lm''*`X'')
**w=matrix of new weight
mata: `w'=`s':*(1:+(`u''))
qui getmata `nweight'=`w', id(`id') replace
							}
							
*--------------------------------
*	Others distance functions	|
*--------------------------------
if (("`dfunction'" =="ds") | ("`dfunction'" =="a") | ("`dfunction'" =="b") | ("`dfunction'" =="c"))	{ 
tempname alpha num den g dg H G lm last xlmh xlmg nc pw w to ok lmp lma lms
*generate starting values from the chi-squared distance function if no starting values have been specified*
if ("`svalues'" == "") {
	mata: `m'=(`X'':*`s'')*`X'
	mata: `lmp'=invsym(`m')*`difft'
						}
						
else 	{
	mata: `lmp'=st_matrix("`svalues'")
		}
	*save starting values:
	mata `lms'=`lmp'	
*
local i=1
local nt=0

	while `i'<=`niter'			{
	
	*----------------------------
	*	DS distance function	|
	*----------------------------
	if ("`dfunction'" =="ds") 			{ 
		local alpha=(`upbound'-`lowbound')/(`upbound'-`upbound'*`lowbound')
		mata: `num'=`lowbound'*(`upbound'-1):+`upbound'*(1-`lowbound')*exp((`X'*`lmp')*`alpha')
		mata: `den'=(`upbound'-1):+(1-`lowbound')*exp((`X'*`lmp')*`alpha')
		mata: `g'=`num':/`den'
		mata: `dg'=`g':*(`upbound':-`g'):*((1-`lowbound')*`alpha'*exp((`X'*`lmp')*`alpha'):/`den')
		mata: `H'=-(`X'':*(`s'':*`dg''))*`X'
		mata: `G'=`X''*(`s':*(`g':-1))
		mata: `lma'=`lmp'-luinv(`H')*(`difft'-`G')
		mata  `lmp'=`lma'
		mata: `w'=`g':*`s'
		mata: `fun'=(`upbound' :-`g'):*(ln((`upbound' :-`g'):/(`upbound'-1)))+(`g':-`lowbound'):*(ln((`g':-`lowbound'):/(1-`lowbound')))
											}
					
	*--------------------------------
	*	A an B distance functions	|
	*--------------------------------										
	if ("`dfunction'" =="a") 			{ 
		mata: `xlmh'=((1:-((`X'*`lmp'):/2)):^(-3))
		mata: `H'=-(`X'':*(`s'':*`xlmh''))*`X'
		mata: `xlmg'=(((1:-((`X'*`lmp'):/2)):^(-2)):-1)
		mata: `G'=`X''*(`s':*`xlmg')
		mata: `lma'=`lmp'-luinv(`H')*(`difft'-`G')
		mata  `lmp'=`lma'
		mata: `w'=((1:-((`X'*`lma'):/2)):^(-2)):*`s'
		mata: `fun'=2:*(sqrt(`w')-sqrt(`s')):^(2)
										}

	
		if ("`dfunction'" =="b") 			{ 
		mata: `xlmh'=((1:-(`X'*`lmp')):^(-2))
		mata: `H'=-(`X'':*(`s'':*`xlmh''))*`X'
		mata: `xlmg'=(((1:-(`X'*`lmp')):^(-1)):-1)
		mata: `G'=`X''*(`s':*`xlmg')
		mata: `lma'=`lmp'-luinv(`H')*(`difft'-`G')
		mata  `lmp'=`lma'
		mata: `w'=`s':*((1:-(`X'*`lma')):^(-1))
		mata: `fun'=-`s':*log(`w':/`s')+`w'-`s'			
											}
									
		
		if ("`dfunction'" =="c") 			{ 
		mata: `xlmh'=exp(`X'*`lmp')
		mata: `H'=-(`X'':*(`s'':*`xlmh''))*`X'
		mata: `xlmg'=(exp(`X'*`lmp')):-1
		mata: `G'=`X''*(`s':*`xlmg')
		mata: `lma'=`lmp'-luinv(`H')*(`difft'-`G')
		mata  `lmp'=`lma'
		mata: `w'=`s':*exp(`X'*`lma')
		if `i'>1 {
		mata: `fun_o'=`fun'
				}
		mata: `fun'=`w':*log(`w':/`s')-`w'+`s'			
											}
											
			
		*save the previous values of the distant function:
		if `i'>1 {
		mata: `fun_o'=`fun'
				}
	*----------------------------
	*	check for convergence	|
	*----------------------------
		*1) All the estimated totals must be (almost) the same as the external ones (the difference depends on the tolerance level)
		*vector of new totals:
		mata `pw'=`X''*`w'
		*vector of differeces between the estimated totals and the external totals
		mata `err'=`t'-`pw'
		*vector with the tolerance level
		mata `to'=J(`nvar',1,`tolerance')
		*ok is scalar indicating the number of estimated totals whose difference with respect to the external totals is lower than the tolerance level
		mata `ok'=(((abs(`err'):<=`to')'*(abs(`err'):<=`to')):==`nvar')
		
		*2) For each observation the percentage change of the distant function  between 2 iteration has to be lower than the tolerance level
		if `i'>1 {
		mata `too'=J(`N',1,`tolerance')
		mata `cfun'=abs((`fun':-`fun_o'):/`fun_o')
		mata `okay'=(((`cfun':<=`too')'(`cfun':<=`too')):==`N')
						}
		if `i'==1 { 
		mata `okay'=0
					}
		
		mata: st_numscalar("`ok'",`ok')
		mata: st_numscalar("`okay'",`okay')

		if (`ok'==1) &  (`okay'==1) & (`nt'==0) {
		display in gr  "Iteration " in yel `i' in gr " - Converged"
		scalar `last'=`i'
		scalar `nc'=0
		continue, break
							}
	
		if (`ok'==1) &  (`okay'==1) & (`nt'>0) & (("`dfunction'" =="a") | ("`dfunction'" =="b") | ("`dfunction'" =="c")) {
		display in gr "Converged, new starting values saved in the return list."
		scalar `last'=`i'
		scalar `nc'=0
		continue, break
							}

		if (`ok'==1) & (`nt'>0) & ("`dfunction'" =="ds") {
		display in gr "Converged, new starting values and new bounds saved in the return list."
		scalar `last'=`i'
		scalar `nc'=0
		continue, break
							}
							
		if (`i'==`niter') & (`nt'<=`ntries') & (`nt'==0) & (`ntries'>0) & (("`dfunction'" =="a") | ("`dfunction'" =="b") | ("`dfunction'" =="c"))	{
		display in gr  "Iteration " in yel `i' in gr " Not Converged within the maximum number of iterations, the algorithm now tries with new starting values up to " in yel `ntries' in gr " times:"
															}
		if (`i'==`niter') & (`nt'<=`ntries') & (`nt'==0) & (`ntries'>0) & ("`dfunction'" =="ds")	{
		display in gr  "Iteration " in yel `i' in gr " Not Converged within the maximum number of iterations, the algorithm now tries with new starting values and new bounds up to " in yel `ntries' in gr " times:"
															}
		
		if (`i'==`niter') & (`nt'>=`ntries') & (`nt'!=0) & (`ntries'>0){
		display in red "Not Converged within the maximum number of tries, try to increase the number of maximum tries and/or the number of maximum iterations"
		scalar `nc'=1
		continue, break
									}
		if (`i'==`niter') & (`nt'>=`ntries') & (`nt'==0) & (`ntries'==0){
		display in gr  "Iteration " in yel `i'	
		display in red "Not Converged within the maximum number of iterations, try to use the NTRIES option"
		scalar `nc'=1
		continue, break
									}
									
		if (`i'==`niter') & (`nt'<=`ntries')	{
		local nt=`nt'+1
		display in gr  "try number " in yel `nt'
		local i=1
		*New starting values are a random function of the chi-squared lagrange multiplayers 
		mata: `lmp'=`lms':*(1:+((-1:+((2):*uniform(`nvar',1)))))
		
		if ("`dfunction'" =="ds")	{
		local lowbound=`mlowbound'+(0.999-`mlowbound')*runiform()
		local upbound=1.001+(`mupbound'-1.001)*runiform()
												}
												}
									
		if (`i'<=`niter') & (`nt'==0) {
		display in gr  "Iteration " in yel `i'	
		}
		
		if `i'<`niter' {
		local i=`i'+1
						}
						
														}
														}
*------------
* endo loop |
*------------	
if ("`dfunction'" =="chi2") {
	*display results:
	qui su `nweight'
		if r(min)<0{
			display as re "New weights obtained from the `dfunction' distance function are negative, try with other distance functions"
			*fill in return list:
			return local negative "yes"
					}
		if r(min)>=0{
			*display results:
			tabstat `varlist' [aw=`nweight'] if `touse', s(su) save
			display as ye "New weights obtained from the `dfunction' distance function"
			matrix `ttp' = r(StatTotal)'
			mata: st_matrix("`lm'", `lm')
			mata: st_rclear()
			*fill in return list:
			return matrix NewTotals=`ttp'
			return matrix lm=`lm'
			return matrix SurveyTotals=`tpm'
			return scalar nobs=`N'
			return local negative "no"
			return local var "`varlist'"
			return local dfunction "`dfunction'"
			return local command "reweight"
					}
							}

if ("`dfunction'" =="a") | ("`dfunction'" =="b") | ("`dfunction'" =="c") | ("`dfunction'" =="ds") {
		if `nc'!=1 	{
			*display results:
			mata: st_matrix("`lms'", `lms')
			getmata `nweight'=`w', id(`id') replace
			display " " 
			display as gr "New totals using reweighted variables"
			tabstat `varlist' [aw=`nweight'] if `touse', s(su) save
			display as ye "New weights obtained from the `dfunction' distance function"
			matrix `ttp' = r(StatTotal)'				
				if ("`dfunction'" =="ds") 	{ 
					display as green "Current bounds: upper=" as ye round(`upbound', .0001) as gr " - lower=" as ye round(`lowbound', .0001)
											}
			*fill in return list:
			mata: st_rclear()
			mata: st_matrix("lma", `lma')
			return matrix lm=lma
			return matrix SurveyTotals=`tpm'
			return matrix NewTotals=`ttp'
			return matrix StartingValues=`lms'
			return scalar nlast_iter = `last'
			return scalar nmaxiter = `niter'
			return scalar nobs=`N'
				if ("`dfunction'" =="ds")	{ 
					return scalar lowbound=`lowbound'
					return scalar upbound=`upbound'
											}
			return local var "`varlist'"
			return local dfunction "`dfunction'"
			return local converged "yes"
			return local command "reweight"
							}				
		if `nc'==1  {
			mata: st_rclear()
			return matrix SurveyTotals=`tpm'
			return scalar ntries = `nt'
			return local converged "no"
			return local var "`varlist'"
			return local dfunction "`dfunction'"
			return local command "reweight"
					}
}
end
