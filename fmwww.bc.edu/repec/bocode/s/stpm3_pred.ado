*! version 1.11 2024-06-24

program stpm3_pred, sortpreserve
  version 16.1
  syntax [anything]   [if][in], [                     ///
                               ATReference(integer 1) ///
                               CENTile(string)        ///
                               CI                     ///
                               CIF                    ///
                               CONTrast(string)       ///
                               CONTRASTVars(string)   ///
                               CUMHazard              ///
                               CRMODels(string)       ///
                               EXPSurv(string)        ///
                               CRUDEProb              ///
                               FAILure                ///
                               FRAME(string)          ///
                               HAZard                 ///
                               LEVel(real `c(level)') ///
                               LNHAZard               ///
                               MERGE                  ///
                               ODE                    ///
                               ODEOPTions(string)     /// ODE integration options
                               noGEN                  /// do not generate at variables
                               noOFFset               ///
                               PER(real 1)            ///
                               RMST                   ///
                               RMFT                   ///
                               SE                     ///
                               SETBaseline            ///
                               SURVival               ///
                               /*TOFFset(string)*/    ///
                               CPNames(string)        ///
                               CRNames(string)        ///
                               TIMEVAR(string)        ///
                               XB                     ///
                               XBNOBaseline           ///
                               XBNOTime               ///
                               VERBOSE                ///
                               ZEROS                  /// (synonym for setbaseline)
                               *                      /// at options
                               ]
                                                                                                                                           

  local hasif = "`if'`in'" != ""        
  
  marksample touse, novarlist

  
  
  qui count if `touse'
  if r(N)==0 error 2000 

// addto this as more options are added
// number of options
  local centilenospace = subinstr("`centile'"," ","",.)

  local noptions = wordcount("`survival' `failure' `cumhazard' `rmft' `rmst' `xb' `xbnobaseline' `xbnotime' `hazard' `lnhazard' `crudeprob' `cif' `centilenospace'")
  if `noptions'>1 {
    di as error "Only one prediction option allowed."
    exit 198
  } 
  if `noptions' == 0 {
    di as error "You must specify the prediction type (e.g. survival,  hazard etc)."
    exit 198
  } 
  
  if "`xbnobaseline'" != "" local xbnotime xbnotime
 

// crmodels option
  tempname current_model
  if "`crmodels'" != "" {
    foreach m in `crmodels' {
      capture estimates describe `m'
      if _rc {
        di as error "Model `m' not found."
        exit 198
      }
    }
    local Nmodels = wordcount("`crmodels'")
    local modelslist `crmodels'
    estimates store `current_model'
    foreach m in `crmodels' {
      qui estimates restore `m'
      local allmodelvars `allmodelvars' `e(model_vars)'     
    }
    local allmodelvars: list uniq allmodelvars
    if "`crnames'" == "" local crnames `crmodels' 
    else {
      if wordcount("`crnames'") != `Nmodels' {
        di as error "crnames must contain `Nmodels' names"
        exit 198
      }
    }    
    qui estimates restore `current_model'
  }
  else {
    if "`cif'" != "" {
      di as error "cif option only available with competing risks using crmodels() option" ///
                _newline "Use failure option for 1-S(t)"
      exit 198
    }
    estimates store `current_model'
    local modelslist `current_model'
    local Nmodels 1
    local allmodelvars `e(model_vars)'
  }
  
  
  
// Parse various options
  if "`contrast'" != "" getcontrastoptions, `contrast'
  Parse_ODEoptions, `odeoptions'
  

  // centile option
  if "`centile'" != "" {
    //if "`e(scale)'" == "lnhazard" & "`ci'" != "" {
    //  di as err "CIs not currently available for centiles for scale(lnhazard) models."
    //  exit 198
    //}
    Parse_centile_options `centile'
  }
// get variable type (factor or variable)
  get_variable_type  
  
// Extract at() options
  if "`zeros'" != "" local setbaseline setbaseline
  local allsetbaseline `setbaseline'
  local setbaseline
  local optnum 1
  local end_of_ats 0
  local 0 ,`options'
  while `end_of_ats' == 0 {
    capture syntax [,] AT`optnum'(string) [*]
    if _rc {
      local Natoptions = `optnum' - 1
      local end_of_ats 1
      continue, break
    }
    local 0 ,`options'
    local optnum = `optnum' + 1
  }
  local Natoptions = `optnum' - 1
  if "`0'" != "," {
    di as error "Illegal option: `0'"
    exit 198
  }

  local hasatoptions = `Natoptions' > 0
  if !`hasatoptions' {
  	local Natoptions 1
    local at1 .
  }
  
  
  // nogen option
  if "`gen'" != "" {
    if "`contrast'" == "" {
      di as error "Only use the nogen option when in combination with the contrast option."
      exit 198
    }
    if "`anything'" != "" {
      di as error "You have given variable names to generate, but also asked not to generate them."
      exit 198
    }
  }  

// frames
  if "`merge'" != "" & "`frame'" != "" {
    di as error "You cannot use both of the merge and frame options."
    exit 198
  }
  if "`merge'" == "" {
    getframeoptions `frame'
    if "`resframe'" == "" local resframe stpm3_pred
    mata: st_local("frameexists",strofreal(st_frameexists(st_local("resframe"))))
  }     
  
  if "`timevar'" == "" & "`centile'" == "" {
    local notimevaropt notimevaropt
    local timevar _t
    if "`frame'" == "" {
      local merge merge
      local resframe
    }
  }    
  
  if "`resframe'" != "" {
    if `frameexists' & "`framereplace'" == "" & "`framemerge'" == "" {
      di as error "Frame `resframe' exists. Use replace, merge suboptions or another framename."
      exit 198
    }
    else if `frameexists' & "`framereplace'" != "" capture frame drop `resframe'
    if !`frameexists' & "`framemerge'" != "" {
      di as error "Cannot merge to a non-existant frame"
      exit 198
    }
    if "`framemerge'" != "" & "`notimevaropt'" == "" {
      di as error "Do not specify timevar() when using frame(.., merge)"
      exit 198
    }
    if "`framemerge'" != "" & `hasif' {
      di as error "Do not use if/in with framemerge"
      exit 198
    }
  }
  
  tempvar t lnt 
  
  if "`timevar'" != "" stpm3_Parsetimevar `timevar' 
  else local timevalues 0
  local hastimevar = `timevalues'==0 & "`centile'" == ""
  //if `timevalues' {
  //  if ("`timevalues_to'" == "`timevalues_from'") {
  //    tempvar tt 
  //    local timevalues_gen `tt'
  //  }
  //  //if "`timevalues_single'" == "" {
  //  //  qui gen `timevalues_gen' = `timevalues_from' if `touse'
  //  //} 
  // // else qui gen `timevalues_gen' = `timevalues_from' in 1 
  // // local timevar `timevalues_gen'
  //}
  

  
