********************************************************************************
*! "r_ml_stata_cv"
*! Author: Giovanni Cerulli
*! Version: 8
*! Date: 11 May 2022 
********************************************************************************

********************************************************************************
* The program 'numlist_to_matrix' put a Stata "numlist" into a Stata "matrix" 
* with one row. We use this program to give Python parameters' grids  
********************************************************************************
cap prog drop numlist_to_matrix
program numlist_to_matrix , rclass
syntax , num_list(numlist min=1)
local nel : word count `num_list'
tempname A
matrix `A' = J(1,`nel',0)
forvalues i=1/`nel'{
		local el : word `i' of `num_list'
		mat `A'[1,`i']=`el'
}
return matrix M = `A'
end
********************************************************************************

*

********************************************************************************
* Display output for "r_ols"
********************************************************************************
cap program drop display_output_r_ols
program display_output_r_ols
syntax , [prediction] 

noi di "{hline 80}"
noi di in gr "{bf:Learner: Least Squares regression}"
di " "

noi di in gr "{ul:Dataset information}"
di " "
noi di "Target variable = " `""`e(dep_var)'""'    _continue
noi di _col(45) "Number of features  = " e(N_features)
noi di "N. of training units = " e(N_train_all) _continue
noi di _col(45) "N. of testing units = " e(N_test_all)
noi di "N. of used training units = " e(N_train_used) _continue
noi di _col(45) "N. of used testing units = " e(N_test_used)
noi di "{hline 80}"
di " "

noi di "{ul:Cross-validation results}"
di " "
noi di "Accuracy measure = explained variance" _continue
noi di _col(45) "Number of folds = " e(N_FOLDS)
noi di "Training accuracy = " e(TRAIN_ACCURACY) _continue
noi di _col(45) "Testing accuracy = " e(TEST_ACCURACY)
noi di "Std. err. test accuracy = " e(SE_TEST_ACCURACY)
noi di "{hline 80}"

if "`prediction'"!=""{
di " "
noi di in gr "{ul:Validation results}"
di " "
noi di "MSE = mean squared error" _continue
noi di _col(45) "MAPE = mean absolute percentage error"
noi di "Training MSE = " e(Train_mse) _continue
noi di _col(45) "Testing MSE = " e(Test_mse)
noi di "Training MAPE % = " e(Train_mape) _continue
noi di _col(45) "Testing MAPE % = " e(Test_mape)
noi di " "
noi di "{hline 80}"
}
end 
********************************************************************************

********************************************************************************
* Display output for "r_tree"
********************************************************************************
cap program drop display_output_r_tree
program display_output_r_tree
syntax , [prediction] 

noi di "{hline 80}"
noi di in gr "{bf:Learner: Tree regression}"
di " "

noi di in gr "{ul:Dataset information}"
di " "
noi di "Target variable = " `""`e(dep_var)'""'    _continue
noi di _col(45) "Number of features  = " e(N_features)
noi di "N. of training units = " e(N_train_all) _continue
noi di _col(45) "N. of testing units = " e(N_test_all)
noi di "N. of used training units = " e(N_train_used) _continue
noi di _col(45) "N. of used testing units = " e(N_test_used)
noi di "{hline 80}"
di " "

noi di "{ul:Cross-validation results}"
di " "
noi di "Accuracy measure = explained variance" _continue
noi di _col(45) "Number of folds = " e(N_FOLDS)
noi di "Best grid index = " e(BEST_INDEX) _continue
noi di _col(45) "Optimal tree depth = " e(OPT_DEPTH)
noi di "Training accuracy = " e(TRAIN_ACCURACY) _continue
noi di _col(45) "Testing accuracy = " e(TEST_ACCURACY)
noi di "Std. err. test accuracy = " e(SE_TEST_ACCURACY)
noi di "{hline 80}"

if "`prediction'"!=""{
di " "
noi di in gr "{ul:Validation results}"
di " "
noi di "MSE = mean squared error" _continue
noi di _col(45) "MAPE = mean absolute percentage error"
noi di "Training MSE = " e(Train_mse) _continue
noi di _col(45) "Testing MSE = " e(Test_mse)
noi di "Training MAPE % = " e(Train_mape) _continue
noi di _col(45) "Testing MAPE % = " e(Test_mape)
noi di " "
noi di "{hline 80}"
}
end 
********************************************************************************
*
********************************************************************************
* Display output for "r_elasticnet"
********************************************************************************
cap program drop display_output_r_elasticnet
program display_output_r_elasticnet
syntax , [prediction] 

noi di "{hline 80}"
noi di in gr "{bf:Learner: Elastic Net regression}"
di " "

noi di in gr "{ul:Dataset information}"
di " "
noi di "Target variable = " `""`e(dep_var)'""'    _continue
noi di _col(45) "Number of features  = " e(N_features)
noi di "N. of training units = " e(N_train_all) _continue
noi di _col(45) "N. of testing units = " e(N_test_all)
noi di "N. of used training units = " e(N_train_used) _continue
noi di _col(45) "N. of used testing units = " e(N_test_used)
noi di "{hline 80}"
di " "

noi di "{ul:Cross-validation results}"
di " "
noi di "Accuracy measure = explained variance" _continue
noi di _col(45) "Number of folds = " e(N_FOLDS)
noi di "Best grid index = " e(BEST_INDEX) _continue
noi di _col(45) "Optimal penalization parameter = " e(OPT_ALPHA)
noi di "Optimal elastic parameter = " e(OPT_L1_RATIO) _continue
noi di _col(45) "Training accuracy = " e(TRAIN_ACCURACY)
noi di "Testing accuracy = " e(TEST_ACCURACY) _continue
noi di _col(45) "Std. err. test accuracy = " e(SE_TEST_ACCURACY)
noi di "{hline 80}"

if "`prediction'"!=""{
di " "
noi di in gr "{ul:Validation results}"
di " "
noi di "MSE = mean squared error" _continue
noi di _col(45) "MAPE = mean absolute percentage error"
noi di "Training MSE = " e(Train_mse) _continue
noi di _col(45) "Testing MSE = " e(Test_mse)
noi di "Training MAPE % = " e(Train_mape) _continue
noi di _col(45) "Testing MAPE % = " e(Test_mape)
noi di " "
noi di "{hline 80}"
}
end 
********************************************************************************
*
********************************************************************************
* Display output for "r_svm"
********************************************************************************
cap program drop display_output_r_svm
program display_output_r_svm
syntax , [prediction] 

noi di "{hline 80}"
noi di in gr "{bf:Learner: Support Vector Machine regression}"
di " "

noi di in gr "{ul:Dataset information}"
di " "
noi di "Target variable = " `""`e(dep_var)'""'    _continue
noi di _col(45) "Number of features  = " e(N_features)
noi di "N. of training units = " e(N_train_all) _continue
noi di _col(45) "N. of testing units = " e(N_test_all)
noi di "N. of used training units = " e(N_train_used) _continue
noi di _col(45) "N. of used testing units = " e(N_test_used)
noi di "{hline 80}"
di " "

noi di "{ul:Cross-validation results}"
di " "
noi di "Accuracy measure = explained variance" _continue
noi di _col(45) "Number of folds = " e(N_FOLDS)
noi di "Best grid index = " e(BEST_INDEX) _continue
noi di _col(45) "Optimal C parameter = " e(OPT_C)
noi di "Optimal GAMMA parameter = " e(OPT_GAMMA) _continue
noi di _col(45) "Training accuracy = " e(TRAIN_ACCURACY)
noi di "Testing accuracy = " e(TEST_ACCURACY) _continue
noi di _col(45) "Std. err. test accuracy = " e(SE_TEST_ACCURACY)
noi di "{hline 80}"

if "`prediction'"!=""{
di " "
noi di in gr "{ul:Validation results}"
di " "
noi di "MSE = mean squared error" _continue
noi di _col(45) "MAPE = mean absolute percentage error"
noi di "Training MSE = " e(Train_mse) _continue
noi di _col(45) "Testing MSE = " e(Test_mse)
noi di "Training MAPE % = " e(Train_mape) _continue
noi di _col(45) "Testing MAPE % = " e(Test_mape)
noi di " "
noi di "{hline 80}"
}
end 
********************************************************************************
*
********************************************************************************
* Display output for "r_randomforest"
********************************************************************************
cap program drop display_output_r_randomforest
program display_output_r_randomforest
syntax , [prediction] 

noi di "{hline 80}"
noi di in gr "{bf:Learner: Random Forest regression}"
di " "

noi di in gr "{ul:Dataset information}"
di " "
noi di "Target variable = " `""`e(dep_var)'""'    _continue
noi di _col(45) "Number of features  = " e(N_features)
noi di "N. of training units = " e(N_train_all) _continue
noi di _col(45) "N. of testing units = " e(N_test_all)
noi di "N. of used training units = " e(N_train_used) _continue
noi di _col(45) "N. of used testing units = " e(N_test_used)
noi di "{hline 80}"
di " "

noi di "{ul:Cross-validation results}"
di " "
noi di "Accuracy measure = rate correct matches" _continue
noi di _col(45) "Number of folds = " e(N_FOLDS)
noi di "Best grid index = " e(BEST_INDEX) _continue
noi di _col(45) "Optimal tree depth = " e(OPT_MAX_DEPTH)
noi di "Optimal n. of splitting features = " e(OPT_MAX_FEATURES) _continue
noi di _col(45) "Optimal n. of trees = " e(OPT_N_ESTIMATORS) 
noi di "Training accuracy = " e(TRAIN_ACCURACY) _continue
noi di _col(45) "Testing accuracy = " e(TEST_ACCURACY)
noi di "Std. err. test accuracy = " e(SE_TEST_ACCURACY)
noi di "{hline 80}"

if "`prediction'"!=""{
di " "
noi di in gr "{ul:Validation results}"
di " "
noi di "MSE = mean squared error" _continue
noi di _col(45) "MAPE = mean absolute percentage error"
noi di "Training MSE = " e(Train_mse) _continue
noi di _col(45) "Testing MSE = " e(Test_mse)
noi di "Training MAPE % = " e(Train_mape) _continue
noi di _col(45) "Testing MAPE % = " e(Test_mape)
noi di " "
noi di "{hline 80}"
}
end 
********************************************************************************
*
********************************************************************************
* Display output for "r_neuralnet"
********************************************************************************
cap program drop display_output_r_neuralnet
program display_output_r_neuralnet
syntax , [prediction] 

noi di "{hline 80}"
noi di in gr "{bf:Learner: Neaural Network regression}"
di " "

noi di in gr "{ul:Dataset information}"
di " "
noi di "Target variable = " `""`e(dep_var)'""'    _continue
noi di _col(45) "Number of features  = " e(N_features)
noi di "N. of training units = " e(N_train_all) _continue
noi di _col(45) "N. of testing units = " e(N_test_all)
noi di "N. of used training units = " e(N_train_used) _continue
noi di _col(45) "N. of used testing units = " e(N_test_used)
noi di "{hline 80}"
di " "

