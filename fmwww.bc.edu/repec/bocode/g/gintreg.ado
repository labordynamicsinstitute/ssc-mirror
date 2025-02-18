*! version 3.1  21may2024
program define gintreg, eclass byable(onecall) ///
                        prop(svyb svyj svyr swml bayes)
        if _by() {
                local BY `"by `_byvars'`_byrc0':"'
        }
        `BY' _vce_parserun gintreg, numdepvars(2) alldepsmissing ///
                mark(Het OFFset CLuster) : `0'
        if "`s(exit)'" != "" {
                version 10: ereturn local cmdline `"gintreg `0'"'
                exit
        }

        version 8.1, missing
        if _caller() < 8 {
                di as err "gintreg requires Stata 8 or newer"
				error 498
                exit
        }
        if replay() {
                if `"`e(cmd)'"'!="gintreg" {
                        error 301
                }
                if _by() {
                        error 190
                }
                DiGintreg `0' /* display results */
                error `e(rc)'
                exit
        }
        if _caller() >= 11 {
                local vv : di "version " string(_caller()) ":"
        }
        `vv' `BY' Estimate `0'
        version 10: ereturn local cmdline `"gintreg `0'"'
end

program Estimate, eclass byable(recall)
        if _caller() >= 11 {
                local vv : di "version " string(max(11,_caller())) ", missing:"
        }
        version 8.1, missing

/* Parse syntax and get distribution- and parameter-specific macros. */
        
        syntax  varlist(min=2 numeric fv ts)    /*
        */      [aw fw pw iw] [if] [in]         /*
        */      [,                              /*
        */      DISTribution(string)            /* gintreg
        */      Level(cilevel)                  /*
        */      NOLOg                           /*
        */      OFFset(varname numeric)         /*
        */      noCONstant                      /*
        */      Robust                  /*
        */      CLuster(passthru)       /*
        */      VCE(passthru)           /*
        */      noDISPLAY               /*
        */      CONSTraints(string)     /*
        */      from(string)            /*
        */      initiald(string)        /* gintreg
        */      lnsigma(string)         /* gintreg
        */      p(string)               /* gintreg 
        */      q(string)               /* gintreg 
        */      lambda(string)          /* gintreg
        */      gini                    /* gintreg
        */      CRITTYPE(passthru)      /*
        */      NOTRANSform             /* 
        */      *                       /*
        */      ]

        GetDistOpts `distribution'
        local title "`r(title)'"
        local llf "`r(llf)'"
        local auxnames `r(auxnames)'
        local auxconstr `r(auxconstr)'
        local k_aux_eq : word count `auxnames'
        local k_eq = 1+`k_aux_eq'
        
        _vce_parse, argopt(CLuster) opt(OIM OPG Robust) old     ///
                : [`weight'`exp'], `vce' `robust' `cluster'
        local robust `r(robust)'
        local cluster `r(cluster)'
        local vce `"`r(vceopt)'"'

        _get_diopts diopts options, `options'
        mlopts mlopts, `options' const(`constraints' `auxconstr') `nolog'
        local coll `s(collinear)'
        local mlopts `mlopts' `crittype'

        gettoken y1 rhs : varlist
        _fv_check_depvar `y1', depname(depvar1)
        tsunab y1 : `y1'
        gettoken y2 rhs : rhs
        _fv_check_depvar `y2', depname(depvar2)
        tsunab y2 : `y2'
        
        if "`constant'"!="" & "`rhs'"=="" {
                di as err /*
                */ "independent variables required with noconstant option"
                exit 100
        }
        if "`weight'"!="" {
                if "`weight'"!="fweight" {
                        local wt "aweight"
                }
                else    local wt "fweight"
        }
        if "`offset'"!="" {
                tempvar offvar
                qui gen double `offvar' = `offset'
                local offopt offset(`offvar')
        }
        global S_ML_off `offset'
        global S_ML_ofv `offvar'
		
        foreach aux of local auxnames {
                if ("``aux''"!="") {
                        ParseHet ``aux''
                        local `aux'_var "`r(varlist)'"
                        local `aux'_nocns "`r(constant)'"
                }
        }
        
        if inlist("`distribution'","snormal","laplace","slaplace","ged", /*
        */ "sged","t","st","gt","sgt") | inlist("`distribution'","","normal") {
                local family "sgt"
        } 
        else    local family "gb2"
        
        if ("`initiald'"!="" & "`from'"!="") {
                di as err /*
                */ "options initiald() and from() cannot both be specified"
                exit 100
        }

/* Markout. */
        
        tempvar doit z

        mark `doit' [`weight'`exp'] `if' `in'
        qui replace `doit' = 0 if `y1'>=. & `y2'>=.
        
        if ("`family'"=="gb2") {
                qui replace `doit' = 0 if (`y2'<=0)
        }

        capture assert `y1'<=`y2' if `y1'<. & `y2'<. & `doit'
        if _rc {
                di as err `"observations with `y1' > `y2' not allowed"'
                exit 498
        }
        markout `doit' `rhs' `offset' `lnsigma_var' `p_var' `q_var' `lambda_var'
        if "`cluster'"!="" {
                markout `doit' `cluster', strok
        }

