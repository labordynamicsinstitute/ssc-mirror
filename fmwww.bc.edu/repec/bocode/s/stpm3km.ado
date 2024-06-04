*! version 0.5 2024-04-24
program define stpm3km, rclass
  version 16.1
  syntax [varlist(default=none fv max=1)]                  ///
                    [if] [in],   [                         ///
                                   noAJ                    ///
                                   CIF                     ///
                                   CRMODels(string)        ///
                                   COMPET1(numlist)        ///
                                   COMPET2(numlist)        ///
                                   COMPET3(numlist)        ///
                                   COMPET4(numlist)        ///
                                   COMPET5(numlist)        ///
                                   COMPET6(numlist)        ///
                                   CUT(numlist ascending)  ///
                                   noESample               ///
                                   FACtor                  ///
                                   FRame(string)           ///
                                   FAILure                 ///
                                   noGRaph                 ///
                                   noKM                    ///
                                   GRoups(integer 0)       ///
                                   MAXT(string)            ///
                                   NAME(string)            ///
                                   NTIMEvar(integer 100)   ///
                                   PITime(string)          ///
                                   SURVival                ///
                                   *                       ///
                                 ]
// crmodels 
//   --X parse crmodels
//   --X first model is default for PITime
//   --X error if esample different between models
//   --X standsurv type	cif / surv / failure
//   --X atlist needs CR models
//   --X run stcompet 
//   -- multiple graphs - need default naming scheme and name option.
//   -- frame needs to work
//   -- error for standard models if survival and failure specified
//   -- check stcompet installed
//   -- check competing events all sensible

// msmodels
//   --X msmodels option parse
//   -- need ttrans and check
//   -- error if esample different between models
//   -- standsurv type	transprob (default - error if not)
//   -- atlist needs number of states
//   -- run msaj
//   -- multiple graphs - need default naming scheme and name option.
//   -- frame needs to work

								 
  if "`e(cmd)'" != "stpm3" {
    di as error "An stpm3 model has not been fitted."
    exit 198
  } 
  marksample touse
  if "`esample'" == "" {
    qui replace `touse' = `touse'*e(sample)
  }
  
// default options
  if wordcount("`survival' `failure' `cif'") > 1 {
    di as err "Only one of the survival, failure and cif options can be specified."
    exit 198
  } 

  if "`survival'`failure'`cif'" == "" local survival survival

  if "`s(fvops)'" != "" {
    local factor factor
    fvrevar `varlist', list
    local varlist `r(varlist)'
  }
  
  if "`factor'" != "" & `groups' != 0 {
    di as error "You cannot use the groups() optons with factor variables."
    exit 198
  }
  
  if `groups' != 0 & "`cut'" != "" {
    di as error "only specify one of the groups() or cut() options."
    exit 198
  }
    
  // default 5 groups
  if `groups' == 0 local groups 5

  local egenopt = cond("`cut'"!="","at(`cut')","group(`groups')")
  
  
  // frame options 
  if "`frame'" != "" { 
  	getframeoptions `frame'
    mata: st_local("frameexists",strofreal(st_frameexists(st_local("resframe"))))
    if `frameexists' & "`framereplace'" == "" & "`framemerge'" == "" {
      di as error "Frame `resframe' exists. Use replace suboption or another framename."
      exit 198
    }
    else if `frameexists' & "`framereplace'" != "" capture frame drop `resframe'
  }
	
  
  // Competing risks and multistate models
  if "`crmodels'" != "" & "`msmodels'" != "" {
  	di as error "Only 1 of crmodels() and msmodels() options can be specified"
	exit 198
  }  
  tempname current_model
  if "`crmodels'" != "" {
    foreach m in `crmodels' {
      capture estimates describe `m'
      if _rc {
        di as error "Model `m' not found."
        exit 198
      }
      local eventvar "`_dta[st_bd]'"
      local compet0  "`_dta[st_ev]'"      
    }
	// check esample between models
	local j 1
    foreach m in `crmodels' {
      tempvar esample`j'	 
      qui estimates restore `m'
      gen byte `esample`j'' = e(sample)
      if `j'>1 {
        capture assert `esample`j'' == `esample`=`j'-1''
        if _rc {
          di as error "e(sample) does not match between models"
          exit 198
        }
      }
      local ++j
    }	
    local Nmodels = wordcount("`crmodels'")
    local modelslist `crmodels'
    estimates store `current_model'
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
  }  
  
  // Prognostic index
  if "`varlist'" == "" {
    if "`e(tvc)'" != "" & "`pitime'" == "" {
      di as error "The stpm3 model has time-dependent effects, so the prognostic index"
      di as error "varies over time. Use the {cmd:pitime()} option to specify a time point" 
      exit 198
    }
  	tempvar PI TPI
    if "`pitime'" == "" {
      qui predict `PI' if `touse', xbnotime merge
    }
    else {
      gen `TPI' = `pitime' if `touse'
      qui predict `PI' , xb timevar(`TPI') merge      
    }
	  local haspi haspi
	  local varlist `PI'
  }
  
  if "`factor'" == "" {
    if `groups' != 1 {
  	  tempvar vgrp
      qui egen `vgrp' = cut(`varlist') if `touse', `egenopt' icodes
      summ `vgrp', meanonly
      qui replace `vgrp' = `vgrp' - `r(min)' + 1 if `touse'
      qui levelsof `vgrp' if `touse'
      local Ngroups `r(r)'
      local levels `r(levels)'
    }
    else if `groups' == 1 {
  	  tempvar vgrp
      qui gen `vgrp' = 1 if `touse'
      local factor factor
      local Ngroups 1
      local levels 1
    }
  }
  else {
    qui levelsof `varlist' if `touse'
    local levels `r(levels)'
    local Ngroups `r(r)'
    local vgrp `varlist'
  }
  tempvar tt
  if "`maxt'" == "" {
    qui summ _t if `touse', meanonly
    local maxt `r(max)'
  } 
  