noi di "{ul:Cross-validation results}"
di " "
noi di "Accuracy measure = explained variance" _continue
noi di _col(45) "Number of folds = " e(N_FOLDS)
noi di "Best grid index = " e(BEST_INDEX) _continue
noi di _col(45) "Optimal n. of neurons in layer 1 = " e(OPT_NEURONS_L_1)
noi di "Optimal n. of neurons in layer 2 = " e(OPT_NEURONS_L_2) _continue
noi di _col(45) "Optimal L2 penalization = " e(OPT_ALPHA) 
noi di "Training accuracy = " e(TRAIN_ACCURACY) _continue
noi di _col(45) "Testing accuracy = " e(TEST_ACCURACY) 
noi di "Std. err. test accuracy = " e(SE_TEST_ACCURACY)
noi di "{hline 80}"

if "`prediction'"!=""{
di " "
noi di in gr "{ul:Validation results}"
di " "
noi di "MSE = mean squared error" _continue
noi di _col(45) "MAPE = mean absolute percentage error"
noi di "Training MSE = " e(Train_mse) _continue
noi di _col(45) "Testing MSE = " e(Test_mse)
noi di "Training MAPE % = " e(Train_mape) _continue
noi di _col(45) "Testing MAPE % = " e(Test_mape)
noi di " "
noi di "{hline 80}"
}
end 
********************************************************************************
*
********************************************************************************
* Display output for "r_nearestneighbor"
********************************************************************************
cap program drop display_output_r_nearestneighbor
program display_output_r_nearestneighbor
syntax , [prediction] 

noi di "{hline 80}"
noi di in gr "{bf:Learner: Nearest Neighbor regression}"
di " "

noi di in gr "{ul:Dataset information}"
di " "
noi di "Target variable = " `""`e(dep_var)'""'    _continue
noi di _col(45) "Number of features  = " e(N_features)
noi di "N. of training units = " e(N_train_all) _continue
noi di _col(45) "N. of testing units = " e(N_test_all)
noi di "N. of used training units = " e(N_train_used) _continue
noi di _col(45) "N. of used testing units = " e(N_test_used)
noi di "{hline 80}"
di " "

noi di "{ul:Cross-validation results}"
di " "
noi di "Accuracy measure = explained variance" _continue
noi di _col(45) "Number of folds = " e(N_FOLDS)
noi di "Best grid index = " e(BEST_INDEX) _continue
noi di _col(45) "Optimal n. of nearest neighbors = " e(OPT_NN)
noi di "Optimal kernel function = " "`e(OPT_WEIGHT)'" _continue
noi di _col(45) "Training accuracy = " e(TRAIN_ACCURACY)
noi di "Testing accuracy = " e(TEST_ACCURACY) _continue
noi di _col(45) "Std. err. test accuracy = " e(SE_TEST_ACCURACY)
noi di "{hline 80}"

if "`prediction'"!=""{
di " "
noi di in gr "{ul:Validation results}"
di " "
noi di "MSE = mean squared error" _continue
noi di _col(45) "MAPE = mean absolute percentage error"
noi di "Training MSE = " e(Train_mse) _continue
noi di _col(45) "Testing MSE = " e(Test_mse)
noi di "Training MAPE % = " e(Train_mape) _continue
noi di _col(45) "Testing MAPE % = " e(Test_mape)
noi di " "
noi di "{hline 80}"
}
end 
********************************************************************************
*
********************************************************************************
* Display output for "r_boost"
********************************************************************************
cap program drop display_output_r_boost
program display_output_r_boost
syntax , [prediction] 

noi di "{hline 80}"
noi di in gr "{bf:Learner: Boosting regression}"
di " "

noi di in gr "{ul:Dataset information}"
di " "
noi di "Target variable = " `""`e(dep_var)'""'    _continue
noi di _col(45) "Number of features  = " e(N_features)
noi di "N. of training units = " e(N_train_all) _continue
noi di _col(45) "N. of testing units = " e(N_test_all)
noi di "N. of used training units = " e(N_train_used) _continue
noi di _col(45) "N. of used testing units = " e(N_test_used)
noi di "{hline 80}"
di " "

noi di "{ul:Cross-validation results}"
di " "
noi di "Accuracy measure = explained variance" _continue
noi di _col(45) "Number of folds = " e(N_FOLDS)
noi di "Best grid index = " e(BEST_INDEX) _continue
noi di _col(45) "Optimal learning rate = " e(OPT_LEARNING_RATE)
noi di "Optimal n. of trees = " e(OPT_N_ESTIMATORS) _continue
noi di _col(45) "Optimal tree depth = " e(OPT_MAX_DEPTH)
noi di "Training accuracy = " e(TRAIN_ACCURACY) _continue
noi di _col(45) "Testing accuracy = " e(TEST_ACCURACY) 
noi di "Std. err. test accuracy = " e(SE_TEST_ACCURACY)
noi di "{hline 80}"

if "`prediction'"!=""{
di " "
noi di in gr "{ul:Validation results}"
di " "
noi di "MSE = mean squared error" _continue
noi di _col(45) "MAPE = mean absolute percentage error"
noi di "Training MSE = " e(Train_mse) _continue
noi di _col(45) "Testing MSE = " e(Test_mse)
noi di "Training MAPE % = " e(Train_mape) _continue
noi di _col(45) "Testing MAPE % = " e(Test_mape)
noi di " "
noi di "{hline 80}"
}
end 
********************************************************************************

*
*
*

********************************************************************************
*! "r_ml_stata_cv"
********************************************************************************
program r_ml_stata_cv , eclass
version 16
syntax varlist(numeric) [if] [in] , ///
mlmodel(string) ///
data_test(name)  ///
seed(numlist max=1 integer) ///
[cross_validation(name)  ///
n_folds(numlist max=1 integer >=2) ///
graph_cv save_graph_cv(name) ///
prediction(name) ///
tree_depth(numlist min=1 integer) ///
n_estimators(numlist min=1 integer) ///
learning_rate(numlist min=1) ///
max_features(numlist min=1 integer) ///
c(numlist min=1) ///
gamma(numlist min=1) ///
alpha(numlist min=1) ///
l1_ratio(numlist min=1) ///
nn(numlist min=1 integer) ///
n_neurons_l1(numlist min=1 integer) ///
n_neurons_l2(numlist min=1 integer) ///
default ///
]
********************************************************************************
if "`mlmodel'"!="ols" & "`mlmodel'"!="elasticnet" & "`mlmodel'"!="tree" & "`mlmodel'"!="randomforest" & "`mlmodel'"!="boost" & "`mlmodel'"!="nearestneighbor" & "`mlmodel'"!="neuralnet" & "`mlmodel'"!="svm" {
	di _newline
	di in red "************************************************************************"
	di in red "WARNING: The argument of option 'mlmodel()' must be one of these:       "
	di in red "'ols', 'elasticnet', 'tree', 'randomforest', 'boost', 'nearestneighbor',"       
	di in red "'neuralnet', 'svm'. 												       "
	di in red "************************************************************************"
	di _newline
break
exit	
}
********************************************************************************
if "`c(os)'" == "MacOSX"{
	cap rm _____in_prediction.dta
	cap rm _____out_prediction.dta
	cap rm _____out_sample_y.dta
	cap rm _____out_sample_x.dta
}
else{
	cap erase _____in_prediction.dta
	cap erase _____out_prediction.dta
	cap erase _____out_sample_y.dta
	cap erase _____out_sample_x.dta
}
********************************************************************************
di ""
di as text "=== Begin Python dependencies ======================================================================="
pylearn , setup
di as text "=== End Python dependencies ========================================================================="
di ""
********************************************************************************
set varabbrev off
********************************************************************************
* DROP ALL THE LABEL VALUES AND PUT THEM IN A TEMPFILE
********************************************************************************
tempfile LABELS
qui: label save _all using `LABELS' , replace
qui: label drop _all
********************************************************************************
* SPLIT "varlist" INTO "target" AND "features"
********************************************************************************
gettoken y X : varlist
********************************************************************************
* MARK THE SAMPLE TO USE
********************************************************************************
marksample touse
********************************************************************************
if "`default'"!=""{
r_ml_stata_default `varlist' if `touse' ,  ///
mlmodel("`mlmodel'")            ///
data_test("`data_test'")        ///
prediction("`prediction'")      ///
seed("`seed'") 
exit
}
if "`default'"=="" & ("`cross_validation'"=="" | "`n_folds'"==""){
	di _newline
	di in red "*************************************************************************"
	di in red "WARNING: It seems you want to run this command not in the 'default' mode."
	di in red "It means that you want to use cross-validation. If it is the case,       "                         	
	di in red "provide options 'cross_validation()' and 'n_folds()', plus               " 
	di in red "all the options required by the specific learner you wish to run.        " 
	di in red "On the contrary, if it is your intention to run the default more,        "	
	di in red "only add the option 'default'.                                           "	
	di in red "*************************************************************************"
	di _newline
break
exit
}
********************************************************************************
* WARNING
********************************************************************************
cap confirm file "`cross_validation'.dta"
if _rc==0 {
	di _newline
	di in red "******************************************************************************"
	di in red "WARNING: A file named `cross_validation'.dta exists in your working directory." 
	di in red "Please, change name to this dataset or delete it before running this command. "   
	di in red "******************************************************************************"
	di _newline
break
exit
}
********************************************************************************
* SAVE THE INITIAL DATASET
********************************************************************************
tempfile data_initial 
qui count
local N_train_all=r(N)
tempvar __id
gen `__id'=_n
qui: save `data_initial' , replace
********************************************************************************
* SELECT THE TRAINING SAMPLE
********************************************************************************
qui: keep if `touse'
preserve
keep `__id'
tempfile data_id
qui save `data_id' , replace
restore
********************************************************************************
* WARNING:
********************************************************************************
cap confirm file "_____out_sample_y.dta"
if _rc==0 {
di _newline
di in red "*****************************************************************************"
di in red "WARNING: A file named '_____out_sample_y.dta' exists in your working directory.   " 
di in red "Please, change name to this dataset or delete it before running this command."   
di in red "*****************************************************************************"
di _newline
break
exit
}
********************************************************************************
* WARNING:
********************************************************************************
cap confirm file "_____out_sample_x.dta"
if _rc==0 {
di _newline
di in red "*****************************************************************************"
di in red "WARNING: A file named '_____out_sample_x.dta' exists in your working directory.   " 
di in red "Please, change name to this dataset or delete it before running this command."   
di in red "*****************************************************************************"
di _newline
break
exit
}
********************************************************************************
* FORM THE TESTING TARGET VARIABLE
********************************************************************************
local _____out_sample_y "_____out_sample_y"
preserve
qui: use `data_test' , clear
qui: keep `y' 
qui save `_____out_sample_y' , replace
restore
*
********************************************************************************
* WARNING:
********************************************************************************
local _____out_sample_x "_____out_sample_x"
preserve
qui: use `data_test' , clear
capture{
	qui: keep `X' 	
}
local rc=_rc 
if `rc'==111{
	di _newline
	di in red "******************************************************************"	 	
	di in red "WARNING: Your testing dataset does not contain the same features  "
	di in red "of your training dataset. It is required that your testing dataset" 
	di in red "owns all the features declared in varlist.                        "
	di in red "******************************************************************"	 	
	break 
	exit    
}
label drop _all
qui save `_____out_sample_x' , replace
restore
********************************************************************************
local k: word count `X'
preserve
qui: use "`_____out_sample_x'" , clear
qui: des 
local p=r(k)
restore
if `p'!=`k'{
	di _newline
	di in red "*******************************************************************"	 	
	di in red "WARNING: Your testing set has `p' features, while your training set"
	di in red "has `k' features (those listed in 'varlist').                      " 
	di in red "The two sets must have the same number of features.                "  
	di in red "*******************************************************************"	 	
	break 
	exit                              
}
else{
	preserve
	qui: keep `X'
	order _all , alpha
	qui: ds
	local X_train_sort `r(varlist)'
	qui use "`_____out_sample_x'" , clear
	order _all , alpha
	qui: ds
	local X_test_sort `r(varlist)'
	order `X_test_sort'
	local i=1
	foreach v of local X_train_sort{
		local h: word `i' of `X_test_sort'
		if "`v'"!="`h'"{
        di _newline
	    di in red "***********************************************************************************"	 	
        di in red "WARNING: The predictors in the testing set do not match those in 'varlist'.        "
        di in red "Please, let the testing set only contain the sole predictors declared in 'varlist'."
	    di in red "***********************************************************************************"
		di _newline
		break 
		exit 1
		}
		local i=`i'+1
	}
	restore
}
********************************************************************************
* WARNING
********************************************************************************
foreach v of local X{
     capture confirm string variable `v'
         if !_rc {di _newline
				  di in red "*********************************************************************************"	 	
                  di in red "WARNING: In your training set of predictors, variable '`v'' is a string variable."
				  di in red "Please, make it numerical. If this variable is categorical,                      "
				  di in red "please generate the categorical binary dummies and use them as predictors        "
				  di in red "in place of variable '`v''.                                                      "  
				  di in red "*********************************************************************************"
				  di _newline
                  break
                  exit				  
				}
        }
********************************************************************************
* WARNING
********************************************************************************
foreach v of local y{
     capture confirm string variable `v'
         if !_rc {di _newline
				  di in red "*****************************************************************************"	 	
                  di in red "WARNING: In your training set the target variable '`v'' is a string variable."
				  di in red "Please, make it numerical.                                                   "
				  di in red "*****************************************************************************"	 	
				  di _newline
                  break
                  exit
                }
        }