/* Index by data type (used in evaluator files). */

        tempvar idx
        qui gen byte `idx' =              ///
                cond(`y1'==`y2', 1,       /// uncensored
                cond(`y1'>=. & `y2'<., 2, /// left-censored
                cond(`y1'<. & `y2'>=., 3, /// right-censored
                cond(`y1'<. & `y2'<., 4,  /// interval
                .)))) if `doit'           //  

/* Count number of observations (and issue error 2000 if necessary). */

        _nobs `doit' [`weight'`exp']
        local N `r(N)'
        _nobs `doit' [`weight'`exp'] if `y1'==`y2', min(0)
        local Nunc `r(N)'
        _nobs `doit' [`weight'`exp'] if `y1'>=., min(0)
        local Nlc `r(N)'
        _nobs `doit' [`weight'`exp'] if `y2'>=., min(0)
        local Nrc `r(N)'

/* Remove collinearity from indepvars. */
        
        fvexpand `rhs'
        local rhsorig `r(varlist)'      
        if "`y1'" == "`y2'" {
                `vv' ///
                _rmdcoll `y1' `rhs' [`weight' `exp'] if `doit', ///
                        `constant' `coll'
                local rhs `r(varlist)'
        }
        else {
                `vv' ///
                cap _rmdcoll `y1' `rhs' [`weight' `exp'] if `doit',     ///
                        `constant' `coll'
                if _rc == 459 {
                `vv' ///
                cap _rmdcoll `y2' `rhs' [`weight' `exp'] if `doit',     ///
                        `constant' `coll'
                }
                if _rc != 0 {
                        if _rc == 459 {
                                dis as err /*
                */ "`y1' and `y2' collinear with independent variables"
                                exit 459
                        }
                        error _rc
                }               
                local rhs `r(varlist)'
        }
        // collinearity report
        local i 1
        foreach var of local rhs {
                local xname : word `i' of `rhsorig'
                _ms_parse_parts `var'
                if `r(omit)' {
                        _ms_parse_parts `xname'
                        if !`r(omit)' {
                                noi di as txt "note: `xname' omitted" /*
                                        */ " because of collinearity"
                        }
                }
                local ++i
        }
        
