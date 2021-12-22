* Examples of sivqr.ado:
* 1. ^Example 1 from ivregress (housing values/rents)
* 2. ^Example 4 from ivregress (wage/tenure)
* 3. Example from Chernozhukov and Hansen / Graddy (1995), demand curve
* 4. Example of 401(k) participation from Chernozhukov and Hansen (2004)
* 5. Example of Engel curve from cqiv command
* 6. ^More on computation time
* 7. A simple graph
* ^detailed in Stata Journal article

* To install:
*net from https://kaplandm.github.io/stata
*net describe sivqr
*net install sivqr
*net get sivqr


* Specify directory w/ sivqr.ado (if not already in a standard directory; use command
*    sysdir   to check standard directories.

*.tex output:  sjlog do sivqr_examples , clear replace


clear all
program drop _all
set more off
set linesize 67
set linesize 78
set linesize 80
cls


*********
* 1. Example 1 from ivregress
*********
* https://www.stata.com/manuals13/rivregress.pdf
webuse hsng2 , clear
timer clear
timer on 1
ivregress 2sls rent pcturban (hsngval = faminc i.region) , vce(robust)
timer off 1
sivqr rent pcturban (hsngval = faminc i.region), q(0.25) reps(200)
sivqr rent pcturban (hsngval = faminc i.region), q(0.50) reps(200)
sivqr rent pcturban (hsngval = faminc i.region), q(0.75) reps(200)
forv i = 2/4 {
 gen dregion`i' = (region==`i')
}
sivqr rent pcturban (hsngval = faminc i.region), q(0.25) reps(0) b(0) // sanity check: identical w/ i.region or dregion*
matrix res = J(3,5,.)
qui ivregress 2sls rent pcturban (hsngval = faminc i.region) , vce(robust)
matrix tmp = e(b)
matrix res[1,1] = tmp[1,1]
matrix res[2,1] = tmp[1,1]
matrix res[3,1] = tmp[1,1]
timer on 2
forv i = 1/3 {
 local q = `i'/4
 local b = 5 + 20*abs(`i'-2)
 sivqr rent pcturban (hsngval = faminc dregion*), q(`q') reps(0) b(`b')
 matrix tmp = e(b)
 matrix res[`i',2] = tmp[1,1]
}
timer off 2
timer on 22
forv i = 1/3 {
 local q = `i'/4
 local b = 5 + 20*abs(`i'-2)
 sivqr rent pcturban (hsngval = faminc dregion*), q(`q') reps(100) b(`b')
}
timer off 22
timer on 4
 ivqreg2 rent hsngval pcturban , q(0.25 0.50 0.75) inst(faminc dregion* pcturban)
 matrix tmp = e(b_25)
 matrix res[1,4] = tmp[1,1]
 matrix tmp = e(b_5)
 matrix res[2,4] = tmp[1,1]
 matrix tmp = e(b_75)
 matrix res[3,4] = tmp[1,1]
timer off 4
*
timer on 3
preserve
count
forv i = 1/3 {
 local q = `i'/4
 capture ivqreg rent pcturban (hsngval = faminc dregion*), q(`q') //gets error...
 matrix tmp = e(b)
 matrix res[`i',3] = tmp[1,1]*tmp[2,1]/tmp[2,1] // set missing if rowsof(tmp)==1
}
count
restore
timer off 3
*
preserve
count
timer on 5
forv i = 1/3 {
 local q = 25*`i'
 cqiv rent pcturban (hsngval = faminc dregion*) , uncensored q(`q')
 matrix tmp = e(results)
 matrix res[`i',5] = tmp[1,1]
}
timer off 5
count
restore
*
timer list
matrix rownames res = q25 q50 q75
matrix colnames res = 2SLS sivqr ivqreg ivqreg2 cqiv
matrix list res , f(%9.0g)
* unlike 2SLS/sivqr, ivqreg2 Coef ests (for hsngval) all essentially zero
* [ivqreg missing due to errors]
*
* ERROR <<estimates post: matrix has missing values>>  ivqreg rent pcturban (hsngval = faminc dregion*), q(0.5)
* ERROR ivqreg rent pcturban (hsngval = faminc dregion3 ), q(0.5)
* Runs if remove dregion* but then negative coef on pcturban...
count //ivqreg gets "no observations" error if r(N)==0, from above timer list call...
ivqreg rent pcturban (hsngval = faminc ), q(0.25)
count
ivqreg rent pcturban (hsngval = faminc ), q(0.50)
ivqreg rent pcturban (hsngval = faminc ), q(0.75)


*********
* 2. Example 4 from ivregress
*********
* https://www.stata.com/manuals13/rivregress.pdf
webuse nlswork , clear
xtset idcode
* Compare with 2SLS, including std err
ivregress 2sls ln_wage c.age##c.age birth_yr grade (tenure = union wks_work msp) , vce(cluster idcode)
bootstrap , reps(20) cluster(idcode) seed(112358) : sivqr ln_wage c.age##c.age birth_yr grade (tenure = union wks_work msp) , q(0.25) reps(0)
bootstrap , reps(20) cluster(idcode) seed(112358) : sivqr ln_wage c.age##c.age birth_yr grade (tenure = union wks_work msp) , q(0.50) reps(0)
bootstrap , reps(20) cluster(idcode) seed(112358) : sivqr ln_wage c.age##c.age birth_yr grade (tenure = union wks_work msp) , q(0.75) reps(0)
*
sivqr ln_wage c.age##c.age birth_yr grade (tenure = union wks_work msp) , q(0.5) reps(0) b(0.001)
gen agesq = age^2  // can't use c.age##c.age with other IVQR commands
matrix res = J(3,5,.)
timer clear
timer on 21
sivqr ln_wage age agesq birth_yr grade (tenure = union wks_work msp) , q(0.25) reps(0) b(0.001)
matrix res[1,2] = _b[tenure]
timer off 21
timer on 22
sivqr ln_wage age agesq birth_yr grade (tenure = union wks_work msp) , q(0.50) reps(0) b(0.001)
matrix res[2,2] = _b[tenure]
timer off 22
timer on 23
sivqr ln_wage age agesq birth_yr grade (tenure = union wks_work msp) , q(0.75) reps(0) b(0.001)
matrix res[3,2] = _b[tenure]
timer off 23
*
preserve //just in case ivqreg does something weird
timer on 31
ivqreg ln_wage age agesq birth_yr grade (tenure = union wks_work msp) , q(0.25)
matrix res[1,3] = _b[tenure]
timer off 31
timer on 32
ivqreg ln_wage age agesq birth_yr grade (tenure = union wks_work msp) , q(0.50)
matrix res[2,3] = _b[tenure]
timer off 32
timer on 33
ivqreg ln_wage age agesq birth_yr grade (tenure = union wks_work msp) , q(0.75)
matrix res[3,3] = _b[tenure]
timer off 33
restore
*
timer on 4 // takes 20-30min
ivqreg2 ln_wage tenure age agesq birth_yr grade , q(0.25 0.5 0.75) ///
        inst(union wks_work msp age agesq birth_yr grade)
matrix tmp = e(b_25)
matrix res[1,4] = tmp[1,1]
matrix tmp = e(b_5)
matrix res[2,4] = tmp[1,1]
matrix tmp = e(b_75)
matrix res[3,4] = tmp[1,1]
timer off 4
*
timer on 5
forv i = 1/3 {
 local q = 25*`i'
 cqiv ln_wage age agesq birth_yr grade (tenure = union wks_work msp) , uncensored q(`q')
 matrix tmp = e(results)
 matrix res[`i',5] = tmp[1,1]
}
timer off 5
*
timer list
ivregress 2sls ln_wage c.age##c.age birth_yr grade (tenure = union wks_work msp) , vce(cluster idcode)
matrix res[1,1] = _b[tenure]
matrix res[2,1] = _b[tenure]
matrix res[3,1] = _b[tenure]
*
matrix rownames res = q25 q50 q75
matrix colnames res = 2SLS sivqr ivqreg ivqreg2 cqiv
matrix list res , f(%9.0g)
* ivqreg2 "tenure" Coef est is .017427 vs. .103 (ivqreg) or .108 (sivqr) or 0.106 (2SLS)
* ivqreg2 other coefs also much closer to 0 than sivqr/ivregress/ivqreg, and some differ in sign (like age)
*
* Quadratic (ivqreg cannot handle)
gen tenuresq = tenure^2
gen wks_worksq = wks_work^2
gen unionmsp = union*msp
matrix c = J(3,2,.)
ivregress 2sls ln_wage age agesq birth_yr grade (tenure tenuresq = union wks_work msp wks_worksq unionmsp ) , vce(cluster idcode)
matrix c[1,1] = _b[tenure]
matrix c[1,2] = _b[tenuresq]
timer clear
timer on 1
sivqr ln_wage age agesq birth_yr grade (tenure tenuresq = union wks_work msp wks_worksq unionmsp ) , q(0.5) reps(0) b(0.01)
matrix c[2,1] = _b[tenure]
matrix c[2,2] = _b[tenuresq]
timer off 1
timer on 2
ivqreg2 ln_wage tenure tenuresq age agesq birth_yr grade , q(0.5) inst(age agesq birth_yr grade union wks_work msp wks_worksq unionmsp )
* <<Warning:  variance matrix is nonsymmetric or highly singular>>
* 2329sec = 38min to run...
* tenure=.013 (vs. sivqr=.028, 2sls=.04)  tenuresq=.000745 (vs. sivqr=.014, 2sls=.06)
matrix c[3,1] = _b[tenure]
matrix c[3,2] = _b[tenuresq]
timer off 2
timer list  // sivqr=15s, ivqreg2=2300s>30min
matrix colnames c = tenure tenuresq
matrix rownames c = 2SLS sivqr ivqreg2
matrix list c , f(%9.0g)
twoway function Effect2SLS = c[1,1]*x + c[1,2]*x^2 , range(0  10) ///
    || function Effect50SIVQR = c[2,1]*x + c[2,2]*x^2 , range(0  10) ///
    || function Effect50IVQREG2 = c[3,1]*x + c[3,2]*x^2 , range(0  10)  , name(tenure_quadratic, replace)
*twoway function Effect2SLS = .0391841*x + .006313*x^2 , range(0  10) ///
*    || function EffectSIVQR = .0280227*x + .0137924*x^2 , range(0  10) ///
* 	 || function EffectIVQREG2 = .013*x + .000745*x^2 , range(0  10)  , name(tenure_quad_fixed, replace)


*********
* 3. Example from Chernozhukov and Hansen (2008) / Graddy (1995)
*********
* ! Warning: note the large standard errors (due to small sample size of 111);
*       even economically large differences may not be statistically significant
* Example similar to Section 5.1 of Chernozhukov and Hansen (2008)
* Data from Graddy (1995)
use http://people.brandeis.edu/~kgraddy/datasets/fishdata.dta , clear
ren price lnp
ren qty lnq
* windspd seems to be better instrument than stormy+mixed:
reg lnp windspd // F=21.4
reg lnp stormy mixed // F=15.8
*
* Basic demand elasticity estimates
sivqr lnq (lnp=windspd) , q(0.25) reps(100)
sivqr lnq (lnp=windspd) , q(0.50) reps(100)
sivqr lnq (lnp=windspd) , q(0.75) reps(100)
sivqr lnq (lnp=windspd) , q(0.25) reps(0) b(0)
sivqr lnq (lnp=windspd) , q(0.50) reps(0) b(0)
sivqr lnq (lnp=windspd) , q(0.75) reps(0) b(0)
*
* Compare computation time of bootstrap alternatives
timer clear
timer on 1
sivqr lnq (lnp=windspd) , q(0.50) reps(500) b(0.1)
timer off 1
timer on 2
bootstrap , reps(500) seed(112358) : sivqr lnq (lnp=windspd) , q(0.50) reps(0) b(0.1)
timer off 2
timer list  // 14s vs. 25s; but with b=.00001 then ~same b/c almost all time is from computing estimate, not bootstrap part
*
* Adding day-of-week dummies lower demand elasticity estimates,
*   but same qualitative pattern across quantiles
sivqr lnq (lnp=windspd) day1-day4 , q(0.25) reps(100)
sivqr lnq (lnp=windspd) day1-day4 , q(0.50) reps(100)
sivqr lnq (lnp=windspd) day1-day4 , q(0.75) reps(100)


*********
* 4. 401(k) example from Chernozhukov and Hansen (2004)
*********
* 401(k) data similar to  Chernozhukov and Hansen (2004)
bcuse 401ksubs , clear
gen inccat = (inc>=10)+(inc>=20)+(inc>=30)+(inc>=40)+(inc>=50)+(inc>=75)
gen agecat = (age>=30)+(age>=36)+(age>=45)+(age>=55)
* Use controls from CH04 if available
* CH04: <<X consists of dummies for income category, dummies for age category, dummies for education category, a marital status indicator, family size, two-earner status, DB pension status, IRA participation status, homeownership status, and a constant.>>
sivqr nettfa i.inccat age marr fsize (p401k = e401k) , q(0.5) reps(0)
sivqr nettfa i.inccat age marr fsize (p401k = e401k) , q(0.5) reps(0) b(0.1)
*sivqr nettfa i.inccat age marr fsize (p401k = e401k) , q(0.5) reps(20) b(1)
bootstrap , reps(20) seed(112358) : sivqr nettfa i.inccat age marr fsize (p401k = e401k) , q(0.5) reps(0) b(1)
matrix res = J(9,5,.)
timer clear
timer on 1
forv i = 1/9 {
  local q = `i'/10
  sivqr nettfa i.inccat age marr fsize (p401k = e401k) , reps(0) b(0.1) q(`q')
  matrix tmp = e(b)
  matrix res[`i',1] = tmp[1,1]
}
timer off 1
*
forv i = 2/6 {
 gen dinccat`i' = (inccat==`i')  // for other commands
}
timer on 2
* Note: dinccat* causes ivqreg output rows to have wrong labels
forv i = 1/9 {
  local q = `i'/10
  qui ivqreg nettfa dinccat* age marr fsize (p401k = e401k) , q(`q')
  matrix tmp = e(b)
  matrix res[`i',2] = tmp[1,1]
}
timer off 2
timer on 3
ivqreg2 nettfa p401k dinccat* age marr fsize , q(.1 .2 .3 .4 .5 .6 .7 .8 .9) ///
        inst(dinccat* age marr fsize e401k)
* "WARNING: some fitted values of the scale function are negative"
matrix tmp = e(b_1)
matrix res[1,3] = tmp[1,1]
matrix tmp = e(b_2)
matrix res[2,3] = tmp[1,1]
matrix tmp = e(b_3)
matrix res[3,3] = tmp[1,1]
matrix tmp = e(b_4)
matrix res[4,3] = tmp[1,1]
matrix tmp = e(b_5)
matrix res[5,3] = tmp[1,1]
matrix tmp = e(b_6)
matrix res[6,3] = tmp[1,1]
matrix tmp = e(b_7)
matrix res[7,3] = tmp[1,1]
matrix tmp = e(b_8)
matrix res[8,3] = tmp[1,1]
matrix tmp = e(b_9)
matrix res[9,3] = tmp[1,1]
timer off 3
timer on 4
forv i = 1/9 {
  local q = `i'/10
  qui ivqte nettfa (p401k = e401k) , q(`q') c(age fsize) d(dinccat* marr) aai
  matrix res[`i',4] = _b[p401k]
}
timer off 4
timer on 5
ivqte nettfa (p401k = e401k) , q(.1 .2 .3 .4 .5 .6 .7 .8 .9) c(age fsize) ///
      d(dinccat* marr)
matrix tmp = e(b)
forv i = 1/9 {
  matrix res[`i',5] = tmp[1,`i']
}
timer off 5
timer list  // sivqr<1min, ivqreg2>1hr
matrix rownames res = q10 q20 q30 q40 q50 q60 q70 q80 q90
matrix colnames res = sivqr ivqreg ivqreg2 ivqteAAI ivqte
matrix list res , f(%9.0g)
* sivqr pretty much matches CH04, despite different control variables
* ivqreg2: *negative* p401k coef for q<=0.6
*
* Without controls (just for illustration purposes), sivqr similar to ivqte
*   (and both fast ~1s runtime)
timer clear
matrix res = J(9,3,.)
timer on 11
forv i = 1/9 {
  local q = `i'/10
  sivqr nettfa (p401k = e401k) , reps(0) b(0.1) q(`q')
  matrix res[`i',1] = _b[p401k]
}
timer off 11
timer on 21
forv i = 1/9 {
  local q = `i'/10
  qui ivqte nettfa (p401k = e401k) , q(`q') aai
  matrix res[`i',2] = _b[p401k]
}
timer off 21
timer on 31
ivqte nettfa (p401k=e401k) , q(.1 .2 .3 .4 .5 .6 .7 .8 .9)
matrix tmp = e(b)
forv i = 1/9 {
  matrix res[`i',3] = tmp[1,`i']
}
timer off 31
timer list
matrix rownames res = q10 q20 q30 q40 q50 q60 q70 q80 q90
matrix colnames res = sivqr ivqteAAI ivqte
matrix list res , f(%9.0g)


*********
* 5. Alcohol Engel curve (budget share vs. total expenditure)
*********
set more off
*ssc describe cqiv
capture net get cqiv  // gets alcoholengel.dta if you don't have it already
use alcoholengel.dta , clear
* Linear
matrix res = J(5,5,.)
matrix rownames res = q50 q60 q70 q80 q90
matrix colnames res = cqiv1 cqiv2 sivqr ivqreg ivqreg2
timer clear
timer on 1
forv i = 1/5 {
 local q = 10*(4+`i')
 qui cqiv alcohol nkids (logexp = logwages nkids ) , uncensored q(`q')
 matrix tmp = e(results)
 matrix res[`i',1] = tmp[1,1]
}
timer off 1
timer on 2
forv i = 1/5 {
 local q = 10*(4+`i')
 qui cqiv  alcohol nkids (logexp = logwages nkids ) , q(`q')
 matrix tmp = e(results)
 matrix res[`i',2] = tmp[1,1]
}
timer off 2
matrix list res , f(%9.0g)
*
timer on 3
forv i = 1/5 {
 local q = (4+`i')/10
 qui sivqr alcohol nkids (logexp = logwages ), q(`q') b(0) reps(0)
 matrix res[`i',3] = _b[logexp]
}
timer off 3
*
timer on 4
forv i = 1/5 {
 local q = (4+`i')/10
 qui ivqreg alcohol nkids (logexp = logwages ), q(`q')
 matrix res[`i',4] = _b[logexp]
}
timer off 4
matrix list res , f(%9.0g)
*
timer on 5
ivqreg2 alcohol logexp nkids , q(.5 .6 .7 .8 .9) inst(logwages nkids)
* "WARNING: some fitted values of the scale function are negative"
matrix tmp = e(b_5)
matrix res[1,5] = tmp[1,1]
matrix tmp = e(b_6)
matrix res[2,5] = tmp[1,1]
matrix tmp = e(b_7)
matrix res[3,5] = tmp[1,1]
matrix tmp = e(b_8)
matrix res[4,5] = tmp[1,1]
matrix tmp = e(b_9)
matrix res[5,5] = tmp[1,1]
timer off 5
*
timer list // mostly <10s, ivqreg<1min, ivqreg2=several minutes
matrix list res , f(%8.0g)
* sivqr very close to ivqreg; cqiv somewhat close & same qualitative pattern
* ivqreg2 is also pretty close, despite the WARNINGs & computation time
*
* Quadratic for q(0.7)
gen logwages2 = logwages^2
matrix res = J(3,4,.)
timer on 6
sivqr alcohol nkids (logexp logexp2 = logwages logwages2 ), q(0.7) b(0) reps(0)
matrix res[1,1] = _b[_cons]
matrix res[2,1] = _b[logexp]
matrix res[3,1] = _b[logexp2]
timer off 6
timer on 7
ivqreg2 alcohol logexp logexp2 nkids , q(0.7) inst(logwages logwages2 nkids) // no warning
matrix res[1,2] = _b[_cons]
matrix res[2,2] = _b[logexp]
matrix res[3,2] = _b[logexp2]
timer off 7
timer on 8
cqiv  alcohol logexp2 nkids (logexp = logwages nkids), q(70) no // from cqiv help
matrix tmp = e(results)
matrix res[1,3] = tmp[4,1]  // _cons
matrix res[2,3] = tmp[1,1]
matrix res[3,3] = tmp[2,1]
timer off 8
timer on 9
cqiv  alcohol logexp2 nkids (logexp = logwages nkids), q(70) uncensored
matrix tmp = e(results)
matrix res[1,4] = tmp[4,1]  // _cons
matrix res[2,4] = tmp[1,1]
matrix res[3,4] = tmp[2,1]
timer off 9
timer list // a few seconds, except ivqreg2>1min
qui _pctile logexp , p(5 95)
twoway function sivqr   = res[1,1] + x*res[2,1] + x^2*res[3,1] , range(`=r(r1)'  `=r(r2)') ///
    || function ivqreg2 = res[1,2] + x*res[2,2] + x^2*res[3,2] , range(`=r(r1)'  `=r(r2)') ///
    || function cqiv    = res[1,3] + x*res[2,3] + x^2*res[3,3] , range(`=r(r1)'  `=r(r2)') ///
    || function cqiv_un  = res[1,4] + x*res[2,4] + x^2*res[3,4]  , range(`=r(r1)'  `=r(r2)')  , name(Engel_comp, replace)
* ivqreg2 is flat; others are concave, show changing elasticities:
matrix elast = J(3,4,.)
qui _pctile logexp , p(25 50 75)
forv i = 1/3 {
 local x = r(r`i')
 forv j = 1/4 {
  matrix elast[`i',`j'] = res[2,`j'] + 2*`x'*res[3,`j']
 }
}
matrix rownames elast = logexp25 logexp50 logexp75
matrix colnames elast = sivqr ivqreg2 cqiv cqiv_un
matrix elast = elast[1..3,3..4],elast[1..3,1],elast[1..3,2]
matrix list elast , f(%9.0g)
*twoway function sivqr = -1.307045 + x*.5224469 + x^2*-.0483395 , range(`=r(r1)'  `=r(r2)') ///
*    || function cqiv = -1.04864  + x*.4126798 + x^2*-.0370653 , range(`=r(r1)'  `=r(r2)') ///
*    || function cqivUN = -.6151476  + x*.2569172 + x^2*-.0231528 , range(`=r(r1)'  `=r(r2)') ///
*    || function ivqreg2 = .0804712+ x*.0001759 + x^2*.0000154  , range(`=r(r1)'  `=r(r2)')  , name(Engel_comp_fixed, replace)


*********
* 6. More on computation time
*********
set more off
* Time across quantile levels (code mostly from referee)
webuse nlswork , clear
mat drop _all
forvalues p = 2/18 {
 local i = `p'/20
 timer clear
 timer on 1
 sivqr ln_wage c.age##c.age birth_yr grade (tenure = union wks_work msp) , q(`i') r(0)
 timer off 1
 timer on 2
 sivqr ln_wage c.age##c.age birth_yr grade (tenure = union wks_work msp) , q(`i') r(0) b(0.005)
 timer off 2
 timer list
 mat timer=nullmat(timer) \ (`i'),r(t1),r(t2)
}
clear
svmat timer
list
su timer2 timer3 , d
tw con timer2 timer1, xtitle(Quantile) ytitle(Seconds) , name(time_by_q, replace)
tw  con timer2 timer1, xtitle(Quantile) ytitle(Seconds) ///
 || con timer3 timer1, xtitle(Quantile) ytitle(Seconds) , name(time_by_q2, replace)


* Sensitivity to seed (code mostly from referee)
set more off
webuse nlswork , clear
mat drop _all
set seed 9595864  // suggested by referee, so not my usual 112358
forvalues i=1/100 {
 cap drop randomseed
 gen double randomseed= round((86425647-1)*runiform() + 1)
 local nr=randomseed[10]
 *di `nr'
 timer clear
 timer on 1
 qui sivqr ln_wage c.age##c.age birth_yr grade (tenure = union wks_work msp) ///
    , q(0.50) r(20) seed(`nr')
 timer off 1
 local b = e(bwidth)
 qui timer list
 local se1 = _se[tenure]
 mat tmp = (`i'),(`nr'),r(t1),(`se1'),.,.
 if (`i'<=5) {
  timer on 2
  qui bootstrap , reps(20) seed(`nr') : sivqr ln_wage c.age##c.age birth_yr grade (tenure = union wks_work msp) , q(0.50) r(0) b(`b')
  timer off 2
  qui timer list
  local se2 = _se[tenure]
  mat tmp = (`i'),(`nr'),r(t1),(`se1'),r(t2),(`se2')
 }
 mat timer=nullmat(timer) \ tmp
 mat l tmp , noheader nonames
}
local defaults
forv i = 1/5 {
 timer clear 99
 timer on 99
 qui sivqr ln_wage c.age##c.age birth_yr grade (tenure = union wks_work msp) , q(0.50) r(20)
 timer off 99
 qui timer list
 local defaults = "`defaults' `r(t99)'"
}
clear
svmat timer
ren timer3 sivqr
ren timer5 bootstrap
twoway kdensity sivqr, xtitle(Seconds) xline(`defaults') ///
    || kdensity bootstrap, xtitle(Seconds) xline(`defaults') , name(time_by_seed , replace)
su sivqr boot , d
di "`defaults'"



*********
* 7. A simple graph
*********
set more off
webuse hsng2 , clear
capture matrix drop res
local varname hsngval
local lev = 90
forv q=10(10)90 {
  sivqr rent pcturban (hsngval = faminc i.region), q(`q') reps(20) level(`lev')
  matrix r = r(table)
  matrix r3 = `q' , r["b","`varname'"] , r["ll","`varname'"] , r["ul","`varname'"]
  matrix res = nullmat(res) \ r3
  matrix list res
}
matrix colnames res = q  est  lowerCI  upperCI
preserve
clear
svmat res , names(col)
line est lowerCI upperCI q , lpattern(solid dash dash) lstyle(p1 p2 p2) ytitle(`varname') legend(order(1 "Estimate" 2 "Pointwise `lev'% CI"))
restore

* End of file
