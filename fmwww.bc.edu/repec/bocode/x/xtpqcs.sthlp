{smcl}
{* *! version 1.0.1  08apr2026}{...}
{vieweralsosee "[R] qreg" "help qreg"}{...}
{vieweralsosee "xtpqcsplot" "help xtpqcsplot"}{...}
{vieweralsosee "xtpqcsmc" "help xtpqcsmc"}{...}
{viewerjumpto "Syntax" "xtpqcs##syntax"}{...}
{viewerjumpto "Description" "xtpqcs##description"}{...}
{viewerjumpto "Options" "xtpqcs##options"}{...}
{viewerjumpto "Requirements" "xtpqcs##requirements"}{...}
{viewerjumpto "Technical notes" "xtpqcs##technical"}{...}
{viewerjumpto "Warnings and cautions" "xtpqcs##warnings"}{...}
{viewerjumpto "Examples" "xtpqcs##examples"}{...}
{viewerjumpto "Stored results" "xtpqcs##results"}{...}
{viewerjumpto "References" "xtpqcs##references"}{...}
{viewerjumpto "Author" "xtpqcs##author"}{...}
{title:Title}

{phang}
{bf:xtpqcs} {hline 2} Panel Quantile Regression with Common Shocks


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:xtpqcs} {depvar} {indepvars} {ifin}{cmd:,}
{cmdab:i:d(}{varname}{cmd:)}
{cmdab:t:ime(}{varname}{cmd:)}
[{it:options}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{cmdab:i:d(}{varname}{cmd:)}}cross-sectional unit identifier (numeric){p_end}
{synopt:{cmdab:t:ime(}{varname}{cmd:)}}time period identifier (numeric){p_end}

