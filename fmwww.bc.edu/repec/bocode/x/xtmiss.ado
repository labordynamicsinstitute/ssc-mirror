*! Version 1.1.0 2025-04-11
*! Author: Dejin Xie (Nanchang University, China)

** Version 1.1.0 2025-04-11, option "ascending" and "descending" added
** Version 1.0.0 2025-03-28, the initial version

****** Report Missing Observations of Individual and Time variables Panel Data ******

program define xtmiss , rclass sortpreserve
version 13

syntax [if] [in] , Id(varlist) Time(varlist) [ Both Punct(string) Join(string) ///
                   Exist Keep Ascending Descending Nolist * ]

marksample touse, strok

if "`nolist'"!="" & "`keep'"=="" {
  dis as res "Since ption {it:{ul:k}eep} is not set, option {it:{ul:n}olist} is ignored automatically."
  local nolist ""
}
if "`ascending'"!="" & "`descending'"!="" {
  dis as err "option {it:{ul:a}scending} or {it:{ul:d}escending} should be set at most one."
  exit
}

if "`join'"=="" {
  local join ";"
}

quietly {

capture assert `touse'==1
local TouSe=!_rc
if `TouSe'==0 {
  tempvar XtMissiD
  gen `XtMissiD'=_n
  local XtNum=`c(N)'
  preserve
  keep if `touse'
  tempfile XtMissFile
}

capture drop Id_Var
egen Id_Var = concat(`id') , punct(`punct')
capture Time_Var
egen Time_Var = concat(`time') , punct(`punct')

return local Idvars `id'
return local Timevars `time'
return scalar exist_num=`c(N)'

if "`exist'"!="" {
  capture drop Id_Exist
  bysort Time_Var : gen Id_Exist=_N
  capture drop Time_Exist
  bysort Id_Var : gen Time_Exist=_N
}

capture drop _fillin
fillin Id_Var Time_Var
return scalar balance_num=`c(N)'

count if _fillin==1
return scalar missing_num=`r(N)'
if `r(N)'==0 {
  noisily dis as res "There is no missing observations in the data (i.e. fully balanced)."
  capture drop Id_Var Time_Var Id_Exist Time_Exist _fillin
  exit
}

capture drop Id_Total
bysort Time_Var : gen Id_Total=_N
capture drop Id_Miss
bysort Time_Var : egen Id_Miss=total(_fillin==1)
capture drop Id_MProp
gen Id_MProp = Id_Miss/Id_Total
sort Id_Var Time_Var
stvarag Id_Var if _fillin==1 , by(Time_Var) parse(`join') generate(Id_MissElm)

if "`both'"!="" {
  capture drop Time_Total
  bysort Id_Var : gen Time_Total=_N
  capture drop Time_Miss
  bysort Id_Var : egen Time_Miss=total(_fillin==1)
  capture drop Time_MProp
  gen Time_MProp = Time_Miss/Time_Total
  sort Id_Var Time_Var 
  stvarag Time_Var if _fillin==1 , by(Id_Var) parse(`join') generate(Time_MissElm)
}

if `TouSe'==0 {
  sort `XtMissiD'
  count if _fillin==0
  replace `XtMissiD'=`XtNum'+_n-`r(N)' if _fillin==1
  save `XtMissFile', replace
  restore
  merge 1:1 `XtMissiD' using `XtMissFile', nogen
}

if "`Nolist'"=="" {
  preserve
  keep if `touse' & _fillin==1
  bysort Time_Var (_fillin) : keep if _n==_N
  if "`ascending'"!="" {
    sort Id_Miss Time_Var
  }
  if "`descending'"!="" {
    gsort -Id_Miss Time_Var
  }
  noisily dis _dup(90) "{bf:{res:~}}"
  noisily dis as txt "The missing situations of individual variable " as res "`id'" as txt " (" as res "n=`=Id_Total[1]'" as txt") are as follows :"
  noisily list Time_Var Id_Miss Id_MProp Id_MissElm , noobs abbr(30) `options'
  restore
  if "`both'"!="" {
    preserve
    keep if `touse' & _fillin==1
    bysort Id_Var (_fillin) : keep if _n==_N
    if "`ascending'"!="" {
      sort Time_Miss Id_Var
    }
    if "`descending'"!="" {
      gsort -Time_Miss Id_Var
    }
    noisily dis _dup(90) "{bf:{res:~}}"
    noisily dis as txt "The missing situations of time variable " as res "`time'" as txt " (" as res "T=`=Time_Total[1]'" as txt") are as follows :"
    noisily list Id_Var Time_Miss Time_MProp Time_MissElm , noobs abbr(30) `options'
    restore
  }
}

if "`keep'"!="" {
  bysort Time_Var (_fillin) : replace Id_MissElm = Id_MissElm[_N] if `touse'
  lab var Id_MissElm "Missing elements in (`id')"
  bysort Time_Var (_fillin) : replace Id_Miss = Id_Miss[_N] if `touse'
  lab var Id_Miss "Number of missing obs in (`id')"
  bysort Time_Var (_fillin) : replace Id_Total = Id_Total[_N] if `touse'
  lab var Id_Total "Total number of obs in (`id')"
  bysort Time_Var (_fillin) : replace Id_MProp = Id_MProp[_N] if `touse'
  lab var Id_MProp "Proportion of missing obs in (`id')"
  if "`exist'"!="" {
    lab var Id_Exist "Number of existing obs in (`id')"
  }
  if "`both'"!="" {
    bysort Id_Var (_fillin) : replace Time_MissElm = Time_MissElm[_N] if `touse'
    lab var Time_MissElm "Missing elements in (`time')"
    bysort Id_Var (_fillin) : replace Time_Miss = Time_Miss[_N] if `touse'
    lab var Time_Miss "Number of missing obs in (`time')"
    bysort Id_Var (_fillin) : replace Time_Total = Time_Total[_N] if `touse'
    lab var Time_Total "Total number of obs in (`time')"
    bysort Id_Var (_fillin) : replace Time_MProp = Time_MProp[_N] if `touse'
    lab var Time_MProp "Proportion of missing obs in (`time')"
    if "`exist'"!="" {
      lab var Time_Exist "Number of existing obs in (`time')"
      order Time_Exist, before(Time_Total)
    }
  }
}
else {
  capture drop Id_Miss Id_Total Id_MProp Id_MissElm `XtMissiD'
  if "`exist'"!="" {
    capture drop Id_Exist Time_Exist
  }
  if "`both'"!="" {
    capture drop Time_Miss Time_Total Time_MProp Time_MissElm
  }
}
capture drop Id_Var Time_Var
capture drop if _fillin==1
capture drop _fillin

}  /* Close brace of quietly */

end
