*! version 1.0.1  31jan2022
program define lppinv, rclass byable(recall)
	version 16.0
	/*
		The algorithm solves "hybrid" least squares linear programming (LS-LP)  
		problems with the help of the Moore-Penrose inverse (pseudoinverse),    
		calculated using singular value decomposition (SVD), with emphasis      
		on estimation of non-typical constrained OLS (cOLS), Transaction Matrix 
		(TM), and custom (user-defined) cases. Eventual regression analysis and 
		a Monte-Carlo-based t-test of mean NRMSE is performed, the sample being 
		drawn from a uniform or a user-specified distribution (Mata function).  

		Author: Ilya Bolotov, MBA, Ph.D.                                        
		Date: 31 January 2022                                                   
	*/

	// syntax                                                                   
	syntax																	///
	anything [if] [in] [,												///
		COLS TM																///
		Model(string) Constraints(string) Slackvars(string)					///
		ZERODiagonal noMC													///
		TOLerance(real `=c(epsdouble)') Level(cilevel)						///
		SEED(int `=c(rngseed_mt64s)') ITERate(int 500) DISTribution(string)	///
	]

	// adjust and preprocess options                                            
	if "`cols'" != "" & "`tm'" != "" {				 // either cOLS or TM option
		di as err "options cols and tm are mutually incompatible"
		exit 198
	}
	if `"`distribution'"' == "" {					 // function name -> pointer
		loc distribution "lppinv_runiform"
	}

	// select a subset of the data (if applicable)                              
	if `"`if'`in'"' != "" {
		preserve
		qui keep `if' `in'
	}

	// perform the pinv estimation via SVD                                      
	mata: lppinv(                                                           ///
		"`cols'`tm'", `"`anything'"', `"`model'"', `"`constraints'"',       ///
		`"`slackvars'"', ("`zerodiagonal'" != "" ? 1 : 0),                  ///
		("`mc'" != "" ? 1 : 0), /* print output */ 1,                       ///
		`tolerance', `level', `seed', `iterate', &`distribution'()          ///
	)

	// return output
	ret add
end

version 16.0
clear mata

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

