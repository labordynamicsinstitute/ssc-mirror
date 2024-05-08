///////////////////////////////////////////////////
/////////////// Generate Splines //////////////////
///////////////////////////////////////////////////
program define stpm3_gensplines, 
  syntax  [if],  [                              ///          
                 allknots(passthru)             ///
                 allknotstvc(passthru)          ///
                 bknots(passthru)               ///
                 bknotstvc(passthru)            ///
                 df(numlist max=1 int >0)       ///
                 knots(passthru)                ///
                 tvc(string)                    ///
                 dftvc(passthru)                ///
                 ttrans(string)                 ///
                 knotstvc(passthru)             ///
                 type(string)                   ///
                 degree(integer 3)              ///
                 hasdelentry(string)            ///
                 timevar(varname)               ///
                 subcentile(string)             ///
                 nolocalreturn                  ///
                 scale(string)                  ///
                 toffset(string)                ///
                 wtvar(string)                  ///
                 ]

  local tt `varlist'    
  marksample touse

// ttrans() option
  tempvar tt tt0 
  if "`toffset'" == "" local toffset 0
  if "`timevar'" == "" local timevar _t + `toffset'
  if "`ttrans'" == "lnt"       qui gen double `tt' = ln(`timevar' + `toffset') if `touse'
  else if "`ttrans'" == "none" qui gen double `tt' = `timevar' + `toffset'    if `touse'
  else qui gen double `tt' = `ttrans' if `touse'
  
  // should not work with timevar option
  if `hasdelentry' {
    if "`ttrans'" == "lnt"       qui gen double `tt0' = ln(_t0 + `toffset') if `touse' 
    else if "`ttrans'" == "none" qui gen double `tt0' = _t0 + `toffset'    if `touse'
    else {
      local ttrans0 = subinstr("`ttrans'","_t","_t0")
      qui gen double `tt0' = `ttrans0'    if `touse'    
    }
  } 
 
  getknots `tt' if `touse', `allknots' `knots' `bknots' ttrans(`ttrans')

// basesline splines
  if "`intknots'" != "" local gensplinesopt knots(`intknots')
  if "`allknots'" != "" local gensplinesopt allknots(`allknots')
  if "`bknots'" != "" local gensplinesopt `gensplinesopt' bknots(`bknots')
  if "`df'" != "" local gensplinesopt `gensplinesopt' df(`df')
  if "`subcentile'" != "" local subcentile subcentile(`subcentile')
  if "`wtvar'" != "" local iw iw(`wtvar')
  

  if inlist("`scale'","lncumhazard","probit","lnodds") local dgen dgen(_d`type')

  if "`scale'" ==  "hazard" {
    // need to add intercept option
    gensplines `tt' if `touse', `gensplinesopt' gen(_`type')          /// 
                                degree(`degree') type(`type')        ///
                                `subcentile' intercept               ///
                                bknots(0,`r(max)') `iw'
  }                          
  else {
    gensplines `tt' if `touse', `gensplinesopt' gen(_`type')   `dgen' /// 
                                degree(`degree') type(`type')        ///
                                `subcentile' `iw'
  }                           
  local intknots     `r(internal_knots)'
  local knots        `r(knots)'
  local bknots_original `bknots'
  local bknots       `r(bknots)'
  local splinelist   `r(splinevarlist)'  
  local dsplinelist  `r(dsplinevarlist)' 

  // labels
  local splinename = cond("`type'" == "ns","Natural cubic spline","B-spline")
  local k = 1
  foreach v in `r(splinevarlist)' {
     label variable `v' "`splinename' `k'"
     local k = `k' + 1
  }
  
  if `hasdelentry' & "`scale'" != "lnhazard" {
    local gensplineopt = cond("`df'" == "1","df(1)","allknots(`knots')")
    gensplines `tt0' if `touse' & _t0>0, `gensplineopt' gen(_ns_t0_)      ///  only for ch models!!!!!!!!!!!
                                         type(`type') degree(`degree')
    local delentryvars `delentryvars' `r(splinevarlist)'
    local k = 1
    foreach v in `r(splinevarlist)' {
       label variable `v' "`splinename' `k' (delayed entry)"
       local k = `k' + 1
    }    
  }
  local df = wordcount("`splinelist'") 

