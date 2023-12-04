*! xtnumfac
*! v. 1.2 - 29.11.2023
capture program drop xtnumfac
program define xtnumfac, eclass 
syntax varlist(min=1 ts  ) [if] [in] [, kmax(integer 8) STANdardize(integer 1) Detail]
version 11.2


marksample touse, novarlist

preserve	

* Error messages
	if `kmax' < 1 {
		display as error "Maximum number of factors needs to be at least 1."
		exit
	}	

	if `standardize' > 5 | `standardize' < 1 {
		display as error "Value for standardize out of range. Values must lie between 1 and 5."
		exit
	}

* keep only touse data
	qui keep if `touse'

* TS/XT information
	cap _xt
	if _rc != 0 {
		tempvar idvar
		gen `idvar' = 1
		qui tsset
		qui xtset `idvar' `r(timevar)'
	}
	qui xtset 		
	local timevar  `r(timevar)'
	local panelvar `r(panelvar)'
	local isbalanced = ("`r(balanced)'" == "strongly balanced" )

* balance dataset
	if `isbalanced' == 0 {
		** get T min, T bar and T max
		tempvar numT
		qui by `panelvar' (`timevar'), sort: gen `numT' = _N 
		qui sum `numT'
		local Tmin = r(min)
		local Tbar = r(mean)
		local Tmax = r(max)

		*** balance panel 
		qui tsfill, full
	}

	*** clear ereturn
	ereturn clear

	qui tab `timevar' 
	ereturn scalar T = r(r)
	qui tab `panelvar' 
	ereturn scalar N_g = r(r)
	ereturn scalar N = r(N)	

	if `c(version)' >= 13 local hid `hidden'

	if `isbalanced' == 0 {
		ereturn `hid' scalar Tbar = `Tbar'
		ereturn `hid' scalar Tmin = `Tmin'
		ereturn `hid' scalar Tmax = `Tmax'
	}
		
	
	
* Get results 
noi mata: mainroutine(st_data(., "`varlist'"), st_numscalar("e(N_g)"), st_numscalar("e(T)"), strtoreal(st_local("kmax")), strtoreal(st_local("standardize")))




restore

