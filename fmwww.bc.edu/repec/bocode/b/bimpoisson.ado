*! 2.1.0 Stephen P. Jenkins and Fernando Rios-Avila, March 2026
* 		New SF approach
* 		Halton as well as uniform draws; different draws derivation method 

********************************************************************************
* Bivariate Mixed-Poisson Regression using Simulated Maximum Likelihood
* Implementation of Munkin & Trivedi (1999). Simulated maximum likelihood 
* 		estimation of multivariate mixed-Poisson regression
* 		models, with application. The Econometrics Journal 2, 29-48.
* 		https://doi.org/10.1111/1368-423X.00019
*
* Compared to MT, we: 	(i) allow Halton draws optionally
*						(ii) use bivariate normal sampling function with free
*								variances (not 1), and allow non-zero rho_sf 
********************************************************************************

program define bimpoisson, eclass byable(onecall)

	// code borrowed from -mvprobit-
	version 15
    if replay() {
		if "`e(cmd)'" != "bimpoisson" {
			noi di as error "results for bimpoisson not found"
            exit 301
        }
        if _by() { 
            error 190 
        } 
        Display `0'
        exit `rc'
	}
    if _by() {
		by `_byvars'`_byrc0': Estimate `0'
		 ereturn local cmdline `"bimpoisson `0'"'
    }
    else    Estimate `0'
	ereturn local cmdline `"bimpoisson `0'"'
end


