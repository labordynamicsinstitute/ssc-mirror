********************************************************************************
* PROGRAM "opl_tb"
********************************************************************************
*! opl_tb, v2, GCerulli, 16oct2024
program opl_tb , eclass
version 16
syntax  ,  ///
xlist(varlist max=2 min=2) cate(varlist max=1 min=1)
marksample touse
markout `touse' `xlist'
********************************************************************************
ereturn local sel_vars "`xlist'" 
********************************************************************************
qui{ // start quietly
********************************************************************************
local R1 "0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0"
local M1: word count `R1'
********************************************************************************
local R2 "0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0"
local M2: word count `R2'
********************************************************************************
local _M =`M1'*`M2'
tempname A
mat `A' = J(`_M',3,.)
********************************************************************************
local i=1
foreach k of local R1{
foreach j of local R2{
********************************************************************************
foreach x of local xlist{
cap drop `x'_std
}
********************************************************************************
opl_tb_c , xlist(`xlist') c1(`k') c2(`j') cate(`cate')
mat `A'[`i',1] =`k'  // value of "X1" in the grid
mat `A'[`i',2] =`j'  // value of "X2" in the grid
mat `A'[`i',3] =e(W_constr) // optimal welfare at c=j
local i=`i'+1
}
}
********************************************************************************
preserve
ereturn clear
svmat `A'
tempname max_w
egen `max_w'=max(`A'3)
qui sum `max_w'
ereturn scalar Max_W=round(r(mean),0.01)

* List maximands (multiple solutions)
tempname W
mkmat `A'1 `A'2 `A'3 if `A'3==`max_w' , matrix(`W') 
matname `W' c1 c2 W_max , columns(1..3) explicit

noi{
di " "
di "{hline 55}"
noi di in gr "{bf:Main results}"
di "{hline 55}"
di in gr "{bf:Policy class: Threshold-based}"
di "{hline 55}"

matlist `W' , ///
border(rows) rowtitle(Maximand) title("{bf: Welfare maximands. Optimal thresholds: c1, c2}") 
ereturn matrix W=`W'
}

qui sum `A'1 if `A'3==`max_w' 
ereturn scalar best_c1=round(r(mean),0.01)
qui sum `A'2 if `A'3==`max_w'
ereturn scalar best_c2=round(r(mean),0.01)

noi{
tempname C
mat `C'=(e(best_c1)\e(best_c2))
matrix rownames `C' = c1 c2
matname `C' Values , columns(1) explicit
matlist `C' , twidth(30) ///
border(rows) rowtitle(Optimal thesholds) title("{bf: Optimal thresholds: average over maximands}")
di "{hline 55}"
}
restore
********************************************************************************
} // end quietly
********************************************************************************
cap drop _units_to_be_treated
********************************************************************************
end