* Report results
if !missing("`detail'") {

	local h1 = 4
	local h2 = 25
	local h3 = 50
	local h4 = 70

	local l1 = 16
	local l2 = 27
	local l3 = 38
	local l4 = 49
	local l5 = 60
	local l6 = 71
	local l7 = `l1' + 3
	local l8 = `l2' + 3
	local l9 = `l3' + 3

	di as result _newline "Statistics for number of common factors in `varlist'" 
	if `isbalanced' == 1 {
		dis as text _col(`h1') "Number of obs" 		_col(`h2') "=" as result %9.0g `e(N)' 	_col(`h3') as text 	"Obs per group"		_col(`h4') "=" %9.0g `e(T)'
		dis as text _col(`h1') "Number of groups" 		_col(`h2') "=" as result %9.0g `e(N_g)'	_col(`h3') as text 	"Number of variables" 	_col(`h4') "=" %9.0g `e(k)'
	}
	else {
		dis as text																							_col(`=`h3'-3') "Obs per group:"		
		dis as text _col(`h1') "Number of obs" 			_col(`h2') "=" %9.0g as result `e(N)'		as text	_col(`h3') "min"					_col(`h4') "=" as result %9.0f `e(Tmin)'
		dis as text _col(`h1') "Number of groups" 		_col(`h2') "=" %9.0g as result `e(N_g)'		as text	_col(`h3') "avg"					_col(`h4') "=" as result %9.2f `e(Tbar)'
		dis as text _col(`h1') "Number of variables" 	_col(`h2') "=" %9.0g as result `e(k)'		as text	_col(`h3') "max"					_col(`h4') "=" as result %9.0f `e(Tmax)'
	}
	*di as result _col(71) as text "N" _col(73) "=" _col(76) %9.0g `e(N)'
	*di as result _col(71) as text "T" _col(73) "=" _col(76) %9.0g `e(T)'
	di ""
	di as text "{hline 11}{c TT}{hline 69}" 	
	di as result _col(2) "# factors " "{c |}" _col(`l1') "PC_{p1}" _col(`l2')  "PC_{p2}" _col(`l3')  "PC_{p3}" _col(`l4')  "IC_{p1}" _col(`l5') "IC_{p2}" _col(`l6') "IC_{p3}" 	
	di as text "{hline 11}{c +}{hline 69}" 	
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
		
		di as text %6s "`k'" _col(12) "{c |}" %11s "`tempIC1'" %11s "`tempIC2'" %11s "`tempIC3'" ///
		%11s "`tempIC4'" %11s "`tempIC5'" %11s "`tempIC6'" %11s 
	}
	di as text "{hline 11}{c BT}{hline 69}" 
	di as text "{hline 11}{c TT}{hline 69}" 	
	di as result _col(2) "# factors " "{c |}" _col(`l7') "ER" _col(`l8')  "GR" _col(`l9')  "GOS" 	
	di as text "{hline 11}{c +}{hline 69}" 	
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
		
		di as text %6s "`k'" _col(12) "{c |}" %11s "`tempIC7'" %11s "`tempIC8'" %11s "`tempIC9'" 
	}
	di as text "{hline 11}{c BT}{hline 69}" 
	di as result "`kmax'" ///
	   as text " factors maximally considered."
	di as text "PC_{p1},...,IC_{p3} from Bai and Ng (2002)"
	di as text "ER, GR from Ahn and Horenstein (2013)"
	di as text "ED from Onatski (2010)"
	di as text "GOS from Gagliardini, Ossola, Scaillet (2019)"

}
else {
	
	local l1 10
	local l2 13
	local l3 10
	local l4 13
	if `isbalanced' == 1 {
		dis as text _col(2) "N" 	_col(6)	as result 	"=" %9.0g `e(N)' 	as text _col(`=`l1'+`l2'+`l3'') "T"			_col(`=`l1'+`l2'+`l3'+7') "=" as result %9.0g `e(T)'
		dis as text _col(2) "N_g" 	_col(6)	as result 	"=" %9.0g `e(N_g)'	as text _col(`=`l1'+`l2'+`l3'') "vars." 		_col(`=`l1'+`l2'+`l3'+7') "=" as result %9.0g `e(k)'
	}
	else {
		dis as text																		_col(`=`l1'+`l2'+`l3'-3') "Obs per group:"		
		dis as text _col(2) "N" 		_col(8) "=" as result	%9.0g `e(N)'	as text	_col(`=`l1'+`l2'+`l3'') "min"		_col(`=`l1'+`l2'+`l3'+7') "=" as result %9.0f `e(Tmin)'
		dis as text _col(2) "N_g" 		_col(8) "=" as result	%9.0g `e(N_g)'	as text	_col(`=`l1'+`l2'+`l3'') "avg"		_col(`=`l1'+`l2'+`l3'+7') "=" as result %9.2f `e(Tbar)'
		dis as text _col(2) "vars." 	_col(8) "=" as result	%9.0g `e(k)'	as text	_col(`=`l1'+`l2'+`l3'') "max"		_col(`=`l1'+`l2'+`l3'+7') "=" as result %9.0f `e(Tmax)'
	}
	*di as result _newline "Estimated number of common factors in `varlist'" 
	*di as result _col(`=`l1'+`l2'+`l3'+3') as text "N" _col(`=`l1'+`l2'+`l3'+6') "=" _col(`=`l1'+`l2'+`l3'+8') %9.0g `e(N)'
	*di as result _col(`=`l1'+`l2'+`l3'+3') as text "T" _col(`=`l1'+`l2'+`l3'+6') "=" _col(`=`l1'+`l2'+`l3'+8') %9.0g `e(T)'
	
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

	di 	as text " GOS" _col(`=`l1'+1') "{c |}" as result %6.0f best_numfac[1,9] ///
		as text _col(`=`l1'+`l2'+2')"{c |}  ED" _col(`=`l1'+`l2'+`l3'+3') "{c |}" as result %6.0f best_numfac[1,10]
	di as text "{hline `l1'}{c BT}{hline `l2'}{c BT}{hline `l3'}{c BT}{hline `l4'}"

	di as result "`kmax'" ///
	   as text " factors maximally considered."
	di as text "PC_{p1},...,IC_{p3} from Bai and Ng (2002)"
	di as text "ER, GR from Ahn and Horenstein (2013)"
	di as text "ED from Onatski (2010)"
	di as text "GOS from Gagliardini, Ossola, Scaillet (2019)"
}

    if (e(missnum) > 0) {
	di as text ""
	di as text "`e(missnum)' missing values imputed before estimating number of factors."
	}
	///global e(missnum)=.

end


*********************************************************************************


mata

