{smcl}
{* July 2022}{...}
{title:Title}

{pstd}
{bf:weakivtest2} — A robust test for weak instruments for 2SLS with multiple endogenous regressors

{title:Syntax}

{p 8 15 2} {cmd:weakivtest2} [{cmd:,} level(#) tau(#) asymptotics(string) criterion(string) index(#) target(#) points(#) fast record] 
{p_end}

{synoptset 24 tabbed}{...}
{synopthdr:option}
{synoptline}
{synopt:{opth level(numlist)}}one or more confidence levels; default is {cmd:level(95 90)}{p_end}
{synopt:{opth tau(numlist)}}one or more bias-tolerance levels; default is {cmd:tau(0.05 0.1 0.2 0.3)}{p_end}
{synopt:{opt asymp:totics(string)}}asymptotic embedding: {cmd:"l0"} (local-to-zero) or {cmd:"lrr1"} (local-to-rank-reduction-of-one); default is {cmd:asymptotics("l0")}{p_end}
{synopt:{opt crit:erion(string)}}bias criterion for the Nagar bias: {cmd:"absolute"} or {cmd:"relative"}; default is {cmd:criterion("absolute")}{p_end}
{synopt:{opt ind:ex(#)}}index of the endogenous regressor that induces rank-deficiency; required only when {cmd:asymptotics("lrr1")} is specified{p_end}
{synopt:{opt tar:get(#)}}target of the 2SLS coefficients: {cmd:0} for the full vector or an index for a single coefficient; default is {cmd:target(0)}{p_end}
{synopt:{opt points(#)}}number of starting points used in the optimization step; default is {cmd:points(1000)}{p_end}
{synopt:{opt fast}}obtain only the simplified conservative critical values to save computation time{p_end}
{synopt:{opt record}}display the progress of the optimization procedure{p_end}
{synoptline}

{title:Description}

{pstd}
{cmd:weakivtest2} implements the robust test for weak instruments of Lewis and Mertens (2024).
It is a postestimation command for {help ivreg2}, {help xtivreg2} (fixed-effects estimator only), and {help ivreghdfe}.
{p_end}

{pstd}
{cmd:weakivtest2} tests the null hypothesis of weak instruments for 2SLS with multiple endogenous regressors.
It can be implemented under two asymptotic embeddings: local-to-zero (L0) and the local-to-rank-reduction-of-one (LRR1).
In particular, the null hypothesis under L0 embedding assumes that all first-stage coefficients are local to zero,
while the null hypothesis under LRR1 embedding assumes that the first-stage coefficient matrix is local to rank-deficiency.
The test evaluates the Nagar bias of 2SLS coefficients using two bias criteria.
In particular, the absolute bias criterion evaluates the bias relative to the maximum OLS bias, extending Stock and Yogo (2005),
while relative bias criterion evaluates the bias relative to its worst-case benchmark, extending Montiel Olea and Pflueger (2013).
The test can evaluate the bias of the entire 2SLS coefficient vector or a single 2SLS coefficient.
The test rejects the null of weak instruments when the test statistic ({it:gmin}) exceeds a critical value, which depends on the significance level and the bias-tolerance level {it:tau}.

{pstd}
{cmd:weakivtest2} extends 
(1) Stock and Yogo's (2005) test, available in {help ivreg2} and in the {help ivregress} postestimation command {cmd:estat firststage}, to be robust to heteroskedasticity and autocorrelation;
(2) Montiel Olea and Pflueger's (2013) test, available in {help weakivtest}, to the case of multiple endogenous regressors;
(3) Sanderson and Windmeijer's (2016) test, avaliable in their Appendix A.3, to be robust to heteroskedasticity and autocorrelation.
{p_end}

{pstd}
Note: {cmd:weakivtest2} requires the {help avar} package to be installed.
{p_end}

{title:Options}

{phang}
{opt level(numlist)} specifies one or more confidence levels (in percent).
The default is {cmd:level(95 90)}.
{p_end}

{phang}
{opt tau(numlist)} specifies one or more bias-tolerance levels.
The default is {cmd:tau(0.05 0.1 0.2 0.3)}.
{p_end}

{phang}
{opt asymp:totics(string)} chooses the asymptotic embedding used in the test.
The option {cmd:asymptotics("l0")} corresponds to the L0 embedding, in which all first-stage coefficients are local to zero.
The option {cmd:asymptotics("lrr1")} corresponds to the LRR1 embedding, in which the first-stage coefficient matrix is local to rank-deficiency.
The default is {cmd:asymptotics("l0")}.
{p_end}

{phang}
{opt crit:erion(string)} selects the bias criterion used to evaluate the Nagar bias.
The option {cmd:criterion("absolute")} evaluates the bias relative to the maximum OLS bias.
The option {cmd:criterion("relative")} evaluates the bias relative to its worst-case benchmark.
The default is {cmd:criterion("absolute")}.
When {cmd:asymptotics("lrr1")} is specified, {cmd:criterion("absolute")} must be used.
{p_end}

{phang}
{opt ind:ex(#)} specifies the location of the endogeneous regressor whose first-stage coefficient vector is assumed to be asymptotically collinear with the frist-stage coefficient vectors of the remaining endogenous regressors.
If there are {it:N} endogenous regressors, {cmd:index(#)} must be an integer between 1 and {it:N}.
This option is required only when {cmd:asymptotics("lrr1")} is specified.
{p_end}

{phang}
{opt tar:get(#)} specifies the target of the 2SLS coefficients for the weak-instrument test.
The default is {cmd:target(0)}, which treats the full vector of 2SLS coefficients as the target.
Alternatively, {cmd:target(j)} with an integer {it:j} between 1 and {it:N} focuses on the {it:j}th 2SLS coefficient.
When {cmd:asymptotics("lrr1")} is specified, {cmd:target(#)} must be either {cmd:0} (full vector) or equal to the value supplied in {cmd:index(#)}.
{p_end}

{phang}
{opt points(#)} sets the number of random starting points used in the optimization routine that computes the critical values.
The default is {cmd:points(1000)}.
{p_end}

{phang}
{opt fast} requests that only simplified conservative critical values be computed.
This option is useful when you want a quick diagnostic; the resulting critical values are guaranteed to be conservative but may be less sharp than the full set of critical values.
{p_end}

{phang}
{opt record} reports the progress of the numerical optimization used to compute the critical values.
This option is intended mainly for diagnostic or debugging purposes.
{p_end}

{pstd}
{cmd:weakivtest2}  estimates the variance-covariance matrix of errors as specified in the preceding {help ivreg2}, {help xtivreg2}, or {help ivreghdfe} command. The following options are supported:
{p_end}

{phang2}
{opt r:obust} specifies that an Eicker–Huber–White heteroskedasticity-robust variance–covariance matrix is used.
{p_end}

{phang2}
{opt cl:uster(varlist)} specifies a cluster–robust variance–covariance matrix based on the variable(s) in {it:varlist}.
{p_end}

{phang2}
{opt r:obust bw(#)} requests a heteroskedasticity- and autocorrelation-consistent variance–covariance matrix computed with a Bartlett (Newey–West) kernel and bandwidth {it:#}.
{p_end}

{phang2}
{opt bw(#)} without {opt robust} requests a variance–covariance matrix that is autocorrelation-consistent but not heteroskedasticity-consistent.
{p_end}

{title:Stored results}

{pstd}
{cmd:weakivtest2} stores the following in {cmd:r()}:

{synoptset 23 tabbed}{...}
{p2col 5 23 26 2: Scalars}{p_end}
{synopt:{cmd:r(stat)}}test statistic for Lewis and Mertens's (2022){p_end}
{synopt:{cmd:r(stat_sy)}}test statistic for Stock and Yogo's (2005) test{p_end}
{synopt:{cmd:r(stat_sw)}}test statistic for Sanderson and Windmeijer's (2016) test{p_end}
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
{synopt:{cmd:r(cv_sy)}}critical values for Stock and Yogo's (2005) test{p_end}
{synopt:{cmd:r(cv_sw)}}critical values for Sanderson and Windmeijer's (2016) test{p_end}
{synopt:{cmd:r(tau)}}bias tolerance levels{p_end}
{synopt:{cmd:r(alpha)}}significance levels{p_end}

{title:References}

{phang}
Lewis, D. J., and K. Mertens. 2024.
{browse "https://www.dallasfed.org/-/media/documents/research/papers/2022/wp2208r2.pdf":{it:A Robust Test for Weak Instruments for 2SLS with Multiple Endogenous Regressors}.}
Working Papers 2208, Federal Reserve Bank of Dallas, revised 26 Sep 2024.
{p_end}

{phang}
Sanderson, E., and F. Windmeijer. 2016.
{browse "https://www.sciencedirect.com/science/article/pii/S0304407615001736":{it:A Weak Instrument F-test in Linear IV Models with Multiple Endogenous Variables}.}
{it:Journal of Econometrics} 190(2): 212–221.
{p_end}

{phang}
Montiel Olea, J. L., and C. E. Pflueger. 2013.
{browse "https://doi.org/10.1080/00401706.2013.806694":{it:A Robust Test for Weak Instruments}.}
{it:Journal of Business and Economic Statistics} 31: 358–369.
{p_end}

{phang}
Stock, J. H., and M. Yogo. 2005.
{browse "https://ideas.repec.org/p/nbr/nberte/0284.html":{it:Testing for Weak Instruments in Linear IV Regression}.}
In {it:Identification and Inference for Econometric Models: Essays in Honor of Thomas Rothenberg}, 80–108.
{p_end}

{title:Author}

{pstd}
{cmd:Lingyun ZHOU}{break}
PBC School of Finance, Tsinghua University.
{p_end}
