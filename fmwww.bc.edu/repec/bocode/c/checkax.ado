*! Version 1.1.0 23november2020

/*
	Syntax:

	checkax, <Price> <Quantity> [<op1>] [<op2>]
		
		<op1> := AXiom[(string)]
			eWGARP
			eWARP
			eGARP	(Defualt)
			eSARP
			eHARP
			eCM
		<op2> := EFFiciency[(real 1)]

CAUTION: The option NOCHECK is not recommended if you are not a Stata programmer.
		NOCHECK is used in user-written Stata commands aei and powerps
		that depend on the checkax command. This option disallows checkax
		from controlling efficiency levels, matrix dimensions and values.
		This option was created solely for use in aei and powerps so as to
		speed up calculation and avoid checking the same things several times
		when looping over checkax.
*/

/* ================================================================== */

* Main program
program checkax, rclass sortpreserve
	version 15.1

	*User input
	syntax, Price(string) Quantity(string) ///
			[EFFiciency(real 1) AXiom(string) NOCHECK]

					*******************************
					*** Checking data structure ***
					***   and syntax validity   ***
					*******************************
	if ("`nocheck'"=="") {
		** Check nr 1:
		* Is efficiency within the allowed range?
		if `efficiency' <= 0 | `efficiency' > 1 {
			display as error 	" Efficiency() must be greater than 0 and " ///
								"equal to or less than 1."
			display as error 	" If not specified, the default setting" ///
								" for efficiency is 1."
			exit 198 /* "Invalid syntax --> range invalid" error */
		}

		* Is there at least one product with a non-zero quantity in every given period?
		mata: st_numscalar("r(nrz)", (min(rowsum(st_matrix("`quantity'")))==0 ? 1 : 0))
		if `r(nrz)' == 1 {
			display as error 	" The data contains observations" ///
			as error 			" with zero (or missing) quantities."
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
	}
	
	else if ("`nocheck'"!="") {
		/* No checks, move directly to calculations */
	}

	** Option nr 2:
	* Which axiom(s) does the user want to check?
	* And creating necessary scalars, vectors and tempnames accordingly.
	local tempname_prefix Pass Num_vio Frac_vio rawResults

	local axiom = lower("`axiom'")

	if ("`axiom'"=="")		local axiom egarp	/* eGARP set to default */
	
	if ("`axiom'"=="all")	local axiom egarp esgarp ewgarp esarp ewarp eharp ecm


	tokenize `axiom'
	local axioms "`1' `2' `3' `4' `5' `6' `7'"

	foreach ax of local axioms {

		if !inlist("`ax'", "egarp", "ewgarp", "esgarp", "esarp", "ewarp", "eharp", "ecm") {
			display as error 	" Axiom() must be either eGARP, eSGARP, eWGARP, eSARP, " ///
								"eWARP, eHARP or eCM; case-insensitive."
			display as error 	" If not specified, the default setting for " ///
								" Axiom() is eGARP."
			exit 198 /* "Invalid syntax --> range invalid" error */
		}
		
		else {
			
			foreach temp of local tempname_prefix {
			
				tempname `temp'_`ax'
			
			}
		
		}
		
	
	}

						**************
						*** AXIOMS ***
						**************

	local goods `=colsof(`price')'
	local obs 	`=rowsof(`price')'
		
	local first_ax = 1
	
	local allAxiomsDisplay ""
	
	tempname rawResults generalInfoTable
	
	foreach ax of local axioms {
		
		** Axioms that do not require FastFloyd
		if inlist("`ax'", "ewgarp", "ewarp") {
		
			mata: `ax'("`price'", "`quantity'", `efficiency')
			local PASS_`ax' = r(PASS)
			local NUM_VIO_`ax' = r(NUM_VIO)
			local FC_`ax': di %3.2f scalar(r(FRAC_VIO))
			local FRAC_VIO_`ax' = `FC_`ax''
			
		}

		** Axioms that do require FastFloyd
		else if inlist("`ax'", "esarp", "egarp", "esgarp", "eharp", "ecm") {
		
			mata: `ax'(&FastFloyd5(), "`price'", "`quantity'", `efficiency')
			local PASS_`ax' = r(PASS)
			local NUM_VIO_`ax' = r(NUM_VIO)
			local FC_`ax': di %3.2f scalar(r(FRAC_VIO))
			local FRAC_VIO_`ax' = `FC_`ax''
			
		}
	
		** Creating output & return list tables
		local axiomDisplay = "e" + upper(substr("`ax'", 2, strlen("`ax'") - 1))
		
		local allAxiomsDisplay "`allAxiomsDisplay' `axiomDisplay'"
			
		* Creating output table
		matrix `rawResults_`ax'' = `PASS_`ax'', `NUM_VIO_`ax'', `FRAC_VIO_`ax''
		matrix rowname `rawResults_`ax'' = "`axiomDisplay'"

		if 		`first_ax' == 1		matrix `rawResults' = `rawResults_`ax''
		else if `first_ax'  > 1		matrix `rawResults' = `rawResults' \ `rawResults_`ax''
			
		local first_ax = `first_ax' + 1
		
		
		* Return list for several axioms
		return scalar OBS						= `obs'
		return scalar GOODS						= `goods'
		return scalar EFF						= `efficiency'
		return scalar PASS_`axiomDisplay'		= `PASS_`ax''
		return scalar NUM_VIO_`axiomDisplay'	= `NUM_VIO_`ax''
		return scalar FRAC_VIO_`axiomDisplay'	= `FRAC_VIO_`ax''
		
	}
	
	return local  AXIOM						"`allAxiomsDisplay'"
		
	* Displaying output table
	
	matrix `generalInfoTable' = `obs', `goods', `efficiency'
	matrix `generalInfoTable' = `generalInfoTable''
	matrix rowname `generalInfoTable' = "	Number of obs		= " ///
										"	Number of goods		= " ///
										"	Efficiency level	= "
	matrix colname `generalInfoTable' = " "
	matlist `generalInfoTable', border(none) lines(none) ///
			format(%5.2g) names(rows) left(10) twidth(30)
	
	matrix colnames `rawResults' = Pass #vio %vio
	matlist `rawResults', border(top bottom) rowtitle("Axiom")

end

/* ================================================================== */
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
					/* FastFloyd */

function FastFloyd5(matrix A)
{

	// Step 1: Replacing zero with missing
	D =  editvalue(A, 0, .)

	// Step 2: Number of rows (or columns)
	T = rows(A)
	
	i2k = J(T, T, .)
	k2j = J(T, T, .)
	
	// Step 3: The loop	
	for (k=1; k<=T; k++) {
				i2k = J(1,T, D[.,k])
				k2j = J(T,1, D[k,.])
				
				i2kk2j = i2k+k2j
				
				// Evaluate strictness before replacing missing with zero
				i2kk2jGD = (D:<=i2kk2j)
				DGi2kk2j = (i2kk2j:<=D)
				DEi2kk2j = (D:==i2kk2j)

				// Replacing missing with zero in order to add and subtract properly
				_editmissing(D,0)
				_editmissing(i2kk2j,0)
				
				D = D:*i2kk2jGD + i2kk2j:*DGi2kk2j - D:*DEi2kk2j
	
				// Replacing zero with missing before the end of the loop
				_editvalue(D,0,.)
				_editvalue(i2kk2j,0,.)
				
	}

	// Step 4: Replacing missing with zero
	D = D :/ D
	
	_editmissing(D, 0)

	return(D)

}
					/* FastFloyd */
/* ================================================================== */


/* ================================================================== */
					/* AXIOM 1: eWGARP */

void ewgarp(string P_temp, string X_temp, scalar eff)
{
	real scalar NUM_VIO, PASS, FRAC_VIO

	P_mat = st_matrix(P_temp)
	X_mat = st_matrix(X_temp)

	T = rows(P_mat)
	
	// Create empty matrices DRP and SDRP of size T x T
	DRP = J(T, T, 0)		/* J(rows, columns, values) */
	SDRP = J(T, T, 0)

		// Looping over i and j
	for (i=1; i<= T; i++) {

		for (j=1; j<= T; j++) {

			if (eff * P_mat[i,.] * (X_mat[i,.])' >= P_mat[i,.] * (X_mat[j,.])') {
			
				DRP[i,j] = 1
				
			  if (eff * P_mat[i,.] * (X_mat[i,.])' > P_mat[i,.] * (X_mat[j,.])') {
					
					SDRP[i,j] = 1
				
				}		/* Ends if > */
			
			}		/* Ends if >= */
			

		}		/* Ends for j */
		
	}		/* Ends for i */
	
	
		// Search for WARP violations
	NUM_VIO = 0

	for (i=1; i<= T; i++) {

		for (j=1; j<= T; j++) {
		
			if (j > i) {

				if (DRP[i,j] == 1 && SDRP[j,i] == 1) {
				
					NUM_VIO++
				
					}		/* Ends if */
					
				else if (DRP[j,i] == 1 && SDRP[i,j] == 1) {
					
					NUM_VIO++
					
					}		/* Ends if */
					
				}		/* Ends if */
			
			}		/* Ends if j != i */

		}		/* Ends for j */
		
		/* Ends for i */

		
	// What is the fraction of violations?
		// Total violations
	TOT_VIO = T*(T-1)/2
	FRAC_VIO = NUM_VIO/TOT_VIO
	FRAC_VIO = FRAC_VIO*100
	
	// Has the data passed?
	PASS = 1

	if (NUM_VIO > 0) {
		PASS = 0
	}

	
	N = T * cols(P_mat)
	GOODS = cols(P_mat)
	
	// Returning results
	st_numscalar("r(PASS)", PASS)
	st_numscalar("r(NUM_VIO)", NUM_VIO)
	st_numscalar("r(FRAC_VIO)", FRAC_VIO)
	st_numscalar("r(GOODS)", cols(P_mat))
	st_numscalar("r(OBS)", T)
	st_numscalar("r(EFF)", eff)

}

					/* AXIOM 1: eWGARP */
/* ================================================================== */

/* ================================================================== */
					/* AXIOM 2: eWARP */ 

void ewarp(matrix P_temp, matrix X_temp, scalar eff)
{
	real scalar NUM_VIO
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

			if (eff*P_mat[i,.] * (X_mat[i,.])' >= P_mat[i,.] * (X_mat[j,.])') {
			
				DRP[i,j] = 1
				
			}		/* Ends if >= */
			

		}		/* Ends for j */
		
	}		/* Ends for i */


		// Search for WARP violations
	NUM_VIO = 0

	for (i=1; i<= T; i++) {

		for (j=1; j<= T; j++) {
		
			if (j > i) {
				
				if (X_mat[i,.] != X_mat[j,.]) {

					if (DRP[i,j] == 1 && DRP[j,i] == 1) {
					
						NUM_VIO++
					}
				}
					
			}		/* Ends if */
			
		}		/* Ends if j != i */
	}		/* Ends for j */
		
		/* Ends for i */
		

	// What is the fraction of violations?
		// Total violations
	TOT_VIO = T*(T-1)/2
	FRAC_VIO = NUM_VIO/TOT_VIO
	FRAC_VIO = FRAC_VIO*100
	
	// Has the data passed?
	PASS = 1

	if (NUM_VIO > 0) {
		PASS = 0
	}

	N = T * cols(P_mat)
	GOODS = cols(P_mat)

	// Returning results
	st_numscalar("r(PASS)", PASS)
	st_numscalar("r(NUM_VIO)", NUM_VIO)
	st_numscalar("r(FRAC_VIO)", FRAC_VIO)
	st_numscalar("r(GOODS)", cols(P_mat))
	st_numscalar("r(OBS)", T)
	st_numscalar("r(EFF)", eff)
	
}				
						
					/* AXIOM 2: eWARP */ 
/* ================================================================== */

/* ================================================================== */
					/* AXIOM 3: eSARP */
					
void esarp(pointer scalar FF, matrix P_temp, matrix X_temp, scalar eff)
{
			matrix	RP, DRP, SDRP
	real 	scalar 	NUM_VIO
	real 	scalar 	PASS
	
	P_mat = st_matrix(P_temp)
	X_mat = st_matrix(X_temp)


	T = rows(P_mat)	

	// Create empty matrices DRP and SDRP of size T x T
	DRP = J(T, T, 0)		/* J(rows, columns, values) */
	SDRP = J(T, T, 0)

	// Looping over i and j
	for (i=1; i<= T; i++) {

		for (j=1; j<= T; j++) {

			if (eff*P_mat[i,.] * (X_mat[i,.])' >= P_mat[i,.] * (X_mat[j,.])') {
			
				DRP[i,j] = 1
				
				if (eff*P_mat[i,.] * (X_mat[i,.])' > P_mat[i,.] * (X_mat[j,.])') {
					
					SDRP[i,j] = 1
				
				}		/* Ends if > */
				
			} 	/* Ends if >= */

		}		/* Ends for j */
		
	}		/* Ends for i */

	// Making RP-Matrix (Transitive Closure of DRP-Matrix)
	RP = (*FF)(DRP)
	
	// Search for WARP violations
	NUM_VIO = 0

	for (i=1; i<= T; i++) {

		for (j=1; j<= T; j++) {
		
			if (j != i) {
				
				if (X_mat[i,.] != X_mat[j,.]) {
					
					if (RP[i,j] == 1 && DRP[j,i] == 1) {
					
						NUM_VIO++
					}
									
				}		/* Ends [j,i] & [i,j] */
					
			}		/* Ends if */
			
		}		/* Ends if j != i */
	}		/* Ends for j */
		
		/* Ends for i */

	// What is the fraction of violations?
		// Total violations
	TOT_VIO = T*(T-1)
	FRAC_VIO = NUM_VIO/TOT_VIO
	FRAC_VIO = FRAC_VIO*100
	
	// Has the data passed?
	PASS = 1

	if (NUM_VIO > 0) {
		PASS = 0
	}

	N = T * cols(P_mat)
	GOODS = cols(P_mat)
	
	// Returning results
	st_numscalar("r(PASS)", PASS)
	st_numscalar("r(NUM_VIO)", NUM_VIO)
	st_numscalar("r(FRAC_VIO)", FRAC_VIO)
	st_numscalar("r(GOODS)", cols(P_mat))
	st_numscalar("r(OBS)", T)
	st_numscalar("r(EFF)", eff)


}	
					/* AXIOM 3: eSARP */ 
/* ================================================================== */

/* ================================================================== */
					/* AXIOM 4: eGARP */
					
void egarp(pointer scalar FF, matrix P_temp, matrix X_temp, scalar eff)
{
			matrix	RP, DRP, SDRP
	real 	scalar 	NUM_VIO
	real 	scalar 	PASS
	
	P_mat = st_matrix(P_temp)
	X_mat = st_matrix(X_temp)

	T = rows(P_mat)	

	// Create empty matrices DRP and SDRP of size T x T
	DRP = J(T, T, 0)		/* J(rows, columns, values) */
	SDRP = J(T, T, 0)

	// Looping over i and j
	for (i=1; i<= T; i++) {

		for (j=1; j<= T; j++) {

			if (eff*P_mat[i,.] * (X_mat[i,.])' >= P_mat[i,.] * (X_mat[j,.])') {
			
				DRP[i,j] = 1
				
				if (eff*P_mat[i,.] * (X_mat[i,.])' > P_mat[i,.] * (X_mat[j,.])') {
					
					SDRP[i,j] = 1
				
				}		/* Ends if > */
				
			} 	/* Ends if >= */

		}		/* Ends for j */
		
	}		/* Ends for i */

	// Making RP-Matrix (Transitive Closure of DRP-Matrix)
	RP = (*FF)(DRP)
	
	// Search for WARP violations
	NUM_VIO = 0

	for (i=1; i<= T; i++) {

		for (j=1; j<= T; j++) {
		
			if (j != i) {
				
				if (X_mat[i,.] != X_mat[j,.]) {
					
					if (RP[i,j] == 1 && SDRP[j,i] == 1) {
					
						NUM_VIO++
					}
				
				}		/* Ends [j,i] & [i,j] */
					
			}		/* Ends if */
			
		}		/* Ends if j != i */
	}		/* Ends for j */
		
		/* Ends for i */

	// What is the fraction of violations?
		// Total violations
	TOT_VIO = T*(T-1)
	FRAC_VIO = NUM_VIO/TOT_VIO
	FRAC_VIO = FRAC_VIO*100
	
	// Has the data passed?
	PASS = 1

	if (NUM_VIO > 0) {
		PASS = 0
	}


	N = T * cols(P_mat)
	GOODS = cols(P_mat)
	
	// Returning results
	st_numscalar("r(PASS)", PASS)
	st_numscalar("r(NUM_VIO)", NUM_VIO)
	st_numscalar("r(FRAC_VIO)", FRAC_VIO)
	st_numscalar("r(GOODS)", cols(P_mat))
	st_numscalar("r(OBS)", T)
	st_numscalar("r(EFF)", eff)

}	
				
					/* AXIOM 4: eGARP */ 
/* ================================================================== */

/* ================================================================== */
					/* AXIOM 5: eHARP */
function eharp(pointer scalar ff, matrix P_temp, matrix X_temp, scalar eff)
{
	real 	scalar 	NUM_VIO, PASS, T, K
	real 	matrix	C, R

	P_mat = st_matrix(P_temp)
	X_mat = st_matrix(X_temp)

	T = rows(P_mat)
	K = cols(P_mat)
	
	temp1 = J(K, 1, 1)
	
	E = (P_mat:*X_mat)*temp1
	
	temp2 = J(1,K, eff*E)
	
	P_mat = P_mat:/temp2

	// Cost-matrix
	C = J(T, T, 0)

	// Looping over i and j
	for (i=1; i<= T; i++) {

		for (j=1; j<= T; j++) {

			if (i!=j) {

				C[i,j] = log(P_mat[i,.]*X_mat[j,.]')
				
			}	/* Ends if */	
			
		}	/* Ends for j */
		
	}	/* Ends for i */

	
	// Floy-Warshall algorithm
	R = C
	
	// Looping over i and j
	for (i=1; i<= T; i++) {

		for (j=1; j<= T; j++) {

			for (k=1; k<=T; k++) {
					
				if (R[j,k] > R[j,i] + R[i,k]) {
					
					R[j,k] = R[j,i] + R[i,k]
					
				}	/* Ends if */
				
			}	/* Ends for k*/
			
		}	/* Ends for j */
		
	}	/* Ends for i */

	
		// Search for WARP violations
	NUM_VIO = 0

	for (i=1; i<= T; i++) {
		if (R[i,i] < 0) {
			
			NUM_VIO++
			
		}	/* Ends if*/

	}	/* Ends for i */ 
		
		
	// What is the fraction of violations?
		// Total violations
	TOT_VIO = T
	FRAC_VIO = NUM_VIO/TOT_VIO
	FRAC_VIO = FRAC_VIO*100
	
	// Has the data passed?
	PASS = 1

	if (NUM_VIO > 0) {
		PASS = 0
	}

	N = T * cols(P_mat)
	GOODS = cols(P_mat)
	
	// Returning results
	st_numscalar("r(PASS)", PASS)
	st_numscalar("r(NUM_VIO)", NUM_VIO)
	st_numscalar("r(FRAC_VIO)", FRAC_VIO)
	st_numscalar("r(GOODS)", cols(P_mat))
	st_numscalar("r(OBS)", T)
	st_numscalar("r(EFF)", eff)

}

					/* AXIOM 5: eHARP */ 
/* ================================================================== */

				
/* ================================================================== */
					/* AXIOM 6: eCM */ 
function ecm(pointer scalar ff, matrix P_temp, matrix X_temp, scalar eff)
{
	real 	scalar 	NUM_VIO, PASS, T, K
	real 	matrix	C, R

	P_mat = st_matrix(P_temp)
	X_mat = st_matrix(X_temp)

	T = rows(P_mat)
	K = cols(P_mat)

	// Cost-matrix
	C = J(T, T, 0)

	// Looping over i and j
	for (i=1; i<= T; i++) {

		for (j=1; j<= T; j++) {

			if (i!=j) {

				C[i,j] = P_mat[i,.]*(X_mat[j,.]' - eff * X_mat[i,.]')
				
			}	/* Ends if */
			
		}	/* Ends for j */
		
	}	/* Ends for i */


	// Floy-Warshall algorithm
	R = C
	
	// Looping over i and j
	for (i=1; i<= T; i++) {

		for (j=1; j<= T; j++) {

			for (k=1; k<=T; k++) {
					
				if (R[j,k] > R[j,i] + R[i,k]) {
					
					R[j,k] = R[j,i] + R[i,k]
					
				}	/* Ends if */
				
			}	/* Ends for k*/
			
		}	/* Ends for j */
		
	}	/* Ends for i */

	
		// Search for WARP violations
	NUM_VIO = 0

	for (i=1; i<= T; i++) {
		if (R[i,i] < 0) {
			
			NUM_VIO++
			
		}	/* Ends if*/

	}	/* Ends for i */ 
		
		
	// What is the fraction of violations?
		// Total violations
	TOT_VIO = T
	FRAC_VIO = NUM_VIO/TOT_VIO
	FRAC_VIO = FRAC_VIO*100
	
	// Has the data passed?
	PASS = 1

	if (NUM_VIO > 0) {
		PASS = 0
	}

	N = T * cols(P_mat)
	GOODS = cols(P_mat)
	
	// Returning results
	st_numscalar("r(PASS)", PASS)
	st_numscalar("r(NUM_VIO)", NUM_VIO)
	st_numscalar("r(FRAC_VIO)", FRAC_VIO)
	st_numscalar("r(GOODS)", cols(P_mat))
	st_numscalar("r(OBS)", T)
	st_numscalar("r(EFF)", eff)
	
}		
					/* AXIOM 6: eCM */ 
/* ================================================================== */


/* ================================================================== */
					/* AXIOM 7: eSGARP */ 
void esgarp(pointer scalar FF, matrix P_temp, matrix X_temp, scalar eff)
{
			matrix	RP, DRP, SDRP
	real 	scalar 	NUM_VIO
	real 	scalar 	PASS
	
	p = st_matrix(P_temp)
	x = st_matrix(X_temp)
	
	T = rows(p)
	K = cols(p)
	Q = factorial(K)
	
	seq = J(1, 1, 1::K)
	
	pu = J(0,K,.)
	
	info = cvpermutesetup(seq)
	while ((p0=cvpermute(info)) != J(0,1,.)) {
		pu = pu\p0'
	}
	

	// Create empty matrices DRP and SDRP of size T x T
	DRP = J(T, T, 0)		/* J(rows, columns, values) */
	SDRP = J(T, T, 0)

	// Looping over i and j
	for (i=1; i<= T; i++) {

		for (j=1; j<= T; j++) {

			for (q=1; q<= Q; q++) {
				
				if (eff*p[i,.] * (x[i,.])' >= p[i,.] * (x[j,pu[q,.]])') {
					
					DRP[i,j] = 1
									
					if (eff*p[i,.] * (x[i,.])' > p[i,.] * (x[j,pu[q,.]])') {
						
						SDRP[i,j] = 1

					}		/* Ends if > */
					
				} 	/* Ends if >= */
				
				if (SDRP[i,j] == 1) 	break 	/* Breaks q loop */
				
			} 	/* Ends for q */
			
		}	/* Ends for j */
		
	}	/* Ends for i */
	
	// Making RP-Matrix (Transitive Closure of DRP-Matrix)
	RP = (*FF)(DRP)

	// Search for WARP violations
	NUM_VIO = 0

	for (i=1; i<= T; i++) {

		for (j=1; j<= T; j++) {
		
			if (RP[i,j] == 1 && SDRP[j,i] == 1) {
					
				NUM_VIO++
					
			}		/* Ends if */
			
		}	/* Ends for j */
	
	}	/* Ends for i */
		
		

	
	// What is the fraction of violations?
		// Total violations
	TOT_VIO = T*T
	FRAC_VIO = NUM_VIO/TOT_VIO
	FRAC_VIO = FRAC_VIO*100

	
	// Has the data passed?
	PASS = 1

	if (NUM_VIO > 0) {
		PASS = 0
	}

	N = T * cols(P_mat)
	GOODS = cols(P_mat)
	
	// Returning results
	st_numscalar("r(PASS)", PASS)
	st_numscalar("r(NUM_VIO)", NUM_VIO)
	st_numscalar("r(FRAC_VIO)", FRAC_VIO)
	st_numscalar("r(GOODS)", cols(P_mat))
	st_numscalar("r(OBS)", T)
	st_numscalar("r(EFF)", eff)

}	
				
					/* AXIOM 7: eSGARP */ 
/* ================================================================== */



end 
