{smcl}
{* *! version 1.0.0  18may2026}{...}
{cmd:help multicoint}{right: ({browse "https://www.stata.com":Stata})}
{hline}

{title:Title}

{phang}
{bf:multicoint} {hline 2} Estimation and testing of multicointegrated
time-series in the sense of Granger-Lee (1989, 1990)

{title:Package contents}

{p 4 6 2}
The {bf:multicoint} library provides every estimator and every test that has
been proposed for the analysis of multicointegrated time-series.  Components:

{p 8 12 2}
{help multicoint##syntax:multicoint} - {it:main}: multicointegration estimation and testing.{p_end}
{p 8 12 2}
{helpb multicoint_sim} - simulate a multicointegrated DGP for Monte-Carlo work.{p_end}
{p 8 12 2}
{helpb multicoint_graph} - diagnostic graphs after {bf:multicoint}.{p_end}
{p 8 12 2}
{helpb multicoint_cv} - Engsted-Gonzalo-Haldrup (1997) critical-value tables.{p_end}

{marker syntax}{...}
{title:Syntax}

{p 8 14 2}
{cmd:multicoint} {it:depvar} {it:indepvars} {ifin} [{cmd:,} {it:options}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab :Main}
{synopt :{opt est:imator(name)}}choice of estimator (see {help multicoint##estimators:Estimators}){p_end}
{synopt :{opt test(name)}}choice of multicoint test (see {help multicoint##tests:Tests}){p_end}
{synopt :{opt tr:end(spec)}}deterministics: {bf:none}, {bf:c}, {bf:ct}, {bf:ctt}{p_end}
{synopt :{opt noc:onstant}}suppress constant term{p_end}

{syntab :Test/lag options}
{synopt :{opt lags(#)}}fixed ADF lag order (default 0){p_end}
{synopt :{opt auto:lag(crit)}}IC for lag selection: {bf:aic}, {bf:bic}, {bf:hqic}, {bf:fixed}{p_end}
{synopt :{opt maxl:ag(#)}}maximum lag for auto-selection (default 8){p_end}

{syntab :DOLS-only options}
{synopt :{opt leads(#)}}leads of {it:Δx} (default 2){p_end}
{synopt :{opt dlags(#)}}lags of {it:Δx} (default 2){p_end}

{syntab :FM-OLS / CCR options}
{synopt :{opt ker:nel(name)}}{bf:bartlett} (default), {bf:parzen}, {bf:qs}{p_end}
{synopt :{opt bw:idth(#)}}fixed bandwidth (default 0 = Andrews auto){p_end}

{syntab :TAOLS options}
{synopt :{opt k(#)}}number of orthonormal basis functions (default 12){p_end}

{syntab :Reporting}
{synopt :{opt l:evel(#)}}confidence level; default 95{p_end}
{synopt :{opt gr:aph}}call {help multicoint_graph} after estimation{p_end}
{synopt :{opt grsave(filename)}}export the diagnostic graph to a file{p_end}
{synopt :{opt notab:le}}suppress result tables{p_end}
{synoptline}

{p 4 6 2}
{it:depvar} is the flow series {it:y_t} (I(1) under the Granger-Lee /
Engsted-Haldrup set-up).
{it:indepvars} is one or more flow regressors {it:x_t} (I(1)).
{cmd:multicoint} internally constructs the cumulated series
{it:Y_t} = Σ{it:y_s}, {it:X_t} = Σ{it:x_s}, and estimates the
multicointegration regression{p_end}

{p 8 8 2}
{bf:Y_t = α + δ_1 t + δ_2 t² + β'·X_t + γ'·x_t + u_t}

{p 4 6 2}
Coefficients on the cumulated I(2) regressors are reported with suffix
{bf:_cum}; the original flow I(1) regressors are reported by their original
name.  Residuals are saved as {bf:_mc_uhat}; cumulated series as
{bf:_mc_Ycum}, {bf:_mc_Xcum1}, etc.

{marker description}{...}
{title:Description}

{pstd}
Two I(1) flow series are said to be {bf:multicointegrated} when their
cumulated sums - which are I(2) by construction - cointegrate together
{it:and} with the original flows.  In that case there is a "second layer"
of long-run equilibrium relating the stock variables to the underlying
flow variables, on top of the standard I(1) cointegration
{it:y - β x ~ I(0)}.

{pstd}
The classical example (Granger & Lee, 1989) is the production-sales-inventory
identity: y_t (production) and x_t (sales) are I(1) and cointegrated; the
level of inventories Q_t = Σ(y - x)_s would normally inherit one unit root,
but in the presence of multicointegration Q_t (or a linear combination of
Q_t and the flows) is stationary.  Stock-flow data of housing starts /
completions, income / consumption / wealth, and many other systems exhibit
this feature (Engsted & Haldrup, 1999).

{pstd}
{cmd:multicoint} bundles {bf:all} the estimators and tests that have been
proposed for this set-up.

{marker estimators}{...}
{title:Estimators}

{phang}{bf:est(ols)} {hline 2} ordinary least squares{p_end}
{pmore}
Plain OLS on the multicoint regression.  Super-consistent for β (rate T²)
and γ (rate T) under multicoint (Haldrup, 1994).  The reported standard
errors are non-standard; use TAOLS for valid inference.

{phang}{bf:est(fmols)} {hline 2} fully-modified OLS{p_end}
{pmore}
Phillips-Hansen (1990).  Corrects OLS for long-run endogeneity and serial
correlation using a kernel HAC long-run variance.  Standard t/F inference
applies asymptotically.  Requires the {helpb cointreg} package
(Wang, 2011).

{phang}{bf:est(dols)} {hline 2} dynamic OLS{p_end}
{pmore}
Saikkonen (1991), Stock & Watson (1993).  Augments the regression with
leads and lags of Δx_t to neutralise long-run endogeneity.  Standard
inference applies.  Requires {helpb cointreg}.

{phang}{bf:est(ccr)} {hline 2} canonical cointegrating regression{p_end}
{pmore}
Park (1992).  Pre-transforms y_t and x_t using a long-run covariance
estimate so OLS on the transformed series yields asymptotically efficient
coefficients with standard inference.  Requires {helpb cointreg}.

{phang}{bf:est(imols)} {hline 2} integrated-modified OLS{p_end}
{pmore}
Vogelsang & Wagner (2014).  Partial-sum-transforms the regression and
estimates by OLS.  Has standard normal/mixed-normal limiting theory under
cointegration and multicointegration without needing a kernel bandwidth.

{phang}{bf:est(taols)} {hline 2} transformed and augmented OLS{p_end}
{pmore}
Hwang & Sun (2018), Sun et al. (2025, 2026).  Applies an orthonormal
Fourier (shifted sine) basis transformation to the regression augmented
with the endogeneity-correction term Δx_t.  The resulting transformed
regression behaves as a classical linear normal regression, so standard
t / F inference is exact in the asymptotic limit.  Recommended when the
cointegration regime is uncertain.

{marker tests}{...}
{title:Tests of multicointegration}

{phang}{bf:test(gl)} {hline 2} Granger-Lee (1989, 1990) two-step{p_end}
{pmore}
Stage 1: regress y_t on x_t and save residual Z_t.  Stage 2: cumulate Z_t
into S_t = Σ Z_s, regress S_t on x_t and ADF-test the second-stage
residual.  Note: this is the {it:original} multicoint test;
Engsted-Gonzalo-Haldrup (1997) show that its limit distribution is a
Brownian-bridge functional - we provide it for completeness only.

{phang}{bf:test(egh)} {hline 2} Engsted-Gonzalo-Haldrup (1997) one-step{p_end}
{pmore}
ADF t-test applied to the residual u_t of the {it:single} multicoint
regression  Y_t = α + δ_1 t + δ_2 t² + β'·X_t + γ'·x_t + u_t.  Rejection
of the unit-root null supports multicointegration.  Critical values from
EGH (1997, Tables 1 - 2), interpolated for the user's sample size T.
See {helpb multicoint_cv} to inspect the full c.v. table.

{phang}{bf:test(taols)} {hline 2} Sun et al. (2026) adaptive F-test{p_end}
{pmore}
Constructs two Wald statistics for γ = 0 - one under the multicoint
regression and one under the conventional cointegration regression - and
combines them with a data-driven weight w that converges to 1 under
multicoint and to 0 under plain coint.  The adaptive Wald statistic is
asymptotically F-distributed with (m_2, K - 3·d_x - 1) degrees of
freedom under either regime.

{phang}{bf:test(all)}{p_end}
{pmore}
Run all three tests and report them side-by-side.

{marker results}{...}
{title:Stored results}

{phang}Scalars{p_end}
{synoptset 22 tabbed}{...}
{synopt :{cmd:e(N)}}number of observations{p_end}
{synopt :{cmd:e(K)}}number of flow regressors{p_end}
{synopt :{cmd:e(rss)}}residual sum of squares{p_end}
{synopt :{cmd:e(r2)}}R²{p_end}
{synopt :{cmd:e(lrse)}}long-run S.E. (FM-OLS / CCR){p_end}
{synopt :{cmd:e(gl_stat)}}Granger-Lee statistic{p_end}
{synopt :{cmd:e(gl_cv05)}}GL 5% c.v.{p_end}
{synopt :{cmd:e(egh_stat)}}EGH t-statistic{p_end}
{synopt :{cmd:e(egh_cv01/cv025/cv05/cv10)}}EGH c.v. at 1, 2.5, 5, 10%{p_end}
{synopt :{cmd:e(egh_lags)}}lag order used by ADF{p_end}
{synopt :{cmd:e(taols_Fm/Fc/Fa)}}TAOLS Wald under multicoint / coint / adaptive{p_end}
{synopt :{cmd:e(taols_w)}}adaptive weight{p_end}

{phang}Macros{p_end}
{synopt :{cmd:e(cmd)}}{bf:multicoint}{p_end}
{synopt :{cmd:e(estimator)}}selected estimator{p_end}
{synopt :{cmd:e(test)}}selected test(s){p_end}
{synopt :{cmd:e(trend)}}deterministics{p_end}
{synopt :{cmd:e(depvar)}}{it:y} flow variable{p_end}
{synopt :{cmd:e(indepvars)}}{it:x} flow variables{p_end}
{synopt :{cmd:e(resvar)}}name of residual variable ({bf:_mc_uhat}){p_end}
{synopt :{cmd:e(Ycumvar)}}cumulated {it:y} variable{p_end}
{synopt :{cmd:e(Xcumvars)}}cumulated {it:x} variables{p_end}

{phang}Matrices{p_end}
{synopt :{cmd:e(b)}}coefficient vector{p_end}
{synopt :{cmd:e(V)}}covariance matrix{p_end}

{marker examples}{...}
{title:Examples}

{phang}{bf:1.  Simulate a multicointegrated DGP and run all tests/estimators}{p_end}
{p 8 16 2}{stata "multicoint_sim, n(300) beta(1) gamma(0.95) regime(multicoint) clear"}{p_end}
{p 8 16 2}{stata "multicoint y x, est(taols) test(all) graph"}{p_end}

{phang}{bf:2.  Estimate via FM-OLS, then DOLS (delegated to cointreg)}{p_end}
{p 8 16 2}{stata "multicoint y x, est(fmols) test(egh) trend(ct)"}{p_end}
{p 8 16 2}{stata "multicoint y x, est(dols) leads(3) dlags(3)"}{p_end}

{phang}{bf:3.  Granger-Lee two-step test under OLS estimation}{p_end}
{p 8 16 2}{stata "multicoint y x, est(ols) test(gl)"}{p_end}

{phang}{bf:4.  Inspect EGH critical values}{p_end}
{p 8 16 2}{stata "multicoint_cv, trend(ct) m1(2) m2(1) tsize(200)"}{p_end}

{phang}{bf:5.  Six-panel diagnostic graph after estimation}{p_end}
{p 8 16 2}{stata "multicoint y x, est(taols) test(taols)"}{p_end}
{p 8 16 2}{stata "multicoint_graph, sixpanel save(mc_diag.png)"}{p_end}

{marker dependencies}{...}
{title:Dependencies}

{pstd}
The FM-OLS, DOLS and CCR estimators delegate to Qunyong Wang's
{helpb cointreg} package, which can be installed with:

{p 8 12 2}
{cmd:. ssc install cointreg}

{pstd}
All other estimators ({bf:ols}, {bf:imols}, {bf:taols}) and all three tests
are implemented natively in this package.

{marker refs}{...}
{title:References}

{phang}
Engsted, T., Gonzalo, J. & Haldrup, N. (1997). Testing for
multicointegration. {it:Economics Letters} 56, 259-266.{p_end}

{phang}
Engsted, T. & Haldrup, N. (1999). Multicointegration in stock-flow
models. {it:Oxford Bulletin of Economics and Statistics} 61(2), 237-254.{p_end}

{phang}
Engsted, T. & Johansen, S. (1997). Granger's representation theorem and
multicointegration. {it:EUI Working Paper ECO} 97/15.{p_end}

{phang}
Granger, C.W.J. & Lee, T.-H. (1989). Investigation of production, sales
and inventory relationships using multicointegration and non-symmetric
error correction models. {it:J. Applied Econometrics} 4, S145-S159.{p_end}

{phang}
Granger, C.W.J. & Lee, T.-H. (1990). Multicointegration. In G.F. Rhodes &
T.B. Fomby (eds.), {it:Advances in Econometrics} 8, 71-84.{p_end}

{phang}
Haldrup, N. (1994). The asymptotics of single-equation cointegration
regressions with I(1) and I(2) variables. {it:J. Econometrics} 63, 153-181.{p_end}

{phang}
Hwang, J. & Sun, Y. (2018). Should we go one step further? An accurate
comparison of size and power for cointegrating regressions.
{it:J. Econometrics}.{p_end}

{phang}
Park, J. (1992). Canonical cointegrating regressions. {it:Econometrica}
60, 119-143.{p_end}

{phang}
Phillips, P.C.B. & Hansen, B.E. (1990). Statistical inference in
instrumental variables regression with I(1) processes.
{it:Review of Economic Studies} 57, 99-125.{p_end}

{phang}
Saikkonen, P. (1991). Asymptotically efficient estimation of cointegrating
regressions. {it:Econometric Theory} 7, 1-21.{p_end}

{phang}
Stock, J. & Watson, M. (1993). A simple estimator of cointegrating vectors
in higher order integrated systems. {it:Econometrica} 61, 783-820.{p_end}

{phang}
Sun, Y. et al. (2025, 2026). TAOLS: Adaptive F and t tests for
cointegration and multicointegration. Working paper.{p_end}

{phang}
Vogelsang, T.J. & Wagner, M. (2014). Integrated modified OLS estimation
and fixed-b inference for cointegrating regressions.
{it:J. Econometrics}.{p_end}

{phang}
Wang, Q. (2011). cointreg: Stata module for cointegration regression
(FM-OLS, CCR, DOLS).  Available from SSC.{p_end}

{marker author}{...}
{title:Author}

{phang}
{bf:Dr Merwan Roudane}{p_end}
{phang}
Department of Economics{p_end}
{phang}
Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{p_end}
{phang}
{bf:multicoint} v1.0.0 - 18 May 2026.  Bug reports and questions welcome.

{title:Also see}

{psee}Online:  {helpb multicoint_sim}, {helpb multicoint_graph},
{helpb multicoint_cv}, {helpb cointreg}{p_end}
