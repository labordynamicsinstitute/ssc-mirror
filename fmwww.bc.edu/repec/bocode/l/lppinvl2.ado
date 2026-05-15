*! version 1.1.0  20nov2025  I I Bolotov
program define lppinvl2, eclass byable(recall)
	version 16.0
	/*
		The Linear Programming via Regularized Least Squares (LPPinv) is a two- 
		stage estimation method that reformulates linear programs as structured 
		least-squares problems. Based on the Convex Least Squares Programming   
		(CLSP) framework, LPPinv solves linear inequality, equality, and bound  
		constraints by (1) constructing a canonical constraint system and       
		computing a pseudoinverse projection, followed by (2) a second          
		pseudoinverse estimation to improve fit, coherence, and achieve Ridge-  
		style regularization (based on the pure Stata/Mata CLSP implementation).
		LPPinv is intended for underdetermined and ill-posed linear problems,   
		for which standard solvers fail.                                        

		Author: Ilya Bolotov, MBA, Ph.D.                                        
		Date: 20 August 2025                                                    
	*/
	tempname vars b c s
	// replay last result                                                       
	if replay() {
		if _by() {
			error 190
		}
		cap conf mat e(z)
		if _rc {
			di as err "results of lppinvl2 not found"
			exit 301
		}
		clspl2										   // print summary
		exit 0
	}
	// syntax                                                                   
	syntax																	///
	[anything] [if] [in], [													///
		AUB(string) AEQ(string) BUB(string) BEQ(string)						///
		LOWERbound(numlist miss) UPPERbound(numlist miss)					///
		REPLACEvalue(numlist miss max=1) r(passthru) Z(passthru)			///
		RCOND(passthru) TOLerance(real -1) ITERationlimit(int 1) noFINAL	///
		CONDTOLerance(passthru) *											///
	]
	// adjust and preprocess options for the LPPinvL2 Mata code                 
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
		numlist " `lowerbound'",  miss
		mata:      lowerbound =   colshape(strtoreal(tokens("`r(numlist)'")),1)
	}
	else    mata:  lowerbound =   J(1,1,.)
	if ("`upperbound'"                                       != "")           {
		numlist " `upperbound'",  miss
		mata:      upperbound =   colshape(strtoreal(tokens("`r(numlist)'")),1)
	}
	else    mata:  upperbound =   J(1,1,.)
	if (`iterationlimit'                                      <  1)           {
		di as err "r() and iterationlimit() must be at least 1"
		exit 198
	}
	if ! (`tolerance' == -1 | (`tolerance' >= 0 & `tolerance' < 1))           {
		di as err "tolerance() must be -1 or lie in [0,1)"
		exit 198
	}
	sca                 `vars'    = ""				   // markout [if] [in]
	foreach name in     `slackvars' `model' `brow' `bcol' `bval'              {
		cap conf var    `name'
		if ! _rc sca    `vars'    =   `vars' +  " `name'"
	}
	tempvar              touse
	mark                `touse'  `if' `in'
	markout             `touse'  `=   `vars''
	mata:     A1 =J(0,0,.)
	if  "`aub'"          != ""                                                {
		mata: if (! hasmissing( _st_varindex(tokens("`aub'"            )))) ///
			  A1 =  st_data(.,  _st_varindex(tokens("`aub'"            )),  ///
			                                        "`touse'"             );;
		mata: if (J(0,0,.)        !=      st_matrix("`aub'"              )) ///
			  A1 =                        st_matrix("`aub'"               );;
	}
	mata:     A2 =J(0,0,.)
	if  "`aeq'"          != ""                                                {
		mata: if (! hasmissing( _st_varindex(tokens("`aeq'"            )))) ///
			  A2 =  st_data(.,  _st_varindex(tokens("`aeq'"            )),  ///
			                                        "`touse'"             );;
		mata: if (J(0,0,.)        !=      st_matrix("`aeq'"              )) ///
			  A2 =                        st_matrix("`aeq'"               );;
	}
	mata:     b1 =J(0,1,.)
	if  "`bub'"          != ""                                                {
		mata: if (! hasmissing( _st_varindex(tokens("`bub'"            )))) ///
			  b1 =  st_data(.,  _st_varindex(tokens("`bub'"            )),  ///
			                                        "`touse'"             );;
		mata: if (J(0,0,.)        !=      st_matrix("`bub'"              )) ///
			  b1 =                        st_matrix("`bub'"               );;
	}
	mata:     b2 =J(0,1,.)
	if  "`beq'"          != ""                                                {
		mata: if (! hasmissing( _st_varindex(tokens("`beq'"            )))) ///
			  b2 =  st_data(.,  _st_varindex(tokens("`beq'"            )),  ///
			                                        "`touse'"             );;
		mata: if (J(0,0,.)        !=      st_matrix("`beq'"              )) ///
			  b2 =                        st_matrix("`beq'"               );;
	}
	mata: replace_value  =   strtoreal(     "`replacevalue'"              );
	mata:         st_local(  "tolerance",    `tolerance'             >= 0 ? ///
		                                      strofreal(`tolerance')      : ///
		                                      strofreal(sqrt(epsilon(1))) );
	loc   iterationlimit = cond(`iterationlimit' <  ., `iterationlimit',    50)
	// estimate with the help of the LPPinvL2 Mata code                         
	mata:     if (                      rows(A1) != rows(b1))             { ///
		          errprintf("A_ub and b_ub must have the same number of " + ///
		                    "rows: "    + strofreal(rows(A1))  +   " vs " + ///
		                                  strofreal(rows(b1))           );  ///
		          exit(198);                                                ///
		      };;                                                           ///
		      if (                      rows(A2) != rows(b2))             { ///
		          errprintf("A_eq and b_eq must have the same number of " + ///
		                    "rows: "    + strofreal(rows(A2))  +   " vs " + ///
		                                  strofreal(rows(b2))           );  ///
		          exit(198);                                                ///
		      };;                                                           ///
		      if (cols(A1) & cols(A2) & cols(A1) != cols(A2))             { ///
		          errprintf("A_ub and A_eq must have the same number of " + ///
		                    "columns: " + strofreal(cols(A1)) +    " vs " + ///
		                                  strofreal(cols(A2))           );  ///
		          exit(198);                                                ///
		      };;                                                           ///
		      if (ustrregexm(`"`anything'"',        "^non",1)             & ///
		                      "`lowerbound'`upperbound'"!= ""             & ///
		         (any(lowerbound :<0) | any(upperbound :<0)))             { ///
		          errprintf("Negative lower or upper bounds are not "     + ///
		                               "allowed in linear programs\n"   );  ///
		          exit(198);                                                ///
		      };;                                                           ///
		      if (rows(upperbound)> 1 & rows(upperbound)!=(n=max((cols(A1), ///
		                                                     cols(A2)  )))| ///
		          rows(lowerbound)> 1 & rows(lowerbound)!= n            ) { ///
		          errprintf("Bounds length ("+strofreal(rows(lowerbound)) + ///
		                    ","              +strofreal(rows(upperbound)) + ///
		                    ") does not match number of variables "       + ///
		                    strofreal(n)      +                "\n"     );  ///
		          exit(198);                                                ///
		      };; h =     (rows(upperbound) == 1 ?    J(n,1, upperbound)    ///
		                                         :           upperbound);   ///
		          l =      ustrregexm(`"`anything'"',          "^non",1)    ///
		            ?                                 J(n,1,          0)    ///
		            :     (rows(lowerbound) == 1 ?    J(n,1, lowerbound)    ///
		                                         :           lowerbound);   ///
		          b =      select((b=b1\b2\h\l),     (nempty=b      :<.));  ///
		      if (b        == J(0,1,.)                      )             { ///
		          errprintf("RHS error: bub() and beq() are mis"          + ///
		                                           "specified\n"        );  ///
		          exit(198);                                                ///
		      };; C =((A1  != J(0,0,.) ? A1 : J(0,cols(A2),.))            \ ///
		              (A2  != J(0,0,.) ? A2 : J(0,cols(A1),.))            \ ///
		                                      J(2,1,   I(n)))[selectindex(  ///
		                                                      nempty), .];  ///
		      if (C        == J(0,0,.)                      )             { ///
		          errprintf("RHS error: aub() and aeq() are mis"          + ///
		                                           "specified\n"        );  ///
		          exit(198);                                                ///
		      };; S =((S=I(rows(A1))\J(rows(A2),rows(A1),0)),               ///
		                             J(rows(S ),2*n,     0)               \ ///
		                             J(n,cols(S),  0), I(n),J(n,n,0)      \ ///
		                             J(n,cols(S)+n,0),-I(n) )[selectindex(  ///
		                                                      nempty), .];  ///
		      if (rows(C ) != rows(S )| rows(C ) != rows(b ))             { ///
		          errprintf("Row mismatch: C="+strofreal(rows(C ))        + ///
		                                ", S="+strofreal(rows(S ))        + ///
		                                ", b="+strofreal(rows(b ))+"\n" );  ///
		          exit(198);                                                ///
		      };; st_matrix("`b'",   b                                   ); ///
		          st_matrix("`c'",   C                                   ); ///
		          st_matrix("`s'",   select(S,    colsum(S ) :!=       0));
	mata:         st_local(  "c",    st_matrix("`c'")         != J(0,0,.) ? ///
		                             "   const( `c' )" :      ""         ); ///
		          st_local(  "s",    st_matrix("`s'")         != J(0,0,.) ? ///
		                             "   slack( `s' )" :      ""         );
	eret loc cmdline   lppinvl2 `0'
	eret loc cmd       lppinvl2
	eret loc estat_cmd lppinvl2 estat
	eret loc title     LPPinv estimation
	qui  clspl2 general, b(`b') `c' `s' `r' `z' `rcond'  tol(`tolerance')    /*
					  */ iter(`iterationlimit') `final' `condtolerance'      /*
					  */ nested
						   /* replace out-of-bound values with replace_value */
	if (                       "`lowerbound'`upperbound'"!= "")             ///
	mata:         x      = colshape(st_matrix("e(x)"),       1);            ///
		          idx    = selectindex((x :< l :- `tolerance')           :| ///
		                               (x :> h :+ `tolerance'));            ///
		          x[rows(idx) ? idx : J(0,1,.)]                           = ///
		          J(rows(idx),1,replace_value);                             ///
		          st_matrix("e(x)",     x    );
						   /* display the result summary                     */
	clspl2											   // print summary
	foreach s in  b1 b2 A1 A2 x b C S idx n h l lowerbound upperbound       ///
				  replace_value U hit r                                       {
		cap mata: mata drop  `s'                       // clean up
	}
end

program define _estat
	version 15.1
	// assert last result                                                       
	cap conf mat e(z)
	if _rc {
		di as err "results of lppinvl2 not found"
		exit 301
	}
	// syntax                                                                   
	syntax   [anything], [*]
	clspl2   estat `=ustrregexrf(`"`anything'"',"^estat","",1)',     `options'
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
