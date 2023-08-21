*! version 1.02 2023-08-16
program define standsurv, rclass sortpreserve
  version 16.1
  syntax [anything] [if] [in],        ///
    [                                 ///  
        ATVars(string)                /// list or stub for at variables
        ATReference(integer 1)        /// reference at() - default 1
        CENTILE(numlist >0 <100)      ///  centiles of standardized curve
        CENTILEUpper(real -99)        /// starting value for upper bound of centile search
        CENTVar(string)               /// name of new centile variable (default _centvar)
        CI                            /// request CI to be calculated
        CIF                           /// cause-specific incidence function
        CONtrast(string)              /// type of contrast
        CONTRASTVars(string)          /// list or stub for contrasts
        CRMODels(string)              /// list of models for competing risks
        CRUDEPRob                     /// Crude probabilities of death
        CRUDEPROBPART                 /// Partitioning of crude probabilities of death 
        ENTer(real 0)                 /// enter for conditional estimates
        EXPSURV(string)               /// calculate expected survival (many options)
        FAILure                       /// calculate failure function
        FRAME(string)                 /// save predictions to a frame
        GENIND(string)                /// generate individual predictions
        HAZard                        /// standardized hazard function
        INDWeights(string)            /// multiply observations by weights
        LEVel(real `c(level)')        /// level for CIs
        LINCOM(string)                /// linear combination of at options
        LINCOMVar(string)             /// name of new variables for linear combination
        LOS                           /// length of stay
        MESTimation                   /// use M-estimation
        MSMODels(string)              /// list of multistate models
        NOdes(integer 30)             /// number of nodes for numerical integration
        noGEN                         /// do not generate at variables
        ODE                           /// use ode for integration
        ODEOPTions(string)            /// ODE integration options
        OVER(varlist)                 /// estimate at unique value of varlist
        PER(real 1)                   /// per option (multiply to give pys etc)
        RMST                          /// restricted mean survival time
        RMFT                          /// restricted mean failure time
        SE                            /// calculate standard error
        STOREG(string)                /// Stores G matrix for delta method
        STUB2(string)                 /// 2nd stub for cif or crude prob
        SURVival                      /// standardized survival function (default)
        TImevar(varname)              /// timepoints for predictions
        TOFFset(string)               /// time offset for different time scales
        TRansform(string)             /// Transformation for variance calculation
        TRANSMat(string)              /// Transition matrix for multistate models
        TRANSPROB                     /// Calculate transition probabilities
        USERFunction(string)          /// user defined function
        USERFUNCTIONVar(string)       /// name of new variables for userfunction
        VERBOSE                       /// show what is happening (speed tests)
        *                             /// atn() options
        ]
  
  tempvar touse_time touse_model touse_at_any 
  tempname current_model
  marksample touse, novarlist
  
  local hasif = "`if'`in'" != ""
  
// default to standardized survival function
  if wordcount("`centile' `hazard' `survival' `rmst' `rmft' `failure' `cif' `crudeprob' `crudeprobpart' `transprob' `los'`msmodels'") == 0 local survival "survival"
// only one prediction option
  if "`cif'" == "" & "`crudprob'" == "" {
    if wordcount("`hazard' `survival' `rmst' `rmft' `failure'" "`crudeprobpart'") + ("`centile'" != "") > 1 {
      di as error "You can only specify one of the survival, hazard, centile, rmst, rmft, crudeprob crudeprobpart options"
      exit 198
    }
  }
  else if "`cif'" != "" {
    if wordcount("`hazard' `survival' failure'" "`crudeprob'" "`crudeprobpart'") + ("`centile'" != "") > 1 {
      di as error "You can't specify the "`hazard' `survival' `failure' `crudeprob' `crudeprobpart'" option with the cif option"
      exit 198
    }
    if "`rmst'" != "" {
      di as error "You can't use rmst in combination with the cif option." 
      di as error "Perhaps you intended to use rmft."
      exit 198
    }
  }
  else if "`crudeprob'" != "" {
    if wordcount("`hazard' `survival' failure'" "`cif'" "`crudeprobpart'") + ("`centile'" != "") > 1 {
      di as error "You can't specify the "`hazard' `survival' `failure'" "`cif'" "`crudeprobpart'" option with the crudeprob option."
      exit 198
    }
  }

// check moremata installed  
  capture findfile lmoremata.mlib  
  if _rc {
    display in yellow "You need to install moremata to use standsurv"
    display in yellow "Type {stata ssc install moremata}, or just click on the link"
    exit  198
  }  
  
// Use of crmodels/msmodels options  
  if "`msmodels'" != "" &  "`crmodels'" !="" {
    di as error "Only one of the msmodels() and crmodels() options can be specifed."
    exit 198
  }  
  
  if "`msmodels'" != "" {
    if "`transmat'" == "" {
      di as error "You need to specify the transmat() option with the msmodels() option"
      exit 198
    }
    confirm matrix `transmat'
    local tmat_cols = colsof(`transmat') 
    local tmat_rows = rowsof(`transmat') 
    if `tmat_cols' != `tmat_rows' {
      di as error "Transition matrix must be a square matrix."
      exit 198
    }
    local Nstates `tmat_cols'
    
    if wordcount("`transprob' `los'")>1 {
      di as error "Only one of the transprob and los options can be specified for multistate models."
      exit 198
    }
    
    if wordcount("`transprob' `los'")==0 {
      local transprob transprob
    }    
    // ##### should check
    // -- square
    // -- diagonals all missing
    // -- elements unique
    local ode ode
  }
  else {
    if wordcount("`transprob' `los'")!=0 {
      di as error "The transprob and los options only available for multistate models."
      exit 198
    }    
  }
  
  local Ncrmodels = cond("`crmodels'" == "",1,wordcount("`crmodels'"))
  local Nmsmodels = cond("`msmodels'" == "",`Ncrmodels',wordcount("`msmodels'"))
  
  if "`crmodels'" == "" & "`cif'" != "" {
    di as error "cif option only available with competing risks using crmodels() option" ///
                _newline "Use failure option for 1-S(t)"
    exit 198
  }
  if "`crmodels'" == "" & "`crudeprobpart'" != "" {
    di as error "crudeprobpart option only available with competing risks using crmodels() option" ///
    exit 198
  }
  
  if `Nmsmodels' == 1 {
    if "`e(cmd)'" != "stpm2" & "`e(cmd2)'" != "streg" & "`e(cmd)'" != "strcs" & "`e(cmd)'" != "stpm3" {
      di as error "You need to fit an stpm2, stpm3, strcs or streg model to use standsurv"
      exit 198
    }
    estimates store `current_model'
    local crmodels `current_model'
  }

  else {
    foreach mod in `crmodels'`msmodels' {
      quietly estimates restore `mod'
      if "`e(cmd)'" != "stpm2" & "`e(cmd2)'" != "streg" & "`e(cmd)'" != "strcs" & "`e(cmd)'" != "stpm3" {
        di as error "Model `mod' is not an stpm2, stpm3, strcs or streg model"
        exit 198
      }
      if "`hazard'`centile'" != "" {
        di as error "`hazard'`centile' option not implemented for competing risks or multistate models."
        exit 198
      }
    }
  }
  
  // nogen option
  if "`gen'" != "" {
    if "`contrast'" == "" | "`lincom'" == "" {
      di as error "Only use the nogen option when in combination with the contrast or lincom options."
      exit 198
    }
    if "`atvars'" != "" {
      di as error "You have given variable names to generate, but also asked not to generate them."
      exit 198
    }
  }
  
  // over option
  if "`over'" != "" {
  // check for no at options
    if strpos("`options'","at1(")>0 {
      di as error "You can't combine the over() option with at() options"
      exit 198
    }
    tempvar grp
    qui egen `grp' = group(`over') if `touse', label
    qui levelsof `grp'
    local Ntmp = `r(r)'
    foreach i in `r(levels)' {
      local atlist `atlist' at`i'(.,atif(`grp'==`i' & `touse'))
    }
    local options `atlist'
    
    local i 1
    while `i' <= `Ntmp' {
      GetGroupLabel `over' if `grp'==`i' 
      local overlab`i' `"`r(label)'"'
      local ++i
    }
  }
  