{syntab:Estimation}
{synopt:{cmdab:q:uantile(}{it:#}{cmd:)}}quantile index tau in (0,1); default {cmd:0.5}{p_end}
{synopt:{cmdab:b:andwidth(}{it:#}{cmd:)}}kernel bandwidth h > 0; default Silverman with floor 0.05{p_end}
{synopt:{cmdab:k:ernel(}{it:string}{cmd:)}}{cmd:gaussian} (default), {cmd:epanechnikov}, or {cmd:uniform}{p_end}
{synopt:{cmdab:comp:are}}report classical Kato et al. (2012) SEs instead of robust SEs{p_end}

{syntab:Reporting}
{synopt:{cmd:level(}{it:#}{cmd:)}}confidence level for CI; default {cmd:level(95)}{p_end}
{synopt:{cmdab:nohe:ader}}suppress the header table above the coefficient table{p_end}
{synoptline}

{pstd}
{depvar} and {indepvars} must be numeric variables.
The panel must contain at least 2 cross-sectional units
and at least 5 time periods.
Missing values are excluded via {cmd:marksample}.


{marker description}{...}
{title:Description}

{pstd}
{cmd:xtpqcs} estimates the fixed-effects panel quantile regression (FEQR) model

{p 8 16 2}
Q{subscript:tau}(Y{subscript:it} | X{subscript:it}, alpha{subscript:i}) =
alpha{subscript:i}(tau) + X{subscript:it}{c '}beta(tau)

{pstd}
using the unregularised Koenker (2004) concentration algorithm and reports
the {bf:robust covariance matrix} of {bf:Chiang, Galvao and Wei (2026,
arXiv:2602.19201)}, which remains consistent in the presence (or absence) of
pervasive common time shocks B{subscript:t} that induce arbitrary
cross-sectional dependence.

{pstd}
{bf:Why does this matter?}  In macro/finance panels the residuals of different
units are contemporaneously correlated because common factors (business cycles,
monetary policy, oil prices) affect everybody at the same time.  Classical FEQR
theory ignores this correlation, leading to {bf:downward-biased standard errors}
and over-rejection of the null.  {cmd:xtpqcs} eliminates this problem.

{pstd}
Under the common-shock framework the asymptotic distribution is

{p 8 16 2}
sqrt(T) * (beta_hat - beta_0) {c -}{c -}> N(0, V),{p_end}
{p 8 16 2}
V = Gamma{sup:-1} Sigma Gamma{sup:-1}   (Theorem 1){p_end}

{pstd}
and {cmd:xtpqcs} reports SE = sqrt(diag(V_hat)/T).

{pstd}
{cmd:xtpqcs} also computes the classical Kato et al. (2012) sandwich
covariance and stores it in {cmd:e(V_classical)}.  By default the robust
estimator is used; specify {cmd:compare} to report the classical one instead.
Both are always stored regardless.

{pstd}
By {bf:Theorem 2} of Chiang, Galvao and Wei (2026), the robust estimator is
consistent {bf:both} in the presence {bf:and} in the absence of common shocks.
The practitioner does not need to know {it:ex ante} whether shocks are present.


{marker options}{...}
{title:Options}

{dlgtab:Required}

{phang}
{cmdab:i:d(}{varname}{cmd:)} specifies the variable that identifies
cross-sectional units.  Must be numeric.  This is required.

{phang}
{cmdab:t:ime(}{varname}{cmd:)} specifies the variable that identifies
time periods.  Must be numeric.  This is required.

{dlgtab:Estimation}

{phang}
{cmdab:q:uantile(}{it:#}{cmd:)} specifies the quantile index tau.
Must lie {bf:strictly between 0 and 1}.  Default is {cmd:0.5}
(conditional median regression).

{phang}
{cmdab:b:andwidth(}{it:#}{cmd:)} specifies the kernel bandwidth h
used to estimate the conditional density f{subscript:i}(0|X).  Default is
Silverman's rule:

{p 12 16 2}
h = max(0.05, 1.06 * sd(eps_hat) * N{sup:-1/5})

{pmore}
where N is the cross-sectional dimension. The floor of 0.05 follows the
simulation design in Section 5 of Chiang, Galvao and Wei (2026).  The user
may override this with any positive value.

{phang}
{cmdab:k:ernel(}{it:string}{cmd:)} selects the kernel function.
Allowed values:

{phang3}
{cmd:gaussian} (default) {hline 2} standard normal density phi(u/h)/h{p_end}
{phang3}
{cmd:epanechnikov} {hline 2} 0.75*(1-u{sup:2})*I(|u|<=1) / h{p_end}
{phang3}
{cmd:uniform} {hline 2} 0.5*I(|u|<=1) / h{p_end}

{phang}
{cmdab:comp:are} replaces the displayed covariance with the classical Kato
et al. (2012) sandwich estimator.  This option is useful for demonstrating
the size distortion caused by ignoring common shocks.  Both matrices are
always stored in {cmd:e()}, regardless of this option.

{dlgtab:Reporting}

{phang}
{cmd:level(}{it:#}{cmd:)} sets the confidence level for the reported table;
default is 95.

{phang}
{cmdab:nohe:ader} suppresses the summary header above the coefficient table.
Useful when estimating across many quantiles in a loop.


{marker requirements}{...}
{title:Requirements}

{phang}
{bf:Stata version:} 14.0 or later.

{phang}
{bf:Panel structure:} The data must be a panel with at least
{bf:N >= 2} cross-sectional units and {bf:T >= 5} time periods.  The panel
need not be balanced; unbalanced panels are handled automatically.

{phang}
{bf:Variable types:} All variables ({depvar}, {indepvars}, id, time) must
be numeric.  String identifiers should be encoded first with
{cmd:encode} or {cmd:egen group()}.

{phang}
{bf:No constant:} Do not include a constant in {indepvars}; the individual
fixed effects alpha{subscript:i}(tau) absorb it.

{phang}
{bf:Dependencies:} {cmd:qreg} and {cmd:egen} must be available (they ship
with Stata).  No external packages are required.


{marker technical}{...}
{title:Technical notes}

{phang}
{bf:Estimation algorithm.}  {cmd:xtpqcs} uses the iterative concentration
algorithm of Koenker (2004), which avoids creating N dummy variables:

{p 8 12 2}
1. Initialise beta from pooled {cmd:qreg}.{p_end}
{p 8 12 2}
2. Compute alpha{subscript:i}(beta) = tau-quantile of {Y - X'beta}
   within each unit i (in Mata).{p_end}
{p 8 12 2}
3. Update beta from {cmd:qreg} of (Y - alpha_i) on X (only p parameters,
   always fast).{p_end}
{p 8 12 2}
4. Repeat steps 2-3 until max|beta_new - beta_old| < 1e-6,
   or at most 50 iterations.{p_end}

{pmore}
This converges to the exact Koenker (2004) solution and scales well to
{bf:very large panels} (N*T > 1,000,000) because the qreg step never
includes dummy variables.

{phang}
{bf:Covariance estimation.}  Four matrices are estimated in Mata (see paper):

{p 8 12 2}
{bf:Gamma_hat} = (1/n) sum K_h(eps_it) * X_it * (X_it - gamma_i)'{p_end}
{p 8 12 2}
{bf:Sigma_hat} = (1/T) sum_t (m_t - mbar)(m_t - mbar)'{p_end}
{p 8 12 2}
{bf:V_robust}  = Gamma{sup:-1} Sigma Gamma{sup:-1} / T{p_end}
{p 8 12 2}
{bf:V_classical} = tau(1-tau) * Gamma{sup:-1} Omega Gamma{sup:-1} / (NT){p_end}

{pmore}
where gamma{subscript:i} is the unit-level weighted-average regressor,
m{subscript:t} is the cross-sectional mean of psi{subscript:it} at time t,
and Omega is the classical quadratic-form matrix.

{phang}
{bf:Asymptotic regime.}  The theory requires (log N){sup:2}/T {c ->} 0.
Practically, T >= 10 is recommended.  The estimator also works in
the "large T" classical regime.

{phang}
{bf:Replay.}  After estimation, typing {cmd:xtpqcs} without arguments replays
the last results, optionally with a new {cmd:level()}.


{marker warnings}{...}
{title:Warnings and cautions}

{phang}
{err:{bf:WARNING: No constant in the model.}}  Do not include {bf:_cons} or a
variable equal to 1 in {indepvars}.  The unit fixed effects
alpha{subscript:i}(tau) already absorb the intercept.  Including a constant
will cause collinearity and numerical failure.

{phang}
{err:{bf:WARNING: Extreme quantiles.}}  At tau near 0 or 1
(e.g. 0.01 or 0.99), the kernel density estimates may be imprecise because
very few residuals fall near zero.  Consider using tau in [0.05, 0.95] unless
T is very large (>= 100).

{phang}
{err:{bf:WARNING: Small T.}}  When T < 10 the asymptotic approximation for
the robust covariance Sigma_hat (which averages T cross-sectional means) may
be poor.  The command requires T >= 5 and will refuse to run if T < 5.

{phang}
{err:{bf:CAUTION: Bandwidth sensitivity.}}  The kernel density estimates
Gamma_hat and f{subscript:i}(0|X) depend on the bandwidth h.  The Silverman
default is a sensible choice but practitioners should check robustness by
running the estimation with 2-3 different {cmd:bandwidth()} values.

{phang}
{err:{bf:CAUTION: Dependent variable scale.}}  The bandwidth is chosen
relative to the residual standard deviation.  Rescaling Y by a large
constant will change the automatic bandwidth.  This does not affect
coefficients but can affect SEs.

{phang}
{err:{bf:CAUTION: Interpreting compare.}}  When common shocks are present,
the classical SEs ({cmd:compare}) are typically {bf:too small}, leading to
over-rejection of the null.  The user should prefer the default robust SEs
unless they have strong reasons to believe that cross-sectional independence
holds exactly.

{phang}
{err:{bf:CAUTION: Unbalanced panels.}}  Unbalanced panels are supported but
the theory technically assumes a balanced panel.  Moderate imbalance is fine;
severely unbalanced panels (e.g. some units observed for only 2 periods)
may yield imprecise unit-level quantile estimates.


{marker examples}{...}
{title:Examples}

{pstd}
{bf:Setup: Generate panel data from the paper's DGP}{p_end}

{phang}{cmd:. clear}{p_end}
{phang}{cmd:. set seed 2026}{p_end}
{phang}{cmd:. set obs 200}{p_end}
{phang}{cmd:. gen id = _n}{p_end}
{phang}{cmd:. gen alpha = runiform()}{p_end}
{phang}{cmd:. expand 30}{p_end}
{phang}{cmd:. bys id: gen t = _n}{p_end}
{phang}{cmd:. gen X = rchi2(3) + 0.3*alpha}{p_end}
{phang}{cmd:. sort t}{p_end}
{phang}{cmd:. by t: gen eta = rnormal() if _n==1}{p_end}
{phang}{cmd:. by t: replace eta = eta[1]}{p_end}
{phang}{cmd:. gen eps = rnormal()}{p_end}
{phang}{cmd:. gen U = (eps + eta)/sqrt(2)}{p_end}
{phang}{cmd:. gen y = alpha + 1*X + (1 + 0.2*X)*U}{p_end}
{phang}{cmd:. xtset id t}{p_end}

{pstd}
{bf:Example 1: Median regression with robust SEs (default)}{p_end}

{phang}{cmd:. xtpqcs y X, id(id) time(t)}{p_end}

{pstd}
{bf:Example 2: Lower tail (tau=0.10)}{p_end}

{phang}{cmd:. xtpqcs y X, id(id) time(t) quantile(0.10)}{p_end}

{pstd}
{bf:Example 3: Compare robust vs. classical SEs}{p_end}

{phang}{cmd:. xtpqcs y X, id(id) time(t) quantile(0.50)}{p_end}
{phang}{cmd:. xtpqcs y X, id(id) time(t) quantile(0.50) compare}{p_end}

{pmore}
Note: the classical SEs are noticeably smaller, illustrating the size
distortion documented in Petersen (2008) and analysed in Theorem 1.

{pstd}
{bf:Example 4: Multiple regressors}{p_end}

{phang}{cmd:. gen X2 = rnormal()}{p_end}
{phang}{cmd:. replace y = y + 0.5*X2}{p_end}
{phang}{cmd:. xtpqcs y X X2, id(id) time(t) quantile(0.50)}{p_end}

{pstd}
{bf:Example 5: Estimate across several quantiles}{p_end}

{phang}{cmd:. foreach q in 0.10 0.25 0.50 0.75 0.90 {c -(}}{p_end}
{phang}{cmd:.     xtpqcs y X, id(id) time(t) quantile(`q') noheader}{p_end}
{phang}{cmd:. {c )-}}{p_end}

{pstd}
{bf:Example 6: Epanechnikov kernel with custom bandwidth}{p_end}

{phang}{cmd:. xtpqcs y X, id(id) time(t) quantile(0.50) kernel(epanechnikov) bandwidth(0.3)}{p_end}

{pstd}
{bf:Example 7: Inspect stored matrices}{p_end}

{phang}{cmd:. xtpqcs y X, id(id) time(t) quantile(0.50)}{p_end}
{phang}{cmd:. matrix list e(V_robust)}{p_end}
{phang}{cmd:. matrix list e(V_classical)}{p_end}
{phang}{cmd:. matrix list e(Gamma_hat)}{p_end}
{phang}{cmd:. matrix list e(Sigma_hat)}{p_end}

{pstd}
{bf:Example 8: Quantile process plot}{p_end}

{phang}{cmd:. xtpqcsplot y X, id(id) time(t) quantiles(0.05(0.05)0.95)}{p_end}

{pstd}
{bf:Example 9: Monte Carlo replication of paper Section 5}{p_end}

{phang}{cmd:. xtpqcsmc, n(500) tperiods(30) reps(200) quantile(0.50)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:xtpqcs} stores the following in {cmd:e()}:

{synoptset 24 tabbed}{...}
{p2col 5 24 28 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}total number of observations used{p_end}
{synopt:{cmd:e(N_g)}}number of cross-sectional units (groups){p_end}
{synopt:{cmd:e(T)}}number of time periods{p_end}
{synopt:{cmd:e(quantile)}}quantile index tau{p_end}
{synopt:{cmd:e(bandwidth)}}kernel bandwidth h actually used{p_end}
{synopt:{cmd:e(df_r)}}residual degrees of freedom (T - p){p_end}

{p2col 5 24 28 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:xtpqcs}{p_end}
{synopt:{cmd:e(cmdline)}}full command as typed{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(ivar)}}panel id variable{p_end}
{synopt:{cmd:e(tvar)}}time variable{p_end}
{synopt:{cmd:e(kernel)}}kernel function used{p_end}
{synopt:{cmd:e(vce)}}{cmd:robust_cgw}{p_end}
{synopt:{cmd:e(vcetype)}}description of the SE method displayed{p_end}

{p2col 5 24 28 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}1 x p coefficient vector beta_hat(tau){p_end}
{synopt:{cmd:e(V)}}p x p displayed variance-covariance (robust or classical){p_end}
{synopt:{cmd:e(V_robust)}}p x p robust CGW covariance: Gamma{sup:-1} Sigma Gamma{sup:-1} / T{p_end}
{synopt:{cmd:e(V_classical)}}p x p classical Kato et al. (2012) sandwich{p_end}
{synopt:{cmd:e(Gamma_hat)}}p x p Jacobian estimate Gamma_hat{p_end}
{synopt:{cmd:e(Sigma_hat)}}p x p common-shock long-run variance Sigma_hat{p_end}
{synopt:{cmd:e(Omega_hat)}}p x p classical Omega_hat{p_end}

{p2col 5 24 28 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}


{marker references}{...}
{title:References}

{phang}
Chiang, H. D., A. F. Galvao, and C.-M. Wei. 2026.
{browse "https://arxiv.org/abs/2602.19201":Panel Quantile Regression with Common Shocks}.
{it:arXiv:2602.19201}.

{phang}
Kato, K., A. F. Galvao, and G. V. Montes-Rojas. 2012. Asymptotics for panel
quantile regression models with individual effects.
{it:Journal of Econometrics} 170: 76{c -}91.

{phang}
Koenker, R. 2004. Quantile regression for longitudinal data.
{it:Journal of Multivariate Analysis} 91: 74{c -}89.

{phang}
Galvao, A. F., J. Gu, and S. Volgushev. 2020. On the unbiased asymptotic
normality of quantile regression with fixed effects.
{it:Journal of Econometrics} 218: 178{c -}215.

{phang}
Petersen, M. A. 2009. Estimating standard errors in finance panel data sets:
Comparing approaches.
{it:Review of Financial Studies} 22: 435{c -}480.


{marker also_see}{...}
{title:Also see}

{psee}
{space 2}Help:  {helpb xtpqcsplot}, {helpb xtpqcsmc}, {helpb qreg},
{helpb xtset}


{marker author}{...}
{title:Author}

{pstd}
{bf:Dr. Merwan Roudane}{break}
Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
Stata implementation of Chiang, Galvao and Wei (2026).
