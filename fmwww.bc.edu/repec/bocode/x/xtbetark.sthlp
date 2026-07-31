{smcl}
{* *! version 1.0.0 22Jul2026}{...}
{title:Title}

{phang}
{bf:xtbetark} {hline 2} Beta regression with AR(k) errors for
proportion/rate outcomes, by joint conditional maximum likelihood, with
panel-corrected standard errors


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:xtbetark}
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

{syntab:SE/VCE}
{synopt:{opt vce(vcetype)}}{cmd:pcse} (the default), {cmd:dk}, or {cmd:oim}{p_end}
{synopt:{opt nmk}}normalize standard errors by N-k instead of N{p_end}

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
Your data must be {cmd:xtset} with {bf:both} a panel and a time variable before
using {cmd:xtbetark}; see {helpb xtset}.{p_end}
{p 4 6 2}
{it:depvar} must be strictly greater than 0 and less than 1.{p_end}
{p 4 6 2}
{it:indepvars} is optional; if omitted, an intercept-only mean equation is fitted.{p_end}
{p 4 6 2}
Factor variables and time-series operators are allowed in {it:depvar}, {it:indepvars},
and {opt scale()}; see {help fvvarlist} and {help tsvarlist}.{p_end}
{p 4 6 2}
Typing {cmd:xtbetark} without arguments replays the last estimation results.{p_end}



{marker postestimation}{...}
{title:Postestimation syntax}

{pstd}
The following {helpb predict} options are available after {cmd:xtbetark}:

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
where the full AR({it:k}) history is available within a contiguous panel-time
segment; the AR(k) recursion is restarted at every panel change or time gap,
exactly as in estimation.



{marker description}{...}
{title:Description}

{pstd}
{cmd:xtbetark} extends {helpb betark:betark} (if installed) to panel data.
The AR(k) component -- the mean equation's autoregressive adjustment, jointly
estimated with the scale equation and AR coefficients via the same recursive
conditional likelihood -- works exactly as in {cmd:betark}. {cmd:xtbetark} adds
the variance-covariance estimator. A panel-appropriate sandwich is applied
{it:on top of} the AR(k)-adjusted likelihood, so the correction targets
only the cross-panel dependence the AR(k) term does not already handle. 
Two such corrections are available via {opt vce()} -- {cmd:pcse} (Beck and Katz [1995]) 
and {cmd:dk} ( Driscoll and Kraay [1998])-- differing in whether they include a time-lag smoothing kernel; 
a third, {cmd:oim}, applies no panel correction at all and provides results identical
to those produced by {helpb betark:betark}.



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
equation always includes a constant in the current version. The mean equation
uses a logit link and the scale equation a log link; no other links are
currently implemented, so these are not user-settable options.

{marker vce_notes}{...}
{dlgtab:SE/VCE}

{phang}
{opt vce(vcetype)} selects the variance-covariance estimator. All three
options share {it:identical} point estimates within a call; only the
reported standard errors differ.

{phang2}
{cmd:vce(pcse)}, the default, generalizes the panel-corrected standard
errors of {help xtbetark##references:Beck and Katz (1995)} -- the same
correction {helpb xtpraisk:xtpraisk} (if installed) applies -- from a
single-equation linear model to {cmd:xtbetark}'s three equations (mean,
scale, each AR lag). For every pair of equations, a cross-panel
covariance is estimated from that pair's equation-level likelihood
scores and combined with the corresponding design cross-products; the
blocks are assembled into the full sandwich. Like the original PCSE,
this has {bf:no time-lag kernel} -- only a contemporaneous cross-panel
term. That is a deliberate match to {cmd:xtbetark}: because the AR(k)
likelihood already removes serial dependence parametrically, there
should be little serial correlation left in the score for a time-lag
correction to usefully explain.

