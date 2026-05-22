{smcl}
{* *! version 1.0.0  20may2026  Dr Merwan Roudane (merwanroudane920@gmail.com)}{...}
{vieweralsosee "mixi01" "help mixi01"}{...}
{vieweralsosee "mixi01_fmols" "help mixi01_fmols"}{...}
{vieweralsosee "mixi01_fmvar" "help mixi01_fmvar"}{...}
{vieweralsosee "mixi01_svar" "help mixi01_svar"}{...}
{vieweralsosee "mixi01_vecm" "help mixi01_vecm"}{...}
{vieweralsosee "mixi01_irf" "help mixi01_irf"}{...}
{vieweralsosee "mixi01_test" "help mixi01_test"}{...}
{viewerjumpto "Syntax" "mixi01_fmiv##syntax"}{...}
{viewerjumpto "Description" "mixi01_fmiv##description"}{...}
{viewerjumpto "Options" "mixi01_fmiv##options"}{...}
{viewerjumpto "Remarks" "mixi01_fmiv##remarks"}{...}
{viewerjumpto "Examples" "mixi01_fmiv##examples"}{...}
{viewerjumpto "Stored results" "mixi01_fmiv##stored"}{...}
{viewerjumpto "References" "mixi01_fmiv##references"}{...}
{viewerjumpto "Author"     "mixi01_fmiv##author"}{...}
{viewerjumpto "Also see"   "mixi01_fmiv##alsosee"}{...}

{title:Title}

{p2colset 5 24 26 2}{...}
{p2col :{hi:mixi01_fmiv} {hline 2}}Fully Modified IV, GIVE, and GMM estimation{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 20 2}
{cmd:mixi01_fmiv} {depvar} {indepvars} {ifin}
[{cmd:,}
{it:options}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model specification}
{synopt :{opt iv(varlist)}}instrumental variables{p_end}
{synopt :{opt i1(varlist)}}I(1) regressors and instruments{p_end}
{synopt :{opt i0(varlist)}}I(0) regressors and instruments{p_end}

{syntab:Estimation method}
{synopt :{opt method(string)}}{cmd:iv} (FM-IV), {cmd:give} (FM-GIVE), or
{cmd:gmm} (FM-GMM); default: {cmd:iv}{p_end}

