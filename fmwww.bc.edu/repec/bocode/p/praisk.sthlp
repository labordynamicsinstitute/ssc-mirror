{smcl}
{* *! version 1.0.0 09Mar2026}{...}
{title:Title}

{phang}
{bf:praisk} {hline 2} Iterated Prais-Winsten regression with AR(k) errors


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:praisk}
{depvar}
[{indepvars}]
{ifin}
{cmd:,} {opt lag(#)} [{it:options}]



{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{p2coldent:* {opt lag(#)}}set maximum lag order of autocorrelation; {cmd:lag()} is required and must be >= 1{p_end}
{synopt:{opt nocons:tant}}suppress constant term{p_end}

{syntab:SE/Robust}
{synopt:{opt r:obust}}synonym for {cmd:vce(robust)}{p_end}
{synopt:{opt vce(vcetype)}}{it:vcetype} may be {opt ols},
	{opt robust}, or {opt cluster} {it:clustvar}{p_end}

{syntab:Reporting}
{synopt:{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synopt:{opt coefl:egend}}display legend instead of statistics{p_end}

{syntab:Convergence}
{synopt:{opt tol:erance(#)}}convergence tolerance; default is {cmd:tolerance(1e-6)}{p_end}
{synopt:{opt iter:ate(#)}}maximum iterations; default is {cmd:iterate(250)}{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}* {opt lag()} is required.{p_end}
{p 4 6 2}
You must {opt tsset} your data before using {opt praisk}; see {manhelp tsset TS}.{p_end}
{p 4 6 2}
{it:indepvars} is optional; if omitted an intercept-only model is fitted.{p_end}
{p 4 6 2}
{it:indepvars} may contain factor variables; see {help fvvarlist}.{p_end}
{p 4 6 2}
{it:depvar} and {it:indepvars} may contain time-series operators; see {help tsvarlist}.{p_end}



{marker postestimation}{...}
{title:Postestimation syntax}

{pstd}
The following {helpb predict} options are available after {cmd:praisk}:

{p 8 17 2}
{cmdab:predict} {newvar} {ifin} [{cmd:,} {it:statistic}]

{synoptset 16 tabbed}{...}
{synopthdr:statistic}
{synoptline}
{synopt:{opt xb}}linear prediction; the default{p_end}
{synopt:{opt res:iduals}}residuals{p_end}
{synopt:{opt ue}}AR(k) innovation residuals{p_end}
{synopt:{opt stdp}}standard error of the linear prediction{p_end}
{synoptline}
{p2colreset}{...}

{pstd}
{opt xb} and {opt stdp} are available both in and out of sample.
{opt residuals} and {opt ue} are calculated only where the dependent variable
is non-missing. The {opt ue} option requires an active {helpb tsset} time
variable and sets predictions to missing for the first {it:k} observations 
of each segment, which lack the {it:k} lagged residuals required to form the AR innovation.



{title:Description}

{pstd}
{cmd:praisk} fits a linear regression model with autoregressive errors AR(k) using the iterated 
Prais-Winsten (generalized least squares) estimator. For AR(k>1), {cmd:praisk} follows the methods
described in Vougas (2021). The transformation uses exact initialization of the first {it:k} observations 
following Galbraith and Galbraith (1974) and Hamilton (1994). AR(k) parameters are estimated by 
solving the pooled Yule-Walker cross-product system jointly across all panels and segments, matching 
the behavior of official {helpb prais}.

{pstd}
After estimation, {cmd:praisk} displays a table of residual autocorrelations at lags 1 through {it:k}.
The {it:untransformed} row shows autocorrelations of the OLS residuals (before AR filtering) and the
{it:transformed} row shows autocorrelations of the AR(k) innovation residuals (after filtering).
A successful transformation is indicated by transformed autocorrelations close to zero. For panel
data, autocorrelations are computed using Stata's lag operator, which restricts all pairs to
within-panel consecutive observations, matching the approach used by {helpb prais} for the
Durbin-Watson statistic.

{pstd}
Typing {cmd:praisk} without arguments replays the last estimation results.



{title:Options}

{dlgtab:Model}

{phang}
{opt lag(#)} specifies the order of the autoregressive process for the errors;
{cmd:lag()} is required and must be >= 1.

{phang}
{opt noconstant} suppresses the constant term from the model.

{dlgtab:SE/Robust}

{phang}
{opt robust} is a synonym for {cmd:vce(robust)}. Cannot be combined with
{cmd:vce()}.

{phang}
{opt vce(vcetype)} specifies how the variance-covariance matrix of the
estimator is computed.

{phang2}
{cmd:vce(ols)}, the default, uses the standard variance estimator for ordinary
least-squares regression.

{phang2}
{cmd:vce(robust)} specifies to use the Huber/White/sandwich estimator.

{phang2}
{cmd:vce(cluster} {it:clustvar}{cmd:)} specifies to use the intragroup
correlation estimator.


{dlgtab:Reporting}

{phang}
{opt level(#)} specifies the confidence level as a percentage for confidence
intervals. The default is {cmd:level(95)} or as set by {helpb set level}.

{phang}
{opt coeflegend}; see {helpb estimation options##coeflegend:[R] Estimation options}.



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
{opt 1) Estimating AR(k) models:}{p_end}
	
    Setup
{phang2}{cmd:. webuse idle}{p_end}
{phang2}{cmd:. tsset t}{p_end}

{pstd}Perform Prais-Winsten AR(1) regression{p_end}
{phang2}{cmd:. praisk usr idle syslcl sysrem, lag(1)}{p_end}

{pstd}Perform Prais-Winsten AR(2) and AR(3) estimation{p_end}
{phang2}{cmd:. praisk usr idle syslcl sysrem, lag(2)}{p_end}
{phang2}{cmd:. praisk usr idle syslcl sysrem, lag(3)}{p_end}

{pstd}Robust standard errors{p_end}
{phang2}{cmd:. praisk usr idle syslcl, lag(1) vce(robust)}{p_end}

{pstd}Replay last results with 99% confidence intervals{p_end}
{phang2}{cmd:. praisk, level(99)}{p_end}

    {hline}
	
{pstd}
{opt 2) Post-estimation:}{p_end}

    Setup
{phang2}{cmd:. webuse idle}{p_end}
{phang2}{cmd:. tsset t}{p_end}
{phang2}{cmd:. praisk usr idle syslcl sysrem, lag(2)}{p_end}

{pstd}Obtain fitted values, OLS residuals, and standard errors of prediction{p_end}
{phang2}{cmd:. predict yhat, xb}{p_end}
{phang2}{cmd:. predict uhat, residuals}{p_end}
{phang2}{cmd:. predict sehat, stdp}{p_end}

{pstd}Obtain AR innovation residuals{p_end}
{phang2}{cmd:. predict ue, ue}{p_end}

{pstd}Visual inspection: plot innovations against time. Under correct specification {cmd:ue} should look 
like white noise with no visible trend, cycles, or volatility clustering.{p_end}
{phang2}{cmd:. tsline ue}{p_end}

{pstd}Check autocorrelation function of innovations. All lags should lie within the confidence bands. Significant 
spikes suggest the AR order is too low. Compare with {cmd:ac uhat} to see how much autocorrelation the filter removed.{p_end}
{phang2}{cmd:. ac ue}{p_end}
{phang2}{cmd:. pac ue}{p_end}

{pstd}{cmd:praisk} automatically displays a table of autocorrelations at lags 1 through {it:k} for both
the untransformed (OLS) residuals and the AR innovation residuals. A successful transformation is
indicated by autocorrelations close to zero in the transformed row. For single time series data,
{helpb wntestq} can be used for a formal white noise test on the innovation residuals.{p_end}

    {hline}

{pstd}
{opt 3) AR order selection workflow:}{p_end}	

    Setup
{phang2}{cmd:. webuse idle}{p_end}
{phang2}{cmd:. tsset t}{p_end}

{pstd}Fit AR(1); the autocorrelation table shows whether lag-1 serial correlation has been removed{p_end}

{phang2}{cmd:. praisk usr idle syslcl, lag(1)}{p_end}
{phang2}{cmd:. estat ic}{p_end}

{pstd}Fit AR(2); check whether transformed autocorrelations at lags 1 and 2 are near zero{p_end}

{phang2}{cmd:. praisk usr idle syslcl, lag(2)}{p_end}
{phang2}{cmd:. estat ic}{p_end}

{pstd}
Stop increasing the AR order when the transformed autocorrelations are negligible and AIC/BIC
stops improving. For formal testing on single time series data, {helpb wntestq} can be applied
to the saved innovation residuals.

{hline}

{pstd}
{opt 4) Normality and heteroskedasticity diagnostics:}{p_end}

    Setup
{phang2}{cmd:. webuse idle}{p_end}
{phang2}{cmd:. tsset t}{p_end}
{phang2}{cmd:. praisk usr idle syslcl, lag(2)}{p_end}
{phang2}{cmd:. predict ue, ue}{p_end}

{pstd}Test normality of innovations{p_end}

{phang2}{cmd:. swilk ue}{p_end}
{phang2}{cmd:. sktest ue}{p_end}
{phang2}{cmd:. qnorm ue}{p_end}
{phang2}{cmd:. histogram ue, normal}{p_end}

{pstd}
Departures from normality affect the validity of reported {it:t} and {it:F} statistics.
Outliers in {cmd:ue} that are not prominent in {cmd:uhat} may indicate
observations where the AR filter is amplifying noise.

{pstd}Check for heteroskedasticity in the innovations{p_end}

{phang2}{cmd:. predict yhat, xb}{p_end}
{phang2}{cmd:. scatter ue yhat}{p_end}

{pstd}
If heteroskedasticity is found, re-estimate with {cmd:vce(robust)} or
{cmd:vce(cluster} {it:clustvar}{cmd:)}. Note: use the OLS residuals
{cmd:uhat} (not {cmd:ue}) to decide whether robust standard errors
are needed, since {cmd:vce(robust)} is applied to the GLS-transformed
data, not to the AR innovations.

{hline}

{title:Stored results}

{pstd}
{cmd:praisk} stores the following in {cmd:e()}:

{synoptset 22 tabbed}{...}
{p2col 5 22 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(rank)}}rank of variance-covariance matrix{p_end}
{synopt:{cmd:e(df_m)}}model degrees of freedom{p_end}
{synopt:{cmd:e(df_r)}}residual degrees of freedom{p_end}
{synopt:{cmd:e(F)}}F statistic (ANOVA F for OLS; Wald F for robust/cluster){p_end}
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
{synopt:{cmd:e(N_clust)}}number of clusters (if {cmd:vce(cluster)}){p_end}
{synopt:{cmd:e(ac_ols1)}, {cmd:e(ac_ols2)}, ...}autocorrelation of untransformed residuals at lag {it:k}{p_end}
{synopt:{cmd:e(ac_ue1)}, {cmd:e(ac_ue2)}, ...}autocorrelation of AR innovation residuals at lag {it:k}{p_end}

{synoptset 22 tabbed}{...}
{p2col 5 22 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:praisk}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(title)}}title in estimation output{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(timevar)}}name of time variable{p_end}
{synopt:{cmd:e(panelvar)}}name of panel variable (if panel data){p_end}
{synopt:{cmd:e(vce)}}{it:vcetype} specified in {cmd:vce()}{p_end}
{synopt:{cmd:e(vcetype)}}title used to label standard errors{p_end}
{synopt:{cmd:e(clustvar)}}name of cluster variable (if {cmd:vce(cluster)}){p_end}
{synopt:{cmd:e(noconstant)}}{cmd:noconstant}, if specified{p_end}

{synoptset 22 tabbed}{...}
{p2col 5 22 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of the estimator{p_end}
{synopt:{cmd:e(rho)}}AR parameter estimates (1 x {it:k}){p_end}
{synopt:{cmd:e(serho)}}standard errors of AR parameter estimates (1 x {it:k}){p_end}

{synoptset 22 tabbed}{...}
{p2col 5 22 24 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}



{pstd}
In addition to the above, the following is stored in {cmd:r()}:

{synoptset 22 tabbed}{...}
{p2col 5 22 24 2: Matrices}{p_end}
{synopt:{cmd:r(table)}}matrix containing the coefficients with their standard errors, test statistics, p-values, and confidence intervals{p_end}

{pstd}
Note that results stored in {cmd:r()} are updated when the command is replayed and will be replaced when any r-class command is run after the estimation command.


{title:References}

{phang}
Galbraith, R. F., and J. I. Galbraith. 1974. On the inverses of some patterned matrices arising
in the theory of stationary time series. {it:Journal of Applied Probability} 11(1): 63–71.

{phang}
Hamilton, J. D. 1994. {it:Time Series Analysis}. Princeton University Press.

{phang}
Linden, A. 2026. Adjustment for autocorrelation in multiple-group (controlled) interrupted time series 
analysis and its effect on power: A simulation study of the Newey-West and Prais-Winsten methods. 
{browse "https://doi.org/10.21203/rs.3.rs-8865851/v1"} 

{phang}
Linden, A. 2026. Multiple-group (controlled) interrupted time series analysis with higher-order autoregressive errors: 
A simulation comparison of Newey–West and Prais–Winsten methods.

{phang}
Vougas, D. V. 2021. Prais-Winsten algorithm for regression with second or
higher order autoregressive errors. {it:Econometrics} 9(3): 32.



{title:Author}

{pstd}
Ariel Linden{break}
Linden Consulting Group, LLC{break}
alinden@lindenconsulting.org{break}



{title:Acknowledgements}

{pstd}
I am grateful to Dimitrios V. Vougas for graciously providing the MATLAB code that served as the
basis for this implementation. Panel data support, factor variable handling, robust standard errors, 
and AR(k > 1) stationarity diagnostics are extensions not discussed in his paper or present in the MATLAB code.



{title:Citation of {cmd:praisk}}

{p 4 8 2}{cmd:praisk} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden, Ariel. 2026. PRAISK: Stata module for computing iterated Prais-Winsten regression with AR(k) errors.
{p_end}



{title:Also see}

{psee}
Manual: {manlink TS prais}

{psee}
Online: {helpb prais}, {helpb regress}, {helpb newey}, {helpb arima}
{p_end}
