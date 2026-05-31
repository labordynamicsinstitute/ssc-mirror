/*==============================================================================
Program define civreg - Coplanar Instrumental Variables Regression

Require package:	
   ivreg2, ranktest, (options: rcall, github for reproduce R results)
		
Versions:
* 05/27/26 - 1.0.0 first-time contribute
* 05/28/26 - 1.0.1 use cluster bootstrap sampling in panel data case
                   add in e():  info. of cov(x,u);
                                  matrix of corr(x, civ)
                                  and matrix of parameter(s) d0

==============================================================================*/

cap pro drop civreg
pro def civreg, eclass byable(recall)

	version 11

	
// Needed for call to ivreg2
	local ver = _caller()
	local ver : di %6.1f `ver'	
	
	local ivreg2_cmd "ivreg2"
	
	if replay() {
/*		
		if `"`e(cmd)'"' != "civreg" {
			error 301
		}
		else syntax [, Level(integer $S_level) FIRST FFIRST /*
			*/	NOFOoter NOOUTput EForm(string) PLUS ]
*/			
		syntax [, Level(integer $S_level) FIRST FFIRST RF /*
			*/	NOHEader NOFOoter NOOUTput EForm(string) PLUS]
			
		if `"`e(cmd)'"' != "civreg" {
			error 301
		}
		
		ereturn local cmd "`ivreg2_cmd'"
		
		if "`nooutput'" == "" {
			
			civreg_header
			
			version `ver': `ivreg2_cmd', level(`level') 				/*
				*/	`noheader' `nofooter' `plus' 							/*
				*/	`first' `ffirst' `rf'								/*
				*/	`=cond("`eform'"!="","eform("+"`eform'"+")","")'	
				
		}
		
		ereturn local cmd "civreg"
	}
// end replay
	else {
		
		syntax anything(name = 0) [if] [in] , [ /*
			*/ 	fe twfe							/*
			*/	hete(integer 0)					/*
			*/	reps(integer 50) 				/*
			*/	d(real 0.01)					/*
			*/	delt(real 0.01)					/*
			*/	dmax(real 70)					/*
			*/	rcode 							/*
			*/	maxiter(integer 50)				/*
			*/	TOLerance(real 1e-8)			/*
			*/	NOLOG							/*
			*/	NOCONStant FIRST FFIRST RF		/*
			*/	savefirst SAVEFPrefix(name)		/*
			*/	saverf SAVERFPrefix(name)		/*
			*/	NOFOoter NOOUTput				/*
			*/	EForm(string) PLUS				/*
			*/	Level(integer $S_level)			/*
			*/	liml gmm2s gmmw	gmm				/*	// to be partialed out
			*/	*								/*
			*/	]

			
		local cmdline "civreg `*'"
		
* If first requested, also needs to request savefirst or savefprefix and set drop flag
		if "`first'" != "" & "`savefirst'`savefprefix'" == "" {
			local savefirst "savefirst"
			local dropfirst "dropfirst"
		}
		if "`savefirst'" != "" & "`savefprefix'" == "" {
			local savefprefix "_civreg_"
		}

* If rf requested, also needs to request saverf or saverfprefix and set drop flag
		if "`rf'" != "" & "`saverf'`saverfprefix'" == "" {
			local saverf "saverf"
			local droprf "droprf"
		}
		if "`saverf'" != "" & "`saverfprefix'" == "" {
			local saverfprefix "_civreg_"
		}
		
		parse_iv `*'
		
		local endo `r(endo)'
		local inexog `r(inexog)'
		local lhs `r(depvar)'
		local exexog `r(exexog)'

		check_no_fv_ts `lhs' `endo' `inexog' `exexog'
		
		if "`endo'" == "" {
			di as err _n "No endogenous regressors specified" 
			error 198
		}	

		local ivreg2_cmd "ivreg2"
		tempname regest
		capture _estimates hold `regest', restore
		capture `ivreg2_cmd', version
		if _rc != 0 {
			di as err /*
			*/	"Error - must have ivreg2 version 2.1.15 or greater installed"
			exit 601
		}
		local vernum "`e(version)'"
		loc lversion `vernum'
		capture _estimates unhold `regest'
		
		if "`rcode'" != "" local r_code = 1
		else local r_code = 0
		
		marksample touse
		markout `touse' `lhs' `endo' `inexog' `exexog' `cluster' , strok
//		tab `touse'
		
* drop duplicate variables
		_rmcoll `endo' if `touse' , nocons force
		local endo "`r(varlist)'"

		_rmcoll `inexog' if `touse' , nocons force
		local inexog "`r(varlist)'"	
		
		_rmcoll `exexog' if `touse' , nocons force
		local exexog "`r(varlist)'"			

* option noconstant		
		if "`noconstant'" == "" local nocons = 0
		else local nocons = 1
		
* mark data
		tempvar mark_id
		qui gen long `mark_id' = _n 
//		qui sort `mark_id' `touse'
		
preserve		

* fe & twfe options:		

		if "`twfe'" == "" {
			
			if "`fe'"=="" local fe_opt = 0
			else local fe_opt = 1
		}
			
		else {
			
			if "`fe'" != "" di in red "option `fe' ignored when `twfe' is specified."
			local fe_opt = 2
			
			if "`nolog'" != "" local lqui "qui "
		}
		
		
* transform data		
		if `fe_opt' > 0 {
			
* Recast the variables as double precision before transforming the data.
			qui recast double `lhs' `endo' `inexog' `exexog'
			
			qui cap xtset
			if "`r(panelvar)'" == "" {
				
di as error /*
	*/	"panel variable not set; use {cmd:xtset} {it:panelvar timevar}"
				exit 459
			}
			else if "`r(timevar)'" == "" {
				
di as error /*
	*/	"time variable not set; use {cmd:xtset} {it:panelvar timevar}"
				exit 459		
			}
		
			local ivar "`r(panelvar)'"
			local tvar "`r(timevar)'"
			
		//	Check whether y_it is time & group-variance	
			qui xtsum `lhs' if `touse'
			local sdy_i = r(sd_b)
			local sdy_t = r(sd_w)

			qui levelsof `ivar' if `touse' , local(ivarnames)
			local N : word count `ivarnames'
			
		//	One-Way FE 
			if `fe_opt'==1 {
				
				if `sdy_t' == 0 {
					
di as error /*
	*/ "Dependent variable must be time-variant when {cmd:fe} specified!"
					exit 198
					
				}
				else {
					qui foreach var of varlist `lhs' `endo' `inexog' `exexog' {
						
						tempvar `var'_i
						egen double ``var'_i' = mean(`var') if `touse' , by(`ivar')
						sum `var' if `touse' , mean
						replace `var' = `var' - ``var'_i' + r(mean) if `touse'
					}
//					sum `lhs' `endo' `inexog' `exexog'
				}
				
			}
			
		//	Two-Way FE: Halperin APM
			else {

				qui levelsof `tvar' if `touse' , local(tvarnames)
				local T : word count `tvarnames'
			
				if (`sdy_t'==0 | `sdy_i'==0 ) {
					
di as error /*
	*/	"Dependent variable must be variant over {it:panelvar} and {it:timevar} when {cmd:twfe} specified!"
					exit 198
					
				}
				else {
					
					`lqui' di _n as text "Halperin APM for regression coefficients:" _n
					
					qui foreach var of varlist `lhs' `endo' `inexog' `exexog' {
						
						tempvar `var'0
						gen double ``var'0' = `var' if `touse'
					}
					
					local iter = 0
					
					while `iter' <= `maxiter' {
						
						local maxdif = 0
						
						qui foreach var of varlist `lhs' `endo' `inexog' `exexog' {
// time-demean
							egen double m_i  = mean(``var'0') if `touse' , by(`ivar')
							gen double `var'1 = ``var'0' - m_i if `touse'
							
