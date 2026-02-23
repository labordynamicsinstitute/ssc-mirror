{smcl}
{* *! version 4.2.0  16feb2026}{...}
{vieweralsosee "[BAYES] bayesmh" "help bayesmh"}{...}
{vieweralsosee "[ME] mixed" "help mixed"}{...}
{vieweralsosee "[ME] melogit" "help melogit"}{...}
{vieweralsosee "[XT] xtreg" "help xtreg"}{...}
{vieweralsosee "CmdStan" "browse https://mc-stan.org/users/interfaces/cmdstan"}{...}
{viewerjumpto "Syntax" "bayeshmc##syntax"}{...}
{viewerjumpto "Description" "bayeshmc##description"}{...}
{viewerjumpto "Options" "bayeshmc##options"}{...}
{viewerjumpto "Subcommands" "bayeshmc##subcommands"}{...}
{viewerjumpto "Supported models" "bayeshmc##models"}{...}
{viewerjumpto "Covariance priors" "bayeshmc##covpriors"}{...}
{viewerjumpto "Diagnostic plots" "bayeshmc##diagnostics"}{...}
{viewerjumpto "Model comparison" "bayeshmc##comparison"}{...}
{viewerjumpto "Stored results" "bayeshmc##stored"}{...}
{viewerjumpto "Technical notes" "bayeshmc##technical"}{...}
{viewerjumpto "Examples" "bayeshmc##examples"}{...}
{viewerjumpto "References" "bayeshmc##references"}{...}
{viewerjumpto "Authors" "bayeshmc##authors"}{...}
{title:Title}

