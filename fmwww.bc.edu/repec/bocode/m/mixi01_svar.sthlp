{smcl}
{* *! version 1.0.0  20may2026  Dr Merwan Roudane (merwanroudane920@gmail.com)}{...}
{vieweralsosee "mixi01" "help mixi01"}{...}
{vieweralsosee "mixi01_fmols" "help mixi01_fmols"}{...}
{vieweralsosee "mixi01_fmvar" "help mixi01_fmvar"}{...}
{vieweralsosee "mixi01_fmiv" "help mixi01_fmiv"}{...}
{vieweralsosee "mixi01_acl"  "help mixi01_acl"}{...}
{vieweralsosee "mixi01_vecm" "help mixi01_vecm"}{...}
{vieweralsosee "mixi01_irf" "help mixi01_irf"}{...}
{vieweralsosee "mixi01_test" "help mixi01_test"}{...}
{viewerjumpto "Syntax" "mixi01_svar##syntax"}{...}
{viewerjumpto "Description" "mixi01_svar##description"}{...}
{viewerjumpto "Options" "mixi01_svar##options"}{...}
{viewerjumpto "Remarks" "mixi01_svar##remarks"}{...}
{viewerjumpto "Examples" "mixi01_svar##examples"}{...}
{viewerjumpto "Stored results" "mixi01_svar##stored"}{...}
{viewerjumpto "References" "mixi01_svar##references"}{...}
{viewerjumpto "Author"     "mixi01_svar##author"}{...}
{viewerjumpto "Also see"   "mixi01_svar##alsosee"}{...}

{title:Title}

