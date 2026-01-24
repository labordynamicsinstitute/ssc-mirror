{smcl}
{* *! version 1.0.0  23jan2026}{...}
{vieweralsosee "[TS] dfuller" "help dfuller"}{...}
{vieweralsosee "[TS] dfgls" "help dfgls"}{...}
{vieweralsosee "[R] boxcox" "help boxcox"}{...}
{viewerjumpto "Syntax" "kmtest##syntax"}{...}
{viewerjumpto "Description" "kmtest##description"}{...}
{viewerjumpto "Options" "kmtest##options"}{...}
{viewerjumpto "Examples" "kmtest##examples"}{...}
{viewerjumpto "Stored results" "kmtest##results"}{...}
{viewerjumpto "Methods and formulas" "kmtest##methods"}{...}
{viewerjumpto "References" "kmtest##references"}{...}
{viewerjumpto "Author" "kmtest##author"}{...}
{title:Title}

{phang}
{bf:kmtest} {hline 2} Kobayashi-McAleer tests of linear and logarithmic transformations for integrated processes


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:kmtest}
{varname}
{ifin}
[{cmd:,} {it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt l:ags(#)}}include {it:#} autoregressive lags in the model{p_end}
{synopt:{opt nod:rift}}assume the process has no drift (use U1/U2 statistics){p_end}

{syntab:Reporting}
{synopt:{opt lev:el(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synopt:{opt det:ail}}display additional parameter estimates{p_end}
{synopt:{opt gr:aph}}produce diagnostic graphs{p_end}
{synopt:{opt saveg:raph(filename)}}save graph to file{p_end}
{synoptline}
{p2colreset}{...}

{p 4 6 2}
{it:varname} must be a time-series variable with strictly positive values.
You must {cmd:tsset} your data before using {cmd:kmtest}; see {manhelp tsset TS}.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:kmtest} performs the Kobayashi-McAleer (1999) non-nested tests for determining
whether a time series should be modeled in levels (linear form) or in logarithms
(logarithmic form) when the series is integrated of order one, I(1).

{pstd}
The test addresses the common problem in applied econometrics of choosing between
modeling a variable {it:y_t} directly or modeling its logarithm ln({it:y_t}). This
choice has important implications for interpretation and inference.

{pstd}
The command provides two pairs of test statistics:

{phang2}
{bf:V1 and V2} (used when drift is present): These tests follow an asymptotic
normal distribution under the null hypothesis.

{phang2}
{bf:U1 and U2} (used when there is no drift): These tests follow a nonstandard
distribution related to functionals of Brownian motion.


{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}
{opt lags(#)} specifies the number of autoregressive lags to include when
modeling the first differences of the series. The default is {cmd:lags(0)},
which assumes the innovations are serially uncorrelated.

{phang}
{opt nodrift} specifies that the integrated process is assumed to have no drift
(mean zero first differences). When this option is specified, the U1 and U2
test statistics are computed, which follow a nonstandard distribution. Without
this option, the V1 and V2 statistics are computed, which are asymptotically
normal.

{dlgtab:Reporting}

{phang}
{opt level(#)} specifies the confidence level, as a percentage, for determining
statistical significance. The default is {cmd:level(95)}.

{phang}
{opt detail} displays additional information including estimated drift parameters
and innovation variances for both the linear and logarithmic models.

{phang}
{opt graph} produces a two-panel time series graph showing the original series
and its logarithm for visual comparison.

{phang}
{opt savegraph(filename)} saves the diagnostic graph to the specified file.


{marker examples}{...}
{title:Examples}

{pstd}Setup: Load example data{p_end}
{phang2}{cmd:. webuse lutkepohl2, clear}{p_end}
{phang2}{cmd:. tsset}{p_end}

{pstd}Basic test with drift (V1/V2 statistics){p_end}
{phang2}{cmd:. kmtest consumption}{p_end}

{pstd}Test with 2 autoregressive lags{p_end}
{phang2}{cmd:. kmtest consumption, lags(2)}{p_end}

{pstd}Test without drift (U1/U2 statistics){p_end}
{phang2}{cmd:. kmtest interest, nodrift}{p_end}

{pstd}Test with detailed output and graph{p_end}
{phang2}{cmd:. kmtest consumption, lags(1) detail graph}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:kmtest} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}number of observations{p_end}
{synopt:{cmd:r(lags)}}number of AR lags{p_end}

{pstd}
When drift is assumed present:

{synopt:{cmd:r(V1)}}V1 test statistic (H0: linear){p_end}
{synopt:{cmd:r(V1_pval)}}p-value for V1{p_end}
{synopt:{cmd:r(V2)}}V2 test statistic (H0: logarithmic){p_end}
{synopt:{cmd:r(V2_pval)}}p-value for V2{p_end}
{synopt:{cmd:r(mu)}}estimated drift in linear model{p_end}
{synopt:{cmd:r(eta)}}estimated drift in log model{p_end}
{synopt:{cmd:r(sigma)}}estimated std. dev. in linear model{p_end}
{synopt:{cmd:r(omega)}}estimated std. dev. in log model{p_end}

{pstd}
When drift is not present:

{synopt:{cmd:r(U1)}}U1 test statistic (H0: linear){p_end}
{synopt:{cmd:r(U1_pval)}}approximate p-value for U1{p_end}
{synopt:{cmd:r(U2)}}U2 test statistic (H0: logarithmic){p_end}
{synopt:{cmd:r(U2_pval)}}approximate p-value for U2{p_end}
{synopt:{cmd:r(sigma)}}estimated std. dev. in linear model{p_end}
{synopt:{cmd:r(omega)}}estimated std. dev. in log model{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(varname)}}name of the tested variable{p_end}
{synopt:{cmd:r(test_type)}}{cmd:with_drift} or {cmd:no_drift}{p_end}
{synopt:{cmd:r(conclusion)}}{cmd:linear}, {cmd:logarithmic}, {cmd:both}, or {cmd:neither}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:kmtest}{p_end}


{marker methods}{...}
{title:Methods and formulas}

{pstd}
{bf:The Linear Model}

{pstd}
The linear I(1) model is defined as:

{p 8 8 2}
y_t - y_{t-1} = e_t + μ

{pstd}
where e_t follows an AR(p) process: α(L)e_t = ε_t, with α(L) = 1 - α_1L - ... - α_pL^p.

{pstd}
{bf:The Logarithmic Model}

{pstd}
The logarithmic I(1) model is defined as:

{p 8 8 2}
log(y_t) - log(y_{t-1}) = u_t + η

{pstd}
where u_t follows an AR(p) process: β(L)u_t = ζ_t.

{pstd}
{bf:Test Statistics with Drift (V1 and V2)}

{pstd}
Under the linear model, the conditional variance of Δy_t given y_{t-1} is constant.
Under the logarithmic model, it is proportional to y_{t-1}^2. This motivates a test
based on the correlation between y_{t-1} and z_t^2, where z_t are the residuals from
an AR(p) regression on Δy_t.

{pstd}
The V1 statistic testing H0: Linear model is:

{p 8 8 2}
V1 = n^(-3/2) * Σ y_{t-1}(z_t^2 - s^2) / √(s^4 * m^2 / 6)

{pstd}
which is asymptotically N(0,1) under the null.

{pstd}
The V2 statistic testing H0: Logarithmic model is:

{p 8 8 2}
V2 = n^(-3/2) * Σ (-log y_{t-1})(v_t^2 - w^2) / √(w^4 * h^2 / 6)

{pstd}
which is also asymptotically N(0,1) under the null.

{pstd}
{bf:Test Statistics without Drift (U1 and U2)}

{pstd}
When there is no drift, the asymptotic distributions are nonstandard:

{p 8 8 2}
U1 → ∫₀¹ W₁(r)dW₂(r) - ∫₀¹ W₁(r)dr ∫₀¹ dW₂(r)

{p 8 8 2}
U2 → -∫₀¹ W₁(r)dW₂(r) + ∫₀¹ W₁(r)dr ∫₀¹ dW₂(r)

{pstd}
where (W₁, W₂) is a two-dimensional Brownian motion with zero covariance.

{pstd}
{bf:Critical Values for U1 and U2}

{center:{c TLC}{hline 25}{c TRC}}
{center:{c |} Significance   Critical  {c |}}
{center:{c |} Level          Value     {c |}}
{center:{c LT}{hline 25}{c RT}}
{center:{c |} 10%            0.477     {c |}}
{center:{c |} 5%             0.664     {c |}}
{center:{c |} 1%             1.116     {c |}}
{center:{c BLC}{hline 25}{c BRC}}


{marker references}{...}
{title:References}

{phang}
Kobayashi, M. and M. McAleer. 1999. Tests of linear and logarithmic transformations
for integrated processes. {it:Econometric Reviews} 18(2): 187-209.

{phang}
Dickey, D. A. and W. A. Fuller. 1979. Distribution of the estimates for autoregressive
time series with a unit root. {it:Journal of the American Statistical Association}
74(366): 427-431.

{phang}
Granger, C. W. J. and J. Hallman. 1991. Nonlinear transformations of integrated
time series. {it:Journal of Time Series Analysis} 12(3): 207-218.

{phang}
Ermini, L. and D. F. Hendry. 1995. Log income versus linear income: An application
of the encompassing principle. Presented at the 7th World Congress of the
Econometric Society, Tokyo, Japan.


{marker author}{...}
{title:Author}

{pstd}
Dr. Merwan Roudane{break}

{pstd}
Implementation based on Kobayashi & McAleer (1999){break}
Version 1.0.0, January 2026{break}

{pstd}
Please cite as:{break}
Roudane, M. 2026. KMTEST: Stata module for testing linear and logarithmic
transformations of integrated processes.


{title:Also see}

{psee}
Manual: {manlink TS dfuller}, {manlink TS dfgls}, {manlink R boxcox}

{psee}
{space 2}Help: {manhelp dfuller TS}, {manhelp dfgls TS}, {manhelp boxcox R}
{p_end}