// Parse at() options
  forvalues i = 1/`Natoptions' {
// parse "if" & "indweights" suboptions
    tokenize "`at`i''", parse(",")
    local at`i'opt  `1'
    if "`1'" == "" | "`1'" == "," {
      di as error "An at option can't be empty" ///
          "Use . to predict for observed covariate pattern"
      exit 198  
    }
    local 0 `2'`3'
    syntax ,[ATIF(string) ATTIMEVAR(string) SETBasline ZEROS OBSvalues IGNORE TOFFset(string)]    // could add atmean option??
    if "`zeros'" != "" local setbaseline setbaseline
    if `hasif' & `"`atif'"' != "" {
      di as error "You can either use an if statement or the atif() suboptions" _newline ///
            "of the at() options, but not both"
      exit 198
    }
    tempvar touse_at`i'
    if `"`atif'"' == "" {
      qui gen byte `touse_at`i'' = `touse'
    }
    else {
      qui gen byte `touse_at`i'' = (`atif')
    }
    if "`ignore'" != "" {
      local ignore`i' ignore`i'
    }
// attimevar
    if "`notimevaropt'" == "" & "`attimevar'" != "" {
        di as error "You can't specify both the attimevar() at suboptions" ///
                    "with the main timevar() option."
        exit 198
    }       
    if "`attimevar'" != "" {
      stpm3_Parsetimevar `attimevar' if `touse', atn(`i')
      if `timevalues`i'' & "`merge`" != "" {
        if ("`timevalues`i'_to'" == "`timevalues`i'_from'") {
          tempvar tt`i'
          local timevalues`i'_gen `tt`i''
        }     
        local hastimevar 0
      }
      else {
        local timevar`i' `attimevar'
        local hastimevar 1          
      }
    }
    
    if "`centile'" != "" {
      local timevar`i' `attimevar'
      local hastimevar 1
    }
    else if "`centile'" == "" {
      if `timevalues' == 1 {
        local timevalues`i'_from    `timevalues_from' 
        local timevalues`i'_to      `timevalues_to'   
        local timevalues`i'_n       `timevalues_n'    
        local timevalues`i'_step    `timevalues_step' 
        local timevalues`i'_gen     `timevalues_gen'  
        local timevalues`i'_single  `timevalues_single'    
        local timevalues`i' 1
        local hastimevar 0
        if "`merge'" != "" confirm new variable `timevalues`i'_gen'
      }
      else {
        local timevalues`i' 0
        if "`attimevar'"== "" local timevar`i' `timevar'
        local hastimevar 1
      }
    }

// setbaseline/zeros    
    if "`setbaseline'" != "" & "`allsetbaseline'" != "" {
      di as error "You can't specify both the setbasline/zeros main option and setbasline/zeros suboption"
      exit 198
    }
    local setbaseline`i' `allsetbaseline'`setbaseline'

// observed values
    if "`obsvalues'" != "" local obsvalues`i' obsvalues`i'
    
// toffset option
  if "`toffset'" != "" {
    //if `Nmodels'==1 {
      //di as error "toffset option only used with more than one model."
      //exit 198
    //}
    if wordcount("`toffset'") != `Nmodels' {
      di as error "the number of arguments in the toffset() option should be the same as the number of models"
      di as error "Use . (or 0) if you want to use the main timescale"
      exit 198
    }    
    local j 1
    foreach toff in `toffset' {
      if "`toff'" == "." local toffset`i'_m`j' = 0
      else {
        capture confirm number `toff'
        if _rc {
          di as error "Invalid numeric value in toffset() option)"
          exit 198
        }
        else local toffset`i'_m`j' `toff'
      }
      local j = `j' + 1
    }
    local hastoffset 1
  }
  


// main at option
    local at`i'opt = subinstr("`at`i'opt'","="," = ",.)
    tokenize `at`i'opt'
    while "`1'"!="" {
      if "`1'" == "." {
        local obsvalues`i' obsvalues`i'
        continue, break
      }
      if "`1'"=="" continue, break
      
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
        if "``1'_type'" == "factor" {
          // commented out, but now not checking if factor level not possible
          //_ms_extract_varlist `2'.`1'  // check legitimate level (could move)
        }
        mac shift 2
        
      }
      else {
        cap confirm var `3'
        if _rc {
          di as err "variable `3' is not in the data set"
          exit 198
        }        
        local at`i'_`1'_value .
        local at`i'_`1'_variable `3'
        mac shift 3
      }
    }
     //local timevarlist `timevarlist' `timevar`i''
  }
  //local hastimevar = "`timevar1'" != "" & `timevalues' == 1 
  //if "`centile'" == "" {
  //  if "`timevalues1_from'" == "" & "`timevar1'" == "" & "`framemerge'" ==""  {
  //    di as err "The timevar() option must be specified (or use frame(.., merge))."
  //    exit 198
  //  }
  //}
  
// whether derivatives of spines varaibles are required
  local needsquadrature 0
  if `Nmodels' == 1 {
    if("`e(scale)'" == "lncumhazard")    {
      local needsode = wordcount("`rmst'`rmft'`crudeprob'`centilenospace'") == 1 | "`ode'" != ""
      if "`hastoffset'" != "" & wordcount("`survival'`failure'") == 1 local needsode 1
      local needsdxb1 = "`hazard'`lnhazard'" != "" | `needsode'
    }
    else if("`e(scale)'" == "lnhazard")  {
      //local needsode = wordcount("`survival'`failure'`cumhazard'`rmst'`rmft'`crudeprob'`centilenospace'") == 1
      local needsode = wordcount("`rmst'`rmft'`crudeprob'") == 1 | "`ode'" != ""
      if !`needsode' {
        if wordcount("`survival'`failure'`cumhazard'`centilenospace'") == 1 {
          local needsquadrature 1
        }
      }
      local needsdxb1 0
    }
    else if("`e(scale)'" == "lnodds")   {
      local needsode = wordcount("`rmst'`rmft'`centilenospace'") == 1 | "`ode'" != ""
      local needsdxb1 = "`hazard'`lnhazard'" != "" | `needsode'    
    }
    else if("`e(scale)'" == "probit")   {
      local needsode = wordcount("`rmst'`rmft'`centilenospace'") == 1 | "`ode'" != ""
      local needsdxb1 = "`hazard'`lnhazard'" != "" | `needsode'    
    }    
  }
  else {
    local needsode 1
    if inlist("`e(scale)'","lncumhazard","lnodds","probit") local needsdxb 1
  }
  
  
  if "`atreference'" != "1" {
    capture numlist "`atreference'", min(1) max(1) range(>0)
    if _rc {
      di as error "Illegal atreference() option."
      exit 198
    }    
    if `atreference'>`Natoptions' {
      di as error "atreference() option is greater than number of at options."
      exit 198
    }
  }
  
  // Expected survival
  if `"`expsurv'"' != "" {
    if "`e(bhazard)'" == "" {
      di as error "you can only use expsurv() with relative survival models"
      exit 198
    }    
    if "`cpnames'" == "" local cpnames d o 
    else {
      if wordcount("`cpnames'") != 2 {
        di as error "cpnames must contain two names"
        exit 198
      }
    }
    Parse_expsurv_options, `expsurv' natoptions(`Natoptions')
  }
  else {
    if "`crudeprob'" != "" {
      di as error "crudeprob option probabilities only applicable when using expsurv() option."
      exit 198
    }
    if "`cpnames'" != "" {
      di as error "cpnames option probabilities only applicable when using expsurv() option."
      exit 198
    }    
  }
  /// add check that timevars are of same length **********************
  /// ** FINISH THIS **
  //if `hastimevar' {
  //  tempvar touse_timevar
  //  qui gen `touse_timevar' = !missing(`timevar1')
  //}

  // check at options are legal ( would need to check both models)
  forvalues i = 1/`Natoptions' {
    if "`setbaseline`i''" != "" | "`obsvalues`i''" != "" continue
    foreach v in `allmodelvars' {
      if strpos("`at`i'vars'","`v'") == 0 {
        di as error "Variable `v' has not been given a value." _newline ///
                    "Either give a value or use the setbaseline or obsvalues suboptions."
        exit 198
      }
    }
  }