/* Remove collinearity and display transformed estimates of het. variables. */

        foreach aux of local auxnames {
                
                // (prep step for "report transformed parameters")
                if ("``aux''"=="") & inlist("`aux'","lnsigma","lambda") & ("`diparm'"=="") {
                        local diparm diparm(__lab__, label(transformed) comment(selected transformations of parameter estimates))
                }
                
                // remove collinearity from auxillary equations...
                if ("``aux''"!="") {
                        `vv' ///
                        _rmcoll ``aux'_var' [`weight' `exp'] if `doit', ///
                                ``aux'_nocns' `coll'
                        local `aux'_var `r(varlist)'
                }                
                // ... or report transformed parameters (sigma & lambda only)
                else if ("`aux'"=="lnsigma") {
                        local diparm `diparm' diparm(lnsigma, exp label("sigma"))
                }
                else if ("`aux'"=="lambda") { 
                        local diparm `diparm' diparm(lambda, tanh label("tanh(lambda)"))
                }
                local auxeq `auxeq' (`aux': ``aux'_var', ``aux'_nocns') // full model 
                local auxeq_cns `auxeq_cns' (`aux':)                    // constant only
        }
        
        // alternate notation for gb2 tree (except lognormal)
        if ("`family'"=="gb2" & !inlist("`distribution'","lognormal","lnormal")) {
                if inlist("","`lnsigma'","`rhs'") {
                        local diparm `diparm' diparm(__sep__) diparm(__lab__, label(alt notation) comment(a,b parameterization of distributions in GB2 family))
                        if ("`lnsigma'"=="") ///
                        local diparm `diparm' diparm(lnsigma, function(exp(-@)) derivative(-exp(-@)) label("a"))
                        if ("`rhs'"=="") ///
                        local diparm `diparm' diparm(model, exp label("b"))
                }
        }
        if ("`notransform'"!="") local diparm // erase `diparm' if 'notransform' specified

/* Get starting values. */
        
        if ("`initiald'"!="") {
                local i0 = subinstr("`0'","initiald(`initiald')","",1)
                
                // remove initiald() option from cmdline
                local i0 = subinstr("`0'","initiald(`initiald')","",.)
                // replace dist(`dist') with dist(`initiald')
                local i0 = subinstr("`i0'","(`distribution')","(`initiald')",1)
                
                if "`nolog'"=="" {
                        di _n "Fitting model with `initiald' distribution:"
                }
                quietly gintreg `i0'
                if "`nolog'"=="" {
                        di as text "`e(title)'" _n "converged in "    /*
                        */ as result "`e(ic)'" as text " iterations:" /*
                        */ "  Log-likelihood = " as res %-20.5f `e(ll)'
                }
                
                tempname b0 bp bq
                matrix `b0' = e(b)
                
                // override default initial value from 0 to 1 for p,q
                // ... if p,q not supplied by from(dist)
                foreach aux in "p" "q" { 
                        if strpos("`auxnames'","`aux'") ///
                        & !strpos("`e(auxnames)'","`aux'") {
                                matrix `b`aux'' = 1
                                matrix colnames `b`aux'' = `aux':_cons
                                matrix `b0' = (`b0', `b`aux'')
                        }
                }
                local initopt "init(`b0', skip)"
        }
        else if ("`from'"!="") {
                local initopt "init(`from')"
        }
        else if "`lnsigma'`p'`q'`lambda'" == "" {

/* Generate variable `z' to get starting values. */

                if "`constraints'`from'"=="" & "`offset'"!="" {
                        local moff "-`offset'"
                }

                qui gen double `z' =                      ///
                        cond(`y1'<.&`y2'<.,(`y1'+`y2')/2, ///
                        cond(`y1'<.,`y1',`y2'))  if `doit'

                qui summarize `z' [`wt'`exp'] if `doit', d

/* Set up initial values for the constant-only model. */

                if "`constant'"=="" { 
                        tempname b00
                        local b00_model = cond("`family'"=="sgt",r(mean),ln(r(mean)))
                        local b00_lnsigma = cond("`family'"=="sgt",ln(r(sd)),1/r(sd))
                        matrix `b00' = (`b00_model', `b00_lnsigma', 1, 1, (r(mean)-r(p50))/r(sd))
                        matrix colnames `b00' = model:_cons lnsigma:_cons p:_cons q:_cons lambda:_cons
                        
                        // when the constant-only is the full model
                        if ("`rhs'"=="") local initopt init(`b00', skip)
                }
                
/* Get initial values for the full model. */

                if "`constraints'" != "" | "`rhs'" != "" {
                        tempname bs b0
                        `vv' ///
                        qui _regress `z' `rhs' [`wt'`exp'] if `doit', `constant'
                        if "`constraints'" == "" {
                                matrix `bs' = ln(e(rmse))
                                matrix `b0' = `bs'*e(b)
                                matrix colnames `bs' = lnsigma:_cons
                        }
                        else {
                                matrix `bs' = ln(e(rmse))
                                matrix `b0' = e(b)
                                matrix colnames `bs' = lnsigma:_cons
                        }
                        matrix coleq `b0' = model
                        matrix `b0' = `b0' , `bs'
                }

/* Fit constant-only model. */
		
                if ("`rhs'"!="" & "`constant'"=="") {
                        if "`nolog'"=="" {
                                di as txt _n "Fitting constant-only model:"
                        }
                        
                        `vv' ///
                        ml model lf `llf'               /*
                        */ (model: `y1' `y2' `idx'=)    /*
                        */ `auxeq_cns'                  /*
                        */ [`weight'`exp'] if `doit',   /*
                        */ init(`b00', skip)            /*
                        */ `mlopts'                     /*
                        */ noout                        /*
                        */ missing                      /*
                        */ collinear                    /*
                        */ nopreserve                   /*
                        */ obs(`N')                     /*
                        */ maximize                     /*
                        */ search(off)                  /*
                        */ `robust'                     /*
                        */ nocnsnotes                   /*
                        */ `negh'

                        local contin continue
                }
        }

