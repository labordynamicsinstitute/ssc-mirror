*! Version 1.0.0 2024-04-09
*! Author: Dejin Xie (Nanchang University, China)

*** Rename Variables as Their nth Row Values ***

program define nrow2
version 12

syntax [varlist] [ , Nrow(int 1) Prefix(string) Onlynum Ignore(string) ///
                     Trim Space Keep Destring Compress ]

if "`trim'"~="" & "`space'"~="" {
  dis as err "option {it:{ul:t}rim} or {it:{ul:n}ospace} should be set at most one."
  error 198  
} 

local nvar: word count `varlist'
  if `nvar'==0 {
    quietly ds
    local varlist=r(varlist)
}

confirm integer number `nrow'
if `nrow' > _N {
  display as error "#row is out of range"
  exit 198
}
if "`prefix'"=="" {
  foreach v of varlist `varlist' {
    if "`trim'"~="" {
      local NewNm `=itrim(trim("`=`v'[`nrow']'"))'
    }
    else if "`space'"~="" {
      if `c(stata_version)'>=14 {
        local NewNm `=ustrregexra("`=`v'[`nrow']'","\s","")'
      }
      else {
        local NewNm `=subinstr("`=`v'[`nrow']'"," ","",.)'
      }
    }
    else {
      local NewNm `"`=`v'[`nrow']'"'
    }
    if "`ignore'"~="" {
      local NewNm `=subinstr("`NewNm'","`ignore'","",.)'
    }
    capture rename `v' `NewNm'
    if _rc == 198 {
      local NewNm = strtoname("`NewNm'",1)
      capture rename `v' `NewNm'
    }
  }
}
else {
  if "`onlynum'"=="" {
    foreach v of varlist `varlist' {
      if "`trim'"~="" {
        local NewNm `prefix'`=itrim(trim("`=`v'[`nrow']'"))'
      }
      else if "`space'"~="" {
        if `c(stata_version)'>=14 {
          local NewNm `prefix'`=ustrregexra("`=`v'[`nrow']'","\s","")'
        }
        else {
          local NewNm `prefix'`=subinstr("`=`v'[`nrow']'"," ","",.)'
        }
      }
      else {
        local NewNm `"`prefix'`=`v'[`nrow']'"'
      }
      if "`ignore'"~="" {
        local NewNm `=subinstr("`NewNm'","`ignore'","",.)'
      }
      capture rename `v' `NewNm'
      if _rc == 198 {
        local NewNm = strtoname("`NewNm'",1)
        capture rename `v' `NewNm'
      }
    }
  }
  else {
    local IgnOpt "ignore(`ignore')"
    foreach v of varlist `varlist' {
      preserve
      capture destring `v' , replace `IgnOpt'
      capture confirm numeric variable `v'
      if !_rc==0 {
        if "`trim'"~="" {
          local NewNm `=itrim(trim("`=`v'[`nrow']'"))'
        }
        else if "`space'"~="" {
          if `c(stata_version)'>=14 {
            local NewNm `=ustrregexra("`=`v'[`nrow']'","\s","")'
          }
          else {
            local NewNm `=subinstr("`=`v'[`nrow']'"," ","",.)'
          }
        }
        else {
          local NewNm `"`=`v'[`nrow']'"'
        }
        if "`ignore'"~="" {
          local NewNm `=subinstr("`NewNm'","`ignore'","",.)'
        }
        capture rename `v' `NewNm'
        if _rc == 198 {
          local NewNm = strtoname("`NewNm'",1)
          capture rename `v' `NewNm'
        }          
      }
      else {
        local NewNm `"`prefix'`=`v'[`nrow']'"'
      }
      restore
      capture rename `v' `NewNm'
      if _rc == 198 {
        local NewNm = strtoname("`NewNm'",1)
        capture rename `v' `NewNm'
      }
    }
  }
}

if "`keep'"=="" {
  drop in 1/`nrow'
}

if "`destring'"~="" {
  destring, replace
}

if "`compress'"~="" {
  compress
}

end
