{smcl}
{* *! version 1.0.0  12jun2026  Merwan Roudane}{...}
{vieweralsosee "[XT] xtset" "help xtset"}{...}
{vieweralsosee "[XT] xtreg" "help xtreg"}{...}
{vieweralsosee "[R] qreg" "help qreg"}{...}
{vieweralsosee "[R] bootstrap" "help bootstrap"}{...}
{viewerjumpto "Syntax" "xtheteroquant##syntax"}{...}
{viewerjumpto "Description" "xtheteroquant##description"}{...}
{viewerjumpto "The two designs" "xtheteroquant##designs"}{...}
{viewerjumpto "Options" "xtheteroquant##options"}{...}
{viewerjumpto "Postestimation use" "xtheteroquant##postest"}{...}
{viewerjumpto "Examples" "xtheteroquant##examples"}{...}
{viewerjumpto "Stored results" "xtheteroquant##results"}{...}
{viewerjumpto "Methods and formulas" "xtheteroquant##methods"}{...}
{viewerjumpto "References" "xtheteroquant##references"}{...}
{viewerjumpto "Author" "xtheteroquant##author"}{...}
{hline}
{cmd:help xtheteroquant}{right:version 1.0.0}
{hline}

{marker title}{...}
{title:Title}

{phang}
{bf:xtheteroquant} {hline 2} Quantiles of heterogeneous individual-specific
coefficients in panel data, with SQB and CDQB bootstrap inference
(Galvao, Hounyo and Lin, 2026)


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:xtheteroquant}
[{depvar} [{indepvars}]]
{ifin}
[{cmd:,} {it:options}]