//////////////////////////////////////
//  create frame for each at option //
//////////////////////////////////////
  if "`verbose'" != "" di "Creating at frames"
  forvalues i = 1/`Natoptions' {
    if "`centile'" == "" {
      tempvar timevartmp`i' touse_timevar`i'
    }
    else {
      tempvar cenvartmp`i' touse_centile`i'
    }
    // add variable whne using "=" in at option
    foreach v in `at`i'vars' {
      local extra_at_vars `extra_at_vars' `at`i'_`v'_variable'
    }
    // add variable listed in at, but not in model_vars
    local atvars_not_in_model
    foreach v in `at`i'vars' {
      if strpos("`allmodelvars'","`v'") == 0 {
        local atvars_not_in_model `atvars_not_in_model' `v'
      }
    }
    if "`centile'" == "" {
      if "`framemerge'" == "" & `timevalues`i'' {
        local nopt = cond("`timevalues`i'_n'"!="","n(`timevalues`i'_n')","")
        local stepopt = cond("`timevalues`i'_step'"!="","step(`timevalues`i'_step')","")
        timevalues_gen  `timevartmp`i'' if `touse_at`i'', from(`timevalues`i'_from') ///
                                                    to(`timevalues`i'_to')     ///
                                                    `nopt' `stepopt' `timevalues`i'_single'
      }
    }
    else {
      if "`centype'" == "numlist" {
        Numlist_to_var `cenvartmp`i'', nlist("`centile'")
      }
      else if "`centype'" == "variable" {
        qui gen `cenvartmp`i'' = `centvar'
        //local centvar`i' `centvar'
      }
    }
    //think about centile issue
    if "`framemerge'" != "" {
      tempvar linkvar tmpid
      gen `tmpid' = _n
      frame `resframe': gen `tmpid' = _n
      qui frlink 1:1 `tmpid', frame(`resframe') gen(`linkvar')
      qui gen `timevartmp`i'' = frval(`linkvar', `frametimevar')
    }
    if "`centile'" == "" {
      if `timevalues`i''==0 & "`framemerge'" == "" local timevartmp`i' `timevar`i''
      gen `touse_timevar`i'' = !missing(`timevartmp`i'') & `touse'
      local timevarlist `timevarlist' `timevartmp`i''
    }
    else {
      gen `touse_centile`i'' = !missing(`cenvartmp`i'')
      local centilelist `centilelist' `cenvartmp`i''
      local centvar`i' `centvar'
      local centilewritelist `centilewritelist' `centvar`i''
    }
    // age at diagnosis
    local allpmvars `agediag`i'_var' `datediag`i'_var' `pmother' 
    tempvar tousetmp
    local tousetmp = cond("`centile'"=="","`touse_timevar`i''","`touse_centile`i''")

    forvalues m = 1/`Nmodels' {
      tempname atframe`i'_m`m'
      qui estimates restore `=word("`modelslist'",`m')'
      if "`ignore`i''" != "" {
        local add_atvars_not_in_model `atvars_not_in_model'
      }
      frame put `timevartmp`i'' `cenvartmp`i'' `allmodelvars' `extra_at_vars' ///
                `add_atvars_not_in_model' `allpmvars' if `tousetmp' & `touse', into(`atframe`i'_m`m'')
      frame `atframe`i'_m`m'' {
        local Nat`i' = _N
        foreach v in `at`i'vars' {
          if `at`i'_`v'_value' != . {
          //check_factor `v', `value'    // not yet working
            qui replace `v' =  `at`i'_`v'_value'
          }
          else qui replace `v' =  `at`i'_`v'_variable'
        }
        if `"`expsurv'"' != "" {
          if "`agediag`i'_val'" != "" {
            tempvar tmpagediag`i'
            gen `tmpagediag`i'' = `agediag`i'_val'
            local agediag`i' `tmpagediag`i''
          }
          else local agediag`i' `agediag`i'_var'
          if "`agediag`i'_var'`agediag`i'_val'" == "" {
            di as error "Age at diagnosis not specified within expsurv()."
            exit 198
          }
          if "`datediag`i'_val'" != "" {
            tempvar tmpdatediag`i'
            gen `tmpdatediag`i'' = `datediag`i'_val'
            local datediag`i' `tmpdatediag`i''
          }
          else local datediag`i' `datediag`i'_var'
          if "`datediag`i''" == "" {
            di as error "date of diagnosis not specified within expsurv()."
            exit 198
          }
        }
     
        if "`setbaseline`i''" != "" {
          foreach v in `e(model_vars)' {
            if `"`: list posof `"`v'"' in at`i'vars'"' == "0" { 
              if "``v'_type'" == "factor" {
                qui replace `v' = ``v'_baseline'
              }
              else if strpos("`e(ef_varlist)'","`v'") & "`e(ef_`v'_center1)'" != "" {
                qui replace `v' = `e(ef_`v'_center1)'
              }
              else qui replace `v' = 0
            }
          }
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
        
      // splines
      // *********************TVC********************
        local ttransopt = cond("`e(ttrans)'"=="lnt","lntime","")
        if "`e(tvc)'" != "" {
          if `e(sharedtvc_knots)' {
            if "`e(knots_tvc)'" != "" local tvcopt tvc(`e(tvc)') allknotstvc(`e(knots_tvc)', `ttransopt')
            else local tvcopt tvc(`e(tvc)') dftvc(1)
          }
          else {
            local tvcopt tvc(`e(tvc)') allknotstvc(
            foreach v in `e(tvcvars)' {
              local tvcopt `tvcopt' `v' `e(knots_tvc_`v')'
            }
            local tvcopt `tvcopt' , `ttransopt')
          }
        }
        else local tvcopt
        
        local knotsopt = cond("`e(knots)'"!="","allknots(`e(knots)', `ttransopt')","df(1)")
      
      // splines needs to be genereated when using centiles
      // use midpoint
        if "`centile'" != "" {
          tempvar timevartmp`i'
          gen `timevartmp`i'' = 1
        }
      
        if "`hastoffset'" != "" local toffsetopt toffset(`toffset`i'_m`m'')


        stpm3_gensplines, `knotsopt' `tvcopt'               ///
                          type(`e(splinetype)') hasdelentry(0)     ///
                          ttrans(`e(ttrans)') degree(`e(degree)')  ///
                          timevar(`timevartmp`i'') scale(`e(scale)') ///
                          `toffsetopt'
        tempvar tnot0_`i'
        qui gen byte `tnot0_`i'' = `timevartmp`i''>0
        local tnot0list `tnot0list' `tnot0_`i''                          
 
        if "`e(constant)'" == "" { 
          tempvar cons`i'_m`m'
          gen `cons`i'_m`m'' = 1
        }
      }
    }
  }
