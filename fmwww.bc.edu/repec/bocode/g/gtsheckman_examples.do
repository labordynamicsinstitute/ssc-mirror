* Examples of gtsheckman.ado
* Need version 11.0 to run Examples 1 and 2, and version 15.0 to run example 3
* To install:
*	download gtsheckman.ado at https://carlsonah.mufaculty.umsystem.edu/research 

clear all
program drop _all
set more off
set linesize 80
cls
version 11.0 // make sure it is version 11.0 or higher
capture log close
log using gtsheckman_examples.log, replace

***** Example 1 *****
*********************
* Upload data
use http://fmwww.bc.edu/ec-p/data/wooldridge/mroz, clear
* use gtsheckman command
gtsheckman lwage educ exper expersq, select(inlf = educ exper expersq age nwifeinc kidslt6 kidsge6)
* gtsheckman estimates are identical to the following two step Heckman estimates
heckman lwage educ exper expersq, select(inlf = educ exper expersq age nwifeinc kidslt6 kidsge6) twostep
* gtsheckman can obtain robust standard errors for the two step Heckman estimator
gtsheckman lwage educ exper expersq, select(inlf = educ exper expersq age nwifeinc kidslt6 kidsge6) vce(robust)

***** Example 2 *****
*********************
* Introduce heteroskedasticity in first stage
gtsheckman lwage educ exper expersq, select(inlf = educ exper expersq age nwifeinc kidslt6 kidsge6) het(educ kidslt6 kidsge6) vce(robust)
* to allow for a more general conditional covariance function, specify CLP function 
gtsheckman lwage educ exper expersq, select(inlf = educ exper expersq age nwifeinc kidslt6 kidsge6) het(educ kidslt6 kidsge6) clp(educ kidslt6 kidsge6) vce(robust)

***** Example 3 *****
*********************
* Generate Data
clear
set seed  1234
set obs 10000
gen id = _n
mat V =	(.5 , 0 ,.25, 0 , 0 \ ///
	  0 , 1 , 0 ,.5 ,.5 \ ///
	 .25, 0 ,.5 , 0 , 0 \ ///
	  0 ,.5 , 0 , 1 , 0 \ ///		 
	  0 ,.5 , 0 , 0 , 1 )
drawnorm b0 b1 c0 c1 c2, cov(V) means(0,1,-2,1,1)
expand 5
bysort id: generate year = _n
gen x1 = rnormal()>0
gen x2 = 3*runiform()
drawnorm u1 u2, cov(.5, .3 \ .3, .5) means(0,0)
gen sstar =  c0 + x1*c1 + x2*c2 + u2
gen s = (sstar>0)
gen y=  b0 + x1*b1 + u1
replace  y=. if s==0
xtset id year
* Two step Heckman estimates are biased
heckman y x1, select(s = x1 x2) twostep
* Generalized two step Heckman estimates are unbiased
timer clear
timer on 1
gtsheckman y x1, select(s = x1 x2) clp(x1 x2 i.x1#c.x2) het(x1 x2 c.x2#c.x2 i.x1#c.x2) vce(cluster id)
timer off 1
* Random effects Heckman estimates are also biased
* NEED Stata version 15.0 to run
capture version 15.0
scalar rc = 0
if _rc!=0{
	display as error "Needs version 15.0 to run"
	scalar rc = rc+1
}
timer on 2
capture noisily xtheckman y x1, select(s = x1 x2) intmethod(ghermite) intpoints(3) vce(cluster id)
timer off 2
if _rc!=0{
	display as error "Update Stata for xtheckman command"
	scalar rc = rc+1
}
if rc==0{
	timer list
}
*Create RCsampleselection program to simulate the above example multiple times
capture program drop RCsampleselection
program define RCsampleselection, rclass
drop _all
set obs 10000
gen id = _n
mat V =	(.5 , 0 ,.25, 0 , 0 \ ///
	  0 , 1 , 0 ,.5 ,.5 \ ///
	 .25, 0 ,.5 , 0 , 0 \ ///
	  0 ,.5 , 0 , 1 , 0 \ ///		 
	  0 ,.5 , 0 , 0 , 1 )
drawnorm b0 b1 c0 c1 c2, cov(V) means(0,1,-2,1,1)
expand 5
bysort id: generate year = _n
gen x1 = rnormal()>0
gen x2 = 3*runiform()
drawnorm u1 u2, cov(.5, .3 \ .3, .5) means(0,0)
gen sstar =  c0 + x1*c1 + x2*c2 + u2
gen s = (sstar>0)
gen y=  b0 + x1*b1 + u1
replace  y=. if s==0
xtset id year
gtsheckman y x1, select(s = x1 x2) vce(cluster id)
return scalar b_heckman = [y]_b[x1]
gtsheckman y x1, select(s = x1 x2) clp(x1 x2 i.x1#c.x2) het(x1 x2 c.x2#c.x2 i.x1#c.x2) vce(cluster id)
return scalar b_gtsheckman = [y]_b[x1]
capture xtheckman y x1, select(s = x1 x2) intmethod(ghermite) intpoints(3) vce(cluster id)
if _rc!=0{
return scalar b_xtheckman = 0
}
else{
return scalar b_xtheckman = [y]_b[x1]
}
end
* Test program
RCsampleselection
* Simulate 100 times and report summary
simulate b_heckman = r(b_heckman) b_gtsheckman = r(b_gtsheckman) b_xtheckman = r(b_xtheckman), reps(100) seed(1234): RCsampleselection
sum b_heckman b_gtsheckman b_xtheckman

* End of file

log close