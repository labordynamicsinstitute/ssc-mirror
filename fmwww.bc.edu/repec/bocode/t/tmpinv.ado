*! version 1.1.2  20feb2024  I I Bolotov
program define tmpinv, eclass byable(recall)
	version 16.0
	/*
		The program implements a non-iterated Transaction Matrix (TM)-specific  
		LPLS estimator for linear programming with the help of the Moore-Penrose
		inverse (pseudoinverse), calculated using singular value decomposition  
		(SVD). Estimation using 2x2 to 50x50 contiguous submatrices, repeated   
		with compensatory slack variables until NRMSE is minimized in a given   
		number of iterations, is followed by an F-test from linear regression/  
		t-test of mean NRMSE from a pre-simulated distribution (Monte-Carlo,    
		50,000 iterations with matrices consisting of normal random variates).  
		The result is adjusted for extreme values to match the RHS via shares   
		of estimated row/column sums if the corresponding option is specified.  

		Author: Ilya Bolotov, MBA, Ph.D.                                        
		Date: 30 September 2022                                                 
	*/
	tempname t title rspec cspec
	// syntax
	syntax																	///
	anything [if] [in] [,													///
		Values(string) Slackvars(string)									///
		ZERODiagonal ADJustment(string)										///
		SUBMatrix(int 2) TOLerance(real 0) Level(cilevel)					///
		DISTribution TRACE ITERate(int 1)									///
	]
	// adjust and preprocess options                                            
	if `"`values'"' != "" & "`zerodiagonal'" != "" { // either cOLS or TM option
		di as err "options values and zerodiagonal are mutually incompatible"
		exit 198
	}
	loc submatrix  = cond(`submatrix' >=  2, `submatrix',  2)/* minimum is  2 */
	loc submatrix  = cond(`submatrix' <= 50, `submatrix', 50)/* maximum is 50 */
	loc adjustment = cond(ustrregexm("`adjustment'", "^\s*ave" ), 1.5, 0) +	///
					 cond(ustrregexm("`adjustment'", "^\s*row" ),   1, 0) +	///
					 cond(ustrregexm("`adjustment'", "^\s*col" ),   2, 0)	///
	// select a subset of the data (if applicable)                              
	if `"`if'`in'"' != "" {
		preserve
		qui keep `if' `in'
	}
	// perform the pinv estimation via SVD                                      
	sca `t' = clock(c(current_date) + " " + c(current_time), "DMYhms")
	mata: tmpinv(                                                           ///
		`"`anything'"', `"`values'"', `"`slackvars'"',                      ///
		("`zerodiagonal'" != "" ? 1 : 0), ("`trace'" != "" ? 1 : 0),        ///
		`submatrix', `iterate', `adjustment',                               ///
		(`tolerance' ? `tolerance' : .), `level'                            ///
	)
	sca `t' = clock(c(current_date) + " " + c(current_time), "DMYhms") - `t'
	// print output                                                             
	di as txt _n "Converged in `=round(`t'/1000, 0.001)'s, solution stored"	///
			  _c " in{stata ret li: r(solution)}" _n
	cap confirm mat r(tests)
	if ! _rc {
		loc `title' = cond(`submatrix' <= 2, "F-test, linear regression:",	///
			"t-tests of mean NRMSE in submatrices, MC sample (50,000):")
		loc `rspec' = "& - `= "& " * rowsof(r(tests))'"
		loc `cspec' = "& %2.0f & %2.0f | %9.0g | " + cond(`submatrix' <= 2,	///
					  "%12.8f | %8.4f & %10.2g & %5.0f & %5.0f & %5.4f &",	///
					  "%12.8f | %8.4f & %8.0g  & %5.4f & %5.4f & %5.4f &")
		di as res _n "``title''"
		matlist r(tests),      names(col) rspec(``rspec'') cspec(``cspec'')
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

