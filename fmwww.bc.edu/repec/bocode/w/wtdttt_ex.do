* do d:/stovring/PharmacoEpid/Hallas/CovarWTD/Application/Program/ado/wtdttt_ex.do

version 14.0

cd D:\stovring\PharmacoEpid\Hallas\CovarWTD\Application\Program\ado
discard
clear
set more off

* Open example dataset
use wtddat_covar

* Apply the parametric WTD model to obtain estimate of percentile
* after which only 20% of prevalent users will have a subsequent
* prescription redemption

* The Exponential model (a poor fit in this situation)
wtdttt last_rxtime, disttype(exp) reverse

* The Log-Normal model
wtdttt last_rxtime, disttype(lnorm) reverse

* Assess fit of Log-Normal model
wtdtttdiag last_rxtime

* And with a Weibull distribution
wtdttt last_rxtime, disttype(wei) reverse
ereturn list

* Use covariate in all three parameter equations
wtdttt last_rxtime, disttype(lnorm) reverse allcovar(i.packsize)

* Since covariate appears to have little influence on the
* lnsigma parameter, we estimate a model where number of
* pills only affect median parameter (mu) and the prevalence
* (logitp).
wtdttt last_rxtime, disttype(lnorm) reverse mucovar(i.packsize) ///
                                      logitpcovar(i.packsize)

* A small example showing treatment probability can be
* estimated based on the distance between index dates 
* and date of last prescription redemption, while taking 
* covariates into account (here: pack size). 

preserve									  
drop _all
set obs 200									  
gen packsize = ((runiform() < .5) * 100) + 100								  
gen distlast = runiform()

wtdtttprob probttt, distrx(distlast)

sort packsize distlast
la var distlast "Time since last prescription (years)"
la var probttt "Probability of being exposed"

twoway scatter probttt distlast, c(L L) msy(i i)

restore

* Another example, where we estimate duration of prescriptions
* from 90th percentile
wtdttt last_rxtime, disttype(lnorm) reverse mucovar(i.packsize) ///
                                      logitpcovar(i.packsize)

drop _all
set obs 200									  
gen packsize = ((runiform() < .5) * 100) + 100								  
gen distlast = runiform()


wtdpreddur predrxdur, iadp(.9)
la var predrxdur "Estimated duration of Rx"
bys packsize: list predrxdur if _n == 1
