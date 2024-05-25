********************************************************************************
* PROGRAM "opl_dt_c"
********************************************************************************
*! opl_dt_c, v2, GCerulli, 24may2024
program opl_dt_c , eclass
version 16
syntax , ///
xlist(varlist max=2 min=2) ///
x1(varlist max=1 min=1) ///
x2(varlist max=1 min=1) ///
x3(varlist max=1 min=1) ///
c1(numlist max=1) ///
c2(numlist max=1) ///
c3(numlist max=1) ///
cate(varlist max=1 min=1) ///
[graph depvar(name)]
marksample touse
markout `touse' `x1' `x2' `x3' 
********************************************************************************
ereturn clear
ereturn scalar c1=`c1'
ereturn scalar c2=`c2'
ereturn scalar c3=`c3'
ereturn local x1 "`x1'"
ereturn local x2 "`x2'"
ereturn local x3 "`x3'"
ereturn local sel_vars "`xlist'"
ereturn local dep_var "`depvar'"
cap drop _optimal_to_be_treated
********************************************************************************
gettoken X1 X2: xlist
********************************************************************************
count if `touse'
local NN=r(N)
********************************************************************************
* Standardize threshold variables [0-1]
********************************************************************************
local i=1
foreach var of local xlist{
cap drop `var'_std
qui sum `var' if `touse'
qui gen double `var'_std = (`var' - `r(min)') / (`r(max)'-`r(min)')  if `touse'
local X`i' "`var'_std"
local i=`i'+1
}
********************************************************************************
local varlist2 "`x1' `x2' `x3'"
local i=1
foreach var of local varlist2{
cap drop _`var'_std
qui sum `var' if `touse'
qui gen double _`var'_std = (`var' - `r(min)') / (`r(max)'-`r(min)')  if `touse'
local x`i' "_`var'_std"
local i=`i'+1
}
********************************************************************************
* Optimal policy learning
********************************************************************************	
tempvar d1 d2 d3
gen `d1' = (`x1'>=`c1') if `touse' // center
gen `d2' = (`x2'>=`c2') if `d1'==1 & `touse' // dx
replace `d2' = (`x3'>=`c3') if `d1'==0 & `touse' // sx
tempvar Z
gen `Z' = (`d1'==0 & `d2'==1) | (`d1'==1 & `d2'==1) if `touse'
********************************************************************
tempvar D_opt
gen `D_opt'=(`cate'>=0) if `touse'
tempvar Welfare_opt
gen `Welfare_opt'=`cate'*`D_opt' if `D_opt'==1 & `touse'
qui sum `Welfare_opt' if `touse'
local W_opt=r(mean)
ereturn scalar W_unconstr=`W_opt'
********************************************************************************
tempvar D_opt_c_new
gen `D_opt_c_new' = `D_opt'*`Z' if `touse'
tempvar Welfare_opt_c
gen `Welfare_opt_c'=`cate'*`D_opt_c_new' if `D_opt_c_new'==1 & `touse'
qui sum `Welfare_opt_c' if `touse'
local W_opt_c=r(mean) // optimal average welfare constrained at threshold c 
ereturn scalar W_constr=`W_opt_c'
********************************************************************************
qui sum `D_opt_c_new'
ereturn scalar perc_treat=100*round(r(mean),0.001)
********************************************************************************
cap drop _units_to_be_treated
gen _units_to_be_treated = `D_opt_c_new'
la var _units_to_be_treated "1 = unit to treat; 0 = unit not to treat"
********************************************************************************
tempvar Z_star
gen `Z_star' = _units_to_be_treated
if "`graph'" != ""{
local w2 = round(e(W_unconstr),0.01)
local w3 = round(e(W_constr),0.01)
local w4 = round(e(perc_treat),0.01)	
tw (scatter `X2' `X1'  if `Z_star'==1  , ///
mcolor(orange) mlabsize(small) msize(small) msymbol(circle)) || /// 
(scatter `X2' `X1'  if `Z_star'==0  ,    ///
mcolor(green) mlabsize(small) msize(small) msymbol(Oh)) , ///
plotregion(style(none)) scheme(s1mono) ///
legend(label(1 "Treated") label(2 "Untreated")) ///
note("Expected unconstrained average welfare = `w2'" ///
"Expected constrained average welfare = `w3'" ///
"Percentage of treated units = `w4'%") ///
title(Optimal policy assignment) subtitle(Policy class: fixed-depth decision-tree)
}
********************************************************************************
qui count
ereturn scalar _N=r(N)
qui tab _units_to_be_treated if _units_to_be_treated==1
ereturn scalar Ntreat=r(N)
ereturn scalar Nuntreat=_N-r(N)
********************************************************************************
* Display output
********************************************************************************
di " "
noi di "{hline 95}"
noi di in gr "{bf:Policy class: Fixed-depth decision-tree}"
di " "

noi di in gr "{ul:Main results}"
di " "
noi di  "Learner = " "Regression adjustment"  _continue
noi di _col(50) "Target variable = "  "`e(dep_var)'"

noi di "N. of units = " e(_N)    _continue
noi di _col(50) "Selection variables = " "`e(sel_vars)'"

noi di "Threshold first splitting var. = " e(c1)    _continue
noi di _col(50) "Threshold second splitting var. = " e(c2)

noi di "Threshold third splitting var. =  = " e(c3)  _continue
noi di _col(50) "Average unconstrained welfare = " e(W_unconstr)

noi di "Average constrained welfare = " e(W_constr)    _continue
noi di _col(50) "Percentage of treated = " e(perc_treat)

noi di  "N. of treated = " e(Ntreat) _continue
noi di _col(50) "N. of untreated = " e(Nuntreat)

noi di  "First splitting variable x1 = " "`e(x1)'" _continue
noi di _col(50) "Second splitting variable x2 = " "`e(x2)'"

noi di  "Third splitting variable x3 = " "`e(x3)'"

noi di "{hline 95}"
di " "
********************************************************************************
end