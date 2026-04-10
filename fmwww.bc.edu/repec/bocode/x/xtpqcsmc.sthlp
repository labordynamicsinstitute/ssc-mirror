{smcl}
{* *! version 1.0.1  08apr2026}{...}
{vieweralsosee "xtpqcs" "help xtpqcs"}{...}
{vieweralsosee "xtpqcsplot" "help xtpqcsplot"}{...}
{viewerjumpto "Syntax" "xtpqcsmc##syntax"}{...}
{viewerjumpto "Description" "xtpqcsmc##description"}{...}
{viewerjumpto "Options" "xtpqcsmc##options"}{...}
{viewerjumpto "Requirements" "xtpqcsmc##requirements"}{...}
{viewerjumpto "Warnings and cautions" "xtpqcsmc##warnings"}{...}
{viewerjumpto "Examples" "xtpqcsmc##examples"}{...}
{viewerjumpto "Stored results" "xtpqcsmc##results"}{...}
{viewerjumpto "DGP details" "xtpqcsmc##dgp"}{...}
{viewerjumpto "References" "xtpqcsmc##references"}{...}
{viewerjumpto "Author" "xtpqcsmc##author"}{...}
{title:Title}

{phang}
{bf:xtpqcsmc} {hline 2} Monte Carlo replication for panel quantile
regression with common shocks


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:xtpqcsmc}
[{cmd:,} {it:options}]

