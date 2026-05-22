{smcl}
{* *! version 1.0.0  20may2026  Dr Merwan Roudane (merwanroudane920@gmail.com)}{...}
{vieweralsosee "mixi01" "help mixi01"}{...}
{vieweralsosee "mixi01_fmols" "help mixi01_fmols"}{...}
{vieweralsosee "mixi01_fmiv" "help mixi01_fmiv"}{...}
{vieweralsosee "mixi01_acl"  "help mixi01_acl"}{...}
{vieweralsosee "mixi01_svar" "help mixi01_svar"}{...}
{vieweralsosee "mixi01_vecm" "help mixi01_vecm"}{...}
{vieweralsosee "mixi01_irf" "help mixi01_irf"}{...}
{vieweralsosee "mixi01_test" "help mixi01_test"}{...}
{viewerjumpto "Syntax" "mixi01_fmvar##syntax"}{...}
{viewerjumpto "Description" "mixi01_fmvar##description"}{...}
{viewerjumpto "Options" "mixi01_fmvar##options"}{...}
{viewerjumpto "Remarks" "mixi01_fmvar##remarks"}{...}
{viewerjumpto "Examples" "mixi01_fmvar##examples"}{...}
{viewerjumpto "Stored results" "mixi01_fmvar##stored"}{...}
{viewerjumpto "References" "mixi01_fmvar##references"}{...}
{viewerjumpto "Author"     "mixi01_fmvar##author"}{...}
{viewerjumpto "Also see"   "mixi01_fmvar##alsosee"}{...}

{title:Title}

