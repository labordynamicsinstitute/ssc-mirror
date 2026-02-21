{smcl}
{* *! version 1.0.1  20feb2026}{...}
{vieweralsosee "xtpmg" "help xtpmg"}{...}
{vieweralsosee "qreg" "help qreg"}{...}
{viewerjumpto "Syntax" "xtpqardl##syntax"}{...}
{viewerjumpto "Description" "xtpqardl##description"}{...}
{viewerjumpto "Model" "xtpqardl##model"}{...}
{viewerjumpto "Options" "xtpqardl##options"}{...}
{viewerjumpto "Examples" "xtpqardl##examples"}{...}
{viewerjumpto "Stored results" "xtpqardl##results"}{...}
{viewerjumpto "References" "xtpqardl##references"}{...}
{viewerjumpto "Author" "xtpqardl##author"}{...}

{title:Title}

{p2colset 5 22 24 2}{...}
{p2col:{bf:xtpqardl} {hline 2}}Panel Quantile Autoregressive Distributed Lag (PQARDL) estimation{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:xtpqardl}
{depvar} {indepvars}
{ifin}
{cmd:,} {opt tau(numlist)} {opt lr(varlist)}
[{it:options}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt tau(numlist)}}quantiles for estimation, e.g., {cmd:tau(0.25 0.5 0.75)}{p_end}
{synopt:{opt lr(varlist)}}long-run level variables; first variable is the lagged dependent (ECT),
   remaining are long-run regressors{p_end}