// ##### NEED TO HAVE DIFFERENT CHECKS FOR DIFFERENT MODELs
// PERHAPS HAVE SEPARATE CODE FOR DIFFERENT MODEL /*
// DEFAULT TO PROB FOR MS MODELS to START.
  
// Check no factor variables
  if "`e(cmd)'" != "stpm3" {
    fvexpand `e(varlist)'
    if "`r(fvops)'" == "true" {
      di as error "standsurv only allows factor variables for stpm3 models" 
      di as error "Refit the model using dummy variables etc"
      exit 198
    }
    local streg_varnames: colvarlist e(b)
    local streg_varnames: subinstr local streg_varnames "_cons" "", all word
    capture fvexpand `streg_varnames'
    if "`r(fvops)'" == "true" {
      di as error "standsurv only allows factor variables for stpm3 models" 
      di as error "Refit the model using dummy variables etc"
      exit 198
    }
  }
  
// checks for toffset option
  if "`toffset'" != "" {
    if "`cif'" == "" & "`survival'"=="" & "`failure'"=="" & "`rmst'"=="" & "`rmft'"=="" & "`transprob'"=="" {
      di as error "toffset() option only works in conjunction wth survival/failure/rmst/rmft/cif options." 
      exit 198
    }  
    if wordcount("`toffset'") != `Nmsmodels' {
      di as error "the number of arguments in the toffset option should be the same as the number of models"
      di as error "Use . if you want to use the original timescale"
      exit 198
    }
    local j 1
    foreach toff in `toffset' {
      if "`toff'" == "." local toffset`j' = 0
      else {
        capture confirm var `toff'
        if _rc {
          di as error "Variable `toff' (specifed in toffset() option), does not exist"
          exit 198
        }
        else local toffset`j' `toff'
      }
      local j = `j' + 1
    }
// force ode integration
    local ode ode
  }

// ode is now method for CIF option
  if "`cif'" != "" | "`crudeprob'" != "" local ode ode
// Check for Mestimation
  if("`mestimation'" != "") {
    if `Ncrmodels' > 1 {
      di as error "Mestimation not implemented for competing risks / multistate models"
    }
    if "`e(cmd)'" == "strcs" {
      di as error "Mestimation not implemented for strcs models"
    }
  }

