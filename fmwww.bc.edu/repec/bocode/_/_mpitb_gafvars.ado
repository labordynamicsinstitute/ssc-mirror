*! part of -mpitb- the MPI toolbox

cap program drop _mpitb_gafvars
program define _mpitb_gafvars , rclass
	syntax , INDVars(varlist) indw(numlist) wgtsid(string)  /// 
		[DOUble replace Klist(numlist integer <=100 >=1 min=1) CVECtor INDicator]
		/* 	NB: most checks for valid input are upto caller
			(e.g., # or sum of wgts, valid MPI names */

	if "`klist'" == "" & "`cvector'" == "" {
		di as err "either klist() or cvector is required"
		exit 197
	}
	
	* additional consistency checks may go here 

	loc genvars ""			// collect all generated vars
	
	* independent of k 
	
	* check for existing vars 
	if "`replace'" != "" {
		cap drop c_`wgtsid'
	}
	else {
		confirm new v c_`wgtsid' 			
	}			
	
	tempvar c_`wgtsid' 
	qui gen `double' `c_`wgtsid'' = .
	m depvars = "`indvars'" 						// st_global("_dta[MPITB_dep_vars_act]")
	m gcvec(depvars,"`indw'","`c_`wgtsid''")

	* dependent on k
	if "`klist'" != "" {
		foreach k of numlist `klist' {

			loc ks = strofreal(`k',"%02.0f")		// k-string 
			
			* check for existing vars 
			if "`replace'" != "" {
				cap drop I_`ks'_`wgtsid'
				cap drop c_`ks'_`wgtsid'
				if "`indicator'" != "" {
					foreach v of varlist `indvars' {
						cap drop c`v'_`ks'_`wgtsid'
						cap drop actb_`v'_`ks'_`wgtsid'
					}
				}
			}
			else {
				confirm new v I_`ks'_`wgtsid' c_`ks'_`wgtsid'
				if "`indicator'" != "" {
					foreach v of varlist `indvars' {
						conf new v c`v'_`ks'_`wgtsid'
						conf new v actb_`v'_`ks'_`wgtsid'
					}
				}
			}

			qui gen byte I_`ks'_`wgtsid' = .
			qui gen `double' c_`ks'_`wgtsid' = .
			loc genvars `genvars' I_`ks'_`wgtsid' c_`ks'_`wgtsid'	

			m gafvars(`k',"I_`ks'_`wgtsid'","`c_`wgtsid''","c_`ks'_`wgtsid'")		// depvars , "`indw'"
			
			if "`indicator'" != "" {
				loc cdepvars ""
				loc actbvars ""
				foreach n in `indvars' {			// _dta[MPITB_dep_vars_act]
					loc cdepvars `cdepvars' c`n'_`ks'_`wgtsid'
					qui gen byte c`n'_`ks'_`wgtsid' = .
					loc actbvars `actbvars' actb_`n'_`ks'_`wgtsid'
					qui gen `double' actb_`n'_`ks'_`wgtsid' = .
					loc genvars `genvars' c`n'_`ks'_`wgtsid' actb_`n'_`ks'_`wgtsid'
				}
				m cdepvars = st_local("cdepvars")
				m actbvars = st_local("actbvars")
				m gdim(depvars,"I_`ks'_`wgtsid'",cdepvars,actbvars,"`indw'")		
			}
			* store infos to char
				// Todo
			di as txt "Note: AF vars for k= " as res `k' as txt " and weighting scheme " as res "`wgtsid'" as txt " generated."
		}
	}
	if "`cvector'" != "" {
		gen `double' c_`wgtsid' = `c_`wgtsid''
		loc genvars `genvars' c_`wgtsid'
	}
	* returns
	ret loc genvars `genvars'

end

m mata clear
m mata set matastrict on
mata
// ********************************************
// *** select weighting schemes from matrix ***
// ********************************************
	// inputs: row number, matrix name, local name wgts, local name wgts id
void swgts(real scalar r, string scalar mname, string scalar lnamewgts, lnamewgtsid)
{
	real matrix W
	string scalar wgts, wgtsid
	
	W = st_matrix(mname)
	wgts = invtokens(strofreal(W[r,.]))
	wgtsid = subinstr(invtokens(strofreal(W[r,.]:*100,"%03.0f"))," ","")
	st_local(lnamewgts, wgts)
	st_local(lnamewgtsid, wgtsid)
}


// *********************************************
// *** generate AF variables (Mata function) ***
// *********************************************
void gafvars(	real scalar k, 			// string scalar dvars,
	//	string scalar w, 		// setwgts must work with matrices, before changing to matrix weights
		string scalar Ivar, 
		string scalar cvar,
		string scalar ckvar,
		| string scalar cdvars) 
{
	real matrix CX	// WX , X, 
	real colvector c, Ik, ck, nmv
	// real rowvector W
	
	//st_view(X=.,.,tokens(dvars))
	st_view(Ik=.,.,Ivar)
	st_view(c=.,.,cvar)
	st_view(ck=.,.,ckvar)
	st_view(CX=.,.,tokens(cdvars))
	// W = strtoreal(tokens(w))
	
	//WX = W:*X				// deprivation values
	//c = rowsum(WX)		// counting vector
	nmv = (c :< .)  		// non-mv matrix 	
	k = k :/ 100
	// identification vector 
	// Ik[.,.] = c :>= k 							// old version 
	// Ik[.,.] = mm_cond(c :< . , (c :>= k) , . ) 	// moremata 
	Ik[.,.] = (c :>= k) :/ nmv
	ck[.,.] = c :* Ik							// censored counting vector

	// if (args()==6) CX[.,.] = X :* Ik // censored deprivation matrix

	// dimensioanl deprivation values as subviews of WX
}

void gcvec(string scalar dvars,
		string scalar w, 		// setwgts must work with matrices, before changing to matrix weights
		string scalar cvar)
{
	real matrix X, WX
	real colvector c
	real rowvector W
	
	st_view(X=.,.,tokens(dvars))
	st_view(c=.,.,cvar)
	W = strtoreal(tokens(w))

	WX = W:*X						// deprivation values
	c[.,.] = rowsum(WX , 1)			// counting vector; create missings
}

void gdim(string scalar dvars,
	string scalar Ivar,
	string scalar cdvars,
	string scalar actbvars,
	string scalar w)
{
	real matrix X, CX, AX
	real colvector Ik
	real rowvector W
	
	st_view(X=.,.,tokens(dvars))
	st_view(Ik=.,.,Ivar)
	st_view(CX=.,.,tokens(cdvars))
	st_view(AX=.,.,tokens(actbvars))
	W = strtoreal(tokens(w))
	
	CX[.,.] = X:*Ik 
	AX[.,.] = CX:*W
}

end 
exit
