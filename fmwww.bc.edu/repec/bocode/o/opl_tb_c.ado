********************************************************************************
* PROGRAM "opl_tb_c"
********************************************************************************
*! opl_tb_c, v7, GCerulli, 09nov2025
program opl_tb_c , eclass
version 16
syntax  , ///
xlist(varlist max=2 min=2) ///
c1(numlist max=1) ///
c2(numlist max=1) ///
cate(varlist max=1 min=1) ///
pom0(numlist max=1) ///
[graph depvar(name) custom_policy(varlist max=1 min=1) save_gr_op(string) save_gr_cp(string)]
********************************************************************************
* Check variable pre-existence of new generated variables
********************************************************************************
capture confirm variable _units_to_be_treated_uop
if !_rc {
    display as error "variable '_units_to_be_treated_uop' already exists"
    error 110
}
capture confirm variable _units_to_be_treated_cop
if !_rc {
    display as error "variable '_units_to_be_treated_cop' already exists"
    error 110
}
capture confirm variable _units_to_be_treated_ccp
if !_rc {
    display as error "variable '_units_to_be_treated_ccp' already exists"
    error 110
}
********************************************************************************
marksample touse
markout `touse' `xlist'
ereturn clear
ereturn scalar c1=`c1'
ereturn scalar c2=`c2'
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
* Unconstrained Optimal Policy
********************************************************************************
tempvar D_opt
gen `D_opt'=(`cate'>=0) if `touse'
cap drop _units_to_be_treated_uop
gen _units_to_be_treated_uop=`D_opt'
la var _units_to_be_treated_uop "1 = unit to treat; 0 = unit not to treat"
tempvar Impact_opt
gen `Impact_opt'=`cate'*`D_opt' if `D_opt'==1 & `touse'
qui sum `Impact_opt' if `touse'
local I_opt=r(mean)
ereturn scalar I_uop=`I_opt'
qui count if (`D_opt'==1 & `touse')
ereturn scalar Ntreat_uop=r(N)
qui count if (`D_opt'==0 & `touse')
ereturn scalar Nuntreat_uop=r(N)
qui count if `touse'
ereturn scalar N_uop=r(N)
qui count if `touse'
ereturn scalar perc_treat_uop=e(Ntreat_uop)/r(N)*100
********************************************************************************
*
********************************************************************************
* Constrained Optimal Policy
********************************************************************************
gettoken X1 X2 : xlist
tempvar Z1
tempvar Z2
gen `Z1'=(`X1'>`c1') // theshold 1 constrain ("X1") 
gen `Z2'=(`X2'>`c2') // theshold 2 constrain ("X2")
tempvar D_opt_c_new
gen `D_opt_c_new' = `D_opt'*`Z1'*`Z2' if `touse'
tempvar Impact_opt_c
gen `Impact_opt_c'=`cate'*`D_opt_c_new' if `D_opt_c_new'==1 & `touse'
qui sum `Impact_opt_c' if `touse'
local I_opt_c=r(mean) // optimal average impact constrained at threshold c 
ereturn scalar I_cop=`I_opt_c'
qui count if `touse'
ereturn scalar N_cop=r(N)
********************************************************************************
qui sum `D_opt_c_new'
ereturn scalar perc_treat_cop=100*round(r(mean),0.001)
********************************************************************************
cap drop _units_to_be_treated_cop
gen _units_to_be_treated_cop = `D_opt_c_new'
la var _units_to_be_treated_cop "1 = unit to treat; 0 = unit not to treat"
********************************************************************************
if "`graph'" != ""{
local w2 = round(e(I_uop),0.01)
local w3 = round(e(I_cop),0.01)
local w4 = round(e(perc_treat_cop),0.01)
local w5 = round(e(perc_treat_uop),0.01)
********************************************************************************
tempvar Z_star
gen `Z_star' = _units_to_be_treated_cop
tw ///
(scatter `X1' `X2', mcolor(white) yline(`c1', lp(dash) lw(thick)) xline(`c2',lp(dash) lw(thick))) || ///
(scatter `X1' `X2' if (`Z_star'==1) , mcolor(orange) msize(small) msymbol(circle)) || ///
(scatter `X1' `X2' if (`Z_star'==0) , mcolor(green)  msize(small) msymbol(Oh))  || , ///
plotregion(style(none)) scheme(s1mono) ///
legend(label(1 "- - Boundary") label(2 "Treated") label(3 "Untreated") rows(1)) ///
note("Expected unconstrained average impact = `w2'" ///
"Percentage of treated units (unconstrained) = `w5'%" ///
"Expected constrained average impact = `w3'" ///
"Percentage of treated units (constrained) = `w4'%",size(vsmall)) ///
title(Optimal policy assignment) subtitle(Policy class: threshold-based) name(gr_op , replace)
********************************************************************************
}
********************************************************************************
if ("`graph'" != "") & ("`save_gr_op'" != ""){	
graph save `save_gr_op' , replace	
}
********************************************************************************
qui count
ereturn scalar _N=r(N)
qui tab _units_to_be_treated_cop if _units_to_be_treated_cop==1
ereturn scalar Ntreat_cop=r(N)
ereturn scalar Nuntreat_cop=_N-r(N)
} // end quietly
********************************************************************************
* Display output
********************************************************************************
di " "
noi di "{hline 85}"
noi di in gr "{bf:MAIN RESULTS: OPTIMAL POLICY}"
noi di "{hline 85}"
noi di in gr "{bf:Policy class: Threshold-based}"
noi di "{hline 85}"
noi di in gr "{bf:GENERAL INFORMATION}"
noi di "{hline 85}"
noi di "Learner = " "Regression adjustment" 
noi di "Target variable = "  "`e(dep_var)'"
noi di "N. of units = " e(_N)   
noi di "Selection variables = " "`e(sel_vars)'"

noi di "{hline 85}"
noi di in gr "{bf:UNCONSTRAINED OPTIMAL POLICY (UOP)}"
noi di "{hline 85}"
noi di "Average unconstrained optimal impact (ATET_uop) = " e(I_uop) 
ereturn scalar TTET_uop = e(I_uop) * e(Ntreat_uop)
noi di "Total unconstrained optimal impact (TTET_uop) = " e(TTET_uop)
ereturn scalar AW_uop = `pom0'+ e(I_uop)*(e(perc_treat_uop)/100)
noi di "Average unconstrained optimal welfare (AW_uop) = " e(AW_uop) 
ereturn scalar TW_uop = e(AW_uop) * e(N_uop)
noi di "Total unconstrained optimal welfare (TW_uop) = " e(TW_uop)
*
noi di "N. units (uop) = " e(N_uop) 
noi di "N. of treated (uop) = " e(Ntreat_uop)
noi di "N. of untreated (uop) = " e(Nuntreat_uop)  
noi di "Percentage of treated (uop) = " e(perc_treat_uop) 
noi di "{hline 85}"
noi di in gr "{bf:CONSTRAINED OPTIMAL POLICY (COP)}"
noi di "{hline 85}"
noi di "Threshold value c1 = " e(c1)    
noi di "Threshold value c2 = " e(c2)
noi di "{hline 85}"
noi di "Average constrained optimal impact (ATET_cop) = " e(I_cop)
ereturn scalar TTET_cop = e(I_cop) * e(Ntreat_cop)
noi di "Total unconstrained optimal impact (TTET_cop) = " e(TTET_cop)
ereturn scalar AW_cop = `pom0'+ e(I_cop)*(e(perc_treat_cop)/100)
noi di "Average constrained optimal welfare (AW_cop) = " e(AW_cop)
ereturn scalar TW_cop = e(AW_cop) * e(N_cop)
noi di "Total constrained optimal welfare (TW_cop) = " e(TW_cop)
noi di "N. units (cop) = " e(N_cop)
noi di "N. of treated (cop) = " e(Ntreat_cop)
noi di "N. of untreated (cop) = " e(Nuntreat_cop)
noi di "Percentage of treated (cop) = " e(perc_treat_cop)
noi di "{hline 85}"
di " "
********************************************************************************
*
*
*
********************************************************************************
* Customized policy learning
********************************************************************************
* Unconstrained Customized Policy (UCP)
********************************************************************************
if "`custom_policy'" != ""{
qui{ // begin quietly
tempvar D_cpt
gen `D_cpt' = `custom_policy' if `touse'
tempvar Impact_cpt
gen `Impact_cpt'=`cate'*`D_cpt' if `D_cpt'==1 & `touse'
qui sum `Impact_cpt' if `touse'
local I_cpt=r(mean)
ereturn scalar I_ucp=`I_cpt'
qui count if (`D_cpt'==1 & `touse')
ereturn scalar Ntreat_ucp=r(N)
qui count if (`D_cpt'==0 & `touse')
ereturn scalar Nuntreat_ucp=r(N)
qui count if `touse'
ereturn scalar N_ucp=r(N)
qui count if `touse'
ereturn scalar perc_treat_ucp=e(Ntreat_ucp)/r(N)*100

********************************************************************************
* Constrained Customized Policy (CCP)
********************************************************************************
gettoken X1 X2 : xlist
tempvar Z1
tempvar Z2
gen `Z1'=(`X1'>`c1') // theshold 1 constrain ("X1") 
gen `Z2'=(`X2'>`c2') // theshold 2 constrain ("X2")
tempvar D_cpt_c_new
gen `D_cpt_c_new' = `D_cpt'*`Z1'*`Z2' if `touse'
tempvar Impact_cpt_c
gen `Impact_cpt_c'=`cate'*`D_cpt_c_new' if `D_cpt_c_new'==1 & `touse'
qui sum `Impact_cpt_c' if `touse'
local I_cpt_c=r(mean) // average impact constrained at threshold c 
ereturn scalar I_ccp=`I_cpt_c'
qui count if `touse'
ereturn scalar N_ccp=r(N)
********************************************************************************
qui sum `D_cpt_c_new'
ereturn scalar perc_treat_ccp=100*round(r(mean),0.001)
********************************************************************************
cap drop _units_to_be_treated_ccp
gen _units_to_be_treated_ccp = `D_cpt_c_new'
la var _units_to_be_treated_ccp "1 = unit to treat; 0 = unit not to treat "
********************************************************************************
if "`graph'" != ""{
local w2 = round(e(I_ucp),0.01)
local w3 = round(e(I_ccp),0.01)
local w4 = round(e(perc_treat_ccp),0.01)
local w5 = round(e(perc_treat_ucp),0.01)
********************************************************************************
tempvar Z_star
gen `Z_star' = _units_to_be_treated_ccp
tw ///
(scatter `X1' `X2', mcolor(white) yline(`c1', lp(dash) lw(thick)) xline(`c2',lp(dash) lw(thick))) || ///
(scatter `X1' `X2' if (`Z_star'==1) , mcolor(orange) msize(small) msymbol(circle)) || ///
(scatter `X1' `X2' if (`Z_star'==0) , mcolor(green)  msize(small) msymbol(Oh))  || , ///
plotregion(style(none)) scheme(s1mono) ///
legend(label(1 "- - Boundary") label(2 "Treated") label(3 "Untreated") rows(1)) ///
note("Expected unconstrained average impact = `w2'" ///
"Percentage of treated units (unconstrained) = `w5'%" ///
"Expected constrained average impact = `w3'" ///
"Percentage of treated units (constrained) = `w4'%" , size(vsmall)) ///
title(Customized policy assignment) subtitle(Policy class: threshold-based) name(gr_cp , replace)
********************************************************************************
}
********************************************************************************
if ("`graph'" != "") & ("`save_gr_cp'" != ""){	
graph save `save_gr_cp' , replace	
}
********************************************************************************
count
ereturn scalar _N=r(N)
qui tab _units_to_be_treated_ccp if _units_to_be_treated_ccp==1
ereturn scalar Ntreat_ccp=r(N)
ereturn scalar Nuntreat_ccp=_N-r(N)
} // end quietly
********************************************************************************
* Display output
********************************************************************************
di " "
noi di "{hline 85}"
noi di in gr "{bf:MAIN RESULTS: CUSTOMIZED POLICY}"
noi di "{hline 85}"
noi di in gr "{bf:Policy class: Threshold-based}"
noi di "{hline 85}"
noi di in gr "{bf:GENERAL INFORMATION}"
noi di "{hline 85}"
noi di "Learner = " "Regression adjustment" 
noi di "Target variable = "  "`e(dep_var)'"
noi di "N. of units = " e(_N)   
noi di "Selection variables = " "`e(sel_vars)'"

noi di "{hline 85}"
noi di in gr "{bf:UNCONSTRAINED CUSTOMIZED POLICY (UCP)}"
noi di "{hline 85}"
noi di "Average unconstrained optimal impact (ATET_ucp) = " e(I_ucp) 
ereturn scalar TTET_ucp = e(I_ucp) * e(Ntreat_ucp)
noi di "Total unconstrained optimal impact (TTET_ucp) = " e(TTET_ucp)
ereturn scalar AW_ucp = `pom0'+ e(I_ucp)*(e(perc_treat_ucp)/100)
noi di "Average unconstrained optimal welfare (AW_ucp) = " e(AW_ucp) 
ereturn scalar TW_ucp = e(AW_ucp) * e(N_ucp)
noi di "Total unconstrained optimal welfare (TW_ucp) = " e(TW_ucp)
*
noi di "N. units (ucp) = " e(N_ucp) 
noi di "N. of treated (ucp) = " e(Ntreat_ucp)
noi di "N. of untreated (ucp) = " e(Nuntreat_ucp)  
noi di "Percentage of treated (ucp) = " e(perc_treat_ucp) 
noi di "{hline 85}"
noi di in gr "{bf:CONSTRAINED CUSTOMIZED POLICY (CCP)}"
noi di "{hline 85}"
noi di "Threshold value c1 = " e(c1)    
noi di "Threshold value c2 = " e(c2)
noi di "{hline 85}"
noi di "Average constrained optimal impact (ATET_ccp) = " e(I_ccp)
ereturn scalar TTET_ccp = e(I_ccp) * e(Ntreat_ccp)
noi di "Total unconstrained optimal impact (TTET_ccp) = " e(TTET_ccp)
ereturn scalar AW_ccp = `pom0'+ e(I_ccp)*(e(perc_treat_ccp)/100)
noi di "Average constrained optimal welfare (AW_ccp) = " e(AW_ccp)
ereturn scalar TW_ccp = e(AW_ccp) * e(N_ccp)
noi di "Total constrained optimal welfare (TW_ccp) = " e(TW_ccp)
noi di "N. units (ccp) = " e(N_ccp)
noi di "N. of treated (ccp) = " e(Ntreat_ccp)
noi di "N. of untreated (ccp) = " e(Nuntreat_ccp)
noi di "Percentage of treated (ccp) = " e(perc_treat_ccp)
noi di "{hline 85}"
di " "
}
********************************************************************************
end
********************************************************************************
