program multisite_varLATE, rclass
version 14.2
syntax varlist(min=4 max=4 numeric)  [if] [aweight]
qui{
preserve

tempvar outcome treatment instrument site 
tokenize `varlist'
gen `outcome'=`1'
gen `treatment'=`2'
gen `instrument'=`3'
gen `site'=`4'

*Keeping if sample
if `"`if'"' != "" {
keep `if'
}

bys `site': egen n1s=total(`instrument')
bys `site': gen ns=_N
gen n0s=ns-n1s
drop if n1s<2|n0s<2
drop ns n1s n0s

matrix A=.,.,.,.,.,.,.,.,.,.,.,.
levelsof `site', local(levels)
foreach y of local levels {
sum `outcome' [`weight' `exp'] if `instrument'==1 & `site'==`y'
scalar Ybar1=r(mean)
scalar nt=r(N)
sum `outcome' [`weight' `exp'] if `instrument'==0 & `site'==`y'
scalar Ybar0=r(mean)
scalar nc=r(N)
scalar ns=nt+nc
gen diff1treat= (`outcome'-Ybar1)^2 if `instrument'==1 & `site'==`y'
gen diff1control= (`outcome'-Ybar0)^2 if `instrument'==0 & `site'==`y'
summ diff1treat [`weight' `exp']
scalar rY1S=(nt/(nt-1))*r(mean)
summ diff1control [`weight' `exp']
scalar rY0S=(nc/(nc-1))*r(mean)
scalar VI_s=(1/nt)*rY1S+(1/nc)*rY0S
drop diff*
scalar I_s=Ybar1 - Ybar0


sum  `treatment' [`weight' `exp'] if `instrument'==1 & `site'==`y'
scalar Dbar1=r(mean)
sum `treatment' [`weight' `exp'] if `instrument'==0 & `site'==`y'
scalar Dbar0=r(mean)
scalar F_s=Dbar1 - Dbar0

gen diff1treat= (`treatment'-Dbar1)^2 if `instrument'==1 & `site'==`y'
gen diff1control= (`treatment'-Dbar0)^2 if `instrument'==0 & `site'==`y'
summ diff1treat [`weight' `exp']
scalar rD1S=(nt/(nt-1))*r(mean)
summ diff1control [`weight' `exp']
scalar rD0S=(nc/(nc-1))*r(mean)
scalar VF_s=(1/nt)*rD1S+(1/nc)*rD0S
drop diff*


gen diff2treat= (`outcome'-Ybar1)*(`treatment'-Dbar1) if `instrument'==1 & `site'==`y'
gen diff2control= (`outcome'-Ybar0)*(`treatment'-Dbar0)  if `instrument'==0 & `site'==`y'
summ diff2treat [`weight' `exp'] 
scalar cDY1S=(nt/(nt-1))*r(mean)/nt
summ diff2control [`weight' `exp']
scalar cDY0S=(nc/(nc-1))*r(mean)/nc
drop  diff*

matrix A=A\ `y',ns,F_s,VF_s,I_s,VI_s,nc,nt,cDY0S,cDY1S,rD0S,rD1S
} 
svmat A

sum A2
gen n=r(sum)
sum A1
gen nbar=n/r(N)

gen prop2= A2/n
gen wtildes= A2/nbar
sum A5 [aw=prop2]
scalar Ibar=r(sum)
sum A3 [aw=prop2]
scalar Fbar=r(sum)
scalar Lbar=Ibar/Fbar
gen outcome2=`outcome'-`treatment'*Lbar

matrix B=.,.
levelsof `site', local(levels)
foreach y of local levels {

sum outcome2 [`weight' `exp'] if `instrument'==1 & `site'==`y'
scalar vbar1=r(mean)
scalar nt=r(N)
sum outcome2 [`weight' `exp'] if `instrument'==0 & `site'==`y'
scalar vbar0=r(mean)
scalar nc=r(N)
scalar ns=nt+nc

scalar nu_s=vbar1-vbar0


gen diff6treat= (outcome2-vbar1)^2 if `instrument'==1 & `site'==`y'
gen diff6control= (outcome2-vbar0)^2 if `instrument'==0 & `site'==`y'
summ diff6treat [`weight' `exp']
scalar rv1S=(nt/(nt-1))*r(mean)
summ diff6control [`weight' `exp']
scalar rv0S=(nc/(nc-1))*r(mean)
scalar V_nu_s=(1/nt)*rv1S+(1/nc)*rv0S
drop diff6*

matrix B=B\nu_s,V_nu_s
}

svmat B
keep A* B* prop2 wtildes nbar n
rename B1 nu_s
rename B2 V_nu_s
rename A1 site
rename A2 ns
rename A3 F_s
rename A4 VF_s
rename A5 I_s
rename A6 VI_s
rename A7 nc
rename A8 nt
rename A9 cDY0S
rename A10 cDY1S
rename A11 rD0S
rename A12 rD1S
drop if site==.

gen F2=F_s^2
gen firstterm=(I_s-F_s*Lbar)^2- V_nu_s

sum firstterm [aw=prop2]
scalar num=r(sum)

gen fordenom=(F2-VF_s)
sum fordenom [aw=prop2]
scalar denom=r(sum)
scalar bound=num/denom

gen forC1=F_s*nu_s
sum forC1 [aw=prop2]
scalar C1=r(sum)
gen forC2=((Lbar*rD1S-cDY1S)/(nt))+((Lbar*rD0S-cDY0S)/(nc))
sum forC2 [aw=prop2]
scalar C2=r(sum)
scalar C3=bound
scalar C4=denom

sum F_s [aw=prop2]
scalar Fbar=r(sum)
gen phi_s5=(wtildes*nu_s)/Fbar
sum phi_s5
scalar barphi5=r(mean)
gen forvar_LATE=(phi_s5-barphi5)^2
sum forvar_LATE
scalar se_LATE=(r(mean)/r(N))^(0.5)

gen phi_s6= (wtildes*(nu_s^2 - V_nu_s) - 2*(C1+C2)*phi_s5 - wtildes*(F2-VF_s)*C3)/C4
sum phi_s6
scalar barphi6=r(mean)
gen forvar=(phi_s6-barphi6)^2
sum forvar
scalar var_est=r(mean)/r(N)
scalar SE_bound=(var_est)^(0.5)

scalar lb=bound-1.96*SE_bound
scalar ub=bound+1.96*SE_bound

return scalar var_LATE=bound
return scalar se_varlate=SE_bound
return scalar lb=lb
return scalar ub=ub
return scalar LATE_hat=Lbar
return scalar se_late_hatt=se_LATE
restore
}
di "The average LATE is " Lbar " and its standard error is " se_LATE
di "The estimated variance of the LATEs across sites is " bound " and its standard error is " SE_bound
di "The 95% confidence interval for the variance of the LATEs across sites is " "[" lb "," ub "]"
di "The ratio of the standard deviation of LATEs and average LATE is " sqrt(bound)/Lbar
end