{p2colset 5 22 24 2}{...}
{p2col:{bf:bayeshmc} {hline 2}}Bayesian estimation via Hamiltonian Monte Carlo
using CmdStan{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{pstd}
{bf:Setup (required before first use)}

{p 8 16 2}
{cmd:bayeshmc, setup path(}{it:cmdstan_path}{cmd:)}

{pstd}
{bf:Estimation}

{p 8 16 2}
{cmd:bayeshmc} [{cmd:,} {it:options}] {cmd::} {it:estimation_command}

{pstd}
{bf:Postestimation}

{p 8 16 2}
{cmd:bayeshmc summary}

{p 8 16 2}
{cmd:bayeshmc ess}

{p 8 16 2}
{cmd:bayeshmc trace} [{cmd:,} {cmdab:par:ameters(}{it:namelist}{cmd:)} {cmdab:sav:ing(}{it:filename}{cmd:)}]

{p 8 16 2}
{cmd:bayeshmc ac} [{cmd:,} {cmdab:par:ameters(}{it:namelist}{cmd:)} {cmdab:lag:s(}{it:#}{cmd:)} {cmdab:sav:ing(}{it:filename}{cmd:)}]

{p 8 16 2}
{cmd:bayeshmc density} [{cmd:,} {cmdab:par:ameters(}{it:namelist}{cmd:)} {cmdab:sav:ing(}{it:filename}{cmd:)}]

{p 8 16 2}
{cmd:bayeshmc histogram} [{cmd:,} {cmdab:par:ameters(}{it:namelist}{cmd:)} {cmdab:sav:ing(}{it:filename}{cmd:)}]

{p 8 16 2}
{cmd:bayeshmc waic}

{p 8 16 2}
{cmd:bayeshmc loo}


{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:MCMC}
{synopt:{opt iter:ations(#)}}number of post-warmup iterations per chain;
default is {cmd:iterations(2000)}{p_end}
{synopt:{opt warm:up(#)}}number of warmup (adaptation) iterations per chain;
default is {cmd:warmup(1000)}{p_end}
{synopt:{opt chain:s(#)}}number of Markov chains; default is {cmd:chains(4)}{p_end}
{synopt:{opt seed(#)}}random-number seed; default is random{p_end}
{synopt:{opt thin(#)}}thinning interval; default is {cmd:thin(1)}{p_end}

{syntab:Sampler tuning}
{synopt:{opt adapt_delta(#)}}target acceptance rate; default is {cmd:adapt_delta(0.8)}.
Increase toward 1.0 for difficult posteriors.{p_end}
{synopt:{opt max_treedepth(#)}}maximum tree depth for NUTS; default is
{cmd:max_treedepth(10)}{p_end}

{syntab:Priors}
{synopt:{opt normalprior(#)}}standard deviation of normal prior on regression
coefficients; default is {cmd:normalprior(100)}{p_end}
{synopt:{opt prior_sd(#)}}synonym for {cmd:normalprior()}{p_end}
{synopt:{opt lkjprior(#)}}LKJ concentration parameter eta for correlation
matrices; default is {cmd:lkjprior(1)} (uniform over correlations){p_end}
{synopt:{opt covprior(string)}}prior for unstructured covariance matrix;
one of {cmd:lkj}, {cmd:iw}, {cmd:siw}, {cmd:huangwand}, {cmd:spherical};
default is {cmd:covprior(lkj)}.
See {help bayeshmc##covpriors:Covariance priors} below.{p_end}

{syntab:Credible intervals}
{synopt:{opt clevel(#)}}set credible level; default is {cmd:clevel(95)}{p_end}
{synopt:{opt hpd}}report highest posterior density (HPD) intervals instead of
equal-tailed intervals{p_end}

{syntab:Execution}
{synopt:{opt par:allel}}run chains in parallel (one process per chain){p_end}
{synopt:{opt thr:eads(#)}}number of threads per chain for within-chain
parallelism; default is {cmd:threads(1)}{p_end}
{synopt:{opt cmdstan(path)}}override the stored CmdStan installation path{p_end}
{synopt:{opt nocache}}force recompilation of the Stan model even if
unchanged{p_end}
{synopt:{opt dryrun}}write the Stan code and data files but do not sample{p_end}
{synopt:{opt verbose}}display detailed progress messages{p_end}

{syntab:Reporting}
{synopt:{opt noheader}}suppress the output header{p_end}
{synopt:{opt sav:ing(filename)}}save MCMC draws to a Stata dataset{p_end}

{syntab:Parameterization}
{synopt:{opt reparam}}use non-centered parameterization for random effects
(may improve sampling in sparse data){p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:bayeshmc} fits Bayesian regression models using the No-U-Turn Sampler
(NUTS), a variant of Hamiltonian Monte Carlo (HMC), implemented through
CmdStan.  It provides a Stata-native interface that automatically generates
Stan code, exports data in JSON format, invokes the CmdStan sampler, and
parses the posterior draws back into Stata for inference and visualization.

{pstd}
The command supports a wide range of single-level, multilevel (mixed-effects),
and panel (random-effects) models.  The syntax mirrors Stata's native
estimation commands: users type {cmd:bayeshmc :} followed by a standard Stata
estimation command exactly as they would type it otherwise.

{pstd}
Compared with Stata's built-in {cmd:bayes:} prefix (which uses the
Metropolis--Hastings algorithm), {cmd:bayeshmc} uses gradient-based sampling
via NUTS/HMC, which typically delivers higher effective sample sizes per
iteration, better mixing for complex posteriors, and is the gold standard for
Bayesian computation as implemented in Stan.

{pstd}
{bf:Prerequisites.}  CmdStan must be installed on the user's system.
See {browse "https://mc-stan.org/users/interfaces/cmdstan":mc-stan.org} for
installation instructions.  After installation, run
{cmd:bayeshmc, setup path(}{it:cmdstan_path}{cmd:)} once to register the
path.


{marker options}{...}
{title:Options}

{dlgtab:MCMC}

{phang}
{opt iterations(#)} specifies the number of post-warmup draws per chain.
The total number of draws equals {it:iterations} x {it:chains}.
Default is 2000.

{phang}
{opt warmup(#)} specifies the number of warmup (adaptation) iterations during
which the sampler tunes its step size and mass matrix.  These draws are
discarded.  Default is 1000.  For complex models (e.g., multilevel or
heteroskedastic), consider increasing to 2000--4000.

{phang}
{opt chains(#)} specifies the number of independent Markov chains.
Running multiple chains enables R-hat convergence diagnostics.  Default is 4.

{phang}
{opt seed(#)} sets the random-number seed for reproducibility.  If not
specified, a random seed is used.

{phang}
{opt thin(#)} specifies the thinning interval; only every {it:#}-th draw is
retained.  Thinning is generally unnecessary with HMC but may reduce storage
for very long runs.  Default is 1 (no thinning).

{dlgtab:Sampler tuning}

{phang}
{opt adapt_delta(#)} sets the target average acceptance probability during
warmup adaptation.  Higher values (e.g., 0.95 or 0.99) yield smaller step
sizes, reducing divergent transitions at the cost of slower sampling.
Default is 0.8.  If you see divergent transition warnings, increase this
value.

{phang}
{opt max_treedepth(#)} sets the maximum tree depth for the NUTS algorithm.
The number of leapfrog steps per iteration is at most 2^{it:max_treedepth}.
Default is 10.  Increase to 12--15 if you see maximum treedepth warnings.

{dlgtab:Priors}

{phang}
{opt normalprior(#)} specifies the standard deviation of the normal prior
placed on all regression coefficients: beta_k ~ N(0, {it:#}^2).  Default is
100, yielding a weakly informative prior.  For standardized data, values of
1--10 may be more appropriate.  {opt prior_sd(#)} is a synonym.

{phang}
{opt lkjprior(#)} specifies the concentration parameter eta of the LKJ prior
on the correlation matrix in multilevel models with unstructured covariance.
When eta = 1 (default), the prior is uniform over all valid correlation
matrices.  When eta > 1, the prior increasingly favors the identity matrix
(weak correlations).  When eta < 1, the prior favors extreme correlations.
This option is relevant only for {cmd:covprior(lkj)} and
{cmd:covprior(huangwand)}.

{phang}
{opt covprior(string)} selects the prior distribution for the unstructured
covariance matrix in multilevel models.
See {help bayeshmc##covpriors:Covariance priors} for details.

{dlgtab:Credible intervals}

{phang}
{opt clevel(#)} specifies the credible interval level as a percentage.
Default is 95.

{phang}
{opt hpd} requests highest posterior density (HPD) intervals.  By default,
equal-tailed intervals are reported.  HPD intervals are the shortest intervals
containing the specified probability mass and are preferred for asymmetric
posteriors.

{dlgtab:Execution}

{phang}
{opt parallel} runs chains in parallel as separate operating-system processes.
This can substantially reduce wall-clock time on multicore machines.  Each
chain runs as an independent CmdStan process.

{phang}
{opt threads(#)} specifies the number of OpenMP threads per chain for
within-chain parallelism via Stan's {cmd:reduce_sum} mechanism.
Default is 1.

{phang}
{opt cmdstan(path)} overrides the CmdStan path previously set by
{cmd:bayeshmc, setup}.  Useful when multiple CmdStan versions are installed.

{phang}
{opt nocache} forces recompilation of the Stan model.  By default,
{cmd:bayeshmc} caches compiled models and reuses them if the Stan code has not
changed.

{phang}
{opt dryrun} writes the Stan code ({cmd:model.stan}) and data
({cmd:data.json}) files without invoking the sampler.  Useful for inspecting
or customizing the generated Stan code.

{phang}
{opt verbose} displays additional progress messages during model compilation
and sampling.


{marker subcommands}{...}
{title:Subcommands}

{pstd}
After estimation, the following postestimation subcommands are available.
All operate on the draws from the most recent {cmd:bayeshmc} estimation.

{phang}
{cmd:bayeshmc summary} displays a table of posterior summaries (mean, SD, MCSE,
median, and credible interval) for all parameters.

{phang}
{cmd:bayeshmc ess} displays effective sample sizes (ESS) and split-chain R-hat
for all parameters.  ESS is computed using the variogram-based estimator of
Vehtari et al. (2021).  R-hat uses the rank-normalized split-chain diagnostic.

{phang}
{cmd:bayeshmc trace} [{cmd:,} {cmd:parameters(}{it:namelist}{cmd:)}
{cmd:saving(}{it:filename}{cmd:)}]
produces trace plots of MCMC draws by iteration.  By default, the first four
parameters are plotted.  Specify {cmd:parameters()} to choose specific
parameters using their display names (e.g., {cmd:parameters(y.sens_ind y._cons)}).

{phang}
{cmd:bayeshmc ac} [{cmd:,} {cmd:parameters(}{it:namelist}{cmd:)}
{cmd:lags(}{it:#}{cmd:)} {cmd:saving(}{it:filename}{cmd:)}]
produces autocorrelation plots.  Default is 40 lags.

{phang}
{cmd:bayeshmc density} [{cmd:,} {cmd:parameters(}{it:namelist}{cmd:)}
{cmd:saving(}{it:filename}{cmd:)}]
produces kernel density plots of the posterior distributions.

{phang}
{cmd:bayeshmc histogram} [{cmd:,} {cmd:parameters(}{it:namelist}{cmd:)}
{cmd:saving(}{it:filename}{cmd:)}]
produces histograms of the posterior distributions.

{phang}
{cmd:bayeshmc waic} computes the Widely Applicable Information Criterion
(Watanabe 2010) using the pointwise log-likelihood.

{phang}
{cmd:bayeshmc loo} computes the leave-one-out cross-validation information
criterion using Pareto-smoothed importance sampling (PSIS-LOO; Vehtari,
Gelman, and Gabry 2017).


{marker models}{...}
{title:Supported models}

{pstd}
{cmd:bayeshmc} supports the following Stata estimation commands.  The Stata
command is typed after the colon exactly as in frequentist estimation.

{dlgtab:Continuous outcomes}

{p2colset 7 32 34 2}{...}
{p2col:{cmd:regress}}linear regression{p_end}
{p2col:{cmd:tobit}}tobit (censored) regression{p_end}
{p2col:{cmd:truncreg}}truncated regression{p_end}
{p2col:{cmd:intreg}}interval regression{p_end}
{p2col:{cmd:hetregress}}heteroskedastic regression{p_end}
{p2col:{cmd:betareg}}beta regression for fractional outcomes{p_end}
{p2col:{cmd:heckman}}Heckman selection model{p_end}
{p2col:{cmd:glm}}generalized linear model{p_end}
{p2colreset}{...}

{dlgtab:Binary outcomes}

{p2colset 7 32 34 2}{...}
{p2col:{cmd:logit} / {cmd:logistic}}logistic regression{p_end}
{p2col:{cmd:probit}}probit regression{p_end}
{p2col:{cmd:cloglog}}complementary log-log regression{p_end}
{p2col:{cmd:hetprobit}}heteroskedastic probit{p_end}
{p2col:{cmd:heckprobit}}probit with sample selection{p_end}
{p2colreset}{...}

{dlgtab:Count outcomes}

{p2colset 7 32 34 2}{...}
{p2col:{cmd:poisson}}Poisson regression{p_end}
{p2col:{cmd:nbreg}}negative binomial regression{p_end}
{p2col:{cmd:gnbreg}}generalized negative binomial regression{p_end}
{p2col:{cmd:tpoisson}}truncated Poisson regression{p_end}
{p2col:{cmd:zip}}zero-inflated Poisson regression{p_end}
{p2col:{cmd:zinb}}zero-inflated negative binomial regression{p_end}
{p2colreset}{...}

{dlgtab:Ordinal outcomes}

{p2colset 7 32 34 2}{...}
{p2col:{cmd:ologit}}ordered logistic regression{p_end}
{p2col:{cmd:oprobit}}ordered probit regression{p_end}
{p2col:{cmd:hetoprobit}}heteroskedastic ordered probit{p_end}
{p2colreset}{...}

{dlgtab:Multinomial outcomes}

{p2colset 7 32 34 2}{...}
{p2col:{cmd:mlogit}}multinomial logistic regression{p_end}
{p2colreset}{...}

{dlgtab:Survival outcomes}

{p2colset 7 32 34 2}{...}
{p2col:{cmd:streg}}parametric survival regression (Weibull){p_end}
{p2colreset}{...}

{dlgtab:Panel (random-effects) models}

{pstd}
These require {cmd:xtset} to be set before estimation.  A single
random intercept per panel unit is estimated.

{p2colset 7 32 34 2}{...}
{p2col:{cmd:xtreg}}linear panel RE regression{p_end}
{p2col:{cmd:xtlogit}}logistic panel RE regression{p_end}
{p2col:{cmd:xtprobit}}probit panel RE regression{p_end}
{p2col:{cmd:xtpoisson}}Poisson panel RE regression{p_end}
{p2col:{cmd:xtnbreg}}negative binomial panel RE regression{p_end}
{p2col:{cmd:xtologit}}ordered logistic panel RE regression{p_end}
{p2col:{cmd:xtoprobit}}ordered probit panel RE regression{p_end}
{p2colreset}{...}

{dlgtab:Multilevel (mixed-effects) models}

{pstd}
These use the {cmd:|| groupvar:} syntax for random effects and support
{cmd:covariance(unstructured)} for correlated random effects.

{p2colset 7 32 34 2}{...}
{p2col:{cmd:mixed}}linear mixed-effects regression{p_end}
{p2col:{cmd:melogit}}mixed-effects logistic regression{p_end}
{p2col:{cmd:meprobit}}mixed-effects probit regression{p_end}
{p2col:{cmd:mecloglog}}mixed-effects complementary log-log{p_end}
{p2col:{cmd:mepoisson}}mixed-effects Poisson regression{p_end}
{p2col:{cmd:menbreg}}mixed-effects negative binomial regression{p_end}
{p2col:{cmd:meologit}}mixed-effects ordered logistic regression{p_end}
{p2col:{cmd:meoprobit}}mixed-effects ordered probit regression{p_end}
{p2col:{cmd:metobit}}mixed-effects tobit regression{p_end}
{p2col:{cmd:mestreg}}mixed-effects parametric survival regression{p_end}
{p2col:{cmd:meglm}}mixed-effects generalized linear model{p_end}
{p2col:{cmd:mehetregress}}mixed-effects heteroskedastic regression{p_end}
{p2col:{cmd:mehetoprobit}}mixed-effects heteroskedastic ordered probit{p_end}
{p2colreset}{...}

{pstd}
Multilevel models with the {cmd:binomial(}{it:varname}{cmd:)} option are
supported for grouped binomial data (e.g., diagnostic test accuracy
meta-analysis).


{marker covpriors}{...}
{title:Covariance priors for unstructured random effects}

{pstd}
For multilevel models with {cmd:covariance(unstructured)}, {cmd:bayeshmc}
supports five prior specifications for the random-effects covariance matrix.
These are selected via the {cmd:covprior()} option.  All priors produce the
same output parameters ({cmd:sigma_u}, {cmd:var_u}, {cmd:corr}) regardless of
the internal parameterization.

{dlgtab:covprior(lkj) -- LKJ decomposition (default)}

{pstd}
Decomposes the covariance matrix into standard deviations and correlations:

{p 8 8 2}
tau_k ~ half-Cauchy(0, 2.5){break}
L_Omega ~ LKJ_corr_cholesky(eta){break}
Sigma = diag(tau) * Omega * diag(tau)

{pstd}
The concentration parameter eta is set via {cmd:lkjprior()}.  When eta = 1,
the prior is uniform over all valid correlation matrices.  This is the
recommended default and the most widely used prior in the Stan community
(Lewandowski, Kurowicka, and Joe 2009; Stan Development Team 2024).

{dlgtab:covprior(iw) -- Inverse-Wishart}

{pstd}
The classical conjugate prior:

{p 8 8 2}
Sigma ~ Inverse-Wishart(R + 1, I_R)

{pstd}
where R is the dimension (number of random effects) and I_R is the R x R
identity matrix.  The degrees of freedom R + 1 yield the least informative
proper Inverse-Wishart.  This prior couples the marginal variances and
correlations, which can be undesirable.  It tends to shrink the correlation
toward zero and may underestimate variance components
(Alvarez, Niemi, and Simpson 2014).

{dlgtab:covprior(siw) -- Scaled Inverse-Wishart}

{pstd}
The scaled Inverse-Wishart (Gelman and Hill 2007; O'Malley and Zaslavsky 2008)
ameliorates the coupling problem of the standard IW by introducing marginal
scale parameters:

{p 8 8 2}
xi_k ~ half-Cauchy(0, 2.5){break}
S_raw ~ Inverse-Wishart(R + 1, I_R){break}
Sigma = diag(xi) * S_raw * diag(xi)

{pstd}
The scale parameters xi allow each variance component to be adjusted
independently before the IW is applied, giving better marginal behavior for
each variance.

{dlgtab:covprior(huangwand) -- Huang-Wand}

{pstd}
The Huang and Wand (2013) prior uses a scale-mixture representation to place
independent half-t priors on the standard deviations while retaining an LKJ
prior on the correlations:

{p 8 8 2}
a_k ~ Inverse-Gamma(1/2, 1/A^2) with A = 2.5{break}
tau_k | a_k ~ half-Normal(0, a_k){break}
L_Omega ~ LKJ_corr_cholesky(eta){break}
Sigma = diag(tau) * Omega * diag(tau)

{pstd}
The marginal prior on each tau_k is half-t with heavy tails, providing
robustness for sparse or weakly identified variance components.  This prior
is recommended for small-sample multilevel models and diagnostic test accuracy
meta-analysis (Huang and Wand 2013).

{dlgtab:covprior(spherical) -- Spherical decomposition}

{pstd}
The spherical (angular) decomposition parameterizes the Cholesky factor of
the correlation matrix through hyperspherical coordinates
(Pinheiro and Bates 1996; Rapisarda, Brigo, and Mercurio 2007):

{p 8 8 2}
tau_k ~ half-Cauchy(0, 2.5){break}
theta_m ~ Uniform(0, pi)  for m = 1, ..., R(R-1)/2{break}
L = f(theta){break}
Sigma = diag(tau) * L L' * diag(tau)

{pstd}
Each row of the Cholesky factor is computed from cosines and cumulative
products of sines of the angles.  A Jacobian adjustment ensures the implied
prior on the correlation matrix is uniform.  For R = 2 (the most common case
in bivariate meta-analysis), there is a single angle theta and the correlation
is simply cos(theta), which is uniform on (-1, 1).

{pstd}
This parameterization avoids the implicit regularization of LKJ and provides
a truly flat prior over the space of positive-definite correlation matrices.

{pstd}
{bf:Choosing a covariance prior.}  In practice, the choice of covariance
prior matters most for small samples, few groups, or weakly identified variance
components.  For well-identified models with moderate-to-large numbers of
groups, the five priors typically give very similar results.  When in doubt:

{p 8 8 2}
{bf:Default:} {cmd:covprior(lkj)} with {cmd:lkjprior(1)} -- well-tested, the
Stan community standard.{break}
{bf:Small samples:} {cmd:covprior(huangwand)} -- robust half-t tails prevent
boundary estimates.{break}
{bf:Prior sensitivity:} Fit the model under two or three priors and compare
posteriors.  Agreement indicates robustness.{break}
{bf:Truly flat correlation prior:} {cmd:covprior(spherical)} -- uniform on
correlation space without the implicit geometry of LKJ.


{marker diagnostics}{...}
{title:Diagnostic plots}

{pstd}
Graphical MCMC diagnostics are essential for assessing convergence and
identifying sampling problems.

{phang}
{cmd:bayeshmc trace} shows the time series of draws for each parameter.
A well-mixing chain appears as a "fuzzy caterpillar" with no trends or
periods of stasis.

{phang}
{cmd:bayeshmc ac} shows the autocorrelation function.  Low autocorrelation
indicates efficient sampling.  HMC/NUTS typically exhibits much lower
autocorrelation than Metropolis--Hastings.

{phang}
{cmd:bayeshmc density} shows kernel density estimates of the posterior.
Overlay with prior distributions to assess prior sensitivity.

{phang}
{cmd:bayeshmc histogram} shows histograms of the posterior draws.

{pstd}
All diagnostic commands accept {cmd:parameters(}{it:namelist}{cmd:)} to select
specific parameters using their display names (as shown in the output table).
By default, the first four parameters are plotted.  All accept
{cmd:saving(}{it:filename}{cmd:)} to save the graph.


{marker comparison}{...}
{title:Model comparison}

{phang}
{cmd:bayeshmc waic} computes the Widely Applicable Information Criterion:

{p 8 8 2}
WAIC = -2 * (lppd - p_waic)

{pstd}
where lppd is the log pointwise predictive density and p_waic is the
effective number of parameters (Watanabe 2010; Gelman, Hwang, and
Vehtari 2014).

{phang}
{cmd:bayeshmc loo} computes the PSIS-LOO (Pareto-smoothed importance
sampling leave-one-out) cross-validation estimate:

{p 8 8 2}
LOO = -2 * sum_i log(p(y_i | y_{-i}))

{pstd}
estimated via importance sampling with Pareto-smoothed weights (Vehtari,
Gelman, and Gabry 2017).  PSIS-LOO is generally preferred over WAIC for model
comparison.  Pareto k diagnostics indicate reliability: k < 0.5 is good,
0.5 < k < 0.7 is acceptable, k > 0.7 suggests the approximation may be
unreliable.


{marker stored}{...}
{title:Stored results}

{pstd}
{cmd:bayeshmc} stores the following in {cmd:e()}:

{synoptset 24 tabbed}{...}
{p2col 5 24 28 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(chains)}}number of chains{p_end}
{synopt:{cmd:e(mcmc_size)}}total number of posterior draws{p_end}

{p2col 5 24 28 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:bayeshmc}{p_end}
{synopt:{cmd:e(family)}}estimation command (e.g., {cmd:melogit}){p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}

{p2col 5 24 28 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}posterior means{p_end}
{synopt:{cmd:e(V)}}diagonal matrix of posterior variances{p_end}
{p2colreset}{...}


{marker technical}{...}
{title:Technical notes}

{dlgtab:How bayeshmc works}

{pstd}
{cmd:bayeshmc} operates in five stages:

{phang}
1. {bf:Parse.}  The Stata estimation command is parsed to identify the model
family, dependent variable, predictors, grouping structure, and covariance
type.

{phang}
2. {bf:Generate.}  A Stan program is automatically written to the CmdStan
working directory.  The program specifies the data block, parameters, priors,
likelihood, and generated quantities (including pointwise log-likelihoods for
WAIC/LOO).

{phang}
3. {bf:Export.}  Data are exported from Stata to JSON format.  Design matrices,
grouping indicators, and trial counts (for binomial models) are included.

{phang}
4. {bf:Sample.}  CmdStan compiles the Stan program (if not cached) and runs
the NUTS sampler.  Each chain produces a CSV file of posterior draws.

{phang}
5. {bf:Parse results.}  The CSV output files are read back into Mata.  Summary
statistics, ESS, and R-hat are computed.  Results are displayed in a
Stata-style table and stored in {cmd:e()}.

{dlgtab:Effective sample size (ESS)}

{pstd}
ESS is computed using the variogram-based estimator of Vehtari et al. (2021),
which improves upon the traditional autocorrelation-based estimator by using
the variogram V_t = mean((x_{i+t} - x_i)^2) and Geyer's initial monotone
sequence truncation.  The estimator is:

{p 8 8 2}
rho_hat(t) = 1 - V_t / (2 * var_hat_plus){break}
ESS = m * n / (1 + 2 * sum_{t=1}^{T} rho_hat(t))

{pstd}
where m is the number of chains and n is the draws per chain.  For a single
chain, the chain is split in half and treated as two chains.

{dlgtab:R-hat convergence diagnostic}

{pstd}
R-hat compares within-chain and between-chain variance.  Values near 1.0
indicate convergence.  R-hat > 1.01 suggests the chains have not converged.
{cmd:bayeshmc} reports the maximum R-hat across all parameters in the header.

{dlgtab:Divergent transitions}

{pstd}
Divergent transitions indicate that the sampler encountered regions of high
curvature in the posterior that it could not accurately explore.  If divergences
occur, increase {cmd:adapt_delta()} toward 0.95 or 0.99, or reparameterize
the model using {cmd:reparam}.

{dlgtab:Model caching}

{pstd}
Compiled Stan models are cached in the CmdStan working directory.  If you
run the same model type with different data, the cached executable is reused,
saving compilation time (typically 30--60 seconds).  Use {cmd:nocache} to
force recompilation.

{dlgtab:Default priors}

{pstd}
{cmd:bayeshmc} uses the following default priors unless overridden:

{p2colset 7 36 38 2}{...}
{p2col:Parameter}Default prior{p_end}
{p2line}
{p2col:Regression coefficients (beta)}N(0, 100^2){p_end}
{p2col:Intercept (alpha)}N(0, 100^2){p_end}
{p2col:Residual SD (sigma)}half-Cauchy(0, 5){p_end}
{p2col:Random-effect SDs (tau)}half-Cauchy(0, 2.5){p_end}
{p2col:Correlation matrix (Omega)}LKJ(eta = 1){p_end}
{p2col:Cutpoints (ordered models)}N(0, 10^2){p_end}
{p2col:Overdispersion (phi, nbreg)}half-Cauchy(0, 5){p_end}
{p2col:Weibull shape}Gamma(1, 1){p_end}
{p2col:Beta regression precision}Gamma(0.01, 0.01){p_end}
{p2colreset}{...}


{marker examples}{...}
{title:Examples}

{pstd}
All examples assume CmdStan has been set up:

{phang2}{cmd:. bayeshmc, setup path(C:\Users\username\.cmdstan\cmdstan-2.38.0)}{p_end}

{pstd}
{bf:{ul:Basic single-level models}}

    {title:Example 1: Linear regression}

{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. bayeshmc, iter(2000) chains(4) seed(12345) : regress price mpg weight}{p_end}
{phang2}{cmd:. bayeshmc summary}{p_end}
{phang2}{cmd:. bayeshmc ess}{p_end}

    {title:Example 2: Logistic regression with full diagnostics}

{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. bayeshmc, iter(2000) chains(4) seed(12345) : logit foreign mpg weight}{p_end}
{phang2}{cmd:. bayeshmc trace}{p_end}
{phang2}{cmd:. bayeshmc ac, lags(30)}{p_end}
{phang2}{cmd:. bayeshmc density}{p_end}
{phang2}{cmd:. bayeshmc histogram}{p_end}

    {title:Example 3: Probit regression with tighter prior}

{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. bayeshmc, iter(2000) chains(4) normalprior(10) seed(12345) :}{p_end}
{phang2}{cmd:      probit foreign mpg weight length}{p_end}

    {title:Example 4: Ordered logistic regression with HPD intervals}

{phang2}{cmd:. webuse fullauto, clear}{p_end}
{phang2}{cmd:. bayeshmc, iter(2000) chains(4) hpd clevel(90) seed(12345) :}{p_end}
{phang2}{cmd:      ologit rep77 foreign price mpg}{p_end}

    {title:Example 5: Complementary log-log regression}

{phang2}{cmd:. webuse lbw, clear}{p_end}
{phang2}{cmd:. bayeshmc, iter(2000) chains(4) seed(12345) : cloglog low age lwt smoke}{p_end}

{pstd}
{bf:{ul:Count data models}}

    {title:Example 6: Poisson regression}

{phang2}{cmd:. webuse airline, clear}{p_end}
{phang2}{cmd:. bayeshmc, iter(2000) chains(4) seed(12345) : poisson injuries XYZowned}{p_end}

    {title:Example 7: Negative binomial regression}

{phang2}{cmd:. webuse medpar, clear}{p_end}
{phang2}{cmd:. bayeshmc, iter(2000) chains(4) seed(12345) : nbreg los type2 type3 hmo}{p_end}

    {title:Example 8: Zero-inflated Poisson}

{phang2}{cmd:. webuse fish, clear}{p_end}
{phang2}{cmd:. bayeshmc, iter(2000) chains(4) seed(12345) :}{p_end}
{phang2}{cmd:      zip count persons livebait, inflate(child camper)}{p_end}

    {title:Example 9: Zero-inflated negative binomial}

{phang2}{cmd:. webuse fish, clear}{p_end}
{phang2}{cmd:. bayeshmc, iter(2000) chains(4) seed(12345) :}{p_end}
{phang2}{cmd:      zinb count persons livebait, inflate(child camper)}{p_end}

    {title:Example 10: Truncated Poisson}

{phang2}{cmd:. webuse tpoisson1, clear}{p_end}
{phang2}{cmd:. bayeshmc, iter(2000) chains(4) seed(12345) : tpoisson count x1 x2, ll(0)}{p_end}

{pstd}
{bf:{ul:Special continuous models}}

    {title:Example 11: Beta regression for fractional outcomes}

{phang2}{cmd:. webuse gastinger, clear}{p_end}
{phang2}{cmd:. bayeshmc, iter(2000) chains(4) seed(12345) :}{p_end}
{phang2}{cmd:      betareg fev1rate i.center age}{p_end}

    {title:Example 12: Tobit regression}

{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. bayeshmc, iter(2000) chains(4) seed(12345) : tobit mpg weight foreign, ll(17)}{p_end}

    {title:Example 13: Truncated regression}

{phang2}{cmd:. webuse truncreg, clear}{p_end}
{phang2}{cmd:. bayeshmc, iter(2000) chains(4) seed(12345) : truncreg wage age educ, ll(0)}{p_end}

    {title:Example 14: Interval regression}

{phang2}{cmd:. webuse intregxmpl, clear}{p_end}
{phang2}{cmd:. bayeshmc, iter(2000) chains(4) seed(12345) :}{p_end}
{phang2}{cmd:      intreg wage1 wage2 age nev_mar rural school tenure}{p_end}

    {title:Example 15: Heteroskedastic regression}

{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. bayeshmc, iter(2000) chains(4) seed(12345) : hetregress price mpg weight, het(foreign)}{p_end}

    {title:Example 16: Heteroskedastic probit}

{phang2}{cmd:. webuse lbw, clear}{p_end}
{phang2}{cmd:. bayeshmc, iter(2000) chains(4) seed(12345) : hetprobit low age lwt smoke, het(race)}{p_end}

{pstd}
{bf:{ul:Selection models}}

    {title:Example 17: Heckman selection model}

{phang2}{cmd:. webuse womenwk, clear}{p_end}
{phang2}{cmd:. bayeshmc, iter(2000) chains(4) seed(12345) :}{p_end}
{phang2}{cmd:      heckman wage education age, select(married children education age)}{p_end}

    {title:Example 18: Heckman probit}

{phang2}{cmd:. webuse womenwk, clear}{p_end}
{phang2}{cmd:. gen byte employed = (wage < .)}{p_end}
{phang2}{cmd:. bayeshmc, iter(2000) chains(4) seed(12345) :}{p_end}
{phang2}{cmd:      heckprobit employed education age, select(married children education age)}{p_end}

{pstd}
{bf:{ul:Multinomial outcomes}}

    {title:Example 19: Multinomial logistic regression}

{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. bayeshmc, iter(2000) chains(4) seed(12345) :}{p_end}
{phang2}{cmd:      mlogit rep78 price mpg weight foreign}{p_end}

{pstd}
{bf:{ul:Survival analysis}}

    {title:Example 20: Weibull survival regression}

{phang2}{cmd:. webuse cancer, clear}{p_end}
{phang2}{cmd:. stset studytime, failure(died)}{p_end}
{phang2}{cmd:. bayeshmc, iter(2000) chains(4) seed(12345) : streg age drug, distribution(weibull)}{p_end}

{pstd}
{bf:{ul:Panel (random-effects) models}}

    {title:Example 21: Panel linear RE}

{phang2}{cmd:. webuse nlswork, clear}{p_end}
{phang2}{cmd:. xtset idcode year}{p_end}
{phang2}{cmd:. bayeshmc, iter(1000) chains(2) seed(12345) : xtreg ln_wage age ttl_exp tenure}{p_end}

    {title:Example 22: Panel logistic RE}

{phang2}{cmd:. webuse nlswork, clear}{p_end}
{phang2}{cmd:. xtset idcode year}{p_end}
{phang2}{cmd:. gen byte highwage = (ln_wage > 1.6) if ln_wage < .}{p_end}
{phang2}{cmd:. bayeshmc, iter(1000) chains(2) seed(12345) : xtlogit highwage age ttl_exp tenure}{p_end}

    {title:Example 23: Panel Poisson RE}

{phang2}{cmd:. webuse nlswork, clear}{p_end}
{phang2}{cmd:. xtset idcode year}{p_end}
{phang2}{cmd:. gen hours_cat = round(hours/10) if hours < .}{p_end}
{phang2}{cmd:. bayeshmc, iter(1000) chains(2) seed(12345) : xtpoisson hours_cat age ttl_exp tenure}{p_end}

    {title:Example 24: Panel ordered logit RE}

{phang2}{cmd:. webuse nlswork, clear}{p_end}
{phang2}{cmd:. xtset idcode year}{p_end}
{phang2}{cmd:. egen wage_cat = cut(ln_wage), group(4)}{p_end}
{phang2}{cmd:. replace wage_cat = wage_cat + 1}{p_end}
{phang2}{cmd:. bayeshmc, iter(1000) chains(2) seed(12345) : xtologit wage_cat age ttl_exp tenure}{p_end}

{pstd}
{bf:{ul:Multilevel (mixed-effects) models}}

    {title:Example 25: Linear mixed model with random intercept}

{phang2}{cmd:. webuse nlswork, clear}{p_end}
{phang2}{cmd:. bayeshmc, iter(2000) chains(4) seed(12345) :}{p_end}
{phang2}{cmd:      mixed ln_wage age ttl_exp tenure || idcode:}{p_end}

    {title:Example 26: Mixed-effects logistic regression}

{phang2}{cmd:. webuse bangladesh, clear}{p_end}
{phang2}{cmd:. bayeshmc, iter(2000) chains(4) seed(12345) :}{p_end}
{phang2}{cmd:      melogit c_use urban age child* || district:}{p_end}

    {title:Example 27: Mixed-effects Poisson}

{phang2}{cmd:. webuse epilepsy, clear}{p_end}
{phang2}{cmd:. bayeshmc, iter(2000) chains(4) seed(12345) :}{p_end}
{phang2}{cmd:      mepoisson seizures treat lbas lbas_trt lage visit || subject:}{p_end}

    {title:Example 28: Mixed-effects negative binomial}

{phang2}{cmd:. webuse epilepsy, clear}{p_end}
{phang2}{cmd:. bayeshmc, iter(2000) chains(4) seed(12345) :}{p_end}
{phang2}{cmd:      menbreg seizures treat lbas lbas_trt lage visit || subject:}{p_end}

{pstd}
{bf:{ul:Diagnostic test accuracy (DTA) meta-analysis}}

    {title:Example 29: Bivariate DTA meta-analysis (LKJ prior, default)}

{pstd}
The bivariate random-effects model for DTA meta-analysis (Reitsma et al. 2005;
Chu and Cole 2006) is fitted using {cmd:melogit} with binomial data and
unstructured random effects for sensitivity and specificity:

{phang2}{cmd:. use dta_data, clear}{p_end}
{phang2}{cmd:. bayeshmc, iter(1000) warmup(2000) chains(4) seed(49830) :}{p_end}
{phang2}{cmd:      melogit y sens_ind || study: sens_ind,}{p_end}
{phang2}{cmd:      covariance(unstructured) binomial(n)}{p_end}
{phang2}{cmd:. bayeshmc summary}{p_end}
{phang2}{cmd:. bayeshmc ess}{p_end}
{phang2}{cmd:. bayeshmc trace, parameters(y.sens_ind y._cons sigma_u1._cons sigma_u2._cons)}{p_end}
{phang2}{cmd:. bayeshmc density, parameters(y.sens_ind y._cons)}{p_end}

    {title:Example 30: DTA meta-analysis with Inverse-Wishart prior}

{phang2}{cmd:. bayeshmc, iter(1000) warmup(2000) chains(4) covprior(iw) seed(49830) :}{p_end}
{phang2}{cmd:      melogit y sens_ind || study: sens_ind,}{p_end}
{phang2}{cmd:      covariance(unstructured) binomial(n)}{p_end}

    {title:Example 31: DTA meta-analysis with Scaled Inverse-Wishart prior}

{phang2}{cmd:. bayeshmc, iter(1000) warmup(2000) chains(4) covprior(siw) seed(49830) :}{p_end}
{phang2}{cmd:      melogit y sens_ind || study: sens_ind,}{p_end}
{phang2}{cmd:      covariance(unstructured) binomial(n)}{p_end}

    {title:Example 32: DTA meta-analysis with Huang-Wand prior}

{pstd}
Recommended for meta-analyses with few studies (< 10):

{phang2}{cmd:. bayeshmc, iter(1000) warmup(2000) chains(4) covprior(huangwand) seed(49830) :}{p_end}
{phang2}{cmd:      melogit y sens_ind || study: sens_ind,}{p_end}
{phang2}{cmd:      covariance(unstructured) binomial(n)}{p_end}

    {title:Example 33: DTA meta-analysis with spherical decomposition prior}

{pstd}
Provides a uniform prior on the (-1, 1) correlation space for R = 2:

{phang2}{cmd:. bayeshmc, iter(1000) warmup(2000) chains(4) covprior(spherical) seed(49830) :}{p_end}
{phang2}{cmd:      melogit y sens_ind || study: sens_ind,}{p_end}
{phang2}{cmd:      covariance(unstructured) binomial(n)}{p_end}

{pstd}
{bf:{ul:Model comparison}}

    {title:Example 34: Comparing Poisson vs. negative binomial with WAIC and LOO}

{phang2}{cmd:. webuse medpar, clear}{p_end}

{phang2}{cmd:. * Model 1: Poisson}{p_end}
{phang2}{cmd:. bayeshmc, iter(2000) chains(4) seed(12345) : poisson los type2 type3 hmo}{p_end}
{phang2}{cmd:. bayeshmc waic}{p_end}
{phang2}{cmd:. bayeshmc loo}{p_end}

{phang2}{cmd:. * Model 2: Negative binomial}{p_end}
{phang2}{cmd:. bayeshmc, iter(2000) chains(4) seed(12345) : nbreg los type2 type3 hmo}{p_end}
{phang2}{cmd:. bayeshmc waic}{p_end}
{phang2}{cmd:. bayeshmc loo}{p_end}

{pstd}
Lower WAIC and LOO indicate better out-of-sample predictive performance.

{pstd}
{bf:{ul:Execution options}}

    {title:Example 35: Parallel chains for faster estimation}

{phang2}{cmd:. bayeshmc, iter(4000) warmup(2000) chains(4) parallel seed(12345) :}{p_end}
{phang2}{cmd:      mixed ln_wage age ttl_exp tenure || idcode:}{p_end}

    {title:Example 36: Fixing divergent transitions}

{pstd}
If you see divergent transition warnings, increase adapt_delta:

{phang2}{cmd:. bayeshmc, iter(2000) chains(4) adapt_delta(0.95) max_treedepth(12)}{p_end}
{phang2}{cmd:      seed(12345) : melogit y x || group: x, covariance(unstructured)}{p_end}

    {title:Example 37: Inspecting the generated Stan code}

{pstd}
Use {cmd:dryrun} to examine and optionally customize the Stan program before
sampling:

{phang2}{cmd:. bayeshmc, dryrun verbose : melogit y x || group:, cov(unstruct)}{p_end}

{pstd}
The Stan file will be written to
{cmd:{it:cmdstan_path}/bhmc3_work/model.stan} and can be inspected with
{cmd:type} or edited manually before rerunning.

    {title:Example 38: Specific parameters in diagnostic plots}

{phang2}{cmd:. bayeshmc, iter(2000) chains(4) seed(12345) : regress price mpg weight foreign}{p_end}
{phang2}{cmd:. bayeshmc trace, parameters(price.mpg price.weight)}{p_end}
{phang2}{cmd:. bayeshmc ac, parameters(price.mpg) lags(50)}{p_end}
{phang2}{cmd:. bayeshmc density, parameters(price.mpg price.weight price._cons)}{p_end}
{phang2}{cmd:. bayeshmc histogram, parameters(sigma._cons) saving(sigma_hist)}{p_end}


{marker references}{...}
{title:References}

{pstd}
{bf:Hamiltonian Monte Carlo and NUTS}

{phang}
Betancourt, M. 2018.
A conceptual introduction to Hamiltonian Monte Carlo.
{it:arXiv:1701.02434}.

{phang}
Duane, S., A. D. Kennedy, B. J. Pendleton, and D. Roweth. 1987.
Hybrid Monte Carlo.
{it:Physics Letters B} 195: 216--222.

{phang}
Hoffman, M. D., and A. Gelman. 2014.
The No-U-Turn Sampler: Adaptively setting path lengths in Hamiltonian Monte
Carlo.
{it:Journal of Machine Learning Research} 15: 1593--1623.

{phang}
Neal, R. M. 2011.
MCMC using Hamiltonian dynamics.
In {it:Handbook of Markov Chain Monte Carlo}, ed. S. Brooks, A. Gelman,
G. Jones, and X.-L. Meng, 113--162. Boca Raton, FL: Chapman and Hall/CRC.

{pstd}
{bf:Convergence diagnostics}

{phang}
Brooks, S. P., and A. Gelman. 1998.
General methods for monitoring convergence of iterative simulations.
{it:Journal of Computational and Graphical Statistics} 7: 434--455.

{phang}
Gelman, A., and D. B. Rubin. 1992.
Inference from iterative simulation using multiple sequences.
{it:Statistical Science} 7: 457--472.

{phang}
Geyer, C. J. 1992.
Practical Markov chain Monte Carlo.
{it:Statistical Science} 7: 473--483.

{phang}
Vehtari, A., A. Gelman, D. Simpson, B. Carpenter, and P.-C. Buerkner. 2021.
Rank-normalization, folding, and localization: An improved R-hat for assessing
convergence of MCMC (with discussion).
{it:Bayesian Analysis} 16: 667--718.

{pstd}
{bf:Model comparison}

{phang}
Gelman, A., J. Hwang, and A. Vehtari. 2014.
Understanding predictive information criteria for Bayesian models.
{it:Statistics and Computing} 24: 997--1016.

{phang}
Vehtari, A., A. Gelman, and J. Gabry. 2017.
Practical Bayesian model evaluation using leave-one-out cross-validation and
WAIC.
{it:Statistics and Computing} 27: 1413--1432.

{phang}
Watanabe, S. 2010.
Asymptotic equivalence of Bayes cross validation and widely applicable
information criterion in singular learning theory.
{it:Journal of Machine Learning Research} 11: 3571--3594.

{pstd}
{bf:Covariance matrix priors}

{phang}
Alvarez, I., J. Niemi, and M. Simpson. 2014.
Bayesian inference for a covariance matrix.
{it:Proceedings of the 26th Annual Conference on Applied Statistics in
Agriculture}.

{phang}
Gelman, A., and J. Hill. 2007.
{it:Data Analysis Using Regression and Multilevel/Hierarchical Models}.
Cambridge: Cambridge University Press.

{phang}
Huang, A., and M. P. Wand. 2013.
Simple marginally noninformative prior distributions for covariance matrices.
{it:Bayesian Analysis} 8: 439--452.

{phang}
Lewandowski, D., D. Kurowicka, and H. Joe. 2009.
Generating random correlation matrices based on vines and extended onion
method.
{it:Journal of Multivariate Analysis} 100: 1989--2001.

{phang}
O'Malley, A. J., and A. M. Zaslavsky. 2008.
Domain-level covariance analysis for multilevel survey data with structured
nonresponse.
{it:Journal of the American Statistical Association} 103: 1405--1418.

{phang}
Pinheiro, J. C., and D. M. Bates. 1996.
Unconstrained parameterizations for variance-covariance matrices.
{it:Statistics and Computing} 6: 289--296.

{phang}
Rapisarda, F., D. Brigo, and F. Mercurio. 2007.
Parameterizing correlations: A geometric interpretation.
{it:IMA Journal of Management Mathematics} 18: 55--73.

{pstd}
{bf:Diagnostic test accuracy meta-analysis}

{phang}
Chu, H., and S. R. Cole. 2006.
Bivariate meta-analysis of sensitivity and specificity with sparse data: A
generalized linear mixed model approach.
{it:Journal of Clinical Epidemiology} 59: 1331--1332.

{phang}
Dwamena, B. A. 2007.
MIDAS: Stata module for meta-analytical integration of diagnostic test
accuracy studies.
{it:Statistical Software Components} S456880, Boston College Department of
Economics.

{phang}
Dwamena, B. A. 2017.
MIDAS: An update for comprehensive diagnostic test accuracy meta-analysis
in Stata.
Presented at the 2017 Stata Conference, Baltimore, MD.

{phang}
Macaskill, P. 2004.
Empirical Bayes estimates generated in a hierarchical summary ROC analysis
agreed closely with those of a full Bayesian analysis.
{it:Journal of Clinical Epidemiology} 57: 925--932.

{phang}
Reitsma, J. B., A. S. Glas, A. W. S. Rutjes, R. J. P. M. Scholten,
P. M. Bossuyt, and A. H. Zwinderman. 2005.
Bivariate analysis of sensitivity and specificity produces informative summary
measures in diagnostic reviews.
{it:Journal of Clinical Epidemiology} 58: 982--990.

{phang}
Rutter, C. M., and C. A. Gatsonis. 2001.
A hierarchical regression approach to meta-analysis of diagnostic test
accuracy evaluations.
{it:Statistics in Medicine} 20: 2865--2884.

{pstd}
{bf:Bayesian methodology}

{phang}
Carpenter, B., A. Gelman, M. D. Hoffman, D. Lee, B. Goodrich, M. Betancourt,
M. Brambilla, J. Guo, P. Li, and A. Riddell. 2017.
Stan: A probabilistic programming language.
{it:Journal of Statistical Software} 76(1): 1--32.

{phang}
Gelman, A., J. B. Carlin, H. S. Stern, D. B. Dunson, A. Vehtari, and
D. B. Rubin. 2013.
{it:Bayesian Data Analysis}. 3rd ed.
Boca Raton, FL: Chapman and Hall/CRC.

{phang}
McElreath, R. 2020.
{it:Statistical Rethinking: A Bayesian Course with Examples in R and Stan}.
2nd ed. Boca Raton, FL: Chapman and Hall/CRC.

{phang}
Stan Development Team. 2024.
{it:Stan User's Guide}. Version 2.35.
{browse "https://mc-stan.org/users/documentation/"}

{pstd}
{bf:Related software}

{phang}
Buerkner, P.-C. 2017.
brms: An R package for Bayesian multilevel models using Stan.
{it:Journal of Statistical Software} 80(1): 1--28.

{phang}
Gabry, J., R. Cesnovar, and A. Johnson. 2024.
{it:CmdStanR: R Interface to CmdStan}.
{browse "https://mc-stan.org/cmdstanr/"}

{phang}
Grant, R. L. 2017.
The Stata interface for Stan.
{it:Stata Journal} 17: 662--670.

{phang}
Rue, H., S. Martino, and N. Chopin. 2009.
Approximate Bayesian inference for latent Gaussian models by using integrated
nested Laplace approximations.
{it:Journal of the Royal Statistical Society, Series B} 71: 319--392.


{marker authors}{...}
{title:Authors}

{pstd}
Ben A. Dwamena, MD{break}
Clinical Associate Professor Emeritus of Radiology{break}
Division of Nuclear Medicine and Molecular Imaging{break}
University of Michigan, Ann Arbor{break}
{browse "mailto:bdwamena@umich.edu":bdwamena@umich.edu}

{pstd}
The MIDAS suite ({cmd:midas}, {cmd:midas_mh}, {cmd:bayeshmc}, and related
commands) is maintained by B. A. Dwamena.  For bug reports and feature
requests, please contact the author.


{marker also_see}{...}
{title:Also see}

{psee}
Help:  {helpb bayesmh}, {helpb mixed}, {helpb melogit}, {helpb meprobit},
{helpb xtreg}, {helpb xtlogit}

{psee}
Web:  {browse "https://mc-stan.org":Stan website},
{browse "https://mc-stan.org/users/interfaces/cmdstan":CmdStan documentation}
{p_end}
