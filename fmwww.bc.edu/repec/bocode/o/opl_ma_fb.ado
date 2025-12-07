********************************************************************************
* "opl_ma_fb.ado" 
* (opl=optimal policy learning, ma=multi-action, fb=first best)
* V.12, GCerulli
* September 16, 2025
********************************************************************************
program opl_ma_fb , eclass
syntax varlist(fv ts) , policy_train(varlist max=1) /// 
                 model(string) ///
				 name_opt_policy(name) ///
				 [match_name(name) ///
				 new_data(name) ///
				 policy_non_optimal_train(varlist max=1) /// 
				 policy_non_optimal_new(string) ///
				 gr_action_train(name) ///
				 gr_reward_train(name) ///
				 gr_reward_new(name) ///
				 save_preds_vars(string) ///
				 value_var(numlist max=1)]
********************************************************************************
marksample touse
gettoken y X : varlist
********************************************************************************
set varabbrev off
********************************************************************************
qui sum `y'
local MIN=r(min)
if `MIN'<0{
		di _newline
		di in red "*************************************************************"
		di in red "WARNING: Variable '`y'' must take non-negative values.       "
		di in red "It should be  a 'welfare' measure.                           "
		di in red "*************************************************************"	
		error 1	
}
********************************************************************************
* Extract the number of policy actions "M"
********************************************************************************
qui levelsof `policy_train' , local(num_actions)
local L: word count `num_actions'
local M=`L'-1
********************************************************************************
* Check if these variables already exist in the dataset
********************************************************************************
local DDvars ""
forvalues j=0/`M'{
    local DDvars `DDvars' _DD`j'
}
********************************************************************************
local Dvars ""
forvalues j=0/`M'{
    local Dvars `Dvars' _D`j'
}
********************************************************************************
local VARS "_index _Y_hat_policy_train _Y_hat_policy_train_non_optimal _Y_hat_policy_optimal `name_opt_policy' `DDvars' `DDvars' `match_name' `_neg_var_flag'"
foreach var of local VARS{
	cap confirm var `var'
	if _rc==0{
		di _newline
		di in red "****************************************"
		di in red "WARNING: Variable `var' already exists. "
		di in red "Please, provide a different name for it."
		di in red "****************************************"	
		error 1
	}
}
********************************************************************************
* These two options cannot be invoked jointly
if "`policy_non_optimal_train'"!="" & "`policy_non_optimal_new'"!=""{
di in red _newline
di in red "*************************************************"
di in red "WARNING: Only one of 'policy_non_optimal_train()'"   
di in red "or 'policy_non_optimal_new()' can be specified.  "
di in red "*************************************************"
di in red _newline
error 1
}
********************************************************************************
* These two options cannot be invoked jointly
if "`policy_non_optimal_new'"!="" & "`new_data'"==""{
di in red _newline
di in red "********************************************"
di in red "WARNING: Options 'policy_non_optimal_new()'"   
di in red "and 'new_data()' must be specified jointly."
di in red "********************************************"
di in red _newline
error 1
}
********************************************************************************
tempvar w
qui gen `w' = `policy_train'
********************************************************************************
* Check if w contains consecutive values starting: 0,1,2,...,M
qui levelsof `w' , local(ww)
local k=0
foreach h of local ww{
	if `h'!=`k'{
		di _newline
		di in red "*****************************************************"
		di in red "WARNING: your treatment variable must be: 0,1,2,...,M"
		di in red "*****************************************************"
		error 1
	}
	local k=`k'+1
}
********************************************************************************
qui{  // Start quietly
********************************************************************************
* Decide if considering a new dataset
********************************************************************************
* Append the "new" data and generate the "_index" (=0 for training; =1 for new data)
********************************************************************************
gen _index=0  
if "`new_data'"!=""{
********************************************************************************
cap drop _index
qui append using `new_data' , gen(_index)
********************************************************************************
label define labIndex 0 "Training" 1 "New" , replace 
label values _index labIndex
}
********************************************************************************
qui count if _index==0
local NTrain = r(N)
qui count if _index==1
local NNew = r(N)
********************************************************************************
tempvar `y'_sq
qui gen ``y'_sq'=`y'^2
********************************************************************************
forvalues i=0/`M'{
	tempvar pred`i'
	qui gen `pred`i''=.
	tempvar predv`i'
	qui gen `predv`i''=.
	tempvar var`i'
	qui gen `var`i''=.
}
********************************************************************************
tempvar variance
qui gen `variance'=.
********************************************************************************
forvalues i=0/`M'{
	tempvar pred_var`i'
	qui gen `pred_var`i''=.
}
********************************************************************************
local class `name_opt_policy'
qui gen `class' =.
********************************************************************************
********************************************************************************
* CONDITIONAL VARIANCE ESTIMATION
********************************************************************************
if "`value_var'"==""{
forvalues i=0/`M'{
*E(y|x)	
qui reg `y' `X' if `w'==`i' & _index==0
tempvar _pred`i'
qui predict `_pred`i'' 
qui replace `pred`i''=`_pred`i''
qui replace `pred`i''= 0 if `pred`i''<0  // put to zero if predicted welfare is negative
* Calcolo dei residui
tempvar __res`i'
qui gen `__res`i'' = `y' - `pred`i'' if `w'==`i' & _index==0
* Calcolo dei residui al quadrato
tempvar __res2`i'
qui gen `__res2`i'' = (`__res`i'')^2
* Secondo step
qui regress `__res2`i'' `X' if `w'==`i' & _index==0
tempvar __`var`i''
qui predict `__`var`i''', xb
qui replace `var`i''=`__`var`i'''
qui replace `var`i''=. if `var`i''<0   // put to missing if conditional variance is negative
}
}
********************************************************************************
else if "`value_var'"!=""{
forvalues i=0/`M'{
*E(y|x)	
qui reg `y' `X' if `w'==`i' & _index==0
tempvar _pred`i'
qui predict `_pred`i'' 
qui replace `pred`i''=`_pred`i''
qui replace `pred`i''= 0 if `pred`i''<0  // put to zero if predicted welfare is negative
* Calcolo dei residui
tempvar __res`i'
qui gen `__res`i'' = `y' - `pred`i'' if `w'==`i' & _index==0
* Calcolo dei residui al quadrato
tempvar __res2`i'
qui gen `__res2`i'' = (`__res`i'')^2
* Secondo step
qui regress `__res2`i'' `X' if `w'==`i' & _index==0
tempvar __`var`i''
qui predict `__`var`i''', xb
qui replace `var`i''=`__`var`i'''
qui replace `var`i''=`value_var' if `var`i''<0   // put to `value_var' if conditional variance is negative
}
}
********************************************************************************
*
********************************************************************************
* Risk analysis
********************************************************************************
if "`model'"=="risk_neutral"{	
	forvalues i=0/`M'{
	   qui replace `pred_var`i'' = `pred`i''
	}		
}
********************************************************************************
else if "`model'"=="risk_averse_linear"{	
	forvalues i=0/`M'{
	   qui replace `pred_var`i'' = `pred`i''/sqrt(`var`i'')
	}		
}
********************************************************************************
else if "`model'"=="risk_averse_quadratic"{	
	forvalues i=0/`M'{
	   qui replace `pred_var`i'' = `pred`i''/`var`i''
	}
}
********************************************************************************
*
********************************************************************************
local PREDS
forvalues i=0/`M'{
	local PREDS `PREDS' `pred_var`i''
}
********************************************************************************
if "`save_preds_vars'"!=""{
* Save conditional variances: Var(y|x,w=j)  
preserve
	forvalues i=0/`M'{
	   gen __var`i' = `var`i''
	}
