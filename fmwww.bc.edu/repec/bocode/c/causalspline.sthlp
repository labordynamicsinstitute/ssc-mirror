{smcl}
{* v1.0.0 2026-03-17}{...}
{hline}
help for {hi:causalspline}
{hline}

{title:Title}

{phang}
{bf:causalspline} {hline 2} Nonlinear causal dose-response estimation
via restricted cubic splines


{title:Syntax}

{p 8 17 2}
{cmd:causalspline}
{ifin}
{cmd:,}
{opt out:come(varname)}
{opt treat:ment(varname)}
{opt conf:ounders(varlist)}
[{it:options}]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt out:come(varname)}}outcome variable Y{p_end}
{synopt:{opt treat:ment(varname)}}continuous treatment variable T{p_end}
{synopt:{opt conf:ounders(varlist)}}pre-treatment confounders X{p_end}
{syntab:Estimation}
{synopt:{opt meth:od(string)}}estimation method: {bf:ipw} (default),
    {bf:gcomp}, {bf:dr}{p_end}
{synopt:{opt dfe:xposure(#)}}spline df for treatment curve; default 4{p_end}
{synopt:{opt eval:grid(#)}}number of grid evaluation points; default 100{p_end}
{synopt:{opt boot:reps(#)}}bootstrap replications for SE; default 200{p_end}
{synopt:{opt level(#)}}confidence level; default 95{p_end}
{syntab:Output}
{synopt:{opt savec:urve(filename)}}save dose-response curve to dataset{p_end}
{synopt:{opt verb:ose}}print progress messages{p_end}
{synoptline}


{title:Description}

{pstd}
{cmd:causalspline} estimates the causal dose-response function
E[Y(t)] = E[Y^(t)] for a {bf:continuous treatment} T under the
unconfoundedness assumption (Y(t) ? T | X for all t).

{pstd}
The exposure-response curve f(T) is modeled using {bf:restricted cubic
splines} (Harrell parameterisation), allowing recovery of nonlinear
dose-response shapes: thresholds, diminishing returns, inverted-U
patterns, and other nonlinear structures without parametric assumptions.

{pstd}
Three identification strategies are available:

{phang2}
{bf:ipw}: Inverse Probability Weighting via the Generalised Propensity
Score (GPS). Fits a linear model for T|X, computes stabilised weights
w_i = f(T_i) / f(T_i|X_i) using normal densities, trims at the 1st/99th
percentiles, and estimates E[Y(t)] by weighted regression of Y on the
spline basis.

{phang2}
{bf:gcomp}: G-computation (outcome regression). Fits OLS of Y on
spline basis plus covariates, then standardises predictions over the
covariate distribution.

{phang2}
{bf:dr}: Doubly robust. Averages the IPW and G-computation estimates.
Consistent if either the GPS model or the outcome model is correctly
specified.

{pstd}
Standard errors are obtained by nonparametric bootstrap.


{title:Post-estimation commands}

{pstd}
After {cmd:causalspline}, the following companion commands are available:

{phang2}{cmd:cs_gradient} - first and second numerical derivatives of E[Y(t)]{p_end}
{phang2}{cmd:cs_fragility} - geometric fragility curve (curvature / slope diagnostics){p_end}
{phang2}{cmd:cs_region, a(#) b(#)} - regional fragility integral over [a, b]{p_end}
{phang2}{cmd:cs_overlap} - ESS and weight diagnostics{p_end}
{phang2}{cmd:cs_plot} - dose-response curve graph{p_end}


{title:Stored results}

{pstd}
{cmd:causalspline} stores the following in {cmd:r()}:

{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Scalars}{p_end}
{synopt:{cmd:r(n)}}sample size{p_end}
{synopt:{cmd:r(t_min)}}minimum treatment value{p_end}
{synopt:{cmd:r(t_max)}}maximum treatment value{p_end}
{synopt:{cmd:r(ess)}}effective sample size (IPW/DR only){p_end}
{synopt:{cmd:r(ess_pct)}}ESS as % of n (IPW/DR only){p_end}
{synopt:{cmd:r(evalgrid)}}number of evaluation points{p_end}
{synopt:{cmd:r(dfexposure)}}spline df for exposure{p_end}
{p2col 5 18 22 2: Matrices}{p_end}
{synopt:{cmd:r(curve_t)}}treatment grid (ng x 1){p_end}
{synopt:{cmd:r(curve_est)}}estimated E[Y(t)] (ng x 1){p_end}
{synopt:{cmd:r(curve_se)}}bootstrap SE (ng x 1){p_end}
{synopt:{cmd:r(curve_lo)}}lower CI bound (ng x 1){p_end}
{synopt:{cmd:r(curve_hi)}}upper CI bound (ng x 1){p_end}
{p2col 5 18 22 2: Macros}{p_end}
{synopt:{cmd:r(method)}}estimation method{p_end}
{synopt:{cmd:r(outcome)}}outcome variable name{p_end}
{synopt:{cmd:r(treatment)}}treatment variable name{p_end}
{synopt:{cmd:r(cmd)}}causalspline{p_end}


{title:Examples}

{pstd}
{bf:Simulate data and run all methods}

{phang2}{cmd:. cs_simulate 500, dgp(threshold) seed(1) clear}{p_end}
{phang2}{cmd:. causalspline, outcome(Y) treatment(T) confounders(X1 X2 X3) method(ipw)}{p_end}
{phang2}{cmd:. cs_plot}{p_end}
{phang2}{cmd:. cs_overlap}{p_end}
{phang2}{cmd:. cs_gradient}{p_end}
{phang2}{cmd:. cs_fragility, type(curvature_ratio)}{p_end}
{phang2}{cmd:. cs_region, a(2) b(4)}{p_end}

{pstd}
{bf:G-computation}

{phang2}{cmd:. causalspline, outcome(Y) treatment(T) confounders(X1 X2 X3) ///}{p_end}
{phang2}{cmd:      method(gcomp) dfexposure(5) evalgrid(100)}{p_end}

{pstd}
{bf:Doubly robust with saved curve}

{phang2}{cmd:. causalspline, outcome(Y) treatment(T) confounders(X1 X2 X3) ///}{p_end}
{phang2}{cmd:      method(dr) bootreps(500) savecurve(my_curve.dta)}{p_end}

{pstd}
{bf:Fragility diagnostics}

{phang2}{cmd:. cs_fragility, type(inverse_slope) savefragility(frag.dta)}{p_end}
{phang2}{cmd:. cs_region, a(3) b(7) type(curvature_ratio)}{p_end}


{title:Methods and formulas}

{pstd}
Let T be a continuous treatment, Y the outcome, X a vector of covariates.
The causal dose-response function is mu(t) = E[Y(t)].

{pstd}
{bf:GPS / IPW weights:}
Fit E[T|X] via OLS. Compute stabilised weights:
w_i = ?(T_i; mu_T, ?_T) / ?(T_i; ?[T_i|X_i], ??)
where ? is the normal density. Weights are trimmed and Hajek-normalised.

{pstd}
{bf:Spline basis:}
Uses Harrell's restricted cubic spline parameterisation (implemented via
{cmd:mkspline, cubic}).

{pstd}
{bf:Fragility measures:}
slope fragility: F_s(t) = 1 / (|mu'(t)| + epsilon)
curvature fragility: F_c(t) = |mu''(t)| / (|mu'(t)| + epsilon)
where epsilon = 0.05 x median|mu'(t)| (adaptive).

{pstd}
{bf:Regional fragility:}
F?[a,b] = (1/(b-a)) ?_a^b F(t) dt  (trapezoidal integration)


{title:References}

{phang}
Hirano, K. & Imbens, G.W. (2004). The propensity score with continuous
treatments. In Gelman & Meng (Eds.), {it:Applied Bayesian Modeling and Causal
Inference from Incomplete-Data Perspectives} (pp. 73-84). Wiley.

{phang}
Imbens, G.W. (2000). The role of the propensity score in estimating
dose-response functions. {it:Biometrika}, 87(3), 706-710.

{phang}
Robins, J.M., Hernan, M.A. & Brumback, B. (2000). Marginal structural
models and causal inference in epidemiology.
{it:Epidemiology}, 11(5), 550-560.

{phang}
Hait, S. (2026). CausalSpline: Nonlinear Causal Dose-Response Estimation
via Splines. R package v0.1.0.
https://github.com/causalfragility-lab/CausalSpline


{title:Author}

{pstd}
Stata port based on CausalSpline R package by Subir Hait,
Michigan State University (haitsubi@msu.edu).


{title:Also see}

{psee}
Online: {helpb cs_gradient}, {helpb cs_fragility}, {helpb cs_region},
{helpb cs_overlap}, {helpb cs_simulate}, {helpb cs_plot}
{p_end}
