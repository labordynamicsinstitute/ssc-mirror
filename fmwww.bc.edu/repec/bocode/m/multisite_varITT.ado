program multisite_varITT , rclass
version 14.2
syntax varlist(min=3 max=3 numeric)  [if] [aweight]
preserve
qui{
tempvar outcome instrument site 
tokenize `varlist'
gen `outcome'=`1'
gen `instrument'=`2'
gen `site'=`3'

*Keeping if sample
if `"`if'"' != "" {
keep `if'
}


bys `site': egen n1s=total(`instrument')
bys `site': gen ns=_N
gen n0s=ns-n1s
drop if n1s<2|n0s<2
drop ns n1s n0s

qui{
matrix A=.,.,.,.,.,.
levelsof `site', local(levels)
foreach y of local levels {		
sum `outcome' [`weight' `exp'] if `instrument'==1 & `site'==`y'
scalar Ybar1=r(mean)
scalar nt=r(N)
sum `outcome' [`weight' `exp'] if `instrument'==0 & `site'==`y'
scalar Ybar0=r(mean)
scalar nc=r(N)
scalar n_s=nt+nc
scalar ATE_s=Ybar1 - Ybar0
gen diff1treat= (`outcome'-Ybar1)^2 if `instrument'==1 & `site'==`y'
gen diff1control= (`outcome'-Ybar0)^2 if `instrument'==0 & `site'==`y'
summ diff1t [`weight' `exp']
scalar rY1S=(nt/(nt-1))*r(mean)
summ diff1co [`weight' `exp']
scalar rY0S=(nc/(nc-1))*r(mean)
scalar V_rob_s=(1/nt)*rY1S+(1/nc)*rY0S
drop diff*

 matrix A=A\ `y',ATE_s,V_rob_s,nt,nc,n_s
}
}
 
svmat A
keep A*
rename A1 site
rename A2 ATE_s
rename A3 V_rob_s
rename A4 nt
rename A5 nc
rename A6 n_s
drop if ATE_s==.

sum n_s
gen n=r(sum)
gen nbar=n/_N

gen propor= n_s/n
gen prop2= n_s/nbar

sum V_rob_s
gen for_ate=prop2*ATE_s
sum for_ate
scalar ATE_hat=r(mean)
gen for_var_ate=propor*V_rob_s
sum for_var_ate
scalar se_coef=sqrt(r(mean))
gen forbound=propor*((ATE_s-ATE_hat)^2-V_rob_s)
sum forbound 
scalar bound=r(sum)
gen var_s=prop2*((ATE_s-ATE_hat)^2-V_rob_s)
sum var_s
gen var_s_cent=var_s-r(mean)
gen var_s_cent_sq=var_s_cent^2
sum var_s_cent_sq
scalar var_est=r(mean)/r(N)
scalar se_est= sqrt(var_est)
return scalar se_est= se_est
scalar lb=bound-1.96*se_est
scalar ub=bound+1.96*se_est

return scalar var_itt=bound
return scalar se_varitt=se_est
return scalar lb=lb
return scalar ub=ub
return scalar ITT_hat=ATE_hat
return scalar se_itt_hat=se_coef
}
di "The average ITT is " ATE_hat " and its standard error is " se_coef
di "The variance of the ITTs across sites is " bound " and its standard error is " se_est
di "The 95% confidence interval for the variance of the ITTs across sites is " "[" lb "," ub "]"
di "The ratio of the standard deviation of ITTs and average ITT is " sqrt(bound)/ATE_hat
restore
end
