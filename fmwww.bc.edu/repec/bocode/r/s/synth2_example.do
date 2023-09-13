cscript
log using example.log, replace

set linesize 80
set scheme sj

use smoking, clear
xtset state year

******************************************************************************
* Replicate results in Abadie, Diamond, and Hainmueller (2010)
synth2 cigsale lnincome age15to24 retprice beer cigsale(1988) cigsale(1980) cigsale(1975), trunit(3) trperiod(1989) xperiod(1980(1)1988) nested allopt

* Implement in-space placebo test using fake treatment units with pre-treatment MSPE 2 times smaller than or equal to that of the treated unit
* For illustration, we drop the "allopt" option to save time. The "allopt" option is recommended for the most accurate results if time permits.
* To assure convergence, we change the default option "sigf(7)" (7 significant figures) to "sigf(6)".
synth2 cigsale lnincome age15to24 retprice beer cigsale(1988) cigsale(1980) cigsale(1975), trunit(3) trperiod(1989) xperiod(1980(1)1988) nested placebo(unit cut(2)) sigf(6)

* Implement in-time placebo test using the fake treatment time 1985 and dropping the covariate cigsale(1988)
synth2 cigsale lnincome age15to24 retprice beer cigsale(1980) cigsale(1975), trunit(3) trperiod(1989) xperiod(1980(1)1984) nested placebo(period(1985))

* Implement leave-one-out robustness test, create a Stata frame "california" storing generated variables, and save all produced graphs to the current path
synth2 cigsale lnincome age15to24 retprice beer cigsale(1988) cigsale(1980) cigsale(1975), trunit(3) trperiod(1989) xperiod(1980(1)1988) nested loo frame(california) savegraph(california, replace)

* Combine all produced graphs
graph combine `e(graph)', cols(2) altshrink

* Change to the generated Stata frame "california"
frame change california

* Change back to the default Stata frame
frame change default

******************************************************************************

log close