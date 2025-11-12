********************************************************************************
* PROGRAM "opl_lc"
********************************************************************************
*! opl_lc, v7, GCerulli, 09nov2025
program opl_lc , eclass
version 16
syntax  ,  ///
xlist(varlist max=2 min=2) cate(varlist max=1 min=1) pom0(numlist max=1)
marksample touse
markout `touse' `xlist'
********************************************************************************
qui{ // start quietly
********************************************************************************
local R1 "0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0"
local M1: word count `R1'
********************************************************************************
local R2 "0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0"
local M2: word count `R2'
********************************************************************************
********************************************************************************
local R3 "0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0"
local M3: word count `R3'
********************************************************************************
local _M =`M1'*`M2'*`M3'
tempname A
mat `A' = J(`_M',4,.)
********************************************************************************
local i=1
foreach k of local R1{
foreach j of local R2{
foreach h of local R3{
********************************************************************************
foreach x of local xlist{
cap drop `x'_std
}
********************************************************************************
opl_lc_c , xlist(`xlist') c1(`k') c2(`j') c3(`h') cate(`cate') pom0(`pom0')
cap drop _units_to_be_treated_uop 
cap drop _units_to_be_treated_cop
********************************************************************************
mat `A'[`i',1] =`k'  // value of "c1" in the grid
mat `A'[`i',2] =`j'  // value of "c2" in the grid
mat `A'[`i',3] =`h'  // value of "c3" in the grid
mat `A'[`i',4] =e(I_cop) // optimal impact at c
local i=`i'+1
}
}
}
********************************************************************************
preserve
ereturn clear
svmat `A'
tempname max_I
egen `max_I'=max(`A'4)
qui sum `max_I'
ereturn scalar Max_I=round(r(mean),0.01)
********************************************************************************
* List maximands (multiple solutions)
tempname W
mkmat `A'1 `A'2 `A'3 `A'4 if `A'4==`max_I' , matrix(`W') 
matname `W' c1 c2 c3 I_max , columns(1..4) explicit
********************************************************************************
noi{
di " "
di "{hline 55}"
noi di in gr "{bf:Main results}"
di "{hline 55}"
di in gr "{bf:Policy class: Linear-combination}"
di "{hline 55}"
********************************************************************************
matlist `W' , ///
border(rows) rowtitle(Maximand) ///
title("{bf: Welfare maximands. Optimal parameters: c1, c2, c3}") 
ereturn matrix M=`W'
}
********************************************************************************
qui sum `A'1 if `A'4==`max_I' 
ereturn scalar best_c1=round(r(mean),0.01)
qui sum `A'2 if `A'4==`max_I'
ereturn scalar best_c2=round(r(mean),0.01)
qui sum `A'3 if `A'4==`max_I'
ereturn scalar best_c3=round(r(mean),0.01)
********************************************************************************
tempname C
mat `C'=(e(best_c1)\e(best_c2)\e(best_c3))
matrix rownames `C' = c1 c2 c3
matname `C' Values , columns(1) explicit
noi{
matlist `C' , twidth(30) ///
border(rows) rowtitle(Optimal parameters) title("{bf: Optimal parameters: average over maximands}")
di "{hline 55}"
}
restore
********************************************************************************
} // end quietly
********************************************************************************
end
********************************************************************************