// tvc splines 
  if "`tvc'" != "" {  
    // inherit bknotstvc from bknots if not specified.
    if "`bknotstvc'" == "" {
      local bknotstvc `bknots_original' 
      local bknotsopt bknotstvc(`bknotstvc')
    }
    parsetvc `tt' if `touse', tvc(`tvc') `dftvc' `allknotstvc' `knotstvc' `bknotsopt' ttrans(`ttrans')


    if `sharedtvc_knots' {
      //if "`bknots'" != "" local gensplineopt `gensplineopt' bknots(`bknots')

      local gensplinesopt
      if "`dftvc'" != "" local gensplinesopt df(`dftvc')      
      if "`allknotstvc'" != "" local gensplinesopt `gensplinesopt' allknots(`allknotstvc')
      if "`knotstvc'"  != "" local gensplinesopt `gensplinesopt' knots(`knotstvc')
      if "`bknotstvc'" != "" local gensplinesopt `gensplinesopt' bknots(`bknotstvc')

      if inlist("`scale'","lncumhazard","probit","lnodds")  local dgen dgen(_d`type'_tvc)
      
      gensplines `tt' if `touse', `gensplinesopt' gen(_`type'_tvc) `dgen'  ///
                                   type(`type') degree(`degree') `subcentile' `iw' 
                                
      local dftvc = wordcount("`r(splinevarlist)'")
      local splinevars_tvc   `splinevars_tvc' `r(splinevarlist)'
      local intknots_tvc     `r(internal_knots)'
      local knots_tvc        `r(knots)'
      local bknots_tvc       `r(bknots)'
      local k = 1

      foreach v in `r(splinevarlist)' {
         label variable `v' "`splinename' `k' (tvc)"
         local k = `k' + 1
      }        
      if `hasdelentry' & "`scale'" != "lnhazard" {      
        local gensplineopt = cond("`dftvc'" == "1","df(1)","allknots(`knots_tvc')")
        gensplines `tt0' if `touse' , `gensplineopt' gen(_`type'_t0_tvc)   ///
                                      type(`type')
        local k = 1
        foreach v in `r(splinevarlist)' {
           label variable `v' "`splinename' `k' (tvc - delayed entry)"
           local k = `k' + 1
        }                                              
      }
    }
    else { // separate df /  knots
      fvrevar `tvc', list
      local tvcvars `r(varlist)'
      foreach v in `tvcvars' {
        local gensplinesopt
        if "`dftvc_`v''" != "" local gensplinesopt `gensplinesopt' df(`dftvc_`v'')      
        if "`knotstvc_`v''" != "" local gensplinesopt `gensplinesopt' knots(`knotstvc_`v'')
        if "`allknotstvc_`v''" != "" local gensplinesopt `gensplinesopt' allknots(`allknotstvc_`v'')
        if "`bknotstvc'" != "" local gensplinesopt `gensplinesopt' bknots(`bknotstvc')
        // add bknots
        
        local dgen
        if inlist("`scale'","lncumhazard","probit","lnodds") local dgen dgen(_d`type'_tvc_`v')
        gensplines `tt' if `touse', `gensplinesopt' gen(_`type'_tvc_`v') `dgen'  ///
                                     type(`type') degree(`degree') `subcentile' `iw'       
        local dftvc_`v' = wordcount("`r(splinevarlist)'")
        local splinevars_tvc_`v' `splinevars_tvc' `r(splinevarlist)'
        local intknots_tvc_`v'   `r(internal_knots)'
        local knots_tvc_`v'      `r(knots)'
        local bknots_tvc_`v'     `r(bknots)'
        
        local k = 1
        foreach z in `r(splinevarlist)' {
           label variable `z' "`splinename' `k' (`v' tvc)"
           local k = `k' + 1
        }
        if `hasdelentry' & "`scale'" != "lnhazard" {      
          local gensplineopt = cond("`df'" == "1","df(1)","allknots(`knots_tvc_`v'')")
          gensplines `tt0' if `touse' , `gensplineopt' gen(_`type'_t0_tvc_`v')   ///
                                        type(`type')
          local k = 1
          foreach v in `r(splinevarlist)' {
             label variable `v' "`splinename' `k' (`v' tvc - delayed entry)"
             local k = `k' + 1
          }                                              
        }        
      }
    }

    fvexpand `tvc'
    local tvc_expand `r(varlist)'
    foreach v in `tvc_expand' {
      _ms_parse_parts `v'
      local v_nofactor `r(name)'
      if !`r(omit)' { 
        local tvc_included `tvc_included' `v'
        local addc = cond("`r(type)'" == "variable","c.","")
        if `sharedtvc_knots' {
          forvalues j = 1/`dftvc' {
            local newterm `addc'`v'#c._`type'_tvc`j'
            local dnewterm `addc'`v'#c._d`type'_tvc`j'
            if `hasdelentry' { 
              local delentryvars `delentryvars' `addc'`v'#c._`type'_t0_tvc`j'
            }
            local splinelist_tvc `splinelist_tvc' `newterm'
            local dsplinelist_tvc `dsplinelist_tvc' `dnewterm'
          }
        }
        else {
          forvalues j = 1/`dftvc_`v_nofactor'' {
            local newterm `addc'`v'#c._`type'_tvc_`v_nofactor'`j'
            local dnewterm `addc'`v'#c._d`type'_tvc_`v_nofactor'`j'
            if `hasdelentry' { 
              local delentryvars `delentryvars' `addc'`v'#c._`type'_t0_tvc_`v_nofactor'`j'
            }
            local splinelist_tvc `splinelist_tvc' `newterm'
            local dsplinelist_tvc `dsplinelist_tvc' `dnewterm'
          }          
        }
      }
    }
  }  


  // need to return by tvc (df / knots etc)
  // then add to ereturn
  // then update stpm3_predict

  c_local knots             `knots'
  c_local intknots          `intknots'
  c_local bknots            `bknots'
  c_local splinelist        `splinelist'  
  c_local dsplinelist       `dsplinelist'
  c_local df                `df'
  c_local sharedtvc_knots   `sharedtvc_knots'
  if "`tvc'" != "" {
    if `sharedtvc_knots' {
      c_local dftvc             `dftvc'   
      c_local knots_tvc         `knots_tvc'
      c_local intknots_tvc      `intknots_tvc'
      c_local bknots_tvc        `bknots_tvc'     
    }
    else {
      foreach v in `tvcvars' {
        c_local dftvc_`v'        `dftvc_`v''
        c_local knots_tvc_`v'    `knots_tvc_`v''
        c_local intknots_tvc_`v' `intknots_tvc_`v''
        c_local bknots_tvc_`v'   `bknots_tvc_`v''
        c_local splinevars_tvc_`v' `splinevars_tvc_`v''
      }    
    }
  }
  c_local splinelist_tvc    `splinelist_tvc'
  c_local splinevars_tvc    `splinevars_tvc'
  c_local dsplinelist_tvc   `dsplinelist_tvc'
  c_local delentryvars      `delentryvars'
  c_local tvc_included      `tvc_included'
