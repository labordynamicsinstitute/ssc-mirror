{smcl}
{* *! version 1.0.0  20may2026  Dr Merwan Roudane (merwanroudane920@gmail.com)}{...}
{vieweralsosee "mixi01" "help mixi01"}{...}
{vieweralsosee "mixi01_fmvar" "help mixi01_fmvar"}{...}
{vieweralsosee "mixi01_fmiv" "help mixi01_fmiv"}{...}
{vieweralsosee "mixi01_acl"  "help mixi01_acl"}{...}
{vieweralsosee "mixi01_svar" "help mixi01_svar"}{...}
{vieweralsosee "mixi01_vecm" "help mixi01_vecm"}{...}
{vieweralsosee "mixi01_irf" "help mixi01_irf"}{...}
{vieweralsosee "mixi01_test" "help mixi01_test"}{...}
{viewerjumpto "Syntax" "mixi01_fmols##syntax"}{...}
{viewerjumpto "Description" "mixi01_fmols##description"}{...}
{viewerjumpto "Options" "mixi01_fmols##options"}{...}
{viewerjumpto "Remarks" "mixi01_fmols##remarks"}{...}
{viewerjumpto "Examples" "mixi01_fmols##examples"}{...}
{viewerjumpto "Stored results" "mixi01_fmols##stored"}{...}
{viewerjumpto "References" "mixi01_fmols##references"}{...}
{viewerjumpto "Author"     "mixi01_fmols##author"}{...}
{viewerjumpto "Also see"   "mixi01_fmols##alsosee"}{...}

{title:Title}

{p2colset 5 24 26 2}{...}
{p2col :{hi:mixi01_fmols} {hline 2}}Fully Modified OLS for mixed I(1)/I(0) regressions{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 20 2}
{cmd:mixi01_fmols} {depvar} {indepvars} {ifin}
[{cmd:,}
{it:options}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Integration classification}
{synopt :{opt i1(varlist)}}variables classified as I(1); default: all {it:indepvars}{p_end}
{synopt :{opt i0(varlist)}}variables classified as I(0){p_end}

