*! Version 1.3.0 2024-03-05
*! Author: Dejin Xie (Nanchang University, China)

** Version 1.3.0 2024-03-05, option "norm" Modified
** Version 1.2.0 2022-06-30, option "base" added
** Version 1.1.0 2019-12-15, option "smooth" added
** Version 1.0.0 2018-11-16, the initial version

****** The Entropy Weight Method (EWM) ******

program define ewm, rclass sortpreserve
version 13

syntax varlist (numeric) [if] [in], [ Score(string) UNdes(varlist) By(varlist) ///
                          Norm(string) SHift(numlist max=1 min=1 >0 <=1) ///
                          SMooth(numlist max=1 min=1 >0 <1) Raw Pv BAse List Keep ]

local VNUM : word count `varlist'
tokenize `varlist'

tempvar EWMID
gen `EWMID'=_n

if `c(stata_version)'>=14 {
  local ustr "ustr"
}

marksample touse, novarlist

if "`score'"=="" {
  local score "EW_Score"
}
if "`by'"~="" {
  local BY_TIME "bysort `by' (`EWMID') :"
  local TIME_BY ", by(`by')"
  if "`base'"~="" {
    tempvar ByBa
    egen `ByBa'=group(`by')
  }
}
else {
  if "`base'"~="" {
    dis as err "The option {it:{ul:ba}se} must be set with option {it:{ul:b}y(varlist)}."
    exit
  }
}
if "`shift'"~="" & "`smooth'"~="" {
  dis as err "option {it:{ul:sh}ift(#)} not allowed with {it:{ul:sm}ooth(#)}."
  error 198
}
if "`raw'"~="" & "`pv'"~="" {
  dis as err "option {it:raw} not allowed with {it:pv}."
  error 198
}

if "`norm'"~="" {
  local norm = upper("`norm'")
  if inlist("`norm'","MM","MX","L1","L2")==0 {
    dis as error `"The option {it:{ul:n}orm(method)} must be one of "{it:MM}", "{it:MX}", "{it:L1}" or "{it:L2}" !"'
    exit(198)
  }
  if inlist("`norm'","L1","L2") & "`base'"~="" & "`by'"~="" {
    dis as text "The option {it:{ul:ba}se} is not worked since option {it:{ul:n}orm(`norm')} is set."
  }
}
else {
  local norm "MM"
}

quietly {
capture drop `score'
capture drop *_EW

capture assert `touse'==1
local TouSeE=!_rc
if `TouSeE'==0 {
  preserve
  tempfile myEWMfile
  keep if `touse'
}