// group-demean
							egen double m_t  = mean(`var'1) if `touse' , by(`tvar')
							gen double `var'2 = `var'1 - m_t if `touse'
							
							gen double dif = abs(`var'2 - ``var'0') if `touse'
							sum dif , mean
							local maxdif = max(`maxdif', r(max))
							
							replace ``var'0' = `var'2 if `touse'
							cap drop m_i m_t dif `var'1 `var'2
							
						}
						
						if `iter'>=1 {
							
							`lqui' di as text "Iteration `iter':  Maximum absolute difference = `maxdif'"
							
							if `maxdif' < `tolerance' {
								`lqui' di as text "Converged at iteration `iter'"
								local _rc = 0
								continue , break

							}
							else if `iter' == `maxiter' {
								`lqui' di in red "Convergence not archieved"
								local _rc = 1
							}							
						}

						local iter = `iter' + 1
					}
		// end while
					
		// add overall mean
					qui foreach var of varlist `lhs' `endo' `inexog' {
						
						sum `var' if `touse' , mean
						replace `var' = ``var'0' + r(mean) if `touse'
					}
				}
			}
		}		
		
		// _rmcoll
		_rmcoll `endo' `inexog' `exexog' if `touse' , `noconstant' force 
		local varlist_rmcoll "`r(varlist)'"
		local endo_rmc 
		local inexog_rmc
		local exexog_rmc

		qui foreach var of varlist `varlist_rmcoll' {
			foreach xvar of local endo {
				if "`xvar'" == "`var'" local endo_rmc `endo_rmc' `var' 
			}
			
			foreach hvar of local inexog {
				if "`hvar'" == "`var'" local inexog_rmc `inexog_rmc' `var'
			}
			
			foreach zvar of local exexog {
				if "`zvar'" == "`var'" local exexog_rmc `exexog_rmc' `var'
			}			
		}		
		
		qui cap xtset
		if "`r(panelvar)'" != "" {
			local panelis 1
			local ivar "`r(panelvar)'"
		}
		else {
			local panelis 0
			local ivar "`mark_id'"
		}
		
		mata: create_civlist("endo_rmc", "lhs", "ivar", "inexog_rmc", /*
						*/	"touse", /*
						*/	"d", "delt", "dmax", "reps", "r_code", "hete", /*
						*/ "nocons", "panelis", /*
						*/	"civ" )
				
		mat rown `sign_k' = `endo_rmc'
		mat coln `sign_k' = "select_sign" 	/*
			*/	"cov_signchg" 				/*
			*/	"cov_abs_nd" 				/*
			*/	"cor_signchg" 				/*
			*/	"cor_abs_nd"					
		
		mat rown `d0' = "d0"
		mat coln `d0' = `endo_rmc'
		
		if `fe_opt' == 0 {
			
			qui cap version `ver': `ivreg2_cmd' /*
							*/	`lhs' (`endo_rmc' = `civ' `exexog_rmc' ) 	/*
							*/	`inexog_rmc' if `touse' , `options'			/*
							*/	`first' `ffirst' `rf' 						/*
							*/	savefprefix(`savefprefix') 					/*
							*/	saverfprefix(`saverfprefix')				/*
							*/	`noheader' `nofooter' `nooutput'			/*
							*/	`eform'	`plus' level(`level') 

		}
		else if `fe_opt' == 1 {
			
			qui cap version `ver': `ivreg2_cmd' /*
							*/	`lhs' (`endo_rmc' = `civ' `exexog_rmc' ) 	/*
							*/	`inexog_rmc' if `touse' , `options'			/*
							*/	`first' `ffirst' `rf' 						/*
							*/	savefprefix(`savefprefix') 					/*
							*/	saverfprefix(`saverfprefix')				/*
							*/	`noheader' `nofooter' `nooutput'			/*
							*/	`eform'	`plus' level(`level')				/*
							*/	dofminus(`=`N'-1 + `nocons'')
		}
		else {

			qui cap version `ver': `ivreg2_cmd' /*
							*/	`lhs' (`endo_rmc' = `civ' `exexog_rmc' ) 	/*
							*/	`inexog_rmc' if `touse' , `options'			/*
							*/	`first' `ffirst' `rf' 						/*
							*/	savefprefix(`savefprefix') 					/*
							*/	saverfprefix(`saverfprefix')				/*
							*/	`noheader' `nofooter' `nooutput'			/*
							*/	`eform'	`plus' level(`level')				/*
							*/	dofminus(`=`N' + `T' - 2 + `nocons'') 
		}

//		correlation of `civ' and `endo'
		tempname corr_civ_endo
		qui corr `endo' `civ' if `touse'
		mat `corr_civ_endo' = r(C)
	
		tempfile _data
//		qui keep if `touse'
		if "`savefprefix'`saverfprefix'" != "" {
			qui keep `mark_id' `civ' `touse' _est_*
		}
		else {
			qui keep `mark_id' `civ' `touse'
		}
		qui sort `mark_id'
		qui save `_data', replace

restore

		qui merge m:1 `mark_id' using `_data', nogen		
		
//		Label CIV
		qui foreach var of local civ {
			label var `var' "`var' generated by most recent civreg command"
		}
		
//		Store results
		tempname b V S W firstmat touse2
		
         mat `b'       =e(b)
         mat `V'       =e(V)
         mat `S'       =e(S)
         mat `W'       =e(W)
         mat `firstmat'=e(first)
		 
// Matrix column names to be changed
                        local l_cnames  : colnames `b'
                        local l_cnamesS : colnames `S'
                        local l_cnamesW : colnames `W'
                        local l_cnamesf : colnames `firstmat'
// Full list of names to change
                        local l_vnames   "`lhs'   `inexog'   `endo'   `exexog'"
                        local l_vnames_t "`lhs_t' `inexog_t' `endo_t' `exexog_t'"
		 
// Macros to be fixed
         local l_insts     "`e(insts)'"
         local l_inexog    "`e(inexog)'"
         local l_instd     "`e(instd)'"
         local l_exexog    "`e(exexog)'"
         local l_depvar    "`e(depvar)'"
         local l_clist     "`e(clist)'"
         local l_elist     "`e(elist)'"
         local l_redlist   "`e(redlist)'"
         local l_partial  "`e(partial)'"

         local l_collin    "`e(collin)'"
         local l_dups      "`e(dups)'"
         local l_insts1    "`e(insts1)'"
         local l_inexog1   "`e(inexog1)'"
         local l_instd1    "`e(instd1)'"
         local l_exexog1   "`e(exexog1)'"
         local l_partial1  "`e(partial1)'"
						
					
		ereturn post `b' `V', dep(`l_depvar') esample(`touse') noclear
             
		ereturn matrix S `S'
		
        if ~matmissing(`W') {
			ereturn matrix W `W'
        }
        
		if ~matmissing(`firstmat') {
			ereturn matrix first `firstmat'
        }
		
		ereturn matrix cor_x_iv `corr_civ_endo'
		ereturn matrix chk_sign `sign_k'
		ereturn matrix d0 `d0'
						
        ereturn local insts    `l_insts'
        ereturn local inexog   `l_inexog'
        ereturn local instd    `l_instd'
        ereturn local exexog   `l_exexog'
        ereturn local partial  `l_partial'
        ereturn local collin   `l_collin'
        ereturn local dups     `l_dups'
        ereturn local insts1   `l_insts1'
        ereturn local inexog1  `l_inexog1'
        ereturn local instd1   `l_instd1'
        ereturn local exexog1  `l_exexog1'
        ereturn local partial1 `l_partial1'
        ereturn local depvar   `l_depvar'
        ereturn local clist    `l_clist'
        ereturn local elist    `l_elist'
        ereturn local redlist  `l_redlist'

//		if "`e(vcetype)'"=="Robust" ereturn local vce "cluster"
						
		ereturn local cmd "civreg"
						
 		ereturn local cmdline	"`cmdline'"
		if `r_code'==1 ereturn local rcode "yes"
		else local rcode "no"
        ereturn scalar sigma_e=e(rmse)
		ereturn scalar hete = `hete'
		ereturn scalar fe_opt = `fe_opt'
		if e(fe_opt)==2 ereturn scalar rc = `_rc'
		
		ereturn scalar reps = `reps'
		ereturn scalar d = `d'
		ereturn scalar delt = `delt'
		ereturn scalar dmax = `dmax'
	
	
// ----------------------------------------------------------------
// 		DISPLAY BLOCK (first-time estimation)
// ----------------------------------------------------------------

// 		Collinearity and duplicates warning messages, if necessary
		if "`e(dups)'" != "" {
			di as res "Warning - duplicate variables detected"
			di as res "Duplicates:" _c
			Disp `e(dups)', _col(16)
		}
		if "`e(collin)'" != "" {
			di as res "Warning - collinearities detected"
			di as res "Vars dropped:" _c
			Disp `e(collin)', _col(16)
		}

//		Temporarily set cmd to ivreg2 so ivreg2 display routine works
		ereturn local cmd "`ivreg2_cmd'"
		
		
		if "`nooutput'" == "" {
				
			civreg_header

			version `ver': `ivreg2_cmd', level(`level') 				/*
				*/	`noheader' `nofooter' `plus' 							/*
				*/	`first' `ffirst' `rf'								/*
				*/	`=cond("`eform'"!="","eform("+"`eform'"+")","")'		
			
		}
		
		ereturn local cmd "civreg"
	
	}
	
//	end replay block
	
end



************************************************************************
************************************************************************
************************************************************************

/*======================================================================
 Check that no variable in the supplied varlist 
	is a factor variable (i., b., ibn., #.) 
	or a time-series operator (L., F., D., S., and their lags/ranges).
======================================================================*/

cap pro drop check_no_fv_ts
pro def check_no_fv_ts

	version 11
	local varlist `0'

	foreach v of local varlist {

		// --- Factor variables ---
		if regexm("`v'", "^[0-9]*[ibno]+b?\.") | /*
		*/ regexm("`v'", "^[0-9]+\.") {
			di as err "civreg: factor variable {bf:`v'} is not allowed."
			di as err "        Create the dummy variable(s) manually before calling civreg."
			exit 198
		}

		// --- Time-series operators ---
		if regexm("`v'", "^[LlFfDdSs][0-9]*\.") | /*
		*/ regexm("`v'", "^[LlFfDdSs][0-9]*\(") {
			di as err "civreg: time-series operator {bf:`v'} is not allowed."
			di as err "        Generate the lag/difference variable manually before calling civreg."
			exit 198
		}
	}
end


/* ======================================================================
	Parse_iv
	Taken from ivreg2h.ado
====================================================================== */

cap pro drop parse_iv 
pro def parse_iv, rclass
	version 9
	
	sreturn clear
		local n 0

		gettoken depvar 0 : 0, parse(" ,[") match(paren)
		IsStop `depvar'
		if `s(stop)' { 
			error 198 
		}
		while `s(stop)'==0 { 
			if "`paren'"=="(" {
				local n = `n' + 1
				if `n'>1 { 