* Save conditional predictions: E(y|x,w=j) 
	forvalues i=0/`M'{
	   gen __pred`i' = `pred`i''
	}
* Save risk-adjusted conditional predictions:  E(y|x,w=j)/Var(y|x,w=j) 
	forvalues i=0/`M'{
	   gen __pred_risk_adj`i' = `pred_var`i''
	}	
********************************************************************************
keep _index `y' `policy_train' __var* __pred* __pred_risk_adj*
cap drop __Y_hat_obs
gen __Y_hat_obs = .
forvalues j = 0/`M' {
    replace __Y_hat_obs = __pred`j' if w == `j'
}
la var __Y_hat_obs "Expected conditional reward given treatment"
la var _index "0 = training obs; 1 = new obs" 
forvalues j = 0/`M' {
    la var __var`j' "Conditional variance for treatment `j'" 
	la var __pred`j' "Conditional reward for treatment `j'"
	la var __pred_risk_adj`j' "Risk-adjusted conditional reward for treatment `j'"
}
qui save `save_preds_vars' , replace
restore
}
********************************************************************************
* Generate the predicted Y for the "training policy" (D)
********************************************************************************
* Generate treatment dummy variables (_DD0, _DD1, ..., _DDM)
********************************************************************************
qui tab `policy_train' , gen(_DD)  // Create dummies for policy_train
local i=1
forvalues j=0/`M'{
    rename _DD`i' _DD`j'  // Ensure correct ordering of dummy variables
    local i=`i'+1
}
********************************************************************************
* Compute REG_D: E(Y | D=j, X)/VAR(Y | D=j, X) based on estimated conditional expectations
********************************************************************************
tempvar REG_DD
gen `REG_DD' = 0
forvalues i=0/`M'{
    replace `REG_DD' = `REG_DD' + _DD`i'*`pred_var`i''
}
gen _Y_hat_policy_train=`REG_DD'

