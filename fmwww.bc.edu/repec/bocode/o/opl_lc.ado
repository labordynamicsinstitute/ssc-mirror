********************************************************************************
* PROGRAM "opl_lc"
********************************************************************************
*! opl_lc, v1, GCerulli, 04June2022
program opl_lc , eclass
version 16
syntax  ,  ///
xlist(varlist max=2 min=2) cate(varlist max=1 min=1)
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
opl_lc_c , xlist(`xlist') c1(`k') c2(`j') c3(`h') cate(`cate')
mat `A'[`i',1] =`k'  // value of "c1" in the grid
mat `A'[`i',2] =`j'  // value of "c2" in the grid
mat `A'[`i',3] =`h'  // value of "c3" in the grid
mat `A'[`i',4] =e(W_constr) // optimal welfare at c
local i=`i'+1
}
}
********************************************************************************
preserve
ereturn clear
svmat `A'
tempname max_w
egen `max_w'=max(`A'4)
qui sum `A'1 if `A'4==`max_w' 
ereturn scalar best_c1=r(mean)
qui sum `A'2 if `A'4==`max_w'
ereturn scalar best_c2=r(mean)
qui sum `A'3 if `A'4==`max_w'
ereturn scalar best_c3=r(mean)
restore
********************************************************************************
} // end quietly
********************************************************************************
}
rename _units_to_be_treated _optimal_to_be_treated
********************************************************************************
preserve
qui contract _optimal_to_be_treated
local p = _freq[2]/(_freq[1]+_freq[2])
ereturn scalar opt_perc_treat=100*round(`p',0.001)
restore
********************************************************************************
end