// extract labels
  if "`factor'" != "" {
    foreach i in `levels' {
      local tmplabel: label (`varlist') `i'
      if "`tmplabel'" == "" local tmplabel `i'
      local label`i' `tmplabel'
    }
  }  
    
  qui range `tt' 0 `maxt' `ntimevar'
  local standsurvtype = "`failure'`survival'`cif'"
  
  foreach i in `levels' {
    tempvar S`i'
    local atlist `atlist' `S`i''
  }
  
  if `Nmodels' >1 & "`cif'" != "" {
    forvalues m = 1/`Nmodels' {
      tempvar `S`i''_m`m'
      local stubnames `stubnames' m`m'
    }
    local stubnamesopt stub2(`stubnames')
  }
  if "`crmodels'" != "" local crmodelsopt crmodels(`crmodels')
  standsurv , `standsurvtype' timevar(`tt')        ///
                   over(`vgrp')  atvar(`atlist') `crmodelsopt' ///
                   `stubnamesopt' 

  if (`Nmodels'==1 & "`km'" == "") | "`cif'" == "" {
    tempvar Skm
    local kmtype = cond("`failure'" != "","f","s")
    qui sts gen `Skm' = `kmtype' if `touse', by(`vgrp')
    qui replace `Skm' = . if _t>`maxt'
  }
  else if `Nmodels'>1 & "`aj'" == "" & "`cif'" != "" {
    tempvar CIFaj
    //local competoptions compet1(`compet1')
    forvalues i = 1/6 {
      if "`compet`i''" != "" local competoptions `competoptions' compet`i'(`compet`i'')
        else continue, break
    }
    qui stcompet  `CIFaj'=ci if `touse', `competoptions' by(`vgrp')
    qui replace `CIFaj' = . if _t>`maxt'
  }
  if "`graph'" == "" {
    local c 1
    foreach i in `levels' {
      // non-parametric estimates
      if "`survival'`failure'" != "" & "`km'" == "" {
        local npline_m1 `npline_m1' (line `Skm' _t if `vgrp'==`i', sort lcolor("scheme p`c'") connect(stairstep ))
      }
      else if `Nmodels'>1 & "`aj'" == "" {
        forvalues m = 1/`Nmodels' {
          addcommas "`compet`=`m'-1''"
          local npline_m`m' `npline_m`m'' (line `CIFaj' _t if `vgrp'==`i' & inlist(`eventvar',`r(numlist)') ///
               , sort lcolor("scheme p`c'") connect(stairstep ))
        } 
      }
      // Model-based estimates
      if "`survival'`failure'" != "" {
        local pline_m1 `pline_m1' (line `S`i'' `tt' , sort lcolor("scheme p`c'") lpattern(dash) lwidth(thin))
      }
      else {
        forvalues m = 1/`Nmodels' {
          local pline_m`m' `pline_m`m'' (line `S`i''_m`m' `tt' , sort lcolor("scheme p`c'") lpattern(dash) lwidth(thin))
        }
      }
	    local ++c
    }	
    _get_gropts, graphopts(`options') getallowed(legend xtitle ytitle title)


    if `"`s(title)'"' == "" {
      if `"`haspi'"' == "" {
        local vtitle: variable label `varlist'
        if `"`vtitle'"' == "" local vtitle `varlist'
        local title title(`"`vtitle'"')
        local vlabel `varlist'
      }
      else if `Ngroups'>1 {
        local title title("Prognostic Index")
        local vlabel Prognostic Index
      }
    }
    if `"`s(ytitle)'"' == "" {
      if "`cif'" == "" local ytitle = cond("`failure'" != "",`"ytitle("F(t)")"',`"ytitle("S(t)")"')
      else local ytitle "ytitle("CIF(t)")"
    }
    if `"`s(xtitle)'"' == "" local xtitle xtitle("Time")

    if `Ngroups'>1 {
      if `"`s(legend)'"' == "" {
        local legendpos = cond("`survival'"!="","pos(1)","pos(11)")
        local c 1
        foreach i in `levels' {
          if "`factor'" == "" local label`i' `i'
          local order `"`order' `c' "`label`i''""'
          local legend legend(order(`order') cols(1) `legendpos')
          local ++c
        } 
      }
      else local legend legend(`s(legend)')
    }
    else if `"`s(legend)'"' == ""  local legend legend(off)
    
    if `"`name'"' != "" grname `name'
    
    if "`cif'" != "" {
      forvalues m = 1/`Nmodels' {
        local mname = word("`crmodels'",`m') 
        if `"`gname'"' == "" local name name(`mname', replace)
        else local name name(`gname'_`mname',`greplace') 
 
        twoway   `npline_m`m''  ///
                 `pline_m`m''   ///
               , `options' `title' `xtitle' `ytitle' `legend' `name'
      }
    }
    else {
      if "`gname'" != "" local name name(`gname',`greplace')
      twoway   `npline_m1'  ///
               `pline_m1'   ///
             , `options' `title' `xtitle' `ytitle' `legend' `name'      
    }
    
  }		 
  if "`resframe'" != "" {
    if "`crmodels'" == "" {
	    foreach i in `levels' {
        local Slist `Slist' `S`i''
      }
    }
    else {
	    foreach i in `levels' {
        forvalues m = 1/`Nmodels' {
          local CIFlist `CIFlist' `S`i''_m`m'
        }
      }      
    }
  	frame put _t `eventvar' `vgrp' `Skm' `CIFaj' `tt'  `Slist' `CIFlist' if `touse', into(`resframe')
	  frame `resframe' {
      local Z = cond("`failure'"!="","F","S")
      qui rename `vgrp' groups
      if `Nmodels'==1 & "`km'" == "" {
        qui rename `Skm' `Z'km          
      }
      else if `Nmodels'>1 & "`aj'" == "" {
        qui rename `CIFaj' CIFaj
      }
      foreach i in `levels' {
        if `Nmodels'==1 {

          rename `S`i'' `Z'`i'
          label variable `Z'`i' `"Level `i' of `vlabel'"'
        }
        else {
          forvalues m = 1/`Nmodels' {
            local mname = word("`crmodels'",`m') 
            rename `S`i''_m`m' CIF`i'_`mname'
            label variable CIF`i'_`mname' `"`mname': Level `i' of `vlabel'"'
          }
        }
      }
	    rename `tt' tt
    }		
  }
  return scalar Ngroups = `Ngroups'
end

// extract reurn from name() in graph options
program grname, rclass
  syntax anything, [replace]
  c_local gname `anything'
  c_local greplace `replace'
end

// change to commas
program addcommas, rclass
  version 16.0
  numlist `0'
  local result "`r(numlist)'"
  local result : subinstr local result " " ",", all
  return local numlist "`result'"
end

// get frame options
program define getframeoptions
  syntax [anything], [replace]
  c_local resframe       `anything'
  c_local framereplace   `replace'
end