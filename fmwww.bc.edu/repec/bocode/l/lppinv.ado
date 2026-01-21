*! version 1.0.0  20aug2025  I I Bolotov
program define lppinv, eclass byable(recall)
	version 16.0
	/*
		The Linear Programming via Regularized Least Squares (LPPinv) is a two- 
		stage estimation method that reformulates linear programs as structured 
		least-squares problems. Based on the Convex Least Squares Programming   
		(CLSP) framework, LPPinv solves linear inequality, equality, and bound  
		constraints by (1) constructing a canonical constraint system and       
		computing a pseudoinverse projection, followed by (2) a convex-         
		programming correction stage to refine the solution under additional    
		regularization (e.g., Lasso, Ridge, or Elastic Net). LPPinv is intended 
		for underdetermined and ill-posed linear problems, for which standard   
		solvers fail.                                                           

		Author: Ilya Bolotov, MBA, Ph.D.                                        
		Date: 20 August 2025                                                    
	*/
	tempname vars CLSP warnings error
	// replay last result                                                       
	if replay() {
		if _by() {
			error 190
		}
		cap conf mat e(z)
		if _rc {
			di as err "results of lppinv not found"
			exit 301
		}
		_summary									   // print summary
		exit 0
	}
	// syntax                                                                   
	syntax																	///
	[anything] [if] [in], [													///
		AUB(string) AEQ(string) BUB(string) BEQ(string)						///
		LOWERbound(numlist miss) UPPERbound(numlist miss)					///
		REPLACEvalue(numlist miss max=1) r(int 1) Z(name) RCOND(real 0)		///
		TOLerance(real -1) ITERationlimit(int 0) noFINAL					///
		alpha(numlist >=-1 <=1 sort) CVXopt(string asis) MISSingokay *		///
	]
	// adjust and preprocess options for Python's LPPinv module                 
	if           ustrregexm( `"`anything'"',       "^estat",     1)           {
		_estat `=ustrregexrf(`"`anything'"',       "^estat", "", 1)', `options'
		exit 0
	}
	else if    ! ustrregexm( `"`anything'"',       "^(non|free)",1)           {
		di as error "invalid mode; specify {bf:nonneg} or {bf:free}"
		exit 198
	}
	if ("`aub'`aeq'"                                         == "")           {
		di as err "at least one of aub() or aeq() is required"
		exit 198
	}
	if ("`aub'"                                              != "")           {
			   cap unab varlist :     `aub'
		if _rc cap conf mat           `aub'
		else       loc  aub           `varlist'
		if _rc                                                                {
			di as err                 "aub: `aub'"
			di as err                 "invalid varlist or matrix"
			exit 198
		}
	}
	if ("`aeq'"                                              != "")           {
			   cap unab varlist :     `aeq'
		if _rc cap conf mat           `aeq'
		else       loc  aeq           `varlist'
		if _rc                                                                {
			di as err                 "aeq: `aeq'"
			di as err                 "invalid varlist or matrix"
			exit 198
		}
	}
	if ("`bub'`beq'"                                         == "")           {
		di as err "at least one of bub() or beq() is required"
		exit 198
	}
	if ("`bub'"                                              != "")           {
			   cap unab varlist :     `bub',       max(1)
		loc rc =   _rc
		if _rc cap conf mat           `bub'
		else       loc  bub           `varlist'
		if _rc     &  `rc' != 103 {
			di as err                 "bub: `bub'"
			di as err                 "invalid varname or matrix"
			exit cond(`rc' == 103, 103, 198)
		}
		else       if `rc' == 103 error 103
	}
	if ("`beq'"                                              != "")           {
			   cap unab varlist :     `beq',       max(1)
		loc rc =   _rc
		if _rc cap conf mat           `beq'
		else       loc  beq           `varlist'
		if _rc     &  `rc' != 103 {
			di as err                 "beq: `beq'"
			di as err                 "invalid varname or matrix"
			exit cond(`rc' == 103, 103, 198)
		}
		else       if `rc' == 103 error 103
	}
	if ("`lowerbound'"                                       != "")           {
		numlist " `lowerbound'", miss
		loc        lowerbound =  "[" +										///
								 ustrregexra(ustrregexra("`r(numlist)'",    ///
								 "[.][a-z]*(\s|$)","None$1"),"\s+",", ") + "]"
	}
	else    loc    lowerbound    "[None]"
	if ("`upperbound'"                                       != "")           {
		numlist " `upperbound'", miss
		loc        upperbound =  "[" +										///
								 ustrregexra(ustrregexra("`r(numlist)'",    ///
								 "[.][a-z]*(\s|$)","None$1"),"\s+",", ") + "]"
	}
	else    loc    upperbound    "[None]"
	if (`r' <  0 | `iterationlimit'          <  0)                            {
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
	if ("`alpha'"                                            != "")           {
		numlist " `alpha'"
		loc        alpha       `r(numlist)'
		foreach    a in        `alpha'                            {
			if ! (`a' == -1 | (`a' >= 0 & `a' <= 1)) {
				di as err "each value in alpha() must be -1 or lie in [0,1]"
				exit 198
			}
			if   (`a' == -1                        ) {
				loc alpha "None"
				continue, break
			}
		}
		if `: word count of `alpha''  > 1									///
			loc alpha =      "[" + ustrregexra("`alpha'", "\s+", ", ") + "]"
	}
	else    loc alpha     "None"
	loc   nonnegative "True"
	mata: if (ustrregexm(`"`anything'"',                       "free",  1)) ///
		  st_local("nonnegative",                              "False"    );;
	loc   _a       ", selectvar='`touse'', missingval=nan), dtype=float64"
	loc   A_array1 "None"
	if  "`aub'"          != ""                                                {
		mata: if (! hasmissing( _st_varindex(tokens("`aub'"            )))) ///
			  st_local("A_array1","_(array(Data.get('`aub''        `_a'))");;
		mata: if (J(0,0,.)        !=      st_matrix("`aub'"              )) ///
			  st_local("A_array1","array(Matrix.get('`aub''            ))");;
	}
	loc   A_array2 "None"
	if  "`aeq'"          != ""                                                {
		mata: if (! hasmissing( _st_varindex(tokens("`aeq'"            )))) ///
			  st_local("A_array2","_(array(Data.get('`aeq''        `_a'))");;
		mata: if (J(0,0,.)        !=      st_matrix("`aeq'"              )) ///
			  st_local("A_array2","array(Matrix.get('`aeq''            ))");;
	}
	loc   b_array1 "None"
	if  "`bub'"          != ""                                                {
		mata: if (! hasmissing( _st_varindex(tokens("`bub'"            )))) ///
			  st_local("b_array1","_(array(Data.get('`bub''        `_a'))");;
		mata: if (J(0,0,.)        !=      st_matrix("`bub'"              )) ///
			  st_local("b_array1","array(Matrix.get('`bub''            ))");;
	}
	loc   b_array2 "None"
	if  "`beq'"          != ""                                                {
		mata: if (! hasmissing( _st_varindex(tokens("`beq'"            )))) ///
			  st_local("b_array2","_(array(Data.get('`beq''        `_a'))");;
		mata: if (J(0,0,.)        !=      st_matrix("`beq'"              )) ///
			  st_local("b_array2","array(Matrix.get('`beq''            ))");;
	}
	loc   replacevalue   =cond("`replacevalue'"!= "","`replacevalue'","None")
	loc   r              =cond( `r',                 `r',                  1)
	loc   Z_array  "None"
	if  "`z'"            != ""                                                {
		mata: if (J(0,0,.)          !=    st_matrix("`z'"                )) ///
			  st_local("Z_array", "array(Matrix.get('`z''              ))");;
	}
	loc   rcond          =cond( `rcond'        >   0,     "`rcond'",		///
						  cond( `rcond'        <   0,        "True", "False"))
	loc   tolerance      =cond( `tolerance'    >=  0, "`tolerance'",      "")
	loc   iterationlimit =cond( `iterationlimit',"`iterationlimit'",      "")
	loc   final          =cond("`final'"       == "",        "True", "False")
	if `"`cvxopt'"'      != ""												///
	loc   cvxopt         =", " + ustrregexrf(`"`cvxopt'"',  "^\s*,",      "")
	// estimate with the help of Python's CLSP module                           
	sca                 `vars'    = ""
	foreach name in     `constraints' `slackvars' `model' `b' `z'             {
		cap conf var    `name'
		if ! _rc sca    `vars'    =   `vars' +  " `name'"
	}
	tempvar              touse
	mark                `touse'  `if' `in'
	if ("`missingokay'"  == "")												///
	markout             `touse'  `=   `vars''
	if ("`bub'"      == "None"  &        "`beq'"      == "None")              {
		di as err "RHS error: bub() and beq() are misspecified"
		error 7102
	}
	if ("`aub'"      == "None"  &        "`aeq'"      == "None")              {
		di as err "LHS error: aub() and aeq() are misspecified"
		error 7102
	}
	python: `CLSP', `warnings', `error' =   _(None, False,                  ///
	                                           fun=lppinv,                  ///
	                                      **dict(c=None,                    ///
	                                          A_ub=`A_array1',              ///
	                                          A_eq=`A_array2',              ///
	                                          b_ub=`b_array1',              ///
	                                          b_eq=`b_array2',              ///
	                                  non_negative=`nonnegative',           ///
	                                        bounds=_b(`lowerbound',         ///
	                                                  `upperbound'),        ///
	                                 replace_value=`replacevalue',          ///
	                                             r=`r',                     ///
	                                             Z=`Z_array',               ///
	                                         rcond=`rcond',                 ///
	`=cond("`tolerance'"     !="",      "tolerance=`tolerance',",     "")'  ///
	`=cond("`iterationlimit'"!="","iteration_limit=`iterationlimit',","")'  ///
	                                         final=`final',                 ///
	                                         alpha=`alpha'    `cvxopt'    ))
	python:         `warnings' = [SFIToolkit.displayln('{txt}note: '+k    ) ///
	                              for k in dict.fromkeys(str(w.message    ) ///
	                              for w in `warnings'                     )]
	python:                       Macro.setLocal("`error'", `error'       )
	if "``error''"  != ""                                                     {
		di as err   "``error''"
		exit 7102
	}
	mata: st_eclear()                                  // store results
	eret post,         esample(`touse')
	qui  count   if    e(sample)
	eret sca N      =  r(N)
	foreach  s   in    iteration_limit r tolerance alpha kappaC kappaB		///
					   kappaA r2_partial nrmse nrmse_partial                  {
		loc  code             "`CLSP'.`s'"
		_store  `s',   py(`code'       ) r(e) t(scalar)
	}
	eret loc cmdline   lppinv  `0'
	eret loc cmd       lppinv
	eret loc estat_cmd lppinv estat
	eret loc title     LPPinv estimation
	foreach  s   in    final seed distribution                                {
		loc  code   =  cond(! inlist("`s'", "distribution"      ),			///
							  "`CLSP'.`s'",									///
							  "`CLSP'.`s'.__code__.co_names[-1]")
		_store  `s',   py(`code', True ) r(e) t(macro )
	}
	foreach  s   in    A C_idx b Z zhat z x y z_lower z_upper x_lower		///
											  x_upper y_lower y_upper         {
		loc  code             "`CLSP'.`s'"
		_store  `s',   py(`code'       ) r(e) t(matrix)
	}
	python:  del   `warnings', `error'
	mata: st_global("s(clsp)","`CLSP'" )
	_summary, noread								   // store summary
end

program define _estat, eclass
	tempname tmp warnings error bar
	// assert last result                                                       
	cap conf mat e(z)
	if _rc {
		di as err "results of lppinv not found"
		exit 301
	}
	// syntax                                                                   
	syntax																	///
	[anything], [															///
		RESET THRESHold(real 0) BAR HBAR MATrix(name) NCOLs(int 1)			///
		SAMPLEsize(int 50) SEED(int 0) DISTribution(string) PARTial			///
		SIMulate Level(cilevel)												///
	]
	// adjust and preprocess options for Python's CLSP module                   
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
	loc   reset          =cond("`reset'"       != "",        "True", "False")
	loc   matrix         =cond("`matrix'"      != "",    "`matrix'","rmsa_i")
	loc   seed           =cond( `seed',                    "`seed'",  "None")
	loc   distribution   =cond("`distribution'"!= "",                       ///
												  "'`distribution''", "None")
	loc   partial        =cond("`partial'"     != "",        "True", "False")
	loc   simulate       =cond("`simulate'"    != "",        "True", "False")
	// compute the structural correlogram of the CLSP constraint system         
	if  ustrregexm( `"`anything'"',                "^corr",      1)           {
		_read
		python:  `tmp', `warnings', `error' = _(None, False,                ///
		                                         fun=`s(clsp)'.corr,        ///
		                                **dict(reset=`reset',               ///
		                                   threshold=`threshold'          ))
		python:         `warnings' = [SFIToolkit.displayln('{txt}note: '+k) ///
		                              for k in dict.fromkeys(str(w.message) ///
		                              for w in `warnings'                 )]
		python:                       Macro.setLocal("`error'", `error'   )
		if "``error''"  != ""												  {
			di as err      "``error''"
			exit 7102
		}
		loc CLSP            `s(clsp)'				   // store results
		foreach  s   in    rmsa                                               {
			loc  code      "  `CLSP'.`s'"
			_store  `s',   py(`code'       ) r(e) t(scalar)
		}
		foreach  s   in    rmsa_i rmsa_dkappaC rmsa_dkappaB rmsa_dkappaA	///
						   rmsa_dnrmse rmsa_dzhat rmsa_dz rmsa_dx             {
			loc  code      "  `CLSP'.`s'"
			_store  `s',   py(`code'       ) r(e) t(matrix)
		}
		python:  del   `warnings', `error'
		mata: st_global("s(clsp)","`CLSP'" )
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
		python:  `tmp', `warnings', `error' = _(None, False,                ///
		                                         fun=`s(clsp)'.ttest,       ///
		                                **dict(reset=`reset',               ///
		                                 sample_size=`samplesize',          ///
		                                        seed=`seed',                ///
		                                distribution=`distribution',        ///
		                                     partial=`partial',             ///
		                                    simulate=`simulate'           ))
		python:         `warnings' = [SFIToolkit.displayln('{txt}note: '+k) ///
		                              for k in dict.fromkeys(str(w.message) ///
		                              for w in `warnings'                 )]
		python:                       Macro.setLocal("`error'", `error'   )
		if "``error''"  != ""												  {
			di as err      "``error''"
			exit 7102
		}
		loc CLSP            `s(clsp)'				   // store results
		if "`seed'"                  != "None"								///
		mata: st_global("e(seed)",         "`seed'"                           )
		if "`distribution'"          != "None"								///
		mata: st_global("e(distribution)", subinstr("`distribution'","'","",.))
		foreach  s   in    nrmse_ttest                                        {
			loc  code      "  `CLSP'.`s'"
			_store  `s',   py(`code'       ) r(e) t(matrix)
		}
		tempname f
		mkf     `f'
		frame   `f':   qui svmat    e(nrmse_ttest), n(nrmse_ttest)
		frame   `f':   ren            nrmse_ttest*    nrmse_ttest
		frame   `f':   qui sum
		loc t   `r(N)' `r(mean)' `r(sd)' `e(nrmse)'
		python:  del   `warnings', `error'
		mata: st_global("s(clsp)","`CLSP'" )
		_summary, noread							   // store summary
		ttesti  `t', l(`level')						   // print ttest
		exit 0
	}
	di as err "{bf:estat `anything'} not valid"
	exit 321
end

program define _read, sclass
	version 16.0
	tempname tmp
	// scalars, macros, and matrices in e()                                     
	cap python:     `tmp'      = CLSP()
	foreach  s   in    iteration_limit r tolerance alpha kappaC kappaB		///
					   kappaA rmsa r2_partial nrmse nrmse_partial             {
		cap python: `tmp'.`s'  =      Scalar.getValue('e(`s')')
	}
	foreach  s   in    final seed distribution                                {
			 if      "`s'"     == "final"									///
		cap python: `tmp'.`s'  = bool(Macro.getGlobal('e(`s')'))
		else if      "`s'"     == "seed"									///
		cap python: `tmp'.`s'  =  int(Macro.getGlobal('e(`s')'))
		else if      "`s'"     == "distribution"                              {
			python: `tmp'.rng  = random.default_rng(`tmp'.seed)
			python: `tmp'.`s'  = lambda n:`tmp'.rng.`e(`s')'(size=(n, 1))
		}
		else																///
		cap python: `tmp'.`s'  =      Macro.getGlobal('e(`s')')
	}
	foreach  s   in    A C_idx b Z zhat z x y rmsa_i rmsa_dkappaC			///
					   rmsa_dkappaB rmsa_dkappaA rmsa_dnrmse rmsa_dzhat		///
					   rmsa_dz rmsa_dx nrmse_ttest z_lower z_upper x_lower	///
					   x_upper y_lower y_upper                                {
			 if      "`s'"     == "C_idx"									///
		cap python: `tmp'.`s'  =    [int(i) for i in Matrix.get('e(C_idx)')[0]]
		else if      "`s'"     == "b"										///
		cap python: `tmp'.`s'  =     array(Matrix.get('e(rhs)'), dtype=float64)
		else																///
		cap python: `tmp'.`s'  =     array(Matrix.get('e(`s')'), dtype=float64)
	}
	cap sret loc clsp   `tmp'						   // store object
end

program define _reorder, eclass
	version 16.0
	loc rows =  e(C_idx)[1, 1]
	loc cols =  e(C_idx)[1, 2]
	// scalars, macros, and matrices in e()                                     
	foreach  s   in    N iteration_limit r tolerance alpha kappaC kappaB	///
					   kappaA rmsa r2_partial nrmse nrmse_partial             {
		mata:          st_numscalar("e(`s')",      st_numscalar("e(`s')"),  ///
									anyof(("iteration_limit"    ),"`s'" )   ///
									?      "hidden" :"visible"          )
	}
	foreach  s   in    distribution seed final title estat_cmd cmd cmdline    {
		mata:             st_global("e(`s')",         st_global("e(`s')"),  ///
									anyof(("N/A"                ),"`s'" )   ///
									?      "hidden" :"visible"          )
	}
	foreach  s   in    y_upper y_lower x_upper x_lower z_upper z_lower		///
					   nrmse_ttest rmsa_dx rmsa_dz rmsa_dzhat rmsa_dnrmse	///
					   rmsa_dkappaA rmsa_dkappaB rmsa_dkappaC rmsa_i y x z	///
					   zhat Z rhs C_idx A                                     {
		mata:             st_matrix("e(`s')",         st_matrix("e(`s')"),  ///
									anyof(("Z","rhs","C_idx","A"),"`s'" ) | ///
									ustrregexm("`s'","(rmsa|ttest)",   1)   ///
									?      "hidden" :"visible"          )
		cap conf mat e(`s')
		if      _rc                   continue
		if      inlist(  "`s'",            "x","x_lower","x_upper"      )	///
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

program define _store, eclass
	version 16.0
	tempname tmp
	// syntax
	syntax name, PYthon(string asis) Result(string) Type(string)
	loc result =             substr(strlower("`result'"),             1, 1)
	loc type   =          strproper(strlower("`type'"                    ))
	// scalars, macros, and matrices in e() and r()                             
	mata:     st_local("_type",    ("scalar",      "local",   "matrix"   )[ ///
		               selectindex(("Scalar",      "Macro",   "Matrix"   )  ///
		                           :==                          "`type'")])
	mata:     st_local("_attr",    ("setValue",    "setLocal", "store"   )[ ///
		               selectindex(("Scalar",      "Macro",   "Matrix"   )  ///
		                           :== "`type'"                         )])
	mata:     st_local("_fun",     ("numscalar",   "global",  "matrix"   )[ ///
		               selectindex(("Scalar",      "Macro",   "Matrix"   )  ///
		                           :==                          "`type'")])
	cap python:      `type'.`_attr'('`tmp'',                  _( `python'))
	if _rc																	///
	mata:    st_`_fun'(   "`result'(`namelist')",  .                      )
	if       "`namelist'" == "b"                   loc namelist  "rhs"
	if       "`namelist'" == "C_idx"  |										///
			 "`result'"   == "r"											///
	mata:    st_matrix(   "`tmp'",                    st_matrix("`tmp'" )')
	mata:    st_`_fun'(   "`result'(`namelist')",                           ///
		     st_`=cond(   "`_fun'"!="global","`_fun'","local")'("`tmp'" ) )
end

program define _summary, sclass
	version 16.0
	tempname tmp warnings error
	if "`1'" == ""    _read
	python:  `tmp', `warnings', `error' = _(None, False,                    ///
	                                         fun=`s(clsp)'.summary,         ///
	                              **dict(display=False                    ))
	python:         `warnings' = [SFIToolkit.displayln('{txt}note: '+k)     ///
		                          for k in dict.fromkeys(str(w.message)     ///
		                          for w in `warnings'                     )]
	python:                       Macro.setLocal("`error'", `error'       )
	if "``error''"  != ""                                                     {
		di as err      "``error''"
		exit 7102
	}
	mata:    st_rclear()                               // store results
	foreach  s   in    inverse                                                {
		loc  code      "`tmp'['`s'']"
		cap _store `s', py(`code', True ) r(r) t(macro )
	}
	foreach  s   in    rmsa_i rmsa_dkappaC rmsa_dkappaB rmsa_dkappaA		///
					   rmsa_dnrmse rmsa_dzhat rmsa_dz rmsa_dx				///
					   z_lower z_upper x_lower x_upper y_lower y_upper        {
		loc  code      "`tmp'['`s'']"
		cap _store `s', py(`code'       ) r(r) t(matrix)
	}
	foreach  v   in           `s(clsp)' `tmp' `warnings' `error'              {
		cap  python:    del   `v'
	}
	cap sret loc clsp  ""
	_reorder
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
version 16.0

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

* Python 3 code ***********                                                     
version 16.0
python:
# Stata Function Interface
from sfi import  Data, Macro, Matrix, Scalar, SFIToolkit
# Python Modules
from   warnings  import catch_warnings, simplefilter
from   itertools import zip_longest
try:
    from  numpy  import nan, array, ndarray, float64, random
    from  clsp   import CLSP
    from  lppinv import lppinv
except:
    SFIToolkit.errprint('pylppinv not found; install from PyPI')
    SFIToolkit.error(7102)

def _(x, flag=False, fun=None, **kwargs):              # preprocess output
    if  fun is None:
        return  (str(x)           if flag                         else
                 float('nan')     if x is None  or (isinstance(x, ndarray)
                                                and x.size  == 0) else
                 x.reshape(-1, 1) if               (isinstance(x, ndarray)
                                                and x.ndim  == 1) else
                 array([a.ravel() for  a in x],             dtype=float64)
                                  if                isinstance(x, list   )
                                  and           all(isinstance(a, ndarray)
                                  for  a in x)                    else
                 list(x.values()) if                isinstance(x, dict   )
                                                                  else  x)
    else:
        result, warnings, error = None, [], ''
        with catch_warnings(record=True) as warnings:
            simplefilter('always')
            try:
                result = fun(**kwargs)
            except Exception as e:
                error  = str(   e)
        return  result, warnings, error

def _b(l, u):                                          # preprocess bounds
    bounds         =  [(a,b) for a,b in zip_longest(l, u, fillvalue=None)]
    if bounds      == [(None, None)]:
        return None
    if len(bounds) == 1:
        return bounds[0]
    else:
        return bounds
end