{p2colset 5 24 26 2}{...}
{p2col :{hi:mixi01_fmvar} {hline 2}}Fully Modified Vector Autoregression{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 20 2}
{cmd:mixi01_fmvar} {varlist} {ifin}
[{cmd:,}
{it:options}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model specification}
{synopt :{opt lags(#)}}number of lags in the VAR; default: {cmd:lags(2)}{p_end}
{synopt :{opt i1(varlist)}}variables classified as I(1){p_end}
{synopt :{opt i0(varlist)}}variables classified as I(0){p_end}

{syntab:Long-run covariance estimation}
{synopt :{opt kernel(string)}}kernel function; default: {cmd:bartlett}{p_end}
{synopt :{opt bw(#|auto)}}bandwidth parameter; default: {cmd:auto}{p_end}
{synopt :{opt prewhiten}}apply VAR(1) prewhitening{p_end}

{syntab:Deterministic components}
{synopt :{opt nocons:tant}}suppress the constant term{p_end}
{synopt :{opt trend}}include a linear time trend{p_end}

{syntab:Reporting}
{synopt :{opt l:evel(#)}}confidence level; default: {cmd:level(95)}{p_end}
{synopt :{opt detail}}display long-run covariance estimates{p_end}
{synopt :{opt compact}}display only the companion matrix{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:mixi01_fmvar} estimates an unrestricted levels VAR of the form

{p 8 8 2}
{it:y_t} = {bf:A}_1 {it:y}_{it:t−1} + ... + {bf:A}_p {it:y}_{it:t−p} + {it:e_t}

{pstd}
using Fully Modified VAR (FM-VAR) estimation as developed in
Phillips (1995, Section 5).  The method applies the FM corrections
equation-by-equation, treating each equation as an FM-OLS regression of
one element of {it:y_t} on the lagged vector {it:y}_{it:t−1}, ..., {it:y}_{it:t−p}.

{pstd}
The FM-VAR estimator has several remarkable properties (Phillips, 1995):

{p 8 12 2}
{bf:(i)} When there is cointegration in the system, the FM-VAR limit theory is
{it:normal} for all stationary coefficients and {it:mixed normal} for all
nonstationary coefficients.  There are {it:no unit-root distributions}, even
for the coefficient submatrix corresponding to the unit roots (I_{n−r}).

{p 8 12 2}
{bf:(ii)} When the system has a full set of unit roots (no cointegration), the
FM-VAR estimator of the unit-root matrix is {it:hyperconsistent} at a rate
exceeding O(T).

{p 8 12 2}
{bf:(iii)} Optimal estimation of the cointegration space is attained by FM-VAR
{it:without} knowledge of the number of unit roots, without pretesting, and
without reduced-rank regression.

{p 8 12 2}
{bf:(iv)} Wald tests based on the FM-VAR estimator have a limit distribution
that is a mixture of chi-squared variates bounded above by chi-squared(q),
enabling valid Granger causality tests regardless of the integration properties.


{marker options}{...}
{title:Options}

{dlgtab:Model specification}

{phang}
{opt lags(#)} specifies the number of lags to include in the VAR.  Default
is 2.  Information criteria (AIC, BIC) are reported to guide selection.

{phang}
{opt i1(varlist)} specifies variables believed to be I(1).  If omitted, all
variables are treated as potentially nonstationary and the full FM correction
is applied.

{phang}
{opt i0(varlist)} specifies variables believed to be I(0).

{dlgtab:Long-run covariance estimation}

{phang}
{opt kernel(string)} selects the kernel function.  See {helpb mixi01_fmols}
for available kernels.

{phang}
{opt bw(#|auto)} sets the bandwidth.

{phang}
{opt prewhiten} applies VAR(1) prewhitening.

{dlgtab:Deterministic components}

{phang}
{opt noconstant} suppresses the constant in each VAR equation.

{phang}
{opt trend} includes a linear time trend.

{dlgtab:Reporting}

{phang}
{opt level(#)} sets the confidence level.

{phang}
{opt detail} displays the estimated long-run covariance matrices.

{phang}
{opt compact} displays only the companion-form coefficient matrix rather
than the full equation-by-equation output.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:Levels versus differences.}  A key advantage of FM-VAR is that the
researcher can estimate the VAR in levels without differencing any variables,
regardless of the integration properties.  Unlike OLS on levels VARs, the
FM corrections remove the second-order bias (endogeneity of nonstationary
regressors) identified in Phillips (1991a).

{pstd}
{bf:Causality testing.}  After FM-VAR estimation, Granger causality tests can
be conducted using {helpb mixi01_test}.  By Theorem 6.1, the Wald statistic
W^+ for testing exclusion restrictions on blocks of F coefficients has a limit
distribution

{p 8 8 2}
W^+ →_d  chi2(q_1) + sum_{j=1}^{q_1} d_j * chi2_{q_{22}}(j)

{pstd}
where d_j in (0,1) are eigenvalues of (R_1 Omega_{00.2} R_1')(R_1 Sigma_{00} R_1')^{−1}.
This is bounded above by chi2(q), so conventional chi-squared critical values
always yield valid (conservative) tests.

{pstd}
{bf:Comparison with Toda–Yamamoto.}  FM-VAR Granger causality avoids the need
for the intentional over-fitting approach of Toda and Yamamoto (1993), which
adds extra lags to ensure valid chi-squared asymptotics.  FM-VAR achieves the
same (and better) with the lag order chosen by information criteria.


{marker examples}{...}
{title:Examples}

{dlgtab:Example 1: Three-variable FM-VAR}

{phang2}{cmd:. webuse lutkepohl2, clear}{p_end}
{phang2}{cmd:. tsset qtr}{p_end}
{phang2}{cmd:. mixi01_fmvar ln_inv ln_inc ln_consump, lags(2) kernel(bartlett) bw(auto)}{p_end}

{dlgtab:Example 2: Mixed system with I(0) variable}

{phang2}{cmd:. * Using simulated data with interest rate as I(0):}{p_end}
{phang2}{cmd:. mixi01_fmvar gdp cpi irate, lags(4) i1(gdp cpi) i0(irate) kernel(parzen) bw(8)}{p_end}

{dlgtab:Example 3: FM-VAR followed by Granger causality}

{phang2}{cmd:. mixi01_fmvar y1 y2 y3, lags(2) i0(y3)}{p_end}
{phang2}{cmd:. mixi01_test, granger(y2) conservative}{p_end}


{marker stored}{...}
{title:Stored results}

{pstd}
{cmd:mixi01_fmvar} stores the following in {cmd:e()}:

{synoptset 24 tabbed}{...}
{p2col 5 24 28 2: Scalars}{p_end}
{synopt :{cmd:e(N)}}number of observations{p_end}
{synopt :{cmd:e(k_eq)}}number of equations{p_end}
{synopt :{cmd:e(lags)}}number of lags{p_end}
{synopt :{cmd:e(k_i1)}}number of I(1) variables{p_end}
{synopt :{cmd:e(k_i0)}}number of I(0) variables{p_end}
{synopt :{cmd:e(bw)}}bandwidth used{p_end}
{synopt :{cmd:e(aic)}}Akaike information criterion{p_end}
{synopt :{cmd:e(bic)}}Bayesian information criterion{p_end}
{synopt :{cmd:e(hqic)}}Hannan–Quinn information criterion{p_end}

{p2col 5 24 28 2: Macros}{p_end}
{synopt :{cmd:e(cmd)}}{cmd:mixi01_fmvar}{p_end}
{synopt :{cmd:e(depvar)}}list of endogenous variables{p_end}
{synopt :{cmd:e(i1vars)}}I(1) variables{p_end}
{synopt :{cmd:e(i0vars)}}I(0) variables{p_end}
{synopt :{cmd:e(kernel)}}kernel function used{p_end}

{p2col 5 24 28 2: Matrices}{p_end}
{synopt :{cmd:e(b)}}1 × (n^2 p + n) stacked coefficient vector{p_end}
{synopt :{cmd:e(V)}}variance–covariance matrix (Sigma_ee metric){p_end}
{synopt :{cmd:e(V_liberal)}}variance–covariance matrix (Omega_ee.2 metric){p_end}
{synopt :{cmd:e(F)}}n × (n p) stacked coefficient matrices [A_1 ... A_p]{p_end}
{synopt :{cmd:e(Companion)}}(np) × (np) companion matrix{p_end}
{synopt :{cmd:e(Sigma)}}n × n error covariance matrix{p_end}
{synopt :{cmd:e(Omega)}}long-run covariance matrix{p_end}
{synopt :{cmd:e(Delta)}}one-sided long-run covariance{p_end}
{synopt :{cmd:e(eigenvalues)}}eigenvalues of the companion matrix{p_end}

{p2col 5 24 28 2: Functions}{p_end}
{synopt :{cmd:e(sample)}}marks estimation sample{p_end}


{marker references}{...}
{title:References}

{phang}
Phillips, P. C. B. (1991a).  Optimal inference in cointegrated systems.
{it:Econometrica}, 59(2), 283–306.
{p_end}

{phang}
Phillips, P. C. B. (1995).  Fully modified least squares and vector
autoregression.  {it:Econometrica}, 63(5), 1023–1078.
{p_end}

{phang}
Toda, H. Y. and T. Yamamoto (1995).  Statistical inference in vector
autoregressions with possibly integrated processes.
{it:Journal of Econometrics}, 66(1–2), 225–250.
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
