{smcl}
{* *! version 2.0.0  18feb2026}{...}
{vieweralsosee "rbfmvar_graph" "help rbfmvar_graph"}{...}
{vieweralsosee "rbfmvar_simulate" "help rbfmvar_simulate"}{...}
{viewerjumpto "Syntax" "rbfmvar##syntax"}{...}
{viewerjumpto "Description" "rbfmvar##description"}{...}
{viewerjumpto "Options" "rbfmvar##options"}{...}
{viewerjumpto "Methodology" "rbfmvar##methodology"}{...}
{viewerjumpto "Examples" "rbfmvar##examples"}{...}
{viewerjumpto "Stored results" "rbfmvar##results"}{...}
{viewerjumpto "References" "rbfmvar##references"}{...}
{viewerjumpto "Author" "rbfmvar##author"}{...}
{title:Title}

{p2colset 5 20 22 2}{...}
{p2col:{bf:rbfmvar} {hline 2}}Residual-Based Fully Modified VAR (RBFM-VAR) estimation for
nonstationary VARs with unknown mixtures of I(0), I(1), and I(2) components{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:rbfmvar}
{varlist}
{ifin}
[{cmd:,} {it:options}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt l:ags(#)}}VAR order p; default is {cmd:lags(2)}{p_end}
{synopt:{opt maxl:ags(#)}}maximum lags for IC selection; default is {cmd:maxlags(8)}{p_end}
{synopt:{opt ic(string)}}information criterion: {bf:aic}, {bf:bic}, {bf:hq}, or {bf:none}; default is {cmd:ic(none)}{p_end}

{syntab:LRV Estimation}
{synopt:{opt ker:nel(string)}}kernel function: {bf:bartlett}, {bf:parzen}, or {bf:qs}; default is {cmd:kernel(bartlett)}{p_end}
{synopt:{opt band:width(#)}}bandwidth for kernel; default is automatic (Andrews 1991){p_end}

{syntab:Testing}
{synopt:{opt gr:anger(string)}}Granger non-causality test: {cmd:granger("y1 -> y2")}{p_end}

{syntab:Post-estimation}
{synopt:{opt irf(#)}}impulse response horizon; default is {cmd:irf(0)} (skip){p_end}
{synopt:{opt bootreps(#)}}bootstrap replications for IRF CI; default is {cmd:bootreps(500)}{p_end}
{synopt:{opt bootci(#)}}confidence level for IRF CI (50-99); default is {cmd:bootci(90)}{p_end}
{synopt:{opt fevd}}compute forecast error variance decomposition{p_end}
{synopt:{opt for:ecast(#)}}multi-step ahead forecast; default is {cmd:forecast(0)} (skip){p_end}

{syntab:Reporting}
{synopt:{opt nopr:int}}suppress output table{p_end}
{synopt:{opt l:evel(#)}}confidence level; default is {cmd:level(95)}{p_end}
{synoptline}

{p 4 6 2}
{cmd:rbfmvar_graph} [{cmd:,} {cmd:irf} {cmd:eig} {cmd:density} {cmd:fevd} {cmd:forecast}
  {cmd:combine} {cmd:saving(}{it:string}{cmd:)} {cmd:nodisplay}]

{p 4 6 2}
{cmd:rbfmvar_simulate} [{cmd:,} {cmd:case(}{it:string}{cmd:)} {cmd:nobs(}{it:#}{cmd:)} {cmd:reps(}{it:#}{cmd:)} {cmd:kernel(}{it:string}{cmd:)} {cmd:saving(}{it:string}{cmd:)} {cmd:seed(}{it:#}{cmd:)} {cmd:noprint}]


{marker description}{...}
{title:Description}

{pstd}
{cmd:rbfmvar} implements the Residual-Based Fully Modified VAR (RBFM-VAR) estimator
proposed by Chang (2000). The method provides valid estimation and inference for
nonstationary Vector Autoregressions (VARs) containing any unknown mixture of
I(0) (stationary), I(1) (unit root), and I(2) (double unit root) variables, which
may be cointegrated in any form.

{pstd}
The key advantages over standard OLS-VAR estimation are:

{phang2}1. {bf:No prior knowledge required}: The estimator does not require pretesting
for unit roots or specifying the cointegration rank.{p_end}

{phang2}2. {bf:Mixed-normal asymptotics}: The RBFM-VAR estimator has a mixed normal
limiting distribution, avoiding the nuisance-parameter-dependent distributions
that plague OLS-VAR inference in nonstationary settings.{p_end}

{phang2}3. {bf:Valid Granger causality testing}: The modified Wald test {it:W_F+} is
asymptotically bounded by chi-square, enabling conservative but valid causality
tests regardless of integration orders.{p_end}

{phang2}4. {bf:Bootstrap IRF confidence intervals}: Residual-based bootstrap provides
percentile confidence intervals for impulse response functions.{p_end}

{phang2}5. {bf:FEVD and Forecasting}: Forecast error variance decomposition and
multi-step ahead forecasts with error bands.{p_end}

{pstd}
{cmd:rbfmvar_graph} produces post-estimation graphs including impulse response
functions (with bootstrap CI bands), eigenvalue stability diagrams, residual
density plots, FEVD stacked area charts, and forecast fan charts.

{pstd}
{cmd:rbfmvar_simulate} reproduces the Monte Carlo simulation from Section 5 of
Chang (2000) for the three DGP cases (A, B, C).


{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}
{opt lags(#)} specifies the VAR order {it:p}. Default is 2.

{phang}
{opt maxlags(#)} specifies the maximum lag order to consider when using
information criterion lag selection. Default is 8.

{phang}
{opt ic(string)} selects the lag order using an information criterion.
Options are {bf:aic} (Akaike), {bf:bic} (Bayesian), {bf:hq} (Hannan-Quinn),
or {bf:none} (use {opt lags()} directly). Default is {bf:none}.
When specified, the output includes a comparison table of all ICs across lag orders.

{dlgtab:LRV Estimation}

{phang}
{opt kernel(string)} specifies the kernel function for long-run variance
estimation. Options are {bf:bartlett} (Bartlett/Newey-West), {bf:parzen},
or {bf:qs} (Quadratic Spectral). Default is {bf:bartlett}.

{phang}
{opt bandwidth(#)} specifies the bandwidth parameter {it:K} for kernel
estimation. If not specified (or set to -1), the bandwidth is selected
automatically using the Andrews (1991) data-driven rule.

{dlgtab:Testing}

{phang}
{opt granger(string)} performs a Granger non-causality test using the
modified Wald statistic {it:W_F+} from Theorem 2 of Chang (2000). The
argument is specified as {cmd:granger("varname1 -> varname2")} to test
H0: varname1 does NOT Granger-cause varname2.

{dlgtab:Post-estimation}

{phang}
{opt irf(#)} computes impulse response functions up to the specified
horizon. Set to 0 (default) to skip IRF computation. Required for FEVD.

{phang}
{opt bootreps(#)} specifies the number of bootstrap replications for IRF
confidence intervals. Default is 500. Set to 0 to skip bootstrap CI.

{phang}
{opt bootci(#)} specifies the confidence level for bootstrap IRF bands
(between 50 and 99). Default is 90.

{phang}
{opt fevd} requests computation of the Forecast Error Variance Decomposition
(FEVD) using Cholesky-orthogonalized IRFs.

{phang}
{opt forecast(#)} computes multi-step ahead forecasts from the estimated
VAR companion form with forecast error standard errors.


{marker methodology}{...}
{title:Methodology}

{pstd}
{bf:ECM Reparameterization.} The levels VAR (Eq. 1 in Chang 2000):

{p 8 8 2}
y_t = A_1 y_{t-1} + ... + A_p y_{t-p} + epsilon_t

{pstd}
is reparameterized into (Eq. 3):

{p 8 8 2}
y_t = Gamma * z_t + A * w_t + epsilon_t

{pstd}
where z_t contains stationary second-difference lags and
w_t = (Delta y_{t-1}', y_{t-1}')' contains nonstationary regressors.

{pstd}
{bf:RBFM-VAR Estimator.} The correction (Eqs. 12-13) removes endogeneity
via Y+ = Y' - Omega_ev * Omega_vv^{-1} * V' and serial correlation via
A+ = (0,I) * Delta_vdw, where v_hat_t is constructed from a restricted
first-order autoregression (Eq. 11).

{pstd}
{bf:Modified Wald Test.} For linear restrictions H0: R vec(F) = r, the
modified Wald statistic W_F+ has a limit distribution bounded above by
chi-square with q degrees of freedom (Theorem 2). Standard critical values
yield conservative but valid tests.

{pstd}
{bf:Bootstrap IRF CI.} Residual-based bootstrap: (i) center and resample
OLS residuals with replacement, (ii) reconstruct bootstrap data, (iii) re-estimate
RBFM-VAR, (iv) compute IRFs, (v) repeat B times, (vi) construct percentile CI bands.

{pstd}
{bf:FEVD.} Using Cholesky-orthogonalized IRFs (Phi_h * P where P = chol(Sigma_e)),
the FEVD at horizon h for variable i due to shock j is the cumulative squared
orthogonalized response divided by total forecast error variance.


{marker examples}{...}
{title:Examples}

{pstd}{bf:Example 1: Basic estimation}

{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. set obs 200}{p_end}
{phang2}{cmd:. set seed 12345}{p_end}
{phang2}{cmd:. gen t = _n}{p_end}
{phang2}{cmd:. tsset t}{p_end}
{phang2}{cmd:. gen y1 = sum(rnormal())}{p_end}
{phang2}{cmd:. gen y2 = sum(rnormal())}{p_end}
{phang2}{cmd:. rbfmvar y1 y2, lags(1) kernel(bartlett)}{p_end}

{pstd}{bf:Example 2: Granger causality test}

{phang2}{cmd:. rbfmvar y1 y2, lags(1) granger("y2 -> y1")}{p_end}

{pstd}{bf:Example 3: IRF with bootstrap confidence intervals}

{phang2}{cmd:. rbfmvar y1 y2, lags(1) irf(20) bootreps(500) bootci(90)}{p_end}
{phang2}{cmd:. rbfmvar_graph, irf}{p_end}

{pstd}{bf:Example 4: FEVD with visualization}

{phang2}{cmd:. rbfmvar y1 y2, lags(1) irf(20) fevd}{p_end}
{phang2}{cmd:. rbfmvar_graph, fevd}{p_end}

{pstd}{bf:Example 5: Forecasting with fan chart}

{phang2}{cmd:. rbfmvar y1 y2, lags(1) forecast(10)}{p_end}
{phang2}{cmd:. rbfmvar_graph, forecast}{p_end}

{pstd}{bf:Example 6: Automatic lag selection with IC table}

{phang2}{cmd:. rbfmvar y1 y2, ic(aic) maxlags(6) irf(20)}{p_end}

{pstd}{bf:Example 7: Complete analysis}

{phang2}{cmd:. rbfmvar y1 y2, lags(1) irf(20) bootreps(200) bootci(95) fevd forecast(8)}{p_end}
{phang2}{cmd:. rbfmvar_graph, irf fevd forecast eig density}{p_end}

{pstd}{bf:Example 8: Monte Carlo simulation}

{phang2}{cmd:. rbfmvar_simulate, case(a) nobs(150) reps(1000)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:rbfmvar} stores the following in {cmd:e()}:

{synoptset 25 tabbed}{...}
{p2col 5 25 29 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(T_eff)}}effective sample size{p_end}
{synopt:{cmd:e(n_vars)}}number of variables{p_end}
{synopt:{cmd:e(p_lags)}}VAR order{p_end}
{synopt:{cmd:e(bandwidth)}}kernel bandwidth used{p_end}
{synopt:{cmd:e(wald_stat)}}modified Wald statistic (if Granger test){p_end}
{synopt:{cmd:e(wald_pval)}}conservative p-value (if Granger test){p_end}
{synopt:{cmd:e(wald_df)}}degrees of freedom (if Granger test){p_end}
{synopt:{cmd:e(irf_horizon)}}IRF horizon (if computed){p_end}
{synopt:{cmd:e(irf_ci_level)}}IRF CI level (if bootstrap){p_end}
{synopt:{cmd:e(irf_boot_reps)}}IRF bootstrap replications{p_end}
{synopt:{cmd:e(forecast_steps)}}forecast steps ahead{p_end}

{p2col 5 25 29 2: Matrices}{p_end}
{synopt:{cmd:e(F_ols)}}full OLS-VAR coefficient matrix{p_end}
{synopt:{cmd:e(F_plus)}}full RBFM-VAR corrected coefficient matrix{p_end}
{synopt:{cmd:e(SE_mat)}}standard error matrix{p_end}
{synopt:{cmd:e(Pi1_ols)}}OLS Pi_1 (coeff on Delta y_{t-1}){p_end}
{synopt:{cmd:e(Pi2_ols)}}OLS Pi_2 (coeff on y_{t-1}){p_end}
{synopt:{cmd:e(Pi1_plus)}}RBFM-VAR Pi_1+{p_end}
{synopt:{cmd:e(Pi2_plus)}}RBFM-VAR Pi_2+{p_end}
{synopt:{cmd:e(Sigma_e)}}error covariance matrix{p_end}
{synopt:{cmd:e(Omega_ev)}}LRV of (epsilon,v){p_end}
{synopt:{cmd:e(Omega_vv)}}LRV of v{p_end}
{synopt:{cmd:e(Delta_vdw)}}one-sided LRV{p_end}
{synopt:{cmd:e(irf)}}IRF matrix (if computed){p_end}
{synopt:{cmd:e(irf_lo)}}lower IRF CI bound (if bootstrap){p_end}
{synopt:{cmd:e(irf_hi)}}upper IRF CI bound (if bootstrap){p_end}
{synopt:{cmd:e(fevd)}}FEVD matrix (if computed){p_end}
{synopt:{cmd:e(forecast)}}forecast values (if computed){p_end}
{synopt:{cmd:e(forecast_se)}}forecast standard errors (if computed){p_end}
{synopt:{cmd:e(residuals)}}estimation residuals{p_end}

{p2col 5 25 29 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}rbfmvar{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(varlist)}}variable list{p_end}
{synopt:{cmd:e(kernel)}}kernel function used{p_end}
{synopt:{cmd:e(ic)}}information criterion{p_end}
{synopt:{cmd:e(granger)}}Granger test specification{p_end}


{marker references}{...}
{title:References}

{phang}
Chang, Y. (2000). Vector Autoregressions with Unknown Mixtures of I(0), I(1),
and I(2) Components. {it:Econometric Theory}, 16(6), 905-926.

{phang}
Chang, Y. and P.C.B. Phillips (1995). Time series regression with mixtures of
integrated processes. {it:Econometric Theory}, 11, 1033-1094.

{phang}
Phillips, P.C.B. (1995). Fully modified least squares and vector autoregression.
{it:Econometrica}, 63, 1023-1078.

{phang}
Phillips, P.C.B. (1991). Optimal inference in cointegrated systems.
{it:Econometrica}, 59, 283-306.

{phang}
Andrews, D.W.K. (1991). Heteroskedasticity and autocorrelation consistent
covariance matrix estimation. {it:Econometrica}, 59(3), 817-858.

{phang}
Toda, H. and P.C.B. Phillips (1993). Vector autoregressions and causality.
{it:Econometrica}, 61, 1367-1393.


{marker author}{...}
{title:Author}

{pstd}
{bf:Dr. Merwan Roudane}{break}
Independent Researcher{break}
Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}

{pstd}
Please cite Chang (2000) and this package when using RBFM-VAR in your research.
{p_end}