/* Heteroskedasticity */

        else {
                qui gintreg `y1' `y2' `rhs' [`weight'`exp'] if `doit', ///
                        dist(`distribution') `constant' `coll' const(`constraints')
                
                tempname b0 b00
                mat `b0' = e(b)
                mat `b00' = e(b)[1,1..colsof(e(b))-`k_aux_eq']
                
                foreach aux of local auxnames {
                        if ("``aux''"=="") {
                                mat `b00' = (`b00', `b0'[1,"`aux':_cons"])
                        }
                        else {
                                tempvar `aux'_con
                                gen double ``aux'_con' = `b0'[1,"`aux':_cons"] if `doit'
                                `vv' qui _regress ``aux'_con' ``aux'_var' [`wt'`exp'] if `doit', ``aux'_nocns'
                                mat `b00' = (`b00', e(b))
                        }
                }
                local initopt "init(`b00', copy)"
        }
        
/* Branch off for fitting full [constrained] model */

        if "`nolog'"=="" {
                di _n as txt "Fitting full model:"
        }
        
        if ("`constant'"=="") {
                local search search(off)
        }
        else    local search search(on)

/* Fit full model. */

        `vv' ///
        ml model lf `llf'                               /*
                */ (model: `y1' `y2' `idx'= `rhs', `constant' `offopt') /*
                */ `auxeq'                              /*
                */ [`weight'`exp'] if `doit',           /*
                */ `initopt'                            /*
                */ `mlopts'                             /*
                */ `vce'                                /*
                */ `contin'                             /*
                */ noout                                /*
                */ missing                              /*
                */ collinear                            /*
                */ nopreserve                           /*
                */ obs(`N')                             /*
                */ maximize                             /*
                */ `search'                             /*
                */ `diparm'                             /*
                */ `negh'                               /*
                */ `moptobj'

