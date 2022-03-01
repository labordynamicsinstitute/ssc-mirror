*! Version 2.0.0 25january2022

/*
	Syntax:

	powerps, <Price> <Quantity> [<op1>] [<op2>] [<op3>] [<op4>] [<op5>] [<op6>]
		
		<op1> := AEI
		<op2> := AXiom[(string)]
			eWGARP
			eWARP
			eGARP	(Defualt)
			eSARP
			eHARP
			eCM
		<op3> := EFFiciency[(real 1)]
		<op4> := PROGRESSbar
		<op5> := SEED[(real 12345)]
		<op6> := SIMulations[(real 1000)]

*/

/* ================================================================== */
					/* Main ado file */

program powerps, rclass sortpreserve
	version 15.1

	*User input
	syntax, Price(string) Quantity(string)	/// 
			[	AEI							///
				AXiom(string)				///
				EFFiciency(real 1)			///
				PROGRESSbar					///
				SEED(real 12345)			///
				SIMulations(real 1000)		///
				TOLerance(real 6)]

					*******************************
					*** Checking data structure ***
					***   and syntax validity   ***
					*******************************
	** Check nr 1:
	* Is efficiency within the allowed range?
	if `efficiency' <= 0 | `efficiency' > 1 {
		display as error 	" Efficiency() must be greater than 0 and equal" ///
							"to or less than 1."
		display as error 	" If not specified, the default setting for" ///
							"efficiency is 1."
		exit 198 /* "Invalid syntax --> range invalid" error */
	}

	** Check nr 2:
	* Is there at least one product with a non-zero quantity in every given period?
	mata: st_numscalar("r(nrz)", (min(rowsum(st_matrix("`quantity'")))==0 ? 1 : 0))
	if `r(nrz)' == 1 {
		display as error 	" The data contains an observation or more" ///
		as error 			" with zero (or missing) quantities for all goods."
		exit 459 /* "Something that should be true of your data is not" error */
	}

	** Check nr 3:
	* Are prices and quantity data of the same dimension?
	mata: checkdimension("`price'", "`quantity'")
	if `r(SR)' == 0 | `r(SC)' == 0 {
		display as error 	" Invalid matrix dimensions." ///
							" The price matrix is " r(RP) "x" r(CP) "." ///
							" The quantity matrix is " r(RX) "x" r(CX) "."
		exit 459 /* "Something that should be true of your data is not" error */
	}

	** Check nr 4:
	* Are prices strictly positive?
	mata: st_numscalar("r(PNSP)", (min(st_matrix("`price'")) < 0 ? 1 : 0))
	if `r(PNSP)' > 0 {
		display as error 	" The price matrix contains non-positive values."
		exit 411 /* "Nonpositive values encountered" error */
	}

	* Does the user want to run AEI?
	if ("`aei'"!="") {

		* Settings for matrices
		local aei_column = 3
		local aei_column_name "AEI"

		if ("`tolerance'" == "")	local tolerance = 6

	}

	else if ("`aei'"=="") {
		local aei_column 2
		local aei_column_name ""
		
	}

	* Which axiom(s) does the user want to check?
	* And creating necessary scalars, vectors and tempnames accordingly.
	local tempname_prefix sim P PS Num_vio Frac_vio AEI rawResults

	local axiom = lower("`axiom'")
	
	if ("`axiom'"=="")		local axiom egarp	/* eGARP set to default */
	
	if ("`axiom'"=="all")	local axiom egarp esgarp ewgarp esarp ewarp eharp ecm

	tokenize `axiom'
	local axioms "`1' `2' `3' `4' `5' `6' `7'"

	foreach ax of local axioms	{
	
		if !inlist("`ax'", "egarp", "ewgarp", "esgarp", "esarp", "ewarp", "eharp", "ecm") {
			display as error 	" Axiom() must be either eGARP, eWGARP, eSGARP, " ///
								"eSARP, eWARP, eHARP or eCM; case-insensitive."
			display as error 	" If not specified, the default setting for " ////
								"Axiom() is eGARP."
			exit 198 /* "Invalid syntax --> range invalid" error */
			
		}

		else {
			
			foreach temp of local tempname_prefix {
				
				tempname `temp'_`ax'

			}

			matrix `sim_`ax'' = J(`simulations', `aei_column',.)
			matrix colname `sim_`ax'' = Num_Vio Frac_Vio `aei_column_name'
			local P_`ax' = 0	
			
		}
	}
	
			****************************
			*** Checkax on real data ***
			****************************

			
					***************		
					*** PowerPS ***
					***************
	tempname gmat te
	mata: newGMAT("`price'","`quantity'", `seed', `simulations')

	matrix `gmat' = gamma_matrix
	matrix `te' = total_expenditure
	local rK = r(K)
	local rT = r(T)

	* With progress bar
	if ("`progressbar'"!="") {
		
		nois _dots 0, title(Loop progress) reps(`simulations')
		
		forvalues i = 1(1)`simulations' {
			
			 _dots `i' 0 
			mata: genXS("`gmat'", `rT', `rK', "`te'", "`price'", `i')
			 	 
			foreach ax of local axioms {
				
				local axiomDisplay = "e" + upper(substr("`ax'", 2, strlen("`ax'") - 1))
	
				** Checkax results
				quietly checkax, price("`price'") quantity("simulated_quantities") ///
						efficiency(`efficiency') axiom("`ax'") nocheck
				quietly return list

				local P_`ax' = `P_`ax'' + (1 - r(PASS_`axiomDisplay'))

				* Number of violations per axiom and subject
				local Num_Vio	= r(NUM_VIO_`axiomDisplay')
				* Fraction of violations per axiom and subject
				local Frac_Vio	= r(FRAC_VIO_`axiomDisplay')

				matrix `sim_`ax''[`i',1] = `Num_Vio'
				matrix `sim_`ax''[`i',2] = `Frac_Vio'
				
				if ("`aei'" != "") {
								 
					** AEI results
					quietly aei, price("`price'") quantity("simulated_quantities") ///
						axiom("`ax'") tolerance(`tolerance')
					quietly return list
								
					local aei_efficiency = r(AEI_`axiomDisplay')
								
					matrix `sim_`ax''[`i',3] = `aei_efficiency'

				}
			}
		}
	}
	
	* Without progress bar
	else if ("`progressbar'"=="") {
	
		forvalues i = 1(1)`simulations' {
		
			mata: genXS("`gmat'", `rT', `rK', "`te'", "`price'", `i')
			 	
			foreach ax of local axioms {
				
				local axiomDisplay = "e" + upper(substr("`ax'", 2, strlen("`ax'") - 1))
	
				** Checkax results
				
				quietly checkax, price("`price'") quantity("simulated_quantities") ///
						efficiency(`efficiency') axiom("`ax'") nocheck
				quietly return list

				local P_`ax' = `P_`ax'' + (1 - r(PASS_`axiomDisplay'))

				* Number of violations per axiom and subject
				local Num_Vio = r(NUM_VIO_`axiomDisplay')
				* Fraction of violations per axiom and subject
				local Frac_Vio = r(FRAC_VIO_`axiomDisplay')

				matrix `sim_`ax''[`i',1] = `Num_Vio'
				matrix `sim_`ax''[`i',2] = `Frac_Vio'

				if ("`aei'" != "") {

					** AEI results
					quietly aei, price("`price'") quantity("simulated_quantities") ///
						axiom("`ax'") tolerance(`tolerance')
					quietly return list
								
					local aei_efficiency = r(AEI_`axiomDisplay')
								
					matrix `sim_`ax''[`i',3] = `aei_efficiency'

				}
				
			}
			
		}

	}

	local first_ax = 1
		
	tempname rawResults generalInfoTable sumStatsTable
	
	local goods `=colsof(`price')'
	local obs 	`=rowsof(`price')'
			
	foreach ax of local axioms {
		local axiomDisplay = "e" + upper(substr("`ax'", 2, strlen("`ax'") - 1))
	
		local P_`ax' = `P_`ax''/`simulations'

		quietly checkax, price("`price'") quantity("`quantity'") ///
			efficiency(`efficiency') axiom("`ax'") nocheck
				
		quietly return list
			
		local PASS_`ax' = r(PASS_`axiomDisplay')
		local PS_`ax'	= `PASS_`ax'' - (1 - `P_`ax'')
		
		quietly aei, price("`price'") quantity("`quantity'") ///
			axiom("`ax'")
		
		local AEI_`ax' = r(AEI_`axiomDisplay')
				
		
		** Creating output & return list tables
		local axiomDisplay = "e" + upper(substr("`ax'", 2, strlen("`ax'") - 1))

		* Raw output table
		matrix `rawResults_`ax'' = `P_`ax'',  `PS_`ax'', `PASS_`ax'', `AEI_`ax''
		matrix rowname `rawResults_`ax'' = "`axiomDisplay'"

		if 		`first_ax' == 1		matrix `rawResults' = `rawResults_`ax''
		else if `first_ax'  > 1		matrix `rawResults' = `rawResults' \ `rawResults_`ax''
			
		local first_ax = `first_ax' + 1

	}

	* Combined main results table
	matrix `generalInfoTable' = `obs', `goods', `simulations', `efficiency'
	matrix `generalInfoTable' = `generalInfoTable''
	matrix rowname `generalInfoTable' = "	Number of obs		= " ///
										"	Number of goods		= " ///
										"	Simulations 		= " ///
										"	Efficiency level	= "
	matrix colname `generalInfoTable' = "#"
	matlist `generalInfoTable', border(none) lines(none) format(%7.2g) names(rows) left(9) twidth(40)

	return scalar OBS						= `obs'
	return scalar GOODS						= `goods'
	return scalar EFF						= `efficiency'
		
	matrix colnames `rawResults' = Power PS Pass AEI
	matlist `rawResults', border(top bottom) rowtitle("Axioms")

	di " "
	di as text "Summary statistics for simulations:"	

	local allAxiomsDisplay ""
	foreach ax of local axioms {
		
		local axiomDisplay = "e" + upper(substr("`ax'", 2, strlen("`ax'") - 1))
		
		local allAxiomsDisplay "`allAxiomsDisplay' `axiomDisplay'"
		
		if ("`aei'" != "") {
							
			* Summary stats table
			tempvar Num Frac AEI
					
			mata: A = st_matrix("`sim_`ax''")
					
			getmata (`Num' `Frac' `AEI') = A, force
				
			quietly tabstat `Num' `Frac' `AEI', stat(mean sd min ///
					p25 median p75 max) save

			quietly return list 
				
			matrix `sumStatsTable' = r(StatTotal)
			matrix colnames `sumStatsTable' =	"#vio" "%vio" AEI
			matrix rownames `sumStatsTable' =	Mean "Std. Dev." Min ///
												Q1 Median Q3 Max
												
			return scalar TOL_`axiomDisplay'= `tolerance'
			
		}
			
		else if ("`aei'" == "") {
						
			* Summary stats table
			tempvar Num Frac
				
			mata: A = st_matrix("`sim_`ax''")
				
			getmata (`Num' `Frac') = A, force
				
			quietly tabstat `Num' `Frac', stat(mean sd min p25 ///
					median p75 max) save
						
			quietly return list 
				
			matrix `sumStatsTable' = r(StatTotal)
			matrix colnames `sumStatsTable' =	"#vio" "%vio"
			matrix rownames `sumStatsTable' =	Mean "Std. Dev." Min ///
													Q1 Median Q3 Max
		}


		matlist `sumStatsTable',	border(top bottom) ///
										rowtitle("`axiomDisplay'")

		* Return list for several axioms
		return scalar SIM						= `simulations'
		return scalar AEI_`axiomDisplay'		= `AEI_`ax''
		return scalar PASS_`axiomDisplay'		= `PASS_`ax''
		return scalar PS_`axiomDisplay'			= `PS_`ax''
		return scalar POWER_`axiomDisplay'		= `P_`ax''
		return local  AXIOM						"`allAxiomsDisplay'"
		return matrix SIMRESULTS_`axiomDisplay'	= `sim_`ax''
		return matrix SUMSTATS_`axiomDisplay'	= `sumStatsTable'

	}

end



mata:
			
/* ================================================================== */
					/* Check nr 3 */

void checkdimension(string P_temp, string X_temp)
{
	real scalar 	same_rows, same_cols, no_rows, no_cols
	real scalar		rx, rp, cx, cp
	
	x = st_matrix(X_temp)
	p = st_matrix(P_temp)
	
	rx = rows(x)
	rp = rows(p)
	
	cx = cols(x)
	cp = cols(p)
	
	//same_rows = (rx == rp ? 1 : 0)
	//same_cols = (cx == cp ? 1 : 0)
	
	if (rx == rp) 				same_rows = 1
	else 						same_rows = 0
	
	if (cx == cp)				same_cols = 1
	else						same_cols = 0
	
	// Rows
	st_numscalar("r(RX)", rx)
	st_numscalar("r(RP)", rp)
	
	// Columns
	st_numscalar("r(CX)", cx)
	st_numscalar("r(CP)", cp)
	
	// Same dimensions dummies
	st_numscalar("r(SR)", same_rows)
	st_numscalar("r(SC)", same_cols)

}
					/* Check nr 3 */
/* ================================================================== */


/* ================================================================== */
					/* powerCalc */
					
function newGMAT(string P_temp, string X_temp, scalar seed, scalar S)					
{
	p = st_matrix(P_temp)
	x = st_matrix(X_temp)

	rseed(seed)							// setting the random seed 

	T = rows(p)							// # observations
	K = cols(p)							// # goods

	TE = (p:*x)*J(K, 1, 1);				// total expenditure

	GMAT = rgamma(T*K,S,1,1)			// (T*K)xS matrix of Gamma(1,1) random numbers
	
	st_matrix("gamma_matrix", GMAT)
	st_numscalar("r(T)", T)
	st_numscalar("r(K)", K)
	st_matrix("total_expenditure", TE)

}
	
function genXS(matrix GMAT, scalar T, scalar K, matrix TE, matrix p, scalar s)
{
	GMAT = st_matrix(GMAT)
	TE = st_matrix(TE)
	p = st_matrix(p)
	
	G = rowshape(GMAT[.,s],T);          // making a TxK matrix 

	D = G:/J(1, K, G*J(K,1,1))
	
	x_S = D:*(J(1, K, TE):/p)           // simulated quantities
	
	st_matrix("simulated_quantities", x_S)

}
					/* powerCalc */
/* ================================================================== */

end


