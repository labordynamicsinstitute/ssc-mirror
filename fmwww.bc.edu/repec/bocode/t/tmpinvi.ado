*! version 1.0.1  20feb2024  I I Bolotov
program define tmpinvi, eclass byable(recall)
	version 16.0
	/*
		The program implements an iterated (multistep) Transaction Matrix (TM)- 
		specific LPLS estimator for linear programming with the help of the     
		Moore-Penrose inverse (pseudoinverse), calculated using singular value  
		decomposition (SVD). Estimation using 2x2 to 50x50 contiguous           
		submatrices, repeated with compensatory slack variables until NRMSE is  
		minimized in a given number of iterations, is followed by an F-test from
		linear regression/t-test of mean NRMSE from a pre-simulated distribution
		(Monte-Carlo, 50,000 iterations with matrices consisting of normal      
		random variates). The result is adjusted for extreme values to match the
		RHS via shares of estimated row/column sums if the corresponding option 
		is specified.                                                           

		Author: Ilya Bolotov, MBA, Ph.D.                                        
		Date: 30 September 2022                                                 
	*/
	tempname t F v s title rspec cspec
	// check for third-party packages from SSC                                  
	cap which moremata.hlp
	if _rc {
		di as err "installing {helpb moremata} (dependency)"
		ssc install moremata
	}
	cap which tmpinv
	if _rc {
		di as err "installing {helpb tmpinv} (dependency)"
		ssc install tmpinv
	}
	// syntax
	syntax																	///
	anything [if] [in] [,													///
		Values(string) Slackvars(string) ZERODiagonal						///
		SUBMatrix(int 2)													///
		Lowerbound(numlist max=1 miss) Upperbound(numlist max=1 miss)		///
		Round(real 8e-307) PENalization										///
		STEPNumber(int 2)  *												///
	]
	// adjust and preprocess options                                            
	if "`lowerbound'" == "" loc lowerbound = .
	if "`upperbound'" == "" loc upperbound = .
	// perform the pinv estimation via SVD                                      
	mata: printf("\n----+--- 1 ---+--- 2 ---+--- 3 ---+--- 4 ---+--- 5\n"); ///
		  f  = (f=trunc(floatround(log10(`stepnumber'))))                 + ///
		          trunc(floatround(f / 3)) + 2
	sca  `t' = clock(c(current_date) + " " + c(current_time), "DMYhms")
	forv  i  = 0/`stepnumber' {						   /* break if converged */
		if `i' >= 1 {
			mata: printf("."); displayflush();                              ///
				  if (! mod(`i', 50)) printf("%"+strofreal(f)+".0fc\n", `i');;
			if `i' == 1 mata: r2 = J(                               1,0,.); ///
							  v  = J(length(st_matrix("r(solution)")),0,.)
			mata: r2 = r2,st_numscalar("r(r2_c)");                          ///
				  if ("`zerodiagonal'" != "")                 {;            ///
				  x  = st_matrix("r(solution)"); _diag(x, 0);               ///
				       st_matrix("r(solution)",           x); };            ///
				  v  = v ,colshape(st_matrix("r(solution)"), 1);            ///
				  if ((r2[1] + r2[cols(r2)]) < . & r2[cols(r2)] <= r2[1]  & ///
				     `i' > 1 | `i' == `stepnumber') {;                      ///
				  st_matrix("r(solution)",                                  ///
				            colshape(v[.,selectindex(r2 :== max(r2))[1]],   ///
				            cols(st_matrix("r(solution)"))));               ///
				   st_local("`F'", "True");         };                      ///
				  st_matrix("`v'", colshape(st_matrix("r(solution)"), 1));  ///
				  if ("`penalization'" !=  ""                             & ///
				      missing(st_matrix("r(solution)"))) {;                 ///
				  st_matrix("`s'", ((rowmissing(st_matrix("r(solution)")) \ ///
				                    J(max((rows(st_matrix("r(solution)")),  ///
				                           cols(st_matrix("r(solution)")))) ///
				                    -      rows(st_matrix("r(solution)")),  ///
				                    1,.)),                                  ///
				                    (colmissing(st_matrix("r(solution)"))'\ ///
				                    J(max((rows(st_matrix("r(solution)")),  ///
				                           cols(st_matrix("r(solution)")))) ///
				                    -      cols(st_matrix("r(solution)")),  ///
				                    1,.))));                                ///
				   st_local("slackvars", "`s'");         };
			loc values      `v'
		}
		qui tmpinv `anything' `if' `in',       v(`values')  s(`slackvars')	///
										 `=cond(! `i',"`zerodiagonal'","")'	///
										 subm(`submatrix')  `options'
		****
		if `lowerbound' < . {
			mata: st_matrix("r(solution)", mm_cond(                         ///
				  round(st_matrix("r(solution)"), `round')               :< ///
				  J(rows(st_matrix("r(solution)")), 1, `lowerbound'), .,    ///
				         st_matrix("r(solution)")))
		}
		if `upperbound' < . {
			mata: st_matrix("r(solution)", mm_cond(                         ///
				  round(st_matrix("r(solution)"), `round')               :> ///
				  J(rows(st_matrix("r(solution)")), 1, `upperbound'), .,    ///
				         st_matrix("r(solution)")))
		}
		if `i' >= 1 & "``F''" != "" continue, break
	}
	sca `t' = clock(c(current_date) + " " + c(current_time), "DMYhms") - `t'
	mata: mata drop f r2 v x
	// print output                                                             
	if r(r2_c) < . {
		di _n as txt														///
		   _n "Converged in `=round(`t'/1000, 0.001)'s, solution stored"	///
		   _c " in{stata ret li: r(solution)}" _n
	}
	else {
		di _n as err														///
		   _n "Not converged, solution stored"								///
		   _c " in{stata ret li: r(solution)}" _n
	}
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
