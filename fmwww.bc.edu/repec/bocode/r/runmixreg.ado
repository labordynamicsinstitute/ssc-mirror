*! runmixregls.ado, George Leckie and Chris Charlton, 01Feb2021
****************************************************************************
* -runmixregls-
****************************************************************************
program define runmixreg
  version 12.0
  if ~replay() {
    Estimate `0'
  }
  if replay() {
    if ("`e(cmd)'" ~= "runmixreg") error 301
    Replay `0'
  }
end

program define Estimate, eclass sortpreserve
  version 12.0
  syntax varlist(min=1 numeric fv) [if] [in] [, ///
      Random(string) ///
      Time(string) ///
      ///
      reffects(namelist min=1 max=1) ///
      ///
      EMiterate(numlist >=0 integer min=1 max=1) ///
      TOLerance(numlist >0 min=1 max=1) ///   
      IFIN ///
      AUTO(numlist >=0 <=2 integer min=1 max=1) ///
      MU ///
      noCOV ///
      TIMEPoints(numlist >=0) ///
      NS(numlist >=0 <=5 integer min=1 max=1) ///
      S(numlist >=0 integer min=1 max=1) ///
      INIT(namelist min=5 max=5) ///
      ///
      noHEader ///
      noTABle ///
      ///
      Level(cilevel) ///
      ///
      noomitted ///
      vsquish ///
      noemptycells ///
      baselevels ///
      allbaselevels ///
      cformat(string) ///
      pformat(string) ///
      sformat(string) ///
      nolstretch ///
      ///
      COEFLegend ///
    ]
    
    * Put all options into the local alloptions
    tokenize `"`0'"', parse(",")
    macro shift 2
    local alloptions "`*'"

    * Marksample straight away to get the [if] and [in] information as this is lost when we do the next syntax commands
    marksample touse // note that this will only listwise delete on the response and the mvars, random and time variables

    local samp_in `in'
    local samp_if `if'
    
    * Parse the response and mean covariates
    tokenize `varlist'
    local response `1'
    macro shift
    local fvars `*'

    * Find out what the id variable is
    quietly xtset
    local id = r(panelvar)  

    * Parse random covariates
    local 0 `random'
    syntax [varlist(default=none)]
    local rvars `varlist'
    markout `touse' `rvars' // additional listwise deletion on whether any of the random variables are missing
    
    * Parse time covariate
    local 0 `time'
    syntax [varlist(default=none max=1)]
    local tvars `varlist'
    markout `touse' `tvars' // additional listwise deletion on whether any of the time values are missing

    sort `id' `tvars'
    
    * List of all variables to be sent to MIXREGLS
    local allvars `id' `response' `fvars' `rvars' `tvars'
    local allvars : list uniq allvars

    * Parse estimation options
    if ("`emiterate'"=="") local emiterate = 20 // NUMBER OF EM CYCLES
    if ("`tolerance'"=="") local tolerance = 0.0001 // convergence criterion (usually set to .001 or .0001).
    if ("`auto'"=="") local auto = 0 // 0 FIX AUTOCORR AT ZERO & ESTIMATE ALL ELSE, FIX AUTOCORR NONZERO & ESTIMATE ALL ELSE, ESTIMATE EVERYTHING
    if ("`ns'"=="") local ns = 0 // 0 STATIONARY AR1 ERROR STRUCTURE, 1 NON-STATIONARY AR1 ERROR STRUCTURE, 2 STATIONARY MA1 ERROR STRUCTURE, 3 STATIONARY ARMA(1,1) ERROR STRUCTURE, 4 SYMMETRIC TOEPLITZ (s) ERROR STRUCTURE, 5 TOEPLITZ SMOOTHED VIA SPECTRAL ANALYSIS
    if (`ns' == 0 | `ns' == 1 | `ns' == 2) {
      local s = 1 
    }
    if (`ns' == 3) {
      local s = 2
    }
    if ("`s'"=="") { // number of autocorrelation terms, which should equal 1 for NS = 0,1,2; 2 for NS = 3; or an integer (>= 1 and < maximum number of timepoints) for NS equal to 4.
      if (`ns' == 4 | `ns' == 5) {
        local s = 1 //`:list sizeof timespoints' - 1
      }
    }

    if `auto' == 1 {
      if ("`init'" == "") {
        display as error "initial values must be specified if auto is set to 1"
        exit 198
      }
    }

    * Work out b and V row and column names

    if "`mu'" == "" {
      local fvarsall "`fvars'"
    }
    else {
      local fvars : list fvars - rvars // if nomu is turned on variables cannot be specified in both fixed and random parts
      local fvarsall : list rvars | fvars
    }

    local fnames "`fvarsall'"

    local rnames ""
    foreach var1 of local rvars {
      local rnames `rnames' "cov(`var1',`var1')"
      if "`cov'" == "" {
        foreach var2 of local rvars {
          local i : list posof "`var1'" in rvars
          local j : list posof "`var2'" in rvars
          if (`i' < `j') local rnames `rnames' "cov(`var1',`var2')"
        }
      }
    }
    
    local tnames "`tvars'"

    local anames ""
    if (`auto' == 2 | `auto' == 1) {
      forvalues i = 1/`s' {
        local anames `anames' "auto`i'"
      }
    }
   
    local names "`fnames' `rnames' var(Residual) `anames'" 

    ****************************************************************************
    * (1) SAVE DAT FILE
    ****************************************************************************

    * Order the variables into their natural ordering
    * order `allvars'

    * Generate a unique sort index
    * generate _sortindex = _n
    
    * Count observations in current sample
    quietly count if `touse'

    * Check that there are two or more observations
    if r(N)==0 {
        display as error "no observations"
        exit 198
    }
    if r(N)==1 {
        display as error "insufficient observations"
        exit 198
    }

    * Sort the data according to the data hierarchy
    * sort `id' _sortindex
    * drop _sortindex
       
    
    ****************************************************************************
    * (2) PREPARE INPUTS FOR THE MIXREGLS DEFINITION FILE
    ****************************************************************************
  
    * Line 6
    local P : list sizeof fvarsall     // Fixed part
    local R : list sizeof rvars        // Random part
    if "`cov'" == "" {
      local RR = (`R' * (`R'+1) / 2)
    }
    else {
      local RR = `R'
    }

    tempname CONV
    scalar `CONV' = `tolerance'          // Tolerance

    tempname NEM
    scalar `NEM' = `emiterate'
	
    tempname IFIN
    if "`ifin'" == "" {
      scalar `IFIN' = 0
    }
    else {
      scalar `IFIN' = 1
    }
	
    tempname NAUTO
    scalar `NAUTO' = `auto'
    // If turned on adds all random effect variables to fixed part too
    tempname NOMU
    if "`mu'" == "" {
      scalar `NOMU' = 1
    }
    else {
      scalar `NOMU' = 0
    }

    // Turns on/off random part covariances
    tempname NOCOV
    if "`cov'" == "" {
      scalar `NOCOV' = 0
    }
    else {
      scalar `NOCOV' = 1
    }
	
    tempname NS
    scalar `NS' = `ns'
	
    tempname S
    scalar `S' = `s'
	
    * Work out total number of parameters in the model
    local k = `P' + `RR' + 1
    if (`auto' == 2 | `auto' == 1) {
      local k = `k' + `s'
    }
   
    * Line 8
    tempname fvarsfields
    foreach var1 of local fvars {
      local v = 1
      foreach var2 of local allvars {
        if "`var1'"=="`var2'" {
          matrix `fvarsfields' = (nullmat(`fvarsfields'), `v')      
        }
        local v = `v' + 1
      }
    }
    
    * Line 9
    tempname rvarsfields
    foreach var1 of local rvars {
      local v = 1
      foreach var2 of local allvars {
        if "`var1'"=="`var2'" {
          matrix `rvarsfields' = (nullmat(`rvarsfields'), `v')      
        }
        local v = `v' + 1
      }
    }

    tempname tvarfield
    scalar `tvarfield' = 0
    foreach var1 of local tvars {
      local v = 1
      foreach var2 of local allvars {
        if "`var1'" == "`var2'" {
          scalar `tvarfield' = `v'
        }
        local v = `v' + 1
      }
    }
	
    tempname tvarvalues
    foreach t of local timepoints {
      matrix `tvarvalues' = (nullmat(`tvarvalues'), `t')
    }

    ****************************************************************************
    * (3) PREPARE OUTPUT VARIABLES TO RECEIVE RESULTS
    ****************************************************************************
    
    tempname nobs
    
    **************************************
    * Group Information
    **************************************    
    
    tempname N_g
    tempname g_min
    tempname g_avg
    tempname g_max    
    
    **************************************
    * Model 1 parameter estimates
    **************************************    
    
    tempname dev
    
    * Equation names
    local eqnames
    forvalues i = 1/`P' {
        local eqnames `eqnames' "Fixed"
    }
    forvalues i = 1/`RR' {
        local eqnames `eqnames' "Random"
    }
    local eqnames `eqnames' "Residual error"
    if (`auto' == 2 | `auto' == 1) {
        forvalues i = 1/`s' {
          local eqnames `eqnames' "Autocorrelation"
        }
    }
    
    * b matrix
    tempname b
    matrix `b' = J(1, `k', .)

    
    * V matrix
    tempname V
    matrix `V' = J(`k', `k', 0)
    
    ****************************************************************************
    * (4) RUN MODEL
    ****************************************************************************
    
    tempname re
    scalar `re' = 0

	
    * Parse reffects and reses
    if ("`reffects'"~="") {
	  scalar `re' = 1
          foreach var of local rvars {
            local i : list posof "`var'" in rvars
	    local reffect_b "`reffect_b' `reffects'_`i'"
            confirm new variable `reffects'_`i'
            quietly generate `reffects'_`i' = .
            label var `reffects'_`i' "`var' random effect"
          }


          foreach var1 of local rvars {
            foreach var2 of local rvars {
              local i : list posof "`var1'" in rvars
              local j : list posof "`var2'" in rvars
              if (`i' <= `j') {
                local reffect_V "`reffect_V' `reffects'_`i'_`j'"
                confirm new variable `reffects'_`i'_`j'
                quietly generate `reffects'_`i'_`j' = .
                if (`i' == `j') {
                  label var `reffects'_`i'_`j' "`var1' random effect co-variance"
                }
                else {
                  label var `reffects'_`i'_`j' "`var1' by `var2' random effect variance"
                }
              }
            }
          }
	  local allvars `allvars' `reffect_b' `reffect_V'
    }
    else {
        scalar `re' = 0
    }

    tempname istart
    tempname imu
    tempname ialpha
    tempname ivarco
    tempname ierror
    tempname iauto
    if "`init'" == "" {
      scalar `istart' = 0
    }
    else {
      scalar `istart' = 1
      matrix `imu'    = `: word 1 of `init''
      matrix `ialpha' = `: word 2 of `init''
      matrix `ivarco' = `: word 3 of `init''
      matrix `ierror' = `: word 4 of `init''
      matrix `iauto'  = `: word 5 of `init''
    }

    tempname niter
    scalar `niter' = 0
    timer clear 99
    timer on 99
    plugin call mixreg `allvars' `samp_if' `samp_in', "`fvarsfields'" "`rvarsfields'" "`tvarfield'" "`tvarvalues'" "`NEM'" "`CONV'" "`IFIN'" "`NAUTO'" "`NOMU'" "`NOCOV'" "`NS'" "`S'" "`nobs'" "`N_g'" "`g_min'" "`g_avg'" "`g_max'" "`dev'" "`b'" "`V'" "`re'" "`niter'" "`istart'" "`imu'" "`ialpha'" "`ivarco'" "`ierror'" "`iauto'"
    timer off 99
    quietly timer list
    local time = r(t99)
    timer clear 99    

    ****************************************************************************
    * (5) RETRIEVE MODEL ESTIMATES
    ****************************************************************************

    matrix colnames `b' = `names'
    matrix rownames `b' = y1
    matrix coleq `b' = `eqnames'

    matrix rownames `V' = `names'
    matrix roweq `V' = `eqnames'
    matrix colnames `V' = `names'
    matrix coleq `V' = `eqnames'


    **************************************
    * LOG-LIKELIHOODS AND ITERATIONS
    **************************************

    * Model 1 ll
    local ll = -0.5*`dev'

    ****************************************************************************
    * ERETURNS
    ****************************************************************************

    **************************************
    * ERETURN ESTIMATES
    **************************************
    ereturn post `b' `V'
    tempname V check_pd
    matrix `V' = e(V)
    capture matrix `check_pd' = cholesky(`V')
    if c(rc)==506 {
      display as txt "{hline 78}
      display _col(`=0.5*(78 - length("MIXREGLS variance-covariance matrix of the estimators file"))') as txt "MIXREGLS variance-covariance matrix of the estimators file"
      display as txt "{hline 78}
      matrix list `V'
      display as txt "{hline 78}
      display as error "the variance-covariance matrix of the estimators, e(V), is not positive definite"
    }

    **************************************
    * ERETURN SCALARS
    **************************************

    ereturn scalar N = `nobs'
    ereturn scalar N_g = `N_g'
    ereturn scalar g_min = `g_min'
    ereturn scalar g_avg = `g_avg'
    ereturn scalar g_max = `g_max'

    ereturn scalar k   = `k'

    ereturn scalar time = `time'

    ereturn scalar ll   = `ll'
    
    ereturn scalar deviance   = -2*e(ll)

    ereturn scalar iterations   = `niter'

    **************************************
    * ERETURN LOCALS
    **************************************

    ereturn local tolerance = `tolerance'
    ereturn local ivar "`id'"
    ereturn local depvar "`response'"
    ereturn local title "Mixed-effects model"
    ereturn local cmdline `e(cmd)' `runmlwin_cmdline'
    ereturn local cmd "runmixreg"


    **************************************
    * ERETURN FUNCTIONS
    **************************************

    ereturn repost, esample(`touse')

    **************************************

    ****************************************************************************
    * (8) OUTPUT  
    ****************************************************************************

    * Estimates table
    Replay, `alloptions'

end


program define Replay
  version 12.0
  syntax [, ///
    noHEader ///
    noTABle ///
    ///
    Level(cilevel) ///
    ///
    noomitted ///
    vsquish ///
    noemptycells ///
    baselevels ///
    allbaselevels ///
    cformat(string) ///
    pformat(string) ///
    sformat(string) ///
    nolstretch ///
    ///
    COEFLegend ///
    * ///
  ]
  
  if ("`header'"=="") {

    display
    display as txt "runmixregls - Run MIXREG from within Stata" _n

    #delimit ;

    display
    _col(1)  as txt e(title)
    _col(50) as txt "Number of obs      =" _col(`=79-9') as res %9.0f e(N)
    ;

    display
    _col(1)  as txt "Group variable: " e(ivar) _col(22) as res %10.0g 
    _col(50) as txt "Number of groups   =" _col(`=79-9') as res %9.0f e(N_g)
    ;

    display
    _col(50) as txt "Obs per group: min =" _col(`=79-9') as res %9.0f e(g_min)
    ;

    display
    _col(50) as txt "               avg =" _col(`=79-9') as res %9.1f e(g_avg)
    ;

    display
    _col(50) as txt "               max =" _col(`=79-9') as res %9.0f e(g_max)
    ;

    display
    _col(1)  as txt "Run time (seconds) =" _col(22) as res %10.0g e(time)
    ;

    display
    _col(1)  as txt "Log Likelihood     =" _col(22) as res %10.9g e(ll)                                                                                   
    ;

    display
    _col(1)  as txt "Deviance           =" _col(22) as res %10.9g e(deviance)                                                                                   
    ;

    #delimit cr

  }

  if ("`table'"=="") {
    ereturn display, ///
      level(`level') ///
      `noomitted' ///
      `vsquish' ///
      `noemptycells' ///
      `baselevels' ///
      `allbaselevels' ///
      cformat(`cformat') ///
      pformat(`pformat') ///
      sformat(`sformat') ///
      `nolstretch' ///
      `coeflegend'

  } 

end

program mixreg, plugin

********************************************************************************
exit
