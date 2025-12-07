********************************************************************************
*! "opl_overlap", G.Cerulli, 23/11/2025
********************************************************************************
program opl_overlap , rclass
syntax [, gr_save_roc(string) gr_save_ps(string)] 
********************************************************************************
local cmd "make_cate"
if "`e(cmd)'"!="make_cate"{
	di in red "*****************************************************************"
	di in red "WARNING: 'opl_overlap' requires 'make_cate' to be previously run."
	di in red "*****************************************************************"
	exit
}
else{
********************************************************************************
* Check variable pre-existence of new generated variables
********************************************************************************
capture confirm variable _ps_var
if !_rc {
	di in red "*********************************************************************"
	display as error "WARNING: variable '_ps_var' already exists"
	di in red "*********************************************************************"
exit
}
********************************************************************************
* Check graph name pre-existence for graph "_GR_PS_"
********************************************************************************
capture graph describe _GR_PS_
if !_rc {
    di in red "*********************************************************************"
    display as error "WARNING: graph '_GR_PS_' already exists"
    di in red "*********************************************************************"
    exit
}
********************************************************************************
* Check graph name pre-existence "_GR_ROC_"
********************************************************************************
capture graph describe _GR_ROC_
if !_rc {
    di in red "*********************************************************************"
    display as error "WARNING: graph '_GR_ROC_' already exists"
    di in red "*********************************************************************"
    exit
}
********************************************************************************	
* MAIN CODE	
********************************************************************************	
qui{
tempvar group
encode _train_new_index , gen(`group')
replace `group'=`group'-1
logit `group' `e(xvars)'
********************************************************************************
* COMPARING DATA TRAIN AND DATA NEW DISTRIBUTIONS (Reverse PS)
********************************************************************************
predict _ps_var , pr 
twoway ///
    (kdensity _ps_var if `group' == 0) ///
    (kdensity _ps_var if `group' == 1), ///
    legend(order(1 "Data train" 2 "Data new")) ///
    title("Reverse propensity-score distributions") ///
    xtitle("")  ytitle("") name(_GR_PS_ , replace)
if "`gr_save_ps'"!=""{
	graph save `gr_save_ps' , replace	
}
********************************************************************************
* ESTIMATE ROC, COMPUTE AUC, GRAPH ROC
********************************************************************************	
lroc ,  name(_GR_ROC_ , replace)
if "`gr_save_roc'"!=""{
	graph save `gr_save_roc' , replace	
}
********************************************************************************
* DISPLAY RESULTS
********************************************************************************
local AUC = r(area)
local _N=r(N)
}
di _newline	
noi di "{hline 85}"
noi di in gr "{bf: *** RESULTS ON 'DATA TRAIN' AND 'DATA NEW' OVERLAP ***}"
noi di "{hline 85}"
if `AUC'<=0.6{
noi di "{hline 85}"
di as result "--> [AUC < 0.6]: The datasets overlap is 'Very Good'"
noi di "{hline 85}"
} 
if `AUC'>0.6 & `AUC'<=0.7{
noi di "{hline 85}"
di as result "--> [0.6 < AUC <= 0.7]: The datasets overlap is 'Good'"
noi di "{hline 85}"
} 
if `AUC'>0.7 & `AUC'<=0.8{
noi di "{hline 85}"
di as result "--> [0.7 < AUC <= 0.8]: The datasets overlap is 'moderate'"
noi di "{hline 85}"
	} 
if `AUC'>0.8 & `AUC'<=0.9{
noi di "{hline 85}"
di as result "--> [0.8 < AUC <= 0.9]: The datasets overlap is 'poor'"
noi di "{hline 85}"
} 
if `AUC'>0.9{
noi di "{hline 85}"
di as result "--> [AUC > 0.9]: The datasets overlap is 'very poor'"
noi di "{hline 85}"
}
********************************************************************************
return scalar AUC = `AUC'
return scalar N = `_N'
********************************************************************************
}
end