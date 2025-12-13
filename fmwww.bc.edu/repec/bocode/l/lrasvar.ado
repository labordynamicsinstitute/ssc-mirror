*! Version 1.1.0 2022-06-27
*! Author: Dejin Xie (Nanchang University, China)

** Version 1.1.0 2022-06-27, option "drop" added
** Version 1.0.0 2020-03-23, the initial version

***** Label or Rename Varlist as the Contents of the Specified Variable *****

program define lrasvar, rclass sortpreserve
version 13

syntax [varlist] , As(varname) [ Force Rename Both Trim Drop ]

if "`rename'"~="" & "`both'"~="" {
  dis as err "option {it:rename} is not allowed with {it:both}."
  error 198  
} 

quietly {
ds `varlist'
local LabAsVar=r(varlist)
if "`drop'"~="" {
  local LabAsVar : list LabAsVar - as
}
order `as' , last
count if missing(`as')==0

if `=wordcount("`LabAsVar'")'>r(N) {
  if "`force'"=="" {
    noisily dis as error "The number of variables is more than obs of {it:`as'}."
    exit
  }
  else {
    noisily dis as res "The number of variables is more than obs of {it:`as'}."
  }
}
if "`trim'"~="" {
  capture confirm string variable `as'
  if !_rc==1 {
    replace `as'=trim(itrim(`as'))
  }
}
if "`rename'"=="" {
  forvalues i=1/`=min(`=wordcount("`LabAsVar'")',r(N))' {
    if `i'<=r(N) {
      label var `=word("`LabAsVar'",`i')' `"`=`as'[`i']'"'
    }
  }
}
if "`rename'"~="" | "`both'"~="" {
  forvalues i=1/`=min(`=wordcount("`LabAsVar'")',r(N))' {
    if `i'<=r(N) {
      capture rename `=word("`LabAsVar'",`i')' `=strtoname(`"`=`as'[`i']'"',1)'
    }
  }
}
if "`drop'"~="" {
  drop `as'
}
}    /* Close brace of quietly */
end