capture noi error 198
di in red `"syntax is "(all instrumented variables = instrument variables)""'
exit 198
				}
				gettoken p depvar : depvar, parse(" =")
				while "`p'"!="=" {
					if "`p'"=="" {
						capture noi error 198 
di as err `"syntax is "(endogenous regressor = instrument variables)""'
di as err `"the equal sign "=" is required"'
						exit 198 
					}
					local endo `endo' `p'
					gettoken p depvar : depvar, parse(" =")
				}
				local temp_ct  : word count `endo'
				if `temp_ct' > 0 {
				//	tsunab endo : `endo'
					fvunab endo : `endo'
				}
* To enable OLS estimator with (=) syntax, allow for empty exexog list
				local temp_ct  : word count `depvar'
				if `temp_ct' > 0 {
				//	tsunab exexog : `depvar'
					fvunab exexog : `depvar'
				}
			}
			else {
				local inexog `inexog' `depvar'
			}
			gettoken depvar 0 : 0, parse(" ,[") match(paren)
			IsStop `depvar'
		}
		local 0 `"`depvar' `0'"'

//		tsunab inexog : `inexog'
		fvunab inexog : `inexog'
		tokenize `inexog'
		local depvar "`1'"
		local 1 " " 
		local inexog `*'

		return local depvar	"`depvar'"
		return local inexog	"`inexog'"
		return local exexog	"`exexog'"
		return local endo	"`endo'"