end

// getknots options
program define getknots , 
  syntax varname [if][in],[allknots(string) knots(string) bknots(string) ///
                           allknotstvc(string) knotstvc(string)          ///
                           ttrans(string)]
  
  marksample touse
  local tt `varlist'

  // in case 0 or 100 specified
  if "`knots'`bknots'`knotstvc'`bknotstvc'`allknots'`allknotstvc'" != "" {
    capture confirm var _d
    if !_rc {
      summ `tt' if _d & `touse', meanonly
      local tmin `r(min)'
      local tmax `r(max)'  
    }
  }

// bknots() option  
  if "`bknots'" != "" {
    knotsscaleoptions `bknots' 
    numlist "`knumlist'", ascending min(2) max(2)
    local klist `r(numlist)'
    local b1 = word("`klist'",1)
    local b2 = word("`klist'",2)
    // percentile option
    if "`knotscale'" == "percentile" {
      forvalues i = 1/2 {
        local tmpk = word("`klist'",`i')
        if "`tmpk'" == "0" local b1 `tmin'
        else if "`tmpk'" == "100" local b1 `tmax'
        else {
          _pctile `tt' if _d==1, percentile(`b`i'')
          local b`i' `r(r1)'
        }
      }
    } 
    // transform to correct time scale
    if "`knotscale'" == "time" & "`ttrans'" == "lnt" {
      local b1 = log(`b1')
      local b2 = log(`b2')
    }
    if "`knotscale'" == "lntime" & "`ttrans'" == "none" {
      local b1 = exp(`b1')
      local b2 = exp(`b2')
    }
  }

// knots & allknots option  
  if "`knots'`allknots'"  != "" {
    knotsscaleoptions `knots'`allknots'  
    numlist "`knumlist'", ascending 
    local klist `r(numlist)'

    local Nk = wordcount("`klist'")
    forvalues i = 1/`Nk' {
      local k`i' = word("`klist'",`i')
    }
    // percentile option
    if "`knotscale'" == "percentile" {
      forvalues i = 1/`Nk' {
        local tmpk = word("`klist'",`i')
        if "`tmpk'" == "0" local k1 `tmin'
        else if "`tmpk'" == "100" local k`Nk' `tmax'
        else {
          _pctile `tt' if _d==1, percentile(`tmpk')
          local k`i' `r(r1)'
        }
      }
    }     
    // transform to correct time scale
    if "`knotscale'" == "time" & "`ttrans'" == "lnt" {
      forvalues i = 1/`Nk' {
        local k`i' = log(`k`i'')
      }
    }
    if "`knotscale'" == "lntime" & "`ttrans'" == "none" {
      forvalues i = 1/`Nk' {
        local k`i' = exp(`k`i'')
      }
    }
    forvalues i = 1/`Nk' {
      local retknots `retknots' `k`i''
    }
  }  
  
  c_local bknots `b1' `b2'
  if "`allknots'" != "" c_local allknots `retknots'
  if "`knots'"    != "" c_local intknots `retknots'