capture drop *_MNRM
forvalues vi=1/`VNUM' {
  tempvar ``vi''_MAXM ``vi''_MINM ``vi''_pc  ``vi''_NMS ``vi''_EJ
  inlist("`norm'","MM","MX") {
    if "`base'"=="" { 
      `BY_TIME' egen ```vi''_MAXM'=max(``vi'')
      `BY_TIME' egen ```vi''_MINM'=min(``vi'')
    }
    else {
      sum ``vi'' if `ByBa'==1
      gen ```vi''_MAXM'=`r(max)'
      gen ```vi''_MINM'=`r(min)'
    }
  }
  if "`norm'"=="MM" {
    if `ustr'regexm("`undes'","(^| )``vi''( |$)") {
      gen ``vi''_MNRM=(```vi''_MAXM'-``vi'')/(```vi''_MAXM'-```vi''_MINM')
    }
    else {
      gen ``vi''_MNRM=(``vi''-```vi''_MINM')/(```vi''_MAXM'-```vi''_MINM')
    }
    if "`shift'"~="" replace ``vi''_MNRM=``vi''_MNRM+`shift'
    if "`smooth'"~="" replace ``vi''_MNRM=`smooth'+(1-`smooth')*``vi''_MNRM
    `BY_TIME' egen ```vi''_pc'=pc(``vi''_MNRM), prop
  }
  if "`norm'"=="MX" {
    if `ustr'regexm("`undes'","(^| )``vi''( |$)") {
      gen ``vi''_MNRM=1-``vi''/```vi''_MAXM'
    }
    else {
      gen ``vi''_MNRM=``vi''/```vi''_MAXM'
    }
    if "`shift'"~="" replace ``vi''_MNRM=``vi''_MNRM+`shift'
    if "`smooth'"~="" replace ``vi''_MNRM=`smooth'+(1-`smooth')*``vi''_MNRM
    `BY_TIME' egen ```vi''_pc'=pc(``vi''_MNRM), prop
  }
  if "`norm'"=="L1" {
    `BY_TIME' egen ``vi''_MNRM = pc(``vi'') , prop
    replace ``vi''_MNRM = 1-``vi''_MNRM if `ustr'regexm("`undes'","(^| )``vi''( |$)")
    gen ```vi''_pc' = ``vi''_MNRM

  }
  if "`norm'"=="L2" {
    tempvar ``vi''_NMQ
    `BY_TIME' egen ```vi''_NMQ'=total(``vi''^2)
    replace ```vi''_NMQ'=(```vi''_NMQ')^0.5
    gen ``vi''_MNRM=``vi''/```vi''_NMQ'
    replace ``vi''_MNRM = 1-``vi''_MNRM if `ustr'regexm("`undes'","(^| )``vi''( |$)")
    `BY_TIME' egen ```vi''_pc'=pc(``vi''_MNRM), prop
  }
  `BY_TIME' egen ```vi''_NMS'=count(``vi'')
  gen ```vi''_EJ'=-```vi''_pc'*ln(```vi''_pc')/ln(```vi''_NMS')
  capture drop ``vi''_ET
  `BY_TIME' egen ``vi''_ET=total(```vi''_EJ')
}
tempvar VENT
egen `VENT'=rowtotal(*_ET)
forvalues vi=1/`VNUM' {
  capture drop ``vi''_EW
  gen ``vi''_EW=(1-``vi''_ET)/(`VNUM'-`VENT')
  label var ``vi''_EW "Entropy Weight of ``vi''"
  drop ``vi''_ET
  capture drop ``vi''_SCOR
  if "`raw'"~="" {
    gen ``vi''_SCOR=``vi''*``vi''_EW
    replace ``vi''_SCOR=(```vi''_MAXM'-``vi'')*``vi''_EW if `ustr'regexm("`undes'","(^| )``vi''( |$)")
  }
    if "`pv'"~="" {
    gen ``vi''_SCOR=```vi''_pc'*``vi''_EW
  }
  if "`raw'"=="" & "`pv'"=="" {
    if "`norm'"=="MM" | "`norm'"=="MX" {
      if "`shift'"~="" replace ``vi''_MNRM=``vi''_MNRM-`shift'
      if "`smooth'"~="" replace ``vi''_MNRM=(``vi''_MNRM-`smooth')/(1-`smooth')
    }
    gen ``vi''_SCOR=``vi''_MNRM*``vi''_EW
  }
}
capture drop `score'
egen `score'=rowtotal(*_SCOR)
if "`raw'"~="" {
  label var `score' "Comprehensive Score (by raw data)"
}
if "`pv'"~="" {
  label var `score' "Comprehensive Score (by proportional data)"
}
if "`raw'"=="" &"`pv'"=="" {
  label var `score' "Comprehensive Score (by Min-Max data)"
}
order *_EW, after(`score')
drop *_SCOR
drop *_MNRM

if `TouSeE'==0 {
  save `myEWMfile', replace
  restore
  merge 1:1 `EWMID' using `myEWMfile', nogenerate
}

preserve
collapse (mean) *_EW if `touse' `TIME_BY'
tempname EntW
if "`by'"=="" {
  mkmat *_EW, matrix(`EntW')
  matrix colnames `EntW' = `varlist'
  matrix rownames `EntW' = EWeight
  local ew ""
  foreach vw of varlist *_EW {
    local ew "`ew' `=`vw'[1]'"
  }
  local ew=trim("`ew'")
  return local ew `ew'
}
else {
  mkmat *_EW, matrix(`EntW') rownames(`by')
  matrix colnames `EntW' = `varlist'
}
return matrix EW = `EntW'
if "`list'"~="" {
  noisily dis as green "The entropy weight of {res:`varlist'} are as follows: "
  noisily list
}
restore

if "`keep'"=="" {
  drop *_EW
}
}  /* Close brace of quietly */
end
