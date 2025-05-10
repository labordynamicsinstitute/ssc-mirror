* Example of Placebo Tests for Standard DID 
* The effects of the abandonment of China's Grand Canal (Cao and Chen, 2022)

* ssc install didplacebo, all replace
* ssc install reghdfe, all replace 

* TWFE Estimation
use cao_chen.dta, clear
xtset county year
reghdfe rebel canal_post, absorb(i.county i.year) cluster(county) 
estimates store did_cao_chen

* In-time placebo test with fake treatment time shifted back by 1-10 periods
didplacebo did_cao_chen, treatvar(canal_post) pbotime(1(1)10) 

* In-space placebo test
didplacebo did_cao_chen, treatvar(canal_post) pbounit rep(500) seed(1)

* Mixed placebo test 
didplacebo did_cao_chen, treatvar(canal_post) pbomix(1) seed(1)