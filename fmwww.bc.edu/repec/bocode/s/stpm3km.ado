*! version 0.3 2023-05-21


program define stpm3km
  version 16.1
  syntax [varlist(default=none)]                           ///
                    [if] [in],   [                         ///
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
                                   *                       ///
                                 ]
  if "`e(cmd)'" != "stpm3" {
    di as error "An stpm3 model has not been fitted."
    exit 198
  } 
  marksample touse
  if "`esample'" == "" {
    qui replace `touse' = `touse'*e(sample)
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
  	tempvar vgrp
    qui egen `vgrp' = cut(`varlist') if `touse', `egenopt' icodes
    qui replace `vgrp' = `vgrp' + 1 if `touse'
    qui levelsof `vgrp' if `touse'
    local Ngroups `r(r)'
    local levels `r(levels)'
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
  local standsurvtype = cond("`failure'" != "","failure","survival")
  foreach i in `levels' {
    tempvar S`i'
    local atlist `atlist' `S`i''
  }
  
  qui standsurv , `standsurvtype' timevar(`tt')        ///
                   over(`vgrp')  atvar(`atlist')

  if "`km'" == "" {
    tempvar Skm
    local kmtype = cond("`failure'" != "","f","s")
    qui sts gen `Skm' = `kmtype' if `touse', by(`vgrp')
    qui replace `Skm' = . if _t>`maxt'
  }
  
  if "`graph'" == "" {
    local c 1
    foreach i in `levels' {
      if "`km'" == "" {
        local kmline `kmline' (line `Skm' _t if `vgrp'==`i', sort lcolor("scheme p`c'") connect(stairstep ))
      }
      local pline  `pline'  (line `S`i'' `tt' , sort lcolor("scheme p`c'") lpattern(dash) lwidth(thin))
	  local ++c
    }	
    _get_gropts, graphopts(`options') getallowed(legend xtitle ytitle title)
di "`options'"

    if `"`s(title)'"' == "" {
      if `"`haspi'"' == "" {
        local vtitle: variable label `varlist'
        if `"`vtitle'"' == "" local vtitle `varlist'
        local title title(`"`vtitle'"')
      }
      else local title title("Prognostic Index")
    }
    if `"`s(ytitle)'"' == "" local ytitle = cond("`failure'" != "",`"ytitle("F(t)")"',`"ytitle("S(t)")"')
    if `"`s(xtitle)'"' == "" local xtitle xtitle("Time")

    if `"`s(legend)'"' == "" {
      local c 1
      foreach i in `levels' {
        local order `"`order' `c' "`i'""'
        local legend legend(order(`order') cols(`Ngroups'))
        local ++c
      } 
    }
    twoway   `kmline'  ///
             `pline'   ///
           , `options' `title' `xtitle' `ytitle' `legend' 
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
