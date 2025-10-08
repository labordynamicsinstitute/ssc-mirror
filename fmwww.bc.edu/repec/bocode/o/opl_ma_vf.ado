********************************************************************************
*! opl_ma_vf, v1, GCerulli, 11Aug2025
*! Optimal policy learning with multi-actions estimating the value function
*! using: IPW, RA, DR
********************************************************************************
program opl_ma_vf , eclass
version 16

* Define the syntax: varlist includes dependent and independent variables
* policy_train: variable indicating the treatment policy used in training
* policy_new: variable indicating the new policy to be evaluated
syntax varlist(fv ts) , policy_train(varlist max=1) policy_new(varlist max=1)

* Mark observations that satisfy the specified conditions
marksample touse
markout `touse' `policy_train' `policy_new'

* Extract dependent variable (Y) and independent variables (X)
gettoken Y X : varlist

* Count the N. of observations
qui count if `touse'
local NN=r(N)

********************************************************************************
* Determine the number of unique actions in the policy_train variable
********************************************************************************
qui levelsof `policy_train' , local(num_actions)
local L: word count `num_actions'
local M=`L'-1  // Number of unique actions minus one

********************************************************************************
* Check for existence of dummy variables (_D0, _D1, ..., _DM)
* If they exist, prompt an error to avoid overwriting
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
}

********************************************************************************
* Check for existence of probability variables (_pi0, _pi1, ..., _piM)
* If they exist, prompt an error
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
}

********************************************************************************
* Assign treatment and policy variables
********************************************************************************
local D `policy_train'
local pi `policy_new'

********************************************************************************
* Estimate E(Y | D=j, X) for each treatment action j
********************************************************************************
forvalues j=0/`M'{
    tempvar Y_hat`j'  // Temporary variable for predictions
    qui reg `Y' `X' if `D'==`j'  // Estimate conditional expectation
    qui predict `Y_hat`j''  // Save predicted values
}

********************************************************************************
* Generate treatment dummy variables (_D0, _D1, ..., _DM)
********************************************************************************
qui tab `D' , gen(_D)  // Create dummies for policy_train
local i=1
forvalues j=0/`M'{
    rename _D`i' _D`j'  // Ensure correct ordering of dummy variables
    local i=`i'+1
}

********************************************************************************
* Estimate propensity scores P(D=j | X) using logistic regression
********************************************************************************
forvalues j=0/`M'{
    tempvar P`j'  // Temporary variable for propensity score
    qui logit _D`j' `X'  // Estimate probability of receiving treatment j
    qui predict `P`j''  // Store estimated propensity scores
}

********************************************************************************
* Compute REG_D: E(Y | D=j, X) based on estimated conditional expectations
********************************************************************************
tempvar REG_D
qui gen `REG_D' = 0
forvalues j=0/`M'{
    qui replace `REG_D' = `REG_D' + _D`j'*`Y_hat`j''  
}

********************************************************************************
* Compute the value function using different estimation methods
********************************************************************************

********************************************************************************
* RA (Regression Adjustment) Method
********************************************************************************
* Generate new policy dummies (_pi0, _pi1, ..., _piM)
qui tab `pi' , gen(_pi)  
local i=1
forvalues j=0/`M'{
    rename _pi`i' _pi`j'  
    local i=`i'+1
}

* Compute RA estimator: expected outcome under new policy
tempvar RA
qui gen `RA' = 0
forvalues j=0/`M'{
    qui replace `RA' = `RA' + _pi`j'*`Y_hat`j''  
}

********************************************************************************
* IPW (Inverse Probability Weighting) Method
********************************************************************************
tempvar A
qui gen `A' = (`D' == `pi')  // Indicator for when D matches new policy

tempvar pD
qui gen `pD' = 0
forvalues j=0/`M'{
    qui replace `pD' = `pD' + _D`j'*`P`j''  
}

tempvar W
qui count
local N = r(N)  // Total number of observations
gen `W' = `A' / (`pD' * `N')  // Compute weights for IPW estimator
qui sum `Y' [aweight=`W']  // Compute weighted mean outcome

* Store and display value function estimate for IPW
tempvar IPW
gen `IPW' = r(mean)
********************************************************************************
* DR (Doubly Robust) Method
********************************************************************************
tempvar DR
qui gen `DR' = ((`Y' - `REG_D') * `A') / `pD' + `RA'  // DR estimator
********************************************************************************
* Eliminate (_D0, _D1, ..., _DM) and (_pi0, _pi1, ..., _piM)
********************************************************************************
forvalues j=0/`M'{
    qui cap drop _D`j'
	qui cap drop _pi`j'
}
********************************************************************************
* Store results in e-class
********************************************************************************
ereturn clear
ereturn scalar N_obs = `NN'
qui sum `RA'
ereturn scalar RA = r(mean)
qui sum `IPW'
ereturn scalar IPW = r(mean)
qui sum `DR'
ereturn scalar DR = r(mean)

********************************************************************************
* Generate a Table of results
********************************************************************************
di " "
di "{hline 55}"
noi di in gr "{bf:MAIN RESULTS}"

di "{hline 55}"
di in gr "{bf:--> Data information}"
di "{hline 55}"
di "Number of training observations = " e(N_obs)

di "{hline 55}"
di in gr "{bf:--> Policy information}"
di "{hline 55}"
di "Target variable: `Y'" 
di "Features: `X'"
di "Policy variable: `policy_train'"
di "Number of actions: `L'"
di "Actions: {`num_actions'}"

di "{hline 55}"
di "Frequencies of the actions in the training dataset"
di "{hline 55}"
tab `policy_train' , mis
di "{hline 55}"
di in gr "{bf:--> Value-function estimation}"
di "{hline 55}"
di "RA = " round(e(RA), 0.01)
di "IPW = " round(e(IPW), 0.01)
di "DR = " round(e(DR), 0.01)
di "{hline 55}"
di "Legend"
di "{hline 55}"
di "RA = Regression Adjustment"
di "IPW = Inverse Probability Weighting"
di "IPW = Doubly Robust"
di "{hline 55}"
********************************************************************************
end
********************************************************************************