// use of frame
  if "`frame'" != "" {
    getframeoptions `frame'
    mata: st_local("frameexists",strofreal(st_frameexists(st_local("resframe"))))
    if `frameexists' & "`framereplace'" != "" {
      frame drop `resframe'
    }
   
    if "`framemerge'" != "" {
      tempvar linkvar tmpid tempframevar
      gen `tmpid' = _n
      frame `resframe': gen `tmpid' = _n
      qui frlink 1:1 `tmpid', frame(`resframe') gen(`linkvar')
      qui gen `tempframevar' = frval(`linkvar', `frametimevar')
      local timevar `tempframevar'
    }
  }
  
// Extract at() options
  local optnum 1
  local end_of_ats 0
  local 0 ,`options'
  while `end_of_ats' == 0 {
    capture syntax [,] AT`optnum'(string) [*]
    if _rc {
      local N_at_options = `optnum' - 1
      local end_of_ats 1
      continue, break
    }
    else local 0 ,`options'
    local optnum = `optnum' + 1
  }
  local N_at_options = `optnum' - 1
  if "`0'" != "," {
    di as error "Illegal option: `0'"
    exit 198
  }
  local hasatoptions = `N_at_options' > 0
  if !`hasatoptions' local N_at_options 1

// Parse at() options
  if `hasatoptions' > 0 {
    forvalues i = 1/`N_at_options' {
  // parse "if" & "indweights" suboptions
      tokenize "`at`i''", parse(",")
      local at`i'opt  `1'
      if "`1'" == "" | "`1'" == "," {
        di as error "An at option can't be empty" ///
            "Use . to standardize over observed covariates"
        exit 198  
      }
      local 0 `2'`3'
      syntax ,[ATIF(string) ATINDWeights(varname) ATTIMEVar(string) ATENTER(string)]
      if `hasif' & `"`atif'"' != "" {
        di as error "You can either use an if statement or the atif suboptions" _newline ///
              "of the at() options, but not both"
        exit 198
      }
      tempvar touse_at`i'
      if `"`atif'"' == "" {
        gen byte `touse_at`i'' = `touse'
      }
      else {
        gen byte `touse_at`i'' = (`atif')
      }
  // atindweight
      if "`atindweights'" != "" {
        if "`indweights'" != "" {
          di as error "You can't combine the main indweight option with atindweight options"
          exit 198
        }
        local atindweights`i' `atindweights'
      }
      else {
        local atindweights`i' `indweights'
      }
  // attimevar
      if "`attimevar'" != "" {
        confirm var `attimevar'
        if "`timevar'" != "" {
          di as error "You can't specify both the attime and timevar options"
          exit 198
        }
        local timevar`i' `attimevar'
      }
      else {
        if "`timevar'" == "" & "`centile'" == "" {
          di as error "you must use either the timevar() or centile () option." 
          di as error "(or the atimevar() suboption of the at() option.)" 
          exit 198  
        }
        local timevar`i' `timevar'
      }
  // atenter    
      if "`atenter'" != "" {
        confirm number `atenter'
        if "`enter'" != "0" {
          di as error "You can't specify both the atenter suboption and enter options"
          exit 198
        }
        local enter`i' `atenter'
      }
      else {
        local enter`i' `enter'
      }      
  // main at option
      local at`i'opt = subinstr("`at`i'opt'","="," = ",.)
      tokenize `at`i'opt'
      while "`1'"!="" {
        if "`1'" == "." | "`1'"=="" continue, break
        fvunab tmpfv: `1'
        local 1 `tmpfv'
        cap confirm var `1'
        if _rc {
          di "`1' is not in the data set"
        }
        local at`i'vars `at`i'vars' `1'
        if "`2'" != "=" {
          cap confirm num `2'
          if _rc {
            di as err "invalid at(... `1' `2' ...)"
            exit 198
          }
          local at`i'_`1'_value `2'
          mac shift 2
          
        }
        else {
          cap confirm var `3'
          if _rc {
            di as err "`var' is not in the data set"
            exit 198
          }        
          local at`i'_`1'_value .
          local at`i'_`1'_variable `3'
          mac shift 3
        }
      }
    }
  }
  else {
    tempvar touse_at1
    gen byte `touse_at1' = `touse'
    local timevar1 `timevar'
    local atindweights1 `indweights'
    local enter1 `enter'
  }
  
// check no missing indweights
  forvalues i = 1/`N_at_options' {
    qui count if missing(`atindweights`i'') & `touse_at`i''
    if `r(N)' {
      di as error "Missing values for atindweights`i'"
      exit 198
    }
  }
  
  
// expected survival
  if `"`expsurv'"' != "" {
    Parse_expsurv_options , `expsurv'
    if `calcexpsurv' {
      capture _stubstar2names double `expsurvvars', nvars(`=`N_at_options'') 
      local expsurv_varnames  `s(varlist)'
      if _rc>0 {
        di as error "expsurvvars() option should either give `N_at_options' new variable names" ///
          "or use the {it:stub*} option. The specified variable(s) may already exist."
        exit 198
      }
    }  
  }
  if "`crudeprob'" != "" & `"`expsurv'"' == "" {
    di as error "Crude probabilities are only available with a relative survival model when calculating expected survival"
    exit 198
  }
  if "`crudeprobpart'" != "" & `"`expsurv'"' == "" {
    di as error "Partitioning of crude probabilities are only available with a relative survival model when calculating expected survival"
    exit 198
  }
  
// maximum observed time value  
  summ _t if _d==1 & e(sample), meanonly
  local maxt `r(max)'  

// centiles  
  if "`centile'" != "" {
    if "`centvar'" == "" local centvar _centvals
    confirm new var `centvar'  
    tempvar touse_centiles
    qui gen `centvar' = .
    local i = 1
    foreach c of numlist `centile' {
      qui replace `centvar' = `c' in `i'
      local ++i
    }    
    gen byte `touse_centiles' = `centvar' != .  
    if `centileupper' == -99 local centileupper = `maxt'*4
  }
  
// time variable
  if "`centile'" == "" {
    tempvar tempt1
    gen `tempt1' =  `timevar1' != .
    qui count if `timevar1' !=.
    local previous_count `r(N)'

    forvalues i = 1/`N_at_options' {
      qui count if `timevar`i'' !=.
      if `i'>1 {
        if `r(N)' != `previous_count' {
          di as error "Timevar variables must be of same length"
          exit 198
        }

        capture assert !missing(`timevar1',`timevar`i'') if `tempt1'
        if _rc {
          di as error "Timvar variables must have same rows with non-missing values."
          exit 198
        }
      }
      local previous_count `r(N)'

      if "`timevar`i''" != "" & "`centile'" != "" {
        di as error "You can't specifiy both the timevar() and centile() options"
        exit 198
      }
      local timevarlist `timevarlist' `timevar`i''
    }
    gen byte `touse_time' = `timevar1' != .
  }
  
  
  qui count if e(sample) & _t0>0
  local hasdel_entry = cond(`r(N)'>0,1,0)  
  
// enter option
  forvalues i = 1/`N_at_options' {
    local hasenter`i' = (`enter`i'' >0)
    if `hasenter`i'' & ("`centile'" != "" | "`hazard'" != "") {
      di as error "The enter() / atenter() options not implemented for hazard or centile options"
      exit 198
    }
  
    if `hasenter`i'' {
      qui count if (`enter`i''>`timevar`i'' & !missing(`timevar`i''))
      if `r(N)' > 0 {
        display as error "Some (or all) of `timevar`i'' is less than your entry time"
        exit 198
      }
      local ode ode
    }
  }
  
// to_use_atany indicator  
  gen `touse_at_any' = 0
  forvalues i = 1/`N_at_options' {
    quietly count if `touse_at`i'' == 1 
    local Nobs_predict_at`i' `r(N)'
    local touse_at_list `touse_at_list' `touse_at`i''
    qui replace `touse_at_any' = 1 if `touse_at_any' == 0 & `touse_at`i'' == 1
  }
  
