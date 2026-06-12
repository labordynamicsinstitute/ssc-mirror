{smcl}
{* *! 1.0.0 10Jun2026}{...}
{title:Title}

{phang}
{bf:poissark} {hline 2} Poisson regression with integer-valued autoregressive-corrected standard errors


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:poissark}
{depvar}
[{indepvars}]
{ifin}
{cmd:,}
{cmd:lag(}{it:#}{cmd:)}
[{it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{p2coldent:* {opt lag(#)}}set maximum lag order of autocorrelation{p_end}
{synopt:{opt off:set(varname)}}include {it:varname} in model with coefficient constrained to 1{p_end}
{synopt:{opt exp:osure(varname)}}include ln({it:varname}) in model with coefficient constrained to 1{p_end}
{synopt:{opt nocons:tant}}suppress constant term{p_end}

{syntab:Reporting}
{synopt:{opt irr}}report incidence-rate ratios{p_end}
{synopt:{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synopt:{opt coefl:egend}}display legend instead of statistics{p_end}
{synopt:{opt nol:og}}suppress iteration log{p_end}

{syntab:Convergence}
{synopt:{opt tol:erance(#)}}convergence criterion; default is {cmd:tolerance(1e-6)}{p_end}
{synopt:{opt iter:ate(#)}}maximum iterations; default is {cmd:iterate(250)}{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
* {opt lag(#)} is required.
{p_end}
{p 4 6 2}
You must {cmd:tsset} your data before using {cmd:poissark}; see {helpb tsset}.{p_end}
{p 4 6 2}
Factor variables are allowed in {it:indepvars}; see {helpb fvvarlist}.{p_end}
{p 4 6 2}
Time-series operators are allowed in {it:depvar} and {it:indepvars}; see {helpb tsvarlist}.{p_end}
{p 4 6 2}
Typing {cmd:poissark} without arguments replays the last estimation results.{p_end}



{p 4 6 2}
The following postestimation predict options are available after {cmd:poissark}:{p_end}

{p 8 17 2}
{cmd:predict} {newvar} {ifin} [{cmd:,} {it:statistic}]

{synoptset 17 tabbed}{...}
{synopthdr:statistic}
{synoptline}
{synopt:{opt n}}predicted number of events; the default; equal to exp(xb) if neither
{opt offset()} nor {opt exposure()} was specified; exp(xb+offset) if {opt offset()} was
specified; or exp(xb)*exposure if {opt exposure()} was specified{p_end}
{synopt:{opt ir}}incidence rate exp(xb), ignoring any offset or exposure variable{p_end}
{synopt:{opt xb}}linear prediction xb; equal to xb if neither {opt offset()} nor
{opt exposure()} was specified; xb+offset if {opt offset()} was specified; or
xb+ln(exposure) if {opt exposure()} was specified{p_end}
{synopt:{opt stdp}}standard error of the linear prediction{p_end}
{synoptline}
{p 4 6 2}
These statistics are available both in and out of sample; type
{cmd:predict} {it:...} {cmd:if e(sample)} {it:...} if wanted only for the estimation sample.{p_end}
{p 4 6 2}
Use the {opt nooffset} option to ignore the offset or exposure in predictions for
{opt n} and {opt xb}.{p_end}



{marker description}{...}
{title:Description}

{pstd}
{cmd:poissark} fits Poisson regression models for count time series with
autoregressive errors of order {it:k}. Regression coefficients are estimated by
Poisson maximum likelihood; the AR thinning parameters rho_1,...,rho_k are
estimated by conditional least squares (CLS) applied to the integer-valued
autoregressive (INAR(p)) model of {help poissark##references:Du and Li (1991)},
which extends the INAR(1) model of {help poissark##references:McKenzie (1985)}
and {help poissark##references:Al-Osh and Alzaid (1987)} to arbitrary order
using independent binomial thinning at each lag. Standard errors for the
regression coefficients are corrected via an INAR-corrected sandwich
estimator that accounts for the estimated autocorrelation structure
({help poissark##references:Klimko and Nelson 1978}). 

{pstd}
Only positive autocorrelation is supported (rho_j >= 0), which is a fundamental constraint
of the binomial thinning mechanism.



{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}
{opt lag(#)} specifies the order of the autoregressive process and must be a positive integer. 

{phang}
{opt off:set(varname)} specifies a variable to be included in the model
with its coefficient constrained to 1.

{phang}
{opt exp:osure(varname)} specifies a variable representing exposure time or
population size. The natural log of {it:varname} is included as an offset.

{phang}
{opt noconstant} suppresses the constant term.


{dlgtab:Reporting}

{phang}
{opt irr} reports exponentiated coefficients as incidence-rate ratios.

{phang}
{opt l:evel(#)} specifies the confidence level as a percentage. Default is
{cmd:level(95)}.

{phang}
{opt coefl:egend}  display legend instead of statistics.

{phang}
{opt nol:og} suppresses the iteration log showing rho values at each iteration.

{dlgtab:Convergence}

{phang}
{opt tol:erance(#)} specifies the convergence criterion. Iteration stops when max|rho_new - rho_old| < #. 
Default is {cmd:tolerance(1e-6)}.

{phang}
{opt iter:ate(#)} specifies the maximum number of iterations. Default is {cmd:iterate(250)}.



{marker examples}{...}
{title:Examples}

{pstd}Load the example dataset (N=730, single-group ITSA, intervention at t=365):{p_end}
{phang2}{cmd:. use poissark_example, clear}{p_end}
{phang2}{cmd:. tsset t}{p_end}

{pstd}Fit AR(1) model (true rho=0.4):{p_end}
{phang2}{cmd:. poissark y_ar1 t x x_t, lag(1)}{p_end}

{pstd}Fit AR(2) model (true rho1=0.4, rho2=0.2):{p_end}
{phang2}{cmd:. poissark y_ar2 t x x_t, lag(2)}{p_end}

{pstd}Fit AR(3) model (true rho1=0.4, rho2=0.3, rho3=0.2):{p_end}
{phang2}{cmd:. poissark y_ar3 t x x_t, lag(3)}{p_end}

{pstd}Report incidence-rate ratios:{p_end}
{phang2}{cmd:. poissark y_ar1 t x x_t, lag(1) irr}{p_end}

{pstd}Display coefficient legends:{p_end}
{phang2}{cmd:. poissark y_ar2 t x x_t, lag(2) coefl}{p_end}

{pstd}Postestimation -- predicted counts and incidence rates:{p_end}
{phang2}{cmd:. poissark y_ar1 t x x_t, lag(1)}{p_end}
{phang2}{cmd:. predict n_hat}{p_end}
{phang2}{cmd:. predict ir_hat, ir}{p_end}



{marker stored_results}{...}
{title:Stored results}

{pstd}
{cmd:poissark} stores the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(df_m)}}model degrees of freedom{p_end}
{synopt:{cmd:e(chi2)}}Wald chi-squared statistic{p_end}
{synopt:{cmd:e(p)}}p-value for Wald chi-squared{p_end}
{synopt:{cmd:e(ll)}}Poisson log likelihood at final beta estimates{p_end}
{synopt:{cmd:e(deviance)}}deviance{p_end}
{synopt:{cmd:e(pearson)}}Pearson chi-squared{p_end}
{synopt:{cmd:e(iterations)}}number of iterations to convergence{p_end}
{synopt:{cmd:e(tolerance)}}convergence tolerance{p_end}
{synopt:{cmd:e(ngaps)}}number of gaps in sample (includes panel changes){p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:poissark}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(title)}}title in estimation output{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(timevar)}}name of time variable{p_end}
{synopt:{cmd:e(panelvar)}}name of panel variable (if panel data){p_end}
{synopt:{cmd:e(vce)}}{it:vcetype}{p_end}
{synopt:{cmd:e(vcetype)}}{cmd:INAR-corrected} (integer-valued autoregressive-corrected){p_end}
{synopt:{cmd:e(predict)}}{cmd:poissark_p}{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector{p_end}
{synopt:{cmd:e(V)}}integer-valued autoregressive (INAR)-corrected variance-covariance matrix{p_end}
{synopt:{cmd:e(rho)}}CLS thinning parameter estimates (1 x p){p_end}
{synopt:{cmd:e(serho)}}standard errors of thinning parameter estimates (1 x p){p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}



{marker references}{...}
{title:References}

{phang}
Al-Osh, M.A. and A.A. Alzaid. 1987. First-order integer-valued autoregressive
(INAR(1)) process. {it:Journal of Time Series Analysis} 8(3): 261-275.

{phang}
Du, J.G. and Y. Li. 1991. The integer-valued autoregressive (INAR(p)) model.
{it:Journal of Time Series Analysis} 12(2): 129-142.

{phang}
Klimko, L.A. and P.I. Nelson. 1978. On conditional least squares estimation
for stochastic processes. {it:Annals of Statistics} 6(3): 629-642.

{phang}
McKenzie, E. 1985. Some simple models for discrete variate time series.
{it:Journal of the American Water Resources Association} 21(4): 645-650.



{marker author}{...}
{title:Author}

{pstd}
Ariel Linden{break}
Linden Consulting Group, LLC{break}
alinden@lindenconsulting.org{break}



{title:Citation of {cmd:poissark}}

{p 4 8 2}{cmd:poissark} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden, Ariel. 2026. POISSARK: Stata module for computing Poisson regression with integer-valued autoregressive-corrected standard errors.
Statistical Software Components s000000, Boston College Department of Economics.
{p_end}



{psee}
Online: {helpb poisson}, {helpb praisk}, (if installed), {helpb xtpraisk}, (if installed)
{p_end}

