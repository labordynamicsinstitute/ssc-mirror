* test_rardl.do — Test all rardl commands
* Requires: commodity_data.xlsx in the same folder

clear all
set more off
adopath + "c:\Users\HP\Documents\xtpmg\roll"
discard

* Load commodity price data
import excel "c:\Users\HP\Documents\xtpmg\roll\commodity_data.xlsx", firstrow clear
gen t = tm(1960m1) + _n - 1
format t %tm
tsset t, monthly

di ""
di "=============================================="
di " TEST 1: Rolling ARDL (oil ~ silver)"
di "=============================================="
rardl oil silver, type(rolling) case(3) wsize(60) maxlag(4) nsim(500) seed(123)

di ""
di "=============================================="
di " TEST 2: Recursive ARDL (oil ~ silver)"
di "=============================================="
rardl oil silver, type(recursive) case(3) initobs(60) maxlag(4) nsim(500) seed(123)

di ""
di "=============================================="
di " TEST 3: Recursive ADF (oil)"
di "=============================================="
rardl oil, type(radf) initobs(60) maxlag(4) adfcase(3) transform(level)

di ""
di "=============================================="
di " TEST 4: Recursive Granger (oil ~ silver)"
di "=============================================="
rardl oil silver, type(rgranger) initobs(60) maxlag(4)

di ""
di "=============================================="
di " TEST 5: Monte Carlo Simulation"
di "=============================================="
rardl oil silver, type(simulate) nsim(500) maxlag(4) seed(999)

di ""
di "=============================================="
di " ALL TESTS COMPLETE"
di "=============================================="
