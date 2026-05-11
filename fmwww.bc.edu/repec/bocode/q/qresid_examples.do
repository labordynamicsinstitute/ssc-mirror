version 15.0
clear all
set more off
set varabbrev off

/*
    qresid examples for SSC submission

    These examples use official Stata data and commands only.  They illustrate
    the usual workflow: fit a model, compute quantile residuals, inspect a
    normal Q-Q plot, and check residuals against fitted values.
*/

capture which qresid
if _rc {
    adopath ++ "."
    which qresid
}

* Example 1: Gaussian linear regression
sysuse auto, clear
regress price mpg weight
qresid rq_gaussian
qnorm rq_gaussian
predict double xb_gaussian, xb
scatter rq_gaussian xb_gaussian, yline(0) ///
    title("Gaussian regression: qresid vs fitted values")

* Example 2: Poisson regression for a small count outcome
sysuse auto, clear
poisson rep78 mpg weight if rep78 < .
qresid rq_poisson, seed(12345)
qnorm rq_poisson
predict double mu_poisson, n
scatter rq_poisson mu_poisson, yline(0) ///
    title("Poisson regression: qresid vs fitted mean")

* Example 3: Binomial counts with trials
clear
set seed 20260511
set obs 200
generate double x = runiform() - .5
generate byte n = 5
generate double p = invlogit(-.4 + 1.2*x)
generate byte y = rbinomial(n, p)
glm y x, family(binomial n) link(logit)
qresid rq_binomial, seed(12345)
qnorm rq_binomial
predict double phat_binomial, mu
scatter rq_binomial phat_binomial, yline(0) ///
    title("Binomial counts: qresid vs fitted probability")

display as result "QRESID_SSC_EXAMPLES_STATUS PASS"