end

// extract knotscale
program define knotsscaleoptions, rclass
  syntax anything, [LNTime LOGTime PERCentile]
  if "`logtime'" != "" local lntime lntime
  
  if wordcount("`lntime' `percentile'") >1 {
    di as error "Only one scale for knots can be given"
    exit 198
  }
  if wordcount("`lntime' `logtime' `percentile'") == 0 {
    local knotscale = "time"
  }
  else {
    local knotscale `lntime' `percentile'
  } 
  c_local knotscale `knotscale'
  c_local knumlist `anything'
end

// extract tvcknots knotscale
program define knotsoptionstvc
  syntax anything, [t(string) LNTime LOGTime PERCentile]
  if "`logtime'" != "" local lntime lntime
  
  if wordcount("`lntime' `percentile'") >1 {
    di as error "Only one scale for knots can be given"
    exit 198
  }
  if wordcount("`lntime' `logtime' `percentile'") == 0 {
    local knotscale = "time"
  }
  else {
    local knotscale `lntime' `percentile'
  } 
  c_local knotscale `knotscale'
  c_local knumlist `anything'
end


// parse tvc option
program define parsetvc,
  syntax varname [if][in],[tvc(string) dftvc(string) ///
                           bknotstvc(string) allknotstvc(string) knotstvc(string) ttrans(string)]

  marksample touse
  local tt `varlist'

  if "`knotstvc'`bknotstvc'`allknotstvc'" != "" {
    capture confirm var _d
    if !_rc {
      summ `tt' if _d & `touse', meanonly
      local tmin `r(min)'
      local tmax `r(max)'  
    }
  }  

  fvunab tvcunab: `tvc'
  if "`dftvc'" != "" {
    capture confirm number `dftvc'
    if !_rc {
      c_local sharedtvc_knots 1
      c_local dftvc `dftvc'
      exit
    }
    else {
      c_local sharedtvc_knots 0
      tokenize `dftvc'
      while "`1'"!="" {
        unab 1: `1'
        cap confirm var `1'
        if _rc {
          di as err "invalid variable in dftvc(... `1' `2' ...)"
          exit 198
        }
        cap confirm number `2'
        if _rc {
          di as err "invalid number in dftvc(... `1' `2' ...)"
          exit 198
        }
        if strpos("`tvcunab'","`1'")==0 {
          di as err "Error in dftvc: variable `1' not specified in tvc() option."
          exit 198
        }
        c_local dftvc_`1' `2'
        mac shift 2
      }
    }
  }
 
  if "`allknotstvc'`knotstvc'" != "" {
    local rettvc = cond("`allknotstvc'" != "","allknotstvc","knotstvc")
    
    
    local tmpk = word("`allknotstvc'`knotstvc'",1)
    capture confirm number `tmpk'
    local sharedtvc_knots = _rc==0   
    if `sharedtvc_knots' {
      knotsscaleoptions `allknotstvc'`knotstvc'
      numlist "`knumlist'", ascending 
      local klist `r(numlist)'

      local Nk = wordcount("`klist'")
      forvalues i = 1/`Nk' {
        local k`i' = word("`klist'",`i')
      }
      // percentile option
      if "`knotscale'" == "percentile" {
        forvalues i = 1/`Nk' {
          local tmpk = word("`klist'",`i')
          if "`tmpk'" == "0" local k1 `tmin'
          else if "`tmpk'" == "100" local k`Nk' `tmax'
          else {
            _pctile `tt' if _d==1, percentile(`tmpk')
            local k`i' `r(r1)'
          }
        }
      }     
      // transform to correct time scale
      if "`knotscale'" == "time" & "`ttrans'" == "lnt" {
        forvalues i = 1/`Nk' {
          local k`i' = log(`k`i'')
        }
      }
      if "`knotscale'" == "lntime" & "`ttrans'" == "none" {
        forvalues i = 1/`Nk' {
          local k`i' = exp(`k`i'')
        }
      }
      forvalues i = 1/`Nk' {
        local retknots `retknots' `k`i''
      }
      c_local `rettvc' `retknots'
      c_local sharedtvc_knots 1
    }        
 
    else {
      c_local sharedtvc_knots `sharedtvc_knots'
      knotsscaleoptions `allknotstvc'`knotstvc'
      
      tokenize `knumlist'
      while "`1'"!="" {
        cap confirm var `1'
        if _rc {
          di as err "invalid variable in (all)knotstvc(... `1' `2' ...)"
          exit 198
        }
        // could check in tvc
        local v `1'
        local nextvar 0
        local tmpklist
        local retknots
        while !`nextvar' {
          capture confirm number `2'
          if _rc {
            numlist "`tmpklist'", ascending 
            local klist `r(numlist)'

            local Nk = wordcount("`klist'")
            forvalues i = 1/`Nk' {
              local k`i' = word("`klist'",`i')
            }
            // percentile option
            if "`knotscale'" == "percentile" {
              forvalues i = 1/`Nk' {
                local tmpk = word("`klist'",`i')
                if "`tmpk'" == "0" local k1 `tmin'
                else if "`tmpk'" == "100" local k`Nk' `tmax'
                else {
                  _pctile `tt' if _d==1, percentile(`tmpk')
                  local k`i' `r(r1)'
                }
              }
            }     
            // transform to correct time scale
            if "`knotscale'" == "time" & "`ttrans'" == "lnt" {
              forvalues i = 1/`Nk' {
                local k`i' = log(`k`i'')
              }
            }
            if "`knotscale'" == "lntime" & "`ttrans'" == "none" {
              forvalues i = 1/`Nk' {
                local k`i' = exp(`k`i'')
              }
            }
            forvalues i = 1/`Nk' {
              local retknots `retknots' `k`i''
            }            
            
            c_local `rettvc'_`v' `retknots'
            capture confirm var `2'
            if _rc & "`2'" != "" {
              di as err "invalid variable in dftvc(... `1' `2' ...)"
              exit 198          
            }
            local nextvar 1
            mac shift 1
            continue, break
          }
          else local tmpklist `tmpklist' `2'
          mac shift 1
        }
      }
    }
  }
  // does not vary by variable
  if "`bknotstvc'" != "" {
    knotsscaleoptions `bknotstvc' 
    numlist "`knumlist'", ascending min(2) max(2)
    local klist `r(numlist)'
    local b1 = word("`klist'",1)
    local b2 = word("`klist'",2)
    // percentile option
    if "`knotscale'" == "percentile" {
      forvalues i = 1/2 {
        local tmpk = word("`klist'",`i')
        if "`tmpk'" == "0" local b1 `tmin'
        else if "`tmpk'" == "100" local b1 `tmax'
        else _pctile `tt' if _d==1, percentile(`b`i'')
        local b`i' `r(r1)'
      }
    } 
    // transform to correct time scale
    if "`knotscale'" == "time" & "`ttrans'" == "lnt" {
      local b1 = log(`b1')
      local b2 = log(`b2')
    }
    if "`knotscale'" == "lntime" & "`ttrans'" == "none" {
      local b1 = exp(`b1')
      local b2 = exp(`b2')
    }    
  }
  c_local bknotstvc `b1' `b2'
end


