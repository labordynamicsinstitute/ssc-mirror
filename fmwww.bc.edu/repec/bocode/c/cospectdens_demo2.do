
// cospectden demo 2
// average housing prices (from Stata manual) 

use "http://www.stata-press.com/data/r12/txhprice", clear
tsset t
gen d_dallas = d.dallas
gen d_houston = d.houston

cospectdens d_dallas d_houston, conv(4 3 2) out(cospectex2) replace 

use cospectex2, clear
graph drop _all
tw (connected Spdensy naturalfreq), name(_g1)
tw (connected Spdensx naturalfreq), name(_g2)
tw (connected Cospect naturalfreq), name(_g3)
tw (connected Cohsq naturalfreq) (line  Cohsq_threshold naturalfreq), name(_g4)
graph combine _g1 _g2 _g3 _g4

// graph phase spectrum
tw  (rarea  phase_L phase_U naturalfreq, cmissing(no) astyle(ci) legend(label(1 "95% CI"))) ///
 (line Phase naturalfreq, cmissing(no) legend(label(2 "Phase Spectrum"))), legend(order(2 1))