{syntab:Long-run covariance estimation}
{synopt :{opt kernel(string)}}kernel function; default: {cmd:bartlett}{p_end}
{synopt :{opt bw(#|auto)}}bandwidth; default: {cmd:auto}{p_end}
{synopt :{opt prewhiten}}apply VAR(1) prewhitening{p_end}

{syntab:GMM options}
{synopt :{opt wmatrix(string)}}weight matrix for GMM: {cmd:unadjusted},
{cmd:robust}, {cmd:hac}; default: {cmd:hac}{p_end}
{synopt :{opt iterate(#)}}maximum number of GMM iterations; default: {cmd:2}{p_end}

{syntab:Sargan test}
{synopt :{opt sargan}}perform FM-Sargan test for instrument validity{p_end}

{syntab:Deterministic components}
{synopt :{opt nocons:tant}}suppress constant{p_end}
{synopt :{opt trend}}include time trend{p_end}

{syntab:Reporting}
{synopt :{opt l:evel(#)}}confidence level; default: {cmd:level(95)}{p_end}
{synopt :{opt first}}display first-stage regression results{p_end}
{synopt :{opt detail}}display long-run covariance estimates{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:mixi01_fmiv} estimates the regression

{p 8 8 2}
{it:y_t} = {bf:A} {it:x_t} + {it:u}_{it:0t}

{pstd}
using FM-IV, FM-GIVE, or FM-GMM estimation as developed in Kitamura and
Phillips (1997).  The regressors {it:x_t} may be endogenous and may contain
both I(1) and I(0) components with unknown cointegrating linkages.  The
instruments {it:z_t} may also be a mixture of I(1) and I(0) processes, possibly
cointegrated with the regressors.

{pstd}
The FM-IV estimator (equation (10) in Kitamura and Phillips) takes the form:

{p 8 8 2}
A_tilde = (Y^{+′} P_Z X − T Delta^+_0z (Z'Z)^{−1} Z'X) (X' P_Z X)^{−1}

{pstd}
where P_Z = Z(Z'Z)^{−1}Z' and the FM corrections adjust for endogeneity and
serial correlation using the "a" subscript convention (Kitamura and Phillips,
Table 1).

{pstd}
{bf:FM-GIVE} (Section 5.2 of KP97) applies a GLS-type transformation using the
spectral density of u_{0t} ⊗ z_{1t} at frequency zero to achieve efficiency
gains for the stationary components while maintaining optimal estimation of
the nonstationary components.

{pstd}
{bf:FM-GMM} (Section 5.1 of KP97) uses an optimal distance matrix S_{zT} in a
linear GMM framework extended to allow for nonstationary regressors and
instruments.

{pstd}
Key result (Theorem 4.3, KP97): Under Assumptions EC, IV and LR,

{p 8 12 2}
(a) sqrt(T)(A_tilde − A)H_1 →_d N(0, J_{z1} S_{z1} J'_{z1}) — normal for
the stationary components.

{p 8 12 2}
(b) T(A_tilde − A)H_2 →_d MN(0, Omega_{00.b} ⊗ (integral B_2 B_2')^{−1})
— mixed normal for the nonstationary components.


{marker options}{...}
{title:Options}

{dlgtab:Model specification}

{phang}
{opt iv(varlist)} specifies the instrumental variables z_t.  The instrument
set should include q >= m variables, where m is the number of regressors.
Both I(1) and I(0) instruments are allowed.

{phang}
{opt i1(varlist)} specifies which regressors and instruments are I(1).

{phang}
{opt i0(varlist)} specifies which regressors and instruments are I(0).

{dlgtab:Estimation method}

{phang}
{opt method(iv)} uses FM-IV (default).  This applies FM corrections to
standard IV, providing consistency and median-unbiased estimation for both
stationary and nonstationary components.

{phang}
{opt method(give)} uses FM-GIVE.  This applies a GLS-type transformation to
achieve asymptotically efficient estimation of the stationary coefficients
(when instruments are strictly exogenous).  The limit theory for the
nonstationary components is unchanged.

{phang}
{opt method(gmm)} uses FM-GMM with an optimal distance matrix.  Under the
Assumption NF (no feedback from errors to stationary instruments), FM-GMM
achieves the same efficiency as GIVE for the stationary components.

{dlgtab:Sargan test}

{phang}
{opt sargan} performs the FM-Sargan test for over-identifying restrictions
(Section 6 of KP97).  The test statistic is asymptotically chi-squared(q−m)
under the null of valid instruments.

{dlgtab:GMM options}

{phang}
{opt wmatrix(string)} specifies the initial weight matrix for iterative GMM.

{phang}
{opt iterate(#)} sets the maximum number of GMM iterations.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:Cointegrated instruments.}  Kitamura and Phillips (Section 4.2) show that
when the I(1) instruments and regressors are cointegrated — as arises naturally
when lagged regressors serve as instruments — the FM-IV estimator remains
valid with only minor changes to the limit theory (subscripts "b" replaced
by "c2").

{pstd}
{bf:Assumption NF (No Feedback).}  For FM-GMM and FM-GIVE efficiency, one
needs E[u_{0,s+j} ⊗ z_{1t}] = 0 for j >= 1.  This is automatic when
instruments are strictly exogenous or when the orthogonality arises from
rational expectations.

{pstd}
{bf:FM-Sargan test.}  The FM version of the Sargan test adjusts for the
presence of nonstationary instruments by using FM residuals in place of
standard IV residuals.  The resulting test is asymptotically chi-squared
under the null.


{marker examples}{...}
{title:Examples}

{dlgtab:Example 1: Basic FM-IV}

{phang2}{cmd:. mixi01_fmiv y x1 x2, iv(z1 z2 z3) i1(x1 z1 z2) i0(x2 z3) method(iv)}{p_end}

{dlgtab:Example 2: FM-GMM with Sargan test}

{phang2}{cmd:. mixi01_fmiv y x1 x2 x3, iv(z1 z2 z3 z4 z5) method(gmm) sargan kernel(qs) bw(auto)}{p_end}

{dlgtab:Example 3: FM-GIVE with first-stage output}

{phang2}{cmd:. mixi01_fmiv y x1 x2, iv(z1 z2 z3) i1(x1 z1 z2) i0(x2 z3) method(give) first}{p_end}


{marker stored}{...}
{title:Stored results}

{pstd}
{cmd:mixi01_fmiv} stores the following in {cmd:e()}:

{synoptset 28 tabbed}{...}
{p2col 5 28 32 2: Scalars}{p_end}
{synopt :{cmd:e(N)}}number of observations{p_end}
{synopt :{cmd:e(k)}}number of regressors{p_end}
{synopt :{cmd:e(k_iv)}}number of instruments{p_end}
{synopt :{cmd:e(k_i1)}}number of I(1) regressors/instruments{p_end}
{synopt :{cmd:e(k_i0)}}number of I(0) regressors/instruments{p_end}
{synopt :{cmd:e(bw)}}bandwidth used{p_end}
{synopt :{cmd:e(sargan)}}FM-Sargan test statistic (if {cmd:sargan}){p_end}
{synopt :{cmd:e(sargan_p)}}p-value for FM-Sargan test{p_end}
{synopt :{cmd:e(sargan_df)}}degrees of freedom for FM-Sargan test{p_end}

{p2col 5 28 32 2: Macros}{p_end}
{synopt :{cmd:e(cmd)}}{cmd:mixi01_fmiv}{p_end}
{synopt :{cmd:e(depvar)}}dependent variable name{p_end}
{synopt :{cmd:e(indepvars)}}regressor names{p_end}
{synopt :{cmd:e(instruments)}}instrument names{p_end}
{synopt :{cmd:e(method)}}{cmd:iv}, {cmd:give}, or {cmd:gmm}{p_end}
{synopt :{cmd:e(kernel)}}kernel function{p_end}

{p2col 5 28 32 2: Matrices}{p_end}
{synopt :{cmd:e(b)}}coefficient vector{p_end}
{synopt :{cmd:e(V)}}variance–covariance matrix{p_end}
{synopt :{cmd:e(Omega)}}long-run covariance matrix{p_end}
{synopt :{cmd:e(Delta)}}one-sided long-run covariance{p_end}
{synopt :{cmd:e(Sigma_uu)}}error covariance Sigma_00{p_end}
{synopt :{cmd:e(Omega_002)}}conditional long-run variance Omega_{00.2}{p_end}
{synopt :{cmd:e(S_z)}}distance matrix for GMM (if {cmd:method(gmm)}){p_end}
{synopt :{cmd:e(first_F)}}first-stage F statistics (if {cmd:first}){p_end}

{p2col 5 28 32 2: Functions}{p_end}
{synopt :{cmd:e(sample)}}marks estimation sample{p_end}


{marker references}{...}
{title:References}

{phang}
Hansen, L. P. (1982).  Large sample properties of generalized method of
moments estimators.  {it:Econometrica}, 50(4), 1029–1054.
{p_end}

{phang}
Kitamura, Y. and P. C. B. Phillips (1997).  Fully modified IV, GIVE and GMM
estimation with possibly non-stationary regressors and instruments.
{it:Journal of Econometrics}, 80(1), 85–123.
{p_end}

{phang}
Phillips, P. C. B. and B. E. Hansen (1990).  Statistical inference in
instrumental variables regression with I(1) processes.
{it:Review of Economic Studies}, 57(1), 99–125.
{p_end}

{phang}
Sargan, J. D. (1958).  The estimation of economic relationships using
instrumental variables.  {it:Econometrica}, 26(3), 393–415.
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
