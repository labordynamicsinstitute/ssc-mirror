{smcl}
{* *! version 1.0.0  02Feb2026}{...}
{viewerjumpto "Syntax" "boundedur##syntax"}{...}
{viewerjumpto "Description" "boundedur##description"}{...}
{viewerjumpto "Options" "boundedur##options"}{...}
{viewerjumpto "Examples" "boundedur##examples"}{...}
{viewerjumpto "Stored results" "boundedur##results"}{...}
{viewerjumpto "References" "boundedur##references"}{...}
{viewerjumpto "Author" "boundedur##author"}{...}
{title:Title}

{phang}
{bf:boundedur} {hline 2} Unit root tests for bounded time series


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:boundedur}
{varname}
{ifin}
{cmd:,}
{opt lbound(#)}
[{it:options}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{p2coldent:* {opt lbound(#)}}lower bound value{p_end}
{synopt:{opt ubound(#)}}upper bound value; default is infinity (one-sided bound){p_end}
{synopt:{opt test(string)}}test type: {cmd:adf}, {cmd:adfalpha}, {cmd:adft}, {cmd:mzalpha}, {cmd:mzt}, {cmd:msb}, or {cmd:all}; default is {cmd:all}{p_end}

{syntab:Lag selection}
{synopt:{opt lags(#)}}number of lags for ADF regression; default is automatic selection using MAIC{p_end}
{synopt:{opt maxlag(#)}}maximum lag for MAIC selection; default is 12*(T/100)^0.25{p_end}

{syntab:Simulation}
{synopt:{opt nsim(#)}}number of Monte Carlo replications; default is 499{p_end}
{synopt:{opt nstep(#)}}discretization steps for simulated process; default is T{p_end}
{synopt:{opt recolor}}apply re-coloring device to MC innovations{p_end}
{synopt:{opt krclag(#)}}lags for re-coloring AR polynomial; default equals lags(){p_end}
{synopt:{opt nosimulation}}compute test statistics only, no p-values{p_end}
{synopt:{opt seed(#)}}set random number seed{p_end}

{syntab:Reporting}
{synopt:{opt level(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synopt:{opt detrend(string)}}detrending method: {cmd:constant} or {cmd:none}; default is {cmd:constant}{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}* {opt lbound(#)} is required.{p_end}
{p 4 6 2}Time-series operators are allowed; see {help tsvarlist}.{p_end}
{p 4 6 2}Data must be {cmd:tsset}; see {helpb tsset}.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:boundedur} implements unit root tests for bounded time series as developed by 
Cavaliere and Xu (2014). Many economic and financial series are bounded either by construction 
(e.g., interest rates, unemployment rates) or through policy controls (e.g., target zone 
exchange rates). Conventional unit root tests (ADF, Phillips-Perron) are unreliable in the 
presence of bounds, as they tend to over-reject the null hypothesis of a unit root, even 
asymptotically.

{pstd}
This package implements:

{phang2}• Augmented Dickey-Fuller (ADF) tests: ADF_alpha and ADF_t{p_end}
{phang2}• Modified M tests (Ng & Perron, 2001): MZ_alpha, MZ_t, and MSB{p_end}
{phang2}• Simulation-based p-values that account for bound effects{p_end}
{phang2}• Optional re-coloring device for improved finite sample performance{p_end}

{pstd}
The tests are based on a simulation approach that uses consistent estimators of the bound 
parameters to generate the appropriate null distribution via Monte Carlo methods. The 
implementation follows Algorithm 1 in Cavaliere and Xu (2014) exactly.


{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opt lbound(#)} specifies the lower bound. This is required. The variable values 
must be greater than or equal to this bound.

{phang}
{opt ubound(#)} specifies the upper bound. If not specified, the test assumes 
a one-sided bound (lower bound only). When specified, the variable values must 
be less than or equal to this bound.

{phang}
{opt test(string)} specifies which test(s) to compute:

{phang3}{cmd:adf} - both ADF_alpha and ADF_t{p_end}
{phang3}{cmd:adfalpha} - ADF_alpha statistic only{p_end}
{phang3}{cmd:adft} - ADF_t statistic only{p_end}
{phang3}{cmd:mzalpha} - MZ_alpha statistic only{p_end}
{phang3}{cmd:mzt} - MZ_t statistic only{p_end}
{phang3}{cmd:msb} - MSB statistic only{p_end}
{phang3}{cmd:all} - all tests (default){p_end}

{dlgtab:Lag selection}

{phang}
{opt lags(#)} specifies the number of lags to include in the ADF regression. 
If not specified, the optimal lag length is selected automatically using the 
Modified Akaike Information Criterion (MAIC) of Ng and Perron (2001).

{phang}
{opt maxlag(#)} specifies the maximum lag length to consider when using MAIC 
selection. The default is 12*(T/100)^0.25 as recommended by Ng and Perron (2001).

{dlgtab:Simulation}

{phang}
{opt nsim(#)} specifies the number of Monte Carlo replications used to compute 
p-values. The default is 499. Larger values (e.g., 999 or 4999) provide more 
accurate p-values but increase computation time.

{phang}
{opt nstep(#)} specifies the number of discretization steps n used to approximate 
the continuous-time regulated Brownian motion. The default is T (sample size), 
which the paper shows provides better finite sample performance than n=20,000.

{phang}
{opt recolor} applies the re-coloring (sieve bootstrap) device described in 
Section 4.3 of the paper. This improves finite sample performance when errors 
are serially correlated. Highly recommended for practical applications.

{phang}
{opt krclag(#)} specifies the number of lags used in the AR polynomial for 
the re-coloring device. The default equals the value specified in {opt lags()}.

{phang}
{opt nosimulation} computes only the test statistics without simulation-based 
p-values. This provides the standard (possibly oversized) test statistics.

{phang}
{opt seed(#)} sets the random number seed for reproducible results.

{dlgtab:Reporting}

{phang}
{opt level(#)} specifies the confidence level for displaying test decisions. 
The default is {cmd:level(95)}.

{phang}
{opt detrend(string)} specifies how to remove deterministic components:

{phang3}{cmd:constant} - removes sample mean (default){p_end}
{phang3}{cmd:none} - no detrending{p_end}


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse lutkepohl}{p_end}
{phang2}{cmd:. tsset qtr}{p_end}

{pstd}Test for unit root with lower bound at 0 (e.g., interest rate){p_end}
{phang2}{cmd:. boundedur investment, lbound(0)}{p_end}

{pstd}Test with two bounds{p_end}
{phang2}{cmd:. boundedur investment, lbound(2) ubound(10)}{p_end}

{pstd}Specify lag length manually{p_end}
{phang2}{cmd:. boundedur investment, lbound(0) lags(4)}{p_end}

{pstd}Use re-coloring for better finite sample performance{p_end}
{phang2}{cmd:. boundedur investment, lbound(0) recolor}{p_end}

{pstd}Run only ADF_t test with more simulations{p_end}
{phang2}{cmd:. boundedur investment, lbound(0) test(adft) nsim(999)}{p_end}

{pstd}Compute test statistics without simulation{p_end}
{phang2}{cmd:. boundedur investment, lbound(0) nosimulation}{p_end}

{pstd}US 3-month Treasury Bill example from paper{p_end}
{phang2}{cmd:. * Load US T-bill data}{p_end}
{phang2}{cmd:. use "us_tbill_data.dta", clear}{p_end}
{phang2}{cmd:. tsset time}{p_end}
{phang2}{cmd:. boundedur tbill, lbound(0) recolor}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:boundedur} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}number of observations{p_end}
{synopt:{cmd:r(lags)}}number of lags used{p_end}
{synopt:{cmd:r(c_lower)}}estimated lower bound parameter{p_end}
{synopt:{cmd:r(c_upper)}}estimated upper bound parameter{p_end}
{synopt:{cmd:r(sigma2_lr)}}long-run variance estimate{p_end}
{synopt:{cmd:r(lbound)}}specified lower bound{p_end}
{synopt:{cmd:r(ubound)}}specified upper bound{p_end}
{synopt:{cmd:r(adf_alpha)}}ADF_alpha test statistic{p_end}
{synopt:{cmd:r(pval_adf_alpha)}}p-value for ADF_alpha{p_end}
{synopt:{cmd:r(adf_t)}}ADF_t test statistic{p_end}
{synopt:{cmd:r(pval_adf_t)}}p-value for ADF_t{p_end}
{synopt:{cmd:r(mz_alpha)}}MZ_alpha test statistic{p_end}
{synopt:{cmd:r(pval_mz_alpha)}}p-value for MZ_alpha{p_end}
{synopt:{cmd:r(mz_t)}}MZ_t test statistic{p_end}
{synopt:{cmd:r(pval_mz_t)}}p-value for MZ_t{p_end}
{synopt:{cmd:r(msb)}}MSB test statistic{p_end}
{synopt:{cmd:r(pval_msb)}}p-value for MSB{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(depvar)}}dependent variable name{p_end}
{synopt:{cmd:r(timevar)}}time variable name{p_end}
{synopt:{cmd:r(detrend)}}detrending method{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(results)}}matrix of test statistics and p-values{p_end}


{marker references}{...}
{title:References}

{phang}
Cavaliere, G., and F. Xu. 2014. Testing for unit roots in bounded time series. 
{it:Journal of Econometrics} 178: 259-272.

{phang}
Ng, S., and P. Perron. 2001. LAG length selection and the construction of unit root 
tests with good size and power. {it:Econometrica} 69: 1519-1554.

{phang}
Phillips, P. C. B., and P. Perron. 1988. Testing for a unit root in time series 
regressions. {it:Biometrika} 75: 335-346.


{marker author}{...}
{title:Author}

{pstd}Dr. Merwan Roudane{break}
Independent Researcher{break}
Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}


{title:Also see}

{psee}
Online: {helpb dfuller}, {helpb pperron}, {helpb dfgls}
{p_end}
