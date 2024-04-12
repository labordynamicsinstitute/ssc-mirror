********************************************************************************
* PROGRAM "opl_tb_c"
********************************************************************************
*! opl_tb_c, v1, GCerulli, 04June2022
program opl_tb_c , eclass
version 16
syntax  , ///
xlist(varlist max=2 min=2) c1(numlist max=1) c2(numlist max=1) cate(varlist max=1 min=1) [graph depvar(name)]
marksample touse
markout `touse' `xlist'
ereturn clear
ereturn scalar c1=`c1'
ereturn scalar c2=`c2'
cap drop _optimal_to_be_treated
ereturn local sel_vars "`xlist'"
ereturn local dep_var "`depvar'"
********************************************************************************
qui{ // start quietly
********************************************************************************
count if `touse'
local NN=r(N)
********************************************************************************
* Standardize threshold variables [0-1]
********************************************************************************
local xstd ""
foreach var of local xlist{
cap drop `var'_std
qui sum `var' if `touse'
qui gen double `var'_std = (`var' - `r(min)') / (`r(max)'-`r(min)')  if `touse'
local xstd `xstd' `var'_std
}
local xlist "`xstd'"
********************************************************************************
* Optimal policy learning
********************************************************************************	
tempvar D_opt
gen `D_opt'=(`cate'>=0) if `touse'
tempvar Welfare_opt
gen `Welfare_opt'=`cate'*`D_opt' if `D_opt'==1 & `touse'
qui sum `Welfare_opt' if `touse'
local W_opt=r(mean)
ereturn scalar W_unconstr=`W_opt'
********************************************************************************
gettoken X1 X2 : xlist
tempvar Z1
tempvar Z2
gen `Z1'=(`X1'>`c1') // theshold 1 constrain ("X1") 
gen `Z2'=(`X2'>`c2') // theshold 2 constrain ("X2")
tempvar D_opt_c_new
gen `D_opt_c_new' = `D_opt'*`Z1'*`Z2' if `touse'
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
la var _units_to_be_treated "1 = unit to treat; 0 = unit not to treat "
********************************************************************************
if "`graph'" != ""{
local w2 = round(e(W_unconstr),0.01)
local w3 = round(e(W_constr),0.01)
local w4 = round(e(perc_treat),0.01)
********************************************************************************
tempvar Z_star
gen `Z_star' = _units_to_be_treated
tw ///
(scatter `X1' `X2', mcolor(white) yline(`c1', lp(dash) lw(thick)) xline(`c2',lp(dash) lw(thick))) || ///
(scatter `X1' `X2' if (`Z_star'==1) , mcolor(orange) msize(small) msymbol(circle)) || ///
(scatter `X1' `X2' if (`Z_star'==0) , mcolor(green)  msize(small) msymbol(Oh))  || , ///
plotregion(style(none)) scheme(s1mono) ///
legend(label(1 "- - Boundary") label(2 "Treated") label(3 "Untreated") rows(1)) ///
note("Expected unconstrained average welfare = `w2'" ///
"Expected constrained average welfare = `w3'" ///
"Percentage of treated units = `w4'%") ///
title(Optimal policy assignment) subtitle(Policy class: threshold-based)
********************************************************************************
}
********************************************************************************
qui count
ereturn scalar _N=r(N)
qui tab _units_to_be_treated if _units_to_be_treated==1
ereturn scalar Ntreat=r(N)
ereturn scalar Nuntreat=_N-r(N)
} // end quietly
********************************************************************************
* Display output
********************************************************************************
di " "
noi di "{hline 85}"
noi di in gr "{bf:Policy class: Threshold-based}"
di " "
noi di in gr "{ul:Main results}"
di " "
noi di  "Learner = " "Regression adjustment"  _continue
noi di _col(48) "Target variable = "  "`e(dep_var)'"
noi di "N. of units = " e(_N)    _continue
noi di _col(48) "Selection variables = " "`e(sel_vars)'"
noi di "Threshold value c1 = " e(c1)    _continue
noi di _col(48) "Threshold value c2 = " e(c2)
noi di "Average unconstrained welfare = " e(W_unconstr)    _continue
noi di _col(48) "Average constrained welfare = " e(W_constr)
noi di "Percentage of treated = " e(perc_treat) _continue
noi di _col(48) "N. of treated = " e(Ntreat)
noi di "N. of untreated = " e(Nuntreat)
noi di "{hline 85}"
di " "
********************************************************************************
end