{phang2}
{cmd:vce(dk)} applies a Driscoll and Kraay (1998)-style sandwich to the
same equation-level scores, following {help xtbetark##references:Hoechle (2007)}'s
{cmd:xtscc} construction. Unlike {cmd:vce(pcse)}, this
includes a Bartlett-kernel time-lag correction, with the bandwidth fixed
internally to {opt lag(#)}, the same AR order fitted in the mean equation
-- {bf:not} the Newey-West (1994) automatic rule, floor(4*(T/100)^(2/9)),
that {helpb xtscc:xtscc} (if installed) uses by default for OLS residuals
with unmodeled serial dependence. Because {cmd:xtbetark}'s AR(k)
likelihood already removes serial dependence parametrically, any
residual correlation left in the score should plausibly extend no
further than the fitted AR order, not scale up with the number of time
periods the way it would for a model with no serial-dependence
correction at all. Provided mainly for
comparison; because {cmd:vce(dk)}'s kernel is designed to correct for
serial dependence that {cmd:xtbetark}'s AR(k) likelihood should have
already removed, it is more prone than {cmd:vce(pcse)} to the
finite-sample anticonservative bias documented for Newey-West-type HAC
estimators when little serial correlation remains to explain.

{phang2}
{cmd:vce(oim)} is {cmd:betark}'s original observed-information
covariance, with {bf:no} cross-panel correction at all. It
is numerically identical to running {cmd:betark} on the same
{cmd:xtset} data.

{phang}
{opt nmk} normalizes standard errors by N-k instead of N when applied to
{cmd:vce(pcse)}, where {it:k} is the total number of estimated
coefficients across all equations. This mirrors {cmd:xtpraisk}'s {cmd:nmk}
option, and like it, is {bf:off by default}. Ignored for {cmd:vce(dk)} and
{cmd:vce(oim)}.

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
{phang2}{cmd:. use xtbetark_example.dta}{p_end}
{phang2}{cmd:. xtset id t}{p_end}

{pstd}Fit an AR(1) model with the default panel-corrected (PCSE) SEs{p_end}
{phang2}{cmd:. xtbetark y_ar1 _x _x_t, lag(1)}{p_end}

{pstd}Compare against the Driscoll-Kraay-style alternative{p_end}
{phang2}{cmd:. xtbetark y_ar1 _x _x_t, lag(1) vce(dk)}{p_end}

{pstd}Compare against the uncorrected VCE (numerically identical to {cmd:betark}){p_end}
{phang2}{cmd:. xtbetark y_ar1 _x _x_t, lag(1) vce(oim)}{p_end}
{phang2}{cmd:. betark y_ar1 _x _x_t, lag(1)}{p_end}

{pstd}Covariates in the scale (precision) equation{p_end}
{phang2}{cmd:. xtbetark y_ar2 _x _x_t, lag(2) scale(t)}{p_end}

{pstd}Postestimation -- AR-adjusted conditional mean and variance{p_end}
{phang2}{cmd:. xtbetark y_ar2 _x _x_t, lag(2)}{p_end}
{phang2}{cmd:. predict mu_hat, cmean}{p_end}
{phang2}{cmd:. predict var_hat, cvariance}{p_end}
{phang2}{cmd:. tsline y_ar2 mu_hat if id==1, xline(150) legend(off)}{p_end}



{marker stored_results}{...}
{title:Stored results}

{pstd}
{cmd:xtbetark} stores the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations (excludes the first {it:k} observations of
each panel-time segment, used to initialize the AR recursion but not contributing to
the likelihood){p_end}
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
{synopt:{cmd:e(N_g)}}number of panels{p_end}
{synopt:{cmd:e(g_min)}}smallest panel size{p_end}
{synopt:{cmd:e(g_avg)}}average panel size{p_end}
{synopt:{cmd:e(g_max)}}largest panel size{p_end}
{synopt:{cmd:e(dklag)}}Bartlett kernel bandwidth used, always equal to {opt lag(#)} (only if {cmd:vce(dk)}); computed internally, not user-settable{p_end}
{synopt:{cmd:e(nmk)}}1 if the N-k normalization was applied (only if
{cmd:vce(pcse)}){p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:xtbetark}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(title)}}title in estimation output{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(timevar)} / {cmd:e(tvar)}}name of time variable{p_end}
{synopt:{cmd:e(panelvar)} / {cmd:e(ivar)}}name of panel variable{p_end}
{synopt:{cmd:e(link)}}link function used for the mean equation{p_end}
{synopt:{cmd:e(linkt)}}title used to label the mean-equation link in the output header{p_end}
{synopt:{cmd:e(slink)}}link function used for the scale equation{p_end}
{synopt:{cmd:e(slinkt)}}title used to label the scale-equation link in the output header{p_end}
{synopt:{cmd:e(noconstant)}}{cmd:noconstant}, if specified{p_end}
{synopt:{cmd:e(vce)}}{cmd:pcse}, {cmd:dk}, or {cmd:oim}{p_end}
{synopt:{cmd:e(vcetype)}}label describing the VCE, shown in the output header{p_end}
{synopt:{cmd:e(predict)}}{cmd:xtbetark_p}{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector, with three equation blocks: the mean equation
(named after {it:depvar}), {cmd:scale}, and {cmd:ar} (rho_1,...,rho_k){p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix, per {cmd:vce()}{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}



{marker references}{...}
{title:References}

{phang}
Beck, N. L., and J. N. Katz. 1995. What to do (and not to do) with
time-series cross-section data. {it:American Political Science Review}
89: 634-647.

{phang}
Driscoll, J. C., and A. C. Kraay. 1998. Consistent covariance matrix
estimation with spatially dependent panel data. {it:Review of Economics
and Statistics} 80(4): 549-560.

{phang}
Ferrari, S., and F. Cribari-Neto. 2004. Beta regression for modelling rates and
proportions. {it:Journal of Applied Statistics} 31(7): 799-815.

{phang}
Ferreira, G., J. I. Figueroa-Zuniga, and M. de Castro. 2015. Partially linear beta
regression model with autoregressive errors. {it:TEST} 24(4): 752-775.

{phang}
Hoechle, D. 2007. Robust standard errors for panel regressions with
cross-sectional dependence. {it:Stata Journal} 7(3): 281-312.

{phang}
Linden, A. 2026. Beta regression with autoregressive errors for interrupted time
series analysis of proportion and rate outcomes: A simulation study.
Preprint. {browse "https://arxiv.org/abs/2607.07914"}

{phang}
Linden, A. 2026. Extending beta regression to panel data
with higher-order autoregressive errors: A Simulation Study.
Preprint. arXiv.

{phang}
Linden, A. 2026. Extending Prais-Winsten regression to panel data
with higher-order autoregressive errors: A simulation study.
{browse "https://arxiv.org/html/2606.12596v1"}

{phang}
Newey, W. K., and K. D. West. 1994. Automatic lag selection in
covariance matrix estimation. {it:Review of Economic Studies} 61(4): 631-653.

{phang}
Rocha, A. V., and F. Cribari-Neto. 2009. Beta autoregressive moving average models.
{it:TEST} 18(3): 529-545.



{title:Author}

{pstd}
Ariel Linden{break}
Linden Consulting Group, LLC{break}
alinden@lindenconsulting.org{break}



{title:Citation of {cmd:xtbetark}}

{p 4 8 2}{cmd:xtbetark} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden, Ariel. 2026. XTBETARK: Stata module for computing beta regression with AR(k) errors for
proportion/rate outcomes, by joint conditional maximum likelihood, with panel-corrected standard errors.
Statistical Software Components SXXXXXX, Boston College Department of Economics. {p_end}



{title:Also see}

{psee}
Online: {helpb betark} (if installed), {helpb praisk} (if installed), 
{helpb xtpraisk} (if installed), {helpb poissark} (if installed),
{helpb betareg}, {helpb xtpcse} {p_end}
