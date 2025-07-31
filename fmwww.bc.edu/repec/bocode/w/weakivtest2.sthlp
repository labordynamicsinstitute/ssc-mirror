{smcl}
{* July 2022}{...}
{title:Title}

{p 4 4 2}
{bf:weakivtest2} —— A Robust Test for Weak Instruments for 2SLS with Multiple Endogenous Regressors

{title:Syntax}

{p 8 15 2} {cmd:weakivtest2} [{cmd:,} level(#) tau(#) asymptotics(string) criterion(string) index(#) target(#) points(#) fast record] 
{p_end}

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt: {opth level(numlist)}}one or more confidence levels; the default is level(95 90){p_end}
{synopt: {opth tau(numlist)}}one or more bias tolerance levels; the default is tau(0.05 0.1 0.2 0.3){p_end}
{synopt: {opt asymp:totics(string)}}the asymptotic embedding; "l0" for the test under the local-to-zero assumption and "lrr1" for the test under the local-to-rank-reduction-of-one assumption; the default is asymptotics("l0"){p_end}
{synopt: {opt crit:erion(string)}}the bias criterion in evaluating the Nagar bias; "absolute" for absolute bias and "relative" for relative bias; this option must be "absolute" when asymptotics("lrr1") is specified; the default is criterion("absolute"){p_end}
{synopt: {opt ind:ex(#)}}an integer j (1<=j<=N) corresponding to the location of the retained regressor in the vector of endogenous regressors, where N is the number of endogenous regressors; this option must be specified if and only if asymptotics("lrr1") is specified.{p_end}
{synopt: {opt tar:get(#)}}the target of 2SLS coefficients; either 0 for entire vector or an integer j (1<=j<=N) corresponding to the location of the individual coefficient, where N is the number of endogenous regressors; this option must be 0 or the number specified in index(#) when asymptotics("lrr1") is specified; the default is target(0).{p_end}
{synopt: {opt points(#)}}the number of starting points for the optimization step; the default is points(1000){p_end}
{synopt: {opt fast}}obtain only the simplified and conversative critical value to save time{p_end}
{synopt: {opt record}}print the optimization process{p_end}
{synoptline}


{title:Description}

{p 4 4 2}{cmd:weakivtest2} implements the robust test for weak instruments for 2SLS with multiple endogenous regressors by Lewis and Mertens (2022).
It is a postestimation command for {help ivreg2}, {help xtivreg2} (fixed effect only) and {help ivreghdfe}.
{p_end}

{p 4 4 2} {cmd:weakivtest2} estimates the variance-covariance matrix of errors as specified in the preceding {help ivreg2}, {help xtivreg2} or {help ivreghdfe} command.
The following options are supported: 
{opt r:obust} estimates an Eicker-Huber-White heteroskedasticity robust variance-covariance matrix;
{opt cl:uster(varlist)} estimates a variance-covariance matrix clustered by the specified variable;
{opt r:obust bw(#)} estimates a heteroskedasticity and autocorrelation-consistent variance-covariance matrix computed with a Bartlett (Newey-West) kernel with # bandwidth.
{opt bw(#)} without the {opt r:obust} option requests estimates that are autocorrelation-consistent but not heteroskedasticity-consistent.
{p_end}

{p 4 4 2}Note: The command requires the {help avar} package.{p_end}


{marker storedresults}{...}
{title:Stored results}

{pstd}{cmd:weakivtest2} stores the following in {cmd:r()}:

{synoptset 23 tabbed}{...}
{p2col 5 23 26 2: Scalars}{p_end}
{synopt:{cmd:r(stat)}}test statistic for Lewis and Mertens's (2022){p_end}
{synopt:{cmd:r(stat_sy)}}test statistic for Stock and Yogo's (2005) test (local-to-zero){p_end}
{synopt:{cmd:r(stat_sw)}}test statistic for Sanderson and Windmeijer's (2016) test (local-to-rank-reduction-of-one){p_end}
{synopt:{cmd:r(points)}}number of random draws{p_end}
{synopt:{cmd:r(T)}}number of observations{p_end}
{synopt:{cmd:r(K)}}number of excluded instrumental variables{p_end}
{synopt:{cmd:r(L)}}number of exogenous regressors{p_end}
{synopt:{cmd:r(N)}}number of endogenous regressors{p_end}
{synopt:{cmd:r(index)}}location of retained regressor for LRR1 test{p_end}
{p2col 5 23 26 2: Macros}{p_end}
{synopt:{cmd:r(fast)}}whether only the simplified critical values are obtained{p_end}
{synopt:{cmd:r(record)}}whether the optimization process is printed{p_end}
{synopt:{cmd:r(criterion)}}bias criterion: "absolute" or "relative"{p_end}
{synopt:{cmd:r(asymptotics)}}asymptotic embedding: "local-to-zero" or "local-to-rank-reduction-of-one"{p_end}
{synopt:{cmd:r(target)}}target of 2SLS coefficients{p_end}
{p2col 5 23 26 2: Matrices}{p_end}
{synopt:{cmd:r(cv)}}critical values for Lewis and Mertens's (2022) test{p_end}
{synopt:{cmd:r(cv_simp)}}simplified conservative critical values for Lewis and Mertens's (2022) test{p_end}
{synopt:{cmd:r(cv_sy)}}critical values for Stock and Yogo's (2005) test (local-to-zero){p_end}
{synopt:{cmd:r(cv_sw)}}critical values for Sanderson and Windmeijer's (2016) test (local-to-rank-reduction-of-one){p_end}
{synopt:{cmd:r(tau)}}bias tolerance levels{p_end}
{synopt:{cmd:r(alpha)}}significance levels{p_end}

{title:References}

{phang}Lewis, Daniel J., and Karel Mertens, 2022. {browse "https://www.dallasfed.org/-/media/documents/research/papers/2022/wp2208r2.pdf":{it:A Robust Test for Weak Instruments for 2SLS with Multiple Endogenous Regressors}.} Working Papers 2208, Federal Reserve Bank of Dallas, revised 26 Sep 2024.{p_end}

{phang}Sanderson, E., and F. Windmeijer, 2016. {browse "https://www.sciencedirect.com/science/article/pii/S0304407615001736":{it:A Weak Instrument F-test in Linear IV Models with Multiple Endogenous Variables}.} {it:Journal of Econometrics}, 190(2), 212–221.{p_end}

{phang}Montiel Olea, J. L. and C. E. Pflueger, 2013. {browse "https://doi.org/10.1080/00401706.2013.806694":{it:A Robust Test for Weak Instruments}.} {it:Journal of Business and Economic Statistics}, 31, 358-369.{p_end}

{phang}Stock, J. and M. Yogo, 2005. {browse "https://www.cambridge.org/core/books/identification-and-inference-for-econometric-models/testing-for-weak-instruments-in-linear-iv-regression/8AD94FF2EFD214D05D75EE35015021E4?utm_campaign=shareaholic&utm_medium=copy_link&utm_source=bookmark":{it:Testing for Weak Instruments in Linear IV Regression}.} {it:In Identification and Inference for Econometric Models: Essays in Honor of Thomas Rothenberg}, Chapter 5 80-108.{p_end}


{title:Author}

{p 4 4 2}
{cmd:Lingyun ZHOU}{break}
PBC School of Finance, Tsinghua University.{break}
