********************************************************************************
*! "c_ml_stata_default"
*! Author: Giovanni Cerulli
*! Version: 4
*! Date: 04 March 2022
********************************************************************************


********************************************************************************
* Display output for "c_tree"
********************************************************************************
cap program drop display_output_c_tree
program display_output_c_tree
syntax , [prediction] 

noi di "{hline 80}"
noi di in gr "{bf:Learner: Tree classification}"
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

noi di in gr "{ul:Parameters}"
di " "
noi di "Tree depth = largest tree possible"
noi di "{hline 80}"

if "`prediction'"!=""{
di " "
noi di in gr "{ul:Validation results}"
di " "
noi di in gr "CER = classification error rate" _continue
noi di in gr _col(45) "Training CER = " e(Train_err)
noi di in gr "Testing CER = " e(Test_err)
noi di " "
noi di "{hline 80}"
}
end 
********************************************************************************
*
********************************************************************************
* Display output for "c_svm"
********************************************************************************
cap program drop display_output_c_svm
program display_output_c_svm
syntax , [prediction] 

noi di "{hline 80}"
noi di in gr "{bf:Learner: Support Vector Machine classification}"
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

noi di in gr "{ul:Parameters}"
di " "
noi di "C parameter = 1"
noi di "GAMMA parameter = 1/(n_features * Var(X))"
noi di "{hline 80}"

if "`prediction'"!=""{
di " "
noi di in gr "{ul:Validation results}"
di " "
noi di in gr "CER = classification error rate" _continue
noi di in gr _col(45) "Training CER = " e(Train_err)
noi di in gr "Testing CER = " e(Test_err)
noi di " "
noi di "{hline 80}"
}
end 
********************************************************************************
*
********************************************************************************
* Display output for "c_randomforest"
********************************************************************************
cap program drop display_output_c_randomforest
program display_output_c_randomforest
syntax , [prediction] 

noi di "{hline 80}"
noi di in gr "{bf:Learner: Random Forest classification}"
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

noi di in gr "{ul:Parameters}"
di " "
noi di "Tree depth = largest tree possible"
noi di "N. of splitting features = N. of features"
noi di "{hline 80}"

if "`prediction'"!=""{
di " "
noi di in gr "{ul:Validation results}"
di " "
noi di in gr "CER = classification error rate" _continue
noi di in gr _col(45) "Training CER = " e(Train_err)
noi di in gr "Testing CER = " e(Test_err)
noi di " "
noi di "{hline 80}"
}
end 
********************************************************************************
*
********************************************************************************
* Display output for "c_neuralnet"
********************************************************************************
cap program drop display_output_c_neuralnet
program display_output_c_neuralnet
syntax , [prediction] 

noi di "{hline 80}"
noi di in gr "{bf:Learner: Neural Network classification}"
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

noi di in gr "{ul:Parameters}"
di " "
noi di "N. of neurons in layer 1 = 100"
noi di "N. of neurons in layer 2 = 0"
noi di "{hline 80}"

if "`prediction'"!=""{
di " "
noi di in gr "{ul:Validation results}"
di " "
noi di in gr "CER = classification error rate" _continue
noi di in gr _col(45) "Training CER = " e(Train_err)
noi di in gr "Testing CER = " e(Test_err)
noi di " "
noi di "{hline 80}"
}
end 
********************************************************************************
*
********************************************************************************
* Display output for "c_nearestneighbor"
********************************************************************************
cap program drop display_output_c_nearestneighbor
program display_output_c_nearestneighbor
syntax , [prediction] 

noi di "{hline 80}"
noi di in gr "{bf:Learner: Nearest Neighbor classification}"
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

noi di in gr "{ul:Parameters}"
di " "
noi di "N. of nearest neighbors = 5"
noi di "Kernel function = uniform"
noi di "{hline 80}"

if "`prediction'"!=""{
di " "
noi di in gr "{ul:Validation results}"
di " "
noi di in gr "CER = classification error rate" _continue
noi di in gr _col(45) "Training CER = " e(Train_err)
noi di in gr "Testing CER = " e(Test_err)
noi di " "
noi di "{hline 80}"
}
end 
********************************************************************************
*
********************************************************************************
* Display output for "c_boost"
********************************************************************************
cap program drop display_output_c_boost
program display_output_c_boost
syntax , [prediction] 

noi di "{hline 80}"
noi di in gr "{bf:Learner: Boosting classification}"
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

noi di in gr "{ul:Parameters}"
di " "
noi di "Learning rate = 1"
noi di "N. of trees = 50"
noi di "{hline 80}"

if "`prediction'"!=""{
di " "
noi di in gr "{ul:Validation results}"
di " "
noi di in gr "CER = classification error rate" _continue
noi di in gr _col(45) "Training CER = " e(Train_err)
noi di in gr "Testing CER = " e(Test_err)
noi di " "
noi di "{hline 80}"
}
end 
********************************************************************************
*
********************************************************************************
* Display output for "c_rmn"
********************************************************************************
cap program drop display_output_c_rmn
program display_output_c_rmn
syntax , [prediction] 

