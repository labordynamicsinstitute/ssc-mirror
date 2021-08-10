discard

**********************************************************************************
* Open the example dataset (discrete time), ordinary WTD analysis with event dates
**********************************************************************************

use ranwtddat_discdates.dta, clear

set seed 1234

preserve
ranwtdttt rxdate, id(pid) disttype(lnorm) samplestart(1jan2014) sampleend(31dec2014)

* Assess fit of Log-Normal model
wtdtttdiag _rxshift
restore


**********************************************************************************
* Open the example dataset (continuous time), reverse WTD analysis with covariates
**********************************************************************************

use ranwtddat_conttime.dta, clear

set seed 1234

* Apply the parametric WTD model to obtain estimate of percentile
* after which only 20% of prevalent users will have a subsequent
* prescription redemption

* The Exponential model (a poor fit in this situation)
* Note that this is an example with continuous time and hence we need to add the
* option -conttime- and -start- and -end- are numbers and not dates.
preserve
ranwtdttt rxtime, id(pid) disttype(exp) samplestart(1) sampleend(2) conttime reverse
restore

* The Log-Normal model
preserve
ranwtdttt rxtime, id(pid) disttype(lnorm) samplestart(1) sampleend(2) conttime reverse

* Assess fit of Log-Normal model - fits well
wtdtttdiag _rxshift
restore

* And with a Weibull distribution
preserve
ranwtdttt rxtime, id(pid) disttype(wei) samplestart(1) sampleend(2) conttime reverse
ereturn list
restore

* Use covariate in all three parameter equations
preserve
ranwtdttt rxtime, id(pid) disttype(lnorm) samplestart(1) sampleend(2) conttime reverse allcovar(i.packsize)
restore

* Since covariate appears to have little influence on the
* lnsigma and logitp parameters, we estimate a model where number of
* pills only affect median parameter (mu).
preserve
ranwtdttt rxtime, id(pid) disttype(lnorm) samplestart(1) sampleend(2) conttime reverse mucovar(i.packsize)

*********************************************************************
* A small example showing how treatment probability can be predicted 
* based on the distance between index dates and date of last 
* prescription redemption, while taking covariates (here: pack size) 
* into account. The last fitted WTD is used for this prediction.
*********************************************************************						  
use lastRx_index, clear /* Open dataset in which we predict treatment
                    probabilities */

wtdtttpredprob probttt, distrx(distlast)

sort packsize distlast
la var distlast "Time since last prescription (years)"
la var probttt "Probability of being exposed"

twoway scatter probttt distlast, c(L L) msy(i i)

restore

**********************************************************************
* Another example, where we predict duration of observed prescription 
* redemptions based on an estimated WTD. Here the predicted duration 
* corresponds to the 90th percentile of the IAD.
**********************************************************************

preserve
ranwtdttt rxtime, id(pid) disttype(lnorm) samplestart(1) sampleend(2) conttime reverse mucovar(i.packsize)

return list

use lastRx_index, clear /* Open dataset in which we predict treatment
                    durations */


wtdtttpreddur predrxdur, iadp(.9)
la var predrxdur "Predicted duration of Rx"
bys packsize: list predrxdur if _n == 1
restore

******************************************************************
* Predict mean duration
******************************************************************

ranwtdttt rxtime, id(pid) disttype(lnorm) samplestart(1) sampleend(2) conttime reverse mucovar(i.packsize)

use lastRx_index, clear /* Open dataset in which we predict treatment
                    durations */


wtdtttpreddur predmeanrxdur, iadmean
la var predmeanrxdur "Predicted mean duration of Rx"
bys packsize: list predmeanrxdur if _n == 1
