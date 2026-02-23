{smcl}
{* *! version 2.0.0  21feb2026}{...}
{vieweralsosee "ardl" "help ardl"}{...}
{vieweralsosee "qardl" "help qardl"}{...}
{vieweralsosee "fbardl" "help fbardl"}{...}
{viewerjumpto "Syntax" "fqardl##syntax"}{...}
{viewerjumpto "Description" "fqardl##description"}{...}
{viewerjumpto "Options" "fqardl##options"}{...}
{viewerjumpto "Output" "fqardl##output"}{...}
{viewerjumpto "Examples" "fqardl##examples"}{...}
{viewerjumpto "Stored results" "fqardl##results"}{...}
{viewerjumpto "References" "fqardl##references"}{...}
{title:Title}

{p2colset 5 18 20 2}{...}
{p2col:{bf:fqardl} {hline 2}}Fourier Quantile Autoregressive Distributed Lag model{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:fqardl}
{depvar} {indepvars}
{ifin}
{cmd:,}
{opt tau(numlist)}
[{it:options}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt tau(numlist)}}quantile(s) to estimate, each in (0,1){p_end}

{syntab:Model}
{synopt:{opt type(string)}}estimation method: {bf:fqardl} (default), {bf:fbqardl}, or {bf:qcoint}{p_end}
{synopt:{opt p(#)}}AR lag order for depvar; 0 = auto-select (default){p_end}
{synopt:{opt q(#)}}DL lag order for indepvars; 0 = auto-select (default){p_end}
{synopt:{opt pmax(#)}}max AR lag for auto-selection; default 4{p_end}
{synopt:{opt qmax(#)}}max DL lag for auto-selection; default 4{p_end}
{synopt:{opt ecm}}estimate Error Correction Model form{p_end}
{synopt:{opt nocons:tant}}suppress constant term{p_end}

{syntab:Fourier}
{synopt:{opt maxk(#)}}maximum Fourier frequency; default 3{p_end}
{synopt:{opt nof:ourier}}exclude Fourier terms (reduces to standard QARDL){p_end}

{syntab:Information Criterion}
{synopt:{opt ic(string)}}information criterion for lag selection: {bf:bic} (default) or {bf:aic}{p_end}
{synopt:{opt maxlag(#)}}max lag for Fourier frequency selection; default 4{p_end}

{syntab:Bootstrap (type=fbqardl)}
{synopt:{opt reps(#)}}number of bootstrap replications; default 999{p_end}

{syntab:Quantile Cointegration (type=qcoint)}
{synopt:{opt leads(#)}}number of leads for dynamic regression; default 1{p_end}
{synopt:{opt lags(#)}}number of lags for dynamic regression; default 1{p_end}

{syntab:Display & Graphs}
{synopt:{opt graph}}produce publication-quality graphs and summary tables{p_end}
{synopt:{opt notable}}suppress coefficient tables{p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}
{cmd:fqardl} estimates the Fourier Quantile Autoregressive Distributed Lag (FQARDL)
model. It extends the standard QARDL framework by incorporating Fourier
trigonometric terms to capture smooth structural breaks without requiring
knowledge of the number, dates, or form of breaks.

{pstd}
The command provides a complete econometric toolkit with three estimation methods:

{dlgtab:type(fqardl) — Standard Fourier Quantile ARDL}

{pstd}
Estimates long-run (beta), short-run AR (phi), and short-run impact (gamma)
parameters at each quantile using iteratively reweighted least squares (IRLS).
Output is organized in {bf:ADJ/LR/SR} blocks:{p_end}

{phang2}{bf:ADJ} — Speed of adjustment: rho(tau) = sum(phi) - 1. Measures how fast
the system returns to long-run equilibrium. Must be negative for convergence.{p_end}

{phang2}{bf:LR} — Long-run coefficients: beta(tau) = gamma(tau) / (1 - sum(phi(tau))).
The equilibrium relationship at each quantile.{p_end}

{phang2}{bf:SR} — Short-run dynamics: lagged differences of dependent variable (phi),
contemporaneous differences of independent variables (gamma), and Fourier terms.{p_end}

{pstd}
When {opt ecm} is specified, the model is reparameterized in Error Correction form
with explicit ECM term and theta (cumulative short-run) coefficients.

{pstd}
A {bf:Wald test for parameter constancy} across quantiles is automatically displayed,
testing whether long-run, short-run AR, and short-run impact parameters are
equal across all specified quantiles.

{dlgtab:type(fbqardl) — Fourier Bootstrap Quantile ARDL}

{pstd}
Extends FQARDL with bootstrap-based cointegration testing. Two complementary
bootstrap methods are run:{p_end}

{phang2}{bf:1. Unconditional Bootstrap} — Uses a single set of restricted residuals
under the joint null of no cointegrating relationship.{p_end}

{phang2}{bf:2. Conditional Bootstrap} — Uses separate restricted residuals for each
test statistic (F_overall, t_dependent, F_independent), providing more
precise null distributions.{p_end}

{pstd}
Three test statistics are computed for cointegration:{p_end}

{phang2}{bf:F_overall} — Joint significance of all level variables (H0: no levels relationship){p_end}
{phang2}{bf:t_dependent} — Significance of lagged dependent variable (H0: no error correction){p_end}
{phang2}{bf:F_independent} — Joint significance of lagged independent variables (H0: no long-run effect of x){p_end}

{pstd}
Bootstrap critical values (1%, 5%, 10%) and p-values are reported for each test.
Cointegration is concluded when all three tests reject at the 5% level.

{pstd}
When {opt graph} is specified with {opt type(fbqardl)}, bootstrap IRF confidence
intervals are also computed using a parametric percentile method, showing
95% confidence bands at horizons h=0, 1, 5, 10, 20.

{dlgtab:type(qcoint) — Quantile Cointegration Test}

{pstd}
Implements a residual-based cointegration test at each quantile. The procedure:{p_end}

{phang2}1. Estimates a dynamic cointegrating regression with leads and lags{p_end}
{phang2}2. Tests for a unit root in the residuals at each quantile{p_end}
{phang2}3. Compares the t-ratio to quantile-dependent critical values{p_end}

{pstd}
This test is useful when cointegration may hold at some quantiles but not others.

{marker output}{...}
{title:Output}

{dlgtab:Graphs (with graph option)}

{pstd}
The {opt graph} option produces up to 6 publication-quality graphs:{p_end}

{phang2}{bf:fqardl_kstar} — SSR vs Fourier frequency k, with optimal k* highlighted{p_end}
{phang2}{bf:fqardl_beta_#} — Long-run beta(tau) quantile process with 95% CI for each variable{p_end}
{phang2}{bf:fqardl_rho} — Speed of adjustment rho(tau) across quantiles{p_end}
{phang2}{bf:fqardl_sr_impact} — Short-run gamma(tau) coefficient process{p_end}
{phang2}{bf:fqardl_irf_#} — Impulse Response Function: dynamic multiplier path from gamma to beta{p_end}
{phang2}{bf:fqardl_persistence} — Persistence profile showing (1+rho)^h decay{p_end}

{dlgtab:Summary Tables (with graph option)}

{pstd}
Three summary tables are displayed alongside graphs:{p_end}

{phang2}{bf:Speed of Adjustment & Half-Life} — Shows rho(tau), 1+rho(tau),
half-life ln(2)/|rho|, and convergence status at each quantile.{p_end}

{phang2}{bf:Long-Run vs Short-Run Comparison} — Compares beta(tau) and gamma(tau)
with LR/SR ratio and adjustment classification (Amplify/Dampen/Reverse).{p_end}

{phang2}{bf:Dynamic Multiplier at Key Horizons} — IRF values at h=0, 1, 5, 10, 20
using the formula: IRF(h,tau) = beta(tau) + (gamma(tau) - beta(tau)) * (1+rho(tau))^h{p_end}

{marker examples}{...}
{title:Examples}

{pstd}{bf:Setup}{p_end}
{phang2}{cmd:. webuse lutkepohl2, clear}{p_end}
{phang2}{cmd:. tsset qtr}{p_end}

{dlgtab:Example 1: Basic FQARDL with automatic lag selection}

{phang2}{cmd:. fqardl inv inc, tau(0.10 0.25 0.50 0.75 0.90)}{p_end}

{pstd}
Estimates FQARDL at 5 quantiles. Lag orders (p,q) are selected
automatically by BIC. Fourier frequency k* is selected by minimum SSR.
Displays ADJ/LR/SR coefficient tables and Wald constancy tests.

{dlgtab:Example 2: FQARDL with graphs and summary tables}

{phang2}{cmd:. fqardl inv inc, tau(0.25 0.50 0.75) graph}{p_end}

{pstd}
Produces 6 graphs (k* selection, beta process, rho, gamma, IRF, persistence)
plus 3 summary tables (half-life, LR vs SR, dynamic multiplier).

{dlgtab:Example 3: FQARDL with fixed lags}

{phang2}{cmd:. fqardl inv inc, tau(0.25 0.50 0.75) p(2) q(2)}{p_end}

{pstd}
Uses fixed lag orders p=2 (AR) and q=2 (DL), bypassing automatic selection.

{dlgtab:Example 4: FQARDL in ECM form}

{phang2}{cmd:. fqardl inv inc, tau(0.25 0.50 0.75) ecm graph}{p_end}

{pstd}
Estimates in Error Correction form with explicit ECM coefficient and
cumulative short-run (theta) parameters.

{dlgtab:Example 5: Standard QARDL (no Fourier)}

{phang2}{cmd:. fqardl inv inc, tau(0.25 0.50 0.75) nofourier}{p_end}

{pstd}
Excludes Fourier terms, reducing to the standard QARDL model.

{dlgtab:Example 6: FBQARDL with full bootstrap}

{phang2}{cmd:. fqardl inv inc, tau(0.25 0.50 0.75) type(fbqardl) reps(199) graph}{p_end}

{pstd}
Runs FQARDL estimation, then performs both unconditional and conditional
bootstrap cointegration tests with 199 replications. With {opt graph},
also computes bootstrap IRF confidence intervals and displays all graphs.

{dlgtab:Example 7: Quantile cointegration test}

{phang2}{cmd:. fqardl inv inc, tau(0.10 0.25 0.50 0.75 0.90) type(qcoint)}{p_end}

{pstd}
Tests for cointegration at each quantile separately using a residual-based
unit root test. Reports t-ratio and critical values at each quantile.

{dlgtab:Example 8: Multiple independent variables}

{phang2}{cmd:. fqardl inv inc consump, tau(0.25 0.50 0.75) graph}{p_end}

{pstd}
Estimates with two independent variables. Separate IRF graphs are
produced for each variable.

{dlgtab:Example 9: AIC lag selection with higher max lags}

{phang2}{cmd:. fqardl inv inc, tau(0.50) ic(aic) pmax(6) qmax(6)}{p_end}

{pstd}
Uses AIC instead of BIC for lag selection, with max lag of 6.

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:fqardl} stores the following in {cmd:e()}:

{synoptset 24 tabbed}{...}
{p2col 5 24 28 2: Scalars}{p_end}
{synopt:{cmd:e(p)}}AR lag order{p_end}
{synopt:{cmd:e(q)}}DL lag order{p_end}
{synopt:{cmd:e(k)}}number of independent variables{p_end}
{synopt:{cmd:e(kstar)}}optimal Fourier frequency{p_end}
{synopt:{cmd:e(ntau)}}number of quantiles{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(boot_Fov_pval)}}unconditional bootstrap F_overall p-value (fbqardl){p_end}
{synopt:{cmd:e(boot_t_pval)}}unconditional bootstrap t_dependent p-value (fbqardl){p_end}
{synopt:{cmd:e(boot_Find_pval)}}unconditional bootstrap F_independent p-value (fbqardl){p_end}
{synopt:{cmd:e(boot2_Fov_pval)}}conditional bootstrap F_overall p-value (fbqardl){p_end}
{synopt:{cmd:e(boot2_t_pval)}}conditional bootstrap t_dependent p-value (fbqardl){p_end}
{synopt:{cmd:e(boot2_Find_pval)}}conditional bootstrap F_independent p-value (fbqardl){p_end}
{synopt:{cmd:e(boot_reps)}}number of bootstrap replications{p_end}

{p2col 5 24 28 2: Matrices}{p_end}
{synopt:{cmd:e(beta)}}long-run parameters (k*ntau x 1){p_end}
{synopt:{cmd:e(beta_cov)}}covariance of beta{p_end}
{synopt:{cmd:e(phi)}}short-run AR parameters (p*ntau x 1){p_end}
{synopt:{cmd:e(phi_cov)}}covariance of phi{p_end}
{synopt:{cmd:e(gamma)}}short-run impact parameters (k*ntau x 1){p_end}
{synopt:{cmd:e(gamma_cov)}}covariance of gamma{p_end}
{synopt:{cmd:e(rho_vec)}}speed of adjustment rho(tau) = sum(phi) - 1{p_end}
{synopt:{cmd:e(tau)}}quantile vector{p_end}
{synopt:{cmd:e(bt_raw)}}raw quantile regression coefficients{p_end}
{synopt:{cmd:e(fh)}}kernel density estimates at quantiles{p_end}
{synopt:{cmd:e(lags)}}optimal lag orders per variable{p_end}
{synopt:{cmd:e(ssr_matrix)}}SSR values for Fourier frequency selection{p_end}
{synopt:{cmd:e(irf_lo)}}bootstrap IRF 2.5th percentile (fbqardl + graph){p_end}
{synopt:{cmd:e(irf_hi)}}bootstrap IRF 97.5th percentile (fbqardl + graph){p_end}
{synopt:{cmd:e(irf_med)}}bootstrap IRF median (fbqardl + graph){p_end}

{pstd}
ECM form additionally stores:{p_end}
{synopt:{cmd:e(phi_ecm)}}ECM speed-of-adjustment coefficient{p_end}
{synopt:{cmd:e(phi_ecm_cov)}}covariance of ECM coefficient{p_end}
{synopt:{cmd:e(theta)}}cumulative short-run coefficients{p_end}
{synopt:{cmd:e(theta_cov)}}covariance of theta{p_end}

{p2col 5 24 28 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}fqardl{p_end}
{synopt:{cmd:e(model)}}fqardl, fqardl-ecm, or qcoint{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(indepvars)}}names of independent variables{p_end}
{synopt:{cmd:e(title)}}model title{p_end}

{marker references}{...}
{title:References}

{phang}
Cho, J.S., Kim, T.-H., & Shin, Y. (2015).
Quantile cointegration in the autoregressive distributed-lag modeling framework.
{it:Journal of Econometrics}, 188(1), 281-300.

{phang}
Furno, M. (2021).
Cointegration tests at the quantiles.
{it:International Journal of Finance and Economics}, 26(1), 1087-1100.

{phang}
Koenker, R. & Xiao, Z. (2004).
Unit root quantile autoregression inference.
{it:Journal of the American Statistical Association}, 99(467), 775-787.

{phang}
McNown, R., Sam, C.Y., & Goh, S.K. (2018).
Bootstrapping the autoregressive distributed lag test for cointegration.
{it:Applied Economics}, 50(13), 1509-1521.

{phang}
Pesaran, M.H., Shin, Y., & Smith, R.J. (2001).
Bounds testing approaches to the analysis of level relationships.
{it:Journal of Applied Econometrics}, 16(3), 289-326.

{phang}
Zaghdoudi, T. (2025).
US-China tension, geopolitical risks and oil price uncertainty:
Evidence from Fourier-QARDL approach.
{it:Energy Research Letters}.

{title:Author}

{pstd}
Dr. Merwan Roudane{break}
merwanroudane920@gmail.com

{title:Also see}

{psee}
{space 2}Help:  {manhelp qreg R}, {helpb ardl}, {helpb qardl}, {helpb fbardl}
{p_end}
