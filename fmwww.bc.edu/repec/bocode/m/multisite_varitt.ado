program multisite_varITT , eclass
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

bys `site': egen multisiteITT_n1s = total(`instrument')
bys `site': gen multisiteITT_ns = _N
gen multisiteITT_n0s = multisiteITT_ns - multisiteITT_n1s
drop if multisiteITT_n1s < 2 | multisiteITT_n0s < 2
drop multisiteITT_ns multisiteITT_n1s multisiteITT_n0s
local total_obs = _N

qui{
matrix A=.,.,.,.,.,.
levelsof `site', local(levels)
local num_site : word count `levels'
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
local total_obs = _N
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

ereturn clear

ereturn scalar itt_hat = ATE_hat
ereturn scalar se_itt_hat = se_coef
ereturn scalar lb_CI_itt=ATE_hat-1.96*se_coef
ereturn scalar ub_CI_itt=ATE_hat+1.96*se_coef

ereturn scalar var_itt=bound
ereturn scalar se_varitt=se_est
ereturn scalar lb_CI_var_itt=bound-1.96*se_est
ereturn scalar ub_CI_var_itt=bound+1.96*se_est

ereturn scalar N = `total_obs'
ereturn scalar Sites = `num_site'

// Output the Final Table
* Create the Output Matrix
matrix mat_res_XX = J(3, 6, .)

* Display Filling
matrix mat_res_XX[1, 1] = ATE_hat 
matrix mat_res_XX[2, 1] = bound 
matrix mat_res_XX[3, 1] = sqrt(bound)/ATE_hat

matrix mat_res_XX[1, 2] = se_coef 
matrix mat_res_XX[2, 2] = se_est  

matrix mat_res_XX[1, 3] = ATE_hat - 1.96 * se_coef // Lower bound
matrix mat_res_XX[2, 3] = bound - 1.96 * se_est // Lower bound
matrix mat_res_XX[1, 4] = ATE_hat + 1.96 * se_coef // Upper bound
matrix mat_res_XX[2, 4] = bound + 1.96 * se_est // Upper bound

matrix mat_res_XX[1, 5] = `num_site'  // Number of Sites
matrix mat_res_XX[1, 6] = `total_obs'  // Total Observations
matrix mat_res_XX[2, 5] = `num_site'  // Number of Sites
matrix mat_res_XX[2, 6] = `total_obs'  // Total Observations
matrix mat_res_XX[3, 5] = `num_site'  // Number of Sites
matrix mat_res_XX[3, 6] = `total_obs'  // Total Observations

}

matrix rownames mat_res_XX = "Average of ITTs" "Variance of ITTs" "sd ITTs / Average ITTs"
matrix colnames mat_res_XX = "Estimate" "SE"  "95% LB" "95% UB" "# Sites" "# Units"
	
* Display the Table
di "{hline 93}"
di _skip(25) "{bf: Estimators of Variance of ITT in Multi-site RCT}"
di "{hline 93}"
noisily matlist mat_res_XX, border(rows) twidth(25)
di as text "The development of this package was funded by the European Union (ERC, REALLYCREDIBLE,GA N°101043899)."

restore
end