{synoptset 32 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Panel dimensions}
{synopt:{cmdab:n(}{it:#}{cmd:)}}number of cross-sectional units N; default {cmd:250}{p_end}
{synopt:{cmdab:tp:eriods(}{it:#}{cmd:)}}number of time periods T; default {cmd:25}{p_end}

{syntab:Simulation}
{synopt:{cmdab:r:eps(}{it:#}{cmd:)}}number of Monte Carlo replications; default {cmd:200}{p_end}
{synopt:{cmdab:q:uantile(}{it:#}{cmd:)}}quantile index tau in (0,1) to evaluate; default {cmd:0.5}{p_end}
{synopt:{cmdab:s:eed(}{it:#}{cmd:)}}random-number seed for reproducibility; default {cmd:20260220}{p_end}

{syntab:DGP parameters}
{synopt:{cmdab:betac:oef(}{it:#}{cmd:)}}slope coefficient beta; default {cmd:1.0}{p_end}
{synopt:{cmdab:gammac:oef(}{it:#}{cmd:)}}heterogeneity parameter gamma; default {cmd:0.2}{p_end}

{syntab:Display}
{synopt:{cmdab:nodo:ts}}suppress the progress dots{p_end}

{syntab:Output}
{synopt:{cmdab:sav:ing(}{it:filename}{cmd:)}}save the replication-level dataset to disk{p_end}
{synoptline}

{pstd}
{cmd:xtpqcsmc} takes {bf:no varlist} and {bf:no data} in memory.
It generates its own panel data from the DGP described below.


{marker description}{...}
{title:Description}

{pstd}
{cmd:xtpqcsmc} replicates the Monte Carlo experiment in {bf:Section 5}
of Chiang, Galvao and Wei (2026) to verify the numerical properties
of the {cmd:xtpqcs} estimator.  It:

{p 8 12 2}
1. Generates {cmd:reps()} independent panels from the location-scale DGP
   with common shocks (see {it:DGP details} below).{p_end}
{p 8 12 2}
2. Estimates the FEQR model using {cmd:xtpqcs} at the specified quantile.{p_end}
{p 8 12 2}
3. Records the estimated coefficient, both SE types, and both rejection
   indicators.{p_end}
{p 8 12 2}
4. Reports the {bf:bias}, {bf:RMSE}, and {bf:95% coverage rate} for
   both the robust and classical covariance estimators.{p_end}

{pstd}
The expected outcome (matching Tables 1 and 2 of the paper):

{phang3}
{bf:Robust coverage} should be close to 0.95 (nominal level).{p_end}
{phang3}
{bf:Classical coverage} should be {bf:below} 0.95, often markedly so,
illustrating the size distortion from ignoring common shocks.{p_end}


{marker options}{...}
{title:Options}

{dlgtab:Panel dimensions}

{phang}
{cmdab:n(}{it:#}{cmd:)} sets the number of cross-sectional units.
Default is 250.  Must be >= 5.

{phang}
{cmdab:tp:eriods(}{it:#}{cmd:)} sets the number of time periods.
Default is 25.  Must be >= 5.  Larger T improves the approximation
quality.

{dlgtab:Simulation}

{phang}
{cmdab:r:eps(}{it:#}{cmd:)} sets the number of Monte Carlo replications.
Default is 200.  For publishable results use reps(1000) or more.
For a quick check, reps(30) is sufficient.

{phang}
{cmdab:q:uantile(}{it:#}{cmd:)} specifies the quantile index tau
to estimate.  Must lie strictly between 0 and 1.  Default is 0.5
(median).  To replicate the full set of paper results, run the
command at 0.25, 0.50, and 0.75.

{phang}
{cmdab:s:eed(}{it:#}{cmd:)} sets the random-number seed for
exact reproducibility.  Default is 20260220.

{dlgtab:DGP parameters}

{phang}
{cmdab:betac:oef(}{it:#}{cmd:)} the slope parameter in the
location-scale DGP.  Default is 1.0.

{phang}
{cmdab:gammac:oef(}{it:#}{cmd:)} the heterogeneity parameter gamma
controlling the strength of quantile heterogeneity.  Default is 0.2.
The true quantile regression coefficient is:

{p 12 16 2}
beta(tau) = betacoef + gammacoef * Phi{sup:-1}(tau)

{pmore}
where Phi{sup:-1} is the standard normal quantile function.

{dlgtab:Display}

{phang}
{cmdab:nodo:ts} suppresses the progress dots printed every 10
replications.  Useful when running in batch mode with log output.

{dlgtab:Output}

{phang}
{cmdab:sav:ing(}{it:filename}{cmd:)} saves the replication-level
dataset (one row per replication, columns: rep, bhat, se_rob, se_cl,
reject_rob, reject_cl) to the specified file.  Use
{cmd:saving(mc_results, replace)} to overwrite.


{marker requirements}{...}
{title:Requirements}

{phang}
{bf:Stata version:} 14.0 or later.

{phang}
{bf:Dependencies:} {cmd:xtpqcs} must be installed.

{phang}
{bf:Data in memory:} {cmd:xtpqcsmc} generates its own data, so it
will {bf:clear} any data currently in memory during execution.  The
original data is restored via {cmd:preserve/restore}.

{phang}
{bf:Computation time (approximate):}

{p 8 12 2}
N=50, T=15, reps=30: ~ 30 seconds (quick check){p_end}
{p 8 12 2}
N=250, T=25, reps=200: ~ 30 minutes{p_end}
{p 8 12 2}
N=500, T=50, reps=1000: ~ 6+ hours{p_end}


{marker warnings}{...}
{title:Warnings and cautions}

{phang}
{err:{bf:WARNING: Data in memory will be cleared.}}  {cmd:xtpqcsmc}
uses {cmd:clear} inside the replication loop.  It wraps everything
in {cmd:preserve/restore}, so your original data should be safe, but
save your work first as a precaution.

{phang}
{err:{bf:WARNING: Computation time.}}  Each replication runs a full
{cmd:xtpqcs} estimation.  With n(500) tperiods(50) reps(1000), the
command may run for many hours.  Start with a small run
({cmd:n(50) tperiods(15) reps(30)}) to verify everything works.

{phang}
{err:{bf:WARNING: Seed sensitivity.}}  The default seed is 20260220.
For robustness, re-run with multiple seeds and verify that the
coverage rates are stable.

{phang}
{err:{bf:CAUTION: Interpreting coverage.}}  With reps(30), the
95% coverage estimate has a standard error of ~4 percentage points.
Report coverage rates from runs with reps >= 200 for reliable
inference.

{phang}
{err:{bf:CAUTION: Small N or T.}}  With N < 30 or T < 10, the
asymptotic approximation may be poor, and coverage rates may deviate
from nominal.  This does not indicate a bug; it reflects finite-sample
bias documented in the paper.


{marker examples}{...}
{title:Examples}

{pstd}
{bf:Example 1: Quick validation (30 seconds)}{p_end}

{phang}{cmd:. xtpqcsmc, n(50) tperiods(15) reps(30) quantile(0.50)}{p_end}

{pstd}
{bf:Example 2: Replicate paper Table 1 (median, standard design)}{p_end}

{phang}{cmd:. xtpqcsmc, n(250) tperiods(25) reps(500) quantile(0.50)}{p_end}

{pstd}
{bf:Example 3: Full replication at three quantiles}{p_end}

{phang}{cmd:. foreach q in 0.25 0.50 0.75 {c -(}}{p_end}
{phang}{cmd:.     xtpqcsmc, n(250) tperiods(25) reps(500) quantile(`q')}{p_end}
{phang}{cmd:. {c )-}}{p_end}

{pstd}
{bf:Example 4: Save replication-level data for custom analysis}{p_end}

{phang}{cmd:. xtpqcsmc, n(200) tperiods(20) reps(200) quantile(0.50) saving(mc_results)}{p_end}
{phang}{cmd:. use mc_results, clear}{p_end}
{phang}{cmd:. histogram bhat, normal title("Distribution of beta_hat(0.50)")}{p_end}

{pstd}
{bf:Example 5: Strong heterogeneity (larger gamma)}{p_end}

{phang}{cmd:. xtpqcsmc, n(200) tperiods(30) reps(200) quantile(0.50) gammacoef(0.5)}{p_end}

{pstd}
{bf:Example 6: Large panel, many reps (publishable results)}{p_end}

{phang}{cmd:. xtpqcsmc, n(500) tperiods(50) reps(1000) quantile(0.50) seed(12345)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:xtpqcsmc} stores the following in {cmd:r()}:

{synoptset 24 tabbed}{...}
{p2col 5 24 28 2: Scalars}{p_end}
{synopt:{cmd:r(bias)}}mean bias: E[beta_hat] - beta(tau){p_end}
{synopt:{cmd:r(rmse)}}root mean squared error of beta_hat{p_end}
{synopt:{cmd:r(cov_robust)}}empirical 95% coverage rate using the robust CI{p_end}
{synopt:{cmd:r(cov_classical)}}empirical 95% coverage rate using the classical CI{p_end}


{marker dgp}{...}
{title:DGP details}

{pstd}
The data-generating process follows Section 5 of Chiang, Galvao and
Wei (2026).  For each panel:

{p 8 12 2}
1. alpha{subscript:i} ~ Uniform(0, 1),  i = 1,...,N{p_end}
{p 8 12 2}
2. X{subscript:it} = chi{sup:2}(3) + 0.3 * alpha{subscript:i}{p_end}
{p 8 12 2}
3. eta{subscript:t} ~ N(0,1) {hline 2} the {bf:common shock} shared across all i{p_end}
{p 8 12 2}
4. eps{subscript:it} ~ N(0,1) {hline 2} idiosyncratic error{p_end}
{p 8 12 2}
5. U{subscript:it} = (eps{subscript:it} + eta{subscript:t}) / sqrt(2){p_end}
{p 8 12 2}
6. Y{subscript:it} = alpha{subscript:i} + beta * X{subscript:it} + (1 + gamma * X{subscript:it}) * U{subscript:it}{p_end}

{pstd}
This is a {bf:location-scale} model.  The true quantile regression
slope at quantile tau is:

{p 8 16 2}
beta(tau) = beta + gamma * Phi{sup:-1}(tau)

{pstd}
The common shock eta{subscript:t} induces {bf:cross-sectional
dependence} in the errors.  The classical estimator ignores this
dependence and produces SEs that are too small; the robust estimator
accounts for it correctly.


{marker references}{...}
{title:References}

{phang}
Chiang, H. D., A. F. Galvao, and C.-M. Wei. 2026.
{browse "https://arxiv.org/abs/2602.19201":Panel Quantile Regression with Common Shocks}.
{it:arXiv:2602.19201}, Section 5.

{phang}
Koenker, R. 2004. Quantile regression for longitudinal data.
{it:Journal of Multivariate Analysis} 91: 74{c -}89.


{marker also_see}{...}
{title:Also see}

{psee}
{space 2}Help:  {helpb xtpqcs}, {helpb xtpqcsplot}


{marker author}{...}
{title:Author}

{pstd}
{bf:Dr. Merwan Roudane}{break}
Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
Stata implementation of Chiang, Galvao and Wei (2026).
