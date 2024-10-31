********************************************************************************
* "opl_ma_fb.ado" 
* (opl=optimal policy learning, ma=multi-action, fb=first best)
* V1, GCerulli
* Juanary 8, 2024
********************************************************************************
program opl_ma_fb , eclass
syntax varlist , policy_train(varlist max=1) ///
                 model(string) ///
				 name_opt_policy(name) ///
				 new_data(name) ///
				 [gr_action_train(name) ///
				 gr_reward_train(name) ///
				 gr_reward_new(name)]
********************************************************************************
marksample touse
gettoken y X : varlist
********************************************************************************
* Check if these variables already exist in the dataset
local VARS "_index _match _max_reward `name_opt_policy'"
foreach var of local VARS{
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
tempvar w
qui gen `w' = `policy_train'
********************************************************************************
qui levelsof `policy_train' , local(num_actions)
local L: word count `num_actions'
local M=`L'-1
********************************************************************************
* Append the "new" data and generate the "_index" (=0 for training; =1 for new data)
********************************************************************************
qui append using `new_data' , gen(_index)
label define labIndex 0 "Training" 1 "New" , replace 
label values _index labIndex
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
forvalues i=0/`M'{
	*E(y|x)	
	qui reg `y' `X' if `w'==`i' & _index==0
	tempvar _pred`i'
	qui predict `_pred`i'' 
	qui replace `pred`i''=`_pred`i'' 
	* {E(y2|x)}
	qui reg ``y'_sq' `X' if `w'==`i' & _index==0
	tempvar _predv`i'
	qui predict `_predv`i'' 
	qui replace `predv`i''=`_predv`i'' 
	* Var(y|x)
	qui replace `var`i''=`predv`i''-(`pred`i'')^2 
}	
********************************************************************************
cap drop _max_reward
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
local PREDS
forvalues i=0/`M'{
	local PREDS `PREDS' `pred_var`i''
}
********************************************************************************
qui egen _max_reward = rowmax(`PREDS')
********************************************************************************
qui count 
local NN=r(N)
forvalues i=0/`M'{
	forvalues j=1/`NN'{
	if `pred_var`i''[`j']==_max_reward[`j']{
		qui replace `class'=`i' in `j' 
		qui replace `variance'=`var`i'' in `j'
}
}	
}
********************************************************************************
if "`model'"=="risk_neutral"{
qui replace _max_reward=_max_reward
global mod "Risk neutral"
}
else if "`model'"=="risk_averse_linear"{
qui replace _max_reward=_max_reward * sqrt(`variance')
global mod "Risk averse linear"
}
else if "`model'"=="risk_averse_quadratic"{
qui replace _max_reward=_max_reward * `variance'
global mod "Risk averse quadratic"
}
********************************************************************************
* GRAPHS 
********************************************************************************
tempvar ID
qui gen `ID' =_n
********************************************************************************
* Graph actual vs optimal class allocation
if "`gr_action_train'"!=""{
preserve
qui keep if _index==0
qui tw (connected `w' `ID' if `class'!=.  , lc(green) lp(dash) mcolor(green)) ///
(connected `class' `ID' if `class'!=. , lc(orange) mcolor(orange)) , ///
legend(order(1 "Actual action" 2 "Optimal action") pos(6) col(2)) ///
note("Model: $mod") xtitle("Observation / Round") ytitle("Action") ///
title("Actual vs. optimal action allocation") ///
ylabel(0(1)`M') ///
subtitle("(Training dataset)") saving("`gr_action_train'", replace) ///
name("`gr_action_train'", replace)
restore
}
********************************************************************************
* Percentage of "optimal choices"
qui gen _match=(`w'==`class')
********************************************************************************
* Graph actual vs maximal reward
if "`gr_reward_train'"!=""{
preserve
qui keep if _index==0
qui sum _max_reward
local A=round(r(mean),0.01)
qui tw (connected _max_reward `ID' , lc(green) lp(dash) mcolor(green) mlabel(`class')) ///
(connected `y' `ID', lc(orange) mcolor(orange)) , ///
yline(`A',lp(dash)) xtitle("Observation / Round") ///
legend(order(1 "Max expected reward" 2 "Actual reward") pos(6) col(2)) ///
title(Actual vs. maximal expected reward) ytitle("Reward") ///
note("Model: $mod" "Average max reward: `A'") ///
subtitle("(Training dataset)") saving("`gr_reward_train'", replace) ///
name("`gr_reward_train'", replace)
restore
}
* Graph maximal reward new data
if "`gr_reward_new'"!=""{
preserve
qui keep if _index==1
qui sum _max_reward
local A=round(r(mean),0.01)
qui tw (connected _max_reward `ID' , lc(green) lp(dash) mcolor(green) mlabel(`class') ) , ///
yline(`A',lp(dash)) xtitle("Observation / Round") ///
legend(order(1 "Max expected reward") pos(6) col(2)) ///
title(Maximal expected reward) ytitle("Maximal reward") ///
note("Model: $mod" "Average max reward: `A'") ///
subtitle("(New dataset)") saving("`gr_reward_new'", replace) ///
name("`gr_reward_new'",replace)
restore
}
********************************************************************************
* END
********************************************************************************
end
********************************************************************************