program define Estimate, eclass byable(recall)
	version 15

	/* two syntaxes, handle one at a time */

	gettoken first : 0, match(paren)
	if "`paren'" == "" {
			/* syntax 1: 2 depvars followed by common predictors */

			gettoken dep1 0:0, parse (" =,[")
			_fv_check_depvar `dep1'
			tsunab dep1 : `dep1'
			rmTS `dep1'
			confirm variable `r(rmTS)'
			gettoken dep2 0:0, parse (" =,[")
			_fv_check_depvar `dep2'
			tsunab dep2 : `dep2'
			rmTS `dep2'
			confirm variable `r(rmTS)'
			gettoken junk left :0, parse ("=")
			
			if "`junk'" == "=" {
					local 0 "`left'"
			}
			
		syntax [varlist(default=none ts fv)]  [if] [in]  [pw aw iw fw] 	///
			[ , Robust Cluster(varname) 	///
			 rho_sf(real 0)					/// 
			 ANTIthetic 					///
			 bias 							///
			 seed(str)  					///
			 alt 							/// 
			 HAlton							///
			 burn(integer 5)				///
			 nsim(integer 10) 				///
			 rng0							///
			 IRR							///
			 EForm							///
			 NOLOg LOg MLOpts(string) 		///
			 FROM(string) VCE(passthru)     ///			 
			 * 		///		 
			]

			local fvops = "`s(fvops)'" == "true" | _caller() >= 11

			if _by() {
					_byoptnotallowed score() `"`score'"'
			}
			
			local ind1 `varlist'
			local ind2 `varlist'
			local dep1n "`dep1'"
			local dep1n : subinstr local dep1 "." "_"
			local dep2n "`dep2'"
			local dep2n : subinstr local dep2 "." "_"
			local e_neq = 2
			local nc1 `constant'
			local nc2 `constant'
			
			if "`eform'" != "" &  "`irr'" != "" {
				display as error "only one of options eform or irr is allowed"
				exit 198	
			}
			
			if abs(`rho_sf') >= 1  {
				display as error "rho_sf must be between -1 and 1"
				exit 198
			}

		if "`alt'" == ""   local title "Bivariate mixed Poisson regression (MSL, with sampling function)"
		else               local title "Bivariate mixed Poisson regression (MSL)"
			
			local option0 `options'
			marksample touse
			markout `touse' `dep1' `dep2' `offset1' `offset2', strok
	}


	else {
		/* syntax 2: 2 depvars, separate equations */

		// get first equation 
		gettoken first 0:0, parse(" ,[") match(paren)
		local left "`0'"
		local junk: subinstr local first ":" ":", count(local number)
		if "`number'" == "1" {
				gettoken dep1n first: first, parse(":")
				gettoken junk first: first, parse(":")
		}
		local first : subinstr local first "=" " "
		gettoken dep1 0: first, parse(" ,[") 
		_fv_check_depvar `dep1'
		tsunab dep1: `dep1'
		rmTS `dep1' 
		confirm variable `r(rmTS)'
		if "`dep1n'" == "" {
				local dep1n "`dep1'"
		}
		syntax [varlist(default=none ts fv)] [, /*
				*/      OFFset(varname numeric) noCONstant]

		local fvops = "`s(fvops)'" == "true" | _caller() >= 11

		local ind1 `varlist'
		local offset1 `offset' 
		local nc1 `constant'

		// get second equation 
		local 0 "`left'"
		gettoken second 0:0, parse(" ,[") match(paren)
		if "`paren'" != "(" {
				dis in red "two equations required"
				exit 110
		}
		local left "`0'"
		local junk : subinstr local second ":" ":", count(local number)
		if "`number'" == "1" {
				gettoken dep2n second: second, parse(":")
				gettoken junk second: second, parse(":")
		}
		local second : subinstr local second "=" " "
		gettoken dep2 0: second, parse(" ,[") 
		_fv_check_depvar `dep2'
		tsunab dep2: `dep2' 
		rmTS `dep2'
		confirm variable `r(rmTS)'
		if "`dep2n'" == "" {
				local dep2n "`dep2'"
		}
		syntax [varlist(default=none ts fv)] [, /*
				*/  OFFset(varname numeric) noCONstant ]

		if !`fvops' {
				local fvops = "`s(fvops)'" == "true"
		}

		local ind2 `varlist'
		local offset2 `offset' 
		local nc2 `constant'
					
		// remain options 
		local 0 "`left'"
		syntax [if] [in]  [pw aw iw fw] 	///
			[ , Robust Cluster(varname) 	///
			 rho_sf(real 0)					///  
			 ANTIthetic 					///
			 HAlton							///		
			 burn(integer 5)				///			 
			 bias 							///
			 seed(str)  					///
			 alt 							/// 
			 nsim(integer 10) 				///
			 rng0							///
			 IRR							///
			 EForm				 			///
			 NOLOg LOg MLOpts(string) 		///
			 FROM(string) VCE(passthru)     ///
			 * 		///		 
			]
			
		if "`eform'" != "" &  "`irr'" != "" {
			display as error "only one of options eform or irr is allowed"
			exit 198	
		}
		
		if "`alt'" == ""   local title "Bivariate mixed Poisson regression (MSL, with sampling function)"
		else               local title "Bivariate mixed Poisson regression (MSL)"	
		
		local option0 `options'
		marksample touse
		markout `touse' `dep1' `dep2' `ind1' `ind2' `offset1'  `offset2'
	}    
	
    local wtype `weight'
    local wtexp `"`exp'"'
    if "`weight'" != ""   local wgt `"[`weight'`exp']"'   

    _get_diopts diopts option0, `option0'
    mlopts stdopts, `option0'
    local coll `s(collinear)'
    local cns `s(constraints)'
    if "`cluster'" != ""   local clopt "cluster(`cluster')"  
	_vce_parse, argopt(CLuster) opt(Robust oim opg) old: ///
            [`weight'`exp'], `vce' `clopt' `robust' 

    local vceopt  `r(vceopt)'
    local cluster `r(cluster)'
    local robust `r(robust)'
    if "`cluster'" ! = ""  local clopt "cluster(`cluster')"  
    if `"`robust'"' != ""  local crtype crittype("log pseudolikelihood")

    // test collinearity 
    qui:_rmcoll `ind1' `wgt' if `touse', `nc1' `coll'
    local ind1 "`r(varlist)'"
    qui:_rmcoll `ind2' `wgt' if `touse', `nc2' `coll'
    local ind2 "`r(varlist)'"
        
    if "`level'" != ""   local level "level(`level')"
    
    if "`offset1'" != "" local offo1 "offset(`offset1')" 
    if "`offset2'" != "" local offo2 "offset(`offset2')" 
 
        * -mllog- passed to command to let -log- overwrite c(iterlog) off
    local mllog `log' `nolog'
    _parse_iterlog, `log' `nolog'
    local log "`s(nolog)'"
    qui {
        if "`log'" == "" {
                local log "noisily"
        }
		else    local log "quietly"

		count if `touse' 
		local nuse = r(N)
		if `nuse' == 0  {
			noi di "no observations"
			exit 2000
		}	
		global touse___ `touse'
	}       
 
	global rho_sf___ `rho_sf'

	if "`nc1'`nc2'" != ""    local skip "skip" 
    if "`ind1'`ind2'" == ""  local skip "skip" 
    if "`robust'" != ""      local skip "skip" 
	
	if "`antithetic'" != ""  global antithetic___ = 1 
	else 				     global antithetic___ = 0
	
	if "`halton'" != ""  global halton___ = 1 
	else 				 global halton___ = 0
		
	if "`bias'" != ""        global bias___ = 1 
	else                     global bias___ = 0
	
	// set seed 
	if "`seed'" != "" {
		set seed `seed'
		global rngstate___ = c(rngstate)	
	}
	else {
		global rngstate___ = c(rngstate)	
		if "`halton'" == "0" {
			display _n "Warning: no seed set. Command will use current rng state"
		}	
	}	
	
	global nsim___ = `nsim'	
	
	// create draws
	
	if "`halton'" != "" {
        
		di " "
		di as text "Generating Halton draws ..."
        
		mata: H_all = halton(`nuse'*`nsim', 2, `=`burn'+1')

		forvalues s = 1/`nsim' {
			tempvar h1_`s' h2_`s'
			quietly gen double `h1_`s'' = .
			quietly gen double `h2_`s'' = .
			
			mata: st_store(., "`h1_`s''", "`touse'", extract_block(H_all, `nsim', `s', 1))
			mata: st_store(., "`h2_`s''", "`touse'", extract_block(H_all, `nsim', `s', 2))			
			// set up globals so that can refer to draws in the evaluator function
			global  dr1_`s'__ "`h1_`s''" 
			global  dr2_`s'__ "`h2_`s''" 			
		}	
	}
	else {
		di " "	
        di as text "Generating pseudorandom uniform draws ..."
        forvalues s = 1/`nsim' {
            tempvar u1_`s' u2_`s'
            quietly gen double `u1_`s'' = runiform() if `touse'
            quietly gen double `u2_`s'' = runiform() if `touse'
			// set up globals so that can refer to draws in the evaluator function			
			global  dr1_`s'__ "`u1_`s''" 
			global  dr2_`s'__ "`u2_`s''" 
        }	
	}
	
************ models ********************************************
	// 2 models: (i) with sampling function (ii) without ('alt')

	if "`alt'" == "" {		
		
		`log' ml model lf bimpoisson_lf 								///
			(`dep1n': `dep1' = `ind1', `nc1' `offo1' )  			///
			(`dep2n': `dep2' = `ind2', `nc2' `offo2' )  			///
			/ln_sig1 /ln_sig2 /arho 								///
			if `touse' `wgt' , 										///
			collinear missing maximize nooutput 					///
			nopreserve  title(`title')  `vceopt'		///
			init(`from') search(off)  `diopts' `irr'				///
			`level' `mlopts'  `stdopts' 							///
			`iterate'  `mllog'				
	}
	else  {		
		
		`log' ml model lf bimpoisson2_lf 							///
			(`dep1n': `dep1' = `ind1', `nc1' `offo1' )  			///
			(`dep2n': `dep2' = `ind2', `nc2' `offo2' )  			///
			/ln_sig1 /ln_sig2 /arho 								///
			if `touse' `wgt', 										///
			collinear missing maximize nooutput 					///
			nopreserve  title(`title')  `vceopt'			///
			init(`from') search(off)  `diopts'	`irr'				///
			`level' `mlopts'  `stdopts' 							///
			`iterate' `mllog'				
	}

		ereturn local cmd "bimpoisson"
        ereturn local predict "bimpoisson_p"
		ereturn scalar sigma1 = exp( e(b)[1,"/ln_sig1"] )
		ereturn scalar sigma2 = exp( e(b)[1,"/ln_sig2"] )
		ereturn scalar rho = tanh( e(b)[1,"/arho"] )
		ereturn scalar nsims = `nsim'
		ereturn scalar k_eform = 2
		ereturn scalar rho_sf = `rho_sf'		
		ereturn scalar burn = `burn'
		
		if "`seed'" != ""  ereturn local seed = `seed'
		else  ereturn local seed = "seed not set"

		if "`antithetic'" != "" ereturn scalar antithetic = 1
		else if "`antithetic'" == "" ereturn scalar antithetic = 0
		if "`halton'" != "" ereturn scalar halton = 1
		else if "`halton'" == "" ereturn scalar halton = 0
		if "`bias'" != ""  ereturn scalar bias = 1
		else if "`bias'" == ""  ereturn scalar bias = 0
		if "`rng0'" != ""  ereturn scalar rng0 = 1
		else if "`rng0'" == ""  ereturn scalar rng0 = 0

		ereturn local rngstate $rngstate___

        Display , `level' `diopts' `irr' `eform'
        exit `e(rc)'
	
		// set rngstate back to initial value, optionally
		if "`rng0'" != "" { set rngstate $rngstate___	}
		
		global nsim___
		global seed___
		global bias___
		global antithetic___
		global halton___
		global rngstate___
		global norm___		
		global touse___		
		forvalues s = 1/`nsim' {
			global  dr1_`s'__ 
			global  dr2_`s'__  			
		}			
	
end

program define Display, eclass

        syntax [, Level(cilevel) IRR EForm *]

        _get_diopts diopts, `options'
		
		ml display,  level(`level') `diopts' `irr' `eform' plus
		_diparm ln_sig1 , exp label("sigma1") prob
		ereturn scalar sigma1_se = r(se) 
		_diparm ln_sig2, exp label("sigma2") prob 
		ereturn scalar sigma2_se = r(se)
		_diparm arho, tanh label("rho") prob
		ereturn scalar rho_se = r(se)
		
		di in smcl  "{hline 13}{c BT}{hline 64}"	
		if "`e(antithetic)'" == "0" & "`e(bias)'" == "0" {
			di "Note: `e(nsims)' draws "
		}
		else if "`e(antithetic)'" == "1" & "`e(bias)'" == "0" {
			di "Note: `e(nsims)' draws " _c
			di "plus `e(nsims)' antithetic draws"
		}
		else if "`e(antithetic)'" == "0" & "`e(bias)'" == "1" {
			di "Note: `e(nsims)' draws, " _c
			di "with first-order bias correction"
		}
		else if "`e(antithetic)'" == "1" & "`e(bias)'" == "1" {
			di "Note: `e(nsims)' draws " _c
			di "plus `e(nsims)' antithetic draws, "	_c		
			di "with first-order bias correction"
		}

end

program define rmTS, rclass

        local tsnm = cond( match("`0'", "*.*"),                 /*
                        */ bsubstr("`0'",                       /*
                        */        (index("`0'",".")+1),.),      /*
                        */ "`0'")

        return local rmTS `tsnm'
end

mata:
real colvector extract_block(real matrix H, real scalar S, 
                              real scalar sim, real scalar col) {
    real scalar nobs, i
    real colvector result
    
    nobs = rows(H) / S
    result = J(nobs, 1, .)
    
    for (i = 1; i <= nobs; i++) {
        result[i] = H[(i-1)*S + sim, col]
    }
    return(result)
}
end