{syntab:Model}
{synopt:{opt pmg}}Pooled Mean Group estimator (default){p_end}
{synopt:{opt mg}}Mean Group estimator{p_end}
{synopt:{opt dfe}}Dynamic Fixed Effects estimator{p_end}
{synopt:{opt p(#)}}autoregressive lag order for the dependent variable; default is {cmd:p(1)}{p_end}
{synopt:{opt q(numlist)}}distributed lag orders; single number for all or per-variable list{p_end}
{synopt:{opt lagsel(string)}}automatic lag selection: {cmd:aic}, {cmd:bic}, or {cmd:both}{p_end}
{synopt:{opt pmax(#)}}maximum AR lag for lag selection; default is {cmd:pmax(4)}{p_end}
{synopt:{opt qmax(#)}}maximum DL lag for lag selection; default is {cmd:qmax(4)}{p_end}

{syntab:Display}
{synopt:{opt halflife}}display per-panel half-life table{p_end}
{synopt:{opt srtable}}display per-panel ECT table{p_end}
{synopt:{opt full}}display all per-panel tables{p_end}
{synopt:{opt irf(#)}}number of impulse response periods to display{p_end}
{synopt:{opt notable}}suppress coefficient tables{p_end}
{synopt:{opt gr:aph}}generate premium visualizations{p_end}

{syntab:Other}
{synopt:{opt ec(name)}}name for ECT variable; default is {cmd:ECT}{p_end}
{synopt:{opt replace}}overwrite existing ECT variable{p_end}
{synopt:{opt nocons:tant}}suppress constant term{p_end}
{synopt:{opt level(#)}}confidence level; default is {cmd:level(95)}{p_end}
{synoptline}
{p2colreset}{...}

{p 4 6 2}
Data must be declared as panel data using {cmd:xtset} {it:panelvar} {it:timevar}
before calling {cmd:xtpqardl}.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:xtpqardl} implements the Panel Quantile Autoregressive Distributed Lag
(PQARDL) model. This approach extends the standard panel ARDL framework of
Pesaran, Shin, and Smith (1999) to a quantile regression setting, allowing
researchers to examine how the long-run cointegrating relationship and the
short-run adjustment dynamics vary across different points of the conditional
distribution.

{pstd}
Traditional panel ARDL methods estimate a single set of long-run coefficients
and a single speed of adjustment, implicitly assuming homogeneity across
quantiles. The PQARDL model relaxes this assumption by estimating
quantile-dependent parameters, capturing asymmetric and distributional
heterogeneity. This is particularly valuable in empirical applications where
extreme events (e.g., large positive or negative shocks) may have different
long-run and short-run effects than moderate ones.

{pstd}
The methodology draws on the quantile ARDL framework developed by Cho, Shin,
and Kim (2015) and its panel extensions applied by Bildirici (2022) and
Hashmi et al. (2022). The estimation proceeds by running quantile regressions
(Koenker and Bassett, 1978) at each specified quantile for each panel, then
aggregating panel-specific estimates using the Pooled Mean Group (PMG), Mean
Group (MG), or Dynamic Fixed Effects (DFE) approach.


{marker model}{...}
{title:Model}

{pstd}
Consider a panel of N cross-sectional units observed over T time periods.
The PQARDL(p, q_1, ..., q_k) model is specified as:

{p 8 8 2}
Q_{tau}(Delta y_{it} | X_{it}) = rho(tau) * y_{i,t-1} + beta(tau)' * X_{it}
+ sum_{j=1}^{p-1} phi_j(tau) * Delta y_{i,t-j}
+ sum_{m=0}^{q_k-1} theta_m(tau) * Delta x_{k,i,t-m} + alpha_i(tau)

{pstd}
where:

{p 8 12 2}
{bf:rho(tau)} is the quantile-dependent speed of adjustment toward long-run equilibrium.
A negative and significant rho(tau) confirms cointegration at quantile tau.

{p 8 12 2}
{bf:beta(tau)} is the vector of long-run cointegrating coefficients at quantile tau,
computed as -coef(x_j) / rho(tau) for each regressor j.

{p 8 12 2}
{bf:phi_j(tau)} are the short-run autoregressive dynamics at quantile tau.

{p 8 12 2}
{bf:theta_m(tau)} are the short-run distributed lag impact coefficients at quantile tau.

{p 8 12 2}
{bf:alpha_i(tau)} are quantile-dependent panel fixed effects.

{pstd}
{bf:PMG Estimation:}
Under PMG, long-run slope coefficients beta(tau) are constrained to be
homogeneous across panels, while short-run coefficients and the speed of
adjustment are allowed to vary. Mean Group estimates are reported as simple
cross-sectional averages of the panel-specific quantile regression estimates,
with standard errors computed using the Pesaran and Smith (1995) non-parametric
variance formula: V = (1/N(N-1)) * sum(b_i - b_bar)(b_i - b_bar)'.

{pstd}
{bf:Wald Tests:}
The command reports Wald tests for the null hypothesis that parameters are
constant across quantiles (H0: parameter(tau_i) = parameter(tau_j) for all
i != j). Rejection provides evidence of quantile heterogeneity, indicating
that the relationship varies across the conditional distribution.


{marker options}{...}
{title:Options}

{dlgtab:Required}

{phang}
{opt tau(numlist)} specifies the quantiles at which estimation is performed.
Values must be between 0 and 1 exclusive.
Example: {cmd:tau(0.1 0.25 0.5 0.75 0.9)} for five quantiles.

{phang}
{opt lr(varlist)} specifies the long-run level variables. The first variable
must be the lagged dependent variable (e.g., L.y or a pre-computed lag),
which identifies the error correction term. Remaining variables are the
long-run regressors whose cointegrating coefficients beta(tau) are
estimated.

{dlgtab:Model}

{phang}
{opt pmg} specifies the Pooled Mean Group estimator. This is the default.

{phang}
{opt mg} specifies the Mean Group estimator.

{phang}
{opt dfe} specifies the Dynamic Fixed Effects estimator.

{phang}
{opt p(#)} specifies the autoregressive lag order. The default is 1.
When p > 1, additional lagged differences of the dependent variable
(D.L1.depvar, D.L2.depvar, ...) are included in the short-run equation.

{phang}
{opt q(numlist)} specifies the distributed lag order(s) for the independent
variables. A single number applies to all variables. A list specifies
per-variable orders. Example: {cmd:q(2 3)} for PQARDL(p, 2, 3) with two
independent variables having 2 and 3 distributed lags respectively.

{phang}
{opt lagsel(string)} activates BIC-based automatic lag selection.
Searches over p = 1,...,pmax and q = 1,...,qmax. Displays a BIC grid
and selects the optimal PQARDL(p, q1, ..., qk) specification.

{dlgtab:Display}

{phang}
{opt halflife} displays a per-panel half-life table. Half-life is
defined as HL(tau) = ln(2)/|rho(tau)| and indicates the number of
periods needed to close 50% of a disequilibrium at quantile tau.

{phang}
{opt srtable} displays the per-panel speed of adjustment table,
showing rho_i(tau) for each panel i and quantile tau.

{phang}
{opt full} equivalent to specifying both {cmd:halflife} and {cmd:srtable}.

{phang}
{opt irf(#)} displays an impulse response function table showing the
response to a unit shock over # periods at each quantile.

{phang}
{opt graph} generates premium visualizations including:
quantile process plots with 95% CI bands,
ECT heatmap across panels and quantiles,
half-life bar chart,
long-run coefficient comparison,
impulse response fan chart, and
persistence profile.

{dlgtab:Other}

{phang}
{opt ec(name)} specifies the name for the error correction term.
Default is ECT.

{phang}
{opt noconstant} suppresses the constant term in the quantile regressions.


{marker examples}{...}
{title:Examples}

{pstd}Setup: generate simulated panel data{p_end}

{phang2}{cmd:. xtpqardl_makedata, n(10) t(50) seed(12345) clear}{p_end}

{pstd}Example 1: Basic PMG estimation at 3 quantiles{p_end}

{phang2}{cmd:. xtpqardl dy dx1 dx2, lr(ly x1 x2) tau(0.25 0.5 0.75) pmg}{p_end}

{pstd}Example 2: 5 quantiles with half-life table{p_end}

{phang2}{cmd:. xtpqardl dy dx1 dx2, lr(ly x1 x2) tau(0.1 0.25 0.5 0.75 0.9) pmg halflife}{p_end}

{pstd}Example 3: Heterogeneous lag orders PQARDL(2, 2, 3){p_end}

{phang2}{cmd:. xtpqardl dy dx1 dx2, lr(ly x1 x2) tau(0.25 0.5 0.75) p(2) q(2 3) pmg}{p_end}

{pstd}Example 4: Automatic BIC lag selection{p_end}

{phang2}{cmd:. xtpqardl dy dx1 dx2, lr(ly x1 x2) tau(0.25 0.5 0.75) lagsel(bic) pmg}{p_end}

{pstd}Example 5: Full analysis with graphs and IRF{p_end}

{phang2}{cmd:. xtpqardl dy dx1 dx2, lr(ly x1 x2) tau(0.1 0.25 0.5 0.75 0.9) pmg halflife irf(15) graph full}{p_end}

{pstd}Example 6: Post-estimation access{p_end}

{phang2}{cmd:. matrix list e(beta_mg)}{p_end}
{phang2}{cmd:. matrix list e(rho_mg)}{p_end}
{phang2}{cmd:. matrix list e(rho_all)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:xtpqardl} stores the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(n_g)}}number of panels{p_end}
{synopt:{cmd:e(valid_panels)}}number of panels successfully estimated{p_end}
{synopt:{cmd:e(p)}}AR lag order{p_end}
{synopt:{cmd:e(k)}}number of short-run independent variables{p_end}
{synopt:{cmd:e(k_lr)}}number of long-run regressors (excluding lagged y){p_end}
{synopt:{cmd:e(ntau)}}number of quantiles{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:xtpqardl}{p_end}
{synopt:{cmd:e(model)}}estimation model: {cmd:pmg}, {cmd:mg}, or {cmd:dfe}{p_end}
{synopt:{cmd:e(ardl_order)}}ARDL order string, e.g., PQARDL(1,2,3){p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(indepvars)}}names of short-run independent variables{p_end}
{synopt:{cmd:e(lrvars)}}names of long-run regressor variables{p_end}
{synopt:{cmd:e(lr_y)}}name of lagged dependent variable (ECT){p_end}
{synopt:{cmd:e(qlags)}}distributed lag orders per variable{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(beta_mg)}}mean group long-run coefficients beta(tau){p_end}
{synopt:{cmd:e(beta_V)}}variance-covariance matrix of beta_mg{p_end}
{synopt:{cmd:e(rho_mg)}}mean group ECT speed of adjustment rho(tau){p_end}
{synopt:{cmd:e(rho_V)}}variance-covariance matrix of rho_mg{p_end}
{synopt:{cmd:e(halflife_mg)}}mean group half-life by quantile{p_end}
{synopt:{cmd:e(phi_mg)}}mean group AR lag coefficients{p_end}
{synopt:{cmd:e(sr_mg)}}mean group short-run impact coefficients{p_end}
{synopt:{cmd:e(beta_all)}}panel-specific long-run beta (N x k*ntau){p_end}
{synopt:{cmd:e(rho_all)}}panel-specific ECT coefficient (N x ntau){p_end}
{synopt:{cmd:e(halflife_all)}}panel-specific half-life (N x ntau){p_end}


{marker references}{...}
{title:References}

{phang}
Cho, J.S., Kim, T., and Shin, Y. (2015).
{it:Quantile cointegration in the autoregressive distributed-lag modeling framework.}
Journal of Econometrics, 188(1), 281-300.
{p_end}

{phang}
Bildirici, M.E. (2022).
{it:Refugee population, governance, and sustainable environment: Evidence from panel quantile autoregressive distributed lag model.}
Environment, Development and Sustainability, 24, 12653-12678.
{p_end}

{phang}
Hashmi, S.M., Chang, B.H., Huang, L., and Uche, E. (2022).
{it:Revisiting the relationship between oil prices, exchange rate, and stock prices: An application of quantile ARDL model.}
Resources Policy, 75, 102543.
{p_end}

{phang}
Pesaran, M.H., Shin, Y., and Smith, R.P. (1999).
{it:Pooled mean group estimation of dynamic heterogeneous panels.}
Journal of the American Statistical Association, 94(446), 621-634.
{p_end}

{phang}
Pesaran, M.H. and Smith, R.P. (1995).
{it:Estimating long-run relationships from dynamic heterogeneous panels.}
Journal of Econometrics, 68(1), 79-113.
{p_end}

{phang}
Koenker, R. and Bassett, G. (1978).
{it:Regression quantiles.}
Econometrica, 46(1), 33-50.
{p_end}


{marker requirements}{...}
{title:Requirements}

{pstd}
Stata 15.1 or later.{p_end}

{pstd}
The {cmd:xtpmg} package (version 2.0.1 or later) is required for complementary
panel ARDL analysis. Install via:{p_end}

{phang2}{cmd:. ssc install xtpmg}{p_end}


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}
{p_end}

{pstd}
Please cite this package as:{break}
Roudane, M. (2026). XTPQARDL: Stata module for Panel Quantile ARDL estimation.
{p_end}
