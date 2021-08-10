*! runmixregls.ado, George Leckie, 27Jun2016
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
  syntax varlist(min=1 numeric fv) [if] [in] [, ///
      noConstant ///
      Between(string) ///
      Within(string) ///
      Association(name) ///
      ///
      reffects(namelist min=2 max=2) ///
      residuals(namelist min=1 max=1) ///
      ///
      noADAPT ///
      INTPoints(numlist >0 integer min=1 max=1) ///
      ///
      iterate(numlist >0 integer min=1 max=1) ///
      TOLerance(numlist >0 min=1 max=1) /// 
      STANDardize ///
      ///
      mixreglspath(string) ///
      ///
      TYPEDATfile ///
      TYPEDEFfile ///
      TYPEOUTfile ///
      VIEWDATfile /// undocumented option
      VIEWDEFfile /// undocumented option
      VIEWOUTfile /// undocumented option
      SAVEDATfile(string) /// undocumented option - currently only works if you specify a full file path
      SAVEDEFfile(string) ///
      SAVEOUTfile(string) ///
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
    
    * Preserve the data
    preserve

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
    
    * Parse reffects and reses
    if ("`reffects'"~="") {
      confirm new variable `reffects'
      tokenize `reffects'
      local reffect_1_b "`1'"
      local reffect_2_b "`2'"
      local reffect_1_se "`1'_se"
      local reffect_2_se "`2'_se"
    }

    * Parse residuals
    if ("`residuals'"~="") {
      confirm new variable `residuals'
    }

    * Parse estimation options
    if ("`iterate'"=="") local iterate = 200
    if ("`tolerance'"=="") local tolerance = 0.0005
    if ("`intpoints'"=="") local intpoints = 11

    * Parse MIXREGLS path
    if ("$mixreglspath"=="" & "`mixreglspath'"=="") {
      display as error "specify the full path for mixreglsb.exe using mixreglspath() or, preferably, by specifying a global named mixreglspath"
      exit 198      
    }
    if ("$mixreglspath"~="") local temp $mixreglspath
    if ("`mixreglspath'"~="") local temp `mixreglspath'
    local mixreglspath `temp'
    confirm file "`mixreglspath'"
    local mixreglspath = subinstr("`mixreglspath'","\","/",.)
    confirm file "`mixreglspath'"

    * Work out MIXREGLS dir and MIXREGLS exe
    local temp = max(strpos(reverse("`mixreglspath'"),"\"),strpos(reverse("`mixreglspath'"),"/"))
    local mixreglsdir = reverse(substr(reverse("`mixreglspath'"),`temp' + 1,.))
    local mixreglsexe = substr("`mixreglspath'",-`temp' + 1,.)


    * Create a temporary directory for the current MIXREGLS run (to aide running multiple instances of MIXREGLS)
    quietly {
      local pwd = c(pwd)
      cd "`c(tmpdir)'"
      tempfile temp1
      capture mkdir "`temp1'"
      cd "`temp1'"
      local mixreglstempdir = c(pwd)
      capture erase "`mixreglsexe'"
      capture erase "MIXREGLS.def"
      capture erase "MIXREGLS.ITS"
      capture erase "MIXREGLS.EST"
      capture erase "MIXREGLS.VAR"
      capture erase "MIXREGLS.RE1"
      capture erase "MIXREGLS.RE2"
      copy "`mixreglsdir'/`mixreglsexe'" "`mixreglsexe'"
      cd "`pwd'"
    }

    * Parse savedatfile (MIXREGLS data file)
    if ("`savedatfile'"~="") {
      local 0 `savedatfile'
      syntax anything(name=datfile), [REPLACE]
      tokenize `datfile', parse(".")
      if ("`2'`3'"=="") local datfile `datfile'.dat
      if ("`replace'"=="") confirm new file `datfile'
      if ("`replace'"~="") capture erase "`datfile'"
    }
    else { // if user hasn't specified filename then save as a temporary file
      tempfile datfile
    }
    
    * Parse savedeffile (MIXREGLS definition file)
    if ("`savedeffile'"~="") {
      local 0 `savedeffile'
      syntax anything(name=deffile), [REPLACE]
      tokenize `deffile', parse(".")
      if ("`2'`3'"=="") local deffile `deffile'.def
      if ("`replace'"=="") confirm new file `deffile'
      if ("`replace'"~="") capture erase "`deffile'"
    }
    else { // if user hasn't specified filename then save as a temporary file
      tempfile deffile
    } 

    * Parse saveoutfile (MIXREGLS output file)
    if ("`saveoutfile'"~="") {
      local 0 `saveoutfile'
      syntax anything(name=outfile), [REPLACE]
      tokenize `outfile', parse(".")
      if ("`2'`3'"=="") local outfile `outfile'.out
      if ("`replace'"=="") confirm new file `outfile'
      if ("`replace'"~="") capture erase "`outfile'"
    }
    else { // if user hasn't specified filename then save as a temporary file
      tempfile outfile
    }
    
    * Create temporary MIXREGLS user files
    tempfile dtafile
    tempfile outfileprepped

    * Create temporary Stata datasets
    tempfile reffectsdta
    tempfile residualsdta

    * Work out b and V row and column names
    if ("`mcons'"=="") local mnames "`mvars' _cons"
    if ("`mcons'"=="noconstant") local mnames "`mvars'"
    
    if ("`bcons'"=="") local bnames "`bvars' _cons"
    if ("`bcons'"=="noconstant") local bnames "`bvars'"
    
    if ("`wcons'"=="") local wnames "`wvars' _cons"
    if ("`wcons'"=="noconstant") local wnames "`wvars'"
    
    if ("`association'"=="") local anames "linear"
    if ("`association'"~="") {
      local 0, `association'
      syntax, [None Linear Quadratic]
      if ("`none'"~="") local anames
      if ("`linear'"~="") local anames "_linear"
      if ("`quadratic'"~="") local anames "linear quadratic"
    }
    
    local sname "sigma"
    
    local names_1 "`mnames' `bnames' _cons"
    local names_2 "`mnames' `bnames' `wnames'"
    local names_3 "`mnames' `bnames' `wnames' `anames' `sname'"



    ****************************************************************************
    * (1) SAVE DAT FILE
    ****************************************************************************
    quietly {


      * Order the variables into their natural ordering
      order `allvars'
      
      * Generate a unique sort index
      generate _sortindex = _n
      
      * Keep estimation sample only
      keep if `touse'

      * Check that there are two or more observations
      count
      if r(N)==0 {
        display as error "no observations"
        exit 198
      }
      if r(N)==1 {
        display as error "insufficient observations"
        exit 198
      }


      * Sort the data according to the data hierarchy
      sort `id' _sortindex
      
      * Generate the observation number in the esample
      generate _obs = _n
      label var _obs "Observation number in esample"
      
      * Outfile the data to a Stata dataset
      compress
      save "`dtafile'", replace

      * Outfile only those variables required by MIXREGLS to a MIXREGLS dat file
      outfile `allvars' using "`datfile'", replace nolabel wide


      * Calculate group statistics
      keep `id'
      local nobs = _N
      tempvar n
      bysort `id': generate `n' = _N
      bysort `id': keep if _n==1
      isid `id'
      local N_g = _N
      sum `n'
      local g_min = r(min) 
      local g_avg = r(mean) 
      local g_max = r(max)
      
    }

    * Type the datfile to the results window
    if ("`typedatfile'"~="") {
      display as txt "{hline 78}
      display _col(`=0.5*(78 - length("MIXREGLS model data file"))') as txt "MIXREGLS model data file"
      display as txt "{hline 78}
      type "`datfile'"
    }

    * View the datfile in the viewer (undocumented option)
    if ("`viewdatfile'"~="") {
      view "`datfile'"
    }
    
    
    
    ****************************************************************************
    * (2) PREPARE INPUTS FOR THE MIXREGLS DEFINITION FILE
    ****************************************************************************
  
    * Line 6
    local NVAR = wordcount("`allvars'")     // Number of variables in the dataset
    local P = wordcount("`mvars'")        // Mean model
    local R = wordcount("`bvars'")        // BS model
    local S = wordcount("`wvars'")        // WS model
    local PNINT = ("`mcons'"=="noconstant")   // Mean model
    local RNINT = ("`bcons'"=="noconstant")   // BS model
    local SNINT = ("`wcons'"=="noconstant")   // WS model
    local CONV = `tolerance'          // Tolerance
    local NQ = `intpoints'            // Number of integration points
    local AQUAD = ("`adapt'"=="")       // Adaptive quadrature
    local MAXIT = `iterate'           // Maximum number of iterations
    local MISS = 0                // Missing data in estimation sample
    local STD = ("`standardize'"~="")     // Standardize all variables
    local NCOV = `ncov'             // Association between log WS variance and random-location effect

    * Work out number of parameters in each equation
    local PINCINT = `P' + 1 - `PNINT'       // Mean model
    local RINCINT = `R' + 1 - `RNINT'       // BS model
    local SINCINT = `S' + 1 - `SNINT'       // WS model

    * Work out total number of parameters in the model
    local k_1 = `PINCINT' + `RINCINT' + 1
    local k_2 = `PINCINT' + `RINCINT' + `SINCINT' 
    local k_3 = `PINCINT' + `RINCINT' + `SINCINT' + `NCOV' + 1

    * Work out where the equations start, stage 2
    local eq1start_1 = 1
    local eq2start_1 = `PINCINT' + 1
    local eq3start_1 = `PINCINT' + `RINCINT' + 1

    local eq1end_1 = `eq2start_1' - 1
    local eq2end_1 = `eq3start_1' - 1
    local eq3end_1 = `eq3start_1' + 0
      
    * Work out where the equations start, stage 2
    local eq1start_2 = 1
    local eq2start_2 = `PINCINT' + 1
    local eq3start_2 = `PINCINT' + `RINCINT' + 1

    local eq1end_2 = `eq2start_2' - 1
    local eq2end_2 = `eq3start_2' - 1
    local eq3end_2 = `eq3start_2' + `SINCINT'

    * Work out where the equations start, stage 3
    local eq1start_3 = 1
    local eq2start_3 = `PINCINT' + 1
    local eq3start_3 = `PINCINT' + `RINCINT' + 1
    local eq4start_3 = `PINCINT' + `RINCINT' + `SINCINT' + 1
    local eq5start_3 = `PINCINT' + `RINCINT' + `SINCINT' + `NCOV' +  1
    local eq1end_3 = `eq2start_3' - 1
    local eq2end_3 = `eq3start_3' - 1
    local eq3end_3 = `eq4start_3' - 1
    local eq4end_3 = `eq5start_3' - 1
    local eq5end_3 = `eq5start_3' + 0
    
    * Line 8
    local mvarsfields ""    
    forvalues v = 3/`=`P'+2' {
      local mvarsfields "`mvarsfields'`v' "     
    }
    
    * Line 9
    local bvarsfields ""    
    foreach var1 of local bvars {
      local v = 1
      foreach var2 of local allvars {
        if "`var1'"=="`var2'" {
          local bvarsfields "`bvarsfields'`v' "         
        }
        local v = `v' + 1
      }
    }

    * Line 10
    local wvarsfields ""    
    foreach var1 of local wvars {
      local v = 1
      foreach var2 of local allvars {
        if "`var1'"=="`var2'" {
          local wvarsfields "`wvarsfields'`v' "           
        }
        local v = `v' + 1
      }
    }


    * Line 8
    local responselabel "%-8s ("`response'")"

    * Line 12
    local mvarlabels
    foreach var of local mvars {
      local mvarlabels "`mvarlabels'%-8s (abbrev("`var'",8)) "
    }
      
    * Line 13
    local bvarlabels
    foreach var of local bvars {
      local bvarlabels "`bvarlabels'%-8s (abbrev("`var'",8)) "
    }

    * Line 14
    local wvarlabels
    foreach var of local wvars {
      local wvarlabels "`wvarlabels'%-8s (abbrev("`var'",8)) "
    }



    ****************************************************************************
    * (3) WRITE MIXREGLS DEFINITION FILE
    ****************************************************************************
    tempfile newdeffile
    tempname deffilehandle
    capture file close `deffilehandle'
    quietly file open `deffilehandle' using "`deffile'", write
      file write `deffilehandle' "MIXREGLS mixed-effects location scale model definition file " _n    // Line 1 - Title
      file write `deffilehandle' "File generated from within Stata using the runmixregls command" _n          // Line 2 - Subtitle
      file write `deffilehandle' "`datfile'" _n                             // Line 3 - Input data file (must be full file name if file not in MIXREGLS directory)
      file write `deffilehandle' "`outfile'" _n                             // Line 4 - Main output file 
      file write `deffilehandle' "`newdeffile'" _n                            // Line 5 - Definition file (still to be created)
      file write `deffilehandle' "`NVAR' `P' `R' `S' `PNINT' `RNINT' `SNINT' `CONV' `NQ' `AQUAD' `MAXIT' `MISS' `STD' `NCOV'" _n
      file write `deffilehandle' "1 2" _n                                 // Line 7
      file write `deffilehandle' "`mvarsfields'" _n                           // Line 8
      file write `deffilehandle' "`bvarsfields'" _n                         // Line 9
      file write `deffilehandle' "`wvarsfields'" _n                         // Line 10
      file write `deffilehandle' `responselabel' _n                         // Line 11
      file write `deffilehandle' `mvarlabels' _n                            // Line 12
      file write `deffilehandle' `bvarlabels' _n                            // Line 13
      file write `deffilehandle' `wvarlabels' _n                            // Line 14
    file close `deffilehandle'
    confirm file "`deffile'"
    
    * Copy the deffile to the MIXREGLS directory and name it MIXREGLS.DEF
    copy "`deffile'" "`mixreglstempdir'\MIXREGLS.def"
    confirm file "`mixreglstempdir'\MIXREGLS.def"
    
    
    * Type the deffile to the results window
    if ("`typedeffile'"~="") {
      display as txt "{hline 78}
      display _col(`=0.5*(78 - length("MIXREGLS model definition file"))') as txt "MIXREGLS model definition file"
      display as txt "{hline 78}
      type "`deffile'"
    }

    * View the deffile in the viewer (undocumented option)
    if ("`viewdeffile'"~="") {
      view "`deffile'"
    }

    
    ****************************************************************************
    * (4) RUN MODEL
    ****************************************************************************
    quietly cd "`mixreglstempdir'"
    timer clear 99
    timer on 99
//    shell "C:\Windows\System32\cmd.exe" /C "`mixreglsexe'"
    shell "`mixreglsexe'"
    timer off 99
    quietly timer list
    local time = r(t99)
    timer clear 99
    quietly cd "`pwd'"
    
    * Erase the MIXREGLS.exe file
    erase "`mixreglstempdir'/`mixreglsexe'"

    * Erase the MIXREGLS.def file
    capture erase "`mixreglstempdir'\MIXREGLS.def"

    * Erase the MIXREGLS.its file
    capture erase "`mixreglstempdir'\MIXREGLS.ITS"

    * Confirm that the two files which should be created by MIXREGLS are indeed created by MIXREGLS
    confirm file "`outfile'"
    confirm file "`newdeffile'"
    
    * Search for error messages
    quietly {
      infix str all 1-76 using "`outfile'", clear
      generate error = (regexm(all,"NaN"))
      sum error
      assert inlist(r(max),0,1)
      local converged = 1 - r(max)
    }
    * Type the outfile to the results window
    if ("`typeoutfile'"~="" | `converged'==0) {
      display as txt "{hline 78}
      display _col(`=0.5*(78 - length("MIXREGLS model output file"))') as txt "MIXREGLS model output file"
      display as txt "{hline 78}
      type "`outfile'"
      display as txt "{hline 78}
    }

    * View the outfile in the viewer (undocumented option)
    if ("`viewoutfile'"~="") {
      view "`outfile'"
    }


    if (`converged'==0) {
      display as error "MIXREGLS failed to converge, examine the MIXREGLS model output file"
      exit 198
    }

    

    ****************************************************************************
    * (5) RETRIEVE MODEL ESTIMATES
    ****************************************************************************

    quietly {

      ****************************************************************************
      * IMPORT MIXREGLS.EST
      ****************************************************************************
      * Uncomment for debugging
      * local mixreglstempdir "C:\Users\gl9158\MIXREGLS\"
      ****************************************************************************

      * Work out line starts and line ends for each model
      infix str all 1-76 using "`mixreglstempdir'\MIXREGLS.EST", clear
      generate atomicid = _n
      generate temp = (substr(all,-9,1)!=" " & substr(all,-8,1)==" " & substr(all,-1,1)!=" ") // This is a fudge. Trying to find the first line of each set of model output. 
      generate model = sum(temp)
      sum model
      local models = r(max)
      assert inrange(`models',2,3)

      generate row = atomicid if temp==1
      local N = _N
      keep if row<.

      local linestart1 = 1
      local lineend3 = `N'

      * Models 1 and 2 are identical when no WS variance covariates are specified
      if (`models'==2) {
        assert _N==2
        local linestart2 = row[1]
        local linestart3 = row[2]
        local lineend1 = `linestart3' - 1
        local lineend2 = `linestart3' - 1
      } 
      if (`models'==3) {
        assert _N==3
        local linestart2 = row[2]
        local linestart3 = row[3]
        local lineend1 = `linestart2' - 1
        local lineend2 = `linestart3' - 1
      }



      **************************************
      * LOG-LIKELIHOODS AND ITERATIONS
      **************************************
      * Uncomment for debugging
      * local mixreglstempdir "C:\Users\gl9158\MIXREGLS\"
      **************************************

      * Model 1 ll and # iterations
      infix deviance 1-15 iterations 16-23 iterate 24-31 in `linestart1' using "`mixreglstempdir'\MIXREGLS.EST", clear
      local ll_1 = -0.5*deviance[1]
      local cumiterations_1 = iterations[1]

      * Model 2 ll and # iterations
      infix deviance 1-15 iterations 16-23 iterate 24-31 in `linestart2' using "`mixreglstempdir'\MIXREGLS.EST", clear
      local ll_2 = -0.5*deviance[1]
      local cumiterations_2 = iterations[1]

      * Model 3 ll and # iterations
      infix deviance 1-15 iterations 16-23 iterate 24-31 in `linestart3' using "`mixreglstempdir'\MIXREGLS.EST", clear
      local ll_3 = -0.5*deviance[1]
      local cumiterations_3 = iterations[1]


      **************************************
      * Model 1 parameter estimates
      **************************************
      infix v1 5-15 v2 20-30 v3 35-45 v4 50-60 v5 65-75 in `=`linestart1'+1'/`lineend1' using "`mixreglstempdir'\MIXREGLS.EST", clear
      generate row = _n
      reshape long v, i(row) j(column)
      drop if v==.
      generate atomicid = _n
      assert _N==`=2*`k_1''
      generate bv = 1 + (_n>=`=`k_1'+1')
      keep if bv==1
      drop bv

      * Generate the equation number
      generate eqnumber = .
      replace eqnumber = 1 if inrange(_n,`eq1start_1',`eq1end_1')
      replace eqnumber = 2 if inrange(_n,`eq2start_1',`eq2end_1')
      replace eqnumber = 3 if inrange(_n,`eq3start_1',`eq3end_1')

      * Generate the equation label
      generate eqlabel = ""
      replace eqlabel = "Mean"        if eqnumber==1
      replace eqlabel = "Between"     if eqnumber==2
      replace eqlabel = "Within"      if eqnumber==3
      replace eqlabel = "Association" if eqnumber==4
      replace eqlabel = "Scale"       if eqnumber==5

* Recode b to put _cons at the end of each equation
generate newrow = atomicid
if ("`mcons'"=="")  recode newrow (`eq1start_1' = `=`eq1end_1' + .5')
if ("`bcons'"=="")  recode newrow (`eq2start_1' = `=`eq2end_1' + .5')
if ("`wcons'"=="")  recode newrow (`eq3start_1' = `=`eq3end_1' + .5')
sort newrow

      * b matrix
      tempname b_1
      mkmat v, matrix(`b_1') roweq(eqlabel)
      matrix rownames `b_1' = `names_1'
      matrix colnames `b_1' = y1
      matrix `b_1' = `b_1''



      **************************************
      * Model 2 parameter estimates
      **************************************
      infix v1 5-15 v2 20-30 v3 35-45 v4 50-60 v5 65-75 in `=`linestart2'+1'/`lineend2' using "`mixreglstempdir'\MIXREGLS.EST", clear
      generate row = _n
      reshape long v, i(row) j(column)
      drop if v==.
      generate atomicid = _n
      assert _N==`=2*`k_2''
      generate bv = 1 + (_n>=`=`k_2'+1')
      keep if bv==1
      drop bv

      * Generate the equation number
      generate eqnumber = .
      replace eqnumber = 1 if inrange(_n,`eq1start_2',`eq1end_2')
      replace eqnumber = 2 if inrange(_n,`eq2start_2',`eq2end_2')
      replace eqnumber = 3 if inrange(_n,`eq3start_2',`eq3end_2')

      * Generate the equation label
      generate eqlabel = ""
      replace eqlabel = "Mean"        if eqnumber==1
      replace eqlabel = "Between"     if eqnumber==2
      replace eqlabel = "Within"      if eqnumber==3
      replace eqlabel = "Association" if eqnumber==4
      replace eqlabel = "Scale"       if eqnumber==5

* Recode b to put _cons at the end of each equation
generate newrow = atomicid
if ("`mcons'"=="")  recode newrow (`eq1start_2' = `=`eq1end_2' + .5')
if ("`bcons'"=="")  recode newrow (`eq2start_2' = `=`eq2end_2' + .5')
if ("`wcons'"=="")  recode newrow (`eq3start_2' = `=`eq3end_2' + .5')
sort newrow

      * b matrix
      tempname b_2
      mkmat v, matrix(`b_2') roweq(eqlabel)
      matrix rownames `b_2' = `names_2'
      matrix colnames `b_2' = y1
      matrix `b_2' = `b_2''


      **************************************
      * Model 3 parameter estimates
      **************************************
      infix v1 5-15 v2 20-30 v3 35-45 v4 50-60 v5 65-75 in `=`linestart3'+1'/`lineend3' using "`mixreglstempdir'\MIXREGLS.EST", clear
      generate row = _n
      reshape long v, i(row) j(column)
      drop if v==.
      generate atomicid = _n
      assert _N==`=2*`k_3''
      generate bv = 1 + (_n>=`=`k_3'+1')
      keep if bv==1
      drop bv

      * Generate the equation number
      generate eqnumber = .
      replace eqnumber = 1 if inrange(_n,`eq1start_3',`eq1end_3')
      replace eqnumber = 2 if inrange(_n,`eq2start_3',`eq2end_3')
      replace eqnumber = 3 if inrange(_n,`eq3start_3',`eq3end_3')
      replace eqnumber = 4 if inrange(_n,`eq4start_3',`eq4end_3')
      replace eqnumber = 5 if inrange(_n,`eq5start_3',`eq5end_3')

      * Generate the equation label
      generate eqlabel = ""
      replace eqlabel = "Mean"        if eqnumber==1
      replace eqlabel = "Between"     if eqnumber==2
      replace eqlabel = "Within"      if eqnumber==3
      replace eqlabel = "Association" if eqnumber==4
      replace eqlabel = "Scale"       if eqnumber==5


* Recode b to put _cons at the end of each equation
generate newrow = atomicid
if ("`mcons'"=="")  recode newrow (`eq1start_3' = `=`eq1end_3' + .5')
if ("`bcons'"=="")  recode newrow (`eq2start_3' = `=`eq2end_3' + .5')
if ("`wcons'"=="")  recode newrow (`eq3start_3' = `=`eq3end_3' + .5')
sort newrow

      * b matrix
      tempname b_3
      mkmat v, matrix(`b_3') roweq(eqlabel)
      matrix rownames `b_3' = `names_3'
      matrix colnames `b_3' = y1
      matrix `b_3' = `b_3''

      **************************************
      capture erase "`mixreglstempdir'\MIXREGLS.EST"

    }

    quietly {
    
      
      * Check that the MIXREGLS.VAR exists (if it doesn't then user is likely using an old version of MIXREGLS)
      capture confirm file "`mixreglstempdir'\MIXREGLS.VAR"
      if c(rc)==601 {
        display as error "this version of MIXREGLS does not return the full variance-covariance matrix for the estimators; upgrade to the latest version of MIXREGLS available at https://hedeker-sites.uchicago.edu/sites/hedeker.uchicago.edu/files/uploads/MixregLS_RevisedSept2013.zip;"
        exit 601
      }

      ****************************************************************************
      * IMPORT MIXREGLS.VAR
      ****************************************************************************
      infix str all 1-80 using "`mixreglstempdir'\MIXREGLS.VAR", clear
      generate atomicid = _n
      generate temp = (length(all)==43)
      generate model = sum(temp)
      sum model
      local models = r(max)
      assert inrange(`models',2,3)

      generate row = atomicid if temp==1
      local N = _N
      keep if row<.

      local linestart1 = 1
      local lineend3 = `N'

      * Models 1 and 2 are identical when no WS variance covariates are specified
      if (`models'==2) {
        assert _N==2
        local linestart2 = row[1]
        local linestart3 = row[2]
        local lineend1 = `linestart3' - 1
        local lineend2 = `linestart3' - 1
      } 
      if (`models'==3) {
        assert _N==3
        local linestart2 = row[2]
        local linestart3 = row[3]
        local lineend1 = `linestart2' - 1
        local lineend2 = `linestart3' - 1
      }
      

      **************************************
      * Variance-covariance matrix, stage 1
      **************************************

      * Load the MIXREGLS.VAR file
      infix v1 5-14 v2 18-27 v3 31-40 v4 44-53 v5 57-66 v6 70-79 in `=`linestart1'+1'/`lineend1' using "`mixreglstempdir'\MIXREGLS.VAR", clear
      generate oldrow = _n
      reshape long v, i(oldrow) j(oldcolumn)
      generate atomicid = _n
      drop oldrow oldcol
      drop if v==.
      assert _N==`=`k_1'*`k_1''

      * Generate new row and col numbers
      egen newrow = seq(), from(1) to(`k_1') block(`k_1')
      bysort newrow (atomicid): generate newcol = _n
      isid newrow newcol
      drop atomicid

* Generate the equation number
generate eqnumber = .
replace eqnumber = 1 if inrange(newrow,`eq1start_1',`eq1end_1')
replace eqnumber = 2 if inrange(newrow,`eq2start_1',`eq2end_1')
replace eqnumber = 3 if inrange(newrow,`eq3start_1',`eq3end_1')

* Generate the equation label
generate eqlabel = ""
replace eqlabel = "Mean"        if eqnumber==1
replace eqlabel = "Between"     if eqnumber==2
replace eqlabel = "Within"      if eqnumber==3

* Recode V to put _cons at the end of each equation
if ("`mcons'"=="")  recode newrow newcol (`eq1start_1' = `=`eq1end_1' + .5')
if ("`bcons'"=="")  recode newrow newcol (`eq2start_1' = `=`eq2end_1' + .5')
if ("`wcons'"=="")  recode newrow newcol (`eq3start_1' = `=`eq3end_1' + .5')


* Reshape original data to matrix form
egen newrow2 = group(newrow)
egen newcol2 = group(newcol)
drop newrow newcol
reshape wide v, i(newrow2) j(newcol2)
generate atomicid = _n


      * V matrix
      tempname V_1
      mkmat v*, matrix(`V_1') roweq(eqlabel)
      local eqnames_1 : roweq `V_1'
      matrix coleq `V_1' = `eqnames_1'
      matrix rownames `V_1' = `names_1'
      matrix colnames `V_1' = `names_1'
      
      
      **************************************
      * Var-cov matrix, stage 2
      **************************************

      * Load the MIXREGLS.VAR file
      infix v1 5-14 v2 18-27 v3 31-40 v4 44-53 v5 57-66 v6 70-79 in `=`linestart2'+1'/`lineend2' using "`mixreglstempdir'\MIXREGLS.VAR", clear
      generate oldrow = _n
      reshape long v, i(oldrow) j(oldcolumn)
      generate atomicid = _n
      drop oldrow oldcol
      drop if v==.
      assert _N==`=`k_2'*`k_2''

      * Generate new row and col numbers
      egen newrow = seq(), from(1) to(`k_2') block(`k_2')
      bysort newrow (atomicid): generate newcol = _n
      isid newrow newcol
      drop atomicid
  
* Generate the equation number
generate eqnumber = .
replace eqnumber = 1 if inrange(newrow,`eq1start_2',`eq1end_2')
replace eqnumber = 2 if inrange(newrow,`eq2start_2',`eq2end_2')
replace eqnumber = 3 if inrange(newrow,`eq3start_2',`eq3end_2')

* Generate the equation label
generate eqlabel = ""
replace eqlabel = "Mean"        if eqnumber==1
replace eqlabel = "Between"     if eqnumber==2
replace eqlabel = "Within"      if eqnumber==3

* Recode V to put _cons at the end of each equation
if ("`mcons'"=="")  recode newrow newcol (`eq1start_2' = `=`eq1end_2' + .5')
if ("`bcons'"=="")  recode newrow newcol (`eq2start_2' = `=`eq2end_2' + .5')
if ("`wcons'"=="")  recode newrow newcol (`eq3start_2' = `=`eq3end_2' + .5')

* Reshape original data to matrix form
egen newrow2 = group(newrow)
egen newcol2 = group(newcol)
drop newrow newcol
reshape wide v, i(newrow2) j(newcol2)
generate atomicid = _n

      * V matrix
      tempname V_2
      mkmat v*, matrix(`V_2') roweq(eqlabel)
      local eqnames_2 : roweq `V_2'
      matrix coleq `V_2' = `eqnames_2'
      matrix rownames `V_2' = `names_2'
      matrix colnames `V_2' = `names_2'
      
      
      **************************************
      * Var-cov matrix, stage 3
      **************************************

      * Load the MIXREGLS.VAR file
      infix v1 5-14 v2 18-27 v3 31-40 v4 44-53 v5 57-66 v6 70-79 in `=`linestart3'+1'/`lineend3' using "`mixreglstempdir'\MIXREGLS.VAR", clear
      generate oldrow = _n
      reshape long v, i(oldrow) j(oldcolumn)
      generate atomicid = _n
      drop oldrow oldcol
      drop if v==.
      assert _N==`=`k_3'*`k_3''

      * Generate new row and col numbers
      egen newrow = seq(), from(1) to(`k_3') block(`k_3')
      bysort newrow (atomicid): generate newcol = _n
      isid newrow newcol
      drop atomicid

* Generate the equation number
generate eqnumber = .
replace eqnumber = 1 if inrange(newrow,`eq1start_3',`eq1end_3')
replace eqnumber = 2 if inrange(newrow,`eq2start_3',`eq2end_3')
replace eqnumber = 3 if inrange(newrow,`eq3start_3',`eq3end_3')
replace eqnumber = 4 if inrange(newrow,`eq4start_3',`eq4end_3')
replace eqnumber = 5 if inrange(newrow,`eq5start_3',`eq5end_3')

* Generate the equation label
generate eqlabel = ""
replace eqlabel = "Mean"        if eqnumber==1
replace eqlabel = "Between"     if eqnumber==2
replace eqlabel = "Within"      if eqnumber==3
replace eqlabel = "Association" if eqnumber==4
replace eqlabel = "Scale"       if eqnumber==5

* Recode V to put _cons at the end of each equation
if ("`mcons'"=="")  recode newrow newcol (`eq1start_3' = `=`eq1end_3' + .5')
if ("`bcons'"=="")  recode newrow newcol (`eq2start_3' = `=`eq2end_3' + .5')
if ("`wcons'"=="")  recode newrow newcol (`eq3start_3' = `=`eq3end_3' + .5')

* Reshape original data to matrix form
egen newrow2 = group(newrow)
egen newcol2 = group(newcol)
drop newrow newcol
reshape wide v, i(newrow2) j(newcol2)
generate atomicid = _n

      * V matrix
      tempname V_3
      mkmat v*, matrix(`V_3') roweq(eqlabel)
      local eqnames_3 : roweq `V_3'
      matrix coleq `V_3' = `eqnames_3'
      matrix rownames `V_3' = `names_3'
      matrix colnames `V_3' = `names_3'
      
      capture erase "`mixreglstempdir'\MIXREGLS.VAR"
    }
    
    

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
      type "`mixreglstempdir'\MIXREGLS.VAR"
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
    ereturn scalar ll_2 = `ll_2'
    ereturn scalar ll_3 = `ll_3'
    
    ereturn scalar deviance   = -2*e(ll)
    ereturn scalar deviance_1 = -2*e(ll_1)
    ereturn scalar deviance_2 = -2*e(ll_2)
    ereturn scalar deviance_3 = -2*e(ll_3)

    ereturn scalar iterations   = `cumiterations_3'
    ereturn scalar iterations_1 = `cumiterations_1'
    ereturn scalar iterations_2 = `cumiterations_2' - `cumiterations_1'
    ereturn scalar iterations_3 = `cumiterations_3' - `cumiterations_2'

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
    ereturn local iterate = `iterate'
    ereturn local n_quad = `intpoints'
    ereturn local adapt = ("`adapt'"=="")
    ereturn local ivar "`id'"
    ereturn local depvar "`response'"
    ereturn local title "Mixed-effects location scale model"
    ereturn local cmdline `e(cmd)' `runmlwin_cmdline'
    ereturn local cmd "runmixregls"



    **************************************
    * ERETURN MATRICES
    **************************************

    ereturn matrix V_3 = `V_3'
    ereturn matrix V_2 = `V_2'
    ereturn matrix V_1 = `V_1'

    ereturn matrix b_3 = `b_3'
    ereturn matrix b_2 = `b_2'
    ereturn matrix b_1 = `b_1'


    **************************************
    * ERETURN FUNCTIONS
    **************************************



    **************************************


    
    
  
    ****************************************************************************
    * (6) RETRIEVE RANDOM EFFECTS AND MERGE INTO ORIGINAL STATA DATASET
    ****************************************************************************
  
    if "`reffects'"~="" {
      quietly {

/*
* Uncomment for debugging
local mixreglstempdir "C:\Users\gl9158\MIXREGLS\"
local reffectsdta "reffects.dta"
//use "data.dta", clear
//preserve
local id id
local reffect_1_b "ustar"
local reffect_2_b "vstar"
*/
        infix str ///
          id  1-12 ///
          nobs 13-24 ///
          a 25-39 ///
          b 40-54 ///
          c 55-70 ///
          using "`mixreglstempdir'\MIXREGLS.RE2", clear
        generate atomicid = _n
        generate model = (id=="ID, nobs, EB")
        replace model = sum(model)
        sum model
        local models = r(max)
        assert inrange(`models',2,3)
        if (`models'==2) recode model (2=3)
        drop if id=="ID, nobs, EB"
        destring id, replace

        replace id = id[_n-1] if id==.
        replace n = n[_n-1] if n==.

        bysort model id (atomicid): generate atomicid2 = _n
        drop atomicid
        reshape wide a b c, i(model id) j(atomicid2)
        isid model id
        drop c1
        replace a2 = b1 if (model==1 | model==2) 
        replace b1 = . if (model==1 | model==2) 
        rename a1 ustar
        rename b1 vstar
        rename a2 ustar_var
        rename b2 ustar2_cov
        rename c2 vstar_var
        generate ustar_se = sqrt(ustar_var)
        generate vstar_se = sqrt(vstar_var)

        * Keep variables of interest
        keep model id ustar ustar_se vstar vstar_se
        order model id ustar ustar_se vstar vstar_se

        * Long to wide
        rename (ustar ustar_se vstar vstar_se) (ustar_ ustar_se_ vstar_ vstar_se_)
        reshape wide ustar_ ustar_se_ vstar_ vstar_se_, i(`id') j(model)
        if (`models'==3) drop vstar_1 vstar_se_1 vstar_2 vstar_se_2
        if (`models'==2) drop vstar_1 vstar_se_1
        if (`models'==2) generate ustar_2 = ustar_1
        if (`models'==2) generate ustar_se_2 = ustar_se_1

        order id ustar_1 ustar_se_1 ustar_2 ustar_se_2 ustar_3 ustar_se_3 vstar_3 vstar_se_3

        * Label variables
        label var id     "ID"
        forvalues m = 1/3 {
          label var ustar_`m'    "EB std. location r.e., stage `m'"
          label var ustar_se_`m' "EB std. location r.e. std. err., stage `m'"
          if (`m'==3) label var vstar_`m'    "EB std. scale r.e., stage `m'"
          if (`m'==3) label var vstar_se_`m' "EB std. scale r.e. std. err., stage `m'"
        }

        * Rename variables  
        rename id `id'
        rename ustar_?    `reffect_1_b'_?
        rename ustar_se_? `reffect_1_se'_?
        rename vstar_?    `reffect_2_b'_?
        rename vstar_se_? `reffect_2_se'_?
        describe
        
        * Generate 
        generate `reffect_1_b'  = `reffect_1_b'_3
        generate `reffect_2_b'  = `reffect_2_b'_3
        generate `reffect_1_se' = `reffect_1_se'_3
        generate `reffect_2_se' = `reffect_2_se'_3

        label var `reffect_1_b'  "EB std. location r.e."
        label var `reffect_1_se' "EB std. location r.e. std. err."
        label var `reffect_2_b'  "EB std. scale r.e."
        label var `reffect_2_se' "EB std. scale r.e. std. err."

        compress
        save "`reffectsdta'", replace
      
      }
    }
    capture erase "`mixreglstempdir'\MIXREGLS.RE2"


    ****************************************************************************
    * (7) RETRIEVE STANDARDIZED RESIDUALS AND MERGE INTO ORIGINAL STATA DATASET
    ****************************************************************************

    if "`residuals'"~="" {
      quietly {
/*
* Uncomment for debugging
local mixreglstempdir "C:\Users\gl9158\MIXREGLS\"
local residualsdta "residuals.dta"
//use "data.dta", clear
//preserve
local residuals "estar"
*/
        infix str ///
          all  1-31 ///
          using "`mixreglstempdir'\MIXREGLS.RE1", clear
        generate atomicid = _n
        generate model = real(substr(all,7,1)) if substr(all,1,5)=="Model"
        assert model[1]==1
        replace model = model[_n-1] if model==.
        tab model
        local models = r(r)
        assert inrange(`models',2,3)        
        
        drop if substr(all,1,5)=="Model"
        destring all, replace
        rename all estar
        bysort model (atomicid): generate _obs = _n
        drop atomicid
        order model _obs estar
        label var model "Model number"
        label var _obs "Observation number"
        label var estar "Standardized residual"
          
        * Long to wide
        rename estar estar_
        reshape wide estar, i(_obs) j(model)
        
        * Generate missing stage 2 residual
        if (`models'==2) generate estar_2 = estar_1
        order _obs estar_1 estar_2 estar_3
    
        * Merge in _sortindex
        merge 1:1 _obs using "`dtafile'", nogenerate assert(match)
        drop _obs

        * Label variables
        label var estar_1 "Standardized residuals, stage 1"
        label var estar_2 "Standardized residuals, stage 2"
        label var estar_3 "Standardized residuals, stage 3"
  
        * Rename variables
        rename estar_? `residuals'_?
        
        * Generate
        generate `residuals' = `residuals'_3
        label var `residuals' "Standardized residuals"

        compress
        save "`residualsdta'", replace
    
  
      }
    }
    capture erase "`mixreglstempdir'\MIXREGLS.RE1"
    
    ****************************************************************************
    * (8) MERGE IN THE RANDOM EFFECTS AND THE RESIDUALS
    ****************************************************************************
    quietly {
      restore
      generate _sortindex = _n
      
      * Merge in the random effects
      if ("`reffects'"~="") {
        merge m:1 `id' using "`reffectsdta'", nogenerate assert(master match) ///
          keepusing(`reffect_1_b' `reffect_1_se' `reffect_2_b'  `reffect_2_se')
      }
      
      * Merge in the residuals
      if ("`residuals'"~="") {
        merge 1:1 _sortindex using "`residualsdta'", nogenerate assert(master match) keepusing(`residuals')
      }
      
      * Merge in the esample indicator variable
      merge 1:1 _sortindex using "`dtafile'", assert(master match) keepusing(_obs)
      replace _obs = (_obs<.)
      ereturn repost, esample(_obs)
      drop _sortindex _merge
      
    }


    ****************************************************************************
    * (8) OUTPUT  
    ****************************************************************************

    * Remove the temporary MIXREGLS directory
    rmdir "`mixreglstempdir'"


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


********************************************************************************
exit