end


/* ======================================================================
	IsStop
	Taken from ivreg2h.ado
====================================================================== */
cap pro drop IsStop
pro define IsStop, sclass
				/* sic, must do tests one-at-a-time, 
				 * 0, may be very large */
	if `"`0'"' == "[" {		
		sret local stop 1
		exit
	}
	if `"`0'"' == "," {
		sret local stop 1
		exit
	}
	if `"`0'"' == "if" {
		sret local stop 1
		exit
	}
* per official ivreg 5.1.3
	if substr(`"`0'"',1,3) == "if(" {
		sret local stop 1
		exit
	}
	if `"`0'"' == "in" {
		sret local stop 1
		exit
	}
	if `"`0'"' == "" {
		sret local stop 1
		exit
	}
	else	sret local stop 0
end


/* ======================================================================
	Disp
	Taken from ivreg2h.ado
====================================================================== */

cap pro drop Disp
pro define Disp 
	version 8.2
	syntax [anything] [, _col(integer 15) ]
	local len = 80-`_col'+1
	local piece : piece 1 `len' of `"`anything'"'
	local i 1
	while "`piece'" != "" {
		di in gr _col(`_col') "`first'`piece'"
		local i = `i' + 1
		local piece : piece `i' `len' of `"`anything'"'
	}
	if `i'==1 { 
		di 
	}
end


/* ======================================================================
	civreg_header
====================================================================== */

cap pro drop civreg_header
pro def civreg_header 
	
	version 11
	syntax
	
	if `e(hete)'==0 local dt_case "Homoscedastic"
	else if `e(hete)'==1 local dt_case "Heteroscedastic (parametric approach)"
	else local dt_case "Heteroscedastic (non-parametric approach)"
	
	if `e(fe_opt)' == 0 		local eff_name "None"
	else if `e(fe_opt)' == 1	local eff_name "Fixed effects"
	else						local eff_name "Two-way fixed effects"
	di _n	as text "{hline 78}"
	di  	in ye "Coplanar instrumental variables (CIV) regression"
	di 		as text "{hline 78}"
	di  	as text "Dual Tendency:" 	_col(17) as text "`dt_case'"
	di		as text "Effects:"			_col(17) as text "`eff_name'"
	di		as text "Reference:"		_col(17) as text /*
			*/							"Dzhumashev and Tursunalieva (2025)"
	
end



*************************************************************************
*	MATA FUNCTIONS
*************************************************************************

mata:
mata clear

/* ================================================================
	ls_xb: OLS & WLS
================================================================ */

real colvector ls_xb(real colvector y,
                     real matrix    X,
					 real scalar nocons,
                     | real colvector w)
{
    real matrix    Xc, Xs, W, XcW
    real colvector b
	
	if (nocons == 0) {
		Xc = X, J(rows(X), 1, 1)
	}
    else {
		Xc = X
	}

    if (args() < 3 | w == J(0,1,.)) {
        b = qrsolve(Xc, y)
    }
	else {
		// OLS: X* = sqrt(w).*X, y* = sqrt(w).*y
		real colvector sw
		sw = sqrt(w)
		b  = qrsolve(cross(sw :* Xc, sw :* Xc), cross(sw :* Xc, sw :* y))
	}

    return(Xc * b)
}


/* ================================================================
	tsls_b
================================================================ */

real colvector tsls_b(
    real colvector y,
    real matrix    x,
    real matrix    z,
    real matrix    c)
{
    real matrix   X, Z, Pz_X
    real scalar   n

    n = rows(y)

    // Adding constant
    X = x, c, J(n, 1, 1)
    Z = z, c, J(n, 1, 1)

    // 2SLS: b = (X'Pz X)^{-1} X'Pz y
    // Pz*X = Z(Z'Z)^{-1}Z'X
    Pz_X = Z * (cholinv(cross(Z, Z)) * cross(Z, X))

    return(qrsolve(cross(Pz_X, X), cross(Pz_X, y)))
}

/* ================================================================
	find_max_pos
================================================================ */

real scalar find_max_pos(real vector x) {
    real scalar max_val, max_idx, i, n
    
    n       = length(x)
    max_val = x[1]
    max_idx = 1
    
    for (i = 2; i <= n; i++) {
        if (x[i] > max_val) {
            max_val = x[i]
            max_idx = i
        }
    }
    
    return(max_idx)
}

/* ============================================================
	find_min_pos
============================================================ */

real scalar find_min_pos(real vector x) {
    real scalar min_val, min_idx, i, n
    
    n       = length(x)
    min_val = x[1]
    min_idx = 1
    
    for (i = 2; i <= n; i++) {
        if (x[i] < min_val) {
            min_val = x[i]
            min_idx = i
        }
    }
    
    return(min_idx)
}

/* ============================================================
	check_initial_abs_increase()
============================================================ */
real scalar check_initial_abs_increase(real colvector x)
{
    real colvector x_clean, abs_x, head, diff_abs
    real scalar n_head

    x_clean = select(x, !missing(x))

    if (rows(x_clean) < 2) return(0)

    n_head = min((20, rows(x_clean)))
    head   = x_clean[1::n_head]

    abs_x = abs(head)

    diff_abs = abs_x[2::rows(abs_x)] - abs_x[1::(rows(abs_x)-1)]

    return(all(diff_abs :>= 0))
}

/* ============================================================
	check_sign_change()
============================================================ */
real scalar check_sign_change(real colvector x)
{
    real colvector x_clean, signs, diff_signs
    real scalar has_change

    x_clean = select(x, !missing(x))

    if (rows(x_clean) < 2) return(0)

    signs = sign(x_clean)

    diff_signs = signs[2::rows(signs)] - signs[1::(rows(signs)-1)]

    has_change = any(diff_signs :!= 0)

    return(has_change)
}

/* ============================================================
	find_first_sign_change()
============================================================ */
real scalar find_first_sign_change(real colvector x)
{
    real colvector x_clean, signs, diff_signs
    real scalar i

    x_clean = select(x, !missing(x))

    if (rows(x_clean) < 2) return(.)

    signs = sign(x_clean)

    diff_signs = signs[2::rows(signs)] - signs[1::(rows(signs)-1)]

    for (i = 1; i <= rows(diff_signs); i++) {
        if (diff_signs[i] != 0) {
			return(i + 1)
		}
		else {
			return(.)			
		}
    }

}


/* ============================================================
	ad2stat
============================================================ */

real scalar ad2_stat(
        real colvector x,
        real colvector y
)
{
        real scalar n, m, N, nz, i, j, k
        real scalar max_val, avg_rank, h, fx, fy
        real scalar xi, yi
        real colvector z_all, z, idx, rank_vec, xs, ys, contrib

        n = rows(x)
        m = rows(y)
        N = n + m

        z_all   = x \ y
        max_val = max(z_all)
        z       = select(z_all, z_all :!= max_val)
        nz      = rows(z)

        idx = order(z, 1)

        rank_vec = J(nz, 1, .)
        i = 1
        while (i <= nz) {
                j = i
                while (j < nz) {
                        if (z[idx[j]] == z[idx[j+1]]) j++
                        else break
                }
                avg_rank = (i + j) / 2
                for (k = i; k <= j; k++) {
                        rank_vec[k] = avg_rank
                }
                i = j + 1
        }

        xs = sort(x, 1)
        ys = sort(y, 1)

        xi      = 0
        yi      = 0
        contrib = J(nz, 1, .)

        for (i = 1; i <= nz; i++) {
                while (xi < n) {
                        if (xs[xi+1] <= z[idx[i]]) xi++
                        else break
                }
                while (yi < m) {
                        if (ys[yi+1] <= z[idx[i]]) yi++
                        else break
                }

                h  = rank_vec[i] / N
                fx = xi / n
                fy = yi / m

                contrib[idx[i]] = ((fx - fy)^2) / (h * (1 - h))
        }

        return((n * m / N^2) * sum(contrib))
}


/* ================================================================
				SAMPLING FUNCTION
================================================================ */

//	call sample() in R
real colvector r_sample(real scalar N, real scalar S, real scalar seed)
{
    string scalar cmd, idx_str
    
    cmd = "quietly rcall vanilla : set.seed(" + strofreal(seed) + "); " + ///
          "idx_r <- sample(1:" + strofreal(N) + ///
          ", " + strofreal(S) + ", replace=TRUE)"
    stata(cmd)
    
    idx_str = st_global("r(idx_r)")
    
    return(strtoreal(tokens(idx_str))')
}

//	Boostrap index
real colvector bootstrap_index(
        real scalar N,
        real scalar S,
        real scalar seed,
        real scalar r_code
)
{
        if (r_code == 0) {
                rseed(seed)
				return(ceil(N :* runiform(S, 1)))
        }
        else {
                return(r_sample(N, S, seed))
        }
}

//	ID-cluster Boostrap index
real colvector cluster_bootstrap_index(real colvector id,
                                       real scalar seed,
                                       real scalar r_code)
{
    real colvector uid
    real scalar    N_cl, i
    real colvector sampled_cl_idx, final_idx

    uid  = uniqrows(id)
    N_cl = rows(uid)

    sampled_cl_idx = bootstrap_index(N_cl, N_cl, seed, r_code)

    final_idx = J(0, 1, .)
	
    for (i = 1; i <= N_cl; i++) {
		
        final_idx = final_idx \ selectindex(id :== uid[sampled_cl_idx[i]])
    }
    return(final_idx)
}



/* ================================================================
			MAKE_V012:	RNORM(0, sd(x)) FUNCTION rep 1:1 in R
================================================================ */

real matrix make_v012(real scalar sd_x, real scalar N, real scalar seed)
{
    string scalar cmd
    real colvector v0, v1, v2

    cmd = "quietly rcall vanilla: " + ///
          "set.seed("+strofreal(seed) + "); " + ///
          "sample(1:"+strofreal(N)+", round(" + ///
						strofreal(N*0.999)+"), replace=TRUE); " + ///
          "v0 <- rnorm(" + strofreal(N) + ", 0," + strofreal(sd_x) + "); " + ///
          "v1 <- rnorm(" + strofreal(N) + ", 0," + strofreal(sd_x) + "); " + ///
          "v2 <- rnorm(" + strofreal(N) + ", 0," + strofreal(sd_x) + ") "
    
	stata(cmd)

    v0 = strtoreal(tokens(st_global("r(v0)")))'
    v1 = strtoreal(tokens(st_global("r(v1)")))'
    v2 = strtoreal(tokens(st_global("r(v2)")))'

    return((v0, v1, v2))
}


/* ================================================================
				HETE. FUNCTION
================================================================ */

// hete = 0
real scalar criterion_homo(
        real colvector x_b,
        real colvector civ_b,
		real scalar nocons
)
{
        real colvector e_ols
        real colvector e2_ols
        real matrix m1i

        e_ols = x_b :- ls_xb(x_b, civ_b, nocons)

        e2_ols = e_ols :^ 2

        m1i = correlation((e2_ols, civ_b))

        return(abs(m1i[1,2]))
}

// hete = 1
real scalar criterion_gls_f(
        real colvector x_b,
        real colvector civ_b,
        real scalar nocons
)
{
        real colvector e_ols, e2_ols
        real colvector le2, le2_hat
        real colvector wgt
        real colvector e_gls, e2_gls

        real scalar ess_o, rss_o
        real scalar ess_g, rss_g
        real scalar chi2_o, chi2_g
        real scalar dv, N
		N = rows(x_b)

        e_ols = x_b :- ls_xb(x_b, civ_b, nocons)
        e2_ols = e_ols :^ 2

        le2 = log(e2_ols)

        le2_hat = ls_xb(le2, civ_b, 0)	// should be included constant

        wgt = 1 :/ exp(le2_hat)

        e_gls = x_b :- ls_xb(x_b, civ_b, nocons, wgt)

        e2_gls = e_gls :^ 2

        ess_o = sum((ls_xb(e2_ols, civ_b, 0) :- mean(e2_ols)) :^ 2)
        rss_o = sum(e2_ols)

        chi2_o = (ess_o / 2) / (rss_o / N)^2

        ess_g = sum((ls_xb(e2_gls, civ_b, 0) :- mean(e2_gls)) :^ 2)
        rss_g = sum(e2_gls)

        chi2_g = (ess_g / 2) / (rss_g / N)^2

        dv = chi2(1, chi2_g) - chi2(1, chi2_o)

        return(abs(dv))
}

// hete = 2
real scalar criterion_gls_ad(
        real colvector x_b,
        real colvector civ_b,
		real scalar nocons
)
{
        real colvector e_ols, e2_ols
        real colvector le2, le2_hat
        real colvector wgt
        real colvector e_gls, e2_gls

        real colvector xx0, yy0

        e_ols = x_b :- ls_xb(x_b, civ_b, nocons)

        e2_ols = e_ols :^ 2

        le2 = log(e2_ols)

        le2_hat = ls_xb(le2, civ_b, 0)

        wgt = 1 :/ exp(le2_hat)

        e_gls = x_b :- ls_xb(x_b, civ_b, nocons, wgt)

        e2_gls = e_gls :^ 2

        xx0 = (ls_xb(e2_ols, civ_b, 0)) :^ 2
        yy0 = (ls_xb(e2_gls, civ_b, 0)) :^ 2
		
		ad0 = ad2_stat(xx0, yy0)
		
        return(1 - ad0)
}


/* ================================================================
				find_d0_boot FUNCTION
================================================================ */
real scalar find_d0_boot(
        real colvector x,
        real colvector r,
		real colvector id,
        real scalar k,
        real scalar d_or,
        real scalar dd,
        real scalar delt,
        real scalar reps,
        real scalar hete,
        real scalar r_code,
		real scalar nocons,
		real scalar panelis
)
{
        real scalar N, S
        real scalar l, i
        real scalar d
        real scalar d0
        real scalar m_rows

        real colvector idx
        real colvector x_b
        real colvector r_b
        real colvector civ_b

        real colvector m1
        real colvector d0i

        N = rows(x)
        S = round(N * 0.999)

        m_rows = floor( (dd-d_or)/delt ) + 1

        d0i = J(reps, 1, .)

        
// =================================================
// 		BOOTSTRAP
// =================================================

        for (l=1; l<=reps; l++) {
				
				if (panelis==1) {
					idx = cluster_bootstrap_index(
									id,
									3*l,
									r_code
									)
				}
				else {
					idx = bootstrap_index(
									N,
									S,
									3*l,
									r_code
									)
				}

                x_b = x[idx]
                r_b = r[idx]

                m1 = J(m_rows, 1, .)

                d = d_or

                for (i=1; i<=m_rows; i++) {

                        civ_b = x_b :- k * d * r_b

                        if (hete == 0) {

                                m1[i] = criterion_homo(
                                                x_b,
                                                civ_b,
												nocons
                                                )
                        }
                        else if (hete == 1) {

                                m1[i] = criterion_gls_f(
                                                x_b,
                                                civ_b,
												nocons
                                                )
                        }
                        else if (hete == 2) {

                                m1[i] = criterion_gls_ad(
                                                x_b,
                                                civ_b,
												nocons
                                                )
                        }

                        d = d + delt
                }
                d0 = find_min_pos(m1) * delt
                d0i[l] = d0
        }
		
        return(mean(d0i))
}



/* ================================================================
				create_civ FUNCTION
================================================================ */

void create_civ(real colvector y,
                     real colvector x,
					 real colvector id,
                     real scalar d_or,
					 real scalar delt,
					 real scalar dmax,
					 real scalar reps,
					 real scalar r_code,
					 real scalar hete,
					 real scalar nocons,
					 real scalar panelis,
					 
					 real colvector civ,
					 real rowvector sign,
					 real matrix d0m)
{
	
	N = rows(y)
	S = round(N * 0.999)
	
	e = y - ls_xb(y, x, nocons)
	r = e * sqrt(variance(x)) / sqrt(variance(e))
	d = d_or

	theta1 = 0
	dd = d
	while (theta1 < dmax) {
		civ = x :- dd :* r
		theta = acos(quadcross(x,civ) / sqrt(quadcross(x,x)*quadcross(civ,civ)))
		theta1 = theta * 180 / pi()
		dd = dd + delt
	}
	
	signc = J(2, 5, .)
	signc[1, 1] = 1
	signc[2, 1] = -1
	
	for (j = 1; j<=2; j++) {

		if (j < 2) {
			k = 1
		}
		else {
			k = -1
		}
		
		i = 1
		m_rows = floor( (dd-d_or) / delt ) + 1
		m1 = J(m_rows, 1, .)
		m2 = J(m_rows, 1, .)
		d = d_or
		
		while (d < dd) {
			civ = x :- k * d * r
			e = x - ls_xb(x, civ, nocons)
			e2 = e:^2
			m1i = variance((e2, civ))
			m2i = correlation((e2, civ))

			m1[i] = m1i[1, 2]
			m2[i] = m2i[1, 2]
			
			d = d + delt
			i = i + 1
		}
		
		m1 = select(m1 , m1  :!= .)
		m2 = select(m2 , m2  :!= .)
		
		m = m1
		signc[j, 3] = check_initial_abs_increase(m)
		signc[j, 5] = check_initial_abs_increase(m2)
		
		if (signc[j,3] != 1) {
			index = find_first_sign_change(m1)
			n_m = rows(m)
			m = m1[index..n_m]
		}
		
		signc[j, 2] = check_sign_change(m)
		signc[j, 3] = check_initial_abs_increase(m)
		signc[j, 4] = check_sign_change(m2)
		
	}
	
	ch = J(2, 1, .)
	for (j = 1; j<=2 ; j++) {
/*		
		if (j==1) {
			sign_str = "cor(x,u)<0"
		}
		else {
			sign_str = "cor(x,u)>0"
		}
		if (signc[j, 3] * signc[j, 4] == 0) {
			printf("The assumption that " + sign_str +" is FALSE\n")
		}
		else {
			printf("The assumption that " + sign_str +" is TRUE\n")			
		}
*/		
		ch[j] = signc[j, 2] + signc[j, 3] + signc[j, 4] + signc[j, 5]
	}
	
	pos_max = find_max_pos(ch)
	k = signc[pos_max, 1]
//	k
//	signc
	sign = signc[pos_max, ]
	
	if (k != 0) {
		d0m = find_d0_boot(
				x,
				r,
				id,
				k,
				d_or,
				dd,
				delt,
				reps,
				hete,
				r_code,
				nocons,
				panelis
		)
		d0m
		civ = x :- k * d0m * r

	}


}



/*================================================================
				MAKER_civ FUNCTION
================================================================*/

void create_civlist(
        string scalar xname,      
        string scalar yname,
		string scalar idname,
        string scalar hname,      
        string scalar tousename,  
        
        string scalar dname,
        string scalar deltname,
		string scalar dmaxname,
        string scalar repsname,
        string scalar rcodename,
        string scalar hetename,
		string scalar noconsn,
		string scalar panelisn,
        
        string scalar outname     
)
{
        string rowvector x0n, y0n, h0n
        
        real matrix x0, y0, h
        real matrix x0i, civ, hi
        
        real colvector y, x, xi , id , civ_i
		real rowvector sign
        
        real scalar N
        real scalar k_x
        real scalar i
        
        real scalar d
        real scalar delt
		real scalar dmax
        real scalar reps
        real scalar r_code
        real scalar hete
		real scalar nocons
		real scalar panelis
        
        string scalar vname
        string scalar civlist

        
// =====================================================
// 		READ STATA LOCALS
// =====================================================

        x0n = tokens(st_local(xname))
        y0n = tokens(st_local(yname))
        h0n = tokens(st_local(hname))
		idn = tokens(st_local(idname))
		touse = st_local(tousename)
      
// =====================================================
// 		READ DATA
// =====================================================

        x0 = st_data(., x0n, touse)
        y0 = st_data(., y0n, touse)
		id = st_data(., idn, touse)

        N = rows(y0)

        if (length(h0n) > 0) {
                h = st_data(., h0n, touse)
        }
        else {
                h = J(N, 1, 0)
        }

        
// =====================================================
// 		READ SCALARS
// =====================================================

        d       = strtoreal(st_local(dname))
        delt    = strtoreal(st_local(deltname))
		dmax    = strtoreal(st_local(dmaxname))
        reps    = strtoreal(st_local(repsname))
        r_code  = strtoreal(st_local(rcodename))
        hete    = strtoreal(st_local(hetename))
		nocons  = strtoreal(st_local(noconsn))
		panelis  = strtoreal(st_local(panelisn))

        k_x = cols(x0)
        
// =====================================================
// 		CREATE CIVLIST
// =====================================================

        civ = J(N, k_x, .)
//		civb = J(N, k_x, .)

		sign_k = J(k_x, 5, .)
		d0 = J(1, k_x, .)

        for (i=1; i<=k_x; i++) {

                xi = x0[,i]

// ---------------------------------------------
// 				FWL reduction
// ---------------------------------------------

                if (k_x > 1) {

                        if (i == 1) {

                                x0i = x0[, i+1..k_x]

                        }
                        else if (i == k_x) {

                                x0i = x0[, 1..i-1]

                        }
                        else {

                                x0i = x0[,1..i-1] , x0[,i+1..k_x]
                        }
						
						hi = x0i, h
                        y = y0 - ls_xb(y0, hi, nocons)
                        x = xi - ls_xb(xi, hi, nocons)
                }
                else {

                        y = y0 - ls_xb(y0, h, nocons)
                        x = xi - ls_xb(xi, h, nocons)
                }
                
// ---------------------------------------------
// 				Create CIV_i
// ---------------------------------------------

                create_civ(
					y,
                    x,
					id,
					d,
					delt,
					dmax,
					reps,
					r_code,
					hete,
					nocons,
					panelis,
					
					civ_i,
					sign,
					d0m
				)
		
				sign_k[i, ] = sign
				d0[i] = d0m
				
				if (k_x==1) {
					civ[,i] = civ_i
					
				} else {

					seed = 3 * reps
					sd_x = sqrt(variance(x))
					
					if (r_code == 1) {
						
						V012 = make_v012(sd_x, N, seed)
						
						civ[,i] = civ_i + V012[., hete+1]
						
					}
					else {
						
						civ[,i] = civ_i + rnormal(N, 1, 0, sd_x)
					}
					
				}
				
//				civ[,i] = civi
        }
		
        
// =====================================================
// 		EXPORT TO STATA
// =====================================================

        civlist = ""

        for (i=1; i<=k_x; i++) {
				
				vname = "civ_" + x0n[i]
					
				// delete old variable if exists
				if (_st_varindex(vname) != .) {
						st_dropvar(vname)
				}
					
				// create variable
				st_addvar("double", vname)
					
				// store values
				st_store(., vname, touse, civ[,i])
					
				// collect varlist
				civlist = civlist + " " + vname
        }

        
// =====================================================
// 		RETURN LOCAL MACRO
// =====================================================

        st_local(outname, strtrim(civlist))
		
// =====================================================
// 		RETURN MATRIX
// =====================================================
		stata("tempname sign_k")
        st_matrix(st_local("sign_k"), sign_k)
		
		stata("tempname d0")
        st_matrix(st_local("d0"), d0)		
		
}


end
