* egranger cert script 1.1.0 ms 20121120
set more off
cscript egranger adofile egranger
capture log close
log using cs_egranger, replace smcl
which egranger
version

* Replicate critical value in MacKinnon (2010), p. 12 for T+1=101
clear all
set obs 101
forvalues i=1/5 {
	gen x`i'=rnormal()
}
gen t=_n
tsset t
qui egranger x1-x5, trend
assert round(e(cv5),0.00001) == -4.89111

* average per-capita disposable personal income dataset
use http://www.stata-press.com/data/r9/rdinc, clear

* T is zero in the first period (lost in 2nd step and test regressions)
gen t=_n-1
gen tsq=t^2

* Cointegration test

egranger ln_ne ln_se, regress
scalar Zt=e(Zt)
capture drop resid
regress ln_ne ln_se
predict double resid, res
regress D.resid L.resid, nocons
qui test L.resid
assert reldif(abs(Zt),sqrt(r(F))) < 1e-8

egranger ln_ne ln_se, lags(2) regress
scalar Zt=e(Zt)
capture drop resid
regress ln_ne ln_se
predict double resid, res
regress D.resid L.resid L(1/2)D.resid, nocons
qui test L.resid
assert reldif(abs(Zt),sqrt(r(F))) < 1e-8

egranger ln_ne ln_se ln_me, lags(2) regress
scalar Zt=e(Zt)
capture drop resid
regress ln_ne ln_se ln_me
predict double resid, res
regress D.resid L.resid L(1/2)D.resid, nocons
qui test L.resid
assert reldif(abs(Zt),sqrt(r(F))) < 1e-8

egranger ln_ne ln_se, lags(3) regress trend
scalar Zt=e(Zt)
capture drop resid
regress ln_ne ln_se t
predict double resid, res
regress D.resid L.resid L(1/3)D.resid, nocons
qui test L.resid
assert reldif(abs(Zt),sqrt(r(F))) < 1e-8

egranger ln_ne ln_se ln_me, lags(4) regress qtrend
scalar Zt=e(Zt)
capture drop resid
regress ln_ne ln_se ln_me t tsq
predict double resid, res
regress D.resid L.resid L(1/4)D.resid, nocons
qui test L.resid
assert reldif(abs(Zt),sqrt(r(F))) < 1e-8

* 2-step ECM

egranger ln_ne ln_se, regress ecm
savedresults save eg e()
capture drop resid
regress ln_ne ln_se
predict double resid, res
regress D.ln_ne L.resid LD.ln_se
savedresults comp eg e(), include(macros: depvar scalar: ll matrix: b V) tol(1e-7) verbose

egranger ln_ne ln_se, lags(2) regress ecm
savedresults save eg e()
capture drop resid
regress ln_ne ln_se
predict double resid, res
regress D.ln_ne L.resid L(1/2)D.(ln_ne ln_se)
savedresults comp eg e(), include(macros: depvar scalar: ll matrix: b V) tol(1e-7) verbose

egranger ln_ne ln_se ln_me, lags(2) regress ecm
savedresults save eg e()
capture drop resid
regress ln_ne ln_se ln_me
predict double resid, res
regress D.ln_ne L.resid L(1/2)D.(ln_ne ln_se ln_me)
savedresults comp eg e(), include(macros: depvar scalar: ll matrix: b V) tol(1e-7) verbose

egranger ln_ne ln_se, lags(3) regress trend ecm
savedresults save eg e()
capture drop resid
regress ln_ne ln_se t
predict double resid, res
regress D.ln_ne L.resid L(1/3)D.(ln_ne ln_se)
savedresults comp eg e(), include(macros: depvar scalar: ll matrix: b V) tol(1e-7) verbose

egranger ln_ne ln_se ln_me, lags(4) regress qtrend ecm
savedresults save eg e()
capture drop resid
regress ln_ne ln_se ln_me t tsq
predict double resid, res
regress D.ln_ne L.resid L(1/4)D.(ln_ne ln_se ln_me)
savedresults comp eg e(), include(macros: depvar scalar: ll matrix: b V) tol(1e-7) verbose

log close
