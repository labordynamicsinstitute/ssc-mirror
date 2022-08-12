*! Version 1.0.2 08august2022
/*
	Syntax:
	hmindex, <Price> <Quantity> [<op1> <op2> <op3> <op4> <op5> <op6>]  
		
		<op1> := AXiom[(string)]
			eWGARP	   (default)
			eWARP
		<op2> := power
		<op3> := SEED[(real 12345)]
		<op4> := SIMulations[(real 1000)]
		<op5> := IDvar[(string)]
		<op6> := GENerate[(string)]
*/
/* ================================================================== */
* Main program
capture program drop hmindex
program hmindex, rclass sortpreserve
	version 15.1
	
	syntax, Price(string) Quantity(string) ///
			[AXiom(string)			///
			 DISTribution   		///
			 SIMulations(real 1000) ///
			 SEED(real 12345)		///
			 GENerate(string)		///
			 ID(string)]
	
	
				*******************************
				*** Checking data structure ***
				***   and syntax validity   ***
				*******************************

	* Is there at least one product with a non-zero quantity in every given period?
	mata: st_numscalar("r(nrz)", (min(rowsum(st_matrix("`quantity'")))==0 ? 1 : 0))
	if `r(nrz)' == 1 {
		display as error 	" The data contains observations" ///
		as error 			" with zero (or missing) quantities."
		exit 459 /* "Something that should be true of your data is not" error */
	}
	* Are prices and quantity data of the same dimension?
	mata: st_numscalar("r(OK)", (rows(st_matrix("`price'")) == rows(st_matrix("`quantity'")) ///
		& cols(st_matrix("`price'")) == cols(st_matrix("`quantity'")) ? 1 : 0))
	if `r(OK)' == 0 {
		display as error 	"Invalid matrix dimensions."
		exit 459 /* "Something that should be true of your data is not" error */
	}
	* Are prices strictly positive?
	mata: st_numscalar("r(PNSP)", (min(st_matrix("`price'")) < 0 ? 1 : 0))
	if `r(PNSP)' > 0 {
		display as error 	" The price matrix contains non-positive values."
		exit 411 /* "Nonpositive values encountered" error */
	}
	
	* Which axiom(s) does the user want to check?
	* And creating necessary scalars, vectors and tempnames accordingly.
	local tempname_prefix hm min_hm mean_hm median_hm max_hm std_hm q1_hm q3_hm sim rawResults
	local axiom = lower("`axiom'")
	if ("`axiom'"=="")		local axiom wgarp	/* WGARP set to default */
	
	if ("`axiom'"=="all")	local axiom wgarp warp
	tokenize `axiom'
	local axioms "`1' `2'"
	foreach ax of local axioms {
		if !inlist("`ax'", "wgarp", "warp") {
			display as error 	" Axiom() must be either WGARP or WARP; case-insensitive."
			display as error 	" If not specified, the default setting for" ///
								" Axiom() is WGARP."
			exit 198 /* "Invalid syntax --> range invalid" error */
		}
		
		else if inlist("`ax'", "wgarp", "warp") {
			
			foreach temp of local tempname_prefix {
				tempname `temp'_`ax'
			}
 		}

 		if "`distribution'" != "" {
 			matrix `sim_`ax'' = J(`simulations', 2,.)
 			matrix colname `sim_`ax'' = HM_NUM HM_FRAC

 		}

	}
						**************
						*** AXIOMS ***
						**************
	local goods `=colsof(`price')'
	local obs 	`=rowsof(`price')'
	
	local first_ax = 1

 	local allAxiomsDisplay ""

 	tempname rawResults generalInfoTable sumStatsTable ind	/* Temp names for tables */

	foreach ax of local axioms {
		capture matrix drop pnondrop
		capture matrix drop qnondrop
		
		* Creating Quantity Matrix with a sequence vector
		mata: st_matrix("seq", range(1,`obs',1))
		matrix qnondrop = (seq, `quantity')
		
		* Creating Price Matrix with a zero vector
		matrix pnondrop = (J(`obs',1,0), `price')

		mata: test_`ax'("pnondrop", "qnondrop")
		
		if `r(PASS)' == 1 {
		
			return scalar HM_`ax' = `=rowsof(pnondrop)'
			
		}
		
		else if `r(PASS)' != 1{
		
			matrix pdrop = J(1,`goods' + 1,.)
			matrix qdrop = J(1,`goods' + 1,.)
	
			local ind = 0
			while `ind' == 0 {
	
				mata: adjmat_`ax'("pnondrop", "qnondrop")

				mata: remove("AdjMat", "pnondrop", "qnondrop")
				
				
				* TO DO: capture only if pd doesn't exist
				capture matrix pdrop = (pdrop\pd)
				capture matrix qdrop = (qdrop\qd)

				mata: test_`ax'("pnondrop", "qnondrop")

				if `r(PASS)' == 1 {
					local ind = 1
				}
				
			} /* Ends while loop */
		
		} /* Ends else if */
		
		capture matrix drop pd
		capture matrix drop qd
		capture matrix drop AdjMat
		
		* Sorting matrices
		matrix dnonsort = [qnondrop, pnondrop]
		mata : st_matrix("dnonsort", sort(st_matrix("dnonsort"), 1))
		matrix qnondrop = dnonsort[1...,2..`goods' + 1]
		matrix pnondrop = dnonsort[1...,`goods' + 3..`=colsof(dnonsort)']
			
		* If matrix pdrop exists (because at least 1 observation was dropped),
		* then clean and sort pdrop and qdrop matrices. Otherwise, skip.
		capture confirm matrix pdrop
		
		if _rc == 0 {
			matrix pdrop = pdrop[2...,1...]
			matrix qdrop = qdrop[2...,1...]
			matrix dsort = [qdrop, pdrop]
			mata : st_matrix("dsort", sort(st_matrix("dsort"), 1))
			matrix qdrop = dsort[1...,2..`goods' + 1]
			matrix pdrop = dsort[1...,`goods' + 3..`=colsof(dsort)']
			
			* Creating column vector with identifier for dropped observations
			matrix obsdrop = dsort[1..., 1]

			* Creating indicator column vector
			matrix I = J(`obs',1, 1)
			forvalues i = 1/`=rowsof(obsdrop)' {
				matrix I[obsdrop[`i',1], 1] = 0
			}
		}
	

		local FC_`ax': di %3.2f scalar((`=rowsof(pnondrop)'/`obs'))
		local FRAC_HM_`ax' = `FC_`ax''
		
		** Creating output & return list tables
		local axiomDisplay = upper("`ax'")
		local allAxiomsDisplay "`allAxiomsDisplay' `axiomDisplay'"
			
		* Creating output table
		matrix `rawResults_`ax'' = `=rowsof(pnondrop)', `FRAC_HM_`ax''
		matrix rowname `rawResults_`ax'' = "`axiomDisplay'"
		if 		`first_ax' == 1		matrix `rawResults' = `rawResults_`ax''
		else if `first_ax'  > 1		matrix `rawResults' = `rawResults' \ `rawResults_`ax''
			
		local first_ax = `first_ax' + 1
		
		
		* Return list for several axioms
		return scalar HM_NUM_`axiomDisplay' 		= `=rowsof(pnondrop)'
		return scalar HM_FRAC_`axiomDisplay'		= `FRAC_HM_`ax''
		
		* If at least one observation was drop, return violater sets
		if `=rowsof(pnondrop)' < `obs' {
			return matrix VS_price_`axiomDisplay'		= pdrop
			return matrix VS_quantity_`axiomDisplay'	= qdrop
			
			return matrix OBSDROP_`axiomDisplay'		= obsdrop
			return matrix INDICATOR_`axiomDisplay'		= I
		} 
		
		return matrix CS_price_`axiomDisplay'		= pnondrop
		return matrix CS_quantity_`axiomDisplay'	= qnondrop				

 	} /* Ends foreach ax */

 	********************
 	*** DISTRIBUTION ***
 	********************
 	if "`distribution'" != "" {
		
 		tempname gmat te
 		mata: newGMAT("`price'","`quantity'", `seed', `simulations')
	
 		matrix `gmat' = gamma_matrix
 		matrix `te' = total_expenditure
 		local rK = r(K)
 		local rT = r(T)

 		forvalues i = 1(1)`simulations' {

 			mata: genXS("`gmat'", `rT', `rK', "`te'", "`price'", `i')

 			foreach ax of local axioms {

 				local axiomDisplay = upper("`ax'")

 				** HMINDEX results
 				quietly hmindex, price("`price'") ///
 								 quantity("simulated_quantities") ///
 								 axiom("`ax'") 
 				quietly return list
				
 				* Number & fraction of violations
 				local HM_NUM = r(HM_NUM_`axiomDisplay')
 				local HM_FRAC = r(HM_FRAC_`axiomDisplay')

 				matrix `sim_`ax''[`i',1] = `HM_NUM'
 				matrix `sim_`ax''[`i',2] = `HM_FRAC'

 			} /* Ends foreach ax */

 		} /* Ends forvalues i */

 	} /* Ends if statement */

 	* Return list common for all axioms
 	return scalar OBS						= `obs'
 	return scalar GOODS						= `goods'
 	return local  AXIOM						"`allAxiomsDisplay'"

 	* Displaying output table
 	if "`distribution'" == "" {
 		matrix `generalInfoTable' = `obs', `goods'
 		matrix `generalInfoTable' = `generalInfoTable''
 		matrix rowname `generalInfoTable' = "	Number of obs		= " ///
 											"	Number of goods		= " 
 	}
 	else if "`distribution'" != "" {
 		matrix `generalInfoTable' = `obs', `goods', `simulations'
 		matrix `generalInfoTable' = `generalInfoTable''
 		matrix rowname `generalInfoTable' = "	Number of obs		= " ///
 											"	Number of goods		= " ///
 											"	Simulations 		= " 
 	}

 	matrix colname `generalInfoTable' = " "
 	matlist `generalInfoTable', border(none) lines(none) ///
 			format(%7.2g) names(rows) left(0) twidth(30)

 	matrix colnames `rawResults' = #HM %HM
 	matlist `rawResults', border(top bottom) rowtitle("Axiom")

 	if "`distribution'" != "" {

 		di " "
 		di as text "Summary statistics for simulations:"	

 		local allAxiomsDisplay ""
 		foreach ax of local axioms {

 			local axiomDisplay = upper("`ax'")

 			local allAxiomsDisplay "`allAxiomsDisplay' `axiomDisplay'"

 			* Summary stats table
 			tempvar HM_NUM HM_FRAC

 			mata: A = st_matrix("`sim_`ax''")

 			getmata (`HM_NUM' `HM_FRAC') = A, force

 			quietly tabstat `HM_NUM' `HM_FRAC', stat(mean sd min p25 ///
 					median p75 max) save

 			quietly return list 

 			matrix `sumStatsTable' = r(StatTotal)
 			matrix colnames `sumStatsTable' =	"#HM" "%HM"
 			matrix rownames `sumStatsTable' =	Mean "Std. Dev." Min ///
 													Q1 Median Q3 Max


 			matlist `sumStatsTable',	border(top bottom) ///
 										rowtitle("`axiomDisplay'")

 			* Return list for several axioms
 			return scalar SIM						= `simulations'
 			return local  AXIOM						"`allAxiomsDisplay'"
 			return matrix SIMRESULTS_`axiomDisplay'	= `sim_`ax''
 			return matrix SUMSTATS_`axiomDisplay'	= `sumStatsTable'

 		} /* Ends foreach ax */

 	}	/* Ends if statement */

 end

  
mata
/* ================================================================== */
					/* AXIOM 1: WGARP */
function adjmat_wgarp(string P_temp, string X_temp)
{
	P_mat = st_matrix(P_temp)
	X_mat = st_matrix(X_temp)
	
	T = rows(P_mat)
	
	// Create empty matrices DRP and SDRP of size T x T
	DRP = J(T, T, 0)
	SDRP = J(T, T, 0)
		// Looping over i and j
	for (i=1; i<= T; i++) {
		for (j=1; j<= T; j++) {
			if (P_mat[i,.] * (X_mat[i,.])' >= P_mat[i,.] * (X_mat[j,.])') {
			
				DRP[i,j] = 1
				
			  if (P_mat[i,.] * (X_mat[i,.])' > P_mat[i,.] * (X_mat[j,.])') {
					
					SDRP[i,j] = 1
				
				}		/* Ends if > */
			
			}		/* Ends if >= */
			
		}		/* Ends for j */
		
	}		/* Ends for i */
	
	
	// Computing edges
	A = J(T, T, 0)
	
	for (i=1; i<= T; i++) {
		
		for (j=1; j<= T; j++) {
			
			if (DRP[i,j]==1 & SDRP[j,i]==1) {
				
				A[i,j] = 1
				
			} /* Ends if */
		
		} /* Ends for j */
		
	}	/* Ends for i */

		
	st_matrix("AdjMat", A)
	
}
					/* AXIOM 1: WGARP */
/* ================================================================== */
/* ================================================================== */
					/* AXIOM 2: WARP */
function adjmat_warp(string P_temp, string X_temp)
{
	P_mat = st_matrix(P_temp)
	X_mat = st_matrix(X_temp)
	T = rows(P_mat)
	// Create empty matrices DRP of size T x T
	DRP = J(T, T, 0)		
	
	// Looping over i and j
	for (i=1; i<= T; i++) {
		for (j=1; j<= T; j++) {
			if (P_mat[i,.] * (X_mat[i,.])' >= P_mat[i,.] * (X_mat[j,.])') {
			
				DRP[i,j] = 1
				
			}		/* Ends if >= */
		}		/* Ends for j */
		
	}		/* Ends for i */
	// Computing edges
	A = J(T, T, 0)
	for (i=1; i<= T; i++) {
		
		for (j=1; j<= T; j++) {
		
			if (X_mat[i,.] != X_mat[j,.]) {
				if (DRP[i,j]==1 & DRP[j,i]==1) {
					
					A[i,j] = 1
					
				} /* Ends if */
			
			} /* Ends if */
			
		} /* Ends for j */
		
	}	/* Ends for i */
	st_matrix("AdjMat", A)
	
}
					/* AXIOM 2: WARP */
/* ================================================================== */
/* ================================================================== */
					/* TEST WGARP*/
void test_wgarp(string P_temp, string X_temp)
{
	real scalar PASS
	P_mat = st_matrix(P_temp)
	X_mat = st_matrix(X_temp)
	T = rows(P_mat)

	
	// Create empty matrices DRP and SDRP of size T x T
	DRP = J(T, T, 0)		/* J(rows, columns, values) */
	SDRP = J(T, T, 0)
	
	// Looping over i and j
	for (i=1; i<= T; i++) {
		for (j=1; j<= T; j++) {
			if (P_mat[i,.] * (X_mat[i,.])' >= P_mat[i,.] * (X_mat[j,.])') {
			
				DRP[i,j] = 1
				
			  if (P_mat[i,.] * (X_mat[i,.])' > P_mat[i,.] * (X_mat[j,.])') {
					
					SDRP[i,j] = 1
				
				}		/* Ends if > */
			
			}		/* Ends if >= */
			
		}		/* Ends for j */
		
	}		/* Ends for i */
	
	
	// Search for WARP violations
	PASS = 1
	for (i=1; i<= T; i++) {
		for (j=1; j<= T; j++) {
		
			if (j > i) {
				if (DRP[i,j] == 1 && SDRP[j,i] == 1) {
				
					PASS = 0
					
					break
					
					}		/* Ends if */
					
				else if (DRP[j,i] == 1 && SDRP[i,j] == 1) {
					
					PASS = 0
					
					break
					
					}		/* Ends if */
					
				}		/* Ends if */
			
			}		/* Ends for j */
	
		}		/* Ends for i */
		
	// Returning results
	st_numscalar("r(PASS)", PASS)
}
		
			
/* ================================================================== */
/* ================================================================== */
					/* TEST WARP*/
void test_warp(matrix P_temp, matrix X_temp)
{
	real scalar PASS
	P_mat = st_matrix(P_temp)
	X_mat = st_matrix(X_temp)
	T = rows(P_mat)
	
	// Create empty matrices DRP and SDRP of size T x T
	DRP = J(T, T, 0)		/* J(rows, columns, values) */
	SDRP = J(T, T, 0)
	
	// Looping over i and j
	for (i=1; i<= T; i++) {
		for (j=1; j<= T; j++) {
			if (P_mat[i,.] * (X_mat[i,.])' >= P_mat[i,.] * (X_mat[j,.])') {
			
				DRP[i,j] = 1
			}		/* Ends if >= */
			
		}		/* Ends for j */
		
	}		/* Ends for i */
		
	// Search for WARP violations	
	PASS = 1
	for (i=1; i<= T; i++) {
		for (j=1; j<= T; j++) {
		
			if (j > i) {
				
				if (X_mat[i,.] != X_mat[j,.]) {
					if (DRP[i,j] == 1 && DRP[j,i] == 1) {
					
						PASS = 0
						
						break
						
					}	/* Ends if */
				
				}	/* Ends if */
					
			}	/* Ends if */
			
		}	/* Ends for j */
	
	}	/* Ends for i */
	
	// Returning results
	st_numscalar("r(PASS)", PASS)
	
}				
		
/* ================================================================== */
/* ================================================================== */
					/* Submodule 1: Remove */
function remove(string AdjMat, string P_temp, string X_temp)
{
	
	P_mat = st_matrix(P_temp)
	X_mat = st_matrix(X_temp)
	
	T = rows(P_mat)
	Columns = cols(P_mat)
	
	AM = st_matrix(AdjMat)
	
	degs = rowsum(AM)
	
	
	maxdegs = max(degs)
	
	d = selectindex((degs:==maxdegs))
		
	dropV = J(T, 1, 0)
	for (i=1; i<=rows(d); i++) {
		j = d[i]
		
		Ai = selectindex(AM[j,.]:>0)
		
		Aidegs = degs[Ai]
		Ai1 = Aidegs:==1

		/* 
		Procedure 1: This procedure looks at the case when the set of maximal
		nodes is not a singleton. Consider node i. If the degree of node i is 
		greater than the degrees of all nodes adjacent to i, 
		[i.e., degs(i)>max(Aidegs)], then we drop node i.
		*/
		
		if (degs[j]>max(Aidegs)) {	 // if (a)
			
			dropV[j] = 1
			
		}
		/*
		Procedure 2: This procedure looks at the case when the set of maximal
		nodes is not a singleton. Consider node i. If the degree of node i is
		equal to the degree of a node h adjacent to node i, 
		[i.e., degs(i)==degs(h)], then we have three cases; see below.
		*/
		
		else {
		
			AiRows = rows(Ai')
			for (h=1; h<=AiRows; h++) {
	
				k = Ai[h]'
				if (degs[j]==degs[k] && j<k) {	// if (b)
					
					Ah = selectindex(AM[k,.]:>0)
					
					Ahdegs = degs[Ah]
					Ah1 = Ahdegs:==1
					
					if (any(Ah:==j)) {			// if (c)

						if (rows(Ai1) != 0) {		// if (d)
							
							dropV[j] = 1
							
						}
						else if (rows(Ah1)!=0) {
							dropV[k] = 1
						
						}
						
						else if (rows(Ai1)==0 && rows(Ah1)==0) {
							
							dropV[j] = 1
							
						}	// Ends if (d)
					
					}	// Ends if (c)
											
				}	// Ends if (b)
			}	// Ends for h
			
		}	// Ends if (a)
	
	}	// Ends for i
	
	
	// Matrices
	pd = P_mat[selectindex(dropV:==1),.]
	qd = X_mat[selectindex(dropV:==1),.]
		
	pnondrop = P_mat[selectindex(dropV:==0),.]
	qnondrop = X_mat[selectindex(dropV:==0),.]
	
	st_matrix("pd", pd)
	st_matrix("qd", qd)
	st_matrix("pnondrop", pnondrop)	
	st_matrix("qnondrop", qnondrop)

}

					/* Submodule 1: Remove */				
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
