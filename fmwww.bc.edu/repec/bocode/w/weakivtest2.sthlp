{smcl}
{* July 2022}{...}
{title:Title}

{p 4 4 2}
{bf:weakivtest2} —— A Robust Test for Weak Instruments with Multiple Endogenous Regressors

{title:Syntax}

{p 8 15 2} {cmd:weakivtest2} [{cmd:,} level(#) tau(#) points(#)] 
{p_end}

{synoptset 15 tabbed}{...}
{synopthdr}
{synoptline}
{synopt: {opt level(#)}}confidence level; the default is level(95);{p_end}
{synopt: {opt tau(#)}}Nagar's relative bias threshold; the default is tau(0.1);{p_end}
{synopt: {opt points(#)}}number of starting points for the optimization step; the default is points(1000);{p_end}
{synopt: {opt fast}}only obtain the simplified and conversative critical value to save time.{p_end}
{synoptline}


{title:Description}

{p 4 4 2}{cmd:weakivtest2} implements the weak instrument test with multiple endogenous regressors in Two-Stage Least Squares (Lewis and Mertens, 2022).
It is a postestimation command for {help ivreg2} and {help xtivreg2} (fixed effect only).
{cmd:weakivtest2} tests the null hypothesis of weak instruments.
The test rejects the null hypothesis when the test statistic exceeds a critical value, which depends on the estimator, the significance level, and the desired weak instrument threshold tau.
{cmd:weakivtest2} extends the Stock and Yogo's (2005) test by allowing heteroskedasticity and autocorrelation, and extends Montiel Olea and Pflueger's (2013) test by allowing multiple endogenous regressors.
{p_end}

{p 4 4 2} {cmd:weakivtest2} estimates the variance-covariance matrix of errors as specified in the preceding {help ivreg2} or {help xtivreg2} command.
The following options are supported: 
{opt r:obust} estimates an Eicker-Huber-White heteroskedasticity robust variance-covariance matrix;
{opt cl:uster(varlist)} estimates a variance-covariance matrix clustered by the specified variable;
{opt r:obust bw(#)} estimates a heteroskedasticity and autocorrelation-consistent variance-covariance matrix computed with a Bartlett (Newey-West) kernel with # bandwidth.
{opt bw(#)} without the {opt r:obust} option requests estimates that are autocorrelation-consistent but not heteroskedasticity-consistent.
{p_end}

{p 4 4 2}Note: You must install {help avar} by typing "ssc install avar" before running {cmd:weakivtest2}.{p_end}


{marker storedresults}{...}
{title:Stored results}

{pstd}{cmd:weakivtest2} stores the following in {cmd:r()}:

{synoptset 23 tabbed}{...}
{p2col 5 23 26 2: Scalars}{p_end}
{synopt:{cmd:r(tau)}}Nagar's (1959) relative bias threshold{p_end}
{synopt:{cmd:r(alpha)}}confidence level alpha{p_end}
{synopt:{cmd:r(wiv_stat)}}Lewis and Mertens's (2022) weak-IV test statistic{p_end}
{synopt:{cmd:r(wiv_stat_sy)}}Stock and Yogo's (2005) weak-IV test statistic{p_end}
{synopt:{cmd:r(wiv_cv)}}critical value for Lewis and Mertens's (2022) statistc with Imhof's (1961) approximation{p_end}
{synopt:{cmd:r(wiv_cv_simplified)}}critical value for Lewis and Mertens's (2022) statistc, simplified version{p_end}
{synopt:{cmd:r(wiv_cv_sy)}}critical value for Stock and Yogo's (2005) statistic with Nagar's (1959) approximation{p_end}


{title:References}

{phang}Imhof, J. P., 1961. "Computing the distribution of quadratic forms in normal variables." {it:Biometrika}, 48(3/4), 419-426.{p_end}

{phang}Lewis, Daniel J., and Karel Mertens, 2022. "A robust test for weak instruments with multiple endogenous regressors.". {it:Working Paper.}{p_end}

{phang}Montiel Olea, J. L. and C. E. Pflueger, 2013. "A robust test for weak instruments." {it:Journal of Business and Economic Statistics}, 31, 358-369.{p_end}

{phang}Nagar, A. L., 1959. "The bias and moment matrix of the general k-class estimators of the parameters in simultaneous equations." {it:Econometrica: Journal of the Econometric Society}, 575-595.{p_end}

{phang}Stock, J. and M. Yogo, 2005. "Testing for weak instruments in linear IV regression." {it:In Identification and Inference for Econometric Models: Essays in Honor of Thomas Rothenberg}, Chapter 5 80-108.{p_end}


{title:Author}

{p 4 4 2}
{cmd:Lingyun ZHOU}{break}
PBC School of Finance, Tsinghua University.{break}
