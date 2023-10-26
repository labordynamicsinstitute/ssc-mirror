*! version 0.4 2023-10-25
program define stpm3km
  version 16.1
  syntax [varlist(default=none)]                           ///
                    [if] [in],   [                         ///
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
  if "`crmodels'" != "" & "`survival'`failure'" == "" local cif cif
  else if "`survival'`failure'" == "" local survival survival
  
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
      qui replace `vgrp' = `vgrp' + 1 if `touse'
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

  if `Nmodels'==1 & "`km'" == "" {
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
      if `Nmodels' == 1 {
        local pline_m1 `pline_m1' (line `S`i'' `tt' , sort lcolor("scheme p`c'") lpattern(dash) lwidth(thin))
      }
      else {
        forvalues m = 1/`Nmodels' {
          local pline_m`m' `pline_m`m'' (line `S`i''_m`m' `tt' , sort lcolor("scheme p`c'") lpattern(dash) lwidth(thin))
        }
      }
	    local ++c
    }	
    _get_gropts, graphopts(`options') getallowed(legend xtitle ytitle title name)


    if `"`s(title)'"' == "" {
      if `"`haspi'"' == "" {
        local vtitle: variable label `varlist'
        if `"`vtitle'"' == "" local vtitle `varlist'
        local title title(`"`vtitle'"')
      }
      else if `Ngroups'>1 local title title("Prognostic Index")
    }
    if `"`s(ytitle)'"' == "" {
      if "`cif'" == "" local ytitle = cond("`failure'" != "",`"ytitle("F(t)")"',`"ytitle("S(t)")"')
      else local ytitle "ytitle("CIF(t)")"
    }
    if `"`s(xtitle)'"' == "" local xtitle xtitle("Time")

    if `Ngroups'>1 {
      if `"`s(legend)'"' == "" {
        local c 1
        foreach i in `levels' {
          local order `"`order' `c' "`i'""'
          local legend legend(order(`order') cols(`Ngroups'))
          local ++c
        } 
      }
      else local legend legend(`s(legend)')
    }
    else if `"`s(legend)'"' == ""  local legend legend(off)
    forvalues m = 1/`Nmodels' {
      if "`crmodels'" != "" {
        local mname = word("`crmodels'",`m') 
        if `"`s(name)'"' == "" local name name(`mname', replace)
        else local name name(`s(name)'_`mname',replace) // FIX THIS
      }
      twoway   `npline_m`m''  ///
               `pline_m`m''   ///
             , `options' `title' `xtitle' `ytitle' `legend' `name'
    }
  }		 
  if "`frame'" != "" {
    mata: st_local("frameexists",strofreal(st_frameexists(st_local("frame"))))
    if `frameexists' {
      di as error "Frame `frame' exists."
      exit 198
    }
	forvalues i = 1/`Ngroups' {
      local Slist `Slist' `S`i''
    }
  	frame put _t `vgrp' `Skm' `tt'  `Slist' if `touse', into(`frame')
	frame `frame' {
      local Z = cond("`failure'"!="","F","S")
      rename `Skm' `Z'km
      rename `vgrp' group
      forvalues i = 1/`Ngroups' {
        rename `S`i'' `Z'`i'
      }
	  rename `tt' tt
    }		
  }		 
end

// change to commas
program addcommas, rclass
  version 16.0
  numlist `0'
  local result "`r(numlist)'"
  local result : subinstr local result " " ",", all
  return local numlist "`result'"
end
