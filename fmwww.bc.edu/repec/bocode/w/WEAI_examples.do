*Section 4: Empirical Examples
*This do file demonstrates all commands used in section 4 of "Calculating the Women's Empowerment in Agriculture Index (WEAI) using Stata. " 

clear all
capture clear matrix
set more off

*Use example data 

log using "WEAI_examples.smcl", replace

use "WEAI_examples.dta", clear

list sex autonomy_inc selfeff never_violence feelinputdecagr assetownership in 1/5


*4.1 Pro-WEAI with details option

weai d1(autonomy_inc selfeff never_violence) d2(feelinputdecagr assetownership credit_accdec incomecontrol work_balance mobility) d3(groupmember), sex(sex) female(2) hhid(hhid) details

format hhid %20.0g
sort hhid sex
list hhid sex emp_score empowered hh_ineq gender_parity in 1/6, separator(6)

*4.2 Pro-WEAI with 8 indicators and graph option

weai d1(autonomy_inc never_violence) d2(feelinputdecagr assetownership credit_accdec incomecontrol work_balance) d3(groupmember), cutoff(0.75) sex(sex) female(2) hhid(hhid) graph


*4.3 Pro-WEAI, disaggregated by group

egen project = group(group)
label var project "Project"
tab project

weai d1(autonomy_inc selfeff never_violence) d2(feelinputdecagr assetownership credit_accdec incomecontrol work_balance mobility) d3(groupmember), sex(sex) female(2) hhid(hhid) by(project)

*4.4 A-WEAI 

weai d1(feelinputdecagr) d2(assetownership credit_accdec) d3(incomecontrol) d4(work_balance) d5(groupmember) w1(0.2) w2(0.13333 0.06667) w3(0.2) w4(0.2) w5(0.2), sex(sex) female(2) hhid(hhid)

log close 