`VV' lppinv(`SS' lp, `SS' rhs, `SS' lhs_m, `SS' lhs_c, `SS' lhs_s, |`RS' f_d,   
            `RS' f_cv, `RS' f_t, `RS' tol, `RS' lvl, `RS' seed, `RS' iter,      
            `PF' dist)                                             /* solver  */
{
	`RS' r, c, i
	`RV' x, e
	`RM' b, M, C, S, a
	`TM' tmp, f

	// general configuration                                                    
	tmp   = _stata("`version' tsset, noq", 1)
	b     = (! _stata("`version' confirm numeric var "           + /* RHS     */
		    regexr(rhs, ".+\.", ""), 1)
		? st_data(., (! tmp ? _st_tsrevar(tokens(rhs)) : tokens(rhs)))
		: (length(tokens(rhs)) == 1 ? st_matrix(rhs) : J(0,0,.))
	)
	M     = (! _stata("`version' confirm numeric var "           + /* LHS     */
		    regexr(lhs_m, ".+\.", ""), 1)
		? st_data(., (! tmp ? _st_tsrevar(tokens(lhs_m)) : tokens(lhs_m)))
		: (length(tokens(lhs_m)) == 1 ? st_matrix(lhs_m) : J(0,0,.))
	)
	C     = (! _stata("`version' confirm numeric var "           +
		    regexr(lhs_c, ".+\.", ""), 1)
		? st_data(., (! tmp ? _st_tsrevar(tokens(lhs_c)) : tokens(lhs_c)))
		: (length(tokens(lhs_c)) == 1 ? st_matrix(lhs_c) : J(0,0,.))
	)
	S     = (! _stata("`version' confirm numeric var "           +
		    regexr(lhs_s, ".+\.", ""), 1)
		? st_data(., (! tmp ? _st_tsrevar(tokens(lhs_s)) : tokens(lhs_s)))
		: (length(tokens(lhs_s)) == 1 ? st_matrix(lhs_s) : J(0,0,.))
	) 
	f_d   = f_d   != . ? f_d  : 0                    /* flag: zero-diagonal   */
	f_cv  = f_cv  != . ? f_cv : 0                    /* flag: critical values */
	f_t   = f_t   != . ? f_t  : 1                    /* flag: trace           */
	tol   = tol   != . ? tol  : c("epsdouble")       /* tolerance             */
	lvl   = lvl   != . ? lvl  : c("level")           /* confidence level      */
	seed  = seed  != . ? seed : c("rngseed_mt64s")   /* MC seed               */
	iter  = iter  != . ? iter : 500                  /* MC iterations         */
	dist  = dist       ? dist : &lppinv_runiform()   /* MC distribution       */

	// prepare LHS (left-hand side), `a`, and RHS (right-hand side), `b`        
	if (strlower(lp) == "cols") {                    /* LS-LP type: cOLS      */
		if (rows(b) < rows(M) + rows(C)) b = b,b
	}
	if (strlower(lp) == "tm") {                      /* LS-LP type: TM        */
		if (! rows(b) | (rows(b) & cols(b) != 2)                               |
		                (rows(S) & cols(S) != 2)) {
			errprintf("Error: TM requires two columns in `b`\n" )
			exit(503)
		}
		/* C -> characteristic matrix                                         */
		r = rows(select(b[.,1], b[.,1] :< .))        /* rows and cols         */
		c = rows(select(b[.,2], b[.,2] :< .))
		C = I(r)#J(1,c,1)\J(1,r,1)#I(c)
		/* missing values of M -> 0                                           */
		if (rows(M)) _editmissing(M, 0)
	} else {
		if (! rows(b) | (rows(b) & cols(b) != 2 - ! cols(M) - ! cols(C))       |
		                (rows(S) & cols(S) != 2 - ! cols(M) - ! cols(C))       |
		      rows(S) & (rows(b)           != rows(S))                         |
		      length(b)                    != rows(M) + rows(C)) {
			errprintf("Error: `a` and `b` are not conformable\n")
			exit(503)
		}
	}
	if (rows(S)) S = select(tmp=colshape(S', 1), tmp :< .)
	/* M, C, S -> `a`                                                         */
	a = (rows(C) ? C,(rows(S) ? S : J(rows(C),0,.)) : J(0,cols(M) + cols(S),.))\
		(rows(M) ? M,J(rows(M),cols(S),0) : J(0,cols(C) + cols(S),.))
	if (f_d) _diag(a, 0)                             /* diagonal of `a' -> 0  */
	C = S = cols(S)                                  /* clear memory          */
	/*`b` -> (., 1)                                                           */
	b = colshape(b', 1)
	/* drop missing values of `a`, `b`                                        */
	a = select(a, (tmp=rowmissing(a) + rowmissing(b)) :== 0)
	b = select(b, (tmp)                               :== 0)
	st_matrix("r(a)", a, "hidden")
	st_matrix("r(b)", b, "hidden")

	// obtain the SVD-based solution of the matrix equation `a @ x = b`         
	x = svsolve(a, b, C, tol)                        /* solution and NRMSE    */
	e = e\sqrt((tmp=b - a * x)'tmp / (r=rows(b)) / variance(b))
	/* regression results (if applicable)                                     */
	st_framecreate(f=st_tempname())
	if (rows(x) <= r) {
		tmp = _stata("`version' frame "+f+": svmat r(b), n(b)", 1)             &
			  _stata("`version' frame "+f+": svmat r(a), n(a)", 1)             &
			  _stata("`version' frame "+f+": reg b1 a*, noc "                  +
			  "l("+strofreal(lvl)+")",   1 - f_t)
	}
	/* NRMSE t-test for `a', based on MC with iter simulations                */
	if ((e[1] != .) & (1 - f_cv)) {                  /* skip if NRMSE == .    */
		e = e\((tmp=trunc(floatround(log10(iter)))) + trunc(floatround(tmp / 3))
			  + 2)                                   /* format: %e[2].0fc     */
		printf("\n{txt}Simulations ({res}%"+ strofreal(e[2] - 1)+".0fc{txt})\n",
		iter)
		printf("----+--- 1 ---+--- 2 ---+--- 3 ---+--- 4 ---+--- 5\n")
		rseed(seed)
		for(i = 1; i < (iter + 1); i++) {
			e = e\sqrt((tmp=(b=(*dist)(r, 1)) - a * svsolve(a, b, C, tol))'tmp /
			      r / variance(b))
			if (! mod(i, 5)) { printf("....."); displayflush(); }
			if (! mod(i, 50))  printf("%"+strofreal(e[2])+".0fc\n", i)
		}
		st_matrix("r(e)", e[3::rows(e)], "hidden")
		tmp = _stata("`version' frame "+f+": svmat r(e), n(e)", 1)             &
			  _stata("`version' frame "+f+": ttest e1 == "                     +
			  strofreal(e[1]) + ", l("+strofreal(lvl)+")", 1 - f_t)
	}

	// return the solution `x', matrix `a' and NRMSE                            
	st_matrix("r(solution)", colshape(x[1::rows(x)-S], c != . ? c : 1))
	st_matrix("r(a)",        a, "hidden")
	st_numscalar("r(nrmse)", e[1])
}

`RM' lppinv_runiform(`RS' r, `RS' c) return(runiform(r, c))        /* dummy   */
end
