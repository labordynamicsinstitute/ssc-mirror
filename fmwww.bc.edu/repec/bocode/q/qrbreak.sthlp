{smcl}
{* *! version 1.9.0  31jul2026}{...}
{hline}
help for {hi:qrbreak}
{hline}

{title:Title}

{p2colset 5 18 20 2}{...}
{p2col :{hi:qrbreak} {hline 2}}Structural breaks in quantile regression (testing and estimation){p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 16 2}
{cmd:qrbreak} {depvar} {indepvars} {ifin}{cmd:,} {opt tau(numlist)} [{opt ns:ize(#)} {opt trim(#)} {opt max:breaks(#)} {opt a:lpha(#)} {opt cil:evel(#)} {opt time(varname)} {opt norm(method)}]

{p 4 6 2}
{it:indepvars} may contain factor variables and time-series operators; base
and omitted factor levels are dropped automatically, exactly as
{cmd:model.matrix()} does in R.  The dependent variable may carry
time-series operators but may not be a factor variable.{p_end}

{title:Description}

{pstd}
{cmd:qrbreak} tests for structural breaks occurring at unknown dates in regression
quantiles and estimates the break dates, their confidence intervals, and the
regression coefficients in each regime.  The analysis is carried out both
quantile by quantile (the SQ test of Qu 2008) and jointly over a range of
quantiles (the DQ test of Oka and Qu 2011).  The number of breaks is determined
by a sequential testing procedure, break dates are estimated by dynamic
programming, and confidence intervals for the break dates are constructed under
the shrinking-break asymptotic framework of Oka and Qu (2011).

{pstd}
The command is a faithful port of the R package {cmd:QR.break} version 1.0.3 by
Zhongjun Qu and Tatsushi Oka (with contributions by Samuel Messer), including
verbatim ports of the quantile regression solvers of the R package
{cmd:quantreg} version 6.1 by Roger Koenker ({cmd:rqbr.f}, the modified
Barrodale-Roberts simplex, and {cmd:rqfnb.f}, the Frisch-Newton interior point
method).  All deterministic results replicate the R implementation.

{pstd}
The approach extends the multiple-structural-break framework of Bai and
Perron (1998, 2003), developed for conditional mean regressions, to
conditional quantiles: the dynamic-programming estimation of the break dates
and the sequential determination of their number follow the Bai-Perron
methodology, while the SQ and DQ statistics replace the mean-regression
tests with subgradient-based tests suited to quantile regression.

{pstd}
The framework assumes stationary, I(0), regressors and errors; it is not
designed for unit-root or cointegrated series.  The {opt nsize()} option
accommodates repeated cross sections (a fresh sample of units in every
period); genuine panel models with unit fixed effects are outside its scope.
For classical Bai-Perron break tests in conditional mean models with I(0)
series see the author's command {cmd:byperron}; for structural breaks in
cointegrating relationships see the author's command {cmd:kperrony}.

{pstd}
The data must be ordered as in the R original: for time series data
({opt nsize(1)}, the default) simply in time order; for repeated cross sections
the first {it:N} observations belong to period 1, the next {it:N} to period 2,
and so forth, where {it:N} is given in {opt nsize()}.  A constant is added
automatically and all regression coefficients are allowed to change across
regimes.

{title:Methods: what the command does, step by step}

{pstd}
{ul:Step 1. Objective values on all admissible subsamples.}  For every
admissible segment of the sample (every start and end period such that the
segment contains at least round({it:T}*{it:trim}) periods) the quantile
regression objective function (the sum of the check function evaluated at the
segment fit) is computed at each requested quantile.  These values are the
building blocks of everything that follows.

{pstd}
{ul:Step 2. Break date estimation by dynamic programming.}  For a given number
of breaks {it:m}, the break dates are estimated globally: the sample is split
into {it:m}+1 regimes so that the sum of the segment objective values is
minimized over all admissible partitions, using the dynamic programming
recursion of the Bai-Perron type adapted to quantile objectives.  For the
single-quantile analysis the objective of that quantile is used; for the
multiple-quantile analysis the objectives are summed over the specified
quantiles, so that all quantiles share the same break dates (Oka and Qu 2011).

{pstd}
{ul:Step 3. Testing 0 versus 1 break (the SQ statistic, Qu 2008).}  The model
without breaks is estimated on the full sample and the subgradient process of
the quantile regression is formed: the normalized partial sums of the sign
function of the residuals, weighted by the regressors.  Under the null of no
break this process fluctuates around a straight line; the SQ statistic is the
largest standardized deviation of the process from that line, taken over time
and over coefficients.  The sign classification of the residuals follows R
exactly: the fitted values are accumulated in extended precision, matching
R's internal matrix product, so the statistics replicate the CRAN
{cmd:QR.break} output digit for digit.  Under {cmd:norm(spectral)} the normalization matrix is instead the rescaled symmetric square root of the regressor correlation matrix, following QR.break 1.0.3; the same critical values apply.

{pstd}
{ul:Step 4. Sequential testing for the number of breaks.}  To test {it:l}
versus {it:l}+1 breaks, the sample is split at the {it:l} estimated break
dates and the 0-versus-1 test of Step 3 is applied within each regime; the
statistic is the maximum over regimes.  If it exceeds the critical value, the
procedure moves on to {it:l}+1 breaks, up to {opt maxbreaks()}; the first
non-rejection determines the number of breaks.  The decision reported in the
output uses the level in {opt alpha()}; the results for all three levels (10,
5, 1 percent) are computed and stored in {cmd:e()}.

{pstd}
{ul:Step 5. The DQ test (Oka and Qu 2011).}  The DQ statistic applies the same
construction jointly over the quantile range: the subgradient process is
evaluated on a grid of quantiles spanning [min({it:tau}), max({it:tau})] with
grid step 1/{it:T}, and the maximum is taken over time, coefficients, and
quantiles.  This test has power against breaks occurring anywhere in the
specified part of the conditional distribution and is the primary test for the
overall decision when several quantiles are given (Part 2 and the Conclusion
in the output).

{pstd}
{ul:Step 6. Critical values.}  SQ critical values come from the table
distributed with the R package; DQ critical values come from the response
surface when the quantile range is symmetric and from simulation otherwise
(see {it:Critical values} below).

{pstd}
{ul:Step 7. Confidence intervals for the break dates.}  Each estimated break
date receives a confidence interval built under the shrinking-break asymptotic
framework of Oka and Qu (2011), using the estimated coefficient changes
between the adjacent regimes and kernel estimates of the conditional densities
in those regimes.

{pstd}
{ul:Step 8. Regime coefficients and break sizes.}  Conditional on the
estimated break dates, the quantile regression with regime-specific
coefficients is estimated; standard errors, t statistics, and p-values use the
nid-type sandwich estimator of {cmd:quantreg}.  Break sizes are the
differences between the coefficients of consecutive regimes, with standard
errors from the same covariance matrix.

{title:Options}

{phang}
{opt tau(numlist)} is required and specifies the quantiles used for break
detection and estimation, for example {cmd:tau(0.2(0.15)0.8)}.  With a single
quantile only the SQ analysis is performed; with several quantiles the DQ
analysis over the range [min(tau), max(tau)] is added.

{phang}
{opt nsize(#)} is the number of cross-sectional units per time period; default
{cmd:nsize(1)} (time series).  When {opt time()} is given and {opt nsize()} is
omitted, {cmd:qrbreak} counts the observations in each period of the time
variable and, if every period has the same count, uses that count
automatically (a note is printed).  Unequal counts or periods whose
observations are not contiguous stop with an error, and an explicitly given
{opt nsize()} that conflicts with the period structure of {opt time()} is
likewise rejected.

{phang}
{opt trim(#)} is the trimming proportion; the minimum regime length is
round({it:T}*{it:trim}).  Default {cmd:trim(0.15)}.

{phang}
{opt maxbreaks(#)} is the maximum number of breaks allowed (at most 10).
Default {cmd:maxbreaks(3)}.

{phang}
{opt alpha(#)} is the significance level, in percent, used in the sequential
procedure that determines the number of breaks; one of 10, 5, or 1.  Default
{cmd:alpha(5)}.

{phang}
{opt cilevel(#)} is the coverage level, in percent, of the confidence intervals
for the break dates; one of 90 or 95.  Default {cmd:cilevel(95)}.

{phang}
{opt time(varname)} gives a (numeric or string) variable holding the date label
of each observation; the value at the first observation of each period is used
to report break dates in date format.  If omitted, break dates are reported as
observation indices only.

{phang}
{opt norm(method)} selects how the subgradient process underlying the SQ and
DQ tests is normalized; it is the exact counterpart of the {cmd:norm.method}
argument of QR.break version 1.0.3.  {cmd:norm(cholesky)}, the default, uses
the Cholesky factor of the regressor cross-product matrix and reproduces
QR.break versions 1.0.2 and earlier exactly; because that factor is built
sequentially, the test statistics depend on the order in which the regressors
are listed.  {cmd:norm(spectral)} uses the symmetric square root of the
correlation matrix of the regressors, rescaled by their standard deviations,
and is therefore invariant to the ordering, units, and signs of the
regressors.  Both normalizations have the same limiting null distribution, so
the same critical values apply and both tests are valid.  Break dates, their
confidence intervals, and regime coefficients do not depend on {opt norm()}.

{title:Critical values}

{pstd}
Critical values of the SQ test are taken from the table distributed with the R
package (for up to 100 coefficients and 10 breaks).  Critical values of the DQ
test are computed from the response surface in Qu (2008) and Oka and Qu (2011)
when the quantile range is symmetric (that is, min(tau) = 1 - max(tau)), at
most 20 coefficients change, and at most 5 breaks are allowed; otherwise they
are obtained by simulation (500 grid points, 50,000 replications), exactly as
in the R package.  The R original does not set a random seed for these
simulations, so simulated DQ critical values are inherently stochastic in both
implementations; set {cmd:set seed} beforehand if you need reproducibility of
the simulated critical values within Stata.

{title:Performance and the compiled plugin}

{pstd}
The computational core of {cmd:qrbreak} (the Barrodale-Roberts quantile
regression solver, the subsample objective-value precomputation, and the SQ
and DQ test statistics) ships as a compiled C plugin.  When {cmd:qrbreak} is
called it loads the plugin for the current operating system
({cmd:qrbreak_core_windows.plugin}, {cmd:qrbreak_core_unix.plugin}, or on
macOS {cmd:qrbreak_core_macosx_arm64.plugin} /
{cmd:qrbreak_core_macosx_x86_64.plugin}, tried in turn) and uses it
automatically.  If no plugin is available for the platform, the command
falls back to a pure Mata implementation of the very same algorithms.  The
two paths produce identical results; the plugin is only faster.  For
orientation, on the author's machine the GDP example of this help file runs
in about 10 seconds with the plugin, while the same analysis in R
({cmd:QR.break} under R 4.3 on Windows) takes about one minute.  The DQ
critical values for asymmetric quantile ranges are obtained by simulation
without a fixed seed, exactly as in the R original, and therefore vary
slightly across runs; all other reported numbers are deterministic.

{title:Examples}

{pstd}
Two datasets accompany the command; both are the example datasets shipped
with the R package QR.break and are hosted at the URLs used below.
{cmd:gdp.dta} is the time-series application of Qu (2008) and Oka and Qu
(2011): quarterly US real GDP growth from 1947 Q4 to 2009 Q2 (247 quarters),
with variables {cmd:gdp} (the growth rate), {cmd:lag1} and {cmd:lag2} (its
first two lags, the regressors of an AR(2)), and {cmd:yq} (the quarter
label).  {cmd:driver.dta} is the repeated cross-section application of Oka
and Qu (2011): the blood alcohol concentration of young drivers over
1983 Q1 to 2007 Q4, with 108 drivers sampled afresh in each of the 100
quarters (10,800 observations) and variables {cmd:bac} (blood alcohol
concentration), {cmd:age}, {cmd:gender} and {cmd:winter} (the latter two 0-1
indicators), and {cmd:yq} (the quarter label).{p_end}

{pstd}
{ul:Example 1, with its replication in R: US real GDP growth} (Qu 2008; Oka
and Qu 2011, Section 6.2; 1947Q4-2009Q2).  In Stata:

{phang2}{cmd:. use https://www.eruygurakademi.com/datasets/qrbreak/gdp.dta, clear}{p_end}
{phang2}{cmd:. qrbreak gdp lag1 lag2, tau(0.2(0.15)0.8) trim(0.15) maxbreaks(3) alpha(5) cilevel(95) time(yq)}{p_end}

{pstd}
The identical analysis in R with the package {cmd:QR.break} (version 1.0.3);
{cmd:v.a = 2} selects the 5 percent decision level of {cmd:alpha(5)} from the
levels (10, 5, 1), and {cmd:v.b = 2} selects the 95 percent confidence level
of {cmd:cilevel(95)} from the levels (90, 95):

{phang2}{cmd:library(QR.break)}{p_end}
{phang2}{cmd:data(gdp)}{p_end}
{phang2}{cmd:res <- rq.break(y = gdp$gdp, x = gdp[, c("lag1", "lag2")],}{p_end}
{phang2}{cmd:   vec.tau = seq(0.2, 0.8, by = 0.15), N = 1, trim.e = 0.15,}{p_end}
{phang2}{cmd:   vec.time = gdp$yq, m.max = 3, v.a = 2, v.b = 2, verbose = TRUE)}{p_end}

{pstd}
The test statistics, critical values, break dates, confidence intervals, and
coefficient tables printed by the two commands coincide (R prints them in its
own layout; the R return value {cmd:res} holds them in {cmd:res$s.out} and
{cmd:res$m.out}).

{pstd}
{ul:Example 2, with its replication in R: blood alcohol of young drivers}
(Oka and Qu 2011, Section 6.1), a repeated cross section with 108 drivers
per quarter.  In Stata:

{phang2}{cmd:. use https://www.eruygurakademi.com/datasets/qrbreak/driver.dta, clear}{p_end}
{phang2}{cmd:. qrbreak bac age gender winter, tau(0.70(0.05)0.85) nsize(108) trim(0.05) maxbreaks(3) alpha(5) cilevel(95) time(yq)}{p_end}

{pstd}
In R:

{phang2}{cmd:library(QR.break)}{p_end}
{phang2}{cmd:data(driver)}{p_end}
{phang2}{cmd:res <- rq.break(y = driver$bac, x = driver[, c("age", "gender", "winter")],}{p_end}
{phang2}{cmd:   vec.tau = seq(0.70, 0.85, by = 0.05), N = 108, trim.e = 0.05,}{p_end}
{phang2}{cmd:   vec.time = driver$yq, m.max = 3, v.a = 2, v.b = 2, verbose = TRUE)}{p_end}

{pstd}
All deterministic numbers again coincide; only the simulated DQ critical
values differ across runs (in both implementations), because the quantile
range is asymmetric and the R original draws them without a fixed seed.

{pstd}
{ul:Example 3. Choosing the quantiles with tau().}  If the question concerns only the
center of the conditional distribution, a single quantile suffices; only the
SQ analysis is performed and the summary decision is based on it:

{phang2}{cmd:. use https://www.eruygurakademi.com/datasets/qrbreak/gdp.dta, clear}{p_end}
{phang2}{cmd:. qrbreak gdp lag1 lag2, tau(0.5) time(yq)}{p_end}

{pstd}
If breaks may affect different parts of the distribution differently (for
example the lower tail shifting while the median is stable), give a grid of
quantiles; each quantile gets its own SQ analysis and the DQ test pools them
for the overall decision:

{phang2}{cmd:. use https://www.eruygurakademi.com/datasets/qrbreak/gdp.dta, clear}{p_end}
{phang2}{cmd:. qrbreak gdp lag1 lag2, tau(0.2(0.15)0.8) time(yq)}{p_end}

{pstd}
If the application concerns one tail only, use an asymmetric range, as in the
driver example above with {cmd:tau(0.70(0.05)0.85)}; note that for asymmetric
ranges the DQ critical values are obtained by simulation, which takes
additional time and makes those critical values (only) vary across runs.

{pstd}
{ul:Example 4. Repeated cross sections with nsize().}  When each time period contains
{it:N} independent units (households, firms, individuals), sort the data so
that the first {it:N} observations are period 1, the next {it:N} period 2, and
so on, and give {it:N} in {opt nsize()}.  Breaks are then breaks in calendar
time, not in the observation index:

{phang2}{cmd:. use https://www.eruygurakademi.com/datasets/qrbreak/driver.dta, clear}{p_end}
{phang2}{cmd:. qrbreak bac age gender winter, tau(0.75) nsize(108) trim(0.05) time(yq)}{p_end}

{pstd}
{ul:Example 5. Controlling the minimum regime length with trim().}  {opt trim()} sets the
shortest regime the procedure is allowed to consider, as a share of the number
of periods.  Increase it when {it:T} is small or when the coefficient tables
of short regimes would be too imprecise to be useful; decrease it (as in the
driver example, {cmd:trim(0.05)}) when breaks close to the sample boundaries
or close to each other are plausible and {it:T}*{it:trim} still comfortably
exceeds the number of regressors:

{phang2}{cmd:. use https://www.eruygurakademi.com/datasets/qrbreak/gdp.dta, clear}{p_end}
{phang2}{cmd:. qrbreak gdp lag1 lag2, tau(0.5) trim(0.25) time(yq)}{p_end}

{pstd}
{ul:Example 6. Capping the search with maxbreaks().}  The sequential procedure stops at
{opt maxbreaks()} even if the last test still rejects.  Raise it when the
sample is long and many regimes are plausible; each additional break adds
another round of subsample testing:

{phang2}{cmd:. use https://www.eruygurakademi.com/datasets/qrbreak/gdp.dta, clear}{p_end}
{phang2}{cmd:. qrbreak gdp lag1 lag2, tau(0.5) maxbreaks(5) time(yq)}{p_end}

{pstd}
{ul:Example 7. Choosing the decision level with alpha().}  {opt alpha()} only selects
which significance level drives the reported DECISION lines and the summary;
{cmd:alpha(10)} is more liberal (more breaks found), {cmd:alpha(1)} more
conservative.  All three levels are always computed and stored, so the choice
can be revisited from {cmd:e()} without re-running:

{phang2}{cmd:. use https://www.eruygurakademi.com/datasets/qrbreak/gdp.dta, clear}{p_end}
{phang2}{cmd:. qrbreak gdp lag1 lag2, tau(0.2(0.15)0.8) alpha(1) time(yq)}{p_end}
{phang2}{cmd:. matrix list e(sq_nbreak_4)}{p_end}

{pstd}
{ul:Example 8. Confidence interval coverage with cilevel().}  {opt cilevel(90)} reports
narrower 90 percent intervals for the break dates instead of the default 95
percent; use it when the dating precision itself is of interest:

{phang2}{cmd:. use https://www.eruygurakademi.com/datasets/qrbreak/gdp.dta, clear}{p_end}
{phang2}{cmd:. qrbreak gdp lag1 lag2, tau(0.65) cilevel(90) time(yq)}{p_end}

{pstd}
{ul:Example 9. Readable dates with time().}  Without {opt time()} break dates are
reported as observation (period) indices only.  Supplying a date variable
(numeric or string; the value at the first observation of each period is used)
turns every reported date and confidence interval into calendar form:

{phang2}{cmd:. use https://www.eruygurakademi.com/datasets/qrbreak/gdp.dta, clear}{p_end}
{phang2}{cmd:. qrbreak gdp lag1 lag2, tau(0.65)}{p_end}
{phang2}{cmd:. qrbreak gdp lag1 lag2, tau(0.65) time(yq)}{p_end}

{pstd}
{ul:Example 10. Restricting the sample with if/in.}  Any {cmd:if} or {cmd:in} restriction
is applied before the analysis; with {opt nsize()} greater than one make sure
the restriction keeps whole periods:

{phang2}{cmd:. use https://www.eruygurakademi.com/datasets/qrbreak/gdp.dta, clear}{p_end}
{phang2}{cmd:. qrbreak gdp lag1 lag2 in 1/200, tau(0.5) time(yq)}{p_end}

{title:Stored results}

{pstd}
{cmd:qrbreak} stores the following in {cmd:e()} (k = 1, ..., number of
quantiles, in the order of {opt tau()}):

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(T)}}number of time periods{p_end}
{synopt:{cmd:e(nsize)}}cross-section size per period{p_end}
{synopt:{cmd:e(trimsize)}}minimum regime length{p_end}
{synopt:{cmd:e(ntau)}}number of quantiles{p_end}
{synopt:{cmd:e(sq_nb_}{it:k}{cmd:)}}number of breaks detected by the SQ procedure at quantile k and the chosen alpha{p_end}
{synopt:{cmd:e(dq_nbreak)}}number of breaks detected by the DQ procedure at the chosen alpha{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(tau)}}quantiles used{p_end}
{synopt:{cmd:e(sq_test_}{it:k}{cmd:)}}SQ test statistics (1 x maxbreaks){p_end}
{synopt:{cmd:e(sq_cv_}{it:k}{cmd:)}}SQ critical values at 10, 5, 1 percent (3 x maxbreaks){p_end}
{synopt:{cmd:e(sq_nbreak_}{it:k}{cmd:)}}numbers of breaks at 10, 5, 1 percent (3 x 1){p_end}
{synopt:{cmd:e(sq_dates_}{it:k}{cmd:)}}estimated break dates by significance level (3 x maxbreaks){p_end}
{synopt:{cmd:e(sq_ci_}{it:k}{cmd:)}}break date estimates and confidence intervals{p_end}
{synopt:{cmd:e(sq_coef_}{it:k}{cmd:)}}regime coefficient tables, stacked (Value, StdErr, t, p){p_end}
{synopt:{cmd:e(sq_bsize_}{it:k}{cmd:)}}break size tables, stacked{p_end}
{synopt:{cmd:e(dq_test)}, {cmd:e(dq_cv)}, {cmd:e(dq_nbreak_all)}, {cmd:e(dq_dates)}, {cmd:e(dq_ci)}}the DQ counterparts{p_end}
{synopt:{cmd:e(mq_coef_}{it:k}{cmd:)}, {cmd:e(mq_bsize_}{it:k}{cmd:)}}regime coefficients and break sizes at quantile k, conditional on the DQ break dates{p_end}

{title:References}

{phang}
Bai, J. and P. Perron (1998). Estimating and testing linear models with
multiple structural changes. {it:Econometrica} 66(1), 47-78.

{phang}
Bai, J. and P. Perron (2003). Computation and analysis of multiple structural
change models. {it:Journal of Applied Econometrics} 18(1), 1-22.

{phang}
Qu, Z. (2008). Testing for structural change in regression quantiles.
{it:Journal of Econometrics} 146(1), 170-184.

{phang}
Oka, T. and Z. Qu (2011). Estimating structural changes in regression quantiles.
{it:Journal of Econometrics} 162(2), 248-267.

{phang}
Koenker, R. (2005). {it:Quantile Regression}. Cambridge University Press.

{phang}
Qu, Z., T. Oka, and S. Messer (2025). QR.break: Structural Breaks in Quantile
Regression. R package version 1.0.3.

{title:Author}

{pmore}
H. Ozan Eruygur{break}
AHBV University, Ankara, Turkiye.{break}
Department of Economics{break}
{browse "https://www.ozaneruygur.com":https://www.ozaneruygur.com}{break}
{browse "mailto:eruygur@gmail.com":eruygur@gmail.com}

{pmore}
Eruygur Academy and Consulting (Eruygur Akademi ve Danismanlik), Ankara, Turkiye.{break}
{browse "https://www.eruygurakademi.com":https://www.eruygurakademi.com}{break}
{browse "mailto:eruygurakademi@gmail.com":eruygurakademi@gmail.com}

{pmore}
This command is a faithful Stata/Mata port of the R package QR.break v1.0.3 by Zhongjun Qu, Tatsushi Oka, and Samuel Messer, including verbatim ports of the quantreg 6.1 solvers of Roger Koenker.

{pmore}
qrbreak v1.11.0 - July 2026

{pstd}
{ul:Please cite as:}

{phang}
Eruygur, H. O. 2026. {bf:qrbreak}: Structural breaks in quantile regression (testing and estimation).
Stata package version 1.11.1. Available from: {browse "https://www.eruygurakademi.com":https://www.eruygurakademi.com}