// varlists for reading X_at matrics   
// Need to extract varlist with atframe works for out of sample predictions
// only need to do once, so use at1().

// NEED TO LOOP OVER MODELS HERE



  forvalues m = 1/`Nmodels' {
    qui estimates restore `=word("`modelslist'",`m')'
    frame `atframe1_m`m'' { 
      _ms_lf_info
      local hasvarlist`m' = `r(k_lf)'==2
      if `hasvarlist`m'' {
        local varlist_xb`m'      `r(varlist1)'
        local varlist_time`m'    `r(varlist2)'
        _ms_extract_varlist `varlist_xb`m'', eq(xb) noomitted nofatal
        stpm3_pred_varlist_add_bn "`r(varlist)'"
        local varlist_xb`m' `r(varlist)'
      }
      else local varlist_time`m' `r(varlist1)'
      _ms_extract_varlist `varlist_time`m'', eq(time) noomitted nofatal
      stpm3_pred_varlist_add_bn "`r(varlist)'"
      local varlist_time`m' `r(varlist)' 
    
      stpm3_pred_varlist_add_bn "`e(dsplinevars)'"
      local dsplinevars`m' `r(varlist)'
    }
    local scale`m'          `e(scale)'
    local ttrans`m'         `e(ttrans)'
    local splinetype`m'      `e(splinetype)'
    local df`m'             `e(dfbase)'
    local degree`m'         `e(degree)'
    local knots`m'          `e(knots)'
    ///***********************TVC******************************
    local knots_tvc`m'      `e(knots_tvc)'     
    local splinelist_tvc`m' `e(splinelist_tvc)'
    local splinevars_tvc`m' `e(splinevars_tvc)'


    local dftvc`m' = wordcount("`splinevars_tvc`m''") // update when separate knots
    
    local hastvc`m' = "`e(tvc)'" != ""
    local hasoffset`m' = "`e(offset)'" != ""    
    local hasconstant`m' = "`e(constant)'" == ""

    tempname beta`m' V`m' timebeta`m'
    matrix `beta`m'' = e(b)
    matrix `V`m'' = e(V)
    matrix `timebeta`m'' = `beta`m''[1,"time:"]
    
    // column location of time-dependent effects - needed for ODE
    if "`e(tvc)'" != "" {
      if `e(sharedtvc_knots)' {
        local j 1
        foreach v in `e(tvc_included)' {
          foreach tv in `e(splinevars_tvc)' {
            local tvccol`m'`j' `tvccol`m'`j'' `=colnumb(`timebeta`m'',"`v'#c.`tv'")'
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
            local tvccol`m'`j' `tvccol`m'`j'' `=colnumb(`timebeta`m'',"`v'#c.`tv'")'
          }
          local ++j
        }
      }
    }   

    
// list of actual used tvcvars needed for ODE & centiles
//*********************** TVC*****************************
    if "`e(tvc)'" != "" {
      local vtemp
      foreach v in `e(splinelist_tvc)' {
        _ms_parse_parts `v'
        if "`r(type)'" == "interaction" {
          local vtmp = subinstr("`v'","#c.`r(name`r(k_names)')'","",.)
          local vtemp `vtemp' `vtmp'
        }
      }  
      local tvc_ode`m': list uniq vtemp
      stpm3_pred_varlist_add_bn "`tvc_ode`m''"
      local tvc_ode`m' `r(varlist)'
    }

// omitted variables  
    tempname omit`m'
    _ms_omit_info e(b)  
    matrix `omit`m'' = r(omit)
  }

  // Restore active model
  qui estimates restore `current_model'
  