noi di "{hline 80}"
noi di in gr "{bf:Learner: Regularized Multinomial classification}"
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


noi di in gr "{ul:Parameters}"
di " "
noi di "Penalization parameter = 1"
noi di "Elastic parameter = 0.5"
noi di "{hline 80}"


if "`prediction'"!=""{
di " "
noi di in gr "{ul:Validation results}"
di " "
noi di in gr "CER = classification error rate" _continue
noi di in gr _col(45) "Training CER = " e(Train_err)
noi di in gr "Testing CER = " e(Test_err)
noi di " "
noi di "{hline 80}"
}
end 
********************************************************************************
*
********************************************************************************
* Display output for "c_naivebayes"
********************************************************************************
cap program drop display_output_c_naivebayes
program display_output_c_naivebayes
syntax , [prediction] 

noi di "{hline 80}"
noi di in gr "{bf:Learner: Naive Bayes classification}"
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

if "`prediction'"!=""{
di " "
noi di in gr "{ul:Validation results}"
di " "
noi di in gr "CER = classification error rate" _continue
noi di in gr _col(45) "Training CER = " e(Train_err)
noi di in gr "Testing CER = " e(Test_err)
noi di " "
noi di "{hline 80}"
}
end 
********************************************************************************


********************************************************************************
* Display output for "c_multinomial"
********************************************************************************
cap program drop display_output_c_multinomial
program display_output_c_multinomial
syntax , [prediction] 

noi di "{hline 80}"
noi di in gr "{bf:Learner: Multinomial classification}"
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


if "`prediction'"!=""{
di " "
noi di in gr "{ul:Validation results}"
di " "
noi di in gr "CER = classification error rate" _continue
noi di in gr _col(45) "Training CER = " e(Train_err)
noi di in gr "Testing CER = " e(Test_err)
noi di " "
noi di "{hline 80}"
}
end 
********************************************************************************

*
*
*

********************************************************************************
*! "c_ml_stata_default"
*! Author: Giovanni Cerulli
*! Version: 4
*! Date: 04 March 2022
********************************************************************************
program c_ml_stata_default , eclass
version 16
syntax varlist(numeric) [if] [in] , ///
mlmodel(string) ///
data_test(name) ///
seed(numlist max=1 integer) ///
[prediction(name)]
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
* CONFIRM THAT "y" IS AN INTEGER VARIABLE (INCLUDING "0")
********************************************************************************
cap confirm int variable `y'
if _rc {
	recast int `y' , force
}
********************************************************************************
* MARK THE SAMPLE TO USE
********************************************************************************
marksample touse
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
				  di in red "*******************************************************************************"	 	
                  di in red "WARNING: In your training set the target variable '`v'' is a string variable.  "
				  di in red "Please, make it numerical. As this is a classification setting,                "
				  di in red "please recode this variable so to take values [1,2,...,M] in a M-class setting."  
				  di in red "if it is binary, please recode it so to take values [1,2].                     "
				  di in red "*******************************************************************************"	 	
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
				  di in red "*******************************************************************************"
                  di in red "WARNING: In your testing set the target variable '`v'' is a string variable.   "
				  di in red "Please, make it numerical. As this is a classification setting,                "
				  di in red "please recode this variable so to take values [1,2,...,M] in a M-class setting."  
				  di in red "if it is binary, please recode it so to take values [1,2].                     "
				  di in red "*******************************************************************************"
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
*
********************************************************************************
* ESTIMATION PROCEDURE
********************************************************************************
* SAVE THE DATASET AS IT IS
tempfile data_fitting 
********************************************************************************
* USE "levelsof" FOR RENAMING PREDICTION PROBABILITIES LATER
********************************************************************************
qui: levelsof `y' , local(ylevels) clean 
********************************************************************************
* SAVE "data_fitting"
******************************************************************************** 
qui: save `data_fitting' , replace

di in red "=== Begin Python warnings ==========================================================================="

