capture drop mads
program define mads, byable(recall) rclass
 version 9.2
 syntax varlist(numeric) [if] [in]
 display
 display as text "            Variable        N    Median       MAD"
 display as text "            --------------------------------------"
 marksample touse
 foreach var of local varlist {
 if "`if'" ~= "" | "`in'" ~= "" {
  quietly keep `if' `in'
 }
 quietly summarize `var' if `touse', detail
 local medi = r(p50)
 local n = r(N)
 capture drop devi
 quietly generate devi = abs(`var' - `medi')
 quietly summarize devi, detail
 local mad = r(p50)*1.4826
 display as result %20s "`var'" %9.0f `n'  %10.2f `medi'  %10.2f `mad'
 drop devi
 }
 return scalar N = `n'
 return scalar Mdn = `medi'
 return scalar MAD = `mad'
end
/*ends*/