// at reference  
  if `atreference' != 1 {
    if !inrange(`atreference',1,`N_at_options') {
      di as error "atreference option out of range"
      exit 198
    }
  }  
  
// stub2 names  
  if("`cif'" != "" | ("`rmft'" != "" & "`crmodels'" != "") | "`crudeprob'" != "" | "`crudeprobpart'" != "" | ("`rmft'" != "" & "`crmodels'"!= "") | "`msmodels'" != "") {
    if("`stub2'" == "") {
      if "`cif'" != "" | ("`rmft'" != "" & "`crmodels'"!= "") local stub2 `crmodels'
      else if "`msmodels'"      != "" {
        forvalues i = 1/`Nstates' {
          local stub2 `stub2' s`i' 
        }
      }
      else if "`crudeprob'"     != "" local stub2 disease other
      else if "`crudeprobpart'" != "" local stub2 `crmodels' exp
    }
  }
  local Nstub2names = wordcount("`stub2'") + ("`crudeprob'" == "" & "`cif'" == "" & "`crudeprobpart'"=="" & ("`rmft'" == "" & "`crmodels'"!= ""))
  if `Nstub2names'>1 & !("`cif'" != "" | ("`rmft'" != "" & "`crmodels'" != "") | ///
                       "`crudeprob'" != "" | "`crudeprobpart'" != "" |           ///
                       ("`rmft'" != "" & "`crmodels'"!= "") |                    /// 
                       "`msmodels'" != "") {
  	di as error "You have used stub2() for an option where it is not needed"
    exit 198
  }
  
// names of new variables
// ######## UPDATE for MSMODELS if stub2name used
  if  "`anything'" != "" {
  	if "`atvars'" != "" {
  	  di as err "You can't specify new varible names and the atvar option"
	  exit 198
	}
	else local atvars `anything'
  }
  if "`atvars'" == "" {
    if ((`Nmsmodels' == 1 & "`crudeprob'" == "") | /// 
       ((`Ncrmodels' > 1 & "`cif'" == "")  & "`crudeprobpart'" == "")) {
      forvalues i = 1/`N_at_options' {
        local at_varnames `at_varnames' _at`i'
      }
    }
    else {
      forvalues i = 1/`N_at_options' {
        foreach s in `stub2' {
          local at_varnames `at_varnames' _at`i'_`s'
        }
      }
    }
  }
  else {
    if "`resframe'" == "" {
      capture _stubstar2names double `atvars', nvars(`N_at_options') 
      if _rc>0 {
        di as error "atvars() option should either give `N_at_options' new variable names " ///
          "or use the {it:stub*} option. The specified variable(s) probably exists."
        exit 198
      }
      local tmp_atnames `s(varlist)'
    }
    else {
      local tmp_atnames `atvars'
    }
    
    if ((`Nmsmodels' == 1 & "`crudeprob'" == "") | ///
       (`Ncrmodels' > 1 & "`cif'" == ""  & "`crudeprobpart'" == "" & "`rmft'" == "")) { 
      local at_varnames `tmp_atnames'
    }
    else {
      _stubstar2names double `tmp_atnames', nvars(`N_at_options') 
      local tmp_atnames `s(varlist)'
      foreach name in `tmp_atnames' {
        foreach s in `stub2' {
          local at_varnames `at_varnames' `name'_`s'
        }
      }
    }
  }

  if "`contrastvars'" == "" {
    if ((`Nmsmodels' == 1 & "`crudeprob'" == "") | (`Nmsmodels' >1 & "`cif'" == "")) {
      forvalues i = 1/`N_at_options' {
        if `i' == `atreference' continue
        local contrast_varnames `contrast_varnames' _contrast`i'_`atreference'
      }
    }
    else {
      forvalues i = 1/`N_at_options' {
        if `i' == `atreference' continue
        foreach s in `stub2' {
          local contrast_varnames `contrast_varnames' _contrast`i'_`s'
        }
      }
    }
  }
  else { 
    capture _stubstar2names double `contrastvars', nvars(`=(`N_at_options'-1)') 
    local tmp_contrast_varnames  `s(varlist)'
    if _rc>0 {
      di as error "contrastvars() option should either give `=`N_at_options'-1' new variable names " ///
        "or use the {it:stub*} option. The specified variable(s) probably exists."
      exit 198
    }
    if ((`Nmsmodels' == 1 & "`crudeprob'" == "") | (`Ncrmodels' >1 & "`cif'" == "")) {
      foreach vv in `tmp_contrast_varnames' {
        local contrast_varnames `contrast_varnames' `vv'
      }  
    }
    else {
      foreach vv in `tmp_contrast_varnames' {
        foreach s in `stub2' {
          local contrast_varnames `contrast_varnames' `vv'_`s'
        }
      }
    }    
  }

  // lincom checks
  // ######## UPDATE for MSMODELS
  if "`lincom'" != "" {
    capture numlist "`lincom'"
    if _rc {
      di as error "Invalid numlist for lincom() option."
      exit 198
    }
    local atmultiplier 1
    if "`crmodels'"  != ""  local atmultiplier `Ncrmodels'
    if "`crudeprob'" != ""  local atmultiplier 2
    if "`msmodels'"  != ""  local atmultiplier `Nstates'
    if wordcount("`lincom'") != `N_at_options'*`atmultiplier' {
      di as error "Number of values in lincom() option should be `=`N_at_options'*`atmultiplier''." 
      exit 198
    }
    if "`lincomvar'" == "" {
      local lincom_varname _lincom
    }
    else local lincom_varname `lincomvar'    
  }

  // userfunction checks
  if "`userfunctionvar'" == "" {
    local userfunction_varname _userfunc
  }
  else local userfunction_varname `userfunctionvar'
  
// genind option

  if "`genind'" != "" {
    if wordcount("`genind'") != `N_at_options' {
      di as error "Number of variable for genind() option should be the same as the number of at() options"
      exit 198
    }
    if (`Nmsmodels' > 1 | "`crudeprob'" != "") { 
      foreach g in `genind' {
        foreach s in `stub2' {
          local genind_varnames `genind_varnames' `g'`i'_`s'
        }
      }
    }
	  else local genind_varnames `genind'

    qui count if `timevar1' != .
    if `r(N)' > 1 {
      di as error "You can only use the genind() option when the timevar variable contains a single value."
      exit 198
    }
    if "`expsurv_genind_varnames'" != "" {
      if wordcount("`expsurv_genind_varnames'") != `N_at_options' {
        di as error "Number of variable for genind() suboption of expsurv() should be the same as the number of at() options"
        exit 198
      }
      if "`crudeprob'" != "" {
        di as error "genind suboption of expsurv() option not available for crude probabilities."
        exit 198
      }
    }
  }
  else {
    if "`expsurv_genind_varnames'" != "" {
      di as error "You can only use the genind() suboption of expsurv when using the genind option."
      exit 198     
    }
  }
  