********************************************************************************
* WARNING
********************************************************************************
preserve
qui: use `_____out_sample_x', clear
foreach v of local X{
     capture confirm string variable `v'
         if !_rc {
		 	      di _newline
				  di in red "********************************************************************************"
                  di in red "WARNING: In your testing set of predictors, variable '`v'' is a string variable."
				  di in red "Please, make it numerical. If this variable is categorical,                     "
				  di in red "please generate the categorical binary dummies and use them as predictors       "  
				  di in red "in place of variable '`v''.                                                     "  
				  di in red "********************************************************************************"
				  di _newline
                  break
                  exit               		
				}
        }
restore
********************************************************************************
* WARNING
********************************************************************************
preserve
qui: use `_____out_sample_y', clear
foreach v of local y{
     capture confirm string variable `v'
         if !_rc {
		 	      di _newline
				  di in red "****************************************************************************"
                  di in red "WARNING: In your testing set the target variable '`v'' is a string variable."
				  di in red "Please, make it numerical.                                                  "
				  di in red "****************************************************************************"
				  di _newline
                  break
                  exit
                }
        }
restore
********************************************************************************
* COUNT THE USED TESTING OBSERVATIONS AND ELIMINATE MISSINGS FROM "_____out_sample_x"
********************************************************************************
preserve 
qui: use `_____out_sample_x', clear
tempfile _____out_sample_x_initial
qui: save `_____out_sample_x_initial', replace
qui: use `_____out_sample_x_initial' , clear
tempvar __id2
gen `__id2'= _n
qui save `_____out_sample_x_initial', replace
restore
********************************************************************************
preserve
qui: use `_____out_sample_x_initial' , clear
qui reg _all
qui: keep if e(sample)
keep `__id2'
tempfile data_id2
qui save `data_id2', replace
restore
********************************************************************************
preserve
qui: use `_____out_sample_x', clear
qui count 
local N_test_all=r(N)
qui reg _all
qui count if e(sample)
local N_test_used=r(N)
qui: keep if e(sample)
qui: save `_____out_sample_x', replace
restore
********************************************************************************
* WARNING
********************************************************************************
capture confirm variable index
if !_rc {
	di _newline
	di in red "************************************************"
	di in red "WARNING: One of your variables is names 'index'." 
	di in red "Please, change name to this variable.           "   
	di in red "************************************************"
	di _newline
	break
	exit
}
********************************************************************************
* WARNING
********************************************************************************
cap confirm file "_____in_prediction.dta"
if _rc==0 {
	di _newline
	di in red "*****************************************************************************"
	di in red "WARNING: A file named '_____in_prediction.dta' exists in your working directory.  " 
	di in red "Please, change name to this dataset or delete it before running this command."   
	di in red "*****************************************************************************"
	di _newline
break
exit
}
********************************************************************************
cap confirm file "_____out_prediction.dta"
if _rc==0 {
	di _newline
	di in red "*****************************************************************************"
	di in red "WARNING: A file named '_____out_prediction.dta' exists in your working directory. " 
	di in red "Please, change name to this dataset or delete it before running this command."   
	di in red "*****************************************************************************"
	di _newline
	break
	exit
}
********************************************************************************
local _____in_prediction "_____in_prediction"
local _____out_prediction "_____out_prediction"
********************************************************************************
*
********************************************************************************
* COMPUTE THE SAMPLE SIZE OF THE TRAINING DATASET. 
* THEN, MAKE THE ORDERING OF THE "X" IN THE TESTING DATASET THE SAME 
* AS THE ORDERING OF THE "X" IN THE TRAINING DATASET. 
********************************************************************************
preserve
qui count if `touse'
local N_train_used=r(N)
local N_features: word count `X'
qui: use `_____out_sample_x' , clear
order `X'  // same order of the X in the training and testing datasets
qui: save `_____out_sample_x'  , replace
restore
********************************************************************************
* PASS THE STATA DIRECTORY TO PYTHON
********************************************************************************
local dir `c(pwd)'
********************************************************************************
* SELECT AND ORDER THE VARIABLES IN THE TRAINING DATASET
********************************************************************************
keep `y' `X'
order `y' `X'
********************************************************************************
* WARNING
********************************************************************************
qui{
preserve
keep `y' `X'
order `y' `X'
qui count 
local NN=r(N)
qui reg `y' `X'
keep if e(sample)
qui count 
local SS=r(N)
restore
}
********************************************************************************
if `SS'!=`NN'{
	di _newline
	di in red "********************************************************************"
	di in red "WARNING: It seems there are missing values in your training dataset,"
	di in red "either in your target variable, or in your predictors.              "
	di in red "Please, check and remove them. Then, re-run this command.           "
	di in red "********************************************************************"
	di _newline
	exit
}
********************************************************************************
* WARNING 
********************************************************************************
qui{
preserve
qui: use `_____out_sample_x' , clear
qui count 
local NN=r(N)
qui reg _all
keep if e(sample)
qui count 
local SS=r(N)
restore
}
********************************************************************************
if `SS'!=`NN'{
	di _newline
	di in red "***********************************************************************************"
	di in red "WARNING: It seems there are missing values in the features of your testing dataset."
	di in red "Please, check and remove them. Then, re-run this command.                          "
	di in red "***********************************************************************************"
	di _newline
	exit
}
********************************************************************************
* ESTIMATION PROCEDURE
********************************************************************************
* SAVE THE DATASET AS IT IS
********************************************************************************
tempfile data_fitting 
qui: save `data_fitting' , replace
di in red "=== Begin Python warnings ==========================================================================="
********************************************************************************
* PYTHON CODE - BEGIN 
********************************************************************************
if "`mlmodel'"=="ols"{
python: r_ols()
preserve
use `_____in_prediction' , clear
if "`prediction'"!=""{
rename _0 `prediction' 
}
qui: save `_____in_prediction' , replace
restore
ereturn clear
}
********************************************************************************
if "`mlmodel'"=="boost"{
	if "`n_estimators'"!="" & "`tree_depth'"!="" & "`learning_rate'"!=""{
	numlist_to_matrix , num_list(`n_estimators')
	mat mat_n_estmators = r(M)	

	numlist_to_matrix , num_list(`tree_depth')
	mat mat_max_depth = r(M)

	numlist_to_matrix , num_list(`learning_rate')
	mat mat_learning_rate = r(M)		
	}
else{
	di _newline
	di in red "****************************************************************"
	di in red "WARNING: Boosting requires to specify these options:            " 
	di in red "(1) 'n_estimators()'; (2) 'tree_depth()'; (3) 'learning_rate()'."   
	di in red "****************************************************************"
	di _newline
break
exit
}
python: r_boost()
preserve
use `_____in_prediction' , clear
if "`prediction'"!=""{
rename _0 `prediction' 
}
qui: save `_____in_prediction' , replace
restore
ereturn clear
ereturn scalar OPT_LEARNING_RATE=OPT_LEARNING_RATE
ereturn scalar OPT_N_ESTIMATORS=OPT_N_ESTIMATORS
ereturn scalar OPT_MAX_DEPTH=OPT_MAX_DEPTH
}
********************************************************************************
else if "`mlmodel'"=="nearestneighbor"{
	if "`nn'"!=""{ 
	numlist_to_matrix , num_list(`nn')
	mat mat_n_neighbor = r(M)
	}
else{
	di _newline
	di in red "****************************************************************"
	di in red "WARNING: Nearest Neighbor requires to specify this option:      " 
	di in red "(1) 'nn()'.                                                     "   
	di in red "****************************************************************"
	di _newline
break
exit	
}
python: r_nearestneighbor()
preserve
use `_____in_prediction' , clear
if "`prediction'"!=""{
rename _0 `prediction' 
}
qui: save `_____in_prediction' , replace
restore
ereturn clear
ereturn scalar OPT_NN=OPT_NN
ereturn local OPT_WEIGHT "$OPT_WEIGHT"
}
********************************************************************************
else if "`mlmodel'"=="neuralnet"{
	if "`n_neurons_l1'"!="" & "`n_neurons_l1'"!="" & "`alpha'"!=""{ 
		numlist_to_matrix , num_list(`n_neurons_l1')
		mat mat_n_neurons_l1 = r(M)	

		numlist_to_matrix , num_list(`n_neurons_l2')
		mat mat_n_neurons_l2 = r(M)	
		
		numlist_to_matrix , num_list(`alpha')
		mat mat_alpha = r(M)	
    }
else{
	di _newline
	di in red "**********************************************************"
	di in red "WARNING: Neural Network requires to specify these options:" 
	di in red "(1) 'n_neurons_l1()'; (2) 'n_neurons_l2()'; (3) 'alpha()'."   
	di in red "**********************************************************"
	di _newline
break
exit
}
python: r_neuralnet()
preserve
use `_____in_prediction' , clear
if "`prediction'"!=""{
rename _0 `prediction' 
}
qui: save `_____in_prediction' , replace
restore
ereturn clear
ereturn scalar OPT_NEURONS_L_1=OPT_NEURONS_L_1
ereturn scalar OPT_NEURONS_L_2=OPT_NEURONS_L_2
ereturn scalar OPT_ALPHA=OPT_ALPHA
}
********************************************************************************
else if "`mlmodel'"=="randomforest"{
	if "`n_estimators'"!="" & "`tree_depth'"!="" & "`max_features'"!=""{
	numlist_to_matrix , num_list(`n_estimators')
	mat mat_n_estmators = r(M)	

	numlist_to_matrix , num_list(`tree_depth')
	mat mat_tree_depth = r(M)

	numlist_to_matrix , num_list(`max_features')
	mat mat_max_features = r(M)
	}
else{
	di _newline
	di in red "**************************************************************"
	di in red "WARNING: Random Forest requires to specify these options: " 
	di in red "(1) 'n_estimators()'; (2) 'tree_depth()'; (3) 'max_features()'"   
	di in red "**************************************************************"
	di _newline
break
exit	
}
python: r_randomforest()
preserve
use `_____in_prediction' , clear
if "`prediction'"!=""{
rename _0 `prediction' 
}
qui: save `_____in_prediction' , replace
restore
ereturn clear
ereturn scalar OPT_MAX_DEPTH=OPT_MAX_DEPTH
ereturn scalar OPT_MAX_FEATURES=OPT_MAX_FEATURES
ereturn scalar OPT_N_ESTIMATORS=OPT_N_ESTIMATORS
}
********************************************************************************
else if "`mlmodel'"=="svm"{
	if "`c'"!="" & "`gamma'"!="" {
	numlist_to_matrix , num_list(`c')
	mat mat_c = r(M)	

	numlist_to_matrix , num_list(`gamma')
	mat mat_gamma = r(M)
	}
else{
	di _newline
	di in red "******************************************************************"
	di in red "WARNING: Support Vector Machine requires to specify these options:" 
	di in red "(1) 'c()'; (2) 'gamma()'.                                         "   
	di in red "******************************************************************"
	di _newline
break
exit	
}
python: r_svm()
preserve
use `_____in_prediction' , clear
if "`prediction'"!=""{
rename _0 `prediction' 
}
qui: save `_____in_prediction' , replace
restore
ereturn clear
ereturn scalar OPT_C=OPT_C
ereturn scalar OPT_GAMMA=OPT_GAMMA
}
********************************************************************************
else if "`mlmodel'"=="tree"{
    if "`tree_depth'"!=""{
	numlist_to_matrix , num_list(`tree_depth')
	mat mat_tree_depth = r(M)	
    }
else{
	di _newline
	di in red "*********************************************************"
	di in red "WARNING: Regression tree requires to specify this option:" 
	di in red "(1) 'tree_depth()'                                       "   
	di in red "**********************************************************"
	di _newline
break
exit	
}	
python: r_tree()
preserve
use `_____in_prediction' , clear
if "`prediction'"!=""{
rename _0 `prediction' 
}
qui: save `_____in_prediction' , replace
restore
ereturn clear
ereturn scalar OPT_DEPTH=OPT_LEAVES
}
********************************************************************************
else if "`mlmodel'"=="elasticnet"{
	if "`l1_ratio'"!="" & "`alpha'"!=""{ 
	numlist_to_matrix , num_list(`l1_ratio')
	mat mat_l1_ratio = r(M)		

	numlist_to_matrix , num_list(`alpha')
	mat mat_alpha = r(M)		
	}
else{
	di _newline
	di in red "******************************************************"
	di in red "WARNING: Elasticnet requires to specify these options:" 
	di in red "(1) 'alpha()'; (2) 'l1_ratio()'.                      "   
	di in red "******************************************************"
	di _newline
break
exit	
}
python: r_elasticnet()
preserve
use `_____in_prediction' , clear
if "`prediction'"!=""{
rename _0 `prediction' 
}
qui: save `_____in_prediction' , replace
restore
ereturn clear
ereturn scalar OPT_ALPHA=OPT_ALPHA
ereturn scalar OPT_L1_RATIO=OPT_L1_RATIO
}
********************************************************************************
*
********************************************************************************
di in red "=== End Python warnings ============================================================================="
di _newline
di as text "=== Begin Stata output =============================================================================="
********************************************************************************
* STORE RESULTS
******************************************************************************** 
preserve
********************************************************************************
qui: use `cross_validation' , clear
qui sum mean_test_score
scalar max_score_test=r(max)
ereturn scalar TEST_ACCURACY=max_score_test
********************************************************************************
qui sum mean_train_score if mean_test_score==max_score_test
scalar score_train=r(mean)
ereturn scalar TRAIN_ACCURACY=score_train
********************************************************************************
qui sum index if mean_test_score==max_score_test
scalar max_index=r(mean)
ereturn scalar BEST_INDEX=int(max_index)
ereturn scalar SE_TEST_ACCURACY=std_test_score[max_index+1]
ereturn scalar N_FOLDS=`n_folds'
********************************************************************************
restore
********************************************************************************
preserve
if "`prediction'"!=""{
qui: use `_____out_prediction' , clear
rename _0 `prediction' 
}
qui: save `_____out_prediction' , replace
restore
********************************************************************************
* CROSS-VALIDATION GRAPH
********************************************************************************
qui: use `cross_validation' , clear
local A=int(max_index)
if "`graph_cv'"!=""{
tw ///
(line mean_test_score index  , xline(`A',lp(dash) lw(thick))) ///
(line mean_train_score index ) , ///
legend(order(1 "TEST ACCURACY" 2 "TRAIN ACCURACY")) ///
note("Learner = `mlmodel'" "Optimal index = `A'" "Number of folds = `n_folds'") ///
ytitle(Accuracy) xtitle(Index) ///
graphregion(fcolor(white)) scheme(s2mono)
}
********************************************************************************
if "`save_graph_cv'"!=""{
set graph off
tw ///
(line mean_test_score index  , xline(`A',lp(dash) lw(thick))) ///
(line mean_train_score index ) , ///
legend(order(1 "TEST ACCURACY" 2 "TRAIN ACCURACY")) ///
note("Learner = `mlmodel'" "Optimal index = `A'" "Number of folds = `n_folds'") ///
ytitle(Accuracy) xtitle(Index) ///
graphregion(fcolor(white)) scheme(s2mono)
qui: graph save `save_graph_cv' , replace
set graph on	
}
********************************************************************************
********************************************************************************
if "`prediction'"!=""{
********************************************************************************
* WARNING
********************************************************************************
capture confirm variable _train_index
if !_rc {
	di _newline
	di in red "*****************************************************************************"
	di in red "WARNING: One of your variables in the dataset is named '_train_index'.       " 
	di in red "Please, change name to this variable before running this command,            "
	di in red "as this name is used for the identifier of training and testing observations."     
	di in red "*****************************************************************************"
	di _newline
	break
	exit
}
********************************************************************************	
qui{ // start quietly
tempfile _____out_sample_x_y
qui: use `_____out_sample_x'
qui merge 1:1 _n using `_____out_sample_y'
cap drop _merge
qui merge 1:1 _n using `_____out_prediction'
cap drop _merge
qui merge 1:1 _n using `data_id2'
cap drop _merge
drop if `__id2'==.
qui save `_____out_sample_x_y'
********************************************************************************
preserve
qui: use `_____out_sample_x_initial', clear
merge 1:1 `__id2' using `_____out_sample_x_y'
cap drop _merge
qui save `_____out_sample_x_initial', replace
restore
********************************************************************************
qui: use `data_initial' , clear
preserve
qui: use `_____in_prediction' , clear
merge 1:1 _n using `data_id'
cap drop _merge
qui: save `_____in_prediction' , replace
restore
qui: merge 1:1 `__id' using `_____in_prediction'
cap drop _merge
cap drop _train_index
gen _train_index = "train"
********************************************************************************
preserve
qui use `_____out_sample_x_initial' , clear
keep `prediction' 
merge 1:1 _n using `data_test'
cap drop _merge
qui save `_____out_sample_x_initial' , replace
restore
********************************************************************************
* Append the dataset "`_____out_sample_x_initial'"
********************************************************************************
append using `_____out_sample_x_initial'
replace _train_index = "test" if _train_index==""
********************************************************************************
* Compute validation train-MSE
tempvar v_train_mse 
gen `v_train_mse'= (`y'-`prediction')^2 if _train_index=="train"
qui sum `v_train_mse' 
ereturn scalar Train_mse = r(mean)

* Compute validation train-MAPE
tempvar v_train_mape 
gen `v_train_mape'= abs((`y'-`prediction')/`y')*100 if _train_index=="train"
qui sum `v_train_mape' 
ereturn scalar Train_mape = r(mean)

* Compute validation test-MSE
tempvar v_test_mse 
gen `v_test_mse'= (`y'-`prediction')^2 if _train_index=="test"
qui sum `v_test_mse' 
ereturn scalar Test_mse = r(mean)

* Compute validation test-MAPE
tempvar v_test_mape 
gen `v_test_mape'= abs((`y'-`prediction')/`y')*100 if _train_index=="test"
qui sum `v_test_mape' 
ereturn scalar Test_mape = r(mean)
} // end quietly
}
else{
qui: use `data_initial' , clear
} 
********************************************************************************
* Display output
********************************************************************************
ereturn local dep_var "`y'"
ereturn scalar N_features=`N_features' 
ereturn scalar N_train_all=`N_train_all' 
ereturn scalar N_test_all=`N_test_all'  
ereturn scalar N_train_used=`N_train_used' 
ereturn scalar N_test_used=`N_test_used'  
********************************************************************************
* Tree
********************************************************************************
if "`prediction'"==""{
	if "`mlmodel'"=="tree"{
    display_output_r_tree 
	}
}
else if "`prediction'"!=""{
	if "`mlmodel'"=="tree"{
    display_output_r_tree , prediction	
	}
}
********************************************************************************
* Elasticnet
********************************************************************************
if "`prediction'"==""{
	if "`mlmodel'"=="elasticnet"{
    display_output_r_elasticnet 
	}
}
else if "`prediction'"!=""{
	if "`mlmodel'"=="elasticnet"{
    display_output_r_elasticnet , prediction	
	}
}
********************************************************************************
* SVM
********************************************************************************
if "`prediction'"==""{
	if "`mlmodel'"=="svm"{
    display_output_r_svm 
	}
}
else if "`prediction'"!=""{
	if "`mlmodel'"=="svm"{
    display_output_r_svm , prediction	
	}
}
********************************************************************************
* Random forests
********************************************************************************
if "`prediction'"==""{
	if "`mlmodel'"=="randomforest"{
    display_output_r_randomforest 
	}
}
else if "`prediction'"!=""{
	if "`mlmodel'"=="randomforest"{
    display_output_r_randomforest , prediction	
	}
}
********************************************************************************
* Neural network
********************************************************************************
if "`prediction'"==""{
	if "`mlmodel'"=="neuralnet"{
    display_output_r_neuralnet
	}
}
else if "`prediction'"!=""{
	if "`mlmodel'"=="neuralnet"{
    display_output_r_neuralnet , prediction	
	}
}
********************************************************************************
* Nearest Neighbor
********************************************************************************
if "`prediction'"==""{
	if "`mlmodel'"=="nearestneighbor"{
    display_output_r_nearestneighbor
	}
}
else if "`prediction'"!=""{
	if "`mlmodel'"=="nearestneighbor"{
    display_output_r_nearestneighbor , prediction	
	}
}
********************************************************************************
* Boosting
********************************************************************************
if "`prediction'"==""{
	if "`mlmodel'"=="boost"{
    display_output_r_boost
	}
}
else if "`prediction'"!=""{
	if "`mlmodel'"=="boost"{
    display_output_r_boost , prediction	
	}
}
********************************************************************************
* OLS
********************************************************************************
if "`prediction'"==""{
	if "`mlmodel'"=="ols"{
    display_output_r_ols
	}
}
else if "`prediction'"!=""{
	if "`mlmodel'"=="ols"{
    display_output_r_ols , prediction	
	}
}
********************************************************************************
di as text "=== End Stata output ================================================================================"
********************************************************************************
cap drop index
********************************************************************************
if "`c(os)'" == "MacOSX"{
	cap rm `_____in_prediction'.dta
	cap rm `_____out_prediction'.dta
	cap rm `_____out_sample_y'.dta
	cap rm `_____out_sample_x'.dta
}
else{
	cap erase `_____in_prediction'.dta
	cap erase `_____out_prediction'.dta
	cap erase `_____out_sample_y'.dta
	cap erase `_____out_sample_x'.dta
}
********************************************************************************
set varabbrev on
********************************************************************************
qui: do `LABELS'
********************************************************************************
end 
********************************************************************************

*
*
*

********************************************************************************
* PYTHON FUNCTIONS
********************************************************************************
python:
################################################################################
#! "r_tree()": Tree regression with CV 
#! Author: Giovanni Cerulli
#! Version: 7
#! Date: 02/05/2022
################################################################################
def r_tree():
	# IMPORT NEEDED PACKAGES
	from sklearn.tree import DecisionTreeRegressor
	from sklearn.model_selection import GridSearchCV
	from sfi import Macro, Scalar , Matrix
	from sfi import Data , SFIToolkit
	import numpy as np
	import pandas as pd
	import os
	
	# SET THE DIRECTORY
	dir=Macro.getLocal("dir")
	os.chdir(dir)
	
	# SET THE TRAIN/TEST DATASET AND THE NEW-INSTANCES-DATASET
	dataset=Macro.getLocal("data_fitting")
	
	# LOAD A STATA DATASET LOCATED INTO THE DIRECTORY AS PANDAS DATAFRAME
	df = pd.read_stata(dataset,convert_categoricals=False)
	
	# DEFINE y THE TARGET VARIABLE
	y=df.iloc[:,0]
	
	# DEFINE X THE FEATURES
	X=df.iloc[:,1::]
	
	# READ THE "SEED" FROM STATA
	R=int(Macro.getLocal("seed"))
	
	# FIT A TREE (with the "number of leaves" parameter=5) JUST FOR ILLUSTRATION
	model=DecisionTreeRegressor(max_depth=5,random_state=R)
	
	# DEFINE THE PARAMETER VALUES THAT SHOULD BE SEARCHED
	# k_range = list(range(1,16))
	tree_depth = Matrix.get("mat_tree_depth")
	k_range=tree_depth[0]

	# CREATE A PARAMETER GRID: MAP THE PARAMETER NAMES TO THE VALUES THAT SHOULD BE SEARCHED
	param_grid = dict(max_depth=k_range)
	
	# READ THE NUMBER OF CV-FOLDS "n_folds" FROM STATA
	n_folds=int(Macro.getLocal("n_folds"))
	
	# INSTANTIATE THE GRID
	grid = GridSearchCV(model, param_grid, cv=n_folds, scoring='explained_variance', return_train_score=True)	
	
	# FIT THE GRID
	grid.fit(X, y)
	
	# FIT THE GRID
	grid.fit(X, y)
	
	# ALL_CV_RES=pd.DataFrame(grid.cv_results_)[['param_max_depth','mean_train_score','mean_test_score']]

	# VIEW THE RESULTS 
	CV_RES=pd.DataFrame(grid.cv_results_)[['mean_train_score','mean_test_score','std_test_score']]
	D=Macro.getLocal("cross_validation") 
	D=D+".dta"
	CV_RES.to_stata(D)
	
	# EXAMINE THE BEST MODEL
	Scalar.setValue('OPT_SCORE',grid.best_score_,vtype='visible')
	
	# PUT "OPT_LEAVES" INTO A STATA SCALAR
	params_values=list(grid.best_params_.values())
	Scalar.setValue('OPT_LEAVES',params_values[0],vtype='visible')
	
	# GET THE VALUE "opt_leaves" AND PUT IT INTO A STATA SCALAR "OPT_LEAVES"
	opt_leaves=grid.best_params_.get('max_depth')
	
	# TRAIN YOUR MODEL USING ALL DATA AND THE BEST KNOWN PARAMETERS
	model=DecisionTreeRegressor(max_depth=opt_leaves,random_state=R)
	
	# FIT THE MODEL
	model.fit(X, y)

	# MAKE IN-SAMPLE PREDICTION FOR y
	y_hat = model.predict(X)
	
	# PUT IN-SAMPLE PREDICTION of y IN A DATA FRAME
	in_sample = pd.DataFrame(y_hat)
	
	# PUT IN-SAMPLE PREDICTION INTO STATA
	D=Macro.getLocal("_____in_prediction") 
	D=D+".dta"
	in_sample.to_stata(D)
	
	# MAKE OUT-OF-SAMPLE PREDICTION FOR y USING A PREPARED DATASET
	D=Macro.getLocal("_____out_sample_x") 
	D=D+".dta"
	Xnew = pd.read_stata(D)
	ynew = model.predict(Xnew)

	# PUT OUT-OF-SAMPLE PREDICTION FOR y INTO A DATA FRAME
	Ynew = pd.DataFrame(ynew)

	# GENERATE A DATAFRAME 'OUT'
	OUT = pd.DataFrame(Ynew)
					
	# PUT "OUT" AS STATA DATASET
	# (NOTE: the first column is the prediction "y_hat")
	D=Macro.getLocal("_____out_prediction") 
	D=D+".dta"
	OUT.to_stata(D)
	
	# PRINT GRID SEARCH RESULTS
	ALL_CV_RES=pd.DataFrame(grid.cv_results_)[['param_max_depth','mean_train_score','mean_test_score']]
	ALL_CV_RES.columns = ['Tree depth', 'Train accuracy', 'Test accuracy']
	ALL_CV_RES['Index'] = ALL_CV_RES.index
	column_names = ['Index','Tree depth', 'Train accuracy', 'Test accuracy']
	ALL_CV_RES = ALL_CV_RES.reindex(columns=column_names)
	print("================================================")
	print(" Results of cross-validation grid search")
	print("================================================")
	print(ALL_CV_RES.to_string(index=False))
	print("================================================")
################################################################################

################################################################################
#! "r_elasticnet()": Elastic-net with CV 
#! Author: Giovanni Cerulli
#! Version: 7
#! Date: 02/05/2022
################################################################################
def r_elasticnet():
	# IMPORT NEEDED PACKAGES
	from sklearn.linear_model import ElasticNet
	from sklearn.model_selection import GridSearchCV
	from sfi import Macro, Scalar , Matrix
	from sfi import Data , SFIToolkit
	import numpy as np
	import pandas as pd
	import os

	# SET THE DIRECTORY
	dir=Macro.getLocal("dir")
	os.chdir(dir)

	# SET THE TRAIN/TEST DATASET AND THE NEW-INSTANCES-DATASET
	dataset=Macro.getLocal("data_fitting")

	# LOAD A STATA DATASET LOCATED INTO THE DIRECTORY AS PANDAS DATAFRAME
	df = pd.read_stata(dataset,convert_categoricals=False)

	# DEFINE y THE TARGET VARIABLE
	y=df.iloc[:,0]

	# DEFINE X THE FEATURES
	X=df.iloc[:,1::]

	# INITIALIZE AN ELATIC NET
	model = ElasticNet()

	# "CROSS-VALIDATION" FOR "L1_RATIO" ("C") AND "ALFA"  BY PRODUCING A "GRID SEARCH"
	# GENERATE THE TWO PARAMETERS' GRID AS A "LIST"
	
	_M = Matrix.get("mat_l1_ratio")
	gridC=_M[0]
	
	_M = Matrix.get("mat_alpha")
	gridG=_M[0]
	
	#gridC=(0,0.25,0.50,0.75,1)
	#gridG=(0,10,20,30,40,50,60,70,80,90,100,110,120,130,150)

	# PUT THE GENERATED GRIDS INTO A PYTHON DICTIONARY 
	param_grid = {'l1_ratio': gridC, 'alpha': gridG}

	# READ THE NUMBER OF CV-FOLDS "n_folds" FROM STATA
	n_folds=int(Macro.getLocal("n_folds"))

	# INSTANTIATE THE GRID
	grid = GridSearchCV(model, param_grid, cv=n_folds, scoring='explained_variance', return_train_score=True)

	# FIT THE GRID
	grid.fit(X, y)

	# VIEW THE RESULTS 
	CV_RES=pd.DataFrame(grid.cv_results_)[['mean_train_score','mean_test_score','std_test_score']]
	D=Macro.getLocal("cross_validation") 
	D=D+".dta"
	CV_RES.to_stata(D)

	params_values=list(grid.best_params_.values()) 
	Scalar.setValue('OPT_ALPHA',params_values[0],vtype='visible')
	Scalar.setValue('OPT_L1_RATIO',params_values[1],vtype='visible')

	# GET THE VALUE "opt_c" AND PUT IT INTO A STATA SCALAR "OPT_C"
	opt_c=grid.best_params_.get('l1_ratio')

	# GET THE VALUE "opt_gamma" AND PUT IT INTO A STATA SCALAR "OPT_GAMMA"
	opt_gamma=grid.best_params_.get('alpha')

	# TRAIN YOUR MODEL USING ALL DATA AND THE BEST KNOWN PARAMETERS
	model = ElasticNet(l1_ratio=opt_c, alpha=opt_gamma)

	# FIT THE MODEL
	model.fit(X, y)

	# MAKE IN-SAMPLE PREDICTION FOR y
	y_hat = model.predict(X)
	
	# PUT IN-SAMPLE PREDICTION of y IN A DATA FRAME
	in_sample = pd.DataFrame(y_hat)
	
	# PUT IN-SAMPLE PREDICTION INTO STATA
	D=Macro.getLocal("_____in_prediction") 
	D=D+".dta"
	in_sample.to_stata(D)
	
	# MAKE OUT-OF-SAMPLE PREDICTION FOR y USING A PREPARED DATASET
	D=Macro.getLocal("_____out_sample_x") 
	D=D+".dta"
	Xnew = pd.read_stata(D)
	ynew = model.predict(Xnew)

	# PUT OUT-OF-SAMPLE PREDICTION FOR y INTO A DATA FRAME
	Ynew = pd.DataFrame(ynew)

	# GENERATE A DATAFRAME 'OUT'
	OUT = pd.DataFrame(Ynew)
					
	# PUT "OUT" AS STATA DATASET
	# (NOTE: the first column is the prediction "y_hat")
	D=Macro.getLocal("_____out_prediction") 
	D=D+".dta"
	OUT.to_stata(D)
	
	# PRINT GRID SEARCH RESULTS
	ALL_CV_RES=pd.DataFrame(grid.cv_results_)[['param_l1_ratio','param_alpha','mean_train_score','mean_test_score']]
	ALL_CV_RES.columns = ['L1 ratio', 'alpha' , 'Train accuracy', 'Test accuracy']
	ALL_CV_RES['Index'] = ALL_CV_RES.index
	column_names = ['Index','L1 ratio', 'alpha' , 'Train accuracy', 'Test accuracy']
	ALL_CV_RES = ALL_CV_RES.reindex(columns=column_names)
	print("====================================================")
	print(" Results of cross-validation grid search")
	print("====================================================")
	print(ALL_CV_RES.to_string(index=False))
	print("====================================================")
################################################################################

################################################################################
#! "r_svm()": SVM regression with CV
#! Author: Giovanni Cerulli
#! Version: 7
#! Date: 02/05/2022
################################################################################
def r_svm():
	# IMPORT NEEDED PACKAGES
	from sklearn import svm
	from sklearn.svm import SVR
	from sklearn.model_selection import GridSearchCV
	from sfi import Macro, Scalar , Matrix
	from sfi import Data , SFIToolkit
	import numpy as np
	import pandas as pd
	import os

	# SET THE DIRECTORY
	dir=Macro.getLocal("dir")
	os.chdir(dir)

	# SET THE TRAIN/TEST DATASET AND THE NEW-INSTANCES-DATASET
	dataset=Macro.getLocal("data_fitting")

	# LOAD A STATA DATASET LOCATED INTO THE DIRECTORY AS PANDAS DATAFRAME
	df = pd.read_stata(dataset,convert_categoricals=False)

	# DEFINE y THE TARGET VARIABLE
	y=df.iloc[:,0]

	# DEFINE X THE FEATURES
	X=df.iloc[:,1::]

	# READ THE "SEED" FROM STATA
	R=int(Macro.getLocal("seed"))

	# INITIALIZE A SVM (with parameters: kernel='rbf', C = 10.0, gamma=0.1)
	model = SVR(kernel='rbf', C = 10.0, gamma=0.1)

	# SVMC "CROSS-VALIDATION" FOR "C" AND "GAMMA" BY PRODUCING A "GRID SEARCH"
	# GENERATE THE TWO PARAMETERS' GRID AS A "LIST"
	
	_M = Matrix.get("mat_c")
	gridC=_M[0]
	
	_M = Matrix.get("mat_gamma")
	gridG=_M[0]
	
	#gridC=list(range(1,101,10))
	#gridG=[0.1,0.2,0.35,0.5,0.65,0.8,1,10]

	# PUT THE GENERATED GRIDS INTO A PYTHON DICTIONARY 
	param_grid = {'C': gridC, 'gamma': gridG}

	# READ THE NUMBER OF CV-FOLDS "n_folds" FROM STATA
	n_folds=int(Macro.getLocal("n_folds"))

	# INSTANTIATE THE GRID
	grid = GridSearchCV(model, param_grid, cv=n_folds, scoring='explained_variance', return_train_score=True)

	# FIT THE GRID
	grid.fit(X, y)

	# VIEW THE RESULTS 
	CV_RES=pd.DataFrame(grid.cv_results_)[['mean_train_score','mean_test_score','std_test_score']]
	D=Macro.getLocal("cross_validation") 
	D=D+".dta"
	CV_RES.to_stata(D)

	# PUT OPTIMAL PARAMETER(S) INTO STATA SCALAR(S)
	params_values=list(grid.best_params_.values()) 
	
	# GET THE VALUE "opt_c" AND PUT IT INTO A STATA SCALAR "OPT_C"
	opt_c=grid.best_params_.get('C')
	Scalar.setValue('OPT_C',opt_c,vtype='visible')

	# GET THE VALUE "opt_gamma" AND PUT IT INTO A STATA SCALAR "OPT_GAMMA"
	opt_gamma=grid.best_params_.get('gamma')
	Scalar.setValue('OPT_GAMMA',opt_gamma, vtype='visible')

	# TRAIN YOUR MODEL USING ALL DATA AND THE BEST KNOWN PARAMETERS
	model = SVR(kernel='rbf', C=opt_c, gamma=opt_gamma)

	# FIT THE MODEL
	model.fit(X, y)

	# MAKE IN-SAMPLE PREDICTION FOR y
	y_hat = model.predict(X)
	
	# PUT IN-SAMPLE PREDICTION of y IN A DATA FRAME
	in_sample = pd.DataFrame(y_hat)
	
	# PUT IN-SAMPLE PREDICTION INTO STATA
	D=Macro.getLocal("_____in_prediction") 
	D=D+".dta"
	in_sample.to_stata(D)
	
	# MAKE OUT-OF-SAMPLE PREDICTION FOR y USING A PREPARED DATASET
	D=Macro.getLocal("_____out_sample_x") 
	D=D+".dta"
	Xnew = pd.read_stata(D)
	ynew = model.predict(Xnew)

	# PUT OUT-OF-SAMPLE PREDICTION FOR y INTO A DATA FRAME
	Ynew = pd.DataFrame(ynew)

	# GENERATE A DATAFRAME 'OUT'
	OUT = pd.DataFrame(Ynew)
					
	# PUT "OUT" AS STATA DATASET
	# (NOTE: the first column is the prediction "y_hat")
	D=Macro.getLocal("_____out_prediction") 
	D=D+".dta"
	OUT.to_stata(D)
		
	# PRINT GRID SEARCH RESULTS
	ALL_CV_RES=pd.DataFrame(grid.cv_results_)[['param_C','param_gamma','mean_train_score','mean_test_score']]
	ALL_CV_RES.columns = ['c', 'Gamma' , 'Train accuracy', 'Test accuracy']
	ALL_CV_RES['Index'] = ALL_CV_RES.index
	column_names = ['Index','c', 'Gamma' , 'Train accuracy', 'Test accuracy']
	ALL_CV_RES = ALL_CV_RES.reindex(columns=column_names)
	print("===============================================")
	print(" Results of cross-validation grid search")
	print("===============================================")
	print(ALL_CV_RES.to_string(index=False))
	print("===============================================")
################################################################################	

################################################################################
#! "r_randomforest()": Random-forest regression with CV
#! Author: Giovanni Cerulli
#! Version: 7
#! Date: 02/05/2022
################################################################################
def r_randomforest():
	# IMPORT NEEDED PACKAGES
	from sklearn.ensemble import RandomForestRegressor
	from sklearn.model_selection import GridSearchCV
	from sfi import Macro, Scalar , Matrix
	from sfi import Data , SFIToolkit
	import numpy as np
	import pandas as pd
	import os

	# SET THE DIRECTORY
	dir=Macro.getLocal("dir")
	os.chdir(dir)

	# SET THE TRAIN/TEST DATASET AND THE NEW-INSTANCES-DATASET
	dataset=Macro.getLocal("data_fitting")

	# LOAD A STATA DATASET LOCATED INTO THE DIRECTORY AS PANDAS DATAFRAME
	df = pd.read_stata(dataset,convert_categoricals=False)

	# DEFINE y THE TARGET VARIABLE
	y=df.iloc[:,0]

	# DEFINE X THE FEATURES
	X=df.iloc[:,1::]

	# COMPUTE THE NUMBER OF FEATURES 
	X = np.array(X)
	n_features=int(len(X[0]))

	# READ THE "SEED" FROM STATA
	R=int(Macro.getLocal("seed"))

	# ESTIMATE A "RFC" AT GIVEN PARAMETERS (JUST TO TRY IF IT WORKS)
	model = RandomForestRegressor(max_depth=5, n_estimators=3, max_features=2, random_state=R)

	# RFC "CROSS-VALIDATION":
	# WE CROSS-VALIDATE OVER TWO PARAMETERS:
	# 1. "D = tree depth" (i.e., number of layers of the tree);
	# 2. "G = n. of features to randomly consider at each split"
	# 3. "B = number of bootstraps"

	# GENERATE THE TWO PARAMETERS' GRID AS "LISTS"
	
	_M = Matrix.get("mat_tree_depth")
	gridD=_M[0]
	
	_M = Matrix.get("mat_max_features")
	gridG=_M[0]
	gridG = [int(x) for x in gridG]
	
	_M = Matrix.get("mat_n_estmators")
	gridB=_M[0]
	gridB = [int(x) for x in gridB]

	#gridD=list(range(1,11))
	#gridG=list(range(1,n_features+1))
	#gridB=[50,100,150,200]

	# PUT THE GENERATED GRIDS INTO A PYTHON DICTIONARY 
	param_grid = {'max_depth': gridD, 'max_features': gridG, 'n_estimators': gridB}

	# READ THE NUMBER OF CV-FOLDS "n_folds" FROM STATA
	n_folds=int(Macro.getLocal("n_folds"))

	# INSTANTIATE THE GRID
	grid = GridSearchCV(model, param_grid, cv=n_folds, scoring='explained_variance', return_train_score=True)

	# FIT THE GRID
	grid.fit(X, y)

	# VIEW THE RESULTS 
	CV_RES=pd.DataFrame(grid.cv_results_)[['mean_train_score','mean_test_score','std_test_score']]
	D=Macro.getLocal("cross_validation") 
	D=D+".dta"
	CV_RES.to_stata(D)

	# PUT OPTIMAL PARAMETER(S) INTO STATA SCALAR(S)
	params_values=list(grid.best_params_.values()) 

	# GET THE VALUE "opt_max_depth" AND PUT IT INTO A STATA SCALAR "OPT_MAX_DEPTH"
	opt_max_depth=grid.best_params_.get('max_depth')
	Scalar.setValue('OPT_MAX_DEPTH',opt_max_depth,vtype='visible')

	# GET THE VALUE "opt_max_features" AND PUT IT INTO A STATA SCALAR "OPT_MAX_FEATURES"
	opt_max_features=grid.best_params_.get('max_features')
	Scalar.setValue('OPT_MAX_FEATURES',opt_max_features, vtype='visible')
	
	# GET THE VALUE "opt_n_estimators" AND PUT IT INTO A STATA SCALAR "OPT_N_ESTIMATORS"
	opt_n_estimators=grid.best_params_.get('n_estimators')
	Scalar.setValue('OPT_N_ESTIMATORS',opt_n_estimators, vtype='visible')

	# TRAIN YOUR MODEL USING ALL DATA AND THE BEST KNOWN PARAMETERS
	model = RandomForestRegressor(max_depth=opt_max_depth, 
									n_estimators=opt_n_estimators, 
									max_features=opt_max_features, 
									random_state=R)

	# FIT THE MODEL
	model.fit(X, y)

	# MAKE IN-SAMPLE PREDICTION FOR y
	y_hat = model.predict(X)
	
	# PUT IN-SAMPLE PREDICTION of y IN A DATA FRAME
	in_sample = pd.DataFrame(y_hat)
	
	# PUT IN-SAMPLE PREDICTION INTO STATA
	D=Macro.getLocal("_____in_prediction") 
	D=D+".dta"
	in_sample.to_stata(D)
	
	# MAKE OUT-OF-SAMPLE PREDICTION FOR y USING A PREPARED DATASET
	D=Macro.getLocal("_____out_sample_x") 
	D=D+".dta"
	Xnew = pd.read_stata(D)
	ynew = model.predict(Xnew)

	# PUT OUT-OF-SAMPLE PREDICTION FOR y INTO A DATA FRAME
	Ynew = pd.DataFrame(ynew)

	# GENERATE A DATAFRAME 'OUT'
	OUT = pd.DataFrame(Ynew)
					
	# PUT "OUT" AS STATA DATASET
	# (NOTE: the first column is the prediction "y_hat")
	D=Macro.getLocal("_____out_prediction") 
	D=D+".dta"
	OUT.to_stata(D)
	
	# PRINT GRID SEARCH RESULTS
	ALL_CV_RES=pd.DataFrame(grid.cv_results_)[['param_max_depth','param_max_features','param_n_estimators','mean_train_score','mean_test_score']]
	ALL_CV_RES.columns = ['Tree depth', 'N. of splitting features', 'N. of trees','Train accuracy', 'Test accuracy']
	ALL_CV_RES['Index'] = ALL_CV_RES.index
	column_names = ['Index','Tree depth', 'N. of splitting features','N. of trees','Train accuracy','Test accuracy']
	ALL_CV_RES = ALL_CV_RES.reindex(columns=column_names)
	print("=====================================================================================")
	print(" Results of cross-validation grid search")
	print("=====================================================================================")
	print(ALL_CV_RES.to_string(index=False))
	print("=====================================================================================")
################################################################################

################################################################################
#! "r_neuralnet()": Neural network regression with CV 
#! Author: Giovanni Cerulli
#! Version: 7
#! Date: 02/05/2022
################################################################################
def r_neuralnet():
	# IMPORT NEEDED PACKAGES
	from sklearn.neural_network import MLPRegressor
	from sklearn.model_selection import GridSearchCV
	from sfi import Macro, Scalar , Matrix
	from sfi import Data , SFIToolkit
	import numpy as np
	import pandas as pd
	import os

	# SET THE DIRECTORY
	dir=Macro.getLocal("dir")
	os.chdir(dir)

	# SET THE TRAIN/TEST DATASET AND THE NEW-INSTANCES-DATASET
	dataset=Macro.getLocal("data_fitting")

	# LOAD A STATA DATASET LOCATED INTO THE DIRECTORY AS PANDAS DATAFRAME
	df = pd.read_stata(dataset,convert_categoricals=False)

	# DEFINE y THE TARGET VARIABLE
	y=df.iloc[:,0]

	# DEFINE X THE FEATURES
	X=df.iloc[:,1::]

	# READ THE "SEED" FROM STATA
	R=int(Macro.getLocal("seed"))

	# ESTIMATE A "neuralnet" AT GIVEN PARAMETERS (JUST TO TRY IF IT WORKS)
	model = MLPRegressor(solver='lbfgs', alpha=1e-5,hidden_layer_sizes=(5, 5), random_state=R)

	# DEFINE THE PARAMETER VALUES THAT SHOULD BE SEARCHED FOR CROSS-VALIDATION
	# 1. "NUMBER OF NEURONS FOR LAYER 1" 
	# 2. "NUMBER OF NEURONS FOR LAYER 2" 
	# 3. "L2 PENALIZIATION PARAMETER"
	# 4. "RANDOM SEED" 

	# CREATE A PARAMETER GRID AS A 2D "LIST" FOR NEURONS-LAYER-1 AND NEURONS-LAYER-2
	
	_M = Matrix.get("mat_n_neurons_l1")
	gridL1=_M[0]
	gridL1 = [int(x) for x in gridL1]
	
	_M = Matrix.get("mat_n_neurons_l2")
	gridL2=_M[0]
	gridL2 = [int(x) for x in gridL2]
	
	grid=[]
	for i in gridL1:
	   for j in gridL2:
	 	 g=(i,j)
	 	 grid.append(g)
	
	# GENERATE THE GRID (JUST ONE NUMBER) FOR THE "RANDOM SEED"	
	gridR=[1]
		
	# GRID FOR "alpha"
	_M = Matrix.get("mat_alpha")
	grid_alpha=_M[0]
		
	# PUT THE GENERATED GRIDS INTO A PYTHON DICTIONARY 
	param_grid={'hidden_layer_sizes': grid , 'random_state':gridR, 'alpha': grid_alpha}

	# READ THE NUMBER OF CV-FOLDS "n_folds" FROM STATA
	n_folds=int(Macro.getLocal("n_folds"))

	# INSTANTIATE THE GRID
	grid = GridSearchCV(model, param_grid, cv=n_folds, scoring='explained_variance', return_train_score=True)

	# FIT THE GRID
	grid.fit(X, y)

	# VIEW THE RESULTS 
	CV_RES=pd.DataFrame(grid.cv_results_)[['mean_train_score','mean_test_score','std_test_score']]
	D=Macro.getLocal("cross_validation") 
	D=D+".dta"
	CV_RES.to_stata(D)

	# PUT THE BEST PARAMETERS INTO STATA SCALARS
	opt_nn=grid.best_params_.get('hidden_layer_sizes')
	opt_neurons1=opt_nn[0]
	opt_neurons2=opt_nn[1]
	Scalar.setValue('OPT_NEURONS_L_1',opt_neurons1,vtype='visible')
	Scalar.setValue('OPT_NEURONS_L_2',opt_neurons2,vtype='visible')
	opt_alpha=grid.best_params_.get('alpha')
	Scalar.setValue('OPT_ALPHA',opt_alpha,vtype='visible')

	# TRAIN YOUR MODEL USING ALL DATA AND THE BEST KNOWN PARAMETERS
	model=MLPRegressor(solver='lbfgs', hidden_layer_sizes=opt_nn, alpha=opt_alpha , random_state=R)

	# FIT THE MODEL
	model.fit(X, y)

	# MAKE IN-SAMPLE PREDICTION FOR y
	y_hat = model.predict(X)
	
	# PUT IN-SAMPLE PREDICTION of y IN A DATA FRAME
	in_sample = pd.DataFrame(y_hat)
	
	# PUT IN-SAMPLE PREDICTION INTO STATA
	D=Macro.getLocal("_____in_prediction") 
	D=D+".dta"
	in_sample.to_stata(D)
	
	# MAKE OUT-OF-SAMPLE PREDICTION FOR y USING A PREPARED DATASET
	D=Macro.getLocal("_____out_sample_x") 
	D=D+".dta"
	Xnew = pd.read_stata(D)
	ynew = model.predict(Xnew)

	# PUT OUT-OF-SAMPLE PREDICTION FOR y INTO A DATA FRAME
	Ynew = pd.DataFrame(ynew)

	# GENERATE A DATAFRAME 'OUT'
	OUT = pd.DataFrame(Ynew)
					
	# PUT "OUT" AS STATA DATASET
	# (NOTE: the first column is the prediction "y_hat")
	D=Macro.getLocal("_____out_prediction") 
	D=D+".dta"
	OUT.to_stata(D)
		
	# PRINT GRID SEARCH RESULTS
	ALL_CV_RES=pd.DataFrame(grid.cv_results_)[['param_hidden_layer_sizes','param_alpha','mean_train_score','mean_test_score']]
	ALL_CV_RES.columns = ['(N. of neurons in L1, N. of neurons in L2)','Alpha','Train accuracy', 'Test accuracy']
	ALL_CV_RES['Index'] = ALL_CV_RES.index
	column_names = ['Index','(N. of neurons in L1, N. of neurons in L2)','Alpha','Train accuracy','Test accuracy']
	ALL_CV_RES = ALL_CV_RES.reindex(columns=column_names)
	print("======================================================================================")
	print(" Results of cross-validation grid search")
	print("======================================================================================")
	print(ALL_CV_RES.to_string(index=False))
	print("======================================================================================")
################################################################################

################################################################################
#! "r_nearestneighbor()": Nearest neighbor regression with CV 
#! Author: Giovanni Cerulli
#! Version: 7
#! Date: 02/05/2022
################################################################################
def r_nearestneighbor():
	# IMPORT NEEDED PACKAGES
	from sklearn.neighbors import KNeighborsRegressor
	from sklearn.model_selection import GridSearchCV
	from sfi import Macro, Scalar , Matrix
	from sfi import Data , SFIToolkit
	import numpy as np
	import pandas as pd
	import os

	# SET THE DIRECTORY
	dir=Macro.getLocal("dir")
	os.chdir(dir)

	# SET THE TRAIN/TEST DATASET AND THE NEW-INSTANCES-DATASET
	dataset=Macro.getLocal("data_fitting")

	# LOAD A STATA DATASET LOCATED INTO THE DIRECTORY AS PANDAS DATAFRAME
	df = pd.read_stata(dataset,convert_categoricals=False)

	# DEFINE y THE TARGET VARIABLE
	y=df.iloc[:,0]

	# DEFINE X THE FEATURES
	X=df.iloc[:,1::]

	# READ THE "SEED" FROM STATA
	R=int(Macro.getLocal("seed"))

	# INITIALIZE a KNN (with the n_neighbors parameter=5)
	model = KNeighborsRegressor(n_neighbors=5)

	# DEFINE THE PARAMETER VALUES THAT SHOULD BE SEARCHED
	# k_range = list(range(1, 31))
	nn = Matrix.get("mat_n_neighbor")
	k_range=nn[0]
	k_range = [int(x) for x in k_range]
	
	weight_options = ['uniform', 'distance']

	# CREATE A PARAMETER GRID: MAP THE PARAMETER NAMES TO THE VALUES THAT SHOULD BE SEARCHED
	param_grid = dict(n_neighbors=k_range, weights=weight_options)

	# READ THE NUMBER OF CV-FOLDS "n_folds" FROM STATA
	n_folds=int(Macro.getLocal("n_folds"))

	# INSTANTIATE THE GRID
	grid = GridSearchCV(model, param_grid, cv=n_folds, scoring='explained_variance', return_train_score=True)

	# FIT THE GRID
	grid.fit(X, y)

	# VIEW THE RESULTS 
	CV_RES=pd.DataFrame(grid.cv_results_)[['mean_train_score','mean_test_score','std_test_score']]
	D=Macro.getLocal("cross_validation") 
	D=D+".dta"
	CV_RES.to_stata(D)

	# PUT "OPT_LEAVES" INTO A STATA SCALAR
	params_values=list(grid.best_params_.values()) 

	# STORE THE BEST NUMBER OF NEIGHBORS INTO A STATA SCALAR
	opt_nn=grid.best_params_.get('n_neighbors')
	Scalar.setValue('OPT_NN',opt_nn,vtype='visible')

	# STORE THE BEST WEIGHT-TYPE INTO A STATA SCALAR
	opt_weight=grid.best_params_.get('weights')
	Macro.setGlobal('OPT_WEIGHT',opt_weight, vtype='visible')

	# TRAIN YOUR MODEL USING ALL DATA AND THE BEST KNOWN PARAMETERS
	model=KNeighborsRegressor(n_neighbors=opt_nn, weights=opt_weight)

	# FIT THE MODEL
	model.fit(X, y)

	# MAKE IN-SAMPLE PREDICTION FOR y
	y_hat = model.predict(X)
	
	# PUT IN-SAMPLE PREDICTION of y IN A DATA FRAME
	in_sample = pd.DataFrame(y_hat)
	
	# PUT IN-SAMPLE PREDICTION INTO STATA
	D=Macro.getLocal("_____in_prediction") 
	D=D+".dta"
	in_sample.to_stata(D)
	
	# MAKE OUT-OF-SAMPLE PREDICTION FOR y USING A PREPARED DATASET
	D=Macro.getLocal("_____out_sample_x") 
	D=D+".dta"
	Xnew = pd.read_stata(D)
	ynew = model.predict(Xnew)

	# PUT OUT-OF-SAMPLE PREDICTION FOR y INTO A DATA FRAME
	Ynew = pd.DataFrame(ynew)

	# GENERATE A DATAFRAME 'OUT'
	OUT = pd.DataFrame(Ynew)
					
	# PUT "OUT" AS STATA DATASET
	# (NOTE: the first column is the prediction "y_hat")
	D=Macro.getLocal("_____out_prediction") 
	D=D+".dta"
	OUT.to_stata(D)
		
	# PRINT GRID SEARCH RESULTS
	ALL_CV_RES=pd.DataFrame(grid.cv_results_)[['param_n_neighbors','param_weights','mean_train_score','mean_test_score']]
	ALL_CV_RES.columns = ['N. of nearest neighbors','Kernel','Train accuracy', 'Test accuracy']
	ALL_CV_RES['Index'] = ALL_CV_RES.index
	column_names = ['Index','N. of nearest neighbors','Kernel','Train accuracy', 'Test accuracy']
	ALL_CV_RES = ALL_CV_RES.reindex(columns=column_names)
	print("=======================================================================")
	print(" Results of cross-validation grid search")
	print("=======================================================================")
	print(ALL_CV_RES.to_string(index=False))
	print("=======================================================================")
################################################################################


################################################################################
#! "r_boost()": Boosting regression with CV
#! Author: Giovanni Cerulli
#! Version: 7
#! Date: 02/05/2022
################################################################################
def r_boost():
	# IMPORT NEEDED PACKAGES
	from sklearn.ensemble import GradientBoostingRegressor
	from sklearn.model_selection import GridSearchCV
	from sfi import Macro, Scalar , Matrix
	from sfi import Data , SFIToolkit
	import numpy as np
	import pandas as pd
	import os

	# SET THE DIRECTORY
	dir=Macro.getLocal("dir")
	os.chdir(dir)

	# SET THE TRAIN/TEST DATASET AND THE NEW-INSTANCES-DATASET
	dataset=Macro.getLocal("data_fitting")

	# LOAD A STATA DATASET LOCATED INTO THE DIRECTORY AS PANDAS DATAFRAME
	df = pd.read_stata(dataset,convert_categoricals=False)

	# DEFINE y THE TARGET VARIABLE
	y=df.iloc[:,0]

	# DEFINE X THE FEATURES
	X=df.iloc[:,1::]

	# READ THE "SEED" FROM STATA
	R=int(Macro.getLocal("seed"))

	# ESTIMATE A "ABC" AT GIVEN PARAMETERS (JUST TO TRY IF IT WORKS)
	model = GradientBoostingRegressor(learning_rate=0.1, n_estimators=100, random_state=R)

	# ABC "CROSS-VALIDATION"
	# WE CROSS-VALIDATE OVER TWO PARAMETERS:
	# 1. "D = learning_rate"
	# 2. "G = n_estimators"
    # 3. "H = tree depth" (i.e., number of layers of the tree)
	
	# GENERATE THE TWO PARAMETERS' GRID AS "LISTS"
	# GRID FOR "learning_rate"
	# gridD=[0.001,0.005,0.01,0.05,0.1,0.20]
	# GRID FOR "n_estimators"
	# gridG=list(range(1,21))
	# GRID FOR "max_depth"
	# gridH=list(range(1,11))
	
	_M = Matrix.get("mat_learning_rate")
	gridD=_M[0]
	
	_M = Matrix.get("mat_n_estmators")
	gridG=_M[0]
	gridG = [int(x) for x in gridG]
	
	_M = Matrix.get("mat_max_depth")
	gridH=_M[0]
	
	# PUT THE GENERATED GRIDS INTO A PYTHON DICTIONARY 
	param_grid = {'learning_rate': gridD, 'n_estimators': gridG, 'max_depth': gridH}

	# READ THE NUMBER OF CV-FOLDS "n_folds" FROM STATA
	n_folds=int(Macro.getLocal("n_folds"))

	# INSTANTIATE THE GRID
	grid = GridSearchCV(model, param_grid, cv=n_folds, scoring='explained_variance', return_train_score=True)

	# FIT THE GRID
	grid.fit(X, y)

	# VIEW THE RESULTS 
	CV_RES=pd.DataFrame(grid.cv_results_)[['mean_train_score','mean_test_score','std_test_score']]
	D=Macro.getLocal("cross_validation") 
	D=D+".dta"
	CV_RES.to_stata(D)

	# PUT OPTIMAL PARAMETER(S) INTO STATA SCALAR(S)
	params_values=list(grid.best_params_.values()) 
	Scalar.setValue('OPT_LEARNING_RATE',params_values[0],vtype='visible')
	Scalar.setValue('OPT_N_ESTIMATORS',params_values[1],vtype='visible')
	Scalar.setValue('OPT_MAX_DEPTH',params_values[2],vtype='visible')

	# GET THE VALUE "opt_learning_rate" AND PUT IT INTO A STATA SCALAR "opt_n_estimators"
	opt_learning_rate=grid.best_params_.get('learning_rate')
	opt_n_estimators=grid.best_params_.get('n_estimators')
	opt_max_depth=grid.best_params_.get('max_depth')

	# TRAIN YOUR MODEL USING ALL DATA AND THE BEST KNOWN PARAMETERS
	model = GradientBoostingRegressor(learning_rate=opt_learning_rate, 
									  n_estimators=opt_n_estimators,
									  max_depth=opt_max_depth,
									  random_state=R)

	# FIT THE MODEL
	model.fit(X, y)

	# MAKE IN-SAMPLE PREDICTION FOR y
	y_hat = model.predict(X)
	
	# PUT IN-SAMPLE PREDICTION of y IN A DATA FRAME
	in_sample = pd.DataFrame(y_hat)
	
	# PUT IN-SAMPLE PREDICTION INTO STATA
	D=Macro.getLocal("_____in_prediction") 
	D=D+".dta"
	in_sample.to_stata(D)
	
	# MAKE OUT-OF-SAMPLE PREDICTION FOR y USING A PREPARED DATASET
	D=Macro.getLocal("_____out_sample_x") 
	D=D+".dta"
	Xnew = pd.read_stata(D)
	ynew = model.predict(Xnew)

	# PUT OUT-OF-SAMPLE PREDICTION FOR y INTO A DATA FRAME
	Ynew = pd.DataFrame(ynew)

	# GENERATE A DATAFRAME 'OUT'
	OUT = pd.DataFrame(Ynew)
					
	# PUT "OUT" AS STATA DATASET
	# (NOTE: the first column is the prediction "y_hat")
	D=Macro.getLocal("_____out_prediction") 
	D=D+".dta"
	OUT.to_stata(D)
		
	# PRINT GRID SEARCH RESULTS
	ALL_CV_RES=pd.DataFrame(grid.cv_results_)[['param_learning_rate','param_n_estimators','param_max_depth','mean_train_score','mean_test_score']]
	ALL_CV_RES.columns = ['Learning rate', 'N. of trees', 'Tree depth','Train accuracy', 'Test accuracy']
	ALL_CV_RES['Index'] = ALL_CV_RES.index
	column_names = ['Index','Learning rate','N. of trees','Tree depth','Train accuracy','Test accuracy']
	ALL_CV_RES = ALL_CV_RES.reindex(columns=column_names)
	print("==========================================================================")
	print(" Results of cross-validation grid search")
	print("==========================================================================")
	print(ALL_CV_RES.to_string(index=False))
	print("==========================================================================")
################################################################################


################################################################################
#! "r_ols()": OLS with CV 
#! Author: Giovanni Cerulli
#! Version: 7
#! Date: 02/05/2022
################################################################################
def r_ols():
	# IMPORT NEEDED PACKAGES
	from sklearn.linear_model import ElasticNet
	from sklearn.model_selection import GridSearchCV
	from sfi import Macro, Scalar
	from sfi import Data , SFIToolkit
	import numpy as np
	import pandas as pd
	import os

	# SET THE DIRECTORY
	dir=Macro.getLocal("dir")
	os.chdir(dir)

	# SET THE TRAIN/TEST DATASET AND THE NEW-INSTANCES-DATASET
	dataset=Macro.getLocal("data_fitting")

	# LOAD A STATA DATASET LOCATED INTO THE DIRECTORY AS PANDAS DATAFRAME
	df = pd.read_stata(dataset,convert_categoricals=False)

	# DEFINE y THE TARGET VARIABLE
	y=df.iloc[:,0]

	# DEFINE X THE FEATURES
	X=df.iloc[:,1::]

	# INITIALIZE AN ELATIC NET
	model = ElasticNet()

	# "CROSS-VALIDATION" FOR "L1_RATIO" ("C") AND "ALFA" BY PRODUCING A "GRID SEARCH"
	# GENERATE THE TWO PARAMETERS' GRID AS A "LIST"
	gridC=(1,1,1)
	gridG=(0,0,0)

	# PUT THE GENERATED GRIDS INTO A PYTHON DICTIONARY 
	param_grid = {'l1_ratio': gridC, 'alpha': gridG}

	# READ THE NUMBER OF CV-FOLDS "n_folds" FROM STATA
	n_folds=int(Macro.getLocal("n_folds"))

	# INSTANTIATE THE GRID
	grid = GridSearchCV(model, param_grid, cv=n_folds, scoring='explained_variance', return_train_score=True)

	# FIT THE GRID
	grid.fit(X, y)

	# VIEW THE RESULTS 
	CV_RES=pd.DataFrame(grid.cv_results_)[['mean_train_score','mean_test_score','std_test_score']]
	D=Macro.getLocal("cross_validation") 
	D=D+".dta"
	CV_RES.to_stata(D)

	params_values=list(grid.best_params_.values()) 
	Scalar.setValue('OPT_ALPHA',params_values[0],vtype='visible')
	Scalar.setValue('OPT_L1_RATIO',params_values[1],vtype='visible')

	# GET THE VALUE "opt_c" AND PUT IT INTO A STATA SCALAR "OPT_C"
	opt_c=grid.best_params_.get('l1_ratio')

	# GET THE VALUE "opt_gamma" AND PUT IT INTO A STATA SCALAR "OPT_GAMMA"
	opt_gamma=grid.best_params_.get('alpha')

	# TRAIN YOUR MODEL USING ALL DATA AND THE BEST KNOWN PARAMETERS
	model = ElasticNet(l1_ratio=opt_c, alpha=opt_gamma)

	# FIT THE MODEL
	model.fit(X, y)

	# MAKE IN-SAMPLE PREDICTION FOR y
	y_hat = model.predict(X)
	
	# PUT IN-SAMPLE PREDICTION of y IN A DATA FRAME
	in_sample = pd.DataFrame(y_hat)
	
	# PUT IN-SAMPLE PREDICTION INTO STATA
	D=Macro.getLocal("_____in_prediction") 
	D=D+".dta"
	in_sample.to_stata(D)
	
	# MAKE OUT-OF-SAMPLE PREDICTION FOR y USING A PREPARED DATASET
	D=Macro.getLocal("_____out_sample_x") 
	D=D+".dta"
	Xnew = pd.read_stata(D)
	ynew = model.predict(Xnew)

	# PUT OUT-OF-SAMPLE PREDICTION FOR y INTO A DATA FRAME
	Ynew = pd.DataFrame(ynew)

	# GENERATE A DATAFRAME 'OUT'
	OUT = pd.DataFrame(Ynew)
					
	# PUT "OUT" AS STATA DATASET
	# (NOTE: the first column is the prediction "y_hat")
	D=Macro.getLocal("_____out_prediction") 
	D=D+".dta"
	OUT.to_stata(D)
################################################################################
end











