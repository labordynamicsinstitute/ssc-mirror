*! version 1.0.0  30sep2022  I I Bolotov
program define tmpinv, eclass byable(recall)
	version 16.0
	/*
		The algorithm solves "hybrid" linear programming-least squares (LP-LS)  
		Transaction Matrix (TM) problems with the help of the Moore-Penrose     
		inverse (pseudoinverse), calculated using singular value decomposition  
		(SVD). The method includes a 50x50 contiguous submatrix estimation and  
		a t-test of mean NRMSE from a pre-simulated distribution (Monte-Carlo,  
		50,000 iterations with matrices consisting of normal random variates),  
		fine-tuned via compensatory slack variables until NRMSE is minimized.   

		Author: Ilya Bolotov, MBA, Ph.D.                                        
		Date: 30 September 2022                                                 
	*/
	tempname t rspec cspec
	// syntax
	syntax																	///
	anything [if] [in] [,													///
		Values(string) Slackvars(string)									///
		ZERODiagonal 														///
		TOLerance(real 0) Level(cilevel)									///
		ITERate(int 1)														///
		DISTribution TRACE													///
	]
	// adjust and preprocess options                                            
	if `"`values'"' != "" & "`zerodiagonal'" != "" { // either cOLS or TM option
		di as err "options values and zerodiagonal are mutually incompatible"
		exit 198
	}
	// select a subset of the data (if applicable)                              
	if `"`if'`in'"' != "" {
		preserve
		qui keep `if' `in'
	}
	// perform the pinv estimation via SVD                                      
	sca `t' = clock(c(current_date) + " " + c(current_time), "DMYhms")
	mata: tmpinv(                                                           ///
		`"`anything'"', `"`values'"', `"`slackvars'"',                      ///
		("`zerodiagonal'" != "" ? 1 : 0),                                   ///
		("`trace'" != "" ? 1 : 0),                                          ///
		(`tolerance' ? `tolerance' : .), `level', `iterate'                 ///
	)
	sca `t' = clock(c(current_date) + " " + c(current_time), "DMYhms") - `t'
	// print output                                                             
	di as txt _n "Converged in `=round(`t'/1000, 0.001)'s, solution stored"	///
			  _c "in{stata ret li: r(solution)}" _n
	cap confirm mat r(nrmse)
	if ! _rc {
		di as res _n "t-tests of mean NRMSE in submatrices, MC sample (50,000):"
		loc `rspec' = "& - `= "& " * rowsof(r(nrmse))'"
		loc `cspec' = "& %2.0f & %2.0f | %9.0g | %12.8f & %8.4f " +		///
					  "& %9.0g `= "& %5.4f " * 3'&"
		matlist r(nrmse),      names(col) rspec(``rspec'') cspec(``cspec'')
	}
	cap confirm mat r(nrmse_dist)
	if ! _rc & "`distribution'" != "" {
		di as res _n "percentiles, MC sample (50,000):"
		loc `rspec' = "& - `= "& " * rowsof(r(nrmse_dist))'"
		loc `cspec' = "`= "& %6.2f " * 10'&"
		matlist r(nrmse_dist), names(col) rspec(``rspec'') cspec(``cspec'')
	}
end

version 16.0
loc RS        real scalar
loc RV        real colvector
loc RM        real matrix
loc SS        string scalar
loc TM        transmorphic matrix
loc PF        pointer(`RM' function) scalar
loc VV        void

loc version   "version 16:"

mata:
mata set matastrict on

`VV' tmpinv(`SS' rhs, `SS' rhs_v, `SS' lhs_s, |`RS' f_d, `RS' f_t, `RS' tol,    
            `RS' lvl, `RS' iter)                                   /* solver  */
{
	`RS' r, c, i, j, lim, mc_N
	`RV' e
	`RM' RHS, RHS_V, LHS_S, D, C, M, S, d, a, b, X, T
	`TM' tmp, f

	// general configuration                                                    
	tmp   = _stata("`version' tsset, noq", 1)
	RHS   = (! _stata("`version' confirm numeric var "           + /* RHS     */
	        regexr(rhs,   ".+\.", ""), 1)
	    ? st_data(., (! tmp ? _st_tsrevar(tokens(rhs)) : tokens(rhs)))
	    : (length(tokens(rhs)) == 1 ? st_matrix(rhs) : J(0,0,.))
	)
	RHS_V = (! _stata("`version' confirm numeric var "           +
	        regexr(rhs_v, ".+\.", ""), 1)
	    ? st_data(., (! tmp ? _st_tsrevar(tokens(rhs_v)) : tokens(rhs_v)))
	    : (length(tokens(rhs_v)) == 1 ? st_matrix(rhs_v) : J(0,1,.))
	)
	LHS_S = (! _stata("`version' confirm numeric var "           + /* LHS     */
	        regexr(lhs_s, ".+\.", ""), 1)
	    ? st_data(., (! tmp ? _st_tsrevar(tokens(lhs_s)) : tokens(lhs_s)))
	    : (length(tokens(lhs_s)) == 1 ? st_matrix(lhs_s) : J(0,0,.))
	)
	f_d   = f_d   != . ? f_d  : 0                    /* flag: zero-diagonal   */
	f_t   = f_t   != . ? f_t  : 0                    /* flag: trace           */
	tol   = tol   != . ? tol  : .                    /* tolerance             */
	lvl   = lvl   != . ? lvl  : c("level")           /* confidence level      */
	iter  = iter  != . ? iter : 1                    /* iterations            */
	lim   =                     50                   /* max block matrix size */
	mc_N  =                     50000                /* Monte-Carlo sample    */
	/* check dimensions of RHS, V, S (the elements of `a`) and `b`            */
	if (! rows(rhs) | (rows(RHS)   & cols(RHS)   != 2)                         |
	                  (rows(RHS_V) & cols(RHS_V) != 1)                         |
	                  (rows(LHS_S) & cols(LHS_S) != 2)) {
		errprintf("Error: TM requires two columns in `b` and `S`, one in `V`\n")
		exit(503)
	}
	if (strtrim(rhs)   != "" & ! rows(RHS)  ) {
		errprintf("Error: variabe/matrix in RHS         not found/ambiguous\n")
		exit(111)
	}
	if (strtrim(rhs_v) != "" & ! rows(RHS_V)) {
		errprintf("Error: variabe/matrix in values()    not found/ambiguous\n")
		exit(111)
	}
	if (strtrim(lhs_s) != "" & ! rows(LHS_S)) {
		errprintf("Error: variabe/matrix in slackvars() not found/ambiguous\n")
		exit(111)
	}
	if (rows(LHS_S) & (length(LHS_S) != length(RHS))                           |
	    rows(RHS_V) & (rows(RHS_V)   != sum(rowmissing(RHS[,1]) :== 0)*
	                                    sum(rowmissing(RHS[,2]) :== 0))) {
		errprintf("Error: TM requires the same number of rows in LHS and RHS\n")
		exit(503)
	}

	// estimate using limxlim contiguous submatrices and t-tests of mean NRMSE  
	X = J(sum(rowmissing(RHS[,1]) :== 0),sum(rowmissing(RHS[,2]) :== 0),.)
	T = J(0,18,.)
	st_framecreate(f=st_tempname())                  /* create a hidden frame */
	(void) _stata("`version' findfile tmpinv.mmat",1)/* load MC distribution  */
	D = fgetmatrix((tmp=fopen(st_global("r(fn)"), "r")))
	fclose(tmp)
	if (rows(RHS) > lim) lim--                       /* choose matrix size    */
	for(i = 0; i < ceil(sum(rowmissing(RHS[,1]) :== 0) / lim); i++) {
		for(j = 0; j < ceil(sum(rowmissing(RHS[,2]) :== 0) / lim); j++) {
			/* dimensions of a contiguous submatrix/full problem              */
			d = (lim*i+1),(lim*j+1)\
			    min((lim*i+lim, sum(rowmissing(RHS[,1]) :== 0))),
			    min((lim*j+lim, sum(rowmissing(RHS[,2]) :== 0)))
			r = d[2,1] - d[1,1] + (rows(RHS) > lim ? /*subM*/ 2 : /*full*/ 1)
			c = d[2,2] - d[1,2] + (rows(RHS) > lim ? /*subM*/ 2 : /*full*/ 1)
			/* M, C, S -> `a`                                                 */
			C = I(r)#J(1,c,1)\J(1,r,1)#I(c)
			S = (rows(LHS_S) ? LHS_S[1..r,1]\
			                   LHS_S[1..c,2]
			                 : J(r+c,0,.))
			M = (f_d
			    ? (rows(RHS) > lim ?
			/*subM*/((tmp=(I(min((r,c)))#(1,J(1,c,0)))[,(1..min((r,c))*c)]),
			        J(rows(tmp),r*c-cols(tmp),0))[|(1\min((r,c))-1),(.\.)|] :
			/*full*/((tmp=(I(min((r,c)))#(1,J(1,c,0)))[,(1..min((r,c))*c)]),
			          J(rows(tmp),r*c-cols(tmp),0)))
			    : (rows(RHS) > lim ?
			/*subM*/(rows(RHS_V) ? I(r*c)[|(1\r*c-1),(.\.)|] :
			          J(0,r*c,.)) :
			/*full*/(rows(RHS_V) ? I(r*c) : J(0,r*c,.)))
			)
			a = C,(rows(S) ? S      : J(rows(C),0,.))\
			      (rows(M) ? M,J(rows(M),cols(S),0) : J(0,cols(C)+cols(S),.))
			C = S = M = J(0,0,.)                     /* clear memory          */
			/*`b` -> (, 1)                                                    */
			if (rows(RHS) > lim) {
			/*subM*/(tmp=RHS)[|d[,1],(1\1)|] = J(r-1,1,0)
				    (tmp    )[|d[,2],(2\2)|] = J(c-1,1,0)
				b = RHS[|d[,1],(1\1)|]\colsum(tmp[,1])\
				    RHS[|d[,2],(2\2)|]\colsum(tmp[,2])\
				    (f_d ? J(min((r,c))-1,1,0) : (rows(RHS_V)
				        ? RHS_V[colshape(colshape(1..length(X),cols(X))[|d|],1)]
				        : J(0,1,.)
				    ))
			} else
			/*full*/
				b = RHS[1..r,1]\
				    RHS[1..c,2]\
				    (f_d ? J(r,1,0) : RHS_V)
			/* missing values in `a` and `b`                                  */
			a = select(a, (tmp=rowmissing(a)+rowmissing(b)) :== 0)
			b = select(b, (tmp)                             :== 0)
			/* SVD-based solution, repeated until NRMSE is minimized          */
			e = sqrt(cross(
			    (tmp=(b-a*(S=svsolve(a,b,.,tol)))[1..r+c]),tmp) /
			    rows(b) / variance(b))
			if(rows(RHS_V)) {                        /* if `V` are defined    */
				S = (RHS_V\J(cols(LHS_S),1,0)),S
				e = .\e
				while(iter & e[rows(e)] >= e[2] | rows(e) < iter + 2) {
					e = e\sqrt(cross((tmp=(b-a*(S=S,svsolve(
					        (a,(J(r+c,1,0)\select(
					        (tmp=S[,max((1,cols(S)-1))]-S[,cols(S)])[1..r*c],
					        rowmissing(RHS_V) :== 0))),
					        b,., tol
					    )[1..cols(a)])[,cols(S)])[1..r+c]),tmp)                /
					    rows(b) / variance(b))
				}
			}
			e = iter,e[(tmp=selectindex(e :== min(e))[1])]
			/* solution with Stata's regress command (if applicable)          */
			if (cols(a) <= rows(b)) {
				st_matrix("r(a)", a, "hidden")
				st_matrix("r(b)", b, "hidden")
				(void) _stata("`version' frame "+f+": svmat r(b), n(b)", 1)    &
				       _stata("`version' frame "+f+": svmat r(a), n(a)", 1)    &
				       _stata("`version' frame "+f+": reg b1 a*, noc  "        +
				       "l("+strofreal(lvl)+")",   ! f_t)
			}
			X[|d|] = S = colshape(S[1..r*c,tmp],c)[|(1\d[2,1]-d[1,1]+1),
			                                        (1\d[2,2]-d[1,2]+1)|]
			/* t-test of mean NRMSE from MC distribution                      */
			if (cols(a) > rows(b) & e[2] != .) {
				d = select(D,(D[,1] :== r :& D[,2] :== c :& D[,3] :== f_d))
				(void) _stata("`version' ttesti "+strofreal(mc_N)              +
				                              " "+strofreal(d[4])              +
				                              " "+strofreal(d[5])              +
				                              " "+strofreal(e[2])              +
				       ", l("+strofreal(lvl)+")", ! f_t)
			} else
				d = J(1,14,.)
			T = T\(r,c,e,d[6..14],st_numscalar("r(t)"),
			      st_numscalar("r(df_t)"),st_numscalar("r(p_l)"),
			      st_numscalar("r(p)"),st_numscalar("r(p_u)"))
		}
	}

	// return the solution `X', NRMSE, and MC distribution percentiles          
	st_eclear()
	st_rclear()
	st_matrix("r(solution)",   X)                    /* solution              */
	st_matrix("r(nrmse)",      (tmp=T[,1..4],T[,14..18]))
	st_matrixrowstripe("r(nrmse)",                   /* NRMSE                 */
	(J(rows(tmp),1,""),strofreal(1::rows(tmp))))
	st_matrixcolstripe("r(nrmse)",
	(J(9,1,""),("r","c","iter","NRMSE","t","df_t","p_l","p","p_u")'))
	st_matrix("r(nrmse_dist)", (tmp=T[,4..13]), "hidden")
	st_matrixrowstripe("r(nrmse_dist)",              /* MC distribution       */
	(J(rows(tmp),1,""),strofreal(1::rows(tmp))))
	st_matrixcolstripe("r(nrmse_dist)",
	(J(10,1,""),("NRMSE","p1","p5","p10","p25","p50","p75","p90","p95","p99")'))
}

end