// Transform option
  if "`transform'" == "" local transform log
  if !inlist("`transform'","loglog","logit","log","none") {
    di as error "Transform options are none, log, loglog or logit"
    exit 198
  }

// Number of observations used in the model  

  local mi 1
  foreach mod in `crmodels'`msmodels' {
    quietly estimates restore `mod'
    tempvar touse_model`mi'
    quietly gen `touse_model`mi'' = e(sample)
    quietly count if `touse_model`mi'' == 1
    local Nobs_model`mi' `r(N)'

    local survival_cmd_model`mi'  = cond("`e(cmd2)'"=="streg","streg","`e(cmd)'")
    if "`survival_cmd_model`mi''" == "streg" {
      local streg_distribution_model`mi' `e(cmd)'
      if "`streg_distribution_model`mi''" == "gamma" {
        di as error "streg gamma models currently not supported"
        exit 198
      }
      if "`e(cure)'" != "" {
        di as error "standsurv does no currently support cure models"
        exit 198
      }
      
      _ms_extract_varlist *, nofatal
      local varlist_xb1_model`mi' `r(varlist)'
      if   "`survival_cmd_model`mi''" == "streg" {
        _ms_eq_info
        local Nequations_model`mi' `r(k_eq)'
        forvalues i = 2/`Nequations_model`mi'' {
          local eqname`i' `r(eq`i')'
          local k`i' `r(k`i')'
        }
        forvalues i = 2/`Nequations_model`mi'' {
          if `k`i''>1 {
            _ms_extract_varlist *, nofatal eq(`eqname`i'')
            local varlist_xb`=`i''_model`mi' `r(varlist)'
          }
        }
        local varsinmodel`mi' = "`varlist_xb1_model`mi'' `varlist_xb2_model`mi'' `varlist_xb3_model`mi''"
        capture di _b[_cons]
        local hascons_xb1_model`mi' = cond(_rc,0,1)
        local hascons_xb2_model`mi' = 1
        local hascons_xb3_model`mi' = 1
      }
    }
    else if "`survival_cmd_model`mi''" == "stpm2" {
      if !inlist("`e(scale)'","hazard","odds","normal") {
        di as error "scale(`e(scale)' not supported by standsurv."
        exit 198
      }
    
      local varsinmodel`mi' = "`e(varlist)' `e(tvc)'"
      local stpm2_scale_model`mi' `e(scale)'
      local stpm2_orthog_model`mi' = cond("`e(orthog)'" == "",0,1)
      local stpm2_ln_bhknots_model`mi' `e(ln_bhknots)'
      local hascons_xb1_model`mi' = cond("`e(noconstant)'"=="",1,0)
      local stpm2_rcsbaseoff_model`mi' = cond("`e(rcsbaseoff)'"=="",0,1)
      local Nequations_model`mi' = 3
      local varlist_xb1_model`mi' `e(varlist)' 
      local varlist_xb3_model`mi' `e(tvc)'
      local hascons_xb2_model`mi' = 0
      local hascons_xb3_model`mi' = 0
      local hasreverse`mi' `e(reverse)'
      _ms_eq_info
      local Nparameters_all`mi' = `r(k1)' 
      local drcs_all_model`mi' `e(drcsterms_base)'
      foreach tvc in `e(tvc)' {
        local drcs_all_model`mi' `drcs_all_model`mi'' `e(drcsterms_`tvc')'
      }
      if("`mestimation'" != "") {
        tempvar expxb_model`mi' dxb_model`mi' expxb0_model`mi'
        qui predict `expxb_model`mi'' if `touse_model`mi'', xb
        qui replace `expxb_model`mi'' = exp(`expxb_model`mi'')
        qui predict `dxb_model`mi'' if `touse_model`mi'', dxb 
        if `hasdel_entry' {
          qui predict `expxb0_model`mi'' if `touse_model`mi'' & _t0>0, xb timevar(_t0)
          qui replace `expxb0_model`mi'' = exp(`expxb0_model`mi'')
          qui replace `expxb0_model`mi'' = 0 if `touse_model`mi'' & _t0==0
        }
        else qui gen `expxb0_model`mi'' = 0 if `touse_model`mi'' 
      }
      // use ode for rmst/rmft
      if "`rmst'`rmft'" != "" local ode ode
    }
    else if "`survival_cmd_model`mi''" == "strcs" {
      local varsinmodel`mi' = "`e(varlist)' `e(tvc)'"
      local strcs_orthog_model`mi' = cond("`e(orthog)'" == "",0,1)
      if "`e(bhtime)'" == "" local strcs_ln_bhknots_model`mi' `e(bhknots)'
      else local strcs_bhknots_model`mi' `e(bhknots)'
      local hascons_xb1_model`mi' = cond("`e(noconstant)'"=="",1,0)
      _ms_eq_info
      local Nparameters_all`mi' = `r(k1)'     
      local Nequations_model`mi' = 3
      local hasreverse`mi' `e(reverse)'
      /* To be added
      if("`mestimation'" != "") {
        tempvar strcs_xb strcs_ch ch_t0
        qui predict `strcs_xb' if `touse_model`mi'', xb
        qui predict `strcs_ch' if `touse_model`mi'', cumhaz
        if `hasdel_entry' {
          qui predict `ch_t0' if `touse_model`mi'', cumhaz timevar(t0)
          replace `strcs_ch' = `strcs_ch' - `ch_t0'
        }
      }
      */
      if "`rmst'`rmft'`survival'`failure'" != "" local ode ode

    }
    else if "`survival_cmd_model`mi''" == "stpm3" {

      
      local varsinmodel`mi' = "`e(model_vars)'"
      local stpm3_scale_model`mi' `e(scale)'
      local stpm3_knots`mi' `e(knots)'
      local hascons_xb1_model`mi' = 0
      local hascons_xb2_model`mi' = "`e(constant)'" == ""
      local Nequations_model`mi' = 2
      
      
      if "`hazard'" != "" & "`stpm3_scale_model`mi''" != "lncumhazard" {
        di as error "hazard option only available for stpm3, scale(lncumhazard) models." 
        exit 198
      }      
      
      // omitted variables  
      tempname omit_model_m`mi'
      _ms_omit_info e(b)  
      matrix `omit_model_m`mi'' = r(omit)      
      //////////////////////////////////////
      //  create frame for each at option //
      //////////////////////////////////////
      if "`verbose'" != "" di "Creating at frames"
      forvalues i = 1/`N_at_options' {
        tempname atframe`i'`mi'
        local atframenames `atframenames' `atframe`i'`mi''
         
        frame put `e(model_vars)' if `touse_at`i'', into(`atframe`i'`mi'')
        frame `atframe`i'`mi'' {
          foreach v in `at`i'vars' {
            if `at`i'_`v'_value' != . {
              qui replace `v' =  `at`i'_`v'_value'
            }
            else qui replace `v' =  `at`i'_`v'_variable'
          }
        
          // extended variables
          foreach v in `e(ef_varlist)' {
            forvalues f = 1/`e(ef_`v'_Nfn)' {
              local type `e(ef_`v'_fn`f')'
              if inlist("`type'","bs","ns","rcs") {
                local knots `e(ef_`v'_knots`f')'
                local knotsopt = cond("`knots'"!="","allknots(`knots')","df(1)")
                local gsopts
                if "`e(ef_`v'_center`f')'" != "" local gsopts `gsopts' center(`e(ef_`v'_center`f')')
                if "`e(ef_`v'_winsor`f')'" != "" local gsopts `gsopts' winsor(`e(ef_`v'_winsor`f')',values)
                gensplines `v', type(`type') `knotsopt' `gsopts' ///
                                gen(_`type'_f`f'_`v')
              }
              else if "`type'" == "fp" {
                local fpopts
                if "`e(ef_`v'_scale`f')'"  != "" local fpopts scale(`e(ef_`v'_scale`f')')
                if "`e(ef_`v'_center`f')'" != "" local fpopts `fpopts' center(`e(ef_`v'_center`f')')
                stpm3_fpgen `v', powers(`e(ef_`v'_powers`f')') stub(_fp_f`f'_`v') `fpopts'
              }
              else if "`type'" == "poly" {
                local polyopts 
                if "`e(ef_`v'_center`f')'" != "" local polyopts `polyopts' center(`e(ef_`v'_center`f')')
                stpm3_polygen `v', degree(`e(ef_`v'_powers`f')') stub(_poly_f`f'_`v') `polyopts'
              }
            }
          }
          forvalues f = 1/`e(ef_Nuser)' {
            local stub = word("`e(ef_fn_names)'",`f')
            if "`e(ef_fn`f'_centerval)'" != "" local fnopts center(`e(ef_fn`f'_centerval)')
            stpm3_userfunc `e(ef_fn`f'_function)', vname(_fn_`stub') `fnopts'
          }             
        
          _ms_lf_info
          if `r(k_lf)'>1 {
            local tmpvarlist `r(varlist1)'
            _ms_extract_varlist `tmpvarlist', eq(xb) noomitted
            standsurv_varlist_add_bn "`r(varlist)'"
            local varlist_xb1_model`mi' `r(varlist)'
          }
        }
        
        // list of tvc variables
        if "`e(tvc)'" != "" {
          foreach v in `e(splinelist_tvc)' {
            _ms_parse_parts `v'
            if "`r(type)'" == "interaction" {
              local vtmp = subinstr("`v'","#c.`r(name`r(k_names)')'","",.)
              local vtemp `vtemp' `vtmp'
            }
          }  
          //local tvc_varlist
          local varlist_xb2_model`mi': list uniq vtemp
          standsurv_varlist_add_bn "`varlist_xb2_model`mi''"
          local varlist_xb2_model`mi' `r(varlist)'
        }        
      }    
      // use ode for rmst/rmft ** Update when sorted out integration **
      if "`rmst'`rmft'" != "" local ode ode
      if "`e(scale)'" == "lnhazard" {
        if "`survival'`failure'`rmst'`rmft'" != "" local ode ode
      }
      tempname timebeta`mi'
      matrix `timebeta`mi'' = e(b)[1,"time:"]
      // column location of time-dependent effects - needed for ODE
      if "`e(tvc)'" != "" {
        if `e(sharedtvc_knots)' {
          local j 1
          foreach v in `e(tvc_included)' {
            foreach tv in `e(splinevars_tvc)' {
              local tvccol`mi'`j' `tvccol`mi'`j'' `=colnumb(`timebeta`mi'',"`v'#c.`tv'")'
            }
            local ++j
          }
        }
        else {
          local j 1
          foreach v in `e(tvc_included)' {
            _ms_parse_parts `v'
            //local tvc_nofactor `tvc_nofactor' `r(name)'
            foreach tv in `e(splinevars_tvc_`r(name)')' {
              local tvccol`mi'`j' `tvccol`m'`j'' `=colnumb(`timebeta`mi'',"`v'#c.`tv'")'
            }
            local ++j
          }
        }
      }             
    }  
    
