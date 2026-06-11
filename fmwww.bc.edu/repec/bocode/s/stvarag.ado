*! Version 1.1.0 2025-03-28
*! Author: Dejin Xie (Nanchang University, China)

** Version 1.1.0 2025-03-28, option "generate" added
** Version 1.0.0 2019-09-02, the initial version

****** Aggregated Values of String Variable(s) ******

program define stvarag, rclass sortpreserve
version 13

syntax varlist (min=1 string) [if] [in] , [ By(varlist) Suffix(string) Generate(string) ///
                                  Nogen Dups Uniq Parse(str asis) Order NOtrim ]

if "`nogen'"~="" & "`dups'"=="" & "`uniq'"=="" {
  dis as error "Option {it:{ul:n}ogen} should be set with option {it:{ul:d}ups} or {it:{ul:u}niq}."
  exit
}

if "`generate'"~="" & "`nogen'"~="" {
  dis as error "Option {it:{ul:g}enerate()} must be not set with option {it:{ul:n}ogen}."
  exit
}
if "`generate'"~="" & "`suffix'"~="" {
  dis as error "Option {it:{ul:g}enerate()} must be not set with option {it:{ul:s}uffix()}."
  exit
} 
if "`nogen'"~="" & "`suffix'"~="" {
  dis as error "Option {it:{ul:n}ogen} must be not set with option {it:{ul:s}uffix()}."
  exit
} 

if `c(stata_version)'>=14 {
  local ustr "ustr"
}

marksample touse, novarlist strok
tempvar SVAGID
gen `SVAGID'=_n

if "`by'"~="" {
  local ByOpt "bysort `by' (`SVAGID') : "
}

local VNUM: word count `varlist'
if "`generate'"~="" {
  local GNUM = wordcount("`generate'")
  if `GNUM'~=`VNUM' {
    dis as error "The number of option {it:{ul:g}enerate()} must be same as {it:varlist} (i.e. {it:``VNUM''})."
    exit
  }
}

quietly {
tokenize `varlist'
forvalues i=1/`VNUM' {
  if "`dups'"~="" {
    capture drop ``i''_dups
  }
  if "`uniq'"~="" {
    capture drop ``i''_uniq
  }
}
preserve
tempfile mySVAGfile
keep if `touse'
if `"`parse'"' == `""' | `"`parse'"' == `""""' {
  local parse " "
}
if `"`parse'"' == "null" {
  local parse ""
}
else {
  local parse : list clean parse
}

forvalues i=1/`VNUM' {
  tempvar ``i''_SVCL
  `ByOpt' gen ```i''_SVCL'=``i''[1]
  if `"`parse'"'~=`"" ""' {
    `ByOpt' replace ```i''_SVCL'=```i''_SVCL'[_n-1]+`"`parse'"'+``i'' if _n>1
  }
  else {
    `ByOpt' replace ```i''_SVCL'=```i''_SVCL'[_n-1]+" "+``i'' if _n>1
  }
  `ByOpt' replace ```i''_SVCL'=```i''_SVCL'[_N]
  if "`notrim'"=="" {
    replace ```i''_SVCL'=`ustr'trim(itrim(```i''_SVCL'))
  }
  if "`order'"~="" | "`dups'"~="" | "`uniq'"~="" {
    if "`dups'"~="" {
      gen ``i''_dups=""
      label var ``i''_dups "Duplicate values of ``i''"
    }
    if "`uniq'"~="" {
      gen ``i''_uniq=""
      label var ``i''_uniq "Unique values of ``i''"
    }
    if `"`parse'"'~=`"" ""' {
      replace ```i''_SVCL'=subinstr(```i''_SVCL', `"`parse' "',`"`parse'"',.)
      replace ```i''_SVCL'=subinstr(```i''_SVCL', `" `parse'"',`"`parse'"',.)
      replace ```i''_SVCL'=subinstr(```i''_SVCL'," ","_.-",.)
      replace ```i''_SVCL'=subinstr(```i''_SVCL',`"`parse'"'," ",.)
    }
    tempvar GPBYID
    if "`by'"~="" {
      egen `GPBYID'=group(`by')
    }
    else {
      gen `GPBYID'=1
    }
    sum `GPBYID'
    local MAXGYID=r(max)
    forvalues k=1/`MAXGYID' {
      forvalues j=1/`c(N)' {
        if `GPBYID'[`j']==`k' & ```i''_SVCL'[`j']~="" {
          local StORDRs=```i''_SVCL'[`j']
          if "`order'"~="" {
            local StORDRs : list sort StORDRs
            replace ```i''_SVCL'=`"`StORDRs'"' if `GPBYID'==`k'
          }
          if "`dups'"~="" {
            local StVDUPs : list dups StORDRs
            replace ``i''_dups=`"`StVDUPs'"' if `GPBYID'==`k'
          }
          if "`uniq'"~="" {
            local StVUNQs : list uniq StORDRs
            replace ``i''_uniq=`"`StVUNQs'"' if `GPBYID'==`k'
          }
          continue, break
        }
      }
    }
    if `"`parse'"'~=`"" ""' {
      replace ```i''_SVCL'=subinstr(```i''_SVCL'," ",`"`parse'"',.)
      replace ```i''_SVCL'=subinstr(```i''_SVCL',"_.-"," ",.)
    }
    if "`dups'"~="" {
      if `"`parse'"'~=`"" ""' {
        replace ``i''_dups=subinstr(``i''_dups," ",`"`parse'"',.)
        replace ``i''_dups=subinstr(``i''_dups,"_.-"," ",.)
      }
    }
    if "`uniq'"~="" {
      if `"`parse'"'~=`"" ""' {
        replace ``i''_uniq=subinstr(``i''_uniq," ",`"`parse'"',.)
        replace ``i''_uniq=subinstr(``i''_uniq,"_.-"," ",.)
      }
    }
  }
  save `mySVAGfile', replace
  restore

  merge 1:1 `SVAGID' using `mySVAGfile', nogen
  if "`generate'`suffix'`nogen'"=="" {
    replace ``i''=```i''_SVCL' if `touse'
  }
  if "`generate'"~="" {
    capture drop `=word("`generate'",`i')'
    gen `=word("`generate'",`i')'=```i''_SVCL'
    label var `=word("`generate'",`i')' "Aggregated values of ``i''"
  }
  if "`suffix'"~="" {
    capture drop ``i''_`suffix'
    gen ``i''_`suffix'=```i''_SVCL'
    label var ``i''_`suffix' "Aggregated values of ``i''"
  }
}
}  /* Close brace of quietly */

end
