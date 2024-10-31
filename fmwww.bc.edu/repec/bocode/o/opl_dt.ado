********************************************************************************
* PROGRAM "opl_dt"
********************************************************************************
*! opl_dt, v4, GCerulli, 16oct2024
program opl_dt , eclass
version 16
syntax , xlist(varlist max=2 min=2) cate(varlist max=1 min=1)
marksample touse
markout `touse' `xlist'
********************************************************************************
qui{ // start quietly
********************************************************************************
local R1 "0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1"
local M1: word count `R1'
********************************************************************************
local R2 "0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1"
local M2: word count `R2'
********************************************************************************
********************************************************************************
local R3 "0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1"
local M3: word count `R3'
********************************************************************************
local _M =`M1'*`M2'*`M3'*8
tempname A
mat `A' = J(`_M',7,.)
********************************************************************************
local i=1
foreach k of local R1{
foreach j of local R2{
foreach h of local R3{
foreach y1 of local xlist{
foreach y2 of local xlist{
foreach y3 of local xlist{
********************************************************************************
opl_dt_c  , xlist(`xlist') x1(`y1') x2(`y2') x3(`y3') c1(`k') c2(`j') c3(`h') cate(`cate')
********************************************************************************
local yname1: word 1 of `xlist'
local yname2: word 2 of `xlist'
********************************************************************************
if "`y1'"=="`yname1'"{
	local _var1=1
	}
else if "`y1'"=="`yname2'"{
	local _var1=2
	}

if "`y2'"=="`yname1'"{
	local _var2=1
	}
else if "`y2'"=="`yname2'"{
	local _var2=2
	}

if "`y3'"=="`yname1'"{
	local _var3=1
	}
else if "`y3'"=="`yname2'"{
	local _var3=2
	}
********************************************************************************	
mat `A'[`i',1] =`_var1'  // value of "x1" in the grid
mat `A'[`i',2] =`_var2'  // value of "x2" in the grid
mat `A'[`i',3] =`_var3'  // value of "x3" in the grid
mat `A'[`i',4] =`k'  // value of "c1" in the grid
mat `A'[`i',5] =`j'  // value of "c2" in the grid
mat `A'[`i',6] =`h'  // value of "c3" in the grid
mat `A'[`i',7] =e(W_constr) // optimal welfare at c
local i=`i'+1
}
}
}
}
}
}
********************************************************************************
preserve
ereturn clear
svmat `A'
tempvar max_w
drop if `A'7==.
egen `max_w'=max(`A'7)

qui sum `max_w'  //
ereturn scalar Max_W=round(r(mean),0.01)  //

keep if `A'7 ==`max_w'
keep `A'1 `A'2 `A'3 `A'4 `A'5 `A'6 `A'7 `max_w'

* List maximands (multiple solutions)
tempname W //
mkmat `A'1 `A'2 `A'3 `A'4 `A'5 `A'6 `A'7 if `A'7==`max_w' , matrix(`W') //
noi matname `W' x1 x2 x3 c1 c2 c3 W_max , columns(1..7) explicit //

noi{
di " "
di "{hline 55}"
noi di in gr "{bf:Main results}"
di "{hline 55}"
di in gr "{bf:Policy class: 2-layer fixed-depth decision tree}"
di "{hline 55}"

matlist `W' , ///
border(rows) rowtitle(Maximand) ///
title("{bf:Welfare maximands. Optimal splitting variables: x1, x2, x3. Optimal thresholds: c1, c2, c3}") 

ereturn matrix W=`W'
}

********************************************************************************
qui sum `A'1 if `A'7==`max_w'
if r(mean)<=1.5{
	ereturn local best_x1 "`yname1'"
}
else{
	ereturn local best_x1 "`yname2'"
}
********************************************************************************
qui sum `A'2 if `A'7==`max_w'
if r(mean)<=1.5{
	ereturn local best_x2 "`yname1'"
}
else{
	ereturn local best_x2 "`yname2'"
}
********************************************************************************
qui sum `A'3 if `A'7==`max_w'
if r(mean)<=1.5{
	ereturn local best_x3 "`yname1'"
}
else{
	ereturn local best_x3 "`yname2'"
}
********************************************************************************
qui sum `A'4 if `A'7==`max_w' 
ereturn scalar best_c1=round(r(mean),0.01)
qui sum `A'5 if `A'7==`max_w'
ereturn scalar best_c2=round(r(mean),0.01)
qui sum `A'6 if `A'7==`max_w'
ereturn scalar best_c3=round(r(mean),0.01)


noi{
tempname D
mat `D'=(e(best_c1)\e(best_c2)\e(best_c3))
matrix rownames `D' = `e(best_x1)' `e(best_x2)' `e(best_x3)'
matname `D' Threshold , columns(1) explicit
matlist `D' ,  twidth(30) ///
border(rows) rowtitle(Optimal splitting variables) title("{bf: Optimal splitting variables and thresholds: average over maximands}")
di "{hline 55}"
}
restore
********************************************************************************
} // end quietly
********************************************************************************
rename _units_to_be_treated _optimal_to_be_treated
********************************************************************************
preserve
qui contract _optimal_to_be_treated
local p = _freq[2]/(_freq[1]+_freq[2])
ereturn scalar opt_perc_treat=100*round(`p',0.001)
restore
********************************************************************************
end
********************************************************************************