********************************************************************************
* PYTHON CODE - BEGIN 
********************************************************************************
if "`mlmodel'"=="multinomial"{
python: c_multinomial()
preserve
qui: use `_____in_prediction' , clear
if "`prediction'"!=""{
rename _0 `prediction' 
}
qui: save `_____in_prediction' , replace
restore
ereturn clear
}
********************************************************************************
else if "`mlmodel'"=="naivebayes"{
python: c_naivebayes()
preserve
qui: use `_____in_prediction' , clear
if "`prediction'"!=""{
rename _0 `prediction' 
}
qui: save `_____in_prediction' , replace
restore
ereturn clear
}
********************************************************************************
else if "`mlmodel'"=="regmult"{
python: c_rmn()
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
else if "`mlmodel'"=="boost"{
python: c_boost()
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
else if "`mlmodel'"=="nearestneighbor"{
python: c_nearestneighbor()
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
else if "`mlmodel'"=="neuralnet"{
python: c_neuralnet()
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
else if "`mlmodel'"=="randomforest"{
python: c_randomforest()
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
else if "`mlmodel'"=="svm"{
python: c_svm()
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
else if "`mlmodel'"=="tree"{
python: c_tree()
preserve
use `_____in_prediction' , clear
if "`prediction'"!=""{
rename _0 `prediction' 
}
qui: save `_____in_prediction' , replace
restore
ereturn clear
}
*
********************************************************************************
di in red "=== End Python warnings ============================================================================="
di _newline
di as text "=== Begin Stata output =============================================================================="
********************************************************************************
* PREDICTION
******************************************************************************** 
preserve
if "`prediction'"!=""{
qui: use `_____out_prediction' , clear
rename _0 `prediction' 
}
qui: save `_____out_prediction' , replace
restore
********************************************************************************
if "`prediction'"!=""{
********************************************************************************
* WARNING
********************************************************************************
capture confirm variable _train_index
if !_rc {
di _newline
di in red "*****************************************************************************"
di in red "WARNING: One of your variables in the dataset is named '_train_index'.        " 
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
save `_____out_sample_x_initial', replace
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
* Compute validation train-ERR (Error rate)
tempvar v_train_err 
gen `v_train_err'= (`y'!=`prediction') if _train_index=="train"
qui sum `v_train_err' 
ereturn scalar Train_err = r(mean)

* Compute validation test-ERR (Error rate)
tempvar v_test_err 
gen `v_test_err'= (`y'!=`prediction') if _train_index=="test"
qui sum `v_test_err' 
ereturn scalar Test_err = r(mean)
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
    display_output_c_tree 
	}
}
else if "`prediction'"!=""{
	if "`mlmodel'"=="tree"{
    display_output_c_tree , prediction	
	}
}
********************************************************************************
* Elasticnet
********************************************************************************
if "`prediction'"==""{
	if "`mlmodel'"=="elasticnet"{
    display_output_c_elasticnet 
	}
}
else if "`prediction'"!=""{
	if "`mlmodel'"=="elasticnet"{
    display_output_c_elasticnet , prediction	
	}
}
********************************************************************************
* SVM
********************************************************************************
if "`prediction'"==""{
	if "`mlmodel'"=="svm"{
    display_output_c_svm 
	}
}
else if "`prediction'"!=""{
	if "`mlmodel'"=="svm"{
    display_output_c_svm , prediction	
	}
}
********************************************************************************
* Random forests
********************************************************************************
if "`prediction'"==""{
	if "`mlmodel'"=="randomforest"{
    display_output_c_randomforest 
	}
}
else if "`prediction'"!=""{
	if "`mlmodel'"=="randomforest"{
    display_output_c_randomforest , prediction	
	}
}
********************************************************************************
* Neural network
********************************************************************************
if "`prediction'"==""{
	if "`mlmodel'"=="neuralnet"{
    display_output_c_neuralnet
	}
}
else if "`prediction'"!=""{
	if "`mlmodel'"=="neuralnet"{
    display_output_c_neuralnet , prediction	
	}
}
********************************************************************************
* Nearest Neighbor
********************************************************************************
if "`prediction'"==""{
	if "`mlmodel'"=="nearestneighbor"{
    display_output_c_nearestneighbor
	}
}
else if "`prediction'"!=""{
	if "`mlmodel'"=="nearestneighbor"{
    display_output_c_nearestneighbor , prediction	
	}
}
********************************************************************************
* Boosting
********************************************************************************
if "`prediction'"==""{
	if "`mlmodel'"=="boost"{
    display_output_c_boost
	}
}
else if "`prediction'"!=""{
	if "`mlmodel'"=="boost"{
    display_output_c_boost , prediction	
	}
}
********************************************************************************
* Regularized Multinomial
********************************************************************************
if "`prediction'"==""{
	if "`mlmodel'"=="regmult"{
    display_output_c_rmn
	}
}
else if "`prediction'"!=""{
	if "`mlmodel'"=="regmult"{
    display_output_c_rmn , prediction	
	}
}
********************************************************************************
* Naive Bayes
********************************************************************************
if "`prediction'"==""{
	if "`mlmodel'"=="naivebayes"{
    display_output_c_naivebayes
	}
}
else if "`prediction'"!=""{
	if "`mlmodel'"=="naivebayes"{
    display_output_c_naivebayes , prediction	
	}
}
********************************************************************************
* Multinomial
********************************************************************************
if "`prediction'"==""{
	if "`mlmodel'"=="multinomial"{
    display_output_c_multinomial
	}
}
else if "`prediction'"!=""{
	if "`mlmodel'"=="multinomial"{
    display_output_c_multinomial , prediction	
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
* RENAME PREDICTION PROBABILITIES
********************************************************************************
local i=1
foreach num of local ylevels{
	rename _`i' `prediction'_prob`num' 
	local i=`i'+1
}
********************************************************************************
end 
********************************************************************************

*
*
*

********************************************************************************
* PYTHON FUNCTIONS
********************************************************************************
*
python:

# ******************************************************************************
# * TITLE:  "DECISION TREE CLASSIFIER NO CROSS-VALIDATION" 
# * DATE:   09/11/2021
# * AUTHOR: GIOVANNI CERULLI
# *****************************************************************************
# * USE THE "scikit-learn" PYTHON PACKAGE, METHOD: "DecisionTreeClassifier()"
# *****************************************************************************
def c_tree():
	# IMPORT THE NEEDED PYTHON PACKAGES
	from sklearn.tree import DecisionTreeClassifier
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
	df = pd.read_stata(dataset)

	# DEFINE y THE TARGET VARIABLE
	y=df.iloc[:,0]

	# DEFINE X THE FEATURES
	X=df.iloc[:,1::]

	# READ THE "SEED" FROM STATA
	R=int(Macro.getLocal("seed"))

	# USING THE BEST PARAMETER TO MAKE PREDICTIONS
	# TRAIN YOUR MODEL USING ALL DATA AND THE BEST PARAMETERS
	model = DecisionTreeClassifier(random_state=R)

	# FIT THE MODEL
	model.fit(X, y)

	# MAKE IN-SAMPLE PREDICTION FOR y and prob, AND PUT IT INTO A DATAFRAME
	y_hat = model.predict(X)
	prob = model.predict_proba(X)

	# STACK THE PREDICTIONS
	in_sample=np.column_stack((y_hat,prob))
	in_sample = pd.DataFrame(in_sample)
					
	# GET RESULTS INTO STATA
	# (NOTE: the first column is the prediction "y_hat")
	
	D=Macro.getLocal("_____in_prediction") 
	D=D+".dta"
	in_sample.to_stata(D)

	# MAKE OUT-OF-SAMPLE "LABEL" PREDICTION FOR y USING A PREPARED DATASET
	D=Macro.getLocal("_____out_sample_x") 
	D=D+".dta"
	Xnew = pd.read_stata(D)
	ynew = model.predict(Xnew)

	# MAKE OUT-OF-SAMPLE "PROBABILITY" PREDICTION FOR y USING A PREPARED DATASET
	prob_new = model.predict_proba(Xnew)
	Prob_new  = pd.DataFrame(prob_new )

	# EXPORT LABEL PREDICTION FOR y INTO AN EXCEL FILE
	Ynew = pd.DataFrame(ynew)

	# MERGE LABEL AND PROBABILITY PREDICTION FOR y INTO AN EXCEL FILE
	# Use "numpy" to stack by column 'ynew' and 'prob_new'
	out=np.column_stack((ynew,prob_new))

	# GENERATE A DATAFRAME 'OUT' FROM THE "out" ARRAY
	OUT = pd.DataFrame(out)
					
	# PUT "OUT" INTO STATA
	# (NOTE: the first column is the prediction "y_hat")
	D=Macro.getLocal("_____out_prediction") 
	D=D+".dta"
	OUT.to_stata(D)

	
#******************************************************************************
# * TITLE:  "SUPPORT VECTOR MACHINE CLASSIFICATION USING CROSS-VALIDATION" 
# * DATE:   02/11/2021
# * AUTHOR: GIOVANNI CERULLI
# *****************************************************************************
# * USE THE "scikit-learn" PYTHON PACKAGE, METHOD: "svm.SVC()"
# *****************************************************************************
def c_svm():

	# IMPORT THE NEEDED PYTHON PACKAGES
	from sklearn import svm
	from sklearn.svm import SVC
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
	df = pd.read_stata(dataset)

	# DEFINE y THE TARGET VARIABLE
	y=df.iloc[:,0]

	# DEFINE X THE FEATURES
	X=df.iloc[:,1::]

	# READ THE "SEED" FROM STATA
	R=int(Macro.getLocal("seed"))

	# TRAIN YOUR MODEL USING ALL DATA
	model = svm.SVC(random_state=R, probability=True)

	# FIT THE MODEL
	model.fit(X, y)

	# MAKE IN-SAMPLE PREDICTION FOR y and prob, AND PUT IT INTO A DATAFRAME
	y_hat = model.predict(X)
	prob = model.predict_proba(X)

	# STACK THE PREDICTIONS
	in_sample=np.column_stack((y_hat,prob))
	in_sample = pd.DataFrame(in_sample)
					
	# GET RESULTS INTO STATA
	# (NOTE: the first column is the prediction "y_hat")
	D=Macro.getLocal("_____in_prediction") 
	D=D+".dta"
	in_sample.to_stata(D)

	# MAKE OUT-OF-SAMPLE "LABEL" PREDICTION FOR y USING A PREPARED DATASET
	D=Macro.getLocal("_____out_sample_x") 
	D=D+".dta"
	Xnew = pd.read_stata(D)
	ynew = model.predict(Xnew)

	# MAKE OUT-OF-SAMPLE "PROBABILITY" PREDICTION FOR y USING A PREPARED DATASET
	prob_new = model.predict_proba(Xnew)
	Prob_new  = pd.DataFrame(prob_new )

	# EXPORT LABEL PREDICTION FOR y INTO AN EXCEL FILE
	Ynew = pd.DataFrame(ynew)

	# MERGE LABEL AND PROBABILITY PREDICTION FOR y INTO AN EXCEL FILE
	# Use "numpy" to stack by column 'ynew' and 'prob_new'
	out=np.column_stack((ynew,prob_new))

	# GENERATE A DATAFRAME 'OUT' FROM THE "out" ARRAY
	OUT = pd.DataFrame(out)
					
	# PUT "OUT" INTO STATA
	# (NOTE: the first column is the prediction "y_hat")
	D=Macro.getLocal("_____out_prediction") 
	D=D+".dta"
	OUT.to_stata(D)


#******************************************************************************
# * TITLE:  "RANDOM FOREST CLASSIFICATION NO CROSS-VALIDATION" 
# * DATE:   02/11/2021
# * AUTHOR: GIOVANNI CERULLI
# *****************************************************************************
# * USE THE "scikit-learn" PYTHON PACKAGE, METHOD: "RandomForestClassifier()"
# *****************************************************************************
def c_randomforest():

	# IMPORT THE NEEDED PYTHON PACKAGES
	from sklearn.ensemble import RandomForestClassifier
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
	df = pd.read_stata(dataset)

	# DEFINE y THE TARGET VARIABLE
	y=df.iloc[:,0]

	# DEFINE X THE FEATURES
	X=df.iloc[:,1::]

	# COMPUTE THE NUMBER OF FEATURES 
	X = np.array(X)
	n_features=int(len(X[0]))

	# READ THE "SEED" FROM STATA
	R=int(Macro.getLocal("seed"))

	# USING THE BEST PARAMETERS TO MAKE PREDICTIONS
	# TRAIN YOUR MODEL USING ALL DATA AND THE BEST KNOWN PARAMETERS
	model = RandomForestClassifier(random_state=R)

	# FIT THE MODEL
	model.fit(X, y)

	# MAKE IN-SAMPLE PREDICTION FOR y and prob, AND PUT IT INTO A DATAFRAME
	y_hat = model.predict(X)
	prob = model.predict_proba(X)

	# STACK THE PREDICTIONS
	in_sample=np.column_stack((y_hat,prob))
	in_sample = pd.DataFrame(in_sample)
					
	# GET RESULTS INTO STATA
	# (NOTE: the first column is the prediction "y_hat")
	D=Macro.getLocal("_____in_prediction") 
	D=D+".dta"
	in_sample.to_stata(D)

	# MAKE OUT-OF-SAMPLE "LABEL" PREDICTION FOR y USING A PREPARED DATASET
	D=Macro.getLocal("_____out_sample_x") 
	D=D+".dta"
	Xnew = pd.read_stata(D)
	ynew = model.predict(Xnew)

	# MAKE OUT-OF-SAMPLE "PROBABILITY" PREDICTION FOR y USING A PREPARED DATASET
	prob_new = model.predict_proba(Xnew)
	Prob_new  = pd.DataFrame(prob_new )

	# EXPORT LABEL PREDICTION FOR y INTO AN EXCEL FILE
	Ynew = pd.DataFrame(ynew)

	# MERGE LABEL AND PROBABILITY PREDICTION FOR y INTO AN EXCEL FILE
	# Use "numpy" to stack by column 'ynew' and 'prob_new'
	out=np.column_stack((ynew,prob_new))

	# GENERATE A DATAFRAME 'OUT' FROM THE "out" ARRAY
	OUT = pd.DataFrame(out)
					
	# PUT "OUT" INTO STATA
	# (NOTE: the first column is the prediction "y_hat")
	D=Macro.getLocal("_____out_prediction") 
	D=D+".dta"
	OUT.to_stata(D)

#******************************************************************************
# * TITLE:  "NEURAL-NETWORK CLASSIFICATION NO CROSS-VALIDATION" 
# * DATE:   02/11/2021
# * AUTHOR: GIOVANNI CERULLI
# *****************************************************************************
# * USE THE "scikit-learn" PYTHON PACKAGE, METHOD: "MLPClassifier()"
# *****************************************************************************
def c_neuralnet():

	# IMPORT THE NEEDED PYTHON PACKAGES
	from sklearn.neural_network import MLPClassifier
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
	df = pd.read_stata(dataset)

	# DEFINE y THE TARGET VARIABLE
	y=df.iloc[:,0]

	# DEFINE X THE FEATURES
	X=df.iloc[:,1::]

	# READ THE "SEED" FROM STATA
	R=int(Macro.getLocal("seed"))

	# TRAIN YOUR MODEL USING ALL DATA 
	model = MLPClassifier(random_state=R)

	# FIT THE MODEL
	model.fit(X, y)

	# MAKE IN-SAMPLE PREDICTION FOR y and prob, AND PUT IT INTO A DATAFRAME
	y_hat = model.predict(X)
	prob = model.predict_proba(X)

	# STACK THE PREDICTIONS
	in_sample=np.column_stack((y_hat,prob))
	in_sample = pd.DataFrame(in_sample)
					
	# GET RESULTS INTO STATA
	# (NOTE: the first column is the prediction "y_hat")
	D=Macro.getLocal("_____in_prediction") 
	D=D+".dta"
	in_sample.to_stata(D)

	# MAKE OUT-OF-SAMPLE "LABEL" PREDICTION FOR y USING A PREPARED DATASET
	D=Macro.getLocal("_____out_sample_x") 
	D=D+".dta"
	Xnew = pd.read_stata(D)
	ynew = model.predict(Xnew)

	# MAKE OUT-OF-SAMPLE "PROBABILITY" PREDICTION FOR y USING A PREPARED DATASET
	prob_new = model.predict_proba(Xnew)
	Prob_new  = pd.DataFrame(prob_new )

	# EXPORT LABEL PREDICTION FOR y INTO AN EXCEL FILE
	Ynew = pd.DataFrame(ynew)

	# MERGE LABEL AND PROBABILITY PREDICTION FOR y INTO AN EXCEL FILE
	# Use "numpy" to stack by column 'ynew' and 'prob_new'
	out=np.column_stack((ynew,prob_new))

	# GENERATE A DATAFRAME 'OUT' FROM THE "out" ARRAY
	OUT = pd.DataFrame(out)
					
	# PUT "OUT" INTO STATA
	# (NOTE: the first column is the prediction "y_hat")
	D=Macro.getLocal("_____out_prediction") 
	D=D+".dta"
	OUT.to_stata(D)


#******************************************************************************
# * TITLE:  "NEAREST_NEIGHBOR, N0 CROSS-VALIDATION" 
# * DATE:   02/11/2021
# * AUTHOR: GIOVANNI CERULLI
# *****************************************************************************
# * USE THE "scikit-learn" PYTHON PACKAGE, METHOD: "KNeighborsClassifier()"
# *****************************************************************************
def c_nearestneighbor():

	# IMPORT THE NEEDED PYTHON PACKAGES
	from sklearn.neighbors import KNeighborsClassifier
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
	df = pd.read_stata(dataset)

	# DEFINE y THE TARGET VARIABLE
	y=df.iloc[:,0]

	# DEFINE X THE FEATURES
	X=df.iloc[:,1::]

	# READ THE "SEED" FROM STATA
	R=int(Macro.getLocal("seed"))

	# TRAIN YOUR MODEL USING ALL DATA AND THE BEST KNOWN PARAMETERS
	model = KNeighborsClassifier()

	# FIT THE MODEL
	model.fit(X, y)

	# MAKE IN-SAMPLE PREDICTION FOR y and prob, AND PUT IT INTO A DATAFRAME
	y_hat = model.predict(X)
	prob = model.predict_proba(X)

	# STACK THE PREDICTIONS
	in_sample=np.column_stack((y_hat,prob))
	in_sample = pd.DataFrame(in_sample)
					
	# GET RESULTS INTO STATA
	# (NOTE: the first column is the prediction "y_hat")
	D=Macro.getLocal("_____in_prediction") 
	D=D+".dta"
	in_sample.to_stata(D)

	# MAKE OUT-OF-SAMPLE "LABEL" PREDICTION FOR y USING A PREPARED DATASET
	D=Macro.getLocal("_____out_sample_x") 
	D=D+".dta"
	Xnew = pd.read_stata(D)
	ynew = model.predict(Xnew)

	# MAKE OUT-OF-SAMPLE "PROBABILITY" PREDICTION FOR y USING A PREPARED DATASET
	prob_new = model.predict_proba(Xnew)
	Prob_new  = pd.DataFrame(prob_new )

	# EXPORT LABEL PREDICTION FOR y INTO AN EXCEL FILE
	Ynew = pd.DataFrame(ynew)

	# MERGE LABEL AND PROBABILITY PREDICTION FOR y INTO AN EXCEL FILE
	# Use "numpy" to stack by column 'ynew' and 'prob_new'
	out=np.column_stack((ynew,prob_new))

	# GENERATE A DATAFRAME 'OUT' FROM THE "out" ARRAY
	OUT = pd.DataFrame(out)
					
	# PUT "OUT" INTO STATA
	# (NOTE: the first column is the prediction "y_hat")
	D=Macro.getLocal("_____out_prediction") 
	D=D+".dta"
	OUT.to_stata(D)

#******************************************************************************
# * TITLE:  "BOOSTING-TREE CLASSIFICATION NO CROSS-VALIDATION" 
# * DATE:   02/11/2021
# * AUTHOR: GIOVANNI CERULLI
# *****************************************************************************
# * USE THE "scikit-learn" PYTHON PACKAGE, METHOD: "AdaBoostClassifier()"
# *****************************************************************************
def c_boost():

	# IMPORT THE NEEDED PYTHON PACKAGES
	from sklearn.ensemble import AdaBoostClassifier
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
	df = pd.read_stata(dataset)

	# DEFINE y THE TARGET VARIABLE
	y=df.iloc[:,0]

	# DEFINE X THE FEATURES
	X=df.iloc[:,1::]

	# READ THE "SEED" FROM STATA
	R=int(Macro.getLocal("seed"))

	# USING THE BEST PARAMETERS TO MAKE PREDICTIONS
	# TRAIN YOUR MODEL USING ALL DATA AND THE BEST KNOWN PARAMETERS
	model = AdaBoostClassifier(random_state=R)

	# FIT THE MODEL
	model.fit(X, y)

	# MAKE IN-SAMPLE PREDICTION FOR y and prob, AND PUT IT INTO A DATAFRAME
	y_hat = model.predict(X)
	prob = model.predict_proba(X)

	# STACK THE PREDICTIONS
	in_sample=np.column_stack((y_hat,prob))
	in_sample = pd.DataFrame(in_sample)
					
	# GET RESULTS INTO STATA
	# (NOTE: the first column is the prediction "y_hat")
	D=Macro.getLocal("_____in_prediction") 
	D=D+".dta"
	in_sample.to_stata(D)

	# MAKE OUT-OF-SAMPLE "LABEL" PREDICTION FOR y USING A PREPARED DATASET
	D=Macro.getLocal("_____out_sample_x") 
	D=D+".dta"
	Xnew = pd.read_stata(D)
	ynew = model.predict(Xnew)

	# MAKE OUT-OF-SAMPLE "PROBABILITY" PREDICTION FOR y USING A PREPARED DATASET
	prob_new = model.predict_proba(Xnew)
	Prob_new  = pd.DataFrame(prob_new )

	# EXPORT LABEL PREDICTION FOR y INTO AN EXCEL FILE
	Ynew = pd.DataFrame(ynew)

	# MERGE LABEL AND PROBABILITY PREDICTION FOR y INTO AN EXCEL FILE
	# Use "numpy" to stack by column 'ynew' and 'prob_new'
	out=np.column_stack((ynew,prob_new))

	# GENERATE A DATAFRAME 'OUT' FROM THE "out" ARRAY
	OUT = pd.DataFrame(out)
					
	# PUT "OUT" INTO STATA
	# (NOTE: the first column is the prediction "y_hat")
	D=Macro.getLocal("_____out_prediction") 
	D=D+".dta"
	OUT.to_stata(D)

#******************************************************************************
# * TITLE:  "REGULARIZED MULTINOMIAL CLASSIFICATION NO CROSS-VALIDATION" 
# * DATE:   02/11/2021
# * AUTHOR: GIOVANNI CERULLI
# *****************************************************************************
# * USE THE "scikit-learn" PYTHON PACKAGE, METHOD: "LogisticRegression()"
# *****************************************************************************
def c_rmn():

	# IMPORT THE NEEDED PYTHON PACKAGES
	from sklearn.linear_model import LogisticRegression
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
	df = pd.read_stata(dataset)

	# DEFINE y THE TARGET VARIABLE
	y=df.iloc[:,0]

	# DEFINE X THE FEATURES
	X=df.iloc[:,1::]

	# READ THE "SEED" FROM STATA
	R=int(Macro.getLocal("seed"))

	# TRAIN YOUR MODEL USING ALL DATA
	model = LogisticRegression(l1_ratio=0.5)

	# FIT THE MODEL
	model.fit(X, y)

	# MAKE IN-SAMPLE PREDICTION FOR y and prob, AND PUT IT INTO A DATAFRAME
	y_hat = model.predict(X)
	prob = model.predict_proba(X)

	# STACK THE PREDICTIONS
	in_sample=np.column_stack((y_hat,prob))
	in_sample = pd.DataFrame(in_sample)
					
	# GET RESULTS INTO STATA
	# (NOTE: the first column is the prediction "y_hat")
	D=Macro.getLocal("_____in_prediction") 
	D=D+".dta"
	in_sample.to_stata(D)

	# MAKE OUT-OF-SAMPLE "LABEL" PREDICTION FOR y USING A PREPARED DATASET
	D=Macro.getLocal("_____out_sample_x") 
	D=D+".dta"
	Xnew = pd.read_stata(D)
	ynew = model.predict(Xnew)

	# MAKE OUT-OF-SAMPLE "PROBABILITY" PREDICTION FOR y USING A PREPARED DATASET
	prob_new = model.predict_proba(Xnew)
	Prob_new  = pd.DataFrame(prob_new )

	# EXPORT LABEL PREDICTION FOR y INTO AN EXCEL FILE
	Ynew = pd.DataFrame(ynew)

	# MERGE LABEL AND PROBABILITY PREDICTION FOR y INTO AN EXCEL FILE
	# Use "numpy" to stack by column 'ynew' and 'prob_new'
	out=np.column_stack((ynew,prob_new))

	# GENERATE A DATAFRAME 'OUT' FROM THE "out" ARRAY
	OUT = pd.DataFrame(out)
					
	# PUT "OUT" INTO STATA
	# (NOTE: the first column is the prediction "y_hat")
	D=Macro.getLocal("_____out_prediction") 
	D=D+".dta"
	OUT.to_stata(D)

#******************************************************************************
# * TITLE:  "NAIVE-BAYES CLASSIFICATION USING CROSS-VALIDATION" 
# * DATE:   02/11/2021
# * AUTHOR: GIOVANNI CERULLI
# *****************************************************************************
# * USE THE "scikit-learn" PYTHON PACKAGE, METHOD: "GaussianNB()"
# *****************************************************************************
def c_naivebayes():

	# IMPORT THE NEEDED PYTHON PACKAGES
	from sklearn.naive_bayes import GaussianNB
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
	df = pd.read_stata(dataset)

	# DEFINE y THE TARGET VARIABLE
	y=df.iloc[:,0]

	# DEFINE X THE FEATURES
	X=df.iloc[:,1::]

	# READ THE "SEED" FROM STATA
	R=int(Macro.getLocal("seed"))

	# TRAIN YOUR MODEL USING ALL DATA
	model=GaussianNB()

	# FIT THE MODEL
	model.fit(X, y)

	# MAKE IN-SAMPLE PREDICTION FOR y and prob, AND PUT IT INTO A DATAFRAME
	y_hat = model.predict(X)
	prob = model.predict_proba(X)

	# STACK THE PREDICTIONS
	in_sample=np.column_stack((y_hat,prob))
	in_sample = pd.DataFrame(in_sample)
					
	# GET RESULTS INTO STATA
	# (NOTE: the first column is the prediction "y_hat")
	D=Macro.getLocal("_____in_prediction") 
	D=D+".dta"
	in_sample.to_stata(D)

	# MAKE OUT-OF-SAMPLE "LABEL" PREDICTION FOR y USING A PREPARED DATASET
	D=Macro.getLocal("_____out_sample_x") 
	D=D+".dta"
	Xnew = pd.read_stata(D)
	ynew = model.predict(Xnew)

	# MAKE OUT-OF-SAMPLE "PROBABILITY" PREDICTION FOR y USING A PREPARED DATASET
	prob_new = model.predict_proba(Xnew)
	Prob_new  = pd.DataFrame(prob_new )

	# EXPORT LABEL PREDICTION FOR y INTO AN EXCEL FILE
	Ynew = pd.DataFrame(ynew)

	# MERGE LABEL AND PROBABILITY PREDICTION FOR y INTO AN EXCEL FILE
	# Use "numpy" to stack by column 'ynew' and 'prob_new'
	out=np.column_stack((ynew,prob_new))

	# GENERATE A DATAFRAME 'OUT' FROM THE "out" ARRAY
	OUT = pd.DataFrame(out)
					
	# PUT "OUT" INTO STATA
	# (NOTE: the first column is the prediction "y_hat")
	D=Macro.getLocal("_____out_prediction") 
	D=D+".dta"
	OUT.to_stata(D)
	
#******************************************************************************
# * TITLE:  "MULTINOMIAL CLASSIFICATION" 
# * DATE:   02/11/2021
# * AUTHOR: GIOVANNI CERULLI
# *****************************************************************************
# * USE THE "scikit-learn" PYTHON PACKAGE, METHOD: "LogisticRegression()"
# *****************************************************************************
def c_multinomial():

	# IMPORT THE NEEDED PYTHON PACKAGES
	from sklearn.linear_model import LogisticRegression
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

	# READ THE "SEED" FROM STATA
	R=int(Macro.getLocal("seed"))

	# TRAIN YOUR MODEL USING ALL DATA AND THE BEST PARAMETERS
	model = LogisticRegression(penalty='none')

	# FIT THE MODEL
	model.fit(X, y)

	# MAKE IN-SAMPLE PREDICTION FOR y and prob, AND PUT IT INTO A DATAFRAME
	y_hat = model.predict(X)
	prob = model.predict_proba(X)

	# STACK THE PREDICTIONS
	in_sample=np.column_stack((y_hat,prob))
	in_sample = pd.DataFrame(in_sample)
					
	# GET RESULTS INTO STATA
	# (NOTE: the first column is the prediction "y_hat")
	D=Macro.getLocal("_____in_prediction") 
	D=D+".dta"
	in_sample.to_stata(D)

	# MAKE OUT-OF-SAMPLE "LABEL" PREDICTION FOR y USING A PREPARED DATASET
	D=Macro.getLocal("_____out_sample_x") 
	D=D+".dta"
	Xnew = pd.read_stata(D,convert_categoricals=False)
	ynew = model.predict(Xnew)

	# MAKE OUT-OF-SAMPLE "PROBABILITY" PREDICTION FOR y USING A PREPARED DATASET
	prob_new = model.predict_proba(Xnew)
	Prob_new  = pd.DataFrame(prob_new )

	# EXPORT LABEL PREDICTION FOR y INTO AN EXCEL FILE
	Ynew = pd.DataFrame(ynew)

	# MERGE LABEL AND PROBABILITY PREDICTION FOR y INTO AN EXCEL FILE
	# Use "numpy" to stack by column 'ynew' and 'prob_new'
	out=np.column_stack((ynew,prob_new))

	# GENERATE A DATAFRAME 'OUT' FROM THE "out" ARRAY
	OUT = pd.DataFrame(out)
					
	# PUT "OUT" INTO STATA
	# (NOTE: the first column is the prediction "y_hat")
	D=Macro.getLocal("_____out_prediction") 
	D=D+".dta"
	OUT.to_stata(D)

end