********************************************************************************
* Estimate propensity scores P(D=j | X) using logistic regression
********************************************************************************
forvalues j=0/`M'{
    tempvar P`j'  // Temporary variable for propensity score
    qui logit _DD`j' `X'  // Estimate probability of receiving treatment j
    qui predict `P`j''  // Store estimated propensity scores
}

********************************************************************************
* Eliminate (_DD0, _DD1, ..., _DDM)
********************************************************************************
forvalues j=0/`M'{
    qui cap drop _DD`j'
}
********************************************************************************
* Generate the predicted Y for a generic non-optimal policy D'=`policy_non_optimal_train'
********************************************************************************
if "`policy_non_optimal_train'"!=""{
local policy_non_optimal `policy_non_optimal_train'
}
else if "`policy_non_optimal_new'"!=""{
local policy_non_optimal `policy_non_optimal_new'	
}
********************************************************************************
if "`policy_non_optimal'"!=""{
********************************************************************************
* Generate treatment dummy variables (_D0, _D1, ..., _DM)
********************************************************************************
qui tab `policy_non_optimal' , gen(_D)  // Create dummies for policy_train
local i=1
forvalues j=0/`M'{
    rename _D`i' _D`j'  // Ensure correct ordering of dummy variables
    local i=`i'+1
}
********************************************************************************
* Compute REG_D: E(Y | D=j, X)/VAR(Y | D=j, X) based on estimated conditional expectations
********************************************************************************
tempvar REG_D
gen `REG_D' = 0
forvalues i=0/`M'{
replace `REG_D' = `REG_D' + _D`i'*`pred_var`i''
}
if "`policy_non_optimal_train'"!=""{
gen _Y_hat_policy_train_non_optimal=`REG_D' if _index==0
}
else if "`policy_non_optimal_new'"!=""{
gen _Y_hat_policy_new_non_optimal=`REG_D' if _index==1
}	 
}
********************************************************************************
* Eliminate (_D0, _D1, ..., _DM)
********************************************************************************
forvalues j=0/`M'{
    qui cap drop _D`j'
}
********************************************************************************
* Compute the optimal policy (first-best)
********************************************************************************
cap drop _Y_hat_policy_optimal
qui egen _Y_hat_policy_optimal = rowmax(`PREDS')
********************************************************************************
* Count the number of words in PREDS
local n : word count `PREDS'
********************************************************************************
* Construct B as a comma-separated list of the variables
forvalues i = 1/`n' {
    local var : word `i' of `PREDS'
    if `i' == 1 {
        local B "`var'"
    }
    else {
        local B "`B', `var'"
    }
}
********************************************************************************
* Generate a variable indicating if any of the variables in B are missing
tempvar anymiss
gen `anymiss' = missing(`B') 
* Replace _Y_hat_policy_optimal with missing if anymiss is true
replace _Y_hat_policy_optimal = . if `anymiss'
********************************************************************************
qui count 
local NN=r(N)
forvalues i=0/`M'{
	forvalues j=1/`NN'{
	if `pred_var`i''[`j']==_Y_hat_policy_optimal[`j']{
		qui replace `class'=`i' in `j' 
		qui replace `variance'=`var`i'' in `j'
}
}	
}
replace `class'=. if `anymiss'
********************************************************************************
* Risk neutral
if "`model'"=="risk_neutral"{
qui replace _Y_hat_policy_optimal=_Y_hat_policy_optimal
local mod "Risk-neutral"
}
********************************************************************************
* Risk averse linear
if "`model'"=="risk_averse_linear"{
qui replace _Y_hat_policy_optimal=_Y_hat_policy_optimal * sqrt(`variance')
replace _Y_hat_policy_train =_Y_hat_policy_train * sqrt(`variance')
local mod "Risk-averse linear"
if "`policy_non_optimal_train'"!=""{
replace _Y_hat_policy_train_non_optimal=_Y_hat_policy_train_non_optimal * sqrt(`variance')
}
else if "`policy_non_optimal_new'"!=""{
replace _Y_hat_policy_new_non_optimal=_Y_hat_policy_new_non_optimal * sqrt(`variance')
}	 
}
********************************************************************************
* Risk averse quadratic
if "`model'"=="risk_averse_quadratic"{
qui replace _Y_hat_policy_optimal=_Y_hat_policy_optimal * `variance'
replace _Y_hat_policy_train =_Y_hat_policy_train * `variance'
local mod "Risk-averse quadratic"
if "`policy_non_optimal_train'"!=""{
replace _Y_hat_policy_train_non_optimal=_Y_hat_policy_train_non_optimal * `variance'
}
else if "`policy_non_optimal_new'"!=""{
replace _Y_hat_policy_new_non_optimal=_Y_hat_policy_new_non_optimal * `variance'
}	 
}
********************************************************************************
qui sum _Y_hat_policy_optimal if _index==0
local NtreatOP=r(N)
********************************************************************************
* GRAPHS 
********************************************************************************
* Graph actual vs optimal class allocation
********************************************************************************
if "`gr_action_train'"!=""{
preserve
qui keep if _index==0
********************************************************************************
qui keep if `class'!=.
tempvar ID
qui gen `ID' =_n 
********************************************************************************
qui tw (connected `w' `ID' if `class'!=.  , lc(green) lp(dash) mcolor(green)) ///
(connected `class' `ID' if `class'!=. , lc(orange) mcolor(orange)) , ///
legend(order(1 "Actual action" 2 "Optimal action") pos(6) col(2)) ///
note("Model: `mod'") xtitle("Observation / Round") ytitle("Action") ///
title("Actual vs. optimal action allocation") ///
ylabel(0(1)`M') ///
subtitle("(Training dataset)") saving("`gr_action_train'", replace) ///
name("`gr_action_train'", replace)
restore
}
********************************************************************************
* Percentage of "optimal choices"
********************************************************************************
if "`match_name'" != ""{
gen `match_name'=(`w'==`class') if _index==0
replace `match_name'=. if `class'==.
qui sum `match_name' if _index==0 // training data
local mm = r(mean)
}
********************************************************************************
*
********************************************************************************
* Collect all "ereturn" objects
********************************************************************************
ereturn clear
ereturn scalar N_train = `NTrain'
ereturn scalar N_new = `NNew'
ereturn scalar N_train_opt_pol = `NtreatOP'

qui sum _Y_hat_policy_train
ereturn scalar V_train=r(mean)
ereturn scalar N_V_train=r(N)

if "`policy_non_optimal_train'"!=""{
qui sum _Y_hat_policy_train_non_optimal 
ereturn scalar V_non_opt_train = r(mean)
ereturn scalar N_V_non_opt_train = r(N)
}
else if "`policy_non_optimal_new'"!=""{
qui sum _Y_hat_policy_new_non_optimal 
ereturn scalar V_non_opt_new = r(mean)
ereturn scalar N_V_non_opt_new = r(N)
}	 
qui sum _Y_hat_policy_optimal if _index==0  // only training data
ereturn scalar V_opt_train = r(mean)
ereturn scalar N_V_opt_train = r(N)
qui sum _Y_hat_policy_optimal if _index==1  // only new data
ereturn scalar V_opt_new = r(mean)
ereturn scalar N_V_opt_new = r(N)
if "`match_name'" != ""{
ereturn scalar rate_opt_match = `mm'
}
} // End quietly
********************************************************************************
* Generate a Table of results
********************************************************************************
di " "
di "{hline 55}"
noi di in gr "{bf:MAIN RESULTS}"
di "{hline 55}"
di in gr "{bf:--> Risk preference}"
di "Type: `mod'"
di "{hline 55}"
di in gr "{bf:--> Data information}"
di "{hline 55}"
di "Number of training observations = " e(N_train)
di "Number of used training observations (optimal policy) = " e(N_train_opt_pol)
di "Number of used training observations (non-optimal policy) = " e(N_V_non_opt_train)
di "Number of new observations = " e(N_new)
di "Number of used new observations (optimal policy) = " e(N_V_opt_new)
di "Number of used new observations (non-optimal policy) = " e(N_V_non_opt_new)

di "{hline 55}"
di in gr "{bf:--> Policy information}"
di "{hline 55}"
di "Target variable: `y'" 
di "Features: `X'"
di "Policy variable: `policy_train'"
di "Number of actions: `L'"
di "Actions: {`num_actions'}"

di "{hline 55}"
di "Frequencies of the actions in the training dataset"
di "{hline 55}"
tab `policy_train' if _index==0 , mis
di "{hline 55}"

di "{hline 55}"
di in gr "{bf:--> Training data}"
di "{hline 55}"
di "Value-function of the policy (training) = " round(e(V_train), 0.01)
di "Value-function of the non-optimal policy (training) = " round(e(V_non_opt_train), 0.01)
di "Value-function of the optimal policy (training) = " round(e(V_opt_train), 0.01)
di "Rate of optimal policy matches = " round(e(rate_opt_match), 0.01)
di "{hline 55}"
di in gr "{bf:--> New data}"
di "{hline 55}"
di "Value-function of the non-optimal policy (new) = " round(e(V_non_opt_new), 0.01)
di "Value-function of the optimal policy (new) = " round(e(V_opt_new), 0.01)
di "{hline 55}"
********************************************************************************
* Graph actual vs maximal outcome
********************************************************************************
if "`gr_reward_train'"!=""{
preserve
qui keep if _index==0
qui sum _Y_hat_policy_optimal
local A=round(r(mean),0.01)
qui sum _Y_hat_policy_train
local B=round(r(mean),0.01)
local C=round(`A'-`B',0.01)
local D=round(`C'/`A',0.01)*100
********************************************************************************
qui keep if `class'!=.
tempvar ID
qui gen `ID' =_n 
********************************************************************************
qui tw (connected _Y_hat_policy_optimal `ID' , lc(green) lp(dash) mcolor(green) mlabel(`class')) ///
(connected _Y_hat_policy_train `ID', lc(orange) mcolor(orange)) , ///
yline(`A',lp(dash)) xtitle("Observation / Round") ///
legend(order(1 "Max expected reward" 2 "Actual expected reward") pos(6) col(2)) ///
title(Actual vs. maximal expected reward) ytitle("Reward") ///
note("Model: `mod'" "Maximal value-function: `A'" "Actual value-function: `B'" "Estimated regret: `C'" "Welfare loss (%): `D'") ///
subtitle("(Training dataset)") saving("`gr_reward_train'", replace) ///
name("`gr_reward_train'", replace)
restore
}
* Graph maximal reward new data
if "`gr_reward_new'"!="" & "`new_data'"!=""{
preserve
********************************************************************************
qui keep if `class'!=.
tempvar ID
qui gen `ID' =_n
qui keep if _index==1
qui sum _Y_hat_policy_optimal
local A=round(r(mean),0.01)
********************************************************************************
qui tw (connected _Y_hat_policy_optimal `ID' , lc(green) lp(dash) mcolor(green) mlabel(`class') ) , ///
yline(`A',lp(dash)) xtitle("Observation / Round") ///
legend(order(1 "Max expected reward") pos(6) col(2)) ///
title(Maximal expected reward) ytitle("Maximal expected reward") ///
note("Model: `mod'" "Average max reward: `A'") ///
subtitle("(New dataset)") saving("`gr_reward_new'", replace) ///
name("`gr_reward_new'",replace)
restore
}
********************************************************************************
* Put label to variables
cap label variable _index                   "Indicator variable: 0=training obs; 1=new obs"
cap label variable _opt_policy              "Optimal policy: treatment maximizing welfare"
cap label variable _Y_hat_policy_train      "Predicted outcome under observed training policy"
cap label variable _Y_hat_policy_train_non_optimal "Predicted outcome under given non-optimal policy"
cap label variable _Y_hat_policy_optimal    "Predicted outcome under estimated optimal policy"
cap label variable _match_var               "Match flag: 1 if actual treatment=optimal treatment; 0 otherwise"
********************************************************************************
* END
********************************************************************************
end
********************************************************************************
