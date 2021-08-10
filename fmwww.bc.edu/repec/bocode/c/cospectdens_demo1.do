// cospectdens demo1

// 1st ex. y(t) = x(t-4) + e
clear 
set obs 550 
gen x = rnormal()
gen t = _n
tsset t 
gen y = 0
replace y = x[t-4]+rnormal() in 5/`r(tmax)'
keep in 51/550

// user-supplied weights
cospectdens y x, w(1 2 3 <4> 3 2 1)  

// convolution of two Daniell weights with lags 5 and 2
cospectdens y x, conv(5 2) out(cospectex) replace 

// graph phase spectrum
use cospectex, clear
tw  (rarea  phase_L phase_U naturalfreq, cmissing(no) astyle(ci) legend(label(1 "95% CI"))) ///
 (line Phase naturalfreq, cmissing(no) legend(label(2 "Phase Spectrum"))), legend(order(2 1))