{p2colset 5 24 26 2}{...}
{p2col :{hi:mixi01_svar} {hline 2}}Structural VAR with P1/T1/P0/T0 shock identification{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 20 2}
{cmd:mixi01_svar} {varlist} {ifin}
[{cmd:,}
{it:options}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model specification}
{synopt :{opt lags(#)}}number of lags; default: {cmd:lags(2)}{p_end}
{synopt :{opt i1(varlist)}}I(1) variables in the system{p_end}
{synopt :{opt i0(varlist)}}I(0) variables in the system{p_end}

{syntab:Shock classification}
{synopt :{opt p1(numlist)}}equation indices with P1 (permanent, I(1)) shocks{p_end}
{synopt :{opt t1(numlist)}}equation indices with T1 (transitory, I(1)) shocks{p_end}
{synopt :{opt p0(numlist)}}equation indices with P0 (permanent, I(0)) shocks{p_end}
{synopt :{opt t0(numlist)}}equation indices with T0 (transitory, I(0)) shocks{p_end}

{syntab:Identification}
{synopt :{opt lr:estrictions(string)}}long-run restrictions in matrix form{p_end}
{synopt :{opt sr:estrictions(string)}}short-run (contemporaneous) restrictions{p_end}
{synopt :{opt sign:restrictions(string)}}sign restrictions on impulse responses{p_end}
{synopt :{opt cholesky}}Cholesky (recursive) identification{p_end}

{syntab:Long-run covariance estimation}
{synopt :{opt kernel(string)}}kernel function; default: {cmd:bartlett}{p_end}
{synopt :{opt bw(#|auto)}}bandwidth; default: {cmd:auto}{p_end}
{synopt :{opt prewhiten}}apply VAR(1) prewhitening{p_end}

{syntab:Estimation method}
{synopt :{opt fmvar}}use FM-VAR for reduced-form estimation (default){p_end}
{synopt :{opt ols}}use OLS for reduced-form estimation{p_end}

{syntab:Reporting}
{synopt :{opt l:evel(#)}}confidence level; default: {cmd:level(95)}{p_end}
{synopt :{opt detail}}display structural impact matrix{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:mixi01_svar} estimates and identifies a structural vector autoregression
for systems containing a mixture of I(1) and I(0) variables, following the
methodology of Fisher, Huh and Pagan (2016).

{pstd}
The reduced-form VAR is estimated using FM-VAR (default) or OLS, then
structural shocks are identified by imposing long-run, short-run, or sign
restrictions that respect the four-way shock classification of Fisher,
Huh and Pagan:

{p 8 12 2}
{bf:P1 (Permanent, I(1)):}  Structural shocks from equations with I(1)
dependent variables that have a nonzero long-run effect on at least one
I(1) variable.  The associated column in the long-run response matrix
C = C(1) is nonzero.

{p 8 12 2}
{bf:T1 (Transitory, I(1)):}  Shocks from I(1) equations that have zero
long-run effects on all I(1) variables.  These are the classic transitory
shocks associated with cointegration.

{p 8 12 2}
{bf:P0 (Permanent, I(0)):}  Shocks from equations with I(0) dependent
variables that have a nonzero long-run effect on at least one I(1) variable.
These arise when the level of the I(0) variable — rather than its change —
appears in the structural equation for an I(1) variable.

{p 8 12 2}
{bf:T0 (Transitory, I(0)):}  Shocks from I(0) equations that have zero
long-run effects on all I(1) variables.  This requires that the I(0) variable
enters the structural equations for I(1) variables in differenced form
(Fisher et al., 2016, Proposition).

{pstd}
The distinction between P0 and T0 has important consequences.  Fisher et al.
show that:

{p 8 12 2}
(a) A P0 shock can {it:destroy cointegration} between I(1) variables that
would otherwise hold.

{p 8 12 2}
(b) The number of permanent shocks can exceed the number of independent
permanent components (stochastic trends) when P0 shocks are present.

{p 8 12 2}
(c) The permanent component of the I(1) variables must be computed using the
generalized formula (equations 14–17 in Fisher et al., 2016) that accounts
for both error-correction terms and lagged I(0) variables.


{marker options}{...}
{title:Options}

{dlgtab:Model specification}

{phang}
{opt lags(#)} specifies the lag order.

{phang}
{opt i1(varlist)} specifies I(1) variables.

{phang}
{opt i0(varlist)} specifies I(0) variables.

{dlgtab:Shock classification}

{phang}
{opt p1(numlist)} specifies which equation numbers contain P1 (permanent,
from I(1)) shocks.  For example, in a 4-variable system with three I(1)
variables and no cointegration, {cmd:p1(1 2 3)} indicates three permanent
shocks.

{phang}
{opt t1(numlist)} specifies equation numbers for T1 (transitory, from I(1))
shocks.  In a system with cointegration rank r, there are r T1 shocks.

{phang}
{opt p0(numlist)} specifies equation numbers for P0 (permanent, from I(0))
shocks.  A shock is P0 when the I(0) variable appears in levels in the
structural equation for an I(1) variable.

{phang}
{opt t0(numlist)} specifies equation numbers for T0 (transitory, from I(0))
shocks.  A shock is T0 when the I(0) variable appears in the structural
equation in differenced form, ensuring zero long-run effects on all I(1)
variables.

{dlgtab:Identification}

{phang}
{opt lrestrictions(string)} specifies long-run identifying restrictions as
a string matrix, using "." for free parameters and "0" for zero restrictions.
For example, {cmd:lrestrictions("* 0 0 0 \ * 0 0 * \ * 0 0 0 \ 0 0 0 0")}
restricts the long-run response matrix C(1) = B(1)^{−1}.

{phang}
{opt srestrictions(string)} specifies contemporaneous (impact) restrictions
on A_0.

{phang}
{opt signrestrictions(string)} specifies sign restrictions on impulse
responses at specified horizons.

{phang}
{opt cholesky} applies Cholesky identification (lower-triangular A_0).

{dlgtab:Long-run covariance estimation}

{phang}
{opt kernel(string)}, {opt bw(#|auto)}, {opt prewhiten} — see
{helpb mixi01_fmols} for details.

{dlgtab:Estimation method}

{phang}
{opt fmvar} (default) uses FM-VAR for the reduced-form, removing second-order
bias from the VAR coefficients.

{phang}
{opt ols} uses standard OLS for the reduced form.  This may be preferred for
comparison or when FM corrections are unnecessary (e.g., all I(0) systems).


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:P0 shocks and cointegration.}  An important contribution of Fisher, Huh
and Pagan (2016) is the demonstration that the presence of a P0 shock — a shock
from an I(0) variable that has a permanent effect on an I(1) variable — can
eliminate cointegration that would otherwise hold.  Consider two I(1) variables
y_{1t} and y_{2t} that are cointegrated when only a supply shock (P1) and demand
shock (T1) are present.  Adding an I(0) interest rate i_t to the system, with
i_t appearing in levels in the structural equation for y_{2t}, introduces a
P0 shock that gives y_{2t} an independent permanent component, breaking
cointegration.

{pstd}
{bf:Design for T0 shocks.}  To ensure that the shock from an I(0) variable is
transitory (T0), the structural equation for each I(1) variable must contain
the I(0) variable in {it:differenced} form only.  This is the Pagan–Pesaran
condition extended in Fisher et al.

{pstd}
{bf:Permanent component formula.}  The permanent component of the I(1)
variables is computed using equation (17) of Fisher et al.:

{p 8 8 2}
Delta y^P_t = (I − R*Phi)^{−1} (I − A_1)^{−1} [e_{1t} + G(I−F)^{−1} e_{2t}]

{pstd}
where R = (I − A_1)^{−1} G (I − F)^{−1}.  This formula generalises the
Beveridge–Nelson decomposition to systems with both error-correction terms
and I(0) variables.


{marker examples}{...}
{title:Examples}

{dlgtab:Example 1: Peersman (2005)-style SVAR}

{pstd}3 I(1) variables (output, oil price, general price level), 1 I(0) variable
(interest rate), no cointegration among I(1) vars.{p_end}

{phang2}{cmd:. mixi01_svar dlgdp dloil dlcpi irate, lags(4) i1(dlgdp dloil dlcpi) i0(irate) ///}{p_end}
{phang2}{cmd:    p1(1 2 3) p0(4) lrestrictions("* 0 0 0 \ * * 0 * \ * * 0 0 \ 0 0 0 0")}{p_end}

{dlgtab:Example 2: With T0 shock (monetary policy is transitory)}

{phang2}{cmd:. mixi01_svar dlgdp dloil dlcpi dirate, lags(4) i1(dlgdp dloil dlcpi) i0(dirate) ///}{p_end}
{phang2}{cmd:    p1(1 2 3) t0(4) cholesky}{p_end}

{dlgtab:Example 3: System with cointegration and P0}

{phang2}{cmd:. mixi01_svar y1 y2 y3 y4, lags(2) i1(y1 y2 y3) i0(y4) ///}{p_end}
{phang2}{cmd:    p1(1) t1(2 3) p0(4) fmvar kernel(parzen) bw(auto)}{p_end}

{phang2}{cmd:. * Plot IRFs with shock labels:}{p_end}
{phang2}{cmd:. mixi01_irf, step(40) ci combine}{p_end}


{marker stored}{...}
{title:Stored results}

{pstd}
{cmd:mixi01_svar} stores the following in {cmd:e()}:

{synoptset 28 tabbed}{...}
{p2col 5 28 32 2: Scalars}{p_end}
{synopt :{cmd:e(N)}}number of observations{p_end}
{synopt :{cmd:e(k_eq)}}number of equations{p_end}
{synopt :{cmd:e(lags)}}lag order{p_end}
{synopt :{cmd:e(k_i1)}}number of I(1) variables{p_end}
{synopt :{cmd:e(k_i0)}}number of I(0) variables{p_end}
{synopt :{cmd:e(n_p1)}}number of P1 shocks{p_end}
{synopt :{cmd:e(n_t1)}}number of T1 shocks{p_end}
{synopt :{cmd:e(n_p0)}}number of P0 shocks{p_end}
{synopt :{cmd:e(n_t0)}}number of T0 shocks{p_end}
{synopt :{cmd:e(rank_C)}}rank of long-run response matrix C(1){p_end}

{p2col 5 28 32 2: Macros}{p_end}
{synopt :{cmd:e(cmd)}}{cmd:mixi01_svar}{p_end}
{synopt :{cmd:e(depvar)}}list of endogenous variables{p_end}
{synopt :{cmd:e(shock_types)}}list: P1, T1, P0, T0 for each shock{p_end}

{p2col 5 28 32 2: Matrices}{p_end}
{synopt :{cmd:e(b)}}stacked VAR coefficient vector{p_end}
{synopt :{cmd:e(V)}}variance–covariance matrix{p_end}
{synopt :{cmd:e(F)}}n × (np) reduced-form VAR coefficient matrices{p_end}
{synopt :{cmd:e(Sigma)}}n × n reduced-form error covariance{p_end}
{synopt :{cmd:e(A0)}}n × n structural impact matrix{p_end}
{synopt :{cmd:e(A0inv)}}n × n structural impact matrix inverse{p_end}
{synopt :{cmd:e(C1)}}n × n long-run response matrix C(1){p_end}
{synopt :{cmd:e(IRF)}}n × n × (step+1) impulse-response array{p_end}
{synopt :{cmd:e(FEVD)}}n × n × (step+1) forecast-error variance decomposition{p_end}
{synopt :{cmd:e(Companion)}}companion matrix{p_end}
{synopt :{cmd:e(permanent)}}permanent component Delta y^P_t{p_end}

{p2col 5 28 32 2: Functions}{p_end}
{synopt :{cmd:e(sample)}}marks estimation sample{p_end}


{marker references}{...}
{title:References}

{phang}
Fisher, L. A., H.-S. Huh and A. R. Pagan (2016).  Econometric methods for
modelling systems with a mixture of I(1) and I(0) variables.
{it:Journal of Applied Econometrics}, 31(5), 892–911.
{p_end}

{phang}
Pagan, A. R. and M. H. Pesaran (2008).  Econometric analysis of structural
systems with permanent and transitory shocks.
{it:Journal of Economic Dynamics and Control}, 32(10), 3376–3395.
{p_end}

{phang}
Peersman, G. (2005).  What caused the early millennium slowdown?  Evidence
from a small open economy.  {it:Journal of International Money and Finance},
24(3), 346–366.
{p_end}

{phang}
Phillips, P. C. B. (1995).  Fully modified least squares and vector
autoregression.  {it:Econometrica}, 63(5), 1023–1078.
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
