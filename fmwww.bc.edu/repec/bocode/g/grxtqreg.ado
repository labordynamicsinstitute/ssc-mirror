*! Version 1.0.0 2018-11-26
*! Author: Dejin Xie (Nanchang University, China)

****** Graph the coefficients of a Quantile Regression for Panel Data (QRPD) ******

capture program drop grxtqreg
program define grxtqreg, rclass sortpreserve
version 14

syntax varlist (numeric) [if] [in] , [Qnum(integer 20) ci fxe fxeci COMbine SCHeme(string)]

qui capture xtset
capture confirm e `r(panelvar)'
if _rc!=0 {
   dis as error "You must {help xtset} your data before using {cmd:grxtqreg},see help {help grxtqreg}!"
   exit
}

marksample touse, novarlist strok
markout `touse' `varlist'
tokenize `varlist'
local depv "`1'"
macro shift
local indeps "`*'"
_fv_check_depvar `depv'
local vk: word count `indeps'
***
preserve 
***
if `vk'>1 & "`combine'"=="" {
   local grss grss
}

if "`fxe'`fxeci'"~="" {
  quietly xtset
  quietly xtreg `depv' `indeps' if `touse', fe
  forvalues j=1/`vk' {
    local bf`j'=_b[``j'']
    local yline`j' "yline(`bf`j'', lp(_.))"
    if "`fxeci'"~="" {
      local bs`j'=r(table)["ul","``j''"]
      local bt`j'=r(table)["ll","``j''"]
      local yline2`j' "yline(`bs`j'' `bt`j'', lp(.))"
    }
  }
}

capture drop xtgrq_*

forvalues j=1/`vk' {
  quietly gen xtgrq_``j'' = .
  quietly gen xtgup_``j'' = .
  quietly gen xtglw_``j'' = .
}

tempvar pctn
quietly gen `pctn' = .

forvalues i=1/`=`qnum'-1' {
  quietly replace `pctn' = `i'/`qnum' in `i'
  quietly xtset
  quietly xtqreg `depv' `indeps' if `touse', id(`r(panelvar)') q(`=`i'/`qnum'')
  forvalues j=1/`vk' {
    quietly replace xtgrq_``j'' = _b[``j''] in `i'
    quietly replace xtgup_``j'' = r(table)["ul","``j''"] in `i'
    quietly replace xtglw_``j'' = r(table)["ll","``j''"] in `i'
  }
}

if "`scheme'"~=""{
  local mysch "scheme(`scheme')"
}
else {
  local mysch "scheme(s1color)"
}

graph drop _all
if "`combine'"==""{
  forvalues j=1/`vk' {
    if "`ci'"=="" {
      quietly `grss' twoway (line xtgrq_``j'' `pctn') ///
       , `mysch' `yline`j'' `yline2`j'' ytitle("{bf:``j''}") xtitle("Quantile")    legend(off) 
    }
    else {
      quietly `grss' twoway (line xtgrq_``j'' `pctn') (line xtgup_``j'' `pctn', lp(-)) ///
      (line xtglw_``j'' `pctn', lp(-)), `mysch' `yline`j'' `yline2`j'' ytitle("{bf:``j''}") xtitle("Quantile") legend(off)
    }
  }
}
else{
  forvalues j=1/`vk' {
    if "`ci'"=="" {
      quietly twoway (line xtgrq_``j'' `pctn') ///
       , `mysch' `yline`j'' `yline2`j'' ytitle("{bf:``j''}") xtitle("Quantile")    name(``j'') nodraw legend(off)
    }
    else {
      quietly twoway (line xtgrq_``j'' `pctn') (line xtgup_``j'' `pctn', lp(-)) ///
      (line xtglw_``j'' `pctn', lp(-)), `mysch' `yline`j'' `yline2`j'' ytitle("{bf:``j''}") xtitle("Quantile") name(``j'') nodraw legend(off)
    }
  }
  quietly graph combine `indeps', `mysch'
}

***
restore
***
capture drop xtgrq_*
capture drop xtgup_*
capture drop xtglw_*
***
end
