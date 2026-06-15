{smcl}
{* *! version 1.0.0 05Jun2026}{...}
{title:Title}

{phang}
{bf:xtpraisk} {hline 2} Prais-Winsten regression with AR(k) errors and
panel-corrected standard errors


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:xtpraisk}
{depvar}
[{indepvars}]
{ifin}
{cmd:,} {opt lag(#)} [{it:options}]


{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{p2coldent:* {opt lag(#)}}set AR lag order{p_end}
{synopt:{opt nocons:tant}}suppress constant term{p_end}
{synopt:{opt np1}}weight panel autocorrelations by T_i instead of T_i-1{p_end}

{syntab:SE}
{synopt:{opt nmk}}normalize standard errors by N-k instead of N{p_end}

{syntab:Reporting}
{synopt:{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synopt:{opt coefl:egend}}display legend instead of statistics{p_end}
{synopt:{opt nol:og}}suppress the iteration log{p_end}

{syntab:Convergence}
{synopt:{opt tol:erance(#)}}convergence tolerance; default is
	{cmd:tolerance(1e-6)}{p_end}
{synopt:{opt iter:ate(#)}}maximum iterations; default is
	{cmd:iterate(250)}{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}* {opt lag()} is required.{p_end}
{p 4 6 2}
A panel variable and a time variable must be specified; use
{helpb xtset}; see {manhelp xtset XT}.{p_end}
{p 4 6 2}
{it:indepvars} may contain factor variables; see {help fvvarlist}.{p_end}
{p 4 6 2}
{it:depvar} and {it:indepvars} may contain time-series operators; see
{help tsvarlist}.{p_end}



{marker postestimation}{...}
{title:Postestimation syntax}

{pstd}
The following {helpb predict} options are available after {cmd:xtpraisk}:

{p 8 17 2}
{cmdab:predict} {newvar} {ifin} [{cmd:,} {it:statistic}]

{synoptset 16 tabbed}{...}
{synopthdr:statistic}
{synoptline}
{synopt:{opt xb}}linear prediction; the default{p_end}
{synopt:{opt res:iduals}}OLS residuals{p_end}
{synopt:{opt ue}}AR(k) innovation residuals{p_end}
{synopt:{opt stdp}}standard error of the linear prediction{p_end}
{synoptline}
{p2colreset}{...}

{pstd}
{opt xb} and {opt stdp} are available both in and out of sample.
{opt residuals} and {opt ue} are calculated only where the dependent variable
is non-missing. The {opt ue} option requires panel data declared with
{helpb xtset} and sets predictions to missing for the first {it:k}
observations of each panel.



{title:Description}

{pstd}
{cmd:xtpraisk} calculates Prais-Winsten regression with AR(k) errors and panel-corrected standard errors, thereby extending
Stata's {helpb xtpcse} command to higher-order autoregressive errors. As with {helpb xtpcse}, {cmd:xtpraisk} 
assumes that the disturbances are, by default, heteroskedastic and contemporaneously correlated across panels.

{pstd}
Typing {cmd:xtpraisk} without arguments replays the last estimation results.



{title:Options}

{dlgtab:Model}

{phang}
{opt lag(#)} specifies the order of the autoregressive process for the
errors; {cmd:lag()} is required and must be >= 1.

{phang}
{opt noconstant} suppresses the constant term from the model.

{phang}
{opt np1} specifies that panel-specific autocorrelations be weighted by T_i
rather than the default T_i - 1 when estimating the common rho. This option
has an effect only when panels are unbalanced; see {helpb xtpcse}.

{dlgtab:SE}

{phang}
{opt nmk} specifies that standard errors be normalized by N-k rather than
the default N. Different authors use one or the other normalization;
see {helpb xtpcse}.

{phang}
Note: {cmd:xtpraisk} always reports panel-corrected standard errors (PCSEs).
PCSEs jointly account for panel heteroscedasticity and contemporaneous
cross-panel correlation (Beck and Katz 1995), subsuming the corrections
provided by {cmd:vce(robust)} or {cmd:vce(cluster)}.

{dlgtab:Reporting}

{phang}
{opt level(#)} specifies the confidence level as a percentage for confidence
intervals. The default is {cmd:level(95)} or as set by {helpb set level}.

{phang}
{opt coeflegend}; see {helpb estimation options##coeflegend:[R] Estimation options}.

{phang}
{opt nolog} suppresses the iteration log that reports the value of rho (for
AR(1)) or the maximum modulus of the companion matrix eigenvalues (for
AR(k > 1)) at each iteration.

{dlgtab:Convergence}

{phang}
{opt tolerance(#)} specifies the convergence criterion. Iteration stops when
the maximum absolute change in any AR parameter across successive iterations
is less than {it:#}. The default is {cmd:tolerance(1e-6)}.

{phang}
{opt iterate(#)} specifies the maximum number of iterations allowed before
an error is returned. The default is {cmd:iterate(250)}.



{title:Examples}

    {hline}

{pstd}
{opt 1) AR(1) estimation matching xtpcse:}{p_end}

    Setup
{phang2}{cmd:. webuse grunfeld}{p_end}
{phang2}{cmd:. xtset company year, yearly}{p_end}

{pstd}Estimate with common AR(1) errors and PCSEs{p_end}
{phang2}{cmd:. xtpraisk invest mvalue kstock, lag(1)}{p_end}

{pstd}Compare with xtpcse{p_end}
{phang2}{cmd:. xtpcse invest mvalue kstock, correlation(ar1)}{p_end}

{pstd}Replay results with 99% confidence intervals{p_end}
{phang2}{cmd:. xtpraisk, level(99)}{p_end}

    {hline}

{pstd}
{opt 2) Higher-order AR errors:}{p_end}

    Setup
{phang2}{cmd:. webuse grunfeld}{p_end}
{phang2}{cmd:. xtset company year, yearly}{p_end}

{pstd}Estimate with AR(2) errors{p_end}
{phang2}{cmd:. xtpraisk invest mvalue kstock, lag(2)}{p_end}

{pstd}Estimate with AR(3) errors{p_end}
{phang2}{cmd:. xtpraisk invest mvalue kstock, lag(3)}{p_end}

    {hline}

{pstd}
{opt 3) Post-estimation diagnostics:}{p_end}

    Setup
{phang2}{cmd:. webuse grunfeld}{p_end}
{phang2}{cmd:. xtset company year, yearly}{p_end}
{phang2}{cmd:. xtpraisk invest mvalue kstock, lag(2)}{p_end}

{pstd}Obtain fitted values and residuals{p_end}
{phang2}{cmd:. predict yhat, xb}{p_end}
{phang2}{cmd:. predict uhat, residuals}{p_end}

{pstd}Obtain AR innovation residuals and inspect for a single panel{p_end}
{phang2}{cmd:. predict ue, ue}{p_end}
{phang2}{cmd:. ac ue if company == 1}{p_end}

{pstd}Note: {cmd:ac} and {helpb wntestq} do not support multiple panels.
Inspect the autocorrelation function for individual panels or rely on the
autocorrelation table displayed by {cmd:xtpraisk}.{p_end}

    {hline}

{pstd}
{opt 4) Unbalanced panels and the np1 option:}{p_end}

{phang2}{cmd:. xtpraisk invest mvalue kstock, lag(1) np1}{p_end}

{pstd}With balanced panels {cmd:np1} has no effect; with unbalanced panels
it weights panel-specific rho estimates by T_i rather than T_i - 1,
matching {cmd:xtpcse}'s {cmd:np1} option.{p_end}

    {hline}



{title:Stored results}

{pstd}
{cmd:xtpraisk} stores the following in {cmd:e()}:

{synoptset 28 tabbed}{...}
{p2col 5 22 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(rank)}}rank of variance-covariance matrix{p_end}
{synopt:{cmd:e(df_m)}}model degrees of freedom{p_end}
{synopt:{cmd:e(chi2)}}Wald chi2 statistic{p_end}
{synopt:{cmd:e(p)}}p-value for Wald test{p_end}
{synopt:{cmd:e(r2)}}R-squared (computed on GLS-transformed data){p_end}
{synopt:{cmd:e(r2_a)}}adjusted R-squared{p_end}
{synopt:{cmd:e(rmse)}}root mean squared error{p_end}
{synopt:{cmd:e(mss)}}model sum of squares (transformed){p_end}
{synopt:{cmd:e(rss)}}residual sum of squares (transformed){p_end}
{synopt:{cmd:e(ll)}}exact log likelihood{p_end}
{synopt:{cmd:e(level)}}confidence level{p_end}
{synopt:{cmd:e(iterations)}}number of iterations to convergence{p_end}
{synopt:{cmd:e(tolerance)}}convergence tolerance used{p_end}
{synopt:{cmd:e(ngaps)}}number of gaps (panel changes + time gaps){p_end}
{synopt:{cmd:e(N_g)}}number of panels{p_end}
{synopt:{cmd:e(g_min)}}smallest group size{p_end}
{synopt:{cmd:e(g_avg)}}average group size{p_end}
{synopt:{cmd:e(g_max)}}largest group size{p_end}
{synopt:{cmd:e(p_lag)}}AR lag order{p_end}
{synopt:{cmd:e(ac_ols1)}, {cmd:e(ac_ols2)}, ...}autocorrelation of OLS residuals at lag {it:k}{p_end}
{synopt:{cmd:e(ac_ue1)}, {cmd:e(ac_ue2)}, ...}autocorrelation of AR innovation residuals at lag {it:k}{p_end}

{synoptset 28 tabbed}{...}
{p2col 5 22 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:xtpraisk}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(title)}}title in estimation output{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(ivar)}}name of panel variable{p_end}
{synopt:{cmd:e(tvar)}}name of time variable{p_end}
{synopt:{cmd:e(panelvar)}}name of panel variable{p_end}
{synopt:{cmd:e(timevar)}}name of time variable{p_end}
{synopt:{cmd:e(balance)}}{cmd:balanced} or {cmd:unbalanced}{p_end}
{synopt:{cmd:e(vcetype)}}Panel-corrected{p_end}
{synopt:{cmd:e(noconstant)}}{cmd:noconstant}, if specified{p_end}
{synopt:{cmd:e(predict)}}program used to implement predict{p_end}

{synoptset 28 tabbed}{...}
{p2col 5 22 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of the estimator{p_end}
{synopt:{cmd:e(rho)}}AR parameter estimates (1 x {it:k}){p_end}
{synopt:{cmd:e(serho)}}standard errors of AR parameter estimates (1 x {it:k}){p_end}

{synoptset 28 tabbed}{...}
{p2col 5 22 24 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}

{pstd}
In addition, {cmd:r(table)} is stored in {cmd:r()} and contains the
coefficient matrix with standard errors, test statistics, p-values, and
confidence intervals. Results stored in {cmd:r()} are updated when the
command is replayed and will be replaced when any r-class command is run
after the estimation command.



{title:References}

{phang}
Beck, N. L., and J. N. Katz. 1995. What to do (and not to do) with
time-series cross-section data. {it:American Political Science Review}
89: 634-647.

{phang}
Galbraith, R. F., and J. I. Galbraith. 1974. On the inverses of some
patterned matrices arising in the theory of stationary time series.
{it:Journal of Applied Probability} 11(1): 63-71.

{phang}
Hamilton, J. D. 1994. {it:Time Series Analysis}. Princeton University Press.

{phang}
Linden, A. 2026. Adjustment for autocorrelation in multiple-group
(controlled) interrupted time series analysis and its effect on power:
A simulation study of the Newey-West and Prais-Winsten methods.
{browse "https://doi.org/10.21203/rs.3.rs-8865851/v1"}

{phang}
Linden, A. 2026. Multiple-group (controlled) interrupted time series
analysis with higher-order autoregressive errors: A simulation study
comparing Newey-West and Prais-Winsten methods.
{browse "https://arxiv.org/abs/2603.24814"}

{phang}
Linden, A. 2026. Extending Prais–Winsten regression to panel data
with higher-order autoregressive errors: A simulation study.
{browse "https://arxiv.org/html/2606.12596v1"}

{phang}
Vougas, D. V. 2021. Prais-Winsten algorithm for regression with second
or higher order autoregressive errors. {it:Econometrics} 9(3): 32.



{title:Citation of {cmd:xtpraisk}}

{p 4 8 2}
{cmd:xtpraisk} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden A. 2026. XTPRAISK: Stata module for computing Prais-Winsten regression with AR(k) errors and
panel-corrected standard errors. 
Statistical Software Components S459735, Boston College Department of Economics.
{p_end}



{title:Author}

{pstd}
Ariel Linden {break}
Linden Consulting Group, LLC {break}
alinden@lindenconsulting.org {break}



{title:Acknowledgements}

{pstd}
I am grateful to Dimitrios V. Vougas for graciously providing the MATLAB
code that served as the basis for the {cmd:praisk} command, on which
{cmd:xtpraisk} is built.



{title:Also see}

{psee}
Manual: {manlink TS prais}, {manlink XT xtpcse}

{psee}
Online: {helpb xtpcse}, {helpb prais}, {helpb regress}, {helpb newey}, {helpb ac},
{helpb praisk} (if installed) {p_end}
