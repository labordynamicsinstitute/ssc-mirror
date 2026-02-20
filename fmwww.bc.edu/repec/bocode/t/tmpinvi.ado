*! version 1.0.2  20aug2025  I I Bolotov
program define tmpinvi, eclass byable(recall)
	version 16.0
	/*
		This program is a wrapper for the TMPinv-estimator commands tmpinv and  
		tmpinvl2 with options extending its functionality to pre/postestimation.
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
	tempfile tmpf
	tempname M bval solution
	tempvar  id
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
		syntax, [REDuced(numlist int max=1 >=-`e(model_n)' <=`e(model_n)')	///
				 PYthon L2]
		if (              "`python'" != ""  & "`l2'" != ""               ) {
			di as err "must specify either {bf:python} or {bf:l2} option"
			exit 198
		}
		// switch result and print summary
		loc tmpinv = cond("`python'" == "", "tmpinvl2",          "tmpinv")
		`tmpinv', `= cond("`reduced'"!= "", "reduced(`reduced')",      "")'
		exit 0
	}
	// syntax                                                                   
	syntax																	///
	[anything] [if] [in], [													///
		PYthon L2 IVAL(varlist) ILOWERbound(name) IUPPERbound(name)			///
		PREestimation(string asis) POSTestimation(string asis) LOOP			///
		Get(namelist) DOUBLE UPdate REPLACE FORCE FORmat(string) *			///
	]
	// adjust and preprocess options                                            
	if ("`python'"   != ""       &  "`l2'"       != ""    )                   {
		di as err "must specify either {bf:python} or {bf:l2} option"
		exit 198
	}
	if ("`ilowerbound'"                          != ""    )					///
	loc   ilowerbound = "=`ilowerbound'"
	if ("`iupperbound'"                          != ""    )					///
	loc   iupperbound = "=`iupperbound'"
	if ("`format'"   != ""                                )                   {
		conf fo `format'
	}
	// generate merge index and preserve for eventual changes in data           
	if ("`get'"      != ""                                )					///
	g `id'     = _n
	if ("`get'"      != ""       |  "`_byvars'"  != ""    )					///
	preserve
	// manually process _byindex() in the absence of marksample                 
	if ("`_byvars'"                              != ""    )					///
	qui keep   if  `_byindex'    == _byindex()
	// run preestimation command/program (= multiple commands)                  
	if trim(`"`preestimation'"'  )               != ""    {
			  `preestimation'
	}
	// perform estimation                                                       
	if ("`ival'"                                 != ""    )                   {
		mata:  st_local("f_mi", strofreal(all(missing(st_data(., "`ival'"))) ))
		if ("`f_mi'"                             == "0"   )               {
			mata:  `M' = I(rows((`bval' = vec(st_data(.,  "`ival'" )' )    ) ))
			mata:   st_matrix("`M'",    ustrregexm( `"`options'"',  "miss") ///
				             ? `M'    : select(`M',    rownonmissing(`bval') ))
			mata:   st_matrix("`bval'", ustrregexm( `"`options'"',  "miss") ///
				             ? `bval' : select(`bval', rownonmissing(`bval') ))
			mata:   mata drop  `M'             `bval'
			loc options =ustrregexrf(`"`options'"',  "mod[^)]+[)]", "")   + ///
												"     mod(`M'         )"
			loc options =ustrregexrf(`"`options'"', "bval[^)]+[)]", "")   + ///
												"    bval(`bval'      )"
		}
	}
	if ("`ilowerbound'"                          != ""    )                   {
		conf    sca     `=substr( "`ilowerbound'",   2,  .)'
		loc options =ustrregexrf(`"`options'"',"lower[^)]+[)]", ""   )    + ///
											"   lower(``ilowerbound'')"
	}
	if ("`iupperbound'"                          != ""    )                   {
		conf    sca     `=substr( "`iupperbound'",   2,  .)'
		loc options =ustrregexrf(`"`options'"',"upper[^)]+[)]", ""   )    + ///
											"   upper(``iupperbound'')"
	}
	loc tmpinv = cond("`python'" == ""         & ("`l2'"     != ""        | ///
					  ustrregexm(`"`options'"',"alpha[(]\s*1[.0]*\s*[)]")), ///
					  "tmpinvl2", "tmpinv"                                )
	qui which `tmpinv'
			  `tmpinv' `anything'  `if' `in',  `options'
	cap conf mat e(X)
	// run postestimation command/program (= multiple commands)                 
	if trim(`"`postestimation'"')                != ""    {
		if ( "`loop'"     != ""  &  "`e(full)'"  != "True")                   {
			forval i =  1/`e(model_n)'  {
			   qui tmpinv,   red(`i')
			  `postestimation'
			}
		}
		else  `postestimation'
	}
	// generate, update, or replace a varlist from e(X)                         
	if ("`get'"      != ""                                )                   {
		loc  n :    word count     `get'
		if (`n'  >  1            & `n'  != `: colsof e(X)')                   {
			di as err  "get() varlist must match the number of columns in e(X)"
			error 198
		}
		if (`n'  == 1                                     )					///
		mata: st_local("get",                                               ///
			           substr(invtokens(((tmp=cols(st_matrix("e(X)"))) - 1) ///
			           * "`get'0" :+ strofreal(1..tmp)), -tmp, .)    )
		mata:    `solution' = st_matrix("e(X)")
		qui keep  if e(sample)
		getmata   (`get')=`solution', `double' `update' `replace' `force'
		mata:     mata drop                  `solution'
		if (    "`format'" != "") format `format' `get'
		qui save `tmpf', replace
	}
	// restore and make eventual changes in data with the help of merge         
	if ("`get'"      != ""       |  "`_byvars'"  != ""    )					///
	restore
	if ("`get'"      != ""                                )					///
	qui merge 1:1   `id' using   `tmpf',       `update' `replace'  nogen
end
