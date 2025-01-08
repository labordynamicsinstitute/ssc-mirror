********************************************************************************
* PROGRAM "opl_lc_c"
********************************************************************************
*! opl_lc_c, v1, GCerulli, 11June2022
program opl_lc_c , eclass
version 16
syntax  , ///
xlist(varlist max=2 min=2) c1(numlist max=1) c2(numlist max=1) c3(numlist max=1) ///
cate(varlist max=1 min=1) [graph depvar(name)]
marksample touse
markout `touse' `xlist'
ereturn clear
ereturn scalar c1=`c1'
ereturn scalar c2=`c2'
ereturn scalar c3=`c3'
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
tempvar Z
gen `Z' = (`c1'*`X1'+`c2'*`X2'>=`c3')  // linear combination
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
if "`graph'" != ""{
local w2 = round(e(W_unconstr),0.01)
local w3 = round(e(W_constr),0.01)
local w4 = round(e(perc_treat),0.01)
********************************************************************************
tempvar XXX2
gen `XXX2' = (`c3'/`c2') - (`c1'/`c2')*`X1'
tempvar Z_star
gen `Z_star' = _units_to_be_treated
twoway (line `XXX2' `X1' if `XXX2'>=0 & `XXX2'<=1, lw(thick) lc(black) xtitle(Education) ytitle(Age)  scale($s) ylabel(0(0.2)1))  || ///
(scatter `X2' `X1'  if `Z_star'==1  , mcolor(orange) mlabsize(small) msize(small) msymbol(circle)) || /// 
(scatter `X2' `X1'  if `Z_star'==0  , mcolor(green) mlabsize(small) msize(small) msymbol(circle)) , ///
plotregion(style(none)) scheme(s1mono) ///
legend(label(1 "Linear constrain") label(2 "Treated") label(3 "Untreated") rows(1)) ///
note("Expected unconstrained average welfare = `w2'" ///
"Expected constrained average welfare = `w3'" ///
"Percentage of treated units = `w4'%") ///
title(Optimal policy assignment) subtitle(Policy class: linear combination)
********************************************************************************
}
********************************************************************************
qui count
ereturn scalar _N=r(N)
qui tab _units_to_be_treated if _units_to_be_treated==1
ereturn scalar Ntreat=r(N)
ereturn scalar Nuntreat=_N-r(N)
********************************************************************************
} // end quietly
********************************************************************************
* Display output
********************************************************************************
di " "
noi di "{hline 85}"
noi di in gr "{bf:Policy class: Linear-combination}"
di " "

noi di in gr "{ul:Main results}"
di " "
noi di  "Learner = " "Regression adjustment"  _continue
noi di _col(48) "Target variable = "  "`e(dep_var)'"
noi di "N. of units = " e(_N)    _continue
noi di _col(48) "Selection variables = " "`e(sel_vars)'"
noi di "Lin. comb.parameter c1 = " e(c1)    _continue
noi di _col(48) "Lin. comb.parameter c2 = " e(c2)
noi di "Lin. comb.parameter c3 = " e(c3)  _continue
noi di _col(48) "Average unconstrained welfare = " e(W_unconstr)
noi di "Average constrained welfare = " e(W_constr)    _continue
noi di _col(48) "Percentage of treated = " e(perc_treat)
noi di  "N. of treated = " e(Ntreat) _continue
noi di _col(48) "N. of untreated = " e(Nuntreat)
noi di "{hline 85}"
di " "
********************************************************************************
end
