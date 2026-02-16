{smcl}
{* *! version 1.0.1  13feb2026}{...}
{viewerjumpto "Title" "xtbreakcoint##title"}{...}
{viewerjumpto "Syntax" "xtbreakcoint##syntax"}{...}
{viewerjumpto "Description" "xtbreakcoint##description"}{...}
{viewerjumpto "Options" "xtbreakcoint##options"}{...}
{viewerjumpto "Models" "xtbreakcoint##models"}{...}
{viewerjumpto "MQ test" "xtbreakcoint##mqtest"}{...}
{viewerjumpto "Examples" "xtbreakcoint##examples"}{...}
{viewerjumpto "Stored results" "xtbreakcoint##stored"}{...}
{viewerjumpto "References" "xtbreakcoint##references"}{...}
{viewerjumpto "Author" "xtbreakcoint##author"}{...}

{marker title}{...}
{title:Title}

{p2colset 5 24 26 2}{...}
{p2col:{bf:xtbreakcoint} {hline 2}}Panel cointegration test with structural breaks and cross-section dependence{p_end}
{p2colreset}{...}

    {bf:Version:} 1.0.1
    {bf:Date:}    13 February 2026
    {bf:Author:}  Dr Merwan Roudane ({browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com})

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:xtbreakcoint}
{depvar} {indepvars}
{ifin}
[{cmd:,} {it:options}]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt mod:el(string)}}deterministic specification; default is {bf:trendshift}{p_end}
{synopt:{opt maxf:actors(#)}}maximum number of common factors; default is {bf:5}{p_end}
{synopt:{opt nof:actor}}skip factor estimation entirely{p_end}

{syntab:ADF test}
{synopt:{opt maxl:ag(#)}}maximum ADF lag order; default is {bf:4}{p_end}
{synopt:{opt met:hod(string)}}{bf:auto} (t-sig at 10%) or {bf:fixed}; default is {bf:auto}{p_end}

{syntab:Estimation}
{synopt:{opt trim(#)}}trimming fraction for break search; default is {bf:0.15}{p_end}
{synopt:{opt maxi:ter(#)}}maximum iterations for factor estimation; default is {bf:20}{p_end}
{synopt:{opt tol:erance(#)}}convergence tolerance; default is {bf:0.001}{p_end}

{syntab:Output}
{synopt:{opt gr:aph}}display graph of estimated break dates{p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}
{cmd:xtbreakcoint} implements the panel cointegration test of
{bf:Banerjee & Carrion-i-Silvestre (2015)}, which allows for
structural breaks and cross-section dependence via common factors.

{pstd}
The test proceeds in five steps:

{phang}1. For each panel unit, estimate the cointegrating regression
in first differences, searching for the optimal break date that
minimizes the sum of squared residuals over [{bf:trim}*T, (1-{bf:trim})*T].{p_end}

{phang}2. Extract common factors from the residual matrix via PCA
(principal component analysis) using the Bai & Ng (2002) IC1
information criterion to determine the number of factors.{p_end}

{phang}3. Iterate: given factors, re-estimate breaks; given breaks,
re-estimate factors — until the SSR converges.{p_end}

{phang}4. Run individual ADF tests on the idiosyncratic residuals
(after removing common factors). Test for common stochastic trends
using the Bai & Ng (2004) MQ test (both non-parametric and parametric).{p_end}

{phang}5. Construct the panel test statistic:{p_end}

{p 12 12 2}
Z_t = sqrt(N) * (tbar - E[t]) / sqrt(Var[t])

{pstd}
where tbar is the average of the individual ADF statistics,
and E[t] and Var[t] are empirical moments tabulated under H0.

{pstd}
Under H0 (no cointegration), Z_t ~ N(0,1).
Reject H0 for sufficiently negative Z_t values (one-sided test).

{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}
{opt model(string)} specifies the deterministic component.
Options are:

{p 12 12 2}
{bf:constant} (or 1) — constant only (Pedroni-type){break}
{bf:trend} (or 2) — constant + time trend{break}
{bf:levelshift} (or 3) — constant + level shift{break}
{bf:trendshift} (or 4) — constant + trend + level shift [default]{break}
{bf:regimeshift} (or 5) — constant + trend + level + slope shift{p_end}

{phang}
{opt maxfactors(#)} sets the maximum number of common factors
to extract. Set to 0 or use {opt nofactor} to skip factor estimation.

{dlgtab:ADF test}

{phang}
{opt maxlag(#)} sets the maximum lag order for the individual ADF tests.

{phang}
{opt method(string)} selects the lag order selection method:
{bf:auto} (default) uses the general-to-specific t-significance approach
(drop the last lag if |t| < 1.645);
{bf:fixed} uses all lags up to {it:maxlag}.

{dlgtab:Estimation}

{phang}
{opt trim(#)} sets the trimming fraction for the break date search.
Break dates are searched over [{it:trim}*T, (1-{it:trim})*T]. Default: 0.15.

{phang}
{opt maxiter(#)} maximum number of iterations for the
factor-break estimation algorithm. Default: 20.

{phang}
{opt tolerance(#)} convergence tolerance. The algorithm stops
when the absolute change in SSR between iterations falls below
this value. Default: 0.001.

{marker models}{...}
{title:Deterministic Models}

{pstd}
The five deterministic specifications correspond to different
assumptions about the data generating process:

{p2colset 5 25 27 2}{...}
{p2col:Model}Deterministic terms{p_end}
{p2line}
{p2col:{bf:constant}}   mu_i{p_end}
{p2col:{bf:trend}}       mu_i + delta_i * t{p_end}
{p2col:{bf:levelshift}} mu_i + theta_i * DU_it{p_end}
{p2col:{bf:trendshift}} mu_i + delta_i * t + theta_i * DU_it{p_end}
{p2col:{bf:regimeshift}}mu_i + delta_i * t + theta_i * DU_it + gamma_i * DT_it{p_end}
{p2line}

{pstd}
where DU_it = I(t > T_b,i) is the level shift dummy and
DT_it = (t - T_b,i) * I(t > T_b,i) is the slope shift dummy.

{marker mqtest}{...}
{title:MQ Test for Common Stochastic Trends}

{pstd}
When common factors are detected, {cmd:xtbreakcoint} automatically
performs the Bai & Ng (2004) MQ test to determine the number of
common stochastic trends among the estimated factors.

{pstd}
Two versions of the test are computed:

{phang}{bf:Non-parametric MQ:} Uses Newey-West long-run covariance
estimation with bandwidth bigJ = 4*ceil((min(T,N)/100)^(1/4)).
No short-run dynamics are removed.{p_end}

{phang}{bf:Parametric MQ:} Estimates a VAR(p) on the rotated factors
to filter out short-run dynamics, then computes the test statistic
on the filtered series. The VAR order is selected using BIC.{p_end}

{pstd}
Both tests use the sequential procedure of Bai & Ng (2004):
starting from r* = r (the number of factors), the null hypothesis
of r* common trends is tested at 5% level. If rejected, r* is
decremented and the test is repeated until the null is not rejected.

{pstd}
Critical values are from Bai & Ng (2004, Econometrica), Table I.
For Model 5 (regime shift), T-dependent critical values are used.

{pstd}
Cross-section dependence (CD) testing can be performed separately
using existing Stata commands:

{phang2}{cmd:. xtcsd, pesaran}      (Pesaran 2004 CD test){p_end}
{phang2}{cmd:. xtcd2}               (Pesaran 2015 weak CD test){p_end}

{marker examples}{...}
{title:Examples}

{pstd}{bf:Using the replication data}{p_end}

{pstd}The file {bf:xtbreakcoint_example.xlsx} contains the original
data from Banerjee & Carrion-i-Silvestre (2015): log import prices,
log foreign prices, and log exchange rates for 10 European countries,
9 sectors, monthly 1995m1-2005m3.{p_end}

{pstd}Load the sector 0 data:{p_end}
{phang2}{cmd:. import excel "xtbreakcoint_example.xlsx", sheet("sector0") firstrow clear}{p_end}
{phang2}{cmd:. encode country, gen(id)}{p_end}
{phang2}{cmd:. xtset id t}{p_end}

{pstd}Basic test — trend shift model (default, matching GAUSS model=4):{p_end}
{phang2}{cmd:. xtbreakcoint lpm lfp lexrate, model(trendshift) maxlag(12)}{p_end}

{pstd}Constant model (no break):{p_end}
{phang2}{cmd:. xtbreakcoint lpm lfp lexrate, model(constant)}{p_end}

{pstd}Level shift model with automatic lag selection:{p_end}
{phang2}{cmd:. xtbreakcoint lpm lfp lexrate, model(levelshift) maxlag(12)}{p_end}

{pstd}Regime shift model with graph:{p_end}
{phang2}{cmd:. xtbreakcoint lpm lfp lexrate, model(regimeshift) maxlag(12) graph}{p_end}

{pstd}No factor estimation (ignore cross-section dependence):{p_end}
{phang2}{cmd:. xtbreakcoint lpm lfp lexrate, model(trendshift) nofactor}{p_end}

{pstd}Access stored results:{p_end}
{phang2}{cmd:. di "Z_t = " r(Z_t) ", p-value = " r(p_value)}{p_end}
{phang2}{cmd:. di "Common factors = " r(nfactors) ", stochastic trends = " r(n_trends)}{p_end}
{phang2}{cmd:. mat list r(adf)}{p_end}
{phang2}{cmd:. mat list r(breaks)}{p_end}

{marker stored}{...}
{title:Stored results}

{pstd}
{cmd:xtbreakcoint} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(Z_t)}}panel Z_t test statistic{p_end}
{synopt:{cmd:r(p_value)}}one-sided p-value{p_end}
{synopt:{cmd:r(tbar)}}average of individual ADF statistics{p_end}
{synopt:{cmd:r(mean_t)}}E[t] under H0{p_end}
{synopt:{cmd:r(var_t)}}Var[t] under H0{p_end}
{synopt:{cmd:r(N)}}number of panels{p_end}
{synopt:{cmd:r(T)}}number of time periods{p_end}
{synopt:{cmd:r(nfactors)}}number of detected common factors{p_end}
{synopt:{cmd:r(n_trends)}}common stochastic trends (non-parametric MQ){p_end}
{synopt:{cmd:r(MQ_np)}}non-parametric MQ test statistic (Bai & Ng 2004){p_end}
{synopt:{cmd:r(n_trends_p)}}common stochastic trends (parametric MQ){p_end}
{synopt:{cmd:r(MQ_p)}}parametric MQ test statistic (Bai & Ng 2004){p_end}
{synopt:{cmd:r(iterations)}}number of convergence iterations{p_end}
{synopt:{cmd:r(reject_pct)}}individual rejection rate (%){p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(adf)}}(Nx1) individual ADF statistics{p_end}
{synopt:{cmd:r(lags)}}(Nx1) selected lag orders{p_end}
{synopt:{cmd:r(breaks)}}(Nx1) estimated break dates{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(model)}}deterministic model used{p_end}
{synopt:{cmd:r(depvar)}}dependent variable{p_end}
{synopt:{cmd:r(indepvars)}}independent variables{p_end}
{synopt:{cmd:r(method)}}lag selection method{p_end}

{marker references}{...}
{title:References}

{phang}
Banerjee, A. and J.L. Carrion-i-Silvestre (2015).
"Cointegration in panel data with structural breaks and
cross-section dependence."
{it:Journal of Applied Econometrics} 30(1): 1–22.
{browse "https://doi.org/10.1002/jae.2348"}

{phang}
Bai, J. and S. Ng (2002). "Determining the number of factors in
approximate factor models."
{it:Econometrica} 70(1): 191–221.

{phang}
Bai, J. and S. Ng (2004). "A PANIC attack on unit roots and
cointegration."
{it:Econometrica} 72(4): 1127–1177.

{phang}
Pesaran, M.H. (2004). "General diagnostic tests for cross section
dependence in panels."
{it:Cambridge Working Papers in Economics} 0435.

{phang}
Pedroni, P. (1999). "Critical values for cointegration tests in
heterogeneous panels with multiple regressors."
{it:Oxford Bulletin of Economics and Statistics} 61(S1): 653–670.

{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}

{pstd}
Translated from original GAUSS code by:{break}
Anindya Banerjee and Josep Lluís Carrion-i-Silvestre{break}
Department of Econometrics, University of Barcelona

{pstd}
Please cite as:{break}
Roudane, M. (2026). "{bf:xtbreakcoint}: Panel cointegration test with structural breaks
and cross-section dependence in Stata." Version 1.0.1.
{p_end}