// frame for results
  if "`merge'" == "" {  
    if "`framemerge'" == "" {
      if /*`hastimevar' &*/ "`centile'" == "" {
        frame put `timevarlist' `framecopy' `touse' if `touse_timevar1' & `touse', into(`resframe')
        local timevarfinal `timevarlist'
        //local uniqtimevar: list uniq timevarlist
        //foreach tv in `uniqtimevar' {
        //  di "bob: `tv'"
        //  note `tv': stpm3_timevar
        //}
      }
      else if "`centype'" == "variable" {
        frame put `centilewritelist' `framecopy' if `touse_centile1' & `touse', into(`resframe')
      }
      else if "`centype'" == "numlist" frame create `resframe'
    }
    else {
      forvalues i = 1/`Natoptions' {
        local timevar`i' `frametimevar'
        local timevarfinal `timevarfinal' `timevar`i''
      }
    } 

    frame `resframe' {
      forvalues i = 1/`Natoptions' {
        if "`centile'" == "" {
          //if `timevalues`i''==1 & "`framemerge'"=="" {
          //  local nopt = cond("`timevalues`i'_n'"!="","n(`timevalues`i'_n')","")
          //  if "`nopt'" == "" & ("`timevalues`i'_from'"=="`timevalues`i'_to'") local nopt n(`Nat`i'')
          //  local stepopt = cond("`timevalues`i'_step'"!="","step(`timevalues`i'_step')","")
          //  capture confirm variable `timevalues`i'_gen'
          //  if _rc {
          //    timevalues_gen `timevalues`i'_gen', from(`timevalues`i'_from') ///
          //                                          to(`timevalues`i'_to')     ///
          //                                          `nopt' `stepopt' `timevalues`i'_single'
          //  }
          //  local timevar`i' `timevalues`i'_gen'
          //  local timevarfinal `timevarfinal' `timevar`i''          
          // }

          if `timevalues`i''==1 & "`framemerge'"=="" {
            capture confirm var `timevalues`i'_gen' 
            if _rc {
              gen `timevalues`i'_gen' = `timevartmp`i''
            }
            local timevar`i' `timevalues`i'_gen'
            local timevarfinal `timevarfinal' `timevar`i''
          }

          if "`framemerge'" == "" local addtouse & `touse' 
          tempvar tnot0_`i'
          gen byte `tnot0_`i'' = `timevar`i''>0 & !missing(`timevar`i'') `addtouse'
          local results_write `results_write' `tnot0_`i''     
          local uniqtimevar: list uniq timevarfinal

          foreach tv in `uniqtimevar ' {
            notes _fetch tmpnote : `tv' 1
            if "`tmpnote'" == "" note `tv': stpm3_timevar
          }    
        }
        else {
          if "`centype'" == "numlist" {
            if _N==0 qui set obs `=wordcount("`centile'")'
            capture confirm variable `centvar'
            if _rc Numlist_to_var `centvar', nlist("`centile'")
            tempvar cenwrite`i'
            gen byte `cenwrite`i'' = !missing(`cenvar')
            local results_write `results_write' `cenwrite`i''
          }
          else if "`centype'" == "variable" {
            tempvar cenwrite`i'
            gen byte `cenwrite`i'' = !missing(`cenvar')
            local results_write `results_write' `cenwrite`i''
          }
        }
      }
      if "`gen'" == "" _stubstar2names `anything', nvars(`Natoptions')  
      local newvarlist `s(varlist)'
      if "`pmhasexpvars'" != "" {
        capture _stubstar2names `expvars', nvars(`Natoptions')  
        if _rc {
          di as error "Error with expvars() suboption of expsurv() option"
          exit 198
        }        
        local expvars `s(varlist)'
      }     

      if "`contrast'" != "" {
        if "`contrastvars'" == "" {
          if `Nmodels' == 1 | "`survival'`failure'" != "" {
            forvalues i = 1/`Natoptions' {
              if `i' == `atreference' continue
              local contrastvars `contrastvars' _contrast`i'_`atreference'
            }
          }
          else if `Nmodels' > 1 {
            foreach m in `crnames' {
              forvalues i = 1/`Natoptions' {
                if `i' == `atreference' continue
                local contrastvars `contrastvars' _contrast`i'_`atreference'_`m'
              }
            }
          }
        }
        capture _stubstar2names `contrastvars', nvars(`=`Natoptions'-1')
        if _rc {
          local oldrc = _rc
          di as error "Error with contrastvars option"
          error `oldrc'
        }
        if `Nmodels' == 1 | "`survival'`failure'" != "" local contrastvars `s(varlist)'
        else {
          local contrastvars
          foreach c in `s(varlist)' {
            foreach m in `crnames' {
               local contrastvars `contrastvars' `c'_`m'
            }
          }
        }
      }
    }
  }
  else {
    forvalues i = 1/`Natoptions' {
      tempvar tnot0_`i'
      if !`hastimevar' {
        if "`centile'" == "" {
          capture confirm variable `timevalues`i'_gen', exact
          if _rc {        
            //local nopt = cond("`timevalues`i'_n'"!="","n(`timevalues`i'_n')","")
            //local stepopt = cond("`timevalues`i'_step'"!="","step(`timevalues`i'_step')","")
            //timevalues_gen `timevalues`i'_gen', from(`timevalues`i'_from') ///
            //                                    to(`timevalues`i'_to')     ///
            //                                    `nopt' `stepopt' `timevalues`i'_single'
            capture confirm var  `timevalues`i'_gen' 
            if _rc {
              gen `timevalues`i'_gen' = `timevartmp`i''
            }
            local timevar`i' `timevalues`i'_gen'
            //local timevarfinal `timevarfinal' `timevar`i''
          }
		  else {
		  	local timevar`i' `timevalues`i'_gen'
		  }
        }
        else {
          if "`centype'" == "numlist" {
            if _N==0 qui set obs `=wordcount("`centile'")'
            capture confirm variable `centvar'
            if _rc Numlist_to_var `centvar', nlist("`centile'") 
          }
        }
      }
      if "`centile'" == "" {
        local timevarfinal `timevarfinal' `timevar`i''     
        gen byte `tnot0_`i'' = `timevar`i''>0 & !missing(`timevar`i'') & `touse'
        local results_write `results_write' `tnot0_`i''
      }
      else {
        tempvar cenwrite`i'
        if "`centype'" == "numlist" {
          capture confirm var `centvar`i''
          if _rc gen `centvar`i'' = `cenvartmp`i''
        }
        gen byte `cenwrite`i'' = !missing(`centvar`i'')
        local results_write `results_write' `cenwrite`i''
      }
      if "`gen'" == "" _stubstar2names `anything', nvars(`Natoptions')  
      local newvarlist `s(varlist)'
      if "`pmhasexpvars'" != "" {
        capture _stubstar2names `expvars', nvars(`Natoptions')
        if _rc {
          di as error "Error with expvars() suboption of expsurv() option"
          exit 198
        }
        local expvars `s(varlist)'
      }      
    }
    
    if "`contrast'" != "" {
      if "`contrastvars'" == "" {
        if `Nmodels' == 1 {
          forvalues i = 1/`Natoptions' {
            if `i' == `atreference' continue
            local contrastvars `contrastvars' _contrast`i'_`atreference'
          }
        }
        else if `Nmodels' > 1 {
          foreach m in `crnames' {
            forvalues i = 1/`Natoptions' {
              if `i' == `atreference' continue
              local contrastvars `contrastvars' _contrast`i'_`atreference'_`m'
            }
          }
        }
      }
      capture _stubstar2names `contrastvars', nvars(`=`Natoptions'-1')
      if _rc {
        local oldrc = _rc
        di as error "Error with contrastvars option"
        error `oldrc'
      }
      if `Nmodels' == 1 | "`survival'`failure'" != "" local contrastvars `s(varlist)'
      else {
        local contrastvars
        foreach c in `s(varlist)' {
          foreach m in `crnames' {
             local contrastvars `contrastvars' `c'_`m'
          }
        }
      }
    }
  }
  // ******** NEED SOME SORT OF CHECK HERE to see if timevar the same *******

  
  // frame for popmort file
  // will only read in necessary ages and years
  if `"`expsurv'"' != "" {
    local minage 100
    local maxattage 0
    local minyear 3000
    local maxattyear 0
    forvalues i = 1/`Natoptions' {
      tempvar attage`i' yeardiag`i' attyear`i'

      if "`agediag`i'_val'" == "" {
        summ `agediag`i'' if `touse', meanonly
        local minage = min(floor(`r(min)'),`minage')
        qui gen `attage`i'' = `agediag`i'' + `timevartmp`i'' + 1 if `touse'
        summ `attage`i'' if `touse', meanonly
        local maxattage = min(max(ceil(`r(max)'),`maxattage'),`pmmaxage')
      }
      else {
        local minage = min(`agediag`i'_val',`minage')
        qui gen `attage`i'' = `agediag`i'_val' + `timevartmp`i'' + 1 if `touse'
        summ `attage`i'' if `touse', meanonly
        local maxattage = min(max(ceil(`r(max)'),`maxattage'),`pmmaxage')        
      }

      if "`datediag`i'_val'" == "" {
        qui gen `yeardiag`i'' = year(`datediag`i'_var') if `touse'
        summ `yeardiag`i'' if `touse', meanonly
        local minyear = min(`r(min)',`minyear')
        qui gen `attyear`i'' = year(`datediag`i'_var' + (`timevartmp`i'' + 1)*365.25)  if `touse'
        summ `attyear`i'' if `touse', meanonly
        local maxattyear = min(max(`r(max)',`maxattyear'),`pmmaxyear')
      }
      else {
        local minyear = min(year(`datediag`i'_val'),`minyear')
        qui gen `attyear`i'' = year(`datediag`i'_val' + (`timevartmp`i'' + 1)*365.25)  if `touse'
        summ `attyear`i'' if `touse', meanonly
        local maxattyear = min(max(`r(max)',`maxattyear'),`pmmaxyear')      
      }
    }
    tempname popmortframe
    frame create `popmortframe'
    frame `popmortframe' {
      qui use "`popmortfile'" if inrange(`pmage',`minage',`maxattage') &   ///
	                               inrange(`pmyear',`minyear',`maxattyear')   
      summ `pmage', meanonly
      if `maxattage'>`r(max)' {
        di as error "Maximum attained age is greater than maximum age in popmort file."
        di as error "Consider using the pmmaxage() option."
        exit 198
      }
      summ `pmyear', meanonly
      if `maxattyear'>`r(max)' {
        di as error "Maximum attained year is greater than maximum year in popmort file."
        di as error "Consider using the pmmaxyear() option."
        exit 198
      }      
    }
  }
  
  mata: stpm3_pred()

  if "`resframe'" != "" di as text "Predictions are stored in frame - `resframe'"

  // additions for t=0
  stpm3_pred_addt0 `newvarlist', `xb'`survival'`failure'`cumhazard'`crudeprob'`cif'`rmst'`rmft' ///
                                 `ci' frame(`resframe') timevars(`timevarfinal') ///
                                 per(`per') expvars(`expvars') crnames(`crnames') ///
                                 `gen'
                                 
  // Warning if centiles out of range                                 
  if "`centile'" != "" {
    stpm3_Check_Centile, atvars(`newvarlist') `ci' cenlow(`cenlow') cenhigh(`cenhigh') ///
                         frame(`resframe') 
  }                                
                                 
                                 
end  
  
////////////////////////////////////////////
// Parsetimevalues                        //
// parse timevalues option                //
////////////////////////////////////////////

program define stpm3_Parsetimevar
  syntax anything [if][in], [n(string) STep(string) gen(string) single atn(integer 0)]
  
  marksample touse
  if "`atn'" == "0" local atn
  capture confirm variable `anything'
  if _rc {
    capture numlist "`anything'"
    if _rc {
      di as error "timevar() option incorrectly specified. You need to supply" ///
                   " a variable or a numlist"
      exit 198
    }
    
    local timevalues 1
  }
  else local timevalues 0

  if `timevalues' {
    numlist "`anything'", ascending min(1) max(2) range(>=0)
  
    local single_time = wordcount("`anything'") == 1
    if `single_time' == 1 {
      if "`step'" != "" {
        di as error "step() suboption can not be used for single timepoints."
        exit 198 
      }
      if "`n'" != "" {
        di as error "n() suboption can not be used for single timepoints."
        exit 198 
      }
      if "`gen'" != "" {
        di as error "You can't use gen with timevalues with a single time point"
        exit 198
      }
      c_local timevalues`atn'_from   = word("`anything'",1)
      c_local timevalues`atn'_to     = word("`anything'",1) 
      c_local timevalues`atn'_single `single'
    }
    
    else {
      c_local timevalues`atn'_from = word("`anything'",1)
      c_local timevalues`atn'_to   = word("`anything'",2)
      if "`n'" != "" & "`step'" != "" {
        di as error "Only one of the n() and step() suboptions can be specified in timevalues option."
        exit 198
      }
      if "`single'" != "" {
        di as error "You can't use the single suboption when specifying a range"
        exit 198
      }
      if "`step'" == "" & "`n'" == "" local n 100 // default n
    }
    if "`gen'" == "" local gen tt
    c_local timevalues`atn'_n    `n'
    c_local timevalues`atn'_step `step'
    c_local timevalues`atn'_gen  `gen'
  }
  c_local timevalues`atn' `timevalues'
