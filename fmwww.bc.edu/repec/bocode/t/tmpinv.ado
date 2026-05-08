*! version 1.1.0  20nov2025  I I Bolotov
program define tmpinv, eclass byable(recall)
	version 16.0
	/*
		The Tabular Matrix Problems via Pseudoinverse Estimation (TMPinv) is a  
		two-stage estimation method that reformulates structured table-based    
		systems - such as allocation problems, transaction matrices, and        
		input–output tables - as structured least-squares problems. Based on the
		Convex Least Squares Programming (CLSP) framework, TMPinv solves systems
		with row and column constraints, block structure, and optionally reduced
		dimensionality by (1) constructing a canonical constraint form and      
		applying a pseudoinverse-based projection, followed by (2) a            
		convex-programming refinement stage to improve fit, coherence, and      
		regularization (e.g., via Lasso, Ridge, or Elastic Net).                

		Author: Ilya Bolotov, MBA, Ph.D.                                        
		Date: 20 August 2025                                                    
	*/
	tempname vars TMPinv warnings error
	// replay last result                                                       
	if replay() {
		if _by() {
			error 190
		}
		cap conf mat e(x)
		if _rc {
			di as err "results of tmpinv not found"
			exit 301
		}
		syntax, [REDuced(numlist int max=1 >=-`e(model_n)' <=`e(model_n)')]
		_update `reduced'							   // switch result
		_summary									   // print summary
		exit 0
	}
	// syntax                                                                   
	syntax																	///
	[anything] [if] [in], [													///
		REDuced(int -1) BROW(string) BCOL(string) BVAL(string)				///
		Slackvars(string) MODel(string) i(int 1) j(int 1) ZERODiagonal		///
		SYMmetric LOWERbound(numlist miss) UPPERbound(numlist miss)			///
		REPLACEvalue(numlist miss max=1) r(int 1) Z(name) RCOND(real 0)		///
		TOLerance(real -1) ITERationlimit(int 0) noFINAL					///
		alpha(numlist >=-1 <=1 sort) CVXopt(string asis) MISSingokay		///
		CONDTOLerance(real 1e-14) *											///
	]
	// adjust and preprocess options for Python's TMPinv module                 
	loc reduced =      cond(  "`reduced'"   != "", "`reduced'", "")
	loc options              `"`options'    reduced(`reduced')"'
	if           ustrregexm( `"`anything'"',       "^estat",     1)           {
		_estat `=ustrregexrf(`"`anything'"',       "^estat", "", 1)', `options'
		exit 0
	}
	else if      ustrregexm( `"`anything'"',       "\d+",        1)           {
		cap numlist          `"`anything'"',       int range(>=1) min(2) max(2)
		if _rc             == 125 {
			di as err                 "Each reduced block must be at "		///
									  "least (3, 3) to allow a solvable "	///
									  "CLSP submatrix with a slack "		///
									  "(surplus) structure"
			exit 198
		}
		else if _rc exit _rc
		loc      rm_list  =  "[" +											///
							  ustrregexra("`r(numlist)'", "\s+", ", ") + "]"
	}
	else    loc  rm_list  "None"
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
	if ("`brow'" == ""            &  "`bcol'"                == "")           {
		di as err "options brow() and bcol() required"
		exit 198
	}
	if ("`brow'"                                             != "")           {
			   cap unab varlist :     `brow',      max(1)
		loc rc =   _rc
		if _rc cap conf mat           `brow'
		else       loc  brow          `varlist'
		if _rc     &  `rc' != 103 {
			di as err                 "brow: `brow'"
			di as err                 "invalid varname or matrix"
			exit cond(`rc' == 103, 103, 198)
		}
		else       if `rc' == 103 error 103
	}
	if ("`bcol'"                                             != "")           {
			   cap unab varlist :     `bcol',      max(1)
		loc rc =   _rc
		if _rc cap conf mat           `bcol'
		else       loc  bcol          `varlist'
		if _rc     &  `rc' != 103 {
			di as err                 "bcol: `bcol'"
			di as err                 "invalid varname or matrix"
			exit cond(`rc' == 103, 103, 198)
		}
		else       if `rc' == 103 error 103
	}
	if ("`bval'"                                             != "")           {
			   cap unab varlist :     `bval',      max(1)
		loc rc =   _rc
		if _rc cap conf mat           `bval'
		else       loc  bval          `varlist'
		if _rc     &  `rc' != 103 {
			di as err                 "bval: `bval'"
			di as err                 "invalid varname or matrix"
			exit cond(`rc' == 103, 103, 198)
		}
		else       if `rc' == 103 error 103
	}
	if (`i' <  0            | `j'            <  0)                            {
		di as err "i() and j() must be non-negative"
		exit 198
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
	loc   _a       ", selectvar='`touse'', missingval=nan), dtype=float64"
	loc   S_array  "None"
	if  "`slackvars'"    != ""                                                {
		mata: if (! hasmissing( _st_varindex(tokens("`slackvars'"      )))) ///
			  st_local("S_array", "_(array(Data.get('`slackvars''  `_a'))");;
		mata: if (J(0,0,.)        !=      st_matrix("`slackvars'"        )) ///
			  st_local("S_array", "array(Matrix.get('`slackvars''      ))");;
	}
	loc   M_array  "None"
	if  "`model'"        != ""                                                {
		mata: if (! hasmissing( _st_varindex(tokens("`model'"          )))) ///
			  st_local("M_array", "_(array(Data.get('`model''      `_a'))");;
		mata: if (J(0,0,.)        !=      st_matrix("`model'"            )) ///
			  st_local("M_array", "array(Matrix.get('`model''          ))");;
	}
	loc   b_array1 "None"
	if  "`brow'"         != ""                                                {
		mata: if (! hasmissing( _st_varindex(tokens("`brow'"           )))) ///
			  st_local("b_array1","_(array(Data.get('`brow''       `_a'))");;
		mata: if (J(0,0,.)        !=      st_matrix("`brow'"             )) ///
			  st_local("b_array1","array(Matrix.get('`brow''           ))");;
	}
	loc   b_array2 "None"
	if  "`bcol'"         != ""                                                {
		mata: if (! hasmissing( _st_varindex(tokens("`bcol'"           )))) ///
			  st_local("b_array2","_(array(Data.get('`bcol''       `_a'))");;
		mata: if (J(0,0,.)        !=      st_matrix("`bcol'"             )) ///
			  st_local("b_array2","array(Matrix.get('`bcol''           ))");;
	}
	loc   b_array3 "None"
	if  "`bval'"         != ""                                                {
		mata: if (! hasmissing( _st_varindex(tokens("`bval'"           )))) ///
			  st_local("b_array3","_(array(Data.get('`bval''       `_a'))");;
		mata: if (J(0,0,.)        !=      st_matrix("`bval'"             )) ///
			  st_local("b_array3","array(Matrix.get('`bval''           ))");;
	}
	loc   i              =cond( `i',                 `i',                  1)
	loc   j              =cond( `j',                 `j',                  1)
	loc   zerodiagonal   =cond("`zerodiagonal'"!= "",        "True", "False")
	loc   symmetric      =cond("`symmetric'"   != "",        "True", "False")
	loc   replacevalue   =cond("`replacevalue'"!= "","`replacevalue'","None")
	loc   r              =cond( `r',                 `r',                  1)
	loc   Z_array  "None"
	if  "`z'"            != ""                                                {
		mata: if (! hasmissing( _st_varindex(tokens("`z'"              )))) ///
			  st_local("Z_array", "_(array(Data.get('`z''          `_a'))");;
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
	if ("`missingokay'"  == ""                                 )			///
	markout             `touse'  `=   `vars''
	if ("`b_array1'" == "None"  &        "`b_array2'" == "None")               {
		di as err "RHS error: brow() and bcol() are misspecified"
		error 7102
	}
	python: `TMPinv', `warnings', `error' = _(None, False,                  ///
	                                           fun=tmpinv,                  ///
	                                      **dict(S=`S_array',               ///
	                                             M=`M_array',               ///
	                                         b_row=`b_array1',              ///
	                                         b_col=`b_array2',              ///
	                                         b_val=`b_array3',              ///
	                                             i=`i',                     ///
	                                             j=`j',                     ///
	                                 zero_diagonal=`zerodiagonal',          ///
	                                       reduced=`rm_list',               ///
	                                     symmetric=`symmetric',             ///
	                                        bounds=_b(`lowerbound',         ///
	                                                  `upperbound'),        ///
	                                 replace_value=`replacevalue',          ///
	                                             r=`r',                     ///
	                                             Z=`Z_array',               ///
	                                         rcond=`rcond',                 ///
	`=cond("`tolerance'"     !="",      "tolerance=`tolerance',",     "")'  ///
	`=cond("`iterationlimit'"!="","iteration_limit=`iterationlimit',","")'  ///
	                                         final=`final',                 ///
	                                         alpha=`alpha',                 ///
	                                cond_tolerance=`condtolerance'          ///
	                                                              `cvxopt'))
	python:           `warnings' = [SFIToolkit.displayln('{txt}note: '+k  ) ///
	                                for k in dict.fromkeys(str(w.message  ) ///
	                                for w in `warnings'                   )]
	python:                         Macro.setLocal("`error'", `error'     )
	if "``error''"  != ""                                                     {
		di as err   "``error''"
		exit 7102
	}
	python:  del      `warnings', `error'
	mata:    st_eclear()                               // store results
	eret post,         esample(`touse')
	qui  count   if    e(sample)
	eret sca N      =  r(N)
	loc      code                                         "`TMPinv'.full "
	_store   full,     py(`code', True ) r(e) t(macro )
	python:            Macro.setGlobal(   "s(tmpinv)",    "`TMPinv'.model"    )
	if "`e(full)'"  == "True"												///
			 python:   Macro.setGlobal(   "s(clsp)",      "`TMPinv'.model"    )
	else     python:   Macro.setGlobal(   "e(reduced)",b64encode(compress(  ///
	                                   dumps(           _s(`TMPinv'.model), ///
	                                   protocol=HIGHEST_PROTOCOL),9)).decode())
	loc      code   =  cond("`e(full)'" == "True","1","len(`TMPinv'.model)"   )
	_store   model_n,  py(`code', True ) r(e) t(macro )
	loc      code                                         "`TMPinv'.x"
	_store   X,        py(`code'       ) r(e) t(matrix)
	eret loc cmdline   tmpinv  `0'
	eret loc cmd       tmpinv
	eret loc estat_cmd tmpinv estat
	eret loc title     TMPinv estimation
	_update `reduced'								   // switch result
	_summary, noread								   // store summary
end

program define _estat, eclass
	tempname tmp warnings error bar
	// assert last result                                                       
	cap conf mat e(z)
	if _rc {
		di as err "results of tmpinv not found"
		exit 301
	}
	// syntax                                                                   
	syntax																	///
	[anything], [															///
		REDuced(int -1)														///
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
		_update  `reduced'							   // switch result
		if     ("`e(full)'"                 ==     "True"         )  _read
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
		python:  del    `warnings', `error'
		mata: st_global("s(clsp)", "`CLSP'")
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
								 name(_tmpinv`j', replace) nodraw
				loc  g "`g' _tmpinv`j'"
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
		_update  `reduced'							   // switch result
		if     ("`e(full)'"                 ==     "True"         )  _read
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
		python:  del    `warnings', `error'
		mata: st_global("s(clsp)", "`CLSP'")
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
	foreach  s   in    iteration_limit r rcond tolerance alpha kappaC		///
					   kappaB kappaA rmsa r2_partial nrmse nrmse_partial      {
			 if      "`s'"     == "rcond"									///
		cap python: `tmp'.`s'  =  Scalar.getValue('e(`s')')                 ///
		                       if Scalar.getValue('e(`s')') > 0 else (True  ///
		                       if Scalar.getValue('e(`s')') < 0 else False)
		else																///
		cap python: `tmp'.`s'  =      Scalar.getValue('e(`s')')
	}
	foreach  s   in    final seed distribution                                {
			 if      "`s'"     == "final"									///
		cap python: `tmp'.`s'  = Macro.getGlobal('e(`s')') == "True"
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
	cap sret loc tmpinv   `tmp'						   // store object
	cap sret loc clsp     `tmp'
end

program define _reorder, eclass
	version 16.0
	loc rows =  e(C_idx)[1, 1]
	loc cols =  e(C_idx)[1, 2]
	// scalars, macros, and matrices in e()                                     
	foreach  s   in    N iteration_limit r rcond tolerance alpha kappaC		///
					   kappaB kappaA rmsa r2_partial nrmse nrmse_partial      {
		mata:          st_numscalar("e(`s')",      st_numscalar("e(`s')"),  ///
									anyof(("iteration_limit"),    "`s'" )   ///
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
		if      inlist(  "`s'",            "X","x","x_lower","x_upper"  )	///
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
	if       "`namelist'" == "rcond"										///
	cap python:      Macro.setLocal("python",  str(-1 if         `python'   ///
		                                           is True  else `python'))
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
	foreach  v   in           `s(tmpinv)' `s(clsp)' `tmp' `warnings' `error'  {
		cap  python:    del   `v'
	}
	cap sret loc tmpinv  ""
	cap sret loc clsp    ""
	_reorder
	if ("`e(full)'" != "True")												///
	di as  res  _n                                               "Reduced "	///
	   ustrregexrf(strproper("`e(title)'"), "tm\w+", "TMPinv", 1) " Model:"	///
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

program define _update, eclass
	version 16.0
	args reduced
	tempname tmp
	if ("`e(full)'" != "True"                                        )        {
		if (                               "`s(tmpinv)'" == "") {
			python:              `tmp'= _l(loads(decompress(b64decode(      ///
			                               Macro.getGlobal("e(reduced)"   )))))
			python:                        Macro.setGlobal("s(tmpinv)","`tmp'")
		}
		if ("`reduced'" != "" & "`reduced'" != "`e(model_i)'" ) {
			if               abs(`reduced') >   `e(model_n)'  {
				di as err  "list index out of range"
				exit 7102
			}
			mata:  st_global("e(model_i)",   strofreal(  `reduced' < 0    ? ///
				                            `e(model_n)'+`reduced' + 1    : ///
				                                         `reduced'           ))
		}
		mata:      st_global("s(clsp)",    "`s(tmpinv)'[`e(model_i)'-1]"      )
		if ("`e(distribution)'"             != ""             ) {
			loc      s         "rng"
			python: `s(clsp)'.`s'= random.default_rng(   `s(clsp)'.seed       )
			loc      s         "distribution"
			python: `s(clsp)'.`s'= lambda n:`s(clsp)'.rng.`e(`s')'(size=(n, 1))
		}
	}
	if ("`e(full)'" == "True" &            "`e(final)'"  != "") exit 0
	foreach  s   in    iteration_limit r rcond tolerance alpha kappaC		///
					   kappaB kappaA r2_partial nrmse nrmse_partial           {
		loc  code             "`s(clsp)'.`s'"
		_store  `s',   py(`code'       ) r(e) t(scalar)
	}
	mata:          st_global("e(cmdline)", ustrregexrf(                     ///
		           st_global("e(cmdline)"),"(res[ult]*)[(][^)]+[)]",        ///
		                                   "$1(`e(normal_i)')"    ))
	foreach  s   in    final seed distribution                                {
		loc  code   =  cond( !   inlist("`s'", "distribution"      ),		///
							  "`s(clsp)'.`s'",								///
							  "`s(clsp)'.`s'.__code__.co_names[-1]")
		_store  `s',   py(`code', True ) r(e) t(macro )
	}
	foreach  s   in    A C_idx b Z zhat z x y z_lower z_upper x_lower		///
											  x_upper y_lower y_upper         {
		loc  code             "`s(clsp)'.`s'"
		_store  `s',   py(`code'       ) r(e) t(matrix)
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
from   pickle    import dumps,   loads, HIGHEST_PROTOCOL
from   base64    import b64encode,      b64decode
from   bz2       import compress,       decompress
try:
    from  numpy  import nan, array, ndarray, float64, random
    from  clsp   import CLSP
    from  tmpinv import tmpinv
except:
    SFIToolkit.errprint('pytmpinv not found; install from PyPI')
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

def _s(m):                                             # clear for storing
    result  = []
    for obj in m:
        d   = {}
        for k, v in vars(obj).items():
            if k in ('rng',) or k.startswith('_') or callable(v):
                continue
            d[k] = v
        result.append(d)
    return  result

def _l(l):                                             # clear for loading
    result  = []
    for d   in l:
        obj = CLSP()
        for k, v in d.items():
            setattr(obj, k, v)
        result.append(obj)
    return  result
end
* an extra line to even the total number
