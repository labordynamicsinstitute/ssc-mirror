*! version 1.1.0  20nov2025  I I Bolotov
program define clspl2, eclass byable(recall)
	version 15.1
	/*
		Convex Least Squares Programming (CLSP) is a modular two-step estimator 
		for solving underdetermined, ill-posed, or structurally constrained     
		least-squares problems. It combines pseudoinverse-based estimation with 
		convex-programming correction methods inspired by Lasso, Ridge, and     
		Elastic Net to ensure numerical stability, constraint enforcement, and  
		interpretability. The current implementation limits the second step to  
		the Ridge case by employing a second pseudoinverse estimation. The      
		package also provides numerical stability analysis and CLSP-specific    
		diagnostics, including partial R^2, normalized RMSE (NRMSE), bootstrap  
		or Monte Carlo t-tests for mean NRMSE, and condition-number-based       
		confidence bands.                                                       

		Author: Ilya Bolotov, MBA, Ph.D.                                        
		Date: 20 August 2025                                                    
	*/
	tempname vars
	// replay last result                                                       
	if replay() {
		if _by() {
			error 190
		}
		cap conf mat e(z)
		if _rc {
			di as err "results of clspl2 not found"
			exit 301
		}
		_summary									   // print summary
		exit 0
	}
	// syntax                                                                   
	syntax																	///
	[anything] [if] [in], [													///
		b(string) Constraints(string) Slackvars(string) MODel(string)		///
		m(int 0) p(int 0) i(int 1) j(int 1) ZERODiagonal r(int 1) Z(name)	///
		RCOND(real  0) TOLerance(real -1) ITERationlimit(int 1) noFINAL		///
		CONDTOLerance(real 1e-14) nested x *								///
	]
	// adjust and preprocess options for the CLSPL2 Mata class                  
	if           ustrregexm( `"`anything'"',       "^estat",     1)           {
		_estat `=ustrregexrf(`"`anything'"',       "^estat", "", 1)', `options'
		exit 0
	}
	if ("`b'"                                                == "")           {
		di as err "option b() required"
		exit 198
	}
	if ("`b'"                                                != "")           {
			   cap unab varlist :     `b',         max(1)
		loc rc =   _rc
		if _rc cap conf mat           `b'
		else       loc  b             `varlist'
		if _rc     &  `rc' != 103 {
			di as err                 "b: `b'"
			di as err                 "invalid varname or matrix"
			exit cond(`rc' == 103, 103, 198)
		}
		else       if `rc' == 103 error 103
	}
	if ("`constraints'"                                      != "")           {
			   cap unab varlist :     `constraints'
		if _rc cap conf mat           `constraints'
		else       loc  constraints   `varlist'
		if _rc                                                                {
			di as err                 "constraints: `constraints'"
			di as err                 "invalid varlist or matrix"
			exit 198
		}
	}
	if ("`slackvars'"                                        != "")           {
			   cap unab varlist :     `slackvars'
		if _rc cap conf mat           `slackvars'
		else       loc  slackvars     `varlist'
		if _rc                                                                {
			di as err                 "slackvars: `slackvars'"
			di as err                 "invalid varlist or matrix"
			exit 198
		}
	}
	if ("`model'"                                            != "")           {
			   cap unab varlist :     `model'
		if _rc cap conf mat           `model'
		else       loc  model         `varlist'
		if _rc                                                                {
			di as err                 "model: `model'"
			di as err                 "invalid varlist or matrix"
			exit 198
		}
	}
	if (`m' <  0 | `p' <  0 | `i' <  0 | `j' <  0)                            {
		di as err "m(), p(), i(), and j() must be non-negative"
		exit 198
	}
	if (`r' <  1 | `iterationlimit'          <  1)                            {
		di as err "r() and iterationlimit() must be at least 1"
		exit 198
	}
	if ("`z'"                                                != "")         ///
	conf mat  `z'
	if ! (`rcond'     == -1 | (`rcond'     >= 0 & `rcond'     < 1))           {
		di as err "rcond() must be -1 or lie in [0,1)"
		exit 198
	}
	if ! (`tolerance' == -1 | (`tolerance' >= 0 & `tolerance' < 1))           {
		di as err "tolerance() must be -1 or lie in [0,1)"
		exit 198
	}
	sca                 `vars'    = ""				   // markout [if] [in]
	foreach name in     `constraints' `slackvars' `model' `b'                 {
		cap conf var    `name'
		if ! _rc sca    `vars'    =   `vars' +  " `name'"
	}
	tempvar              touse
	mark                `touse'  `if' `in'
	markout             `touse'  `=   `vars''
	mata: problem = "general"
	mata: if (ustrregexm(`"`anything'"',                       "ap|tm", 1)) ///
		  problem =      "ap";;
	mata: if (ustrregexm(`"`anything'"',                     "cmls|rp", 1)) ///
		  problem =    "cmls";;
	mata:     C = J(0,0,.)
	if  "`constraints'"  != ""                                                {
		mata: if (! hasmissing( _st_varindex(tokens("`constraints'"    )))) ///
			  C =   st_data(.,  _st_varindex(tokens("`constraints'"    )),  ///
			                                        "`touse'"             );;
		mata: if (J(0,0,.)        !=      st_matrix("`constraints'"      )) ///
			  C =                         st_matrix("`constraints'"       );;
	}
	mata:     S = J(0,0,.)
	if  "`slackvars'"    != ""                                                {
		mata: if (! hasmissing( _st_varindex(tokens("`slackvars'"      )))) ///
			  S =   st_data(.,  _st_varindex(tokens("`slackvars'"      )),  ///
			                                        "`touse'"             );;
		mata: if (J(0,0,.)        !=      st_matrix("`slackvars'"        )) ///
			  S =                         st_matrix("`slackvars'"         );;
	}
	mata:     M  =J(0,0,.)
	if  "`model'"        != ""                                                {
		mata: if (! hasmissing( _st_varindex(tokens("`model'"          )))) ///
			  M =   st_data(.,  _st_varindex(tokens("`model'"          )),  ///
			                                        "`touse'"             );;
		mata: if (J(0,0,.)        !=      st_matrix("`model'"            )) ///
			  M =                         st_matrix("`model'"             );;
	}
	mata:     b  =J(0,0,.)
	if  "`b'"            != ""                                                {
		mata: if (! hasmissing( _st_varindex(tokens("`b'"              )))) ///
			  b =   st_data(.,  _st_varindex(tokens("`b'"              )),  ///
			                                        "`touse'"             );;
		mata: if (J(0,0,.)        !=      st_matrix("`b'"                )) ///
			  b =                         st_matrix("`b'"                 );;
	}
	mata: m              =  `m'                    ? `m'                  : .
	mata: p              =  `p'                    ? `p'                  : .
	mata: i              =  `i'                    ? `i'                  : 1
	mata: j              =  `j'                    ? `j'                  : 1
	mata: zero_diagonal  = "`zerodiagonal'" != ""  ?  1                   : 0
	mata: r              =  `r'                    ? `r'                  : 1
	mata:     Z  =J(0,0,.)
	if  "`z'"            != ""                                                {
		mata: if (J(0,0,.)        !=      st_matrix("`z'"                )) ///
			  Z  =                        st_matrix("`z'"                 );;
	}
	mata: rcond          =  `rcond'         >   0  ? `rcond'                ///
						 : (`rcond'         <   0  ?  1                   : .)
	mata: tolerance      =  `tolerance'     >=  0  ? `tolerance'          : .
	mata: iteration_limit=  `iterationlimit'       ? `iterationlimit'     : .
	mata: final          = "`final'"        != ""  ?  0                   : 1
	// make the command metadata (clspl2 can be both standalone and nested)     
	loc cmdline          =   cond("`nested'"!= ""  & "`e(cmdline)'"  != "", ///
								  "`e(cmdline)'",    "clspl2  `0'        ")
	loc cmd              =   cond("`nested'"!= ""  & "`e(cmd)'"      != "", ///
								  "`e(cmd)'",        "clspl2             ")
	loc estat_cmd        =   cond("`nested'"!= ""  & "`e(estat_cmd)'"!= "", ///
								  "`e(estat_cmd)'",  "clspl2 estat       ")
	loc title            =   cond("`nested'"!= ""  & "`e(title)'"    != "", ///
								  "`e(title)'",      "CLSP estimation    ")
	if  "`nested'" !=  ""                                                   ///
	foreach  s   in    full model_n model_i reduced    /* tmpinvl2   */       {
		loc           `s' "`e(`s')'"
	}
	// estimate with the help of the CLSPL2 Mata class                          
	mata: if (b == J(0,0,.))                                   {            ///
		      errprintf("RHS error: b() is misspecified\n");                ///
		      exit(198);                                                    ///
		  };;
	mata: if (C == J(0,0,.) & M == J(0,0,.) & m == . & p == .) {            ///
		      errprintf("LHS error: all of constraints(), model(), m(), " + ///
		                "and p() are misspecified\n");                      ///
		      exit(198);                                                    ///
		  };;
	mata: CLSP = CLSPL2();                                                  ///
		  CLSP.solve(problem, C, S, M, b, m, p, i, j, zero_diagonal,        ///
		                      r, Z, rcond, tolerance, iteration_limit,      ///
		                      final, `condtolerance')
	mata: mata drop           C  S  M  b  m  p  i  j  zero_diagonal         ///
		                      r  Z  rcond  tolerance  iteration_limit       ///
		                      final
	mata: st_eclear()                                  // store results
	eret post,         esample(`touse')
	qui  count   if    e(sample)
	eret sca N      =  r(N)
	foreach  s   in    iteration_limit r rcond tolerance alpha kappaC		///
					   kappaB kappaA r2_partial nrmse nrmse_partial           {
		_store  `s',   r(e) t(scalar)
	}
	foreach  s   in    cmdline cmd estat_cmd  title                         ///
					   full model_n model_i reduced    /* tmpinvl2   */       {
		eret loc      `s' ``s''
	}
	if ("`nested'" !=  "" & "`e(cmd)'" ==  "clspl2")   error 199
	foreach  s   in    final seed distribution                                {
		_store  `s',   r(e) t(macro )
	}
	foreach  s   in    A C_idx b Z zhat z x y z_lower z_upper x_lower		///
											  x_upper y_lower y_upper         {
		_store  `s',   r(e) t(matrix)
	}
	if ("`nested'" !=  "" & "`x'"      !=  ""      )                        ///
	mata: st_matrix("e(X)",       st_matrix("e(x)"))
	_summary, noread								   // store summary
end

program define _estat, eclass
	version 15.1
	tempname tmp warnings error bar
	// assert last result                                                       
	cap conf mat e(z)
	if _rc {
		di as err "results of clspl2 not found"
		exit 301
	}
	// syntax                                                                   
	syntax																	///
	[anything], [															///
		RESET THRESHold(real 0) BAR HBAR MATrix(name) NCOLs(int 1)			///
		SAMPLEsize(int 50) SEED(int 0) DISTribution(string) PARTial			///
		SIMulate Level(cilevel)												///
	]
	// adjust and preprocess options for the CLSPL2 Mata class                  
	if ("`anything'"                                         == "")           {
		di as err "subcommand required"
		exit 321
	}
	if (`threshold'                          <  0)                            {
		di as err "threshold() must be non-negative"
		exit 198
	}
	if ("`bar'"               != "" & "`hbar'"               != "")           {
		di as err "must specify either bar or hbar option"
		exit 198
	}
	loc   matrix         = cond("`matrix'"  != "",  "`matrix'", "rmsa_i")
	mata: reset          = "`reset'"        != ""  ?  1                   : 0
	mata: threshold      =  `threshold'            ? `threshold'          : .
	mata: sample_size    =  `samplesize'           ? `samplesize'         : .
	mata: seed           =  `seed'                 ? `seed'               : .
	mata: distribution   = "`distribution'"
	mata: partial        = "`partial'"      != ""  ?  1                   : 0
	mata: simulate       = "`simulate'"     != ""  ?  1                   : 0
	// compute the structural correlogram of the CLSP constraint system         
	if  ustrregexm( `"`anything'"',                "^corr",      1)           {
		_read
		qui mata: CLSP.corr(reset, threshold)          // store results
		foreach  s   in    rmsa                                               {
			_store  `s',   r(e) t(scalar)
		}
		foreach  s   in    rmsa_i rmsa_dkappaC rmsa_dkappaB rmsa_dkappaA	///
						   rmsa_dnrmse rmsa_dzhat rmsa_dz rmsa_dx             {
			_store  `s',   r(e) t(matrix)
		}
		_summary, noread							   // store summary
		if "`bar'"      != ""  |											///
		   "`hbar'"     != ""                                                 {
			loc b        = cond("`bar'" != "",    "bar", "hbar")
			tempname f
			mkf     `f'
			frame   `f':   qui svmat    e(`matrix'), n(`matrix')
			frame   `f':   qui g constraint    = _n
			frame   `f':   if `: colsof e(`matrix')' < 2 ren `matrix'* `matrix'
			loc j    = 1							   // plot result
			frame   `f':   foreach var of varl               `matrix'*        {
				graph `b' `var', over(constraint) title("`var'")			///
								 name(_clsp`j', replace) nodraw
				loc  g "`g' _clsp`j'"
				loc  ++j
			}
			graph combine   `g', cols(`ncols'   )							///
								 name(`matrix', replace) nodraw
			graph drop      `g'
			graph display   `matrix'
		}
		exit 0
	}
	// perform bootstrap or Monte Carlo t-tests on the NRMSE statistic from the 
	// CLSP estimator                                                           
	if  ustrregexm( `"`anything'"',                "^ttest",     1)           {
		_read
		qui mata: CLSP.ttest(reset, sample_size, seed, distribution,        ///
			                 partial,  simulate)       // store results
		foreach  s   in    nrmse_ttest                                        {
			_store  `s',   r(e) t(matrix)
		}
		tempname f
		mkf     `f'
		frame   `f':   qui svmat    e(nrmse_ttest), n(nrmse_ttest)
		frame   `f':   ren            nrmse_ttest*    nrmse_ttest
		frame   `f':   qui sum
		loc t   `r(N)' `r(mean)' `r(sd)'									///
				`=cond("`partial'" != "",e(nrmse_partial),e(nrmse))'
		_summary, noread							   // store summary
		ttesti  `t', l(`level')						   // print ttest
		exit 0
	}
	di as err "{bf:estat `anything'} not valid"
	exit 321
end

program define _read, sclass
	version 15.1
	// scalars, macros, and matrices in e()                                     
	mata: CLSP =  CLSPL2()
	foreach  s   in    iteration_limit r rcond tolerance alpha kappaC		///
					   kappaB kappaA rmsa r2_partial nrmse nrmse_partial      {
		if            "`s'"    == "rcond"									///
		cap mata: CLSP.`s'     =  (tmp=st_numscalar("e(`s')")) >  0 ? tmp   ///
			                   :  (tmp                         <  0 ? 1   : .)
		else																///
		cap mata: CLSP.`s'     =  (tmp=st_numscalar("e(`s')")) != J(0,0,.)  ///
			                      ? tmp : .
	}
	foreach  s   in    final seed distribution                                {
			 if       "`s'"    == "final"									///
		cap mata: CLSP.`s'     =  st_global("e(`s')") == "True" ? 1 : 0
		else if       "`s'"    == "seed"									///
		cap mata: CLSP.`s'     =  strtoreal(st_global("e(`s')"))
		else if       "`s'"    == "distribution"							///
		cap mata: CLSP.`s'     =  st_global("e(`s')")
	}
	foreach  s   in    A C_idx b Z zhat z x y rmsa_i rmsa_dkappaC			///
					   rmsa_dkappaB rmsa_dkappaA rmsa_dnrmse rmsa_dzhat		///
					   rmsa_dz rmsa_dx nrmse_ttest z_lower z_upper x_lower	///
					   x_upper y_lower y_upper                                {
		loc tmp                =  cond("`s'" == "b", "rhs", "`s'")
		cap mata: CLSP.`s'     =  st_matrix("e(`tmp')")
	}
end

program define _reorder, eclass
	version 15.1
	loc rows =  e(C_idx)[1, 1]
	loc cols =  e(C_idx)[1, 2]
	// scalars, macros, and matrices in e()                                     
	foreach  s   in    N iteration_limit r rcond tolerance alpha kappaC		///
					   kappaB kappaA rmsa r2_partial nrmse nrmse_partial      {
		mata:          st_numscalar("e(`s')",      st_numscalar("e(`s')"),  ///
									anyof(("iteration_limit"    ),"`s'" )   ///
									?      "hidden" :"visible"          )
	}
	foreach  s   in    distribution seed final model_n model_i reduced		///
					   full title estat_cmd cmd cmdline                       {
		mata:             st_global("e(`s')",         st_global("e(`s')"),  ///
									anyof(("full", "reduced"),    "`s'" )   ///
									?      "hidden" :"visible"          )
	}
	foreach  s   in    y_upper y_lower x_upper x_lower z_upper z_lower		///
					   nrmse_ttest rmsa_dx rmsa_dz rmsa_dzhat rmsa_dnrmse	///
					   rmsa_dkappaA rmsa_dkappaB rmsa_dkappaC rmsa_i y x z	///
					   zhat X Z rhs C_idx A                                   {
		mata:             st_matrix("e(`s')",         st_matrix("e(`s')"),  ///
									anyof(("Z","rhs","C_idx","A"),"`s'" ) | ///
									ustrregexm("`s'","(rmsa|ttest)",   1)   ///
									?      "hidden" :"visible"          )
		cap conf mat e(`s')
		if      _rc                   continue
		if      inlist(  "`s'",        "X","x","x_lower","x_upper"      )	///
		mata:   st_local( "x" ,     cols(st_matrix("e(`s')")) ==  1         ///
			                               ?      `","`s'""'      :  "" )
		if               "`x'" == ""  continue   /* skip if non-vector       */
		mata:   tmp =           st_matrixrowstripe("e(`s')"             )
			 if inlist(  "`s'", "A","rhs"                               )	///
		mata:   tmp[.,          1] =             J( rows(tmp),    1, "M");  ///
			    tmp[1..`rows',  1] =             J(`rows',        1, "C");
		else if inlist(  "`s'", "C_idx"                                 )	///
		mata:   tmp =                             ("",               "C");
		else if inlist(  "`s'", "Z","zhat","z","z_lower","z_upper"   `x')	///
		mata:   tmp[.,          1] =             J( rows(tmp),    1, "S");  ///
			    tmp[1..`cols',  1] =             J(`cols',        1, "C");
		else if inlist(  "`s'", "y","y_lower","y_upper"                 )	///
		mata:   tmp[.,          1] =             J( rows(tmp),    1, "S");
		mata:                   st_matrixrowstripe("e(`s')",                ///
			                    /* row    stripes     */ tmp            )
		mata:   tmp =           st_matrixcolstripe("e(`s')"             )
			 if inlist(  "`s'", "A","Z"                                 )	///
		mata:   tmp[.,          1] =             J( rows(tmp),    1, "S");  ///
			    tmp[1..`cols',  1] =             J(`cols',        1, "C");
		else if inlist(  "`s'", "C_idx"                                 )	///
		mata:   tmp =                             ("","rows")\("","cols");
		else if inlist(  "`s'", "rmsa_dzhat","rmsa_dz","rmsa_dx"        )	///
		mata:   tmp[.,          1] =             J( rows(tmp),    1, "S");  ///
			    tmp[1..`cols',  1] =             J(`cols',        1, "C");
		else																///
		mata:   tmp =                             ("",             "`s'");
		mata:                   st_matrixcolstripe("e(`s')",                ///
			                    /* column stripes     */ tmp            )
	}
	// macros and matrices in r()                                               
	foreach  s   in    inverse                                                {
		mata:             st_global("r(`s')",         st_global("r(`s')"))
	}
	foreach  s   in    y_upper y_lower x_upper x_lower z_upper z_lower		///
					   rmsa_dx rmsa_dz rmsa_dzhat rmsa_dnrmse rmsa_dkappaA	///
					   rmsa_dkappaB rmsa_dkappaC rmsa_i                       {
		mata:             st_matrix("r(`s')",         st_matrix("r(`s')"))
		cap conf mat r(`s')
		if _rc   continue
		mata:                   st_matrixrowstripe("r(`s')",  ("","`s'" ))
		mata:                   st_matrixcolstripe("r(`s')",                ///
			                                      ("","min" )\("","max" )\  ///
			                                      ("","mean")\("","sd"  ))
	}
end

program define _store, sclass
	version 15.1
	// syntax
	syntax name, Result(string) Type(string)
	loc result =             substr(strlower("`result'"),             1, 1)
	loc type   =          strproper(strlower("`type'"                    ))
	// scalars, macros, and matrices in e() and r()                             
	mata:     st_local("_fun",     ("numscalar",   "global",  "matrix"   )[ ///
		               selectindex(("Scalar",      "Macro",   "Matrix"   )  ///
		                           :==                          "`type'")])
	loc tmp    =             cond("`namelist'" == "b", "rhs", "`namelist'")
	if       "`namelist'" =="rcond"											///
	cap mata: st_`_fun'("`result'(`tmp')", CLSP.`tmp' >= . ?  0 :           ///
		                                  (CLSP.`tmp' >= 1 ? -1 : CLSP.`tmp'))
	else {
		if   "`namelist'" !="final"    &  "`namelist'"!= "seed"				///
		cap mata: st_`_fun'("`result'(`tmp')",          CLSP.`namelist')
		else																///
		cap mata: st_`_fun'("`result'(`tmp')",     "`namelist'" != "final"  ///
			                       ?          strofreal(CLSP.`namelist')    ///
			                       : ("False","True"  )[CLSP.`namelist'+1])
	}
	if _rc																	///
	cap mata: st_`_fun'("`result'(`tmp')",         "`type'" != "Macro"      ///
		                                           ? . : ""               )
end

program define _summary, sclass
	version 15.1
	tempname tmp
	if "`1'" == ""    _read
	mata:    st_rclear()                               // store results
	mata:    st_global("r(inverse)", (CLSP.Z != J(0,0,.))                 & ///
		                             (max(abs(CLSP.Z - I(rows(CLSP.Z))))  > ///
		                              CLSP.tolerance) ? "Bott-Duffin"       ///
		                                              : "Moore-Penrose")
	foreach  s   in    rmsa_i rmsa_dkappaC rmsa_dkappaB rmsa_dkappaA		///
					   rmsa_dnrmse rmsa_dzhat rmsa_dz rmsa_dx				///
					   z_lower z_upper x_lower x_upper y_lower y_upper        {
		cap mata: st_matrix("r(`s')",(tmp=min(CLSP.`s'),max(CLSP.`s'),      ///
			                                  mean(colshape(CLSP.`s', 1)),  ///
			                         sqrt(variance(colshape(CLSP.`s', 1)))) ///
			                         != J(1,4,.) ? tmp :(regexm("`s'","^y") ///
			                                     ? tmp : J(0,0,.)        ))
	}
	cap mata: mata drop CLSP
	_reorder
	if ("`e(cmd)'" == "tmpinvl2"     &  "`e(full)'" != "True")				///
	di as  res  _n                                               "Reduced "	///
	   ustrregexrf(strproper("`e(title)'"), "pinv", "Pinv", 1)    " Model:"	///
	   as  txt  _n  %-20s                                     "  Position:"	///
	   as  res      %18s                    " `e(model_i)' of `e(model_n)'"
	loc p  "partial"
	di as  res  _n "Estimator Configuration:"		   // print results
	mata:  display(_sprint("Generalized inverse",  st_global("r(inverse)"  )))
	mata:  display(_sprint("Iterations (r)",    st_numscalar("e(r)"        )))
	mata:  display(_sprint("Tolerance",         st_numscalar("e(tolerance)")))
	mata:  display(_sprint("Final correction",     st_global("e(final)"    )))
	mata:  display(                                usubinstr(               ///
				  _sprint("Regularization (a)", st_numscalar("e(alpha)")),  ///
				  "(a)",  "(α)",  .                                         ))
	di as  res  _n "Numerical Stability:"
	mata:  display(_sprint("kappaC",            st_numscalar("e(kappaC)"   )))
	mata:  display(_sprint("kappaB",            st_numscalar("e(kappaB)"   )))
	mata:  display(_sprint("kappaA",            st_numscalar("e(kappaA)"   )))
	cap conf sca e(rmsa)
	if ! _rc																///
	mata:  display(_sprint("rmsa",              st_numscalar("e(rmsa)"     )))
	cap conf mat r(rmsa_dz)
	if ! _rc																///
	foreach s in   rmsa_i rmsa_dkappaC rmsa_dkappaB rmsa_dkappaA			///
				   rmsa_dnrmse rmsa_dzhat rmsa_dz rmsa_dx                     {
		mata: display(_sprint("`s'",               st_matrix("r(`s')"      )))
	}
	di as  res  _n "Goodness of Fit:"
	mata:  display(_sprint("r2_`p'",            st_numscalar("e(r2_`p')"   )))
	mata:  display(_sprint("nrmse",             st_numscalar("e(nrmse)"    )))
	mata:  display(_sprint("nrmse_`p'",         st_numscalar("e(nrmse_`p')")))
	cap conf mat r(z_lower)
	if ! _rc																///
	foreach s in   z_lower z_upper x_lower x_upper y_lower y_upper            {
		mata: display(_sprint("`s'",               st_matrix("r(`s')"      )))
	}
end

* Mata code ***************                                                     
version 15.1

loc RS           real scalar
loc SS           string scalar
loc TR           transmorphic rowvector

mata:
mata set matastrict on

`SS' _sprint(`SS' l,    `TR' v)
{
    if (orgtype(v) == "scalar")
    return("  {txt}" + sprintf("%-20s", l + ":")                              +
             "{res}" + sprintf( "%16s", _format(v,    10)))
    else
    return("  {txt}" + sprintf("%-16s", l + ":") +  "min="                    +
             "{res}" + sprintf( "%10s", _format(v[1], 10))                    +
           "  {txt}"                             +  "max="                    +
             "{res}" + sprintf( "%10s", _format(v[2], 10))                    +
           "  {txt}"                             + "mean="                    +
             "{res}" + sprintf( "%10s", _format(v[3], 10))                    +
           "  {txt}"                             +   "sd="                    +
             "{res}" + sprintf( "%10s", _format(v[4], 10)))
}
`SS' _format(`TR' x, |  `RS' w)
{
    `RS'  dp, ep
    `SS'  fixed
    w     = w != . ? w : 10
    dp    = max((3, trunc(w / 2) - 1))
    ep    = max((2, dp           - 1))

    if (isstring(x)) return(sprintf("%"+strofreal(w)+"s",                   x))
    fixed =                 sprintf("%"+strofreal(w)+"."+strofreal(dp)+"f", x)
    if ( missing(x)) return(sprintf("%"+strofreal(w)+"."+strofreal(dp)+"f", .))
    if ( !  (abs(x)  >= 10^(-(dp + 1))      & abs(x)    <  10^(w - dp)      &
          strlen(fixed)    <=      w))
                     return(sprintf("%"+strofreal(w)+"."+strofreal(ep)+"e", x))
    else             return(fixed)
}
end
* an extra line to even the total number
