{smcl}
{* *! version 1.0.0  21may2026}{...}
{cmd:help mixi12}{right: ({browse "https://www.stata.com":Stata})}
{hline}

{title:Title}

{phang}
{bf:mixi12} {hline 2} Full library for cointegration analysis of systems
containing both I(1) and I(2) variables

{title:Package contents}

{p 4 6 2}
The {bf:mixi12} library bundles every estimator and every test the
literature has proposed for cointegrated systems with a mixture of I(1)
and I(2) variables.  Click any sub-command below to open its dedicated
help page.

{p 8 12 2}
{help mixi12##syntax:mixi12} - {it:main}: orchestrator that runs the full pipeline.{p_end}
{p 8 12 2}
{helpb mixi12_unit} - cross-variable integration-order summary; delegates per-variable Dickey-Pantula, Hasza-Fuller and Haldrup Z(F*) testing to {helpb dptest}.{p_end}
{p 8 12 2}
{helpb mixi12_haldrup} - Haldrup (1994) single-equation residual-based ADF cointegration test for mixed I(1)/I(2) systems; delegates to {helpb dptest, test(coint)}.{p_end}
{p 8 12 2}
{helpb mixi12_johansen} - two-step Johansen (1995, 1997) I(2) VAR estimation plus Paruolo (1996) joint Q(r, s_1) rank test.{p_end}
{p 8 12 2}
{helpb mixi12_trans} - Kongsted (2005) / Kurita (2011) I(2)-to-I(1) transformation LR test.{p_end}
{p 8 12 2}
{helpb mixi12_sw} - Stock-Watson (1993) triangular estimator for mixed I(1)/I(2) systems.{p_end}
{p 8 12 2}
{helpb mixi12_mco} - multicointegration estimation (OLS / FM-OLS / DOLS / CCR / IM-OLS / TAOLS) for I(1) flows whose cumulants are I(2); delegates to {helpb multicoint}.{p_end}
{p 8 12 2}
{helpb mixi12_mco_compare} - side-by-side comparison of all six multicointegration estimators and all three tests.{p_end}
{p 8 12 2}
{helpb mixi12_gl} - Granger-Lee (1989, 1990) two-step multicointegration test.{p_end}
{p 8 12 2}
{helpb mixi12_egh} - Engsted-Gonzalo-Haldrup (1997) one-step residual ADF multicointegration test.{p_end}
{p 8 12 2}
{helpb mixi12_sim} - simulator for Doornik-Mosconi-Paruolo (2017) Formula I(1)/I(2) and Kurita-style money-multiplier DGPs.{p_end}
{p 8 12 2}
{helpb mixi12_graph} - diagnostic plots (levels/differences, cointegration relations, common-trend proxies).{p_end}
{p 8 12 2}
{helpb mixi12_cv} - critical-value lookup (Haldrup, chi-squared, Pantula).{p_end}

{marker syntax}{...}
{title:Syntax}

{p 8 14 2}
{cmd:mixi12} {it:varlist} {ifin} [{cmd:,} {it:options}]

{p 8 14 2}
{cmd:mixi12} {it:subcommand} ...

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab :Pipeline}
{synopt :{opt unit}}run the unit-root battery only{p_end}
{synopt :{opt hald:rup}}run the Haldrup test only{p_end}
{synopt :{opt jo:hansen}}run the joint Q + two-step Johansen only{p_end}
{synopt :{opt all}}run all three (default){p_end}
{syntab :Common}
{synopt :{opt lags(#)}}VAR / ADF lag length (default 2){p_end}
{synopt :{opt tr:end(spec)}}deterministics: {bf:none}, {bf:c}, {bf:ct}{p_end}
{synopt :{opt saving(file)}}export results to {it:file}.dta{p_end}
{synoptline}

{p 4 6 2}
{it:varlist} is a time-series-set varlist; the first variable is treated
as the dependent variable when the Haldrup single-equation test is run.

{marker description}{...}
{title:Description}

{pstd}
{cmd:mixi12} provides a one-stop pipeline for the empirical analysis of
multivariate systems where the integration order of the variables is
unknown and may be a mixture of I(1) and I(2).  Such systems arise
naturally for nominal stock variables (broad money, monetary base,
price indices) once levels - not growth rates - are taken; the
benchmark applications are long-run money demand and purchasing-power
parity.

{pstd}
There are two distinct branches of the mixed-integration literature
covered by this package:

{phang2}
1.  {bf:Direct I(2)} - the I(2) variables are observed in levels (e.g.
nominal money, prices).  The toolbox here is the Johansen two-step
VAR with two reduced-rank conditions, Haldrup's single-equation
residual ADF, and Kongsted's I(2)-to-I(1) transformation test.{p_end}

{phang2}
2.  {bf:Multicointegration} - the I(2) variables are not directly
observed but are constructed as cumulants of underlying I(1) flow
variables (production-sales-inventory, consumption-income-wealth).
The toolbox here is the Granger-Lee 2-step, Engsted-Gonzalo-Haldrup
1-step, and Sun et al. TAOLS adaptive tests, together with OLS /
FM-OLS / DOLS / CCR / IM-OLS / TAOLS estimators.{p_end}

{marker methods}{...}
{title:Methods}

{dlgtab:1.  Per-variable integration order}

{pstd}
{cmd:mixi12_unit} delegates to {helpb dptest} (Roudane 2026) which
combines four univariate diagnostics:

{phang2}
{bf:ADF} on levels and differences (Dickey & Fuller 1979).{p_end}

{phang2}
{bf:Dickey-Pantula (1987) sequential t*} - starts from the most
non-stationary hypothesis (I(d_max)) and tests downwards until a
unit-root is rejected.  Avoids the size distortions of the original
ADF when applied directly to I(2) data.{p_end}

{phang2}
{bf:Hasza-Fuller (1979) joint F} - {it:Phi_2(2)} for an intercept-only
specification.  Tests H_0: alpha = beta = 1 against H_1: at most one
unit root.  Critical values from Hasza & Fuller (1979, Table 4.1).{p_end}

{phang2}
{bf:Haldrup (1994 JBES) semi-parametric Z(F*)} - applies a
Newey-West / Bartlett correction to the Hasza-Fuller F so that the
test remains valid under MA error structure.  Same critical values as
the parametric Hasza-Fuller F.{p_end}

{dlgtab:2.  Haldrup (1994 JoE) single-equation cointegration}

{pstd}
{cmd:mixi12_haldrup} runs the static OLS regression

{p 8 8 2}
{bf:y_t = alpha + delta'·c_t + beta_1' x1_t + beta_2' x2_t + u_t}

{pstd}
where {it:x1_t} are I(1) and {it:x2_t} are I(2) regressors, then applies
an ADF test to the residual.  Critical values come from Haldrup (1994
J. Econometrics 63, Table 1) and are indexed by (m_1, m_2, T), the
numbers of I(1) and I(2) regressors and the sample size.  The test
generalises Engle-Granger / Phillips-Ouliaris to mixed I(1)/I(2)
regression and is consistent under the null of no cointegration even
when the levels regression is spurious.

{dlgtab:3.  Johansen two-step I(2) VAR + Paruolo joint Q test}

{pstd}
{cmd:mixi12_johansen} estimates the cointegrated VAR

{p 8 8 2}
{bf:Delta^2 X_t = alpha beta' X_{t-1} + Gamma Delta X_{t-1} + Sigma_i Psi_i Delta^2 X_{t-i} + mu + eps_t}

{pstd}
with two reduced-rank conditions:

{phang2}
{bf:Step 1 (Johansen 1988):} {it:Pi} = {it:alpha beta'} of rank {it:r}.{p_end}

{phang2}
{bf:Step 2 (Johansen 1997):} {it:alpha_perp' Gamma beta_perp} =
{it:phi eta'} of rank {it:s_1}, with {it:s_2} = {it:p - r - s_1} the
number of common I(2) stochastic trends.{p_end}

{pstd}
The {bf:Paruolo (1996) joint Q(r, s_1)} statistic combines the trace
statistics from both steps:

{p 8 8 2}
{bf:Q(r, s_1) = TRACE(r) + TRACE(s_1 | r)}

{pstd}
and is asymptotically chi-squared under the joint null.  It is the
recommended test for I(2) rank determination in Juselius (2006),
Kurita (2011) and Majsterek (2012) because it has correct asymptotic
size whereas the sequential trace test does not.

{pstd}
The output decomposes the data into:
{p_end}
{phang2}
- {bf:r} cointegrating relations beta'X_t ~ I(1);{p_end}
{phang2}
- {bf:s_1} common stochastic trends of order I(1);{p_end}
{phang2}
- {bf:s_2} common stochastic trends of order I(2).{p_end}

{dlgtab:4.  Kongsted I(2)-to-I(1) transformation test}

{pstd}
{cmd:mixi12_trans} tests, after {cmd:mixi12_johansen} has produced
{it:beta_perp_2}, the null

{p 8 8 2}
{bf:H_0:  sp(tau) = sp(G)}

{pstd}
where {it:tau} = ({it:beta, beta_perp_1}) and {it:G} is a user-supplied
{it:p x q} matrix of candidate linear combinations.  If the null is
not rejected, the linear combinations in {it:G} constitute a valid
transformation that reduces the I(2) system to I(1) without loss of
information.  Examples:

{phang2}
- Money multiplier {it:m2 - mb} on (m2, mb, p, R): G = (1, -1, 0, 0)'.{p_end}
{phang2}
- Long-run price homogeneity on (m, p, y, R): G = (1, -1, 0, 0)'.{p_end}
{phang2}
- Nominal-to-real on (m, p, y): G = (1, -1, 0)'.{p_end}

{pstd}
The LR statistic is asymptotically chi-squared (Johansen 2006;
Kongsted 2005; Kurita 2011).

{dlgtab:5.  Stock-Watson (1993) triangular estimator}

{pstd}
{cmd:mixi12_sw} estimates the single-equation regression

{p 8 8 2}
{bf:y_t = alpha + delta·t + beta_1' x1_t + beta_2' x2_t + Sigma_j gamma_j Delta x_{t+j} + u_t}

{pstd}
augmented with leads and lags of the differences of all regressors.
The augmentation removes long-run endogeneity, so the limiting
distribution of the long-run coefficients is mixed-Gaussian and
standard t / F inference is asymptotically valid.

{dlgtab:6.  Multicointegration (I(1) flow / I(2) stock)}

{pstd}
{cmd:mixi12_mco} (and its standalone twins {cmd:mixi12_gl},
{cmd:mixi12_egh}, {cmd:mixi12_mco_compare}) cover the special case in
which the I(2) variables are not observed but constructed as cumulants
of I(1) flows.  The regression actually estimated is

{p 8 8 2}
{bf:Y_t = alpha + delta_1·t + delta_2·t^2 + beta'·X_t + gamma'·x_t + u_t}

{pstd}
with {it:Y_t} = {it:Sigma y_s} and {it:X_t} = {it:Sigma x_s} both I(2),
{it:x_t} the original I(1) flows, and {it:u_t} ~ I(0) under
multicointegration.  Six estimators are available:

{phang2}
- {bf:OLS} (Haldrup 1994): super-super-consistent at rate {it:T^2}.{p_end}
{phang2}
- {bf:FM-OLS} (Phillips & Hansen 1990): kernel HAC correction for endogeneity.{p_end}
{phang2}
- {bf:DOLS} (Saikkonen 1991; Stock & Watson 1993): leads/lags augmentation.{p_end}
{phang2}
- {bf:CCR} (Park 1992): canonical cointegrating regression.{p_end}
{phang2}
- {bf:IM-OLS} (Vogelsang & Wagner 2014): integrated-modified OLS.{p_end}
{phang2}
- {bf:TAOLS} (Hwang & Sun 2018; Sun et al. 2025, 2026): orthonormal Fourier basis transformation; exact normal-theory inference.{p_end}

{pstd}
Three tests are available:

{phang2}
- {bf:Granger-Lee (1989, 1990)}: two-step ADF on the cumulated residual of a stage-1 cointegrating regression.{p_end}
{phang2}
- {bf:Engsted-Gonzalo-Haldrup (1997)}: one-step ADF on the residual of the multicointegration regression; critical values from EGH 1997, Tables 1-2.{p_end}
{phang2}
- {bf:TAOLS adaptive F} (Sun et al. 2026): combines the Wald statistic under both the multicointegration regression and the conventional cointegration regression with a data-driven weight; asymptotically F-distributed under either regime.{p_end}

{marker dependencies}{...}
{title:Dependencies}

{pstd}
{cmd:mixi12_unit} and {cmd:mixi12_haldrup} delegate to {bf:dptest}
(Roudane 2026), which ships every per-variable I(2) unit-root
statistic (Dickey-Pantula sequential t*, Hasza-Fuller joint F, Haldrup
semi-parametric Z(F*)) and the Haldrup (1994 JoE) residual-based ADF
cointegration test.  {cmd:mixi12_mco}, {cmd:mixi12_mco_compare},
{cmd:mixi12_gl} and {cmd:mixi12_egh} delegate to {bf:multicoint}
(Roudane 2026) for the I(1) flow / I(2) stock multicointegration case.
Install both with:

{p 8 12 2}{cmd:. ssc install dptest}{p_end}
{p 8 12 2}{cmd:. ssc install multicoint}{p_end}

{pstd}
All other commands ({helpb mixi12_johansen}, {helpb mixi12_trans},
{helpb mixi12_sw}, {helpb mixi12_sim}, {helpb mixi12_graph},
{helpb mixi12_cv}) are self-contained.

{marker results}{...}
{title:Stored results}

{phang}Scalars{p_end}
{synoptset 22 tabbed}{...}
{synopt :{cmd:e(N)}}sample size{p_end}
{synopt :{cmd:e(p)}}number of variables in the system{p_end}
{synopt :{cmd:e(rank)}}cointegration rank {it:r} (Johansen){p_end}
{synopt :{cmd:e(s1)}}number of I(1) common stochastic trends{p_end}
{synopt :{cmd:e(s2)}}number of I(2) common stochastic trends{p_end}
{synopt :{cmd:e(lags)}}lag length used{p_end}

{phang}Matrices{p_end}
{synopt :{cmd:e(beta)}}cointegrating matrix (p x r){p_end}
{synopt :{cmd:e(alpha)}}loadings (p x r){p_end}
{synopt :{cmd:e(beta1)}}I(1) common-trend weights (p x s_1){p_end}
{synopt :{cmd:e(beta2)}}I(2) common-trend weights (p x s_2){p_end}
{synopt :{cmd:e(Q)}}Paruolo joint Q(r, s_1) table{p_end}

{marker examples}{...}
{title:Examples}

{phang}{bf:1. Simulate a Kurita-style monetary system and run the full pipeline}{p_end}
{p 8 16 2}{stata "mixi12_sim, dgp(km) n(160) seed(42) clear"}{p_end}
{p 8 16 2}{stata "mixi12 m2 mb p rd, lags(3) trend(c) all"}{p_end}

{phang}{bf:2. Classify integration orders}{p_end}
{p 8 16 2}{stata "mixi12_unit m2 mb p rd, det(const) level(5)"}{p_end}

{phang}{bf:3. Single-equation Haldrup test}{p_end}
{p 8 16 2}{stata "mixi12_haldrup m2, i1(rd) i2(mb p) det(trend)"}{p_end}

{phang}{bf:4. Joint Paruolo Q + two-step Johansen I(2) VAR}{p_end}
{p 8 16 2}{stata "mixi12_johansen m2 mb p rd, lags(3) trend(c) joint"}{p_end}

{phang}{bf:5. Test the money multiplier as an I(2)-to-I(1) transformation}{p_end}
{p 8 16 2}{stata "matrix G = (1 \ -1 \ 0 \ 0)"}{p_end}
{p 8 16 2}{stata "mixi12_trans, g(G)"}{p_end}

{phang}{bf:6. Stock-Watson triangular estimator}{p_end}
{p 8 16 2}{stata "mixi12_sw m2, i1(rd) i2(mb p) leads(2) lagsdiff(2) trend(c)"}{p_end}

{phang}{bf:7. Multicointegration — all six estimators side-by-side}{p_end}
{p 8 16 2}{stata "mixi12_mco_compare y x, trend(c) leads(2) dlags(2)"}{p_end}

{phang}{bf:8. Diagnostic plots}{p_end}
{p 8 16 2}{stata "mixi12_graph levels m2 mb p"}{p_end}
{p 8 16 2}{stata "mixi12_graph cointspace"}{p_end}

{marker refs}{...}
{title:References}

{phang}
Dickey, D.A. & Fuller, W.A. (1979). Distribution of the estimators
for autoregressive time series with a unit root.  {it:J. American
Statistical Association} 74, 427-431.{p_end}

{phang}
Dickey, D.A. & Pantula, S.G. (1987). Determining the order of
differencing in autoregressive processes.  {it:J. Business & Economic
Statistics} 5, 455-461.{p_end}

{phang}
Doornik, J.A., Mosconi, R. & Paruolo, P. (2017). Formula I(1) and
I(2): Race tracks for likelihood maximization algorithms of I(1) and
I(2) cointegrated VAR models.  {it:Econometrics} 5, 49.{p_end}

{phang}
Engle, R.F. & Granger, C.W.J. (1987). Co-integration and error
correction: Representation, estimation and testing.  {it:Econometrica}
55, 251-276.{p_end}

{phang}
Engsted, T., Gonzalo, J. & Haldrup, N. (1997). Testing for
multicointegration.  {it:Economics Letters} 56, 259-266.{p_end}

{phang}
Engsted, T. & Haldrup, N. (1999). Multicointegration in stock-flow
models.  {it:Oxford Bulletin of Economics and Statistics} 61, 237-254.{p_end}

{phang}
Granger, C.W.J. & Lee, T.-H. (1989). Investigation of production,
sales and inventory relationships using multicointegration and
non-symmetric error correction models.  {it:J. Applied Econometrics}
4, S145-S159.{p_end}

{phang}
Granger, C.W.J. & Lee, T.-H. (1990). Multicointegration.  In
G.F. Rhodes & T.B. Fomby (eds.), {it:Advances in Econometrics} 8, 71-84.{p_end}

{phang}
Haldrup, N. (1994a). Semi-parametric tests for double unit roots.
{it:J. Business & Economic Statistics} 12, 109-122.{p_end}

{phang}
Haldrup, N. (1994b). The asymptotics of single-equation cointegration
regressions with I(1) and I(2) variables.  {it:J. Econometrics} 63,
153-181.{p_end}

{phang}
Hasza, D.P. & Fuller, W.A. (1979). Estimation for autoregressive
processes with unit roots.  {it:Annals of Statistics} 7, 1106-1120.{p_end}

{phang}
Hwang, J. & Sun, Y. (2018). Should we go one step further?  An
accurate comparison of size and power for cointegrating regressions.
{it:J. Econometrics}.{p_end}

{phang}
Johansen, S. (1988). Statistical analysis of cointegration vectors.
{it:J. Economic Dynamics and Control} 12, 231-254.{p_end}

{phang}
Johansen, S. (1992). A representation of vector autoregressive
processes integrated of order 2.  {it:Econometric Theory} 8, 188-202.{p_end}

{phang}
Johansen, S. (1995).  {it:Likelihood-Based Inference in Cointegrated
Vector Autoregressive Models}.  Oxford University Press.{p_end}

{phang}
Johansen, S. (1997). Likelihood analysis of the I(2) model.
{it:Scandinavian Journal of Statistics} 24, 433-462.{p_end}

{phang}
Johansen, S. (2006). Statistical analysis of hypotheses on the
cointegrating relations in the I(2) model.  {it:J. Econometrics} 132,
81-115.{p_end}

{phang}
Juselius, K. (2006). {it:The Cointegrated VAR Model: Methodology and
Applications}.  Oxford University Press.{p_end}

{phang}
Kongsted, H.C. (2005). Testing the nominal-to-real transformation.
{it:J. Econometrics} 124, 205-225.{p_end}

{phang}
Kurita, T. (2011). Modelling time series data of monetary aggregates
using I(2) and I(1) cointegration analysis.  {it:Bulletin of Economic
Research}.{p_end}

{phang}
Maddala, G.S. & Kim, I.-M. (1998). {it:Unit Roots, Cointegration, and
Structural Change}.  Cambridge University Press.{p_end}

{phang}
Majsterek, M. (2012). Cointegration analysis in the case of I(2) -
general overview.  {it:Central European Journal of Economic Modelling
and Econometrics} 4, 215-252.{p_end}

{phang}
Pantula, S.G. (1986). Comments on "Modelling the persistence of
conditional variances".  {it:Econometric Reviews} 5, 71-74.{p_end}

{phang}
Park, J.Y. (1992). Canonical cointegrating regressions.
{it:Econometrica} 60, 119-143.{p_end}

{phang}
Paruolo, P. (1996). On the determination of integration indices in
I(2) systems.  {it:J. Econometrics} 72, 313-356.{p_end}

{phang}
Phillips, P.C.B. & Hansen, B.E. (1990). Statistical inference in
instrumental variables regression with I(1) processes.  {it:Review of
Economic Studies} 57, 99-125.{p_end}

{phang}
Phillips, P.C.B. & Ouliaris, S. (1990). Asymptotic properties of
residual based tests for cointegration.  {it:Econometrica} 58, 165-193.{p_end}

{phang}
Saikkonen, P. (1991). Asymptotically efficient estimation of
cointegrating regressions.  {it:Econometric Theory} 7, 1-21.{p_end}

{phang}
Stock, J.H. & Watson, M.W. (1993). A simple estimator of cointegrating
vectors in higher order integrated systems.  {it:Econometrica} 61,
783-820.{p_end}

{phang}
Sun, Y., Hwang, J., et al. (2025, 2026). TAOLS: Adaptive F and t tests
for cointegration and multicointegration.  Working paper.{p_end}

{phang}
Vogelsang, T.J. & Wagner, M. (2014). Integrated modified OLS
estimation and fixed-b inference for cointegrating regressions.
{it:J. Econometrics} 178, 741-760.{p_end}

{marker author}{...}
{title:Author}

{phang}
{bf:Dr Merwan Roudane}{p_end}
{phang}
Department of Economics (Independent Researcher){p_end}
{phang}
Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{p_end}
{phang}
{bf:mixi12} v1.0.0 - 21 May 2026.  Bug reports and questions welcome.

{title:Also see}

{psee}Companion commands:
{helpb mixi12_unit}, {helpb mixi12_haldrup}, {helpb mixi12_johansen},
{helpb mixi12_trans}, {helpb mixi12_sw}, {helpb mixi12_mco},
{helpb mixi12_mco_compare}, {helpb mixi12_gl}, {helpb mixi12_egh},
{helpb mixi12_sim}, {helpb mixi12_graph}, {helpb mixi12_cv}.

{psee}Engines: {helpb dptest}, {helpb multicoint}.
