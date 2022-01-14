********************************************************************************
*! "r_ml_stata"
*! Author: Giovanni Cerulli
*! Version: 11
*! Date: 13 January 2022
********************************************************************************
program r_ml_stata , eclass
version 16
syntax varlist , mlmodel(string) in_prediction(name) cross_validation(name) out_sample_x(name) out_sample_y(name) ///
out_prediction(name) seed(numlist max=1 integer) n_folds(numlist max=1 integer) [save_graph_cv(name)]
********************************************************************************
gettoken y X : varlist
********************************************************************************
* WARNING 1
********************************************************************************
cap confirm file `out_sample_y'.dta
if _rc!=0 {
di _newline
di in red "***************************************************************************"
di in red "WARNING: File '`out_sample_y'' does not exist in your directory.             " 
di in red "Please, provide a Stata out-of-sample dataset made only of y."   
di in red "***************************************************************************"
di _newline
break
exit
}
********************************************************************************
cap confirm file `out_sample_x'.dta
if _rc!=0 {
di _newline
di in red "***************************************************************************"
di in red "WARNING: File '`out_sample_x'' does not exist in your directory.             " 
di in red "Please, provide a Stata out-of-sample dataset made only of new X-instances."   
di in red "***************************************************************************"
di _newline
exit
}
else if _rc==0{
********************************************************************************
* PASS THE STATA DIRECTORY TO PYTHON
********************************************************************************
local dir `c(pwd)'
********************************************************************************
tempfile data_intial 
save `data_intial' , replace
********************************************************************************
* WARNING 2
********************************************************************************
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
********************************************************************************
if `SS'!=`NN'{
di _newline
di in red "******************************************************************"
di in red "WARNING: It seems there are missing values in your 'varlist'.     "
di in red "         Please, remove them and re-run this command.             "
di in red "******************************************************************"
di _newline
exit
}
********************************************************************************
* KEEP AND ORDER THE DEPENDENT AND THE INDEPENDENT VARIABLES
********************************************************************************
keep `y' `X'
order `y' `X'
********************************************************************************
*
********************************************************************************
* ESTIMATION PROCEDURE
********************************************************************************
* SAVE THE DATASET AS IT IS
tempfile data_fitting 
save `data_fitting' , replace
********************************************************************************
* PYTHON CODE - BEGIN 
********************************************************************************
if "`mlmodel'"=="boost"{
python script "`c(sysdir_plus)'py/r_boost.py"
preserve
keep `y' `in_prediction'
save `in_prediction' , replace
restore
ereturn clear
ereturn scalar OPT_LEARNING_RATE=OPT_LEARNING_RATE
ereturn scalar OPT_N_ESTIMATORS=OPT_N_ESTIMATORS
}
********************************************************************************
else if "`mlmodel'"=="elasticnet"{
python script "`c(sysdir_plus)'py/r_elasticnet.py"
preserve
keep `y' `in_prediction'
save `in_prediction' , replace
restore
ereturn clear
ereturn scalar OPT_ALPHA=OPT_ALPHA
ereturn scalar OPT_L1_RATIO=OPT_L1_RATIO
}
********************************************************************************
else if "`mlmodel'"=="nearestneighbor"{
python script "`c(sysdir_plus)'py/r_nearestneighbor.py"
preserve
keep `y' `in_prediction'
save `in_prediction' , replace
restore
ereturn clear
ereturn scalar OPT_NN=OPT_NN
ereturn local OPT_WEIGHT "$OPT_WEIGHT"
}
********************************************************************************
else if "`mlmodel'"=="neuralnet"{
python script "`c(sysdir_plus)'py/r_neuralnet.py"
preserve
keep `y' `in_prediction'
save `in_prediction' , replace
restore
ereturn clear
ereturn scalar OPT_NEURONS_L_1=OPT_NEURONS_L_1
ereturn scalar OPT_NEURONS_L_2=OPT_NEURONS_L_2
}
********************************************************************************
else if "`mlmodel'"=="randomforest"{
python script "`c(sysdir_plus)'py/r_randomforest.py"
preserve
keep `y' `in_prediction'
save `in_prediction' , replace
restore
ereturn clear
ereturn scalar OPT_MAX_DEPTH=OPT_MAX_DEPTH
ereturn scalar OPT_MAX_FEATURES=OPT_MAX_FEATURES
}
********************************************************************************
else if "`mlmodel'"=="svm"{
python script "`c(sysdir_plus)'py/r_svm.py"
preserve
keep `y' `in_prediction'
save `in_prediction' , replace
restore
ereturn clear
ereturn scalar OPT_C=OPT_C
ereturn scalar OPT_GAMMA=OPT_GAMMA
}
********************************************************************************
else if "`mlmodel'"=="tree"{
python script "`c(sysdir_plus)'py/r_tree.py"
preserve
keep `y' `in_prediction'
save `in_prediction' , replace
restore
ereturn clear
ereturn scalar OPT_DEPTH=OPT_LEAVES
}
********************************************************************************
* STORE RESULTS
******************************************************************************** 
preserve
********************************************************************************
use `cross_validation' , clear
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
use `out_sample_y' , clear
foreach var of varlist _all{
	local y_test `var'
}
cap drop index
gen index=_n-1
save `out_sample_y' , replace
restore
********************************************************************************
preserve
use `out_prediction' , clear
rename _0 out_sample_pred
la var out_sample_pred "Out-of-sample predictions"
merge 1:1 index using `out_sample_y'
cap drop _merge
la var `y_test' "Actual outcome of the test dataset"
save `out_prediction' , replace
restore
********************************************************************************
* CROSS-VALIDATION GRAPH
********************************************************************************
use `cross_validation' , clear
local A=int(max_index)
if "`save_graph_cv'"!=""{
tw ///
(line mean_test_score index  , xline(`A',lp(dash) lw(thick))) ///
(line mean_train_score index ) , ///
legend(order(1 "TEST ACCURACY" 2 "TRAIN ACCURACY")) ///
note("Learner = `mlmodel'" "Optimal index = `A'" "Number of folds = `n_folds'") ///
ytitle(Accuracy) xtitle(Index) ///
graphregion(fcolor(white)) scheme(s2mono) saving(`save_graph_cv' , replace)
}
********************************************************************************
use `data_intial' , clear
********************************************************************************
}
********************************************************************************
end 
********************************************************************************
