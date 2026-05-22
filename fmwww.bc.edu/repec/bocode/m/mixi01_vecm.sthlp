{smcl}
{* *! version 1.0.0  20may2026  Dr Merwan Roudane (merwanroudane920@gmail.com)}{...}
{vieweralsosee "mixi01" "help mixi01"}{...}
{vieweralsosee "mixi01_fmols" "help mixi01_fmols"}{...}
{vieweralsosee "mixi01_fmvar" "help mixi01_fmvar"}{...}
{vieweralsosee "mixi01_fmiv" "help mixi01_fmiv"}{...}
{vieweralsosee "mixi01_acl"  "help mixi01_acl"}{...}
{vieweralsosee "mixi01_svar" "help mixi01_svar"}{...}
{vieweralsosee "mixi01_irf" "help mixi01_irf"}{...}
{vieweralsosee "mixi01_test" "help mixi01_test"}{...}
{viewerjumpto "Syntax" "mixi01_vecm##syntax"}{...}
{viewerjumpto "Description" "mixi01_vecm##description"}{...}
{viewerjumpto "Options" "mixi01_vecm##options"}{...}
{viewerjumpto "Remarks" "mixi01_vecm##remarks"}{...}
{viewerjumpto "Examples" "mixi01_vecm##examples"}{...}
{viewerjumpto "Stored results" "mixi01_vecm##stored"}{...}
{viewerjumpto "References" "mixi01_vecm##references"}{...}
{viewerjumpto "Author"     "mixi01_vecm##author"}{...}
{viewerjumpto "Also see"   "mixi01_vecm##alsosee"}{...}

{title:Title}