/* Returns. */
                
        ereturn scalar N_unc = `Nunc'
        ereturn scalar N_lc  = `Nlc'
        ereturn scalar N_rc  = `Nrc'
        ereturn scalar N_int = e(N) - e(N_unc) - e(N_lc) - e(N_rc)
        
        ereturn scalar k_eq     = `k_eq'
        ereturn scalar k_aux_eq = `k_aux_eq'
        
        ereturn local distribution "`distribution'" 
        ereturn local depvar  "`y1' `y2'"
        ereturn local indepvars "`rhs'"
        ereturn local constant  "`constant'"
        ereturn local auxnames "`auxnames'"
        

        if strpos("`auxnames'","lnsigma") & ("`lnsigma'"=="") {
                ereturn scalar b_sigma = exp([lnsigma]_cons)
                ereturn scalar se_sigma = exp([lnsigma]_cons)*[lnsigma]_se[_cons]
        }
        if strpos("`auxnames'","lambda") & ("`lambda'"=="") {
                ereturn scalar b_lambda = tanh([lambda]_cons)
                ereturn scalar se_lambda = tanh([lambda]_cons)*[lambda]_se[_cons]
        }
        if strpos("`auxnames'","p") & ("`p'"=="") {
                ereturn scalar b_p = [p]_cons
                ereturn scalar se_p = [p]_cons*[p]_se[_cons]
        }
        if strpos("`auxnames'","q") & ("`q'"=="") {
                ereturn scalar b_q = [q]_cons
                ereturn scalar se_q = [q]_cons*[q]_se[_cons]
        }
        
        foreach aux of local auxnames {
                if ("``aux''"!="") {
                        ereturn local het_`aux' "heteroskedasticity"
                }
        }

        ereturn local predict "gintreg_p"

        if "$S_BADLC"!="" {
                ereturn scalar N_lcout = $S_BADLC
                        /* # outlier intervals approximated as LC */
                global S_BADLC
        }
        if "$S_BADRC"!="" {
                ereturn scalar N_rcout = $S_BADRC
                        /* # outlier intervals approximated as RC */
                global S_BADRC
        }
        ereturn local title  "`title'"
        ereturn local offset `offset'
        
        if ("`gini'"!="") {
                if ("`rhs'`lnsigma'`p'`q'"!="") {
                        di as error ///
                        "gini not operational with independent variables"
                }
                else {
                if ("`distribution'"=="weibull") {
                        scalar sigma = exp(e(b)[1,"lnsigma:_cons"])
                        local gini_coef = 1-(.5^(sigma))
                }
                else if ("`distribution'"=="gamma"} {
                        scalar sigma = exp(e(b)[1,"lnsigma:_cons"])
                        scalar p = e(b)[1,"p:_cons"]
                        local gini_coef = exp(lngamma(p+.5)) ///
                        / (exp(lngamma(p+1)) * sqrt(_pi))
                }
                else if inlist("`distribution'","br3","dagum") {
                        scalar sigma = exp(e(b)[1,"lnsigma:_cons"])
                        scalar p = e(b)[1,"p:_cons"]
                        local gini_coef = ///
                        [exp(lngamma(p)) * exp(lngamma(2*p+sigma))] ///
                        / [exp(lngamma(p+sigma))*exp(lngamma(2*p))] - 1
                }
                else if inlist("`distribution'","br12","sm") {
                        scalar sigma = exp(e(b)[1,"lnsigma:_cons"])
                        scalar q = e(b)[1,"q:_cons"]
                        local gini_coef = 1 - [exp(lngamma(q)) ///
                        * exp(lngamma(2*q-sigma))] ///
                        / [exp(lngamma(q-sigma)) * exp(lngamma(2*q))]
                }
                else di as err "gini not operational with dist(`distribution')"
                ereturn scalar gini_coef = `gini_coef'
                ereturn local gini "gini"
        }
        
        }
        
        * Clean up 
        constraint drop `auxconstr'

/* Display results. */

        if "`display'" == "" {
                ereturn local cmd "intreg" // trick ml_display into displaying obs types (doesn't work for -replay-)
                DiGintreg, level(`level') `diopts' neq(`k_eq')
                ereturn local cmd "gintreg"
                error `e(rc)'
        }
end

program ParseHet, rclass
		syntax varlist(fv ts numeric) [, noCONStant]
		return local varlist "`varlist'"
		return local constant `constant'
end

program define DiGintreg
        syntax [, Level(cilevel) *]

        _get_diopts diopts else, `options'
        version 9: ml display, level(`level') nofootnote `diopts' `else'
        _prefix_footnote
        if ("`e(gini)'"=="gini") di "Gini coefficient: `e(gini_coef)'"

if !missing(e(N_lcout)) | !missing(e(N_rcout)) {

/* The following messages should be VERY rare. */

        if e(N_lcout) == 1 {
                di _n as txt "Note: 1 interval observation was an " /*
                */ "extreme outlier (large negative residual)" _n /*
                */ "      and was handled by assuming it was a " /*
                */ "left-censored observation."
        }
        else if e(N_lcout) <. {
                di _n as txt "Note: `e(N_lcout)' interval observations " /*
                */ "were extreme outliers (all with large negative" _n /*
                */ "      residuals) and were handled by " /*
                */ "assuming they were left-censored observations."
        }
        if e(N_rcout) == 1 {
                di _n as txt "Note: 1 interval observation was an " /*
                */ "extreme outlier (large positive residual)" _n /*
                */ "      and was handled by assuming it was a " /*
                */ "right-censored observation."
        }
        else if e(N_rcout) <. {
                di _n as txt "Note: `e(N_rcout)' interval observations " /*
                */ "were extreme outliers (all with large positive" _n /*
                */ "      residuals) and were handled by " /*
                */ "assuming they were right-censored observations."
        }
        di as txt /*
        */ "      This is an excellent approximation for all intervals " /*
        */ "except for those" _n "      that are very narrow."

} 
end

program define GetDistOpts, rclass

	if inlist("`1'","","normal") {
		local title "Interval regression"
		local llf "intllf_normal"
                local auxnames "lnsigma"
	}
        else if ("`1'"=="sged") {
		local title "SGED interval regression"
		local llf "intllf_sged"
                local auxnames "lnsigma p lambda"
	}
        else if ("`1'"=="ged") {
		local title "GED interval regression"
		local llf "intllf_sged"
                local auxnames "lnsigma p lambda"
                constraint free
                constraint define `r(free)' [lambda]_cons=0
                local auxconstr `r(free)'
	}
        else if ("`1'"=="slaplace") {
		local title "Skewed Laplace interval regression"
		local llf "intllf_sged"
                local auxnames "lnsigma p lambda"
                constraint free
                constraint define `r(free)' [p]_cons=1
                local auxconstr `r(free)'
	}
        else if ("`1'"=="laplace") {
		local title "Laplace interval regression"
		local llf "intllf_sged"
                local auxnames "lnsigma p lambda"
                constraint free
                constraint define `r(free)' [lambda]_cons=0
                local auxconstr "`r(free)'"
                constraint free
                constraint define `r(free)' [p]_cons=1
                local auxconstr "`auxconstr' `r(free)'"
        }
        else if ("`1'"=="snormal") {
		local title "Skewed normal interval regression"
		local llf "intllf_sged"
                local auxnames "lnsigma p lambda"
                constraint free
                constraint define `r(free)' [p]_cons=2
                local auxconstr `r(free)'
        }
        else if inlist("`1'","lognormal","lnormal") {
		local title "Lognormal interval regression"
		local llf "intllf_lognormal"
                local auxnames "lnsigma"
	}
        else if ("`1'"=="sgt") {
		local title "Skewed Generalized t interval regression"
		local llf "intllf_sgt"
                local auxnames "lnsigma p q lambda"
	}
        else if ("`1'"=="gt") {
		local title "Generalized t interval regression"
		local llf "intllf_sgt"
                local auxnames "lnsigma p q lambda"
                constraint free
                constraint define `r(free)' [lambda]_cons=0
                local auxconstr `r(free)'
	}
        else if ("`1'"=="st") {
		local title "Skewed t interval regression"
		local llf "intllf_sgt"
                local auxnames "lnsigma p q lambda"
                constraint free
                constraint define `r(free)' [p]_cons=2
                local auxconstr `r(free)'
	}
        else if ("`1'"=="t") {
		local title "t interval regression"
		local llf "intllf_sgt"
                local auxnames "lnsigma p q lambda"
                constraint free
                constraint define `r(free)' [lambda]_cons=0
                local auxconstr "`r(free)'"
                constraint free
                constraint define `r(free)' [p]_cons=2
                local auxconstr "`auxconstr' `r(free)'"
        }
        else if ("`1'"=="ggamma") {
                local title "Generalized gamma interval regression"
                local llf "intllf_ggamma"
                local auxnames "lnsigma p"
        }
        else if ("`1'"=="gamma") {
                local title "Gamma interval regression"
                local llf "intllf_ggamma"
                local auxnames "lnsigma p"
                constraint free
                constraint define `r(free)' [lnsigma]_cons=0
                local auxconstr "`r(free)'"
        }
        else if ("`1'"=="weibull") {
                local title "Weibull interval regression"
                local llf "intllf_ggamma"
                local auxnames "lnsigma p"
                constraint free
                constraint define `r(free)' [p]_cons=1
                local auxconstr "`r(free)'"
        }
        else if ("`1'"=="gb2") {
                local title "Generalized beta of the second kind interval regression"
                local llf "intllf_gb2"
                local auxnames "lnsigma p q"
        }
        else if inlist("`1'","br12","sm") {
                local title "Burr-12 interval regression"
                local llf "intllf_gb2"
                local auxnames "lnsigma p q"
                constraint free
                constraint define `r(free)' [p]_cons=1
                local auxconstr "`r(free)'"
        }
        else if inlist("`1'","br3","dagum") {
                local title "Burr-3 interval regression"
                local llf "intllf_gb2"
                local auxnames "lnsigma p q"
                constraint free
                constraint define `r(free)' [q]_cons=1
                local auxconstr "`r(free)'"
        }
        else {
                di as err "option distribution() specified incorrectly"
                error 198
        }

	return local title "`title'"
	return local llf "`llf'"
        return local auxnames "`auxnames'"
        return local auxconstr "`auxconstr'"
end