clear all
cap prog drop _all
prog ivp, eclass
  syntax [varlist] [if] [in] [, exog(varlist) endog(varlist) * ]
  marksample touse
  gettoken lhs varlist:varlist
  loc rhs1: list varlist | endog
  loc insts1: list varlist | exog 
  loc insts1: list insts1 - endog
  loc exexog: list insts1 - varlist
  loc i=1
  foreach v of loc endog {
   tempvar v`i'
   reg `v' `exog' if `touse'
   predict `v`i'', resid
   local vs "`vs' `v`i++''"
   }
  poisson `lhs' `rhs1' `vs' if `touse'
end 
prog pdata, rclass
  drop _all
  matrix C = (1, .25, .5 \ .25, 1, 0 \ .5, 0, 1)
  if "`1'"=="" loc n=round(1000*exp(.1*invnorm(uniform())))
  else loc n=`1'
  drawnorm x e z, n(`n') corr(C)
  g y=exp(1+x+e)
  bs _b[x] _b[_cons]: ivp y, exog(z) endog(x)
  return scalar tb=_b[ _bs_1]
  return scalar tbse=_se[ _bs_1]
  return scalar tc=_b[ _bs_2]
  return scalar tcse=_se[ _bs_2]
  return scalar tn=e(N)
  ivpois y, exog(z) endog(x) 
  return scalar b=_b[x]
  return scalar bse=_se[x]
  return scalar c=_b[_cons]
  return scalar cse=_se[_cons]
  return scalar n=e(N)
  eret clear
end
set seed 1234567
*pdata 1000

simulate, reps(1000): pdata 1000

cap drop r ts gmm i
g r=.
g ts=.
g gmm=.
g i=_n in 1/200
qui forv i=5/195 {
 loc b=`i'/100
 replace r=(2-2*norm(abs((b-`b')/bse))<.05)
 su r, meanonly
 replace gmm=r(mean) in `i'
 replace r=(2-2*norm(abs((tb-`b')/tbse))<.05)
 su r, meanonly
 replace ts=r(mean) in `i'
}
replace i=(i-100)/100
line gmm ts i, xti(" " "Distance from true beta, percent of beta") yli(.05) yti("Rejection rate, alpha=5%" " ") leg(lab(1 "GMM") lab(2 "Twostep") pos(3) col(1))
