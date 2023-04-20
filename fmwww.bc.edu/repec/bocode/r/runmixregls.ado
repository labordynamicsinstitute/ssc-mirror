*! runmixregls.ado, George Leckie and Chris Charlton, 09Feb2023
****************************************************************************
* -runmixregls-
****************************************************************************
program define runmixregls
  version 12.0
  if ~replay() {
    Estimate `0'
  }
  if replay() {
    if ("`e(cmd)'" ~= "runmixregls") error 301
    Replay `0'
  }
end

program define Estimate, eclass sortpreserve
  version 12.0

  local runmixregls_cmdline `0'

  syntax varlist(min=1 numeric fv) [if] [in] [, ///
      noConstant ///
      Between(string) ///
      Within(string) ///
      Association(name) ///
      ///
      meanxb(namelist min=1 max=1) ///
      meanfitted(namelist min=1 max=1) ///
      bgvariancexb(namelist min=1 max=1) ///
      bgvariancefitted(namelist min=1 max=1) ///
      wgvariancexb(namelist min=1 max=1) ///
      wgvarianceeta(namelist min=1 max=1) ///
      wgvariancefitted(namelist min=1 max=1) ///
      reffects(namelist min=1 max=1) ///
      reunstandard(namelist min=1 max=1) ///
      residuals(namelist min=1 max=1) ///
      runstandard(namelist min=1 max=1) ///
      ///
      noADAPT ///
      INTPoints(numlist >0 integer min=1 max=1) ///
      ///
      iterate(numlist >0 integer min=1 max=1) ///
      TOLerance(numlist >0 min=1 max=1) /// 
      RIDGEin(real 0.1) ///
      STANDardize ///
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
    marksample touse // note that this will only listwise delete on the response and the mvars, not on bvars on wvars

    local samp_in `in'
    local samp_if `if'
    
    * Parse the response and mean covariates
    tokenize `varlist'
    local response `1'
    macro shift
    local mvars `*'
    local mcons `constant'

    * Find out what the id variable is
    quietly xtset
    local id = r(panelvar)  

    * Parse BS variance covariates
    local 0 `between'
    syntax [varlist(default=none)] [, noConstant]
    local bvars `varlist'
    local bcons `constant'
    markout `touse' `bvars' // additional listwise deletion on whether any of the between variables are missing

    * Parse WS variance covariates
    local 0 `within'
    syntax [varlist(default=none)] [, noConstant]
    local wvars `varlist'
    local wcons `constant'
    markout `touse' `wvars' // additional listwise deletion on whether any of the within variables are missing
    
    * List of all variables to be sent to MIXREGLS
    local allvars `id' `response' `mvars' `bvars' `wvars'
    local allvars : list uniq allvars
    
    * Parse association
    if ("`association'"=="") local ncov = 1
    if ("`association'"~="") {
      local 0, `association'
      syntax, [None Linear Quadratic]
      if ("`none'"~="") local ncov = 0
      if ("`linear'"~="") local ncov = 1
      if ("`quadratic'"~="") local ncov = 2
    }

    * Option dependancies
    if ("`residuals'" ~= "") { //residuals depends on runstandard and wgvariancefitted (if not returned from plugin)
      if ("`runstandard'" == "") {
        tempvar runstandard
      }
      if ("`wgvariancefitted'" == "") {
        tempvar wgvariancefitted
      }
    }

    if ("`runstandard'" ~= "" & "`meanfitted'" == "") { // runstandard depends on meanfitted
      tempvar meanfitted
    }

    if ("`meanfitted'" ~= "") {
      if ("`meanxb'" == "") { // meanfitted depends on meanxb
        tempvar meanxb
      }

      if ("`reunstandard'" == "") { // meanfitted depends on reunstandard
        tempvar reunstandard
      }
    }

    if ("`wgvariancefitted'" ~= "" & "`wgvarianceeta'" == "") { // wgvariancefitted depends on wgvarianceeta
      tempvar wgvarianceeta
    }

    if ("`wgvarianceeta'" ~= "") {
      if ("`wgvariancexb'" == "") { // wgvarianceeta depends on wgvariancexb
        tempvar wgvariancexb
      }

      if ("`reunstandard'" == "") { // wgvarianceeta depends on reunstandard
        tempvar reunstandard
      }
    }

    if ("`reunstandard'" ~= "") { // reunstandard depends on reffects and bgvariancefitted
      if ("`reffects'" == "") {
        tempvar reffects
      }
      if ("`bgvariancefitted'" == "") {
        tempvar bgvariancefitted
      }
    }

    if ("`bgvariancefitted'" ~= "" & "`bgvariancexb'" == "") { // bgvariancefitted depends on bgvariancexb
      tempvar bgvariancexb
    }

    * Parse reffects and reses
    if ("`reffects'"~="") {
      local reffect_1_b "`reffects'0"
      local reffect_2_b "`reffects'1"
      local reffect_1_var "`reffects'0_var"
      local reffect_1_2_cov "`reffects'0_1_cov"
      local reffect_2_var "`reffects'1_var"
      local reffect_1_se "`reffects'0_se"
      local reffect_2_se "`reffects'1_se"
      confirm new variable `reffect_1_b'
      confirm new variable `reffect_2_b'
      confirm new variable `reffect_1_var'
      confirm new variable `reffect_1_2_cov'
      confirm new variable `reffect_2_var'
      confirm new variable `reffect_1_se'
      confirm new variable `reffect_2_se'
    }

    if ("`reunstandard'" ~= "") {
      local reunstandard_1_b "`reunstandard'0"
      local reunstandard_2_b "`reunstandard'1"
      local reunstandard_1_var "`reunstandard'0_var"
      local reunstandard_1_2_cov "`reunstandard'0_1_cov"
      local reunstandard_2_var "`reunstandard'1_var"
      local reunstandard_1_se "`reunstandard'0_se"
      local reunstandard_2_se "`reunstandard'1_se"
      confirm new variable `reunstandard_1_b'
      confirm new variable `reunstandard_2_b'
      confirm new variable `reunstandard_1_var'
      confirm new variable `reunstandard_1_2_cov'
      confirm new variable `reunstandard_2_var'
      confirm new variable `reunstandard_1_se'
      confirm new variable `reunstandard_2_se'
    }

    * Parse residuals
    if ("`residuals'" ~= "") {
      confirm new variable `residuals'
    }

    if ("`meanxb'" ~= "") {
      confirm new variable `meanxb'
    }

    if ("`meanfitted'" ~= "") {
      confirm new variable `meanfitted'
    }

    if ("`runstandard'" ~= "") {
      confirm new variable `runstandard'
    }

    if ("`wgvarianceeta'" ~= "") {
      confirm new variable `wgvarianceeta'
    }

    if ("`wgvariancexb'" ~= "") {
      confirm new variable `wgvariancexb'
    }

    if ("`wgvariancefitted'" ~= "") {
      confirm new variable `wgvariancefitted'
    }

    if ("`bgvariancexb'" ~= "") {
      confirm new variable `bgvariancexb'
    }

    if ("`bgvariancefitted'" ~= "") {
      confirm new variable `bgvariancefitted'
    }

    * Parse estimation options
    if ("`iterate'"=="") local iterate = 200
    if ("`tolerance'"=="") local tolerance = 0.0005
    if ("`intpoints'"=="") local intpoints = 11

    * Work out b and V row and column names

    * Swap back if enabling permutation
    //if ("`mcons'"=="") local mnames "`mvars' _cons"
    if ("`mcons'"=="") local mnames "_cons `mvars'"
    if ("`mcons'"=="noconstant") local mnames "`mvars'"
    
    * Swap back if enabling permutation
    //if ("`bcons'"=="") local bnames "`bvars' _cons"
    if ("`bcons'"=="") local bnames "_cons `bvars'"
    if ("`bcons'"=="noconstant") local bnames "`bvars'"

    * Swap back if enabling permutation
    // if ("`wcons'"=="") local wnames "`wvars' _cons"
    if ("`wcons'"=="") local wnames "_cons `wvars'"
    if ("`wcons'"=="noconstant") local wnames "`wvars'"
    
    if (`ncov'==0) local anames
    if (`ncov'==1 | `ncov'==2) {
      local anames "linear"
    }
    if (`ncov'==2) {
      local anames "`anames' quadratic"
    }
    
    local sname "sigma"

    local names_1 "`mnames' `bnames' _cons"
    local names_2 "`mnames' `bnames' `wnames'"
    local names_3 "`mnames' `bnames' `wnames' `anames' `sname'"

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
    local P : list sizeof mvars        // Mean model
    local R : list sizeof bvars        // BS model
    local S : list sizeof wvars        // WS model
    tempname PNINT
    scalar `PNINT' = ("`mcons'"=="noconstant") // Mean model
    tempname RNINT    
    scalar `RNINT' = ("`bcons'"=="noconstant")   // BS model
    tempname SNINT
    scalar `SNINT' = ("`wcons'"=="noconstant")   // WS model
    tempname CONV
    scalar `CONV' = `tolerance'          // Tolerance
    tempname NQ
    scalar `NQ' = `intpoints'            // Number of integration points
    tempname AQUAD
    scalar `AQUAD' = ("`adapt'"=="")       // Adaptive quadrature
    tempname MAXIT
    scalar `MAXIT' = `iterate'           // Maximum number of iterations
    tempname STD
    scalar `STD' = ("`standardize'"~="")     // Standardize all variables
    tempname NCOV
    scalar `NCOV' = `ncov'             // Association between log WS variance and random-location effect
	
    tempname RIDGEIN
    scalar `RIDGEIN' = `ridgein'             // Association between log WS variance and random-location effect

    tempname MLS
    scalar `MLS' = 0

    * Work out number of parameters in each equation
    local PINCINT = `P' + 1 - `PNINT'       // Mean model
    local RINCINT = `R' + 1 - `RNINT'       // BS model

    local nassoc = `NCOV'

    local SINCINT = `S' + 1 - `SNINT'       // WS model

    * Work out total number of parameters in the model
    local k_1 = `PINCINT' + `RINCINT' + 1
    local k_2 = `PINCINT' + `RINCINT' + `SINCINT' 
    local k_3 = `PINCINT' + `RINCINT' + `SINCINT' + `nassoc' + 1
   
    * Line 8
    tempname mvarsfields
    foreach var1 of local mvars {
      local v = 1
      foreach var2 of local allvars {
        if "`var1'"=="`var2'" {
          matrix `mvarsfields' = (nullmat(`mvarsfields'), `v')
        }
        local v = `v' + 1
      }
    }
    
    * Line 9
    tempname bvarsfields
    foreach var1 of local bvars {
      local v = 1
      foreach var2 of local allvars {
        if "`var1'"=="`var2'" {
          matrix `bvarsfields' = (nullmat(`bvarsfields'), `v')
        }
        local v = `v' + 1
      }
    }

    * Line 10
    tempname wvarsfields
    foreach var1 of local wvars {
      local v = 1
      foreach var2 of local allvars {
        if "`var1'"=="`var2'" {
          matrix `wvarsfields' = (nullmat(`wvarsfields'), `v')
        }
        local v = `v' + 1
      }
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
    
    tempname dev_1
    
    * Equation names
    local eqnames_1
    forvalues i = 1/`PINCINT' {
      local eqnames_1 `eqnames_1' "Mean"
    }
    forvalues i = 1/`RINCINT' {
      local eqnames_1 `eqnames_1' "Between"
    }
    local eqnames_1 `eqnames_1' "Within"
    
    * b matrix
    tempname b_1
    matrix `b_1' = J(1, `k_1', .)

    
    * V matrix
    tempname V_1
    matrix `V_1' = J(`k_1', `k_1', 0)
   

    **************************************
    * Model 2 parameter estimates
    **************************************

    tempname dev_2    
    
    * Equation names
    local eqnames_2
    forvalues i = 1/`PINCINT' {
      local eqnames_2 `eqnames_2' "Mean"
    }
    forvalues i = 1/`RINCINT' {
      local eqnames_2 `eqnames_2' "Between"
    }
    forvalues i = 1/`SINCINT' {
      local eqnames_2 `eqnames_2' "Within"
    }
    
    * b matrix
    tempname b_2
    matrix `b_2' = J(1, `k_2', .)
    
    * V matrix
    tempname V_2
    matrix `V_2' = J(`k_2', `k_2', 0)


    **************************************
    * Model 3 parameter estimates
    **************************************

    tempname dev_3    
    
    * Equation names
    local eqnames_3
    forvalues i = 1/`PINCINT' {
      local eqnames_3 `eqnames_3' "Mean"
    }
    forvalues i = 1/`RINCINT' {
      local eqnames_3 `eqnames_3' "Between"
    }
    forvalues i = 1/`SINCINT' {
      local eqnames_3 `eqnames_3' "Within"
    }
    forvalues i = 1/`nassoc' {
      local eqnames_3 `eqnames_3' "Association"
    }
    local eqnames_3 `eqnames_3' "Scale"
    
    * b matrix
    tempname b_3
    matrix `b_3' = J(1, `k_3', .)
    
    * V matrix
    tempname V_3
    matrix `V_3' = J(`k_3', `k_3', 0)
    
    ****************************************************************************
    * (4) RUN MODEL
    ****************************************************************************
    
    tempname re_1
    scalar `re_1' = 0
    tempname re_2
    scalar `re_2' = 0
    tempname re_3
    if "`reffects'"~="" {
      scalar `re_3' = 1
      quietly generate `reffect_1_b' = .
      label var `reffect_1_b' "EB std. location r.e."
      quietly generate `reffect_2_b' = .
      label var `reffect_2_b' "EB std. scale. scale r.e"
      quietly generate `reffect_1_var' = .
      label var `reffect_1_var' "EB std. location r.e. sampling variance"
      quietly generate `reffect_1_2_cov' = .
      label var `reffect_1_2_cov' "EB std. scale location r.e. sampling covariance"
      quietly generate `reffect_2_var' = .
      label var `reffect_2_var' "EB std. scale r.e. sampling variance"
      local allvars `allvars' `reffect_1_b' `reffect_2_b' `reffect_1_var' `reffect_1_2_cov' `reffect_2_var'
    }
    else {
      scalar `re_3' = 0
    }

    tempname res_1
    scalar `res_1' = 0
    tempname res_2
    scalar `res_2' = 0
    tempname res_3
    if ("`residuals'"~="") {
      scalar `res_3' = 1
      quietly generate `residuals' = .
      label var `residuals' "Standardized residual"
      local allvars `allvars' `residuals'
    }
    else {
      scalar `res_3' = 0
    }

    tempname niter_1
    scalar `niter_1' = 0
    tempname niter_2
    scalar `niter_2' = 0
    tempname niter_3
    scalar `niter_3' = 0
    
    timer clear 99
    timer on 99
    plugin call mixregls `allvars' `samp_if' `samp_in', "`mvarsfields'" "`bvarsfields'" "`wvarsfields'" "`PNINT'" "`RNINT'" "`SNINT'" "`CONV'" "`NQ'" "`AQUAD'" "`MAXIT'" "`STD'" "`NCOV'" "`RIDGEIN'" "`MLS'" "`nobs'" "`N_g'" "`g_min'" "`g_avg'" "`g_max'" "`dev_1'" "`b_1'" "`V_1'" "`re_1'" "`res_1'" "`niter_1'" "`dev_2'" "`b_2'" "`V_2'" "`re_2'" "`res_2'" "`niter_2'" "`dev_3'" "`b_3'" "`V_3'" "`re_3'" "`res_3'" "`niter_3'"
    timer off 99
    quietly timer list
    local time = r(t99)
    timer clear 99

    if ("`reffects'"~="") {
      quietly generate `reffect_1_se' = sqrt(`reffect_1_var')
      label var `reffect_1_se' "EB std. location r.e. std. err."
      quietly generate `reffect_2_se' = sqrt(`reffect_2_var')
      label var `reffect_2_se' "EB std. scale r.e. std. err."
    }

    ****************************************************************************
    * (5) RETRIEVE MODEL ESTIMATES
    ****************************************************************************

    /* turn off permutation for now as this gets complicated for R terms
     * for example 3x3 requires
     * 0 0 0 0 0 1
     * 0 0 0 1 0 0
     * 1 0 0 0 0 0
     * 0 0 0 0 1 0
     * 0 1 0 0 0 0
     * 0 0 1 0 0 0

    tempname perm1
    tempname perm2
    tempname perm3
    matrix `perm1' = J(`k_1', `k_1', 0)
    matrix `perm2' = J(`k_2', `k_2', 0)
    matrix `perm3' = J(`k_3', `k_3', 0)
    local i = 1
    if `PNINT' == 0 {
      matrix `perm1'[1, `P' + 1] = 1
      matrix `perm2'[1, `P' + 1] = 1
      matrix `perm3'[1, `P' + 1] = 1
      local ++i
    }
    forvalues j = 1/`P' {
      matrix `perm1'[`i', `j'] = 1
      matrix `perm2'[`i', `j'] = 1
      matrix `perm3'[`i', `j'] = 1
      local ++i
    }
    if `RNINT' == 0 {
      matrix `perm1'[`i', `PINCINT' + `R' + 1] = 1
      matrix `perm2'[`i', `PINCINT' + `R' + 1] = 1
      matrix `perm3'[`i', `PINCINT' + `R' + 1] = 1
      local ++i
    }
    forvalues j = `=`PINCINT' + 1'/`=`PINCINT' + `R'' {
      matrix `perm1'[`i', `j'] = 1
      matrix `perm2'[`i', `j'] = 1
      matrix `perm3'[`i', `j'] = 1
      local ++i
    }
    matrix `perm1'[`i', `PINCINT' + `RINCINT' + 1] = 1
    if `SNINT' == 0 {
      matrix `perm2'[`i', `PINCINT' + `RINCINT' + `S' + 1] = 1
      matrix `perm3'[`i', `PINCINT' + `RINCINT' + `S' + 1] = 1
      local ++i
    }
    forvalues j = `=`PINCINT' + `RINCINT' + 1'/`=`PINCINT' + `RINCINT' + `S'' {
      matrix `perm2'[`i', `j'] = 1
      matrix `perm3'[`i', `j'] = 1
      local ++i
    }

    forvalues j = `=`PINCINT' + `RINCINT' + `SINCINT' + 1'/`=`PINCINT' + `RINCINT' + `SINCINT' + `nassoc'' {
      matrix `perm3'[`i', `j'] = 1
      local ++i
    }

    matrix `perm3'[`i', `PINCINT' + `RINCINT'  + `SINCINT' + `nassoc' + 1] = 1

    matrix `b_1' = `b_1' * `perm1'
    matrix `b_2' = `b_2' * `perm2'
    matrix `b_3' = `b_3' * `perm3'

    matrix `V_1' = `perm1'' * `V_1' * `perm1'
    matrix `V_2' = `perm2'' * `V_2' * `perm2'
    matrix `V_3' = `perm3'' * `V_3' * `perm3'

    */

    matrix colnames `b_1' = `names_1'
    matrix rownames `b_1' = y1
    matrix coleq `b_1' = `eqnames_1'

    matrix rownames `V_1' = `names_1'
    matrix roweq `V_1' = `eqnames_1'
    matrix colnames `V_1' = `names_1'
    matrix coleq `V_1' = `eqnames_1'

    matrix colnames `b_2' = `names_2'
    matrix rownames `b_2' = y1
    matrix coleq `b_2' = `eqnames_2'

    matrix rownames `V_2' = `names_2'
    matrix roweq `V_2' = `eqnames_2'
    matrix colnames `V_2' = `names_2'
    matrix coleq `V_2' = `eqnames_2'

    matrix colnames `b_3' = `names_3'
    matrix rownames `b_3' = y1
    matrix coleq `b_3' = `eqnames_3'

    matrix rownames `V_3' = `names_3'
    matrix roweq `V_3' = `eqnames_3'
    matrix colnames `V_3' = `names_3'
    matrix coleq `V_3' = `eqnames_3'

    *****************************************************************************
    * CALCULATE RESIDUALS IF THESE HAVE BEEN REQUESTED AND NOT ALREADY CALCULATED
    *****************************************************************************
    capture assert `residuals' == . | `residuals' == 0
    if (_rc == 0) { // Residuals were not returned from plugin
      local noresi = 1
    }
    else {
      local noresi = 0
    }

    if ("`bgvariancexb'" ~= "") {
      quietly generate `bgvariancexb' = 0
      foreach var of local bnames {
        if ("`var'" == "_cons") {
          quietly replace `bgvariancexb' = `bgvariancexb' + `b_3'[1, "Between:_cons"]
        }
        else {
          quietly replace `bgvariancexb' = `bgvariancexb' + `b_3'[1, "Between:`var'"]*`var'
        }
      }
      label var `bgvariancexb' "BG var. fun.: Linear prediction"
    }

    if ("`bgvariancefitted'" ~= "") {
      quietly generate `bgvariancefitted' = exp(`bgvariancexb')
      label var `bgvariancefitted' "BG var. fun.: Exp. linear prediction"
    }

    if ("`reunstandard'" ~= "") {
      quietly generate `reunstandard_1_b' = sqrt(`bgvariancefitted')*`reffect_1_b'
      label var `reunstandard_1_b' "EB unstd. location r.e."
      if (`ncov' == 0) {
        quietly generate `reunstandard_2_b' = `b_3'[1, "Scale:sigma"]*`reffect_2_b'
      }
      if (`ncov' == 1) {
        quietly generate `reunstandard_2_b' = `b_3'[1, "Association:linear"]*`reffect_1_b' + `b_3'[1, "Scale:sigma"]*`reffect_2_b'
      }
      if (`ncov' == 2) {
        quietly generate `reunstandard_2_b' = `b_3'[1, "Association:linear"]*`reffect_1_b' + `b_3'[1, "Association:quadratic"]*`reffect_1_b'*`reffect_1_b' + `b_3'[1, "Scale:sigma"]*`reffect_2_b'
      }
      label var `reunstandard_2_b' "EB unstd. scale r.e."

      tempname cov
      matrix `cov' = (`=exp(`b_3'[1, "Between:_cons"])', 0\0, `=`b_3'[1, "Scale:sigma"]^2')
      tempname chol
      matrix `chol' = cholesky(`cov')
      quietly generate `reunstandard_1_var' = `reffect_1_var'*`chol'[1, 1]*`chol'[1, 1]
      label var `reunstandard_1_var' "EB unstd. location r.e. sampling variance"

      quietly generate `reunstandard_1_2_cov' = `reffect_1_var'*`chol'[1, 1]*`chol'[2, 1] + `reffect_1_2_cov'*`chol'[1, 1]*`chol'[2, 2]
      label var `reunstandard_1_2_cov' "EB unstd. scale location r.e. sampling covariance"

      quietly generate `reunstandard_2_var' = `reffect_1_var'*`chol'[2, 1]*`chol'[2, 1] + `reffect_1_2_cov'*`chol'[2, 1]*`chol'[2, 2] + `reffect_1_2_cov'*`chol'[2, 1]*`chol'[2, 2] + `reffect_2_var'*`chol'[2, 2]*`chol'[2, 2]
      label var `reunstandard_2_var' "EB unstd. scale r.e. sampling variance"

      quietly generate `reunstandard_1_se' = sqrt(`reunstandard_1_var')
      label var `reunstandard_1_se' "EB unstd. location r.e. std. err."

      quietly generate `reunstandard_2_se' = sqrt(`reunstandard_2_var')
      label var `reunstandard_2_se' "EB unstd. scale r.e. std. err."
    }

    if ("`wgvariancexb'" ~= "") {
      quietly generate `wgvariancexb' = 0
      foreach var of local wnames {
        if ("`var'" == "_cons") {
          quietly replace `wgvariancexb' = `wgvariancexb' + `b_3'[1, "Within:_cons"]
        }
        else {
          quietly replace `wgvariancexb' = `wgvariancexb' + `b_3'[1, "Within:`var'"]*`var'
        }
      }
      label var `wgvariancexb' "WG var. fun.: Linear prediction, fixed portion only"
    }

    if ("`wgvarianceeta'" ~= "") {
      quietly generate `wgvarianceeta' = `wgvariancexb' + `reunstandard_2_b'
      label var `wgvarianceeta' "WG var. fun.: Linear prediction"
    }

    if ("`wgvariancefitted'" ~= "") {
      quietly generate `wgvariancefitted' = exp(`wgvarianceeta')
      label var `wgvariancefitted' "WG var. fun.: Exp. Linear prediction"
    }

    if ("`meanxb'" ~= "") {
      quietly generate `meanxb' = 0
      foreach var of local mnames {
        if ("`var'" == "_cons") {
          quietly replace `meanxb' = `meanxb' + `b_3'[1, "Mean:_cons"]
        }
        else {
          quietly replace `meanxb' = `meanxb' + `b_3'[1, "Mean:`var'"]*`var'
        }
      }
      label var `meanxb' "Mean fun.: Linear prediction, fixed portion only"
    }

    if ("`meanfitted'" ~= "") {
      quietly generate `meanfitted' = `meanxb' + `reunstandard_1_b'
      label var `meanfitted' "Mean fun.: Linear prediction"
    }

    if ("`runstandard'" ~= "") {
      quietly generate `runstandard' = (`response'- `meanfitted')
      label var `runstandard' "Unstandardized residuals"
    }

    if ("`residuals'" ~= "") {
      if (`noresi' == 1) {
        quietly replace `residuals' = `runstandard' / sqrt(`wgvariancefitted')
      }
    }

    **************************************
    * LOG-LIKELIHOODS AND ITERATIONS
    **************************************

    * Model 1 ll
    local ll_1 = -0.5*`dev_1'

    * Model 2 ll
    local ll_2 = -0.5*`dev_2'

    * Model 3 ll
    local ll_3 = -0.5*`dev_3'

    ****************************************************************************
    * ERETURNS
    ****************************************************************************

    **************************************
    * ERETURN ESTIMATES
    **************************************
    tempname b V
    matrix `b' = `b_3'
    matrix `V' = `V_3'

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

    ereturn scalar k   = `k_3'
    ereturn scalar k_1 = `k_1'
    ereturn scalar k_2 = `k_2'
    ereturn scalar k_3 = `k_3'

    ereturn scalar time = `time'

    ereturn scalar ll   = `ll_3'
    ereturn scalar ll_1 = `ll_1'
    if `niter_2' == 0 {
      ereturn scalar ll_2 = `ll_1'
    }
    else {
      ereturn scalar ll_2 = `ll_2'
    }
    ereturn scalar ll_3 = `ll_3'
    
    ereturn scalar deviance   = -2*e(ll)
    ereturn scalar deviance_1 = -2*e(ll_1)
    ereturn scalar deviance_2 = -2*e(ll_2)
    ereturn scalar deviance_3 = -2*e(ll_3)

    ereturn scalar iterations   = `niter_1' + `niter_2' + `niter_3'
    ereturn scalar iterations_1 = `niter_1' 
    if `niter_2' == 0 {
      ereturn scalar iterations_2 = `niter_1'
    }
    else {
      ereturn scalar iterations_2 = `niter_2'
    }
    ereturn scalar iterations_3 = `niter_3'

    ereturn scalar chi2_1vs2 =  -2*(e(ll_1) - e(ll_2))
    ereturn scalar chi2_1vs3 =  -2*(e(ll_1) - e(ll_3))
    ereturn scalar chi2_2vs3 =  -2*(e(ll_2) - e(ll_3))

    ereturn scalar p_1vs2 =  chi2tail(`=`k_2' - `k_1'',e(chi2_1vs2)) 
    ereturn scalar p_1vs3 =  chi2tail(`=`k_3' - `k_1'',e(chi2_1vs3)) 
    ereturn scalar p_2vs3 =  chi2tail(`=`k_3' - `k_2'',e(chi2_2vs3))



    **************************************
    * ERETURN LOCALS
    **************************************

    ereturn local standardize = ("`standardize'"~="")
    ereturn local tolerance = `tolerance'
    ereturn local ridgein = `ridgein'
    ereturn local iterate = `iterate'
    ereturn local n_quad = `intpoints'
    ereturn local adapt = ("`adapt'"=="")
    ereturn local ivar "`id'"
    ereturn local depvar "`response'"
    ereturn local title "Mixed-effects location scale model"
    ereturn local cmdline `e(cmd)' `runmixregls_cmdline'
    ereturn local cmd "runmixregls"



    **************************************
    * ERETURN MATRICES
    **************************************

    ereturn matrix V_3 = `V_3'
    if `niter_2' == 0 {
      matrix `V_2' = `V_1'
    }
    ereturn matrix V_2 = `V_2'
    ereturn matrix V_1 = `V_1'

    ereturn matrix b_3 = `b_3'
    if `niter_2' == 0 {
      matrix `b_2' = `b_1'
    }
    ereturn matrix b_2 = `b_2'
    ereturn matrix b_1 = `b_1'


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
    display as txt "runmixregls - Run MIXREGLS from within Stata" _n

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
    _col(1)  as txt "Integration points =" _col(22) as res %10.0g `e(n_quad)'
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

    #delimit ;

    display
    _col(1)  as txt "LR test Stage 1 vs. Stage 2 model: chi2(" e(k_2) - e(k_1) ") = " as res %8.2f e(chi2_1vs2) as txt " Prob >= chi2 = " as res %5.4f e(p_1vs2)
        ;

    display
    _col(1)  as txt "LR test Stage 1 vs. Stage 3 model: chi2(" e(k_3) - e(k_1) ") = " as res %8.2f e(chi2_1vs3) as txt " Prob >= chi2 = " as res %5.4f e(p_1vs3)
        ;

    display
    _col(1)  as txt "LR test Stage 2 vs. Stage 3 model: chi2(" e(k_3) - e(k_2) ") = " as res %8.2f e(chi2_2vs3) as txt " Prob >= chi2 = " as res %5.4f e(p_2vs3)
        ;

    #delimit cr
  } 

end

program mixregls, plugin

********************************************************************************
exit
