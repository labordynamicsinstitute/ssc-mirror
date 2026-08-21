*! =============================================================================
*!  QUICKSTART.DO
*!
*!  The short tour: one dataset, every estimator, nothing else.  For the full
*!  interface with every option spelled out, see EXAMPLES.DO.
*!
*!  Download this one file and run it.  That is all.  It fetches the command
*!  straight from the repository into a temporary directory, so there is
*!  nothing else to download, no working directory to set, and nothing left
*!  installed on your machine afterwards.
*! =============================================================================
*!
*!  Ported from the R reference implementation
*!    Haschka, R. E. (2026). Copula-based endogeneity corrections in R.
*!    https://github.com/HashtagHaschka/Copula-based-endogeneity-corrections
*!  and from endogCopula by Ashwin Malshe,
*!    https://github.com/ashgreat/endogCopula
*!
*!  GPL-3 or later, with the additional attribution term stated in LICENSE.

clear all
set more off

* -----------------------------------------------------------------------------
*  Fetch the command
* -----------------------------------------------------------------------------
*  Into c(tmpdir), not into your ado directory: this leaves no trace.  If you
*  are running the file from inside a clone of the repository it uses the local
*  copy instead and never touches the network.

local gh "https://raw.githubusercontent.com/girishm77/copulaendog_stata_python/main/stata"

capture confirm file "copulaendog.ado"
if !_rc {
    adopath ++ "`c(pwd)'"
    di as txt "Using the local copy of copulaendog in `c(pwd)'."
}
else {
    local dir "`c(tmpdir)'/copulaendog"
    capture mkdir "`dir'"
    local failed = 0
    foreach f in copulaendog.ado copulaendog_p.ado copulaendog.sthlp {
        capture copy "`gh'/`f'" "`dir'/`f'", replace
        if _rc local failed = 1
    }
    if `failed' {
        di as err "Could not download the command from"
        di as err "  `gh'"
        di as err "Check your internet connection, or clone the repository and"
        di as err "run this file from its stata/ directory."
        exit 601
    }
    adopath ++ "`dir'"
    di as txt "Downloaded copulaendog into `dir'."
}

which copulaendog

* -----------------------------------------------------------------------------
*  The data
* -----------------------------------------------------------------------------
*  Simulated, so that every assumption can be checked against the truth.
*
*      (xi, v) ~ bivariate normal with corr = 0.6
*      P       = exp(0.8*v + 0.6*w)
*      y       = 1 + 2*P + 1.5*x - 0.5*w + xi
*
*  P is a strictly increasing function of the normal variate 0.8*v + 0.6*w, so
*  the Gaussian copula between P and the structural error holds exactly, while
*  P itself is lognormal and therefore strongly non-normal -- which is what
*  identifies the correction.  The true coefficient on P is 2.
*
*  Note the 0.6*w: it makes corr(W, P*) different from zero, so the Park &
*  Gupta uncorrelatedness assumption fails by construction.  Watch validity
*  catch it below.

set seed 90210
quietly {
    set obs 2000
    generate double w  = rnormal()
    generate double x  = rnormal()
    generate double v  = rnormal()
    generate double xi = 0.6*v + sqrt(1 - 0.6^2)*rnormal()
    generate double P  = exp(0.8*v + 0.6*w)
    generate double y  = 1 + 2*P + 1.5*x - 0.5*w + xi
    label variable y "outcome"
    label variable P "endogenous regressor, true coefficient 2"
    label variable x "exogenous"
    label variable w "exogenous, and correlated with P"
}

* -----------------------------------------------------------------------------
*  1.  What the problem looks like
* -----------------------------------------------------------------------------
di as txt _n "{hline 78}" _n "OLS, uncorrected. The truth is 2." _n "{hline 78}"
regress y P x w

* -----------------------------------------------------------------------------
*  2.  Park & Gupta (2012)
* -----------------------------------------------------------------------------
*  The original: add the copula transform of P to the regression.

di as txt _n "{hline 78}" _n "PG" _n "{hline 78}"
copulaendog y P, exog(x w) method(pg) nboots(199) seed(1)

*  validity walks the identification requirements.  On this dataset it should
*  report that P is non-normal enough to identify the model, and that the
*  uncorrelatedness assumption is violated -- which it is, by construction.

copulaendog, validity

* -----------------------------------------------------------------------------
*  3.  The estimators that do not need that assumption
* -----------------------------------------------------------------------------
*  2sCOPE and IMA transform the exogenous regressors too and project the
*  correlation out in a first stage.  BMW reverses the order: it residualises
*  first and rank-transforms the residual.

di as txt _n "{hline 78}" _n "2sCOPE" _n "{hline 78}"
copulaendog y P, exog(x w) method(2scope) nboots(199) seed(1)

di as txt _n "{hline 78}" _n "IMA" _n "{hline 78}"
copulaendog y P, exog(x w) method(ima) nboots(199) seed(1)

di as txt _n "{hline 78}" _n "BMW" _n "{hline 78}"
copulaendog y P, exog(x w) method(bmw) nboots(199) seed(1)

* -----------------------------------------------------------------------------
*  4.  JAMS (Liengaard et al. 2025)
* -----------------------------------------------------------------------------
*  Lets the copula structure differ across the categories of a discrete
*  control.  Here it has nothing to find, because the data were generated with
*  one common structure -- and the test at the bottom of the output should say
*  so rather than manufacture a difference.

quietly generate byte store = 1 + int(3*runiform())
quietly replace y = y + 0.4*store

di as txt _n "{hline 78}" _n "JAMS, structure varying over store" _n "{hline 78}"
copulaendog y P, exog(x w i.store) method(jams) conditional(store) ///
    nboots(199) seed(1)

* -----------------------------------------------------------------------------
*  5.  Prediction
* -----------------------------------------------------------------------------
*  The copula terms are endogeneity controls, not part of the causal model, so
*  they do not enter the prediction.

quietly copulaendog y P, exog(x w) method(2scope) nboots(199) seed(1)
predict yhat
predict xi_hat, residuals
summarize yhat xi_hat

* -----------------------------------------------------------------------------
*  Where to go next
* -----------------------------------------------------------------------------
di as txt _n "{hline 78}"
di as txt "Done. Every estimate of the coefficient on P above should sit near 2,"
di as txt "and uncorrected OLS should not."
di as txt ""
di as txt "  help copulaendog     the full syntax"
di as txt "  EXAMPLES.DO          every option of every estimator, defaults included"
di as txt "{hline 78}"