// error if try to average over covariates with missing values
    foreach var in `varsinmodel`mi'' {
      qui count if missing(`var') & `touse_at_any'
      if `r(N)'>0 {
        di as error "There are missing values for `var'" 
        di as error "You can restrict using an if statement"
        exit 198
      }
    }
    
    
    
    local mi = `mi' + 1    
  }
  
// Display warning if predicting for observations not in e(sample)
  qui count if !e(sample) & `touse_at_any'
  if `r(N)' > 1 {
    display as text "!!WARNING!! You are including observations not included in the model"
    display as text "when calculating standardized estimates." 
    display as text "Ensure this is what you intended."
  }
  
// error if expected survival and missing covariates needed for merging popmort file

  if `"`expsurv'"' != "" {
    foreach var in `agediag' `datediag' `pmother' {

      qui count if missing(`var') & `touse_at_any'
      if `r(N)'>0 {
        di as error "`var' has missing values"
        exit 198
      }
    }
  }
  
// Check contrast option  
  if "`contrast'" != "" {
    if !inlist("`contrast'","difference","ratio","pchange") {
      di as error "contrast option should either be difference or ratio"
      exit 198
    }
  }
  
// ODE suboptions
  Parse_ODEoptions, `odeoptions'

// Call mata program   
  if "`verbose'" != "" di in yellow _newline "Calling main mata program"
  mata: SS_standsurv()

  local fr = cond("`frame'"!="","frame `resframe':","")
  forvalues i = 1/`N_at_options' {
    local iftv`i' = cond("`framemerge'"!="","`frametimevar' == 0","`timevar`i'' == 0")
  }  
  
// replace point-estimates & CIs= 1 if timevar == 0 for survival etc
  if "`survival'" != "" & "`gen'" == "" {
    forvalues i = 1/`N_at_options' {
      local tmpname = word("`at_varnames'",`i')
      qui `fr' replace `tmpname' = 1 if `iftv`i''
      if("`ci'" != "") {
        qui `fr' replace `tmpname'_lci = 1 if `iftv`i''
        qui `fr' replace `tmpname'_uci = 1 if `iftv`i''
      }
      if `"`expsurv'"' != "" & `"`expsurvvars'"' != "" {
        local tmpname = word("`expsurv_varnames'",`i')
        qui `fr' replace `tmpname' = 1 if `iftv`i''
      }
    }  
  }

  
  if ("`failure'" != "" | "`rmst'" != "" | "`rmft'" != "" | "`cif'" != ""  | "`crudeprob'" != "") & "`timevar'" != "" & "`gen'" == "" {
    local Nvars = wordcount("`at_varnames'")
    forvalues i = 1/`Nvars' {
      local tmpname = word("`at_varnames'",`i')
      local iftv`i' = cond("`frametimevar'"!="","`frametimevar' ==0","`timevar1'==0")
      quietly `fr' replace `tmpname' = 0 if `iftv`i''
      if("`ci'" != "") {
        quietly `fr' replace `tmpname'_lci = 0 if `iftv`i''
        quietly `fr' replace `tmpname'_uci = 0 if `iftv`i''
      }
    
    }  
    if `"`expsurv'"' != "" & "`expsurvvars'" != "" {
      forvalues i = 1/`N_at_options' {
        local tmpname = word("`expsurvvars'",`i')
        quietly `fr' replace `tmpname' = 0 if `iftv`i''
      }
    }    
  }

  if "`contrast'" == "difference" {
    local j 1
    forvalues i = 1/`N_at_options' {
      if `i' == `atreference' continue  
      local vv = word("`contrast_varnames'",`j') 
      if "`timevar'" != "" {
        quietly `fr' replace `vv' = 0 if `iftv`i''
      }
      if "`ci'" != "" & "`timevar'" != "" {
        quietly `fr' replace `vv'_lci = 0 if `iftv`i''
        quietly `fr' replace `vv'_uci = 0 if `iftv`i''
      }
      local ++j
    }
  }

  if "`contrast'" == "ratio" {
    local j 1
    forvalues i = 1/`N_at_options' {
      if `i' == `atreference' continue    
      local vv = word("`contrast_varnames'",`j') 
      if "`timevar'" != "" {
        quietly `fr' replace `vv' = 1 if `iftv`i''
      }
      if "`ci'" != "" & "`timevar'" != "" {
        quietly `fr' replace `vv'_lci = 1 if `iftv`i''
        quietly `fr' replace `vv'_uci = 1 if `iftv`i''
      }
      local ++j
    }
  }
