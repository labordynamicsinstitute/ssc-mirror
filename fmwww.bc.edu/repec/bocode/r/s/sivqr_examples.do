* Examples of sivqr.ado:
* 1. ^Example 4 from ivregress (wage/tenure)
* 2. ^More on computation time
* 3. A simple graph
* 4. Wooldridge examples
* ^detailed in Stata Journal article

* To install:
*net from https://kaplandm.github.io/stata
*net describe sivqr
*net install sivqr
*net get sivqr


* Specify directory w/ sivqr.ado (if not already in a standard directory; use command
*    sysdir   to check standard directories.

*.tex output:  sjlog do sivqr_examples , clear replace


version 17.0
clear all
program drop _all
set more off
set linesize 80
cls


* To install other commands/data:
ssc install bcuse , replace
*ivqregdec (Dec. 2010 version): manually from https://sites.google.com/site/dwkwak/dataset-and-code
capture do ivqregdec.mata // create .mlib
*ivqreg is July 2010 version; works better in most ways, not all
ssc install ivqreg2 , replace

* Version info
version
which sivqr
which ivregress
which ivqreg
which ivqreg2


*********
* 1. Example 4 from ivregress
*********
* https://www.stata.com/manuals13/rivregress.pdf
webuse nlswork , clear
matrix res = J(3,5,.)
*
ivregress 2sls ln_wage c.age##c.age birth_yr grade (tenure = union wks_work msp) , vce(cluster idcode)
matrix res[1,1] = _b[tenure]
matrix res[2,1] = _b[tenure]
matrix res[3,1] = _b[tenure]
*
// newid/bootstrap: see https://www.stata.com/support/faqs/statistics/bootstrap-with-panel-data/
generate newid = idcode
xtset newid year
*
// other IVQR commands don't support c.age##c.age, so:
generate agesq = age^2
timer clear
* first with plug-in bandwidth (default/recommended)
timer on 20 // under 1 min total
forvalues i = 1/3 {
  local q = `i'/4
  timer on 2`i'
  sivqr ln_wage age agesq birth_yr grade (tenure = union wks_work msp) , quantile(`q')
  matrix res[`i',2] = _b[tenure]
  timer off 2`i'
}
timer off 20
* now with bandwidth(0)
timer on 30 // total ~ 7 minutes (4+1+2)
forvalues i = 1/3 {
  local q = `i'/4
  timer on 3`i'
  sivqr ln_wage age agesq birth_yr grade (tenure = union wks_work msp) , quantile(`q') bandwidth(0)
  matrix res[`i',3] = _b[tenure]
  timer off 3`i'
}
timer off 30
*
* ~ 5-10 minutes total for these three ivqreg calls
preserve //just in case ivqreg does something weird
* newest version gets error for over-identified model
capture noisily ivqregdec ln_wage age agesq birth_yr grade (tenure = union wks_work msp) , q(0.50) robust
timer on 40
forvalues i = 1/3 {
  local q = `i'/4
  timer on 4`i'
  capture noisily ivqreg ln_wage age agesq birth_yr grade (tenure = union wks_work msp) , q(`q') robust
  matrix res[`i',4] = _b[tenure]
  timer off 4`i'
}
timer off 40
restore
*
timer on 50 // ~ 2000s ~ 30min for me
ivqreg2 ln_wage tenure age agesq birth_yr grade , quantile(0.25 0.5 0.75) instruments(union wks_work msp age agesq birth_yr grade)
matrix tmp = e(b_25)
matrix res[1,5] = tmp[1,1]
matrix tmp = e(b_5)
matrix res[2,5] = tmp[1,1]
matrix tmp = e(b_75)
matrix res[3,5] = tmp[1,1]
timer off 50
*
matrix rownames res = q25 q50 q75
matrix colnames res = 2SLS sivqr sivqr0 ivqreg ivqreg2
timer list
matrix list res , f(%9.0g)
* q0.25: sivqr~ivqreg < 95%CI from ivqreg2 (albeit barely)
* q0.50: all similar (& similar to 2SLS)
* q0.75: sivqr~ivqreg > 95%CI from ivqreg2
* not order of magnitude different, but a few percentage points
*
* cluster bootstrap with sivqr (same est, new std err)
ivregress 2sls ln_wage c.age##c.age birth_yr grade (tenure = union wks_work msp) , vce(cluster idcode)
timer on 17 // ~ 25 minutes total
bootstrap , reps(100) cluster(idcode) idcluster(newid) seed(112358) : sivqr ln_wage c.age##c.age birth_yr grade (tenure = union wks_work msp) , quantile(0.25)
timer off 17
timer on 18 // ~ 10-15 minutes total
bootstrap , reps(100) cluster(idcode) idcluster(newid) seed(112358) : sivqr ln_wage c.age##c.age birth_yr grade (tenure = union wks_work msp) , quantile(0.50)
timer off 18
timer on 19 // ~ 25-30 minutes total
bootstrap , reps(100) cluster(idcode) idcluster(newid) seed(112358) : sivqr ln_wage c.age##c.age birth_yr grade (tenure = union wks_work msp) , quantile(0.75)
timer off 19
timer list
*
* double-check timing/estimate when re-order ivqreg2 regressors (see mroz example below)
timer on 5 // similar to before, ~ 30 minutes
ivqreg2 ln_wage age agesq birth_yr grade tenure , quantile(0.25 0.5 0.75) instruments(union wks_work msp age agesq birth_yr grade)
* WARNING: .03758389% of the fitted values of the scale function are not positive
* Warning:  variance matrix is nonsymmetric or highly singular
* [no Std. Err. reported]
* [tenure estimates now negative; other differences]
timer off 5
timer list



*********
* 2. More on computation time
*********
set more off
* Time across quantile levels (code mostly from referee)
webuse nlswork , clear
mat drop _all
forvalues p = 2/18 {
 local i = `p'/20
 timer clear
 timer on 1
 sivqr ln_wage c.age##c.age birth_yr grade (tenure = union wks_work msp) , quantile(`i')
 timer off 1
 timer on 2
 sivqr ln_wage c.age##c.age birth_yr grade (tenure = union wks_work msp) , quantile(`i') bandwidth(0)
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
matrix drop _all
set seed 9595864  // suggested by referee, so not my usual 112358
forvalues i=1/100 {
 capture drop randomseed
 generate double randomseed = round((86425647-1)*runiform() + 1)
 local nr = randomseed[10]
 timer clear
 timer on 1
 quietly sivqr ln_wage c.age##c.age birth_yr grade (tenure = union wks_work msp) , quantile(0.50) seed(`nr') reps(20)
 timer off 1
 local b = e(bwidth)
 quietly timer list
 local se1 = _se[tenure]
 matrix tmp = (`i'),(`nr'),r(t1),(`se1'),.,.
 if (`i'<=5) {
  timer on 2
  quietly bootstrap , reps(20) seed(`nr') : sivqr ln_wage c.age##c.age birth_yr grade (tenure = union wks_work msp) , quantile(0.50) bandwidth(`b')
  timer off 2
  quietly timer list
  local se2 = _se[tenure]
  matrix tmp = (`i'),(`nr'),r(t1),(`se1'),r(t2),(`se2')
 }
 matrix timer = nullmat(timer) \ tmp
 matrix list tmp , noheader nonames
}
local defaults
forvalues i = 1/5 {
 timer clear 99
 timer on 99
 quietly sivqr ln_wage c.age##c.age birth_yr grade (tenure = union wks_work msp) , quantile(0.50)
 timer off 99
 quietly timer list
 local defaults = "`defaults' `r(t99)'"
}
clear
svmat timer
rename timer3 sivqr20reps
rename timer5 bootstrap20reps
twoway kdensity sivqr20reps, xtitle(Seconds) xline(`defaults') || kdensity bootstrap20reps, xtitle(Seconds) xline(`defaults') , name(time_by_seed , replace)
summarize sivqr20reps bootstrap20reps , detail
display "reps(0) times: `defaults'"



*********
* 3. A simple graph (using Example 1 from ivregress)
*********
set more off
webuse hsng2 , clear
capture matrix drop res
local varname hsngval
local lev = 90
forvalues q=10(10)90 {
  capture sivqr rent pcturban (hsngval = faminc i.region), quantile(`q') reps(20) level(`lev')
  matrix r = r(table)
  matrix r3 = `q' , r["b","`varname'"] , r["ll","`varname'"] , r["ul","`varname'"]
  matrix res = nullmat(res) \ r3
  // matrix list res
}
matrix colnames res = q  est  lowerCI  upperCI
matrix list res
preserve
clear
svmat res , names(col)
line est lowerCI upperCI q , lpattern(solid dash dash) lstyle(p1 p2 p2) ytitle(`varname') legend(order(1 "Estimate" 2 "Pointwise `lev'% CI"))
restore



*********
* 4. Examples from Wooldridge's intro text
*********
* http://fmwww.bc.edu/gstat/examples/wooldridge/wooldridge15.html

* Ex 15.4
* bigger cross-quantile differences with sivqr/ivqreg than ivqreg2
* ivqreg2 slower, esp. vs. plug-in sivqr
use http://fmwww.bc.edu/ec-p/data/wooldridge/card , clear
timer clear
ivregress 2sls lwage (educ = nearc4 ) exper expersq black smsa south , robust noheader
matrix res = e(b)'
matrix res = res,J(rowsof(res),4,.)
matrix colnames res = 2sls ivqreg sivqr0 sivqr ivqreg2
*estat overid
forvalues i = 3/7 {
 matrix res`i' = res
 local q = `i'/10
 preserve
 timer on 1`i'
 ivqreg lwage exper expersq black smsa south (educ = nearc4) , q(`q') robust
 matrix res`i'[1,2] = e(b)'
 timer off 1`i'
 restore
 timer on 2`i'
 sivqr lwage (educ = nearc4 ) exper expersq black smsa south , bandwidth(0) quantile(`q')
 matrix res`i'[1,3] = e(b)'
 timer off 2`i'
 timer on 3`i'
 sivqr lwage (educ = nearc4 ) exper expersq black smsa south , quantile(`q')
 matrix res`i'[1,4] = e(b)'
 timer off 3`i'
}
timer on 4
ivqreg2 lwage educ exper expersq black smsa south , quantile(.1 .2 .3 .4 .5 .6 .7 .8 .9) instruments(nearc4 exper expersq black smsa south)
forvalues i = 3/7 {
 matrix res`i'[1,5] = e(b_`i')'
}
timer off 4
forvalues i = 3/7 {
 matrix list res`i' , f(%9.0g)
}
matrix educ = res3[1,1..5]
forvalues i = 4/7 {
 matrix educ = educ \ res`i'[1,1..5]
}
matrix rownames educ = q30 q40 q50 q60 q70
matrix list educ , f(%7.0g)
timer list
*
* sivqr allows weights
* at q=.5, similarly larger educ coeff as 2sls with weights
sivqr lwage (educ = nearc4 ) exper expersq black smsa south [pw=weight] , quantile(0.5)
ivregress 2sls lwage (educ = nearc4 ) exper expersq black smsa south [pw=weight] , robust noheader
* "weights not allowed": ivqreg2 lwage educ exper expersq black smsa south [pw=weight] , quantile(0.5) instruments(nearc4 exper expersq black smsa south)

* Ex 15.5
* all fast; differences are economically but not statistically significant
use http://fmwww.bc.edu/ec-p/data/wooldridge/mroz , clear
ivregress 2sls lwage (educ = motheduc fatheduc) exper expersq , robust noheader
matrix res = e(b)'
matrix res = res,J(rowsof(res),3,.)
matrix colnames res = 2sls ivqreg sivqr ivqreg2
estat overid // p=0.51
forvalues i = 1/4 {
 local q = `i'/5
 timer clear
 preserve
 timer on 1
 ivqreg lwage exper expersq (educ = motheduc fatheduc) , q(`q') robust
 matrix res[1,2] = e(b)'
 timer off 1
 restore
 timer on 2
 sivqr lwage (educ = motheduc fatheduc) exper expersq , bandwidth(0) quantile(`q')
 capture matrix res[1,3] = e(b)'
 timer off 2
 timer on 3
 ivqreg2 lwage educ exper expersq , quantile(`q') instruments(motheduc fatheduc exper expersq)
 capture matrix res[1,4] = e(b)'
 timer off 3
 timer list
 matrix list res , f(%9.0g)
}
* beware, if you change the order of regressors (here, move educ to end):
*   the runtime can be *much* longer
*   the coefficient estimates can be *much* different
*   but...not true for every model/dataset, sometimes change is negligible (like fishdata.dta)
timer on 4 // much slower (minutes, instead of seconds above)
ivqreg2 lwage exper expersq educ , quantile(.25 .5 .75) instruments(exper expersq motheduc fatheduc)
* WARNING: 7.0093458% of the fitted values of the scale function are not positive
* ...and very different estimates (like negative educ coeff for q=.75)
timer off 4
timer list


* Isolating the regressor-order-changing phenomenon:
* fast (educ 1st), then slow (educ last)
*use http://fmwww.bc.edu/ec-p/data/wooldridge/mroz , clear
*ivqreg2 lwage educ exper expersq , quantile(.25 .5 .75) instruments(exper expersq motheduc fatheduc)
*ivqreg2 lwage exper expersq educ , quantile(.25 .5 .75) instruments(exper expersq motheduc fatheduc)


* End of file
