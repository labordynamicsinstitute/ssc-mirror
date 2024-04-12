********************************************************************************
* PROGRAM "make_cate"
********************************************************************************
*! make_cate, v2, GCerulli, 14Nov2023
program make_cate , eclass
version 16
syntax varlist [if] [in] , treatment(varlist max=1) model(string) ///
train_cate(name) new_cate(name) [new_data(name)]
marksample touse
markout `touse' `treatment'
********************************************************************************
* Form y and x
********************************************************************************
tokenize "`varlist'"
local y "`1'"
macro shift 1
local xvars "`*'"
local w "`treatment'" 
********************************************************************************
if "`new_data'"==""{
********************************************************************************
	if "`model'"=="linear"{
		teffects ra (`y' `xvars', linear) (`w') if `touse'
		}
	else if "`model'"=="logit"{
		teffects ra (`y' `xvars', logit) (`w') if `touse'
		}	
	else if "`model'"=="poisson"{
		teffects ra (`y' `xvars', poisson) (`w') if `touse'
		}
	else if "`model'"=="flogit"{
		teffects ra (`y' `xvars', flogit) (`w') if `touse'
		}	
********************************************************************************	
tempvar Ey1_x Ey0_x
predict `Ey1_x' , cmean tlevel(1)
predict `Ey0_x' , cmean tlevel(0)
gen `train_cate'=(`Ey1_x' - `Ey0_x')
ereturn local cate = "`train_cate'"
}
********************************************************************************
if "`new_data'"!=""{
********************************************************************************
	if  "`model'"=="linear"{
		cap drop _train_new_index
		gen _train_new_index="train"
		append using `new_data' 
		replace _train_new_index="new" if _train_new_index==""
		teffects ra (`y' `xvars') (`w') if `touse' & _train_new_index=="train"
	}
	else if ("`model'"=="logit"){
		cap drop _train_new_index
		gen _train_new_index="train"
		append using `new_data' 
		replace _train_new_index="new" if _train_new_index==""
		teffects ra (`y' `xvars', logit) (`w') if `touse' & _train_new_index=="train"
	}	
	else if ("`model'"=="poisson"){
		cap drop _train_new_index
		gen _train_new_index="train"
		append using `new_data' 
		replace _train_new_index="new" if _train_new_index==""
		teffects ra (`y' `xvars', poisson) (`w') if `touse' & _train_new_index=="train"
	}	
	else if ("`model'"=="flogit"){
		cap drop _train_new_index
		gen _train_new_index="train"
		append using `new_data' 
		replace _train_new_index="new" if _train_new_index==""
		teffects ra (`y' `xvars', flogit) (`w') if `touse' & _train_new_index=="train"
	}	
********************************************************************************
tempvar Ey1_x1 Ey0_x1 Ey1_x2 Ey0_x2
*
predict `Ey1_x1' if _train_new_index=="train" , cmean tlevel(1)
predict `Ey0_x1' if _train_new_index=="train" , cmean tlevel(0)
gen `train_cate'=(`Ey1_x1' - `Ey0_x1') if _train_new_index=="train"
ereturn local cate_train "`train_cate'"
*
predict `Ey1_x2' if _train_new_index=="new" , cmean tlevel(1)
predict `Ey0_x2' if _train_new_index=="new" , cmean tlevel(0)
gen `new_cate'=(`Ey1_x2' - `Ey0_x2') if _train_new_index=="new"
ereturn local cate_new "`new_cate'"
}
********************************************************************************
ereturn local dep_var "`y'"
ereturn local treatment "`w'"
ereturn local xvars "`xvars'"
********************************************************************************
end