end

/////////////////////////////////////////////
// timevalues_gen                          //
// generate timevar for timevalues option  //
/////////////////////////////////////////////
program define timevalues_gen
  syntax anything [if][in], from(string) to(string) [n(string) step(string) single]
  local gen `anything'
  marksample touse
  if "`from'"=="`to'" {
    if "`single'" == "" {
      if "`n'" != "" set obs `n'
      qui gen `gen' = `from' if `touse'
    }
    else {
      set obs 1
      qui gen `gen' = `from' in 1
    }
  }
  else {
    if "`step'" == "" qui range `gen' `from' `to' `n'
    else {
      local n = ceil(1 + (`to' - `from')/`step')      
      qui if `n'>_N set obs `n'
      qui gen `gen' = min(`from' + (_n -1) *(`step'),`to') if _n<=`n'
    }
  }
end
  
// extract frame name and replace option  
program define getframeoptions
  syntax [anything], [replace merge mergecreate   copy(string)]
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
      c_local timevar
    }
  }
  if "`merge'" != "" {
    frame `anything' {
      notes _dir vars_with_notes
      local ntimevar 0 
      foreach v in `vars_with_notes' {
        if "`v'" == "_dta" continue
        notes _fetch tempnote : `v' 1
        if "`tempnote'" == "stpm3_timevar" {
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
  c_local framecopy      `copy'
end

////////////////////////////////////////////////////////////
// get_variable_type                                      //
// program to extract variables type (factor or variable) //
// also defines baselevel for factor variables            //
////////////////////////////////////////////////////////////

program define get_variable_type
  local fvnames : colfullnames e(b)

  foreach var in `fvnames' {
    _ms_parse_parts `var'
    if `r(omit)' continue
    if inlist("`r(type)'","factor","variable") {
      if strpos("`allvars'","`r(name)'") >0 {
        check_mixed_variable_type `r(type)' ``r(name)'_type'
      }
      local `r(name)'_type `r(type)'
      local allvars `allvars' `r(name)'
    } 
    else if "`r(type)'" == "interaction" {
      forvalues k=1/`r(k_names)' {
        if "`r(op`k')'" == "c" local tmptype variable
        else local tmptype factor
        if inlist("`r(type)'","factor","variable") {
          if strpos("`allvars'","`r(name`k')'") >0 {

            check_mixed_variable_type `tmptype' ``r(name`k')'_type'
            continue
          }
        }
        local `r(name`k')'_type `tmptype'
        local allvars `allvars' `r(name`k')'      
      }
    }
  }  
  // loop through again to establish baseline level
  foreach v in `fvnames' {
    _ms_parse_parts `v'
    if "`r(type)'" == "variable" continue 
    if "`r(type)'" == "factor" {
      if "``r(name)'_baseline'" != "" continue
      if strpos("`r(op)'","b") >0 {
        local `r(name)'_baseline `r(level)'
        continue
      }
    }
    if "`r(type)'" == "interaction" {
      forvalues k=1/`r(k_names)' {
        if "``r(name`k')'_baseline'" != "" continue
        if "`r(op`k')'" == "c" continue
        if strpos("`r(op`k')'","b") >0 {
          local `r(name`k')'_baseline `r(level`k')'
        }
      }
    }
  }

  // for factor variables with no baseline set lowest to baseline
  // **1NEED TO FIX - SHOULD BE MINIMUM OF LEVELS**
  foreach v in `allvars' {
    if "``v'_`type''" == "factor" {
      if "``v'_baseline'" == "" {
        local `v'_baseline = 1
      }
    }
  }

  // store results
  foreach v in `allvars' {
    c_local `v'_type ``v'_type'
    c_local `v'_baseline ``v'_baseline'
  }
