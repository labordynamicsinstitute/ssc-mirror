*! miesize - version 1.0.1 Paul A Tiffin 2023-02-06; Note; now updated with the ability to specify confidence intervals between 50 and 99.99%.
program define miesize, rclass
version 15.0

syntax varname [if] [in] , BY(varname) [,GLass COUNTdown Level(cilevel)]

*This will calculate the z value that will be used for the confidence interval estimation (e.g. 1.96 for 95% CIs)
local z=abs(invnormal(((100-`level')/100)/2))

*This produces an error message if an out of range value for the confidence intervals are selected 
if `level'<10 | `level'>99.99 {
		di in red 	///
		"{bf:level()} must be between 10 and 99.99 inclusive for {bf:miesize}"
		exit 198
	}

return local varname `varlist'
return local by_var `by'  
marksample touse,strok novarlist
quietly count 
if `r(N)'==0 {
	error 2000
	}
qui mi query
scalar m=r(M)
qui mi describe

foreach i in match_by match_var both_vars se_temp* se_sq_temp* D_m* mean* vtotal_* vb_* sep_* vw_* var_* sum_var_* vb_* X {
capture drop `i'
}

*Check that both variables are numeric
capture confirm numeric variable `varlist'
if _rc!=0 disp as error "The outcome variable does not appear numeric." 
if _rc!=0 exit

capture confirm numeric variable `by'
if _rc!=0  disp as error "The grouping variable does not appear numeric." 
if _rc!=0 exit

qui gen match_by=.
qui gen match_var=.
qui replace match_by = 1 if strpos(r(ivars), "`by'")
qui replace match_by = 0 if match_by!=1

qui replace match_var = 1 if strpos(r(ivars), "`varlist'")
qui replace match_var = 0 if match_var!=1
qui gen both_vars=1 if (match_by+match_var)==2

if both_vars==1 & m>1 & m!=. {


******If both variables are imputed*************************************************************************************************************************************
**************************************** Glass's Delta*******************************
******************************************Delta 1************************************
if "`glass'" =="glass" {
*Deriving an average for the glass effect size over imputations
scalar rd=0
qui mi xeq 1/`=scalar(m)': esize twosample `varlist'  if `touse', by(`by') glass; scalar rd = rd +r(delta1)
scalar rd=rd/(m)

*reverse engineering the SEs within each dataset from the CIs (SE is not provided by the esize command) - note this is only calculated for the first row of the data
forvalues i=1/`=scalar(m)' {
	qui esize twosample _`i'_`varlist' if `touse',  by(_`i'_`by') glass
	scalar a_temp`i'=r(ub_delta1)
	scalar b_temp`i'=r(delta1)
	if "`countdown'"=="countdown"{
	disp as text "Countdown " as res ((m)*4)-`i'
	}
	else{
	}
	qui gen se_temp`i'=(a_temp`i'-b_temp`i')/1.96 if _n==1 
}

*Derive VW - within imputation variance
forvalues i=1/`=scalar(m)'{
	qui gen se_sq_temp`i'=(se_temp`i')^2 if _n==1
}

qui egen vw_`by'=rowtotal(se_sq_temp*) if _n==1 
qui replace vw_`by'=vw_`by'/`=scalar(m)' if _n==1 

*Calculating a VB- between imputations variance
*First derive the effect size estimate for each imputed data set
forvalues i=1/`=scalar(m)'{
        qui esize twosample _`i'_`varlist' if `touse', by(_`i'_`by') glass
		if "`countdown'"=="countdown"{
	disp as text "Countdown " as res ((m)*3)-`i'
	}
	else{
	}
         qui gen D_m`i'= r(delta1) if _n==1 
}

*Recall the scalar rd is the mean Glass' delta value 
*Calculating the mean Glass' delta
qui egen mean_d_`by'=rowmean(D_m*) if _n==1

* calculating VW -the within dataset variance 
forvalues i=1/`=scalar(m)'{
         qui gen var_`by'_sq`i'=(D_m`i'-mean_d_`by') if _n==1
         qui replace var_`by'_sq`i'=(var_`by'_sq`i')^2  if _n==1
}

qui gen mean_d=rd if _n==1
qui egen sum_var_`by'=rowtotal(var_`by'_sq*) if _n==1
qui gen vb_`by'=sum_var_`by'/((m)-1) if _n==1
qui scalar vb_`by'=vb_`by' 

*Derive the final pooled SE
*Vtotal=VW + VB + VB/m
qui gen vtotal_`by'= vw_`by' + vb_`by' + (vb_`by'/`=scalar(m)') if _n==1
qui gen sep_`by'=sqrt(vtotal_`by') if _n==1
scalar pooled_se= sep_`by' 

scalar ub_`by'=(`=scalar(rd)') + (`z'*(`=scalar(pooled_se)'))
scalar lb_`by'=(`=scalar(rd)') - (`z'*(`=scalar(pooled_se)'))

return local ub_g1=(`=scalar(rd)') + (`z'*(`=scalar(pooled_se)'))
return local lb_g1=(`=scalar(rd)') - (`z'*(`=scalar(pooled_se)'))
return local pt_est_g1 `=scalar(rd)'
return local pooled_se_g1 `=scalar(pooled_se)'
return local pooled_se_g1 `=scalar(pooled_se)'

*Drop temporary variables
drop se_temp*  se_sq_temp*  D_m* mean* vtotal_* sep_* vw_* var_* sum_var_* vb_*
************************************Delta 2*********************************************************************
*Deriving an average for the Glass' effect size 2 over imputations

scalar rdt=0
qui mi xeq 1/`=scalar(m)': esize twosample `varlist' if `touse', by(`by') glass; scalar rdt = rdt +r(delta2)
scalar rdt=rdt/(m)

*reverse engineering the SEs within each dataset from the CIs (SE is not provided by the esize command) - note this is only calculated for the first row of the data
forvalues i=1/`=scalar(m)' {
	qui esize twosample _`i'_`varlist' if `touse',  by(_`i'_`by') glass
	if "`countdown'"=="countdown"{
	disp as text "Countdown " as res ((m)*2)-`i'
	}
	else{
	}
	scalar a_temp`i'=r(ub_delta2)
	scalar b_temp`i'=r(delta2)
	qui gen se_temp`i'=(a_temp`i'-b_temp`i')/1.96 if _n==1 
}

*Derive VW - within imputation variance
forvalues i=1/`=scalar(m)'{
	qui gen se_sq_temp`i'=(se_temp`i')^2 if _n==1
}

qui egen vw_`by'=rowtotal(se_sq_temp*) if _n==1 
qui replace vw_`by'=vw_`by'/`=scalar(m)' if _n==1 

*Calculating a VB- between imputations variance
*First derive the effect size estimate for each imputed data set
forvalues i=1/`=scalar(m)'{
        qui esize twosample _`i'_`varlist' if `touse', by(_`i'_`by') glass
		if "`countdown'"=="countdown"{
	disp as text "Countdown " as res ((m)*1)-`i'
	}
	else{
	}
         qui gen D_m`i'= r(delta2) if _n==1 
}

*Recall the scalar 'rdt' is the mean Glass' delta 2 value 
*calculating the mean Glass' delta
qui egen mean_d_`by'=rowmean(D_m*) if _n==1

*Calculating VW -the within dataset variance 
forvalues i=1/`=scalar(m)'{
         qui gen var_`by'_sq`i'=(D_m`i'-mean_d_`by') if _n==1
         qui replace var_`by'_sq`i'=(var_`by'_sq`i')^2  if _n==1
}

qui gen mean_d=rdt if _n==1
qui egen sum_var_`by'=rowtotal(var_`by'_sq*) if _n==1
qui gen vb_`by'=sum_var_`by'/((m)-1) if _n==1
qui scalar vb_`by'=vb_`by' 

*Derive the final pooled SE
*Vtotal=VW + VB + VB/m
qui gen vtotal_`by'= vw_`by' + vb_`by' + (vb_`by'/`=scalar(m)') if _n==1
qui gen sep_`by'=sqrt(vtotal_`by') if _n==1
scalar pooled_se= sep_`by' 

scalar ub2_`by'=(`=scalar(rdt)') + (`z'*(`=scalar(pooled_se)'))
scalar lb2_`by'=(`=scalar(rdt)') - (`z'*(`=scalar(pooled_se)'))

return local ub_g2=(`=scalar(rdt)') + (`z'*(`=scalar(pooled_se)'))
return local lb_g2=(`=scalar(rdt)') - (`z'*(`=scalar(pooled_se)'))
return local pt_est_g2 `=scalar(rdt)'
return local pooled_se_g2 `=scalar(pooled_se)'

*Reporting average number in both groups
scalar group_count_n1=0
qui mi xeq 1/`=scalar(m)': esize twosample `varlist' if `touse', by(`by') glass; scalar group_count_n1 = group_count_n1 +r(N_1)
scalar  group_count_n1= group_count_n1/(m)

scalar group_count_n2=0
qui mi xeq 1/`=scalar(m)': esize twosample `varlist' if `touse', by(`by') glass; scalar group_count_n2 = group_count_n2 +r(N_2)
scalar  group_count_n2= group_count_n2/(m)

disp as text "Average obs per Group 1 " as res group_count_n1
disp as text "Average obs per Group 2 " as res group_count_n2

di as text "                                                           "
di as text "Effect size    {c |} Pooled estimate" _col(37) "    [`level'% conf. interval]"
di as text "{hline 15}{c +}{hline 53}"
di as text "Glass's Delta 1{c |} " as result     %9.0g rd  "              " %9.0g lb_`by' 	"       " %9.0g ub_`by' 
di as text "Glass's Delta 2{c |} " as result     %9.0g rdt "              "%9.0g lb2_`by' "       " %9.0g ub2_`by' 

*Drop temporary variables
drop se_temp*  se_sq_temp*  D_m* mean* vtotal_* sep_* vw_* var_* sum_var_* vb_*

}
**************************************** Cohen's d*******************************
else {

*Deriving an average for the Cohen's d effect size over imputations
scalar rdd=0
qui mi xeq 1/`=scalar(m)': esize twosample `varlist' if `touse', by(`by'); scalar rdd = rdd +r(d)
scalar rdd=rdd/(m)

*reverse engineering the SEs within each dataset from the CIs (SE is not provided by the esize command) - note this is only calculated for the first row of the data
forvalues i=1/`=scalar(m)' {
	qui esize twosample _`i'_`varlist' if `touse',  by(_`i'_`by') 
	scalar a_temp`i'=r(ub_d)
	scalar b_temp`i'=r(d)
	if "`countdown'"=="countdown"{
	disp as text "Countdown " as res ((m)*4)-`i'
	}
	else{
	}
	qui gen se_temp`i'=(a_temp`i'-b_temp`i')/1.96 if _n==1 
}

*Derive VW - within imputation variance
forvalues i=1/`=scalar(m)'{
	qui gen se_sq_temp`i'=(se_temp`i')^2 if _n==1
}

qui egen vw_`by'=rowtotal(se_sq_temp*) if _n==1 
qui replace vw_`by'=vw_`by'/`=scalar(m)' if _n==1 

*Calculating a VB- the between imputations variance
*First derive the effect size estimate for each imputed data set
forvalues i=1/`=scalar(m)'{
        qui esize twosample _`i'_`varlist' if `touse', by(_`i'_`by') 
		if "`countdown'"=="countdown"{
	disp as text "Countdown " as res ((m)*3)-`i'
	}
	else{
	}
         qui gen D_m`i'= r(d) if _n==1 
}

*Recall the scalar 'rd' is the mean Cohen's d effect
*Calculating the mean Cohen's d effect
qui egen mean_d_`by'=rowmean(D_m*) if _n==1

*Calculating VW -the within dataset variance 
forvalues i=1/`=scalar(m)'{
         qui gen var_`by'_sq`i'=(D_m`i'-mean_d_`by') if _n==1
         qui replace var_`by'_sq`i'=(var_`by'_sq`i')^2  if _n==1
}

qui gen mean_d=rdd if _n==1
qui egen sum_var_`by'=rowtotal(var_`by'_sq*) if _n==1
qui gen vb_`by'=sum_var_`by'/((m)-1) if _n==1
qui scalar vb_`by'=vb_`by' 

*Derive the final pooled SE
*Vtotal=VW + VB + VB/m
qui gen vtotal_`by'= vw_`by' + vb_`by' + (vb_`by'/`=scalar(m)') if _n==1
qui gen sep_`by'=sqrt(vtotal_`by') if _n==1
scalar pooled_se= sep_`by' 

scalar ub_d_`by'=(`=scalar(rdd)') + (`z'*(`=scalar(pooled_se)'))
scalar lb_d_`by'=(`=scalar(rdd)') - (`z'*(`=scalar(pooled_se)'))
return local ub_d=(`=scalar(rdd)') + (`z'*(`=scalar(pooled_se)'))
return local lb_d=(`=scalar(rdd)') - (`z'*(`=scalar(pooled_se)'))

return local pt_est_d `=scalar(rdd)'
return local pooled_se_d `=scalar(pooled_se)'

*Drop temporary variables
drop se_temp*  se_sq_temp*  D_m* mean* vtotal_* sep_* vw_* var_* sum_var_* vb_*


********************************************Hedges's G*************************************************************************************

*Deriving an average for the Hedges's G effect size over imputations
scalar rdg=0
qui mi xeq 1/`=scalar(m)': esize twosample `varlist' if `touse', by(`by'); scalar rdg = rdg +r(g)
scalar rdg=rdg/(m)

*Reverse engineering the SEs within each dataset from the CIs (SE is not provided by the esize command) - note this is only calculated for the first row of the data
forvalues i=1/`=scalar(m)' {
	qui esize twosample _`i'_`varlist' if `touse',  by(_`i'_`by') 
	scalar a_temp`i'=r(ub_g)
	scalar b_temp`i'=r(g)
	if "`countdown'"=="countdown"{
	disp as text "Countdown " as res ((m)*2)-`i'
	}
	else{
	}
	qui gen se_temp`i'=(a_temp`i'-b_temp`i')/1.96 if _n==1 
}

*Derive VW - the within imputations variance
forvalues i=1/`=scalar(m)'{
	qui gen se_sq_temp`i'=(se_temp`i')^2 if _n==1
}

qui egen vw_`by'=rowtotal(se_sq_temp*) if _n==1 
qui replace vw_`by'=vw_`by'/`=scalar(m)' if _n==1 

*Calculating a VB- between imputations variance
*First derive the effect size estimate for each imputed data set
forvalues i=1/`=scalar(m)'{
        qui esize twosample _`i'_`varlist' if `touse', by(_`i'_`by')
if "`countdown'"=="countdown"{
	disp as text "Countdown " as res ((m)*1)-`i'
	}
	else{
	}		
         qui gen D_m`i'= r(g) if _n==1 
}

*Recall the scalar rd is the mean Hedges's g effect
*Calculating the mean Hedges's g effect
qui egen mean_d_`by'=rowmean(D_m*) if _n==1

*Calculating VW -the within dataset variance 
forvalues i=1/`=scalar(m)'{
         qui gen var_`by'_sq`i'=(D_m`i'-mean_d_`by') if _n==1
         qui replace var_`by'_sq`i'=(var_`by'_sq`i')^2  if _n==1
}

qui gen mean_d=rdg if _n==1
qui egen sum_var_`by'=rowtotal(var_`by'_sq*) if _n==1
qui gen vb_`by'=sum_var_`by'/((m)-1) if _n==1
qui scalar vb_`by'=vb_`by' 

*Derive the final pooled SE
*Vtotal=VW + VB + VB/m
qui gen vtotal_`by'= vw_`by' + vb_`by' + (vb_`by'/`=scalar(m)') if _n==1
qui gen sep_`by'=sqrt(vtotal_`by') if _n==1
scalar pooled_se= sep_`by' 

scalar ub_g_`by'=(`=scalar(rdg)') + (`z'*(`=scalar(pooled_se)'))
scalar lb_g_`by'=(`=scalar(rdg)') - (`z'*(`=scalar(pooled_se)'))

return local ub_g=(`=scalar(rdg)') + (`z'*(`=scalar(pooled_se)'))
return local lb_g=(`=scalar(rdg)') - (`z'*(`=scalar(pooled_se)'))
return local pt_est_g `=scalar(rdg)'
return local pooled_se_g `=scalar(pooled_se)'
return local pooled_se_g `=scalar(pooled_se)'

*Reporting average number in both groups
scalar group_count_n1=0
qui mi xeq 1/`=scalar(m)': esize twosample `varlist' if `touse', by(`by'); scalar group_count_n1 = group_count_n1 +r(N_1)
scalar  group_count_n1= group_count_n1/(m)

scalar group_count_n2=0
qui mi xeq 1/`=scalar(m)': esize twosample `varlist' if `touse', by(`by'); scalar group_count_n2 = group_count_n2 +r(N_2)
scalar  group_count_n2= group_count_n2/(m)

disp as text "Average obs per Group 1 " as res group_count_n1
disp as text "Average obs per Group 2 " as res group_count_n2

*Drop temporary variables
drop se_temp*  se_sq_temp*  D_m* mean* vtotal_* sep_* vw_* var_* sum_var_* vb_* 

di as text "                                                           "
di as text "Effect size    {c |} Pooled estimate" _col(37) "    [`level'% conf. interval]"
di as text "{hline 15}{c +}{hline 53}"
di as text "Cohen's {it:d}      {c |} " as result     %9.0g rdd  "              " %9.0g lb_d_`by' 	"       " %9.0g ub_d_`by' 
di as text "Hedges' {it:g}      {c |} " as result     %9.0g rdg  "              " %9.0g lb_g_`by' 	"       " %9.0g ub_g_`by' 
}
}
 ***************************************** If Grouping variable not imputed and outcome imputed  m>1 **************************************************************************************************
 
if match_var == 1 & match_by== 0 & m>1 & m!=. {
 
disp as text "Note: your grouping variable does not appear to be imputed. The analysis will be carried out accordingly." 
 

 
 **************************************** Glass's Delta***********************************************************************************************************************
******************************************Delta 1*****************************************************************************************************************************
if "`glass'" =="glass" {
*Deriving an average for the glass effect size over imputations
scalar rd=0
qui mi xeq 1/`=scalar(m)': esize twosample `varlist'  if `touse', by(`by') glass; scalar rd = rd +r(delta1)
scalar rd=rd/(m)

*reverse engineering the SEs within each dataset from the CIs (SE is not provided by the esize command) - note this is only calculated for the first row of the data
forvalues i=1/`=scalar(m)' {
	qui esize twosample _`i'_`varlist' if `touse',  by(`by') glass
	scalar a_temp`i'=r(ub_delta1)
	scalar b_temp`i'=r(delta1)
	if "`countdown'"=="countdown"{
	disp as text "Countdown " as res ((m)*4)-`i'
	}
	else{
	}
	qui gen se_temp`i'=(a_temp`i'-b_temp`i')/1.96 if _n==1 
}

*Derive VW - within imputation variance
forvalues i=1/`=scalar(m)'{
	qui gen se_sq_temp`i'=(se_temp`i')^2 if _n==1
}

qui egen vw_`by'=rowtotal(se_sq_temp*) if _n==1 
qui replace vw_`by'=vw_`by'/`=scalar(m)' if _n==1 

*Calculating a VB- between imputations variance
*First derive the effect size estimate for each imputed data set
forvalues i=1/`=scalar(m)'{
        qui esize twosample _`i'_`varlist' if `touse', by(`by') glass
		if "`countdown'"=="countdown"{
	disp as text "Countdown " as res ((m)*3)-`i'
	}
	else{
	}
         qui gen D_m`i'= r(delta1) if _n==1 
}

*Recall the scalar rd is the mean Glass' delta value 
*Calculating the mean Glass' delta
qui egen mean_d_`by'=rowmean(D_m*) if _n==1

* calculating VW -the within dataset variance 
forvalues i=1/`=scalar(m)'{
         qui gen var_`by'_sq`i'=(D_m`i'-mean_d_`by') if _n==1
         qui replace var_`by'_sq`i'=(var_`by'_sq`i')^2  if _n==1
}

qui gen mean_d=rd if _n==1
qui egen sum_var_`by'=rowtotal(var_`by'_sq*) if _n==1
qui gen vb_`by'=sum_var_`by'/((m)-1) if _n==1
qui scalar vb_`by'=vb_`by' 

*Derive the final pooled SE
*Vtotal=VW + VB + VB/m
qui gen vtotal_`by'= vw_`by' + vb_`by' + (vb_`by'/`=scalar(m)') if _n==1
qui gen sep_`by'=sqrt(vtotal_`by') if _n==1
scalar pooled_se= sep_`by' 

scalar ub_`by'=(`=scalar(rd)') + (`z'*(`=scalar(pooled_se)'))
scalar lb_`by'=(`=scalar(rd)') - (`z'*(`=scalar(pooled_se)'))

return local ub_g1=(`=scalar(rd)') + (`z'*(`=scalar(pooled_se)'))
return local lb_g1=(`=scalar(rd)') - (`z'*(`=scalar(pooled_se)'))
return local pt_est_g1 `=scalar(rd)'
return local pooled_se_g1 `=scalar(pooled_se)'
return local pooled_se_g1 `=scalar(pooled_se)'

*Drop temporary variables
drop se_temp*  se_sq_temp*  D_m* mean* vtotal_* sep_* vw_* var_* sum_var_* vb_*
************************************Delta 2*********************************************************************
*Deriving an average for the Glass' effect size 2 over imputations

scalar rdt=0
qui mi xeq 1/`=scalar(m)': esize twosample `varlist' if `touse', by(`by') glass; scalar rdt = rdt +r(delta2)
scalar rdt=rdt/(m)

*reverse engineering the SEs within each dataset from the CIs (SE is not provided by the esize command) - note this is only calculated for the first row of the data
forvalues i=1/`=scalar(m)' {
	qui esize twosample _`i'_`varlist' if `touse',  by(`by') glass
	if "`countdown'"=="countdown"{
	disp as text "Countdown " as res ((m)*2)-`i'
	}
	else{
	}
	scalar a_temp`i'=r(ub_delta2)
	scalar b_temp`i'=r(delta2)
	qui gen se_temp`i'=(a_temp`i'-b_temp`i')/1.96 if _n==1 
}

*Derive VW - within imputation variance
forvalues i=1/`=scalar(m)'{
	qui gen se_sq_temp`i'=(se_temp`i')^2 if _n==1
}

qui egen vw_`by'=rowtotal(se_sq_temp*) if _n==1 
qui replace vw_`by'=vw_`by'/`=scalar(m)' if _n==1 

*Calculating a VB- between imputations variance
*First derive the effect size estimate for each imputed data set
forvalues i=1/`=scalar(m)'{
        qui esize twosample _`i'_`varlist' if `touse', by(`by') glass
		if "`countdown'"=="countdown"{
	disp as text "Countdown " as res ((m)*1)-`i'
	}
	else{
	}
         qui gen D_m`i'= r(delta2) if _n==1 
}

*Recall the scalar 'rdt' is the mean Glass' delta 2 value 
*calculating the mean Glass' delta
qui egen mean_d_`by'=rowmean(D_m*) if _n==1

*Calculating VW -the within dataset variance 
forvalues i=1/`=scalar(m)'{
         qui gen var_`by'_sq`i'=(D_m`i'-mean_d_`by') if _n==1
         qui replace var_`by'_sq`i'=(var_`by'_sq`i')^2  if _n==1
}

qui gen mean_d=rdt if _n==1
qui egen sum_var_`by'=rowtotal(var_`by'_sq*) if _n==1
qui gen vb_`by'=sum_var_`by'/((m)-1) if _n==1
qui scalar vb_`by'=vb_`by' 

*Derive the final pooled SE
*Vtotal=VW + VB + VB/m
qui gen vtotal_`by'= vw_`by' + vb_`by' + (vb_`by'/`=scalar(m)') if _n==1
qui gen sep_`by'=sqrt(vtotal_`by') if _n==1
scalar pooled_se= sep_`by' 

scalar ub2_`by'=(`=scalar(rdt)') + (`z'*(`=scalar(pooled_se)'))
scalar lb2_`by'=(`=scalar(rdt)') - (`z'*(`=scalar(pooled_se)'))

return local ub_g2=(`=scalar(rdt)') + (`z'*(`=scalar(pooled_se)'))
return local lb_g2=(`=scalar(rdt)') - (`z'*(`=scalar(pooled_se)'))
return local pt_est_g2 `=scalar(rdt)'
return local pooled_se_g2 `=scalar(pooled_se)'

*Reporting average number in both groups
scalar group_count_n1=0
qui mi xeq 1/`=scalar(m)': esize twosample `varlist' if `touse', by(`by') glass; scalar group_count_n1 = group_count_n1 +r(N_1)
scalar  group_count_n1= group_count_n1/(m)

scalar group_count_n2=0
qui mi xeq 1/`=scalar(m)': esize twosample `varlist' if `touse', by(`by') glass; scalar group_count_n2 = group_count_n2 +r(N_2)
scalar  group_count_n2= group_count_n2/(m)

disp as text "Average obs per Group 1 " as res group_count_n1
disp as text "Average obs per Group 2 " as res group_count_n2

di as text "                                                           "
di as text "Effect size    {c |} Pooled estimate" _col(37) "    [`level'% conf. interval]"
di as text "{hline 15}{c +}{hline 53}"
di as text "Glass's Delta 1{c |} " as result     %9.0g rd  "              " %9.0g lb_`by' 	"       " %9.0g ub_`by' 
di as text "Glass's Delta 2{c |} " as result     %9.0g rdt "              "%9.0g lb2_`by' "       " %9.0g ub2_`by' 

*Drop temporary variables
drop se_temp*  se_sq_temp*  D_m* mean* vtotal_* sep_* vw_* var_* sum_var_* vb_*

}
**************************************** Cohen's d*******************************
else {

*Deriving an average for the Cohen's d effect size over imputations
scalar rdd=0
qui mi xeq 1/`=scalar(m)': esize twosample `varlist' if `touse', by(`by'); scalar rdd = rdd +r(d)
scalar rdd=rdd/(m)

*reverse engineering the SEs within each dataset from the CIs (SE is not provided by the esize command) - note this is only calculated for the first row of the data
forvalues i=1/`=scalar(m)' {
	qui esize twosample _`i'_`varlist' if `touse',  by(`by') 
	scalar a_temp`i'=r(ub_d)
	scalar b_temp`i'=r(d)
	if "`countdown'"=="countdown"{
	disp as text "Countdown " as res ((m)*4)-`i'
	}
	else{
	}
	qui gen se_temp`i'=(a_temp`i'-b_temp`i')/1.96 if _n==1 
}

*Derive VW - within imputation variance
forvalues i=1/`=scalar(m)'{
	qui gen se_sq_temp`i'=(se_temp`i')^2 if _n==1
}

qui egen vw_`by'=rowtotal(se_sq_temp*) if _n==1 
qui replace vw_`by'=vw_`by'/`=scalar(m)' if _n==1 

*Calculating a VB- the between imputations variance
*First derive the effect size estimate for each imputed data set
forvalues i=1/`=scalar(m)'{
        qui esize twosample _`i'_`varlist' if `touse', by(`by') 
		if "`countdown'"=="countdown"{
	disp as text "Countdown " as res ((m)*3)-`i'
	}
	else{
	}
         qui gen D_m`i'= r(d) if _n==1 
}

*Recall the scalar 'rd' is the mean Cohen's d effect
*Calculating the mean Cohen's d effect
qui egen mean_d_`by'=rowmean(D_m*) if _n==1

*Calculating VW -the within dataset variance 
forvalues i=1/`=scalar(m)'{
         qui gen var_`by'_sq`i'=(D_m`i'-mean_d_`by') if _n==1
         qui replace var_`by'_sq`i'=(var_`by'_sq`i')^2  if _n==1
}

qui gen mean_d=rdd if _n==1
qui egen sum_var_`by'=rowtotal(var_`by'_sq*) if _n==1
qui gen vb_`by'=sum_var_`by'/((m)-1) if _n==1
qui scalar vb_`by'=vb_`by' 

*Derive the final pooled SE
*Vtotal=VW + VB + VB/m
qui gen vtotal_`by'= vw_`by' + vb_`by' + (vb_`by'/`=scalar(m)') if _n==1
qui gen sep_`by'=sqrt(vtotal_`by') if _n==1
scalar pooled_se= sep_`by' 

scalar ub_d_`by'=(`=scalar(rdd)') + (`z'*(`=scalar(pooled_se)'))
scalar lb_d_`by'=(`=scalar(rdd)') - (`z'*(`=scalar(pooled_se)'))

return local ub_d=(`=scalar(rdd)') + (`z'*(`=scalar(pooled_se)'))
return local lb_d=(`=scalar(rdd)') - (`z'*(`=scalar(pooled_se)'))
return local pt_est_d `=scalar(rdd)'
return local pooled_se_d `=scalar(pooled_se)'

*Drop temporary variables
drop se_temp*  se_sq_temp*  D_m* mean* vtotal_* sep_* vw_* var_* sum_var_* vb_*


********************************************Hedges's G*************************************************************************************

*Deriving an average for the Hedges's G effect size over imputations
scalar rdg=0
qui mi xeq 1/`=scalar(m)': esize twosample `varlist' if `touse', by(`by'); scalar rdg = rdg +r(g)
scalar rdg=rdg/(m)

*Reverse engineering the SEs within each dataset from the CIs (SE is not provided by the esize command) - note this is only calculated for the first row of the data
forvalues i=1/`=scalar(m)' {
	qui esize twosample _`i'_`varlist' if `touse',  by(`by') 
	scalar a_temp`i'=r(ub_g)
	scalar b_temp`i'=r(g)
	if "`countdown'"=="countdown"{
	disp as text "Countdown " as res ((m)*2)-`i'
	}
	else{
	}
	qui gen se_temp`i'=(a_temp`i'-b_temp`i')/1.96 if _n==1 
}

*Derive VW - the within imputations variance
forvalues i=1/`=scalar(m)'{
	qui gen se_sq_temp`i'=(se_temp`i')^2 if _n==1
}

qui egen vw_`by'=rowtotal(se_sq_temp*) if _n==1 
qui replace vw_`by'=vw_`by'/`=scalar(m)' if _n==1 

*Calculating a VB- between imputations variance
*First derive the effect size estimate for each imputed data set
forvalues i=1/`=scalar(m)'{
        qui esize twosample _`i'_`varlist' if `touse', by(`by')
if "`countdown'"=="countdown"{
	disp as text "Countdown " as res ((m)*1)-`i'
	}
	else{
	}		
         qui gen D_m`i'= r(g) if _n==1 
}

*Recall the scalar rd is the mean Hedges's g effect
*Calculating the mean Hedges's g effect
qui egen mean_d_`by'=rowmean(D_m*) if _n==1

*Calculating VW -the within dataset variance 
forvalues i=1/`=scalar(m)'{
         qui gen var_`by'_sq`i'=(D_m`i'-mean_d_`by') if _n==1
         qui replace var_`by'_sq`i'=(var_`by'_sq`i')^2  if _n==1
}

qui gen mean_d=rdg if _n==1
qui egen sum_var_`by'=rowtotal(var_`by'_sq*) if _n==1
qui gen vb_`by'=sum_var_`by'/((m)-1) if _n==1
qui scalar vb_`by'=vb_`by' 

*Derive the final pooled SE
*Vtotal=VW + VB + VB/m
qui gen vtotal_`by'= vw_`by' + vb_`by' + (vb_`by'/`=scalar(m)') if _n==1
qui gen sep_`by'=sqrt(vtotal_`by') if _n==1
scalar pooled_se= sep_`by' 

scalar ub_g_`by'=(`=scalar(rdg)') + (`z'*(`=scalar(pooled_se)'))
scalar lb_g_`by'=(`=scalar(rdg)') - (`z'*(`=scalar(pooled_se)'))

return local ub_g=(`=scalar(rdg)') + (`z'*(`=scalar(pooled_se)'))
return local lb_g=(`=scalar(rdg)') - (`z'*(`=scalar(pooled_se)'))
return local pt_est_g `=scalar(rdg)'
return local pooled_se_g `=scalar(pooled_se)'
return local pooled_se_g `=scalar(pooled_se)'

*Reporting average number in both groups
scalar group_count_n1=0
qui mi xeq 1/`=scalar(m)': esize twosample `varlist' if `touse', by(`by'); scalar group_count_n1 = group_count_n1 +r(N_1)
scalar  group_count_n1= group_count_n1/(m)

scalar group_count_n2=0
qui mi xeq 1/`=scalar(m)': esize twosample `varlist' if `touse', by(`by'); scalar group_count_n2 = group_count_n2 +r(N_2)
scalar  group_count_n2= group_count_n2/(m)

disp as text "Average obs per Group 1 " as res group_count_n1
disp as text "Average obs per Group 2 " as res group_count_n2

*Drop temporary variables
drop se_temp*  se_sq_temp*  D_m* mean* vtotal_* sep_* vw_* var_* sum_var_* vb_* 

di as text "                                                           "
di as text "Effect size    {c |} Pooled estimate" _col(37) "    [`level'% conf. interval]"
di as text "{hline 15}{c +}{hline 53}"
di as text "Cohen's {it:d}      {c |} " as result     %9.0g rdd  "              " %9.0g lb_d_`by' 	"       " %9.0g ub_d_`by' 
di as text "Hedges' {it:g}      {c |} " as result     %9.0g rdg  "              " %9.0g lb_g_`by' 	"       " %9.0g ub_g_`by' 
}
 
} 

********************************************  If outcome not imputed but grouping variable imputed m>1 ********************************************************************************************

if match_var==0 & match_by==1 & m>1 & m!=. {

disp as text "Your outcome variable does not appear to be imputed. The analysis will be carried out accordingly."

  
 **************************************** Glass's Delta***********************************************************************************************************************
******************************************Delta 1*****************************************************************************************************************************
if "`glass'" =="glass" {
*Deriving an average for the glass effect size over imputations
scalar rd=0
qui mi xeq 1/`=scalar(m)': esize twosample `varlist'  if `touse', by(`by') glass; scalar rd = rd +r(delta1)
scalar rd=rd/(m)

*reverse engineering the SEs within each dataset from the CIs (SE is not provided by the esize command) - note this is only calculated for the first row of the data
forvalues i=1/`=scalar(m)' {
	qui esize twosample `varlist' if `touse',  by(_`i'_`by') glass
	scalar a_temp`i'=r(ub_delta1)
	scalar b_temp`i'=r(delta1)
	if "`countdown'"=="countdown"{
	disp as text "Countdown " as res ((m)*4)-`i'
	}
	else{
	}
	qui gen se_temp`i'=(a_temp`i'-b_temp`i')/1.96 if _n==1 
}

*Derive VW - within imputation variance
forvalues i=1/`=scalar(m)'{
	qui gen se_sq_temp`i'=(se_temp`i')^2 if _n==1
}

qui egen vw_`by'=rowtotal(se_sq_temp*) if _n==1 
qui replace vw_`by'=vw_`by'/`=scalar(m)' if _n==1 

*Calculating a VB- between imputations variance
*First derive the effect size estimate for each imputed data set
forvalues i=1/`=scalar(m)'{
        qui esize twosample `varlist' if `touse', by(_`i'_`by') glass
		if "`countdown'"=="countdown"{
	disp as text "Countdown " as res ((m)*3)-`i'
	}
	else{
	}
         qui gen D_m`i'= r(delta1) if _n==1 
}

*Recall the scalar rd is the mean Glass' delta value 
*Calculating the mean Glass' delta
qui egen mean_d_`by'=rowmean(D_m*) if _n==1

* calculating VW -the within dataset variance 
forvalues i=1/`=scalar(m)'{
         qui gen var_`by'_sq`i'=(D_m`i'-mean_d_`by') if _n==1
         qui replace var_`by'_sq`i'=(var_`by'_sq`i')^2  if _n==1
}

qui gen mean_d=rd if _n==1
qui egen sum_var_`by'=rowtotal(var_`by'_sq*) if _n==1
qui gen vb_`by'=sum_var_`by'/((m)-1) if _n==1
qui scalar vb_`by'=vb_`by' 

*Derive the final pooled SE
*Vtotal=VW + VB + VB/m
qui gen vtotal_`by'= vw_`by' + vb_`by' + (vb_`by'/`=scalar(m)') if _n==1
qui gen sep_`by'=sqrt(vtotal_`by') if _n==1
scalar pooled_se= sep_`by' 

scalar ub_`by'=(`=scalar(rd)') + (`z'*(`=scalar(pooled_se)'))
scalar lb_`by'=(`=scalar(rd)') - (`z'*(`=scalar(pooled_se)'))

return local ub_g1=(`=scalar(rd)') + (`z'*(`=scalar(pooled_se)'))
return local lb_g1=(`=scalar(rd)') - (`z'*(`=scalar(pooled_se)'))
return local pt_est_g1 `=scalar(rd)'
return local pooled_se_g1 `=scalar(pooled_se)'
return local pooled_se_g1 `=scalar(pooled_se)'

*Drop temporary variables
drop se_temp*  se_sq_temp*  D_m* mean* vtotal_* sep_* vw_* var_* sum_var_* vb_*
************************************Delta 2*********************************************************************
*Deriving an average for the Glass' effect size 2 over imputations

scalar rdt=0
qui mi xeq 1/`=scalar(m)': esize twosample `varlist' if `touse', by(`by') glass; scalar rdt = rdt +r(delta2)
scalar rdt=rdt/(m)

*reverse engineering the SEs within each dataset from the CIs (SE is not provided by the esize command) - note this is only calculated for the first row of the data
forvalues i=1/`=scalar(m)' {
	qui esize twosample `varlist' if `touse',  by(_`i'_`by') glass
	if "`countdown'"=="countdown"{
	disp as text "Countdown " as res ((m)*2)-`i'
	}
	else{
	}
	scalar a_temp`i'=r(ub_delta2)
	scalar b_temp`i'=r(delta2)
	qui gen se_temp`i'=(a_temp`i'-b_temp`i')/1.96 if _n==1 
}

*Derive VW - within imputation variance
forvalues i=1/`=scalar(m)'{
	qui gen se_sq_temp`i'=(se_temp`i')^2 if _n==1
}

qui egen vw_`by'=rowtotal(se_sq_temp*) if _n==1 
qui replace vw_`by'=vw_`by'/`=scalar(m)' if _n==1 

*Calculating a VB- between imputations variance
*First derive the effect size estimate for each imputed data set
forvalues i=1/`=scalar(m)'{
        qui esize twosample `varlist' if `touse', by(_`i'_`by') glass
		if "`countdown'"=="countdown"{
	disp as text "Countdown " as res ((m)*1)-`i'
	}
	else{
	}
         qui gen D_m`i'= r(delta2) if _n==1 
}

*Recall the scalar 'rdt' is the mean Glass' delta 2 value 
*calculating the mean Glass' delta
qui egen mean_d_`by'=rowmean(D_m*) if _n==1

*Calculating VW -the within dataset variance 
forvalues i=1/`=scalar(m)'{
         qui gen var_`by'_sq`i'=(D_m`i'-mean_d_`by') if _n==1
         qui replace var_`by'_sq`i'=(var_`by'_sq`i')^2  if _n==1
}

qui gen mean_d=rdt if _n==1
qui egen sum_var_`by'=rowtotal(var_`by'_sq*) if _n==1
qui gen vb_`by'=sum_var_`by'/((m)-1) if _n==1
qui scalar vb_`by'=vb_`by' 

*Derive the final pooled SE
*Vtotal=VW + VB + VB/m
qui gen vtotal_`by'= vw_`by' + vb_`by' + (vb_`by'/`=scalar(m)') if _n==1
qui gen sep_`by'=sqrt(vtotal_`by') if _n==1
scalar pooled_se= sep_`by' 

scalar ub2_`by'=(`=scalar(rdt)') + (`z'*(`=scalar(pooled_se)'))
scalar lb2_`by'=(`=scalar(rdt)') - (`z'*(`=scalar(pooled_se)'))

return local ub_g2=(`=scalar(rdt)') + (`z'*(`=scalar(pooled_se)'))
return local lb_g2=(`=scalar(rdt)') - (`z'*(`=scalar(pooled_se)'))
return local pt_est_g2 `=scalar(rdt)'
return local pooled_se_g2 `=scalar(pooled_se)'

*Reporting average number in both groups
scalar group_count_n1=0
qui mi xeq 1/`=scalar(m)': esize twosample `varlist' if `touse', by(`by') glass; scalar group_count_n1 = group_count_n1 +r(N_1)
scalar  group_count_n1= group_count_n1/(m)

scalar group_count_n2=0
qui mi xeq 1/`=scalar(m)': esize twosample `varlist' if `touse', by(`by') glass; scalar group_count_n2 = group_count_n2 +r(N_2)
scalar  group_count_n2= group_count_n2/(m)

disp as text "Average obs per Group 1 " as res group_count_n1
disp as text "Average obs per Group 2 " as res group_count_n2

di as text "                                                           "
di as text "Effect size    {c |} Pooled estimate" _col(37) "    [`level'% conf. interval]"
di as text "{hline 15}{c +}{hline 53}"
di as text "Glass's Delta 1{c |} " as result     %9.0g rd  "              " %9.0g lb_`by' 	"       " %9.0g ub_`by' 
di as text "Glass's Delta 2{c |} " as result     %9.0g rdt "              "%9.0g lb2_`by' "       " %9.0g ub2_`by' 

*Drop temporary variables
drop se_temp*  se_sq_temp*  D_m* mean* vtotal_* sep_* vw_* var_* sum_var_* vb_*

}
**************************************** Cohen's d*******************************
else {

*Deriving an average for the Cohen's d effect size over imputations
scalar rdd=0
qui mi xeq 1/`=scalar(m)': esize twosample `varlist' if `touse', by(`by'); scalar rdd = rdd +r(d)
scalar rdd=rdd/(m)

*reverse engineering the SEs within each dataset from the CIs (SE is not provided by the esize command) - note this is only calculated for the first row of the data
forvalues i=1/`=scalar(m)' {
	qui esize twosample `varlist' if `touse',  by(_`i'_`by') 
	scalar a_temp`i'=r(ub_d)
	scalar b_temp`i'=r(d)
	if "`countdown'"=="countdown"{
	disp as text "Countdown " as res ((m)*4)-`i'
	}
	else{
	}
	qui gen se_temp`i'=(a_temp`i'-b_temp`i')/1.96 if _n==1 
}

*Derive VW - within imputation variance
forvalues i=1/`=scalar(m)'{
	qui gen se_sq_temp`i'=(se_temp`i')^2 if _n==1
}

qui egen vw_`by'=rowtotal(se_sq_temp*) if _n==1 
qui replace vw_`by'=vw_`by'/`=scalar(m)' if _n==1 

*Calculating a VB- the between imputations variance
*First derive the effect size estimate for each imputed data set
forvalues i=1/`=scalar(m)'{
        qui esize twosample `varlist' if `touse', by(_`i'_`by') 
		if "`countdown'"=="countdown"{
	disp as text "Countdown " as res ((m)*3)-`i'
	}
	else{
	}
         qui gen D_m`i'= r(d) if _n==1 
}

*Recall the scalar 'rd' is the mean Cohen's d effect
*Calculating the mean Cohen's d effect
qui egen mean_d_`by'=rowmean(D_m*) if _n==1

*Calculating VW -the within dataset variance 
forvalues i=1/`=scalar(m)'{
         qui gen var_`by'_sq`i'=(D_m`i'-mean_d_`by') if _n==1
         qui replace var_`by'_sq`i'=(var_`by'_sq`i')^2  if _n==1
}

qui gen mean_d=rdd if _n==1
qui egen sum_var_`by'=rowtotal(var_`by'_sq*) if _n==1
qui gen vb_`by'=sum_var_`by'/((m)-1) if _n==1
qui scalar vb_`by'=vb_`by' 

*Derive the final pooled SE
*Vtotal=VW + VB + VB/m
qui gen vtotal_`by'= vw_`by' + vb_`by' + (vb_`by'/`=scalar(m)') if _n==1
qui gen sep_`by'=sqrt(vtotal_`by') if _n==1
scalar pooled_se= sep_`by' 

scalar ub_d_`by'=(`=scalar(rdd)') + (`z'*(`=scalar(pooled_se)'))
scalar lb_d_`by'=(`=scalar(rdd)') - (`z'*(`=scalar(pooled_se)'))

return local ub_d=(`=scalar(rdd)') + (`z'*(`=scalar(pooled_se)'))
return local lb_d=(`=scalar(rdd)') - (`z'*(`=scalar(pooled_se)'))
return local pt_est_d `=scalar(rdd)'
return local pooled_se_d `=scalar(pooled_se)'

*Drop temporary variables
drop se_temp*  se_sq_temp*  D_m* mean* vtotal_* sep_* vw_* var_* sum_var_* vb_*


********************************************Hedges's G*************************************************************************************

*Deriving an average for the Hedges's G effect size over imputations
scalar rdg=0
qui mi xeq 1/`=scalar(m)': esize twosample `varlist' if `touse', by(`by'); scalar rdg = rdg +r(g)
scalar rdg=rdg/(m)

*Reverse engineering the SEs within each dataset from the CIs (SE is not provided by the esize command) - note this is only calculated for the first row of the data
forvalues i=1/`=scalar(m)' {
	qui esize twosample `varlist' if `touse',  by(_`i'_`by') 
	scalar a_temp`i'=r(ub_g)
	scalar b_temp`i'=r(g)
	if "`countdown'"=="countdown"{
	disp as text "Countdown " as res ((m)*2)-`i'
	}
	else{
	}
	qui gen se_temp`i'=(a_temp`i'-b_temp`i')/1.96 if _n==1 
}

*Derive VW - the within imputations variance
forvalues i=1/`=scalar(m)'{
	qui gen se_sq_temp`i'=(se_temp`i')^2 if _n==1
}

qui egen vw_`by'=rowtotal(se_sq_temp*) if _n==1 
qui replace vw_`by'=vw_`by'/`=scalar(m)' if _n==1 

*Calculating a VB- between imputations variance
*First derive the effect size estimate for each imputed data set
forvalues i=1/`=scalar(m)'{
        qui esize twosample `varlist' if `touse', by(_`i'_`by')
if "`countdown'"=="countdown"{
	disp as text "Countdown " as res ((m)*1)-`i'
	}
	else{
	}		
         qui gen D_m`i'= r(g) if _n==1 
}

*Recall the scalar rd is the mean Hedges's g effect
*Calculating the mean Hedges's g effect
qui egen mean_d_`by'=rowmean(D_m*) if _n==1

*Calculating VW -the within dataset variance 
forvalues i=1/`=scalar(m)'{
         qui gen var_`by'_sq`i'=(D_m`i'-mean_d_`by') if _n==1
         qui replace var_`by'_sq`i'=(var_`by'_sq`i')^2  if _n==1
}

qui gen mean_d=rdg if _n==1
qui egen sum_var_`by'=rowtotal(var_`by'_sq*) if _n==1
qui gen vb_`by'=sum_var_`by'/((m)-1) if _n==1
qui scalar vb_`by'=vb_`by' 

*Derive the final pooled SE
*Vtotal=VW + VB + VB/m
qui gen vtotal_`by'= vw_`by' + vb_`by' + (vb_`by'/`=scalar(m)') if _n==1
qui gen sep_`by'=sqrt(vtotal_`by') if _n==1
scalar pooled_se= sep_`by' 

scalar ub_g_`by'=(`=scalar(rdg)') + (`z'*(`=scalar(pooled_se)'))
scalar lb_g_`by'=(`=scalar(rdg)') - (`z'*(`=scalar(pooled_se)'))

return local ub_g=(`=scalar(rdg)') + (`z'*(`=scalar(pooled_se)'))
return local lb_g=(`=scalar(rdg)') - (`z'*(`=scalar(pooled_se)'))
return local pt_est_g `=scalar(rdg)'
return local pooled_se_g `=scalar(pooled_se)'
return local pooled_se_g `=scalar(pooled_se)'

*Reporting average number in both groups
scalar group_count_n1=0
qui mi xeq 1/`=scalar(m)': esize twosample `varlist' if `touse', by(`by'); scalar group_count_n1 = group_count_n1 +r(N_1)
scalar  group_count_n1= group_count_n1/(m)

scalar group_count_n2=0
qui mi xeq 1/`=scalar(m)': esize twosample `varlist' if `touse', by(`by'); scalar group_count_n2 = group_count_n2 +r(N_2)
scalar  group_count_n2= group_count_n2/(m)

disp as text "Average obs per Group 1 " as res group_count_n1
disp as text "Average obs per Group 2 " as res group_count_n2

*Drop temporary variables
drop se_temp*  se_sq_temp*  D_m* mean* vtotal_* sep_* vw_* var_* sum_var_* vb_* 

di as text "                                                           "
di as text "Effect size    {c |} Pooled estimate" _col(37) "    [`level'% conf. interval]"
di as text "{hline 15}{c +}{hline 53}"
di as text "Cohen's {it:d}      {c |} " as result     %9.0g rdd  "              " %9.0g lb_d_`by' 	"       " %9.0g ub_d_`by' 
di as text "Hedges' {it:g}      {c |} " as result     %9.0g rdg  "              " %9.0g lb_g_`by' 	"       " %9.0g ub_g_`by' 
}
 
} 

if match_by==0 & match_var==0 { 
disp as text "It appears that neither of the variables are imputed. The standard 'esize twosample' analysis will be performed."
disp as text "You may wish to check your imputed data is in standard stata wide format."
if "`glass'" =="glass" {
esize twosample `varlist', by(`by') glass
}
else esize twosample `varlist', by(`by') 
}

****************************************************************************************************************************************************************************************
******If both variables are imputed only once (m=1) *************************************************************************************************************************************

if both_vars==1 & m==1 {
disp as text "Your data appears to have only one imputation for both grouping and outcome variables. Therefore a two sample effect size for the imputed dataset will be calculated using esize, not miesize."   

if "`glass'" =="glass" {
*Deriving an average for the glass effect size in the singly imputed dataset
esize twosample _1_`varlist', by(_1_`by') glass

}

else esize twosample _1_`varlist', by(_1_`by') 
}

*************************************************************************************************************************************************************************************
****If grouping variable imputed once ****************************************************************************************
if match_by==1 & match_var==0 & m==1 {
disp as text "Your data appears to have only one imputation for the grouping variable and no imputations for the outcome variable. Therefore a two sample effect size for the imputed dataset will be calculated using esize, not miesize."   

if "`glass'" =="glass" {
*Deriving an average for the glass effect size in the singly imputed dataset
esize twosample `varlist', by(_1_`by') glass

}

else esize twosample `varlist', by(_1_`by') 
}


*************************************************************************************************************************************************************************************
****If outcome variable imputed once ****************************************************************************************

if match_by==0 & match_var==1 & m==1 {
disp as text "Your data appears to have only one imputation for the outcome variable and no imputations for the grouping variable. Therefore a two sample effect size for the imputed dataset will be calculated using esize, not miesize."   

if "`glass'" =="glass" {
*Deriving an average for the glass effect size in the singly imputed dataset
esize twosample _1_`varlist', by(`by') glass
}

else esize twosample _1_`varlist', by(`by') 
}



end