// label for over option
  if "`over'" != "" {
    forvalues i = 1/`N_at_options' {
      local tmpname = word("`at_varnames'",`i')
      `fr' label var `tmpname' `"`overlab`i''"'
    }
  }
  
// Warnings
  if "`centile'" != "" {
    foreach var in `at_varnames' {
      quietly count if (`var'>`maxt') & (`touse_centiles')
      if `r(N)'>0 {
        di as result "Warning: centile point estimate for `var' > maximum event time"
      }
      if "`ci'" != "" {
        quietly count if (`var'_uci>`maxt') & (`touse_centiles')
        if `r(N)'>0 {
          di as result "Warning: CI for centile for `var' > maximum event time"
        }  
      }
    }
  }
  
// Return stuff
  return local varmethod=cond("`mestimation'" == "","delta-method","M-estimation")
end

program define Parse_expsurv_options
  syntax [,  AGEDiag(varname)      ///
        EXPSURVVars(string)        ///
        DATEDiag(varname)          ///
        GENIND(string)             ///
        PMAGE(string)              ///
        PMMAXAge(integer 99)       ///
        PMMAXyear(integer 10000)   ///
        PMOTHER(string)            ///
        PMRATE(string)             ///
        PMYEAR(string)             ///
        SPLIT(real 1)              ///
        USING(string)              ///
        NENTER(real 30)            ///
        *                          ///
      ]

  
