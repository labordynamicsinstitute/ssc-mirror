{smcl}
{* *! version 1.0.0  14feb2026}{...}
{vieweralsosee "[XT] xtcointtest" "help xtcointtest"}{...}
{vieweralsosee "[XT] xtunitroot" "help xtunitroot"}{...}
{viewerjumpto "Syntax" "xtcadfcoint##syntax"}{...}
{viewerjumpto "Description" "xtcadfcoint##description"}{...}
{viewerjumpto "Critical values" "xtcadfcoint##criticalvalues"}{...}
{viewerjumpto "Options" "xtcadfcoint##options"}{...}
{viewerjumpto "Models" "xtcadfcoint##models"}{...}
{viewerjumpto "Stored results" "xtcadfcoint##results"}{...}
{viewerjumpto "Examples" "xtcadfcoint##examples"}{...}
{viewerjumpto "References" "xtcadfcoint##references"}{...}
{viewerjumpto "Author" "xtcadfcoint##author"}{...}

{title:Title}

{p2colset 5 24 26 2}{...}
{p2col:{bf:xtcadfcoint} {hline 2}}Panel CADF cointegration test with structural breaks and cross-section dependence{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:xtcadfcoint}
{depvar}
{indepvars}
{ifin}
[{cmd:,} {it:options}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model Specification}
{synopt:{opt mod:el(#)}}deterministic specification; 0-5; default is {cmd:model(1)}{p_end}
{synopt:{opt br:eaks(#)}}number of structural breaks; 0, 1, or 2; default is {cmd:breaks(0)}{p_end}
{synopt:{opt trim:ming(#)}}trimming fraction for break search; default is {cmd:trimming(0.15)}{p_end}

{syntab:Common Factors and Cross-Section Dependence}
{synopt:{opt nfa:ctors(#)}}number of common factors; default is {cmd:nfactors(1)}{p_end}
{synopt:{opt nocce}}do not use CCE procedure (assumes cross-section independence){p_end}

{syntab:Structural Break Effects}
{synopt:{opt brkslope}}allow breaks to change the cointegrating vector across regimes{p_end}
{synopt:{opt brkloadings}}allow breaks to change factor loadings across regimes{p_end}

{syntab:Lag Augmentation}
{synopt:{opt maxl:ags(#)}}maximum lag order for ADF/CADF augmentation; default is {cmd:maxlags(4)}{p_end}
{synopt:{opt lags:elect(method)}}lag selection criterion: {cmd:aic}, {cmd:bic},
{cmd:maic}, {cmd:mbic}, or {cmd:fixed}; default is {cmd:bic}{p_end}

{syntab:Critical Values}
{synopt:{opt sim:ulate(#)}}number of Monte Carlo replications for bootstrap critical values; default is 0 (skip){p_end}

{syntab:Reporting}
{synopt:{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
A panel variable and a time variable must be set; use {helpb xtset}.
{p_end}
{p 4 6 2}
The panel must be balanced (no gaps in time series for any unit).
{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:xtcadfcoint} tests the null hypothesis of no cointegration in a panel data
setting, allowing for cross-section dependence (via common correlated effects),
multiple structural breaks (0, 1, or 2), and heterogeneity in break dates and
parameters across panel units.

{pstd}
The test is based on the panel CIPS (Cross-sectionally Augmented IPS) statistic,
which averages the individual CADF (Cross-sectionally Augmented Dickey-Fuller)
cointegration test statistics across all panel units. Under the null of no
cointegration, the panel CIPS statistic has a non-standard distribution, and
critical values depend on N, T, k, and the model specification.

{pstd}
The procedure is implemented as follows:

{phang}1. Estimate the pooled CCE (Common Correlated Effects) cointegrating
relationship, projecting out the effect of cross-section averages and
deterministic components.{p_end}

{phang}2. Compute Engle-Granger residuals from the estimated long-run
relationship.{p_end}

{phang}3. Run individual CADF (or ADF) regressions on the residuals, augmented
with lagged cross-section averages.{p_end}

{phang}4. The panel CIPS statistic is the average of the individual
t-statistics.{p_end}

{phang}5. For endogenous breaks (breaks > 0), the break dates are estimated by
minimizing the sum of squared residuals over a grid of candidate break dates.{p_end}

{marker criticalvalues}{...}
{title:Critical Values}

{pstd}
The panel CIPS statistic has a non-standard distribution. Critical values
depend on the panel dimensions (N, T), the number of regressors (k), the
deterministic specification (model), the number of breaks, and break effect
options (brkslope, brkloadings). For this reason, no universal asymptotic
critical values are available.

{pstd}
{bf:How to obtain critical values:}

{phang}1. {bf:Bootstrap simulation (recommended):} Use the {opt simulate(#)}
option to compute critical values by Monte Carlo simulation under the null
hypothesis (no cointegration). The DGP generates independent random walks
for both the dependent and independent variables, matching the simulation
scripts distributed by the authors. Example:{p_end}

{phang2}{cmd:. xtcadfcoint y x1 x2, model(3) breaks(1) simulate(1000)}{p_end}

{phang}Recommended replications: 1000 (quick, ~1 min), 5000 (moderate, ~5 min),
50000 (publication-quality, ~1 hour). Critical values are reported at the
1%, 2.5%, 5%, and 10% significance levels with rejection decisions.{p_end}

{phang}2. {bf:Paper tables:} Refer to Tables B.13-B.24 in the online appendix of
Banerjee and Carrion-i-Silvestre (2025) for selected (N, T, k)
configurations.{p_end}

{pstd}
{bf:Interpreting results:}

{phang}{bf:Reject H0} if the panel CIPS statistic is more negative than the
critical value at the chosen significance level. A rejection indicates evidence
of cointegration in the panel.{p_end}

{phang}{bf:Fail to reject H0} if the panel CIPS statistic is less negative than
the critical value. This indicates no evidence of cointegration.{p_end}

{marker models}{...}
{title:Model Specifications}

{pstd}
The {opt model()} option specifies the deterministic component:

{p2colset 9 22 24 2}{...}
{p2col:Model}Description{p_end}
{p2line}
{p2col:{cmd:model(0)}}No deterministic component{p_end}
{p2col:{cmd:model(1)}}Constant only (default){p_end}
{p2col:{cmd:model(2)}}Constant and linear time trend{p_end}
{p2col:{cmd:model(3)}}Constant with multiple level shifts{p_end}
{p2col:{cmd:model(4)}}Linear time trend with multiple level shifts{p_end}
{p2col:{cmd:model(5)}}Linear time trend with both level and trend slope shifts{p_end}
{p2line}

{pstd}
Models 3-5 require {cmd:breaks(1)} or {cmd:breaks(2)}. In the paper, these
correspond to Models A1/B1/C1 (no break in loadings) and A2/B2/C2 (break in
loadings).

{marker options}{...}
{title:Options}

{dlgtab:Model Specification}

{phang}
{opt model(#)} specifies the deterministic component of the cointegrating
regression. See {help xtcadfcoint##models:Models} above.

{phang}
{opt breaks(#)} specifies the number of endogenous structural breaks to test.
0 = no breaks, 1 = one break, 2 = two breaks. When breaks > 0, the break
dates are estimated by minimizing the SSR. Default is 0.

{phang}
{opt trimming(#)} sets the trimming fraction for the break date search grid.
Observations within {it:#}*T of the sample endpoints are excluded from
candidate break points. Default is 0.15.

{dlgtab:Common Factors and Cross-Section Dependence}

{phang}
{opt nfactors(#)} specifies the number of common factors assumed. The rank
condition requires num_factors <= (1 + k). Default is 1.

{phang}
{opt nocce} suppresses the common correlated effects (CCE) procedure. When
specified, the panel units are assumed to be cross-sectionally independent.

{dlgtab:Structural Break Effects}

{phang}
{opt brkslope} allows the cointegrating vector (slope parameters) to change
across regimes defined by the structural breaks.

{phang}
{opt brkloadings} allows the factor loadings to change across regimes defined
by the structural breaks.

{dlgtab:Lag Augmentation}

{phang}
{opt maxlags(#)} sets the maximum lag order for the ADF/CADF augmentation in
the cointegration test regression. Default is 4.

{phang}
{opt lagselect(method)} specifies the criterion for automatic lag selection:
{cmd:aic} (Akaike), {cmd:bic} (Bayesian, default), {cmd:maic} (Modified AIC),
{cmd:mbic} (Modified BIC), or {cmd:fixed} (use maxlags for all units).

{dlgtab:Critical Values}

{phang}
{opt simulate(#)} specifies the number of Monte Carlo replications to use for
bootstrap critical values. Under the null hypothesis (no cointegration),
independent random walks are generated for both the dependent and independent
variables, and the test statistic is computed for each replication. Critical
values at the 1%, 2.5%, 5%, and 10% significance levels are reported along with
rejection decisions. The DGP matches the GAUSS simulation scripts distributed
with the paper. Recommended values: 1000 (quick), 5000 (moderate), 50000+
(publication-quality). Default is 0 (skip).

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:xtcadfcoint} stores the following in {cmd:r()}:

{synoptset 24 tabbed}{...}
{p2col 5 24 28 2:Scalars}{p_end}
{synopt:{cmd:r(panel_cips)}}panel CIPS statistic (lambda_hat){p_end}
{synopt:{cmd:r(panel_cips_alt)}}panel CIPS statistic (lambda_tilde); only with breaks{p_end}
{synopt:{cmd:r(N)}}number of panel units{p_end}
{synopt:{cmd:r(T)}}number of time periods{p_end}
{synopt:{cmd:r(k)}}number of regressors{p_end}
{synopt:{cmd:r(model)}}model specification{p_end}
{synopt:{cmd:r(breaks)}}number of breaks{p_end}
{synopt:{cmd:r(nfactors)}}number of common factors{p_end}
{synopt:{cmd:r(brk_slope)}}1 if breaks affect slopes{p_end}
{synopt:{cmd:r(brk_loadings)}}1 if breaks affect loadings{p_end}
{synopt:{cmd:r(cce)}}1 if CCE was used{p_end}
{synopt:{cmd:r(trimming)}}trimming fraction{p_end}
{synopt:{cmd:r(maxlags)}}maximum lag order{p_end}

{p2col 5 24 28 2:Matrices}{p_end}
{synopt:{cmd:r(beta_ccep)}}pooled CCE coefficient estimates{p_end}
{synopt:{cmd:r(SSR)}}sum of squared residuals (4x1){p_end}
{synopt:{cmd:r(t_individual)}}individual CADF/ADF t-statistics (Nx1){p_end}
{synopt:{cmd:r(p_selected)}}selected lag orders per unit (Nx1){p_end}
{synopt:{cmd:r(Tb_hat)}}estimated break dates (lambda_hat); only with breaks{p_end}
{synopt:{cmd:r(Tb_tilde)}}estimated break dates (lambda_tilde); only with breaks{p_end}

{p2col 5 24 28 2:Scalars (with {opt simulate()})}{p_end}
{synopt:{cmd:r(cv_panel_1)}}panel CIPS critical value at 1%{p_end}
{synopt:{cmd:r(cv_panel_2_5)}}panel CIPS critical value at 2.5%{p_end}
{synopt:{cmd:r(cv_panel_5)}}panel CIPS critical value at 5%{p_end}
{synopt:{cmd:r(cv_panel_10)}}panel CIPS critical value at 10%{p_end}
{synopt:{cmd:r(cv_ind_1)}}individual CADF critical value at 1%{p_end}
{synopt:{cmd:r(cv_ind_2_5)}}individual CADF critical value at 2.5%{p_end}
{synopt:{cmd:r(cv_ind_5)}}individual CADF critical value at 5%{p_end}
{synopt:{cmd:r(cv_ind_10)}}individual CADF critical value at 10%{p_end}
{synopt:{cmd:r(simulate)}}number of bootstrap replications{p_end}

{marker examples}{...}
{title:Examples}

{pstd}{bf:Setup: PSY data (Banerjee & Carrion-i-Silvestre empirical application)}{p_end}

{phang}{cmd:. use psy_rhpi_rdipc.dta, clear}{p_end}
{phang}{cmd:. xtset state year}{p_end}

{pstd}{bf:Example 1: No structural breaks, constant, CCE with 2 factors}{p_end}

{phang}{cmd:. xtcadfcoint ln_rhpi ln_rdipc, model(1) breaks(0) nfactors(2)}{p_end}

{pstd}{bf:Example 2: Two breaks, level shifts, breaks affect slopes and loadings}{p_end}

{phang}{cmd:. xtcadfcoint ln_rhpi ln_rdipc, model(3) breaks(2) brkslope brkloadings nfactors(2) maxlags(4)}{p_end}

{pstd}{bf:Example 3: No CCE (assumes cross-section independence)}{p_end}

{phang}{cmd:. xtcadfcoint ln_rhpi ln_rdipc, model(1) breaks(0) nocce}{p_end}

{pstd}{bf:Example 4: With bootstrap critical values (1000 replications)}{p_end}

{phang}{cmd:. xtcadfcoint ln_rhpi ln_rdipc, model(3) breaks(1) nfactors(2) simulate(1000)}{p_end}

{pstd}{bf:Example 5: Publication-quality critical values}{p_end}

{phang}{cmd:. xtcadfcoint ln_rhpi ln_rdipc, model(3) breaks(2) brkslope brkloadings nfactors(2) simulate(5000)}{p_end}

{marker references}{...}
{title:References}

{phang}
Banerjee, A. and Carrion-i-Silvestre, J.L. (2025).
Panel Data Cointegration Testing with Structural Instabilities.
{it:Journal of Business & Economic Statistics}, forthcoming.
DOI: 10.1080/07350015.2024.2314746.{p_end}

{phang}
Banerjee, A. and Carrion-i-Silvestre, J.L. (2015).
Cointegration in Panel Data with Structural Breaks and Cross-Section Dependence.
{it:Journal of Applied Econometrics}, 30(1), 1-22.{p_end}

{phang}
Pesaran, M.H. (2006).
Estimation and Inference in Large Heterogeneous Panels with a Multifactor
Error Structure. {it:Econometrica}, 74(4), 967-1012.{p_end}

{phang}
Pesaran, M.H. (2007).
A Simple Panel Unit Root Test in the Presence of Cross-Section Dependence.
{it:Journal of Applied Econometrics}, 22(2), 265-312.{p_end}

{phang}
Kim, D. and Perron, P. (2009).
Unit Root Tests Allowing for a Break in the Trend Function at an Unknown Time
under Both the Null and Alternative Hypotheses.
{it:Journal of Econometrics}, 148(1), 1-13.{p_end}

{marker author}{...}
{title:Author}

{pstd}Dr Merwan Roudane{p_end}
{pstd}Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{p_end}

{pstd}
Based on the GAUSS code by Josep Lluis Carrion-i-Silvestre and Anindya Banerjee.{p_end}

{title:Also see}

{psee}
{space 2}Help:  {helpb xtcointtest}, {helpb xtunitroot}, {helpb xtset}
{p_end}
