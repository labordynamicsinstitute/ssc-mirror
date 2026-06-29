{smcl}
{* *! version 1.0.0 27Jun2026}{...}
{title:Title}

{phang}
{bf:betark} {hline 2} Beta regression with AR(k) errors for proportion/rate outcomes, by joint conditional maximum likelihood


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:betark}
{depvar}
[{indepvars}]
{ifin}
{cmd:,} {opt lag(#)} [{it:options}]


{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{p2coldent:* {opt lag(#)}}set the order of the AR(k) process for the mean equation{p_end}
{synopt:{opt sc:ale(varlist)}}covariates for the precision (scale) equation; default is constant only{p_end}
{synopt:{opt nocons:tant}}suppress constant term from the mean equation{p_end}

{syntab:Reporting}
{synopt:{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synopt:{opt coefl:egend}}display legend instead of statistics{p_end}
{synopt:{opt nol:og}}suppress the iteration log{p_end}

{syntab:Convergence}
{synopt:{opt tol:erance(#)}}convergence criterion; default is {cmd:tolerance(1e-6)}{p_end}
{synopt:{opt iter:ate(#)}}maximum iterations; default is {cmd:iterate(1500)}{p_end}
{synopt:{opt from(matrix)}}user-supplied starting values, in place of the default static {helpb betareg} fit{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}* {opt lag(#)} is required.{p_end}
{p 4 6 2}
You must {cmd:tsset} your data before using {cmd:betark}; see {helpb tsset}.{p_end}
{p 4 6 2}
{it:depvar} must be strictly greater than 0 and less than 1.{p_end}
{p 4 6 2}
{it:indepvars} is optional; if omitted, an intercept-only mean equation is fitted.{p_end}
{p 4 6 2}
Factor variables and time-series operators are allowed in {it:depvar}, {it:indepvars},
and {opt scale()}; see {help fvvarlist} and {help tsvarlist}.{p_end}
{p 4 6 2}
Typing {cmd:betark} without arguments replays the last estimation results.{p_end}
{p 4 6 2}



{marker postestimation}{...}
{title:Postestimation syntax}

{pstd}
The following {helpb predict} options are available after {cmd:betark}:

{p 8 17 2}
{cmdab:predict} {newvar} {ifin} [{cmd:,} {it:statistic}]

{synoptset 16 tabbed}{...}
{synopthdr:statistic}
{synoptline}
{synopt:{opt cmean}}conditional (AR-adjusted, one-step-ahead) mean of {it:depvar}; the default{p_end}
{synopt:{opt cvar:iance}}conditional (AR-adjusted) variance of {it:depvar}{p_end}
{synopt:{opt xb}}linear prediction in the mean equation, {bf:without} the AR adjustment{p_end}
{synopt:{opt xbsc:ale}}linear prediction in the scale equation{p_end}
{synoptline}
{p2colreset}{...}

{pstd}
{opt xb} and {opt xbscale} are available both in and out of sample. {opt cmean} and
{opt cvariance} require lagged values of {it:depvar} and are therefore computed only
where the full AR({it:k}) history is available within a contiguous time segment.



{marker description}{...}
{title:Description}

{pstd}
{cmd:betark} fits a beta regression model for a continuous proportion or rate outcome
strictly bounded on (0,1), with autoregressive errors of order {it:k} in the mean
equation's linear predictor. {cmd:betark} estimates the mean equation coefficients, the
precision (scale) equation coefficients, and the AR coefficients rho_1,...,rho_k
{it:jointly} in a single conditional likelihood. This is possible because the
recursive substitution of {help betark##references:Rocha and Cribari-Neto (2009)}
and {help betark##references:Ferreira, Figueroa-Zuniga, and de Castro (2015)} yields a
closed-form conditional beta density at each time period, given the AR(k) history.



{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}
{opt lag(#)} specifies the order of the AR(k) process in the mean equation and must
be a positive integer; {cmd:lag()} is required.

{phang}
{opt scale(varlist)} specifies covariates for the precision (scale) equation, on the
log scale. If omitted, the scale equation is constant-only (a single estimated
precision parameter phi, as in the default {helpb betareg} specification).

{phang}
{opt noconstant} suppresses the constant term from the mean equation. The scale
equation always includes a constant in the current version.

{dlgtab:Reporting}

{phang}
{opt level(#)} specifies the confidence level as a percentage. Default is
{cmd:level(95)}.

{phang}
{opt coeflegend}; see {helpb estimation options##coeflegend:[R] Estimation options}.

{phang}
{opt nolog} suppresses the iteration log.

{dlgtab:Convergence}

{phang}
{opt tolerance(#)} specifies the parameter- and value-change convergence criterion.
Default is {cmd:tolerance(1e-6)}.

{phang}
{opt iterate(#)} specifies the maximum number of iterations. Default is
{cmd:iterate(1500)}, matching {helpb betareg}'s default.

{phang}
{opt from(matrix)} supplies user starting values in place of the default, which is
a static {cmd:betareg} fit (rho = 0) on the same mean and scale specification.



{marker examples}{...}
{title:Examples}

{pstd}Set-up{p_end}
{phang2}{cmd:. use betark_example.dta}{p_end}
{phang2}{cmd:. tsset t}{p_end}

{pstd}Fit an AR(1) model{p_end}
{phang2}{cmd:. betark y t _x150 _x_t150, lag(1)}{p_end}

{pstd}Fit an AR(2) model{p_end}
{phang2}{cmd:. betark y t _x150 _x_t150, lag(2)}{p_end}

{pstd}Covariates in the scale (precision) equation{p_end}
{phang2}{cmd:. betark y t _x150 _x_t150, lag(2) scale(t)}{p_end}

{pstd}Suppress the iteration log{p_end}
{phang2}{cmd:. betark y t _x150 _x_t150, lag(2) nolog}{p_end}

{pstd}Postestimation -- AR-adjusted conditional mean and variance{p_end}
{phang2}{cmd:. betark y t _x150 _x_t150, lag(2)}{p_end}
{phang2}{cmd:. predict mu_hat, cmean}{p_end}
{phang2}{cmd:. predict var_hat, cvariance}{p_end}
{phang2}{cmd:. tsline y mu_hat, xline(150)}{p_end}

{pstd}Compare to the linear prediction without the AR adjustment{p_end}
{phang2}{cmd:. predict xb_hat, xb}{p_end}
{phang2}{cmd:. gen mu_noar = invlogit(xb_hat)}{p_end}
{phang2}{cmd:. tsline y mu_hat mu_noar, xline(150)}{p_end}



{marker stored_results}{...}
{title:Stored results}

{pstd}
{cmd:betark} stores the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations (excludes the first {it:k} observations of
each segment, used to initialize the AR recursion but not contributing to the
likelihood){p_end}
{synopt:{cmd:e(df_m)}}mean-equation model degrees of freedom (excludes scale and AR
parameters){p_end}
{synopt:{cmd:e(chi2)}}Wald chi-squared statistic for the mean equation's non-constant
coefficients{p_end}
{synopt:{cmd:e(p)}}p-value for Wald chi-squared{p_end}
{synopt:{cmd:e(ll)}}joint conditional log likelihood at the final estimates{p_end}
{synopt:{cmd:e(p_lag)}}order of the AR process fitted{p_end}
{synopt:{cmd:e(iterations)}}number of iterations to convergence{p_end}
{synopt:{cmd:e(converged)}}1 if the optimizer reported convergence, 0 otherwise{p_end}
{synopt:{cmd:e(ngaps)}}number of gaps in sample (includes panel changes); the AR
recursion is restarted at each{p_end}
{synopt:{cmd:e(tolerance)}}convergence tolerance used{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:betark}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(title)}}title in estimation output{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(timevar)}}name of time variable{p_end}
{synopt:{cmd:e(panelvar)}}name of panel variable (if panel data){p_end}
{synopt:{cmd:e(link)}}link function used for the mean equation{p_end}
{synopt:{cmd:e(linkt)}}title used to label the mean-equation link in the output header{p_end}
{synopt:{cmd:e(slink)}}link function used for the scale equation{p_end}
{synopt:{cmd:e(slinkt)}}title used to label the scale-equation link in the output header{p_end}
{synopt:{cmd:e(noconstant)}}{cmd:noconstant}, if specified{p_end}
{synopt:{cmd:e(predict)}}{cmd:betark_p}{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector, with three equation blocks: the mean equation
(named after {it:depvar}), {cmd:scale}, and {cmd:ar} (rho_1,...,rho_k){p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of the joint conditional MLE{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}



{marker references}{...}
{title:References}

{phang}
Ferrari, S., and F. Cribari-Neto. 2004. Beta regression for modelling rates and
proportions. {it:Journal of Applied Statistics} 31(7): 799-815.

{phang}
Ferreira, G., J. I. Figueroa-Zuniga, and M. de Castro. 2015. Partially linear beta
regression model with autoregressive errors. {it:TEST} 24(4): 752-775.

{phang}
Linden, A. 2026. Beta regression with autoregressive errors for interrupted time
series analysis of proportion and rate outcomes: A simulation study.
Preprint. {it:arXiv}.

{phang}
Rocha, A. V., and F. Cribari-Neto. 2009. Beta autoregressive moving average models.
{it:TEST} 18(3): 529-545.



{title:Author}

{pstd}
Ariel Linden{break}
Linden Consulting Group, LLC{break}
alinden@lindenconsulting.org{break}



{title:Citation of {cmd:betark}}


{p 4 8 2}{cmd:betark} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden, Ariel. 2026. Stata module for computing Beta regression with autoregressive-corrected errors for proportion outcomes, 
by joint conditional maximum likelihood. Statistical Software Components sXXXXXX, Boston College Department of Economics.
{p_end}




{title:Also see}

{psee}
Online: {helpb betareg}, {helpb poissark} (if installed),
{helpb praisk} (if installed), {helpb xtpraisk} (if installed) {p_end}