`VV' tmpinv(`SS' rhs, `SS' rhs_v, `SS' lhs_s, |`RS' f_d, `RS' f_t, `RS' lim,    
            `RS' iter, `RS' adj, `RS' tol, `RS' lvl)               /* solver  */
{
	`RS' r, c, i, j, mc_N, r2_c, r2_v
	`RV' v, e
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
	f_d   = f_d  != . ? f_d  : 0                     /* flag: zero-diagonal   */
	f_t   = f_t  != . ? f_t  : 0                     /* flag: trace           */
	lim   = lim  != . ? lim  : 50                    /* max submatrix size    */
	iter  = iter != . ? iter : 1                     /* iterations            */
	adj   = adj  != . ? adj  : 0                     /* flag: adjustment      */
	tol   = tol  != . ? tol  : .                     /* tolerance             */
	lvl   = lvl  != . ? lvl  : c("level")            /* confidence level      */
	mc_N  =                    50000                 /* Monte-Carlo sample    */
	/* check the dimensions of RHS, V, S (the elements of `a`), and `b`       */
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
	if (rows(RHS_V) & (length(RHS_V) != sum(rowmissing(RHS[,1]) :== 0)         *
	                                    sum(rowmissing(RHS[,2]) :== 0))        |
	    rows(LHS_S) & (length(LHS_S) != length(RHS))) {
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
			/* selection from known values (if applicable)                    */
			if (rows(RHS_V)) v = colshape((colshape((RHS_V\J(rows(X)*cols(X)-
			                     rows(RHS_V),1,.))[
			                     colshape(colshape(1..length(X),cols(X))[|d|],1)
			                     ],c-(tmp=rows(RHS) > lim ? 1 : 0)),
			                     J(r-tmp,tmp,.)\J(tmp,c,.)), 1)
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
			/*subM*/(rows(RHS_V) ? I(r*c)[|(1\rows(v)),(.\.)|] :
			          J(0,r*c,.)) :
			/*full*/(rows(RHS_V) ? I(r*c) : J(0,r*c,.))))
			a = C,(rows(S) ? S            : J(rows(C),0,.))\
			      (rows(M) ? M,J(rows(M),cols(S),0) : J(0,cols(C)+cols(S),.))
			C = S = M = .                            /* clear memory          */
			/*`b` -> (, 1)                                                    */
			if (rows(RHS) > lim) {
			/*subM*/(tmp=RHS)[|d[,1],(1\1)|] = J(r-1,1,0)
				    (tmp    )[|d[,2],(2\2)|] = J(c-1,1,0)
				b = RHS[|d[,1],(1\1)|]\colsum(tmp[,1])\
				    RHS[|d[,2],(2\2)|]\colsum(tmp[,2])\
				    (f_d ? J(min((r,c))-1,1,0) : (rows(RHS_V) ? v : J(0,1,.)))
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
			    (tmp=(b-a*(S=svsolve(a,b,.,tol)))[1..r+c]),tmp)                /
			    rows(b) / variance(b))
			if(lim > 2 & rows(RHS_V)) {              /* if `V` are defined    */
				S = (v\J(cols(LHS_S)!=0,1,0)),S
				e = .\e
				while((iter=iter == 1 ? c("maxiter") : iter)                   &
				      e[rows(e)] >= e[2] & rows(e) < iter + 2) {
					e = e\sqrt(cross((tmp=(b-a*(S=S,svsolve(
					        (a,(J(r+c,1,0)\select(
					        (tmp=S[,max((1,cols(S)-1))]-S[,cols(S)])[1..r*c],
					        rowmissing(v) :== 0))),
					        b,., tol
					    )[1..cols(a)])[,cols(S)])[1..r+c]),tmp)                /
					    rows(b) / variance(b))
				}
			}
			e = (iter > 1 ? iter : rows(e)-(cols(S) > 1)*2),
			    e[(tmp=selectindex(e :== min(e))[1])]
			X[|d|] = colshape((S=S[,tmp])[1..r*c],c)[|(1\d[2,1]-d[1,1]+1),
			                                        (1\d[2,2]-d[1,2]+1)|]
			/* determined and overdetermined TM: F-test from Stata's regress  */
			tmp = (tmp=select(D,(D[,1] :== r :& D[,2] :== c :& D[,3] :== f_d)))\
			      J((tmp == J(0,cols(D),.)),cols(D),.)
			if (lim <= 2 & cols(a) <= rows(b)){
				st_matrix("r(a)", a, "hidden")
				st_matrix("r(b)", b, "hidden")
				(void) _stata("`version' frame "+f+": svmat r(b), n(b)", 1)    &
				       _stata("`version' frame "+f+": svmat r(a), n(a)", 1)    &
				       _stata("`version' frame "+f+": reg b1 a*, noc  "        +
				       "l("+strofreal(lvl)+")",   ! f_t)
				tmp = .,e[2],tmp[6..14],st_numscalar("e(r2)"),
				             st_numscalar("e(F)"),st_numscalar("e(df_m)"),
				             st_numscalar("e(df_r)"),
				             Ftail(st_numscalar("e(df_m)"),
				             st_numscalar("e(df_r)"),st_numscalar("e(F)"))
			/* underdetermined TM: t-test of mean NRMSE from MC distribution  */
			} else if (lim > 2 & (e[2]+tmp[3]) != .) {
				(void) _stata("`version' ttesti "+strofreal(mc_N)              +
				                              " "+strofreal(tmp[4])            +
				                              " "+strofreal(tmp[5])            +
				                              " "+strofreal(e[2])              +
				       ", l("+strofreal(lvl)+")", ! f_t)
				tmp = e,tmp[6..14],st_numscalar("r(t)"),st_numscalar("r(df_t)"),
				                   st_numscalar("r(p_l)"),st_numscalar("r(p)"),
				                   st_numscalar("r(p_u)")
			} else                                   /* problem, NRMSE == .   */
				tmp = e,J(1,14,.)
			a = b = .                                /* clear memory          */
			T = T\(r,c,tmp)
		}
	}

	// adjust the solution `X` to match RHS via shares of `X`s row- or colsums  
	if (adj) X = ((adj <= 1.5 ? editmissing(X:/quadrowsum(X) :* select(RHS[,1],
	    /*rows*/ rowmissing(RHS[,1]) :== 0), 0) : J(rows(X),cols(X),0))        +
	              (adj >= 1.5 ? editmissing(X:/quadcolsum(X) :* select(RHS[,2],
	    /*cols*/ rowmissing(RHS[,2]) :== 0)',0) : J(rows(X),cols(X),0)))       /
	             (adj != 1.5 ? 1 : 2)

	// calculate the R-squared and R-squared for CONSTRAINTS                 
	r    = sum(rowmissing(RHS[,1]) :== 0)
	c    = sum(rowmissing(RHS[,2]) :== 0)
	C    = I(r)#J(1,c,1)\J(1,r,1)#I(c)
	b    = select(RHS[,1]\RHS[,2], rowmissing(RHS[,1]\RHS[,2]) :== 0)
	r2_c =                  (1 - cross((tmp=b      - C * colshape(X, 1)), tmp) /
	                             cross((tmp=b     :- mean(b)           ), tmp))
	if (rows(RHS_V)) r2_v = (1 - cross((tmp=RHS_V  -     colshape(X, 1)), tmp) /
                                 cross((tmp=RHS_V :- mean(RHS_V)       ), tmp))

	// return the solution `X`, tests `T`, and MC distribution percentiles `D`  
	st_eclear()
	st_rclear()
	st_matrix("r(solution)",   X)                    /* solution              */
	st_matrix("r(tests)",      (tmp=T[,1..4],T[,14..18]))
	st_matrixrowstripe("r(tests)",                   /* tests                 */
	(J(rows(tmp),1,""),strofreal(1::rows(tmp))))
	st_matrixcolstripe("r(tests)",(lim <= 2 ?
	(J(9,1,""),("r","c","iter","NRMSE","r2","F","df_m","df_r","p")') :
	(J(9,1,""),("r","c","iter","NRMSE","t","df_t","p_l","p","p_u")')))
	st_matrix("r(nrmse_dist)", (tmp=T[,4..13]), "hidden")
	st_matrixrowstripe("r(nrmse_dist)",              /* MC distribution       */
	(J(rows(tmp),1,""),strofreal(1::rows(tmp))))
	st_matrixcolstripe("r(nrmse_dist)",
	(J(10,1,""),("NRMSE","p1","p5","p10","p25","p50","p75","p90","p95","p99")'))
	st_numscalar("r(r2_v)", r2_v >= 0 & r2_v <= 1 ? r2_v
                                      : .)
	st_numscalar("r(r2_c)", r2_c >= 0 & r2_c <= 1 ? r2_c
                                      : .)
}

end