{p2colset 5 24 26 2}{...}
{p2col :{hi:mixi01_vecm} {hline 2}}Mixed VECM for systems with I(1) and I(0) variables{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 20 2}
{cmd:mixi01_vecm} {varlist} {ifin}
[{cmd:,}
{it:options}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model specification}
{synopt :{opt lags(#)}}number of lags in the underlying VAR; default: {cmd:lags(2)}{p_end}
{synopt :{opt rank(#)}}cointegration rank among I(1) variables; default: determined by Johansen test{p_end}
{synopt :{opt i1(varlist)}}variables classified as I(1){p_end}
{synopt :{opt i0(varlist)}}variables classified as I(0){p_end}

{syntab:Deterministic components}
{synopt :{opt nocons:tant}}suppress constant{p_end}
{synopt :{opt trend}}include restricted trend in cointegrating relations{p_end}
{synopt :{opt utrend}}include unrestricted trend{p_end}

{syntab:Testing}
{synopt :{opt trace}}report Johansen trace test for mixed system{p_end}
{synopt :{opt maxeigen}}report maximum eigenvalue test{p_end}
{synopt :{opt testi0}}test for the presence of I(0) components (B31=0 restriction){p_end}

{syntab:Reporting}
{synopt :{opt l:evel(#)}}confidence level; default: {cmd:level(95)}{p_end}
{synopt :{opt alpha}}display loading (adjustment) matrix{p_end}
{synopt :{opt beta}}display cointegrating vectors{p_end}
{synopt :{opt detail}}display full model matrices{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:mixi01_vecm} estimates a vector error-correction model for a system
containing both I(1) and I(0) variables, following the methodology of Chen
(2022).

{pstd}
The standard VECM:

{p 8 8 2}
Delta Y_t = alpha beta' Y_{t−1} + sum_{l=1}^{p−1} Pi_l Delta Y_{t−l} + U_t

{pstd}
requires that all components of Y_t are I(1).  When some components are I(0),
the model must be reformulated.  Chen (2022) shows that a VECM with k
I(0) components among n variables is equivalent to a standard VECM with
additional "pseudo" cointegrating vectors.

{pstd}
{bf:Key idea (Lemma 2.5, Chen 2022):}  The condition B31 = 0 in the
transformation matrix B between the observed variables Y_t and the underlying
process (Delta Z_t, X_t)' is both necessary and sufficient for k components
of Y_t to be I(0).  This condition translates into testable restrictions on
the cointegration space.

{pstd}
Specifically, if Y_t contains r true cointegrating relations among the
n_1 = n − k I(1) variables, plus k pseudo cointegrating relations from the
I(0) variables, the total cointegration rank for the Johansen procedure is
h = r + k.  The pseudo cointegrating vectors take the form:

{p 8 8 2}
beta_tilde = (beta_1', 0 \ beta_2', 0 \ 0, I_k)

{pstd}
where beta_1 and beta_2 are the true cointegrating coefficients among
the I(1) variables, and I_k is the identity identifying the I(0)
variables as "cointegrating with themselves."


{marker options}{...}
{title:Options}

{dlgtab:Model specification}

{phang}
{opt lags(#)} specifies the lag order of the underlying VAR in levels.  The
VECM has p−1 lags of Delta Y_t.

{phang}
{opt rank(#)} specifies the true cointegration rank r among the I(1)
variables.  The total rank used in estimation is r + k, where k is the number
of I(0) variables.  If omitted, the Johansen trace test is used to determine r.

{phang}
{opt i1(varlist)} specifies I(1) variables.

{phang}
{opt i0(varlist)} specifies I(0) variables.  Each variable listed here
contributes one pseudo cointegrating vector.

{dlgtab:Testing}

{phang}
{opt trace} displays the Johansen trace test adapted for the mixed system.
The total number of cointegrating relations being tested is r + k.

{phang}
{opt maxeigen} displays the maximum eigenvalue test.

{phang}
{opt testi0} tests the restriction B31 = 0 from Lemma 2.5 of Chen (2022).
This is a likelihood-ratio test for the presence of I(0) components in the
system.  Under the null that all variables are I(1), the I(0) restriction
is not binding.

{dlgtab:Reporting}

{phang}
{opt alpha} displays the (n × h) loading matrix alpha_tilde, partitioned
into loadings on true and pseudo cointegrating relations.

{phang}
{opt beta} displays the (n × h) cointegrating matrix beta_tilde.

{phang}
{opt detail} displays the full VECM matrices including the short-run
dynamics Pi_l.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:Connection to underlying VAR.}  Chen (2022, Lemma 2.4) establishes that
any cointegrated VECM has an "underlying process" (Delta Z_t, X_t)' that is a
stationary VAR.  Conversely, any stationary VAR with r components designated
as Delta Z_t and h = n − r components as X_t generates a VECM with r unit
roots and h cointegrating relations through the transformation Y_t = B (Z_t', X_t')'.

{pstd}
When B31 = 0, the last k components of Y_t depend only on X_t (the stationary
part), making them I(0).  This provides the constructive principle for
building mixed VECMs.

{pstd}
{bf:Estimation.}  The Johansen ML procedure is applied to the full system
with total cointegration rank h = r + k.  The I(0) variables contribute
pseudo cointegrating vectors with known structure (identity on the I(0)
variable, zero elsewhere).  These known vectors can be imposed as restrictions
in the beta matrix during estimation.

{pstd}
{bf:Testing for I(0) components.}  The {opt testi0} option implements
a likelihood-ratio test comparing:

{p 8 12 2}
H0: All n variables are I(1) with cointegration rank h.{break}
H1: k variables are I(0), with cointegration rank r among the remaining
I(1) variables and total rank r + k.

{pstd}
The test statistic is asymptotically chi-squared under H0.


{marker examples}{...}
{title:Examples}

{dlgtab:Example 1: Hamilton (1994)-style system}

{pstd}System with 3 I(1) variables (one cointegrating relation) and 1 I(0) variable.{p_end}

{phang2}{cmd:. mixi01_vecm y1 y2 y3 y4, lags(2) i1(y1 y2 y3) i0(y4) rank(1) trace}{p_end}

{dlgtab:Example 2: Automatic rank determination}

{phang2}{cmd:. mixi01_vecm gdp cpi m2 irate, lags(4) i1(gdp cpi m2) i0(irate) trace maxeigen}{p_end}

{dlgtab:Example 3: Test for I(0) components}

{phang2}{cmd:. mixi01_vecm y1 y2 y3 y4, lags(2) rank(1) testi0}{p_end}

{dlgtab:Example 4: Display all matrices}

{phang2}{cmd:. mixi01_vecm y1 y2 y3 y4, lags(2) i1(y1 y2 y3) i0(y4) rank(1) alpha beta detail}{p_end}


{marker stored}{...}
{title:Stored results}

{pstd}
{cmd:mixi01_vecm} stores the following in {cmd:e()}:

{synoptset 28 tabbed}{...}
{p2col 5 28 32 2: Scalars}{p_end}
{synopt :{cmd:e(N)}}number of observations{p_end}
{synopt :{cmd:e(k_eq)}}number of equations{p_end}
{synopt :{cmd:e(lags)}}lag order of underlying VAR{p_end}
{synopt :{cmd:e(rank)}}true cointegration rank r{p_end}
{synopt :{cmd:e(rank_total)}}total rank h = r + k{p_end}
{synopt :{cmd:e(k_i1)}}number of I(1) variables{p_end}
{synopt :{cmd:e(k_i0)}}number of I(0) variables{p_end}
{synopt :{cmd:e(ll)}}log-likelihood{p_end}
{synopt :{cmd:e(lr_testi0)}}LR statistic for I(0) test (if {opt testi0}){p_end}
{synopt :{cmd:e(p_testi0)}}p-value for I(0) test{p_end}

{p2col 5 28 32 2: Macros}{p_end}
{synopt :{cmd:e(cmd)}}{cmd:mixi01_vecm}{p_end}
{synopt :{cmd:e(depvar)}}list of endogenous variables{p_end}
{synopt :{cmd:e(i1vars)}}I(1) variables{p_end}
{synopt :{cmd:e(i0vars)}}I(0) variables{p_end}

{p2col 5 28 32 2: Matrices}{p_end}
{synopt :{cmd:e(b)}}stacked VECM coefficient vector{p_end}
{synopt :{cmd:e(V)}}variance–covariance matrix{p_end}
{synopt :{cmd:e(alpha)}}n × h loading matrix{p_end}
{synopt :{cmd:e(beta)}}n × h cointegrating matrix{p_end}
{synopt :{cmd:e(Pi)}}n × n long-run matrix alpha*beta'{p_end}
{synopt :{cmd:e(Gamma)}}short-run coefficient matrices{p_end}
{synopt :{cmd:e(Sigma)}}n × n error covariance{p_end}
{synopt :{cmd:e(eigenvalues)}}Johansen eigenvalues{p_end}
{synopt :{cmd:e(trace_stat)}}trace test statistics{p_end}
{synopt :{cmd:e(trace_cv)}}trace test critical values{p_end}

{p2col 5 28 32 2: Functions}{p_end}
{synopt :{cmd:e(sample)}}marks estimation sample{p_end}


{marker references}{...}
{title:References}

{phang}
Chen, P. (2022).  Vector error correction models with stationary and
nonstationary variables.  SSRN Working Paper No. 4218834.
{p_end}

{phang}
Hamilton, J. D. (1994).  {it:Time Series Analysis}.  Princeton University Press.
{p_end}

{phang}
Johansen, S. (1995).  {it:Likelihood-Based Inference in Cointegrated Vector
Autoregressive Models}.  Oxford University Press.
{p_end}

{phang}
Lütkepohl, H. (2006).  {it:New Introduction to Multiple Time Series
Analysis}.  Berlin: Springer.
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