end

// check variable types (called from get_variable_type)
// ****check whether this is necessary*****
program define check_mixed_variable_type,
  args type1 type2
  if "`type1'" != "`type2'" {
    di as error "Your model mixes factor and standard variable types for the same variable." 
    exit 198    
  }
end  


////////////////////////
// getcontrastoptions //
// contrast options   //
////////////////////////
program define getcontrastoptions
  capture syntax , [DIFference RATio]
  if _rc {
    local oldrc = _rc
    di as error "Error with contrast option"
    error `oldrc'
  }

  c_local contrast `difference'`ratio'
end

////////////////////////
// Parse_ODEoptions   //
////////////////////////
program define Parse_ODEoptions
  syntax  [,                                             ///
      abstol(real 1e-8)                                  ///
      error_control(real -99)                            ///
      initialh(real 1e-8)                                ///
      maxsteps(integer 1000)                             ///
      pgrow(real -0.2)                                   ///
      pshrink(real -0.25)                                ///
      reltol(real 1e-05)                                 ///
      safety(real 0.9)                                   ///
      tstart(real 1e-6)                                  ///
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

// adds appropriate values when timevar=0
program define stpm3_pred_addt0 
  syntax [anything], [survival failure rmst rmft cumhazard xb crudeprob cif ///
                    ci frame(string) timevars(string) per(real 1) expvars(string) ///
                    crnames(string) nogen]
                    
  local Natoptions = wordcount("`anything'")
  
  if "`frame'" != "" local fr frame `frame':
  if "`gen'"=="" {
    if "`survival'" != "" {
      forvalues i = 1/`Natoptions' {
        local v = word("`anything'",`i')
        local tv = word("`timevars'",`i')
        `fr' qui replace `v' = 1*`per' if `tv' == 0
        if "`ci'" != "" {
          `fr' qui replace `v'_lci = 1*`per' if `tv' == 0
          `fr' qui replace `v'_uci = 1*`per' if `tv' == 0
        }
        if "`expvars'" != "" {
          local v = word("`expvars'",`i')
          `fr' qui replace `v' = 1*`per' if `tv' == 0
          if "`ci'" != "" & "`crudeprob'" != "" {
            `fr' qui replace `v'_lci = 1*`per' if `tv' == 0
            `fr' qui replace `v'_uci = 1*`per' if `tv' == 0
          }        
        }
      }
    }
  }
  
  if "`gen'"=="" {
    if "`failure'`rmst'`rmft'`cumhazard'`crudeprob'" != "" {
      forvalues i = 1/`Natoptions' {
        local v = word("`anything'",`i')
        local tv = word("`timevars'",`i')
        `fr' qui replace `v' = 0 if `tv' == 0
        if "`ci'" != "" {
          `fr' qui replace `v'_lci = 0 if `tv' == 0
          `fr' qui replace `v'_uci = 0 if `tv' == 0
        }
        if "`expvars'" != "" {
          local v = word("`expvars'",`i')
          `fr' qui replace `v' = 0 if `tv' == 0
          if "`ci'" != "" {
            `fr' qui replace `v'_lci = 0 if `tv' == 0
            `fr' qui replace `v'_uci = 0 if `tv' == 0
          }        
        }      
      }
    } 
  }
  
  if "`gen'"=="" {
    if "`cif'" != "" {
      forvalues i = 1/`Natoptions' {
        local v = word("`anything'",`i')
        local tv = word("`timevars'",`i')
        foreach m in `crnames' {
         `fr' qui replace `v'_`m' = 0 if `tv' == 0
          if "`ci'" != "" {
            `fr' qui replace `v'_`m'_lci = 0 if `tv' == 0
            `fr' qui replace `v'_`m'_uci = 0 if `tv' == 0
          }       
        }
      }
    }
  }

end  