// using file
  capture qui desc using "`using'"
  if _rc {
    di as error "File `using' not found"
    exit 198
  }
  qui desc using "`using'", varlist
  local usingvarlist `r(varlist)'
  c_local popmortfile `using'  
  
  if "`datediag'" == "" {
    di as error "You need to specify the date of diagnosis"
    exit 198
  }
  else c_local datediag `datediag'
  
  
  if "`agediag'" == "" {
    di as error "You need to specify age at diagnosis using agediag()"
    exit 198
  }
  else c_local agediag `agediag'
  
  
  if "`pmrate'" == "" c_local pmrate rate
  else c_local pmrate `pmrate'
  if subinword("`usingvarlist'","`pmrate'","",1)=="`usingvarlist'" {
    di as error "`pmrate' not found in population mortality file"
    exit 198
  }

  if "`pmage'" == "" c_local pmage _age
  else c_local pmage `pmage'
  if subinword("`usingvarlis// ######## UPDATE for MSMODELSt'","`pmage'","",1)=="`usingvarlist'" {
    di as error "`pmage' not found in population mortality file"
    exit 198
  }
  
  if "`pmyear'" == "" c_local pmyear _year
  else c_local pmyear `pmyear'
  if subinword("`usingvarlist'","`pmyear'","",1)=="`usingvarlist'" {
    di as error "`pmyear' not found in population mortality file"
    exit 198
  }
  
  c_local pmother                 `pmother'
  c_local pmmaxage                `pmmaxage'
  c_local pmmaxyear               `pmmaxyear'
  c_local nenter                  `nenter'
  c_local split_pm                `split'
  c_local expsurv_genind_varnames `genind'  
  
  local optnum 1
  local end_of_ats 0
  local 0 ,`options'  
  while `end_of_ats' == 0 {
    capture syntax [,] AT`optnum'(string) [*]
    if _rc {
      local N_at_options = `optnum' - 1
      local end_of_ats 1
      continue, break
    }
    else local 0 ,`options'
    local optnum = `optnum' + 1
  }
  local N_at_options = `optnum' - 1
  if "`0'" != "," {
    di as error "Illegal option: `0'"
    exit 198
  }  
  local hasatoptions = `N_at_options' > 0
  if !`hasatoptions' local N_at_options 1

// Parse at() options  
  if `hasatoptions' > 0 {
    forvalues i = 1/`N_at_options' {
      tokenize `at`i''
      local at`i'opt  `1'    
  // parse "if" suboption
      while "`1'"!="" {
        if "`1'" == "." {
          local at`i'vars .
          continue, break
        }
        fvunab tmpfv: `1'
        local 1 `tmpfv'

        local at`i'vars `at`i'vars' `1'
        cap confirm num `2'
        if _rc {
          di as err "invalid at(... `1' `2' ...)"
          exit 198
        }
        if subinword("`usingvarlist'","`1'","",1)=="`usingvarlist'" {
          di as error "Error in at`i'() option" ///
                "`1' is not in population mortality  file"
          exit 198
        }        
        c_local at`i'pm_`1'_value `2'
        mac shift 2
      }
      c_local at`i'vars_pm `at`i'vars'
    }
  }
  
// expsurv names  
  c_local calcexpsurv = "`expsurvvars'" != ""
  c_local has_expsurv_genind = "`genind'" != ""
  c_local expsurvvars `expsurvvars'
  c_local N_at_options_pm `N_at_options'
  c_local hasatoptions_pm `hasatoptions' 
end

program define Parse_ODEoptions
  syntax  [,                                             ///
      abstol(real 1e-6)                                  ///
      error_control(real -99)                            ///
      initialh(real 1e-8)                                ///
      maxsteps(integer 1000)                             ///
      pgrow(real -0.2)                                   ///
      pshrink(real -0.25)                                ///
      reltol(real 1e-05)                                 ///
      safety(real 0.9)                                   ///
      tstart(real 1e-8)                                  ///
      verbose                                            ///
      ]

  if `error_control' == -99 {
    local error_control = (5/`safety')^(1/`pgrow') 
  }
      
  c_local ODE_abstol          `abstol'
  c_local ODE_reltol          `reltol'
  c_local ODE_maxsteps        `maxsteps'
  c_local ODE_initialh        `initialh'
  c_local ODE_safety          `safety'
  c_local ODE_pgrow           `pgrow'
  c_local ODE_pshrink         `pshrink'
  c_local ODE_error_control   `error_control'
  c_local ODE_tstart          `tstart'
  c_local ODE_verbose         `verbose'
end

program define standsurv_varlist_add_bn, rclass
  foreach v in `1' {
    _ms_parse_parts `v'
    if "`r(type)'" == "variable" {
      local varlist `varlist' `v'
      continue
    }
    else if "`r(type)'" == "interaction" {
      local vtmp `v'
      forvalues k = 1/`r(k_names)' {
        
        capture confirm integer number `r(op`k')'
        if !_rc local vtmp = subinstr("`vtmp'","`r(op`k')'.","`r(op`k')'bn.",.)
      }
      local varlist `varlist' `vtmp'
    }
    else {
      local vtmp = subinstr("`v'",".","bn.",.)
      local varlist `varlist' `vtmp'
    }
  }
  return local varlist `varlist' 
end

// extract frame options
program define getframeoptions
  syntax [anything], [replace merge mergecreate ]
  if wordcount("`replace' `merge'") >1 {
    di as error "Use only one of the replace and merge suboptions."
    exit 198
  }
  if wordcount("`merge' `mergecreate'") == 2 {
    di as error "You cannot use both merge and mergecreate suboptions."
    exit 198
  }
  if "`mergecreate'" != "" {
    mata: st_local("frameexists",strofreal(st_frameexists(st_local("anything"))))
    if `frameexists' {
      local merge merge
      c_local timevar // need this??
    }
  }

  if "`merge'" != "" {
    frame `anything' {
      notes _dir vars_with_notes
      local ntimevar 0 
      foreach v in `vars_with_notes' {
        notes _fetch tempnote : `v' 1
        if "`tempnote'" == "standsurv_timevar" {
          local ntimevar = `ntimevar' + 1
          if `ntimevar'>1 {
            di as error "More than one timevar in frame `anything', specify specific timevar with timevar() suboption"
            exit 198
          }
          local frametimevar `v'
        }
      }
      if `ntimevar' == 0 {
        di as error "Could not find an stpm3 timevar in frame `anything'"
        exit 198
      }
    }
  }
  c_local frametimevar   `frametimevar'
  c_local resframe       `anything'
  c_local framereplace   `replace'
  c_local framemerge     `merge'
end

// adapted from sts graph
program define GetGroupLabel, rclass
  syntax varlist [if] , 

  foreach var of local varlist {
    cap confirm numeric var `var'
    if _rc {                // string variable
      local ll = usubstr(`var'[`n'],1,20)
    }
    else {                  // numeric variable
      sum `var' `if', mean
      local ll `"`var' = `: label (`var') `=r(min)''"'
    }
    local lab `"`lab'`sep'`ll'"'
    local sep ": "
  } 
  return local label `"`lab'"'
end