{pstd}
If {it:depvar} is omitted, {cmd:xtheteroquant} runs as a postestimation
command after {helpb xtreg}, {helpb regress}, {helpb reghdfe}, {helpb areg}
or {helpb xtgls}, reusing {cmd:e(depvar)}, the regressors in {cmd:e(b)},
and {cmd:e(sample)}.  The data must be {helpb xtset}.

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt tau(numlist)}}quantile level(s) of the cross-sectional
coefficient distribution; default {cmd:tau(.25 .5 .75)}{p_end}
{synopt:{opt r:eps(#)}}number of bootstrap replications; default
{cmd:reps(200)}{p_end}
{synopt:{opt l:evel(#)}}confidence level; default {cmd:level(95)}{p_end}
{synopt:{opt se:ed(#)}}random-number seed for reproducible bootstrap
draws{p_end}
{synopt:{opt nocons:tant}}suppress the unit-specific intercept in the
first-step regressions{p_end}
{synopt:{opt min:obs(#)}}minimum within-unit observations required;
default max(K+2, {it:#}){p_end}

{syntab:Inference}
{synopt:{opt des:ign(string)}}{cmd:both} (default), {cmd:sqb} (alias
{cmd:stochastic}) or {cmd:cdqb} (alias {cmd:deterministic}); selects
which bootstrap tables/bands are displayed{p_end}
{synopt:{opt cit:ype(string)}}{cmd:basic} (default; centered, as in the
paper) or {cmd:percentile} bootstrap confidence intervals{p_end}
{synopt:{opt null(#)}}null value for the symmetric-tail bootstrap
p-values; default {cmd:null(0)}{p_end}

{syntab:Reporting and graphs}
{synopt:{opt plot}}quantile process plot: estimates and CI bands over a
grid of tau values (one panel per coefficient){p_end}
{synopt:{opt gr:id(#)}}number of grid points for {opt plot}; default
{cmd:grid(19)}, i.e. tau = .05, .10, ..., .95{p_end}
{synopt:{opt plotv:ars(namelist)}}subset of coefficients to plot
(use {cmd:_cons} for the intercept){p_end}
{synopt:{opt dist}}kernel-density plot of the first-step coefficient
estimates with the tau-quantiles marked{p_end}
{synopt:{opt det:ail}}table of the cross-sectional distribution of the
first-step estimates (mean, sd, min, median, max, skewness){p_end}
{synopt:{opt gen1(stub)}}save the first-step unit-specific coefficients
as new variables {it:stub}{cmd:_}{it:varname} (constant for all
observations of a unit){p_end}
{synopt:{opt name(name)}}name for the (combined) graph{p_end}
{synopt:{opt nodots}}suppress bootstrap replication dots{p_end}
{synoptline}
{p 4 6 2}
The panel must be declared with {helpb xtset} before running
{cmd:xtheteroquant}.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:xtheteroquant} implements the two-step estimator of Galvao, Hounyo
and Lin (2026) for the {it:tau}-quantile of the cross-sectional
distribution of heterogeneous individual-specific coefficients in the
linear panel-data model

{p 8 8 2}
y_it = a_i + x_it'b_i + e_it,{space 8}i = 1,...,N,{space 2}t = 1,...,T,

{pstd}
where every unit i has its own intercept a_i {it:and} its own slope
vector b_i.  The procedure is:

{phang2}{bf:Step 1 (individual estimation).}  For each unit i, estimate
the coefficient vector by OLS using only that unit's time series.{p_end}

{phang2}{bf:Step 2 (quantile aggregation).}  For each coefficient, take
the empirical {it:tau}-quantile of the N first-step estimates,
theta_hat(tau) = argmin_theta (1/N) sum_i rho_tau(theta_hat_i - theta),
where rho_tau is the quantile-regression check function.{p_end}

{pstd}
Unlike conventional fixed-effects quantile regression ({helpb qreg} /
panel QR), where {it:tau} indexes the conditional distribution of the
{it:outcome}, here {it:tau} indexes the distribution of the
{it:structural coefficients across units}: tau = .9 answers "what is
the slope for the 90th-percentile most-responsive unit?", not "what is
the effect at the 90th percentile of y?".  Typical uses: heterogeneous
treatment or policy sensitivities, the distribution of mutual-fund
timing skill, firm-specific pass-through, country-specific elasticities.

{pstd}
With {it:depvar} alone (no regressors), the command estimates the
{it:tau}-quantile of unit long-run means (Example 2 in the paper).


{marker designs}{...}
{title:The two designs and the two bootstraps}

{pstd}
The same point estimator targets two different parameters, depending on
how the heterogeneous coefficients are viewed.  {cmd:xtheteroquant}
always computes both bootstrap procedures and reports those requested
in {opt design()}:

{phang2}{bf:Stochastic design (SQB).}  The b_i are random draws from a
larger population, and the target is the population {it:tau}-quantile.
Convergence rate sqrt(N); valid under sqrt(N)/T = O(1).  Inference uses
the {it:Stochastic-design Quantile Bootstrap}: resample time periods
within each unit, then resample units with replacement.  Use this when
your N units are a sample (e.g., a sample of workers, funds, firms).{p_end}

{phang2}{bf:Deterministic design (CDQB).}  The observed N units {it:are}
the population of interest, and the target is the empirical (limiting)
{it:tau}-quantile of the realized coefficients.  Convergence rate
sqrt(N*sqrt(T)); requires roughly sqrt(T) << N << T^(3/2).  Inference
uses the {it:Centered Deterministic-design Quantile Bootstrap}:
resample time periods only, and re-center each bootstrap quantile at
the average bootstrap rank of the original estimate (Remark 2 in the
paper).  Use this when you observe everyone (e.g., all OECD countries,
all funds in the market).{p_end}

{pstd}
Using SQB in a deterministic design is conservative (intervals too
wide); using CDQB in a stochastic design understates uncertainty.  When
in doubt about whether the units are a sample, prefer SQB.


{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opt tau(numlist)} sets the quantile level(s) reported in the tables,
each strictly between 0 and 1.  Default {cmd:tau(.25 .5 .75)}.

{phang}
{opt reps(#)} sets the number of bootstrap replications B.  Default 200.
For publication-quality intervals use 999 or more.

{phang}
{opt level(#)} sets the confidence level; see {helpb level}.

{phang}
{opt seed(#)} sets the random-number seed before drawing bootstrap
samples, making results exactly reproducible.

{phang}
{opt noconstant} omits the unit-specific intercept a_i from the
first-step regressions.

{phang}
{opt minobs(#)} drops units with fewer than max(K+2, {it:#}) time
periods, where K is the number of estimated coefficients.  Units whose
within-unit X'X is singular are also dropped.  The number of dropped
units is reported and stored in {cmd:r(N_drop)}.

{dlgtab:Inference}

{phang}
{opt design(string)} chooses which design's results to display:
{cmd:both} (default), {cmd:sqb}/{cmd:stochastic}, or
{cmd:cdqb}/{cmd:deterministic}.  Both sets of results are always
computed and stored in {cmd:r()} regardless of this option.

{phang}
{opt citype(string)} chooses the bootstrap confidence-interval
construction.  {cmd:basic} (default) is the centered interval implied
by approximating the distribution of (theta_hat - theta) by the
bootstrap distribution of (theta* - theta_hat), as in the paper.
{cmd:percentile} reports the raw percentile interval of the bootstrap
draws.

{phang}
{opt null(#)} sets the hypothesized value theta_0 used in the
symmetric-tail bootstrap p-value
p = (1/B) sum_b 1{ |theta*_b - theta_hat| >= |theta_hat - theta_0| }.
Default 0.

{dlgtab:Reporting and graphs}

{phang}
{opt plot} draws the quantile process plot: for each coefficient, the
estimated {it:tau}-quantile (solid navy line) over a grid of tau values
with SQB (maroon, dashed) and/or CDQB (green, short-dashed) confidence
bands, replicating Figures 1-2 of the paper.  Multiple coefficients are
arranged with {helpb graph combine}.

{phang}
{opt grid(#)} sets the number of equally spaced grid points used by
{opt plot}: tau_g = g/({it:#}+1), g = 1,...,{it:#}.  Default 19.

{phang}
{opt plotvars(namelist)} restricts the plot to the listed coefficients;
use {cmd:_cons} for the intercept.  At most 12 panels are drawn.

{phang}
{opt dist} draws kernel densities of the first-step unit-specific
estimates, one panel per coefficient, with dashed vertical lines at the
estimated {it:tau}-quantiles from {opt tau()}.  A direct visual check
of the shape, skewness, bunching or gaps of the coefficient
distribution (relevant for Assumption 7 of the paper).

{phang}
{opt detail} prints a summary table (mean, sd, min, median, max,
skewness) of the first-step coefficient distribution; also stored in
{cmd:r(firststats)}.

{phang}
{opt gen1(stub)} saves the first-step unit-specific coefficient
estimates as new double variables {it:stub}{cmd:_}{it:varname}
({it:stub}{cmd:_cons} for the intercept), repeated over each unit's
observations.  Handy for second-stage cross-sectional regressions of
coefficients on unit characteristics (conditional quantile model (2.4)
in the paper).

{phang}
{opt name(name)} names the process-plot graph ({it:name}) and the
density graph ({it:name}{cmd:_dist}).  Defaults: {cmd:xthq_process}
and {cmd:xthq_dist}.

{phang}
{opt nodots} suppresses the bootstrap progress dots.


{marker postest}{...}
{title:Postestimation use}

{pstd}
After fitting a pooled or fixed-effects model, calling
{cmd:xtheteroquant} without a varlist reuses the dependent variable,
the regressors and the estimation sample of the previous fit:

{phang2}{cmd:. xtreg y x1 x2, fe}{p_end}
{phang2}{cmd:. xtheteroquant, tau(.25 .5 .75) reps(200)}{p_end}

{pstd}
Note that {cmd:xtheteroquant} always re-estimates the model unit by
unit (heterogeneous slopes); it does not reuse the homogeneous-slope
coefficient estimates, only the variable list and the sample.
Factor-variable and time-series operators in {cmd:e(b)} are not
supported in this mode; supply an explicit varlist instead.
The user's {cmd:e()} results are left untouched.


{marker examples}{...}
{title:Examples}

{pstd}Simulate a heterogeneous-coefficient panel{p_end}
{phang2}{cmd:. clear all}{p_end}
{phang2}{cmd:. set seed 12345}{p_end}
{phang2}{cmd:. set obs 150}{p_end}
{phang2}{cmd:. gen long id = _n}{p_end}
{phang2}{cmd:. gen double a_i  = rnormal()}{p_end}
{phang2}{cmd:. gen double b1_i = rchi2(2)/2}{p_end}
{phang2}{cmd:. gen double b2_i = rnormal(1, .5)}{p_end}
{phang2}{cmd:. expand 60}{p_end}
{phang2}{cmd:. bysort id: gen int t = _n}{p_end}
{phang2}{cmd:. xtset id t}{p_end}
{phang2}{cmd:. gen double x1 = rnormal()}{p_end}
{phang2}{cmd:. gen double x2 = rnormal()}{p_end}
{phang2}{cmd:. gen double y = a_i + b1_i*x1 + b2_i*x2 + rnormal()}{p_end}

{pstd}Quartiles of the heterogeneous slopes, both bootstraps{p_end}
{phang2}{cmd:. xtheteroquant y x1 x2, tau(.25 .5 .75) reps(200) seed(1)}{p_end}

{pstd}More quantiles, percentile CIs, distribution detail{p_end}
{phang2}{cmd:. xtheteroquant y x1 x2, tau(.1 .25 .5 .75 .9) reps(500) citype(percentile) detail}{p_end}

{pstd}Quantile process plot and first-step densities{p_end}
{phang2}{cmd:. xtheteroquant y x1 x2, tau(.5) reps(200) plot grid(19) dist name(demo)}{p_end}

{pstd}Only the stochastic design, slope on x1 only in the plot{p_end}
{phang2}{cmd:. xtheteroquant y x1 x2, tau(.5) reps(200) design(sqb) plot plotvars(x1)}{p_end}

{pstd}As postestimation after xtreg{p_end}
{phang2}{cmd:. xtreg y x1 x2, fe}{p_end}
{phang2}{cmd:. xtheteroquant, tau(.25 .5 .75) reps(200)}{p_end}

{pstd}Quantile of unit long-run means (intercept-only model){p_end}
{phang2}{cmd:. xtheteroquant y, tau(.25 .5 .75) reps(200)}{p_end}

{pstd}Save first-step coefficients for a second-stage cross-section{p_end}
{phang2}{cmd:. xtheteroquant y x1 x2, reps(200) gen1(bhat)}{p_end}
{phang2}{cmd:. egen tag = tag(id)}{p_end}
{phang2}{cmd:. summarize bhat_x1 if tag}{p_end}

{pstd}Access the full results matrix{p_end}
{phang2}{cmd:. matrix list r(table)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:xtheteroquant} stores the following in {cmd:r()}:

{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}number of units used{p_end}
{synopt:{cmd:r(N_drop)}}units dropped (too few obs or singular X'X){p_end}
{synopt:{cmd:r(T_avg)}}average within-unit observations{p_end}
{synopt:{cmd:r(T_min)}}minimum within-unit observations{p_end}
{synopt:{cmd:r(T_max)}}maximum within-unit observations{p_end}
{synopt:{cmd:r(reps)}}bootstrap replications{p_end}
{synopt:{cmd:r(level)}}confidence level{p_end}
{synopt:{cmd:r(K)}}number of coefficients{p_end}
{synopt:{cmd:r(null)}}null value used for p-values{p_end}

{p2col 5 18 22 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:xtheteroquant}{p_end}
{synopt:{cmd:r(depvar)}}dependent variable{p_end}
{synopt:{cmd:r(indepvars)}}regressors{p_end}
{synopt:{cmd:r(coefnames)}}coefficient names (regressors + {cmd:_cons}){p_end}
{synopt:{cmd:r(ivar)}}panel variable{p_end}
{synopt:{cmd:r(tvar)}}time variable{p_end}
{synopt:{cmd:r(citype)}}CI construction used{p_end}
{synopt:{cmd:r(design)}}design(s) displayed{p_end}
{synopt:{cmd:r(taulist)}}quantile levels reported{p_end}

{p2col 5 18 22 2: Matrices}{p_end}
{synopt:{cmd:r(table)}}long results table, one row per
(tau, coefficient): tau, estimate, SQB se/lb/ub/p, CDQB se/lb/ub/p{p_end}
{synopt:{cmd:r(b)}}point estimates, K x #tau{p_end}
{synopt:{cmd:r(se_sqb)}, {cmd:r(lb_sqb)}, {cmd:r(ub_sqb)}, {cmd:r(p_sqb)}}SQB
standard errors, CI bounds and p-values, each K x #tau{p_end}
{synopt:{cmd:r(se_cdqb)}, {cmd:r(lb_cdqb)}, {cmd:r(ub_cdqb)}, {cmd:r(p_cdqb)}}CDQB
analogues{p_end}
{synopt:{cmd:r(taus)}}quantile levels, 1 x #tau{p_end}
{synopt:{cmd:r(firststats)}}first-step coefficient distribution summary,
K x 6{p_end}
{synopt:{cmd:r(first)}}first-step unit-specific estimates, N x K
(omitted if N exceeds the maximum matrix size){p_end}


{marker methods}{...}
{title:Methods and formulas}

{pstd}
{bf:Point estimation.}  For each usable unit i, theta_hat_i is the OLS
coefficient vector from the regression of {it:depvar} on
{it:indepvars} (and a constant) over that unit's time series.  For each
coefficient and each tau, the point estimate is the empirical
tau-quantile of the N first-step estimates,
inf{x : (1/N) sum_i 1{theta_hat_i <= x} >= tau}, which is the
check-function minimizer of Algorithm 1 in the paper.

{pstd}
{bf:SQB (Algorithm 2).}  For b = 1,...,B: (i) within each unit, draw T_i
(y,x) pairs with replacement and recompute theta*_i; (ii) draw N units
with replacement and take the empirical tau-quantile of the selected
theta*_i, giving theta**_b.  The CI is constructed from the
distribution of (theta**_b - theta_hat).

{pstd}
{bf:CDQB (Algorithm 3).}  Step (i) is identical.  No unit resampling is
performed.  The centering probability is
p*_tau = (1/B) sum_b (1/N) sum_i 1{theta*_bi <= theta_hat(tau)}, and
each centered bootstrap quantile theta*_b,c is the empirical
p*_tau-quantile of {theta*_bi : i = 1,...,N}.  The CI is constructed
from the distribution of (theta*_b,c - theta_hat).

{pstd}
{bf:CIs and p-values.}  With {cmd:citype(basic)} the (1-alpha) interval
is [2*theta_hat - Q_{1-alpha/2}, 2*theta_hat - Q_{alpha/2}], where Q_p
denotes the p-quantile of the bootstrap draws; with
{cmd:citype(percentile)} it is [Q_{alpha/2}, Q_{1-alpha/2}].  Bootstrap
standard errors are the standard deviations of the draws.  P-values are
symmetric-tail: p = (1/B) sum_b 1{ |draw_b - theta_hat| >=
|theta_hat - theta_0| }.


{marker references}{...}
{title:References}

{phang}
Galvao, A. F., U. Hounyo, and J. Lin.  2026.  Estimation and inference
for the tau-quantile of heterogeneous individual-specific coefficients.
Working paper, arXiv:2605.01923.

{phang}
Koenker, R., and G. Bassett.  1978.  Regression quantiles.
{it:Econometrica} 46(1): 33-50.

{phang}
Koenker, R.  2004.  Quantile regression for longitudinal data.
{it:Journal of Multivariate Analysis} 91(1): 74-89.

{phang}
Galvao, A. F., and K. Kato.  2016.  Smoothed quantile regression for
panel data.  {it:Journal of Econometrics} 193(1): 92-112.

{phang}
Galvao, A. F., J. Gu, and S. Volgushev.  2020.  On the unbiased
asymptotic normality of quantile regression with fixed effects.
{it:Journal of Econometrics} 218(1): 178-215.


{marker author}{...}
{title:Author}

{pstd}
Merwan Roudane{break}
Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
GitHub: {browse "https://github.com/merwanroudane":github.com/merwanroudane}

{pstd}
Please cite both the original paper (Galvao, Hounyo and Lin, 2026) and
this implementation when using {cmd:xtheteroquant} in published work.
{p_end}