{syntab:Long-run covariance estimation}
{synopt :{opt kernel(string)}}kernel function; {cmd:bartlett}, {cmd:parzen},
{cmd:tukeyhanning}, or {cmd:qs} (quadratic spectral); default: {cmd:bartlett}{p_end}
{synopt :{opt bw(#|auto)}}bandwidth (lag truncation) parameter; {cmd:auto}
selects the Andrews (1991) data-driven bandwidth; default: {cmd:auto}{p_end}
{synopt :{opt prewhiten}}apply VAR(1) prewhitening before kernel estimation{p_end}

{syntab:Deterministic components}
{synopt :{opt nocons:tant}}suppress the constant term{p_end}
{synopt :{opt trend}}include a linear time trend{p_end}

{syntab:Reporting}
{synopt :{opt l:evel(#)}}set confidence level; default: {cmd:level(95)}{p_end}
{synopt :{opt detail}}display detailed long-run covariance estimates{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:mixi01_fmols} estimates the regression

{p 8 8 2}
{it:y_t} = {bf:A} {it:x_t} + {it:u}_{it:0t}

{pstd}
using the Fully Modified OLS (FM-OLS) procedure of Phillips and Hansen (1990)
as generalized in Phillips (1995, Sections 3–4) to accommodate regressors
{it:x_t} that may contain both I(1) and I(0) components, possibly with
unknown cointegrating linkages among them.

{pstd}
The FM-OLS estimator modifies ordinary least squares by applying two
semiparametric corrections:

{p 8 12 2}
{bf:Endogeneity correction.}  The dependent variable {it:y_t} is transformed to
{it:y_t}^+ = {it:y_t} − {bf:Omega}_{it:0x} {bf:Omega}_{it:xx}^{−1} Δ{it:x_t}
using kernel estimates of the long-run covariance between the equation error and
the differenced regressors.  This removes second-order bias caused by feedback
from any cointegrating relationship.

{p 8 12 2}
{bf:Serial correlation correction.}  A one-sided long-run covariance term
{bf:Delta}^+_{it:0x} is subtracted to remove the effects of serial covariance
between the equation error and past history of the regressor innovations.

{pstd}
Together these corrections yield the FM-OLS estimator:

{p 8 8 2}
{bf:A}^+ = ({bf:Y}^{+′}{bf:X} − {it:T} {bf:Delta}^+_{it:0x}) ({bf:X′X})^{−1}

{pstd}
{bf:Key result} (Phillips, 1995, Theorem 4.1):

{p 8 12 2}
(a) In the stationary directions (H_1), sqrt({it:T})({bf:A}^+ − {bf:A})
converges to a normal distribution, identical to OLS under correct
specification.

{p 8 12 2}
(b) In the nonstationary directions (H_2), {it:T}({bf:A}^+ − {bf:A})
converges to a mixed-normal (Brownian motion) functional, symmetric and
median-unbiased, free of nuisance parameters.

{pstd}
These results hold {it:without} prior knowledge of which regressors are I(1)
versus I(0), without pretesting, and without knowing the dimension of the
cointegration space among the regressors.  The user may optionally supply
{cmd:i1()} and {cmd:i0()} classifications for sharper inference and for
compatibility with {helpb mixi01_test}, but they are not required for
consistent estimation.


{marker options}{...}
{title:Options}

{dlgtab:Integration classification}

{phang}
{opt i1(varlist)} specifies which independent variables are believed to be
I(1).  If neither {cmd:i1()} nor {cmd:i0()} is specified, all independent
variables are treated as possibly nonstationary and the full FM correction is
applied.  The FM-OLS estimator remains consistent either way (Phillips, 1995,
Remark 4.4(e)), but explicit classification enables sharper Wald tests via
{helpb mixi01_test}.

{phang}
{opt i0(varlist)} specifies which independent variables are believed to be
I(0).

{dlgtab:Long-run covariance estimation}

{phang}
{opt kernel(string)} selects the kernel function used to estimate the long-run
covariance matrix Omega and the one-sided long-run covariance Delta.
Choices are:

{p 12 16 2}
{cmd:bartlett} — the Bartlett (triangular) kernel with truncation at lag K.
This satisfies Assumption KL in Phillips (1995).

{p 12 16 2}
{cmd:parzen} — the Parzen kernel, which is twice continuously differentiable
with characteristic exponent r = 2.

{p 12 16 2}
{cmd:tukeyhanning} — the Tukey–Hanning kernel (cosine window).  Note: this
kernel can produce negative spectral estimates.

{p 12 16 2}
{cmd:qs} — the quadratic spectral (Bartlett–Priestley) kernel of Priestley
(1981, p. 463), which is non-truncated and positive semidefinite.

{phang}
{opt bw(#|auto)} sets the bandwidth parameter {it:K} in the kernel estimates.
Under the theory of Phillips (1995, Assumption BW), {it:K} should grow at rate
{it:T}^k for k in (1/4, 2/3).  If {cmd:auto} is specified, the Andrews (1991)
plug-in procedure is used to choose {it:K} automatically.

{phang}
{opt prewhiten} applies a VAR(1) filter to the residual vector before kernel
estimation, recoloring afterwards.  This often improves finite-sample
performance of the long-run covariance estimates.

{dlgtab:Deterministic components}

{phang}
{opt noconstant} suppresses the constant from the regression equation.

{phang}
{opt trend} includes a linear time trend among the regressors. See Phillips
(1995, Section 4.7) for the extension to models with deterministic regressors.

{dlgtab:Reporting}

{phang}
{opt level(#)} sets the confidence level for reported confidence intervals.

{phang}
{opt detail} displays the estimated long-run covariance matrix Omega_hat,
the one-sided covariance Delta_hat, and the correction terms.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:I(1) versus I(0) classification.} A central message of Phillips (1995)
is that the researcher need not know the integration properties of the
regressors in advance.  The FM corrections are applied as if all regressors
were I(1); for any I(0) components, the corrections are asymptotically
negligible.  Hence {cmd:mixi01_fmols} produces valid estimates and standard
errors whether the user's classification is right, wrong, or simply omitted.

{pstd}
{bf:Bandwidth choice.}  Under Assumption BW(i), the bandwidth K must satisfy
K = O_e(T^k) for k in (1/4, 2/3).  The Andrews (1991) rule typically
produces bandwidths in this range for moderate to large T.  For small
samples, manual specification via {cmd:bw(#)} is recommended.

{pstd}
{bf:Wald tests.}  After {cmd:mixi01_fmols}, use {helpb mixi01_test} to
perform Wald tests.  By Theorem 4.5, the Wald statistic has a limit
distribution that is a mixture of chi-squared variates, bounded above by
chi-squared(q).  The conservative test uses chi-squared(q) critical values;
the liberal test uses {it:Omega_00.2} in the variance metric (Remark 4.6(b)).


{marker examples}{...}
{title:Examples}

{dlgtab:Example 1: Basic FM-OLS with automatic bandwidth}

{pstd}Setup: regress log GDP on log investment (I(1)) and interest rate (I(0)).{p_end}

{phang2}{cmd:. webuse lutkepohl2, clear}{p_end}
{phang2}{cmd:. tsset qtr}{p_end}
{phang2}{cmd:. mixi01_fmols ln_consump ln_inv ln_inc, i1(ln_inv ln_inc) kernel(bartlett) bw(auto)}{p_end}

{dlgtab:Example 2: Mixed I(1)/I(0) with explicit classification}

{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. * Simulated time series example:}{p_end}
{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. set obs 200}{p_end}
{phang2}{cmd:. set seed 12345}{p_end}
{phang2}{cmd:. gen t = _n}{p_end}
{phang2}{cmd:. tsset t}{p_end}
{phang2}{cmd:. gen e1 = rnormal()}{p_end}
{phang2}{cmd:. gen e2 = rnormal()}{p_end}
{phang2}{cmd:. gen e3 = rnormal()}{p_end}
{phang2}{cmd:. gen x1 = sum(e1)}{p_end}
{phang2}{cmd:. gen x2 = sum(e2)}{p_end}
{phang2}{cmd:. gen x3 = 0.8*L.x3 + e3 if t>1}{p_end}
{phang2}{cmd:. replace x3 = e3 if t==1}{p_end}
{phang2}{cmd:. gen y = 2*x1 + 1.5*x2 + 0.5*x3 + rnormal()}{p_end}
{phang2}{cmd:. mixi01_fmols y x1 x2 x3, i1(x1 x2) i0(x3) kernel(parzen) bw(6)}{p_end}

{dlgtab:Example 3: With time trend and prewhitening}

{phang2}{cmd:. mixi01_fmols y x1 x2 x3, i1(x1 x2) i0(x3) trend prewhiten kernel(qs) bw(auto) detail}{p_end}

{dlgtab:Example 4: Followed by Wald test}

{phang2}{cmd:. mixi01_fmols y x1 x2 x3, i1(x1 x2) i0(x3)}{p_end}
{phang2}{cmd:. mixi01_test, wald("x2=0, x3=0") conservative}{p_end}


{marker stored}{...}
{title:Stored results}

{pstd}
{cmd:mixi01_fmols} stores the following in {cmd:e()}:

{synoptset 24 tabbed}{...}
{p2col 5 24 28 2: Scalars}{p_end}
{synopt :{cmd:e(N)}}number of observations{p_end}
{synopt :{cmd:e(k)}}number of regressors (including constant/trend){p_end}
{synopt :{cmd:e(k_i1)}}number of I(1) regressors{p_end}
{synopt :{cmd:e(k_i0)}}number of I(0) regressors{p_end}
{synopt :{cmd:e(bw)}}bandwidth (lag truncation) used{p_end}
{synopt :{cmd:e(rank)}}rank of long-run covariance Omega_xx{p_end}
{synopt :{cmd:e(ll)}}log-likelihood (under Gaussian errors){p_end}
{synopt :{cmd:e(rss)}}residual sum of squares (from FM regression){p_end}

{p2col 5 24 28 2: Macros}{p_end}
{synopt :{cmd:e(cmd)}}{cmd:mixi01_fmols}{p_end}
{synopt :{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt :{cmd:e(indepvars)}}names of independent variables{p_end}
{synopt :{cmd:e(i1vars)}}names of I(1) variables{p_end}
{synopt :{cmd:e(i0vars)}}names of I(0) variables{p_end}
{synopt :{cmd:e(kernel)}}kernel function used{p_end}
{synopt :{cmd:e(properties)}}{cmd:b V}{p_end}

{p2col 5 24 28 2: Matrices}{p_end}
{synopt :{cmd:e(b)}}1 × k coefficient vector{p_end}
{synopt :{cmd:e(V)}}k × k variance–covariance matrix (using Sigma_00 metric){p_end}
{synopt :{cmd:e(V_liberal)}}k × k variance–covariance matrix (using Omega_00.2 metric){p_end}
{synopt :{cmd:e(Omega)}}(n+m) × (n+m) long-run covariance matrix{p_end}
{synopt :{cmd:e(Delta)}}one-sided long-run covariance matrix{p_end}
{synopt :{cmd:e(Sigma_uu)}}error covariance matrix Sigma_00{p_end}
{synopt :{cmd:e(Omega_002)}}conditional long-run variance Omega_{00.2}{p_end}
{synopt :{cmd:e(b_ols)}}OLS coefficient vector (for comparison){p_end}

{p2col 5 24 28 2: Functions}{p_end}
{synopt :{cmd:e(sample)}}marks estimation sample{p_end}


{marker references}{...}
{title:References}

{phang}
Andrews, D. W. K. (1991).  Heteroskedasticity and autocorrelation consistent
covariance matrix estimation.  {it:Econometrica}, 59(3), 817–858.
{p_end}

{phang}
Phillips, P. C. B. (1995).  Fully modified least squares and vector
autoregression.  {it:Econometrica}, 63(5), 1023–1078.
{p_end}

{phang}
Phillips, P. C. B. and B. E. Hansen (1990).  Statistical inference in
instrumental variables regression with I(1) processes.
{it:Review of Economic Studies}, 57(1), 99–125.
{p_end}

{phang}
Priestley, M. B. (1981).  {it:Spectral Analysis and Time Series}.
London: Academic Press.
{p_end}


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
Department of Economics (Independent Researcher){break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}
{p_end}


{marker alsosee}{...}
{title:Also see}

{pstd}
Master help — {helpb mixi01}.
{p_end}

{pstd}
Sibling commands — {helpb mixi01_fmols}, {helpb mixi01_fmvar},
{helpb mixi01_fmiv}, {helpb mixi01_acl}, {helpb mixi01_svar},
{helpb mixi01_vecm}, {helpb mixi01_irf}, {helpb mixi01_test}.
{p_end}
