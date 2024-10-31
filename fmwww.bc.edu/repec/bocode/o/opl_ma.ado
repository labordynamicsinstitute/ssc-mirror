*! opl_ma, v1, GCerulli, 06Jan2024
program opl_ma , eclass
version 16
syntax varlist , policy_train(varlist max=1) policy_new(varlist max=1)
marksample touse
markout `touse' `policy_train' `policy_new'
gettoken Y X : varlist
********************************************************************************
qui levelsof `policy_train' , local(num_actions)
local L: word count `num_actions'
local M=`L'-1
********************************************************************************
local VARS1 ""
forvalues j=0/`M'{
	local VARS1 `VARS1' _D`j'
}
foreach var of local VARS1{
	cap confirm var `var'
	if _rc==0{
		di in red "Variable `var' already exists. Please, provide a different name for it."
		error 1
	}
	else{ 
		di in red ""	
	}
}
********************************************************************************
local VARS2 ""
forvalues j=0/`M'{
	local VARS2 `VARS2' _pi`j'
}
foreach var of local VARS2{
	cap confirm var `var'
	if _rc==0{
		di in red "Variable `var' already exists. Please, provide a different name for it."
		error 1
	}
	else{ 
		di in red ""	
	}
}
********************************************************************************
local D `policy_train'
local pi `policy_new'
********************************************************************************
* Estimate the predictions by action: E(Y|D=j,X), j=0,1,2,...,M
forvalues j=0/`M'{
* E(Y|D=j,X)
tempvar Y_hat`j'
qui reg `Y' `X' if `D'==`j'
qui predict `Y_hat`j''
}
********************************************************************************
* Generate the D-dummies (_D0, _D1, _D2,...)
qui tab `D' , gen(_D)
local i=1
forvalues j=0/`M'{
rename _D`i' _D`j'	
local i=`i'+1
}
********************************************************************************
* Estimate the propensity scores
forvalues j=0/`M'{
* Pj = Pr(_Dj=1|X)
tempvar P`j'
qui logit _D`j' `X'
qui predict `P`j''
}
********************************************************************************
* Estimate the variable "REG_D" containing E(Y|D=j,X) for each j 
tempvar REG_D
qui  gen `REG_D'=0
forvalues j=0/`M'{
qui replace `REG_D' = `REG_D' + _D`j'*`Y_hat`j''  	
}
********************************************************************************
* Estimate of the value function
********************************************************************************
* RA (Regression Adjustment)
********************************************************************************
* Generate the pi-dummies (_pi0, _pi1, _pi2)
qui tab `pi' , gen(_pi)
local i=1
forvalues j=0/`M'{
rename _pi`i' _pi`j'	
local i=`i'+1
}
* Estimate the variable "RA" containing E(Y|D=j,X) for each j based on the pi-dummies
tempvar RA
qui gen `RA'=0
forvalues j=0/`M'{
qui replace `RA' = `RA' + _pi`j'*`Y_hat`j''  	
}
* Value function estimation RA
qui sum `RA'
di in red "Value function estimation for RA = "r(mean)
********************************************************************************
* IPW (Inverse Probability Weighting)
********************************************************************************
tempvar A
qui gen `A'=(`D'==`pi')
tempvar pD
qui gen `pD'=0
forvalues j=0/`M'{
qui replace `pD' = `pD' + _D`j'*`P`j''  	
}
tempvar W
qui count
local N=r(N)
gen `W' = `A'/(`pD'*`N')
qui sum `Y' [aweight=`W']
*qui gen `IPW' = (`A' * `Y') / `pD'
* Value function estimation IPW
tempvar IPW
gen `IPW'=r(mean)
qui sum `IPW'
di in red "Value function estimation for IPW = "r(mean)
********************************************************************************
* DR (Doubly Robust)
********************************************************************************
tempvar DR
qui gen `DR' = ((`Y'-`REG_D') * `A')/ `pD' + `RA'
* Value function estimation DR
qui sum `DR'
di in red "Value function estimation for DR = "r(mean)
********************************************************************************
ereturn clear
********************************************************************************
qui sum `RA'
ereturn scalar RA=r(mean)
qui sum `IPW'
ereturn scalar IPW=r(mean)
qui sum `DR'
ereturn scalar DR=r(mean)
********************************************************************************
end