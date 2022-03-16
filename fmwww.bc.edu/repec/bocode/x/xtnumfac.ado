capture program drop xtnumfac
program define xtnumfac, eclass
syntax varlist(max=1 ts /*ts added by JD*/ ) [if] [in] [, kmax(integer 8) STANdardize(integer 1) Detail]
version 11.2


marksample touse


* Error messages
	qui xtset 	
	if "`r(balanced)'" ~= "strongly balanced" {
	display as error "Dataset must be balanced for this program to work."
	exit
	} 


	if `kmax' < 1 {
	display as error "Maximum number of factors needs to be at least 1."
	exit
	}	

	

* Extract panel identifiers and panel size	
	qui xtset
	local timevar  = r(timevar)
	local panelvar = r(panelvar)
	qui tab `timevar' if `touse'
	ereturn scalar T = r(r)
	qui tab `panelvar' if `touse'
	ereturn scalar N = r(r)	

	
* Get results 
	mata: mainroutine(st_data(., "`varlist'", "`touse'"), st_numscalar("e(N)"), st_numscalar("e(T)"), strtoreal(st_local("kmax")), strtoreal(st_local("standardize")))


* Report results
if !missing("`detail'") {
/*
	di as result _newline "Statistics for number of common factors in `varlist'" _col(80) as text "N = `e(N)'; T = `e(T)'" 
	di ""
	di as text "{hline 11}{c TT}{hline 108}" 	
	di as result _col(2) "# factors " "{c |}" _col(15) "PC_{p1}" _col(27)  "PC_{p2}" _col(39)  "PC_{p3}" _col(51)  "IC_{p1}" _col(63) "IC_{p2}" _col(75) "IC_{p3}" _col(90) "ER"  _col(102) "GR" _col(114) "GOL"
	di as text "{hline 11}{c +}{hline 108}" 	
	di as text "{hline 11}{c +}{hline 108}" 	
	forvalues k = 0(1)`kmax' {
		forvalues myIC = 1(1)6 {
			if `k'== best_numfac[1,`myIC'] {
				local tempIC`myIC' : display %6.3f allICs[`k'+1,`myIC']
				local tempIC`myIC' `tempIC`myIC''*
			} 
			else {
				local tempIC`myIC' : display %6.3f allICs[`k'+1,`myIC']
				local tempIC`myIC' `tempIC`myIC'' " "				
			}
		}
		
		di as text %6s "`k'" _col(12) "{c |}" %12s "`tempIC1'" %12s "`tempIC2'" %12s "`tempIC3'" ///
		%12s "`tempIC4'" %12s "`tempIC5'" %12s "`tempIC6'" %12s "`tempIC7'" ///
		%12s "`tempIC8'" %12s "`tempIC9'"
	}
	di as text "{hline 11}{c BT}{hline 108}" 
	di as text "*: number of factors " ///
	   as text "{ul:chosen}" ///
       as text " by respective estimator."
	di as text _col(4) "PC_{p1},...,IC_{p3} from Bai and Ng (2002); ER, GR from Ahn and Horenstein (2013); GOL from Gagliardini, Ossola, Scaillet (2019)"
	*/
	di as result _newline "Statistics for number of common factors in `varlist'" 
	di as result _col(71) as text "N" _col(73) "=" _col(76) %9.0g `e(N)'
	di as result _col(71) as text "T" _col(73) "=" _col(76) %9.0g `e(T)'
	di ""
	di as text "{hline 11}{c TT}{hline 76}" 	
	di as result _col(2) "# factors " "{c |}" _col(19) "PC_{p1}" _col(31)  "PC_{p2}" _col(43)  "PC_{p3}" _col(55)  "IC_{p1}" _col(67) "IC_{p2}" _col(79) "IC_{p3}" 	
	di as text "{hline 11}{c +}{hline 76}" 	
	forvalues k = 0(1)`kmax' {
		forvalues myIC = 1(1)6 {
			if `k'== best_numfac[1,`myIC'] {
				local tempIC`myIC' : display %6.3f allICs[`k'+1,`myIC']
				local tempIC`myIC' `tempIC`myIC''*
			} 
			else {
				local tempIC`myIC' : display %6.3f allICs[`k'+1,`myIC']
				local tempIC`myIC' `tempIC`myIC'' " "				
			}
		}
		
		di as text %6s "`k'" _col(12) "{c |}" %12s "`tempIC1'" %12s "`tempIC2'" %12s "`tempIC3'" ///
		%12s "`tempIC4'" %12s "`tempIC5'" %12s "`tempIC6'" %12s 
	}
	di as text "{hline 11}{c BT}{hline 76}" 
	di as text "{hline 11}{c TT}{hline 76}" 	
	di as result _col(2) "# factors " "{c |}" _col(19) "ER" _col(31)  "GR" _col(43)  "GOL" 	
	di as text "{hline 11}{c +}{hline 76}" 	
	forvalues k = 0(1)`kmax' {
		forvalues myIC = 7(1)9 {
			if `k'== best_numfac[1,`myIC'] {
				local tempIC`myIC' : display %6.3f allICs[`k'+1,`myIC']
				local tempIC`myIC' `tempIC`myIC''*
			} 
			else {
				local tempIC`myIC' : display %6.3f allICs[`k'+1,`myIC']
				local tempIC`myIC' `tempIC`myIC'' " "				
			}
		}
		
		di as text %6s "`k'" _col(12) "{c |}" %12s "`tempIC7'" %12s "`tempIC8'" %12s "`tempIC9'" 
	}
	di as text "{hline 11}{c BT}{hline 76}" 
	di as result "`kmax'" ///
	   as text " factors maximally considered."
	di as text "PC_{p1},...,IC_{p3} from Bai and Ng (2002)"
	di as text "ER, GR from Ahn and Horenstein (2013)"
	di as text "ED from Onatski (2010)"
	di as text "GOL from Gagliardini, Ossola, Scaillet (2019)"

}
else {
	/*
	di as result _newline "Estimated number of common factors in `varlist'" 
	di as text "N = `e(N)'; T = `e(T)'" 
	di ""
	di as text "{hline 11}{c TT}{hline 98}" 	
	di as result _col(12)  "{c |}" _col(15) "PC_{p1}" _col(25)  "PC_{p2}" _col(35)  "PC_{p3}" _col(45)  "IC_{p1}" _col(55) "IC_{p2}" _col(65) "IC_{p3}" _col(77) "ER"  _col(87) "GR" _col(97) "GOL" _col(107) "ED"
	di as text "{hline 11}{c +}{hline 98}" 	
	di _continue as text %6s _col(2) "# factors " "{c |}" 
	di as result %6.0f best_numfac[1,1] %10.0f best_numfac[1,2] %10.0f best_numfac[1,3] ///
	   %10.0f best_numfac[1,4] %10.0f best_numfac[1,5] %10.0f best_numfac[1,6] %10.0f best_numfac[1,7] ///
	   %10.0f best_numfac[1,8] %10.0f best_numfac[1,9] %10.0f best_numfac[1,10]
	di as text "{hline 11}{c BT}{hline 98}"  
	di as result "`kmax'" ///
	   as text " factors maximally considered."
	di as text "PC_{p1},...,IC_{p3} from Bai and Ng (2002); ER, GR from Ahn and Horenstein (2013);"
	di as text "ED from Onatski (2010)"
	di as text "GOL from Gagliardini, Ossola, Scaillet (2019)"

	*/
	local l1 10
	local l2 13
	local l3 10
	local l4 13

	di as result _newline "Estimated number of common factors in `varlist'" 
	di as result _col(`=`l1'+`l2'+`l3'+3') as text "N" _col(`=`l1'+`l2'+`l3'+6') "=" _col(`=`l1'+`l2'+`l3'+8') %9.0g `e(N)'
	di as result _col(`=`l1'+`l2'+`l3'+3') as text "T" _col(`=`l1'+`l2'+`l3'+6') "=" _col(`=`l1'+`l2'+`l3'+8') %9.0g `e(T)'
	
	di as text "{hline `l1'}{c TT}{hline `l2'}{c TT}{hline `l3'}{c TT}{hline `l4'}"
	di as text _col(2) "IC" _col(`=`l1'+1') "{c |} # factors" _col(`=`l1'+`l2'+2')"{c |}" _col(`=`l1'+`l2'+5') "IC" _col(`=`l1'+`l2'+`l3'+3') "{c |} # factors"
	di as text "{hline `l1'}{c +}{hline `l2'}{c +}{hline `l3'}{c +}{hline `l4'}"
	di 	as text " PC_{p1}" _col(`=`l1'+1') "{c |}" as result %6.0f best_numfac[1,1] ///
		as text _col(`=`l1'+`l2'+2')"{c |}  IC_{p1}" _col(`=`l1'+`l2'+`l3'+3') "{c |}" as result %6.0f best_numfac[1,4]

	di 	as text " PC_{p2}" _col(`=`l1'+1') "{c |}" as result %6.0f best_numfac[1,2] ///
		as text _col(`=`l1'+`l2'+2')"{c |}  IC_{p2}" _col(`=`l1'+`l2'+`l3'+3') "{c |}" as result %6.0f best_numfac[1,5]

	di 	as text " PC_{p3}" _col(`=`l1'+1') "{c |}" as result %6.0f best_numfac[1,3] ///
		as text _col(`=`l1'+`l2'+2')"{c |}  IC_{p3}" _col(`=`l1'+`l2'+`l3'+3') "{c |}" as result %6.0f best_numfac[1,6]

	di 	as text " ER" _col(`=`l1'+1') "{c |}" as result %6.0f best_numfac[1,7] ///
		as text _col(`=`l1'+`l2'+2')"{c |}  GR" _col(`=`l1'+`l2'+`l3'+3') "{c |}" as result %6.0f best_numfac[1,8]

	di 	as text " GOL" _col(`=`l1'+1') "{c |}" as result %6.0f best_numfac[1,9] ///
		as text _col(`=`l1'+`l2'+2')"{c |}  ED" _col(`=`l1'+`l2'+`l3'+3') "{c |}" as result %6.0f best_numfac[1,10]
	di as text "{hline `l1'}{c BT}{hline `l2'}{c BT}{hline `l3'}{c BT}{hline `l4'}"

	di as result "`kmax'" ///
	   as text " factors maximally considered."
	di as text "PC_{p1},...,IC_{p3} from Bai and Ng (2002)"
	di as text "ER, GR from Ahn and Horenstein (2013)"
	di as text "ED from Onatski (2010)"
	di as text "GOL from Gagliardini, Ossola, Scaillet (2019)"

}
end


*********************************************************************************


mata

// mata drop mainroutine()
function mainroutine(real matrix data, real scalar N, real scalar T, kmax, stan)  {
	real matrix X, allICs
	real rowvector best_numfac
	
// Reshape to wide format	
	X        = colshape(data', T)'	
	
	
// Add if-clauses for standardization options	
	if (stan == 2 | stan == 3) X = X - J(T,1,1)*mean(X)

	if (stan == 4 | stan == 5) X = X - J(T,1,1)*mean(X) - mean(X')'*J(1,N,1) + J(T,1,1)*mean(vec(X))*J(1,N,1)
	
	if (stan == 3 | stan == 5) {
	X_sd = sqrt(diagonal(quadvariance(X)))
	X = X :/(J(T,1,1)*X_sd')
	}
			

// Call interior functions to get all IC values and chosen num of factors	
	allICs0      = numfac_int(X,kmax)
	best_numfac0 = bestnum_ic_int(allICs0[1..9,])
	best_numfac = (best_numfac0, allICs0[10,1])
	allICs      = allICs0[1..9,]

// Pass results to Stata
	st_matrix("e(allICs)", allICs')
	st_matrix("e(best_numfac)", best_numfac)	
	st_numscalar("e(kmax)", kmax)
	st_matrix("allICs", allICs')
	st_matrix("best_numfac", best_numfac)

// matrix col and row names (by JD)
	cnames = (J(9,1,"") , ("PC_{p1}" \ "PC_{p2}" \ "PC_{p3}" \ "IC_{p1}" \ "IC_{p2}" \ "IC_{p3}" \ "ER" \ "GR" \ "GOL"))
	rnames = (J(kmax+1,1,""), strofreal(0::kmax))
	
	st_matrixrowstripe("e(allICs)",rnames)
	st_matrixcolstripe("e(allICs)",cnames)

	st_matrixcolstripe("e(best_numfac)",(cnames \ ("", "ED") ))
	st_matrixrowstripe("e(best_numfac)",("","k*"))
}


// mata drop numfac_int()
function numfac_int(X0, kmax0)  {
// numfac_int calculates the Bai&Ng (2002) and Ahn&Horenstein (2013) ICs for 
// the number of factors.
// It has two inputs:
//   X0:    A TxN matrix containing the data of interest.
//   kmax0: The maximum number of factors to consider.
// The output is a matrix providing the IC values for factor models with 
// k=1,2,...,kmax0 factors in its rows. The columns correspond to the following
// statistics: 1:PC_p1,...,6:IC_p3, 7:ER, 8:GR, 9: GOL
	T     = rows(X0)
	N     = cols(X0)
    minNT = min((N, T))
	
	if (T > N) {
			xx         = cross(X0,X0)
            fullsvd(xx:/(N*T), junk1, mus, junk2) // N x N
        } 
	else {  
			xx         = cross(X0',X0')
            fullsvd(xx:/(N*T), junk1, mus ,junk2) // T x T	 
	}	

// NOTE: Due to the equality of mean squared residuals and cumulative 
// eigenvalues, this function requires neither the estimation of SSR nor a 
// factor estimate.     
    
// Bai&Ng factor estimate first
    PC_ICs    = J(3,kmax0,.)
    IC_ICs    = J(3,kmax0,.)
    V_val     = J(1,kmax0+1,.)
    // These are the three penalties (without mm0 or the estimate of sig2)
    penalties = ((N+T)/(N*T)*ln((N*T)/(N+T)) \ (N+T)/(N*T)*ln(minNT) \ ln(minNT)/minNT)
	
    for (mm0=kmax0; mm0>=1; mm0--) {
       V_val[mm0]    = sum(mus[mm0+1..minNT])
       PC_ICs[.,mm0] = J(3,1,V_val[mm0]) + penalties*mm0*V_val[kmax0]
       IC_ICs[.,mm0] = J(3,1,ln(V_val[mm0])) + penalties*mm0
    }
	
	
    V_val[kmax0+1] = sum(mus[kmax0+2..minNT])
    V0               = mean(vec(X0):^2)
    PC_ICs           = (J(3,1,V0), PC_ICs)
    IC_ICs           = (J(3,1,ln(V0)), IC_ICs)
	
// Now do Ahn&Horenstein
    ER       = J(1,kmax0,.)
    GR       = J(1,kmax0,.)
    mutildes = (J(1,kmax0,.), mus[kmax0+1]/V_val[kmax0+1])
    for (mm1=kmax0; mm1>=1; mm1--) {
         ER[mm1]       = mus[mm1]/mus[mm1+1]
         mutildes[mm1] = mus[mm1]/V_val[1,mm1]
         GR[mm1]       = ln(1+mutildes[mm1])/ln(1+mutildes[mm1+1])
    }
    mockEV      = V0/ln(minNT);
    ER          = (mockEV/mus[1], ER)
    GR          = (ln(1 + mockEV)/ln(1+ mutildes[1]), GR)
	
// Now do Onatski
	mus_o    = mus*N
	jay      = kmax0+1
	ED       = -4
	ED_old   = -2
	
	while (ED_old != ED) 
	{
		y_delt    = mus_o[jay..(jay+4)]
		x_delt    = J(5,1,1)
		x_delt    = (x_delt, (((jay-1)..(jay+3))'):^(2/3))
		bet_delt  = qrsolve(x_delt,y_delt)
		delta     = 2*abs(bet_delt[2,1])
	
		lamdiff   = mus_o[1..(jay-1)] - mus_o[2..jay]
		ED_old    = ED
		del_check = (lamdiff :> delta)'
		intlist   = 1..(jay-1)
		intlist2  = intlist:*del_check
		ED        = max(intlist2)				
		jay       = ED+1
	}
	ED      = (ED, J(1,kmax0,.))
	

// Now do GOL
// penalty is g(n,t), p. 512
	penalty = (sqrt(N)+sqrt(T))^2/(N*T) * ln(N*T / (sqrt(N)+sqrt(T))^2 )
	GOL = (mus[1..kmax0+1] :- penalty)'
	allICs0 = (PC_ICs\ IC_ICs\ ER\ GR\ GOL\ED)

	return(allICs0)
}

// mata drop bestnum_ic_int()
function bestnum_ic_int(allICs1) 
{
// bestnum_ic_int picks an estimate for the number of factors from a matrix with IC
// values for n increasing number of factors (starting at 0).
// The function has one input:
//   - allICs1: a matrix containing the ICs corresponding to different
//              numbers of factors (in cols) for different ICs (rows).  
//              We assume that the first 6 rows are the Bai&Ng ICs whereas 
//              rows 7 and 8 are those of Ahn and Horenstein;
//				row 9 is the selection criterion used by GOL.
// The function output is a 1x8 vector of estimates for the number of factors.
	best_numfac0 = J(1,9,.)
	tempmin     = .
	for (jj=1; jj<=6; jj++) {
		minindex(allICs1[jj,.], 1, tempmin, junk1)
		best_numfac0[jj] = tempmin-1
    }	
	for (jj=7; jj<=8; jj++) {
		maxindex(allICs1[jj,.], 1, tempmin, junk1)
		best_numfac0[jj] = tempmin-1
    }
// selection rule for number of factors is: first number for which the difference is smaller than zero. 
// Here we count how many are larger than zero, which is eqaul to k(min|stat<0) because we have possibility of no factors as well.
    best_numfac0[9] = sum(allICs1[9,.]:>0)

	return(best_numfac0)
}
end