// mata drop mainroutine()
function mainroutine(real matrix data, real scalar N, real scalar T, kmax, stan)  {
	real matrix X, allICs, allICs0, X_sd
	real rowvector best_numfac, best_numfac0
	string matrix cnames, rnames
	
// Reshape to wide format	
	X        = colshape(data', T)'	
// Correct number of units to account for several supplied variables	
	N        = cols(data)*N

// Add if-clauses for standardization options	
	pointer mfunc
	if (hasmissing(X)==0) mfunc = &mymean()
	else mfunc = &meanmiss()
	
	if (stan == 2 | stan == 3) X = X - J(T,1,1)*(*mfunc)(X)

	if (stan == 4 | stan == 5) X = X - J(T,1,1)*(*mfunc)(X) - (*mfunc)(X')'*J(1,N,1) + J(T,1,1)*(*mfunc)(vec(X))*J(1,N,1)
	
	if (stan == 3 | stan == 5) {
		X_sd = sqrt(((*mfunc)(X:^2) - (*mfunc)(X):^2))'
		X = X :/(J(T,1,1)*X_sd')
	}
		

// Call interior functions to get all IC values and chosen num of factors	
	allICs0      = numfac_int(X,kmax)
	// update kmax
	kmax = cols(allICs0)-1
	st_local("kmax",strofreal(kmax))
	best_numfac0 = bestnum_ic_int(allICs0[1..9,])
	best_numfac = (best_numfac0, allICs0[10,1])
	allICs      = allICs0[1..9,]

// Pass results to Stata
	st_matrix("e(allICs)", allICs')
	st_matrix("e(best_numfac)", best_numfac)	
	st_numscalar("e(kmax)", kmax)
	st_matrix("allICs", allICs')
	st_matrix("best_numfac", best_numfac)
	st_numscalar("e(k)",cols(data))

// matrix col and row names (by JD)
	cnames = (J(9,1,"") , ("PC_{p1}" \ "PC_{p2}" \ "PC_{p3}" \ "IC_{p1}" \ "IC_{p2}" \ "IC_{p3}" \ "ER" \ "GR" \ "GOS"))
	rnames = (J(kmax+1,1,""), strofreal(0::kmax))
	
	st_matrixrowstripe("e(allICs)",rnames)
	st_matrixcolstripe("e(allICs)",cnames)

	st_matrixcolstripe("e(best_numfac)",(cnames \ ("", "ED") ))
	st_matrixrowstripe("e(best_numfac)",("","k*"))
}

/// mean function which allows for missings
function meanmiss(real matrix X) return(quadcolsum(X,0):/quadcolsum(X:!=.))
function mymean(real matrix X) return(mean(X))

// mata drop numfac_int()
function numfac_int(X0, kmax0)  {
// numfac_int calculates the Bai&Ng (2002) and Ahn&Horenstein (2013) ICs for 
// the number of factors.
// It has two inputs:
//   X0:    A TxN matrix containing the data of interest.
//   kmax0: The maximum number of factors to consider.
// The output is a matrix providing the IC values for factor models with 
// k=1,2,...,kmax0 factors in its rows. The columns correspond to the following
// statistics: 1:PC_p1,...,6:IC_p3, 7:ER, 8:GR, 9: GOS

	T     = rows(X0)
	N     = cols(X0)
    minNT = min((N, T))

    if (minNT < (kmax0+5)) {
    	kmax0 = minNT - 5
    	sprintf("")
    	if (minNT <= 5) {

    		sprintf("Cannot estimate ED, at least 6 cross-sections/variables are required to estimate number of common factors.")    				
    	}
    	if (kmax0 <= 0) {
    		kmax0 = 1    		
    	}    
    	sprintf("Number of variables/cross-sections too small. Maximum number of common factors set to %s." , strofreal(kmax0) )	
    	sprintf("")
    }

	missind = X0 :== .
	missnum = sum(sum(missind)')
	st_numscalar("e(missnum)", missnum)
	
	if ( missnum == 0) {
		if (T > N) {
				xx         = cross(X0,X0)
				fullsvd(xx:/(N*T), junk1, mus, junk2) // N x N
			} 
		else {  
				xx         = cross(X0',X0')
				fullsvd(xx:/(N*T), junk1, mus ,junk2) // T x T	 
		}	
	}
	else {
		obsind  = J(T,N,1) - missind

	    X0mean  = J(T,1,1) * meanmiss(editmissing(X0,0))
		X0      = editmissing(X0,0) + X0mean:*missind
		
		conv_crit = (X0 - X0mean):^2
		
		conv_crit = mean(meanmiss(conv_crit)')
		upd       = conv_crit
		
		while (upd > 0.001*conv_crit) {
			X0_old = X0
			if (T > N) {
				xx         = cross(X0,X0)
				fullsvd(xx:/(N*T), vee_k, mus, junk2)
				vee_k = vee_k[.,1..(kmax0+5)]
				uu_k  = X0*vee_k/sqrt(N*T)
			} 
			else {  
				xx         = cross(X0',X0')
				fullsvd(xx:/(N*T), uu_k, mus ,junk2)
				uu_k  = uu_k[.,1..(kmax0+5)]
				vee_k = X0'*uu_k/sqrt(N*T)
			}
			X0  = X0_old:*obsind + (uu_k*vee_k'):*missind:*sqrt(N*T)
			upd = mean(mean(abs(X0-X0_old))')
		}
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

	if (minNT > 5) {
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
			if (ED==0) {
				break	
			}
			jay       = ED+1
		}
		ED      = (ED, J(1,kmax0,.))
	}
	else {
		ED = (J(rows(ER),cols(ER),.))
	}

// Now do GOS
// penalty is g(n,t), p. 512
	penalty = (sqrt(N)+sqrt(T))^2/(N*T) * ln(N*T / (sqrt(N)+sqrt(T))^2 )
	GOS = (mus[1..kmax0+1] :- penalty)'
	allICs0 = (PC_ICs\ IC_ICs\ ER\ GR\ GOS\ED)

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
//				row 9 is the selection criterion used by GOS.
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

