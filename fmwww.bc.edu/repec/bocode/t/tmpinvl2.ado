*! version 1.1.0  20nov2025  I I Bolotov
program define tmpinvl2, eclass byable(recall)
	version 15.1
	/*
		The Tabular Matrix Problems via Pseudoinverse Estimation (TMPinv) is a  
		two-stage estimation method that reformulates structured table-based    
		systems - such as allocation problems, transaction matrices, and        
		input–output tables - as structured least-squares problems. Based on the
		Convex Least Squares Programming (CLSP) framework, TMPinv solves systems
		with row and column constraints, block structure, and optionally reduced
		dimensionality by (1) constructing a canonical constraint form and      
		applying a pseudoinverse-based projection, followed by (2) a second     
		pseudoinverse estimation to improve fit, coherence, and achieve Ridge-  
		style regularization (based on the pure Stata/Mata CLSP implementation).

		Author: Ilya Bolotov, MBA, Ph.D.                                        
		Date: 20 August 2025                                                    
	*/
	tempname vars
	// check for third-party packages from SSC                                  
	cap which clspl2
	if _rc {
		di as err "clspl2 not found; install from SSC"
		exit 499
	}
	// replay last result                                                       
	if replay() {
		if _by() {
			error 190
		}
		cap conf mat e(X)
		if _rc {
			di as err "results of tmpinvl2 not found"
			exit 301
		}
		syntax, [REDuced(numlist int max=1 >=-`e(model_n)' <=`e(model_n)')]
		_update `reduced'							   // switch result
		clspl2										   // print summary
		exit 0
	}
	// syntax                                                                   
	syntax																	///
	[anything] [if] [in], [													///
		REDuced(int -1) BROW(string) BCOL(string) BVAL(string)				///
		Slackvars(string) MODel(string) i(int 1) j(int 1) ZERODiagonal		///
		SYMmetric LOWERbound(numlist miss) UPPERbound(numlist miss)			///
		REPLACEvalue(numlist miss max=1) r(passthru) Z(passthru)			///
		RCOND(passthru) TOLerance(real -1) ITERationlimit(int 1)			///
		noFINAL CONDTOLerance(passthru) SAving(string) *					///
	]
	// adjust and preprocess options for the TMPinvL2 Mata code                 
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
		mata:    rm_list   =          strtoreal(tokens("`r(numlist)'"));
		loc      full                 "False"
	}
	else                                                                      {
		mata:    rm_list   =          .,.;
		loc      full                 "True"
	}
	if ("`brow'" == ""            |  "`bcol'"                == "")           {
		di as err                     "both options brow() and bcol() required"
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
		if ("`model'"                                        == "")           {
			di as err                 "Both options model() and bval() "	///
									  "required"
			exit 198
		}
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
		if ("`bval'"                                         == "")           {
			di as err                 "Both options model() and bval() "	///
									  "required"
			exit 198
		}
	}
	if (`i' <  0            | `j'            <  0)                            {
		di as err "i() and j() must be non-negative"
		exit 198
	}
	if ("`lowerbound'"                                       != "")           {
		numlist " `lowerbound'",  miss
		mata:      lowerbound =   colshape(strtoreal(tokens("`r(numlist)'")),1)
	}
	else    mata:  lowerbound =   J(1,1,.)
	if ("`upperbound'"                                       != "")           {
		numlist " `upperbound'",  miss
		mata:      upperbound =   colshape(strtoreal(tokens("`r(numlist)'")),1)
	}
	else    mata:  upperbound =   J(1,1,.)
	if (`iterationlimit'                     <  1)                            {
		di as err "r() and iterationlimit() must be at least 1"
		exit 198
	}
	if ! (`tolerance' == -1 | (`tolerance' >= 0 & `tolerance' < 1))           {
		di as err "tolerance() must be -1 or lie in [0,1)"
		exit 198
	}
	if (`"`saving'"'                                         == "")           {
		loc saving       tmpinvl2
	}
	sca                 `vars'    = ""				   // markout [if] [in]
	foreach name in     `slackvars' `model' `brow' `bcol' `bval'              {
		cap conf var    `name'
		if ! _rc sca    `vars'    =   `vars' +  " `name'"
	}
	tempvar              touse
	mark                `touse'  `if' `in'
	markout             `touse'  `=   `vars''
	mata:     b1 =J(0,1,.)
	if  "`brow'"         != ""                                                {
		mata: if (! hasmissing( _st_varindex(tokens("`brow'"           )))) ///
			  b1 =  st_data(.,  _st_varindex(tokens("`brow'"           )),  ///
			                                        "`touse'"             );;
		mata: if (J(0,0,.)        !=      st_matrix("`brow'"             )) ///
			  b1 =                        st_matrix("`brow'"              );;
	}
	mata:     b2 =J(0,1,.)
	if  "`bcol'"         != ""                                                {
		mata: if (! hasmissing( _st_varindex(tokens("`bcol'"           )))) ///
			  b2 =  st_data(.,  _st_varindex(tokens("`bcol'"           )),  ///
			                                        "`touse'"             );;
		mata: if (J(0,0,.)        !=      st_matrix("`bcol'"             )) ///
			  b2 =                        st_matrix("`bcol'"              );;
	}
	mata:     b3 =J(0,1,.)
	if  "`bval'"         != ""                                                {
		mata: if (! hasmissing( _st_varindex(tokens("`bval'"           )))) ///
			  b3 =  st_data(.,  _st_varindex(tokens("`bval'"           )),  ///
			                                        "`touse'"             );;
		mata: if (J(0,0,.)        !=      st_matrix("`bval'"             )) ///
			  b3 =                        st_matrix("`bval'"              );;
	}
	mata:     S = J(rows(b1)+rows(b2),0,0)
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
	mata: symmetric      = "`symmetric'"    != ""                    ?  1 :  0
	mata: replace_value  =   strtoreal(     "`replacevalue'"              );
	mata:         st_local(  "tolerance",    `tolerance'             >= 0 ? ///
		                                      strofreal(`tolerance')      : ///
		                                      strofreal(sqrt(epsilon(1))) );
	loc   iterationlimit = cond(`iterationlimit' <  ., `iterationlimit',    50)
	// estimate with the help of the TMPinvL2 Mata code                         
	mata:         st_local(  "m",             strofreal(rows(b1) *  `i'));  ///
		          st_local(  "p",             strofreal(rows(b2) *  `j'));
	mata:         st_local(  "m_subset",      rm_list[1] < .              ? ///
		                                      strofreal(rm_list[1] - 1)   : ///
		                                      strofreal(            `m'));  ///
	mata:         st_local(  "p_subset",      rm_list[2] < .              ? ///
		                                      strofreal(rm_list[2] - 1)   : ///
		                                      strofreal(            `p'));
	mata:         st_local(  "model_n",       "`full'"    =="False"       ? ///
		                      strofreal(ceil(`m'/`m_subset')              * ///
		                                ceil(`p'/`p_subset'))    :  "1");   ///
		      if (rows(upperbound) > 1 & rows(upperbound) !=(n= `m'*`p')  | ///
		          rows(lowerbound) > 1 & rows(lowerbound) != n)           { ///
		          errprintf("Bounds length ("+strofreal(rows(lowerbound)) + ///
		                    ","              +strofreal(rows(upperbound)) + ///
		                    ") does not match number of variables "       + ///
		                    strofreal(n)      +                "\n"     );  ///
		          exit(198);                                                ///
		      };; h      = rows(upperbound) == 1 ?    J(n,1, upperbound)    ///
		                                         :           upperbound;    ///
		          l      = rows(lowerbound) == 1 ?    J(n,1, lowerbound)    ///
		                                         :           lowerbound;
						   /* perform bound-constrained iterative refinement */
	forval   _ =                                      1/`iterationlimit'      {
		mata:     C      = J(0,0,.); S_iter =J(0,0,.); M_iter2= J(0,0,.);   ///
			      b1_iter= J(0,1,.); b2_iter=J(0,1,.); b3_iter= J(0,1,.);   ///
			      b4_iter= J(0,1,.);
		if (`_'>  1      &    "`lowerbound'`upperbound'" != "")               {
			mata: result = colshape(X,                                1);   ///
				  M_idx  = selectindex((result :>= l :- `tolerance'   )  :& ///
				                       (result :<= h :+ `tolerance'   ));   ///
				  M      = I(n)  [M_idx,.];            /* overwrite M    */ ///
				  b3     = result[M_idx,.];            /* overwrite b3   */ ///
				  if (rows(M_idx) == n) (void) _stata("continue, break",1);;
		}
		else																///
		mata:     X      = J(`m',`p',.);                                    ///
						   /* perform full or reduced estimation             */
		if (`m_subset'   < `m' | `p_subset'   < `p'           )               {
			mata: if ("`zerodiagonal'"      != ""             )           { ///
				      M_diag = J(min((`m',`p')),       n,0);                ///
				      b_diag = J(min((`m',`p')),       1,0);                ///
				      for (k = 1; k <= min((`m',`p')); k++)                 ///
				      M_diag[k,(k-1)*`p'+k] = 1; tmp =    .;                ///
				      M_iter =_uniqrows_tagindex(M!=J(0,0,.)              ? ///
				                                 M\M_diag  :  M_diag, tmp); ///
				      b3     =                            (b3\b_diag)[tmp]; ///
				  } else                         M_iter = M;                ///
				  if (M_iter != J(0,0,.)                      )           { ///
				      if ( ! (all((M_iter:==0):|(M_iter:==1))             & ///
				              all(rowsum(M_iter)       :==1)              & ///
				              all(colsum(M_iter)       :<=1)) )           { ///
				          errprintf("M must be a unique row subset of "   + ///
				                    "the  identity matrix in the "        + ///
				                                      "reduced model\n"  ); ///
				          exit(198);                                        ///
				      };;                                                   ///
				      X_true = J(1*`m',`p',.);                              ///
				      for (idx = 1; idx <=  rows(M_iter);idx++)           { ///
				          col  =    max((1..cols(M_iter))                :* ///
				                                (M_iter[ idx,.]:==  1 )  ); ///
				          X_true[   floor((col-1)/`p')+1,mod(col-1,`p')+1]= ///
				                                                   b3[idx]; ///
				      };;                                                   ///
				  };;                                                       ///
				  if (        "`lowerbound'`upperbound'" != "")           { ///
				      X_lim  = J(2*`m',`p',.);                              ///
				      for (idx = 1; idx <=  rows(C=I(n));idx++)           { ///
				          col  =    max((1..cols(C)):*(C[idx,.]:==  1 )  ); ///
				          X_lim[    floor((col-1)/`p')+1,mod(col-1,`p')+1]= ///
				                                                    h[idx]; ///
				          X_lim[`m'+floor((col-1)/`p')+1,mod(col-1,`p')+1]= ///
				                                                    l[idx]; ///
				      };;                                                   ///
				  };;                                                       ///
				  if (S      != J(0,0,.) & any(S :!= 0)                   & ///
				                              `_' == 1        )           { ///
				      displayas( "txt"                                   ); ///
				      printf("Warning: User-provided S is ignored "       + ///
				                           "in the reduced model\n"      ); ///
				  };;
		}
		loc       model_i=                           0
		forval    rblock =                      1/`= ceil(`m'/`m_subset' )'   {
		forval    cblock =                      1/`= ceil(`p'/`p_subset' )'   {
		tempname  b c s M
		if (`m_subset'   < `m' | `p_subset'   < `p'           )               {
			mata: m_start=(`rblock'-1) * `m_subset'+ 1;                     ///
				  m_end  =min((m_start + `m_subset'- 1,   `m'));            ///
				  p_start=(`cblock'-1) * `p_subset'+ 1;                     ///
				  p_end  =min((p_start + `p_subset'- 1,   `p'));            ///
				  S_iter =  I((m_iter=m_end-m_start+ 1)                   + ///
				              (p_iter=p_end-p_start+ 1)       );            ///
				  b1_iter=  b1[m_start :: m_end];                           ///
				  b2_iter=  b2[p_start :: p_end];                           ///
				  if (M_iter != J(0,0,.)                      )           { ///
				      subset =  colshape(X_true[   m_start::    m_end,      ///
				                                   p_start..    p_end], 1); ///
				      if (any((nempty=    subset   :<.)      ))           { ///
				          b3_iter=        select(subset,       nempty);     ///
				          M_iter2= I(rows(subset))[selectindex(nempty), .]; ///
				      } else                                              { ///
				          b3_iter= J(0,1,.);                                ///
				          M_iter2= J(0,0,.);                                ///
				      };                                                    ///
				  };;                                                       ///
				  if (        "`lowerbound'`upperbound'" != "")           { ///
				      subset =  colshape(X_lim[    m_start::    m_end,      ///
				                                   p_start..    p_end]    \ ///
				                         X_lim[`m'+m_start::`m'+m_end,      ///
				                                   p_start..    p_end], 1); ///
				      if (any((nempty=    subset   :<.)      ))           { ///
				          b4_iter=        select(subset,       nempty);     ///
				          C      = (J(2,1,I((k=rows(subset)/2))        ))[  ///
				                                   selectindex(nempty), .]; ///
				          S      = (I(k),   J(k,k,0)\         J(k,k,0),     ///
				                   -I(k)         )[selectindex(nempty), .]; ///
				          S_iter = (S_iter, J(rows(S_iter), cols(S),0)    \ ///
				                            J(rows(S), cols(S_iter),0),     ///
				                    S                                    ); ///
				      } else                                              { ///
				          b4_iter= J(0,1,.);                                ///
				          C      = J(0,0,.);                                ///
				      };                                                    ///
				  };;
		}
		else {
			mata: m_iter =      `m';                                        ///
				  p_iter =      `p';                                        ///
				  M_iter2=M;     b1_iter= b1; b2_iter= b2; b3_iter= b3;     ///
				  if (        "`lowerbound'`upperbound'" != "")           { ///
				          b4_iter=        select( (blim=h\l),blim :<.);     ///
				          C      =        select(J(2,1,I(n)),blim :<.);     ///
				          S_iter = (S,    J(rows(S),2*n,0)\( Slim=          ///
				                          J(n,cols(S),0),I(n),J(n,n,0)    \ ///
				                          J(n,cols(S)+n,0),                 ///
				                         -I(n))[selectindex(blim :< .),.]); ///
				 };;
		}
			mata: if (b1_iter== J(0,1,.) & b2_iter== J(0,1,.) )           { ///
				      errprintf("RHS error: brow() and bcol() are "       + ///
				                                   "misspecified\n"      ); ///
				      exit(198);                                            ///
				  };;                                   /* blim first */    ///
				      st_matrix("`b'",   b1_iter\b2_iter\b4_iter\b3_iter ); ///
				      st_matrix("`c'",   C                               ); ///
				      st_matrix("`s'",   select(S_iter,                     ///
				                         colsum(S_iter)      :!=       0)); ///
				      st_matrix("`M'",   M_iter2                         );
			mata:     st_local(  "u",    strofreal(m_iter               )); ///
				      st_local(  "v",    strofreal(p_iter               )); ///
				      st_local(  "c",    st_matrix("`c'")     != J(0,0,.) ? ///
				                         "   const( `c' )" :  ""         ); ///
				      st_local(  "s",    st_matrix("`s'")     != J(0,0,.) ? ///
				                         "   slack( `s' )" :  ""         ); ///
				      st_local(  "M",    st_matrix("`M'")     != J(0,0,.) ? ///
				                         "   model( `M' )" :  ""         );
			eret loc cmdline   tmpinvl2 `0'
			eret loc cmd       tmpinvl2
			eret loc estat_cmd tmpinvl2 estat
			eret loc title     TMPinv estimation
			eret loc full     `full'
			eret loc model_n  `model_n'
			if "`full'"        == "False"									///
			eret loc model_i   =`model_i' + 1
				 loc model_i   = cond("`e(model_i)'" != "", "`e(model_i)'", ///
															"  `model_i' "  )
			if "`full'"        == "False"									///
			eret loc reduced   = ustrregexra(`"`saving'"',  "[.]ster", "", 1)
			qui  clspl2 ap,    b(`b') `c' `s' `M' m(`u') p(`v') i(`i') j(`j')/*
							*/`=cond("`full'"!="False","`zerodiagonal'","")' /*
							*/`r' `z' `rcond'  tol(`tolerance')              /*
							*/ iter(`iterationlimit') `final' `condtolerance'/*
							*/ nested  x
			if "`full'"        == "False"									///
			qui  est  save   "`e(reduced)'",								///
							  `=cond("`model_i'"=="1","replace","append")'
			if "`full'"        == "False"									///
			mata: X[m_start::m_end,p_start..p_end] = st_matrix("e(X)");
			else															///
			mata: X            =                     st_matrix("e(X)");
			if "`full'"        != "False"            continue, break
		}
		}
			mata: X            =       ("`symmetric'" == "" ? X  : 0.5*(X+X'));
	}
						   /* replace out-of-bound values with replace_value */
	if (                       "`lowerbound'`upperbound'"!= "")             ///
	mata:         X      = colshape(X,                       1);            ///
		          idx    = selectindex((X :< l :- `tolerance')           :| ///
		                               (X :> h :+ `tolerance'));            ///
		          X[rows(idx) ? idx : J(0,1,.)]                           = ///
		          J(rows(idx),1,replace_value);                             ///
		          X      = colshape(X,`p');
						   /* ensure the result is properly stored           */
	if     "`full'" == "False"  tempfile  tmpf
	forval        i      =                      1/`e(model_n)'                {
		if "`full'" == "False"  qui est use      "`e(reduced)'",   number(`i')
		mata:         st_matrix("e(X)", "`symmetric'" == "" ? X  : 0.5*(X+X'));
		if "`full'" == "False"  qui est save      `tmpf',					///
										 `=cond("`i'"=="1","replace","append")'
	}
	if     "`full'" == "False"  copy     `tmpf'  "`e(reduced)'.ster", replace
						   /* update the result and display its summary      */
	_update `reduced'								   // switch result
	clspl2											   // print summary
	foreach s in  b1 b2 b3 S M X C S_iter M_iter M_iter2 b1_iter b2_iter    ///
				  b3_iter b4_iter result M_idx M_diag b_diag X_true X_lim   ///
				  subset nempty col idx tmp h l lowerbound upperbound       ///
				  replace_value symmetric rm_list k n blim Slim             ///
				  m_start m_end p_start p_end m_iter p_iter U hit r           {
		cap mata: mata drop  `s'                       // clean up
	}
end

program define _estat
	version 15.1
	// assert last result                                                       
	cap conf mat e(z)
	if _rc {
		di as err "results of tmpinvl2 not found"
		exit 301
	}
	// syntax                                                                   
	syntax																	///
	[anything], [															///
		REDuced(int -1) *													///
	]
	_update `reduced'								   // print summary
	clspl2   estat `=ustrregexrf(`"`anything'"',"^estat","",1)',     `options'
end

program define _update
	version 15.1
	args reduced

	if ("`e(full)'" == "False"          &  "`reduced'"    != ""           & ///
	    "`reduced'"                     != "`e(model_i)'"     ) {
		if               abs(`reduced') >   `e(model_n)'  {
			di as err  "list index out of range"
			exit 7102
		}
		mata:         st_global("e(model_i)",strofreal(  `reduced' < 0    ? ///
			                                `e(model_n)'+`reduced' + 1    : ///
			                                             `reduced'           ))
	}
	if ("`e(full)'" == "False"                                )               {
		mata:     X = st_matrix("e(X)"        );
		qui  est  use                      "`e(reduced)'", number(`e(model_i)')
		mata:         st_matrix("e(X)",      X);
		mata:     mata drop                  X         // clean up
	}
end

* Mata code ***************                                                     
version 15.1

loc RS        real scalar
loc RV        real colvector
loc RM        real matrix

mata:
mata set matastrict on

`RM' _uniqrows_tagindex(`RM' X, `TM' idx)
{
	/*
		--                                                                      
		M = `RM' _uniqrows_tagindex(M, tmp)                                     
		                      -  -                                              
		unique rows with first-occurrence indices                               
		                                                                        
		returns: (uniqrows(X))                                           (k x p)
	*/
	`RS' r
	`RM' U
	`RV' hit

	U   = uniqrows(X)
	idx = J(0, 1, .)
	for (r  = 1; r <= rows(U); r++) {
		hit = selectindex(rowsum(X :!= U[r,.]) :== 0)
		idx = idx \ hit[1]
	}
	return(U)
}
end