/////////////////////////////
// Parse_expsurv_options   //
/////////////////////////////
program define Parse_expsurv_options
  syntax [, AGEDiag(string)            ///
			EXPRMSTNODES(integer 30)   ///
            EXPVars(string)            ///
            DATEDiag(string)           ///
            PMAGE(string)              ///
            PMMAXAge(integer 99)       ///
            PMMAXyear(integer 10000)   ///
            PMOTHER(string)            ///
            PMRATE(string)             ///
            PMYEAR(string)             ///
            SPLIT(real 1)              ///
            USING(string)              ///
            NENTER(real 30)            ///
            NATOPTIONS(integer 1)      ///
			OLDEXPSURV                 ///
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
  local popmortfile `using'
  local Natoptions `natoptions'
  
  if "`datediag'" != "" {
    capture confirm variable `datediag'
    if _rc {
      local ndatewords = wordcount(`"`datediag'"')
      if `ndatewords' == 1 {
        local tmpdate = date("`datediag'","YMD")
        if `tmpdate' == . {
          di as error "Invalid date"
          exit 198
        }
        else {
          forvalues i=1/`Natoptions' {
            local datediag`i'_val `tmpdate'
          }
        }
      }
      else if `ndatewords' == `Natoptions' {
        forvalues i = 1/`Natoptions' {
          local tmpdatediag = word(`"`datediag'"',`i')
          local tmpdate = date(`"`tmpdatediag'"',"YMD")
          local datediag`i'_val `tmpdate'
        }        
      }
      else {
        di as error "Invalid datediag() option"
        exit 198
      }
    }
    else {
      local datediag_var `datediag'
    }
    local datediag
  }    
  if "`agediag'" != "" {
    capture confirm variable `agediag'
    if _rc {
      local nagewords = wordcount(`"`agediag'"')
      if `nagewords' == 1 {
        capture confirm number `agediag'
        if _rc {
          di as error "Invalid agediag() option"
          exit 198
        }
        else {
          forvalues i=1/`Natoptions' {
            local agediag`i'_val `agediag'
          }
        }
      }
      else if `nagewords' == `Natoptions' {
        forvalues i = 1/`Natoptions' {
          local tmpagediag = word(`"`agediag'"',`i')
          confirm number `tmpagediag'
          local agediag`i'_val `tmpagediag'
        }
      }
      else {
        di as error "Invalid agediag() option"
        exit 198
      }
    }
    else {
      local agediag_var `agediag'
    }
    local agediag
  }
  
  if "`pmrate'" == "" local pmrate rate
  if "`pmage'" == ""  local pmage  _age
  if "`pmyear'" == "" local pmyear _year
  
  local optnum 1
  local end_of_ats 0
  local 0 ,`options'  
  while `end_of_ats' == 0 {
    capture syntax [,] AT`optnum'(string) [*]
    if _rc {
      local end_of_ats 1
      continue, break
    }
    else local 0 ,`options'
    local optnum = `optnum' + 1
  }
  local Natoptions_pm = `optnum' - 1
  if "`0'" != "," {
    di as error "Illegal option: `0'"
    exit 198
  }  
  local hasatoptions = `Natoptions_pm' > 0
  if !`hasatoptions' local Natoptions_pm 1

// Parse at() options 
  if `hasatoptions' > 0 {
    forvalues i = 1/`Natoptions_pm' {
      tokenize `"`at`i''"', parse(",")
      local at`i'opt  `1'
      local 0 `2'`3'
      syntax ,[AGEDiag(string) datediag(string)]    // could add atmean option??
      // agediag
      if "`agediag'" != "" {
        if "`agediag`i'_var'" != "" {
          di as error "You cannot specify agediag within an at suboption and as a main expsurv option."
          exit 198
        }
        capture confirm variable `agediag'
        if _rc {
          confirm number `agediag'
          c_local agediag`i'_val `agediag'
        }
        else local agediag`i'_var `agediag'
      }
      else {
        c_local agediag`i'_val `agediag`i'_val'
        c_local agediag`i'_var `agediag_var'
      }
      // datediag
      if "`datediag'" != "" {
        if "`datediag_var'`datediag_val'" != "" {
          di as error "You cannot specify datediag within an at suboption and as a main expsurv option."
          exit 198
        }
        capture confirm variable `datediag'
        if _rc {
          local tmpdate = date("`datediag'","YMD")
          if `tmpdate' == . {
            di as error "Invalid date"
            exit 198
          }
          c_local datediag`i'_val `=date("`datediag'","YMD")'
        }
        else local datediag`i'_var `datediag'
      }
      else {
        c_local datediag`i'_val `datediag`i'_val'
        c_local datediag`i'_var `datediag_var'
      }
      // main at option
      tokenize `at`i'opt'
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
        c_local at`i'_pm_`1'_value `2'
        mac shift 2
      }
      c_local at`i'_pm_vars `at`i'vars'
    }
  }
  else {
    // use shared values if no expsurv at options
    forvalues i = 1/`Natoptions' {
      c_local agediag`i'_val `agediag`i'_val'
      c_local agediag`i'_var `agediag_var'   
      c_local datediag`i'_val `datediag`i'_val'
      c_local datediag`i'_var `datediag_var'      
    }
  }
  
//check vars in popmort file
  qui describe using "`popmortfile'", varlist short
  local popmortvars `r(varlist)'
  foreach var in `pmage' `pmyear' `pmother' `pmrate' {
    local varinpopmort:list posof "`var'" in popmortvars
    if !`varinpopmort' {
      di "`var' is not in popmort file"
      exit 198
    }
  } 
  
// expsurv names 
  if "`expvars'" != "" {
    c_local pmhasexpvars pmhasexpvars 
    c_local expvars `expvars'
  }
  
  c_local pmage           `pmage'
  c_local pmyear          `pmyear'
  c_local pmother         `pmother'
  c_local pmmaxage        `pmmaxage'
  c_local pmmaxyear       `pmmaxyear'
  c_local pmrate          `pmrate'
  c_local nenter          `nenter'
  c_local split_pm        `split'
  c_local popmortfile     `popmortfile'  
  c_local N_at_options_pm `Natoptions_pm'
  c_local hasatoptions_pm `hasatoptions' 
  c_local oldexpsurv      `oldexpsurv'
  c_local exprmstnodes    `exprmstnodes'
end

program define stpm3_pred_varlist_add_bn, rclass
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

// Parse_centile_options
program define Parse_centile_options
  syntax anything, [tol(real 1e-6)       ///
                    low(real 1e-08)      /// 
                    high(real 100)       ///
                    maxiter(integer 100) ///
                    centvar(string)      ///
                    nodes(integer 30)    ///
                    ]

  capture numlist "`anything'", min(0) max(100)
  if !_rc {
    c_local centype numlist
    c_local centile `r(numlist)'
  }
  else {
    capture confirm var `anything'
    if _rc {
      di as error "Error in centile option - should be a single number or variable."
      exit 198
    }
    c_local centype variable
    local centvar `anything'
    c_local centile `centvar'
  }
  if "`centvar'" == "" local centvar centile
  c_local centol     `tol'
  c_local cenlow     `low'
  c_local cenhigh    `high'
  c_local cenmaxiter `maxiter'
  c_local centvar    `centvar'
  c_local cennodes   `nodes'
end

// convert num list to a variable
program define Numlist_to_var
  syntax newvarlist(max=1), nlist(numlist min=0 max=100)
  local N = wordcount("`nlist'")
  qui gen `varlist' = .
  forvalues i=1/`N' {
    qui replace `varlist' = `=word("`nlist'",`i')' in `i'
  }
end

// check if centile outside range
program define stpm3_Check_Centile
  syntax ,[atvars(string) ci cenlow(real -99) cenhigh(real -99) frame(string)]
  
  capture confirm var _t
  local has_t = cond(_rc,0,1)
  
  qui count if e(sample)
  if `r(N)'==0 local has_t 0
  
  if "`frame'" != "" local fr frame `frame':
  
  if `has_t' {
    summ _t if e(sample), meanonly
    local mint `r(min)'
    local maxt `r(max)'
    
    // predictions greater than maxium follow-up time.
    foreach z in `atvars' {
      `fr' qui count if `z'>`maxt'
      if `r(N)' {
        di as text "Warning: Estimated centile > maximum follow-up time (`z')"
      }
      else if "`ci'" != "" {
        `fr'  qui count if `z'_uci>`maxt'
          if `r(N)' {
            di as text "Warning: Estimated centile upper bound > maximum follow-up time (`z'_uci)"
          }        
      }
    }
  }
  // predicts at cenhigh
  foreach z in `atvars' {
    `fr' qui count if `z'>`cenhigh'
    if `r(N)' {
      di as text "Warning: predictions greater than default high value (100)" 
      di as text "for centiles. If you did not intend this," 
      di as text "change your scale or use the high() suboption" 
      di as text "of the centile() option"
    }
  }
end


